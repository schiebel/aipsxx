# ATCA pipeline prototype

pragma include once

include 'imagesupport.g'
include 'misc.g'
include 'note.g'
include 'os.g'
include 'serverexists.g'
include 'unset.g'


atcapipeline := subsequence (dir=unset)
{
   if (!serverexists('dos', 'os', dos)) {
      return throw('The os server "dos" is either not running or not valid', 
                    origin='atcapipeline.g');
   }
   if (!serverexists('dms', 'misc', dms)) {
      return throw('The os server "dos" is either not running or not valid', 
                    origin='atcapipeline.g');
   }


# Private

   its:=[=]

# Tools

   its.is := imagesupport();
   if (is_fail(its.is)) fail;
#
   its.imager := [=];
#
   its.filenames := unset;
   its.dir := unset;               # Directory for new files
   its.msname := unset;            # MeasurementSet
#


###
   const its.createdir := function ()
   {
      wider its;

# Get directory name

      its.dir := its.is.defaultname('pipeline');
      if (is_fail(its.dir)) fail;

# Create it

      if (is_fail(dos.mkdir(its.dir))) {
         return throw(spaste('Failed to make directory ', its.dir),
                       origin='atcapipeline.createdir');
      }
#
      return T;
   }



# Public functions

###
   const self.calibrate := function (init=T, primary='1934-638', secondaries,
                                     leakage=T, bandpass=T, spwids=unset, interval=unset,
                                     average=unset, plot=F)
   {
      wider its;

# Make ATCA calibrater

      include 'atcacalibrater.g'
      cal := atcacalibrater (its.msname);
      if (is_fail(cal)) fail;

# Initialize models

      if (init) {
         ok := cal.setjy(sources=[primary, secondaries]);
         if (is_fail(ok)) fail;
      }

# Solve for calibraters

      ok := cal.solve (primary=primary, secondaries=secondaries,
                       leakage=leakage, bandpass=bandpass, 
                       interval=interval, spwids=spwids);
      if (is_fail(ok)) fail;

# Plot

      if (plot) {
         ok := cal.plot(gain=T, bandpass=bandpass, leakage=leakage);
         if (is_fail(ok)) fail;
      }

# Apply to all sources applying averaging before application to targets

      ok := cal.correct (interval=average, vector=T)
      if (is_fail(ok)) fail;
#
      ok := cal.done();
      if (is_fail(ok)) fail;
#
      return T;
   }



###
   const self.done := function ()
   {
      wider its;
      wider self;
#
      ok := its.is.done();
      if (is_record(its.imager) && length(its.imager)>0) {
         ok := its.imager.done();
      }
#
      val its := F;
      val self := F;
      return T;
   }

###
   const self.edit := function ()
   {
      include 'atcaediter.g'
      return T;
   }

###
   const self.fill := function (filenames, freqchain=unset, lowfreq=unset, 
                                highfreq=unset, fields=unset, options=unset)
   {
      wider its;
#
      its.filenames := dms.tovector(filenames,'string');
      if (is_fail(its.filenames)) fail;

# Construct filler

      include 'atcafiller.g'

#
      if (is_unset(options)) options := "";
      f := atcafiller (msname=its.msname, filenames=its.filenames,
                       options=options);
      if (is_fail(f)) fail;

# Select

      if (is_unset(fields)) fields := "";
      if (!is_unset(freqchain) ||
          !(is_unset(lowfreq) && is_unset(highfreq)) || 
            length(fields)!=0) {
         if (is_unset(freqchain)) freqchain := 0;
         if (is_unset(lowfreq)) lowfreq := 0.1;
         if (is_unset(highfreq)) highfreq := 1000.;
#
         ok := f.select (freqchain=freqchain, lowfreq=lowfreq, highfreq=highfreq, fields=fields)
         if (is_fail(ok)) fail;
      }

# Fill

      ok := f.fill();
      if (is_fail(ok)) fail;
#
      ok := f.done();
      if (is_fail(ok)) fail;
#
      return T;
   }

###
   const self.image := function (spwids=1, source, stokes='I', cell=unset, n=unset, 
                                 fwhm=unset, uvrange=unset, weight='uniform', 
                                 clean=F, niter=unset)
   {
      wider its;
#
      dowait := T;
#
      if (is_record(its.imager) && length(its.imager)==0) {
         include 'atcaimager.g'
         its.imager := atcaimager (its.msname);
         if (is_fail(its.imager)) fail;
      }
      stokes := to_upper(stokes);
#
      ok := its.imager.setdata(spwids=spwids, source=source);
      if (is_fail(ok)) fail;
#
      ok := its.imager.setimage(weight=weight, stokes=stokes, cell=cell, 
                                n=n, uvrange=uvrange, fwhm=fwhm);
      if (is_fail(ok)) fail;
#
      name := its.imager.image(clean=clean, niter=niter);
      if (is_fail(name)) fail;
#
      return name;
   }

###
   const self.ms := function ()
   {
      wider its;
      return its.msname;
   }

###
   const self.msrec := function ()
   {
      wider its;
#
      r := [=];
      if (length(its.msname)>0) {
         include 'atcasupport.g'
         as := atcasupport();
         r := as.createMSRec(its.msname);  
         ok := as.done();
      } else {
         note ('MS not yet set', priority='WARN', origin='atcapipeline.msrec')
      }
#
      return r;
   }     




# Constructor

# Make directory

   if (is_unset(dir)) {
      ok := its.createdir();
      if (is_fail(ok)) fail;
   } else {
      if (dos.fileexists (dir))  {      
        its.dir := dir;
      } else {
        return throw ('Specified directory does not exist',
                       origin='atcapipeline.g')
      }
   }

# Set MS file name

   its.msname := spaste(its.dir, '/data.ms');
}
