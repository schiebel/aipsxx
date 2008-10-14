// $Id: glishd.cc,v 19.2 2004/07/13 22:37:01 dschieb Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997,2000 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: glishd.cc,v 19.2 2004/07/13 22:37:01 dschieb Exp $")
#include "system.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <syslog.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>

#if defined(_AIX)
// for bzero()
#include <strings.h>
#endif

#if HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif

#include "Glish/Client.h"
#include "Glish/List.h"
#include "Glish/Reporter.h"
#include "Socket.h"
#include "LocalExec.h"
#if USENPD
#include "Npd/npd.h"
#else
extern "C" {
    int get_userid( const char * );
    int get_user_group( const char * );
    const char *get_group_name( int );
    char **authenticate_client( int );
};
#endif
#include "ports.h"


inline int streq( const char* a, const char* b ) { return ! strcmp( a, b ); }
const char* get_prog_name( const char* full_path );

inline char* extract_prog_name( char *exec_line )
	{ return (!strtok( exec_line, " " ) || !strtok( NULL, " " ) ||
		  !strtok( NULL, " " )) ? 0 : strtok( NULL, " " ); }

int glishd_verbose = 0;
int suspend_user = 0;

void glishd_sighup();
void install_terminate_handlers();

#if !(defined( __linux__) || defined(__APPLE_CC__))
extern "C" char* sys_errlist[];
#endif
extern "C" int chdir( const char* path );

//  --   --   --   --   --   --   --   --   --   --   --   --   --   --   --
//		SIGHUP can be used to shut down glishd
//  --   --   --   --   --   --   --   --   --   --   --   --   --   --   --
//
//  In this file, there are two daemons, "dServer" and "dUser", and there are
//  two types of clients, "Interp" and shared (AKA multi-threaded) clients.
//  Each of these represents processes.
//
//  "dServer" is only started by root. It listens to the published port,
//  authenticates those who connect, and starts "dUser" for each unique
//  user (in the unix sense) who connects.
//
//  "dUser" handles requests from the authenticated user, and chats with
//  "dServer", its parent. "dUser" deals with the clients, "Interp" and
//  shared clients, maintaining lists of both.
//
//  "Interp" represents the glish command interpreters who use "glishd" to
//  start and control clients.
//  --   --   --   --   --   --   --   --   --   --   --   --   --   --   --

//
//  Base class for daemons
//
class GlishDaemon : public Exec {
    public:
	GlishDaemon( int &argc, char **&argv );
	GlishDaemon( );
	virtual ~GlishDaemon();
	virtual void loop() = 0;
	int IsValid() const { return valid; }
	virtual int AddInputMask( fd_set* mask );
	void InitInterruptPipe( );

	// shutdown functions:
	// 	Invalidate()	--  leisurely shutdown
	//	FatalError()	--  immediate shutdown
	void Invalidate();
	virtual void FatalError();

    protected:
	void close_on_fork( int fd );
	int fork();
	static char *hostname;
	static char *name;
	int interrupt_pipe[2];
	int valid;
	static List(int) *close_fds;
};

List(int) *GlishDaemon::close_fds = 0;
static GlishDaemon *current_daemon = 0;
class dUser;
glish_declare(PDict,LocalExec);

//
//  These are the intrepreter connections which talk only
//  to 'dUser'.
//
class Interp {
    public:
	Interp( Client *c ) : interpreter( c ), work_dir(strdup("/")), binpath(0), ldpath(0) {  }
	~Interp();

	// Read and act on the next interpreter request.  Returns 0 to
	// indicate that the interpreter exited, non-zero otherwise.
	//
	// ~mask" corresponds to a select() mask previously constructed
	// using Interpreter()->AddInputMask().
	//
	// Upon return, "internal_event" will be non-zero if the received
	// event was directed to glishd itself; otherwise, "internal_event"
	// will be set to zero upon return.
	int NextRequest( GlishEvent* e, dUser *hub, GlishEvent*& internal_event );

	Client* Interpreter()	{ return interpreter; }

	int AddInputMask( fd_set* mask )
		{ return interpreter->AddInputMask(mask); }
	int HasClientInput( fd_set* mask )
		{ return interpreter->HasClientInput(mask); }
	GlishEvent* NextEvent( fd_set* mask )
		{ return interpreter->NextEvent( mask ); }

    protected:

	void SetWD( Value* wd );
	void SetBinPath( Value* path );
	void SetLdPath( Value* path );
	void PingClient( Value* client_id );
	void CreateClient( Value* argv, dUser *hub );
	void ClientRunning( Value* client, dUser *hub );
	void ShellCommand( Value* cmd );
	void KillClient( Value* client_id );
	void Probe( Value* probe_val );

	void ChangeDir();	// Change to our working-directory.

	Client* interpreter;	// Client used for connection to interpreter.
	char* work_dir;		// working-directory for this interpreter.
	Value *binpath;		// the path to use to start clients
	Value *ldpath;		// the path to use to start clients

	// Whether we've generated an error message for a bad work_dir.
	int did_wd_msg;

	// Clients created on behalf of interpreter.
	PDict(LocalExec) clients;
};

glish_declare(PList,Client);
glish_declare(PDict,Client);
glish_declare(PList,Interp);

//
//  Daemon which operates on an individual user's behalf.
//  There is one of these daemons running for each glish
//  user on a given machine.
//
class dUser : public GlishDaemon {
    public:
	dUser( int &argc, char **&argv );
	dUser( int sock, const char *user, const char *host );
	~dUser();

	//
	// these functions are used by both master and slave processes
	//
  	int AddInputMask( fd_set* mask );

