// $Id: Stmt.h,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
#ifndef stmt_h
#define stmt_h
#include "Glish/List.h"
#include "Func.h"
#include "Event.h"

class Stmt;
class EventDesignator;
class Agent;
class Task;
class Sequencer;

// This is used for notification of when an event has been handled, i.e.
// completion of a notification.
class NotifyTrigger : public GlishObject {
    public:
	virtual void NotifyDone( );
	NotifyTrigger() { }
	virtual ~NotifyTrigger();
};

class Notification : public GlishObject {
public:
	enum Type { WHENEVER, AWAIT, STICKY, UNKNOWN };
	Notification( Agent* notifier, const char* field, IValue* value,
			Notifiee* notifiee, NotifyTrigger *t=0, Type ty=WHENEVER );
	~Notification();

	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	void invalid( ) { valid = 0; }
	Type type() { return type_; }
	void type( Type t ) { type_ = t; }

	Agent* notifier;
	char* field;
	IValue* value;
	Notifiee* notifiee;
	NotifyTrigger *trigger;
	int valid;
	Type type_;
	};

glish_declare(PList,Notification);
typedef PList(Notification) notification_list;

glish_declare(PList,Stmt);
typedef PList(Stmt) stmt_list;

glish_declare(PDict,stmt_list);
typedef PDict(stmt_list) stmt_list_dict;


class Stmt : public ParseNode {
    public:
	Stmt()
		{ index = 0; }

	// Exec() tells a statement to go ahead and execute.  We use
	// it as a wrapper around the actual execute member function
	// so we can reset the current line number and perform any
	// other "global" statement execution (such as setting the
	// control flow to default to FLOW_NEXT).
	//
	// The "value_needed" argument, indicates whether any value
	// produced by this statement is of interest (because the
	// statement is possibly the last one in a function, so the
	// value will become the function value).  Note that "value_needed"
	// is advisory; some statements (like "return") will always
	// return a value regardless of "value_needed"'s setting.
	//
	// Exec() returns a value associated with the statement or 0
	// if there is none, and in "flow" returns a stmt_flow_type
	// indicating control flow information.
	virtual IValue* Exec( evalOpt &opt );
	// Returns true if this statement is going to do an echo of itself
	// AS PART OF EVALUATION, I.E. "DoExec()", if trace is turned on.
	virtual int DoesTrace( ) const;

	// Called when an event we've expressed interest in has arrived.
	// The argument specifies the Agent associated with the
	// event.
	virtual void Notify( Agent* agent );

	// Returns true if we're currently active for the given event
	// generated by the given agent, with the given value; false
	// otherwise.  Only actually used by "whenever" statements.
	virtual int IsActiveFor( Agent* agent, const char* field, IValue* value,
				Expr *from_subsequence=0 ) const;

	// Sets the statement's activity, either to true (if "activate" is
	// true) or to false.
	virtual void SetActivity( int activate );
	virtual int GetActivity( ) const;

	// Return the index of this statement.  Might be 0, indicating
	// that the statement is not intended to be indexed (presently,
	// only "whenever" statements are meant to be indexed).
	int Index() const	{ return index; }

	virtual ~Stmt();

	//
	// Sometimes, e.g. when a syntax error occurs, the stmt tree can
	// get messed up. In particular, one node can be included more than
	// once in the tree. This function collects those nodes in the tree
	// which can be Unref'ed in the stmt_list. This prevents nodes from
	// being freed more than once.
	//
	virtual void CollectUnref( stmt_list & );

	virtual Notification::Type NoteType( ) const;

    protected:
	// DoExec() does the real work of executing the statement.
	virtual IValue* DoExec( evalOpt &opt ) = 0;

	int index;
	};


class SeqStmt : public Stmt {
    public:
	SeqStmt( Stmt* arg_lhs, Stmt* arg_rhs );

	IValue* DoExec( evalOpt &opt );

	int Describe( OStream&, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~SeqStmt();

	void CollectUnref( stmt_list & );

	const char *Description() const;

    protected:
	Stmt* lhs;
	Stmt* rhs;
	};


class WheneverStmt : public Stmt {
    public:
	WheneverStmt( Sequencer *arg_seq );

