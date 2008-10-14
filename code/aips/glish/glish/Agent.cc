// $Id: Agent.cc,v 19.13 2004/11/03 20:38:57 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: Agent.cc,v 19.13 2004/11/03 20:38:57 cvsmgr Exp $")
#include "system.h"
#include <stdio.h>
#include <string.h>

#include "Agent.h"
#include "Frame.h"
#include "IValue.h"
#include "Glish/Reporter.h"
#include "Sequencer.h"

#define INTERESTED_IN_ALL "*"


agent_list *agents = 0;


Notifiee::Notifiee( Stmt* arg_stmt, Sequencer *s ) :
			frame_(0), stack_(0), sequencer(s)
	{
	stmt_ = arg_stmt;
	Ref( stmt_ );
	}

Notifiee::Notifiee( Stmt* arg_stmt, Frame* arg_frame, Sequencer *s ) :
			stack_(0), sequencer(s)
	{
	stmt_ = arg_stmt;
	frame_ = arg_frame;

	Ref( stmt_ );

	if ( frame_ )
		Ref( frame_ );
	}

Notifiee::Notifiee( Stmt* arg_stmt, stack_type *arg_stack, Sequencer *s ) :
			frame_(0), sequencer(s)
	{
	stmt_ = arg_stmt;
	stack_ = arg_stack;

	if ( stack_ ) Ref( stack_ );
	Ref( stmt_ );
	}

Notifiee::~Notifiee()
	{
	sequencer->NotifieeDone( this );
	Unref( stmt_ );
	Unref( frame_ );
	Unref( stack_ );
	}

Agent::Agent( Sequencer* s, int DestructLast )
	{
	sequencer = s;
	agent_ID = 0;
	agent_value = 0;
	string_copies = 0;
	active = sINITIAL;

	agent_value = new IValue( create_record_dict(), this );
	if ( DestructLast )
		(*agents).insert( this );
	else
		(*agents).append( this );
	preserve_events = 0;
	}

void Agent::SetActivity( State s ) { active = s; }

void Agent::Done()
	{
	IterCookie* c = interested_parties.InitForIteration();

	notifiee_list* list;
	const char* key;
	while ( (list = interested_parties.NextEntry( key, c )) )
		{
		loop_over_list( *list, i )
			Unref( (*list)[i] );
		delete list;
		interested_parties.Remove( key );
		}

	for ( int i=unref_stmts.length()-1; i >= 0; --i )
		NodeUnref( unref_stmts.remove_nth(i) );
	}

Agent::~Agent()
	{
	(void) (*agents).remove( this );

	Done();

	if ( string_copies )
		{
		loop_over_list( *string_copies, i )
			{
			char* str = (char*) (*string_copies)[i];
			free_memory( str );
			}

		delete string_copies;
		}
	}

int Agent::BundleEvents( int ) { return 0; }
int Agent::FlushEvents( ) { return 0; }

void Agent::SendSingleValueEvent( const char* event_name, const IValue* value, u_long flags )
	{
	ConstExpr c( value ); Ref( (IValue*) value );
	Parameter p( VAL_VAL, &c, 0 ); Ref( &c );
	parameter_list plist;
	plist.append( &p );

	SendEvent( event_name, &plist, 0, flags );
	}

int Agent::CreateEvent( const char* event_name, IValue* event_value,
			NotifyTrigger *t, int preserve, Expr *from_subsequence )
	{
	return NotifyInterestedParties( event_name, event_value, t, preserve, from_subsequence );
	}

void Agent::RegisterInterest( Notifiee* notifiee, const char* field,
					int is_copy )
	{
	if ( ! field )
		field = INTERESTED_IN_ALL;

	notifiee_list* interest_list = interested_parties[field];

	if ( ! interest_list )
		{
		interest_list = new notifiee_list;
		interested_parties.Insert( field == INTERESTED_IN_ALL ?
					   string_dup(field) : field,
					   interest_list );
		}
	else if ( is_copy )
		{
		free_memory( (char*) field );
		field = 0;
		}

	Ref( notifiee );
	interest_list->append( notifiee );

	if ( is_copy && field )
		{
		// We need to remember the field since we're responsible
		// for garbage-collecting it when we're destructed.

		if ( ! string_copies )
			string_copies = new string_list;

		string_copies->append( field );
		}
	}

void Agent::UnRegisterInterest( Stmt* s, const char* field )
	{
	if ( ! field )
		field = INTERESTED_IN_ALL;

	notifiee_list* list = interested_parties[field];

	if ( ! list )
		return;

	int element = -1;
	loop_over_list( *list, i )
		if ( (*list)[i]->stmt() == s )
			{
			element = i;
			break;
			}

	if ( element >= 0 )
		Unref( list->remove_nth(element) );

	if ( list->length() == 0 )
		{
		char *store = interested_parties.Remove(field);
		if ( string_copies ) string_copies->remove(store);
		free_memory(store);
		delete list;
		}
	}

