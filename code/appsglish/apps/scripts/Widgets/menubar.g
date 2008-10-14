# menubar.g: general-purpose menu-bar object.

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
# $Id: menubar.g,v 19.2 2004/08/25 02:16:10 cvsmgr Exp $

#---------------------------------------------------------

pragma include once
# print 'include menubar.g  h01sep99'

include 'guicomponents.g'	# messagebox
include 'popuphelp.g'		#

#=========================================================
test_menubar := function () {
    include 'menubardemo.g'
    return menubardemo();
};


#=========================================================
# NB: If no argument, just use the menubar functions (defrec etc).

menubar := function (ref parentframe=F) {
    private := [=];
    public := [=];

    private.parentframe := parentframe;		# input argument

    private.init := function () {
	wider private;
    	private.filename := 'saveas.gls';	# default file-name
	private.messagebox := F;		# 
	private.menuagent := [=];		# buttons
	private.topmenuagent := [=];		# ref to top-menu-agents
	private.entryframe := F;		# see userentry()
	private.cautionframe := F;		# see caution()
	if (!is_boolean(private.parentframe)) {
    	    private.launch();
	}
	return T;
    }


#=============================================================
# Public interface:
#=============================================================

    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('menubar event:',$name,$value);
	# print s;
    }

    public.makemenu := function (text=F, ref menu=F) {
    	return private.makemenubutton (text, menu);
    }
    public.defrecinit := function (text=F, ref menu=F, funcname=F) {
    	return private.defrecinit (text, menu, funcname);
    }
    public.makemenuitem := function(defrec, ref callback=F) {
    	return private.makemenuitem (defrec, callback);
    }
    public.makemenuseparator := function(ref menu=F) {
    	defrec := private.defrecinit ('menu_separator', menu);
    	return private.makemenuitem (defrec);
    }
    public.userentry := function(defrec) {
    	defrec.text := 'direct_userentry';	# temporary kludge
    	return private.makemenuitem (defrec);
    }
    public.standardmenuitem := function (text, ref callback=F) {
    	return private.standardmenuitem (text, callback);
    }

    public.givehelp := function (ref help=F, title=F) {
    	return private.givehelp (help, title);
    }

    public.focus := function (text=F, color='yellow') {
    	return private.focus (text, color);
    }

    public.getbarmenuagent := function (text=F) {
    	return private.findmenu (text, baronly=T);
    }
    public.getmenuagent := function (text=F, menuname=F) {	#...?
    	return private.findmenuitem (text, menuname);
    }
    # public.getindices := function(text=F, menuname=F) {	#...?
    #	return private.getindices(text, menuname);
    # }

    public.getmenuframe := function() {
	return ref private.menuframe;
    }
    public.getbuttonframe := function() {
	return ref private.leftside;        # actual button frame
    }

    public.newtext := function (ref menuagent, newtext) {
	print 'menubar.newtext: obsolete';
	return F;
	for (m in menuagent) {m.text := newtext};
	return private.update(menuagent)
    }
    public.newaction := function (ref menuagent, ref callback) {
	print 'menubar.newaction: obsolete';
	return F;
	for (m in menuagent) {m.action := callback};
	return T;
    }
    public.disable := function (ref menuagent, disable=T) {
	for (m in menuagent) {m.disabled := disable}; 
	return private.update(menuagent)
    }
    public.tick := function (ref menuagent, tick=T) {
	for (m in menuagent) {m.tick := tick}; 
	return private.update(menuagent)
    }

    public.savefile := function(savefile=F) {
	wider private;
	if (!is_boolean(savefile)) private.filename := savefile;
	return private.filename;
    }
    public.summary := function(menuagent=F) {
	return private.summary(menuagent);
    }

    public.done := function(dummy=F) {return public.close();}
    public.close := function(dummy=F) {
	wider private;
	for (i in ind(private.menuagent)) {
	    if (is_agent(private.menuagent[i])) {
		deactivate whenever_stmts(private.menuagent[i]).stmt;
	    }
	}
	val private.menuagent := F; 			# necessary?
	private.cleanup();
	val private.menuframe := F;
	val private.parentframe := F;			#.....?
	public.agent -> done();				# outside world
	public.agent -> close();			# outside world
	return T;
    }

#======================================================================
#======================================================================
# Private functions:
#======================================================================
# Make the menubar:

    private.launch := function () {
	wider private;

	whenever private.parentframe->killed do {	#
	    private.cleanup();
	    # NB: calling .close() here causes Glish to exit (!?)
	    # print 'window killed, guiframe:',private.guiframe 
	}

    	private.menuframe := frame (parentframe,
		expand='x',side='left', relief='raised', borderwidth=1);

    	private.leftside := frame (private.menuframe,
		side='left',height=10,borderwidth=0);
    	private.middleSpacer := frame (private.menuframe,
		width=30,height=10,borderwidth=0);

	private.makemenubutton('help', private.menuframe);	# always
	return T;
    }


# Menu-items are defined with a definition record 'defrec'.

    private.defrecinit := function (text=F, ref menu=F, funcname=F) {
	wider private;			# because of private.paramfields
	defrec := [=];			# definition record

	defrec.text := text;		# button caption
	defrec.menu := menu;		# agent of its parent-menu
	defrec.menuname := F;		# name (text) of its parent-menu
	defrec.type := 'item';		# can be 'item' or 'menu'

	defrec.wait := F;		# if T, wait for OK/Cancel

	defrec.relief := 'flat';	# button style

	defrec.popupmenu := F;		# for popupmenu (help-button)

	defrec.disabled := F;		# enabled
	defrec.tick := F;		# not ticked 
	# defrec.toggle := F;		# if T, toggle each time 
	# defrec.toggled := F;		# current toggle value 

	defrec.action := ref private.default_action;	# callback function
	defrec.prompt := F;		# if string, ask user-input
	defrec.shorthelp := ' ';	# short-help string (does not work?)
	defrec.help := F;		# overall help (string/function)
	defrec.onlyif := F;		# inhibited if function != T
	defrec.refresh := F;		# refresh panel (e.g. for new context)
	defrec.auxinfo := [=];		# auxiliary info (string/function/record)
	defrec.test := F;		# overall test (function)
	defrec.autoapply := F;		# automatic overall test (function)
	defrec.caution := F;		# if string, caution the user first

	f := ' ';			# vector of 'param' field names
	n := 0;	
	f[n+:=1] := 'paramchoice';	# choice of param-values
	f[n+:=1] := 'paramchoiceonly';	# if T, only allow paramchoice 
	f[n+:=1] := 'paramshape';	# scalar/vector/measure/...
	f[n+:=1] := 'paramunit';	# string (measure?)
	f[n+:=1] := 'paramhelp';	# help (function/string) per param
	f[n+:=1] := 'paramtest';	# test-function per param
	f[n+:=1] := 'paramgui';		# gui-function per param
	f[n+:=1] := 'paramcheck';	# check-function per param
	f[n+:=1] := 'paramhide';	# if T, parameter is hidden
	f[n+:=1] := 'paramrange';	# allowed range of param-values
	private.paramfields := f;	# used elsewhere too	

	for (fname in private.paramfields) {
	    defrec[fname] := [=];
	}

	# After specifying a record of parameter values, it has to be passed to
	# some specific function by the application. This may be done by using the 
	# value of the hidden parameter 'funcname'. In order to facilitate this,
	# the menubar provides the following small automatic service: 

	if (funcname) {					# default is F (i.e. not)
	    defrec.paramchoice.funcname := defrec.text;	# i.e. the button-cation
	    defrec.paramhide.funcname := T;		# hidden from the user
	}

	return defrec;
    }


