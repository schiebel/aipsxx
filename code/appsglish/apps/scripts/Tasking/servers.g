# servers.g: Access to servers in the Distributed Object (Tasking) System.
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
#        Postal address: APS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: servers.g,v 19.2 2004/08/25 02:04:39 cvsmgr Exp $

# Not generally intended to be used by end users.

pragma include once
    
include 'note.g';
include 'timer.g';

global defaultservers;

# List which servers can create and run which classes:

const server_controller := subsequence() {
  private := [=];     # private data & functions
  private.suspend := F;
  private.trace := F;
  private.progress := [=];
  private.includesdone := F;
  private.nummemoryclients := 0; # No memory events are sent if this is zero
  private.servermemory := [=];   # A cache of the memory used by each server
  private.memory_last := time(); # Used the limit the rate at which 
                                 # memory events are sent. 
  private.plotters := [=];
  
  # Timeouts for various events: <= to disable timeout
  private.timeout := [=];
  private.timeout.create := -1;
  private.timeout.close := 10;
  private.timeout.done := 10;
  private.timeout.makeplot := 60;
  
  private.mytimer := client('timer');
  
  # Required clients: a failure to start one of these will cause
  # an exit!
  private.requiredClients := "misc timer quanta measures";
  private.prestarts := [=];
  
  # We use this as a staging post for events that should 
  # be visible outside.
  private.alert := subsequence() {
    whenever self->jobfinished do {
      if (is_record($value)&&has_field($value, 'value')) {
	self->[as_string($value.value)]($value);
      }
    }
    whenever self->joberror do {
      self->error($value);
    }
    whenever self->jobfail do {
      self->fail($value);
    }
    whenever self->jobnote do {
      self->note($value);
    }
    whenever self->jobactivate do {
      self->activate();
    }
    whenever self->jobterminate do {
      self->terminate();
    }
    whenever self->jobcreate do {
      self->create();
    }
    whenever self->jobadd do {
      self->add();
    }
  }
  private.alerter := private.alert();
  
  private.pushwhenevers := function(id) {
    wider private;
    index := len(private.agents[id].whenevers)+1
      private.agents[id].whenevers[index]:=last_whenever_executed();
    return T;
  }
  
  # Use this to see if a given job has finished
  self.alerter := function() {return ref private.alerter;}
  
  # start by just queuing up log messages
  private.logger.time := "";
  private.logger.priority := "";
  private.logger.message := "";
  private.logger.origin := "";
  private.logger.postglobally := T;
  private.logger.postlocally := T;
  
  # This might be a generally useful function. Turn a glish value
  # (array, record) into a single string.
  private.format := function(v,max_array_length=10) {
    returnval := '';
    if (is_record(v)) {
      names := field_names(v);
      if (length(names) == 0) {
	returnval := '[=]';
      } else {
	returnval := '[';
	l := names[length(names)];
	for (i in names) {
	  # recurse
	  if (i != l) {
	    returnval := paste(returnval, i, '=', private.format(v[i]),
			       ' ', sep='');
	  } else {
	    returnval := paste(returnval, i, '=', private.format(v[i]),
			       sep='');
	  }
	}
	returnval := paste(returnval, ']', sep='');
      }
    } else {
      returnval := '[';
      l := length(v);
      if (l > max_array_length) {
	for (i in 1:max_array_length) {
	  returnval := paste(returnval, ' ',as_string(v[i]),sep='');
	}
	returnval := paste(returnval, ' ... ', 
			   as_string(l - max_array_length), ' more elements');
      } else if (l == 1) { 
	return as_string(v);
      } else if (l) {
	for (i in 1:length(v)) {
	  if (i != l) {
	    returnval := paste(returnval, ' ',as_string(v[i]),sep='');
	  } else {
	    returnval := paste(returnval, as_string(v[i]),sep='');
	  }
	}
      }
      returnval := paste(returnval, ']', sep='');
    }
    return returnval;
  }
  
  # Print an invoke record by putting each field on its own line, 
  # ignoring fields that start with _, and putting returnval first.
  private.invokerecformat := function(value) {
    wider private;
    if (!is_record(value)) return private.format(value);
    
    retval := '';
    # OK, it is a record. Print returnval first
    if (has_field(value, 'returnval'))
      retval := spaste(retval, 'returnval=',
		       private.format(value['returnval']));
    for (i in field_names(value)) {
      if (split(i,'')[1] != '_' && i != 'returnval')
	retval := spaste(retval, '\n', i, '=', 
			 private.format(value[i]));
    }
    return retval;
  }
  
  private.agents := [=];# agent[i] is agent #i, has a .host and .server fields.

  ########
  # Convert server name (e.g. 'imager') to an agent number. 
  # Return -1 if not found
  private.find := function(server, host='') {
    wider private;
    if (length(private.agents) <= 0) {
      return -1;
    }
    for (i in 1:length(private.agents)) {
      if (is_agent(private.agents[i]) &&
	  split(private.agents[i].server, '#')[1] == server &&
	  private.agents[i].host == host) {
	return i;
      }
    }
    return -1;
  }
  
  ########
  # Count the number of servers of name (e.g. 'imager')
  private.count := function(server, host='') {
    # Return the numbers of a given server
    # found
    wider private;
    if (length(private.agents) <= 0) {
      return 0;
    }
    found := 0;
    for (i in 1:length(private.agents)) {
      if (is_record(private.agents[i]) &&
	  split(private.agents[i].server, '#')[1] == 
	  server && private.agents[i].host == host) {
	found +:=1;
      }
    }
    return found;
  }
  
  ########
  # Kill a server by id (an integer)
  private.done := function(id) {
    wider private;
    # "Delete" private.agents[id]
    if (has_field(private.agents[id], 'whenevers')) {
      deactivate private.agents[id].whenevers;
    }
    private.agents[id] := F;
    return T;
  }
  
  ########
  # Defer inclusion  
  private.deferredinclude := function() {
    wider private;
    if (!private.includesdone) {
      include 'progress.g';
      include 'choice.g';
      private.includesdone := T;
    }
  }
  
  ########
  # Return a record containing all agents
  self.agents := function() {
    wider private;
    return ref private.agents;
  }
#
# Get the plotter for a given tool
#
  self.hasplotter := function(id, name) {
    wider private;
    id   := as_string(id);
    name := as_string(name);
    return is_record(private.plotters[id]) &&
	is_record(private.plotters[id][name]);
  }
#
# Get the plotter for a given tool
#
  self.addplotter := function(id, name, mincolors=0, maxcolors=100,
			      size=[600, 450]) {
    wider private;
    include 'pgplotter.g';
    id   := as_string(id);
    name := as_string(name);
    if(!has_field(private.plotters, id)) {
      private.plotters[id] := [=];
    }
    if(any(field_names(private.plotters[id])==name)&&
       is_record(field_names(private.plotters[id][name]))) {
      return throw('defaultservers already has a plotter named ', name);
    }
    else {
#      note('Created plotter ', name, ' for server ', id);
      private.plotters[id][name] := pgplotter(name, mincolors=mincolors,
					      maxcolors=maxcolors, size=size);
      return T;
    }
  }
#
  self.getplotter := function(id=0, name='') {
    wider private;
    id := as_string(id);
    name := as_string(name);
    if(has_field(private.plotters, id)) {
      if(name!='') {
	if(has_field(private.plotters[id], name)&&
	   is_record(private.plotters[id][name])) {
	  return ref private.plotters[id][name];
	}
	else {
	  return throw('No plotters for this tool id ', id,
		       ' and name ', name);
	}
      }
      else {
	return ref private.plotters[id];
      }
    }
    else {
      return throw('No plotters for this tool id ', id);
    }
  }

  ########
  # Creates a new server if necessary, otherwise it just returns a reference
  # to an extant server. If a new server is started then the required
  # whenever's are created.
  self.activate := function(server, host='', forcenewserver = F, async=F,
			      terminateonempty=T) {
    global system;
    wider private;
    if (private.trace) {
      note(paste('server=', private.format(server), 'host=',
		 private.format(host), 'forcenewserver=',
		 private.format(forcenewserver)), 
	   priority='DEBUGGING', 
	   origin='servers.activate', postglobally=F);
    }
    
    # Do we need to create a new server?
    id := private.find(server, host);
    servernumber := private.count(server, host) + 1;
    if (forcenewserver || id <= 0) {
      # OK, we need to make a new server
      id := length(private.agents) + 1;
      # If a server aiprcs variable is set to an async string then
      # set the async flag := T, and set the command invocation to 
      # the aipsrc variable
      include 'getrc.g';
      local tmp
      if (getrc.find(tmp, spaste(server,'.async'))){
	async := T;
	system.asyncserver := tmp; 
      }
      # Actually create the server
      if (host != '') {
	note(paste('Starting server', private.format(server), 
		   'on host', private.format(host)),
	     priority='NORMAL', 
	     origin='servers.activate', postglobally=T);
	private.agents[id] := client(server, host=host, 
				     suspend=private.suspend, async=async);
	if (is_fail(private.agents[id])) {
	  errmsg := spaste('The server \'', server, 
			   '\' could not be started on host ',
			   private.format(host), '!\nThis probably means that',
			   ' the executable is missing or corrupt.\n',
			   'This denotes a severe problem with the remote ',
			   'installation which prevents any use.\n',
			   'Please contact your local AIPS++ support person.');
	  if (any(private.requiredClients)==client) {
	    print 'Failed to start a required client: exiting from AIPS++';
	    exit;
	  } else {
	    return throw(errmsg);
	  }
	}
      } else {
	note(paste('Starting server', private.format(server)), 
	     priority='NORMAL', 
	     origin='servers.activate', postglobally=T);
	private.agents[id] := client(server, suspend=private.suspend,
				     async=async);
	if (is_fail(private.agents[id])) {
	  errmsg := spaste('The server \'', server, 
			   '\' could not be started on host ',
			   private.format(host), '!\nThis probably means that',
			   ' the executable is missing or corrupt.\n',
			   'This denotes a severe problem with the ',
			   'installation which prevents any use.\n',
			   'Please contact your local AIPS++ support person.');
	  if (any(private.requiredClients)==client) {
	    print 'Failed to start a required client: exiting from AIPS++';
	    exit;
	  } else {
	    return throw(errmsg);
	  }
	}
	# Print it as well in case something *really* bad has happened.
      }
      if (async) {
	
	global system;
	# In principle an activate with async=T will only ever be
	#run for scripts that need to finish before an exit
	
	# split up the command
	ok := F;
	scommand := split(private.agents[id].activate);
	# Grab the path to the executable
	thepath := paste((split(environ.AIPSPATH))[1:2], sep='/');
	# Reassemble the fully qualified command
	command := paste(spaste(thepath, '/bin/', scommand[1]));

	# Now get how we're suppose to run mpi  on NCSA machines 'mpirun -np'
	# Could be invoked async for mpi so set up the mpirun command
	# first
	if (has_field(system, 'mpicommand')){
	  # Use a local executable in the mpirun command if it exists
	  # (cannot use dos.fileexists as that leads to circular dependencies)
          checklocal:= spaste('./', scommand[1]);
          if (length(stat(checklocal)) > 0) {
	    thepath:= '.';
          } else {
            thepath := spaste(thepath, '/bin');
          }
	  command := sprintf(system.mpicommand, system.numprocs[scommand[1]],
			     spaste(thepath, '/', scommand[1]),
			     paste(scommand[2:len(scommand)]));
	  note(command, origin='servers.activate');
	  print command, paste(scommand[2:len(scommand)]);
	  ok := T;
	} 
	if (has_field(system, 'asyncserver')){
	  command := sprintf(system.asyncserver, command, 
			     paste(scommand[2:len(scommand)]));
	  note(command, origin='servers.activate');
	  print command, paste(scommand[2:len(scommand)]);
	  ok := T;
	}
        if (!ok) {
	  command := private.agents[id].activate;
	  # Invoke the command and print any output from it
	  if (!(command~m/\'/))  { 
	    go1 := command ~ s/</\\</g;
	    go := go1 ~ s/>/\\>/g;
	    command := go ~ s/\*/\\*/g;
	  }
	} else {
	  # Invoke the command and print any output from it
	  if (!(command~m/\'/)) { 
	    go1 := command ~ s/</\\\</g;
	    go := go1 ~ s/>/\\\>/g;
	    command := go ~ s/\*/\\\*/g;
          }
	}
	private.prestarts[server] := shell(command, async=T);
	private.prestarts[server].server := server;
	whenever private.prestarts[server]->stdout, 
	  private.prestarts[server]->stderr do {
	    note($value, origin='servers.activate');
	}
      }
      if (! is_agent(private.agents[id])) {
	err := paste('Cannot start or execute server named:', server);
	return throw(err, origin='servers.activate');
      };
      
      # Record some generally useful information
      if (servernumber>1) {
	private.agents[id].server := spaste(server, '#', servernumber);
      } else {
	private.agents[id].server := server;
      }
      if (host!='') {
        private.agents[id].server := spaste(private.agents[id].server, '@', 
					   host);
      }
      
      private.agents[id].host := host;
      private.agents[id].busy := 0;
      private.agents[id].whenevers := [];
      private.agents[id].id := id;
      private.agents[id].terminateonempty := terminateonempty;
      private.agents[id].shouldstop := F;
      
      # So we can readily get back to ourselves from a whenever
      private.agents[id].private := ref private;
      
      # Setup per-agent whenevers
      whenever (private.agents[id])->error do {           # Error report
	$agent.private.alerter->joberror([agent=$agent, value=$value]);
	note(paste($value), priority='SEVERE',
	     origin='servers.activate', postglobally=F);
      } private.pushwhenevers(id);
      
      # We need to turn off busy with a whenever, in case the user
      # has typed a ^C. Otherwise, the server will always appear
      # to be busy
      whenever (private.agents[id])->run_result,
	(private.agents[id])->error do {
	$agent.busy -:= 1;
	if ($agent.busy < 0) {
	  $agent.busy := 0;
	}
      }  private.pushwhenevers(id);
      
      whenever (private.agents[id])->log do {           # Logging
	thisagent := $agent;
	thisvalue := $value;
	if (has_field(thisvalue, 'origin')) {
	  orig := thisvalue.origin;
	} else {
	  orig := thisagent.server;
	}                
	# Send a note event
	value := [message=thisvalue.message,
		  priority=thisvalue.priority,
		  origin=orig,
		  time=thisvalue.time_string,
		  server=thisagent.server];
	thisagent.private.alerter->jobnote([agent=$agent, value=value]);
	note(value.message, priority=value.priority,
	     origin=value.origin, time=value.time);
	if(is_record(thisvalue)&&has_field(thisvalue, '_memory')) {
	  private.servermemory[thisagent.server] := thisvalue._memory;
	}
	if (private.nummemoryclients > 0 &&
	    time() - private.memory_last > 1) {
	  private.servermemory.Glish := alloc_info().used/1024/1024;
	  private.memory_last := time();
	  self -> memory(private.servermemory);
	}
      } private.pushwhenevers(id);
      
      whenever (private.agents[id])->run_result_async do { # Async
	$agent.busy -:= 1;
	if ($agent.busy < 0) {
	  $agent.busy := 0;
	}
	if ($name == 'error') {
	  $agent.private.alerter->joberror([agent=$agent, value=$value]);
	  msg := spaste('Asynchronous job has an error:\n', $value);
	  note(paste(msg), priority='SEVERE',
	       origin='servers.activate', postglobally=F);
	} else if ($name == 'fail') {
	  $agent.private.alerter->jobfail([agent=$agent, value=$value]);
	  msg := spaste('Asynchronous job has failed:\n', $value);
	  print msg;
	  note(paste(msg), priority='SEVERE',
	       origin='servers.activate', postglobally=F);
	} else {
	  $agent.private.alerter->jobfinished([agent=$agent, value=$value._jobid]);
	  $agent.private.results[$value._jobid] := $value;
	  $agent.private.finished[$value._jobid] := T;
	  msg := spaste('Job #', $value._jobid, ' has finished\n');
	    note(msg, priority='NORMAL', origin='servers.activate');
	}
      } private.pushwhenevers(id);
      
      whenever (private.agents[id])->done do {          # Client terminated
	thisagent := $agent;
	if (has_field(thisagent, 'id')) {
	  thisagent.private.done(thisagent.id);
	  if (private.nummemoryclients > 0)
#	    print 'servers.whenever.done', private.nummemoryclients, thisagent.server;
	    self->remove(thisagent.server);
	  private.servermemory := 
	    private.servermemory[field_names(private.servermemory) != thisagent.server];
	}
	
	} private.pushwhenevers(id);
      
      whenever (private.agents[id])->memory do {
	thisagent := $agent;
	thisvalue := $value;
	private.servermemory[thisagent.server] := thisvalue;
	if (private.nummemoryclients > 0 &&
	    time() - private.memory_last > 1) {
	  private.servermemory.Glish := alloc_info().used/1024/1024;
	  private.memory_last := time();
	  self -> memory(private.servermemory);
	}
      } private.pushwhenevers(id);
      
      whenever (private.agents[id])->get_progress do {  # Progress create
	private.deferredinclude();
	agref := ref $agent;
	theval := $value;
	id := length(agref.private.progress) + 1;
	agref.private.progress[id] :=
	  progress(theval.min, theval.max,
		   theval.title, theval.subtitle, theval.minlabel,
		   theval.maxlabel, theval.estimate);
	if (is_fail(agref.private.progress[id])) {
	  msg := spaste('Failed to create progress meter because ', 
                        agref.private.progress[id]::message);
	  note(msg, priority='WARN', origin='servers.activate');
	}
	
	if (!is_record(agref.private.progress[id])) {
	  msg := spaste('Failed to create progress meter');
	  note(msg, priority='WARN', origin='servers.activate');
	}
	
	# Have to send event out even if progress failed - otherwise it hangs 
	agref->progress_result(id);
      } private.pushwhenevers(id);
      
      whenever (private.agents[id])->progress do {      # Progress track
	private.deferredinclude();
	id := $value.id;
	if (!is_fail($agent.private.progress[id])) {
	  ($agent.private.progress[id]).update($value.value);
	}
      } private.pushwhenevers(id);
      
      whenever (private.agents[id])->get_choice do {    # Choice
	private.deferredinclude();
	$agent->choice(choice($value.description, $value.choices));
      } private.pushwhenevers(id);
      
      whenever (private.agents[id])->get_stop do {    # Stop
	private.deferredinclude();
	if (has_field(private.agents[id], 'shouldstop')) {
	  $agent->stop(private.agents[id].shouldstop);
	  private.agents[id].shouldstop := F;
	}
      } private.pushwhenevers(id);

      whenever (private.agents[id])->get_hasGUI do {    # hasGUI
        $agent->hasGUI(have_gui());
      } private.pushwhenevers(id);
      
      whenever (private.agents[id])->makeplot do {      # Make a plotter
	id := $agent.id;
	name := $value.name;
	mincolors := $value.mincolors;
	maxcolors := $value.maxcolors;
        size := [$value.sizex, $value.sizey];
	me := $agent;
	ok := T;
	
	if(name=='') {
	  ok := 'No name has been specified for the plotter';
	}
	else {
	  global defaultservers;
	  if(!defaultservers.hasplotter(id, name)) {
	    # Timeout version uses an asynceval for the creation
	    if (private.timeout.makeplot>0) {
	      note('Submitting request to make a pgplotter ', name);
	      command := spaste('defaultservers.addplotter(id=', id,
				', name=\'',name,
				'\', mincolors=', mincolors,
				', size=', as_evalstr(size),
				', maxcolors=',maxcolors,')');
	      include 'asynceval.g';
	      private.asynceval['makeplot'] := asynceval();
	      private.timername['makeplot'] :=
		  private.mytimer->register(private.timeout.makeplot);
	      private.asynceval['makeplot']->run(command);
	      await private.asynceval['makeplot']->result,
		  private.mytimer->[private.timername['makeplot']];
	      private.mytimer->unregister(private.timername['makeplot']);
	      if ($name==private.timername['makeplot']) {
		errmsg :=
		    spaste('An attempt to create a pgplotter has failed.\n',
			   'This indicates an unexpected problem. We recommend you save your work and restart AIPS++.\n',
			   'Please submit a bug-report using bug() if you can reproduce the ',
			   'problem.');
		ok := spaste('Error creating plotter for ', name);
	      }
	      private.asynceval['makeplot'].done();
	    }
	    else {
	      defaultservers.addplotter(id, name,
					mincolors=mincolors,
					maxcolors=maxcolors,
					size=size);
	    }
	    if (!defaultservers.hasplotter(id, name)) { 
	      ok := spaste('Error creating plotter for ', name);
	    }
	  }
	  else {
	    # It exists, but does it have enough colors?
	    plotter := defaultservers.getplotter(id, name);
	    if(is_fail(plotter)) {
	      ok := spaste('Error obtaining plotter ', plotter::message)
		}
	    else {
	      qc := plotter.qcol();
	      if (mincolors > qc[2] - qc[1] + 1) {
		ok := spaste('Not enough colours in open plotter');
	      }
	    }
	  }
	}
	if (is_string(ok)) {
	  me->makeplot_error(msg);
	  throw(ok);
	} else {
	  note('Successfully made plotter ', name);
	  me->makeplot_result(T);
	}	    
      } private.pushwhenevers(id);
      
      whenever (private.agents[id])->plot do {           # Make a plot
	## Not very efficient yet, 2 copies are made!
	name := $value.name;
	plot := $value.plot;
	me := $agent;
	id := $agent.id;
	if (!defaultservers.hasplotter(id, name)) {
	  me->plot_error(spaste('No plotter named ',name, ' exists'));
	}
	else {
	  plotter := defaultservers.getplotter(id, name);
	  plotter.gui();
	  plotter.play(plot);
	  last := field_names(plot)[length(plot)];
	  if (has_field(plot[last], 'return')) {
	    me->plot_result(plot[last].return);
	  } else {
	    me->plot_result(T);
	  }
	}
      } private.pushwhenevers(id);
      
      whenever (private.agents[id])->view do {           # View a file
	name := $value.name;
	include 'catalog.g';
	dc.view(name);
      } private.pushwhenevers(id);
      
      # Turn on tracing if necessary
      if (private.trace) {
	(private.agents[id])->trace(private.trace);
      }
    }
    # Tell the world that something happened.
    self.alerter()->jobactivate();
    return id;
  }
  
  ########
  # Suspend a list of clients by name
  self.suspend := function(suspend_clients) {
    wider private;
    if (private.trace) {
      note(paste('suspend_clients=', suspend_clients), 
	   priority='DEBUGGING', origin='servers.suspend', 
	   postglobally=F);
    }
    private.suspend := suspend_clients;
  }
  
# Return the OLD value of the trace
  self.trace := function(trace_clients) {
#        print 'Tracing disabled until bug is found'
#        return F
    wider private;
    oldtrace := private.trace;
    private.trace := trace_clients;
    
    if (! is_boolean(trace_clients)) {
      fail 'servers.trace(trace_clients): trace_clients must be boolean';
    }
## Turn off infinite recurse
##	if (trace_clients) {
##	    note('Server Tracing turned ON', priority='DEBUGGING',
##			origin='servers.trace()');
##	} else {
##	    note('Server Tracing turned OFF', priority='DEBUGGING', 
##			origin='servers.trace()');
##	}
#	private.trace := trace_clients;
#        for (j in field_names(private.server_class_map)) {
#	    for (i in 1:length(private.server_class_map[j].agents)) {
#		(private.server_class_map[j].agents[i])->trace(trace_clients);
#	    }
#        }
    
    return oldtrace;
  }
  
  ########
  # Run a server asynchronously. The ref theagent is a 
  # record containing information on the actual server
  private.run_async := function(ref theagent, ref invokerecord) {
    wider private;
    if (theagent.busy) { return private.busy_error(theagent) }
    if (! has_field(private, 'results')) {
      private.results := [=];
      private.finished := F;
    }
    
    jobid := length(private.results) + 1;
    invokerecord._jobid := jobid;
    private.results[jobid] := 'Still running';
    private.finished[jobid] := F;
    note(spaste('Starting asynchronous Job#',jobid),
	 priority='NORMAL', origin='servers.run_async');
    theagent.busy +:= 1;
    theagent.shouldstop := F;
    theagent->run_async(invokerecord);
    return jobid;
  }
  
  ########
  # Server is busy
  private.busy_error := function(ref theagent) {
    wider private;
    err := paste('Cannot run: server', theagent.server, 'is already',
		 'executing another task. Please wait.');
    note(err, priority='SEVERE', origin='servers.busy_error',
	 postglobally=F);
    fail err;
  }
  
  ########
  # Server is done
  private.busy_error_done := function(ref theagent) {
    wider private;
    err := paste('Cannot terminate: server', theagent.server, 'is',
		 'executing. Please wait.');
    note(err, priority='SEVERE', origin='servers.busy_error_done',
	 postglobally=F);
    fail err;
  }
  
  ########
  # Kill a specific server (i.e. the whole process!)
  self.kill := function(agentid) {
    wider private;
    if (private.trace) {
      note(paste('Glish SEND kill, agentid=', agentid),
	   priority='DEBUGGING', origin='servers.kill', 
	   postglobally=F);
    }
    
    if (!self.isvalid(agentid)) {
      fail spaste('Illegal agent id: ', as_string(agentid),
		  ' Must be integer between 1 and ', 
		  as_string(length(private.agents)));
    }
    
    theagent := ref private.agents[agentid];
    note(paste('Killing server', theagent.server),
	 priority='WARN', origin='servers.kill', 
	 postglobally=T);
    # Since we really want to kill it and the terminate
    # probably will not kill it, we issue a system kill command
    # as well
    if (private.nummemoryclients > 0) {
      self->remove(theagent.server);
    }
    errmsg :=
      spaste('Server \'', theagent.server, '\' was killed');
    theagent.private.alerter->jobfail([agent=theagent, value=errmsg]);
    theagent->terminate();
    
    # Only try a kill -9 on this host!
    if (has_field(theagent, 'established')&&
	has_field(theagent.established, 'pid')&&
	theagent.host=='') {
      a:=shell(paste('kill -9 ', theagent.established.pid), async=T);
    }
    theagent.busy := 0;
    private.done(agentid);
    note(errmsg, priority='WARN', origin='servers.kill',
	 postglobally=F);
    return T;
  }
  
  ########
  # Mark a specific object (objectid) in a given server (id) as done.
  self.done := function(id, objectid) {
    wider private;
    if (private.trace) {
      note(paste('Glish SEND done, objectid=',private.format(objectid)),
	   priority='DEBUGGING', origin='servers.done', 
	   postglobally=F);
    }
    
    if (!self.isvalid(id)) {
      fail spaste('Illegal agent id: ', as_string(id),
		  ' Must be integer between 1 and ', 
		  as_string(length(private.agents)));
    }
    
    theagent := ref private.agents[id];
    if (!is_agent(theagent)) {
      fail spaste('Agent id: ', as_string(id),
		  ' does not represent a valid agent');
    }
    if (theagent.busy) { return private.busy_error_done(theagent) }
    if (private.timeout.done>0) {
      private.timername['done'] := private.mytimer->register(private.timeout.done);
      theagent->done(objectid);
      await theagent->done_result, theagent->error, theagent->fail,
	private.mytimer->[private.timername['done']];
      private.mytimer->unregister(private.timername['done']);
      if ($name==private.timername['done']) {
	errmsg :=
	  spaste('Server: \'', theagent.server, '\' has failed to terminate on command.\n',
		 'This indicates an unexpected problem. Consider saving your work and restarting AIPS++.\n',
		 'Please submit a bug-report using bug() if you can reproduce the ',
		 'problem.');
	print errmsg;
	fail errmsg;
      }
    } else {
      theagent->done(objectid);
      await theagent->done_result, theagent->error, theagent->fail;
    }
    
    if ($name == 'error') {
      fail paste($value);
    } else if ($name == 'fail') {
      $agent.busy -:= 1;
      if ($agent.busy < 0) {
	$agent.busy := 0;
      }
      private.done(id);   # Make sure we drive a stake through its heart.
      errmsg :=
	spaste('Server \'', $agent.server, '\' has failed unexpectedly!\n',
	       'You may be able to create the relevant tool again.\n',
	       'If that causes unexpected behavior, please restart AIPS++\n',
	       'Please submit a bug-report using bug() if you can reproduce the ',
	       'problem.');
      # Print it as well in case something *really* bad has happened.
      print errmsg;
      fail errmsg;
      $agent.private.alerter->jobfail([agent=$agent, value=errmsg]);
    } else {
      numobjects := $value; # Number of objects left on the server
      if ((theagent.terminateonempty)&&(numobjects <= 0)) {
	# Wait for server to avoid race where the user immediately wants
	# to create another object of the same server.
	if (private.timeout.close>0) {
	  private.timername['close'] := private.mytimer->register(private.timeout.close);
	  theagent->terminate();
	  await theagent->done, theagent->fail,
	    private.mytimer->[private.timername['close']];
	  if ($name==private.timername['close']) {
	    note(spaste('Closing empty server: ', theagent.server,
			' timed out after ',
			private.timeout.close, 's'),
		 priority='WARN', origin='servers.done', 
		 postglobally=F);
	  }
	  private.mytimer->unregister(private.timername['close']);
	} else {
	  theagent->terminate();
	  await theagent->done, theagent->fail;
	}
	private.done(id);   # Make sure we drive a stake through its heart.
	
        if ($name=='fail') {
	  note(spaste('Close of empty server: ', theagent.server,
		      ' failed for an unknown reason'),
	       priority='WARN', origin='servers.done', 
	       postglobally=F);
	} else {
	  note(spaste('Successfully closed empty server: ', theagent.server),
	       priority='NORMAL', origin='servers.done', 
	       postglobally=F);
	}
      }
      self.alerter()->jobterminate();
    }
    return T;
  }
  
  ########
  # Run a specific method of the server
  self.run := function(const id, ref invokerecord, async=F) {
    wider private;
    if (private.trace) {
      note(paste('Glish SEND invokerecord=',private.format(invokerecord)),
	   priority='DEBUGGING', origin='servers.run', 
	   postglobally=F);
    }
    
    if (!self.isvalid(id)) {
      fail spaste('Illegal agent id: ', as_string(id),
		  ' Must be integer between 1 and ', 
		  as_string(length(private.agents)));
    }
    
    theagent := ref private.agents[id];
    if (!is_agent(theagent)) {
      msg := spaste('Attempt to execute on non-existent server!\n',
		    'Maybe you are using an object copy that has been deleted?');
      note(msg, priority='SEVERE', origin='servers.run',
	   postglobally=F);
      fail msg;
    }
    if (async) {return private.run_async(theagent, invokerecord)}
    
    # If we are running synchronously, we might want to run even if we are 
    # already busy. Queue should probably only be true for system functions
    # like logging.
    # This will work because glish will queue up the request in the
    # I/O queue. If we don't do this, if log messages come out faster
    # than the log (misc) client can handle them, then we start getting
    # log errors.
    #
    # So, TODO: add a queue=F default argument and set it to T for things
    # like logging.
    
    theagent.busy +:= 1;
    theagent->run(invokerecord);
    # If the above following await is ^C'd out of, theagent.busy will
    # gets decremented with a whenever anyway.
    
    await theagent->run_result, theagent->error, theagent->fail;
    if ($name == 'error') {
      if (is_fail($value)) {
	fail;
      } else {
	fail paste(as_string($value));
      }
    }
    if ($name == 'fail') {
      errmsg :=
	spaste('Server \'', $agent.server, '\' has failed unexpectedly!\n',
	       'You will need to create the relevant tool again.\n',
	       'If that causes unexpected behavior, please restart AIPS++\n',
	       'Please submit a bug-report using bug() if you can reproduce the ',
	       'problem.');
      # Print it as well in case something *really* bad has happened.
      print errmsg;
      fail errmsg;
    }
    # run_result
    val invokerecord := $value;
    if (private.trace) {
      note(paste('Glish RECEIVE invokerecord=',
		 private.format(invokerecord)), 
	   priority='DEBUGGING', origin='servers.run', 
	   postglobally=F);
    }
    if (has_field(invokerecord, 'returnval')) {
      return invokerecord.returnval;
    } else {
      return T;
    }
  }
  
  ########
  # Stop a running object asap
  self.stop := function(const id, stop=T) {
    wider private;
    
    if (!self.isvalid(id)) {
      fail spaste('Illegal agent id: ', as_string(id),
		  ' Must be integer between 1 and ', 
		  as_string(length(private.agents)));
    }
    
    theagent := ref private.agents[id];
    if (!is_agent(theagent)) {
      msg := spaste('Attempt to stop a non-existent server!\n',
		    'Maybe you are using an object copy that has been deleted?');
      note(msg, priority='SEVERE', origin='servers.stop',
	   postglobally=F);
      fail msg;
    }
    theagent.shouldstop := stop;
    return T;
  }
  
  self.methods := function(const agentid, const objectid) {
    wider private;
    if (private.trace) {
      note(paste('Glish SEND'),
	   priority='DEBUGGING', origin='servers.methods', 
	   postglobally=F);
    }
    
    if (!self.isvalid(agentid)) {
      fail spaste('Illegal agent id: ', as_string(agentid),
		  ' Must be integer between 1 and ', 
		  as_string(length(private.agents)));
    }
    
    theagent := ref private.agents[agentid];
    if (!is_agent(theagent)) {
      msg := spaste('Attempt to execute on non-existent server!\n',
		    'Maybe you are using an object copy that has been deleted?');
      fail msg;
    }
    
    theagent->methods(objectid);
    # If the above following await is ^C'd out of, theagent.busy will
    # gets decremented with a whenever anyway.
    
    await theagent->methods_result, theagent->error, theagent->fail;
    if ($name == 'error') {
      if (is_fail($value)) {
	fail;
      } else {
	fail paste(as_string($value));
      }
    }
    if ($name == 'fail') {
      errmsg :=
	spaste('Server \'', $agent.server, '\' has failed unexpectedly!\n',
	       'You will need to create the relevant tool again.\n',
	       'If that causes unexpected behavior, please restart AIPS++\n',
	       'Please submit a bug-report using bug() if you can reproduce the ',
	       'problem.');
      # Print it as well in case something *really* bad has happened.
      print errmsg;
      fail errmsg;
    }
    # run_result
    returnval := $value;
    if (private.trace) {
      note(paste('Glish RECEIVE returnval=', private.format(returnval)), 
	   priority='DEBUGGING', origin='servers.methods', 
	   postglobally=F);
    }
    return returnval;
  }
  
  self.running := function(jobid) {
    wider private;
    if (jobid < 1 || jobid > length(private.results)) {
      err := spaste('No such jobid: ', as_string(jobid), '. Must be',
		    ' between 1 and ', as_string(length(private.results)));
      return throw(err, origin='servers.running');
    }
    return !private.finished[jobid];
  }
  
  self.result := function(jobid, clear=T) {
    wider private;
    wider self;
    running := self.running(jobid);
    if (is_fail(running)) fail;
    if (running) {
      err := spaste('Jobid #', as_string(jobid), ' is still running');
	note(err, priority='SEVERE', origin='servers.result',
	     postglobally=F);
      fail err;
    }
    
    # Signal that it has already been retrieved
    if (! is_record(private.results[jobid])) return F;
    
    # Sanitize the record by getting rid of the DO related fields
    # and putting returnval first
    retval := [=];
    if (has_field(private.results[jobid], 'returnval'))
      retval['returnval'] := private.results[jobid]['returnval'];
    for (i in field_names(private.results[jobid])) {
      if (split(i, '')[1] != '_' && i != 'returnval')
	retval[i] := private.results[jobid][i];
    }
    if (clear) private.results[jobid] := F;
    return retval;
  }
  
  self.isvalid := function(agentid) {
    return (is_numeric(agentid) && agentid > 0 && 
	    agentid <= length(private.agents));
  }
  
  self.busy := function(agentid) {
    wider private;
    wider self;
    
    if (!self.isvalid(agentid)) {
      fail spaste('Illegal agent id: ', as_string(agentid),
		  ' Must be integer between 1 and ', 
		  as_string(length(private.agents)));
    }
    return private.agents[agentid].busy;
  };
  
# Now that we have an agent id (an integer) corresponding to
# a server for this type, we can create an object of this type.
# The invokerecord contains all the useful info that is sent
# to the server for the creation
  self.create := function(id, type, creator='', invokerecord=[=]) {
    wider private;
    if (private.trace) {
      note(paste('creator=',private.format(creator), 
		 ' invokerecord=', private.format(invokerecord)), 
	   priority='DEBUGGING', 
	   origin='servers.create', postglobally=F);
    }
    if (!self.isvalid(id)) {
      fail spaste('Illegal agent id: ', as_string(id),
		  ' Must be integer between 1 and ', 
		  as_string(length(private.agents)));
    }
    invokerecord._type := type;
    invokerecord._creator := creator;
    agentid := id;
    # Allow one minute for a create
    if (private.timeout.create>0) {
      private.timername['create'] := private.mytimer->register(private.timeout.create);
      private.agents[id]->create(invokerecord);
      await private.agents[id]->create_result, private.agents[id]->error,
	private.agents[id]->fail, private.mytimer->[private.timername['create']];
      private.mytimer->unregister(private.timername['create']);
      if ($name==private.timername['create']) {
	errmsg :=
	  spaste('Server: \'', private.agents[id].server, '\' has failed to start on command\n',
		 'This indicates an unexpected problem. We recommend you save your work and restart AIPS++.\n',
		 'Please submit a bug-report using bug() if you can reproduce the ',
		 'problem.');
	print errmsg;
	fail errmsg;
      }
    } else {
      private.agents[id]->create(invokerecord);
      await private.agents[id]->create_result, private.agents[id]->error,
	private.agents[id]->fail;
    }
    if ($name == 'error'||$name == 'fail') {
      fail paste($value);
    }
    # create_result: this is a record containing 
    # e.g. [_sequence=2, _pid=2887, _time=940878429, _host=herbert] 
    id := $value;
    if (!is_record(id)) {
      note(paste(id), priority='SEVERE', origin='servers',
	   postglobally=F);
      fail paste('Illegal id :', id);
    }
    # Add the objectid
    id.objectid := [sequence=id._sequence, pid=id._pid, time=id._time,
		    host=id._host, agentid=agentid];
    # The id now contains:
    # [_sequence=3, _pid=2930, _time=940878520, _host=herbert,
    #   objectid=[sequence=3, pid=2930, time=940878520, host=herbert, agentid=3]] 
    self.alerter()->jobcreate();
    return id;
  }
  
# Now that we have an agent id (an integer) corresponding to
# a server for this type, we can create an object of this type.
# The creator is just for info. The invokerecord contains
# all the useful info that is sent to the server.
  self.add := function(agentid, id) {
    wider private;
    if (private.trace) {
      note(paste('agentid=', agentid),
	   priority='DEBUGGING', 
	   origin='servers.add', postglobally=F);
    }
    if (!self.isvalid(agentid)) {
      fail spaste('Illegal agent id: ', as_string(agentid),
		  ' Must be integer between 1 and ', 
		  as_string(length(private.agents)));
    }

    id2 := private.agents[agentid];
    if (!is_record(id2)) {
      note(paste('id=', id2), priority='SEVERE', origin='servers',
	   postglobally=F);
      fail paste('Illegal id :', id);
    }
    id2 := [=];
    id2._sequence := id.sequence;
    id2._pid := id.pid;
    id2._time := id.time;
    id2._host := id.host;
    id2._agentid := agentid;
    id2.objectid := [sequence=id2._sequence, pid=id2._pid, time=id2._time,
		     host=id2._host, agentid=agentid];
    self.alerter()->jobadd();
    return id2;
  }
  
  # Allow control of the timeouts
  self.settimeout := function(action='create', timeout=60) {
   wider private;
    if (action=='all') {
      for (action in field_names(private.timeout)) {
	private.timeout[action] := timeout;
      }
    } else if (action=='none') {
      for (field in field_names(private.timeout)) {
	private.timeout[field] := -1.0;
      }
    } else if (has_field(private.timeout, action)) {
      private.timeout[action] := timeout;
    }
    return T;
  }
  
  # Allow control of the timeouts
  self.timeouts := function() {
    wider private;
    return private.timeout;
  }
  
  # Returns a 'standard' public object with some standard objects defined
  # Assumes that private.agent exists and is the agent id.
  # Functions available:
  #    busy() # T if this objects implementation is doing something.
  self.init_object := function(ref private) {
    wider private;
    wider self;
    
    objprivate := ref private;
    objpublic := [=];
    
    objpublic.busy := function() {
      wider objprivate;
      return as_boolean(defaultservers.busy(objprivate.agent));
    }
    
    objpublic.result := function(jobid,clear=T) {
      wider objprivate;
      return defaultservers.result(jobid, clear);
    };
    
    return objpublic;
  }
  
  self.info := function() {
    wider private;
    form := '%3s %15s %15s %20s %4s';
    s := sprintf(form, 'Id', 'Name', 'Server', 'Host', 'Busy');
    note(s);
    for (id in 1:len(private.agents)) {
      ag := private.agents[id];
      if (is_record(ag)) {
	s:=sprintf(form, as_string(id), as_string(ag.name), as_string(ag.server),
		   as_string(ag.host), as_string(as_boolean(ag.busy)));
	note(s);
      }
    }
    return T;
  }

  self.findid := function(name) {
    wider private;
    for (id in 1:len(private.agents)) {
      if (private.agents[id].name==name) {
	return id;
      }
    }
    return throw('No such server : ', name);
  }
  
  self.memory := function() {
    wider private;
    private.servermemory.Glish := alloc_info().used/1024/1024;
    return private.servermemory;
  }
  
  self.sendmemoryevents := function() {
    wider private;
    private.nummemoryclients +:= 1;
    return T;
  }

  self.stopmemoryevents := function() {
    wider private;
    if (private.nummemoryclients > 0) private.nummemoryclients -:= 1;
    return T;
  }

}  # constructor

# Make servers. The defaultservers variable cannot be const as some
# functions, in particular the makeplot whenever need to append fields
# to the defaultservers variable. Long term this technique needs to be
# revisted so that the server_controller functions which do gui
# related things get moved out of servers.g
defaultservers := server_controller();
note('defaultservers ready', priority='NORMAL', origin='servers');
# Only use timeouts if actually directed to
defaultservers.settimeout('none');

include 'getrc.g';
# Set the dowait variable
if (!any(symbol_names() == 'dowait')) {
  global dowait := T;
  local tmp
  if (getrc.find(tmp, 'user.dowait')) {
    tmp := to_upper(split(tmp, '')[1]);
    if (tmp == 'F') {
      global dowait := F;
    }
  }
  note(paste('dowait variable is', as_string(dowait)), priority='NORMAL', 
       origin='servers');
}

# Pre-start servers.
{
  local prestartServers := "timer misc quanta", tmp;
  if (getrc.find(tmp, 'user.prestart')) {
    if (tmp == 'none') {
      prestartServers := '';
    } else {
      prestartServers := split(tmp);
    }
  }
  for (i in ind(prestartServers)) {
    local server := prestartServers[i];
    if (strlen(server) > 0) {
#      note(paste('Pre-starting', server), origin='servers.init',
#	   priority='DEBUGGING');
      defaultservers.activate(server, async=T);
    }
  }
}
