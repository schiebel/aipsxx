/*
 * $Log: rmtlib.cc,v $
 * Revision 19.0  2003/07/16 03:40:03  aips2adm
 * exhale: Base release 19.000.00
 *
 * Revision 18.0  2002/06/07 19:44:40  aips2adm
 * exhale: Base release 18.000.00
 *
 * Revision 17.0  2001/11/12 18:31:02  aips2adm
 * exhale: Base release 17.000.00
 *
 * Revision 16.0  2001/05/02 22:55:53  aips2adm
 * exhale: Base release 16.000.00
 *
 * Revision 15.0  2000/10/26 14:06:27  aips2adm
 * exhale: Base release 15.000.00
 *
 * Revision 14.1  2000/07/10 23:37:29  rmarson
 * Cleaned up compiler warnings
 *
 * Revision 14.0  2000/03/23 14:32:33  aips2adm
 * exhale: Base release 14.000.00
 *
 * Revision 13.1  1999/12/20 05:29:04  wbrouw
 * Change (name *) 0 cast to static_cast<name *>(0)
 *
 * Revision 13.0  1999/08/10 17:02:18  aips2adm
 * exhale: Base release 13.000.00
 *
 * Revision 12.0  1999/07/14 21:45:44  aips2adm
 * exhale: Base release 12.000.00
 *
 * Revision 11.0  1998/10/03 04:33:49  aips2adm
 * exhale: Base release 11.000.00
 *
 * Revision 10.0  1998/07/20 15:12:46  aips2adm
 * exhale: Base release 10.000.00
 *
 * Revision 9.0  1997/08/25 18:25:58  aips2adm
 * exhale: Base release 09.000.00
 *
 * Revision 8.1  1997/07/23 20:10:53  wyoung
 * Initial check in.
 *
 * Revision 1.7  89/03/23  14:09:51  root
 * Fix from haynes@ucscc.ucsc.edu for use w/compat. ADR.
 * 
 * Revision 1.6  88/10/25  17:04:29  root
 * rexec code and a bug fix from srs!dan, miscellanious cleanup. ADR.
 * 
 * Revision 1.5  88/10/25  16:30:17  root
 * Fix from jeff@gatech.edu for getting user@host:dev right. ADR.
 * 
 * Revision 1.4  87/10/30  10:36:12  root
 * Made 4.2 syntax a compile time option. ADR.
 * 
 * Revision 1.3  87/04/22  11:16:48  root
 * Two fixes from parmelee@wayback.cs.cornell.edu to correctly
 * do fd biasing and rmt protocol on 'S' command. ADR.
 * 
 * Revision 1.2  86/10/09  16:38:53  root
 * Changed to reflect 4.3BSD rcp syntax. ADR.
 * 
 * Revision 1.1  86/10/09  16:17:35  root
 * Initial revision
 * 
 */

/*
 *	rmt --- remote tape emulator subroutines
 *
 *	Originally written by Jeff Lee, modified some by Arnold Robbins
 *
 *	WARNING:  The man page rmt(8) for /etc/rmt documents the remote mag
 *	tape protocol which rdump and rrestore use.  Unfortunately, the man
 *	page is *WRONG*.  The author of the routines I'm including originally
 *	wrote his code just based on the man page, and it didn't work, so he
 *	went to the rdump source to figure out why.  The only thing he had to
 *	change was to check for the 'F' return code in addition to the 'E',
 *	and to separate the various arguments with \n instead of a space.  I
 *	personally don't think that this is much of a problem, but I wanted to
 *	point it out.
 *	-- Arnold Robbins
 *
 *	Redone as a library that can replace open, read, write, etc, by
 *	Fred Fish, with some additional work by Arnold Robbins.
 */
 
/*
 *	MAXUNIT --- Maximum number of remote tape file units
 *
 *	READ --- Return the number of the read side file descriptor
 *	WRITE --- Return the number of the write side file descriptor
 */

#define RMTIOCTL	1
// #define USE_REXEC	1	/* rexec code courtesy of Dan Kegel, srs!dan */
// #define _NO_PROTO      /* test for compiling on the IBM */

#include <stdio.h>
#include <signal.h>
#include <sys/types.h>
#include <fcntl.h>

#ifdef RMTIOCTL
#include <sys/ioctl.h>
#include <sys/mtio.h>    /* for sun */
/* #include <sys/tape.h>    for ibm */
#endif

#ifdef USE_REXEC
#include <netdb.h>
#endif

#include <errno.h>
#include <setjmp.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

