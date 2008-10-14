// $Id: test_client.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: test_client.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $")
#include <iostream>

#include "Glish/Client.h"

#include "Glish/Reporter.h"

int main( int argc, char** argv )
	{
	Client c( argc, argv );

	std::cout << argv[0] << " fired up, arg list is: ";

	for ( int i = 1; i < argc; ++i )
		{
		std::cout << argv[i];
		if ( i < argc - 1 )
			std::cout << ", ";
		}

	std::cout << "\n";

	for ( GlishEvent* e; (e = c.NextEvent()); )
		glish_message->Report( "received event, name = ", e->name,
				 ", value =", e->value );

	return 0;
	}
