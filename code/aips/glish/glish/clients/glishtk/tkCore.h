// $Id: tkCore.h,v 19.0 2003/07/16 05:14:26 aips2adm Exp $
// Copyright (c) 1997,1998,2000 Associated Universities Inc.
//
#ifndef tkcore_h_
#define tkcore_h_

#include "tk.h"
#include "Glish/Proxy.h"
#include "Glish/Queue.h"
#include "config.h"
#include "Glish/glishtk.h"
#include "tkUtil.h"

//###  Functions for Converting Between Strings to Values
// Split a string up into an array of strings with each newline character
extern Value *glishtk_splitnl( char * );
// Split a string up into an array of ints with each space character
extern Value *glishtk_splitsp_int( const char * );
// Split a string up into an array of strings with each space character
// note the array which is returned will be trashed by subsequent calls.
extern char **glishtk_splitsp_str_( char *, int & );
extern Value *glishtk_splitsp_str( char * );

//###  Functions for Invoking Tk Commands For Callbacks
extern const char *glishtk_nostr(TkProxy *proxy, const char *cmd, Value *args);
extern const char *glishtk_oneint(TkProxy *proxy, const char *cmd, Value *args);
extern const char *glishtk_onebinary(TkProxy *proxy, const char *cmd, const char *ptrue,
			       const char *pfalse, Value *args);
extern const char *glishtk_onebool(TkProxy *proxy, const char *cmd, Value *args);
extern const char *glishtk_oneintlist(TkProxy *proxy, const char *cmd, int howmany, Value *args);
extern const char *glishtk_oneidx(TkProxy *, const char *cmd, Value *args);
extern const char *glishtk_oneortwoidx(TkProxy *, const char *cmd, Value *args);
extern const char *glishtk_strandidx(TkProxy *, const char *cmd, Value *args);
extern const char *glishtk_strwithidx(TkProxy *, const char *cmd, const char *param,
						Value *args);
extern const char *glishtk_no2str(TkProxy *, const char *cmd, const char *param,
						Value *args);

extern const char *glishtk_scrollbar_update(TkProxy *, const char *cmd, Value *args);

//### Event handlers common to Frame and tkCore widgets
extern const char *glishtk_bind(TkProxy *agent, const char *, Value *args );
extern const char *glishtk_disable_cb( TkProxy *a, const char *cmd, Value *args );

class TkFrameP : public TkFrame {
    public:
	TkFrameP( ProxyStore *s, charptr relief_, charptr side_, charptr borderwidth,
		  charptr padx_, charptr pady_, charptr expand_, charptr background,
		  charptr width, charptr height, charptr cursor, charptr title,
		  charptr icon, int new_cmap, TkProxy *tlead_, charptr tpos_,
		  charptr hlcolor, charptr hlbackground, charptr hlthickness,
		  charptr visual, int visualdepth, charptr logf );
	TkFrameP( ProxyStore *s, TkFrame *frame_, charptr relief_, charptr side_,
		  charptr borderwidth, charptr padx_, charptr pady_, charptr expand_,
		  charptr background, charptr width, charptr height, charptr cursor,
		  int new_cmap, charptr hlcolor, charptr hlbackground, charptr hlthickness );
	TkFrameP( ProxyStore *s, TkCanvas *canvas_, charptr relief_, charptr side_,
		  charptr borderwidth, charptr padx_, charptr pady_, charptr expand_,
		  charptr background, charptr width, charptr height, const char *tag_ );
	TkFrameP( ProxyStore *s, MkTab *tab_, charptr relief_, charptr side_,
		  charptr borderwidth, charptr padx_, charptr pady_, charptr expand_,
		  charptr background, charptr width, charptr height, const char *tag_ );

	// Called when the frame is killed via the window manager
	void KillFrame( );
	void ResizeEvent( );
	void LeaderMoved( );
	void LeaderMapped( );
	void LeaderUnmapped( );

	const char *SetSide( Value * );
	const char *SetPadx( Value * );
	const char *SetPady( Value * );
	const char *SetExpand( Value * );
	const char *GetTag( Value * );

	const char *SetResizable( Value * );
	const char *SetMinsize( Value * );
	const char *SetMaxsize( Value * );

	const char *SetIcon( Value * );

	const char *Grab( int global_scope=0 );
	const char *Release( );
	const char *GrabCB( Value * );
	const char *ReleaseCB( Value * );
	const char *FontsCB( Value * );

	const char *IconifyCB( Value * );
	const char *DeiconifyCB( Value * );

	const char *Raise( Value *args=0 );
	const char *Title( Value * );

