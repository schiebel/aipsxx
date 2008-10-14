# regionentry.g: Standalone gui for region entry to supplement guientry.region
# Copyright (C) 1996,1997,1998,1999,2000,2001
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
# $Id: regionentry.g,v 19.2 2004/08/25 02:18:29 cvsmgr Exp $



pragma include once

include 'regionmanager.g'
include 'widgetserver.g'
#
include 'clipboard.g'
include 'illegal.g'
include 'unset.g'
include 'note.g'
include 'serverexists.g'

const regionentry := subsequence (ref parent=F, widgetset=dws)
{
   if (!serverexists('drm', 'regionmanager', drm)) {
       throw ('drm is either not running or not valid',
               origin='regionentry.file');
   }
#
   its := [=];
   its.f0 := [=];              # Top frame
   its.entry := [=];           # Entry widget
   its.value := [=];           # Widget value
   its.spanner := [=];         # Spanner button widget
   its.spanner.button := [=];
   its.spanner.menu := [=];
   its.spanner.menu.buttons := [=];
   its.spanner.menu.list := "Copy Paste Clear Unset";
   its.status := [=];          # Status indicator
#
   its.frameresources := widgetset.resources('frame');   


### Private functions

###
   const its.setIllegal := function ()
   {
      wider its;
#
      its.status->bitmap('cross.xbm');
      its.status->foreground('red');
      its.status->background('black');
      return T;
    }

###
   const its.setLegal := function ()
   {
      wider its;
#
      its.status->bitmap('tick.xbm');
      its.status->background(its.frameresources.background);
      its.status->foreground('darkgreen');
#
      return T;
    }

###
   const its.setValue := function (value)
   {
      wider its;
#
      if (is_region(value)) {
         self.clear();
         its.entry->insert ('<Region>');
         its.setLegal();

# If I just assign the itemcontainer directly I get into
# reference trouble; regions lose their references to
# their function.  Going via a record seems to solve this...
# I have no idea whose responsibility it is to destroy
# the made itemcontainer !

         rec := value.torecord();
         i := itemcontainer();
         i.fromrecord(rec);
         its.value := i;
      } else if (is_unset(value)) {
         self.clear();
         its.entry->insert ('<unset>');
         its.entry->background('yellow');
         its.setLegal();
         its.value := value;
       } else {
         self.clear();
         its.setIllegal();
         its.value := illegal;
       }
#
      return T;
   }
   

### Public Functions

###
   const self.clear := function (setunset=F)
   {
      wider its;
#
      its.entry->delete('start', 'end');
      its.entry->background('white');
      if (setunset) its.value := unset;
      return T;
   }

###
   const self.disable := function ()
   {
      its.entry->disabled(T);
   }

###
   const self.done := function ()
   {
      wider its, self;
#
      val its := F;
      val self := F;
      return T;
   }

###
   const self.enable := function ()
   {
      its.entry->disabled(F);
   }


###
   const self.get := function () 
   {
     wider its;
#
     return its.value;
   }


###
   const self.insert := function (value)
   {
     wider its;
#
     v := value;
     if (is_string(value)) {
        if (is_defined(value)) {
           v := symbol_value(value);
        }
     }
#
     local ok;
     if (!is_unset(v) && !is_region(v)) {
        ok := its.setValue(illegal);
     } else {
        ok := its.setValue(v);
     }
#
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


### Constructor


# Top level frame
 
   if (is_boolean(parent) && parent==F) widgetset.tk_hold();
   its.f0 := widgetset.frame(parent, side='left');
   if (is_boolean(parent) && parent==F) {
     its.f0->unmap();
     widgetset.tk_release();
   }

# Make entry

   its.entry := widgetset.entry (its.f0);
   whenever its.entry->return do {
      s := its.entry->get();
      self.insert(s);
   }

# Make the spanner

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
            xxx := dcb.paste();
            self.insert(xxx);
         } else if ($value=='Clear') {
            self.clear(setunset=T);
         } else if ($value=='Unset') {
            its.setValue(unset);
         }
      }
   }

# Status indicator

  its.status := widgetset.button(its.f0, bitmap='tick.xbm');
  its.setLegal();
  if (is_boolean(parent) && parent==F) its.f0->map();

# Insert unset as initial value

   self.insert(unset);

}
