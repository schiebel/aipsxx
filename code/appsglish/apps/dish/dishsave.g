# dishsave.g: the dish Save operation.
#------------------------------------------------------------------------------
#
#   Copyright (C) 1999,2000,2001,2002,2003
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
#    $Id: dishsave.g,v 19.2 2004/08/25 01:11:10 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include 'dishsavegui.g';

const dishsave := function(ref itsdish)
{
    public := [=];
    private := [=];
    private.gui := F;
    private.dish := itsdish;
#    private.sdutil := F;

    private.wsname := F;

    # save the last viewed record to the current named working set
    public.apply := function(lv=F,outf=F) {
        wider private;
########################
        if (is_boolean(lv)) {
	    if (private.dish.doselect()) {
		if (private.dish.rm().selectionsize()==1) {
		    lv := private.dish.rm().getselectionvalues();
		    nominee := ref lv;
		    nname := private.dish.rm().getselectionnames();
		} else {
		    print 'ERROR: bad selection in Results Manager';
		    return F;
		}
	    } else {
		lv:=private.dish.rm().getlastviewed();
		nominee := ref lv.value;
		nname := lv.name;
	    }
	} else {	
	    nominee := ref lv;
	    nname := 'temp';
        }
######################

        ws := F;
        if (is_boolean(outf)) {
	    if (is_agent(private.gui)) {
       	       private.wsname := private.gui.wsname();
       	       if (strlen(private.wsname) == 0) private.wsname := F;
       	    } else {# otherwise just use what's already there
                #ok:=private.dish.open(spaste(nname,'_save'),new=T);
                if (is_boolean(private.wsname)) {
                   private.dish.message('No working set has been indicated for the save operation.');
                   return F;
                }

	    }
        } else {
            ok:=private.dish.open(outf,new=T);
	    rmlen:=private.dish.rm().size();
	    private.wsname := private.dish.rm().getnames(rmlen);
        };
        if (is_defined(private.wsname)) ws := symbol_value(private.wsname);
        if (!is_sditerator(ws)) {
            private.dish.message('The selected entry is no longer a valid working set');
            return F;
        }
########################
	global __sdsavetemp__ := nominee;
        if (is_boolean(__sdsavetemp__)) {
            private.dish.message('There is no currently viewed SDRecord available to be saved.');
            return F;
        } else if (is_sditerator(__sdsavetemp__)) {
	    sdlength := __sdsavetemp__.length();
	    ok := __sdsavetemp__.setlocation(1);
#	    if (is_boolean(private.sdutil)) private.sdutil := sdutil();
	    for (i in 1:sdlength) {
		ok := __sdsavetemp__.setlocation(i);
		global __temprec__ := __sdsavetemp__.get();
		a:=ws.appendrec(__temprec__);
		ok:=ws.flush();
	    };
	} else if (is_sdrecord(__sdsavetemp__)) {
	    a := ws.appendrec(nominee);
		ok:=ws.flush();
	    if (!is_boolean(a) || !a) {
	    private.dish.message('There was a problem appending to the working set. See the logger for details.');
	    return F;
	    }
	private.dish.message('The currently viewed SDRecord has been appended to the selected working set.');
        }
	return T;
    }

    public.dismissgui := function() {
        wider private;
        if (is_agent(private.gui)) private.gui.done();
        private.gui := F;
        return T;
    }

    public.done := function() {
        wider private;
        wider public;
        public.dismissgui();
        val private := F;
        val public := F;
        return T;
    }

    public.getstate := function() {
        wider private;
        state := [=];
        if (is_agent(private.gui)) private.wsname := private.gui.wsname();
        state.wsname := private.wsname;
        return state;
    }

    public.opmenuname := function() { return 'Save to table';}
    public.opfuncname := function() { return 'save';}

    public.gui := function(parent, widgetset=dws) {
	wider private;
	wider public;
	if (!is_agent(private.gui) && widgetset.have_gui()) {
	    private.gui := dishsavegui(parent, public, private.dish, widgetset);
	}
	return private.gui;
    }

    public.opmenuname := function() { return 'Save to table';}
    public.opfuncname := function() { return 'save';}

    public.setstate := function(state) {
	wider public;
	if (is_record(state) && has_field(state, 'wsname') &&
	    is_string(state.wsname) && len(state.wsname) == 1) {
#	    public.setws(state.wsname);
	}
    }

#JPM need to define private.combo
#  self.setstate := function(state) {
#      wider private;
#      if (is_record(state)) {
#          # set to the default value
#          private.combo.insertentry('');
#          if (has_field(state,'cwsname') && is_string(state.cwsname) &&
#              len(state.cwsname) == 1) {
#              # verify that this ws is available in the combobox
#              knownws := private.combo.get('start','end');
#              mask := knownws == state.cwsname;
#              if (any(mask)) {
#                  which := ind(mask)[mask] - 1;
#                  if (len(which) == 1) {
#                      private.combo.select(which);
#                  }
#              }
#          }
#      }
#  }


    # set the working set, this must be a name already known to
    # the results manager.  If fromgui is T, then it assumes that
    # that is is known to the results manager - i.e. there are
    # no additional checks.
    public.setws := function(wsname) {
	wider private;
	result := F;
	size := private.dish.rm().size();
	if (size > 0) {
	    names := private.dish.rm().getnames(seq(size));
	    which := ind(names)[names == wsname];
	    if (len(which) == 1) {
		v := symbol_value(names[which]);
		if (is_sditerator(v) && v.iswritable()) {
		    private.wsname := wsname;
		    result := T;
		} else {
		    print 'ERROR: Not an SDIterator or not writable';
		    return F;
		};
	    } else {
		print 'ERROR: File not found in Results Manager';
		print '--- Make sure the file has been opened.';
		print '--- run "d.open(filename,access="w") ';
		print '--- or  "d.open("filename",new=T)';
		return F;
	   };
	}
	# update the GUI if one is in use
	if (result && is_agent(private.gui)) {
	    private.gui.setws(private.wsname);
	}

	return result;
    } 

    return public;
}