# Update some the given menu-agent(s) according to its description:

    private.update := function(ref menuagent) {
	wider private;
	for (m in menuagent) {
	    if (!m.disabled) m->disabled(m.disabled);
	    text := m.text;
	    if (m.tick) text := paste(text,'*');
	    m->text(text);
	    if (m.disabled) m->disabled(m.disabled);

	    s := paste('update:',text);
	    s := spaste(s,' menu=',m.menuname);
	    s := spaste(s,' disabled=',m.disabled);
	    # print s;				# temporary
	}
	# addpopuphelp(private);		#...?
	return T;	
    }

# Show a summary of the existing menu-agents:

    private.summary := function(menuagent=F) {
	if (is_boolean(menuagent)) {
	    menuagent := private.menuagent;
	    print 'summary of all menu-agents:'
	} else {
	    print 'summary of a subset of menu-agents:'
	}
	n := 0;
	for (m in menuagent) {
	    s := paste((n+:=1),m.type)
	    s := paste(s,m.disabled)
	    s := paste(s,m.tick)
	    s := paste(s,m.text)
	    s := spaste(s,'   menuname=',m.menuname)
	    print s;
	}
	return T;
    }


# Make a new menu-item, using the given definition record (defrec);

    private.makemenuitem := function(defrec, ref callback=F) {
	wider private;

	direct_userentry := F;			# 
	if (defrec.text=='menu_separator') {	# special item...
 	    private.checkmenu(defrec);		# check menu-agent
	    menubutton := defrec.menu;
	    n := len(private.menuagent) + 1;	# increment
	    return ref private.menuagent[n] := button(menubutton,' ');
	} else if (defrec.text=='direct_userentry') {
	    direct_userentry := T;		# 
	} else {
 	    private.checkmenu(defrec);		# check menu-agent
	}

	if (is_function(callback)) {		# callback function given
	    defrec.action := callback;		# copy it
	}

	private.checkdefrec (defrec);		# check/adjust syntax

	defrec.type := 'item';			# i.e.: not menu
	paramenu := F;
	text := defrec.text;
	param := [=];
	menubutton := defrec.menu;

      # Pop-up the user entry-box directly (i.e. no menu-button):

	if (direct_userentry) {			# temporary kludge
	    return private.direct_userentry(defrec);
	}

      # Make a sub-menu if only one parameter (with a choice of values), 
      # and no prompt specified: 

	if (is_boolean(defrec.prompt) & len(defrec.paramchoice)==1) {	
	    menubutton := private.makemenubutton(defrec.text, defrec.menu);
	    defrec.menuname := defrec.text;	# transfer the name
	    choice := defrec.paramchoice[1];	# one parameter only
	    shape := F;				# i.e. 'scalar'
	    if (len(defrec.paramshape)>0) {
	    	shape := defrec.paramshape[1];
	    }
	    for (i in ind(choice)) {
		v := private.getfirstchoice(choice[i], shape)
		defrec.paramvalue := v;
		defrec.text := spaste(defrec.paramvalue);
	    	menuagent := private.addmenuagent(menubutton, defrec);
	    }
	    return menuagent;				# last/only one

      # Make a regular menu-item

	} else {
	    return private.addmenuagent(menubutton, defrec);
	}
    }

# Get the first value of the choice record/vector:

    private.getfirstchoice := function (choice, shape=F) {
	if (is_function(choice)) {
	    v := choice();
	    if (is_fail(v)) print v;
	    # print 'getfirstchoice: is_function -> ',v;
	    choice := v;
	}
	if (is_boolean(shape) || shape=='scalar') {
	    if (is_record(choice)) return choice[1][1]
	    return choice[1];
	} else if (shape=='vector') {
	    if (is_record(choice)) return choice[1]
	    return choice;
	} else {
	    print 'getfirstchoice: not recognised',shape;
	    return F;
	}
    }


# Make a new menu-item, using the given definition record (defrec);

    private.addmenuagent := function(ref menubutton, defrec) {
	wider private;

	n := private.findmenuitem(defrec.text, menubutton, index=T);
	if (is_boolean(n)) {
	    # print defrec.text,': menuitem does not yet exist:',n;
	} else {
	    # print defrec.text,': menuitem exists already: n=',n;
	} 

	n := len(private.menuagent) + 1;		# increment
	private.menuagent[n] := button(menubutton, defrec.text, value=n);
	# if (defrec.popupmenu) popupmenu(private.menuagent[n]);
	# addpopuphelp(private);			# each time..?


	ff := field_names(defrec);			# all fields
	ff := ff[ff!='menu'];				# exclude
	for (fn in ff) {
	    private.menuagent[n][fn] := defrec[fn];	# copy all fields
	}

	whenever private.menuagent[n]->press do {
	    private.cleanup();
	    private.currindex := $value;		# used by .userentry()

	    r := T;                                     # assume OK
	    if (is_function(private.menuagent[$value].onlyif)) {
		r := private.menuagent[$value].onlyif(); # external validation
	    }
	    if (is_fail(r)) {
		print r;
		print 'menubar(onlyif)->fail: execution inhibited';
	    } else if (!is_boolean(r)) {                # e.g. string
		print 'menubar(onlyif)->',type_name(r),': execution inhibited';
		private.givehelp(r, 'onlyif');          # display message
	    } else if (!r) {                            # inhibited
		print 'menubar(onlyif)->F: execution inhibited';

	    } else if (is_string(private.menuagent[$value].caution)) {
	    	private.caution();			# caution the user first
	    } else if (is_string(private.menuagent[$value].prompt)) {
	    	private.userentry();			# popup-panel for user
	    } else {
	    	private.execute();			# execute action-function
	    }
	}

	# print ' ****** menu item',n,':',private.menuagent[n];
	return ref private.menuagent[n];
    }


# Allow direct user-entry (rather than setting up a menu-button). 
# NB: Temporary: split of user-entry from menubar?
# NB: In this way, the nr of user-entries keeps growing!

    private.direct_userentry := function(defrec) {
	wider private;

	# print '\n direct_userentry:',defrec;

	n := len(private.menuagent) + 1;		# increment
	menubutton := button(f:=frame(), type='menu');	# dummy button
	private.menuagent[n] := button(menubutton, defrec.text, value=n);
	private.currindex := n;				# used by .userentry()
	# addpopuphelp(private);			# each time..?

	ff := field_names(defrec);			# all fields
	ff := ff[ff!='menu'];				# exclude
	for (fn in ff) {
	    private.menuagent[n][fn] := defrec[fn];	# copy all fields
	}
	print 'wait=',defrec.wait, private.menuagent[n].wait;

	private.cleanup();
	private.userentry();			# popup-panel for user

	return T;
    }


