// $Id: Task.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,1998,2000 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: Task.cc,v 19.13 2004/11/03 20:38:59 cvsmgr Exp $")
#include "system.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#if HAVE_OSFCN_H
#include <osfcn.h>
#endif

#include "Channel.h"
#include "Select.h"
#include "RemoteExec.h"
#include "Task.h"
#include "LdAgent.h"
#include "Sequencer.h"
#include "Glish/Reporter.h"


class Serialize GC_FINAL_CLASS {
    public:
	Serialize( const_args_list &argv_, int start = 0 ) : argv(argv_),
			list_element(start), str_element(0) { }
	const char *get( )
		{ return list_element >= argv.length() ? 0 :
		  argv[list_element]->StringPtr(0)[str_element]; }
	void set( char * );

	Serialize &operator++( );
	Serialize &operator++( int )
		{ return (*this).operator++( ); }

    protected:
	const_args_list &argv;
	int list_element;
	int str_element;
};

Serialize &Serialize::operator++( )
	{
	if ( list_element < argv.length() &&
	     ++str_element >= argv[list_element]->Length() )
		{
		str_element = 0;
		while ( ++list_element < argv.length() &&
			! argv[list_element]->Length() );
		}

	return *this;
	}
	
void Serialize::set( char *new_string )
	{
	if ( list_element >= argv.length() ||
	     str_element >= argv[list_element]->Length() )
		return;
	const char **ary = argv[list_element]->StringPtr( );
	free_memory( (char*) ary[str_element] );
	ary[str_element] = new_string;
	}

Task::Task( TaskAttr* task_attrs, Sequencer* s, int DestructLast ) : ProxySource( s, DestructLast )
	{
	attrs = task_attrs;
	pending_events = 0;
	channel = 0;
	local_channel = 0;
	selector = 0;
	task_error = 1;
	no_such_program = 1;
	executable = 0;
	name = 0;
	read_pipe_str = write_pipe_str = 0;
	pipes_used = 0;

	active = sINITIAL;	// not sACTIVE till we get a .established event
	protocol = 0;		// not set until Client establishes itself

	bundle = 0;
	bundle_size = 0;

	id = sequencer->RegisterTask( this, idi );

	if ( attrs->task_var_ID )
		agent_ID = attrs->task_var_ID;
	else
		agent_ID = id;
	}

void Task::SendTerminate( )
	{
	IValue tru(glish_true);
	SendSingleValueEvent( "terminate", &tru, Agent::mLOG( ) );
	if ( executable ) executable->Deactivate( );
	}

Task::~Task()
	{
	SendTerminate();

	sequencer->DeleteTask( this );

	CloseChannel();

	delete pending_events;

	delete attrs;
	free_memory( name );
	delete executable;

	free_memory( read_pipe_str );
	free_memory( write_pipe_str );

	Unref( selector );
	}

