/* posixextra.vapi
 *
 * Scheduled for inclusion in posix.vapi
 */

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace PosixExtra {
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_ACCMODE;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_RDONLY;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_WRONLY;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_RDWR;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_CREAT;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_EXCL;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_NOCTTY;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_TRUNC;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_APPEND;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_NONBLOCK;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_SYNC;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_ASYNC;
	[CCode (cheader_filename = "fcntl.h")]
	public int open (string path, int oflag);

    [CCode (cname = "fd_set", cheader_filename = "sys/select.h", free_function = "")]
    [Compact]
    public class FdSet
    {
        //[CCode (cname = "FD_ZERO")]
        //public FdSet ();
        [CCode (cname = "FD_CLR", instance_pos=1.1)]
        public void clear (int fd);
        [CCode (cname = "FD_ISSET", instance_pos=1.1)]
        public bool isSet (int fd);
        [CCode (cname = "FD_SET", instance_pos=1.1)]
        public void set (int fd);
        [CCode (cname = "FD_ZERO")]
        public void zero ();
    }

    [CCode (cname = "struct timeval", cheader_filename = "time.h")]
    [Compact]
    public struct TimeVal
    {
        public long tv_sec;
        public long tv_usec;
    }

    /* ------------- pty --------------- */

    [CCode (cheader_filename = "pty.h")]
    public int openpty (out int amaster,
                        out int aslave,
                        [CCode (array_length=false, array_null_terminated=true)] char[] name,
                        TermIOs? termp,
                        WinSize? winp);

    [CCode (cheader_filename = "sys/select.h")]
    public int select (int nfds, FdSet readfds, FdSet writefds, FdSet exceptfds, TimeVal timeval);

    /* -------- signal -------------------- */
    [CCode (cheader_filename = "signal.h")]
    public const int SIGHUP;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGINT;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGQUIT;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGILL;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGTRAP;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGABRT;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGIOT;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGBUS;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGFPE;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGKILL;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGUSR1;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGSEGV;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGUSR2;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGPIPE;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGALRM;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGTERM;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGSTKFLT;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGCLD;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGCHLD;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGCONT;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGSTOP;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGTSTP;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGTTIN;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGTTOU;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGURG;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGXCPU;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGXFSZ;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGVTALRM;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGPROF;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGWINCH;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGPOLL;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGIO;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGPWR;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGSYS;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGUNUSED;

    public static delegate void sighandler_t (int signal);

    [CCode (cheader_filename = "signal.h")]
    public sighandler_t signal (int signum, sighandler_t handler);

    /* --------- stdlib --------------- */
    [CCode (cheader_filename = "stdlib.h")]
    public int posix_openpt (int flags);

    [CCode (cheader_filename = "stdlib.h")]
    int ptsname_r (int fd, char[] buf);

    [CCode (cheader_filename = "stdlib.h")]
    public int grantpt (int fd);

    [CCode (cheader_filename = "stdlib.h")]
    public int unlockpt (int fd);

    /* ---------------------------- */

	[CCode (cheader_filename = "unistd.h")]
	public int close (int fd);
	[CCode (cheader_filename = "unistd.h")]
	public ssize_t read (int fd, void* buf, size_t count);
	[CCode (cheader_filename = "unistd.h")]
	public ssize_t write (int fd, void* buf, size_t count);

    /* ------------- termios --------------- */

    [CCode (cheader_filename = "termios.h")]
    public const int B0;
    [CCode (cheader_filename = "termios.h")]
    public const int B50;
    [CCode (cheader_filename = "termios.h")]
    public const int B75;
    [CCode (cheader_filename = "termios.h")]
    public const int B110;
    [CCode (cheader_filename = "termios.h")]
    public const int B134;
    [CCode (cheader_filename = "termios.h")]
    public const int B150;
    [CCode (cheader_filename = "termios.h")]
    public const int B200;
    [CCode (cheader_filename = "termios.h")]
    public const int B300;
    [CCode (cheader_filename = "termios.h")]
    public const int B600;
    [CCode (cheader_filename = "termios.h")]
    public const int B1200;
    [CCode (cheader_filename = "termios.h")]
    public const int B1800;
    [CCode (cheader_filename = "termios.h")]
    public const int B2400;
    [CCode (cheader_filename = "termios.h")]
    public const int B4800;
    [CCode (cheader_filename = "termios.h")]
    public const int B9600;
    [CCode (cheader_filename = "termios.h")]
    public const int B19200;
    [CCode (cheader_filename = "termios.h")]
    public const int B38400;
    [CCode (cheader_filename = "termios.h")]
    public const int B57600;
    [CCode (cheader_filename = "termios.h")]
    public const int B115200;
    [CCode (cheader_filename = "termios.h")]
    public const int B230400;
    [CCode (cheader_filename = "termios.h")]
    public const int B460800;
    [CCode (cheader_filename = "termios.h")]
    public const int B500000;
    [CCode (cheader_filename = "termios.h")]
    public const int B576000;
    [CCode (cheader_filename = "termios.h")]
    public const int B921600;
    [CCode (cheader_filename = "termios.h")]
    public const int B1000000;
    [CCode (cheader_filename = "termios.h")]
    public const int B1152000;
    [CCode (cheader_filename = "termios.h")]
    public const int B1500000;
    [CCode (cheader_filename = "termios.h")]
    public const int B2000000;
    [CCode (cheader_filename = "termios.h")]
    public const int B2500000;
    [CCode (cheader_filename = "termios.h")]
    public const int B3000000;
    [CCode (cheader_filename = "termios.h")]
    public const int B3500000;
    [CCode (cheader_filename = "termios.h")]
    public const int B4000000;
    [CCode (cheader_filename = "termios.h")]
    public const int BRKINT;
    [CCode (cheader_filename = "termios.h")]
    public const int CBAUDEX;
    [CCode (cheader_filename = "termios.h")]
    public const int CIBAUD;
    [CCode (cheader_filename = "termios.h")]
    public const int CLOCAL;
    [CCode (cheader_filename = "termios.h")]
    public const int CMSPAR;
    [CCode (cheader_filename = "termios.h")]
    public const int CREAD;
    [CCode (cheader_filename = "termios.h")]
    public const int CRTSCTS;
    [CCode (cheader_filename = "termios.h")]
    public const int CSTOPB;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHO;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHOE;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHOK;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHONL;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHOCTL;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHOPRT;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHOKE;
    [CCode (cheader_filename = "termios.h")]
    public const int FLUSHO;
    [CCode (cheader_filename = "termios.h")]
    public const int HUPCL;
    [CCode (cheader_filename = "termios.h")]
    public const int ICANON;
    [CCode (cheader_filename = "termios.h")]
    public const int IGNBRK;
    [CCode (cheader_filename = "termios.h")]
    public const int IGNPAR;
    [CCode (cheader_filename = "termios.h")]
    public const int INPCK;
    [CCode (cheader_filename = "termios.h")]
    public const int ISTRIP;
    [CCode (cheader_filename = "termios.h")]
    public const int ISIG;
    [CCode (cheader_filename = "termios.h")]
    public const int INLCR;
    [CCode (cheader_filename = "termios.h")]
    public const int IGNCR;
    [CCode (cheader_filename = "termios.h")]
    public const int ICRNL;
    [CCode (cheader_filename = "termios.h")]
    public const int IUCLC;
    [CCode (cheader_filename = "termios.h")]
    public const int IXON;
    [CCode (cheader_filename = "termios.h")]
    public const int IXANY;
    [CCode (cheader_filename = "termios.h")]
    public const int IXOFF;
    [CCode (cheader_filename = "termios.h")]
    public const int IMAXBEL;
    [CCode (cheader_filename = "termios.h")]
    public const int IUTF8;
    [CCode (cheader_filename = "termios.h")]
    public const int NOFLSH;
    [CCode (cheader_filename = "termios.h")]
    public const int OCRNL;
    [CCode (cheader_filename = "termios.h")]
    public const int OLCUC;
    [CCode (cheader_filename = "termios.h")]
    public const int ONLCR;
    [CCode (cheader_filename = "termios.h")]
    public const int ONOCR;
    [CCode (cheader_filename = "termios.h")]
    public const int ONLRET;
    [CCode (cheader_filename = "termios.h")]
    public const int OFDEL;
    [CCode (cheader_filename = "termios.h")]
    public const int OFILL;
    [CCode (cheader_filename = "termios.h")]
    public const int OPOST;
    [CCode (cheader_filename = "termios.h")]
    public const int PARMRK;
    [CCode (cheader_filename = "termios.h")]
    public const int PARENB;
    [CCode (cheader_filename = "termios.h")]
    public const int PARODD;
    [CCode (cheader_filename = "termios.h")]
    public const int PENDIN;
    [CCode (cheader_filename = "termios.h")]
    public const int TCIFLUSH;
    [CCode (cheader_filename = "termios.h")]
    public const int TCIOFF;
    [CCode (cheader_filename = "termios.h")]
    public const int TCIOFLUSH;
    [CCode (cheader_filename = "termios.h")]
    public const int TCION;
    [CCode (cheader_filename = "termios.h")]
    public const int TCOOFF;
    [CCode (cheader_filename = "termios.h")]
    public const int TCOON;
    [CCode (cheader_filename = "termios.h")]
    public const int TCOFLUSH;
    [CCode (cheader_filename = "termios.h")]
    public const int TCSANOW;
    [CCode (cheader_filename = "termios.h")]
    public const int TCSADRAIN;
    [CCode (cheader_filename = "termios.h")]
    public const int TCSAFLUSH;
    [CCode (cheader_filename = "termios.h")]
    public const int TOSTOP;
    [CCode (cheader_filename = "termios.h")]
    public const int VDISCARD;
    [CCode (cheader_filename = "termios.h")]
    public const int VERASE;
    [CCode (cheader_filename = "termios.h")]
    public const int VEOF;
    [CCode (cheader_filename = "termios.h")]
    public const int VEOL;
    [CCode (cheader_filename = "termios.h")]
    public const int VEOL2;
    [CCode (cheader_filename = "termios.h")]
    public const int VINTR;
    [CCode (cheader_filename = "termios.h")]
    public const int VKILL;
    [CCode (cheader_filename = "termios.h")]
    public const int VLNEXT;
    [CCode (cheader_filename = "termios.h")]
    public const int VMIN;
    [CCode (cheader_filename = "termios.h")]
    public const int VQUIT;
    [CCode (cheader_filename = "termios.h")]
    public const int VREPRINT;
    [CCode (cheader_filename = "termios.h")]
    public const int VTIME;
    [CCode (cheader_filename = "termios.h")]
    public const int VSWTC;
    [CCode (cheader_filename = "termios.h")]
    public const int VSTART;
    [CCode (cheader_filename = "termios.h")]
    public const int VSTOP;
    [CCode (cheader_filename = "termios.h")]
    public const int VSUSP;
    [CCode (cheader_filename = "termios.h")]
    public const int VWERASE;

    [CCode (cname = "struct termios", cheader_filename = "termios.h", free_function = "")]
    [Compact]
    public class TermIOs
    {
        public uint c_iflag;
        public uint c_oflag;
        public uint c_cflag;
        public uint c_lflag;
        public uchar c_line;
        public uchar[32] c_cc;
        public uint c_ispeed;
        public uint c_ospeed;
    }
    [CCode (cname = "struct winsize", cheader_filename = "termios.h", free_function = "")]
    [Compact]
    public class WinSize
    {
        public ushort ws_row;
        public ushort ws_col;
        public ushort ws_xpixel;
        public ushort ws_ypixel;
    }
    [CCode (cheader_filename = "termios.h")]
    public void cfmakeraw (TermIOs termios_p);

    [CCode (cheader_filename = "termios.h")]
    public uint cfgetispeed (TermIOs termios_p);

    [CCode (cheader_filename = "termios.h")]
    public uint cfgetospeed (TermIOs termios_p);

    [CCode (cheader_filename = "termios.h")]
    public int cfsetispeed (TermIOs termios_p, uint speed);

    [CCode (cheader_filename = "termios.h")]
    public int cfsetospeed (TermIOs termios_p, uint speed);

    [CCode (cheader_filename = "termios.h")]
    public int cfsetspeed (TermIOs termios_p, uint speed);

    [CCode (cheader_filename = "termios.h")]
    public int tcdrain (int fd);

    [CCode (cheader_filename = "termios.h")]
    public int tcflush (int fd, int queue_selector);

    [CCode (cheader_filename = "termios.h")]
    public int tcgetattr (int fd, TermIOs termios_p);

    [CCode (cheader_filename = "termios.h")]
    public int tcsetattr (int fd, int optional_actions, TermIOs termios_p);

    [CCode (cheader_filename = "termios.h")]
    public int tcsendbreak (int fd, int duration);

    [CCode (cheader_filename = "termios.h")]
    public int tcflow (int fd, int action);

    /* ------------- tty --------------- */
    [CCode (cheader_filename = "unistd.h")]
    int ttyname_r (int fd, char[] buf);

}

