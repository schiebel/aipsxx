# deconvolver.g: Deconvolves images
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
#   $Id: deconvolver.g,v 19.3 2005/03/02 01:20:19 kgolap Exp $
#

pragma include once

include "general.g"
include "servers.g"
include "widgetserver.g"
include "imager.g"

#defaultservers.suspend(T)
#defaultservers.trace(T)

# Users aren't to use this.
const _define_deconvolver := function(ref agent, id) {
    self := [=]
    public := [=]

    self.agent := ref agent;
    self.id := id;

    self.openRec := [_method="open", _sequence=self.id._sequence]
    public.open := function(dirtyname='', psfname='') {
	wider self;
	self.openRec.thedirty := dirtyname;
	self.openRec.thepsf := psfname;
	returnval := defaultservers.run(self.agent, self.openRec);
        return returnval;
    }


    self.reopenRec := [_method="reopen", _sequence=self.id._sequence]
    public.reopen := function() {
	wider self;
	returnval := defaultservers.run(self.agent, self.reopenRec);
        return returnval;
    }

    self.closeRec := [_method="close", _sequence=self.id._sequence]
    public.close := function() {
	wider self;
        return defaultservers.run(self.agent, self.closeRec);
    }

    self.dirtynameRec := [_method="dirtyname", _sequence=self.id._sequence]
    public.dirtyname := function() {
	wider self;
        return defaultservers.run(self.agent, self.dirtynameRec);
    }

    self.psfnameRec := [_method="psfname", _sequence=self.id._sequence]
    public.psfname := function() {
	wider self;
        return defaultservers.run(self.agent, self.psfnameRec);
    }

    self.summaryRec := [_method="summary", _sequence=self.id._sequence]
    public.summary:=function() {
        wider self;
        return defaultservers.run(self.agent, self.summaryRec);
    }

    self.stateRec := [_method="state", _sequence=self.id._sequence]
    public.state:=function() {
        wider self;
        return defaultservers.run(self.agent, self.stateRec);
    }

    self.restoreRec := [_method="restore", _sequence=self.id._sequence]
    public.restore:=function(model='', image='',
			     ref bmaj='0rad', ref bmin='0rad', ref bpa='0deg',
			     async=!dowait) {
        wider self;
	self.restoreRec.model:=model;
	self.restoreRec.image:=image;
	self.restoreRec.bmaj:=bmaj;
	self.restoreRec.bmin:=bmin;
	self.restoreRec.bpa:=bpa;
	returnval := defaultservers.run(self.agent, self.restoreRec, async);
        if(!async) {
	  val bmaj:=self.restoreRec.bmaj;
	  val bmin:=self.restoreRec.bmin;
	  val bpa:=self.restoreRec.bpa;
	}
        return returnval;
    }

    self.residualRec := [_method="residual", _sequence=self.id._sequence]
    public.residual:=function(model='', image='',
			      async=!dowait) {
        wider self;
	self.residualRec.model:=model;
	self.residualRec.image:=image;
	return defaultservers.run(self.agent, self.residualRec, async);
    }

    self.cleanRec := [_method="clean", _sequence=self.id._sequence]
    public.clean:=function(algorithm='hogbom', niter=1000, gain=0.1,
			   threshold='0Jy',  displayprogress=F,
			   model='', mask='', async=!dowait) {
        wider self;
	self.cleanRec.algorithm:=algorithm;
	self.cleanRec.niter:=niter;
	self.cleanRec.gain:=gain;
	self.cleanRec.threshold:=threshold;
	self.cleanRec.displayprogress:=displayprogress;
	self.cleanRec.model:=model;
	self.cleanRec.mask:=mask;
	returnval := defaultservers.run(self.agent, self.cleanRec, async);
        return returnval;
    }

    self.makeRec := [_method="make", _sequence=self.id._sequence]
    public.make:=function(image='', async=!dowait) {
	wider self;
	self.makeRec.image:=image;
	returnval := defaultservers.run(self.agent, self.makeRec, async);
        return returnval;
    }

    self.clarkcleanRec := [_method="clarkclean", _sequence=self.id._sequence]
    public.clarkclean:=function(niter=1000, gain=0.1,
		       		threshold='0Jy', displayprogress=F, 
				model='', mask='', 
				histbins=500, psfpatchsize=[51,51], maxextpsf=0.2,
				speedup=0.0, maxnumpix=10000, 
				maxnummajcycles=-1, maxnummineriter=-1,
			   	async=!dowait) {
        wider self;
	self.clarkcleanRec.niter:=niter;
	self.clarkcleanRec.gain:=gain;
	self.clarkcleanRec.threshold:=threshold;
	self.clarkcleanRec.displayprogress:=displayprogress;
	self.clarkcleanRec.model:=model;
	self.clarkcleanRec.mask:=mask;
	self.clarkcleanRec.histbins:=histbins;
	self.clarkcleanRec.psfpatchsize:=psfpatchsize;
	self.clarkcleanRec.maxextpsf:=maxextpsf;
	self.clarkcleanRec.speedup:=speedup;
	self.clarkcleanRec.maxnumpix:=maxnumpix;
	self.clarkcleanRec.maxnummajcycles:=maxnummajcycles;
	self.clarkcleanRec.maxnummineriter:=maxnummineriter;
	returnval := defaultservers.run(self.agent, self.clarkcleanRec, async);
        return returnval;
    }

    self.pixonRec := [_method="pixon", _sequence=self.id._sequence]
    public.pixon:=function(sigma='0.001Jy', 
			   model='', imageplane=T, async=!dowait) {
        wider self;
	self.pixonRec.sigma:=sigma;
	self.pixonRec.model:=model;
	self.pixonRec.imageplane:=imageplane;
	returnval := defaultservers.run(self.agent, self.pixonRec, async);
        return returnval;
    }

    self.memRec := [_method="mem", _sequence=self.id._sequence]
    public.mem:=function(entropy='entropy', niter=20, sigma='0.001Jy', 
			 targetflux='1.0Jy', constrainflux=F, displayprogress=F, 
	                 model='', prior='', mask='',
			 imageplane=F, async=!dowait) {
        wider self;
	self.memRec.entropy:=entropy;
	self.memRec.niter:=niter;
	self.memRec.sigma:=sigma;
	self.memRec.targetflux:=targetflux;
	self.memRec.constrainflux:=constrainflux;
	self.memRec.displayprogress:=displayprogress;
	self.memRec.model:=model;
	self.memRec.prior:=prior;
	self.memRec.mask:=mask;
        self.memRec.imageplane:=imageplane;
	returnval := defaultservers.run(self.agent, self.memRec, async);
        return returnval;
    }


    self.makepriorRec := [_method="makeprior", _sequence=self.id._sequence]
    public.makeprior:=function(prior='', templateimage='',
			lowclipfrom='0.0Jy', lowclipto='0.0Jy', 
			highclipfrom='9e20Jy', highclipto='9e20Jy', 
			blc=[], trc=[], async=!dowait) {
        wider self;
	self.makepriorRec.prior:=prior;
	self.makepriorRec.templateimage:=templateimage;
	self.makepriorRec.lowclipfrom:=lowclipfrom;
	self.makepriorRec.lowclipto:=lowclipto;
	self.makepriorRec.highclipfrom:=highclipfrom;
	self.makepriorRec.highclipto:=highclipto;
	self.makepriorRec.blc:=blc;
	self.makepriorRec.trc:=trc;
	returnval := defaultservers.run(self.agent, self.makepriorRec, async);
        return returnval;
    }

    self.setscalesRec := [_method="setscales", _sequence=self.id._sequence]
    public.setscales:=function(scalemethod='nscales', 
	nscales=5, uservector=[0.0,3.0,10.0], async=!dowait) {
        wider self;
	self.setscalesRec.scalemethod:=scalemethod;
	self.setscalesRec.nscales:=nscales;
	self.setscalesRec.uservector:=uservector;
	returnval := defaultservers.run(self.agent, self.setscalesRec, async);
        return returnval;
    }

    self.ftRec := [_method="ft", _sequence=self.id._sequence]
    public.ft:=function(model='', transform='', async=!dowait) {
        wider self;
	self.ftRec.model:=model;
	self.ftRec.transform:=transform;
	return defaultservers.run(self.agent, self.ftRec, async);
    }

    self.smoothRec := [_method="smooth", _sequence=self.id._sequence]
    public.smooth:=function(model='', image='',
			    bmaj='0rad', bmin='0rad', bpa='0deg',
			    normalize=T, async=!dowait) {
        wider self;
	self.smoothRec.model:=model;
	self.smoothRec.image:=image;
	self.smoothRec.bmaj:=bmaj;
	self.smoothRec.bmin:=bmin;
	self.smoothRec.bpa:=bpa;
	self.smoothRec.normalize:=normalize;
	returnval := defaultservers.run(self.agent, self.smoothRec, async);
        if(!async) {
	  val bmaj:=self.smoothRec.bmaj;
	  val bmin:=self.smoothRec.bmin;
	  val bpa:=self.smoothRec.bpa;
	}
        return returnval;
      }

    self.clipimageRec := [_method="clipimage", _sequence=self.id._sequence]
    public.clipimage:=function(clippedimage='', inputimage='',
			threshold='0.0Jy', async=!dowait) {
        wider self;
	self.clipimageRec.clippedimage:=clippedimage;
	self.clipimageRec.inputimage:=inputimage;
	self.clipimageRec.threshold:=threshold;
	returnval := defaultservers.run(self.agent, self.clipimageRec, async);
        return returnval;
    }

    self.boxmaskRec := [_method="boxmask", _sequence=self.id._sequence]
    public.boxmask :=function(mask='', blc=[], trc=[], 
		     	fillvalue='1.0Jy', outsidevalue='0.0Jy', 
			async=!dowait) {
        wider self;
	self.boxmaskRec.mask:=mask;
	self.boxmaskRec.blc:=blc;
	self.boxmaskRec.trc:=trc;
	self.boxmaskRec.fillvalue:=fillvalue;
	self.boxmaskRec.outsidevalue:=outsidevalue;
	returnval := defaultservers.run(self.agent, self.boxmaskRec, async);
        return returnval;
    }

    self.convolveRec := [_method="convolve", _sequence=self.id._sequence]
    public.convolve := function(convolvedmodel='', model='', async=!dowait) {
	wider self;
	self.convolveRec.convolvedmodel:=convolvedmodel;
	self.convolveRec.model:=model;
	returnval := defaultservers.run(self.agent, self.convolveRec, async);
        return returnval;
    }

    self.makegaussianRec := [_method="makegaussian", _sequence=self.id._sequence]
    public.makegaussian:=function(gaussianimage='',
			     bmaj='0rad', bmin='0rad', bpa='0deg',
			     normalize=T,
			     async=!dowait) {
        wider self;
	self.makegaussianRec.gaussianimage:=gaussianimage;
	self.makegaussianRec.bmaj:=bmaj;
	self.makegaussianRec.bmin:=bmin;
	self.makegaussianRec.bpa:=bpa;
	self.makegaussianRec.normalize:=normalize;
	returnval := defaultservers.run(self.agent, self.makegaussianRec, async);
        return returnval;
    }

    public.id := function() {
	wider self;
	return self.id.objectid;
    }

    public.done := function()
    {
        wider self, public;
        ok := defaultservers.done(self.agent, public.id());
        if (ok) {
            self := F;
            val public := F;
        }
        return ok;
    }

    public.updatestate := function(ref f, method) {
        if (method == 'INIT') {
  	    tf:=dws.frame(f, side='left');
            f.text := dws.text(tf);
            vsb:=dws.scrollbar(tf);
            whenever vsb->scroll do f.text->view($value);
            whenever f.text->yscroll do vsb->view($value);
            f.text->insert(public.state(), 'end');
        } else if (method == 'DONE') {
            f.text := F; # cleanup
        } else if (method == 'close') {
            f.text->delete('start', 'end');
            f.text->insert('deconvolver closed', 'start');
        } else {
            f.text->delete('start', 'end');
            f.text->insert(public.state(), 'start');
        }
        return T;
    }

    public.type := function() {
      return 'deconvolver';
    }

    plugins.attach('deconvolver', public);
    return ref public;

} # _define_deconvolver()


