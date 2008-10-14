// $Id: Client.h,v 19.0 2003/07/16 05:15:48 aips2adm Exp $
// Copyright (c) 1993 The Regents of the University of California.
// Copyright (c) 1997 Associated Universities Inc.
#ifndef client_h
#define client_h

#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

#include "Glish/Value.h"
#include "sos/io.h"

class sos_in;
class sos_out;
class ProxyId;

extern ProxyId glish_proxyid_dummy;

class EventContext GC_FINAL_CLASS {
public:
	EventContext(const char *client_name_ = 0, const char *context_ = 0 );
	EventContext(const EventContext &c);
	EventContext &operator=(const EventContext &c);
	const char *id() const { return context; }
	const char *name() const { return client_name; }
	~EventContext();
	int operator==(const EventContext &c) const
			{ return strcmp( context, c.context ) ? 0 : 1; }
	int operator!=(const EventContext &c) const
			{ return strcmp( context, c.context ) ? 1 : 0; }
private:
	char *context;
	char *client_name;
	static unsigned int client_count;
};

class GlishEvent : public GlishObject {
public:
	GlishEvent( const char* arg_name, const Value* arg_value );
	GlishEvent( const char* arg_name, Value* arg_value );
	GlishEvent( char* arg_name, Value* arg_value );

	~GlishEvent();

	const char* Name() const	{ return name; }
	Value* Val() const		{ return value; }

	int IsRequest() const;
	int IsReply() const;
	int IsProxy() const;
	int IsBundle() const;
	int IsQuiet() const;
	unsigned char Flags() const	{ return flags; }

	void SetIsRequest();
	void SetIsReply();
	void SetIsProxy();
	void SetIsBundle();
	void SetIsQuiet();
	void SetFlags( unsigned char new_flags ) { flags = new_flags; }

	void SetValue( Value *v );
	void SetValue( const Value *v );

	// These are public for historical reasons.
	const char* name;
	Value* value;

protected:
	unsigned char flags;
	int delete_name;
	int delete_value;
	};

typedef enum event_src_type { INTERP, ILINK, STDIO, GLISHD } event_src_type;

class EventSource : public GlishObject {
    public:
	EventSource( int read_fd, int write_fd, event_src_type type_ = INTERP ) :
		source( read_fd, &common ), sink( write_fd, &common ), context( ), type(type_) { }

	EventSource( int read_fd, int write_fd, event_src_type type_,
		const EventContext &context_ ) : source( read_fd, &common ),
		sink( write_fd, &common ), context(context_), type(type_) { }

	EventSource( int fd, event_src_type type_ = INTERP ) : 
	    source( fd, &common ), sink( fd, &common ), context( ), type(type_) { }

	EventSource( int fd, event_src_type type_, const EventContext &context_ ) :
			source( fd, &common ), sink( fd, &common ), context( context_ ), type(type_) { }

	// destructor closes the fds
	~EventSource() { }

	sos_fd_sink &Sink()	{ return sink; }
	sos_fd_source &Source()	{ return source; }

	const EventContext &Context() const { return context; }
	event_src_type Type() { return type; }

    protected:
	sos_common common;
	sos_fd_source source;
	sos_fd_sink sink;
	EventContext context;
	event_src_type type;
	};


class ProxyId GC_FINAL_CLASS {
    public:
	ProxyId( ) { ary[0]=ary[1]=ary[2]=0; }
	ProxyId( int interp_, int task_, int id_ )
		{ ary[0]=interp_; ary[1]=task_; ary[2]=id_; }
	ProxyId( const int *a )
		{ ary[0]=a[0]; ary[1]=a[1]; ary[2]=a[2]; }
	ProxyId( const ProxyId &o )
		{ ary[0] = o.ary[0]; ary[1] = o.ary[1]; ary[2] = o.ary[2]; }
	//
	// takes client-side agent record
	//
	ProxyId( const Value * );

