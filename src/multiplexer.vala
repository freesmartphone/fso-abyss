/*
 * multiplexer.vala
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
using CONST;
using Gsm0710;

//===========================================================================
// callback forwarders
//

public static bool at_command_fwd( Context ctx, string command )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    return m.at_command( command );
}

public static int read_fwd( Context ctx, void* data, int len )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    return m.read( data, len );
}

public static bool write_fwd( Context ctx, void* data, int len )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    return m.write( data, len );
}

public static void deliver_data_fwd( Context ctx, int channel, void* data, int len )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.deliver_data( channel, data, len );
}

public static void deliver_status_fwd( Context ctx, int channel, int status )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.deliver_status( channel, status );
}

public static void debug_message_fwd( Context ctx, string msg )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.debug_message( msg );
}

public static void open_channel_fwd( Context ctx, int channel )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.open_channel( channel );
}

public static void close_channel_fwd( Context ctx, int channel )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.close_channel( channel );
}

public static void terminate_fwd( Context ctx )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.terminate();
}

public static void response_to_test_fwd( Context ctx, char[] data )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.response_to_test( data );
}

//===========================================================================
// The Multiplexer class
//
public class Multiplexer
{
    Server server;

    string portname;
    Context ctx;
    int portfd = -1;
    IOChannel portchannel;
    uint portwatch;
    uint portspeed;

    uint pingwatch;

    Timer idle_wakeup_timer;
    uint idle_wakeup_threshold;
    uint idle_wakeup_waitms;

    Channel[] vc = new Channel[MAX_CHANNELS];

    public Multiplexer( bool advanced, int framesize, string portname_, int portspeed_, Server server_ )
    {
        portname = portname_;
        portspeed = portspeed_;
        server = server_;

        ctx = new Context();
        ctx.initialize();

        ctx.mode = advanced? 1 : 0;
        ctx.frame_size = framesize;
        ctx.port_speed = portspeed_;

        ctx.user_data = this;

        ctx.at_command = at_command_fwd;
        ctx.read = read_fwd;
        ctx.write = write_fwd;
        ctx.deliver_data = deliver_data_fwd;
        ctx.deliver_status = deliver_status_fwd;
        ctx.debug_message = debug_message_fwd;
        ctx.open_channel = open_channel_fwd;
        ctx.close_channel = close_channel_fwd;
        ctx.terminate = terminate_fwd;
        ctx.response_to_test = response_to_test_fwd;

        debug( "%s: constructed", repr() );
    }

    ~Multiplexer()
    {
        debug( "%s: destructed", repr() );
    }

    public string repr()
    {
        return "<Multiplexer 07.10-%s Framesize %d via %s @ %d>".printf( ( ctx.mode == 1? "advanced":"basic" ), ctx.frame_size, portname, ctx.port_speed );
    }

    public bool initSession()
    {
        debug( "%s: init session", repr() );

        if ( !openSerial() )
            return false;

        portchannel = new IOChannel.unix_new( portfd );
        portwatch = portchannel.add_watch( IOCondition.IN, device_io_can_read );

        // make sure we're out of MUX mode
        ctx.shutdown();

        bool ok;

        if ( ctx.mode == 0 )
        {
            if (!at_command( "AT+CMUX=0\r\n" ) )
                return false;
            ok = ctx.startup( false );
        }
        else
        {
            ok = ctx.startup( true );
        }

        /*
        if (ok)
            Timeout.add_seconds( GSM_PING_SEND_TIMEOUT, protocol_ping_send_timeout );
        */

        return ok;
    }

    public void closeSession()
    {
        debug( "closeSession" );
        for ( int i = 1; i < MAX_CHANNELS; ++i )
            if ( vc[i] != null )
                vc[i].close();

        ctx.shutdown();

        portchannel = null;
        if ( portfd != -1 )
            PosixExtra.close( portfd );
    }

    public void allocChannel( string name, int chan, out string path, out int allocated_channel ) throws GLib.Error
    {
        int channel = chan;
        if ( chan == 0 )
        {
            // find the first free one
            int i = 1;
            while ( channel == 0 && i < MAX_CHANNELS && vc[i] != null )
                ++i;
            channel = i;
        }

        debug( "allocChannel requested for name %s, requested channel %d", name, channel );
        // lets check whether we already have this channel
        if ( vc[channel] != null )
            throw new MuxerError.ChannelTaken( "Channel is already taken." );

        var ok = ctx.openChannel( channel );
        assert( ok );
        debug( "0710 open channel returned result %d", (int)ok );
        vc[channel] = new Channel( this, name, channel );

        var t = new Timer();
        t.start();

        var mc = MainContext.default();
        var ack = false;

        // FIXME: Ok, I don't like that, but until Vala supports asnyc dbus
        // on server side, we have to live with it.
        do
        {
            mc.iteration( false );
            ack = ( vc[channel].isAcked() );
        }
        while ( !ack && t.elapsed() < GSM_OPEN_CHANNEL_ACK_TIMEOUT );

        if ( ack )
        {
            path = vc[channel].path();
            allocated_channel = channel;
        }
        else
        {
            vc[channel] = null;
            throw new MuxerError.NoChannel( "Modem does not provide this channel." );
        }
    }

    public void releaseChannel( string name ) throws GLib.Error
    {
        debug( "releaseChannel requested for name %s", name );
        bool closed = false;
        for ( int i = 1; i < MAX_CHANNELS; ++i )
        {
            if ( vc[i] != null && vc[i].name() == name )
            {
                vc[i].close();
                closed = true;
            }
        }
        if ( !closed )
            throw new MuxerError.NoChannel( "Could not find any channel with that name." );
    }

    public void setStatus( int channel, string status ) throws GLib.Error
    {
        debug( "setStatus requested for channel %d", channel );
        if ( vc[channel] == null )
            throw new MuxerError.NoChannel( "Could not find channel with that index." );

        // FIXME: ...
    }

    public void setWakeupThreshold( int seconds, int waitms ) throws GLib.Error
    {
        if ( seconds < 0 ) /* disable */
            idle_wakeup_timer = null;

        if ( idle_wakeup_timer == null )
        {
            idle_wakeup_timer = new Timer();
            idle_wakeup_timer.start();
        }

        idle_wakeup_threshold = seconds;
        idle_wakeup_waitms = waitms;

    }

    public void testCommand( string data ) throws GLib.Error
    {
        debug( "muxer: testCommand" );
        ctx.sendTest( data, (int)data.size() );
    }

    //
    // internal helpers
    //
    public bool openSerial()
    {
        portfd = PosixExtra.open( portname, PosixExtra.O_RDWR | PosixExtra.O_NOCTTY | PosixExtra.O_NONBLOCK );
        if ( portfd == -1 )
            return false;

        Posix.fcntl( portfd, Posix.F_SETFL, 0 );

        PosixExtra.TermIOs termios = {};
        PosixExtra.tcgetattr( portfd, termios );

        assert( portspeed == 115200 );

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
        termios.c_cc[PosixExtra.VMIN] = 1;
        termios.c_cc[PosixExtra.VTIME] = 0;
        termios.c_cc[PosixExtra.VINTR] = 0;
        termios.c_cc[PosixExtra.VQUIT] = 0;
        termios.c_cc[PosixExtra.VSTART] = 0;
        termios.c_cc[PosixExtra.VSTOP] = 0;
        termios.c_cc[PosixExtra.VSUSP] = 0;

        PosixExtra.tcsetattr( portfd, PosixExtra.TCSAFLUSH, termios);

        int status = PosixExtra.TIOCM_DTR | PosixExtra.TIOCM_RTS;
        Posix.ioctl( portfd, PosixExtra.TIOCMBIS, &status );

        return true;
    }

    public bool writefd( string command, int fd )
    {
        var readfds = new PosixExtra.FdSet();
        var writefds = new PosixExtra.FdSet();
        var exceptfds = new PosixExtra.FdSet();
        writefds.set( fd );
        PosixExtra.TimeVal t = { 1, 0 };
        debug( ":::writefd select for fd %d", fd );
        int res = PosixExtra.select( fd+1, readfds, writefds, exceptfds, t );
        if ( res < 0 || !writefds.isSet(fd) )
            return false;
        ssize_t bwritten = PosixExtra.write( fd, command, command.size() );
        PosixExtra.tcdrain( portfd );
        debug( ":::writefd written %d bytes", (int)bwritten );
        return ( (int)bwritten == command.size() );
    }

    public string readfd( int fd )
    {
        var readfds = new PosixExtra.FdSet();
        var writefds = new PosixExtra.FdSet();
        var exceptfds = new PosixExtra.FdSet();
        readfds.set( fd );
        PosixExtra.TimeVal t = { 1, 0 };
        char[] buffer = new char[512];
        debug( ":::readfd select for fd %d", fd );
        int res = PosixExtra.select( fd+1, readfds, writefds, exceptfds, t );
        if ( res < 0 || !readfds.isSet( fd ) )
            return "";
        ssize_t bread = PosixExtra.read( fd, buffer, 512 );
        debug( ":::readfd read %d bytes", (int)bread );
        return (string) buffer;
    }

    public int channelByName( string name )
    {
        for ( int i = 1; i < MAX_CHANNELS; ++i )
        {
            if ( vc[i] != null && vc[i].name() == name )
                return i;
        }
        return 0;
    }

    public string serialStatusToString( int status )
    {
        var sb = new StringBuilder();
        if ( ( status & SerialStatus.FC ) == SerialStatus.FC )
            sb.append( "FC ");
        if ( ( status & SerialStatus.DSR ) == SerialStatus.DSR )
            sb.append( "DSR ");
        if ( ( status & SerialStatus.CTS ) == SerialStatus.CTS )
            sb.append( "CTS ");
        if ( ( status & SerialStatus.RING ) == SerialStatus.RING )
            sb.append( "RING ");
        if ( ( status & SerialStatus.DCD ) == SerialStatus.DCD )
            sb.append( "DCD ");
        return sb.str;
    }

    public void clearPingResponseTimeout()
    {
        if ( pingwatch != 0 )
            Source.remove( pingwatch );
    }

    //
    // callbacks from channel
    //
    public void submit_data( int channel, void* data, int len )
    {
        debug( "channel -> submit_data" );

        if ( idle_wakeup_timer != null )
        {
            var elapsed = idle_wakeup_timer.elapsed();
            if ( elapsed > idle_wakeup_threshold )
            {
                debug( "channel has been idle for %.2f seconds, waking up", elapsed );
                var wakeup = new char[] { 'W', 'A', 'K', 'E', 'U', 'P', '!' };
                ctx.sendTest( wakeup, wakeup.length );
                Thread.usleep( 1000 * idle_wakeup_waitms );
            }
        }

        ctx.writeDataForChannel( channel, data, len );
    }

    public void channel_closed( int channel )
    {
        debug( "channel -> closed" );
        ctx.closeChannel( channel );
        vc[channel] = null;
        server.channelHasBeenClosed();
    }

    //
    // callbacks from 0710 core
    //
    public bool at_command( string command )
    {
        debug( "0710 -> should send at_command '%s'", command );

        while ( readfd( portfd ) != "" ) ;

        // first, send something to wake up
        writefd( "ATE0Q0V1\r\n", portfd );
        // then, read until there is nothing to read
        while ( readfd( portfd ) != "" ) ;
        // now, write the actual command
        writefd( command, portfd );
        // and read the result
        string res = "";
        string r = "";

        do
        {
            r = readfd( portfd );
            res += r;
        } while (r != "");

        debug( " -> answer = %s", res );

        if ( "\r\nOK" in res )
        {
            debug( " -> answer OK" );
            return true;
        }
        else
        {
            debug( " -> answer NOT ok" );
            return false;
        }
    }

    public int read( void* data, int len )
    {
        debug( "0710 -> should read max %d bytes to %p", len, data );
        if ( idle_wakeup_timer != null )
            idle_wakeup_timer.reset();

        var number = PosixExtra.read( portfd, data, len );
        debug( "read %d bytes from fd %d", (int)number, portfd );
        hexdebug( false, data, (int)number );
        if ( number == -1 )
            error( "read error fd %d: %s", portfd, Posix.strerror( Posix.errno ) );
        return (int)number;
    }

    public bool write( void* data, int len )
    {
        debug( "0710 -> should write %d bytes", len );
        if ( idle_wakeup_timer != null )
            idle_wakeup_timer.reset();

        hexdebug( true, data, len );
        var number = PosixExtra.write( portfd, data, len );
        // FIXME: necessary always?
        PosixExtra.tcdrain( portfd );
        if ( number > 0 )
            debug( "wrote %d/%d bytes to fd %d", (int)number, len, portfd );
        else
            warning( "could not write to fd %d: %s", portfd, Posix.strerror( Posix.errno ) );
        return ( number > 0 );
    }

    public void deliver_data( int channel, void* data, int len )
    {
        debug( "0710 -> deliver %d bytes for channel %d", len, channel );
        if ( vc[channel] == null )
        {
            debug( "::::should deliver bytes for unknown channel: ignoring" );
        }
        else
        {
            vc[channel].deliverData( data, len );
        }
        clearPingResponseTimeout();
    }

    public void deliver_status( int channel, int serial_status )
    {
        string status = serialStatusToString( serial_status );
        debug( "0710 -> deliver status %d = '%s' for channel %d", serial_status, status, channel );
        if ( vc[channel] == null )
        {
            debug( ":::should deliver status for unknown channel: ignoring" );
        }
        else
        {
            if ( !vc[channel].isAcked() )
                vc[channel].acked();

            server.Status( channel, status );
        }
        clearPingResponseTimeout();
    }

    public void debug_message( string msg )
    {
        debug( "0710 -> say '%s", msg );
    }

    public void open_channel( int channel )
    {
        debug( "0710 -> open channel %d", channel );
    }

    public void close_channel( int channel )
    {
        debug( "0710 -> close channel %d", channel );
    }

    public void terminate()
    {
        debug( "0710 -> terminate" );
    }

    public void response_to_test( char[] data )
    {
        var b = new StringBuilder();
        foreach( var c in data )
            b.append_printf( "%c", c );
        debug( "0710 -> response to test (%d bytes): %s", data.length, b.str );
        clearPingResponseTimeout();
    }
    //
    // callbacks from glib
    //
    public bool device_io_can_read( IOChannel source, IOCondition condition )
    {
        assert( condition == IOCondition.IN );
        debug( "device_io_can_read for fd %d", source.unix_get_fd() );

        ctx.readyRead();

        return true; // call me again
    }

    public bool protocol_ping_response_timeout()
    {
        debug( "\n*\n*\n* PING TIMEOUT !!!\n*\n*\n*" );
        return true;
    }

    public bool protocol_ping_send_timeout()
    {
        var data = new char[] { 'P', 'I', 'N', 'G' };
        ctx.sendTest( data, data.length );

        if ( pingwatch != 0 )
            Source.remove( pingwatch );
        pingwatch = Timeout.add_seconds( GSM_PING_RESPONSE_TIMEOUT, protocol_ping_response_timeout );
        return true;
    }
}
