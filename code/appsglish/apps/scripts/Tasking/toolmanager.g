# toolmanager.g: Maintain a list of AIPS++ tools
#
#   Copyright (C) 1998,1999,2000,2002
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
#   $Id: toolmanager.g,v 19.2 2004/08/25 02:06:08 cvsmgr Exp $
#

pragma include once;

# Verify that this is a tool: the only criterion is that it be 
# a record with a type function
const is_tool := function(tool) {
  if(!is_record(tool)) return F;
  if(!has_field(tool, 'type')) return F;
  if(!is_function(tool.type)) return F;
  if(!is_string(tool.type())) return F;
  return T;
}
  
toolmanager := subsequence() {
  
  include 'aipsrc.g';
  include 'note.g';
  include 'choice.g';
  include 'sh.g';
  include 'plugins.g';

  private := [=];

  self:: := [tools=[=], data=[=], command=[=]];
  
  private.tablemappings := [Image='image',
			    Measurement_Set='ms',
			    Component_List='componentlist',
			    Plot_file='pgplotter'];

  private.values := [=];
  
  private.toolguiserver := unset;
  private.toolcliserver := unset;

  private.prefergui := unset;
  private.logcommands := F;
  private.logevents := F;
  
  private.foundmeta := F;
  
  private.tools := [=];
  
  include 'asynceval.g';
  private.asynceval := asynceval();
  
  include 'toolmanagersupport.g';
  private.tms := toolmanagersupport;

  private.minimal := F;
  private.aipsrcprefergui := T;

  found := drc.findbool(desired, 'toolmanager.gui.auto');
  
  if (found) {
    if(desired) {
      private.aipsrcprefergui := T;
    }
    else {
      private.aipsrcprefergui := F;
    }
  }

  found := drc.find(desired, 'toolmanager.fullgui');
  
  if(found) {
    if(desired) {
      private.minimal := T;
    }
    else {
      private.minimal := F;
    }
  }
# 
# Ensure that the interfaces are initialized
#
  private.initui := function() {
    wider private, self;
    if(is_unset(private.toolguiserver)) {
      include 'toolguiserver.g';
      private.toolguiserver := toolguiserver();
      whenever private.toolguiserver->show_return,
	  private.toolguiserver->dismiss_return,
	  private.toolguiserver->go_return,
	  private.toolguiserver->done_return do {
	name := $name;
	value := $value;
	private.tms.logevent(name, value);
	self->[name](value);
      } private.whenevers['gui'] := last_whenever_executed;
    }
    if(is_unset(private.toolcliserver)) {
      include 'toolcliserver.g';
      private.toolcliserver := toolcliserver();
      whenever private.toolcliserver->show_return,
	  private.toolcliserver->dismiss_return,
	  private.toolcliserver->go_return,
	  private.toolcliserver->done_return do {
	name := $name;
	value := $value;
	private.tms.logevent(name, value);
	self->[name](value);
      } private.whenevers['cli'] := last_whenever_executed;
    }
    return T;
  }
  
#
# Can we and do we prefer to use a gui?
#
  private.usegui := function(prefergui=unset) {
    
    # First case: if we don't have it, don't use it!
    if(!have_gui()) return F;
    
    # Next, input overrides
    if(!is_unset(prefergui)) {
      # prefergui set, if it is true then we will use the gui
      # despite what the aipsrc file or the usegui says
      if(is_boolean(prefergui)) return prefergui;
    }
    else {
      # prefergui not set so we look at the aipsrc values
      #
      # Default is no gui
      #
      prefergui := private.aipsrcprefergui;
    }
    
    # Next case, the use may have said to use the gui using 
    # the setgui function
    if(is_boolean(private.prefergui)) return private.prefergui;
    
    return prefergui;
  }
  
  #
  # Scan global symbols looking for new tools, also removes currently listed
  # tools which no longer appear to be valid. We don't have to do this
  # too often since it takes some time (a few seconds or more).
  #
  const private.findtools := function() {
    wider self, private;
    
    # Find all candidates: records with a type function that returns a
    # string
    candidates := symbol_names(is_tool);
    
    if(length(candidates)==0) return T;
    
    # Get rid of tools with leading underscores
    candidates := candidates[ !(candidates ~ m/^_/) ] ;
    
    # Get rid of candidates with leading default (this is another
    # nasty kludge!)
    candidates := candidates[ !(candidates ~ m/^default/) ] ;
    
    # Now we need to go through the candidates and add any new ones
    for (candidate in candidates) {
      if(self.isregistered(candidate)) {
	continue;
      }
      else {
        self.registertool(candidate);
      }
    }       
    # Now the opposite, check that all of the tools in the registry
    # still exist
    for (tool in field_names(private.tools)) {
      if(!any(candidates==tool)) {
        self.unregistertool(tool);
      }
    }
    
    return T;
  }
  
################################
#
# Is this a valid tool name?
#
  const self.isvalidtoolname := function(name) {
    if(name~m/^[0-9]/) return F;
    if(name~m/[\*]/) return F;
    if(name~m/[\.]/) return F;
    if(name~m/[\-\/\!\@\#\%\^\&]/) return F;
    return T;
  }

################################
  const self.getnewtoolname := function(name) {
    wider private;
    # To make a template remove any trailing numbers
    name := name ~ s/[0-9]*$//g;
    if(!any(field_names(private.tools)==name)) return name;      
    for (i in 1:100) {
      test := spaste(name, i);
      if(!any(field_names(private.tools)==test)) return test;      
    }
    return throw('Cannot automatically generate tool name');
  }

################################
  const self.getnewitemname := function(name) {
    wider private;
    # To make a template remove any trailing numbers
    include 'itemcontainer.g';
    name := name ~ s/[0-9]*$//g;
    if(!is_defined(name)) return name;
    if(!is_itemcontainer(symbol_value(name))) return name;
    for (i in 1:10000) {
      test := spaste(name, i);
      if(!is_defined(test)) return test;
      if(!is_itemcontainer(symbol_value(test))) return test;
    }
    return throw('Cannot automatically generate item name');
  }

################################
# Verify that this is a tool: the only criterion is that it be the name
# of a record with a type function
  const self.istool := function(tool) {
    wider self, private;
    if(!is_string(tool)||(tool=='')) return F;
    return is_tool(symbol_value(tool));
  }
  
################################
# Return type by executing type() function
  const self.tooltype := function(tool) {
    wider self;
    if(!is_string(tool)) return throw('Argument tool must be a string');
    if(is_tool(symbol_value(tool))) {
      tmp := symbol_value(tool).type();
      if (is_fail(tmp)) {
	return throw('Error executing ', tool, '.type()');
      }
      if(is_string(tmp)) return tmp;
    }
    return throw('Cannot determine type: not a tool');
  }
  
#
# Is a tool type?
#
################################
  const self.istooltype := function(type) {
    if(private.minimal) return T;

    private.tms.findmeta();
    dotcount := length(split(type, '.'))-1;
    if(dotcount) return F;
    global types;
    return types.exists(type);
  }

################################
  const self.hasconstructors := function(type) {
    if(private.minimal) return T;

    private.tms.findmeta();
    dotcount := length(split(type, '.'))-1;
    if(dotcount) return F;
    global types;
    meta := types.meta(type, ctors=T);
    return as_boolean(len(meta)>0);
  }

################################
# For global functions, we need to search over all possible classes
  const self.isglobalfunction := function(fn) {
    wider private;
    if(private.minimal) return T;

    if(!is_string(fn)) return F;
    global types;
    private.tms.findmeta();
    for (type in types.classes()) {
      if(types.exists(type, spaste('global_', fn))) return T;
    }
    return F;
  }
  
################################
# ditto for constructors
  const self.isconstructor := function(fn) {
    wider private;
    if(private.minimal) return T;

    if(!is_string(fn)) return F;
    global types;
    private.tms.findmeta();
    for (type in types.classes()) {
      if(types.exists(type, spaste('ctor_', fn))) return T;
    }
    return F;
  }
  
################################
# For global functions, we need to search over all possible classes
  const self.findtype := function(fn) {
    global types;
    private.tms.findmeta();
    for (type in types.classes()) {
      if(types.exists(type, spaste('global_', fn))) return type;
    }
    return throw('Unknown global function ', fn);
  }
  
################################
# Register an existing tool by name
# e.g. tool='myimager, status='Idle'
  self.registertool := function (tool, status='-', description=unset) {
    wider private, self;
    
    if(private.minimal) return T;

    private.tms.findmeta();
    
    if(!self.istool(tool)) {
      return throw ('Cannot register ', tool, ' since it is not a tool');
    }
    
    if(any(field_names(private.tools)==tool)) {
      return T;
    }
    private.tools[tool] := [=];
    private.tools[tool].type := self.tooltype(tool);
    private.tools[tool].status := status;
    private.tools[tool].description := '';
    
    rec := [=];
    if(is_unset(description)||!is_string(description)) {
      rec := private.tms.where(private.tools[tool].type);
      if(is_record(rec)&&is_string(rec.description)) {
	private.tools[tool].description := rec.description;
      }
    }
    else {
      rec.description := description;
    }
    
    return T;
  }
  
################################
# Set a tool status
  const self.settoolstatus := function (tool, status='-') {
    wider private, self;
    if(private.minimal) return T;

    if(!self.istool(tool)) {
      return throw ('Cannot set tool status ', tool,
		    ' since it is not a tool');
    }
    private.tools[tool].status := status;
    return T;
  }
  
################################
# Unregister an existing tool by name. Don't check to see 
# if it is a tool since it may not be deleted or set to
# F by someone
  const self.unregistertool := function(tool) {
    wider private, self;
    if(private.minimal) return T;

    if(!any(field_names(private.tools)==tool)) {
      return throw ('Tool ', tool, ' is not registered');
    }
    # Don't know how to delete an element of a record.
    new := [=];
    for (obj in field_names(private.tools)) {
      if(obj!=tool) new[obj] := private.tools[obj];
    }
    private.tools := new;
    return T;
  }
################################
# Is this registered?
  const self.isregistered := function (tool) {
    wider private, self;
    if(private.minimal) return T;

    if(!self.istool(tool)) return F;
    return any(field_names(private.tools)==tool);
  }
  
################################
# Find by name and return the tool record containing the type etc
# of a registered tool
  const self.toolinfo := function (tool) {
    wider private, self;
    if(!self.istool(tool)) return throw(tool, ' is not a tool');
    if(!any(field_names(private.tools)==tool)) {
      return throw ('Tool ', tool, ' is not registered');
    }
    return private.tools[tool];
  }
  
################################
# Delete a tool. Any deleted tool is automatically unregistered.
  const self.deletetool := function (tool) {
    wider private, self;
    if(private.minimal) return T;
    
    if(!self.istool(tool)) {
      return throw(paste(as_string(tool), 'is not a tool'));
    }
    
    if(!self.unregistertool(tool)) note(paste('Failed to unregister', tool));
    
    # Ask for confirmation of the deletion of const tools
    ic := eval(spaste('is_const(', tool, ')'));
    if (ic) {
      tmp := choice(spaste(tool,
			   ' is read-only (\'const\'): removing it will probably cause AIPS++ to fail - are you ',
			   'sure you want to remove it?'), "no yes");
      if (tmp == 'no') return F;
    }
    
    # Try to be nice and use the done() function
    if(has_field(symbol_value(tool), 'done')) {
      if(!symbol_value(tool).done()) {
	note(paste('Tool', tool, 'did not exit as commanded.'),
	     priority='WARN', origin='toolmanager.deletetool')
      }
    }
    if(private.logcommands) {
      include 'scripter.g';
      ds.log(spaste(tool, '.done();'));
    }
    # Now just delete the tool name
    tmp := symbol_delete(tool);
    if (is_fail(tmp)) return throw('Trouble deleting tool name', tool, ':',
				   tmp);
    note(paste('Successfully deleted tool', tool));
    return T;
  }
  
################################
# Delete a tool. Any deleted tool is automatically unregistered.
  const self.killtool := function (tool) {
    wider private, self;
    if(private.minimal) return T;
    
    if(!self.isregistered(tool)) {
      return throw(paste(as_string(tool), 'is not a tool'));
    }

    
    type := private.tools[tool];

    toolrecord := symbol_value(tool);
    if(!is_record(toolrecord)||!has_field(toolrecord, 'id')) {
      return throw('Unable to find server for tool ', tool,
		   ' since it does not have an id() function');
    }
    id := toolrecord.id();

    if(!is_record(id)||!has_field(id, 'agentid')) {
      return throw('Unable to find server for tool ', tool);
    }
    agentid := id.agentid;

    atrisk := '';
    todie := [agentid];
    i := 0;
    for (t in field_names(private.tools)) {
      if(t!=tool) {
	pt := symbol_value(t);
	if(has_field(pt, 'id')) {
	  id := symbol_value(t).id();
	  if(is_record(id)&&has_field(id, 'agentid')) {
	    if(id.agentid==agentid) {
	      i+:=1;
	      atrisk[i] := t;
	      todie[i+1] := id.agentid;
	    }
	  }
	}
      }
    }
    
    # Ask for confirmation of the deletion of const tools
    if (is_const(symbol_value(tool))) {
      tmp := choice(spaste(tool,
			   ' is read-only (\'const\'): killing it will probably cause AIPS++ to fail\n- are you ',
			   'sure you want to kill it?'), "no yes");
      if (tmp == 'no') return F;
    }
    else {
      if(i>0) {
	tmp := choice(spaste('Killing the server for tool ', tool,
			     ' will kill the following tools ', atrisk, '\nthat are running in the same server: - are you sure?'), "no yes");
	if (tmp == 'no') return F;
      }
    }
    
    defaultservers.kill(agentid);

    # Now erase all the tools that were also killed
    for (t in [tool, atrisk]) {
      if(self.isregistered(tool)&&
	 !self.unregistertool(tool)) note(paste('Failed to unregister', t));
      # Now just delete the tool name
      tmp := symbol_delete(t);
      if (is_fail(tmp)) {
	throw('Trouble deleting tool name', t, ':', tmp);
      }
      else {
	note(paste('Successfully killed tool', t));
      }
    }
    return T;
  }
  
################################
# Delete the uis for non-existent tools
  const self.deleteui := function (tools='') {
    wider private, self;
    return T;
  }
  
################################
# Show a tool constructor e.g. 'imager'. If we can and prefer to use
# a gui then we will, otherwise or if the gui functions don't
# exist, we'll use the cli. If the cli functions don't exist,
# we're out of luck
  const self.showconstructor := function(type, prefergui=T) {
    wider self, private;
    if(private.minimal) return T;

    private.tms.findmeta();

    if(!self.isconstructor(type)) {
      return throw ('Cannot find constructor ', type);
    }

    private.initui();

    if(private.usegui(prefergui)) {
      return private.toolguiserver.constructor(type);
    }
    else {
      return private.toolcliserver.constructor(type);
    }
  }
  
################################
# Can we show a gui for a tool?
  const self.canshowtoolgui := function(tool) {
    wider self, private;
    
    if(private.minimal) return T;

    if(!self.istool(tool)) {
      return F;
    }
    if(private.usegui(T)) {
      # If the tool has a .gui() function that's all we need to know.
      command := spaste('has_field(', tool, ', ', '\'gui\')', 
			' && is_function(', tool, '.gui)');
      tmp := eval(command);
      if (is_boolean(tmp) && tmp) {
	return T;
      }
      # OK let's try for the autogui
      private.tms.findmeta();
      global types;
      result:=self.toolinfo(tool);
      if(!is_record(result)) return F;
      return types.exists(result.type);
    }
    return F;

  }

################################
# Show a tool e.g. 'myimager'. If we can and prefer to use
# a gui then we will, otherwise or if the gui functions don't
# exist, we'll use the cli. If the cli functions don't exist,
# we're out of luck
  const self.showtool := function(tool, prefergui=T, forceauto=F) {
    wider self, private;
    
    if(private.minimal) return T;

    private.tms.findmeta();
    
    if(!self.istool(tool)) {
      return throw ('Cannot find tool ', tool);
    }
    result:=self.toolinfo(tool);
    if(!is_record(result)) return result;
    
    type:=result.type;
    
    private.initui();

    if(private.usegui(prefergui)) {
      # If the tool has a .gui() function that's all we need to know.
      command := spaste('has_field(', tool, ', ', '\'gui\')', 
			' && is_function(', tool, '.gui)');
      tmp := eval(command);
      if (!forceauto && is_boolean(tmp) && tmp) {
        # Run asynchronously
	private.asynceval->run(spaste(tool, '.gui()'));
	return T;
      }
      else {
	# Try the auto GUI. If that doesn't work, we'll try the CLI.
	return private.toolguiserver.tool(tool, type);
      }
    }
    
    # Now we fall through to the CLI section
    # If the tool has a .cli() function that's all we need to know.
    command := spaste('has_field(', tool, ', ', '\'cli\')', 
		      ' && is_function(', tool, '.cli)');
    tmp := eval(command);
    if (!forceauto && is_boolean(tmp) && tmp) {
      # Run asynchronously
      private.asynceval->run(spaste(tool, '.cli()'));
      return T;
    }
    else {
      return private.toolcliserver.tool(tool, type);
    }
    # Nothing worked: fail!
    return throw('No UI defined for tool ', tool);
  }
  
################################
# 
  const self.addtablemapping := function(type, cons) {
    wider self, private;
    if(!is_string(type)) return throw('Table type must be a string');
    if(!is_string(cons)) return throw('Table constructor name must be a string');
    type ~:= s/ /_/g;
    private.tablemappings[type]:=cons;
    return T;
  }

################################
#
  const self.tablemappings := function() {
    wider private;
    return private.tablemappings;
  }

################################
# Create a tool from a table using internal default
# mappings and return name of tool (as string!)
# This is synchronous only
  const self.toolfromtable := function(tab) {
    wider self, private;
    
    if(private.minimal) return T;

    private.tms.findmeta();
    
    if(!tableexists(tab)) {
      return throw ('Cannot find table ', tab);
    }

    include 'catalog.g';
    what := dc.whatis(tab);
    if(!what.istable) {
      return throw ('File ', tab, ' is not a table');
    }

    # table is the default
    what.type ~:= s/ /_/g
    if(any(what.type==field_names(private.tablemappings))) {
      type := private.tablemappings[what.type];
    }
    else {
      type := 'table';
    }
    name := self.getnewtoolname(spaste('my', type));
    global types;
    inc := types.getincludefile(type);
    if(which_include(inc)!='') include inc;
    command := spaste(name, ':=', type , '(\'', tab, '\')');
    note('Constructing ', name, ' using command ', command);
    ok := eval(command);
    if(self.registertool(name)&&self.showtool(name)) {
      return name;
    }
    return throw('Cannot create tool for table ', tab);
  }
  
################################
# Create a tool from a table using internal default
# mappings and return name of tool (as string!)
  const self.showtoolfromtable := function(tab) {
    wider private, self;
    return self.showtool(self.toolfromtable(tab));
  }
################################
# Show a global function e.g. 'imagertest'
  const self.showglobalfunction := function(fn, prefergui=T, forceauto=F) {
    wider self, private;

    if(private.minimal) return T;

    private.initui();

    private.tms.findmeta();
    private.findtools();
    if(!self.isglobalfunction(fn))
	return throw(fn, ' is not a global function');
    
    if(private.usegui(prefergui)) {
      if(!forceauto && self.isglobalfunction(spaste(fn, 'gui'))) {
        # Run asynchronously
	private.asynceval->run(spaste(fn, 'gui()'));
	return T;
      }
      else {
	return private.toolguiserver.globalfunction(method=fn);
      }
    }
    else {
      if(!forceauto && self.isglobalfunction(spaste(fn, 'cli'))) {
        # Run asynchronously
	private.asynceval->run(spaste(fn, 'cli()'));
	return T;
      }
      else {
	return private.toolcliserver.globalfunction(method=fn);
      }
    }
    fail "No global function UI available";
  }
  
################################
# Show an itemmanager e.g. 'dmm'. If we can and prefer to use
# a gui then we will, otherwise or if the gui functions don't
# exist, we'll use the cli. If the cli functions don't exist,
# we're out of luck
  const self.showitemmanager := function(itemmanager, title=unset,
                                           prefergui=T, forceauto=F) {
    wider self, private;
    
    if(private.minimal) return T;

    private.initui();

    private.tms.findmeta();

    if(!self.istool(itemmanager)) {
      return throw ('Cannot find itemmanager ', itemmanager);
    }
    result:=self.toolinfo(itemmanager);
    if(!is_record(result)) return result;
    type:=result.type;
    
    if(private.usegui(prefergui)) {

      # If the itemmanager has a .gui() function that's all we need to know.
      command := spaste('has_field(', itemmanager, ', ', '\'gui\')', 
			' && is_function(', itemmanager, '.gui)');
      tmp := eval(command);
      if (!forceauto && is_boolean(tmp) && tmp) {
        # Run asynchronously
	private.asynceval->run(spaste(itemmanager, '.gui()'));
	return T;
      }
      else {
	# Try the auto GUI. If that doesn't work, we'll try the CLI.
	return private.toolguiserver.itemmanager(itemmanager, type,
						 title=title);
      }
    }
    
    # Now we fall through to the CLI section
    # If the itemmanager has a .cli() function that's all we need to know.
    command := spaste('has_field(', itemmanager, ', ', '\'cli\')', 
		      ' && is_function(', itemmanager, '.cli)');
    tmp := eval(command);
    if (!forceauto && is_boolean(tmp) && tmp) {
      # Run asynchronously
      private.asynceval->run(spaste(itemmanager, '.cli()'));
      return T;
    }
    else {
      return private.toolcliserver.itemmanager(itemmanager, type);
    }
    # Nothing worked: fail!
    return throw('No UI defined for itemmanager ', itemmanager);
  }

################################
  const self.showmanager := function(prefergui=unset) {
    wider private;
    private.minimal := F;
    private.initui();
    private.findtools();
    private.tms.findmeta();
    if(private.usegui(prefergui)) {
      return private.toolguiserver.showmanager();
    }
    else {
      return private.toolcliserver.showmanager();
    }
  }
  
################################
  const self.gui := function() {
    wider private;
    private.minimal := F;
    private.initui();
    private.findtools();
    private.tms.findmeta();
    return private.toolguiserver.showmanager();
  }
  
################################
  const self.cli := function() {
    wider private;
    private.minimal := F;
    private.initui();
    private.findtools();
    private.tms.findmeta();
    return private.toolcliserver.showmanager();
  }

##########################################################################
#
# Now the functions for the toolmanager itself
#
# General purpose show function
  const self.show := function(what=unset, prefergui=unset,
				forceauto=T) {
    
    wider self, private;
    
    if(private.minimal) return T;

    private.findtools();
    
    private.tms.findmeta();
    
    if(is_unset(what)) {
      # Tool manager
      return self.showmanager(prefergui);
    }
    else if(self.istool(what)) {
      # Tool
      return self.showtool(what, prefergui, forceauto);
    }
    else if(self.isglobalfunction(what)) {
      # Tool function
      return self.showglobalfunction(fn=what, prefergui=prefergui,
				       forceauto=forceauto);
    }
    else if(self.isconstructor(what)) {
      # Tool constructor
      return self.showconstructor(what, prefergui);
    }
    else if(tableexists(what)) {
      # From table
      return self.showtoolfromtable(what)&&self.showmanager();
    }
    return throw('Type of ', what, ' is unknown: cannot show');
  }
  
################################
# The tool manager is done: need more here
  const self.done := function() {
    wider private, self;
    private := F;
    self := F;
    return T;
  }
################################
  # Tool manager is a type, of course
  const self.type := function() {
    return 'toolmanager';
  }
################################
  # Log commands?
  const self.logcommands := function(log=T) {
    wider private;
    private.logcommands := log;
    private.tms.logcommands(log);
    return T;
  }
################################
  # Log events?
  const self.logevents := function(log=T) {
    wider private;
    private.logcommands := log;
    private.tms.logevents(log);
    return T;
  }
  
################################
# Use the gui iso a cli
  const self.usegui := function(usegui=T) {
    wider private;
    private.minimal := F;
    private.prefergui := usegui;
    return T;
  }
  
################################
# Use the cli iso a gui
  const self.usecli := function(usecli=T) {
    wider private;
    private.minimal := F;
    private.prefergui := !usecli;
    return T;
  }
  
################################
# Return list of tools
  const self.tools := function()
  {
    wider self;
    private.findtools();
    return ref private.tools;
  }
  
  const self.initialize := function() {
    wider private, self;
    # If using a gui then show the tools now
    if(!private.minimal&&private.usegui()) return self.show();
    return T;
  }

  whenever self->show, self->go, self->dismiss, self->done do {
    rec := $value;
    event := $name
    wider self, private;
    if(!private.minimal){
      private.tms.findmeta();
      private.initui();

      prefergui := T;
      if(has_field(rec, 'prefergui')) {
	prefergui := rec.prefergui;
      }
      if(private.usegui(prefergui)) {
	private.toolguiserver->[event](rec);
      }
      else {
	private.toolcliserver->[event](rec);
      }
    }
  }
  
}

# Make a singleton
const tm := toolmanager(); 

# Now initialize
tm.initialize();

toolmanagertest := function() {
  include 'image.g';
  global im, tm;
  im := imagemaketestimage();
  tm.show('im');
  tm.show('is_image');
  include 'modelmanager.g';
  tm.show('dmm');
}

