// $Id: Sequencer.h,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
#ifndef sequencer_h
#define sequencer_h
#include <stdio.h>
#include "Glish/Client.h"
#include "Stmt.h"
#include "Glish/Queue.h"
#include "Agent.h"
#include "Regex.h"
#include "Select.h"
#include "Sysinfo.h"

class UserAgent;
class GlishEvent;
class Frame;
class Notifiee;
class ScriptClient;
class Channel;

// Searches "system.include.path" for the given file; returns a malloc()'d copy
// of the path to the executable, which the caller should delete when
// done with.
extern char* which_include( const char* file_name );

// Attempt to retrieve the value associated with id. Returns 0 if the
// value is not found.
extern int lookup_print_precision( );
extern int lookup_print_limit( );

class Task;
class LoadedAgent;
class BuiltIn;
class AcceptSocket;
class AcceptSelectee;
class Selector;
class RemoteDaemon;
class await_type;
struct func_name_info;

glish_declare(PDict,Task);
glish_declare(PDict,RemoteDaemon);
glish_declare(PDict,char);
glish_declare(PQueue,Notification);
glish_declare(PList, await_type);
glish_declare(PList, WheneverStmtCtor);

typedef PDict(Expr) expr_dict;
typedef PList(await_type) awaittype_list;

glish_declare(PList,expr_list);
typedef PList(expr_list) expr_list_stack;

glish_declare(PList,ivalue_list);
typedef PList(ivalue_list) fail_stack_stack;

glish_declare(PList, func_name_info);
typedef PList(func_name_info) func_name_list;

class Scope : public expr_dict {
public:
	Scope( scope_type s = LOCAL_SCOPE ) : scope(s), expr_dict() {}
	~Scope();
	scope_type GetScopeType() const { return scope; }
	int WasGlobalRef(const char *c) const
		{ return global_refs.Lookup(c) ? 1 : 0; }
	void MarkGlobalRef(const char *c);
	void ClearGlobalRef(const char *c);
private:
	scope_type scope;
	PDict(char) global_refs;
};

glish_declare(PList,Scope);
typedef PList(Scope) scope_list;

class back_offsets_type;

class stack_type : public GlishRef {
    public:
	stack_type( const stack_type &, int clip = 0,
		    int delete_on_spot_arg = 0 );
	stack_type( );
	~stack_type( );

	frame_list *frames() { return frames_; }
	const frame_list *frames() const { return frames_; }
	int frame_len() const { return flen; }
	offset_list *offsets() { return offsets_; }
	const offset_list *offsets() const { return offsets_; }
	int offset_len() const { return olen; }
	// returns the stack which this copy was cloned from, or 0
	const stack_type *delete_on_spot() const { return delete_on_spot_; }

    protected:
	stack_type &operator=( const stack_type & );
	frame_list *frames_;
	int flen;
	offset_list *offsets_;
	int olen;
	const stack_type *delete_on_spot_;
};

glish_declare(PList,stack_type);
typedef PList(stack_type) stack_list;

extern void system_change_function(IValue *, IValue *);
class Sequencer;

class SystemInfo GC_FINAL_CLASS {
public:
	inline unsigned int TRACE( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<0; }
	inline unsigned int PRINTLIMIT( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<1; }
	inline unsigned int PRINTPRECISION( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<2; }
	inline unsigned int PATH( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<3; }
	inline unsigned int ILOGX( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<4; }
	inline unsigned int OLOGX( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<4; }
	inline unsigned int PAGER( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<4; }
	inline unsigned int STACKLIMIT( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<5; }
	inline unsigned int CLIENT( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<6; }

