#executivegui: Gui for the executive
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
#   $Id: executivegui.g,v 19.2 2004/08/25 02:08:21 cvsmgr Exp $


pragma include once;

include 'widgetserver.g';
include 'executive.g';

const executivegui := subsequence(ex=dex, widgetset=dws) {
  
  private := [frames=[=], buttons=[=], whenevers=[=], listboxs=[=],
	      operations=[=]];
  
  private.guientry := widgetset.guientry();
  
  private.ex := ex;
  
  private.catalog := F;
  
  private.isbusy := F;
  
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
    title := 'executive (AIPS++)';
    private.frame['top']->title(title);
  }
  
  const private.list := function() {
    wider private;
    
    rec := private.ex.list();
    if(is_fail(rec)) return throw('Error listing table', rec::message);
    
    if(len(rec)) {
      listtoinsert := array('', 6, length(rec));
      names := field_names(rec);
      j := 0;
      for (i in 1:length(rec)) {
	j +:= 1;
	if(is_record(rec[i])) {
	  listtoinsert[1,j] := as_string(j);
	  listtoinsert[2,j] := rec[i].script;
	  listtoinsert[3,j] := rec[i].host;
	  if(is_record(rec[i])&&has_field(rec[i], 'time')) {
	    include 'misc.g';
	    listtoinsert[4,j] := dms.timetostring(rec[i].time);
	  }
	  if(is_record(rec[i])&&has_field(rec[i], 'status')) {
	    listtoinsert[5,j] := rec[i].status;
	  }
	  if(is_record(rec[i])&&has_field(rec[i], 'comments')) {
	    listtoinsert[6,j] := rec[i].comments;
	  }
	}
      }
      private.listboxs['list']->delete('start', 'end');
      private.listboxs['list']->insert(listtoinsert);
    }

    private.settitle();

    return T;
  }
  
  const private.edit := function() {
    wider private;
    selection := private.listboxs["list"]->selection();
    if(len(selection)) {
      what := private.listboxs["list"]->get(selection);
      include 'os.g';
      name := what[2];
      result := dos.edit(name, async=F);
      host := what[3];
      return private.ex.runscript(name, host);
    }
    else {
      return T;
    }
  }
  
  const private.rerun := function() {
    wider private;
    selection := private.listboxs["list"]->selection();
    if(len(selection)) {
      what := private.listboxs["list"]->get(selection);
      name := what[2];
      host := what[3];
      return private.ex.runscript(name, host);
    }
    else {
      return T;
    }
  }
  
  const private.stop := function() {
    wider private;
    id := private.listboxs["list"]->selection() + 1;
    result:=private.ex.stop(id);
    if(is_fail(result)) {
      return throw('Error stopping job ', id, ':', result::message);
    }
    else {
      return T;
    }
  }
  
  const private.submit := function() {
    wider private;
    name := private.buttons['Name'].get();
    if(is_unset(name)||(is_string(name)&&name=='')) {
      return throw('Name must be set');
    }
    host := private.buttons['Host'].get();
    return private.ex.runscript(name, host);
  }
  
  const private.delete := function() {
    wider private;
    id := private.listboxs["list"]->selection() + 1;
    result:=private.ex.delete(id);
    if(is_fail(result)) {
      return throw('Error deleting job ', id, ':', result::message);
    }
    else {
      return T;
    }
  }
  
