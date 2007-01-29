// $Id: echo_client.cc,v 19.0 2003/07/16 05:14:21 aips2adm Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.
//
// Glish "echo" client - echoes back any event sent to it.
//

#include "Glish/glish.h"
RCSID("@(#) $Id: echo_client.cc,v 19.0 2003/07/16 05:14:21 aips2adm Exp $")
#include "Glish/Client.h"

int main( int argc, char** argv )
	{
	Client c( argc, argv );

	if ( argc > 1 )
		{
		// First echo our arguments.
		Value v( (charptr*) argv, argc, PRESERVE_ARRAY );

		c.PostEvent( "echo_args", &v );
		}

	for ( GlishEvent* e; (e = c.NextEvent()); )
		if ( e->IsRequest() )
			c.Reply( e->value );
		else
			c.PostEvent( e );

	return 0;
	}
