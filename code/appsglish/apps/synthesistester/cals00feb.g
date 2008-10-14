
include 'imager.g';
include 'calibrater.g';
include 'image.g';
include 'ms.g';
include 'flagger.g';
include 'sysinfo.g';

#
# Utility function: atan2(x,y)
#
atan2 := function(x, y) {
   fact:= 180.0 / pi;
   if ((x > 0) & (y > 0)) angle:= atan(y/x) * fact;
   if ((x > 0) & (y < 0)) angle:= atan(y/x) * fact + 360;
   if ((x < 0) & (y > 0)) angle:= 180 - atan(y/abs(x)) * fact;
   if ((x < 0) & (y < 0)) angle:= 180 + atan(abs(y)/abs(x)) * fact;
   return angle;
};

#
# Load the data
#
   aipsroot:=sysinfo().root();
   fitsfilename:=spaste(aipsroot, '/data/demo/CALS00FEB.fits');
   m:=fitstoms(fitsfile=fitsfilename, msfile='cals00feb.ms');
   m.done();
#
# Basic editing
#
   fg:=flagger('cals00feb.ms');
   fg.setflagmode('unflag');
   fg.query(query='FIELD_ID >= 0');
   fg.setflagmode('flag');
   fg.filter(column='DATA', operation='range', comparison='Amplitude',
             range=['0.00001Jy','1.34Jy']);
   fg.done();
#
# Set default source model
#
   imagr:=imager('cals00feb.ms');
   imagr.setjy(spwid=1);
#
# Solve for G Jones
#
   cal:=calibrater('cals00feb.ms');
   cal.setdata(msselect='SPECTRAL_WINDOW_ID==1');
   cal.setapply(type='P', t=5.0);
   cal.setsolve(type='G', t=60.0, refant=3, table='cals00feb.gcal1');
   cal.solve();
#
# Establish the flux density scale
#
   cal.fluxscale(tablein='cals00feb.gcal1', tableout='cals00feb.gcalout1',
                 reference='1331+305',
                 transfer=['0927+390', '0713+438', '0854+201', '1310+323',
                           '1337-129', '1252-336', '1534-354', '1743-038',
                           '1751+096']);
#
# Correct the data
#
   cal.setapply(type='P', t=5.0);
   cal.setapply(type='G', t=0.0, table='cals00feb.gcalout1');
   cal.correct();
   cal.done();
#
# Make a map of 3C286
#
   imagr.setdata(fieldid=2, mode='channel', nchan=1, start=1, step=1, spwid=1);
   imagr.setimage(nx=256, ny=256, cellx='0.4arcsec', celly='0.4arcsec', 
                  stokes='IQUV', fieldid=2, spwid=1, start=1, step=1, nchan=1,
                  mode='channel');
   imagr.make('1331-g1.model');
   imagr.clean(algorithm='clark', niter=5000, gain=0.1, threshold='0.0Jy',
               model='1331-g1.model', image='1331-g1.restored',
               residual='1331-g1.residual');
#
# Extract peak (I,Q,U,V)
#
   img1:= image('1331-g1.model');
   pmax:= array(0.0, 4);
   for (plane in 1:4) {
      pregion:= drm.box([1,1,plane], [256,256,plane]);
      img1.statistics(statsout=pstats, region=pregion);
      if (abs(pstats.min) > abs(pstats.max)) {
         pmax[plane]:= pstats.min;
      } else {
         pmax[plane]:= pstats.max;
      };
   };
   img1.done();
#
   ival:= pmax[1];
   qval:= pmax[2];
   uval:= pmax[3];
#
# Set the polarization model, applying the AIPS PCAL constraint
#
   imagr.setjy(fieldid=2, spwid=1, fluxdensity=[ival, qval, uval, 0.0]);
#
# Solve for D Jones from 3C286
#
   cal:= calibrater('cals00feb.ms');
   cal.setdata(msselect='FIELD_ID==2 && SPECTRAL_WINDOW_ID==1');

   cal.setapply(type='P', t=5.0);
   cal.setapply(type='G', t=0.0, table='cals00feb.gcalout1');
   cal.setsolve(type='D', t=86400.0, preavg=600.0, table='cals00feb.dcal1');
   cal.solve();
#
# Correct all ten sources for G Jones and D Jones
#
   cal.setdata(msselect='SPECTRAL_WINDOW_ID==1');
   cal.setapply(type='P', t=5.0);
   cal.setapply(type='G', t=0.0, table='cals00feb.gcalout1');
   cal.setapply(type='D', t=0.0, table='cals00feb.dcal1');
   cal.correct();
   cal.done();
#
# Make a polarization-calibrated (I,Q,U,V) image for all ten sources
#
   fldtab:= table('cals00feb.ms/FIELD');
   fldname:= fldtab.getcol('NAME');
   fldtab.close();

   for (ifld in 1:10) {
      imagr.setdata(fieldid=ifld, mode='channel', nchan=1, start=1, step=1, 
                    spwid=1);
      imagr.setimage(nx=256, ny=256, cellx='0.4arcsec', celly='0.4arcsec', 
                     stokes='IQUV', fieldid=ifld, spwid=1, start=1, step=1, 
                     nchan=1, mode='channel');

      modelname:= spaste(fldname[ifld], '.model');
      restoredname:= spaste(fldname[ifld], '.restored');
      residualname:= spaste(fldname[ifld], '.residual');
      print 'Final imaging for', modelname;

      imagr.make(modelname);
      imagr.clean(algorithm='clark', niter=5000, gain=0.1, threshold='0.0Jy',
                  model=modelname, image=restoredname, residual=residualname);
   };
   imagr.done();
