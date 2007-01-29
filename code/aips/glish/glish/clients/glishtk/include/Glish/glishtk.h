// $Id: glishtk.h,v 19.0 2003/07/16 05:14:29 aips2adm Exp $
// Copyright (c) 1997,1998 Associated Universities Inc.
//
#ifndef tkagent_h_
#define tkagent_h_

#include "tk.h"
#include "Glish/Proxy.h"
#include "Glish/Queue.h"

#include <stdarg.h>
#include <stdio.h>

#if ! defined(HAVE_TCL_GETSTRINGRESULT)
#define Tcl_GetStringResult(tcl) (tcl)->result
#endif

extern int TkHaveGui();

class TkProxy;
class TkCanvas;
class TkFrame;
class MkTab;

typedef void (*WidgetCtor)( ProxyStore *, Value * );

glish_declare(PDict,char);
typedef PDict(char) name_hash;

glish_declare(PList,TkProxy);
typedef PList(TkProxy) tkagent_list;

class TkProc;
glish_declare(PDict,TkProc);
typedef PDict(TkProc) tkprochash;

#define NULL_TkProc ((TkProc*) -1)

//###  Function to do Argv Eval
extern int tcl_ArgEval( TkProxy *proxy, int argc, char *argv[] );

//###  Quote the string and return an alloc'ed string
extern char *glishtk_quote_string( charptr, int quote_empty_string=1 );
extern char *glishtk_quote_string( charptr*, int, int quote_empty_string=1 );

//###  Function to Make Callbacks
extern char *glishtk_make_callback( Tcl_Interp*, Tcl_CmdProc*, ClientData data, char *out=0 );

//###  scrollbar callback
extern const char *glishtk_scrolled_update(TkProxy *proxy, const char *cmd, Value *args);

//###  Callback Procs
typedef const char *(*TkEventProc)(Tcl_Interp*, Tk_Window, const char *, Value*);
typedef const char *(*TkOneParamProc)(Tcl_Interp*, Tk_Window, const char *, const char *, Value *);
typedef const char *(*TkTwoParamProc)(Tcl_Interp*, Tk_Window, const char *, const char *, const char *, Value *);
typedef const char *(*TkOneIntProc)(Tcl_Interp*, Tk_Window, const char *, int, Value *);
typedef const char *(*TkTwoIntProc)(Tcl_Interp*, Tk_Window, const char *, const char *, int, Value *);
typedef const char *(*TkEventAgentProc)(TkProxy*, const char *, Value*);
typedef const char *(*TkEventAgentProc2)(TkProxy*, const char *, const char *, Value*);
typedef const char *(*TkEventAgentProc3)(TkProxy*, const char *, const char *, const char *, Value*);
typedef const char *(*TkEventAgentProc4)(TkProxy*, const char *, int, Value *);
typedef const char *(*TkEventAgentProc5)(TkProxy*, const char *, const char *, int, Value *);
typedef Value *(*TkStrToValProc)( const char * );

class glishtk_event;
glish_declare(PQueue,glishtk_event);

//### Initialization function for loaded object...
extern "C" void GlishTk_init( ProxyStore *, int, const char * const * );
extern "C" void GlishTk_loop( ProxyStore *, const GlishCallback *, int, const GlishCallback *, int );

class TkProxy : public Proxy {
    friend void GlishTk_init( ProxyStore *, int, const char * const * );
    friend void GlishTk_loop( ProxyStore *, const GlishCallback *, int, const GlishCallback *, int );
    public:
	TkProxy( ProxyStore *s, int init_graphic=1 );
	~TkProxy();

	virtual charptr NewName( Tk_Window parent=0 ) const;
	virtual charptr IndexCheck( charptr );
	virtual charptr IndexCheck( int idx, char *buf=0 );

	virtual int IsValid() const;
	virtual void UnMap();
	Tk_Window Self() { return self; }
	Tcl_Interp *Interp() { return tcl; }
	const Tk_Window Self() const { return self; }

	virtual const char **PackInstruction();
	virtual int CanExpand() const;

	// Used to post events which *originate* from Tk. This is important
	// because of scrollbar/canvas initialization, i.e. the Tk events
	// must be queued and sent after the "whenever"s are in place.
	void PostTkEvent( const char *, Value * );

	static int GlishEventsHeld() { return hold_glish_events; }
	static void FlushGlishEvents();

