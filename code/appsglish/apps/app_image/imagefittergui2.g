# imagefittergui2.g: Secondary GUI for imagefitter 
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
#   $Id: imagefittergui2.g,v 19.3 2004/08/25 00:57:47 cvsmgr Exp $
#
# Emits events  
#
# Event     Value                     Meaning
# done        -                       when this subsequence has been doned
# fit                                 User user wants to do a fit. 
#               rec.region            The region to fit
#               rec.estimate          The estimate (componentlist) of the fit
#               rec.fixed[n]          For each component a string indicating
#                                     which parameter is fixed (fxyabp)

pragma include once

include 'componentlist.g';
include 'fitterparameters.g'
include 'helpmenu.g';
include 'illegal.g';
include 'image.g';
include 'measures.g';
include 'note.g';
include 'quanta.g';
include 'serverexists.g';
include 'timer.g';
include 'unset.g';
include 'viewerimageshowregions.g'
include 'viewershowcomponentlist.g'
include 'widgetserver.g';

const imagefittergui2 := subsequence (ref theImage, n=1, ref theDisplayPanel, 
                                      ref theRegionManager, widgetset=ddlws,
                                      ref theDDD)
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment variable is not set',
                   origin='imagefittergui2.g');
   }
   if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is either not running not valid',
                    origin='imagefittergui2.g');
    }
   if (!serverexists('dm', 'measures', dm)) {
      return throw('The measures server "dm" is either not running not valid',
                    origin='imagefittergui2.g');
    }

#
   its := [=];
   its.bunit := '';              # Brightness unit
   its.coordsys := [=];          # Coordsys tool
   its.componentTypes := "Gaussian Point";   # Component types
#
   its.skyaxes := [=];           # Which axes hold the sky
   its.skyaxes.world := [];      
   its.skyaxes.pixel := [];
   its.axisIncr := [];           # Axis increments for sky
   its.axisUnits := "";          # Axis units for sky
   its.refVal := [];             # Axis reference values for sky
#
   its.message := ['',''];       # MEssage line 
   its.enabled := T;
#
   its.frames := [=];            # Where all the component frames go
   its.tab := [=];
   its.tabframe := [=];
   its.n := 0;                   # Number components
   its.type := [=];              # Model type of current tabbed component
#
   its.ge := widgetset.guientry();
   if (is_fail(its.ge)) fail;
#
   its.fp := fitterparameters(widgetset=widgetset);      # Tool to make parameter entries
   if (is_fail(its.fp)) fail;
#
   its.visr := viewerimageshowregions(theDDD);           # Tool to show regions
   if (is_fail(its.visr)) fail;
   its.regionIDs := [=];                                 # ids of region DDDs
#
   its.vscl := viewershowcomponentlist(theDDD);          # Tool to show componentlists 
   if (is_fail(its.vscl)) fail;
   its.clIDs := [=];                                    # ids of cl DDDs
   its.showButtons := [=];
#
   its.widths := [5, 15, 3, 13, 13];        # Widths for entry widgets: label, estimate, fixed, fit, error
#
   its.polarization := [=];          # Describes polarization state of displayed image
                                     # Gets updated from time to time
   its.ddoptions := [=];             # The ddoptions from the main image displaydata
                                     # Gets updated from time to time
#
   its.busy := [=];                  # Protection for re-entrant whenevers
   its.busy.regionshow := F;

### Private functions


###
   const its.autoEstimate := function (n=1)
   {
      wider its;
      which := its.tab.which(); 
      fn := spaste(which.index);
      type := its.type[fn];
#
      type := 'GAUSSIAN'                  # Only Gaussian auto estimates available
      region := self.getregion();
#
      local cl;
      if (n==1) {
         local p, m, c;
         cl := theImage.fitsky(pixels=p, pixelmask=m, converged=c,
                               models=type, region=region, fit=F,
                               deconvolve=F);
      } else {
         cl := theImage.findsources(nmax=n, region=region, point=F, width=5);
      }
#
      return cl;
   }

### 
   const its.defineSillyBeamStuff := function ()
   {
      rb := theImage.restoringbeam();
      if (is_fail(rb)) fail;
      if (length(rb)>0) {
         maj := dq.convert(rb.major, 'rad');
         min := dq.convert(rb.minor, 'rad');
         fac := pi / 4.0 / ln(2.0) * maj.value * min.value;
         str := spaste(fac, 'rad2');
         ok := dq.define('beam', str);
         if (is_fail(ok)) fail;
      }
#
      q1 := dq.quantity(abs(its.axisIncr[1]), its.axisUnits[1]);
      if (is_fail(q1)) fail;
      q2 := dq.quantity(abs(its.axisIncr[1]), its.axisUnits[1]);
      if (is_fail(q2)) fail;      
      fac := dq.convert(q1, 'rad').value * dq.convert(q2, 'rad').value;
      str := spaste(fac, 'rad2');
      ok := dq.define('pixel', str);
      if (is_fail(ok)) fail;
#
      q1 := dq.quantity(1.0, its.bunit);
      if (is_fail(q1)) fail;
      q2 := dq.quantity(1.0, 'rad2');
      q3 := dq.mul(q1, q2);
      if (is_fail(q3)) fail;
      if (!dq.compare(q3, 'Jy')) {
         wider its;
         its.bunit := 'Jy/pixel';
      }
   }


###
   const its.dddSkyCoordToPixel := function (coord)
#
# Convert a DDD coordinate (the sky) to pixels (all dimensions)
# For the non-sky dimensions we just use the reference pixel.  
# This does not correctly  reflect the zaxis or hidden 
# axis selections.  SO use with care
#
   {
      wider its;
#
      wc := its.refVal;                   # Holds sky only which is axes 1 and 2
#
      wqc := dq.convert(coord[1], its.axisUnits[1]);
      if (is_fail(wqc)) fail;
      wc[1] := dq.getvalue(wqc);
#
      wqc := dq.convert(coord[2], its.axisUnits[2]);
      if (is_fail(wqc)) fail;
      wc[2] := dq.getvalue(wqc);
#
      return theImage.topixel(wc);        # Pads others with refpix
   }      


###
   const its.indicateRegionInserted := function (interval, name)
   {
      its.f0.f1.f0.indicate->state(F);
      return T;
   }


