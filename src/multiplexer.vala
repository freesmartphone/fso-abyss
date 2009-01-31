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

//===========================================================================
// The Multiplexer class
//
public class Multiplexer
{
    string portname;
    Context ctx;
    int portfd = -1;
    IOChannel portchannel;
    uint portwatch;

    Channel[] vc = new Channel[MAX_CHANNELS];

    public Multiplexer( bool advanced, int framesize, string portname_, int portspeed )
    {
        debug( "Multiplexer created for mode %s, framesize %d, device %s @ %d", advanced? "advanced":"basic", framesize, portname_, portspeed );
        portname = portname_;
        ctx = new Context();
        ctx.initialize();

        ctx.server = 0;
        ctx.mode = advanced? 1 : 0;
        ctx.frame_size = framesize;
        ctx.port_speed = portspeed;

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
    }

    public bool initSession()
    {
        debug( "initSession" );
        portfd = PosixExtra.open( portname, PosixExtra.O_RDWR ); // | PosixExtra.O_NOCTTY | PosixExtra.O_NONBLOCK );
        if ( portfd == -1 )
            return false;

        portchannel = new IOChannel.unix_new( portfd );
        portwatch = portchannel.add_watch( IOCondition.IN, device_io_can_read );

        //return ctx.startup( true );
        if ( ctx.mode == 0 )
        {
            at_command( "AT+CMUX=0\r\n" );
            return ctx.startup( false );
        }
        else
        {
            return ctx.startup( true );
        }
    }

    public void closeSession()
    {
        debug( "closeSession" );
        for ( int i = 1; i < MAX_CHANNELS; ++i )
            if ( vc[i] != null )
                if ( vc[i].status() == Channel.Status.Acked )
                    vc[i].close();

        ctx.shutdown();

        portchannel = null;
        if ( portfd != -1 )
            PosixExtra.close( portfd );
    }

    public string allocChannel( string name, int channel )
    {
        debug( "allocChannel requested for name %s, requested channel %d", name, channel );
        var ok = ctx.openChannel( channel );
        assert( ok );
        debug( "0710 open channel returned result %d", (int)ok );
        vc[channel] = new Channel( name, channel );
        //FIXME return pts
        return "";
    }

    public void releaseChannel( string name )
    {
        debug( "releaseChannel requested for name %s", name );
        for ( int i = 1; i < MAX_CHANNELS; ++i )
        {
            if ( vc[i] != null && vc[i].name() == name )
            {
                vc[i].close();
                ctx.closeChannel( i );
            }
        }
    }

    //
    // internal helpers
    //
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
        debug( "::writefd written %d bytes", (int)bwritten );
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
        debug( "::readfd read %d bytes", (int)bread );
        return (string) buffer;
    }

    //
    // callbacks from 0710 core
    //
    public bool at_command( string command )
    {
        debug( "0710 -> should send at_command '%s'", command );

        while ( readfd( portfd ) != "" ) ;

        // first, send something to wake up
        writefd( "AT\r\n", portfd );
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
        var number = PosixExtra.read( portfd, data, len );
        debug( "read %d bytes from fd %d", (int)number, portfd );
        hexdebug( data, (int)number );
        if ( number == -1 )
            error( "read error fd %d: %s", portfd, Posix.strerror( Posix.errno ) );
        return (int)number;
    }

    public bool write( void* data, int len )
    {
        debug( "0710 -> should write %d bytes", len );
        hexdebug( data, len );
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
    }

    public void deliver_status( int channel, int serial_status )
    {
        debug( "0710 -> deliver status %d for channel %d", serial_status, channel );
        assert( vc[channel] != null );
        if ( vc[channel].status() == Channel.Status.Requested )
        {
            vc[channel].acked(); // submit serial status
        }
        else
            vc[channel].setSerialStatus( serial_status );
    }

    public void debug_message( string msg )
    {
        debug( "debug messages from 0710 core: '%s", msg );
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
}
