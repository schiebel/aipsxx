# onlinegbtmsfillergui: A GUI for the online GBT MS filler agent
# Copyright (C) 1999,2000,2001,2002,2003
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
# $Id: onlinegbtmsfillergui.g,v 19.0 2003/07/16 03:42:54 aips2adm Exp $

include "widgetserver.g";
include "note.g";
include "helpmenu.g";
include "popuphelp.g";
include "quanta.g";
include "measures.g";

include "onlinegbtmsfiller.g";

onlinegbtmsfillergui := function(thefiller,widgetset=dws)
{
    pvt := [=];
    public := [=];

    if (!have_gui()) return throw('A GUI is not available for this glish session, ',
				  'unable to create one for the online GBT filler',
				  origin='onlinegbtmsfillergui');

    if (!is_agent(thefiller) || !has_field(thefiller,'type') ||
	thefiller.type() != 'onlinegbtmsfiller') {
	return throw('thefiller is not an onlinegbtmsfiller',
		     origin='onlinegbtmsfillergui');
    }

    widgetset.tk_hold();

    pvt.itsFiller := thefiller;

    # are we mapped
    pvt.mapped := T;

    # all of the routine function related whenevers - to be killed via done
    pvt.whenevers := as_integer([]);

    # keep the file menu ones separate
    pvt.fileMenuWhenevers := as_integer([]);

    # outer frame
    pvt.parent := widgetset.frame(title='GBT On-line MeasurementSet Filler');

    # the menubar
    pvt.mb := widgetset.frame(pvt.parent,relief='raised',side='left',
			      expand='x');

    # the File menu
    # This is done in a function so that it can be called when the projects
    # menu needs to be redone.  This is a workaround due to a bug which
    # makes it impossible to remove sub-menus from an existing menu.
    # the file menu is embedded in its own frame so that it can't migrate
    # around the menu bar when it is re-created
    pvt.fileMenuFrame := widgetset.frame(pvt.mb, relief='flat', expand='none');
    pvt.makeFileMenu := function(fileMenuFrame, widgetset) {
	wider pvt;
	pvt.fileMenu := widgetset.button(fileMenuFrame,'File',type='menu');
     
	# the help for the File menu
	helptext := 'File Menu';
	helpitems := as_string([]);
	helpitems[1] := 'Choose the project to fill';
	helpitems[2] := 'Refresh the Projects menu using the top-level directory';
	helpitems[3] := 'Set the top-level MeasurementSet directory';
	helpitems[4] := 'Set the top-level data directory';
	helpitems[5] := 'Dismiss this GUI but leave the underlying tool intact';
	helpitems[6] := 'Stop the filler and destroy this tool';
	for (txt in helpitems) {
	    helptext := spaste(helptext,'\n','- ',txt);
	}
	popuphelp(pvt.fileMenu, txt=helptext);
	
	# The available projects to choose from
	pvt.projectsMenu := widgetset.button(pvt.fileMenu,'Projects',type='menu');
	pvt.projectsSubMenus := [=];
	pvt.projectButtons := [=];
	pvt.currProjectMenu := pvt.projectsMenu;
	pvt.projectCount := 0;
	pvt.projectWhenevers := as_integer([]);
	
	# rescan the top-level data directory 
	pvt.rescanDataButton := 
	    widgetset.button(pvt.fileMenu,'Refresh Projects Menu');    
	
	# Set the top-level MS directory
	pvt.setMSButton := 
	    widgetset.button(pvt.fileMenu,'Set MeasurementSet Directory ...');
	
	# Set the top-level data directory
	pvt.setDataButton := 
	    widgetset.button(pvt.fileMenu,'Set Data Directory ...');
	
	# An empty button for spacing
	pvt.emptyFileButton := widgetset.button(pvt.fileMenu,'  ',disabled=T);
	
	# A Dismiss button - dismisses (unmaps) this GUI, can be remapped via
	# a call to the gui() function in the filler tool
	pvt.dismissButton := widgetset.button(pvt.fileMenu, 'Dismiss', type='dismiss');

	# A Done button - kills this tool
	pvt.doneButton := widgetset.button(pvt.fileMenu,'Done',type='halt');
    }
    pvt.makeFileMenu(pvt.fileMenuFrame, widgetset)
	
    # The Options menu
    pvt.optionsMenu := widgetset.button(pvt.mb, 'Options', type='menu');
    # the help for the Options menu
    helptext := 'Options Menu';
    helpitems := as_string([]);
    helpitems[1] := 'Keep the raw pointing values in NRAO_GBT_POINTING';
    helpitems[2] := 'Keep the raw focus values in NRAO_GBT_POINTING';
    helpitems[3] := 'Fill the ACS lag values to the LAG_DATA column';
    helpitems[4] := 'Choose which vanVleck correction to use on ACS data';
    helpitems[5] := 'Choose which smoothing function to use on ACS data';
    helpitems[6] := 'Choose which CAL_TEMP to use from the receiver cal table';
    for (txt in helpitems) {
	helptext := spaste(helptext,'\n','- ',txt);
    }
    popuphelp(pvt.optionsMenu, txt=helptext);

    # Options here are all check buttons, so far
    pvt.keepPointing := widgetset.button(pvt.optionsMenu,'Keep Raw Pointing Values',
					 type='check');
    pvt.keepPointing->state(pvt.itsFiller->fillrawpointing());
    pvt.keepFocus := widgetset.button(pvt.optionsMenu,'Keep Raw Focus Values',
				      type='check');
    pvt.keepFocus->state(pvt.itsFiller->fillrawfocus());
    pvt.fillLags := widgetset.button(pvt.optionsMenu,'Fill ACS Lag Values',
				     type='check');
    pvt.fillLags->state(pvt.itsFiller->filllags());
    pvt.vanVleckMenu := widgetset.button(pvt.optionsMenu,'VanVleck Corrections',type='menu');
    pvt.schwabVV := widgetset.button(pvt.vanVleckMenu,'Schwab',type='radio');
    pvt.oldVV := widgetset.button(pvt.vanVleckMenu,'Old',type='radio');
    pvt.noVV := widgetset.button(pvt.vanVleckMenu,'None',type='radio');
    currvv := pvt.itsFiller->vv();
    if (currvv == "Schwab") {
	pvt.schwabVV->state(T);
    } else if (currvv == "Old") {
	pvt.oldVV->state(T);
    } else {
	pvt.noVV->state(T);
    }
    pvt.smoothMenu := widgetset.button(pvt.optionsMenu,'Smoothing functions',type='menu');
    pvt.hanningSm := widgetset.button(pvt.smoothMenu,'Hanning',type='radio');
    pvt.hammingSm := widgetset.button(pvt.smoothMenu,'Hamming',type='radio');
    pvt.noSm := widgetset.button(pvt.smoothMenu,'None',type='radio');
    currSm := pvt.itsFiller->smooth();
    if (currSm == "Hanning") {
	pvt.hanningSm->state(T);
    } else if (currSm == "Hamming") {
	pvt.hammingSm->state(T);
    } else {
	pvt.noSm->state(T);
    }
    pvt.useCalMenu := widgetset.button(pvt.optionsMenu,'?_CAL_TEMP',type='menu');
    pvt.lowCal := widgetset.button(pvt.useCalMenu,'LOW',type='radio');
    pvt.highCal := widgetset.button(pvt.useCalMenu,'HIGH',type='radio');
    if (pvt.itsFiller->usehighcal()) {
	pvt.highCal->state(T);
    } else {
	pvt.lowCal->state(T);
    }

    # a spacer to keep the help on the right
    pvt.mbSpacer := widgetset.frame(pvt.mb,height=10,borderwidth=0,expand='x');

    # the help menu frame, kept on the right by the spacer
    pvt.helpFrame := widgetset.frame(pvt.mb,relief='flat',borderwidth=0,
				     width=1,height=1,side='right',
				     expand='none');
    pvt.helpMenu := widgetset.helpmenu(pvt.helpFrame,
				       'GBT On-line MeasurementSet Filler',
				       'Refman:onlinegbtmsfiller');


    # A state indicator
    pvt.stateFrame := widgetset.frame(pvt.parent, side='left');
    pvt.stateLabel := widgetset.label(pvt.stateFrame, 'State :');
    pvt.stateIndicator := widgetset.label(pvt.stateFrame, width=10);

    # Golive suspend and Update buttons, on a line
    pvt.actionFrame := widgetset.frame(pvt.parent, side='left');
    pvt.fillButton := widgetset.button(pvt.actionFrame, 'Fill');
    pvt.suspendButton := widgetset.button(pvt.actionFrame, 'Suspend');
    pvt.updateButton := widgetset.button(pvt.actionFrame, 'Update',);

    # current top-level director and project information
    pvt.projectInfoFrame := widgetset.frame(pvt.parent,side='left');

    # a frame I use several times
    labelledInfo := function(parent, alabel, awidth, usescrollbar=F) {
	# just have these naked, its all private any way
	public := [=];
	public.frame := widgetset.frame(parent, side='top');
	public.label := widgetset.label(public.frame, alabel);
	public.entry := widgetset.entry(public.frame, width=awidth, disabled=T, 
				      background='lightgray');
	if (usescrollbar) {
	    public.sb := widgetset.scrollbar(public.frame, orient='horizontal');
	    whenever public.sb->scroll do { public.entry->view($value);}
	    whenever public.entry->xscroll do { public.sb->view($value);}
	}
	return public;
    }

    pvt.projectFrame := widgetset.frame(pvt.projectInfoFrame,side='left');
    pvt.projectLabel := labelledInfo(pvt.projectFrame, 'Project', 16, T);
    pvt.datatopLabel := labelledInfo(pvt.projectFrame, 'Data Directory', 16, T);
    pvt.mstopLabel := labelledInfo(pvt.projectFrame, 'MS Directory', 16, T);

    # Status information
    pvt.statusFrameTop := widgetset.frame(pvt.parent, side='top');

    pvt.statusFrame1 := widgetset.frame(pvt.statusFrameTop,side='left');
    pvt.scanLabel := labelledInfo(pvt.statusFrame1, 'Scan', 10);
    pvt.dmjdLabel := labelledInfo(pvt.statusFrame1, 'DMJD in log', 25);
    pvt.tsLabel := labelledInfo(pvt.statusFrame1, 'File timestamp', 25);

    pvt.statusFrame2 := widgetset.frame(pvt.statusFrameTop,side='left');
    pvt.backendFrame := widgetset.frame(pvt.statusFrame2,side='top');
    pvt.backendLabel := widgetset.label(pvt.backendFrame,'Backend');
    # these buttons are as wide as "SpectralProcessor" 17 chars
    pvt.dcrButton := widgetset.button(pvt.backendFrame,'DCR',type='menu',relief='groove',
				      width=17);
    pvt.spButton := widgetset.button(pvt.backendFrame,'SpectralProcessor',type='menu',relief='groove',
				      width=17);
    pvt.acsAButton := widgetset.button(pvt.backendFrame,'ACS Bank A',type='menu',relief='groove',
				       width=17);
    pvt.acsBButton := widgetset.button(pvt.backendFrame,'ACS Bank B',type='menu',relief='groove',
				       width=17);
    pvt.acsCButton := widgetset.button(pvt.backendFrame,'ACS Bank C',type='menu',relief='groove',
				       width=17);
    pvt.acsDButton := widgetset.button(pvt.backendFrame,'ACS Bank D',type='menu',relief='groove',
				       width=17);
    pvt.holoButton := widgetset.button(pvt.backendFrame,'Holography', type='menu', 
				       relief='groove',width=17);

    pvt.msFrame := widgetset.frame(pvt.statusFrame2,side='top');
    pvt.msLabel := widgetset.label(pvt.msFrame,'MeasurementSet');
    pvt.dcrMS := widgetset.entry(pvt.msFrame,width=30,background='lightgray',disabled=T,
				 borderwidth=3);
    pvt.spMS := widgetset.entry(pvt.msFrame,width=30,background='lightgray',disabled=T,
				 borderwidth=3);
    pvt.acsAMS := widgetset.entry(pvt.msFrame,width=30,background='lightgray',disabled=T,
				  borderwidth=3);
    pvt.acsBMS := widgetset.entry(pvt.msFrame,width=30,background='lightgray',disabled=T,
				  borderwidth=3);
    pvt.acsCMS := widgetset.entry(pvt.msFrame,width=30,background='lightgray',disabled=T,
				  borderwidth=3);
    pvt.acsDMS := widgetset.entry(pvt.msFrame,width=30,background='lightgray',disabled=T,
				  borderwidth=3);
    pvt.holoMS := widgetset.entry(pvt.msFrame,width=30, background='lightgray',disabled=T,
				  borderwidth=3);

    pvt.dcrMS->insert('<unset>');
    pvt.spMS->insert('<unset>');
    pvt.acsAMS->insert('<unset>');
    pvt.acsBMS->insert('<unset>');
    pvt.acsCMS->insert('<unset>');
    pvt.acsDMS->insert('<unset>');
    pvt.holoMS->insert('<unset>');

    pvt.sizeFrame := widgetset.frame(pvt.statusFrame2,side='top');
    pvt.sizeLabel := widgetset.label(pvt.sizeFrame,'Size (rows)');
    pvt.dcrSize := widgetset.entry(pvt.sizeFrame,width=10,justify='right',
				   disabled=T,background='lightgray',
				   borderwidth=3);
    pvt.spSize := widgetset.entry(pvt.sizeFrame,width=10,justify='right',
				   disabled=T,background='lightgray',
				   borderwidth=3);
    pvt.acsASize := widgetset.entry(pvt.sizeFrame,width=10,justify='right',
				     disabled=T,background='lightgray',
				     borderwidth=3);
    pvt.acsBSize := widgetset.entry(pvt.sizeFrame,width=10,justify='right',
				     disabled=T,background='lightgray',
				     borderwidth=3);
    pvt.acsCSize := widgetset.entry(pvt.sizeFrame,width=10,justify='right',
				     disabled=T,background='lightgray',
				     borderwidth=3);
    pvt.acsDSize := widgetset.entry(pvt.sizeFrame,width=10,justify='right',
				     disabled=T,background='lightgray',
				     borderwidth=3);
    pvt.holoSize := widgetset.entry(pvt.sizeFrame,width=10,justify='right',
				   disabled=T,background='lightgray',
				   borderwidth=3);

    # set the project menu given a list of projects
    pvt.setProjectMenu := function(projects) {
	wider pvt;
	# this is a workaround due to a bug in eliminating sub-menus
	if (has_field(pvt,'fileMenu') && is_agent(pvt.fileMenu)) {
	    val pvt.fileMenu := F;
	}
	pvt.makeFileMenu(pvt.fileMenuFrame, widgetset);
	pvt.setupFileMenuActions();
#	if (len(pvt.projectWhenevers) > 0) {
	    # deactivate any existing button whenevers
#	    deactivate pvt.projectWhenevers;
	    # remove all of the buttons 
#	    for (abuttonName in field_names(pvt.projectButtons)) {
#		val pvt.projectButtons[abuttonName] := F;
#	    }
	    # and all of the submenus
#	    for (abuttonName in field_names(pvt.projectsSubMenus)) {
#		val pvt.projectsSubMenus[abuttonName] := F;
#	    }
#	    pvt.projectsSubMenus := [=];
#	    pvt.projectButtons := [=];
#	    pvt.projectWhenevers := as_integer([]);
#	    pvt.currProjectMenu := pvt.projectsMenu;
#	    pvt.projectCount := 0;
#	}
	if (is_unset(projects)) return T;
	for (project in sort_pair(to_lower(projects),projects)) {
	    if (pvt.projectCount > 20) {
		# need a new sub-menu
		pvt.projectsSubMenus[len(pvt.projectsSubMenus)+1] :=
		    widgetset.button(pvt.currProjectMenu, text='more ...',
				     type='menu');
		pvt.currProjectMenu := pvt.projectsSubMenus[len(pvt.projectsSubMenus)];;
		pvt.projectCount := 0;
	    }
	    pvt.projectButtons[project] := 
		widgetset.button(pvt.currProjectMenu, text=project,
				 value=project);
	    pvt.projectCount +:= 1;
	    whenever pvt.projectButtons[project]->press do {
		pvt.itsFiller->setproject($value);
	    }
	    pvt.projectWhenevers[len(pvt.projectWhenevers)+1] := last_whenever_executed();
	}
	return T;
    }

    # the callback function for file access
    pvt.nextFileEvent := F;
    pvt.fileCallback := function(pathname) {
	wider pvt;
	if (is_string(pathname) && strlen(pathname) > 0) {
	    pvt.itsFiller->[pvt.nextFileEvent](pathname);
	    # and break the connection
	}
	dc.setselectcallback(0);
    }

    # set up the callback
    pvt.setupFileCallback := function(whichEvent) {
	wider pvt;
	pvt.nextFileEvent := whichEvent;
	# use the default catalog
	dc.gui(F);
	dc.show(show_types='Directory');
	dc.setselectcallback(pvt.fileCallback);
    }

    # set the state indicator
    pvt.setStateIndicator := function(whichState) {
	wider pvt;
	if (whichState == "fill") {
	    pvt.stateIndicator->text("Filling");
	    pvt.fillButton->disabled(T);
	    pvt.suspendButton->disabled(F);
	    pvt.updateButton->disabled(F);
	} else if (whichState == "idle") {
	    pvt.stateIndicator->text("Idle");
	    pvt.fillButton->disabled(T);
	    pvt.suspendButton->disabled(F);
	    pvt.updateButton->disabled(F);
	} else if (whichState == "suspended") {
	    pvt.stateIndicator->text("Suspended");
	    pvt.fillButton->disabled(F);
	    pvt.suspendButton->disabled(T);
            pvt.suspendButton->relief('raised');
	    pvt.updateButton->disabled(T);
            pvt.updateButton->relief('raised');
	} else if (whichState == "done") {
	    # unmap it and then wipe it out
	    pvt.parent->unmap();
	    # clean up all of the whenevers
	    deactivate pvt.whenevers;
	    deactivate pvt.projectWhenevers;
	    deactivate pvt.fileMenuWhenevers;
	    # and wipe out the top level frame
	    val pvt.parent := F;
	} else {
	    pvt.stateIndicator->text("CONFUSED");
	}
    }    

    pvt.setProjectEntry := function() {
	pvt.projectLabel.entry->delete('start','end');
	project := pvt.itsFiller->project();
	if (!is_unset(project)) {
            pvt.projectLabel.entry->insert(project);
            pvt.projectLabel.entry->background('lightgray');
	} else {
            pvt.projectLabel.entry->insert('<unset>');
            pvt.projectLabel.entry->background('yellow');
        }
    }

    pvt.setDataTopEntry := function() {
	pvt.datatopLabel.entry->delete('start','end');
	datatop := pvt.itsFiller->datatop();
	if (!is_unset(datatop)) {
            pvt.datatopLabel.entry->insert(datatop);
            pvt.datatopLabel.entry->background('lightgray');
	} else {
            pvt.datatopLabel.entry->insert('<unset>');
            pvt.datatopLabel.entry->background('yellow');
        }
    }

    pvt.setMSTopEntry := function() {
	pvt.mstopLabel.entry->delete('start','end');
	mstop := pvt.itsFiller->msdirectory();
	if (!is_unset(mstop)) {
            pvt.mstopLabel.entry->insert(mstop);
            pvt.mstopLabel.entry->background('lightgray');
	} else {
            pvt.mstopLabel.entry->insert('<unset>');
            pvt.mstopLabel.entry->background('yellow');
        }
    }

    # setup actions for the File menu buttons
    pvt.setupFileMenuActions := function() {
	wider pvt;
	# rescan projects
	if (len(pvt.fileMenuWhenevers) > 0) deactivate pvt.fileMenuWhenevers;
	pvt.fileMenuWhenevers := as_integer([]);
	whenever pvt.rescanDataButton->press do {
	    # the filler will itself issue an event to trigger updating the project menu
	    pvt.itsFiller->refreshprojects();
	}
	pvt.fileMenuWhenevers[len(pvt.fileMenuWhenevers)+1] := last_whenever_executed();
	
	# set the top-level MS directory
	whenever pvt.setMSButton->press do {
	    pvt.setupFileCallback("setmsdirectory");
	}
	pvt.fileMenuWhenevers[len(pvt.fileMenuWhenevers)+1] := last_whenever_executed();
	
	# set the top-level data directory
	whenever pvt.setDataButton->press do {
	    pvt.setupFileCallback("setdatatop");
	}
	pvt.fileMenuWhenevers[len(pvt.fileMenuWhenevers)+1] := last_whenever_executed();

	# the dismiss button
	whenever pvt.dismissButton->press do {
	    pvt.parent->unmap();
	    pvt.mapped := F;
	}
	
	# the done button
	whenever pvt.doneButton->press do {
	    wider public;
	    if (donechoice('Really exit the filler?')) {
		pvt.itsFiller->done();
	    }
	}
	pvt.fileMenuWhenevers[len(pvt.fileMenuWhenevers)+1] := last_whenever_executed();
    }
    pvt.setupFileMenuActions();

    whenever pvt.keepPointing->press do {
	pvt.itsFiller->setfillrawpointing(pvt.keepPointing->state());
	# just to be safe
	pvt.keepPointing->state(pvt.itsFiller->fillrawpointing());
    }

    whenever pvt.keepFocus->press do {
	pvt.itsFiller->setfillrawfocus(pvt.keepFocus->state());
	# just to be safe
	pvt.keepFocus->state(pvt.itsFiller->fillrawfocus());
    }

    whenever pvt.fillLags->press do {
	pvt.itsFiller->setfilllags(pvt.fillLags->state());
	# just to be safe
	pvt.fillLags->state(pvt.itsFiller->filllags());
    }

    whenever pvt.schwabVV->press do {
	pvt.itsFiller->setvv("schwab");
	# just to be safe
	pvt.schwabVV->state(T);
    }

    whenever pvt.oldVV->press do {
	pvt.itsFiller->setvv("old");
	# just to be safe
	pvt.oldVV->state(T);
    }

    whenever pvt.noVV->press do {
	pvt.itsFiller->setvv("none");
	# just to be safe
	pvt.noVV->state(T);
    }

    whenever pvt.hanningSm->press do {
	pvt.itsFiller->setsmooth("hanning");
	# just to be safe
	pvt.hanningSm->state(T);
    }

    whenever pvt.hammingSm->press do {
	pvt.itsFiller->setsmooth("hamming");
	# just to be safe
	pvt.hammingSm->state(T);
    }

    whenever pvt.noSm->press do {
	pvt.itsFiller->setsmooth("none");
	# just to be safe
	pvt.noSm->state(T);
    }

    whenever pvt.lowCal->press do {
	pvt.itsFiller->setusehighcal(F);
	# just to be safe
	pvt.lowCal->state(T);
    }

    whenever pvt.highCal->press do {
	pvt.itsFiller->setusehighcal(T);
	# just to be safe
	pvt.highCal->state(T);
    }

    # fill button
    whenever pvt.fillButton->press do {
	pvt.itsFiller->golive();
    }
    pvt.whenevers[len(pvt.whenevers)+1] := last_whenever_executed();

    # suspend button
    whenever pvt.suspendButton->press do {
	pvt.suspendButton->relief('sunken');
	pvt.suspendButton->disabled(T);
	pvt.itsFiller->suspend();
    }
    pvt.whenevers[len(pvt.whenevers)+1] := last_whenever_executed();

    # update button
    whenever pvt.updateButton->press do {
	pvt.updateButton->relief('sunken');
	pvt.updateButton->disabled(T);
	pvt.itsFiller->update();
    }
    pvt.whenevers[len(pvt.whenevers)+1] := last_whenever_executed();

    # events from the filler which trigger responses here
    # the state changes
    whenever pvt.itsFiller->state do {
	pvt.setStateIndicator($value);
    }
    pvt.whenevers[len(pvt.whenevers)+1] := last_whenever_executed();

    # the known projects have changed
    whenever pvt.itsFiller->refreshprojects do {
	result := pvt.setProjectMenu(pvt.itsFiller->projects());
    }
    pvt.whenevers[len(pvt.whenevers)+1] := last_whenever_executed();

    # a new status event
    # function needed to convert time values to readable strings
    pvt.timeString := function(timeVal) {
	atime := spaste(as_string(timeVal),' d');
	atimeAsEpoch := dm.epoch('utc',dq.quantity(atime));
	return dq.time(dm.getvalue(atimeAsEpoch),form='dmy');	
    }

    pvt.handleStatusEvent := function(status) {
	wider pvt;
	pvt.scanLabel.entry->delete('start','end');
	pvt.scanLabel.entry->insert(as_string(status.nextscan));
	pvt.dmjdLabel.entry->delete('start','end');
	pvt.dmjdLabel.entry->insert(pvt.timeString(status.nextdmjd));
	pvt.tsLabel.entry->delete('start','end');
	pvt.tsLabel.entry->insert(pvt.timeString(status.nexttimestamp));
	pvt.keepPointing->state(status.fillrawpointing);
	pvt.keepFocus->state(status.fillrawfocus);
	pvt.fillLags->state(status.filllags);
	if (status.vv == "Schwab") {
	    pvt.schwabVV->state(T);
	} else if (status.vv == "Old") {
	    pvt.oldVV->state(T);
	} else {
	    pvt.noVV->state(T);
	}
	if (status.smooth == "Hanning") {
	    pvt.hanningSm->state(T);
	} else if (status.smooth == "Hamming") {
	    pvt.hammingSm->state(T);
	} else {
	    pvt.noSm->state(T);
	}
	pvt.highCal->state(status.usehighcal);

	pvt.handleMSStatusEvent(status);
    }

    pvt.handleMSStatusEvent := function(status) {
	wider pvt;
	# DCR
	curDCRMS := pvt.dcrMS->get();
	thisDCRMS := dos.basename(status.dcr.ms);
	if (curDCRMS != thisDCRMS) {
	    # update ms name - may be <unset>
	    pvt.dcrMS->delete('start','end');
	    pvt.dcrMS->insert(thisDCRMS);
	    pvt.dcrMS->background('lightgray');
	    # size is always updated here
	    pvt.dcrSize->delete('start','end');
	    pvt.dcrSize->insert(as_string(status.dcr.nrows));
	} else {
	    # ms name is okay, only update size if it is >= 0
	    # because if its < 0, then this is unset and if the
	    # name is okay, that means the size must already be -1
	    if (status.dcr.nrows >= 0) {
		pvt.dcrSize->delete('start','end');
		pvt.dcrSize->insert(as_string(status.dcr.nrows));
	    }
	}
	# SP
	curSPMS := pvt.spMS->get();
	thisSPMS := dos.basename(status.sp.ms);
	if (curSPMS != thisSPMS) {
	    # update ms name - may be <unset>
	    pvt.spMS->delete('start','end');
	    pvt.spMS->insert(thisSPMS);
	    pvt.spMS->background('lightgray');
	    # size is always updated here
	    pvt.spSize->delete('start','end');
	    pvt.spSize->insert(as_string(status.sp.nrows));
	} else {
	    # ms name is okay, only update size if it is >= 0
	    # because if its < 0, then this is unset and if the
	    # name is okay, that means the size must already be -1
	    if (status.sp.nrows >= 0) {
		pvt.spSize->delete('start','end');
		pvt.spSize->insert(as_string(status.sp.nrows));
	    }
	}
	# ACS - bank A
	curAcsAMS := pvt.acsAMS->get();
	thisAcsAMS := dos.basename(status.acs.A.ms);
	if (curAcsAMS != thisAcsAMS) {
	    # update ms name - may be <unset>
	    pvt.acsAMS->delete('start','end');
	    pvt.acsAMS->insert(thisAcsAMS);
	    pvt.acsAMS->background('lightgray');
	    # size is always updated here
	    pvt.acsASize->delete('start','end');
	    pvt.acsASize->insert(as_string(status.acs.A.nrows));
	} else {
	    # ms name is okay, only update size if it is >= 0
	    # because if its < 0, then this is unset and if the
	    # name is okay, that means the size must already be -1
	    if (status.acs.A.nrows >= 0) {
		pvt.acsASize->delete('start','end');
		pvt.acsASize->insert(as_string(status.acs.A.nrows));
	    }
	}
	# ACS - bank B
	curAcsBMS := pvt.acsBMS->get();
	thisAcsBMS := dos.basename(status.acs.B.ms);
	if (curAcsBMS != thisAcsBMS) {
	    # update ms name - may be <unset>
	    pvt.acsBMS->delete('start','end');
	    pvt.acsBMS->insert(thisAcsBMS);
	    pvt.acsBMS->background('lightgray');
	    # size is always updated here
	    pvt.acsBSize->delete('start','end');
	    pvt.acsBSize->insert(as_string(status.acs.B.nrows));
	} else {
	    # ms name is okay, only update size if it is >= 0
	    # because if its < 0, then this is unset and if the
	    # name is okay, that means the size must already be -1
	    if (status.acs.B.nrows >= 0) {
		pvt.acsBSize->delete('start','end');
		pvt.acsBSize->insert(as_string(status.acs.B.nrows));
	    }
	}
	# ACS - bank C
	curAcsCMS := pvt.acsCMS->get();
	thisAcsCMS := dos.basename(status.acs.C.ms);
	if (curAcsCMS != thisAcsCMS) {
	    # update ms name - may be <unset>
	    pvt.acsCMS->delete('start','end');
	    pvt.acsCMS->insert(thisAcsCMS);
	    pvt.acsCMS->background('lightgray');
	    # size is always updated here
	    pvt.acsCSize->delete('start','end');
	    pvt.acsCSize->insert(as_string(status.acs.C.nrows));
	} else {
	    # ms name is okay, only update size if it is >= 0
	    # because if its < 0, then this is unset and if the
	    # name is okay, that means the size must already be -1
	    if (status.acs.C.nrows >= 0) {
		pvt.acsCSize->delete('start','end');
		pvt.acsCSize->insert(as_string(status.acs.C.nrows));
	    }
	}
	# ACS - bank D
	curAcsDMS := pvt.acsDMS->get();
	thisAcsDMS := dos.basename(status.acs.D.ms);
	if (curAcsDMS != thisAcsDMS) {
	    # update ms name - may be <unset>
	    pvt.acsDMS->delete('start','end');
	    pvt.acsDMS->insert(thisAcsDMS);
	    pvt.acsDMS->background('lightgray');
	    # size is always updated here
	    pvt.acsDSize->delete('start','end');
	    pvt.acsDSize->insert(as_string(status.acs.D.nrows));
	} else {
	    # ms name is okay, only update size if it is >= 0
	    # because if its < 0, then this is unset and if the
	    # name is okay, that means the size must already be -1
	    if (status.acs.D.nrows >= 0) {
		pvt.acsDSize->delete('start','end');
		pvt.acsDSize->insert(as_string(status.acs.D.nrows));
	    }
	}
	# Holography
	curHoloMS := pvt.holoMS->get();
	thisHoloMS := dos.basename(status.holo.ms);
	if (curHoloMS != thisHoloMS) {
	    # update ms name - may be <unset>
	    pvt.holoMS->delete('start','end');
	    pvt.holoMS->insert(thisHoloMS);
	    pvt.holoMS->background('lightgray');
	    # size is always updated here
	    pvt.holoSize->delete('start','end');
	    pvt.holoSize->insert(as_string(status.holo.nrows));
	} else {
	    # ms name is okay, only update size if it is >= 0
	    # because if its < 0, then this is unset and if the
	    # name is okay, that means the size must already be -1
	    if (status.holo.nrows >= 0) {
		pvt.holoSize->delete('start','end');
		pvt.holoSize->insert(as_string(status.holo.nrows));
	    }
	}
    }

    whenever pvt.itsFiller->status do {
	pvt.handleStatusEvent($value);
    }
    pvt.whenevers[len(pvt.whenevers)+1] := last_whenever_executed();

    whenever pvt.itsFiller->msstatus do {
	pvt.handleMSStatusEvent($value);
    }
    pvt.whenevers[len(pvt.whenevers)+1] := last_whenever_executed();

    # a new top-level data directory
    whenever pvt.itsFiller->setdatatop do {
	pvt.setDataTopEntry();
	# this also always triggers an update of the projects menu
	pvt.itsFiller->refreshprojects();
    }
    pvt.whenevers[len(pvt.whenevers)+1] := last_whenever_executed();

    # the project has been set
    whenever pvt.itsFiller->setproject do {
	pvt.setProjectEntry();
    }
    pvt.whenevers[len(pvt.whenevers)+1] := last_whenever_executed();

    # a new top-level MS directory
    whenever pvt.itsFiller->setmsdirectory do {
	pvt.setMSTopEntry();
    }
    pvt.whenevers[len(pvt.whenevers)+1] := last_whenever_executed();

    # an update event
    whenever pvt.itsFiller->update do {
	    pvt.itsFiller->state();
	pvt.updateButton->relief('raised');
	if (pvt.itsFiller->state() != 'suspended') {
	    pvt.updateButton->disabled(F);
	} else {
	    pvt.updateButton->disabled(T);
	}
    }
    
    # a GUI event, make sure our top frame is mapped
    whenever pvt.itsFiller->gui do {
	if (!pvt.mapped) {
	    pvt.parent->map();
	    pvt.mapped := T;
	}
    }
    pvt.whenevers[len(pvt.whenevers)+1] := last_whenever_executed();

    # a done event
    whenever pvt.itsFiller->done do {
    }
    pvt.whenevers[len(pvt.whenevers)+1] := last_whenever_executed();


    # set the initial state of the GUI
    pvt.setProjectMenu(pvt.itsFiller->projects());
    pvt.setStateIndicator(pvt.itsFiller->state());
    pvt.setProjectEntry();
    pvt.setDataTopEntry();
    pvt.setMSTopEntry();

    widgetset.tk_release();

    # for debugging
    public.debug := function() { wider pvt; return pvt;}


    return public;
}


