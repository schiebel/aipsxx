# calmap: synthesis integration one level higher than imager and calibrater
# Copyright (C) 1999,2000,2001,2002
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: calmap.g,v 19.1 2004/08/25 01:23:21 cvsmgr Exp $

# include guard
pragma include once
 
# Include files

include 'imager.g';
include 'calibrater.g';
include 'image.g';
include 'note.g';
include 'plugins.g';
include 'unset.g';
include 'misc.g';
include 'os.g';
include 'quanta.g';
#
# Define a calmap instance
#
const _define_calmap := function(msfile) {
#
   private := [=]
   public := [=]
#
#------------------------------------------------------------------------
# Private data and functions
#------------------------------------------------------------------------
#
   # Initialize private calibrater, imager and image tools
   private.calibrater := calibrater(msfile);

   private.imager := imager(msfile);
   ok := private.imager.setimage();
   if (is_fail(ok)) return throw (ok::message);
   ok := private.imager.weight();
   if (is_fail(ok)) return throw (ok::message);
#   ok := private.imager.advise(takeadvice=T);
#   if (is_fail(ok)) return throw (ok::message);

   private.image := F;

   # Initialize private data
   private.msfile := msfile;
   private.model := F;
   private.mask := F;
   private.restored := F;
   private.residual := F;

   const private.getid := function (fieldname) 
   {
   # Obtain the field_id for a given field name
   #
      wider private;

      msname := private.msfile;
      t:= table(spaste(msname,'/FIELD'), ack=F);
      names:= t.getcol('NAME');
      n:= len(names);
      fieldmatch := dms.stripleadingblanks(fieldname);
      if (strlen(fieldmatch) > 0) {
         fieldids:= seq(1:n)[names == fieldmatch];
         nfldid:= len(fieldids);
         if (nfldid == 0) {
            t.close();
            note(paste('Field: ', fieldname, ' not found'));
            return F;
         };
         if (nfldid > 1) {
            t.close();
            note(paste('More than one field named: ', fieldname));
            return F;
         };
         t.close();
         return fieldids[1];
       } else {
         return F;
       };
   };

   const private.calsetdata := function (selection=unset)
   {
   # Run the calibrater.setdata() function
   #
      wider private, public;

      # Set up the calibrater.setdata parameters
      mode := 'channel';
      nchan := 1;
      start := 1;
      step := 1;
      mstart := '0km/s';
      mstep := '0km/s';
      msselect := '';

      if (!is_unset(selection)) {
         # Process the frequency selection information
         freqsel := selection.get('freqsel');
         if (!is_unset(freqsel)) {
            mode := freqsel.get('name');
            if (mode=='' || mode=='CHANNEL') {
               nchan := freqsel.get('nchan');
               start := freqsel.get('start');
               step := freqsel.get('step');
            } else if (mode == 'VELOCITY') {
               nchan := freqsel.get('nchan');
               mstart := freqsel.get('mstart');
               mstep := freqsel.get('mstep');
            };
         };
         # Process the broader MS selection parameters
         uvrange := selection.get('uvrange');
         msselect := selection.get('msselect');

         # Append fieldname and spwid selection to msselect
         msselect := dms.stripleadingblanks(msselect);
         if (strlen(msselect) > 0) msselect := spaste('(', msselect, ')');

         fieldnames := selection.get('fieldnames');
         spwids := selection.get('spwids');

         if (length(fieldnames) > 0) {
            for (i in 1:length(fieldnames)) {
               fldstrip := dms.stripleadingblanks(fieldnames[i]);
               fldstrip := dms.striptrailingblanks(fldstrip);
               id := private.getid(fldstrip);
               if (id != F) {
                  if (strlen(msselect) > 0) msselect :=spaste(msselect, ' &&');
                  msselect := spaste(msselect, ' (FIELD_ID==',id,')');
               };
            };
         };
         if (length(spwids) > 0) {
            for (i in 1:length(spwids)) {
               if (strlen(msselect) > 0) msselect :=spaste(msselect, ' &&');
               msselect := spaste(msselect, ' && (SPECTRAL_WINDOW_ID==',
                  spwids[i], ')');
            };
         };


         # Execute calibrater.setdata()
         ok:= private.calibrater.setdata(mode=mode, nchan=nchan, start=start, 
                 step=step, mstart=mstart, mstep=mstep, uvrange=uvrange,
                 msselect=msselect);
         if (is_fail(ok)) return throw (ok::message);

      };
      return T;
   };

   const private.setapply := function(calibrationlist=unset, 
                                      ref someapplied)
   {
   # Run the calibrater.setapply() function for all specified 
   # uv-plane calibration components
   #
      wider private, public;

      val someapplied := F;
      if (!is_unset(calibrationlist)) {
         types := calibrationlist.get('types');
         calibrations := calibrationlist.get('calibrations');
         n := length(types);
         for (i in 1:n) {
            type := dms.stripleadingblanks(types[i]);
	    # Exclude image-plane calibration components
            if (!is_unset(calibrations[i]) && strlen(type)>0 && type != 'VP') {
               t := calibrations[i].get('t');
               tablename := calibrations[i].get('table');
               select := calibrations[i].get('select');
               private.calibrater.setapply(type=type, t=t, table=tablename, 
                  select=select);
               val someapplied := T;
            };
         };
      };
      return T;
   };

   const private.setvp := function(calibrationlist=unset)
   {
   # Set image-plane calibration components (only voltage pattern
   # supported at present).
   #
      wider private;

      if (!is_unset(calibrationlist)) {
         # Look for VP (voltage pattern) calibration component
         types := calibrationlist.get('types');
         ntypes := length(types);
         calibrations := calibrationlist.get('calibrations');
         found := F;
         for (i in 1:ntypes) {
            type := types[i];
            cal := calibrations[i];
            if (!is_unset(cal) && strlen(type) > 0) {
               itemtype := cal.get('name');
               # Check for image-plane components (only VP at present)
               if (type == 'VP' && itemtype == 'VP' && !found) {
                  # Extract the imager.setvp() parameters
                  found := T;
                  usedefaultvp := cal.get('usedefaultvp');
                  vptable := cal.get('vptable');
                  dosquint := cal.get('dosquint');
                  parangleinc := cal.get('parangleinc');

                  # Run the imager.setvp() function
                  ok := private.imager.setvp(dovp=T, usedefaultvp=usedefaultvp,
                     vptable=vptable, dosquint=dosquint, 
                     parangleinc=parangleinc);
                  if (is_fail(ok)) return throw (ok::message);
               };
            };
         };
      };
      return T;
   };

   const private.predictmodel := function(modellist=unset)
   {
   # Predict a list of models to fill the MODEL_DATA column
   #
      wider private;

      # Set the default model visibility for all fields in the MS
      private.imager.setjy();

      # Predict the model visibility for all specified sources
      if (!is_unset(modellist)) {
         nmodel := length(modellist.get('models'));
         if (nmodel > 0) {
            sources := modellist.get('sources');
            models := modellist.get('models');
            for (i in 1:nmodel) {
               source := dms.stripleadingblanks(sources[i]);
               source := dms.striptrailingblanks(source);
               id := private.getid(source);

               if (!is_unset(models[i]) && id != F) {
                  type := models[i].get('name');
                  # Case model_type of:
                  #
                  # IMAGE:
                  if (type == 'IMAGE') {
                     images := models[i].get('images');
                     complist := models[i].get('complist');
                     # Transform the images and component list
                     private.imager.setdata(mode='channel', nchan=0, start=1,
                        step=1, fieldid=[id], async=F);
                     private.imager.ft(model=images, complist=complist,
                        incremental=F, async=F);
                  #
                  # FLUXDENSITY
                  } else if (type == 'FLUXDENSITY') {
                     iquv := models[i].get('iquv');
                     private.imager.setjy(fieldid=[id], fluxdensity=iquv);
                  #
                  # CATALOG
                  } else if (type == 'CATALOG') {
                     catalogname := models[i].get('catalogname');
                     if (catalogname != 'Perley-Taylor 95') {
                        note('Only Perley-Tayor 95 supported at present',
                           priority='WARN', origin='calmap.predictmodel');
                     };
                     private.imager.setjy(fieldid=[id]);
                  };
               };
            };
         };
      };
      return T;
   };

   const private.setsolve := function(solverlist=unset, ref somesolved)
   {
   # Run the calibrater.setsolve() function for all specified solvers
   #
      wider private;

      val somesolved := F;
      if (!is_unset(solverlist)) {
         types := solverlist.get('types');
         solvers := solverlist.get('solvers');
         n := length(types);
         for (i in 1:n) {
            type := dms.stripleadingblanks(types[i]);
            type := dms.striptrailingblanks(type);
            if (!is_unset(solvers[i]) && strlen(type) > 0) {
               t := solvers[i].get('t');
               phaseonly := solvers[i].get('phaseonly');
               tablename := solvers[i].get('table');
               append := solvers[i].get('append');
               private.calibrater.setsolve(type=type, t=t, phaseonly=phaseonly,
                  table=tablename, append=append);
               val somesolved := T;
            };
         };
      };
      return T;
   };

   const private.imgrsetdata := function (selection=unset)
   {
   # Run the imager.setdata() function
   #
      wider private, public;

      if (!is_unset(selection)) {
         # Process the frequency selection information
         freqsel := selection.get('freqsel');

         # Set default frequency selection parameters
         mode := 'channel';
         nchan := 0;
         start := 1;
         step := 1;
         mstart := '0km/s';
         mstep := '0km/s';

         if (!is_unset(freqsel)) {
            mode := freqsel.get('name');
            if (mode=='' || mode=='CHANNEL') {
               nchan := freqsel.get('nchan');
               start := freqsel.get('start');
               step := freqsel.get('step');
            } else if (mode == 'VELOCITY') {
               nchan := freqsel.get('nchan');
               mstart := freqsel.get('mstart');
               mstep := freqsel.get('mstep');
            };
         };
         # Process the broader MS selection parameters
         msselect := selection.get('msselect');
         spwids := selection.get('spwids');

         # Process field name selections
         fieldnames := selection.get('fieldnames');
         fieldids := [];

         if (length(fieldnames) > 0) {
            jfield := 1;
            for (i in 1:length(fieldnames)) {
               fldstrip := dms.stripleadingblanks(fieldnames[i]);
               fldstrip := dms.striptrailingblanks(fldstrip);
               id := private.getid(fldstrip);
               if (id != F) {
                  fieldids[jfield] := id;
                  jfield := jfield + 1;
               };
            };
         };

         # Execute imager.setdata()
         ok := private.imager.setdata(mode=mode, nchan=nchan, start=start, 
            step=step, mstart=mstart, mstep=mstep, spwid=spwids, 
            fieldid=fieldids, msselect=msselect, async=F);
         if (is_fail(ok)) return throw (ok::message);
         
      };
      return T;
   };

   const private.validstring := function (inputstring) 
   {
   # Pre-process input strings to ensure validity
   #
      outputstring := inputstring;
      # Guard against "" or " "
      if (shape(outputstring) == 0) {
         outputstring:= ' ';
      } else {
         # Convert Glish string arrays 
         outputstring := paste (outputstring);
         # Strip spurious matching start and end quotes 
         outputstring := outputstring ~ s/^'(.*)'$/$1/;
         outputstring := outputstring ~ s/^"(.*)"$/$1/;
      };
      return outputstring;
   };

   const private.setupimagingfields := function(imagingfieldlist=unset,
                                                ref location, ref model,
                                                ref mask, ref fixed, 
                                                ref fluxscale, ref prior, 
                                                ref datamask, ref fluxmask, 
                                                ref restored, ref residual,
                                                ref nvalid)
   {
   # Set up the imaging fields, and return relevant, extracted
   # imaging field parameters.
   #
      wider private;

      # Initialization
      val nvalid := 0;
      val location := F; 
      val model := ['']; 
      jmodel := 1;
      val mask := [''];
      val fixed := [F];
      val fluxscale := [''];
      val prior := [''];
      val datamask := [''];
      val fluxmask := [''];
      val restored := [''];
      val residual := [''];

      if (!is_unset(imagingfieldlist)) {
         models := imagingfieldlist.get('models');
         imflds := imagingfieldlist.get('imagingfields');
         nmodels := length(models);
         found := F;
 
         # Loop over model entries
         for (i in 1:nmodels) {
            # Check for non-null model name
            modl := private.validstring(models[i]);
            modl := dms.stripleadingblanks(modl);
            modl := dms.striptrailingblanks(modl);
            if (strlen(modl) > 0) {
               # Add to list of model entries
               val model[jmodel] := modl;
   
               # Initialize related parameters for this model entry
               val mask[jmodel] := '';
               val fixed[jmodel] := F;
               val fluxscale[jmodel] := '';
               val prior[jmodel] := '';
               val datamask[jmodel] := '';
               val fluxmask[jmodel] := '';
               val restored[jmodel] := spaste(modl, '.restored');
               val residual[jmodel] := spaste(modl, '.residual');
               jmodel := jmodel + 1;

               # Extract imaging field parameters for this entry
               imfld := imflds[i];

               if (!is_unset(imfld)) {
                  
                  # Extract mask parameters and create the associated
                  # masks if necessary
                  msk := imfld.get('mask');
                  if (!is_unset(msk)) {
                     masktype := msk.get('name');
                     maskname := spaste(modl, '.mask');
                     mask[jmodel] := maskname;
                     # Case mask_type of:
                     #
                     # MASK:
                     if (masktype == 'MASK') {
                        mask[jmodel] := msk.get('mask');
                     #
                     # BOXMASK:
                     } else if (masktype == 'BOXMASK') {
                        blc := msk.get('blc');
                        trc := msk.get('trc');
                        value := msk.get('value');
                        # Create mask
                        ok := private.imager.boxmask(mask=maskname, blc=blc, 
                           trc=trc, value=value, async=F);
                        if (is_fail(ok)) return throw (ok::message);
                     #
                     # THRESHOLDMASK:
                     } else if (masktype == 'THRESHOLDMASK') {
                        image := msk.get('image');
                        threshold := msk.get('threshold');
                        # Create mask
                        ok := private.imager.mask(image=image, mask=maskname,
                           threshold=threshold, async=F);
                        if (is_fail(ok)) return throw (ok::message);
                     #
                     # REGIONMASK:
                     } else if (masktype == 'REGIONMASK') {
                        region := msk.get('region');
                        value := msk.get('value');
                        # Create mask
                        ok := private.imager.regionmask(mask=maskname, 
                           region=region, value=value);
                        if (is_fail(ok)) return throw (ok::message);
                     #
                     # EXPRMASK:
                     } else if (masktype == 'EXPRMASK') {
                        expr := msk.get('expr');
                        # Create mask
                        ok := private.imager.exprmask(expr=expr);
                        if (is_fail(ok)) return throw (ok::message);
                     };
                  } else {
                    # is_unset(msk); no mask specified
                  };

                  # Set the imaging coordinates for this imaging field
                  imcoord := imfld.get('imagingcoord');
                  if (!is_unset(imcoord)) {
                     # Extract first non-null location found
                     loc := imcoord.get('location');
                     if (!is_boolean(loc) && !found) {
                        val location := loc;
                        found := T;
                     };

                     # Extract setimage() parameters
                     nx := imcoord.get('nx');
                     ny := imcoord.get('ny');
                     cellx := imcoord.get('cellx');
                     celly := imcoord.get('celly');
                     stokes := imcoord.get('stokes');
                     doshift := imcoord.get('doshift');
                     phasecenter := imcoord.get('phasecenter');
                     shiftx := imcoord.get('shiftx');
                     shifty := imcoord.get('shifty');
                     mode := imcoord.get('mode');
                     # Initialize frequency information
                     nchan := 0;
                     start := 1;
                     step := 1;
                     mstart := '0km/s';
                     mstep := '0km/s';
                     freqsel := imcoord.get('freqsel');
                     if (!is_unset(freqsel)) {
                        ftype := freqsel.get('name');
                        nchan := freqsel.get('nchan');
                        # Case frequency_type of:
                        #
                        # CHANNEL:
                        if (ftype == 'CHANNEL') {
                           start := freqsel.get('start');
                           step := freqsel.get('step');
                        #
                        # VELOCITY:
                        } else if (ftype == 'VELOCITY') {
                           mstart := freqsel.get('mstart');
                           mstep := freqsel.get('mstep');
                        };
                     };
                     spwid := imcoord.get('spwid');
                     fieldid := imcoord.get('fieldid');
                     facets := imcoord.get('facets');

                     # Run imager.setimage()
                     ok := private.imager.setimage(nx=nx, ny=ny, cellx=cellx,
                        celly=celly, stokes=stokes, doshift=doshift,
                        phasecenter=phasecenter, shiftx=shiftx, shifty=shifty,
                        mode=mode, nchan=nchan, start=start, step=step,
                        mstart=mstart, mstep=mstep, spwid=spwid, 
                        fieldid=fieldid, facets=facets);
                     if (is_fail(ok)) return throw (ok::message);

                  } else {
                     # is_unset(imcoord); run default setimage()
                     ok := private.imager.setimage();
                     if (is_fail(ok)) return throw (ok::message);
                  };

               } else {
                 # is_unset(imfld); run default setimage()
                 ok := private.imager.setimage();
                 if (is_fail(ok)) return throw (ok::message);
               };

               # Create this model image if it does not already exist
               val nvalid := nvalid + 1;
               if (!dos.fileexists(modl)) {
                  ok := private.imager.make(image=modl, async=F);
                  if (is_fail(ok)) return throw (ok::message);
               };

            }; # if (strlen(modl) > 0)
         }; # for (i in 1:nmodels)
         
      } else { 
         # unset_imagingfieldlist
      };

   return T;
   };

   const private.setoptions := function(ftmachine=unset, location=F)
   {
   # Set up the FT and gridding machine
   #
      wider private;

      if (!is_unset(ftmachine)) {
         cache := ftmachine.get('cache');
         tile := ftmachine.get('tile');
         gridfunction := ftmachine.get('gridfunction');
         padding := ftmachine.get('padding');
   
         # Run the imager.setoptions() function
         ok := private.imager.setoptions(ftmachine='gridft', cache=cache, 
            tile=tile, gridfunction=gridfunction, location=location, 
            padding=padding);
         if (is_fail(ok)) return throw (ok::message);
      };
      return T;
   };

   const private.uvweight := function(weighting)
   {
   # Set the gridding weighting
   #
      wider private;
    
      if (!is_unset(weighting)) {
         wtype := weighting.get('name');
         # Case weighting_type of:
         #
         # NATURAL:
         if (wtype == 'NATURAL') {

            # Run the imager.weight() function
            ok := private.imager.weight(type='natural', async=F);
            if (is_fail(ok)) return throw (ok::message);
         #
         # UNIFORM:
         } else if (wtype == 'UNIFORM') {
            fieldofview := weighting.get('fieldofview');
            npixels := weighting.get('npixels');

            # Run the imager.weight() function
            ok := private.imager.weight(type='uniform', 
               fieldofview=fieldofview, npixels=npixels, async=F);
            if (is_fail(ok)) return throw (ok::message);
         #
         # BRIGGS:
         } else if (wtype == 'BRIGGS') {
            rmode := weighting.get('rmode');
            noise := weighting.get('noise');
            robust := weighting.get('robust');
            fieldofview := weighting.get('fieldofview');
            npixels := weighting.get('npixels');
    
            # Run the imager.weight() function
            ok := private.imager.weight(type='briggs', rmode=rmode, 
               noise=noise, robust=robust, fieldofview=fieldofview, 
               npixels=npixels, async=F);
            if (is_fail(ok)) return throw (ok::message);
         #
         # RADIAL:
         } else if (wtype == 'RADIAL') {
            
            # Run the imager.weight() function
            ok := private.imager.weight(type='radial', async=F);
            if (is_fail(ok)) return throw (ok::message);
         };

         # Extract uvrange and filtering parameters
         uvmin := weighting.get('uvmin');
         uvmax := weighting.get('uvmax');
         bmaj := weighting.get('bmaj');
         bmin := weighting.get('bmin');
         bpa := weighting.get('bpa');

         # Filter weights if requested
         qbmaj := dq.quantity(bmaj);
         qbmin := dq.quantity(bmin);
         if (qbmaj.value * qbmin.value > 0) {
            # Run the imager.filter() function
            ok := private.imager.filter(type='gaussian', bmaj=bmaj, bmin=bmin,
               bpa=bpa, async=F);
            if (is_fail(ok)) return throw (ok::message);
         };

         # Set imaging weight uv-range
         if (uvmin > 0 && uvmax > 0) {
            # Run the imager.uvrange() function
            ok := private.imager.uvrange(uvmin=uvmin, uvmax=uvmax, async=F);
            if (is_fail(ok)) return throw (ok::message);
         };
                            
      } else {
         # is_unset(weighting)
      };
      return T;
   };

   const private.setbeam := function(restoringbeam=unset)
   {
   # Set the restoring beam
   #
      wider private;

      if (!is_unset(restoringbeam)) {
         type := restoringbeam.get('name');
         # Case beam_type of:
         #
         # GAUSSIAN:
         if (type == 'GAUSSIAN') {
            bmaj := restoringbeam.get('bmaj');
            bmin := restoringbeam.get('bmin');
            bpa := restoringbeam.get('bpa');

            # Run the imager.setbeam() function
            ok := private.imager.setbeam(bmaj=bmaj, bmin=bmin, bpa=bpa);
            if (is_fail(ok)) return throw (ok::message);
         #
         # FITPSF:
         } else if (type == 'FITPSF') {
            psf := restoringbeam.get('psf');

            # Fit the restoring beam from the specified PSF image
            ok := private.imager.fitpsf(psf=psf, bmaj, bmin, bpa, async=F);
            if (is_fail(ok)) return throw (ok::message);

            # Set it as the restoring beam
            ok := private.imager.setbeam(bmaj=bmaj, bmin=bmin, bpa=bpa);
            if (is_fail(ok)) return throw (ok::message);
         };

      } else {
         # is_unset(restoringbeam)
      };
      return T;
   };

   const private.deconvolve := function(deconvolver=unset, model='', 
                                        complist='', mask='', fixed=F,
                                        fluxscale='', prior='', datamask='',
                                        fluxmask='', residual='', ref workdone)
   {
   # Image and deconvolve (image solve)
   #
      wider private;
   
      val workdone := F;

      if (!is_unset(deconvolver)) {
         # Extract deconvolver type and common parameters
         type := deconvolver.get('name');
         algorithm := deconvolver.get('algorithm');
         niter := deconvolver.get('niter');

         # Check if multi-field
         if ((algorithm ~ m/^mf/g) > 0) {
            # Set multi-field parameters
            cyclefactor := deconvolver.get('cyclefactor');
            cyclespeedup := deconvolver.get('cyclespeedup');
            stoplargenegatives := deconvolver.get('stoplargenegatives');
            stoppointmode := deconvolver.get('stoppointmode');
     
            # Run the imager.setmfcontrol() function
            ok := private.imager.setmfcontrol(cyclefactor=cyclefactor,
               cyclespeedup=cyclespeedup, 
               stoplargenegatives=stoplargenegatives,
               stoppointmode=stoppointmode, fluxscale=fluxscale, async=F);
            if (is_fail(ok)) return throw (ok::message);
         };

         # Check if multi-scale
         if ((algorithm ~ m/multiscale/g) > 0) {
            # Set the multi-scale parameters
            scalemethod := deconvolver.get('scalemethod');
            nscales := deconvolver.get('nscales');
            uservector := deconvolver.get('uservector');

            # Run the imager.setscales() function
            ok := private.imager.setscales(scalemethod=scalemethod, 
               nscales=nscales, uservector=uservector, async=F);
            if (is_fail(ok)) return throw (ok::message);
         };

         # Case deconvolver_type of:
         #
         # CLEAN
         if (type == 'CLEAN') {
            gain := deconvolver.get('gain');
            threshold := deconvolver.get('threshold');
            displayprogress := deconvolver.get('displayprogress');

            # Run the imager.clean() function
            ok := private.imager.clean(algorithm=algorithm, niter=niter, 
               gain=gain, threshold=threshold, displayprogress=displayprogress,
               model=model, fixed=fixed, complist=complist, mask=mask,
               image='', residual=residual, async=F);
            if (is_fail(ok)) return throw (ok::message);
            val workdone := T;
         #
         # MEM:
         } else if (type == 'MEM') {
            sigma := deconvolver.get('sigma');
            targetflux := deconvolver.get('targetflux');
            constrainflux := deconvolver.get('constrainflux');
            displayprogress := deconvolver.get('displayprogress');
            
            # Run the imager.mem() function
            ok := private.imager.mem(algorithm=algorithm, niter=niter, 
               sigma=sigma, targetflux=targetflux, constrainflux=constrainflux,
               displayprogress=displayprogress, model=model, fixed=fixed,
               complist=complist, prior=prior, mask=mask, image='',
               residual=residual, async=F);
            if (is_fail(ok)) return throw (ok::message);
            val workdone := T;
         #
         # NNLS:
         } else if (type == 'NNLS') {
            tolerance := deconvolver.get('tolerance');

            # Run the imager.nnls() function
            ok := private.imager.nnls(algorithm=algorithm, niter=niter,
               tolerance=tolerance, model=model, fixed=fixed, 
               complist=complist, fluxmask=fluxmask, datamask=datamask,
               image='', residual=residual, async=F);
            if (is_fail(ok)) return throw (ok::message);
            val workdone := T;
         };
         
      } else {
         # is_unset(deconvolver)
      };
      return T
   };

   const private.restore := function(model='', complist='', residual='',
                                     restored='')
   {
   # Produce the final restored images
   #
      wider private;

      if (length(model) > 0) {
         # Run the imager.restore() function
         private.imager.restore(model=model, complist=complist, image=restored,
            residual=residual);
      };
      return T;
   };
   
#
#------------------------------------------------------------------------
# Public functions
#------------------------------------------------------------------------
#
   const public.solvecal := function(sourcemodels=unset, selection=unset,
                                     calibration=unset, solvers=unset)
   {
   # Solve for calibration components
   #
      wider private;

      # Predict the model
      private.predictmodel(sourcemodels);

      # Select the data to be calibrated
      private.calsetdata(selection);

      # Set the fixed calibration components
      private.setapply(calibration, someapplied);

      # Set the calibration components to be solved
      private.setsolve(solvers, somesolved);
      
      # Solve 
      if (somesolved) {
         private.calibrater.solve();
      };      

      return T;
   };

   const public.applycal := function(selection=unset, calibration=unset)
   {
   # Apply calibration components
   #
      wider private;

      # Select the data to be calibrated
      private.calsetdata(selection);
 
      # Set calibration application parameters
      private.setapply(calibration, someapplied);
 
      # Correct the data
      if (someapplied) {
         private.calibrater.correct();
      };

      return T;
   };

   const public.makemap := function(selection=unset, calibration=unset,
                                    ftmachine=unset, imagingfields=unset,
                                    complist='', weighting=unset, 
                                    deconvolver=unset, restoringbeam=unset)
   {
   # Apply calibration and make an image
   #
      wider public, private;

      # Apply the uv-plane calibration
      ok := public.applycal(selection, calibration);
      if (is_fail(ok)) return throw (ok::message);

      # Re-select for imaging
      ok := private.imgrsetdata(selection);
      if (is_fail(ok)) return throw (ok::message);

      # Set up the imaging fields
      ok := private.setupimagingfields(imagingfields, location, model, mask, 
         fixed, fluxscale, prior, datamask, fluxmask, restored, residual,
         nvalid);
      if (is_fail(ok)) return throw (ok::message);
      if (nvalid <= 0) return F;

      # Save the valid model entry image names to private data
      private.model := model;
      private.mask := mask;
      private.restored := restored;
      private.residual := residual;

      # Set up the FT and gridding machine
      ok := private.setoptions(ftmachine, location);
      if (is_fail(ok)) return throw (ok::message);

      # Set the gridding weighting
      ok := private.uvweight(weighting);
      if (is_fail(ok)) return throw (ok::message);

      # Set the restoring beam
      ok := private.setbeam(restoringbeam);
      if (is_fail(ok)) return throw (ok::message);

      # Set image-plane calibration components (only VP at present)
      ok := private.setvp(calibration);
      if (is_fail(ok)) return throw (ok::message);

      # Deconvolve (image solve)
      ok := private.deconvolve(deconvolver, model, complist, mask, fixed, 
         fluxscale, prior, datamask, fluxmask, residual, deconvdone);
      if (is_fail(ok)) return throw (ok::message);

      # Restore the final images
      if (deconvdone) {
         ok := private.restore(model, complist, residual, restored);
         if (is_fail(ok)) return throw (ok::message);
      };

      return T;
   };

   const public.summary := function(...)
   {
   # Contained method: imager.summary(...)
   #
      wider private;

      # Run the imager.summary() function
      ok := private.imager.summary(...);
      if (is_fail(ok)) return throw (ok::message);

      return T;
   };

   const public.plotuv := function(...)
   {
   # Contained method: imager.plotuv(...)
   #
      wider private;

      # Run the imager.plotuv() function
      ok := private.imager.plotuv(...);
      if (is_fail(ok)) return throw (ok::message);

      return T;
   };

   const public.plotvis := function(...)
   {
   # Contained method: imager.plotvis(...)
   #
      wider private;

      # Run the imager.plotvis() function
      ok := private.imager.plotvis(...);
      if (is_fail(ok)) return throw (ok::message);

      return T;
   };

   const public.plotweights := function(...)
   {
   # Contained method: imager.plotweights(...)
   #
      wider private;

      # Run the imager.plotweights() function
      ok := private.imager.plotweights(...);
      if (is_fail(ok)) return throw (ok::message);

      return T;
   };

   const public.sensitivity := function(ref pointsource="0Jy", 
      ref relative=0.0, ref sumweights=0.0, async=!dowait)
   {
   # Contained method: imager.sensitivity(...)
   #
      wider private;

      # Run the imager.sensitivity() function
      ok := private.imager.sensitivity(pointsource, relative, sumweights,
         async);
      if (is_fail(ok)) return throw (ok::message);

      return T;
   };

   const public.plotcal := function(...)
   {
   # Contained method: calibrater.plotcal(...)
   #
      wider private;

      # Run the calibrater.plotcal() function
      ok := private.calibrater.plotcal(...);
      if (is_fail(ok)) return throw (ok::message);

      return T;
   };

   const public.view := function(modelentry='', type='restored')
   {
   # Display one of several images associated with a model
   # entry, including: model, mask, restored or residual.
   #
      wider private;

      # Check for a valid model entry name
      mentry := private.validstring(modelentry);
      mentry := dms.stripleadingblanks(mentry);
      mentry := dms.striptrailingblanks(mentry);

      if (!is_boolean(private.model) && length(private.model) > 0) {
         indx := (private.model == mentry);
         valid := (sum(indx) > 0);
         if (valid) {
            imagetype := private.validstring(type);
            imagetype := dms.stripleadingblanks(imagetype);
            imagetype := dms.striptrailingblanks(imagetype);
            imagename := '';
            # Case image_type of:
            #
            # MODEL:
            if (imagetype == 'MODEL' || imagetype == 'model') {
               imagename := private.model[indx];
            #
            # MASK:
            } else if (imagetype == 'MASK' || imagetype == 'mask') {
               imagename := private.mask[indx];
            #
            # RESTORED:
            } else if (imagetype == 'RESTORED' || imagetype == 'restored') {
               imagename := private.restored[indx];
            #
            # RESIDUAL:
            } else if (imagetype == 'RESIDUAL' || imagetype == 'residual') {
               imagename := private.residual[indx];
            };
            
            if (strlen(imagename) > 0) {
               # Check if the image server is already running; if not,
               # create it with this image.
               if (is_boolean(private.image)) {
                  private.image := image(infile=imagename);
                  if (is_fail(private.image)) 
                     return throw (private.image::message);
               } else {
                  # Re-open the image server with the new image
                  ok := private.image.close();
                  if (is_fail(ok)) return throw (ok::message);
                  ok := private.image.open(infile=imagename);
                  if (is_fail(ok)) return throw (ok::message);
               };
               # View the image
               ok := private.image.view();
               if (is_fail(ok)) return throw (ok::message);
            };
         };
      };

      return T;
   };

   const public.done := function()
   {
      wider private, public;

      # Close the calibrater, imager and image tools
      private.calibrater.done();
      private.imager.done();
      if (!is_boolean(private.image)) private.image.done();
 
      private := F;
      val public := F;
      if (has_field(private, 'gui')) {
         ok := private.gui.done(T);
         if (is_fail(ok)) fail;
      }
      return T;
   }

   const public.type := function() {
      return 'calmap';
   }

   const public.gui := function() 
   {
   # Null 
      return T;
   };

   plugins.attach('calmap', public);
   return ref public;

} # _define_calmap()

#
# Construct from an existing MeasurementSet
#
const calmap := function(msfile='') {
#   
   # Check for null MS file name
   if (msfile=='') {
      throw('Must supply a measurement set filename');
      return F;
   } else if (!dos.fileexists(msfile)) {
      throw('Measurement set ', msfile, ' non-existent!');
      return F;	
   }

   return ref _define_calmap(msfile);
} 

#
# Define demonstration function: return T if successful otherwise fail
#
const calmapdemo:=function() {
   mycalmap:=calmap();
   note(paste("Demonstation of ", mycalmap.objectName()));
   note('Not yet implemented');  
   return T;
}

#
# Define test function: return T if successful otherwise fail
#
const calmaptest:=function() { fail "Not yet implemented";}

# 
#------------------------------------------------------------------------
#


