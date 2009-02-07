/*
 * serial.vala
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

//===========================================================================
public class Serial : Object
//===========================================================================
{
    string _portname;
    protected uint _portspeed;
    int _portfd = -1;
    uint _v24;

    IOChannel _channel;
    uint _watch;

    protected bool _isPty;
    char[] _ptyname = new char[512]; // MAX_PATH?

    protected HupFunc _hupfunc;
    protected ReadFunc _readfunc;

    ByteArray _buffer;
    uint _writeWatch;

    public Serial( string portname, uint portspeed, HupFunc? hupfunc, ReadFunc? readfunc )
    {
        _portname = portname;
        _portspeed = portspeed;
        _hupfunc = hupfunc;
        _readfunc = readfunc;
        debug( "%s: constructed", repr() );
    }

    ~Serial()
    {
        debug( "%s: destructed", repr() );
    }

    public string repr()
    {
        return "<Serial %s (%u)>".printf( _portname, _portspeed );
    }

    public void close()
    {
        if ( _watch != 0 )
        Source.remove( _watch );
        _channel = null;
        if ( _portfd != -1 )
            Posix.close( _portfd );
    }

    public bool isOpen()
    {
        return ( _portfd != -1 );
    }

    public string name()
    {
        return _isPty? (string)_ptyname : _portname;
    }

    public bool openRaw()
    {
        if ( _isPty )
        {
            _portfd = PosixExtra.posix_openpt( PosixExtra.O_RDWR | PosixExtra.O_NOCTTY | PosixExtra.O_NONBLOCK );
        }
        else
        {
            _portfd = PosixExtra.open( _portname, PosixExtra.O_RDWR | PosixExtra.O_NOCTTY | PosixExtra.O_NONBLOCK );
        }
        if ( _portfd == -1 )
        {
            warning( "%s: could not open %s: %s", repr(), _portname, Posix.strerror( Posix.errno ) );
            return false;
        }

        if ( _isPty )
        {
            PosixExtra.grantpt( _portfd );
            PosixExtra.unlockpt( _portfd );
            PosixExtra.ptsname_r( _portfd, _ptyname );

            int flags = Posix.fcntl( _portfd, Posix.F_GETFL );
            int res = Posix.fcntl( _portfd, Posix.F_SETFL, flags | Posix.O_NONBLOCK );
            if ( res < 0 )
                warning( "%s: can't set pty master to NONBLOCK: %s", repr(), Posix.strerror( Posix.errno ) );
        }

        Posix.fcntl( _portfd, Posix.F_SETFL, 0 );

        PosixExtra.TermIOs termios = {};
        PosixExtra.tcgetattr( _portfd, termios );

        if ( _portspeed == 115200 )
        {
            // 115200
            PosixExtra.cfsetispeed( termios, PosixExtra.B115200 );
            PosixExtra.cfsetospeed( termios, PosixExtra.B115200 );
        }
        else
            warning( "%s: portspeed != 115200", repr() );

        // local read
        termios.c_cflag |= (PosixExtra.CLOCAL | PosixExtra.CREAD);

        // 8n1
        termios.c_cflag &= ~PosixExtra.PARENB;
        termios.c_cflag &= ~PosixExtra.CSTOPB;
        termios.c_cflag &= ~PosixExtra.CSIZE;
        termios.c_cflag |= PosixExtra.CS8;

        // hardware flow control
        //termios.c_cflag |= PosixExtra.CRTSCTS;

        // software flow control off
        //termios.c_iflag &= ~(PosixExtra.IXON | PosixExtra.IXOFF | PosixExtra.IXANY);

        // raw input
        termios.c_lflag &= ~(PosixExtra.ICANON | PosixExtra.ECHO | PosixExtra.ECHOE | PosixExtra.ISIG);
        termios.c_iflag &= ~(PosixExtra.INLCR | PosixExtra.ICRNL | PosixExtra.IGNCR);

        // raw output
        termios.c_oflag &= ~(PosixExtra.OPOST | PosixExtra.OLCUC | PosixExtra.ONLRET | PosixExtra.ONOCR | PosixExtra.OCRNL );

        /*
        // no special character handling
        termios.c_cc[PosixExtra.VMIN] = 0;
        termios.c_cc[PosixExtra.VTIME] = 2;
        termios.c_cc[PosixExtra.VINTR] = 0;
        termios.c_cc[PosixExtra.VQUIT] = 0;
        termios.c_cc[PosixExtra.VSTART] = 0;
        termios.c_cc[PosixExtra.VSTOP] = 0;
        termios.c_cc[PosixExtra.VSUSP] = 0;
        */
        PosixExtra.tcsetattr( _portfd, PosixExtra.TCSANOW, termios);

        /*
        _v24 = PosixExtra.TIOCM_DTR | PosixExtra.TIOCM_RTS;
        Posix.ioctl( _portfd, PosixExtra.TIOCMBIS, &_v24 );
        */

        // setup watches, if we have delegates
        if ( _hupfunc != null || _readfunc != null )
        {
            _channel = new IOChannel.unix_new( _portfd );
            _channel.set_encoding( null );
            _channel.set_buffer_size( 32768 );
            _watch = _channel.add_watch( IOCondition.IN | IOCondition.HUP, _actionCallback );
        }

        _buffer = new ByteArray();

        return true;
    }

    public int read( void* data, int len )
    {
        assert( _portfd != -1 );
        ssize_t bytesread = Posix.read( _portfd, data, len );
        return (int)bytesread;
    }

    public int _write( void* data, int len )
    {
        assert( _portfd != -1 );
        ssize_t byteswritten = Posix.write( _portfd, data, len );
        return (int)byteswritten;
    }

    public int write( void* data, int len )
    {
        assert( _portfd != -1 );
        var restart = ( _buffer.len == 0 );
        var temp = new uint8[len];
        Memory.copy( temp, data, len );
        _buffer.append( temp );
        //debug( "current buffer length = %d", (int)_buffer.len );
        if ( restart )
        {
            //debug( "restarting writer" );
            _writeWatch = _channel.add_watch( IOCondition.OUT, _writeCallback );
        }
        return len;
    }

    public bool _actionCallback( IOChannel source, IOCondition condition )
    {
        //debug( "_actionCallback, condition = %d", condition );
        if ( IOCondition.IN == condition && _readfunc != null )
        {
            _readfunc( this );
            return true;
        }
        if ( IOCondition.HUP == condition && _hupfunc != null )
            _hupfunc( this );
        return false;
    }

    public bool _writeCallback( IOChannel source, IOCondition condition )
    {
        //debug( "_writeCallback, condition = %d", condition );

        int len = 64 > _buffer.len? (int)_buffer.len : 64;

        var byteswritten = _write( _buffer.data, len  );
        //debug( "_writeCallback: wrote %d bytes", (int)byteswritten );
        _buffer.remove_range( 0, (int)byteswritten );

        return ( _buffer.len != 0 );
    }

}

//===========================================================================
public class Pty : Serial
//===========================================================================
{
    public Pty( HupFunc? hupfunc, ReadFunc? readfunc )
    {
        debug( "Pseudo Tty created" );

        _readfunc = readfunc;
        _hupfunc = hupfunc;
        _isPty = true;

        _portspeed = 115200;
    }
}
//===========================================================================
public delegate void HupFunc( Serial serial );
public delegate void ReadFunc( Serial serial );
