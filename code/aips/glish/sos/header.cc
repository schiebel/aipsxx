//======================================================================
// header.cc
//
// $Id: header.cc,v 19.0 2003/07/16 05:17:48 aips2adm Exp $
//
// Copyright (c) 1997 Associated Universities Inc.
//
//======================================================================
#include "sos/sos.h"
RCSID("@(#) $Id: header.cc,v 19.0 2003/07/16 05:17:48 aips2adm Exp $")
#include "config.h"
#include <time.h>
#include <sys/time.h>
#include <stdlib.h>
#include "sos/header.h"
#include "sos/mdep.h"
#include "sos/types.h"
#include <string.h>

void sos_header_kernel::set( void *b, unsigned int l, sos_code t, int freeit )
	{
	if ( buf_ && freeit_ )
		free_memory( buf_ );
	buf_ = (unsigned char*) b;
	length_ = l;
	type_ = t;
	freeit_ = freeit;
	}

sos_header &sos_header::operator=( sos_header &h )
	{
	if ( kernel->unref() ) delete kernel;
	kernel = h.kernel;
	kernel->ref();
	return *this;
	}


#define HEADER_SET( TYPE, TAG )						\
void sos_header::set( TYPE *a, unsigned int l, int freeit )		\
	{								\
	if ( kernel->count() > 1 )					\
		{							\
		kernel->unref();					\
		kernel = new sos_header_kernel( a, l, TAG, freeit );	\
		}							\
	else								\
		kernel->set( a, l, TAG, freeit );			\
	}

HEADER_SET(byte,SOS_BYTE)
HEADER_SET(short,SOS_SHORT)
HEADER_SET(int,SOS_INT)
HEADER_SET(float,SOS_FLOAT)
HEADER_SET(double,SOS_DOUBLE)

void sos_header::set ( )
	{
	if ( kernel->count() > 1 )
		{
		kernel->unref();
		kernel = new sos_header_kernel( 0, 0, SOS_UNKNOWN );
		}
	else
		kernel->set( 0, 0, SOS_UNKNOWN);
	}

void sos_header::set( char *a, unsigned int l, sos_code t, int freeit )
	{
	if ( kernel->count() > 1 )
		{
		kernel->unref();
		kernel = new sos_header_kernel( a, l, t, freeit );
		}
	else
		kernel->set( a, l, t, freeit );
	}

void sos_header::set( unsigned char *a, unsigned int l, sos_code t, int freeit )
	{
	if ( kernel->count() > 1 )
		{
		kernel->unref();
		kernel = new sos_header_kernel( a, l, t, freeit );
		}
	else
		kernel->set( a, l, t, freeit );
	}

void sos_header::scratch( )
	{
	if ( kernel->count() == 1 && kernel->freeit_ ) return;
	if ( kernel->count() > 1 )
		{
		kernel->unref();
		kernel = new sos_header_kernel(alloc_char(size()), 0, SOS_UNKNOWN, 1 );
		}
	else
		kernel->set( alloc_char(size()), 0, SOS_UNKNOWN, 1 );
	}

void sos_header::useti( unsigned int i )
	{
	int off = 2 + user_offset( );
	kernel->buf_[ off++ ] = i & 0xff; i >>= 8;
	kernel->buf_[ off++ ] = i & 0xff; i >>= 8;
	kernel->buf_[ off++ ] = i & 0xff; i >>= 8;
	kernel->buf_[ off   ] = i & 0xff; i >>= 8;
	}

void sos_header::stamp( )
	{
	struct timeval tv = { 0, 0 };
	stamp( tv );
	}

