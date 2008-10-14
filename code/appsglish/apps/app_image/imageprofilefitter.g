# imageprofilefitter.g: Fit profiles in images with models
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
#   $Id: imageprofilefitter.g,v 19.11 2004/08/25 00:58:57 cvsmgr Exp $
#
#  imageprofilefitter          - top-level tool
#     imageprofilefittergui    - shows image, user selects profiles and regions
#     profilefittergui         - shows profile and fitter parameters
#         imageprofilesupport  - shows profile
#         specfitcompgui       - shows fitting parameters
#
 
pragma include once
include 'note.g'
include 'quanta.g'
include 'image.g'
include 'imagesupport.g'
include 'regionmanager.g'
include 'serverexists.g'
include 'os.g'
include 'unset.g'


const imageprofilefitter := subsequence (infile, infile2=unset, sigma=unset, parent=F, 
                                         axis=unset, plotter=unset, showimage=T, 
                                         widgetset=unset)
{
   if (!serverexists('dq', 'quanta', dq)) {
      return throw('The quanta server "dq" is either not running or not valid', 
                    origin='imageprofilefitter.g');
   }
   if (!serverexists('drm', 'regionmanager', drm)) {
      return throw('The regionmanager "drm" is either not running or not valid', 
                    origin='imageprofilefitter.g');
   }
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is either not running or not valid', 
                    origin='imageprofilefitter.g');
   }
   if (!serverexists('defaultimagesupport', 'imagesupport', defaultimagesupport)) {
      return throw('The imagesupport server "defaultimagesupport" is either not running or not valid',
                    origin='imageprofilefitter.g');
   }

#
   its := [=];
#
   its.infile := '';            # Main image
   its.infile2 := unset;        # Display image
   its.sigma := unset;          # Weights image
#
   its.axis := axis;            # Profile pixel axis
   its.axes := [];              # Axes to average over
   its.mode := 'interactive';   # Mode: interactive or automatic
   its.showimage := showimage;  # If T the primary GUI is used.  If F it's not.
#
   its.image := [=];
   its.image.object := [=];           # Image tool
   its.image.csys  := [=];            # Coordsys tool
   its.image.opened := F;             # T if we made the tool (needs to be doned)
   its.image.bunit := '';
#
   its.momentimage := [=];
   its.momentimage.object := [=];     # Image tool
   its.momentimage.opened := F;       # T if we made the tool (needs to be doned)
   its.momentimage.dir := unset;      # Where we put the moment image if we make it
#
   its.position:= [=];               # Current position selected with cursor
   its.position.pixel := [];
   its.position.world := [=];
   its.region := [=];                  #
   its.region.region := [=];           # Region generated from GUI with region tool 
                                       # when not averaging profiles
   its.region.profile := [=];          # Region generated from GUI with position tool 
 				       # or region from region tool when averaging profiles
#
   its.data.profile := [];          # Profile generated from its.region.profile
   its.data.mask := [];             # Mask generated from its.region.profile
 #
   its.estimate := [=];             # The estimate
   its.estimate.profile := [];
   its.estimate.mask := [];
   its.estimate.residual := [];
#
   its.fit := [=];                  # The fit
   its.fit.profile := [];
   its.fit.mask := [];
   its.fit.residual := [];
#
   its.store := [=];            # Internal store of fits/estimates (as added by user)
#
   its.gui := [=];              # GUI displaying moment image
#
   its.gui2 := [=];             # GUIs for interactive profile display and fitting
   its.gui2.fit := [=];         # For fitting
#
   its.plotnames := ['Estimate', 'Fit', 'Residual', 'Fit Individual'];
   its.ci := [=];               # Colour indices for plotting
   its.ci['Data'] := 1;           # White
   its.ci['Estimate'] := 7;       # Yellow
   its.ci['Fit'] := 9;        # Lime green
   its.ci['Fit Individual'] := 5; # Pale blue
   its.ci['Residual'] := 2;       # Red
#
   its.title := [=];            # Title string for plotter
   its.title.pos := [=];        # This bit holds the position part of the title
   its.title.pos.text := '';
   its.title.pos.ci := 1;
   its.title.what := [=];       # This bit holds what we are plotting
   its.title.what.text := "";
   its.title.what.ci := [];
#                               # Don't bother me, I'm busy
   its.busy := [=];
   its.busy['estimate'] := F;
   its.busy['fit'] := F;
   its.busy['position'] := F;
   its.busy['replot'] := F;
   its.busy['region'] := F;
   its.busy['evaluate'] := F;
   its.busy['clipboard'] := F;
   its.busy['add'] := F;
#
   its.whenevers := [=];
   its.whenevers['exit'] := [];

### Private functions



###
   const its.convertPosition := function (value)