	void Init( event_dsg_list* arg_trigger, Stmt *arg_stmt, Expr *arg_in_subsequence=0 );
	WheneverStmt( event_dsg_list* arg_trigger, Stmt *arg_stmt, Sequencer* arg_seq,
		      Expr *arg_in_subsequence=0 );

	virtual ~WheneverStmt();

	IValue* DoExec( evalOpt &opt );
	void Notify( Agent* agent );

	Notification::Type NoteType( ) const;

	//
	// Currently these two stmts do the same thing...
	//
	int IsActiveFor( Agent* agent, const char* field, IValue* value,
			 Expr *from_subsequence=0 ) const;

	int GetActivity( ) const;
	void SetActivity( int activate );

	static unsigned int NotifyCount();

	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	int canDelete() const;

	const char *Description() const;

    protected:
	event_dsg_list* trigger;
	Stmt* stmt;
	Sequencer* sequencer;
	int active;
	static unsigned int notify_count;
	stack_type *stack;
	NodeList *cycle_roots;
	Expr *in_subsequence;
	};


class WheneverStmtCtor : public Stmt {
    public:

	//
	// It is assumed that these, the ctor and "SetStmt()",  will
	// be called together. This little dance is to allow
	// activate/deactivate statements to be constructed with the
	// proper index.
	//
	WheneverStmtCtor( event_dsg_list* arg_trigger, Sequencer* arg_sequencer );
	void SetStmt( Stmt* arg_stmt );

	virtual ~WheneverStmtCtor();

	IValue* DoExec( evalOpt &opt );

	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	void CollectUnref( stmt_list & );

	int Index( );

	const char *Description() const;

    protected:
	event_dsg_list* trigger;
	Stmt* stmt;
	Sequencer* sequencer;
	WheneverStmt* cur;
	Expr *in_subsequence;
	};


class LinkStmt : public Stmt {
    public:
	LinkStmt( event_dsg_list* source, event_dsg_list* sink, Sequencer* sequencer );

	IValue* DoExec( evalOpt &opt );
	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~LinkStmt();

	const char *Description() const;

    protected:
	void MakeLink( Task* src, const char* source_event,
			Task* snk, const char* sink_event );

	virtual void LinkAction( Task* src, IValue* v );

	event_dsg_list* source;
	event_dsg_list* sink;
	Sequencer* sequencer;
	};


class UnLinkStmt : public LinkStmt {
    public:
	UnLinkStmt( event_dsg_list* source, event_dsg_list* sink,
			Sequencer* sequencer );

	~UnLinkStmt();

	const char *Description() const;

    protected:
	void LinkAction( Task* src, IValue* v );
	};


class AwaitStmt : public Stmt {
    public:
	AwaitStmt( event_dsg_list* arg_await_list, int arg_only_flag,
		   event_dsg_list* arg_except_list,
		   Sequencer* arg_sequencer );

	IValue* DoExec( evalOpt &opt );
	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }
	const char *TerminateInfo() const;
	event_dsg_list *AwaitList() { return await_list; }

	~AwaitStmt();

	void CollectUnref( stmt_list & );

	const char *Description() const;

	Notification::Type NoteType( ) const;

    protected:
	event_dsg_list* await_list;
	int only_flag;
	event_dsg_list* except_list;
	Sequencer* sequencer;
	Stmt* except_stmt;
	};


class ActivateStmt : public Stmt {
    public:
	ActivateStmt( int activate, Expr* e, Sequencer* sequencer );

	IValue* DoExec( evalOpt &opt );
	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~ActivateStmt();

	const char *Description() const;

    protected:
	int activate;
	Expr* expr;
	Sequencer* sequencer;
	};


class IfStmt : public Stmt {
    public:
	IfStmt( Expr* arg_expr,
		Stmt* arg_true_branch,
		Stmt* arg_false_branch );

	IValue* DoExec( evalOpt &opt );
	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~IfStmt();

	const char *Description() const;

	void CollectUnref( stmt_list & );

    protected:
	Expr* expr;
	Stmt* true_branch;
	Stmt* false_branch;
	};


