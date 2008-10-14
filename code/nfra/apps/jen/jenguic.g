# jenguic.g: Some gui-components used in JEN modules

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
# $Id: jenguic.g,v 19.0 2003/07/16 03:38:32 aips2adm Exp $

#---------------------------------------------------------

pragma include once
# print 'include jenguic.g  h01sep99';

include 'profiler.g';		        # used for profiling etc
include 'guicomponents.g';			# messagebox

#=====================================================================
#=====================================================================
jenguic := function () {
    private := [=];
    public := [=];


# Initialise the object (called at the end of this constructor):

    private.init := function () {
	wider private;

	private.prof := profiler('jenplot');    # profiler object
	public.clear_buttons();

	private.trace := F;
	private.message := F;			# see .control()

	private.echo := client ('echo_client');	# make client
	private.timer := client ('timer');	# make client

	return T;
    }

#==========================================================================
# Public interface:
#==========================================================================

    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('jenguic event:',$name,$value);
	# print s;
    }
    whenever public.agent->message do {
	print 'jenguic message-event:',$value;
    }

    public.done := function (dummy=F) {
	return private.done();
    }

    public.prof := function () {
	return ref private.prof;		# reference to profiler data functions
    }
    public.trace := function (tf=F) {
	return private.prof.trace(tf);	        # make the profiler trace
    }

    public.private := function(copy=F) {	# access to private part
	if (copy) return private;		# return a copy
	return ref private;			# return a reference
    }
    public.inspect := function (name=F) {	# Inspect various things
	# return private.inspect(name);
    }



#========================================================================
# General functions:
#========================================================================

    private.done := function (dummy=F) {
	wider private;
	public.clear_buttons();
	public.agent -> done();
	# private.prof.show_profile();            # show profiler result
	# private.prof.show_obsolete(full=T);     # record of obsolete calls
	return T;
    }

# Helper function: delay for given nr of seconds: 

    public.delay := function(sec=0.1, txt=' ', trace=F) {
	wider private;
	if (!has_field(private,'echo')) private.echo := client ('echo_client');
	if (!has_field(private,'timer')) private.timer := client ('timer');
	if (trace) print txt,': start delay: sec=',sec;
	private.echo -> echo();				# allow events
	if (trace) print txt,': delay: await echo....';
	await private.echo -> echo;			# wait
	private.timer -> interval(sec);
	if (trace) print txt,':delay: await timer....';
	await private.timer -> ready;
	private.timer -> interval(0);			# disable timer
	if (trace) print txt,': delay: finished';
	return T;
    }

#------------------------------------------------------------------------------
# Display formatted information in a message-box:
# NB: This function is also an extra check of the inputs of messagebox(),
#     which will crash Glish if the text-string is longer than maxcols chars...!
# NB: Conclusion(): Standard AIPS++ functions are not robust enough....!? 


    public.boxmessage := function (text=F, title=F, clear=T, trace=F,
				   background='white',
				   maxrows=40, maxcols=80) {
	s := paste('jenguic.boxmessage(text=',type_name(text),'):');
	if (trace) print s,'  title=',type_name(title), title;
	if (is_string(text)) {
	    nrows := ncols := ncmax := nlines := 0;
	    for (s1 in split(text,'\n')) {
		nlines +:= 1;
		nchars := len(split(s1,''));
		ncmax := max(nchars,ncmax);
		if (trace) print nlines,nchars,':',s1;
	    }
	    nrows := max(5,nlines+5);    
	    nrows := min(nrows,maxrows);    
	    ncols := max(10,ncmax+1);    
	    ncols := min(ncols,maxcols);    
	    if (trace) {
		s := spaste('nrows=',nrows,' (nlines=',nlines,')');
		s := spaste(s,' ncols=',ncols,' (ncmax=',ncmax,')');
		print s;
	    }
	    if (is_boolean(title)) title := 'messagebox';
	    messagebox(paste(text), title=paste(title),
		       background=background,
		       maxrows=nrows, maxcols=ncols);
	}
	return T;
    }

# NB: function (val msg, val background = white, val title =  ,
#     val font = spaste(-adobe-courier-medium-r-normal--, 12, -*),
#     val maxrows = 5, val maxcols = 80) {


