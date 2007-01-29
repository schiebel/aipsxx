# imagemomentsgui.g: custom GUI for image.moments function
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
#   $Id: imagemomentsgui.g,v 19.2 2004/08/25 00:58:15 cvsmgr Exp $
#
#
 
pragma include once

include 'messageline.g'
include 'note.g'
include 'helpmenu.g'
include 'pixelrange.g'
include 'radiobuttons.g'
include 'widgetserver.g'
include 'separableconvolutiongui.g'
include 'image.g'
include 'unset.g'
include 'coordsys.g'

const imagemomentsgui := subsequence (ref parent=F, image, widgetset=dws)
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment variable is not set',
                   origin='imagemomentsgui.g');
   }
   if (!is_image(image)) {
      return throw('The value of the "image" variable is not a valid image object',
                    origin='imagemomentsgui.g');
   }
#
   prvt := [=];
   prvt.ge := widgetset.guientry();     # GUI entry server
   if (is_fail(prvt.ge)) fail;

   prvt.standalone := (is_boolean(parent) && parent==F);
#
   prvt.image := [=];              # The image stuff
   prvt.image.object := [=];       # The actual object
   prvt.image.csys := [=];         # The coordinate system tool
   prvt.medianmoment := [=];       # An alias for the median check box
   prvt.medianIsDisabled := F;     # Is the median coordinate moment enabled ?
   prvt.needPlotter := [=];        # MUST we have a plotter
   prvt.stats := [=];              # Stick image statistics in here
#
# Track whether widgets are enabled or disabled.  If the parent
# widget is disabled (e.g. basic) then its children are considered
# disabled (e.g. region).  These are all T until context renders
# them otherwise.  Most things  are never disabled.
#
   prvt.state := [=];
# 
   prvt.state.basic := [=];
   prvt.state.basic.rollup := T;
#
   prvt.state.convolution := [=];
   prvt.state.convolution.rollup := [=];
   prvt.state.convolution.rollup.current := T;
   prvt.state.convolution.rollup.last := T;
   prvt.state.convolution.smooth := T;
# 
   prvt.state.data := [=];
   prvt.state.data.rollup := T; 
   prvt.state.data.which := T;
   prvt.state.data.range := T;
   prvt.state.data.snrsig := T;
#
   prvt.state.plotting.rollup := T;
#   prvt.state.plotting.plotter := [=];
#   prvt.state.plotting.plotter.name := T;   
#   prvt.state.plotting.plotter.yind := T;   
#
   prvt.possibleMoments := "";
   prvt.possibleMoments[1] := 'mean intensity';
   prvt.possibleMoments[2] := 'integrated intensity';
   prvt.possibleMoments[3] := 'weighted coordinate';
   prvt.possibleMoments[4] := 'weighted coordinate dispersion';
   prvt.possibleMoments[5] := 'median intensity';
   prvt.possibleMoments[6] := 'median coordinate';
   prvt.possibleMoments[7] := 'standard deviation about mean';
   prvt.possibleMoments[8] := 'root mean square';
   prvt.possibleMoments[9] := 'absolute mean deviation';
   prvt.possibleMoments[10] := 'maximum';
   prvt.possibleMoments[11] := 'coordinate of maximum';
   prvt.possibleMoments[12] := 'minimum ';
   prvt.possibleMoments[13] := 'coordinate of minimum';
#
   prvt.method := '';
   prvt.possibleKernels := "gaussian boxcar hanning";


###
   prvt.disableMedian := function (state)
   {
      wider prvt;     
      if (state) {
         if (!prvt.medianIsDisabled) {
            prvt.medianmoment->disabled(F);
            prvt.medianmoment->state(F);
            prvt.medianmoment->disabled(T);
            prvt.medianIsDisabled := T;
         }
      } else {
         if (prvt.medianIsDisabled) {
            prvt.medianmoment->disabled(F);
            prvt.medianIsDisabled := F;
         }
      }
      return T;
   }


###
   prvt.enableRollups := function(parent, basic, convolution, 
                                  data, plotting)
#
# Enables/Disables rollups as requested.
#
   {
      if (basic) {
         parent.f0.f0.r0.enable();
         parent.state.basic.rollup := T;
      } else {
         parent.f0.f0.r0.up();
         parent.f0.f0.r0.disable();
         parent.state.basic.rollup := F;
      }
#
      parent.state.convolution.rollup.last := 
          parent.state.convolution.rollup.current;
      if (convolution) {
         parent.f0.f0.r1.enable();
         parent.state.convolution.rollup.current := T;
      } else {
         parent.f0.f0.r1.up();
         parent.f0.f0.r1.disable();
         parent.state.convolution.rollup.current := F;
      }
#
      if (data) {
         parent.f0.f0.r2.enable();
         parent.state.data.rollup := T;
      } else {
         parent.f0.f0.r2.up();
         parent.f0.f0.r2.disable();
         parent.state.data.rollup := F;
      }
#
      if (plotting) {
         parent.f0.f0.r3.enable();
         parent.state.plotting.rollup := T;
      } else {
         parent.f0.f0.r3.up();
         parent.f0.f0.r3.disable();
         parent.state.plotting.rollup := F;
      }
#
      return T;
   }

###
   prvt.enableConvolution := function (ref parent, state)
   {
      if (state) {
         parent.f0.f0.f1.f0.smooth.disabled(F);
         parent.state.convolution.smooth := T;
      } else {
         parent.f0.f0.f1.f0.smooth.disabled(T);
         parent.state.convolution.smooth := F;
      }
      return T;
   }


###
   prvt.enableData := function (ref parent, inex, all, snrsigma)
#
# inex==T means enable include/exclude/all widget
# all=T means all is selected as well
#
   {
      range := F;
      if (inex) range := T;
      if (!inex) all := F;
      if (all) range := F;
#
      prvt.f0.f0.f2.range.disabled(which=!inex, sliders=!range);
      parent.state.data.which := F;
      if (inex) parent.state.data.which := T;
      parent.state.data.range := F;
      if (range) parent.state.data.range := T;
#
      if (snrsigma) {
         parent.f0.f0.f2.f2.snr.disable(F);
         parent.f0.f0.f2.f3.sigma.disable(F);
#
         parent.state.data.snrsig := T;
      } else {
         parent.f0.f0.f2.f2.snr.disable(T);
         parent.f0.f0.f2.f3.sigma.disable(T);
#
         parent.state.data.snrsig := F;
      }
      return T;
   }


###
   const prvt.defaultMomentAxis := function (prvt)
   {
      local pa, wa;
      ok := prvt.image.csys.findcoordinate (pa, wa, 'spectral', 1);
      if (is_fail(ok)) fail;
      defaultAxis := 1;
      if (ok) defaultAxis := pa[1];
      return defaultAxis;
   }


