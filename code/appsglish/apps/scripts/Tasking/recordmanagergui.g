#recordmanagergui: Gui for the recordmanager
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
#   $Id: recordmanagergui.g,v 19.2 2004/08/25 02:03:57 cvsmgr Exp $


pragma include once;

include 'widgetserver.g';
include 'recordmanager.g';

const recordmanagergui := subsequence(rcm=drcm, widgetset=dws) {
  
  private := [frames=[=], buttons=[=], whenevers=[=], listboxs=[=],
	      operations=[=]];
  
  private.guientry := widgetset.guientry();
  
  private.rcm := rcm;
  
  private.catalog := F;
  
  private.isbusy := F;
  
  private.callback := F;

  private.pushwhenever := function() {
    wider private;
    private.whenevers[len(private.whenevers) + 1] :=
	last_whenever_executed();
  }
  
  const private.lock := function() {
    wider private;
    if(!private.isbusy) {
      private.isbusy := T;
      return T;
    }
    else {
      return F;
    }
  }
  
  const private.unlock := function() {
    wider private;
    private.isbusy := F;
    return T;
  }
  
  const private.settitle := function() {
    wider private;
    name := private.rcm.name();
    title := 'recordmanager (AIPS++)';
    if(!is_unset(name)) {
      title := paste(title, name);
    }
    if(private.rcm.readonly()) {
      title := paste(title, '(Read only)');
    }
    private.frame['top']->title(title);
  }
  
  const private.list := function() {
    wider private;
    
    private.listboxs['list']->delete('start', 'end');
    
    if(is_unset(private.rcm.name())) return T;
    
    rec := private.rcm.list();
    if(is_fail(rec)) return throw('Error listing table', rec::message);
    
    if(len(rec)) {
      listtoinsert := array('', 3, length(rec));
      names := field_names(rec);
      j := 0;
      for (i in 1:length(rec)) {
	if(names[i]!='version') {
	  j +:= 1;
	  listtoinsert[1,j] := names[i];
	  if(is_record(rec[i])&&has_field(rec[i], 'time')) {
	    listtoinsert[2,j] := rec[i].time;
	  }
	  if(is_record(rec[i])&&has_field(rec[i], 'comments')) {
	    listtoinsert[3,j] := rec[i].comments;
	  }
	}
      }
      private.listboxs['list']->insert(listtoinsert);
    }

    private.buttons['Save']->disabled(private.rcm.readonly());
    private.buttons['Delete']->disabled(private.rcm.readonly());

    private.settitle();

    return T;
  }
  
  const private.restore := function() {
    wider private;
    selection := private.listboxs["list"]->selection();
    if(length(selection)) {
      name := private.listboxs["list"]->get(selection)[1];
      if (name=='') {
	return T; # No-op if no selection
      }
      private.buttons['Name'].insert(name);
      comments := '';
      symbol_set(name, private.rcm.getrecord(name, comments=comments));
      private.buttons['Record'].insert(name);
      private.buttons['Comments'].insert(comments);
    }
    
  }
  
  const private.save := function() {
    wider private;
    if(private.rcm.readonly()) {
      return throw('Cannot save to readonly file');
    }
    rec := private.buttons['Record'].get();
    rec := private.rcm.torecord(rec);
    if(!is_record(rec)) {
      return throw('The record must be set');
    }
    name := private.buttons['Name'].get();
    if(is_unset(name)||(is_string(name)&&name=='')) {
      return throw('Name must be set');
    }
    comments := private.buttons['Comments'].get();
    result:=private.rcm.saverecord(name, rec, comments, ack=T, dosave=T);
    if(is_fail(result)) {
      return throw('Error saving record ', result::message);
    }
    else {
      return T;
    }
  }
  
  const private.create := function() {
    wider private;
    name := private.buttons['Name'].get();
    if(is_unset(name)||(is_string(name)&&name=='')) {
      return throw('Name must be set');
    }
    if(is_defined(name)) {
      include 'choice.g';
      if(choice(spaste('The variable ', name,
		       ' already exists. Are you sure that you wish to overwrite it?'),
		['No', 'Yes'])=='No') {
	return F;
      }
    }
    symbol_set(name, private.rcm.getrecord(name, comments=comments));
    if(!is_defined(name)) {
      return throw('Failed to create new record',
		   origin='recordmanagergui.create');
    }
    return T;
  }
  
  const private.send := function() {
    wider private;
    rec := private.buttons['Record'].get();
    rec := private.rcm.torecord(rec);
    if(!is_record(rec)) {
      return throw('The record must be set');
    }
    if(is_function(private.callback)) {
      private.callback(rec);
      private.callback := F;
      private.frame['Send']->unmap();
    }
    self.unmap();
    return T;
  }
  
  const private.delete := function() {
    wider private;
    if(private.rcm.readonly()) {
      return throw('Cannot delete readonly file');
    }
    selection := private.listboxs["list"]->selection();
    if(length(selection)) {
      name := private.listboxs["list"]->get(selection)[1];
      if (name=='') {
	return T; # No-op if no selection
      }
      result:=private.rcm.delete(name);
      if(is_fail(result)) {
	return throw('Error deleting record ', result::message);
      }
      else {
	return T;
      }
    }
  }
  
#    
# The top frame
#
  widgetset.tk_hold();
  
  private.frame["top"] := widgetset.frame(title='recordmanager (AIPS++)',
					  side='top');
#
# A menu bar containing File, Special, Options, Help
#
  private.menubar := widgetset.frame(private.frame["top"],side='left',
				     relief='raised');
#
# File Menu 
#
  private.filebutton := widgetset.button(private.menubar, 'File',
					 relief='flat', type='menu');
  private.filebutton.shorthelp := 'Do various file operations such as opening and closing a record table';
  private.filemenu := [=];
  private.filemenu["open"] :=
      widgetset.button(private.filebutton, 'Open record table');
  private.filemenu["openreadonly"] :=
      widgetset.button(private.filebutton, 'Open record table read only');
  
  whenever private.filemenu["open"]->press do {
    include 'catalog.g';
    if(is_boolean(private.catalog)) {
      private.catalog := catalog();
    }
    msg := 'Starting filecatalog GUI. Select an entry';
    note (msg, priority='NORMAL', origin='recordmanagergui');
    private.catalog.gui(F);       # Don't refresh for speed
    private.catalog.show(show_types='Records');
    private.catalog.setselectcallback(private.rcm.open);
  }
  
  whenever private.filemenu["openreadonly"]->press do {
    include 'catalog.g';
    if(is_boolean(private.catalog)) {
      private.catalog := catalog();
    }
    msg := 'Starting filecatalog GUI. Select an entry';
    note (msg, priority='NORMAL', origin='recordmanagergui');
    private.catalog.gui(F);       # Don't refresh for speed
    private.catalog.show(show_types='Records');
    private.catalog.setselectcallback(private.rcm.openreadonly);
  }
  
  private.filemenu["close"] :=
      widgetset.button(private.filebutton, 'Close record table');
  whenever private.filemenu["close"]->press do {
    private.rcm.save();
    private.rcm.close();
    private.settitle();
    private.list();
  }
  private.filemenu["dismiss"] :=
      widgetset.button(private.filebutton, 'Dismiss', type='dismiss');
  private.filemenu["exit"] :=
      widgetset.button(private.filebutton, 'Done', type='halt');
  
# 
# Finally the Help menu
#
  private.rightmenubar := widgetset.frame(private.menubar,side='right');
  private.helpmenu := widgetset.helpmenu(private.rightmenubar,
					 menuitems=['recordmanager'],
					 refmanitems=['Refman:recordmanager']);
  
  private.frame['inputs'] := widgetset.frame(private.frame['top'], side='left');
  
  private.labels['Name'] := widgetset.label(private.frame['inputs'],
					    'Name of record');
  
  private.buttons['Name'] :=
      private.guientry.string(private.frame['inputs'],
			      unset, allowunset=T);
  private.buttons['Name'].setwidth(30);
  
  private.labels['Record'] := widgetset.label(private.frame['inputs'],
					      'Record');
  
  private.buttons['Record'] :=
      private.guientry.record(private.frame['inputs']);
  private.buttons['Record'].setwidth(40);
  
  private.frame['inputs2'] := widgetset.frame(private.frame['top'], side='left');

  private.labels['Comments'] := widgetset.label(private.frame['inputs2'],
						'Comments');
  
  private.buttons['Comments'] :=
      private.guientry.string(private.frame['inputs2'], onestring=F);
  private.buttons['Comments'].setwidth(90);
  
  private.frame['menu'] := widgetset.frame(private.frame['top'], side='left');
  
  private.buttons['Save'] := widgetset.button(private.frame['menu'],
					      'Save');
  
  private.buttons['Restore'] := widgetset.button(private.frame['menu'],
						 'Restore');
  
  private.buttons['Delete'] := widgetset.button(private.frame['menu'],
						'Delete');
  
  private.frame['menuright'] := widgetset.frame(private.frame['menu'],
						side='right');
  
  private.buttons['Create'] := widgetset.button(private.frame['menuright'],
						'Create', type='action');

  private.frame['Send'] := widgetset.frame(private.frame['menuright'],
					   side='right');
  
  private.buttons['Send'] := widgetset.button(private.frame['Send'],
					      'Send&Dismiss');
  private.frame['Send']->unmap();
  
  private.frame['list'] :=
      widgetset.frame(private.frame['top'], side='top');
  
  private.listboxs['list'] :=
      widgetset.synclistboxes(private.frame['list'], 3,
			      ['Name', 'Time', 'Comments'],
			      height=15, width=[20, 19, 60],
			      background='lightgrey',
			      foreground=['red', 'black', 'blue'],
			      fill='y');
  
  private.frame['bottom'] := widgetset.frame(private.frame['top'],
					     side='left');
  private.buttons['Refresh'] := widgetset.button(private.frame['bottom'],
						 'Refresh');
  
  private.frame['bottomright'] := widgetset.frame(private.frame['bottom'],
						  side='right');
  private.buttons['Dismiss'] := widgetset.button (private.frame['bottomright'],
						  'Dismiss',
						  type='dismiss');
  
  widgetset.tk_release();
  
  whenever private.buttons['Delete']->press do {
    if(private.lock()) {
      private.delete();
      private.list();
      private.unlock();
    }
  }
  
  whenever private.buttons['Save']->press do {
    if(private.lock()) {
      private.save();
      private.list();
      private.unlock();
    }
  }
  
  whenever private.buttons['Restore']->press do {
    if(private.lock()) {
      private.restore();
      private.unlock();
    }
  }
  
  whenever private.buttons['Create']->press do {
    if(private.lock()) {
      private.create();
      private.unlock();
    }
  }
  
  whenever private.buttons['Send']->press do {
    if(private.lock()) {
      private.send();
      private.unlock();
    }
  }
  
  whenever private.buttons['Refresh']->press do {
    if(private.lock()) {
      private.list();
      private.unlock();
    }
  }
  
  whenever private.buttons['Dismiss']->press,
      private.filemenu["dismiss"]->press do {
	if(private.lock()) {
	  self.unmap();
	  private.unlock();
	}
      }
  
  whenever private.filemenu['exit']->press do {
    if(private.lock()) {
      self.done();
      private.unlock();
    }
  }
  
  self.insert := function(name, rec, comments='') {
    wider private;
    if(is_record(rec)) {
      private.buttons['Name'].insert(name);
      private.buttons['Record'].insert(rec);
      private.buttons['Comments'].insert(comments);
    }
    return T;
  }
  
  self.get := function() {
    wider private;
    private.buttons['Record'].insert();
    return T;
  }
  
  self.setcallback := function(fn) {
    wider private;
    if(is_function(fn)) {
      private.frame['Send']->map();
      private.callback := fn;
    }
  }
  
  self.refresh := function() {
    wider private;
    private.list();
    private.settitle();
  }
  
  self.done := function() {
    wider private;
    private.frame['top']->unmap();
  }
  
  self.dismiss := function() {
    wider private;
    private.frame['top']->unmap();
  }
  
  self.map := function() {
    wider private;
    private.frame['top']->map();
  }
  
  self.unmap := function() {
    wider private;
    private.frame['top']->unmap();
  }
  
  ok := private.list();
  ok := private.settitle();
  
}

