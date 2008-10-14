// $Id: Pager.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1997,1998 Associated Universities Inc.

#include "config.h"
#include "Glish/glish.h"
RCSID("@(#) $Id: Pager.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $")
#include "Pager.h"
#include "Executable.h"

Reporter* pager = 0;

void PagerReporter::report( const ioOpt &opt, const RMessage& m0,
			    const RMessage& m1, const RMessage& m2,
			    const RMessage& m3, const RMessage& m4,
			    const RMessage& m5, const RMessage& m6,
			    const RMessage& m7, const RMessage& m8,
			    const RMessage& m9, const RMessage& m10,
			    const RMessage& m11, const RMessage& m12,
			    const RMessage& m13, const RMessage& m14,
			    const RMessage& m15, const RMessage& m16
			  )
	{

	if ( ValCtor::silent( ) ) return;

	charptr *exec_ary = seq->System().PagerExec();
	int exec_len = seq->System().PagerExecLen();
	int limit = seq->System().PagerLimit();
	char *exec = 0;

	if ( ! exec_ary || exec_len < 0 || limit < 0 ||
	     ! (exec = which_executable( exec_ary[0] )) )
		glish_message->report( opt, m0, m1,  m2,  m3,  m4,  m5,  m6,  m7, m8,
				 m9, m10, m11, m12, m13, m14, m15, m16 );
	else
		{
		stream.reset();
		Reporter::report( opt, m0, m1,  m2,  m3,  m4,  m5,  m6,  m7, m8,
				  m9, m10, m11, m12, m13, m14, m15, m16 );

		int line_count = 0;
		int char_count = 0;
		for ( const char *ptr = ((SOStream&)stream).str(); *ptr; ++ptr, ++char_count )
			if ( *ptr == '\n' ) line_count++;

		if ( line_count <= limit &&
		     char_count / 85 <= limit )
			glish_message->report( opt, ((SOStream&)stream).str() );
		else
			{
			int x = 0;

			char **argv = alloc_charptr( exec_len+1 );
			argv[x++] = exec;
			for ( ; x < exec_len; ++x )
				argv[x] = (char*) exec_ary[x];
			argv[x] = 0;
			stream << "\n";
			seq->PagerOutput( ((SOStream&)stream).str(), argv );
			free_memory( argv );
			}

		free_memory( exec );
		}
	}

void PagerReporter::Prolog( const ioOpt & )
	{
	}

void PagerReporter::Epilog( const ioOpt & )
	{
	stream.flush();
	}


void init_interp_reporters( Sequencer *s )
	{
	static int did_init = 0;
	if ( ! did_init )
		{
		init_reporters();
		pager = new PagerReporter( s );
		did_init = 1;
		}
	}

void finalize_interp_reporters()
	{
	static int did_final = 0;
	if ( ! did_final )
		{
		finalize_reporters();
		delete pager;
		did_final = 1;
		}
	}