###
   const its.insertestimate := function (estimate, whichEst=1, whichGUI=unset)
#
# The estimate is a ddd description or a componentlist. 
#
# ddd description
# type=rectangle
# color=red, 
# label=, 
# id=1, 
# blc=[0.00872664626 0.00872664626] , 
# trc=[0.0174532925 0.0174532925] 
#
   {
      wider its;
#
      if (is_unset(whichGUI)) {
         whichGUI := its.tab.which();
         fn := spaste(whichGUI.index);
      } else {
         fn := spaste(as_integer(whichGUI));
      }
      typeGUI := its.type[fn];
#
      if (is_componentlist(estimate)) {
         const n := estimate.length();
         if (whichEst > n) {
            s := spaste('Requested component ', whichEst, ' does not exist in estimate componentlist');
            note(s, priority='SEVERE', origin='imagefittergui2.insertestimate');
            return F;
         }
#
#
#         if (typeGUI!=typeCL) {
#            note('Cannot insert fit, GUI and fit component types are inconsistent',
#                 priority='SEVERE', origin='imagefittergui2.insertestimate');
#            return F;
#         }
#
# Position
#
         if (its.frames[fn].f1.pars.pos.fixed->state()==F) {
            d := estimate.getrefdir(whichEst);
            its.fp.insertestimate(its.frames[fn].f1.pars.pos, d);
         }
#
# Shape.  
#      
         shp := estimate.getshape(whichEst);         
         typeCL := to_upper(estimate.shapetype(whichEst));
         if (length(shp) > 0 && (typeGUI=='GAUSSIAN' || typeGUI=='DISK')) {
            if (its.frames[fn].f1.pars.major.fixed->state()==F) {
               its.fp.insertestimate(its.frames[fn].f1.pars.major, shp.majoraxis);
            }
            if (its.frames[fn].f1.pars.minor.fixed->state()==F) {
               its.fp.insertestimate(its.frames[fn].f1.pars.minor, shp.minoraxis);
            }
            tmp := dq.convert(shp.positionangle, 'deg');
            if (its.frames[fn].f1.pars.pa.fixed->state()==F) {
               its.fp.insertestimate(its.frames[fn].f1.pars.pa, tmp);
            }
         }
#
# Flux.  Convert from integral to peak for presentation to user.
#
         if ((typeCL=='GAUSSIAN' || typeCL=='DISK')) {
            if (its.frames[fn].f1.pars.flux.fixed->state()==F) {
               f := estimate.getfluxvalue(whichEst)[its.polarization.index];
               u := estimate.getfluxunit(whichEst);
#
               intFlux := dq.quantity(f,u);
               peakFlux := theImage.convertflux(value=intFlux, topeak=T, major=shp.majoraxis,
                                                minor=shp.minoraxis, type=typeCL);
               if (is_fail(peakFlux)) fail; 
               its.fp.insertestimate(its.frames[fn].f1.pars.flux, peakFlux);
            }
         } else {

# Point

            f := estimate.getfluxvalue(whichEst)[its.polarization.index];
            u := estimate.getfluxunit(whichEst);
            peakFlux := dq.quantity(f,theImage.brightnessUnit());
            its.fp.insertestimate(its.frames[fn].f1.pars.flux, peakFlux);
         }
      } else {
#
# The estimate has come from the DDD.    Fish out the values.
#
         typeEst := to_upper(estimate.type);
         qcenter := estimate.center;
         qmajor := estimate.major;
         qminor := estimate.minor;
         qpa := estimate.positionangle;         

# Find a rough averaged width in pixels

         incr := its.coordsys.increment(type='direction', format='q')
         if (is_fail(incr)) fail;
         qmajor2 := dq.convert(qmajor, 'arcsec');
         if (is_fail(qmajor2)) fail;
         qminor2 := dq.convert(qminor, 'arcsec');
         if (is_fail(qminor2)) fail;
         majminav := (dq.getvalue(qmajor2) + dq.getvalue(qminor2)) / 2.0;
#
         inc2 := incr;
         for (i in 1:length(incr)) {
            inc2[i] := dq.convert(incr[i], 'arcsec');
            if (is_fail(inc2[i])) fail;
          }
#
         incv := dq.getvalue(inc2);
         if (is_fail(incv)) fail;
         incav := (abs(incv[1]) + abs(incv[2])) / 2.0;
         pmajmin := majminav / incav;
#

         if (typeEst=='ELLIPSE') {
#
# Centre 
#
            pc := its.dddSkyCoordToPixel(estimate.center)
            if (is_fail(pc)) fail;
            wc := its.coordsys.toworld(pc, 'm');
            if (is_fail(wc)) fail;
#
            if (its.frames[fn].f1.pars.pos.fixed->state()==F) {
               its.fp.insertestimate(its.frames[fn].f1.pars.pos, wc.direction);
            }
#
# Get very rough peak flux in shape (pretend its a rectangle)
#
            local peakFlux;
            if (its.frames[fn].f1.pars.flux.fixed->state()==F) {
               zidx :=  theDisplayPanel.animator().currentframe();
               plane := theRegionManager.displayedplane(theImage, its.ddoptions,
                                                        zidx, asworld=F);
               bb := theImage.boundingbox(region=plane);
               if (is_fail(bb)) fail;
#
               pblc := bb.blc;                                      # Only for non-sky axes
               pblc[its.skyaxes.pixel] := pc[its.skyaxes.pixel] - pmajmin;
#
	       ptrc := bb.blc;                                      # Only for non-sky axes
               ptrc[its.skyaxes.pixel] := pc[its.skyaxes.pixel] + pmajmin;
#
               pbox := theRegionManager.box(blc=pblc, trc=ptrc);
               ok := theImage.statistics(statsout=stats, region=pbox, list=F);
               if (is_fail(ok)) fail;
#
               tmp := stats.max;
               if (abs(stats.min) > abs(stats.max)) tmp := stats.min;
               peakFlux := dq.quantity(tmp, its.bunit);
            }
#
# Peak flux 
#
            if (its.frames[fn].f1.pars.flux.fixed->state()==F) {
               its.fp.insertestimate(its.frames[fn].f1.pars.flux, peakFlux);
            }

            if (typeGUI=='GAUSSIAN' || typeGUI=='DISK') {
#
# Width 
#
               if (its.frames[fn].f1.pars.major.fixed->state()==F) {
                  its.fp.insertestimate(its.frames[fn].f1.pars.major, dq.convert(qmajor, 'arcsec'));
                  }
               if (its.frames[fn].f1.pars.minor.fixed->state()==F) {
                  its.fp.insertestimate(its.frames[fn].f1.pars.minor, dq.convert(qminor, 'arcsec'));
               }
#
# Position Angle
#
               if (its.frames[fn].f1.pars.pa.fixed->state()==F) {
                  its.fp.insertestimate(its.frames[fn].f1.pars.pa, dq.convert(qpa, 'deg'));
               }
            }
         } else {
            note ('Estimate cannot be decoded',
                  priority='SEVERE', origin='imagefittergui2.insertEstimate');
         }
      }
      return T;
   }



