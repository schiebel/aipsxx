# viewerimagestatistics.g: Viewer support for statistics generation from images
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
#   $Id: viewerimagestatistics.g
#
# Emits events:
#
#   Name              Value
#  statistics        rec.ddname
#                    rec.region
#                    rec.stats
#

pragma include once

include 'clipboard.g'
include 'note.g'
include 'pgplotter.g'
include 'serverexists.g'
include 'unset.g'
include 'misc.g'
#
include 'regionmanager.g'
include 'image.g'
include 'widgetserver.g'

const viewerimagestatistics := subsequence (parent, widgetset=dws)
{
    if (!serverexists('drm', 'regionmanager', drm)) {
       return throw('The regionmanager server "drm" is not running',
                     origin='viewerimagestatistics.g');
    }
    if (!serverexists('dcb', 'clipboard', dcb)) {
       return throw('The clipboard server "dcb" is not running',
                     origin='viewerimagestatistics.g');
    }
    if (!serverexists('dms', 'misc', dms)) {
       return throw('The misc server "dms" is not running',
                     origin='viewerimagestatistics.g');
    }
#
    its := [=];
    its.ws := widgetset;

# Callback functions

    its.getImageTool := [=];               # Get Image tool from ddname 
    its.getZoomedRegion := [=];            # Get zoomed region
    its.pseudoToWorldRegion := [=];        # Convert pseudo to world region
    its.getMovieAxis := [=];               # Get movie axis
#
    its.td := [=];                         # Tab dialog
    its.tabs := [=];                       # The tabs, indexed by ddname
    its.tabnames := "";                    # The tab names (indexed by integer)
    its.ddnames := "";                     # DisplayData names
    its.index := [=];                      # Tabs index. Indexed by ddname
    its.active := [=];                     # Activity status, indexed by ddname
    its.imageTools := [=];                 # Image tools indexed by ddname
#
    its.stats := [=];                      # Holds statistics values, indexed by ddname
    its.plotter := [=];                    # Plotter names, indexexed by ddname
#
    its.region := [=];


### Private methods


###
   const its.addOneTab := function (ddname)
   {
      wider its;
#
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

# Create TAB, indexed by string converted integer
# and add it to the tabdialog widget

      ok := its.makeTab(n, ddname, tabname);
      if (is_fail(ok)) fail;
#
      return ok;
   }

###
   const its.assembleEvent := function (ddname)
   {
      wider its;
#
      r := [ddname=ddname, region=its.region[ddname], stats=its.stats[ddname]];
      return r;
   }


###
    const its.clearGui := function (ref rec)
    {
       rec.f1.f0.min->delete('start', 'end');
       rec.f1.f0.max->delete('start', 'end');
       rec.f1.f0.npts->delete('start', 'end');
#
       rec.f1.f1.sum->delete('start', 'end');
       rec.f1.f1.mean->delete('start', 'end');
       rec.f1.f1.flux->delete('start', 'end');
#
       rec.f1.f2.stddev->delete('start', 'end');
       rec.f1.f2.var->delete('start', 'end');
       rec.f1.f2.rms->delete('start', 'end');
#
       rec.f1.f3.minpos->delete('start', 'end');
       rec.f1.f3.minposf->delete('start', 'end');
       rec.f1.f4.maxpos->delete('start', 'end');
       rec.f1.f4.maxposf->delete('start', 'end'); 
#
       rec.f1.f5.median->delete('start', 'end');
       rec.f1.f5.meddev->delete('start', 'end');
       rec.f1.f5.quartile->delete('start', 'end');
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
#
# Buttons
#
       its.tabs[ddname].f0a := its.ws.frame(its.tabs[ddname], side='left');
       its.tabs[ddname].f0a.plot := its.ws.button(its.tabs[ddname].f0a, type='action', text='plot');
       its.ws.popuphelp(its.tabs[ddname].f0a.plot, 'Plot histogram of last interactively generated region');
       its.tabs[ddname].f0a.autoplot := its.ws.button(its.tabs[ddname].f0a, type='check', text='Auto-plot', width=9);
       txt := spaste('When unchecked push the plot button to plot histogram');
       its.ws.popuphelp(its.tabs[ddname].f0a.autoplot, txt, 'Always plot histogram when statistics generated',
                        combi=T, width=80);
#
       its.tabs[ddname].f0a.full := its.ws.button(its.tabs[ddname].f0a, type='action', text='Full');
       its.ws.popuphelp(its.tabs[ddname].f0a.full, 'Generate statistics from full image');
       its.tabs[ddname].f0a.plane := its.ws.button(its.tabs[ddname].f0a, type='action', text='Plane');
       its.ws.popuphelp(its.tabs[ddname].f0a.plane, 'Generate statistics from area of displayed+zoomed plane');
#
       bu := its.imageTools[ddname].brightnessunit();
       txt := spaste('Unit: ', bu);
       its.tabs[ddname].f0a.space := its.ws.frame(its.tabs[ddname].f0a, expand='x', height=1, width=20);
       its.tabs[ddname].f0a.units := its.ws.label(its.tabs[ddname].f0a, text=txt);
#
       its.tabs[ddname].f0 := its.ws.frame(its.tabs[ddname], side='left');
       its.tabs[ddname].f0.copy := its.ws.button(its.tabs[ddname].f0, type='action', text='copy');
       its.ws.popuphelp(its.tabs[ddname].f0.copy, 'Copy results to clipboard');
       its.tabs[ddname].f0.autocopy := its.ws.button(its.tabs[ddname].f0, type='check', text='Auto-copy');
       its.ws.popuphelp(its.tabs[ddname].f0.autocopy, 
                        'Always copy results to clipboard when statistics are generated');
#
#       its.tabs[ddname].f0.space := its.ws.frame(its.tabs[ddname].f0, expand='x', width=2, height=1);
       its.tabs[ddname].f0.robust := its.ws.button(its.tabs[ddname].f0, type='check', text='Robust', width=7);
       txt := spaste('When checked, robust statistics will also be calculated');
       its.ws.popuphelp(its.tabs[ddname].f0.robust, txt);
#
       its.tabs[ddname].f0.extend := its.ws.button(its.tabs[ddname].f0, type='check', text='Extend');
       its.ws.popuphelp(its.tabs[ddname].f0.extend, 'Extend any interactive region along movie axis');
       its.tabs[ddname].f0.extendEntry := its.ws.entry(its.tabs[ddname].f0, width=7);
       txt := spaste ('For example, entering 10 20 would extend the interactive spatial region\n',
                      ' over pixels 10 through 20 along the movie axis. After entering\n',
                      ' the range, double click inside the region again to recompute the statistics\n',
                      'If not (or illegally) specified, extends along full movie axis\n',
                      'If only one value given that is the start pixel and it extends\n',
                      '  to the end of the axis');
       its.ws.popuphelp(its.tabs[ddname].f0.extendEntry, txt,
                        'Enter pixel range along movie axis to extend region over',
                        combi=T, width=80);
#
# Full image statistics
# 
       its.stats[ddname] := [=];
       its.region[ddname] := [=];
#
       whenever its.tabs[ddname].f0a.full->press do {
          ddn := its.td.which().name;           # Can't really rely on ddname being correct
          its.tabs[ddn]->disable();
          its.region[ddn] := drm.box();
          robust := its.tabs[ddn].f0.robust->state();
#
          ok := its.imageTools[ddn].statistics(statsout=its.stats[ddn], async=F, 
                                               list=F, robust=robust);
          if (is_fail(ok)) {
            note (ok::message, priority='SEVERE',
                  origin='viewerimagestatistics.makeTab');
          } else {
             its.writeGui (its.tabs[ddn], its.stats[ddn]);
#
             rec := its.assembleEvent (ddn);
             if (its.tabs[ddn].f0.autocopy->state()) dcb.copy(rec);
             if (its.tabs[ddn].f0a.autoplot->state()) {
                ok := its.plotHistogram(its.imageTools[ddn], ddn);
                if (is_fail(ok)) {
                   note (ok::message, priority='SEVERE',
                         origin='viewerimagestatistics.makeTab');
                }                
             }
             self->statistics(rec);
          }
          its.tabs[ddn]->enable();
       }
#
# Displayed zoomed plane statistics
#
       whenever its.tabs[ddname].f0a.plane->press do {
         ddn := its.td.which().name;           # Can't really rely on ddname being correct
         its.tabs[ddn]->disable();
         its.region[ddn] := its.getZoomedRegion(ddn);
         if (is_fail(its.region[ddn])) {
            note (its.region[ddn]::message, priority='SEVERE',
                  origin='imageviewersupport.makeViewStatistics');
         } else {
            robust := its.tabs[ddn].f0.robust->state();
            ok := its.imageTools[ddn].statistics(statsout=its.stats[ddn], region=its.region[ddn], 
                                                  async=F, list=F, robust=robust);
            if(!is_fail(ok)) {
               its.writeGui (its.tabs[ddn], its.stats[ddn]);
#
               rec := its.assembleEvent (ddn);
               if (its.tabs[ddn].f0.autocopy->state()) dcb.copy(rec);
               if (its.tabs[ddn].f0a.autoplot->state()) {
                  its.plotHistogram(its.imageTools[ddn], ddn, region=its.region[ddn]);
               }
               self->statistics(rec);
            } else {
               note (ok::message, priority='SEVERE',
                     origin='viewerimagestatistics.makeTab');
            }
         }
         its.tabs[ddn]->enable();
       }
#
# Autocopy state
#
       whenever its.tabs[ddname].f0.autocopy->press do {
          ddn := its.td.which().name;           # Can't really rely on ddname being correct
          if (its.tabs[ddn].f0.autocopy->state()) {
             its.tabs[ddn].f0.copy->disabled(T);
          } else {
             its.tabs[ddn].f0.copy->disabled(F); 
          } 
       }
#
# Copy statistics to clipboard
#
       whenever its.tabs[ddname].f0.copy->press do {
          ddn := its.td.which().name;           # Can't really rely on ddname being correct
          rec := its.assembleEvent (ddn);
          dcb.copy(rec);
       }
# 
# Autoplot state
#
       whenever its.tabs[ddname].f0a.autoplot->press do {
          ddn := its.td.which().name;           # Can't really rely on ddname being correct
          if (its.tabs[ddn].f0a.autoplot->state()) {
             its.tabs[ddn].f0a.plot->disabled(T);
          } else {
             its.tabs[ddn].f0a.plot->disabled(F);
          }
       }
#
# Plot histogram
#
       whenever its.tabs[ddname].f0a.plot->press do {
          ddn := its.td.which().name;           # Can't really rely on ddname being correct
#
          its.tabs[ddn]->disable();
          state := its.tabs[ddn].f0a.autoplot->state();
          if (length(its.region[ddn])==0) {
             note ('There is not yet a region to plot', priority='WARN',
                    origin='viewerimagestatistics.makeTab');
          } else {
             its.tabs[ddn].f0a.plot->disabled(T);
             its.plotHistogram (its.imageTools[ddn], ddn, region=its.region[ddn]);
             if (state) {
                its.tabs[ddname].f0a.plot->disabled(T);
             } else {
                its.tabs[ddname].f0a.plot->disabled(F);
             }
          }
          its.tabs[ddn]->enable();
       }
#
# Results
#
       its.tabs[ddname].f1 := its.ws.frame(its.tabs[ddname], side='top', expand='none');
#
# Min/max/Npts
#
       its.tabs[ddname].f1.f0 := its.ws.frame(its.tabs[ddname].f1, expand='x', side='left');
       its.tabs[ddname].f1.f0.l0 := its.ws.label(its.tabs[ddname].f1.f0, 'Min', width=4);
       its.tabs[ddname].f1.f0.min := its.ws.listbox(its.tabs[ddname].f1.f0, height=1, width=10, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f1.f0.min, 'Minimum value');
#
       its.tabs[ddname].f1.f0.l1 := its.ws.label(its.tabs[ddname].f1.f0, 'Max', width=4);
       its.tabs[ddname].f1.f0.max := its.ws.listbox(its.tabs[ddname].f1.f0, height=1, width=10, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f1.f0.max, 'Maximum value');
#
       its.tabs[ddname].f1.f0.l2 := its.ws.label(its.tabs[ddname].f1.f0, 'nPts', width=6);
       its.tabs[ddname].f1.f0.npts := its.ws.listbox(its.tabs[ddname].f1.f0, height=1, width=10, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f1.f0.npts, 'Number of unmasked points');
       its.tabs[ddname].f1.f0.space := its.ws.frame(its.tabs[ddname].f1.f0, expand='x', height=1, width=1);
#
# Min/max locations
#
       its.tabs[ddname].f1.f3 := its.ws.frame(its.tabs[ddname].f1, expand='x', side='left');
       its.tabs[ddname].f1.f3.l0 := its.ws.label(its.tabs[ddname].f1.f3, 'MinPos', width=4);
       its.tabs[ddname].f1.f3.minpos := its.ws.listbox(its.tabs[ddname].f1.f3, height=1, width=10, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f1.f3.minpos, 'Absolute pixel coordinate of minimum value');
#
       its.tabs[ddname].f1.f3.l1 := its.ws.label(its.tabs[ddname].f1.f3, 'world', width=4); 
       its.tabs[ddname].f1.f3.minposf := its.ws.listbox(its.tabs[ddname].f1.f3, height=1, width=28, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f1.f3.minposf, 'Absolute world coordinate of minimum value');
#
       its.tabs[ddname].f1.f4 := its.ws.frame(its.tabs[ddname].f1, expand='x', side='left');
       its.tabs[ddname].f1.f4.l0 := its.ws.label(its.tabs[ddname].f1.f4, 'MaxPos', width=4);
       its.tabs[ddname].f1.f4.maxpos := its.ws.listbox(its.tabs[ddname].f1.f4, height=1, width=10, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f1.f4.maxpos, 'Absolute pixel coordinate of maximum value');
#
       its.tabs[ddname].f1.f4.l1 := its.ws.label(its.tabs[ddname].f1.f4, 'world', width=4);
       its.tabs[ddname].f1.f4.maxposf := its.ws.listbox(its.tabs[ddname].f1.f4, height=1, width=28, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f1.f4.maxposf, 'Absolute world coordinate of maximum value');
#
# Sum/mean/flux
#
       its.tabs[ddname].f1.f1 := its.ws.frame(its.tabs[ddname].f1, expand='x', side='left');
       its.tabs[ddname].f1.f1.l0 := its.ws.label(its.tabs[ddname].f1.f1, 'Sum', width=4);
       its.tabs[ddname].f1.f1.sum:= its.ws.listbox(its.tabs[ddname].f1.f1, height=1, width=10, fill='none'); 
       its.ws.popuphelp(its.tabs[ddname].f1.f1.sum, 'sum = SUM I_i');
#
       its.tabs[ddname].f1.f1.l1 := its.ws.label(its.tabs[ddname].f1.f1, 'Mean', width=4); 
       its.tabs[ddname].f1.f1.mean := its.ws.listbox(its.tabs[ddname].f1.f1, height=1, width=10, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f1.f1.mean, 'mean = 1/n * SUM I_i');
#
       its.tabs[ddname].f1.f1.l2 := its.ws.label(its.tabs[ddname].f1.f1, 'Flux', width=6);
       its.tabs[ddname].f1.f1.flux := its.ws.listbox(its.tabs[ddname].f1.f1, height=1, width=10, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f1.f1.flux, 'Integrated flux density if beam present and units Jy/beam');
       its.tabs[ddname].f1.f1.space := its.ws.frame(its.tabs[ddname].f1.f1, expand='x', height=1, width=1);
#
# Variance/Standard deviation/rms
#
       its.tabs[ddname].f1.f2 := its.ws.frame(its.tabs[ddname].f1, expand='x', side='left');
#
       its.tabs[ddname].f1.f2.l1 := its.ws.label(its.tabs[ddname].f1.f2, 'Var', width=4);
       its.tabs[ddname].f1.f2.var := its.ws.listbox(its.tabs[ddname].f1.f2, height=1, width=10, fill='none');  
       its.ws.popuphelp(its.tabs[ddname].f1.f2.var, 'variance = 1/(n-1) * SUM (I_i - mean)^2');
#
       its.tabs[ddname].f1.f2.l0 := its.ws.label(its.tabs[ddname].f1.f2, 'StdDev', width=4);
       its.tabs[ddname].f1.f2.stddev:= its.ws.listbox(its.tabs[ddname].f1.f2, height=1, width=10, fill='none'); 
       its.ws.popuphelp(its.tabs[ddname].f1.f2.stddev, 'standard deviation = sqrt(variance)');
#
       its.tabs[ddname].f1.f2.l2 := its.ws.label(its.tabs[ddname].f1.f2, 'Rms', width=6);   
       its.tabs[ddname].f1.f2.rms:= its.ws.listbox(its.tabs[ddname].f1.f2, height=1, width=10, fill='none');
       its.tabs[ddname].f1.f2.space := its.ws.frame(its.tabs[ddname].f1.f2, expand='x', height=1, width=1);
       its.ws.popuphelp(its.tabs[ddname].f1.f2.rms, 'root mean square = sqrt(1/n * SUM (I_i)^2}');
#
# Median, median deviations, inter quartile  range
#
       its.tabs[ddname].f1.f5 := its.ws.frame(its.tabs[ddname].f1, expand='x', side='left');
#
       its.tabs[ddname].f1.f5.l0 := its.ws.label(its.tabs[ddname].f1.f5, 'Median', width=4); 
       its.tabs[ddname].f1.f5.median := its.ws.listbox(its.tabs[ddname].f1.f5, height=1, width=10, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f1.f5.median, 'Median value (50% largest value)');
#
       its.tabs[ddname].f1.f5.l1 := its.ws.label(its.tabs[ddname].f1.f5, 'MedDev', width=4);
       its.tabs[ddname].f1.f5.meddev := its.ws.listbox(its.tabs[ddname].f1.f5, height=1, width=10, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f1.f5.meddev, 'Median of the absolute deviations from the median');
#
       its.tabs[ddname].f1.f5.l2 := its.ws.label(its.tabs[ddname].f1.f5, 'Quartile', width=6);
       its.tabs[ddname].f1.f5.quartile := its.ws.listbox(its.tabs[ddname].f1.f5, height=1, width=10, fill='none');
       its.ws.popuphelp(its.tabs[ddname].f1.f5.quartile, 
                        'The inter-quartile range (0.5 * [75% largest value - 25% largest value])');

# Add new TAB to the tabdialog widget

      ok := its.td.add(its.tabs[ddname], tabname);
      if (is_fail(ok)) fail;
      if (length(its.td.list())==1)  its.td.front(tabname);
#
      its.ws.tk_release();
#
      return T;
    }

###      
   const its.plotHistogram := function (im, ddname, region=unset)
   {   
      wider its;  
         
# Set plotter name.  Make a random name so each image gets its own 

      if (!has_field(its.plotter, ddname)) {
         its.plotter[ddname] := spaste(ddname, '_plotter',  '/glish');
      }
      if (is_unset(region) || length(region)==0) {
 
# Full image
      
         return im.histograms(plotter=its.plotter[ddname]);
      } else {
    
# Specified region
   
         return im.histograms(plotter=its.plotter[ddname], region=region);
      }
   }
 

###
    const its.writeGui := function (rec, stats)
    {
       its.ws.tk_hold();
       its.clearGui (rec);
#
       if (length(stats.npts)>0) {
          rec.f1.f0.min->insert(sprintf("%8.3e", stats.min));
          rec.f1.f0.max->insert(sprintf("%8.3e", stats.max));
          rec.f1.f0.npts->insert(as_string(stats.npts));
#
          rec.f1.f1.sum->insert(sprintf("%8.3e", stats.sum));
          rec.f1.f1.mean->insert(sprintf("%8.3e", stats.mean));   
          if (has_field(stats, 'flux')) {
             rec.f1.f1.flux->insert(sprintf("%8.3e", stats.flux));
          }
#
          rec.f1.f2.stddev->insert(sprintf("%8.3e", stats.sigma));
          rec.f1.f2.var->insert(sprintf("%8.3e", (stats.sigma)*(stats.sigma)));
          rec.f1.f2.rms->insert(sprintf("%8.3e", stats.rms));
#
          rec.f1.f3.minpos->insert(paste(as_string(stats.minpos)));
          rec.f1.f3.minposf->insert(stats.minposf);
#
          rec.f1.f4.maxpos->insert(paste(as_string(stats.maxpos)));
          rec.f1.f4.maxposf->insert(stats.maxposf);
#
          if (has_field(stats, 'median')) {
             rec.f1.f5.median->insert(sprintf("%8.3e", stats.median));
             rec.f1.f5.meddev->insert(sprintf("%8.3e", stats.medabsdevmed));
             rec.f1.f5.quartile->insert(sprintf("%8.3e", stats.quartile));
          }
       } else {
         note ('No valid points in region', origin='imageviewersupport.g',
               priority='WARN');
       }
#
       its.ws.tk_release();
       return T;
    }


### Public methods

###
    const self.add := function (ddname) 
    {
       wider its;
#     
       if (has_field(its.index, ddname) && its.active[ddname]) {
          return throw (spaste('Entry ', ddname, ' is already active'),
                        origin='viewerimagestatistics.add');
       }
#
       its.imageTools[ddname] := its.getImageTool(ddname);
       ok := its.addOneTab(ddname); 
       if (is_fail(ok)) fail;
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
                        origin='viewerimagestatistics.delete');   
       }
