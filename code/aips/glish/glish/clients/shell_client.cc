// $Id: shell_client.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,2000 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: shell_client.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $")
#include "system.h"
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>

#if defined(_AIX)
// for bzero()
#include <strings.h>
#endif

#if defined(HAVE_SYS_UIO_H)
#include <sys/uio.h>
#endif

#if HAVE_OSFCN_H
#include <osfcn.h>
#endif

#if HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif

#if HAVE_SYS_TIME_H
#include <sys/time.h>
#endif

#if HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif

#ifdef HAVE_VFORK_H
#include <vfork.h>
#endif

#ifndef WEXITSTATUS
#define WEXITSTATUS(stat_val) ((unsigned)(stat_val) >> 8)
#endif

#include "Glish/Client.h"

inline int streq( const char* a, const char* b )
	{
	return ! strcmp( a, b );
	}

char* prog_name;
char* child_name;
int pid;
int ping_through;


// Given an argv, forks argv[0] as a new child, returns an array of
// file descriptors (ret):
//	ret[0]	=>	child's stdout
//	ret[1]	=>	child's stdin
//	ret[2]	=>	child's stderr
//
// and modifies pid to the child's PID.
//
// The global prog_name is used for generating error messages.

int* CreateChild( char** argv, int& pid );


// Get the next event via Client c and depending on its name do the following:
//
//	EOF		close the output file
//	terminate	kill the child
//	stdin		send it to the child via write_to_child_fd
//
// Any other event name generates a message to stderr and is ignored.
//
// The globals prog_name and child_name are used for generating error
// messages; pid for sending signals to the child; and, if non-zero,
// ping_through indicates that the child should be sent a SIGIO after
// "stdin" data has been written to it

void SendChildInput( Client& c, int write_to_child_fd );


// Exhaust input present on a child's fd; if read goes okay (not EOF),
// send an 'event_name' message via Client c and return 0; otherwise, wait for
// child termination and return non-zero and set status to child exit status.
//
// The globals prog_name and child_name are used for generating error
// messages.

int ReceiveChildOutput( Client& c, int read_from_child_fd, const char *event_name );


// Wait for the child to exit and return its exit status.

int await_child_exit();

// Create a master/slave pty pair.  Returns 0 if failure, non-zero on success.
int get_pty_pair( int pty[2] );

// Handler for when the child exits.  All it does is close the writing
// end of the following pipe, which we can subsequently detect via select().
void child_exit_handler( );
int child_exit_pipe[2];


int main( int argc, char** argv )
	{
	Client c( argc, argv );

	prog_name = argv[0];
	++argv, --argc;

	ping_through = 0;
	if ( argc > 0 && streq( argv[0], "-ping" ) )
		{
		ping_through = 1;
		++argv, --argc;
		}

	child_name = argv[0];

	(void) install_signal_handler( SIGCHLD, child_exit_handler );

	if ( pipe( child_exit_pipe ) < 0 )
		{
		fprintf( stderr, "%s (%s): ", prog_name, child_name );
		perror( "child-exit pipe failed" );
		return 1;
		}

	int *child_pipes = CreateChild( argv, pid );

	if ( ! child_pipes )
		return 1;

	int child_fd = child_pipes[0];
	int child_err = child_pipes[2];
	int child_exit_fd = child_exit_pipe[0];
	int do_out = 1, do_err = 1;

	fd_set selection_mask;

	for ( ; ; )
		{
		FD_ZERO( &selection_mask );
		if ( do_out ) FD_SET( child_fd, &selection_mask );
		if ( do_err ) FD_SET( child_err, &selection_mask );
		FD_SET( child_exit_fd, &selection_mask );
		c.AddInputMask( &selection_mask );

		if ( select( FD_SETSIZE, (SELECT_MASK_TYPE *) &selection_mask, 0, 0, 0 ) < 0 )
			{
			if ( errno != EINTR )
				{
				int preserve_errno = errno;

				fprintf( stderr, "%s (%s): ",
					prog_name, child_name );
				errno = preserve_errno;
				perror(
				    "select() returned for unknown reason" );
				}

			continue;
			}

		if ( c.HasClientInput( &selection_mask ) )
			SendChildInput( c, child_pipes[1] );

		if ( FD_ISSET( child_err, &selection_mask ) )
			if ( ReceiveChildOutput( c, child_err, "stderr" ) ) do_err = 0;

		if ( FD_ISSET( child_fd, &selection_mask ) )
			if ( ReceiveChildOutput( c, child_fd, "stdout" ) ) do_out = 0;

		if ( FD_ISSET( child_exit_fd, &selection_mask ) )
			return await_child_exit();
		}
	}


