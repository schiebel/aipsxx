// $Id: Sequencer.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: Sequencer.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $")
#include "system.h"
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <unistd.h>
#include <setjmp.h>
#include <sys/param.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "Pager.h"
#include <pthread.h>

#if defined(_AIX)
// for bzero()
#include <strings.h>
#endif

#if HAVE_OSFCN_H
#include <osfcn.h>
#endif

#ifdef HAVE_LIMITS_H
#include <limits.h>
#endif
#ifdef HAVE_FLOAT_H
#include <float.h>
#endif

#include "sos/io.h"

#ifdef HAVE_SIGPROCMASK
#include <signal.h>
#endif

#ifdef HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif

#ifdef HAVE_CRT_EXTERNS_H
#include <crt_externs.h>
#endif

#ifndef MAXHOSTNAMELEN
#define MAXHOSTNAMELEN 64
#endif

extern "C" {
char* getenv( const char* );
int isatty( int fd );
int system( const char* string );
void nb_reset_term( int );
}

/* Used for recovery after a ^C */
extern jmp_buf glish_include_jmpbuf;
extern int glish_include_jmpbuf_set;

#if USENPD
#include "Npd/npd.h"
#endif
#include "Daemon.h"
#include "Glish/Reporter.h"
#include "Sequencer.h"
#include "Frame.h"
#include "BuiltIn.h"
#include "Task.h"
#include "LdAgent.h"
#include "input.h"
#include "Channel.h"
#include "Select.h"
#include "Socket.h"
#include "ports.h"
#include "version.h"
#include "change.h"

#if USE_EDITLINE
extern "C" {
	void finalize_readline_history( );
	void initialize_readline_history( const char * );
}
#endif

#define GLISH_RC_FILE ".glishrc"
#define GLISH_RC_FILE_PRE ".glishrc.pre"
#define GLISH_RC_FILE_POST ".glishrc.post"
#define GLISH_HISTORY_FILE ".glishlog"
#define RCDIR_VAR "GLISHROOT"
const char * const LD_PATH = "LD_LIBRARY_PATH";

// Time to wait until probing a remote daemon, in seconds.
#define PROBE_DELAY 6

// Interval between subsequent probes, in seconds.
#define PROBE_INTERVAL 5

extern int allwarn;
extern void init_regex();
extern void init_scanner();

// Keeps track of the current sequencer...
Sequencer *Sequencer::cur_sequencer = 0;
// Keeps track of if the queue is blocked...
int Sequencer::hold_queue = 0;
Scope *Sequencer::stashed_scope = 0;
fail_stack_stack *Sequencer::fail_stack = 0;

// This is used to indicate that final cleanup is ongoing. Currently
// this only affects the cleanup of WheneverStmts. Eventaully, these
// will be cleaned up properly, and this can be removed.
int shutting_glish_down = 0;

struct func_name_info {
	func_name_info( const char *n, unsigned short f, unsigned short l ) :
		name_(string_dup(n)), file_(f), line_(l) { }
	~func_name_info( ) { free_memory(name_); }
	const char *name( ) const { return name_; }
	unsigned short file( ) const { return file_; }
	unsigned short line( ) const { return line_; }
    private:
	char *name_;
	unsigned short file_;
	unsigned short line_;
};


await_type::await_type( await_type &o )
	{
	stmt_ = o.stmt_;
	except_ = o.except_;
	only_ = o.only_;
	dict_ = o.dict_;
	o.dict_ = 0;
	agent_ = o.agent_;
	name_ = o.name_;
	filled_value = o.filled_value;
	if ( filled_value ) Ref(filled_value);
	filled_agent = o.filled_agent;
	if ( filled_agent ) Ref(filled_agent);
	filled_name = o.filled_name ? string_dup(o.filled_name) : 0;
	}

void await_type::operator=( await_type &o )
	{
	stmt_ = o.stmt_;
	except_ = o.except_;
	only_ = o.only_;
	if ( dict_ ) delete_agent_dict( dict_ );
	dict_ = o.dict_;
	o.dict_ = 0;
	agent_ = o.agent_;
	name_ = o.name_;
	filled_value = o.filled_value;
	if ( filled_value ) Ref(filled_value);
	filled_agent = o.filled_agent;
	if ( filled_agent ) Ref(filled_agent);
	filled_name = o.filled_name ? string_dup(o.filled_name) : 0;
	}

void await_type::set( )
	{
	// await statement members
	stmt_ = except_ = 0;
	only_ = 0;
	if ( dict_ ) delete_agent_dict( dict_ );
	dict_ = 0;
	// request/reply members
	agent_ = 0;
	name_ = 0;
	Unref( filled_value );
        Unref( filled_agent );
        if ( filled_name )  free_memory( filled_name );
	}

void await_type::set( Stmt *s, Stmt *e, int o )
	{
	stmt_ = s;
	except_ = e;
	only_ = o;
	agent_ = 0;
	name_ = 0;
	filled_value = 0;
	filled_agent = 0;
	filled_name = 0;

	if ( dict_ ) delete_agent_dict( dict_ );

	dict_ = new agent_dict( ORDERED );
	event_dsg_list *el = ((AwaitStmt*)stmt_)->AwaitList();
	loop_over_list ( *el, X )
		{
		name_list &nl = (*el)[X]->EventNames();
		if ( nl.length() == 0 ) continue;
		Agent *await_agent = (*el)[X]->EventAgent( VAL_REF );

		if ( ! await_agent )
			continue;

		// if agent has bundled up events, make
		// sure they're flushed...
		await_agent->FlushEvents( );

		loop_over_list( nl, Y )
			{
			char *nme = nl[Y];
			agent_list *al = (*dict_)[nme];
			if ( ! al )
				{
				al = new agent_list;
				dict_->Insert(string_dup(nme),al);
				}

			al->append(await_agent);
			}

		(*el)[X]->EventAgentDone();
		}
	}

void await_type::set( Agent *a, const char *n )
	{
	agent_ = a;
	name_ = n;
	stmt_ = 0;
	except_ = 0;
	only_ = 0;
	if ( dict_ ) delete_agent_dict( dict_ );
	dict_ = 0;
	filled_value = 0;
	filled_agent = 0;
	filled_name = 0;
	}

int await_type::SetValue( Agent *agent_, const char *name_x, IValue *val, int force )
	{
	agent_list *al = 0;
	if ( filled_value || filled_name || filled_agent ) return 0;

	if ( ! force && dict() && ( !(al = (*dict())[name_x]) || !al->is_member(agent_) ) )
		return 0;

	filled_value = val;
	if ( filled_value ) Ref(filled_value);
	filled_agent = agent_;
	if ( filled_agent ) Ref(filled_agent);
	filled_name = name_x ? string_dup(name_x) : 0;
	return 1;
	}

// Used to flag changes in the system agent.
void system_change_function(IValue *, IValue *n)
	{
	Sequencer::CurSeq()->System().SetVal(n);
	}

static charptr *merge_chars( charptr *one, int onelen, charptr *two, int twolen )
	{
	if ( ! one || ! two || ! onelen || ! twolen ) return 0;

	charptr *ret = (charptr*) alloc_charptr( onelen+twolen );
	for (int i=0; i < onelen; ++i)
		ret[i] = one[i];
	for ( LOOPDECL i=0; i < twolen; ++i )
		ret[i+onelen] = two[i];
	free_memory(one);
	free_memory(two);
	return ret;
	}

static char **split_path( char *path, int &count )
	{
	count = 0;
	if ( ! path ) return 0;

	int i = 1;
	char *ptr = path;
	while ( *ptr ) { if ( *ptr++ == ':' ) i++; }

	char **ret = alloc_charptr( i );

	count = 0;
	char *cur = path;
	while ( i-- )
		{
		if ( i )
			{
			for ( ptr=cur; *ptr && *ptr != ':'; ++ptr );
			if ( *ptr == ':' )
				{
				*ptr = '\0';
				ret[count++] = string_dup(cur);
				*ptr++ = ':';
				cur = ptr;
				}
			else
				ret[count++] = string_dup(cur);
			}
		else
			ret[count++] = string_dup(cur);
		}

	return ret;
	}

static char *join_path( const char **path, int len, const char *var_name = 0 )
	{
	int count = len + 1;
	if ( ! path ) return 0;

	for ( int i = 0; i < len; ++i )
		count += strlen(path[i]);

	if ( var_name ) count += strlen(var_name) + 1;
	char *ret = alloc_char( count );
	if ( var_name ) sprintf( ret, "%s=", var_name );
	else ret[0] = '\0';

	for ( LOOPDECL i=0; i < len; ++i )
		{
		strcat( ret, path[i] );
		if ( i < len-1 ) strcat(ret, ":");
		}

	return ret;
	}

stack_type::stack_type( )
	{
	frames_ = new frame_list;
	flen = 0;
	offsets_ = new offset_list;
	olen = 0;
	delete_on_spot_ = 0;
	}

stack_type::stack_type( const stack_type &other, int clip, int delete_on_spot_arg )
	{
	frames_ = new frame_list;
	offsets_ = new offset_list;

#if defined(ENABLE_GC)
	// This allows the garbage collector to NIL out the frame list pointer
	// allowing it to collect cycles created when a record contains a function
	// whose stack references the record, e.g. :
	//
	//     func test() {
	//         pub := [=]
	//         pub.fun := func() { print 'hello' }
	//         return pub
	//     }
	//     root := test()
	//
	GC_register_disappearing_link((void**)&frames_);
#endif

	int len = clip && other.frame_len() >= 0 ? other.frame_len() : other.frames()->length();
	for ( int i = 0; i < len; i++ )
		{
		Frame *n = (*other.frames())[i];
		if (n) Ref(n);
		frames_->append(n);
		}
	flen = len;

	len = clip && other.offset_len() >= 0 ? other.offset_len() : other.offsets()->length();
	for ( LOOPDECL i = 0; i < len; i++ )
		offsets_->append((*other.offsets())[i]);
	olen = len;

	delete_on_spot_ = delete_on_spot_arg ? &other : 0;
	}

stack_type::~stack_type( )
	{
	if ( frames_ && ! delete_on_spot_ )
		{
		for ( int i=frames_->length()-1;i >= 0; i-- )
			{
			Frame *cur = frames_->remove_nth(i);
			Unref(cur);
			}
		}

	Unref( frames_ );
	Unref( offsets_ );
	}

// A special type of Client used for script clients.  It overrides
// FD_Change() to create or delete ScriptSelectee's as needed.
class ScriptClient : public Client {
public:
	ScriptClient( int& argc, char** argv, Client::ShareType multi = Client::NONSHARED,
		      PersistType persist = Client::TRANSIENT, const char *script_file = 0 );

	// Inform the ScriptClient as to which selector and agent
	// it should use for getting and propagating events.
	void SetInterface( Selector* selector, Agent* agent );

	// Creates Selectees for each of the event sources if this
	// hasn't already been done. This can only be called after
	// SetInterface() has been called.
	void AddEventSources( );

	~ScriptClient();

protected:
	void FD_Change( int fd, int add_flag );

	Selector* selector;
	Agent* agent;
	name_list event_src_list;
	};

// A Selectee corresponding to input for a Glish client.
class ClientSelectee : public Selectee {
    public:
	ClientSelectee( Sequencer* s, Task* t );
	int NotifyOfSelection();

    protected:
	Sequencer* sequencer;
	Task* task;
	};


// A Selectee used only to intercept the initial "established" event
// generated by a local Glish client.  Because we communicate with these
// clients using pipes instead of sockets, we can't use the AcceptSelectee
// (see below) to recognize when they're connecting.
class LocalClientSelectee : public Selectee {
    public:
	LocalClientSelectee( Sequencer* s, Channel* c );
	int NotifyOfSelection();

    protected:
	Sequencer* sequencer;
	Channel* chan;
	};

// This selectee is used to continue sending an event which was suspended
// for some reason (likely the result of the pipe filling up).
class SendSelectee : public Selectee {
    public:
	SendSelectee( Selector *s, sos_status *ss_, Selectee *old_ = 0 );
	int NotifyOfSelection();

    protected:
	Selector *selector;
	Selectee *old;
	sos_status *ss;
	};


// A Selectee corresponding to a new request of a client to connect
// to the sequencer.
class AcceptSelectee : public Selectee {
    public:
	AcceptSelectee( Sequencer* s, Socket* conn_socket );
	int NotifyOfSelection();

    protected:
	Sequencer* sequencer;
	Socket* connection_socket;
	};


// A Selectee corresponding to a Glish script's own client.
class ScriptSelectee : public Selectee {
public:
	ScriptSelectee( ScriptClient* client, Agent* agent, int conn_socket );
	int NotifyOfSelection();

protected:
	ScriptClient* script_client;
	Agent* script_agent;
	int connection_socket;
	};


// A Selectee for detecting user input.
class UserInputSelectee : public Selectee {
public:
	UserInputSelectee( int user_fd ) : Selectee( user_fd )	{ }

	// Indicate user input available by signalling to end the
	// select.
	int NotifyOfSelection()	{ return 1; }
	};


class PagerSelectee : public Selectee {
public:
	PagerSelectee( int user_fd, Sequencer *s ) : Selectee( user_fd ),
						     seq(s) { }
	int NotifyOfSelection();
protected:
	Sequencer *seq;
	};

// A Selectee for detecting Glish daemon activity.
class DaemonSelectee : public Selectee {
public:
	DaemonSelectee( RemoteDaemon* daemon, Selector* sel, Sequencer* s );
	~DaemonSelectee();

	int NotifyOfSelection();

protected:
	RemoteDaemon* daemon;
	Selector* selector;
	Sequencer* sequencer;
	};


// A SelectTimer for handling glishd probes.
class ProbeTimer : public SelectTimer {
public:
	ProbeTimer( PDict(RemoteDaemon)* daemons, Sequencer* s );
	void UpdateInterval( );

protected:
	int DoExpiration();
	double probe_interval;

	PDict(RemoteDaemon)* daemons;
	Sequencer* sequencer;
	};


// A special type of Agent used for script clients; when it receives
// an event, it propagates it via the ScriptClient object.
class ScriptAgent : public Agent {
public:
	ScriptAgent( Sequencer* s, Client* c ) : Agent(s)	{ client = c; }

	IValue* SendEvent( const char* event_name, parameter_list* args,
			int /* is_request */, u_long /* flags */, Expr *from_subsequence=0 )
		{
		IValue* event_val = BuildEventValue( args, 1 );
		client->PostEvent( event_name, event_val, client->LastContext() );
		Unref( event_val );
		return 0;
		}

	~ScriptAgent() { delete client; }

protected:
	Client* client;
	};


Scope::~Scope()
	{
	IterCookie* c = InitForIteration();

	Expr* member;
	const char* key;
	while ( (member = NextEntry( key, c )) )
		Unref( member );

	c = global_refs.InitForIteration();
	char * val;
	while ( (val = global_refs.NextEntry( key, c )) )
		free_memory( val );
	}


void Scope::MarkGlobalRef(const char *c)
	{
	if ( ! WasGlobalRef( c ) )
		{
		char *str = string_dup(c);
		global_refs.Insert( str, str );
		}
	}

void Scope::ClearGlobalRef(const char *c)
	{
	char *v = global_refs.Remove(c);
	free_memory( v );
	}

