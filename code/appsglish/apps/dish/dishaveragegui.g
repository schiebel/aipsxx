# dishaveragegui.g: the GUI for the dish average operation.
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
#    $Id: dishaveragegui.g,v 19.1 2004/08/25 01:09:14 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include	'widgetserver.g';

const dishaveragegui := subsequence(parent, itsop, logcommand, widgetset=dws) 
{
    widgetset.tk_hold();

    private := [=];

    private.op := itsop;
    private.logcommand := logcommand;

    private.outerFrame :=
	widgetset.frame(parent, side='top', relief='ridge');
    private.labelFrame := 
	widgetset.frame(private.outerFrame, expand='x');
    private.mainLabel := 
	widgetset.label(private.labelFrame, 'Averaging');

    private.mainFrame := widgetset.frame (private.outerFrame, side='left');

    private.middleFrame := widgetset.frame (private.mainFrame, side='top');

    private.rightFrame := widgetset.frame(private.mainFrame, side='top',
					  expand='y');
    private.topPad := widgetset.frame(private.rightFrame, expand='y',
				      height=1);
    private.applyButton := widgetset.button (private.rightFrame, text='Apply', 
					     height=3,type='action');
    popuphelp(private.applyButton,
	      hlp='Average the working set',
	      txt='Uses whatever the current working set in the selection operation is.  Even if no further selection is done.',
	      combi=T);
    private.bottomPad := widgetset.frame(private.rightFrame, expand='y',
					 height=1, borderwidth=0);
    private.dismissButton := 
	widgetset.button(private.rightFrame, text='Dismiss', type='dismiss');
    popuphelp(private.dismissButton,
	      hlp='Dismiss this operation GUI.', 
	      txt='This is equivalent to using the Operations menu to turn off this GUI.',
	      combi=T);

    private.verticalPadding := 
	widgetset.frame(private.outerFrame,height=15, width=1,expand='none');

    private.alignmentFrame := 
	widgetset.frame (private.middleFrame, side='left');
    private.restFreqFrame := 
	widgetset.frame(private.middleFrame, side='left');
    private.weightingFrame := 
	widgetset.frame (private.middleFrame, side='left');

    private.alignmentLabel := 
	widgetset.label (private.alignmentFrame, 'Alignment:');
    private.noAlignmentButton := 
	widgetset.button (private.alignmentFrame, 'None', value='NONE',
			  type='radio', width=12, disabled=F,relief='flat');
    popuphelp(private.noAlignmentButton,hlp='No alignment');
    private.noAlignmentButton->state(T);
    private.velocityButton := 
	widgetset.button (private.alignmentFrame, 'By Velocity ', 
			  value='VELOCITY', type='radio', width=12, 
			  disabled=F,relief='flat');
    popuphelp(private.velocityButton,
	      hlp='Align by velocity',
	      txt=paste('Only channels having the same velocity with be averaged together.',
			'It must be possible to convert the axis to velocity if it is not already a velocity axis'),
	      combi=T);
    private.xaxisButton :=
	widgetset.button (private.alignmentFrame, 'By X-Axis', value='XAXIS',
			  type='radio', width=12, disabled=F,relief='flat');
    popuphelp(private.xaxisButton,
	      hlp='Align by x-axis',
	      txt='Only channels having the same x-axis value will be averaged together.',
	      combi=T);
    private.restShiftLabel := 
	widgetset.label (private.restFreqFrame,  'Rest Frequency:');
    private.restShiftButton := 
	widgetset.button (private.restFreqFrame, 
			  'Shift to match first in average',
			  type='check', disabled=T,relief='flat');
    popuphelp(private.restShiftButton,
	      hlp='Adjust the rest frequency - velocity alignment only.',
	      txt=paste('The rest frequency is first shifted to match that of the first in the average',
			'and then the velocity is recalculated before alignment.'),
	      combi=T);
    private.restShiftButton->state(F);

    private.weightingLabel := 
	widgetset.label (private.weightingFrame, 'Weighting:');
    private.noWeightingButton := 
	widgetset.button (private.weightingFrame, 'None ', 
			  value='NONE', type='radio', width=12,relief='flat');
    popuphelp(private.noWeightingButton,
	      hlp='Equal weights',
	      txt='All data values have equal weight in the average');
    private.noWeightingButton->state (T);

    private.tsysWeightingButton := 
	widgetset.button (private.weightingFrame, 'Tsys & Time ', 
			  value = 'TSYS', type='radio',width=12, 
			  disabled=F,relief='flat');
    popuphelp(private.tsysWeightingButton,
	      hlp='Theoretical RMS weighting',
	      txt='The weight for all channels in each spectra is the same value.',
	      combi=T);

    private.rmsWeightingButton := 
	widgetset.button (private.weightingFrame, 'RMS  ', value='RMS',
			  type='radio', width=12, disabled=F,relief='flat');
    popuphelp(private.rmsWeightingButton,
	      hlp='Calculated RMS weighting',
	      txt='The RMS across the entire spectra is used.',
	      combi=T);
    private.selectionFrame := 
	widgetset.frame(private.middleFrame, side='left',expand='x');
    private.selectionLabel := 
	widgetset.label(private.selectionFrame,'Selection:');
    private.selectionButton := 
	widgetset.button(private.selectionFrame, 
			 'Make selection before averaging',
			 type='check',relief='flat');
    popuphelp(private.selectionButton,
	      hlp='Select before averaging?',
	      txt=paste('When pressed, the selection currently set up in the selection operation',
			'is made and the average is done on the result.'),
	      combi=T);
    private.selectionButton->state(T);

    whenever private.applyButton->press do {
	private.op.apply();
	private.logcommand('dish.ops().average.apply',[=]);
    }

    whenever private.dismissButton->press do {
	self->dismiss(private.op.opmenuname());
    }

    whenever private.noAlignmentButton->press, private.velocityButton->press,
	private.xaxisButton->press do {
	    private.op.setalignment($value);
	    private.logcommand('dish.ops().average.setalignment',
			       [alignment=$value]);
	}

    whenever private.noWeightingButton->press, 
	private.tsysWeightingButton->press, private.rmsWeightingButton->press do {
	    private.op.setweighting($value);
	    private.logcommand('dish.ops().average.setweighting',
			       [weighting=$value]);
	}

    whenever private.restShiftButton->press do {
	state := private.restShiftButton->state();
	private.op.dorestshift(state);
	private.logcommand('dish.ops().average.dorestshift',
			   [dorestshift=state]);
    }
 
    whenever private.selectionButton->press do {
	state := private.selectionButton->state();
	private.op.doselection(state);
	private.logcommand('dish.ops().average.doselection',
			   [doselection=state]);
    }

    self.setweighting := function(weighting) {
	wider private;
	# assume all sanity checks have already happened
	if (weighting == 'TSYS') {
	    private.tsysWeightingButton->state(T);
	} else {
	    if (weighting == 'RMS') {
		private.rmsWeightingButton->state(T);
	    } else {
		private.noWeightingButton->state(T);
	    }
	}
	return T;
    }

    self.setalignment := function(alignment) {
	wider private;
	# assumes all sanity checks have already happened
	if (alignment == 'VELOCITY') {
	    private.velocityButton->state(T);
	    private.allowRestShift(T);
	} else {
	    private.allowRestShift(F);
	    if (alignment == 'XAXIS') {
		private.xaxisButton->state(T);
	    } else {
		private.noAlignmentButton->state(T);
	    }
	}
    }

    self.dorestshift := function(dorestshift) {
	wider private;
	private.restShiftButton->state(dorestshift);
    }

    self.doselection := function(doselection) {
	wider private;
	private.selectionButton->state(doselection);
    }

    private.allowRestShift := function(tOrF) {
	wider private;
	private.restShiftButton->disabled(!tOrF);
    }
	
    self.outerframe := function() {
	wider private;
	return private.outerFrame;
    }

    # a done function which makes this GUI unusable
    self.done := function() {
	wider private;
	val private.outerFrame := F;
	val private := F;
    }
    junk := widgetset.tk_release();
}
