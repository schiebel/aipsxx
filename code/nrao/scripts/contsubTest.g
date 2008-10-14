# Continuum subtraction demo script
#  Adapted from VLA HI line data reduction demo
#
#  This script fills and calibrates the NGC5921 dataset,
#   then demonstrates continuum subtraction in both the
#   uv and image planes.

#It fills, flags (ACs), and calibrates the uv data, then (1) forms a
#cont+line image, from which the continuum is subtracted, and (2) subtracts
#the continuum in the uv-plane and forms a line-only image.  The results
#from boths types of subtraction can then be compared in the viewer (a good
#example of blinking).  Note that, implicitly, the B solution demos
#scan-based solutions (though there is only one scan in solve), and the G
#solution demos the "solution intervals referenced to scan boundaries".
#
#  2003Oct21 gmoellen

pragma include once;

include 'sysinfo.g';
include 'imager.g';
include 'calibrater.g';
include 'image.g';
include 'ms.g';
include 'flagger.g';
include 'logger.g';
include 'table.g';

#dl.purge(0);

system.output.olog := 'SSGTesting.log'

contsubTest := function() {
stime := time()
nametest := 'Continuum subtraction test';

doFill:=T;
doFlag:=T;
doCal:=T;
doImage:=T;

#
# VLA H_I line data reducion: NGC 5921
#
# Load the data
#

temp:=dos.dir();
if (!any(temp=='ngc5921.ms')) {
 aipsroot:=sysinfo().root();                   # Assemble name of UVFITS file
 fitsfilename:=spaste(aipsroot, '/data/demo/NGC5921.fits');
 msetS := fitstoms(msfile='ngc5921.ms',        # Line dataset
                   fitsfile=fitsfilename);
 msetS.summary(verbose=T);                     # Obtain summary
 msetS.close()();                                 # Finish ms tool
 msetS.done();                                 # Finish ms tool
};

#
# Basic editing
#   
if (doFlag) {
 include 'flagger.g'
 fgS:=flagger('ngc5921.ms');           # Make flagger tool
 fgS.flagac();                         # flag ACs
 fgS.done();                           # Finish flagger tool:
};

#
# Set source model
#

if (doCal) {
 include 'imager.g'
 imgrS:=imager('ngc5921.ms');       # Start imager tool  
 imgrS.setjy(fieldid=1,                    
             fluxdensity=[14.8009,0,0,0]); # Set 1331+305 (3C286) model
 imgrS.done();

#
# Calibrate
#
 calS := calibrater('ngc5921.ms');

# G first
 calS.reset();
 calS.setdata(msselect='FIELD_ID <= 2');
 calS.setsolve(type='G', t=300.0, refant=15,
               table='ngc5921.gcal');
 calS.state();
 calS.solve();
 calS.plotcal(tablename='ngc5921.gcal');



# flux scale
 calS.fluxscale(tablein='ngc5921.gcal',
                tableout='ngc5921.fluxcal',
                reference='1331+30500002',
                transfer=['1445+09900002']);
 calS.plotcal(tablename='ngc5921.fluxcal');

# now B, using G
 calS.reset();
 calS.setdata(msselect='FIELD_ID==1');
 calS.setapply(type='G', t=0.0,
               table='ngc5921.gcal',
               select='FIELD_ID==1');
 calS.setsolve(type='B', t=0.0, refant=15,
               table='ngc5921.bcal');
 calS.state();
 calS.solve();
 calS.plotcal(tablename='ngc5921.bcal');

# now apply both B and G to all 
 calS.reset();
 calS.setapply(type='B',
               table='ngc5921.bcal');   

# first do 3C286 with its G
 calS.setdata(msselect='FIELD_ID==1');  
 calS.setapply(type='G', t=0.0,
               table='ngc5921.fluxcal', 
               select='FIELD_ID==1');
 calS.correct();

# now do target and cal with cals G
 calS.setdata(msselect='FIELD_ID > 1');  
 calS.setapply(type='G', t=0.0,
               table='ngc5921.fluxcal', 
               select='FIELD_ID==2');
 calS.correct();

 calS.done();

 include 'msplot.g';
 mymp:=msplot('ngc5921.ms');

};

if (doImage) {
#
# Make a cont+line channel map of NGC 5921  (uv channels 6-57)
#
 imgrS:=imager('ngc5921.ms');       # Start imager tool  
 imgrS.setdata(fieldid=3, mode='channel',  # Select data for field 3, spectral
               spwid=1, nchan=52, start=6, #  window 1 and all channels 
               step=1);           
 imgrS.setimage(nx=256, ny=256, stokes='I',          # Imaging parameters
                cellx='10arcsec', celly='10arcsec', 
                start=6, step=1, nchan=52,
                mode='channel',fieldid=3);
 imgrS.weight(type='natural');                       # Uniform weighting
 
 temp:=dos.dir();
 if (any(temp=='ngc5921.image1')) shell('rm -rf ngc5921.image1');
 if (any(temp=='ngc5921.model1')) shell('rm -rf ngc5921.model1');
 if (any(temp=='ngc5921.residual1')) shell('rm -rf ngc5921.residual1');

 imgrS.clean(algorithm='clark', niter=3000,          # Image and deconvolve
             threshold='0.0Jy',                      # with Clark CLEAN
             model='ngc5921.model1', 
             image='ngc5921.image1',
             residual='ngc5921.residual1');

#
# Subtract continuum (uv channels 6-9, 54-57) in image plane:
#

 im:=image('ngc5921.image1');
 
 if (any(temp=='ngc5921.line1')) shell('rm -rf ngc5921.line1');
 if (any(temp=='ngc5921.cont11')) shell('rm -rf ngc5921.cont1');

subim:=im.continuumsub(outline='ngc5921.line1',
                        outcont='ngc5921.cont1',
                        channels=[1:4,49:52],    # image plane channel nums!
                        fitorder=0);

subim.statistics(statsout=teststats, list=F);
#rms := teststats.rms;
 im.done();
 subim.done();


#
# Subtract continuum (uv channels 6-9, 54-57) in uv plane:
#   (performance is poor here because uvlsf is in glish)
#
 msetS := ms('ngc5921.ms',readonly=F)
 msetS.uvlsf(fldid=3,
             spwid=1,
             chans=[6:9,54:57],
             solint=30,
             fitorder=0,
             mode='subtract');
msetS.close(); 
msetS.done();

#
# Image continuum-subtracted uv-data (uv chans 6-57, as above):
#
 if (any(temp=='ngc5921.line2')) shell('rm -rf ngc5921.line2');
 if (any(temp=='ngc5921.model2')) shell('rm -rf ngc5921.model2');
 if (any(temp=='ngc5921.residual2')) shell('rm -rf ngc5921.residual2');

 imgrS.clean(algorithm='clark', niter=3000,          # Image and deconvolve
             threshold='0.0Jy',                      # with Clark CLEAN
             model='ngc5921.model2', 
             image='ngc5921.line2',
             residual='ngc5921.residual2');

imgrS.close();
imgrS.done();
}

#-------------------------------------------------------------
thistest := teststats.rms;
col:=tablecreatescalarcoldesc("contsub-rms",as_float(1))
td:=tablecreatedesc(col)

temp:=dos.dir();
if (!any(temp=='testTable')) {
tab:=table("testTable", readonly=F, tabledesc=td, nrow = 1)
table('testTable').addcols(td);
table('testTable').putcol('contsub-rms', thistest);
} else {

     for ( cname in  table('testTable').colnames()) {
       if(cname == 'contsub-rms' ) {
         storedval := table('testTable').getcol('contsub-rms');
         if(abs(storedval - thistest) < 0.05)
           print spaste('### ', nametest, '... passed');
         else
           print spaste('### ', nametest, '... Faild ');
       }
     }
     if( !table('testTable').getcol('contsub-rms') ) {
       table('testTable').addcols(td);
       table('testTable').putcol('contsub-rms', thistest);
       print "### add a column to table";
     }
}

print "The pass criterion of this test is the difference of the " ;
print "image statistics rms of the current testing image containing ";
print "the continuum-subtracted result with the first testing result ";
print "is less than 5%. ";

etime := time();
print spaste('### Finished in run time = ', (etime - stime), ' seconds');

}
