# toolguiserver: Serves GUIs for tools
#
#   Copyright (C) 1998,1999,2000,2001,2002,2003
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
#   $Id: toolguibasefunction.g,v 19.2 2004/08/25 02:05:58 cvsmgr Exp $
#

pragma include once;

include 'widgetserver.g';

# Base function for constructors, toolfunctions and tools
# Looks harder than it is. Uses a simple subsequence in 
# toolmanagersupport to actually do the work.

const toolguibasefunction := subsequence(type, ref tool=unset, title=unset,
					 ref parent=unset, methods=unset,
					 mode='construct',
					 hints=[=], widgetset=dws) {
  
  include 'note.g'

  private := [=];
  
  include 'toolmanagersupport.g';

  private.tms := toolmanagersupport;

  private.gui := [=];
  private.type := type;
  private.title := title;
  private.methods := methods;
  private.tool := tool;
  private.mode := mode;
  private.hints := hints;
  
  private.whenevers := [];
  private.pushwhenever := function() {
    wider private;
    private.whenevers[len(private.whenevers) + 1] := last_whenever_executed();
  }
  
  # The following two functions are used to lock the entire subsequence
  # so that only one thing can be done at once
  private.isbusy := F;
  
  const private.lock := function() {
    wider private;
    if(!private.isbusy) {
      private.isbusy := T;
      for (i in "commands inputs save get done dismiss go web") {
	field := spaste(i, 'button');
	if(has_field(private, field)&&is_agent(private[field])) {
	  private[field]->disable();
	}
      }
      return T;
    }
    else {
      return F;
    }
  }
  const private.unlock := function() {
    wider private;
    private.isbusy := F;
    for (i in "commands inputs save get done dismiss go web webbutton") {
      field := spaste(i, 'button');
      if(has_field(private, field)&&is_agent(private[field])) {
	private[field]->enable();
      }
    }
    return T;
  }
  
  const private.getexecrec := function() {
    wider private;

    values := [=];
    if(!private.getvalues(private.lastmethod, values)) {
      errmsg := 'Arguments are invalid';
      self->error(errmsg);
      return throw(errmsg);
    }

    # Set up values for execution
    rec := [=];
    rec.tool := private.tool;
    rec.method := private.lastmethod;
    rec.data := values;
    rec.mode := private.mode;
    rec.newtool := unset;
    rec.isliteral := private.getliteral();

    # Need to check values in various ways
    if(private.mode=='construct') {
      if(has_field(values, 'toolname')) {
	# Output is constructor
	include 'toolmanager.g';
	rec.newtool := tm.getnewtoolname(values.toolname);
	note('Execution will construct new tool ', rec.newtool);
	rec.tool := rec.newtool;
	private.tool := rec.newtool;
      }
    }
    else if(private.mode=='item') {
      if(has_field(values, 'return')) {
	# Output is constructor
	include 'toolmanager.g';
	if (is_unset(values.return)) {
          retname:= private.getdefaults().return;
	} else {
          retname:= values.return;
        };
	rec.newtool := tm.getnewitemname(retname);
	note('Execution will construct new item ', rec.newtool);
      }
    }
    else {
      # Look to see if any of the arguments are tools
      toolname := private.gettool(values);
      if(toolname!='') {
	rec.newtool := toolname;
	note('Execution will create output tool ', toolname);
      }
    }
    # Due to a design error in types.g we have to search
    # explicitly for the type of a global function
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
    
  # When we go, get the values from the gui, make the 
  # subsequence to do the execution and wait for a done
  # event
  private.run := function() {
    
    wider private, self;

    its := [=];
    
    its.done := function() {
      wider private;
      if(has_field(private.execute[private.rec.key], 'done')) {
	private.execute[private.rec.key].done();
	private.execute[private.rec.key]:=F;
      }
      if(private.mode!='construct') {
	private.killbutton->disabled(T);
	private.killbutton->background('grey');
      }
      deactivate its.whenevers;
    }

    its.whenevers := [];
    
    # Need to kill these whenevers, as well
    its.pushwhenever := function() {
      wider its;
      its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
    }

    private.rec := private.getexecrec();

    if(is_fail(private.rec)) {
      private.unlock();
      fail;
    }
    
    # Use the toolmanager subsequence to execute but not block
    private.rec.key := spaste(private.rec.type, ':', private.rec.tool);
    private.execute[private.rec.key] := private.tms.execute();
    if(!is_agent(private.execute[private.rec.key])) {
      if(is_fail(private.execute[private.rec.key])) {
	errmsg := paste('Toolmanager could not execute command for ',
			private.rec.tool, ':',
			private.execute[private.rec.key]::message);
	self->fail(errmsg);
	return F;
      }
      else {
	errmsg := paste('Toolmanager could not execute command for ',
			private.rec.tool);
	self->fail(errmsg);
	return F;
      }
    }
    private.execute[private.rec.key]->run(private.rec);

    # Mode specific actions?
    if(private.mode!='construct') {
      private.killbutton->disabled(F);
      private.killbutton->background('red');
    }
    
    # The execution caused an error: just unlock the frame,
    # deactivate and continue. 
    whenever private.execute[private.rec.key]->error do {
      self->error($value);
      private.unlock();
      its.done();
    } its.pushwhenever();
    
    # It failed! Kill everything at the higher level
    whenever private.execute[private.rec.key]->fail do {
      self->fail($value);
      private.unlock();
      its.done();
    } its.pushwhenever();
    
    # It succeeded! Now finish up. 
    whenever private.execute[private.rec.key]->done do {
      if(is_record(private)&&is_record(self)) {
	private.rec := $value;
	private.unlock();
	its.done();
	tool := private.rec.tool;
	type := private.rec.type;
	method := private.rec.method;
	mode := private.rec.mode;
	# For an item, just send a go
	if(private.rec.mode=='item') {
	  data := private.rec.data;
	  newtool := private.rec.newtool;
	  private.tms.invokesendcallback(newtool);
	  self.done();
	  self->go_return([method=method, tool=tool, type=type, mode=mode,
			   values=data, newtool=newtool]);
	  val self := F;
	}
	# If constructing, only a go is needed
	else if(private.rec.mode=='construct') {
	  data := private.rec.data;
	  self.done();
	  self->go_return([method=method, tool=tool, type=type, mode=mode,
			   values=data]);
	  val self := F;
	}
	# If we made a new tool as a by product then both a show and
        # a go are needed
	else if(!is_unset(private.rec.newtool)) {
	  newtool := private.rec.newtool;
	  self->go_return([method=method, tool=tool, newtool=newtool,
			   type=type, mode=mode,
			   values=tm::data[tool]]);
	}
	# Otherwise we just executed a tool function
	else {
	  # Fill the parameters record with any results from 
	  # the execution and refresh the GUI. Only update the
	  # inout or out parameters
	  tool := private.rec.tool;
	  type := private.rec.type;
	  method := private.rec.method;
	  private.setupdated(private.rec.method, private.rec.data);
	  toolrecord := symbol_value(tool);
	  if (is_record(toolrecord)&&has_field(toolrecord, 'updatestate')&&
	      has_field(private, 'stateframe')) {
	    toolrecord.updatestate(private.stateframe, 'update');
	  }
	  self->go_return([method=method, tool=tool, type=type, mode=mode,
			   values=tm::data[tool]]);
	}
      }
    } its.pushwhenever();
    
    return T;
  }
  
  # Get the default values
  private.getdefaults :=function() {
    wider private;
    values := [=];
    for (arg in field_names(private.gui[private.lastmethod].parameters)) {
      values[arg] := private.gui[private.lastmethod].parameters[arg].default;
    }
    return values;
  }
  
  # Set active frame
  private.setactive := function(method) {
    wider private;

    custom := private.custom->state();

    type := private.gui[method].gui;

    widgetset.tk_hold();

    # Make the top level frame?
    if(has_field(private.gui[method], 'frame')) {
      private.gui[method].frame->unmap();
    }
    else {
      private.gui[method].frame := 
	  widgetset.frame(private.commandframe);
      private.gui[method].frame->unmap();

      # Add labelling
      if(has_field(private.titles, method)&&
	 has_field(private.titles[method], 'title')) {
	if(private.mode=='construct') {
	  labeltext := paste('Constructor:', method);
	}
	else {
	  labeltext := paste('Function:', method);
	}
	private.gui[method].label1 := 
	    widgetset.label(private.gui[method].frame, 
			    text=labeltext,
			    borderwidth=0, justify='center');
	private.gui[method].label := 
	    widgetset.label(private.gui[method].frame, 
			    text=sprintf('%.70s', private.titles[method].title),
			    borderwidth=0, justify='center');
	private.gui[method].shorthelp := private.titles[method].title;
      }
      else {
	labeltext := spaste('Arguments for ', private.tool, '.', method);
	if(is_unset(private.tool)) {
	  labeltext := spaste('Arguments for ', method);
	}
	private.gui[method].label := widgetset.label(private.gui[method].frame,
						     labeltext,
						     borderwidth=0,
						     justify='center');
      }
    }

    # Now make the custom or autogui frames, etc
    if(custom&&(type!='autogui')) {
      # Has a custom frame: we need to rebuild it since the underlying
      # details might have changed
      if(has_field(private.gui[method], 'customgui')&&
	 has_field(private.gui[method].customgui, 'done')) {
	private.gui[method].customgui.done();
	private.gui[method].customgui := F;
      }
      note(paste('Building custom gui for', type));
      if(!has_field(private.gui[method], 'customframe')||
	 !is_agent(private.gui[method]['customframe'])) {
	private.gui[method].customframe:=
	    widgetset.frame(private.gui[method].frame);
      }
      toolrecord := symbol_value(private.tool);
      private.gui[method].customgui:=
	  toolrecord[type](parent=private.gui[method].customframe);
      # Set the state of the custom gui
      include 'inputsmanager.g';
      values := inputs.getvalues(tool, method);
      private.gui[method].customgui.setstate(values);
      private.custom->state(custom);
      private.gui[method].activegui := type;
      # Map it in
      if(has_field(private.gui[method].customgui, 'gui')) {
	private.gui[method].customgui.gui();
      }
      if(has_field(private.gui[method], 'autoframe')) {
	private.gui[method].autoframe->unmap();
      }
      private.gui[method].customframe->map();
    }
    else {
      if(type!='autogui') {
	note(paste('Showing auto gui for', type));
      }
      # Make both the autogui and a custom frame
      if(!has_field(private.gui[method], 'autoframe')) {
	private.gui[method].autoframe :=
	    widgetset.frame(private.gui[method].frame,
			    side='bottom',
			    expand='x');
	if(length(private.gui[method].parameters)) {
	  include 'autogui.g';
	  private.gui[method].autogui:=
	      autogui(params=private.gui[method].parameters,
		      toplevel=private.gui[method].autoframe,
		      relief='flat',
		      autoapply=F,
		      expand='x',
		      map=F);
	  if(is_fail(private.gui[method].autogui)) {
	    private.gui[method].frame->map();
	    widgetset.tk_release();
	    fail;
	  }
	  if(!is_agent(private.gui[method].autogui)) {
	    private.gui[method].frame->map();
	    widgetset.tk_release();
	    return throw('Cannot make autogui for ', method);
	  }
	  if(is_record(private.hints)) {
	    private.gui[method].autogui.setcontexts(private.hints);
	  }
	}
	else {
	  private.gui[method].autogui:=
	      widgetset.label(private.gui[method].autoframe,
			      'No arguments for this function');
	}
      }
      # Has an autogui frame
      private.gui[method].activegui := 'autogui';
      if(has_field(private.gui[method], 'customframe')) {
	private.gui[method].customframe->unmap();
      }
      private.gui[method].autoframe->map();
    }

    private.gui[method].frame->map();

    # Now map everything in and release
    widgetset.tk_release();

    return T;
  }
  
  # Get values from the gui
  private.getvalues :=function(method, ref values) {
    wider private;
    if(private.gui[method].activegui=='autogui') {
      if(is_record(private.gui[method].autogui)&&
	 has_field(private.gui[method].autogui, 'get')) {
	val values := private.gui[method].autogui.get();
	if(!is_record(values)) {
	  throw('Arguments are invalid: please check');
	  return F;
	}
      }
    }
    else {
      val values := private.gui[method].customgui.getstate(T);
      if(!is_record(values)) {
	values := [=];
	throw('Arguments are invalid: please check');
	return F;
      }
    }
    return T;
  }
  
  # Set values in the gui
  private.setvalues :=function(values) {
    wider private;
    if(private.gui[private.lastmethod].activegui=='autogui') {
      if(is_record(values)) {
	for (arg in field_names(values)) {
	  if(has_field(private.gui[private.lastmethod], 'parameters')&&
	     has_field(private.gui[private.lastmethod].parameters, arg)) {
	    private.gui[private.lastmethod].parameters[arg].value := values[arg];
	  }
	}
      }
      if(has_field(private.gui[private.lastmethod].autogui, 'fillgui')) {
	private.gui[private.lastmethod].autogui.fillgui(private.gui[private.lastmethod].parameters);
      }
    }
    else {
      private.gui[private.lastmethod].customgui.setstate(values);
    }
    return T;
  }
  
  # Get any output tool name that is not the return
  private.gettool :=function(values) {
    wider private;
    if(private.gui[private.lastmethod].activegui=='autogui') {
      for (arg in field_names(values)) {
	if(has_field(private.gui[private.lastmethod].parameters, arg)&&
	   private.gui[private.lastmethod].parameters[arg].ptype=='tool') {
	  name := values[arg];
	  include 'toolmanager.g';
          if(is_string(name))
	     name := tm.getnewtoolname(name);
          else
             name := 'defaulttool';
	  return name;
	}
      }
    }
    return '';
  }
  
  # Get any output tool name
  private.getliteral :=function() {
    wider private;
    rec := [=];
    for (arg in field_names(private.gui[private.lastmethod].parameters)) {
      rec[arg] := private.gui[private.lastmethod].parameters[arg].isliteral;
    }
    return rec;
  }
  
  # Set values in the gui
  private.resetvalues :=function() {
    wider private;
    if(private.gui[private.lastmethod].activegui=='autogui') {
      if(has_field(private.gui[private.lastmethod].autogui, 'fillgui')) {
	private.gui[private.lastmethod].autogui.fillgui(private.gui[private.lastmethod].parameters);
      }
    }
    else {
      private.gui[private.lastmethod].customgui.setstate(values);
    }
    return T;
  }
  
  # Send updated values to the gui
  private.setupdated := function(method, values) {
    wider private;
    if(private.gui[method].activegui=='autogui') {
      if(has_field(private.gui[method], 'parameters')) {
	updaterec := [=];
	for (arg in field_names(values)) {
	  if(has_field(private.gui[method].parameters, arg)&&
	     has_field(private.gui[method].parameters[arg], 'dir')&&
	     private.gui[method].parameters[arg].dir!='in') {
	    updaterec[arg] := private.gui[method].parameters[arg];
	    updaterec[arg].value := values[arg];
	  }
	}
	if(has_field(private.gui[private.lastmethod].autogui, 'fillgui')) {
	  private.gui[method].autogui.fillgui(updaterec);
	}
      }
    }
    else {
      private.gui[private.lastmethod].customgui.setstate(values);
    }
    return T;
  }
  
  # Send updated values to the gui
  private.setallupdated := function(method, values) {
    wider private;
    if(private.gui[method].activegui=='autogui') {
      if(has_field(private.gui[method], 'parameters')) {
	updaterec := [=];
	for (arg in field_names(values)) {
	  if(has_field(private.gui[method].parameters, arg)) {
	    updaterec[arg] := private.gui[method].parameters[arg];
	    updaterec[arg].value := values[arg];
	  }
	}
	if(has_field(private.gui[private.lastmethod].autogui, 'fillgui')) {
	  private.gui[method].autogui.fillgui(updaterec);
	}
      }
    }
    else {
      private.gui[private.lastmethod].customgui.setstate(values);
    }
    return T;
  }
  
# Function to fill the frame and whenevers: defer as late as possible
# This is executed only when the user selects a given method
  private.showgui := function(method, group) {
    
    wider private;

    # De-select the old value
    if( has_field(private.groupmethods, private.lastgroup) &&
	has_field(private.methodslist, private.lastgroup) ) {
      sel := as_string(private.methodslist[private.lastgroup]->selection());
      if(sel!='') {
	value := private.methodslist[private.lastgroup]->get(sel);
	private.methodslist[private.lastgroup]->delete(sel);
	private.methodslist[private.lastgroup]->insert(value, sel);
      }
    }

#
# Make or map in the required frames
#
    if(!has_field(private.gui, method)) {
      private.gui[method] := [=];
    }
    if(!has_field(private.gui[method], 'parameters')) {
      uiparameters := private.tms.getuiparameters(private.type, method,
						  private.mode);
      if(is_fail(uiparameters)) fail;
      private.gui[method].parameters := uiparameters.args;
      private.gui[method].gui := uiparameters.gui.name;
      private.gui[method].activegui := uiparameters.gui.name;
      if(is_fail(private.gui[method].parameters)) fail;
    }
    if(private.gui[method].gui!='autogui') {
      private.custom->state(T);
      private.customframe->map();
    }
    else {
      private.custom->state(F);
      private.customframe->unmap();
    }

    widgetset.tk_hold();

    private.setactive(method);    

    # Switch off the kill button
    if(private.mode!='construct') {
      private.killbutton->disabled(T);
      private.killbutton->background('grey');
    }

    values := [=];
    private.getvalues(method, values);

    # Now unmap old group and map in new group
    if(has_field(private, 'groupmethodstopframe')&&
	has_field(private.groupmethodstopframe, group)&&
	has_field(private.groupmethodstopframe, private.lastgroup)) {
      private.groupmethodstopframe[private.lastgroup]->unmap();
      private.groupmethodstopframe[group]->map();
    }

    if(has_field(private.gui, private.lastmethod)) {
      private.gui[private.lastmethod].frame->unmap();
    }
    private.gui[method].frame->map();

    # Select the current method
    if(has_field(private.groupmethods, group)) {
      i := 0;
      for (m in private.groupmethods[group]) {
	if( m==method && is_agent(private.methodslist[group]) ) {
	  private.methodslist[group]->select(as_string(i));
	  private.methodslist[group]->see(as_string(i));
	  break;
	}
	i+:=1;
      }
    }
    widgetset.tk_release();

    private.lastgroup := group;
    private.lastmethod:=method;

    return T;
  } # showgui
  
# Function to find the group of a method
  private.findgroup := function(method) {
    wider private;
    for (group in field_names(private.groupmethods)) {
      if(any(private.groupmethods[group]==method)) {
	return group;
      }
    }
    return private.groupmethods[1];
  }
  
  #### Start of construction phase    
  
  # Find the titles for the autogui frames
  ctors := F;
  if(private.mode=='construct') {
    ctors := T;
  }
  globals := F;
  if(private.mode=='global') {
    globals := T;
  }
  private.titles := types.meta(private.type, ctors=ctors, globals=globals,
			       addhelp=T);
  
  # If we have no specific method, get all the methods for this tool
  if(is_unset(methods)) {
    private.methods := field_names(private.titles);
  }
  
  # There might be no functions to show. 
  if(length(private.methods)==0) {
    fail 'There are no functions to show';
  }
  
  groups := array('basic', length(private.methods));
  private.lastmethod:=unset;
  ngroups := 0;
  private.groupmethods := [=];
  lengthgroupmethods := [=];
  uiparameters := F;
  for (method in private.methods) {
    ngroups +:= 1;
    if(has_field(private.titles[method], 'group')) {
      groups[ngroups] := as_string(private.titles[method].group);
    }
  }
  # Sort alphabetically on groups
  private.methods := sort_pair(groups, private.methods);
  groups  := sort(groups);
  # If only one group, then substitute all
  if(length(unique(groups))==1) groups := array('all', length(private.methods));
  # Now figure out assignments
  for (i in 1:len(private.methods)) {
    group := groups[i];
    method := private.methods[i];
    if(!has_field(private.groupmethods, group)) {
      private.groupmethods[group] := '';
      lengthgroupmethods[group] := 0;
    }
    lengthgroupmethods[group] +:= 1;
    private.groupmethods[group][lengthgroupmethods[group]] := method;
  }
  # Add an all grouping
  if(length(private.groupmethods)>1) private.groupmethods['all'] :=
      sort(private.methods);
  uiparameters := private.tms.getuiparameters(private.type,
					      private.methods[1],
					      private.mode);
  if(is_fail(uiparameters)) fail;
  
  widgetset.tk_hold();
  if(is_agent(parent)) {
    private.frame := widgetset.frame(parent, side='top',
				     relief='ridge', expand='x');
    if(private.mode!='item') {
      private.rightmenubar := widgetset.frame(private.frame, side='left',
					      relief='flat', expand='x');
      private.padleft := widgetset.frame(private.rightmenubar);
      private.label := widgetset.label(private.rightmenubar, title,
				       borderwidth=0);
      private.padright := widgetset.frame(private.rightmenubar);
    }
  }
  else {
    private.frame := widgetset.frame(side='top',
				     title=spaste(title, ' (AIPS++)'),
				     relief='ridge');
  }
  
  private.commandtopframe := widgetset.frame(private.frame, side='right');
  private.commandframe := widgetset.frame(private.commandtopframe,
					  side='bottom', relief='ridge');
  
# If more than one method then we will make a listbox containing 
# the private.methods
  private.methodslist := [=];
  if(length(private.methods)>1) {
    private.methodsmenuframe := widgetset.frame(private.commandtopframe,
						side='top', expand='y',
						relief='ridge');
    private.methodslabel := [=];
    private.methodsframe := widgetset.frame(private.methodsmenuframe,
					    side='top',
					    expand='none');
#
# Add group listing?
#
    if(len(private.groupmethods)>1) {
      private.groupsswitch :=
	  widgetset.selectablelist(private.methodsframe,
				   private.methodsframe,
				   label='Function group',
				   list=field_names(private.groupmethods),
				   relief='raised',
				   hlp='Select group of functions for display',
				   nbreak=30,
				   casesensitive=T);
    }
    for (group in field_names(private.groupmethods)) {
      private.groupmethodstopframe[group] :=
	  widgetset.frame(private.methodsframe,
			  side='top');
      private.groupmethodstopframe[group]->unmap();
      if(private.mode=='construct') {
	private.methodslabel[group] :=
	    widgetset.label(private.groupmethodstopframe[group],
			    paste(private.type, group, 'constructors'),
			    borderwidth=0);
	private.methodslabel[group].shorthelp := 'Functions for constructing new tools of the specified type';
      }
      else if(private.mode=='global') {
	private.methodslabel[group] :=
	    widgetset.label(private.groupmethodstopframe[group],
			    paste(group, 'global functions'),
			    borderwidth=0);
	private.methodslabel[group].shorthelp := 'Associated global functions';
      }
      else {
	private.methodslabel[group] :=
	    widgetset.label(private.groupmethodstopframe[group],
			    paste(group, 'functions'));
	private.methodslabel[group].shorthelp := 'Functions available from this tool';
      }
      private.groupmethodsframe[group] :=
	  widgetset.frame(private.groupmethodstopframe[group], side='left');

#
# Add methods listing?
#
      private.methodslist[group] :=
	  widgetset.listbox(private.groupmethodsframe[group], 
			    height=min(30,
				       length(private.groupmethods[group])),
			    mode='browse',
			    background='lightgrey');
      for (i in 1:length(private.groupmethods[group])) {
	private.methodslist[group]->insert(private.groupmethods[group][i]);
      }
      private.methodslist[group]->select('0');
      if(length(private.groupmethods[group])>30) {
	private.vsb[group] :=
	    widgetset.scrollbar(private.groupmethodsframe[group]);
	whenever private.methodslist[group]->yscroll do {
	  private.vsb[private.lastgroup]->view($value);
	} private.pushwhenever();
	whenever private.vsb[group]->scroll do {
	  private.methodslist[private.lastgroup]->view($value);
	} private.pushwhenever();
      }
    }
  }

# Go button

# Frame for menu buttons
  private.bottomframe := widgetset.frame(private.commandframe,
					 side='top', expand='x');
  private.bottomleftframe := widgetset.frame(private.bottomframe, side='left',
					     expand='x');
  private.bottompadleftframe := widgetset.frame(private.bottomleftframe,
						side='right', expand='x');
  private.bottombottomleftframe := widgetset.frame(private.bottomframe,
						   side='left',
						   expand='x');
  if(private.mode=='construct') {
    private.gobutton := widgetset.button(private.bottomleftframe,
					 'Create', type='action');
    private.gobutton.shorthelp := 'Create the tool';
  }
  else if(private.mode=='item') {
    private.gobutton := widgetset.button(private.bottomleftframe,
					 'Create and Send', type='action');
    private.gobutton.shorthelp := 'Create the data item and send to the GUI input';
#
  }
  else {
    private.gobutton := widgetset.button(private.bottomleftframe, 'Go',
					 type='action');
    private.gobutton.shorthelp := 'Execute the function';
  }
  
# Custom button
  
  private.customframe := widgetset.frame(private.bottomleftframe, side='left');
  if(is_fail(private.customframe)) {
    widgetset.tk_release();
    return throw('Cannot make custom frame ', private.customframe::message);
  }
  private.custom := widgetset.button(private.customframe, 'Custom',
				     type='check');
  if(is_fail(private.custom)) fail;
  private.custom.shorthelp := 'Show the custom gui';
  private.customframe->unmap();
  whenever private.custom->press do {
    if(private.lock()) {
      private.setactive(private.lastmethod);
      private.unlock();
    }
  } private.pushwhenever();
  
  
# Kill button
  if(private.mode!='construct') {
    private.killframe := widgetset.frame(private.bottomleftframe, side='left', expand='none');
    private.killbutton := widgetset.button(private.killframe, 'Running: abort?', background='grey');
    private.killbutton->disabled(T);
    private.killbutton.shorthelp := 'Kill this tool completely. Use with care since you will see many lines of needlessly worrying error messages.';
    whenever private.killbutton->press do {
      if(private.mode=='tool') {
	include 'toolmanager.g';
	result := tm.killtool(private.rec.tool);
	if(is_boolean(result)&&result) {
	  private.execute[private.rec.key]->kill();
	}
      }
      deactivate private.whenevers;
    } private.pushwhenever();
  }
  private.webbutton := widgetset.button(private.bottomleftframe, 'Function help');
  private.webbutton.shorthelp := 'Drive your browser to help for this function';
  whenever private.webbutton->press do {
    if(private.lock()) {
      rec:=private.tms.where(private.type);
      if(is_record(rec)&&has_field(rec, 'package')&&has_field(rec, 'module')){
        if(private.mode != 'global')
	   what := spaste(rec.package, '.', rec.module, '.', private.type);
        else
	   what := spaste(rec.package, '.', rec.module);
	if(is_string(private.lastmethod)&&(private.lastmethod!='')) {
	  if(private.mode=='construct') {
	    what := spaste(what, '.', private.lastmethod, '.constructor');
	  }
	  else {
            if(private.mode != 'global')
	       what := spaste(what, '.', private.lastmethod, '.function');
            else
	       what := spaste(what, '.', private.lastmethod);
	  }
	}
	note(spaste('Driving browser to help on ', what));
	help(spaste('Refman:', what));
      }
      else {
	note('No web help available', priority='WARN');
      }
      private.unlock();
    }
  } private.pushwhenever();
  private.bottompadrightframe := widgetset.frame(private.bottomleftframe,
						 side='right', expand='x');
  
  if(private.mode!='item') {
    # Menu for controlling commands
    private.commandsbutton := widgetset.button(private.bottombottomleftframe,
					       'Command',
					       relief='groove',
					       type='menu');
    private.commandsbutton.shorthelp := 'Various operations on equivalent Glish command';
    private.commandsmenu := [=];
    private.commandsmenu['copy'] := widgetset.button(private.commandsbutton,
						     'Copy command to clipboard');
    # Copycommand
    whenever private.commandsmenu['copy']->press do {
      if(private.lock()) {
	rec := private.getexecrec();
	if(!is_fail(rec)) {
	  dcb.copy(private.tms.getcommand(rec, doglobal=F));
	}
	private.unlock();
      }
    } private.pushwhenever();
    
    
    # Script
    private.commandsmenu['script'] := widgetset.button(private.commandsbutton,
						       'Copy command to scripter');
    whenever private.commandsmenu['script']->press do {
      if(private.lock()) {
	rec := private.getexecrec();
	if(!is_fail(rec)) {
	  private.tms.logcommand(rec);
	}
	private.unlock();
      }
    } private.pushwhenever();
    
    # Script
    private.commandsmenu['log'] := widgetset.button(private.commandsbutton,
						    'Copy command to logger');
    whenever private.commandsmenu['log']->press do {
      if(private.lock()) {
	rec := private.getexecrec();
	if(!is_fail(rec)) {
	  note('# ', private.tms.getcommand(rec, F));
	}
	else {
	  throw('Arguments are invalid');
	}
	private.unlock();
      }
    } private.pushwhenever();
  }
  
  # Menu for controlling inputs
  private.inputsbutton := widgetset.button(private.bottombottomleftframe, 'Arguments',
					   relief='groove',
					   type='menu');
  private.inputsbutton.shorthelp :=
      'Various operations on inputs of currently selected function';
  private.inputsmenu := [=];
  
  include 'inputsmanager.g'
  rec:=inputs.list();
  
  # Copy button
  private.inputsmenu['copy'] := widgetset.button(private.inputsbutton,
						 'Copy arguments to clipboard');
  whenever private.inputsmenu['copy']->press do {
    if(private.lock()) {
      values := [=];
      if(private.getvalues(private.lastmethod, values)) {
	dcb.copy(values);
      }
      else {
	throw('Arguments are invalid');
      }
      private.unlock();
    }
  } private.pushwhenever();
  
  # Paste button
  private.inputsmenu['paste'] := widgetset.button(private.inputsbutton,
						  'Paste arguments from clipboard');
  whenever private.inputsmenu['paste']->press do {
    if(private.lock()) {
      private.setvalues(dcb.paste());
      private.unlock();
    }
  } private.pushwhenever();
  
# Reset button
  private.inputsmenu['reset'] := widgetset.button(private.inputsbutton,
						  'Reset arguments to defaults');
  whenever private.inputsmenu['reset']->press do {
    if(private.lock()) {
      private.setvalues(private.getdefaults());
      private.unlock();
    }
  } private.pushwhenever();
  
  private.inputsmenu['save'] := widgetset.button(private.inputsbutton,
						 'Save arguments to named location');
  # Save button
  whenever private.inputsmenu['save']->press do {
    if(private.lock()) {
      label :=  private.inputsname.get();
      if(label!='') {
	values := [=];
	if(private.getvalues(private.lastmethod, values)) {
	  note(paste('Saving inputs to', label));
	  include 'inputsmanager.g';
	  inputs.savevalues(private.type, private.lastmethod, values, label,
			    dosave=T);
	}
      }
      private.unlock();
    }
  } private.pushwhenever();
  
  private.inputsmenu['restore'] := widgetset.button(private.inputsbutton,
						    'Restore arguments from named location');
  whenever private.inputsmenu['restore']->press do {
    if(private.lock()) {
      label :=  private.inputsname.get();
      if(label!='') {
	include 'inputsmanager.g'
	values := inputs.getvalues(private.type, private.lastmethod, label);
	private.setvalues(values);
	note(paste('Restoring inputs from', label));
      }
      private.unlock();
    }
  } private.pushwhenever();
  
  private.inputsmenu['list'] := widgetset.button(private.inputsbutton, 'List existing named locations for inputs');
  whenever private.inputsmenu['list']->press do {
    include 'inputsmanager.g'
    note('Possible input locations are: ', inputs.list().keywords);
  } private.pushwhenever();
  
  private.dge := widgetset.guientry(expand='x');
  private.inputsname := private.dge.string(private.bottombottomleftframe, 'lastsave', onestring=T);
  
  if(length(private.methods)>0) {
    whenever private.gobutton->press do {
      if(private.lock()) {
	values := [=];
	private.run();
      }
    } private.pushwhenever();
  }
#
# Status area
#
  if (!is_unset(private.tool)) {
    toolrecord := symbol_value(private.tool);
    if (is_record(toolrecord)&&
	has_field(toolrecord, 'updatestate')) {
      private.staterollup := widgetset.rollup(private.frame, side='left',
					      title='Tool status', show=F);
      private.stateframe := widgetset.frame(private.staterollup.frame(),
					    side='left');
      toolrecord.updatestate(private.stateframe, 'INIT');
      private.stateframe->map();
    }
  }
  
# Done button: don't lock/unlock
  private.dismissframe := widgetset.frame(private.frame, side='right');
  if(private.mode=='tool') {
    # Standard done button for a tool
    private.donebutton := widgetset.button(private.dismissframe, 'Done', 
					   type='halt');
    private.donebutton.shorthelp := 'Stop this tool';
    
    whenever private.donebutton->press do {
      wider private;
      if(is_record(private)&&is_record(self)) {
	if(private.mode=='global') {
	  fn := private.lastmethod;
	  mode := private.mode;
	  self.done();
	  self->done_return([method=fn, mode=mode]);
	  val self := F;
	}
	else {
	  tool := private.tool;
	  mode := private.mode;
	  self.done();
	  self->done_return([tool=tool, mode=mode]);
	  val self := F;
	}
      }
    };
  };
  
  private.dismissbutton := widgetset.button(private.dismissframe,
					    'Dismiss',
					    type='dismiss');
  if(private.mode=='global') {
    private.dismissbutton.shorthelp := 'Dismiss this function gui.';
  }
  else if(private.mode=='item') {
    private.dismissbutton.shorthelp := 'Dismiss this item gui.';
  }
  else {
    private.dismissbutton.shorthelp := 'Dismiss this tool gui. The tool remains active and the gui may be shown from the Tools in use menu.';
  }
  whenever private.dismissbutton->press, private.frame->killed do {
    if(is_record(private)&&is_record(self)) {
      if(private.mode=='construct') {
	type := private.type;
	method := private.lastmethod;
	mode := private.mode;
	self.done();
	self->dismiss_return([type=type, method=method, mode=mode]);
	val self := F;
      }
      else if(private.mode=='global') {
	method := private.lastmethod;
	mode := private.mode;
	self.done();
	self->dismiss_return([method=method, mode=mode]);
	val self := F;
      }
      else if(private.mode=='tool') {
	tool := private.tool;
	method := private.lastmethod;
	mode := private.mode;
	self.done();
	self->dismiss_return([tool=tool, method=method, mode=mode]);
	val self := F;
      }
      else if(private.mode=='item') {
	tool := private.tool;
	method := private.lastmethod;
	mode := private.mode;
	self.done();
	self->dismiss_return([tool=tool, method=method, mode=mode]);
	val self := F;
      }
    }
  } private.pushwhenever();
  
  if(private.mode!='item') {
    if(private.mode=='construct') {
      label := 'Constructor help';
    }
    else if(private.mode=='global') {
      label := 'Function help';
    }
    else {
      label := 'Tool help';
    }
    private.toolwebbutton := widgetset.button(private.dismissframe, label);
    private.toolwebbutton.shorthelp := 'Drive your browser to relevant help';

    whenever private.toolwebbutton->press do {
      if(private.lock()) {
	rec:=private.tms.where(private.type);
	if(is_record(rec)&&has_field(rec, 'package')&&has_field(rec, 'module')){
	  what := spaste(rec.package, '.', rec.module, '.', private.type);
	  note(spaste('Driving browser to help on ', what));
	  help(spaste('Refman:', what));
	}
	else {
	  note('No web help available', priority='WARN');
	}
	private.unlock();
      }
    } private.pushwhenever();
  }
  
# Make the first autogui
  whenever self->init do {
    wider private;
    private.lock();
    method := private.groupmethods[1][1];
    private.lastmethod := method;
    group := private.findgroup(method);
    private.lastgroup := group;
    private.showgui(method, group);
    values := [=];
    private.getvalues(method, values);
    self->show_return([method=method, values=values, mode=private.mode]);
    deactivate;
    private.unlock();
  } private.pushwhenever();
  
  widgetset.tk_release();

# If we have more than one method then we will need
# a whenever to select private.methods from the listbox
  if(length(private.methods)>1) { 
    for (group in field_names(private.groupmethods)) {
      whenever private.methodslist[group]->select do {
	if(private.lock()) {
	  if(has_field(private.groupmethods, private.lastgroup)) {
	    method := private.groupmethods[private.lastgroup][$value + 1];
	    widgetset.tk_hold();
	    if(is_fail(private.showgui(method, private.lastgroup))) {
	      throw ('Failed to start gui for method ', method);
	    }
	    values := [=];
	    private.getvalues(method, values);
	    self->show_return([method=method, values=values,
			       mode=private.mode]);
	    widgetset.tk_release();
	  }
	  private.unlock();	
	}
      } private.pushwhenever();
    }
  }

  if(has_field(private, 'groupsswitch')) {
    whenever private.groupsswitch->select do {
      if(private.lock()) {
	if(is_record($value)&&has_field($value, 'item')) {
	  widgetset.tk_hold();
	  group := $value.item;
	  method := private.groupmethods[group][1];
	  if(is_fail(private.showgui(method, group))) {
	    throw ('Failed to start gui for method ', method);
	  }
	  values := [=];
	  private.getvalues(method, values);
	  self->show_return([method=method, values=values,
			     mode=private.mode]);
	  widgetset.tk_release();
	}
	private.unlock();
      }
    }
  }
  
  whenever self->show, self->go, self->done do {
    rec := $value;
    event := $name
      if(is_record(private)&&is_record(self)&&
	 is_record(rec)&&has_field(rec, 'method')) {
      if(private.lock()) {
	widgetset.tk_hold();
	group := private.findgroup(rec.method);
	if(event=='show') {
	  if(is_fail(private.showgui(rec.method, group))) {
	    throw ('Failed to start gui for method ', rec.method);
	  }
	  else {
	    if(has_field(rec, 'values')) {
	      private.setallupdated(rec.method, rec.values);
	    }
	  }
	}
	else if(event=='go') {
	  if(is_fail(private.showgui(rec.method, group))) {
	    throw ('Failed to start gui for method ', rec.method);
	  }
	  else {
	    if(has_field(rec, 'values')) {
	      private.setallupdated(rec.method, rec.values);
	    }
	    private.run();
	  }
	  self->show_return(rec);
	}
	else if(event=='done') {
	  if(private.mode=='global') {
	    method := private.lastmethod;
	    mode := private.mode;
	    self.done();
	    self->done_return([method=method, mode=mode]);
	    val self := F;
	  }
	  else {
	    tool := private.tool;
	    method := private.lastmethod;
	    mode := private.mode;
	    self.done();
	    self->done_return([tool=tool, method=method, mode=mode]);
	    val self := F;
	  }
	}
	else if(event=='dismiss') {
	  if((private.mode=='construct')||(private.mode=='global')) {
	    method := private.lastmethod;
	    mode := private.mode;
	    self.done();
	    self->dismiss_return([method=method, mode=mode]);
	    val self := F;
	  }
	  else {
	    tool := private.tool;
	    method := private.lastmethod;
	    mode := private.mode;
	    self.done();
	    self->dismiss_return([tool=tool, method=method, mode=mode]);
	    val self := F;
	  }
	}
	widgetset.tk_release();
	private.unlock();	
      }
    } 
  } private.pushwhenever();
  
# Add the popup help
  result := widgetset.addpopuphelp(private, 5);
  
  self.map := function() {
    wider private;
    private.frame->map();
  }
  
  self.unmap := function() {
    wider private;
    private.frame->unmap();
  }
  
  self.done := function() {
    wider private;
    if(!is_record(self)) return F;
    if(!is_record(private)) return F;
    if(has_field(private, 'whenevers')) {
      deactivate private.whenevers;
    }
    toolrecord := symbol_value(private.tool);
    if (!is_unset(toolrecord)&&has_field(toolrecord,'updatestate')&&
	has_field(private, 'stateframe')) {
      toolrecord.updatestate(private.stateframe, 'DONE');
      private.stateframe->unmap();
      private.stateframe := F;
    }

    for (i in field_names(private)) {
      if(is_agent(private[i])) val private[i] := F;
    }
    val private := F;
  }
}

