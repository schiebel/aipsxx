// $Id: Daemon.cc,v 19.13 2004/11/03 20:38:57 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: Daemon.cc,v 19.13 2004/11/03 20:38:57 cvsmgr Exp $")
#include "system.h"
#include <sys/param.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>

#include "Glish/Client.h"
#include "Daemon.h"
#if USENPD
#include "Npd/npd.h"
#else
extern int authenticate_to_server( int );
#endif
#include "Glish/Reporter.h"
#include "Channel.h"
#include "Socket.h"
#include "LocalExec.h"
#include "Sequencer.h"
#include "ports.h"

#if HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif

#define DAEMON_NAME "glishd"

//
//  parameters:		-id <NAME> -host <HOSTNAME> -port <PORTNUM>
//
//  glishd no longer does authentication when started by non-root users.
//
Channel *start_remote_daemon( const char *host )
	{
	char command_line[1024];
	char *binpath = Sequencer::BinPath( host, "PATH" );
	char *ldpath = Sequencer::LdPath( host, "LD_LIBRARY_PATH" );

	AcceptSocket connection_socket( 0, INTERPRETER_DEFAULT_PORT );
	mark_close_on_exec( connection_socket.FD() );

	sprintf(command_line, "%s -id glish-daemon -host %s -port %d -+- &\n",
		DAEMON_NAME, local_host_name(), connection_socket.Port() );

	int input[2];

	if ( pipe( input ) < 0 )
		perror( "glish: problem creating pipe" );

	int pid_ = (int) vfork();

	if ( pid_ == 0 )
		{ // child
		char *argv[4];
		argv[0] = RSH;
		argv[1] = (char*) host;
		argv[2] = "sh";
		argv[3] = 0;
		if ( dup2( input[0], fileno(stdin) ) < 0 )
			{
			perror( "glish: couldn't do dup2()" );
			_exit( -1 );
			}

		close( input[0] );
		close( input[1] );

                execvp( argv[0], &argv[0] );

                perror( "glish couldn't exec child" );
                _exit( -1 );
                }

	close( input[0] );

	if ( binpath )
		{
		write( input[1], binpath, strlen(binpath) );
		write( input[1], ";\n", 2 );
		}

	if ( ldpath )
		{
		write( input[1], ldpath, strlen(ldpath) );
		write( input[1], ";\n", 2 );
		}

	write( input[1], command_line, strlen(command_line) );
	write( input[1], "exit\n", 5 );
	
	close( input[1] );

	glish_message->Report( "waiting for daemon ..." );
	int new_conn = accept_connection( connection_socket.FD() );

	if ( binpath ) free_memory( binpath );
	if ( ldpath ) free_memory( ldpath );

	reap_terminated_process();

	return new Channel( new_conn, new_conn );
	}

//
//  parameters:		-id <NAME> -pipes <READFD> <WRITEFD>
//
//  glishd no longer does authentication when started by non-root users.
//
//  This has NOT been tested, and probably isn't presently used. A glishd
//  started by a user can no longer be used to hold "shared" (AKA multi-threaded)
//  client information because they are no longer shared by more than one user.
//  The reason for this is security/ownership sorts of problems.
//
Channel *start_local_daemon( )
	{
	int argc = 0;
	char *argv[10], rpipe[15], wpipe[15];
	int read_pipe[2], write_pipe[2];
	char *exec_name = which_executable( DAEMON_NAME );

	if ( ! exec_name )
		return 0;

	if ( pipe( read_pipe ) < 0 || pipe( write_pipe ) < 0 )
		{
		perror( "start_local_daemon(): problem creating pipe" );
		return 0;
		}

	mark_close_on_exec( read_pipe[0] );
	mark_close_on_exec( write_pipe[1] );

	sprintf(rpipe, "%d", write_pipe[0]);
	sprintf(wpipe, "%d", read_pipe[1]);

	argv[argc++] = exec_name;
	argv[argc++] = "-id";
	argv[argc++] = "glish-daemon";
	argv[argc++] = "-pipes";
	argv[argc++] = rpipe;
	argv[argc++] = wpipe;
	argv[argc++] = "-+-";
	argv[argc++] = 0;

	new LocalExec( argv[0], (const char**) argv );

	close( read_pipe[1] );
	close( write_pipe[0] );

	return new Channel( write_pipe[0], read_pipe[1] );
	}

RemoteDaemon* connect_to_daemon( const char* host, int &err )
	{
	err = 0;

#if USENPD
	static int reported_key_problem = 0;
	static int created_keyfile = 0;

	if ( ! created_keyfile && ! (created_keyfile = create_keyfile()) )
		{
		if ( ! reported_key_problem )
			{
			reported_key_problem = 1;
			glish_warn->Report("couldn't create key file.");
			}
		return 0;
		}
#endif

	int daemon_socket = get_tcp_socket();

	if ( remote_connection( daemon_socket, host, DAEMON_PORT ) )
		{ // Connected.
		mark_close_on_exec( daemon_socket );

		Channel* daemon_channel =
			new Channel( daemon_socket, daemon_socket );

		RemoteDaemon* r = new RemoteDaemon( host, daemon_channel );

		if ( ! authenticate_to_server( daemon_socket ) )
			{
			Unref( daemon_channel );
			close( daemon_socket );
			err = 1;
			glish_error->Report("Daemon creation failed, not authorized.");
			return 0;
			}

		// Read and discard daemon's "establish" event.
		GlishEvent* e = recv_event( daemon_channel->Source() );
		Unref( e );

		// Tell the daemon which directory we want to work out of.
		char work_dir[MAXPATHLEN];

		if ( ! getcwd( work_dir, sizeof( work_dir ) ) )
			glish_fatal->Report( "problems getting cwd:", work_dir );

		Value work_dir_value( work_dir );
		send_event( daemon_channel->Sink(), "setwd",
				&work_dir_value );

		return r;
		}

	else
		{
		close( daemon_socket );
		return 0;
		}
	}

void RemoteDaemon::UpdateBinPath( const Value *path )
	{
	send_event( chan->Sink(), "setbinpath", path );
	}

void RemoteDaemon::UpdateLdPath( const char *path )
	{
	IValue p( path );
	send_event( chan->Sink(), "setldpath", &p );
	}
