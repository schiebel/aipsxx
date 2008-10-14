# menuframes.g: a widget for hiding and showing a frame and its contents
# Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: menuframes.g,v 19.2 2004/08/25 02:16:24 cvsmgr Exp $

#pragma include once;

include 'widgetserver.g';
include 'unset.g';

# The menuframes subsequence: standard sort of arguments.
# We need both the toplevel frame and the menubutton.
# Use exclusive=F to show more than one frame at once.

menuframes := subsequence(parent, menubutton, exclusive=T, widgetset=dws) {
  prvt := [=];
  
  if (!is_agent(parent)) {
    fail 'Parent is not an agent';
  }
  if (!is_agent(menubutton)) {
    fail 'Menubutton is not an agent';
  }

  prvt.frames := [=];
  prvt.menubutton := menubutton;
  prvt.parent := widgetset.frame(parent);
  prvt.exclusive := exclusive;
  if (!prvt.exclusive) {
      # this small frame serves to provide something for the packer to
      # do when all of the controlled frames are unmapped, which can only
      # happen when exclusive is false.  Otherwise, when they are all unmapped
      # prvt.parent assumes the size of last mapped frame.
      prvt.smallframe := widgetset.frame(prvt.parent, height=1, expand='none',
					 borderwidth=0);
  }
  prvt.enabled := T;
  prvt.buttons := [=];
  prvt.whenevers := [=];

  # many events are simply forwarded to each of the frames
  whenever self->["background bind borderwidth cursor disable disabled enabled exportselection font foreground justify relief view width"] do {
    wider prvt;
    for (i in field_names(prvt.frame)) {
      prvt.frames[i]->[$name]($value);
    }
  }

  # Add a frame and return the frame to be filled in
  self.add := function(title) {
    wider prvt;
    widgetset.tk_hold();
    if(!has_field(prvt.frames, title)||!is_agent(prvt.frames[title])) {
      prvt.frames[title] := widgetset.frame(prvt.parent);
    }
    if(!has_field(prvt.buttons, 'title')||!is_agent(prvt.buttons[title])) {
      if(prvt.exclusive) {
	prvt.buttons[title] := widgetset.button(prvt.menubutton,
						text=title, type='radio');
      }
      else {
	prvt.buttons[title] := widgetset.button(prvt.menubutton,
						text=title, type='check');
      }
      prvt.buttons[title]->state(T);
      prvt.buttons[title].title := title;
      whenever prvt.buttons[title]->press do {
	self.switch($agent.title, on=prvt.buttons[title]->state());
      }
      prvt.whenevers[title] := last_whenever_executed();
    }
    self.switch(title);
    widgetset.tk_release();
    return prvt.frames[title];
  }
 
  self.delete := function(title) {
    wider prvt;
    widgetset.tk_hold();
    prvt.frames[title]->unmap();
    if(has_field(prvt.whenevers, title)&&(prvt.whenevers[title]>0)) {
      deactivate prvt.whenevers[title];
    }
    val prvt.frames[title] := F;
    prvt.whenevers[title] := 0;
    prvt.buttons[title] := F;
    if(prvt.exclusive) {
      for (i in field_names(prvt.frames)) {
	if(is_agent(prvt.frames[i])&&(i!=title)) {
	  self.switch(i);
          break;
	}
      }
    }
    widgetset.tk_release();
    return T;
  }
  
  # use this to toggle the visible frame
  self.switch := function(title, on=T) {
    wider prvt;
    if(!has_field(prvt.frames, title)) return F;
    if(!is_agent(prvt.frames[title])) return F;
    # Only one frame on at once
    widgetset.tk_hold();
    if(prvt.exclusive) {
      # To switch on, switch others off first
      if(on) {
	for (i in field_names(prvt.frames)) {
	  if(is_agent(prvt.frames[i])) prvt.frames[i]->unmap();
	}
	prvt.frames[title]->map();
	prvt.buttons[title]->state(T);
      }
      # To switch off, switch any other on afterwards
      else {
	for (i in field_names(prvt.frames)) {
	  if(is_agent(prvt.frames[i])&&(i!=title)) {
	    self.switch(i);
	    break;
	  }
	}
      }
    }
    else {
      # Can have many frames on at once
      if(on) {
	prvt.frames[title]->map();
	prvt.buttons[title]->state(T);
      }
      else {
	prvt.frames[title]->unmap();
	prvt.buttons[title]->state(F);
      }
    }
    self->switch([title=title, state=on]);
    widgetset.tk_release();
    return T;
  }
  
  self.disable := function() 
  {
    if (prvt.enabled) {
      wider prvt;
      prvt.parent->disable();
      prvt.enabled := F;
    }
    return T;
  }

  self.enable := function() 
  {
    if (!prvt.enabled) {
      wider prvt;
      prvt.parent->enable();
      prvt.enabled := T;
    }
    return T;
  }

  self.done := function ()
  {
    wider prvt;
    for (i in field_names(prvt.whenevers)) {
      if(prvt.whenevers[i]>0) deactivate prvt.whenevers[i];
    }
    for (i in field_names(prvt.frames)) {
      if(is_agent(prvt.frames[i])) prvt.frames[i]:=F;
    }
    val prvt := F;
    val self := F;
    return T;
  }
  
  self.getstate := function() {
    wider prvt;
    result := [=];
    for (i in field_names(prvt.buttons)) {
      result[i] := prvt.buttons[i]->state();
    }
    return result;
  }

}