#
# Convert position from moment image to nD image
#
   {
      wider its;
#
      p := as_integer(its.image.csys.topixel(value.measure) + 0.5);
      blc := p;
      trc := p;

# Needs some thinking here. I am assuming the first two
# non-profile axes are the spatial averaging ones. 

      width := value.width;
      s := its.image.object.shape();
      if (width > 0) {
         for (i in 1:2) {
            idx := its.axes[i];
            t := blc[idx] - width;
            blc[idx] := max(1, t);
            t := trc[idx] + width;
            trc[idx] := min(s[idx], t);
         }
      }
      blc[its.axis] := 1;
      trc[its.axis] := s[its.axis];
#
      r := drm.box(blc, trc);
      if (is_fail(r)) fail;

# Convert to world again

      w := its.image.csys.toworld(p, 'nms');
      if (is_fail(w)) fail;
#
      rec := [=];
      rec.position := [=];
      rec.position.pixel := p;
      rec.position.world := w;
      rec.region := r;
#         
      return rec;
   }

###
   const its.convertRegion := function (value)
#
# Convert region from moment image to nD image
# The region will reflect all display and hidden axis values
#
   {
      wider its;

# Make extension box for profile axis

      s := its.image.object.shape();
      blc := "1pix";
      trc := spaste(s[its.axis], 'pix');
      ebox := drm.wbox(blc=blc, trc=trc,
                       pixelaxes=its.axis,
                       csys=its.image.csys);
      if (is_fail(ebox)) fail;

# Extend region over profile axes and set to current
# value on all other axes

      region := drm.extension (box=ebox, region=value.region);
      if (is_fail(region)) fail;

# Now find average pixel location. This will be used by the
# profile plotter to compute the abcissa vector
#

      bb := its.image.object.boundingbox(value.region);
      if (is_fail(bb)) fail;

# Assume first two non-profile axes are the display axes

      p := bb.blc;
      for (i in 1:2) {
         idx := its.axes[i];
         p[idx] := (bb.blc[idx] + bb.trc[idx]) / 2.0;
      }
      w := its.image.csys.toworld(p, 'nms');
      if (is_fail(w)) fail;
#
      rec := [=];
      rec.region := region;
#
      rec.position := [=];
      rec.position.pixel := p;
      rec.position.world := w;
#
      return rec;
   }

###
   const its.done := function (dogui)
   {
      wider its;
      wider self;
#
      deactivate its.whenevers['exit']
#
      if (dogui && is_agent(its.gui) && length(its.gui)>0) {
         ok := its.gui.done();
      }
#
      if (is_agent(its.gui2.fit) && length(its.gui2.fit)>0) {
        ok := its.gui2.fit.done();
      }
#
      if (its.image.opened) {
         ok := its.image.object.done();
      } 
      ok := its.image.csys.done();
#
      if (its.momentimage.opened) {
         ok := its.momentimage.object.done();
      } 
      if (is_unset(its.infile2)) {
         if (!is_unset(its.momentimage.dir)) {
            if (dos.fileexists(file=its.momentimage.dir, follow=T)) {
               ok := dos.remove(pathname=its.momentimage.dir, recursive=T, follow=T);
            }
         }
      }
# 
      val its := F;
      val self := F;
#
      return T;
   }


###
   const its.evaluateOneComponent := function (ref profile, ref residual, model, which)
   {

# Copy generic elements

      x := [=];
      for (fn in field_names(model)) {
         if (fn != 'elements') x[fn] := model[fn];
      }

# Now create an elements item for just one component

      x.elements := [=];
      x.elements[1] := [=];
      n := length(model.element);
      for (fn in field_names(model.elements[which])) {
         x.elements[1][fn] := model.elements[which][fn];
      }

#  Returns an empty record if ok

      ok := its.image.object.fitprofile (profile, residual,
                                         region=its.region.profile,
                                         fit=F, axis=its.axis,
                                         estimate=x);
      if (is_record(ok) && length(ok)==0) return T;
      return ok;
   }

###
   const its.getandplotprofile := function ()
   {
      wider its;
#
      method := 'fit';
      its.gui2[method].setfitbuttonname('Fit profile');
      its.gui2[method].map();

# Get averaged spectrum from whole image 

      shp := its.image.object.shape();
      its.region.profile := [=];
      its.region.region := [=];
      n := length(shp);
      its.position.pixel := array(1, n);
#
      ok := its.image.object.getregion(its.data.profile, its.data.mask,
                                       axes=its.axes, dropdeg=T);
      if (is_fail(ok)) fail;

# Set up title 

      w := its.image.csys.toworld(its.position.pixel, 'nms');
      if (is_fail(w)) fail;
#
      its.title.what := its.makeTitle ();
      its.title.pos.text := 
           spaste ('     ', w.string, ' (', as_string(its.position.pixel), ')');
      title := [its.title.what.text, its.title.pos.text];
      ci := [its.title.what.ci, its.title.pos.ci];
      ok := its.gui2.fit.settitle (title, ci);

# Plot

      ok := its.gui2.fit.clearandresetplot();
      ok := its.gui2.fit.setplot(pos=its.position.pixel, ordinate=its.data.profile, 
                                 mask=its.data.mask,  ci=its.ci['Data'],  
                                 unit=its.image.bunit, which=1);
      its.gui2.fit.plot();    
#
      return T;
   }



