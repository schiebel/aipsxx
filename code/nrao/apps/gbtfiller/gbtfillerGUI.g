# gbtfiller_gui: GUI closure object for the gbtfiller
# Copyright (C) 1999,2000
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: gbtfillerGUI.g,v 19.0 2003/07/16 03:42:47 aips2adm Exp $

# include guard
pragma include once;

include "gmisc.g";
include "note.g";
include "widgetserver.g";


const gbtfiller_gui := function(title='gbtfiller', output='table',
				height=10, width=40, widgetset=dws)
{
   self := [=];
   result := [=];
#	I can't seem to bundle up the whenevers so that the GUI can
#	be automatically recreated if it is destroyed via a quit
#	Until and if I figure that out, this variable and the has_gui
#	member function can be used to at least determine the state
   self.guiAvailable := F;
   self.title := title;
   self.height := height;
   self.width := width;
   self.fillHandler := F;
   self.updateHandler := F;
   self.suspendHandler := F;
   self.quitHandler := F;
   self.outTable := T;

   self.statusColors := [=];
   self.statusColors['SUSPENDED'] := 'blue';
   self.statusColors['PAUSED'] := 'blue';
   self.statusColors['FILLING'] := 'yellow';
   self.statusColors['BOGUS'] := 'red';
   self.statusColors['OPENING'] := 'yellow';
   self.statusActions := [=];
   self.lastStatus := '';
   self.currStatus := '';
   self.openInProgress := F;
   self.statusPending := F;

   if (output == 'table') self.outTable := F;

   self.baseFrame := widgetset.frame(title=title,side='top');

   self.upperFrame := widgetset.frame(self.baseFrame, side='left');

   self.buttonFrame := widgetset.frame(self.upperFrame,side='top',expand='none')
   self.fillButton := widgetset.button(self.buttonFrame,text='Fill',fill='x');
   self.updateButton := widgetset.button(self.buttonFrame,text='Update',fill='x');
   self.suspendButton := widgetset.button(self.buttonFrame,text='Suspend',fill='x');
   self.quitButton := widgetset.button(self.buttonFrame,text='Quit',fill='x');
   self.buttonPad := widgetset.frame(self.buttonFrame,expand='y',height=1,width=1);

   self.entriesFrame := widgetset.frame(self.upperFrame,side='top',expand='none');
   self.projectFrame := widgetset.frame(self.entriesFrame,side='right');
   self.projectEntry := widgetset.entry(self.projectFrame, fill='x');
   self.projectLabel := widgetset.label(self.projectFrame, 'Project:',fill='none');
   self.backendFrame := widgetset.frame(self.entriesFrame,side='right');
   self.backendEntry := widgetset.entry(self.backendFrame, fill='x');
   self.backendLabel := widgetset.label(self.backendFrame, 'Backend:',fill='none');
   self.tableFrame := widgetset.frame(self.entriesFrame,side='right');
   self.tableEntry := widgetset.entry(self.tableFrame, fill='x');
   if (self.outTable) {
      self.tableLabel := widgetset.label(self.tableFrame, 'Table:',fill='none');
   } else {
      self.tableLabel := widgetset.label(self.tableFrame, 'MeasurementSet:',fill='none');
   }
   self.startFrame := widgetset.frame(self.entriesFrame,side='right');
   self.startEntry := widgetset.entry(self.startFrame, fill='x');
   self.startLabel := widgetset.label(self.startFrame, 'Start Time:',fill='none');
   self.stopFrame := widgetset.frame(self.entriesFrame,side='right');
   self.stopEntry := widgetset.entry(self.stopFrame, fill='x');
   self.stopLabel := widgetset.label(self.stopFrame, 'Stop Time:',fill='none');
   self.objectFrame := widgetset.frame(self.entriesFrame,side='right');
   self.objectEntry := widgetset.entry(self.objectFrame, fill='x');
   self.objectLabel := widgetset.label(self.objectFrame, 'Object:',fill='none');

   self.lowerFrame := widgetset.frame(self.baseFrame, side='left');
   self.statusLabel := widgetset.label(self.lowerFrame);

#       initial state is fill - fill and quit are active
#	pressing fill goes to update/paused state, update and suspend active
#		whichItem is disabled based on state
#		if relatedItem is an agent, its forground color is set
#		else whichItem's color is set
   self.itemState := function (whichItem, state, relatedItem=F) {
      wider self;
      color := 'black'
      if (state) color := 'gray75'
      whichItem->disabled(state);
      if (is_agent(relatedItem)) 
         relatedItem->foreground(color);
      else
         whichItem->foreground(color);
   }

   self.status := function(status, arg='')
   {
       wider self;
       if (self.openInProgress && has_field(self.statusActions, status)) {
	   self.statusPending := status;
       } else {
	   if (!is_boolean(self.statusPending)) {
	       status := self.statusPending;
	       self.statusPending := F;
	       self.statusActions[status]();
	   } else {
	       self.statusLabel->text(paste(status,arg));
	       if (has_field(self.statusColors, status))
		   self.statusLabel->foreground(self.statusColors[status]);
	       else
		   self.statusLabel->foreground('red');
	       self.lastStatus := self.currStatus;
	       self.currStatus := status;
	   }
       }
   }

   result.status := self.status;

   self.disabledEntries := function (state)
   {
     wider self;
     self.itemState(self.projectEntry, state, self.projectLabel);
     self.itemState(self.backendEntry, state, self.backendLabel);
     self.itemState(self.tableEntry, state, self.tableLabel);
     self.itemState(self.startEntry, state, self.startLabel);
     self.itemState(self.stopEntry, state, self.stopLabel);
     self.itemState(self.objectEntry, state, self.objectLabel);
   }

   result.disabledEntries := self.disabledEntries;

   self.statusActions['SUSPENDED'] := function()
   {
     wider self;
     if (!self.openInProgress) {
	 self.disabledEntries(F);
	 self.itemState(self.fillButton, F);
	 self.itemState(self.updateButton, T);
	 self.itemState(self.suspendButton, T);
     }
     self.status('SUSPENDED');
   }

   result.suspendedState := self.statusActions['SUSPENDED'];

   self.statusActions['FILLING'] := function()
   {
     wider self;
     if (!self.openInProgress) {
	 self.disabledEntries(T);
	 self.itemState(self.fillButton, T);
	 self.itemState(self.updateButton, F);
	 self.itemState(self.suspendButton, F);
     }
     self.status('FILLING');
   }

   result.fillingState := self.statusActions['FILLING'];

   self.statusActions['PAUSED'] := function()
   {
     wider self;
     if (!self.openInProgress) {
	 self.disabledEntries(T);
	 self.itemState(self.fillButton, T);
	 self.itemState(self.updateButton, F);
	 self.itemState(self.suspendButton, F);
     }
     self.status('PAUSED');
   }

   result.pausedState := self.statusActions['PAUSED'];

   self.statusActions['BOGUS'] := function ()
   {
      wider self;
      self.disabledEntries(T);
      self.itemState(self.fillButton, T);
      self.itemState(self.updateButton, T);
      self.itemState(self.suspendButton, T);
      self.quitHandler := F;
      self.status('BOGUS');
   }

   result.bogusState := self.statusActions['BOGUS'];

   self.statusActions['OPENING'] := function(on=F, arg='')
   {
       wider self;
       if (on) {
	   self.disabledEntries(T);
	   self.itemState(self.fillButton, T);
	   self.itemState(self.updateButton, T);
	   self.itemState(self.suspendButton, T);
	   self.status('OPENING',arg);
	   self.openInProgress := T;
       } else {
	   self.openInProgress := F;
	   if (has_field(self.statusActions,self.lastStatus))
	       self.statusActions[self.lastStatus]();
       }
   }

   result.openingState := self.statusActions['OPENING'];
   
   self.statusActions['SUSPENDED']();

   whenever self.quitButton->press do {
	if (is_function(self.quitHandler)) junk := self.quitHandler([=]);
	result.quit();
   }

   whenever self.fillButton->press do {
        proj := self.projectEntry->get();
        backend := self.backendEntry->get();
        table := self.tableEntry->get();
        start := self.startEntry->get();
        stop := self.stopEntry->get();
        object := self.objectEntry->get();
	if ((strlen(proj) > 0) && (strlen(backend) > 0)) {
	   fillrec := [project=proj,backend=backend];
           if (strlen(table) > 0) {
              if (self.outTable) {
                 fillrec.table_name := table;
              } else {
                 fillrec.ms_name := table;
              }
           }
           if (strlen(start) > 0) fillrec.start_time := start;
           if (strlen(stop) > 0) fillrec.stop_time := stop;
	   if (strlen(object) > 0) fillrec.object := object;
           if (is_function(self.fillHandler)) {
		junk := self.fillHandler(fillrec);
           } else {
		note('No fill handler available', priority='SEVERE',
		     origin='gbtfiller GUI');
           }
        } else {
	    note('You must specify a project and a backend',
		 priority='SEVERE',origin='gbtfiller GUI');
        }
   }

   whenever self.updateButton->press do {
        if (is_function(self.updateHandler)) junk := self.updateHandler([=]);
        else note('No update handler available',priority='SEVERE',origin='gbtfiller GUI');
   }

   whenever self.suspendButton->press do {
	if (is_function(self.suspendHandler)) {
	   junk := self.suspendHandler([=]);
           result.suspendedState();
	} else {
	    note('No suspend handler available',priority='SEVERE',origin='gbtfiller GUI');
	}
   }
 
   self.guiAvailable := T;

   self.setEntry := function(which, arg) {
      wider self;
      if (is_agent(which) && is_string(arg)) {
         which->delete("start","end");
         which->insert(arg,"start");
      }
   }
	
   result.setState := function(rec) {
	wider self;
	if (has_field(rec,'project')) {
		self.setEntry(self.projectEntry,rec.project);
	} else {
		self.setEntry(self.projectEntry,"");
	}
	if (has_field(rec,'backend')) {
		self.setEntry(self.backendEntry,rec.backend);
	} else {
		self.setEntry(self.backendEntry,"");
	}
        if (self.outTable) {
	   if (has_field(rec,'table_name')) {
		self.setEntry(self.tableEntry,rec.table_name);
	   } else {
		self.setEntry(self.tableEntry,"");
	   }
        } else {
           if (has_field(rec,'ms_name')) {
		self.setEntry(self.tableEntry,rec.ms_name);
           } else {
                self.setEntry(self.tableEntry,"");
           }
	}
	if (has_field(rec,'start_time')) {
		self.setEntry(self.startEntry,rec.start_time);
	} else {
		self.setEntry(self.startEntry,"");
	}
	if (has_field(rec,'stop_time')) {
		self.setEntry(self.stopEntry,rec.stop_time);
	} else {
		self.setEntry(self.stopEntry,"");
	}
	if (has_field(rec,'object')) {
		self.setEntry(self.objectEntry,rec.object);
	} else {
		self.setEntry(self.objectEntry,"");
	}
   }

   result.setFillHandler := function(handler) {
	wider self;
	self.fillHandler := handler;
   }

   result.setUpdateHandler := function(handler) {
	wider self;
	self.updateHandler := handler;
   }

   result.setSuspendHandler := function(handler) {
	wider self;
	self.suspendHandler := handler;
   }

   result.setQuitHandler := function(handler) {
	wider self;
	self.quitHandler := handler;
   }

   result.quit := function() {
      wider self;
      self.baseFrame := F;
      self.guiAvailable := F;
   }

   result.has_gui := function() { wider self; return self.guiAvailable;}

#	uncomment this to provide access to self - sometimes useful for debugging
   result.self := function() { wider self; return self;}

   return result;
}
