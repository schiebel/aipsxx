// $Id: multiplexer.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.
//
// Glish "multiplexer" client:
//
//	handle(event-name) requests that events named event-name
//		be forwarded to this interpreter
//
//	unhandle(event-name) cancels event forwarding
//
//	unknown is returned if there is no forwarding address
//		for a non-handle or non-unhandle request
//
#include "Glish/glish.h"
RCSID("@(#) $Id: multiplexer.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $")
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include "Glish/Client.h"

glish_declare(PDict,name_list);
typedef PDict(name_list) name_dict;

name_list my_contexts;
name_dict event_context_list;

void EndContext(char* progname, char* context)
	{
	if ( ! strcmp( context, "*glishd*" ) )
		{
		// glishd exited!
		std::cerr<<progname<<": glishd context exited."<<std::endl;
		exit(1);
		}

	loop_over_list( my_contexts, j )
		{
		if ( ! strcmp( my_contexts[j], context ) )
			delete my_contexts.remove_nth( j-- );
		}

	// Should clean up event forwarding lists too
	IterCookie* icook = event_context_list.InitForIteration();
	const char* name;
	name_list* l;

	while ( l = (name_list*)event_context_list.NextEntry( name, icook ) )
		{
		loop_over_list( (*l), i )
			{
			if ( ! strcmp( (*l)[i], context ) )
				delete l->remove_nth( i-- );
			}

		if ( l->length() == 0 ) // last one; remove event registry
			{
			delete l;
			delete event_context_list.Remove( name );
			icook = event_context_list.InitForIteration();
			}
		}
	}

void ListContexts(Client* c)
	{
	loop_over_list( my_contexts, j )
		c->PostEvent( "context", my_contexts[j] );
	}

void ListAll( Client* c )
	{
	IterCookie* icook = event_context_list.InitForIteration();
	const char* name;
	name_list* l;

	while ( l = (name_list*)event_context_list.NextEntry( name, icook ) )
		{
		for ( int j=0 ; j<l->length() ; ++j )
			{
			Value* myrec = create_record();
			myrec->SetField( "name", name );
			myrec->SetField( "context",(*l)[j] );
			c->PostEvent( "eventhandle", myrec );
			Unref( myrec );
			}
		}
	}

void Handle( Client* c, char* name )
	{
	name_list* l = event_context_list[ name ];

	if ( ! l )
		{
		l = new name_list;
		event_context_list.Insert( strdup(name), l );
		}

	for ( int j=0 ; j<l->length() ; ++j )
		{
		if ( ! strcmp( (*l)[j], c->LastContext().id() ) )
			{
			c->PostEvent( "failed", "already_got_handle" );
			return;
			}
		}

	l->append( strdup( c->LastContext().id() ) );
	c->PostEvent( "handling", name );
	}

void UnHandle( Client* c, char* name )
	{
	name_list* l = event_context_list[ name ];

	if ( ! l )
		{
		c->PostEvent( "failed", "dont_got_event" );
		return;
		}

	int got_it = 0;

	for ( int j=0 ; j<l->length() ; ++j )
		{
		if ( ! strcmp( (*l)[j], c->LastContext().id() ) )
			{
			delete l->remove_nth( j-- );
			got_it = 1;
			}
		}

	if ( got_it )
		{
		c->PostEvent( "unhandling", name );

		if (l->length()==0)
			event_context_list.Remove( name );
		}
	else
		c->PostEvent( "failed", "dont_got_handle" );
	}

int main( int argc, char** argv )
	{
	Client c( argc, argv, Client::USER );

	int j;

	// Initial context
	my_contexts.append( strdup( c.LastContext().id() ) );

	// For every event named "name", we need a string list of
	//   contexts to forward it to.

	for ( GlishEvent* e; (e = c.NextEvent()); )
		{
		const char* name = e->name;

		if ( ! strcmp( name, "*new-context*" ) )
			{
			my_contexts.append( e->value->StringVal() );
			continue;
			}

		else if ( ! strcmp( name, "*end-context*" ) )
			{
			char* val = e->value->StringVal();
			EndContext( argv[0], val );
			delete val;
			continue;
			}

		else if ( ! strcmp( name, "*list-contexts*" ) )
			{
			ListContexts( &c );
			continue;
			}

		else if ( ! strcmp( name, "*list-all*" ) )
			{
			ListAll( &c );
			continue;
			}

		else if ( ! strcmp( name, "established" ) )
			{
			continue;
			}

		else if ( ! strcmp( name, "handle" ) )
			{
			char* val = e->value->StringVal();
			Handle( &c, val );
			delete val;
			continue;
			}

		else if ( ! strcmp( name, "unhandle" ) )
			{
			char* val = e->value->StringVal();
			UnHandle( &c, val );
			delete val;
			continue;
			}

		else
			{
			name_list* l = event_context_list[ name ];

			if ( ! l )
				{
				c.Unrecognized();
				continue;
				}

			for ( j=0 ; j<l->length() ; ++j )
				{
				c.PostEvent( e, EventContext( 0, (*l)[j] ) );
				}
			continue;
			}

		}
	return 0;
	}