###
   prvt.createMomentsWidget := function (ref medianmoment, label, labWidth, ref left, ref right, 
                                         textLeft, textRight, idx, checkLeft=F, checkRight=F, 
                                         ref widgetset)
#
# left and right are packing top
#
   {
     wider prvt;
#
# Left column
#
     field := textLeft;
     left[field] := widgetset.frame(left, side='left');
     left[field]['label'] := widgetset.label(left[field], label, width=labWidth);
     if (strlen(label)>0) {
        widgetset.popuphelp(left[field]['label'], 'Select the desired moment(s) to create');
     }
     left[field]['b'] := widgetset.button(left[field], text=textLeft,
                                          type='check', height=1);
     if (checkLeft) left[field]['b']->state(T);
     if (textLeft=='median coordinate') val medianmoment := ref left[field]['b'];
#
# Right column
#
     field := textRight;
     right[field] := widgetset.frame(right, side='left');
     if (textRight!='empty') {
        right[field]['b'] := widgetset.button(right[field], text=textRight,
                                              type='check', height=1);
        if (checkRight) right[field]['b']->state(T);
     } else {
        bgcol := dws.resources('frame').background;
        right[field]['b'] := widgetset.button(right[field], text='',
                                              text='', type='plain', height=1,
                                              relief='flat', background=bgcol);
        right[field]['b']->disabled(T);
     }
     right[field]['label'] := widgetset.label(right[field], label, 
                                              width=0,
                                              foreground=widgetset.resources('label').background);
     if (textRight=='median coordinate') val medianmoment := ref right[field]['b'];
     return T;
 }
   
###
   const prvt.createAxes := function (ref prvt)
   {
      defaultAxis := prvt.defaultMomentAxis(prvt);
      widgetset.tk_hold();
      if (has_field(prvt.f0.f0.f0.f1, 'axis')) prvt.f0.f0.f0.f1.axis.done();
#
      p2w := prvt.image.csys.axesmap(toworld=T);
      prvt.f0.f0.f0.f1.axis := radiobuttons(parent=prvt.f0.f0.f0.f1,
                                          names=prvt.image.csys.names()[p2w],
                                          default=defaultAxis,
                                          side='left',
                                          widgetset=widgetset);
      whenever prvt.f0.f0.f0.f1.axis->value do {
         prvt.updateVelocityTypeState();
      }
#
      widgetset.tk_release();
      return T;
   }

   const prvt.createConvolution := function (ref prvt)
   {
      if (has_field(prvt.f0.f0.f1.f0, 'smooth')) prvt.f0.f0.f1.f0.smooth.done();
      prvt.f0.f0.f1.f0.smooth := separableconvolutiongui(parent=prvt.f0.f0.f1.f0,
                                                  names=prvt.image.csys.names(),
                                                  axes=[1:length(prvt.image.csys.names())],
                                                  widgetset=widgetset);
#
# This code is in the constructor, but this function may
# be called by setimage as well
#
      prvt.state.convolution.smooth := T;
#
      return T;
   }


###
   const prvt.enableBasic := function (ref prvt)
   {
      prvt.enableRollups(prvt, basic=T, convolution=T, data=T, 
                         plotting=T);
#
      prvt.f0.f0.f0.f2.method->text('Basic');
      prvt.method := '';
#
      prvt.enableConvolution(prvt, T);
      prvt.enableData (prvt, inex=T, all=T, snrsigma=F);
#
# We are not allowed to have "all" pixel selection if we are smoothing in
# basic mode (the idea of smoothing is to select pixels to make a mask)
# So turn it off for this method if any smoothing is checked on
#
      if (prvt.f0.f0.f1.f0.smooth.nonechecked()) {
         prvt.f0.f0.f2.range.enableallbutton();
      } else {
         prvt.f0.f0.f2.range.disableallbutton();
      }
#
# The only mode in which the median is allowed is basic and no smoothing
#
      prvt.disableMedian(F);
#
      prvt.needPlotter := F;
#
      return T;
   }


###
   const prvt.enableWindowAutoBosma := function (ref prvt)
   {
      prvt.enableRollups(prvt, basic=T, convolution=T, data=T,
                         plotting=T);
#
      prvt.f0.f0.f0.f2.method->text('Window/automatic/converging mean');
      prvt.method := 'window';
#
      prvt.enableConvolution(prvt, T);
      prvt.enableData (prvt, inex=F, all=F, snrsigma=T);
#
      prvt.disableMedian(T);
      prvt.needPlotter := F;
#
      return T;
   }

###
   const prvt.enableWindowAutoFit := function (ref prvt)
   {      
      prvt.enableRollups(prvt, basic=T, convolution=T, data=T,
                         plotting=T);
#
      prvt.f0.f0.f0.f2.method->text('Window/automatic/fit');   
      prvt.method := 'window,fit';
#
      prvt.enableConvolution(prvt, T);
      prvt.enableData (prvt, inex=F, all=F, snrsigma=T);
#
      prvt.disableMedian(T);
      prvt.needPlotter := F;
#
      return T;
   }

###
   const prvt.enableWindowInterDirect := function (ref prvt)
   {      
      prvt.enableRollups(prvt, basic=T, convolution=T, data=F,
                         plotting=T);
#
      prvt.f0.f0.f0.f2.method->text('Window/interactive/direct');
      prvt.method := 'window,interactive';
#
      prvt.enableConvolution(prvt, T);
      prvt.enableData (prvt, inex=F, all=F, snrsigma=F);
#
      prvt.disableMedian(T);
      prvt.needPlotter := T;
#
      return T;
   }

###
   const prvt.enableWindowInterFit := function (ref prvt)
   {      
      prvt.enableRollups(prvt, basic=T, convolution=T, data=F,
                         plotting=T);
#
      prvt.f0.f0.f0.f2.method->text('Window/interactive/fit');
      prvt.method := 'window,interactive,fit';
#
      prvt.enableConvolution(prvt, T);
      prvt.enableData (prvt, inex=F, all=F, snrsigma=F);
#
      prvt.disableMedian(T);
      prvt.needPlotter := T;
#
      return T;
   }

###
   const prvt.enableFitAuto := function (ref prvt)
   {      
      prvt.enableRollups(prvt, basic=T, convolution=F, data=T,
                         plotting=T);
#
      prvt.f0.f0.f0.f2.method->text('Fit/automatic');
      prvt.method := 'fit';
#
      prvt.enableConvolution(prvt, F);
      prvt.enableData (prvt, inex=F, all=F, snrsigma=T);
#
      prvt.disableMedian(T);
      prvt.needPlotter := F;
#
      return T;
   }

