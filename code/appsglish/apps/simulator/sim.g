include 'simulator.g';

# pass in an image and simulate away;
const sim:=function(modfile='', noise='0.0Jy', doaca=T, doalma=T, dosd=T, sim=T,
		    gridfunction='pb', ftmachine='both', scale=1, weight=1,
		    algorithms='mem')
{

  include 'logger.g';
  dl.purge(0);
  include 'webpublish.g';

  testdir := 'sim';
  if(doaca) testdir:=spaste(testdir,'+ACA');
  if(doalma) testdir:=spaste(testdir,'+ALMA');
  if(dosd) testdir:=spaste(testdir,'+SD');

  if(sim) {
    note('Cleaning up directory ', testdir);
    ok := shell(paste("rm -fr ", testdir));
    if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); };
    ok := shell(paste("mkdir", testdir));
    if (ok::status) { throw("mkdir", testdir, "fails!") };
  }

  resultsdir := spaste(testdir, '/results');
  webpub:=webpublish(spaste(resultsdir, '/index.html'),
		     spaste('AIPS++ simulation of ALMA observations and processing. This includes ', testdir ~ s/sim\+//g, ' observations.</p>'));
  if(is_fail(webpub)) fail;
		     
  webpub.comments('This simulates processing of ALMA observations.</p>');

  msname   := spaste(testdir, '/',testdir, '.ms');
  simmodel := spaste(testdir, '/',testdir, '.model');
  simsmodel:= spaste(testdir, '/',testdir, '.smodel');
  simtemp  := spaste(testdir, '/',testdir, '.temp');
  simpsf   := spaste(testdir, '/',testdir, '.psf');
  simempty := spaste(testdir, '/',testdir, '.empty');
  simmask  := spaste(testdir, '/',testdir, '.mask');
  simvp    := spaste(testdir, '/',testdir, '.vp');

  dir0 := dm.direction('j2000',  '0h0m0.0', '-45.00.00.00');
  reftime := dm.epoch('iat', '2001/01/01');

  if(modfile=='') {
    include 'sysinfo.g';
    sysroot := sysinfo().root();
    modfile:=spaste(sysroot, '/data/demo/M31.model.fits');
  }
  note('The model is ', modfile);

  if(sim) {

    include 'vpmanager.g';
    vp:=vpmanager();
    if(dosd) vp.setcannedpb('ALMASD', commonpb='NONE');
    if(doaca) vp.setcannedpb('ACA', commonpb='DEFAULT');
    if(doalma) vp.setcannedpb('ALMA', commonpb='DEFAULT');
    vp.summarizevps(T);
    vp.saveastable(tablename=simvp);

    note('Create the empty measurementset');
    
    mysim := simulator();
    
    posalma := dm.observatory('alma');
    posaca := dm.observatory('alma');

    mysim.setspwindow(row=1, spwname='FOO', freq='130GHz', deltafreq='1MHz',
		      freqresolution='1MHz', nchannels=1, stokes='RR LL');
    
    include 'readSTN.g';

    if(doaca) {
      note('Simulating ACA');
      rec:=readSTN('ACA.STN');
      mysim.setconfig(telescopename='ACA', x=rec.xx, y=rec.yy, z=rec.zz, 
                      dishdiameter=rec.diam, 
		      mount='equatorial', antname='ACA',
		      coordsystem='local', referencelocation=posaca);
      mysim.setfield(sourcename='M31SIM', sourcedirection=dir0,
		     integrations=1, xmospointings=5, ymospointings=5,
		     mosspacing=1.0);
      mysim.settimes('1s', '1s', T, '0s', '+50s', referencetime=reftime);
      if(!tableexists(msname)) {
	mysim.create(newms=msname, shadowlimit=0.001, 
		     elevationlimit='8.0deg', autocorrwt=0.0);
      }
      else {
	mysim.add(elevationlimit='8.0deg', autocorrwt=0.0);
      }
    }
    
    if(dosd) {
      note('Simulating ALMA single dish observations');
      mysim.setconfig(telescopename='ALMASD', x=0., y=0., z=0., 
                      dishdiameter=12.0, 
		      mount='alt-az', antname='ALMA',
		      coordsystem='local', referencelocation=posalma);
      mysim.setfield(sourcename='M31SIM', sourcedirection=dir0,
		     integrations=1, xmospointings=21, ymospointings=21,
		     mosspacing=1.0);
      mysim.settimes('1s', '1s', T, '1001s', '1882s', referencetime=reftime);
      if(!tableexists(msname)) {
	mysim.create(newms=msname, shadowlimit=0.001, 
		     elevationlimit='8.0deg', autocorrwt=64.0);
      }
      else {
	mysim.add(elevationlimit='8.0deg', autocorrwt=64.0);
      }
    }

    if(doalma) {
      note('Simulating ALMA interferometric observations');
      rec:=readSTN('ALMA.E.STN');
      mysim.setconfig(telescopename='ALMA', x=rec.xx, y=rec.yy, z=rec.zz, 
                      dishdiameter=rec.diam, 
		      mount='alt-az', antname='ALMA',
		      coordsystem='local', referencelocation=posalma);
      mysim.setfield(sourcename='M31SIM', sourcedirection=dir0,
		     integrations=1, xmospointings=21, ymospointings=21,
		     mosspacing=1.0);
      mysim.settimes('1s', '1s', T, '1s', '882s', referencetime=reftime);
      if(!tableexists(msname)) {
	mysim.create(newms=msname, shadowlimit=0.001, 
		     elevationlimit='8.0deg', autocorrwt=0.0);
      }
      else {
	mysim.add(elevationlimit='8.0deg', autocorrwt=0.0);
      }
    }
    mysim.done();

    note('Make an empty image from the MS, and fill it with the');
    note('the model image;  this is to get all the coordinates to be right');
    
    myimg1 := image(modfile);   # this is the model image with bad coordinates
    imgshape := myimg1.shape();
    imsize := imgshape[1];
    arr1 := myimg1.getchunk();
    myimg1.done();
    
    myimager := imager(msname);
    myimager.setdata(mode="none" , nchan=1, start=1, step=1,
		     mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1:1000);
    myimager.setimage(nx=imsize, ny=imsize,
		      cellx="0.6arcsec" , celly="0.6arcsec" ,
		      stokes="I" , fieldid=1, facets=1, doshift=T,
		      phasecenter=dir0);
    myimager.setoptions(ftmachine=ftmachine, gridfunction="pb");
    myimager.make(simmodel);
    myimager.done();
    
    myimg2 := image(simmodel);  #  this is the dummy image with correct coordinates
    myimg2.statistics();
    myimg2.putchunk( arr1 );      #  now this image has the model pixels and coords
    myimg2.summary();
    myimg2.statistics();
    myimg2.done();

    note('Made model image with correct coordinates');
    note('Read in the MS again and predict from this new image');
    
    mysim := simulatorfromms(msname);
    mysim.setoptions(ftmachine=ftmachine, gridfunction="pb");
    mysim.setvp(dovp=T, vptable=simvp, usedefaultvp=F);
    mysim.predict(simmodel);
    
    if(noise!='0.0Jy') {
      note('Add noise');
      mysim.setnoise(mode='simplenoise', simplenoise=noise);
      mysim.corrupt();
    }
    mysim.done();
    
  }
  
  webpub.comments('<p>The original model (including a copy in FITS format )</p>');
  for (name in [simmodel]) {
    if(tableexists(name)) webpub.image(name, name, dofits=T);
  }
  webpub.flush();

  myimg1 := image(modfile);   # this is the model image with incorrect coordinates
  imgshape := myimg1.shape();
  myimg1.done();
  
  cell:="6arcsec"; imsize:=imgshape[1]/10;
  if(imsize%2) imsize+:=3;
  if(doalma||doaca) {
    cell:="0.6arcsec"; imsize:=imgshape[1];
  }

  myimager := imager(msname);
  myimager.setdata(mode="none" , nchan=1, start=1, step=1,
		   mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1:1000);
  myimager.setimage(nx=imsize, ny=imsize, cellx=cell , celly=cell ,
		    stokes="I" , fieldid=1, facets=1, doshift=T,
		    phasecenter=dir0);
  myimager.setoptions(ftmachine=ftmachine, gridfunction=gridfunction);
  myimager.setvp(dovp=T, vptable=simvp, usedefaultvp=F);

  myimager.setmfcontrol(scaletype='SAULT');
  myimager.setsdoptions(weight=weight);
  myimager.weight(type="uniform");

  myimager.make(simempty);
  myimager.approximatepsf(model=simempty, psf=simpsf);
  bmaj:=F; bmin:=F; bpa:=F;
  myimager.fitpsf(simpsf, bmaj, bmin, bpa);

  if(!(doaca||doalma)) {
    im:=image(simempty);
    shape:=im.shape();
    cs:=im.coordsys();
    cs.summary()
    im.done();
    myimager.smooth(simmodel, simtemp, F, bmaj, bmin, bpa, normalize=F);
    im:= image(simtemp);
    im.regrid(outfile=simsmodel, shape=shape, csys=cs, axes=[1,2]);
    im.done();
  }
  else {
    myimager.smooth(simmodel, simsmodel, F, bmaj, bmin, bpa, normalize=F);
  }


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
    if(tableexists(simrest)) {
      imagecalc(simerror, spaste('"', simrest, '" - "', simsmodel, '"')).done();
    }
    webpub.comments(spaste('<p>The images for ', algorithm, ' image processing</p>'));
    for (name in [simimage, simrest, simresid, simerror]) {
      if(tableexists(name)) webpub.image(name, name);
    }
    webpub.flush();
  }

  webpub.comments('The smoothed model, and psf</p>');
  for (name in [simsmodel, simpsf]) {
    if(tableexists(name)) webpub.image(name, name);
  }
  webpub.flush();

  myimager.done();

  webpub.log();
  webpub.script('sim.g');
  webpub.done();
}

include 'logger.g';
dl.purge(0);
sim('m31.bigimage', doaca=F, doalma=T, dosd=T, weight=2000.0, ftmachine='both',
    sim=T, algorithms="dirty mfentropy");