IValue* Task::SendEvent( const char* event_name, IValue *&event_val,
			int is_request, u_long flags, const ProxyId &proxy_id, int is_bundle )
	{
	if ( task_error )
		return is_request ? error_ivalue() : 0;

	IValue* result = 0;

	if ( is_request && ! channel )
		{ // We need to synchronize; wait for the task to connect.
		if ( local_channel )
			{ // Okay, already have a channel, just connect.
			(void) sequencer->NewConnection( local_channel );
			channel = local_channel;
			}

		else
			channel = sequencer->WaitForTaskConnection( this );

		if ( ! channel )
			// Connection problem, bail out.
			return error_ivalue();
		}

	if ( &proxy_id != &glish_proxyid_dummy )
		{
		recordptr rec = create_record_dict( );
		rec->Insert(string_dup("id"), new IValue((int*)proxy_id.array(),ProxyId::len(),COPY_ARRAY));
		rec->Insert(string_dup("value"), event_val);
		event_val = new IValue(rec);
		}

	if ( ! channel )
		{
		if ( ! pending_events )
			pending_events = new event_list;

		GlishEvent *e = new GlishEvent( string_dup(event_name), copy_value(event_val) );

		if ( &proxy_id != &glish_proxyid_dummy )
			e->SetIsProxy( );
		if ( is_request )
			e->SetIsRequest();
		if ( is_bundle )
			e->SetIsBundle();

		// will need to keep track of proxy_id's if pending_events
		// is ever made to work with request/reply events.
		pending_events->append( e );
		}

	else
		{
		sos_fd_sink &sink = channel->Sink();

		if ( Agent::mLOG(flags) )
			sequencer->LogEvent( id, name, event_name, event_val, 0 );

		if ( is_request )
			{
			const char* fmt = "*%s-reply*";
			char* reply_name = alloc_char( strlen( event_name ) + strlen( fmt ) + 1 );
			sprintf( reply_name, fmt, event_name );

			IValue* new_val = create_irecord();
			new_val->SetField( "*request*", event_val );
			new_val->SetField( "*reply*", reply_name );

			Unref( event_val );
			event_val = new_val;

			GlishEvent e( event_name, (const Value*)event_val );
			e.SetIsRequest();

			if ( is_bundle ) e.SetIsBundle( );

			Agent *agent = this;
			if ( &proxy_id != &glish_proxyid_dummy )
				{
				e.SetIsProxy( );
				agent = GetProxy( proxy_id );
				if ( ! agent )
					return (IValue*) Fail( "bad proxy identifier" );
				}

			sendEvent( sink, &e, 0, ProxyId(sequencer->pid(),idi,0) );

			result = sequencer->AwaitReply( agent, event_name,
							reply_name );
			free_memory( reply_name );
			}

		else
			{
			GlishEvent e( event_name, (const Value*) event_val );
			if ( is_bundle ) e.SetIsBundle( );
			if ( &proxy_id != &glish_proxyid_dummy ) e.SetIsProxy( );
			sendEvent( sink, &e, ProxyId(sequencer->pid(),idi,0) );
			}
		}

	return result;
	}

IValue* Task::SendEvent( const char* event_name, parameter_list* args,
			int is_request, u_long flags, const ProxyId &proxy_id )
	{
	if ( task_error )
		return is_request ? error_ivalue() : 0;

	IValue* event_val = BuildEventValue( args, 1 );

	IValue* result = SendEvent( event_name, event_val, is_request, flags, proxy_id );

	Unref( event_val );

	return result;
	}