	int interp() const { return ary[0]; }
	int task() const { return ary[1]; }
	int id() const { return ary[2]; }
	int operator==( int v ) const
		{ return ary[0] == v && ary[1] == v && ary[2] == v; }
	int operator==( const ProxyId &o ) const
		{ return ary[0] == o.ary[0] && ary[1] == o.ary[1] && ary[2] == o.ary[2]; }
	int operator!=( int v ) const
		{ return ary[0] != v && ary[1] != v && ary[2] != v; }
	int operator!=( const ProxyId &o ) const
		{ return ary[0] != o.ary[0] || ary[1] != o.ary[1] || ary[2] != o.ary[2]; }
	ProxyId &operator=( const ProxyId &o )
		{ ary[0] = o.ary[0]; ary[1] = o.ary[1]; ary[2] = o.ary[2]; return *this; }
	void set( )
		{ ary[0]=0; ary[1]=0; ary[2]=0; }
	void set( int interp_, int task_, int id_ )
		{ ary[0]=interp_; ary[1]=task_; ary[2]=id_; }
	void set( const int *a )
		{ ary[0]=a[0]; ary[1]=a[1]; ary[2]=a[2]; }
	const int *array() const { return ary; }
	static int len() { return 3; }
    private:
	int ary[3];
};

// Holds information regarding outbound "link" commands.
class EventLink;

glish_declare(PList,EventLink);
glish_declare(PDict,EventLink);

glish_declare(PList,EventSource);
typedef PList(EventSource) source_list;
glish_declare(PDict,EventSource);

typedef PList(EventLink) event_link_list;
glish_declare(PDict,event_link_list);

glish_declare(PList,GlishEvent);
typedef PList(GlishEvent) event_list;

typedef PDict(event_link_list) event_link_context_list;
glish_declare(PDict,event_link_context_list);

glish_declare(Dict,int);
typedef Dict(int) sink_id_list;
glish_declare(PDict,sink_id_list);

class AcceptSocket;

extern int glish_timedoutdummy;
extern EventContext glish_ec_dummy;

class Client GC_FINAL_CLASS {
    friend class ClientProxyStore;
    public:
	//
	//  The "Type" describes how the client is shared by glish users
	//  on a particular machine:
	//
	//  NONSHARED => new client is started each time
	//  USER => one client is shared for a particular user
	//  GROUP => one client is shared for all members of a (unix) group
	//  WORLD => one client is shared by all users
	//
	enum ShareType { NONSHARED=0, USER, GROUP, WORLD };
	//
	//  Describes how the shared client should be have when there are
	//  no more interpreters attached to it.
	//
	enum PersistType { TRANSIENT=0, PERSIST };

	// Client's are constructed by giving them the program's
	// argc and argv.  Any client-specific arguments are read
	// and stripped off.
	Client( int& argc, char** argv, ShareType arg_multithreaded = NONSHARED, PersistType arg_persist = TRANSIENT )
		{ Init( argc, argv, arg_multithreaded, arg_persist, 0 ); }

	// Alternatively, a Client can be constructed from fd's for
	// reading and writing events and a client name.  This version
	// of the constructor does not generate an initial "established"
	// event.
	Client( int client_read_fd, int client_write_fd, const char* name ) : last_context( name )
		{ Init( client_read_fd, client_write_fd, name, 0 ); }
	Client( int client_read_fd, int client_write_fd, const char* name,
		const EventContext &arg_context, ShareType arg_multithreaded = NONSHARED ) : last_context(arg_context)
		{ Init( client_read_fd, client_write_fd, name, arg_context, arg_multithreaded, 0 ); }

	virtual ~Client();

	// Wait for the next event to arrive and return a pointer to 
	// it.	The GlishEvent will be Unref()'d on the next call to
	// NextEvent(), so if the caller wishes to keep the GlishEvent
	// (or its Value) they must Ref() the GlishEvent (or its Value).
	//
	// If a timeout is specified and no activity has occured during
	// that period 0 is returned and timedout is set to true.
	// 
	// If 0 is otherwise returned, the interpreter connection has been 
	// broken then 0 is returned (and the caller should terminate).
	//
	virtual GlishEvent* NextEvent(const struct timeval *timeout = 0,
				      int &timedout = glish_timedoutdummy);

