# fitterparameters.g: generate entries for fitting parameters
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
#   $Id: fitterparameters.g,v 19.2 2004/08/25 00:56:41 cvsmgr Exp $
#

pragma include once

include 'illegal.g';
include 'measures.g';
include 'note.g';
include 'quanta.g';
include 'quantumentry.g';
include 'serverexists.g';
include 'unset.g';
include 'widgetserver.g';

const fitterparameters := subsequence (widgetset=dws)
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment variable is not set',
                   origin='fitterparameters.g');
   }
   if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is either not running not valid',
                    origin='fitterparameters.g');
    }
   if (!serverexists('dm', 'measures', dm)) {
      return throw('The measures server "dm" is either not running not valid',
                    origin='fitterparameters.g');
    }
#
   its := [=];
   its.ge := widgetset.guientry();
   if (is_fail(its.ge)) fail;
   its.holderheight := 27;
#

  

### Private functions
###
   const its.makeLabel := function (ref parent, ref rec, fld, txt, width, height, hlp=unset)
   {
      nh := length(rec.holders)+1;
      rec.holders[nh] := widgetset.frame(parent, height=height, side='left',
                                         expand='none', relief='flat');
#
      np := length(rec.propups)+1;
      rec.propups[np] := widgetset.frame(rec.holders[nh], height=height, 
                                         width=1, expand='none');
      rec[fld] := widgetset.label(rec.holders[nh], text=txt, width=width);
      if (!is_unset(hlp)) widgetset.popuphelp(rec[fld], hlp);
      return T;
   }

###
   const its.makeFixed := function (ref parent, ref rec, fld, width, height, 
                                    theEntry)
#
# Make check-box to indicate whether parameter should be held fixed or not
# If so, disable associated entry
#
   {
      nh := length(rec.holders)+1;
      rec.holders[nh] := widgetset.frame(parent, height=height, side='left',
                                         expand='none', relief='flat');
#
      np := length(rec.propups)+1;
      rec.propups[np] := widgetset.frame(rec.holders[nh], height=height, 
                                         width=1, expand='none');
      rec[fld] := widgetset.button(rec.holders[nh], type='check', text='Fix',
                                   width=width);
      widgetset.popuphelp(rec[fld], 'Check to keep parameter fixed at current value during fit', width=100);
#
      whenever rec[fld]->press do {
         state := rec[fld]->state();
         if (state) {
            theEntry.disable(T);
         } else {
            theEntry.disable(F);
         }         
      }
#
      return T;
   }


###
   const its.makeEntry := function (ref parent, ref rec, fld, width, height, direction, arrow,
                                    theEntry=[=])
#
# Make an entry widget
#
   {
      nh := length(rec.holders)+1;
      rec.holders[nh] := widgetset.frame(parent, height=height, side='left',
                                         expand='none', relief='flat');
      np := length(rec.propups)+1;
      rec.propups[np] := widgetset.frame(rec.holders[nh], height=height, 
                                         width=1, expand='none');
#
      ok := F;
      if (arrow && is_agent(theEntry)) {
         na := length(rec.arrows)+1;
         rec.arrows[na] := widgetset.button(rec.holders[nh], bitmap='leftarrow.xbm');
         widgetset.popuphelp(rec.arrows[na], 'Replace the fit by the estimate');
         ok := T;
      }
#
      if (direction) {
         nh2 := length(rec.holders)+1;
         rec.holders[nh2] := widgetset.frame(rec.holders[nh], side='top', relief='flat',
                                             height=height, expand='none', borderwidth=0);
         rec[fld[1]] := widgetset.entry(rec.holders[nh2], width=width, disabled=T);
         rec[fld[2]] := widgetset.entry(rec.holders[nh2], width=width, disabled=T);
#
         if (ok) {
            whenever rec.arrows[na]->press do {

# Only transfer if the 'fixed' flag is off

               state := rec.fixed->state();
               if (!state) {
                  vlong := rec[fld[1]]->get();         # formatted strings
                  vlat  := rec[fld[2]]->get();
                  if (strlen(vlong)>0 && strlen(vlat)>0) {
                     theRef := theEntry.get().refer;
                     if (is_unset(theRef) || is_illegal(theRef)) {
                        note ('Estimate is illegal or unset - can\'t get reference',
                              priority='WARN', origin='fitterparameters.makeEntry');
                     } else {
                        d := dm.direction(theRef, vlong, vlat);
                        theEntry.insert(d);
                     }
                  }
               }
            }
         }
      } else {
         rec[fld] := widgetset.entry(rec.holders[nh], width=width, disabled=T);
#
         if (ok) {
            whenever rec.arrows[na]->press do {

# Only transfer if the 'fixed' flag is off

               state := rec.fixed->state();
               if (!state) {
                  v := rec[fld]->get();
                  if (strlen(v) > 0) {
                     q := theEntry.get();
                     if (is_unset(q) || is_illegal(q)) {
                        note ('Estimate is illegal or unset - can\'t get units',
                              priority='WARN', origin='fitterparameters.makeEntry');
                     } else {
                        u := dq.getunit(q);
                        q := dq.quantity(as_double(v), u);
                        theEntry.insert(q);
                     }
                  }
               }
            }
         }
      }
#
      return T;
   }


