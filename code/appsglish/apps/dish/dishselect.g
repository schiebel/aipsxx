# dishselect.g: the dish selection operation.
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
#    $Id: dishselect.g,v 19.1 2004/08/25 01:11:20 cvsmgr Exp $
#
#------------------------------------------------------------------------------
pragma include once;

include 'dishselectgui.g';

const dishselect := function(ref itsdish)
{

    public := [=];
    private := [=];

    private.sdutil:=sdutil();

    private.gui := F;

    private.dish := itsdish;

    public.apply := function(fromgui=T,returnws=F) {
        wider public,private;
	if (!fromgui) {
		oldWorkingSetName:=private.getws();
		newWorkingSet := private.select(fromgui);
	} else {
        	oldWorkingSetName := private.cwsname();
        	newWorkingSet := private.select();
	}
        if (is_fail(newWorkingSet)) {
	    msg := 'selection failed';
	    if (has_field(newWorkingSet::,'message')) msg := newWorkingSet::message;
	    fail(msg);
	}
	if (is_boolean(newWorkingSet)) {
	    # this only happens when there is not a criteria
	    private.dish.message('No active criteria, using current working set');
	    return T;
	}
        if (newWorkingSet.length()==0) {
	    newWorkingSet.done();
            private.dish.message('Criteria resulted in zero-length selection: using current working set');
	    return T;
        }
	if (!returnws) {
            newWorkingSetName :=
                private.dish.rm().add('working_set',
                                      'selected on criteria',
                                      newWorkingSet,
                                      'SDITERATOR'); # 
	    eval(newWorkingSetName).length();
            private.dish.message(paste(newWorkingSetName,'created:',
                                       newWorkingSet.length(),'records'));
	    return T;
	} else {
           return newWorkingSet;
	} 
    }

    # return the current working set
    public.cws := function() {
        wider private;
        return symbol_value(private.cwsname());
    }

    private.cwsname := function() {
        wider private;
        workingSetName := '';
        # get the current name from the GUI if one is available
        if (is_agent(private.gui)) {
            workingSetName := private.gui.cws();
        } else {
	    workingSetName := private.ws;
	}
        return workingSetName;
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

    # dismiss the gui
    public.dismissgui := function() {
        wider private;
        if (is_agent(private.gui)) private.gui.done();
        private.gui := F;
        return T;
    }

    public.setcriteria := function(critrec=[=]) {
	wider private;	
	if (is_record(critrec)) {
		private.criteria:=critrec;
	}
        newcrit:=spaste('critrec=',as_string(private.criteria));
        private.dish.logcommand('dish.ops().select.setcriteria',newcrit);
	return T;
    }

    private.getcriteria := function(fromgui=T) {
        wider private;
        criteria := [=];
	if (!fromgui) {
		criteria:=private.criteria;
		return criteria;
	};
        # right now, this requires a GUI, eventually it must not
        if (is_agent(private.gui)) {
            criteria := private.gui.getcriteria();
        }
	newcrit:=spaste('critrec=[',criteria,']');
	private.dish.logcommand('dish.ops().select.setcriteria',newcrit);
        return criteria;
    }

    # return any state information as a record
    public.getstate := function() {
        wider private;
        state := [=];

        # all of the state is currently in the GUI, it should be here instead
        if (is_agent(private.gui)) {
            state := private.gui.getstate();
        }
        return state;
    }

    public.gui := function(parent, widgetset=dws) {
        wider private;
	wider public;
        # don't build one if we already have one or there is no display
        if (!is_agent(private.gui) && widgetset.have_gui()) {
            private.gui := dishselectgui(parent, public,
                                         itsdish, widgetset);
        }
        return private.gui;
    }

    public.newworkingset := function(wsname, ws) {
        wider private;
        # forward this to the GUI, when available
        result := F;
        if (is_agent(private.gui)) {
            private.gui.setws(wsname, ws);
            result := T;
        }
        return result;
    }

    public.opmenuname := function() { return 'Selection';}

    public.opfuncname := function() { return 'select';}

    private.select := function(fromgui=T) {
	wider private;
	# get the current working set & if there are any selection criteria
	# set by the user in the comboboxes, create a new sditerator based
	# on those criteria.  return the new iterator
	# if no selection criteria are set then return a F to indicate that
	# the cws() should be used.
	# If there is a problem, a fail will be returned.
	wider public,private;
	if (!fromgui) {
	    oldWorkingSet := public.cws();
	    criteria := private.criteria;
	} else {
	    oldWorkingSet := public.cws();
	    wsname:=private.cwsname();
	    private.dish.logcommand('dish.ops().select.setws',[ws=wsname]);
	    criteria := private.getcriteria();
	}
	private.dish.logcommand('dish.ops().select.setcriteria',
				data=[critrec=criteria]);
	if (!is_sditerator(oldWorkingSet)) {
	    fail 'no working set (sditerator) selected';
	}#
	if (len(criteria) == 0) return F;

	for (field in field_names(criteria)) {
	    if (is_fail(criteria[field])) {
		fail;
	    }
	}

	dum:=oldWorkingSet.select(criteria);
	return dum;
    }

    private.getws := function() {
	wider private;
	return symbol_value(private.ws);
    }

    public.setws := function(ws,fromgui=T) {
	wider private;

#	if (!is_sditerator(ws)) return throw('Not a working set');
	if (!fromgui && is_string(ws)) {
		private.ws:=ws;
		return T;
	}
	if (is_string(ws)) {
		private.ws := ws;
		if (is_agent(private.gui)) {
			private.gui.setws(private.ws,symbol_value(private.ws));
		}
	}
	return T;
    }

    public.setstate := function(state) {
	wider private;
        if (is_record(state)) {
            # just forward it to the gui
            if (is_agent(private.gui)) {
                private.gui.setstate(state);
            }
        }
    }

    public.setPendingCWS := function() {
	wider private;
	# just forward it to the gui
	if (is_agent(private.gui)) {
	    private.gui.setPendingCWS();
	}
    }

    public.updatecomboboxes := function() {
	wider private;
	if (is_agent(private.gui)) {
		ok:=private.gui.updateComboboxes(public.cws());
	}
    }

##select     Description: Select a subset of a scangroup.
##           Example:     select(records='[1:100]',scans='[4:6]',
##                        source='firstz',restfrequency='[1.41e+9:2.4e+10]'
##                        date='1997-07-23');
##           Returns:     T (if successful)
##           Produces:    A new scangroup based on the selected criteria.
   public.dselect := function(scans=F,rows=F,source=F,restfrequency=F,date=F,
                    ut=F,filein=F) {
        wider private,public;
 	criteria:=[=];

        ok:=public.setws(private.dish.wsname());

        if (!is_boolean(restfrequency)) {
                criteria.data:=[=];
                criteria.data.desc:=[=];
                criteria.data.desc.restfrequency:=private.sdutil.parseranges(restfrequency);
        }
        if (!is_boolean(scans)) {
                criteria.header:=[=];
                criteria.header.scan_number:=private.sdutil.parseranges(scans);
        };
        if (!is_boolean(rows)) {
                criteria.row:=private.sdutil.parseranges(rows);
        };
        if (!is_boolean(source)) {
                criteria.header:=[=];
                criteria.header.source_name:=private.sdutil.parsestringlist(source);
		if (is_fail(criteria.header.source_name)) {
		    fail('There is a syntax error in the source_name selection');
		}
        };
        if (!is_boolean(date)) {
                criteria.header:=[=];
                criteria.header.date:=date;
        }
        if (!is_boolean(ut)) {
                criteria.header:=[=];
                criteria.header.ut:=private.sdutil.parseranges(ut);
        }
        ok:=public.setcriteria(critrec=criteria);
        ok:=public.apply(F);
	if (is_fail(ok)) fail;
        # do we want to filein the new working set?
        if (filein) {
                sz:=private.dish.rm().size();
                ok:=private.dish.rm().select(sz);
                ok:=public.dfilein(private.dish.rm().getselectionnames());
        }
	return T;
   }


#    public.debug := function() {wider private; return private;}

    # return the public interface
    return public;
}