	// Another version of NextEvent which can be passed an fd_set
	// returned by select() to aid in determining from where to
	// read the next event.
	virtual GlishEvent* NextEvent( fd_set* mask );

	// Returns the next event from the given event source.
	virtual GlishEvent* NextEvent( EventSource* source );

	// Called by the main program (or whoever called NextEvent()) when
	// the current event is unrecognized.
	void Unrecognized( const ProxyId &proxy_id=glish_proxyid_dummy );

	// Called to report that the current event has an error.
	void Error( const char* msg, const ProxyId &proxy_id=glish_proxyid_dummy );
	void Error( const char* fmt, const char* arg, const ProxyId &proxy_id=glish_proxyid_dummy );
	void Error( const Value *v, const ProxyId &proxy_id=glish_proxyid_dummy );

	// Sends an event with the given name and value.
	void PostEvent( const GlishEvent* event, const EventContext &context = glish_ec_dummy );
	void PostEvent( const char* event_name, const Value* event_value,
			const EventContext &context = glish_ec_dummy,
			const ProxyId &proxy_id=glish_proxyid_dummy );
	void PostEvent( const char* event_name, const Value* event_value,
			const ProxyId &proxy_id )
			{ PostEvent( event_name, event_value, glish_ec_dummy, proxy_id ); }

	// Sends an event with the given name and character string value.
	void PostEvent( const char* event_name, const char* event_value,
			const EventContext &context = glish_ec_dummy,
			const ProxyId &proxy_id =glish_proxyid_dummy );
	void PostEvent( const char* event_name, const char* event_value,
			const ProxyId &proxy_id )
			{ PostEvent( event_name, event_value, glish_ec_dummy, proxy_id ); }

	// Sends an event with the given name, using a printf-style format
	// and an associated string argument.  For example,
	//
	//	client->PostEvent( "error", "couldn't open %s", file_name );
	//
	void PostEvent( const char* event_name, const char* event_fmt, const char* event_arg,
			const EventContext &context = glish_ec_dummy,
			const ProxyId &proxy_id=glish_proxyid_dummy );
	void PostEvent( const char* event_name, const char* event_fmt,
			const char* event_arg, const ProxyId &proxy_id )
			{ PostEvent( event_name, event_fmt, event_arg, glish_ec_dummy, proxy_id ); }
	void PostEvent( const char* event_name, const char* event_fmt, const char* arg1,
			const char* arg2, const EventContext &context = glish_ec_dummy,
			const ProxyId &proxy_id=glish_proxyid_dummy );
	void PostEvent( const char* event_name, const char* event_fmt, const char* arg1,
			const char* arg2, const ProxyId &proxy_id )
			{ PostEvent( event_name, event_fmt, arg1, arg2, glish_ec_dummy, proxy_id ); }

	// Reply to the last received event.
	void Reply( const Value* event_value, const ProxyId &proxy_id=glish_proxyid_dummy );
	void Reply( const char *event_value, const ProxyId &proxy_id=glish_proxyid_dummy );
	void Reply( const char* event_fmt, const char* event_arg,
		    const ProxyId &proxy_id=glish_proxyid_dummy );
	void Reply( const char* event_fmt, const char* arg1,
		    const char* arg2, const ProxyId &proxy_id=glish_proxyid_dummy );

	// True if the Client is expecting a reply, false otherwise.
	int ReplyPending() const	{ return pending_reply != 0; }

	// These functions are used to indicate if events which are dropped
	// (in the interpreter) by should result in warning by the interpreter
	// or not. If quiet is set, no warnings are reported. Note that Error()
	// and Unrecognized() are never quiet...
	void SetQuiet( ) { do_quiet = 1; }
	void ClearQuiet( ) { do_quiet = 0; }
	int IsQuiet( ) { return do_quiet; }