#--------------------------------------------------------------------------
# Check/repair/signal/adjust/complete defrec syntax: 

    private.checkdefrec := function (ref defrec) {
	wider private;
	private.printlegacy := T;		# 
	s1 := spaste('menubar warning: ');
	s2 := spaste(' (item=',defrec.text,')');

	if (has_field(defrec,'choice')) {	# legacy
	    s := paste(s1,'defrec field \'choice\' -> paramchoice');
	    if (private.printlegacy) print paste(s,s2);
	    defrec.paramchoice := defrec.choice;
	}

	if (has_field(defrec,'param')) {	# legacy
	    s := paste(s1,'defrec field \'param\' -> paramchoice');
	    if (private.printlegacy) print paste(s,s2);
	    defrec.paramchoice := defrec.param;
	    defrec.param := [=];		# ..?
	}

	if (has_field(defrec,'paramvalue')) {	# legacy
	    s := paste(s1,'defrec has obsolete field \'paramvalue\'');
	    if (private.printlegacy) print paste(s,s2);
	    if (is_record(defrec.paramvalue)) {
		for (fname in field_names(defrec.paramvalue)) {
	    	    defrec.paramchoice[fname] := defrec.paramvalue[fname];
		}
	    } else {
	    	defrec.paramchoice := defrec.paramvalue;
	    }
	}
	defrec.paramvalue := [=];		# always, see .execute() !!!

	if (has_field(defrec,'paramtype')) {	# legacy
	    s := paste(s1,'defrec has obsolete field \'paramtype\'');
	    if (private.printlegacy) print paste(s,s2);
	    defrec.paramtype := [=];		# ..?
	}


	# If there is only one parameter in defrec, it does not have
	# to be specified with named fields in records. However, since
	# records are assumed downstream, such scalar/vectors are
	# converted into record fields named <private.dfltparname>

	private.dfltparname := '_x_';		# default param name
	s3 := paste('-> record-field',private.dfltparname);
	for (fname in private.paramfields) {
	    if (!is_record(defrec[fname])) {	
	    	value := defrec[fname];		# keep the value
	    	defrec[fname] := [=];		# make into record
	    	defrec[fname][private.dfltparname] := value;
		s := spaste('menubar defrec.',fname);
		s := sprintf('%-12s',s);
		s := paste(s,s3,s2);
		# print s;			# temporary
	    }
	}

	# see param<...> above.  

	if (!is_record(defrec.auxinfo)) {	
	    value := defrec.auxinfo;		# keep the value
	    defrec.auxinfo := [=];		# make into record
	    defrec.auxinfo.aux := value;	# string or function
	    s := spaste('menubar defrec.auxinfo');
	    s := sprintf('%-12s',s);
	    s := paste(s,s3,s2);
	    # print s;				# temporary
	}


	# Use the first choice-value one as the default paramvalue:

	for (fname in field_names(defrec.paramchoice)) {
	    if (!has_field(defrec.paramshape,fname)) {
		defrec.paramshape[fname] := 'scalar';
	    }
	    v := private.getfirstchoice(defrec.paramchoice[fname],
					defrec.paramshape[fname])
	    defrec.paramvalue[fname] := v;
	}

	return T;
    }


#============================================================================

# Make sure that the defrec has a valid menu-agent and menuname:

    private.checkmenu := function (ref defrec) {
	if (is_record(defrec.menu)) {
	    menuname := 'external';
	    if (has_field(defrec.menu,'text')) {
		menuname := defrec.menu.text
	    }
	} else if (is_string(defrec.menu)) {
	    menuname := defrec.menu;
	    defrec.menu := private.findmenu(defrec.menu);
	    if (is_boolean(defrec.menu)) { 
		defrec.menu := private.makemenubutton(menuname)
	    }
	} else {
	    menuname := '??';
	    defrec.menu := private.makemenubutton(menuname)
	}
	defrec.menuname := menuname;
	return T;
    }


# Make a new menu-button, attached to menu (if specified):

    private.makemenubutton := function(text, ref menu=F) {
	wider private;
	menuname := F;
	if (is_boolean(menu)) {				# default
	    menuagent := private.leftside;
	    menuname := 'menubar';
	} else if (is_string(menu)) {
	    menuagent := private.findmenu(menu);	# find existing
	    if (is_boolean(menuagent)) { 		# not found
	    	menuagent := private.leftside;	
	    	menuname := 'menubar';
	    } 
	} else if (is_record(menu)) {			# agent given
	    menuagent := menu;				# use it
	} else {					# not recognised
	    return F;
	}
	n := 1 + len(private.menuagent);		# increment 
	private.menuagent[n] := button(menuagent, text, 
				relief='flat', type='menu')
	private.menuagent[n].type := 'menu';
	private.menuagent[n].text := text;

	if (is_string(menuname)) {
	    # OK, is defined
	} else if (has_field(menuagent,'text')) {
	    menuname := menuagent.text;
	} else {
	    menuname := 'external';
	}
	private.menuagent[n].menuname := menuname;
	if (menuname=='menubar') {
	    k := 1 + len(private.topmenuagent);
	    private.topmenuagent[k] := ref private.menuagent[n]
	}

	# print 'mademenubutton:',n,text,menuname;
	return ref private.menuagent[n];
    }

#--------------------------------------------------------------------
# Put/remove a 'focus' color on the specified top-menubutton:

    private.focus := function (text=F, color='yellow') {
	wider private;
	for (m in private.topmenuagent) {
	    m->background('lightgrey');			# no focus
	    if (m.text==text) m->background(color);	# one focus
	}
	return T;
    }

#--------------------------------------------------------------------
# Find a menu-button with the given text (i.e. label);

    private.findmenu := function(text, baronly=F) {
	i := 0;
	for (m in private.menuagent) {
	    i +:= 1;
	    if (!is_boolean(m)) {
		if (m.type=='menu') {
		    if (m.text==text) {
			if (baronly) {			# on menubar only
			    if (m.menuname!='menubar') next;
			}
			return ref private.menuagent[i];
		    }
		} 
	    }
	}
	return F;
    }