###
   const prvt.enableFitInter := function (ref prvt)
   {
      prvt.enableRollups(prvt, basic=T, convolution=F, data=F,
                         plotting=T);
#
      prvt.f0.f0.f0.f2.method->text('Fit/interactive');
      prvt.method := 'fit,interactive';
#
      prvt.enableConvolution(prvt, F);
      prvt.enableData (prvt, inex=F, all=F, snrsigma=T);
#
      prvt.disableMedian(T);
      prvt.needPlotter := T;
#
      return T;
   }


###
   const prvt.isMomentAxisSpectral := function () 
   {
      axis := prvt.f0.f0.f0.f1.axis.getvalue().index;
      types := prvt.image.csys.axiscoordinatetypes(world=F);
      tmp := to_upper(types[axis]);
      if (tmp=='SPECTRAL') {
         return T;
      } else {
         return F;
      }
   }

###
   const prvt.updateVelocityTypeState := function ()
   {
      wider prvt;
      if (prvt.isMomentAxisSpectral()) {
         prvt.f0.f0.f0.f1a.velocity.disabled(F);
      } else {
         prvt.f0.f0.f0.f1a.velocity.disabled(T);
      }
      return T;
   }


### Constructor

   prvt.image.object := image;
   prvt.image.csys := prvt.image.object.coordsys();    # Tool
   if (is_fail(prvt.image.csys)) fail;
#
   tk_hold();
   title := spaste('imagemoments (', prvt.image.object.name(strippath=F), ')');
   prvt.f0 := widgetset.frame(parent, expand='both', side='top', 
                              relief='raised', title=title);
   prvt.f0->unmap();
   tk_release();
   whenever prvt.f0->resize do {
      self->resize();
   }
#
   if(prvt.standalone) {
     prvt.f0.menubar := widgetset.frame(prvt.f0, side='left', relief='raised',
					expand='x');
     prvt.f0.menubar.file  := widgetset.button(prvt.f0.menubar, type='menu', 
					       text='File', relief='flat');
     prvt.f0.menubar.file.dismiss := widgetset.button(prvt.f0.menubar.file,  
						   text='Dismiss Window', type='dismiss');
     prvt.f0.menubar.file.done := widgetset.button(prvt.f0.menubar.file, 
						   text='Done', type='dismiss');
     helptxt := spaste('- dismiss window, preserving state\n',
                       '- destroy window, destroying state');
     widgetset.popuphelp(prvt.f0.menubar.file, helptxt, 'Menu of File operations', combi=T);
#
     whenever prvt.f0.menubar.file.done->press do {
       self->exit();
       self.done();
     }
     whenever prvt.f0.menubar.file.dismiss->press do {
       prvt.f0->unmap();
     }
#
     prvt.f0.menubar.spacer := widgetset.frame(prvt.f0.menubar, expand='x', 
					       height=1);
#
     prvt.f0.menubar.help := widgetset.helpmenu(parent=prvt.f0.menubar, 
                              menuitems="Image ImageMoments ImageMomentsGUI Regionmanager",
                              refmanitems=['Refman:images.image', 'Refman:images.image.moments',
                                           'Refman:images.image.momentsgui', 'Refman:images.regionmanager'],
                              helpitems=['about Images', 'about imagemoments', 'about imagemoments GUI',
                                         'about the Regionmanager']);
   }
#
# Put all the rollups in here
#
   prvt.f0.f0 := widgetset.frame(prvt.f0, side='top', expand='x', relief='raised');
#
##############################################################################
# Basic settings rollup
##############################################################################
#
   prvt.f0.f0.r0 := widgetset.rollup(prvt.f0.f0, title='Basic Settings');
   prvt.f0.f0.r0.up();
   prvt.f0.f0.f0 := prvt.f0.f0.r0.frame();
   labWidth := 14;
#
# Region
#
   prvt.f0.f0.f0.f0 := widgetset.frame(prvt.f0.f0.f0, side='left');
   prvt.f0.f0.f0.f0.label := widgetset.label(prvt.f0.f0.f0.f0, 'Region',
                                             width=labWidth);
   widgetset.popuphelp(prvt.f0.f0.f0.f0.label, 'Enter region of interest');
   prvt.f0.f0.f0.f0.region := prvt.ge.region(parent=prvt.f0.f0.f0.f0,
                                             allowunset=T);
#
# Moments axis
#
   prvt.f0.f0.f0.f1 := widgetset.frame(prvt.f0.f0.f0, side='left');
   prvt.f0.f0.f0.f1.label := widgetset.label(prvt.f0.f0.f0.f1, 'Moment axis',
                                             width=labWidth);
   widgetset.popuphelp(prvt.f0.f0.f0.f1.label, 'Select the moment axis');
   prvt.createAxes(prvt);
#
# Doppler type (only relevant if moment axis is a spectral axis)
#
   doppler := dm.doppler('optical');
   list := dm.listcodes(doppler).normal;
   prvt.f0.f0.f0.f1a := widgetset.frame(prvt.f0.f0.f0, side='left');
   prvt.f0.f0.f0.f1a.label := widgetset.label(prvt.f0.f0.f0.f1a, 'Doppler type',
                                              width=labWidth);
   prvt.f0.f0.f0.f1a.velocity := widgetset.optionmenu (prvt.f0.f0.f0.f1a,
                                                       labels=list);
   if (!prvt.isMomentAxisSpectral()) {
      prvt.f0.f0.f0.f1a.velocity.disabled(T);
   }
# 
# Methods
#
   rsrc := dws.resources('optionmenu');
   prvt.f0.f0.f0.f2 := widgetset.frame(prvt.f0.f0.f0, side='left');
   prvt.f0.f0.f0.f2.label := widgetset.label(prvt.f0.f0.f0.f2, 'Method', 
                                             width=labWidth);
   widgetset.popuphelp(prvt.f0.f0.f0.f2.label, 'Select the desired method');
   prvt.f0.f0.f0.f2.method := widgetset.button(prvt.f0.f0.f0.f2,
                                               type='menu', text='Basic',
                                               foreground=rsrc.foreground,
                                               background=rsrc.background,
                                               relief=rsrc.relief,
                                               font=rsrc.font);
#
   prvt.f0.f0.f0.f2.method.basic := widgetset.button(prvt.f0.f0.f0.f2.method,
                                                     'Basic');
