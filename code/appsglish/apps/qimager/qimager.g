# qimager.g: Make images from AIPS++ MeasurementSets
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
#   $Id: qimager.g,v 1.5 2004/08/25 01:48:12 cvsmgr Exp $
#

pragma include once

include 'plugins.g'
include 'servers.g'
include 'note.g'

#defaultservers.suspend(T)
#defaultservers.trace(T)

# Users aren't to use this.
const _define_qimager := function(ref agent, id) {
    self := [=]
    public := [=]

    self.agent := ref agent;
    self.id := id;

    public.stop := function(stop=T) {
        wider self;
	return defaultservers.stop(self.agent, stop);
    }

    self.openRec := [_method="open", _sequence=self.id._sequence]
    public.open := function(thems, compress=F) {
	wider self;
	self.openRec.thems := thems;
        self.openRec.compress := compress;
        return defaultservers.run(self.agent, self.openRec);
    }

    self.closeRec := [_method="close", _sequence=self.id._sequence]
    public.close := function() {
	wider self;
        return defaultservers.run(self.agent, self.closeRec);
    }

    self.nameRec := [_method="name", _sequence=self.id._sequence]
    public.name := function() {
	wider self;
        return defaultservers.run(self.agent, self.nameRec);
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

    self.setqimagerec := [_method="setimage", _sequence=self.id._sequence]
    public.setimage:=function(nx=128, ny=128,
			      cellx='1arcsec', celly='1arcsec',
			      stokes='I',
                              doshift=F, 
			      phasecenter=F,
			      shiftx='0arcsec', shifty='0arcsec',
                              mode='mfs', nchan=1,
                              start=1, step=1,
			      mstart='0km/s',
                              mstep='0km/s',
                              spwid=1, fieldid=1,
			      facets=1, distance='0m') {
        wider self;
        include 'measures.g';
        if(is_boolean(phasecenter)) {
          phasecenter:=dm.direction('b1950', '0deg', '90deg');
	}
	self.setqimagerec.nx:=nx;
	self.setqimagerec.ny:=ny;
        self.setqimagerec.cellx:=cellx;
        self.setqimagerec.celly:=celly;
        self.setqimagerec.stokes:=stokes;
        self.setqimagerec.doshift:=doshift;
        self.setqimagerec.phasecenter:=phasecenter;
        self.setqimagerec.shiftx:=shiftx;
        self.setqimagerec.shifty:=shifty;
        self.setqimagerec.mode:=mode;
        self.setqimagerec.nchan:=nchan;
        self.setqimagerec.start:=start;
        self.setqimagerec.step:=step;
        self.setqimagerec.mstart:=mstart;
        self.setqimagerec.mstep:=mstep;
        self.setqimagerec.spwid:=spwid;
        self.setqimagerec.fieldid:=fieldid;
        self.setqimagerec.facets:=facets;
        self.setqimagerec.distance:=distance;
	return defaultservers.run(self.agent, self.setqimagerec);
    }

    self.adviseRec := [_method="advise", _sequence=self.id._sequence]
    public.advise:=function(takeadvice=T, amplitudeloss=0.05,
			    fieldofview='1deg', ref pixels=128,
			    ref cell='1arcsec', ref facets=1,
			    ref phasecenter=F, async=!dowait) {
        wider self;
	self.adviseRec.takeadvice:=takeadvice;
	self.adviseRec.amplitudeloss:=amplitudeloss;
	self.adviseRec.fieldofview:=fieldofview;
	returnval := defaultservers.run(self.agent, self.adviseRec, async);
        if(!async) {
	  val pixels:=self.adviseRec.pixels;
	  val cell:=self.adviseRec.cell;
	  val facets:=self.adviseRec.facets;
	  val phasecenter:=self.adviseRec.phasecenter;
	}
        return returnval;
    }

#-----------------------------------------------------------------------------
# Private function to convert synthesis selection strings to TAQL
#
   const self.synthselect := function (synth='') {
#
      taql := synth;
      if (strlen(synth) > 0) {
         # Check for '0-rel' or '0-REL'
         zerorel := synth ~ m/0-REL/i;
         if (zerorel) {
            synth := synth ~ s/0-REL//gi;
         } else {
            # Check for '1-rel' or '1-REL'
            synth := synth ~ s/1-REL//gi;
            # Adjust all relevant MS/calibration indices by 1
            synth := synth ~ s/ANTENNA1/(ANTENNA1+1)/gi;
            synth := synth ~ s/ANTENNA2/(ANTENNA2+1)/gi;
            synth := synth ~ s/FEED1/(FEED1+1)/gi;
            synth := synth ~ s/FEED2/(FEED2+1)/gi;
            synth := synth ~ s/ARRAY_ID/(ARRAY_ID+1)/gi;
            synth := synth ~ s/CORRELATOR_ID/(CORRELATOR_ID+1)/gi;
            synth := synth ~ s/FIELD_ID/(FIELD_ID+1)/gi;
            synth := synth ~ s/OBSERVATION_ID/(OBSERVATION_ID+1)/gi;
            synth := synth ~ s/PULSAR_ID/(PULSAR_ID+1)/gi;
            # Temporary 10/2000; use DATA_DESC_ID directly for now
            synth := synth ~ s/SPECTRAL_WINDOW_ID/(DATA_DESC_ID+1)/gi;
            synth := synth ~ s/ANTENNA_ID/(ANTENNA_ID+1)/gi;
            synth := synth ~ s/ORBIT_ID/(ORBIT_ID+1)/gi;
            synth := synth ~ s/PHASED_ARRAY_ID/(PHASED_ARRAY_ID+1)/gi;
            synth := synth ~ s/FEED_ID/(FEED_ID+1)/gi;
            synth := synth ~ s/BEAM_ID/(BEAM_ID+1)/gi;
            synth := synth ~ s/PHASED_FEED_ID/(PHASED_FEED_ID+1)/gi;
            synth := synth ~ s/SOURCE_ID/(SOURCE_ID+1)/gi;
            taql := synth;
         };
      };
      return taql;
   };

#-----------------------------------------------------------------------------
# Private function to pre-process input selection strings
# 
   const self.validstring := function (inputstring) {
#
      outputstring := inputstring;
      # Guard against "" or " "
      if (shape(outputstring) == 0) {
         outputstring:= ' ';
      } else {
         # Convert Glish string arrays 
         outputstring := paste (outputstring);
         # Strip spurious start and end quotes (
         outputstring := outputstring ~ s/^'(.*)'$/$1/;
         outputstring := outputstring ~ s/^"(.*)"$/$1/;
      };
      return outputstring;
   };
#-----------------------------------------------------------------------------

    self.setdataRec := [_method="setdata", _sequence=self.id._sequence]
    public.setdata:=function(mode='none', nchan=[1], start=[1], step=[1],
               		     mstart='0km/s',
                             mstep='0km/s',
			     spwid=[1], fieldid=[1], 
			     msselect = ' ', async=!dowait) {
        wider self;
        self.setdataRec.mode:=mode;
        self.setdataRec.nchan:=nchan;
        self.setdataRec.start:=start;
        self.setdataRec.step:=step;
        self.setdataRec.mstart:=mstart;
        self.setdataRec.mstep:=mstep;
        self.setdataRec.spwid:=spwid;
        self.setdataRec.fieldid:=fieldid;
      # Pre-process input select string and convert to TAQL
        self.setdataRec.msselect:= self.synthselect (self.validstring(msselect));
	return defaultservers.run(self.agent, self.setdataRec, async);
    }

    self.setoptionsRec := [_method="setoptions", _sequence=self.id._sequence]
    public.setoptions:=function(ftmachine='ft',
				cache=0, tile=16,
				gridfunction='SF',
				location=F,
				padding=1.2) {
        wider self;
        include 'measures.g';
        if(is_boolean(location)) {
          location:=dm.position('wgs84', '0m', '0m', '0m');
	}
	self.setoptionsRec.ftmachine:=ftmachine;
	self.setoptionsRec.cache:=cache;
	self.setoptionsRec.tile:=tile;
        self.setoptionsRec.gridfunction:=gridfunction;
        self.setoptionsRec.location:=location;
        self.setoptionsRec.padding:=padding;
	return defaultservers.run(self.agent, self.setoptionsRec);
    }

    self.weightRec := [_method="weight", _sequence=self.id._sequence]
    public.weight:=function(type="uniform", rmode="norm", noise='0.0Jy',
			    robust=0.0, fieldofview="0rad", npixels=0,
			    async=!dowait) {
        wider self;
	if(type=='briggs' && (rmode==''))
	  rmode:='norm';
	self.weightRec.type:=type;
	self.weightRec.rmode:=rmode;
	self.weightRec.noise:=noise;
	self.weightRec.robust:=robust;
	self.weightRec.fieldofview:=fieldofview;
	self.weightRec.npixels:=npixels;
	return defaultservers.run(self.agent, self.weightRec, async);
    }

    self.filterRec := [_method="filter", _sequence=self.id._sequence]
    public.filter:=function(type="gaussian", bmaj='0rad', bmin='0rad',
			    bpa='0deg', async=!dowait) {
        wider self;
	self.filterRec.type:=type;
	self.filterRec.bmaj:=bmaj;
	self.filterRec.bmin:=bmin;
	self.filterRec.bpa:=bpa;
	return defaultservers.run(self.agent, self.filterRec, async);
    }

    self.uvrangeRec := [_method="uvrange", _sequence=self.id._sequence]
    public.uvrange:=function(uvmin=0.0, uvmax=0.0, async=!dowait) {
        wider self;
	self.uvrangeRec.uvmin:=uvmin;
	self.uvrangeRec.uvmax:=uvmax;;
	return defaultservers.run(self.agent, self.uvrangeRec, async);
    }

    self.sensitivityRec := [_method="sensitivity", _sequence=self.id._sequence]
    public.sensitivity:=function(ref pointsource="0Jy", ref relative=0.0,
				 ref sumweights=0.0, async=!dowait) {
        wider self;
	returnval := defaultservers.run(self.agent, self.sensitivityRec, async);
        if(!async) {
	  val pointsource:=self.sensitivityRec.pointsource;
	  val relative:=self.sensitivityRec.relative;
	  val sumweights:=self.sensitivityRec.sumweights;
	}
        return returnval;
    }

    self.makeimagerec := [_method="makeimage", _sequence=self.id._sequence];
    public.makeimage:=function(type="observed", image='',
			       compleximage='', async=!dowait) {
      wider self;
      self.makeimagerec.type:=type;
      self.makeimagerec.image:=image;
      self.makeimagerec.compleximage:=compleximage;
      return defaultservers.run(self.agent, self.makeimagerec, async);
    }

    self.approximatepsfRec := [_method="approximatepsf", _sequence=self.id._sequence]
    public.approximatepsf:=function(model='', psf='', async=!dowait) {
        wider self;
	self.approximatepsfRec.model:=model;
	self.approximatepsfRec.psf:=psf;
	return defaultservers.run(self.agent, self.approximatepsfRec, async);
    }

    self.restoreRec := [_method="restore", _sequence=self.id._sequence]
    public.restore:=function(model='', complist='', image='', residual='',
			     async=!dowait) {
        wider self;
	self.restoreRec.model:=model;
	self.restoreRec.complist:=complist;
	self.restoreRec.image:=image;
	self.restoreRec.residual:=residual;
	returnval := defaultservers.run(self.agent, self.restoreRec, async);
        return returnval;
    }

    self.residualRec := [_method="residual", _sequence=self.id._sequence]
    public.residual:=function(model='', complist='', image='',
			      async=!dowait) {
        wider self;
	self.residualRec.model:=model;
	self.residualRec.complist:=complist;
	self.residualRec.image:=image;
	return defaultservers.run(self.agent, self.residualRec, async);
    }

    self.cleanRec := [_method="clean", _sequence=self.id._sequence]
    public.clean:=function(algorithm='clark', niter=1000, gain=0.1,
			   threshold='0Jy',
			   displayprogress=F, 
			   model='', fixed=F, complist='',
			   mask='', image='', residual='', 
                           interactive=F,
			   npercycle=100,
			   masktemplate='',
			   async=!dowait) {
        wider self;
          if(model != '' && image=='' && !is_unset(image)){
            for (k in 1: length(model)){
              image[k]:=spaste(model[k], '.restored');
            }
          }
	if (is_unset(image)) image:='';
         if(model != '' && residual=='' && !is_unset(residual)){
            for (k in 1: length(model)){
              residual[k]:=spaste(model[k], '.residual');
            }
         }
         if(is_unset(residual)) residual:='';
        if(interactive && (npercycle >0) ){
          self.cleanRec.niter:=npercycle;
	  if( residual == ''){
	    interactive:=F;
	    self.cleanRec.niter:=niter; 
	    note('Cannot use interactive masking without residual image', 
	    priority='WARN');
	    note('Going into non-interactive mode', priority='WARN'); 
          }
        }
	else{
	  self.cleanRec.niter:=niter;
	  interactive:=F;
        }
	self.cleanRec.algorithm:=algorithm;
	self.cleanRec.gain:=gain;
	self.cleanRec.threshold:=threshold;
	self.cleanRec.displayprogress:=displayprogress;
	self.cleanRec.model:=model;
	self.cleanRec.fixed:=fixed;
	self.cleanRec.complist:=complist;
	self.cleanRec.mask:=mask;
	self.cleanRec.image:=image;
	self.cleanRec.residual:=residual;
	if(interactive){
	 include 'interactivemask.g'
	 if(mask==''){
	   mask:=spaste(model,'.mask')
           self.cleanRec.mask:=mask;
	 }
	 numloop:=as_integer(niter/npercycle);
	 if(!dos.fileexists(residual) && (masktemplate=='')){
	   ok:=public.makeimage(type='corrected', image=residual)
	     if(!ok){
	      note('Problem in making dirty image', priority='WARN');
	      return F; 
	     }
          } 
	
	 for (k in 1:numloop){
	   if(k == 1 && masktemplate != ''){
	     myint:=interactivemask(masktemplate, mask);
	   }
	   else{
	     myint:=interactivemask(residual, mask);
	   } 
	   myint.start();
	   if(myint==3) break;  # stop button pressed... stop right now
	   if(myint==2){ # continue but no more interactive masking
	     self.cleanRec.niter:=niter-k*npercycle;
	     returnval := defaultservers.run(self.agent, self.cleanRec, async);
	     break;
	   } 
	   returnval := defaultservers.run(self.agent, self.cleanRec, async);
	   if(returnval) break; 
	 }
       }
	else{
	  returnval := defaultservers.run(self.agent, self.cleanRec, async);
	}
        return returnval;
      }

    self.memRec := [_method="mem", _sequence=self.id._sequence]
    public.mem:=function(algorithm='entropy', niter=20,
			 gain=0.3, sigma='0.001Jy',
			 targetflux='1.0Jy', constrainflux=F,
			 displayprogress=F, model='', fixed=F,
			 complist='', prior='', mask='', 
			 image='', residual='', async=!dowait) {
        wider self;
	self.memRec.algorithm:=algorithm;
	self.memRec.niter:=niter;
	self.memRec.gain:=gain;
	self.memRec.sigma:=sigma;
	self.memRec.targetflux:=targetflux;
	self.memRec.constrainflux:=constrainflux;
	self.memRec.displayprogress:=displayprogress;
	self.memRec.model:=model;
	self.memRec.fixed:=fixed;
	self.memRec.complist:=complist;
	self.memRec.prior:=prior;
	self.memRec.mask:=mask;
	self.memRec.image:=image;
	self.memRec.residual:=residual;
	returnval := defaultservers.run(self.agent, self.memRec, async);
        return returnval;
    }

    self.nnlsRec := [_method="nnls", _sequence=self.id._sequence]
    public.nnls:=function(algorithm='nnls', niter=1000, tolerance=0.0000001,
			  model='', fixed=F, complist='',
			  fluxmask='', datamask='',
			  image='', residual='',
			  async=!dowait) {
        wider self;
	self.nnlsRec.algorithm:=algorithm;
	self.nnlsRec.niter:=niter;
	self.nnlsRec.tolerance:=tolerance;
	self.nnlsRec.model:=model;
	self.nnlsRec.fixed:=fixed;
	self.nnlsRec.complist:=complist;
	self.nnlsRec.fluxmask:=fluxmask;
	self.nnlsRec.datamask:=datamask;
	self.nnlsRec.image:=image;
	self.nnlsRec.residual:=residual;
	returnval := defaultservers.run(self.agent, self.nnlsRec, async);
        return returnval;
    }

    self.setmfcontrolRec := [_method="setmfcontrol", _sequence=self.id._sequence]
    public.setmfcontrol:=function(cyclefactor=1.5, cyclespeedup=-1,
      			stoplargenegatives=2, stoppointmode=-1,
			async=!dowait) {
	wider self;
	self.setmfcontrolRec.cyclefactor:=cyclefactor;
	self.setmfcontrolRec.cyclespeedup:=cyclespeedup;
	self.setmfcontrolRec.stoplargenegatives:=stoplargenegatives;
	self.setmfcontrolRec.stoppointmode:=stoppointmode;
	returnval := defaultservers.run(self.agent, self.setmfcontrolRec, async);
        return returnval;
    }

    self.setsdoptionsRec := [_method="setsdoptions", _sequence=self.id._sequence];
    public.setsdoptions:=function(scale=1.0, weight=1.0, async=!dowait) {
      wider self;
      self.setsdoptionsRec.scale:=scale;
      self.setsdoptionsRec.weight:=weight;
      returnval := defaultservers.run(self.agent, self.setsdoptionsRec, async);
      return returnval;
    }

    self.featherRec := [_method="feather", _sequence=self.id._sequence]
    public.feather:=function(image='', highres='', lowres='',  lowpsf='',
			     async=!dowait) {
        wider self;
	self.featherRec.image:=image;
	self.featherRec.highres:=highres;
	self.featherRec.lowres:=lowres;
	self.featherRec.lowpsf:=lowpsf;
	return defaultservers.run(self.agent, self.featherRec, async);
    }


    self.pbRec := [_method="pb", _sequence=self.id._sequence]
    public.pb:=function(inimage='', outimage='', incomps='', outcomps='',
			operation='apply',  
			pointingcenter=F, parangle='0deg', pborvp='pb',
			async=!dowait) {
        wider self;
        include 'measures.g';
#
        if(is_boolean(pointingcenter) && inimage!='') {
           if (pointingcenter) {
             return throw ('pointingcenter must be F or a direction measure');
           }
#
	   img := image(inimage);
           if (is_fail(img)) fail;
	   cs := img.coordsys();
           if (is_fail(cs)) fail;
#
	   values := cs.referencevalue(type='direction', format='m')
           if (is_fail(values)) fail;
           pointingcenter:=values.direction;
#
           img.done()
           cs.done()
	}
	self.pbRec.inimage:=inimage;
	self.pbRec.outimage:=outimage;
	self.pbRec.incomps:=incomps;
	self.pbRec.outcomps:=outcomps;
	self.pbRec.operation:=operation;
	self.pbRec.pointingcenter:=pointingcenter;
	self.pbRec.parangle:=parangle;
	self.pbRec.pborvp:=pborvp;
	return defaultservers.run(self.agent, self.pbRec, async);
    }

    self.linearmosaicRec := [_method="linearmosaic", _sequence=self.id._sequence]
    public.linearmosaic:=function(mosaic='', fluxscale='', sensitivity='',
				images='', fieldid=[1], async=!dowait) {
        wider self;
        include 'measures.g';
	self.linearmosaicRec.mosaic:=mosaic;
	self.linearmosaicRec.fluxscale:=fluxscale;
	self.linearmosaicRec.sensitivity:=sensitivity;
	self.linearmosaicRec.images:=images;
	self.linearmosaicRec.fieldid:=fieldid;

	return defaultservers.run(self.agent, self.linearmosaicRec, async);
    }

    self.predictRec := [_method="predict", _sequence=self.id._sequence]
    public.predict:=function(model='', complist='', incremental=F,
			     async=!dowait) {
        wider self;
	self.predictRec.model:=model;
	self.predictRec.complist:=complist;
	self.predictRec.incremental:=incremental;
	return defaultservers.run(self.agent, self.predictRec, async);
    }

    public.ft:=function(model='', complist='', incremental=F,
			     async=!dowait) {
      include 'note.g';
      note('qimager.ft is now called qimager.predict - please change your script');
      return public.predict(model, complist, incremental, async);
    }

    self.makeRec := [_method="make", _sequence=self.id._sequence]
    public.make:=function(image='', async=!dowait) {
        wider self;
	self.makeRec.image:=image;
	return defaultservers.run(self.agent, self.makeRec, async);
    }

    self.fitpsfRec := [_method="fitpsf", _sequence=self.id._sequence]
    public.fitpsf:=function(psf='', ref bmaj='0rad', ref bmin='0rad',
			    ref bpa='0deg', async=!dowait) {
        wider self;
	self.fitpsfRec.psf:=psf;
	returnval := defaultservers.run(self.agent, self.fitpsfRec, async);
        if(!async) {
	  val bmaj:=self.fitpsfRec.bmaj;
	  val bmin:=self.fitpsfRec.bmin;
	  val bpa:=self.fitpsfRec.bpa;
	}
        return returnval;
    }

    self.setbeamRec := [_method="setbeam", _sequence=self.id._sequence]
    public.setbeam:=function(bmaj='0rad', bmin='0rad', bpa='0rad') {
        wider self;
	self.setbeamRec.bmaj:=bmaj;
	self.setbeamRec.bmin:=bmin;
	self.setbeamRec.bpa:=bpa;
	returnval := defaultservers.run(self.agent, self.setbeamRec);
        return returnval;
      }

    self.setvpRec := [_method="setvp", _sequence=self.id._sequence]
    public.setvp:=function(dovp=T, usedefaultvp=T, vptable='', 
	dosquint=F,parangleinc='360deg') {
        wider self;
	self.setvpRec.dovp:=dovp;
	self.setvpRec.usedefaultvp:=usedefaultvp;
	self.setvpRec.vptable:=vptable;
	self.setvpRec.dosquint:=dosquint;
	self.setvpRec.parangleinc:=parangleinc;
	returnval := defaultservers.run(self.agent, self.setvpRec);
        return returnval;
      }

    self.smoothRec := [_method="smooth", _sequence=self.id._sequence]
    public.smooth:=function(model='', image='', usefit=T,
			    bmaj='0rad', bmin='0rad', bpa='0rad',
			    normalize=T, async=!dowait) {
        wider self;
	self.smoothRec.model:=model;
	self.smoothRec.image:=image;
	self.smoothRec.usefit:=usefit;
	self.smoothRec.bmaj:=bmaj;
	self.smoothRec.bmin:=bmin;
	self.smoothRec.bpa:=bpa;
	self.smoothRec.normalize:=normalize;
	returnval := defaultservers.run(self.agent, self.smoothRec, async);
        return returnval;
      }

    self.maskRec := [_method="mask", _sequence=self.id._sequence]
    public.mask:=function(image='', mask='', threshold='0.0Jy',
			  async=!dowait) {
        wider self;
	self.maskRec.image:=image;
	self.maskRec.mask:=mask;
	self.maskRec.threshold:=threshold;
	return defaultservers.run(self.agent, self.maskRec, async);
      }

    self.boxmaskRec := [_method="boxmask", _sequence=self.id._sequence]
    public.boxmask:=function(mask='', blc=[], trc=[], value=1.0,
			     async=!dowait) {
        wider self;
	self.boxmaskRec.mask:=mask;
	self.boxmaskRec.blc:=blc;
	self.boxmaskRec.trc:=trc;
	self.boxmaskRec.value:=value;
	return defaultservers.run(self.agent, self.boxmaskRec, async);
      }

    self.regionmaskRec := [_method="regionmask", _sequence=self.id._sequence]
    public.regionmask:=function(mask='', region=[Regions=[=]], value=1.0) {
        wider self;

        if(!is_string(mask)||(mask==''))
	    return throw('mask must be specified');
        if(!is_unset(region)&&!is_record(region))
	    return throw('region must be a valid region or a record of regions');
        if(is_fail(public.make(mask))) fail;

# below if section is to deal with gui inputs
         if(!is_region(region) && field_names(region[1])== "Regions"){
           regionRecord:=[=];
           for (k in 1:length(region)){
              regionRecord[k]:=region[k].Regions;
           }
          region:=regionRecord;    
         }
   
        if(!is_region(region)){
          regionRecord:=[=];
          regionRecord:=region;
          region:=F;
          if(length(regionRecord==0))
               return throw('region has to be a record of regions or a valid region');
          region:=regionRecord[1];
          if(length(regionRecord)>1){
           for (k in 2:length(regionRecord)){
             region:=drm.union(region, regionRecord[k]);
           }
          }
         }

        ok:=eval('include \'image.g\'');
        im := image(mask);
        if(is_fail(im)) return throw('Error opening mask image');
	if(is_fail(im.set(region=region, pixels=value)))
	    return throw('Error setting mask pixels');
        note(paste('Successfully made mask image', mask,
		   'from specified region'));
	return im.done();
      }

    self.exprmaskRec := [_method="exprmask", _sequence=self.id._sequence]
    public.exprmask:=function(mask='', expr='') {
        wider self;

        if(!is_string(mask)||(mask==''))
	    return throw('mask must be specified');

        if(is_fail(public.make(mask))) fail;

        ok:=eval('include \'image.g\'');
        im := image(mask);
        if(is_fail(im)) return throw('Error opening mask image');
        if(is_fail(im.calc(expr))) 
	    return throw(paste('Error setting mask pixels using expression', expr));
        note(paste('Successfully made mask image', mask,
		   'from specified expression', expr));
	return im.done();
      }

    self.setscalesRec := [_method="setscales", _sequence=self.id._sequence]
    public.setscales:=function(uservector=[0.0,3.0,10.0], async=!dowait) {
        wider self;
        self.setscalesRec.uservector:=uservector;
        returnval := defaultservers.run(self.agent, self.setscalesRec, async);
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
        include "widgetserver.g"
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
            f.text->insert('qimager closed', 'start');
        } else {
            f.text->delete('start', 'end');
            f.text->insert(public.state(), 'start');
        }
        return T;
    }

    public.type := function() {
      return 'qimager';
    }

    plugins.attach('qimager', public);
    return ref public;

} # _define_qimager()