int Agent::HasRegisteredInterest( Stmt* stmt, const char* field )
	{
	notifiee_list* interest = interested_parties[field];

	if ( interest && SearchNotificationList( interest, stmt ) )
		return 1;

	interest = interested_parties[INTERESTED_IN_ALL];

	if ( interest && SearchNotificationList( interest, stmt ) )
		return 2;

	return 0;
	}

IValue* Agent::AssociatedStatements()
	{
	int num_stmts = 0;

	IterCookie* c = interested_parties.InitForIteration();
	const char* key;
	notifiee_list* interest;

	while ( (interest = interested_parties.NextEntry( key, c )) )
		num_stmts += interest->length();

	char** event = alloc_charptr( num_stmts );
	int* stmt = alloc_int( num_stmts );
	glish_bool* active = alloc_glish_bool( num_stmts );
	int count = 0;

	c = interested_parties.InitForIteration();
	while ( (interest = interested_parties.NextEntry( key, c )) )
		{
		loop_over_list( *interest, j )
			{
			event[count] = string_dup( key );
			stmt[count] = (*interest)[j]->stmt()->Index();
			active[count] = (*interest)[j]->stmt()->GetActivity() ?
							glish_true : glish_false;
			++count;
			}
		}

	if ( count != num_stmts )
		glish_fatal->Report(
		"internal inconsistency in Agent::AssociatedStatements" );

	IValue* r = create_irecord();
	r->SetField( "event", (charptr*) event, num_stmts );
	r->SetField( "stmt", stmt, num_stmts );
	r->SetField( "active", active, num_stmts );

	return r;
	}

Task* Agent::AgentTask()
	{
	return 0;
	}

int Agent::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	if ( agent_ID )
		s << agent_ID;
	else
		s << "<agent>";
	return 1;
	}

void Agent::WrapperGone( const IValue *v )
	{
	if ( agent_value == v ) agent_value = 0;
	}

int Agent::StickyNotes( ) const
	{
	return 0;
	}

IValue* Agent::BuildEventValue( parameter_list* args, int use_refs )
	{
	if ( args->length() == 0 )
		return empty_bool_ivalue();

	if ( args->length() == 1 && ! (*args)[0]->Name() )
		{
		Expr* arg_expr = (*args)[0]->Arg();
		evalOpt opt;

		IValue *arg_val = use_refs ? arg_expr->RefEval( opt, VAL_CONST ) :
					arg_expr->CopyEval(opt);

		NodeList *roots = UserFunc::GetRoots( );
		if ( roots && arg_val && UserFunc::GetRootsLen() > 0 &&
		     arg_val->PropagateCycles( roots ) > 0 )
			{
			ReflexPtrBase::new_key( );
			arg_val->SetUnref( roots );
			}

		return arg_val;
		}

	// Build up a record.
	IValue* event_val = create_irecord();

	int did_new_key = 0;

	loop_over_list( *args, i )
		{
		Parameter* p = (*args)[i];
		const char* index;
		char buf[64];
		
		if ( p->Name() )
			index = p->Name();
		else
			{
			sprintf( buf, "arg%d", i + 1 );
			index = buf;
			}

		Expr* arg_expr = p->Arg();
		evalOpt opt;
		IValue* arg_val = use_refs ?
			arg_expr->RefEval( opt, VAL_CONST ) : arg_expr->CopyEval(opt);

		NodeList *roots = UserFunc::GetRoots( );
		if ( roots && arg_val && UserFunc::GetRootsLen() > 0 &&
		     arg_val->PropagateCycles( roots ) > 0 )
			{
			if ( ! did_new_key )
				{
				ReflexPtrBase::new_key( );
				did_new_key = 1;
				}
				
			arg_val->SetUnref( roots );
			}

		event_val->AssignRecordElement( index, arg_val );

		Unref( arg_val );
		}

	return event_val;
	}

int Agent::NotifyInterestedParties( const char* field, IValue* value, NotifyTrigger *t,
				    int preserve, Expr *from_subsequence )
	{
	notifiee_list* interested = interested_parties[field];
	int there_is_interest = 0;

	if ( interested )
		{
		loop_over_list( *interested, i )
			{
			// We ignore DoNotification's return value, for now;
			// we consider that the Notifiee exists, even if not
			// active, sufficient to consider that there was
			// interest in this event.
			(void) DoNotification( (*interested)[i], field, value, t, from_subsequence );
			}

		there_is_interest = 1;
		}

	interested = interested_parties[INTERESTED_IN_ALL];

	if ( interested )
		{
		loop_over_list( *interested, i )
			(void) DoNotification( (*interested)[i], field, value, t, from_subsequence );

		there_is_interest = 1;
		}

	if ( (preserve_events || preserve) && agent_value &&
	     agent_value->Type() == TYPE_RECORD )
		{
		// We have to assign the corresponding field in the agent
		// record right here, ourselves, since the sequencer isn't
		// going to do it for us in Sequencer::RunQueue.
		agent_value->AssignRecordElement( field, value );
		}

	Unref( value );
	Unref( t );

	return there_is_interest;
	}

