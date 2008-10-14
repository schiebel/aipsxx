# editfitlist.g: GUI to edit componentlist 
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: editfitlist.g,v 19.3 2004/08/25 00:56:31 cvsmgr Exp $
#
#
# Emits events
#
#  Name               Value
#    delete            indices deleted
#
 
pragma include once

include 'componentlist.g'
include 'note.g'
include 'unset.g'
include 'viewershowcomponentlist.g'
include 'widgetserver.g'

const editfitlist := subsequence (parent=F, ddd=unset, allowdeletefirst=T, 
                                  widgetset=dws)
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment variable is not set',
                   origin='editfitlist.g');
   }
#
   its := [=];
   its.parent := parent;
   its.list := [=];      # Record of componentlists
   its.om := [=];        # Fit selection index
   its.show := [=];      
   its.hide := [=];      
   its.delete := [=];      
   its.listbox := [=];   # Listbox for component listing
   its.showing := [=];   # Are we showing this list on the ddd
   its.listidx := 0;     # What list is presently in the listbox
   its.counter := [=];      # Counter
#
   its.ddd := ddd;       # drawing display data server
   its.vscl := viewershowcomponentlist(ddd=its.ddd);
   if (is_fail(its.vscl)) fail;

   its.dddIDs := [=];    # DDD Ids indexed by componentlist idx.


#### Private functions


###
   const its.deleteindex := function (idx=unset)
   {
      wider its;
#
      n2 := 0;
      names := its.om.getnames();
      names2 := "";
      showing2 := as_boolean([]);
      which := [];
#
      if (is_unset(idx)) {

# Do them all in

         list2 := [=];
         n := length(its.list);
         if (n==0 || (!allowdeletefirst && n==1)) return [];
#
         start := 1;
         if (!allowdeletefirst) start := 2;
         j := 1;
         for (i in start:n) {
            which[j] := i;
            its.list[i].done();
            if (its.showing[i]) {
              ok := its.vscl.hide(its.dddIDs[i]);
            }
            j +:= 1;
         }
#
         if (!allowdeletefirst) {                           
            list2[1] := emptycomponentlist(log=F);
            ok := list2[1].concatenate(its.list[1], log=F);
            if (is_fail(ok)) fail;
            names2[1] := names[1];
            showing2[1] := its.showing[1];
         }
#
         if (allowdeletefirst || its.listidx!=0) {
            its.listbox->delete('start', 'end');
            its.listidx := 0;
         }
#
         its.showing := showing2;
         its.list := list2;
         n2 := length(its.list);
      } else if (is_integer(idx) && idx>0) {
         if (idx==1 && !allowdeletefirst) {
            note ('You are not allowed to delete this entry',
                  origin='editfitlist.delete', priority='WARN');
            return [];
         }

# Remove from displays

         if (idx>1 || (idx==1 && allowdeletefirst)) {
            which := idx;
            if (idx==its.listidx) {
               its.listbox->delete('start', 'end');
               its.listidx := 0;
            }
#
            if (its.showing[idx]) {
               ok := its.vscl.hide(its.dddIDs[idx]);
               its.showing[idx] := F;
            }

# Now we must copy all of the entries but the deleted one.
# This is very expensive

            list2 := [=];
            n := length(its.list);
            j := 1;
            for (i in 1:n) {
               if (i==idx) {
                  its.list[i].done();
               } else {
                  list2[j] := emptycomponentlist(log=F);
                  ok := list2[j].concatenate(its.list[i], log=F);
                  if (is_fail(ok)) fail;
                  if (i==1) {
                     names2[j] := names[i];
                  } else {

# Should not do this.  It's really the callers responsibility
# to name the entries in 'replacelistitem'.  I cant be bothered
# reworking this right now.  If I don't do this the names don't
# shuffle down.  It's all because I keep 'Current + accepted[1:n]

                     names2[j] := as_string(j-1);
                  }
                  showing2[j] := its.showing[i];
                  if (its.listidx==i) its.listidx := j;
#
                  j +:= 1;
               }
            }
            n2 := j - 1;
            its.list := list2;
            its.showing := showing2;
         }
      }
      its.showing := showing2;
      if (n2 > 0) {
         ok := its.om.replace(names2, names2, names2);
      } else {
         ok := its.om.replace();
      }
      if (is_fail(ok)) fail;
#
      return which;
   }

