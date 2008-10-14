# dishgui.g: The gui for dish, the AIPS++ single-dish environment.
#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000,2001,2002
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
#    $Id: dishgui.g,v 19.2 2004/08/25 01:10:19 cvsmgr Exp $
#
#------------------------------------------------------------------------------

pragma include once;

include "dish.g";
include "widgetserver.g";
include "popuphelp.g";
include "catalog.g";
include "scripter.g";

dishgui := subsequence(parent=F, widgetset=dws, itsdish, scripter=ds) 
{
    private := [=];
    private.catalog := F;
    private.dish := itsdish;
    private.toolname := F;

    # the default scripter
    private.scripter := scripter;

    # default is to not log to the scripting tool
    private.script := F;

    private.new := F;
    private.access := 'r';

    private.widgetset := widgetset;

    self.widgetset := function() { wider private; return private.widgetset;}


    private.cleanup := function(rec = unset) {
	wider private;
	if (is_unset(rec)) {
	    rec := private;
	    rec.is_finished := T;
	}
	# set all agents in rec to F, recursive call if a field is a record
	for (field in field_names(rec)) {
	    if (is_record(rec[field])) {
		private.cleanup(rec[field]);
	    } else {
		if (is_agent (rec[field])) {
		    val rec[field] := F;
		}
	    }
	}
    }

    self.done := function() {
	# this just emits the done event, rely on dish to call dismissgui
	self->done(T);
    }

    self.dismissgui := function() {
	wider private;
	private.cleanup();
    }

    private.logcommands := function(torf) {
	wider private;
	private.script := torf;
	if (private.script) {
		note('logging to scripter is enabled');
	} else {
		note('logging to the scripter is disabled');
	}
    }

    self.dologging := function(torf=unset) {
	if (!is_unset(torf)) {
	    private.optionsmenu['script']->state(torf);
	    private.logcommands(torf);
	}
	return private.script;
    }

    # method is the name of function to log
    # data are the arguments, by name
    # if there is an argument named "return" which is
    # a non-zero length string, then that string is used
    # as the lh side of the full command, if no return
    # is specified, "ok" is assumed.
    self.logcommand := function(method, data=[=]) {
	wider private;
    # figure out toolname - really only works for one instance
    # only do this once!
#	too costly in time
#    if (is_defined('tm')) {
#    	currtools:=tm.tools();
#    	for (i in 1:len(currtools)) {
#		currtypes[i] := currtools[i].type;
#    	}
#    	if (any(currtypes=='dish')) {
#		private.toolname:=field_names(currtools)[currtypes=='dish'][1];
#    	} else {
		private.toolname:='d';
#		return F;
#    	}
##    }
    # replace prefab 'dish' with real toolname
	tmp:=split(method,'.');
    	method:=as_string(private.toolname);
	if (len(tmp)>1) {
        	for (i in 2:len(tmp)) {
			method:=spaste(method,'.',tmp[i]);
		}
	}
#	} else {
#	method:='dish';
#	}


	if (private.script && is_string(method) && is_record(data)) {
	    command := spaste(method,'(');
	    first := T;
	    hasReturn := F;
	    for (field in field_names(data)) {
		if (field == 'return' && is_string(data[field])) {
		    command := spaste(data[field],' := ',command);
		    hasReturn := T;
		} else {
		    if (!first) {
			command := spaste(command,',');
		    } 
		    command := spaste(command, field,'=');
		    if (len(data[field]) == 0) {
			command := spaste(command,'[]');
		    } else {
			command := spaste(command, as_evalstr(data[field]));
		    }
		    first := F;
		}
	    }
	    command := spaste(command,')');
	    if (!hasReturn) {
		command := spaste('ok := ',command);
	    }
	    private.scripter.log(command);
	}
    }

    junk := widgetset.tk_hold();

    # the outer frame
    private.frame := widgetset.frame(parent, title='DISH', side='top');

    self.frame := ref private.frame;

    # watch for killed events
    whenever private.frame->killed do { wider self; self.done();}

    # a function to disable/enable the frame and contents and set a busy cursor
    # calls to this with T must be matched by calls with F
    # because of the use of disable/enable
    private.busy := function(tOrF) {
	wider private;
	if (tOrF) {
	    private.frame->cursor('watch');
	    private.frame->disable();
	} else {
	    private.frame->enable();
	    private.frame->cursor('left_ptr');
	}
    }

    self.busy := function(tOrF) { wider private; private.busy(tOrF);}

    private.saveStateAsCallback := function(filename) {
        # ignore unsets
	wider private;
        if (!is_unset(filename)) {
            ok := itsdish.statefile(filename);
            if (!is_fail(ok) && ok) {
                ok := private.dish.savestate();
            }
            if (is_fail(ok) || !ok) {
                return throw('dish was unable to save its state');
            } else {
                if (private.script) {
                 private.dish.logcommand('dish.statefile',
			[fullPathname=dparams.getparamfile()]);
                 private.dish.logcommand('dish.savestate');
                }
            }
        }
        return T;
    }

    private.saveStateAs := function() {
        wider private;
        # don't force a resow here, dc.show will do that shortly
        dc.gui(F);
        # start from where we are
        pf := dparams.getparamfile();
        pfdir := dos.dirname(pf);
        if (dos.fileexists(pfdir) && dos.filetype('Directory')) {
            dc.show(pfdir, show_types='All');
        } else {
            dc.show(show_types='All');
        }
        dc.setselectcallback(private.saveStateAsCallback);
        return T;
    }

    private.restoreStateFromCallback := function(filename) {
	wider private;
        # ignore unsets
        if (!is_unset(filename)) {
            # this may change the state of showscript, honor its current value
            doshow := private.script;
            ok := private.dish.statefile(filename);
            if (!is_fail(ok) && ok) {
                ok := private.dish.restorestate();
            }
            if (is_fail(ok) || !ok) {
                return throw('dish was unable to restore its state');
            } else {
                if (doshow) {
                   private.dish.logcommand('dish.statefile',
			[fullPathname=dparams.getparamfile()]);
                   private.dish.logcommand('dish.restorestate');
                }
            }
        }
        return T;
    }

    private.restoreStateFrom := function() {
        wider private;
        # don't force a resow here, dc.show will do that shortly
        dc.gui(F);
        # start from where we are
        pf := dparams.getparamfile();
        pfdir := dos.dirname(pf);
        if (dos.fileexists(pfdir) && dos.filetype('Directory')) {
            dc.show(pfdir, show_types='All');
        } else {
            dc.show(show_types='All');
        }
        dc.setselectcallback(private.restoreStateFromCallback);
        return T;
    }
#
    private.openCallback := function(pathname) {
        wider private;
        private.dish.open(pathname, private.nextAccess, private.nextNew);
        # and break the connection
        dc.setselectcallback(0);
    }

    private.chooseAndOpenFile := function (access, new=F) {
        wider private;
        # use the default catalog, just establish a connection
        # after making sure the gui is up and let the user handle
        # it or break it as they will - other operations can
        # continue during the process
        private.nextAccess := access;
        private.nextNew := new;
        # don't force a reshow here, dc.show will do that shortly
        dc.gui(F);
	# only show known data types;
	known_data[1]:='Other Table';
	known_data[2]:='Measurement Set';
        if (new) {
            dc.show(show_types=known_data);
        } else {
	     dc.show(show_types=known_data);
        }
        dc.setselectcallback(private.openCallback);
    }

    self.savewhendone := function() {
        wider private;
        return private.optionsmenu['save']->state();
    }

    self.select := function() {
	wider private;
	# workaround for bug in glish - querying state of select option button
	# can unset the ranges in the plotter, somehow
	ri := private.dish.plotter.ranges();
	if (private.optionsmenu['select']->state()) {
		private.dish.message('Select SDS from Results Manager');
	};
	private.dish.plotter.putranges(ri);
	return private.optionsmenu['select']->state();
    }

    # build the menu bar
    private.menubar := widgetset.frame(private.frame, side='left', 
				       relief='raise', expand='x');
    # File menu
    private.filebutton:=widgetset.button(private.menubar, 'File', type='menu');
    # the help for the File menu
    helptext := 'File Menu';
    helpitems := as_string([]);
    helpitems[1] := 'create a new single dish table on disk';
    helpitems[2] := 'open an existing single dish table from disk';
    helpitems[3] := 'save the current state to the current state file';
    helpitems[4] := 'change to a different state file and save the state there';
    helpitems[5] := 'restore the state previously saved from the current state file';
    helpitems[6] := 'change to a different state file and restore the state from it';
    helpitems[7] := 'reset dish to its default, pristine state';
    helpitems[8] := 'dismiss the GUI window, use dish.gui() to bring it back ';
    for (txt in helpitems) {
          helptext := spaste(helptext,'\n','- ',txt);
    }
    private.filebutton.shorthelp:=helptext;

    private.filemenu := [=];
    # the "access" here is of the files to display, not the file to create,
    # which is always "rw", this ensures that all readable files will be
    # displayed in the chooser
    private.filemenu['new']  := widgetset.button(private.filebutton, 'New ...',
				value=[access='r',new=T]);
    private.filemenu['open'] := widgetset.button(private.filebutton, 'Open', 
				type='menu');
    private.openmenu := [=];
    private.openmenu['read'] := widgetset.button(private.filemenu['open'],
				'Read Only ...',value=[access='r',new=F]);
    private.openmenu['readwrite'] := widgetset.button(private.filemenu['open'],
			        'Reading and Writing ... ',
				value=[access='rw',new=F]);
    private.filemenu['savestate']:=widgetset.button(private.filebutton, 
		                'Save state');
    private.filemenu['savestateas']:=widgetset.button(private.filebutton,
				'Save state as ...',value=[access='rw',new=T]);
    private.filemenu['restorestate']:=widgetset.button(private.filebutton,
				'Restore state');
    private.filemenu['restorestatefrom']:=widgetset.button(private.filebutton,
				'Restore state from ...',
				value=[access='r',new=F]);
    private.filemenu['restoredefaults']:=widgetset.button(private.filebutton,
				'Reset to default state');
    private.filemenu['dismiss'] := widgetset.button(private.filebutton, 
				'Dismiss Window',type='dismiss');

    private.open := function(thefilename) {
	wider private;
	private.catalog.setselectcallback(F);
	private.catalog.dismiss();
	# checks on the value
	# if its just an empty string, ignore it
	if (is_string(thefilename) && sum(strlen(thefilename)) > 0) {
	    # for now, we only handle one at a time
	    if (len(thefilename) > 1) {
		throw(paste('The DISH open menu can only handle one selection at a time'));
	    } else {
		# if (private.new) one must not already exist
		if (private.new && is_file(thefilename)) {
		    throw(paste(thefilename,'already exists, creating a new SD data set would overwrite it'));
		} else if (!private.new) {
		    s := stat(thefilename);
		    if (len(s) == 0) {
			throw(paste('The selected file does not exist:',thefilename));
		    }
		    # are the access permissions adequate
		    # we can't check this yet from glish, apaprently
		    # rely on the open to do that
		}
		# emit an open event to be picked up by dish
		self->open(file=thefilename, access=private.access, new=private.new);
	    } 
	}
    }
	
    # File menu actions
    whenever private.filemenu['new']->press, private.openmenu['read']->press, private.openmenu['readwrite']->press do {
	wider private;
	deactivate;
	private.busy(T);
	private.new := $value.new;
	private.access := $value.access;
	junk:=private.chooseAndOpenFile(access=private.access,new=private.new);
	private.busy(F);
	activate;
    }

    whenever private.filemenu['savestate']->press do {
        ok := private.dish.savestate();
        if (!is_fail(ok) && ok) {
            private.dish.logcommand('dish.savestate');
        }
    }

    whenever private.filemenu['savestateas']->press do {
        ok:=private.saveStateAs();
    }

    whenever private.filemenu['restorestate']->press do {
        # this may change the state of showscript, honor its current value
        ok := private.dish.restorestate();
        if (!is_fail(ok) && ok) {
            private.dish.logcommand('dish.restoretate');
        }
    }

    whenever private.filemenu['restorestatefrom']->press do {
        ok := private.restoreStateFrom();
    }

    whenever private.filemenu['restoredefaults']->press do {
        # this may change the state of showscript, honor its current value
        ok := private.dish.restorestate(usedefault=T);
        if (!is_fail(ok) && ok) {
            private.dish.logcommand('dish.restoretate',[usedefault=T]);
        }
    }

    whenever private.filemenu['dismiss']->press do { 
	wider private;
	private.busy(T);
#	self.done();
	#don't want to done just unmap
	private.dish.nogui();
    }
    

    # Options menu
    private.optionsbutton := widgetset.button(private.menubar, 'Options', type='menu');
        # the help for the options menu
        helptext := 'Toggle options';
        helptext := spaste(helptext,'\n','- Save the state to the current statefile when dish ends');
        helptext := spaste(helptext,'\n','- Echo glish to the default scripter,ds, for most GUI operations');
    private.optionsbutton.shorthelp := helptext;
    private.optionsmenu := [=];
    private.optionsmenu['script'] := widgetset.button(private.optionsbutton,
				      'Write script commands', type='check');
    private.optionsmenu['save'] := widgetset.button(private.optionsbutton,
				      'Save state when done',type='check');
    private.optionsmenu['select']:=widgetset.button(private.optionsbutton,
				     'Select from rm (for SDITs)',type='check');
    private.optionsmenu['save']->state(F);
    whenever private.optionsmenu['script']->press do {
	private.logcommands(private.optionsmenu['script']->state());
    }

    # Operations menu
    private.operbutton := widgetset.button(private.menubar, 'Operations', type='menu');
    private.operbutton.shorthelp := 'Toggle the individual operation frames';

    private.opermenu := [=];
    private.operframes := [=];
    private.operbutton->disabled(T);

    # Call this tools menu for now
    private.toolbutton:= widgetset.button(private.menubar,'Tools',type='menu');
    private.toolbutton.shorthelp := 'Toggle tool frames';
    private.toolmenu := [=];
    private.toolbutton->disabled(T);

    # The right side of the menu bar, containing the help menu
    private.rightmenubar := widgetset.frame(private.menubar, side='right', 
					    relief='flat', expand='x');

    # Help menu
    private.helpMenu := dws.helpmenu(private.rightmenubar,'Dish','gettingresults:GRsingledish');

    # the Results Manager frame, its up to the creating object to 
    # instruct its results manager to build its GUI here, presumably
    # it knows what its widgetset should be, if not dws.
    private.rmFrame := widgetset.frame(private.frame, relief='ridge');
    self.rmframe := function() { wider private; return private.rmFrame;}

    # The message line
    private.messageline := widgetset.messageline(private.frame);
    private.postIt := function(message) {
	wider private;
	if (is_agent(private.messageline) && !has_field(private, 'is_finished')) {
	    #the above check still seems to occasionally generate a fail
	    #vf <fail>: private.messageline is not an agent
	    #vf      File:   dishgui.g, Line 490
	    #add the superfluous if to help clear up?!
	  if (is_agent(private.messageline)) private.messageline->postnoforward(message);
	}
    }
    whenever self->post do {
	private.postIt($value);
    }

    # and at the bottom, the frame to hold the operations
    private.opsFrame := frame(private.frame, side='top', borderwidth=0);
    # we need something in this frame which doesn't go away and also doesn't
    # take up any space
    private.junkFrame := frame(private.opsFrame, height=0, width=0,
			       expand='none', borderwidth=0);
    self.opsframe := function() {wider private; return private.opsFrame;}

    # add a new operation which already is found within the indicated
    # opframe, which will be known in the operations menu by opname
    # the "mapped" argument determines if this is mapped or not
    self.newop := function(opgui, opname, mapped) 
    {
	wider private;
	# make the new button - just add it to the end, it would be
	# nice if this kept things sorted alphabetically
	private.operbutton->disabled(F);
	private.operframes[opname] := opgui.outerframe();
	private.opermenu[opname] := 
	    widgetset.button(private.operbutton, opname, type='check',
			     value=opname);
	self.mapop(opname, mapped);
	whenever private.opermenu[opname]->press do {
	    self.mapop($value, private.opermenu[opname]->state());
	}
	whenever opgui->dismiss do {
	    self.mapop($value, F);
	}
    }

    self.mapop := function(opname, mapped)
    {
	wider private;
	if (has_field(private.operframes, opname)) {
	    if (mapped) {
		private.operframes[opname]->map();
	    } else {
		private.operframes[opname]->unmap();
	    }
	    private.opermenu[opname]->state(mapped);
	}
	self->map([op=opname,mapped=mapped]);
    }
    
    #now emulate same behavior with tools as operations
    self.newtool := function(toolgui, toolname, mapped)
    {
        wider private;
        # make the new button - just add it to the end, it would be
        # nice if this kept things sorted alphabetically
        private.toolbutton->disabled(F);
        private.operframes[toolname] := toolgui.outerframe();
        private.toolmenu[toolname] :=
            widgetset.button(private.toolbutton, toolname, type='check',
                             value=toolname);
        self.maptool(toolname, mapped);
        whenever private.toolmenu[toolname]->press do {
            self.maptool($value, private.toolmenu[toolname]->state());
        }
        whenever toolgui->dismiss do {
            self.maptool($value, F);
        }
    }

    self.maptool := function(toolname, mapped)
    {
        wider private;
        if (has_field(private.operframes, toolname)) {
            if (mapped) {
                private.operframes[toolname]->map();
            } else {
                private.operframes[toolname]->unmap();
            }
            private.toolmenu[toolname]->state(mapped);
        }
        self->map([op=toolname,mapped=mapped]);
    }

    # finally, add all of the popup help
    addpopuphelp(private);

#    self.debug := function() { wider private; return private;}

    junk := widgetset.tk_release();
}


