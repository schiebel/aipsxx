# toolmanagerguiserver: Serves tool manager GUI
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
#   $Id: toolmanagerguiserver.g,v 19.2 2004/08/25 02:06:18 cvsmgr Exp $
#

include 'widgetserver.g';

pragma include once;

const toolmanagerguiserver := subsequence(widgetset=dws) {
  
  private := [frames=[packages=[=], modules=[=], functions=[=]],
	      labels=[packages=[=], modules=[=], functions=[=]],
	      listboxs=[packages=[=], modules=[=], functions=[=]],
	      whenevers=[packages=[=], modules=[=], functions=[=]],
	      buttons=[packages=[=], modules=[=], functions=[=]]];
  
  private.interval := 0;
  private.verbose  := F;
  private.toolmanager := F;;
  private.sort := 'name';
  private.filter := 'all';
  
  include 'toolmanagersupport.g';
  
  private.tms := toolmanagersupport;
  
  private.bg := widgetset.resources('frame').background;

  private.compound := F;
  
  private.whenevers := [=];
  private.pushwhenever := function() {
    wider private;
    private.whenevers[len(private.whenevers) + 1] :=
	last_whenever_executed();
  }
  
  # The following two functions are used to lock the entire subsequence
  # so that only one thing can be done at once
  private.isbusy := F;
  
  const private.lock := function() {
    wider private;
    if(!private.isbusy) {
      private.isbusy := T;
      for (i in "tools functions") {
	for (field in field_names(private.buttons[i])) {
	  private.buttons[i][field]->disabled(T);
	}
      }
      private.entry['search']->disabled(T);
      private.status->postnoforward('');
      if(0) private.frames['Manager']->cursor('watch');
      return T;
    }
    else {
      private.status->postnoforward('Busy!');
      return F;
    }
  }
  const private.unlock := function() {
    wider private;
    for (i in "tools functions") {
      for (field in field_names(private.buttons[i])) {
	private.buttons[i][field]->disabled(F);
      }
    }
    private.entry['search']->disabled(F);
    if(0) private.frames['Manager']->cursor('left_ptr');
    private.isbusy := F;
    return T;
  }
  
# An interval of <= 0 turns off scanning.
  private.findtoolsperiodically := function(interval=0, name='') {
    wider self, private;
    self.refresh();
    if(private.interval<=0) return T;
    if (has_field(private, 'scanid')) {
      timer.remove(private.scanid);
    }
    private.scanid := timer.execute(private.findtoolsperiodically,
				    private.interval,
				    oneshot=T);
    return T;
  }
  
  private.showtool := function() {
    wider private;
    selection := private.listboxs["inuse"]->selection();
    if(length(selection)) {
      name := private.listboxs["inuse"]->get(selection)[1];
      if (name=='') {
	private.status->postnoforward('Need to select something');
	return T; # No-op if no selection
      }
      include 'toolmanager.g';
      tm.showtool(name, prefergui=T);
    }
  }
  
  private.killtool := function() {
    wider private;
    selection := private.listboxs["inuse"]->selection();
    if(length(selection)) {
      name := private.listboxs["inuse"]->get(selection)[1];
      if (name=='') {
	private.status->postnoforward('Need to select something');
	return T; # No-op if no selection
      }
      include 'toolmanager.g';
      tm.killtool(name);
    }
  }
  
# Call 'done' on the selected tool if it has such a function, and then
# remove the symbol and update. Only do the update if actually necessary
  private.tooldone := function() {
    wider private;
    
    selection := private.listboxs["inuse"]->selection();
    if(length(selection)) {
      name := private.listboxs["inuse"]->get(selection)[1];
      if (name=='') {
	private.status->postnoforward('Need to select something');
      }
      else {
	private.status->postnoforward(paste('Deleting tool', name));
	include 'toolmanager.g';
	tm.deletetool(name);
      }
    }
    else {
      private.status->postnoforward('Need to select something');
    }
  }
  
  self.add := function(name, title, hlp) {
    wider private;
    private.frames[name] := widgetset.frame(private.tabdialogframe,
					    side='top', relief='ridge');
    private.tabdialog.add(private.frames[name], title, hlp);
    return ref private.frames[name];
  }
  
  self.delete := function(name) {
    wider private;
    return private.tabdialog.delete(name);
  }
  
  self.front := function(name) {
    wider private;
    return private.tabdialog.front(name);
  }
  
  self.available := function(name) {
    wider private;
    return private.tabdialog.available(name);
  }
  
  self.lead := function() {
    wider private;
    return private.frames['topframe'];
  }
  
  self.map := function() {
    wider private;
    private.frames["topframe"]->map();
  }
  
  self.unmap := function() {
    wider private;
    private.frames["topframe"]->unmap();
  }
  
  self.type := function() {
    return 'manager';
  }
  
# Refresh the display from the current list. Defunct tools are
# removed from the tabdialog
  self.refresh := function() {
    wider private;
    private.status->postnoforward('Refreshing list of tools');
    private.clear(private.listboxs["inuse"]);
    include 'toolmanager.g';
    tools := tm.tools();
    toolnames := sort(field_names(tools));
    j := 0;
    ftoolnames := '';
    ftypes := '';
    for (i in 1:length(toolnames)) {
      # Filter
      if(private.filter=='user') {
	if(eval(spaste('!is_const(',toolnames[i],')'))) {
	  j+:=1;
	  ftoolnames[j] := toolnames[i];
	  value := tm.tooltype(toolnames[i]);
	  if(is_string(value)) {
	    ftypes[j] := value;
	  }
	  else {
	    ftypes[j] := 'unknown';
	  }
	}
      }
      else {
	ftoolnames[i] := toolnames[i];
	value := tm.tooltype(toolnames[i]);
	if(is_string(value)) {
	  ftypes[i] := value;
	}
	else {
	  ftypes[i] := 'unknown';
	}
      }
    }
    listtoinsert := array('', 2, length(ftoolnames));
    listtoinsert[1,] := ftoolnames;
    listtoinsert[2,] := ftypes;
    # Sort
    if (private.sort=='type') {
      savelisttoinsert := listtoinsert;
      listtoinsert[1,] := sort_pair(savelisttoinsert[2,],
				    savelisttoinsert[1,]);
      listtoinsert[2,] := sort(savelisttoinsert[2,]);
    }
    private.listboxs['inuse']->delete('start', 'end');
    private.listboxs['inuse']->insert(listtoinsert);
    # Now check to see that defunct guis are removed
    for (name in private.tabdialog.list()) {
      if(name=='Manager') {
      }
      else if(name=='Tools in use') {
      }
      else if(name=='') {
      }
      else {
        if(name~m/:/) {
	  parts := split(name, ':');
          if(len(parts)==2&&!any(ftoolnames==parts[2])) {
	    note('Deleting GUI for defunct tool ', parts[2]);
	    private.tabdialog.delete(name);
	  }
	}
      }
    }
    private.status->postnoforward('');
  }
  
# Show the selected tool
  private.showctor := function() {
    wider private;
    selection := private.listboxs["tools"]->selection();
    if(length(selection)) {
      name := private.listboxs["tools"]->get(selection);
      if (name=='') {
	private.status->postnoforward('Need to select a tool');
	return;
      }
      include 'toolmanager.g';
      tm.showconstructor(name);
    }
    else {
      private.status->postnoforward('Need to select a tool');
      return F;
    }
  }
# Run the selected function
  private.runfunction := function() {
    wider private;
    selection := private.listboxs["functions"]->selection();
    if(length(selection)) {
      name := private.listboxs["functions"]->get(selection);
      if (name=='') {
	private.status->postnoforward('Need to select a function');
	return F;
      }
      include 'toolmanager.g';
      tm.showglobalfunction (name);
    }
    else {
      private.status->postnoforward('Need to select a function');
      return F;
    }
    return T;
  }
  
# The gui is done
  private.done := function() {
    wider private;
    if (has_field(private, 'scanid')) {
      timer.remove(private.scanid);
    }
  }
  
  widgetset.tk_hold();
  
  private.frames["topframe"] := widgetset.frame(title='Tool manager (AIPS++)',
						side='top');
  private.frames["topframe"]->bind('<Enter>', 'enter');
#
# A menu bar containing File, Special, Options, Help
#
  private.topmenubar := widgetset.frame(private.frames["topframe"],
					side='left',
					relief='raised', expand='x');
#
# File Menu 
#
  helptxt := ' - Dismiss the tool manager gui. Retrieve using tm.gui()';
  private.filebutton := widgetset.button(private.topmenubar, 'File',
					 type='menu');
  widgetset.popuphelp(private.filebutton, helptxt, 'Do various operations', combi=T);
  private.filemenu := [=];
  private.filemenu['dismiss'] := widgetset.button(private.filebutton, 'Dismiss toolmanager',
						  type='dismiss');
  private.filemenu['exit AIPS++'] := widgetset.button(private.filebutton, 'Exit AIPS++',
						      type='halt');
  private.optionsbutton := widgetset.button(private.topmenubar, 'Options',
					    type='menu');
  private.optionsbutton.shorthelp := 'Set up options for processing';
  private.optionsmenu := [=];
  
  private.optionsmenu['logcommands'] :=
      widgetset.button(private.optionsbutton, 'Copy commands to scripter',
		       type='radio');
  whenever private.optionsmenu['logcommands']->press do {
    if(private.lock()) {
      private.tms.logcommands(private.optionsmenu['logcommands']->state());
      private.unlock();
    }
  } private.pushwhenever();

#  private.optionsmenu['logevents'] :=
#      widgetset.button(private.optionsbutton, 'Copy GUI events to scripter',
#		       type='radio');
#  whenever private.optionsmenu['logevents']->press do {
#    if(private.lock()) {
#      private.tms.logevents(private.optionsmenu['logevents']->state());
#      private.unlock();
#    }
#  } private.pushwhenever();

  private.optionsmenu['showscripter'] := widgetset.button(private.optionsbutton, 'Show scripter');
  whenever private.optionsmenu['showscripter']->press do {
    if(private.lock()) {
      include 'scripter.g';
      ds.gui();
      private.unlock();
    }
  } private.pushwhenever();
# 
# Finally the Help menu
#
  private.rightmenubar := widgetset.frame(private.topmenubar,side='right');
  private.helpmenu := widgetset.helpmenu(private.rightmenubar);
#
# Now add the tabdialog
#
  private.tabdialog := widgetset.tabdialog(private.frames['topframe'], colmax=4,
					   hlthickness=2, title=unset);
  
  private.tabdialogframe := private.tabdialog.dialogframe();
  
  private.frames['manager'] := self.add('Manager', 'Manager',
					'Press to see Manager view');
  
  private.frames['search'] := widgetset.frame(private.frames['manager'],
					      title='Search',
					      side='top');
  
  private.frames['searchstring'] := widgetset.frame(private.frames['search'],
						    side='left');
  
  private.labels['searchstring'] :=
      widgetset.label(private.frames['searchstring'],
		      'Search string: ',
		      borderwidth=0);
  
  private.labels['searchstring'].shorthelp := 'Search for keywords. Enter as many as you like, separated by spaces. You can use regular expression syntax if necessary.';
  
  private.dge := widgetset.guientry(expand='x');
  private.entry['search'] := private.dge.string(private.frames['searchstring'], '',
						onestring=T);
  
  private.frames['subframe'] := widgetset.frame(private.frames['manager'],
						side='left');
  
  # Now make the frames for each column
  private.frames['packagesetc'] := widgetset.frame(private.frames['subframe'],
						   side='left');
  
  private.frames['packages'] := widgetset.frame(private.frames['packagesetc'],
						side='top', expand='y');
  
  private.labels['packages'] := widgetset.label(private.frames['packages'],
						'Packages',
						borderwidth=0);
  private.labels['packages'].shorthelp := 'A collection of related modules';

  private.listboxs['packages'] :=
      widgetset.scrolllistbox(private.frames['packages'], height=10,
			      width=15, fill='y', background=private.bg);
  
  private.frames['modulestoolsfunctions'] :=
      widgetset.frame(private.frames['packagesetc'],
		      side='top', relief='ridge');
  
  private.labels['modulestoolsfunctions'] :=
      widgetset.label(private.frames['modulestoolsfunctions'], '',
		      borderwidth=0);
  private.frames['modulesetc'] :=
      widgetset.frame(private.frames['modulestoolsfunctions'],
		      side='left');
  
  private.frames['modules'] := widgetset.frame(private.frames['modulesetc'],
					       side='top', relief='ridge');
  
  private.labels['modules'] := widgetset.label(private.frames['modules'],
					       'Modules',
					       borderwidth=0);
  
  private.labels['modules'].shorthelp := 'A collection of related tools and functions';

  private.listboxs['modules'] :=
      widgetset.scrolllistbox(private.frames['modules'], height=10,
			      width=15, fill='y', background=private.bg);
  
  private.frames['toolsfunctions'] := widgetset.frame(private.frames['modulesetc'],
						      side='top', relief='ridge');
  
  private.labels['toolsfunctions'] :=
      widgetset.label(private.frames['toolsfunctions'], '',
		      borderwidth=0);
  
  private.frames['toolsandfunctions'] := widgetset.frame(private.frames['toolsfunctions'],
							 side='left', relief='ridge');
  
  private.frames['tools'] := widgetset.frame(private.frames['toolsandfunctions'],
					     side='top', expand='y');
  
  private.labels['tools'] := widgetset.label(private.frames['tools'],
					     'Tools',
					     borderwidth=0);
  private.labels['tools'].shorthelp := 'A collection of related functions operating on some common data';
  
  private.listboxs['tools'] :=
      widgetset.scrolllistbox(private.frames['tools'], height=10, width=15,
			      fill='y', background=private.bg);
  
  private.frames['toolsbottom'] := widgetset.frame(private.frames['tools'],
						   side='left');
  private.buttons['tools']['create'] := widgetset.button(private.frames['toolsbottom'],
							 'Create',
							 type='action');
  private.buttons['tools']['create'].shorthelp :=
      'Create an instance of the selected tool type. If not highlighted then the tool can only be created from the command line.';
  
  private.frames['functions'] := widgetset.frame(private.frames['toolsandfunctions'],
						 side='top', expand='y');
  
  private.labels['functions'] := widgetset.label(private.frames['functions'],
						 'Global functions',
						 borderwidth=0);
  private.labels['functions'].shorthelp := 'Global functions';
  
  private.listboxs['functions'] :=
      widgetset.scrolllistbox(private.frames['functions'], height=10,
			      width=15, background=private.bg,
			      fill='y');
  
  private.frames['functionsbottom'] := widgetset.frame(private.frames['functions'],
						       side='left');
  private.buttons['functions']['run'] :=
      widgetset.button(private.frames['functionsbottom'], 'Run',
		       type='action');
  private.buttons['functions']['run'].shorthelp := 'Run the selected function. If not highlighted then this function can only be run from the command line.';
  
  private.frames['inuse'] := self.add('inuse', 'Tools in use',
				      'Press to see Tools In Use view');

  whenever private.tabdialog->front do {
    if($value=='Tools in use') {
      self.refresh();
    }
  } private.pushwhenever();
  
  private.frames['padinuse'] := widgetset.frame(private.frames['inuse'],
						side='left');
  private.frames['padleftinuse'] := widgetset.frame(private.frames['padinuse']);
  private.listboxs['inuse'] :=
      widgetset.synclistboxes(private.frames['padinuse'], 2,
			      ['Tool name', 'Tool type'],
			      height=15,
			      width=[20, 20],
			      background=private.bg,
			      foreground=['red', 'black'], fill='y');
  private.frames['padrightinuse'] := widgetset.frame(private.frames['padinuse']);
  
  private.frames['inusebottom'] := widgetset.frame(private.frames['inuse'],
						   side='left');
  private.frames['padleftinusebottom'] :=
      widgetset.frame(private.frames['inusebottom']);
  private.buttons['inuse']['show'] := widgetset.button(private.frames['inusebottom'], 'Show',
						       type='action');
  private.buttons['inuse']['show'].shorthelp := 'Show the GUI for the selected tool';
  private.buttons['inuse']['delete'] := widgetset.button(private.frames['inusebottom'],
							 'Delete');
  private.buttons['inuse']['delete'].shorthelp := 'Delete the selected tool (equivalent to using the Done button or .done() function)';
  private.buttons['inuse']['kill'] := widgetset.button(private.frames['inusebottom'],
							 'Kill',
						       type='halt');
  private.buttons['inuse']['kill'].shorthelp := 'Kill the selected tool by stopping the associated server. Use with care: this will kill other tools that are using the same server';
  private.frames['padrightinusebottom'] :=
      widgetset.frame(private.frames['inusebottom']);
  
  private.frames['inusebottombottom'] := widgetset.frame(private.frames['inuse'],
							 side='left');
  private.buttons['inuse']['refresh'] :=
      widgetset.optionmenu(private.frames['inusebottombottom'],
			   ['Refresh', 'Refresh 10s',
			    'Refresh 30s', 'Refresh 60s'],
			   ['Refresh now', 'Refresh every 10s',	
			    'Refresh every 30s', 'Refresh every 60s'],
			   [0, 10, 30, 60],
			   hlp='Refresh the list of tools');
  include 'aipsrc.g';
  found := drc.find(desired, 'manager.refresh', def='10');
  if(found&&is_numeric(as_integer(desired))) {
    private.buttons['inuse']['refresh'].selectvalue(as_integer(desired));
    val private.interval := as_integer(desired);
  }
  
  private.buttons['inuse']['sort'] :=
      widgetset.optionmenu(private.frames['inusebottombottom'],
			   ['Sort by name', 'Sort by type'],
			   ['Sort by name', 'Sort by type'],
			   ['name', 'type'],
			   hlp='Sort the list of tools');
  
  private.buttons['inuse']['sort'].selectvalue(private.sort);
  found := drc.find(desired, 'manager.sort', def='name');
  if(found&&any(desired=="name type")) {
    private.buttons['inuse']['sort'].selectvalue(as_string(desired));
    val private.sort := as_string(desired);
  }
  
  
  private.buttons['inuse']['filter'] :=
      widgetset.optionmenu(private.frames['inusebottombottom'],
			   ['Show all tools', 'Show user tools only'],
			   ['Show all tools', 'Show user tools only'],
			   ['all', 'user'],
			   hlp='Filter the list of tools');
  
  private.buttons['inuse']['filter'].selectvalue(private.filter);
  found := drc.find(desired, 'manager.filter', def='all');
  if(found&&any(desired=="all user")) {
    private.buttons['inuse']['filter'].selectvalue(as_string(desired));
    val private.filter := as_string(desired);
  }
  
# Set up status line
  private.status:=widgetset.messageline(private.frames["manager"]);
  
  private.frames['bottom'] := widgetset.frame(private.frames['manager'],
					      side='left', expand='x');
  
  private.buttons['web'] := widgetset.button(private.frames['bottom'], 'Help');
  private.buttons['web'].shorthelp := 'Drive browser to help on currently selected package, module, tool or function';
  
  whenever private.frames["topframe"]->enter do {
    
    whenever private.buttons['inuse']['refresh']->select do {
      if(private.lock()) {
	val private.interval := $value.value;
	private.findtoolsperiodically();
	private.unlock();
      }
    } private.pushwhenever();
    
    whenever private.buttons['inuse']['sort']->select do {
      if(private.lock()) {
	val private.sort := $value.value;
	self.refresh();
	private.unlock();
      }
    } private.pushwhenever();
    
    whenever private.buttons['inuse']['filter']->select do {
      if(private.lock()) {
	val private.filter := $value.value;
	self.refresh();
	private.unlock();
      }
    } private.pushwhenever();
    
    
    whenever private.buttons['web']->press do {
      if(private.lock()) {
	private.web();
	private.unlock();
      }
    } private.pushwhenever();
    
    whenever private.filemenu['dismiss']->press do
    {
      include 'choice.g';
      if(choice('Dismissing the Tool Manager is not usually a good idea. Are you sure?', ['No', 'Yes'])=='Yes') {
	private.frames['topframe']->unmap();
	note('Dismissing the tool manager. Re-show using tm.gui()', priority='WARN');
      }
    }
    
    whenever private.filemenu['exit AIPS++']->press do
    {
      include 'choice.g';
      if(choice('Exiting AIPS++. Are you sure?', ['No', 'Yes'])=='Yes') {
	exit;
	note('Exiting AIPS++');
      }
    }
    whenever private.entry['search']->value do {
      if(private.lock()) {
	if(has_field(private.whenevers, 'search')) {
	  deactivate private.whenevers['search'];
	}
	if(has_field(private.listboxs, 'search')&&
	   is_record(private.listboxs['search'])) {
	  private.listboxs['search'].done();
	  private.listboxs['search'] := F;
	}
	private.compound := F;
	private.status->postnoforward('');
	if(is_string($value)&&strlen($value)) {
	  string := $value;
	  hits := self.search(string);
	  if(length(hits)) {
	    private.listboxs['search'] :=
		widgetset.selectablelist(private.frames['searchstring'], 
					 private.frames['searchstring'],
					 label='Show search Results', list=hits,
					 relief='raised',
					 casesensitive=T);
	    whenever private.listboxs['search']->select do {
	      if(private.lock()) {
		private.status->postnoforward('');
		private.package := '';
		private.module := '';
		private.tool := '';
		private.function := '';
		private.constructor := '';
		if(is_record($value)&&has_field($value, 'item')) {
		  private.compound := $value.item;
		  private.showcompound();
		  private.view(private.listboxs['search'], private.compound);
		}
		private.listboxs['search'].done();
		private.listboxs['search'] := F;
		private.unlock();
	      }
	    }
	    private.whenevers['search'] := last_whenever_executed();
	  }
	}
	private.unlock();
      }
    } 
    
    whenever private.listboxs['tools']->select do {
      if(private.lock()) {
	private.compound := F;
	private.status->postnoforward('');
	private.tool := '';
	private.function := '';
	private.constructor := '';
	private.methods := '';
	private.arguments := '';
	if(is_numeric($value)&&length($value)==1) {
	  private.tool := $agent->get($value);
	  private.showtoolsandfunctions();
	  private.view(private.listboxs['tools'], private.tool);
	}
	private.unlock();
      }
    }
    
    # We cannot lock this since it would disable the double click
    whenever private.listboxs['inuse']->select do {
      private.compound := F;
      private.status->postnoforward('');
      private.reset();
      selection := $value;
      if(is_numeric(selection)&&length(selection)==1) {
	result := private.listboxs["inuse"]->get(selection);
	private.tool := result[1];
	type := result[2];
	include 'toolmanager.g';
	private.buttons['inuse']['show']->disabled(!tm.canshowtoolgui(result[1]));
	private.showallfortool(type);
	private.view(private.listboxs['inuse'], private.tool);
      }
    }
    
    whenever private.listboxs['functions']->select do {
      if(private.lock()) {
	private.compound := F;
	private.status->postnoforward('');
	private.function := '';
	private.tool := '';
	private.constructor := '';
	private.methods := '';
	private.arguments := '';
	if(is_numeric($value)&&length($value)==1) {
	  private.function := $agent->get($value);
	  private.showtoolorfunction();	
	  private.view(private.listboxs['functions'], private.function);
	}
	private.unlock();
      }
    }
    
    whenever private.listboxs['modules']->select do {
      if(private.lock()) {
	private.compound := F;
	private.status->postnoforward('');
	private.function := '';
	private.tool := '';
	private.constructor := '';
	private.methods := '';
	private.arguments := '';
	if(is_numeric($value)&&length($value)==1) {
	  private.module := $agent->get($value);
	  private.showtoolsandfunctions();	
	  private.view(private.listboxs['modules'], private.module);
	}
	private.unlock();
      }
    }
    
    whenever private.listboxs['packages']->select do {
      if(private.lock()) {
	private.compound := F;
	private.status->postnoforward('');
	private.reset();
	if(is_numeric($value)&&length($value)==1) {
	  private.package := $agent->get($value);
	  private.showmodules();		# Show modules
	  private.view(private.listboxs['packages'], private.package);
	}
	private.unlock();
      }
    }
    deactivate;
  }
  
  private.reset := function() {
    wider private;
    for (lb in "modules tools functions") {
      private.clear(private.listboxs[lb]);
    }
    for (lb in "toolsfunctions modules modulestoolsfunctions") {
      private.labels[lb]->text('');
    }
    private.package := '';
    private.module := '';
    private.tool := '';
    private.function := '';
    private.constructor := '';
    private.method := '';
    return T;
  }
  
  private.web := function() {
    wider private;
    
    command := 'Refman:';
    if(is_string(private.compound)) {
      command := spaste(command,private.compound);
      private.status->postnoforward('');
      private.status->postnoforward(paste('Driving web browser to', command));
    }
    else {
      private.compound := F;
      if(private.package!='') {
	command := spaste(command, private.package);
	if(private.module!='') {
	  command := spaste(command,'.',private.module);
	  if(private.tool!='') {
	    command := spaste(command,'.',private.tool);
	    if(private.method!='') {
	      command := spaste(command,'.',private.method);
	    }
	  }
	  else if(private.function!='') {
	    command := spaste(command,'.',private.function);
	  }
	}
	private.status->postnoforward('');
	private.status->postnoforward(paste('Driving web browser to', command));
      }
      else {
	private.status->postnoforward('');
	private.status->postnoforward('Nothing selected, driving web browser to Reference Manual');
      }
    }
    
    result := help(command);
    private.status->postnoforward('');
    return result;
  }
  
  private.showcurrent := function() {
    wider private;
    
    if(private.package!='') {
      name := private.package;
      if(private.module!='') {
	name := spaste(name,'.',private.module);
	if(private.tool!='') {
	  name := spaste(name,'.',private.tool);
	  if(private.method!='') {
	    name := spaste(name,'.',private.method);
	  }
	}
	else if(private.function!='') {
	  name := spaste(name,'.',private.function);
	}
      }
    }
    else {
      name := '';
    }
    return name;
  }
  
  private.view := function(ref lb, value='') {
    wider private;
    if(value=='') {
      lb->view('0');
    }
    else {
      index :=-1;
      if(has_field(lb, 'list')) {
	for (item in split(lb.list)) {
	  index +:= 1;
	  if(item==value) {
	    break;
	  }
	}
	if(index<0) return F;
	lb->see(as_string(index));
      }
    }
    return T;
  }
  
  private.clear := function(ref lb) {
    wider private;
    lb->delete('start', 'end');
    lb.list := '';
    return T;
  }
  
  private.noselect := function(ref lb) {
    wider private;
    lb->delete('start', 'end');
    lb->insert(lb.list);
    lb->view('0');
    return T;
  }
  
  private.insert := function(ref lb, list) {
    wider private;
    lb.list := list;
    lb->insert(list);
    return T;
  }
  
  private.select := function(lb, value) {
    wider private;
    lb->delete('start', 'end');
    lb->insert(lb.list);
    index :=-1;
    if(has_field(lb, 'list')) {
      for (item in split(lb.list)) {
	index +:= 1;
	if(item==value) {
	  break;
	}
      }
      if(index<0) return F;
      lb->select(as_string(index));
      lb->view(as_string(index));
    }
    return T;
  }
  
  private.showtoolorfunction := function() {
    wider private, private;
    
    # Now set the selection
    if(private.tool!='') {
      if(has_field(private.packmod, 'objs')&&
	 has_field(private.packmod.objs, private.tool)) {
	private.noselect(private.listboxs['functions']);
	private.select(private.listboxs['tools'], private.tool);
	return T;
      }
    } 
    else if(private.function!='') {
      if(has_field(private.packmod, 'funs')&&
	 has_field(private.packmod.funs, private.function)) {
	private.noselect(private.listboxs['tools']);
	private.select(private.listboxs['functions'], private.function);
	rec := private.packmod.funs[private.function];
	return T;
      }
    }
    return F;
  }
  
  # Show all (global) functions
  private.showtoolsandfunctions := function() {
    wider private;
    
    private.clear(private.listboxs['functions']);
    private.clear(private.listboxs['tools']);
    
    if(private.module=='') return F;
    
    if(has_field(help::pkg[private.package], private.module)) {
      private.select(private.listboxs['modules'], private.module);
    }
    else {
      return F;
    }
    
    if((private.package!='')&&(private.module!='')) {
      private.packmod := ref help::pkg[private.package][private.module];
    }
    else {
      private.packmod := [=];
    }
    
    private.labels['toolsfunctions']->text('');
    if(has_field(private.packmod, 'd')) {
      private.labels['toolsfunctions']->text(private.packmod.d);
    }
    
    include 'toolmanager.g';
    ntools :=0;
    if(has_field(private.packmod, 'objs')) {
      tools := field_names(private.packmod.objs);
      atools := '';
      for (tool in tools) {
	if(tm.istooltype(tool)&&tm.hasconstructors(tool)) {
	  ntools+:=1;
	  atools[ntools]:= tool;
	}
      }
      if(ntools>0) private.insert(private.listboxs['tools'], sort(atools));
    }
    
    nfuns := 0;
    if(has_field(private.packmod, 'funs')) {
      funs := field_names(private.packmod.funs);
      afuns := '';
      for (fun in funs) {
	if(tm.isglobalfunction(fun)) {
	  nfuns+:=1;
	  afuns[nfuns]:= fun;
	}
      }
      if(nfuns>0) private.insert(private.listboxs['functions'], sort(afuns));
    }
    
    # Do trivial selection
    if(ntools==1&&nfuns==0) {
      if(private.tool=='') private.tool := tools[1];
    }
    else if (ntools==0&&nfuns==1) {
      if(private.function=='') private.function := funs[1];
    }
    
    private.showtoolorfunction();
    
    return T;
    
  }
  
  # Show all modules
  private.showmodules := function() {
    wider private;
    
    private.clear(private.listboxs['functions']);
    private.clear(private.listboxs['tools']);
    private.clear(private.listboxs['modules']);
    
    if(private.package=='') {
      private.package := private.listboxs['packages']->get('0');
    }
    
    if(private.package=='') return F;
    
    if(has_field(help::pkg, private.package)) {
      private.select(private.listboxs['packages'], private.package);
    }
    else {
      return F;
    }
    
    if(has_field(help::pkg[private.package]::, 'd')) {
      private.labels['modulestoolsfunctions']->text(help::pkg[private.package]::['d']);
    }
    else {
      private.labels['modulestoolsfunctions']->text('');
    }
    
    # Remove aipsrcdata since it is misclassified
    filtered := split(paste(sort(field_names(help::pkg[private.package])~s/aipsrcdata//g)));
    private.insert(private.listboxs['modules'], filtered);
    
    return private.showtoolsandfunctions();
    
  }
  
  
  # Show all packages
  private.showpackages := function() {
    wider private;
    
    private.clear(private.listboxs['functions']);
    private.clear(private.listboxs['tools']);
    private.clear(private.listboxs['modules']);
    private.clear(private.listboxs['packages']);
    
    private.insert(private.listboxs['packages'], sort(field_names(help::pkg)));
    
    private.packmod := [=];
    
    private.showmodules();
    
    return T;
    
  }
  
  private.istool := function(candidate) {
    wider private;
    if(has_field(help::pkg[private.package][private.module], 'objs')&&
       has_field(help::pkg[private.package][private.module].objs, candidate)) {
      return T;
    }
    else {
      return F;
    }
  }
  
  private.istoolfunction := function(candidate) {
    wider private;
    parts := split(candidate, '.');
    if(length(parts)!=2) return F;
    if(private.istool(parts[1])) {
      if(has_field(help::pkg[private.package][private.module].objs[parts[1]], 'm')&&
	 has_field(help::pkg[private.package][private.module].objs[parts[1]].m, parts[2])) {
	return T;
      }
      else {
	return F;
      }
    }
    else {
      return F;
    }
  }
  
  private.istoolconstructor := function(candidate) {
    wider private;
    parts := split(candidate, '.');
    if(length(parts)!=2) return F;
    if(private.istool(parts[1])) {
      if(has_field(help::pkg[private.package][private.module].objs[parts[1]], 'c')&&
	 has_field(help::pkg[private.package][private.module].objs[parts[1]].c, parts[2])) {
	return T;
      }
      else {
	return F;
      }
    }
    else {
      return F;
    }
  }
  
  private.isfunction := function(candidate) {
    wider private;
    if(has_field(help::pkg[private.package][private.module], 'funs')&&
       has_field(help::pkg[private.package][private.module].funs, candidate)) {
      return T;
    }
    else {
      return F;
    }
  }
  
  # Search for string what. This has no memory of the previous 
  # search
  self.search := function(what){
    wider private;
    
    target := split(what);
    
    hits := '';
    for(i in 1:len(what)){
      hitFlags := help::atoms ~ eval(spaste('m/',what[i],'/'));
      if(sum(hitFlags)) {
	found := help::atoms[hitFlags];
	found ~:= s/.function$//g
	    found ~:= s/.constructor$//g
		if(length(found)&&is_string(found)) {
		  hits := paste(hits, found);
		}
      }
    }
    # Remove the aipsrcdata entries
    hitFlags := hits ~ m/aipsrcdata/;
    return split(hits[!hitFlags]);
  }
  
  self.show := function(package='', module='', tool='', method='') {
    wider private;
    private.reset();
    private.package:=package;
    private.module:=module;
    private.tool:=tool;
    private.package:=package;
    return private.showpackages();
  }
  
  private.showcompound := function() {
    wider private;
    private.reset();
    parts := split(private.compound, '.');
    # Find package: this is unambiguous
    if(length(parts)>0) {
      private.package:=parts[1];
    }
    else {
      private.package:='';
    }
    
    # Find module: again this is unambiguous
    if((length(parts)>1)) {
      private.module:=parts[2];
    }
    else {
      private.module:='';
    }
    
    # Next part is unambiguous: could be a tool or a function
    if(length(parts)>2) {
      candidate:=parts[3];
    }
    else {
      candidate:='';
    }
    # Try tool first
    if(private.istool(candidate)) {        
      private.tool:=candidate;
      if(length(parts)>3) {
	# Now it's ambiguous between method and constructor.
	candidate := parts[4];
	if(private.istoolfunction(spaste(private.tool, '.', candidate))) {
	  private.method := candidate;
	  private.constructor := '';
	}
	else if(private.istoolconstructor(spaste(private.tool, '.', candidate))) {
	  # Could be a constructor
	  private.constructor := candidate;
	  private.method := '';
	}
      }
    }
    else if (private.isfunction(candidate)) {
      # Could be a function
      private.function := candidate;
    }
    private.showpackages();
    return T;
  }
  
  private.showallfortool := function(type) {
    wider private, private;
    private.reset();
    # Look in help system first
    private.compound := F;
    where := private.tms.where(type);
    if(has_field(where, 'package')&&where.package!='') {
      private.package := where.package;
      private.module := where.module;
      private.tool := type;
      result:=self.show(private.package, private.module, private.tool);
      private.method := '';
      return result;
    }
    else {
      private.status->postnoforward('Cannot find related help information in meta information');
      # Look more widely
      hits := self.search(type);
      if(length(hits)) {
	private.listboxs['search']->insert(hits);
	top:=private.listboxs['search']->get(0);
	if(is_string(top)&&strlen(top)) {
	  private.compound := top;
	  private.showcompound();
	}
	return T;
      }
      else {
	private.status->postnoforward('Cannot find related help information in help files');
	return F;
      }
    }
  }
  
  whenever private.frames["manager"]->killed do {
    private.status->postnoforward('');
    deactivate private.whenevers;
    self.unmap();
  } private.pushwhenever();
  
  whenever private.frames["topframe"]->enter do {
    whenever private.buttons["tools"].create->press,
	private.listboxs["tools"]->doubleclick do {
	  private.status->postnoforward('');
	  if(private.lock()) {
	    private.showctor();
	    private.unlock();
	  }
	} private.pushwhenever();
    
    whenever private.buttons["functions"].run->press,
	private.listboxs["functions"]->doubleclick do {
	  private.status->postnoforward('');
	  if(private.lock()) {
	    private.runfunction();
	    private.unlock();
	  }
	} private.pushwhenever();
    
    whenever private.buttons["inuse"].delete->press do {
      private.status->postnoforward('');
      if(private.lock()) {
	private.tooldone();
	self.refresh();
	private.unlock();
      }
    } private.pushwhenever();
    
    whenever private.buttons["inuse"].kill->press do {
      private.status->postnoforward('');
      if(private.lock()) {
	private.killtool();
	self.refresh();
	private.unlock();
      }
    } private.pushwhenever();
    
    whenever private.buttons["inuse"].show->press,
	private.listboxs["inuse"]->doubleclick do {
	  private.status->postnoforward('');
	  if(private.lock()) {
	    private.showtool();
	    private.unlock();
	  }
	} private.pushwhenever();
    deactivate;
  }  
# Now fill the list
  private.findtoolsperiodically();
  self.refresh();
  widgetset.tk_release();
  
# Add the popup help
  result := widgetset.addpopuphelp(private, 5);
  
  self.gui := function() {
    wider private, private;
    
    # Ensure that the system is initialized. Then add any tools that are not
    # defined in actual help files.
    global help;
    if(length(help::pkg)==0) {
      hs:=showhelp();
    }
    if(!has_field(help::pkg, 'unclassified')) {
      help::pkg['unclassified'] := [=];
      help::pkg['unclassified']['unclassified'] := [=];
      help::pkg['unclassified']['unclassified'] := [=];
      help::pkg['unclassified']['unclassified']['objs'] := [=];
      help::pkg['unclassified']['unclassified']['funs'] := [=];
      metatools := types.classes();
      for (tool in metatools) {
	where := private.tms.where(tool);
	if(where.package=='') {
	  help::pkg['unclassified']['unclassified']['objs'][tool] := [=];
	}
      }
    }
    result := private.showpackages();
    result:=self.refresh();
    private.frames['topframe']->map();
    self.show('general');
    
    return T;
  }
  
  self.debug := function() {return ref private;};
  
  result := private.tabdialog.front('Manager');
  
  result := widgetset.addpopuphelp(private, 5);
  
  result := private.reset();
  
}

