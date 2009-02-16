/*
 * channel.vala
 *
 * Authored by Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

//===========================================================================
using GLib;

//===========================================================================
// The Channel class
//
public class Channel
{
    public enum Status
    {
        Requested,  /* requested on 07.10 layer, but not acknowledged by modem */
        Acked,      /* acknowledged by modem, but not opened by any client */
        Open,       /* acknowledged and opened by a client */
        Denied,     /* denied by the modem. this status is persistent */
        Shutdown,   /* shutting down, will no longer be openable */
    }

    // FIXME: Do we really want to expose the whole multiplexer object to the channel? Consider only using the relevant delegates.
    Multiplexer _multiplexer;

    Status _status;

    string _name;
    int _number;

    Pty _pty;

    int _serial_status;

    public Channel( Multiplexer? multiplexer, string name, int number )
    {
        _multiplexer = multiplexer;
        _status = Status.Requested;
        _name = name;
        _number = number;
        _pty = new Pty( onHup, onRead );
        debug( "%s: constructed", repr() );
    }

    ~Channel()
    {
        debug( "%s: destructed", repr() );
    }

    public string repr()
    {
        return "<Channel %d (%s) connected via %s>".printf( _number, _name, _pty != null? _pty.name() : "(none)" );
    }

    public string acked()
    {
        debug( "%s: acked; opening pty", repr() );

        if ( !_pty.openRaw() )
        {
             debug( ":::could not open pty: %s", Posix.strerror( Posix.errno ) );
             return "";
        }

        _status = Status.Acked;
        return _pty.name();
    }

    public void close()
    {
        debug( "%s: close()", repr() );

        var oldstatus = _status;
        _status = Status.Shutdown;

        if ( oldstatus != Status.Requested )
        {
            if (_multiplexer != null )
                _multiplexer.channel_closed( _number );
        }

        if ( _pty != null )
        {
            _pty.close();
            _pty = null;
        }
    }

    public string name()
    {
        return _name;
    }

    public string path()
    {
        return _pty.name();
    }

    public bool isAcked()
    {
        return _status != Status.Requested;
    }

    public void setSerialStatus( int s )
    {
        debug( "setSerialStatus()" );
        _serial_status = s;
        // emit dbus signal or send send condition via pty
    }

    public void deliverData( void* data, int len )
    {
        _pty.write( data, len );
        MainContext.default().iteration( false ); // give other channels a chance (round-robin)
    }

    //
    // delegates from Pty object
    //
    public void onRead( Serial serial )
    {
        debug( "%s: can read from Pty", repr() );
        var buffer = new char[8192];
        int bytesread = serial.read( buffer, 8192 );
        debug( ":::read %d bytes", bytesread );

        if (_multiplexer != null )
            _multiplexer.submit_data( _number, buffer, (int)bytesread );
    }

    public void onHup( Serial serial )
    {
        debug( "%s: got HUP from Pty", repr() );
        close();
    }

}