###
   const its.handlePosition := function (eventValue) 
   {
       wider its;
#
       its.mode := 'interactive';

# Map appropriate GUI.  Can have both...

#     method := its.gui.getmethod();
       method := 'fit';
       its.gui2[method].setfitbuttonname('Fit profile');
       its.gui2[method].map();

# Convert position from the 2D display to that of the N-D image

       rec := its.convertPosition (eventValue);
       if (is_fail(rec)) fail;

# Store the centre position and the region to average over.  

       its.position := rec.position;
       its.region.profile := rec.region;
#
       ok := its.image.object.getregion(its.data.profile, its.data.mask,
                                        region=its.region.profile, axes=its.axes, 
                                        dropdeg=T);
       if (is_fail(ok)) fail;

# Set up title 

       its.title.what := its.makeTitle ();
       its.title.pos.text := 
          spaste ('     ', its.position.world.string, ' (', as_string(its.position.pixel), ')');
       title := [its.title.what.text, its.title.pos.text];
       ci := [its.title.what.ci, its.title.pos.ci];
       ok := its.gui2.fit.settitle (title, ci);

# Plot

       ok := its.gui2.fit.clearandresetplot();
       ok := its.gui2.fit.setplot(pos=its.position.pixel, ordinate=its.data.profile, 
                                  mask=its.data.mask,  ci=its.ci['Data'],  
                                  unit=its.image.bunit, which=1);
      its.gui2.fit.plot();    
#
      return T;
   }



###
   const its.handleRegion := function (doAverage, eventValue) 
   {
       wider its;
#
       its.gui.disable();

# Map appropriate GUI.  

#       method := its.gui.getmethod();
       method := 'fit';
       its.gui2[method].map();

# Convert pseudoregion to true region

       rec := its.convertRegion (eventValue);
       if (is_fail(rec)) fail;

# Store the centre position and region

       its.position := rec.position;
       its.region.profile := [=];
       its.region.region := [=];
#
       if (doAverage) {
          its.gui2[method].setfitbuttonname('Fit profile');
          its.mode := 'interactive';

# Average all profiles in region

          its.region.profile := rec.region;
          ok := its.image.object.getregion(its.data.profile, its.data.mask,
                                           region=its.region.profile, axes=its.axes, 
                                           dropdeg=T);
          if (is_fail(ok)) fail;
       } else {
          its.gui2[method].setfitbuttonname('Fit region');
          its.mode := 'automatic';

# Non-averaging case - we will plot the first spectrum and fit all spectra in region

          its.region.region := rec.region;

# Print bounding box
       
          bb := its.image.object.bb(its.region.region);
          s := spaste('Bounding box = ', bb.blc, ' to ', bb.trc);
          note (s, origin='imageprofilefitter.g');

# Get profile from BLC of bounding box
        
          blc := bb.blc;
          trc := blc;
          trc[its.axis] := bb.trc[its.axis];

# Store position and region

          its.region.profile := drm.box(blc,trc);
          its.position.pixel := blc;                     # Only need pixel position

# Get profile

           ok := its.image.object.getchunk(blc=blc, trc=trc, axes=its.axes, dropdeg=T, getmask=T);
           if (is_fail(ok)) fail;
#
           its.data.profile := ok.pixels;
           its.data.mask := ok.pixelmask;
       }
    
# Set up title 

       its.title.what := its.makeTitle ();
       its.title.pos.text := 
          spaste ('     ', its.position.world.string, ' (', as_string(its.position.pixel), ')');
       title := [its.title.what.text, its.title.pos.text];
       ci := [its.title.what.ci, its.title.pos.ci];
       ok := its.gui2.fit.settitle (title, ci);

# Plot

       ok := its.gui2.fit.clearandresetplot();
       ok := its.gui2.fit.setplot(pos=its.position.pixel, ordinate=its.data.profile, 
                                  mask=its.data.mask,  ci=its.ci['Data'],  
                                  unit=its.image.bunit, which=1);
       its.gui2.fit.plot();    
#
       its.gui.enable();
       return T;
   }



###
   const its.openImage := function (ref opened, infile)
#
# Handles a string or image object
#
   {
      wider its;
      t := ref infile
      val opened := F;
      if (is_image(infile)) {
         val opened := F;
      } else if (is_string(infile)) {
         t := image(infile);
         if (is_fail(t)) fail;
         val opened := T;
      }
      return t;
   }


