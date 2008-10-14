# imagefittergui.g: GUI for imagefitter which fits images with models
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
#   $Id: imagefittergui.g,v 19.2 2004/08/25 00:57:32 cvsmgr Exp $
#
#   Events emitted
#--------------------
#   Name            Value                Meaning
#
#   acceptfit                            User has accepted the fit
#                   T or F
#                   -
#   fitlistDelete   Index                User has deleted an item from the fit list
#   exit                                 User user has pushed the exit button
#                   -
#   dismissed       -                    Primary GUI has been dismissed
#   fit                                  User user wants to do a fit. 
#               rec.region               The region to fit
#               rec.estimate             The estimate (componentlist) of the fit 
#               rec.fixed[n]             For each component a string indicating
#                                        which parameter is fixed (fxyabp)
#   restored                    the user has restored regions into the private
#                               restoreregions.g widget
#                  -
#   savePressed                 the user wishes to save the regions (known only
#                               to imagefitter) to a table
#                  -
#   subtract                    user pressed subtract (T) or add (F) fit button 
#                  T or F
 
pragma include once

include 'componentlist.g'
include 'editfitlist.g';
include 'note.g'
include 'pixelrange.g'
include 'pgplotwidget.g'
include 'unset.g'
include 'viewer.g'
include 'widgetserver.g'

const imagefittergui := subsequence (ref parent=F, expandResiduals=F, image, 
                                     ref regionmanager, dmin,  dmax,
                                     maxpix, widgetset=ddwls)  
{
   if (!have_gui()) {
      return throw('No Gui is available, possibly the  DISPLAY environment variable is not set',
                   origin='imagefittergui.g');
   }
   if (!serverexists('dv', 'viewer', dv)) {
      return throw('The viewer server "dv" is not running',
                    origin='imagefittergui.g');
   }
   if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is not running',
                    origin='imagefittergui.g');
   }
#
   its := [=];
#                       
   its.isDecisionEnabled := T;        # State of decision buttons
#
   its.image := image;                 # The calling image object
   its.rm := ref regionmanager;        # The regionmanager to use
   its.skyaxes := [=];                 # Which axes hold the sky
   its.pol := [=];                     # Description of current Stokes (see fn. getcurrentpol)
#
   its.restore := [=];                 # GUI for restoring regions
   its.save := [=];                    # GUI for saving regions
   its.cl := [=];                      # GUI for saving componentlist
#
   its.display := [=];                   # For main image display
   its.display.viewer := viewer('imagefitter_display', widgetset=widgetset,
                                 deleteatexit=F);           # viewer server
   if (is_fail(its.display.viewer)) fail;
   its.display.dp := [=];                # display panel
   its.display.dd := [=];                # display data 
   its.display.ddd := [=];               # drawing display data 
   its.display.animator := [=];          # Display panel animator
#
   its.resid := [=];                   # For residual image display
   its.resid.viewer := viewer('imagefitter_resid', widgetset=widgetset,
                               deleteatexit=F);            # viewer server
   if (is_fail(its.resid.viewer)) fail;
   its.resid.dp := [=];                # display panel
   its.resid.dd := [=];                # display data 
   its.resid.colormap := [=];          # Viewer colormap manager  
   its.resid.adjust := [=];            # Display panel adjustment  
   its.resid.canvas := [=];            # Display panel canvas manager    
#
   its.efl := [=];                     # Fit list management and display
#
   its.message := "";                  # Messageline messages (simple and complex mode)
#
   its.gui2 := [=];                    # Fine control GUI
   its.mode := 'simple';               # 'complex' when gui2 is activated
   its.maxpix := maxpix;
#
   its.busy := [=];                    # Are we already busy dealing with events
   its.busy.getregions := F;   


# Private functions
###
   const its.displayraster := function (parent, bb, pixels, mask, dMin=unset, dMax=unset,
                                         csize=1.5, xlabel='x', ylabel='y', planeIndex=-1)
   {
      blc := bb.blc;
      trv := [blc[1]-1.0, 1, 0, blc[2]-1.0, 0, 1];
      pShape := pixels::shape;
      if (is_unset(dMin)) dMin := min(pixels);
      if (is_unset(dMax)) dMax := max(pixels);
#    
      x1 := blc[1] - 1.0 + 0.5;
      x2 := x1 + pShape[1];
      y1 := blc[2] - 1.0 + 0.5;
      y2 := y1 + pShape[2];
#
      parent.clear();
      parent.sch(csize);      
      parent.svp(0.0, 1.0, 0.0, 1.0);
      parent.env(x1, x2, y1, y2, 1, 0);
      parent.eras();
      parent.swin(x1, x2, y1, y2);
      parent.wnad(x1, x2, y1, y2);
      parent.imag(pixels, dMin, dMax, trv);
      parent.box('BCNST', 0.0, 0, 'BCNST', 0.0, 0);
#
      title := '';
      if (planeIndex > 0) title := spaste('plane = ', planeIndex);
      parent.lab(xlabel, ylabel, title);
#
      return T;
   }

