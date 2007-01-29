// $Id: tkProxy.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
//

#include "Glish/glish.h"
RCSID("@(#) $Id: tkProxy.cc,v 19.1 2004/07/13 22:37:01 dschieb Exp $")
#include <X11/Xlib.h>
#include <string.h>
#include <stdlib.h>
#include "Glish/Value.h"
#include "system.h"
#include "tkCore.h"
#include "tkCanvas.h"
#include "comdefs.h"

typedef Dict(int) color_list;
ProxyStore *TkProxy::global_store = 0;

int TkProxy::root_unmapped = 0;
Tk_Window TkProxy::root = 0;
Tcl_Interp *TkProxy::tcl = 0;

PQueue(glishtk_event) *TkProxy::tk_queue = 0;
int TkProxy::hold_tk_events = 0;
int TkProxy::hold_glish_events = 0;
Value *TkProxy::last_error = 0;
Value *TkProxy::bitmap_path = 0;
int TkProxy::widget_index = 0;

unsigned long TkFrame::count = 0;

char *glishtk_quote_string( charptr str, int quote_empty_string )
	{
	if ( ! str || ! quote_empty_string && ! *str ) return 0;
	int len = 0;
	
	register char x;
	charptr in = str;
	while ( (x = *in++) )
		len += (x == '"' || x == '$' || x == '[' || x == '\\' ? 2 : 1);
	char *ret = (char*) alloc_memory(len+3);
	char *out = ret;
	*out++ = '"';
	for ( in = str; (x = *in++); *out++ = x )
		if ( x == '"' || x == '$' || x == '[' || x == '\\' ) *out++ = '\\';
	*out++ = '"';
	*out++ = '\0';
	return ret;
	}

char *glishtk_quote_string( charptr *str, int slen, int quote_empty_string )
	{
	if ( ! str || ! quote_empty_string && slen <= 0 ) return 0;
	int len = 0;
	
	for ( int i=0; i < slen; ++i )
		{
		charptr in = str[i];
		register char x;
		while ( (x = *in++) )
			len += (x == '"' || x == '$' || x == '[' || x == '\\' ? 2 : 1);
		}

	char *ret = (char*) alloc_memory(len+slen+3);
	char *out = ret;
	*out++ = '"';
	for ( int i=0; i < slen; ++i )
		{
		register char x;
		for ( charptr in = str[i]; (x = *in++); *out++ = x )
			if ( x == '"' || x == '$' || x == '[' || x == '\\' ) *out++ = '\\';
		if ( i+1 < slen ) *out++ = ' ';
		}
	*out++ = '"';
	*out++ = '\0';
	return ret;
	}

int tcl_ArgEval( TkProxy *proxy, int argc, char *argv[] )
	{
	if ( argc < 1 ) return TCL_ERROR;

	static char *buf = 0;
	static int blen = 0;

	if ( ! blen )
		{
		blen = 1024;
		buf = (char*) alloc_memory( blen );
		}

	int clen = 0;
	int len = 0;

#define ARGEVAL_ADD(what)					\
	len = strlen(what);					\
	if ( clen + len + 2 >=  blen )				\
		{						\
		while ( clen + len + 2 >=  blen ) blen *= 2;	\
		buf = (char*) realloc_memory( buf, blen );	\
		}						\
	memcpy( &buf[clen], what, len );			\
	clen += len;

#define ARGEVAL_SP   buf[clen++] = ' ';
#define ARGEVAL_ZERO buf[clen] = '\0';

	ARGEVAL_ADD(argv[0])
	for ( register int i = 1; i < argc; ++i )
		{
		ARGEVAL_SP
		ARGEVAL_ADD(argv[i] )
		}

	ARGEVAL_ZERO

	FILE *fle=0;
	if ( (fle=proxy->Logfile()) )
		fprintf( fle, "%s\n", buf );

	return Tcl_Eval( proxy->Interp(), buf );
	}

void glishtk_log_to_file( FILE *fle, const char *str, ... )
	{
	if ( fle )
		{
		va_list ap;
		fprintf( fle, "%s", str );
		va_start(ap, str);
		str = va_arg(ap,const char*);
		while ( str )
			{
			fprintf( fle, "%s", str );
			str = va_arg(ap,const char*);
			}
		fprintf( fle, "\n" );
		va_end(ap);
		}
	}

