// $Id: Select.h,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998 Associated Universities Inc.
#ifndef select_h
#define select_h

#include "system.h"

#include <sys/time.h>
#include <sys/types.h>
#include "Glish/List.h"

#if HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif

#if HAVE_SYS_TIME_H
#include <sys/time.h>
#endif

class Sequencer;
class SelectTimer;

glish_declare(PList,SelectTimer);
typedef PList(SelectTimer) timer_list;

#define alloc_Selecteeptr( num ) (Selectee**) alloc_memory( sizeof(Selectee*) * (num) )
#define realloc_Selecteeptr( ptr, num ) (Selectee**) realloc_memory( ptr, sizeof(Selectee*) * (num) )

class Selectee GC_FINAL_CLASS {
public:
	enum Type { READ, WRITE };

	Selectee( int fd_, Type type__ = READ ) : fd(fd_), type_(type__) { }
	virtual ~Selectee();

	int FD()	{ return fd; }
	Type type() 	{ return type_; }

	// returns non-zero if the selection should stop, zero otherwise
	virtual int NotifyOfSelection()	{ return 0; }

protected:
	int fd;
	Type type_;
	};


class SelectTimer GC_FINAL_CLASS {
public:
	// Creates a timer that expires "delta" seconds from now.
	// If "interval" is non-zero then after expiring the timer
	// will reset to expire after that many more seconds.
	SelectTimer( struct timeval* delta, struct timeval* interval = 0 );
	SelectTimer( long delta_sec, long delta_usec,
			long interval_sec = 0, long interval_usec = 0 );

	virtual ~SelectTimer();

	// Returns the timer's absolute expiration time.
	struct timeval ExpirationTime()			{ return exp_t; }

protected:
	friend class Selector;

	void Init( struct timeval* delta, struct timeval* interval );

	// Called by a Selector to indicate that the timer has expired.
	// Returns non-zero if the timer has reactivated itself, zero
	// if it is now inactive.
	int Expired();

	// Called to do whatever work is associated with the timer expiring.
	// Returns non-zero if the timer should reactive (ignored if the
	// interval value is itself zero), zero if the timer should become
	// inactive.
	virtual int DoExpiration();

	struct timeval exp_t;
	struct timeval interval_t;
	};

class Selector : public GlishRef {
public:
	Selector();
	virtual ~Selector();

	virtual void AddSelectee( Selectee* s );
	virtual void DeleteSelectee( int selectee_fd, Selectee *replacement=0 );

	// Returns the Selectee associated with the given fd, or, if
	// none, returns 0.
	Selectee* FindSelectee( int selectee_fd ) const;

	void AddTimer( SelectTimer* t );

	// For any file descriptors this Selector might read events from,
	// sets the corresponding bits in the passed fd_set.  The caller
	// may then use the fd_set in a call to select().  Returns the
	// number of fd's added to the mask.
	int AddInputMask( fd_set* mask );

	// If selection stops early due to non-zero return from Selectee's
	// NotifyOfSelection(), returns that non-zero value.  Otherwise
	// returns 0.
	virtual int DoSelection( Sequencer *seq, int CanBlock=1 );

	void BreakSelection();

protected:
	int max_num_fds;
	Selectee** selectees;	// array indexed by fd

	void FindTimerDelta( struct timeval *timeout, struct timeval &min_t );

	Selectee* current_selectee;	// current selectee being notified
	int selectee_count;

	// If true, delete selectee when notification done.
	int nuke_current_selectee;

	fd_set* r_fdset;
	fd_set* w_fdset;
	timer_list timers;

	int break_selection;
	};

#endif	/* select_h */