	// For any file descriptors this Client might read events from,
	// sets the corresponding bits in the passed fd_set.  The caller
	// may then use the fd_set in a call to select().  Returns the
	// number of fd's added to the mask.
	int AddInputMask( fd_set* mask );

	// Returns true if the following mask indicates that input
	// is available for the client.
	int HasClientInput( fd_set* mask );

	// Returns true if the client was invoked by a Glish interpreter,
	// false if the client is running standalone.
	int HasInterpreterConnection()
		{ return int(have_interpreter_connection); }

	// Returns true if the client has *some* event source, either
	// the interpreter or stdin; false if not.
	int HasEventSource()	{ return ! int(no_glish); }

	// Returns the shared type.
	ShareType Shared() { return multithreaded; }

	// return context of last event received
	const EventContext &LastContext() { return last_context; }

	// access to the event sources this client is managing
	source_list &EventSources( ) { return event_sources; }

	static const char *Name( ) { return initial_name; }

    protected:

	void Init( int& argc, char** argv, ShareType arg_multithreaded, PersistType arg_persist, const char *script_file );
	void Init( int client_read_fd, int client_write_fd, const char* name, const char *script_file );
	void Init( int client_read_fd, int client_write_fd, const char* name,
		   const EventContext &arg_context, ShareType arg_multithreaded, const char *script_file );

	Client( int& argc, char** argv, ShareType arg_multithreaded, PersistType arg_persist, const char *script_file )
		{ Init( argc, argv, arg_multithreaded, arg_persist, script_file ); }

	// Register with glishd if multithreaded, adding event_source
	// that corresponds to the glishd.  Returns nonzero if connection
	// failed for any reason (eg no glishd).
	int ReRegister( char* registration_name = 0 );

	friend void Client_signal_handler( );

	// Performs Client initialization that doesn't depend on the
	// arguments with which the client was invoked.
	void ClientInit();

	// Creates the necessary signal handler for dealing with client
	// "ping"'s.
	void CreateSignalHandler();

	// Sends out the Client's "established" event.
	void SendEstablishedEvent( const EventContext &context );

	// Returns the next event from the given event source.
	GlishEvent* GetEvent( EventSource* source );

	// Called whenever a new fd is added (add_flag=1) or deleted
	// (add_flag=0) from those that the client listens to.  By
	// redefining this function, a Client subclass can keep track of
	// the same information that otherwise must be computed by calling
	// AddInputMask() prior to each call to select().
	virtual void FD_Change( int fd, int add_flag );

	// Called asynchronously whenever a ping is received; the
	// interpreter sends a ping whenever a new event is ready and
	// the client was created with the <ping> attribute.
	virtual void HandlePing();

	// Removes a link.
	void UnlinkSink( Value* v );

	// Decodes an event value describing an output link and returns
	// a pointer to a (perhaps preexisting) corresponding EventLink.
	// "want_active" states whether the EventLink must be active
	// or inactive.  "is_new" is true upon return if a new EventLink
	// was created.  Nil is returned upon an error.
	EventLink* AddOutputLink( Value* v, int want_active, int& is_new );

	// Builds a link to the peer specified in "v", the originating
	// link event.  If the link already exists, just activates it.
	// If not, forwards an event telling the link peer how to connect
	// to us.
	void BuildLink( Value* v );

	// Accept a link request from the given socket.  Returns an
	// internal Glish event that can be handed to a caller of
	// NextEvent, which they (should) will then pass along to
	// Unrecognized.
	GlishEvent* AcceptLink( int sock );

	// Rendezvous with a link peer.  The first method is for when
	// we're the originator of the link, the second for when we're
	// responding.
	void RendezvousAsOriginator( Value* v );
	void RendezvousAsResponder( Value* v );