###
   const its.interactiveEstimate := function ()
   {
      wider its;
      self.disable();
#
      which := its.tab.which();
      fn := spaste(which.index);
      type := its.type[fn];

# Put DDD in the center of the zoomed display. Get panel status

      status := theDisplayPanel.status();
      if (is_fail(status)) fail;

# The blc/trc reflects the zoom

      qBlc := r_array(dq.quantity(0.0, 'rad'), shape=2, id='quant');
      qTrc := r_array(dq.quantity(0.0, 'rad'), shape=2, id='quant');
      for (i in 1:2) {
         qBlc[i] := dq.quantity(status.paneldisplay.worldblc[i], 
                                status.paneldisplay.axisunits[i])
         qTrc[i] := dq.quantity(status.paneldisplay.worldtrc[i], 
                                status.paneldisplay.axisunits[i])
      }
      pBlc := its.coordsys.topixel(qBlc);
      if (is_fail(pBlc)) fail;
      pTrc := its.coordsys.topixel(qTrc);
      if (is_fail(pTrc)) fail;
      pCen := (pBlc + pTrc) / 2.0;
      shp := pTrc - pBlc + 1;
#
      wCen := its.coordsys.toworld(pCen, 'q');
      if (is_fail(wCen)) fail;
#
      center := dq.quantity("1km 1GHz");
      center[1] := wCen[its.skyaxes.world[1]];
      center[2] := wCen[its.skyaxes.world[2]];
#
      incr := its.coordsys.increment(format='q');
      values := dq.getvalue(incr);
      units := dq.getunit(incr);
#
      n := min(shp[its.skyaxes.pixel] / 2.0);
      t := abs(n*values[its.skyaxes.world[1]]);
      major := dq.quantity(t, units[its.skyaxes.world[1]]);
      t := abs(n/2.0*values[its.skyaxes.world[2]]);
      minor := dq.quantity(t, units[its.skyaxes.world[2]]);
      positionangle := dq.quantity('0deg'); 
#
# Add the ddd object
#
#      if (type=='GAUSSIAN') {
#         rec.type := 'rectangle';
#      } else if (type=='DISK') {
#         rec.type := 'rectangle';
#      } else if (type=='POINT') {
#         rec.type := 'rectangle';
#      }
#
      rec := theDDD.makeellipse(center=center, major=major, minor=minor, 
                                positionangle=positionangle,
                                outline=T, movable=T, editable=T,
                                doreference=T, drawrectangle=F);
      if (is_fail(rec)) fail;
#
      id := theDDD.add(rec);
      if (is_fail(id)) fail;
#
      return T;
   }


###
   const its.makeOneFrame := function (i)
