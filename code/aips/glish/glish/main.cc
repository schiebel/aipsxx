// $Id: main.cc,v 19.17 2004/11/03 20:38:59 cvsmgr Exp $
//
// Copyright (c) 1993 The Regents of the University of California.
// All rights reserved.
// Copyright (c) 1997,1998,2000,2004 Associated Universities Inc.
// All rights reserved.
//
// This code is derived from software contributed to Berkeley by
// Vern Paxson and software contributed to Associated Universities
// Inc. by Darrell Schiebel.
//
// The United States Government has rights in this work pursuant
// to contract no. DE-AC03-76SF00098 between the United States
// Department of Energy and the University of California, contract
// no. DE-AC02-89ER40486 between the United States Department of Energy
// and the Universities Research Association, Inc. and Cooperative
// Research Agreement #AST-9223814 between the United States National
// Science Foundation and Associated Universities, Inc.
//
// Redistribution and use in source and binary forms are permitted
// provided that: (1) source distributions retain this entire
// copyright notice and comment, and (2) distributions including
// binaries display the following acknowledgement:  ``This product
// includes software developed by the University of California,
// Berkeley, the National Radio Astronomy Observatory (NRAO), and
// their contributors'' in the documentation or other materials
// provided with the distribution and in all advertising materials
// mentioning features or use of this software.  Neither the names of
// the University or NRAO or the names of their contributors may be
// used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE.
//

#include "Glish/glish.h"
RCSID("@(#) $Id: main.cc,v 19.17 2004/11/03 20:38:59 cvsmgr Exp $")
#include "system.h"
#include <signal.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <setjmp.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <termios.h>
#include <sys/ioctl.h>

#if HAVE_OSFCN_H
#include <osfcn.h>
#endif

#ifdef HAVE_SIGINFO_H
#include <siginfo.h>
#endif
#ifdef HAVE_UCONTEXT_H
#include <ucontext.h>
#endif
#ifdef HAVE_FLOATINGPOINT_H
#include <floatingpoint.h>
#endif
#ifdef HAVE_MACHINE_FPU_H
#include <machine/fpu.h>
#endif

#include "input.h"
#include "glishlib.h"
#include "Glish/Reporter.h"
#include "Sequencer.h"
#include "IValue.h"
#include "Task.h"
#include "Glish/ValCtor.h"
#include "IValCtorKern.h"

static Sequencer* s = 0;
// used to recover from a ^C typed while glish
// is executing an instruction
int glish_top_jmpbuf_set = 0;
jmp_buf glish_top_jmpbuf;
int glish_include_jmpbuf_set = 0;
jmp_buf glish_include_jmpbuf;

int allwarn = 0;

#if USE_EDITLINE
extern "C" {
	char *readline( const char * );
	char *nb_readline( const char * );
	extern char *rl_data_incomplete;
	void add_history( char * );
	void nb_readline_cleanup();
	void *create_editor( );
	void *set_editor( void * );
	void finalize_readline_history( );
	void initialize_readline_history( const char * );
}
#endif

static void glish_dump_core( const char * );
static int handling_fatal_signal = 0;

static void install_terminate_handlers();

#define DEFINE_SIG_FWD(NAME,STRING,SIGNAL,COREDUMP)			\
void NAME( )								\
	{								\
	ValCtor::cleanup( );						\
	fprintf(stderr,"\n[fatal error, '%s' (signal %d), exiting]\n",	\
			STRING, SIGNAL);				\
									\
	install_signal_handler( SIGNAL, (signal_handler) SIG_DFL );	\
									\
	COREDUMP							\
									\
	kill( getpid(), SIGNAL );					\
	}

#if !defined(TCGETA)
#define TCGETA TIOCGETA
#define TCSETAF TIOCSETAF
#endif


DEFINE_SIG_FWD(glish_sighup,"hangup signal",SIGHUP,)
DEFINE_SIG_FWD(glish_sigterm,"terminate signal",SIGTERM,)
DEFINE_SIG_FWD(glish_sigabrt,"abort signal",SIGABRT,)

void glish_sigquit( )
	{
	ValCtor::cleanup( );
	fprintf(stderr,"exiting on ^\\ ...\n");
	fflush(stderr);
	exit(0);
	}

