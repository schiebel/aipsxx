#   dishimager.g
#------------------------------------------------------------------------------
#   Copyright (C) 1999,2000,2001,2003
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
#    $Id: dishimager.g,v 19.2 2004/08/25 01:10:24 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include 'dishimagergui.g';

const dishimager := function(ref itsdish)
{
    public := [=];
    private := [=];

    # the default is to start off without the GUI
    private.gui := F;

    private.dish := itsdish;
    private.sdutil := F;
    private.thems := unset;
    private.mysd := unset;
    private.mysi := unset;
    private.myso := unset;
    private.myw  := unset;

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
	    private.gui.sethistory(private.history);
	    private.gui.setms(private.thems);
	    private.gui.setsd(private.mysd);
	    private.gui.setsi(private.mysi);
	    private.gui.setso(private.myso);
	    private.gui.setw(private.myw);
	}
    }

#   must be sent an MS on disk or an sditerator which points to an MS on disk
    public.apply := function(thems,sd,si,so,w,row=1) {
        wider private;
        # the GUI always sets the state here before actually invoking apply
        # so we can rely on the private state to be correct
# this had better be temporary!
#	include 'fixsdms.g';
#	ok:=fixsdms(thems);
#	include 'fixpnt.g';
#	ok2:=fixpnt(thems);
	include 'imager.g';
	global myim:=imager(thems);
	sds:=spaste('myim.setdata(',sd,')');
	ok:=eval(sds);
#	get phase center
	maintab := table(thems);
	ptab:=table(maintab.getkeyword('POINTING'));
	direcs:=ptab.getcol('DIRECTION');
	maintab.done();
	ptab.done();
	thedir:=direcs[,1,row];
	global mydir:=dm.direction('J2000',spaste(thedir[1],'rad'),spaste(thedir[2],'rad'));
	print 'mydir is ',mydir;
	myim.weight(w);
	sis:=spaste('myim.setimage(',si,',phasecenter=mydir)');
	ok:=eval(sis);
	myim.makeimage(image='scanimage',type='singledish');
	imscan:=image('scanimage');
	imscan.view(raster=T,contour=T,axislabels=T);
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
            private.thems := private.gui.getms();
        }
        return private.thems;
    }

    public.getsd := function() {
	wider private;
	if (is_agent(private.gui)) {
	    private.mysd := private.gui.getsd();
	}	
	return private.mysd;
    }
    public.getsi := function() {
	wider private;
	if (is_agent(private.gui)) {
	    private.mysi := private.gui.getsi();
	} 
	return private.mysi;
    }
    public.getso := function() {
	wider private;
	if (is_agent(private.gui)) {
	    private.myso := private.gui.getso();
	}
	return private.myso;
    }
    public.getw := function() {
	wider private;
	if (is_agent(private.gui)) {
	    private.myw := private.gui.getw();
	}
	return private.myw;
    }

    # return any state information as a record
    public.getstate := function() {
        wider private, public;
        state := [=];
	if (is_agent(private.gui)) {
        	state.thems := public.getms();
	}
        state.history := unset;
        state.selection := unset;
        if (is_agent(private.gui)) {
            state.history := private.gui.gethistory();
	    state.thems:=private.gui.getms();
	    state.sd   :=private.gui.getsd();
	    state.si   :=private.gui.getsi();
	    state.so   :=private.gui.getso();
	    state.w    :=private.gui.getw();
        }
        return state;
    }

    public.gui := function(parent, widgetset=dws) {
        wider private;
        wider public;
        # don't build one if we already have one or there is no display
        if (!is_agent(private.gui) && widgetset.have_gui()) {
            private.gui := dishimagergui(parent, public,
                                           itsdish.logcommand,
                                           widgetset);
            private.updateGUIstate();
            whenever private.gui->done do {
		wider private;
                if (is_record(private)) private.gui := F;
            }

        }
        return private.gui;
    }

    public.opmenuname := function() { return 'imager';}

    public.opfuncname := function() { return 'imager';}

    public.setms := function(myms, updateGUI=T) {
        wider private;
        if (is_string(myms)) {
            private.thems := myms;
            if (updateGUI && is_agent(private.gui)) {
                private.gui.setms(private.thems);
            }
        }
        return T;
    }
    public.setsd := function(mysd, updateGUI=T) {
	wider private;
	if (is_string(mysd)) {
	   private.mysd := mysd;
	   if (updateGUI && is_agent(private.gui)) {
		private.gui.setsd(private.mysd);
	   }
        }
    }

    public.setsi := function(mysi, updateGUI=T) {
        wider private;
        if (is_string(mysi)) {
           private.mysi := mysi;
           if (updateGUI && is_agent(private.gui)) {
                private.gui.setsi(private.mysi);
           }
        }
    }

    public.setso := function(myso, updateGUI=T) {
        wider private;
        if (is_string(myso)) {
           private.myso := myso;
           if (updateGUI && is_agent(private.gui)) {
                private.gui.setso(private.myso);
           }
        }
    }

    public.setw := function(myw, updateGUI=T) {
        wider private;
        if (is_string(myw)) {
           private.myw := myw;
           if (updateGUI && is_agent(private.gui)) {
                private.gui.setw(private.myw);
           }
        }
    }


    # set the state from the indicated record
    # invoking this with an empty record should reset this to its
    # initial state
    public.setstate := function(state) {
	wider public, private;
	result := F;
	if (is_record(state)) {
	    # default values;
	    private.thems := unset;
	    private.mysd := unset;
	    private.mysi := unset;
	    private.myso := unset;
	    private.myw  := unset;
	    private.history := unset;
	    if (has_field(state,'thems')) {
		private.thems := state.thems;
	    }
	    if (has_field(state,'sd')) {
                private.mysd := state.sd;
            }
	    if (has_field(state,'si')) {
                private.mysi := state.si;
            }
	    if (has_field(state,'so')) {
                private.myso := state.so;
            }
	    if (has_field(state,'w')) {
                private.myw := state.w;
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