#define BUFMAGIC	64	/* a magic number for buffer sizes */
#define MAXUNIT	4

#define READ(fd)	(Ctp[fd][0])
#define WRITE(fd)	(Ptc[fd][1])

static int Ctp[MAXUNIT][2] = { {-1, -1}, {-1, -1}, {-1, -1}, {-1, -1} };
static int Ptc[MAXUNIT][2] = { {-1, -1}, {-1, -1}, {-1, -1}, {-1, -1} };

extern int errno;
int isrmt (int);

/*
 *	abort --- close off a remote tape connection
 */

static void abort(int fildes)
{
	close(READ(fildes));
	close(WRITE(fildes));
	READ(fildes) = -1;
	WRITE(fildes) = -1;
}



/*
 *	command --- attempt to perform a remote tape command
 */

static int command(int fildes, const char *buf)
{
	register int blen;
	void (*pstat)(int);

/*
 *	save current pipe status and try to make the request
 */

	blen = strlen(buf);
	pstat = signal(SIGPIPE, SIG_IGN);
	if (write(WRITE(fildes), buf, blen) == blen)
	{
		signal(SIGPIPE, pstat);
		return(0);
	}

/*
 *	something went wrong. close down and go home
 */

	signal(SIGPIPE, pstat);
	abort(fildes);

	errno = EIO;
	return(-1);
}



/*
 *	status --- retrieve the status from the pipe
 */

static int status(int fildes)
{
	int i;
	char c, *cp;
	char buffer[BUFMAGIC];

/*
 *	read the reply command line
 */

	for (i = 0, cp = buffer; i < BUFMAGIC; i++, cp++)
	{
		if (read(READ(fildes), cp, 1) != 1)
		{
			abort(fildes);
			errno = EIO;
			return(-1);
		}
		if (*cp == '\n')
		{
			*cp = 0;
			break;
		}
	}

	if (i == BUFMAGIC)
	{
		abort(fildes);
		errno = EIO;
		return(-1);
	}

/*
 *	check the return status
 */

	for (cp = buffer; *cp; cp++)
		if (*cp != ' ')
			break;

	if (*cp == 'E' || *cp == 'F')
	{
		errno = atoi(cp + 1);
		while (read(READ(fildes), &c, 1) == 1)
			if (c == '\n')
				break;

		if (*cp == 'F')
			abort(fildes);

		return(-1);
	}

/*
 *	check for mis-synced pipes
 */

	if (*cp != 'A')
	{
		abort(fildes);
		errno = EIO;
		return(-1);
	}

	return(atoi(cp + 1));
}

#ifdef USE_REXEC

/*
 * _rmt_rexec
 *
 * execute /etc/rmt on a remote system using rexec().
 * Return file descriptor of bidirectional socket for stdin and stdout
 * If username is NULL, or an empty string, uses current username.
 *
 * ADR: By default, this code is not used, since it requires that
 * the user have a .netrc file in his/her home directory, or that the
 * application designer be willing to have rexec prompt for login and
 * password info. This may be unacceptable, and .rhosts files for use
 * with rsh are much more common on BSD systems.
 */

static int
_rmt_rexec(char *host, char *user)
{
	struct servent *rexecserv;

	rexecserv = getservbyname("exec", "tcp");
	if (NULL == rexecserv) {
		fprintf (stdout, "? exec/tcp: service not available.");
		exit(0);
	}
	if ((user != NULL) && *user == '\0')
		user = (char *) NULL;
	return rexec (&host, rexecserv->s_port, user, NULL,
			"/etc/rmt", (int *)NULL);
}
#endif /* USE_REXEC */

/*
 *	_rmt_open --- open a magtape device on system specified, as given user
 *
 *	file name has the form [user@]system:/dev/????
#ifdef COMPAT
 *	file name has the form system[.user]:/dev/????
#endif
 */

#define MAXHOSTLEN	257	/* BSD allows very long host names... */