###
   const its.restore_regions := function (ref mainPanel, ref parent, table)
   {
      mainPanel->disable();
      if (length(parent.restore)>0) {
         parent.restore.gui();
         parent.restore.refresh(); 
      } else {
         parent.restore := widgetset.restoreregions(table=table, changenames=T,
                                                    globalrestore=F);
      }
      whenever parent.restore->restored do {
          mainPanel->enable();
          self->restored();
      }
      whenever parent.restore->dismissed do { 
          mainPanel->enable();
      }
   }


###
   const its.save_regions := function (ref mainPanel, ref parent, table)
   {
      mainPanel->disable();
      if (length(parent.save)>0) {
         parent.save.gui();
      } else {
         parent.save:= widgetset.saveregions(table=table, changenames=T,
                                             globalsave=F);
      }
      whenever parent.save->saved,parent.save->dismissed do { 
          mainPanel->enable();
      }
   }


### Constructor

   widgetset.tk_hold();
#
# Find the sky
#
   its.skyaxes.pixel := [];
   its.skyaxes.world := [];
   cs := its.image.coordsys();
   if (is_fail(cs)) fail;
   ok := cs.findcoordinate(its.skyaxes.pixel, its.skyaxes.world,
                          'direction', 1);
   if (is_fail(ok)) fail;
   if (!ok) {
      return throw ('This image does not hold the sky', origin='imagefittergui.g');
   }
   if (is_fail(cs.done())) fail;
#
# See if we need a private color map or not by making 
# a dummy displaypanel with the default viewer
#
   newcmap := F;
   its.f0 := dv.newdisplaypanel(show=F, newcmap=unset);
   if (!is_fail(its.f0)) {
       newcmap := its.f0.newcmap();
       its.f0.done();
   } else {
       widgetset.tk_release();
       return throw('Unable to make any viewer displaypanels');
   }
#
   its.f0 := widgetset.frame(parent, expand='both', side='top',
                             relief='raised', title='imagefitter',
                             newcmap=newcmap);
   its.f0->unmap();
   widgetset.tk_release();
#
   its.f0.menubar := widgetset.frame(its.f0, side='left', 
                                      relief='raised', expand='x');
   its.f0.menubar.file := widgetset.button(its.f0.menubar, type='menu', 
                                            text='File', relief='flat');
   its.f0.menubar.file.save := widgetset.button(its.f0.menubar.file, 
                                                 text='Save accepted regions to table');
   its.f0.menubar.file.restore := widgetset.button(its.f0.menubar.file, 
                                                 text='Restore regions from a table and fit');
#
   t := widgetset.resources('button', 'dismiss');
   its.f0.menubar.file.dismiss := widgetset.button(its.f0.menubar.file, 
                                                 text='Dismiss window', background=t.background,
                                                 foreground=t.foreground);
   t := widgetset.resources('button', 'halt');
   its.f0.menubar.file.exit := widgetset.button(its.f0.menubar.file, 
                                                 text='Done', background=t.background,
                                                 foreground=t.foreground);
   helptxt := spaste('Menu of file selections\n',
                     '- save accepted regions to a table \n',
                     '- restore and fit regions from a table \n',
                     '- dismiss the imagefitter GUI (recover with function gui) \n',
                     '- destroy and exit the imagefitter');
   widgetset.popuphelp(its.f0.menubar.file, helptxt, 'File menu', combi=T);
#
   whenever its.f0.menubar.file.dismiss->press do {
      ok := its.f0->unmap();
      if (is_agent(its.gui2)) its.gui2.dismiss();
      self->dismissed();
   }
   whenever its.f0.menubar.file.exit->press do {
      self->exit();
   }
   whenever its.f0.menubar.file.save->press do {
      its.save_regions(its.f0, its, its.image);
      self->savePressed();
   }
   whenever its.f0.menubar.file.restore->press do {
      its.restore_regions(its.f0, its, its.image);
   }
#
   its.f0.menubar.spacer := widgetset.frame(its.f0.menubar, expand='x', 
                                             height=1);
