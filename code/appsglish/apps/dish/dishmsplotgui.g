#   dishmsplotgui.g: GUI for dishmsplot
#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000,2001
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
#    $Id: dishmsplotgui.g,v 19.1 2004/08/25 01:10:39 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include	'widgetserver.g';

const dishmsplotgui := subsequence(parent, itsop, logcommand, 
				     widgetset=dws) {

    widgetset.tk_hold();

    private := [=];

    private.op := itsop;
    private.logcommand := logcommand;

    private.outerFrame :=
	widgetset.frame(parent, side='top', relief='ridge');
    # all GUI operations should be labeled, doing it this way ensures
    # that it remains centered at the top of the outer frame
    private.labelFrame := 
	widgetset.frame(private.outerFrame, expand='x');
    private.mainLabel := 
	widgetset.label(private.labelFrame, 'Display data with MSPLOT');

    private.combo := widgetset.combobox(private.outerFrame, 'msplot:',
					autoinsertorder='head',
					canclearpopup=T,entrywidth=20,
					help='The MS to display');

    private.bottomFrame := 
	widgetset.frame(private.outerFrame, expand='x', borderwidth=0,
			side='left');
    private.button := widgetset.button(private.bottomFrame,'Edit',type='check');
    # this padding ensures that the apply button is centered and the
    # dismiss button is all the way on the right
    private.leftPad :=
	widgetset.frame(private.bottomFrame, expand='x', width=1, borderwidth=0);
    private.applyFrame :=
	widgetset.frame(private.bottomFrame, side='right', borderwidth=0,expand='none');
    private.applyButton := 
	widgetset.button(private.applyFrame, 'Apply', type='action');
    # make sure you add popup help
    private.applyButton.shorthelp := 'Display the MS indicated';
    private.rightPad :=
	widgetset.frame(private.bottomFrame, expand='x', width=1, borderwidth=0);
    private.dismissButton := 
	widgetset.button(private.bottomFrame, 'Dismiss', type='dismiss');
    private.dismissButton.shorthelp := 'Dismiss this operation GUI';

    # the apply handler
    private.doapply := function() {
	wider private;
	# first, make sure the operation knows the GUIs state
	ent := private.combo.getentry();
	myedit := self.getedit();
	private.op.setms(ent, F);
	currselected := private.combo.get('selected');
	if (ent != '' && 
	    (is_fail(currselected) || ent != currselected)) {
	    private.combo.insert(ent,select=T);
	}
	private.logcommand('dish.ops().msplot.setms',[myms=ent]);
	private.op.apply(ent,myedit);
	private.logcommand('dish.ops().msplot.apply',[=]);
    }

    # the handlers for the above buttons
    whenever private.applyButton->press do {
	# invoke the apply function in the operation
	private.doapply();
    }

    whenever private.dismissButton->press do {
	self->dismiss(private.op.opmenuname());
    }

    self.outerframe := function() {
	wider private;
	return private.outerFrame;
    }

    # a done function which makes this GUI unusable
    self.done := function() {
	wider private, self;
	self->done();
    }

    self.setms := function(myms) {
	wider private;
	if (is_unset(myms)) {
	    private.combo.insertentry('');
	} else {
	    myms := as_string(myms);
	    private.combo.insertentry(myms);
	    currselected := private.combo.get('selected');
	    if (is_fail(currselected) || myms != currselected) {
		private.combo.insert(myms,select=T);
	    }
	}
    }

    self.getms := function() {
	wider private;
	return private.combo.getentry();
    }

    self.setedit := function(mystate) {
	wider private;
	private.button->state(mystate);
    }

    self.getedit := function() {
	wider private;
	return private.button->state();
    }

    self.sethistory := function(history) {
	wider private;
	private.combo.delete('start','end');
	if (!is_unset(history) && is_string(history) &&
	    len(history) > 0) {
	    for (i in 1:len(history)) {
		private.combo.insert(history[i],(i-1));
	    }
	}
    }

    self.gethistory := function() {
	wider private;
	return private.combo.get(0,'end');
    }

    self.setselection := function(selection) {
	wider private;
	if (is_integer(selection)) {
	    junk := private.combo.select(selection);
	}
    }

    self.getselection := function() {
	return private.combo.selection();
    }


    junk := widgetset.tk_release();

    # self is returned automatically, it should NOT be explicitly returned here
}
