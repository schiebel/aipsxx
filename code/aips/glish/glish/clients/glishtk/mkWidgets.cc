#include "Glish/Proxy.h"
#include "Glish/glishtk.h"
#include "mkWidgets.h"
#include "tkCore.h"
#include "comdefs.h"

int MkWidget::initialized = 0;
int MkTab::count = 0;

#define STD_EXPAND_PACKINSTRUCTION(CLASS)		\
const char **CLASS::PackInstruction()			\
	{						\
	static char *ret[5];				\
	int c = 0;					\
	if ( fill )					\
		{					\
		ret[c++] = (char*) "-fill";		\
		ret[c++] = fill;			\
		if ( ! strcmp(fill,"both") ||		\
		     ! strcmp(fill, frame->Expand()) ||	\
		     frame->NumChildren() == 1 &&	\
		     ! strcmp(fill,"y") )		\
			{				\
			ret[c++] = (char*) "-expand";	\
			ret[c++] = (char*) "true";	\
			}				\
		else					\
			{				\
			ret[c++] = (char*) "-expand";	\
			ret[c++] = (char*) "false";	\
			}				\
		ret[c++] = 0;				\
		return (const char **) ret;		\
		}					\
	else						\
		return 0;				\
	}

void MkWidgets_init( ProxyStore *store )
	{
	store->Register( "combobox", MkCombobox::Create );
	store->Register( "tabbox", MkTab::CreateContainer );
	store->Register( "tab", MkTab::CreateTab );
	}

#if 0
char *glishtk_make_ocallback( Tcl_Interp *tcl, char *obj, Tcl_CmdProc *cmd, ClientData data, char *out )
	{
	static int index = 0;
	static char buf[100];
	if ( ! out ) out = buf;
	sprintf( out, "gtkcb%x", ++index );
	Tcl_CreateObjCommand( tcl, obj, out, cmd, data, 0 );
	return out;
	}
#endif
MkWidget::MkWidget( ProxyStore *s ) : TkProxy( s )
	{
	if ( ! initialized )
		{
#ifdef TCLSCRIPTDIRP
		tcl_VarEval( this, "lappend auto_path ", TCLSCRIPTDIRP, (char*) NULL );
#endif
#ifdef TCLSCRIPTDIR
		tcl_VarEval( this, "lappend auto_path ", TCLSCRIPTDIR, (char*) NULL );
#endif
		tcl_VarEval( this, "package require mkWidgets", (char*) NULL );
		initialized = 1;
		}
	}

MkTab::MkTab( ProxyStore *s, TkFrame *frame_, charptr width_, charptr height_ ) : MkWidget( s ), tabcount(0)
	{
	agent_ID = "<graphic:tabbox>";
	frame = frame_;
	char *argv[12];

	count += 1;

	width = string_dup( width_ );
	height = string_dup( height_ );

	int c = 0;
	argv[c++] = (char*) "tabcontrol";
	argv[c++] = (char*) NewName(frame->Self());
	argv[c++] = (char*) "-width";
	argv[c++] = (char*) "auto";

	tcl_ArgEval( this, c, argv );

	char *ctor_error = Tcl_GetStringResult(tcl);
	if ( ctor_error && *ctor_error && *ctor_error != '.' ) HANDLE_CTOR_ERROR(ctor_error);

	self = Tk_NameToWindow( tcl, argv[1], root );

	frame->AddElement( this );
	frame->Pack();
	}

void MkTab::Raise( const char *tag )
	{
	tcl_VarEval( this, Tk_PathName(Self( )), " invoke ", tag, (char*)NULL );
	}

void MkTab::Add( const char *tag, TkProxy *proxy )
	{
	elements.Insert( string_dup(tag), proxy );
	}

void MkTab::Remove( const char *tag )
	{
	TkProxy *old = (TkProxy*) elements.Insert( tag, this );
	if ( old )
		{
		old->UnMap( );
		tcl_VarEval( this, Tk_PathName(this->Self( )), " delete ", tag, (char*)NULL );
		}
	}