#
# Make the GUI for one component
#
   {
      wider its;
      fn := spaste(i);
      its.frames[fn] := widgetset.frame(its.tabframe, side='top', relief='raised');
      its.frames[fn]->unmap();
#
# Frame for buttons at top
#
      its.frames[fn].f0 := widgetset.frame(its.frames[fn], side='left', relief='flat');
#
# Select component type
#
      its.frames[fn].f0.f0 := widgetset.frame(its.frames[fn].f0, side='top', 
                                              relief='flat', expand='none');
      its.frames[fn].f0.f0.l0 := widgetset.label(its.frames[fn].f0.f0, 'Type');
      widgetset.popuphelp(its.frames[fn].f0.f0.l0, 'Select component type');
      its.frames[fn].f0.f0.om := widgetset.optionmenu(parent=its.frames[fn].f0.f0, 
                                                      names=its.componentTypes, 
                                                      values=its.componentTypes, 
                                                      labels=its.componentTypes);
      its.frames[fn].f0.f0.om.index := i;
      its.type[fn] := to_upper(its.frames[fn].f0.f0.om.getlabel());
#
# Spacer
#
      its.frames[fn].f0.f1 := widgetset.frame(parent=its.frames[fn].f0, 
                                              height=3, expand='x', relief='flat');
#
# Buttons for estimates. Currently a check button. Will be action
# when david gives me DD to use ellipse/cursor estimates etc.
#
      its.frames[fn].f0.f2 := widgetset.frame(its.frames[fn].f0, side='top', 
                                              relief='flat', width=1, expand='none');
      its.frames[fn].f0.f2.l0 := widgetset.label(its.frames[fn].f0.f2, 'Estimates');
      txt := spaste('You can make an interactive or automatic estimate\n',
                    'for this component - see popuphelp on Inter and Auto buttons');
      widgetset.popuphelp(its.frames[fn].f0.f2.l0, txt, 
                          'Make an estimate for this component', 
                           combi=T, width=100);
      its.frames[fn].f0.f2.f0 := widgetset.frame(its.frames[fn].f0.f2, width=1, 
                                                 side='left', relief='flat');

# Auto estimate

      its.frames[fn].f0.f2.f0.autoest := widgetset.button(parent=its.frames[fn].f0.f2.f0, 
                                                          text='Auto');
      txt := spaste('When you press the "Auto" button, an estimate is\n',
                    'automatically made for you.  This estimate is made\n',
                    'only from the pixels in the currently housed region.\n',
                    'Make sure this region is the one you want');
      widgetset.popuphelp(its.frames[fn].f0.f2.f0.autoest, txt, 
                          'Automatic estimate', combi=T);
#
      whenever  its.frames[fn].f0.f2.f0.autoest->press do {
         self.insertmessage('Generating estimate');
         self.disable();
         self.clearfit();
         cl := its.autoEstimate(n=1);
         if (is_fail(cl)) {
            self.enable();
            note(cl::message, priority='SEVERE', origin='imagefittergui2.makeOneFrame');
         } else {
            ok := its.insertestimate(estimate=cl);
            if (is_fail(ok)) {
               self.enable();
               note(ok::message, priority='SEVERE', origin='imagefittergui2.makeOneFrame');
            }
         }
         self.enable();
         self.insertmessage('When estimate OK, press "Fit"');
      }

# Interactive estimate

      its.frames[fn].f0.f2.f0.intest := widgetset.button(parent=its.frames[fn].f0.f2.f0, 
                                                         text='Inter');
      txt := spaste('When you press the "Inter" button an elliptical \n',
                    'overlay will appear on the display.  Click within it\n',
                    '(left button) to select it.  Then move or reshape \n',
                    '(rotate via shift-left button) as desired.  Double \n',
                    'click within it to make the estimate');
      widgetset.popuphelp(its.frames[fn].f0.f2.f0.intest, txt, 
                          'Interactive estimate', combi=T);
#
      whenever  its.frames[fn].f0.f2.f0.intest->press do {
         self.insertmessage('Select overlay, reshape, double click when ready');
         ok := its.interactiveEstimate();
         if (is_fail(ok)) {
            note(ok::message, priority='SEVERE', origin='imagefittergui2.makeOneFrame');
         }
      }
#
      its.frames[fn].f0.f2.f0.clearest := widgetset.button(parent=its.frames[fn].f0.f2.f0,
                                                           text='Clear');
      widgetset.popuphelp(its.frames[fn].f0.f2.f0.clearest, 'Clear estimate');
#
      whenever  its.frames[fn].f0.f2.f0.clearest->press do {
         self.clearestimate();
         self.clearfit();
      }

# Show estimate

      its.frames[fn].f0.f2.f0.show := widgetset.button(parent=its.frames[fn].f0.f2.f0,
                                                       text='Show');
      widgetset.popuphelp(its.frames[fn].f0.f2.f0.show, 'Show/hide estimate on display');
#
      whenever  its.frames[fn].f0.f2.f0.show->press do {
         ok := its.showEstimate(its.frames[fn].f0.f2.f0.show);
         if (is_fail(ok)) {
            note(ok::message, priority='SEVERE', origin='imagefittergui2.makeOneFrame');
         }
      }
      its.showButtons[fn] := ref its.frames[fn].f0.f2.f0.show;     # Alias
#
# Frame for parameters.  
#
      its.frames[fn].f1 := widgetset.frame(its.frames[fn], side='left', relief='flat');
#
# Align in vertical frames
#
      its.frames[fn].f1.labels := widgetset.frame(its.frames[fn].f1, side='top', relief='flat');
      its.frames[fn].f1.estimates := widgetset.frame(its.frames[fn].f1, side='top', relief='flat');
      its.frames[fn].f1.fixeds := widgetset.frame(its.frames[fn].f1, side='top', relief='flat');
      its.frames[fn].f1.fits := widgetset.frame(its.frames[fn].f1, side='top', relief='flat');
      its.frames[fn].f1.errors := widgetset.frame(its.frames[fn].f1, side='top', relief='flat');
#
      its.frames[fn].f1.labels.labtop := widgetset.label(its.frames[fn].f1.labels, 'Param', 
                                                         width=its.widths[1]);
      its.frames[fn].f1.estimates.labtop := widgetset.label(its.frames[fn].f1.estimates, 'Estimate', 
                                                            width=its.widths[2]);
      its.frames[fn].f1.fixeds.labtop := widgetset.label(its.frames[fn].f1.fixeds, '', width=its.widths[3]);
      its.frames[fn].f1.fits.labtop := widgetset.label(its.frames[fn].f1.fits, 'Fit', width=its.widths[4]);
      its.frames[fn].f1.errors.labtop := widgetset.label(its.frames[fn].f1.errors, 'Error', 
                                                         width=its.widths[5]);
#
# Destroy extant parameter widgets for this component
#
      its.frames[fn].f1.pars := [=];
#
# Create parameters entry/fit/error widgets
#
      its.makeParameters(its.frames[fn].f1.labels,
                         its.frames[fn].f1.estimates,
                         its.frames[fn].f1.fixeds,
                         its.frames[fn].f1.fits,
                         its.frames[fn].f1.errors,
                         'gaussian', its.widths, i);
#
# Add to TAB
#
      its.tab.add(its.frames[fn], fn);
#
# When user selects a new component type, destroy and remake parameters
# We have to go to a lot of bother to clean out the records of agents
#
      whenever its.frames[fn].f0.f0.om->select do {
         ag := $agent;
         gn := spaste(ag.index);
         type := to_upper(ag.getlabel());
         if (its.type[gn] != type) {
            widgetset.tk_hold();
#
            its.fp.cleanquantum (its.frames[gn].f1.pars.flux);
            its.fp.cleanpos2d (its.frames[gn].f1.pars.pos)
#
            if (its.type[gn]=='GAUSSIAN' || its.type[gn]=='DISK') {
               its.fp.cleanquantum(its.frames[gn].f1.pars.major);
               its.fp.cleanquantum(its.frames[gn].f1.pars.minor);
               its.fp.cleanquantum(its.frames[gn].f1.pars.pa);
            }
            its.frames[gn].f1.pars := F;
#
            its.makeParameters(its.frames[fn].f1.labels,
                               its.frames[fn].f1.estimates,
                               its.frames[fn].f1.fixeds,
                               its.frames[fn].f1.fits,
                               its.frames[fn].f1.errors,
                               $value.label, its.widths, ag.index);
            its.tab.replace(its.frames[gn], gn);
            its.tab.front(gn);
            widgetset.tk_release();
#
            its.type[gn] := type;
         }
      }
      return T;
   }

###
   const its.makeParameters := function (ref labels, ref estimates, 
                                         ref fixeds, ref fits, 
                                         ref errors, type, widths, i)
