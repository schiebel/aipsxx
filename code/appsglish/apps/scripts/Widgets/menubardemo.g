# menubardemo.g: Tool for genarating a script from button presses:
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
# $Id: menubardemo.g,v 19.2 2004/08/25 02:16:19 cvsmgr Exp $

#---------------------------------------------------------	
# J.E.Noordam, june 1998

pragma include once
print 'include menubardemo.g'

include 'textwindow.g'
include 'menubar.g'


#=========================================================
menubardemo := function () {
    private := [=];
    public := [=];

    private.makeitem := [=];		# menu item definition functions
    private.itemheader := [=];
    private.itemfooter := [=];

    private.init := function() {
	wider private;
	private.messagebox := F;	# ...?
	private.tw := F;		# text-window (gui)
	private.gui();			# launch the gui (always)
	return T;
    }


#=========================================================
# Public interface:

    public.agent := create_agent();	# communication

    public.close := function() {
	if (is_record(private.tw)) private.tw.close();
    }
    public.private := function() {
	return private;
    }


#==========================================================
#==========================================================
# 
    private.message := function (text) {
	if (is_record(private.tw)) {
	    private.tw.message(text);		# text-window statusline
	} else {
	    print paste(text);			# print
	}
    }

    private.text := function (text) {
	if (is_record(private.tw)) {
	    private.tw.append(text);		# text-window itself
	} else {
	    print paste(text);			# print
	}
    }



#==========================================================
# Make the menubardemo gui:

     private.gui := function () {
	wider private;
    	private.tw := textwindow('menubar demo')
    	whenever private.tw.agent->message do {
	    # print 'message:',$value;
    	}
    	whenever private.tw.agent->close do {
	    # print 'textwindow close event';
	    val private.messagebox := F;
    	}

	private.menubar := private.tw.menubar();		# is reference

	private.makeviewmenu();
	private.makeitemmenu();
	private.makemiscmenu();

	defrec := private.menubar.defrecinit('overview','help');  
	private.menubar.makemenuitem(defrec, private.show_overview);

	return T;
    }


#-----------------------------------------------------------------

    private.makeviewmenu := function() {
	menu := 'view';

	private.tw.standardmenuitem('print');
	private.tw.standardmenuitem('printcommand');
	private.tw.standardmenuitem('clear');

    	private.menubar.makemenuseparator(menu);
	defrec := private.menubar.defrecinit('make manual',menu);  
	private.menubar.makemenuitem(defrec, private.show_manual);

	names := field_names(private.makeitem);
 	private.showdefmenu (names, menu)
   	return T;
    }

#-----------------------------------------------------------------

    private.makeitemmenu := function() {
	menu := 'menu-items';

	private.makeitem.basic(menu);
	private.makeitem.action(menu);
	private.makeitem.prompthelp(menu);
	private.makeitem.multiparam(menu);

    	private.menubar.makemenuseparator(menu);

	private.makeitem.caution(menu);

	names := "basic action prompthelp caution multiparam";
 	private.showdefmenu (names, menu)
   	return T;
    }


#-----------------------------------------------------------------

    private.makemiscmenu := function() {
	menu := 'misc';

    	private.menubar.makemenu(menu);		# because submenu is the first..!       
	private.makeitem.submenu(menu);

	private.parentitem.standalone(menu);	# use of menubar functionality 
						# given any button agent
	private.parentitem.textwindow(menu);	# use of private.tw.menubar()

	# private.makeitem.standard(menu);
	private.makeitem.separator(menu);

    	private.menubar.makemenuseparator(menu);
    	defrec := private.menubar.defrecinit('defrec fields',menu); 
	private.menubar.makemenuitem(defrec, private.showdefrecfields);

	names := "submenu standalone textwindow standard separator";
 	private.showdefmenu (names, menu)
   	return T;
    }

#-----------------------------------------------------------------
#-----------------------------------------------------------------
#-----------------------------------------------------------------
# General introduction and overview of menubar and its demo:

    private.show_overview := function() {
	s:=' '; n:=0;
	s[n+:=1] := ' '
	s[n+:=1] := 'This demo demonstrates the use and the various features of the menubar.'
	s[n+:=1] := 'The following order is recommended:'
	s[n+:=1] := ' '
	s[n+:=1] := '- basic:       How to specify ans use the simplest possible menu-item.'
	s[n+:=1] := '- action:      Some details about the action (function) that is executed'
	s[n+:=1] := '               when a menu-item is clicked.'
	s[n+:=1] := '- prompt/help: User interaction with parameter values.'
	s[n+:=1] := '- multiparam:  A full demo of how to deal with a multi-parameter action.'
	s[n+:=1] := '- caution:     A way of cautioning the user before executing an action.'
	s[n+:=1] := ' '
	s[n+:=1] := '- submenu:     How to make (a cascade of) sub-menus.'
	s[n+:=1] := '- standalone:  How to attach \'menubar\' items to other button-agents.'
	s[n+:=1] := '- textwindow:  How to specify menubar items in a standard textwindow.'
	s[n+:=1] := ' '
	s[n+:=1] := 'NB: The \'manual\' option in the view-menu will display the text of the various'
	s[n+:=1] := 'demos in a more or less logical fashion in the text-window. This can be printed.'
	s[n+:=1] := ' '
	s[n+:=1] := ' '
	private.tw.clear();			# .....?
	private.tw.append(s);
    }

# Show an entire 'manual', to be printed:

    private.show_manual := function () {
	private.tw.clear();			# ....?
	private.help_menubardemo();		# general introduvtion and overview
	private.showdef_basic();
	private.showdef_action();
	private.showdef_prompthelp();
	private.showdef_caution();
	private.showdef_multiparam();
	private.showdef_submenu();
	private.showdef_standalone();
	private.showdef_textwindow();
    }


#-----------------------------------------------------------------

    private.itemheader.basic := function () {
	s:=' '; n:=0;
	s[n+:=1] := 'Here is how to define the simplest possible menu-item.'
	s[n+:=1] := 'First, a menubar object (record) is needed:'
	s[n+:=1] := '- include \"menubar.g\"'
	s[n+:=1] := '- private.menubar := menubar(frame())'
	s[n+:=1] := 'This produces a gui with a menubar in a frame (try it).'
	s[n+:=1] := 'A simple menu-item can now be defined in the following way:'
	return s;
    }
    private.makeitem.basic := function (menu) {
    	defrec := private.menubar.defrecinit('basic', menu);
    	private.menubar.makemenuitem(defrec, private.showdef_basic);        
    }
    private.showdef_basic := function () {
	private.showitemdef('basic');
    }
    private.itemfooter.basic := function () {
	s:=' '; n:=0;
	s[n+:=1] := 'The menubar function .defrecinit(name, menu) initialises'
	s[n+:=1] := 'an \'item definition record\' (defrec). The fields of defrec'
	s[n+:=1] := 'determine the properties of the menu-item.'
	s[n+:=1] := '(see also item \'defrec-fields\' in the \'misc\' menu)'
	s[n+:=1] := 'The arguments of .defrecinit() are the item name (here: \'basic\')'
	s[n+:=1] := 'and the menu to which the item belongs. The latter can be either'
	s[n+:=1] := 'a string or a Glish/Tk button agent. If it is a string, the item'
	s[n+:=1] := 'will be attached to the menu of that name if it exists already.'
	s[n+:=1] := 'If a menu with that name does not yet exist, it will be created.'
	s[n+:=1] := ' '
	s[n+:=1] := 'The menubar function .makemenuitem(defrec) turns the defrec'
	s[n+:=1] := 'into an item with the specified name in the specified menu.'
	s[n+:=1] := 'Its 2nd argument is a function (with zero or one parameters),'
	s[n+:=1] := 'which is executed whenever the menu-button is clicked. In this example,'
	s[n+:=1] := 'the function \'private.showdef_basic()\' displayed this text.'
	return s;
    }

#-----------------------------------------------------------------

    private.itemheader.submenu := function () {
	s:=' '; n:=0;
	s[n+:=1] := 'A menu-item may also be a sub-menu. The function .makemenu() returns'
	s[n+:=1] := 'a button-agent of type \'menu\', which can be used as the second'
	s[n+:=1] := 'argument in .defrecinit(). Sub-menus may be cascaded.'
	return s;
    }
    private.makeitem.submenu := function (menu) {
    	m := private.menubar.makemenu('submenu', menu);	# should be part of menu...?!       
	separ := T;
    	defrec := private.menubar.defrecinit('show definition', m);
	defrec.action := ref private.showdef_submenu
    	private.menubar.makemenuitem(defrec);        
	separ := T;
    	m1 := private.menubar.makemenu('subsubmenu', m);       
    	private.menubar.makemenu('subsubsubmenu', m1);       
    }

    private.showdef_submenu := function () {
	private.showitemdef('submenu');
    }

#-----------------------------------------------------------------

    private.itemheader.standalone := function () {
	s:=' '; n:=0;
	s[n+:=1] := 'Menu-items with the \'menubar\' features can be attached'
	s[n+:=1] := 'to any menu-button (Glish/Tk agent) in any other gui:'
	return s;
    }
    private.parentitem.standalone := function (menu) {
    	defrec := private.menubar.defrecinit('standalone', menu);
    	private.menubar.makemenuitem(defrec, private.makeitem.standalone);        
    }
    private.makeitem.standalone := function () {
	include 'menubar.g';
	menubar_object := menubar();
	global gui_frame := frame(title='some gui-frame');
	menubutton_agent := button(gui_frame,'menu-button of some gui', type='menu');
	separ := T;		
	b1 := button(menubutton_agent,'normal item 1')
	b2 := button(menubutton_agent,'normal item 2')
	separ := T;		
    	defrec := menubar_object.defrecinit('menubar-type item 1', menubutton_agent);
    	menubar_object.makemenuitem(defrec);        
    	defrec := menubar_object.defrecinit('menubar-type item 2', menubutton_agent);
    	menubar_object.makemenuitem(defrec);        
    	defrec := menubar_object.defrecinit('show definition', menubutton_agent);
    	menubar_object.makemenuitem(defrec, private.showdef_standalone);        
	separ := T;		
	b3 := button(menubutton_agent,'normal item 3')
	b4 := button(menubutton_agent,'etc')
    }

    private.showdef_standalone := function () {
	private.showitemdef('standalone');
    }
    private.itemfooter.standalone := function () {
	s:=' '; n:=0;
	s[n+:=1] := 'In this example, it is assumed that a menu-button (type=\'menu\') has been'
	s[n+:=1] := 'defined in some gui_frame. Buttons b1,b2,b3,b4 are \'normal\' menu-items,'
	s[n+:=1] := 'without the features of \'menubar-type\' items.'
	s[n+:=1] := ' ';
	s[n+:=1] := 'NB: Obviously, menubar.g must have been included, and a menubar'
	s[n+:=1] := '    object must be created without any arguments.';
	return s;
    }


#-----------------------------------------------------------------

    private.itemheader.separator := function () {
	s:=' '; n:=0;
	s[n+:=1] := 'Separator menu-items'
	return s;
    }
    private.makeitem.separator := function () {
    	defrec := private.menubar.defrecinit('separator', menu);
    	private.menubar.makemenuitem(defrec, private.makeitem.separator);        
    }

    private.showdef_separator := function () {
	private.showitemdef('separator');
    }


#-----------------------------------------------------------------

    private.itemheader.caution := function () {
	s:=' '; n:=0;
	s[n+:=1] := 'If defrec.caution is a string, the user gets an extra'
	s[n+:=1] := 'chance to continue an action, or to cancel it.'
	return s;
    }
    private.makeitem.caution := function (menu) {
    	defrec := private.menubar.defrecinit('caution',menu);
    	defrec.caution := 'are you sure?';
    	defrec.action := ref function() {print paste('done');} 
    	private.menubar.makemenuitem(defrec); 
    
    }

    private.showdef_caution := function () {
	private.showitemdef('caution');
    }


#-----------------------------------------------------------------

    private.itemheader.action := function () {
	s:=' '; n:=0;
	s[n+:=1] := 'Whenever a menu-item is clicked, some action is executed.'
	s[n+:=1] := 'This action (a Glish function) may be supplied in two ways:'
	s[n+:=1] := '- by setting defrec.action := ref <function-name>'
	s[n+:=1] := '- by suppying the function-name as 2nd argument to .makemenuitem().'
	s[n+:=1] := 'NB: The function-name should NOT be followed by parentheses (),'
	s[n+:=1] := '  because that would refer to a function VALUE rather than a function.'
	s[n+:=1] := 'If no action is specified, menubar executes a default-action,'
	s[n+:=1] := '  which shows the value(s) of the action parameter(s).'
	return s;
    }
    private.makeitem.action := function (menu) {
    	defrec := private.menubar.defrecinit('action',menu); 
    	defrec.action := ref private.showdef_action;
    	private.menubar.makemenuitem(defrec); 
    }
    private.showdef_action := function () {
	private.showitemdef('action');
    }
    private.itemfooter.action := function () {
	s:=' '; n:=0;
	s[n+:=1] := 'A central feature of the menubar is the user-interaction with the' 
	s[n+:=1] := '  parameter values that are passed to the supplied action-function.' 
	s[n+:=1] := 'A distinction must be made between the number of arguments of this' 
	s[n+:=1] := '  function (zero or one), and the number of actual parameter-values'
	s[n+:=1] := '  that the action requires. If the number of parameters is more than one,' 
	s[n+:=1] := '  they are passed to the action as named fields of a single record-argument.' 
	s[n+:=1] := ' ' 
	s[n+:=1] := 'Parameter-attributes are specified by means of defrec:' 
 	s[n+:=1] := '- defrec.paramchoice gives a choice of pre-defined parameter-values' 
	s[n+:=1] := '    which can be selected by the user by means of mouse-clicks.'
 	s[n+:=1] := '    The first value of .paramchoice is taken as the default.'
	s[n+:=1] := '- Other parameter-specific attributes are:'
	s[n+:=1] := '    - .paramhelp (string or function): invoked by the user.' 
	s[n+:=1] := '    - .paramtest (function): invoked by the user.' 
	s[n+:=1] := '    - .paramcheck (function): invoked automatically.' 
	s[n+:=1] := '    - .paramrange (vector: [vmin,vmax]): invoked automatically.' 
	s[n+:=1] := '    - .paramunit (string): just information at the moment.' 
	s[n+:=1] := ' ' 
	s[n+:=1] := '- If the action only requires one parameter, it may be specified' 
	s[n+:=1] := '    directly as scalar or vector value(s) of .paramchoice.' 
	s[n+:=1] := '- A multi-parameter record argument is specified by specifiying'
	s[n+:=1] := '    the various parameter attributes as named fields of defrec.param<...>' 
	s[n+:=1] := '- NB: If there is one parameter (even as a named record-field!) it is' 
	s[n+:=1] := '    passed to the action as a scalar/vector argument.' 
	s[n+:=1] := ' ' 
	s[n+:=1] := 'Some slightly more advanced features:' 
	s[n+:=1] := '- .paramchoice may also be a function (with zero arguments, of course),' 
	s[n+:=1] := '    which returns a (vector or record of) values for the choice-menu.' 
	s[n+:=1] := '    Since this function is called anew each time, the offered choice' 
	s[n+:=1] := '    in parameter values is up-to-date and may be context-sensitive!' 
	s[n+:=1] := '- The shape (scalar/vector/..) of a parameter is determined by'
	s[n+:=1] := '    specifying defrec.shape. The default is \'scalar\'.' 
	s[n+:=1] := '- If .paramchoice for a parameter is a record, its fields may have different' 
	s[n+:=1] := '    data-types (e.g. double, boolean, string etc).'
	s[n+:=1] := '- If .paramchoiceonly is specified (as T), the parameter value cannot be' 
	s[n+:=1] := '    edited by the user, but only selected from the choice-menu.' 
	s[n+:=1] := ' ' 
	s[n+:=1] := 'The user is urged to play with the examples provided in this demo!' 
	return s;
    }

#-----------------------------------------------------------------

    private.itemheader.prompthelp := function () {
	s:=' '; n:=0;
	s[n+:=1] := 'If defrec.prompt is specified (as a string), a panel will pop-up to'
	s[n+:=1] := 'allow the user to modify parameter values.'
	s[n+:=1] := ' '
	s[n+:=1] := 'defrec.help'
	s[n+:=1] := 'defrec.test'
	s[n+:=1] := 'defrec.auxinfo'
	s[n+:=1] := ' '
	s[n+:=1] := 'defrec.paramchoice'
	s[n+:=1] := 'defrec.paramhelp'
	s[n+:=1] := 'defrec.paramtest'
	s[n+:=1] := 'defrec.paramcheck'
	return s;
    }
    private.makeitem.prompthelp := function (menu) {
    	defrec := private.menubar.defrecinit('prompthelp',menu);
    	defrec.prompthelp := 'this is the prompthelp string';
    	private.menubar.makemenuitem(defrec); 
    }

    private.showdef_prompthelp := function () {
	private.showitemdef('prompthelp');
    }

#-----------------------------------------------------------------

    private.showdefrecfields := function () {
	s:=' '; n:=0;
	s[n+:=1] := ' '
	s[n+:=1] := 'An item definition record (defrec) has the following fields:'
	s[n+:=1] := ' '
	s[n+:=1] := '- defrec.text            (string) item name, i.e. text on button'
	s[n+:=1] := '- defrec.menu            (string or agent)'
	s[n+:=1] := '- defrec.action          (function)'
	s[n+:=1] := '- defrec.help            (string or function)'
	s[n+:=1] := '- defrec.test            (function, one argument)'
	s[n+:=1] := '- defrec.auxinfo         (string or function or record)'
	s[n+:=1] := '- defrec.prompt          (string)'
	s[n+:=1] := '- defrec.caution         (string)'
	s[n+:=1] := '- defrec.disabled        (boolean)'
	s[n+:=1] := '- defrec.tick            (boolean)'
	s[n+:=1] := ' '
	s[n+:=1] := '- defrec.paramchoice     (record or vector)'
	s[n+:=1] := '- defrec.paramchoiceonly (record or boolean)'
	s[n+:=1] := '- defrec.paramshape      (string) scalar or vector'
	s[n+:=1] := '- defrec.paramhelp       (record or function/string)'
	s[n+:=1] := '- defrec.paramtest       (record or function)'
	s[n+:=1] := '- defrec.paramcheck      (record or function)'
	s[n+:=1] := '- defrec.paramrange      (record or vector[2])'
	s[n+:=1] := '- defrec.paramhide       (record or boolean)'
	s[n+:=1] := '- defrec.paramunit       (record or string)'

	s[n+:=1] := ' '
	private.tw.append(s);
	return T;
    }


#-----------------------------------------------------------------

    private.itemheader.multiparam := function () {
	s:=' '; n:=0;
	s[n+:=1] := 'Demo of various parameter specification options:'
	return s;
    }
    private.makeitem.multiparam := function (menu) {
    	defrec := private.menubar.defrecinit('multiparam',menu); 

        defrec.prompt := 'this is the prompt-string';
        defrec.help := ref private.help_multiparam;	
        defrec.test := ref private.test_multiparam;	
        text := paste('auxiliary info-string, labelled whatever');	
        defrec.auxinfo.whatever := text;	
        defrec.auxinfo.show_definition := ref private.showdef_multiparam;	

	separ := T;
        defrec.paramchoice.ss := 3.142828;
        defrec.paramhelp.ss := 'demonstrates: scalar value (default)';

	separ := T;
        defrec.paramchoice.cc := [-1:3]*0.5;
        defrec.paramhelp.cc := 'demonstrates: choice (editable too)';

	separ := T;
        defrec.paramchoice.dd := ref private.choice_function;
        defrec.paramhelp.dd := 'demonstrates: use of a choice-function';

	separ := T;
        defrec.paramchoice.co := [1:4];
        defrec.paramchoiceonly.co := T;
        defrec.paramhelp.co := 'demonstrates: choiceonly (not editable)';

	separ := T;
        defrec.paramchoice.hh := 'this is a hidden parameter';
        defrec.paramhide.hh := T;
        defrec.paramhelp.hh := 'demonstrates: hide (not editable)';

	separ := T;
        defrec.paramchoice.mt := [=];
        defrec.paramchoice.mt[1] := [-1:3]/2;
        defrec.paramchoice.mt[2] := ["aa bb cc dd"];
        defrec.paramhelp.mt := 'demonstrates: multi-type choice';

	separ := T;
        defrec.paramshape.vv := 'vector';
        defrec.paramchoice.vv := [=];
        defrec.paramchoice.vv[1] := [-1:3]*0.5;
        defrec.paramchoice.vv[2] := [-1:3];
        defrec.paramchoice.vv[3] := complex([-1:3]);
        defrec.paramchoice.vv[4] := "a bb ccc dddd";
	text := 'the value is assumed to be a vector' 
        defrec.paramhelp.vv := text;

	separ := T;
    	private.menubar.makemenuitem(defrec);    
    }

    private.choice_function := function () {
	v := random(3);
	return v;
    }
    private.showdef_multiparam := function () {
	private.showitemdef('multiparam');
    }
    private.test_multiparam := function (param=F) {
	print 'test_multiparam: param=',param;		# temporary
    }
    private.help_multiparam := function () {
	s:=' '; n:=0;
	s[n+:=1] := 'Each of the various parameters demonstrates'
	s[n+:=1] := 'one or more parameter-specification options:'
	s[n+:=1] := '- ss: scalar value (default)'
	s[n+:=1] := '- cc: choice (editable too)'
	s[n+:=1] := '- dd: use of a choice-function'
	s[n+:=1] := '- co: choiceonly (not editable)'
	s[n+:=1] := '- hh: hide (not editable)'
	s[n+:=1] := '- mt: multi-type choice'
	s[n+:=1] := '- vv: vector value'
	return s;
    }


#-----------------------------------------------------------------

    private.makeitem.separ := function (menu) {
    	private.menubar.makemenuseparator(menu);        # separator	 
    }

#-----------------------------------------------------------------


#-----------------------------------------------------------------

    private.makeitem.newmenu := function (menu) {
    	private.menubar.makemenu('newmenu');         
    }

#-----------------------------------------------------------------

#-----------------------------------------------------------------
#-----------------------------------------------------------------
# Standard menu items:

#-----------------------------------------------------------------

    private.itemheader.textwindow := function () {
	s:=' '; n:=0;
	s[n+:=1] := ' '
	s[n+:=1] := ' '
	s[n+:=1] := ' '
	s[n+:=1] := ' '
	return s;
    }
    private.parentitem.textwindow := function (menu) {
    	defrec := private.menubar.defrecinit('textwindow', menu);
    	private.menubar.makemenuitem(defrec, private.makeitem.textwindow);        
    }


    public.testfunc := function () {
    	return as_string(private.makeitem.textwindow);
    }

    private.makeitem.textwindow := function () {
	wider private;
	include 'textwindow.g';
	private.textwindow := textwindow();
	separ := T;
    	item :=private.textwindow.standardmenuitem('open');    
    	item.action := function() {print 'this is a user-defined open-function'};
    	item := private.textwindow.standardmenuitem('save');    
    	item.action := function() {print 'this is a user-defined save-function'};
    	private.textwindow.standardmenuitem('dismiss');    
	separ := T;
    	private.textwindow.standardmenuitem('clear');    
    	private.textwindow.standardmenuitem('print');    
    	private.textwindow.standardmenuitem('printcommand');    
	menu := 'view'
    	private.textwindow.menubar().makemenuseparator(menu);	 
    	defrec := private.textwindow.menubar().defrecinit('show definition',menu);    
    	private.textwindow.menubar().makemenuitem(defrec, private.showdef_textwindow);    
	separ := T;
	menu := 'usermenu'
    	defrec := private.textwindow.menubar().defrecinit('item 1',menu);    
	defrec.action := ref function() {print 'this is the action of item 1'}    
    	private.textwindow.menubar().makemenuitem(defrec);    
    	defrec := private.textwindow.menubar().defrecinit('item 2',menu);    
	defrec.action := ref function() {print 'this is the action of item 2'}    
    	private.textwindow.menubar().makemenuitem(defrec);    
    	private.textwindow.menubar().makemenuseparator(menu);	 
    	defrec := private.textwindow.menubar().defrecinit('item 3',menu);
	defrec.action := ref function() {
	    private.textwindow.append('this is the action of item 3')
	}    
    	private.textwindow.menubar().makemenuitem(defrec);    
    }

    private.showdef_textwindow := function () {
	private.showitemdef('textwindow');
    }
    private.itemfooter.textwindow := function () {
	s:=' '; n:=0;
	s[n+:=1] := ' '
	s[n+:=1] := ' '
	s[n+:=1] := ' '
	return s;
    }




#-----------------------------------------------------------------
#-----------------------------------------------------------------
#-----------------------------------------------------------------
#-----------------------------------------------------------------
# Display the definition-function of the specified menu-item:

    private.showitemdef := function (fname) {
	private.showheader(fname);
	fs := as_string(private.makeitem[fname]);
	ss := split(fs,'\n');			# split into lines
	for (s in ss) {
	    # print spaste(len(split(s,'')),': ',s);
	    if (s ~ m/^{/) next;		# if 1st char is {
	    if (s ~ m/^function/) next;		# if line starts with 'function'
	    s := s ~ s/^{/..../			# replace '{' at start of line with ....
	    if (s ~ m/^\(separ/) s := ' ';	# if line starts with '(separ'
	    s := s ~ s/;//g			# remove all ';' 
	    s := s ~ s/}$//			# remove '}' at end of line 
	    s := s ~ s/\[\(/\[/			# replace '[(' with '[' 
	    s := s ~ s/\)\]/\]/			# replace ')]' with ']' 
	    if (s ~ m/^\(/) {			# if 1st char is '(' 
	    	s := s ~ s/^\(//		# remove '(' at start of line 
	    	s := s ~ s/\)$//		# remove ')' at end of line 
	    }
	    s := spaste('    ',s);		# margin 
	    private.tw.append(s);
	}
	private.showfooter(fname);
    }



    private.showheader := function (fname) {
	private.tw.append(' ');
	private.tw.append('************************************************');
	private.tw.append(' ');
	if (has_field(private.itemheader,fname)) {
	    s := private.itemheader[fname]();
	} else {
	    s := paste(' ',fname,':');
	}
	private.tw.append(s);
	private.tw.append(' ');
    }

    private.showfooter := function (fname) {
	private.tw.append(' ');
	if (has_field(private.itemfooter,fname)) {
	    s := private.itemfooter[fname]();
	} else {
	    s := paste(' ');
	}
	private.tw.append(s);
	private.tw.append(' ');
    }


# Make a menu for showing specified fields (functions) of private.makeitem:

    private.showdefmenu := function (names, menu) {
    	private.menubar.makemenuseparator(menu);
	if (is_boolean(names)) return F;		# none specified
    	defrec := private.menubar.defrecinit('show definition',menu);
	defrec.paramchoice := names;
    	private.menubar.makemenuitem(defrec, private.showitemdef);
	return T;
    }


#=========================================================
# Finished. Initialise and return the public interface:

    private.init();
    return public;			# reference

};		# closing bracket of make_mans_aux
#=========================================================


mbd := menubardemo();			# start up the demo
# fs := mbd.testfunc();		# testing: string version of a function
# fs := split(fs,'\n');		# split