# Make a new server for every invocation
const deconvolver := function(dirtyname, psfname='', host='', forcenewserver=T) {
    agent := defaultservers.activate("deconvolver", host, forcenewserver)
    id := defaultservers.create(agent, "deconvolver", "deconvolver",
                        [thedirty=dirtyname, thepsf=psfname]);
    return ref _define_deconvolver(agent,id);

} # deconvolver()

const deconvolvertester := function(filename='3C273XC1.ms', size=256,
				    cell='0.7arcsec', stokes='I',
				    coordinates='b1950',
				    host='', forcenewserver=F)
{
    newimager:=imagertester(filename, size, cell, stokes, coordinates, host,
			   forcenewserver);
    newimager.makeimage('observed', spaste(filename, '.dirty'),async=F);
    newimager.makeimage('psf', spaste(filename, '.psf'),async=F);
    newimager.done();
    agent := defaultservers.activate("deconvolver", host, forcenewserver)
    id := defaultservers.create(agent, "deconvolver", "deconvolver",
                        [thedirty=spaste(filename, '.dirty'),
			 thepsf=spaste(filename, '.psf')]);
    newdeconvolver :=  _define_deconvolver(agent,id);   
    return ref newdeconvolver;
}


const deconvolverlongtest := function() {


  global dowait := T;
  ntest := 0;
  results := [=];
  
  testdir := 'deconvolverlongtest/';
  
  
  note('Cleaning up directory ', testdir);
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); }

  # Make the directory
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw("rm fails!") }
  ok := shell(paste("mkdir", testdir));
  if (ok::status) { throw("mkdir", testdir, "fails!") }

  # Make the data
  msfile:=spaste(testdir, '3C273XC1.ms');
  dirtyfile:=spaste(testdir, '3C273XC1.dirty');
  psffile:=spaste(testdir, '3C273XC1.psf');

  # Make the MeasurementSet, dirty, and psf
  imagermaketestms(msfile);
  newimager:=imager(msfile);
  newimager.setimage(nx=256, ny=256, cellx='0.7arcsec', celly='0.7arcsec');
  newimager.makeimage('observed', dirtyfile, async=F);
  newimager.makeimage('psf', psffile, async=F);
  newimager.done();

  # Start timing here
  note('## Start timing');
  stime:=time()

  #################################################################################

  global mydeconvolver:=deconvolver(dirtyname=dirtyfile, psfname=psffile);
  if(is_fail(mydeconvolver)) fail;

  checkresult := function(ok, ntest, nametest, ref results) {
    if(is_fail(ok)) {
      results[ntest] := paste("Test", ntest, " on ", nametest, "failed ", ok::message);
    }
    else if(is_boolean(ok)) {
      if(ok) {
        results[ntest] := paste("Test", ntest, " on ", nametest, "succeeded");
      }
      else {
        results[ntest] := paste("Test", ntest, " on ", nametest, "failed ", ok::message);
      }
    }
    else {
      results[ntest] := paste("Test", ntest, " on ", nametest, "returned", ok);
    }
  }

  #################################################################################

  nametest := 'boxmask';
  note('Test deconvolver.boxmask');
  maskfile:=spaste(testdir, '3C273XC1.mask');
  maskfile2:=spaste(testdir, '3C273XC1.mask2');
  
    ntest +:=1;
    ok :=mydeconvolver.boxmask(mask=maskfile, blc=[120,110,0,0], 
	trc=[150,133,0,0], fillvalue='1.0Jy', outsidevalue='0.0Jy');
    checkresult(ok, ntest, nametest, results);

    ntest +:=1;
    ok :=mydeconvolver.boxmask(mask=maskfile2, blc=[110,64,0,0], 
	trc=[180,150,0,0], fillvalue='1.0Jy', outsidevalue='0.0Jy');
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'clarkclean';
  note('Test deconvolver.clarkclean');
  clarkcleanfile1:=spaste(testdir, '3C273XC1.clarkclean1');
  clarkcleanfile2:=spaste(testdir, '3C273XC1.clarkclean2');
  
    ntest +:=1;
    mydeconvolver.clarkclean(niter=1000, gain=0.1,
		       		threshold='0Jy', displayprogress=F, 
				model=clarkcleanfile1, mask='', 
				histbins=500, psfpatchsize=[51,51], maxextpsf=0.2,
				speedup=0.0, maxnumpix=10000, 
				maxnummajcycles=-1, maxnummineriter=-1);
    ok :=  tableexists(clarkcleanfile1);
    checkresult(ok, ntest, nametest, results);
    ntest +:=1;
