// $Id: list.cc,v 19.1 2004/07/13 22:37:02 dschieb Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,2000 Associated Universities Inc.

#include "sos/sos.h"
RCSID("@(#) $Id: list.cc,v 19.1 2004/07/13 22:37:02 dschieb Exp $")
#include "sos/alloc.h"
#include <stdio.h>
#include <iostream>
#include <stdlib.h>

#include "sos/list.h"

static const int DEFAULT_CHUNK_SIZE = 10;

// Print message on stderr and exit.
static void default_error_handler(char* s)
	{
	std::cerr << s << "\n";
	exit(1);
	}

FINAL BaseList::set_finalize_handler(FINAL handler)
	{
	FINAL old = finalize_handler;
	finalize_handler = handler;
	return old;
	}

BaseList::BaseList(int size, FINAL handler)
	{
	if ( size <= 0 )
		chunk_size = DEFAULT_CHUNK_SIZE;
	else
		chunk_size = size;

	if ( size < 0 )
		{
		num_entries = max_entries = 0;
		entry = 0;
		}
	else
		{
		num_entries = 0;
		if ( (entry = (ent*) allocate(sizeof(ent) * chunk_size)) )
			max_entries = chunk_size;
		else
			max_entries = 0;
		}

	finalize_handler = handler;
	}


BaseList::BaseList(BaseList& b)
	{
	max_entries = b.max_entries;
	chunk_size = b.chunk_size;
	num_entries = b.num_entries;
	finalize_handler = b.finalize_handler;


	if ( max_entries )
		entry = (ent*) allocate( sizeof(ent)*max_entries );
	else
		entry = 0;

	for ( int i = 0; i < num_entries; i++ )
		entry[i] = b.entry[i];
	}

void BaseList::operator=(BaseList& b)
	{
	if ( this == &b )
		return;	// i.e., this already equals itself

	free_memory( entry );

	max_entries = b.max_entries;
	chunk_size = b.chunk_size;
	num_entries = b.num_entries;
	finalize_handler = b.finalize_handler;

	if ( max_entries )
		entry = (ent*) allocate( sizeof(ent)*max_entries );
	else
		entry = 0;

	for ( int i = 0; i < num_entries; i++ )
		entry[i] = b.entry[i];
	}

int BaseList::operator==(BaseList& b) const
	{
	if ( this == &b )
		return 1;

	if ( num_entries == b.num_entries && 
	     ! memcmp( entry, b.entry, sizeof(ent)*num_entries ) )
		return 1;

	return 0;
	}

void BaseList::insert(ent a)
	{
	if ( num_entries == max_entries )
		resize( );	// make more room

	for ( int i = num_entries; i > 0; i-- )	
		entry[i] = entry[i-1];	// move all pointers up one

	num_entries++;
	entry[0] = a;
	}

void BaseList::insert_nth(int off, ent a)
	{
	if ( num_entries == max_entries )
		resize( );	// make more room

	if ( off > num_entries )
		off = num_entries + 1;

	if ( off < 0 ) off = 0;

	for ( int i = num_entries; i > off; i-- )	
		entry[i] = entry[i-1];	// move all pointers up one

	num_entries++;
	entry[off] = a;
	}

ent BaseList::remove(ent a)
	{
	int i = 0;
	for ( ; i < num_entries && a != entry[i]; i++ )
		;

	return remove_nth(i);
	}

ent BaseList::remove_nth(int n)
	{
	if ( n < 0 || n >= num_entries )
		return 0;

	ent old_ent = entry[n];
	--num_entries;

	for ( ; n < num_entries; n++ )
		entry[n] = entry[n+1];

	entry[n] = 0;	// for debugging
	return old_ent;
	}

// Get and remove from the end of the list.
ent BaseList::get()
	{
	if ( num_entries == 0 )
		{
		default_error_handler("get from empty BaseList");
		return 0;
		}

	return entry[--num_entries];
	}


void BaseList::clear()
	{
	if ( finalize_handler )
		for ( int i = 0; i < num_entries; i++ )
			finalize_handler(entry[i]);
	num_entries = 0;
	}

BaseList::~BaseList()
	{
	if ( finalize_handler )
		for ( int i = 0; i < num_entries; i++ )
			finalize_handler(entry[i]);
	free_memory( entry );
	}

ent BaseList::replace(int ent_index,ent new_ent)
	{
	if ( ent_index < 0 || ent_index > num_entries-1 )
		{
		return 0;
		}
	else
		{
		ent old_ent = entry[ent_index];
		entry[ent_index] = new_ent;
		return old_ent;
		}
	}

int BaseList::resize( int needed )
	{
	while ( num_entries + needed > max_entries )
		max_entries += chunk_size;
	chunk_size *= 2;
	entry = (ent*) realloc_memory( (void*) entry, sizeof( ent ) * max_entries );
	return max_entries;
	}

ent BaseList::is_member(ent e) const
	{
	int i = 0;
	for ( ; i < length() && e != entry[i]; i++ )
		;

	return (i == length()) ? 0 : e;
	}

int BaseList::SoftDelete( )
	{
	return 1;
	}
