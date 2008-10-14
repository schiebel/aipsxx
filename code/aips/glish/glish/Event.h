// $Id: Event.h,v 19.12 2004/11/03 20:38:57 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998 Associated Universities Inc.
#ifndef event_h
#define event_h

#include "Glish/List.h"

class EventDesignator;

glish_declare(PList,EventDesignator);
typedef PList(EventDesignator) event_dsg_list;
glish_declare(PList,PList(char));
typedef PList(PList(char)) name_list_list;

class Expr;
class Notifiee;
class Agent;
class ParameterPList;
class Stmt;

class EventDesignator : public GlishObject {
public:
	EventDesignator( Expr* agent, Expr* event_name );
	EventDesignator( Expr* agent, const char* event_name );

	// Send out an event with the given value.  The event designator
	// called already knows what the event name is.  If is_request is
	// true than this is a request/response event, and the value of
	// the response is returned; otherwise the function returns nil.
	IValue* SendEvent( ParameterPList* arguments, int is_request,
			   Expr *from_subsequence=0 );

	// Used to register a "notifiee" (i.e., an event statement plus
	// an associated Frame) as wanting to be notified of occurrences
	// of the event corresponding to this event designator.
	void Register( Notifiee* notifiee );

	// Undo a previous Register()
	void UnRegister( Stmt* s );

	// Evaluates and returns the event's agent.  Returns nil if
	// the agent expression does not evaluate to an agent value.
	// EventAgentDone() must be called when done with the agent
	// value (it should not be called if a nil value was returned).
	//
	// The val_type argument indicates whether the agent is going
	// to be used for modification (VAL_REF) or not (VAL_CONST).
	Agent* EventAgent( value_reftype val_type );
	void EventAgentDone();

	// Returns the event agent expression, primarily for use
	// in error messages.
	Expr* EventAgentExpr() const	{ return agent; }

	name_list &EventNames( int force_eval=0 );

	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~EventDesignator();

	// This is a hack for Tk widgets
	void Reset( );

protected:
	Expr* agent;
	Expr* event_name_expr;
	const char* event_name_str;
	IValue* event_agent_ref;
	name_list *names;
	name_list_list *deletions;
	int send_count;
	};

extern void delete_name_list( name_list* nl );

extern void describe_event_list( const event_dsg_list* list, OStream& s );

#endif /* event_h */