#
   whenever prvt.f0.f0.f0.f2.method.basic->press do {
      prvt.enableBasic(prvt);
   }
   prvt.f0.f0.f0.f2.method.window := widgetset.button(prvt.f0.f0.f0.f2.method,
                                                      'Window', type='menu');
   prvt.f0.f0.f0.f2.method.window.auto := widgetset.button(prvt.f0.f0.f0.f2.method.window,
                                                           'Auto', type='menu');
   prvt.f0.f0.f0.f2.method.window.auto.bosma := widgetset.button(prvt.f0.f0.f0.f2.method.window.auto,
                                                                 'Converging mean');
   whenever prvt.f0.f0.f0.f2.method.window.auto.bosma->press do {
      prvt.enableWindowAutoBosma(prvt);
   }
   prvt.f0.f0.f0.f2.method.window.auto.fit := widgetset.button(prvt.f0.f0.f0.f2.method.window.auto,
                                                               'Fit Gaussian');
   whenever prvt.f0.f0.f0.f2.method.window.auto.fit->press do {
      prvt.enableWindowAutoFit(prvt);
   }
   prvt.f0.f0.f0.f2.method.window.inter := widgetset.button(prvt.f0.f0.f0.f2.method.window,
                                                           'Interactive', type='menu');
   prvt.f0.f0.f0.f2.method.window.inter.direct := widgetset.button(prvt.f0.f0.f0.f2.method.window.inter,
                                                                 'Direct');
   whenever prvt.f0.f0.f0.f2.method.window.inter.direct->press do {
      prvt.enableWindowInterDirect(prvt);
   }
   prvt.f0.f0.f0.f2.method.window.inter.fit := widgetset.button(prvt.f0.f0.f0.f2.method.window.inter,
                                                               'Fit Gaussian');
   whenever prvt.f0.f0.f0.f2.method.window.inter.fit->press do {
      prvt.enableWindowInterFit(prvt)
   }
   prvt.f0.f0.f0.f2.method.fit := widgetset.button(prvt.f0.f0.f0.f2.method,
                                                      'Fit Gaussian', type='menu');
   prvt.f0.f0.f0.f2.method.fit.auto := widgetset.button(prvt.f0.f0.f0.f2.method.fit,
                                                        'Auto');
   whenever prvt.f0.f0.f0.f2.method.fit.auto->press do {
      prvt.enableFitAuto(prvt);
   }
   prvt.f0.f0.f0.f2.method.fit.inter := widgetset.button(prvt.f0.f0.f0.f2.method.fit,
                                                         'Interactive');
   whenever prvt.f0.f0.f0.f2.method.fit.inter->press do {
      prvt.enableFitInter(prvt);
   }
#
# Moments
#
   prvt.f0.f0.f0.f3 := widgetset.frame(prvt.f0.f0.f0, side='left');
   prvt.f0.f0.f0.f3.left := widgetset.frame(prvt.f0.f0.f0.f3, side='top');
   prvt.f0.f0.f0.f3.right := widgetset.frame(prvt.f0.f0.f0.f3, side='top');
#
   j := 1;
   checkRight := F;
   for (i in 1:7) {
      checkLeft := F;
      if (i==1) {
         label := 'Basic\nMoments';
         checkLeft := T;
      } else if (i==3) {
         label := 'Advanced\nMoments';
      } else {
         label := '';
      }
#
      mLeft := prvt.possibleMoments[j];
      if (i==4) {
         mRight := 'empty';
         j +:= 1;
      } else {
         mRight := prvt.possibleMoments[j+1];
         j +:= 2;
      }
      prvt.createMomentsWidget(prvt.medianmoment, label, labWidth, prvt.f0.f0.f0.f3.left, 
                             prvt.f0.f0.f0.f3.right, mLeft, mRight, i, 
                             checkLeft, checkRight, widgetset);
   }
#
# We can't have convolution with the median coordinate moment. If we turn 
# the median back on, we have to put the convolution rollup back the way it was
#
   whenever prvt.medianmoment->press do {
      if (prvt.medianmoment->state()) {
         prvt.f0.f0.r1.up();
         prvt.f0.f0.r1.disable();
#
         prvt.state.convolution.rollup.last := 
            prvt.state.convolution.rollup.current;
         prvt.state.convolution.rollup.current := F;
      } else {
         if (prvt.state.convolution.rollup.last) {
            prvt.f0.f0.r1.enable();
         }
         temp_smooth := prvt.state.convolution.rollup.current;
         prvt.state.convolution.rollup.current := 
             prvt.state.convolution.rollup.last;
         prvt.state.convolution.rollup.last := temp_smooth;
      }
   }
#
   prvt.f0.f0.f0.f4 := widgetset.frame(prvt.f0.f0.f0, side='left');
   prvt.f0.f0.f0.f4.label := widgetset.label(prvt.f0.f0.f0.f4, text='',
                                             width=labWidth);
   prvt.f0.f0.f0.f4.selectall := widgetset.button(prvt.f0.f0.f0.f4, 
                                                  text='select all');
   prvt.f0.f0.f0.f4.selectnone := widgetset.button(prvt.f0.f0.f0.f4, 
                                                   text='select none');
   whenever prvt.f0.f0.f0.f4.selectall->press do {
      prvt.selectOneStateForAllMoments(T);
   }
   whenever prvt.f0.f0.f0.f4.selectnone->press do {
      prvt.selectOneStateForAllMoments(F);
   }
#
   prvt.f0.f0.f0.f5 := widgetset.frame(prvt.f0.f0.f0, side='left');
   prvt.f0.f0.f0.f5.label := widgetset.label(prvt.f0.f0.f0.f5, 
                                             'Output name', width=labWidth);
   prvt.f0.f0.f0.f5.outfile := prvt.ge.file (prvt.f0.f0.f0.f5, value=unset, default='', 
                                             allowunset=T, editable=T, types='Image');
   hlp := spaste('This is either the full name for one moment\n',
                 'or a root name for multiple moments.  In the \n',
                 'latter case, the full name will be made for you');

   widgetset.popuphelp(prvt.f0.f0.f0.f5.label, hlp, 'Enter the output moment image name', combi=T);
#
# Convolution rollup
#
   prvt.f0.f0.r1 := widgetset.rollup(prvt.f0.f0, title='Convolution');
   prvt.f0.f0.r1.up();
   prvt.f0.f0.f1 := prvt.f0.f0.r1.frame();
#
   prvt.f0.f0.f1.f0 := widgetset.frame(prvt.f0.f0.f1, side='left');
   prvt.createConvolution(prvt);
#
#
# We are not allowed to have "all" pixel selection if we are smoothing in 
# basic mode (the idea of smoothing is to select pixels to make a mask)
# So turn it off for this method.  
#
   whenever prvt.f0.f0.f1.f0.smooth->check do {
      method := prvt.f0.f0.f0.f2.method->text();
      if ($value==T) {
         if (method=='Basic') {
            prvt.f0.f0.f2.range.setradiovalue('all', F);
            prvt.f0.f0.f2.range.disableallbutton();
#
# Defaults to include if neither include nor exclude is selected
#
            rad := prvt.f0.f0.f2.range.getradiovalue();
            if (!has_field(rad, 'index')) {
              prvt.f0.f0.f2.range.setradiovalue(1, T);
            }
         } else {
            prvt.f0.f0.f2.range.enableallbutton();
         }
      } else {
         if (prvt.f0.f0.f1.f0.smooth.nonechecked()) {
            prvt.f0.f0.f2.range.enableallbutton();
#
# Defaults to include if none of include, exclude, all is selected
#
            rad := prvt.f0.f0.f2.range.getradiovalue();
            if (!has_field(rad, 'index')) {
              prvt.f0.f0.f2.range.setradiovalue(1, T);
            }
         }
      }      
   }
