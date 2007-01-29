// $Id: Regex.h,v 19.12 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1997,1998 Associated Universities Inc.
#ifndef regex_h_
#define regex_h_

#include "Glish/Object.h"
#include "regx/regexp.h"

class IValue;
class OStream;

extern int glish_dummy_int;

class regxsubst GC_FINAL_CLASS {
    public:
	regxsubst() : subst(0), reg(0),	startp(0), endp(0),
			pcnt(0), psze(0), refs(0), rcnt(0),
			rsze(0), splits(0), scnt(0), ssze(0),
			err_(0), split_count(0) { }
	regxsubst( char *s ) : subst(s), reg(0), startp(0), endp(0),
			pcnt(0), psze(0), refs(0), rcnt(0),
			rsze(0), splits(0), scnt(0), ssze(0),
			err_(0), split_count(0) { }
	regxsubst( const regxsubst &o ) : subst( o.subst ? string_dup(o.subst) : 0 ),
			reg(0), startp(0), endp(0), pcnt(0), psze(0),
			refs(0), rcnt(0), rsze(0), splits(0), scnt(0),
			ssze(0), err_(0), split_count(0) { } 
	~regxsubst();
	void compile( regexp *reg_ );
	void compile( regexp *reg_, char *subst_ );
	char *apply( char *dest );
	void split( char **dest, const char *src );
	const char *err( ) const { return err_; }
	const char *str( ) const { return subst; };
	void setStr( char *s );
	void setStr( const char *s ) { setStr( (char*)( s ? string_dup(s) : 0 ) ); }

	int splitCount( ) const { return split_count; }
	void splitReset( ) { scnt = 0; }

    protected:
	char *subst;
	regexp *reg;
	char **startp;
	char **endp;
	int pcnt;
	int psze;
	unsigned short *refs;
	int rcnt;
	int rsze;
	char **splits;
	int scnt;
	int ssze;
	char *err_;
	int split_count;
};

class RegexMatch;

class Regex : public GlishObject {
     public:

	static unsigned int GLOBAL( unsigned int mask=~((unsigned int) 0) ) { return mask & 1<<0; }
	static unsigned int FOLD( unsigned int mask=~((unsigned int) 0) ) { return mask & 1<<1; }

	enum regex_type { MATCH, SUBST };

	regex_type Type() const { return subst.str() ? SUBST : MATCH; }

	Regex( char *match_, char divider_ = '!', unsigned int flags_ = 0, char *subst_ = 0 );
	Regex( const Regex &oth );
	Regex( const Regex *oth );

	//
	// Always in_place and can_resize!! Returns (total) number of matches.
	//
	int Eval( char **&root, int &root_len, RegexMatch *match=0, int offset=0, int &len=glish_dummy_int,
		  IValue **error=0, int free_it=0, char **alt_src=0, int alt_len=0 );

	//
	// Is this a "global" regular expression?
	//
	int Global( ) { return GLOBAL(flags) ? 1 : 0; }

	//
	// returns non-null string if an error occurred
	// while creating the regular expression
	//
	const char *Error( ) const { return error_string ? error_string : subst.err(); }

	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	// returns an allocated string
	const char *Description( ) const;

	//
	// how many entries is the string going to be split into
	// with each match?
	//
	int Splits() const { return subst.str() ? subst.splitCount() : 0; }

	int matchCount() const { return match_count; }

	~Regex();

	// Internal use...
	regexp *R() { return reg; }

     protected:
	void compile( );

	regxsubst subst;
	regexp *reg;
	PMOP   pm;

	char   *match;
	char   *match_end;

	char   *error_string;

	char divider;
	unsigned int flags;
	int match_count;

	char *desc;
};

struct match_node;
glish_declare(PList,match_node);
typedef PList(match_node) match_node_list;

//
// Class which manages the match information across
// multiple Regex applications.
//
class RegexMatch GC_FINAL_CLASS {
    public:
	RegexMatch( ) : last(0) { }
	~RegexMatch( );

	//
	// Called to reset the match information
	//
	void clear( );

	//
	// Can be called initially to "register" a Regex,
	// but this is now unnecessary
	//
	void add( Regex * );

	//
	// Called to collect the information from a
	// successful match.
	//
	void update( char *, Regex * );

	//
	// Called when the match fails.
	//
	void failed( char *, Regex * );

	//
	// Called to retrieve the match information. If this
	// value needs to persist, it must be Ref()ed or copied.
	//
	IValue *get( );

    private:
	match_node_list list;
	IValue *last;
};

extern void copy_regexs( void *to_, void *from_, size_t len );

#endif
