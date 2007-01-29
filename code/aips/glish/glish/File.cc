// $Id: File.cc,v 19.12 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1998 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: File.cc,v 19.12 2004/11/03 20:38:58 cvsmgr Exp $")
#include "system.h"
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "Glish/Reporter.h"
#include "File.h"
#include <ctype.h>
#include "Glish/Stream.h"


File::File( const char *str_ ) : str(0), desc(0), in(0), out(0)
	{
	if ( !str_ || !str_[0] ) return;

	str = string_dup(str_);

	int len = strlen(str);

	if ( str[0] == '<' )
		{
		type_ = IN;
		in = Open( "r" );
		}
	else if ( str[0] == '>' )
		{
		type_ = OUT;
		if ( str[1] == '>' )
			out = Open( "a" );
		else
			out = Open( "w" );
		}
	else if ( str[0] == '|' )
		{
		if ( str[len-1] == '|' )
			{
			type_ = PBOTH;
			dual_popen( clean_string( ), &in, &out ); 
			}
		else
			{
			type_ = POUT;
			out = popen( clean_string( ), "w" );
			}
		}
	else if ( str[len-1] == '|' )
		{
		type_ = PIN;
		in = popen( clean_string( ), "r" );
		}
	else
		type_ = ERR;
	}

char *File::read_line( )
	{
	if ( type_ != IN && type_ != PIN && type_ != PBOTH ||
	     ! in || feof(in) ) return 0;

	char buf[1025];
	buf[0] = '\0';

	fgets( buf, 1024, in );
	int l = strlen(buf);

	int len = l+1;
	char *ret = alloc_char( len );
	memcpy( ret, buf, l+1 );

	while ( ! feof( in ) && ret[len-2] != '\n' )
		{
		fgets( buf, 1024, in );
		l = strlen(buf);
		ret = (char*) realloc_memory( ret, len + l );
		memcpy( &ret[len-1], buf, l+1 );
		len += l;
		}

	return ret;
	}

char *File::read_chars( int num )
	{
	if ( type_ != IN && type_ != PIN && type_ != PBOTH ||
	     ! in || feof(in) ) return 0;


	char *ret = alloc_char( num+1 );
	int len = 0;

	if ( (len = read( fileno(in), ret, num )) > 0 )
		{
		ret[len] = '\0';
		return ret;
		}
	else
		{
		free_memory( ret );
		return 0;
		}
	}

byte *File::read_bytes( int &num )
	{
	if ( type_ != IN && type_ != PIN && type_ != PBOTH ||
	     ! in || feof(in) ) return 0;


	byte *ret = alloc_byte( num );
	int len = 0;

	if ( (len = read( fileno(in), ret, num )) > 0 )
		{
		num = len;
		return ret;
		}
	else
		{
		num = 0;
		free_memory( ret );
		return 0;
		}
	}

void File::write( charptr buf )
	{
	if ( type_ != OUT && type_ != POUT && type_ != PBOTH || ! out ) return;

	fwrite( buf, 1, strlen(buf), out );
	fflush( out );
	}

void File::close( Type t )
	{
	switch ( type_ )
	    {
	    case IN:
		if ( in ) fclose( in );
		in = 0;
		break;
	    case OUT:
		if ( out ) fclose( out );
		out = 0;
		break;
	    case PIN:
		if ( in ) pclose( in );
		in = 0;
		break;
	    case POUT:
		if ( out ) pclose( out );
		out = 0;
		break;
	    case PBOTH:
		if ( out && (t == PBOTH || t==POUT || t==OUT) )
			{
			dual_pclose( out );
			out = 0;
			}
		if ( in && (t == PBOTH || t==PIN || t==IN) )
			{
			dual_pclose( in );
			in = 0;
			}
		break;
	    }
	}
	
File::~File( )
	{
	if ( str ) free_memory( str );
	close();
	}

char *File::clean_string( )
	{
	static char *buffer = 0;
	static int buffer_len = 0;

	if ( ! buffer )
		{
		buffer_len = 1024;
		buffer = alloc_char( 1024 );
		}

	const char *start = str;
	int len = strlen(str);
	const char *end = str + len - 1;

	if ( *start == '|' && *end == '|' ) --end;
	if ( *start == '>' ) { if ( *++start == '>' ) ++start; }
	else if ( *start == '|' || *start == '<' ) { ++start; }
	else if ( *end == '|' ) { --end; }

	while ( isspace(*start) ) ++start;
	while ( isspace(*end) ) --end;

	int ret_len = end-start+1;
	if ( ret_len+1 > buffer_len )
		{
		while ( ret_len+1 > buffer_len ) buffer_len += (int)(buffer_len*0.5);
		buffer = (char*) realloc_memory( buffer, buffer_len );
		}

	memcpy( buffer, start, ret_len );
	buffer[ret_len] = '\0';

	return buffer;
	}

FILE *File::Open( const char *mode )
	{
	struct stat sbuf;
	char *f = clean_string( );
	int exists = lstat( f, &sbuf ) == 0;

	if ( *mode == 'r' && ! exists || exists && S_ISDIR(sbuf.st_mode) )
		{
		type_ = ERR;
		return 0;
		}

	FILE *ret = fopen( f, mode );
	if ( ! ret ) type_ = ERR;
	return ret;
	}

int File::Describe( OStream& s, const ioOpt & ) const
	{
	s << "<FILE: " << str << ">";
	return 1;
	}

const char *File::Description( ) const
	{
	if ( desc ) return desc;

	((File*)this)->desc = alloc_char( strlen(str) + 9);

	sprintf(((File*)this)->desc, "<FILE: %s>", str);

	return desc;
	}
