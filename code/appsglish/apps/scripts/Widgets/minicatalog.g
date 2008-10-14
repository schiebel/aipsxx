# minicatalog.g: File browsing widget
# Copyright (C) 2000,2001
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
# $Id: minicatalog.g,v 19.3 2005/04/15 15:33:59 dking Exp $

pragma include once;

include 'widgetserver.g';
include 'unset.g';

# to do: optional disable of type listbox

const minicatalog := subsequence(parent=F, allowedtypes='All', title=unset,
				 hasbuttons=F, widgetset=dws) {
    include 'catalog.g';
    its := [=];
    its.gui := [=];
    its.busy := F;
    its.types := allowedtypes;
    its.ws := widgetset;
    its.labels := "File Type";
    its.currentdir := '.';

    t := its.ws.tk_hold();
    its.gui.parent := parent;
    if (is_boolean(parent)) {
      if (is_unset(title)) title := 'Mini File Catalog';
      its.gui.parent := its.ws.frame(title=title);
    } else {
	its.gui.parent := ref parent;
    }
    #its.origcursor := its.gui.parent->cursor();

    its.gui.mainframe := its.ws.frame(its.gui.parent,relief='groove');
    its.gui.entryframe := its.ws.frame(its.gui.mainframe,side='left');
    its.gui.entrylbl := its.ws.label(its.gui.entryframe,text='Directory:');
    its.gui.entry := its.ws.entry(its.gui.entryframe, background='white',
				     fill='x');
    its.dclist := [=];
    its.gui.slb := its.ws.synclistboxes(parent=its.gui.mainframe,
					nboxes=2, labels=its.labels,
					hscrollbar=T,width=[20,15],
					fill='both');
    if (hasbuttons) {
      its.gui.bottomframe := its.ws.frame(its.gui.parent, side='left');
      its.gui.bottomleftframe := its.ws.frame(its.gui.bottomframe, height=0);
      its.gui.select := its.ws.button(its.gui.bottomframe, 'Select',
				       type='action');
      its.gui.bottommiddleframe := its.ws.frame(its.gui.bottomframe, height=0);
      its.gui.cancel := its.ws.button(its.gui.bottomframe, 'Cancel',
				       type='dismiss');
      its.gui.bottomrightframe := its.ws.frame(its.gui.bottomframe, height=0);
    }
    its.gui.slb->bind('<Double-ButtonPress>', 'doubleclick');
    its.gui.slb->bind('<Return>','return');
    t:=its.ws.tk_release();


    its.whenevers := [];
    its.pushwhenever := function() {
	wider its;
	its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
	return T;
    }

    its.doselection := function() {
      i := its.gui.slb->selection()+1;
      if(len(i)==0) return;
      dir := its.dclist.types[i];
      str := spaste(its.currentdir,'/',its.dclist.names[i]);
      if (dir == 'Directory') {
	self.update(str,its.types);
	self->select([fname=str,ftype=dir]);
      } else {
	rec := [fname=str,ftype=dir];
	self->doubleclick(rec);
      }
    }

    whenever its.gui.parent->done do {
      self->done();
    } its.pushwhenever();

    whenever self->clear do {
	its.gui.slb->clear('start','end');
    } its.pushwhenever();

    whenever its.gui.slb->doubleclick,its.gui.slb->return do {	
      its.doselection();
    } its.pushwhenever();

    whenever its.gui.slb->select do {
	i := its.gui.slb->selection()+1;
	if(len(i)>0) {
	    dir := its.dclist.types[i];
	    str := spaste(its.currentdir,'/',its.dclist.names[i]);	
	    rec := [fname=str,ftype=dir];
	    self->select(rec);	
	}
    } its.pushwhenever();    

    
    whenever its.gui.entry->return do {
	self.update($value,its.types);
    } its.pushwhenever();

    if (hasbuttons) {
      whenever its.gui.cancel->press do {
	self->done();
      } its.pushwhenever();

      whenever its.gui.select->press do {
	its.doselection();
      } its.pushwhenever();
    }

    self.disable:= function() {
	wider its;
	its.gui.parent->disable();
	deactivate its.whenevers;       

    }
    self.enable:= function() {	
	wider its;
	its.gui.parent->enable();
	activate its.whenevers;
    }
    self.update := function(directory=unset,types='All') {
	wider its;
	if (its.busy) {
	    return T;
	}
	if (is_unset(directory)) {
	    directory :=its.currentdir;
	}
	its.busy := T;
	self.disable();
	temp := its.dclist;
	its.dclist := dc.dirlist(dir=directory, mask='*',
				 listtypes=types, listattr=F);
	if (is_fail(its.dclist)) {
	    x := its.dclist;
	    its.dclist := temp;
	    its.busy := F;
	    self.enable();
	    fail x;
	}
	its.currentdir := its.dclist.directory;
	its.gui.entry->delete('start','end');
	its.gui.entry->insert(its.currentdir);
	its.gui.slb->delete('start','end');
	tmparr := array(' ',2,len(its.dclist.names)); 
	tmparr[1,] := its.dclist.names;
	tmparr[2,] := its.dclist.types;
	its.gui.slb->insert(tmparr);
	its.gui.slb->see('start');
	self.enable();
	its.busy := F;
	return T;
    }
    t := self.update(its.currentdir,its.types);

    self.setvalidtypes := function(types='All') {
	wider its;	
	its.types := types;
	return T;
    }

    self.done := function() {
	wider its,self;
	deactivate its.whenevers;
	its.gui.slb.done();
	val its.gui.mainframe := F;# have to do this ???
	val its.gui :=  F;
	val its := F;
	val self := F;
	return T;
    }
}
