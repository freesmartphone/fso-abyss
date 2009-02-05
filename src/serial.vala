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
// The Serial class
//
public class Serial
{
    string _portname;
    uint _portspeed;
    int _portfd = -1;
    uint _v24;

    public Serial( string portname, uint portspeed )
    {
        _portname = portname;
        _portspeed = portspeed;
    }

    public bool isOpen()
    {
        return ( _portfd != -1 );
    }

    public int openRaw()
    {
        _portfd = PosixExtra.open( _portname, PosixExtra.O_RDWR | PosixExtra.O_NOCTTY | PosixExtra.O_NONBLOCK );
        if ( _portfd == -1 )
        {
            warning( "could not open %s: %s", _portname, Posix.strerror( Posix.errno ) );
            return _portfd;
        }

        Posix.fcntl( _portfd, Posix.F_SETFL, 0 );

        PosixExtra.TermIOs termios = new PosixExtra.TermIOs();
        PosixExtra.tcgetattr( _portfd, termios );

        // other speeds not implemented yet
        assert( _portspeed == 115200 );

        // 115200
        PosixExtra.cfsetispeed( termios, PosixExtra.B115200 );
        PosixExtra.cfsetospeed( termios, PosixExtra.B115200 );

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

        return _portfd;
    }

    ~Serial()
    {
        debug( "Serial Port %s (%ud) destructed", _portname, _portspeed );
    }

}