#define LOG_CLEANUP_ONE(VAR)						\
	{								\
	if ( VAR##_file ) { fclose( VAR##_file ); VAR##_file = 0; }	\
	if ( VAR##_val )  { Unref( VAR##_val );	VAR##_val = 0; }	\
	if ( VAR##_name ) { free_memory( VAR##_name ); VAR##_name = 0; }\
	}

SystemInfo::~SystemInfo()
	{
	if ( val ) Unref( val );
	LOG_CLEANUP_ONE(log)
	LOG_CLEANUP_ONE(ilog)
	LOG_CLEANUP_ONE(olog)
	}

void SystemInfo::SetVal(IValue *v)
	{
	if ( val ) Unref( val );
	val=v;
	if ( val ) Ref(val);
	update = ~((unsigned int) 0);
	if ( sequencer ) sequencer->SystemChanged( );
	}

const char *SystemInfo::prefix_buf(const char *prefix, const char *buf)
	{
	static unsigned int size = 1024;
	static char *outbuf = alloc_char( size );

	if ( ! prefix || ! buf )
		return buf;

	int nlcount = 0;
	int charcount = 0;
	char *ptr = 0;
	for (ptr = (char*)buf; *ptr; charcount++)
		if ( *ptr++ == '\n' ) ++nlcount;

	unsigned int outsize = charcount + (nlcount + 1) * strlen(prefix) + 3;
	if ( outsize > size )
		{
		while ( outsize > size ) size *= 2;
		outbuf = realloc_char( outbuf, size );
		}

	char *pp = 0;
	char *optr = outbuf;

	for (pp=(char*)prefix; *pp; pp++)
		*optr++ = *pp;

	for (ptr = (char*)buf; *ptr; ptr++)
		{
		*optr++ = *ptr;
		if ( *ptr == '\n' )
			for (pp=(char*)prefix; *pp; pp++)
				*optr++ = *pp;
		}

	if ( *optr != '\n' ) *optr++ = '\n';
	else optr++;
	*optr = '\0';

	return outbuf;
	}


void SystemInfo::DoLog( int input, const Value *v )
	{
	char* desc = v->StringVal( ' ', v->PrintLimit() , 1 );
	DoLog( input, desc );
	free_memory( desc );
	}

void SystemInfo::DoLog( int input, const char *orig_buf, int len )
	{
	int done = 0;
	const char *buf = orig_buf;

	if ( ILOGX(update) || OLOGX(update) )
		update_output( );

#define DOLOG_ACTION(VAR,FIX_BUF)						\
	if ( VAR##_file )							\
		{								\
		FIX_BUF								\
		write(fileno(VAR##_file), buf, len >= 0 ? len : strlen(buf));	\
		done = 1;							\
		}								\
	else if ( VAR##_val && VAR##_val->Deref()->Type() == TYPE_FUNC && VAR##_val->Length() >= 1 ) \
		{								\
		parameter_list param;						\
		FIX_BUF								\
		ActualParameter *p = new ActualParameter( VAL_VAL, new ConstExpr( new IValue( buf ) ) ); \
		param.append( p );						\
		Func *func = ((IValue*)VAR##_val->Deref())->FuncPtr()[0];	\
		evalOpt opt(evalOpt::COPY);					\
		IValue *ret = func->Call( opt, &param );			\
		done = 1;							\
		if ( ret && ret->Type() == TYPE_FAIL )				\
			{							\
			glish_error->Report("in trace function (disconnecting):"); \
			ret->Describe( glish_error->Stream(), ioOpt(ioOpt::SHORT()) );\
			glish_error->Stream() << endl;				\
			Unref(VAR##_val);					\
			VAR##_val = 0;						\
			done = 0;						\
			}							\
		Unref( ret );							\
		Unref( p );							\
		}								\
	else if ( VAR##_val && ((IValue*)VAR##_val->Deref())->IsAgentRecord() )	\
		{								\
		Agent *agent = ((IValue*)VAR##_val->Deref())->AgentVal();	\
		FIX_BUF								\
		IValue *v = new IValue( buf );					\
		agent->SendSingleValueEvent( "append", v, 0 );			\
		done = 1;							\
		Unref( v );							\
		}
#define DOLOG_FIXBUF buf = prefix_buf("#",buf);

	DOLOG_ACTION(log, if (!input) DOLOG_FIXBUF )
	if ( ! done )
		if ( input )
			{
			DOLOG_ACTION(ilog,)
			}
		else
			{
			DOLOG_ACTION(olog,DOLOG_FIXBUF)
			}
	}

void SystemInfo::AbortOccurred()
	{
	if ( log_file ) fclose(log_file);
	if ( ilog_file ) fclose(ilog_file);
	if ( olog_file ) fclose(olog_file);
	}

void SystemInfo::update_output( )
	{
	const IValue *v1;
	const IValue *v2;
	const IValue *v3;

	trace = 0;
	log = 0;
	if ( val && val->Type() == TYPE_RECORD &&
	     val->HasRecordElement( "output" ) &&
	     (v1 = (const IValue*)(val->ExistingRecordElement( "output" ))) &&
	     v1 != false_value && v1->Type() == TYPE_RECORD )
		{
		if ( v1->HasRecordElement( "trace" ) &&
		     (v2 = (const IValue*)(v1->ExistingRecordElement("trace"))) &&
		     v2 != false_value && v2->Type() == TYPE_BOOL &&
		     v2->BoolVal() == glish_true )
			trace = 1;

		pager_exec = 0;
		pager_exec_len = 0;

		if ( v1->HasRecordElement( "pager" ) &&
		     (v2 = (const IValue*)(v1->ExistingRecordElement("pager"))) &&
		     v2 != false_value && v2->Type() == TYPE_RECORD )
			{
			if ( v2->HasRecordElement( "exec" ) &&
			     (v3 = (const IValue*)(v2->ExistingRecordElement("exec"))) &&
			     v3 != false_value && v3->Type() == TYPE_STRING )
				{
				pager_exec = v3->StringPtr(0);
				pager_exec_len = v3->Length();
				}

			if ( v2->HasRecordElement( "limit" ) &&
			     (v3 = (const IValue*)(v2->ExistingRecordElement("limit"))) &&
			     v3 != false_value && v3->IsNumeric() )
				pager_limit = v3->IntVal();
			}


#define UPDATE_LOG_ACTION(VAR, EXTRA_CLEANUP)				\
if ( v1->HasRecordElement( #VAR ) &&					\
     (v2 = (const IValue*)(v1->ExistingRecordElement( #VAR ))) &&	\
     v2 != false_value )						\
	{								\
	if ( v2->Deref()->Type() == TYPE_STRING )			\
		{							\
		VAR = 1;						\
		char *nf = v2->StringVal();				\
		if ( VAR##_name )					\
			if ( strcmp(nf,VAR##_name) )			\
				{					\
				free_memory( VAR##_name );		\
				VAR##_name = nf;			\
				}					\
			else						\
				free_memory( nf );			\
		else							\
			VAR##_name = nf;				\
									\
		if ( nf == VAR##_name )					\
			{						\
			if ( VAR##_file ) fclose( VAR##_file );		\
			if ( ! access(VAR##_name, F_OK) )		\
				VAR##_file = fopen(VAR##_name, "a");	\
			else						\
				{					\
				VAR##_file = fopen(VAR##_name, "a");	\
				if ( VAR##_file ) chmod(VAR##_name, S_IRUSR | S_IWUSR); \
				}					\
			}						\
									\
		if ( VAR##_val )					\
			{						\
			Unref(VAR##_val);				\
			VAR##_val = 0;					\
			}						\
		}							\
	else if ( v2->Deref()->Type() == TYPE_FUNC ||			\
		  ((IValue*)v2->Deref())->IsAgentRecord() ) 		\
		{							\
		VAR = 1;						\
		if ( VAR##_val != v2 )					\
			{						\
			Unref(VAR##_val);				\
			VAR##_val = (IValue*) v2;			\
			if (VAR##_val) Ref(VAR##_val);			\
			}						\
		if ( VAR##_name )					\
			{						\
			free_memory( VAR##_name );			\
			VAR##_name = 0;					\
			}						\
		if ( VAR##_file )					\
			{						\
			fclose(VAR##_file);				\
			VAR##_file = 0;					\
			}						\
		}							\
	else								\
		LOG_CLEANUP_ONE(VAR)					\
									\
	EXTRA_CLEANUP							\
									\
	}								\
else									\
	LOG_CLEANUP_ONE(VAR)

#define UPDATE_LOG_CLEANUP			\
	if ( log_file || log_val )		\
		{				\
		LOG_CLEANUP_ONE(ilog)		\
		LOG_CLEANUP_ONE(olog)		\
		}

		UPDATE_LOG_ACTION(log, UPDATE_LOG_CLEANUP)
		if ( ! log_file && ! log_val )
			{
			UPDATE_LOG_ACTION(ilog,)
			UPDATE_LOG_ACTION(olog,)
			}
		}

	update &= ~TRACE();
	update &= ~ILOGX();
	update &= ~OLOGX();
	}

void SystemInfo::update_print( )
	{
	const IValue *v1;
	const IValue *v2;
	int tmp;

	printlimit = 0;
	printprecision = -1;
	if ( val && val->Type() == TYPE_RECORD &&
	     val->HasRecordElement( "print" ) &&
	     (v1 = (IValue*) val->ExistingRecordElement( "print" )) &&
	     v1 != false_value && v1->Type() == TYPE_RECORD )
		{
		if ( v1->HasRecordElement( "limit" ) &&
		     (v2 = (IValue*) v1->ExistingRecordElement("limit")) &&
		     v2 != false_value && v2->IsNumeric() &&
		     (tmp = v2->IntVal()) > 0 )
			printlimit = tmp;

		if ( v1->HasRecordElement( "precision" ) &&
		     (v2 = (IValue*) v1->ExistingRecordElement("precision")) &&
		     v2 != false_value && v2->IsNumeric() &&
		     (tmp = v2->IntVal()) >= 0)
			printprecision = tmp;
		}

	update &= ~PRINTLIMIT();
	update &= ~PRINTPRECISION();
	}

void SystemInfo::update_stacklimit( )
	{
	const IValue *v1;
	const IValue *v2;
	int tmp;

	stacklimit = 0;
	if ( val && val->Type() == TYPE_RECORD &&
	     val->HasRecordElement( "limits" ) &&
	     (v1 = (IValue*) val->ExistingRecordElement( "limits" )) &&
	     v1 != false_value && v1->Type() == TYPE_RECORD )
		{
		if ( v1->HasRecordElement( "stack" ) &&
		     (v2 = (IValue*) v1->ExistingRecordElement("stack")) &&
		     v2 != false_value && v2->IsNumeric() &&
		     (tmp = v2->IntVal()) > 0 )
			stacklimit = tmp;
		}

	update &= ~STACKLIMIT();
	}

void SystemInfo::update_path( )
	{
	const IValue *v1;
	const IValue *v2;

	include = 0;
	includelen = 0;
	keydir = 0;
	binpath = 0;
	ldpath = 0;
	if ( val && val->Type() == TYPE_RECORD &&
	     val->HasRecordElement( "path" ) &&
	     (v1 = (const IValue*)(val->ExistingRecordElement( "path" ))) &&
	     v1 != false_value && v1->Type() == TYPE_RECORD )
		{
		if ( v1->HasRecordElement( "include" ) &&
		     (v2 = (const IValue*)(v1->ExistingRecordElement("include"))) &&
		     v2 != false_value && v2->Type() == TYPE_STRING &&
		     v2->Length() )
			{
			include = v2->StringPtr(0);
			includelen = v2->Length();
			}

		if ( v1->HasRecordElement( "key" ) &&
		     (v2 = (const IValue*)(v1->ExistingRecordElement("key"))) &&
		     v2 != false_value && v2->Type() == TYPE_STRING &&
		     v2->Length() )
			keydir = v2->StringPtr(0)[0];

		if ( v1->HasRecordElement( "bin" ) &&
		     (v2 = (const IValue*)(v1->ExistingRecordElement("bin"))) &&
		     v2 != false_value &&
		     ( v2->Type() == TYPE_STRING || v2->Type() == TYPE_RECORD ) &&
		     v2->Length() )
			binpath = v2;

		if ( v1->HasRecordElement( "lib" ) &&
		     (v2 = (const IValue*)(v1->ExistingRecordElement("lib"))) &&
		     v2 != false_value &&
		     ( v2->Type() == TYPE_STRING || v2->Type() == TYPE_RECORD ) &&
		     v2->Length() )
			{
			ldpath = v2;
			set_load_path( (Value*) ldpath );
			}
		}

	update &= ~PATH();
	}

void SystemInfo::update_client( )
	{
	const IValue *v1;
	const IValue *v2;
	double tmp;

	client_ping = PROBE_INTERVAL;
	if ( val && val->Type() == TYPE_RECORD &&
	     val->HasRecordElement( "client" ) &&
	     (v1 = (IValue*) val->ExistingRecordElement( "client" )) &&
	     v1 != false_value && v1->Type() == TYPE_RECORD )
		{
		if ( v1->HasRecordElement( "ping" ) &&
		     (v2 = (IValue*) v1->ExistingRecordElement("ping")) &&
		     v2 != false_value && v2->IsNumeric() &&
		     (tmp = v2->DoubleVal()) > 0 )
			client_ping = tmp;
		}

	update &= ~CLIENT();
	}

void Sequencer::SystemChanged( )
	{
	system_change_count += 1;
	}

void Sequencer::UpdateLocalPath( )
	{
	static unsigned int count = 0;
	if ( count != system_change_count )
		{
		IValue *path = (IValue*) system.BinPath();
		if ( path && (path = (IValue*) path->Deref()) )
			{
			const IValue *v1;
			if ( path && path->Type() == TYPE_STRING )
				set_executable_path( path->StringPtr(0), path->Length() );
			else if ( path && path->Type() == TYPE_RECORD )
				{
				if ( path->HasRecordElement( "localhost" ) &&
				     (v1 = (IValue*) path->ExistingRecordElement("localhost")) &&
				     v1 != false_value && v1->Type() == TYPE_STRING )
					set_executable_path( v1->StringPtr(0), v1->Length() );
				else if ( path->HasRecordElement( connection_host ) &&
					  (v1 = (IValue*) path->ExistingRecordElement( connection_host )) &&
					   v1 != false_value && v1->Type() == TYPE_STRING )
					set_executable_path( v1->StringPtr(0), v1->Length() );
				else if ( path->HasRecordElement( "default" ) &&
					  (v1 = (IValue*) path->ExistingRecordElement( "default" )) &&
					   v1 != false_value && v1->Type() == TYPE_STRING )
					set_executable_path( v1->StringPtr(0), v1->Length() );
				}
			}

		path = (IValue*) system.LdPath();
		if ( path && (path = (IValue*) path->Deref()) )
			{
			const IValue *v1;
			if ( path && path->Type() == TYPE_STRING )
				env.put( LD_PATH, join_path(path->StringPtr(0),path->Length(),LD_PATH) );
			else if ( path && path->Type() == TYPE_RECORD )
				{
				if ( path->HasRecordElement( "localhost" ) &&
				     (v1 = (IValue*) path->ExistingRecordElement("localhost")) &&
				     v1 != false_value && v1->Type() == TYPE_STRING )
					env.put( LD_PATH, join_path(v1->StringPtr(0),v1->Length(),LD_PATH) );
				else if ( path->HasRecordElement( connection_host ) &&
					  (v1 = (IValue*) path->ExistingRecordElement( connection_host )) &&
					   v1 != false_value && v1->Type() == TYPE_STRING )
					env.put( LD_PATH, join_path(v1->StringPtr(0),v1->Length(),LD_PATH) );
				else if ( path->HasRecordElement( "default" ) &&
					  (v1 = (IValue*) path->ExistingRecordElement( "default" )) &&
					   v1 != false_value && v1->Type() == TYPE_STRING )
					env.put( LD_PATH, join_path(v1->StringPtr(0),v1->Length(),LD_PATH) );
				}
			}

		}
	count = system_change_count;
	}

void Sequencer::UpdateRemotePath( )
	{
	static unsigned int count = 0;
	static int oldlen = 0;

	if ( ! daemons.Length() ) return;
	if ( count != system_change_count || daemons.Length() != oldlen )
		{
		IValue *path = (IValue*) system.BinPath();
		if ( path  && (path = (IValue*) path->Deref()) )
			{
			if ( path && path->Type() == TYPE_STRING )
				{
				const char *key = 0;
				RemoteDaemon *daemon = 0;
				IterCookie* c = daemons.InitForIteration();
				while ( (daemon = daemons.NextEntry( key, c )) )
					daemon->UpdateBinPath( path );
				}
			else if ( path && path->Type() == TYPE_RECORD )
				{
				const IValue *dflt = 0;
				if ( path->HasRecordElement( "default" ) &&
				     (dflt = (IValue*) path->ExistingRecordElement( "default" )) )
					if ( dflt == false_value && dflt->Type() != TYPE_STRING )
						dflt = 0;

				const IValue *v1;
				const char *key = 0;
				RemoteDaemon *daemon = 0;
				IterCookie* c = daemons.InitForIteration();
				while ( (daemon = daemons.NextEntry( key, c )) )
					{
					if ( path->HasRecordElement( daemon->Host() ) &&
					     (v1 = (IValue*) path->ExistingRecordElement( daemon->Host() )) &&
					     v1 != false_value && v1->Type() == TYPE_STRING )
						daemon->UpdateBinPath( v1 );
					else if ( dflt )
						daemon->UpdateBinPath( dflt );
					}
				}
			}

		char *string = 0;
		path = (IValue*) system.LdPath();
		if ( path  && (path = (IValue*) path->Deref()) )
			{
			if ( path && path->Type() == TYPE_STRING )
				{
				string = join_path(path->StringPtr(0),path->Length(),LD_PATH);
				const char *key = 0;
				RemoteDaemon *daemon = 0;
				IterCookie* c = daemons.InitForIteration();
				while ( (daemon = daemons.NextEntry( key, c )) )
					daemon->UpdateLdPath( string );
				}
			else if ( path && path->Type() == TYPE_RECORD )
				{
				const IValue *dflt = 0;
				char *dflt_str = 0;
				if ( path->HasRecordElement( "default" ) &&
				     (dflt = (IValue*) path->ExistingRecordElement( "default" )) )
					{
					if ( dflt == false_value || dflt->Type() != TYPE_STRING )
						dflt = 0;
					else
						dflt_str = join_path(dflt->StringPtr(0),dflt->Length(),LD_PATH);
					}

				const IValue *v1;
				const char *key = 0;
				RemoteDaemon *daemon = 0;
				IterCookie* c = daemons.InitForIteration();
				while ( (daemon = daemons.NextEntry( key, c )) )
					{
					if ( path->HasRecordElement( daemon->Host() ) &&
					     (v1 = (IValue*) path->ExistingRecordElement( daemon->Host() )) &&
					     v1 != false_value && v1->Type() == TYPE_STRING )
						{
						string = join_path(v1->StringPtr(0),v1->Length(),LD_PATH);
						daemon->UpdateLdPath( string );
						free_memory( string );
						}
					else if ( dflt )
						daemon->UpdateLdPath( dflt_str );
					}

				if ( dflt_str ) free_memory( dflt_str );
				}
			}
		}

	oldlen = daemons.Length();
	count = system_change_count;
	}

void Sequencer::UpdatePath( const char *host )
	{
	IValue *v1 = 0;

	const char *daemon_host = ! host || ! strcmp(host,ConnectionHost()) ?
				"localhost" : host;
	host = ! host || ! strcmp("localhost",host) ? ConnectionHost() : host;

	RemoteDaemon* d;
	if ( (d = daemons[daemon_host]) )
		{
		IValue *path = (IValue*) system.BinPath();
		if ( path  && (path = (IValue*) path->Deref()) )
			{
			if ( path && path->Type() == TYPE_RECORD &&
			     path->HasRecordElement( host ) &&
			     (v1 = (IValue*) path->ExistingRecordElement( host )) &&
			     v1 != false_value && v1->Type() == TYPE_STRING )
				d->UpdateBinPath(v1);
			}

		path = (IValue*) system.LdPath();
		if ( path  && (path = (IValue*) path->Deref()) )
			{
			if ( path && path->Type() == TYPE_RECORD &&
			     path->HasRecordElement( host ) &&
			     (v1 = (IValue*) path->ExistingRecordElement( host )) &&
			     v1 != false_value && v1->Type() == TYPE_STRING )
				{
				char *string = join_path(v1->StringPtr(0),v1->Length(),LD_PATH);
				d->UpdateLdPath(string);
				free_memory( string );
				}
			}
		}
	}

void Sequencer::TopLevelReset()
	{
	if ( cur_sequencer )
		cur_sequencer->toplevelreset();
	}

void Sequencer::toplevelreset()
	{
	if ( stdin_selectee_removed && isatty( fileno( stdin ) ) &&
			! selector->FindSelectee( fileno( stdin ) ) )
		{
		selector->AddSelectee( new UserInputSelectee( fileno( stdin ) ) );
		stdin_selectee_removed = 0;
		}

	for ( int len = await_list.length(); len > 0; len-- )
		{
		await_type *last = await_list.remove_nth(len-1);
		if ( last ) delete last;
		}
	}

void Sequencer::InitScriptClient( evalOpt &opt )
	{
	// Create "script" global.
	script_client = new ScriptClient( argc_, argv_, MultiClientScript(), Client::TRANSIENT, run_file );

	if ( script_client->HasInterpreterConnection() )
		{
		// Set up script agent to deal with incoming and outgoing
		// events.
		ScriptAgent* script_agent =
			new ScriptAgent( this, script_client );
		script_client->SetInterface( selector, script_agent );
		script_expr->Assign( opt, script_agent->AgentRecord() );

		IValue *val = new IValue( glish_true );
		sys_val->SetField( "is_script_client", val );
		Unref(val);

		// Don't print messages and dump core when we receive
		// a SIGTERM, because it means our interpreter has exited.
		(void) install_signal_handler( SIGTERM, ValCtor::cleanup );

		// Include ourselves as an active process; otherwise
		// we'll exit once our child processes are gone.
		++num_active_processes;

		// Used to determine if "Sequencer::~Sequencer()" should
		// specifically delete "script_client".
		script_client_active = 1;
		}

	else
		{
		script_expr->Assign( opt, new IValue( glish_false ) );
		IValue *val = new IValue( glish_false );
		sys_val->SetField( "is_script_client", val );
		Unref(val);
		}

	ScriptCreated( 1 );
	}

void Sequencer::SetupSysValue( IValue *sys_value )
	{
	IValue *host = new IValue(local_host_name());
	sys_value->SetField( "host", host );
	Unref(host);

	char change[24];
	sprintf( change, "%d", GLISH_CHANGE );
	charptr *verv = (charptr*) alloc_charptr( 2 );
	verv[0] = string_dup(GLISH_VERSION);
	verv[1] = string_dup(change);
	IValue *ver = new IValue( verv, 2 );
	sys_value->SetField( "version", ver );
	Unref(ver);

	IValue *pid = new IValue( xpid );
	sys_value->SetField( "pid", pid );
	Unref(pid);

	IValue *ppid = new IValue( (int) getppid() );
	sys_value->SetField( "ppid", ppid );
	Unref(ppid);

	recordptr path = create_record_dict();
#if USENPD
	path->Insert( string_dup("key"), new IValue(get_key_directory()) );
#endif
	char *envpath = getenv( "PATH" );
	if ( envpath )
		{
		int len = 0;
		charptr *binpath = (charptr*) split_path(envpath,len);
		if ( binpath && len )
			{
			recordptr bin = create_record_dict( );
			bin->Insert( string_dup(local_host_name()), new IValue(binpath,len) );
			path->Insert( string_dup("bin"), new IValue( bin ) );
			}
		}

	envpath = getenv( LD_PATH );
	char libdir[] = LIBDIR;
	if ( envpath )
		{
		int ldlen = 0;
		charptr *ldpath = (charptr*) split_path(envpath,ldlen);
		int lblen = 0;
		charptr *lbpath = (charptr*) split_path(libdir,lblen);
		int len = ldlen + lblen;
		if ( lblen && ldlen )
			ldpath = merge_chars(ldpath,ldlen,lbpath,lblen);
		if ( ldpath && len )
			{
			recordptr ld = create_record_dict( );
			IValue *pathval = new IValue(ldpath,len);
			ld->Insert( string_dup(local_host_name()), pathval );
			set_load_path( (Value*) pathval );
			path->Insert( string_dup("lib"), new IValue( ld ) );
			}
		}
	else
		{
		int len = 0;
		charptr *lbpath = (charptr*) split_path(libdir,len);
		if ( lbpath && len )
			{
			recordptr ld = create_record_dict( );
			IValue *pathval = new IValue(lbpath,len);
			ld->Insert( string_dup(local_host_name()), pathval );
			set_load_path( (Value*) pathval );
			path->Insert( string_dup("lib"), new IValue( ld ) );
			}
		}

	char **inc = alloc_charptr( 2 );
	inc[0] = string_dup(".");
	inc[1] = string_dup(SCRIPTDIR);
	path->Insert( string_dup("include"), new IValue( (charptr*) inc, 2 ) );

	IValue * path_val = new IValue( path );
	sys_value->SetField( "path", path_val );
	Unref(path_val);

	recordptr max = create_record_dict();
	max->Insert( string_dup("integer"), new IValue( (int) INT_MAX ) );
	max->Insert( string_dup("byte"), new IValue( (int) UCHAR_MAX ) );
	max->Insert( string_dup("short"), new IValue( (int) SHRT_MAX ) );
	max->Insert( string_dup("float"), new IValue( (float) FLT_MAX ) );
	max->Insert( string_dup("double"), new IValue( (double) DBL_MAX ) );

	recordptr min = create_record_dict();
	min->Insert( string_dup("integer"), new IValue( (int) INT_MIN ) );
	min->Insert( string_dup("byte"), new IValue( (int) 0 ) );
	min->Insert( string_dup("short"), new IValue( (int) SHRT_MIN ) );
	min->Insert( string_dup("float"), new IValue( (float) FLT_MIN ) );
	min->Insert( string_dup("double"), new IValue( (double) DBL_MIN ) );

	recordptr limits = create_record_dict();
	limits->Insert( string_dup("max"), new IValue( max ) );
	limits->Insert( string_dup("min"), new IValue( min ) );
	limits->Insert( string_dup("stack"), new IValue( 5000 ) );

	IValue *limits_val = new IValue( limits );
	sys_value->SetField( "limits", limits_val );
	Unref(limits_val);

	IValue *cpus_val = new IValue( info.NumCpus( ) );
	sys_value->SetField( "cpus", cpus_val );
	Unref( cpus_val );

	recordptr output = create_record_dict();
	recordptr pager = create_record_dict();
	char *envpager = getenv( "PAGER" );
	pager->Insert( string_dup("exec"), new IValue( envpager ? envpager : "more" ) );
	pager->Insert( string_dup("limit"), new IValue( 24 ) );
	output->Insert( string_dup("pager"), new IValue( pager ) );
	IValue *output_val = new IValue( output );

	sys_value->SetField( "output", output_val );
	Unref(output_val);

	IValue *nogui = new IValue( glish_false );
	sys_value->SetField( "nogui", nogui );
	Unref(nogui);
	}

char *Sequencer::NewTaskId( int &idi )
	{
	static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

	pthread_mutex_lock( &lock );
	idi = ++last_task_id;
	pthread_mutex_unlock( &lock );

	char buf[128];
	sprintf( buf, "<task:%d>", idi );
	char* new_ID = string_dup( buf );

	return new_ID;
	}

int *Sequencer::NewObjId( int TaskId )
	{
	int *ret = alloc_int(3);
	static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

	pthread_mutex_lock( &lock );
	ret[0] = xpid;
	ret[1] = TaskId;
	ret[2] = ++obj_cnt;
	pthread_mutex_unlock( &lock );

	return ret;
	}

Sequencer::Sequencer( int& argc, char**& argv ) : verbose_mask(0), system_change_count(1),
				system(this), script_client(0), script_client_active(0),
				expanded_name(0), run_file(0), doing_pager(0)
	{
	evalOpt opt;

#if defined(ENABLE_GC)
	/* We try to make sure that we allocate at 	*/
	/* least N/GC_free_space_divisor bytes between	*/
	/* collections, where N is the heap size plus	*/
	/* a rough estimate of the root set size.	*/
	GC_free_space_divisor = 2;
#endif

	cur_sequencer = this;

	multi_script = Client::NONSHARED;
	script_created = 0;
	shutdown_posted = 0;
	doing_init = 1;
	argc_ = argc;
	argv_ = argv;

	obj_cnt = 0;
	xpid = (int) getpid();

	error_result = 0;

	agents = new agent_list;
	glish_current_subsequence = new expr_list;

	glish_files = new name_list;
	glish_files->append(0);

	init_interp_reporters(this);
	init_ivalues();
	init_regex();
	init_scanner( );

	char glish_rc_filename[2048];
	const char *glish_rc_dir = 0;

#if USE_EDITLINE
	if ( (glish_rc_dir = getenv( "HOME" )) )
		{
		sprintf( glish_rc_filename, "%s/%s",
			 glish_rc_dir, GLISH_HISTORY_FILE );
		initialize_readline_history( glish_rc_filename );
		}
#endif

	// Create the global scope.
	PushScope( GLOBAL_SCOPE );
	// Setup stack
	stack.append(new stack_type);

	create_built_ins( this, argv[0] );

	null_stmt = new NullStmt;

	stmts = null_stmt;
	last_task_id = my_id = 1;

	pending_task = 0;
	stdin_selectee_removed = 0;

	maximize_num_fds();

	// avoid SIGPIPE's - they can occur if a client's termination
	// is not detected prior to sending an event to the client
#ifdef HAVE_SIGPROCMASK
	sigset_t sig_mask;
	sigemptyset( &sig_mask );
	sigaddset( &sig_mask, SIGPIPE );
	sigprocmask( SIG_BLOCK, &sig_mask, 0 );
#else
	sigblock( sigmask( SIGPIPE ) );
#endif

	connection_socket = new AcceptSocket( 0, INTERPRETER_DEFAULT_PORT );
	mark_close_on_exec( connection_socket->FD() );

	selector = new Selector;

	selector->AddSelectee( new AcceptSelectee( this, connection_socket ) );
	ProbeTimer *daemon_probe = new ProbeTimer( &daemons, this );
	selector->AddTimer( daemon_probe );

	connection_host = local_host_name();
	connection_port = alloc_char(32);
	sprintf( connection_port, "%d", connection_socket->Port() );

	static const char tag_fmt[] = "*tag-%s.%d*";
	int n = strlen( tag_fmt ) + strlen( connection_host ) + /* slop */ 32;

	interpreter_tag = alloc_char(n);
	sprintf( interpreter_tag, tag_fmt, connection_host, xpid );

	monitor_task = 0;
	last_whenever_executed = 0;

	num_active_processes = 0;
	verbose = 0;


	// Create the "system" global variable.
	system_agent = new SystemAgent( this );
	sys_val = system_agent->AgentRecord();

	Expr* system_expr = InstallID( string_dup( "system" ), GLOBAL_SCOPE );
	system_expr->SetChangeNotice(system_change_function);
	system_expr->Assign( opt, sys_val );

	SetupSysValue( sys_val );

	// Create place for the script variable to be filled in later
	script_expr = InstallID( string_dup( "script" ), GLOBAL_SCOPE );
	script_expr->Assign( opt, new IValue( glish_false ) );

	name = argv[0];
	interpreter_path = which_executable( argv[0] );
	name_list *load_list = new name_list;

	// Skip past client parameters
	int argcnt = 0;
	int found_sep = 0;
	for ( ++argv, --argc; argc > 0; ++argv, --argc, ++argcnt )
		if ( ! strcmp( argv[0], "-+-" ) )
			{
			--argc, ++argv, ++found_sep;
			break;
			}

	if ( ! found_sep )
		{
		argc += argcnt;
		argv -= argcnt;
		}

	// Process startup parameters
	for ( ; argc > 0; ++argv, --argc )
		{
		if ( ! strcmp( argv[0], "-l" ) )
			if ( argc > 1 )
				{
				++argv; --argc;
				if ( argv[0] && strlen(argv[0]) )
					load_list->append( argv[0] );
				else
					glish_fatal->Report("bad file name with \"-l\".");
				}
			else
				glish_fatal->Report("\"-l\" given with no file to load.");

		else if ( ! strcmp( argv[0], "-tk" ) )
			load_list->append( "glishtk.g" );

		else if ( argv[0][0] == '-' && argv[0][1] == 'v' &&
			  argv[0][2] >= '1' && argv[0][2] <= '9' &&
			  argv[0][3] == '\0' )
			verbose = argv[0][2] - '0';

		else if ( ! strcmp( argv[0], "-noaf" ) )
			verbose_mask |= NO_AUTO_FAIL();

		else if ( ! strcmp( argv[0], "-faildef" ) )
			verbose_mask |= FAIL_DEFAULT();

		else if ( ! strcmp( argv[0], "-vi" ) )
			verbose_mask |= VERB_INCL();

		else if ( ! strcmp( argv[0], "-vf" ) )
			verbose_mask |= VERB_FAIL();

		else if ( ! strcmp( argv[0], "-w" ) )
			++allwarn;

		else if ( ! strcmp( argv[0], "-version" ) )
			{
			glish_message->Report( "Glish version ", GLISH_VERSION, ". " );
			exit( 0 );
			}

		else if ( ! strcmp( argv[0], "-info" ) )
			{
			glish_message->Report( "Glish version:          ", GLISH_VERSION, ". " );
			glish_message->Report( "script directory:       ", SCRIPTDIR );
			glish_message->Report( "site glishrc directory: ", RCDIR );
			glish_message->Report( "key directory:          ", KEYDIR );
			exit( 0 );
			}

		else if ( ! strcmp( argv[0], "-help" ) )
			{
			glish_message->Report( "-help        get this output" );
			glish_message->Report( "-version     get glish version" );
			glish_message->Report( "-info        get glish directory information" );
			glish_message->Report( "-l <FILE>    load <FILE> after .glishrc" );
			glish_message->Report( "-vf          report each \"dropped\" fail value" );
			glish_message->Report( "-vi          report each included file" );
			glish_message->Report( "-v[1-9]      set the verbosity level" );
			glish_message->Report( "-w           report each generated error string" );
			glish_message->Report( "-noaf        suppress auto-fail behavior (TEMPOARY FLAG)" );
			glish_message->Report( "-faildef     initialized values to <fail> by default" );
			glish_message->Report( "<FILE>       execute <FILE> rather than running interactively" );
			glish_message->Report( "<ENV>=<VAL>  export <ENV> to the environment with value <VAL>" );
			glish_message->Report( "--           end arguments to Glish" );
			exit( 0 );
			}

		else if ( strchr( argv[0], '=' ) )
			putenv( argv[0] );

		else
			break;
		}

	MakeArgvGlobal( opt, argv, argc, 1 );
	MakeEnvGlobal( opt );
	BuildSuspendList();

	char* monitor_client_name = getenv( "glish_monitor" );
	if ( monitor_client_name )
		ActivateMonitor( monitor_client_name );

	Parse( opt, glish_init );

	FILE* glish_rc_file;
	int loaded_system_glishrc = 0;

	//
	// Before anything else look for $HOME/.glishrc.pre
	//
	if ( (glish_rc_dir = getenv( "HOME" )) )
		{
		sprintf( glish_rc_filename, "%s/%s",
			 glish_rc_dir, GLISH_RC_FILE_PRE );

		if ( is_regular_file(glish_rc_filename) &&
		     (glish_rc_file = fopen( glish_rc_filename, "r")) )
			{
			if ( VERB_INCL(verbose_mask) )
				std::cerr << "vi " << glish_rc_filename << std::endl;
			Parse( opt, glish_rc_file, glish_rc_filename );
			}
		}

	glish_rc_dir = getenv( RCDIR_VAR );

	//
	//  Check $GLISHROOT/.glishrc
	//
	if ( glish_rc_dir )
		{
		sprintf( glish_rc_filename, "%s/%s",
				glish_rc_dir, GLISH_RC_FILE );

		if ( is_regular_file( glish_rc_filename ) &&
			(glish_rc_file = fopen( glish_rc_filename, "r")) )
				{
				if ( VERB_INCL(verbose_mask) )
					std::cerr << "vi " << glish_rc_filename << std::endl;
				Parse( opt, glish_rc_file, glish_rc_filename );
				loaded_system_glishrc = 1;
				}
		}

	//
	//  Check <default-rc-location>/.glishrc, if we didn't
	//  find one in $GLISHROOT...
	//
	if ( ! loaded_system_glishrc )
		{
		sprintf( glish_rc_filename, "%s/%s",
				RCDIR, GLISH_RC_FILE );

		if ( is_regular_file( glish_rc_filename ) &&
			(glish_rc_file = fopen( glish_rc_filename, "r")) )
				{
				if ( VERB_INCL(verbose_mask) )
					std::cerr << "vi " << glish_rc_filename << std::endl;
				Parse( opt, glish_rc_file, glish_rc_filename );
				}
		}

	//
	//  Load $GLISHRC if it exists and is a valid file...
	//
	if ( (glish_rc_dir = getenv( "GLISHRC" )) &&
	     is_regular_file( glish_rc_dir ) &&
	     (glish_rc_file = fopen( glish_rc_dir, "r")) )
		{
		if ( VERB_INCL(verbose_mask) )
			std::cerr << "vi " << glish_rc_dir << std::endl;
		Parse( opt, glish_rc_file, glish_rc_dir );
		}
	else
		{
		//
		//  Otherwise load .glishrc from $HOME, if it exists
		//
		if ( is_regular_file( GLISH_RC_FILE ) &&
		     (glish_rc_file = fopen( GLISH_RC_FILE, "r" )) )
			{
			if ( VERB_INCL(verbose_mask) )
				std::cerr << "vi " << GLISH_RC_FILE << std::endl;
			Parse( opt, glish_rc_file, GLISH_RC_FILE );
			}

		else if ( (glish_rc_dir = getenv( "HOME" )) )
			{
			sprintf( glish_rc_filename, "%s/%s",
					glish_rc_dir, GLISH_RC_FILE );

			if ( is_regular_file(glish_rc_filename) &&
			     (glish_rc_file = fopen( glish_rc_filename, "r")) )
				{
				if ( VERB_INCL(verbose_mask) )
					std::cerr << "vi " << glish_rc_filename << std::endl;
				Parse( opt, glish_rc_file, glish_rc_filename );
				}
			}
		}

	//
	// Before anything else look for $HOME/.glishrc.post
	//
	if ( (glish_rc_dir = getenv( "HOME" )) )
		{
		sprintf( glish_rc_filename, "%s/%s",
			 glish_rc_dir, GLISH_RC_FILE_POST );

		if ( is_regular_file(glish_rc_filename) &&
		     (glish_rc_file = fopen( glish_rc_filename, "r")) )
			{
			if ( VERB_INCL(verbose_mask) )
				std::cerr << "vi " << glish_rc_filename << std::endl;
			Parse( opt, glish_rc_file, glish_rc_filename );
			}
		}



	// after glishrc update timer settings to register
	// any change to system.client.ping
	daemon_probe->UpdateInterval( );

	if ( load_list->length() )
		{
		loop_over_list( *load_list, i )
			{
			char *exp_name = which_include((*load_list)[i]);
			if ( exp_name && is_regular_file( exp_name ) )
				load_list->replace(i,exp_name);
			else
				glish_fatal->Report("Can't include file \"",
						      (*load_list)[i],"\".");
			}

		// Prevent re-executing the .glishrc statements
		ClearStmt();

		loop_over_list( *load_list, j )
			if ( ! include_once.Lookup((*load_list)[j]) )
				{
				expanded_name = (*load_list)[j];
				if ( VERB_INCL(verbose_mask) )
					std::cerr << "vi " << expanded_name << std::endl;
				Parse( opt, (*load_list)[j] );
				}

		delete_name_list( load_list );
		}

	int do_interactive = 1;

// 	release_explicit( );

	if ( argc > 0 && strcmp( argv[0], "--" ) && (run_file = which_include(argv[0])) )
		{
		do_interactive = 0;
		MakeArgvGlobal( opt, argv, argc, 0 );
		if ( ! include_once.Lookup( run_file ) )
			{
			if ( VERB_INCL(verbose_mask) )
				std::cerr << "vi " << run_file << std::endl;
			Parse( opt, run_file );
			}
		}

	if ( ! ScriptCreated() )
		InitScriptClient( opt );

	if ( do_interactive )
		Parse( opt, stdin );
	}


Sequencer::~Sequencer()
	{
	if ( ! shutdown_posted )
		{
		shutdown_posted = 1;
		IValue exit_val(glish_true);
		SystemEvent( "exit", &exit_val );
		RunQueue( );
		}

	shutting_glish_down = 1;

#ifdef LINT
	int x;
	const char* key;
	IterCookie* c = include_once.InitForIteration();
	while ( (x = include_once.NextEntry( key, c )) )
		free_memory((char*)key);

	void *xs = 0;
	c = env.InitForIteration();
	while ( (xs = env.NextEntry( key, c )) )
		free_memory((char*)key);

	loop_over_list( notes_inuse, k )
		Unref( notes_inuse[k] );

	NodeUnref( stmts );

	loop_over_list( scopes, j )
		delete scopes[j];

	loop_over_list( global_frame, i )
		Unref( global_frame[i] );

	while ( stack.length() ) PopFrames();

	if ( ! script_client_active && script_client )
		delete script_client;

	free_memory( interpreter_tag );
	delete connection_socket;
	free_memory( connection_port );
#endif

	while ( (*agents).length() )
		Unref( (*agents).remove_nth( (*agents).length() - 1 ) );

#ifdef LINT
	Unref( selector );

	finalize_values();
	finalize_interp_reporters();
	delete null_stmt;
#endif
	}


void Sequencer::AddBuiltIn( BuiltIn* built_in )
	{
	evalOpt opt;
	Expr* id = InstallID( string_dup( built_in->Name() ), GLOBAL_SCOPE );
	id->Assign( opt, new IValue( built_in ) );
	}


void Sequencer::QueueNotification( Notification* n )
	{
	if ( verbose > 1 )
		glish_message->Report( "queueing", n );

	notification_queue.EnQueue( n );
	}

void Sequencer::PushNote( Notification *n )
	{
	//
	// If we're pushing on an AWAIT notification, then we first
	// remove any AWAITS on top because otherwise they may build
	// up; at the toplevel, that is...
	//
	if ( n && (n->type() == Notification::AWAIT || n->type() == Notification::STICKY) )
		while ( notes_inuse.length() &&	notes_inuse[notes_inuse.length()-1] &&
			(notes_inuse[notes_inuse.length()-1]->type() == Notification::AWAIT ||
			 notes_inuse[notes_inuse.length()-1]->type() == Notification::STICKY) )
			Unref( notes_inuse.remove_nth( notes_inuse.length()-1 ) );
	notes_inuse.append( n );
	}

void Sequencer::PopNote( int doing_func )
	{
	Notification *n = 0;
	notification_list sticky;
	if ( doing_func )
		{
		while ( notes_inuse.length() && (n=notes_inuse.remove_nth( notes_inuse.length()-1 )) )
			{
			if ( n->type() == Notification::STICKY )
				sticky.append(n);
			else
				Unref( n );
			}
		}
	else
		{
		//
		// Here we pop off until we hit a notification generated by
		// a whenever, because awaits push on pseudo notifications to
		// make $value, $name, and $agent work properly
		//
		while ( notes_inuse.length() && notes_inuse[notes_inuse.length()-1] )
			{
			Notification *n = notes_inuse.remove_nth( notes_inuse.length()-1 );
			int do_break = n->type() == Notification::WHENEVER;
			if ( n->type() == Notification::STICKY )
				sticky.append(n);
			else
				Unref( n );
			if ( do_break ) break;
			}
		}

	for ( int j=sticky.length()-1; j >= 0; --j )
		notes_inuse.append(sticky[j]);
	}

static void expr_list_element_unref( void *vp )
	{
	Expr *p = (Expr*) vp;
	Unref( p );
	}

void Sequencer::PushScope( scope_type s )
	{
	Scope *newscope = new Scope( s );
	scopes.append( newscope );
	if ( s != LOCAL_SCOPE )
		global_scopes.append( scopes.length() - 1 );
	if ( s == FUNC_SCOPE )
		{
		expr_list *el = new expr_list;
		el->set_finalize_handler( expr_list_element_unref );
		back_refs.append( el );
		}
	}

int Sequencer::PopScope( back_offsets_type **back_ref_ptr )
	{
	int top_scope_pos = scopes.length() - 1;

	if ( top_scope_pos < 0 )
		glish_fatal->Report( "scope underflow in Sequencer::PopScope" );

	Scope* top_scope = scopes[top_scope_pos];
	int frame_size = top_scope->Length();

	scopes.remove( top_scope );

	if ( top_scope->GetScopeType() != LOCAL_SCOPE )
		global_scopes.remove( top_scope_pos );

	if ( top_scope->GetScopeType() == FUNC_SCOPE )
		{
		int back_ref_top = back_refs.length()-1;

		if ( back_ref_top < 0 )
			glish_fatal->Report( "back reference underflow in Sequencer::PopScope" );

		expr_list *back = back_refs.remove_nth( back_ref_top );

		if ( back )
			{
			if ( back_ref_ptr && back->length() > 0 )
				{
				*back_ref_ptr = new back_offsets_type( back->length() );
				loop_over_list( *back, X )
				  (**back_ref_ptr).set( X, ((VarExpr*)(*back)[X])->offset(),
							((VarExpr*)(*back)[X])->soffset(),
							((VarExpr*)(*back)[X])->Scope() );
				}
			Unref( back );
			}
		}

	delete top_scope;

	return frame_size;
	}

void Sequencer::StashScope( )
	{
	int top_scope_pos = scopes.length() - 1;

	if ( stashed_scope )
		glish_fatal->Report( "stashed scope overflow in Sequencer::StashScope" );

	if ( top_scope_pos < 0 )
		glish_fatal->Report( "scope underflow in Sequencer::StashScope" );

	stashed_scope = scopes[top_scope_pos];
	scopes.remove( stashed_scope );

	if ( stashed_scope->GetScopeType() != LOCAL_SCOPE )
		global_scopes.remove( top_scope_pos );
	}

void Sequencer::RestoreScope( )
	{
	if ( ! stashed_scope )
		glish_fatal->Report( "stashed scope underflow in Sequencer::RestoreScope" );

	scopes.append( stashed_scope );
	if ( stashed_scope->GetScopeType() != LOCAL_SCOPE )
		global_scopes.append( scopes.length() - 1 );

	stashed_scope = 0;
	}

scope_type Sequencer::GetScopeType() const
	{
	int s_index = scopes.length() - 1;

        if ( ! s_index )
		return GLOBAL_SCOPE;

	int gs_index = global_scopes.length();
	if (  gs_index && global_scopes[--gs_index] == s_index )
		return FUNC_SCOPE;

	return LOCAL_SCOPE;
	}

Scope *Sequencer::GetScope( )
	{
	if ( scopes.length() )
		return scopes[0];
	else
		return 0;
	}

Expr* Sequencer::InstallID( char* id, scope_type scope, int do_warn, int bool_initial,
				int GlobalRef, int FrameOffset,
				change_var_notice f )
	{
	int scope_index;
	int scope_offset = 0;
	int gs_index = global_scopes.length() - 1;

	if ( GlobalRef )
		scope = LOCAL_SCOPE;

	switch ( scope )
		{
		case LOCAL_SCOPE:
			scope_index = scopes.length() - 1;

			if ( GlobalRef )
				scope_offset = -scope_index;
			else
				{
				int goff = global_scopes[gs_index];
				if ( scopes[goff]->GetScopeType() != GLOBAL_SCOPE )
					scope_offset = scope_index - goff;
				else
					scope_offset = scope_index - 1;
				}
			break;
		case FUNC_SCOPE:
			scope_index = global_scopes[gs_index];
			break;
		case GLOBAL_SCOPE:
			scope_index = 0;
			break;
		default:
			glish_fatal->Report("bad scope tag in Sequencer::InstallID()" );

		}

	Scope *cur_scope = scopes[scope_index];

	scope = cur_scope->GetScopeType();

	int frame_offset = GlobalRef ? FrameOffset : cur_scope->Length();

	Expr* result = CreateVarExpr( id, GlobalRef ? GLOBAL_SCOPE : scope, scope_offset,
				      frame_offset, this, f, bool_initial );

	if ( cur_scope->WasGlobalRef( id ) )
		{
		cur_scope->ClearGlobalRef( id );
		if ( do_warn )
			glish_warn->Report( "scope of \"", id,"\" goes from global to local");
		}

	Expr *old = (Expr*) cur_scope->Insert( id, result );

	if ( scope == GLOBAL_SCOPE )
		{
		global_frame.append( 0 );
		if ( GetScopeType() != GLOBAL_SCOPE && ! GlobalRef )
			// a "string_dup()" is required here because this current
			// invocation of InstallID() will free/use this copy, but
			// this next invocation will also do the same...
			InstallID( string_dup( id ), LOCAL_SCOPE, do_warn, bool_initial, 1, frame_offset );
		}

	if ( old )
		{
		Unref(old);
		free_memory( id );
		}

	return result;
	}

Expr* Sequencer::LookupID( char* id, scope_type scope, int do_install, int do_warn,
			   int local_search_all, int bool_initial )
	{
	Expr *result = 0;

	switch ( scope )
		{
		case ANY_SCOPE:
			{
			int gindex = global_scopes.length() - 1;
			int goff = global_scopes[gindex];
			int off = scopes.length()-1;
			int cnt = off;
			for ( ; ! result && cnt >= 0; cnt-- )
				result = (*scopes[cnt])[id];

			if ( off != cnt+1 )
				{
				scopes[off]->MarkGlobalRef( id );
				if ( result && scopes[cnt+1]->GetScopeType() != GLOBAL_SCOPE )
					{
					VarExpr *ve = (VarExpr*)((*scopes[cnt+1])[id]);
					Expr *result = CreateVarExpr( id, ve->Scope() == GLOBAL_SCOPE ? GLOBAL_SCOPE : LOCAL_SCOPE,
								      cnt+1 - goff + ve->soffset(), ve->offset(), this );
					Expr *old = (Expr*) scopes[off]->Insert( id, result );
					if ( old )
						{
						Unref(old);
						free_memory( id );
						}
					return result;
					}
				}

			if ( ! result && do_install )
				return InstallID( id, GLOBAL_SCOPE, do_warn, bool_initial );
			}
			break;
		case LOCAL_SCOPE:
			{
			if ( local_search_all )
				{
				for ( int cnt = scopes.length()-1; ! result && cnt >= 0; cnt-- )
					{
					result = (*scopes[cnt])[id];
					if ( scopes[cnt]->GetScopeType() != LOCAL_SCOPE )
						break;
					}
				if ( ! result && do_install )
					return InstallID( id, FUNC_SCOPE, do_warn, bool_initial );
				}
			else
				{
				result = (*scopes[scopes.length()-1])[id];
				if ( ! result && do_install )
					return InstallID( id, LOCAL_SCOPE, do_warn, bool_initial );
				}
			}
			break;
		case FUNC_SCOPE:
			{
			int cnt = global_scopes.length() - 1;
			int offset = global_scopes[cnt];
			result = (*scopes[offset])[id];
			if ( ! result && do_install )
				return InstallID( id, FUNC_SCOPE, do_warn, bool_initial );
			}
			break;
		case GLOBAL_SCOPE:
			result = (*scopes[0])[id];
			if ( ! result && do_install )
				return InstallID( id, GLOBAL_SCOPE, do_warn, bool_initial );
			if ( result && GetScopeType() != GLOBAL_SCOPE )
				return InstallID( id, LOCAL_SCOPE, do_warn, bool_initial, 1,
						  ((VarExpr*)result)->offset(),
						  ((VarExpr*)result)->change_func() );
			break;
		default:
			glish_fatal->Report("bad scope tag in Sequencer::LookupID()" );

		}

	free_memory(id);
	return result;
	}

Expr *Sequencer::InstallVar( char* id, scope_type scope, VarExpr *var )
	{
	int scope_index;
	int scope_offset = 0;
	int gs_index = global_scopes.length() - 1;

	switch ( scope )
		{
		case LOCAL_SCOPE:
			{
			scope_index = scopes.length() - 1;

			int goff = global_scopes[gs_index];
			if ( scopes[goff]->GetScopeType() != GLOBAL_SCOPE )
				scope_offset = scope_index - goff;
			else
				scope_offset = scope_index - 1;
			}
			break;
		case FUNC_SCOPE:
			scope_index = global_scopes[gs_index];
			break;
		case GLOBAL_SCOPE:
			scope_index = 0;
			break;
		default:
			glish_fatal->Report("bad scope tag in Sequencer::InstallID()" );

		}

	Scope *cur_scope = scopes[scope_index];

	scope = cur_scope->GetScopeType();

	int frame_offset = cur_scope->Length();

	var->set( scope, scope_offset, frame_offset );

	if ( cur_scope->WasGlobalRef( id ) )
		{
		cur_scope->ClearGlobalRef( id );
		glish_warn->Report( "scope of \"", id,"\" goes from global to local");
		}

	Expr *old = (Expr*) cur_scope->Insert( id, var );

	if ( scope == GLOBAL_SCOPE )
		global_frame.append( 0 );

	if ( old )
		{
		Unref(old);
		free_memory( id );
		}

	return var;
	}

Expr *Sequencer::LookupVar( char* id, scope_type scope, VarExpr *var, int &created )
	{
	Expr *result = 0;
	created = 0;

	switch ( scope )
		{
		case ANY_SCOPE:
			{
			int gindex = global_scopes.length() - 1;
			int goff = global_scopes[gindex];
			int off = scopes.length()-1;
			int cnt = off;
			for ( ; ! result && cnt >= 0; cnt-- )
				result = (*scopes[cnt])[id];

			if ( off != cnt+1 )
				{
				scopes[off]->MarkGlobalRef( id );
				if ( result && scopes[cnt+1]->GetScopeType() != GLOBAL_SCOPE )
					{
					created = 1;
					return CreateVarExpr( id, ( ((VarExpr*)((*scopes[cnt+1])[id]))->soffset() < 0 &&
								    ((VarExpr*)((*scopes[cnt+1])[id]))->Scope() == GLOBAL_SCOPE )
								    ? GLOBAL_SCOPE : LOCAL_SCOPE,
							      cnt+1 - goff + ((VarExpr*)((*scopes[cnt+1])[id]))->soffset(),
							      ((VarExpr*)((*scopes[cnt+1])[id]))->offset(), this );
					}
				}

			if ( ! result )
				return InstallVar( id, GLOBAL_SCOPE, var );
			}

			break;
		case LOCAL_SCOPE:
			{
			for ( int cnt = scopes.length()-1; ! result && cnt >= 0; cnt-- )
				{
				result = (*scopes[cnt])[id];
				if ( scopes[cnt]->GetScopeType() != LOCAL_SCOPE )
					break;
				}
			if ( ! result )
				return InstallVar( id, FUNC_SCOPE, var );
			}
			break;
		case FUNC_SCOPE:
			{
			int cnt = global_scopes.length() - 1;
			int offset = global_scopes[cnt];
			result = (*scopes[offset])[id];
			if ( ! result )
				return InstallVar( id, FUNC_SCOPE, var );
			}
			break;
		case GLOBAL_SCOPE:
			result = (*scopes[0])[id];
			if ( ! result )
				return InstallVar( id, GLOBAL_SCOPE, var );
			break;
		default:
			glish_fatal->Report("bad scope tag in Sequencer::LookupID()" );

		}

	free_memory( id );
	return result;
	}

void Sequencer::SetErrorResult( IValue *err )
	{
	Unref(cur_sequencer->error_result);
	cur_sequencer->error_result = err ? new IValue( *err ) : 0;
	}

Sequencer *Sequencer::CurSeq ( )
	{
	return cur_sequencer;
	}

const AwaitStmt *Sequencer::ActiveAwait ( )
	{
	await_type *aw = cur_sequencer->await();
	return (const AwaitStmt*) (aw ? aw->stmt() : 0);
	}

int Sequencer::AwaitDone( )
	{
	await_type *aw = await( );
	return aw && aw->ResultValue( );
	}

#define DECLARE_PATHFUNC( NAME )					\
char *Sequencer::NAME( const char *host, const char *var_str )		\
	{								\
	const IValue *pv = cur_sequencer->System().NAME();		\
	const IValue *v = 0;						\
	char *string = 0;						\
									\
	if ( ! pv ) return 0;						\
									\
	if ( pv->Type() == TYPE_STRING )				\
		string = join_path( pv->StringPtr(0), pv->Length() );	\
	else if ( pv->Type() == TYPE_RECORD )				\
		{							\
		if ( pv->HasRecordElement( host ) &&			\
		     ( v = (const IValue*)(pv->ExistingRecordElement( host ))) && \
		     v != false_value && v->Type() == TYPE_STRING && v->Length() ) \
			string = join_path( v->StringPtr(0), v->Length(), var_str ); \
		else if ( pv->HasRecordElement( "default" ) &&		\
			  ( v = (const IValue*)(pv->ExistingRecordElement( "default" ))) && \
			  v != false_value && v->Type() == TYPE_STRING && v->Length() ) \
			string = join_path( v->StringPtr(0), v->Length(), var_str ); \
		}							\
									\
	return string;							\
	}

DECLARE_PATHFUNC( BinPath )
DECLARE_PATHFUNC( LdPath )


void Sequencer::HoldQueue( )
	{
	hold_queue += 1;
	}

void Sequencer::ReleaseQueue( )
	{
	hold_queue -= 1;
	}

const IValue *Sequencer::LookupVal( evalOpt &opt, const char *id )
	{
	Expr *expr = 0;
	const IValue *val = 0;
	if ( cur_sequencer && (expr = cur_sequencer->LookupID( string_dup( id ), GLOBAL_SCOPE, 0 )) )
		{
		val = expr->ReadOnlyEval( opt );
		expr->ReadOnlyDone( val );	// **BUG**
		}
	return val;
	}

Frame *Sequencer::FindCycleFrame( int start_off )
        {
        frame_list &t = frames();
	if ( start_off < 0 ) start_off = t.length()-1;
        for ( int x=start_off; x >= 0; --x )
                if ( t[x] && t[x]->GetCycleRoots( ) )
                        return t[x];
        return t[start_off];
        }

// Messy, messy
void Sequencer::DeleteVal( const char* id )
	{
	VarExpr *expr = (VarExpr*) (*scopes[0])[id];
	static unsigned long filler = 0;
	static char buf[256];

	if ( expr )
		{
		// Get the value that we are blowing away and change it to 'F',
		// but leave it in the frame because functions may be point to it.
		IValue *iv = global_frame[expr->offset()];
		if ( iv )
			{
			IValue *newval = new IValue(glish_false);
			iv->TakeValue(newval);		// Unref()s newval
			}
		// Create an impossible, non-clashing name
		sprintf(buf,"*%lx*",filler++);
		char *newid = string_dup(buf);
		// Remove the old name from the scope dict
		(*scopes[0]).Remove( id );
		// Stick the new name into the old VarExpr
		// so that the name will be deleted
		expr->change_id(newid);
		// Put the changed VarExpr back into the scope hash with
		// the new name so that size correspondence of the frame
		// and scope is maintained
		(*scopes[0]).Insert(newid,expr);
		}
	}

void Sequencer::DescribeFrames( OStream& s ) const
	{
	if ( stack.length() ) s << endl;
	loop_over_list( stack, X )
		{
		stack_type *S = stack[X];
		s << "[" << X << "]" << (void*) S;
		if ( (*S->frames()).length() )
			{
			s << "\tframes:\t\t";
			loop_over_list((*S->frames()), i)
				if ( (*S->frames())[i] )
					s << (void*) (*S->frames())[i] << "\t";
				else
				  	s << "X" << "\t\t";
			s << endl;

			s << "\t\t\t\t";
			loop_over_list((*S->frames()), j)
				if ( (*S->frames())[j] )
					s << (*S->frames())[j]->Size() << "\t\t";
				else
				  	s << "X" << "\t\t";
			}
		s << endl;
		if ( (*S->offsets()).length() )
			{
			s << "\t\toffsets:\t";
			loop_over_list((*S->offsets()), i)
				s << (*S->offsets())[i] << "\t\t";
			s << endl;
			}
		}
	}

void Sequencer::PushFrame( Frame* new_frame )
	{
	frames().append( new_frame );
	if ( new_frame && new_frame->GetScopeType() != LOCAL_SCOPE )
		global_frames().append( frames().length() - 1 );
	}

void Sequencer::PushFrames( stack_type *new_stack )
	{
	if ( new_stack && new_stack->frame_len() != new_stack->frames()->length() )
		{
		stack_type *ns = new stack_type( *new_stack, 1, 1);
		stack.append( ns );
		}
	else
		{
		Ref(new_stack);
		stack.append(new_stack);
		}
	}

Frame* Sequencer::PopFrame( )
	{
	int howmany = 1;

	int top_frame_pos = frames().length() - 1;

	if ( top_frame_pos < howmany - 1 )
		glish_fatal->Report(
			"local frame stack underflow in Sequencer::PopFrame" );

	Frame *top_frame = 0;
	for ( int i = top_frame_pos; howmany > 0; howmany--, i-- )
		{
		top_frame = frames().remove_nth( i );
		if ( top_frame && top_frame->GetScopeType() != LOCAL_SCOPE )
			global_frames().remove( i );
		}

	return top_frame;
	}

const stack_type *Sequencer::PopFrames( )
	{
	stack_type *ns = stack.remove_nth(stack.length()-1);
	const stack_type *ret = 0;
	if ( (ret = ns->delete_on_spot()) )
		delete ns;
	else
		Unref(ns);

	return ret ? ret : ns;
	}

Frame* Sequencer::CurrentFrame()
	{
	int top_frame = frames().length() - 1;
	if ( top_frame < 0 )
		return 0;

	return frames()[top_frame];
	}

Frame* Sequencer::FuncFrame()
	{
	for ( int frame = frames().length() - 1; frame >= 0; --frame )
		if ( frames()[frame] && frames()[frame]->GetScopeType() == FUNC_SCOPE )
			return frames()[frame];

	return 0;
	}

stack_type* Sequencer::LocalFrames()
	{
	if ( frames().length() )
		return new stack_type(*stack[stack.length()-1]);
	else
		return 0;
	}

IValue* Sequencer::FrameElement( scope_type scope, int scope_offset,
					int frame_offset )
	{
// 	if ( scope_offset < 0 )
// 		scope = GLOBAL_SCOPE;

	switch ( scope )
		{
		case LOCAL_SCOPE:
			{
			int offset = scope_offset;
			int gs_off = global_frames().length() - 1;

			if ( gs_off >= 0 )
				offset += global_frames()[gs_off];

			if ( offset < 0 || offset >= frames().length() || ! frames()[offset] )
				glish_fatal->Report(
		    "local frame error in Sequencer::FrameElement (",
		    scope_offset, ",", gs_off ? global_frames()[gs_off] : -1,
		    "," , frames().length(), ")" );

			return frames()[offset]->FrameElement( frame_offset );
			}
			break;
		case FUNC_SCOPE:
			{
			int gs_off = global_frames().length() - 1;
			int offset = global_frames()[gs_off];

			if ( offset < 0 || offset >= frames().length() )
				glish_fatal->Report(
		    "local frame error in Sequencer::FrameElement (",
		    offset, " (", gs_off, "), ", frames().length(), ")" );

			return frames()[offset]->FrameElement( frame_offset );
			}
			break;
		case GLOBAL_SCOPE:
			{
			if ( frame_offset < 0 || frame_offset >= global_frame.length() )
				glish_fatal->Report(
				"bad global frame offset in Sequencer::FrameElement" );
			return global_frame[frame_offset];
			}
			break;
		default:
			glish_fatal->Report("bad scope tag in Sequencer::FrameElement()" );
		}

	return 0;
	}

const char *Sequencer::SetFrameElement( scope_type scope, int scope_offset,
					int frame_offset, IValue* value, change_var_notice f )
	{
	const char *ret = 0;
	IValue* prev_value;

// 	if ( scope_offset < 0 )
// 		scope = GLOBAL_SCOPE;

	switch ( scope )
		{
		case LOCAL_SCOPE:
			{
			int offset = scope_offset;
			int gs_off = global_frames().length() - 1;

			if ( gs_off >= 0 )
				offset += global_frames()[gs_off];

			if ( offset < 0 || offset >= frames().length() )
				glish_fatal->Report(
		    "local frame error in Sequencer::SetFrameElement (",
		    scope_offset, ",", gs_off ? global_frames()[gs_off] : -1,
		    "," , frames().length(), ")" );

			IValue*& frame_value =
				frames()[offset]->FrameElement( frame_offset );

			if ( frame_value && frame_value->IsConst() )
				ret = "'const' values cannot be modified.";
			else
				{
				prev_value = frame_value;
				frame_value = value;
				value->MarkSoftDel( );
				if ( prev_value ) prev_value->ClearSoftDel( );
				}
			}
			break;
		case FUNC_SCOPE:
			{
			int gs_off = global_frames().length() - 1;
			int offset = global_frames()[gs_off];

			if ( offset < 0 || offset >= frames().length() )
				glish_fatal->Report(
		    "local frame error in Sequencer::SetFrameElement (",
		    offset, " (", gs_off, "), ", frames().length(), ")" );

			IValue*& frame_value =
				frames()[offset]->FrameElement( frame_offset );

			if ( frame_value && frame_value->IsConst() )
				ret = "'const' values cannot be modified.";
			else
				{
				prev_value = frame_value;
				frame_value = value;
				value->MarkSoftDel( );
				if ( prev_value ) prev_value->ClearSoftDel( );
				}
			}
			break;
		case GLOBAL_SCOPE:
			{
			if ( frame_offset < 0 || frame_offset >= global_frame.length() )
				glish_fatal->Report(
				"bad global frame offset in Sequencer::FrameElement" );
			prev_value = global_frame.replace( frame_offset, value );
			if ( prev_value && prev_value->IsConst() )
				{
				prev_value = global_frame.replace( frame_offset, prev_value );
				ret = "'const' values cannot be modified.";
				}
			else
				{
				value->MarkGlobalValue( );
				if ( prev_value ) prev_value->ClearGlobalValue( );
				if ( f ) (*f)(prev_value,value);
				}
			}
			break;
		default:
			glish_fatal->Report("bad scope tag in Sequencer::SetFrameElement()" );


		}

	if ( prev_value )
		{
#ifdef FREEMEM
		int rcnt = prev_value->RefCount();
		if ( rcnt > 1 && prev_value->Type() == TYPE_RECORD &&
		     rcnt == prev_value->CountRefs(prev_value)+1 )
			{
			recordptr r = prev_value->RecordPtr();
			if ( r )
				{
				IterCookie* c = r->InitForIteration();

				Value* member;
				const char* key;

				while ( (member = r->NextEntry( key, c )) )
					{
					free_memory( (void*) key );
					Unref( member );
					}

				r->Clear();
				}

			}
#endif

		Unref( prev_value );
		}

	return ret;
	}

void Sequencer::PushFuncName( const char *n, unsigned short fle, unsigned short lne )
	{
	cur_sequencer->func_names.append( new func_name_info( n, fle, lne ) );
	}

void Sequencer::PopFuncName( )
	{
	int top_pos = cur_sequencer->func_names.length() - 1;

	if ( top_pos < 0 )
		glish_fatal->Report(
			"local frame stack underflow in Sequencer::PopFuncName" );

	func_name_info *top = cur_sequencer->func_names.remove_nth( top_pos );

	delete top;
	}

IValue *Sequencer::FuncNameStack( )
	{
	int len = cur_sequencer->func_names.length();

	if ( ! len ) return 0;

	char **strs = alloc_charptr( len );

	int offset = 0;
	func_name_list &names = cur_sequencer->func_names;
	for ( int i=0; i < len; i++ )
		{
		int nlen;
		if ( names[i]->name() && (nlen=strlen(names[i]->name())) && nlen > offset )
			offset = nlen;
		}

	char fmt[40],fmt_none[42];
	offset = offset < 45 ? offset+2 : 45;
	sprintf( fmt,      "%%%d.%ds(), %%s line %%d", offset, offset );
	sprintf( fmt_none, "%%%d.%ds()", offset, offset );

	for ( int i=0; i < len; i++ )
		{
		char *str = 0;
		func_name_info *info = names[i];

		const char *fle;
		if ( info->file() && (fle = (*glish_files)[info->file()]) )
			{
			str = alloc_char( strlen( fle ) + offset + 27 );
			sprintf( str, fmt, info->name(), fle, info->line( ) );
			}
		else
			{
			str = alloc_char( offset + 4 );
			sprintf( str, fmt_none, info->name() );
			}

		strs[i] = str;
		}

	return new IValue( (charptr*) strs, len );
	}

void Sequencer::UnhandledFail( const IValue *val )
	{
	if ( cur_sequencer->VERB_FAIL(cur_sequencer->verbose_mask) && val->Type() == TYPE_FAIL )
		{
		char *str = val->StringVal(' ',0,0,0,"vf ");
		std::cerr << str << std::endl;
		free_memory(str);
		}
	}

void Sequencer::FailCreated( IValue *val )
	{
	int len = 0;
	fail_stack_stack *fs = cur_sequencer->fail_stack;
	if (  fs && (len = fs->length( )) > 0 )
		{
		Ref( val );
		(*fs)[len-1]->append( val );
		}
	}

void Sequencer::PushFailStack( )
	{
	if ( ! fail_stack ) fail_stack = new fail_stack_stack;
	fail_stack->append( new ivalue_list );
	}

IValue *Sequencer::PopFailStack( )
	{
	static int count = 0;
	IValue *result = 0;
	int len = 0;
	if ( fail_stack && (len = fail_stack->length()) > 0 )
		{
		++count;
		ivalue_list *ivl = fail_stack->remove_nth( len-1 );
		loop_over_list( *ivl, X )
			{
			if ( (*ivl)[X] && ! (*ivl)[X]->FailMarked() && ! result )
				// Copy required?
				result = (*ivl)[X];
			else
				Unref( (*ivl)[X] );
			}
		Unref( ivl );
		}
	return result;
	}

char* Sequencer::RegisterTask( Task* new_task, int &idi )
	{
	char* new_ID = NewTaskId( idi );
	ids_to_tasks.Insert( new_ID, new_task );

	//
	// Make sure the task stays around at least until we
	// receive an "establish event"
	//
	Ref(new_task);

	return new_ID;
	}

void Sequencer::DeleteTask( Task* task )
	{
	(void) ids_to_tasks.Remove( task->TaskID() );
	}


void Sequencer::AddStmt( Stmt* addl_stmt )
	{
	stmts = merge_stmts( stmts, addl_stmt );
	}

void Sequencer::ClearStmt( )
	{
	NodeUnref( stmts );
	stmts = null_stmt;
	}

Stmt *Sequencer::GetStmt( )
	{
	return stmts;
	}

int Sequencer::RegisterStmt( Stmt* stmt )
	{
	static int count = 0;
	registered_stmts.append( stmt );
	return ++count;
	}

void Sequencer::UnregisterStmt( Stmt* stmt )
	{
	registered_stmts.remove( stmt );
	}

void Sequencer::RegisterBackRef( VarExpr *var )
	{
	int len = back_refs.length();

	if ( len > 0 && ! back_refs[len-1]->is_member( var ) )
		{
		Ref( var );
		back_refs[len-1]->append(var);
		}
	}

void Sequencer::NotifieeDone( Notifiee *gone )
	{
	Notification *n = 0;
	notification_queue.InitForIteration();
	while( (n = notification_queue.Next()) )
		if ( n->notifiee == gone )
			n->invalid( );
	}

Stmt* Sequencer::LookupStmt( int index )
	{
	for ( register int i=0; i < registered_stmts.length(); ++i )
		{
		register Stmt *s = registered_stmts[i];
		if ( s->Index() == index ) return s;
		if ( index < s->Index() ) break;
		}
	return 0;
	}

int Sequencer::LocalHost( const char *host )
	{
	if ( ! host ||
	     ! strcmp( host, ConnectionHost() ) ||
	     ! strcmp( host, "localhost" ) )
		return 1;
	else
		return 0;
	}

Channel* Sequencer::GetHostDaemon( const char* host, int &err )
	{
	err = 0;
	RemoteDaemon* d;

	if ( LocalHost( host ) )
		{
		// Check to see if a daemon is running
		static double checked_local_daemon = 0;
		double cur_time = 0;
		d = daemons["localhost"];
		if ( ! d && ( checked_local_daemon == 0 ||
			      (cur_time = get_current_time()) - checked_local_daemon > 30) )
			{
			checked_local_daemon = (cur_time != 0 ? cur_time : get_current_time());
			d = OpenDaemonConnection( "localhost", err );
			}
		}
	else
		{
		d = daemons[host];
		if ( ! d )
			d = CreateDaemon( host );
		if ( ! d )
			err = 1;
		}

	return d ? d->DaemonChannel() : 0;
	}


IValue *Sequencer::Exec( evalOpt &opt, int startup_script, int value_needed )
	{
	if ( interactive( ) )
		return 0;

	if ( glish_error->Count() > 0 )
		{
		glish_message->Report( "execution aborted" );
		return 0;
		}

	IValue *ret = 0;
	if ( stmts )
		{
		opt.set(evalOpt::VALUE_NEEDED);
		Stmt *cur_stmts = stmts;	// do this dance with stmts to
		Ref(cur_stmts);			// prevent stmts from being freed
						// or reassigned as part of an eval()

		ret = cur_stmts->Exec( opt );

		if ( ! value_needed )
			{
			if ( ret && ret->Type() == TYPE_FAIL )
				{
				ret->Describe( glish_error->Stream() );
			        glish_error->Stream() << endl;
				}
			Unref( ret );
			ret = 0;
			}

		Unref(cur_stmts);
		}

	if ( ! startup_script )
		EventLoop();

	ClearStmt();
	return ret;
	}

void Sequencer::PushAwait( )
	{
	await_list.append( new await_type( ) );
	}

await_type *Sequencer::PopAwait( )
	{
	return await_list.remove_nth(await_list.length()-1);
	}

void Sequencer::Await( AwaitStmt* arg_await_stmt, int only_flag,
			Stmt* arg_except_stmt )
	{
	int removed_stdin = 0;

	PushAwait( );

	await( )->set( arg_await_stmt, arg_except_stmt, only_flag );

	if ( isatty( fileno( stdin ) ) && selector->FindSelectee( fileno( stdin ) ) )
		{
		selector->DeleteSelectee( fileno( stdin ) );
		stdin_selectee_removed = removed_stdin = 1;
#if USE_EDITLINE
		//
		// reset term so user can see what is typed
		//
		nb_reset_term(1);
#endif
		}

	EventLoop( 1 );

	await_type *awt = PopAwait();
	PushNote( new Notification( awt->ResultAgent(), awt->ResultName(),
                  awt->ResultValue(), 0, 0, Notification::AWAIT ) );
	if ( awt ) delete awt;

	if ( isatty( fileno( stdin ) ) && removed_stdin )
		{
		selector->AddSelectee( new UserInputSelectee( fileno( stdin ) ) );
		stdin_selectee_removed = 0;
#if USE_EDITLINE
		nb_reset_term(0);
#endif
		}
	}

int Sequencer::HaveStdinSelectee( ) const
	{
	return isatty( fileno( stdin ) ) && selector->FindSelectee( fileno( stdin ) );
	}

int Sequencer::AddStdinSelectee( )
	{
	if ( isatty( fileno( stdin ) ) )
		{
		if ( ! selector->FindSelectee( fileno( stdin ) ) )
			selector->AddSelectee( new UserInputSelectee( fileno( stdin ) ) );
		return 1;
		}

	return 0;
	}

int Sequencer::RemoveStdinSelectee( )
	{
	if ( isatty( fileno( stdin ) ) )
		{
		if ( selector->FindSelectee( fileno( stdin ) ) )
			selector->DeleteSelectee( fileno( stdin ) );
		return 1;
		}

	return 0;
	}

void Sequencer::PagerOutput( char *string, char **argv )
	{
	int removed_stdin = 0;

	if ( isatty( fileno( stdin ) ) && selector->FindSelectee( fileno( stdin ) ) )
		{
		selector->DeleteSelectee( fileno( stdin ) );
		stdin_selectee_removed = removed_stdin = 1;
#if USE_EDITLINE
		//
		// reset term so user can see what is typed
		//
		nb_reset_term(1);
#endif
		}

	int input[2];
	int status[2];

	if ( pipe( input ) < 0 || pipe( status ) < 0 )
		perror( "glish: problem creating pipe" );

	int pid_ = (int) vfork();

	if ( pid_ == 0 )
		{ // child

		if ( dup2( input[0], fileno(stdin) ) < 0 )
			{
			perror( "glish: couldn't do dup2()" );
			_exit( -1 );
			}

		close( input[0] );
		close( input[1] );
		close( status[0] );

                execvp( argv[0], &argv[0] );

                perror( "glish couldn't exec child" );
                _exit( -1 );
                }

	close( input[0] );
	close( status[1] );

	write( input[1], string, strlen(string) );
	close( input[1] );

	//
	// UserInputSelectee is pulling double duty here; all it does
	// is stop the event loop when a fd changes. "status[0]" should
	// only change when the exec'ed  pager exits (i.e. when it is
	// closed).
	//
	selector->AddSelectee( new PagerSelectee( status[0], this ) );

	doing_pager = 1;
	EventLoop( 0 );

	selector->DeleteSelectee( status[0] );
	close( status[0] );

	if ( isatty( fileno( stdin ) ) && removed_stdin )
		{
		selector->AddSelectee( new UserInputSelectee( fileno( stdin ) ) );
		stdin_selectee_removed = 0;
#if USE_EDITLINE
		nb_reset_term(0);
#endif
		}

	reap_terminated_process();
	}


IValue* Sequencer::AwaitReply( Agent* agent, const char* event_name,
				const char* reply_name )
	{
	// should look at this to see why a copy is required!
	event_name = string_dup(event_name);
	reply_name = string_dup(reply_name);
	int removed_stdin = 0;

	PushAwait( );

	await( )->set( agent, reply_name );

	if ( isatty( fileno( stdin ) ) && selector->FindSelectee( fileno( stdin ) ) )
		{
		selector->DeleteSelectee( fileno( stdin ) );
		stdin_selectee_removed = removed_stdin = 1;
#if USE_EDITLINE
		//
		// reset term so user can see what is typed
		//
		nb_reset_term(1);
#endif
		}

	EventLoop( 1 );

	IValue *result = await( )->ResultValue( );

	if ( ! result )
		{
		glish_warn->Report( agent, " terminated without replying to ",
				event_name, " request" );
		result = error_ivalue();
		}
	else
		Ref( result );

	last_reply = 0;

	await_type *awt = PopAwait();
	if ( awt ) delete awt;

	if ( isatty( fileno( stdin ) ) && removed_stdin )
		{
		selector->AddSelectee( new UserInputSelectee( fileno( stdin ) ) );
		stdin_selectee_removed = 0;
#if USE_EDITLINE
		nb_reset_term(0);
#endif
		}

	free_memory((char*)event_name);
	free_memory((char*)reply_name);
	return result;
	}


void unref_suspended_value( void *val_ )
	{
	Unref( (Value*) val_ );
	}

void Sequencer::SendSuspended( sos_status *ss, Value *v )
	{
	if ( ! ss ) return;
	ss->finalize( unref_suspended_value, v );

	Selectee *old = selector->FindSelectee( ss->fd() );

	if ( ! old || old->type() != Selectee::WRITE )
		selector->AddSelectee( new SendSelectee( selector, ss, old ) );
	}

Channel* Sequencer::AddLocalClient( int read_fd, int write_fd )
	{
	Channel* c = new Channel( read_fd, write_fd );
	Selectee* s = new LocalClientSelectee( this, c );

	selector->AddSelectee( s );

	return c;
	}


Channel* Sequencer::WaitForTaskConnection( Task* task )
	{
	Task* t;
	Channel* chan;

	// Need to loop because perhaps we'll receive connections
	// from tasks other than the one we're waiting for.
	do
		{
		int new_conn = accept_connection( connection_socket->FD() );
		mark_close_on_exec( new_conn );

		chan = new Channel( new_conn, new_conn );
		t = NewConnection( chan );
		}
	while ( t && t != task );

	if ( t )
		return chan;
	else
		return 0;
	}

Task* Sequencer::NewConnection( Channel* connection_channel )
	{
	GlishEvent* establish_event =
		recv_event( connection_channel->Source() );

	// It's possible there's already a Selectee for this channel,
	// due to using a LocalClientSelectee.  If so, remove it, so
	// it doesn't trigger additional activity.
	RemoveSelectee( connection_channel );

	if ( ! establish_event )
		{
		glish_error->Report( "new connection immediately broken" );
		return 0;
		}

	IValue* v = (IValue*) (establish_event->value);
	char* task_id;
	int protocol;

	if ( v->Type() == TYPE_STRING )
		{
		task_id = v->StringVal();
		protocol = 1;
		}

	else if ( ! v->FieldVal( "name", task_id ) ||
		  ! v->FieldVal( "protocol", protocol ) )
		{
		glish_error->Report( "bad connection establishment" );
		return 0;
		}

	// ### Should check for protocol compatibility here.

	Task* task = ids_to_tasks[task_id];

	if ( ! task )
		{
		glish_error->Report( "connection received from non-existent task ",
				task_id );
		Unref( establish_event );
		return 0;
		}

	else
		{
		task->SetProtocol( protocol );

		const IValue *pidv = 0;
		if ( ! task->GetPid( ) && (pidv = (IValue*) v->Field( "pid" )) && pidv->IsNumeric( ) )
			task->SetPid( pidv->IntVal() );

		AssociateTaskWithChannel( task, connection_channel );

		//
		// 'task' was Ref'ed so that the establish event
		// can at least happen before the task is deleted.
		// here we undo that Ref.
		//
		if ( task->RefCount() <= 1 )
			{
			Unref(task);
			return 0;
			}
		else
			Unref(task);

		NewEvent( task, establish_event, 0, 0, 1 );
		}

	free_memory( task_id );

	return task;
	}


void Sequencer::AssociateTaskWithChannel( Task* task, Channel* chan )
	{
	task->SetChannel( chan, selector );
	task->SetActive();

	selector->AddSelectee( new ClientSelectee( this, task ) );

	// empty out buffer so subsequent select()'s will work
	if ( chan->DataInBuffer() )
		EmptyTaskChannel( task );
	}

void Sequencer::RemoveSelectee( Channel* chan )
	{
	if ( selector->FindSelectee( chan->Source().fd() ) )
		selector->DeleteSelectee( chan->Source().fd() );
	}


int Sequencer::NewEvent( Task* task, GlishEvent* event, int complain_if_no_interest,
			 NotifyTrigger *t, int preserve )
	{
	if ( ! event )
		{ // task termination
		task->CloseChannel();

		if ( task->Finished() )
			return 0;

		// Abnormal termination - no "done" message first.
		event = new GlishEvent( (const char*) "fail",
					(Value*)(new IValue( task->AgentID() )) );
		}

	const char* event_name = event->name;
	IValue* value = (IValue*)event->value;
	Agent *agent = task;

	if ( verbose > 0 )
		glish_message->Report( name, ": received event ",
				 task->Name(), ".", event_name, " ", value );

	if ( monitor_task && task != monitor_task )
		LogEvent( task->TaskID(), task->Name(), event_name, value, 1 );

	if ( event->IsProxy() )
		{
		if ( ! strcmp( event_name, "*proxy-id*" ) )
			{
			IValue *result = new IValue(NewObjId(task->TaskIDi()),ProxyId::len());
			task->SendEvent( event_name, result );
			Unref(result);
			}
		else if ( value->Type() == TYPE_RECORD )
			{
			const IValue *nid = 0;
			const IValue *nval = 0;
			if ( (nval = (IValue*)value->HasRecordElement("*proxy-create*")) &&
			     nval->Type() == TYPE_INT && nval->Length() == ProxyId::len())
				{
				ProxyTask *pxy = new ProxyTask(ProxyId(nval->IntPtr(0)), task, this);
				event->SetValue( (Value*)(value = pxy->AgentRecord()) );
				if ( ! event->IsQuiet() ) complain_if_no_interest = 1;
				}
			else if ( (nval = (IValue*)value->HasRecordElement("value")) &&
				  (nid = (IValue*)value->HasRecordElement("id")) &&
				  nid->Type() == TYPE_INT && nid->Length() == ProxyId::len())
				{
				ProxyId id(nid->IntPtr(0));
				ProxyTask *pxy = task->GetProxy(id);
				if ( pxy )
					{
					const IValue *pp = 0;
					if ( nval->Type() == TYPE_RECORD &&
					     (pp = (IValue*)nval->HasRecordElement("*proxy-create*")) &&
					     pp->Type() == TYPE_INT && pp->Length() == ProxyId::len() )
						{
						ProxyTask *pxy = new ProxyTask(ProxyId(pp->IntPtr(0)), task, this);
						event->SetValue( (Value*)(value = pxy->AgentRecord()) );
						}
					else
						event->SetValue((Value*)copy_value(nval));

					if ( ! strcmp( event_name, "done" ) )
						pxy->SetFinished( );

					agent = pxy;
					}
				else
					{
					// BAD PROXY IDENTIFIER
					Unref( event );
					return 0;
					}

				if ( ! event->IsQuiet() ) complain_if_no_interest = 1;
				}
			else
				if ( ! event->IsQuiet() ) complain_if_no_interest = 1;
			}
		else
			if ( ! event->IsQuiet() ) complain_if_no_interest = 1;
		}

	else if ( ! strcmp( event_name, "established" ) )
		{
		// We already did the SetActive() when the channel
		// was established.
		}

	else if ( ! strcmp( event_name, "done" ) )
		task->SetFinished();

	else if ( ! strcmp( event_name, "fail" ) )
		{
		task->SetFinished();
		complain_if_no_interest = 1;
		}

	else if ( ! strcmp( event_name, "*rendezvous*" ) )
		Rendezvous( event_name, value );

	else if ( ! strcmp( event_name, "*forward*" ) )
		ForwardEvent( event_name, value );

	else
		if ( ! event->IsQuiet() ) complain_if_no_interest = 1;

	if ( NewEvent( agent, event, complain_if_no_interest, t, preserve ) )
		{
		pending_task = task;

		// Make sure the pending task isn't delete'd before
		// we can exhaust its pending input.

		Ref( pending_task );

		return 1;
		}

	else
		return 0;
	}


int Sequencer::NewEvent( LoadedAgent* task, GlishEvent* event, int complain_if_no_interest,
			 NotifyTrigger *t, int preserve )
	{
	if ( ! event )
		{ // task termination

		if ( task->Finished() )
			return 0;

		// Abnormal termination - no "done" message first.
		event = new GlishEvent( (const char*) "fail",
					(Value*)(new IValue( task->AgentID() )) );
		}

	const char* event_name = event->name;
	IValue* value = (IValue*)event->value;
	Agent *agent = task;

	if ( verbose > 0 )
		glish_message->Report( name, ": received event ",
				 task->Name(), ".", event_name, " ", value );

	if ( monitor_task /* && task != monitor_task */ )
		LogEvent( task->TaskID(), task->Name(), event_name, value, 1 );

	if ( event->IsProxy() )
		{
		if ( value->Type() == TYPE_RECORD )
			{
			const IValue *nid = 0;
			const IValue *nval = 0;
			if ( (nval = (IValue*)value->HasRecordElement("*proxy-create*")) &&
			     nval->Type() == TYPE_INT && nval->Length() == ProxyId::len())
				{
				ProxyTask *pxy = new ProxyTask(ProxyId(nval->IntPtr(0)), task, this);
				event->SetValue( (Value*)(value = pxy->AgentRecord()) );
				if ( ! event->IsQuiet() ) complain_if_no_interest = 1;
				}
			else if ( (nval = (IValue*)value->HasRecordElement("value")) &&
				  (nid = (IValue*)value->HasRecordElement("id")) &&
				  nid->Type() == TYPE_INT && nid->Length() == ProxyId::len())
				{
				ProxyId id(nid->IntPtr(0));
				ProxyTask *pxy = task->GetProxy(id);
				if ( pxy )
					{
					const IValue *pp = 0;
					if ( nval->Type() == TYPE_RECORD &&
					     (pp = (IValue*)nval->HasRecordElement("*proxy-create*")) &&
					     pp->Type() == TYPE_INT && pp->Length() == ProxyId::len() )
						{
						ProxyTask *pxy = new ProxyTask(ProxyId(pp->IntPtr(0)), task, this);
						event->SetValue( (Value*)(value = pxy->AgentRecord()) );
						}
					else
						event->SetValue((Value*)copy_value(nval));

					if ( ! strcmp( event_name, "done" ) )
						pxy->SetFinished( );

					agent = pxy;
					}
				else
					{
					//
					// If we have a bogus ProxyId & this is a "done" event,
					// odds are that this is just a proxy that was deleted
					// from the interpreter side of things... the event
					// will have already been delivered to those looking for
					// events from the proxy...
					//
// 					if ( strcmp( event_name, "done" ) )
// 						{
// 						// BAD PROXY IDENTIFIER
// 						fprintf( stderr, "\t\t\t===> Sequencer::NewEvent( ): bad proxy identifier!\n" );
// 						}
					Unref( event );
					return 0;
					}

				if ( ! event->IsQuiet() ) complain_if_no_interest = 1;
				}
			else
				if ( ! event->IsQuiet() ) complain_if_no_interest = 1;
			}
		else
			if ( ! event->IsQuiet() ) complain_if_no_interest = 1;
		}

	else if ( ! strcmp( event_name, "established" ) )
		{
		// We already did the SetActive() when the channel
		// was established.
		}

	else if ( ! strcmp( event_name, "done" ) )
		task->SetFinished();

	else if ( ! strcmp( event_name, "fail" ) )
		{
		task->SetFinished();
		complain_if_no_interest = 1;
		}

	else if ( ! strcmp( event_name, "*rendezvous*" ) )
		Rendezvous( event_name, value );

	else if ( ! strcmp( event_name, "*forward*" ) )
		ForwardEvent( event_name, value );

	else
		if ( ! event->IsQuiet() ) complain_if_no_interest = 1;

	return NewEvent( agent, event, complain_if_no_interest, t, preserve );
	}


void Sequencer::CheckAwait( Agent* agent, const char* event_name, IValue *event_val )
	{
	for ( int i=await_list.length()-1; i >= 0; --i )
		{
		await_type *aw = await_list[i];
		if ( aw->stmt() && agent->HasRegisteredInterest( aw->stmt(), event_name ) ||
		     aw->agent() && aw->agent() == agent->AgentTask() && ! strcmp( aw->name(), event_name ) )
			{
			aw->SetValue( agent, event_name, event_val, 1 );
			break;
			}
		}
	}

#define NEWEVENT_BODY								\
										\
	int ignore_event = 0;							\
	int reply_event = 0;							\
	int await_finished = 0;							\
										\
	if ( await.active() )							\
		{								\
		int found_match = 0;						\
										\
		/* Look ahead into queued awaits for future handling */		\
		loop_over_list( await_list, X )					\
			{							\
			Agent *la = 0;						\
			if ( (la=await_list[X]->await.agent()) && la == agent && \
			     ! strcmp( await_list[X]->await.name(), event_name ) ) \
				{						\
				if ( (found_match = await_list[X]->SetValue( agent, event_name, value )) ) \
					{					\
					reply_event = 1;			\
					break;					\
					}					\
				}						\
			else if ( agent->HasRegisteredInterest( await_list[X]->await.stmt(), event_name ) ) \
				{						\
				if ( (found_match = await_list[X]->SetValue( agent, event_name, value )) ) \
					break;					\
				}						\
			}							\
										\
		if ( ! found_match )						\
			{							\
			if ( await.agent() && await.agent() == agent &&		\
			     ! strcmp( await.name(), event_name ) )		\
				{						\
				reply_event = 1;				\
				await_finished = 1;				\
				last_reply = value;				\
				Ref(last_reply);				\
				}						\
			else if ( await.stmt() )				\
				{						\
				await_finished = agent->HasRegisteredInterest( await.stmt(), event_name ); \
										\
				if ( ! await_finished && await.only( ) && 	\
				     ! agent->HasRegisteredInterest( await.except(), event_name ) ) \
					ignore_event = 1;			\
				}						\
			}							\
		}								\
										\
	if ( ! reply_event )							\
		{								\
		if ( ignore_event )						\
			glish_warn->Report( "event ", agent->Name(), ".", event_name,	\
				      " ignored due to \"await\"" );		\
		else if ( ! await.agent() || ! await_finished )			\
			{							\
			/* We're going to want to keep the event value as a */	\
			/* field in the agent's AgentRecord.                */	\
			Ref( value );						\
										\
			int was_interest = agent->CreateEvent( event_name,	\
							       value, t, preserve ); \
										\
			if ( ! was_interest && complain_if_no_interest )	\
				glish_warn->Report( "event ", agent->Name(), ".",	\
					      event_name, " (", value, 		\
					      ") dropped" );			\
										\
			/* process effects of CreateEvent() */			\
			RunQueue( await_finished );				\
			}							\
		}


int Sequencer::NewEvent( Agent* agent, const char* event_name, IValue* value,
			 int complain_if_no_interest, NotifyTrigger *t, int preserve )
	{

	int ignore_event = 0;
	int reply_event = 0;
	int await_finished = 0;

	await_type *aw = await( );

	if ( aw )
		{
		int found_match = 0;

		/* Look ahead into queued awaits for future handling */
		loop_over_list( await_list, X )
			{
			Agent *la = 0;
			if ( (la=await_list[X]->agent()) && la == agent &&
			     ! strcmp( await_list[X]->name(), event_name ) )
				{
				if ( (found_match = await_list[X]->SetValue( agent, event_name, value )) )
					{
					reply_event = 1;
					break;
					}
				}
			else if ( agent->HasRegisteredInterest( await_list[X]->stmt(), event_name ) )
				{
				if ( (found_match = await_list[X]->SetValue( agent, event_name, value )) )
					break;
				}
			}

		if ( ! found_match )
			{
			if ( aw->agent() && aw->agent() == agent &&
			     ! strcmp( aw->name(), event_name ) )
				{
				reply_event = 1;
				await_finished = 1;
				last_reply = value;
				Ref(last_reply);
				}
			else if ( aw->stmt() )
				{
				await_finished = agent->HasRegisteredInterest( aw->stmt(), event_name );

				if ( ! await_finished && aw->only( ) &&
				     ! agent->HasRegisteredInterest( aw->except(), event_name ) )
					ignore_event = 1;
				}
			}
		}

	if ( ! reply_event )
		{
		if ( ignore_event )
			glish_warn->Report( "event ", agent->Name(), ".", event_name,
				      " ignored due to \"await\"" );
		else if ( ! aw || ! aw->agent() || ! await_finished )
			{
			/* We're going to want to keep the event value as a */
			/* field in the agent's AgentRecord.                */
			Ref( value );

			int was_interest = agent->CreateEvent( event_name,
							       value, t, preserve );

			if ( ! was_interest && complain_if_no_interest )
				glish_warn->Report( "event ", agent->Name(), ".",
					      event_name, " (", value,
					      ") dropped" );

			/* process effects of CreateEvent() */
			RunQueue( await_finished );
			}
		}

	Unref( value );
	return await_finished ? 1 : 0;
	}

int Sequencer::NewEvent( Agent* agent, GlishEvent* event, int complain_if_no_interest,
			 NotifyTrigger *t, int preserve )
	{
	const char* event_name = event->name;
	IValue* value = (IValue*)event->value;

	int ignore_event = 0;
	int reply_event = 0;
	int await_finished = 0;

	await_type *aw = await( );

	if ( aw )
		{
		int found_match = 0;

		/* Look ahead into queued awaits for future handling */
		loop_over_list( await_list, X )
			{
			Agent *la = 0;
			int match_type = 0;
			if ( (la=await_list[X]->agent()) && la == agent &&
			     ! strcmp( await_list[X]->name(), event_name ) )
				{
				if ( (found_match = await_list[X]->SetValue( agent, event_name, value )) )
					{
					reply_event = 1;
					break;
					}
				}
			else if ( (match_type = agent->HasRegisteredInterest( await_list[X]->stmt(), event_name )) )
				{
				if ( (found_match = await_list[X]->SetValue( agent, event_name, value, match_type > 1 ? 1 : 0 )) )
					break;
				}
			}

		if ( ! found_match )
			{
			if ( aw->agent() && aw->agent() == agent &&
			     ! strcmp( aw->name(), event_name ) )
				{
				reply_event = 1;
				await_finished = 1;
				last_reply = value;
				Ref(last_reply);
				}
			else if ( aw->stmt() )
				{
				await_finished = agent->HasRegisteredInterest( aw->stmt(), event_name );

				if ( ! await_finished && aw->only( ) &&
				     ! agent->HasRegisteredInterest( aw->except(), event_name ) )
					ignore_event = 1;
				}
			}
		}

	if ( ! reply_event )
		{
		if ( ignore_event )
			glish_warn->Report( "event ", agent->Name(), ".", event_name,
				      " ignored due to \"await\"" );
		else if ( ! aw || ! aw->agent() || ! await_finished )
			{
			/* We're going to want to keep the event value as a */
			/* field in the agent's AgentRecord.                */
			Ref( value );

			int was_interest = agent->CreateEvent( event_name,
							       value, t, preserve );

			if ( ! was_interest && complain_if_no_interest )
				glish_warn->Report( "event ", agent->Name(), ".",
					      event_name, " (", value,
					      ") dropped" );

			/* process effects of CreateEvent() */
			RunQueue( await_finished );
			}
		}

	Unref( event );
	return await_finished ? 1 : 0;
	}

void Sequencer::NewClientStarted()
	{
	++num_active_processes;
	}


int Sequencer::ShouldSuspend( const char* task_var_ID )
	{
	if ( task_var_ID )
		return suspend_list[task_var_ID];
	else
		// This is an anonymous client - don't suspend.
		return 0;
	}

int Sequencer::EmptyTaskChannel( Task* task, int force_read )
	{
	int status = 0;

	if ( task->Active() )
		{
		Channel* c = task->GetChannel();
		ChanState old_state = c->ChannelState();

		c->ChannelState() = CHAN_IN_USE;

		//
		// Must protect channel, because it can be Unref'ed
		// as part of the call to NewEvent()
		//
		Ref( task );
		Ref( c );
		if ( force_read )
			status = NewEvent( task, recv_event( c->Source(), (FILE*) task->TranscriptFile( ) ));

		while ( status == 0 &&
			c->ChannelState() == CHAN_IN_USE &&
			c->DataInBuffer() )
			{
			status = NewEvent( task, recv_event( c->Source(), (FILE*) task->TranscriptFile( ) ));
			}

		if ( c->ChannelState() == CHAN_INVALID )
			{ // This happens iff the given task has exited
			selector->DeleteSelectee( c->Source().fd() );

			task->CloseChannel( );

			while ( reap_terminated_process() )
				;

			--num_active_processes;
			}

		else
			c->ChannelState() = old_state;

		Unref( c );
		Unref( task );
		}

	return status;
	}


void Sequencer::MakeEnvGlobal( evalOpt &opt )
	{

#ifndef HAVE_CRT_EXTERNS_H
	char** env = environ;
#else
	char** env = *_NSGetEnviron( );
#endif

	IValue* env_value = create_irecord();

	if ( env )
		for ( char** env_ptr = env; *env_ptr; ++env_ptr )
			{
			char* delim = strchr( *env_ptr, '=' );

			if ( delim )
				{
				*delim = '\0';
				IValue *val = new IValue( delim + 1 );
				env_value->AssignRecordElement( *env_ptr, val );
				Unref(val);
				*delim = '=';
				}
			else
				{
				IValue *val = new IValue( glish_false );
				env_value->AssignRecordElement( *env_ptr, val );
				Unref(val);
				}
			}

	Expr* env_expr = LookupID( string_dup( "environ" ), GLOBAL_SCOPE );
	env_expr->Assign( opt, env_value );
	}


void Sequencer::MakeArgvGlobal( evalOpt &opt, char** argv, int argc, int append_name )
	{
	// If there's an initial "--" argument, remove it, it's a vestige
	// from when "--" was needed to separate script files from their
	// arguments.
	if ( argc > 0 && ! strcmp( argv[0], "--" ) )
		++argv, --argc;

	IValue *argv_value = 0;
	if ( ! append_name )
		argv_value = new IValue( (charptr*) argv, argc, COPY_ARRAY );
	else
		{
		char **av = alloc_charptr( argc+1 );
		av[0] = string_dup(name);
		for ( int i = 0; i < argc; i++ )
			av[i+1] = string_dup(argv[i]);
		argv_value = new IValue( (charptr*) av, argc+1 );
		}

	Expr* argv_expr = LookupID( string_dup( "argv" ), GLOBAL_SCOPE );
	argv_expr->Assign( opt, argv_value );
	}


void Sequencer::BuildSuspendList()
	{
	char* suspend_env_list = getenv( "suspend" );

	if ( ! suspend_env_list )
		return;

	char* suspendee = strtok( suspend_env_list, " " );

	while ( suspendee )
		{
		suspend_list.Insert( suspendee, 1 );
		suspendee = strtok( 0, " " );
		}
	}


IValue *Sequencer::Parse( evalOpt &opt, FILE* file, const char* filename, int value_needed )
	{
	restart_yylex( file );

	int orig_scope_len = scopes.length();
	yyin = file;
	current_sequencer = this;
	line_num = 1;

	if ( yyin && isatty( fileno( yyin ) ) )
		{
		glish_message->Report( "Glish version ", GLISH_VERSION, ". " );

		// And add a special Selectee for detecting user input.
		selector->AddSelectee( new UserInputSelectee( fileno( yyin ) ) );
		interactive_set( 1 );
		}
	else
		interactive_set( 0 );

	unsigned short old_file_name = file_name;
	if ( filename )
		{
		glish_files->append(string_dup(filename));
		file_name = glish_files->length()-1;
		}

	NodeUnref( stmts );
	IValue *ret = glish_parser( opt, stmts );

	if ( ret )
		{
		if ( ! in_evaluation( ) ) glish_error->Report( "syntax errors parsing input" );
		SetErrorResult( ret );

		if ( stmts )
			{
			stmt_list del;
			stmts->CollectUnref(del);
			loop_over_list( del, i )
				NodeUnref( del[i] );
			stmts = 0;
			while ( scopes.length() > orig_scope_len )
				PopScope();
			}
		}
	else
		ret = Exec( opt, 1, value_needed );


	line_num = 0;

	file_name = old_file_name;

	return ret;
	}


IValue *Sequencer::Parse( evalOpt &opt, const char file[], int value_needed )
	{
	if ( ! is_regular_file( file ) )
		return (IValue*) ValCtor::error( "\"", file, "\" does not exist or is not a regular file" );

	FILE* f = fopen( file, "r" );

	if ( ! f )
		return (IValue*) ValCtor::error( "can't open file \"", file, "\"" );


	return Parse( opt, f, file, value_needed );
	}

IValue *Sequencer::Parse( evalOpt &opt, const char* strings[], int value_needed )
	{
	scan_strings( strings );
	return Parse( opt, 0, "glish internal initialization", value_needed );
	}

extern void *current_flex_buffer();
extern void *new_flex_buffer( FILE * );
extern void delete_flex_buffer(void*);
extern void set_flex_buffer(void*);
IValue *Sequencer::Eval( evalOpt &opt, const char* strings[] )
	{
	void *old_buf = current_flex_buffer();
	void *new_buf = new_flex_buffer( 0 );
	int is_interactive = interactive( );
	int is_in_eval = in_evaluation( );
	in_evaluation_set(1);
	set_flex_buffer(new_buf);
	ClearStmt();
	scan_strings( strings );
	IValue *ret = Parse( opt, 0, "glish eval", 1 );
	set_flex_buffer(old_buf);
	delete_flex_buffer(new_buf);
	interactive_set(is_interactive);
	in_evaluation_set(is_in_eval);
	return ret;
	}

extern void clear_error();
IValue *Sequencer::Include( evalOpt &opt, const char *file )
	{
	int orig_scope_len = scopes.length();

	expanded_name = which_include( file );

	if ( ! expanded_name )
		{
		glish_error->Report( "could not include '", file, "', file not found" );
		return error_ivalue();
		}
	else if ( include_once.Lookup(expanded_name) )
		{
		free_memory( expanded_name );
		expanded_name = 0;
		return new IValue( glish_true );
		}

	if ( ! is_regular_file( expanded_name ) )
		{
		free_memory( expanded_name );
		expanded_name = 0;
		return (IValue*) ValCtor::error( "\"",file, "\" does not exist or is not a regular file" );
		}

	FILE *fptr = fopen( expanded_name, "r");

	if ( ! fptr )
		{
		free_memory( expanded_name );
		expanded_name = 0;
		return (IValue*) ValCtor::error( file, " not found" );
		}

	if ( VERB_INCL(verbose_mask) )
		std::cerr << "vi " << expanded_name << std::endl;

	unsigned short old_file_name = file_name;
	glish_files->append(string_dup(file));
	file_name = glish_files->length()-1;

	void *old_buf = current_flex_buffer();
	void *new_buf = new_flex_buffer( fptr );
	int is_interactive = interactive( );
	set_flex_buffer(new_buf);
	unsigned short old_line_num = line_num;
	line_num = 1;


	glish_error->SetCount(0);
	interactive_set( 0 );

	NodeUnref( stmts );
	IValue *ret = glish_parser( opt, stmts );

	if ( ! ret )
		{
		int stack_length = stack.length();
		stack_type *incst = new stack_type;
		PushFrames( incst );

		if ( glish_include_jmpbuf_set )
			{
			ret = Exec( opt, 1, 1 );
			const stack_type *xsx = 0;
			if ( (xsx = PopFrames( )) != incst )
				glish_fatal->Report("stack inconsistency in Sequencer::Include");
			}
		else
			{
			if ( setjmp(glish_include_jmpbuf) == 0 )
				{
				glish_include_jmpbuf_set = 1;
				ret = Exec( opt, 1, 1 );
				if ( PopFrames( ) != incst )
					glish_fatal->Report("stack inconsistency in Sequencer::Include");
				}
			else
				{
				// we were interrupted by a ^C
				ret = 0;
				while ( stack.length() > stack_length )
					PopFrames();
				}

			glish_include_jmpbuf_set = 0;
			}

		delete incst;
		if ( ret && ret->Type() != TYPE_FAIL )
			{
			Unref( ret );
			ret = 0;
			}
		}
	else
		{
		if ( include_once.Lookup(expanded_name) )
			free_memory( include_once.Remove(expanded_name) );

		if ( stmts )
			{
			stmt_list del;
			stmts->CollectUnref(del);
			loop_over_list( del, i )
				NodeUnref( del[i] );
			stmts = 0;
			while ( scopes.length() > orig_scope_len )
				PopScope();
			}
		}

	free_memory( expanded_name );
	expanded_name = 0;

	line_num = old_line_num;
	file_name = old_file_name;

	clear_error();
	glish_error->SetCount(0);
	set_flex_buffer(old_buf);
	delete_flex_buffer(new_buf);
	fclose( fptr );
	interactive_set( is_interactive );
	return ret;
	}

void Sequencer::IncludeOnce( )
	{
	if ( expanded_name && ! include_once.Lookup(expanded_name) )
		include_once.Insert(string_dup(expanded_name), 1);
	}

RemoteDaemon* Sequencer::CreateDaemon( const char* host )
	{
	int err = 0;
	RemoteDaemon* rd = OpenDaemonConnection( host, err );
	if ( err ) return 0;

	if ( rd )
		// We're all done, the daemon was already running.
		return rd;

	RemoteDaemon *ret = new RemoteDaemon( host, start_remote_daemon(host) );
	daemons.Insert( string_dup( host ), ret );
	selector->AddSelectee(new DaemonSelectee( ret, selector, this ) );
	return ret;
	}

RemoteDaemon* Sequencer::OpenDaemonConnection( const char* host, int &err )
	{
	RemoteDaemon *r = 0;
	err = 0;
	const char *h = host;

	if ( ! strcmp(h,"localhost") )
		h = ConnectionHost();

	//
	// update the key directory before using if necessary
	//
#if USENPD
	if ( System().KeyDir() )
		set_key_directory( System().KeyDir() );
#endif
	if ( (r = connect_to_daemon( h, err )) )
		{
		daemons.Insert( string_dup( host ), r );
		selector->AddSelectee(new DaemonSelectee( r, selector, this ) );
		}

	return r;
	}


void Sequencer::ActivateMonitor( char* monitor_client_name )
	{
	TaskAttr* monitor_attrs =
		new TaskAttr( "*monitor*", "localhost", 0 );

	const_args_list monitor_args;
	monitor_args.append( new IValue( monitor_client_name ) );

	monitor_task = new ClientTask( &monitor_args, monitor_attrs, this );

	if ( monitor_task->TaskError() )
		{
		Unref( monitor_task );
		monitor_task = 0;
		}
	}


void Sequencer::LogEvent( const char* gid, const char* id,
			const char* event_name, const IValue* event_value,
			int is_inbound )
	{
	if ( ! monitor_task )
		return;

	IValue gid_value( gid );
	IValue id_value( id );
	IValue name_value( event_name );

	parameter_list args;

	ConstExpr gid_expr( &gid_value ); Ref( &gid_value );
	ConstExpr id_expr( &id_value ); Ref( &id_value );
	ConstExpr name_expr( &name_value ); Ref( &name_value );
	ConstExpr value_expr( event_value ); Ref( (IValue*) event_value );

	Parameter gid_param((const char *) "glish_id", VAL_VAL, &gid_expr, 0 ); Ref( &gid_expr );
	Parameter id_param((const char *) "id", VAL_VAL, &id_expr, 0 ); Ref( &id_expr );
	Parameter name_param((const char *) "name", VAL_VAL, &name_expr, 0 ); Ref( &name_expr );
	Parameter value_param((const char *) "value", VAL_VAL, &value_expr, 0 ); Ref( &value_expr );

	args.insert( &name_param );
	args.insert( &id_param );
	args.insert( &gid_param );
	args.insert( &value_param );

	const char* monitor_event_name = is_inbound ? "event_in" : "event_out";
	monitor_task->SendEvent( monitor_event_name, &args, 0, 0 );
	}

void Sequencer::LogEvent( const char* gid, const char* id, const GlishEvent* e,
			int is_inbound )
	{
	LogEvent( gid, id, e->name, (IValue*) (e->value), is_inbound );
	}


void Sequencer::SystemEvent( const char* name_, const IValue* val_ )
	{
	system_agent->SendSingleValueEvent( name_, val_, Agent::mLOG() | Agent::mOVERRIDE() );
	}


void Sequencer::Rendezvous( const char* event_name, IValue* value )
	{
	char* source_id;
	char* sink_id;

	if ( ! value->FieldVal( "source_id", source_id ) ||
	     ! value->FieldVal( "sink_id", sink_id ) )
		glish_fatal->Report( "bad internal", event_name, "event" );

	Task* src = ids_to_tasks[source_id];
	Task* snk = ids_to_tasks[sink_id];

	if ( ! src || ! snk )
		glish_fatal->Report( "no such source or sink ID in internal",
				event_name, "event:", source_id, sink_id );

	// By sending out these two events immediately, before any other
	// *rendezvous* events can arise, we impose a serial ordering on
	// all rendezvous.  This avoids deadlock.
	//
	// Actually, now that we always use sockets (even locally), the
	// following isn't necessary, since connecting to a socket won't
	// block (unless the "listen" queue for the remote socket is
	// full).  We could just pass along the *rendezvous-resp* event
	// to the sink and be done with it.  But we retain the protocol
	// because it was a lot of work getting it right and we don't want
	// to have to figure it out again if for some reason we don't
	// always use sockets.
	src->SendSingleValueEvent( "*rendezvous-orig*", value, Agent::mLOG( ) );
	snk->SendSingleValueEvent( "*rendezvous-resp*", value, Agent::mLOG( ) );

	delete source_id;
	delete sink_id;
	}


void Sequencer::ForwardEvent( const char* event_name, IValue* value )
	{
	char* receipient_id;
	char* new_event_name;

	if ( ! value->FieldVal( "receipient", receipient_id ) ||
	     ! value->FieldVal( "event", new_event_name ) )
		glish_fatal->Report( "bad internal event \"", event_name, "\"" );

	Task* task = ids_to_tasks[receipient_id];

	if ( ! task )
		glish_fatal->Report( "no such receipient ID in ", event_name,
				"internal event:", receipient_id );

	task->SendSingleValueEvent( new_event_name, value, Agent::mLOG( ) );

	delete receipient_id;
	delete new_event_name;
	}


int Sequencer::EventLoop( int in_await )
	{
	RunQueue();

	if ( pending_task )
		{
		EmptyTaskChannel( pending_task );

		// We Ref()'d the pending_task when assigning it, to make
		// sure it didn't go away due to the effects of RunQueue().

		Unref( pending_task );

		pending_task = 0;
		}

	while ( ! selector->DoSelection( this ) )
		{
		RunQueue();
		}

	return ActiveClients();
	}

int Sequencer::PendingEventLoop( )
	{
	while ( notification_queue.length() )
		RunQueue();

	return ActiveClients();
	}

void Sequencer::RunQueue( int await_ended )
	{
	if ( hold_queue ) return;

	Notification* n;

	while ( (n = notification_queue.DeQueue()) )
		{
		if ( ! n->valid )
			{
			Unref( n );
			continue;
			}

		if ( verbose > 1 )
			glish_message->Report( "doing", n );

		if ( n->notifiee->stack() )
			PushFrames( n->notifiee->stack() );
		else if ( n->notifiee->frame() )
			PushFrame( n->notifiee->frame() );

		IValue* notifier_val = n->notifier->AgentRecord();

		if ( notifier_val && n->notifier->PreserveEvents() &&
		     notifier_val->Type() == TYPE_RECORD &&
		     notifier_val->HasRecordElement( n->field ) != n->value )
			// Need to assign the event value.
			notifier_val->AssignRecordElement( n->field, n->value );

		int sticky = n->type() == Notification::STICKY;
		if ( await_ended ) n->type(Notification::AWAIT);

		// There are a bunch of Ref's and Unref's here because the
		// Notify() call below can lead to a recursive call to this
		// routine (due to an "await" statement), so 'n' might
		// otherwise be deleted underneath our feet.
		Ref( n );
		Ref( n->notifiee );
		if ( notifier_val ) Ref(notifier_val);
		Ref(n->notifiee->stmt());
		//
		// PushNote() doesn't do a Ref()
		//
		PushNote( n );

		n->notifiee->stmt()->Notify( n->notifier );

		if ( n->notifiee->stack() )
			{
			if ( n->notifiee->stack() != PopFrames( ) )
				glish_fatal->Report( "stack inconsistency in Sequencer::RunQueue" );
			}
		else if ( n->notifiee->frame() )
			(void) PopFrame();

		if ( n->trigger )
			n->trigger->NotifyDone( );

		Unref(n->notifiee->stmt());
		Unref(notifier_val);
		Unref( n->notifiee );
		Unref( n );
		//
		// PopNote() does does one Unref() of "n"
		//
		if ( ! await_ended && ! sticky )
			PopNote( );
		}

	}

int Sequencer::CurWheneverIndex( )
	{
	int len = cur_whenever.length();
	if ( len <= 0 ) return -1;
	return cur_whenever[len-1]->Index();
	}

void Sequencer::ClearWhenevers( )
	{
	int len = cur_whenever.length();
	while ( len > 0 )
		cur_whenever.remove_nth(--len);
	}

void Sequencer::AbortOccurred( )
	{
	if ( ! shutdown_posted )
		{
		shutdown_posted = 1;
		IValue exit_val(glish_true);
		SystemEvent( "exit", &exit_val );
		RunQueue( );
		}

	System().AbortOccurred();
	}

ClientSelectee::ClientSelectee( Sequencer* s, Task* t )
    : Selectee( t->GetChannel()->Source().fd() )
	{
	sequencer = s;
	task = t;
	}

int ClientSelectee::NotifyOfSelection()
	{
	return sequencer->EmptyTaskChannel( task, 1 );
	}


LocalClientSelectee::LocalClientSelectee( Sequencer* s, Channel* c )
    : Selectee( c->Source().fd() )
	{
	sequencer = s;
	chan = c;
	}

int LocalClientSelectee::NotifyOfSelection()
	{
	(void) sequencer->NewConnection( chan );
	return 0;
	}


SendSelectee::SendSelectee( Selector *s, sos_status *ss_, Selectee *old_ ) :
				Selectee( ss_->fd(), Selectee::WRITE )
	{
	selector = s;
	ss = ss_;
	old = old_;
	}

int SendSelectee::NotifyOfSelection()
	{
	if ( ! ss->resume( ) )
		selector->DeleteSelectee( ss->fd(), old );

	return 0;
	}


AcceptSelectee::AcceptSelectee( Sequencer* s, Socket* conn_socket )
    : Selectee( conn_socket->FD() )
	{
	sequencer = s;
	connection_socket = conn_socket;
	}

int AcceptSelectee::NotifyOfSelection()
	{
	int new_conn;

	if ( connection_socket->IsLocal() )
		new_conn = accept_local_connection( connection_socket->FD() );
	else
		new_conn = accept_connection( connection_socket->FD() );

	mark_close_on_exec( new_conn );

	(void) sequencer->NewConnection( new Channel( new_conn, new_conn ) );

	return 0;
	}


ScriptSelectee::ScriptSelectee( ScriptClient* client, Agent* agent, int conn_socket )
    : Selectee( conn_socket )
	{
	script_client = client;
	script_agent = agent;
	connection_socket = conn_socket;
	}

int ScriptSelectee::NotifyOfSelection()
	{
	fd_set fdmask;

	FD_ZERO( &fdmask );
	FD_SET( connection_socket, &fdmask );

	GlishEvent* e = script_client->NextEvent( &fdmask );
	script_client->AddEventSources();

	if ( ! e )
		{
		delete script_client;
		exit( 0 );
		}

	// Ref() the value, since CreateEvent is going to Unref() it, and the
	// script_client is also going to Unref() it via Unref()'ing the
	// whole GlishEvent.
	Ref( e->value );

	script_agent->CreateEvent( e->name, (IValue*)(e->value) );

	return 0;
	}

int PagerSelectee::NotifyOfSelection( )
	{
	seq->PagerDone( );
	return 1;
	}

DaemonSelectee::DaemonSelectee( RemoteDaemon* arg_daemon, Selector* sel,
				Sequencer* s )
: Selectee( arg_daemon->DaemonChannel()->Source().fd() )
	{
	daemon = arg_daemon;
	selector = sel;
	if ( selector )
		Ref( selector );
	sequencer = s;
	}

DaemonSelectee::~DaemonSelectee()
	{
	Unref( selector );
	}

int DaemonSelectee::NotifyOfSelection()
	{
	sos_fd_source &daemon_fd = daemon->DaemonChannel()->Source();
	GlishEvent* e = recv_event( daemon_fd );

	const char* message_name = 0;

	if ( e )
		{
		if ( ! strcmp( e->name, "probe-reply" ) )
			{
			if ( daemon->State() == DAEMON_LOST )
				{
				glish_message->Report( "connectivity to daemon @ ",
						daemon->Host(), " restored" );
				message_name = "connection_restored";
				}

			daemon->SetState( DAEMON_OK );
			}

		else
			{
			if ( strcmp( e->name, "established" ) )
				glish_error->Report( "received unsolicited message from daemon @ ",
					       daemon->Host(), ", [", e->name, "]"  );
			}

		Unref( e );
		}

	else
		{
		glish_error->Report( "Glish daemon @ ", daemon->Host(),
				" terminated" );
		selector->DeleteSelectee( daemon_fd.fd() );
		message_name = "daemon_terminated";
		}

	if ( message_name )
		{
		IValue message_val( daemon->Host() );
		sequencer->SystemEvent( message_name, &message_val );
		}

	return 0;
	}


ProbeTimer::ProbeTimer( PDict(RemoteDaemon)* arg_daemons, Sequencer* s )
: SelectTimer( PROBE_DELAY, 0, PROBE_INTERVAL, 0 )
	{
	daemons = arg_daemons;
	sequencer = s;
	probe_interval = (double) PROBE_INTERVAL;
	if ( probe_interval != sequencer->System().ClientPing() )
		UpdateInterval();
	}

int ProbeTimer::DoExpiration()
	{
	IterCookie* c = daemons->InitForIteration();

	RemoteDaemon* r;
	const char* key;
	while ( (r = daemons->NextEntry( key, c )) )
		{
		if ( r->State() == DAEMON_REPLY_PENDING )
			{ // Oops.  Haven't gotten a reply from our last probe.
			glish_warn->Report( "connection to Glish daemon @ ", key,
					" lost" );
			r->SetState( DAEMON_LOST );

			IValue message_val( r->Host() );
			sequencer->SystemEvent( "connection_lost",
						&message_val );
			}

		// Probe the daemon, regardless of its state.
		send_event( r->DaemonChannel()->Sink(), "probe",
				false_value );

		if ( r->State() == DAEMON_OK )
			r->SetState( DAEMON_REPLY_PENDING );
		}

	if ( probe_interval != sequencer->System().ClientPing() )
		UpdateInterval();

	return 1;
	}

void ProbeTimer::UpdateInterval( )
	{
	double new_interval = sequencer->System().ClientPing();
	if ( new_interval != probe_interval )
		{
		probe_interval = new_interval;
		interval_t.tv_sec = (long) probe_interval;
		interval_t.tv_usec = (long) (( probe_interval - (long) probe_interval ) * 1000000);
		}
	}

ScriptClient::ScriptClient( int& argc, char** argv, Client::ShareType multi, Client::PersistType persist,
			    const char *script_file ) : Client( argc, argv, multi, persist, script_file )
	{
	selector = 0;
	agent = 0;
	}

ScriptClient::~ScriptClient( )
	{
	loop_over_list( event_src_list, i )
		delete event_src_list[i];
	Unref( selector );
	}

void ScriptClient::SetInterface( Selector* s, Agent* a )
	{
	selector = s;
	if ( selector )
		Ref( selector );
	agent = a;
	AddEventSources();
	}

void ScriptClient::AddEventSources()
	{
	int got_src = 0;

	if ( event_src_list.length() == event_sources.length() )
		return;

	loop_over_list( event_sources, i )
		{
		if ( ! strcmp( event_sources[i]->Context().id(), interpreter_tag ) )
			got_src++;
		if ( ! event_src_list.is_member((char*)event_sources[i]->Context().id()) )
			{
			selector->AddSelectee( new ScriptSelectee( this, agent, event_sources[i]->Source().fd() ) );
			event_src_list.append(string_dup(event_sources[i]->Context().id()));
			}
		}

	if ( ! got_src )
		selector->AddSelectee( new ScriptSelectee( this, agent, fileno( stdin ) ) );

	}

void ScriptClient::FD_Change( int fd, int add_flag )
	{
	if ( ! agent )
		return;

	if ( add_flag )
		selector->AddSelectee( new ScriptSelectee( this, agent, fd ) );
	else
		selector->DeleteSelectee( fd );
	}

void EnvHolder::put( const char *var, char *string )
	{
	char *old = strings.Lookup( var );
	if ( old == string ) return;
	strings.Insert( old ? var : string_dup( var ), string );
	putenv( string );
	if ( old ) free_memory( old );
	}

char* which_include( const char* filename )
	{
	charptr *paths = Sequencer::CurSeq()->System().Include();
	int len = Sequencer::CurSeq()->System().IncludeLen();

	if ( ! paths || filename[0] == '/' || filename[0] == '.' )
		{
		if ( access( filename, R_OK ) == 0 )
			return canonic_path( filename );
		else
			return 0;
		}

	char directory[1024];

	for ( int i = 0; i < len; i++ )
		if ( paths[i] && strlen(paths[i]) )
			{
			sprintf( directory, "%s/%s", paths[i], filename );

			if ( access( directory, R_OK ) == 0 )
				return string_dup( directory );
			}

	return 0;
	}
