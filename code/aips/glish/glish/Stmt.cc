// $Id: Stmt.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: Stmt.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $")
#include "system.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "Glish/Reporter.h"
#include "Pager.h"
#include "Sequencer.h"
#include "Stmt.h"
#include "BuiltIn.h"
#include "Task.h"
#include "Frame.h"

IValue *FailStmt::last_fail = 0;
Stmt* null_stmt;
unsigned int WheneverStmt::notify_count = 0;

void NotifyTrigger::NotifyDone() { }
NotifyTrigger::~NotifyTrigger() { }

Notification::Notification( Agent* arg_notifier, const char* arg_field,
			    IValue* arg_value, Notifiee* arg_notifiee,
			    NotifyTrigger *t, Type ty ) : valid(1), type_(ty)
	{
	notifier = arg_notifier;
	field = string_dup( arg_field );
	value = arg_value;
	notifiee = arg_notifiee;
	trigger = t;

	Ref( value );
	Ref( notifier );
	}

Notification::~Notification()
	{
	free_memory( field );
	Unref( value );
	Unref( trigger );
	Unref( notifier );
	}

int Notification::Describe( OStream& s, const ioOpt &opt ) const
	{
	s << "notification of ";
	notifier->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << "." << field << " (";
	value->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << ") for ";
	notifiee->stmt()->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	return 1;
	}

Stmt::~Stmt() { }

void Stmt::CollectUnref( stmt_list &del_list )
	{
	if ( RefCount() > 1 )
		NodeUnref( this );
	else if ( ! del_list.is_member( this ) )
		del_list.append( this );
	}

Notification::Type Stmt::NoteType( ) const 
	{
	return Notification::UNKNOWN;
	}

IValue* Stmt::Exec( evalOpt &flow )
	{
	unsigned short prev_line_num = line_num;

	line_num = Line();
	
	flow.set(evalOpt::NEXT);

	if ( Sequencer::CurSeq()->System().Trace() )
		if ( ! DoesTrace() && Describe(glish_message->Stream(), ioOpt(ioOpt::SHORT(),"\t|-> ")) )
			glish_message->Stream() << endl;

	IValue* result = DoExec( flow );

	line_num = prev_line_num;

	return result;
	}

int Stmt::DoesTrace( ) const
	{
	return 0;
	}

void Stmt::Notify( Agent* /* agent */ )
	{
	}

int Stmt::IsActiveFor( Agent* /* agent */, const char* /* field */,
		       IValue* /* value */, Expr */* from_subsequence */ ) const
	{
	return 1;
	}

void Stmt::SetActivity( int /* activate */ )
	{
	}

int Stmt::GetActivity( ) const
	{
	return 1;
	}

const char *SeqStmt::Description() const
	{
	return "sequence";
	}

SeqStmt::~SeqStmt()
	{
	NodeUnref( lhs );
	NodeUnref( rhs );
	}

SeqStmt::SeqStmt( Stmt* arg_lhs, Stmt* arg_rhs )
	{
	lhs = arg_lhs;
	rhs = arg_rhs;
	}

IValue* SeqStmt::DoExec( evalOpt &flow )
	{
	evalOpt lflow(flow);
	flow.clear(evalOpt::VALUE_NEEDED);
	IValue* result = lhs->Exec( flow );
	flow = lflow;

	if ( flow.Next() )
		{
		Unref( result );
		result = rhs->Exec( flow );
		}

	return result;
	}

void SeqStmt::CollectUnref( stmt_list &del_list )
	{
	if ( RefCount() > 1 )
		NodeUnref( this );
	else if ( ! del_list.is_member( this ) )
		{
		del_list.append( this );
		if ( lhs ) lhs->CollectUnref( del_list );
		if ( rhs ) rhs->CollectUnref( del_list );
		lhs = rhs = 0;
		}
	}

int SeqStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.flags(ioOpt::SHORT()) ) return 0;
	s << "{\n";
	lhs->Describe( s, opt );
	s << "\n";
	rhs->Describe( s, opt );
	s << "}\n";
	return 1;
	}

