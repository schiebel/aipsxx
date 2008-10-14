// $Id: Proxy.h,v 19.0 2003/07/16 05:15:53 aips2adm Exp $
// Copyright (c) 1998 Associated Universities Inc.
#ifndef proxy_h
#define proxy_h

#include "Glish/Client.h"

class Proxy;
class ProxyStore;
glish_declare(PList,Proxy);
typedef PList(Proxy) proxy_list;

class event_queue_item;
glish_declare(PList,event_queue_item);
typedef PList(event_queue_item) event_queue;


typedef void (*PxyStoreCB1)( ProxyStore *, Value *, GlishEvent *, void * );
typedef void (*PxyStoreCB2)( ProxyStore *, Value *, void * );
typedef void (*PxyStoreCB3)( ProxyStore *, Value * );
class pxy_store_cbinfo;
glish_declare(PDict,pxy_store_cbinfo);
typedef PDict(pxy_store_cbinfo) pxy_store_cbdict;

//### Initialization function for loaded objects...
typedef void (*GlishInitFunc)( ProxyStore *, int, const char * const * );
typedef void (*GlishCallbackFunc) ( void * );
struct GlishCallback {
	int fd;
	GlishCallbackFunc func;
	void *data;
	GlishCallback( const GlishCallback &o ) : fd( o.fd ), func( o.func ), data( o.data ) { }
	GlishCallback( int f, GlishCallbackFunc cb, void *d=0 ) : fd( f ), func( cb ), data( d ) { }
};
typedef void (*GlishLoopFunc)( ProxyStore *, const GlishCallback *read_info, int, const GlishCallback *write_info, int );

class ProxyStore {
friend class Proxy;
    public:
	enum ShareType { NONSHARED=Client::NONSHARED, USER=Client::USER,
			 GROUP=Client::GROUP, WORLD=Client::WORLD };

	ProxyStore( ) { };

	virtual ~ProxyStore( ) { }

	virtual GlishEvent* NextEvent(const struct timeval *timeout = 0, int &timedout = glish_timedoutdummy) = 0;
	virtual GlishEvent* NextEvent( EventSource* source ) = 0;

	void Register( const char *string, PxyStoreCB1 cb, void *data = 0 );
	void Register( const char *string, PxyStoreCB2 cb, void *data = 0 );
	void Register( const char *string, PxyStoreCB3 cb );

	Proxy *GetProxy( const ProxyId &proxy_id );

	void Loop( );
	void ProcessEvent( GlishEvent *e );

	int QueuedEvents() const { return equeue.length() > 0; }

	virtual int ReplyPending() const = 0;
	virtual void Reply( const Value *, const ProxyId &proxy_id=glish_proxyid_dummy ) = 0;
	virtual void Error( const char* msg, const ProxyId &proxy_id=glish_proxyid_dummy ) = 0;
	virtual void Error( const char* fmt, const char* arg, const ProxyId &proxy_id=glish_proxyid_dummy ) = 0;
	virtual void Error( const Value *v, const ProxyId &proxy_id=glish_proxyid_dummy ) = 0;
	virtual void Unrecognized( const ProxyId &proxy_id=glish_proxyid_dummy ) = 0;

	virtual void PostEvent( const GlishEvent* event, const EventContext &context = glish_ec_dummy ) = 0;
	virtual void PostEvent( const char* event_name, const Value* event_value,
			const EventContext &context = glish_ec_dummy,
			const ProxyId &proxy_id=glish_proxyid_dummy ) = 0;

	virtual const char *GetOption( const char * ) const;

	virtual void Initialized( ) { };
	virtual int Done( ) const = 0;

    protected:
	virtual char *TakePending( ) = 0;

	void addProxy( Proxy * );
	void removeProxy( Proxy * );
	virtual const ProxyId getId( ) = 0;

	proxy_list       pxlist;
	pxy_store_cbdict cbdict;
	event_queue	 equeue;
};

class ClientProxyStore : public ProxyStore{
    public:

	ClientProxyStore( int &argc, char **argv,
		    ShareType multithreaded = NONSHARED );

	~ClientProxyStore( );

	GlishEvent* NextEvent(const struct timeval *timeout = 0, int &timedout = glish_timedoutdummy);
	GlishEvent* NextEvent( EventSource* source );

	// ------ Pass Through to Client ------
	void Unrecognized( const ProxyId &proxy_id=glish_proxyid_dummy )
		{ client.Unrecognized( proxy_id ); }
	void Error( const char* msg, const ProxyId &proxy_id=glish_proxyid_dummy )
		{ client.Error( msg, proxy_id ); }
	void Error( const char* fmt, const char* arg, const ProxyId &proxy_id=glish_proxyid_dummy )
		{ client.Error( fmt, arg, proxy_id ); }
	void Error( const Value *v, const ProxyId &proxy_id=glish_proxyid_dummy )
		{ client.Error( v, proxy_id ); }

