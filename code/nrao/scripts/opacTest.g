#
#
# OPACITY corrections demonstration script -- gmoellen (03Nov04)
#
# This script demos and tests ordinary G solving with and 
#  without opacity corrections, illustrating the importance of
#  the opacity corrections in the determination of the flux density
#  scale.
# The data used in this script is simulated: 6 antennas, 8 hours, 1 spw, 
#  1 channel, 60s integrations, full pol, 1 point source target, 2 point 
#  source calibrators.  Both calibrators are observed for 2 minutes each
#  between 13 minute target source scans.  The primary calibrator has a 
#  known flux density of 2.345 Jy, and is at RA=89deg,Dec=75deg; the 
#  secondary calibrator is 0.357 Jy, and is at RA=180deg,Dec=75deg,
#  but its flux density is considered "unknown" in the script.  The 
#  target is a 13 mJy point source 1 degree east of the secondary calibrator. 
#  The sources are circumpolar (always up), but the primary is in a
#  different direction (and so has different opacity effects).
#  The only systematic errors introduced in the simulation are opacity
#  (0.2n at zenith) and continuously varying G.  Noise (10mJy per integration)
#  has also been added.
#
# This script will be expanded to illustrate gain curve corrections
#  in the near future.

pragma include once;

include 'sysinfo.g';
include 'logger.g';
include 'ms.g';
include 'note.g';
include 'table.g';

system.output.olog := 'SSGTesting.log'

opacTest := function() {
stime := time();
nametest := 'Calibrater: opacity corrections test';

msname:='opacdemo.ms';

# Fill data from UVFITS (opacdemo.uvfits)
temp:=dos.dir();
if (!any(temp=='opacdemo.ms')) {
myms:=fitstoms(msfile=msname,
fitsfile='/home/bernoulli5/aips2data/opacdemo.uvfits');
myms.done();
}

# True flux densities (for later comparison)
tfd:=[2.345, 0.013, 0.357];

# Launch calibrater tool, initialize scratch columns
include 'calibrater.g'
mycal:=calibrater(filename=msname);
mycal.initcalset();

# Set flux density of primary calibrator
include 'imager.g'
myimgr:=imager(filename=msname)
myimgr.setjy(fieldid=1,fluxdensity=2.345);

myms:=ms(filename=msname);  # Will be used to calculate final flux densities


# First solve without using opacity
#----------------------------------
# solve for G
mycal.reset();
mycal.setdata(msselect='FIELD_ID IN [1,3]');
mycal.setsolve(type='G',table='cal.g',t=60,refant=1);
mycal.solve();
mycal.plotcal('AMP','cal.g');

# Note that the amplitude solutions contain the variation due to opacity.

mycal.fluxscale('cal.g','cal.g2','Source1','Source3')
mycal.plotcal('AMP','cal.g2');

# Note that the fluxscale result is consistent with the presumption
#  that the _average_ amplitude gain is the same for both calibrators, 
#  but that the difference varies substantially with time.  This cal
#  table will correct the gain variations well, but violates the fact
#  that the instrumental gains vary smoothly in time.  Flux densities
#  derived from this table will be incorrect.


# apply calibration to everything
mycal.reset();
mycal.setdata(msselect='FIELD_ID==1');
mycal.setapply(type='G',table='cal.g2',select='FIELD_ID==1');
mycal.correct();

mycal.reset();
mycal.setdata(msselect='FIELD_ID IN [2,3]');
mycal.setapply(type='G',table='cal.g2',select='FIELD_ID==3');
mycal.correct();

# Query ms for calibrated source flux densities
mfd:=[myms.ptsrc(1)[1], myms.ptsrc(2)[1], myms.ptsrc(3)[1]]
mfd:=floor(10000*mfd+0.5)/10000;
efd:=mfd-tfd;

#  "Ignoring opacity corrections:"
#  "----------------------------"
for (i in 1:3) {
 print spaste('Field ',i,': True=',tfd[i],
                          ' Meas=',mfd[i],
                          ' Err=',efd[i],
                          ' (',floor(1000*abs(efd[i]/tfd[i])+0.5)/10,'%)');
}

# Now solve using opacity:
#-------------------------
# solve for G
mycal.reset();
mycal.setdata(msselect='FIELD_ID IN [1,3]');
mycal.setapply(type='TOPAC',t=-1,opacity=0.2);
mycal.setsolve(type='G',table='calopac.g',t=60,refant=1);
mycal.solve();
mycal.plotcal('AMP','calopac.g');

# Note that the amplitude solutions do not contain the variation due 
#  to opacity; it has been accounted for by TOPAC.

mycal.fluxscale('calopac.g','calopac.g2','Source1','Source3')
mycal.plotcal('AMP','calopac.g2');

# Note that, although the SNR is different for the two calibrators (one
#  is much weaker), there are no systematic variations in the amplitude
#  gains between the two calibrators.  The flux density scale has thus
#  been more accurately transferred to the secondary calibrator.

# apply calibration to everything
mycal.reset();
mycal.setdata(msselect='FIELD_ID==1');
mycal.setapply(type='TOPAC',t=-1,opacity=0.2);
mycal.setapply(type='G',table='calopac.g2',select='FIELD_ID==1');
mycal.correct();

mycal.reset();
mycal.setdata(msselect='FIELD_ID IN [2,3]');
mycal.setapply(type='TOPAC',t=-1,opacity=0.2);
mycal.setapply(type='G',table='calopac.g2',select='FIELD_ID==3');
mycal.correct();

mycal.done();

# Query ms for calibrated source flux densities
mfd:=[myms.ptsrc(1)[1], myms.ptsrc(2)[1], myms.ptsrc(3)[1]]
mfd:=floor(10000*mfd+0.5)/10000;
efd:=mfd-tfd;

# "Using opacity corrections:" 
# "-------------------------"
#for (i in 1:3) {
# print spaste('Field ',i,': True=',tfd[i],
#                         ' Meas=',mfd[i],
#                         ' Err=',efd[i],
#                         ' (',floor(1000*abs(efd[i]/tfd[i])+0.5)/10,'%)');
#}

#---------------------------------------------------------------
#thistest := array(efd,3,1);
#result:=tablecreatearraycoldesc("opac-efd",as_float(1), 1, [3])
thistest := sum(efd)
col := tablecreatescalarcoldesc("opac-efd",as_float(1))
td:=tablecreatedesc(col)

temp:=dos.dir();
if (!any(temp=='testTable')) {
tab:=table("testTable", readonly=F, tabledesc=td, nrow = 1)
table('testTable').addcols(td);
table('testTable').putcol('opac-efd', thistest);
} else { 

for ( cname in  table('testTable').colnames()) {
  if(cname == 'opac-efd' ) {
    storedval := table('testTable').getcol('opac-efd');
    if( abs(storedval - thistest) < 0.05 )
      print spaste('### ', nametest, '... passed');
    else
      print spaste('### ', nametest, '... Faild ');
  }
}
if( !table('testTable').getcol('opac-efd') ) {
table('testTable').addcols(td);
table('testTable').putcol('opac-efd', thistest);
print '### Add a opac-efd column to testTable';
}

}
print "The pass criterion of this test is the difference of the ";
print "current sum of the efd vector with the first test is less ";
print "than 0.05.  efd = mfd - tfd ";
print "mfd = the calibrated source flux densities ";
print "tfd = the true flux densities tfd ";


etime := time();
print spaste('### Finished in run time = ', (etime - stime), ' seconds');
}