# Make a new server for every invocation
const qimager := function(filename='', compress=F, host='', forcenewserver=T) {
  include 'os.g';
  if (filename=='') {
    throw('Must supply a measurementset filename');
    return F;
  } else if (!dos.fileexists(filename)) {
    throw('Measurementset ', filename, ' nonexistent!');
    return F;	
  }
  agent := defaultservers.activate("qimager", host, forcenewserver);
  if(is_fail(agent)) fail;
  id := defaultservers.create(agent, "qimager", "qimager", 
	[thems=filename, compress=compress]);
  if(is_fail(id)) fail;
  return ref _define_qimager(agent,id);

} 

##############################################################################
# Test script
#
const qimagertest:= function (level='all') {
# 
  # Create a qimagertester tool
  include 'qimagertester.g';
  mytester := qimagertester();   
  if(level=='all' || level == 'beta')
     testlist:=['sftest', 'mftest', 'wftest', 'spectraltest', 'memtest',
	     'utiltest'];
  else
     testlist:=['utiltest'];
  mytester.runtests(testlist);
  mytester.done();
  return T;
};


const qimagermaketestcl:=function(clfile='3C273XC1.cl', refer='b1950')
{
  include "componentlist.g"
  cl := emptycomponentlist();
  cl.simulate(1);
  cl.setflux(1, [29.78, 0.0, 0, 0], 'Jy', 'Stokes');
  cl.setrefdir(1, '12h26m33.248', 'time', '02d19m43.290', 'angle');
  cl.setrefdirframe(1, 'b1950');
  cl.convertrefdir(1, refer);
  cl.setshape(1, 'Point');
  cl.rename(clfile);
  cl.close();
  cl.done();
}

