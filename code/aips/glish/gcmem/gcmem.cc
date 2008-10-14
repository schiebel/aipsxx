/* ======================================================================
** alloc.cc
**
** $Id: gcmem.cc,v 19.0 2003/07/16 05:17:22 aips2adm Exp $
**
** Copyright (c) 1997 Associated Universities Inc.
**
**======================================================================
*/
#define ENABLE_GC
#include "gcmem/alloc.h"
RCSID("@(#) $Id: gcmem.cc,v 19.0 2003/07/16 05:17:22 aips2adm Exp $")
#include "config.h"
#include <stdio.h>
#include <string.h>
#include <errno.h>

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

char *string_dup( const char *str )
	{
	int len = strlen( str )+1;
	return (char*) memmove( alloc_char(len), str, len );
	}

static struct timeval last_time_;
static struct timeval time_remaining_;
static number_;
static fd_set read_fds_;
static fd_set *read_fds_ptr_;
static fd_set write_fds_;
static fd_set *write_fds_ptr_;
static fd_set except_fds_;
static fd_set *except_fds_ptr_;
static int select_done_;
static int select_status_;
static int select_errno_;

int gc_stop_proc( )
	{
	if ( select_done_ ) return 1;

	struct timeval zero = { 0, 0 };

	if ( read_fds_ptr_ ) *read_fds_ptr_ = read_fds_;
	if ( write_fds_ptr_ ) *write_fds_ptr_ = write_fds_;
	if ( except_fds_ptr_ ) *except_fds_ptr_ = except_fds_;

	int status = select( number_, (SELECT_MASK_TYPE *) read_fds_ptr_,
			     (SELECT_MASK_TYPE *) write_fds_ptr_,
			     (SELECT_MASK_TYPE *) except_fds_ptr_, &zero );

	if ( status != 0 )
		{
		select_errno_ = errno;
		select_status_ = status < 0 && (errno == EINVAL || errno == EBADF) ? 0 : status;
		select_done_ = 1;
		return 1;
		}

	struct timeval cur_time;

        if ( GET_TIME( cur_time ) < 0 )
		return -1;

	time_remaining_.tv_sec -= cur_time.tv_sec - last_time_.tv_sec;
	time_remaining_.tv_usec -= cur_time.tv_usec - last_time_.tv_usec;
	while ( time_remaining_.tv_usec < 0 && time_remaining_.tv_sec > 0 )
		{
		--time_remaining_.tv_sec;
		time_remaining_.tv_usec += 1000000;
		}

	if ( time_remaining_.tv_sec < 0 || time_remaining_.tv_usec < 0 ||
	     time_remaining_.tv_sec == 0 && time_remaining_.tv_usec == 0 )
		{
		select_done_ = 1;
		select_status_ = 0;
		return 1;
		}

	last_time_ = cur_time;
	return 0;
	}

int  gc_select(int n, fd_set *readfds,  fd_set  *writefds,
	       fd_set *exceptfds, struct timeval *timeout )
	{

	//
	// simply return select with few allocations
	//
	if ( GC_get_bytes_since_gc() <  GC_get_heap_size()/4 )
		return select( n, readfds, writefds, exceptfds, timeout );

	int status;
	struct timeval zero = { 0, 0 };
	read_fds_ptr_ = readfds;
	write_fds_ptr_ = writefds;
	except_fds_ptr_ = exceptfds;

	if ( readfds ) read_fds_ = *readfds;
	if ( writefds ) write_fds_ = *writefds;
	if ( exceptfds ) except_fds_ = *exceptfds;

	if ( (status = select( n, (SELECT_MASK_TYPE *) readfds,
			       (SELECT_MASK_TYPE *) writefds,
			       (SELECT_MASK_TYPE *) exceptfds, &zero )) != 0 )
		return status;

	if ( timeout->tv_sec < 0 || timeout->tv_usec < 0 ||
	     timeout->tv_sec == 0 && timeout->tv_usec == 0 )
		return status;

	if ( GET_TIME( last_time_ ) < 0 )
		return -1;

	select_done_ = 0;
	select_errno_ = 0;
	select_status_ = 0;
	number_ = n;
	time_remaining_ = *timeout;

	GC_try_to_collect( gc_stop_proc );

	if ( ! select_done_  )
		{
		if ( time_remaining_.tv_sec < 0 || time_remaining_.tv_usec < 0 ||
		     time_remaining_.tv_sec == 0 && time_remaining_.tv_usec == 0 )
			return 0;
		
		if ( readfds ) *readfds = read_fds_;
		if ( writefds ) *writefds = write_fds_;
		if ( exceptfds ) *exceptfds = except_fds_;

		status = select( n, (SELECT_MASK_TYPE *) readfds,
				 (SELECT_MASK_TYPE *) writefds,
				 (SELECT_MASK_TYPE *) exceptfds, &time_remaining_ );

		//
		//  File descriptors can be closed in the process of
		//  collecting garbage... on solaris the closed FDs
		//  then result in errors from select...
		//
		if ( status < 0 && (errno == EINVAL || errno == EBADF) )
			return 0;

		return status;
		}

	errno = select_errno_;
	return select_status_;
	}