###
   const its.makeQuantity := function (ref parent, ref rec, fld, width, height, units)
#
# Make a quantum entry widget
# In/out :
#  parent - the parent agent for the GUI components 
#  rec    - the record to hold the GUI agents in
#             must have fields 'holders' and  'propups'
#             entry  in rec[fld]
# In:
#  fld    - field name for rec to put entry in
#  width  - width of entry
#  height - 
#  units  - List of allowed units for quantity
#  
#
   {
      wider its;
#
      nh := length(rec.holders)+1;
      rec.holders[nh] := widgetset.frame(parent, height=height, side='left',
                                         expand='none', relief='flat');
      np := length(rec.propups)+1;
      rec.propups[np] := widgetset.frame(rec.holders[nh], height=height, 
                                         width=1, expand='none');
#
      txt := spaste('1', unit);
      t := dq.quantity(txt);
      rec[fld] := quantumentry(rec.holders[nh], list=units, widgetset=widgetset);
      rec[fld].setwidth(width);
#      rec[fld].clear(); 
#
      return T;
   }



### Public functions

   const self.cleanquantum := function (ref rec)
   {
      rec.estimate.done();
#
      popupremove(rec);
      val rec.label := F;
      val rec.fixed := F;
      val rec.fit := F;
      val rec.error := F;
#
      nh := length(rec.holders);
      for (i in 1:nh) {   
         val rec.holders[i] := F;
      }
      nh := length(rec.propups);
      for (i in 1:nh) {
         val rec.propups[i] := F;
      }
      nh := length(rec.arrows);
      for (i in 1:nh) {
         val rec.arrows[i] := F;
      }
      val rec := F;
      return T;
   }
         
###
   const self.cleanpos2d := function (ref rec)
   {
      rec.estimate.done();
      popupremove(rec);
#
      val rec.label := F;
      val rec.fixed := F;
      val rec.fitLong := F;
      val rec.fitLat := F;
      val rec.errorLong := F;
      val rec.errorLat := F;   
#
      nh := length(rec.holders);
      for (i in 1:nh) {
         val rec.holders[i] := F;
      }
      nh := length(rec.propups);
      for (i in 1:nh) {
         val rec.propups[i] := F;
      }
      nh := length(rec.arrows);
      for (i in 1:nh) {
         val rec.arrows[i] := F;
      }
      val rec := F;
      return T;
   }

###
   const self.clearestimate := function (ref rec)
   {
      if (has_field(rec, 'estimate')) {
         return rec.estimate.clear();
      } else {
         return F;
      }
   }