char *glishtk_make_callback( Tcl_Interp *tcl, Tcl_CmdProc *cmd, ClientData data, char *out )
	{
	static int index = 0;
	static char buf[100];
	if ( ! out ) out = buf;
	sprintf( out, "gtkcb%x", ++index );
	Tcl_CreateCommand( tcl, out, cmd, data, 0 );
	return out;
	}

const char*glishtk_winfo(TkProxy *proxy, const char *cmd, Value * )
	{
	tcl_VarEval( proxy, "winfo ", cmd, SP, Tk_PathName(proxy->Self( )), (char *)NULL );
	return Tcl_GetStringResult(proxy->Interp( ));
	}

const char*glishtk_focus(TkProxy *proxy, const char *cmd, Value * )
	{
	tcl_VarEval( proxy, "focus ", Tk_PathName(proxy->Self( )), (char *)NULL );
	return Tcl_GetStringResult(proxy->Interp( ));
	}

class glishtk_event {
    public:
	glishtk_event( TkProxy *a_, const char *n_, Value *v_ ) :
			agent(a_), nme(n_ ? strdup(n_) : strdup(" ")), val(v_)
//  somehow (?!?!) copy_value() seems to result in some of the value being
//  lost when the value is queued for later processing...
//			{ Ref(agent); copy_value(val); }
			{ Ref(agent); Ref(val); }
	void Post();
	~glishtk_event();
	Value *value() { return val; }
    protected:
	TkProxy *agent;
	char *nme;
	Value *val;
};

void glishtk_event::Post()
	{
	agent->PostEvent( nme, val );
	}

glishtk_event::~glishtk_event()
	{
	Unref(val);
	Unref(agent);
	free_memory( nme );
	}

TkProc::TkProc( TkProxy *a, TkStrToValProc cvt ) : cmdstr(0), proc(0), proc1(0), proc2(0),
			agent(a), aproc(0), aproc2(0), aproc3(0), aproc4(0), aproc5(0),
			iproc(0), iproc1(0), param(0), param2(0), convert(cvt), i(0) { }

TkProc::TkProc(const char *c, TkEventProc p, TkStrToValProc cvt) : cmdstr(c),
			proc(p), proc1(0), proc2(0), agent(0), aproc(0), aproc2(0),
			aproc3(0), aproc4(0), aproc5(0), iproc(0), iproc1(0), param(0),
			param2(0), convert(cvt), i(0) { }

TkProc::TkProc(const char *c, const char *x, const char *y, TkTwoParamProc p, TkStrToValProc cvt)
			: cmdstr(c), proc(0), proc1(0), proc2(p), agent(0), aproc(0),
			aproc2(0), aproc3(0), aproc4(0), aproc5(0), iproc(0), iproc1(0),
			param(x), param2(y), convert(cvt), i(0) { }

TkProc::TkProc(const char *c, const char *x, int y, TkTwoIntProc p, TkStrToValProc cvt )
			: cmdstr(c), proc(0), proc1(0), proc2(0), agent(0), aproc(0),
			aproc2(0), aproc3(0), aproc4(0), aproc5(0), iproc(0), iproc1(p),
			param(x), param2(0), convert(cvt), i(y) { }

TkProc::TkProc(const char *c, const char *x, TkOneParamProc p, TkStrToValProc cvt )
			: cmdstr(c), proc(0), proc1(p), proc2(0), agent(0), aproc(0),
			aproc2(0), aproc3(0), aproc4(0), aproc5(0), iproc(0), iproc1(0),
			param(x), param2(0), convert(cvt), i(0) { }

TkProc::TkProc(const char *c, int x, TkOneIntProc p, TkStrToValProc cvt )
			: cmdstr(c), proc(0), proc1(0), proc2(0), agent(0), aproc(0),
			aproc2(0), aproc3(0), aproc4(0), aproc5(0), iproc(p), iproc1(0),
			param(0), param2(0), convert(cvt), i(x) { }

TkProc::TkProc(TkProxy *a, const char *c, TkEventAgentProc p, TkStrToValProc cvt )
			: cmdstr(c), proc(0), proc1(0), proc2(0), agent(a), aproc(p),
			aproc2(0), aproc3(0), aproc4(0), aproc5(0), iproc(0), iproc1(0),
			param(0), param2(0), convert(cvt), i(0) { }

