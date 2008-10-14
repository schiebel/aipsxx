
include 'imager.g';
include 'calibrater.g';
include 'image.g';
include 'ms.g';
include 'flagger.g';
include 'sysinfo.g';

#
# Load the data
#
 
 aipsroot:=sysinfo().root();                       # Assemble UVFITS filename
 fitsfilename:=spaste(aipsroot, '/data/demo/CALS00FEB.fits');
 msetC := fitstoms(msfile='cals00feb.ms',           # Continuum data set
                   fitsfile=fitsfilename);
 msetC.summary(verbose=T);                         # Obtain summary
 msetC.done();                                     # Finish ms tool

#
# Basic editing
#
 include 'flagger.g'                   # Make flagger tool
 fgC:=flagger('cals00feb.ms');         # Set mode to 'flag' data  
 fgC.setflagmode('flag');  
 fgC.setpol(pol=[1,4]);                # Prepare to examine RR, LL
 fgC.filter(column='DATA',             # Flag data with RR, LL amplitude 
            operation='range',         #  outside 0.0-1.34 (pseudo-Jy),
            comparison='Amplitude',    #  applying flags to all polarizations
            range=['0.00001Jy','1.34Jy']);
 fgC.done();                           # Finish flagger tool:

#
# Set default source model
#
 include 'imager.g'
 imgrC := imager('cals00feb.ms');   # Start imager tool
 imgrC.setjy(fieldid=2);            # Set flux density for 1331+305 (3C286)

#
# Solve for G Jones
#
 calC := calibrater('cals00feb.ms');         # Create Calibrater tool
                                             # Select calibrator sources 
                                             #   (in this case, all sources)
 calC.setdata(msselect='FIELD_ID IN [1:10] && SPECTRAL_WINDOW_ID==1');  
 calC.setapply(type='P', t=5.0);             # Arrange to apply parallactic 
                                             #  angle correction (for polarization only)
 calC.setsolve(type='G', t=60.0, refant=3,    # Arrange to solve for G 
               table='cals00feb.gcal');      #  on 60.0 sec timescale
 calC.state();                               # Review setapply/setsolve settings
 calC.solve();                               # Solve
 calC.plotcal(tablename='cals00feb.gcal');   # Inspect solutions

#
# Establish the flux density scale
#
 calC.fluxscale(tablein='cals00feb.gcal',      # Transfer flux density scale 
                tableout='cals00feb.fluxcal',  #  from 1331+305 (3C286) to others
                reference='1331+305',               
                transfer=['0927+390', '0713+438', '0854+201', '1310+323',
                          '1337-129', '1252-336', '1534-354', '1743-038',
                          '1751+096']);
 calC.plotcal(tablename='cals00feb.fluxcal');    # Inspect

#
# Correct the data
#
                                               # Select fields to which calibration 
                                               #  is applied (all)
 calC.setdata(msselect='FIELD_ID IN [1:10] && SPECTRAL_WINDOW_ID==1');
 calC.reset();                                 # Reset setapply/setsolve
 calC.setapply(type='P', t=5.0);               # Arrange to apply parallactic angle 
                                               #  correction
 calC.setapply(type='G', t=0.0,                # Arrange to apply G solutions
               table='cals00feb.fluxcal');
 calC.state();                                 # Review setapply settings
 calC.correct();                               # Apply solutions and write 
                                               #  CORRECTED_DATA column

#
# Make a map of 3C286 to get I,Q,U model
#
 imgrC.setdata(fieldid=2, mode='none',  # Select 1331+305 (field_id=2), one SpW
               nchan=1, start=1, 
               step=1, spwid=[1]);
 imgrC.setimage(nx=256, ny=256,         # Set image plane parameters
                cellx='0.4arcsec', celly='0.4arcsec', 
                stokes='IQUV', fieldid=2, spwid=[1], 
                start=1, step=1, nchan=1,
                mode='mfs');
 imgrC.clean(algorithm='clark',         # Run clean to obtain image
             niter=5000, gain=0.1, threshold='0.0Jy',
             model='3c286_polcal.model', image='3c286_polcal.image',
             residual='3c286_polcal.residual');

