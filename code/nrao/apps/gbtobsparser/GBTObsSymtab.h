#ifndef NRAO_GBTOBSSYMTAB_H
#define NRAO_GBTOBSSYMTAB_H
//
// $Id: GBTObsSymtab.h,v 19.3 2004/11/30 17:50:40 ddebonis Exp $
// Copyright (c) 1998,2000,2001 Associated Universities Inc.
//
#include "Glish/Client.h"
#include <casa/string.h>

#include <casa/namespace.h>
extern void handle_var_error( );
typedef List(int) int_list;
struct obs_identifier {
	char *cat;
	char *nme;
};

class Var {
    public:
	enum Mode { FULL, HALF };
	Var( char *category, char *name ) : mde(FULL), cat(category), nme(name) { }
	Var( char *alias ) :
		mde(HALF), cat(alias), nme(0) { }
	const char *category() const { return cat; }
	const char *name() const { return nme; }
	Mode mode() const { return mde; }
    protected:
	Mode mde;
	char *cat;
	char *nme;
};

struct obs_varexpr {
	Var *var;
	int_list *index;
};

glish_declare(PList,Var);
typedef PList(Var) varlist_t;
typedef PList(Var) var_list;

typedef PList(char) char_list;

glish_declare(PDict,Var);
typedef PDict(Var) alias_t;

glish_declare(PList,alias_t);
typedef PList(alias_t) symbollist_t;

glish_declare(PDict,alias_t);
typedef PDict(alias_t) symboltable_t;

class SymbolTable {
    public:
	enum Result { OK=0, FAILURE,
		      MMATCH,
		      NMATCH_CAT, NMATCH_NAME,
		      MDOTS_CAT, MDOTS_NAME,
		      NDOTS };

	// returns 0, on failure
	Var *find( const char *category, const char *name=0 );

	// retrive error results
	Result getResult() const { return result; }
	char **getStrings( int &len );
	void last( const char *&cat, const char *&name ) const
		{ cat = lastc; name = lastn; }


	void add( Var * );
	void alias( const char *str, Var * );
	Var *alias( const char *str ) { return aliases[str]; }


	void dump( );

    protected:
	Var *find_all( const char *str );
	Result resolve_alias( const char *&category, const char *&name ) const;
	Result result;
	symboltable_t table;
	alias_t aliases;
	varlist_t matches;
	symbollist_t cmatches;
	const char *lastc;
	const char *lastn;
};

#endif