# Find a menu-item with the given text (i.e. label),
# and attached to the given menu (if specified):

    private.findmenuitem := function(text, ref menu=F, index=F) {
	i := 0;
	# print 'findmenuitem:',text,'menu=',type_name(menu),index;
	for (m in private.menuagent) {
	    i +:= 1;
	    # print i,':',type_name(m),m.text,m.menuname;
	    if (!is_boolean(m)) {
		if (m.type=='item') {
		    if (is_boolean(menu)) {	# check menu
			# OK, any menu
		    } else if (is_string(menu)) {
			# print i,'string:',m.menuname,menu;
			# if (m.menuname != menu) next;
		    } else if (is_record(menu)) {
			# print i,'record:',m.menuname,menu.menuname;
			# if (m.menuname != menu.menuname) next;
		    } else {
			next;
		    }
		    if (m.text==text) {		# check text
			# print 'findmenuitem: found:',text;
			if (index) return i;	# return index 
			return ref private.menuagent[i];
		    }
		} 
	    }
	}
	return F;				# not found
    }


#==========================================================================
# A small collection of predefined 'standard' menu-items:

    private.standardmenuitem := function (text, ref callback=F) {
	defrec := private.defrecinit(text);
	if (text=='save') {
	    defrec.menu := 'file';
	    defrec.shorthelp := 'save in a default file';
	} else if (text=='saveas') {
	    defrec.text := 'save as ...';
	    defrec.menu := 'file';
	    defrec.shorthelp := 'save in a new file';
	    defrec.paramchoice.filename := private.filename;
	    defrec.prompt := 'give file name';
	} else if (any("open read"==text)) { 
	    defrec.text := paste(text,'...');
	    defrec.menu := 'file';
	    defrec.shorthelp := 'open a file and restore';
	} else if (text=='restore') {
	    defrec.menu := 'file';
	    defrec.shorthelp := 'restore from default file';

	} else if (any("dismiss exit quit hide close"==text)) { 
	    defrec.menu := 'file';
	    defrec.action := public.close;

	} else if (text=='clear') {
	    defrec.menu := 'view';
	    defrec.text := 'clear window';
	    defrec.shorthelp := 'clear text in window';
	} else if (text=='print') {
	    defrec.menu := 'view';
	    defrec.text := 'print window-text';
	    defrec.shorthelp := 'print a hardcopy of the text';
	} else if (text=='printcommand') {
	    defrec.menu := 'view';
	    defrec.text := 'set print-command';
	    defrec.shorthelp := 'specify print-command';
	    defrec.paramchoice.command := "pri lpr pr";
	    defrec.help := 'pri is the AIPS++ standard';
	    defrec.prompt := defrec.shorthelp;

	} else if (text=='find') {
	    defrec.menu := 'edit';
	    defrec.shorthelp := 'find';

	} else if (text=='glishelp') {
	    defrec.menu := 'help';
	    defrec.shorthelp := 'glishelp';
	    callback := function() {
		include 'glishelp.g';	# only when needed
		glishelp();
	    }

	} else if (text=='web') {
	    defrec.menu := 'help';
	    s := paste('Drive the WWW browser to the last',
		       'item for which help() was asked'); 
	    defrec.shorthelp := s;
	    callback := function() {
		include 'aips2help.g';	# only when needed
		web();
	    }

	} else if (text=='popupmenu') {
	    defrec.menu := 'help';
	    defrec.popupmenu := T;	# nothing is done with this

	} else if (any(text=="aips Refman: Glish:")) {
	    defrec.menu := 'help';
	    s := paste('Drive the WWW browser to the',text,'manual'); 
	    defrec.shorthelp := s;
	    callback := function() {
		include 'aips2help.g';	# only when needed
		help(text);
	    }

	} else if (text=='bug_report') {
	    defrec.menu := 'help';
	    defrec.shorthelp := 'report a bug';
	    callback := function() {
		include 'bug.g';	# only when needed 
		bug();
	    }

	} else {
	    defrec.menu := '??';	# not recognised, make new menu
	}

	if (is_function(callback)) {
	    defrec.action := callback;
	} else if (is_function(defrec.action)) {
	    # OK, default function provided
	} else {
	    s := paste('dummy action for',defrec.text);
	    defrec.action := function(p=F) {print s};
	}
	return public.makemenuitem(defrec);	
    }

#===========================================================================
# Execute the action associated with the selected menu-item:

    private.execute := function () {
	private.cleanup();
	k := private.currindex;
	value := private.menuagent[k].paramvalue;
	s := paste(k,'menubar.execute: value=',value)
	# print s,'\n action:\n',as_string(private.menuagent[k].action);
	if (len(value)<=0) {				# no parameters
	    s := paste(s,'(no param)',is_record(value),len(value))
	    r := private.menuagent[k].action();
	} else if (len(value)==1) {			# one parameter
	    s := paste(s,'one param=',value[1])
	    r := private.menuagent[k].action(value[1]);
	} else {					# parameter record
	    r := private.menuagent[k].action(value);
	}
	# print 'menubar.execute:',s;			# temporary
	if (is_fail(r)) {
	    print r;					# take other action...? 
	    fail(r)
	}
	# print 'menubar.execute: r=',r;		# temporary
	return r;
    }

# Execute the provided test-function:

    private.dotest := function (ref testfunction) {
	private.read_entryboxes();
	k := private.currindex;
	value := private.menuagent[k].paramvalue;
	r := testfunction(value);
	if (is_fail(r)) {
	    print 'failed: test-function';
	    print r;					# temporary
	} else if (is_string(r)) {
	    title := paste('result of test_function:');
	    private.givehelp (r, title);		#....?
	}
    }

# Helper function to clean up any open sub-frames:

    private.cleanup := function() {
	wider private;
	# print 'menubar.cleanup:'
	if (is_agent(private.entryframe)) {
	    # print '- remove entryframe'
	    private.entryframe -> unmap();		# Darrell's trick
	    val private.entryframe := F;		# see userentry()
	}
	if (is_agent(private.cautionframe)) {
	    # print '- remove cautionframe'
	    private.cautionframe -> unmap();		# Darrell's trick
	    val private.cautionframe := F;		# see caution()
	}
	# print '- initempagent():'
	private.initempagent();				# remove temporary agents
	# print '- public.agent->cleanup():'
	public.agent -> cleanup();			# outside world
	return T;
    }

# Helper function for message-box:

    private.boxmessage := function (text=F, title=F, trace=F) {
	wider private;
	inhibit := F;                                   # T: debugging
	if (inhibit) trace := T;                        # always
	s := paste('menubar.boxmessage(text=',type_name(text),'):');
	if (trace) print s,'  title=',type_name(title), title;

	if (is_string(text)) {
	    nlines := nchars := ncmax := 0;
	    for (s1 in split(text,'\n')) {
		nlines +:= 1;
		nc := len(split(s1,''));                # nr of chars/line
		nchars +:= nc;                          # total nr of chars
		ncmax := max(nc,ncmax);
	    }
	    maxcols := ncmax + 1;                       # necessary!
	    maxrows := min(nlines, 30);
	    maxrows := max(1,maxrows);                  # safety
	    s := spaste('text: nlines=',nlines,' nchars=',nchars,' ncmax=',ncmax);
	    if (trace) print s;
	    if (is_boolean(title)) title := 'messagebox';
	    messagebox(paste(text), title=paste(title), 
		       maxcols=maxcols, maxrows=maxrows);
	}
	return T;
    }

