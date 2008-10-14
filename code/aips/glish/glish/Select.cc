// $Id: Select.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: Select.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $")
#include "system.h"
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <string.h>
#include <stdlib.h>
#include "Sequencer.h"
#include "Glish/Reporter.h"

#if defined(_AIX)
// for bzero()
#include <strings.h>
#endif

#if HAVE_OSFCN_H
#include <osfcn.h>
#endif

#ifdef HAVE_X11_FD_H
#include <X11/fd.h>
#endif

#ifdef SETRLIMIT_NOT_DECLARED
extern "C" int setrlimit(int, const struct rlimit *);
extern "C" int getrlimit(int, struct rlimit *);
#endif

#ifdef SELECT_NOT_DECLARED
extern "C" int select( int, SELECT_MASK_TYPE*, SELECT_MASK_TYPE*,
		      SELECT_MASK_TYPE*, void* );
#endif

#ifdef GETTOD_NOT_DECLARED
extern "C" int gettimeofday (struct timeval *, struct timezone *);
#endif

#ifdef HAVE_BSDGETTIMEOFDAY
#define gettimeofday BSDgettimeofday
#endif

#ifdef __CLCC__
#define GET_TIME(x) gettimeofday( &x )
#else
#define GET_TIME(x) gettimeofday( &x, (struct timezone *) 0 )
#endif

#include "Select.h"


void gripe( const char* msg );


// Increment a timeval by the given amount.
void increment_time( struct timeval& t, const struct timeval& incr )
	{
	t.tv_sec += incr.tv_sec;
	t.tv_usec += incr.tv_usec;

	while ( t.tv_usec >= 1000000 )
		{
		++t.tv_sec;
		t.tv_usec -= 1000000;
		}
	}

// Decrement a timeval by the given amount.
void decrement_time( struct timeval& t, const struct timeval& decr )
	{
	t.tv_sec -= decr.tv_sec;
	t.tv_usec -= decr.tv_usec;

	while ( t.tv_usec < 0 )
		{
		--t.tv_sec;
		t.tv_usec += 1000000;
		}
	}

// Returns true if t1 is chronologically less than t2, false otherwise.
int time_less_than( const struct timeval& t1, const struct timeval& t2 )
	{
	return t1.tv_sec < t2.tv_sec ||
		(t1.tv_sec == t2.tv_sec && t1.tv_usec < t2.tv_usec);
	}


Selectee::~Selectee()
	{
	}


SelectTimer::SelectTimer( struct timeval* delta, struct timeval* interval )
	{
	Init( delta, interval );
	}

SelectTimer::SelectTimer( long delta_sec, long delta_usec,
			long interval_sec, long interval_usec )
	{
	struct timeval delta;
	delta.tv_sec = delta_sec;
	delta.tv_usec = delta_usec;

	struct timeval interval;
	interval.tv_sec = interval_sec;
	interval.tv_usec = interval_usec;

	Init( &delta, &interval );
	}

SelectTimer::~SelectTimer()
	{
	}


void SelectTimer::Init( struct timeval* delta, struct timeval* interval )
	{

	if ( GET_TIME( exp_t ) < 0 )
		gripe( "gettimeofday failed" );

	increment_time( exp_t, *delta );

	if ( interval )
		interval_t = *interval;
	else
		interval_t.tv_sec = interval_t.tv_usec = 0;
	}

int SelectTimer::Expired()
	{
	if ( DoExpiration() &&
	     (interval_t.tv_sec > 0 || interval_t.tv_usec > 0) )
		{
		increment_time( exp_t, interval_t );
		return 1;
		}

	return 0;
	}

int SelectTimer::DoExpiration()
	{
	return 1;
	}


Selector::Selector() : break_selection(0)
	{
#ifdef HAVE_SETRLIMIT
	struct rlimit rl;
	if ( getrlimit( RLIMIT_NOFILE, &rl ) < 0 )
		gripe( "getrlimit() failed" );

	max_num_fds = int( rl.rlim_max );
#else
	max_num_fds = 32;
#endif

	selectees = alloc_Selecteeptr( max_num_fds );

	for ( int i = 0; i < max_num_fds; ++i )
		selectees[i] = 0;

	current_selectee = 0;
	nuke_current_selectee = 0;
	selectee_count = 0;

	r_fdset = (fd_set*) alloc_memory_atomic( sizeof(fd_set) );
	FD_ZERO( r_fdset );
	w_fdset = (fd_set*) alloc_memory_atomic( sizeof(fd_set) );
	FD_ZERO( w_fdset );
	}

Selector::~Selector()
	{
	for ( int i = 0; i < max_num_fds; ++i )
		delete selectees[i];

	free_memory( selectees );
	free_memory( r_fdset );
	free_memory( w_fdset );
	}

void Selector::AddSelectee( Selectee* s )
	{
	selectees[s->FD()] = s;

	if ( s->type() == Selectee::READ )
		FD_SET( s->FD(), r_fdset );
	else
		FD_SET( s->FD(), w_fdset );

	++selectee_count;
	}

