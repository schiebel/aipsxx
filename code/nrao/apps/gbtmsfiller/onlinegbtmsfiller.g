# onlinegbtmsfiller: agent which fills GBT data in real time
# Copyright (C) 1999,2000,2001,2002
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
# $Id: onlinegbtmsfiller.g,v 19.0 2003/07/16 03:42:53 aips2adm Exp $

# include guard
pragma include once;

include "os.g";
include "catalog.g";
include "note.g";

include "gbtmsfiller.g";

include "onlinegbtmsfillergui.g";
 

# this subsequence needs to be merged in with onlinegbtmsfiller
livegbtmsfiller := subsequence(itsFiller)
{
    private := [=];

    #  flags
    private.isFilling := F;
    private.isActive := F;
    private.updatePending := F;

    private.itsFiller := itsFiller;;

    whenever self->update do {
	wider private;
	private.updatePending := T;
	if (!private.isFilling) {
	    private.setupFiller();
	}
    }
    private.updateWhenever := last_whenever_executed();
    deactivate private.updateWhenever;

    private.setupFiller := function() {
	wider private;
	if (private.isActive) {
	    if (private.updatePending) {
		private.updatePending := F;
		private.itsFiller.update();
	    }
	    if (private.itsFiller.more() && private.isActive) {
		self->state('fill');
		private.isFilling := T;
		jobid := private.itsFiller.fillnext(async=T);
		whenever defaultservers.alerter()->[as_string(jobid)] do {
		    deactivate;
		    self->status(private.itsFiller.status());
		    private.setupFiller();
		}
	    } else {
		private.isFilling := F;
		self->state('idle');
	    }
	}
    }

    whenever self->suspend do {
	wider private;
	private.isActive := F;
	deactivate private.updateWhenever;
	activate private.goliveWhenever;
	deactivate private.suspendWhenever;
	self->state('suspended');
    }
    private.suspendWhenever := last_whenever_executed();

    whenever self->golive do {
	wider private;
	private.isActive := T;
	activate private.updateWhenever;
	activate private.suspendWhenever;
	deactivate private.goliveWhenever;
	private.setupFiller();
    }
    private.goliveWhenever := last_whenever_executed();
    
    self.isactive := function() {wider private; return private.isActive;}

    self.filler := function() {wider private; return private.itsFiller;}
}

# Constructor for this object 

