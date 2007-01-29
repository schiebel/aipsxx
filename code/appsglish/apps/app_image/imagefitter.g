# imagefitter.g: Fit images with models
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
#   $Id: imagefitter.g,v 19.2 2004/08/25 00:57:17 cvsmgr Exp $

 
pragma include once
include 'note.g'
include 'image.g'
include 'imagesupport.g'
include 'regionmanager.g'
include 'statistics.g'
include 'componentlist.g'
include 'serverexists.g'
include 'os.g'


const imagefittertest := function(which=unset)
{
    include 'imagefittertest.g'
    return imagefitterservertest(which=which);
}




const imagefitter := subsequence (infile, region=unset, ref parent=F, 
                                  auto=F, gui=T, residual='',
                                  maxpixels=256*256, widgetset=unset)
#
# region         - specifies region of image to display 
# auto=T         - automatically make fit from self found
#                  islands.  But if region is set, use those
#                  regions instead (region can be a record with a 
#                  many regions in it)
#
# gui  T         - use GUI.  For automodes, just show results
# residual       - if modify==F, the a copy of the input image
#                  is made, and the subtracted data stored in it.
#                  If you wish to save the residual image, specify
#                  the name of the residual image.  Otherwise a temporary
#                  file will be used and destroyed on exit.
# maxpixels      - maximum number of pixels to fit without querying user via GUI
{

   if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is either not running or not valid', 
                    origin='imagefitter.g');
   }
   if (!serverexists('drm', 'regionmanager', drm)) {
      return throw('The regionmanager "drm" is either not running or not valid', 
                    origin='imagefitter.g');
   }
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is either not running or not valid', 
                    origin='imagefitter.g');
   }
   if (!serverexists('defaultimagesupport', 'imagesupport', defaultimagesupport)) {
      return throw('The imagesupport server "defaultimagesupport" is either not running or not valid', 
                    origin='imagefitter.g');
   }
   if (auto) {
      return throw('The automatic modes are not yet implemented', 
                    origin='imagefitter.g');
   }

#
   its := [=];
#
   its.gui := [=];                              # Main GUI
   its.residual := residual;
   its.tempdir := '';
#
# This describes whether we are in basic auto-estimate mode or
# the more complex interface where the user can set estimates
# interactively (for 1 or more components)
#
   its.mode := 'simple';               # or 'complex'
#
# These are all the componentlists we maintain
#
   its.cl := [=];
   its.cl[1] := [=];                             # The current fit
   its.cl[2] := [=];                             # The last accepted fit
   its.fitlist := [=];                           # A record of componentlists, one per accepted fit
   its.regionslist := [=];                       # A record of regions, one per accepted fit
#
# This houses the residual pixels and mask after each fit
#
   its.resid := [=];    
   its.resid.pixels := [];
   its.resid.mask := [];
#
# This houses the fit region
#
   its.fit := [=];
   its.fit.region := [=];        # The intersection of the above region
                                 # and the plane displayed.  This is what 
                                 # goes to the fitting function
   its.fit.bb := [=];            # Bounding box of the fit region
#
   its.openedConstructionImage := F;         # Did we open the construction image
#
   its.image := [=];
   its.image.construction.object := [=];     # The construction image object
   its.image.object := [=];                  # The image object used to get/fit/subtract data
                                             # may be a ref to its.image.construction.object
   its.image.bunit := '';                    # Brightness unit
   its.image.shape := '';                    # Shape of input image
   its.image.skyaxes := [=];                 # Where are the sky axes
   its.image.stats := [=];                   # Statistics record for construction image
   its.image.coordsys := [=];                # Coordsys tool
#
# Take note of some whenevers that we have to turn on and off
# to handle autofitting. Also a whenever that is deactivated when 
# fitting so that the user doesn't continue to make regions
# whilst not having yet decided what to do with the current one.
#
   its.inter_whenevers := [];
   its.fit_whenevers := [];
   its.system_whenevers := [];
#
   its.busy := [=];
   its.busy.fit := F;
 

### Private functions