###
   const its.makeMoment := function ()
   {
      wider its;
#
      if (is_unset(its.infile2)) {

# Generate name of moment image

         inname := its.image.object.name(strippath=F);
         parentdir := dos.dirname(inname);
         if (is_fail(parentdir)) fail;
         root := spaste(parentdir, '/', 'imageprofilefitter_temp');
         its.momentimage.dir := defaultimagesupport.defaultname(root);
         if (is_fail(its.momentimage.dir)) fail;
#
         if (is_fail(dos.mkdir(its.momentimage.dir))) {
            msg := spaste('Could not create temporary directory ', its.momentimage.dir);
            return throw(msg, origin='imageprofilefitter.g');
         }
         filename := spaste(its.momentimage.dir, '/', 'momentimage');

# Find statistics

         note ('Generate image statistics', origin='imageprofilefitter.makeMoment',
               priority='NORMAL');
         local stats;
         ok := its.image.object.statistics(stats, list=F);
         if (is_fail(ok)) fail;

# Generate moment image

         moments := [-1];      # Average
         mask := unset;
         method := '';
         excludepix := [-3*stats.sigma, 3*stats.sigma];
#
         note ('Generate moment image', origin='imageprofilefitter.makeMoment',
               priority='NORMAL');
         ok := its.image.object.moments(moments=moments, axis=its.axis,
                                        mask=mask, method=method,
                                        excludepix=excludepix,
                                        doppler='radio', outfile=filename);
         if (is_fail(ok)) fail;
         its.momentimage.object := image(filename);
         if (is_fail(its.momentimage.object)) fail;
         its.momentimage.opened := T;
      } else {
         its.momentimage.object := 
            its.openImage(its.momentimage.opened, its.infile2);            
      }
#
      return T;
   }

###
   const its.makeTitle := function ()
   {
      wider its;
#
      title := ['Data '];
      ci := [1];
      j := 2;
      for (i in its.plotnames) {
         state := its.gui2.fit.getplotmenucheckstate ('Select', i);
         if (state) {
            title[j] := spaste (i, '');
            ci[j] := its.ci[i];
            j +:= 1;
         }
      }
#
      r := [=];
      r.text := title;
      r.ci := ci;
      return r;
   }

###
   const its.replot := function (value)
   {
      its.gui2.fit.clearplot();
      if (value==T) {

# Replot current profile types of interest if they are available

         which := its.which();
      } else {

# Replot data only

         which := [1]; 
      }

# Use xautoscale=F to honour any zooming user has done.

      return its.gui2.fit.plot(xautoscale=F, yautoscale=T, which=which);
   }

###
   const its.setimage := function (infile=unset, infile2=unset, sigma=unset)
   {
      wider its;

# Shut down old tools

      if (its.image.opened) {
         its.image.object.done();
      } 
      if (its.momentimage.opened) {
         its.momentimage.object.done();
      } 
      if (is_coordsys(its.image.csys)) its.image.csys.done();
#
# Open the image  and get coordinates
#
      if (!is_unset(infile)) {
         its.infile := infile;
         its.image.object := its.openImage(its.image.opened, its.infile);
         if (is_fail(its.image.object)) fail;
#
         its.image.csys := its.image.object.coordsys();
         if (is_fail(its.image.csys)) fail;
         its.image.bunit := its.image.object.brightnessunit();
         if (is_fail(its.image.bunit)) fail;
         if (length(its.image.bunit)==0) {  
            note ('No brightness units in image, assuming Jy',
                  origin='imageprofilefitter.g', priority='WARN');
            its.image.bunit := 'Jy';
         }

# Find spectral axis if profile axis not given

         if (is_unset(its.axis)) {
            local pa, wa;
            found := its.image.csys.findcoordinate(pa, wa, 'spectral');
           if (found) {
               its.axis := pa[1];
            } else {
               its.axis := min(3, length(its.image.shape()));
            }
            s := spaste ('Selecting axis ', its.axis, ' as the profile axis');
            note(s, origin='imageprofilefitter.g', priority='NORMAL');
         }

# Work out averaging axes for N-D image when extracting
# a profile.  It's the first two non-profile axes.  What
# if user wants other axes ????

         j := 1;
         for (i in 1:length(its.image.object.shape())) {
            if (i != its.axis) {
               its.axes[j] := i;
               j +:= 1;
            }
         }
      }

# Generate or open moment image

      its.infile2 := infile2;
      if (its.showimage) {
         ok := its.makeMoment();
         if (is_fail(ok)) fail;
      }
#
      its.sigma := sigma;
#
      return T;
   }


###
   its.which := function ()
#
# Find out which profiles we are interested in seeing
# The profiles may not yet have been actually created.
#
   {
      wider its;

# Data
      which := [1];                     

# Estimate

      if (its.gui2.fit.getplotmenucheckstate ('Select', its.plotnames[1])) {
         which := [which, 2];
      }

# Fit (all components together)

      if (its.gui2.fit.getplotmenucheckstate ('Select', its.plotnames[2])) {
         which := [which, 3];
      }

# Residual (all components together)

      if (its.gui2.fit.getplotmenucheckstate ('Select', its.plotnames[3])) { 
         which := [which, 4];
      }

# Fit (each component separately). We have one extra profile 
# per component if individual plots requested

      n := its.gui2.fit.ncomponents();
      if (its.gui2.fit.getplotmenucheckstate ('Select', its.plotnames[4])) { 
         which := [which, [5:(5+n-1)]];
      }
#
      return which;
   }