int Agent::DoNotification( Notifiee* n, const char* field, IValue* value,
			   NotifyTrigger *t, Expr *from_subsequence )
	{
	Stmt* s = n->stmt();

	if ( s->IsActiveFor( this, field, value, from_subsequence ) )
		{
		if ( t ) Ref(t);

		Notification* note = new Notification( this, field, value, n, t,
			StickyNotes() ? Notification::STICKY : s->NoteType() );

		sequencer->QueueNotification( note );

		return 1;
		}

	else
		return 0;
	}

int Agent::SearchNotificationList( notifiee_list* list, Stmt* stmt )
	{
	loop_over_list( *list, i )
		if ( (*list)[i]->stmt() == stmt )
			return 1;

	return 0;
	}

void Agent::RegisterUnref( Stmt *s )
	{
	if ( ! unref_stmts.is_member(s) )
		{
		Ref( s );
		unref_stmts.append( s );
		}
	}

void Agent::UnRegisterUnref( Stmt *s )
	{
	unref_stmts.remove(s);
	}

int Agent::IsProxy( ) const
	{
	return 0;
	}

int Agent::IsPseudo( ) const
	{
	return 0;
	}

ProxyTask *ProxySource::GetProxy( const ProxyId &proxy_id )
	{
	loop_over_list( ptlist, i )
		if ( ptlist[i]->Id() == proxy_id )
			return ptlist[i];
	return 0;
	}

ProxyTask::ProxyTask( const ProxyId &id_, ProxySource *t, Sequencer *s ) : Agent(s), bundle(0),
				bundle_size(0), task(t), id(id_)
								    
	{
	char buf[128];
	sprintf(buf, "<proxy:%d>", id.id());
	agent_ID = string_dup(buf);
	task->RegisterProxy(this);
	SetActive( );
	}

void ProxyTask::SetActivity( State s )
	{
	active = s;

	CreateEvent( "active", new IValue( active != sFINISHED ), 0, 1 );

	if ( active == sFINISHED )
		(void) (*agents).remove( this );
	}

void ProxyTask::WrapperGone( const IValue *v )
	{
	if ( agent_value == v )
		{
		// must be careful with agent_value, otherwise we end up in an
		// infinite loop because this function is called as 'v' is being
		// deleted, NewEvent() Ref()'s and Unref()'s the agent_value which
		// results in WrapperGone being called repeatedly. So the solution
		// is to Ref() it; it is already being deleated so it won't result
		// in a memory leak.
		Ref((GlishObject*)v); Ref((GlishObject*)v); Ref((GlishObject*)v);
		IValue *val = new IValue(glish_true);
		sequencer->NewEvent( this, "done", val, 0, 0 );
		agent_value = 0;
		}
	}

ProxyTask::~ProxyTask( )
	{
	if ( bundle && bundle->Length() >= bundle_size )
		FlushEvents( );

	IValue *val = new IValue(glish_true);
	task->SendEvent( "terminate", val, 0, Agent::mLOG( ), id );
	Unref( val );

	task->UnregisterProxy(this);

	if ( bundle ) delete_record( bundle );
	if ( agent_ID ) free_memory((char*)agent_ID);
	}

IValue *ProxyTask::SendEvent( const char* event_name, parameter_list* args,
			      int is_request, u_long flags, Expr */* from_subsequence */ )
	{
	if ( bundle_size )
		{
		if ( is_request )
			{
			FlushEvents( );
			return task->SendEvent( event_name, args, is_request, flags, id );
			}
		else
			{
			if ( ! bundle ) bundle = create_record_dict( );
			IValue* val = BuildEventValue( args, 0 );
			char *nme = alloc_char( strlen(event_name) + 9 );
			sprintf( nme, "%.8x%s", bundle->Length(), event_name );
			bundle->Insert( nme, val );
			if ( bundle->Length() >= bundle_size )
				FlushEvents( );
			return 0;
			}
		}
	else
		return task->SendEvent( event_name, args, is_request, flags, id );
	}

int ProxyTask::BundleEvents( int howmany )
	{
	bundle_size = howmany <= 1 ? 0 : howmany;

	if ( bundle && bundle->Length() >= bundle_size )
		FlushEvents( );

	if ( bundle && bundle_size <= 0 )
		{
		delete_record( bundle );
		bundle = 0;
		}

	return 1;
	}