IValue *Task::SendEvent( const char* event_name, parameter_list* args,
			 int is_request, u_long flags, Expr */* from_subsequence */ )
	{
	if ( bundle_size )
		{
		if ( is_request )
			{
			FlushEvents( );
			return SendEvent( event_name, args, is_request, flags, glish_proxyid_dummy );
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
		return SendEvent( event_name, args, is_request, flags, glish_proxyid_dummy );
	}

int Task::BundleEvents( int howmany )
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

int Task::FlushEvents( )
	{
	if ( bundle && bundle->Length() > 0 )
		{
		IValue *val = new IValue( bundle );
		SendEvent( "event-bundle", val, 0, Agent::mLOG( ), glish_proxyid_dummy, 1 );
		Unref( val );
		bundle = 0;
		}
	return 1;
	}


void Task::SetChannel( Channel* c, Selector* s )
	{
	channel = c;
	selector = s;
	if ( selector )
		Ref( selector );

	channel->Sink().nonblock( );

	if ( pending_events )
		{
		loop_over_list( *pending_events, i )
			{
			GlishEvent* e = (*pending_events)[i];

			sequencer->LogEvent( id, name, e, 0 );

			send_event( channel->Sink(), e, (FILE*) TranscriptFile( ) );

			Unref( e );
			}

		pending_events = 0;
		}
	}

void Task::CloseChannel()
	{
	if ( channel )
		{
		//
		// this is now just used as a flag
		// to Sequencer::EmptyTaskChannel
		//
		channel->ChannelState() = CHAN_INVALID;
		selector->DeleteSelectee( channel->Source().fd() );
		Unref( channel );
		channel = 0;
		}
	}

Task* Task::AgentTask()
	{
	return this;
	}

int Task::Describe( OStream& s, const ioOpt &opt ) const
	{
	if ( opt.prefix() ) s << opt.prefix();
	s << "task " << Name();
	return 1;
	}

const char** Task::CreateArgs( const char* prog, int num_args, int& argc )
	{
	argc = num_args;

	int use_socket = attrs->daemon_channel || attrs->async_flag || attrs->force_sockets;

	// Leave room for the executable's name, the -id flag, the id,
	// the -interpreter flag, and the interpreter's tag.
	argc += 5;

	if ( use_socket )
		// Leave room for -host <host> -port <port>
		argc += 4;
	else
		// Local exec, leave room for -pipes <input> <output>
		argc += 3;

	if ( attrs->suspend_flag )
		++argc;		// room for -suspend flag

	if ( attrs->ping_flag )
		++argc;		// room for -ping flag

	if ( attrs->useshm )
		++argc;		// room for -useshm flag

	if ( attrs->transcript )
		argc += 2;	// room for transcript file

	argc += 1;		// room for the end of client args

				// + 1 for final nil
	charptr *argv = (charptr*) alloc_charptr( argc + 1 );
	int argp = 0;

	argv[argp++] = prog;

	argv[argp++] = "-id";
	argv[argp++] = id;

	if ( use_socket )
		{
		pipes_used = 0;

		argv[argp++] = "-host";
		argv[argp++] = sequencer->ConnectionHost();

		argv[argp++] = "-port";
		argv[argp++] = sequencer->ConnectionPort();
		}

	else
		{
		if ( pipe( read_pipe ) < 0 || pipe( write_pipe ) < 0 )
			perror( "glish: problem creating pipe" );

		pipes_used = 1;

		mark_close_on_exec( read_pipe[0] );
		mark_close_on_exec( write_pipe[1] );

		argv[argp++] = "-pipes";

		char buf[64];
		sprintf( buf, "%d", write_pipe[0] );
		argv[argp++] = write_pipe_str = string_dup( buf );

		sprintf( buf, "%d", read_pipe[1] );
		argv[argp++] = read_pipe_str = string_dup( buf );
		}

	argv[argp++] = "-interpreter";
	argv[argp++] = sequencer->InterpreterTag();

	if ( attrs->suspend_flag )
		argv[argp++] = "-suspend";

	if ( attrs->ping_flag )
		argv[argp++] = "-ping";

	if ( ! use_socket && attrs->useshm )
		argv[argp++] = "-useshm";

	if ( attrs->transcript )
		{
		argv[argp++] = "-transcript";
		argv[argp++] = attrs->transcript;
		}
	
	argv[argp++] = "-+-";

	if ( argp != argc - num_args )
		glish_fatal->Report( "inconsistent argv in Task::CreateArgs" );

	argv[argc] = 0;

	return argv;
	}

void Task::Exec( const char** argv )
	{
	if ( attrs->daemon_channel )
		{
		sequencer->UpdateRemotePath( );
		executable = new RemoteExec( attrs->daemon_channel, argv[0],
					     attrs->name, argv );
		}
	else
		{
		sequencer->UpdateLocalPath( );
		char* exec_name = which_executable( argv[0] );

		if ( ! exec_name )
			return;

		//
		// full path needed for registration of shared clients
		//
		const char *tmp = argv[0];
		argv[0] = exec_name;
		executable = new TaskLocalExec( exec_name, argv, this );
		SetPid( ((TaskLocalExec*)executable)->pid() );
		argv[0] = tmp;

		if ( ! attrs->force_sockets )
			{
			close( read_pipe[1] );
			close( write_pipe[0] );

			local_channel = sequencer->AddLocalClient( read_pipe[0],
								   write_pipe[1] );
			}

		free_memory( exec_name );
		}

	no_such_program = 0;
	task_error = executable->ExecError();

	if ( ! task_error )
		// This is a little buggy - we'd like the sequencer to know
		// about this client only after the client makes its
		// initial rendezvous with the Sequencer.  But the sequencer
		// will only accept such a rendezvous in its event loop
		// *after* it has determined that there are still some
		// active clients out there and thus it's worth waiting
		// for external events to arrive.  Thus if the sequencer
		// only counted the client as active after its rendezvous
		// there would be a race: if no clients were active but
		// a new one had just been started, the sequencer wouldn't
		// wait for its rendezvous.  So instead we tell the sequencer
		// about the client as soon as we've created it.  If the
		// client fails to make its rendezvous then the sequencer's
		// count of active clients will always be too high; this
		// can be fixed if&when we add timeouts to the sequencer so
		// it can detect clients that have never managed to
		// rendezvous.
		sequencer->NewClientStarted();

	}

void Task::SetActivity( State is_active )
	{
	active = is_active;
	CreateEvent( "active", new IValue( active != sFINISHED ), 0, 1 );

	if ( active == sFINISHED )
		{
		CloseChannel();
		if ( executable ) executable->DoneReceived();
		}
	}

void Task::AbnormalExit( int status )
	{
	loop_over_list( ptlist, i )
		ptlist[i]->AbnormalExit( status );
	sequencer->NewEvent( this, 0, 1 );
	}

void *Task::getTranscriptFile( )
	{
	if ( attrs->transcript && attrs->pid && ! attrs->transcript_file )
		attrs->OpenTranscript( );
	return attrs->transcript_file;
	}


ShellTask::ShellTask( const_args_list* args, TaskAttr* task_attrs,
			Sequencer* s )
    : Task( task_attrs, s, 1 )
	{
	char* arg_string = paste( args );

	name = string_dup( "shell_client" );

	// Turn off async attribute; we don't want the shell_client
	// program to run asynchronously.
	attrs->async_flag = 0;

	int argc;
	// Need three arguments: sh, -c, arg-string
	const char** argv = CreateArgs( name, 3, argc );

	int argp = argc - 3;

	argv[argp++] = "sh";
	argv[argp++] = "-c";
	argv[argp++] = arg_string;
	argv[argp] = 0;

	Exec( argv );

	free_memory( argv );
	free_memory( arg_string );
	}


ClientTask::ClientTask( const_args_list* args, TaskAttr* task_attrs,
			Sequencer* s, int shm_flag )
    : Task( task_attrs, s )
	{

	if ( ! shm_flag || attrs->daemon_channel ||
	     attrs->async_flag || attrs->force_sockets )
		attrs->useshm = useshm = 0;
	else
		attrs->useshm = useshm = 1;

	// Get the program name.
	const IValue* arg = (const IValue*)((*args)[0]->Deref());

	if ( arg->Type() == TYPE_STRING )
		name = string_dup( arg->StringPtr(0)[0] );
	else
		name = arg->StringVal();

	// See if based on its name we should suspend this client.
	if ( s->ShouldSuspend( name ) )
		task_attrs->suspend_flag = 1;

	// Count up how many arguments there are.
	int num_args = 0;

	loop_over_list( *args, i )
		{
		arg = (const IValue*)((*args)[i]->Deref());

		if ( arg->Type() == TYPE_STRING )
			num_args += arg->Length();
		else
			++num_args;
		}

	int argc;
	const char** argv = CreateArgs( name, num_args, argc );

	int argp = argc - num_args;
	int first_arg_pos = argp;
	int saw_name = 0;

	loop_over_list( *args, j )
		{
		arg = (const IValue*)((*args)[j]->Deref());

		if ( arg->Type() == TYPE_STRING )
			{
			charptr* words = arg->StringPtr(0);
			int n = arg->Length();

			for ( int k = 0; k < n; ++k )
				{
				if ( saw_name )
					argv[argp++] = string_dup( words[k] );
				else
					// Skip over name.
					saw_name = 1;
				}
			}

		else
			{
			if ( saw_name )
				argv[argp++] = arg->StringVal();
			else
				// Skip over name.
				saw_name = 1;
			}
		}

	argv[argp] = 0;

	if ( attrs->async_flag )
		CreateAsyncClient( argv );
	else
		Exec( argv );

	for ( argp = first_arg_pos; argp < first_arg_pos + num_args; ++argp )
		free_memory( ((char**) argv)[argp] );

	if ( name && agent_value )
		{
		agent_value->AssignRecordElement("name",new IValue((const char*) name));
		const char *host = ! attrs->hostname || ! strcmp(attrs->hostname,"localhost") ? local_host_name() : attrs->hostname;
		agent_value->AssignRecordElement("host",new IValue(host));
		}

	free_memory( argv );
	}


void ClientTask::CreateAsyncClient( const char** argv )
	{
	no_such_program = 0;
	task_error = 0;

	sequencer->NewClientStarted();

	int argc = 0;
	for ( ; argv[argc]; ++argc )
		;

	(void) CreateEvent( "activate", new IValue( argv, argc, COPY_ARRAY ), 0, 1 );
	}


TaskAttr::TaskAttr( char* arg_ID, char* arg_hostname, Channel* arg_daemon_channel,
		    int arg_async_flag, int arg_ping_flag, int arg_suspend_flag,
		    int arg_force_sockets, const char *name_, char *transcript_,
		    int loaded_client_flag )
	{
	task_var_ID = arg_ID;
	hostname = arg_hostname;
	transcript = transcript_;
	transcript_file = 0;
	daemon_channel = arg_daemon_channel;
	async_flag = arg_async_flag;
	ping_flag = arg_ping_flag;
	suspend_flag = arg_suspend_flag;
	useshm = 0;
	name = name_ ? string_dup(name_) : 0;
	force_sockets = arg_force_sockets;
	pid = 0;
	loaded_client = loaded_client_flag;
	}

TaskAttr::~TaskAttr()
	{
	free_memory( task_var_ID );
	free_memory( hostname );
	free_memory( name );
	free_memory( transcript );
	if ( transcript_file ) fclose( (FILE*) transcript_file );
	}

void TaskAttr::OpenTranscript( )
	{
	if ( transcript && pid && ! transcript_file )
		{
		char *file = alloc_char( strlen(transcript)+34 );
		sprintf( file, "%s.%0.5ui.gts", transcript, pid );
		if ( ! (transcript_file = fopen( file, "w" )) )
			{
			perror( "couldn't open transcript file" );
			free_memory( transcript );
			transcript = 0;
			}
		free_memory( file );
		}
	}


IValue* CreateTaskBuiltIn::DoCall( evalOpt &, const_args_list* args_val )
	{
	// Arguments are:
	//
	//	var-ID hostname client async ping suspend input noshm transcript args...
	//
	// where "var-ID", "hostname", and transcript are string values,
	// and client/async/ping/suspend are boolean flags.

	const_args_list& args = *args_val;

	int task_args_start = 11;

	if ( args.length() <= task_args_start )
		return (IValue*) Fail( "too few arguments given to create_task" );

	char* var_ID = GetString( args[0] );
	char* hostname = GetString( args[1] );

	int err = 0;
	Channel* channel = sequencer->GetHostDaemon( hostname, err );

	if ( err )
		return (IValue*) Fail( "remote task creation failed" );

	// If the following values are changed, be sure to also change
	// them in CreateTaskBuiltIn::DoSideEffectsCall().
	int client_flag = args[2]->IntVal();
	int async_flag = args[3]->IntVal();
	int ping_flag = args[4]->IntVal();
	int suspend_flag = args[5]->IntVal();
	int force_sockets = args[8]->IntVal();
	char* transcript_file = GetString( args[9] );
	int loaded_client = args[10]->IntVal();

	int shm_flag = 1;
	const char *script_name = 0;
	if ( client_flag && sequencer->LocalHost( hostname ) && channel )
		{
		shm_flag = 0;
		sequencer->UpdatePath( );
		char *client = GetString( args[task_args_start] );

		const char *ptr_base = args[task_args_start]->StringPtr(0)[0];
		const char *ptr = ptr_base + strlen(ptr_base) - 1;
		while ( ptr != ptr_base && *ptr != '/' ) --ptr;
		if ( *ptr == '/' ) ++ptr;
		char *exe = which_executable( ptr );
		int running = 0;
		IValue *val = 0;

		if ( exe && ! strcmp( exe, sequencer->Path() ) )
			{
			script_name =  ExpandScript( task_args_start, args );
			val = new IValue( script_name );
			}
		else
			val = new IValue( client );

		send_event( channel->Sink(),  "client-up", val );
		GlishEvent* e = recv_event( channel->Source() );
		running = e && e->value->IsNumeric() && e->value->BoolVal() ? 1 : 0;
		Unref( e );
		Unref( val );
		free_memory( exe );

		if ( running )
			{
			if ( hostname )
				free_memory( hostname );
			hostname = string_dup( "localhost" );
			}
		else
			{
			if ( hostname )
				free_memory( hostname );
			hostname = 0;
			channel = 0;
			}

		}

	else if ( ! client_flag && sequencer->LocalHost( hostname ) )
		{
		//
		// if this is a local shell client or a dynamically loaded
		// client, prevent it from being started by the daemon
		//
		if ( hostname )
			free_memory( hostname );

		hostname = 0;
		channel = 0;
		}

	IValue* input = 0;

	if ( args[6]->Type() != TYPE_BOOL || args[6]->BoolVal() )
		input = new IValue( (IValue*) args[6], VAL_CONST );

	shm_flag = shm_flag && args[7]->IntVal();

	attrs = new TaskAttr( var_ID, hostname, channel, async_flag,
			      ping_flag, suspend_flag, force_sockets, script_name, transcript_file, loaded_client );

	// Collect the arguments to the task.
	const_args_list task_args;
	for ( int i = task_args_start; i < args.length(); ++i )
		task_args.append( args[i] );

	IValue* result;

	if ( client_flag )
		result = CreateClient( &task_args, shm_flag );

	else if ( loaded_client )
		result = CreateLoadedClient( &task_args );

	else	{ // Shell client.
		if ( async_flag )
			result = CreateAsyncShell( &task_args );

		else
			{
			char* command = paste( &task_args );

			if ( hostname )
				result = RemoteSynchronousShell( command,
								input );
			else
				{
				char* input_str;

				if ( ! input || (input->Type() == TYPE_BOOL &&
						 ! input->BoolVal()) )
					input_str = 0;
				else
					input_str = input->StringVal( '\n' );

				result = SynchronousShell( command, input_str );

				free_memory( input_str );
				}

			delete attrs;
			free_memory( command );
			}
		}

	Unref( input );
	return result;
	}

void CreateTaskBuiltIn::DoSideEffectsCall( evalOpt &opt, const_args_list* args_val,
						int& side_effects_okay )
	{
	// Check for synchronous shell call; we allow those to be
	// for side-effects only.  The corresponding arguments are
	// numbers 2 (client/shell flag) and 3 (async flag).

	const_args_list& args = *args_val;
	if ( args.length() > 3 )
		{
		int client_flag = args[2]->IntVal();
		int async_flag = args[3]->IntVal();

		if ( ! client_flag && ! async_flag )
			side_effects_okay = 1;
		}

	Unref( DoCall( opt, args_val ) );
	}


char* CreateTaskBuiltIn::GetString( const IValue* val )
	{
	if ( val->Type() == TYPE_BOOL && ! val->BoolVal() )
		// False means "default".
		return 0;
	else
		return val->StringVal();
	}


const char* CreateTaskBuiltIn::ExpandScript( int start, const_args_list &argv )
	{
	Serialize args( argv, start );

	++args;					// step past the interpreter
						// to the first argument
	const char *arg;
	for ( ; (arg = args.get()); ++args )
		{
		if ( ! strcmp( arg, "-v" ) || ! strcmp( arg, "-w" ) || strchr( arg, '=' ) )
			continue;
		else if ( ! strcmp( arg, "-l" ) )
			++args;
		else
			break;
		}

	char *runfile;
	if ( arg && strcmp( arg, "--" ) &&
	     (runfile = which_include(arg)) )
		{
		char *ret = canonic_path( runfile );
		args.set( ret );
		free_memory( runfile );
		return ret;
		}

	return 0;
	}


extern int allwarn;
IValue* CreateTaskBuiltIn::SynchronousShell( const char* command,
						const char* input )
	{
	FILE* shell = popen_with_input( command, input );

	if ( ! shell )
		{
		glish_warn->Report( "could not execute shell command \"", command,
				"\"" );
		return error_ivalue();
		}

	IValue* result = GetShellCmdOutput( command, shell, 0 );

	int status = pclose_with_input( shell );

	if ( result )
		{
		IValue *stat_val = new IValue( status >> 8 );
		result->AssignAttribute( "status", stat_val );
		Unref( stat_val );
		}

	if ( status && ( allwarn || sequencer->Verbose() > 0 ))
		{
		char status_buf[128];
		sprintf( status_buf, "0x%x", status >> 8 );
		glish_warn->Report( "shell command \"", command,
				"\" terminated with status = ", status_buf );
		}

	return result;
	}


IValue* CreateTaskBuiltIn::RemoteSynchronousShell( const char* command,
							IValue* input )

	{
	sos_fd_sink &sink = attrs->daemon_channel->Sink();

	IValue* r = create_irecord();
	r->SetField( "command", command );

	if ( input )
		r->SetField( "input", input );

	send_event( sink, "shell", r );
	Unref( r );

	GlishEvent* e = recv_event( attrs->daemon_channel->Source() );
	if ( ! e )
		{
		glish_warn->Report( "remote daemon died" );
		return error_ivalue();
		}

	int was_okay = e->value->IntVal();
	delete e;

	if ( ! was_okay )
		{
		glish_warn->Report( "could not execute shell command \"", command,
				"\" on host ", attrs->hostname );

		return error_ivalue();
		}

	IValue* result = GetShellCmdOutput( command, 0, 1 );

	e = recv_event( attrs->daemon_channel->Source() );
	if ( ! e )
		{
		glish_warn->Report( "remote daemon died" );
		return error_ivalue();
		}

	if ( result )
		result->AssignAttribute( "status", e->value );

	int status = e->value->IntVal();
	delete e;

	if ( status )
		{
		char status_buf[128];
		sprintf( status_buf, "0x%x", status >> 8 );
		glish_warn->Report( "shell command \"", command,
				"\" on host ", attrs->hostname,
				" terminated with status = ", status_buf );
		}

	return result;
	}


IValue* CreateTaskBuiltIn::GetShellCmdOutput( const char* command, FILE* shell,
						int is_remote )
	{
#define MAX_CMD_OUTPUT_LINES 8192
	charptr event_values[MAX_CMD_OUTPUT_LINES];
#define MAX_SHELL_LINE_LEN 8192
	char line_buf[MAX_SHELL_LINE_LEN];
	int line_num = 0;

#define NEXT_CMD_LINE							\
	(is_remote ? NextRemoteShellCmdLine( line_buf ) :		\
			NextLocalShellCmdLine( shell, line_buf ))

	while ( NEXT_CMD_LINE )
		{
		int len = strlen( line_buf );

		// Remove trailing newline.
		if ( len > 0 && line_buf[len - 1] == '\n' )
			line_buf[len - 1] = '\0';

		if ( ++line_num >= MAX_CMD_OUTPUT_LINES )
			{
			glish_warn->Report(
			"too much data generated by shell command \"",
					command, "\"" );

			// throw away the remainder of the input
			while ( NEXT_CMD_LINE )
				;

			break;
			}

		event_values[line_num - 1] = string_dup( line_buf );
		}

	char **event_values_copy = alloc_charptr( line_num );

	copy_array( event_values, event_values_copy, line_num, charptr );

	return new IValue( (charptr*) event_values_copy, line_num );
	}


char* CreateTaskBuiltIn::NextLocalShellCmdLine( FILE* shell, char* line_buf )
	{
#if defined(__alpha) || defined(__alpha__)
	char *ret = fgets( line_buf, MAX_SHELL_LINE_LEN, shell );
	while ( ! ret && ! feof(shell) )
		ret = fgets( line_buf, MAX_SHELL_LINE_LEN, shell );
	return ret;
#else
	return fgets( line_buf, MAX_SHELL_LINE_LEN, shell );
#endif
	}

char* CreateTaskBuiltIn::NextRemoteShellCmdLine( char* line_buf )
	{
	GlishEvent* e = recv_event( attrs->daemon_channel->Source() );

	if ( ! e )
		{
		glish_warn->Report( "remote daemon died" );
		return 0;
		}

	IValue* v = (IValue*)(e->value);

	if ( v->Type() != TYPE_STRING )
		{
		// This is the "done" event, with a boolean true as value.
		delete e;
		return 0;
		}

	char* next_line = v->StringVal();
	strcpy( line_buf, next_line );

	free_memory( next_line );
	delete e;

	return line_buf;
	}


IValue* CreateTaskBuiltIn::CreateAsyncShell( const_args_list* args )
	{
	Task* task = new ShellTask( args, attrs, sequencer );

	IValue *err = 0;
	if ( (err = CheckTaskStatus( task )) )
		{
		Unref( task );
		return err;
		}
	else
		return task->AgentRecord();

	}


IValue* CreateTaskBuiltIn::CreateClient( const_args_list* args, int shm_flag )
	{
	if ( attrs->async_flag )
		{
		if ( attrs->hostname && strcmp( attrs->hostname, "localhost" ) )
			return (IValue*) Fail(
		"hostname option is incompatible with asynchronous client" );

		if ( attrs->suspend_flag )
			glish_warn->Report(
		"suspend option is not supported for asynchronous clients" );
		}

	Task* task = new ClientTask( args, attrs, sequencer, shm_flag );

	IValue *err = 0;
	if ( (err = CheckTaskStatus( task )) )
		{
		Unref( task );
		return err;
		}
	else
		return task->AgentRecord();
	}

IValue* CreateTaskBuiltIn::CreateLoadedClient( const_args_list* args )
	{
	Agent *task = new LoadedAgent( args, attrs, sequencer );
	return task->AgentRecord();
	}

IValue *CreateTaskBuiltIn::CheckTaskStatus( Task* task )
	{
	if ( task->NoSuchProgram() )
		return (IValue*) ValCtor::error( "no such program, \"", task->Name(), "\"" );

	else if ( task->Exec() && task->Exec()->ExecError() )
		return (IValue*) ValCtor::error( "could not exec program, \"",
				task->Name(), "\"" );

	return 0;
	}


void Task::sendEvent( sos_sink &fd, const char* event_name,
		      const GlishEvent* e, int can_suspend, const ProxyId &proxy_id )
	{
	sos_status *ss = send_event( fd, event_name, e, 1, proxy_id, (FILE*) TranscriptFile( ) );
	if ( ss ) sequencer->SendSuspended( ss, copy_value(e->value) );
	}

void ClientTask::sendEvent( sos_sink &fd, const char* event_name,
		      const GlishEvent* e, int can_suspend, const ProxyId &proxy_id )
	{
	sos_status *ss = send_event( fd, event_name, e, 1, proxy_id, (FILE*) TranscriptFile( ) );
	if ( ss ) sequencer->SendSuspended( ss, copy_value(e->value) );
	}

void TaskLocalExec::AbnormalExit( int status )
	{
	task->AbnormalExit( status );
	}

int same_host( Task* t1, Task* t2 )
	{
	const char* t1_host = t1->Host();
	const char* t2_host = t2->Host();

	if ( ! t1_host )
		t1_host = "localhost";

	if ( ! t2_host )
		t2_host = "localhost";

	return ! strcmp( t1_host, t2_host );
	}