### Public functions

###
   const self.done := function ()
   {
      return its.done(T);
   }


###
   const self.getestimate := function ()
   {
      wider its;
      if (its.mode=='interactive') {
         return its.gui2.fit.getestimate();
      } else {
         note ('Estimates for region fitting not available',
               origin='imageprofilefitter.getestimate',
               priority='WARN');
         return [=];
      }
   }

###
   const self.getfit := function ()
   {  
      wider its;
#
      r := [=];
      if (its.mode=='interactive') {
         r.fit := its.gui2.fit.getfit();
         r.position := its.position;
      }
      return r;
   }

###
   const self.getprofiles := function (outfile=unset, ascii=F, format='%e', 
                                       dataonly=F, overwrite=T, ack=F)
   {
      wider its;
#
      n := length(its.data.profile);
      if (n == 0) {
         return throw ('Nothing to get', origin='imageprofilefitter.getprofiles');
      }  
#
      ok := n==length(its.estimate.profile) && n==length(its.fit.profile);
      if (!ok && !dataonly) {
         return throw ('Data and model/fit vectors not of same length',
                       origin='imageprofilesupport.getprofiles');
      }

# Get abcissa in current units of plot/fit (the same)

     abcRec := its.gui2.fit.getabcissa();
     if (is_fail(abcRec)) fail;
     q := dq.quantity(1.0, abcRec.unit);
     isVel := dq.compare('1km/s', q);
#
      if (is_unset(outfile)) {
         rec := [=];
         rec.abcissa := [=];
         rec.abcissa.pixel := abcRec.values.pixel.abs;
         rec.abcissa.values := abcRec.values.current;
         rec.abcissa.unit := abcRec.unit;
         rec.abcissa.doppler := abcRec.doppler;
#
         rec.data := [=];
         rec.data.values := its.data.profile;
         rec.data.unit := its.image.bunit;
#
         if (!dataonly) {
            rec.estimate := its.estimate.profile;
            rec.fit := its.fit.profile;
            rec.residual := rec.data.values - rec.fit;
         }
         rec.mask := its.data.mask; 
         return rec;
      } else {
         if (ascii) {
            if (dos.fileexists(outfile)) {
               if (overwrite) {
                  ok := dos.remove(outfile); 
                  if (is_fail(ok)) fail;
               } else {
                  return throw ('Output file exists, will not overwrite',
                                origin='imageprofilefitter.getprofiles');
               }
            }
#
            if (ack) {
               note (spaste('Writing ascii file ', outfile));
            }
            fileHandle := open(spaste('> ', as_string(outfile)));
#
            local str;
            if (isVel) {
               str := spaste (abcRec.unit, ' ', abcRec.doppler, ' ', 
                              its.image.bunit);
            } else {
               str := spaste (abcRec.unit, ' ', its.image.bunit);
            }
            write (fileHandle, str);
            if (dataonly) {
              write (fileHandle, 'Pixel        World      Data       Mask');
            } else {
              write (fileHandle, 'Pixel        World      Data       Estimate        Fit        Residual        Mask');
            }
            for (i in 1:n) { 
               if (dataonly) {
                  p := [abcRec.values.pixel.abs[i],
                        abcRec.values.current[i], 
                        its.data.profile[i]];
               } else {
                  p := [abcRec.values.pixel.abs[i],
                        abcRec.values.current[i],
                        its.data.profile[i], 
                        its.estimate.profile[i], 
                        its.fit.profile[i]];
                  p[6] := p[3]-p[5];
               }
               line := paste(sprintf(format, p), ' ');
               line := paste (line, as_integer(its.data.mask[i]));
               write (fileHandle, line);
            }
            fileHandle := F;
         } else {

# Create column descriptors

           include 'table.g';
           local td;
           if (dataonly) {
              names := "Pixel World Data Mask"
              c1 := tablecreatescalarcoldesc(names[1], 1.0);
              c2 := tablecreatescalarcoldesc(names[2], 1.0);
              c3 := tablecreatescalarcoldesc(names[3], 1.0);
              c4 := tablecreatescalarcoldesc(names[4], T);
#
              td := tablecreatedesc (c1, c2, c3, c4);
              if (is_fail(td)) fail;
           } else {
              names := "Pixel World Data Estimate Fit Residual Mask"
              c1 := tablecreatescalarcoldesc(names[1], 1.0);
              c2:= tablecreatescalarcoldesc(names[2], 1.0);
              c3 := tablecreatescalarcoldesc(names[3], 1.0);
              c4 := tablecreatescalarcoldesc(names[4], 1.0);
              c5 := tablecreatescalarcoldesc(names[5], 1.0);
              c6 := tablecreatescalarcoldesc(names[6], 1.0);
              c7 := tablecreatescalarcoldesc(names[7], T);
#
              td := tablecreatedesc (c1, c2, c3, c4, c5, c6, c7);
              if (is_fail(td)) fail;
           }
#
           if (dos.fileexists(outfile)) {
              if (overwrite) {
                 ok := dos.remove(outfile); 
                 if (is_fail(ok)) fail;
               } else {
                 return throw ('Output table exists, will not overwrite',
                                origin='imageprofilefitter.getprofiles');
              }
           }

# Create table

           if (ack) {
              note (spaste('Writing aips++ table ', outfile));
           }
           t := table (tablename=outfile, tabledesc=td, nrow=n, readonly=F, ack=F);
           if (is_fail(t)) fail;

# Write columns

           ok := t.putcol(names[1], abcRec.values.pixel.abs);
           if (is_fail(ok)) fail;
#
           ok := t.putcol(names[2], abcRec.values.current);
           if (is_fail(ok)) fail;
           ok := t.putcolkeyword(names[2], 'unit', abcRec.unit);
           if (is_fail(ok)) fail;
           if (isVel) {
              ok := t.putcolkeyword(names[2], 'doppler', abcRec.doppler);
              if (is_fail(ok)) fail;
           }
#
           ok := t.putcol(names[3], its.data.profile);
           if (is_fail(ok)) fail;
           ok := t.putcolkeyword(names[3], 'unit', its.image.bunit);
           if (is_fail(ok)) fail;
#
           if (dataonly) {
              ok := t.putcol(names[4], its.data.mask);
              if (is_fail(ok)) fail;
           } else {
              ok := t.putcol(names[4], its.estimate.profile);
              if (is_fail(ok)) fail;
              ok := t.putcolkeyword(names[4], 'unit', its.image.bunit);
              if (is_fail(ok)) fail;
#
              ok := t.putcol(names[5], its.fit.profile);
              if (is_fail(ok)) fail;
              ok := t.putcolkeyword(names[5], 'unit', its.image.bunit);
              if (is_fail(ok)) fail;
#
              ok := t.putcol(names[6], its.fit.profile-its.data.profile);
              if (is_fail(ok)) fail;
              ok := t.putcolkeyword(names[6], 'unit', its.image.bunit);
              if (is_fail(ok)) fail;
#
              ok := t.putcol(names[7], its.data.mask);
              if (is_fail(ok)) fail;
           }
#
           ok := t.done();                            
         }
      }
#
      return T;
   }
   