###
   const its.activate_deactivate := function (list, doActivate)
   {
       n := length(list);
       if (n > 0) {
          if (doActivate) {
             for (i in 1:n) {
               activate list[i];
             }
          } else {
             for (i in 1:n) {
                deactivate list[i];
             }
          }
       }
   }

###
    const its.autofit := function (ref regions)
    {
       wider its;
#
# Turn off other whenevers looking for the acceptFit event
#
       its.activate_deactivate(its.inter_whenevers, F);
#
       const n := length(regions);
       estimate := emptycomponentlist(log=F);
       if (n>0) {
          its.gui.setbusyregionevent(T);
          its.gui.disablemodifybuttons();
          its.gui.disenabledecisionbuttons(disable=T);
          its.gui.disablepixelrange();
          its.gui.disablefinecontrol();
          for (i in 1:n) {
             if (!drm.isworldregion(regions[i])) {
                msg := spaste('Record ', i, ' of the regions record is not a valid world region');
                note (msg, priority='SEVERE', origin='imagefitter.g');
             } else {
                msg := spaste('Fitting region ', i);
                note ('', priority='NORMAL', origin='imagefitter.g');
                note (msg, priority='NORMAL', origin='imagefitter.g');
#
                its.fit.region := regions[i];
                ok := its.fitone(estimate, "");
                its.acceptFit();
             }
          }
#
          its.gui.setbusyregionevent(F);
          its.gui.enablemodifybuttons();
          its.gui.disenabledecisionbuttons(disable=F);
          its.gui.enablepixelrange();
          its.gui.enablefinecontrol();
       }
       its.activate_deactivate(its.inter_whenevers, T);
       its.gui.displaymessage('Create a region with the cursor (double click to emit)');
       estimate.done();
    }

###
    const its.cleanup := function ()
    {
       if (dos.fileexists(file=its.tempdir, follow=T)) {
          ok := dos.remove(pathname=its.tempdir, recursive=T, follow=T);
          if (is_fail(ok)) return F;
       }
       return T;
    }

###
   const its.copyimage := function (region)
   {
      wider its;

# Generate file name for copied image

      local filename;
      if (strlen(its.residual)>0) {
         filename := its.residual;
      } else {
         inname := its.image.construction.object.name(strippath=F);
         parentdir := dos.dirname(inname);
         if (is_fail(parentdir)) fail;
         root := spaste(parentdir, '/', 'imagefitter_temp');
         its.tempdir := defaultimagesupport.defaultname(root);
         if (is_fail(its.tempdir)) fail;
#
         if (is_fail(dos.mkdir(its.tempdir))) {
            msg := spaste('Could not create temporary directory ', its.tempdir);
            return throw(msg, origin='imagefitter.g');
         }
#
         filename := spaste(its.tempdir, '/', 'imagefitter.copy');
      }

# Copy image

      msg := spaste('Copying image to "', filename, ' "');
      note(msg, priority='NORMAL', origin='imagefitter.g');
      if (is_unset(region)) {
         its.image.object := 
            its.image.construction.object.subimage(outfile=filename,
                                                   list=F);
      } else {
         its.image.object := 
            its.image.construction.object.subimage(outfile=filename,
                                                   region=region, list=F);
      }
      if (is_fail(its.image.object)) fail;
      its.image.object.unlock();    # Give DL immediate access
#      
      return T;
   }


###
   const its.findsky := function ()
   {
      wider its;
#
# Which axes in the image are long then lat.  imagefittergui.displayimage
# will always display x=long and y=lat
#
      local pa, wa;
      ok := its.image.coordsys.findcoordinate(pa, wa, 'direction', 1);
      if (!ok || is_fail(ok)) fail; 
#
      its.image.skyaxes.pixel := pa;
      its.image.skyaxes.world := wa;
#
      return T;
   }

