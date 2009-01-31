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

    [CCode (cheader_filename = "sys/select.h")]
    public int select (int nfds, FdSet readfds, FdSet writefds, FdSet exceptfds, TimeVal timeval);


    /* ---------termios ------------------- */
    [CCode (cheader_filename = "termios.h")]
    public int tcdrain (int fd);

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

    /* ---------------------------- */

	[CCode (cheader_filename = "unistd.h")]
	public int close (int fd);
	[CCode (cheader_filename = "unistd.h")]
	public ssize_t read (int fd, void* buf, size_t count);
	[CCode (cheader_filename = "unistd.h")]
	public ssize_t write (int fd, void* buf, size_t count);
}