#    
# The top frame
#
  widgetset.tk_hold();
  
  private.frame["top"] := widgetset.frame(title='executive (AIPS++)',
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
  
  private.filemenu["dismiss"] :=
      widgetset.button(private.filebutton, 'Dismiss', type='dismiss');
  private.filemenu["exit"] :=
      widgetset.button(private.filebutton, 'Done', type='halt');
  
# 
# Finally the Help menu
#
  private.rightmenubar := widgetset.frame(private.menubar,side='right');
  private.helpmenu := widgetset.helpmenu(private.rightmenubar,
					 menuitems=['executive'],
					 refmanitems=['Refman:executive']);
  
  private.frame['inputs'] := widgetset.frame(private.frame['top'], side='left');
  
  private.labels['Name'] := widgetset.label(private.frame['inputs'],
					    'Name of script');
  private.labels['Name'].shorthelp := 'Name of script';
  
  private.buttons['Name'] :=
      private.guientry.file(private.frame['inputs'],
			      '', allowunset=F, types='Glish');
  private.buttons['Name'].setwidth(50);
  private.buttons['Name'].shorthelp := 'Name of script';
  
  private.labels['Host'] := widgetset.label(private.frame['inputs'],
					      'Host');
  private.labels['Host'].shorthelp := 'Host on which to run the script';
  
  private.buttons['Host'] :=
      private.guientry.string(private.frame['inputs']);
  private.buttons['Host'].setwidth(20);
  
  private.frame['inputs2'] := widgetset.frame(private.frame['top'], side='left');

  private.labels['Comments'] := widgetset.label(private.frame['inputs2'],
						'Comments');
  private.labels['Comments'].shorthelp := 'Comments on script';
  private.buttons['Comments'] :=
      private.guientry.string(private.frame['inputs2'], onestring=F);
  private.buttons['Comments'].setwidth(80);
  private.buttons['Comments'].shorthelp := 'Comments on script';
  
  private.buttons['Submit'] := widgetset.button(private.frame['inputs2'],
						'Submit', type='action');
  private.buttons['Submit'].shorthelp := 'Submit the script to run on the specified host';

  private.frame['menu'] := widgetset.frame(private.frame['top'], side='right');
  
  private.frame['list'] :=
      widgetset.frame(private.frame['top'], side='top');
  
  private.listboxs['list'] :=
      widgetset.synclistboxes(private.frame['list'], 6,
			      ['Job', 'Script', 'Host', 'Time', 'Status',
			       'Comments'],
			      height=15, width=[4, 30, 10, 19, 8, 40],
			      background='lightgrey',
			      foreground=['blue', 'red', 'black', 'black',
					  'black', 'green'],
			      fill='y');
  
  private.frame['bottom'] := widgetset.frame(private.frame['top'],
					     side='left');
  private.buttons['Refresh'] := widgetset.button(private.frame['bottom'],
						 'Refresh');
  private.buttons['Refresh'].shorthelp := 'Refresh the status listing';
  
  private.frame['bottomright'] := widgetset.frame(private.frame['bottom'],
						  side='right');
  private.buttons['Dismiss'] := widgetset.button (private.frame['bottomright'],
						  'Dismiss',
						  type='dismiss');
  private.buttons['Dismiss'].shorthelp := 'Dismiss this gui. Restore using gui() function';
  
  private.buttons['Stop'] := widgetset.button(private.frame['bottomright'],
					      'Stop', type='halt');
  private.buttons['Stop'].shorthelp := 'Stop the script';
  
  private.buttons['Delete'] := widgetset.button(private.frame['bottomright'],
						'Delete');
  private.buttons['Delete'].shorthelp := 'Delete the script from the queue';
  
  private.buttons['Rerun'] := widgetset.button(private.frame['bottomright'],
						 'Rerun');
  private.buttons['Rerun'].shorthelp := 'Rerun the script';
  
  private.buttons['Edit'] := widgetset.button(private.frame['bottomright'],
						 'Edit');
  private.buttons['Edit'].shorthelp := 'Edit the script and then rerun';
  
  widgetset.tk_release();
  
  whenever private.buttons['Delete']->press do {
    if(private.lock()) {
      private.delete();
      private.list();
      private.unlock();
    }
  }
  
  whenever private.buttons['Stop']->press do {
    if(private.lock()) {
      private.stop();
      private.list();
      private.unlock();
    }
  }
  
  whenever private.buttons['Edit']->press do {
    if(private.lock()) {
      private.edit();
      private.unlock();
    }
  }
  
  whenever private.buttons['Rerun']->press do {
    if(private.lock()) {
      private.rerun();
      private.unlock();
    }
  }
  
  whenever private.buttons['Submit']->press do {
    if(private.lock()) {
      private.submit();
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
  
  self.insert := function(name, host, comments='') {
    wider private;
    private.buttons['Name'].insert(name);
    private.buttons['Host'].insert(host);
    private.buttons['Comments'].insert(comments);
    return T;
  }
  
  self.refresh := function() {
    wider private;
    private.list();
    private.settitle();
    return T;
  }
  
  self.done := function() {
    wider private;
    private.frame['top']->unmap();
    return T;
  }
  
  self.dismiss := function() {
    wider private;
    private.frame['top']->unmap();
    return T;
  }
  
  self.map := function() {
    wider private;
    private.frame['top']->map();
    return T;
  }
  
  self.unmap := function() {
    wider private;
    private.frame['top']->unmap();
    return T;
  }
  
  widgetset.addpopuphelp(private, 5);

  ok := private.list();
  ok := private.settitle();
  
}

