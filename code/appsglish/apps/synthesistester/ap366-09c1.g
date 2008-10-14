
include 'calibrater.g';
include 'imager.g';
include 'ms.g';
include 'image.g'

#
# Load the data
#
   aipsroot:=sysinfo().root();
   fitsfilename:=spaste(aipsroot, '/data/demo/AP366-09C1.fits');
   m:=fitstoms(fitsfile=fitsfilename, msfile='ap366-09c1.ms');
   m.done();
#
# Set the source model
#
   imagr:=imager('ap366-09c1.ms');
   imagr.setjy(fieldid=9);
   imagr.done();
#
# Simple phase and amplitude cross-calibration
#
   cal:=calibrater('ap366-09c1.ms');
   cal.setdata(msselect='FIELD_ID==9');
   cal.setsolve(type='G',table='ap366.gcal',t=180.0);
   cal.solve();
   cal.setdata(msselect='FIELD_ID==10');
   cal.setapply(type='G',table='ap366.gcal',t=0.0);
   cal.correct();
   cal.done();
#
# Make a map of 0957+561
#
   imagr:=imager('ap366-09c1.ms');
   imagr.setdata(fieldid=10);
   imagr.setimage(nx=512, ny=512, cellx='0.1arcsec', celly='0.1arcsec', 
                  fieldid=10);
   imagr.weight();
   imagr.make('0957.model');
   imagr.clean(niter=5000, model='0957.model', image='0957.restored',
               residual='0957.residual');
#
# Display using the viewer
#
   im:=image('0957.restored');
   im.view();

