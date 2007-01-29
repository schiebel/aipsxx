//======================================================================
// str.cc
//
// $Id: str.cc,v 19.0 2003/07/16 05:17:49 aips2adm Exp $
//
// Copyright (c) 1997 Associated Universities Inc.
//
//======================================================================
#include "sos/sos.h"
RCSID("@(#) $Id: str.cc,v 19.0 2003/07/16 05:17:49 aips2adm Exp $")
#include "sos/str.h"

str_kernel::str_kernel( const char *s ) : cnt(1), size(1)
	{
	ary = (char**) alloc_zero_memory(size*sizeof(char*));
	len = (unsigned int*) alloc_zero_memory_atomic(size*sizeof(unsigned int));
	if ( s && *s )
		{
		len[0] = ::strlen(s);
		ary[0] = alloc_char(len[0]+1);
		memcpy(ary[0],s,len[0]+1);
		}
	}

void str_kernel::set( unsigned int off, const char *s )
	{
	if ( s && *s )
		{
		register unsigned int s_len = ::strlen(s);
		if ( ary[off] )
			{
			if ( len[off] < s_len )
				ary[off] = (char*) realloc_memory(ary[off],s_len+1);
			}
		else
			ary[off] = alloc_char(s_len+1);

		len[off] = s_len;
		memcpy(ary[off],s,s_len+1);
		}
	else
		{
		len[off] = 0;
		if ( ary[off] ) ary[off][0] = '\0';
		}
	}

void str_kernel::set( unsigned int off, char *s, int take_array )
	{
	if ( ! take_array ) { set( off, (const char*) s ); return; }

	if ( ary[off] )
		free_memory( ary[off] );

	if ( s && *s )
		{
		len[off] = ::strlen(s);
		ary[off] = s;
		}
	else
		{
		len[off] = 0;
		ary[off] = 0;
		}
	}

str_kernel *str_kernel::clone() const
	{
	str_kernel *nk = new str_kernel(size);
	for ( unsigned int i=0; i < size; i++ )
		if ( ary[i] && len[i] )
			{
			nk->ary[i] = alloc_char(len[i]+1);
			memcpy(nk->ary[i],ary[i],len[i]+1);
			nk->len[i] = len[i];
			}
	return nk;
	}

void str_kernel::grow( unsigned int new_size )
	{
	if ( new_size <= size )
		{
		for ( int i = new_size; i < size; i++ )
			free_memory( ary[i] );
		size = new_size;
		}
	else
		{
		ary = (char**) realloc_memory(ary,new_size*sizeof(char*));
		len = (unsigned int*) realloc_memory(len,new_size*sizeof(unsigned int));
		for ( unsigned int i = size; i < new_size; i++ )
			{
			ary[i] = 0;
			len[i] = 0;
			}
		size = new_size;
		}
	}

str_kernel::~str_kernel( )
	{
	for ( unsigned int x = 0; x < size; x++ )
		if ( ary[x] ) free_memory( ary[x] );
	free_memory(ary);
	free_memory(len);
	}

void str::do_copy()
	{
	if ( kernel->count() > 1 )
		{
		kernel->unref();
		kernel = kernel->clone();
		}
	}
