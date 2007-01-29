// $Id: tkCanvas.h,v 19.0 2003/07/16 05:14:27 aips2adm Exp $
// Copyright (c) 1997 Associated Universities Inc.
//

#ifndef tkcanvas_h
#define tkcanvas_

#include "tkCore.h"
//
//  For glish_declare(Dict,int)
//
#include "Glish/Client.h"

typedef Dict(int) canvas_item_count;

class TkCanvas : public TkProxy {
    public:
	TkCanvas( ProxyStore *, TkFrame *, charptr width, charptr height, const Value *region_,
		  charptr relief, charptr borderwidth, charptr background, charptr fill,
		  charptr hlcolor, charptr hlbackground, charptr hlthickness );

	void UnMap();

	const char **PackInstruction();

	void yScrolled( const double *firstlast );
	void xScrolled( const double *firstlast );

	void BindEvent(const char *event, Value *rec);

	void Add(TkFrame *item) {  frame_list.append(item); }
	void Remove(TkFrame *item) { frame_list.remove(item); }

	static void Create( ProxyStore *, Value * );
	~TkCanvas();
	int WidgetCount() const { return count; }
	int ItemCount(const char *) const;
	int NewItemCount(const char *);
	ProxyStore *seq() { return store; }
	int CanExpand() const;
    protected:
	char *fill;
	static int count;
	canvas_item_count item_count;
	tkagent_list frame_list;
	};

#endif