const qimagermaketestms := function(msfile='3C273XC1.ms') {

  include "ms.g";
  # Make the data
  include "sysinfo.g";
  aipsroot:=sysinfo().root();
  fitsfile:=spaste(aipsroot, '/data/demo/3C273XC1.fits');
  ok := shell(paste("rm -fr ", msfile))
  msnew:=fitstoms(msfile, fitsfile, readonly=F);
  if(has_field(msnew, 'close')) {
    msnew.close();
    msnew.done();
  }
}

const qimagermaketestsdms := function(msfile='gbt_cygnus_800MHz.ms') {

  include "gbtmsfiller.g";
  # Make the data
  include "sysinfo.g";
  include "os.g";
  aipsroot:=sysinfo().root();
  gbtfile:=spaste(aipsroot, '/data/nrao/GBT/pnt_prime_13');
  if(!dos.fileexists(gbtfile)) {
    return throw('Data file ', gbtfile,
		 ' does not exist: cannot create test measurementset');
  }
  ok := shell(paste("rm -fr ", msfile));

  note('Filling scans 2350 to 2424 from GBT FITS files in ', gbtfile, ' to ', msfile);

  gbtfiller := gbtmsfiller();
  if(is_fail(gbtfiller)) fail;
  gbtfiller.setproject(gbtfile);
  gbtfiller.setbackend('DCR');
  gbtfiller.setmsdirectory(dos.dirname(msfile));
  filldir := gbtfiller.msdirectory();
  gbtfiller.fillall();
  gbtfiller.done();
  include 'table.g';
  tablerename(spaste(filldir, '/pnt_prime_13_DCR'), msfile);

  include 'gbtcal.g';
  note('Calibrating data');

  gc:=gbtcal(msfile);
  gc.fixpnt(800000000.0);
  gc.fixtime(1.00);
  gc.calibrate(100, method='mean', doplot=F);
  gc.setsigma(0.0, 0.6);
  gc.done();
}


