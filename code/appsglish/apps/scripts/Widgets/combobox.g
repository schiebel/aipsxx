# combobox.g: General-purpose combobox widget.
# -----------------------------------------------------------------------------
#   Copyright (C) 1998,1999,2000,2001
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#    $Id: combobox.g,v 19.2 2004/08/25 02:12:32 cvsmgr Exp $
#
#------------------------------------------------------------------------------
# combobox
#
# design notes:
# -------------
# the main goal is to provide something like the combobox widget that first
# appeared with windows 3.1.  This widget is a combination of a tk label
# a tk entry and a tk listbox which appears when a button is pressed.
# When the listbox pops up, it grabs global focus on the window 
# manager.  Any button-1 press event releases the grab and removes
# the popped up window.  If the cursor is in the listbox, a button-1
# event will generate a selection, which will appear in the entry field,
# if not, nothing in the entry field has changed.
#
# implementation notes
# --------------------
#   - please see the description in guicomponents.help
#   - The complex widget emits events via the public.agent() member.
#     Whenever's can be set up on this agent.
#   - listboxes are 0-relative indexed and the combobox maintains that
#     The internal private.selected points to the currently selected item
#     in the listbox and is -1 if nothing is selected.  This index is
#     0-relative so be careful when using it.
#   - The order of arguments was chosen to try and put arguments for
#     which the default will likely be OK later in the argument list.
#
# todo list
# ---------
# - Is the mixture of functions and events too confusing?
# - Is there a need for finer control over the placement of
#   stuff the components within the widget
# - Should this maintain the 0-relative indexing as listbox does or should
#   this be different and do 1-relative indexing as most of aips++ does?
# - Its apparently not possible to get the width of the listbox to
#   match the width of the entry since there is no way to query the
#   current with of the entry widget. This would appear to be a 
#   tk feature, but that should be verified before we give up on this.
# - See if there is a "best" ordering of the first few defaulted arguments
#   so that the ones most likely to be changed really do come first.
#------------------------------------------------------------------------------

pragma include once;

include 'widgetserver.g';

