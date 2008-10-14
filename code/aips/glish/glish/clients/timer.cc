// $Id: timer.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: timer.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $")
#include "system.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>

#if defined(_AIX)
// for bzero()
#include <strings.h>
#endif

#if HAVE_OSFCN_H
#include <osfcn.h>
#endif

#if HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif

#if HAVE_SYS_TIME_H
#include <sys/time.h>
#endif

#include "Glish/Client.h"
#include "Glish/List.h"

#include "Channel.h"


inline int streq( const char* a, const char* b )
	{
	return ! strcmp( a, b );
	}


//
//  TimeDesc details one time interval this client is handling.
//
//        Note: It is assumed that all strings entered in
//              "list" are dynamically allocated and are to
//              be freed by this class.
//
class TimeDesc
    {
    public:
	TimeDesc( double delay_v ) :
			delay_(delay_v), multiple(1) { }
	~TimeDesc();

	// which event names are associated with this interval
	name_list &names( ) { return list; }

	// what is the interval
	double delay( ) const { return delay_; }

	// these are used to build the interval list...
	// they allow the builder to step through the time list,
	// and construct an interval list (counting each time
	// this interval is crossed).
	double next( ) const { return delay_ * multiple; }
	void step( ) { multiple += 1; }
	void reset( ) { multiple = 1; }

    private:
	name_list list;
	double delay_;	
	int multiple;
    };

TimeDesc::~TimeDesc( )
	{
	for ( int i=list.length()-1; i >= 0; --i )
		free_memory((char*)list[i]);
	}

glish_declare(PList,TimeDesc);
typedef PList(TimeDesc) time_list;

//
//  TimeList just holds all of the time intervals this client
//  is handling
//
class TimeList
    {
    public:
	TimeList() { }
	~TimeList();

	// add one time interval
	void add_time( double val, const char *id );

	// remove one time interval
	void remove_time( const char *id );
	void remove_time( TimeDesc *t ) { delete times.remove(t); }

	// access time descriptions
	TimeDesc *operator[](int i) { return times[i]; }

	// how many intervals are we dealing with
	int length() { return times.length(); }

	// debugging
	void dump( FILE * );

    private:
	time_list times;
	int cur;
    };

void TimeList::add_time( double val, const char *id )
	{
	int count = 0;
	for ( ; count < times.length() && val > times[count]->delay(); ++count );

	if ( count >= times.length() )
		{
		times.append( new TimeDesc( val ) );
		times[times.length()-1]->names().append(strdup(id));
		}
	else
		{
		if ( times[count]->delay() > val )
			times.insert_nth( count, new TimeDesc( val ) );
		times[count]->names().append(strdup(id));
		}
	}

void TimeList::remove_time( const char *id )
	{
	for ( int i=0; i < times.length(); ++i )
		{
		name_list &nl = times[i]->names();
		for ( int j=0; j < nl.length(); ++j )
			if ( ! strcmp( id, nl[j] ) )
				{
				free_memory( nl.remove_nth(j) );
				if ( ! nl.length() )
					delete times.remove_nth(i);
				return;
				}
		}
	}

void TimeList::dump( FILE *f )
	{
	for ( int i=0; i < times.length(); ++i )
		{
		fprintf(f, "%f\n\t", times[i]->delay());
		for ( int j=0; j < times[i]->names().length(); j++ )
			fprintf(f, "%s ",times[i]->names()[j]);
		fprintf(f, "\n");
		}
	}

TimeList::~TimeList( )
	{
	for ( int i=times.length()-1; i >= 0; --i )
		delete times[i];
	}
	
//
// This is essentially one element of the "display list" for the
// timer events.
//
class Interval
    {
    public:

	// we need to know how long this interval is, and which
	// description is associated with it...
	Interval( double d, TimeDesc *td );
	~Interval( ) { }

	// how long is the interval
	double delay( ) const { return delay_; }

	// get the select() struct for this interval
	struct timeval val() const { return val_; }

	// get the time descriptor associated with this interval
	TimeDesc *desc() { return desc_; }

	// how many times should this interval be repeated
	// each pass through the "display list"
	unsigned int number() const { return repeat; }

	// bump the repeat count
	void incr( ) { ++repeat; }
    private:
	struct timeval val_;
	double delay_;
	TimeDesc *desc_;
	unsigned int repeat;
    };

glish_declare(PList,Interval);
typedef PList(Interval) interval_list;

