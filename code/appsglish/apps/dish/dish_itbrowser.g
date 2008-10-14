# dish_itbrowser: Dish sditerator browser.
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: dish_itbrowser.g,v 19.1 2004/08/25 01:08:44 cvsmgr Exp $
#
#----------------------------------------------------------------------------

# include guard
pragma include once;

include "sditerator.g";
include "dish_recbrowser.g";
include "widgetserver.g";


# sdrecViewFunction takes two args, the data and its name

const sditbrowser := subsequence(iterator, name = F, sdrecViewFunction = F, 
				 topFrame = F, separateRecBrowser = T,
				 rmpaste=F,itsdish=F)
{
    dws.tk_hold();
    private := [=];
    private.nlb := 0;
    private.lblist := [=];
    private.copypastmenus := [=];
    private.alwaysClear := F;
    private.useBrowser := F;
    private.viewPending := F;
    private.viewInProgress := F;
    private.sepRecBrowser := separateRecBrowser;
    private.rmpaste:=rmpaste;
    private.it := iterator;
    private.size := private.it.length();
    private.curr := 0;
    private.delayPending := F;
    private.name := name;
    # use Brian's timer closure when it catches up to Darrell's recent changes.
	initial:=time();
    private.timer := client("timer -oneshot");
    private.dish := ref itsdish;
    private.rm := itsdish.rm()

    if (is_boolean(topFrame)) private.topFrame := 
	dws.frame(title='SD Working Set Browser');
    if (is_boolean(name)) {
	private.name := private.it.name();
    }
    # l := dws.label(private.topFrame, private.name);
    lb := dws.button(private.topFrame, private.name, type='action');
    popuphelp(lb,txt='Press to refresh this browser');
    whenever lb->press do {self.refresh();}
    private.outerFrame := dws.frame(private.topFrame,side='left',borderwidth=0);
    private.yScrollFrame := dws.frame(private.outerFrame, side='left',
		borderwidth=0);
    private.lbFrame:=dws.frame(private.yScrollFrame, side='left',borderwidth=0);
    private.browserFrame := F;
				
    # this should ultimately be attached to each sdrec
    if (is_function(sdrecViewFunction)) 
	private.view_sdrec := sdrecViewFunction;
    else {
	note('No view function available in the iterator');
    }

    private.getCurr := function()
    {
	wider private;
	wider self;
	# watch for changes in the size of private.it - refresh if different
	itlen := private.it.length();
	if (itlen != private.size) {
	    self.refresh();
	}
	private.it.setlocation(private.curr+1);
	return private.it.get();
    }

    private.viewCurr := function()
    {
	wider private;
	if (private.viewInProgress) {
	    private.viewPending := T;
	} else {
	    private.viewInProgress := T;
	    sdrec := private.getCurr();

	    if (private.useBrowser->state()) {
		private.sdbrowser.setRecord(sdrec, 
			paste('Record ',private.curr+1));
	    }
	    if (private.alwaysPlot->state()&&is_function(private.view_sdrec)) {
#		overlay := ! (private.alwaysClear->state());
		overlay := F;
		if (is_record(private.rm)) {
		    private.rm.setlastviewed([value=sdrec, 
					   name=sdrec.header.source_name,
					   description='Browser transient']);
		}
		private.view_sdrec(sdrec, sdrec.header.source_name,
				   overlay=overlay);
	    }
	    private.viewInProgress := F;
	    if (private.viewPending) {
		private.viewPending := F;
		private.viewCurr();
	    }
	}
    }

    private.yscrollCallback := function(theValue, lbId)
    {
	wider private;
	private.yScrollbar->view(theValue);
	# this should also update the other listboxs via view
	# but that is not possible
    }

    private.selectCallback := function(newSelection, callingLB=-1,
				       noview = F)
    {
	wider private;
	private.topFrame->cursor('watch');
	if (newSelection < 0) newSelection := 0;
	if (newSelection >= private.size) newSelection := private.size - 1;
	which := paste(newSelection);
	for (i in field_names(private.lblist)) {
	    if (private.lblist[i].id != callingLB) {
		# lb curr might sometimes not be the same as the internal curr
		# due to arrow key interactions, primarily.
		curr := private.lblist[i].lb->selection();
		if (len(curr)) private.lblist[i].lb->clear(as_string(curr));
		private.lblist[i].lb->select(which);
		private.lblist[i].lb->see(which);
	    }
	}
	private.curr := newSelection;
	if (!noview) private.viewCurr();
	private.topFrame->cursor('left_ptr');
    }

    # wait for events to catch up with the listboxes
    private.delayedSelection := function(newwhich) {
	wider private;
	if (!private.delayPending) {
	    private.delayPending := T;
	    private.curr := newwhich;
	    private.timer->register(0.01);
	    await private.timer->tag;
	    tag := $value;
	    whenever private.timer->[tag] do {
		private.selectCallback(private.curr);
		private.delayPending := F;
	    }
	}
    }

    self.addListBox := function (theLabel, relief='sunken', fixwidth=F,
                                 widgetset=dws)
    {
	wider private;

	private.nlb +:= 1;
	id := private.nlb;
	private.lblist[id] := [=];
	private.lblist[id].id := id;
	if (is_integer(fixwidth)) {
	    private.lblist[id].frame := widgetset.frame(private.lbFrame, 
			borderwidth=0,expand='y');
	    private.lblist[id].label:=widgetset.label(private.lblist[id].frame,
			theLabel);
	    private.lblist[id].lb :=widgetset.listbox(private.lblist[id].frame, 
			mode='browse', fill='both', relief=relief,
			width=fixwidth, exportselection=F);
	} else {
	    private.lblist[id].frame := widgetset.frame(private.lbFrame, 
			borderwidth=0);
	    private.lblist[id].label:=widgetset.label(private.lblist[id].frame, 			theLabel);
	    private.lblist[id].lb := widgetset.listbox(private.lblist[id].frame,
 			mode='browse', fill='both',relief=relief,
			exportselection=F);
	}
	private.lblist[id].xsb := widgetset.scrollbar(private.lblist[id].frame, 
			orient='horizontal');
	whenever private.lblist[id].xsb->scroll do {
	    private.lblist[id].lb->view($value);
	}
	whenever private.lblist[id].lb->xscroll do {
	    private.lblist[id].xsb->view($value);
	}
	whenever private.lblist[id].lb->yscroll do {
	    private.yscrollCallback($value, id);
	}
	whenever private.lblist[id].lb->select do {
	    private.curr := $value;
	    private.selectCallback(private.curr, id);
	}
	private.lblist[id].lb->bind('<Key-Up>','up');
	private.lblist[id].lb->bind('<Key-j>','up');
	private.lblist[id].lb->bind('<Key-KP_Up>','up');
	private.lblist[id].lb->bind('<Key-Down>','down');
	private.lblist[id].lb->bind('<Key-k>','down');
	private.lblist[id].lb->bind('<Key-KP_Down>','down');
	private.lblist[id].lb->bind('<Key-Home>','home');
	private.lblist[id].lb->bind('<Key-KP_Home>','home');
	private.lblist[id].lb->bind('<Key-End>','end');
	private.lblist[id].lb->bind('<Key-KP_End>','end');

	whenever private.lblist[id].lb->up do {
	    private.curr -:= 1;
	    private.delayedSelection(private.curr);
	}

	whenever private.lblist[id].lb->down do {
	    private.curr +:= 1;
	    private.delayedSelection(private.curr);
	}

	whenever private.lblist[id].lb->end do {
	    private.selectCallback(private.size);
	}

	whenever private.lblist[id].lb->home do {
	    private.selectCallback(0);
	}
	    
        # add the copypastemenu
        copyItems := ['Copy to clipboard', 'Copy to results manager'];
        private.lblist[id].cpmenu :=
            widgetset.popupselectmenu(private.lblist[id].lb, copyItems);
        whenever private.lblist[id].cpmenu->select do {
            wider self;
            option := $value;
            if (option == 'Copy to clipboard') {
                self.copy();
            } else if (option == 'Copy to results manager') {
                # use the clipboard, first copy it to the CB
                self.copy();
                # and then paste it to the results manager
                if (is_function(private.rmpaste)) private.rmpaste();
            }
        }

	return id;
    }

    # add the default list boxes
    lb1 := self.addListBox('Record', relief='flat', 
		fixwidth=(as_integer(log(private.size) + 2)));
    lb2 := self.addListBox('Scan');
    lb3 := self.addListBox('Object');

    private.setListBoxValues := function()
    {
	wider private;
	hv:= private.it.getheadervector("scan_number source_name");
	if (private.it.length() != private.size) {
	    oldlb1width := as_integer(log(private.size)+2);
	    private.size := private.it.length();
	    newlb1width := as_integer(log(private.size)+2);
	    if (newlb1width > oldlb1width) {
		private.lblist[lb1]->width(newlb1width);
	    }
	}

	private.lblist[lb1].lb->delete('start','end');
	private.lblist[lb2].lb->delete('start','end');
	private.lblist[lb3].lb->delete('start','end');
	if (private.size > 0) {
	    private.lblist[lb1].lb->insert(as_string([1:private.size]));
	    private.lblist[lb2].lb->insert(as_string(hv.scan_number));
	    private.lblist[lb3].lb->insert(hv.source_name);
	}
    }
       
	
    # add the y scroll bar

    private.yScrollbarFrame := dws.frame(private.yScrollFrame, expand='y');
    private.topPad := dws.frame(private.yScrollbarFrame, expand='none', 
		width=23, height=23);
    private.yScrollbar := dws.scrollbar(private.yScrollbarFrame);
    private.bottomPad := dws.frame(private.yScrollbarFrame, expand='none', 
		width=23, height=23,relief='groove');

    # and a dismiss button on the bottom
    private.bottomBar := dws.frame(private.topFrame,side='left',expand='x',
		borderwidth=0);

    private.clearBox := dws.frame(private.bottomBar,side='left',borderwidth=0);
#    private.alwaysClear := dws.button(private.clearBox,'Always clear plotter',
#			       type='check');
#    popuphelp(private.alwaysClear,
#	      txt='Turn this off to overplot each new selection');
#    if (is_agent(private.alwaysClear)) private.alwaysClear->state(F);
    # private.alwaysClear->disabled(T);
    private.alwaysPlot := dws.button(private.clearBox,'Plot selection',
			      type='check');
    popuphelp(private.alwaysPlot,
	      txt='Turn this on to plot each new selection');
    private.alwaysPlot->state(T);
    whenever private.alwaysPlot->press do {
	if (private.alwaysPlot->state() && is_function(private.view_sdrec)) {
	    sdrec := private.getCurr();
	    overlay := ! (private.alwaysClear->state());
	    # eventually this should only be a hint, but for now, actually
	    # always clear the plotter if an overlay is NOT requested
	    if (!overlay) { 
		private.dish.plotter().clear_plotter();
	    }
	    if (is_record(private.rm)) {
		private.rm.setlastviewed([value=sdrec, name=sdrec.header.source_name,
					  description='Browser transient']);
	    }
	    private.view_sdrec(sdrec, sdrec.header.source_name,overlay=overlay);
	}
    }
    private.useBrowser := dws.button(private.clearBox,'Browse record',
				type='check');
    private.useBrowser->state(F);
    popuphelp(private.useBrowser,
	      txt='Start the record browser');

    private.dismissBox:=dws.frame(private.bottomBar,side='right',borderwidth=0);
    private.dismissButton := dws.button(private.dismissBox,'Dismiss',
		type='dismiss');
    popuphelp(private.dismissButton, hlp='Dismiss this browser ',
	      txt='the associated record browser, if displayed, is NOT dismissed via this button', combi=T);

    private.dismiss := function () 
    {
	wider private;
	wider self;
	# first the listboxes
	for (i in field_names(private.lblist)) val private.lblist[i].frame := F;
	# then the frames held here
	val private.yScrollbarFrame := F;
	val private.dismissFrame := F;
	val private.topFrame := F;
	# and finally report it
	self->dismissed();
    }

    whenever private.dismissButton->press do {
	private.dismiss();
    }

    private.attachBrowser := function()
    {
	wider private;
	private.topFrame->cursor('watch');
	dws.tk_hold();
	sdrec := private.getCurr();
	if (! private.sepRecBrowser) {
	    private.browserFrame := dws.frame(private.outerFrame,borderwidth=0,
			height=0, width=0);
	}
	private.sdbrowser:=sdrecordbrowser(sdrec,paste('Record ',private.curr+1),private.browserFrame);
	whenever private.sdbrowser->dismissed do { private.browserDismissed()};
	dws.tk_release();
	private.topFrame->cursor('left_ptr');
   }

    private.dismissBrowser := function()
    {
	wider private;
	if (is_record(private.sdbrowser)) private.sdbrowser.dismiss();
	val private.sdbrowser := F;
	val private.browserFrame := F;
    }

    if (private.sepRecBrowser) {
	private.setBrowserFrameMapping := function(state)
	{
	    wider private;
	    if (state) {
		private.attachBrowser();
	    } else {
		private.dismissBrowser();
	    }
	}
	private.browserDismissed := function()
	{
	    wider private;
	    private.sdbrowser := F;
	    private.browserFrame := F;
	    private.useBrowser->state(F);
	}
    } else {
	private.setBrowserFrameMapping := function(state)
	{
	    wider private;
	    if (state) {
		if (is_boolean(private.browserFrame))
		    private.attachBrowser();
		else
		    private.browserFrame->map();
	    } else {
		private.browserFrame->unmap();
	    }
	}
    }

    whenever private.useBrowser->press do {
	private.setBrowserFrameMapping(private.useBrowser->state());
    }

    self.select := function(which)
    {
	wider private;
	private.selectCallback(which);
    }

    self.size := function()
    {
	wider private;
	return private.size;
    }

    # add event handling
    whenever private.yScrollbar->scroll do
    {
	for (i in field_names(private.lblist)) {
	    private.lblist[i].lb->view($value);
	}
    }

    private.curr := 0;
#    private.selectCallback(private.curr);
    private.sdbrowser := F;

    # for debugging purposes - remove eventually
#    self.private := function() { wider private; return private;}

    self.dismiss := function() { wider private; private.dismiss();}

    self.isactive := function() { wider private; 
	return is_agent(private.topFrame);}

    self.getstate := function() {
	wider private;
	state := [=];

	state.row := private.curr;
#	state.clearplotter := private.alwaysClear->state();
	state.clearplotter := F;
	state.plotselection := private.alwaysPlot->state();
	state.browserec := private.useBrowser->state();

	return state;
    }

    self.setstate := function(state) {
	wider private;
	if (is_record(state)) {
	    # default state
	    toview := 0;
#	    private.alwaysClear->state(T);
	    if (is_agent(private.alwaysClear)) private.alwaysClear->state(F);
	    private.alwaysPlot->state(T);
	    private.useBrowser->state(F);
	    private.dismissBrowser();
	    if (has_field(state,'row') &&
		is_integer(state.row) &&
		state.row != private.curr &&
		state.row >= 0 &&
		state.row < private.it.length()) {
		toview := state.row;
	    }
	    private.selectCallback(toview);
	} 
    }

    self.copy := function() {
        wider private;
        # copy the currently selected record to the clipboard
        # make it look like it came from the results manager so that
        # we can pass more information
        cbrec := [=];
        cbrec.names := spaste('rec_',private.curr+1,'_browser');
        # possibly but record number and name of iterator here
        cbrec.descriptions := paste('SDRECORD from browse of',private.name);
        cbrec.values := [=];
        cbrec.values[cbrec.names] := private.getCurr();
        return dcb.copy(cbrec);
    }

    self.refresh := function() {
	wider private;
	dws.tk_hold();
	dws.tk_release();
	# redo the internals which depend on the state of the iterator
	private.setListBoxValues();
	if (private.curr >= private.it.length()) {
	    # if the curr pointer is beyond the end, reset it to the end
	    private.curr := max(0,private.it.length()-1);
	}
	if (private.it.length() > 0) private.selectCallback(private.curr,noview=T);
	return T;
    }
    self.refresh();

    junk := dws.tk_release();
}