###
   const self.clearfit := function (ref rec)
   {
      if (has_field(rec, 'fit')) {
         rec.fit->delete('start', 'end'); 
         rec.error->delete('start', 'end'); 
      } else if (has_field(rec, 'fitLong') &&
                 has_field(rec, 'fitLat')) {
           rec.fitLong->delete('start', 'end');
           rec.fitLat->delete('start', 'end');
           rec.errorLong->delete('start', 'end');
           rec.errorLat->delete('start', 'end');
      } else {
         return F;
      }
      return T;
   }


###
   const self.done := function ()
   {
      wider its, self;
      its.ge.done();
      val its := F;
      val self := F;
      return T;
   }

###
   const self.getestimate := function (rec)
   {
      if (has_field(rec, 'estimate')) {
         return rec.estimate.get();
      } else {
         return throw ('No estimate field in record',
                       origin='fitterparameters.getestimateunit');
      }
   }

###
   const self.getfit := function (rec)
   {
      r := [=];
      u := self.getestimateunit(rec);
      if (has_field(rec, 'fit')) {
         r.value := as_double(rec.fit->get());
         r.error := as_double(rec.error->get());
         r.unit := u;
      } else if (has_field(rec, 'fitLong') &&
                 has_field(rec, 'fitLat')) {
           r.value := [];
           r.value[1] := as_double(rec.fitLong->get());
           r.value[2] := as_double(rec.fitLat->get());
           r.error := [];
           r.error[1] := as_double(rec.errorLong->get());
           r.error[2] := as_double(rec.errorLat->get()); 
           r.unit := u;
      }
      return r;
   }

###
   const self.getestimateunit := function (rec)
#
# There might not be a value in the entry box yet
# so get the unit indpendently of function get
#
   {
      if (has_field(rec, 'estimate')) {
         return rec.estimate.getunit();
      } else {
         return throw ('No estimate field in record',
                       origin='fitterparameters.setestimateunit');
      }
   }

###
   const self.getfixed := function (rec) 
   {
      return rec.fixed->state();
   }

###
   const self.insertestimate:= function (ref rec, value)
   {
      self.clearestimate(rec);
      if (has_field(rec, 'estimate')) {
         return rec.estimate.insert(value);
      }
      return F;
   }

###
   const self.insertfit := function (ref rec, value, error)
   {
      self.clearfit(rec);
#
      if (has_field(rec, 'fit')) {
         rec.fit->insert(sprintf("%-15.7e", value));
         rec.error->insert(sprintf("%-15.7e", error));
      } else if (has_field(rec, 'fitLong') &&
                 has_field(rec, 'fitLat')) {
         rec.fitLong->insert(value[1]);
         rec.fitLat->insert(value[2]);
#
         rec.errorLong->insert(error[1]);
         rec.errorLat->insert(error[2]);
      }
#
      return T;
   }


###
   const self.makepos2d := function (ref labels, ref estimates,
                                     ref fixeds, ref fits,
                                     ref errors, ref rec, widths, hlp=unset)
