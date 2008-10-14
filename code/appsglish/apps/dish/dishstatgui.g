# dishstatgui.g: dish's spectrum statistics gui
#------------------------------------------------------------------------------
#   Copyright (C) 1996-1999,2000,2001,2002
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
#    $Id: dishstatgui.g,v 19.1 2004/08/25 01:11:45 cvsmgr Exp $
#
#------------------------------------------------------------------------------

pragma include once;

include "dish_util.g";
#include "dish_sranges.g";
include 'popuphelp.g';

const dishstatgui := subsequence (parent, itsdish, logcommand, widgetset=dws)
{
    # a subsequence returns an agent named "self"
    # we will attach the public portion of this closure to self
    # Self will emit events, e.g. a 'dismiss' event will be
    # emitted when the user hits the dismiss button.

    private := [=];

#    private.CHANNELUNITS := 1;
#    private.AXISUNITS := 2;
#    private.units := [=];
#    private.units[private.CHANNELUNITS] := 'Channels';
#    private.units[private.AXISUNITS] := 'X-Axis Units';
#    private.conversionCallbacks := [=];

    # the 
    private.op := itsdish.ops().statistics;
    private.logcommand := itsdish.logcommand;
    private.plotter:=itsdish.plotter;
    private.rm := itsdish.rm();

#    private.rangeUnits := F;

    private.updatePlotterRanges := function(rangeString) {
#    private.updatePlotterRanges := function(rangeString, units) {
#	if (units != private.AXISUNITS) {
#	    nominee := ref private.rm.getlastviewed().value;
#	    if (is_sdrecord(nominee)) {
#		rangeString:=private.op.rangeStringToUnitString(rangeString,
#						      nominee.data.desc,T);
#	    }
#	}
	rangeMatrix := private.op.rangeStringToMatrix(rangeString);
	return T;
    }

    private.rangeBoxReturned := function ()
    {
	wider private;
	# first set the units
	# we are adding at the head
#	if (is_boolean(private.rangeUnits)) {
#	    private.rangeUnits := private.currUnits;
#	} else {
#	    curlen := len(private.rangeUnits);
#	    private.rangeUnits[curlen+1] := private.currUnits;
#	    private.rangeUnits[2:(curlen+1)] := private.rangeUnits[1:curlen];
#	    private.rangeUnits[1] := private.currUnits;
#	}
	# then get the value of the range box
	itsvalue := private.rangeBox.getentry();
	# and update the plotter with it
	# the combobox has been updated internally when the return happened
#	return private.updatePlotterRanges(private.rangeBox.getentry(),
#					   private.currUnits);
	return private.updatePlotterRanges(private.rangeBox.getentry());
    }

    private.rangeBoxSelected := function (eventvalue)
    {
	wider private;
#	itsunits := private.rangeUnits[eventvalue+1];
	itsvalue := private.rangeBox.get(eventvalue);
	# Needed to keep range-setting lists in sync.
	# Must watch units changes and send to plotter in X-Axis units!
#	if (itsunits != private.currUnits) {
#	    private.setUnits (itsunits);
#	}
#	return private.updatePlotterRanges(itsvalue, itsunits);
	return private.updatePlotterRanges(itsvalue);
    }

    private.rangeBoxCleared := function() 
    {
	wider private;
#	private.rangeUnits := F;
        if (is_sdrecord(private.rm.getlastviewed().value)) {
           private.plotter.plotrec(private.rm.getlastviewed().value);
        };
    }
    private.intBoxCleared := function()
    {
	wider private;
	private.scan.setValue('');
	private.startint.setValue('');
	private.stopint.setValue('');
	private.atpeak.setValue('');
	private.centroid.setValue('');
	private.rms.setValue('');
	private.peak.setValue('');
	private.area.setValue('');
	private.min.setValue('');
	private.plotter.putranges('');
    }


    tk_hold();
    
    # outerFrame - top to bottom

    private.outerFrame := dws.frame(parent,side='top',relief='ridge');
    private.labelFrame := dws.frame (private.outerFrame,expand='x');
    private.mainLabel  := label (private.labelFrame,'Spectrum Statistics');
    # dialogFrame - left to right
    private.mainFrame:=dws.frame(private.outerFrame,side='right');
    private.actionf :=dws.frame(private.mainFrame);
    private.statsright:=dws.frame(private.mainFrame);
    private.statsleft:=dws.frame(private.mainFrame);
    #
    #
    private.acttop  :=dws.frame(private.actionf,side='left');
    private.actsec  :=dws.frame(private.actionf,side='left');
    private.actthi  :=dws.frame(private.actionf,side='left',expand='both');
    private.actbot  :=dws.frame(private.actionf,side='left');
    private.apply   :=dws.button(private.acttop,'   Apply     ',height=1,type='action',borderwidth=1);
    private.copy   := dws.button(private.actsec,'Copy to ClipB',type='action',borderwidth=1);
    private.print  := dws.button(private.actthi,'Print to File',type='action',borderwidth=1);
    private.plotranges:=dws.button(private.actbot,'Select Ranges',type='check',relief='flat');
    #
    # temp location for this!
    #
    whenever private.plotranges->press do {
	wider private;
	rangestate:=private.plotranges->state();
	ok:=private.plotter.setranges(private.rangeBox,rangestate);
    };

    whenever private.apply->press do {
	itsdish.busy(T);
	therec:=[=];
	therec:=private.doStat();
	ok:=self.setvalues(therec);
	myrangestring:=private.rangeBox.getentry()
#	myrangestring:=spaste("'",myrangestring,"'");
	itsdish.busy(F);
    }
    whenever private.print->press do 
    {
	if (!has_field(private,'printframe')) {
	    private.printframe:=dws.frame(side='top',relief='ridge');
	    private.printlf:=dws.frame(private.printframe,expand='x',borderwidth=0);
	    private.printml :=dws.label(private.printlf,'Write stats to file');
	    private.printcombo:=dws.combobox(private.printframe,'Disk File: ',
					     autoinsertorder='head',canclearpopup=T,
					     help='Write stats to file');
	    private.printbf:=dws.frame(private.printframe,expand='x',side='left');
	    private.writef:=dws.frame(private.printbf,borderwidth=2,expand='none');
	    private.writeb:=dws.button(private.writef,text='Write',type='action');
	    private.disb:=dws.button(private.printbf,'Dismiss',type='dismiss');
	    whenever private.writeb->press do {
		diskfile:=paste(private.printcombo.getentry());
		fp:=open([">>",diskfile]);
		fprintf(fp,'%s \n','  scan  start          stop           atPeak         Centroid');
		scan:=as_float(private.scan.getValue());
		start:=as_double(private.startint.getValue());
		stop :=as_double(private.stopint.getValue());
		vpeak:=as_double(private.atpeak.getValue());
		centroid:=as_double(private.centroid.getValue());
		min:=as_double(private.min.getValue());
		area :=as_double(private.area.getValue());
		peak :=as_double(private.peak.getValue());
		rms  :=as_double(private.rms.getValue());
		fprintf(fp,'%6.0f %14.7e %14.7e %14.7e %14.7e \n',scan,start,stop,vpeak,centroid);
		fprintf(fp,'%s \n','        Peak           Area           Mininum        rms');
		dummy:='      ';
		fprintf(fp,'%s %14.7e %14.7e %14.7e %14.7e \n',dummy,peak,area,min,rms);
		private.printframe->unmap();
	    }
    	    whenever private.disb->press do {
		private.printframe->unmap();
	    }
	} else { # it already existed...bring it back
	    private.printframe->map();
	}
    }
    whenever private.copy->press do {
	wider private;
	if (has_field(private,'myresults')) {
	    dcb.copy(private.myresults);
	} else {
	    print 'no values available -- press Go to update';
	}
    }

    #
    # stats right frame
    #
    #
    private.toprowf:=dws.frame(private.statsright,side='left',borderwidth=0,expand='x');
    private.secrowf:=dws.frame(private.statsright,side='left',borderwidth=0,expand='x');
    private.thirowf:=dws.frame(private.statsright,side='left',borderwidth=0,expand='x');
    private.fourowf:=dws.frame(private.statsright,side='left',borderwidth=0,expand='x');
    private.fifrowf:=dws.frame(private.statsright,side='left',borderwidth=0,expand='x');
    #  private.botrowf:=dws.frame(private.statsright,side='left',borderwidth=0,expand='x');
    #
    # need labeled entrys -- don't find this in the dws set
    dummy:=label(private.toprowf,'');
    private.startint:=labeledEntry(private.toprowf,'Start','',entryWidth=14);
    private.stopint :=labeledEntry(private.secrowf,'  Stop','',entryWidth=15);
    private.peak:=labeledEntry(private.thirowf,'  Peak','',entryWidth=15);
    private.area:=labeledEntry(private.fourowf,'  Area','',entryWidth=15);
    private.min := labeledEntry(private.fifrowf,'   Min','',entryWidth=15);
    #
    
    private.ltoprowf:=dws.frame(private.statsleft,side='left',borderwidth=0,expand='x');
    private.lsecrowf:=dws.frame(private.statsleft,side='left',borderwidth=0,expand='x');
    private.lthirowf:=dws.frame(private.statsleft,side='left',borderwidth=0,expand='x');
    private.lfourowf:=dws.frame(private.statsleft,side='left',borderwidth=0,expand='x');
    private.lfifrowf:=dws.frame(private.statsleft,side='left',borderwidth=0,expand='x');
    #  private.lbotrowf:=dws.frame(private.statsleft,side='left',borderwidth=0,expand='x');
    #
    private.scan:=labeledEntry(private.ltoprowf,'   Scan ','',entryWidth=15);
    dummy2:=label(private.lsecrowf,'');
    private.atpeak  :=labeledEntry(private.lthirowf,' at Peak','',entryWidth=15);
    private.centroid:=labeledEntry(private.lfourowf,'Centroid','',entryWidth=15);
    private.rms     :=labeledEntry(private.lfifrowf,'     rms','',entryWidth=15);
    #
    #
    # Ranges frame
    #
    private.rangeFrame := dws.frame (private.outerFrame, borderwidth=0, side='left');
    private.rangeEntryFrame:=dws.frame(private.rangeFrame, borderwidth=0, side='top',
				       expand='x');
    private.rangeLabel:=label(private.rangeEntryFrame,text='Range used in stats:');
    private.rangeBox := combobox(private.rangeEntryFrame,'',autoinsertorder='head',
				 hscrollbar='always',canclearpopup=T,entrywidth=80);
    #
    tk_release();
    #
    # This is what is enabled
    #
    private.startint.disabledAppearance(F);
    private.stopint.disabledAppearance(F); 
    #
    ###
    #
    # actionFrame - top to bottom
    #    private.actionFrame := dws.frame (private.actionf, side='top', expand='both');

    # end actionFrame
    uniquelastcombobox(private.rangeBox, T);
    whenever private.rangeBox.agent()->select do {
	private.rangeBoxSelected($value);
    }
    whenever private.rangeBox.agent()->return do {
	private.rangeBoxReturned();
    }
    whenever private.rangeBox.agent()->clear do {
	private.rangeBoxCleared();
	private.intBoxCleared();
    }
    private.bottomFrame := dws.frame(private.outerFrame, side='right', borderwidth=0, 
				 expand='x');
    private.dismissFrame := dws.frame(private.bottomFrame, expand='none');
    private.dismissButton := dws.button(private.dismissFrame, 'Dismiss',type='dismiss');
    popuphelp(private.dismissButton,
	      hlp='Dismiss this operation GUI',
	      txt='This is equivalent to using the Operations menu to turn off this GUI.',
	      combi=T);
    # outerPad to keep everything above this in place
    private.outerPad := dws.frame (private.outerFrame, height=1, width=1, expand='both');
    # end outerPad

    whenever private.dismissButton->press do {
	self->dismiss(private.op.opmenuname());
    }

    private.orderButtons := [=];

#    private.currUnits := -1;

#    private.setUnits := function (whichUnits)
#    {
#	wider private;
#
#	if (private.currUnits != whichUnits) {
#	}
#    }

    private.add_to_rangebox := function (range)
    {
	private.rangeBox.insert(range, select=T);
	private.rangeBoxReturned();
    }
    private.add_to_mine:=function(range)
    {
	stringie:=split(range,':');
	mystart:=split(stringie[1],'[');
	mystop:=split(stringie[2],']');
	private.startint.setValue(mystart);
	private.stopint.setValue(mystop);
    }

    private.add_to_range_entry_box := function (range)
    {
	private.rangeBox.insertentry(range);
    }

    private.setAction := function (whichAction)
    {
	wider private;

	private.currAction := whichAction;
    }

    private.append := function (ref list, thing)
    {
	# appends thing to list
	for (i in 1:len (thing)) {
	    list[len (list)+i] := thing;
	}
    }
    private.doStat := function() 
    {
       wider private;
       lv := ref private.rm.getlastviewed();
       nominee := ref lv.value;
       nname := lv.name;
       if (is_boolean (nominee)) {
            dish.message ('Error!  An SDRecord has not yet been viewed');
       } else if (is_sditerator(nominee)) {
            # this can't happen at this point
            dish.message ('Cant generate stats on a working set');
       } else if (is_sdrecord (nominee)) {
            ranges := private.rangeBox.getentry();
            # and make sure we remember it, if it isn't currently selected
            currselected := private.rangeBox.get('selected');
            if (ranges !='' && (is_fail(currselected)||currselected != ranges)){
                    private.rangeBox.insert(ranges, select=T);
                    private.rangeBoxReturned();
            }
            type := "";
            rmsoffit := F;
            guess := [=];

#            if (T) {
	     private.myresults:=[=];
             private.myresults := private.op.apply (nominee);
	     private.myresults:=private.myresults.pol_1;
	     private.peak.setValue(as_string(private.myresults.peak));
	     private.area.setValue(as_string(private.myresults.area));
	     private.rms.setValue(as_string(private.myresults.rms));
	     private.centroid.setValue(as_string(private.myresults.centroid));
	     private.atpeak.setValue(as_string(private.myresults.vpeak));
	     private.min.setValue(as_string(private.myresults.min));
	     private.scan.setValue(as_string(private.myresults.scan));
	     private.startint.setValue(as_string(private.myresults.startint));
	     private.stopint.setValue(as_string(private.myresults.stopint));
      }
      return private.myresults;
    } # END doStat

    self.apply := function ()
    {
	wider private;
        private.myresults:=[=];
        private.myresults := private.op.apply (nominee);
        private.peak.setValue(as_string(private.myresults.peak));
        private.area.setValue(as_string(private.myresults.area));
        private.rms.setValue(as_string(private.myresults.rms));
        private.centroid.setValue(as_string(private.myresults.centroid));
        private.atpeak.setValue(as_string(private.myresults.vpeak));
        private.min.setValue(as_string(private.myresults.min));
        private.scan.setValue(as_string(private.myresults.scan));
        private.startint.setValue(as_string(private.myresults.startint));
        private.stopint.setValue(as_string(private.myresults.stopint));
    }

     self.done := function ()
    {
	self->done(T);
    }

    self.outerframe := function ()
    {
	wider private;

	return private.outerFrame;
    }

    self.getstate := function()
    {
	wider private;
	state := [=];
	state.scan:=private.scan.getValue();
	state.start:=private.startint.getValue();
	state.stop :=private.stopint.getValue();
	state.vpeak:=private.atpeak.getValue();
	state.centroid:=private.centroid.getValue();
	state.min:=private.min.getValue();
	state.area :=private.area.getValue();
	state.peak :=private.peak.getValue();
	state.rms  :=private.rms.getValue();
#	state.units:=private.currUnits;
	state.rangeHistory:=private.rangeBox.get(0,'end');
	state.rangeEntry:=private.rangeBox.getentry();
	return state;
    }

#    self.xunits := function() {
#	wider private;
#	if (private.currUnits==1) {
#		return F;
#	} else {
#		return T;
#	}
#    }

    self.myranges:=function() {
	wider private;
	return private.rangeBox.getentry();
    }

    self.setranges := function(ranges){
	wider private;
	ok:=private.add_to_range_entry_box(ranges);
	ok:=private.add_to_mine(ranges);
#	ok:=private.updatePlotterRanges(ranges,private.currUnits);
	ok:=private.updatePlotterRanges(ranges);
	return T;
    }

    self.setvalues := function(therec) {
	wider private;
        private.peak.setValue(as_string(therec.peak));
        private.area.setValue(as_string(therec.area));
        private.rms.setValue(as_string(therec.rms));
        private.centroid.setValue(as_string(therec.centroid));
        private.atpeak.setValue(as_string(therec.vpeak));
        private.min.setValue(as_string(therec.min));
        private.scan.setValue(as_string(therec.scan));
    }

#    self.setunits := function(units) {
#	wider private;
#	if (units==T) {
#	   private.converterWidget.setunits(2);
#	   private.setUnits(2);
#	} else {
#	   private.converterWidget.setunits(1);
#	   private.setUnits(1);
#	}
#	return T;
#    }

    self.setstate := function(state)
    {
	wider private;
	result := F;
	if (is_record(state)) {
	    # default values
	    private.rangeBox.delete('start','end');
	    private.rangeBox.insertentry('');
	    private.rangeBoxCleared();
	    # and now actually set these
#	    if (has_field(state,'units') &&
#		is_integer(state.units) &&
#		state.units >= 1 && 
#		state.units <= len(private.units)) {
#		private.currUnits := state.units;
#	    }
	    if (has_field(state,'rangeHistory') &&
		is_string(state.rangeHistory) &&
		len(state.rangeHistory) > 0) {
		for (i in 1:len(state.rangeHistory)) {
		    if (strlen(state.rangeHistory[i]) > 0)
			private.rangeBox.insert(state.rangeHistory[i],(i-1));
		}
	    }
#	    if (has_field(state,'rangeUnits') &&
#		is_integer(state.rangeUnits)) {
#		private.rangeUnits := state.rangeUnits;
#	    }
	    if (has_field(state,'rangeSelection') &&
		is_integer(state.rangeSelection)) {
		junk := private.rangeBox.select(state.rangeSelection);
	    }
	    if (has_field(state,'rangeEntry') &&
		is_string(state.rangeEntry)) {
		private.rangeBox.insertentry(state.rangeEntry)
	    }
	    if (has_field(state,'rangesState') &&
		is_record(state.rangesState)) {
	    }
	    if (has_field(state,'scan')) {
		private.scan.setValue(state.scan);
	    } else {
		private.scan.setValue('');
	    }
	    if (has_field(state,'start')) {
		private.startint.setValue(state.start);
	    } else {
		private.startint.setValue('');
	    }
	    if (has_field(state,'stop')) {
		private.stopint.setValue(state.stop);
	    } else {
		private.stopint.setValue('');
	    }
	    if (has_field(state,'vpeak')) {
		private.atpeak.setValue(state.vpeak);
	    } else {
		private.atpeak.setValue('');
	    }
	    if (has_field(state,'centroid')) {
		private.centroid.setValue(state.centroid);
	    } else {
		private.centroid.setValue('');
	    }
	    if (has_field(state,'min')) {
		private.min.setValue(state.min);
	    } else {
		private.min.setValue('');
	    }
	    if (has_field(state,'area')) {
		private.area.setValue(state.area);
	    } else {
		private.area.setValue('');
	    }
	    if (has_field(state,'peak')) {
		private.peak.setValue(state.peak);
	    } else {
		private.peak.setValue('');
	    }
	    if (has_field(state,'rms')) {
		private.rms.setValue(state.rms);
	    } else {
		private.rms.setValue('');
	    }
	    # and now make sure everything is in sync
	    # are the selection and the entry box strings the same
#	    currUnits := private.currUnits;
	    # if the entry has no contents, it can't have any units
#	    if (private.rangeBox.getentry() != '' &&
#		private.rangeBox.getentry() == private.rangeBox.get('selected'))# {
		# then make sure that the current units are the range units for
		# the given selection
#		currUnits := private.rangeUnits[private.rangeBox.selection()+1];
		# final check to ensure that the units retrieved here are valid
		# if not, default to previous value
#		if (!is_integer(currUnits)) currUnits := private.currUnits;
#	    }
#	    private.setUnits(currUnits);
	    # and finally, update the plotter if there is anything to plot
#	    if (is_sdrecord(private.rm.getlastviewed().value)) {
#		private.updatePlotterRanges(private.rangeBox.getentry(),
#					    private.currUnits);
#	    }
	    result := T;
	}
	return result;
    }

    # subsequences automatically return self
}