const char *WheneverStmtCtor::Description() const
	{
	return "whenever";
	}

WheneverStmtCtor::WheneverStmtCtor( event_dsg_list* arg_trigger, Sequencer* arg_sequencer )
	{
	trigger = arg_trigger;
	stmt = 0;
	cur = 0;
	sequencer = arg_sequencer;
	sequencer->RegisterWhenever(this);
	int sqlen = glish_current_subsequence->length();
	in_subsequence =  sqlen ? (*glish_current_subsequence)[sqlen-1] : 0;
	}

int WheneverStmtCtor::Index( )
	{
	if ( ! cur ) cur = new WheneverStmt(sequencer);
	return cur->Index();
	}

void WheneverStmtCtor::SetStmt( Stmt* arg_stmt )
	{
	sequencer->UnregisterWhenever( );
	index = 0;
	stmt = arg_stmt;
	}

WheneverStmtCtor::~WheneverStmtCtor()
	{
	NodeUnref( stmt );

	if ( trigger && trigger->RefCount() == 1 )
		{
		loop_over_list( *trigger, i )
			Unref( (*trigger)[i] );
		}

	Unref( trigger );
	}

void WheneverStmtCtor::CollectUnref( stmt_list &del_list )
	{
	if ( RefCount() > 1 )
		NodeUnref( this );
	else if ( ! del_list.is_member( this ) )
		{
		del_list.append( this );
		if ( stmt ) stmt->CollectUnref( del_list );
		stmt = 0;
		}
	}

IValue* WheneverStmtCtor::DoExec( evalOpt & )
	{
	if ( ! cur )
		new WheneverStmt( trigger, stmt, sequencer, in_subsequence );
	else
		{
		cur->Init( trigger, stmt, in_subsequence );
		cur = 0;
		}

	return 0;
	}

int WheneverStmtCtor::Describe( OStream& s, const ioOpt &opt ) const
	{
	GlishObject::Describe( s, opt );
	if ( opt.flags(ioOpt::SHORT()) ) return 1;
	s << " ";
	describe_event_list( trigger, s );
	s << " do ";
	stmt->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	return 1;
	}


const char *WheneverStmt::Description() const
	{
	return "whenever";
	}

unsigned int WheneverStmt::NotifyCount()
	{
	return notify_count;
	}

Notification::Type WheneverStmt::NoteType( ) const
	{
	return Notification::WHENEVER;
	}

WheneverStmt::WheneverStmt(Sequencer *arg_seq) : trigger(0), sequencer(arg_seq),
						 active(0), stack(0), cycle_roots(0), in_subsequence(0)
	{
	index = sequencer->RegisterStmt( this );
	}

WheneverStmt::WheneverStmt( event_dsg_list* arg_trigger, Stmt *arg_stmt, Sequencer* arg_seq,
			    Expr *arg_in_subsequence ) : trigger(0), sequencer(arg_seq),
						 active(0), stack(0), cycle_roots(0), in_subsequence(0)
	{
	index = sequencer->RegisterStmt( this );

	Init( arg_trigger, arg_stmt, arg_in_subsequence );
	}

void WheneverStmt::Init( event_dsg_list* arg_trigger, Stmt *arg_stmt, Expr *arg_in_subsequence )
	{
	trigger = arg_trigger; Ref(trigger);
	stmt = arg_stmt; Ref(stmt);
	in_subsequence = arg_in_subsequence;

	stack = sequencer->LocalFrames();

	//
	// The reference-cycle roots (functions) were being deleted out from
	// under whenever statements. This happens when a whenever stmt(s) is
	// the only thing keeping a collection of functions active. There is
	// not always a cycle list for the most recent function invocation, so
	// we must search back through the list (of lists).
	//
	cycle_roots = UserFunc::GetRoots( );
	for ( int i=1; ! cycle_roots && i < UserFunc::GetRootsLen( ); cycle_roots = UserFunc::GetRoots( i++ ) );
	if ( cycle_roots ) Ref( cycle_roots );

	Notifiee *note = new Notifiee( this, stack, sequencer );
	loop_over_list( *trigger, i )
		{
		(*trigger)[i]->Register( note );
		Agent *ag = (*trigger)[i]->EventAgent( VAL_CONST );
		if ( ag )
			{
			ag->RegisterUnref( this );
			(*trigger)[i]->EventAgentDone( );
			}
		}

	Unref( note );

	active = 1;

	//
	// This is checked to avoid Unref()ing this out from under
	// us. A ref_count == 1 seems to happen when the agents
	// upon which this whenever is based are not agents, e.g.
	// when the widget creation routine <fail>s
	//
	// LEAK: I think in such cases, this memory is leaked...
	//
	if ( RefCount() > 1 )
		Unref(this);

	sequencer->WheneverExecuted( this );
	}

