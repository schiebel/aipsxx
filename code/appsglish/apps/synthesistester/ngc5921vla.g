
include 'imager.g';
include 'calibrater.g';
include 'image.g';
include 'ms.g';
include 'flagger.g';

#
# VLA H_I line data reducion: NGC 5921
#
# Clean up the work directory
#
   dirname:='ngc5921';
   ok:= shell(paste("rm -fr", dirname));
   ok:= shell(paste("mkdir", dirname));
#
# Load the data
#
   aipsroot:=sysinfo().root();
   fitsfilename:=spaste(aipsroot, '/data/demo/NGC5921.fits');
   m:=fitstoms(fitsfile=fitsfilename, msfile='ngc5921/ngc5921.ms');
   m.summary(verbose=T);
   m.done();
#
# Basic editing
#
   fg:=flagger('ngc5921/ngc5921.ms');
   fg.setflagmode('unflag');
   fg.query(query='FIELD_ID >= 0');
#
# Flag data for 1331+305
#
   fg.setflagmode('flag');
   fg.setids(fieldid=1);
   fg.filter(column='DATA', operation='range', comparison='Amplitude',
             range=['0.0Jy','1.6Jy']);
#
# Flag data for 1445+099
#   
   fg.setflagmode('flag');
   fg.setids(fieldid=2);
   fg.filter(column='DATA', operation='range', comparison='Amplitude',
             range=['0.0Jy','0.4Jy']);
#
# Flag data for NGC 5921
#
   fg.setflagmode('flag');
   fg.setids(fieldid=3);
   fg.filter(column='DATA', operation='range', comparison='Amplitude',
             range=['0.0Jy','0.11Jy']);
   fg.done();
#
# Set source model
#
   imagr:=imager('ngc5921/ngc5921.ms');
   imagr.setjy(fieldid=1, fluxdensity=[14.8009,0,0,0]);
   imagr.done();
#
# Solve for G Jones using pseudo-continuum
#
   cal:=calibrater('ngc5921/ngc5921.ms');
   cal.setdata(msselect='FIELD_ID <= 2');
   cal.setsolve(type='G', t=300.0, preavg=300.0, refant=15, 
                table='ngc5921/ngc5921.gcal');
   cal.solve();
#
# Establish the flux density scale
#
   cal.fluxscale(tablein='ngc5921/ngc5921.gcal', 
                 tableout='ngc5921/ngc5921.gcalout',
                 reference='1331+30500002',
                 transfer=['1445+09900002']);

   cal.plotcal(tablename='ngc5921/ngc5921.gcalout');
   cal.done();
#
# Solve for B Jones (bandpass)
#
   cal:=calibrater('ngc5921/ngc5921.ms');
   cal.setdata(msselect='FIELD_ID==1');
   cal.setapply(type='G', t=0.0, table='ngc5921/ngc5921.gcalout');
   cal.setsolve(type='B', t=86400.0, preavg= 86400.0, refant=15, 
                table='ngc5921/ngc5921.bcal');
   cal.solve();
   cal.plotcal(tablename='ngc5921/ngc5921.bcal');
   cal.done();
#
# Correct the line data for G and B Jones
#
   cal:=calibrater('ngc5921/ngc5921.ms');
   cal.setapply(type='G', t=0.0, table='ngc5921/ngc5921.gcalout', 
                select='FIELD_ID==2');
   cal.setapply(type='B', t=0.0, table='ngc5921/ngc5921.bcal');
   cal.correct();
   cal.done();
#
# Make a map of NGC 5921
#
   imagr:= imager('ngc5921/ngc5921.ms');
   imagr.setdata(fieldid=3, mode='channel', nchan=63, start=1, step=1,
                 spwid=1);
   imagr.setimage(nx=256, ny=256, cellx='10arcsec', celly='10arcsec', 
                  stokes='I', fieldid=3, spwid=1, start=1, step=1, nchan=63,
                  mode='channel');
   imagr.weight();
   imagr.make('ngc5921/ngc5921.model');
   imagr.clean(algorithm='clark', niter=3000, gain=0.1, threshold='0.0Jy',
               model='ngc5921/ngc5921.model', image='ngc5921/ngc5921.restored',
               residual='ngc5921/ngc5921.residual');
#
# Final restore
#
   imagr.restore(model='ngc5921/ngc5921.model', 
                 image='ngc5921/ngc5921.restored2');
   imagr.done();
#
# Subtract mean continuum channels (5-8, 55-58) using image tool
#
   im:=imagefromimage(outfile='ngc5921/ngc5921.restored3', 
                      infile='ngc5921/ngc5921.restored2');
   im.done();

   im:=image('ngc5921/ngc5921.restored3');
   offregion:=drm.box([1,1,1,55],[256,256,1,58]);
   imsub:=im.subimage(region=offregion);
   imsub.moments(outfile='ngc5921/ngc5921.model.cont55-58',moments=-1,axis=4);
   imsub.done();
   offregion:=drm.box([1,1,1,5],[256,256,1,8]);
   imsub:=im.subimage(region=offregion);
   imsub.moments(outfile='ngc5921/ngc5921.model.cont5-8',moments=-1,axis=4);
   imsub.done();
   imoff1:=image('ngc5921/ngc5921.model.cont55-58');
   imoff2:=image('ngc5921/ngc5921.model.cont5-8');
   im.calc('$im - $imoff1/2 - $imoff2/2');
   im.done();
#
# View final image
#
   im:=image('ngc5921/ngc5921.restored3');
   im.view();
#
# End
#