	//
	// these functions are used only in the master process
	//
	int HasClientInput( fd_set* mask )
		{ return slave ? slave->HasClientInput( mask ) : 0 ; }
	int SendFd( int fd )
		{ return ! fd_pipe ? -1 : send_fd( fd_pipe, fd ); }
	GlishEvent* NextEvent( fd_set* mask )
		{ return slave ? slave->NextEvent( mask ) : 0 ; }
	void PostEvent( const char* event_name, const Value* event_value )
		{ if ( slave ) slave->PostEvent(event_name, event_value); }

	//
	// these functions are used only in the slave process or a dUser
	// running without a master (dServer)
	//
	Client *LookupClient( const char *s );
	void ClientGone( const char *s );
	int RecvFd( ) { return ! fd_pipe ? -1 : recv_fd( fd_pipe ); }
	void ProcessConnect();			// connection, via dServer
	void ProcessInterps( fd_set * );	// existing interpreters
	void ProcessClients( fd_set * );	// existing shared clients
	void ProcessMaster( fd_set * );		// events from dServer
	void ProcessTransitions( fd_set * );	// clients which may be either
						// interpreters or shared clients
	void ProcessInternalReq( GlishEvent * );// requests to the daemon
	void loop();				// handle requests

	const char *Id( ) const { return id; };

    protected:
	int pid();
	Client *LookupClientInMaster( const char *s );
	char *new_name();

	char *id;
	PList(Client) transition;
	PDict(Client) clients;
	PList(Interp) interps;
  
	Client *master;
	Client *slave;

	ExecMinder lexpid;

	int count;
	int fd_pipe;

	int pid_;
};

glish_declare(PDict,dUser);
glish_declare(PDict,char);
typedef PDict(char) str_dict;
glish_declare(PDict,str_dict);

//
//  Master daemon. There is one master daemon per machine,
//  and it must be started by root.
//
class dServer : public GlishDaemon {
    public:
	dServer( int &argc, char **&argv );
	~dServer();

	// select on our fds
	void loop();

	// process interpreter connection, on published port
	void ProcessConnect();

	// process events from our minions
	void ProcessUsers( fd_set* mask );

	int AddInputMask( fd_set* mask );

	void FatalError();

    protected:
	void Register( Value *, const char *user_name );
	void CreateClient( Value *, const char *user_name );
	void ClientRunning( Value *, const char *user_name, dUser * );
	void ClientGone( Value *, const char *user_name, dUser * );
	void clear_clients_registered_to( const char *user );

	char *id;
	AcceptSocket accept_sock;
	PDict(dUser) users;

	// client name -> user who started it
	str_dict world_clients;
	// group name -> client name -> user who started it
	PDict(str_dict) group_clients;
};

char *GlishDaemon::hostname = 0;
char *GlishDaemon::name = 0;

void GlishDaemon::InitInterruptPipe( )
	{
	if ( pipe( interrupt_pipe ) < 0 )
		{
		syslog( LOG_ERR, "problem creating interrupt pipe" );
		interrupt_pipe[0] = interrupt_pipe[1] = 0;
		}
	else
		{
		close_on_fork( interrupt_pipe[0] );
		close_on_fork( interrupt_pipe[1] );
		}
	}

GlishDaemon::GlishDaemon( ) : valid(1)
	{
	interrupt_pipe[0] = interrupt_pipe[1] = 0;
	if ( close_fds == 0 ) close_fds = new List(int);
	}

GlishDaemon::GlishDaemon( int &, char **&argv ) : valid(0)
	{
	if ( close_fds == 0 ) close_fds = new List(int);

	// fork() to:
	//     o  allows the parent to exit signaling to any shell
	//        that it's process has finished
	//     o  get a new processed id so we're not a process
	//        group leader
	int npid;
	if ( (npid = fork()) < 0 )
		{
		syslog( LOG_ERR, "problem forking server daemon" );
		return;
		}
	else if ( npid != 0 )		// parent
		exit(0);

	// setsid() to:
	//     o  become session leader of a new session
	//     o  become process group leader
	//     o  have no controlling terminal
	setsid();

	// change to the root directory, by default, to avoid keeping
	// directories mounted unnecessarily
	chdir("/");

	// clear umask to prevent unexpected permission changes
	umask(0);

	// add bullet-proofing for common signals.
	install_signal_handler( SIGINT, (signal_handler) SIG_IGN );
	install_signal_handler( SIGTERM, (signal_handler) SIG_IGN );
	install_signal_handler( SIGPIPE, (signal_handler) SIG_IGN );
	// install terminate handlers to close accept socket
	install_terminate_handlers();
	// SIGHUP can be used to shutdown the daemon. "current_daemon"
	// is the hook through which shutdown is accomplished.
	install_signal_handler( SIGHUP, (signal_handler) glishd_sighup );
	InitInterruptPipe();
	current_daemon = this;

	// store away our name
	if ( ! name ) name = strdup(argv[0]);

	// signals to children that all is OK
	valid = 1;
	}

int GlishDaemon::AddInputMask( fd_set* mask )
	{
	if ( *interrupt_pipe > 0 && ! FD_ISSET( interrupt_pipe[0], mask ) )
		{
		FD_SET( interrupt_pipe[0], mask );
		return 1;
		}

	return 0;
	}

void GlishDaemon::close_on_fork( int fd )
	{
	mark_close_on_exec( fd );
	close_fds->append(fd);
	}