# Help-action for giving help:

    private.givehelp := function (ref help=F, title=F, trace=F) {
	wider private;
	if (trace) print 'givehelp: title=',title,'help=',type_name(help);
	if (is_function(help)) {
	    s := help();
	    if (is_fail(s)) print s;
	    if (trace) print '**',s;
	    if (is_string(s)) private.boxmessage(s, title)
	} else if (is_string(help)) {
	    if (trace) print '**',help;
	    private.boxmessage(help, title);
	} else if (is_boolean(help)) {
	    # do nothing ....
	} else {
	    print $value,'type not recognised:',type_name(help);
	}
	return T;
    }

#--------------------------------------------------------------------
# Caution (for options that do something drastic). 

    private.caution := function () {
	wider private;
	private.cleanup();
	menuagent := private.menuagent[private.currindex];

	private.cautionframe := frame(title='caution');

	subject := menuagent.shorthelp;
	label1 := label(private.cautionframe, subject);

	question := menuagent.caution;
	label2 := label(private.cautionframe, question);

	bf := frame(private.cautionframe, side='right');
	cancel := button(bf, 'cancel', background='red');
	contin := button(bf, 'OK', background='green');
	print '\a';					# beep

	whenever contin -> press do {private.execute()}	# OK, continue
	whenever cancel -> press do {private.cleanup()}	# no execution
	return T;
    }

#------------------------------------------------------------------
#------------------------------------------------------------------
# Entry of values by the user.

    private.userentry := function () {
	wider private;
	private.cleanup();
	menuagent := private.menuagent[private.currindex];

	title := paste('parameters for action:',menuagent.text);
	private.entryframe := frame(title=title, width=500);

	lab := label(private.entryframe, menuagent.prompt);

	private.make_entryboxes(menuagent);

	private.buttonframe := frame(private.entryframe, side='right');

	cancel_button := button(private.buttonframe,'cancel', background='red');
	OK_button := button(private.buttonframe,'OK', background='green');
	if (T) {					# always?
	    padding := frame(private.buttonframe);	# label/message?
	    private.overallhelp(private.buttonframe, menuagent)
	}

	whenever cancel_button -> press do {
	    private.cleanup();				# do not execute
	}

	r := 'undefined';				# return value..

	# print 'menuagent.wait=',menuagent.wait
	if (menuagent.wait) {
	    print 'waiting for OK/cancel.....';
	    await OK_button->press, cancel_button->press
	    #.............................
	    print '...continuing...';
	    print 'OK_button:',OK_button;
	    print 'cancel_button:',cancel_button;
	    if (has_field(OK_button,'press') && OK_button.press) {
	    	private.read_entryboxes();		# read  
	    	r := private.execute();		# execute action
		# print 'userentry: after execute(): r=\n',r;
		return r;	# NB: Does NOT return to calling function!!
	    } 

	} else {
	    whenever OK_button -> press do {
	    	private.read_entryboxes();		# read  
	    	private.execute();			# execute action
	    }
	}

	return r;		# NB: Where does this end up...?
    }


# Refresh the user popup-panel (e.g. for setting up a new context):

    private.refreshpanel := function() {
	private.cleanup();			# remove any current one
	private.userentry();			# renew popup-panel for user
    }

# Make the overall option-button:

    private.overallhelp := function (ref buttonframe, ref menuagent) {
	wider private;
	private.menu_button := button(buttonframe,'?',type='menu');
	if (!is_boolean(menuagent.help)) {
	    private.menu_help := button(private.menu_button,'help');
	    whenever private.menu_help -> press do {
		title := paste('help for:',menuagent.text);
	    	private.givehelp (menuagent.help, title);
	    }
	}
	if (is_function(menuagent.test)) {
	    private.menu_test := button(private.menu_button,'test');
	    whenever private.menu_test -> press do {
	    	private.dotest(menuagent.test);
	    }
	}
	if (menuagent.refresh) {
	    private.menu_refresh := button(private.menu_button,'refresh');
	    whenever private.menu_refresh -> press do {
	    	private.refreshpanel();
	    }
	}
	private.menu_aux := [=];			# auxiliary info
	for (fname in field_names(menuagent.auxinfo)) {
	    k := 1 + len(private.menu_aux);
	    private.menu_aux[k] := button(private.menu_button,fname,value=k);
	    private.menu_aux[k].action := menuagent.auxinfo[fname];
	    private.menu_aux[k].name := fname;
	    whenever private.menu_aux[k] -> press do {
		k := $value;
		name := private.menu_aux[k].name;
		action := private.menu_aux[k].action;
		if (is_function(action)) {
		    r := action();			# execute function
		    if (is_fail(r)) {
			print 'failed:',name;
			print r;			# temporary
		    } else if (is_string(r)) {
		    	title := paste('result of',name,'for:',menuagent.text);
	    	    	private.givehelp (r, title);	#....?
		    }
		} else {
		    title := paste(name,'for:',menuagent.text);
	    	    private.givehelp (paste(action), title);	#....?
		}
	    }
	}
	return T;
    }


# Make entry-boxes for all parameters:

    private.make_entryboxes := function (menuagent) {
	wider private;
	private.initempagent();

	tk_hold();					# 
	for (fname in field_names(menuagent.paramvalue)) {
	    private.makeboxframe(menuagent, fname);
	}
	tk_release();					# 
	return T;
    }

    private.initempagent := function (trace=F) {
	wider private;
	if (trace) print 'private.initempagent():';
	ss := "tempagent menu_aux menu_help menu_test menu_refresh";
	for (name in ss) {
	    if (trace) s := paste('menubar.initempagent():',name,':');
	    if (has_field(private,name)) {
		n1 := n2:= 0;
		for (i in ind(private[name])) {
		    n1 +:= 1;
		    if (is_agent(private[name][i])) {
			n2 +:= 1;
			deactivate whenever_stmts(private[name][i]).stmt;
		    }
		}
		if (trace) s := paste(s,n1,', agents deactivated:',n2); 
	    } else {
		if (trace) s := paste(s,'no such field');
	    }
	    if (trace) print s;
	}
	private.tempagent := [=];
	private.boxframe := [=];
	private.entrybox := [=];
	private.entrylabel := [=];
	private.entryinfo := [=];
	private.entryname := [=];
	private.entryvalue := [=];
	private.entrytype := [=];
	private.entryunit := [=];
	private.entryshape := [=];
	private.entryhelp := [=];
	private.entrytest := [=];
	private.entrygui := [=];
	private.entrycheck := [=];
	private.entrychoice := [=];
	private.entrymenu := [=];
	return T;
    }

