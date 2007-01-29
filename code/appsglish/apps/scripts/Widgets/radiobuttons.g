# radiobuttons.g: widget handling multiple radiobuttons 
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: 
#
#
 
pragma include once

include 'note.g'
include 'widgetserver.g'
include 'unset.g'


const radiobuttons := subsequence(ref parent=F, names, 
                                  default=1, side='left',
                                  widgetset=dws)
{
   if (!is_string(names)) {
      return throw('The "names" variable must be a string',
                    origin='radiobuttons.g');
   }
   if (!is_integer(default)) {
      return throw('The "default" variable must be an integer',
                    origin='radiobuttons.g');
   }
#
   prvt := [=]; 
   prvt.isDisabled := F;
   prvt.names := names;
   prvt.value := [=];
   prvt.default := default;
   if (default>length(names)) prvt.default := -1;
#
   widgetset.tk_hold();
   prvt.f0 := widgetset.frame(parent, side=side, expand='x');
   prvt.f0->unmap();
   widgetset.tk_release();
#
   const n := length(prvt.names);
   for (i in 1:n) {
      fN := spaste('b', i);
      prvt.f0[fN] := widgetset.button(parent=prvt.f0, 
                                      type='radio', text=names[i]);
      prvt.f0[fN]['index'] := i;
      whenever prvt.f0[fN]->press do {
        rec := [=];
        rec.name := prvt.names[$agent.index];
        rec.index := $agent.index;
        prvt.value := rec;
        self->value(rec);
      }
   }
   if (prvt.default>0) {
      fN := spaste('b', prvt.default);
      prvt.f0[fN]->state(T);
#
      rec := [=];
      rec.name := prvt.names[prvt.default];
      rec.index := prvt.default;
      prvt.value := rec;
   }
   prvt.f0->map();

###
   const self.disabled := function (disable=T, allbuttons=F)
   {
#
# WHen disabling, just parent frame is disabled.
# When enabling, parent frame is enabled.  But the
# buttons states are lefts as they are.  You can
# force them on if you wish
#
      wider prvt;
      if (disable) {
         if (!prvt.isDisabled) prvt.f0->disable();
      } else {
         if (prvt.isDisabled) prvt.f0->enable();    
      }
      prvt.isDisabled := disable;
#  
      if (allbuttons) {
         if (disable) {
            for (i in 1:length(prvt.names)) {  
               fN := spaste('b', i);
               prvt.f0[fN]->disabled(T);
            }
         } else {
            for (i in 1:length(prvt.names)) {  
               fN := spaste('b', i);
               prvt.f0[fN]->disabled(F);
            }
         }
      }
      return T;
   }


###
   const self.disablebutton := function (idx)
#
# Sets the state of the button to off
# and disables it.  Does not look at
# whether the whole widget is enabled or not
#
   {
      if (self.setstate(idx, F)) {
         wider prvt;
         fN := spaste('b', idx);
         prvt.f0[fN]->disabled(T);
      }
      return T;
   }
 
###
   const self.enablebutton := function (idx)
#
# State of button is not changed
#
   {
      if (idx>0 && idx<=length(prvt.names)) {
         wider prvt;
         fN := spaste('b', idx);
         prvt.f0[fN]->disabled(F);
      }
      return T;
   }


###
   const self.done := function ()
   {
      wider prvt, self;
      val prvt := F;
      val self := F;
      return T;
   }

###
   const self.setstate := function (idx, state)
#
# allowed is all off or one on
#
   {
      if (idx>0 && idx<=length(prvt.names)) {
         wider prvt;
         fN := spaste('b', idx);
#
# The basic radio button widget will turn off the other ones
# if they are on
#
         prvt.f0[fN]->state(state);
#
         allOff := T;
         for (i in 1:length(prvt.names)) {
            fN := spaste('b', i);
            if (prvt.f0[fN]->state()) {
               allOff := F;
               idx := i;
               break;
            }
         }
#
         rec := [=];
         if (!allOff) {
            rec.name := prvt.names[idx];
            rec.index := idx;
         }
         prvt.value := rec;
         return T;
      }
      return F;
   }



###
   const self.getvalue := function ()
   {
      return prvt.value;
   }


###
   const self.reset := function (idx=-1)
   {
      wider prvt;
      const n := length(prvt.names);
      for (i in 1:n) {
         fN := spaste('b', i);
         prvt.f0[fN]->state(F);
      }
      prvt.value := [=];
      if (idx > 0) self.setstate(idx, T);
      return T;
   }
}