#    mydeconvolver.reopen();
    mydeconvolver.clarkclean(niter=1000, gain=0.1,
		       		threshold='0Jy', displayprogress=F, 
				model=clarkcleanfile2, mask=maskfile, 
				histbins=500, psfpatchsize=[51,51], maxextpsf=0.2,
				speedup=0.0, maxnumpix=10000, 
				maxnummajcycles=-1, maxnummineriter=-1);
    ok :=  tableexists(clarkcleanfile2);
    checkresult(ok, ntest, nametest, results);
 
  #################################################################################

  nametest := 'setscales';
  note('Test deconvolver.setscales');
  
    ntest +:=1;
    ok :=mydeconvolver.setscales(scalemethod="nscales", nscales=4);
    checkresult(ok, ntest, nametest, results);

    ntest +:=1;
    ok :=mydeconvolver.setscales(scalemethod="uservector", uservector=[0.0,2.5,6.0] );
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'clean';
  note('Test deconvolver.clean');

  hogcleanfile:=spaste(testdir, '3C273XC1.hogclean');
  mscleanfile:=spaste(testdir, '3C273XC1.msclean');
  mscleanmaskfile:=spaste(testdir, '3C273XC1.mscleanmask');

    ntest +:=1;
#    mydeconvolver.reopen();
    mydeconvolver.setscales(scalemethod="nscales", nscales=1);
    mydeconvolver.clean(algorithm='hogbom', niter=1000, gain=0.1,
			   threshold='0Jy', displayprogress=F, 
			   model=hogcleanfile, mask=maskfile);
    ok :=  tableexists(hogcleanfile);
    checkresult(ok, ntest, nametest, results);

    ntest +:=1;