TkProc::TkProc(TkProxy *a, const char *c, const char *x, TkEventAgentProc2 p, TkStrToValProc cvt )
			: cmdstr(c), proc(0), proc1(0), proc2(0), agent(a), aproc(0),
			aproc2(p), aproc3(0), aproc4(0), aproc5(0), iproc(0), iproc1(0),
			param(x), param2(0), convert(cvt), i(0) { }

TkProc::TkProc(TkProxy *a, const char *c, const char *x, const char *y, TkEventAgentProc3 p, TkStrToValProc cvt )
			: cmdstr(c), proc(0), proc1(0), proc2(0), agent(a), aproc(0),
			aproc2(0), aproc3(p), aproc4(0), aproc5(0), iproc(0), iproc1(0),
			param(x), param2(y), convert(cvt), i(0) { }

TkProc::TkProc(TkProxy *a, const char *c, int y, TkEventAgentProc4 p, TkStrToValProc cvt )
			: cmdstr(c), proc(0), proc1(0), proc2(0), agent(a), aproc(0),
			aproc2(0), aproc3(0), aproc4(p), aproc5(0), iproc(0), iproc1(0),
			param(0), param2(0), convert(cvt), i(y) { }

TkProc::TkProc(TkProxy *a, const char *c, const char *x, int y, TkEventAgentProc5 p, TkStrToValProc cvt )
			: cmdstr(c), proc(0), proc1(0), proc2(0), agent(a), aproc(0),
			aproc2(0), aproc3(0), aproc4(0), aproc5(p), iproc(0), iproc1(0),
			param(x), param2(0), convert(cvt), i(y) { }

Value *TkProc::operator()(Tcl_Interp *tcl, Tk_Window s, Value *arg)
	{
	const char *val = 0;

	if ( proc )
		val = (*proc)(tcl, s,cmdstr,arg);
	else if ( proc1 )
		val = (*proc1)(tcl, s,cmdstr,param,arg);
	else if ( proc2 )
		val = (*proc2)(tcl, s,cmdstr,param,param2,arg);
	else if ( aproc != 0 && agent != 0 )
		val = (*aproc)(agent, cmdstr, arg );
	else if ( aproc2 != 0 && agent != 0 )
		val = (*aproc2)(agent, cmdstr, param, arg);
	else if ( aproc3 != 0 && agent != 0 )
		val = (*aproc3)(agent, cmdstr, param, param2, arg);
	else if ( aproc4 != 0 && agent != 0 )
		val = (*aproc4)(agent, cmdstr, i, arg);
	else if ( aproc5 != 0 && agent != 0 )
		val = (*aproc5)(agent, cmdstr, param, i, arg);
	else if ( iproc )
		val = (*iproc)(tcl, s, cmdstr, i, arg);
	else if ( iproc1 )
		val = (*iproc1)(tcl, s, cmdstr, param, i, arg);
	else
		return error_value();

	if ( val != (void*) TCL_ERROR )
		{
		if ( convert && val )
			return (*convert)(val);
		else
			return new Value( glish_true );
		}
	else
		return new Value( glish_false );
	}

static int (*glishtk_dflt_xioerror_handler)(Display *) = 0;
int glishtk_xioerror_handler(Display *d)
	{
	ValCtor::cleanup();
	if ( glishtk_dflt_xioerror_handler )
		(*glishtk_dflt_xioerror_handler)(d);
	exit(1);
	return 1;
	}

static int (*glishtk_dflt_xerror_handler)(Display *,XErrorEvent*) = 0;
int  glishtk_tkerrorhandler(ClientData cd, XErrorEvent*e){
	fprintf( stderr, "XError: error code %u\n", e->error_code );
        fprintf( stderr, "XError: request code %u\n", e->request_code );
        fprintf( stderr, "XError: minor code %u\n", e->minor_code );
        fprintf( stderr, "XError: resource id %u\n", e->resourceid );
	return 0;
}
int glishtk_xerror_handler(Display *d, XErrorEvent*e)
	{
	ValCtor::cleanup();
	if ( glishtk_dflt_xerror_handler )
		(*glishtk_dflt_xerror_handler)(d,e);
	exit(1);
	return 1;
	}

void TkProxy::set_global_store( ProxyStore *store )
	{
	global_store = store;
	}