include 'ranges.g';

# A combobox with an an associated set of values, an enabling button 
# plus a button which, when pressed, displays the associated values, 
# possibly collapsing them as a range.
# Just a few arguments here, if the combobox needs to be done differently
# than this does, use the functions after creation
# This also has its own get, which ensures that when a value
# is retrieved it comes from the entry and, if that value is not
# the same as the currently selected value and is not an empty string,
# then it is inserted into the combobox.  This returns an
# empty string if the enabled button is off.


const dishSelectionCombobox := function(parent, labeltext, assocvalues=F,
					collapseDisplayAllRanges=F,
					canclearpopup=F,
					help='', widgetset=dws,itsdish)
{
    private := [=];
    public := [=];

    private.assocvalues := assocvalues;
    if (is_double(private.assocvalues)) private.assocvalues::print.precision := 15;

    private.f := widgetset.frame(parent, borderwidth=0,side='left');
    private.cb := widgetset.combobox(private.f, labeltext=labeltext, canclearpopup=canclearpopup,
				     help=help);
    private.enabler := widgetset.button(private.f, text='',type='check',relief='flat');
    private.enabler.shorthelp := 'Press to enable selection';
    whenever private.enabler->press do {};
    private.allButton := widgetset.button(private.f, text='All',disabled=F);
#    if (is_boolean(private.assocvalues)) private.allButton->disabled(T);
    private.allButton.shorthelp :=
	'Show all allowed values in a separate window';

    private.disabled := function(tOrF) {
	wider private;
	private.enabler->state(!tOrF);
    }

    if (collapseDisplayAllRanges && is_function(ranges)) {
	private.rangeHandler := function() {
	    return ranges().collapse(as_string(private.assocvalues));
	}
    } else {
	private.rangeHandler := function() {
	    return as_string(private.assocvalues);
	}
    }
    whenever private.allButton->press do {
	itsdish.busy(T);
	itsdish.ops().select.updatecomboboxes();
	itsdish.busy(F);
	j := messagebox(private.rangeHandler(), title=labeltext);
    }
    addpopuphelp(private);

    public.combobox := function() {wider private; return ref private.cb;}
    public.agent := function() {wider private; return private.cb.agent();}
    public.enabled := function() {
	wider private; 
	return private.enabler->state();
    }
    public.disabled := ref private.disabled;
    public.setassocvalues := function(assocvalues) {
	wider private;
	private.assocvalues := assocvalues;
	if (is_double(private.assocvalues)) private.assocvalues::print.precision := 15;
	private.allButton->disabled(F);
    }
    public.clearassocvalues := function() {
	wider private;
	private.assocvalues := F;
#	private.allButton->disabled(T);
    }
    public.getassocvalues := function() {
	wider private;
	return private.assocvalues;
    }
    public.get := function() {
	wider private;
	result := '';
	if (public.enabled()) {
	    result := private.cb.getentry();
	    thesel := private.cb.get('selected');
	    if (result != '' && (is_fail(thesel) || result != thesel)) {
		private.cb.insert(result,select=T);
	    }
	}
	if (strlen(result) == 0) result := as_string([]);
	return result;
    }
    # this is shorthand for inserting '' into the entry portion and
    # clearassocvalues() (which also disables that button).  
    # It does not clear the combobox listbox.
    # Use clearall to clear everything
    public.clear := function() {
	public.combobox().insertentry('');
	public.clearassocvalues();
    }
    public.clearall := function() {
	public.clear();
	public.combobox().delete('start','end');
    }

    public.getstate := function() {
	wider public;

	state := [=];

	state.cb := [=];
	state.cb.history := public.combobox().get('start','end');
	state.cb.entry := public.combobox().getentry();
	state.cb.selection := public.combobox().selection();

	state.enabled := public.enabled();
	state.assocvalues := public.getassocvalues();

	return state;
    }

    public.setstate := function(state) {
	wider public;
	if (is_record(state)) {
	    # default state
	    public.clearall();
	    public.disabled(T);
	    public.clearassocvalues();

	    if (has_field(state,'cb') &&
		is_record(state.cb) &&
		has_field(state.cb,'history') &&
		is_string(state.cb.history) &&
		has_field(state.cb,'entry') &&
		is_string(state.cb.entry) &&
		has_field(state.cb,'selection') &&
		is_integer(state.cb.selection)) {
		if (len(state.cb.history)>0) {
		    for (i in 1:len(state.cb.history)) {
			public.combobox().insert(state.cb.history[i],
						 as_string(i-1));
		    }
		}
		if (len(state.cb.selection) > 0) {
		    public.combobox().select(as_string(state.cb.selection));
		}
		public.clear();
		public.combobox().insertentry(state.cb.entry);
	    }
	    if (has_field(state,'enabled') &&
		is_boolean(state.enabled)) {
		public.disabled(!state.enabled);
	    }
	    if (has_field(state,'assocvalues') &&
		!is_boolean(state.assocvalues)) {
		public.setassocvalues(state.assocvalues);
	    }
		    
	}
    }
#    public.debug := function() { wider private; return ref private;}

    return public;
}
