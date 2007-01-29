// $Id: LdAgent.h,v 19.12 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 2002 Associated Universities Inc.
#ifndef ldagent_h
#define ldagent_h

#include "Agent.h"
#include "Select.h"
#include "Glish/Proxy.h"
#include <pthread.h>

class Sequencer;
class TaskAttr;
class LoadedAgent;

class LoadedProxyStore : public ProxyStore {
    friend class LoadedAgent;
    friend class LoadedProxySelectee;
    friend class LoadedAgentSelectee;
    public:
	LoadedProxyStore( Sequencer *s, int in, int out, GlishLoopFunc );
	IValue *SendEvent( const char* event_name, parameter_list* args,
				int is_request, u_long flags, Expr *from_subsequence=0 );

	GlishEvent* NextEvent( EventSource* source );
	GlishEvent* NextEvent(const struct timeval *timeout = 0, int &timedout = glish_timedoutdummy)
							{ return NextEvent( (EventSource*) 0 ); }

	int ReplyPending() const { return pending_reply ? 1 : 0; }
	void Reply( const Value *, const ProxyId &proxy_id=glish_proxyid_dummy );
	void PostEvent( const GlishEvent* event, const EventContext &context = glish_ec_dummy );
	void PostEvent( const char* event_name, const Value* event_value,
			const EventContext &context = glish_ec_dummy,
			const ProxyId &proxy_id=glish_proxyid_dummy );

	void Error( const char* msg, const ProxyId &proxy_id=glish_proxyid_dummy );
	void Error( const char* fmt, const char* arg, const ProxyId &proxy_id=glish_proxyid_dummy );
	void Error( const Value *v, const ProxyId &proxy_id=glish_proxyid_dummy );
	void Unrecognized( const ProxyId &proxy_id=glish_proxyid_dummy );

	void Loop();

	void Initialized( );
	int Done( ) const { return done; }

    private:

	char *TakePending( ) { char *t=pending_reply; pending_reply=0; return t; }
	const ProxyId getId( );

	GlishLoopFunc loaded_loop;
	static void *start_thread( void* );
	static void fileproc( void * );
	void doLoop( );
	int done;
	int do_quiet;

	pthread_mutex_t init_lock;

	pthread_mutex_t in_lock;
	event_list incoming;
	pthread_mutex_t out_lock;
	int in_fd;
	int out_fd;
	event_list outgoing;
	GlishEvent *last_event;
	char *pending_reply;
	Sequencer *seq;
	int task_id;
	char *task_str;
	pthread_t thread;
};

// Selectee for the loaded client on the interpreter side
class LoadedAgentSelectee : public Selectee {
    public:
	LoadedAgentSelectee( Sequencer* s, LoadedProxyStore *store, LoadedAgent *a, int source_fd );
	int NotifyOfSelection();
    protected:
	LoadedProxyStore *proxy_store;
	LoadedAgent *agent;
	Sequencer* sequencer;
	int in_fd;
};

class LoadedAgent : public ProxySource {
    public:
	LoadedAgent( const_args_list *args, TaskAttr *task_attrs, Sequencer *s );
	IValue *SendEvent( const char* event_name, parameter_list* args,
			   int is_request, u_long flags, Expr *from_subsequence=0 );
	IValue* SendEvent( const char* event_name, parameter_list* args,
			   int is_request, u_long flags, const ProxyId &proxy_id );
	IValue* SendEvent( const char* event_name, IValue *&event_val,
			   int is_request=0, u_long flags=0,
			   const ProxyId &proxy_id=glish_proxyid_dummy,
			   int is_bundle=0 );

	~LoadedAgent( );

	const char *TaskID( ) const { return stor->task_str; }

    private:

	void *handle;

	LoadedProxyStore *stor;
	LoadedAgentSelectee *selectee;

	// pipes to trigger event notification
	//
	//   *   out triggers Tk end
	//   *   in triggers interpreter end
	//
	int out[2];
	int in[2];
};

#endif
