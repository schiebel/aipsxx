# dishbaselinegui.g: a GUI for the dish baseline operation.
#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000,2001,2003
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
#    $Id: dishbaselinegui.g,v 19.1 2004/08/25 01:09:24 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include	'widgetserver.g';

include 'dishentries.g';
include 'dish_util.g';
#include 'dish_ranges.g'

const dishbaselinegui := subsequence(parent, itsdish=dish, widgetset=dws) {
    widgetset.tk_hold();

    private := [=];

    private.op := itsdish.ops().baseline;
    private.logcommand := itsdish.logcommand;
    private.base := "dish.ops().baseline.";
    private.plotter := itsdish.plotter;
    # the results manager is needed in order to query last viewed in one place
    private.rm := itsdish.rm();

    private.units := [=];
    private.units["channels"] := 'Channels';
    private.units["xaxis"] := 'X-Axis Units';

    private.rangeUnits := F;

    private.statistics_selection := function()
    {
	return private.ranges.get_marked_indices (private.plotter.ips.getcurrentabcissa());
    }

    private.rangeBoxReturned := function ()
    {
	wider private;
	if (is_boolean(private.rangeUnits)) {
	    private.rangeUnits := private.currUnits;
	} else {
	    curlen := len(private.rangeUnits);
	    private.rangeUnits[curlen+1] := private.currUnits;
	    private.rangeUnits[2:(curlen+1)] := private.rangeUnits[1:curlen];
	    private.rangeUnits[1] := private.currUnits;
	}
#	# and update the plotter
#	# the combobox has been updated internally when the return happened
	return private.updatePlotterRanges();
    }

    private.rangeBoxSelected := function (eventvalue)
    {
	wider private, self;
	itsunits := private.rangeUnits[eventvalue+1];
	itsvalue := private.rangeBox.get(eventvalue);
	ok := private.op.setrangestring(itsvalue, itsunits);
	return private.op.setrangestring(itsvalue, itsunits);
    }

    private.rangeBoxCleared := function() 
    {
	wider private;
#	private.ranges.delete_all_ranges();
	private.plotter.putranges('');
	private.rangeUnits := F;
	if (is_sdrecord(private.rm.getlastviewed().value)) {
           private.plotter.plotrec(private.rm.getlastviewed().value);
	};
    }

    # outerFrame - top to bottom
    private.outerFrame := widgetset.frame (parent, side='top', relief='ridge');
    # labelFrame - just contains the label
    private.labelFrame := widgetset.frame (private.outerFrame, expand='x');
    private.mainLabel := widgetset.label (private.labelFrame, 'Baselines');
    # dialogFrame - left to right
    private.dialogFrame := widgetset.frame (private.outerFrame, side='left', expand='x');
    # typeFrame - top to bottom
    private.typeFrame := widgetset.frame (private.dialogFrame, borderwidth=0, side='top',
					  expand='y');
    # polyFrame - left to right
    private.polyFrame := widgetset.frame (private.typeFrame, borderwidth=0, side='left');
    private.polynomialTypeButton := 
	widgetset.button (private.polyFrame, text='Polynomial', type='radio', 
			  relief='flat', value="polynomial");
    popuphelp(private.polynomialTypeButton, hlp='Fit a Polynomial');
    private.orderMenuButton := 
	widgetset.button (private.polyFrame, type='menu',
			  text=spaste ('Order ', 1), width=11);
    popuphelp(private.orderMenuButton,
	      hlp='Set the polynomial order.',
	      txt='order=0 is a constant, order=1 is a line, order=2 is quadratic, etc...',
	      combi=T);
    # end polyFrame

    # sinewaveButtonFrame - left to right
    private.sinewaveButtonFrame := 
	widgetset.frame (private.typeFrame, borderwidth=0, side='left', expand='x');
    # same group as polynomial button
    private.sinewaveTypeButton := 
	widgetset.button (private.sinewaveButtonFrame, 'Sinusoid', type='radio', 
			  relief='flat', group=private.polyFrame, value="sinusoid");
    popuphelp(private.sinewaveTypeButton,
	      hlp='Fit a sinusoid about the mean',
	      txt='The mean is first subtracted from the data before the sinusoid is fit to it.',
	      combi=T);
    private.sinewavePad := 
	widgetset.frame (private.sinewaveButtonFrame, expand='x', borderwidth=0, 
			 height=1, width=1);
    # end sinewaveButtonFrame

    # sineParmsFrame - top to bottom
    private.sineParmsFrame := 
	widgetset.frame (private.typeFrame, side='top', borderwidth=0, expand='x');
    private.sineAmpEntry := 
	labeledEntry (private.sineParmsFrame, ' Amplitude', '1',
		      entryWidth=12, justify='right',
		      hlp='Initial amplitude guess',
		      txt='y = amplitude*cos(2pi(x-X0)/period)',
		      combi=T, widgetset=widgetset);
    private.periodX0Frame := 
	widgetset.frame (private.sineParmsFrame, side='left', borderwidth=0, expand='x');
    private.periodX0EntryFrame := 
	widgetset.frame (private.periodX0Frame, side='top', borderwidth=0, expand='none');
    private.sinePeriodEntry := 
	labeledEntry (private.periodX0EntryFrame, '    Period',
		      '1', entryWidth=12, justify='right',
		      hlp='Initial period guess',
		      txt='y = amplitude*cos(2pi(x-X0)/period)',
		      combi=T, widgetset=widgetset);
    private.sineX0Entry := 
	labeledEntry (private.periodX0EntryFrame, '        X0', '0',
		      entryWidth=12, justify='right',
		      hlp='Initial X0 guess',
		      txt='y = amplitude*cos(2pi(x-X0)/period)',
		      combi=T, widgetset=widgetset);
    private.periodX0Pad := 
	widgetset.frame (private.periodX0Frame, borderwidth=0, height=1, width=1, 
			 expand='x');
    private.maxIterEntry := 
	labeledEntry (private.sineParmsFrame, 'Max. Iter.', '10',
		      entryWidth=12, justify='right',
		      hlp='Maximum number of iterations',
		      txt='The fit will stop after this many iterations',
		      widgetset=widgetset);
    private.criteriaEntry := 
	labeledEntry (private.sineParmsFrame, '  Criteria',
		      '0.001', entryWidth=12, justify='right',
		      hlp='Convergence criteria',
		      txt='The fit has converged with the fractional change in chisq is less than or equal to this value',
		      combi=T, widgetset=widgetset);
    # end sineParmsFrame

    private.typePad := 
	widgetset.frame (private.typeFrame, borderwidth=0, height=1, width=1, expand='y');
    # end of typeFrame

    # actionFrame - top to bottom
    private.actionFrame := 
	widgetset.frame (private.dialogFrame, side='top', expand='both');

    private.recalculateButton := 
	widgetset.button (private.actionFrame, type='check', text='Recalculate    ',
			  width=15, relief='flat');
    popuphelp(private.recalculateButton,
	      hlp='Recalculate if pressed',
	      txt='The fit is recalculated if this button is in the pressed position when Apply is pressed. If this button is not pressed, the last fit calculated will be used.',
	      combi=T);
    private.showButton := 
	widgetset.button (private.actionFrame, type='radio', text='Show           ', 
			  relief='flat', value="show");
    popuphelp(private.showButton,
	      hlp='Show the result if pressed',
	      txt='The fit is plotted on top of the data and not subtracted from the data.',
	      combi=T);
    private.subtractButton := 
	widgetset.button (private.actionFrame, type='radio', text='Subtract       ',
			  relief='flat', value="subtract");
    popuphelp(private.subtractButton,
	      hlp='Subtract from data if pressed',
	      txt='The fit is subtracted from the data and that result is then plotted',
	      combi=T);
    private.actionPad1 := 
	widgetset.frame (private.actionFrame, expand='both', height=1, width=1);
    private.plotranges := widgetset.button(private.actionFrame,type='check',text='Select Range', relief='flat');
    private.actionPad2 := 
	widgetset.frame (private.actionFrame, expand='both', height=1, width=1);
    # end actionFrame

    # padding to keep rightFrame on right, everything else on left
    private.dialogPad := 
	widgetset.frame (private.dialogFrame, borderwidth=0, width=10, expand='x');
    # rightFrame - top to bottom
    private.rightFrame := 
	widgetset.frame (private.dialogFrame, side='top', expand='both');
    # applyButtonFrame
    private.applyButton := 
	widgetset.button (private.rightFrame, text='Apply', height=3, type='action');
    popuphelp(private.applyButton,
	      hlp='Do this operation',
	      txt='The states of the various buttons are checked and whatever action is required is done.',
	      combi=T);

    private.rmsEntry := 
	labeledEntry (private.rightFrame, 'RMS of fit', '',
		      entryWidth=15, justify='right',
		      hlp='The RMS of the (fit-data)',
		      txt='This is calcualted over the range specified',
		      combi=T, widgetset=widgetset);
    private.convergedEntry := 
	labeledEntry (private.rightFrame, ' Converged', 'F',
		      entryWidth=15, justify='right',
		      hlp='Did the fit converge',
		      txt='This only has meaning for a sinusoid fit.',
		      combi=T, widgetset=widgetset);
    private.iterationsEntry := 
	labeledEntry (private.rightFrame, 'Iterations', '0',
		      entryWidth=15, justify='right',
		      hlp='Actual number of iterations',
		      txt='How many iteration did the sinusoid fitter do.',
		      widgetset=widgetset);
    # rightFramePad
    private.rightFramePad := 
	widgetset.frame (private.rightFrame, height=1, width=1,
			 borderwidth=0, side='top', expand='both');
    # end rightFrame
    # end dialogFrame

    # rangesFrame
    private.rangeFrame := 
	widgetset.frame (private.outerFrame, borderwidth=0, side='left');
    # JAU: Need a label here for combobox?
    private.rangeEntryFrame := 
	widgetset.frame (private.rangeFrame, borderwidth=0, side='top', expand='x');
    private.rangeLabel := 
	widgetset.label (private.rangeEntryFrame,
			 text='Ranges to include in fit:');
    private.rangeBox := 
	widgetset.combobox(private.rangeEntryFrame,'',autoinsertorder='head',
			   hscrollbar='always',canclearpopup=T,
			   entrywidth=80, entrybackground='white',
			   help=paste('The current active baseline ranges.',
				      'The fit will occur over these channels.',
				      'Hit return here to force the plotter to redraw the ranges'));
    uniquelastcombobox(private.rangeBox, T);
    whenever private.rangeBox.agent()->select do {
	private.rangeBoxSelected($value);
    }
    whenever private.rangeBox.agent()->return do {
	private.rangeBoxReturned();
    }
    whenever private.rangeBox.agent()->clear do {
	private.rangeBoxCleared();
    }

    whenever private.plotranges->press do {
	rangestate:=private.plotranges->state();
	ok:=private.plotter.setranges(private.rangeBox,rangestate);
    };
    private.bottomFrame := 
	widgetset.frame(private.outerFrame, side='right', borderwidth=0, expand='x');
    private.dismissFrame := widgetset.frame(private.bottomFrame, expand='none');
    private.dismissButton := 
	widgetset.button(private.dismissFrame, 'Dismiss', type='dismiss');
    popuphelp(private.dismissButton,
	      hlp='Dismiss this operation GUI',
	      txt='This is equivalent to using the Operations menu to turn off this GUI.',
	      combi=T);
#    private.rangePlotterFrame := widgetset.frame (private.bottomFrame, relief='groove');
    # Initialize the range-handling system.  Hairy stuff right now.
#    private.ranges := sdTkPgplotter_newranges ('Baselining', itsdish, ref private.statistics_selection);
#    private.ranges.display().create (parentFrame=private.rangePlotterFrame, rangeType='Baselining');
#    private.rangeButtonsFrame := 
#	widgetset.frame (private.rangeFrame, borderwidth=0, side='top', expand='none');
    # leave callbacks unset for now, set it later
#    private.rangeButtonsPad := 
#	widgetset.frame (private.rangeButtonsFrame, borderwidth=0, height=1, width=1, 
#			 expand='y');
    # outerPad to keep everything above this in place
    private.outerPad := 
	widgetset.frame (private.outerFrame, height=1, width=1, expand='both');
    # end outerPad

    private.orderButtons := [=];

    for (i in 0:25) {
	private.orderButtons[i+1] := 
	    widgetset.button (private.orderMenuButton, text=spaste (i), value=i);
	whenever private.orderButtons[i+1]->press do {
	    private.setorder($value);
	}
    }

    # the apply handler
    private.doapply := function() {
	wider private, self;
	# make sure that the entry state is reflects in the underlying op
	# the buttons should keep up, just the sine parameters if necessary
	# and the ranges
	if (private.sinewaveTypeButton->state()) {
	    private.op.setamplitude(self.getamplitude());
	    private.logcommand('dish.ops().baseline.setamplitude',
			       [amplitude=self.getamplitude()]);
	    private.op.setperiod(self.getperiod());
	    private.logcommand('dish.ops().baseline.setperiod',
			       [amplitude=self.getperiod()]);
	    private.op.setx0(self.getx0());
	    private.logcommand('dish.ops().baseline.setx0',
			       [amplitude=self.getx0()]);
	    private.op.setmaxiter(self.getmaxiter());
	    private.logcommand('dish.ops().baseline.setmaxiter',
			       [amplitude=self.getmaxiter()]);
	    private.op.setcriteria(self.getcriteria());
	    private.logcommand('dish.ops().baseline.setcriteria',
			       [amplitude=self.getcriteria()]);
	}
	# and do the apply, all state information should now be up to date
	# with this GUI in private.op
	private.op.apply();
    }

    # the handlers for the above buttons
    whenever private.applyButton->press do {
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
	state := [=];
	val private.outerFrame := F;
	val private := F;
	self->done(state);
    }

    private.updatePlotterRanges := function() {
	wider self,private;
#	currranges := private.op.getrange('xaxis');
	currranges := self.getranges();
	private.plotter.putranges(currranges);
	return T;
    }

    private.currUnits := '';

    private.unitNumber := function(unitString) {
	if (unitString == "channels") return 1;
	return 2;
    }

    private.unitString := function(unitNumber) {
	if (unitNumber == 1) return "channels";
	return "xaxis";
    }

    self.setunits := function (units)
    {
	wider private;

	if (private.currUnits != units) {
	    private.currUnits := units;
	    private.converterWidget.setunits (private.unitNumber(units));
	}
	private.logcommand('dish.ops().baseline.setunits',[units=units]);
    }

    # convert a range matrix to a string representation
    private.rangesToString := function(newranges) {
        result := '';
        if (has_field(newranges::,"shape") &&
            len(newranges::shape) == 2 && newranges::shape[2] > 0) {
            newranges::print.precision := 8;
            for (i in 1:newranges::shape[2]) {
                if (i != 1) {
                    result := spaste(result,' ');
                }
                if (newranges[1,i] == newranges[2,i]) {
                    result := spaste(result,as_string(newranges[1,i]));
                } else {
                    result := spaste(result, '[',as_string(newranges[1,i]),':',
                                     as_string(newranges[2,i]),']');
                }
            }
        }
        return result;
    }

    private.rangeNotify := function (clear=F)
    {
	wider private,self;

	if (is_string(clear) && clear == 'disabled') {
	    # JAU: Disabling this (buggy) logic for now.
	    # print 'rangeNotify - inserting empty string into entry';
	    # private.rangeBox.insertentry('');
	    # print 'rangeNotify - entry contents : ', 
	#	private.rangeBox.getentry();
	    return T;
	}

	newRanges:=private.ranges.get_displayed_ranges();
	private.rangeString:=private.rangesToString(newRanges);
	private.rangeBox.insertentry(private.rangeString);
	self.setrange(private.rangeString);
	private.op.setrange(private.ranges.get_displayed_ranges(), 'xaxis', F);
	private.logcommand('dish.ops().baseline.setrange',
			   [newrange=private.ranges.get_displayed_ranges(),
			    units='xaxis', changeunits=F]);
    }

#    private.ranges.set_range_notify_callback(private.rangeNotify, 'Baselining');

    self.settype := function (whichType)
    {
	wider private;
	if (whichType == "polynomial") {
	    private.polynomialTypeButton->state(T);
	    private.activatePolynomial (T);
	    private.activateSinewave (F);
	} else {
	    private.sinewaveTypeButton->state(T);
	    private.activatePolynomial (F);
	    private.activateSinewave (T);
	}
#	private.logcommand('dish.ops().baseline.settype',[whichType=whichType]);
    }

    private.activatePolynomial := function (tOrF)
    {
	private.orderMenuButton->disabled (!tOrF);
    }

    private.activateSinewave := function (tOrF)
    {
	private.sineAmpEntry.disabledAppearance (!tOrF);
	private.sinePeriodEntry.disabledAppearance (!tOrF);
	private.sineX0Entry.disabledAppearance (!tOrF);
	private.maxIterEntry.disabledAppearance (!tOrF);
	private.criteriaEntry.disabledAppearance (!tOrF);
	private.convergedEntry.disabledAppearance (!tOrF);
	private.iterationsEntry.disabledAppearance (!tOrF);
	# the above enables the entries as well as changes the appearance,
	# disable the entries of these last two if they have just been
	# activated.
	if (tOrF) {
	    private.convergedEntry.disabled (T);
	    private.iterationsEntry.disabled (T);
	}
    }

    self.recalculate := function(torf) {
	wider private;
	private.recalculateButton->state(torf);
    }

    self.setaction := function(action) {
	wider private;
	if (action == "show") {
	    private.showButton->state(T);
	} else {
	    private.subtractButton->state(T);
	}
	private.logcommand('dish.ops().baseline.setaction',[action=action]);
    }

    self.setamplitude := function(amplitude) {
	wider private;
	private.sineAmpEntry.setValue(as_string(amplitude));
	private.logcommand('dish.ops().baseline.setamplitude',[amplitude=amplitude]);
    }

    self.getamplitude := function() {
	wider private;
	return as_double(private.sineAmpEntry.getValue());
    }

    self.setperiod := function(period) {
	wider private
	private.sinePeriodEntry.setValue(as_string(period));
	private.logcommand('dish.ops().baseline.setperiod',[period=period]);
    }

    self.getperiod := function() {
	wider private
	return as_double(private.sinePeriodEntry.getValue());
    }

    self.setx0 := function(x0) {
	wider private;
	private.sineX0Entry.setValue(as_string(x0));
	private.logcommand('dish.ops().baseline.setx0',[x0=x0]);
    }

    self.getx0 := function() {
	wider private;
	return as_double(private.sineX0Entry.getValue());
    }

    self.setmaxiter := function(maxiter) {
	wider private;
	private.maxIterEntry.setValue(as_string(as_integer(maxiter)));
	private.logcommand('dish.ops().baseline.setmaxiter',[maxiter=maxiter]);
    }

    self.getmaxiter := function() {
	wider private;
	return as_integer(private.maxIterEntry.getValue());
    }

    self.setcriteria := function(criteria){
	wider private;
	private.criteriaEntry.setValue(as_string(criteria));
	private.logcommand('dish.ops().baseline.setcriteria',[criteria=criteria]);
    }

    self.getcriteria := function() {
	wider private
	return as_double(private.criteriaEntry.getValue());
    }

    self.getranges := function() {
	wider private;
	return private.rangeBox.getentry();
    }

    self.setrange := function(newrangestring) {
	wider private;
	# just as if the user had typed it here and hit return
	k := private.rangeBox.insertentry(newrangestring);
	# update the selection as necessary
	currselected := private.rangeBox.get('selected');
	if (self.getranges() != '' && 
	    (is_fail(currselected) || currselected != self.getranges())) {
	    private.rangeBox.insert(self.getranges(), select=T);
	}
	private.rangeBoxReturned();
	private.logcommand('dish.ops().baseline.setrange',[newrangestring=newrangestring]);
    }

    whenever private.polynomialTypeButton->press, private.sinewaveTypeButton->press do {
	self.settype($value);
	private.op.settype($value, F);
	private.logcommand('dish.ops().baseline.settype',[type=$value]);
    }

    whenever private.showButton->press, private.subtractButton->press do {
	private.op.setaction($value, F);
	private.logcommand('dish.ops().baseline.setaction',[action=$value]);
    }

    whenever private.recalculateButton->press do {
	private.op.recalculate(private.recalculateButton->state(), F);
	private.logcommand('dish.ops().baseline.recalculate',[torf=$value]);
    }

    # self.setorder is called by disbaseline and it needs to update the GUI
    # but not send anything back to dishbaseline
    self.setorder := function(order) {
	# update the GUI
	private.orderMenuButton->text (spaste ('Order ', order));
	private.logcommand('dish.ops().baseline.setorder',[order=order]);
    }

    # private.setorder is called internally and it needs to update the GUI
    # and send the new order back to dishbaseline
    private.setorder := function(order) {
	wider self, private;
	# update the GUI
	self.setorder(order);
	# inform the operation
	private.op.setorder(as_integer(order), F);
    }

    # get the internal state of the range combo box and units
    self.getRangeState := function() {
	wider private;
	state := [=];
	state.rangeHistory := private.rangeBox.get(0,'end');
	state.rangeUnits := private.rangeUnits;
	state.rangeSelection := private.rangeBox.selection();
	state.rangesState := private.ranges.getstate();
	return state;
    }

    # set the internal state of the range combox box, units, et al
    self.setRangeState := function(state) {
	wider private;
	if (is_record(state)) {
	    # default values
	    private.rangeBox.delete('start','end');
	    private.rangeBox.insertentry('');
	    private.rangeBoxCleared();
#	    private.ranges.setstate([=]);
	    if (has_field(state, 'rangeHistory') &&
		is_string(state.rangeHistory) &&
		len(state.rangeHistory) > 0) {
		for (i in 1:len(state.rangeHistory)) {
		    if (strlen(state.rangeHistory[i]) > 0) 
			private.rangeBox.insert(state.rangeHistory[i],(i-1));
		}
	    }
	    if (has_field(state, 'rangeUnits') &&
		is_integer(state.rangeUnits)) {
		private.rangeUnits := state.rangeUnits;
	    }
	    if (has_field(state, 'rangeSelection') &&
		is_integer(state.rangeSelection)) {
		junk := private.rangeBox.select(state.rangeSelection);
	    }
	    if (has_field(state, 'rangesState') &&
		is_record(state.rangesState)) {
#		private.ranges.setstate(state.rangesState);
	    }
	}
    }

    self.setrms := function(rms) {
	wider private;
	if (is_unset(rms)) {
	    private.rmsEntry.setValue('');
	} else {
	    private.rmsEntry.setValue(as_string(rms));
	}
    }

    self.setconverged := function(converged) {
	wider private;
	if (is_unset(converged)) {
	    private.convergedEntry.setValue(F);
	} else {
	    private.convergedEntry.setValue(as_string(converged));
	}
    }

    self.setiterations := function(iterations) {
	wider private;
	if (is_unset(iterations)) {
	    private.iterationsEntry.setValue(0);
	} else {
	    private.iterationsEntry.setValue(as_string(iterations));
	}
    }

    self.debug := function() {wider private; return private;}

    junk := widgetset.tk_release();

    # self is returned automatically, it should NOT be explicitly returned here
}