###
   const its.fitone := function (estimate, fixed)
   {
      wider its;
#
      txt1 := 'Create a region with the cursor (double click to emit)';
      txt2 := 'When estimate OK, press "Fit"';
#
      local converged, error;
      its.gui.displaymessage('Computing fit');
      range := its.gui.getpixelrange();
      ok := its.image.object.fitsky(pixels=its.resid.pixels, 
                                    pixelmask=its.resid.mask, 
                                    converged=converged,  
                                    region=its.fit.region, 
                                    models=its.gui.getmodeltypes(),
                                    estimate=estimate,
                                    fixed=fixed,
                                    includepix=range.include,
                                    excludepix=range.exclude,
                                    deconvolve=F, list=F);
      if (is_fail(ok)) {
         note ('Fit failed - rejected', priority='WARN', 
                origin='imagefitter.fitone');
         ok2 := its.gui.displayfitparameters(clear=T);
         ok2 := its.gui.displaymessage(txt1, txt2);
         return F;
      } else {
         if (!converged) {
            note ('No convergence, fit rejected', priority='WARN', 
                  origin='imagefitter.fitone');
            ok2 := its.gui.displayfitparameters(clear=T);
            ok2 := its.gui.displaymessage(txt1, txt2);
            return F;
         } else {
#
# Display residuals
#
            its.cl[1] := ok;
            its.fit.bb := its.image.object.boundingbox(its.fit.region);
            its.gui.displayresidual(its.resid.pixels);
#
            its.gui.displayhistogram(its.image.bunit,
                                     its.resid.pixels[its.resid.mask]);
#
            its.gui.displaystatistics(its.resid.pixels[its.resid.mask]);
#
            its.gui.displayfitparameters(its.cl[1]);
            its.gui.displaymessage('Click "Accept", "Subtract" or refit');
            return T;
         }
      }
   }


###
   const its.getmaxpixels := function ()
   {
      wider its;
      if (has_field(its, 'gui')) {

         return its.gui.getmaxpixels();
      } else {
         return maxpixels;
      }
   }


###
   const its.acceptFit := function ()
   {
      wider its;
#
# Extra protection incase somehow a bad componentlist comes in
#
      if (!is_componentlist(its.cl[1])) {
         note ('The current fitted Componentlist is not valid - cannot accept',
               origin='imagefitter.acceptFit', priority='WARN');
         return T;
      }      
#
# Update last accepted fit with current fit
#
      its.cl[2] := its.cl[1];
#
# Add fit to list.
#
      idx := length(its.fitlist) + 1;
      its.fitlist[idx] := emptycomponentlist(log=F);
      ok := its.fitlist[idx].concatenate(its.cl[2],log=F);
      if (is_fail(ok)) fail;
#
# Add regions to list
#
      its.regionslist[idx] := its.fit.region;
#
# Update GUI list display with new Componentlist
#
      ok := its.gui.updatefitlist (componentlist=its.fitlist[idx], 
                                   name=as_string(idx));
      if (is_fail(ok)) fail;
      its.gui.setfitlistcounter(length(its.fitlist));
#
      return T;
   }


###
   const its.openimage := function (const imagename)
#
# Handles a string or image object
#
   {
      wider its;
      t := ref imagename;
      if (is_image(imagename)) {
         its.openedConstructionImage := F;
      } else if (is_string(imagename)) {
         t := image(imagename);
         if (is_fail(t)) fail;
         its.openedConstructionImage := T;
      }
      return t;
   }

###
   const its.sendRegionsToGui := function ()
#
# Send the regions to the saveregions widget.  
#
   {
      const n := length(its.regionslist);
      if (n > 0) {
         its.gui.setsaveregions(its.regionslist);
      } else {
         note ('There are no regions to save yet',
               priority='WARN', origin='imagefitter.sendRegionsToGui');
      }
#
      return T;
   }

