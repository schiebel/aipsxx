# toolgui.g: 
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
#   $Id: toolgui.g,v 19.2 2004/08/25 02:05:53 cvsmgr Exp $

pragma include once;

include 'widgetserver.g';
#
toolgui:=subsequence(tool, functions='', sequential=T,
		     rules=[=], parent=F, widgetset=dws) {

  if(!is_record(tool)&&!has_field(tool, 'type')) {
    return throw('toolgui needs a tool as the first argument',
		 origin='toolgui');
  }
#
# Stuff we will need
#
  include 'unset.g';
  include 'types.g';
  include 'inputsmanager.g';
  include 'toolmanagersupport.g';
  include 'autogui.g';
  include 'tabdialog.g';
#
# Private holder
#  
  private := [=];
#
# Find the tool type and make a handle for it
#
  private.tooltype := tool.type();
  private.toolname := spaste(private.tooltype, random());
  symbol_set(private.toolname, tool);
#
  private.tms := toolmanagersupport;

  private.tms.findmeta();

  private.inputs := [=];
  private.gui := [=];
  private.frames := [=];

  private.commandinfo := types.meta(private.tooltype,
				    addhelp=T);
  private.functions := field_names(private.commandinfo);
  if(functions != '') {
    private.functions := functions;
  }

  note('Making tool GUI with functions ', private.functions);

###
#
# Enforce rules on the enabling of each function
#
  private.rules := rules;
  private.disablefunction := function(called) {
    wider self, private;
    if(!has_field(private.rules, called)) private.rules[called] := [=];
    private.rules[called].isactive:=F;
  }
  private.enablefunction := function(called) {
    wider self, private;
    if(!has_field(private.rules, called)) private.rules[called] := [=];
    private.rules[called].isactive:=T;
  }
  private.isactivefunction := function(called) {
    wider self, private;
    if(has_field(private.rules, called)&&
       has_field(private.rules[called], 'isactive')) {
      return private.rules[called].isactive;
    }
    return T;
  }
#
# An example of a set of rules would be:
#
# rules := [setimage=[runonce=T], setdata=[runonce=T], clean=[requires="setimage setdata"]];
#
  private.enforcerules := function(called='') {
    wider self, private;

    if(called!='') {
      if(!has_field(private.rules, called)) {
	private.rules[called] := [=];
      }
      private.rules[called].hasbeencalled := T;
#
# Switch this off if it is only allowed to be run once
#
      if(has_field(private.rules[called], 'runonce')) {
	if(private.isactivefunction(called)) {
	  note('Disabling function ', called, ' since it can only be run once');
	  private.disablefunction(called);
	}
      }
    }
#
# Now check to see that all prerequisites have been met
#
    for (rule in field_names(private.rules)) {
      if(has_field(private.rules[rule], 'requires')) {
	for (require in private.rules[rule].requires) {
	  if(!(has_field(private.rules, require)&&
	       has_field(private.rules[require], 'hasbeencalled')&&
	       private.rules[require].hasbeencalled)) {
	    private.disablefunction(rule);
	    note('Disabling function ', rule, ' because function ',
		 require, ' has not been run');
	    break;
	  }
	  if(!private.isactivefunction(rule)) {
	    note('Enabling function ', rule,
		 ' now that prerequisite functions have been run');;
	  }
	  private.enablefunction(rule);
	}
      }
    }
#
# Now set the GUI for the next active function, only going forwards
#
    private.nextgui := '';
    index := 0;
    for (rule in private.functions) {
      index+:=1;
      if(rule==called) {
	break;
      }
    }
    if(index==length(private.functions)) {
      private.nextgui==called;
    }
    else {
      for (i in (index+1):length(private.functions)) {
	rule := private.functions[i];
	if(private.isactivefunction(rule)) {
	  private.nextgui := rule;
	  if(rule==called) note('Showing GUI for next function ', rule);
	  break;
	}
      }
    }
    if(private.nextgui=='') private.nextgui := called;

    return T;
  }
###
#
# Add information on using this function
#
  private.addinfo := function(fn) {
    wider private;
    hlp:='';
    if(has_field(private.commandinfo[fn], 'title')) {
      hlp:=private.commandinfo[fn].title;
    }
    private.info[fn]->append(paste(fn, ': ', hlp, '\n'), 'title');
    private.info[fn]->config('title', foreground='blue');
    if(has_field(private.rules, fn)&&has_field(private.rules[fn], 'runonce')) {
      private.info[fn]->append('- Can be run only once\n', 'runonce');
      private.info[fn]->config('runonce', foreground='blue');
    }
    if(has_field(private.rules, fn)&&has_field(private.rules[fn], 'requires')) {
      private.info[fn]->append(paste('- Requires functions',
				     private.rules[fn].requires,
				     'to be run first\n'), 'requires');
      private.info[fn]->config('requires', foreground='blue');
    }
    prereq := '';
    for (rule in field_names(private.rules)) {
      if(has_field(private.rules[rule], 'requires')) {
	if(any(private.rules[rule].requires==fn)) {
	  prereq := spaste(prereq, rule);
	}
      }
    }
    if(prereq!='') {
      private.info[fn]->append(paste('- Must be run before functions', 
				     prereq, '\n'), 'isrequired');
      private.info[fn]->config('isrequired', foreground='blue');
    }
    private.info[fn]->see('start');
    private.info[fn]->disable();
  }
###
#
# Make the autogui that holds the parameters
#
  private.makegui := function(fn) {
    wider private;
    if(fn!=''&&!has_field(private.gui, fn)) {
      private.infoframe[fn] := widgetset.frame(private.frames[fn], side='top',
					       relief='sunken');
      private.info[fn] := widgetset.text(private.infoframe[fn], height=4);
      private.addinfo(fn);
      private.guiframe[fn] := widgetset.frame(private.frames[fn], side='top',
					      relief='ridge');
      uiparams := private.tms.getuiparameters(private.tooltype, fn, 'tool');
      private.inputs[fn] := uiparams.args;
      values := inputs.getvalues(private.tooltype, fn);
      for (arg in field_names(values)) {
	if(has_field(private.inputs[fn], arg)) {
	  private.inputs[fn][arg].value := values[arg];
	}
      }
      private.gui[fn]:=autogui(params=private.inputs[fn],
			       toplevel=private.guiframe[fn],
			       relief='flat',
			       autoapply=F,
			       expand='x',
			       map=F);
    }
    return T;
  }
###
#
# Show help for this function in the browser
#
  private.showhelp := function(fn) {
    wider private;
    include 'aips2help.g';
    rec:=private.tms.where(private.tooltype);
    if(is_record(rec)&&has_field(rec, 'package')&&has_field(rec, 'module')){
      if(rec.package!=''&&rec.module!='') {
	what := spaste(rec.package, '.', rec.module, '.', private.tooltype);
	what := spaste(what, '.', fn, '.function');
	note(spaste('Driving browser to help on ', what));
	help(spaste('Refman:', what));
	return T;
      }
    }
    note(spaste('No help available on ', private.tooltype, '.', fn));
    return F;
  }
###
#
# A function to run other functions
#
  private.runfunction := function(fn) {
    wider private;
    rec := [=];
    rec.tool := private.toolname;
    rec.newtool := unset;
    rec.type := private.tooltype;
    rec.method := fn;
    rec.mode := 'tool';
    rec.data := private.gui[fn].get();

    inputs.savevalues(private.tooltype, fn, rec.data, dosave=F);

    rec.isliteral := [=];
    for (arg in field_names(rec.data)) {
      rec.isliteral[arg] := private.inputs[fn][arg].isliteral;
    }
    rec.inc := types.getincludefile(rec.type);
    command := private.tms.getcommand(rec, F);
    eval(private.tms.getcommand(rec, F));
    global ok;
    self->run([function=fn, data=rec.data, command=command, return=ok]);
    return T;
  }
############################################################################
#
# Now actually construct the GUI and whenevers
#

  widgetset.tk_hold();
  if(is_agent(parent)) {
    private.frames.top := widgetset.frame(parent, side='top');
  }
  else {
    private.frames.top := widgetset.frame(title=paste(private.tooltype,
						      'GUI (AIPS++)'),
					  side='top');
  }
  if(!is_agent(private.frames.top)) return throw('Unable to create top frame',
						 origin='toolgui');
#
# Make a tab dialog for the menu
#
  private.frames.menu := widgetset.frame(private.frames.top, side='left',
					 relief='flat');
  private.tabdialog := widgetset.tabdialog(private.frames.menu, colmax=6,
					   title=paste(private.tooltype,
						       'functions'));
  if(is_fail(private.tabdialog)) fail;
  private.frames.dialog := private.tabdialog.dialogframe();
  if(is_fail(private.tabdialog)) fail;
#
# Now add each method in turn
#
  for (fn in private.functions) {
    private.frames[fn] := widgetset.frame(private.frames.dialog);
    hlp:='';
    if(has_field(private.commandinfo[fn], 'title')) {
      hlp:=private.commandinfo[fn].title;
    }
    private.tabdialog.add(private.frames[fn], fn, hlp=hlp);
  }

#
# Load autogui for each method arguments only when needed
#
  whenever private.tabdialog->front do {
    fn := $value;
    if(!private.busy) {
      private.busy := T;
      widgetset.tk_hold();
      private.makegui(fn);
      private.tabdialog.front(fn);
      if(has_field(private.rules, fn)&&has_field(private.rules[fn], 'isactive')) {
	private.buttons.go->disabled(!private.rules[fn].isactive);
      }
      else {
	private.buttons.go->disabled(F);
      }
      widgetset.tk_release();
      private.busy := F;
    }
  }


#
# Go and dismiss buttons
#
  private.frames.action := widgetset.frame(private.frames.top, side='right',
					   relief='flat');
  private.frames.actionright := widgetset.frame(private.frames.action, side='right',
					       relief='flat');
  private.frames.actionleft := widgetset.frame(private.frames.action, side='left',
					       relief='flat');
  private.buttons := [=];
  private.buttons.dismiss := widgetset.button(private.frames.actionright, 'Dismiss',
					 type='halt');
  private.buttons.dismiss.shorthelp := 'Dismiss this GUI (tool continues to run)';
  whenever private.buttons.dismiss->press do {
    if(!private.busy) self.done();
  }
  private.buttons.go := widgetset.button(private.frames.actionright, 'Go',
					 type='action');
  private.buttons.go.shorthelp := 'Run currently visible function';
  whenever private.buttons.go->press do {
    if(!private.busy) {
      private.busy := T;
      private.buttons.all->disabled(T);
      private.buttons.go->disabled(T);
      private.buttons.dismiss->disabled(T);
      fn := private.tabdialog.which().name;
      private.runfunction(fn);
      widgetset.tk_hold();
# Decide which GUI comes next and then make it
      private.enforcerules(fn);
      private.makegui(private.nextgui);
      private.tabdialog.front(private.nextgui);
      private.buttons.all->disabled(F);
      private.buttons.go->disabled(F);
      private.buttons.dismiss->disabled(F);
      widgetset.tk_release();
      private.busy := F;
    }
  }
  if(sequential) {
    private.buttons.all := widgetset.button(private.frames.actionright, 'All',
					    type='action');
    private.buttons.all.shorthelp := 'Run all functions in sequence (with current arguments)';
    whenever private.buttons.all->press do {
      if(!private.busy) {
	private.busy := T;
	private.buttons.all->disabled(T);
	private.buttons.go->disabled(T);
	private.buttons.dismiss->disabled(T);
	note('Running functions in sequence');
	for (fn in private.functions) {
	  note('Running function ', fn);
	  private.makegui(fn);
	  private.runfunction(fn);
	}
	private.buttons.all->disabled(F);
	private.buttons.go->disabled(F);
	private.buttons.dismiss->disabled(F);
	private.busy := F;
      }
    }
  }
  private.buttons.help := widgetset.button(private.frames.actionleft, 'Help');
  private.buttons.help.shorthelp := 'Drive browser to help on this tool';
  whenever private.buttons.help->press do {
    private.buttons.help->disabled(T);
    private.showhelp(private.tabdialog.which().name);
    private.buttons.help->disabled(F);
  }

  self.type := function() {return "toolgui";};

  self.done := function() {
    wider private;
    
    note('toolgui exiting', origin='toolgui');

    for (f in private.frames) {
      if(is_agent(f)) f->unmap();
    }
    for (f in private.frames) {
      f:=F;
    }

    symbol_delete(private.toolname);

    private := F;
    self->done();
    return T;
  }
#
# Now actually make the GUI
#
  private.makegui(private.functions[1]);
  if(length(private.rules)) {
    note('Imposing rules for functions ', field_names(rules));
    private.enforcerules();
  }
#
  result := widgetset.addpopuphelp(private, 5);
#
  widgetset.tk_release();

}
