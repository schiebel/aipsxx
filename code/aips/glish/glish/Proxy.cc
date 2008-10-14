// $Id: Proxy.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $
// Copyright (c) 1998 Associated Universities Inc.

#include "Glish/glish.h"
RCSID("@(#) $Id: Proxy.cc,v 19.13 2004/11/03 20:38:58 cvsmgr Exp $")
#include "system.h"
#include "Glish/Proxy.h"

//
//  Generates Events:
//
//		o  *proxy-id* to get an ID for each proxy
//		o  *proxy-create* to create a proxy in the interpreter
//
#define PXGETID		"*proxy-id*"
#define PXCREATE	"*proxy-create*"

class pxy_store_cbinfo GC_FINAL_CLASS {
    public:
	pxy_store_cbinfo( PxyStoreCB1 cb, void * data_ ) : cb1(cb), cb2(0), cb3(0), data(data_) { }
	pxy_store_cbinfo( PxyStoreCB2 cb, void * data_ ) : cb1(0), cb2(cb), cb3(0), data(data_) { }
	pxy_store_cbinfo( PxyStoreCB3 cb ) : cb1(0), cb2(0), cb3(cb), data(0) { }
	void invoke( ProxyStore *s, Value *v, GlishEvent *e );
    private:
	PxyStoreCB1 cb1;
	PxyStoreCB2 cb2;
	PxyStoreCB3 cb3;
	void *data;
};

void pxy_store_cbinfo::invoke( ProxyStore *s, Value *v, GlishEvent *e )
	{
	static Value *true_reply = new Value(glish_true);
	if ( cb1 ) (*cb1)( s, v, e, data );
	else if ( cb2 ) (*cb2)( s, v, data );
	else if ( cb3 ) (*cb3)(s,v);
	if ( s->ReplyPending() ) s->Reply(true_reply);
	}

class event_queue_item GC_FINAL_CLASS {
    public:
	event_queue_item( GlishEvent *e, char *&rn ) : event(e), reply_name(rn)
		{ rn = 0; }
	GlishEvent *Event() { return event; }
	char *ReplyName() { return reply_name; }
    protected:
	GlishEvent *event;
	char *reply_name;
};

ClientProxyStore::ClientProxyStore( int &argc, char **argv,
			ShareType multithreaded ) :
		client( argc, argv, (Client::ShareType) multithreaded ) { }
	
ClientProxyStore::~ClientProxyStore( )
	{
	while ( pxlist.length() > 0 )
		{
		Proxy *p = pxlist.remove_nth(0);
		Unref( p );
		}

	IterCookie* c = cbdict.InitForIteration();
	pxy_store_cbinfo *member;
	const char *key;
	while ( (member = cbdict.NextEntry( key, c )) )
		{
		free_memory( (char*) key );
		delete member;
		}
	}

GlishEvent *ClientProxyStore::NextEvent(const struct timeval *timeout, int &timedout)
	{
	if ( equeue.length() )
		{
		timedout = 0;
		Unref(client.last_event);
		event_queue_item *eqi = equeue.remove_nth(0);
		client.last_event = eqi->Event();
		client.pending_reply = eqi->ReplyName();
		delete eqi;
		return client.last_event;
		}
	return client.NextEvent(timeout,timedout);
	}

GlishEvent *ClientProxyStore::NextEvent( EventSource* source )
	{
	if ( equeue.length() )
		{
		Unref(client.last_event);
		event_queue_item *eqi = equeue.remove_nth(0);
		client.last_event = eqi->Event();
		client.pending_reply = eqi->ReplyName();
		delete eqi;
		return client.last_event;
		}

	return client.NextEvent(source);
	}

void ProxyStore::Register( const char *string, PxyStoreCB1 cb, void *data )
	{
	char *s = string_dup(string);
	pxy_store_cbinfo *old = (pxy_store_cbinfo*) cbdict.Insert( s, new pxy_store_cbinfo( cb, data ) );
	if ( old )
		{
		free_memory( s );
		delete old;
		}
	}

void ProxyStore::Register( const char *string, PxyStoreCB2 cb, void *data )
	{
	char *s = string_dup(string);
	pxy_store_cbinfo *old = (pxy_store_cbinfo*) cbdict.Insert( s, new pxy_store_cbinfo( cb, data ) );
	if ( old )
		{
		free_memory( s );
		delete old;
		}
	}

void ProxyStore::Register( const char *string, PxyStoreCB3 cb )
	{
	char *s = string_dup(string);
	pxy_store_cbinfo *old = (pxy_store_cbinfo*) cbdict.Insert( s, new pxy_store_cbinfo( cb ) );
	if ( old )
		{
		free_memory( s );
		delete old;
		}
	}

void ProxyStore::addProxy( Proxy *p )
	{
	ProxyId id(getId( ));

	if ( id != 0 )
		{
		p->setId( id );
		pxlist.append( p );
		}
	}

void ProxyStore::removeProxy( Proxy *p )
	{
	pxlist.remove( p );
	}

