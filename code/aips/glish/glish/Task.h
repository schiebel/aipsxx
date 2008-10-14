// $Id: Task.h,v 19.12 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
#ifndef task_h
#define task_h

#include "Agent.h"
#include "BuiltIn.h"
#include "LocalExec.h"

class Channel;
class Selector;
class GlishEvent;
class ProxyTask;

class TaskAttr GC_FINAL_CLASS {
    public:
	TaskAttr( char* arg_ID, char* hostname, Channel* daemon_channel,
		  int async_flag=0, int ping_flag=0, int suspend_flag=0, int force_sockets=0,
		  const char *name_ = 0, char *transcript_=0, int loaded_client_flag=0 );

	~TaskAttr();
	void OpenTranscript( );

	char* task_var_ID;
	char* hostname;
	Channel* daemon_channel;		// null for local invocation
	int async_flag;
	int ping_flag;
	int suspend_flag;
	int useshm;
	char *name;
	int force_sockets;
	char *transcript;
	void *transcript_file;
	int pid;
	int loaded_client;
	};

class Task : public ProxySource {
    public:
	Task( TaskAttr* task_attrs, Sequencer* s, int DestructLast=0 );
	~Task();

	void SendTerminate( );

	const char* Name() const	{ return name; }
	const char* TaskID() const	{ return id; }
	int         TaskIDi() const	{ return idi; }
	const char* Host() const	{ return attrs->hostname; }
	int NoSuchProgram() const	{ return no_such_program; }
	Executable* Exec() const	{ return executable; }
	int TaskError() const		{ return task_error; }

	// Bundling of events is done with this first SendEvent() to
	// avoid double bundling of events, i.e. in ProxyTask and Task.
	IValue* SendEvent( const char* event_name, parameter_list* args,
			int is_request, u_long flags, Expr *from_subsequence=0 );
	IValue* SendEvent( const char* event_name, parameter_list* args,
			int is_request, u_long flags, const ProxyId &proxy_id );
	IValue* SendEvent( const char* event_name, IValue *&event_val,
			int is_request=0, u_long flags=0,
			const ProxyId &proxy_id=glish_proxyid_dummy,
			int is_bundle=0 );

	// Returns non-zero on success
	int BundleEvents( int howmany=0 );
	int FlushEvents( );

	int  GetPid( ) const    { return attrs->pid; }
	void SetPid( int pid )  { attrs->pid = pid; }

	void *TranscriptFile( ) { return attrs->transcript ? getTranscriptFile( ) : 0; }

	void SetChannel( Channel* c, Selector* s );
	void CloseChannel();
	Channel* GetChannel() const	{ return channel; }

	int Protocol() const	{ return protocol; }
	void SetProtocol( int arg_protocol )	{ protocol = arg_protocol; }

	Task* AgentTask();

	int Describe( OStream &s, const ioOpt &opt ) const;
	int Describe( OStream &s ) const
		{ return Describe( s, ioOpt() ); }

	virtual void sendEvent( sos_sink &fd, const char* event_name,
			const GlishEvent* e, int can_suspend,
			const ProxyId &proxy_id=glish_proxyid_dummy );

	void sendEvent( sos_sink &fd, const char* event_name, const GlishEvent* e,
			const ProxyId &proxy_id=glish_proxyid_dummy )
		{ sendEvent( fd, event_name, e, 1, proxy_id ); }

	void sendEvent( sos_sink &fd, const GlishEvent* e, int can_suspend,
			const ProxyId &proxy_id=glish_proxyid_dummy )
		{ sendEvent( fd, e->name, e, can_suspend, proxy_id ); }

	void sendEvent( sos_sink &fd, const GlishEvent* e,
			const ProxyId &proxy_id=glish_proxyid_dummy )
		{ sendEvent( fd, e->name, e, 1, proxy_id ); }

	void sendEvent( sos_sink &fd, const char* nme, const Value* value,
			int can_suspend = 1, const ProxyId &proxy_id=glish_proxyid_dummy )
		{
		GlishEvent e( nme, value );
		sendEvent( fd, &e, can_suspend, proxy_id );
		}

	void AbnormalExit( int );