# Make an entry-box for a single parameter (fname):

    private.makeboxframe := function(menuagent, fname=F) {
	wider private;

	if (has_field(menuagent.paramhide, fname)) {
	    hide := menuagent.paramhide[fname];		# hide T/F
	    if (hide) return;				# hidden 
	}

	n := 1 + len(private.boxframe);			# increment	
        private.boxframe[n] := frame(private.entryframe, side='right');
	private.entryinfo[n] := button(private.boxframe[n], 
				width=8, type='menu', relief='flat');

	private.entrymenu[n] := button(private.boxframe[n],'?',
					type='menu')
	private.entrybox[n] := entry(private.boxframe[n], width=30);
	private.entrybox[n] -> background('white');
	private.entrybox[n].nentry := n;
	private.onentrybox(private.entrybox[n]);

	private.entryname[n] := fname;
	private.entrylabel[n] := label(private.boxframe[n],
						spaste(fname,':'));

	help := F;					# default: none
	if (has_field(menuagent.paramhelp, fname)) {
	    help := menuagent.paramhelp[fname];		# help string/function
	}
	private.entryhelp[n] := help;

	test := F;
	if (has_field(menuagent.paramtest, fname)) {
	    test := menuagent.paramtest[fname];		# test-function
	}
	private.entrytest[n] := test;

	gui := F;
	if (has_field(menuagent.paramgui, fname)) {
	    gui := menuagent.paramgui[fname];		# gui-function
	    if (!is_function(gui)) gui := F;		# give message?
	}
	private.entrygui[n] := gui;

	check := F;
	if (has_field(menuagent.paramcheck, fname)) {
	    check := menuagent.paramcheck[fname];	# check-function
	    if (!is_function(check)) check := F;	# give message?
	} else if (has_field(menuagent.paramrange, fname)) {
	    check := menuagent.paramrange[fname];	# see .checkrange()
	}
	private.entrycheck[n] := check;

	hide := F;
	if (has_field(menuagent.paramhide, fname)) {
	    hide := menuagent.paramhide[fname];		# hide T/F
	}

	shape := 'scalar';
	if (has_field(menuagent.paramshape, fname)) {
	    shape := menuagent.paramshape[fname];	# e.g. 'vector'
	}
	private.entryshape[n] := shape;

	unit := F;
	if (has_field(menuagent.paramunit, fname)) {
	    unit := menuagent.paramunit[fname];		# e.g. 'm/s'
	}
	private.entryunit[n] := unit;

	choiceonly := F;
	if (has_field(menuagent.paramchoiceonly, fname)) {
	    choiceonly := T;
	}
	if (choiceonly) private.entrybox[n] -> disabled(T);

	choice := [=];
	refresh_value := F;
	if (has_field(menuagent.paramchoice, fname)) {
	    choice := menuagent.paramchoice[fname];	# vector/record/function
	    if (is_function(choice)) {			# is a function
		v := choice();				# execute it 
		if (is_fail(v)) print v;
		choice := v;				# vector/record
		refresh_value := T;			# do not use current value
	    }
	    if (!is_record(choice)) {
		v := choice;
		choice := [=];				# choice -> record
		choice[1] := v;
	    }
	}
	private.entrychoice[n] := choice;		# record


	value := menuagent.paramvalue[fname];		# current value
	if (refresh_value) {				# use 1st choice
	    value := choice[1][1];			# if scalar
	    if (shape=='vector') value := choice[1];	# if vector
	}
	ptype := type_name(value);			# data-type
	private.updatentry(n, value, ptype, origin='makeboxframe');


	if (hide) {					# 'hidden' parameter 
	    # private.entrylabel[n] -> foreground('grey');
	    # private.entryinfo[n] -> foreground('grey');
	    # private.entrybox[n] -> foreground('grey');
	    private.entrybox[n] -> background('lightgrey');
	    private.entrybox[n] -> disabled(T);
	    s := 'not editable';
	    k := 1 + len(private.tempagent);
	    private.tempagent[k] := button(private.entrymenu[n],s)

	} else {					# normal parameter

	    if (choiceonly) {
		k := 1 + len(private.tempagent);
		private.tempagent[k] := button(private.entrymenu[n],
					       'not editable')
		k := 1 + len(private.tempagent);
		private.tempagent[k] := button(private.entrymenu[n],
					       'allowed values:')
	    }

	    for (vv in choice) {			# choice is a record
		if (shape=='vector') {
		    private.maketempagent_value (vv, n);
		} else {				# assume: shape=='scalar'
		    for (value in vv) {			# each field may be a vector
		        private.maketempagent_value (value, n);
		    }
		}
	    }

	    if (!is_boolean(private.entryhelp[n])) {
		k := 1 + len(private.tempagent);
		private.tempagent[k] := button(private.entrymenu[n],
					       'help', value=k)
		private.tempagent[k].type := 'help';
		private.tempagent[k].nentry := n;
		private.ontempagent(private.tempagent[k]);
	    }

	    if (is_function(private.entrygui[n])) {
		k := 1 + len(private.tempagent);
		private.tempagent[k] := button(private.entrymenu[n],
					       'gui', value=k)
		private.tempagent[k].type := 'gui';
		private.tempagent[k].nentry := n;
		private.ontempagent(private.tempagent[k]);
	    }

	    if (is_function(private.entrytest[n])) {
		k := 1 + len(private.tempagent);
		private.tempagent[k] := button(private.entrymenu[n],
					       'test', value=k)
		private.tempagent[k].type := 'test';
		private.tempagent[k].nentry := n;
		private.ontempagent(private.tempagent[k]);
	    }

	    # if (private.entryshape[n] != 'scalar') {			# always?
		k := 1 + len(private.tempagent);
	    	private.tempagent[k] := button(private.entryinfo[n],
			        spaste(private.entryshape[n]));
	    # }

	    if (!is_boolean(private.entryunit[n])) {
		k := 1 + len(private.tempagent);
	    	private.tempagent[k] := button(private.entryinfo[n],
			        spaste('unit: ',private.entryunit[n]));
	    }

	}

	private.decode_entrybox(n);			# cycle round (test)
	# print n,'entrybox:',type,fname,'=',value,'help:',help;
	return T;
    } 

# Helper function: make a tempagent of type 'value':

    private.maketempagent_value := function (value, nentry) {
	wider private;
	k := 1 + len(private.tempagent);
	private.tempagent[k] := button(private.entrymenu[nentry],
				spaste('   ',value), value=k);
	private.tempagent[k].type := 'value';
	private.tempagent[k].paramvalue := value;
	private.tempagent[k].ptype := type_name(value);
	private.tempagent[k].nentry := nentry;
	private.ontempagent(private.tempagent[k]);
	return T;
    }

# Helper function: take action on return in entrybox:

    private.onentrybox := function(ref entrybox) {
	wider private;
	whenever entrybox -> return do {
	    v := $value;				# result of return
	    for (i in ind(private.boxframe)) {
	    	svalue := private.entrybox[i] -> get();	# get value
		if (svalue==v) {
		    private.decode_entrybox(i);		# cycle round
		    break;				# finished
		}
	    }
	}
    }