###
   const its.insertcomponentlist := function (componentlist, im=unset)
   {
      wider its;
#
# Set print precision
#
      global system;
      local prec;
      if (has_field(system, 'print') && has_field(system.print, 'precision')) {
         prec := system.print.precision;
      }
      system.print.precision := 6;
#
      its.listbox->delete('start', 'end');
      const n := componentlist.length();
      for (i in 1:n) {
         componentShape := componentlist.getshape(i);
         componentType := to_upper(componentlist.shapetype(i));
         its.listbox->insert(spaste('Component ', i, ' of type ', componentType));
#
         if (i>1) {  
            its.listbox->insert('');
         }
         fluxValues := componentlist.getfluxvalue(i);
         fluxUnit := componentlist.getfluxunit(i);
         fluxErrors := componentlist.getfluxerror(i);

# Convert to peak and list if image supplied

         if (is_image(im)) {
            f2 := fluxValues;
            ef2 := fluxErrors;
            for (j in 1:length(fluxValues)) {
               if (fluxValues[j]>0.0) {              
                  intFlux := dq.quantity(fluxValues[j], fluxUnit);
                  peakFlux := im.convertflux(value=intFlux, topeak=T,
                                             major=componentShape.majoraxis,
                                             minor=componentShape.minoraxis,
                                             type=componentType);
                  f2[j] := dq.getvalue(peakFlux);
               }
               if (fluxErrors[j]>0.0) {              
                  ef2[j] := fluxErrors[j] / fluxValues[j] * f2[j];
               }
            }
            its.listbox->insert(spaste('Peak Flux : ', f2, ' (', ef2, ') ', im.brightnessunit()));
         }

# List integral flux

         its.listbox->insert(spaste('Int  Flux : ', fluxValues, ' (', fluxErrors, ') ',
                                    fluxUnit));
#
         lon := componentlist.getrefdirra(i, 'time', 12)
         lat := componentlist.getrefdirdec(i, 'angle', 11);
         lonError := componentlist.getdirerrorlong(i);;
         latError := componentlist.getdirerrorlat(i);
#
         lonError := dq.convert(lonError, 'arcsec');
         lonStr := dq.tos(lonError, prec=9);
#
         latError := dq.convert(latError, 'arcsec');
         latStr := dq.tos(latError, prec=9);
#
         its.listbox->insert(spaste('RA/DEC : ', lon, '  ', lat, ' ',
                             '(', lonStr, ' ', latStr, ')'));

# Convert location to pixels if image given

         if (is_image(im)) {
            w := [=];
            w.direction := componentlist.getrefdir(i);
            p := im.topixel(w);
            if (!is_fail(p)) {
               its.listbox->insert(spaste('         ', p, ' absolute pix'));
            }
         }
#
         if (componentType=='GAUSSIAN' || componentType=='DISK') {
            componentlist.convertshape(i, componentShape.majoraxis.unit,
                                       componentShape.minoraxis.unit,
                                       'deg');
            componentShape := componentlist.getshape(i);
            componentShapeErrors := componentlist.getshapeerror(i);
#
            its.listbox->insert(spaste('Major axis : ', componentShape.majoraxis.value,
                                       ' (', componentShapeErrors.majoraxis.value, ') ',
                                       componentShape.majoraxis.unit));
            its.listbox->insert(spaste('Minor axis : ', componentShape.minoraxis.value,
                                       ' (', componentShapeErrors.minoraxis.value, ') ',
                                       componentShape.minoraxis.unit));
            its.listbox->insert(spaste('Position angle : ', componentShape.positionangle.value,
                                       ' (', componentShapeErrors.positionangle.value, ') ',
                                       componentShape.positionangle.unit));
         } else if (componentType=='POINT') {
         }
      }
      its.listbox->see('start');
# 
      system.print.precision := prec;
      return T;
   }


###
   const its.donelist := function ()
   {
      wider its;
#
      n := length(its.list);
      if (n > 0) {
         for (i in 1:n) {
            ok := its.list[i].done();
         }
      }
#
      return T;
   }



#### Public functions

###
   const self.dismiss := function ()
   {
       wider its;
       its.f0->unmap();
#
       return T;
   }

###
   const self.done := function ()
   {
      wider its;
#
      ok := its.donelist();
      ok := its.om.done();
      ok := its.listbox.done();
      ok := its.show.done();
      ok := its.hide.done();
      ok := its.delete.done();
#
      val its := F;
      val self := F;
#
      return T;
   }

###
   const self.getlist := function ()
   {
      wider its;
      return its.list;
   }

###
   const self.gui := function ()
   {
       wider its;
       return its.f0->map();
   }

###
   const self.hideall := function ()
#
# Clear all overlays
#
   {
      wider its;
#
      n := length(its.list);
      if (n > 0) {
         for (i in 1:n) {
            if (its.showing[i]) {
              ok := its.vscl.hide(its.dddIDs[i]);
              its.showing[i] := F;
            }
         }
     }
#
     return T;
   }

###
   const self.replacelistitem := function (componentlist, name, im=unset, index=unset, list=T)
   {
      wider its;
#
      if (!is_componentlist(componentlist)) { 
         return throw ('Given Componentlist is invalid', origin='editfitlist.replacelistitem');
      }

# We are allowed to ADD an item as well if we get the indices right.

      n := length(its.list);
      if (is_unset(index)) index := n + 1;
      ok := index==(n+1) || (index > 0 && index <= n);
      if (!ok) {
         return throw ('Invalid index', origin='editfitlist.replacelistitem');
      }
      if (index==n+1) {
         its.showing[index] := F;
         its.dddIDs[index] := [=];
      }

# Destroy old componentlist if it exists

      if (index > 0 && index <= n) {
         ok := its.list[index].done();
         if (is_fail(ok)) fail;
      } 

# Replace this componentlist

      its.list[index] := emptycomponentlist(log=F);
      ok := its.list[index].concatenate(componentlist, log=F);
      if (is_fail(ok)) fail;
      its.dddIDs[index] := [=];               # ddd ID for this list
#
      if (its.showing[index]) {
         ok := its.vscl.hide(its.dddIDs[index]);
         its.showing[index] := F;
      }

# Update optionmenu

      names := its.om.getnames();
      names[index] := as_string(name);
      ok := its.om.replace(names, names, names);
      if (is_fail(ok)) fail;

# List the parameters to the list box

      if (list) {
         ok := its.insertcomponentlist (componentlist=componentlist, im=im)
         if (is_fail(ok)) fail;
         its.listidx := index;
      }
#
      return T;
   }