int WheneverStmt::canDelete() const
	{
// 	return shutting_glish_down;
	return 1;
	}

void WheneverStmt::Notify( Agent* /* agent */ )
	{
	evalOpt flow;

	notify_count += 1;

	//
	// need to set "file_name" for errors during execution
	//
	unsigned short old_file_name = file_name;
	file_name = file;
	Unref( stmt->Exec( flow ) );
	file_name = old_file_name;

	notify_count -= 1;

	if ( ! flow.Next() )
		glish_warn->Report( "loop/break/return does not make sense inside",
				this );
	}

int WheneverStmt::IsActiveFor( Agent *agent, const char* /* field */,
			       IValue* /* value */, Expr *from_subsequence ) const
	{
	int ret = active;

	if ( agent->IsSubsequence() )
		{
		if ( from_subsequence && in_subsequence &&
		     from_subsequence == in_subsequence &&
		     ! agent->ReflectEvents() )
			ret = 0;

		else if ( ! from_subsequence && ! in_subsequence  && agent->IsSubsequence() )
			ret = 0;
		}

	return ret;
	}

void WheneverStmt::SetActivity( int activate )
	{
	active = activate;
	}

int WheneverStmt::GetActivity( ) const
	{
	return active;
	}

int WheneverStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	GlishObject::Describe( s, opt );
	if ( opt.flags(ioOpt::SHORT()) ) return 1;
	s << " ";
	describe_event_list( trigger, s );
	s << " do ";
	stmt->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	return 1;
	}

IValue* WheneverStmt::DoExec( evalOpt & )
	{
	return 0;
	}

WheneverStmt::~WheneverStmt()
	{
	sequencer->UnregisterStmt( this );

	NodeUnref( stmt );

	if ( trigger && trigger->RefCount() == 1 )
		{
		loop_over_list( *trigger, i )
			Unref( (*trigger)[i] );
		}

	Unref( stack );
	Unref( cycle_roots );
	Unref( trigger );
	}


const char *LinkStmt::Description() const
	{
	return "link";
	}

LinkStmt::~LinkStmt()
	{
	if ( source )
		{
		loop_over_list( *source, i )
			Unref( (*source)[i] );

		delete source;
		}

	if ( sink )
		{
		loop_over_list( *sink, i )
			Unref( (*sink)[i] );

		delete sink;
		}
	}

LinkStmt::LinkStmt( event_dsg_list* arg_source, event_dsg_list* arg_sink,
			Sequencer* arg_sequencer )
	{
	source = arg_source;
	sink = arg_sink;
	sequencer = arg_sequencer;
	}

