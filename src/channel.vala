/*
 * channel.vala
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
// The Channel class
//
public class Channel
{
    public enum Status
    {
        Requested,  /* requested on 07.10 layer, but not acknowledged by modem */
        Acked,      /* acknowledged by modem, but not opened by any client */
        Open,       /* acknowledged and opened by a client */
        Denied,     /* denied by the modem. this status is persistent */
        Shutdown,   /* shutting down, will no longer be openable */
    }

    Status _status;
    string _name;
    int _number;
    int _serial_status;

    public Channel( string name, int number )
    {
        debug( "Channel %s = %d created", name, number );
        _status = Status.Requested;
        _name = name;
        _number = number;
    }

    public string acked()
    {
        debug( "Channel now acked! creating pty" );
        // open pty
        _status = Status.Acked;
        return "/this/path/not/valid";
    }

    public void close()
    {
        debug( "close()" );
        // close pty, if open
        _status = Status.Shutdown;
    }

    public string name()
    {
        return _name;
    }

    public Status status()
    {
        return _status;
    }

    public void setSerialStatus( int s )
    {
        debug( "setSerialStatus()" );
        _serial_status = s;
        // emit dbus signal or send send condition via pty
    }
}
