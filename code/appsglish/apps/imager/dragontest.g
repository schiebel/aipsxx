# dragontest.g: Test dragon
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: dragontest.g,v 19.1 2004/08/25 01:19:45 cvsmgr Exp $
#

pragma include once;

include "dragon.g";
include "simulator.g";
include "componentlist.g";
include "sysinfo.g";

const dragontest := function(fitsfile='', doimage=T, dofind=T) {
  if(fitsfile==''){
    aipsroot:=sysinfo().root();
    fitsfile:=spaste(aipsroot, '/data/demo/3DDAT.fits')
  }
  compo_making := function(clfile='simu.comp') {
    cl:=emptycomponentlist();
    components := [=];
    cl.addcomponent(flux=[100.0, 0, 0, 0] , fluxunit="Jy" ,
		    polarization="Stokes", shape="Gaussian",
		    dirframe='j2000', ra='16:00:00', dec='50.00.00', 
		    decunit='angle', majoraxis=[value=0.11, unit="arcmin" ],
		    minoraxis=[value=0.1, unit="arcmin" ],
		    positionangle=[value=0.0, unit="rad"], 
		    spectrumtype='constant', 
		    freq=[unit="GHz" , value=0.0738]);
    cl.addcomponent(flux=[100.0, 0, 0, 0] , fluxunit="Jy" ,
		    polarization="Stokes",shape="Gaussian",
		    dirframe='j2000', ra='16:00:00', dec='46.00.00', 
		    decunit='angle', majoraxis=[value=0.11, unit="arcmin" ],
		    minoraxis=[value=0.1, unit="arcmin" ],
		    positionangle=[value=0.0, unit="rad"], 
		    spectrumtype='constant', 
		    freq=[unit="GHz" , value=0.0738]);
    cl.addcomponent(flux=[100.0, 0, 0, 0] , fluxunit="Jy" ,
		    polarization="Stokes",shape="Gaussian",
		    dirframe='j2000', ra='15:38:00', dec='47.00.00', 
		    decunit='angle', majoraxis=[value=0.11, unit="arcmin" ],
		    minoraxis=[value=0.1, unit="arcmin" ],
		    positionangle=[value=0.0, unit="rad"], 
		    spectrumtype='constant', 
		    freq=[unit="GHz" , value=0.0738]);

    cl.addcomponent(flux=[100.5, 0, 0, 0] , fluxunit="Jy" ,
		    polarization="Stokes",shape="Gaussian",
		    dirframe='j2000', ra='15:27:00', dec='52.00.00', 
		    decunit='angle', 
		    majoraxis=[value=0.11, unit="arcmin" ],
		    minoraxis=[value=0.1, unit="arcmin" ],
		    positionangle=[value=0.0, unit="rad"], 
		    spectrumtype='constant', 
		    freq=[unit="GHz" , value=0.0738]);    
    cl.addcomponent(flux=[100.0, 0, 0, 0] , fluxunit="Jy" ,
		    polarization="Stokes",shape="Gaussian",
		    dirframe='j2000', ra='16:00:00', dec='54.00.00', 
		    decunit='angle', majoraxis=[value=0.11, unit="arcmin" ],
		    minoraxis=[value=0.1, unit="arcmin" ],
		    positionangle=[value=0.0, unit="rad"], 
		    spectrumtype='constant', 
		    freq=[unit="GHz" , value=0.0738]);  

    cl.addcomponent(flux=[100.5, 0, 0, 0] , fluxunit="Jy" ,
		    polarization="Stokes",shape="Gaussian",
		    dirframe='j2000', ra='16:33:00', dec='53.00.00', 
		    decunit='angle', majoraxis=[value=0.11, unit="arcmin" ],
		    minoraxis=[value=0.1, unit="arcmin" ],
		    positionangle=[value=0.0, unit="rad"], 
		    spectrumtype='constant', 
		    freq=[unit="GHz" , value=0.0738]);  

    cl.addcomponent(flux=[100.5, 0, 0, 0] , fluxunit="Jy" ,
		    polarization="Stokes",shape="Gaussian",
		    dirframe='j2000', ra='16:30:00', dec='48.00.00', 
		    decunit='angle', majoraxis=[value=0.11, unit="arcmin" ],
		    minoraxis=[value=0.1, unit="arcmin" ],
		    positionangle=[value=0.0, unit="rad"], 
		    spectrumtype='constant', 
		    freq=[unit="GHz" , value=0.0738]);  


    
 
    cl.rename(clfile);
    cl.close();
    
  }
  
  checkresult := function(ok, funcname) {
    
    if(is_fail(ok)){
      
      note(paste("failed in ",funcname), origin='dragontest');
    }
    else if(is_boolean(ok)){
      if(!ok) note(paste("failed in ",funcname), origin='dragontest');
    }
    else {
      note(paste(funcname," returned ",ok), origin='dragontest');
    }
    
  }
  
  find_source := function( filename, fluxlev){
    animage := image(filename);
    csys := animage.coordsys();
    axes := animage.shape();
    print 'axes are ', axes;
    imagearray := animage.getchunk(blc=[1, 1], trc=[axes[1], axes[2]]);
    peak:=10000000;
    xpeak:=100000000;
    ypeak:=100000000;
    compnum:=0;
    cl:=emptycomponentlist();
    while( peak > fluxlev){
      peak := 0; 
      for (k in 6:(axes[1]-5)){
	for (j in 6:(axes[2]-5)){
	  if (imagearray[k,j] > peak){
	    
	    if((imagearray[k+5,j] < imagearray[k,j]) &&  (imagearray[k,j+5] < imagearray[k,j]) &&
	       (imagearray[k-5,j] < imagearray[k,j]) && (imagearray[k,j-5] < imagearray[k,j])) {
	      peak:=imagearray[k,j];
	      xpeak := k;
	      ypeak := j;
	    }
	  }
	}
      }
      if (peak > fluxlev){
	print xpeak, ypeak;
	box1:=drm.box([xpeak-5, ypeak-5], [xpeak+5, ypeak+5]);
	local resipix, conver, mask;
	fitcomp:=animage.fit2d(pixels=resipix,mask=mask,converged=conver,models="gaussian",
			       region=box1);
	if(conver){
	  cl.add(fitcomp.component(1));
	  for (k in 1:11){
	    for (j in 1:11){
	      imagearray[xpeak+k-6, ypeak+j-6]:=resipix[k,j];
	    }
	  }
	}
      }
    }
    
#### May do level by levelof flux and use substr_model
    
    cl.rename(paste(filename,".components",sep=""));
    
    print 'No of sources found= ',cl.length();
    
    cl.close();
    cl.done();
    animage.close();
    animage.done();
    
  }

# Start of test code

  include 'os.g';
  if(!dos.fileexists(fitsfile)) {
    return throw('Test FITS file ', fitsfile, ' not found');
  }

  testdir := 'dragontest';

  note('Cleaning up directory ', testdir, origin='dragontest');
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); };
  
  # Make the directory
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw("rm fails!") }
  ok := shell(paste("mkdir", testdir));
  if (ok::status) { throw("mkdir", testdir, "fails!") };
  
  # Make the data
  msfile:=spaste(testdir, '/','three.ms');
  clfile := spaste(testdir, '/', 'simu.comp');
  imagefile := spaste(testdir, '/', 'dragon');
  residualfile := spaste(testdir, '/', 'dragon.residual');
  restoredfile := spaste(testdir, '/', 'dragon.restored');
  newclfile := spaste(testdir, '/', 'dragon.comp');

  note('Making test MeaurementSet ', msfile, ' from ', fitsfile, origin='dragontest');
  myms := fitstoms(msfile, fitsfile, T, F);
  myms.done();
  compo_making(clfile);
  