IValue* LinkStmt::DoExec( evalOpt & )
	{
	IValue *err = 0;
	loop_over_list( *source, i )
		{
		if ( err ) break;

		EventDesignator* src = (*source)[i];
		Agent* src_agent = src->EventAgent( VAL_CONST );

		if ( ! src_agent )
			{
			err = (IValue*) Fail( src->EventAgentExpr(),
					      "is not an agent" );
			continue;
			}

		Task* src_task = src_agent->AgentTask();

		if ( ! src_task )
			{
			err = (IValue*) Fail( src->EventAgentExpr(),
				"is not a client" );
			continue;
			}

		PList(char) &name_list = src->EventNames( 1 );

		if ( name_list.length() == 0 )
			{
			err = (IValue*) Fail( this,
				"linking of all events not yet supported" );
			continue;
			}

		loop_over_list( *sink, j )
			{
			if ( err ) break;

			EventDesignator* snk = (*sink)[j];
			Agent* snk_agent = snk->EventAgent( VAL_REF );

			if ( ! snk_agent )
				{
				err = (IValue*) Fail( snk->EventAgentExpr(),
					"is not an agent" );
				continue;
				}

			Task* snk_task = snk_agent->AgentTask();

			if ( ! snk_task )
				{
				err = (IValue*) Fail( snk->EventAgentExpr(),
					"is not a client" );
				continue;
				}

			PList(char) &sink_list = snk->EventNames( 1 );

			if ( sink_list.length() > 1 )
				err = (IValue*) Fail(
				"multiple event names not allowed in \"to\":",
						this );
			else
				{
				loop_over_list( name_list, k )
					{
					const char* name = (name_list)[k];

					MakeLink( src_task, name, snk_task,
						  sink_list.length() ? sink_list[0] : name );
					}
				}

			snk->EventAgentDone();
			}

		src->EventAgentDone();
		}

	return err;
	}

int LinkStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	GlishObject::Describe( s, opt );
	s << " ";
	describe_event_list( source, s );
	s << " to ";
	describe_event_list( sink, s );
	return 1;
	}

void LinkStmt::MakeLink( Task* src, const char* source_event,
			 Task* snk, const char* sink_event )
	{
	IValue* v = create_irecord();

	v->SetField( "event", source_event );
	v->SetField( "new_name", sink_event );
	v->SetField( "source_id", src->TaskID() );
	v->SetField( "sink_id", snk->TaskID() );
	v->SetField( "is_local", same_host( src, snk ) );

	LinkAction( src, v );

	Unref( v );
	}

void LinkStmt::LinkAction( Task* src, IValue* v )
	{
	src->SendSingleValueEvent( "*link-sink*", v, Agent::mLOG( ) );
	}


const char *UnLinkStmt::Description() const
	{
	return "unlink";
	}

UnLinkStmt::~UnLinkStmt() { }

UnLinkStmt::UnLinkStmt( event_dsg_list* arg_source, event_dsg_list* arg_sink,
			Sequencer* arg_sequencer )
: LinkStmt( arg_source, arg_sink, arg_sequencer )
	{
	}

void UnLinkStmt::LinkAction( Task* src, IValue* v )
	{
	src->SendSingleValueEvent( "*unlink-sink*", v, Agent::mLOG( ) );
	}


const char *AwaitStmt::Description() const
	{
	return "await";
	}

AwaitStmt::~AwaitStmt()
	{
	if ( await_list )
		{
		loop_over_list( *await_list, i )
			Unref( (*await_list)[i] );

		delete await_list;
		}

	if ( except_list )
		{
		loop_over_list( *except_list, i )
			Unref( (*except_list)[i] );

		delete except_list;
		}

	NodeUnref( except_stmt );
	}

void AwaitStmt::CollectUnref( stmt_list &del_list )
	{
	if ( RefCount() > 1 )
		NodeUnref( this );
	else if ( ! del_list.is_member( this ) )
		{
		del_list.append( this );
		if ( except_stmt ) except_stmt->CollectUnref( del_list );
		except_stmt = 0;
		}
	}

AwaitStmt::AwaitStmt( event_dsg_list* arg_await_list, int arg_only_flag,
		      event_dsg_list* arg_except_list, Sequencer* arg_sequencer )
	{
	await_list = arg_await_list;
	only_flag = arg_only_flag;
	except_list = arg_except_list;
	sequencer = arg_sequencer;
//	except_stmt = null_stmt;
	except_stmt = this;
	}