# makes a measurement set with 7 VLA D-array pointings on CAS A at 8 GHz 
const qimagermaketestmfms := function(msfile='XCAS.ms') {

  include "ms.g";
  # Make the data
  include "sysinfo.g";
  aipsroot:=sysinfo().root();
  fitsfile:=spaste(aipsroot, '/data/demo/XCAS-UV.fits');
  ok := shell(paste("rm -fr ", msfile))
  msnew:=fitstoms(msfile, fitsfile, readonly=F);
  if(has_field(msnew, 'close')) {
    msnew.close();
    msnew.done();
  }

}

const qimagerpbtest := function(size=256, cleanniter=1000, cleangain=0.1)
{
  global dowait:=T;

    # Variables that define the demonstration
  testdir := 'qimagerpbtest';

    note('Cleaning up directory ', testdir)
    ok := shell(paste("rm -fr ", testdir))
    if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); }

    # Make the directory
    ok := shell(paste("rm -fr ", testdir))
    if (ok::status) { throw("rm fails!") }
    ok := shell(paste("mkdir", testdir))
    if (ok::status) { throw("mkdir", testdir, "fails!") }

    # Make the data
    msfile:=spaste(testdir, '/','3C273XC1.ms');
    qimagermaketestms(msfile);

    # Start timing here
    note('## Start timing')
    note('## Running qimagerpbtest with ', size, ' by ', size, ' pixel images')
    stime:=time()

    # Create the qimager object
    note('## Creating qimager object from MeasurementSet ', msfile);
    global anqimagertest:=qimager(msfile);
    if (is_fail(anqimagertest)) throw(anqimagertest::message);

    note('## Set up the image parameters')
    cell:='0.4arcsec'
    include 'measures.g';
    mcore:=dm.direction('b1950', '12h26m33.248000', '02d19m43.290000');
    note('## Image will be in RA,DEC coordinates')
    ok:=anqimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=mcore,doshift=T)
    if(is_fail(ok)) throw(ok::status);

    note('## Set up the data selection parameters')
    ok:=anqimagertest.setdata(mode='none', nchan=1, start=1, step=1);
    if(is_fail(ok)) throw(ok::status);

    note('## Switching on Primary beam correction')
    ok:=anqimagertest.setvp(dovp=T, usedefaultvp=T);
    if(is_fail(ok)) throw(ok::status);

    note('## Make an empty image')
    ok:=anqimagertest.make(image=spaste(testdir, '/', '3C273XC1.dirty'));
    if(is_fail(ok)) throw(ok::status);

    note('## Weight the data')
    ok:=anqimagertest.weight(type='briggs');
    if(is_fail(ok)) throw(ok::status);

    note('## Filter the data')
    ok:=anqimagertest.filter(type="gaussian", bmaj="2arcsec", bmin="2arcsec");
    if(is_fail(ok)) throw(ok::status);

    note ('## MF Clean')
    ok:=anqimagertest.setbeam(bmaj="5arcsec", bmin="5arcsec");
    if(is_fail(ok)) throw(ok::status);
    ok:=anqimagertest.clean(algorithm='mfclark',
			   model=spaste(testdir, '/', '3C273XC1.clean'), 
			   niter=cleanniter, gain=cleangain,
			   threshold='1Jy',
			   image=spaste(testdir, '/', '3C273XC1.restored'));
    if(is_fail(ok)) throw(ok::status);

    # close
    note('## Close the qimager object')
    ok := anqimagertest.close(); 
    if (!ok) {
	throw('Unexpected close error (1)')
    }
    ok := anqimagertest.done(); 
    if (!ok) {
	throw('Unexpected done error (1)')
    }

    etime:=time();
    note(sprintf('## Finished successfully in run time = %5.2f (s) for size = %d ',
	     etime-stime, size));

    return T
}





