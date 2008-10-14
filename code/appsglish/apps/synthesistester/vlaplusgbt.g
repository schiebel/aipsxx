# vlaplusgbt.g: test combination of VLA and GBT
#
#   Copyright (C) 1998,1999,2000,2001,2002
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
#   $Id: vlaplusgbt.g,v 19.1 2004/08/25 01:54:08 cvsmgr Exp $

include 'simulator.g';

vlaplusgbt := function() {

  stddisplay := function(name, FT=F) {
    include 'qv.g';
    if(!tableexists(name)) return;
    if(FT) {
      newname := spaste(name, '.ft');
      include 'table.g';
      tabledelete(newname);
      im:=image(name);im.fft(amp=newname);im.done();
      name:=newname;
    }
    q:=qv(name);
    q.colormap();
    q.label(name);
    q.papercolors();
    q.setoption('resample', 'bilinear');
    q.setoption('wedge', 'right');
    if(!FT) q.region(drm.quarter());
    q.writeps();
    q.done();
    simps  := spaste(name, '.ps');
    simjpg := spaste(name, '.jpg');
    shell (paste('convert ', simps, simjpg));
    shell (paste('rm -f ', simps));
  }
  
  
# pass in an image and simulate away;
  const sim:=function(modfile='', noise='0.0Jy', dovla=T, dogbt=T, sim=T,
		      gridfunction='pb', ftmachine='both', scale=1, weight=1,
		      algorithms='mem')
  {
    
    testdir := 'simBOTH';
    if(dovla&&!dogbt) testdir:='simVLA';
    if(!dovla&&dogbt) testdir:='simGBT';
    
    msname   := spaste(testdir, '/',testdir, '.ms');
    simmodel := spaste(testdir, '/',testdir, '.model');
    simsmodel:= spaste(testdir, '/',testdir, '.smodel');
    simpsf   := spaste(testdir, '/',testdir, '.psf');
    simempty := spaste(testdir, '/',testdir, '.empty');
    simmask  := spaste(testdir, '/',testdir, '.mask');
    simvp    := spaste(testdir, '/',testdir, '.vp');
    
    dir0 := dm.direction('j2000',  '0h0m0.0', '45.00.00.00');
    
    if(sim) {
      
      note('Cleaning up directory ', testdir);
      ok := shell(paste("rm -fr ", testdir));
      if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); };
      ok := shell(paste("mkdir", testdir));
      if (ok::status) { throw("mkdir", testdir, "fails!") };
      
      include 'vpmanager.g';
      vp:=vpmanager();
      if(dovla) vp.setcannedpb('VLA', commonpb='DEFAULT');
      if(dogbt) vp.setcannedpb('GBT', commonpb='NONE');
      vp.summarizevps(T);
      vp.saveastable(tablename=simvp);
      
      note('Create the empty measurementset');
      
      mysim := simulator();
      
      mysim.setspwindow(row=1, spwname='XBAND', freq='8.0GHz', deltafreq='50.0MHz',
			freqresolution='50.0MHz', nchannels=1, stokes='RR LL');
      
      if(dovla) {
	note('Simulating VLA');
	posvla := dm.observatory('vla');
#
#  Define VLA C array by hand, local coordinates
#
	xx := [41.1100006,134.110001,268.309998,439.410004,644.210022,880.309998,
	       1147.10999,1442.41003,1765.41003,-36.7900009,-121.690002,-244.789993,
	       -401.190002,-588.48999,-804.690002,-1048.48999,-1318.48999,-1613.98999,
	       -4.38999987,-11.29,-22.7900009,-37.6899986,-55.3899994,-75.8899994,
	       -99.0899963,-124.690002,-152.690002];
	yy := [3.51999998,-39.8300018,-102.480003,-182.149994,-277.589996,-387.839996,
	       -512.119995,-649.76001,-800.450012,-2.58999991,-59.9099998,-142.889999,
	       -248.410004,-374.690002,-520.599976,-685,-867.099976,-1066.42004,77.1500015,
	       156.910004,287.980011,457.429993,660.409973,894.700012,1158.82996,1451.43005,
	       1771.48999];
	zz := [0.25,-0.439999998,-1.46000004,-3.77999997,-5.9000001,-7.28999996,
	       -8.48999977,-10.5,-9.56000042,0.25,-0.699999988,-1.79999995,-3.28999996,
	       -4.78999996,-6.48999977,-9.17000008,-12.5299997,-15.3699999,1.25999999,
	       2.42000008,4.23000002,6.65999985,9.5,12.7700005,16.6800003,21.2299995,
	       26.3299999];
#
# We want roughly D configuration
#
	xx /:=3.3;
	yy /:=3.3;
	zz /:=3.3;
	
	diam := 0.0 * [1:27] + 25.0;
	mysim.setconfig(telescopename='VLA', x=xx, y=yy, z=zz, dishdiameter=diam, 
			mount='alt-az', antname='VLA',
			coordsystem='local', referencelocation=posvla);
	mysim.setfield(sourcename='M31SIM', sourcedirection=dir0,
		       integrations=1, xmospointings=5, ymospointings=5,
		       mosspacing=1.0);
	mysim.settimes('60s', '300s', T, '-14400s', '+14400s');
	mysim.create(newms=msname, shadowlimit=0.001, 
		     elevationlimit='8.0deg', autocorrwt=0.0);
      }
      
      if(dogbt) {
	note('Simulating GBT');
	posgbt := dm.observatory('gbt');
	mysim.setconfig(telescopename='GBT', x=[0.0], y=[0.0], z=[0.0],
			dishdiameter=[100.0], 
			mount='alt-az', antname='GBT',
			coordsystem='local', referencelocation=posgbt);
	mysim.setfield(sourcename='M31SIM', sourcedirection=dir0,
		       integrations=1, xmospointings=21, ymospointings=21,
		       mosspacing=1.0);
	mysim.settimes('1s', '1s', T, '14401s', '15283s');
	if(!dovla) {
	  mysim.create(newms=msname, shadowlimit=0.001, 
		       elevationlimit='8.0deg', autocorrwt=1.0);
	}
	else {
	  mysim.add(elevationlimit='8.0deg', autocorrwt=1.0);
	}
      }
      
      mysim.done();
      
      note('Make an empty image from the MS, and fill it with the');
      note('the model image;  this is to get all the coordinates to be right');
      
      if(modfile=='') {
	include 'sysinfo.g';
	note('Using standard M31 image');
	modfile := spaste(sysinfo().root(), '/data/demo/M31.model.fits');
      }
      myimg1 := image(modfile);   # this is the model image with bad coordinates
      imgshape := myimg1.shape();
      imsize := imgshape[1];
      
      myimager := imager(msname);
      myimager.setdata(mode="none" , nchan=1, start=1, step=1,
		       mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1:1000);
      myimager.setimage(nx=imsize, ny=imsize, cellx="2arcsec" , celly="2arcsec" ,
			stokes="I" , fieldid=1, facets=1, doshift=T,
			phasecenter=dir0);
      myimager.setoptions(ftmachine=ftmachine, gridfunction="pb");
      myimager.make(simmodel);
      myimager.done();
      
      myimg2 := image(simmodel);  #  this is the dummy image with correct coordinates
      arr1 := myimg1.getchunk();
      myimg2.putchunk( arr1 );      #  now this image has the model pixels and 
      #  the correct coordinates
      myimg1.done();
      myimg2.done();
      note('Made model image with correct coordinates');
      note('Read in the MS again and predict from this new image');
      
      mysim := simulatorfromms(msname);
      mysim.setoptions(ftmachine=ftmachine, gridfunction="pb");
      if(dovla) mysim.setvp(dovp=T, vptable=simvp, usedefaultvp=F);
      mysim.predict(simmodel);
      
      if(noise!='0.0Jy') {
	note('Add noise');
	mysim.setnoise(mode='simplenoise', simplenoise=noise);
	mysim.corrupt();
      }
      mysim.done();
      
    }
    
    myimg1 := image(modfile);   # this is the model image with incorrect coordinates
    imgshape := myimg1.shape();
    myimg1.done();
    
    cell:="20arcsec"; imsize:=imgshape[1]/10;
    if(dovla) {
      cell:="2arcsec"; imsize:=imgshape[1];
    }
    if(imsize%2) imsize+:=3;
    
    myimager := imager(msname);
    myimager.setdata(mode="none" , nchan=1, start=1, step=1,
		     mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1:1000);
    myimager.setimage(nx=imsize, ny=imsize, cellx=cell , celly=cell ,
		      stokes="I" , fieldid=1, facets=1, doshift=T,
		      phasecenter=dir0);
    myimager.setoptions(ftmachine=ftmachine, gridfunction=gridfunction);
    
    if(dovla) myimager.setvp(dovp=T, vptable=simvp, usedefaultvp=F);
    
    myimager.setmfcontrol(scaletype='SAULT');
    myimager.setsdoptions(weight=weight);
    myimager.weight(type="uniform", fieldofview="600arcsec");
    
    myimager.make(simempty);
    myimager.approximatepsf(model=simempty, psf=simpsf);
    bmaj:=F; bmin:=F; bpa:=F;
    myimager.fitpsf(simpsf, bmaj, bmin, bpa);
    myimager.smooth(simmodel, simsmodel, F, bmaj, bmin, bpa, normalize=F);
    
    myimager.regionmask(simmask, drm.quarter());
    
    for (algorithm in algorithms) {
      
      simimage := spaste(testdir, '/', testdir, '.', algorithm);
      simrest  := spaste(testdir, '/', testdir, '.', algorithm, '.restored');
      simresid := spaste(testdir, '/', testdir, '.', algorithm, '.residual');
      simerror := spaste(testdir, '/', testdir, '.', algorithm, '.error');
      
      tabledelete(simrest);
      tabledelete(simresid);
      tabledelete(simimage);
      
      if(algorithm=='mfclark') {
	myimager.setmfcontrol(scaletype='SAULT', cyclespeedup=10000);
	myimager.clean(algorithm='mfclark', niter=100000, gain=0.1, displayprogress=F,
		       model=simimage , image=simrest, residual=simresid,
		       mask=simmask);
      }
      else if(algorithm=='mfmultiscale'){
	myimager.setmfcontrol(scaletype='SAULT', cyclespeedup=100);
	myimager.setscales('uservector', uservector=[0, 6, 12]);
	myimager.clean(algorithm='mfmultiscale', niter=1000, gain=0.7,
		       displayprogress=F,
		       model=simimage , image=simrest, residual=simresid,
		       mask=simmask);
	
      }
      else if(algorithm=='mfentropy'){
	myimager.setmfcontrol(scaletype='SAULT', cyclespeedup=1);
	myimager.mem(algorithm='mfentropy', niter=30, displayprogress=F,
		     model=simimage , image=simrest, residual=simresid,
		     mask=simmask);
      }
      else {
	myimager.setmfcontrol(scaletype='SAULT');
	myimager.make(simempty);
	myimager.residual(model=simempty, image=simimage);
      }
      if(dovla&&tableexists(simrest)) {
	imagecalc(simerror, spaste('"', simrest, '" - "', simsmodel, '"')).done();
      }
      for (name in [simimage, simrest, simresid, simerror]) {
	stddisplay(name);
	stddisplay(name, T);
      }
    }
    
    for (name in [simsmodel, simmodel, simpsf]) {
      stddisplay(name);
      stddisplay(name, T);
    }
    myimager.done();
  }
  
  const feather:=function(algorithm='mfentropy', ftmachine='both', scale=1, weight=1,
			  gridfunction='pb') 
  {
    
    testdir := 'simBOTH';
    testhigh:='simVLA';
    testlow:='simGBT';
    
    msname    := spaste(testdir, '/',testdir, '.ms');
    simsmodel := spaste(testhigh, '/',testhigh, '.smodel');
    simlowpsf := spaste(testlow, '/',testlow, '.psf');
    simfeather:= spaste(testdir, '/',testdir, '.', algorithm, '.feather');
    simvp     := spaste(testdir, '/',testdir, '.vp');
    
    simlowres := spaste(testlow, '/', testlow, '.', algorithm, '.restored');
    simhighres := spaste(testhigh, '/', testhigh, '.', algorithm, '.restored');
    simerror := spaste(simfeather, '.error');
    
    dir0 := dm.direction('j2000',  '0h0m0.0', '45.00.00.00');
    
    cell:='2arcsec'; imsize:=512;
    myimager := imager(msname);
    myimager.setdata(mode="none" , nchan=1, start=1, step=1,
		     mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1:1000);
    myimager.setimage(nx=imsize, ny=imsize, cellx=cell , celly=cell ,
		      stokes="I" , fieldid=1, facets=1, doshift=T,
		      phasecenter=dir0);
    myimager.setoptions(ftmachine=ftmachine, gridfunction=gridfunction);
    
    myimager.setmfcontrol(scaletype='SAULT');
    myimager.setsdoptions(weight=weight);
    myimager.setvp(dovp=T, usedefaultvp=F, vptable=simvp);
    myimager.feather(simfeather, highres=simhighres, lowres=simlowres, 
		     lowpsf=simlowpsf);
    if(tableexists(simfeather)) {
      tabledelete(simerror);
      imagecalc(simerror,
		spaste('"', simfeather, '" - "', simsmodel, '"')).done();
    }
    for (name in [simfeather, simerror]) {
      stddisplay(name);
      stddisplay(name, T);
    }
    myimager.done();
  }
  
  stime := time();

  algorithms := "dirty psf mfentropy mfmultiscale mfclark";
  case := [[T, T], [F, T], [T, F]];
  for (i in 1:3) {
    note('Processing dovla=', case[2*i-1], ' dogbt=', case[2*i]);
    sim(dovla=case[2*i-1], dogbt=case[2*i], weight=10000.0, ftmachine='both', sim=T,
	algorithms=algorithms);
  }
  feather();

  note('Completed VLA plus GBT processing in ', time()-stime, ' seconds');

  return T;
}