const char *TkProxy::init_tk( int visible_root )
	{
	if ( ! root )
		{
		if ( ! tcl )
			{
			tcl = Tcl_CreateInterp();
			if ( ! tcl ) return "TCL creation failed";
			}

		static int tcl_started = TCL_ERROR;

		if ( tcl_started == TCL_ERROR )
			{
			tcl_started = Tcl_Init( tcl );
			if ( tcl_started == TCL_ERROR )
				return Tcl_GetStringResult(tcl);
			}

		static int tk_started = TCL_ERROR;

		if ( tk_started == TCL_ERROR )
			{
			tk_started = Tk_Init(tcl);

			if ( tk_started == TCL_OK )
				{
				root = Tk_MainWindow(tcl);
/*
				glishtk_dflt_xioerror_handler = XSetIOErrorHandler(glishtk_xioerror_handler);
				glishtk_dflt_xerror_handler = XSetErrorHandler(glishtk_xerror_handler);

*/
                                ClientData cd = 0;
                                Tk_CreateErrorHandler(Tk_Display(root), -1, -1, -1,  glishtk_tkerrorhandler, cd);
				static char tk_follow[] = "tk_focusFollowsMouse";
				const char *option = 0;
				if ( ! TkProxy::global_store || ! (option = TkProxy::global_store->GetOption("focus")) ||
				     strcmp( "click", option ) )
					Tcl_Eval(tcl, tk_follow);

				if ( ! visible_root )
					{
					root_unmapped = 1;
					tcl_VarEval( tcl, "wm withdraw ", Tk_PathName(root), (char *)NULL );
					}
				}
			else
				return Tcl_GetStringResult(tcl);
			}
		}

	else if ( root_unmapped && visible_root )
		{
		root_unmapped = 0;
		tcl_VarEval( tcl, "wm deiconify ", Tk_PathName(root), (char *)NULL );
		}

	return 0;
	}

void TkProxy::HoldEvents( ProxyStore *, Value * )
	{
	hold_tk_events++;
	}

void TkProxy::ReleaseEvents( ProxyStore *, Value * )
	{
	hold_tk_events--;
	if ( hold_tk_events < 0 )
		hold_tk_events = 0;
	}

void TkProxy::ProcessEvent( const char *name, Value *val )
	{
	if ( ! IsValid() ) return;

	TkProc *proc = procs[name];

	if ( proc != 0 )
		{
		static Value *true_result = new Value( glish_true );
		Value *v = (*proc)( tcl, self, val );
		if ( ReplyPending() ) Reply( v ? v : true_result );
		Unref(v);
		}
	else
		Error("unknown event");
	}

void TkProxy::EnterEnable() { }
void TkProxy::ExitEnable() { }
int TkProxy::IsValid() const { return self != 0; }

void TkProxy::SetError( Value *v )
	{
	if ( last_error ) Unref(v);
	else last_error = v;
	}

void TkProxy::PostTkEvent( const char *s, Value *v )
	{
	if ( RefCount() > 0 ) Ref(this);
	if ( hold_glish_events )
		tk_queue->EnQueue( new glishtk_event( this, s, v ) );
	else
		PostEvent( s, v );
	if ( RefCount() > 0 ) Unref(this);
	}

void TkProxy::FlushGlishEvents()
	{
	if ( hold_glish_events )
		{
		glishtk_event* e = 0;

		hold_glish_events = 0;
		while ( (e = tk_queue->DeQueue()) )
			{
#ifdef GGC
			ProxyStore::CurSeq()->UnregisterValue(e->value());
#endif
			e->Post();
			delete e;
			}
		}
	}

void TkProxy::Version( ProxyStore *s, Value * )
	{
	Value *tkv = new Value( TK_VERSION );
	attributeptr tka = tkv->ModAttributePtr();
#if defined(TK_PATCH_LEVEL)
        tka->Insert( strdup( "patch" ), new Value(TK_PATCH_LEVEL) );
#endif
	Value *tclv = new Value(TCL_VERSION);
        tka->Insert( strdup( "tcl" ), tclv );
#if defined(TCL_PATCH_LEVEL)
	attributeptr tcla = tclv->ModAttributePtr();
	tcla->Insert( strdup( "patch" ), new Value(TCL_PATCH_LEVEL) );
#endif

	if ( s->ReplyPending() )
		s->Reply( tkv );
	else
		s->PostEvent( "version", tkv );

	Unref(tkv);
	}

