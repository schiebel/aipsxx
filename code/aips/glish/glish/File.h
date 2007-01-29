// $Id: File.h,v 19.12 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1998 Associated Universities Inc.
#ifndef file_h
#define file_h

#include "Glish/Object.h"
#include "stdio.h"

class File : public GlishObject {
    public:
	enum Type { IN, OUT, PIN, POUT, PBOTH, ERR };
	File( const char *str_ );
	~File( );
	char *read_line( );
	char *read_chars( int num );
	byte *read_bytes( int &num );
	void write( charptr buf );
	void close( Type t=PBOTH );
	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }
	const char *Description( ) const;
	Type type( ) { return type_; }
    private:
	FILE *Open( const char *mode );
	char *clean_string( );
	Type type_;
	char *str;
	char *desc;
	FILE *in;
	FILE *out;
};

#endif