###
   self.setcounter := function (count)
   {
      wider its;
      its.counter->delete('start', 'end');
      its.counter->insert(as_string(count));
      return T;
   }

### Constructor

   widgetset.tk_hold();
#
   hasParent := is_agent(its.parent);
   its.f0 := widgetset.frame(parent=its.parent, expand='both', side='top',
                             relief='raised', title='Fit list editor')
   if (!hasParent) its.f0->unmap();
#
   widgetset.tk_release();

# Fit selection

   its.f0.f0 := widgetset.frame(its.f0, side='left');
   its.f0.f0.label := widgetset.label(its.f0.f0, 'Fit ');
   its.om := widgetset.optionmenu(its.f0.f0, hlp='Select fit index');
   whenever its.om->select do {
      idx := $value.index;
      ok := its.insertcomponentlist (its.list[idx]);
      its.listidx := idx;
   }

# Action buttons

   its.show := widgetset.actionoptionmenu(parent=its.f0.f0, 
                                          labels=['Show','Show'], 
                                          names=['Show', 'Show All'],
                                          values=[T,F],
                                          hlp='Show selected componentlists on display');
   if (is_fail(its.show)) fail;
#
   whenever its.show->select do {
      v := its.show.getvalue();
      if (v) {
         idx := its.om.getindex();
#
         col := unset;
         if (idx==1) col := 'yellow';
         if (is_integer(idx) && idx>0  && !its.showing[idx]) {
            its.dddIDs[idx] := its.vscl.show(its.list[idx], color=col);
            its.showing[idx] := T;
         }
      } else {
         n := length(its.list);
         for (idx in 1:n) {
            if (!its.showing[idx]) {
               col := unset;
               if (idx==1) col := 'yellow';
               its.dddIDs[idx] := its.vscl.show(its.list[idx], color=col);
               its.showing[idx] := T;
            }
         }
      }
   }
#
   its.hide := widgetset.actionoptionmenu(parent=its.f0.f0, 
                                          labels=['Hide','Hide'], 
                                          names=['Hide', 'Hide All'],
                                          values=[T,F],
                                          hlp='Hide selected componentlists from display');
   if (is_fail(its.hide)) fail;
   whenever its.hide->select do {
      v := its.hide.getvalue();
      if (v) {
         idx := its.om.getindex();
         if (is_integer(idx) && idx>0  && its.showing[idx]){ 
            ok := its.vscl.hide(its.dddIDs[idx]);
            its.showing[idx] := F;
         }
      } else {
         n := length(its.list);
         for (idx in 1:n) {
            if (its.showing[idx]) {
               ok := its.vscl.hide(its.dddIDs[idx]);
               its.showing[idx] := F;
            }
         }
      }
   }
#
   its.delete := widgetset.actionoptionmenu(parent=its.f0.f0, 
                                            labels=['Delete','Delete'], 
                                            names=['Delete', 'Delete All'],
                                            values=[T,F],
                                            hlp='Delete selected componentlists from list');
   if (is_fail(its.delete)) fail;
   whenever its.delete->select do {
      v := its.delete.getvalue();
      which := [];
      if (v) {
         idx := its.om.getindex();
         which := its.deleteindex(idx);
      } else {
         which := its.deleteindex();
      } 
#
      idx := its.om.getindex();
      its.insertcomponentlist(its.list[idx]);
#
      if (length(which) > 0) {
         self->delete(which);
      }
   }

# Counter

   its.counter := widgetset.entry(its.f0.f0, width=3);
   its.counter->disabled(T);
   widgetset.popuphelp (its.counter, 'Number of accepted fits');

# Listbox 

   its.listbox := widgetset.scrolllistbox(its.f0, height=8, width=40,
                                          exportselection=T, mode='extended');

# Dismiss

   if (!hasParent) {
      its.f0.f2 := widgetset.frame(its.f0, side='left');
      its.f0.f2.f0 := widgetset.frame(its.f0.f2, height=1, expand='x', side='left');
      its.f0.f2.dismiss := widgetset.button(its.f0.f2, text='Dismiss', type='dismiss');   
      widgetset.popuphelp(its.f0.f2.dismiss, 'Dismiss GUI');
      whenever its.f0.f2.dismiss-> press do {
         its.f0->unmap();
      }
   }
}