void sos_header::stamp( struct timeval &initial )
	{
	int mn_ = SOS_MAGIC;
	unsigned char *mn = (unsigned char *) &mn_;
	unsigned char *ptr = kernel->buf_;
	*ptr++ = kernel->version_;		// 0
	*ptr++ = SOS_ARC;			// 1
	*ptr++ = kernel->type_;			// 2
	*ptr++ = sos_size(kernel->type_);	// 3
	// magic number
	*ptr++ = *mn++;				// 4
	*ptr++ = *mn++;				// 5
	*ptr++ = *mn++;				// 6
	*ptr++ = *mn++;				// 7
	// length
	unsigned int l = kernel->length_;
	*ptr++ = l & 0xff; l >>= 8;		// 8
	*ptr++ = l & 0xff; l >>= 8;		// 9
	*ptr++ = l & 0xff; l >>= 8;		// 10
	*ptr++ = l & 0xff; l >>= 8;		// 11
	// time seconds
	struct timeval tp;
	struct timezone tz;
	gettimeofday(&tp, &tz);
	int t = tp.tv_sec;

	if ( ! initial.tv_sec )
		{
		initial.tv_sec = tp.tv_sec;
		initial.tv_usec = tp.tv_usec;
		}

	// time seconds
	*ptr++ = t & 0xff; t >>= 8;		// 12
	*ptr++ = t & 0xff; t >>= 8;		// 13
	*ptr++ = t & 0xff; t >>= 8;		// 14
	*ptr++ = t & 0xff; t >>= 8;		// 15

	// time useconds -- introduced with SOS version #1
	if ( kernel->version( ) > 0 )
		{
		t = tp.tv_usec;
		*ptr++ = t & 0xff; t >>= 8;	// 16
		*ptr++ = t & 0xff; t >>= 8;	// 17
		*ptr++ = t & 0xff; t >>= 8;	// 18
		*ptr++ = t & 0xff; t >>= 8;	// 19
		}

	// future use
	*ptr++ = 0x0;
	*ptr++ = 0x0;

	// next 6 bytes user space
	}

void sos_header::adjust_version( )
	{
	if ( version() == 0 )
		{
		unsigned char *buf = kernel->buf_;
		buf[27] = buf[23];
		buf[26] = buf[22];
		buf[25] = buf[21];
		buf[24] = buf[20];
		buf[23] = buf[19];
		buf[22] = buf[18];
		buf[21] = buf[17];
		buf[20] = buf[16];
		buf[16] = buf[17] = buf[18] = buf[19] = 0;
		buf[0] = 1;
		}
	}

#ifdef SOS_DEBUG
ostream &operator<< (ostream &ios, const sos_header &h)
	{
	unsigned int v = h.time();
	char *time = string_dup(ctime((const time_t *) &v));
	int i = 0;
	for (i = strlen(time) - 1; i > 0 && time[i] == '\n'; --i );
	time[i+1] = '\0';

	ios << time << " ";
	switch( h.type() )
		{
		case SOS_BYTE: ios << "BYTE: "; break;
		case SOS_SHORT: ios << "SHORT: "; break;
		case SOS_INT: ios << "INT: "; break;
		case SOS_FLOAT: ios << "FLOAT: "; break;
		case SOS_DOUBLE: ios << "DOUBLE: "; break;
		case SOS_STRING: ios << "STRING: "; break;
		case SOS_RECORD: ios << "RECORD: "; break;
		default: ios << "UNKNOWN: ";
		}
	ios << "len=" << h.length() << ", type_len=" << (int) h.typeLen();
	ios << ", arch=";
	switch( h.arch() )
		{
		case SOS_SUN3ARC: ios << "sun3arc"; break;
		case SOS_SPARC: ios << "sparc"; break;
		case SOS_VAXARC: ios << "vaxarc"; break;
		case SOS_ALPHAARC: ios << "alphaarc"; break;
		case SOS_HCUBESARC: ios << "hcubesarc"; break;
		default: ios << "*error*";
		}

	ios << endl << "\tuser: ";
	char *user = (char*) ((sos_header &)h).iBuffer() + h.user_offset( );
	for ( int C = 0; C < 6; C++ )
		ios << (void*) user[C] << " ";

	return ios;
	}
#endif
