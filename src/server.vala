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
public abstract interface OrgFreesmartphoneGsmMux
{
    public abstract string GetVersion() throws DBus.Error;
    public abstract bool HasAutoSession() throws DBus.Error;
    public abstract void OpenSession( bool advanced, int framesize, string port, int portspeed ) throws DBus.Error;
    public abstract void CloseSession() throws DBus.Error;
    public abstract void AllocChannel( string name, int channel, out string path, out int allocated_channel ) throws DBus.Error;
    public abstract void ReleaseChannel( string name ) throws DBus.Error;
    public abstract void SetWakeupThreshold( uint seconds, uint waitms ) throws DBus.Error;
    public abstract void SetStatus( int channel, string status ) throws DBus.Error;
    public signal void Status( int channel, string status );
    public abstract void TestCommand( uint8[] data ) throws DBus.Error;
}

//===========================================================================
public class Server : OrgFreesmartphoneGsmMux, Object
{
    DBus.Connection conn;
    dynamic DBus.Object dbus;

    Gsm0710mux.Manager manager;

    public Server()
    {
        try
        {
            debug( "DBus-Server: created" );
            conn = DBus.Bus.get( DBus.BusType.SYSTEM );
            dbus = conn.get_object( DBUS_BUS_NAME, DBUS_OBJ_PATH, DBUS_INTERFACE );
        } catch ( DBus.Error e )
        {
            error( "DBus-Server: %s", e.message );
        }

        manager = new Gsm0710mux.Manager();
    }

    ~Server()
    {
        debug( "DBus-Server: destructed" );
    }

    //
    // DBus API
    //

    public string GetVersion() throws DBus.Error
    {
        return manager.getVersion();
    }

    public bool HasAutoSession() throws DBus.Error
    {
        return manager.hasAutoSession();
    }

    public void OpenSession( bool advanced, int framesize, string port, int portspeed ) throws DBus.Error
    {
        manager.openSession( advanced, framesize, port, portspeed );
    }

    public void CloseSession() throws DBus.Error
    {
        manager.closeSession();
    }

    public void AllocChannel( string name, int channel, out string path, out int allocated_channel ) throws DBus.Error
    {
        debug( "AllocChannel requested for name %s, requested channel %d", name, channel );

        var ci = Gsm0710mux.ChannelInfo();
        ci.type = Gsm0710mux.ChannelType.PTY;
        ci.consumer = name;
        ci.number = channel;

        manager.allocChannel( ref ci );

        path = ci.transport;
        allocated_channel = ci.number;
    }

    public void ReleaseChannel( string name ) throws DBus.Error
    {
        manager.releaseChannel( name );
    }

    public void SetWakeupThreshold( uint seconds, uint waitms ) throws DBus.Error
    {
        manager.setWakeupThreshold( seconds, waitms );
    }

    public void SetStatus( int channel, string status ) throws DBus.Error
    {
        manager.setStatus( channel, status );
    }

    public void TestCommand( uint8[] data ) throws DBus.Error
    {
        manager.testCommand( data );
    }

}