###
   const its.modifyImage := function (subtract=T)
   {
      wider its;
#
      if (!is_componentlist(its.cl[1])) {
         note('There are no models yet', priority='WARN', 
              origin='imagefitter.modifyImage');
         return T;
      }
#
      s := 'Add';
      if (subtract) {
         its.gui.displaymessage('Subtracting model');
      } else {
         its.gui.displaymessage('Adding model');
         s := 'Subtract';
      }
#
# Disable buttons until done
#
      its.gui.disablemodifybuttons();
      ms := its.gui.disenabledecisionbuttons(disable=T);
#
# Subtract/add last fit.
#
      displayedPlane := drm.displayedplane(its.image.object, its.gui.getddoptions(),
                                           its.gui.getcurrentplane());
      if (is_fail(displayedPlane)) fail;      
      ok := its.image.object.modify(model=its.cl[1], region=displayedPlane,
                                    subtract=subtract, list=F);
      if (is_fail(ok)) fail;
      its.image.object.unlock();
#
# Now redisplay the image/region.  Since we do not specify 
# dmin and dmax, whatever the current min/max are
# will be reused.
#
      ok := its.gui.redisplayimage();
      if (is_fail(ok)) fail;
#
# Re-enable modify buttons 
#
      its.gui.enablemodifybuttons();
# 
# Put decision button back to previous state
#
      its.gui.disenabledecisionbuttons(ms);
#
      t := spaste('Click "Accept", "', s, '" or refit');
      its.gui.displaymessage(t);
#
      return T;
   }

### Public functions
###
   const self.regions := function (which=unset)
   {
      wider its;
      n := length(its.regionslist);
      if (n==0) {
         note('The fitlist is empty', priority='WARN',
              origin='imagefitter.regions');
         return [=];
      }
#
      if (is_unset(which)) {
         return its.regionslist;
      } else {
         idx:= as_integer(which);
         if (idx<1 || idx>n) {
            s := spaste ('Illegal fit/componentlist index, \n',
                         'there have been ', n, ' accepted fits');
            return throw (s, origin='imagefitter.componentlist');
         }
#
         return its.regionslist[idx];
      }
   }

###
   const self.componentlist := function (which=unset, concatenate=F, deconvolve=F)
   {
      wider its;
#
      i1 := 1;
      i2 := length(its.fitlist);      
      if (i2==0) {
         note('The fit list is empty', priority='WARN',
              origin='imagefitter.componentlist');
         return [=];
      }

# Just return fitlist if so desired

      if (is_unset(which) && !concatenate) {
         if (deconvolve) {
            r := [=];
            for (i in 1:i2) {
               r[i] := its.image.object.deconvolvecomponentlist(its.fitlist[i]);
               if (is_fail(r[i])) fail;
            }
            return r;
         } else {
            return its.fitlist;
         }
      }

# Else concatenate componentlists from all entries
# or just return specified componentlist

      if (!is_unset(which)) {
         idx:= as_integer(which);
         if (idx<1 || idx>i2) {
            s := spaste ('Illegal fit/componentlist index, \n',
                         'there have been ', i2, ' accepted fits');
            return throw (s, origin='imagefitter.componentlist');
         }
         i1 := idx;
         i2 := idx;
      }
#
      t := emptycomponentlist(log=F);
      for (idx in i1:i2) {
         if (deconvolve) {
            cl := its.image.object.deconvolvecomponentlist(its.fitlist[idx]);
            if (is_fail(cl)) fail;
            ok := t.concatenate(cl, log=F);
            if (is_fail(ok)) fail;
         } else {
            ok := t.concatenate(its.fitlist[idx], log=F);
            if (is_fail(ok)) fail;
         }
      }
#
      return t;
   }

###
   const self.done := function ()
   {
      wider its;
      wider self;
#
# Shut down GUI.    This cleans up any viewer attachments to any 
# image objects so we must do this first.
#
      if (length(its.gui)>0) its.gui.done();
      deactivate its.system_whenevers[1];         
#
# Done tools
#
      if (its.openedConstructionImage) {
         its.image.construction.object.done();
      } 
      its.image.object.done();
      its.image.coordsys.done();
#
      if (strlen(its.residual)==0) {
         ok := its.cleanup();
         if (ok::status) {
            msg := spaste('Could not remove temporary directory ',
                          its.tempdir);
            note (msg, priority='WARN', origin='imagefitter.g'); 
         }
      }
#
# Do in componentlists, fitlist and editor
#
      if (is_componentlist(its.cl[1])) ok := its.cl[1].done();
      if (is_componentlist(its.cl[2])) ok := its.cl[2].done();
#
      n := length(its.fitlist);
      if (n > 0) {
         for (i in 1:n) {
            ok := its.fitlist[i].done();
         }
      }
#
# Do ourselves in.
# 
      val its := F;
      val self := F;
#
      return T;
   }



