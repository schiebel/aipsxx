//======================================================================
// sos/str.h
//
// $Id: str.h,v 19.0 2003/07/16 05:17:39 aips2adm Exp $
//
// Copyright (c) 1997 Associated Universities Inc.
//
//======================================================================
#if ! defined(sos_str_h_)
#define sos_str_h_
#include "sos/sos.h"
#include <sys/types.h>
#include <unistd.h>
#include <string.h>

class str_kernel GC_FINAL_CLASS {
public:
	str_kernel( unsigned int size_ = 0 ) : cnt(1), size(size_ ? size_ : 1)
		{ ary = (char**) alloc_zero_memory(size*sizeof(char*));
		  len = (unsigned int*) alloc_zero_memory(size*sizeof(unsigned int)); }

	str_kernel( const char * );

	unsigned int strlen( unsigned int off=0 ) const
		{ return len[off]; }
	unsigned int length() const { return size; }

	char *get( unsigned int off ) { return ary[off]; }
	char *Get( unsigned int off ) { return ary[off] ? ary[off] : ""; }

	char **getary() { return ary; }
	unsigned int *getlen() { return len; }

	void set( unsigned int, const char * );
	void set( unsigned int, char *, int take_array );

	void ref() { cnt++; }
	unsigned int unref() { return --cnt; }
	unsigned int count() const { return cnt; }

	str_kernel *clone() const;
	void grow( unsigned int );

	~str_kernel();

protected:
	unsigned int cnt;
	unsigned int size;
	char **ary;
	unsigned int *len;
};

class str_ref GC_FINAL_CLASS {
friend class str;
friend unsigned int strlen( const str_ref & );
public:
	inline operator const char *() const;
	inline str_ref &operator=( const char * );
	inline str_ref &operator=( const str_ref & );
private:
	str_ref( str *s_, unsigned int off_ ) : s(s_), off(off_) { }

	// stubs to prevent these functions from being called
	str_ref() { }
	str_ref( const str_ref &) { }

	str *s;
	unsigned int off;
};

class str GC_FINAL_CLASS {
friend class str_ref;
friend unsigned int strlen( const str_ref & );
public:
	str( unsigned int size = 0 ) : kernel( new str_kernel( size ) ) { }
	str( const char *s ) : kernel( new str_kernel(s) ) { }
	str( const str &s ) : kernel(s.kernel) { kernel->ref(); }
	str( const str *s ) : kernel( s ? s->kernel : new str_kernel( (unsigned int) 0) )
		{ if ( s ) kernel->ref(); }

	str &operator=( const str &s )
		{
		if ( s.kernel != kernel )
			{
			if ( ! kernel->unref() ) delete kernel;
			kernel = s.kernel;
			kernel->ref();
			}
		return *this;
		}

	const char *operator[]( unsigned int i ) const
		{ return kernel->get(i); }
	str_ref operator[]( unsigned int i )
		{ return str_ref(this,i); }

	void set( unsigned int off, const char *s )
		{ kernel->set(off, s); }
	const char *get( unsigned int off = 0 ) const
		{ return kernel->get( off ); }
	const char *Get( unsigned int off = 0 ) const
		{ return kernel->Get( off ); }

	char **getary()
		{ return kernel->getary(); }
	unsigned int *getlen()
		{ return kernel->getlen(); }
	
	//
	// make sure we have a modifiable version
	//
	void mod() { if ( kernel->count() > 1 ) do_copy(); }
	unsigned int count() const { return kernel->count(); }

	void grow( unsigned int size )
		{ mod(); kernel->grow( size ); }

	unsigned int length() const { return kernel->length(); }
	unsigned int strlen( unsigned int off = 0 ) const { return kernel->strlen(off); }

	~str() { if ( ! kernel->unref() ) delete kernel; }
private:
	void do_copy();
	str_kernel *kernel;
};

inline str_ref::operator const char *() const
	{ return s->kernel->get( off ); }
inline str_ref &str_ref::operator=( const char *v )
	{ s->mod(); s->kernel->set( off, v ); return *this; }
inline str_ref &str_ref::operator=( const str_ref &o )
	{ s->mod(); s->kernel->set( off, o.s->kernel->get(o.off) ); return *this; }

inline unsigned int strlen( const str_ref &ref )
	{ return ref.s->kernel->strlen(ref.off); }

typedef str* strptr;
#if defined(ENABLE_STR) || !defined(sos_io_h_)
typedef const char * const * const_charptr;
typedef const char* charptr;
#endif

#endif