Interval::Interval( double d, TimeDesc *td ) : delay_(d), desc_(td), repeat(1)
	{
	if ( delay_ > 0 )
		{
		// given a value like 4.32, convert to a timeval struct with, for example,
		// the seconds field set to 4 and the microseconds field set to 320000
		val_.tv_sec = (int) delay_;
		val_.tv_usec = (int) ((delay_ - (int) delay_) * 1000000.0);
		}
	else
		val_.tv_sec = val_.tv_usec = 0;
	}


enum elapse_options { INIT, USE };
//
// This is the "display list" for the timer client
//
class IntervalList
    {
    public:
	IntervalList( TimeList &tl_ ) : cur(0), start_interval(0),
					repeat_cnt(0), startup(1), tl(tl_) { }
	~IntervalList();

	// build the "display list"
	void build( elapse_options op );

	// clear the "display list"
	void clear( );

	// loop through the display list
	Interval *next( );

	// how far are we from the
	// beginning of the cycle
	double elapsed( elapse_options );

	// debugging
	void dump( FILE *f );
    private:
	interval_list list;
	int cur;
	int repeat_cnt;
	int startup;
	Interval *start_interval;
	TimeList &tl;
    };

void IntervalList::clear( )
	{
	cur = 0;
	startup = 1;

	if ( start_interval )
		{
		delete start_interval;
		start_interval = 0;
		}

	for ( int i=list.length()-1; i >= 0; --i )
		delete list.remove_nth(i);
	}

double IntervalList::elapsed( elapse_options opt )
	{
	static double last;

	if ( opt == INIT ) last = get_current_time();
	double cur = get_current_time();

	double ret = cur - last;
	return ret;
	}

void IntervalList::build( elapse_options opt )
	{
	double off = elapsed( opt );

	clear( );

	if ( ! tl.length() ) return;

	tl[0]->reset();
	double cur_time = tl[0]->delay();

	start_interval = new Interval( (off > 0.0 && off < cur_time ? cur_time - off : cur_time), tl[0] );
	tl[0]->step( );

	for ( int i=1; i < tl.length(); ++i )
		{
		tl[i]->reset();
		while ( cur_time < tl[i]->delay() )
			{
			double min_delay = tl[0]->next( ) - cur_time;
			TimeDesc *desc = tl[0];
			for ( int j=1; j <= i; ++j )
				if ( tl[j]->next() - cur_time < min_delay )
					{
					min_delay = tl[j]->next() - cur_time;
					desc = tl[j];
					}

			if ( list.length() && list[list.length()-1]->desc() == desc &&
			     list[list.length()-1]->delay() == min_delay )
				list[list.length()-1]->incr( );
			else
				list.append( new Interval( min_delay, desc ) );

			desc->step( );
			cur_time += min_delay;
			}
		}

	// need to complete the loop back to tl[0]
	if ( tl.length() > 1 )
		{
		TimeDesc *desc = 0;
		while ( desc != tl[0] )
			{
			desc = tl[0];
			double min_delay = tl[0]->next( ) - cur_time;
			for ( int j=1; j < tl.length(); ++j )
				if ( tl[j]->next() - cur_time < min_delay )
					{
					min_delay = tl[j]->next() - cur_time;
					desc = tl[j];
					}

			if ( list.length() && list[list.length()-1]->desc() == desc &&
			     list[list.length()-1]->delay() == min_delay )
				list[list.length()-1]->incr( );
			else
				list.append( new Interval( min_delay, desc ) );

			desc->step( );
			cur_time += min_delay;
			}
		}

	else 
		list.append( new Interval( tl[0]->delay(), tl[0] ) );
	}

Interval *IntervalList::next( )
	{
	if ( startup )
		if ( start_interval )
			{
			startup = 0;
			return start_interval;
			}
		else
			return 0;

	Interval *ret = list[cur];
	if ( ++repeat_cnt >= list[cur]->number() )
		{
		repeat_cnt = 0;
		if ( ++cur >= list.length() ) cur = 0;
		}

	return ret;
	}

void IntervalList::dump( FILE *f )
	{
	if ( start_interval )
		fprintf(f,"S:%f#%u\t", start_interval->delay(),start_interval->number());
	for ( int i=0; i < list.length(); ++i )
		fprintf(f,"%f#%u ", list[i]->delay(),list[i]->number());
	fprintf(f,"\n");
	}

