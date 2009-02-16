/*
 * server.vala - dbus server implementation, parameter validation
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

//===========================================================================
[DBus (name = "org.freesmartphone.GSM.MUX")]
public class Server : Object
{
    DBus.Connection conn;
    dynamic DBus.Object dbus;

    Multiplexer muxer;
    KeyFile config;

    bool autoopen = false;
    bool autoclose = false;
    bool autoexit = true;
    string session_path = "/dev/ttySAC0";
    uint session_speed = 115200;
    bool session_mode = true;
    uint session_framesize = 64;

    uint channelsOpen;

    public Server()
    {
        try
        {
            debug( "Server: created" );
            conn = DBus.Bus.get( DBus.BusType.SYSTEM );
            dbus = conn.get_object( DBUS_BUS_NAME, DBUS_OBJ_PATH, DBUS_INTERFACE );
        } catch ( DBus.Error e )
        {
            error( "Server: %s", e.message );
        }

        config = new KeyFile();
        try
        {
            config.load_from_file( CONFIG_FILENAME, KeyFileFlags.NONE );
            debug( "Server: read config from %s", CONFIG_FILENAME );
        }
        catch ( GLib.Error e )
        {
            warning( "Server: could not read config file: %s", e.message );
            config = null;
        }
        if ( config != null )
        {
            try
            {
                autoopen = config.get_boolean( "omuxerd", "autoopen" );
                autoclose = config.get_boolean( "omuxerd", "autoclose" );
                autoexit = config.get_boolean( "omuxerd", "autoexit" );
                session_path = config.get_string( "session", "port" );
                session_speed = config.get_integer( "session", "speed" );
                session_mode = config.get_boolean( "session", "mode" );
                session_framesize = config.get_integer( "session", "framesize" );
            }
            catch ( GLib.Error e )
            {
                warning( "Server: config error: %s", e.message );
            }
        }
    }

    ~Server()
    {
        debug( "Server: destructed" );
    }

    public void _shutdown()
    {
        debug( "_shutdown" );
        if ( muxer != null )
        {
            muxer.closeSession();
            muxer = null;
        }
        if ( autoexit )
            loop.quit();
    }

    public void channelHasBeenClosed()
    {
        channelsOpen--;
        if ( channelsOpen == 0 && autoclose )
            _shutdown();
    }

    //
    // DBus API
    //

    public string GetVersion()
    {
        return MUXER_VERSION;
    }

    public bool hasAutoSession()
    {
        return autoopen;
    }

    public void OpenSession( bool advanced, int framesize, string port, int portspeed ) throws DBus.Error, GLib.Error
    {
        debug( "InitSession requested for mode %s, framesize %d, port %s @ %d", advanced? "advanced":"basic", framesize, port, portspeed );
        if ( muxer != null )
        {
            throw new MuxerError.SessionAlreadyOpen( "Close session before opening another one." );
        }
        else
        {
            muxer = new Multiplexer( advanced, framesize, port, portspeed, this );
            if ( !muxer.initSession() )
            {
                muxer = null;
                throw new MuxerError.SessionOpenError( "Can't initialize the session" );
            }
        }
    }

    public void CloseSession() throws DBus.Error, GLib.Error
    {
        debug( "CloseSession requested" );
        if ( muxer == null )
        {
            throw new MuxerError.NoSession( "Session has to be initialized first." );
        }
        else
        {
            muxer.closeSession();
            muxer = null;
        }
    }

    public void AllocChannel( string name, int channel, out string path, out int allocated_channel ) throws DBus.Error, GLib.Error
    {
        debug( "AllocChannel requested for name %s, requested channel %d", name, channel );

        if ( autoopen )
        {
            debug( "AutoOpen!" );
            OpenSession( session_mode, (int)session_framesize, session_path, (int)session_speed );
        }

        if ( channel < 0 )
        {
            throw new MuxerError.InvalidChannel( "Channel has to be >= 0" );
        }

        if ( muxer == null )
        {
            throw new MuxerError.NoSession( "Session has to be initialized first." );
        }
        else
        {
            muxer.allocChannel( name, channel, out path, out allocated_channel );
            channelsOpen++;
        }
    }

    public void ReleaseChannel( string name ) throws DBus.Error, GLib.Error
    {
        debug( "ReleaseChannel requested for name %s", name );
        if ( muxer == null )
        {
            throw new MuxerError.NoSession( "Session has to be initialized first." );
        }
        else
            muxer.releaseChannel( name );
    }

    public void SetWakeupThreshold( int seconds, int waitms ) throws DBus.Error, GLib.Error
    {
        debug( "SetWakeupThreshold to wakeup before transmitting data after %d seconds of idleness", seconds );
        if ( muxer == null )
        {
            throw new MuxerError.NoSession( "Session has to be initialized first." );
        }
        else
            muxer.setWakeupThreshold( seconds, waitms );
    }

    public void SetStatus( int channel, string status ) throws DBus.Error, GLib.Error
    {
        debug( "SetStatus requested for channel %d, status = %s", channel, status );
        if ( muxer == null )
        {
            throw new MuxerError.NoSession( "Session has to be initialized first." );
        }
        else
            muxer.setStatus( channel, status );
    }

    public signal void Status( int channel, string status );

    public void TestCommand( string data ) throws DBus.Error, GLib.Error
    {
        debug( "TestCommand: %s", data );
        muxer.testCommand( data );
    }

}
