# dishcalculator.g: DISH calculator.
#------------------------------------------------------------------------------
# Copyright (C) 1999,2000,2002,2003
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
# $Id: dishcalculator.g,v 19.1 2004/08/25 01:09:29 cvsmgr Exp $
#------------------------------------------------------------------------------
pragma include once;

include 'dishcalculatorgui.g'
include 'popuphelp.g'

const dishcalculator := function (ref itsdish)
{

  private := [=];     # mostly private data
  public  := [=];

  private.gui := F;
  private.dish := itsdish;
  
#
# Stack counter is for labeling the stack values
# lb=listbox counter is for keeping track of values in listbox-this is
# necessary because deleting values within the listbox causes problems
# in the indexing
  private.stackcntr:=0;
  private.lbcntr   :=0;
#
  public.dismissgui := function() {
        wider private;
        if (is_agent(private.gui)) {
            private.gui.done();
        }
        private.gui := F;
        return T;
  }

  public.setstate := function(state) {
      wider private;
      result := F;
      if (is_record(state)) {
	  if (is_agent(private.gui)) {
	      result := private.gui.setstate(state);
	  }
      }
      return result;
  }

  public.getstate := function() {
	wider private;
	if (is_agent(private.gui)) {
		return private.gui.getstate();
	}
	return F;
  }
  public.opmenuname := function() { return 'Calculator';}

  public.opfuncname := function() { return 'calculator';}
 
  public.gui := function(parent, widgetset=dws) {
        wider private;
        wider public;
        # don't build one if we already have one or there is no display
        if (!is_agent(private.gui) && widgetset.have_gui()) {
            private.gui := dishcalculatorgui(parent, itsdish, widgetset);
	}
        whenever private.gui->done do {
	    wider private;
	    if (is_record(private)) private.gui := F;
        }
        return private.gui;
    }

    public.done := function() {
        wider private;
        wider public;
        public.dismissgui();
        val private := F;
        val public := F;
        return T;
    }

    public.paste := function() {
	wider private;
	return private.gui.paste();
    }

    return public;
#

}	# end dishcalculator