###
   const self.getstore := function ()
   {
      wider its;
      return its.store;
   }

###
   const self.gui := function() 
   {
      if (its.showimage) {
         if (has_field(its, 'gui')) {
            return its.gui.gui();
         } else {
            note ('No GUI is available in this mode', 
                 priority='WARN', origin='imageprofilefitter.g');
         }
      } else {
         return its.gui2.fit.gui();
      }
   }

###
   const self.setimage := function (infile=unset, infile2=unset, sigma=unset)
   {
      wider its;

# Install new images

      ok := its.setimage(infile, infile2, sigma);
      if (is_fail(ok)) fail;

# Set new image in primary GUI if using it

      if (its.showimage) {
         ok := its.gui.setimage (its.momentimage.object);
         if (is_fail(ok)) fail;
      }

# Set new coordinate system in secondary GUI

      ok := its.gui2.fit.setcoordsys(csys=its.image.csys, shp=its.image.object.shape());
      if (is_fail(ok)) fail;

# Now, if we are not using the primary GUI to trigger regions for profile
# drawing, we trigger the plotting here.    The profile is averaged over the entire image.
# Perhaps we could  also have a 'setregion' function and a 'fit' function to
# be called explicitly

      ok := its.getandplotprofile();
      if (is_fail(ok)) fail;
#
      return ok;
   }

###
   const self.type := function ()
   {
      return 'imageprofilefitter';
   }


### Constructor 

   if (!have_gui()) {
      return throw ('No display is currently available (is DISPLAY set ?)',
                     origin='imageprofilefitter.g');
   }

# Set image, csys, make moment image

   ok := its.setimage (infile, infile2, sigma);
   if (is_fail(ok)) fail;
#
   include 'ddlws.g'
   if (is_unset(widgetset)) widgetset := ddlws;

#
# Make secondary profile fitting GUI but don't map it in yet
#
   include 'profilefittergui.g'
   its.gui2.fit := profilefittergui (csys=its.image.csys, shp=its.image.object.shape(), 
                                     axis=its.axis, ncomp=1,  bunit=its.image.bunit,
                                     hasdone=F, hasdismiss=T, plotter=plotter,
                                     widgetset=widgetset);
   if (is_fail(its.gui2.fit)) fail;