	int Trace() { if ( TRACE(update) ) update_output( ); return trace; }
	int ILog() { if ( ILOGX(update) ) update_output( ); return ilog || log; }
	int OLog() { if ( OLOGX(update) ) update_output( ); return olog || log; }
	int PagerLimit() { if ( PAGER(update) ) update_output( ); return pager_limit; }
	charptr *PagerExec() { if ( PAGER(update) ) update_output( ); return pager_exec; }
	int PagerExecLen() { if ( PAGER(update) ) update_output( ); return pager_exec_len; }
	void DoILog( const char *s, int len=-1 ) { DoLog( 1, s, len ); }
	void DoILog( const Value *v) { DoLog( 1, v ); }
	void DoOLog( const char *s, int len=-1 ) { DoLog( 0, s, len ); }
	void DoOLog( const Value *v) { DoLog( 0, v ); }
	int PrintLimit() { if ( PRINTLIMIT(update) ) update_print( ); return printlimit; }
	int PrintPrecision() { if ( PRINTPRECISION(update) ) update_print( ); return printprecision; }
	charptr KeyDir() { if ( PATH(update) ) update_path( ); return keydir; }
	charptr *Include() { if ( PATH(update) ) update_path( ); return include; }
	int IncludeLen() { if ( PATH(update) ) update_path( ); return includelen; }
	const IValue *BinPath() { if ( PATH(update) ) update_path( ); return binpath; }
	const IValue *LdPath() { if ( PATH(update) ) update_path( ); return ldpath; }
	int StackLimit() { if ( STACKLIMIT(update) ) update_stacklimit( ); return stacklimit; }
	double ClientPing() { if ( CLIENT(update) ) update_client( ); return client_ping; }
	SystemInfo( Sequencer *s ) : val(0), log(0), log_val(0), log_file(0), log_name(0),
			ilog(0), ilog_val(0), ilog_file(0), ilog_name(0),
			olog(0), olog_val(0), olog_file(0), olog_name(0),
			pager_limit(0), pager_exec(0), pager_exec_len(0),
			stacklimit(0), printlimit(0), printprecision(-1), include(0), includelen(0),
			binpath(0), ldpath(0), keydir(0), update( ~((unsigned int) 0) ), sequencer(s) { }
	void SetVal(IValue *v);
	~SystemInfo();
	void AbortOccurred();
private:
	void DoLog( int input, const char *s, int len=-1 );
	void DoLog( int input, const Value * );
	const char *prefix_buf(const char *prefix, const char *buf);
	void update_output( );
	void update_stacklimit( );
	void update_print( );
	void update_path( );
	void update_client( );
	IValue *val;
	int trace;

	int log;
	IValue *log_val;
	FILE *log_file;
	char *log_name;
	int ilog;
	IValue *ilog_val;
	FILE *ilog_file;
	char *ilog_name;
	int olog;
	IValue *olog_val;
	FILE *olog_file;
	char *olog_name;

	int pager_limit;
	charptr *pager_exec;
	int pager_exec_len;

	int stacklimit;

	int printlimit;
	int printprecision;

	charptr *include;
	int includelen;
	const IValue *binpath;
	const IValue *ldpath;
	charptr keydir;

	double client_ping;

	unsigned int update;
	Sequencer *sequencer;

};

class EnvHolder GC_FINAL_CLASS {
    public:
	void put( const char *var, char *string );
	IterCookie* InitForIteration() const
		{ return strings.InitForIteration(); }
	void* NextEntry( const char*& key, IterCookie*& cookie )
		{ return strings.NextEntry( key, cookie ); }
    private:
	PDict(char) strings;
};

class await_type GC_FINAL_CLASS {
    public:
	await_type() : stmt_(0), except_(0), only_(0), dict_(0),
		       agent_(0), name_(0),	filled_value(0),
		       filled_agent(0), filled_name(0) { }
	await_type( await_type &o );
	~await_type( ) { set( ); }
	void operator=( await_type &o );
	int active( ) { return stmt_ || agent_ ? 1 : 0; }
	void set( );
	void set( Stmt *s, Stmt *e, int o );
	void set( Agent *a, const char *n );

	// await statement members
	Stmt *stmt() { return stmt_; }
	Stmt *except() { return except_; }
	int only() { return only_; }
	agent_dict *dict() { return dict_; }

	// request/reply members
	Agent *agent( ) { return agent_; }
	const char *name( ) { return name_; }

	//
	// values for satisfied await
	//
	int SetValue( Agent *agent_, const char *name_, IValue *val, int force=0 );
	IValue *ResultValue( ) { return filled_value; }
	Agent *ResultAgent( ) { return filled_agent; }
	const char *ResultName( ) const { return filled_name; }

    private:
	Stmt *stmt_;
	Stmt *except_;
	int only_;
	agent_dict *dict_;
	Agent *agent_;
	const char *name_;
	//
	// values which are filled when await is satisfied
	//
	IValue *filled_value;
	Agent *filled_agent;
	char *filled_name;
};