#
# Make entry/fix/fit/error widgets for component i of given type
#
   {
      wider its;
      fn := spaste(i);
#
      t := to_upper(type);
      its.fp.makequantum(labels, estimates, fixeds, fits, errors,
                         its.frames[fn].f1.pars, 'flux', widths, 
                         its.bunit, hlp='Peak brightness');
      its.fp.makepos2d (labels, estimates, fixeds, fits, errors,
                        its.frames[fn].f1.pars, widths, 
                        hlp='Position');
      if (t=='GAUSSIAN' || t=='DISK') {
         ok := its.fp.makequantum(labels, estimates, fixeds, fits, errors,
                                  its.frames[fn].f1.pars, 'major', widths, 
                                  'arcsec', hlp='Major axis FWHM');
         if (is_fail(ok)) fail;
         ok := its.fp.setestimateunitwidth (its.frames[fn].f1.pars.major, 6);
         if (is_fail(ok)) fail;
#
         its.fp.makequantum(labels, estimates, fixeds, fits, errors,
                            its.frames[fn].f1.pars, 'minor', widths,
                            'arcsec', hlp='Minor axis FWHM');
         if (is_fail(ok)) fail;
         ok := its.fp.setestimateunitwidth (its.frames[fn].f1.pars.minor, 6);
         if (is_fail(ok)) fail;

         its.fp.makequantum(labels, estimates, fixeds, fits, errors,
                            its.frames[fn].f1.pars, 'pa', widths,
                            'deg', hlp='Position Angle');
         if (is_fail(ok)) fail;
         ok := its.fp.setestimateunitwidth (its.frames[fn].f1.pars.pa, 6);
         if (is_fail(ok)) fail;
      }
#
      return T;
   }

###
   const its.showEstimate := function (ref b)
   {
      wider its;
#
      which := its.tab.which(); 
      fn := spaste(which.index);
      t := to_upper(b->text());
#
      if (t=='SHOW') {
         cl := self.getoneestimate(which.index, ascomponentlist=T)
         if (is_fail(cl)) fail;
#
         id := its.vscl.show (cl, color='green');
         if (is_fail(id)) fail;
#
         its.clIDs[fn] := id;

         b->text('Hide');
      } else {
         if (has_field(its.clIDs, fn)) {
            ok := its.vscl.hide(its.clIDs[fn]);
            if (is_fail(ok)) fail;
            its.clIDs[fn] := [=];
         }
         b->text('Show');
      }
#
      return T;
   }

### Public functions


###
   const self.clearestimate := function ()
   {
      wider its;
#
      which := its.tab.which(); 
      fn := spaste(which.index);
      type := its.type[fn];
#
      its.fp.clearestimate (its.frames[fn].f1.pars.flux);
      its.fp.clearestimate (its.frames[fn].f1.pars.pos);
      if (type=='GAUSSIAN' || type=='DISK') {
         its.fp.clearestimate (its.frames[fn].f1.pars.major);
         its.fp.clearestimate (its.frames[fn].f1.pars.minor);
         its.fp.clearestimate (its.frames[fn].f1.pars.pa);
      }

# Remove overlay

      if (has_field(its.clIDs, fn)) {
         ok := its.vscl.hide(its.clIDs[fn]);
      }
#
      return T;
   }


###
   const self.clearfit := function ()
  {
      wider its;
#
      for (i in (1:its.n)) {
         fn := spaste(i);
         type := its.type[fn];
#
         its.fp.clearfit(its.frames[fn].f1.pars.flux);
         its.fp.clearfit(its.frames[fn].f1.pars.pos);
#
         if (type=='GAUSSIAN' || type=='DISK') {
            its.fp.clearfit(its.frames[fn].f1.pars.major);
            its.fp.clearfit(its.frames[fn].f1.pars.minor);
            its.fp.clearfit(its.frames[fn].f1.pars.pa);
         }
      }
#
      return T;
   }


###
   const self.disable := function ()
   {
      wider its;
#
      if (its.enabled) {
         its.f0->disable();
         its.enabled := F;
      }
      return T;
   }


###
   const self.dismiss := function ()
   {
      its.f0->unmap();
      return T;
   }

###
   const self.done := function ()
   {
      wider its, self;
#
      self->done();
#
      ok := its.tab.done();
      ok := its.coordsys.done();
      ok := its.ge.done();
      ok := its.fp.done();
#
      val its := F;
      val self := F;
      return T;
   }

###
   const self.enable := function ()
   {
      wider its;
#
      if (!its.enabled) {
        its.f0->enable();
        its.enabled := T;
      }
      return T;
   }


###
   const self.getestimate := function ()
   {
      cl := emptycomponentlist(log=F);
#
      for (i in 1:its.n) {
        sky := self.getoneestimate(i);
        if (is_fail(sky)) fail;
        ok := cl.add(sky, iknow=T);
        if (is_fail(ok)) fail;
      }
      return cl;
   }


###
   const self.getfixed := function ()
   {
      fixed := "";
      for (i in 1:its.n) {
        fixed[i] := self.getonefixed(i);         
      }
      return fixed;
   }

###
   const self.getmodeltypes := function ()
   {
      types := array('', its.n);
      for (i in 1:its.n) {
         fn := spaste(i);
         types[i] := its.type[fn];
      }
      return types;
   }

###
   const self.getoneestimate := function (which, ascomponentlist=F)