# Helper function: take action on button pressed:

    private.ontempagent := function(ref tempagent) {
	wider private;
	whenever tempagent -> press do {
	    trace := F;                                 # debugging
	    k := $value;				# tempagent number
	    n := private.tempagent[k].nentry;		# entrybox number
	    tempagenttype := private.tempagent[k].type;
	    s := spaste('\n\n menubar tempagent event: k=',k,' n=',n);
	    if (trace) print s := paste(s,tempagenttype);

	    if (tempagenttype=='value') {
		value := private.tempagent[k].paramvalue;
		ptype := private.tempagent[k].ptype;
		private.updatentry(n, value, ptype, origin='ontempagent (value)');
		for (i in [1:3000]) x := acos(-1);	# delay....!
		private.decode_entrybox(n);		# cycle round

	    } else if (tempagenttype=='help') {
		title := paste('help for:',private.entryname[n]);
		if (trace) print type_name(title),'title=',title;
		if (trace) print 'private.entryhelp[n]:',type_name(private.entryhelp[n]);
		private.givehelp (private.entryhelp[n], title);

	    } else if (tempagenttype=='test') {
		value := private.decode_entrybox(n);	# get/decode/check
		if (trace) print 'value=',type_name(value),shape(value),':',value;
		if (trace) print 'private.entrytest[n]:',type_name(private.entrytest[n]);
		s := private.entrytest[n](value);	# function always..?
		title := paste('test of:',private.entryname[n]);
		if (trace) print type_name(title),'title=',title;
		if (is_string(s)) private.boxmessage(s, title);

	    } else if (tempagenttype=='gui') {
		# value := private.decode_entrybox(n);	# get/decode/check
		value := private.decode_entrybox(n, ignoretype=T);
		private.gui_nentry := n;
		# Call the gui call-back function (see example below).
		# This makes the gui, and should return an agent,
		# which send the events dismiss() and/or cancel():
		private.gui_agent := private.entrygui[n](value);
		s := paste('menubar.ontempagent(gui): n=',n);
		s := paste(s,'input arg:',type_name(value),shape(value));
		s := paste(s,'->',type_name(private.gui_agent));
		print s;                                # temporary
		if (!is_agent(private.gui_agent)) {
		    print s,'gui_agent not an agent!';  # always
		}
		whenever private.gui_agent -> cancel do {
		    # cancel event: do nothing
		    n := private.gui_nentry;
		    s := paste('menubar: gui_agent: n=',n);
		    print s := paste(s,'cancel event'); # temporary
		    deactivate whenever_stmts(private.gui_agent).stmt;
		    val private.gui_agent := F;         # .....?
		}
		whenever private.gui_agent -> dismiss do {
		    # dismiss event received: update entry-box value
		    n := private.gui_nentry;
		    s := paste('menubar: gui_agent: n=',n);
		    s := paste(s,'dismiss event');
		    s := paste(s,'$value:',type_name($value),shape($value));
		    if (is_string($value)) s := paste(s,'=',$value);
		    print s;                            # temporary
		    private.updatentry(n, $value, origin='ontempagent (gui)');
		    for (i in [1:3000]) x := acos(-1);	# delay....!
		    private.decode_entrybox(n);		# cycle round
		    deactivate whenever_stmts(private.gui_agent).stmt;
		    val private.gui_agent := F;         # .....?
		}
		## await private.gui_agent -> dismiss;	# DON'T wait for dismiss event

	    } else {
		print 'ontempagent: not recognised',tempagent
	    }
	}
    }

# Example of a gui callback function (see ontempagent() above):
# NB: This is just an example: not called anywhere in this object!

    private.example_gui_callback := function(current_value=F) {
	wider private;
	print 'private.gui_uvb[fname]: current_value=',current_value;
	private.tempguiagent := create_agent();         # mandatory
	#------------------------------------------------------------
	# Example of a simple gui: a frame with a dismiss button:
	private.tempguiframe := frame(title=spaste('gui_uvb.',fname));
	private.tempguibutton_ok := button(private.tempguiframe,'dismiss',
					   background='orange');
	private.tempguibutton_cancel := button(private.tempguiframe,'cancel',
					       background='yellow');
	# The callback should return either a dismiss or a cancel event:
	whenever private.tempguibutton_ok -> press do {	
	    private.tempguiagent -> dismiss($value);   
	    deactivate whenever_stmts(private.tempguiagent).stmt;
	    val private.tempguiframe := F;	        # remove gui
	}
	whenever private.tempguibutton_cancel -> press do {	
	    private.tempguiagent -> cancel();    
	    deactivate whenever_stmts(private.tempguiagent).stmt;
	    val private.tempguiframe := F;	        # remove gui
	}
	#------------------------------------------------------------
	# Wait for dismiss or cancel event via private.tempguiagent:	
	return ref private.tempguiagent;	        # mandatory 
    }


# Read and decode the contents of all entryboxes:

    private.read_entryboxes := function() {
	wider private;
	k := private.currindex;
	for (i in ind(private.boxframe)) {
	    name := private.entryname[i];			# parameter name
	    value := private.decode_entrybox(i);		# get and decode
	    # print k,'read_entrybox',i,name,'=',value;
	    private.menuagent[k].paramvalue[name] := value;	# new default value
	}
	return T;
    }

# Get and decode the contents of entry-box k:

    private.decode_entrybox := function(k, ignoretype=F) {
	wider private;
	name := private.entryname[k];			# get name
	svalue := private.entrybox[k]->get();		# get string value

	ptype := private.entrytype[k];			# e.g. 'integer'
	if (ignoretype) ptype := 'ignoretype';
	shape := private.entryshape[k];			# e.g. 'scalar'
	value := private.decode(svalue, ptype, shape, name)
	if (is_fail(value)) {
	    print '\a';					# beep
	    title := paste('invalid value of:',name);
	    s := paste('eval(value) produced a fail');
	    s := paste(s,'\n NB: restored last valid value');
	    private.boxmessage(s, title);
	    value := private.entryvalue[k];		# recover last value
	}
	ptype := type_name(value);

	if (!is_boolean(private.entrycheck[k])) {	# check validity
	    s := spaste(name,' (',ptype,') =',value,':');
	    if (is_function(private.entrycheck[k])) {
	    	ok := private.entrycheck[k](value);	# use given function
		if (is_fail(ok)) {
		    print paste(s,'entrycheck has failed'); 
		    print ok;
		}
	    } else {
		pp := private.entrycheck[k];
	    	ok := private.checkrange(value, pp);	# use internal function
	    }
	    if (is_boolean(ok) & ok) {			# ok (T)
		# print s,'validity-check: ok';		# temporary
	    } else {					# problem 
	    	print '\a';				# beep
		if (is_boolean(ok)) ok := 'invalid value or type';
		s := paste(s,'\n',ok);
		s := paste(s,'\n NB: restored last valid value');
	    	title := paste('invalid value of:',name);
	        private.boxmessage(s, title);
	    	value := private.entryvalue[k];		# recover last value
		ptype := type_name(value);
	    }
	}
	private.updatentry (k, value, ptype, origin='decode_entrybox');
	return value;					# essential!
    }