const combobox := function(parent, labeltext='label', items=F, 
			   addonreturn=T, entrydisabled=F,
			   canclearpopup=F,
			   autoinsertorder='tail', disabled=F, 
			   borderwidth=2, exportselection=T,
			   vscrollbar='ondemand', hscrollbar='none',
			   labelwidth=0, labelfont='',
			   labelrelief='flat',labeljustify='left',
			   labelbackground='lightgrey', labelforeground='black',
			   labelanchor='c',
			   entrywidth=30, entryfont='', entryrelief='sunken',
			   entryjustify='left', entrybackground='lightgrey',
			   entryforeground='black',
			   arrowbutton='downarrow.xbm',
			   arrowbackground='lightgrey',
			   arrowforeground='black',
			   listboxheight=6,
			   help='',
			   widgetset=dws)
{
    private := [=];
    private.ws := widgetset;

    private.f := private.ws.frame(parent,side='left',borderwidth=borderwidth,expand='x');

    private.l := private.ws.label(private.f,text=labeltext,justify=labeljustify,
				  font=labelfont, width=labelwidth, relief=labelrelief,
				  foreground=labelforeground, background=labelbackground,
				  anchor=labelanchor);
    private.ef := private.ws.frame(private.f,side='left',borderwidth=0,expand='x');
    private.ef2 := private.ws.frame(private.ef,side='top',borderwidth=0,expand='x');
    private.e := private.ws.entry(private.ef2, width=entrywidth, justify=entryjustify,
				  font=entryfont, relief=entryrelief, 
				  foreground=entryforeground, background=entrybackground,
				  disabled=entrydisabled,exportselection=exportselection);
    # which thing gets the help, default is for the label to get it but if there is no
    # label, give it to the entry
    helpedWidget := ref private.l;
    if (strlen(labeltext) == 0) {
	helpedWidget := ref private.e;
    } 
    if(help!='') {
	helpedWidget.shorthelp := help;
    } else if (strlen(labeltext) != 0) {
	# strip off any leading and trailing white space
	helpedWidget.shorthelp := paste('Required value(s) for', labeltext ~ s/^\s*(.*?)\s*$/$1/g );
    }

    # list is the fallback text if the bitmap file can't be opened
    private.bf := private.ws.frame(private.ef,borderwidth=0,height=1,width=1,side='top',expand='y');
    private.b := private.ws.button(private.bf,bitmap=arrowbutton,text='List',
				   foreground=arrowforeground,background=arrowbackground);
    private.b.shorthelp := 'Press to show history of entries';
    # this padding keeps the button at the top - necessary when a horzontal
    # scrollbar is added to the entry widget
    private.bfpad := private.ws.frame(private.bf,borderwidth=0,height=1,width=1,expand='y');
    if (is_boolean(items)) {
	private.hasitems := F;
	private.items := '';
	private.b->disabled(T);
	private.selected := -1;
    } else {
	private.hasitems := T;
	private.items := items;
	private.selected := 0;
    }
    private.addonreturn := addonreturn;
    private.isdisabled := disabled;
    private.entryisdisabled := entrydisabled;
    private.entryforeground := entryforeground;
    private.entrybackground := entrybackground;
    private.entrywidth := entrywidth;
    private.entryfont := entryfont;
    private.entryjustify := entryjustify;
    private.entryrelief := entryrelief;
    private.listboxheight := listboxheight;
    private.popupcursor := 'left_ptr';
    private.vscrollbar := F;
    private.vondemand := T;
    private.hscrollbar := F;
    private.hondemand := T;
    private.hasscrollbar := F;
    private.canclearpopup := canclearpopup;

    private.tailinsert := T;
    if (autoinsertorder == 'head') private.tailinsert := F;

    public := [=];
    private.agent := create_agent();
    public.agent := function() {
	wider private;
	return ref private.agent;
    }

    private.setVScrollbarType := function(type) {
	wider private;
	private.vscrollbar := F;
	if (type == 'ondemand') {
	    private.vscrollbar := T;
	    private.vondemand := T;
	} else if (type == 'always') {
	    private.vscrollbar := T;
	    private.vondemand := F;
	}
    }
    private.setHScrollbarType := function(type) {
	wider private;
	private.hscrollbar := F;
	if (type == 'ondemand') {
	    private.hscrollbar := T;
	    private.hondemand := T;
	} else if (type == 'always') {
	    private.hscrollbar := T;
	    private.hondemand := F;
	}
    }

    private.addHScrollBar := function() {
	wider private;
	if (!private.hasscrollbar) {
	    private.esb := private.ws.scrollbar(private.ef2,orient='horizontal');
	    whenever private.esb->scroll do
		private.e->view($value);
	    whenever private.e->xscroll do
		private.esb->view($value);
	}
	private.hasscrollbar := T;
    }

    private.removeHScrollBar := function() {
	wider private;
	private.hasscrollbar := F;
	private.esb := F;
    }

    private.setHScrollBar := function() {
	wider private;
	if (private.hscrollbar) {
	    if (private.hondemand) {
		if (private.maxlen > private.entrywidth) 
		    private.addHScrollBar();
		else 
		    private.removeHScrollBar();
	    } else {
		private.addHScrollBar();
	    }
	}
	else private.removeHScrollBar();
    }

    private.setVScrollbarType(vscrollbar);
    private.setHScrollbarType(hscrollbar);
    if (!private.hscrollbar) private.hasscrollbar := F;
    private.maxlen := 0;
    if (private.hscrollbar && !private.hondemand) private.addHScrollBar();
    else if (private.hondemand && private.hasitems) {
	private.maxlen := max(strlen(private.items));
	private.setHScrollBar();
    }

    private.addItem := function(newItem, selectIt=T, index=F) {
	wider private;
	if (is_boolean(index)) {
	    if (private.tailinsert) {
		index := len(private.items);
	    } else {
		index := 0;
	    }
	}
	if (private.hasitems) {
	    oldlen := len(private.items);
	    private.items[oldlen+1] := '';
	    if (index < oldlen) {
		private.items[(index+2):(oldlen+1)] := 
		    private.items[(index+1):(oldlen)];
	    }
	    if (private.selected >= index) private.selected +:= 1;
	    private.items[index+1] := newItem;
	} else {
	    private.items := newItem;
	    private.hasitems := T;
	    index := 0;
	    private.b->disabled(F);
	}
	if (selectIt) {
	    private.selected := index;
	    private.selectIt;
	}
	if (private.hondemand) {
	    thislen := strlen(newItem);
	    if (thislen > private.maxlen) {
		private.maxlen := thislen;
		private.setHScrollBar();
	    }
	}
    }

    private.selectIt := function() {
	wider private;
	private.e->delete('0','end');
	if (private.selected >= 0) {
	    private.e->insert(private.items[private.selected+1]);
	}
    }

    whenever private.e->return do {
	wider public;
	thisValue := $value;
	if (private.addonreturn) {
	    private.addItem(thisValue);
	    private.agent->select(private.selected);
	}
	private.agent->return(thisValue);
    }
	
    private.entrydisabled := function(tOrF) {
	wider private;
	private.e->disabled(tOrF);
    }
	
    if (private.hasitems && private.selected >= 0) {
	private.e->insert(private.items[private.selected+1]);
    }


    private.popup := F;

    private.makepopup := function() {
	wider private;
	if (is_boolean(private.popup)) {
	    private.popup := [=];
	    private.popup.f := private.ws.frame(tlead=private.ef,side='left');
	    lbh := private.listboxheight;
	    noVScrollbar := (!private.vscrollbar) ||
		(private.vondemand && len(private.items) <= lbh);
	    if (noVScrollbar) lbh := len(private.items);
	    lbw := private.entrywidth;
	    if (!private.hasscrollbar) lbw := 
		max(private.entrywidth,private.maxlen);
	    private.popup.lb := 
		private.ws.scrolllistbox(private.popup.f,
					 hscrollbar=private.hasscrollbar,
					 vscrollbar=(!noVScrollbar),
					 seeoninsert=F,
					 width=lbw, height=lbh,
					 font=private.entryfont,
					 relief=private.entryrelief,
					 background=private.entrybackground,
					 foreground=private.entryforeground);
	    if (private.hasitems) {
		private.popup.lb->insert(private.items);
		if (private.selected >= 0) {
		    private.popup.lb->select(as_string(private.selected));
		    private.popup.lb->see(as_string(private.selected));
		}
		if (private.canclearpopup) {
		    private.popup.b := private.ws.button(private.popup.f,'Clear',
							 font=private.entryfont);
		    whenever private.popup.b->press do {
			private.delete('start','end');
			private.agent->clear(T);
			private.cleanuppopup();
		    }
		}
	    }
	    private.popup.f->bind('<Button-1>','button1');
	    private.popup.f->bind('<Enter>','enter');
	    private.popup.f->bind('<Leave>','leave');
	    # button 1 only shows up outside of the listbox
	    whenever private.popup.f->button1 do {private.cleanuppopup();}
	    whenever private.popup.lb->select do {
		private.selected := as_integer($value);
		private.e->delete('0','end');
		if (private.hasitems) {
		    private.e->insert(private.items[private.selected+1]);
		}
		private.agent->select(private.selected);
		private.cleanuppopup();
	    }
	    # enter and leave signal cursor changes
	    whenever private.popup.f->enter do {
		private.popup.f->cursor(private.popupcursor);
	    }
	    whenever private.popup.f->leave do {
		private.popup.f->cursor('X_cursor');
	    }
	}
	private.popup.f->grab('global');
    }

    private.index := function(str) {
	if (len(str) == 0) return 0;
	if (is_numeric(str)) return as_integer(str);
	if (str == 'end') {
	    return len(private.items)-1;
	} else {
	    if (str == 'selected' || str == 'active') {
		if (private.selected < 0) 
		    fail('combobox has no current selection');
		return private.selected;
	    }
	}
	n := as_integer(str);
	if (n < 0 || n >= len(private.items)) 
	    fail('combobox index out of range');
	return n;
    }

    private.delete := function(first, last) {
	wider private;
	if (first==last) {
	    fndx := private.index(first);
	    lndx := fndx;
	} else {
	    fndx := private.index(first);
	    lndx := private.index(last);
	}
	if (is_fail(fndx) || is_fail(lndx)) fail;
	mask := F;
	if (fndx == 0) {
	    if (lndx == (len(private.items)-1)) {
		# delete everything
		private.items := '';
		private.selected := -1;
		private.hasitems := F;
		private.b->disabled(T);
	    } else {
		mask := [(lndx+1):(len(private.items)-1)];
	    }
	} else {
	    if (lndx == (len(private.items)-1)) {
		mask := [0:(fndx-1)];
	    } else {
		mask := [[0:(fndx-1)],[(lndx+1):(len(private.items)-1)]];
	    }
	}
	mask +:= 1;
	if (!is_boolean(mask)) {
	    private.items := private.items[mask];
	    if (private.selected >= fndx & private.selected <= lndx) {
		private.selected := fndx-1;
	    } else {
		if (private.selected >= lndx) {
		    private.selected -:= (lndx-fndx)+1;
		}
	    }
		  if (private.selected < 0) private.selected := 0;
	}
	private.selectIt();
	if (private.hondemand) {
	    if (private.hasitems) {
		private.maxlen := max(strlen(private.items));
	    } else {
		private.maxlen := 0;
	    }
	    if (private.maxlen <= private.entrywidth) {
		private.removeHScrollBar();
	    }
	}
    }

    private.cleanuppopup := function() {
	wider private;
	private.popup.f->release();
	val private.popup.lb := F;
	val private.popup.f := F;
	val private.popup := F;
    }

    private.disable := function(tOrF) {
	wider private;
	private.isdisabled := tOrF;
	if (private.hasitems) private.b->disabled(tOrF);
	if (!private.entryisdisabled) private.entrydisabled(tOrF);
    }

					# const public.debug := function() { wider private; return ref private;}

    whenever private.b->press do { 
	wider private;
	wider public;
	private.makepopup();
	private.agent->press(T);
    }

    const public.pixelwidth := function() {
	wider private;
	return private.f->pixelwidth();
    }
    const public.pixelheight := function() {
	wider private;
	return private.f->pixelheight();
    }
    const public.get := function(first, last=F) {
	wider private;
	if (is_boolean(last)) {
	    # single position
	    fi := private.index(first);
	    if (is_fail(fi)) fail;
	    return private.items[fi+1];
	} else {
	    # multi position
	    fi := private.index(first);
	    li := private.index(last);
	    if (is_fail(fi) || is_fail(last)) fail;
	    return private.items[(fi+1):(li+1)];
	}
    }
    const public.selection := function() {
	wider private;
	return private.selected;
    }
    const public.select := function(whichitem) {
	wider private;
	ndx := private.index(whichitem);
	if (is_fail(ndx)) fail;
	private.selected := ndx;
	private.selectIt();
	return T;
    }

    const public.getentry := function() {
	wider private;
	return private.e->get();
    }
    public.addonreturn := function(addonreturn) {
	wider private;
	private.addonreturn := addonreturn;
    }
    public.canclearpopup := function(tOrF) {
	wider private;
	private.canclearpopup := tOrF;
    }
    public.borderwidth := function(newwidth) {
	wider private;
	private.f->borderwidth(newwidth);
    }

    public.exportselection := function(tOrF) {
	wider private;
	private.e->exportselection(tOrF);
    }

    public.disabled := function(tOrF) {
	wider private;
	private.disable(tOrF);
    }

    public.delete := function(first, last=F) {
	wider private;
	if (is_boolean(last)) last:=first;
	private.delete(first, last);
    }

    public.insert := function(newitem, index=F, select=F) {
	wider private;
	if (!is_boolean(index)) {
	    ndx := private.index(index);
	    if (is_fail(ndx)) ndx := F;
	    private.addItem(newitem, select, ndx);
	} else {
	    private.addItem(newitem, select);
	}
	return T;
    }

    public.insertentry := function(newentry) {
	wider private;
	private.e->delete('0','end');
	private.e->insert(newentry);
    }

    public.vscrollbar := function(vscrollbar) {
	wider private;
	private.setVScrollbarType(vscrollbar);
    }

    public.hscrollbar := function(hscrollbar) {
	wider private;
	private.setHScrollbarType(hscrollbar);
	private.setHScrollBar();
    }

    public.autoinsertorder := function(insertorder) {
	wider private;
	if (insertorder == 'head') {
	    private.tailinsert := F;
	} else {
	    private.tailinsert := T;
	}
    }

    public.bind := function(xevent, eventname) {
	wider private;
	wider public;
	private.e->bind(xevent, eventname);
	whenever private.e->[eventname] do {
	    private.agent->[eventname]($value);
	}
    }

    public.cursor := function(xcursor) {
	wider private;
	private.f->cursor(xcursor);
    }

    public.popupcursor := function(xcursor) {
	wider private;
	private.popupcursor := xcursor;
    }

    # label related functions
    public.labeltext := function(newlabel) {
	wider private;
	private.l->text(newlabel);
    }
    public.labelwidth := function(newwidth) {
	wider private;
	private.l->width(newwidth);
    }
    public.labelfont := function(newfont) {
	wider private;
	private.l->font(newfont);
    }
    public.labelrelief := function(newrelief) {
	wider private;
	private.l->relief(newrelief);
    }
    public.labeljustify := function(newjustify) {
	wider private;
	private.l->justify(newjustify);
    }
    public.labelforeground := function(newforeground) {
	wider private;
	private.l->foreground(newforeground);
    }
    public.labelbackground := function(newbackground) {
	wider private;
	private.l->background(newbackground);
    }
    public.labelanchor := function(newanchor) {
	wider private;
	private.l->anchor(newanchor);
    }

    # entry related functions
    public.entrydisabled := function(tOrF) {
	wider private;
	private.entryisdisabled := tOrF;
	if (!private.isdisabled) {
	    private.entrydisabled(private.entryisdisabled);
	}
    }
    public.entrywidth := function(newwidth) {
	wider private;
	private.entrywidth := newwidth;
	private.e->width(private.entrywidth);
	if (is_record(private.popup)) {
	    private.popup.lb->width(private.entrywidth);
	}
	private.setHScrollBar();
    }
    public.entryfont := function(newfont) {
	wider private;
	private.entryfont := newfont;
	private.e->font(private.entryfont);
	if (is_record(private.popup)) {
	    private.popup.lb->font(private.entryfont);
	}
    }
    public.entryjustify := function(newjustify) {
	wider private;
	private.entryjustify := newjustify;
	private.e->justify(private.entryjustify);
	if (is_record(private.popup)) {
	    private.popup.lb->justify(private.entryjustify);
	}
    }
    public.entryrelief := function(newrelief) {
	wider private;
	private.entryrelief := newrelief;
	private.e->relief(private.entryrelief);
	if (is_record(private.popup)) {
	    private.popup.lb->relief(private.entryrelief);
	}
    }
    public.entryforeground := function(newforeground) {
	wider private;
	private.entryforeground := newforeground;
	private.e->foreground(private.entryforeground);
	if (is_record(private.popup)) {
	    private.popup.lb->foreground(private.entryforeground);
	}
    }
    public.entrybackground := function(newbackground) {
	wider private;
	private.entrybackground := newbackground;
	private.e->background(private.entrybackground);
	if (is_record(private.popup)) {
	    private.popup.lb->background(private.entrybackground);
	}
    }

    # arrow button related functions
    public.arrowbutton := function(newbutton) {
	wider private;
	private.b->bitmap(newbutton);
    }
    public.arrowforeground := function(newforeground) {
	wider private;
	private.b->foreground(newforeground);
    }
    public.arrowbackground := function(newbackground) {
	wider private;
	private.b->background(newbackground);
    }

    # listbox functions
    public.listboxheight := function(newheight) {
	wider private;
	private.listboxheight := newheight;
	if (is_record(private.popup)) {
	    private.popup.lb->height(private.listboxheight);
	}
    }

    widgetset.addpopuphelp(private);

    public.debug := function() { wider private; return private;}

    return public;
}

