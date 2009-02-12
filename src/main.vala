/*
 * main.vala
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

Server server;
MainLoop loop;

//===========================================================================
public static void SIGINT_handler( int signal )
{
    debug( "SIGINT handler called" );
    if ( server != null )
    {
        server._shutdown();
        loop.quit();
    }
}

//===========================================================================
public static void LOG_handler( string? log_domain, LogLevelFlags log_levels, string message )
{
    var t = TimeVal();
    stdout.printf( "%s: %s\n", t.to_iso8601(), message );
}

//===========================================================================
void main()
{
    loop = new MainLoop( null, false );

    try
    {
        var conn = DBus.Bus.get( DBus.BusType.SYSTEM );

        dynamic DBus.Object bus = conn.get_object( DBUS_BUS_NAME, DBUS_OBJ_PATH, DBUS_INTERFACE );
        // try to register service in session bus
        uint request_name_result = bus.request_name( MUXER_BUS_NAME, (uint) 0 );

        if ( request_name_result == DBus.RequestNameReply.PRIMARY_OWNER )
        {
            Log.set_handler( null, LogLevelFlags.LEVEL_DEBUG, LOG_handler );
            Posix.signal( Posix.SIGINT, SIGINT_handler );

            server = new Server();
            conn.register_object( MUXER_OBJ_PATH, server );

            loop.run();
        }
        else
        {
            error( "Can't register bus name. Service already started?\n" );
        }
    } catch (Error e) {
        error( "Oops: %s\n", e.message );
    }
}