const qimagersdtest:=function() {

  global dowait:=T;

  # Variables that define the demonstration
  const testdir := 'qimagersdtest';
  
  note('Cleaning up directory ', testdir);
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); };

  # Make the directory
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw("rm fails!") };
  ok := shell(paste("mkdir", testdir));
  if (ok::status) { throw("mkdir", testdir, "fails!") };

  # Make the data
  msfile:=spaste(testdir, '/gbt_cygnus_800MHz.ms');
  if(is_fail(qimagermaketestsdms(msfile))) fail;

  imagefile:=spaste(testdir, '/gbt_cygnus_800MHz.image');
  weightfile:=spaste(testdir, '/gbt_cygnus_800MHz.scanweight');
  gridfile:=spaste(testdir, '/gbt_cygnus_800MHz.scanimage');

  # Create the qimager object
  note('## Creating qimager object from MeasurementSet ', msfile);
  global anqimagertest:=qimager(msfile);
  if (is_fail(anqimagertest)) throw(anqimagertest::message);
  #
  # Use the data from one cal phase only
  #
  anqimagertest.setdata(fieldid=1,spwid=1,
		       msselect='NRAO_GBT_RECEIVER_ID==0&&NRAO_GBT_STATE_ID==1');
  #
  dir:=dm.direction('J2000', '20:15:00.00', '+040.30.00');

  anqimagertest.setimage(nx=144, ny=100,
			cellx='4arcmin',celly='4arcmin',
			stokes='I',
			doshift=T, phasecenter=dir, spwid=1);
      
  anqimagertest.setoptions(gridfunction='PB')
  #
  # Make the coverage image
  #
  anqimagertest.makeimage(image=weightfile, type='coverage');
  #
  #
  include 'image.g';
  s:=0;
  imcov := image(weightfile); imcov.statistics(s); imcov.done();
  threshold := s.max / 100.0;
  #
  anqimagertest.makeimage(image=gridfile, type='singledish');
  #
  # Threshold coverage image to avoid undersampled points
  #
  lweightfile := weightfile ~ s!/!\\/!g;
  lgridfile   := gridfile ~ s!/!\\/!g;

  command := spaste(lgridfile,'[',lweightfile,'>', threshold,
			    ']/',lweightfile,'[',lweightfile,'>',
		    threshold, ']');
  note('Thresholding using image calculator command ', command);
  imf:=imagecalc(imagefile, command); imf.statistics(); imf.done();

  ok := anqimagertest.close(); 
  if (!ok) {
    throw('Unexpected close error (1)');
  }
  ok := anqimagertest.done(); 
  if (!ok) {
    throw('Unexpected done error (1)');
  }
  
  return T;
}