static int _rmt_open (char *path, int oflag, int mode)
{
	int i, rc;
	char buffer[BUFMAGIC];
	char system[MAXHOSTLEN];
	char device[BUFMAGIC];
	char login[BUFMAGIC];
	char *sys, *dev, *user;

	sys = system;
	dev = device;
	user = login;

/*
 *	first, find an open pair of file descriptors
 */

	for (i = 0; i < MAXUNIT; i++)
		if (READ(i) == -1 && WRITE(i) == -1)
			break;

	if (i == MAXUNIT)
	{
		errno = EMFILE;
		return(-1);
	}

/*
 *	pull apart system and device, and optional user
 *	don't munge original string
 *	if COMPAT is defined, also handle old (4.2) style person.site notation.
 */

	while (*path != '@'
#ifdef COMPAT
			&& *path != '.'
#endif
			&& *path != ':') {
		*sys++ = *path++;
	}
	*sys = '\0';
	path++;

	if (*(path - 1) == '@')
	{
		(void) strcpy (user, system);	/* saw user part of user@host */
		sys = system;			/* start over */
		while (*path != ':') {
			*sys++ = *path++;
		}
		*sys = '\0';
		path++;
	}
#ifdef COMPAT
	else if (*(path - 1) == '.')
	{
		while (*path != ':') {
			*user++ = *path++;
		}
		*user = '\0';
		path++;
	}
#endif
	else
		*user = '\0';

	while (*path) {
		*dev++ = *path++;
	}
	*dev = '\0';

#ifdef USE_REXEC
/* 
 *	Execute the remote command using rexec 
 */
	READ(i) = WRITE(i) = _rmt_rexec(system, login);
	if (READ(i) < 0)
		return -1;
#else
/*
 *	setup the pipes for the 'rsh' command and fork
 */

	if (pipe(Ptc[i]) == -1 || pipe(Ctp[i]) == -1)
		return(-1);

	if ((rc = fork()) == -1)
		return(-1);

	if (rc == 0)
	{
		close(0);
		dup(Ptc[i][0]);
		close(Ptc[i][0]); close(Ptc[i][1]);
		close(1);
		dup(Ctp[i][1]);
		close(Ctp[i][0]); close(Ctp[i][1]);
		(void) setuid (getuid ());
		(void) setgid (getgid ());
		if (*login)
		{
			execl("/usr/ucb/rsh", "rsh", system, "-l", login,
				"/etc/rmt", static_cast<char *>(0));
			execl("/usr/bin/remsh", "remsh", system, "-l", login,
				"/etc/rmt", static_cast<char *>(0));
		}
		else
		{
			execl("/usr/ucb/rsh", "rsh", system,
				"/etc/rmt", static_cast<char *>(0));
			execl("/usr/bin/remsh", "remsh", system,
				"/etc/rmt", static_cast<char *>(0));
		}

/*
 *	bad problems if we get here
 */

		perror("exec");
		exit(1);
	}

	close(Ptc[i][0]); close(Ctp[i][1]);
#endif

/*
 *	now attempt to open the tape device
 */

	sprintf(buffer, "O%s\n%d\n", device, oflag);
	if (command(i, buffer) == -1 || status(i) == -1)
		return(-1);

	return(i);
}



/*
 *	_rmt_close --- close a remote magtape unit and shut down
 */

static int _rmt_close(int fildes)
{
	int rc;

	if (command(fildes, "C\n") != -1)
	{
		rc = status(fildes);

		abort(fildes);
		return(rc);
	}

	return(-1);
}



/*
 *	_rmt_read --- read a buffer from a remote tape
 */

static int _rmt_read(int fildes, char *buf, unsigned int nbyte)
{
	int rc, i;
	char buffer[BUFMAGIC];

	sprintf(buffer, "R%d\n", nbyte);
	if (command(fildes, buffer) == -1 || (rc = status(fildes)) == -1)
		return(-1);

	for (i = 0; i < rc; i += nbyte, buf += nbyte)
	{
		nbyte = read(READ(fildes), buf, rc);
		if (nbyte <= 0)
		{
			abort(fildes);
			errno = EIO;
			return(-1);
		}
	}

	return(rc);
}



/*
 *	_rmt_write --- write a buffer to the remote tape
 */

static int _rmt_write(int fildes, char *buf, unsigned int nbyte)
{
	char buffer[BUFMAGIC];
	void (*pstat)(int);

	sprintf(buffer, "W%d\n", nbyte);
	if (command(fildes, buffer) == -1)
		return(-1);

	pstat = signal(SIGPIPE, SIG_IGN);
	if (write(WRITE(fildes), buf, nbyte) == static_cast<int>(nbyte))
	{
		signal (SIGPIPE, pstat);
		return(status(fildes));
	}

	signal (SIGPIPE, pstat);
	abort(fildes);
	errno = EIO;
	return(-1);
}



/*
 *	_rmt_lseek --- perform an imitation lseek operation remotely
 */