class Sequencer GC_FINAL_CLASS {
friend class LoadedProxyStore;
friend class SystemAgent;
public:
	inline unsigned int VERB_INCL( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<0; }
	inline unsigned int VERB_FAIL( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<1; }
	inline unsigned int NO_AUTO_FAIL( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<2; }
	inline unsigned int FAIL_DEFAULT( unsigned int mask=~((unsigned int) 0) ) const { return mask & 1<<3; }

	friend class SystemInfo;
	Sequencer( int& argc, char**& argv );
	~Sequencer();

	int pid() const { return xpid; }

	const char* Name()		{ return name; }
	const char* Path()		{ return interpreter_path; }

	void AddBuiltIn( BuiltIn* built_in );

	void QueueNotification( Notification* n );
	int NotificationQueueLength ( ) { return notification_queue.length(); }

	void PushScope( scope_type s = LOCAL_SCOPE );

	// Returns size of frame corresponding to scope. If the address of a
	// back_offsets class pointer is passed and we're poping a function scope,
	// the pointer will be filled with the back offsets to wider variables,
	// e.g. global. This is important for identifying ways that the life of
	// local variables, especially functions, can be extended.
	int PopScope( back_offsets_type **p = 0 );

	void StashScope();
	void RestoreScope();

	scope_type GetScopeType( ) const;
	// For now returns the "global" scope. Later this may be modified
	// to take a "scope_type" parameter.
	Scope *GetScope( );
	int ScopeDepth() const { return scopes.length(); }

	Expr* InstallID( char* id, scope_type scope, int do_warn = 1, int bool_initial=0,
					int GlobalRef = 0, int FrameOffset = 0,
					change_var_notice f=0 );
	// "local_search_all" is used to indicate if all local scopes should be
	// searched or if *only* the "most local" scope should be searched. This
	// is only used if "scope==LOCAL_SCOPE".
	Expr* LookupID( char* id, scope_type scope, int do_install = 1, int do_warn = 1,
			int local_search_all=1, int bool_initial=0 );

	Expr* InstallVar( char* id, scope_type scope, VarExpr *var );
	Expr* LookupVar( char* id, scope_type scope, VarExpr *var,
			 int &created = glish_dummy_int );

	static Sequencer *CurSeq( );
	static const AwaitStmt *ActiveAwait( );
	int AwaitDone( );
	static char *BinPath( const char *host, const char *var = 0 );
	static char *LdPath( const char *host, const char *var = 0 );

	// Returns true when "auto fail" should be suppressed,
	// unhandled fails cause the routine to fail by default.
	int SupressAutoFail( ) const { return NO_AUTO_FAIL(verbose_mask); }
	int FailDefault( ) const { return FAIL_DEFAULT(verbose_mask); }

	SystemInfo &System() { return system; }

	// In the integration of Tk, the Tk event loop is called in the
	// process of handling glish events to the Tk widgets. It is
	// necessary to prevent the Sequencer::RunQueue() from running.
	static void HoldQueue( );
	static void ReleaseQueue( );

	// This function attempts to look up a value in the current sequencer.
	// If the value doesn't exist, null is returned.
	static const IValue *LookupVal( evalOpt &opt, const char *id );

	// things which ought not to be done...
	IValue *GetGlobal( int offset ) { return global_frame[offset]; }
	IValue *GetFunc( int frame, int offset ) { return frames()[frame]->FrameElement(offset); }
	Frame *FindCycleFrame( int frame=-1 );
	Frame *GetLocalFrame( ) { frame_list &t = frames(); return t[t.length()-1]; }

	// Deletes a given global value. This is used by 'symbol_delete()' which
	// is the only way to get rid of a 'const' value.
	void DeleteVal( const char* id );

	void DescribeFrames( OStream& s ) const;
	int FrameLen() const { return frames().length(); }
	int StackLen() const { return stack.length(); }
	void PushFrame( Frame* new_frame );
	void PushFrames( stack_type *new_stack );
	// Note that only the last frame popped is returned (are the others leaked?).
	Frame* PopFrame( );
	const stack_type *PopFrames( );

	// This trio of functions supports keeping track of the
	// function call stack. This is used in error reporting.
	void PushFuncName( const char *name, unsigned short file, unsigned short line );
	void PopFuncName( );
	static IValue *FuncNameStack( );

	static void UnhandledFail( const IValue * );
	static void FailCreated( IValue * );
	void PushFailStack( );
	IValue *PopFailStack( );

	// The current evaluation frame, or 0 if there are no local frames.
	Frame *CurrentFrame();
	Frame *FuncFrame();

