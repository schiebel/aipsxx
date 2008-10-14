// $Id: tproxy.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
#include <iostream>
#include "Glish/Proxy.h"

std::ostream &operator <<(std::ostream &o, const ProxyId &id)
	{
	o << id.interp() << ":" << id.task() << ":" << id.id();
	return o;
	}

class ProxyA : public Proxy {
    public:
	ProxyA( ProxyStore *s );
	~ProxyA( );
	static void Create( ProxyStore *s, Value *v, GlishEvent *e, void *data );
	void ProcessEvent( const char *name, Value *val );
};

ProxyA::ProxyA( ProxyStore *s ) : Proxy(s)
	{ std::cerr << "Created a ProxyA: " << id << std::endl; }

ProxyA::~ProxyA( )
	{ std::cerr << "Deleted a ProxyA: " << id << std::endl; }

void ProxyA::Create( ProxyStore *s, Value *v, GlishEvent *e, void *data )
	{ 
	std::cerr << "In ProxyA::Create" << std::endl;
	ProxyA *np = new ProxyA( s );
	np->SendCtor("newtp");
	}

void ProxyA::ProcessEvent( const char *name, Value *val )
	{
	Value *result = new Value(id.id());
	if ( ReplyPending() )
		Reply( result );
	else
		PostEvent( name, result );
	Unref( result );
	}

int main( int argc, char** argv )
	{
        ClientProxyStore stor( argc, argv );
	stor.Register( "make", ProxyA::Create );
	stor.Loop();
        return 0;
	}
