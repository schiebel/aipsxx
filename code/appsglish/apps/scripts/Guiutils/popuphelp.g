# popuphelp.g: Add popup help to a GUI
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
# $Id: popuphelp.g,v 19.2 2004/08/25 02:01:04 cvsmgr Exp $
#
pragma include once

include 'note.g';
include 'timer.g';
include 'widgetserver.g';
#
##defaultservers.trace(T)
##defaultservers.suspend(T)
#
# Make sure system.help exists
#
global system;
if (!is_defined('system')) system := [=];
if (!has_field(system, 'help')) system.help := [=];
if (!has_field(system.help, 'type')) system.help.type := 1;
if (!is_integer(system.help.type)) system.help.type := 1;
if (!has_field(system.help, 'intvl')) const system.help.intvl := 0.30;
system.help.popup := F;
if (has_field(system.help, 'popupinit')) system.help.popupinit := F;
const system.help.popupinit := subsequence(type=1, intvl=0.30) {
  private := [=];
#
# Initialise popup fields
#
  if (is_integer(type) && length(type) == 1) {
    private.type := max(0, min(3, type));
  } else private.type := 1;
  if (is_numeric(intvl) && length(intvl) == 1) {
    private.intvl := max(0.25, min(100, intvl));
  } else private.intvl := 0.30;
  private.poptag := F;
  private.poptick := 0;
  private.popframe := F;
  private.popframex := F;
  private.mb3seen := F;
  private.myfr := F;
#
# Get correct help text
#
  private.maketext := function(ref myfr, ref txt) {
    if (is_agent(myfr) && is_string(txt)) return txt;
    else if (is_record(myfr) && is_function(txt)) {
      if (has_field(myfr, 'popwhere') &&
	  is_record(myfr.popwhere) && has_field(myfr.popwhere, 'device')) {
	local y := myfr.popwhere.device[2];
	local nam := '';
	if (has_field(myfr, 'nearest') && has_field(myfr, 'get') &&
	    is_function(myfr.nearest) && is_function(myfr.get)) {
	  y := myfr.nearest(y);
	  nam := myfr.get(y);
	  return txt(nam, y);
	} else if (is_agent(myfr)) {
	  y := myfr->nearest(y);
	  nam := myfr->get(y);
	  return txt(nam, y);
	};
      };
    };
    return F;
  }
#
# Make popup window
#
  private.makepop := function(ref myfr, ref text, widgetset=dws) {
    wider private;
    private.popframe := F;
    private.popframex := F;
    if (is_record(myfr) && is_string(text)) {
      if (has_field(myfr, 'listbox') && is_function(myfr.listbox)) {
	private.popframex := widgetset.frame(tlead=myfr.listbox(), tpos='s', 
					     background='black', width=0,
					     height=0, borderwidth=1,
					     padx=0, pady=0);
      } else if (is_agent(myfr)) {
	private.popframex := widgetset.frame(tlead=myfr, tpos='s', 
					     background='black', width=0,
					     height=0, borderwidth=1,
					     padx=0, pady=0);
      };
      if (is_agent(private.popframex)) {
	private.popframe := widgetset.frame(private.popframex, 
					    background='lightyellow',
					    width=0, height=0);
      };
      if (is_agent(private.popframe)) {
	private.popframe.lb01 := widgetset.message(private.popframe,
						   text=text, 
						   width=myfr.hlpwd,
						   relief='flat',
						   font='bold',
						   background='lightyellow');
      };
    };
    return is_agent(private.popframe);
  }
#
# The actual timer call-back function to generate popup help
#
  private.poptag := client('timer','-oneshot');
  whenever private.poptag->ready do {
    wider private;
    if (private.mb3seen) {
    } else if (is_agent(private.myfr) &&
	       has_field(private.myfr, 'hdtxt') &&
	       has_field(private.myfr, 'hlptxt')) {
      private.poptick +:= 1;
      if (private.poptick > 1) {
	local text := F;
	if (private.type == 1) {
	  text := private.maketext(private.myfr, private.myfr.hdtxt);
	} else {
	  text := private.maketext(private.myfr, private.myfr.hlptxt);
	};
	private.makepop(private.myfr, text, private.myfr.widgetset);
      } else private.poptag->interval(private.intvl);
    };
  }
#
# The popup events
#
  whenever self->mb3 do {
    wider private;
    myfr := ref $value;
    if ((private.type == 1 || private.type == 2) && 
	is_record(private.myfr) && myfr == private.myfr) {
      private.popframe := F;
      private.popframex := F;
      private.poptick := 0;
      private.mb3seen := F;
      local text := private.maketext(private.myfr, private.myfr.hlptxt);
      if (private.makepop(private.myfr, text, private.myfr.widgetset)) {
	  private.mb3seen := T;
      };
    };
  }
#
  whenever self->rmb3 do {
    wider private;
    myfr := ref $value;
    if ((private.type == 1 || private.type == 2) &&
	is_record(private.myfr) && myfr == private.myfr) {
      private.popframe := F;
      private.popframex := F;
      private.poptick := 0;
      private.mb3seen := F;
    };
  }
#
  whenever self->lve, self->btn do {
    wider private;
    private.popframe := F;
    private.popframex := F;
    private.poptick := 0;
    private.mb3seen := F;
    private.myfr := F;
  }
#
  whenever self->ent do {
    wider private;
    private.popframe := F;
    private.popframex := F;
    private.poptick := 0;
    private.mb3seen := F;
    private.myfr := F;
    if (is_agent($value)) {
      private.myfr := ref $value;
      if (private.type == 1 || private.type == 3) {
	private.poptag->interval(private.intvl);
      };
    };
  }
#
  whenever self->moti do {
    wider private;
    myfr := ref $value;
    private.poptick := 0;
    if (is_record(private.myfr) && myfr == private.myfr) {
      if (private.type == 1 || private.type == 3) {
	if (is_record(private.popframe) &&
	    is_record(private.popframex) && !private.mb3seen) {
	  private.popframe := F;
	  private.popframex := F;
	  private.poptag->interval(private.intvl);
	};
      };
    };
  }
#
# Data
#
  const self.type := function() {
    wider private;
    return private.type;
  }
#
  whenever self->settype do {
    wider private;
    if (is_integer($value) && length($value) == 1) {
      private.type := max(0, min(3, $value));
    } else private.type := 1;
  }
}
#
# Global methods
#
# popuphelp(tkagent, hlp, optional txt) will display the txt (as string)
# or calls the function txt for listboxes or agents with have a
# nearest() and get() and listbox() function. Display depends on the
# value of system.help.type: 0=none; 1=both; 2= long MB3; 3=long while
# hovering on agent. combi=T will combine txt and hlp.
#
const popuphelp := function(ref fr, txt=F, hlp=F, combi=F, width=60,
			    widgetset=dws) {
  global system;
# init popup system
  if (!is_agent(system.help.popup)) {
    const system.help.popup := 
      system.help.popupinit(system.help.type, system.help.intvl);
  };
  local wdth := width; 			#width of short help
  if (!is_record(fr)) {
    return throw('popuphelp - argument must be an agent or a record, ', 
		 'not a ', type_name(fr));
  };
  if (is_agent(fr) && !has_field(fr, 'killed')) {
    local longh := '';
    local shorth := '';
    if (is_string(hlp) || is_function(hlp)) {
      shorth := hlp;
      if (is_string(txt) || is_function(txt)) longh := txt;
      else {
	longh := shorth;
	if (is_string(shorth) && (shorth ~ m/^(.*[\n\.])/)) shorth := $m;
      };
    } else if (is_string(txt) || is_function(txt)) {
      longh := txt;
      if (is_string(txt) && (txt ~ m/^(.*[\n\.])/)) shorth := $m;
      else shorth := longh;
      if (is_string(shorth) && strlen(shorth) > wdth) {
	shorth := spaste(split(shorth, '')[1:wdth]);
      };
    };
    if (is_string(shorth) && strlen(shorth) > wdth) wdth := 30;
    if (is_string(shorth) && is_string(longh) && shorth != longh) {
      local a := '..';
      local b := '\n--Press right button for more--';
      if (strlen(shorth)>1 && split(shorth, '')[strlen(shorth)] == '\n') {
	shorth := spaste(split(shorth, '')[1:(strlen(shorth)-1)]);
	wdth -:= 1;
      };
      shorth := spaste(shorth, a, b);
      wdth +:= 2;
      wdth := max(wdth, strlen(b));
    };
    if ((is_string(shorth) && strlen(shorth) != 0) || is_function(shorth)) {
      fr.hlptxt := longh;
      fr.hdtxt := shorth;
      fr.hlpwd := wdth*7;
      fr.popwhere := 0;
      if (combi && is_string(hlp) && is_string(fr.hlptxt)) {
	fr.hlptxt := spaste(hlp, '\n', fr.hlptxt);
      };
# store the widgetset ref. in the agent
      fr.widgetset := widgetset;
      fr->bind('<Button-3>', 'mb3');
      fr->bind('<ButtonRelease-3>', 'rmb3');
      fr->bind('<Button>', 'btn');
      fr->bind('<Enter>', 'ent');
      fr->bind('<Leave>', 'lve');
      fr->bind('<Motion>', 'mot');
      whenever fr->["mb3 rmb3 lve btn"] do {
	global system;
	agent := ref $agent;
	system.help.popup->[$name](agent);
      }
      whenever fr->ent do {
	global system;
	agent := ref $agent;
	agent.popwhere := $value;
	system.help.popup->ent(agent);
      }
      whenever fr->mot do {
	global system;
	agent := ref $agent;
# Test for real motion
	if (!is_record(agent.popwhere) ||
	    agent.popwhere.device != $value.device) {
	  agent.popwhere := $value;
	  system.help.popup->moti(agent);
	};
      }
    };
  };
  return T;
}
#
# popupmenu(agent) will add a ? button with menu to the agent to select the
# type of popup: none, hover, MB3, both
#
# Added the buttonlabel argument, since '?' may not be too clear.
#
const popupmenu := function(ref agent, deflt=F,
			    relief='flat', buttonlabel='?',
			    widgetset=dws) {
  global system;
  if (is_defined('drc') && is_record(drc) && 
      has_field(drc, 'find') && is_function(drc.find)) {
    local x;			# otherwise Glish makes it global
    if (drc.findlist(x, 'help.popup.type', "none both mb3long hoverlong")) {
      system.help.type := x-1;
    };
  } else {
    if (is_integer(deflt)) system.help.type := as_integer(deflt);
  };
# init popup system
  if (!is_agent(system.help.popup)) {
    const system.help.popup := 
      system.help.popupinit(system.help.type, system.help.intvl);
  };
  system.help.popup->settype(as_integer(system.help.type));
  agent.popupbt0 := widgetset.button(agent, buttonlabel, type='menu',
				     relief=relief);
  popuphelp(agent.popupbt0, 'Popup help type', widgetset=widgetset);
  j := 0;
  agent.popupbt0.popupmenu := [=];
  for (i in ['No popup help', 'Short(hover) and long(MB3)',
	    'Long only(MB3)', 'Long only(hover)']) {
    agent.popupbt0.popupmenu[i] :=
      widgetset.button(agent.popupbt0, i, value=j, type='radio');
    if (j == system.help.popup.type() ||
	(j == 0 && (system.help.popup.type() < 0 ||
		    system.help.popup.type() > 3))) {
      agent.popupbt0.popupmenu[i]->state(T);
    };
    whenever agent.popupbt0.popupmenu[i]->press do {
      system.help.popup->settype(as_integer($value));
    };
    j +:= 1;
  };
  return T;
}
#
# popupremove(ag) will remove any popuphelp from the specified agent, and
# then set the agent to F. It works recursively from the bottom up.
# Necessary to stop some crashes if you just clean the agent.
#
# Just cleans out the global area after change.
#
const popupremove := function(ref ag=F, mxlevels=8) {
  global system;
# init popup system
  if (!is_agent(system.help.popup)) {
    const system.help.popup := 
      system.help.popupinit(system.help.type, system.help.intvl);
  };
  mxlevels  -:= 1;
  if (mxlevels <= 0) return;
  if (is_record(ag)) {
    for (i in field_names(ag)) {
      if (i == '*agent*') continue;
      if (is_record(ag[i])) popupremove(ag[i], mxlevels);
    };
    if (is_agent(ag)) {
      system.help.popup->lve(ag);
      val ag := F;
    };
  };
  return T;
}
#
# addpopuphelp(agents) scans record agents for agents will shorthelp field
# and add help
#
const addpopuphelp := function(ref agents, maxlevels=4,
			       widgetset=dws) { 
# avoid infinite recurse
  maxlevels -:= 1;
  if (maxlevels <= 0)  return;
# n.b. is_record returns T for an agent as well as a record.
  if (!is_record(agents)) {
    return throw('addpopuphelp - argument must be an agent or a record, ', 
		 'not a ', type_name(agents));
  };
  if (is_agent(agents) &&
      has_field(agents, 'shorthelp') && !has_field(agents, 'popwhere')) {
# Bind the current agent if it is one.
# Avoid infinite recurse if things reference each other
    popuphelp(agents, hlp=agents.shorthelp, widgetset=widgetset);
  };
# Recurse if possible
  for (i in field_names(agents)) {
    if (i == '*agent*') continue;
    if (is_record(agents[i]) && !has_field(agents[i], 'popwhere')) {
      addpopuphelp(agents[i], maxlevels, widgetset=widgetset);
    };
  };
  return T;
}