#
# Create primary GUI to display 2D view of image.  Without the primary
# GUI, the setimage function is used to trigger a new spectrum plot.
#
#
   if (its.showimage) {
      include 'imageprofilefittergui.g'
      its.gui := imageprofilefittergui (parent, imageobject=its.momentimage.object,
                                        widgetset=widgetset);
      if (is_fail(its.gui)) fail;
      ok := its.gui.setcallbacks (callback1=its.handlePosition,
                                  callback2=its.handleRegion);
      if (is_fail(ok)) fail;
#
      whenever its.gui->done do {
         ok := its.done(F);
      }
      its.gui.disable();
   }
# 
# Add plot menu items.  Profilefittergui has no intelligence. you have to tell it everything.
#
   ok := its.gui2.fit.addplotmenucheckmenu ('Select',  its.plotnames, [T,T,T,F]);
   if (is_fail(ok)) fail;
   whenever its.gui2.fit->plotmenuselect do {
      its.title.what := its.makeTitle ();
      title := [its.title.what.text, its.title.pos.text];
      ci := [its.title.what.ci, its.title.pos.ci];
      its.gui2.fit.settitle (title, ci);
      its.replot(T);
   }
   if (its.showimage) its.gui.enable();
#
# If we are not using the primary GUI to trigger  profile extraction
# then we just make the profile averaged over the entire image
#
   if (!its.showimage) {
     ok := its.getandplotprofile();
     if (is_fail(ok)) fail;
   }

# Handle replot event

   whenever its.gui2.fit->replot do {
      if (!its.busy['replot']) {
         its.busy['replot'] := T;
         if (its.showimage) its.gui.disable();
         its.replot($value);
         if (its.showimage) its.gui.enable();
         its.busy['replot'] := F;
      }
   }

# Handle autoestimate event

   whenever its.gui2.fit->autoestimate do {
      if (!its.busy['estimate']) {
         if (its.showimage) its.gui.disable();
         its.busy['estimate'] := T;      
#
         estimate := its.image.object.fitprofile (its.estimate.profile, 
                                                  its.estimate.residual,
                                                  region=its.region.profile, 
                                                  fit=F, ngauss=$value.nmax,
                                                  axis=its.axis,
                                                  estimate=$value);
         if (is_fail(estimate)) {	
            note(estimate::message, priority='SEVERE',
                 origin='imageprofilefitter.g');  
         } else {
            its.gui2.fit.insertestimate(estimate);
#
            ok := its.gui2.fit.clearandresetplot();
            ok := its.gui2.fit.setplot(pos=its.position.pixel, ordinate=its.data.profile, 
                                       mask=its.data.mask, ci=its.ci['Data'], 
                                       unit=its.image.bunit, which=1);
#
            ok := its.gui2.fit.addplot (its.estimate.profile, ci=its.ci['Estimate'], which=2);
#
            which := [1];
            if (its.gui2.fit.getplotmenucheckstate ('Select', 'Estimate')) {
               which := [1,2];
            }
            ok := its.gui2.fit.plot(yautoscale=T, which=which);
#
            if (its.showimage) its.gui.enable();
            its.busy['estimate'] := F;
         }
      }
   }

# Handle evaluate event; generated by an interactive estimate
# We redraw all the plots as the interactive estimate will 
# draw some crosses and lines

   whenever its.gui2.fit->evaluate do {
      if (!its.busy['evaluate']) {
         its.busy['evaluate'] := T;
#
         ok := its.image.object.fitprofile (its.estimate.profile, 
                                            its.estimate.residual, 
                                            region=its.region.profile, 
                                            fit=F, axis=its.axis,
                                            estimate=$value);
#
         its.gui2.fit.clearandresetplot();
         its.gui2.fit.setplot(pos=its.position.pixel, ordinate=its.data.profile, 
                              mask=its.data.mask, ci=its.ci['Data'], 
                              unit=its.image.bunit, which=1);
         its.gui2.fit.addplot(its.estimate.profile, ci=its.ci['Estimate'], which=2);
#
         which := [1];
         if (its.gui2.fit.getplotmenucheckstate ('Select', 'Estimate')) {
            which := [1,2];
         }
         its.gui2.fit.plot(yautoscale=T, which=which)
#
         its.busy['evaluate'] := F;
      }
   }