#
   its.f0.menubar.help := widgetset.helpmenu(parent=its.f0.menubar, 
                              menuitems="Imagefitter Image RegionManager",
                              refmanitems=['Refman:imagefitter', 'Refman:images','Refman:regionmanager'],
                              helpitems=['about the imagefitter','about images', 'about image regions']);
#
   its.f0.f0 := widgetset.frame(its.f0, expand='both', side='left', relief='raised')
   its.f0.f0.f0 := widgetset.frame(its.f0.f0, expand='y', side='top', relief='raised');
#
   its.left0 := widgetset.frame(its.f0.f0.f0, expand='both', side='top');
#
# Label
#
   its.left0.label := widgetset.label(its.left0, 'Fit Residual Displays');

################################################################################
#
# Histogram
#
#################################################################################

   its.left0.f1 := widgetset.frame(its.left0, expand='none', side='left');
#
   its.left0.f1.f0 := widgetset.frame(its.left0.f1, side='top', expand='both');
   its.left0.f1.f0.plotter := pgplotwidget(its.left0.f1.f0, size=[185,185], 
                                           padx=1.0, pady=2.0,
                                           maxcolors=2, havemessages=F,
                                           widgetset=widgetset); 
   histo := ref its.left0.f1.f0.plotter;

################################################################################
#
# Statistics
#
################################################################################

   its.left0.f2 := widgetset.frame(its.left0, expand='none', side='top');
#
   its.left0.f2.f0 := widgetset.frame(its.left0.f2, expand='none', side='left');
   its.left0.f2.f0.l0 := widgetset.label(its.left0.f2.f0, 'Mean', width=4);
   its.left0.f2.f0.mean := widgetset.listbox(its.left0.f2.f0, height=1, width=10);
   its.left0.f2.f0.l1 := widgetset.label(its.left0.f2.f0, 'Sig', width=4);
   its.left0.f2.f0.sigma := widgetset.listbox(its.left0.f2.f0, height=1, width=10);
   its.left0.f2.f0.f0 := widgetset.frame(its.left0.f2.f0, expand='x', height=1, width=1);
#
   its.left0.f2.f1 := widgetset.frame(its.left0.f2, expand='none', side='left');
   its.left0.f2.f1.l0 := widgetset.label(its.left0.f2.f1, 'Min', width=4);
   its.left0.f2.f1.min := widgetset.listbox(its.left0.f2.f1, height=1, width=10);
   its.left0.f2.f1.l1 := widgetset.label(its.left0.f2.f1, 'Max', width=4);
   its.left0.f2.f1.max := widgetset.listbox(its.left0.f2.f1, height=1, width=10);
   its.left0.f2.f1.f0 := widgetset.frame(its.left0.f2.f1, expand='x', height=1, width=1);
#
   statsMean := ref its.left0.f2.f0.mean;
   statsSigma := ref its.left0.f2.f0.sigma;
   statsMin := ref its.left0.f2.f1.min;
   statsMax := ref its.left0.f2.f1.max;

################################################################################
#
# Residual image display
#
################################################################################

   expand := 'none';
   if (expandResiduals) expand := 'both';
   its.left0.f3 := widgetset.frame(its.left0, expand=expand, 
                         height=180, width=180, side='top', relief='flat');
#
# Make display panel 
#
   its.resid.dp := its.resid.viewer.newdisplaypanel(parent=its.left0.f3, 
                                                    width=185, height=185, 
                                                    hasgui=T,
                                                    guihasmenubar=[tools=T,help=T],
                                                    guihasbuttons=[adjust=T,print=T],
                                                    guihasanimator=F, guihascontrolbox=F,
                                                    maxcolors=30);
   if (is_fail(its.resid.dp)) fail;
#
# Make action buttons
#
   its.left0.f3.f0 := widgetset.frame(its.left0.f3, expand='none', side='left');
   its.left0.f3.f0.accept := widgetset.button(its.left0.f3.f0, 'Accept');
#
   widgetset.popuphelp(its.left0.f3.f0.accept, 'Click to accept fit');
#
   acceptButton := ref its.left0.f3.f0.accept;
#
   whenever acceptButton->press do {
      self->acceptfit(T);
   }
#
# Second row
#
   its.left0.f3.f0.modify := widgetset.button(its.left0.f3.f0, 'Subtract', width=7);
   hlpTxt := spaste('If you created the fitter with modify=T, the \n',
                    'input image itself is modified. If modify=F, \n',
                    'then the image is copied and the copy is modified \n',
                    'and used for the fitting. By default this copy is \n',
                    'discarded when the application is terminated with \n',
                    'the done function or with the exit button in the \n',
                    'file menu.  However you can save it if you use the \n',
                    'residual argument in the constructor');
   widgetset.popuphelp(its.left0.f3.f0.modify, hlpTxt, 'Modify display with last fit', combi=T);