void TkProxy::HaveGui( ProxyStore *s, Value * )
	{
	if ( s->ReplyPending() )
		{
		Value val( TkHaveGui() ? glish_true : glish_false );
		s->Reply( &val );
		}
	}

void TkProxy::CheckColor( ProxyStore *s, Value *arg )
	{
	if ( s->ReplyPending() )
		{
		const char *err = init_tk(0);

		if ( err )
			{
			s->Error( err );
			return;
			}

		const char *color = 0;
		if ( arg->Type() == TYPE_STRING && arg->Length() >= 1 &&
		     (color = arg->StringPtr(0)[0]) )
			{
			static color_list *existing_colors = 0;

			if ( ! existing_colors )
				existing_colors = new color_list;

			int result = 0;
			//
			//  +1  =>  color exists
			//  -1  =>  color does not exist
			//
			if ( ! (result = existing_colors->Lookup( color )) )
				{
				XColor xcolor;
				XColor xscreen;

				if ( XLookupColor( Tk_Display(root), Tk_Colormap(root), color, &xscreen, &xcolor ) )
					{
					existing_colors->Insert( strdup( color ), 1 );
					result = 1;
					}
				else
					existing_colors->Insert( strdup( color ), -1 );
				}

			Value val( result > 0 ? glish_true : glish_false );
			s->Reply( &val );
			}
		else
			s->Error( "bad argument type for tk_checkcolor" );
		}
	}

void TkProxy::Load( ProxyStore *s, Value *arg )
	{
	char *toload = 0;
	const char *module = 0;
	int fail_if_no_tk = 1;

	if ( arg->Type() == TYPE_STRING && arg->Length() >= 1 &&
	     (toload = which_shared_object(arg->StringPtr(0)[0])) )
		{
		if ( arg->Length() > 1 )
			module = arg->StringPtr(0)[1];
		}

	else if ( arg->Type() == TYPE_RECORD && arg->Length() >= 1 )
		{
		Value *str = arg->NthField( 1 );
		if ( str->Type() == TYPE_STRING && str->Length() >= 1 &&
		     (toload = which_shared_object(str->StringPtr(0)[0])) )
			{
			if ( str->Length() > 1 )
				module = str->StringPtr(0)[1];
			if ( arg->Length() > 1 && ! strcmp( arg->NthFieldName(2), "needtk" ) )
				{
				Value *needtk = arg->NthField( 2 );
				if ( needtk && needtk->IsNumeric() )
					fail_if_no_tk = needtk->IntVal();
				}
			}
		}

	if ( toload )
		{
		const char *err = init_tk(0);

		if ( err && fail_if_no_tk )
			s->Error( err );

		else if ( module )
			{
			if ( tcl_VarEval( tcl, "load ", toload, " ", module, (char *)NULL ) == TCL_ERROR )
				s->Error( Tcl_GetStringResult(tcl) );
			}
		else
			{
			if ( tcl_VarEval( tcl, "load ", toload, (char *)NULL ) == TCL_ERROR )
				s->Error( Tcl_GetStringResult(tcl) );
			}

		free_memory(toload);
		}
	else
		s->Error( "Couldn't find object to load" );
	}

static char *join_path( const char **path, int len, const char *var_name = 0 )
	{
	int count = len + 1;
	if ( ! path ) return 0;

	for ( int i = 0; i < len; ++i )
		count += strlen(path[i]);

	if ( var_name ) count += strlen(var_name) + 1;
	char *ret = (char*) alloc_memory( sizeof(char) * count );
	if ( var_name ) sprintf( ret, "%s=", var_name );
	else ret[0] = '\0';

	for ( LOOPDECL i=0; i < len; ++i )
		{
		strcat( ret, path[i] );
		if ( i < len-1 ) strcat(ret, ":");
		}

	return ret;
	}


void TkProxy::SetLoadPath( ProxyStore *, Value *v )
	{
	if ( v && v->Type() == TYPE_STRING && v->Length() > 0 )
		{
		set_load_path( v );
		char *libpath = join_path(v->StringPtr(0),v->Length(),"LD_LIBRARY_PATH");
		putenv(libpath);	// here we leak libpath, because putenv
		}			// depends on it sticking around
	}

