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
    int _serial_status;

    IOChannel _masterchannel;
    IOChannel _slavechannel;
    uint _masterwatch;
    uint _slavewatch;

    int _masterfd;
    int _slavefd;

    public Channel( Multiplexer multiplexer, string name, int number )
    {
        debug( "Channel %s = %d created", name, number );
        _multiplexer = multiplexer;
        _status = Status.Requested;
        _name = name;
        _number = number;
    }

    public string acked()
    {
        debug( "Channel now acked! creating pty" );
        var path = new char[512];
        int res = PosixExtra.openpty( out _masterfd, out _slavefd, path, null, null );
        debug( "openpty returned %d", res );
        if ( res != 0 )
        {
            debug( "could not open pty: %s", Posix.strerror( Posix.errno ) );
            return "";
        }
        debug( "pty opened ok, masterfd: %d, slavefd: %d, name %s", _masterfd, _slavefd, (string)path );

        _masterchannel = new IOChannel.unix_new( _masterfd );
        _masterwatch = _masterchannel.add_watch( IOCondition.IN, can_read_from_master );

        //_slavechannel = new IOChannel.unix_new( _slavefd );
        //_slavewatch = _slavechannel.add_watch( IOCondition.IN, can_read_from_slave );

        _status = Status.Acked;
        return (string)path;
    }

    public void close()
    {
        debug( "close()" );
        // close pty, if open
        _status = Status.Shutdown;
    }

    public string name()
    {
        return _name;
    }

    public Status status()
    {
        return _status;
    }

    public void setSerialStatus( int s )
    {
        debug( "setSerialStatus()" );
        _serial_status = s;
        // emit dbus signal or send send condition via pty
    }

    public void deliverData( void* data, int len )
    {
        debug( "deliverData()" );
        ssize_t byteswritten = PosixExtra.write( _masterfd, data, len );
        if ( (int)byteswritten < len )
        {
            error( "could only write %d bytes to pty. buffer overrun!", (int)byteswritten );
        }
    }

    //
    // callbacks
    //
    public bool can_read_from_master( IOChannel source, IOCondition condition )
    {
        assert( condition == IOCondition.IN );
        debug( "can_read_from_master for fd %d", source.unix_get_fd() );

        var buffer = new char[8192];
        ssize_t bytesread = PosixExtra.read( _masterfd, buffer, 8192 );

        debug( "read %d bytes from fd %d: %s", (int)bytesread, _masterfd, (string)buffer );

        _multiplexer.submit_data( _number, buffer, (int)bytesread );

        return true;
    }

    public bool can_read_from_slave( IOChannel source, IOCondition condition )
    {
        assert( condition == IOCondition.IN );
        debug( "can_read_from_slave for fd %d", source.unix_get_fd() );

        var buffer = new char[8192];
        ssize_t bytesread = PosixExtra.read( _slavefd, buffer, 8192 );

        debug( "read %d bytes from fd %d: %s", (int)bytesread, _slavefd, (string)buffer );

        return true;
    }

}