#
# Get estimate values from gui
#
   {
      wider its;
#
      allunset := T;
      cl := emptycomponentlist(log=F);
      cl.simulate(1,F);
#
      fn := spaste(which);
      typeGUI := its.type[fn];
      etxt := spaste('Model ', which, ' does not have a valid estimate');
#
# Position. The user could change the reference type via
# the widget interface, so check it here
#
      dir := its.frames[fn].f1.pars.pos.estimate.get();
      if (is_illegal(dir)) {
         fail etxt;        
      }
      if (!is_unset(dir) && length(dir)>0) {
         dirTypeImage := its.coordsys.referencecode('dir');
         if (is_fail(dirTypeImage)) fail;
         if (dm.getref(dir) != dirTypeImage) {
            txt := spaste('Direction estimate reference type (', dir.refer,
                          ') is not the same as that of image (',
                          dirTypeImage, ')');
            fail txt;
         }
#
         allunset := F;
         values := dm.getvalue(dir);
         ok := cl.setrefdir(which=1, 
                            ra=dq.getvalue(values[1]), raunit=dq.getunit(values[1]),
                            dec=dq.getvalue(values[2]), decunit=dq.getunit(values[2]), 
                            log=F);
         if (is_fail(ok)) fail;
         ok := cl.setrefdirframe(which=1, frame=dirTypeImage, log=F);
         if (is_fail(ok)) fail;
      }
#
      if (typeGUI=='GAUSSIAN' || typeGUI=='DISK') {
#
# Shape
#
         major := its.frames[fn].f1.pars.major.estimate.get();
         if (is_illegal(major)) fail etxt;
         minor := its.frames[fn].f1.pars.minor.estimate.get();
         if (is_illegal(minor)) fail etxt;
         pa := its.frames[fn].f1.pars.pa.estimate.get();
         if (is_illegal(pa)) fail etxt;
         if ( (!is_unset(major)&&length(major)>0)  && 
              (!is_unset(minor)&&length(minor)>0)  && 
              (!is_unset(pa)&&length(pa)>0) ) {
            allunset := F;
            ok := cl.setshape(which=1, type=typeGUI, majoraxis=major, minoraxis=minor,
                              positionangle=pa, log=F);
            if (is_fail(ok)) fail;
         }
#
# Flux.  Convert peak to integral.
#
         flux := [0,0,0,0];
         qf := its.frames[fn].f1.pars.flux.estimate.get();
         if (is_illegal(qf)) fail etxt;
         if (!is_unset(qf) && length(qf)>0) {
            allunset := F;
            flux[its.polarization.index] := dq.getvalue(qf);
            intFlux := theImage.convertflux(value=qf, topeak=F, 
                                            major=major, minor=minor);
            if (is_fail(intFlux)) fail;
#
            flux[its.polarization.index] := dq.getvalue(intFlux);
            ok := cl.setflux(which=1, value=flux, unit=dq.getunit(intFlux),
                             polarization=its.polarization.type, log=F);
            if (is_fail(ok)) fail;
         }
      } else if (typeGUI=='POINT') {
         ok := cl.setshape(which=1, type=typeGUI, log=F);
         if (is_fail(ok)) fail;
#
         flux := [0,0,0,0];
         qf := its.frames[fn].f1.pars.flux.estimate.get();
         if (is_illegal(qf)) fail etxt;
         if (!is_unset(qf) && length(qf)>0) {
            allunset := F;
            beam := theImage.restoringbeam();
            if (length(beam) > 0) {
               intFlux := theImage.convertflux(value=qf, topeak=F, 
                                               major=beam.major, minor=beam.minor);
               if (is_fail(intFlux)) fail;
#
               flux[its.polarization.index] := dq.getvalue(intFlux);
               ok := cl.setflux(which=1, value=flux, unit=dq.getunit(intFlux),
                                polarization=its.polarization.type, log=F);
               if (is_fail(ok)) fail;
            } else {
               return throw ('No restoring beam in image', origin='imagefittergui2.getoneestimate');
            }
         }
      }      
#
# If all entries are unset, tell user to make an estimate.
#
      if (allunset) {
         msg := spaste('Estimate is invalid for component ', which);
         return throw (msg, origin='imagefittergui2.getOneEstimate');
      }
#
      if (ascomponentlist) {
         return cl;
      } else {
         return cl.component(1, iknow=T);
      }
   }


###
   const self.getonefixed := function (which)
   {
      wider its;
      fn := spaste(which);
      type := its.type[fn];
#
      fixed := '';
      if (its.frames[fn].f1.pars.flux.fixed->state()) fixed := spaste(fixed,'f');
      if (its.frames[fn].f1.pars.pos.fixed->state()) fixed := spaste(fixed,'xy');
#
      if (type=='GAUSSIAN' || type=='DISK') {
         if (its.frames[fn].f1.pars.major.fixed->state()) fixed := spaste(fixed,'a');
         if (its.frames[fn].f1.pars.minor.fixed->state()) fixed := spaste(fixed,'b');
         if (its.frames[fn].f1.pars.pa.fixed->state()) fixed := spaste(fixed,'p');
      }
#
      return fixed;
   }

###
   const self.getnumbercomponents := function ()
   {
      wider its;
      return its.n;
   }

###
   const self.getregion := function ()
   {
      r := its.f0.f1.f0.region.get();
      if (is_unset(r)) {
         zidx := theDisplayPanel.animator().currentframe();
         plane := theRegionManager.displayedplane(theImage, its.ddoptions,
                                                  zidx, asworld=T);
         return plane;
      } else {
         return r;
      }
   }

###
   const self.gui := function () 
   {
      wider its;
      its.f0->map();
   }

###
   const self.insertfit := function (cl) 
   {
      wider its;
#
      const n := cl.length();
      for (i in 1:n) {
         fn := spaste(i);
#
         typeGUI := its.type[fn];
         typeCL := to_upper(cl.shapetype(i));
#
# Position
#
         long := cl.getrefdirra(i, unit='time', precision=12);
         if (is_fail(long)) fail;
         lat := cl.getrefdirdec(i, unit='angle', precision=11);
         if (is_fail(lat)) fail;
#
         longErr := dq.tos(cl.getdirerrorlong(i), prec=9);
         if (is_fail(longErr)) fail;
         latErr  := dq.tos(cl.getdirerrorlat(i), prec=9);
         if (is_fail(latErr)) fail;
# 
         its.fp.insertfit(its.frames[fn].f1.pars.pos, [long,lat], [longErr, latErr]);
#      
# Shape
#
         shp := cl.getshape(i);
         shperr := cl.getshapeerror(i);
         if (typeCL=='GAUSSIAN' || typeCL=='DISK') {
            if (typeGUI=='GAUSSIAN' || typeGUI=='DISK') {
               unit := its.frames[fn].f1.pars.major.estimate.get().unit;   
               value := dq.convert(shp.majoraxis, unit).value;  
               if (is_fail(value)) fail;
               error := dq.getvalue(shperr.majoraxis);
               if (error > 0.0) {
                  error := dq.getvalue(dq.convert(shperr.majoraxis, unit));
                  if (is_fail(error)) fail;
               }
               its.fp.insertfit(its.frames[fn].f1.pars.major, value, error);
            }
#
            if (typeGUI=='GAUSSIAN' || typeGUI=='DISK') {
               unit := its.frames[fn].f1.pars.minor.estimate.get().unit;
               value := dq.convert(shp.minoraxis, unit).value;  
               if (is_fail(value)) fail;
               error := dq.getvalue(shperr.minoraxis);
               if (error > 0.0) {
                  error := dq.getvalue(dq.convert(shperr.minoraxis, unit));
                  if (is_fail(error)) fail;
               }
               its.fp.insertfit(its.frames[fn].f1.pars.minor, value, error);
            }
#
            if (typeGUI=='GAUSSIAN' || typeGUI=='DISK') {
               unit := its.frames[fn].f1.pars.pa.estimate.get().unit;
               value := dq.convert(shp.positionangle, unit).value;  
               if (is_fail(value)) fail;
               error := dq.convert(shperr.positionangle, unit).value;  
               if (is_fail(error)) fail;
               its.fp.insertfit(its.frames[fn].f1.pars.pa, value, error);
            }
#
# Flux.  Convert integral to peak for presentation to user.
#
            fluxValue := cl.getfluxvalue(i)[its.polarization.index];
            if (is_fail(fluxValue)) fail;
            fluxUnit := cl.getfluxunit(i);
            if (is_fail(fluxUnit)) fail;
            intFlux := dq.quantity(fluxValue, fluxUnit);
            peakFlux := theImage.convertflux(value=intFlux, topeak=T,
                                             major=shp.majoraxis,
                                             minor=shp.minoraxis);
            if (is_fail(peakFlux)) fail;

# Work out the error in the peak assuming fractional error unchanged

            fluxErrValue := cl.getfluxerror(i)[its.polarization.index];
            if (is_fail(fluxErrValue)) fail;
            errorPeak := fluxErrValue / fluxValue * dq.getvalue(peakFlux);
#
            its.fp.insertfit(its.frames[fn].f1.pars.flux, dq.getvalue(peakFlux), errorPeak);
         } else {

# Deal with flux for pure POINT components.  

            note ('Cannot handle POINT components', origin='imagefittergui2.insertestimate',
                  priority='WARN');
         }
      }
#
      return T;
   }