const qimagercomponenttest := function(size=256, doshift=F, doplot=T)
{

  global dowait:=T;

    # Variables that define the demonstration
  testdir := 'qimagercomponenttest';
  if(doshift) testdir:=spaste(testdir,'-shifted');

    note('Cleaning up directory ', testdir)
    ok := shell(paste("rm -fr ", testdir))
    if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); }

    # Make the directory
    ok := shell(paste("rm -fr ", testdir))
    if (ok::status) { throw("rm fails!") }
    ok := shell(paste("mkdir", testdir))
    if (ok::status) { throw("mkdir", testdir, "fails!") }

    # Make the data
    msfile:=spaste(testdir, '/','3C273XC1.ms');
    qimagermaketestms(msfile);

    # Start timing here
    note('## Start timing')
    note('## Running qimagercomponenttest with ', size, ' by ', size, ' pixel images')
    stime:=time()

    # Make component list file
    clfile:=spaste(testdir, '/','3C273XC1.cl');
    qimagermaketestcl(clfile);

    # Create the qimager object
    note('## Creating qimager object from MeasurementSet ', msfile);
    global anqimagertest:=qimager(msfile);
    if (is_fail(anqimagertest)) throw(anqimagertest::message);

    note('## Set up the image parameters')
    cell:='0.4arcsec'
    include 'measures.g';
    pc:=dm.direction('b1950', '12h26m32.687538', '02d19m34.489993')
    if(doshift) {
      note('## Image will be in galactic coordinates')
      pc:=dm.measure(pc,'gal');
      ok:=anqimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=pc,doshift=T)
    }
    else {
      note('## Image will be in RA,DEC coordinates')
      ok:=anqimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=pc,doshift=T)
    }
    if(is_fail(ok)) throw(ok::status);

    note('## Set up the data selection parameters')
    ok:=anqimagertest.setdata(mode='none', nchan=1, start=1, step=1, fieldid=1,
		   spwid=1);
    if(is_fail(ok)) throw(ok::status);

    note('## Get a summary of the state of the object')
    ok:=anqimagertest.summary();
    if(is_fail(ok)) throw(ok::status);

    note('## Make an empty image')
    ok:=anqimagertest.make(image=spaste(testdir, '/', '3C273XC1.clean'));
    if(is_fail(ok)) throw(ok::status);

    note ('## Fourier transform')
    ok:=anqimagertest.ft(complist=clfile, model=spaste(testdir, '/', '3C273XC1.clean'));
    if(is_fail(ok)) throw(ok::status);

    if(doplot&&have_gui()) {
      note ('## Plot visibilities')
      ok:=anqimagertest.plotvis();
      if(is_fail(ok)) throw(ok::status);
    }

    note ('## Hogbom Clean')
    ok:=anqimagertest.clean(algorithm='hogbom', complist=clfile,
		 model=spaste(testdir, '/', '3C273XC1.clean'), 
		 niter=1000, gain=0.1,
		 image=spaste(testdir, '/', '3C273XC1.clean.restored'));
    if(is_fail(ok)) throw(ok::status);

    # close
    note('## Close the qimager object')
    ok := anqimagertest.close(); 
    if (!ok) {
	throw('Unexpected close error (1)')
    }
    ok := anqimagertest.done(); 
    if (!ok) {
	throw('Unexpected done error (1)')
    }

    etime:=time();
    note(sprintf('## Finished successfully in run time = %5.2f (s) for size = %d ',
	     etime-stime, size));
    return T
}