IValue* AwaitStmt::DoExec( evalOpt & )
	{
	Notifiee *note = new Notifiee( this, sequencer );
	loop_over_list( *await_list, i )
		(*await_list)[i]->Register( note );
	Unref( note );

	if ( except_list )
		{
		note = new Notifiee( except_stmt, sequencer );
		loop_over_list( *except_list, j )
			(*except_list)[j]->Register( note );
		Unref( note );
		}

	sequencer->Await( this, only_flag, except_stmt );

	loop_over_list( *await_list, k )
		(*await_list)[k]->UnRegister( this );

	if ( except_list )
		loop_over_list( *except_list, l )
			(*except_list)[l]->UnRegister( except_stmt );

	return 0;
	}

Notification::Type AwaitStmt::NoteType( ) const
	{
	return Notification::AWAIT;
	}

const char *AwaitStmt::TerminateInfo() const
	{
	static SOStream sos;
	sos.reset();
	sos << "await terminated";
	if ( file && glish_files )
		sos << " (file \"" << (*glish_files)[file] << "\", line " << line << ")";
	sos << ":" << endl;
	Describe(sos);
	sos << "" << endl;
	return sos.str();
	}

int AwaitStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	s << "await ";

	loop_over_list( *await_list, i )
		{
		(*await_list)[i]->Describe( s, ioOpt(opt.flags(),opt.sep()) );
		s << " ";
		}

	if ( except_list )
		{
		s << " except ";

		loop_over_list( *except_list, j )
			{
			(*except_list)[j]->Describe( s, ioOpt(opt.flags(),opt.sep()) );
			s << " ";
			}
		}
	return 1;
	}

const char *ActivateStmt::Description() const
	{
	return "activate";
	}

ActivateStmt::~ActivateStmt()
	{
	NodeUnref( expr );
	}

ActivateStmt::ActivateStmt( int arg_activate, Expr* e,
				Sequencer* arg_sequencer )
	{
	activate = arg_activate;
	expr = e;
	sequencer = arg_sequencer;
	}

IValue* ActivateStmt::DoExec( evalOpt &opt )
	{
	if ( expr )
		{
		IValue* index_value = expr->CopyEval(opt);

		if ( ! index_value->IsNumeric() )
			{
			IValue *err = (IValue*) Fail( "non-numeric index, ", index_value );
			Unref( index_value );
			return err;
			}

		int* index_ = index_value->IntPtr(0);
		int n = index_value->Length();

		for ( int i = 0; i < n; ++i )
			{
			Stmt* s = sequencer->LookupStmt( index_[i] );

			if ( ! s )
				{
				Unref( index_value );
				return 0;
				}

			s->SetActivity( activate );
			}

		Unref( index_value );
		}

	else
		{
		Notification* n = sequencer->LastNotification();

		if ( ! n )
			return (IValue*) Fail(
			"\"activate\"/\"deactivate\" executed without previous \"whenever\"" );

		n->notifiee->stmt()->SetActivity( activate );
		}

	return 0;
	}

int ActivateStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( activate )
		s << "activate";
	else
		s << "deactivate";

	if ( expr )
		{
		s << " ";
		expr->Describe( s, ioOpt(opt.flags(),opt.sep()) );
		}
	return 1;
	}

const char *IfStmt::Description() const
	{
	return "if";
	}

IfStmt::~IfStmt()
	{
	NodeUnref( expr );
	NodeUnref( true_branch );
	NodeUnref( false_branch );
	}

void IfStmt::CollectUnref( stmt_list &del_list )
	{
	if ( RefCount() > 1 )
		NodeUnref( this );
	else if ( ! del_list.is_member( this ) )
		{
		del_list.append( this );
		if ( true_branch ) true_branch->CollectUnref( del_list );
		if ( false_branch ) false_branch->CollectUnref( del_list );
		true_branch = false_branch = 0;
		}
	}

IfStmt::IfStmt( Expr* arg_expr, Stmt* arg_true_branch,
		Stmt* arg_false_branch )
	{
	expr = arg_expr;
	true_branch = arg_true_branch;
	false_branch = arg_false_branch;
	}