#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
# Define a named control button of the given type, and attach a callback function:
# NB: The argument 'name' is the argument passed to the callback function.

    public.define_button := function (ref bagent, name=F, caption=F, 
				      btype=F, ref callback=F, 
				      width=0, height=1,
				      background='lightgrey', 
				      foreground='black',
				      disabled=F, trace=F) {
	wider private;
	s := paste('jenguic.define_button (',name,btype,'):');
	if (trace) print s;
	if (!is_agent(bagent)) {
	    print s,'no agent provided';
	    return F;
	}

	nc := len(private.ctrl);			# current nr
	private.ctrl[nc+:=1] := [=];			# create a new one
	private.ctrl[nc].name := name;			# input argument
	private.ctrl[nc].btype := btype;		# input argument
	private.ctrl[nc].callback := callback;		# input argument
	private.ctrl[nc].width := width;	        # input argument
	private.ctrl[nc].height := height;	        # input argument
	private.ctrl[nc].foreground := foreground;	# input argument
	private.ctrl[nc].background := background;	# input argument
	private.ctrl[nc].button := F;			# see below

	if (is_boolean(caption)) caption := name;	# default

	if (is_boolean(btype)) {			# plain button
	    private.ctrl[nc].button := button(bagent, caption, value=nc,
					      background=background,
					      foreground=foreground,
					      width=width, height=height,
					      disabled=disabled);
	} else if (btype=='space') {			# spacer
	    private.ctrl[nc].button := frame(bagent, height=5);
	    return T;					# no 'whenever' needed
	} else if (btype=='menusep') {			# menu separator
	    private.ctrl[nc].button := button(bagent,' ');
	    return T;					# no 'whenever' needed
	} else if (btype=='menu') {
	    private.ctrl[nc].button := button(bagent, caption, type=btype);
	    return ref private.ctrl[nc].button;	# reference to menu button
	} else if (btype=='check') {			# check-button
	    private.ctrl[nc].button := button(bagent, caption, value=nc, 
					      type=btype);
	    # private.ctrl[nc].button -> state(private.plov[name]);
	} else if (btype=='radio') {			# radio-button
	    private.ctrl[nc].button := button(bagent, caption, value=nc, 
					      type=btype, group=bagent);
	} else {					# ....?
	    print s,'button-type not recognised:',btype;
	    private.ctrl[nc].btype := paste(btype,'(not recognised!)');
	    private.ctrl[nc].callback := F;		# clean up (?)
	    return F;
	}

	# Check for any name-clashes (may cause problems with get_ctrl() etc):
	for (i in ind(private.ctrl)) {
	    if (i==nc) next;                            # ignore the last
	    if (private.ctrl[i].name==name) {
		s := paste(i,'jenguic.define_button: name-clash for:');
		print s := paste(s,name,' btype=',btype);
	    }
	}

	# Set up the whenever event-catcher:
	whenever private.ctrl[nc].button -> press do {
	    i := $value;
	    name := private.ctrl[i].name;
	    s := paste('+++ ctrl_button pressed:',i,name);
	    r := private.ctrl[i].callback (name);	# argument may be: (dummy=F)
	    # print s := paste(s,'result ->',r);
	    # private.pgw.message(s);
	}
	return T;
    }

# Helper functions to get/set the state of a group of named gui buttons.
# The names are the (boolean) fields of a record.

    public.button_state := function (ref button=[=], set=T, trace=F) {
	if (trace) print 'button_state: set=',set,len(button);
	for (name in field_names(button)) {
	    b := public.get_button(name);
	    if (!is_agent(b)) {
		print 'jenguic.button_state: not an agent:',name;
		next;                         # agent not found
	    }
	    before := button[name];           # record field value before
	    if (set) b -> state(before);      # set the state, if required
	    after := (b -> state());          # get the (new) state
	    button[name] := after;            # update the record field
	    s := paste('jenguic.button_state:',set,name,':',before,'->',after);
	    if (trace) print s;
	}
	return T;
    }

