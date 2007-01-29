// $Id: Socket.cc,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: Socket.cc,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $")
#include "system.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#if HAVE_OSFCN_H
#include <osfcn.h>
#endif

#include "Socket.h"


Socket::Socket( int arg_is_local, int socket_fd )
	{
	is_local = arg_is_local;

	if ( socket_fd < 0 )
		fd = is_local ? get_local_socket() : get_tcp_socket();
	else
		fd = socket_fd;

	port = 0;
	}

Socket::~Socket()
	{
	close( fd );
	}

void Socket::Gripe( char* msg )
	{
	fprintf( stderr, "Socket error: %s\n", msg );
	perror( "perror value" );
	exit( 1 );
	}

AcceptSocket::AcceptSocket( int arg_is_local, int port_hint, int is_a_hint )
: Socket( arg_is_local )
	{
	int result;

	do
		{
		if ( is_local )
			result = bind_local_socket( fd );
		else
			result = bind_socket( fd, port_hint );

		if ( ! is_a_hint )
			break;
		}
	while ( result == 0 && ++port_hint < 65535 );

	if ( result < 0 )
		Gripe( "couldn't bind AcceptSocket to any port" );

	if ( result == 0 )
		port = 0;
	else
		port = port_hint;
	}


Socket* AcceptSocket::Accept()
	{
	int new_connection = is_local ?
		accept_local_connection( fd ) : accept_connection( fd );

	if ( new_connection < 0 )
		Gripe( "problems with Accept()" );

	return new Socket( is_local, new_connection );
	}