#
# Data selection rollup
#
   prvt.stats := [=];
   prvt.stats.min := 0;
   prvt.stats.max := 0;
   prvt.image.object.statistics(statsout=prvt.stats,async=F,list=F,force=T);
   if (length(prvt.stats.npts)==0) {
      return throw('The image appears to be fully masked bad - there are no valid data points',
                         origin='imagemomentsgui');
   }
#
   prvt.f0.f0.r2 := widgetset.rollup(prvt.f0.f0, title='Data Selection');
   prvt.f0.f0.r2.up();
   prvt.f0.f0.f2 := prvt.f0.f0.r2.frame();
#
   prvt.f0.f0.f2.range := pixelrange(parent=prvt.f0.f0.f2, 
                                     min=prvt.stats.min, max=prvt.stats.max,
                                     widgetset=widgetset);
#
   prvt.f0.f0.f2.f2 := widgetset.frame(prvt.f0.f0.f2, side='left');
   prvt.f0.f0.f2.f2.label := widgetset.label(prvt.f0.f0.f2.f2,
                                             'Peak SNR');
   hlp := spaste('Spectra which are pure noise are rejected without\n',
                 'moment computation.  The current algorithm finds\n',
                 'the peak SNR in the spectrum and compares it with a cutoff.\n',
                 'This is not a brilliant algorithm...');
   widgetset.popuphelp(prvt.f0.f0.f2.f2.label, hlp, 
             'Enter spectrum noise determination peak SNR', combi=T);
   prvt.f0.f0.f2.f2.snr := prvt.ge.scalar(prvt.f0.f0.f2.f2,
                                          value=3.0, default=3.0,
                                          allowunset=T, editable=T);
#
   prvt.f0.f0.f2.f3 := widgetset.frame(prvt.f0.f0.f2, side='left');
   prvt.f0.f0.f2.f3.label := widgetset.label(prvt.f0.f0.f2.f3,
                                             'Std dev.');
   hlp := spaste('If this is required and you do not give it, it\n',
                 'will be worked out for you by fitting to a histogram\n',
                 'of the pixel values.  If you specify a plotting device\n',
                 'this is an interactive process');
   widgetset.popuphelp(prvt.f0.f0.f2.f3.label, hlp,
             'Enter the standard deviation of the noise in the image', combi=T, width=70);
 
   prvt.f0.f0.f2.f3.sigma := prvt.ge.scalar(prvt.f0.f0.f2.f3,
                                            value=unset, default=0.0,
                                            allowunset=T, editable=T);
# 
# Plotting rollup
#
   prvt.f0.f0.r3 := widgetset.rollup(prvt.f0.f0, title='Plotting');
   prvt.f0.f0.r3.up();
   prvt.f0.f0.f3 := prvt.f0.f0.r3.frame();
#
   prvt.f0.f0.f3.f0 := widgetset.frame(prvt.f0.f0.f3, side='left');
   prvt.f0.f0.f3.f0.label := widgetset.label(prvt.f0.f0.f3.f0, 'Plotter');
   hlp := spaste('This should be a standard PGPlot device string such as\n',
                 '1/xs.   You cannot give a Glish pgplotter or pgplotwidget\n',
                 'in here yet.  If you are using an automatic mode, and give\n',
                 'a plotter, then each spectrum will be displayed as it\n',
                 'is analyzed.  The display will include fits etc');
   widgetset.popuphelp(prvt.f0.f0.f3.f0.label, hlp, 'Enter plotting device', combi=T);
   prvt.f0.f0.f3.f0.plotter := prvt.ge.string(prvt.f0.f0.f3.f0,
                                              value=unset, default='',
                                              allowunset=T, editable=T);
#
   prvt.f0.f0.f3.f1 := widgetset.frame(prvt.f0.f0.f3, side='left');
   hlp := ['Number of subplots per page in x direction',
           'Number of subplots per page in y direction'];
   prvt.f0.f0.f3.f1.nframe := widgetset.frame(parent=prvt.f0.f0.f3.f1,
					      side='top');
   if (is_fail(prvt.f0.f0.f3.f1.nframe)) fail;
   prvt.f0.f0.f3.f1.nx := 
       widgetset.multiscale(prvt.f0.f0.f3.f1.nframe, values=[1],
			    start=1, end=10, constrain=F, resolution=1,
			    entry=T, extend=T, names=['nx'],
			    helps=hlp[1]);
   if (is_fail(prvt.f0.f0.f3.f1.nx)) fail;
   prvt.f0.f0.f3.f1.ny := 
       widgetset.multiscale(prvt.f0.f0.f3.f1.nframe, values=[1],
			    start=1, end=10, constrain=F, resolution=1,
			    entry=T, extend=T, names=['ny'],
			    helps=hlp[2]);
   if (is_fail(prvt.f0.f0.f3.f1.ny)) fail;
#
   prvt.f0.f0.f3.f2 := widgetset.frame(prvt.f0.f0.f3, side='left');
   prvt.f0.f0.f3.f2.yind := widgetset.button(parent=prvt.f0.f0.f3.f2,
                                             type='check', 
                                             text='Scale y axes independently');
   hlp := spaste('You can plot all spectra with the same intensity \n',
                 'range, or scale each one separately');
   widgetset.popuphelp(prvt.f0.f0.f3.f2.yind, hlp, 'Auto scale each spectrum ?', combi=T);
#
# Go, reset and dismiss 
#
   if (prvt.standalone) {
      prvt.f0.f1 := widgetset.frame(prvt.f0, side='left', expand='x', 
                                    relief='raised');
      prvt.f0.f1.go := widgetset.button(prvt.f0.f1, text='Go',  
                                        type='action');
      prvt.f0.f1.space := widgetset.frame(prvt.f0.f1, width=1, height=1, expand='x')
      prvt.f0.f1.reset := widgetset.button(prvt.f0.f1, text='Reset', 
                                           type='action')
      widgetset.popuphelp(prvt.f0.f1.reset, 'Reset GUI');
      whenever prvt.f0.f1.reset->press do {
	self.reset();
      }
      prvt.f0.f1.dismiss := widgetset.button(prvt.f0.f1, text='Dismiss', 
					     type='dismiss');
      widgetset.popuphelp(prvt.f0.f1.dismiss, 'Dismiss window (preserving state)');
      whenever prvt.f0.f1.dismiss->press do {
	ok := prvt.f0->unmap();
      }
      whenever prvt.f0.f1.go->press do {
	self.go();
      }
  }