# Helper functions to get/set the color of a group of named gui buttons.
# The names are the (boolean) fields of a record.

    public.button_color := function (ref button=[=], set=T, trace=T) {
	if (trace) print 'button_color: set=',set,len(button);
	for (name in field_names(button)) {
	    b := public.get_button(name);
	    if (!is_agent(b)) {
		print 'jenguic.button_color: not an agent:',name;
		next;                         # agent not found
	    }
	    before := (b -> background());    # get current color
	    color := 'lightgrey';             # 
	    if (is_string(button[name])) color := button[name];
	    if (set) b -> background(color);  # set the color, if required
	    after := (b -> background());     # get the (new) color
	    button[name] := after;            # update the record field
	    s := paste('jenguic.button_color:',set,name,':',before,'->',after);
	    if (trace) print s;
	}
	return T;
    }

# Helper function (should go to jenguic):

    public.add_menu_help := function (ref bmenu, root=F, ref callback=F) {
	public.define_button(bmenu, btype='menusep');
	if (is_boolean(callback)) {
	    callback := private.help_not_implemented();
	}
	public.define_button(bmenu, spaste(root,'_help'), 
			     caption='help', callback=callback);
	return T;
    }

    private.help_not_implemented := function () {
	print 'menu help not (yet) implemented';
	return T;
    }


#-------------------------------------------------------------------------------

    public.clear_buttons := function () {
	wider private;
	if (has_field(private,'ctrl')) {          # if ctrl exists already
	    for (i in ind(private.ctrl)) {
		if (is_agent(private.ctrl[i].button)) {
		    deactivate whenever_stmts(private.ctrl[i].button).stmt;
		}
	    }
	}
	private.ctrl := [=];			# record of buttons etc
	return T;
    }

#---------------------------------------------------------------------------------
# Helper function: get a reference to the control button with the specified name:

    public.get_button := function (name=F, trace=F) {
	for (i in ind(private.ctrl)) {
	    if (private.ctrl[i].name==name) {
		if (trace) {
		    print s := paste('jenguic.get_button: found:',name,'index=',i);
		}
		return ref private.ctrl[i].button;	# return reference
	    }
	}
	print s := paste('jenguic.get_button: name not recognised:',name);
	return F;
    }

#---------------------------------------------------------------------------------
# Helper function: get a reference to the control button with the specified name:

    public.get_ctrl := function (name=F, trace=F) {
	for (i in ind(private.ctrl)) {
	    if (private.ctrl[i].name==name) {
		if (trace) {
		    print s := paste('jenguic.get_ctrl: found:',name,'index=',i);
		}
		return ref private.ctrl[i];	        # return reference
	    }
	}
	print s := paste('jenguic.get_button: name not recognised:',name);
	return F;
    }

#---------------------------------------------------------------------------------
# Helper function: find the nr of the ctrl-button with a given characteristic:

    private.get_ctrl_index := function (name=F, trace=F) {
	for (i in ind(private.ctrl)) {
	    if (private.ctrl[i].name==name) {
		if (trace) {
		    print s := paste('jenguic.get_ctrl_index: found:',name,'index=',i);
		}
		return i;		         	# return index
	    }
	}
	print s := paste('jenguic.get_ctrl_index: not recognised:',name);
	return F;
    }


# Experimental (use popup-help instead):

	# private.ctrl[nc].button->bind('<Enter>','enter');
	# private.ctrl[nc].button->bind('<Leave>','exit');
	# whenever private.ctrl[nc].button->enter do {
	#     nc := $value;
	#     private.popupframe := frame(tlead=private.ctrl[nc].button, 
	# 				tpos='se', background='blue');
	# }
	# whenever private.ctrl[nc].button->exit do {
	#     val private.popupframe := F;		# delete again
	# }	

#---------------------------------------------------------------------------
# Attach a user callback function to the specified menu-button:

    public.addcallback := function (menu, caption=F, ref callback=F) {
	# print 'addcallback:menu=',menu,':',caption;
	for (i in ind(private.ctrl)) {
	    # print 'ctrl',i,':',private.ctrl[i].btype,'   ',private.ctrl[i].name;
	    if (private.ctrl[i].btype == 'menu' && 
		private.ctrl[i].name == menu) {
		public.define_button (private.ctrl[i].button, menu, caption,
				       callback=callback);
		return T;				# OK, escape
	    }
	}
	# print 'addcallback: menu not found:',menu,len(private.ctrl);
	return F;
    }

    private.external_item_select := F;    
    public.add_external_item_select := function (caption='external',
						 ref callback=F) {
	wider private;
	private.external_item_select := callback;	# keep for later
	public.addcallback ('select', caption, private.external_select);
	return T;
    }

    private.external_select := function (dummy=F) {
	# print 'external_select:';
    }