# Check whether the given value is in range:

    private.checkrange := function (value, pp) {
	print 'checkrange: value=',value,'pp=',pp;	# temporary
	if (is_function(pp)) {				# function provided 
	    r := pp(value);				# returns T or string!
	    if (is_fail(r)) print r;
	    return r;
	} else if (is_numeric(pp) && len(pp)==2) {
	    if (value<pp[1]) {
		return paste('out-of-range:',value,'<',pp[1]);
	    } else if (value>pp[2]) {
		return paste('out-of-range:',value,'>',pp[2]);
	    }
	    return T;					# OK
	} else {
	    return paste('checkrange: not recognised',pp);
	}
	return F;
    } 

# Update entry nr k with the given value and its type:

    private.updatentry := function (k, value, ptype=F, origin=F, trace=F) {
	wider private;
	s := paste('menubar.updatentry(',k,ptype,origin);
	s := spaste(s,', value=',type_name(value),shape(value),'):');
	if (is_boolean(ptype)) ptype := type_name(value);
	if (is_string(value)) {
	    sval := paste(value);
	} else {
	    sval := spaste(value);
	}
	ss := split(sval,'');                           # split into chars
	nchar := len(ss);
	if (trace) print paste(s,'->',ptype,' nchar=',nchar);
	if (nchar>80) {
	    # print 'menubar.updatentry(): nchar limited to 80 <',nchar;
	    # sval := spaste(ss[1:80]);
	}
	private.entrybox[k] -> delete ('start','end');	# clear entry-box
	private.entrybox[k] -> insert(sval);		# display value (string)
	private.entryinfo[k] -> text(ptype);		# display its type
	private.entryvalue[k] := value;			# keep value
	private.entrytype[k] := ptype;			# keep ptype 
	return T;
    }

# Decode the string-value from a entry-box. 

    private.decode := function (sval, expectype, shape, name=F) {
	s := paste('menubar.decode():',name,expectype,shape,len(sval),'sval=',sval);
	# print s;

	if (expectype == 'string') {
	    if (shape=='vector') {
	    	sval := split(sval,' ');		# split on spaces
	    }
	    return rval := sval;			# return string
	}  

	if (shape=='vector') {
	    ss := split(sval,'');                       # split into chars
	    if (any(ss=='[')) {                         # vector opening bracket
		if (!any(ss==']')) {                    # no vector closing bracket
		    ss := [ss,']'];                     # add one
		    sval := spaste(ss);                 # re-paste
		}
	    } else {
		# warning message?
	    }
 	    ss := split(sval,' ');			# split on spaces
	    s1 := paste(ss,sep=',');		        # re-paste with comma's
	    rval := eval(s1);				# evaluate 
	    if (is_fail(rval)) {
	    	print s;
		print 'evaluated unsuccesfully: s1=',s1;
	    	fail(rval);
	    }  
	} else {
	    rval := sval;
	}

	if (expectype == 'ignoretype') {                # ignore type               
	    return rval;                                # return as is
	} else if (expectype == 'double') {
	    return rval := as_double(rval);		# convert
	} else if (expectype == 'integer') {
	    return rval := as_integer(rval);		# convert
	} else if (expectype == 'complex') {
	    return rval := as_complex(rval);		# convert
	} else if (expectype == 'dcomplex') {
	    return rval := as_dcomplex(rval);		# convert
	} else if (expectype == 'boolean') {
	    if (rval=='F') return rval := F;	# as_boolean('T') -> T 
	    return rval := T;                   # as_boolean('F') -> T (!) 
	} else if (expectype == 'float') {
	    return rval := as_float(rval);		# convert
	} else if (expectype == 'short') {
	    return rval := as_short(rval);		# convert
	} else if (expectype == 'byte') {
	    return rval := as_byte(rval);		# convert
	} else {
	    print s;
	    print s := paste('decode: not recognised',expectype);
	    fail(s);
	}
    }


#========================================================================
# Default action (function), used if none supplied in defrec.action:

    private.default_action := function(param=F) {
	s := paste('\n This \'default_action\' was called because');
	s := paste(s,'\n no other action (function) has been specified.');
	s := paste(s,'\n It merely shows the input argument value(s).');
	s := spaste(s,'\n\n param (',type_name(param),'):');
	if (is_record(param)) {
	    ff := field_names(param);
	    for (fname in ff) {
		value := param[fname];
		ptype := type_name(value);
		n := len(value);
		s := spaste(s,'\n field ', fname,': (',ptype,') ');
		if (is_record(value)) {
		    s := spaste(s,' ',value)
		} else {
		    if (n<=0) {
			s := spaste(s,' empty')
		    } else if (n==1) {
			s := spaste(s,' scalar:',value)
		    } else {
			nmax := 20;
			s := spaste(s,' vector[',n,']: ');
			s := paste(s,value[1:min(nmax,n)]);
			if (n>nmax) s := paste(s,'...');
		    }
		}
	    }
	} else {
	    s := paste(s,param);
	}
	name := private.menuagent[private.currindex].text;
	title := paste('default action for:',name);
	private.boxmessage(s, title);
	return s;
    }

#========================================================================
# Temporarily not used (perhaps later): 
#========================================================================
# Get a reference to the specified menubutton(s):

    private.getmenuagent := function(text=F, menu=F) {
	ii := private.getindices(text, menu);		# vector of indices
	refagent := [=];
	n := 0;
	for (i in ii) {
	    refagent[n+:=1] := ref private.menuagent[i];
	}
	return refagent;	# record with zero or more menu-agents
    }

# Remove the specified menubutton(s):

    private.removemenuagent := function(text=F, menuname=F) {
	wider private;
	ii := private.getindices(text, menuname); 	# vector of indices
	for (i in ii) {
	    val private.menuagent[i] := F;		# causes glish to exit!
	}
	return T;
    }

# Helper function: get vector of indices in private.menuagent:

    private.getindices := function(text=F, menuname=F) {
	anytext := is_boolean(text);
	anymenu := is_boolean(menuname);
	ii := [];
	for (i in ind(private.menuagent)) {
	    if (is_record(private.menuagent[i])) {	# may be boolean!
	    	if (is_boolean(menuname)) {
		    # OK, any menu
		} else if (is_string(menuname)) {
		    if (private.menuagent[i].menuname!=menuname) next
		} else if (is_record(menuname)) {
		    if (private.menuagent[i].menu!=menuname[1].menu) next
		} else {
		    print 'invalid menu type:',type_name(menuname)
		    next;
		}
	    	if (is_boolean(text)) {
		    # OK, any text
		} else if (is_string(text)) {
		    if (private.menuagent[i].text!=text) next
		} else {
		    print 'invalid text type:',type_name(text)
		    next
		}
		ii := [ii,i];				# OK
	    }
	}
	# print 'indices: ii=',ii;			# temporary
	return ii;
    }


#=========================================================
# Finished. Initialise and return the public interface:

    private.init();
    return public;

};				# closing bracket of menubar
#=========================================================

# mb := test_menubar();		# run test-routine



