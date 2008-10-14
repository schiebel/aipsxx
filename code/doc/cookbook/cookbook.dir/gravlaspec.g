
include 'imager.g';
include 'calibrater.g';
include 'image.g';
include 'ms.g';
include 'flagger.g';

#
# VLA H_I line data reducion: NGC 5921
#
# Load the data
#
 aipsroot:=sysinfo().root();                   # Assemble name of UVFITS file
 fitsfilename:=spaste(aipsroot, '/data/demo/NGC5921.fits');
 msetS := fitstoms(msfile='ngc5921.ms',        # Line dataset
                   fitsfile=fitsfilename);
 msetS.summary(verbose=T);                     # Obtain summary
 msetS.done();                                 # Finish ms tool

#
# Basic editing
#   
 include 'flagger.g'
 fgS:=flagger('ngc5921.ms');           # Make flagger tool
 fgS.setflagmode('flag');              # Set mode to flag data:
 fgS.setids(fieldid=1);                # Clip outlying data for 
 fgS.filter(column='DATA',             #  1331+305 (field 1)
            operation='range', 
            comparison='Amplitude',
            range=['0.0Jy','1.6Jy']);   
 fgS.setids(fieldid=2);                # Clip outlying data for 
 fgS.filter(column='DATA',             #  1445+099 (field 2)
            operation='range', 
            comparison='Amplitude',
            range=['0.0Jy','0.4Jy']);

 fgS.setids(fieldid=3);                # Clip outlying data for 
 fgS.filter(column='DATA',             #  NGC 5921 (field 3):
            operation='range', 
            comparison='Amplitude',
            range=['0.0Jy','0.11Jy']);
 fgS.done();                           # Finish flagger tool:

#
# Set source model
#
 include 'imager.g'
 imgrS:=imager('ngc5921.ms');       # Start imager tool  
 imgrS.setjy(fieldid=1,                    
             fluxdensity=[14.8009,0,0,0]); # Set 1331+305 (3C286) model

#
# Solve for G Jones 
#
 calS := calibrater('ngc5921.ms');              # Create calibrater tool
 calS.setdata(msselect='FIELD_ID <= 2');        # Select data for calibrators 
                                                #  (Fields 1 & 2)
 calS.setsolve(type='G', t=300.0, refant=15,    # Arrange to solve for G on 
               table='ngc5921.gcal');           #  300-second timescale
 calS.state();                                  # Review setsolve settings
 calS.solve();                                  # Solve
 calS.plotcal(tablename='ngc5921.gcal');        # Inspect solutions

#
# Establish the flux density scale
#
 calS.fluxscale(tablein='ngc5921.gcal',        # Transfer flux density scale 
                tableout='ngc5921.fluxcal',    #  from 3c286 to others
                reference='1331+30500002',
                transfer=['1445+09900002']);
 calS.plotcal(tablename='ngc5921.fluxcal');    # Inspect 

#
# Solve for B Jones (bandpass)
#
 calS.setdata(msselect='FIELD_ID==1');      # Select BP calibrator (1331+305)
 calS.reset();                              # Reset apply/solve state
 calS.setapply(type='G', t=0.0,             # Arrange to apply G solutions
               table='ngc5921.fluxcal'); 
 calS.setsolve(type='B', t=86400.0, refant=15, # Arrange to solve for bandpass 
               table='ngc5921.bcal');
 calS.state();                              # Review setapply/setsolve settings
 calS.solve();                              # Solve
 calS.plotcal(tablename='ngc5921.bcal');    # Inspect

#
# Correct the line data for G and B Jones
#
                                         # Select fields to which calibration 
                                         #   will be applied
 calS.setdata(msselect='FIELD_ID IN [1:3]');  
 calS.reset();                           # Reset setapply/setsolve
 calS.setapply(type='G', t=0.0,          # Arrange to apply G solutions
               table='ngc5921.fluxcal', 
               select='FIELD_ID==2');
 calS.setapply(type='B', t=0.0,          # Arrange to apply B solutions
               table='ngc5921.bcal');   
 calS.state();                           # Review setapply settings
 calS.correct();                         # Apply solutions and write 
                                         #  CORRECTED_DATA column
 calS.done();                            # Finish calibrater tool

#
# Make a channel map of NGC 5921
#
 imgrS.setdata(fieldid=3, mode='channel',  # Select data for field 3, spectral
               spwid=1, nchan=63, start=1, #  window 1 and all channels 
               step=1);           
 imgrS.setimage(nx=256, ny=256, stokes='I',          # Imaging parameters
                cellx='10arcsec', celly='10arcsec', 
                start=1, step=1, nchan=63,
                mode='channel',fieldid=3);
 imgrS.weight(type='uniform');                       # Uniform weighting
 imgrS.clean(algorithm='clark', niter=3000,          # Image and deconvolve
             threshold='0.0Jy',                      # with Clark CLEAN
             model='ngc5921.model', 
             image='ngc5921.image',
             residual='ngc5921.residual');
 imgrS.restore(model='ngc5921.model',                # Restore full field
              image='ngc5921.restored');
 imgrS.done();                                       # Finish imager tool

#
# Subtract mean continuum channels (5-8, 55-58) using image tool
#
   # Start image tool containing restored image:
   restim:=image('ngc5921.restored');
   # Mask bad channels (first few, last few)
   restim.set(pixelmask=F,region=drm.box([1,1,1,1],[256,256,1,5]));
   restim.set(pixelmask=F,region=drm.box([1,1,1,60],[256,256,1,63]));
   
   # Copy restored image for in-place continuum subtraction:
   csubim:=imagefromimage(outfile='ngc5921.final', 
                      infile='ngc5921.restored');

   # Define region of image which is continuum (channels 6-9,55-58): 
   cregion1:=drm.box([1,1,1,6],[256,256,1,9]);
   cont1:=restim.subimage(outfile='cont1.im',region=cregion1);
   cregion2:=drm.box([1,1,1,55],[256,256,1,58]);
   cont2:=restim.subimage(outfile='cont2.im',region=cregion2);
   # Form single image containing all continuum channels:
   #   (this is a virtual image referencing cont1.im & cont2.im)
   cont:=imageconcat(infiles="cont1.im cont2.im",relax=T);

   # Form integrated continuum as moment=-1 of continuum channels
   cont.moments(outfile='ngc5921.cont',moments=-1,axis=4);

   # Delete intermediate images/tools:
   cont.done();
   cont1.delete(); cont1.done();
   cont2.delete(); cont2.done();

   # Subtract continuum from cube:
   csubim.calc('$csubim - ngc5921.cont')

   # View final image
   csubim.view();
#
# End
#