int TkProxy::DoOneTkEvent( int flags, int hold_wait )
	{
//** 	if ( shutting_glish_down ) return 0;

	int ret = 0;
	if ( hold_tk_events )
		{
		if ( flags & TK_FILE_EVENTS )
			ret = Tk_DoOneEvent( TK_FILE_EVENTS | (hold_wait ? 0 : TK_DONT_WAIT) );
		}
	else
		ret = Tk_DoOneEvent( flags );

	return ret;
	}

int TkProxy::DoOneTkEvent( )
	{
	int ret = 0;

	if ( hold_tk_events )
		ret = Tk_DoOneEvent( TK_FILE_EVENTS | TK_TIMER_EVENTS );
	else
		ret = Tk_DoOneEvent( TK_ALL_EVENTS );

	return ret;
	}

void TkProxy::SetBitmapPath( ProxyStore *, Value *v )
	{
	if ( v && v->Type() == TYPE_STRING )
		{
		if ( bitmap_path ) Unref( bitmap_path );
		bitmap_path = v;
		Ref( bitmap_path );
		}
	}

char *TkProxy::which_bitmap( const char* filename )
	{
	charptr *paths = bitmap_path ? bitmap_path->StringPtr() : 0;
	int len = bitmap_path ? bitmap_path->Length() : 0;

	if ( ! paths || filename[0] == '/' || filename[0] == '.' )
		{
		if ( access( filename, R_OK ) == 0 )
			return strdup( filename );
		else
			return 0;
		}

	char directory[1024];

	for ( int i = 0; i < len; i++ )
		if ( paths[i] && strlen(paths[i]) )
			{
			sprintf( directory, "%s/%s", paths[i], filename );

			if ( access( directory, R_OK ) == 0 )
				return strdup( directory );
			}

	return 0;
	}



charptr TkProxy::NewName( Tk_Window parent ) const
	{
	static char *buf = 0;
	static int len = 100;

	if ( ! buf )
		buf = (char*) alloc_memory( sizeof(char) * len );

	if ( parent )
		{
		charptr pp = Tk_PathName(parent);
		if ( ! pp || pp[0] == '.' && pp[1] == '\0' )
			sprintf( buf, ".g%x", ++widget_index );
		else
			{
			int ppl = strlen(pp) + 15;
			if ( ppl > len )
				{
				while ( ppl > len ) len *= 2;
				buf = (char*) realloc_memory( buf, len );
				}
			sprintf( buf, "%s.g%x", pp, ++widget_index );
			}
		}
	else
		sprintf( buf, ".g%x", ++widget_index );

	return buf;
	}

void TkProxy::SetMap( int do_map, int toplevel )
	{
	int dont_map_ = do_map ? 0 : 1;
	if ( dont_map != dont_map_ )
		{
		dont_map = dont_map_;
		if ( ! toplevel )
			{
			if ( dont_map )
				tcl_VarEval( this, "pack forget ", Tk_PathName(self), (char *)NULL );
			if ( frame ) frame->Pack();
			}
		else
			{
			Tk_Window win =  TopLevel();
			if ( win )
				{
				if ( dont_map )
					{
					if ( ! withdrawn )
						{
						withdrawn = 1;
						if ( ! leader_unmapped )
							tcl_VarEval( this, "wm withdraw ", Tk_PathName(win), (char *)NULL );
						}
					}
				else
					{
					withdrawn = 0;
					if ( ! leader_unmapped )
						tcl_VarEval( this, "wm deiconify ", Tk_PathName(win), (char *)NULL );
					}
				}
			}
		}
	}

TkProxy::TkProxy( ProxyStore *s, int init_graphic ) : Proxy( s ), dont_map( 0 ), withdrawn( 0 ),
						      leader_unmapped( 0 ), disable_count( 0 )
	{
	agent_ID = "<graphic>";
	enable_state = 0;
	is_graphic = init_graphic;

	self = 0;
	frame = 0;

	if ( tk_queue == 0 )
		tk_queue = new PQueue(glishtk_event)();

	if ( init_graphic )
		{
		const char *err = init_tk(0);
		if ( err ) SetError( new Value(err) );

		procs.Insert("background", new TkProc(this, "-bg", glishtk_onestr, glishtk_str));
		procs.Insert("foreground", new TkProc(this, "-fg", glishtk_onestr, glishtk_str));
		procs.Insert("relief", new TkProc(this, "-relief", glishtk_onestr, glishtk_str));
		procs.Insert("borderwidth", new TkProc(this, "-borderwidth", glishtk_onedim, glishtk_strtoint));
		procs.Insert("pixelwidth", new TkProc(this, "width",glishtk_winfo, glishtk_strtoint));
		procs.Insert("pixelheight", new TkProc(this, "height",glishtk_winfo, glishtk_strtoint));
		procs.Insert("hlcolor", new TkProc(this, "-highlightcolor", glishtk_onestr, glishtk_str));
		procs.Insert("hlbackground", new TkProc(this, "-highlightbackground", glishtk_onestr, glishtk_str));
		procs.Insert("hlthickness", new TkProc(this, "-highlightthickness", glishtk_onedim, glishtk_strtoint));
		procs.Insert("focus", new TkProc(this, "focus", glishtk_focus, glishtk_str));
		}
	}