#    mydeconvolver.reopen();
    mydeconvolver.setscales(scalemethod="nscales", nscales=3);
    mydeconvolver.clean(algorithm='msclean', niter=200, gain=0.2,
			   threshold='0Jy',displayprogress=F, 
			    model=mscleanfile, mask='');
    ok :=  tableexists(mscleanfile);
    checkresult(ok, ntest, nametest, results);
  
    ntest +:=1;
#    mydeconvolver.reopen();
    mydeconvolver.setscales(scalemethod="nscales", nscales=3);
    mydeconvolver.clean(algorithm='msclean', niter=200, gain=0.2,
			   threshold='0Jy', displayprogress=F, 
			   model=mscleanmaskfile, mask=maskfile2);
    ok :=  tableexists(mscleanmaskfile);
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'ft';
  note('Test deconvolver.ft');
  xformfile:=spaste(testdir, '3C273XC1.fft');
  
    ntest +:=1;
    ok :=mydeconvolver.ft(model=mscleanfile, transform=xformfile);
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'make';
  note('Test deconvolver.make');
  blankfile:=spaste(testdir, '3C273XC1.blank');

    ntest +:=1;
    ok :=mydeconvolver.make(image=blankfile);
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'smooth';
  note('Test deconvolver.smooth');
  smoothfile1:=spaste(testdir, '3C273XC1.smooth1');
  smoothfile2:=spaste(testdir, '3C273XC1.smooth2');
 
    ntest +:=1;
    ok :=mydeconvolver.smooth(model=mscleanfile, image=smoothfile1,
	bmaj='3arcsec', bmin='3arcsec', bpa='0deg', normalize=T);
    checkresult(ok, ntest, nametest, results);
  
    ntest +:=1;
    ok :=mydeconvolver.smooth(model=mscleanfile, image=smoothfile2,
	bmaj='20arcsec', bmin='20arcsec', bpa='0deg', normalize=F);
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'makeprior';
  note('Test deconvolver.makeprior');
  priorfile:=spaste(testdir, '3C273XC1.prior');
  
    ntest +:=1;
    ok :=mydeconvolver.makeprior(prior=priorfile, templateimage=smoothfile1,
			lowclipfrom='0.0001Jy', lowclipto='0.00001Jy', 
			highclipfrom='99.0Jy', highclipto='99.0Jy',
			blc=[50,50,0,0], trc=[200,200,0,0]);
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'mem';
  note('Test deconvolver.mem');
  memfile:=spaste(testdir, '3C273XC1.mem1');
