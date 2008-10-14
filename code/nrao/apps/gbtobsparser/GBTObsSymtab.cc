//
// $Id: GBTObsSymtab.cc,v 19.2 2004/11/30 17:50:40 ddebonis Exp $
// Copyright (c) 1998,2000,2001 Associated Universities Inc.
//
#include <casa/string.h>
#include <casa/stdio.h>
#include "GBTObsSymtab.h"

#include <casa/namespace.h>
#define FAIL(how) { result = how; lastc = category; lastn = name; return 0; }
#define RETURN(what) { result = OK; lastc = category; lastn = name; return what; }

SymbolTable::Result SymbolTable::resolve_alias( const char *&category, const char *&name ) const
	{
	while ( Var *C = aliases[category] )
		{
		if ( C->mode() == Var::FULL )
			{
			if ( name ) return MDOTS_CAT;
			category = C->category();
			name = C->name();
			}
		else
			category = C->category();
		}


	if ( ! name ) return NDOTS;

	while ( Var *N = aliases[name] )
		{
		if ( N->mode() == Var::FULL ) return MDOTS_NAME;
		name = N->category();
		}

	return OK;
	}

void SymbolTable::alias( const char *str, Var *nv )
	{
	if ( ! str || ! nv ) return;

	Var *v = aliases[str];
	if ( v == nv ) return;

	if ( v ) delete v;
	aliases.Insert(strdup(str), nv);
	}

void SymbolTable::add( Var *nv )
	{
	if ( ! nv->category() || ! nv->name() )
		{
		delete nv;
		return;
		}

	alias_t *list = table[nv->category()];
	if ( ! list )
		{
		list = new alias_t;
		table.Insert( nv->category(), list );
		}

	Var *v = (*list)[nv->name()];
	if ( v ) delete v;
	list->Insert(nv->name(), nv);
	}


Var *SymbolTable::find_all( const char *str )
	{
	if ( ! str ) return 0;

	cmatches.clear();
	matches.clear();

	int slen = strlen( str );
	IterCookie *c = table.InitForIteration();
	alias_t *elem;
	const char *key;
	while ( (elem = table.NextEntry( key, c )) )
		{
		IterCookie *c = elem->InitForIteration();
		Var *var;
		const char *vkey;
		while( (var = elem->NextEntry( vkey, c)) )
			if ( ! strncmp( str, vkey, slen ) )
				matches.append(var);
		}

	const char *category = 0;
	const char *name = str;
	if ( matches.length() <= 0 ) FAIL(NMATCH_NAME)

	if ( matches.length() == 1 )
		RETURN(matches[0])
	else
		{
		int exact = -1;
		loop_over_list( matches, x )
			if ( ! strcmp( str, matches[x]->name() ) )
				{
				if ( exact >= 0 )
					FAIL(MMATCH)
				else
					exact = x;
				}

		if ( exact >= 0 )
			RETURN(matches[exact])
		else
			FAIL(MMATCH)
		}
	}

Var *SymbolTable::find( const char *category, const char *name )
	{
	if ( ! category ) FAIL(FAILURE)

	if ( (result = resolve_alias( category, name )) != OK )
		{
		lastc = category;
		lastn = name;
		if ( result == NDOTS )
			return find_all( category ? category : name );
		else
			return 0;
		}

	alias_t *ndict = table[category];

	if ( ! ndict )
		{
		cmatches.clear();
		int slen = strlen( category );
		IterCookie *c = table.InitForIteration();
		alias_t *elem;
		const char *key;
		while ( (elem = table.NextEntry( key, c )) )
			if ( ! strncmp( category, key, slen ) )
				{
				Var *v = (*elem)[name];
				if ( v ) RETURN(v)
				cmatches.append( elem );
				}

		if ( cmatches.length() <= 0 ) FAIL(NMATCH_CAT)

		matches.clear();
		for ( int i=0; i < cmatches.length(); ++i )
			{
			slen = strlen(name);
			alias_t &list = *cmatches[i];
			c = list.InitForIteration();
			Var *v;
			while ( (v = list.NextEntry( key, c )) )
				if ( ! strncmp( name, key, slen ) )
					matches.append(v);
			}
		}
	else
		{
		Var *v = (*ndict)[name];
		if ( v ) RETURN(v)

		matches.clear();
		int slen = strlen(name);
		IterCookie *c = (*ndict).InitForIteration();
		const char *key;
		while ( (v = ndict->NextEntry( key, c )) )
			if ( ! strncmp( name, key, slen ) )
				matches.append(v);
		}

	if ( matches.length() <= 0 ) FAIL(NMATCH_NAME)

	if ( matches.length() == 1 )
		RETURN(matches[0])
	else
		FAIL(MMATCH)
	}

char **SymbolTable::getStrings( int &len )
	{
	len = matches.length();
	if ( matches.length() <= 0 )
		return 0;

	char **ret = (char**) alloc_memory( sizeof(char*) * matches.length() );
	for ( int i = 0; i < matches.length(); ++i )
		{
		Var *v = matches[i];
		ret[i] = (char*) alloc_memory( strlen(v->category()) + strlen(v->name()) + 2 );
		sprintf( ret[i], "%s.%s", v->category(), v->name() );
		}
	return ret;
	}

void SymbolTable::dump( )
	{
	IterCookie *c = table.InitForIteration();
	alias_t *elem;
	const char *key;
	while ( (elem = table.NextEntry( key, c )) )
		{
		IterCookie *i = elem->InitForIteration();
		Var *var;
		const char *param;
		while ( (var = elem->NextEntry( param, i )) )
			printf("%s.%s\n", key, param);
		}
	}