IValue* IfStmt::DoExec( evalOpt &flow )
	{
	const IValue* test_value = expr->ReadOnlyEval(flow);
	Str err;
	int take_true_branch = test_value->BoolVal(1,err);
	expr->ReadOnlyDone( test_value );

	if ( err.chars() )
		return (IValue*) Fail(err.chars());

	IValue* result = 0;

	if ( take_true_branch )
		{
		if ( true_branch )
			result = true_branch->Exec( flow );
		}

	else if ( false_branch )
		result = false_branch->Exec( flow );

	return result;
	}

int IfStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	s << "if ";
	expr->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	if ( opt.flags(ioOpt::SHORT()) ) return 1;
	s << " ";

	if ( true_branch )
		true_branch->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	else
		s << " { } ";

	if ( false_branch )
		{
		s << "\nelse ";
		false_branch->Describe( s, ioOpt(opt.flags(),opt.sep()) );
		}
	return 1;
	}

const char *ForStmt::Description() const
	{
	return "for";
	}

ForStmt::~ForStmt()
	{
	NodeUnref( index );
	NodeUnref( range );
	NodeUnref( body );
	}

void ForStmt::CollectUnref( stmt_list &del_list )
	{
	if ( RefCount() > 1 )
		NodeUnref( this );
	else if ( ! del_list.is_member( this ) )
		{
		del_list.append( this );
		if ( body ) body->CollectUnref( del_list );
		body = 0;
		}
	}

ForStmt::ForStmt( Expr* index_expr, Expr* range_expr,
		  Stmt* body_stmt )
	{
	index = index_expr;
	range = range_expr;
	body = body_stmt;
	}

IValue* ForStmt::DoExec( evalOpt &flow )
	{
	IValue* range_value = range->CopyEval(flow);

	if ( ! range_value ) return 0;

	IValue* result = 0;
	glish_type type = range_value->Type();

	if ( ! range_value->IsNumeric() && type != TYPE_STRING && type != TYPE_RECORD )
		result = (IValue*) Fail( "range (", range,
				") in for loop is not numeric or record or string" );
	else
		{
		int len = range_value->Length();

		for ( int i = 1; i <= len; ++i )
			{
			IValue *iter_value = 0;
			IValue *loop_counter = 0;

			if ( type == TYPE_RECORD )
				iter_value = new IValue( * (IValue*) range_value->NthField( i ) );
			else
				{
				loop_counter = new IValue( i );
				iter_value = (IValue*)((*range_value)[loop_counter]);
				}

			index->Assign( flow, iter_value );

			Unref( result );

			// Must preserve value_needed flag; it would be
			// nice to have a more elegant way to do this...
			int value_needed = flow.value_needed();
			flow.clear(evalOpt::VALUE_NEEDED);
			result = body->Exec( flow );
			if ( value_needed ) flow.set(evalOpt::VALUE_NEEDED);

			Unref( loop_counter );

			if ( flow.Break() || flow.Return() )
				break;
			}
		}

	Unref( range_value );

	if ( ! flow.Return() )
		flow.set(evalOpt::NEXT);

	return result;
	}

int ForStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	s << "for ( ";
	index->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << " in ";
	range->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << " ) ";
	if ( opt.flags(ioOpt::SHORT()) ) return 1;
	body->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	return 1;
	}

const char *WhileStmt::Description() const
	{
	return "while";
	}

WhileStmt::~WhileStmt()
	{
	NodeUnref( test );
	NodeUnref( body );
	}

void WhileStmt::CollectUnref( stmt_list &del_list )
	{
	if ( RefCount() > 1 )
		NodeUnref( this );
	else if ( ! del_list.is_member( this ) )
		{
		del_list.append( this );
		if ( body ) body->CollectUnref( del_list );
		body = 0;
		}
	}

WhileStmt::WhileStmt( Expr* test_expr, Stmt* body_stmt )
	{
	test = test_expr;
	body = body_stmt;
	}

