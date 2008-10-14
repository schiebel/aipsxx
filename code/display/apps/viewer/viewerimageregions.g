# viewerimageregions.g: Viewer support for region generation from images
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
#
# Emits events:
#
#   Name              Value
#  region            rec.ddname
#                    rec.region
#                    rec.stats
#
# $Id: viewerimageregions.g,v 19.1 2005/06/15 18:10:58 cvsmgr Exp $
#

pragma include once

include 'clipboard.g'
include 'regionentry.g'
include 'note.g'
include 'optionmenu.g'
include 'serverexists.g'
include 'unset.g'
include 'illegal.g'
#
include 'coordsys.g'
include 'regionmanager.g'
include 'image.g'
include 'quanta.g'
include 'viewerimageshowregions.g'
include 'widgetserver.g'

const viewerimageregions := subsequence (parent, ddd, viewer, widgetset=dws)
{
    if (!serverexists('drm', 'regionmanager', drm)) {
       return throw('The regionmanager server "drm" is not running',
                     origin='viewerimageregions.g');
    }
    if (!serverexists('dq', 'quanta', dq)) {
       return throw('The quanta server "dq" is not running',
                     origin='viewerimageregions.g');
    }
    if (!serverexists('dcb', 'clipboard', dcb)) {
       return throw('The clipboard server "dcb" is not running',
                     origin='viewerimageregions.g');
    }
#
    its := [=];
    its.viewer := viewer;
    its.ddd := ddd;                        # Registered Drawing display data
    its.ws := widgetset;
    its.visr := viewerimageshowregions(ddd=ddd);
    if (is_fail(its.visr)) fail;

# Callback functions

    its.getImageTool := [=];               # Get Image tool from ddname 
    its.pseudoToWorldRegion := [=];        # Convert pseudo to world region
    its.getDisplayAxes := [=];             # Get display axes
#
    its.displayaxes := [=];                # Record describing where the display axes are
                                           # indexed per ddname
    its.td := [=];                         # Tab dialog
    its.tabs := [=];                       # The tabs, indexed by ddname
    its.tabnames := "";                    # The tab names (indexed by integer)
    its.ddnames := "";                     # DisplayData names
    its.index := [=];                      # Tabs index. Indexed by ddname
    its.active := [=];                     # Activity status, indexed by ddname
#
    its.regions := [=];                    # Accumulated regions, indexed by tabname
    its.dddIDs := [=];                     # IDs of ddd objects
    its.dddIDs.show := [=];                # These are for when we press 'Show'
    its.dddIDs.acc := [=];                 # These are the ones we make in Accumulate mode
                                           # one index per region in the accumulation
    its.timers := [=];                     # Timers, indexed by tabname

### Private methods


###
   const its.accumulateRegion := function (ddname, region)  
   {
      wider its;
#
      n := length(its.regions[ddname]) + 1;
      its.regions[ddname][n] := region;
#
      its.f0.naccum->delete('start', 'end');
      its.f0.naccum->insert(as_string(n));
#
      return n;
   }

###
   const its.addOneTab := function (ddname)
   {
      wider its;

# Overwrite if name exists, else we get in big logic tangles.

      if (has_field(its.index, ddname)) {
         n := its.index[ddname];
      } else {
         n := length(its.tabnames) + 1;
      }
#  
      tabname := ddname;
      its.tabnames[n] := tabname;
      its.ddnames[n] := ddname;
      its.index[ddname] := n;

# Create TAB and add it to the tabdialog widget

      ok := its.makeTab(n, ddname, tabname);
      if (is_fail(ok)) fail;
#
      return ok;
   }

###
   const its.assembleEvent := function (ddname, type, region, tag)
   {
      r := [ddname=ddname, region=region, type=type, tag=tag];
      return r;
   }


###
   const its.clearAccumulatedRegions := function ()  
   { 
      wider its;
#
      if (length(its.ddnames)==0) return T;
#
      for (ddname in its.ddnames) {
         if (its.active[ddname]) { 
            ok := its.doneAccumulatedRegions (ddname);
            if (is_fail(ok)) fail;
            its.f0.naccum->delete('start', 'end');
            its.f0.naccum->insert(as_string(0));
         }
      }

# Remove accumulated DDDs from display

      n := length(its.dddIDs.acc);
      if (n>0) {
         for (i in 1:n) {
            its.visr.hide(its.dddIDs.acc[i]);
         }
      }
      its.dddIDs.acc := [=];
#
      return T;
   }

###
   const its.combineAccumulatedRegions := function (ddname, first)
   {
      wider its;
#
      n := length(its.regions[ddname]);
#
      r := [=];
      if (n==0) {
         if (first) {
            note ('No accumulated regions; nothing to do',
                  origin='viewerimageregions.combineAccumulatedRegions',
                  priority='NORMAL');
         }
      } else if (n==1) {
         if (first) {
            note ('You need at least two regions to make a compound region; nothing to do',
                  origin='viewerimageregions.combineAccumulatedRegions',
                  priority='NORMAL');
         }
      } else {
         t := its.f0.compound.getvalue();
         if (is_fail(t)) fail;
#
         if (t=='union') {
            r.region := drm.union(its.regions[ddname]);
            r.type := 'union';
         } else if (t=='intersection') {
            r.region := drm.intersection(its.regions[ddname]);
            r.type := 'int';                       # Only used to generate region name
                                                   # by regionmanager if listening
         } else {
            return throw ('Unrecognized accumulated compound region type',
                          origin='viewerimageregions.combineAccumulatedRegions');
         }
         if (is_fail(r.region)) fail;
         if (first) {
            msg := spaste('Generated ', t, ' from ', n, ' accumulated regions');
            note (msg, origin='viewerimageregions.combineAccumulatedRegions',
                  priority='NORMAL');
         }
      }
#
      return r;
   }

###
   const its.doneAccumulatedRegions := function (ddname) 
   {
      wider its;
#
      n := length(its.regions[ddname]);
      if (n>0) {
         for (i in 1:n) {
            ok := its.regions[ddname][i].done();
            if (is_fail(ok)) fail;
         }     
         its.regions[ddname] := [=];
      }
      return T;
   }


###
   const its.indicateRegionInserted := function (ddname)
   {
      wider its;
      its.tabs[ddname].f0.indicate->state(F);
      return T;
   }


###
   const its.insertRegion := function (ddname, region)  
   {
      wider its;
#
      ok := its.tabs[ddname].f0.region.insert(region);
      if (is_fail(ok)) fail;
#
      its.tabs[ddname].f0.indicate->state(T);
      its.timers[ddname].timer->interval(0.5);
      return T;
   }


###
   const its.makeNonTab := function ()
   {
       wider its;
#
       txt := spaste('Compound region type to form from accumulated regions');
       its.f0.compound := its.ws.optionmenu(its.f0, labels="union intersection",
                                            hlp=txt);
#
       its.f0.action := its.ws.button(its.f0, type='Action', text='Start', width=7);
       longHelp := spaste('Press Start to begin accumulating regions\n',
                          'Once you have accumulated all the regions\n',
                          'you are interested in, select what kind of\n',  
                          'compound region (union/intersection) you \n',
                          'wish to make from the accumulated regions\n',
                          'and press Finish.  The region will be created,\n',
                          'emitted as an event and captured in the \n',
                          'region entry widget.');
       its.ws.popuphelp(its.f0.action, longHelp,
                        'Start or finish region accumulation',
                        combi=T, width=80);
       its.f0.reset := its.ws.button(its.f0, type='Action', text='Reset');
       its.ws.popuphelp(its.f0.reset, 'Reset regions accumulated to 0');
#
       its.f0.label0 := its.ws.label(its.f0, 'Accumulate');
       its.ws.popuphelp(its.f0.label0, 'When checked indicates regions are being accumulated');
       its.f0.check := its.ws.button(its.f0, type='check', text=''); 
       its.ws.popuphelp(its.f0.check, 'When checked indicates regions are being accumulated');
       its.f0.check->disabled(T);
       its.f0.naccum := its.ws.entry(its.f0, width=3);
       txt := spaste('Number of regions accumulated so far');
       its.ws.popuphelp(its.f0.naccum, txt);
       its.f0.naccum->insert(as_string(0));
#
# Handle start/stop accumulate press
#
       whenever its.f0.action->press do {
         action := its.f0.action->text();
#
         if (action=='Start') {
                                         
# Turning accumulation state on  
                 
            its.clearAccumulatedRegions();
            its.f0.action->text('Finish')
            its.f0.check->state(T);
         } else {

# Turning accumulation state off; generate compound region from
# accumulated regions for each DD and insert

            j := 0;
            for (ddname in its.ddnames) {
               if (its.active[ddname]) {
                  j +:= 1;
                  cReg := its.combineAccumulatedRegions(ddname, j==1);
                  if (is_fail(cReg)) {
                     note (cReg::message, origin='viewerimageregions.makeNonTab',
                           priority='SEVERE');
                  } else {
                     if (length(cReg) > 0) {
                        ok := its.insertRegion(ddname, cReg.region);
                        if (is_fail(ok)) {
                           note (ok::message, origin='viewerimageregions.makeNonTab',
                                 priority='SEVERE');
                        } else {
                           rec := its.assembleEvent (ddname, cReg.type, cReg.region, 'compound');
                           self->region(rec);
#
                           its.f0.check->state(F);
                           its.f0.action->text('Start')
                           its.clearAccumulatedRegions();
                        }
                     }
                  }
               }
            }
         }       
      }
#
      whenever its.f0.reset->press do {
         its.clearAccumulatedRegions();
         its.f0.action->text('Start')
         its.f0.check->state(F);
      }
#
      return T;
   }


###
    const its.makeTab := function (idx, ddname, tabname)
    {
       wider its;
       its.ws.tk_hold();
#
       its.tabs[ddname] := its.ws.frame(its.tdf, side='top', relief='raised');
       its.tabs[ddname].f0 := its.ws.frame(its.tabs[ddname], side='left');
       its.tabs[ddname].f0.label0 := its.ws.label(its.tabs[ddname].f0, 'Region', width=6);
       longHelp := spaste('\nRegions are generated by the box and polygon\n',
                          'tools on the Viewer display.  Every time you\n',
                          'create a region (by double clicking) the region\n',
                          'is emitted as an event and also captured in this\n',
                          'entry widget.   Also, when you accumulate \n',
                          'regions, when you generate the compound region\n',
                          '(union or intersection) it is also captured here\n');
       its.ws.popuphelp(its.tabs[ddname].f0.label0, longHelp,
                        'Whenever regions are generated, they are captured here',
                        combi=T, width=80);
       its.tabs[ddname].f0.region := regionentry(its.tabs[ddname].f0, widgetset=its.ws);
       its.tabs[ddname].f0.region.setwidth(10);
       its.tabs[ddname].f0.indicate := its.ws.button(its.tabs[ddname].f0, type='check', text='Inserted'); 
       txt := spaste('\nWhen a region is created interactively, this check \n',
                     'button will be checked briefly to indicate that \n',
                     'the region has been captured');
       its.ws.popuphelp(its.tabs[ddname].f0.indicate, txt, 'Indicate region capture', combi=T);
#
       its.tabs[ddname].f0.show := its.ws.button(its.tabs[ddname].f0, type='Action', text='Show');
       txt := spaste('This displays the region on the displaypanel and\n',    
                     'writes the boundingbox of the region to the logger\n\n',
                     'If the region you are displaying is compound (e.g. a union)\n',
                     'then all of the simple regions in it are found and plotted.\n',
                     'The knowledge that the compound region  was an intersection\n',
                     'or union etc. is not presently displayed graphically');
       its.ws.popuphelp(its.tabs[ddname].f0.show, txt, 'Show region on image display', combi=T);
#
       whenever its.tabs[ddname].f0.show->press do {
         its.viewer.hold();
         ddn := its.td.which().name;
#
         text := its.tabs[ddn].f0.show->text();
         its.tabs[ddn].f0.show->disabled(T);
         if (text=='Show') {
            rr := its.tabs[ddn].f0.region.get();
            if (is_fail(rr)) {
               note (rr::message, priority='SEVERE', origin='viewerimageregions.makeTab');
            } else if (is_unset(rr)) {
               note ('No region to display', priority='WARN', 
                      origin='viewerimageregions.makeTab');
            } else if (is_illegal(rr)) {  
               note ('The current region is invalid', priority='WARN', 
                      origin='viewerimageregions.makeTab');
            } else {
               im := its.getImageTool(ddn);
               if (is_fail(im)) {
                  note (im::message, priority='SEVERE', 
                        origin='viewerimageregions.makeTab');
               } else {
                  id := its.visr.show(im, rr, T);
                  if (is_fail(id)) {
                     note (ok::message, priority='SEVERE', 
                           origin='viewerimageregions.makeTab');
                  } else {
                     its.dddIDs.show := id;
                  }
               }
               its.tabs[ddname].f0.show->text('Hide');
            }
         } else {
            ok := its.visr.hide (its.dddIDs.show);
            if (is_fail(ok)) {
               note (ok::message, priority='SEVERE', 
                     origin='viewerimageregions.makeTab');
            }
            its.dddIDs.show := [=];
            its.tabs[ddn].f0.show->text('Show');
         }
         its.tabs[ddn].f0.show->disabled(F);
         its.viewer.release();
       }

# Add new TAB to the tabdialog widget

      ok := its.td.add(its.tabs[ddname], tabname);
      if (is_fail(ok)) fail;
      if (length(its.td.list())==1)  its.td.front(tabname);
#
      its.ws.tk_release();

# Accumulated regions holder

      its.regions[ddname] := [=];
#
      return T;
    }


### Public methods

###
   const self.accumstate := function ()
   {
      wider its;
#
      return its.f0.check->state();
   }

###
    const self.add := function (ddname) 
    {
       wider its;
#
       if (has_field(its.index, ddname) && its.active[ddname]) {
          return throw (spaste('Entry ', ddname, ' is already active'),
                        origin='viewerimageregions.add');
       }
#
       ok := its.addOneTab(ddname); 
       if (is_fail(ok)) fail;
#
       its.timers[ddname] := [=];
       its.timers[ddname].timer := client('timer', '-oneshot');
       whenever its.timers[ddname].timer->ready do {
          ddn := its.td.which().name;
          its.indicateRegionInserted(ddn);
       }
       its.active[ddname] := T;
#
       return T;
    }

###
    const self.delete := function (ddname) 
    {
       wider its;
#
       if (has_field(its.active, ddname) && !its.active[ddname]) {
          return throw (spaste('Entry ', ddname, ' is not active'),
                        origin='viewerimageregions.delete');
       }
#
       idx := its.index[ddname];
       tabname := its.tabnames[idx];
       ok := its.td.delete(tabname); 
       if (is_fail(ok)) fail;
#
       ok := its.tabs[ddname].f0.region.done();
       if (is_fail(ok)) fail;
       its.timers[ddname].timer := F;
       ok := its.doneAccumulatedRegions(ddname);
       if (is_fail(ok)) fail;
       its.tabs[ddname] := F;
       its.active[ddname] := F;
#
       return T;
    }


###
    const self.done := function () 
    {
       wider its, self;
#
       ok := its.td.done();
#
       for (ddname in its.ddnames) {
          if (its.active[ddname]) {
             ok := its.tabs[ddname].f0.region.done();
             its.timers[ddname].timer := F;
             ok := its.doneAccumulatedRegions(ddname);
             if (is_fail(ok)) fail;
             its.tabs[ddname] := F;
             its.active[ddname] := F;
          }
       }
#
       val its := F;
       val self := F;
#
       return T;
    }

###
   self.insertregion := function (pseudoregion)
   {
      wider its;

# Distribute over DDs

      i := 0;
      for (ddname in its.ddnames) {
         if (its.active[ddname]) {
            i +:= 1;

# Get Image tool

            im := its.getImageTool(ddname);
            if (is_fail(im)) fail;

# Convert pseudoregion to world region via callback

            rr := its.pseudoToWorldRegion(ddname, pseudoregion, T);
            if (is_fail(rr)) fail;
#
# Find out where the display axes are for each DD.  Ultimately we need
# to do this so that we fish out the right axes of the region for display
# Presently not implemented in this subsequence so don't call this function
#
#            its.displayaxes[ddname] := its.getDisplayAxes(ddname);

# If we are accumulating, do that. Else poke it in the widget

            if (self.accumstate()) {
               n := its.accumulateRegion (ddname, rr);
               if (is_fail(n)) fail;
#
               if (i==1) {
                  note (spaste('Added region ', n, ' to accumulation store'),
                  origin='viewerimageregions.insertregion');

# Display region from first registered DD (it will always be visible)
# We dont' need to see it many time !

                  id := its.visr.show (im=im, region=rr, list=F);
                  if (is_fail(id)) fail;
#
                  idx := length(its.dddIDs.acc) + 1;
                  its.dddIDs.acc[idx] := id;
               }
            } else {
               ok := its.insertRegion (ddname, rr);
               if (is_fail(ok)) fail;
               rec := its.assembleEvent (ddname, pseudoregion.type, rr, 'simple');
               self->region(rec);
            }
         }
      }
   }

###
   const self.setcallbacks := function (callback1, callback2, callback3)
   {
      wider its;

# Arg. ddname, returns image Tool

      if (is_function(callback1)) {
         its.getImageTool := callback1;
      } else {
         return throw ('callback1 is not a function',
                        origin='viewerimageregions.setcallbacks');
      }

# Arg. ddname, pseudoregion and intersect; returns world region

      if (is_function(callback2)) {
         its.pseudoToWorldRegion := callback2;
      } else {
         return throw ('callback2 is not a function',
                        origin='viewerimageregions.setcallbacks');
      }

# Arg. ddname; returns display axes

      if (is_function(callback3)) {
         its.getDisplayAxes := callback3;
      } else {
         return throw ('callback3 is not a function',
                        origin='viewerimageregions.setcallbacks');
      }
#
      return T;
   }

### Constructor

# Frame for non-tab stuff

   its.f0 := its.ws.frame (parent, side='left');
   ok := its.makeNonTab(); 
   if (is_fail(ok)) fail;

# Tab dialog 

   its.td := its.ws.tabdialog(parent, colmax=3, title=unset);
   if (is_fail(its.td)) fail;

# Frame to put all the TABS in

   its.tdf := its.td.dialogframe();
   if (is_fail(its.tdf)) fail;
}