#    mydeconvolver.reopen();

    ntest +:=1;
    converged :=mydeconvolver.mem(entropy='entropy', niter=20, sigma='0.001Jy', 
			 targetflux='5.0Jy', constrainflux=F, displayprogress=F,
	                 model=memfile);
    ok :=  tableexists(memfile);	
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'mem-with-prior';
  note('Test deconvolver.mem with prior');
  memfile:=spaste(testdir, '3C273XC1.mem2');
#    mydeconvolver.reopen();

    ntest +:=1;
    converged :=mydeconvolver.mem(entropy='entropy', niter=20, sigma='0.001Jy', 
			 targetflux='5.0Jy', constrainflux=F,  displayprogress=F,
	                 model=memfile, prior=priorfile);
    ok := tableexists(memfile);
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'mem-with-mask';
  note('Test deconvolver.mem with mask');
  memfile:=spaste(testdir, '3C273XC1.mem3');
#    mydeconvolver.reopen();

    ntest +:=1;
    converged :=mydeconvolver.mem(entropy='entropy', niter=20, sigma='0.001Jy', 
			 targetflux='5.0Jy', constrainflux=F,  displayprogress=F,
	                 model=memfile, mask=maskfile);
   ok := tableexists(memfile);
   checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'residual';
  note('Test deconvolver.residual');
  residfile:= spaste(testdir, '3C273XC1.resid');

    ntest +:=1;
    ok :=mydeconvolver.residual(model=mscleanfile, image=residfile);
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'restore';
  note('Test deconvolver.restore');
  restorefile:= spaste(testdir, '3C273XC1.restore');
 
    ntest +:=1;
    ok :=mydeconvolver.restore(model=mscleanfile, image=restorefile,
			     bmaj='3.8arcsec', bmin='3.2arcsec', bpa='36.1436deg');
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'summary';
  note('Test deconvolver.summary');
  
    ntest +:=1;
    ok :=mydeconvolver.summary();
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'clipimage';
  note('Test deconvolver.clipimage');
  clipfile:=spaste(testdir, '3C273XC1.clip');

    ntest +:=1;
    ok :=mydeconvolver.clipimage(clippedimage=clipfile, inputimage=psffile, 
	threshold='0.01Jy');
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################

  nametest := 'open';
  note('Test deconvolver.open');
  
    ntest +:=1;
    ok :=mydeconvolver.open(dirtyname=dirtyfile, psfname=psffile);	  
    checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  #################################################################################

  ntest +:=1;
  ok := mydeconvolver.done();
  
  checkresult(ok, ntest, nametest, results);

  for (result in results) {
    note(result);
  }
  etime:=time();
  note('## deconvolver.deconvolverlongtest()');
  note('## Finished successfully in run time = ', (etime - stime), ' seconds');
  
  return T;
}