void Selector::DeleteSelectee( int selectee_fd, Selectee *replacement )
	{
	if ( selectee_fd < 0 )
		return;

	if ( ! FD_ISSET( selectee_fd, r_fdset ) && ! FD_ISSET( selectee_fd, w_fdset ) )
		return;

	Selectee* s = selectees[selectee_fd];

	selectees[selectee_fd] = 0;

	if ( ! s )
		{
		glish_error->Report( "bad fd in Selector::DeleteSelectee" );
		return;
		}

	if ( s->type() == Selectee::READ )
		FD_CLR( selectee_fd, r_fdset );
	else
		FD_CLR( selectee_fd, w_fdset );

	if ( s == current_selectee )
		// Don't delete it right now, while it's in use, just
		// flag that we should do so when we're done with it.
		nuke_current_selectee = 1;

	else
		delete s;

	--selectee_count;

	if ( replacement )
		AddSelectee( replacement );

	}

Selectee* Selector::FindSelectee( int selectee_fd ) const
	{
	if ( ! FD_ISSET( selectee_fd, r_fdset ) && ! FD_ISSET( selectee_fd, w_fdset ) )
		return 0;

	return selectees[selectee_fd];
	}

void Selector::AddTimer( SelectTimer* t )
	{
	timers.append( t );
	}

int Selector::AddInputMask( fd_set* mask )
	{
	int num = selectee_count;
	int num_added = 0;

	// what should be done about the write fds? For now,
	// we ignore them, and this should generally be OK.
	for ( int cnt=0; num && cnt < FD_SETSIZE; ++cnt )
		if ( FD_ISSET(cnt, r_fdset ) )
			{
			if ( ! FD_ISSET( cnt, mask ) )
				{
				FD_SET( cnt, mask );
				++num_added;
				}
			--num;
			}

	return num_added;
	}

void Selector::FindTimerDelta( struct timeval *timeout, struct timeval &min_t )
	{
	if ( timers.length() > 0 )
		{
		int have_min = 0;

		for ( int i = 0; i < timers.length(); ++i )
			{
			struct timeval timer_t = timers[i]->ExpirationTime();

			if ( ! have_min )
				{
				min_t = timer_t;
				have_min = 1;
				}

			else
				{
				if ( time_less_than( timer_t, min_t ) )
					min_t = timer_t;
				}
			}

		if ( ! have_min )
			gripe( "internal consistency problem" );

		struct timeval t;

		if ( GET_TIME( t ) < 0 )
			gripe( "gettimeofday failed" );

		*timeout = min_t;

		// Convert the timeout to a delta from the current time.

		if ( time_less_than( *timeout, t ) )
			{ // Don't decrement the timeout, it'll go negative.
			timeout->tv_sec = timeout->tv_usec = 0;
			}

		else
			decrement_time( *timeout, t );
		}
	else
		timeout = 0;
	}

void Selector::BreakSelection()
	{
	break_selection = 1;
	}

int Selector::DoSelection( Sequencer *seq, int CanBlock )
	{
	break_selection = 0;

	if ( seq->AwaitDone( ) ) return 1;

	struct timeval min_t;
	struct timeval timeout_buf;
	struct timeval *timeout = &timeout_buf;
	struct timeval noblock;

	FindTimerDelta( timeout, min_t );

	if ( ! CanBlock )
		{
		noblock.tv_sec = noblock.tv_usec = 0;
		timeout = &noblock;
		}

	fd_set read_mask = *r_fdset;
	fd_set write_mask = *w_fdset;
	int status;

	if ( (status = gc_select( FD_SETSIZE, (SELECT_MASK_TYPE *) &read_mask,
			(SELECT_MASK_TYPE *) &write_mask, (SELECT_MASK_TYPE *) 0, timeout )) < 0 )
		{
		//
		// If a client dies between the time we set up the masks and the
		// call to select(), we get a EBADF (bad file descriptor). We get
		// a EINTR when a signal occurs while waiting in the select().
		//
		if ( errno != EINTR && errno != EBADF )
			gripe( "error in DoSelection()" );

		return 0;
		}


	if ( status == 0 )
		{ // Timeout expired.  Assume current time is min_t.
		for ( int i = 0; i < timers.length(); ++i )
			{
			struct timeval timer_t = timers[i]->ExpirationTime();
			if ( ! time_less_than( min_t, timer_t ) )
				// timer_t <= min_t
				if ( ! timers[i]->Expired() )
					{
					// Timer is now inactive.
					timers.remove_nth( i );
					--i;	// because loop's about to ++
					}
			}
		}

	for ( int i = 0; status > 0 && i < max_num_fds; ++i )
		{
		if ( FD_ISSET( i, &read_mask ) || FD_ISSET( i, &write_mask ) )
			{

			if ( (current_selectee = selectees[i]) )
				{
				nuke_current_selectee = 0;

				static int count = 0;
				int last = ++count;
				int selectee_value =
					current_selectee->NotifyOfSelection();

				if ( nuke_current_selectee )
					delete current_selectee;

				current_selectee = 0;

				if ( selectee_value )
					return selectee_value;

				// We must watch because recursive calls to
				// Selector::DoSelection() can read all of the
				// active file descriptors and leave us hanging.
				if ( count != last )
					return 0;
				}

			--status;
			}

		if ( break_selection ) {return 1;}
		}

	if ( status != 0 )
		gripe( "inconsistency in DoSelection()" );

	return 0;
	}

void gripe( const char* msg )
	{
	fprintf( stderr, "Selector/Selectee/SelectTimer error: %s\n", msg );
	perror( "perror value" );
	exit( 1 );
	}
