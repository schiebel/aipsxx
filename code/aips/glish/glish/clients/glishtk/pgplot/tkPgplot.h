// $Id: tkPgplot.h,v 19.0 2003/07/16 05:14:39 aips2adm Exp $
// Copyright (c) 1997,1998 Associated Universities Inc.
//
#ifndef tkpgplot_h_
#define tkpgplot_h_
#include "Glish/glishtk.h"

class TkPgplot : public TkProxy {
    public:
	TkPgplot (ProxyStore *, TkFrame *, charptr width, charptr height, 
		  const Value *region_, const Value *axis_, const Value *nxsub, 
		  const Value *nysub, charptr relief_, charptr borderwidth, 
		  charptr padx, charptr pady, charptr foreground, charptr background,
		  charptr fill_, int mincolor, int maxcolor, int cmap_share, int cmap_fail );
	TkPgplot (ProxyStore *, const Value *idv, const Value *region_, const Value *axis_,
		  const Value *nxsub, const Value *nysub );

	static void Create (ProxyStore *, Value * );

	~TkPgplot ();

	int IsValid() const;
	void UnMap ();
	void yScrolled (const double *firstlast);
	void xScrolled (const double *firstlast);

	const char **PackInstruction ();

	int CanExpand () const;

	// Standard PGPLOT routines.
	const char *Pgarro (Value *);
	const char *Pgask (Value *);
	const char *Pgbbuf (Value *);
	const char *Pgbeg (Value *);
	const char *Pgbin (Value *);
	const char *Pgbox (Value *);
	const char *Pgcirc (Value *);
	const char *Pgclos (Value *);
	const char *Pgconb (Value *);
	const char *Pgconl (Value *);
	const char *Pgcons (Value *);
	const char *Pgcont (Value *);
	const char *Pgctab (Value *);
	const char *Pgdraw (Value *);
	const char *Pgebuf (Value *);
	const char *Pgend (Value *);
	const char *Pgenv (Value *);
	const char *Pgeras (Value *);
	const char *Pgerrb (Value *);
	const char *Pgerrx (Value *);
	const char *Pgerry (Value *);
	const char *Pgetxt (Value *);
	const char *Pggray (Value *);
	const char *Pghi2d (Value *);
	const char *Pghist (Value *);
	const char *Pgiden (Value *);
	const char *Pgimag (Value *);
	const char *Pglab (Value *);
	const char *Pgldev (Value *);
	const char *Pglen (Value *);
	const char *Pgline (Value *);	
	const char *Pgmove (Value *);
	const char *Pgmtxt (Value *);
	const char *Pgnumb (Value *);
	const char *Pgopen (Value *);
	const char *Pgpage (Value *);
	const char *Pgpanl (Value *);
	const char *Pgpap (Value *);
	const char *Pgpixl (Value *);
	const char *Pgpnts (Value *);
	const char *Pgpoly (Value *);
	const char *Pgpt (Value *);
	const char *Pgptxt (Value *);
	const char *Pgqah (Value *);
	const char *Pgqcf (Value *);
	const char *Pgqch (Value *);
	const char *Pgqci (Value *);
	const char *Pgqcir (Value *);
	const char *Pgqcol (Value *);
	const char *Pgqcr (Value *);
	const char *Pgqcs (Value *);
	const char *Pgqfs (Value *);
	const char *Pgqhs (Value *);
	const char *Pgqid (Value *);
	const char *Pgqinf (Value *);
	const char *Pgqitf (Value *);
	const char *Pgqls (Value *);
	const char *Pgqlw (Value *);
	const char *Pgqpos (Value *);
	const char *Pgqtbg (Value *);
	const char *Pgqtxt (Value *);
	const char *Pgqvp (Value *);
	const char *Pgqvsz (Value *);
	const char *Pgqwin (Value *);
	const char *Pgrect (Value *);
	const char *Pgrnd (Value *);
	const char *Pgrnge (Value *);
	const char *Pgsah (Value *);
	const char *Pgsave (Value *);
	const char *Pgscf (Value *);
	const char *Pgsch (Value *);
	const char *Pgsci (Value *);
	const char *Pgscir (Value *);
	const char *Pgscr (Value *);
	const char *Pgscrn (Value *);
	const char *Pgsfs (Value *);
	const char *Pgshls (Value *);
	const char *Pgshs (Value *);
	const char *Pgsitf (Value *);
	const char *Pgslct (Value *);
	const char *Pgsls (Value *);
	const char *Pgslw (Value *);
	const char *Pgstbg (Value *);
	const char *Pgsubp (Value *);
	const char *Pgsvp (Value *);
	const char *Pgswin (Value *);
	const char *Pgtbox (Value *);
	const char *Pgtext (Value *);
	const char *Pgunsa (Value *);
	const char *Pgupdt (Value *);
	const char *Pgvect (Value *);
	const char *Pgvsiz (Value *);
	const char *Pgvstd (Value *);
	const char *Pgwedg (Value *);
	const char *Pgwnad (Value *);

	// change cursor
	const char *Cursor (Value *);

    protected:
	int is_valid;
	int id;
	char *fill;
};

class PgProc : public TkProc {
    public:

	PgProc(TkPgplot *f, const char *(TkPgplot::*p)(Value*), TkStrToValProc cvt = 0)
			: TkProc(f,cvt), pgproc(p) { }

	PgProc(const char *c, TkEventProc p, TkStrToValProc cvt = 0)
			: TkProc(c,p,cvt), pgproc(0) { }

	PgProc(TkPgplot *a, const char *c, TkEventAgentProc p, TkStrToValProc cvt = 0)
			: TkProc(a,c,p,cvt), pgproc(0) { }

	virtual Value *operator()(Tcl_Interp*, Tk_Window s, Value *arg);

    protected:
	const char *(TkPgplot::*pgproc)(Value*);
};

#endif