#
   modifyButton := ref its.left0.f3.f0.modify;
#
   whenever modifyButton->press do {
     t := modifyButton->text();
      if (t=='Subtract') {
         self->modify(T);
         modifyButton->text('Add');
      } else {
         self->modify(F);
         modifyButton->text('Subtract');
      }
   }
#
############################################################################
# Main image display
#
   its.f0.f0.f1 := widgetset.frame(its.f0.f0, expand='both', side='top', 
                                    relief='raised');
#
# Make display panel 
#
   its.f0.f0.f1.f0 := widgetset.frame(its.f0.f0.f1, expand='both', side='left'); 
   its.display.dp := its.display.viewer.newdisplaypanel(its.f0.f0.f1.f0, hasgui=T,
                                                        width=270, height=270,
                                                        guihasmenubar=[tools=T, help=T],
                                                        guihascontrolbox=T,
                                                        guihasanimator=T, 
                                                        guihasbuttons=[adjust=T,unzoom=T,print=T],
                                                        hasdismiss=F, hasdone=F, 
                                                        guihastracking=T);
   if (is_fail(its.display.dp)) fail;
#
# Get hold of animator so we can examine its events.  If the
# image is stepped, re-determine the Stokes and tell GUI2
#
   its.display.animator := its.display.dp.animator();
   whenever its.display.animator->state do {
      its.pol := self.getcurrentpol();
      if (its.mode=='complex') {
        its.gui2.setpolarization(its.pol);
#
        its.gui2.insertregion(unset);
        its.gui2.clearestimate();
        its.gui2.clearfit();
      }
   }
#
# Get hold of annotation DDD
#
   its.display.ddd := its.display.dp.annotationdd();
   if (is_fail(its.display.ddd)) fail;
#
   whenever its.display.dp->region do {
      if (its.busy.getregions==T) {
         note ('You cannot emit another region until the previous one is dealt with', 
                priority='WARN', origin='imagefittergui.g');
      } else {
         its.busy.getregions := T;
         region := $value.region;
#
# If in complex mode, the region is secured for emission when FIT is pressed
#
         if (its.mode=='complex') {
            ok := its.gui2.insertregion(region);
            its.busy.getregions := F;   
         } else {         
#
# In simple mode, generation of a region starts the fitting process.
# The estimate is an empty componentlist as image::fitsky will
# work out the estimate.  All parameters are fitted for.
#
            rec := [=];
            rec.estimate := emptycomponentlist(log=F);
            rec.fixed := "";                       
            rec.region := region; 

# Clear of any componentlist overlays

            its.efl.hideall();
#
            self->fit(rec);
#
# imagefitter must tell us when we can be not-busy again.
# I.e. after the fit has finished (might take a while)
#
         }
      }
   }
#
# Fit list parameters display
#
   its.efl := editfitlist (parent=its.f0.f0.f1, ddd=its.display.ddd, 
                           allowdeletefirst=F, widgetset=widgetset);
   if (is_fail(its.efl)) fail;
   whenever its.efl->delete do {
      self->fitlistDelete($value);
   }
#
##############################################################################
#
# Rollup for pixel selection.  
#
   its.f0.f2 := widgetset.frame(its.f0, side='top', expand='x', relief='flat');
   its.f0.f2.r0 := widgetset.rollup(its.f0.f2, title='Pixel Selection', show=F);
   its.f0.f2.f0 := its.f0.f2.r0.frame();
   its.f0.f2.f0.f0 := widgetset.frame(its.f0.f2.f0, side='left', expand='x');
#
   its.f0.f2.f0.f0.range := pixelrange(parent=its.f0.f2.f0.f0,
                                        min=dmin, max=dmax, 
                                        labels="include exclude auto",
                                        widgetset=widgetset);
   its.f0.f2.f0.f0.fill := widgetset.frame(its.f0.f2.f0.f0, height=1, expand='x');
   pixelRange := ref its.f0.f2.f0.f0.range;