onlinegbtmsfiller := subsequence()
{
    
# Define private data and functions. Self is already available since this
# is a subsequence.  Self is automatically returned.

    private:=[=];

    # it has a private filler
    private.itsFiller := gbtmsfiller();
    private.liveFiller := F;

    # flags for actions which are pending
    private.pendingUpdate := F;
    private.pendingSuspend := F;

    # is it alive (in private.golive), or filling
    private.itsAlive := F;

    # its current state, either "filling", "idle", "suspended", or "done"
    private.itsState := "suspended";

    # things to do, possible things are currently : update, suspend, newms, done
    private.todo := as_string([]);

    # the permanent (handler) whenever
    private.handlerWhenever := as_integer([]);

    # the backend whenevers
    private.backendWhenevers := as_integer([]);

    # it starts out without a GUI
    private.gui := F;

    # the top-level data directory - initially unset
    private.datatop := unset;
    # projects found here - initially unset
    private.projects := unset;

    # keep the project current set here - initially, this will not reflect the
    # state of the filler, but thats okay
    private.project := unset;

    # event handlers
    private.handlers := [=];

    # this function is called whenever datatop changes and also on request.
    # It updates the list of probable project directories found immediately
    # under datatop.  A project directory is any directory under datatop
    # which itself contains a filed name ScanLog.fits.  If datatop is
    # unset, then projects will be unset.
    private.refreshprojects := function() {
	wider private;
	private.projects := unset;
	result := F;
	if (!is_unset(private.datatop)) {
	    # this can only be true if datatop is already known to be a direct.
	    projects := as_string([]);
	    dirs := dos.dir(private.datatop,types='d');
	    for (dir in dirs) {
		scanLog := dos.fullname(spaste(private.datatop,'/',dir,'/ScanLog.fits'));
		if (dos.fileexists(scanLog) &&
		    dc.whatis(scanLog).type == "FITS") {
		    # we have a winner
		    projects[len(projects)+1] := dir;
		}
	    }
	    private.projects := projects;
	    result := T;
	}
	return result;
    }
    
    # set the top-level data directory 
    # - this also always invokes refreshprojects
    private.setdatatop := function(newcandidate) {
	wider private;
	# make it unset to start with
	private.datatop := unset;
	if (dos.fileexists(newcandidate) && 
	    dos.filetype(newcandidate) == 'Directory') {
	    # looks good
	    private.datatop := newcandidate;
	}
	# this always unsets the project as well
	private.project := unset;
	return private.refreshprojects();
    }

    private.setState := function(newState) {
	wider private;
	if (private.itsState != newState) {
	    private.itsState := newState;
	    private.handlers.state();
	    if (!is_agent(private.liveFiller)) {
		# this is only seen internally, and only when done is seen while its alive
		# this ensures that the golive loop will stop
		private.itsState := 'suspended';
	    } else {
		if (private.itsState != 'filling') private.itsAlive := F;
	    }
	}
	return T;
    }

    private.suspend := function() {
	wider private;
	private.setState('suspended');
	if (is_agent(private.liveFiller)) private.liveFiller->suspend();
	# deactivate the backend monitors
	deactivate private.backendWhenevers;
	private.pendingSuspend := F;
	return T;
    }

    private.done := function() {
	if (is_agent(private.liveFiller)) private.liveFiller->suspend();
	private.setState('done');
	private.handlers.state();
    }

    # athe todo list handler
    private.handleTodo := function() {
	if (len(private.todo) > 0) {
	    wider private;
	    # possible items are "update", "done", "suspend", "newms"
	    todoList := private.todo;
	    # reset it right away to make it unlike that it gets extended while handling
	    private.todo := as_string([]);
	    
	    # if there is a done or suspend, do it and return
	    if (any(todoList == 'done')) {
		private.done();
	    } else if (any(todoList == 'suspend')) {
		private.suspend();
	    } else {
		# if there is a newms
		if (any(todoList) == 'newms') {
		    private.itsFiller.newms();
		}
		if (any(todoList) == 'update') {
                    self->update(T);
		    if (is_agent(private.liveFiller)) {
			private.liveFiller->update();
			# emit an update event
			self->update();
		    } else {
			private.itsFiller.update();
		    }
		    private.pendingUpdate := F;
		}
	    }
	}
    }

    # set up the permanent event handlers
    
    # the backend monitors, if we know about ygor
    private.agents := [=];
    # try and include ygor.g
    if (!is_defined('ygor') && strlen(which_include('ygor.g')) > 0) {
	ok := eval('include \"ygor.g\"');
	if (is_fail(ok)) {
	    note('unexpected failure in including ygor.g',
		 origin='onlinegbtmsfiller', priority='SEVERE');
	}
    }

    # the state event handler
    private.stateEvent := function(theValue) {
	# sanity - check for a true value
	if (is_string(theValue)) {
	    if (any(theValue ~ m/Ready/)) {
		private.handlers.update();
	    } # otherwise, we ignore it
	} else {
	    return throw('Unexpected scanLogEntry event value :', as_string(theValue),
			 origin='onlinegbtmsfiller');
	}
    }
	
    if (is_defined('ygor')) {
	# just register the ScanCoordinator
	private.agents.ScanCoordinator := ygor("ScanCoordinator");
	# register the state event and set up the whenever for it
	private.agents.ScanCoordinator.regValue("state");
	whenever private.agents.ScanCoordinator->state do {
	    private.stateEvent($value);
	}
	private.backendWhenevers[len(private.backendWhenevers)+1] := 
		last_whenever_executed();
	deactivate private.backendWhenevers;
    } else {
	note('unable to monitor ScanCoordinator, no ygor found',
	     origin='onlinegbtmsfiller', priority='WARN');
    }

    # emit the state string
    private.handlers.state := function(...) {
	wider private;
	self->state(private.itsState);
    }

    # emit the list of apparently available projects
    private.handlers.projects := function(...) {
	wider private;
	self->projects(private.projects);
    }

    # emit the current top data directory, okay at any tiem
    private.handlers.datatop := function(...) {
	wider private;
	result := private.datatop;
	if (!is_unset(result)) result := dos.fullname(result);
	self->datatop(result);
    }

    # set the current top data directory
    private.handlers.setdatatop := function(...) {
	wider private;
	result := F;
	if (private.itsState != "suspended") {
	    note('Unable to change the top data directory because the filler has not been suspended',
		 origin='onlinegbtmsfiller->setdatatop', priority='SEVERE');
	} else {
	    if (num_args != 1) {
		note('setdatatop requires 1 argument',
		     origin='onlinegbtmsfiller->setdatatop', priority='SEVERE');
	    } else {
		newDatatop := nth_arg(1,...);
		result := private.setdatatop(newDatatop);
		if (!result) 
		    note(newDatatop,' does not exist or is not a directory',
			 origin='onlinegbtmsfiller->setdatatop', priority='SEVERE');
	    }
	}
	self->setdatatop(result);
    }

    # refresh the projects
    private.handlers.refreshprojects := function(...) {
	self->refreshprojects(private.refreshprojects());
    }

    # what is the currently selected project, this is okay at any time
    private.handlers.project := function(...) {
	wider private;
	self->project(private.project);
    }

    # set the project, this is only okay if the filler has been suspended
    private.handlers.setproject := function(...) {
	wider private;
	result := F;
	if (private.itsState != "suspended") {
	    note('Unable to change the project because the filler has not been suspended',
		 origin='onlinegbtmsfiller->setproject', priority='SEVERE');
	} else {
	    # only set the project if its in the known list of projects
	    # we can't do this unless there are projects known 
	    if (is_unset(private.projects)) {
		note('There are no available projects in the current top-level DATA directory',
		     origin='onlinegbtmsfiller->setproject', priority='SEVERE');
	    } else {
		if (num_args != 1) {
		    note('setproject requires 1 argument',
			 origin='onlinegbtmsfiller->setproject', priority='SEVERE');
		} else {
		    newProject := nth_arg(1,...);
		    if (is_string(newProject) && any(private.projects == newProject)) {
			# let the filler have a go at it, in order to get to here, project.datatop must be set
			fullProject := dos.fullname(spaste(private.datatop,'/',newProject));
			result := private.itsFiller.setproject(fullProject);
			if (result) {
			    # the filler likes it, go with it
			    private.project := newProject;
			    result := T;
			} else {
			    note('Unexpectedly failed to set project to ', newProject,' in ', private.datatop,
				 origin='onlinegbtmsfiller->setproject', priority='SEVERE');
			}
		    }
		}
	    }
	}
	self->setproject(result);
    }

    # what is the current MS directory, this is okay at any time
    private.handlers.msdirectory := function(...) {
	self->msdirectory(private.itsFiller.msdirectory());
    }

    # set the MS directory, this is only okay if the filler has been suspended
    private.handlers.setmsdirectory := function(...) {
	wider private;
	result := F;
	if (private.itsState != "suspended") {
	    note('Unable to change the MS directory because the filler has not been suspended',
		 origin='onlinegbtmsfiller', priority='SEVERE');
	} else {
	    result := private.itsFiller.setmsdirectory(dos.fullname(...));
	}
	self->setmsdirectory(result);
    }

    private.handlers.fillrawpointing := function(...) {
	self->fillrawpointing(private.itsFiller.fillrawpointing());
    }

    private.handlers.setfillrawpointing := function(...) {
	self->setfillrawpointing(private.itsFiller.setfillrawpointing(...));
    }

    private.handlers.fillrawfocus := function(...) {
	self->fillrawfocus(private.itsFiller.fillrawfocus());
    }

    private.handlers.setfillrawfocus := function(...) {
	self->setfillrawfocus(private.itsFiller.setfillrawfocus(...));
    }

    private.handlers.filllags := function(...) {
	self->filllags(private.itsFiller.filllags());
    }

    private.handlers.setfilllags := function(...) {
	self->setfilllags(private.itsFiller.setfilllags(...));
    }

    private.handlers.vv := function(...) {
	self->vv(private.itsFiller.vv());
    }

    private.handlers.setvv := function(...) {
	self->setvv(private.itsFiller.setvv(...));
    }

    private.handlers.smooth := function(...) {
	self->smooth(private.itsFiller.smooth());
    }

    private.handlers.setsmooth := function(...) {
	self->setsmooth(private.itsFiller.setsmooth(...));
    }

    private.handlers.usehighcal := function(...) {
	self->usehighcal(private.itsFiller.usehighcal());
    }

    private.handlers.setusehighcal := function(...) {
	self->setusehighcal(private.itsFiller.setusehighcal(...));
    }

    private.handlers.more := function(...) {
	self->more(private.itsFiller.more());
    }

    private.handlers.fillnext := function(...) {
	self->fillnext(private.itsFiller.fillnext(async=T));
    }

    private.handlers.status := function(...) {
	self->status(private.itsFiller.status());
    }

    # go live
    private.handlers.golive := function(...) {
	wider private;
	# ignore this if we already are live
	if (private.itsAlive) return T;

	# don't go live if project is unset
	if (is_unset(private.project)) {
	    note('A project must be selected before real-time filling can begin',
		 origin='onlinegbtmsfiller->golive', priority='SEVERE');
	    return F;
	}

	# indicate that we are live
	private.itsAlive := T;
	# first, are we good to go
	if (!private.itsFiller.isattached() ||
	    !dos.fileexists(private.itsFiller.msdirectory())) {
	    # it would also be good to check that output MSs can be made in msdirectory
	    # perhaps leave that job to the filler DO via setmsdirectory
	    # no, emit a warning and keep sleeping
	    note('Unable to fill in real-time no scan log or output MS directory',
		 origin='onlinegbtmsfiller', priority='SEVERE');
	    private.itsState := 'suspended';
	    private.itsAlive := F;
	    return F;
	}
	# okay, go to idle state
	private.itsState := 'idle';
	private.handlers.state();

	# update - to be sure we are in sync
	self->update();
	private.itsFiller.update();

	# turn on monitoring of the backends
	activate private.backendWhenevers;

	if (is_agent(private.liveFiller)) {
	    private.liveFiller->golive();
	} else {
	    # any more scans to fill
	    while (private.itsFiller.more() && private.itsState != 'suspended') {
		# go to filling status
		private.itsState := 'fill';
		private.handlers.state();
		# emit the next status
		self->status(private.itsFiller.status());
		# fill the scan
		private.itsFiller.fillnext();
		# handle the todos
		private.handleTodo();
		# and emit the ms status
		self->msstatus(private.itsFiller.status());
	    }
	    # mark this here because after we've started handling the todo list
	    # golive will need to be restarted
	    # there may be an awkward part here when the todos are being handled
	    # and golive is still running - we'll see.
	    private.itsAlive := F;
	    # handle the todo list one more time
	    private.handleTodo();
	    # if the previous didn't set the state to suspended, set it to idle
	    if (private.itsState != 'suspended') {
		private.itsState := 'idle';
		private.handlers.state();
	    }
	}
	return T;
    }

    # update events
    private.handlers.update := function(...) {
	wider private;
	# various cases
	# suspended, do nothing
	if (private.itsState == 'suspended') return T;

	# simplest, an update is pending
	if (private.pendingUpdate) {
	    # itsAlive should be true, if not, then it needs to be restarted
	    if (!private.itsAlive) 
		private.handlers.golive();
	    # otherwise we can ignore this
	} else {
	    # if we are alive, add it to the todos
	    if (private.itsAlive) {
		# if we are idle, that means the live filler is running
		if (private.itsState == "idle" && 
		    is_agent(private.liveFiller)) {
		    private.liveFiller->update();
		    self->update();
		} else {
		    private.todo[len(private.todo)+1] := 'update';
		    private.pendingUpdate := T;
		}
	    } else {
		# otherwise go live
		private.handlers.golive();
	    }
	}
	return T;
    }

    # suspend events
    private.handlers.suspend := function(...) {
	wider private;
	# various cases
	# suspended or suspended pending, do nothing
	if (private.itsState == 'suspended' ||
	    private.pendingSuspend) return T;

	# if we are alive, add it to the todos
	if (private.itsAlive) {
	    private.todo[len(private.todo)+1] := 'suspend';
	    private.pendingSuspend := T;
	} else {
	    # we must be idle, do the suspend
	    private.suspend();
	}
	return T;
    }

    # newms events
    private.handlers.newms := function(...) {
	wider private;
	# various cases
	# if its alive, add it to the todos
	if (private.itsAlive) {
	    private.todo[len(private.todo)+1] := 'newms';
	    # any number of them can be in the todo list, don't mark it as pending
	} else {
	    # we're in a lull, do it
	    private.itsFiller.newms();
	    # if we're idle, this triggers a new golive()
	    if (private.itsState == 'idle') private.golive();
	}
	return T;
    }

    # a done event
    private.handlers.done := function(...) {
	wider private;
	# deactivate all of the whenevers
	deactivate private.backendWhenevers;
	deactivate private.handlerWhenever;
	# various cases
	# if its alive, add it to the todos
	if (private.itsAlive) {
	    private.todo[len(private.todo)+1] := 'done';
	} else {
	    # just do it
	    private.done();
	}
    }
	
    # and the whenever to invoke them
    whenever self->* do {
	if (has_field(private.handlers,$name)) {
	    private.handlers[$name]($value);
	} else {
	    note(spaste('Unrecognized event :',$name),
		 origin='onlinegbtmsfiller', priority='SEVERE');
	}
    }
    private.handlerWhenever := last_whenever_executed();

    # finally, set the top data directory and MS directory using
    # the appropriate aipsrc values and defaults.  It would be nice
    # if I could query something common with M&C to find out where
    # they are really writing to.  Or perhaps greb a common environment variable.
    drc.find(datatop,'gbt.msfiller.datatop',def='/home/gbtdata');
    # this is just a guess on my part at this point - no such directory
    # has as yet been agreed to or created
    drc.find(msdirectory,'gbt.msfiller.msdirectory',def='/home/gbtms');
    private.setdatatop(datatop);
    private.handlers.setmsdirectory(msdirectory);

    # generate the gui
    self.gui := function() {
	wider private;
	if (is_boolean(private.gui)) {
	    # the GUI uses only public functions and is itself an
	    # agent which receives events from this tool
	    private.gui := onlinegbtmsfillergui(self);
	} else {
	    self->gui();
	}
    }

    private.liveFiller := livegbtmsfiller(private.itsFiller);
    whenever private.liveFiller->msstatus do { 
	self->msstatus($value);
	private.handleTodo();
    }
    whenever private.liveFiller->status do { 
	self->status($value);
    }
    whenever private.liveFiller->state do { 
	private.setState($value);
	private.handleTodo();
    }

    # report on the type of tool for the tool managers benefit
    self.type := function() { return "onlinegbtmsfiller";}

    # end gracefully and render this agent useless
    self.done := function() {
	wider private;
 	private.done();
    }

    self.debug := function() { wider private; return private;}
}


# and make one
of := onlinegbtmsfiller();
of.gui();
