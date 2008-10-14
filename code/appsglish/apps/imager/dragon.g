# dragon.g: Make wide-field images from AIPS++ MeasurementSets
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
#   $Id: dragon.g,v 19.1 2004/08/25 01:19:25 cvsmgr Exp $
#

pragma include once

const dragon := function(filename) {

  include "calibrater.g";
  include "imager.g";
  include "componentlist.g";
  include "automask.g"
  include "interactivemask.g"
  include "measures.g";
  include "note.g";

  self := [=];
  public := [=];
  
  self.imager := imager(filename);
  if(is_fail(self.imager)) fail;
  self.calibrater := calibrater(filename);
  if(is_fail(self.calibrater)) fail;

  self.setimage := [=]
  self.setoutlier := [=]

  public.reset := function() {
    wider self;
    note('Resetting image information, and calibration');
    self.setimage := [=];
    self.setoutlier := [=];
    self.imager.correct(timestep='10s', async=F);
    return T;
  }

  public.setimage:=function(nx=128, ny=128,
			    cellx='1arcsec', celly='1arcsec',
			    stokes='I',
			    doshift=F, 
			    phasecenter=F,
			    mode='mfs', nchan=1,
			    start=1, step=1,
			    spwid=1, fieldid=1,
			    facets=1, name='dragon') {
    wider self;

    if(name=='') {
      name := 'dragon';
      note (paste('First field will be called ', name));
    }

    self.setimage := [nx=nx, ny=ny, cellx=cellx, celly=celly,
		      stokes=stokes, doshift=doshift,
		      phasecenter=phasecenter,
		      mode=mode, nchan=nchan, start=start, step=step,
		      spwid=spwid, fieldid=fieldid, facets=facets, name=name];
    
    # Do an initial check
    state := self.setimage;
    f:=self.imager.setimage(nx=state.nx, ny=state.ny,
			    cellx=state.cellx, celly=state.celly,
			    stokes=state.stokes, doshift=state.doshift,
			    phasecenter=state.phasecenter,
			    mode=state.mode, nchan=state.nchan,
			    start=state.start, step=state.step,
			    spwid=state.spwid, fieldid=state.fieldid,
			    facets=state.facets);
    if(!is_boolean(f)||!f) return f;
    return T;
  }

  public.setoutlier:=function(nx=128, ny=128,
			      cellx='1arcsec', celly='1arcsec',
			      stokes='I',
			      doshift=F, 
			      phasecenter=F,
			      mode='mfs', nchan=1,
			      start=1, step=1,
			      spwid=1, fieldid=1,
			      name='') {
    wider self;
    if(name=='') {
      if(has_field(self.image, 'name')&&self.image.name!='') {
	name := spaste(self.image.name, '.outlier', length(self.setoutlier)+1);
      }
      else {
	name := spaste('dragon.outlier', length(self.setoutlier)+1);
      }
      note (paste('Outlier will be called ', name));
    }

    self.setoutlier[name] := [nx=nx, ny=ny, cellx=cellx, celly=celly,
			      stokes=stokes, doshift=doshift,
			      phasecenter=phasecenter,
			      mode=mode, nchan=nchan, start=start, step=step,
			      spwid=spwid, fieldid=fieldid, name=name];

    return T;

  }

  public.advise:=function(amplitudeloss=0.05,
			  fieldofview='1deg', ref pixels=128,
			  ref cell='1arcsec', ref facets=1,
			  ref phasecenter=F) {
    wider self;
    return self.imager.advise(takeadvice=F, amplitudeloss=amplitudeloss,
			      fieldofview=fieldofview, pixels=pixels,
			      cell=cell, facets=facets,
			      phasecenter=phasecenter, async=F);
  }

  public.setoptions:=function(cache=0, padding=1.2) {
    wider self;
    return self.imager.setoptions(cache=cache, padding=padding);
  }
  
  public.weight:=function(type="uniform", rmode="none", noise='0.0Jy',
			  robust=0.0, fieldofview="0rad", npixels=0) {
    wider self;
    return self.imager.weight(type, rmode, noise, robust, fieldofview, npixels,
			      async=F);
  }
  
  public.filter:=function(bmaj='0rad', bmin='0rad', bpa='0deg') {
    wider self;
    return self.imager.filter(bmaj=bmaj, bmin=bmin, bpa=bpa, async=F);
  }
  
  public.uvrange:=function(uvmin=0.0, uvmax=0.0) {
    wider self;
    return self.imager.uvrange(uvmin, uvmax, async=F);
  }
  
  public.setbeam:=function(bmaj='0rad', bmin='0rad', bpa='0rad') {
    wider self;      
    return self.imager.setbeam(bmaj, bmin, bpa, async=F);
  }
  
  public.image:=function(levels=unset, amplitudelevel='0.0Jy', timescales=[],
			 niter=1000, threshold='0.0Jy',
			 gain=0.1, ref models='', complist='',
			 ref images='', makeresiduals=T, ref residuals='',
			 plot=T, display=F, ref statsregion=unset,
			 ref statsout=[=], algorithm='wfclark', maskmodification='none') {
    
    userstopped:=F;

    # Check the levels
    levels := split(levels);
    if(is_unset(levels) || sum(strlen(levels))==0) {
     
        note('No flux levels for self-calibrating',priority='WARN');
        note('Will do a normal imaging run', priority='WARN');
    }
    else{
     
    for (level in levels) {
      if(!is_string(level))
	  return throw('levels for selfcal must be quantities as strings',
					 origin='dragon.image');
    }
    
    if(length(timescales)!=length(levels)) {
      if(length(timescales)==1) {
	note('Using default phase-only solution, timescale =', timescales[1]);
	timescales := array(timescales[1], length(levels));
      }
      else {
	note('Using default phase-only solution, timescale = 10s');
	timescales := array('10.0s', length(levels));
      }
    }
   } 
    if(length(self.setimage)==0) {
      return throw('Image parameters not yet set');
    }

    # Make the initial model
    imodels := array('', 1+length(self.setoutlier));

    imodels[1] := self.setimage.name;
    if(tableexists(imodels[1])) tabledelete(imodels[1]);
    note(paste('Making initial empty model', imodels[1]));
    state := self.setimage;
    f:=self.imager.setimage(nx=state.nx, ny=state.ny,
			    cellx=state.cellx, celly=state.celly,
			    stokes=state.stokes, doshift=state.doshift,
			    phasecenter=state.phasecenter,
			    mode=state.mode, nchan=state.nchan,
			    start=state.start, step=state.step,
			    spwid=state.spwid, fieldid=state.fieldid,
			    facets=state.facets);
    if(!is_boolean(f)||!f) return f;
    f:=self.imager.make(imodels[1], async=F);
    if(!is_boolean(f)||!f) return f;
    f:=self.imager.setdata(mode='none', nchan=state.nchan, start=state.start,
			   step=state.step, spwid=state.spwid,
			   fieldid=state.fieldid, async=F);
    if(!is_boolean(f)||!f) return f;

    # Now make the outliers
    if(length(self.setoutlier)) {
      for (i in 1:length(self.setoutlier)) {
        state := self.setoutlier[i]
	note(paste('Making outlier', state.name));
	imodels[i+1] := state.name;
	f:=self.imager.setimage(nx=state.nx, ny=state.ny,
				cellx=state.cellx, celly=state.celly,
				stokes=state.stokes, doshift=state.doshift,
				phasecenter=state.phasecenter,
				mode=state.mode, nchan=state.nchan,
				start=state.start, step=state.step,
				spwid=state.spwid, fieldid=state.fieldid,
				facets=1);
	if(!is_boolean(f)||!f) return f;
	f:=self.imager.make(state.name, async=F);
	if(!is_boolean(f)||!f) return f;
	f:=self.imager.setdata(mode='none', nchan=state.nchan,
			       start=state.start, step=state.step,
			       spwid=state.spwid, fieldid=state.fieldid,
			       async=F);
	if(!is_boolean(f)||!f) return f;
      }
    }

    if(complist!='') {
      note(paste('Component model                 = ', as_evalstr(complist)));
    }
    
    note(paste('Complete set of image models    = ', as_evalstr(imodels)));
    
    iresiduals:='';
    if(makeresiduals) {
      for (i in 1:length(imodels)) {
	iresiduals[i] := spaste(imodels[i], '.residual');
      }
      note('Complete set of residuals       = ', as_evalstr(iresiduals));
    }

    iimages:='';
    for (i in 1:length(imodels)) {
      iimages[i] := spaste(imodels[i], '.restored');
    }

    note(paste('Complete set of restored images = ', as_evalstr(iimages)));

    if(self.setimage.facets==1) {
      algorithm:='mf';
      note('No facets: Using multi-field clean algorithm');
  };

    # Now reset the image parameters for the main field    
    state := self.setimage;
    f:=self.imager.setimage(nx=state.nx, ny=state.ny,
			    cellx=state.cellx, celly=state.celly,
			    stokes=state.stokes, doshift=state.doshift,
			    phasecenter=state.phasecenter,
			    mode=state.mode, nchan=state.nchan,
			    start=state.start, step=state.step,
			    spwid=state.spwid, fieldid=state.fieldid,
			    facets=state.facets);

    if(!is_boolean(f)||!f) return f;

     if(is_unset(levels) || sum(strlen(levels))==0){ 
        lev1:='0.0';
       note('Performing a normal clean and stopping; niter= ', niter) 
     }
     else{
         note('Performing first clean down to ', levels[1]);
         lev1:=levels[1];
     }
    # Clean the image
    if(makeresiduals) {
      f:=self.imager.clean(algorithm=algorithm, niter=niter, gain=gain,
			   threshold=lev1,
			   model=imodels, residual=iresiduals, image=iimages,
			   complist=complist, async=F);
      if(!is_boolean(f)||!f) return f;
    }
    else {
      f:=self.imager.clean(algorithm=algorithm, niter=niter, gain=gain,
			   threshold=lev1, image=iimages,
			   model=imodels, complist=complist, async=F);
      if(!is_boolean(f)||!f) return f;
    }
    if(is_unset(levels) || sum(strlen(levels))==0){ 
       return T;
   }
    # Stop now?
    if(display) {
      im := image(iimages[1]);
      im.view();
      stop := choice('Finished first clean, stop now?', ['no', 'yes'], timeout=60);
      im.close(); im.done();
      if(stop=='yes') {	
	userstopped:=T;
	note('Stopping at user request', origin='dragon.image');
	return;
      }
    }
    else {
      stop := choice('Finished first clean, stop now?', ['no', 'yes']);
      if(stop=='yes') {	
	userstopped:=T;
	note('Stopping at user request', origin='dragon.image');
	return;
      }
    }

    # Now start clean/selfcal cycle
    for (i in 1:length(levels)) {
      
      level := levels[i];
      
      # Set up the gain solutions
      atime:=dq.convert(dq.quantity(timescales[i]), 's').value;
      qlevel := dq.convert(dq.quantity(level), 'Jy');
      qalevel := dq.convert(dq.quantity(amplitudelevel), 'Jy');
      if(is_quantity(qlevel)&&is_quantity(qalevel)&&
	 (qlevel.value<qalevel.value)) {
	note('Amplitude and phase gain (G-Jones) solution', origin='dragon.image');
        gaintable := spaste(imodels[1], '.', timescales[i], '.Gamp.gaintable');
	f:=self.calibrater.setsolve(type='G', t=atime, phaseonly=F, table=gaintable);
	if(!is_boolean(f)||!f) return f;
	f:=self.calibrater.solve();
	if(!is_boolean(f)||!f) return f;
	f:=self.calibrater.setapply(type='G', t=0, table=gaintable, select='');
	if(!is_boolean(f)||!f) return f;
	self.calibrater.correct();
      }
      else {
	note('Phase only gain (G-Jones) solution', origin='dragon.image');
        gaintable := spaste(imodels[1], '.', timescales[i], '.Gphase.gaintable');
	f:=self.calibrater.setsolve(type='G', t=atime, phaseonly=T, table=gaintable);
	if(!is_boolean(f)||!f) return f;
	f:=self.calibrater.solve();
	if(!is_boolean(f)||!f) return f;
	f:=self.calibrater.setapply(type='G', t=0, table=gaintable, select='');
	f:=self.calibrater.correct();
	if(!is_boolean(f)||!f) return f;
      }
      
      note('Cleaning down to ', level);
      # Clean the image
        masks:='';
      if(maskmodification=='auto') {
         masks:='';
         for (k in 1:length(imodels)) {
            masks[k] := spaste(iimages[k], '.mask');
            rmcom:=spaste("rm -rf ", masks[k]);
            shell(rmcom); 
         }
        automask(modelimage=iimages, cutlevel=level);
        for (k in 1:length(imodels)) {
         dv.newdisplaypanel();
         dv.loaddata(iimages[k], drawtype='raster')
         dv.hold();
         dv.loaddata(masks[k], drawtype='contour')
	happy := choice('Are you satisfied with the mask', ['yes', 'no'], timeout=60);
          if(happy=='no') { 
            masks[k]:='';
            note('Will not be using this mask');
          } 
         dv.deleteall();
         dv.release();
        }
      }
      else if(maskmodification=='interactive'){
         for (k in 1:length(imodels)) {
            masks[k] := spaste(iimages[k], '.mask');
            a:=interactivemask(iimages[k], masks[k]);
            a.start();
            while(!is_boolean(a)){
              timer.wait(5)
            }
         }

      }
      else {
	note('Imaging without masks')
      }
      f:=self.imager.clean(algorithm=algorithm, niter=niter, gain=gain,
			   threshold=level,
			   model=imodels, mask=masks, residual=iresiduals, 
                           image=iimages, complist=complist, async=F);
      if(!is_boolean(f)||!f) return f;    
      im := image(iimages[1]);
      im.statistics(region=statsregion, statsout=statsout);

      # Stop now?
      if(i>1&&i<length(levels)) {
	if(display) {
	  im.view();
	  stop := choice('Stop clean/selfcal now?', ['no', 'yes'], timeout=60);
	  if(stop=='yes') {	
	    userstopped:=T;
	    note('Stopping at user request', origin='dragon.image');
	    break;
	  }
	}
	else {
	  stop := choice('Stop clean/selfcal now?', ['no', 'yes']);
	  if(stop=='yes') {	
	    userstopped:=T;
	    note('Stopping at user request', origin='dragon.image');
	    break;
	  }
	}
      }
      im.close(); im.done();

      # Plot the data
      if(plot) {
	f:=self.imager.plotvis('residual', async=F);
	if(!is_boolean(f)||!f) return f;
      }

    }
    val models := imodels;
    val residuals := iresiduals;
    val images := iimages;
    return T;
  }
  
  public.done := function()
  {
    wider self, public;
    self.imager.done();
    self.calibrater.done();
    self := F;
    val public := F;
    return T;
  }
  
  public.name := function()
  {
    wider self;
    return self.imager.name();
  }

  public.type := function() {
    # The Return of the Dragon.....(ouch!)
    return 'dragon';
  }

  plugins.attach('dragon', public);

  return ref public;

} 













