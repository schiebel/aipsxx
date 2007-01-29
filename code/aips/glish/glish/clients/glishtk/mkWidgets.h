// $Id: mkWidgets.h,v 19.0 2003/07/16 05:15:14 aips2adm Exp $
// Copyright (c) 2002 Associated Universities Inc.
//
#ifndef mkwidgets_h_
#define mkwidgets_h_
#include "Glish/glishtk.h"
#include "Glish/Dict.h"

glish_declare(PDict,TkProxy);
typedef PDict(TkProxy) tkproxyhash;

class MkWidget : public TkProxy {
    public:
	MkWidget( ProxyStore *s );
    private:
	static int initialized;
};

class MkTab : public MkWidget {
    public:
	MkTab( ProxyStore *, TkFrame *, charptr width, charptr height );
	static void CreateContainer( ProxyStore *, Value * );
	static void CreateTab( ProxyStore *, Value * );
	void Raise( const char *tag );
	int WidgetCount( ) const { return count; }
	int ItemCount(const char *) const { return tabcount; }
	int NewItemCount(const char *) { return ++tabcount; }
	const char *Width( ) const { return width; }
	const char *Height( ) const { return height; }
	void Add( const char *tag, TkProxy *proxy );
	void Remove( const char *tag );
	void UnMap( );
	~MkTab( );
	ProxyStore *seq() { return store; }
    protected:
	char *width;
	char *height;
	static int count;
	int tabcount;
	tkproxyhash elements;
};

class MkCombobox : public MkWidget {
    public:
	MkCombobox( ProxyStore *, TkFrame *, charptr *entries_, int num, int width,
		    charptr justify, charptr font, charptr relief, charptr borderwidth,
		    charptr foreground, charptr background, charptr state, charptr fill );
	static void Create( ProxyStore *, Value * );

	void Return( );
	void Selection( );

	const char **PackInstruction();

	const char *Insert( Value * );

    protected:
	static void finalize_string( void * );
	name_list entries;
	char *fill;
};

class MkProc : public TkProc {
    public:

	MkProc(MkWidget *mk, const char *(MkTab::*p)(Value*), TkStrToValProc cvt = 0)
			: TkProc(mk,cvt), mktab(p), mkcombo(0) { }

	MkProc(MkWidget *mk, const char *(MkCombobox::*p)(Value*), TkStrToValProc cvt = 0)
			: TkProc(mk,cvt), mktab(0), mkcombo(p) { }

	virtual Value *operator()(Tcl_Interp*, Tk_Window s, Value *arg);

    protected:
	const char *(MkTab::*mktab)(Value*);
	const char *(MkCombobox::*mkcombo)(Value*);
};

#endif
