pragma include once

include 'serverexists.g';
include 'misc.g'
include 'note.g';
include 'os.g';


atcaimager := subsequence (msname)
{
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is either not running or not valid', 
                    origin='atcaimager.g');
   }
   if (!serverexists('dms', 'misc', dms)) {
      return throw('The misc server "dms" is either not running or not valid', 
                    origin='atcaimager.g');
   }


# Private

   its := [=]
#
   its.dir := '';            # Directory to make files in
   its.msname := '';         # MS filename
   its.imager := [=];        # Imager tool
   its.msRec := [=];         # Record holding field names and IDs
   its.sourceID := -1;       # Field ID of source we want to image
   its.sourceName := '';
   its.spwids := -1;         # Select spwids
   its.doneSetData := F;


###
   const its.makeImager := function ()
   {
      wider its;
#
      include 'imager.g';
      its.imager := imager(its.msname);
      if (is_fail(its.imager)) fail;
#
      return T;
   }

# Public

###
   const self.done := function ()
   {
      wider its;
      wider self;
#
      ok := its.as.done();
      ok := its.imager.done();
#
      val its := F;
      val self := F;
#
      return T;
   }


###
   const self.image := function (clean=F, niter=0, cutoff=unset)
   {
      wider its;
#
      s1 := as_evalstr(its.spwids);
      spwidString := dms.striptrailingblanks(s1);      # Glish adds a trailing blank...
#
      if (clean) {

# Deconvolved image

         model := spaste (its.dir, '/', its.sourceName, '-', spwidString, '.model');
         ok := dos.remove(model, mustexist=F);
         restored := spaste (its.dir, '/', its.sourceName, '-', spwidString, '.restored');
         ok := dos.remove(restored, mustexist=F);
         residual := spaste (its.dir, '/', its.sourceName, '-', spwidString, '.residual');
         ok := dos.remove(residual, mustexist=F);

# Find sensitivity if no niters given either
                  
         cut := dq.quantity ('0Jy');
         if (is_unset(cutoff) && niter==0) {
            local sens, rel, sum;
            ok := its.imager.sensitivity (pointsource=sens, relative=rel, 
                                          sumweights=sum, async=F);
            if (is_fail(ok)) fail;

# 10*sigma

            cut := dq.mul(sens, 10.0);
            if (is_fail(cut)) fail;

# Set niter to big number so thresh-hold is active

            niter := 1000000;
         }
         ok := its.imager.clean(algorithm='clark',
                               model=model,
                               image=restored,
                               residual=residual,
#                               mask='', 
#                               threshold=cut,
                               niter=niter,
                               gain=0.1, 
                               displayprogress=F, async=F);
         if (is_fail(ok)) fail;
#
         return restored;
      } else {

# Dirty image

         name := spaste (its.dir, '/', its.sourceName, '-', spwidString, '.dirty');
         ok := dos.remove(name, mustexist=F);
         ok := its.imager.makeimage (type='corrected', image=name, async=F);
         if (is_fail(ok)) fail;
#
         return name;
      }
#
      return T;
   }      

###
   const self.setdata := function (spwids=1, source)
   {
      wider its;

# Find source ID

      its.sourceName := source;
      its.sourceID := its.as.findID (its.msRec, source);
      if (is_fail(its.sourceID)) fail;
      its.spwids := spwids;

# Set up data selection parameters.

      nchan := its.msRec.num_chan[its.spwids[1]];    # All channels from first spwid [needs a check]
      start := 1;
      step := 1;
      fieldid := its.sourceID;                       # Specified source
#
      ok := its.imager.setdata (mode='channel', nchan=nchan, start=start,
                                step=step, spwid=its.spwids,
                                fieldid=fieldid, async=F);
      if (is_fail(ok)) fail;
#
      its.doneSetData := T;
      return T;
   }

###
   const self.setimage := function (weight='uniform', uvrange=unset, fwhm=unset,
                                    stokes='I', cell=unset, n=unset)

   {
      wider its;

# Did we call setdata - presently this is mandatory.

      if (!its.doneSetData) {
         return throw ('You must call function setdata first', 
                       origin='atcaimager.setimage')
      }

# Select uv range

      if (!is_unset(uvrange)) {
         if (length(uvrange)==2) {
            ok := its.imager.uvrange (uvmin=uvrange[1], uvmax=uvrange[2]);
            if (is_fail(ok)) fail;
         }
      }

# Apply filtering (tapering)

      if (!is_unset(fwhm)) {
         if (is_numeric(fwhm)) {
            fwhm := spaste(fwhm, 'arcsec');
         }
         ok := its.imager.filter (type='gaussian', bmaj=fwhm, bmin=fwhm, bpa='0deg');
         if (is_fail(ok)) fail;
      }

# See what Imager has to advise.  Cheap and nasty to get field of view for ATCA

      f := its.msRec.ref_frequency[its.spwids[1]];         # Assume all spwids alike
      fieldOfView := spaste(30*1.4e9/f, 'arcmin');
      local nxy, cellxy, facets, phasecenter;
      ok := its.imager.advise (takeadvice=F, pixels=nxy, cell=cellxy, 
                               facets=facets, fieldofview=fieldOfView,
                               phasecenter=phasecenter);
      if (is_fail(ok)) fail;

# Set parameters

      if (!is_unset(cell)) {
         if (is_numeric(cell)) {
            cellxy := spaste(cell, 'arcsec');
         } else {
            cellxy := cell;
         }
      }
      if (!is_unset(n)) nxy := n;
      ok := its.imager.setimage (nx=nxy, ny=nxy, cellx=cellxy, celly=cellxy,
                                 stokes=stokes, doshift=F, 
                                 mode='mfs', nchan=1, step=1,
                                 fieldid=its.sourceID,
                                 spwid=its.spwids)
#                                 facets=facets);
      if (is_fail(ok)) fail;

# Weighting

      ok := its.imager.weight (type=weight);
      if (is_fail(ok)) fail;
#
      return T;
   }


# Constructor

  if (len(as_string(msname)) == 0) {
     return throw ('MS filename not provided', 
                   origin='atcaimager.g');
  }
  its.msname := as_string(msname);

# Make ATCA support tool

   include 'atcasupport.g'
   its.as := atcasupport();
   if (is_fail(its.as)) fail;

# Find directory that MS files is living in

   its.dir := its.as.directoryname(its.msname);
   if (is_fail(its.dir)) fail;

# Find stuff from MS

   its.msRec := its.as.createMSRec (its.msname);
   if (is_fail(its.msRec)) fail;

# Create Imager tool

  ok := its.makeImager ();
  if (is_fail(ok)) fail;
}