#
   its.f0.f2.f0.f1 := widgetset.frame(its.f0.f2.f0, side='left', expand='x');
   ge := widgetset.guientry();
   its.f0.f2.f0.f1.label := widgetset.label(its.f0.f2.f0.f1, 'Max pixels');
   widgetset.popuphelp(its.f0.f2.f0.f1.label, 'Maximum number of pixels to fit without query');
   its.f0.f2.f0.f1.maxpix := ge.scalar (parent=its.f0.f2.f0.f1,
                                     value=its.maxpix, default=its.maxpix,
                                     allowunset=F, editable=T);
   whenever its.f0.f2.f0.f1.maxpix->value do {
      ok := self.setmaxpixels ($value);
      if (!ok) {
         its.f0.f2.f0.f1.maxpix.insert(its.maxpix);
      }
   }

##############################################################################
#
# Rollup for fitting fine control.  
#
   its.f0.f3 := widgetset.frame(its.f0, side='top', expand='x', relief='flat');
   its.f0.f3.r0 := widgetset.rollup(its.f0.f3, title='Fine Control', show=F);
   its.f0.f3.f0 := its.f0.f3.r0.frame();
   its.f0.f3.f0.f0 := widgetset.frame(its.f0.f3.f0, side='left', expand='x',
                                       relief='flat');
#
# Number of components
#
   its.f0.f3.f0.f0.scale := widgetset.multiscale(parent=its.f0.f3.f0.f0, 
                                                  start=1, end=4, values=[1.0],
                                                  names=['No. components'],
                                                  helps=['No. simultaneous to fit'],
                                                  entry=T, extend=T, resolution=1,
                                                  length=5);
   numberComponents := ref its.f0.f3.f0.f0.scale;
#
# Push this button to activate secondary control GUI
#
   its.f0.f3.f0.f0.fill0 := widgetset.frame(its.f0.f3.f0.f0, height=1, width=10,
                                             expand='none');
   its.f0.f3.f0.f0.activate:= widgetset.button(its.f0.f3.f0.f0, 'Go',
                                                type='action');
   hlpTxt := spaste('This will activate a secondary GUI giving you much \n',
                    'more control over the fitting process');
   widgetset.popuphelp(its.f0.f3.f0.f0.activate, hlpTxt, 'Activate fine control GUI', combi=F);
   its.f0.f3.f0.f0.fill := widgetset.frame(its.f0.f3.f0.f0, height=1, expand='x');
   whenever its.f0.f3.f0.f0.activate->press do {
      ncomp := numberComponents.getvalues()[1];
      if (is_agent(its.gui2)) {
         if (ncomp != its.gui2.getnumbercomponents()) {
            self.disenabledecisionbuttons();
            self.disablepixelrange();
            self.disablefinecontrol();

# Make new frames as needed in GUI

            ok := its.gui2.makeframes(ncomp, destroy=F);
            if (is_fail(ok)) {
               note (ok::message, origin='imagefittergui.g',
                     priority='SEVERE');
            }
#
            self.disenabledecisionbuttons();
            self.enablepixelrange();
            self.enablefinecontrol();
         }
      } else {
         self.disenabledecisionbuttons();
         self.disablepixelrange();
         self.disablefinecontrol();
#
         include 'imagefittergui2.g';
         its.gui2 := imagefittergui2(theImage=its.image, n=ncomp,
                                     theDisplayPanel=its.display.dp,
                                     theRegionManager=its.rm,
                                     theDDD=its.display.ddd,
                                     widgetset=widgetset);
         if (is_fail(its.gui2)) {
            note(ok2::message, priority='SEVERE',
                 origin='imagefittergui.g');
         } else {
            its.gui2.setpolarization(its.pol);
            its.gui2.setddoptions(self.getddoptions());
            its.mode := 'complex';
            whenever its.gui2->done do {
               its.mode := 'simple';
               self.displaymessage('Create a region with the cursor (double click to emit)');
            }
            whenever its.gui2->fit do {
               its.gui2.disable();               # It's up to imagefitter to re-enable
               its.efl.hideall();
               its.gui2.hideallestimates();
#
               self->fit($value);
            }
         }
         self.disenabledecisionbuttons();
         self.enablepixelrange();
         self.enablefinecontrol();
#
         self.displaymessage('See Fine Control GUI for instructions');
      }
   }
#
##########################################################################
# Status and dismiss 
#
   its.f0.f1 := widgetset.frame(its.f0, side='left', expand='x', 
                                 relief='raised');
   its.f0.f1.message := widgetset.messageline(its.f0.f1, width=40);
   its.f0.f1.space := widgetset.frame(its.f0.f1, width=1, height=1, expand='x')
   its.f0.f1.dismiss := widgetset.button(its.f0.f1, text='Dismiss', 
                                          type='dismiss')
   widgetset.popuphelp(fr=its.f0.f1.dismiss, 
                       txt='Dismiss GUI but preserve its state (recover with .gui()', 
                       width=100);
   whenever its.f0.f1.dismiss->press do {
      ok := its.f0->unmap();
      if (is_agent(its.gui2)) its.gui2.dismiss();
      self->dismissed();
   }
   message := ref its.f0.f1.message;