	// Returns a list of the frames that are currently local, i.e. up to and
	// and including the first non LOCAL_SCOPE frame. Returns 0 if there are
	// no frames between the current frame and the GLOBAL_SCOPE frame. If this
	// list is to be kept, the frames must be Ref()ed. The returned list is
	// dynamically allocated, though.
	stack_type* LocalFrames();

	IValue* FrameElement( scope_type scope, int scope_offset, int frame_offset );
	// returns error message
	const char *SetFrameElement( scope_type scope, int scope_offset,
				     int frame_offset, IValue* value, change_var_notice f=0 );

	// The last notification processed, or 0 if none received yet.
	Notification* LastNotification() { return notes_inuse.length() ? notes_inuse[notes_inuse.length()-1] : 0; }
	//
	// These are used by UserFunc et al.
	//
	void PushNote( Notification *n );
	void PopNote( int doing_func=0 );

	// The last "whenever" statement executed, or 0 if none yet.
	// Register the given statement as the most recently-executed
	// whenever statement.
	Stmt* LastWheneverExecuted()	 { return last_whenever_executed; }
	void WheneverExecuted( Stmt* s ) { last_whenever_executed = s; }

	RegexMatch &GetMatch( ) { return regex_match; }

	// Registers a new task with the sequencer and returns its
	// task ID.
	char* RegisterTask( Task* new_task, int &idi );

	// Unregister a task.
	void DeleteTask( Task* task );

	void AddStmt( Stmt* addl_stmt );
	void ClearStmt( );
	Stmt *GetStmt( );

	// Register a statement; this assigns it a unique index that
	// can be used to retrieve the statement using LookupStmt().
	// Indexes are small positive integers.
	int RegisterStmt( Stmt* stmt );
	void UnregisterStmt( Stmt* stmt );

	// Register expressions which refer back to a larger scope,
	// e.g. global. This is important for tracking how the life
	// of function local variables can be extended...
	void RegisterBackRef( VarExpr * );

	// Notifiee has been deleted, tag queued events
	// for this notifiee
	void NotifieeDone( Notifiee * );

	// Returns 0 if the index is invalid.
	Stmt* LookupStmt( int index );

	// Returns a non-zero value if the hostname is the local
	// host, and zero otherwise
	int LocalHost( const char* hostname );

	// Return a channel to a daemon for managing clients on the given host.
	// sets "err" to a non-zero value if an error occurs
	Channel* GetHostDaemon( const char* host, int &err );

	IValue *Exec( evalOpt &opt, int startup_script = 0, int value_needed = 0 );
	IValue *Eval( evalOpt &opt, const char* strings[] );
	IValue *Include( evalOpt &, const char* file );
	// called when "pragma include once" is used
	void IncludeOnce( );

	static void SetErrorResult( IValue *err );
	void ClearErrorResult()
		{ Unref(error_result); error_result = 0; }
	const IValue *ErrorResult() const { return error_result; }

	// Wait for an event in which await_stmt has expressed interest,
	// though while waiting process any of the events in which
	// except_stmt has expressed interest (or all other events,
	// if "only_flag" is false).
	void Await( AwaitStmt* await_list, int only_flag, Stmt* except_list );
	void PagerOutput( char *string, char **argv );
	void PagerDone( ) { doing_pager = 0; }

	// Wait for a reply to the given event to arrive on the given
	// channel and return its value.
	IValue* AwaitReply( Agent* agent, const char* event_name,
				const char* reply_name );

	// In sending an event, the sending was discontinued. Most likely
	// because the pipe filled up. The fd being written to should be
	// monitored, and sending resumed when possible. Value is just a
	// copy (reference counted) and is deleted when the send completes.
	void SendSuspended( sos_status *, Value * );

	// Inform the sequencer to expect a new, local (i.e., pipe-based)
	// client communicating via the given fd's.  Returns the channel
	// used from now on to communicate with the client.
	Channel* AddLocalClient( int read_fd, int write_fd );

	// Tells the sequencer that a new client has been forked.  This
	// call *must* be made before the sequencer returns to its event
	// loop, since it keeps track of the number of active clients,
	// and if the number falls to zero the sequencer exits.
	void NewClientStarted();

	// Waits for the given task to connect to the interpreter,
	// and returns the corresponding channel.
	Channel* WaitForTaskConnection( Task* task );

	// Open a new connection and return the task it now corresponds to.
	Task* NewConnection( Channel* connection_channel );