	// Sends the given event.  If sds is non-negative, the event's value
	// is taken from the SDS "sds".
	void SendEvent( const GlishEvent* e, int sds, const EventContext &context_arg );
	void SendEvent( const GlishEvent* e, int sds = -1 )
		{ SendEvent( e, sds, last_context ); }


	void RemoveIncomingLink( int dead_event_source );
	void RemoveInterpreter( EventSource* source );

	const char *initial_client_name;
	// name that us used e.g. by FatalReporter...
	static const char *initial_name;
	int have_interpreter_connection;
	int no_glish;	// if true, no event source whatsoever

	char* pending_reply;	// the name of the pending reply, if any

	// All EventSources, keyed by context and typed
	source_list event_sources;

	// Maps interpreter contexts to output link lists
	//
	// context_links is a PDICT of event_link_contexts_lists,
	//	keyed by context.
	//
	// event_link_context_list is a PDICT of event_link_lists,
	//	keyed by event name.
	//
	// event_link_list is a PLIST of EventLinks.

	PDict(event_link_context_list) context_links;

	// context_sinks and context_sources are PDICTs of sink_id_lists,
	//	keyed by context.
	PDict(sink_id_list) context_sinks;
	PDict(sink_id_list) context_sources;

	GlishEvent* last_event;

	// Previous signal handler; used for <ping>'s.
	glish_signal_handler former_handler;

	const char *local_host;
	char *interpreter_tag;

	// Context of last received event
	EventContext last_context;
	EventContext default_context;

	// Multithreaded or not?
	ShareType multithreaded;
	// Persist after all connections are broken?
	PersistType persistent;

	// Use shared memory
	int useshm;

	// Is this a script client
	const char *script_client;

	int do_quiet;

	void *transcript_file;
	};

Value *read_value( sos_in & );
void write_value( sos_out &, const Value *, const ProxyId &proxy_id=glish_proxyid_dummy );
void write_value( sos_out &, Value *, const char *, char *name, unsigned char flags,
		  const ProxyId &proxy_id=glish_proxyid_dummy, FILE *transcript=0 );
inline void write_value( sos_out &s, Value *v, const char *k, char *name, 
			 const ProxyId &proxy_id=glish_proxyid_dummy, FILE *transcript=0 )
		{ write_value( s, v, k, name, 0, proxy_id, transcript ); }
inline void write_value( sos_out &s, Value *v, const char *k,
			 const ProxyId &proxy_id=glish_proxyid_dummy, FILE *transcript=0 )
		{ write_value( s, v, k, 0, 0, proxy_id, transcript ); }

// returns zero on failure...
int write_agent( sos_out &, Value *, sos_header &, const ProxyId & );

// --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
GlishEvent* recv_event( sos_source &in, FILE *transcript=0 );

extern sos_status *send_event( sos_sink &out, const char* event_name,
			       const GlishEvent* e, int can_suspend = 0,
			       const ProxyId &proxy_id=glish_proxyid_dummy, FILE *transcript=0 );

inline sos_status *send_event( sos_sink &out, const GlishEvent* e, int can_suspend = 0,
			       const ProxyId &proxy_id=glish_proxyid_dummy, FILE *transcript=0 )
	{
	return send_event( out, e->name, e, can_suspend, proxy_id, transcript );
	}
inline sos_status *send_event( sos_sink &out, const GlishEvent* e, FILE *transcript )
	{
	return send_event( out, e->name, e, 0, glish_proxyid_dummy, transcript );
	}

inline sos_status *send_event( sos_sink &out, const char* name, const Value* value,
			       int can_suspend = 0, const ProxyId &proxy_id=glish_proxyid_dummy,
			       FILE *transcript=0 )
	{
	GlishEvent e( name, value );
	return send_event( out, name, &e, can_suspend, proxy_id, transcript );
	}

void set_load_path( Value * );
void set_load_path( char **path, int len );
char *which_shared_object( const char* filename );

#endif	/* client_h */