#
   ok := its.f0->map();


### Public functions

###
   const self.clearhistogram := function ()
   {
      histo.eras();
      return T;
   }

###
   const self.clearresidual := function ()
   {
      its.resid.dp.unregister(its.resid.dd);
      return T;
   }

###
   const self.clearstatistics := function ()
   {
      statsMean->delete('start', 'end');
      statsSigma->delete('start', 'end');
      statsMin->delete('start', 'end');
      statsMax->delete('start', 'end');
      return T;
   }

###
   const self.disablemodifybuttons := function ()
   {
      modifyButton->disabled(T);         
      return T;
   }

###
   const self.disenabledecisionbuttons := function (disable=unset)
   {
      wider its;
#
      if (!is_unset(disable)) {
         acceptButton->disabled(disable);
         t := !its.isDecisionEnabled;
         its.isDecisionEnabled := !disable;
         return t;
      } else {
         if (its.isDecisionEnabled) { 
            acceptButton->disabled(T); 
            its.isDecisionEnabled := F;  
         } else {
            acceptButton->disabled(F);
            its.isDecisionEnabled := T;  
         }
         return !its.isDecisionEnabled;
      }
   }

###
   const self.disablepixelrange := function ()
   {
      wider its;
      its.f0.f2.r0.disable();
      return T;
   }
       
### 
   const self.disablefinecontrol := function ()
   {
      wider its;
      its.f0.f3.r0.disable();
      return T; 
   }
  
###
   const self.disablegui2 := function ()
   {
      wider its;
      if (is_agent(its.gui2)) {
         return its.gui2.disable();
      } else {
         return F;
      }
   }
###
   const self.displayimage := function (filename)
   {
      wider its;
#
      its.display.dd := its.display.viewer.loaddata(filename, 'raster');
      if (is_fail(its.display.dd)) fail;

# Set current polarization description

      its.pol := self.getcurrentpol();
#
# If the zaxis or hidden axes are changed, re-determine
# the Stokes and tell GUI2.  Also reset the GUI2 region to unset
# and give it the new DD options.
#   
      whenever its.display.dd->options do {
        if (its.mode=='complex') {
           pol := self.getcurrentpol();
           if (its.pol.stokes != pol.stokes ||
               its.pol.type != pol.type ||
               its.pol.index != pol.index) {
#
              its.pol := pol;
              its.gui2.setpolarization(its.pol);
              its.gui2.insertregion(unset);
              its.gui2.clearestimate();
              its.gui2.clearfit();
              its.gui2.setddoptions(self.getddoptions());
           }
         }
      }
      pNames := self.getddoptions().xaxis.popt;
#
# We force the x axis to be longitude and the y axis to latitude
#
      xaxis := pNames[its.skyaxes.pixel[1]];
      yaxis := pNames[its.skyaxes.pixel[2]];
#   
# Set zaxis to first non-sky axis
#
      zaxis := '';
      for (i in 1:length(pNames)) {
         if (i!=its.skyaxes.pixel[1] && i!=its.skyaxes.pixel[2]) {
            zaxis := pNames[i];             
            break;  
         }
      }
#
      if (strlen(zaxis)==0) {
         ok := its.display.dd.setoptions([xaxis=xaxis, yaxis=yaxis]);
      } else {
         ok := its.display.dd.setoptions([xaxis=xaxis, yaxis=yaxis, zaxis=zaxis]);
      }
      its.display.dp.register(its.display.dd);
      return T; 
   }
      
###
   const self.displayresidual := function (ref pixels)
   {
      wider its;
      if (length(its.resid.dd)>0) { 
         its.resid.viewer.deletedata(its.resid.dd);
      }
      its.resid.dd := its.resid.viewer.loaddata(pixels, 'raster');
      its.resid.dp.register(its.resid.dd);
      return T;
   }   

###   
   const self.displayhistogram := function (imageUnits, ref pixels, dMin='DEF',
                                            dMax='DEF', nBins=20)
   {
      if (is_string(dMin) && dMin=='DEF') dMin := min(pixels);
      if (is_string(dMax) && dMax=='DEF') dMax := max(pixels);
#
      histo.clear();
      histo.sch(1.5);
      histo.hist(pixels, dMin, dMax, nBins, 0);
      xLab := spaste('Intensity (', imageUnits, ')');
      histo.lab(xLab, 'Value', '');
      return T;                     
   }