const ProxyId ClientProxyStore::getId( )
	{
	static Value *v =  ValCtor::create(glish_true);
	GlishEvent *save_last = client.last_event;
	client.last_event = 0;
	char *rname = client.pending_reply;
	client.pending_reply = 0;

	GlishEvent e( (const char*) PXGETID, (const Value*) v );
	e.SetIsProxy( );
	PostEvent( &e );

	// we could get other events before our
	// *proxy-id* event is responded to...
	GlishEvent *reply = client.NextEvent( );
	while ( strcmp(reply->Name(),PXGETID) )
		{
		equeue.append(new event_queue_item(reply,client.pending_reply));
		client.last_event = 0;
		reply = client.NextEvent( );
		}

	if ( ! reply || reply->Val()->Type() != TYPE_INT ||
	     reply->Val()->Length() != ProxyId::len() )
		{
		Unref( client.last_event );
		client.last_event = save_last;
		return ProxyId();
		}

	ProxyId result(reply->Val()->IntPtr(0));
	Unref( client.last_event );
	client.last_event = save_last;
	client.pending_reply = rname;

	return result;
	}

Proxy *ProxyStore::GetProxy( const ProxyId &proxy_id )
	{
	loop_over_list( pxlist, i )
		if ( pxlist[i]->Id() == proxy_id )
			return pxlist[i];
	return 0;
	}

void ProxyStore::ProcessEvent( GlishEvent *e )
	{
	if ( e->IsProxy() )
		{
		Value *rval = e->Val();
		if ( rval->Type() != TYPE_RECORD )
			{
			Error( "bad proxy value" );
			return;
			}

		const Value *idv = rval->HasRecordElement( "id" );
		Value *val = rval->Field( "value" );
		if ( ! idv || ! val || idv->Type() != TYPE_INT ||
		     idv->Length() != ProxyId::len() )
			{
			Error( "bad proxy value" );
			return;
			}

		ProxyId id(idv->IntPtr(0));
		int found = 0;
		loop_over_list( pxlist, i )
			if ( pxlist[i]->Id() == id )
				{
				found = 1;
				if ( ! strcmp( "terminate", e->Name() ) )
					Unref(pxlist[i]->Done( val ));
				else
					{
					if ( e->IsBundle() )
						{
						if ( val->Type() != TYPE_RECORD )
							{
							Error( "bad event bundle", id );
							return;
							}

						recordptr events = val->RecordPtr(0);
						for ( int x=0; x < events->Length(); ++x )
							{
							const char* bname;
							Value *bval = events->NthEntry( x, bname );
							pxlist[i]->ProcessEvent( &bname[8], bval );
							}
						}
					else
						pxlist[i]->ProcessEvent( e->Name(), val );
					}
				break;
				}

		if ( ! found ) Error( "bad proxy id" );
		}
	else 
		{
		if ( e->IsBundle( ) )
			{
			Value *val = e->Val();
	
			if ( val->Type() != TYPE_RECORD )
				{
				Error( "bad event bundle" );
				return;
				}

			recordptr events = val->RecordPtr(0);
			for ( int x=0; x < events->Length(); ++x )
				{
				const char* bname;
				Value *bval = events->NthEntry( x, bname );
				if ( pxy_store_cbinfo *cbi = cbdict[bname] )
					cbi->invoke( this, bval, e );
				else
					Unrecognized( );
				}
			}
		else if ( pxy_store_cbinfo *cbi = cbdict[e->Name()] )
			cbi->invoke( this, e->Val(), e );
		else
			Unrecognized( );
		}
	}

void ProxyStore::Loop( )
	{
	for ( GlishEvent* e; (e = NextEvent()); )
		ProcessEvent( e );
	}

const char *ProxyStore::GetOption( const char * ) const { return 0; }

void Proxy::setId( const ProxyId &i ) { id = i; }

Proxy::Proxy( ProxyStore *s ) : store(s)
	{
	// store will set our id
	store->addProxy( this );
	}

Proxy::~Proxy( )
	{
	store->removeProxy( this );
	}

Proxy *Proxy::Done( Value * )
	{
	return this;
	}

void Proxy::SendCtor( const char *name, Proxy *source )
	{
	recordptr rec = create_record_dict();
	rec->Insert( string_dup(PXCREATE), ValCtor::create((int*)id.array(),ProxyId::len(),COPY_ARRAY) );
	if ( ! source )
		{
		if ( ReplyPending( ) )
			{
			char *pending = store->TakePending();
			GlishEvent e( pending, ValCtor::create(rec) );
			e.SetIsReply( );
			e.SetIsProxy( );
			PostEvent( &e );
			}
		else
			{
			GlishEvent e( name, ValCtor::create(rec) );
			e.SetIsProxy( );
			PostEvent( &e );
			}
		}
	else
		{
		Value *v = ValCtor::create(rec);
		if ( ReplyPending( ) )
			source->Reply( v );
		else
			source->PostEvent( name, v );
		Unref(v);
		}
	}