class ForStmt : public Stmt {
    public:
	ForStmt( Expr* index_expr, Expr* range_expr,
		 Stmt* body_stmt );

	IValue* DoExec( evalOpt &opt );
	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~ForStmt();

	const char *Description() const;

	void CollectUnref( stmt_list & );

    protected:
	Expr* index;
	Expr* range;
	Stmt* body;
	};


class WhileStmt : public Stmt {
    public:
	WhileStmt( Expr* test_expr, Stmt* body_stmt );

	IValue* DoExec( evalOpt &opt );
	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~WhileStmt();

	const char *Description() const;

	void CollectUnref( stmt_list & );

    protected:
	Expr* test;
	Stmt* body;
	};


class PrintStmt : public Stmt {
    public:
	PrintStmt( parameter_list* arg_args ) {	args = arg_args; }

	IValue* DoExec( evalOpt &opt );
	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~PrintStmt();

	const char *Description() const;

    protected:
	parameter_list* args;
	};


class FailStmt : public Stmt {
    public:
	FailStmt( Expr* arg_arg ) { arg = arg_arg; }

	IValue* DoExec( evalOpt &opt );
	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~FailStmt();

	static void SetFail( IValue *err );
	static void ClearFail();
	static IValue *SwapFail( IValue *err );
	static const IValue *GetFail();

	const char *Description() const;

    protected:
	static IValue *last_fail;
	Expr* arg;
	};


class IncludeStmt : public Stmt {
    public:
	IncludeStmt( Expr* arg_arg, Sequencer* arg_sequencer ) :
			sequencer( arg_sequencer )
		{ arg = arg_arg; }

	IValue* DoExec( evalOpt &opt );
	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~IncludeStmt();

	const char *Description() const;

    protected:
	Expr* arg;
	Sequencer* sequencer;
	};


class ExprStmt : public Stmt {
    public:
	ExprStmt( Expr* arg_expr ) { expr = arg_expr; }

	IValue* DoExec( evalOpt &opt );
	int DoesTrace( ) const;

	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~ExprStmt();

	const char *Description() const;

    protected:
	Expr* expr;
	};


class ExitStmt : public Stmt {
    public:
	ExitStmt( Expr* arg_status, Sequencer* arg_sequencer )
		{
		status = arg_status;
		sequencer = arg_sequencer;
		can_delete = 1;
		}

	IValue* DoExec( evalOpt &opt );
	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~ExitStmt();

	int canDelete() const;

	const char *Description() const;

    protected:
	Expr* status;
	Sequencer* sequencer;
	int can_delete;
	};


class LoopStmt : public Stmt {
    public:
	LoopStmt()	{ }

	IValue* DoExec( evalOpt &opt );

	~LoopStmt();

	const char *Description() const;
	};


class BreakStmt : public Stmt {
    public:
	BreakStmt()	{ }

	IValue* DoExec( evalOpt &opt );

	~BreakStmt();

	const char *Description() const;
	};


class ReturnStmt : public Stmt {
    public:
	ReturnStmt( Expr* arg_retval )
		{ retval = arg_retval; }

	IValue* DoExec( evalOpt &opt );
	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~ReturnStmt();

	const char *Description() const;

    protected:
	Expr* retval;
	};


class StmtBlock : public Stmt {
    public:
	StmtBlock( int fsize, Stmt *arg_stmt, Sequencer *arg_sequencer );

	IValue *DoExec( evalOpt &opt );

	int Describe( OStream& s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	~StmtBlock();

	void CollectUnref( stmt_list & );

    protected:
	Sequencer *sequencer;
	Stmt *stmt;
	int frame_size;
	};

class NullStmt : public Stmt {
    public:
	NullStmt()	{ }

	IValue* DoExec( evalOpt &opt );

	~NullStmt();

	int canDelete() const;

	const char *Description() const;
	};


extern Stmt* null_stmt;
extern Stmt* merge_stmts( Stmt* stmt1, Stmt* stmt2 );

/* Used to setup subsequence whenevers */
extern expr_list *glish_current_subsequence;

#endif /* stmt_h */
