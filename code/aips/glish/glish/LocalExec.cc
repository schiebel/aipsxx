// $Id: LocalExec.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: LocalExec.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $")
#include "system.h"
#include <errno.h>
#include <signal.h>
#include <sys/file.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <iostream>

#if HAVE_OSFCN_H
#include <osfcn.h>
#endif

#ifdef HAVE_SIGLIB_H
#include <sigLib.h>
#endif

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#if HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif

#ifdef HAVE_VFORK_H
#include <vfork.h>
#endif

#ifdef HAVE_CRT_EXTERNS_H
#include <crt_externs.h>
#endif

#include "LocalExec.h"

LocalExec::LocalExec( const char* arg_executable, const char** argv )
    : Executable( arg_executable ), lexpid( this )
	{
	MakeExecutable( argv );
	}

LocalExec::LocalExec( const char* arg_executable )
    : Executable( arg_executable ), lexpid( this )
	{
	const char* argv[2];
	argv[0] = arg_executable;
	argv[1] = 0;
	MakeExecutable( argv );
	}


LocalExec::~LocalExec() { }

void LocalExec::MakeExecutable( const char** argv )
	{
	pid_ = 0;
	exec_error = 1;
	has_exited = 0;

	if ( access( executable, X_OK ) < 0 )
		return;

	/*
	** Ignore ^C coming from parent because ^C is used in the
	** interpreter interface, and it gets delievered to all children.
	*/
	signal_handler old_sigint = install_signal_handler( SIGINT, (signal_handler) SIG_IGN );

	pid_ = (int) vfork();

	if ( pid_ == 0 )
		{ // child

#ifndef HAVE_CRT_EXTERNS_H
		char** env = environ;
#else
		char** env = *_NSGetEnviron( );
#endif

#ifndef POSIX
		execve( executable, (char **)argv, env );
#else
		execve( executable, (char *const*)argv, env );
#endif

		std::cerr << "LocalExec::MakeExecutable: couldn't exec ";
		perror( executable );
		_exit( -1 );
		}


	if ( pid_ > 0 )
		exec_error = 0;

	/*
	** Restore ^C
	*/
	install_signal_handler( SIGINT, (signal_handler) old_sigint );

	}


int LocalExec::Active( int ignore_deactivate )
	{
	if ( has_exited || exec_error || ( !ignore_deactivate && deactivated ) )
		return 0;

	return 1;
	}

void LocalExec::SetStatus( int s )
	{
	status = s;
	has_exited = 1;

	if ( ! WIFEXITED(s) )
		{
		AbnormalExit( s );
		std::cerr << "LocalExec::SetStatus: abnormal child termination for "
		     << executable << "\n";
		}
	}

void LocalExec::AbnormalExit( int ) { }

int LocalExec::Active()
	{
	return Active( 0 );
	}

void LocalExec::Ping()
	{
	if ( kill( pid_, SIGIO ) < 0 )
		{
		std::cerr << "LocalExec::Ping: problem pinging executable ";
		perror( executable );
		}
	}

int LocalExec::pid( )
	{
	return pid_;
	}