void MkTab::UnMap()
	{
	IterCookie* c = elements.InitForIteration();
	TkProxy *member;
	const char *key;
	while ( (member = elements.NextEntry( key, c )) )
		{
		if ( member != this )
			{
			free_memory( (void*) key );
			member->UnMap( );
			}
		}
	elements.Clear( );
	}

MkTab::~MkTab( )
	{
	UnMap( );
	if ( width ) free_memory( width );
	if ( height ) free_memory( height );
	}

void MkTab::CreateContainer( ProxyStore *s, Value *args )
	{
	MkTab *ret = 0;

	if ( args->Length() != 3 )
		InvalidNumberOfArgs(3);

	SETINIT
	SETVAL( parent, parent->IsAgentRecord() )
	SETDIM( width )
	SETDIM( height )

	TkProxy *agent = (TkProxy*) (global_store->GetProxy(parent));
	if ( agent && ! strcmp( agent->AgentID(), "<graphic:frame>") )
		ret = new MkTab( s, (TkFrame*)agent, width, height );

	CREATE_RETURN
	}

void MkTab::CreateTab( ProxyStore *s, Value *args )
	{
	TkFrameP *ret = 0;
	if ( args->Length() != 11 )
		InvalidNumberOfArgs(11);

	SETINIT
	SETVAL( container, container->IsAgentRecord() )
	SETSTR( text_ )
	SETSTR( side )
	SETINT( row_ )
	char row[10];
	sprintf( row, " %d ", row_ >= 0 && row_ < 5 ? row_ : 0 );
	SETSTR( justify )
	SETDIM( padx )
	SETDIM( pady )
	SETSTR( font )
	SETINT( width_ )
	char width[30];
	sprintf( width, "%d", width_ );
	SETSTR( foreground )
	SETSTR( background )

	TkProxy *agent = (TkProxy*)(s->GetProxy(container));
	if ( agent && ! strcmp( agent->AgentID(), "<graphic:tabbox>") )
		{
		MkTab *tab = (MkTab*) agent;

		static char tabname[256];
		GENERATE_TAG(tabname, tab, "tab")

		TkFrame *frame = new TkFrameP(s,tab,"flat",side,"0",padx,pady,"none",
					      "lightgrey",tab->Width( ),tab->Height( ),tabname);

		if ( frame && frame->IsValid( ) )
			{
			//
			// Is this single extra "pack" sufficient???
			//
			tcl_VarEval( agent, "pack ", Tk_PathName(frame->Self()), (char*)NULL );

			char *text = glishtk_quote_string( text_ );

			int c = 0;
			char *argv[30];
			argv[c++] = Tk_PathName(tab->Self());
			argv[c++] = (char*) "insert";
			argv[c++] = (char*) tabname;
			argv[c++] = (char*) row;
			argv[c++] = (char*) "-text";
			argv[c++] = (char*) text;
			argv[c++] = (char*) "-window";
			argv[c++] = Tk_PathName(frame->Self());
			argv[c++] = (char*) "-justify";
			argv[c++] = (char*) justify;
			argv[c++] = (char*) "-padx";
			argv[c++] = (char*) padx;
			argv[c++] = (char*) "-pady";
			argv[c++] = (char*) pady;
			if ( font && *font )
				{
				argv[c++] = (char*) "-font";
				argv[c++] = (char*) font;
				}
			if ( width_ > 0 )
				{
				argv[c++] = (char*) "-width";
				argv[c++] = (char*) width;
				}
			argv[c++] = (char*) "-foreground";
			argv[c++] = (char*) foreground;
			argv[c++] = (char*) "-background";
			argv[c++] = (char*) background;

			tcl_ArgEval( tab, c, argv );

			char *ctor_error = Tcl_GetStringResult(tcl);
			Tcl_ResetResult(tcl);

			if ( ctor_error && *ctor_error && *ctor_error != '.' &&
			     strcmp(tabname,ctor_error) )
				{
				s->Error( ctor_error );
				delete frame;
				}

			else
				{
				tab->Add( tabname, frame );
				frame->SendCtor("newtk");
				}

			free_memory( text );
			}
		else if ( frame )
			{
			Value *err = frame->GetError();
			if ( err )
				{
				s->Error( err );
				Unref( err );
				}
			else
				s->Error( "tk widget creation failed" );

			delete frame;
			}
		else
			s->Error( "tk widget creation failed" );
		}
	else
		s->Error( "invalid tab container" );
	}

