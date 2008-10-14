// $Id: Str.h,v 19.0 2003/07/16 05:15:51 aips2adm Exp $
// Copyright (c) 1997 Associated Universities Inc.
//
#if ! defined(str_h_)
#define str_h_
#include "Glish/glish.h"
#include <sys/types.h>
#include <unistd.h>
#include <string.h>

//
//  This contains a simple string implementation, which is currently only
//  used for maintaining the correspondence between glish objects and file
//  names.
//
class StrKernel GC_FINAL_CLASS {
public:
	StrKernel( ) : str(0), cnt(1) { }
	StrKernel( const char *s ) : str( s && s[0] ? string_dup( s ) : 0 ),
					cnt(1) { }
	StrKernel( char *s ) : str( s ), cnt(1) { }
	const char *Chars() const { return str ? str : ""; }
	const char *chars() const { return str; }
	void ref() { cnt++; }
	unsigned int unref() { return --cnt; }
	~StrKernel();
private:
	char *str;
	unsigned int cnt;
};

class Str GC_FINAL_CLASS {
public:
	Str( ) : kernel( 0 ) { }
	Str( const char *s ) : kernel( new StrKernel(s) ) { }
	Str( char *s, int own=1 ) :
		kernel( own ? new StrKernel(s) :
			new StrKernel((const char*) s ) ) { }
	Str( const Str &s ) : kernel(s.kernel) { if ( kernel ) kernel->ref(); }
	Str( const Str *s ) : kernel( s ? s->kernel : 0 )
			{ if ( kernel ) kernel->ref(); }
	Str &operator=( const Str &s ) 
		{
		if ( s.kernel != kernel )
			{
			if ( kernel && ! kernel->unref() ) delete kernel;
			if ( (kernel = s.kernel) ) kernel->ref();
			}
		return *this;
		}
	const char *Chars() const { return kernel ? kernel->Chars() : "" ; }
	const char *chars() const { return kernel ? kernel->chars() : 0 ; }
	~Str() { if ( kernel && ! kernel->unref() ) delete kernel; }
private:
	StrKernel *kernel;
};

#endif