### simulating components
  note('Simulating components', origin='dragontest');

  mysim:=simulatorfromms(msfile);
  mysim.predict(complist=clfile);
  mysim.setnoise(noise='0.2Jy');
  mysim.setgain(interval='60s', amplitude=[0.01, 0.01]);
  ok:=mysim.corrupt();
  mysim.close();
  mysim.done();
  
######done simulating
  checkresult(ok, 'simulation');
  
##########################
  if(!doimage) {
    note('Successfully completed simulation', origin='dragontest');
    return T;
  }

  note('Running dragon', origin='dragontest');
  mydrag:=dragon(msfile);
  note('Test Image is ', imagefile, origin='dragontest');
  mydrag.setimage(name=imagefile,nx=1280, ny=1280, cellx='30arcsec', celly='30arcsec',
		  doshift=F, phasecenter=dm.direction('J2000','0deg', '0deg'),
		  mode='mfs', facets=9);
  mydrag.uvrange(uvmin=0, uvmax=10000);
  ok :=mydrag.weight(type="uniform" , rmode="none" , noise="0Jy" , robust=0,
		     fieldofview="0rad" ,
		     npixels=500);
  ok:=mydrag.setoptions(padding=1.4, cache=0);
  ok:=mydrag.image(levels="3Jy 1.2Jy 0.5Jy",amplitudelevel='0.7Jy',
		   timescales="60s 10s 10s",
		   niter=50000, gain=0.05, threshold='0.45Jy', plot=F, display=F);
  mydrag.done();

####over with dragon######
  checkresult(ok, 'dragon');

##########################

  if(!dofind) {
    note('Successfully completed imaging', origin='dragontest');
    return T;
  }
  note('Finding sources', origin='dragontest');  
  ok:=find_source(residualfile,40);
  
  checkresult(ok,'find_source');
  
  note('Checking sources', origin='dragontest');  
  compo_found:=componentlist(newclfile);
  compo_true:=componentlist(clfile);
  if(compo_true.length()!=compo_found.length()){
    print 'Number of found components is ',compo_found.length(),'; should have been ',
    compo_true.length();
  }
  else{
    
    for (k in 1:compo_true.length()){
      distmin:=100000;
      ra_true:=dq.convert( compo_true.getrefdir(k).m0, 'rad').value;
      dec_true:=dq.convert( compo_true.getrefdir(k).m1, 'rad').value;
      for(j in 1:compo_found.length()){
	dist:=  ra_true- dq.convert( compo_found.getrefdir(j).m0, 'rad').value;
	dist:= dist^2 + (dec_true- dq.convert(compo_found.getrefdir(j).m1, 'rad').value)^2;
	dist:=sqrt(dist);
	if (dist < distmin){
	  distmin:=dist; 
	  jmin:=j;
	}
      }
      print 'Nearest source to simulated component ', k, 'is at', distmin/pi*180*60,
      'arcmin and is found comp ', jmin;
      print 'True RA is ', (ra_true+2*pi)/pi*12, ' Found ra is ',
      (dq.convert(compo_found.getrefdir(jmin).m0, 'rad').value+2*pi)/pi*12;
      print 'True dec is ', dec_true*180.0/pi, ' Found dec is ',
      dq.convert(compo_found.getrefdir(jmin).m1, 'deg').value;
      print 'True flux is ', compo_true.component(k).flux.value, 'Found flux is ',
      compo_found.component(jmin).flux.value;
    }
  }
  note('Successfully completed all phases of dragontest', origin='dragontest');

  return T;
}