int GlishDaemon::fork()
	{
	int npid = ::fork();

	if ( npid == 0 )		// child
		{
		for ( int len = close_fds->length(); len > 0; --len )
			close( close_fds->remove_nth( len - 1 ) );

		ExecMinder::ForkReset( );
		}

	return npid;
	}

void GlishDaemon::Invalidate()
	{
	valid = 0;
	if ( *interrupt_pipe )
		close(interrupt_pipe[1]);
	interrupt_pipe[0] = interrupt_pipe[1] = 0;
	}

void GlishDaemon::FatalError()
	{
	valid = 0;
	if ( *interrupt_pipe )
		close(interrupt_pipe[1]);
	interrupt_pipe[0] = interrupt_pipe[1] = 0;
	}

GlishDaemon::~GlishDaemon() { }

int dUser::pid( )
	{
	return pid_;
	}

dUser::dUser( int &argc, char **&argv ) : GlishDaemon(argc, argv), master(0), slave(0),
						count(0), fd_pipe(0), pid_(0)
	{
	// it is assumed that GlishDaemon will set valid if all is OK
	if ( ! valid ) return;

	interps.append( new Interp( new Client( argc, argv )) );
	}

dUser::dUser( int sock, const char *user, const char *host ) : master(0), slave(0),
						lexpid(this), count(0), fd_pipe(0), pid_(0)
	{
	// it is assumed that GlishDaemon will set valid if all is OK
	if ( ! valid ) return;

	if ( ! hostname ) hostname = strdup(local_host_name());
	id = (char*) alloc_memory( strlen(hostname) + strlen(name) + strlen(user) + strlen(host) + 35 );
	sprintf( id, "%s @ %s [%d] (%s@%s)", name, hostname, int( getpid() ), user, host );

	int read_pipe[2], write_pipe[2], fd_pipe_[2];

	//	parent:	writes to write_pipe[1]
	//		reads from read_pipe[0]
	//		writes to fd_pipe_[1]
	//	child:	reads from write_pipe[0]
	//		writes to read_pipe[1]
	//		reads from fd_pipe_[0]
	if ( pipe( read_pipe ) < 0 || pipe( write_pipe ) < 0 || stream_pipe(fd_pipe_) < 0 )
		{
		valid = 0;
		syslog( LOG_ERR, "problem creating pipe for user daemon" );
		return;
		}

	// we now fork, the child will be owned by "user", and it will be
	// responsible for forking, pinging, etc. for the clients "user"
	// creates on this machine. this new "glishd" will create with
	// the "root" "glishd" via the pipes.
	int npid;
	if ( (npid = fork()) < 0 )
		{
		valid = 0;
		syslog( LOG_ERR, "problem forking user daemon" );
		return;
		}
	else if ( npid == 0 )		// child
		{
		setuid(get_userid( user ));
		setgid(get_user_group( user ));

		close( read_pipe[0] );
		close( write_pipe[1] );
		close( fd_pipe_[1] );

		while ( suspend_user ) sleep(1);

		InitInterruptPipe();

		master = new Client( write_pipe[0], read_pipe[1], new_name() );
		transition.append( new Client( sock, sock, new_name() ) );
		fd_pipe = fd_pipe_[0];

		loop();

		exit (0);
		}
	else				// parent
		{
		close( read_pipe[1] );
		close( write_pipe[0] );
		close( fd_pipe_[0] );

		slave = new Client( read_pipe[0], write_pipe[1], id );
		fd_pipe = fd_pipe_[1];

		pid_ = npid;
		}
	}

Client *dUser::LookupClientInMaster( const char *s )
	{
	if ( ! master ) return 0;

	master->PostEvent( "client-up", s );
	GlishEvent *e = master->NextEvent( );

	if ( e && e->value->IsNumeric() && e->value->BoolVal() )
		return master;

	return 0;
	}

Client *dUser::LookupClient( const char *s )
	{
	Client *ret = clients[s];
	if ( ret ) return ret;
// 	ret = clients[s];
// 	if ( ret ) return ret;
	return LookupClientInMaster( s );
	}

void dUser::ClientGone( const char *s )
	{
	if ( ! master ) return;
	master->PostEvent( "client-gone", s );
	}

int dUser::AddInputMask( fd_set* mask )
	{
	int cnt = GlishDaemon::AddInputMask( mask );
	loop_over_list( transition, i)
		cnt += transition[i]->AddInputMask( mask );

	loop_over_list( interps, j)
		cnt += interps[j]->AddInputMask( mask );

	const char *key = 0;
	Client *client = 0;
	IterCookie* c = clients.InitForIteration();
	while ( (client = clients.NextEntry( key, c )) )
		cnt += client->AddInputMask( mask );

	if ( master )
		{
		cnt += master->AddInputMask( mask );
		if ( fd_pipe > 0 && ! FD_ISSET( fd_pipe, mask ) )
			{
			FD_SET( fd_pipe, mask );
			++cnt;
			}
		}

	if ( slave )
		cnt += slave->AddInputMask( mask );

	return cnt;
	}

void dUser::loop( )
	{
	fd_set input_fds;
	fd_set* mask = &input_fds;

	// must do this for SIGHUP to work properly
	current_daemon = this;

	while ( valid && (interps.length() || clients.Length() || transition.length()) )
		{
		FD_ZERO( mask );
		AddInputMask( mask );

		while ( select( FD_SETSIZE, (SELECT_MASK_TYPE *) mask, 0, 0, 0 ) < 0 )
			{
			if ( errno != EINTR )
				{
				syslog( LOG_ERR,"error during select(), exiting" );
				exit( 1 );
				}
			}

		if ( ! valid ) continue;

		// See if anything is up with our shared clients
		ProcessClients( mask );

		// Process events from master
		ProcessMaster( mask );

		// Accept requests from our intrepreters
		ProcessInterps( mask );

		// Now look for any new interpreters contacting us, via dServer.
		if ( FD_ISSET( fd_pipe, mask ) )
			ProcessConnect();

		ProcessTransitions( mask );
		}
	}