#
# Set the state of widget enable/disable to start with.
# We default to the basic method
#
   prvt.enableBasic(prvt)
   ok := prvt.f0->map();
#

###
   const self.done := function ()
   {
      wider prvt, self;
#
# Basic settings widgets
#
      prvt.f0.f0.f0.f0.region.done();
      prvt.f0.f0.f0.f1.axis.done();
      prvt.f0.f0.f0.f1a.velocity.done();
      prvt.f0.f0.f0.f5.outfile.done();
      prvt.f0.f0.r0.done();
#
# Smoothing widgets
#
      prvt.f0.f0.f1.f0.smooth.done();
      prvt.f0.f0.r1.done();
#
# Data selection widgets
#
      prvt.f0.f0.f2.range.done();
      prvt.f0.f0.f2.f2.snr.done();
      prvt.f0.f0.f2.f3.sigma.done();
      prvt.f0.f0.r2.done();
#
# Plotting rollup
#
      prvt.f0.f0.f3.f0.plotter.done();
      prvt.f0.f0.f3.f1.nx.done();
      prvt.f0.f0.f3.f1.ny.done();
      prvt.f0.f0.r3.done();
#
      prvt.ge.done();
#
# Coordinate system
#
      prvt.image.csys.done();
#
      val prvt := F;
      val self := F;
      return T;
   }

###
   const self.gui := function ()
   {
      prvt.f0->map();
      return T;
   }


###
   const self.setimage := function (image)
   {
      wider prvt;
      if (!is_image(image)) fail;
#
# Set image object.  It's not the job of this
# subsequence to done the image object
#
      prvt.image.object := image;
      if (is_coordsys(prvt.image.csys)) {
         ok := prvt.image.csys.done();
         if (is_fail(ok)) fail;
      }
      prvt.image.csys := prvt.image.object.coordsys();
      if (is_fail(prvt.image.csys)) fail;
#
# Set title
#
      title := spaste('imagemoments (', prvt.image.object.name(strippath=F), ')');
      prvt.f0->title(title);
#
# Moment axis
#
      prvt.createAxes(prvt)
#
# Convolution
#
      prvt.createConvolution(prvt)
#
# Data selection range
#
      prvt.stats := [=];
      prvt.stats.min := 0;
      prvt.stats.max := 0;
      prvt.image.object.statistics(statsout=prvt.stats,async=F,list=F,force=T);
      prvt.f0.f0.f2.range.setrange(prvt.stats.min, prvt.stats.max);
#
      return T;
   }



###
   const self.getstate := function (check=T)
#
# Get the state of the GUI.  Optionally check values
# for validity.  Only smoothing and data selection
# rollups are potentially disabled at this point
#
   {
      rec := [=];
#
# Which moments.  
#
      rec.moments := [];
      j := 1;
      k := -1;
      for (f in prvt.possibleMoments) {
         state := F;
         if (has_field(prvt.f0.f0.f0.f3.left, f)) {
            state := prvt.f0.f0.f0.f3.left[f]['b']->state();
         } else if (has_field(prvt.f0.f0.f0.f3.right, f)) {
            state := prvt.f0.f0.f0.f3.right[f]['b']->state();
         }
#    
         if (state) {
            rec.moments[j] := k;
            j +:= 1;
         }
         k +:= 1;
      }
#
# Moment axis
#
      rec.axis := prvt.f0.f0.f0.f1.axis.getvalue().index;
#
# Velocity type
#
      rec.doppler := prvt.f0.f0.f0.f1a.velocity.getlabel();
#
# Region
#
      tmp := prvt.f0.f0.f0.f0.region.get();
      if (check) {
         if (is_fail(tmp)) {
            note ('The region is illegal', priority='WARN', 
                  origin='imagemomentsgui.g');
            return F;
         }
      }
      rec.region := tmp;
#
# Method
#
      rec.method := prvt.method;
#
# Outfile
#
      tmp := prvt.f0.f0.f0.f5.outfile.get();
      if (check) {
         if (is_fail(tmp)) {
            note ('The output file name is illegal', priority='WARN', 
                  origin='imagemomentsgui.g');
            return F;
         } else {
           rec.outfile := tmp;
         }
      } else {
         rec.outfile := tmp;
      }
#
# Smoothing
#
      rec.smoothaxes := unset;
      rec.smoothtypes := unset;
      rec.smoothwidths := unset;
      rec.smoothout := '';
#
# Check state as smoothing may be disabled.
#
      if (prvt.state.convolution.rollup.current) {
#
# Get the state of the separable convolution  GUI and reinterpret it 
# into the form that moments wants.  The convolution GUI gives us all the 
# values for  all axes whether they are turned on or not.  Here we
# only pick out the ones that are turned on.  
#
         smooth := prvt.f0.f0.f1.f0.smooth.getstate(check);
         if (check && is_boolean(smooth) && smooth==F) return F;
#
         j := 1;
         fieldNames := field_names(smooth.kernels);
         for (i in fieldNames) {
            if (smooth['kernels'][i]['check']==T) {
               rec.smoothaxes[j] := as_integer(i);
               rec.smoothtypes[j] := smooth['kernels'][i]['type'];
               rec.smoothwidths[j] := smooth['kernels'][i]['width'];
               j +:= 1;
            }
         }
         rec.smoothout := smooth.outfile;
      }
#
# Data selection.  Check state as it may be disabled.
#
      rec.includepix := [];
      rec.excludepix := [];
      if (prvt.state.data.rollup) {
#
	  range := prvt.f0.f0.f2.range.getslidervalues();
#
# If include/exclude/all are all off, the record 
# will be empty.  
#
         inex := prvt.f0.f0.f2.range.getradiovalue();
         if (has_field(inex, 'name')) {
            if (inex.name=='include') {
              rec.includepix := range;
            } else if (inex.name=='exclude') {
               rec.excludepix := range;
            } else if (inex.name=='all') {
              ;
            }
         } else {    
            if (check) {
               note('You must make an "include/exclude/all" selection', priority='WARN',
                     origin='imagemomentsgui.g');
               return F;
            }
         }
      }
#
      rec.peaksnr := unset;
      rec.stddev := unset;
      if (prvt.state.data.snrsig) {
         tmp := prvt.f0.f0.f2.f2.snr.get();
         if (check) {
            if (is_fail(tmp)) {
               note('The peak SNR value is illegal', priority='WARN',
                     origin='imagemomentsgui.g');
               return F;
            } else if(tmp<=0) {
               note('The peak SNR value must be positive', priority='WARN',
                     origin='imagemomentsgui.g');
               return F;
            }
         }
         rec.peaksnr := tmp;
#
         tmp := prvt.f0.f0.f2.f3.sigma.get();
         if (check) {
            if (is_fail(tmp)) {
               note('The standard deviation of the noise value is illegal', priority='WARN',
                     origin='imagemomentsgui.g');
               return F;
            } else if (tmp<0) {
               note('The standard deviation of the noise must be non-negative', 
                     priority='WARN', origin='imagemomentsgui.g');
               return F;
            }
         }
         rec.stddev  := tmp;
      }
#
# Plotting
#
      tmp := prvt.f0.f0.f3.f0.plotter.get();
      if (check & prvt.needPlotter) {
         if (is_fail(tmp)) {
            note('The plotter is illegal', priority='WARN',
                  origin='imagemomentsgui.g');
         } else if (is_unset(tmp) || strlen(tmp)==0) {
            note('You must give a plotter', priority='WARN',
                  origin='imagemomentsgui.g');
            return F;
         }
      }
      rec.plotter := tmp;
#
# The idiot user could extend the ranges to include
# negative nx/ny.  So make a test.
#      
      rec.nx := prvt.f0.f0.f3.f1.nx.getvalues();
      rec.ny := prvt.f0.f0.f3.f1.ny.getvalues();
      if (check) {
         if (rec.nx <=0) {
            note('The number of plots in the x direction must be positive', priority='WARN',
                 origin='imagemomentsgui.g');
            return F;
         }
         if (rec.ny <=0) {
           note('The number of plots in the y direction must be positive', priority='WARN',
                 origin='imagemomentsgui.g');
            return F;
         }
      }
#
      rec.yind := prvt.f0.f0.f3.f2.yind->state();
#
      rec.async := F;
#
      return rec;
   }




