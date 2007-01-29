# toolclibasefunction: Base function for tool clis
#
#   Copyright (C) 1998,1999,2000
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
#   $Id: toolclibasefunction.g,v 19.2 2004/08/25 02:05:43 cvsmgr Exp $
#

pragma include once;

const toolclibasefunction := subsequence(type, ref tool=unset, title=unset,
					 methods=unset,
					 mode='construct',
					 hints=[=]) {
  
  include 'note.g';
  
  private := [=];
  
  private := [=];
  private.mode := mode;
  private.autocli := [=];
  private.commands := [=];
  private.execute := [=];
  private.type := type;
  private.title := title;
  private.methods := methods;
  private.hints := hints;
  private.tool := tool;
  
  private.prompt := '>';
  
  include 'toolmanagersupport.g';
  private.tms := toolmanagersupport;
  
  private.whenevers := [];
  self.pushwhenever := function() {
    wider private;
    private.whenevers[len(private.whenevers) + 1] := last_whenever_executed();
  }
  
  # Get any output tool name
  private.getliteral :=function() {
    wider private;
    rec := [=];
    for (arg in field_names(private.autocli[private.lastmethod].parameters)) {
      rec[arg] := private.autocli[private.lastmethod].parameters[arg].isliteral;
    }
    return rec;
  }
  
  const private.getexecrec := function(values) {
    wider private;
    
    # Set up values for execution
    rec := [=];
    rec.tool := private.tool;
    rec.method := private.lastmethod;
    rec.data := values;
    rec.mode := private.mode;
    rec.newtool := unset;
    rec.isliteral := private.getliteral();
    if(has_field(values, 'toolname')) {
      # Output is constructor
      include 'toolmanager.g';
      rec.newtool := tm.getnewtoolname(values.toolname);
      note('Execution will construct new tool ', rec.newtool);
      rec.tool := rec.newtool;
      private.tool := rec.newtool;
    }
    else {
      # Look to see if any of the arguments are tools
      toolname := private.gettool();
      if(toolname!='') {
	rec.newtool := toolname;
	note('Execution will create output tool ', toolname);
      }
    }
    if(private.mode=='global') {
      include 'toolmanager.g';
      rec.type := tm.findtype(private.lastmethod);
    }
    else {
      rec.type := private.type;
    }
    rec.inc := types.getincludefile(rec.type);
    return rec;
  }
  
  # Get any output tool name
  private.gettool :=function() {
    wider private;
    for (arg in field_names(private.autocli[private.lastmethod].parameters)) {
      if(private.autocli[private.lastmethod].parameters[arg].ptype=='tool') {
	name := private.autocli[private.lastmethod].parameters[arg].value;
	include 'toolmanager.g';
	name := tm.getnewtoolname(name);
	return name;
      }
    }
    return '';
  }
  
  # Get the default values
  private.getdefaults :=function() {
    wider private;
    values := [=];
    if(private.getvalues(values)) {
      for (arg in field_names(values)) {
	if(has_field(private.autocli[private.lastmethod], 'parameters')&&
	   has_field(private.autocli[private.lastmethod].parameters, arg)) {
	  values[arg] := private.autocli[private.lastmethod].parameters[arg].default;
	}
      }
    }
    return values;
  }
  
  # Get values from the cli
  private.getvalues :=function(ref values) {
    wider private;
    if(has_field(private.autocli, private.lastmethod)) {
      val values := private.autocli[private.lastmethod].form.get();
      if(!is_record(values)) {
	throw('Inputs are invalid: please check');
	return F;
      }
      else {
	return T;
      }
    }
    else {
      throw('CLI and last function are inconsistent');
      return F;
    }
  }
  
  # Set values in the cli
  private.setvalues :=function(values) {
    wider private;
    if(is_record(values)) {
      for (arg in field_names(values)) {
	if(has_field(private.autocli[private.lastmethod], 'parameters')&&
	   has_field(private.autocli[private.lastmethod].parameters, arg)&&
	   is_record(private.autocli[private.lastmethod].parameters[arg])) {
	  private.autocli[private.lastmethod].parameters[arg].value := values[arg];
	}
      }
    }
    private.autocli[private.lastmethod].form.fillcli(private.autocli[private.lastmethod].parameters);
    return T;
  }
  
  # Send updated values to the cli
  private.setupdated := function(method, values) {
    wider private;
    if(has_field(private.autocli[method], 'parameters')) {
      updaterec := [=];
      for (arg in field_names(values)) {
	if(has_field(private.autocli[method].parameters, arg)&&
	   has_field(private.autocli[method].parameters[arg], 'dir')&&
	   private.autocli[method].parameters[arg].dir!='in') {
	  updaterec[arg] := private.autocli[method].parameters[arg];
	  if(is_record(updaterec[arg])) {
	    updaterec[arg].value := values[arg];
	  }
	}
      }
      private.autocli[method].form.fillcli(updaterec);
    }
    return T;
  }
  
  # Find the titles for the autocli frames
  private.titles := types.meta(private.type, ctors=(private.mode=='construct'),
			       globals=(private.mode=='global'),
			       addhelp=T);
  
  # If we have no specific method, get all the methods for this tool
  if(is_unset(methods)) {
    if(is_unset(private.tool)) {
      methods := field_names(private.titles);
    }
    else {
      methods := sort(field_names(private.titles));
    }
  }
  if(length(methods)==0) {
    note('No cli: tool has no functions');
    return F;
  }
  private.methods := methods;
  private.lastmethod:=unset;
  
  # Call back functions
  private.commands["go"] := function(values, command) {
    wider private;
    private.rec := private.getexecrec(values);
    if(is_fail(private.rec)) fail;
    
    # Use the subsequence to execute as directed
    private.execute[type] := private.tms.execute();
    private.execute[type]->run(private.rec);
    
    # It succeeded! Now finish up
    await private.execute[type]->*;
    if($name=='done') {
      private.rec := $value;
      if(private.mode=='construct') {
	self->done(private.rec.tool);
      }
      else {
	# Fill the parameters record with any results from 
	# the execution and refresh the CLI. Only update the
	# inout or out parameters
	if(has_field(private.rec, 'data')&&is_record(private.rec.data)) {
	  private.setupdated(private.lastmethod, private.rec.data);
	}
      }
      print "Command succeeded";
      return T;
    }   
    else if ($name=='fail') {
      print "Command failed";
      return F;
    }
    else if ($name=='error') {
      print "Command resulted in error";
      return F;
    } 
    else {
      print "Command resulted in unknown event", $name;
      return F;
    } 
  }
  
  # Script
  private.commands["script"] := function(values, command) {
    rec := private.getexecrec(values);
    if(is_fail(rec)) fail;
    rec.data := values;
    tm.logcommand(rec);
    return T;
  }
  
  # Copycommand
  private.commands["copycommand"] := function(values, command) {
    wider private;
    include 'clipboard.g';
    rec := private.getexecrec(values);
    if(is_fail(rec)) fail;
    rec.data := values;
    dcb.copy(tm.getcommand(rec, F));
    return T;
  } 
  
  private.commands["get"] := function(values, command) {
    wider private;
    label := command;
    if(label=='') label:='lastsave';
    values := inputs.getvalues(tool, private.lastmethod, label);
    private.setvalues(values);
    return T;
  }
  
  private.commands["save"] := function(values, command) {
    wider private;
    values := [=];
    if(private.getvalues(values)) {
      label :=  command;
      if(label=='') label:='lastsave';
      inputs.savevalues(tool, private.lastmethod, values, label);
    }
  } 
  
  # Copy button
  private.commands["copy"] := function(values, command) {
    include 'clipboard.g';
    dcb.copy(values);
  } 
  
  # Paste button
  private.commands["paste"] := function(values, command) {
    wider private;
    include 'clipboard.g';
    values := dcb.paste();
    if(is_record(values)) {
      private.setvalues(values);
    }
    else {
      note ('Clipboard does not contain an inputs record');
      return F;
    }
  }
  
  # Paste button
  private.commands["web"] := function(values, command) {
    rec:=tm.where(private.type);
    if(is_record(rec)&&has_field(rec, 'package')&&has_field(rec, 'module')){
      what := spaste(rec.package, '.', rec.module, '.', private.type);
      if(is_string(private.lastmethod)&&(private.lastmethod!='')) {
	what := spaste(what, '.', private.lastmethod);
      }
      note(spaste('Driving browser to help on ', what));
      help(spaste('Refman:', what));
    }
    else {
      note('No web help available', priority='WARN');
    }
  }
  
  private.commands["?"] := function(values, command) {
    printf('Available commands:\n');
    printf('   inp                    - show current inputs\n');
    printf('   help                   - show help for current inputs\n');
    printf('   web                    - show web help for current function\n');
    printf('   go                     - execute function\n');
    printf('   reset                  - reset inputs to defaults\n');
    printf('   quit                   - quit this function\n');
    printf('   save [keyword]         - save current inputs to keyword\n');
    printf('   get  [keyword]         - get inputs from keyword\n');
    printf('   copy                   - copy current inputs to clipboard\n');
    printf('   paste                  - paste current inputs from clipboard\n');
    printf('   copycommand            - copy command to clipboard\n');
    return T;
  }
  
  # Reset button
  private.commands["reset"] := function(values, command) {
    wider private;
    private.setvalues(private.getdefaults());
    return T;
  }
  
  # Function to fill the frame and whenevers: defer as late as possible
  # This is executed only when the user selects a given method
  private.makeautocli := function(method) {
    
    wider private;
    
    # If we have more than one method then we will need
    # a whenever to select methods from the listbox
    if(!is_unset(private.lastmethod)&&(method==private.lastmethod)) return T;
    
    if(!has_field(private.autocli, method)) private.autocli[method] := [=];
    
    if(!has_field(private.autocli[method], 'parameters')) {
      private.autocli[method].parameters :=
	  private.tms.getuiparameters(private.type, method,
				      private.mode).args;
      if(is_fail(private.autocli[method].parameters)) fail;
    }
    
    private.autocli[method].form:=
	autocli(params=private.autocli[method].parameters,
		title=spaste(title, ': ', method));
    
    if(is_fail(private.autocli[method].form)) fail;
    
    if(!is_agent(private.autocli[method].form))
	return throw('Cannot create autocli for ', method);
    
    private.autocli[method].form.setcallbacks(private.commands);
  }
  
  # Loop over methods
  self.loop := function() {
    wider private;
    if(private.mode=='contruct') {
      print "Starting CLI for construction of ", private.type;
      private.prompt := spaste(private.type,'.');
    }
    else {
      if(private.mode=='global') {
	print "Starting CLI for execution of ", private.type;
	private.prompt := spaste(private.type,'.');
      }
      else {
	print "Starting CLI for execution of the functions of ", private.tool;
	private.prompt := spaste(private.tool,'.');
      }
    }
    if(!is_unset(private.type)) {
      includefiles := types.getincludefile(private.type);
      if (is_string(includefiles)) {
	for (file in includefiles) {
	  ok := eval(spaste('include \'', file, '\''));
	}
	if (is_fail(ok)) {
	  throw('Could not include file ', includefiles);
	}
      }
    }
    
    # Loop over functions or constructors
    retry:=T;
    while(retry) {
      if(length(private.methods)>1) { 
	print "Choose a function from [<return> to finish]: ", private.methods;
	method:=readline(private.prompt);
      }
      else {
	method := private.methods;
      }
      if(strlen(method)==0) {
	print "Exiting from CLI";
	retry := F;
      }
      else if(!any(method==private.methods)) {
	print "Unknown function :", method;
      }
      else {
	if(is_fail(private.makeautocli(method))) fail;
	private.lastmethod := method;
	if(private.mode=='global') {
	  header:=spaste('Inputs for function ', method);
	  prompt:=spaste(private.prompt, method,'>');
	  footer:=spaste('Exiting from function ', method,
			 ', please select another function');
	}
	else {
	  header:=spaste('Inputs for function ', tool, '.', method);
	  prompt:=spaste(private.prompt, method,'>');
	  footer:=spaste('Exiting from function ', tool, '.', method,
			 ', please select another function');
	}
	# Loop over commands:
	# Read first commmand and then use a whenever to get more
	private.autocli[method].form.loop(header, prompt, footer);
	if(private.mode=='construct') retry := F;
      }
    }
  }

}