int combobox_returncb( ClientData data, Tcl_Interp *, int, GTKCONST char *[] )
	{
	((MkCombobox*)data)->Return();
	return TCL_OK;
	}

int combobox_selectcb( ClientData data, Tcl_Interp *, int, GTKCONST char *[] )
	{
	((MkCombobox*)data)->Selection();
	return TCL_OK;
	}

MkCombobox::MkCombobox( ProxyStore *s, TkFrame *frame_, charptr *entries_, int num, int width,
			charptr justify, charptr font, charptr relief, charptr borderwidth,
			charptr foreground, charptr background, charptr state,
			charptr fill_ ) : MkWidget( s ), entries(finalize_string), fill(0)
	{
	frame = frame_;
	char **argv = (char**) alloc_memory( sizeof(char*) * (num+30) );
	char width_[30];
	char lines_[30];
	char *foreground_ = glishtk_quote_string(foreground);
	char *background_ = glishtk_quote_string(background);

	agent_ID = "<graphic:combobox>";
	sprintf( width_, "%d", width );

	int c = 0;
	argv[c++] = (char*) "combobox";
	argv[c++] = (char*) NewName(frame->Self());
	if ( num > 0 )
		{
		argv[c++] = (char*) "-entries";
		argv[c++] = (char*) "{";
		for ( int i = 0; i < num; ++i )
			{
			char *s = glishtk_quote_string( entries_[i] );
			entries.append( s );
			argv[c++] = s;
			}
		argv[c++] = (char*) "}";
		}
	argv[c++] = (char*) "-width";
	argv[c++] = width_;
	argv[c++] = (char*) "-justify";
	argv[c++] = (char*) justify;
	if ( font && *font )
		{
		argv[c++] = (char*) "-font";
		argv[c++] = (char*) font;
		}
	argv[c++] = (char*) "-relief";
	argv[c++] = (char*) relief;
	argv[c++] = (char*) "-borderwidth";
	argv[c++] = (char*) borderwidth;
	argv[c++] = (char*) "-fg";
	argv[c++] = (char*) foreground;
	argv[c++] = (char*) "-bg";
	argv[c++] = (char*) background;
	argv[c++] = (char*) "-state";
	argv[c++] = (char*) state;
	if ( ! strcmp( state, "disabled" ) ) disable_count++;

	char *cback = glishtk_make_callback( tcl, combobox_selectcb, this );

	argv[c++] = (char*) "-command";
	argv[c++] = (char*) cback;

	tcl_ArgEval( this, c, argv );

	char *ctor_error = Tcl_GetStringResult(tcl);
	if ( ctor_error && *ctor_error && *ctor_error != '.' ) HANDLE_CTOR_ERROR(ctor_error);

	self = Tk_NameToWindow( tcl, argv[1], root );

	cback = glishtk_make_callback( tcl, combobox_returncb, this );

	FILE *fle = Logfile();
	if ( fle )
		fprintf( fle, "proc %s { } { puts \"(comobox ret:%s) %s\" }\n", cback, cback, Tk_PathName(self) );

	tcl_VarEval( this, Tk_PathName(self), " bind <Return> ", cback, (char*)NULL );
	ctor_error = Tcl_GetStringResult(tcl);
	fprintf( stderr, "\t\t=====> %s bind <Return> %s <%s>\n", Tk_PathName(self), cback, ctor_error );

	if ( fill_ && fill_[0] && strcmp(fill_,"none") )
		fill = strdup(fill_);

	frame->AddElement( this );
	frame->Pack();

	procs.Insert( "insert", new MkProc(this, &MkCombobox::Insert) );

	free_memory(foreground_);
	free_memory(background_);
	free_memory( argv );
	}

