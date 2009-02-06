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
        debug( "Channel %s = %d created", name, number );
        _multiplexer = multiplexer;
        _status = Status.Requested;
        _name = name;
        _number = number;
    }

    ~Channel()
    {
        debug( "Channel %s = %d destructed", _name, _number );
    }

    public string acked()
    {
        debug( "Channel now acked! creating pty" );

        _pty = new Pty( onHup, onRead );
        if ( !_pty.openRaw() )
        {
             debug( "could not open pty: %s", Posix.strerror( Posix.errno ) );
             return "";
        }

        _status = Status.Acked;
        return _pty.name();
    }

    public void close()
    {
        debug( "close()" );
        _status = Status.Shutdown;
        // notify multiplexer
        if (_multiplexer != null )
            _multiplexer.channel_closed( _number );
        _pty.close();
        _pty = null;
    }

    public string name()
    {
        return _name;
    }

    public Status status()
    {
        return _status;
    }

    public string path()
    {
        return _pty.name();
    }

    public void setSerialStatus( int s )
    {
        debug( "setSerialStatus()" );
        _serial_status = s;
        // emit dbus signal or send send condition via pty
    }

    public void deliverData( void* data, int len )
    {
        debug( "deliverData()..." );
        int byteswritten = _pty.write( data, len );
        if ( byteswritten < len )
        {
            error( "could only write %d bytes to pty. buffer overrun!", byteswritten );
        }
        debug( "...OK sent %d bytes to %d", byteswritten, _pty.fileno() );
        MainContext.default().iteration( false ); // give other channels a chance (round-robin)
    }

    //
    // callbacks
    //
    public void onRead( Serial serial )
    {
        debug( "can read from Pty" );
        var buffer = new char[8192];
        int bytesread = serial.read( buffer, 8192 );
        debug( "read %d bytes from fd %d: %s", bytesread, serial.fileno(), (string)buffer );

        if (_multiplexer != null )
            _multiplexer.submit_data( _number, buffer, (int)bytesread );
    }

    public void onHup( Serial serial )
    {
        debug( "got HUP from fd %d", serial.fileno() );
        close();
    }

}