extern void yyrestart( FILE * );
void glish_sigint( )
	{
	if ( glish_include_jmpbuf_set || glish_top_jmpbuf_set )
		{
		if ( Sequencer::ActiveAwait() )
			glish_message->Report( Sequencer::ActiveAwait()->TerminateInfo() );
		Sequencer::TopLevelReset();
		unblock_signal(SIGINT);
		if ( glish_include_jmpbuf_set )
			longjmp( glish_include_jmpbuf, 1 );
		else
			longjmp( glish_top_jmpbuf, 1 );
		}

	char answ = 0;
	struct termios tbuf, tbufsave;
	int did_ioctl = 0;

	fprintf(stdout,"\nexit glish (y/n)? ");
	fflush(stdout);

	if ( ioctl( fileno(stdin), TCGETA, &tbuf) != -1 )
		{
		tbufsave = tbuf;
		tbuf.c_lflag &= ~ICANON;
		tbuf.c_cc[4] = 1;		/* MIN */
		tbuf.c_cc[5] = 9;		/* TIME */
		if ( ioctl( fileno(stdin), TCSETAF, &tbuf ) != -1 )
			did_ioctl = 1;
		}

	read( fileno(stdin), &answ, 1 );
	if ( did_ioctl )
		ioctl( fileno(stdin), TCSETAF, &tbufsave );

	fputc('\n',stdout);
	fflush(stdout);

	if ( answ == 'y' || answ == 'Y' )
		{
		ValCtor::cleanup( );
		install_signal_handler( SIGINT, (signal_handler) SIG_DFL );
		kill(getpid(), SIGINT);
		}

	unblock_signal(SIGINT);
	}

int main( int argc, char** argv )
	{
	ValCtor::init( new IValCtorKern );

	install_terminate_handlers();

	(void) install_signal_handler( SIGINT, glish_sigint );
	(void) install_signal_handler( SIGHUP, glish_sighup );
	(void) install_signal_handler( SIGTERM, glish_sigterm );
	(void) install_signal_handler( SIGABRT, glish_sigabrt );
	(void) install_signal_handler( SIGQUIT, glish_sigquit );

	seed_random_number_generator();

	s = new Sequencer( argc, argv );

	evalOpt opt;
	s->Exec(opt);

	ValCtor::cleanup();

	delete s;

	return 0;
	}

#define DUMP_CORE						\
	if ( ! handling_fatal_signal )				\
		{						\
		handling_fatal_signal = 1;			\
		glish_dump_core( "glish.core" );		\
		}

DEFINE_SIG_FWD(glish_sigsegv,"segmentation violation",SIGSEGV,DUMP_CORE)
DEFINE_SIG_FWD(glish_sigbus,"bus error",SIGBUS,DUMP_CORE)
DEFINE_SIG_FWD(glish_sigill,"illegal instruction",SIGILL,DUMP_CORE)
#ifdef SIGEMT
DEFINE_SIG_FWD(glish_sigemt,"hardware fault",SIGEMT,DUMP_CORE)
#endif
DEFINE_SIG_FWD(glish_sigtrap,"hardware fault",SIGTRAP,DUMP_CORE)
#ifdef SIGSYS
DEFINE_SIG_FWD(glish_sigsys,"invalid system call",SIGSYS,DUMP_CORE)
#endif

static void install_sigfpe();
static void install_terminate_handlers()
	{
	(void) install_signal_handler( SIGSEGV, glish_sigsegv );
	(void) install_signal_handler( SIGBUS, glish_sigbus );
	(void) install_signal_handler( SIGILL, glish_sigill );
#ifdef SIGEMT
	(void) install_signal_handler( SIGEMT, glish_sigemt );
#endif
	install_sigfpe();
	(void) install_signal_handler( SIGTRAP, glish_sigtrap );
#ifdef SIGSYS
	(void) install_signal_handler( SIGSYS, glish_sigsys );
#endif
	}


#if USE_EDITLINE

static int fmt_readline_str( char* to_buf, int max_size, char* from_buf )
	{
	if ( from_buf )
		{
		char* from_buf_start = from_buf;

		while ( isspace(*from_buf_start) )
			++from_buf_start;

		if ( (int) strlen( from_buf_start ) <= max_size )
			to_buf = strcpy( to_buf, from_buf_start );
		else
			{
			glish_error->Stream() << "Not enough buffer size (in fmt_readline_str)"
			     << endl;
			free_memory( (void*) from_buf );
			return 0;
			}
		  
		sprintf( to_buf, "%s\n", from_buf_start );

		if ( from_buf )
			free_memory( (void*) from_buf );

		return strlen( to_buf );
		}

	else
		return 0;
	}