	void Pack();
	void PackSpecial( TkProxy * );
	void AddElement( TkProxy *obj ) { elements.append(obj); }
	void RemoveElement( TkProxy *obj );
	void UnMap();

	static void Create( ProxyStore *, Value * );
	~TkFrameP();

	const char *Expand() const { return expand; }
	const char *Side() const;

	const char **PackInstruction();
	int CanExpand() const;

	int ExpandNum(const TkProxy *except=0, unsigned int grtOReqt = 0) const;

	int NumChildren() const { return elements.length() - 1; }

	void Disable( );
	void Enable( int force = 1 );

	Tk_Window TopLevel();
	FILE *Logfile();

    protected:
	char *side;
	char *padx;
	char *pady;
	char *expand;
	char *tag;
	TkCanvas *canvas;
	MkTab *tab;
  	tkagent_list elements;
	static unsigned long grab;

	Tk_Window topwin;

	unsigned char reject_first_resize;

	int size[2];

	TkProxy *tlead;
	char *tpos;
	int unmapped;

	FILE *logfile;

	char *icon;
	};

class FmeProc : public TkProc {
    public:

	FmeProc(TkFrameP *f, const char *(TkFrameP::*p)(Value*), TkStrToValProc cvt = 0)
			: TkProc(f,cvt), fproc(p) { }

	FmeProc(const char *c, TkEventProc p, TkStrToValProc cvt = 0)
			: TkProc(c,p,cvt), fproc(0) { }

	FmeProc(TkFrameP *a, const char *c, TkEventAgentProc p, TkStrToValProc cvt = 0)
			: TkProc(a,c,p,cvt), fproc(0) { }

	virtual Value *operator()(Tcl_Interp*, Tk_Window s, Value *arg);

    protected:
	const char *(TkFrameP::*fproc)(Value*);
};

class TkButton : public TkFrame {
    public:
	enum button_type { PLAIN, RADIO, CHECK, MENU };

	TkButton( ProxyStore *, TkFrame *, charptr label, charptr type_, charptr padx,
		  charptr pady, int width, int height, charptr justify, charptr font,
		  charptr relief, charptr borderwidth, charptr foreground,
		  charptr background, int disabled, const Value *val, charptr anchor,
		  charptr fill, charptr bitmap, TkFrame *group,
		  charptr hlcolor, charptr hlbackground, charptr hlthickness );
	TkButton( ProxyStore *, TkButton *, charptr label, charptr type_, charptr padx,
		  charptr pady, int width, int height, charptr justify, charptr font,
		  charptr relief, charptr borderwidth, charptr foreground,
		  charptr background, int disabled, const Value *val, charptr bitmap,
		  TkFrame *group, charptr hlcolor, charptr hlbackground, charptr hlthickness );

	void UnMap();

	unsigned char State() const;
	void State(unsigned char s);

	TkButton *Parent() { return menu; }
	Tk_Window Menu() { return type == MENU ? menu_base : menu ? menu->Menu() : 0; }
	int IsMenu() { return type == MENU; }
	int IsMenuEntry() { return menu != 0; }

	void Add(TkButton *item) {  entry_list.append(item); }
	void Remove(TkButton *item);
	const char *Index( ) const { return menu_index ? menu_index : ""; }

	void ButtonPressed( );
	static void Create( ProxyStore *, Value * );

	const char **PackInstruction();
	int CanExpand() const;

	~TkButton();

	void Disable( );
	void Enable( int force = 1 );

	Tk_Window TopLevel();
	FILE *Logfile();

	// Enable modification, used to allow glish commands to modify
	// a widget even if it has been disabled for the user.
	void EnterEnable();
	void ExitEnable();

    protected:
	Value *value;

	unsigned char state;		// only used for check buttons
	button_type type;

	TkButton *menu;
	TkFrame *radio;
	Tk_Window menu_base;
	unsigned long next_menu_entry;	// only used for menu buttons
	tkagent_list entry_list;        // only used for menu buttons
	void update_menu_index( int );
	char *menu_index;

	char *fill;
	int unmapped;
	};

class TkScale : public TkProxy {
    public:
	TkScale ( ProxyStore *, TkFrame *, double from, double to, double value, charptr len,
		  charptr text, double resolution, charptr orient, int width, charptr font,
		  charptr relief, charptr borderwidth, charptr foreground, charptr background,
		  charptr fill, charptr hlcolor, charptr hlbackground, charptr hlthickness,
		  int showvalue );

