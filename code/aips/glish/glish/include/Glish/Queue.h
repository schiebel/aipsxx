// $Id: Queue.h,v 19.0 2003/07/16 05:15:53 aips2adm Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.
#ifndef queue_h
#define queue_h

#include "Glish/glish.h"

class BaseQueue;

#define Queue(type) glish_name2(type,Queue)
#define PQueue(type) glish_name2(type,PQueue)

class QueueElement GC_FINAL_CLASS {
    protected:
    friend class BaseQueue;
	QueueElement( void* element )
		{ elem = element; next = 0; }
	QueueElement* next;
	void* elem;
	};

class BaseQueue GC_FINAL_CLASS {
    public:
	BaseQueue();
	void EnQueue( void* element );
	void* DeQueue();
	int length() const { return num_entries; }
	void InitForIteration( ) { cur = head; }
	void *Next( );
    protected:
	int num_entries;
	QueueElement* head;
	QueueElement* tail;
	QueueElement* cur;
	};

#define Queuedeclare(type)						\
	class Queue(type) : public BaseQueue {				\
	    public:							\
		void EnQueue( type element )				\
			{ BaseQueue::EnQueue( (void*) element ); }	\
		type DeQueue()						\
			{ return (type) BaseQueue::DeQueue(); }		\
		type Next()						\
			{ return (type) BaseQueue::Next(); }		\
		}

#define PQueuedeclare(type)						\
	class PQueue(type) : public BaseQueue {				\
	    public:							\
		void EnQueue( type* element )				\
			{ BaseQueue::EnQueue( (void*) element ); }	\
		type* DeQueue()						\
			{ return (type*) BaseQueue::DeQueue(); }	\
		type* Next()						\
			{ return (type*) BaseQueue::Next(); }		\
		}

#endif	/* queue_h */
