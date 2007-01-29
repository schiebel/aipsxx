// $Id: input.cc,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: input.cc,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $")
#include "system.h"
#include <iostream.h>
#if HAVE_OSFCN_H
#include <osfcn.h>
#endif

#include "input.h"
#include "Sequencer.h"

char *readline_read( const char *prompt, int new_editor )
	{
	// currently not implemented outside interpreter...
	return 0;
	}

int interactive_read( FILE* file, const char prompt[], char buf[],
			int max_size )
	{
#ifndef __GNUC__
        static int did_sync = 0;
        if ( ! did_sync )
		{
		ios::sync_with_stdio();
		did_sync = 1;
		}
#endif

	cout << prompt;
	cout.flush();

	current_sequencer->EventLoop();

	return read( fileno( file ), buf, max_size );
	}
