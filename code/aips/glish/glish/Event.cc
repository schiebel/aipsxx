// $Id: Event.cc,v 19.13 2004/11/03 20:38:57 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: Event.cc,v 19.13 2004/11/03 20:38:57 cvsmgr Exp $")
#include "system.h"
#include <string.h>

#include "IValue.h"
#include "Expr.h"
#include "Agent.h"
#include "Glish/Reporter.h"


EventDesignator::EventDesignator( Expr* arg_agent, Expr* arg_event_name )
	{
	agent = arg_agent;
	event_name_expr = arg_event_name;
	event_name_str = 0;
	event_agent_ref = 0;
	names = 0;
	send_count = 0;
	deletions = 0;
	}

EventDesignator::EventDesignator( Expr* arg_agent, const char* arg_event_name )
	{
	agent = arg_agent;
	event_name_expr = 0;
	event_name_str = arg_event_name;
	event_agent_ref = 0;
	names = 0;
	send_count = 0;
	deletions = 0;
	}

EventDesignator::~EventDesignator( )
	{
	NodeUnref( agent );
	NodeUnref( event_name_expr );
	if ( names ) delete_name_list( names );
	if ( deletions )
		{
		loop_over_list( *deletions, i )
			delete_name_list( (*deletions)[i] );
		delete deletions;
		}
	}

Agent* EventDesignator::EventAgent( value_reftype val_type )
	{
	evalOpt opt;
	event_agent_ref = agent->RefEval( opt, val_type );
	IValue* event_agent_val = (IValue*)(event_agent_ref->Deref());

	if ( ! event_agent_val->IsAgentRecord() )
		{
		EventAgentDone();
		return 0;
		}

	return event_agent_val->AgentVal();
	}

void EventDesignator::EventAgentDone()
	{
	Unref( event_agent_ref );
	event_agent_ref = 0;
	}

IValue* EventDesignator::SendEvent( parameter_list* arguments, int is_request, Expr *from_subsequence )
	{
	++send_count;

	Agent* a = EventAgent( VAL_REF );

	name_list &nl = EventNames( 1 );

	if ( nl.length() == 0 )
		{
		EventAgentDone();
		glish_error->Report( "->* illegal for sending an event" );
		--send_count;
		return is_request ? error_ivalue() : 0;
		}

	IValue* result = 0;

	if ( a && ! a->Finished( ) )
		{
		if ( nl.length() > 1 )
			glish_error->Report( this,
				       "must designate exactly one event" );

		result = a->SendEvent( nl[0], arguments, is_request, Agent::mLOG( ), from_subsequence );
		}

	else if ( a )
		result = (IValue*) Fail( is_request, EventAgentExpr(), "has finished and exited" );

	else
		result = (IValue*) Fail( EventAgentExpr(), "is not an agent" );

	EventAgentDone();

	--send_count;

	// This routine can be re-entrant so we must ensure that the
	// generated name list is preserved until the send is completed.
	// We use 'deletions' and 'send_count' for this.
	if ( deletions && deletions->is_member( &nl ) )
		delete_name_list( deletions->remove( &nl ) );

	return result;
	}

void EventDesignator::Register( Notifiee* notifiee )
	{
	if ( names ) delete_name_list( names );
	names = 0;

	name_list &nl = EventNames();

	Agent* a = EventAgent( VAL_CONST );

	if ( a )
		{
		if ( nl.length() == 0 )
			// Register for all events.
			a->RegisterInterest( notifiee );
		else
			loop_over_list( nl, i )
				a->RegisterInterest( notifiee, string_dup(nl[i]), 1 );
		}

	else
		glish_error->Report( EventAgentExpr(), "is not an agent" );

	EventAgentDone();
	}

void EventDesignator::UnRegister( Stmt* s )
	{
	name_list &nl = EventNames();

	Agent* a = EventAgent( VAL_CONST );

	if ( a )
		{
		if ( nl.length() == 0 )
			// Register for all events.
			a->UnRegisterInterest( s );

		else
			loop_over_list( nl, i )
				a->UnRegisterInterest( s, nl[i] );
		}

	else
		glish_error->Report( EventAgentExpr(), "is not an agent" );

	EventAgentDone();
	}

name_list &EventDesignator::EventNames( int force_eval )
	{

	if ( names )
		{
		if ( force_eval )
			{
			if ( send_count > 1 )
				{
				if ( ! deletions )
					deletions = new name_list_list;
				deletions->append( names );
				}
			else
				delete_name_list( names );
			names = 0;
			}
		else
			 return *names;
		}

	names = new name_list;

	if ( event_name_str )
		{
		names->append( string_dup( event_name_str ) );
		return *names;
		}

	if ( ! event_name_expr )
		return *names;

	evalOpt opt;
	const IValue* index_val = event_name_expr->ReadOnlyEval( opt );

	if ( index_val->Type() == TYPE_STRING )
		{
		int n = index_val->Length();
		const char** s = index_val->StringPtr(0);
		for ( int i = 0; i < n; ++i )
			names->append( string_dup( s[i] ) );
		}

	else
		glish_error->Report( this, "does not have a string-valued index" );

	event_name_expr->ReadOnlyDone( index_val );

	return *names;
	}

int EventDesignator::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	// skip prefix below
	EventAgentExpr()->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << "->";

	if ( event_name_expr )
		{
		s << "[";
		event_name_expr->Describe( s, ioOpt(opt.flags(),opt.sep()) );
		s << "]";
	}

	else if ( event_name_str )
		s << "." << event_name_str;

	else
		s << "*";
	return 1;
	}


void delete_name_list( name_list* nl )
	{
	if ( nl )
		{
		loop_over_list( *nl, i )
			free_memory( (*nl)[i] );

		delete nl;
		}
	}


void describe_event_list( const event_dsg_list* list, OStream& s )
	{
	if ( list )
		loop_over_list( *list, i )
			{
			if ( i > 0 )
				s << ", ";
			(*list)[i]->Describe( s );
			}
	}
