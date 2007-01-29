// $Id: tell_glishd.cc,v 19.0 2003/07/16 05:14:19 aips2adm Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: tell_glishd.cc,v 19.0 2003/07/16 05:14:19 aips2adm Exp $")
#include "system.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if HAVE_OSFCN_H
#include <osfcn.h>
#endif

#include "Glish/Client.h"
#include "sos/io.h"

#include "Glish/Reporter.h"
#include "ports.h"

const char* prog_name;

void usage()
	{
	fprintf( stderr, "usage: %s -k [host]\n", prog_name );
	fprintf( stderr, "\t-k kill Glish daemon on given host\n" );
	exit( 1 );
	}


int main( int argc, char** argv )
	{
	prog_name = argv[0];
	++argv, --argc;

	if ( argc <= 0 )
		usage();

	if ( strcmp( argv[0], "-k" ) )
		usage();

	++argv, --argc;	// skip control flag

	if ( argc > 1 )
		usage();

	const char* host = (argc == 1) ? argv[0] : local_host_name();

	init_reporters();
	init_values();

	int daemon_socket = get_tcp_socket();
	if ( ! remote_connection( daemon_socket, host, DAEMON_PORT ) )
		{
		fprintf( stderr, "%s: couldn't connect to glishd on host %s\n",
				prog_name, host );
		exit( 1 );
		}

	sos_fd_sink sock( daemon_socket );
	send_event( sock, "*terminate-daemon*", (const Value*) 0 );

	return 0;
	}