void MkCombobox::Return( )
	{
	tcl_VarEval( this, Tk_PathName(self), " cget -state", (char *)NULL );
	const char *curstate = Tcl_GetStringResult(tcl);
	if ( strcmp("disabled", curstate) )
		{
		tcl_VarEval( this, Tk_PathName(self), " get", (char *)NULL );
		Value *ret = new Value( Tcl_GetStringResult(tcl) );
		PostTkEvent( "return", ret );
		Unref(ret);
		}
	}
void MkCombobox::Selection( )
	{
	tcl_VarEval( this, Tk_PathName(self), " cget -state", (char *)NULL );
	const char *curstate = Tcl_GetStringResult(tcl);
	if ( strcmp("disabled", curstate) )
		{
		tcl_VarEval( this, Tk_PathName(self), " get", (char *)NULL );
		Value *ret = new Value( Tcl_GetStringResult(tcl) );
		PostTkEvent( "select", ret );
		Unref(ret);
		}
	}

const char *MkCombobox::Insert( Value *val )
	{

	charptr *strs;
	if ( val->Type() == TYPE_STRING && val->Length() > 0 &&
	     (strs = val->StringPtr(0)) )
	  	{
		for ( int x=0; x < val->Length(); ++x )
			if ( strs[x] ) entries.append( glishtk_quote_string(strs[x]) );
		}

	char **argv = (char**) alloc_memory( sizeof(char*) * (entries.length()+5) );

	if ( entries.length() > 0 )
		{
		int c = 0;

		argv[c++] = Tk_PathName(Self());
		argv[c++] = (char*) " config -entries { ";
		for ( int i = 0; i < entries.length(); ++i )
			argv[c++] = entries[i];
		argv[c++] = (char*) " }";

		tcl_ArgEval( this, c, argv );
		}

	return "";
	}

void MkCombobox::finalize_string( void *s ) { free_memory( (char*) s ); }

void MkCombobox::Create( ProxyStore *s, Value *args )
	{
	MkCombobox *ret;

	if ( args->Length() != 11 )
		InvalidNumberOfArgs(11);

	SETINIT
	SETVAL( parent, parent->IsAgentRecord() )
	SETVAL( ev, ev->Type( ) == TYPE_STRING )
	SETINT( width )
	SETSTR( justify )
	SETSTR( font )
	SETSTR( relief )
	SETDIM( borderwidth )
	SETSTR( foreground )
	SETSTR( background )
	SETSTR( state )
	SETSTR( fill )

	TkProxy *agent = (TkProxy*)(global_store->GetProxy(parent));
	if ( agent && ! strcmp( agent->AgentID(), "<graphic:frame>") )
		ret =  new MkCombobox( s, (TkFrame*)agent, ev->StringPtr(0), ev->Length( ), width,
				       justify, font, relief, borderwidth, foreground, background,
				       state, fill );
	else
		{
		SETDONE
		s->Error("bad parent type");
		return;
		}

	CREATE_RETURN
	}

STD_EXPAND_PACKINSTRUCTION(MkCombobox)

Value *MkProc::operator()(Tcl_Interp *tcl, Tk_Window s, Value *arg) {

	const char *val = 0;

	if ( agent ) {
		if ( mktab )
			val = (((MkTab*)agent)->*mktab)( arg);
		else if ( mkcombo )
			val = (((MkCombobox*)agent)->*mkcombo)( arg);
		else
			return TkProc::operator()( tcl, s, arg );
	} else
		return TkProc::operator()( tcl, s, arg );

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