IValue* WhileStmt::DoExec( evalOpt &flow )
	{
	Str err;
	IValue* result = 0;

	while ( 1 )
		{
		const IValue* test_value = test->ReadOnlyEval( flow );
		int do_test = test_value->BoolVal(1,err);
		test->ReadOnlyDone( test_value );

		if ( err.chars() )
			{
			result = (IValue*) Fail(err.chars());
			break;
			}

		if ( do_test )
			{
			Unref( result );

			// Must preserve value_needed flag; it would be
			// nice to have a more elegant way to do this...
			int value_needed = flow.value_needed();
			flow.clear(evalOpt::VALUE_NEEDED);
			result = body->Exec( flow );
			if ( value_needed ) flow.set(evalOpt::VALUE_NEEDED);

			if ( flow.Break() || flow.Return() )
				break;
			}

		else
			break;
		}

	if ( ! flow.Return() )
		flow.set(evalOpt::NEXT);

	return result;
	}

int WhileStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	s << "while ( ";
	test->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << " ) ";
	if ( opt.flags(ioOpt::SHORT()) ) return 1;
	body->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	return 1;
	}

const char *PrintStmt::Description() const
	{
	return "print";
	}

PrintStmt::~PrintStmt()
	{
	if ( args )
		{
		loop_over_list( *args, i )
			NodeUnref( (*args)[i] );
		delete args;
		}
	}

IValue* PrintStmt::DoExec( evalOpt & )
	{
	if ( args )
		{
		char* args_string = paste( args );
		pager->Report( args_string );
		free_memory( args_string );
		}

	else
		glish_message->Report( "" );

	return 0;
	}

int PrintStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	s << "print ";

	describe_parameter_list( args, s );

	s << ";";
	return 1;
	}


const char *FailStmt::Description() const
	{
	return "fail";
	}

FailStmt::~FailStmt()
	{
	if ( arg ) NodeUnref( arg );
	}

IValue* FailStmt::DoExec( evalOpt &flow )
	{
	flow.set(evalOpt::RETURN);

	if ( arg )
		ClearFail();

	IValue *ret = (IValue*) Fail( );

	//
	// Assign message separately so that the message is preserved.
	//
	if ( arg ) ret->SetFailMessage( arg->CopyEval(flow) );

	return ret;
	}

int FailStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	s << "fail ";

	if ( arg )
		arg->Describe( s, ioOpt(opt.flags(),opt.sep()) );

	s << ";";
	return 1;
	}


void FailStmt::ClearFail()
	{
	Unref(last_fail);
	last_fail = 0;
	}

const IValue *FailStmt::GetFail()
	{
	return last_fail;
	}

IValue *FailStmt::SwapFail( IValue *err )
	{
	IValue *t = last_fail;
	if ( err ) Ref( err );
	last_fail = err;
	return t;
	}

void FailStmt::SetFail( IValue *err )
	{
	if ( err ) Ref( err );
	Unref(last_fail);
	last_fail = err;
	}


const char *IncludeStmt::Description() const
	{
	return "include";
	}

IncludeStmt::~IncludeStmt()
	{
	if ( arg ) NodeUnref( arg );
	}

IValue* IncludeStmt::DoExec( evalOpt &flow )
	{
	const IValue *str_val = arg->ReadOnlyEval( flow );
	char *str = str_val->StringVal();
	arg->ReadOnlyDone( str_val );

	IValue *ret = sequencer->Include( flow, str );

	free_memory( str );
	return ret;
	}

int IncludeStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	s << "include ";

	if ( arg )
		arg->Describe( s, ioOpt(opt.flags(),opt.sep()) );

	s << ";";
	return 1;
	}


const char *ExprStmt::Description() const
	{
	return "expression";
	}

ExprStmt::~ExprStmt()
	{
	NodeUnref( expr );
	}

IValue* ExprStmt::DoExec( evalOpt &flow )
	{
	if ( flow.value_needed() && ! expr->Invisible() )
		return expr->CopyEval(flow);
	else
		return expr->SideEffectsEval( flow );
	}

