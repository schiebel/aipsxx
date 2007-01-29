
include 'ms.g';             # if filling from a UVFITS file
include 'imager.g';
include 'calibrater.g';
include 'image.g';

#
# Load the data (from UVFITS)
#

msetC:=fitstoms(msfile='ap366.ms',          # From data repository
                fitsfile='/home/aips++/data/demo/AP366-09C1.fits');
msetC.summary(verbose=T);                   # Obtain summary
msetC.done();                               # Finish ms tool

# 
# Set the default source model
#

imgrC:=imager('ap366.ms');       # Start imager tool
imgrC.setjy(fieldid=11);           # Set flux density for 1328+307 (3C286)

# 
# Solve for G 
#

calC:=calibrater('ap366.ms');               # Create Calibrater tool
calC.setdata(msselect='FIELD_ID IN [9,11]');
calC.setapply(type='P',                     # Arrange to apply parallactic 
              t=5.0);                       #  angle correction (for poln only)
calC.setsolve(type='G',                     # Arrange to solve for G 
              t=60.0,                       #  on 60.0 sec timescale
              refant=3,
              table='ap366.gcal');
calC.state();                               # Review setapply/setsolve settings
calC.solve();                               # Solve
calC.plotcal(tablename='ap366.gcal');       # Inspect solutions

#
# Establish flux density scale
#

calC.fluxscale(tablein='ap366.gcal',      # Transfer flux density scale 
               tableout='ap366.fluxcal',  #  from 1328+307 (3C286) to others
               reference='1328+307',               
               transfer='0917+624');
calC.plotcal(tablename='ap366.fluxcal');  # Inspect

# 
# Correct the data
#

calC.setdata(msselect='FIELD_ID IN [9:11]');  # Select fields to which cal
                                              #  will be applied
calC.reset();                                 # Reset setapply/setsolve
calC.setapply(type='P',                       # Arrange to apply parallactic angle 
              t=5.0);                         #  correction
calC.setapply(type='G',                       # Arrange to apply G solutions
              t=0.0,
              table='ap366.fluxcal');
calC.state();                                 # Review setapply settings
calC.correct();                               # Apply solutions and write 

# (the data now ready for total intensity imaging)



# 
# Set the polarization model for instr. pol cal
#

stokes := [7.462, -0.621, -0.593, 0.0]       # 3C286 polarization model determined 
                                             #  from imaging
imgrC.setjy(fieldid=11, fluxdensity=stokes); # Set model for IQUV

#
# Solve for D
#

calC.setdata(msselect='FIELD_ID==11');       # Select data for 3C286
calC.reset();                                # Reset setapply/setsolve
calC.setapply(type='P',                      # Arrange to apply parallactic angle
              t=5.0);
calC.setapply(type='G',                      # Arrange to apply G solutions
              t=0.0, 
              table='ap366.fluxcal');
calC.setsolve(type='D',                      # Arrange to solve for D over long 
              t=86400.0,                     #  time scale, average data within 
              preavg=600.0,                  #  the solution to no more than 600 
              table='ap366.dcal');           #  sec per chunk
calC.state();                                # Review setapply/setsolve settings
calC.solve();                                # Solve

# 
# Apply all calibration to all sources
#

calC.setdata(msselect='FIELD_ID IN [9:11]'); # Select fields to which calibration 
                                             #  will be applied
calC.reset();                                # Reset setapply/setsolve
calC.setapply(type='P',                      # Arrange to apply parallactic 
              t=5.0);                        #  angle correction
calC.setapply(type='G',                      # Arrange to apply G solutions
              t=0.0,
              table='ap366.fluxcal');  
calC.setapply(type='D',                      # Arrange to apply D solutions
              t=0.0,
              table='ap366.dcal'); 
calC.state();                                # review setapply settings
calC.correct()                               # Correct the data


#
# Image and deconvolve in full poln
#

imgrC.setdata(mode='none',         # Select continuum data
              fieldid=10);         #  for field 10 (0957+561)
imgrC.setimage(nx=512,             # Set image plane parameters
               ny=512,
               cellx='0.1arcsec',
               celly='0.1arcsec',
               stokes='IQUV',      #   (full polarization)
               fieldid=10);  
imgrC.weight(type='uniform');      # Set uniform weighting
imgrC.clean(algorithm='clark',     # Image, and deconvolve using 
            niter=5000,            #  the Clark CLEAN
            gain=0.1,
            model='0957+561.mod',                 
            image='0957+561.im',
            residual='0957+561.resid');
imgrC.restore(model='0957+561.mod',     # Restore full field
              image='0957+561.res');      


# 
# View final result
#

imC:=image('0957+561.res');        # Start Image tool
imC.view();                        # Launch viewer


# 
# Finish tools
#

calC.done();                       # Finish imager tool
imgrC.done();                      # Finish calibrater tool