###
   const self.displaymessage := function (txt1, txt2=unset)
   {
      wider its;
      t1 := txt1;
      t2 := txt2;
      if (is_unset(txt2)) t2 := txt1;
#
      if (its.mode=='simple') {
         message->clear();
         message->postnoforward(t1);
         its.message[1] := t1;
         return T;
      } else if (its.mode=='complex') {
         its.message[2] := t2;
         return its.gui2.insertmessage(t2);
      }
   }
                     
             
###
   const self.displaystatistics := function (ref pixels)
   {
      self.clearstatistics();
      statsMean->insert(sprintf("%8.3e", mean(pixels)));
      statsSigma->insert(sprintf("%8.3e", stddev(pixels)));
      statsMin->insert(sprintf("%8.3e", min(pixels)));
      statsMax->insert(sprintf("%8.3e", max(pixels)));
      return T;
   }

 ###
   const self.displayfitparameters := function (componentlist=unset, clear=F)
#
# clear==T is only used for the secondary GUI
#
   {
      wider its;
#
# Secondary GUI
#
      if (its.mode=='complex') {
         if (clear) {
            its.gui2.clearfit();
            return T;
         } else {
            ok := its.gui2.insertfit(componentlist);
            if (is_fail(ok)) {
               note (ok::message, priority='SEVERE',
                     origin='imagefittergui.displayfitparameters')   
            }
         }
      }
#
# Move on to primary GUI and insert parameters if CL valid
#
      if (!is_componentlist(componentlist) || clear==T) return T;

# Replace CL 1; this index always holds the current fit parameters.

      ok := its.efl.replacelistitem(componentlist, index=1, name='Current', im=its.image);
      if (is_fail(ok)) fail;
#
      return T;
   }

###
   const self.done := function ()
   {
      wider its, self;
#
      if (is_agent(its.gui2)) {
         its.mode := 'simple';
         ok := its.gui2.done();
      }
#
      if (length(its.restore)>0) {
         ok := its.restore.done();
      }
      if (length(its.save)>0) {
         ok := its.save.done();
      }
#
      if (is_agent(its.display.print)) {
         ok := its.display.print.done();
      }
      if (length(its.display.viewer)>0 &&
          is_agent(its.display.viewer)) {
         ok := its.display.viewer.done();      # Cleans up dd, ddd
      }
#
      if (is_agent(its.resid.print)) {
         ok := its.resid.print.done();
      }
      if (length(its.resid.viewer)>0 &&
          is_agent(its.resid.viewer)) {
         ok := its.resid.viewer.done();
      }
#
      ok := its.efl.done();
#
      val its := F;
      val self := F;
      return T;
   }  

###
   const self.enablemodifybuttons := function ()
   {
      modifyButton->disabled(F);
      return T;
   }


###
   const self.enablepixelrange := function () 
   {
      wider its;
      its.f0.f2.r0.enable();
      return T;
   }

###
   const self.enablefinecontrol := function () 
   {
      wider its;
      its.f0.f3.r0.enable();
      return T;
   }

###
   const self.enablegui2 := function () 
   {
      wider its;
      if (is_agent(its.gui2)) {
         return its.gui2.enable();
      } else {
         return F;
      }
   }

###
   const self.getcurrentplane := function()
#
# Returns one-rel absolute pixel of current plane
# being displayed
#
   {
      return its.display.animator.currentframe();
   }

###
   const self.getcurrentpol := function ()