#
# Extract peak (I,Q,U,V)
#
   # Start image tool containing model image from clean:
   img1:= image('3c286_polcal.model');
   # Make an array to hold peak for each Stokes
   pmax:= array(0.0, 4);
   # For each Stokes, extract statistics, including peaks:
   for (plane in 1:4) {
      pregion:= drm.box([1,1,plane], [256,256,plane]);
      img1.statistics(statsout=pstats, region=pregion);
      if (abs(pstats.min) > abs(pstats.max)) {
         pmax[plane]:= pstats.min;
      } else {
         pmax[plane]:= pstats.max;
      };
   };

   # Finish image tool:
   img1.done();

   # Variables to hold required max values:
   ival:= pmax[1];
   qval:= pmax[2];
   uval:= pmax[3];

#
# Set the polarization model for 3C286:
#
 stokes := [ival, qval, uval, 0.0]     # Polarization model determined 
                                       #  from imaging
 imgrC.setjy(fieldid=2, spwid=1,       # Set model for IQUV
             fluxdensity=stokes);
  
#
# Solve for D Jones from 3C286 (applying P and G):
#
                                               # Select data for polarization calibrater
 calC.setdata(msselect='FIELD_ID==2 && SPECTRAL_WINDOW_ID==1');
 calC.reset();                                 # Reset setapply/setsolve
 calC.setapply(type='P', t=5.0);               # Arrange to apply parallactic angle
 calC.setapply(type='G', t=0.0,                # Arrange to apply G solutions
               table='cals00feb.fluxcal');      
 calC.setsolve(type='D', t=86400.0, preavg=600.0,   # Arrange to solve for D over long 
               table='cals00feb.dcal');            #  time scale, average data within 
                                                    #  the solution to no more than 600 
                                                    #  sec per chunk
 calC.state();                                 # Review setapply/setsolve settings
 calC.solve();                                 # Solve

#
# Correct all ten sources for P Jones, G Jones, and D Jones
#
                                                # Select fields to which calibration 
                                                #  is to be applied
 calC.setdata(msselect='FIELD_ID IN [1:10] && SPECTRAL_WINDOW_ID==1');
 calC.reset();                                  # Reset setapply/setsolve
 calC.setapply(type='P', t=5.0);                # Arrange to apply parallactic 
                                                #  angle correction
 calC.setapply(type='G', t=0.0,                 # Arrange to apply G solutions
               table='cals00feb.fluxcal');  
 calC.setapply(type='D', t=0.0,                 # Arrange to apply D solutions
               table='cals00feb.dcal'); 
 calC.state();                                  # review setapply settings
 calC.correct();                                # Correct the data
 calC.done();                                   # Finish calibrater tool

#
# Make a polarization-calibrated (I,Q,U,V) image for 3C286:
#

 imgrC.setdata(fieldid=2, mode='none', spwid=1,    # Select data for field 2 and
               nchan=1, start=1, step=1);          #   spectral window 1

 imgrC.setimage(nx=256, ny=256, stokes='IQUV',        # Imaging parameters
                cellx='0.4arcsec', celly='0.4arcsec',
                fieldid=2, spwid=1, start=1, step=1,
                nchan=1, mode='none');

 imgrC.clean(algorithm='clark', niter=5000, gain=0.1,     # Image, and deconvolve using 
             model='3c286.model',                       # the Clark CLEAN
             image='3c286.image',
             residual='3c286.residual');

 imgrC.restore(model='3c286.model',                     # Restore full field
               image='3c286.restored');      


#
# Make a polarization-calibrated (I,Q,U,V) image for all sources:
#

 # **************************************************
 # set the following variable to T to make all images:
 # **************************************************

 doall:=F;

 if (doall) {

   fldtab:= table('cals00feb.ms/FIELD');
   fldname:= fldtab.getcol('NAME');
   fldtab.close();

   for (ifld in 1:10) {
      imgrC.setdata(fieldid=ifld, mode='channel', nchan=1, start=1, step=1, 
                    spwid=1);
      imgrC.setimage(nx=256, ny=256, cellx='0.4arcsec', celly='0.4arcsec', 
                     stokes='IQUV', fieldid=ifld, spwid=1, start=1, step=1, 
                     nchan=1, mode='channel');

      modelname:= spaste(fldname[ifld], '.model');
      imagename:= spaste(fldname[ifld], '.image');
      residualname:= spaste(fldname[ifld], '.residual');
      restoredname:= spaste(fldname[ifld], '.restored');
      print 'Final imaging for', modelname;

      imgrC.clean(algorithm='clark', niter=5000, gain=0.1, threshold='0.0Jy',
                  model=modelname, image=imagename, residual=residualname);

      imgrC.restore(model=modelname,  
                    image=restoredname);      

	

   };
 }
 imgrC.done();     # Finish imager tool