###
   const self.hideallestimates := function ()
   {
      wider its;
#
      for (i in 1:its.n) {
         fn := spaste(i);
         if (has_field(its.clIDs, fn)) {
            ok := its.vscl.hide(its.clIDs[fn]);
            if (is_fail(ok)) fail;
            its.clIDs[fn] := [=];
         }
         its.showButtons[fn]->text('Show');
      }
#
      return T;
   }

###
   const self.insertmessage := function (text)
   {
      wider its;
      its.f0.f1.msg->clear();
      its.f0.f1.msg->postnoforward(text);
      its.message[2] := its.message[1];
      its.message[1] := text;
      return T;
   }


###
   const self.insertregion := function (region) 
   {
      wider its;
#
      ok := its.f0.f1.f0.region.insert(region);
      if (!is_fail(ok)) {
         its.f0.f1.f0.indicate->state(T);
         timer.execute(its.indicateRegionInserted, 0.5, T);
      }
#
      return ok;
   }

###
   const self.makeframes := function (n, destroy=T)
   {
      wider its;
#
# Destroy old tabs and make new
#
      iStart := 1;
      iEnd := n;
#
      widgetset.tk_hold();
      if (destroy || its.n==0) {
         if (is_agent(its.tab)) its.tab.done();
#
         its.tab := widgetset.tabdialog(its.f0.f0, title='Select Component');
         if (is_fail(its.tab)) {
            widgetset.tk_release();
            fail;
         }
         its.tabframe := its.tab.dialogframe();
         val its.frames := [=];
         its.n := 0;
      }
#
      if (n==its.n) {
         widgetset.tk_release();
         return T;
      } else if (n < its.n) {
         l := its.tab.list();
         for (i in (n+1):(its.n)) {
            its.tab.delete(l[i]);
         }
         its.n := n;
         widgetset.tk_release();
         return T;
      } else if (n > its.n) {
         iStart := its.n + 1;
         iEnd := n;
      }
#
# Make new frames, unmapping them as they are made
# and adding them to the tabber
#
      for (i in iStart:iEnd)  {
         ok := its.makeOneFrame(i);
         if (is_fail(ok)) {
            widgetset.tk_release();
            fail;
         }
      }
#
      widgetset.tk_release();
      its.n := n;
#
      return T;
   }

###
   const self.setddoptions := function (rec)
   {
      wider its;
      its.ddoptions := rec;
      return T;
   }

###
   const self.setpolarization := function (rec)
   {
      wider its;
      its.polarization := rec;
      return T;
   }



### Constructor

#
# Get Coordinate System and find the sky
#
   its.coordsys := theImage.coordsys();
   if (is_fail(its.coordsys)) fail;
#
   ok := its.coordsys.findcoordinate(its.skyaxes.pixel, its.skyaxes.world,
                                     'direction', 1);
   if (is_fail(ok)) fail;
   if (!ok) {
      return throw('This image does not hold the sky', origin='imagefittergui2.g');
   }
#
# Pull out some often used quantities from the CS
#
   its.axisIncr := its.coordsys.increment(format='n')[its.skyaxes.world];
   its.axisUnits := its.coordsys.units()[its.skyaxes.world];
   its.refVal := its.coordsys.referencevalue(format='n')[its.skyaxes.world];
#
# Unit
#
   its.bunit := theImage.brightnessunit(); 
   if ((strlen(its.bunit))==0) its.bunit := 'Jy/pixel';
#
# Sort out restoring beam units.  It is possible someone else
# could redefine the global units whilst we are using
# imagefitter.  This could be dealt with by calling this
# function more often
#
   ok := its.defineSillyBeamStuff();
   if (is_fail(ok)) fail;
#
# Top frame
#
   widgetset.tk_hold();
   its.f0 := widgetset.frame(side='top', title='ImageFitter Fine Control');
   its.f0->unmap();
   widgetset.tk_release();
#
# Frame for TAB
#
   its.f0.f0 := widgetset.frame(its.f0, side='left');
#
# Space
#
   its.f0.f1 := widgetset.frame(its.f0, height=8, relief='flat', expand='x');
#
# Holder for all component things
#
   its.f0.f1 := widgetset.frame(its.f0, side='top', relief='raised', expand='x');
