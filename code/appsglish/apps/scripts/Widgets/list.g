# list.g: general-purpose list (container) object.

# Copyright (C) 1996,1997,1998,1999
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
# $Id: list.g,v 19.2 2004/08/25 02:15:45 cvsmgr Exp $

#---------------------------------------------------------

pragma include once
# print 'include list.g  h01sep99'

# include 'jen_util.g'		# makes jenutil/jtl
include 'combobox.g'
# include 'results_manager.g'
include 'guicomponents.g'	# messagebox,...
# include 'popuphelp.g'		# 
# include 'menubar.g'		# should list be independent of this? 
# include 'guimisc.g'		# filechooser etc
# include 'tracelogger.g'	# should list be independent of this? 

#=========================================================
test_list := function () {
    include 'menubar.g'
    private := [=];
    private.list := [=];
    private.t0 := time();			# used in item labels

  # Make the main components of the gui: 

    title := paste('test_list') 
    private.frame := frame(side='top',title=title); # overall
    private.menubar := menubar(private.frame);		# make a menu-bar
    private.listframe := frame(private.frame);		
    private.statusline := status_line(private.frame);	# 


  # Make a list, its gui, and some event-handlers:

    private.list := list(label='items');
    private.list.gui(private.listframe);

    whenever private.list.agent->* do {
	s := paste('private.list.agent: event=',$name);
	print s;
    }

    whenever private.list.agent->select do {
	s := paste('select event=',$name,',  value=',$value);
	item := private.list.get();		# get (ref to) current item
	if (is_fail(item)) print item;
    }
    whenever private.list.agent->message do {
	private.statusline.show(paste($value));
    }

  # Add some relevant menu-items to the menu-bar:

    defrec := private.menubar.defrecinit('some items','input');
    defrec.choice := [5,10,20];    
    defrec.action := ref function(n=1) {
	item := [=];
    	for (i in [1:5]) {
	    item.label := paste('item label:',i+10*n);
	    item.data := i + 100*n;
	    private.list.append(item, refresh=F);
        }
	private.list.refreshcombo();			# refresh the combo-box
    }
    private.menubar.makemenuitem(defrec);        	# 

    defrec := private.menubar.defrecinit('standalone','gui');    
    defrec.action := function() {
	sal := list()
    	sal.gui();
    }
    private.menubar.makemenuitem(defrec);        	# 

    return ref public;
};


