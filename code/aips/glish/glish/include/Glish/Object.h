// $Id: Object.h,v 19.0 2003/07/16 05:15:47 aips2adm Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
#ifndef object_h
#define object_h
#include "Glish/Str.h"
#include "Glish/List.h"
#include "sos/ref.h"

// GlishObject is the root of the class hierarchy.  GlishObjects know how to
// describe themselves.

//
// Line number and file to associate with newly created objects..
//
extern name_list *glish_files;
extern unsigned short file_name;
extern unsigned short line_num;

class OStream;
class Value;
class RMessage;
extern RMessage EndMessage;
extern Str glish_errno;

typedef const char* charptr;
typedef GcRef GlishRef;

class ioOpt GC_FINAL_CLASS {
    public:
	inline static unsigned short SHORT( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<0; }
	inline static unsigned short NO_NEWLINE( unsigned short mask=~((unsigned short) 0) ) { return mask & 1<<1; }
	ioOpt( ) : prefix_(0), flags_(0), sep_(' '), maxe_(-1) { }
	ioOpt( unsigned short f ) : prefix_(0), flags_(f), sep_(' '), maxe_(-1) { }
	ioOpt( unsigned short f, char s ) : prefix_(0), flags_(f), sep_(s), maxe_(-1) { }
	ioOpt( unsigned short f, charptr p ) : prefix_(p), flags_(f), sep_(' '), maxe_(-1) { }
	ioOpt( unsigned short f, int m ) : prefix_(0), flags_(f), sep_(' '), maxe_(m) { }
	ioOpt( unsigned short f, char s, charptr p ) : prefix_(p), flags_(f), sep_(s), maxe_(-1) { }
	ioOpt( unsigned short f, char s, int m ) : prefix_(0), flags_(f), sep_(s), maxe_(m) { }
	ioOpt( unsigned short f, char s, charptr p, int m ) : prefix_(p), flags_(f), sep_(s), maxe_(m) { }
	unsigned short flags( unsigned short mask=~((unsigned short) 0) ) const { return mask & flags_; }
	char sep() const { return sep_; }
	charptr prefix() const { return prefix_; }
	int maxElements() const { return maxe_; }
    private:
	charptr prefix_;
	unsigned short flags_;
	char sep_;
	int maxe_;
};

class GlishObject : public GlishRef {
    public:
	GlishObject() : file( file_name ), line(line_num)	{ }

	GlishObject( const GlishObject &o ) : GlishRef(o), file(file_name), line(line_num)	{ }

	virtual ~GlishObject()	{ }

	unsigned short Line()		{ return line; }

	// Generate a long description of the object to the
	// given stream.  This typically includes descriptions of
	// subobjects as well as this object. Returns non-zero if
	// something is actuall written to the stream.
	virtual int Describe( OStream&, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	// Non-virtual, non-const versions of Describe() and DescribeSelf().
	// We add it here so that if when deriving a subclass of GlishObject we
	// forget the "const" declaration on the Describe/DescribeSelf
	// member functions, we'll hopefully get a warning message that
	// we're shadowing a non-virtual function.
	int Describe( OStream& s, const ioOpt &opt )
		{ return ((const GlishObject*) this)->Describe( s, opt ); }
	int Describe( OStream& s )
		{ return Describe( s, ioOpt() ); }

	// Get a quick (minimal) description of the object. This is
	// used in CallExpr::Eval() to get the name of the function.
	// Getting it via a stream is just too much overhead.
	virtual const char *Description() const;

	const Str strFail( const RMessage&, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage 
		) const;

	Value *Fail( int auto_fail, const RMessage&, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage, const RMessage& = EndMessage,
		const RMessage& = EndMessage 
		) const;

	Value *Fail( const RMessage &a, const RMessage &b = EndMessage,
		const RMessage &c = EndMessage, const RMessage &d = EndMessage,
		const RMessage &e = EndMessage, const RMessage &f = EndMessage,
		const RMessage &g = EndMessage, const RMessage &h = EndMessage,
		const RMessage &i = EndMessage, const RMessage &j = EndMessage,
		const RMessage &k = EndMessage, const RMessage &l = EndMessage,
		const RMessage &m = EndMessage, const RMessage &n = EndMessage,
		const RMessage &o = EndMessage, const RMessage &p = EndMessage,
		const RMessage &q = EndMessage 
		) const { return Fail( 1, a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p ); }

	Value *Fail( const Value * ) const;

	Value *Fail( ) const;

    protected:
	unsigned short file;
	unsigned short line;
	};

#endif	/* object_h */
