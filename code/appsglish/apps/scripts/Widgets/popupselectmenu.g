# popupselectmenu.g: Add popup menu to a GUI
# Copyright (C) 1996,1997,1998,1999,2001
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: popupselectmenu.g,v 19.2 2004/08/25 02:17:34 cvsmgr Exp $
#
pragma include once

include "note.g";
include "widgetserver.g";
#
const popupselectmenu := subsequence(ref fr, labels="", background='gray',
				     foreground='black',
				     font='', relief='none', widgetset=dws) {
  if (!is_record(fr)) {
    return throw('popupmenu - argument must be an agent or a record, ', 
		 'not a ', type_name(fr));
  };
  
  private := [=];
  private.fr := ref fr;

  if(!has_field(fr, 'popupmenu')||!is_record(fr.popupmenu)) {
    fr.popupmenu := [=];
    fr.popupmenu.enabled:=T;
  }

  # Return an agent for which we can get events
  const private.menu := subsequence() {
    
    wider private;
    # No existing popupmenuframe: add one
    if (has_field(private.fr, 'listbox') && is_function(private.fr.listbox)) {
      private.fr.popupmenu.frame := widgetset.frame(tlead=private.fr.listbox(), tpos='c', 
					    background=background);
    } else if (is_agent(private.fr)) {
      private.fr.popupmenu.frame := widgetset.frame(tlead=private.fr, tpos='c',
					    background=background);
    };
    private.fr.popupmenu.frame->bind('<Leave>', 'lve');
    private.fr.popupmenu.frame->raise(private.fr);
    
    private.fr.popupmenu.frame.menu := [=];
    for (label in private.fr.labels) {
      private.fr.popupmenu.frame.menu[label] :=
	  widgetset.button(private.fr.popupmenu.frame, label,
			   value=label,
			   foreground=foreground,
			   background=background,
			   font=font,
			   relief='flat',
			   justify='left',
			   borderwidth=0);
      # Relay all types of event but stop after one event!
      private.fr.popupmenu.frame.menu[label].parent :=
	  ref private.fr.popupmenu.frame;
      whenever private.fr.popupmenu.frame.menu[label]->press do {
	self->select($value);
	$agent.parent->unmap();
	$agent.parent := F;
	deactivate;
      }
    }
    whenever private.fr.popupmenu.frame->lve do {
      thisagent := ref $agent;
      thisagent->unmap();
      val thisagent := F;
      deactivate;
    }
  }
  self.kill := function() {
    wider private;
    if(has_field(private.fr, 'popupmenu.subs')) {
      private.fr.popupmenu.subs := F;
    }
    if(has_field(private.fr, 'popupmenu.frame')) {
      private.fr.popupmenu.frame := F;
    }
    if(has_field(private.fr, 'popupmenu')) private.fr.popupmenu := F;
  }
  
  self.enable := function() {
    wider private;
    if(has_field(private.fr, 'popupmenu')) {
      private.fr.popupmenu.enabled:=T;
    }
  }

  self.disable := function() {
    wider private;
    if(has_field(private.fr, 'popupmenu')) {
      private.fr.popupmenu.enabled:=F;
    }
  }

  if (is_agent(private.fr) && !has_field(private.fr, 'killed')) {
    if ((is_string(labels) && strlen(labels) != 0) || is_function(labels)) {
      private.fr.labels := labels;
      private.fr->bind('<Button-3>', 'mb3');
      private.fr->bind('<Leave>', 'lve');
      # We relay the first event and then exit
      whenever private.fr->["mb3"] do {
        if(private.fr.popupmenu.enabled) {
	  private.fr.popupmenu.subs := private.menu();
	  whenever private.fr.popupmenu.subs->* do {
	    self->[$name]($value);
	    deactivate;
	  }
	}
      }
      whenever private.fr->["lve"] do {
        if(private.fr.popupmenu.enabled) {
	  if(has_field($agent, 'popupmenu.subs')) {
	    $agent.popupmenu.subs.kill();
	  }
	  deactivate;
	}
      }
    }
  }
  
}
  