#=========================================================
list := function (label='list items') {
    private := [=];
    private.value := 0;			# place-holder
    # private.value := value;		# list-object identifier (??)
    private.list := [=];		# list definition record
    private.list.label := label;	# input argument

    public := [=];

    s := paste('list: ',private.list.label)
    # public.trace := tracelogger(s);
    # whenever public.trace.agent -> message do {
    #	s := spaste(private.value,' ');
    #	s := spaste(s,private.list.label,': ',$value);
    #	public.message(s)
    # }

# Definition of private variables:

    private.init := function() {
	wider private;
	private.listframe := F;		# no gui yet
	private.mb := F;		# see .gui()
	private.gdescr := 'list generic description';
	private.list.displayfunction := F;	# item display func
	private.list.sdescr := ' ';	# specific description
	private.list.guicolor := 'lightgrey';# 'yellow'?
	private.list.attached := [=];	# attached named records
	private.menuseparator := [=];
	private.clear();		# clear the list
    }

    private.clear := function () {
	wider private;
	private.clearcombo();		# before!
	private.list.item := [=];	# actual list items
	private.list.itemlabel := ' ';	# as displayed
	private.list.items := [];	# order vector (points into list)
	private.list.length := 0;	# total length of list
	private.list.current := 0;	# index of current item
	return T;
    }

#=========================================================
# Public interface (specific part):

# Operations on individual list items:

    public.append := function(item, label=F, refresh=T) {
	return private.append (item, label, refresh);
    }
    public.replace := function(index=F, item, label=F) {
	return private.replace (index, item, label);
    }
    public.insert := function(index=F, item, label=F) {
	# return private.insert (index, item, label);
    }
    public.inspect := function(index=F, callback=F) {
	return private.inspect(index, callback);
    }
    public.get := function (index=F, copy=F) {
	return private.get (index, copy);
    }
    public.remove := function(index=F) {
	return private.remove(index);
    }

# Graphical user interface (gui):

    public.gui := function(ref guiframe=F) {
	return private.gui(guiframe);
    }
    public.menuitem := function(name, ref bagent) {
    	return private.menuitem (name, bagent);
    }
    public.hidegui := function() {
	return private.hidegui();
    }
    public.refreshcombo := function() {	
	return private.refreshcombo();
    }

# Operations on the entire list:

    public.save := function(file=F) {
	return private.save (file);
    }
    public.restore := function(file=F) {
	return private.restore (file);
    }
    public.items := function() {
	return private.list.items;
    }
    public.length := function() {
	return len(private.list.items);
    }
    public.label := function(label=F) {
	wider private;
	if (is_string(label)) private.list.label := label; 
	return private.list.label;
    }
    public.itemlabel := function(index=F, label=F) {
	wider private;
	index := private.currentindex(index);
	if (is_string(label)) {
	    private.list.itemlabel[index] := label;
	    private.refreshcombo();
	}
	return private.list.itemlabel[index];
    }
    public.type := function() {
	if (len(private.list.items)>0) {
	    i := private.list.items[1];			# first active item
	    s := type_name(private.list.item[i]);	# first only....??
	} else {
	    s := '(list empty)';
	}
	return s;
    }
    public.delete := function () {return public.done();}
    public.done := function() {
        wider private;
	private.clear();
	val private := F;
    }
    public.clear := function() {
	return private.clear();
    }
    public.current := function(index=F, notify=F) {
	return private.currentindex(index, notify);
    }
    public.attachrecord := function(rec, name=F, callback=F) {
    	return private.attachrecord (rec, name, callback);
    }
    public.getattached := function(name=F, copy=T) {
    	return private.getattached (name, copy);
    }
    public.detachrecord := function(name=F) {
    	return private.detachrecord (name);
    }
    public.inspectrecord := function(name=F, callback=F) {
    	return private.inspectrecord (name, callback);
    }
    public.displayfunction := function(callback=F) {
    	return private.displayfunction (callback);
    }
    public.descr := function(descr=F) {
	wider private;
	if (is_string(descr)) private.list.sdescr := descr;
	return private.list.sdescr;
    }

# Public interface (generic part):

    public.agent := create_agent();	# communication
    whenever public.agent -> * do {	# for testing only
	s := paste('list.agent: event=',$name,
		             ',  value=',$value);
	# public.trace.note(3,s)
    }
    whenever public.agent -> message do {	
	# s := paste('list message,  value=',$value);
	# public.trace.note(3,s)
    }

    public.help := function() {
	s := paste(' ');			# header?
	s := spaste(s,'\n',private.gdescr);	# generic descr
	s := spaste(s,'\n',private.list.sdescr);# specific descr
	print s;				# temporary
	return T;
    }
    public.inspectprivate := function() {
	include 'inspect.g';			# only if necessary
	name := 'list';				# private.list.label?
	inspect(private,name);
	return T;
    }
    public.printcommand := function(cmd=F) {	# needed?
    	# return jenutil.setprintcommand(cmd)
    }

#---------------------------------------------------------
# Message-handler (plug-in?)
# General message handler (depends on situation):

    private.statusline := F;			# defined in gui..
    public.message := function(str, color=F, box=F) {
	# public.trace.note(1,str);		# generic?
	if (is_record(private.statusline)) {
	    private.statusline.show(str);
	} else {
	    public.agent -> message(str);	# generic?
	    # print str;			# do something
	}    
	if (box) messagebox(str);		# separate box
	return str;
    }


#==========================================================
#==========================================================
# Private functions:
#==========================================================

#----------------------------------------------------------
# Refresh the combobox:

    private.clearcombo := function() {
	if (is_boolean(private.listframe)) return F;
	for (i in [1:(private.list.length+1)]) {
	    r := private.combo.delete(0);	# ridiculous!
	}
	return T;
    }

    private.refreshcombo := function() {
	wider private;
	if (is_boolean(private.listframe)) return F;
	private.clearcombo();
	k := 0;
	for (i in private.list.items) {
	    label := private.list.itemlabel[i];
	    private.combo.insert(label,F);
	    s := paste(k,i,': refreshcombo:',label);
	    if (i==private.list.current) {
		r := private.combo.select(k);
		s := paste(s,'(selected)',r);
	    }
	    # public.trace.note(3,s);
	    k +:= 1;			# combobox index
	}
	return T;
    }

#----------------------------------------------------------
# Append the given item at the tail of the list:

    private.append := function(item, label=F, refresh=T) {
	wider private;
	private.list.length +:= 1;		# extend the list
	index := private.list.length;		# the new slot
	private.list.items := [private.list.items,index];
	s := paste('append: items=',private.list.items);
	# public.trace.note(2,s);
	return private.replace(index, item, label, refresh);
    }

#----------------------------------------------------------
# Replace the specified item (index) with a new one:

    private.replace := function (index, item, label=F, refresh=T) {
	wider private;
	if (is_fail(index:=private.currentindex(index))) {
	    print index;			# temporary...?
	    return index;			# i.e. fail
	}
	private.list.item[index] := item;	# new item

	itemlabel := paste('item',index);	# default label
	if (is_string(label)) {			# explicit label 
	    itemlabel := paste(label);
	} else if (is_record(item)) {
	    if (has_field(item, 'label')) {
		itemlabel := paste(item.label);	# implicit label
	    } else if (has_field(item, 'name')) {
		itemlabel := paste(item.name);	# implicit label
	    }
	} 
	private.list.itemlabel[index] := itemlabel; 
	s := paste(index,' replace item: ',itemlabel);
	# public.trace.note(2,s);

	if (refresh) private.refreshcombo();	
	return T;
    }

#-------------------------------------------------------------
# Get a reference to, or a copy of, the specified item. 
# If the index=F, get the current one.

    private.get := function (index=F, copy=F) {
	if (is_fail(index:=private.currentindex(index))) {
	    return index;			# i.e. fail
	}
	itemlabel := private.list.itemlabel[index];
	s := spaste(index,' get (copy=',copy,') item:',itemlabel);
	public.message(s);
	if (copy) {
	    return private.list.item[index];	# copy
	} else {			
	    return ref private.list.item[index];# reference
	}
    }

#----------------------------------------------------------
# Remove the item with the given (index) from the list:
# If index=F, remove the current one.

    private.remove := function(index=F) {
	wider private;
	if (is_fail(index:=private.currentindex(index))) {
	    print index;			# temporary
	    return index;			# i.e. fail
	}
	
	itemlabel := private.list.itemlabel[index];	# old one
	s := paste(index,'remove item:',itemlabel)
	# public.trace.note(1,s);
	public.message(s);

	private.list.item[index] := F;		# delete the item

	sv := [private.list.items == index];
	k := ind(private.list.items)[sv];	# position in .items
	s := paste(k,'sv=',sv)
	# public.trace.note(3,s);

	if (k<len(private.list.items)) {
	    private.list.current := private.list.items[k+1]; # after
	} else if (k>1) {
	    private.list.current := private.list.items[k-1]; # before
	} else {
	    private.list.current := 0;		# none left
	}  
	private.list.items := private.list.items[!sv];	# remove

	s := paste('remove: current=',private.list.current)
	s := paste(s,' items:',private.list.items)
	# public.trace.note(2,s);

	private.refreshcombo();
	private.currentindex(notify=T);		# tell the world
	return T;
    }

#----------------------------------------------------------
# Make an item the 'current' one, and return the index. 
# If index=F, just return the current index. 
# If notify=T, send an event to the outside world.

    private.currentindex := function(index=F, notify=F) {
	wider private;
	bylabel := F;
	if (is_boolean(index)) {
	    index := private.list.current;	# current value
	} else if (is_string(index)) {		# by item-label
	    bylabel := T;
	} else if (!is_integer(index)) {
	    fail ('index should be integer or string');
	}
	n := private.list.length;		# total length
	if (n<=0) {
	    fail ('no items in list');
	} else if (bylabel) {			# index is string
	    nfound := 0;
	    label := index;			# copy string
	    for (i in private.list.items) {
		if (private.list.itemlabel[i]==label) {
		    index := i;			# make integer
		    nfound +:= 1;		# increment
		}
	    }
	    if (nfound==0) {
		fail (paste('item not found:',label));
	    }
	} else if (index<=0) {
	    fail(spaste('index=',index,'<=0'));
	} else if (index>n) {
	    fail(spaste('index=',index,'>length=',n));
	}

	if (index != private.list.current) {	# index changed
	    private.list.current := index;	# new index
	    notify := T;			# tell the world
	}
	if (notify) {
	    s := paste('current: index=',private.list.current);
	    # public.trace.note(1,s);
	    public.agent->select(index);	# send event
	}
	return private.list.current;		# return index
    }

#---------------------------------------------------------------
# Make a gui, either embedded or stand-alone:

    private.gui := function(ref guiframe=F) {
	wider private;
	if (is_agent(private.listframe)) {	# just in case
	    print 'private.listframe=',private.listframe;
	    # private.hidegui();		# causes Glish error!
	}

	if (is_boolean(guiframe)) {
	    standalone := T;		# standalone frame
	    s := paste('list:',private.list.label);
	    private.listframe := frame(title=s);
	} else {
	    standalone := F;		# embedded frame
	    private.listframe := ref guiframe;
	}


	private.comboframe := frame(private.listframe, side='left');
	whenever private.comboframe->killed do {	#
	    # print 'list: comboframe killed' 
	    # private.hidegui();	# causes Glish segmentation fault
	}

	#-----------------------------------------------------------
	# - Alternative: use a menubar here with its functions:
	# include 'menubar.g';			# only when needed
	# private.mb := menubar(private.comboframe);
	# - Drop the definition for private.menubutton below.
	# - Another alternative (uses private.menubutton):
	# private.mb := menubar(gui=F);		# just use menubar functions
	# - All menu-items have the following form (in menuitem()):
	# defrec := private.mb.defrecinit(<text>, private.list.label)
	# private.mb.makemenuitem(defrec, <action>)
	#-----------------------------------------------------------

	private.menubutton := button(private.comboframe, 
			             private.list.label, type='menu') 
	private.combo := combobox(private.comboframe);

	private.combo.vscrollbar('always');	# 'ondemand'?
	private.combo.hscrollbar('ondemand');
	# private.combo.labeltext(private.list.label);
	private.combo.labeltext(' ');
	private.combo.autoinsertorder('tail');	# 
	private.combo.entrybackground(private.list.guicolor);
	whenever private.combo.agent()->* do {
	    s := paste('combo.agent: event=',$name,
			          ', value=',$value);
	    # public.trace.note(1,s);
	};
	whenever private.combo.agent()->select do {
	    index := private.list.items[$value+1];
	    private.currentindex(index, notify=T);
	};

	private.menuitem('status', private.menubutton);
	private.menuitem('file', private.menubutton);
	private.menuitem('inspect', private.menubutton);
	private.menuitem('separator', private.menubutton);
	private.menuitem('remove', private.menubutton);
	private.menuitem('separator', private.menubutton);
	private.menuitem('clear', private.menubutton);
	# private.menuitem('inspectlist', private.menubutton);
	# private.menuitem('trace', private.menubutton);

	if (standalone) {
	    private.statusline := 
			status_line(private.listframe)
	    private.menuitem('separator', private.menubutton);
	    private.menuitem('dismiss', private.menubutton);
	} 

	private.refreshcombo();
	return T;
    }

# Add the specified button to the given button-agent (bagent):

    private.menuitem := function(name, ref bagent) {
	wider private;
	if (name=='dismiss') {
	    private.dismissbutton := button(bagent,'dismiss');
	    whenever private.dismissbutton->press do {
	    	private.hidegui()
	    };

	} else if (name=='inspect') {
	    private.inspectbutton := button(bagent,'inspect item'); 
	    s := 'inspect the value of the current item';
	    private.inspectbutton.shorthelp := s; 
	    whenever private.inspectbutton->press do {
		include 'inspect.g';			# only if necessary
	    	private.inspect();
	    };

	} else if (name=='inspectlist') {
	    private.inspectlistbutton := button(bagent,'inspect list'); 
	    s := 'inspect the entire list (record)';
	    private.inspectlistbutton.shorthelp := s; 
	    whenever private.inspectlistbutton->press do {
	    	private.inspectlist();
	    };

	} else if (name=='remove') {
	    private.removebutton := button(bagent,'remove item'); 
	    s := 'remove the current item';
	    private.removebutton.shorthelp := s; 
	    whenever private.removebutton->press do {
	    	private.remove();
	    };

	} else if (name=='separator') {		# separator
	    n := len(private.menuseparator);
	    private.menuseparator[n+:=1] := button(bagent,' ... '); 

	} else if (name=='clear') {
	    private.clearbutton := button(bagent,'clear list (!)'); 
	    s := 'clear the list';
	    private.clearbutton.shorthelp := s;
	    whenever private.clearbutton->press do {
	    	private.clear();
	    };

	} else if (name=='status') {
	    private.statusbutton := button(bagent,
				'status', type='menu')
	    private.lengthbutton := button(private.statusbutton,
				'list-length');
	    whenever private.lengthbutton->press do {
		n := len(public.items());
		s := paste('the list contains',n,'items');
		public.message(s);
	    };
	    private.typebutton := button(private.statusbutton,
				'item-type');
	    whenever private.typebutton->press do {
		s := public.type();
		s := paste('the list items have type',s);
		public.message(s);
	    };

	} else if (name=='file') {
	    private.filebutton := button(bagent,
				'file', type='menu')
	    private.savebutton := button(private.filebutton,
				'save list');
	    s := 'save the list in a file ...';
	    private.savebutton.shorthelp := s;
	    whenever private.savebutton->press do {
	    	private.save();
	    };

	    private.restorebutton := button(private.filebutton,
				'restore list');
	    s := 'restore a saved list from a file ...';
	    private.restorebutton.shorthelp := s;
	    whenever private.restorebutton->press do {
	    	private.restore();
	    };

	    private.saveitembutton := button(private.filebutton,
				'save item');
	    s := 'save current list-item in a file ...';
	    private.saveitembutton.shorthelp := s;
	    whenever private.saveitembutton->press do {
	    	private.saveitem();
	    };

	    private.readbutton := button(private.filebutton,
				'read item');
	    s := 'read a list-item from a file ...';
	    private.readbutton.shorthelp := s;
	    whenever private.readbutton->press do {
	    	private.readitem();
	    };

	} else if (name=='trace') {
	    caption := paste('trace','list');
    	    # public.trace.guibutton('showgui',bagent,caption); 

	} else {
	    s := paste('guibutton: not recognised:',name);
	    public.message(s);
	    fail(s);
	}

	# addpopuphelp(private);
	return T;
    }

# Hide the gui:

    private.hidegui := function() {
	wider private;
	# public.trace.hidegui();		# close trace-window
	val private.listframe := F;	# 
	val private.statusline := F;
	return T;
    }


#-----------------------------------------------------------
# Inspect the entire list (record): 

    private.inspectlist := function () {
	include 'inspect.g';			# only if necessary
	name := spaste(private.list.label);
	s2 := paste(index,'inspect:');
	inspect(private.list,name);
	return T;
    }

#-----------------------------------------------------------
# Display the value of the given item (index): 
# If a display formatting function (callback) is supplied or present, 
# use it.

    private.inspect := function (index=F, callback=F) {
	if (is_fail(index:=private.currentindex(index))) {
	    return index;			# i.e. fail
	}
	name := spaste('list-item[',index,']');
	itemlabel := private.list.itemlabel[index];
	s := paste('item',index,': label=',itemlabel,':');
	s2 := paste(index,'inspect:');
	if (is_function(callback)) {
	    s2 := paste(s2,'callback provided');
	    s1 := callback(private.list.item[index]);
	    include 'inspect.g';			# only if necessary
	    inspect(s1,name)
	} else if (is_function(private.list.displayfunction)) {
	    s2 := paste(s2,'use private.list.displayfunction()');
	    s1 := private.list.displayfunction(private.list.item[index]);
	    include 'inspect.g';			# only if necessary
	    inspect(s1,name)
	} else {
	    inspect(private.list.item[index],name);
	    return T;
	}
	# public.trace.note(2,s2);	# debugging only?
	return T;
    }


# Get/set the display function that may be used in private.inspect():

    private.displayfunction := function(callback=F) {
	wider private;
	s := paste('format: callback type=',type_name(callback));
	# public.trace.note(2,s);
	if (is_function(callback)) {
	    private.list.displayfunction := callback;
	    s := paste('format type=',
			type_name(private.list.displayfunction));
	    # public.trace.note(2,s)
	}
	return private.list.displayfunction;
    }

#----------------------------------------------------------
# Named records with auxiliary information may be attached.
# The list does not know anything about their contents.

    private.attachrecord := function(rec, name=F, callback=F) {
	wider private;
	if (is_boolean(name)) name := 'dflt';
	private.attached[name] := rec;
	private.callback[name] := callback;
	return T;
    }
    private.detachrecord := function(name=F) {
	wider private;
	if (is_boolean(name)) name := 'dflt';
	if (has_field(private.attached,name)) {
	    private.attached[name] := F;
	    private.callback[name] := F;
	} else {
	    s := paste('detachrecord: not recognised:',name);
	    messagebox(s,'red');
	}
	return T;
    }
    private.getattached := function(name=F, copy=T) {
	wider private;
	if (is_boolean(name)) name := 'dflt';
	if (has_field(private.attached,name)) {
	    if (copy) {
	    	return private.attached[name];
	    } else {
	    	return ref private.callback[name];
	    }
	} else {
	    s := paste('getattached: not recognised:',name);
	    messagebox(s,'red');
	}
	return T;
    }
    private.inspectrecord := function(name=F, callback=F) {
	wider private;
	if (is_boolean(name)) name := 'dflt';
	if (has_field(private.attached,name)) {
	    if (is_function(callback)) {
	    	s := callback(private.attached[name]);
	    	include 'inspect.g';			# only if necessary
		inspect(s,name);
	    } else {
	    	include 'inspect.g';			# only if necessary
	    	inspect(private.attached[name],name);
	    }
	} else {
	    s := paste('inspectrecord: not recognised:',name);
	    messagebox(s,'red');
	}
	return T;
    }

#------------------------------------------------------------
# Interaction with a disk-file:

    private.save := function(file=F) {
	wider private;
	if (is_boolean(file)) {
	    file := spaste(private.list.label,'.list');
	}
	write_value(private.list, file);	# write to file
	s := paste('saved list into file',file);
	return public.message(s);
    }

    private.saveitem := function(file=F) {
	wider private;
	if (is_string(file)) {
	    # OK, use the given filename
	} else {
	    # NB: This requires some form of filename input.
	    #     Filechooser requires existing files only!
	    #     Implement menubar functionality in list.g?
	    s := paste('option save-item not supported yet');
	    public.message(s);
	    return F;
	} 
	item := public.get();			# current item
	write_value(item,file);			# store in file
	s := paste('save item in file',file);
	return public.message(s);
    }

    private.restore := function(file=F) {
	wider private;
	if (is_string(file)) {
	    # use the given filename
	} else {
	    file := spaste(private.list.label,'.list');
	} 
	private.list := read_value(file);	# read from to file
	private.refreshcombo();				
    	private.currentindex(notify=T);		# tell the world
	s := paste('restored from file',file);
	return public.message(s);
    }

    private.readitem := function(file=F) {
	wider private;
	if (is_string(file)) {
	    # OK, use the given filename
	} else {
	    fc := filechooser();		# wait for result
	    file := fc.guiReturns;
	    if (is_boolean(file)) return F;	# cancelled
	} 
	item := read_value(file);		# read from file
	label := file;				# use filename as label
	public.append(item, label);		# append to list
	s := paste('read item from file',file);
	return public.message(s);
    }


#=========================================================
# Finished. Initialise and return the public interface:

    private.init();
    return public;

};		# closing bracket of list
#=========================================================

# gl := list();			# make a list object
# test_list();			# run test/demo-routine

# Comments on combobox:
# - Need cb.getlength(), to get nr of items
#   alternatively: allow cb.delete(0,'end');
#   alternatively: provide cb.clear();