#=======================================================================
# Special: Application control button in given frame:

    public.appctrl := function (ref bframe=F,	
				help='appctrl help-text',
				title='appctrl help') {
	acb := [=];                             # control record
	acb.trace := T;                         # switch
	acb.switch := [=];                      # status record
	acb.switch.enabled := F;                # switch
	acb.switch.onestep := F;                # switch
	acb.switch.continue := T;               # switch
	acb.switch.cancel := F;                 # switch
	acb.switch.blinkon := T;                # switch
	acb.agent := create_agent();            # outside world
	whenever acb.agent -> * do {
	    if (acb.trace) print 'acb event:',$name,$value;
	}
	acb.help := function (help=F, title=F) {
	    wider acb;
	    if (is_string(help)) acb.helptext := help;          
	    if (is_string(title)) acb.helptitle := title; 
	}
	acb.help (help=help, title=title);      # input args
	acb.status := function (name=F) {
	    wider acb;
	    if (is_boolean(name)) {
		if (acb.trace) print 'acb.status()->',acb.switch; 
		return acb.switch;
	    } else if (has_field(acb.switch,name)) {
		r := acb.switch[name];
		if (acb.trace) print 'acb.status(',name,')->',r; 
		return r; 
	    } else {
		print 'acb.status(): not recognised:',name;
		return F;
	    }
	}
	acb.suspend := function (enforce=F) {
	    wider acb;
	    if (enforce) acb.switch.continue := F;
	    private.appctrl_suspend(acb);
	    # acb.allow_events();
	}
	acb.continue := function (caption='continue') {
	    wider acb;
	    acb.switch.suspended := F;       # escape if suspended
	    acb.switch.continue := T;
	    acb.switch.onestep := F;
	    acb.button.menu -> text(paste(caption));
	    acb.button.menu -> background('green');
	    acb.allow_events();
	}
	acb.onestep := function (caption='onestep') {
	    wider acb;
	    acb.switch.suspended := F;       # escape if suspended
	    acb.switch.continue := F;
	    acb.switch.onestep := T;
	    acb.button.menu -> text(paste(caption));
	    acb.button.menu -> background('blue');
	    acb.allow_events();
	}
	acb.cancel := function (caption='cancel') {
	    wider acb;
	    acb.switch.cancel := T;
	    acb.button.menu -> text(paste(caption));
	    acb.agent -> cancel();      # outside world
	    acb.disable();
	    acb.allow_events();
	}
	acb.enable := function (caption='enabled') {
	    wider acb;
	    print 'acb.enable()';
	    acb.switch.enabled := T;
	    acb.switch.suspended := F;
	    acb.switch.continue := F;
	    acb.switch.onestep := F;
	    acb.switch.cancel := F;
	    acb.button.menu -> enable();
	    acb.button.menu -> background('yellow');
	    acb.button.menu -> text(paste(caption)); 
	    acb.button.suspend -> text('suspend');
	    acb.allow_events();
	}
	acb.disable := function (caption='disabled') {
	    wider acb;
	    acb.switch.enabled := F;
	    acb.switch.suspended := F;             # ....?
	    acb.button.menu -> disable();         
	    acb.button.menu -> background('grey');
	    acb.button.menu -> text(paste(caption)); 
	    acb.allow_events();
	}
	acb.allow_events := function(origin=' ') {
	    acb.client.echo -> echo();   
	    s := paste('acb.allow_events(',origin,'):');
	    # print paste(s,' awaiting echo.....');
	    await acb.client.echo -> echo;            # essential!
	}
	acb.done := function () {             # needed?
	    wider acb;
	    acb.cancel();
	    # disable all whenevers!
	    val acb.menu := F;
	}

	acb.client := [=];
	acb.client.echo := client ('echo_client'); 
	whenever acb.client.echo -> echo do {
	    if (acb.trace) print 'acb.client.echo: echo event';
	}
	acb.client.timer := client ('timer');  
	whenever acb.client.timer -> ready do {
	    acb.client.timer -> interval(0);	 # disable timer
	    if (acb.trace) print 'acb timer ready and disabled'; 
	    if (acb.switch.cancel) {
		if (acb.trace) print 'cancel: disable';
		acb.disable();
	    }
	    acb.switch.blinkon := !acb.switch.blinkon;    # toggle
	    if (acb.switch.blinkon) {
		acb.button.menu -> background('yellow');
	    } else {
		acb.button.menu -> background('grey');
	    }
	}

	acb.button := [=];
	acb.button.menu := button(bframe,'appctrl', type='menu');
	acb.button.suspend := button(acb.button.menu, 'suspend',
				background='yellow');
	acb.button.continue := button(acb.button.menu, 'continue >>',
				 background='green');
	acb.button.step := button(acb.button.menu, 'step >|',
			     background='blue');
	acb.help := button(acb.button.menu, 'help');
	acb.button.cancel0 := button(acb.button.menu, 'cancel',
				type='menu', background='red');
	acb.button.cancel := button(acb.button.cancel0, 'cancel',
			       background='red');
	
	whenever acb.button.suspend -> press do {
	    acb.suspend(enforce=T);
       	}
	whenever acb.button.step -> press do {acb.onestep();}
	whenever acb.button.continue -> press do {acb.continue();}
	whenever acb.button.cancel -> press do {acb.cancel();}
	whenever acb.help -> press do {
	    public.boxmessage(acb.helptext, 
			      title=acb.helptitle);
	}
	acb.disable();                          # initial state
	return ref acb;
    } 

