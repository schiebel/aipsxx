# gbtfiller_base : basic glish script for gbt*filler client
# Copyright (C) 1998,1999
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# unde the terms of the GNU Library General Public License as published by
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
# $Id: gbtfiller_base.g,v 19.0 2003/07/16 03:42:45 aips2adm Exp $

# include guard
pragma include once
 

include "gbtfillerGUI.g";
include "table.g";
include "note.g";

# it would be nice if this could share most of the stuff in gbtfiller.g
# rather than duplicate it all here pretty much as is.

gbtfiller_base := function (withGUI = T, msFiller = F) 
{
    self := [=];
    result := [=];

    if (msFiller) {
	self.filler := client("gbtmsfiller");
	self.prepend := "gbtmsfiller";
	self.output := "table";
    } else {
	self.filler := client("gbtfiller");
	self.prepend := "gbtfiller";
	self.output := "ms";
    }

    self.backendDir := F;
    self.openPending := F;
    self.timer := client("timer");
    self.interval := 5;
    self.lastState := F;
    self.table_name := F;
    self.isFilling := F;
    self.updatePending := F;
    self.readyForUpdate := T;
    self.theTable := F;
    self.msFiller := msFiller;

    self.monitor := function(arg1) {
	wider self;
#         verify that the record has the correct fields
	recordOK := T;
	if (! is_record(arg1)) {
	    note('argument is not a record.', priority='SEVERE',
		 origin='gbtfiller_base::monitor');
	    recordOK := F;
	}
	if (recordOK && ! has_field(arg1,"project")) {
	    note('project field missing from argument.', priority='SEVERE',
		 origin='gbtfiller_base::monitor');
	    recordOK := F;
	}
	if (recordOK && ! has_field(arg1,"backend")) {
	    note('backend field missing from argument.', priority='SEVERE',
		 origin='gbtfiller_base::monitor');
	    recordOK := F;
	}
	if (recordOK) {
	    self.backendDir := spaste(arg1.project,"/",arg1.backend);
#           look for optional inverval field
	    if (has_field(arg1,"interval")) {
		self.interval := arg1.interval;
	    }

	# this is NOT portable
	    self.lastState := shell(paste("ls -l",self.backendDir,
					  " | wc -l"));
	    self.timer->interval(self.interval);
	}
    }
    self.suspendMonitor := function () {
	wider self;
	self.timer->interval(-1);
    }

    if (withGUI) {
	self.gui := gbtfiller_gui(self.prepend,self.output);
    } else {
	self.gui := F;
    }

    self.fillerFailed := function(msg)
    {
	wider self;
	if (is_record(self.gui)) {
	    junk := note(spaste('failed : ',msg), priority='SEVERE',
			 origin=self.prepend);
	    self.gui.bogusState();
	}
	if (is_agent(self.timer)) self.timer->terminate();
	self.timer := F;
	self.filler := F;
    }

    whenever self.filler->["failed fail"] do {
	self.fillerFailed($value);
    }

    whenever self.filler->history do
    {
	junk := note(as_string($value), priority='NORMAL', origin=self.prepend);
    }

    self.fill_result := function(arg)
    {
	wider self;
	if (!(is_string(arg) && arg == "OK")) {
	    # the filler has gone into suspended state
	    self.isFilling := F;
	    self.suspendMonitor();
	    if (is_record(self.gui)) self.gui.suspendedState();
	    self.updatePending := F;
	    note(as_string(arg),priority='NORMAL',origin=self.prepend);
	} # otherwise the filler is just paused, do nothing
    }
    
    whenever self.filler->["update_result fill_result"] do
    {
	thisName := $name;
	thisValue := $value;
	self.readyForUpdate := T;
	note('update/fill has finished.',priority='NORMAL',origin=self.prepend);

	if (is_record(self.gui)) self.gui.status('PAUSED');
	if (thisName == 'fill_result') self.fill_result(thisValue);

	if (self.updatePending) {
	    junk := result.update();
	}
    }

    whenever self.filler->help_result do
    { 
	print $value;
    }

    whenever self.filler->shutdown_result do
    {
	note(as_string($value),priority='NORMAL',origin=self.prepend);
	if (is_record(self.gui)) self.gui.bogusState();
	self.timer->terminate();
    }

    whenever self.filler->error do
    {
	self.suspendMonitor();
	self.isFiller := F;
	self.updatePending := F;
	if (is_record(self.gui)) self.gui.suspendedState();
	note(spaste(' ERROR : ', $value),priority='SEVERE',origin=self.prepend);
    }

    whenever self.filler->["ms_name table_name"] do
    {
        if (is_string($value)) {
	    self.open($value);
        }
    }

# actuall functions which generate events

    self.fill := function(rec) {
	wider self;
	state := result.query_state();
	if (state == "paused") {
	    note('Filler must be suspended before a new fill can begin',
		 priority='NORMAL', origin=self.prepend);
	    return F;
	} else {
	    self.readForUpdate := F;
	    # close internal table so that lock is freed
	    self.close();
	    self.filler->fill(rec);
	    self.isFilling := T;
	    self.monitor(rec);
	    if (is_record(self.gui)) self.gui.fillingState();
	    return T;
	}
    }

    if (!msFiller) {
	result.fill := function(backend, project, table_name=F, 
				start_time=F, stop_time=F, object=F)
	{
	    wider self;

	    rec := [backend=backend, project=project];
#        	add optional arguments when present
	    if (is_string(table_name)) rec.table_name := table_name;
	    if (is_string(start_time)) rec.start_time := start_time;
	    if (is_string(stop_time)) rec.stop_time := stop_time;
	    if (is_string(object)) rec.object := object;

	    if (is_record(self.gui)) self.gui.setState(rec);

	    return self.fill(rec);
	}

	result.table := function() { wider self; return self.theTable;}

    } else {
	result.fill := function(backend, project, ms_name=F, 
				start_time=F, stop_time=F, object=F)
	{
	    wider self;

	    rec := [backend=backend, project=project];
#        	add optional arguments when present
	    if (is_string(ms_name)) rec.ms_name := ms_name;
	    if (is_string(start_time)) rec.start_time := start_time;
	    if (is_string(stop_time)) rec.stop_time := stop_time;
	    if (is_string(object)) rec.object := object;

	    if (is_record(self.gui)) self.gui.setState(rec);

	    return self.fill(rec);
	}

	result.ms := function() { wider self; return self.theTable;}
    }

    result.update := function(rec=[=])
    {
	wider self;
	if (self.readyForUpdate && self.isFilling) {
	    state := result.query_state();
	    if (state == "suspended") {
		note('The filler is suspended, use fill() to start/resume filling',
		     priority='NORMAL', origin=self.prepend);
	    } else {
		self.readyForUpdate := F;
		# close table?
		self.close();
		self.filler->update();
		self.updatePending := F;
	    }
	    return T;
	} else {
	    if (!self.updatePending) {
		note('Update pending.', priority='NORMAL', origin=self.prepend);
		self.updatePending := T;
	    }
	    
	}
    }

    result.suspend := function(rec=[=])
    {
	wider self;
	if (!self.isFilling) {
	    note('The filler is already suspended',
		 priority='NORMAL', origin=self.prepend);
	} else {
	    self.filler->suspend();
	}
    }

    result.query_state := function()
    {
	self.filler->queryState();
	await self.filler->state;
	return $value;
    }

    self.close := function()
    {
	wider self;
	if (!is_boolean(self.theTable)) {
	    self.theTable.close();
	}
	self.theTable := F;
    }

    self.open := function (pathName_)
    {
	wider self;
	self.close();
	self.table_name := pathName_;
	if (is_record(self.gui)) 
	    self.gui.openingState(T,spaste(' : ',pathName_));
	self.theTable := table(pathName_);
	if (is_record(self.gui)) self.gui.openingState(F);
	if (is_fail(self.theTable)) {
	    if (self.msFiller) {
		note(spaste('error! could not open MS with name',pathName_),
		     priority='SEVERE', origin=self.prepend);
	    } else {
		note(spaste('error! could not open table with name',pathName_),
		     priority='SEVERE', origin=self.prepend);
	    }
	    self.theTable := F;
	    return F;
	} else {
	    if (self.msFiller) {
		note('Output MS has been updated',priority='NORMAL',origin=self.prepend);
	    } else {
		note('Output table has been updated',
		     priority='NORMAL',origin=self.prepend);
	    }
	    return result;
	}
    }

    whenever self.timer->ready do {
	if (is_string(self.backendDir)) {
	# this is NOT portable
	    newState := shell(paste("ls -l",self.backendDir,
				    " | wc -l"));
	    if (newState != self.lastState) {
		self.updatePending := T;
		note('gbtmonitor: update pending.',priority='NORMAL',origin=self.prepend);
		junk := result.update();
		self.lastState := newState;
	    }
	}
    }

    result.quit := function(rec=[=])
    {
	wider self;
	if (is_record(self.gui)) self.gui.quit();
	self.gui := F;
	if (is_agent(self.filler)) self.filler->terminate();
	if (is_agent(self.timer)) self.timer->terminate();
	self.filler := F;
	self.timer := F;
    }

    if (is_record(self.gui)) {
	self.gui.setFillHandler(self.fill);
	self.gui.setUpdateHandler(result.update);
	self.gui.setSuspendHandler(result.suspend);
	self.gui.setQuitHandler(result.quit);
    }

    result.self := function() { wider self; return self;}

    return result;
}