###
   const self.reset := function ()
   {
      wider prvt;
#
# Enable everything that might have been disabled
#
      prvt.enableRollups(prvt, basic=T, convolution=T, data=T, 
                         plotting=T);
      prvt.enableConvolution(prvt, state=T);
      prvt.enableData(prvt, inex=T, all=F, snrsigma=T)
      prvt.medianmoment->disabled(F);
#
# Insert an unset region
#
      prvt.f0.f0.f0.f0.region.insert(unset);
#
# Set spectral axis
#
      defaultAxis := prvt.defaultMomentAxis(prvt);
      prvt.f0.f0.f0.f1.axis.setstate(defaultAxis, T);
#
# Select first velocity type
#
      prvt.f0.f0.f0.f1a.velocity.selectindex(1);
      if (prvt.isMomentAxisSpectral()) {
         prvt.f0.f0.f0.f1a.velocity.disabled(F);
      }
#
# Turn on first moment
#
      prvt.selectOneStateForAllMoments(F);
      prvt.f0.f0.f0.f3.left[prvt.possibleMoments[1]]['b']->state(T);
#
# Clear output moment name
#
      prvt.f0.f0.f0.f5.outfile.insert(unset);
#
# Reset smoothing widget and output entries
#
      prvt.f0.f0.f1.f0.smooth.reset();
#
# Reset data selection
#
      prvt.f0.f0.f2.range.setrange(prvt.stats.min, prvt.stats.max);
      prvt.f0.f0.f2.range.setradiovalue('all', T);
#
# SNR/sigma
#
      prvt.f0.f0.f2.f2.snr.insert(3.0);
      prvt.f0.f0.f2.f3.sigma.insert(unset);
# 
# Plotting 
#
      prvt.f0.f0.f3.f0.plotter.insert(unset);
      prvt.f0.f0.f3.f1.nx.setvalues(1);
      prvt.f0.f0.f3.f1.ny.setvalues(1);
      prvt.f0.f0.f3.f2.yind->state(F);
#
# Set basic method
#
      prvt.enableBasic(prvt);
#
      return T;   
   }


###
   const self.setstate := function (rec)