	// value was set, so generate an event
	void ValueSet( double );
	// set value
	void SetValue( double );
	void SetStart( double );
	void SetEnd( double );
	static void Create( ProxyStore *, Value * );
	~TkScale();

	void EnterEnable();
	void ExitEnable();

	void Disable( );
	void Enable( int force = 1 );

	const char **PackInstruction();
	int CanExpand() const;

	void UnMap();

    protected:
	char *fill;
	unsigned int id;
	static unsigned int scale_count;
	double from_, to_;
	double last_value;
	};

class TkText : public TkProxy {
    public:
	TkText( ProxyStore *, TkFrame *, int width, int height, charptr wrap,
		charptr font, int disabled, charptr text, charptr relief,
		charptr borderwidth, charptr foreground, charptr background,
		charptr fill, charptr hlcolor, charptr hlbackground, charptr hlthickness );

	charptr IndexCheck( charptr );
	const char **PackInstruction();
	int CanExpand() const;

	static void Create( ProxyStore *, Value * );
	void yScrolled( const double *firstlast );
	void xScrolled( const double *firstlast );
	~TkText();

	// Enable modification, used to allow glish commands to modify
	// a widget even if it has been disabled for the user.
	void EnterEnable();
	void ExitEnable();

	void Disable( );
	void Enable( int force = 1 );

	void UnMap();

    protected:
	char *fill;
	};

class TkScrollbar : public TkProxy {
    public:
	TkScrollbar( ProxyStore *, TkFrame *, charptr orient, int width,
		     charptr foreground, charptr background, int jump,
		     charptr hlcolor, charptr hlbackground, charptr hlthickness );

	const char **PackInstruction();
	int CanExpand() const;

	static void Create( ProxyStore *, Value * );
	void Scrolled( Value *data );
	~TkScrollbar();

	void EnterEnable();
	void ExitEnable();
	void Disable( );
	void Enable( int force = 1 );

	void UnMap();
	};

class TkLabel : public TkProxy {
    public:
	TkLabel( ProxyStore *, TkFrame *, charptr text,
		 charptr justify, charptr padx, charptr pady, int width,
		 charptr font, charptr relief, charptr borderwidth,
		 charptr foreground, charptr background, charptr anchor, charptr fill,
		 charptr hlcolor, charptr hlbackground, charptr hlthickness );

	static void Create( ProxyStore *, Value * );
	~TkLabel();

	const char **PackInstruction();
	int CanExpand() const;

    protected:
	char *fill;
	};

class TkEntry : public TkProxy {
    public:
	TkEntry( ProxyStore *, TkFrame *, int width,
		 charptr justify, charptr font, charptr relief, 
		 charptr borderwidth, charptr foreground, charptr background,
		 int disabled, int show, int exportselection, charptr fill,
		 charptr hlcolor, charptr hlbackground, charptr hlthickness );

	static void Create( ProxyStore *, Value * );

	charptr IndexCheck( charptr );
	charptr IndexCheck( int idx, char *buf=0 );

	void ReturnHit( );
	void xScrolled( const double *firstlast );

	const char **PackInstruction();
	int CanExpand() const;

	~TkEntry();

	void EnterEnable();
	void ExitEnable();

	void Disable( );
	void Enable( int force = 1 );

	void UnMap();

    protected:
	char *fill;

	};

class TkMessage : public TkProxy {
    public:
	TkMessage( ProxyStore *, TkFrame *, charptr text, charptr width,
		   charptr justify, charptr font, charptr padx, charptr pady,
		   charptr relief, charptr borderwidth,
		   charptr foreground, charptr background, charptr anchor, charptr fill,
		   charptr hlcolor, charptr hlbackground, charptr hlthickness, int aspect_ );

	static void Create( ProxyStore *, Value * );

	~TkMessage();

	const char **PackInstruction();
	int CanExpand() const;

    protected:
	char *fill;

	};

class TkListbox : public TkProxy {
    public:
	TkListbox( ProxyStore *, TkFrame *, int width, int height, charptr mode,
		   charptr font, charptr relief, charptr borderwidth,
		  charptr foreground, charptr background, int exportselection, charptr fill,
		   charptr hlcolor, charptr hlbackground, charptr hlthickness );

	charptr IndexCheck( charptr );
	charptr IndexCheck( int idx, char *buf=0 );

	void yScrolled( const double *firstlast );
	void xScrolled( const double *firstlast );
	void elementSelected( );
  
	static void Create( ProxyStore *, Value * );

	const char **PackInstruction();
	int CanExpand() const;

	~TkListbox();
	void UnMap();

    protected:
	char *fill;
	};

#endif
