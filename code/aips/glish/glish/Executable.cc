// $Id: Executable.cc,v 19.13 2004/11/03 20:38:57 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.

#include "config.h"
#include "Glish/glish.h"
RCSID("@(#) $Id: Executable.cc,v 19.13 2004/11/03 20:38:57 cvsmgr Exp $")
#include "system.h"
#include <stdio.h>
#include <iostream>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <sys/file.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/types.h>

#if HAVE_OSFCN_H
#include <osfcn.h>
#endif

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#if HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif

#ifdef HAVE_SIGLIB_H
#include <sigLib.h>
#endif

#include "Executable.h"

#if defined(SIGCHLD)
#define GLISH_SIGCHLD SIGCHLD
#elif defined(SIGCLD)
#define GLISH_SIGCHLD SIGCLD
#endif


extern "C" {
char* getenv( const char* );
char* strdup( const char* );
}

Exec::Exec( ) { }
Exec::~Exec( ) { }
int Exec::pid( ) { return 0; }
void Exec::SetStatus( int ) { }

PList(ExecMinder) *ExecMinder::active_list = 0;

ExecMinder::ExecMinder( ) { }
ExecMinder::ExecMinder( Exec *ex ) : lexec(ex)
	{
	if ( ex )
		{
		if ( ! active_list ) active_list = new PList(ExecMinder);
		active_list->append( this );
		install_signal_handler( GLISH_SIGCHLD, (signal_handler) sigchld );
		}
	}

ExecMinder::~ExecMinder( )
	{
	if ( active_list )
		{
		loop_over_list( *active_list, i )
			if ( (*active_list)[i] == this )
				{
				(*active_list).remove_nth(i);
				break;
				}
		}
	}

void ExecMinder::sigchld( )
	{
	int status = 0;
	int pid_ = wait_for_pid( -1, &status, WNOHANG );

	while ( pid_ > 0 )
		{
		int found = 0;
		if ( active_list )
			loop_over_list( *active_list, i )
				if ( (*active_list)[i]->pid() == pid_ )
					{
					found = 1;
					if ( WIFEXITED( status ) || WIFSIGNALED( status ) )
						{
						(*active_list)[i]->SetStatus( status );
						(*active_list).remove_nth(i);
						}
					else if ( WIFSTOPPED(status) )
						std::cerr << "ExecMinder::sigchld: process " <<
						  pid_ << " stopped" << std::endl;
					break;
					}

		if ( ! found ) status_pupdate( pid_, status );
		pid_ = wait_for_pid( -1, &status, WNOHANG );
		}

	unblock_signal( GLISH_SIGCHLD );
	}

void ExecMinder::ForkReset( )
	{
	if ( active_list && (*active_list).length() )
		{
		// keeps all the ExecMinder's we're deleting (by deleting
		// Exec's) from trying to search through our list.
		PList(ExecMinder) *list = active_list;
		active_list = 0;
		while ( (*list).length() )
			{
			(*list).remove_nth((*list).length()-1);
//
//			causes a crash, need to understand why:
//
// 			ExecMinder *cur = (*list).remove_nth((*list).length()-1);
// 			delete cur->lexec;
			}
		active_list = list;
		}
	}


Executable::Executable( const char* arg_executable )
	{
	executable = string_dup( arg_executable );
	exec_error = has_exited = deactivated = 0;
	}

void Executable::DoneReceived() { }

Executable::~Executable()
	{
	free_memory( executable );
	}

int can_execute( const char* name )
	{
	if ( access( name, X_OK ) == 0 )
		{
		struct stat sbuf;
		// Here we are checking to make sure we have either a
		// regular file or a symbolic link
		if ( stat( name, &sbuf ) == 0 && ( S_ISREG(sbuf.st_mode)
#ifdef S_ISLNK
		      || S_ISLNK(sbuf.st_mode)
#endif
		   ) )
			return 1;
		}

	return 0;
	}

static charptr *executable_path = 0;
static int executable_path_len = 0;

void set_executable_path( charptr *path, int len )
	{
	executable_path = path;
	executable_path_len = len;
	}

char* which_executable( const char* exec_name )
	{
	if ( ! exec_name ) return 0;

	if ( exec_name[0] == '/' || exec_name[0] == '.' )
		{
		char *exe = canonic_path(exec_name);
		exe = exe ? exe : string_dup(exec_name);
		if ( can_execute( exe ) ) return exe;
		free_memory( exe );
		return 0;
		}

	char directory[2048];
	if ( executable_path )
		{
		for ( int i = 0; i < executable_path_len; ++i )
			{
			sprintf( directory, "%s/%s", executable_path[i], exec_name );
			if ( can_execute( directory ) )
				{
				char *ret = canonic_path( directory );
				return ret ? ret : string_dup( directory );
				}
			}
		}
	else
		{
		char* path = getenv( "PATH" );

		if ( ! path ) return 0;

		char* dir_beginning = path;
		char* dir_ending = path;

		while ( *dir_beginning )
			{
			while ( *dir_ending && *dir_ending != ':' )
				++dir_ending;

			int hold_char = *dir_ending;

			if ( hold_char )
				*dir_ending = '\0';

			sprintf( directory, "%s/%s", dir_beginning, exec_name );

			if ( hold_char )
				*(dir_ending++) = hold_char;

			if ( can_execute( directory ) )
				{
				char *ret = canonic_path( directory );
				return ret ? ret : string_dup( directory );
				}

			dir_beginning = dir_ending;
			}
		}

	return 0;
	}