static long _rmt_lseek(int fildes, long offset, int whence)
{
	char buffer[BUFMAGIC];

	sprintf(buffer, "L%ld\n%d\n", offset, whence);
	if (command(fildes, buffer) == -1)
		return(-1);

	return(status(fildes));
}


/*
 *	_rmt_ioctl --- perform raw tape operations remotely
 */

#ifdef RMTIOCTL
static int _rmt_ioctl(int fildes, int op, char *arg)
{
	int rc, cnt;
	char buffer[BUFMAGIC];

/*
 *	MTIOCOP is the easy one. nothing is transfered in binary
 */

	if (op == MTIOCTOP)  /* for Sun only  */
/*	if (op == STIOCTOP)     for IBM only  */
	{
		sprintf(buffer, "I%d\n%d\n", ((struct mtop *) arg)->mt_op,
			((struct mtop *) arg)->mt_count);
		if (command(fildes, buffer) == -1)
			return(-1);
		return(status(fildes));
	}

/*
 *	we can only handle 2 ops, if not the other one, punt
 */

  	if (op != static_cast<int>(MTIOCGET))   /* for Sun only  */
/*	if (op != STIOCMD)       for IBM only  */
	{
		errno = EINVAL;
		return(-1);
	}

/*
 *	grab the status and read it directly into the structure
 *	this assumes that the status buffer is (hopefully) not
 *	padded and that 2 shorts fit in a long without any word
 *	alignment problems, ie - the whole struct is contiguous
 *	NOTE - this is probably NOT a good assumption.
 */

	if (command(fildes, "S") == -1 || (rc = status(fildes)) == -1)
		return(-1);

	for (; rc > 0; rc -= cnt, arg += cnt)
	{
		cnt = read(READ(fildes), arg, rc);
		if (cnt <= 0)
		{
			abort(fildes);
			errno = EIO;
			return(-1);
		}
	}

/*
 *	now we check for byte position. mt_type is a small integer field
 *	(normally) so we will check its magnitude. if it is larger than
 *	256, we will assume that the bytes are swapped and go through
 *	and reverse all the bytes
 */
/*    comment this out for the IBM and see what happens 
 *      doesn't know about mtget.mt_type
 *	if (((struct mtget *) arg)->mt_type < 256)
 *		return(0);
 *
 *	for (cnt = 0; cnt < rc; cnt += 2)
 *	{
 *		c = arg[cnt];
 *		arg[cnt] = arg[cnt+1];
 *		arg[cnt+1] = c;
 *	}
 */

	return(0);
  }
#endif /* RMTIOCTL */

/*
 *	Added routines to replace open(), close(), lseek(), ioctl(), etc.
 *	The preprocessor can be used to remap these the rmtopen(), etc
 *	thus minimizing source changes:
 *
 *		#ifdef <something>
 *		#  define access rmtaccess
 *		#  define close rmtclose
 *		#  define creat rmtcreat
 *		#  define dup rmtdup
 *		#  define fcntl rmtfcntl
 *		#  define fstat rmtfstat
 *		#  define ioctl rmtioctl
 *		#  define isatty rmtisatty
 *		#  define lseek rmtlseek
 *		#  define lstat rmtlstat
 *		#  define open rmtopen
 *		#  define read rmtread
 *		#  define stat rmtstat
 *		#  define write rmtwrite
 *		#endif
 *
 *	-- Fred Fish
 *
 *	ADR --- I set up a <rmt.h> include file for this
 *
 */

/*
 *	Note that local vs remote file descriptors are distinquished
 *	by adding a bias to the remote descriptors.  This is a quick
 *	and dirty trick that may not be portable to some systems.
 */

#define REM_BIAS 128


/*
 *	Test pathname to see if it is local or remote.  A remote device
 *	is any string that contains ":/dev/".  Returns 1 if remote,
 *	0 otherwise.
 */
 
static int remdev (register char *path)
{

	if ((path = strchr (path, ':')) != NULL)
	{
		if (strncmp (path + 1, "/dev/", 5) == 0)
		{
			return (1);
		}
	}
	return (0);
}


/*
 *	Open a local or remote file.  Looks just like open(2) to
 *	caller.
 */
 
int rmtopen (char *path, int oflag, int mode)
{
	int fd;

	if (remdev (path))
	{
		fd = _rmt_open (path, oflag, mode);

		return (fd == -1) ? -1 : (fd + REM_BIAS);
	}
	else
	{
		return (open (path, oflag, mode));
	}
}

/*
 *	Test pathname for specified access.  Looks just like access(2)
 *	to caller.
 */
 
