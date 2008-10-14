# synthesistest.g: Test of the synthesis system
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: synthesistest.g,v 19.2 2004/08/25 01:21:10 cvsmgr Exp $
#

pragma include once;

include "simulator.g"
include "imager.g"
include "calibrater.g"
include "componentlist.g"
include "demonstration.g"
include "viewer.g"
include 'catalog.g'

const synthesistest := function(componentnumbers=1:4,
				gain=[0.00, 0.05], leakage=0.001, noise='0.1Jy',
				seed=185349251) {
  
  global dowait := T;
  ntest := 0;
  results := [=];
  doshift:=T;
  
  ddemo.caption('This demonstrates use of many parts of the synthesis system. A data set is simulated  using the simulator tool and then imaged using imager and calibrater.', 'First we clean up some directories from previous runs and make a template MeasurementSet from an existing MeasurementSet.');

  testdir := 'synthesistest/';
  
  note('Cleaning up directory ', testdir);
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); }
  
  # Make the directory
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw("rm fails!") }
  ok := shell(paste("mkdir", testdir));
  if (ok::status) { throw("mkdir", testdir, "fails!") }
  
  # Start timing here
  note('## Start timing');
  stime:=time();
      
  # Make the data
  msfile:=spaste(testdir, '3C273XC1.ms');
  gainfile:=spaste(testdir, '3C273XC1.gain');
  clfile:=spaste(testdir, '3C273XC1.cl');
  nclfile:=spaste(testdir, '3C273XC1.fitted.cl');
  
  # Make the componentlist and MeasurementSet
  imagermaketestms(msfile);
  
  ddemo.caption('Our model is in the form of a componentlist of discrete components. The synthesis applications work with both images and componentlists.', 'The model componentlist is generated in a glish script but we have convertors from Caltech VLBI format, AIPS ST files, and WENSS, FIRST, and NVSS catalogs. Adding convertors is simple, requiring only glish scripting.');

  simulatormaketestcl(clfile, componentnumbers=componentnumbers);

  checkresult := function(ok, ntest, nametest, ref results) {
    
    results[ntest] := '';
    
    if(is_fail(ok)) {
      results[ntest] := paste("Test", ntest, " on ", nametest, "failed ", ok::message);
    }
    else if(is_boolean(ok)) {
      if(!ok) results[ntest] := paste("Test", ntest, " on ", nametest, "failed ", ok::message);
    }
    else {
      results[ntest] := paste("Test", ntest, " on ", nametest, "returned", ok);
    }
  }
   
  global myimager:=imager(filename=msfile);
  if(is_fail(myimager)) fail;
  
  # Choose a phase center not on the core
  phasecenter := [type="direction" , refer="B1950" ,
		  m1=[value=0.04061, unit="rad" ],
		  m0=[unit="rad" , value=-3.02575]];

  ddemo.caption('Fourier transforming model to the UV plane',
		'We use the imager tool ft function to do the Fourier transform');

  ok :=myimager.setimage(nx=256, ny=256, cellx="0.7arcsec" ,
			 celly="0.7arcsec" , stokes="IQUV" , 
			 doshift=doshift, phasecenter=phasecenter,
			 shiftx="0arcsec" ,
			 shifty="0arcsec" , mode='mfs' , nchan=1, start=1, step=1,
			 mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1, facets=1);
  if(is_fail(ok)) fail;
  
  ok :=myimager.make(image=spaste(testdir, "empty" ));
  if(is_fail(ok)) fail;
  ok :=myimager.ft(model=spaste(testdir, "empty"),
		   complist=clfile, incremental=F);
  if(is_fail(ok)) fail;

  ok :=myimager.done();
  if(is_fail(ok)) fail;
  
  global mysimulator:=simulator(filename=msfile);
  if(is_fail(mysimulator)) fail;
  
  ddemo.caption('Now we create the simulator tool and set it up to apply corruptions of various sorts', 'These corruptions use components that we insert into the MeasurementEquation. Instead of allowing solution for calibration effects, these components only calculate fake calibration errors. The MeasurementEquation formalism then automatically applies these errors to the OBSERVED_DATA column in the MeasurementSet, producing a CORRECTED_DATA column');

  #################################################################################
  
  ntest +:=1;
  nametest := 'simulator.setgain'; note(paste('###', nametest, '###'));
      
  ok :=mysimulator.setgain(mode="calculate" , table='', interval="10s" ,
			   amplitude=gain );
  
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  
  ntest +:=1;
  nametest := 'simulator.setleakage'; note(paste('###', nametest, '###'));
      
  ok :=mysimulator.setleakage(mode="calculate" , table='', interval="10s" ,
			      amplitude=leakage);

  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  
  ntest +:=1;
  nametest := 'simulator.setnoise'; note(paste('###', nametest, '###'));
     
  ok :=mysimulator.setnoise(mode="calculate" , table='', noise=noise);

  checkresult(ok, ntest, nametest, results);

  #################################################################################
  
  ntest +:=1;
  nametest := 'simulator.setpa'; note(paste('###', nametest, '###'));
      
  ok :=mysimulator.setpa(mode="calculate" , table='', interval="10s" );

  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  
  ntest +:=1;
  nametest := 'simulator.setseed'; note(paste('###', nametest, '###'));
      
  ok :=mysimulator.setseed(seed=seed);

  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  
  ntest +:=1;
  nametest := 'simulator.simulate'; note(paste('###', nametest, '###'));
      
  ok :=mysimulator.simulate();

  checkresult(ok, ntest, nametest, results);

  #################################################################################

  ntest +:=1;
  nametest := 'simulator.done'; note(paste('###', nametest, '###'));
      
  ok :=mysimulator.done();
  
  checkresult(ok, ntest, nametest, results);

  #################################################################################

  ddemo.caption('Now we construct an imager tool for this simulated MeasurementSet, and use this imager tool to image and clean the corrupted data.',	 'Available imager functions include advise, setimage, setdata, image, weight, filter, uvrange, restore, clean, nnls, fitpsf, smooth, plotuv, plotvis, plotweights, sensitivity, and more.');


  global myimager:=imager(filename=msfile);
  if(is_fail(myimager)) fail;

  #################################################################################
  ntest +:=1;
  nametest := 'imager.setimage'; note(paste('###', nametest, '###'));
  
  ok :=myimager.setimage(nx=256, ny=256, cellx="0.7arcsec" ,
			 celly="0.7arcsec" , stokes="I" , doshift=doshift,
			 phasecenter=phasecenter,
			 shiftx="0arcsec" ,
			 shifty="0arcsec" , mode='mfs' , nchan=1, start=1, step=1,
			 mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1, facets=1);

  checkresult(ok, ntest, nametest, results);

  #################################################################################
  ntest +:=1;
  nametest := 'imager.clean'; note(paste('###', nametest, '###'));
  
  for (algorithm in ['clark']) {
    ok :=myimager.clean(algorithm=algorithm , niter=10000, gain=0.1,
			threshold="0.35Jy" , displayprogress=F,
			model=spaste(testdir, algorithm, ".clean") , fixed=F,
			complist='', mask='',
			image=spaste(testdir, algorithm, ".clean.restored") ,
			residual=spaste(testdir, algorithm, ".clean.residual") );
    ok := ok && tableexists(spaste(testdir, algorithm, ".clean"));
    ok := ok && tableexists(spaste(testdir, algorithm, ".clean.restored"));
    ok := ok && tableexists(spaste(testdir, algorithm, ".clean.residual"));
    checkresult(ok, ntest, nametest, results);
  }

  #################################################################################
  ddemo.caption('Next we transform the Clean model using the imager.ft function, and then plot the visibility.', 'Plotting is performed using PGPLOT with an AIPS++ interactive interface that allows editing of the list of plot commands');

  ntest +:=1;
  nametest := 'imager.ft'; note(paste('###', nametest, '###'));
  
  ok :=myimager.ft(model=spaste(testdir, algorithm, ".clean") ,
		   complist='', incremental=F);

  checkresult(ok, ntest, nametest, results);

  #################################################################################
  if(0) {
    ntest +:=1;
    nametest := 'imager.plotvis'; note(paste('###', nametest, '###'));
	
    ok :=myimager.plotvis();
    checkresult(ok, ntest, nametest, results);
  }

  #################################################################################
  ntest +:=1;
  nametest := 'imager.restore'; note(paste('###', nametest, '###'));
  
  ok :=myimager.restore(model=spaste(testdir, algorithm, ".clean") ,
			complist='', 
			image=spaste(testdir, algorithm, ".clean.restored") ,
			residual=spaste(testdir, algorithm, ".clean.residual") );
  ok := ok && tableexists(spaste(testdir, algorithm, ".clean.restored"));
  ok := ok && tableexists(spaste(testdir, algorithm, ".clean.residual"));
  checkresult(ok, ntest, nametest, results);

  #################################################################################
  # Now show the image

  ddemo.caption('We can now display the clean image using the viewer tool.', 'Starting the viewer tool requires loading a shared object library which takes 20-30 seconds. This delay occurs only the first time that viewer is used. ')

  ntest +:=1;
  nametest := 'dc.view'; note(paste('###', nametest, '###'));

  ok := dc.view(spaste(testdir, algorithm, ".clean.restored"));

  checkresult(ok, ntest, nametest, results);

  ddemo.caption('Use the statistics window to check the noise level', 'To set a region, select a shape on the left, and then set the shape by clicking the boundaries. Finally double-click inside the region to signify that the region is complete. Regions may also be dragged around.');

  #################################################################################

  ddemo.caption('To improve the image, we will self-calibrate the image using the calibrater tool.',
		'calibrater uses the MeasurementEquation to solve and apply calibration corrections. First we define which terms in the MeasurementEquation are to be activated, and then we solve for them using a generic non-linear solver. In this example, we solve for antenna-based phase terms only.')

  global mycalibrater:=calibrater(filename=msfile);
  if(is_fail(mycalibrater)) fail;
  
  #################################################################################

  ntest +:=1;
  nametest := 'calibrater.setsolve'; note(paste('###', nametest, '###'));

  ok :=mycalibrater.setsolve('G', t=10, phaseonly=T, table=gainfile);
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  ntest +:=1;
  nametest := 'calibrater.solve'; note(paste('###', nametest, '###'));

  ok :=mycalibrater.solve();
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  ntest +:=1;
  nametest := 'calibrater.correct'; note(paste('###', nametest, '###'));

  ok :=mycalibrater.correct();
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  if(0) {
    ntest +:=1;
    nametest := 'calibrater.done'; note(paste('###', nametest, '###'));
    ok :=mycalibrater.done();
    checkresult(ok, ntest, nametest, results);
  }
  
  #################################################################################
  
  ddemo.caption('Next we will clean the self-calibrated data and display the resulting image.',
		'To do this, we can use the imager that is still running. The AIPS++ locking system takes care of notifying imager that the data have changed and must be re-read.');

  ntest +:=1;
  nametest := 'imager.setimage'; note(paste('###', nametest, '###'));

  ok :=myimager.setimage(nx=256, ny=256, cellx="0.7arcsec" ,
			 celly="0.7arcsec" , stokes="I" , doshift=doshift,
			 phasecenter=phasecenter,
			 shiftx="0arcsec" ,
			 shifty="0arcsec" , mode='mfs' , nchan=1, start=1, step=1,
			 mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1, facets=1);
  checkresult(ok, ntest, nametest, results);

  #################################################################################
  ntest +:=1;
  nametest := 'imager.clean'; note(paste('###', nametest, '###'));
  
  for (algorithm in ['clark']) {
    ok :=myimager.clean(algorithm=algorithm , niter=10000, gain=0.1,
			threshold="0.Jy" , displayprogress=F,
			model=spaste(testdir, algorithm, ".sclean") , fixed=F,
			complist='', mask='',
			image=spaste(testdir, algorithm, ".sclean.restored") ,
			residual=spaste(testdir, algorithm, ".sclean.residual") );
    ok := ok && tableexists(spaste(testdir, algorithm, ".sclean"));
    ok := ok && tableexists(spaste(testdir, algorithm, ".sclean.restored"));
    ok := ok && tableexists(spaste(testdir, algorithm, ".sclean.residual"));
    checkresult(ok, ntest, nametest, results);
  }

  #################################################################################
  ntest +:=1;
  nametest := 'imager.ft'; note(paste('###', nametest, '###'));
  
  ok :=myimager.ft(model=spaste(testdir, algorithm, ".sclean") ,
		   complist='', incremental=F);

  checkresult(ok, ntest, nametest, results);

  #################################################################################
  if(0) {
    ntest +:=1;
    nametest := 'imager.plotvis'; note(paste('###', nametest, '###'));
	
    ok :=myimager.plotvis();
    checkresult(ok, ntest, nametest, results);
  }

  #################################################################################
  ntest +:=1;
  nametest := 'imager.restore'; note(paste('###', nametest, '###'));
  
  ok :=myimager.restore(model=spaste(testdir, algorithm, ".sclean") ,
			complist='', 
			image=spaste(testdir, algorithm, ".sclean.restored") ,
			residual=spaste(testdir, algorithm, ".sclean.residual") );
  ok := ok && tableexists(spaste(testdir, algorithm, ".sclean.restored"));
  ok := ok && tableexists(spaste(testdir, algorithm, ".sclean.residual"));
  checkresult(ok, ntest, nametest, results);

  #################################################################################

  ntest +:=1;
  nametest := 'imager.done'; note(paste('###', nametest, '###'));
      
  ok :=myimager.done();
  
  checkresult(ok, ntest, nametest, results);

  #################################################################################

  # Now show the image
  global myimage := image(spaste(testdir, algorithm, ".sclean.restored"));

  if(is_fail(myimage)) fail;

  comp := [=];

  #################################################################################

  ddemo.caption('Finally, we will use the image tool to fit components to the self-calibrated image.',
		'Here we use the fitter in batch mode. There is an interactive version, imagefitter, also available. The fitsky function returns the fitted component.');

  ntest +:=1;
  nametest := 'image.fitsky'; note(paste('###', nametest, '###'));

  pixels := F; mask := F; converged := F;
  ok := myimage.fitsky(pixels=pixels, pixelmask=mask, converged=converged,
		      region=drm.box(blc=[115, 130], trc=[130,150]));

  if(!is_fail(ok)) {
    note('First sky component is ', ok.component(1));
    comp[1] := ok.component(1);
  }
  checkresult(is_record(ok), ntest, nametest, results);
  #################################################################################
  ntest +:=1;
  nametest := 'image.fitsky'; note(paste('###', nametest, '###'));

  pixels := F; mask := F; converged := F;
  ok := myimage.fitsky(pixels=pixels, pixelmask=mask, converged=converged,
		      region=drm.box(blc=[130, 105], trc=[155, 130]));

  if(!is_fail(ok)) {
    note('Second sky component is ', ok.component(1));
    comp[2] := ok.component(1);
  }
  checkresult(is_record(ok), ntest, nametest, results);

  #################################################################################

  ntest +:=1;
  nametest := 'image.done'; note(paste('###', nametest, '###'));
      
  ok :=myimage.done();
  
  checkresult(ok, ntest, nametest, results);

  #################################################################################

  global ecl := emptycomponentlist();
  if(is_fail(ecl)) fail;

  ntest +:=1;
  nametest := 'componentlist.add'; note(paste('###', nametest, '###'));

  ok :=ecl.add(comp[1], iknow=T);
  checkresult(ok, ntest, nametest, results);

  #################################################################################

  ntest +:=1;
  nametest := 'componentlist.add'; note(paste('###', nametest, '###'));

  ok :=ecl.add(comp[2], iknow=T);
  checkresult(ok, ntest, nametest, results);

  #################################################################################

  ntest +:=1;
  nametest := 'componentlist.rename'; note(paste('###', nametest, '###'));

  ok :=ecl.rename(nclfile);
  checkresult(ok, ntest, nametest, results);

  #################################################################################

  ntest +:=1;
  nametest := 'componentlist.edit'; note(paste('###', nametest, '###'));
  ok :=ecl.edit(2);
  checkresult(ok, ntest, nametest, results);

  #################################################################################

  ntest +:=1;
  nametest := 'componentlist.done'; note(paste('###', nametest, '###'));

  ok :=ecl.done();
  checkresult(ok, ntest, nametest, results);

  #################################################################################
  # Now show the image

  ddemo.caption('To end, we show the final cleaned and self-calibrated image',
		'Note the large decrease in noise level.');

  ntest +:=1;
  nametest := 'dc.view'; note(paste('###', nametest, '###'));

  ok := dc.view(spaste(testdir, algorithm, ".sclean.restored"));

  checkresult(ok, ntest, nametest, results);

  #################################################################################

  if(0) {
    ntest +:=1;
    nametest := 'visplot'; note(paste('###', nametest, '###'));
    
    global myvisplot:=visplot(msfile);
    checkresult(is_record(myvisplot), ntest, nametest, results);
  }

  #################################################################################

  nfailed := 0;
  for (result in results) {
    if(result!='') {
      nfailed+:=1;
      note(result);
    }
  }
    
  ddemo.caption('That\'s it!')

  if(nfailed>0) {

    etime:=time();
    note(sprintf('Finished with %d failure(s) in run time = %5.2f seconds', nfailed,
		(etime-stime)));
  
    return F;
  }
  else {

    etime:=time();
    note(sprintf('Finished with complete success in run time = %5.2f seconds', 
		(etime-stime)));
    return T;
  
  }
}

