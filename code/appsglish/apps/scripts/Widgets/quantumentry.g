# quantumentry.g: Standalone gui for quantum entry to supplement guientry.quantity
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
# $Id: 


pragma include once

include 'clipboard.g'
include 'unset.g'
include 'illegal.g'
include 'quanta.g'
include 'widgetserver.g'
include 'note.g'
include 'serverexists.g'

const quantumentry := subsequence (ref parent=F, list, default=unset, help=unset, 
                                   havespanner=T, havestatus=T, widgetset=dws)
{
   if (!serverexists('dq', 'quanta', dq)) {
       throw ('dq is either not running or not valid',
               origin='quantumentry.file');
   }
#
   its := [=];
   its.f0 := [=];              # Top frame
   its.entry := [=];           # Entry widget
   its.value := [=];           # Widget value
   its.unit := [=];            # Unit optionmenu widget
   its.unitlist := list;       # List of allowed units
#
   its.help := help;
#
   its.spanner := [=];         # Spanner button widget
   its.spanner.have := havespanner;
   its.spanner.button := [=];
   its.spanner.menu := [=];
   its.spanner.menu.buttons := [=];
   its.spanner.menu.list := "Copy Paste Clear Unset";
#
   its.status := [=];          # Status indicator
   its.status.have := havestatus;
   its.status.button := [=];
#
   its.frameresources := widgetset.resources('frame');   


### Private functions

   const its.setIllegal := function (emit=T)
   {
      wider its;
#
      if (its.status.have) {
         its.status.button->bitmap('cross.xbm');
         its.status.button->foreground('red');
         its.status.button->background('black');
      }
      its.value := illegal;
      if (emit) self->value(illegal);
      return T;
    }

###
   const its.setLegal := function (value=unset, emit=T)
   {
      wider its;
#
      if (its.status.have) {
         its.status.button->bitmap('tick.xbm');
         its.status.button->background(its.frameresources.background);
         its.status.button->foreground('darkgreen');
      }
      if (!is_unset(value)) its.value := value;
      if (emit) self->value(its.value);
      return T;
    }

###
   const its.setUnset := function (emit=T)
   {
      wider its;
#
      its.entry->delete('start', 'end');
      its.entry->background("yellow");
      its.entry->foreground("black");
      its.entry->insert('<unset>');
      its.value := unset;
      return its.setLegal(emit=emit)
    }

### Public Functions

###
   const self.clear := function ()
   {
      its.entry->delete('start', 'end');
      its.entry->background("white");
      return T;
   }

###
   const self.disable := function (disable=T)
   {
      wider its;
#
      if (disable) {
         its.entry->disabled(T);
         return its.unit.disabled(T);
      } else {
         its.entry->disabled(F);
         return its.unit.disabled(F);
      }
   }

###
   const self.done := function ()
   {
      wider its, self;
      its.unit.done();
#
      val its := F;
      val self := F;
      return T;
   }

###
   const self.get := function (reread=F) 
   {
      wider its;
#
     if (reread) {
        ok := self.insert(its.entry->get(), emit=F);
        if (is_fail(ok)) fail;
     } 
#
     return its.value;
   }

###
   const self.getunit := function () 
   {
     return its.unit.getlabel();
   }

###
   const self.getunitlist := function () 
   {
     return its.unitlist;
   }

###
   const self.insert := function (value, emit=T)
   {
     wider its;
#
     if (is_unset(value)) {
        return its.setUnset(emit=emit);
     } else if (is_illegal(value)) {
        return its.setIllegal(emit=emit);
     }
     if (is_string(value)) {
        if (value=='<unset>') {
           return its.setUnset(emit=emit);
        } else if (value=='<illegal>') {
           return its.setIllegal(emit=emit);
        }
     }
#
     v := value;
     if (!is_quantity(value)) {

# See if we can make a quantum directly from it (e.g. a string).  

        if (is_string(value) && dq.check(value)) {      # Legal unit
           v := dq.quantity(value);  
           if (is_fail(v)) {
              its.setIllegal(emit=emit);
              return F;
           }

# Unfortunately,  dq.quantity('10') will make a legal quantum... Test for that.

           ok := T;
           u := dq.getunit(v);
           l := length(u);
           if (l==0) ok := F; 
           if (l==1 &&  u=='') ok := F; 
#
           if (!ok) {

# We don't have any units.  Give it some.

              t := dq.getvalue(v);
              v := dq.quantity(t, its.unit.getlabel());
              if (is_fail(v)) {
                 its.setIllegal(emit=emit);
                 return F;
              }
           }
        } else if (is_numeric(value)) {

# It's just a number.  Give it a unit

           v := dq.quantity(as_double(value), its.unit.getlabel());
           if (is_fail(v)) {
              its.setIllegal(emit=emit);
              return F;
           }
        } else {

# It was neither a quantum nor a valid quantum string
# nor a numeric value so it's illegal

           its.setIllegal(emit=emit);
           return F;
        }
     }

# By now, 'v' should be a legal quantum.
# See if unit is in the widget list

     u := dq.getunit(v);
     n := length(its.unitlist);
     idx := 0;   
     for (i in 1:n) {
        if (u == its.unitlist[i]) {
           idx := i;
           break;        
        }
     }

# If not found, perhaps we can convert it ?

     v2 := v;
     if (idx==0) {
        for (i in 1:n) {
          if (dq.compare(v, its.unitlist[i])) {
             v2 := dq.convert(v, its.unitlist[i]);
             if (is_fail(v2)) {
                its.setIllegal(emit=emit);
                return F;
             } else {
               idx := i;
             }
           }
        }
     }
#
     if (idx==0) {
        its.setIllegal(emit=emit);
        return F;
     }
         
# Select unit in menu

     its.unit.selectindex(idx);

# Insert

     self.clear();
     s := as_string(dq.getvalue(v2));
     if (is_fail(s)) fail;
     its.entry->insert(s);
     its.setLegal(v2, emit=emit);
#
     return T;
   }

###
   self.replaceunitmenu := function (list, width=-1)
   {
      wider its;
#
      ok := its.unit.replace(labels=list, width=width);
      if (!is_fail(ok)) {
         its.unitlist := list; 
      }
      return ok;
   }

###
   self.setwidth := function (width) 
   {

      wider its;
#
      its.entry->width(width);
      return T;
   }

###
   self.setunitwidth := function (width) 
   {
      wider its;
#
      return its.unit.setwidth(width);
   }

### Constructor


# Top level frame
 
   if (is_boolean(parent) && parent==F) widgetset.tk_hold();
   its.f0 := widgetset.frame(parent, side='left', expand='none');
   if (is_boolean(parent) && parent==F) {
     its.f0->unmap();
     widgetset.tk_release();
   }

# Make entry

   its.entry := widgetset.entry (its.f0, width=10, fill='none');
   whenever its.entry->return do {
      self.insert(its.entry->get(), emit=T);
      self->carriageReturn(its.value)
   }
   if (!is_unset(its.help)) {
      widgetset.popuphelp(its.entry, its.help, combi=T);
   }

# Make units menu

   its.unit := widgetset.optionmenu (parent=its.f0, labels=its.unitlist);
   whenever its.unit->select do {
      self->unitchange($value);
   }

# Make the spanner

   if (its.spanner.have) {
      its.spanner.button :=  widgetset.button(its.f0, 'Menu', bitmap='spanner.xbm',
                                              type='menu', relief='raised');
      widgetset.popuphelp(its.spanner.button, 'Menu for various operations on the entry');
      for (i in 1:length(its.spanner.menu.list)) {
         its.spanner.menu.buttons[i] := widgetset.button(its.spanner.button, 
                                                         its.spanner.menu.list[i], 
                                                         value=its.spanner.menu.list[i]);
         whenever its.spanner.menu.buttons[i]->press do {
            if ($value=='Copy') {
               dcb.copy(its.value);
            } else if ($value=='Paste') {
               self.insert(dcb.paste());
            } else if ($value=='Clear') {
               self.clear();
            } else if ($value=='Unset') {
               self.insert(unset);
            }
         }
      }
   }

# Status indicator

  if (its.status.have) {
     its.status.button := widgetset.button(its.f0, bitmap='tick.xbm');
  }
#
  its.setLegal();

  if (is_boolean(parent) && parent==F) its.f0->map();

# Insert default value

  ok := self.insert(default);
  if (is_fail(ok)) fail;
}
