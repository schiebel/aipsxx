
include 'imager.g';
include 'calibrater.g';
include 'image.g';
include 'ms.g';
include 'flagger.g';
include 'sysinfo.g';
include 'stopwatch.g';

#
# Load the data
#
   aipsroot:=sysinfo().root();
   fitsfilename:=spaste(aipsroot, '/data/demo/atca4800.fits');
   m:=fitstoms(fitsfile=fitsfilename, msfile='4800.ms');
   m.done();
#
# Set default source model
#
   imagr:=imager('4800.ms');
   imagr.setjy(fieldid=1, spwid=1);
#
# Solve for G Jones
#
   cal:=calibrater('4800.ms');
   cal.setdata(msselect='FIELD_ID==1');
   cal.setapply(type='P', t=5.0);
   cal.setsolve(type='G', t=60.0, refant=3, table='4800.gcal1');
   cal.solve();
   cal.done();
#
# Solve for D Jones
#
   cal:= calibrater('4800.ms');
   cal.setdata(msselect='FIELD_ID==1');

   cal.setapply(type='P', t=5.0);
   cal.setapply(type='G', t=0.0, table='4800.gcalout1');
   cal.setsolve(type='D', t=86400.0, preavg=600.0, table='4800.dcal1');
   cal.solve();
   cal.done();
#
#
# Intercompare D-terms
#
   t:=table('4800.dcal1');
   gain:= t.getcol('GAIN');

   print;
   print "AIPS++ - MIRIAD comparison";
   print;

   for (j in 1:6) {
      d1r:= real(gain[1,2,1,j]);
      d1i:= imag(gain[1,2,1,j]);
      d2r:= real(gain[2,1,1,j]);
      d2i:= imag(gain[1,2,1,j]);
      print 'Ant=', j, ' ', sprintf('%10.3f %10.3f %10.3f %10.3f', d1r, -d1i, d2r, -d2i);
      if (j==1) {
         m1r:= -0.009; m1i:= 0.024; m2r:= 0.007; m2i:= 0.025;
      } else if (j==2) {
         m1r:= -0.008; m1i:= 0.005; m2r:= 0.001; m2i:= -0.001;
      } else if (j==3) {
         m1r:= -0.009; m1i:= 0.010; m2r:= 0.004; m2i:= 0.009;
      } else if (j==4) {
         m1r:= 0.002; m1i:= -0.021; m2r:=-0.003; m2i:= -0.019;
      } else if (j==5) {
         m1r:= 0.007; m1i:= -0.010; m2r:=-0.013; m2i:= -0.011;
      } else if (j==6) {
         m1r:= 0.000; m1i:= -0.006; m2r:=-0.013; m2i:= -0.005;
      };

      print 'Miriad  ', sprintf('%10.3f %10.3f %10.3f %10.3f', m1r, m1i, m2r, m2i);
      print '----------------------------------------------------';
      
   };