void dUser::ProcessTransitions( fd_set *mask )
	{
	Client *c = 0;
	GlishEvent *internal = 0;

	for ( int i=0; i < transition.length(); ++i )
		{
		c = transition[i];
		if ( c->HasClientInput( mask ) )
			{
			GlishEvent *e = c->NextEvent( mask );

			// transient exiting
			if ( ! e )
				{
				delete transition.remove_nth( i-- );
				continue;
				}

			// perisitent client registering itself
			if ( ! strcmp( e->name, "*register-persistent*" ) )
				{
				char *nme = strdup(e->value->StringPtr(0)[0]);
				clients.Insert( nme, transition.remove_nth( i-- ) );

				const char *type = e->value->StringPtr(0)[1];
				if ( master && (! strcmp( type, "GROUP") || ! strcmp( type, "WORLD" )) )
					master->PostEvent(e);

				continue;
				}

			//      ???
			if ( ! strcmp( e->name, "established" ) )
				continue;

			// process interpreter request
			Interp *itp = new Interp( transition.remove_nth(i--) );
			interps.append( itp );
			if ( ! itp->NextRequest( e, this, internal ) )
				{
				delete interps.remove_nth( interps.length() );
				continue;
				}

			if ( internal )
				ProcessInternalReq( internal );
			}
		}
	}

void dUser::ProcessInterps( fd_set *mask )
	{
	GlishEvent *e = 0;

	for ( int i = 0; i < interps.length(); ++i )
		{
		GlishEvent *internal = 0;
		Interp *itp = interps[i];
		if ( itp->HasClientInput(mask) )
			{
			e = itp->Interpreter()->NextEvent( mask );

			if ( ! e )		// remove interpreter
				{
				delete interps.remove_nth( i-- );
				continue;
				}

			itp->NextRequest( e, this, internal );

			if ( internal )
				ProcessInternalReq( internal );
			}
		}
	}


void dUser::ProcessClients( fd_set *mask )
	{
	const char *key = 0;
	Client *client = 0;
	IterCookie* c = clients.InitForIteration();

	while ( (client = clients.NextEntry( key, c )) )
		if ( client->HasClientInput( mask ) )
			{
			GlishEvent *e = client->NextEvent( mask );

			if ( ! e )	// "shared" client exited
				{
				ClientGone( key );
				// free key
				free_memory( clients.Remove( key ) );
				delete client;
				}
			else
				{
				// ignore non-null events for now
				}
			}
	}


void dUser::ProcessConnect( )
	{
	int fd = RecvFd();

	if ( fd > 0 )
		transition.append( new Client( fd, fd, new_name() ) );
	else
		syslog( LOG_ERR, "attempted connect failed (or master exited), ignoring" );

	}

void dUser::ProcessMaster( fd_set *mask )
	{
	if ( master && master->HasClientInput( mask ) )
		{
		GlishEvent *e = master->NextEvent( mask );

		if ( ! e )
			{
			syslog( LOG_ERR, "problems, master exited" );
			if ( master ) delete master;
			close( fd_pipe );
			fd_pipe = 0;
			master = 0;
			}
		else
			{
			const Value *nme = 0;
			if ( ! strcmp( e->name, "client" ) && (nme = e->value->HasRecordElement( "name" )) )
				{
				Client *client = clients[nme->StringPtr(0)[0]];
				if ( client )
					client->PostEvent( "client", e->value );
				else
					syslog( LOG_ERR, "bad client event: %s", nme->StringPtr(0)[0] );
				}
			}
		}
	}


void dUser::ProcessInternalReq( GlishEvent* event )
	{
	const char* nme = event->name;

	if ( streq( nme, "*terminate-daemon*" ) )
		exit( 0 );
	else
		syslog( LOG_ERR,"bad internal event, \"%s\"", nme );
	}


dUser::~dUser( )
	{
	if ( master )
		delete master;

	if ( slave )
		delete slave;

	if ( fd_pipe )
		close( fd_pipe );

	loop_over_list( transition, i )
		delete transition[i];

	loop_over_list( interps, j )
		delete interps[j];

	const char *key = 0;
	Client *client = 0;
	IterCookie* c = clients.InitForIteration();
	while ( (client = clients.NextEntry( key, c )) )
		{
		// free key
		free_memory( clients.Remove( key ) );
		delete client;
		}

	if ( id ) free_memory( id );
	}

char *dUser::new_name( )
	{
	char *nme = (char*) alloc_memory(strlen(id)+20);
	sprintf(nme, "%s #%d", id, count++);
	return nme;
	}