#
       idx := its.index[ddname];
       tabname := its.tabnames[idx];
       ok := its.td.delete(tabname); 
       if (is_fail(ok)) fail;
#
       if (is_region(its.region[ddname])) {
          ok := its.region[ddname].done();
          if (is_fail(ok)) fail;
       }
#
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
             if (is_region(its.region[ddname])) {
                ok := its.region[ddname].done();
                if (is_fail(ok)) fail;
             }
          }
       }
       val its := F;
       val self := F;
#
       return T;
    }

###
   self.insertregion := function (region, true=F)
   {
      wider its;

# Distribute over DDs

      for (ddname in its.ddnames) {
         if (its.active[ddname]) {
            its.tabs[ddname]->disable();

# Convert pseudoregion to world region via callback

            local rr;
            if (!true) {
               rr := its.pseudoToWorldRegion(ddname, region, T);
               if (is_fail(rr)) {
                  its.tabs[ddname]->enable();
                  fail;
               }
            } else {
               rr := region;
            }

# Generate statistics 

            robust := its.tabs[ddname].f0.robust->state();
            extend := its.tabs[ddname].f0.extend->state();
#
            if (extend) {

# Learn some things about image

               cs := its.imageTools[ddname].coordsys();
               shp := its.imageTools[ddname].shape();
               pixelAxis := its.getMovieAxis (ddname);
               blc := '1pix';
               trc := spaste (shp[pixelAxis], 'pix');

# Get extend range

               xx := its.tabs[ddname].f0.extendEntry->get();
               vv := dms.tovector(xx, 'integer');
               nv := length(vv);
               if (is_integer(vv) && nv>0) {
                 vv := sort(vv);
                 if (nv>0) blc := spaste (vv[1], 'pix');
                 if (nv>1) trc := spaste (vv[2], 'pix');
               } else {
                  note ('Invalid region extension range, extending over full length of movie axis',
                        priority='WARN', origin='viewerimagestatistics.insertregion');
               }

# Find out the movie axis and make world box for it.

               extendBox := drm.wbox (blc=blc, trc=trc, pixelaxes=pixelAxis, csys=cs);
               if (is_fail(extendBox)) {
                  its.tabs[ddname]->enable();
                  fail;
               }
               ok := cs.done()

# Now extend region over image for the movie axis

               its.region[ddname] := drm.extension (region=rr, box=extendBox);
               if (is_fail(its.region[ddname])) {
                  its.tabs[ddname]->enable();
                  fail;
               }
               ok := extendBox.done();
               if (!true) ok := rr.done();
            } else {
               its.region[ddname] := rr;
            }

# Generate statistics

            ok := its.imageTools[ddname].statistics(statsout=its.stats[ddname], region=its.region[ddname],
                                                    async=F, list=F, robust=robust);
            if (is_fail(ok)) {
               its.tabs[ddname]->enable();
               fail;
            }
#
            its.writeGui (its.tabs[ddname], its.stats[ddname]);
            rec := its.assembleEvent (ddname);
            if (its.tabs[ddname].f0.autocopy->state()) {
               dcb.copy(rec);
            }
            if (its.tabs[ddname].f0a.autoplot->state()) {
              ok := its.plotHistogram(its.imageTools[ddname], ddname, region=its.region[ddname]);
              if (is_fail(ok)) {
                 its.tabs[ddname]->enable();
                 fail;
              }
            }
            self->statistics(rec);
            its.tabs[ddname]->enable();
         }
      }
   }

