# toolguiserver: Serves GUIs for tools
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
#   $Id: toolmanagersupport.g,v 19.2 2004/08/25 02:06:29 cvsmgr Exp $
#

pragma include once

toolmanagersupport := function() {
  
  public := [=];

  private := [=];

  private.sendcallbackfn := [=];
  private.sendcallbackcount := 0;
  
  private.locationframe := [=];
  private.locationframecount := 0;
  
  private.foundmeta := F;
  private.logcommands := F;
  private.logevents := F;

  private.itemindex := 1;

  # Log events
  const public.logevent := function(name, values) {
    wider private;
    if(!private.logevents) return F;
    name ~:= s/_return$//;
    command := spaste('mydemo.tool(\'\', \'\', event=\'', name, '\', rec=',
		      as_evalstr(values), ')');
    include 'scripter.g';
    ds.log(command);
    return T;
  }
  const public.logevents := function(log=T) {
    wider private;
    if(!private.logevents&&log) {
      ds.log('include \'guidemonstration.g\'');
      ds.log('mydemo:=guidemonstration();');
    }
    private.logevents := log;
    return T;
  }
  # Log commands?
  const public.logcommands := function(log=T) {
    wider private;
    private.logcommands := log;
    return T;
  }
  
################################
  const public.registersendcallback := function(ref callbackFunc) 
  {
  # Register the callback function for the Send button which is used
  # when running as an item manager. Called from guientry.g. The
  # callback functions are stored in a stack by the toolmanager,
  # and popped from the stack by deregistersendcallback().
  #
    wider private;
    private.sendcallbackcount := private.sendcallbackcount + 1;
    private.sendcallbackfn[private.sendcallbackcount] := callbackFunc;
    return T;
  };

################################
  const public.deregistersendcallback := function() 
  {
  # Pop the stack of callback functions for the Send button used
  # when running as an item manager. Called from guientry.g.
  #
    wider private;
    private.sendcallbackfn[max(private.sendcallbackcount,1)] := 0;
    private.sendcallbackcount := max(private.sendcallbackcount-1, 0);
    return T;
  };

################################
  const public.locationframe := function() 
  {
  #
  # Return a location frame for this entry
  #
    wider private;
    return private.locationframe[private.locationframecount];
  };

################################
  const public.registerlocationframe := function(ref f) 
  {
  # Register the callback function for the Send button which is used
  # when running as an item manager. Called from guientry.g. The
  # callback functions are stored in a stack by the toolmanager,
  # and popped from the stack by deregisterframe().
  #
    wider private;
    private.locationframecount := private.locationframecount + 1;
    private.locationframe[private.locationframecount] := ref f;
    return T;
  };

################################
  const public.deregisterlocationframe := function() 
  {
  # Pop the stack of callback functions for the Send button used
  # when running as an item manager. Called from guientry.g.
  #
    wider private;
    private.locationframe[max(private.locationframecount,1)] := F;
    private.locationframecount := max(private.locationframecount-1, 0);
    return T;
  };

################################
  # This server function is called by the tool?uiservers only.
  const public.invokesendcallback := function(value)
  {
  # Invoke the Send callback function, as used by the item manager,
  # from the top of the stack.
  #
    wider private;
    j := max(private.sendcallbackcount, 1);
    if(is_function(private.sendcallbackfn[j])) {
      private.sendcallbackfn[j](value);
    };
    return T;
  };

  const public.findmeta := function() {
    wider private;

    if(!private.foundmeta) {
      # Have to find the meta information. This goes into the
      # global variable types that is accessed by the servers
      global types;
      include 'types.g';
      global types;
      types.includemeta();
      private.foundmeta := T;
    }
  }
  
################################
# Find package, module and description for a given type. A
# tool does not need to be registered
  const public.where := function(type) {
    wider public, private;

    public.findmeta();
    
    # Include the help information
    include 'aips2help.g';
    
    rec := [=];
    rec.description:='';
    rec.package:='';
    rec.module:='';
    # Ensure that the system is initialized
    if(length(help::pkg)==0) hs:=showhelp();
    # Try to find out the package/module/class
    for (package in field_names(help::pkg)) {
      for (module in field_names(help::pkg[package])) {
        if(module!='aipsrcdata') {
	  # Look for both tools and functions
	  if (has_field(help::pkg[package][module], 'objs') &&
	      has_field(help::pkg[package][module].objs, type) &&
	      has_field(help::pkg[package][module].objs[type], 'd')) {
	    rec.description:=
		paste(split(help::pkg[package][module].objs[type].d));
	    rec.package:=package;
	    rec.module:=module;
	    return rec;
	  }
	  if (has_field(help::pkg[package][module], 'funs') &&
	      has_field(help::pkg[package][module].funs, type) &&
	      has_field(help::pkg[package][module].funs[type], 'd')) {
	    rec.description:=
		paste(split(help::pkg[package][module].funs[type].d));
	    rec.package:=package;
	    rec.module:=module;
	    return rec;
	  }
	}
      }
    }
    return rec;
  }
  
################################
  # This server function is called by the tool?uiservers only.
  const public.getuiparameters := function(type, method, ref mode) {
    
    public.findmeta();
    
    global types;
    meta := [=];
    found := F;
    for (c in [T, F]) {
      meta := types.meta(type, ctors=c, globals=F);
      if(len(meta)&&has_field(meta, method)) {
	if(c) {
	  val mode := 'construct';
	}
	found := T;
	break;
      }
    }
    if(!found) {
      meta := types.meta(type, ctors=F, globals=T);
      if(len(meta)&&has_field(meta, method)) {
	val mode := 'global';
	found := T;
      }
    }
    if(!found||(length(meta)==0)) {
      return throw (paste('No user interface definition for', method));
    }
    
    uiparameters := [args=[=], gui=[=], cli=[=]];
    
    if(has_field(meta[method], 'gui')) {
      uiparameters.gui.name := meta[method].gui;
    }
    else {
      uiparameters.gui.name := 'autogui';
    }
    
    if(has_field(meta[method], 'cli')) {
      uiparameters.cli.name := meta[method].cli;
    }
    else {
      uiparameters.gui.name := 'autocli';
    }
    
    # Find the uiparameters
    for (arg in field_names(meta[method].data)) {
      if(has_field(meta[method].data[arg], 'parameters')) {
	uiparameters.args[arg] := meta[method].data[arg].parameters;
      }
      if(has_field(meta[method].data[arg], 'help')&&
         has_field(meta[method].data[arg].help, 'text')&&
	 !has_field(uiparameters.args[arg], 'help')) {
	uiparameters.args[arg].help := meta[method].data[arg].help.text;
      }
    }
    # Fill in the values using either the default (for "out" only)
    # or the value as last used
    include 'inputsmanager.g';
    values := inputs.getvalues(type, method);
    
    if(is_fail(values)) fail;
    for (arg in field_names(values)) {
      if(has_field(uiparameters, 'args')&&
	 has_field(uiparameters.args, arg)) {
	if(uiparameters.args[arg].dir=="out") {
	  uiparameters.args[arg].value := uiparameters.args[arg].default;
	}
	else {
	  uiparameters.args[arg].value := values[arg];
	}
      }
    }
    return uiparameters;
  }
  
  const public.execute := subsequence () {
    
    wider public;

    prvt := [=];
    
    prvt.whenevers := [];
    prvt.pushwhenever := function() {
      wider prvt;
      prvt.whenevers[len(prvt.whenevers) + 1] := last_whenever_executed();
    }
    
    # The following two functions are used to lock the subsequence
    # so that only one thing can be done at once
    prvt.isbusy := F;
    
    const prvt.lock := function() {
      wider prvt;
      if(!prvt.isbusy) {
	return T;
      }
      else {
	return F;
      }
    }
    const prvt.unlock := function() {
      wider prvt;
      prvt.isbusy := F;
    }
  
    whenever self->run do {
      wider public;
      prvt.rec := $value;
      if(prvt.lock()) {
	include 'inputsmanager.g';
	inputs.savevalues(prvt.rec.type, prvt.rec.method, prvt.rec.data);

	# We set up whenevers to catch errors from any DO that
	# is associated.
	if(is_defined(prvt.rec.tool)) {
	  possibleDO := symbol_value(prvt.rec.tool);
	  if(has_field(possibleDO, 'id')&&
	     has_field(possibleDO.id(), 'agentid')) {
	    whenever defaultservers.alerter()->fail do {
	      if($value.agent.id==possibleDO.id().agentid) {
		self->fail(paste($value.value));
		deactivate prvt.whenevers;
	      }
	    } prvt.pushwhenever();
	    whenever defaultservers.alerter()->error do {
	      if($value.agent.id==possibleDO.id().agentid) {
		self->error($value.value);
		deactivate prvt.whenevers;
	      }
	    } prvt.pushwhenever();
	    whenever defaultservers.alerter()->note do {
	      if($value.agent.id==possibleDO.id().agentid) {
		self->note($value.value);
	      }
	    } prvt.pushwhenever();
	  }
	}
	
	global tm;
	if(!has_field(tm::, prvt.rec.tool)) {
	  tm::[prvt.rec.tool]:=[=];
	}
	tm::['command'][prvt.rec.tool] := public.getcommand(prvt.rec);
	global dowait;
	olddowait := dowait;
	dowait := T;
	result := eval(tm::['command'][prvt.rec.tool]);
	dowait := olddowait;
	if(is_fail(result)) {
	  self->error(result::message);
	}
	else {
	  if(has_field(tm::['data'], prvt.rec.tool)) {
	    prvt.rec.data := tm::['data'][prvt.rec.tool];
	  }
	  if (has_field(prvt.rec.data, 'returnval')) {
	    prvt.rec.data['return'] := prvt.rec.data['returnval'];
	  }
	  # Log the command
	  if(private.logcommands) {
	    public.logcommand(prvt.rec);
	  }
	  # Now send a done event containing the context
	  self->done(prvt.rec);
	}
	deactivate prvt.whenevers;
      }
      prvt.unlock();
    } prvt.pushwhenever();
    
    whenever self->kill do {
      if(has_field(prvt, 'rec')&&has_field(prvt.rec, 'tool')&&
	 is_defined(prvt.rec.tool)&&
	 has_field(eval(prvt.rec.tool), 'id')) {
	possibleDO:=symbol_value(prvt.rec.tool);
        if(has_field(possibleDO, 'id')&&
	   has_field(possibleDO.id(), 'agentid')) {
	  defaultservers.kill(possibleDO.id().agentid);
	}
      }
      self->fail(throw('Killed by user'));
      failed := T;
      if(length(prvt.whenevers)) deactivate prvt.whenevers;
      val self := F;

      global tm;
      tm::['tools'][prvt.rec.tool]:=[=];
      tm::['data'][prvt.rec.tool]:=[=];

    } prvt.pushwhenever();
    
    self.done := function() {
      wider prvt;
      if(length(prvt.whenevers)) deactivate prvt.whenevers;
      val self := F;
    }
    
  }
  
################################
  # This server function is called by the tool?uiservers only.
  const public.logcommand := function (rec) {
    include 'scripter.g';
    ds.log(public.getcommand(rec, doglobal=F));
    return T;
  }
  
################################
  # This server function is called by the tool?uiservers only.
  # Returns the command in an executable form
  const public.getcommand := function (rec, doglobal=T) {
    wider public;
    
    mode := rec.mode;
    type := rec.type;
    isliteral := rec.isliteral;
    tool := rec.tool;
    newtool := rec.newtool;
    method := rec.method; 
    data := rec.data;
    inc := rec.inc;
    
    global tm;
    tm::['data'][tool] := ref data;

    command := '';
    if(mode=='construct') {
      if(is_string(inc)) {
	for (f in inc) {
	  command := spaste('include \'',f,'\';\n');
	}
      }
      command := spaste(command, newtool, ':=', method, '(');
    }
    else if(mode=='item') {
      if(is_string(inc)) {
	for (f in inc) {
	  command := spaste('include \'',f,'\';\n');
	}
      }
      command := spaste(command, newtool, ':=', tool, '.', method, '(');
    }
    else {
      if(!is_unset(newtool)) {
	returnstring := spaste(newtool, ':=');
      }
      else if(doglobal) {
	returnstring := spaste('tm::[\'data\'][\'',tool,'\'][\'return\']:=');
      }
      else {
	returnstring := 'ok:=';
      }
      if(mode=='global') {
	if(is_string(inc)) {
	  for (f in inc) {
	    command := spaste('include \'',f,'\';\n');
	  }
	}
	command := spaste(command, returnstring, method,'(');
      }
      else {
	command := spaste(command, returnstring, tool,'.',method,'(');
      }
    }

#
# Now step through the variables, making those items 
# globally and uniquely named in the script that will
# be executed. It's possible that this will fail if
# two scripts from different runs are combined.
#
# JPM - I'm not certain of the point of this. It does obfuscate the
# scripting output. I'll touch base with Tim but for the time being I'm
# removing it.

    predefines := '';

#    if(!doglobal) {
#      for (i in field_names(data)) {
#	if (i!='return' && i!='toolname') {
#	  include 'recordmanager.g';
#	  if(is_record(data[i])) {
#	    itemname:=spaste('my', i, 'asrecord', private.itemindex);
#	    private.itemindex +:= 1;
#	    if(predefines=='') {
#	      predefines:=spaste('include \'recordmanager.g\';\n', itemname,
#				 ':=', as_evalstr(drcm.torecord(data[i])),';\n');
#	    }
#	    else {
#	      predefines:=spaste(predefines, ' ', itemname, ':=',
#				 as_evalstr(drcm.torecord(data[i])),';\n');
#	    }
#	    tm::['data'][tool][i]:=spaste('drcm.fromrecord(',itemname,')');
#	    isliteral[i] := T;
#	  }
#	}
#      }
#    }
#
# Now make the actual command
#    
    count := 0;
    for (i in field_names(data)) {
      if (i!='return' && i!='toolname') {
	if (count!=0) {
	  command := spaste(command, ', ');
	}
        if(doglobal) {
	  if(isliteral[i]) {
	    command := spaste(command, i, '=', data[i]);
	  }
	  else {
	    command := spaste(command, i, '=tm::[\'data\'][\'',tool,'\'][\'',i,'\']');	  }
	}
	else {
	  if(isliteral[i]) {
	    command := spaste(command, i, '=', data[i]);
	  }
	  else {
	    command := spaste(command, i, '=', as_evalstr(data[i]));
	  }
	}
	count +:= 1;
      }
    }
    
    command := spaste(command, ');');
    
    if(predefines!='') {
      command := paste(predefines, command);
    }
    return command;
    # That's it!
  }
  
  return public;
}

const toolmanagersupport := toolmanagersupport();