dServer::dServer( int &argc, char **&argv ) : GlishDaemon( argc, argv ), id(0),
						        accept_sock( 0, DAEMON_PORT, 0 )
	{
	// it is assumed that GlishDaemon will set valid if all is OK
	if ( ! valid ) return;

	if ( ! hostname ) hostname = strdup(local_host_name());
	id = (char*) alloc_memory( strlen(hostname) + strlen(name) + 30 );
	sprintf( id, "%s @ %s [%d]", name, hostname, int( getpid() ) );

	if ( glishd_verbose )
		syslog( LOG_INFO, "STARTING: %s", id );

	// setup syslog facility
	openlog(id,LOG_CONS,LOG_DAEMON);

	if ( accept_sock.Port() == 0 )		// didn't get it.
		{
		syslog( LOG_ERR, "daemon apparently already running, exiting" );
		exit( 1 );
		}

	// don't let our children inherit the accept socket fd; we want
	// it to go away when we do.
	mark_close_on_exec( accept_sock.FD() );
#if USENPD
	// init for npd and the md5 authentication code
	init_log(argv[0]);
#endif
	if ( argc == 2 )
		{
		struct stat stat_buf;
		if ( stat( argv[1], &stat_buf ) < 0 )
			syslog( LOG_ERR, "couldn't stat key directory \"%s\"", argv[1] );
#if USENPD
		else if ( S_ISDIR(stat_buf.st_mode) )
			{
			set_key_directory(argv[1]);
			if ( glishd_verbose )
				syslog( LOG_INFO, "using key directory \"%s\"", argv[1] );
			}
#endif
		else
			syslog( LOG_ERR, "key directory, \"%s\", invalid", argv[1] );
		}		
	}

void dServer::loop()
	{
	fd_set input_fds;
	fd_set* mask = &input_fds;

	// must do this for SIGHUP to work properly
	current_daemon = this;

	while ( valid )
		{
		FD_ZERO( mask );
		AddInputMask( mask );

		while ( select( FD_SETSIZE, (SELECT_MASK_TYPE *) mask, 0, 0, 0 ) < 0 )
			{
			if ( errno != EINTR )
				{
				syslog( LOG_ERR,"error during select(), exiting" );
				exit( 1 );
				}
			}

		if ( ! valid ) continue;

		// check on our minions
		ProcessUsers( mask );

		// Now look for any new interpreters contacting us.
		if ( FD_ISSET( accept_sock.FD(), mask ) )
			ProcessConnect();
		}
	if ( glishd_verbose )
		syslog( LOG_INFO, "EXITING event loop" );
	}

void dServer::ProcessConnect()
	{
	int s = accept_connection( accept_sock.FD() );

	if ( s < 0 )
		{
		syslog( LOG_ERR, "error when accepting connection, exiting" );
		exit( 1 );
		}

	// Don't let our children inherit this socket fd; if
	// they do, then when we exit our remote Glish-
	// interpreter peers won't see select() activity
	// and detect out exit.
	mark_close_on_exec( s );

	char **peer = 0;

	if ( (peer = authenticate_client( s )) )
		{
		dUser *user = users[peer[0]];
		if ( user )
			{
			if ( user->SendFd( s ) < 0 )
				syslog( LOG_ERR, "sendfd failed, %m" );
			}
		else
			{
			dUser *user = new dUser( s, peer[0], peer[1] );
			if ( user && user->IsValid() )
				users.Insert( strdup(peer[0]), user );
			else
				delete user;
			}
		}

	close( s );
	}

void dServer::clear_clients_registered_to( const char *user )
	{
	const char *key = 0, *key2 = 0;
	str_dict *map = 0;
	char *val = 0;
	IterCookie* c = world_clients.InitForIteration();

	while ( (val = world_clients.NextEntry( key, c )) )
		{
		if ( ! strcmp(user, val) )
			{
			if ( glishd_verbose )
				syslog( LOG_INFO, "removing world client (%s): %s", user, key );
			free_memory( world_clients.Remove(key) );
			free_memory( val );
			}
		}

	c = group_clients.InitForIteration();
	while ( (map = group_clients.NextEntry( key, c )) )
		{
		IterCookie *c2 = (*map).InitForIteration();
		while ( (val = (*map).NextEntry( key2, c2 )) )
			{
			if ( ! strcmp(user, val) )
				{
				if ( glishd_verbose )
					syslog( LOG_INFO, "removing group client (%s/%s): %s", user, key, key2 );
				free_memory( (*map).Remove(key2) );
				free_memory( val );
				}
			}
		if ( ! (*map).Length() )
			{
			if ( glishd_verbose )
				syslog( LOG_INFO, "removing group client list: %s/%s", user, key );
			free_memory( group_clients.Remove( key ) );
			delete map;
			}
		}
	}
	

void dServer::CreateClient( Value *value, const char *user_name )
	{
	const Value *name_val = value->HasRecordElement( "name" );
	const char *nme = name_val ? name_val->StringPtr(0)[0] : 0;

	if ( ! nme ) return;

	char *registered_user = 0;
	const char *group = get_group_name( get_user_group( user_name ) );
	str_dict *map = group_clients[group];
	if ( map && (registered_user = (*map)[nme]) )
		{
		if ( glishd_verbose )
			syslog( LOG_INFO, "create group client (%s): <%s> %s", user_name, registered_user, nme );
		users[registered_user]->PostEvent( "client", value );
		return;
		}

	if ( (registered_user = world_clients[nme]) )
		{
		if ( glishd_verbose )
			syslog( LOG_INFO, "create world client (%s): <%s> %s", user_name, registered_user, nme );
		users[registered_user]->PostEvent( "client", value );
		return;
		}
	}

