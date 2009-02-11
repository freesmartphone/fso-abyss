/*
 * const.vala: constants and helper functions
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

namespace CONST
{
    //===========================================================================
    public const string DBUS_BUS_NAME  = "org.freedesktop.DBus";
    public const string DBUS_OBJ_PATH  = "/org/freedesktop/DBus";
    public const string DBUS_INTERFACE = "org.freedesktop.DBus";
    public const string DBUS_INTERFACE_INTROSPECTABLE = "org.freedesktop.DBus.Introspectable";

    public const string MUXER_BUS_NAME  = "org.freesmartphone.omuxerd";
    public const string MUXER_OBJ_PATH  = "/org/freesmartphone/GSM/Muxer";
    public const string MUXER_INTERFACE = "org.freesmartphone.GSM.MUX";
    public const string MUXER_VERSION   = "0.0.0";

    public const double GSM_OPEN_CHANNEL_ACK_TIMEOUT = 2.0;
    public const uint GSM_PING_SEND_TIMEOUT = 5;
    public const uint GSM_PING_RESPONSE_TIMEOUT = 3;

    public errordomain MuxerError {
        ChannelTaken,
        InvalidChannel,
        NoSession,
        NoChannel,
        SessionAlreadyOpen,
        SessionOpenError,
    }

    //===========================================================================
    public void hexdebug( bool write, void* data, int len )
    {
        if ( len < 1 )
            return;

        int BYTES_PER_LINE = 16;

        uchar* pointer = (uchar*) data;
        var hexline = new StringBuilder( write? ">>> " : "<<< " );
        var ascline = new StringBuilder();
        uchar b;
        int i;

        for ( i = 0; i < len; ++i )
        {
            b = pointer[i];
            hexline.append_printf( "%02X ", b );
            if ( 31 < b && b < 128 )
                ascline.append_printf( "%c", b );
            else
                ascline.append_printf( "." );
            if ( i % BYTES_PER_LINE+1 == BYTES_PER_LINE )
            {
                debug( "%s", hexline.str + " " + ascline.str );
                hexline = new StringBuilder( write? ">>> " : "<<< " );
                ascline = new StringBuilder();
            }
        }
        if ( i % BYTES_PER_LINE+1 != BYTES_PER_LINE )
            debug( "%s", hexline.str + " " + ascline.str );
    }
}