###
   const self.setcallbacks := function (callback1=unset, callback2=unset,
                                        callback3=unset, callback4=unset)
#
# The idea is to get viewerimageanalysis to do as much of the
# work as possible, and keept viewerimagestatistics down largely
# to an interface layer.  So we use callbacks, inserted by viewerimageanalysis
# to do the work for us.
#
   {
      wider its;

# Arg. ddname, returns image Tool

      if (is_function(callback1)) {
         its.getImageTool := callback1;
      } else {
         if (!is_unset(callback1)) {
            return throw ('callback1 is not a function',
                           origin='viewerimagestatistics.setcallbacks');
         }
      }

# Arg. ddname, returns zoomed region of display

      if (is_function(callback2)) {
         its.getZoomedRegion := callback2;
      } else {
         if (!is_unset(callback2)) {
            return throw ('callback2 is not a function',
                           origin='viewerimagestatistics.setcallbacks');
         }
      }

# Arg. ddname, pseudoregion and intersect; returns world region

      if (is_function(callback3)) {
         its.pseudoToWorldRegion := callback3;
      } else {
         if (!is_unset(callback3)) {
            return throw ('callback3 is not a function',
                           origin='viewerimagestatistics.setcallbacks');
         }
      }

# Arg. ddname, returns movie axis
                           
      if (is_function(callback4)) {
         its.getMovieAxis := callback4;
      } else {                          
         if (!is_unset(callback4)) {
            return throw ('callback4 is not a function',
                           origin='viewerimagestatistics.setcallbacks');
         }
      } 
#
      return T;
   }

### Constructor


# Tab dialog 

   its.td := its.ws.tabdialog(parent, colmax=3, title=unset);
   if (is_fail(its.td)) fail;

# Frame to put all the TABS in

   its.tdf := its.td.dialogframe();
   if (is_fail(its.tdf)) fail;
}
