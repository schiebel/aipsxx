#   listboxcontainer.g: A GlishTk widget which binds a scrolllistbox to an itemcontainer
#
#   Copyright (C) 2000,2001
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
#	$Id: listboxcontainer.g,v 19.2 2004/08/25 02:15:50 cvsmgr Exp $	
#
pragma include once;

include 'widgetserver.g';
include 'itemcontainer.g';
include 'illegal.g';

const listboxcontainer := subsequence(ref parent,container=unset,
				      width=20,height=6,
				      mode='xing',relief='xing',
				      borderwidth=2, foreground='xing',
				      background='xing',
				      exportselection=F, fill='x',
				      seeoninsert=T,hscrollbar=T,
				      vscrollbar=T, vscrollbarright=T,
				      widgetset=dws)
{
    # type checking
    if (!is_agent(parent)) {
	fail 'Need a parent frame';
    }

    if (!is_unset(container)) {
	if (!is_itemcontainer(container) && (!is_record(container))) {
	    msg := spaste('"',container, '"is not a container or record');
	    fail msg;    
	}
    }
    
    #constructor
    its := [=];
    its.container := [=];
    its.listmap := [=];

    widgetset.tk_hold();

    its.outerFrame := widgetset.frame(parent, borderwidth=0, 
                                           side='left', expand=fill);     
    its.lbox := widgetset.scrolllistbox(parent=its.outerFrame,width=width,
					height=height,mode=mode,
					relief=relief,borderwidth=borderwidth,
					foreground=foreground,
					background=background,
					exportselection=exportselection,
					hscrollbar=hscrollbar,
					vscrollbar=vscrollbar,
					vscrollbarright=vscrollbarright,
					seeoninsert=seeoninsert,
					fill=fill);
    
    # public

    const self.fromforeign := function(container) {
	wider its;
	if ( is_itemcontainer(container)) {
	    its.container := container;	   
	} else {
	    itemcont := itemcontainer();
	    itemcont.fromrecord(container)
	    its.container := itemcont; 
	}
	if (its.container.length() > 0) {
	    for (str in its.container.names()) {
		its.map(str);
		its.lbox->insert(str);
	    }
	}
	return T;
    }
    const self.hasitem := function(item) {
	return its.container.has_item(item);
    }
    const self.itemnames := function() {	
	return its.container.names();
    }

    const self.done := function() {
	wider its;
	its.container.done();
	val its.container := F;
	val its.listmap := F;
	val its.lbox := F;
	val its.outerFrame := F;
	val its := F;
	val self := F;
	return T;
    }

    # private area

    const its.indextofield := function(index) {
	for ( str in field_names(its.listmap)) {
	    if (its.listmap[str] == index) {
		return str;
	    }
	}
	return '';
    }
    const its.fieldtoindex := function(field) {
	for ( str in field_names(its.listmap)) {
	    if (str == field) {
		return its.listmap[str];
	    }
	}
	fail 'field not found';
    }
     const its.set := function(item,value) {
	wider its;
	isthere := its.container.has_item(item);
	its.container.set(item,value);
	str := spaste(item);
	if (!isthere) {
	    its.map(item);
	    its.lbox->insert(str);	    
	}  
	return T;
    }
    const its.delete := function(item) {
	if (!is_string(item) && !is_integer(item)) {
	    fail 'Strings and integers only!'; 
	}
	wider its;	
	if (is_integer(item)) {
	    if ( item < 0 || item > length(its.listmap)-1) {
		fail 'Index out of range';
	    }
	    item := its.indextofield(item);
	    
	}
	if ( its.container.has_item(item) ) {
	    its.container.delete(item);
	    str := spaste(its.unmap(item));
	    its.lbox->delete(str);	
	} else {
	    fail 'field not found';
	}	
	return T;
    }

    const its.get := function(item) {
	# inconsistent indexing in itemcontainer (1:n) and listbox (0:n-1)
	# using listbox indexing !!!!
	if (is_integer(item)) {
	    item +:= 1;
	}
	return its.container.get(item);    
	
    }
    const its.map := function(item) {
	wider its;
	n := length(its.listmap);
	its.listmap[item] := n;
	return T;
    }
    const its.unmap := function(item) {
	wider its;
	listcpy := [=];
	index := as_integer(its.listmap[item]);
	for (str in field_names(its.listmap)) {
	    if (its.listmap[str] !=  index) {
		if ( its.listmap[str] > index) {
		    # decrement index
		    listcpy[str] := its.listmap[str]-1;		    
		} else {	
		    # leave it
		    listcpy[str] := its.listmap[str];
		}
	    }
	}
	its.listmap := listcpy;
	return index;
    }

    const its.asstringindex := function(value) {
	if (!is_integer(value)) {
	    for (i in 1:length(value) ) {
		index := (its.fieldtoindex(value[i]));
		out[i] := as_string(index);
	    }
	} else {
	    for (i in 1:length(value) ) {
		out[i] := spaste(value[i]);
	    }
	}
	return out;
    }

    # rest of constructor
    if (is_unset(container)) {
	its.container:= itemcontainer();
    } else {
	self.fromforeign(container);
    }
    ok := widgetset.tk_release();

    # Events

    # Forwarding
    whenever its.lbox->select do {
	if (length($value) > 0) {
	    field := its.indextofield($value);	
	    self->select(field);
	}
    }
    its.fwdwhenevers := "background bind borderwidth exportselection font height hscrollbar mode relief seeoninsert view vscrollbar vscrollview width";
    for (str in its.fwdwhenevers) {
	whenever self->[str] do {
	    its.lbox->[$name]($value);
	}
    }
    # specific events
    whenever self->see do {
	index := its.asstringindex($value);
	its.lbox->[$name](index);
	
    }
    whenever self->selection do {
	arr := its.lbox->selection();
	if (length(arr) > 0) {
	    local out;
	    for ( i in 1:length(arr) ) {
		out[its.indextofield(arr[i])] := 
		    its.container.get([its.indextofield(arr[i])]);
	    }
	    self->selection(out);
	}
    }
    whenever self->clear,self->select do {
	if ($value == 'all' && $name == 'clear') {
	    its.lbox->clear('0',spaste(length(its.listmap)-1));
	} else {
	    for (str in its.asstringindex($value)) {
		its.lbox->[$name](str);
	    }
	}
    }

    whenever self->insert do {
	rec := $value;
	if ( (length(rec) == 2) && (is_string(rec[1])) ) {
	    its.set($value[1],$value[2]);       
	} else {
	    for (str in field_names(rec)) {

		its.set(str,rec[str]);
	    }
	}
    }
    whenever self->delete do {
	rec := $value;
	first := F;
	for (i in 1:length(rec)) {
	    if (is_integer(rec[i])) {
		if (!first) {first := i;}
		ret := its.delete(rec[first]);
	    } else if (is_string(rec[i]))  {
		its.delete(rec[i]);
	    }
	}
    }

    whenever self->get do {
	 result := its.get($value);
	 self->get(result);
    }


}
