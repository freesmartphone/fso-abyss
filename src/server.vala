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

    construct
    {
        try
        {
            debug( "server object created" );
            conn = DBus.Bus.get( DBus.BusType.SYSTEM );
            dbus = conn.get_object( DBUS_BUS_NAME, DBUS_OBJ_PATH, DBUS_INTERFACE );
        } catch (DBus.Error e) {
            error( e.message );
        }
    }

    public string GetVersion()
    {
        return MUXER_VERSION;
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
        if ( channel < 0 )
        {
            throw new MuxerError.InvalidChannel( "Channel has to be >= 0" );
        }

        if ( muxer == null )
        {
            throw new MuxerError.NoSession( "Session has to be initialized first." );
        }
        else
            muxer.allocChannel( name, channel, out path, out allocated_channel );
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

    public void SetStatus( int channel, string status ) throws DBus.Error, GLib.Error
    {
        debug( "SetStatus requested for channel %d, status = %s", channel, status );
        muxer.setStatus( channel, status );
    }

    public signal void Status( int channel, string status );

    public void _shutdown()
    {
        debug( "_shutdown" );
        if ( muxer != null )
        {
            muxer.closeSession();
            muxer = null;
        }
    }

    public void TestCommand( string data ) throws DBus.Error, GLib.Error
    {
        debug( "TestCommand: %s", data );
        muxer.testCommand( data );
    }

}