#
# get/setstate is ok.  the GUI will be in the correct
# enable state for all the elements in the record to be
# activated.  but if someone gives us a clipboard
# record, bits of it may not be enabled for insertion...
#
# Catching all the context sensitive stuff is a mess.
# There is duplication of the constructor code effectively.
#
   {
      wider prvt;
#
# Put GUI back into start up condition (basic settings)
# Everything is enabled with this.
#
      self.reset();
#
# Region.  We can only know its value
#
      if (has_field(rec, 'region')) {
         prvt.f0.f0.f0.f0.region.insert(rec.region);
      }
#
# Doppler type
#
      if (has_field(rec, 'doppler')) {
         prvt.f0.f0.f0.f1a.velocity.selectlabel(rec.doppler);
      }
#
# Method.  These enable functions also set the value
# of the method button to the appropriate string
# and set prvt.method.  Should separate this.
#
      if (has_field(rec, 'method')) {
         method := rec.method;
         if (strlen(method)==0) {
            prvt.enableBasic(prvt);
         } else if (method~m/win/) {
            if (method~m/int/) {
               if (method~m/fit/) {
                  prvt.enableWindowInterFit(prvt);
               } else {
                  prvt.enableWindowInterDirect(prvt);
               }
            } else {
               if (method~m/fit/) {
                  prvt.enableWindowAutoFit(prvt);
               } else {
                  prvt.enableWindowAutoBosma(prvt);
               }
            }
         } else if (method~m/fit/) {
            if (method~m/int/) {
               prvt.enableFitInter(prvt);
            } else {
               prvt.enableFitAuto(prvt);
            }
         } else {
            return throw('Error parsing "method" field of record',
                         origin='imagemomentsgui.setstate');
         }
      }
#
# Moment axis
#
      if (has_field(rec, 'axis')) {
         prvt.f0.f0.f0.f1.axis.setstate(rec.axis, T);
      }
#
# Moments
#
      doMedianCoordinate := F;
      if (has_field(rec, 'moments')) {
         for (i in 1:length(rec.moments)) {
            idx := rec.moments[i] + 2;
            f := prvt.possibleMoments[idx];
            if (f=='median coordinate') doMedianCoordinate := T;
            if (has_field(prvt.f0.f0.f0.f3.left, f)) {
               prvt.f0.f0.f0.f3.left[f]['b']->state(T);
            } else if (has_field(prvt.f0.f0.f0.f3.right, f)) {
               prvt.f0.f0.f0.f3.right[f]['b']->state(T);
            }
         }
      }
#
# Output moments name.  
#
      if (has_field(rec, 'outfile')) {
         prvt.f0.f0.f0.f5.outfile.insert(rec.outfile);
      }
#
# Convolution.  We have to make the record in the form that the 
# separable convolution GUI widget wants
#
      doConvolution := F;      
      if (has_field(rec, 'smoothaxes') &
          has_field(rec, 'smoothtypes') &
          has_field(rec, 'smoothwidths')) {
         n1 := length(rec.smoothaxes);
         n2 := length(rec.smoothtypes);
         n3 := length(rec.smoothwidths);
#
         if (n1==n2 & n1==n3 & n1>0) {      
            doConvolution := T;
            rec2 := [=];  
            rec2.kernels := [=];
            rec2.outfile := '';
#
            for (i in 1:n1) {  
               fN := as_string(rec.smoothaxes[i]);
               rec2.kernels[fN] := [=];
               rec2.kernels[fN]['check'] := T;
               rec2.kernels[fN]['type'] := rec.smoothtypes[i];
               rec2.kernels[fN]['width'] := rec.smoothwidths[i];
            }
         }
         rec2['outfile'] := rec.smoothout;
         prvt.f0.f0.f1.f0.smooth.setstate(rec2);
      }
#
# Deal with median coordinate.  Do it here after all convolution stuff 
# is set up.  We can't have convolution with median coordinate moment.
#
      if (doMedianCoordinate) {
         prvt.f0.f0.r1.up();
         prvt.f0.f0.r1.disable();
         prvt.state.convolution.rollup.last := 
            prvt.state.convolution.rollup.current;
         prvt.state.convolution.rollup.current := F;
      }
#
# Data selection
#
      if (has_field(rec, 'includepix')) {
         r := rec.includepix;
         if (length(r)==2) {
            prvt.f0.f0.f2.range.setradiovalue('include', T)
            prvt.f0.f0.f2.range.setrange(r[1], r[2]);
         }
      } else if (has_field(rec, 'excludepix')) {
         r := rec.excludepix;
         if (length(r)==2) {
            prvt.f0.f0.f2.range.setradiovalue('exclude', T)
            prvt.f0.f0.f2.range.setrange(r[1], r[2]);
         }
      } else if (has_field(rec, 'all')) {
         prvt.f0.f0.f2.range.setradiovalue('all', T)
      }
#
# If any of the convolution is turned on, we cannot have
# 'all' pixel selection.  We dont make the extra checks
# that we have the right method (get/setstate is symmetrical)
#
      if (doConvolution) {
         prvt.f0.f0.f2.range.setradiovalue('all', T)
         prvt.f0.f0.f2.range.disableallbutton();
      }
#
# If 'all' is on, we disable the include/exclude sliders
#
      v := prvt.f0.f0.f2.range.getradiovalue();
      if (v.name=='all') {
        prvt.f0.f0.f2.range.disabled(sliders=T);
      }
#
      if (has_field(rec, 'peaksnr')) {
         prvt.f0.f0.f2.f2.snr.insert(rec.peaksnr);
         if (!prvt.state.data.snrsig) {
            prvt.f0.f0.f2.f2.snr.disable(T);
         }
      }
#
      if (has_field(rec, 'stddev')) {
        prvt.f0.f0.f2.f3.sigma.insert(rec.stddev);
         if (!prvt.state.data.snrsig) {
            prvt.f0.f0.f2.f3.sigma.disable(T);
         }
      }
#
# Plotting
#
      if (has_field(rec, 'plotter')) {
         prvt.f0.f0.f3.f0.plotter.insert(rec.plotter);
      }
#
      if (has_field(rec, 'nx') & has_field(rec, 'ny')) {
	  prvt.f0.f0.f3.f1.nx.setvalues(rec.nx);
	  prvt.f0.f0.f3.f1.ny.setvalues(rec.ny);
      }
#
      if (has_field(rec, 'yind')) {
         prvt.f0.f0.f3.f2.yind->state(T);
      }
#
      if (has_field(rec, 'async')) {
      }
#
      return T;
   }


###
   const self.go := function (rec=[=], async=F)
   {
#
# Get the parameters and see if they are good.
#
      if (length(rec)==0) rec := self.getstate(T);
      if (is_boolean(rec) && rec==F) return F;
      if (async) async.rec := T;
#
# Do it after final check for a stupid record
#
      if (has_field(rec, 'moments') &&
          has_field(rec, 'axis') &&
          has_field(rec, 'region') &&
          has_field(rec, 'method') &&
          has_field(rec, 'smoothaxes') &&
          has_field(rec, 'smoothtypes') &&
          has_field(rec, 'smoothwidths') &&
          has_field(rec, 'includepix') &&
          has_field(rec, 'excludepix') &&
          has_field(rec, 'peaksnr') &&
          has_field(rec, 'doppler') &&
          has_field(rec, 'stddev') && 
          has_field(rec, 'outfile') &&
          has_field(rec, 'smoothout') && 
          has_field(rec, 'plotter') &&
          has_field(rec, 'nx') &&
          has_field(rec, 'ny') &&
          has_field(rec, 'yind') &&
          has_field(rec, 'async')) {
         if (!rec.async) prvt.f0->disable();
         ok := prvt.image.object.moments(moments=rec.moments,
                                axis=rec.axis, region=rec.region,
                                method=rec.method,
                                smoothaxes=rec.smoothaxes,
                                smoothtypes=rec.smoothtypes,
                                smoothwidths=rec.smoothwidths,
                                includepix=rec.includepix,
                                excludepix=rec.excludepix,
                                peaksnr=rec.peaksnr, stddev=rec.stddev,
                                doppler=rec.doppler,
                                outfile=rec.outfile,
                                smoothout=rec.smoothout,
                                plotter=rec.plotter,
                                nx=rec.nx, ny=rec.ny,
                                yind=rec.yind,
                                async=rec.async);
         if (!rec.async) prvt.f0->enable();
         if (is_fail(ok)) {
            note (spaste('Failed to run function because ', ok::message),
                  origin='imagemomentsgui.go', priority='SEVERE');
            return F;
         }
      } else {
         note ('The supplied record is invalid',
               priority='WARN', origin='imagemomentsgui.go');
         return F;
      }
#
      return T;
   }


###
   const prvt.selectOneStateForAllMoments := function (state)
   {
      wider prvt;
      for (f in prvt.possibleMoments) {
         if (has_field(prvt.f0.f0.f0.f3.left, f)) {
            if (f=='median coordinate' && prvt.medianIsDisabled) {
               prvt.f0.f0.f0.f3.left[f]['b']->state(F);
            } else {
               prvt.f0.f0.f0.f3.left[f]['b']->state(state);
            }
         } else if (has_field(prvt.f0.f0.f0.f3.right, f)) {
            if (f=='median coordinate' && prvt.medianIsDisabled) {
               prvt.f0.f0.f0.f3.right[f]['b']->state(F);
            } else {
               prvt.f0.f0.f0.f3.right[f]['b']->state(state);
            }
         }
      }
      return T;
   }
}

