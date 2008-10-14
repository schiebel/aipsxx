# checkmenu.g: a widget for creating a menu containing check box items
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
#   $Id: checkmenu.g,v 19.2 2004/08/25 02:12:10 cvsmgr Exp $

 
pragma include once
include 'widgetserver.g'

const checkmenu := subsequence (ref parent, label='checkmenu', names="", 
                                values="", hlp='', hlp2='', padx=7, 
                                pady=3, width=0,
                                height=1, justify='center', font='', 
                                relief='groove', borderwidth=2,
                                foreground='black', background='lightgrey',
                                disabled=F, anchor='c',
                                fill='none', widgetset=dws)
{
   include 'note.g'
   if (!is_agent(parent)) {
      return throw ('Variable "parent" must be an agent', origin='checkmenu');
   }

   private := [=];
   private.empty := T;
   private.holder := [=];         # Holder of parent frame
   private.menu := [=];           # Menu button
   private.data := [=];           # names, values
   private.isenabled := T;

###
   private.buildSubMenu := function ()
   {
      wider private;
#
      private.data.whenevers := [];
      const nNames := length(private.data.names);
      if (nNames>0) {
         private.empty := F;
         for (i in 1:nNames) {
            field := spaste(i);
            private.menu[field] := widgetset.button(parent=private.menu,
                                                    type='check',
                                                    text=private.data.names[i], 
                                                    value=private.data.values[i],
                                                    font=font, 
                                                    foreground=foreground,
                                                    background=background);
            private.menu[field]['index'] := i;
#
            whenever private.menu[field]->press do {
               ag := $agent;
               idx := ag.index;
               private.data.states[idx] := ag->state();
#
               result := [=];
               result.name := private.data.names[idx];
               result.value := private.data.values[idx];
               result.state := ag->state();
               result.index := idx;
               self->select(result);
            }
            private.data.whenevers[i] := last_whenever_executed();
         }
      }
   }


###
   private.checkInputs := function (ref names, ref values)
   {
      nNames := length(names);
      if (nNames>0 && !is_string(names)) {
         return throw('The "names" variable must be a string', 
                      origin='checkmenu');
      }

      nValues := length(values);      
      if (nValues>0 && nValues!=nNames) {
         msg := 'The "values" variable must be the same length as the "names" variable';
         return throw(msg, origin='checkmenu');
      }
      if (nValues==0) val values := names;
      return T;
   }



###
   private.setMenu:= function (names, values)
   {
      wider private;
      private.data.names := names;
      private.data.values := values;
      if (length(private.data.names)>0) {
         private.data.states := array(F,length(names));
      } else {
         private.data.states := [];
      }
      return T;
   }

###
   const self.disabled := function (disable=T)
   {
      wider private;
      private.menu->disabled(disable);      
      private.isenabled := !disable;
      return T;
   }


###
   const self.extend := function (names="", values="")
   {
#
# Check inputs
#
      check := private.checkInputs(names, values);
      if (is_fail(check)) fail;
#
# Add to existing list.  Fails occur if types are inconsistent
#
      if (length(private.data.names)>0) {
         newnames := [private.data.names, names];      
      } else {
         newnames := names;
      }
      if (is_fail(newnames)) fail;
      if (length(private.data.values)>0) {
         newvalues := [private.data.values, values];      
      } else {
         newvalues := values;
      }
      if (is_fail(newvalues)) fail;
#
# Replace menu
#
      text := private.menu->text();
      states := m.getstates();
      self.replace(text, newnames, newvalues, width=-1);
#
# Put states back the way they were for the
# pre-extension menu
#
      for (i in 1:length(states)) self.selectindex(i,states[i]);
#
      return T;
   }


###
   const self.findname := function (name)
   {
      if (private.empty) return F;
#
      const nNames := length(private.data.names);
      for (i in 1:nNames) {
         if (private.data.names[i] == name) return i;
      }
      return F;
   }

###
   const self.findvalue := function (value)
   {
      if (private.empty) return F;
#
      const nNames := length(private.data.names);
      for (i in 1:nNames) {
         if (private.data.values[i] == value) return i;
      }
      return F;
   }


###
   const self.getlabel := function ()
   {
      return private.menu->text();
   }   


###
   const self.getvalues := function ()
   {
      return private.data.values;
   }   


###
   const self.getnames := function ()
   {
      return private.data.names;
   }   


###
   const self.getstate := function (idx)
   {
      if (private.empty) {
         return throw('Empty menu', origin='checkmenu');   
      } else if (idx > length(private.data.names)) {
         return throw ('Invalid index', origin='checkmenu');   
      } else {
         return private.data.states[idx];
      }
   }

###
   const self.getstates := function ()
   {
      return private.data.states;
   }   

###
   const self.getonstates := function ()
   {
      states := self.getstates();
      return ind(states)[states==T];
   }      
          
###       
   const self.getoffstates := function ()
   {
      states := self.getstates();
      return ind(states)[states==F];
   }   


###
   const self.isenabled := function ()
   {
      return private.isenabled;
   }


###
   const self.replace := function (label='checkmenu', names="", 
                                   values="", width=0)
#
# width=-1 means dont change button width
#
   {
#
# Check inputs
#
      check := private.checkInputs(names, values);
      if (is_fail(check)) fail;
#
# Store inputs internally
#
      private.setMenu(names, values);
#
# Shut down old menu items
#
      widgetset.tk_hold();
      wider private;
      for (i in length(private.data.whenevers):1) {
         field := spaste(i);
         val private.menu[field] := F;
         deactivate private.data.whenevers[i];
      }
#
# Build menu and change label and width parameters
#
      self.setlabel(label, width);
#
      private.buildSubMenu();
      widgetset.tk_release();
#
# Send out event
#
      self->replaced();
#
      return T;
   }



###
   const self.reset := function ()
   {
      wider private;
      for (i in 1:length(private.data.names)) {
         field := spaste(i);
          private.menu[field]->state(F);
          private.data.states[i] := F;
      }
      return T;
   }


###
   const self.selectindex := function (idx, state='swap')
   {
      if (!is_integer(idx)) {
         msg := 'The variable "idx" must be an integer';
         note (msg, priority='WARN', origin='checkmenu');   
         return F;
      }
      swap := F;
      if (is_string(state)) {
         swap := T;
      } else {
         if (!is_boolean(state)) {
            msg := 'The variable "state" must be boolean';
            note (msg, priority='WARN', origin='checkmenu');   
            return F;
         }
      }
#
      if (private.empty) {
         msg := 'There are no entries in the menu';
         note (msg, priority='WARN', origin='checkmenu');   
         return F;
      }
#
      wider private;
      const nNames := length(private.data.names);
      if (idx<1 || idx>nNames) {
         msg := spaste('Index not in the range [1,',
                       nNames, ']');
         note (msg, priority='WARN', origin='checkmenu');   
         return F;
      }
#
      widgetset.tk_hold();
      field := spaste(idx);
      state2 := state;
      if (swap) state2 := !self.getstate(idx);
      private.menu[field]->state(state2);
      private.data.states[idx] := state2;
      widgetset.tk_release();
      return T;
   }


###
   const self.selectname := function (name, state='swap')
   {
      idx := self.findname(name);
      if (idx==F) return F;
      return self.selectindex(idx, state);
   }

###
   const self.selectvalue := function (value, state='swap')
   {
      idx := self.findvalue(value);
      if (idx==F) return F;
      return self.selectindex(idx, state);
   }


###
   const self.setbackground := function (color)
   {
       private.menu->background(color);
       return T;
   }

###
   const self.setforeground := function (color)
   {
       private.menu->foreground(color);
       return T;
   }



###
   const self.setlabel := function (label, width=-1)
#
# width=-1 means don't change button width.  if the button
# width is 0 (autoscale), it will still autoscale
#
   {
       wider private;
       widgetset.tk_hold();
       private.menu->text(label);
       if (width==-1) {
          width2 := private.menu->width();
          private.menu->width(width2);
       } else {
          private.menu->width(width);
       }
       widgetset.tk_release();
       return T;
   }



###
#
# Here is the constructor
#
# Checks
#
   check := private.checkInputs(names, values);
   if (is_fail(check)) fail;
#
# Store menu inputs internally
#
   private.setMenu(names, values);
#
# Create menu button
#
   private.holder := parent;
   private.menu := widgetset.button(parent=private.holder, type='menu', 
                                    text=label,
                                    padx=padx, pady=pady, width=width,
                                    height=height, justify=justify,
                                    font=font, relief=relief, 
                                    borderwidth=borderwidth,
                                    foreground=foreground,
                                    background=background,
                                    disabled=disabled, 
                                    anchor=anchor, 
                                    fill=fill);
#
   if (strlen(hlp)>0) {
      if (strlen(hlp2)==0) {
         widgetset.popuphelp(private.menu, hlp);
      } else {
         widgetset.popuphelp(private.menu, hlp2, hlp, combi=T);
      }
   }
#
# Add submenu and service 
# 
   private.buildSubMenu();
}