void dServer::Register( Value *value, const char *user_name )
	{
	const char *nme = value->StringPtr(0)[0];
	const char *type = value->StringPtr(0)[1];

	if ( ! strcmp( type, "WORLD" ) )
		{
		if ( glishd_verbose )
			syslog( LOG_INFO, "register world (%s): %s", user_name, nme );
		world_clients.Insert( strdup(nme), strdup(user_name) );
		}
	else if ( ! strcmp( type, "GROUP" ) )
		{
		const char *group = get_group_name( get_user_group( user_name ) );
		if ( glishd_verbose )
			syslog( LOG_INFO, "register group (%s/%s): %s", user_name, group, nme );
		str_dict *map = group_clients[group];
		if ( ! map )
			{
			map = new str_dict;
			group_clients.Insert(strdup(group), map);
			}
		else
			{
			char *u = (*map)[nme];
			if ( u )
				{
				free_memory((*map).Remove(nme));
				free_memory(u);
				}
			}
		(*map).Insert( strdup(nme), strdup(user_name));
		}
	}

void dServer::ClientRunning( Value* client, const char *user_name, dUser *user )
	{
	client->Polymorph( TYPE_STRING );

	int argc = client->Length();

	if ( argc < 1 )
		{
		syslog( LOG_ERR, "\"client-up\" event with no client name" );
		user->PostEvent( "client-up-reply", false_value );
		return;
		}

	charptr *strs = client->StringPtr();
	const char *name_str = strs[0];

	char *registering_user = 0;
	const char *group = get_group_name( get_user_group( user_name ) );

	str_dict *map = group_clients[group];
	if ( map && ( (registering_user = (*map)[name_str]) ))
		{
		if ( glishd_verbose )
			syslog( LOG_INFO, "ping group client (%s): <%s> %s", user_name, registering_user, name_str );
		Value true_value( glish_true );
		user->PostEvent( "client-up-reply", &true_value );
		return;
		}

	if ( (registering_user = world_clients[name_str]) )
		{
		if ( glishd_verbose )
			syslog( LOG_INFO, "ping world client (%s): <%s> %s", user_name, registering_user, name_str );
		Value true_value( glish_true );
		user->PostEvent( "client-up-reply", &true_value );
		return;
		}

	if ( glishd_verbose )
		syslog( LOG_INFO, "ping non-existent client (%s): %s", user_name, name_str );
	
	user->PostEvent( "client-up-reply", false_value );
	}

void dServer::ClientGone( Value* client, const char *user_name, dUser *user )
	{
	client->Polymorph( TYPE_STRING );

	int argc = client->Length();

	if ( argc < 1 )
		{
		syslog( LOG_ERR, "\"client-gone\" event with no client name" );
		return;
		}

	charptr *strs = client->StringPtr();
	const char *name_str = strs[0];

	char *registering_user = 0;
	const char *group = get_group_name( get_user_group( user_name ) );

	str_dict *map = group_clients[group];
	if ( map && ( (registering_user = (*map)[name_str]) ))
		{
		if ( glishd_verbose )
			syslog( LOG_INFO, "group client exited (%s): <%s/%s> %s", user_name, registering_user, group, name_str );
		(*map).Remove( name_str );
		}

	else if ( (registering_user = world_clients[name_str]) )
		{
		if ( glishd_verbose )
			syslog( LOG_INFO, "world client exited (%s): <%s> %s", user_name, registering_user, name_str );
		world_clients.Remove( name_str );
		}
	else if ( glishd_verbose )
		syslog( LOG_INFO, "unknown client exited (%s): %s", user_name, name_str );

	}

void dServer::ProcessUsers( fd_set *mask)
	{
	const char* key = 0;
	dUser *user = 0;
	IterCookie* c = users.InitForIteration();

	while ( (user = users.NextEntry( key, c )) )
		if ( user->HasClientInput( mask ) )
			{
			GlishEvent *e = user->NextEvent( mask );

			if ( ! e )	// dUser has exited
				{
				if ( glishd_verbose )
					syslog( LOG_INFO, "user daemon exited: %s", user->Id() );
				// At some point, we'll need to do "shared"
				// client cleanup here too.
				clear_clients_registered_to( key );
				free_memory( users.Remove( key ) );
				delete user;
				}
			else
				{
				if ( ! strcmp( e->name, "*register-persistent*" ) )
					Register( e->value, key );
				if ( ! strcmp( e->name, "client" ) )
					CreateClient( e->value, key );
				if ( ! strcmp( e->name, "client-up" ) )
					ClientRunning( e->value, key, user );
				if ( ! strcmp( e->name, "client-gone" ) )
					ClientGone( e->value, key, user );
				}
			}
	}

int dServer::AddInputMask( fd_set *mask )
	{
	int count = GlishDaemon::AddInputMask( mask );
	const char* key = 0;
	dUser *user = 0;
	IterCookie* c = users.InitForIteration();

	while ( (user = users.NextEntry( key, c )) )
		count += user->AddInputMask( mask );

	if ( accept_sock.FD() > 0 && ! FD_ISSET( accept_sock.FD(), mask ) )
		{
		FD_SET( accept_sock.FD(), mask );
		++count;
		}

	return count;
	}

dServer::~dServer()
	{
	closelog();

	const char *key = 0;
	dUser *user = 0;
	IterCookie* c = users.InitForIteration();
	while ( (user = users.NextEntry( key, c )) )
		{
		// free key
		free_memory( users.Remove( key ) );
		delete user;
		}

	if ( id ) free_memory(id);
	}

void dServer::FatalError()
	{
	// close port so it is freed up otherwise it seems to
	// take some time for the OS to realize the port is free.
	close(accept_sock.FD());
	GlishDaemon::FatalError();
	}

Interp::~Interp( )
	{
	delete interpreter;

	const char *key = 0;
	LocalExec *client = 0;
	IterCookie* c = clients.InitForIteration();
	while ( (client = clients.NextEntry( key, c )) )
		{
		// free key
		free_memory( clients.Remove( key ) );
		delete client;
		}

	free_memory( work_dir );
	}