# Helper function: eternal loop:

    private.appctrl_suspend := function (ref acb=[=]) {
        if (!acb.switch.enabled) {
	    s := 'appctrl_suspend(): not active';
	    if (acb.trace) print s;
	    return F;
        } else if (acb.switch.suspended) {
	    s := 'appctrl_suspend(): already suspended';
	    if (acb.trace) print s;
	    return F;
        } else if (acb.switch.onestep) {    # before (acb.switch.continue)
	    s := 'appctrl_suspend(): onestep=T (suspend)';
	    if (acb.trace) print s;
	    acb.switch.onestep := F;           # reset
        } else if (acb.switch.continue) {
	    s := 'appctrl_suspend(): continue=T (not suspended)';
	    if (acb.trace) print s;
	    return F;
	}
	if (acb.trace) print '\n appctrl_suspend():\n';

	acb.button.suspend -> text('suspended');
	acb.button.suspend -> disable();         
	acb.button.menu -> text('suspended');
	count := 0;
	acb.switch.suspended := T;             # reset elsewhere
	while (acb.switch.suspended) {
	    count +:= 1;
	    acb.allow_events();
	    acb.client.timer -> interval(0.5);      # sec
	    await acb.client.timer -> ready;        # essential
	}
	if (acb.trace) print 'appctrl_suspend(): escape';
	acb.button.suspend -> text('suspend');
	acb.button.suspend -> enable();         
	acb.switch.onestep := F;               # reset
	return T;
    }


#=======================================================================
# Finished. Initialise and return the public interface:

    private.init();				# initialise
    return ref public;				# ref?

};				# closing bracket of jenplot
#=======================================================================


#=========================================================
test_jenguic := function () {
    private := [=];
    public := [=];
    print '\n\n\n\n ******** test_jenguic';
    global jng;
    jng := jenguic();
    print '****************************************';
    print 'test_jenguic: created global symbol: jng';
    print '****************************************';

    if (T) {
	f := frame();
	global acbn;
	print 'test_jenguic: created global symbol: acbn';
	acbn := jng.appctrl(f, help='test_jenguic');
	print acbn;
	private.continue := T;
	count := 0;
	acbn.enable();
	while (private.continue) {
	    count +:= 1;
	    print '\n ************** test_jenguic: count=',count;
	    jng.delay(2.0, txt='test_jenguic', trace=T);
	    acbn.suspend(enforce=F);
	    if (acbn.status('cancel')) private.continue := F;   # escape
	    if (count>10) private.continue := F;            # escape
	}
	print 'test_jenguic: finished, count=',count
	acbn.disable();
	jng.delay(2.0, txt='test_jenguic', trace=T);
	acbn.enable();
   }
    return T;
};
# test_jenguic();                 # run the test-program

#===========================================================
# Remarks and things to do:
#================================================================