int ExprStmt::DoesTrace( ) const
	{
	return expr->DoesTrace();
	}

int ExprStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	expr->Describe( s, ioOpt(opt.flags(),opt.sep()) );
	s << ";";
	return 1;
	}

const char *ExitStmt::Description() const
	{
	return "exit";
	}

ExitStmt::~ExitStmt() { }

int ExitStmt::canDelete() const
	{
	return can_delete;
	}

IValue* ExitStmt::DoExec( evalOpt &opt )
	{
	can_delete = 0;

	ValCtor::cleanup();

	int exit_val = status ? status->CopyEval(opt)->IntVal() : 0;

	delete sequencer;

	exit( exit_val );

	return 0;
	}

int ExitStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	s << "exit";

	if ( status )
		{
		s << " ";
		status->Describe( s, ioOpt(opt.flags(),opt.sep()) );
		}
	return 1;
	}

const char *LoopStmt::Description() const
	{
	return "next";
	}

LoopStmt::~LoopStmt() { }

IValue* LoopStmt::DoExec( evalOpt &flow )
	{
	flow.set(evalOpt::LOOP);
	return 0;
	}


const char *BreakStmt::Description() const
	{
	return "break";
	}

BreakStmt::~BreakStmt() { }

IValue* BreakStmt::DoExec( evalOpt &flow )
	{
	flow.set(evalOpt::BREAK);
	return 0;
	}

const char *ReturnStmt::Description() const
	{
	return "return";
	}

ReturnStmt::~ReturnStmt()
	{
	NodeUnref( retval );
	}

IValue* ReturnStmt::DoExec( evalOpt &flow )
	{
	flow.set(evalOpt::RETURN);

	if ( retval )
		return retval->CopyEval(flow);

	else
		return 0;
	}

int ReturnStmt::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	s << "return";

	if ( retval )
		{
		s << " ";
		retval->Describe( s, ioOpt(opt.flags(),opt.sep()) );
		}
	return 1;
	}

StmtBlock::~StmtBlock()
	{
	NodeUnref( stmt );
	}

void StmtBlock::CollectUnref( stmt_list &del_list )
	{
	if ( RefCount() > 1 )
		NodeUnref( this );
	else if ( ! del_list.is_member( this ) )
		{
		del_list.append( this );
		if ( stmt ) stmt->CollectUnref( del_list );
		stmt = 0;
		}
	}

StmtBlock::StmtBlock( int fsize, Stmt *arg_stmt,
			Sequencer *arg_sequencer )
	{
	stmt = arg_stmt;
	frame_size = fsize;
	sequencer = arg_sequencer;
	}

IValue* StmtBlock::DoExec( evalOpt &flow )
	{
	IValue* result = 0;

	if ( frame_size )
		{
		Frame* call_frame = new Frame( frame_size, 0, 0, LOCAL_SCOPE );

		sequencer->PushFrame( call_frame );

		result = stmt->Exec( flow );

		if ( sequencer->PopFrame() != call_frame )
			glish_fatal->Report( "frame inconsistency in StmtBlock::DoExec" );

		Unref( call_frame );
		}
	else
		{
		sequencer->PushFrame( 0 );
		result = stmt->Exec( flow );
		sequencer->PopFrame();
		}

	return result;
	}

int StmtBlock::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.flags(ioOpt::SHORT()) ) return 0;
	if ( opt.prefix() ) s << opt.prefix();
	s << "{{ ";
	stmt->Describe( s, opt );
	s << " }}";
	return 1;
	}

const char *NullStmt::Description() const
	{
	return ";";
	}

NullStmt::~NullStmt() { }

int NullStmt::canDelete() const
	{
	return 0;
	}

IValue* NullStmt::DoExec( evalOpt & )
	{
	return 0;
	}


Stmt* merge_stmts( Stmt* stmt1, Stmt* stmt2 )
	{
	if ( stmt1 == null_stmt )
		return stmt2;

	else if ( stmt2 == null_stmt )
		return stmt1;

	else
		return new SeqStmt( stmt1, stmt2 );
	}