int Interp::NextRequest( GlishEvent* e, dUser *hub, GlishEvent*& internal_event )
	{
	internal_event = 0;

	if ( ! e )
		return 0;

	if ( streq( e->name, "setwd" ) )
		SetWD( e->value );

	else if ( streq( e->name, "setbinpath" ) )
		SetBinPath( e->value );

	else if ( streq( e->name, "setldpath" ) )
		SetLdPath( e->value );

	else if ( streq( e->name, "ping" ) )
		PingClient( e->value );

	else if ( streq( e->name, "client" ) )
		CreateClient( e->value, hub );

	else if ( streq( e->name, "client-up" ) )
		ClientRunning( e->value, hub );

	else if ( streq( e->name, "shell" ) )
		ShellCommand( e->value );

	else if ( streq( e->name, "kill" ) )
		KillClient( e->value );

	else if ( streq( e->name, "probe" ) )
		Probe( e->value );

	else if ( e->name[0] == '*' )
		// Internal event for glishd itself.
		internal_event = e;

	else
		interpreter->Unrecognized();

	return 1;
	}

void Interp::SetWD( Value* v )
	{
	free_memory( work_dir );
	did_wd_msg = 0;

	work_dir = v->StringVal();
	ChangeDir();	// try it out to see if it's okay
	}

void Interp::SetBinPath( Value* path )
	{
	if ( binpath ) Unref( binpath );
	Ref( path );
	binpath = path;
	}

void Interp::SetLdPath( Value* path )
	{
	if ( ldpath ) Unref( ldpath );
	Ref( path );
	ldpath = path;
	}

void Interp::PingClient( Value* client_id )
	{
	char* id = client_id->StringVal();
	LocalExec* client = clients[id];

	if ( ! client )
		syslog( LOG_ERR, "no such client, \"%s\"", id );
	else
		client->Ping();

	free_memory( id );
	}

void Interp::CreateClient( Value* value, dUser *hub )
	{
	const Value *name_val = value->HasRecordElement( "name" );
	const char *name_str = name_val ? name_val->StringPtr(0)[0] : 0;

	if ( ! name_str ) return;

	if ( binpath ) set_executable_path( binpath->StringPtr(0), binpath->Length() );
	char *lookup = which_executable(name_str);

	if ( lookup )
		{
		Client *persistent = hub->LookupClient(lookup);
		if ( persistent )
			{
			charptr *name = name_val->StringPtr( );
			free_memory( (char*) name[0] );
			name[0] = lookup;

			if ( glishd_verbose )
				{
				char *str = value->StringVal();
				syslog( LOG_INFO, "joining shared client: %s", str );
				free_memory( str );
				}

			persistent->PostEvent( "client", value );
			return;
			}
		}
	else if ( name_str && is_regular_file( name_str ) )				// Script client?
		{
		Client *persistent = hub->LookupClient( name_str );
		if ( persistent )
			{

			if ( glishd_verbose )
				{
				char *str = value->StringVal();
				syslog( LOG_INFO, "joining shared script client: %s", str );
				free_memory( str );
				}

			persistent->PostEvent( "client", value );
			return;
			}
		}			
		  

	Value *argv_val = value->Field( "argv", TYPE_STRING );
	if ( ! argv_val ) return;

	int argc = argv_val->Length();

	if ( argc == 0 )
		{
		free_memory( lookup );
		return;
		}

	charptr* argv = argv_val->StringPtr(0);
	if ( binpath ) set_executable_path( binpath->StringPtr(0), binpath->Length() );
	char *name = which_executable( argv[0] );

	if ( ! name )
		{
		free_memory( lookup );
		return;
		}

	if ( ldpath ) putenv(ldpath->StringVal());

	charptr* client_argv = (charptr*) alloc_memory(sizeof(charptr) * (argc + 1));
	client_argv[0] = name;

	for ( int i = 1; i < argc; ++i )
		client_argv[i] = argv[i];
	client_argv[argc] = 0;

	ChangeDir();
	LocalExec* exec = new LocalExec( name, client_argv );

	if ( exec->ExecError() )
		{
		glish_error->Report( "problem exec'ing client ", 
			client_argv[0], ": ", sys_errlist[errno] );
		free_memory( lookup );
		return;
		}

	clients.Insert( lookup, exec );

	free_memory( client_argv );
	free_memory( name );
	}

void Interp::ClientRunning( Value* client, dUser *hub )
	{
	client->Polymorph( TYPE_STRING );

	int argc = client->Length();

	if ( argc < 1 )
		{
		glish_error->Report( "no client name given" );
		interpreter->PostEvent( "client-up-reply", false_value );
		return;
		}

	if ( binpath ) set_executable_path( binpath->StringPtr(0), binpath->Length() );
	const char *name_str = client->StringPtr(0)[0];

	char *name = which_executable( name_str );

	if ( name && hub->LookupClient(name) )
		{
		Value true_value( glish_true );
		interpreter->PostEvent( "client-up-reply", &true_value );
		if ( name != name_str ) free_memory( name );
		return;
		}

	else  if ( hub->LookupClient( name_str ) && is_regular_file( name_str ) )	// Script client?
		{
		Value true_value( glish_true );
		interpreter->PostEvent( "client-up-reply", &true_value );
		return;
		}

	interpreter->PostEvent( "client-up-reply", false_value );
	if ( name != name_str ) free_memory( name );
	}