#
# Make a parameter row for a 2D position parameter.  Each column of the
# row is aligned. This is done by passing in a parent agent for
# each column
#
# In/out:
#   labels    - parent for labels widgets
#   estimates - parent for estimates entry boxes
#   fixeds    - parent for fixeds check boxes
#   fits      - parent for fits entry widgets
#   errors    - parent for errors entry widgets
#   rec       - On output has new fields
#             pos
#             pos.label          - label widget
#             pos.estimate       - direction entry widget
#             pos.fixed          - fixed check box widget
#             pos.fit{Long,Lat}  - fit simple entry widgets
#             pos.error{Long,Lat}- error simple error widgets
#
#             pos.holders       - holds some frames
#             pos.propups       - holds some more frames
#             pos.arrows        - holds transfer arrow widgets 
# In:
#  widths  - [1]  width for label
#            [2]  width for estimate
#            [3]  width for fixed
#            [4]  width for fit
#            [5]  width for error
#
#
   {
      wider its;
      rec.pos := [=];
      rec.pos.holders := [=];
      rec.pos.propups := [=];
      rec.pos.arrows := [=];
#
      hh := its.holderheight * 2;
      its.makeLabel(labels, rec.pos, 'label', 'pos', widths[1], hh, hlp=hlp);
#
      nh := length(rec.pos.holders) + 1;
      rec.pos.holders[nh] := widgetset.frame(estimates, height=hh, expand='none',
                                            relief='flat', side='left');
      np := length(rec.pos.propups) + 1;
      rec.pos.propups[np] := widgetset.frame(rec.pos.holders[nh], height=hh, width=1, 
                                             expand='none');
      rec.pos.estimate := its.ge.direction(rec.pos.holders[nh], value=unset, 
                                           allowunset=T, options='vertical');
      rec.pos.estimate.setwidth(widths[2]);
#      rec.pos.estimate.clear();
#
      its.makeFixed (fixeds, rec.pos, 'fixed', widths[3], hh, rec.pos.estimate);
#
      its.makeEntry (fits, rec.pos, "fitLong fitLat", widths[4],  hh, 
                     T, T, rec.pos.estimate);
#
      its.makeEntry (errors, rec.pos, "errorLong errorLat", widths[5],  hh, T, F);
#
      return T;
   }

###
   const self.makequantum := function (ref labels, ref estimates,
                                       ref fixeds, ref fits,
                                       ref errors, ref rec, fld, 
                                       widths, units, hlp=unset)
#
# Make a parameter row for a quantum. Each column of the
# row is aligned. This is done by passing in a parent agent for
# each column
#
# In/out:
#   labels    - parent for labels widgets
#   estimates - parent for estimates entry boxes
#   fixeds    - parent for fixeds check boxes
#   fits      - parent for fits entry widgets
#   errors    - parent for errors entry widgets
#   fld       - the name of the field to fill in 'rec'
#   rec       - On output has new fields
#             fld
#             fld.label          - label widget
#             fld.estimate       - quantumentry widget
#             fld.fixed          - fixed check box widget
#             fld.fit            - fit simple entry widget
#             fld.error          - error simple error widget
#
#             fld.holders       - holds some frames
#             fld.propups       - holds some more frames
#             fld.arrows        - holds transfer arrow widgets 
# In:
#  widths  - [1]  width for label
#            [2]  width for estimate
#            [3]  width for fixed
#            [4]  width for fit
#            [5]  width for error
#  units   - list of allowed units for quantum
#
#
   {
      wider its;
      rec[fld] := [=];
      rec[fld].holders := [=];
      rec[fld].propups := [=];
      rec[fld].arrows := [=];
#
      its.makeLabel(labels, rec[fld], 'label', fld, widths[1], its.holderheight, hlp=hlp);
#
      its.makeQuantity (estimates, rec[fld], 'estimate', widths[2], 
                        its.holderheight, units);
      whenever rec[fld].estimate->carriageReturn do {
         self->estimateCR($value);
      }
#
      its.makeFixed (fixeds, rec[fld], 'fixed', widths[3], its.holderheight, 
                     rec[fld].estimate);
#
      its.makeEntry (fits, rec[fld], 'fit', widths[4],  its.holderheight, 
                     F, T, rec[fld].estimate);
#
      its.makeEntry (errors, rec[fld], 'error', widths[5],  its.holderheight, F, F);
#
      return T;
   }

###
   const self.setestimateunit := function (ref rec, unit, width)
   {
      if (has_field(rec, 'estimate')) {
         return rec.estimate.replaceunitmenu(unit, width);
      } else {
         return throw ('No estimate field in record',
                       origin='fitterparameters.setestimateunit');
      }
   }

###
   const self.setestimateunitwidth := function (ref rec, width)
   {
      if (has_field(rec, 'estimate')) {
         return rec.estimate.setunitwidth(width);
      } else {
         return throw ('No estimate field in record',
                       origin='fitterparameters.setestimateunitwidth');
      }
   }
}
