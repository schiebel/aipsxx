# dishsavegui.g: the GUI for dishsave
#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000
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
#    $Id: dishsavegui.g,v 19.1 2004/08/25 01:11:15 cvsmgr Exp $
#
#------------------------------------------------------------------------------
# 
pragma include once;

include	'widgetserver.g';

const dishsavegui := subsequence(parent, itsop, itsdish, widgetset=dws) {
    widgetset.tk_hold();

    private := [=];

    private.op := itsop;
    private.logcommand := itsdish.logcommand;

    private.outerFrame :=
	widgetset.frame(parent, side='top', relief='ridge');
    private.labelFrame := 
	widgetset.frame(private.outerFrame, expand='x');
    private.mainLabel := 
	widgetset.label (private.labelFrame, 
			 'Save the currently displayed data.');

    private.combo := 
	itsdish.rm().wscombobox(private.outerFrame, 
				'Output Working Set',
				mode='w',
				help=paste('The working set in use by this operation.',
					   'Use File/New to add a new, empty working set.',
					   'Use File/Open/Reading and writing to add an existing working set.'));
    private.bottomFrame := 
	widgetset.frame(private.outerFrame, expand='x', borderwidth=0,
			side='left');
    private.leftPad :=
	widgetset.frame(private.bottomFrame, expand='x', width=1, borderwidth=0);
    private.applyFrame :=
	widgetset.frame(private.bottomFrame, side='right', borderwidth=0,expand='none');
    private.applyButton := 
	widgetset.button(private.applyFrame, 'Apply', type='action');
    # make sure you add popup help
    private.applyButton.shorthelp := 'Save to the output working set.';
    private.rightPad :=
	widgetset.frame(private.bottomFrame, expand='x', width=1, borderwidth=0);
    private.dismissButton := 
	widgetset.button(private.bottomFrame, 'Dismiss', type='dismiss');
    private.dismissButton.shorthelp := 'Dismiss this operation GUI';

    whenever private.dismissButton->press do {
	self->dismiss(private.op.opmenuname());
    }

    # the handlers for the above buttons
    whenever private.applyButton->press do {
	ok := private.op.apply();
	if (!is_fail(ok) && ok) {
	    private.logcommand('dish.ops().save.setws',
			       [wsname=private.combo.getentry()]);
	    private.logcommand('dish.ops().save.apply',[=]);
	}
    }

    # set the selection in the combobox to the indicated ws by name
    self.setws := function(wsname) {
	# if this is not a string, clear it
	if (!is_string(wsname)) {
	    private.combo.insertentry('');
	} else {
	    # see if its already in the combobox
	    contents := private.combo.get('start','end');
	    if (len(contents)) {
		which := ind(contents)[contents == wsname];
		# select it
		private.combo.select(as_string(which-1));
	    }
	}
    }

    self.wsname := function() {
	wider private;
	return private.combo.getentry();
    }

    self.outerframe := function() {
	wider private;
	return private.outerFrame;
    }

    self.done := function() {
	wider private;
	val private.outerFrame := F;
	val private := F;
    }

    self.debug := function() {wider private; return private;}

    junk := widgetset.tk_release();

    # self is returned automatically, it should NOT be explicitly returned here
}
