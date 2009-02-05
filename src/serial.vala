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
    uint _portspeed;
    int _portfd = -1;
    uint _v24;

    IOChannel _channel;
    uint _watch;

    protected bool _isPty;
    char[] _ptyname = new char[512]; // MAX_PATH?

    protected HupFunc _hupfunc;
    protected ReadFunc _readfunc;

    public Serial( string portname, uint portspeed, HupFunc? hupfunc, ReadFunc? readfunc )
    {
        debug( "Serial Port %s (%u) created", portname, portspeed );
        _portname = portname;
        _portspeed = portspeed;
        _hupfunc = hupfunc;
        _readfunc = readfunc;
    }

    ~Serial()
    {
        debug( "Serial Port %s (%u) destructed", _portname, _portspeed );
    }

    public void close()
    {
        if ( _watch != 0 )
        Source.remove( _watch );
        _channel = null;
        if ( _portfd != -1 )
            Posix.close( _portfd );
    }

    public int fileno()
    {
        return _portfd;
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
            _portfd = PosixExtra.posix_openpt( PosixExtra.O_RDWR | PosixExtra.O_NOCTTY /* | PosixExtra.O_NONBLOCK */ );
        }
        else
        {
            _portfd = PosixExtra.open( _portname, PosixExtra.O_RDWR | PosixExtra.O_NOCTTY | PosixExtra.O_NONBLOCK );
        }
        if ( _portfd == -1 )
        {
            warning( "could not open %s: %s", _portname, Posix.strerror( Posix.errno ) );
            return false;
        }

        if ( _isPty )
        {
            PosixExtra.grantpt( _portfd );
            PosixExtra.unlockpt( _portfd );
            PosixExtra.ptsname_r( _portfd, _ptyname );
        }

        Posix.fcntl( _portfd, Posix.F_SETFL, 0 );

        PosixExtra.TermIOs termios = new PosixExtra.TermIOs();
        PosixExtra.tcgetattr( _portfd, termios );

        if ( _portspeed == 115200 )
        {
            // 115200
            PosixExtra.cfsetispeed( termios, PosixExtra.B115200 );
            PosixExtra.cfsetospeed( termios, PosixExtra.B115200 );
        }
        else
            warning( "portspeed != 115200" );

        // local read
        termios.c_cflag |= (PosixExtra.CLOCAL | PosixExtra.CREAD);

        // 8n1
        termios.c_cflag &= ~PosixExtra.PARENB;
        termios.c_cflag &= ~PosixExtra.CSTOPB;
        termios.c_cflag &= ~PosixExtra.CSIZE;
        termios.c_cflag |= PosixExtra.CS8;

        // hardware flow control
        termios.c_cflag |= PosixExtra.CRTSCTS;
        termios.c_iflag &= ~(PosixExtra.IXON | PosixExtra.IXOFF | PosixExtra.IXANY);

        // raw input
        termios.c_lflag &= ~(PosixExtra.ICANON | PosixExtra.ECHO | PosixExtra.ECHOE | PosixExtra.ISIG);

        // raw output
        termios.c_oflag &= ~PosixExtra.OPOST;

        // no special character handling
        termios.c_cc[PosixExtra.VMIN] = 0;
        termios.c_cc[PosixExtra.VTIME] = 10;
        termios.c_cc[PosixExtra.VINTR] = 0;
        termios.c_cc[PosixExtra.VQUIT] = 0;
        termios.c_cc[PosixExtra.VSTART] = 0;
        termios.c_cc[PosixExtra.VSTOP] = 0;
        termios.c_cc[PosixExtra.VSUSP] = 0;

        PosixExtra.tcsetattr( _portfd, PosixExtra.TCSAFLUSH, termios);

        _v24 = PosixExtra.TIOCM_DTR | PosixExtra.TIOCM_RTS;
        Posix.ioctl( _portfd, PosixExtra.TIOCMBIS, &_v24 );

        // setup watches, if we have delegates
        if ( _hupfunc != null || _readfunc != null )
        {
            _channel = new IOChannel.unix_new( _portfd );
            _watch = _channel.add_watch( IOCondition.IN | IOCondition.HUP, _actionCallback );
        }

        return true;
    }

    public int read( void* data, int len )
    {
        assert( _portfd != -1 );
        ssize_t bytesread = Posix.read( _portfd, data, len );
        return (int)bytesread;
    }

    public int write( void* data, int len )
    {
        assert( _portfd != -1 );
        ssize_t byteswritten = Posix.write( _portfd, data, len );
        return (int)byteswritten;
    }

    public bool _actionCallback( IOChannel source, IOCondition condition )
    {
        debug( "_actionCallback, condition = %d", condition );
        if ( IOCondition.IN == condition && _readfunc != null )
        {
            _readfunc( this );
            return true;
        }
        if ( IOCondition.HUP == condition && _hupfunc != null )
            _hupfunc( this );
        return false;
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
    }
}
//===========================================================================
public delegate void HupFunc( Serial serial );
public delegate void ReadFunc( Serial serial );