# Handle fit event

   whenever its.gui2.fit->fit do {
      estimate := $value;
      if (!its.busy['fit']) {
         if (its.showimage) its.gui.disable();
         its.busy['fit'] := T;
#
         if (its.mode=='interactive') {

# See if estimate has been filled in.  If not, go get one and insert it

            if (!has_field(estimate, 'elements')) {
               nmax := estimate.nmax;
               newEstimate := its.image.object.fitprofile (values=its.estimate.profile, 
                                                           resid=its.estimate.residual,
                                                           region=its.region.profile, 
                                                           fit=F, ngauss=estimate.nmax,
                                                           axis=its.axis,
                                                           estimate=estimate);
               its.gui2.fit.insertestimate(newEstimate);
               estimate := its.gui2.fit.getestimate();
#
               its.gui2.fit.clearandresetplot();
               its.gui2.fit.clearplot();
               ok := its.gui2.fit.setplot(pos=its.position.pixel, ordinate=its.data.profile, 
                                          mask=its.data.mask, ci=its.ci['Data'], 
                                          unit=its.image.bunit, which=1);
#
               ok := its.gui2.fit.addplot (its.estimate.profile, ci=its.ci['Estimate'],
                                           which=2);
            }

# Now do fit

            fit := its.image.object.fitprofile (values=its.fit.profile, 
                                                resid=its.fit.residual,
                                                region=its.region.profile, 
                                                fit=T, axis=its.axis,
                                                poly=estimate.baseline, 
                                                estimate=estimate, sigma=its.sigma);
            if (!is_fail(fit) && length(fit) > 0) {
               fit2 := its.gui2.fit.insertfit(fit);
               if (!is_fail(fit2)) {
                  ok := its.gui2.fit.addplot(ordinate=its.fit.profile, 
                                             ci=its.ci[its.plotnames[2]], which=3);
                  ok := its.gui2.fit.addplot(ordinate=its.fit.residual, 
                                             ci=its.ci[its.plotnames[3]], which=4);
               } else {
                  note (fit2::message, priority='SEVERE', origin='imagefitterprofile.g');
               }

# Generate individual components as well (perhaps this should be done
# on demand only, whereupon we will need to store the separate profiles)

#              if (its.gui2.fit.getplotmenucheckstate ('Select', its.plotnames[4])) {
                  n := its.gui2.fit.ncomponents();
                  local profile, residual;  
                  for (i in 1:n) {
                     ok := its.evaluateOneComponent (profile, residual, fit, i)
                     ok := its.gui2.fit.addplot(ordinate=profile, which=4+i,
                                                ci=its.ci[its.plotnames[4]]);
                  }
#               }
#
               ok := its.gui2.fit.plot(which=its.which(), yautoscale=T);
               ok := its.gui2.fit.markmodel (fit2, its.ci[its.plotnames[2]])
            } else {
               if (is_fail(fit)) {
                  note (fit::message, priority='SEVERE', origin='imagefitterprofile.g');
               }
#
               ok := its.gui2.fit.plot(which=its.which(), yautoscale=T);
            }
         } else {

# Make up names for fit and residual images

             fname := spaste(its.image.object.name(F), '.fit');
             rname := spaste(its.image.object.name(F), '.resid');
             local p, r;

# Fit all profiles in region

             ok := its.image.object.fitallprofiles (region=its.region.region, 
                                                    ngauss=its.gui2.fit.ncomponents(),
                                                    axis=its.axis, sigma=its.sigma,
                                                    fit=fname, resid=rname);
             if (is_fail(ok)) {
                note (ok::message, origin='imageprofilefitter.g', priority='SEVERE');
             } else {
                note ('Fitting finished', priority='NORMAL', origin='imageprofilefitter.g');
             }
         }
#
         if (its.showimage) its.gui.enable();
         its.busy['fit'] := F;
      }
   }

# Handle clipboard event

   whenever its.gui2.fit->clipboard do {
      if (!its.busy['clipboard']) {
         its.busy['clipboard'] := T;
         if (its.showimage) its.gui.disable();
#
         if (its.mode=='interactive') {
            r := [=];
            r.estimate := its.gui2.fit.getestimate();
            r.fit := its.gui2.fit.getfit();
            r.position := its.position;
            dcb.copy(r);
         }
#
         its.busy['clipboard'] := F;
         if (its.showimage) its.gui.enable();
      }
   }

# Handle add event

   whenever its.gui2.fit->add do {
      if (!its.busy['add']) {
         its.busy['add'] := T;
         if (its.showimage) its.gui.disable();
#
         if (its.mode=='interactive') {
            r := [=];
            r.estimate := its.gui2.fit.getestimate();
            r.fit := its.gui2.fit.getfit();
            r.position := its.position;
#
            idx := length(its.store) + 1;
            its.store[idx] := r; 
         } else {
            note ('Add not possible for multi-profile fit mode', priority='WARN',
                  origin='imageprofilefitter.g');
         }
#
         its.busy['add'] := F;
         if (its.showimage) its.gui.enable();
      }
   }

# Handle saveplot event

   whenever its.gui2.fit->saveplot do {
      ok := self.getprofiles(outfile=$value.filename, ascii=$value.ascii, 
                             overwrite=$value.overwrite, dataonly=$value.dataonly,
                             ack=T)
      if (is_fail(ok)) {
         note (ok::message);
      }
   }
#
   whenever system->exit do {
      self.done();
   }
   its.whenevers['exit'] := last_whenever_executed();
} 
