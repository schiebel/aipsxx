# pixelrange.g: widget for pixel range selection
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
include 'radiobuttons.g'
include 'widgetserver.g'
include 'unset.g'



const pixelrange := subsequence (ref parent=F, min=0.0, max=1.0, 
                                 labels="include exclude all", widgetset=dws)
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment variable is not set',
                   origin='pixelrange.g');
   }
   if (length(labels)!=3) {
      return throw('You must give three labels', origin='pixelrange.g');
   }
#
   prvt := [=];
   prvt.min := min;
   prvt.max := max;
   prvt.state := [=];
   prvt.labels := labels;
#

### Constructor

#
   widgetset.tk_hold();
   prvt.f0 := widgetset.frame(parent, expand='both', side='left', 
                              relief='raised');
   prvt.f0->unmap();
   widgetset.tk_release();
#
   prvt.f0.f0 := widgetset.frame(prvt.f0, side='left');
   prvt.f0.f0.label := widgetset.label(prvt.f0.f0, 'Pixel\nRange',
                                       width=6);

   hlp := spaste('Select all pixels, or an inclusion or an exclusion intensity range');        
   widgetset.popuphelp(prvt.f0.f0.label, hlp, width=80);
   prvt.f0.f0.which := radiobuttons(parent=prvt.f0.f0, names=labels,
                                    default=3, side='top',
                                    widgetset=widgetset);
#   
   prvt.f0.f1 := widgetset.frame(parent=prvt.f0, side='top');
   prvt.f0.f1.rmin := widgetset.multiscale(parent=prvt.f0.f1,
                                          start=prvt.min, end=prvt.max,
                                          values=[prvt.min],
                                          resolution=(prvt.max-prvt.min)/500.0,
                                          entry=T, extend=F, names=['Min']);
   if (is_fail(prvt.f0.f1.rmin)) fail;
   prvt.f0.f1.rmax:= widgetset.multiscale(parent=prvt.f0.f1,
			    start=prvt.min, end=prvt.max,
                            values=[prvt.max],
			    resolution=(prvt.max-prvt.min)/500.0,
			    entry=T, extend=F, names=['Max']);
   if (is_fail(prvt.f0.f1.rmax)) fail;
#
# Deactivate sliders for 'all' pixels  (initial state)
#
   prvt.f0.f1.rmin.disable();
   prvt.f0.f1.rmax.disable();
   prvt.state.range := F;
   whenever prvt.f0.f0.which->value do {
      if ($value.name==prvt.labels[3]) {
          prvt.f0.f1.rmin.setvalues(prvt.min);
          prvt.f0.f1.rmax.setvalues(prvt.max);
	  prvt.f0.f1.rmin.disable();
	  prvt.f0.f1.rmax.disable();
          prvt.state.range := F;
      } else {
	  prvt.f0.f1.rmin.enable();
	  prvt.f0.f1.rmax.enable();
          prvt.state.range := T;
      }
   }
   ok := prvt.f0->map();


###
   const self.disabled := function (which=unset, sliders=unset) 
   {
      wider prvt;
      if (is_unset(which)) {
#
      } else if (which) {
         prvt.f0.f0.which.disabled(disable=T, allbuttons=F);
      } else if (!which) {
         prvt.f0.f0.which.disabled(disable=F, allbuttons=T);
      }
#
      if (is_unset(sliders)) {
#
      } else if (sliders) {
         prvt.f0.f1.rmin.disable();
         prvt.f0.f1.rmax.disable();
      } else {
         prvt.f0.f1.rmin.enable();
         prvt.f0.f1.rmax.enable();
      }
   }

###
   const self.disableallbutton := function ()
   {
      wider prvt;
      prvt.f0.f0.which.disablebutton(3);
   }

###
   const self.enableallbutton := function ()
   {
      wider prvt;
      prvt.f0.f0.which.enablebutton(3);
   }

###
   const self.done := function ()
   {
      wider prvt, self;
#
# Data selection widgets
#
      prvt.f0.f0.which.done();
      prvt.f0.f1.rmin.done();
      prvt.f0.f1.rmax.done();
#
      val prvt := F;
      val self := F;
      return T;
   }

###
   const self.getslidervalues := function () 
   {
      values := [];
      values[1] := prvt.f0.f1.rmin.getvalues()[1];
      values[2] := prvt.f0.f1.rmax.getvalues()[1];
      return values;
   }

###
   const self.getradiovalue := function () 
   {
      return prvt.f0.f0.which.getvalue();
   }

###
   const self.setrange := function (min, max)
   {
      wider prvt;
      prvt.min := min;
      prvt.max := max;
#
      if (prvt.state.range==F) {
	  prvt.f0.f1.rmin.enable();
	  prvt.f0.f1.rmax.enable();
      }
#
      prvt.f0.f1.rmin.setrange(prvt.min, prvt.max);
      prvt.f0.f1.rmin.setresolution((prvt.max-prvt.min)/500.0);
      prvt.f0.f1.rmin.setvalues(prvt.min);
#
      prvt.f0.f1.rmax.setrange(prvt.min, prvt.max);
      prvt.f0.f1.rmax.setresolution((prvt.max-prvt.min)/500.0);
      prvt.f0.f1.rmax.setvalues(prvt.max);
#
      if (prvt.state.range==F) {
	  prvt.f0.f1.rmin.disable();
	  prvt.f0.f1.rmax.disable();
      }
      return T;
   }

###
   const self.setradiovalue := function (idx, state)
   {
      wider prvt;
      idx2 := idx;
      if (is_string(idx)) {
         if (idx==prvt.labels[1]) {
            idx2 := 1;
         } else if (idx==prvt.labels[2]) {
            idx2 := 2;
         } else if (idx==prvt.labels[3]) {
            idx2 := 3;
         }
      }      
      prvt.f0.f0.which.setstate(idx2, state);
      return T;
   }
}


