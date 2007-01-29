# dishselectgui.g: a GUI for the dish select operation.
#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000,2001,2002
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
#    $Id: dishselectgui.g,v 19.1 2004/08/25 01:11:25 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include	'widgetserver.g';
#include 'dish_util.g';
include 'sditerator.g';

const dishselectgui := subsequence(parent, itsop, itsdish, widgetset=dws) {

    widgetset.tk_hold();

    private := [=];

    private.op := itsop;
    private.logcommand := itsdish.logcommand;
    private.sdutil := sdutil();
    private.dish := itsdish;
    private.pendingCWSname := F;

    private.outerFrame :=
	widgetset.frame(parent, side='top', relief='ridge', expand='x');
    private.labelFrame := 
	widgetset.frame(private.outerFrame, expand='x');
    private.mainLabel := 
 	widgetset.label(private.labelFrame, 'Selection Criteria');

    dataSourceTitle := '      Working Set';
    objectTitle     := '      Object Name';
    recordTitle     := '           Record';
    scanTitle       := '             Scan';
    dateTitle       := '             Date';
    lstTitle        := 'UTC(s since date)';
    freqTitle       := '   Rest Freq.(Hz)';
    velocityTitle   := '         Velocity';

    private.currwsname := '';
    private.mustUpdateComboboxes := T;

    private.cbcallback := function(action) {
	wider private;
	# the 'INSERT' action is ignored here, we don't care
	if (action == 'RENAME') {
	    # just get whatever the current entry contents are
	    private.currwsname := private.wscb.getentry();
	} else {
	    if (action == 'DELETE') {
		private.wscbSelectionHandler();
	    }
	}
    }


    private.wscb :=  itsdish.rm().wscombobox(private.outerFrame,
					     dataSourceTitle,
					     private.cbcallback,
					     mode='rw',
					     help=paste('The working set in use by this operation.',
							'Use File/Open to add an existing working set.'));
    whenever private.wscb.agent()->select do {
	private.wscbSelectionHandler();
    }

    private.objectSelector := 
	dishSelectionCombobox (private.outerFrame, objectTitle,
			       canclearpopup=T, widgetset=widgetset,itsdish=private.dish);
    private.recordSelector := 
	dishSelectionCombobox (private.outerFrame, recordTitle,
			       collapseDisplayAllRanges=T,
			       canclearpopup=T, widgetset=widgetset,
          help=paste('Use 1,4 to select records 1 and 4.','Use [1,4] to select records 1 through 4.'),itsdish=private.dish);
    private.scanSelector := 
	dishSelectionCombobox (private.outerFrame, scanTitle,
			       collapseDisplayAllRanges = T,
			       canclearpopup=T, widgetset=widgetset,
     	  help=paste('Use 10,100 to select scans 10 and 100.','Use [10,100] to select scans 10 through 100.'),itsdish=private.dish);
    private.dateSelector := 
	dishSelectionCombobox (private.outerFrame, dateTitle,
			       canclearpopup=T, widgetset=widgetset,itsdish=private.dish);
    private.lstSelector := 
	dishSelectionCombobox (private.outerFrame, lstTitle,
			       canclearpopup=T, widgetset=widgetset,itsdish=private.dish);
    private.restFrequencySelector := 
	dishSelectionCombobox (private.outerFrame, freqTitle,
			       canclearpopup=T, widgetset=widgetset,
   	  help=paste('Rest Frequency requires a range. Use [1.102150602e+11,1.102160602e+11] to set a range'),itsdish=private.dish);
    private.bottomFrame := 
	widgetset.frame(private.outerFrame, expand='x', borderwidth=0,
			side='left');
    private.leftPad :=
	widgetset.frame(private.bottomFrame, expand='x', width=1, borderwidth=0);
    private.applyFrame :=
	widgetset.frame(private.bottomFrame, side='right', borderwidth=0,expand='none');
    private.applyButton := 
	widgetset.button(private.applyFrame, 'Apply', type='action');
    private.applyButton.shorthelp := 'Invoke the generic apply';
    private.rightPad :=
	widgetset.frame(private.bottomFrame, expand='x', width=1, borderwidth=0);
    private.dismissButton := 
	widgetset.button(private.bottomFrame, 'Dismiss', type='dismiss');
    private.dismissButton.shorthelp := 'Dismiss this operation GUI';

    whenever private.applyButton->press do {
	# invoke the apply function in the operation
	r := private.op.apply();
        if (is_fail(r)) {
            dl.log(message=paste('dish selection failed',r::message),
		   priority='SEVERE');
	    itsdish.message('Selection failed - see log messages for details');
	} else {
	    private.logcommand('dish.ops().select.apply',[=]);
        }
    }

    whenever private.dismissButton->press do {
	self->dismiss(private.op.opmenuname());
    }

    private.objectSelector.disabled (T);
    private.recordSelector.disabled (T);
    private.scanSelector.disabled (T);
    private.dateSelector.disabled (T);
    private.lstSelector.disabled (T);
    private.restFrequencySelector.disabled (T);

    private.clearComboboxes := function() {
	wider private;
	private.objectSelector.clear();
	private.recordSelector.clear();
	private.scanSelector.clear();
	private.dateSelector.clear();
	private.lstSelector.clear();
	private.restFrequencySelector.clear();
    }


    self.updateComboboxes := function (workingSet) {
	wider private;
	if (private.mustUpdateComboboxes  && is_sditerator(workingSet)) {
	    # the selection vector for fields used here
	    vecTemplate := [data=[desc=[restfrequency=0.0]],header=[date="",ut=0.0,source_name="",scan_number=0]];
#	Note: getvectors does NOT retain the measure quality
#	of a field-it returns only the value!! -JPM 05OCT00
	    vecValues := workingSet.getvectors (vecTemplate);
	    
	    objectValues := unique (vecValues.header.source_name);
	    private.objectSelector.setassocvalues(objectValues);
	    
	    recordValues := 1:workingSet.length ();
	    private.recordSelector.setassocvalues(recordValues);
	    
	    scanValues := unique (vecValues.header.scan_number);
	    private.scanSelector.setassocvalues(scanValues);
	    
	    dateValues := unique(vecValues.header.date);
	    private.dateSelector.setassocvalues(dateValues);
	    
	    utValues:= unique(vecValues.header.ut);
	    private.lstSelector.setassocvalues(utValues);
	    
	    freqValues := unique(vecValues.data.desc.restfrequency);
	    private.restFrequencySelector.setassocvalues (freqValues);
	    
	    private.mustUpdateComboboxes := F;
	}
    }# updateComboboxes

    private.wscbSelectionHandler := function() {
	wider private;
	private.dish.busy(T);
	ent := private.wscb.getentry();
	if (ent != private.currwsname) {
	    private.clearComboboxes();
	    private.currwsname := ent;
	    ws := symbol_value(ent);
# remove auto update when get new ws - takes too long 11/28/00 -- JPM
#	    if (is_sditerator(ws)) {
#		private.updateComboboxes(ws);
#	    }
	    private.mustUpdateComboboxes := T;
	    # this may operate before dish is fully available, guard for it
	    if (has_field(private.dish,'message'))
		private.dish.message ('new working set is ready');
	}
	private.dish.busy(F);
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

    self.cws := function() {
	wider private;
	return private.wscb.getentry();
    }

    self.getcriteria := function() {
	wider private;
	criteria := [=];
	objectCriteria := private.objectSelector.get();
	recordCriteria :=  private.recordSelector.get();
	scanCriteria :=  private.scanSelector.get();
	dateCriteria :=  private.dateSelector.get();
	LSTCriteria :=  private.lstSelector.get();
	frequencyCriteria :=  private.restFrequencySelector.get();
	
	if (len (objectCriteria) > 0) {
	    criteria.header.source_name := private.sdutil.parsestringlist(objectCriteria);
	    # watch for fails in the above
	    if (is_fail(criteria.header.source_name)) {
		fail('There is a syntax error in the Object Name selection entry');
	    }
	}
	if (len (recordCriteria) > 0) {
	    criteria.row := private.sdutil.parseranges(recordCriteria);
	}
	if (len (scanCriteria) > 0) {
	    criteria.header.scan_number := private.sdutil.parseranges(scanCriteria);
	};
	if (len (dateCriteria) > 0) {
	    criteria.header.date := private.sdutil.parsestringlist(dateCriteria);
	}
	if (len (LSTCriteria) > 0) {
	    criteria.header.ut := private.sdutil.parseranges(LSTCriteria);
	}
	if (len (frequencyCriteria) > 0) {
            criteria.data:=[=];
            criteria.data.desc:=[=];
	    criteria.data.desc.restfrequency :=
		(as_double(private.sdutil.parseranges(frequencyCriteria)));
	}# if frequencyCriteria exist
	return criteria;
    }

    self.setws := function(wsname, ws) {
	wider private;
	if (!is_sditerator(ws)) {
		print 'FAIL: Unrecognized file used'
		return F;
	};
	# update the ws combobox by selecting this new one, which will
	# always be the first entry in the combobox
#	private.wscb.select(0);
        knownws := private.wscb.get('start','end');
        mask := knownws == wsname;
        if (any(mask)) {
           which := ind(mask)[mask] - 1;
           if (len(which) == 1) {
              private.wscb.select(which);
           }
        } 
	private.currwsname := wsname;
	private.clearComboboxes();
#	self.updateComboboxes(ws);
	private.mustUpdateComboboxes := T;
	# this may operate before dish is fully available, guard for it
	if (has_field(private.dish,'message'))
	    private.dish.message ('new working set is ready');
    }

    self.getstate := function() {
	wider private;
	state := [=];

	state.cwsname := private.wscb.getentry();

	state.source_name := private.objectSelector.getstate();
	state.record := private.recordSelector.getstate();
	state.scan := private.scanSelector.getstate();
	state.date := private.dateSelector.getstate();
	state.lst := private.lstSelector.getstate();
	state.restfreq := private.restFrequencySelector.getstate();
	
	return state;
    }

    self.setstate := function(state) {
	wider private;
	if (is_record(state)) {
	    # default state
	    private.wscb.insertentry('');
	    private.objectSelector.setstate([=]);
	    private.recordSelector.setstate([=]);
	    private.scanSelector.setstate([=]);
	    private.dateSelector.setstate([=]);
	    private.lstSelector.setstate([=]);
	    private.restFrequencySelector.setstate([=]);
	    if (has_field(state,'cwsname')  &&
		is_string(state.cwsname) && len(state.cwsname) == 1) {
		# verify that this ws is available in the combobox
		knownws := private.wscb.get('start','end');
		mask := knownws == state.cwsname;
		if (any(mask)) {
		    which := ind(mask)[mask] - 1;
		    if (len(which) == 1) {
			private.wscb.select(which);
		    }
		} else {
		    # remember this - dish sets the op states first so
		    # this WS generally won't be available yet, after the
		    # rm state is set dish will request that this be set.
		    private.pendingCWSname := state.cwsname;
		}
	    }
	    if (has_field(state,'source_name'))
		private.objectSelector.setstate(state.source_name);
	    if (has_field(state,'record'))
		private.recordSelector.setstate(state.record);
	    if (has_field(state,'scan'))
		private.scanSelector.setstate(state.scan);
	    if (has_field(state,'date'))
		private.dateSelector.setstate(state.date);
	    if (has_field(state,'lst'))
		private.lstSelector.setstate(state.lst);
	    if (has_field(state,'restfreq'))
		private.restFrequencySelector.setstate(state.restfreq);
	}
    }

    self.setPendingCWS := function() {
	wider private;
	if (is_string(private.pendingCWSname)) {
	    # verify that this ws is available in the combobox
	    knownws := private.wscb.get('start','end');
	    mask := knownws == private.pendingCWSname;
	    if (any(mask)) {
		which := ind(mask)[mask] - 1;
		if (len(which) == 1) {
		    private.wscb.select(which);
		}
	    }
	    private.pendingCWSname := F;
	}
    }

    self.debug := function() {wider private; return private;}

    junk := widgetset.tk_release();
}