	static void Version( ProxyStore *p, Value *v );
	static void HaveGui( ProxyStore *p, Value *v );
	static void CheckColor( ProxyStore *p, Value *v=0 );
	static void HoldEvents( ProxyStore *p=0, Value *v=0 );
	static void ReleaseEvents( ProxyStore *p=0, Value *v=0 );
	static int DoOneTkEvent( int flags, int hold_wait = 0 );
	static int DoOneTkEvent( );
	static void SetBitmapPath( ProxyStore *p, Value *v );
	static void Load( ProxyStore *p, Value *v );
	static void SetLoadPath( ProxyStore *p, Value *v );

	// For some widgets, they must be enabled before an action is performed
	// otherwise widgets which are disabled will not even accept changes
	// from a script.
	virtual void EnterEnable();
	virtual void ExitEnable();

	static Value *GetError() { Value *ret = last_error; last_error = 0; return ret; }
	static void SetError(Value*);

	void SetMap( int do_map, int toplevel );
	int DontMap( ) const { return dont_map; }

	virtual void Disable( );
	virtual void Enable( int force = 1 );
	int Enabled( ) const { return disable_count == 0; }

	void BindEvent(const char *event, Value *rec);

	virtual Tk_Window TopLevel( );
	virtual FILE *Logfile( );

	int IsPseudo();

	const char *AgentID() const { return agent_ID; }

	void ProcessEvent( const char *name, Value *val );

	// locate the bitmap file
	char *which_bitmap( const char * );

	static void Register( const char *, WidgetCtor );

    protected:
	static void set_global_store( ProxyStore *);
	static ProxyStore *global_store;

	void do_pack( int argc, char **argv);

	static const char *init_tk( int visible_root=1 );
	tkprochash procs;
	static int widget_index;
	static int root_unmapped;
	static Tk_Window root;
	static Tcl_Interp *tcl;
	Tk_Window self;
	TkFrame *frame;

	static int hold_tk_events;
	static int hold_glish_events;
	static PQueue(glishtk_event) *tk_queue;

	// For keeping track of last error
	static Value *last_error;
	static Value *bitmap_path;

	unsigned int enable_state;

	int dont_map;
	unsigned short withdrawn;
	unsigned short leader_unmapped;

	unsigned int disable_count;

	const char *agent_ID;
	int is_graphic;
	};

class TkProc {
    public:

	TkProc( TkProxy *a, TkStrToValProc cvt = 0 );
	TkProc(const char *c, TkEventProc p, TkStrToValProc cvt = 0);
	TkProc(const char *c, const char *x, const char *y, TkTwoParamProc p, TkStrToValProc cvt = 0);
	TkProc(const char *c, const char *x, int y, TkTwoIntProc p, TkStrToValProc cvt = 0);
	TkProc(const char *c, const char *x, TkOneParamProc p, TkStrToValProc cvt = 0);
	TkProc(const char *c, int x, TkOneIntProc p, TkStrToValProc cvt = 0);
	TkProc(TkProxy *a, const char *c, TkEventAgentProc p, TkStrToValProc cvt = 0);
	TkProc(TkProxy *a, const char *c, const char *x, TkEventAgentProc2 p, TkStrToValProc cvt = 0);
	TkProc(TkProxy *a, const char *c, const char *x, const char *y, TkEventAgentProc3 p, TkStrToValProc cvt = 0);
	TkProc(TkProxy *a, const char *c, int y, TkEventAgentProc4 p, TkStrToValProc cvt = 0);
	TkProc(TkProxy *a, const char *c, const char *x, int y, TkEventAgentProc5 p, TkStrToValProc cvt = 0);

	virtual Value *operator()(Tcl_Interp*, Tk_Window s, Value *arg);

    protected:
	const char *cmdstr;

	TkEventProc proc;
	TkOneParamProc proc1;
	TkTwoParamProc proc2;

	TkProxy *agent;
	TkEventAgentProc aproc;
	TkEventAgentProc2 aproc2;
	TkEventAgentProc3 aproc3;
	TkEventAgentProc4 aproc4;
	TkEventAgentProc5 aproc5;

	TkOneIntProc iproc;
	TkTwoIntProc iproc1;

	const char *param;
	const char *param2;

	TkStrToValProc convert;

	int i;
	};

class TkFrame : public TkProxy {
    public:

	TkFrame( ProxyStore *s ) : TkProxy(s), radio_id(0), id(++count) { }
	unsigned long RadioID() const { return radio_id; }
	void RadioID( unsigned long id_ ) { radio_id = id_; }
	unsigned long Id() const { return id; }

	virtual void AddElement( TkProxy *obj );
	virtual void RemoveElement( TkProxy *obj );
	virtual void Pack();
	virtual const char *Expand() const;
	virtual int NumChildren() const;