int* CreateChild( char** argv, int& pid )
	{
	int to_pipe[2];
	static int ret[3];

	if ( pipe( to_pipe ) < 0 )
		{
		fprintf( stderr, "%s (%s): ", prog_name, argv[0] );
		perror( "couldn't create pipe" );
		return 0;
		}

	// Try to create a pseudo-terminal for the child's standard
	// output so that text it generates will be line-buffered.
	int from_pipe[2];

	int using_pty = 1;
	if ( ! get_pty_pair( from_pipe ) )
		{
		using_pty = 0;

		// Fall back on using a pipe for the output.
		if ( pipe( from_pipe ) < 0 )
			{
			fprintf( stderr, "%s (%s): ", prog_name, argv[0] );
			perror( "couldn't create pipe" );
			return 0;
			}
		}

	// Try to create a pseudo-terminal for the child's standard
	// error so that text it generates will be line-buffered.
	int err_pipe[2];

	if ( ! get_pty_pair( err_pipe ) )
		{
		using_pty = 0;

		// Fall back on using a pipe for the output.
		if ( pipe( err_pipe ) < 0 )
			{
			fprintf( stderr, "%s (%s): ", prog_name, argv[0] );
			perror( "couldn't create pipe" );
			return 0;
			}
		}

	pid = vfork();

	if ( pid == 0 )
		{ // child

		// Set the child's process group incase it and all of
		// its children must be forcefully killed.
		pid = getpid();
		setpgid(pid,pid);

		if ( dup2( to_pipe[0], fileno(stdin) ) < 0 ||
		     dup2( from_pipe[1], fileno(stdout) ) < 0 ||
		     dup2( err_pipe[1], fileno(stderr) ) < 0 )
			{
			fprintf( stderr, "%s (%s): ", prog_name, argv[0] );
			perror( "couldn't do dup2()" );
			_exit( -1 );
			}

		close( to_pipe[0] );
		close( to_pipe[1] );
		close( from_pipe[0] );
		close( from_pipe[1] );
		close( err_pipe[0] );
		close( err_pipe[1] );

		execvp( argv[0], &argv[0] );

		fprintf( stderr, "%s (child): couldn't exec ", prog_name );
		perror( argv[0] );
		_exit( -1 );
		}

	close( to_pipe[0] );
	close( from_pipe[1] );
	close( err_pipe[1] );

	ret[0] = from_pipe[0];
	ret[1] = to_pipe[1];
	ret[2] = err_pipe[0];

	return ret;
	}


void SendChildInput( Client& c, int send_to_child_fd )
	{
	GlishEvent* e = c.NextEvent();

	if ( ! e || streq( e->name, "terminate" ) )
		{
		sleep(3);
		kill( pid, SIGTERM );
		sleep(1);
		if ( kill( pid, 0 ) >= 0 )
			{
			kill ( - pid, SIGKILL );
			exit( 0 );
			}
		}

	else if ( streq( e->name, "EOF" ) )
		close( send_to_child_fd );

	else if ( streq( e->name, "stdin" ) )
		{
		char* ivtmp = "\n";
		struct iovec iv[2] = { { 0, 0 }, { ivtmp, 1 } };
		char* input_str = e->value->StringVal();

		iv[0].iov_base = input_str;
		iv[0].iov_len = strlen(input_str);

		if ( writev( send_to_child_fd, iv, 2 ) < 0 )
			{
			fprintf( stderr, "%s (%s): ", prog_name, child_name );
			perror( "write to child failed" );
			return;
			}

		free_memory(input_str);

		if ( ping_through )
			kill( pid, SIGIO );
		}

	else
		c.Unrecognized();
	}