	void PostEvent( const GlishEvent* event, const EventContext &context = glish_ec_dummy )
		{ client.PostEvent( event, context ); }
	void PostEvent( const char* event_name, const Value* event_value,
			const EventContext &context = glish_ec_dummy,
			const ProxyId &proxy_id=glish_proxyid_dummy )
		{ client.PostEvent( event_name, event_value, context, proxy_id ); }
	void PostEvent( const char* event_name, const Value* event_value,
			const ProxyId &proxy_id )
		{ PostEvent( event_name, event_value, glish_ec_dummy, proxy_id ); }
	void PostEvent( const char* event_name, const char* event_value,
			const EventContext &context = glish_ec_dummy,
			const ProxyId &proxy_id =glish_proxyid_dummy )
		{ client.PostEvent( event_name, event_value, context, proxy_id ); }
	void PostEvent( const char* event_name, const char* event_value,
			const ProxyId &proxy_id )
		{ PostEvent( event_name, event_value, glish_ec_dummy, proxy_id ); }
	void PostEvent( const char* event_name, const char* event_fmt, const char* event_arg,
			const EventContext &context = glish_ec_dummy,
			const ProxyId &proxy_id=glish_proxyid_dummy )
		{ client.PostEvent( event_name, event_fmt, event_arg, context, proxy_id ); }
	void PostEvent( const char* event_name, const char* event_fmt,
			const char* event_arg, const ProxyId &proxy_id )
		{ PostEvent( event_name, event_fmt, event_arg, glish_ec_dummy, proxy_id ); }
	void PostEvent( const char* event_name, const char* event_fmt, const char* arg1,
			const char* arg2, const EventContext &context = glish_ec_dummy,
			const ProxyId &proxy_id=glish_proxyid_dummy )
		{ client.PostEvent( event_name, event_fmt, arg1, arg2, context, proxy_id ); }
	void PostEvent( const char* event_name, const char* event_fmt, const char* arg1,
			const char* arg2, const ProxyId &proxy_id )
		{ PostEvent( event_name, event_fmt, arg1, arg2, glish_ec_dummy, proxy_id ); }

	void Reply( const Value* event_value, const ProxyId &proxy_id=glish_proxyid_dummy )
		{ client.Reply( event_value, proxy_id ); }
	void Reply( const char *event_value, const ProxyId &proxy_id=glish_proxyid_dummy )
		{ client.Reply( event_value, proxy_id ); }
	void Reply( const char* event_fmt, const char* event_arg,
		    const ProxyId &proxy_id=glish_proxyid_dummy )
		{ client.Reply( event_fmt, event_arg, proxy_id ); }
	void Reply( const char* event_fmt, const char* arg1,
		    const char* arg2, const ProxyId &proxy_id=glish_proxyid_dummy )
		{ client.Reply( event_fmt, arg1, arg2, proxy_id ); }
	int ReplyPending() const	{ return client.ReplyPending( ); }

	void SetQuiet( ) { client.SetQuiet( ); }
	int AddInputMask( fd_set* mask ) { return client.AddInputMask( mask ); }

	// how to tell if the client is defunct?
	int Done( ) const { return 0; }

    protected:
	Client client;
	char *TakePending( ) { char *t=client.pending_reply; client.pending_reply=0; return t; }
	const ProxyId getId( );
};

class Proxy : public GlishRef {
friend class ProxyStore;
    public:

	Proxy( ProxyStore * );

	virtual ~Proxy( );

	//
	// the pointer returned is Unref()ed, if you want the Proxy object
	// object to survive the "terminate" event, you should overload this
	// function and return 0.
	//
	virtual Proxy *Done( Value * );
	virtual void ProcessEvent( const char *name, Value *val ) = 0;

	const ProxyId &Id( ) const { return id; }

	void SendCtor( const char *name = "new", Proxy *source = 0 );

#if 0
	void Unrecognized( )	{ store->Unrecognized( id ); }

	void PostEvent( const char* event_name, const char* event_value,
			const EventContext &context = glish_ec_dummy )
				{ store->PostEvent( event_name, event_value, context, id ); }

	void PostEvent( const char* event_name, const char* event_fmt, const char* arg1,
			const EventContext &context = glish_ec_dummy )
				{ store->PostEvent( event_name, event_fmt, arg1, context, id ); }
	void PostEvent( const char* event_name, const char* event_fmt, const char* arg1,
			const char* arg2, const EventContext &context = glish_ec_dummy )
				{ store->PostEvent( event_name, event_fmt, arg1, arg2, context, id ); }

	void Reply( const char *event_value ) { store->Reply( event_value, id ); }
	void Reply( const char* event_fmt, const char* arg )
				{ store->Reply( event_fmt, arg, id ); }
	void Reply( const char* event_fmt, const char* arg1, const char* arg2 )
				{ store->Reply( event_fmt, arg1, arg2, id ); }
#endif

	void Reply( const Value* event_value ) { store->Reply( event_value, id ); }

	void PostEvent( const char* event_name, const Value* event_value,
			const EventContext &context = glish_ec_dummy )
				{ store->PostEvent( event_name, event_value, context, id ); }

	void PostEvent( const GlishEvent* event, const EventContext &context = glish_ec_dummy )
				{ store->PostEvent( event, context ); }

	int ReplyPending() const { return store->ReplyPending(); }

	void Error( const char* msg ) { store->Error( msg, id ); }
	void Error( Value *val ) { store->Error( val, id ); }
	void Error( const char* fmt, const char* arg )
				{ store->Error( fmt, arg, id ); }

    protected:
	void setId( const ProxyId &i );
	ProxyStore *store;
	ProxyId id;
};

#endif
