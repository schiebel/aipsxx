# executive.g: Execute scripes in a queue, possibly on another machine
#
#   Copyright (C) 1998,1999,2000,2001,2002
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
#   $Id: executive.g,v 19.2 2004/08/25 02:08:11 cvsmgr Exp $

pragma include once;

include 'unset.g';
include 'note.g';

const executive := subsequence(concurrent=1) {
#
# Holder for private data
#
  private := [=];
#
# Internal counters
#
  private.concurrent := concurrent;
  private.running := 0; # This is the number of jobs running at any time
  private.sequence := 0;# Sequence number always increases
#
# Various holders
#
  private.clients := [=];   # Client holders: each client is an agent
  private.jobs := [=];      # Job holders: each job is a record
  private.logfiles := [=];  # File holders for logs: each is a File descriptor
#
# Boilerplate for whenever pushing and deactivating
#
  private.whenevers := [=];
  private.pushwhenever := function(id) {
    id := as_string(id);
    wider private;
    if (!has_field(private.whenevers, id)) {
      private.whenevers[id] := [];
    }
    private.whenevers[id][len(private.whenevers[id]) + 1] := 
        last_whenever_executed();
  }
  
  private.deactivatewhenever := function(id) {
    wider private;
    id := as_string(id);
    if (has_field(private.whenevers, id)) {
      deactivate private.whenevers[id];
      private.whenevers[id] := [];
    }
  }
#
# Return unique ID
#
  private.id := function() {
    wider private;
    private.sequence +:=1;
    return private.sequence;
  }
#
# Can we find a job to run, if so return the id, if not, return zero
#
  private.find := function() {
    wider private;
#
# Are there any empty slots?
#
    if(private.running<private.concurrent) {
#
# Do exhaustive search to allow out of sequence running
#
      for (id in 1:length(private.jobs)) {
	job := ref private.jobs[id];
	if(is_record(job)&&(job.status=='waiting')) return id;
      }
    }
    return 0;
  }
#
# Is it possible to start another job?
#
  private.start := function() {
    wider private;
#
# Can we find an empty slot?
#
    id := private.find();
#
# Yes: start the job
#
    if(id) {
      job := ref private.jobs[id];
#
# Open the log file
#
      if(job.log!='') {
	private.logfiles[id] := open(paste('> ', job.log));
      }
      else {
	private.logfiles[id] := F;
      }
#
# Assemble the command
#
      command := ['glish', job.script];
      if(job.host!='') {
	if(job.log!='') {
	  private.clients[id] := shell(command, host=job.host, async=T);
	}
	else {
	  private.clients[id] := client(command, host=job.host);
	}
      }
      else {
	if(job.log!='') {
	  private.clients[id] := shell(command, async=T);
	}
	else {
	  private.clients[id] := client(command);
	}
      }
#
# Did we get a valid client?
#
      if(is_agent(private.clients[id])) {
	note('Job ', id, ' started, running script ', job.script);
	job.status := 'running';
	job.time := time();
	private.running +:=1;
      }
      else {
	return throw('Could not start client');
      }
#
# Relay any event to the outside world
#
      whenever private.clients[id]->* do {
	self->relay([id=id, name=$name, value=$value]);
	private.start();
      }
      private.pushwhenever(id);
#
# We are done: stop
#
      whenever private.clients[id]->done do {
	job := ref private.jobs[id];
	if(job.log!='') {
	  note('Job ', job.id, ' finished, script ', job.script, ', log file ', job.log);
	}
	else {
	  note('Job ', job.id, ' finished, script ', job.script);
	}
	job.time := time();
	self->done(job);
	private.running -:= 1;
	private.stop(id);
	private.start();
      }
      private.pushwhenever(id);
#
# Gather stdout and stderr
#
      whenever private.clients[id]->stdout, private.clients[id]->stderr do {
	job := ref private.jobs[id];
	if(is_file(private.logfiles[id])) {
	  fprintf(private.logfiles[id], '%s\n', $value);
	}
	private.start();
      }
      private.pushwhenever(id);

      if(is_record(private.gui)) private.gui.refresh();
      return id;
    }
#
# Not ready to start yet
#
    else {
      if(is_record(private.gui)) private.gui.refresh(); 
     return F;
    }
  }
#
# Stop a job
#
  private.stop := function(id) {
    wider private;
    if(id<=length(private.clients)) {
      private.clients[id] := F;
      private.deactivatewhenever(id);
      private.logfiles[id] := F;
      job := ref private.jobs[id];
      job.status := 'finished';
      job.time := time();
    }
    return T;
  }
#
# Show number of concurrent jobs allowed
#
  self.concurrent := function() {
    wider private;
    return private.concurrent;
  }
#
# Set number of concurrent jobs allowed: try to start another job while we are
# here
#
  self.setconcurrent := function(concurrent) {
    wider private;
    if(concurrent>0) {
      private.concurrent:=concurrent;
      private.start();
      return T;
    }
    else {
      return throw('Number of concurrent jobs must be greater than zero');
    }
  }
#
# Return number of running jobs
#
  self.running := function() {
    wider private;
    if(is_record(private.gui)) private.gui.refresh();
    return private.running;
  }
#
# Run a script on a given host: returns a job identifier
#
  self.runscript := function(script, host='', log='', comment='') {
    wider self, private;
    job := [=];
    job.script:=script;
    job.host:=host;
    job.log:=log;
    job.time := time();
    job.comment := comment;
    job.status := 'waiting';
    id := private.id();
    job.id:=id;
#
# Now store this job in the queue of jobs....
#
    private.jobs[job.id] := job;
    private.clients[job.id] := F;
    private.logfiles[id] := F;
#
# .... and now try to start next job without assuming that this job
# is the next to go
#
    private.start();
#
# In any event, return the id of this job
#
    if(is_record(private.gui)) private.gui.refresh();
    return id;
  }
#
# Run commands
#
  self.run := function(commands, inc='', host='', dolog=F, comment='') {
    wider private;
    script := spaste('dex.',system.host,'.',system.pid,'.',private.sequence+1,'.g');
    f:=open(spaste('> ', script));
    if(!is_file(f)) {
      return throw('Cannot open script file ', script, ' for writing');
    }
    if(inc!='') {
      fprintf(f, 'include \'%s\'\n%s\nexit(1)\n', inc, commands);
    }
    else {
      fprintf(f, '%s\nexit(1)\n', commands);
    }
    f:=F;
    log := '';
    if(dolog) {
      log := spaste('dex.',system.pid,'.',private.sequence+1,'.log');
    }
    return self.runscript(script, host, log, comment);
  }
#
# Make
#
  self.make := function(target, args, makefile='makefile', host='', dolog=F,
			comment='') {
    wider private;
    commands := spaste('make(target=\'',target,
		       '\', args=', as_evalstr(args),
		       ', makefile=\'', makefile,
		       '\')');
    return self.run(commands, inc='make.g', host=host, dolog=dolog,
		    comment=comment);
  }
#
# Terminate nicely
#
  private.terminate := function(id) {
    wider private;
    job := ref private.jobs[id];
    if(is_record(job)) {
      if(job.status=='running') {
	note('Stopped running job ', job.id, ', script ', job.script);
	private.stop(job.id);
	job.status := 'aborted';
	private.running -:= 1;
      }
      else if(job.status=='waiting') {
	note('Deleting queued job ', job.id, ', script ', job.script);
	private.stop(job.id);
	job.status := 'deleted';
      }
    }
    return T;
  }
#
# Stop a given job
#    
  self.stop := function(id) {
    wider self, private;
#
# Check to see if this can be in the list of jobs
#
    if((id<1)||(id>length(private.jobs))) {
      return throw('Not a valid job index');
    }
#
# Terminate
#
    private.terminate(id);
#
# Try to start next job
#
    private.start();
    return T;
  }
#
# Comment
#    
  self.comment := function(id, comment='') {
    wider self, private;
#
# Check to see if this can be in the list of jobs
#
    if((id<1)||(id>length(private.jobs))) {
      return throw('Not a valid job index');
    }
    private.jobs[id].comment := comment;
    private.start();
    return T;
  }
#
# Comment
#    
  self.addcomment := function(id, comment='') {
    wider self, private;
#
# Check to see if this can be in the list of jobs
#
    if((id<1)||(id>length(private.jobs))) {
      return throw('Not a valid job index');
    }
    private.jobs[id].comment := paste(private.jobs[id].comment, comment);
    private.start();
    return T;
  }
#
# List all jobs
#
  self.show := function() {
    wider private;
    for (id in 1:length(private.jobs)) {
      note('Job ', id, ' : ', private.jobs[id]);
    }
    return T;
  }

  self.list := function() {
    wider private;
    return private.jobs;
  }

  self.type := function() {
    return "executive";
  }

  self.gui := function() {
    wider private;
    if(!is_record(private, gui)) {
      include 'executivegui.g';
      private.gui := executivegui(self);
    }
    return F;
  }

  self.test := function() {
    wider private;
    return executivetest();
  }

  self.done := function() {
    wider private;
    for (id in 1:length(private.jobs)) {
      private.terminate(id);
    }
    if(is_record(private.gui)) private.gui.done();
    private := F;
    self := F;
    return T;
  }

}

const executivetest := function(host='') {

  testdir := 'executivetest';
  note('Cleaning up directory ', testdir);
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); };
  ok := shell(paste("mkdir", testdir));
  if (ok::status) { throw("mkdir", testdir, "fails!") };

  global dex;
  dex.setconcurrent(2);
  dex.gui();
  dex.run('print time();print system;', host);
  dex.run('print time();print system;');
  dex.run('print time();print system;', host);
  dex.run('print time();print system;', host);
  dex.run('print time();print system;', host);
  dex.stop(1);
  dex.show();
  dex.stop(4);
  dex.list();
  return T;
}


const defaultexecutive := const executive();
const dex := const defaultexecutive;
note('defaultexecutive (dex) ready', priority='NORMAL', origin='executive.g');



