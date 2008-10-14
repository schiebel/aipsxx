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
#   $Id: serverguibasefunction.g,v 19.2 2004/08/25 02:04:34 cvsmgr Exp $
#

pragma include once;

include 'widgetserver.g';

# Base function for constructors, toolfunctions and tools
# Looks harder than it is. Uses a simple subsequence in 
# toolmanagersupport to actually do the work.

const serverguibasefunction := subsequence(type, title=unset,
  ref parent=unset, filter=unset, widgetset=dws) {
  
  include 'note.g'

  private := [=];
  
  include 'toolmanagersupport.g';

  private.tms := toolmanagersupport;

  private.gui := [=];
  private.type := type;
  private.filter := filter;
  private.mode := 'tool';
  
  private.whenevers := [=];
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
      for (i in "commands save get done dismiss go web webbutton") {
	private[spaste(i, 'button')]->disable();
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
    for (i in "commands save get done dismiss go web webbutton") {
      private[spaste(i, 'button')]->enable();
    }
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
  
  # Get values from the gui
  private.getvalues :=function(ref values) {
    wider private;
    if(is_record(private.gui[private.lastmethod].autogui)&&
       has_field(private.gui[private.lastmethod].autogui, 'get')) {
      val values := private.gui[private.lastmethod].autogui.get();
      if(!is_record(values)) {
	throw('Arguments are invalid: please check');
	return F;
      }
    }
    return T;
  }
  
  # Set values in the gui
  private.setvalues :=function(values) {
    wider private;
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
    return T;
  }
  
  # Set values in the gui
  private.resetvalues :=function() {
    wider private;
    if(has_field(private.gui[private.lastmethod].autogui, 'fillgui')) {
      private.gui[private.lastmethod].autogui.fillgui(private.gui[private.lastmethod].parameters);
    }
    return T;
  }
  
  # Send updated values to the gui
  private.setupdated := function(method, values) {
    wider private;
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
    return T;
  }
  
# Function to fill the frame and whenevers: defer as late as possible
# This is executed only when the user selects a given method
  private.showgui := function(method) {
    
    wider private;
    
    if(!is_unset(private.lastmethod)&&(method==private.lastmethod)) return T;
    
    if(!has_field(private.gui, method)) {
      private.gui[method] := [=];
    }
    
    if(!has_field(private.gui[method], 'parameters')) {
      uiparameters := private.tms.getuiparameters(private.type, method,
						  private.mode);
      if(is_fail(uiparameters)) {
	return throw('Failed to get parameters for ', method, ':',
		     uiparameters::message);
      }
      private.gui[method].parameters := uiparameters.args;
    }
    
    if(!is_unset(private.lastmethod)&&
       has_field(private.gui, private.lastmethod)&&
       has_field(private.gui[private.lastmethod], 'frame')&&
       is_agent(private.gui[private.lastmethod].frame)) {
      private.gui[private.lastmethod].frame->unmap();
    }

    private.lastmethod:=method;
    

# Make or map in the required frames
#
    if(has_field(private.gui, method)&&
       has_field(private.gui[method], 'frame')&&
       is_agent(private.gui[method].frame)) {
      # Exists: just map in
      widgetset.tk_hold();
      private.gui[method].frame->map();
      widgetset.tk_release();
      return T;
    }
    else {
      # Make the frame for this method
      if(!has_field(private.gui, method)) private.gui[method]:=[=];
      widgetset.tk_hold();
      private.gui[method].frame :=
	  widgetset.frame(private.commandframe);
      # Add labelling
      if(has_field(private.titles, method)&&
	 has_field(private.titles[method], 'title')) {
	labeltext := paste('Function:', method);
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
	labeltext := spaste('Arguments for ', method);
	private.gui[method].label := widgetset.label(private.gui[method].frame,
						     labeltext,
						     borderwidth=0,
						     justify='center');
      }
      private.gui[method].autoframe := widgetset.frame(private.gui[method].frame,
						       side='bottom',
						       expand='x');
      if(length(private.gui[method].parameters)) {
	include 'autogui.g';
	private.gui[method].autogui:=
	    autogui(params=private.gui[method].parameters,
		    toplevel=private.gui[method].autoframe,
		    relief='flat',
		    autoapply=T,
		    expand='x',
		    map=F);
	whenever private.gui[method].autogui->changenotice do {
	  self->changenotice($value);
	}

	widgetset.tk_release();
	if(is_fail(private.gui[method].autogui)) {
	  fail;
	}
      }
      else {
	private.gui[method].autogui:=
	    widgetset.label(private.gui[method].autoframe,
			    'No arguments for this function');
	widgetset.tk_release();
      }
      widgetset.tk_hold();

      # Finally set the method
      private.methodslist[private.lastgroup]->clear('0', 'end');
      for (i in 1:length(private.groupmethods[private.lastgroup])) {
	if(method==private.groupmethods[private.lastgroup][i]) {
	  private.methodslist[private.lastgroup]->select(as_string(i-1));
	  break;
	}
      }
      widgetset.tk_release();
    }
    return T;
  } # showgui
  
  #### Start of construction phase    
  
  # Find the titles for the autogui frames
  include 'types.g';
  types.includemeta();
  private.titles := types.meta(private.type, ctors=F,
			       globals=F,
			       addhelp=T);
  
  methods := field_names(private.titles);
  if(is_function(private.filter)) {
    newmethods := '';
    i := 0;
    for (method in methods) {
      if(private.filter(method)) {
	i+:=1;
	newmethods[i] := method;
      }
    }
    methods := newmethods;
  }
  allmethods := methods;
  
  # There might be no functions to show. 
  if(length(methods)==0) {
    fail 'There are no functions to show';
  }
  
  groups := array('basic', length(methods));
  private.lastmethod:=unset;
  ngroups := 0;
  private.groupmethods := [=];
  lengthgroupmethods := [=];
  uiparameters := F;
  for (method in methods) {
    ngroups +:= 1;
    if(has_field(private.titles[method], 'group')) {
      groups[ngroups] := as_string(private.titles[method].group);
    }
  }
  # Sort alphabetically on groups
  methods := sort_pair(groups, methods);
  groups  := sort(groups);
  # If only one group, then substitute all
  if(length(unique(groups))==1) groups := array('all', length(allmethods));
  # Now figure out assignments
  for (i in 1:len(methods)) {
    group := groups[i];
    method := methods[i];
    if(!has_field(private.groupmethods, group)) {
      private.groupmethods[group] := '';
      lengthgroupmethods[group] := 0;
    }
    lengthgroupmethods[group] +:= 1;
    private.groupmethods[group][lengthgroupmethods[group]] := method;
  }
  # Add an all grouping
  if(length(private.groupmethods)>1) private.groupmethods['all'] :=
      sort(allmethods);
  private.lastmethod := unset;
  for (m in methods) {
    uiparameters := private.tms.getuiparameters(private.type, m,
						private.mode);
    if(!is_fail(uiparameters)) {
      private.lastmethod := m;
      break;
    }
  }
  if(is_unset(private.lastmethod)) {
    return throw('No functions with defined interface');
  }
  
  widgetset.tk_hold();
  if(is_agent(parent)) {
    private.frame := widgetset.frame(parent, side='top',
				     relief='ridge', expand='x');
  }
  else {
    private.frame := widgetset.frame(side='top',
				     title=spaste(title, ' (AIPS++)'),
				     relief='ridge');
  }
  
  private.commandtopframe := widgetset.frame(private.frame,
						 side='right');
  private.commandframe := widgetset.frame(private.commandtopframe,
					  side='bottom', relief='ridge');
  
# If more than one method then we will make a listbox containing 
# the methods
  if(length(methods)>1) {
    private.methodsmenuframe := widgetset.frame(private.commandtopframe,
						side='top', expand='y',
						relief='ridge')
	private.methodslabel := [=];
    private.methodslist := [=];
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
				   nbreak=20,
				   casesensitive=T);
    }
    for (group in field_names(private.groupmethods)) {
      private.groupmethodstopframe[group] :=
	  widgetset.frame(private.methodsframe,
			  side='top');
      private.groupmethodstopframe[group]->unmap();
      private.methodslabel[group] :=
	  widgetset.label(private.groupmethodstopframe[group],
			  paste(group, 'functions'));
      private.methodslabel[group].shorthelp := 'Functions available';
      private.groupmethodsframe[group] :=
	  widgetset.frame(private.groupmethodstopframe[group], side='left');

#
# Add methods listing?
#
      private.methodslist[group] :=
	  widgetset.listbox(private.groupmethodsframe[group], 
			    height=min(20, length(private.groupmethods[group])),
			    background='lightgrey');
      for (i in 1:length(private.groupmethods[group])) {
	private.methodslist[group]->insert(private.groupmethods[group][i]);
      }
      private.methodslist[group]->clear('0', 'end');
      private.methodslist[group]->select('0');
      if(length(private.groupmethods[group])>20) {
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
  private.lastgroup := sort(groups)[1];;
  private.method := private.groupmethods[private.lastgroup][1];
  
  if(has_field(private, 'groupmethodstopframe')&&
     has_field(private.groupmethodstopframe, private.lastgroup)) {
    private.groupmethodstopframe[private.lastgroup]->map();
  }
  if(has_field(private, 'groupsswitch')) {
    whenever private.groupsswitch->select do {
      value := $value;
      if(!private.lock()) {
	if(is_record(value)&&has_field(value, 'item')) {
	  widgetset.tk_hold();
	  group := value.item;
	  name := private.groupmethods[group][1];
	  self.front(group, name);
	  widgetset.tk_release();
	}
	private.unlock();
      }
    }
  }
  
# If we have more than one method then we will need
# a whenever to select methods from the listbox
  if(length(methods)>1) { 
    for (group in field_names(private.groupmethods)) {
      whenever private.methodslist[group]->select do {
	if(!private.lock()) {
	  if(has_field(private.groupmethods, private.lastgroup)) {
	    widgetset.tk_hold();
	    name := private.groupmethods[private.lastgroup][$value + 1];
	    self.front(group, name)
	    widgetset.tk_release();
	  }
	  private.unlock();	
	}
      } private.pushwhenever();
    }
  }
  
  self.front := function(group=unset, method=unset, values=unset) {
    wider private;
    if(is_unset(group)) {
      group := as_string(private.titles[method].group);
    }
    if(group!=private.lastgroup) {
      if(has_field(private, 'groupmethodstopframe')&&
	 has_field(private.groupmethodstopframe, private.lastgroup)) {
	private.groupmethodstopframe[private.lastgroup]->unmap();
      }
      private.lastgroup := group;
      if(has_field(private, 'groupmethodstopframe')&&
	 has_field(private.groupmethodstopframe, private.lastgroup)) {
	private.groupmethodstopframe[private.lastgroup]->map();
      }
    }
    if(is_fail(private.showgui(method))) {
      throw ('Failed to start gui for method ', method);
    }
    if(!is_unset(values)) private.setvalues(values);
    private.lastmethod := method;
    return T;
  }

# Add the popup help
  result := widgetset.addpopuphelp(private, 5);

  private.lastgroup := sort(groups)[1];;

  widgetset.tk_release();
  
  name := private.groupmethods[private.lastgroup][1];
  self.front(private.lastgroup, name);
  
  self.map := function() {
    wider private;
    private.frame->map();
  }
  
  self.unmap := function() {
    wider private;
    private.frame->unmap();
  }

  self.get := function() {
    wider private;
    values := [=];
    private.getvalues(values);
    return values;
  }

  self.getmethod := function() {
    wider private;
    return private.lastmethod;
  }

  self.done := function() {
    wider private;
    if(!is_record(self)) return F;
    if(!is_record(private)) return F;
    if(has_field(private, 'whenevers')) {
      deactivate private.whenevers;
    }
    for (i in field_names(private)) {
      if(is_agent(private[i])) val private[i] := F;
    }
    val private := F;
  }
  
  result := self.front(private.lastgroup, private.lastmethod);

}