const qimagerselfcaltest := function(size=256, doshift=F, doplot=T)
{

  include 'calibrater.g';

  global dowait:=T;

    # Variables that define the demonstration
  testdir := 'qimagerselfcaltest';
  if(doshift) testdir:=spaste(testdir,'-shifted');

    note('Cleaning up directory ', testdir)
    ok := shell(paste("rm -fr ", testdir))
    if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); }

    # Make the directory
    ok := shell(paste("rm -fr ", testdir))
    if (ok::status) { throw("rm fails!") }
    ok := shell(paste("mkdir", testdir))
    if (ok::status) { throw("mkdir", testdir, "fails!") }

    # Make the data
    msfile:=spaste(testdir, '/','3C273XC1.ms');
    qimagermaketestms(msfile);

    # Start timing here
    note('## Start timing')
    note('## Running qimagerselfcaltest with ', size, ' by ', size, ' pixel images')
    stime:=time()

    # Create the qimager object
    note('## Creating qimager object from MeasurementSet ', msfile);
    global anqimagertest:=qimager(msfile);
    if (is_fail(anqimagertest)) throw(anqimagertest::message);

    note('## Set up the image parameters')
    cell:='0.4arcsec'
    include 'measures.g';
    pc:=dm.direction('b1950', '12h26m33.248000', '02d19m43.290000');
    if(doshift) {
      note('## Image will be in galactic coordinates')
      pc:=dm.measure(pc,'gal');
      ok:=anqimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=pc,doshift=T)
    }
    else {
      note('## Image will be in RA,DEC coordinates')
      ok:=anqimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=pc,doshift=T)
    }
    if(is_fail(ok)) throw(ok::status);

    note('## Set up the data selection parameters')
    ok:=anqimagertest.setdata(mode='none', nchan=1, start=1, step=1, fieldid=1,
		   spwid=1);
    if(is_fail(ok)) throw(ok::status);

    note ('## Hogbom Clean')
    ok:=anqimagertest.clean(algorithm='hogbom', 
		 model=spaste(testdir, '/', '3C273XC1.clean'), 
		 niter=1000, gain=0.1,
		 image=spaste(testdir, '/', '3C273XC1.clean.restored'));
    if(is_fail(ok)) throw(ok::status);

    note ('## Clip the image')
    ok:=anqimagertest.clipimage(image=spaste(testdir, '/', '3C273XC1.clean'), 
		     threshold='750mJy')
    if(is_fail(ok)) throw(ok::status);
   
    # Create the cal object
    ok := eval('include \'calibrater.g\'');
    note('## Creating calibrater object from MeasurementSet ', msfile);
    ca:=calibrater(msfile);
    if (is_fail(ca)) throw(ca::message);

    note ('## Set up calibrater object');
    tjones:=spaste(testdir, '/', '3C273XC1.tjones');
    gjones:=spaste(testdir, '/', '3C273XC1.gjones');
    ok:=ca.setsolve(type='T', t=60.0, phaseonly=T, table=tjones, append=F);
    if(is_fail(ok)) throw(ok::status);
    ok:=ca.setsolve(type='G', t=600.0, phaseonly=F, table=gjones, append=F);
    if(is_fail(ok)) throw(ok::status);

    note ('## Do the selfcal');
    ok:=anqimagertest.selfcal(caltool=ca, 
		   model=spaste(testdir, '/', '3C273XC1.clean'));
    if(is_fail(ok)) throw(ok::status);

    note ('## Hogbom Clean')
    ok:=anqimagertest.clean(algorithm='hogbom',
		 model=spaste(testdir, '/', '3C273XC1.selfcal.clean'), 
		 niter=1000, gain=0.1,
		 image=spaste(testdir, '/', '3C273XC1.selfcal.clean.restored'));
    if(is_fail(ok)) throw(ok::status);

    # close
    note('## Close the qimager object')
    ok := anqimagertest.close(); 
    if (!ok) {
	throw('Unexpected close error (1)')
    }
    ok := anqimagertest.done(); 
    if (!ok) {
	throw('Unexpected done error (1)')
    }

    # close
    note('## Close the cal object')
    ok := ca.close(); 
    if (!ok) {
	throw('Unexpected close error (1)')
    }
#    ok := ca.done(); 
#    if (!ok) {
#	throw('Unexpected done error (1)')
#    }

    etime:=time();
    note(sprintf('## Finished successfully in run time = %5.2f (s) for size = %d ',
	     etime-stime, size));
    return T
}


const qimagerbetatests := function(){return qimageralltests('beta');}
const qimagerlitetests := function(){return qimageralltests('lite');}