    protected:
	// Creates and returns an argv vector with room for num_args arguments.
	// The program name and any additional, connection-related arguments
	// are added to the beginning and upon return "argc" holds the
	// total number of arguments.  Thus the non-connection arguments
	// can be put in positions argc-num_args through argc-1.
	//
	// The return value should be deleted when done with.
	const char** CreateArgs( const char* prog, int num_args, int& argc );

	void Exec( const char** argv );

	void SetActivity( State );

	void *getTranscriptFile( );

	char* name;
	char* id;
	int idi;
	TaskAttr* attrs;
	Channel* channel;
	Channel* local_channel;	// used for local tasks
	int no_such_program;
	Selector* selector;

	// Events that we haven't been able to send out yet because
	// our associated task hasn't yet connected to the interpreter.
	event_list* pending_events;

	Executable* executable;
	int task_error;	// true if any problems occurred

	int protocol;	// which protocol the client speaks, or 0 if not known

	// Pipes used for local connections.
	int pipes_used;
	int read_pipe[2], write_pipe[2];
	char* read_pipe_str;
	char* write_pipe_str;

	recordptr bundle;
	int       bundle_size;
	};


class ShellTask : public Task {
    public:
	ShellTask( const_args_list* args, TaskAttr* task_attrs, Sequencer* s );
	};

class ClientTask : public Task {
    public:
	ClientTask( const_args_list* args, TaskAttr* task_attrs, Sequencer* s, int shm_flag=0 );
	void sendEvent( sos_sink &fd, const char* event_name,
			const GlishEvent* e, int can_suspend = 1,
			const ProxyId &proxy_id=glish_proxyid_dummy );
    protected:
	int useshm;
	void CreateAsyncClient( const char** argv );
	};

class CreateTaskBuiltIn : public BuiltIn {
    public:
	CreateTaskBuiltIn( Sequencer* arg_sequencer )
	    : BuiltIn("create_task", NUM_ARGS_VARIES)
		{ sequencer = arg_sequencer; }

	IValue* DoCall( evalOpt &opt, const_args_list* args_val );
	void DoSideEffectsCall( evalOpt &opt, const_args_list* args_val,
				int& side_effects_okay );

    protected:
	// Extract a string from the given value, or if it indicates
	// "default" (by being equal to F) return 0.
	char* GetString( const IValue* val );

	// 'argv' represents the parameters to start a "script client",
	// this function goes through these arguments and expands the
	// path to the glish script.
	const char* ExpandScript( int start, const_args_list &args_val );

	// Execute the given command locally and synchronously, with the
	// given string as input, and return a Value holding the result.
	IValue* SynchronousShell( const char* command, const char* input );

	// Same except execute the command remotely.
	IValue* RemoteSynchronousShell( const char* command,
					IValue* input );

	// Read the shell output appearing on "shell" due to executing
	// "command" and return a Value representing the result.  Used
	// by SynchronousShell() and RemoteSynchronousShell().  "is_remote"
	// is a flag that if true indicates that the shell is executing
	// remotely.
	IValue* GetShellCmdOutput( const char* command, FILE* shell,
					int is_remote );

	// Read the next line from a local or remote (respectively)
	// synchronous shell command.
	char* NextLocalShellCmdLine( FILE* shell, char* line_buf );
	char* NextRemoteShellCmdLine( char* line_buf );

	// Create an asynchronous shell or client.
	IValue* CreateAsyncShell( const_args_list* args );
	IValue* CreateClient( const_args_list* args, int shm_flag );
	IValue* CreateLoadedClient( const_args_list* args );

	// Check to see whether the creation of the given task was
	// successful. Returns 0 if creation was successful, or an
	// error (non-zero pointer) if it failed.
	IValue *CheckTaskStatus( Task* task );

	Sequencer* sequencer;
	TaskAttr* attrs;	// attributes for task currently being created
	};

class TaskLocalExec : public LocalExec {
    public:
	TaskLocalExec( const char* arg_executable, const char** argv, Task *t ) :
			LocalExec( arg_executable, argv ), task(t) { }
	TaskLocalExec( const char* arg_executable, Task *t ) :
			LocalExec( arg_executable ), task(t) { }

	void AbnormalExit( int );

    protected:
	Task *task;
	};

// True if both tasks are executing on the same host.
extern int same_host( Task* t1, Task* t2 );

#endif	/* task_h */