	void AssociateTaskWithChannel( Task* task, Channel *chan );

	int NewEvent( Task* task, GlishEvent* event, int complain_if_no_interest = 0,
		      NotifyTrigger *t=0, int preserve=0 );
	int NewEvent( LoadedAgent* task, GlishEvent* event, int complain_if_no_interest = 0,
		      NotifyTrigger *t=0, int preserve=0 );
	int NewEvent( Agent* agent, GlishEvent* event, int complain_if_no_interest = 0,
		      NotifyTrigger *t=0, int preserve=0 );
	int NewEvent( Agent* agent, const char* event_name, IValue* value,
		      int complain_if_no_interest = 0, NotifyTrigger *t=0, int preserve=0 );

	// Returns true if tasks associated with the given nam should
	// have an implicit "<suspend>" attribute, false otherwise.
	int ShouldSuspend( const char* task_var_ID );

	// Used to inform the sequencer that an event belonging to the
	// agent with the given id has been generated.  If is_inbound
	// is true then the event was generated by the agent and has
	// come into the sequence; otherwise, the event is being sent
	// to the agent.
	void LogEvent( const char* gid, const char* id, const char* event_name,
			const IValue* event_value, int is_inbound );
	void LogEvent( const char* gid, const char* id, const GlishEvent* e,
			int is_inbound );

	// With UserAgents, the event handling never goes through
	// Sequencer::NewEvent(), so Agent need to be able
	void CheckAwait( Agent* agent, const char* event_name, IValue *event_val );

	// Report a "system" event; one that's reflected by the "system"
	// global variable.
	void SystemEvent( const char* name, const IValue* val );

	// Read all of the events pending in a given task's channel input
	// buffer, being careful to stop (and delete the channel) if the
	// channel becomes invalid (this can happen when one of the events
	// causes the task associated with the channel to be deleted).
	// The final flag, if true, specifies that we should force a read
	// on the channel.  Otherwise we just consume what's already in the
	// channel's buffer.
	int EmptyTaskChannel( Task* task, int force_read = 0 );

	// Reads and responds to incoming events until either one of
	// the responses is to terminate (because an "exit" statement
	// was encountered, or because there are no longer any active
	// clients) or we detect keyboard activity (when running
	// interactively). Returns non-null value if active clients remain.
	int EventLoop( int in_await = 0 );
	// Loops only while there are events pending in the queue
	int PendingEventLoop( );

	const char* ConnectionHost()	{ return connection_host; }
	const char* ConnectionPort()	{ return connection_port; }
	const char* InterpreterTag()	{ return interpreter_tag; }

	// Returns a non-zero value if there are existing clients.
	int ActiveClients() const	{ return num_active_processes > 0; }

	Client::ShareType MultiClientScript() { return multi_script; }
	Client::ShareType MultiClientScript( Client::ShareType set_to )
		{
		multi_script = set_to;
		return multi_script;
		}
	int DoingInit( ) { return doing_init; }
	int ScriptCreated( ) { return script_created; }
	int ScriptCreated( int set_to ) 
		{
		script_created = set_to;
		return script_created;
		}
	void InitScriptClient( evalOpt & );

	static void TopLevelReset();

	void UpdateLocalPath( );
	void UpdateRemotePath( );
	//
	// host=0 implies local bin path
	//
	void UpdatePath( const char *host = 0 );

	//
	// register current whenever ctor, for use in
	// activate/deactivate stmts local to the whenever
	//
	void RegisterWhenever( WheneverStmtCtor *ctor ) { cur_whenever.append(ctor); }
	void UnregisterWhenever( ) { int len = cur_whenever.length();
				     if ( len > 0 ) cur_whenever.remove_nth(len-1); }
	void ClearWhenevers( );

	int CurWheneverIndex( );

	// Called when the user aborts the glish session...
	void AbortOccurred( );

	// Retrieve the verbosity level
	int Verbose( ) const { return verbose; }

	// These are used by the internal "readline()" function to:
	//     o  check to see if stdin events are enabled
	//     o  add the stdin selectee
	//     o  remove the stdin selectee
	//
	int HaveStdinSelectee( ) const;
	int AddStdinSelectee( );
	int RemoveStdinSelectee( );

	void AddSelectee( Selectee *s ) { selector->AddSelectee( s ); }