	virtual const char *Side() const;
	virtual int ExpandNum(const TkProxy *except=0, unsigned int grtOReqt = 0) const;

    private:

	static unsigned long count;
	unsigned long radio_id;
	unsigned long id;
};
	
extern void glishtk_log_to_file( FILE *, const char *, ... );
inline int tcl_VarEval( TkProxy *proxy,
			const char *a, const char *b )
	{
	FILE *fle;
	if ( (fle = proxy->Logfile()) ) glishtk_log_to_file( fle, a, b );
	return Tcl_VarEval( proxy->Interp(), a, b );
	}
inline int tcl_VarEval( Tcl_Interp *tcl, const char *a, const char *b )
	{ return Tcl_VarEval( tcl, a, b ); }

inline int tcl_VarEval( TkProxy *proxy,
			const char *a, const char *b, const char *c )
	{
	FILE *fle;
	if ( (fle = proxy->Logfile()) ) glishtk_log_to_file( fle, a, b, c );
	return Tcl_VarEval( proxy->Interp(), a, b, c );
	}
inline int tcl_VarEval( Tcl_Interp *tcl, const char *a, const char *b, const char *c )
	{ return Tcl_VarEval( tcl, a, b, c ); }

inline int tcl_VarEval( TkProxy *proxy,
			const char *a, const char *b, const char *c,
			const char *d )
	{
	FILE *fle;
	if ( (fle = proxy->Logfile()) ) glishtk_log_to_file( fle, a, b, c, d );
	return Tcl_VarEval( proxy->Interp(), a, b, c, d );
	}
inline int tcl_VarEval( Tcl_Interp *tcl, const char *a, const char *b, const char *c,
			const char *d )
	{ return Tcl_VarEval( tcl, a, b, c, d ); }

inline int tcl_VarEval( TkProxy *proxy,
			const char *a, const char *b, const char *c,
			const char *d, const char *e )
	{
	FILE *fle;
	if ( (fle = proxy->Logfile()) ) glishtk_log_to_file( fle, a, b, c, d, e );
	return Tcl_VarEval( proxy->Interp(), a, b, c, d, e );
	}
inline int tcl_VarEval( Tcl_Interp *tcl, const char *a, const char *b, const char *c,
			const char *d, const char *e )
	{ return Tcl_VarEval( tcl, a, b, c, d, e ); }

inline int tcl_VarEval( TkProxy *proxy,
			const char *a, const char *b, const char *c,
			const char *d, const char *e, const char *f )
	{
	FILE *fle;
	if ( (fle = proxy->Logfile()) ) glishtk_log_to_file( fle, a, b, c, d, e, f );
	return Tcl_VarEval( proxy->Interp(), a, b, c, d, e, f );
	}
inline int tcl_VarEval( TkProxy *proxy,
			const char *a, const char *b, const char *c,
			const char *d, const char *e, const char *f,
			const char *g )
	{
	FILE *fle;
	if ( (fle=proxy->Logfile()) ) glishtk_log_to_file( fle, a, b, c, d, e, f, g );
	return Tcl_VarEval( proxy->Interp(), a, b, c, d, e, f, g );
	}

inline int tcl_VarEval( TkProxy *proxy,
			const char *a, const char *b, const char *c,
			const char *d, const char *e, const char *f,
			const char *g, const char *h )
	{
	FILE *fle;
	if ( (fle=proxy->Logfile()) ) glishtk_log_to_file( fle, a, b, c, d, e, f, g, h );
	return Tcl_VarEval( proxy->Interp(), a, b, c, d, e, f, g, h );
	}

inline int tcl_VarEval( TkProxy *proxy,
			const char *a, const char *b, const char *c,
			const char *d, const char *e, const char *f,
			const char *g, const char *h, const char *i )
	{
	FILE *fle;
	if ( (fle=proxy->Logfile()) ) glishtk_log_to_file( fle, a, b, c, d, e, f, g, h, i );
	return Tcl_VarEval( proxy->Interp(), a, b, c, d, e, f, g, h, i );
	}

inline int tcl_VarEval( TkProxy *proxy,
			const char *a, const char *b, const char *c,
			const char *d, const char *e, const char *f,
			const char *g, const char *h, const char *i,
			const char *j )
	{
	FILE *fle;
	if ( (fle=proxy->Logfile()) ) glishtk_log_to_file( fle, a, b, c, d, e, f, g, h, i, j );
	return Tcl_VarEval( proxy->Interp(), a, b, c, d, e, f, g, h, i, j );
	}

#endif