char *readline_read( const char *prompt, int new_editor )
	{
#ifndef __GNUC__
        static int did_sync = 0;
        if ( ! did_sync )
		{
		ios::sync_with_stdio();
		did_sync = 1;
		}
#endif

	char* ret;
	void *last_editor = 0;

	//
	// tell readline to create a new editor environment?
	//
	if ( new_editor ) last_editor = set_editor( create_editor( ) );

	ret = nb_readline( prompt );

	while ( ret == rl_data_incomplete )
		{
		int clc = current_sequencer->EventLoop();
		ret = clc ? nb_readline( prompt ) : readline( prompt );
		}

	if ( ret && *ret ) add_history( ret );

	if ( last_editor ) free_memory( set_editor( last_editor ) );

	return ret;
	}

int interactive_read( FILE* /* file */, const char prompt[], char buf[],
			int max_size )
	{
	return fmt_readline_str( buf, max_size, readline_read(prompt,0) );
	}

#endif

void describe_value( IValue *v )
	{
	glish_message->Report(v);
	}

static void glish_dump_core( const char *file )
	{
	IValue *stack = Sequencer::FuncNameStack();
	charptr *cptr = stack->StringPtr(0);
	for ( int i=0; i < stack->Length(); ++i )
		fprintf( stderr, "\t%s\n", cptr[i] );
	}

//
//  Handle SIGFPE, the complications are:
//
//	o  solaris 2.* must use sigfpe()
//	o  alpha must compile with -ieee and isolate portions
//		which need -ieee due to performance hit
//
//  note that these signal handlers are only used to trap integer
//  division problems, floats should happen with IEEE NaN and Inf
//
int glish_abort_on_fpe = 1;
int glish_sigfpe_trap = 0;
#if defined(__alpha) || defined(__alpha__)
int glish_alpha_sigfpe_init = 0;
#endif

//
// ONLY SOLARIS 2.*, I believe...
//
#if defined(HAVE_SIGFPE) && defined(FPE_INTDIV)
//
//  Catch integer division exception to prevent "1 % 0" from
//  crashing glish...
//
void glish_sigfpe( int, siginfo_t *, ucontext_t *uap )
	{
	glish_sigfpe_trap = 1;
	/*
	**  Increment program counter; ieee_handler does this by
	**  default, but here we have to use sigfpe() to set up the
	**  signal handler for integer divide by 0.
	*/
	uap->uc_mcontext.gregs[REG_PC] = uap->uc_mcontext.gregs[REG_nPC];

	if ( glish_abort_on_fpe )
		{
		ValCtor::cleanup( );
		fprintf(stderr,"\n[fatal error, 'floating point exception' (signal %d), exiting]\n", SIGFPE );
		sigfpe(FPE_INTDIV, (sigfpe_handler_type)SIGFPE_DEFAULT);
		kill( getpid(), SIGFPE );
		}
	}

//
//  Currently for solaris "as_short(1/0)" et al. doesn't give the right
//  result. There doesn't seem to be a good fix for this because casting
//  doesn't generate an exception; division is not the problem.
//
static void install_sigfpe() { sigfpe(FPE_INTDIV, (sigfpe_handler_type)(glish_sigfpe) ); }
#elif defined(__alpha) || defined(__alpha__)
//
// for the alpha, this should be defined in "alpha.c"
//
extern "C" void glish_sigfpe();
static void install_sigfpe()
	{
	glish_alpha_sigfpe_init = 1;
	install_signal_handler( SIGFPE, glish_sigfpe );
	ieee_set_fp_control(IEEE_TRAP_ENABLE_INV);
	}
#else
void glish_sigfpe( )
	{
	glish_sigfpe_trap = 1;

	if ( glish_abort_on_fpe )
		{
		ValCtor::cleanup( );
		fprintf(stderr,"\n[fatal error, 'floating point exception' (signal %d), exiting]\n", SIGFPE );
		install_signal_handler( SIGFPE, (signal_handler) SIG_DFL );
		kill( getpid(), SIGFPE );
		}
	}

static void install_sigfpe() { install_signal_handler( SIGFPE, glish_sigfpe ); }
#endif

static char copyright1[]  = "Copyright (c) 1993 The Regents of the University of California.";
static char Copyright2[] = "Copyright (c) 1997,1998,1999,2004 Associated Universities Inc.";