int ReceiveChildOutput( Client& c, int read_from_child_fd, const char *event_name )
	{
	// Exhaust child's output, until we come across a read that ends
	// on a line ('\n') boundary.
	static char* buf = 0;
	static int buf_size = 1024;
	int size = 0;
	char* line_end = 0;

	if ( buf == 0 )
		buf = (char*) alloc_memory( sizeof(char)*1024 );

	char *buf_ptr = buf;

	do
		{
		while ( ! line_end )
			{ // Need to fill buffer.

			int read_size = read( read_from_child_fd, buf_ptr,
						buf_size - size - 1 );

			// When reading from the pty after the child has
			// executed we can get EIO or EINVAL.
			if ( read_size < 0 && errno != EIO && errno != EINVAL )
				{
				fprintf( stderr, "%s (%s): ", prog_name,
						child_name );
				perror( "read from child failed" );
				}

			if ( read_size <= 0 )
				{
				if ( size > 0 ) c.PostEvent( event_name, buf );
				return 1;
				}

			// Mark the end of the buffer.
			buf_ptr[read_size] = '\0';
			size += read_size;

			line_end = strchr( buf_ptr, '\n' );

			if ( ! line_end && buf_size - size < 256 )
				{
				int cursize = buf_ptr - buf;
				buf_size *= 2;
				buf = (char*) realloc_memory( buf, buf_size );
				buf_ptr = buf + cursize;
				}

			buf_ptr += read_size;
			}

		// Nuke trailing newline.
		*line_end = '\0';

		// While we're at it, get rid of the \r that stdio
		// includes due to using a pty.
		if ( line_end > buf && line_end[-1] == '\r' )
			line_end[-1] = '\0';

		c.PostEvent( event_name, buf );
		++line_end;
		int num_to_move = buf_ptr - line_end;

		for ( int i = 0; i < num_to_move; ++i )
			buf[i] = *line_end++;

		size = num_to_move;
		buf_ptr = &buf[size];
		*buf_ptr = '\0';
		line_end = strchr( buf, '\n' );
		}
	while ( buf_ptr > buf );

	return 0;
	}


int await_child_exit()
	{ // EOF - presumably the child is about to exit.
	int child_status;
	int child_id;

	do
		{
		child_id = wait_for_pid( pid, &child_status, WNOHANG );
		}
	while ( child_id < 0 && errno == EINTR );

	if ( child_id < 0 )
		{
		fprintf( stderr, "%s: problem waiting for child %s",
			 prog_name, child_name );
		perror( " to terminate" );
		}

	return WEXITSTATUS(child_status);
	}


int get_pty_pair( int pty[2] )
	{
	static char pty_name[sizeof( "/dev/ttyp1" )];

	// First find the master.
	int master_fd = -1;

	for ( char p1 = 0; p1 < ('s' - 'p') && master_fd == -1; p1++ )
		for ( char p2 = 0; p2 < 0x10; p2++ )
			{
			sprintf( pty_name, "/dev/pty%c%x", p1 + 'p', p2 );

			if ( (master_fd = open( pty_name, O_RDWR )) >= 0 )
				{
				// Success.
				sprintf( pty_name,
					"/dev/tty%c%x", p1 + 'p', p2 );
				break;
				}
			}

	if ( master_fd < 0 )
		return 0;

	int slave_fd = open( pty_name, O_RDWR );

	if ( slave_fd < 0 )
		{
		close( master_fd );
		return 0;
		}

	pty[0] = master_fd;
	pty[1] = slave_fd;

	return 1;
	}


void child_exit_handler( )
	{
	close( child_exit_pipe[1] );
	}