###
   const self.gui := function() 
   {
      if (has_field(its, 'gui')) {
         its.gui.gui();
      } else {
         note ('No GUI is available in this mode', 
               priority='WARN', origin='imagefitter.g');
      }
      return T;
   }

###
   const self.nfits := function ()
   {
      return length(its.fitlist);
   }

###
   const self.setmaxpixels := function (maxpix) 
   {
      wider its;
#
      if (has_field(its, 'gui')) {
         its.fit.maxpix := its.gui.setmaxpixels(maxpix);
      }
#
      return T;
   }

###
   const self.summary := function ()
   {
      return its.image.construction.object.summary();
   }


###
   const self.type := function ()
   {
      return 'imagefitter';
   }

### Constructor 
#
# Open the construction image
#
   its.image.construction.object := its.openimage(infile)
   if (is_fail(its.image.construction.object)) fail;

# Copy the construction image if required, applying the region.

   ok := its.copyimage(region);
   if (is_fail(ok)) fail;
#
# Generate coordsys tool
#
   its.image.coordsys := its.image.object.coordsys();
   if (is_fail(its.image.coordsys)) fail;
#
# Set coordinate system of image into regionmanager and find the
# DirectionCoordinate sky axes
#
   if (!its.findsky()) {
      return throw ('This image does not have a sky plane',
                    origin='imagefitter.g');
   }
   ok := drm.setcoordinates(its.image.coordsys, F);
   if (is_fail(ok)) fail;
#
# Get hold of some axis information (in pixel axis order) 
#   
   its.image.bunit := its.image.object.brightnessunit();
   if ((strlen(its.image.bunit))==0) its.image.bunit := 'Jy';
   its.image.shape := its.image.object.shape();
   ok := its.image.object.statistics(statsout=its.image.stats, list=F);
   if (is_fail(ok)) fail;
   if (length(its.image.stats.npts)==0) {
      return throw('The image appears to be fully masked bad',
                   origin='imagefitter.g');
   }
   its.image.object.unlock();
