// $Id: RemoteExec.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.

#include "config.h"
#include "Glish/glish.h"
RCSID("@(#) $Id: RemoteExec.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $")
#include <stdio.h>
#include <string.h>

#include "Glish/Value.h"
#include "Glish/Client.h"

#include "Channel.h"
#include "RemoteExec.h"
#include "system.h"


RemoteExec::RemoteExec( Channel* arg_daemon_channel, const char* arg_executable,
			const char *arg_name, const char** argv )
    : Executable( arg_executable )
	{
	daemon_channel = arg_daemon_channel;
	name = arg_name ? string_dup( arg_name ) : 0;

	char id_buf[64];
	static int remote_exec_id = 0;

	sprintf( id_buf, "remote task %d", ++remote_exec_id );
	id = string_dup( id_buf );

	int argc = 0;
	while ( argv[argc] ) ++argc;

	recordptr rec = create_record_dict();
	rec->Insert( string_dup("name"), ValCtor::create( arg_name ? arg_name : arg_executable ) );
	rec->Insert( string_dup("argv"), ValCtor::create( argv, argc, COPY_ARRAY ) );
	rec->Insert( string_dup("id"), ValCtor::create( id ) );
	Value param( rec );
	send_event( daemon_channel->Sink(), "client", &param );
	}


RemoteExec::~RemoteExec()
	{
	if ( Active() )
		{
		Value id_value( id );
		send_event( daemon_channel->Sink(), "kill", &id_value );
		}

	free_memory( id );
	free_memory( name );
	}


void RemoteExec::Ping()
	{
	if ( Active() )
		{
		Value id_value( id );
		send_event( daemon_channel->Sink(), "ping", &id_value );
		}
	}


int RemoteExec::Active()
	{
	if ( has_exited || exec_error || deactivated )
		return 0;
	else
		return 1;	// ### query agent?
	}