#
# By great deviousness, this recovers the Stokes
# pixel and parameter of the currently displayed image
#
   {
#
# Get dd options
#
      opt := self.getddoptions();
      const n := length(opt.xaxis.popt);
#
# The displayed image must be the sky. See if the 
# z-axis is the Stokes axis
#
      idx := -1;
      stokesPixel := -1;
      if (has_field(opt, 'zaxis')) {
         name := to_upper(opt.zaxis.value);
         if (name=='STOKES') {
            stokesPixel := self.getcurrentplane();   # 1-rel      
            idx := 3;
         }
      }
#
# If we didn't find it here, we find it there
#
      if (stokesPixel==-1) {
        const nHidden := n - 3;
        if (nHidden>0) {
           for (k in 1:nHidden) {
              fn := spaste('haxis', k);
              name := to_upper(opt[fn].listname);
              if (name=='STOKES') {
                 stokesPixel := opt[fn].value;      # 1-rel
                 idx := 3 + k;
                 break;
              }
            }
         }
      }   
#
# We have the pixel, what Stokes is it ?
#
      rec := [=];
      if (stokesPixel!=-1) {
         pixel := 1:n;
         pixel[pixel] := 1;
         pixel[idx] := stokesPixel;
         cm := its.image.coordmeasures(pixel);
         if (is_fail(cm)) {
            note('Error finding Stokes parameter of displayed image - assuming I',
                  priority='SEVERE', origin='imagefittergui.getcurrentpol');
            rec.stokes := 'I';
            rec.type := 'stokes';
            rec.index := 1;
            return rec;
         }
#
# Now find an index into the componentlist polarization  order.  
#
         s := to_upper(cm.stokes);
         p := "I Q U V XX XY YX YY RR RL LR LL";
         i := [1,2,3,4,1,2,3,4,1,2,3,4];
         t := "";
         t[1:4] := 'stokes';
         t[5:8] := 'linear';
         t[9:12] := 'circular';
#
         rec.stokes := cm.stokes;
         rec.type := t[p==s];
         rec.index := i[p==s];
      } else {
#
# Assume total intensity (as does image.fitsky)
#
         rec.stokes := 'I';
         rec.type := 'stokes';
         rec.index := 1;
      }
      return rec;
   }


###
   const self.getddoptions := function()
   {
      return its.display.dd.getoptions();
   }


###
   const self.getdisplaymessage := function ()
   {
      return its.message;
   }

###
   const self.displaypanel := function ()
   {
      wider its;
      return its.display.dp;
   }

###
   const self.getmodeltypes := function ()
   {
#
# The basic interface only allows 1 Gaussians
#
      if (its.mode=='complex') {
        return its.gui2.getmodeltypes();
      } else {
        return "gaussian";
      }
   }

###
   const self.gui := function ()
   {
      wider its;
      its.f0->map();
      if (is_agent(its.gui2)) its.gui2.gui();
      return T;
   }

###
   const self.getpixelrange := function ()
   {
      which := pixelRange.getradiovalue();
#
      r := [=];
      r.include := [];
      r.exclude := [];
#
      if (which.name=='include') {

         r.include := pixelRange.getslidervalues();
      } else if (which.name=='exclude') {
         r.exclude := pixelRange.getslidervalues();
      }
#
      return r;
   }

###
   const self.redisplayimage := function (dmin=unset, dmax=unset)
   { 
       wider its;
       o := self.getddoptions();
       rec := [=];
       rec.reread := T;
       if (is_unset(dmin)) {
          rec.datamin := o.datamin.value;
       } else {
          rec.datamin := dmin;
       }
       if (is_unset(dmax)) {
          rec.datamax := o.datamax.value;
       } else {
          rec.datamax := dmax;
       }
       its.display.dd.setoptions(rec);
       return T;
   } 

###
   const self.getrestoredregions := function ()
   {
      return its.restore.regions();
   } 

###
   const self.removeregion := function()
   {
      its.display.dp.disablecontrols();
      its.display.dp.enablecontrols();
   }

###
   const self.getmaxpixels := function ()
   {
      wider its;
      return its.maxpix;
   }

###
   const self.setmaxpixels := function (maxpix)
   {
       wider its;
       if (maxpix < 1) {
          note ('This maxpix value is illegal - ignoring',
                 origin='imagefittergui.setmaxpixels',
                 priority='WARN');
          return F;
       } else { 
          its.maxpix := maxpix;
       }
#
       return T;
   }

###
   const self.setmodifybuttons := function (subtract)
   {
      wider its;
      if (subtract) {
         modifyButton->text('Subtract');
      } else {
         modifyButton->text('Add');
      }
      return T;
   }

###
   const self.setbusyregionevent := function (busy=T)
   {
      wider its;
      its.busy.getregions := busy;
      return T;
   }

###
   const self.setsaveregions := function (ref regions)
   {
      return its.save.setregions(regions);
   }

###
   const self.updatefitlist := function (componentlist, name)
   {
      wider its;

# Add new componentlist.  The efl tool maintains a list
# holding the current fit plus the accepted fits.

      ok := its.efl.replacelistitem(componentlist=componentlist, 
                                    name=name, list=F, im=its.image);
      if (is_fail(ok)) fail;
#
      return T;
   }

###
   const self.setfitlistcounter := function (count)
   {
      wider its;
      return its.efl.setcounter(count);
   }
}