IntervalList::~IntervalList( )
	{
	for ( int i=list.length()-1; i >= 0; --i )
		delete list[i];
	}

//
//  SOME NOTES:
//    o  IntervalList::next must handle repeating intervals
//    o  IntervalList::IntervalList needs to take and keep a reference
//           to TimeList
//    o  IntervalList::build must take into account where we currently
//           are in the timer period and use the TimeList reference
//
int main( int argc, char** argv )
	{
	Client c( argc, argv );

	char* prog_name = argv[0];
	++argv, --argc;

	TimeList tlist;
	IntervalList ilist( tlist );
	struct timeval timeout;

	int one_shot = 0;	// whether we should only fire once per "delay"
	if ( argc > 0 && streq( argv[0], "-oneshot" ) )
		{
		++one_shot;
		++argv, --argc;
		}

	if ( argc > 0 )
		tlist.add_time( atof(argv[0]), "" );

	fd_set selection_mask;
	FD_ZERO( &selection_mask );

	ilist.build( INIT );

	for ( ; ; )
		{
		Interval *cur = ilist.next();
		c.AddInputMask( &selection_mask );

		if ( cur ) timeout = cur->val();

		int status = select( FD_SETSIZE, (SELECT_MASK_TYPE *) &selection_mask,
				     0, 0, cur ? &timeout : 0 );

		if ( status < 0 )
			{
			fprintf( stderr, "%s: ", prog_name );
			perror( "select() returned for unknown reason" );
			exit( 1 );
			}

		// !!! FOR THESE ADVANCE Interval !!!
		else if ( status == 0 )
			{ // timeout elapsed
			  // cur should be non-zero
			Value val( cur->desc()->delay() );
			name_list &events = cur->desc()->names();
			for ( int i=0; i < events.length(); ++i )
				c.PostEvent( *events[i] ? events[i] : "ready", &val );

			if ( one_shot )
				{ // don't rearm
				tlist.remove_time(cur->desc());
				// !!! do we need to factor in  !!!
				// !!! time already elapsed??   !!!
				ilist.build( USE );
				}
			}

		// !!! FOR THESE REDO THE CURRENT Interval !!!
		else if ( c.HasClientInput( &selection_mask ) )
			{
			GlishEvent* e = c.NextEvent();

			if ( ! e )
				return 0;

			if ( streq( e->name, "interval" ) )
				{
				tlist.remove_time("");
				if ( e->value->DoubleVal() > 0 )
					tlist.add_time( e->value->DoubleVal(), "" );
				// !!! do we need to factor in  !!!
				// !!! time already elapsed??   !!!
				ilist.build( INIT );
				}

			else if ( streq( e->name, "stop" ) )
				{
				tlist.remove_time("");
				ilist.build( INIT );
				}

			else if ( streq( e->name, "sleep" ) )
				{ // "sleep" is a request/reply event,
				  // mainly for testing purposes.
				int duration = e->value->IntVal();
				sleep( duration );
				c.Reply( e->value );
				}

			else if ( streq( e->name, "register" ) )
				{ // register a "tagged" delay
				static char tag[40];
				static unsigned int tag_cnt = 0;
				Value *val = e->value;

				double *times = val->DoublePtr();
				charptr *tags = (charptr*) alloc_memory(val->Length()*sizeof(charptr));
				int len = 0;

				for (int i=0; i < val->Length(); ++i )
					if ( times[i] > 0 )
						{
						sprintf( tag, "tmr%x", ++tag_cnt );
						tlist.add_time( times[i], tag );
						tags[i] = strdup(tag);
						++len;
						}

				Value ret( tags, len );
				if ( e->IsRequest() )
					c.Reply( &ret );
				else
					c.PostEvent( "tag", &ret );

				// !!! do we need to factor in  !!!
				// !!! time already elapsed??   !!!
				ilist.build( INIT );
				}

			else if ( streq( e->name, "unregister" ) )
				{ // unregister a "tagged" delay
				Value *val = e->value;
				charptr *strs = val->StringPtr(0);

				for ( int i=0; i < val->Length(); ++i )
					tlist.remove_time(strs[i]);

				// !!! do we need to factor in  !!!
				// !!! time already elapsed??   !!!
				ilist.build( INIT );
				}

			else
				c.Unrecognized();
			}

		else
			{
			fprintf( stderr, "%s: bogus select() return\n",
				 prog_name );
			exit( 1 );
			}
		}
	}