int rmtaccess (char *path, int amode)
{
	if (remdev (path))
	{
		return (0);		/* Let /etc/rmt find out */
	}
	else
	{
		return (access (path, amode));
	}
}


/*
 *	Read from stream.  Looks just like read(2) to caller.
 */
  
int rmtread (int fildes, char *buf, unsigned int nbyte)
{

	if (isrmt (fildes))
	{
		return (_rmt_read (fildes - REM_BIAS, buf, nbyte));
	}
	else
	{
		return (read (fildes, buf, nbyte));
	}
}


/*
 *	Write to stream.  Looks just like write(2) to caller.
 */
 
int rmtwrite (int fildes, char *buf, unsigned int nbyte)
{
	if (isrmt (fildes))
	{
		return (_rmt_write (fildes - REM_BIAS, buf, nbyte));
	}
	else
	{
		return (write (fildes, buf, nbyte));
	}
}

/*
 *	Perform lseek on file.  Looks just like lseek(2) to caller.
 */

long rmtlseek (int fildes, long offset, int whence)
{
	if (isrmt (fildes))
	{
		return (_rmt_lseek (fildes - REM_BIAS, offset, whence));
	}
	else
	{
		return (lseek (fildes, offset, whence));
	}
}


/*
 *	Close a file.  Looks just like close(2) to caller.
 */
 
int rmtclose (int fildes)
{
	if (isrmt (fildes))
	{
		return (_rmt_close (fildes - REM_BIAS));
	}
	else
	{
		return (close (fildes));
	}
}

/*
 *	Do ioctl on file.  Looks just like ioctl(2) to caller.
 */
 
int rmtioctl (int fildes, unsigned long request, char *arg)
{
	if (isrmt (fildes))
	{
#ifdef RMTIOCTL
		return (_rmt_ioctl (fildes - REM_BIAS, request, arg));
#else
		errno = EOPNOTSUPP;
		return (-1);		/* For now  (fnf) */
#endif
	}
	else
	{
		return (ioctl (fildes, request, arg));
	}
}


/*
 *	Duplicate an open file descriptor.  Looks just like dup(2)
 *	to caller.
 */
 
int rmtdup (int fildes)
{
	if (isrmt (fildes))
	{
		errno = EOPNOTSUPP;
		return (-1);		/* For now (fnf) */
	}
	else
	{
		return (dup (fildes));
	}
}

/*
 *	Get file status.  Looks just like fstat(2) to caller.
 */
 
int rmtfstat (int fildes, struct stat *buf)
{
	if (isrmt (fildes))
	{
		errno = EOPNOTSUPP;
		return (-1);		/* For now (fnf) */
	}
	else
	{
		return (fstat (fildes, buf));
	}
}


/*
 *	Get file status.  Looks just like stat(2) to caller.
 */
 
int rmtstat (char *path, struct stat *buf)
{
	if (remdev (path))
	{
		errno = EOPNOTSUPP;
		return (-1);		/* For now (fnf) */
	}
	else
	{
		return (stat (path, buf));
	}
}



/*
 *	Create a file from scratch.  Looks just like creat(2) to the caller.
 */

#include <sys/file.h>		/* BSD DEPENDANT!!! */
// #include <fcntl.h>		/* use this one for S5 with remote stuff */

int rmtcreat (char *path, int mode)
{
	if (remdev (path))
	{
		return (rmtopen (path, 1 | O_CREAT, mode));
	}
	else
	{
		return (creat (path, mode));
	}
}

/*
 *	Isrmt. Let a programmer know he has a remote device.
 */

int isrmt (int fd)
{
	return (fd >= REM_BIAS);
}

/*
 *	Rmtfcntl. Do a remote fcntl operation.
 */

int rmtfcntl (int fd, int cmd, int arg)
{
	if (isrmt (fd))
	{
		errno = EOPNOTSUPP;
		return (-1);
	}
	else
	{
		return (fcntl (fd, cmd, arg));
	}
}

/*
 *	Rmtisatty.  Do the isatty function.
 */

int rmtisatty (int fd)
{
	if (isrmt (fd))
		return (0);
	else
		return (isatty (fd));
}


/*
 *	Get file status, even if symlink.  Looks just like lstat(2) to caller.
 */
 
int rmtlstat (char *path, struct stat *buf)
{
	if (remdev (path))
	{
		errno = EOPNOTSUPP;
		return (-1);		/* For now (fnf) */
	}
	else
	{
		return (lstat (path, buf));
	}
}