const qimageralltests:=function(level='all') {

 include 'logger.g'

  const note := function(...) { defaultlogger.note(...,
						   origin='qimageralltests()') }

  note ('## Running all qimagertests');
  stime:=time()

  qimagertestresult:=qimagertest(level);
  qimagerpbtestresult:=qimagerpbtest();
  qimagerselfcaltestresult:=qimagerselfcaltest();
  qimagercomponenttestresult:=qimagercomponenttest();

  etime:=time();
  note(sprintf('## Finished all tests in run time = %5.2f (s)', (etime - stime)));
  
  note('## Status of tests:')
  note('   qimagertest status : ', qimagertestresult);
  note('   qimagerpbtest status : ', qimagerpbtestresult);
  note('   qimagerselfcaltest status : ', qimagerselfcaltestresult);
  note('   qimagercomponenttest status : ', qimagercomponenttestresult);
  qimagerspectraltestresult := T;

  return qimagertestresult&&
    qimagerpbtestresult&&
      qimagerselfcaltestresult&&
      qimagercomponenttestresult;
}


const qimagermultiscale := function(msname='', imsizes=[128, 256], cellsizes=[2, 1], 
scales=[0, 5, 15], nitermult=0.15, niterpower=1.2, fields=[1], spwid=1, centerfield=1) 
{
  dowait:=T;

  if (len(imsizes) != len(cellsizes))  {
     stop ('imsizes and cellsizes vectors must be the same length');
  }
# Does the MS exist?
  if(!tableexists(msname)) {
    stop ('MeasurementSet ', msname, ' does not exist');
  }
  if (len(fields) < 1) {
    stop ('Need at least one field');
  }
  if (len(scales) < 1) {
    stop ('Need at least one scale');
  }

# get everything in the right order
  scales := sort(scales);
  imsizes := sort(imsizes);
  cellsizes := - sort ( - cellsizes );

  ok := note('This function performs several rounds of multi-scale clean deconvolutions');
  ok := note('on single or multi-field data.  Each succesive round should be performed');
  ok := note('with larger images and smaller pixels.');
  ok := note('If the control and parameterization do not meet your needs,');
  ok := note('you may want to create your own function by editing this one,');
  ok := note(paste('Image sizes requested: ', imsizes));
  ok := note(paste('Cell sizes requested: ', cellsizes));
  ok := note(paste('Scale sizes requested: ', scales));

  nfields := len(fields);
  algorithm := 'mfmultiscale';
  if (nfields == 1)  algorithm := 'multiscale';

  taper:= 2.5*cellsizes;

  for (i in [1:len(imsizes)] ) {
    niter := as_integer(nitermult*(imsizes[i]^niterpower));
    ok := note(paste('Round ', i, ' will use ', niter, ' iterations  on ', imsizes[i], 
	'^2 pixel images with ', cellsizes[i],' arcsec cells'));
    print (paste('Round ', i, ' will use ', niter, ' iterations  on ', imsizes[i], 
	'^2 pixel images with ', cellsizes[i],' arcsec cells'));

  }

  myqimager:=qimager(msname);
  ok :=myqimager.setdata(mode="none" , nchan=1, start=1, step=1, 
  mstart="0km/s", mstep="0km/s", spwid=spwid, fieldid=fields );
  
  basename := spaste('mms.', msname);
  previousmodel := '';
  finalimage := spaste(basename, '.', len(imsizes), '.restored');

  for (i in [1:len(imsizes)] ) {  
    modname := spaste(basename, '.', i, '.mod');
    imgname := spaste(basename, '.', i, '.restored');
    resname := spaste(basename, '.', i, '.residual');
    tempname := spaste(basename, '.', i, '.template');
  
    print (paste('Round ', i, ' made with imagesize = ', imsizes[i], ' and model ', modname));
    ok := note (paste('Round ', i, ' made with imagesize = ', imsizes[i], ' and model ', modname));
  
    ok :=myqimager.setimage(nx=imsizes[i], ny=imsizes[i], 
      cellx=spaste(cellsizes[i],"arcsec"), celly=spaste(cellsizes[i],"arcsec"),
      stokes="I",  doshift=F,
      shiftx="0arcsec", shifty="0arcsec", mode="mfs" , nchan=1, start=1, step=1, 
      mstart="0km/s", mstep="0km/s", spwid=spwid, fieldid=centerfield, facets=1);

    ok :=myqimager.weight(type="uniform" );
    ok :=myqimager.filter(type="gaussian", bmaj=spaste(taper[i],"arcsec"), bmin=spaste(taper[i],"arcsec"));
    ok :=myqimager.setvp(dovp=T, usedefaultvp=T);
    ok :=myqimager.setscales(scalemethod='uservector', uservector=scales);
  
  # If there is a previous model, regrid it to the current imsizes (large image)
  # and use that as a starting model for the next round of cleaning 
    if (previousmodel != '') {
  	ok := myqimager.makeimage(type='psf', image=tempname);
  	imgsmall := image(previousmodel);
  	imgbig   := image(tempname);
        cs := imbig.coordsys()
  	imgnew   := imgsmall.regrid(outfile=modname, csys=cs,
  			shape=imgbig.shape(), axes=[1,2]);
#
  	ok := imgnew.done();
  	ok := imgbig.done();
  	ok := imgsmall.done();
        ok := cs.done();
        print (paste('Regridded ', previousmodel, ' to size of ', modname));
        ok := note (paste('Regridded ', previousmodel, ' to size of ', modname));
    }
  
  # calculate the number of iterations to do this round
    niter := as_integer(nitermult*(imsizes[i]^niterpower));
    speedup := niter/3;

    stoplargenegs := 2
    if (i > 1) stoplargenegs := -1;
    ok := myqimager.setmfcontrol(cyclefactor=1.5, cyclespeedup=speedup,
				stoplargenegatives=stoplargenegs,
			  	stoppointmode=4);
    ok :=myqimager.clean(algorithm=algorithm , niter=niter, gain=0.7,
                          threshold="0Jy", 
  			  displayprogress=T,
                          model=modname, fixed=F,
                          complist='', mask='',
                          image=imgname,
                          residual=resname);
    
    previousmodel := modname;

    print (paste('Finished model ', modname));
    ok := note (paste('Finished model ', modname));
  }
  ok := myqimager.done();

  if (ok && tableexists()) {
	return T;
  }
  return F;
}