void Interp::ShellCommand( Value* cmd )
	{
	char* command;
	if ( ! cmd->FieldVal( "command", command ) )
		glish_error->Report( "remote glishd received bad shell command:",
				cmd );

	char* input;
	if ( ! cmd->FieldVal( "input", input ) )
		input = 0;

	ChangeDir();

	FILE* shell = popen_with_input( command, input );

	if ( ! shell )
		{
		Value F( glish_false );
		interpreter->PostEvent( "fail", &F );
		}
	else
		{
		// ### This is an awful lot of events; much simpler would
		// be to slurp up the entire output into an array of strings
		// and send that back.  Value::AssignElements makes this
		// easy since it will grow the array as needed.  The
		// entire result could then be stuffed into a record.

		Value T( glish_true );

		interpreter->PostEvent( "okay", &T );
		char line_buf[8192];

		while ( fgets( line_buf, sizeof( line_buf ), shell ) )
			interpreter->PostEvent( "shell_out", line_buf );

		interpreter->PostEvent( "done", &T );

		// Cfront, in its infinite bugginess, complains about
		// "int assigned to enum glish_bool" if we use
		//
		//	Value status_val( pclose( shell ) );
		//
		// here, so instead we create status_val dynamically.

		Value* status_val = new Value( pclose_with_input( shell ) );

		interpreter->PostEvent( "status", status_val );

		Unref( status_val );
		}

	free_memory( command );
	free_memory( input );
	}


void Interp::KillClient( Value* client_id )
	{
	char* id = client_id->StringVal();
	LocalExec* client = clients[id];

	if ( ! client )
		glish_error->Report( "no such client ", id );

	else
		{
		// free key
		free_memory(clients.Remove( id ));
		delete client;
		}

	free_memory( id );
	}


void Interp::Probe( Value* /* probe_val */ )
	{
	interpreter->PostEvent( "probe-reply", false_value );
	}

void Interp::ChangeDir()
	{
	if ( chdir( work_dir ) < 0 && ! did_wd_msg )
		{
		glish_error->Report( "couldn't change to directory ", work_dir, ": ",
					sys_errlist[errno] );
		did_wd_msg = 1;
		}
	}


const char *get_prog_name(const char* full_path )
	{
	if ( strchr( full_path, '/' ) == (char*) NULL )
		return full_path;

	int i = 0;
	while ( full_path[i] != '\0' ) ++i;
	while ( full_path[i] != '/'  ) --i;
	return full_path + (i+1) * sizeof( char );
	}

void glishd_sighup()
	{
	if ( current_daemon )
		current_daemon->Invalidate();
	unblock_signal(SIGHUP);
	}


#define DEFINE_SIG_FWD(NAME,STRING,SIGNAL)				\
void NAME( )								\
	{								\
	if ( current_daemon )						\
		current_daemon->FatalError();				\
									\
	syslog( LOG_ERR, STRING );					\
	install_signal_handler( SIGNAL, (signal_handler) SIG_DFL );	\
	unblock_signal(SIGNAL);						\
	}

DEFINE_SIG_FWD(glishd_sigsegv,"EXITING with segmentation violation (SIGSEGV)",SIGSEGV)
DEFINE_SIG_FWD(glishd_sigbus,"EXITING with bus error (SIGBUS)",SIGBUS);
DEFINE_SIG_FWD(glishd_sigill,"EXITING with illegal instruction (SIGILL)",SIGILL);
#ifdef SIGEMT
DEFINE_SIG_FWD(glishd_sigemt,"EXITING with SIGEMT",SIGEMT);
#endif
DEFINE_SIG_FWD(glishd_sigfpe,"EXITING with floating point exception (SIGFPE)",SIGFPE);
DEFINE_SIG_FWD(glishd_sigtrap,"EXITING with trace trap (SIGTRAP)",SIGTRAP);
#ifdef SIGSYS
DEFINE_SIG_FWD(glishd_sigsys,"EXITING with bad system call (SIGSYS)",SIGSYS);
#endif

void install_terminate_handlers()
	{
	(void) install_signal_handler( SIGSEGV, glishd_sigsegv );
	(void) install_signal_handler( SIGBUS, glishd_sigbus );
	(void) install_signal_handler( SIGILL, glishd_sigill );
#ifdef SIGEMT
	(void) install_signal_handler( SIGEMT, glishd_sigemt );
#endif
	(void) install_signal_handler( SIGFPE, glishd_sigfpe );
	(void) install_signal_handler( SIGTRAP, glishd_sigtrap );
#ifdef SIGSYS
	(void) install_signal_handler( SIGSYS, glishd_sigsys );
#endif
	}

main( int argc, char **argv )
	{
	GlishDaemon *dmon;

	int collect = 1;
	char **argv_mod = (char**) alloc_memory( sizeof(char*) * argc );
	int argc_mod = 1;
	argv_mod[0] = argv[0];
	for ( int i=1; i < argc; ++i )
		{
		if ( collect && argv[i][0] == '-' && argv[i][1] == '-' )
			{
			if ( argv[i][2] == '\0' ) collect = 0;
			else if ( ! strcmp( argv[i], "--verbose" ) )
				{
				glishd_verbose = 1;
				continue;
				}
			else
				{
				// Got a bad options, die if root, eat if non-root
				if ( getuid() == 0 )
					{
					fprintf( stderr, "Unknown option: %s\n", argv[i] );
					exit(1);
					}
				continue;
				}
			}
		else
			collect = 0;

		argv_mod[argc_mod++] = argv[i];
		}

	if ( getuid() == 0 )
		dmon = new dServer( argc_mod, argv_mod );
	else
		dmon = new dUser( argc_mod, argv_mod );

	dmon->loop( );

	delete dmon;

	return 0;
	}
