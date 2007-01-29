// $Id: Stream.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1997 Associated Universities Inc.
//

#include "config.h"
#include "Glish/glish.h"
RCSID("@(#) $Id: Stream.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $")
#include "Glish/Stream.h"
#include "system.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <iostream>

#include "iosmacros.h"

int OStream::reset() { return 0; }

OStream &OStream::operator<<( OStream &(*f)(OStream&) )
	{
	return (*f)(*this);
	}

OStream &OStream::flush( )
	{
	return *this;
	}

char *DBuf::tmpbuf = 0;
DBuf::DBuf(unsigned int s)
	{
	if ( ! tmpbuf ) tmpbuf = alloc_char( 512 );
	size_ = s ? s : 1;
	buf = alloc_char( size_ + 1 );
	len_ = 0;
	}

DBuf::~DBuf() { free_memory( buf ); }

#define DEFINE_APPEND(TYPE)						\
int DBuf::put( TYPE v, const char *format )				\
	{								\
	sprintf(tmpbuf,format,v);					\
	unsigned int l = strlen(tmpbuf);				\
	if ( len_ + l + 1 >= size_ )					\
		{							\
		while ( len_ + l + 1 >= size_ ) size_ *= 2;		\
		buf = realloc_char( buf, size_ + 1 );			\
		}							\
	memcpy(&buf[len_],tmpbuf,l);					\
	len_ += l;							\
	return l;							\
	}

DEFINE_FUNCS_NO_CHARPTR(DEFINE_APPEND)
int DBuf::put( const char *v, const char * )
	{
	unsigned int l = strlen(v);
	if ( len_ + l + 1 >= size_ )
		{
		while ( len_ + l + 1 >= size_ ) size_ *= 2;
		buf = realloc_char( buf, size_ + 1 );
		}
	memcpy(&buf[len_],v,l);
	len_ += l;
	return l;
	}

void DBuf::reset() { len_ = 0; }

#define SOSTREAM_PUT(TYPE)			\
OStream &SOStream::operator<<( TYPE v )		\
	{					\
	buf.put(v);				\
	return *this;				\
	}

DEFINE_FUNCS(SOSTREAM_PUT)

int SOStream::reset()
	{
	buf.reset();
	return 1;
	}

OStream &endl(OStream &s)
	{
	s << "\n";
	return s;
	}

