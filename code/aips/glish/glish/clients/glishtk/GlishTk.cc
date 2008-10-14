#include "Glish/glish.h"
RCSID("@(#) $Id: GlishTk.cc,v 19.0 2003/07/16 05:14:50 aips2adm Exp $")
#include <stdlib.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include "Glish/Proxy.h"
#include "tkCore.h"
#include "tkCanvas.h"

extern "C" void GlishTk_init( ProxyStore *, int, const char * const * );
extern "C" void GlishTk_loop( ProxyStore *, const GlishCallback *, int, const GlishCallback *, int );
extern void MkWidgets_init( ProxyStore *store );

void GlishTk_init( ProxyStore *store, int, const char * const * )
	{

	TkProxy::set_global_store( store );

	store->Register( "frame", TkFrameP::Create );
	store->Register( "button", TkButton::Create );
	store->Register( "scale", TkScale::Create );
	store->Register( "text", TkText::Create );
	store->Register( "scrollbar", TkScrollbar::Create );
	store->Register( "label", TkLabel::Create );
	store->Register( "entry", TkEntry::Create );
	store->Register( "message", TkMessage::Create );
	store->Register( "listbox", TkListbox::Create );
	store->Register( "canvas", TkCanvas::Create );
	store->Register( "version", TkProxy::Version );
	store->Register( "have_gui", TkProxy::HaveGui );
	store->Register( "tk_hold", TkProxy::HoldEvents );
	store->Register( "tk_release", TkProxy::ReleaseEvents );
	store->Register( "tk_iconpath", TkProxy::SetBitmapPath );
	store->Register( "tk_checkcolor", TkProxy::CheckColor );

	store->Register( "tk_load", TkProxy::Load );
	store->Register( "tk_loadpath", TkProxy::SetLoadPath );
	MkWidgets_init( store );
	}

static void fileproc_callback( ClientData data, int )
	{
	GlishCallback *gcb = (GlishCallback*) data;
	(*gcb->func)( gcb->data );
	}

void GlishTk_loop( ProxyStore *store, const GlishCallback *rinfo, int rlen, const GlishCallback *winfo, int wlen )
	{
	const char *result = TkProxy::init_tk(0);

	for ( int i=0; i<rlen; ++i )
		if ( rinfo[i].fd && rinfo[i].func )
			Tk_CreateFileHandler( rinfo[i].fd, TK_READABLE, fileproc_callback, new GlishCallback( rinfo[i] ) );

	for ( LOOPDECL i=0; i<wlen; ++i )
		if ( winfo[i].fd && winfo[i].func )
			Tk_CreateFileHandler( winfo[i].fd, TK_WRITABLE, fileproc_callback, new GlishCallback( winfo[i] ) );

	store->Initialized( );

	while ( ! store->Done( ) )
		TkProxy::DoOneTkEvent( );
	}