#
# Region
#
   its.f0.f1.f0 := widgetset.frame(its.f0.f1, side='left', relief='flat', expand='x');
   its.f0.f1.f0.label := widgetset.label(its.f0.f1.f0, 'Region');
   txt := spaste('Any region generated from the main image display will \n',
                 'be housed here.  This region will be used when you press \n',
                 'the "FIT" button.  It will also be used when you press \n',
                 'the "AUTO" estimate button.  Thus the use of the region \n',
                 'is context dependent. \n\n',
                 'If you unset the region via the spanner menu, then \n',
                 'the region defaults to the (unzoomed) displayed \n',
                 'region of the image');
   widgetset.popuphelp(its.f0.f1.f0.label, txt, 'House interactively created regions', combi=T, width=100);
#
   its.f0.f1.f0.fill0 := widgetset.frame(its.f0.f1.f0, height=1, expand='x');
   its.f0.f1.f0.region := its.ge.region(its.f0.f1.f0, allowunset=T, editable=T);
   its.f0.f1.f0.indicate := widgetset.button(its.f0.f1.f0, type='check', text='Inserted');
   txt := spaste('When a region is created interactively, this check \n',
                 'button will be checked briefly to indicate that \n',
                 'the region has been captured');
   widgetset.popuphelp(its.f0.f1.f0.indicate, txt, 'Indicate region capture', combi=T);
#
   its.f0.f1.f0.show := widgetset.button(its.f0.f1.f0, text='Show');
   txt := spaste ('Pressing this button when it is labelled "Show" will \n',
                  'display the last region captured in the region entry. \n',
                  'Pressing this button when it is labelled "Hide" will \n',
                  'remove from the display, the current region being displayed');
   widgetset.popuphelp(its.f0.f1.f0.show, txt, 'Show/Hide region', combi=T);
   whenever its.f0.f1.f0.show->press do {
      if (!its.busy.regionshow) {
         its.busy.regionshow := T;
         txt := its.f0.f1.f0.show->text();
         if (txt=='Show') {
            rr := self.getregion();
            if (is_unset(rr)) {
               note ('There is not yet a region to show', priority='WARN', 
                     origin='imagefittergui2.g');
            } else if (is_illegal(rr)) {
               note ('The region is illegal', priority='WARN', 
                     origin='imagefittergui2.g');
            } else {
               txt := spaste('Bounding box = ', as_string(theImage.boundingbox(region=rr)));
               note (txt, priority='NORMAL', origin='imagefittergui2.g');
# 
               id := its.visr.show (theImage, rr, T);
               if (is_fail(id)) {
                  note (ok::message, priority='SEVERE', origin='imagefittergui2.g');
               }
               its.regionIDs := id;
               its.f0.f1.f0.show->text('Hide');
            }
         } else {
            ok := its.visr.hide(its.regionIDs);
            if (is_fail(ok)) {
               note (ok::message, priority='SEVERE', origin='imagefittergui2.g');   
            }
            its.regionIDs := [=];
            its.f0.f1.f0.show->text('Show');
         }
         its.busy.regionshow := F;
      }
   }
#
# Frame for buttons at bottom
#
   its.f0.f1.f1 := widgetset.frame(its.f0.f1, side='left', relief='flat', expand='x');
   its.f0.f1.msg := widgetset.messageline(its.f0.f1.f1, width=40);
   its.f0.f1.f1.fill0  := widgetset.frame(its.f0.f1.f1, height=1, width=1, expand='x');

# Auto-estimate for all components

   its.f0.f1.f1.est := widgetset.button(its.f0.f1.f1, text='Est', type='action');
   txt := spaste('This will make an estimate for all of the components in \n',
                 'the given region simultaneously.  The position information \n',
                 'should be quite good, the shape information less reliable');
   widgetset.popuphelp(its.f0.f1.f1.est, txt, 'Compute estimate', combi=T, width=100);
   whenever its.f0.f1.f1.est->press do {
      self.disable();
      estimate := its.autoEstimate(n=its.n);
      if (is_fail(estimate)) {
         note(estimate::message, priority='SEVERE',
              origin='imagefittergui2.g');
      } else {
         n := estimate.length();
         if (n < its.n) {
            note('Auto-estimate did not recover specified number of components',
                 priority='WARN', origin='imagefittergui2.g');
         }
#
         if (n > 0) {
            for (i in 1:min(n,its.n)) {
               ok := its.insertestimate (estimate=estimate, whichEst=i, whichGUI=i);
               if (is_fail(ok)) {
                  note(ok::message, priority='SEVERE', origin='imagefittergui2.g');
               }
            } 
         }
      }
      self.enable();
   }
#
# Fit
#
   its.f0.f1.f1.fit := widgetset.button(its.f0.f1.f1, text='Fit', type='action');
   txt := spaste('This will fit all the components simultaneously \n',
                 'in the given region');
   widgetset.popuphelp(its.f0.f1.f1.fit, txt, 'Compute fit', combi=T, width=100);
   whenever its.f0.f1.f1.fit->press do {
      rec := [=];
      rec.region := self.getregion();
      rec.estimate := self.getestimate();
      if (is_fail(rec.estimate)) {
         note(rec.estimate::message, priority='SEVERE',
              origin='imagefittergui2.g');
      } else {
         rec.fixed := self.getfixed();
         self->fit(rec);
      }
   }

#
# Detect the emission of the interactive ddd object (interactive estimates)
#
   whenever theDDD->objectready do {

# Get id

      id := $value.id;
      est := theDDD.description(id);
      ok := its.insertestimate(est);
      if (is_fail(ok)) {
         self.enable();
         note(ok::message, priority='SEVERE', 
              origin='imagefittergui2.g');
      }

# Delete from display

      ok := theDDD.remove(id);
      self.enable();
      self.insertmessage('When estimate OK, press "Fit"');
   }

# Done

   its.f0.f1.f1.fill1  := widgetset.frame(its.f0.f1.f1, height=1, width=5, expand='none');
   its.f0.f1.f1.done := widgetset.button(its.f0.f1.f1, text='Done', type='halt');
   widgetset.popuphelp(its.f0.f1.f1.done, 'Destroy this GUI');
   whenever its.f0.f1.f1.done->press do {
      self.done();
   }
#
# Initial message
#
   self.insertmessage('When estimate OK, press "Fit"');
#
# Initial number of components
#
   ok := self.makeframes(n, destroy=F);
   if (is_fail(ok)) fail;
#
# Map base frame in
#
   ok := its.f0->map();
}
