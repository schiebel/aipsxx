#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000,2001
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
#    $Id: dishmsplot.g,v 19.2 2004/08/25 01:10:34 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include 'dishmsplotgui.g';

const dishmsplot := function(ref itsdish)
{
    public := [=];
    private := [=];

    # the default is to start off without the GUI
    private.gui := F;

    private.dish := itsdish;
    private.sdutil := F;
    private.myms := unset;
    private.editchoice := T;
    private.history := unset;
    private.selection := unset;

    private.append := function(ref list, thing) {
	# appends thing to list
	for (i in 1:len(thing)) {
	    list[len(list)+i] := thing;
	}
    }

    private.updateGUIstate := function() {
	wider private;
	if (is_agent(private.gui)) {
	    private.gui.setms(private.myms);
	    private.gui.sethistory(private.history);
	    private.gui.setselection(private.selection);
	}
    }

#   must be sent an MS on disk or an sditerator which points to an MS on disk
    public.apply := function(lv=F,editchoice=T) {
        wider private;
        # the GUI always sets the state here before actually invoking apply
        # so we can rely on the private state to be correct
#	print 'lv is ',lv;
        if (is_boolean(lv)|lv=='') {
           if (private.dish.doselect()) {
                if (private.dish.rm().selectionsize()==1) {
                        lv := private.dish.rm().getselectionvalues();
			nominee:=lv.name();
                        nname:=private.dish.rm().getselectionnames();
                } else {
                        return throw('did not work');
                }
           } else {
			print 'No MS provided, No MS selected or select from RM not checked';
			return F;
           }
        } else {
                nominee := ref lv;
                nname:='temp';
        }
	include 'msplot.g';
	ok:=msplot(nominee,edit=editchoice);
        #
        return T;
    }

    # dismiss the gui
    public.dismissgui := function() {
        wider private;
        if (is_agent(private.gui)) {
            private.gui.done();
        }
        private.gui := F;
        return T;
    }

    # done with this closure, this makes it impossible to use the public
    # part of this after invoking this function
    public.done := function() {
        wider private;
        wider public;
        public.dismissgui();
        val private := F;
        val public := F;
        return T;
    }

    public.getms := function() {
        wider private;
        if (is_agent(private.gui)) {
            private.myms := private.gui.getms();
        }
        return private.myms;
    }

    public.getedit := function() {
	wider private;
	if (is_agent(private.gui)) {
		private.editchoice:=private.gui.getedit();
	}
	return private.editchoice;
    }

    # return any state information as a record
    public.getstate := function() {
        wider private, public;
        state := [=];
	if (is_agent(private.gui)) {
        	state.myms := public.getms();
	}
        state.history := unset;
        state.selection := unset;
        if (is_agent(private.gui)) {
            state.history := private.gui.gethistory();
            state.selection := private.gui.getselection();
        }
        return state;
    }

    public.gui := function(parent, widgetset=dws) {
        wider private;
        wider public;
        # don't build one if we already have one or there is no display
        if (!is_agent(private.gui) && widgetset.have_gui()) {
            private.gui := dishmsplotgui(parent, public,
                                           itsdish.logcommand,
                                           widgetset);
            private.updateGUIstate();
            whenever private.gui->done do {
		# necessary because sometimes private is destroyed
		# elsewhere before this is called
		if (is_record(private)) {
		    private.gui := F;
		}
            }

        }
        return private.gui;
    }

    public.opmenuname := function() { return 'msplot';}

    public.opfuncname := function() { return 'msplot';}

    public.setms := function(myms, updateGUI=T) {
        wider private;
        if (is_string(myms)) {
            private.myms := myms;
            if (updateGUI && is_agent(private.gui)) {
                private.gui.setms(private.myms);
            }
        }
        return T;
    }

    public.setedit :=function(editchoice,updateGUI=T) {
	wider private;
	if (is_boolean(editchoice)) {
		private.editchoice := editchoice;
		if (updateGUI && is_agent(private.gui)) {
			private.gui.setedit(editchoice);
		}
	}
	return T;
    }

    # set the state from the indicated record
    # invoking this with an empty record should reset this to its
    # initial state
    public.setstate := function(state) {
	wider public, private;
	result := F;
	if (is_record(state)) {
	    # default values;
	    private.myms := unset;
	    private.history := unset;
	    private.selection := unset;
	    if (has_field(state,'myms')) {
		private.myms := state.myms;
	    }
	    if (has_field(state, 'history')) {
		private.history := state.history;
	    }
	    if (has_field(state, 'selection')) {
		private.selection := state.selection;
	    }
	    private.updateGUIstate();
	    result := T;
	}
	return result;
    }

    # initialize to the default state
    public.setstate([=]);

#    public.debug := function() { wider private; return private;}

    # return the public interface
    return public;
}