# this wraps up an existing combobox so that it
# checks first to see that, on a return event, that the
# current entry value isn't identical to the last selected
# value.  It only adds a new value if they are not identical.
# If ignorewhitespace==T then the comparison ignores any whitespace.
# The existing combobox is changed in place, nothing is returned.
# It is a useful example and it is used in the dish package.

const uniquelastcombobox := function(ref existingcombobox, ignorewhitespace=F)
{
    private := [=];
    private.ignorewhitespace := ignorewhitespace;
    
    # this is the comparison function, it return T if they
    # are not identical and there fore should be added.
    
    private.addThisItem := function(a, b) {
	wider private;
	result := F;
	if (is_string(a) && is_string(b) && len(a) == len(b)) {
	    if (ignorewhitespace) {
		a ~:= s/\s+//g;
		b ~:= s/\s+//g;
	    }
	    result := a != b;
	}
	return result;
    }
    # turn off auto add on return on the existing combobox
    existingcombobox.addonreturn(F);

    whenever existingcombobox.agent()->return do {
	wider private;
	newitem := $value;
	currselection := existingcombobox.get('selected');
	if (is_fail(currselection)) {
	    existingcombobox.insert(newitem,select=T);
	} else {
	    if (private.addThisItem(newitem, currselection)) {
		existingcombobox.insert(newitem,select=T);
	    }
	}
    }
}

tcombobox := function ()
{
  f := dws.frame (title='test combobox ()',side='top');
  cb1 := dws.combobox (f,'colors',
		       "red blue green yellow amber brown orange saffron");
  cb2 := dws.combobox (f,'COLORS',
		       "RED BLUE GREEN YELLOW AMBER BROWN ORANGE SAFFRON",
		       hscrollbar='always');
  cb3 := dws.combobox (f,'Tables', vscrollbar='none');
  j := uniquelastcombobox(cb3);
  cb4 := dws.combobox (f,'empty');
  junk := cb3.insert ('one');
  junk := cb3.insert ('two');
  junk := cb3.insert ('three');
  junk := cb3.insert ('four');
  junk := cb3.insert ('five');
  junk := cb3.insert ('six');
  junk := cb3.insert ('seven');
  whenever cb3.agent()->select do {
      print 'combobox select event: new selection for cb3:', $value;
      print 'item := ', cb3.get($value);
  }
  return ref [f=f,cb1=cb1,cb2=cb2,cb3=cb3,cb4=cb4];

}# tcombobox