int ProxyTask::FlushEvents( )
	{
	if ( bundle && bundle->Length() > 0 )
		{
		IValue *val = new IValue( bundle );
		task->SendEvent( "event-bundle", val, 0, Agent::mLOG( ), id, 1 );
		Unref( val );
		bundle = 0;
		}
	return 1;
	}

int ProxyTask::IsProxy( ) const
	{
	return 1;
	}

void ProxyTask::AbnormalExit( int status )
	{
	recordptr rec = create_record_dict();
	rec->Insert(string_dup("id"), new IValue((int*)id.array(),ProxyId::len(),COPY_ARRAY));
	rec->Insert(string_dup("value"), new IValue( task->AgentID() ));
	GlishEvent *event = new GlishEvent( (const char*) "fail", (Value*)(new IValue( rec )) );
	event->SetIsProxy( );
	event->SetIsQuiet( );
	sequencer->NewEvent( task, event, 0 );
	}


SystemAgent::SystemAgent( Sequencer *s ) : UserAgent(s) { }

IValue* SystemAgent::SendEvent( const char* event_name, parameter_list *args,
				int is_request, u_long flags, Expr *from_subsequence )
	{
	if ( ! strcmp( event_name, "memory" ) )
		{
		int *ivec = alloc_int( 2 );
		sequencer->info.Update( );
		ivec[0] = sequencer->info.MemoryUsed( );
		ivec[1] = sequencer->info.MemoryFree( );
		return new IValue( ivec, 2 );
		}

	if ( ! strcmp( event_name, "swap" ) )
		{
		int *ivec = alloc_int( 2 );
		sequencer->info.Update( );
		ivec[0] = sequencer->info.SwapUsed( );
		ivec[1] = sequencer->info.SwapFree( );
		return new IValue( ivec, 2 );
		}

	if ( Agent::mOVERRIDE(flags) && ! strcmp( event_name, "exit" ) )
		{
		return UserAgent::SendEvent( event_name, args, is_request, flags, from_subsequence );
		}

	return (IValue*) Fail( "unknown event, \"", event_name, "\"" );
	}

class uagent_await_info GC_FINAL_CLASS {
    public:
	uagent_await_info( const char *n, UserAgent *a ) : name_(n), agent_(a), result_(0) { }
	void set_result( IValue *v ) { result_ = copy_value(v); }
	IValue *result( ) const { return result_; }
	const char *name( ) const { return name_; }
	UserAgent *agent( ) const { return agent_; }
	~uagent_await_info( ) { }
    protected:
	const char *name_;
	UserAgent *agent_;
	IValue *result_;
};

IValue* UserAgent::SendEvent( const char* event_name, parameter_list* args,
				int is_request, u_long flags, Expr *from_subsequence )
	{
	IValue* event_val = BuildEventValue( args, 0 );

	if ( Agent::mLOG(flags) )
		sequencer->LogEvent( "<agent>", "<agent>",
					event_name, event_val, 0 );

	sequencer->CheckAwait( this, event_name, event_val );

	CreateEvent( event_name, event_val, 0, 0, from_subsequence );

	return is_request ? AwaitReply( event_name ) : 0;
	}

int UserAgent::StickyNotes( ) const
	{
	return 0;
	}

IValue *UserAgent::AwaitReply( const char *event_name )
	{
	uagent_await_info *pre = new uagent_await_info( event_name, this );
	await.append( pre );
	sequencer->PendingEventLoop( );
	uagent_await_info *post = await.remove_nth(await.length()-1);
	if ( pre != post ) glish_fatal->Report("stack inconsistency in UserAgent::AwaitReply");
	return post->result() ? post->result() : (IValue*) Fail("no reply generated by subsequence");
	}

int UserAgent::CreateEvent( const char* event_name, IValue* event_value,
			    NotifyTrigger *t, int preserve, Expr *from_subsequence )
	{
	if ( from_subsequence && await.length() )
		{
		// here contrary to client behavior, perhaps the
		// newest await should get the first value
		loop_over_list( await, i )
			{
			register uagent_await_info *cur = await[i];
			if ( ! cur->result() && cur->agent() == this &&
			     ! strcmp(event_name,cur->name()) )
				cur->set_result( event_value );
			}
		}

	return Agent::CreateEvent( event_name, event_value, t, preserve, from_subsequence );
	}

void delete_agent_dict( agent_dict *ad )
	{
	if ( ad )
		{
		IterCookie* c = ad->InitForIteration();
		agent_list* member;
		const char* key;
		while ( (member = ad->NextEntry( key, c )) )
			{
			free_memory( (void*) key );
			delete member;
			}

		delete ad;
		}
	}