	int MemoryUsed( ) const { return info.MemoryUsed( ); }
	int MemoryFree( ) const { return info.MemoryFree( ); }
	int SwapUsed( ) const { return info.SwapUsed( ); }
	int SwapFree( ) const { return info.SwapFree( ); }
	void InfoUpdate( ) { info.Update( ); }

protected:
	void MakeEnvGlobal( evalOpt &opt );
	void MakeArgvGlobal( evalOpt &opt, char** argv, int argc, int append_name=0 );
	void BuildSuspendList();
	IValue *Parse( evalOpt &, FILE* file, const char* filename = 0, int value_needed=0 );
	IValue *Parse( evalOpt &, const char file[], int value_needed=0 );
	IValue *Parse( evalOpt &, const char* strings[], int value_needed=0 );

	RemoteDaemon* CreateDaemon( const char* host );
	// Sets err to a non-zero value if an error occurred
	RemoteDaemon* OpenDaemonConnection( const char* host, int &err );
	void ActivateMonitor( char* monitor_client );
	void Rendezvous( const char* event_name, IValue* value );
	void ForwardEvent( const char* event_name, IValue* value );
	void RunQueue( int await_ended=0 );
	void RemoveSelectee( Channel* chan );

	void SetupSysValue( IValue * );

	void PushAwait( );
	await_type *PopAwait();

	// both of these used by multiple threads
	int *NewObjId( int );
	char *NewTaskId( int & );

	int xpid;
	int obj_cnt;

	char *name;
	char *interpreter_path;
	int verbose;
	unsigned int verbose_mask;
	int my_id;

	void SystemChanged( );
	unsigned int system_change_count;
	SystemInfo system;

	Sysinfo info;
	Agent* system_agent;

	Expr *script_expr;
	ScriptClient* script_client;
	int script_client_active;

	scope_list scopes;
	offset_list global_scopes;
	static Scope *stashed_scope;
	expr_list_stack back_refs;

	static fail_stack_stack *fail_stack;

	stack_list stack;
	const frame_list &frames() const { return *(stack[stack.length()-1]->frames()); }
	frame_list &frames() { return *(stack[stack.length()-1]->frames()); }
	const offset_list &global_frames() const { return *(stack[stack.length()-1]->offsets()); }
	offset_list &global_frames() { return *(stack[stack.length()-1]->offsets()); }

	ivalue_list global_frame;

	func_name_list func_names;

	int last_task_id;
	PDict(Task) ids_to_tasks;
	PDict(RemoteDaemon) daemons;
	Dict(int) suspend_list;	// which variables' tasks to suspend
	PQueue(Notification) notification_queue;

	//
	// handle "last" notifications for whenever statements, used with
	// LastNotification(), PushNote() and PopNote() above...
	//
	notification_list notes_inuse;

	Stmt* last_whenever_executed;
	RegexMatch regex_match;
	Stmt* stmts;
	PList(Stmt) registered_stmts;
	Dict(int) include_once;
	char *expanded_name;

	await_type *await( ) { return await_list[await_list.length()-1]; }
	awaittype_list await_list;
	await_type *last_await_info;

	IValue* last_reply;
	int stdin_selectee_removed;

	// Task that we interrupted processing because we came across
	// an "await"-ed upon event; if non-null, should be Empty()'d
	// next time we process events.
	Task* pending_task;

	Task* monitor_task;

	AcceptSocket* connection_socket;
	Selector* selector;
	const char* connection_host;
	char* connection_port;
	char* interpreter_tag;

	int num_active_processes;

	// Used to indicate that the current script client should be
	// started as a multi-threaded client.
	Client::ShareType multi_script;
	// Used to indicate that the sequencer is in the initialization
	// phase of startup.
	int doing_init;
	int script_created;

	// These three values are used in the process of initializing
	// "script" value. This was complicated by "multi-threaded"
	// clients.
	int argc_;
	char **argv_;
	IValue *sys_val;

	char *run_file;

	IValue *error_result;

	// Keeps track of the current sequencer...
	// Later this may have to be a stack...
	static Sequencer *cur_sequencer;
	static int hold_queue;

	//
	// handling for the current whenever stmt
	//
	PList(WheneverStmtCtor) cur_whenever;

	// Called from Sequencer::TopLevelReset()
	void toplevelreset();
	int doing_pager;

	EnvHolder env;

	// set when the system->exit event is posted
	int shutdown_posted;
	};

extern IValue *glish_parser( evalOpt &, Stmt *&stmt );

#endif /* sequencer_h */