#
# Inter-compare AIPS and AIPS++ polarization values
#
# Tabulate the values derived from AIPS/PCAL/IMSTAT (max abs).
#
   ivalc:= [=];
   qvalc:= [=];
   uvalc:= [=];

   ivalc['aips']['1331+305']:= 7.451;
   qvalc['aips']['1331+305']:= -0.547;
   uvalc['aips']['1331+305']:= -0.642;

   ivalc['aips']['0854+201']:= 2.395;
   qvalc['aips']['0854+201']:= 0.0318;
   uvalc['aips']['0854+201']:= 0.109;

   ivalc['aips']['0927+390']:= 10.65;
   qvalc['aips']['0927+390']:= -0.0258;
   uvalc['aips']['0927+390']:= -0.0667;

   ivalc['aips']['0713+438']:= 1.549;
   qvalc['aips']['0713+438']:= 0.00304;
   uvalc['aips']['0713+438']:= -0.0022;

   ivalc['aips']['1310+323']:= 1.866;
   qvalc['aips']['1310+323']:= -0.0350;
   uvalc['aips']['1310+323']:= 0.0383;

   ivalc['aips']['1337-129']:= 5.506;
   qvalc['aips']['1337-129']:= 0.0156;
   uvalc['aips']['1337-129']:= -0.135;

   ivalc['aips']['1252-336']:= 0.435;
   qvalc['aips']['1252-336']:= -0.0157;
   uvalc['aips']['1252-336']:= 0.0131;

   ivalc['aips']['1534-354']:= 0.569;
   qvalc['aips']['1534-354']:= 0.00544;
   uvalc['aips']['1534-354']:= -0.00281;

   ivalc['aips']['1743-038']:= 4.484;
   qvalc['aips']['1743-038']:= -0.0925;
   uvalc['aips']['1743-038']:= 0.0609;

   ivalc['aips']['1751+096']:= 2.061;
   qvalc['aips']['1751+096']:= -0.134;
   uvalc['aips']['1751+096']:= 0.0646;
#   
# Iterate through all sources
#
   fldtab:= table('cals00feb.ms/FIELD');
   fldname:= fldtab.getcol('NAME');
   fldtab.close();

   for (field in fldname) {
      restoredname:= spaste(field, '.restored');
#
# Measure max abs in (I,Q,U,V)
#
      img1:= image(restoredname);
      pmax:= array(0.0, 4);
      for (plane in 1:4) { 
         pregion:= drm.box([1,1,plane], [256,256,plane]);
         img1.statistics(statsout=pstats, region=pregion);
         if (abs(pstats.min) > abs(pstats.max)) {
            pmax[plane]:= pstats.min;
         } else {
            pmax[plane]:= pstats.max;
         };
      };
      img1.done();
#
      ival:= pmax[1];
      qval:= pmax[2];
      uval:= pmax[3];
 
      ivalc['aipspp'][field]:= ival;
      qvalc['aipspp'][field]:= qval;
      uvalc['aipspp'][field]:= uval;
   };      

#
# Print AIPS-AIPS++ differences for moderately polarized sources
#
# 3C286 as reference
#
   q286a:= qvalc['aips']['1331+305'];
   u286a:= uvalc['aips']['1331+305'];
   chi286a:= 0.5 * atan2 (q286a, u286a);

   q286app:= qvalc['aipspp']['1331+305'];
   u286app:= uvalc['aipspp']['1331+305'];
   chi286app:= 0.5 * atan2 (q286app, u286app);

   for (field in ['1331+305','0854+201','1337-129','1751+096']) {
      ivala:= ivalc['aips'][field];
      qvala:= qvalc['aips'][field];
      uvala:= uvalc['aips'][field];
      pvala:= sqrt (qvala^2 + uvala^2);
      chivala:= 0.5 * atan2 (qvala, uvala) - chi286a + 33.0;

      ivalapp:= ivalc['aipspp'][field];
      qvalapp:= qvalc['aipspp'][field];
      uvalapp:= uvalc['aipspp'][field];
      pvalapp:= sqrt (qvalapp^2 + uvalapp^2);
      chivalapp:= 0.5 * atan2 (qvalapp, uvalapp) - chi286app + 33.0;

      print;
      print field, "I= ", sprintf("%7.3f", ivala), " Q= ", 
         sprintf("%7.3f", qvala), " U= ", sprintf("%7.3f", uvala), 
         " P= ", sprintf("%7.3f", pvala), " chi= ", sprintf("%7.2f", chivala),
         " AIPS";
      print field, "I= ", sprintf("%7.3f", ivalapp), " Q= ",
         sprintf("%7.3f", qvalapp), " U= ", sprintf("%7.3f", uvalapp), 
         " P= ", sprintf("%7.3f", pvalapp)," chi= ",sprintf("%7.2f",chivalapp),
         " AIPS++";
   };
#
