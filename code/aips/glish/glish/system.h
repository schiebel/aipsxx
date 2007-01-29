/* $Id: system.h,v 19.12 2004/11/03 20:39:00 cvsmgr Exp $
** Copyright (c) 1993 The Regents of the University of California.
** Copyright (c) 1997,1998,2002 Associated Universities Inc.
*/

#ifndef system_h
#define system_h
#include "Glish/glish.h"
#include "config.h"
#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif

#include <stdio.h>
#include <math.h>

#define is_a_nan(x) isnan(x)

#ifdef HAVE_LIBC_H
#include <libc.h>
#endif

typedef void (*signal_handler)( );

#ifdef __cplusplus
extern "C" {
#endif
	/* Change the given fd to non-blocking or blocking I/O. */
	void set_fd_non_blocking( int fd, int non_blocking_flag );

	/* Return the fd of a new TCP socket. */
	int get_tcp_socket();

	/* Return the fd of a new socket for local (same-host) use. */
	int get_local_socket();

	/* Returns a copy of the name of a local socket. */
	char* local_socket_name( int sock );

	/* Attempt to bind to given address.  Returns 0 if address
	 * is in use, 1 if bind successful, and -1 if fatal error
	 * encountered.  Upon success, a listen() is done on the
	 * socket with queue length 5.
	 */
	int bind_socket( int socket, int port );
	int bind_local_socket( int socket );	/* same for local socket */

	/* Accept a connection on the given socket, returning the
	 * new connection socket, or -1 on error.
	 */
	int accept_connection( int connection_socket );

	/* Accepts a local connection on the given socket, returning the
	 * new connection socket, or -1 on error.
	 */
	int accept_local_connection( int connection_socket );

	/* Connects the given local socket to the port on the given remote host.
	 * Returns 0 on failure, 1 on success.
	 */
	int remote_connection( int local_socket, const char* hostname,
				int port );

	/* Connect the given socket to the same-host socket specified by
	 * the given path.
	 */
	int local_connection( int sock, const char* path );

	/* Creates a stream pipe, currently used in
	 * glishd to pass open file descriptors.
	 */
	int stream_pipe( int fd[2] );
	/* Send and receive an open file descriptor
	 * over a stream pipe.
	 */
	int send_fd( int pipe, int fd );
	int recv_fd( int pipe );

	/* An interface to waitpid/wait4. */
	int wait_for_pid( int pid, int *loc, int opts );

	/* Returns the PID of the next terminated process, if any, or 0
	 * if no more terminated processes are lying around waiting to be
	 * reaped.
	 */
	int reap_terminated_process();

	/* Mark the given file descriptor as close-on-exec. */
	void mark_close_on_exec( int fd );

	/* maximum number of file descriptors
	 */
	int max_fds( );

	/* Do a popen() to read from a shell command, and if input is
	 * non-nil set up its standard input to read the given text.
	 *
	 * This routine currently only supports one active shell command
	 * at a time.
	 */
	FILE* popen_with_input( const char* command, const char* input );

	/* Extended popen which allows opening a shell and reading and
	 * writing from/to the process. Returns nill on failure.
	 */
	int dual_popen( const char *command, FILE **in, FILE **out );
	/*
	 * Extended pclose. This closes the FILEs opened by dual_popen().
	 * After all of the fd's opened to the child process have been
	 * closed, a waitpid() is done. This must be called for each
	 * FILE returned by dual_popen(). Returns -1 on failure. Note,
	 * -1 is also return if there are still outstanding FILEs
	 * associated with the child process.
	 */
	int dual_pclose( FILE * );

	/* The matching close command. */
	int pclose_with_input( FILE* pipe );

	/* Creates a new named pipe and returns its name, or else nil
	 * on failure.
	 */
	char* make_named_pipe();

	/* Does whatever is needed to maximize the number of file descriptors
	 * available to the process.
	 */
	void maximize_num_fds();

	/* Install the given signal handler, returning the previous one. */
	signal_handler install_signal_handler( int signal,
						signal_handler handler );

	/* Unblock the signal specified by "sig" */
	void unblock_signal( int sig );


	/* Sets the terminal to character mode, thus select returns
	 * as each character is typed. Needed for command line editing.
	 */
	void set_term_char_mode();

	/* Resets the terminal to line mode, after "set_term_char_mode()"
	 * is called.
	 */
	void set_term_unchar_mode();

	/* A wrapper for gethostname(); returns a pointer to a static region. */
	const char* local_host_name();

	/* time in seconds since 1970
	 */
	double get_current_time();
	/*
	 * Initialize random number generator
	 */
	void seed_random_number_generator();
	/*
	 * Get a random number
	 */
	long random_long();

	/*
	 * canonicalize a path
	 */
	char *canonic_path( const char *path_in );

	/*
	 * Clean up after a crash.
	 */
	void glish_cleanup( );

	int is_regular_file( const char *filename );

	/*
	 * popen() & pclose() with hooks to update the
	 * status from a SIGCHLD handler
	 */
	FILE *status_popen( const char *cmd, const char *mode );
	int status_pclose( FILE *fp );
	void status_pupdate( int pid, int status );

#ifndef HAVE_STRDUP
	char *strdup( const char *str );
#endif

#if defined(__alpha) || defined(__alpha__)
	void glish_fdiv( float *, float *, int, int );
	void glish_ddiv( double *, double *, int, int );
	void glish_func_loop( double (*)( double ), double*, double*, int );

	int glish_float_to_int( float );
	int glish_double_to_int( double );
	short glish_float_to_short( float );
	short glish_double_to_short( double );
	byte glish_float_to_byte( float );
	byte glish_double_to_byte( double );

	void glish_ary_float_to_int( int *, float *, int, int );
	void glish_ary_double_to_int( int *, double *, int, int );
	void glish_ary_float_to_short( short *, float *, int, int );
	void glish_ary_double_to_short( short *, double *, int, int );
	void glish_ary_float_to_byte( byte *, float *, int, int );
	void glish_ary_double_to_byte( byte *, double *, int, int );

#endif

#ifdef __cplusplus
	}
#endif

#endif /* system.h */
