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

    public bool InitSession( bool advanced, int framesize, string port, int portspeed )
    {
        debug( "InitSession requested for mode %s, framesize %d, port %s @ %d", advanced? "advanced":"basic", framesize, port, portspeed );
        if ( muxer != null )
        {
            error( "muxer already initialized" );
            return false;
            //FIXME raise dbus error
        }
        else
        {
            muxer = new Multiplexer( advanced, framesize, port, portspeed );
            if ( !muxer.initSession() )
            {
                error( "can't initialize muxer session" );
                return false;
                //FIXME raise dbus error
            }
            return true;
        }
    }

    public void CloseSession()
    {
        debug( "CloseSession requested" );
        if ( muxer == null )
        {
            error( "muxer not yet initialized" );
            //FIXME raise dbus error
        }
        else
        {
            muxer.closeSession();
            muxer = null;
        }
    }

    public string AllocChannel( string name, int channel )
    {
        debug( "AllocChannel requested for name %s, requested channel %d", name, channel );
        if ( muxer == null )
        {
            error( "muxer not yet initialized" );
            return "";
            //FIXME raise dbus error
        }
        else
            return muxer.allocChannel( name, channel );
    }

    public void ReleaseChannel( string name )
    {
        debug( "ReleaseChannel requested for name %s", name );
        if ( muxer == null )
        {
            error( "muxer not yet initialized" );
            //FIXME raise dbus error
        }
        else
            muxer.releaseChannel( name );
    }

    public void _shutdown()
    {
        debug( "_shutdown" );
        if ( muxer != null )
        {
            muxer.closeSession();
            muxer = null;
        }
    }

}