void TkProxy::Disable( )
	{
	disable_count++;
	}

void TkProxy::Enable( int force )
	{
	if ( force ) disable_count = 0;
	else disable_count--;
	}

void TkProxy::UnMap()
	{
	if ( self )
		{
		Value *v = new Value( glish_true );
		PostTkEvent( "done", v );
		Unref(v);

		Tk_DestroyWindow( self );
		}

	frame = 0;
	self = 0;
	}

const char **TkProxy::PackInstruction()
	{
	return 0;
	}

void TkProxy::do_pack( int argc, char **argv)
	{
	int set_cmd = 0;
	if ( argc > 0 && ! argv[0] )
		{
		argv[0] = (char*) "pack";
		set_cmd = 1;
		}
	tcl_ArgEval( this, argc, argv );
	if ( set_cmd ) argv[0] = 0;
	}

charptr TkProxy::IndexCheck( charptr c )
	{
	return c;
	}

charptr TkProxy::IndexCheck( int, char* )
	{
	return 0;
	}

int TkProxy::CanExpand() const
	{
	return 0;
	}

TkProxy::~TkProxy( )
	{
	IterCookie* c = procs.InitForIteration();

	TkProc* member;
	const char* key;
	while ( (member = procs.NextEntry( key, c )) )
		delete member;
	}

void TkProxy::BindEvent(const char *event, Value *rec)
	{
	PostTkEvent( event, rec );
	}

Tk_Window TkProxy::TopLevel( )
	{
	return frame ? frame->TopLevel() : 0;
	}

FILE *TkProxy::Logfile( )
	{
	return frame ? frame->Logfile() : 0;
	}

int TkProxy::IsPseudo( )
	{
	return 1;
	}

const char*glishtk_scrolled_update(TkProxy *proxy, const char *, Value *val )
	{
	if ( val->Type() != TYPE_STRING || val->Length() != 1 )
		return 0;

	tcl_VarEval( proxy, Tk_PathName(proxy->Self( )), SP, val->StringPtr(0)[0], (char *)NULL );
	return 0;
	}

void TkProxy::Register( const char *str, WidgetCtor ctor )
	{
	if ( global_store )
		global_store->Register( str, ctor );
	}

int TkHaveGui()
	{
	Display *display;
	static int ret = 0;
	static int setup = 1;

	//
	// There are some *strange* problems with X11R5 + Solaris...
	// after multiple (50+) calls to "have_gui()" (plus other
	// things operations) e.g.:
	//      GO := T
	//      CNT := 0
	//      while (GO) {CNT+:=1;include "tt.g";GO:=have_gui()}
	//      print GO,CNT
	// where "tt.g" is an empty file, "have_gui()" will start
	// returning 'F'. Calling XOpenDisplay(NULL) once is more
	// efficient, and solves this problem, but probably isn't
	// as proper.
	//
	if ( setup )
		{
		if ( (display=XOpenDisplay(NULL)) != NULL )
			{
			ret = 1;
			XCloseDisplay(display);
			}
		setup = 0;
		}

	return ret;
	}

void TkFrame::AddElement( TkProxy *obj ) { exit(1); }
void TkFrame::RemoveElement( TkProxy *obj ) { exit(1); }
void TkFrame::Pack() { exit(1); }
const char *TkFrame::Expand() const { exit(1); return 0; }
int TkFrame::NumChildren() const { exit(1); return 0; }
const char *TkFrame::Side() const { exit(1); return 0; }
int TkFrame::ExpandNum(const TkProxy *except, unsigned int grtOReqt) const { exit(1); return 0; }
