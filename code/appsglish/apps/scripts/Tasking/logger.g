# logger.g: a glish convenience script for logging 
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
# $Id: logger.g,v 19.2 2004/08/25 02:03:07 cvsmgr Exp $

pragma include once

include 'quanta.g'

# make sure there isn't already a defaultlogger with the required interface
# this should NEVER be the case if the user starts up a standard aips++, but
# I'm not sure there's a way to check on that.  Require a minimal interface,
# note and log.

if (is_defined('defaultlogger') && is_record(defaultlogger) &&
    has_field(defaultlogger,'note') && has_field(defaultlogger, 'log')) {
    # make sure there is an associated dl, if there isn't one already
    # but don't make any of this const, thats the responsiblity of whomever
    # provided the other logger in the first place
    if (!is_defined('dl')) dl := ref defaultlogger;
} else {

    # Make a dummy logger that just queues message until the real logger
    # is ready. Needed because the logger is needed by some of the things
    # it includes.
    #------------------------------------------------------------------------
    defaultlogger := [=];
    defaultlogger.time := "";
    defaultlogger.priority := "";
    defaultlogger.message := "";
    defaultlogger.origin := "";
    defaultlogger.postglobally := T;
    defaultlogger.postlocally := T;

    defaultlogger.log := function(timeString='',priority,message,origin=[=],
                                  postglobally=T, postlocally=T, postcli=F)
    {
	global defaultlogger;

	if (length(message) > 1) message := paste(message);
	which := length(defaultlogger.time) + 1;
	if(length(timeString) == 0 || timeString=='') {
	    timeString := dq.time(dq.quantity('today'),
				  prec=6, form="dmy local");
	}
	defaultlogger.time[which] := timeString;
	defaultlogger.priority[which] := priority;
	defaultlogger.message[which] := message;
	if (len(origin)==0) {
	    defaultlogger.origin[which] := '';
	} else {
	    defaultlogger.origin[which] := origin;
	}
	defaultlogger.postglobally[which] := postglobally;
	defaultlogger.postlocally[which] := postlocally;
	if (postcli) {
	    print spaste(priority, ': ', message);
	}
    }

    defaultlogger.note := function(..., origin='logger::note()',
				   postglobally=T,
				   postlocally=T, postcli=F)
    {
	global defaultlogger;
	string := "";
	if (num_args(...) > 0) {
	    for (i in 1:num_args(...)) {
		string := paste(string, as_string(nth_arg(i, ...)));
	    }
	}
	defaultlogger.log('', 'NORMAL', string, origin, postcli=postcli);
    }
    #------------------------------------------------------------------------

    if (! is_defined("global_use_gui")) {
	global_use_gui := [=];
    }

    const logger := function(use_gui=global_use_gui)
    {
	include "logsink.g";
	include "aipsrc.g";
	include "logtable.g";

	public := [=];    # Public member functions
	public::print.limit := 1;	
	self   := [=];    # Private data
	self.textsink := textlogsink();
	public.time := "";
	public.priority := "";
	public.message := "";
	public.origin := "";

	self.use_gui := F;

	# We need to look up a couple of aipsrc variables

	# If logger.file == "none" do not log to a log table, otherwise
	# we do.
	desired := "";
	found := drc.find(desired, "logger.file");
	if (found && (desired == 'none')) {
	    defaultlogger.note('Logging to a file is NOT enabled.',
			       origin='::logger()');
	}
	self.logtable := logtable();
	self.tzoffset := drc.tzoffset();
	# Find out if we want glish input/output/both logged.
	found := drc.find(desired, "logger.glish");
	if (!found) {
	    desired := "input";
	}    
	self.loginput := F;
	self.logoutput := F;
	if (desired == "input") {
	    self.loginput := T;
	} else if (desired == "output") {
	    self.logoutput := T;
	} else if (desired == "both") {
	    self.loginput := T;
	    self.logoutput := T;
	} else if (desired == "none") {
	    # nothing
	} else {
	    defaultlogger.log('', 'SEVERE', 
		spaste('.aipsrc: logger.glish must be input,output, or both, not ', 
		       desired), 'logger()');
	}

	# Find out the height for the gui and the columns to show.
	drc.findint(self.height, "logger.height", 8);
	self.widths := [0,0,0,0];
	drc.findint(self.widths[1], "logger.timewidth", 20);
	drc.findint(self.widths[2], "logger.prioritywidth", 6);
	drc.findint(self.widths[3], "logger.messagewidth", 75);
	drc.findint(self.widths[4], "logger.originwidth", 25);
	drc.find(self.show, "logger.guishow", 'time,priority,message');
	drc.findbool(self.showbuttons, "logger.showbuttons", T);
	drc.findbool(self.autoscroll, "logger.autoscroll", T);
	drc.find(self.background, "logger.background", "xing");

	# See if the user defined the logsink to use it in aipsrc
	found := drc.find(desired, "logger.default");

	# The initialization rules are:
	#   use_gui numeric and T, and have_gui() - use a gui; otherwise
	#   aipsrc value set - use it; otherwise
	#   have_gui() T, use gui

	if (is_numeric(use_gui)) {
	    if (have_gui() && use_gui) {
		self.use_gui := T;
	    } else {
		self.use_gui := F;
	    }
	} else if (found) {
	    if (have_gui() && desired=="gui") {
		self.use_gui := T;
	    } else {
		self.use_gui := F;
	    }
	} else {
	    if (have_gui()) {
		self.use_gui := T;
	    } else {
		self.use_gui := F;
	    }
	}

	if (self.use_gui) {
	    self.guisink := guilogsink(F, self.height, self.widths,
				       self.show,
				       self.autoscroll, self.showbuttons,
				       self.background,
				       0, '', self.tzoffset);
	    if (is_fail(self.guisink)) fail;
	} else {
	    self.guisink := F;
	}

	self.makequery := function(expr)
        {
	    query := '';
	    if (len(expr) >= 1  && strlen(expr[1]) > 0) {
		query := paste('where', expr[1]);
	    }
	    if (len(expr) >= 2  && strlen(expr[2]) > 0) {
		query := paste(query, 'orderby', expr[2]);
	    }
	    return query;
	}

	self.deactivategui := function(id) {
	    wider self;
	    self.use_gui := F;
	    self.guisink.deactivate();
	    return T;
	}

	public.gui := function(parent=F, title=unset, widgetset=dws) {
	    wider self;
	    if (have_gui()) {
		self.use_gui := T;
		if (!is_record(self.guisink) || !self.guisink.isactive()) {
		    self.guisink := guilogsink(parent,
					       self.height, self.widths,
					       self.show, self.autoscroll,
					       self.showbuttons,
					       self.background, 0, '',
					       self.tzoffset, 0,
					       widgetset, title);
		    public.register_callbacks(self.guisink);
		    self.guisink.activate();
		    if (has_field(public, "loginput") && has_field(self, "loginput")) {
			public.loginput(self.loginput);
		    }
		}
		return T;
	    } else {
		self.use_gui := F;
		self.guisink := F;
		return F;
	    }
	}

	public.screen := function() {
	    wider self;
	    self.guisink.dismiss();
	    return T;
	}

	public.note := function(..., origin='logger::note()', postglobally=T,
				postlocally=T, postcli=F)
	{
	    string := "";
	    if (num_args(...) > 0) {
		string := paste(...);
	    }
	    chars := split(string,'');
	    if (length(chars)>0 && chars[length(chars)] == '\n') {
		string := "";
		for (i in 1:(length(chars)-1)) {
		    string := spaste(string, chars[i]);
		}
	    }
	    string := spaste(string);
	    return public.log('', 'NORMAL', string, origin=origin,
		  	      postglobally=postglobally,
			      postlocally=postlocally,
			      postcli=postcli);
	}

	public.attach := function(logfile=unset)
	{
	    desired := "";
	    filenm := "";
	    if (is_string(logfile)) {
	      filenm := logfile;
	    } else {
	      desired := "";
	      found := drc.find(desired, "logger.file", "aipsrc.log");
	      if (desired != "none") {
		if (desired ~ m%^/%) {
		  filenm := desired;
	        } else {
		  aipspath:=split(environ.AIPSPATH)[1];
		  filenm := paste (aipspath, desired, sep='/');
	        }
	      }
	    }
	  return self.logtable.attach (filenm);
	}

	public.loginput := function(dolog = T)
	{
	  wider self;
	  self.loginput := dolog;
	  global system;
	  if (dolog) {
	    if (!has_field(system, "output")) {
	      system.output := [=];
	    }
	    system.output.ilog := function(message) {
	      wider self;
	      public.note(paste('>', paste(message,sep='')), 
			  postlocally=system.output.ilog::use_gui);
	      if (is_record(defaultservers)&&
		  has_field(defaultservers, 'memory')&&
		  is_record(defaultservers.memory())&&
		  has_field(defaultservers.memory(), 'chart')) {
		defaultservers.memory().chart('Glish', alloc_info().used/1024.0/1024.0);
	      }
	    }
	    system.output.ilog::use_gui := self.use_gui;
	  } else {
	    if (has_field(system, "output")) {
	      system.output.ilog := F;
	    }
	  }
	  return dolog;
	}

	public.logoutput := function(dolog = T)
	{
	    wider self;
	    self.logoutput := dolog;
	    global system;
	    if (dolog) {
		if (!has_field(system, "output")) {
		    system.output := [=];
		}
		system.output.olog := function(message) {
		    wider self;
		    public.note(paste('<', paste(message,sep='')), 
				postlocally=system.output.olog::use_gui);
		}
		system.output.olog::use_gui := self.use_gui;
	    } else {
		if (has_field(system, "output")) {
		    system.output.olog := F;
		}
	    }
	    return dolog;
	}

	
	public.nmessages := function()
	{
	    wider self;
	    if (is_record(self.logtable)) {
		return self.logtable.nmessages();
	    } else {
		return 0;
	    }
	}


	public.purge := function(keeplast=500, expr='') {
	    wider self;
	    if (is_record(self.logtable)) {
		if (! self.logtable.purge(keeplast, self.makequery(expr))) {
		    return F;
		}
		if (is_record(self.guisink)) {
		    self.guisink.inittext(T);
		}
	    }
	    return T;
	}

	public.printtofile := function(num=-1, filename='',
				       colwidth=[-1,-1,-1,-1],
				       expr='', ascommand=F)
	{
	    if (is_record(self.logtable)) {
		return self.logtable.printtofile(num, filename, colwidth,
						 self.makequery(expr),
						 ascommand);
	    } else {
		return 'no logtable';
	    }
	}

	public.handlequery := function(height, widths, show, autoscroll,
				       showbuttons, background,
				       level, expr, id, widgetset, title)
        {
	    ag := guilogsink(F, height, widths, show, autoscroll, showbuttons,
			     background, level+1, expr, self.tzoffset,
			     id, widgetset, title);
	    public.register_callbacks(ag);
	    return ag;
	}

	public.getformatted := function(ref time, ref priority, ref
					messages, ref origin, howmany=-1, 
					expr='', concat=F)
	{
	    wider self;
	    if (is_record(self.logtable)) {
		return self.logtable.getformatted(time, priority, messages,
						  origin, howmany,
						  self.makequery(expr),
						  concat);
	    } else {
		return F;
	    }
	}
	

	public.log := function(timeString='', priority, message, origin=[=],
			       postglobally=T, postlocally=T, postcli=F) {

	    if (length(message) > 1) message := paste(message);

	    wider self;
	    if (! is_string(timeString)) timeString := as_string(timeString);
	    if(length(timeString) == 0 || timeString=='') {
		timeString := dq.time(dq.quantity('today'),
				      prec=6, form="dmy local");
	    }
	    if (postlocally) {
		if (self.use_gui) {
		    self.guisink.write(timeString, priority, message,
				       paste(origin));
		    if (postcli) {
			print spaste(priority, ': ', message);
		    }
		} else {
		    self.textsink.write(timeString, priority, message,
					paste(origin));
		}
	    }
	    if (postglobally && is_record(self.logtable)) {
		self.logtable.addmessages(message, priority=priority, 
					  location=paste(origin));
	    }
	    return T;
	}

	public.verbose := function(show_time=T,show_priority=T,show_origin=T)
	{
	    wider self;
	    if (is_record(self.guisink)) {
		self.guisink.setshow(show_time, show_priority, show_origin);
	    }
	    self.textsink.setshow(show_time, show_priority, show_origin);
	    return T;
	}

	public.brief := function(show_time=F,show_priority=F,show_origin=F)
	{
	    return public.verbose (show_time, show_priority, show_origin);
	}

	public.register_callbacks := function(gui)
	{
	    wider self;
	    if (is_record(gui)) {
		gui.set_deactivate_callback(self.deactivategui);
		gui.set_refill_callback(public.getformatted);
		gui.set_nmessages_callback(public.nmessages);
		gui.set_purge_callback(public.purge);
		gui.set_printtofile_callback(public.printtofile);
		gui.set_query_callback(public.handlequery);
	    }
	}

	public.type := function()
	{
	    return 'logger';
	}

	public.loginput(self.loginput);
	public.logoutput(self.logoutput); # 

	public.register_callbacks(self.guisink);
	return public;
    }



    # Make the logger
    const dl:=logger();

    # Copy over the queued messages
    local i;
    for (i in ind(defaultlogger.time)) {
	if (strlen(defaultlogger.origin[i]) > 0) {
	    dl.log(defaultlogger.time[i], defaultlogger.priority[i], defaultlogger.message[i],
		   defaultlogger.origin[i], defaultlogger.postglobally, 
		   defaultlogger.postlocally);
	} else {
	    dl.log(defaultlogger.time[i], defaultlogger.priority[i], defaultlogger.message[i],
		   [=], defaultlogger.postglobally, 
		   defaultlogger.postlocally);
	}
    }
    # Make defaultlogger a reference for dl
    const defaultlogger:=ref dl;
    defaultlogger.log('', 'NORMAL', 'defaultlogger (dl) ready', 'logger');

    # Add defaultlogger to the GUI if necessary
    if (any(symbol_names(is_record)=='objrepository') &&
	has_field(objrepository, 'notice')) {
	objrepository.notice('defaultlogger', 'logger');
    }
}
