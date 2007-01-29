// $Id: Queue.cc,v 19.12 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: Queue.cc,v 19.12 2004/11/03 20:38:58 cvsmgr Exp $")
#include "Glish/Queue.h"


BaseQueue::BaseQueue()
	{
	head = tail = 0;
	num_entries = 0;
	cur = 0;
	}

void BaseQueue::EnQueue( void* element )
	{
	QueueElement* qe = new QueueElement( element );

	if ( ! head )
		head = tail = qe;

	else
		{
		tail->next = qe;
		tail = qe;
		}
	++num_entries;
	}

void* BaseQueue::DeQueue()
	{
	if ( ! head )
		return 0;

	QueueElement* qe = head;
	head = head->next;

	if ( qe == tail )
		tail = 0;

	void* result = qe->elem;
	delete qe;

	--num_entries;
	return result;
	}

void *BaseQueue::Next()
	{
	if ( ! cur ) return 0;
	QueueElement *el = cur;
	cur = cur->next;
	return el->elem;
	}