#
# Do the work
#
   if (auto) {
      if (gui) {
      } else {
      }
   } else {
      include 'imagefittergui.g';
#     
# Main GUI
#
      include 'ddlws.g';                                      # Defer to run time
      if (is_unset(widgetset)) widgetset := ddlws;
#
      its.gui := imagefittergui(parent, expandResiduals=F,
                                image=its.image.construction.object,
                                regionmanager=drm,
                                dmin=its.image.stats.min[1],
                                dmax=its.image.stats.max[1],
                                maxpix=maxpixels,
                                widgetset=widgetset);
      if (is_fail(its.gui)) fail;
      if (is_boolean(its.gui) && its.gui==F) {
         return throw ('No display is currently available (is DISPLAY set ?)',
                       origin='imagefitter.g');
      }
      its.gui.disenabledecisionbuttons();
      its.gui.disablemodifybuttons();
#
# Send image to Viewer.
#
      ok := its.gui.displayimage(its.image.object.name(strippath=F));
      if (is_fail(ok)) fail;
#
      its.gui.displaymessage('Create a region with the cursor (double click to emit)');
#
# Respond to fit event.  We don't listen for any more "fit" events until 
# the user is done with this one.  
#
      whenever its.gui->fit do {
         if (its.busy.fit) {
            note ('You are sending fit requests too frequently',
                   priority='WARN', origin='imagefitter.g');
         } else {
            its.busy.fit := T;
            evalue := $value;
            its.fit.region := evalue.region;

# Try and guess whether the user has asked for a sensible fit or not

            bb := its.image.object.boundingbox(its.fit.region);
            nPixels := prod(bb.bbShape);
            ok := T;
            if (nPixels > its.getmaxpixels()) {
               include 'choice.g'
               s := spaste('Fitting ', nPixels, ' pixels > max (', its.getmaxpixels(), ') - continue ?');
               c := choice(s, "Yes No", timeout=10.0);
               ok := (c=='Yes');
            }
#
            if (ok) {
               its.gui.disablemodifybuttons();
               its.gui.disenabledecisionbuttons(disable=T);
#
# Do the fit.  fitone catches fails and always returns T or F
#
               if (!is_fail(ok)) {
                  ok := its.fitone(evalue.estimate, evalue.fixed);
                  if (ok) {
                     its.gui.setmodifybuttons(subtract=T);
                     its.gui.disenabledecisionbuttons(disable=F);
                  }
                } else {
                  its.gui.setmodifybuttons(subtract=T);
                  its.gui.disenabledecisionbuttons(disable=F);
               }

# Tell fine-control GUI to reactivate

               its.gui.enablegui2();
               its.gui.enablemodifybuttons();
            }
#
# Tell GUI to listen to region events again. When a fit event is generated,
# the GUI will stop listening for region events until told otherwise
#
            its.gui.setbusyregionevent(F);
            its.busy.fit := F;
         }
      }
      its.fit_whenevers[1] := last_whenever_executed();
#
# If user likes the fit, add it to the list
#
      whenever its.gui->acceptfit do {
         its.gui.disenabledecisionbuttons();
         ok := its.acceptFit();
         if (is_fail(ok)) {
            note (ok::message, priority='SEVERE', origin='imagefitter.g');
         }
         its.gui.displaymessage('Create a region with the cursor (double click to emit)',
                                'When estimate OK, press "Fit"');
#
         self->accept(length(its.fitlist));
      }
      idx := length(its.inter_whenevers) + 1;
      its.inter_whenevers[idx] := last_whenever_executed();
#
# Subtract or add fit to main display
#
      whenever its.gui->modify do {
         txt := its.gui.getdisplaymessage();
         its.modifyImage($value);
         its.gui.displaymessage(txt[1], txt[2]);
      }
#
# Send accepted fit regions to the GUI saveregions widget
# for saving
#
      whenever its.gui->savePressed do {
         its.sendRegionsToGui();
      }
#
# The user has restored regions from a table.  Fit them all
# one after another.
#
      whenever its.gui->restored do {
         regions := its.gui.getrestoredregions();      
         its.gui.disablemodifybuttons();
         if (is_fail(its.autofit(regions))) fail;
         its.gui.enablemodifybuttons();
      }
#
# Fitlist deletion event
#
      whenever its.gui->fitlistDelete do {

# Get list of deleted indices.  In the GUI the first fitlist entry is 
# always the current fit, so we discard that one and subtract one from the
# index.  This puts the indices in step with those and the regions held here.

         idx := $value;

# Update the associated lists by dropping the deleted entries
# This is expensive but there is no other way to do this

         if (length(idx) > 0) {
            for (i in idx) {
               if (i > 1) {
                  its.regionslist[i-1] := F;     # or .done() ?
               }
            }
#
            r := [=];
            c := [=];
            j := 1;
            nr := length(its.regionslist);
            if (nr > 0) {
               for (i in 1:nr) {
                  if (!is_boolean(its.regionslist[i])) {
                     r[j] := its.regionslist[i];
                     c[j] := emptycomponentlist(log=F);
                     ok := c[j].concatenate(its.fitlist[i], log=F);
                     j +:= 1;
                  }
               }
#
               n := length(its.fitlist);
               if (n > 0) {
                  for (i in 1:n) {
                     ok := its.fitlist[i].done();
                  }
               }
#
               its.regionslist := r;
               its.fitlist := c;
            }
         }
#
         its.gui.setfitlistcounter(length(its.fitlist));
      }
#
# Do ourselves in
#
      whenever its.gui->exit do {
         self.done();
      }
      whenever system->exit do {
         self.done();
      }
      its.system_whenevers[1] := last_whenever_executed();
   }
}
