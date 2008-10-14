# pimager.g: Make images from AIPS++ MeasurementSets
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
#   $Id: pimager.g,v 19.1 2004/08/25 01:47:10 cvsmgr Exp $
#

pragma include once

include 'plugins.g'
include 'servers.g'
include 'note.g'

#defaultservers.suspend(T)
#defaultservers.trace(T)

# Users aren't to use this.
const _define_pimager := function(ref agent, id) {
    self := [=]
    public := [=]

    self.agent := ref agent;
    self.id := id;

    self.openRec := [_method="open", _sequence=self.id._sequence]
    public.open := function(thems) {
	wider self;
	self.openRec.thems := thems;
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

    self.setimageRec := [_method="setimage", _sequence=self.id._sequence]
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
	self.setimageRec.nx:=nx;
	self.setimageRec.ny:=ny;
        self.setimageRec.cellx:=cellx;
        self.setimageRec.celly:=celly;
        self.setimageRec.stokes:=stokes;
        self.setimageRec.doshift:=doshift;
        self.setimageRec.phasecenter:=phasecenter;
        self.setimageRec.shiftx:=shiftx;
        self.setimageRec.shifty:=shifty;
        self.setimageRec.mode:=mode;
        self.setimageRec.nchan:=nchan;
        self.setimageRec.start:=start;
        self.setimageRec.step:=step;
        self.setimageRec.mstart:=mstart;
        self.setimageRec.mstep:=mstep;
        self.setimageRec.spwid:=spwid;
        self.setimageRec.fieldid:=fieldid;
        self.setimageRec.facets:=facets;
	self.setimageRec.distance:=distance;
	return defaultservers.run(self.agent, self.setimageRec);
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
    public.setdata:=function(mode='none', nchan=1, start=1, step=1,
               		     mstart='0km/s',
                             mstep='0km/s',
			     spwid=[], fieldid=[], 
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
    public.setoptions:=function(ftmachine='gridft',
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
    public.weight:=function(type="uniform", rmode="rnorm", noise='0.0Jy',
			    robust=0.0, fieldofview="0rad", npixels=0,
			    async=!dowait) {
        wider self;
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

    self.makeimageRec := [_method="makeimage", _sequence=self.id._sequence]
    public.makeimage:=function(type="observed", image='',
			   compleximage='', async=!dowait) {
        wider self;
	self.makeimageRec.type:=type;
	self.makeimageRec.image:=image;
	self.makeimageRec.compleximage:=compleximage;
	return defaultservers.run(self.agent, self.makeimageRec, async);
    }

    public.image:=function(type="observed", image='',
			   compleximage='', async=!dowait) {
        wider self;
	mymessage := 
        note('Function \'image\' has been renamed as \'makeimage\' ', priority='WARN');
        note('Please update your usage', priority='WARN');
	return public.makeimage(type, image, compleximage, async);
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
			   async=!dowait) {
        wider self;
	self.cleanRec.algorithm:=algorithm;
	self.cleanRec.niter:=niter;
	self.cleanRec.gain:=gain;
	self.cleanRec.threshold:=threshold;
	self.cleanRec.displayprogress:=displayprogress;
	self.cleanRec.model:=model;
	self.cleanRec.fixed:=fixed;
	self.cleanRec.complist:=complist;
	self.cleanRec.mask:=mask;
	self.cleanRec.image:=image;
	self.cleanRec.residual:=residual;
	returnval := defaultservers.run(self.agent, self.cleanRec, async);
        return returnval;
    }

    self.memRec := [_method="mem", _sequence=self.id._sequence]
    public.mem:=function(algorithm='entropy', niter=20, sigma='0.001Jy',
			   targetflux='1.0Jy', constrainflux=F,
			   displayprogress=F, model='', fixed=F,
			   complist='', prior='', mask='', 
                           image='', residual='', async=!dowait) {
        wider self;
	self.memRec.algorithm:=algorithm;
	self.memRec.niter:=niter;
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
    public.setmfcontrol:=function(cyclefactor=3.0, cyclespeedup=-1,
      			stoplargenegatives=2, stoppointmode=-1,fluxscale='',
			async=!dowait) {
	wider self;
	self.setmfcontrolRec.cyclefactor:=cyclefactor;
	self.setmfcontrolRec.cyclespeedup:=cyclespeedup;
	self.setmfcontrolRec.stoplargenegatives:=stoplargenegatives;
	self.setmfcontrolRec.stoppointmode:=stoppointmode;
	self.setmfcontrolRec.fluxscale:=fluxscale;
	returnval := defaultservers.run(self.agent, self.setmfcontrolRec, async);
        return returnval;
    }

    self.featherRec := [_method="feather", _sequence=self.id._sequence]
    public.feather:=function(image='', highres='', lowres='',  
				usedefaultvp=T, vptable='', async=!dowait) {
        wider self;
	self.featherRec.image:=image;
	self.featherRec.highres:=highres;
	self.featherRec.lowres:=lowres;
	self.featherRec.usedefaultvp:=usedefaultvp;
	self.featherRec.vptable:=vptable;
	return defaultservers.run(self.agent, self.featherRec, async);
    }

    self.ftRec := [_method="ft", _sequence=self.id._sequence]
    public.ft:=function(model='', complist='', incremental=F, async=!dowait) {
        wider self;
	self.ftRec.model:=model;
	self.ftRec.complist:=complist;
	self.ftRec.incremental:=incremental;
	return defaultservers.run(self.agent, self.ftRec, async);
    }

    self.setjyRec := [_method="setjy", _sequence=self.id._sequence]
    public.setjy:=function(fieldid=-1, spwid=-1, fluxdensity=-1, 
	async=!dowait) {
        wider self;
	self.setjyRec.fieldid:=fieldid;
	self.setjyRec.spwid:=spwid;

        self.setjyRec.fluxdensity:=fluxdensity;
        i:=len(self.setjyRec.fluxdensity);
	if (i < 4) self.setjyRec.fluxdensity[(i+1):4]:=0.0;

	return defaultservers.run(self.agent, self.setjyRec, async);
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

    self.correctRec := [_method="correct", _sequence=self.id._sequence]
    public.correct:=function(doparallactic=T, timestep='1s', async=!dowait) {
        wider self;
        self.correctRec.doparallactic:=doparallactic;
        self.correctRec.timestep:=timestep;
	return defaultservers.run(self.agent, self.correctRec, async);
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
	dosquint=T,parangleinc='360deg') {
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
    public.regionmask:=function(mask='', region=unset, value=1.0) {
        wider self;

        if(!is_string(mask)||(mask==''))
	    return throw('mask must be specified');
        if(!is_unset(region)&&!is_region(region))
	    return throw('region must be a valid region');
        if(is_fail(public.make(mask))) fail;

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

    self.clipimageRec := [_method="clipimage", _sequence=self.id._sequence]
    public.clipimage:=function(image='', threshold='0.0Jy', async=!dowait) {
        wider self;
	self.clipimageRec.image:=image;
	self.clipimageRec.threshold:=threshold;
	return defaultservers.run(self.agent, self.clipimageRec, async);
      }

    self.clipvisRec := [_method="clipvis", _sequence=self.id._sequence]
    public.clipvis:=function(threshold='0.0Jy', async=!dowait) {
        wider self;
	self.clipvisRec.threshold:=threshold;
	return defaultservers.run(self.agent, self.clipvisRec, async);
      }

    self.plotuvRec := [_method="plotuv", _sequence=self.id._sequence]
    public.plotuv:=function(rotate=F, async=!dowait) {
        wider self;
        self.plotuvRec.rotate:=rotate;
	return defaultservers.run(self.agent, self.plotuvRec, async);
    }

    self.plotsummaryRec := [_method="plotsummary", _sequence=self.id._sequence]
    public.plotsummary:=function(async=!dowait) {
        wider self;
	return defaultservers.run(self.agent, self.plotsummaryRec, async);
    }

    self.plotvisRec := [_method="plotvis", _sequence=self.id._sequence]
    public.plotvis:=function(type="all", increment=1, async=!dowait) {
        wider self;
	self.plotvisRec.type:=type;
	self.plotvisRec.increment:=increment;
	return defaultservers.run(self.agent, self.plotvisRec, async);
    }

    self.plotweightsRec := [_method="plotweights", _sequence=self.id._sequence]
    public.plotweights:=function(gridded=F, increment=1, async=!dowait) {
        wider self;
	self.plotweightsRec.gridded:=gridded;
	self.plotweightsRec.increment:=increment;
	return defaultservers.run(self.agent, self.plotweightsRec, async);
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

    self.tryparreadRec := [_method="tryparread", _sequence=self.id._sequence]
    public.tryparread:=function(ms, numloops=8) {
        wider self;
	self.tryparreadRec.ms:=ms;
	self.tryparreadRec.numloops:=numloops;
	returnval := defaultservers.run(self.agent, self.tryparreadRec, async);
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
            f.text->insert('pimager closed', 'start');
        } else {
            f.text->delete('start', 'end');
            f.text->insert(public.state(), 'start');
        }
        return T;
    }

    public.type := function() {
      return 'pimager';
    }

    plugins.attach('pimager', public);
    return ref public;

} # _define_pimager()


# Make a new server for every invocation
const pimager := function(filename='', host='', forcenewserver=T, numprocs=1) {
  include 'os.g';

  if (filename=='') {
    throw('Must supply a measurementset filename');
    return F;
  } else if (!dos.fileexists(filename)) {
    throw('Measurementset ', filename, ' nonexistent!');
    return F;	
  }

  global system;
       # numprocs can never be less than two for mpi at least right now.
   if(numprocs > 1){
      parallel := T;
   } else {
      numprocs := 2
      parallel := T;
   }
   if(has_field(system, 'numprocs')){
       system.numprocs.pimager := numprocs;
   } else {
       system.numprocs := [=];
       system.numprocs.pimager := numprocs;
   }

    include 'getrc.g';
    getrc.find(system.mpicommand, 'system.parallel.mpicommand');

    agent := defaultservers.activate("pimager", host, forcenewserver,
                                      async=parallel)
  if(is_fail(agent)) fail;
  id := defaultservers.create(agent, "pimager", "pimager", [thems=filename]);
  if(is_fail(id)) fail;
  return ref _define_pimager(agent,id);

} 

const pimagertester := function(npixels=3000, nfacets=5, numprocs=3)
{

# Initial clean up and naming
  include 'note.g';
  note('Cleaning up test directory pimagertest');
  shell('rm -rf pimagertest');
  shell('mkdir pimagertest');
  msname:=spaste('pimagertest/','new3ddat.ms');
  model:=spaste('pimagertest/','para');
  image:=spaste(model,'.restored');
  residual:=spaste(model, '.residual');
  niter:=10000/nfacets/nfacets;

# Create ms
  note('Creating ms');
  pimagermaketestms(msname);
# run pimager
  time1:=time();
  pim:=pimager(msname,numprocs=numprocs);
  pim.setimage(nx=npixels, ny=npixels, cellx='30arcsec',celly='30arcsec',
	       facets=nfacets);
  pim.setoptions(padding=1.5);
  pim.clean(algorithm='wfclark',model=model,image=image,
	    residual=residual, niter=niter);
  pim.done();
  time2:=time();
  print "Time taken=", (time2-time1)/60, " minutes";   
 
}

const pimagermaketestcl:=function(clfile='3C273XC1.cl', refer='b1950')
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

const pimagermaketestms := function(msfile='new3ddat.ms') {

  include "ms.g";
  # Make the data
  include "sysinfo.g";
  aipsroot:=sysinfo().root();
  fitsfile:=spaste(aipsroot, '/data/demo/3DDAT.fits');
  ok := shell(paste("rm -fr ", msfile))
  msnew:=fitstoms(msfile, fitsfile, readonly=F);
  if(has_field(msnew, 'close')) {
    msnew.close();
    msnew.done();
  }

}


# makes a measurement set with 7 VLA D-array pointings on CAS A at 8 GHz 
const pimagermaketestmfms := function(msfile='XCAS.ms') {

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



const pimagertest := function(size=256, cleanniter=1000, cleangain=0.1, doshift=F,
			     doplot=T, cache=1024*1024, algorithm='clark', numprocs=2)
{

  global dowait:=T;

    # Variables that define the demonstration
  testdir := 'pimagertest';
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
    pimagermaketestms(msfile);

    # Start timing here
    note('## Start timing')
    note('## Running pimagertest with ', size, ' by ', size, ' pixel images')
    stime:=time()

    # Create the pimager object
    note('## Creating pimager object from MeasurementSet ', msfile);
    global anpimagertest:=pimager(msfile, numprocs=numprocs);
    if (is_fail(anpimagertest)) throw(anpimagertest::message);

    note('## Pimager has member functions: ', anpimagertest);

    note('## Set up the image parameters')
    cell:='0.4arcsec'
    include 'measures.g';
    mcore:=dm.direction('b1950', '12h26m33.248000', '02d19m43.290000');
    if(doshift) {
      note('## Image will be in galactic coordinates')
      pc:=dm.measure(mcore,'gal');
      ok:=anpimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=pc,doshift=T)
    }
    else {
      note('## Image will be in RA,DEC coordinates')
      ok:=anpimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=mcore,doshift=T)
    }
    if(is_fail(ok)) throw(ok::status);

    note('## Set up the cache size to be ', cache, ' pixels')
    ok:=anpimagertest.setoptions(cache=cache, padding=1.2)
    if(is_fail(ok)) throw(ok::status);

    note('## Set up the data selection parameters')
    ok:=anpimagertest.setdata(mode='all', nchan=1, start=1, step=1, fieldid=1,
		   spwid=1);
    if(is_fail(ok)) throw(ok::status);

    note('## Get a summary of the state of the object')
    ok:=anpimagertest.summary();
    if(is_fail(ok)) throw(ok::status);

    note('## Make an empty image')
    ok:=anpimagertest.make(image=spaste(testdir, '/', '3C273XC1.dirty'));
    if(is_fail(ok)) throw(ok::status);

    note('## Weight the data')
    ok:=anpimagertest.weight(type='briggs');
    if(is_fail(ok)) throw(ok::status);

    note('## Filter the data')
    ok:=anpimagertest.filter(type="gaussian", bmaj="2arcsec", bmin="2arcsec");
    if(is_fail(ok)) throw(ok::status);

    note('## Calculate the psf')
    ok:=anpimagertest.makeimage(type='psf', image=spaste(testdir, '/', '3C273XC1.psf'));
    if(is_fail(ok)) throw(ok::status);

    note('## Fit the psf')
    bmaj:=F; bmin:=F; bpa:=F;
    ok:=anpimagertest.fitpsf(spaste(testdir, '/', '3C273XC1.psf'), bmaj=bmaj,
			    bmin=bmin, bpa=bpa);
    if(is_fail(ok)) throw(ok::status);
    note('## Fitted beam: ', bmaj, bmin, bpa)

    note ('## Make a dirty image')
    ok:=anpimagertest.makeimage(type='observed', image=spaste(testdir, '/', '3C273XC1.dirty'))
    if(is_fail(ok)) throw(ok::status);
    
    if(cleanniter==0) {
      # close
      note('## Close the pimager object')
      ok := anpimagertest.close(); 
      if (!ok) {
  	throw('Unexpected close error (1)')
      }
      ok := anpimagertest.done(); 
      if (!ok) {
  	throw('Unexpected done error (1)')
      }
      return;
    }

    note('## Make a mask from a box')
    ok:=anpimagertest.make(image=spaste(testdir, '/', '3C273XC1.mask'));
    if(is_fail(ok)) throw(ok::status);
    ok:=anpimagertest.boxmask(spaste(testdir, '/', '3C273XC1.mask'),
		   blc=[95+size/2-128,65+size/2-128,1,1],
		   trc=[185+size/2-128,150+size/2-128,2,1]);
    if(is_fail(ok)) throw(ok::status);

    note ('## Clark Clean')
    ok:=anpimagertest.clean(algorithm=algorithm,
		 model=spaste(testdir, '/', '3C273XC1.clean'), 
                 mask=spaste(testdir, '/', '3C273XC1.mask'),
		 niter=cleanniter, gain=cleangain,
		 image=spaste(testdir, '/', '3C273XC1.restored'),
		 residual=spaste(testdir, '/', '3C273XC1.residual'));

    if(is_fail(ok)) throw(ok::status);

    note ('## Fourier transform')
    ok:=anpimagertest.ft(model=spaste(testdir, '/', '3C273XC1.clean'));
    if(is_fail(ok)) throw(ok::status);

    if(doplot&&have_gui()) {
      note ('## Plot visibilities')
      ok:=anpimagertest.plotvis();
      if(is_fail(ok)) throw(ok::status);
    }

    note ('## Calculating restored image correctly')
    ok:=anpimagertest.restore(model=spaste(testdir, '/', '3C273XC1.clean'), 
			     image=spaste(testdir, '/', '3C273XC1.restored'),
			     residual=spaste(testdir, '/', '3C273XC1.residual'));
  if(is_fail(ok)) throw(ok::status);

    note ('## Smooth the restored image')
    ok:=anpimagertest.smooth(model=spaste(testdir, '/', '3C273XC1.restored'),
		  image=spaste(testdir, '/', '3C273XC1.restored.smoothed'),
		  bmaj="5arcsec", bmin="5arcsec");
    if(is_fail(ok)) throw(ok::status);

    note ('## Make a thresholded mask')
    ok:=anpimagertest.mask(image=spaste(testdir, '/', '3C273XC1.restored.smoothed'),
		mask=spaste(testdir, '/', '3C273XC1.thresholdmask'),
		threshold='0.05Jy');
    if(is_fail(ok)) throw(ok::status);

    note ('## Clean with thresholded mask')
    ok:=anpimagertest.clean(algorithm=algorithm,
		 model=spaste(testdir, '/', '3C273XC1.clean.masked'), 
		 mask=spaste(testdir, '/', '3C273XC1.thresholdmask'),
		 niter=cleanniter, gain=cleangain,
		 image=spaste(testdir, '/', '3C273XC1.restored'));
    if(is_fail(ok)) throw(ok::status);

    note ('## Make a residual image on the Sun');
    include 'measures.g';
    pc:=dm.direction('sun');
    ok:=anpimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
		    stokes='IV',phasecenter=pc,doshift=T);
    if(is_fail(ok)) throw(ok::status);
    ok:=anpimagertest.makeimage(type='residual', image=spaste(testdir, '/', 'sun.residual'));
    if(is_fail(ok)) throw(ok::status);

    note ('## Make a residual image at the celestial pole (J2000)')
    include 'measures.g';
    pc:=dm.direction('j2000')
    ok:=anpimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
      stokes='IV',phasecenter=pc,doshift=T)
    if(is_fail(ok)) throw(ok::status);
    ok:=anpimagertest.makeimage(type='residual', image=spaste(testdir, '/', 'pole.residual'))
    if(is_fail(ok)) throw(ok::status);

    note ('## Make a residual image due south')
    pc:=dm.direction('azel', '0deg', '-90deg')
    ok:=anpimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
      stokes='IV',phasecenter=pc,doshift=T)
    if(is_fail(ok)) throw(ok::status);
    ok:=anpimagertest.setoptions(location=dm.observatory('VLA'),cache=cache,padding=1.2)
    if(is_fail(ok)) throw(ok::status);
    ok:=anpimagertest.makeimage(type='residual',
		 image=spaste(testdir, '/', 'duesouth.residual'))
    if(is_fail(ok)) throw(ok::status);

    # close
    note('## Close the pimager object')
    ok := anpimagertest.close(); 
    if (!ok) {
	throw('Unexpected close error (1)')
    }
    ok := anpimagertest.done(); 
    if (!ok) {
	throw('Unexpected done error (1)')
    }

    etime:=time();
    note(sprintf('## Finished successfully in run time = %5.2f (s) for size = %d ',
	     etime-stime, size));

    return T
}

const pimagerpbtest := function(size=256, cleanniter=1000, cleangain=0.1)
{
  global dowait:=T;

    # Variables that define the demonstration
  testdir := 'pimagerpbtest';

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
    pimagermaketestms(msfile);

    # Start timing here
    note('## Start timing')
    note('## Running pimagerpbtest with ', size, ' by ', size, ' pixel images')
    stime:=time()

    # Create the pimager object
    note('## Creating pimager object from MeasurementSet ', msfile);
    global anpimagertest:=pimager(msfile);
    if (is_fail(anpimagertest)) throw(anpimagertest::message);

    note('## Set up the image parameters')
    cell:='0.4arcsec'
    include 'measures.g';
    mcore:=dm.direction('b1950', '12h26m33.248000', '02d19m43.290000');
    note('## Image will be in RA,DEC coordinates')
    ok:=anpimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=mcore,doshift=T)
    if(is_fail(ok)) throw(ok::status);

    note('## Set up the data selection parameters')
    ok:=anpimagertest.setdata(mode='all', nchan=1, start=1, step=1);
    if(is_fail(ok)) throw(ok::status);

    note('## Switching on Primary beam correction')
    ok:=anpimagertest.setvp(dovp=T, usedefaultvp=T);
    if(is_fail(ok)) throw(ok::status);

    note('## Make an empty image')
    ok:=anpimagertest.make(image=spaste(testdir, '/', '3C273XC1.dirty'));
    if(is_fail(ok)) throw(ok::status);

    note('## Weight the data')
    ok:=anpimagertest.weight(type='briggs');
    if(is_fail(ok)) throw(ok::status);

    note('## Filter the data')
    ok:=anpimagertest.filter(type="gaussian", bmaj="2arcsec", bmin="2arcsec");
    if(is_fail(ok)) throw(ok::status);

    note ('## MF Clean')
    ok:=anpimagertest.setbeam(bmaj="5arcsec", bmin="5arcsec");
    if(is_fail(ok)) throw(ok::status);
    ok:=anpimagertest.clean(algorithm='mfclark',
			   model=spaste(testdir, '/', '3C273XC1.clean'), 
			   niter=cleanniter, gain=cleangain,
			   threshold='1Jy',
			   image=spaste(testdir, '/', '3C273XC1.restored'));
    if(is_fail(ok)) throw(ok::status);

    # close
    note('## Close the pimager object')
    ok := anpimagertest.close(); 
    if (!ok) {
	throw('Unexpected close error (1)')
    }
    ok := anpimagertest.done(); 
    if (!ok) {
	throw('Unexpected done error (1)')
    }

    etime:=time();
    note(sprintf('## Finished successfully in run time = %5.2f (s) for size = %d ',
	     etime-stime, size));

    return T
}


const pimagerspectraltest := function(size=128, cleanniter=100, cleangain=0.2)
{
  global dowait:=T;

  include "ms.g";
  # Make the data
  include "sysinfo.g";

    # Variables that define the demonstration
    const testdir := 'pimagerspectraltest'

    note('Cleaning up directory ', testdir)
    ok := shell(paste("rm -fr ", testdir))
    if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); }

    # Make the directory
    ok := shell(paste("rm -fr ", testdir))
    if (ok::status) { throw("rm fails!") }
    ok := shell(paste("mkdir", testdir))
    if (ok::status) { throw("mkdir", testdir, "fails!") }

    # Make the data
    aipsroot:=sysinfo().root();
    fitsfile:=spaste(aipsroot, '/data/demo/BLLAC.fits');
    msfile:=spaste(testdir, '/','bllac.ms');
    note('Creating MeasurementSet from', fitsfile);
    msnew:=fitstoms(msfile, fitsfile, readonly=F);
    if (is_fail(msnew)) throw(msnew::message);
    msnew.close();

    # Start timing here
    note('## Start timing')
    note('## Running pimagerspectraltest with ', size, ' by ', size, ' pixel images')
    stime:=time()

    # Create the pimager object
    note('## Creating pimager object from MeasurementSet ', msfile);
    global anpimagertest:=pimager(msfile);
    if (is_fail(anpimagertest)) throw(anpimagertest::message);

    note('## Set up the continuum image specification parameters')
    ok:=anpimagertest.setimage(nx=size,ny=size,cellx='2arcsec',celly='2arcsec',
      stokes='I',doshift=F, mode='mfs', nchan=512, start=1, step=1);
    if(is_fail(ok)) throw(ok::status);

    note('## Set up the data selection parameters')
    ok:=anpimagertest.setdata(mode='channel', nchan=512, start=1, step=1);
    if(is_fail(ok)) throw(ok::status);

    note('## Show summary')
    ok:=anpimagertest.summary();
    if(is_fail(ok)) throw(ok::status);

#    note('## Make a dirty continuum image')
#    ok:=anpimagertest.makeimage('corrected',
#		 image=spaste(testdir, '/', 'bllac.continuum.dirty'));
#    if(is_fail(ok)) throw(ok::status);
    
    note('## Set up the spectral image specification parameters')
    ok:=anpimagertest.setimage(nx=size,ny=size,cellx='2arcsec',celly='2arcsec',
      stokes='I',doshift=F, mode='channel', nchan=64, start=1, step=8);
    if(is_fail(ok)) throw(ok::status);

    note('## Make a dirty spectral image')
    ok:=anpimagertest.makeimage('corrected',
		 image=spaste(testdir, '/', 'bllac.spectral.dirty'));
    if(is_fail(ok)) throw(ok::status);
    
    note('## Perform clean deconvolution');
    ok:=anpimagertest.clean(algorithm='hogbom', niter=cleanniter, threshold='0Jy',
		 gain=cleangain, model=spaste(testdir, '/', 'bllac.model'),
		 image=spaste(testdir, '/', 'bllac.restored'));
    if(is_fail(ok)) throw(ok::status);
    
    # close
    note('## Close the pimager object')
    ok := anpimagertest.close(); 
    if (!ok) {
	throw('Unexpected close error (1)')
    }
    ok := anpimagertest.done(); 
    if (!ok) {
	throw('Unexpected done error (1)')
    }

    etime:=time();
    note(sprintf('## Finished successfully in run time = %5.2f (s) for size = %d ',
	     etime-stime, size));
    return T

}

const pimagermftest:=function(doplot=T, doshift=F) {

  global dowait:=T;

    # Variables that define the demonstration
    const testdir := 'pimagermftest'
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
    pimagermaketestms(msfile);

    # Create the pimager object
    note('## Creating pimager object from MeasurementSet ', msfile);
    global anpimagertest:=pimager(msfile);
    if (is_fail(anpimagertest)) throw(anpimagertest::message);

    include 'measures.g';
    mcore:=dm.direction('b1950', '12h26m33.248000', '02d19m43.290000');
    mjet:=dm.direction('b1950',  '12h26m32.313898', '02d19m27.889981');
    if(doshift) {
      note('## Processing jet image in Galactic coordinates')
      mjet:=dm.measure(mjet, 'gal');
    }

    note('## Setting up the images')
    cell:='0.32arcsec';
    size:=64;
    ok:=anpimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
		    stokes='IV', doshift=T, phasecenter=mcore)
    if(is_fail(ok)) throw(ok::status);
    ok:=anpimagertest.make(image=spaste(testdir, '/', 'core.model'))
    if(is_fail(ok)) throw(ok::status);

    ok:=anpimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
		    stokes='IV', doshift=T, phasecenter=mjet)
    if(is_fail(ok)) throw(ok::status);
    ok:=anpimagertest.make(image=spaste(testdir, '/', 'jet.model'))
    if(is_fail(ok)) throw(ok::status);

    note('## Cleaning the fields')
    ok:=anpimagertest.clean(algorithm='mfclark', niter=1000, gain=0.1, threshold='1000mJy',
			   model=spaste(testdir, '/', 'core.model'),
			   mask='',
			   image=spaste(testdir, '/', 'core.model.restored'));

    if(is_fail(ok)) throw(ok::status);

    note('## Cleaning the fields with field 1 fixed')
    ok:=anpimagertest.clean(algorithm='mfclark', niter=1000, gain=0.1, threshold='500mJy',
			   model=[spaste(testdir, '/', 'core.model'),
				  spaste(testdir, '/', 'jet.model')],
			   fixed=[T,F],
			   mask=['',''],
			   image=[spaste(testdir, '/', 'core.model.restored'),
				  spaste(testdir, '/', 'jet.model.restored')]);

    if(doplot&&have_gui()) {
      note ('## Plot visibilities')
      ok:=anpimagertest.plotvis();
      if(is_fail(ok)) throw(ok::status);
    }

    ok := anpimagertest.close(); 
    if (!ok) {
	throw('Unexpected close error (1)')
    }
    ok := anpimagertest.done(); 
    if (!ok) {
	throw('Unexpected done error (1)')
    }

    return T;
}

const pimagercomponenttest := function(size=256, doshift=F, doplot=T)
{

  global dowait:=T;

    # Variables that define the demonstration
  testdir := 'pimagercomponenttest';
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
    pimagermaketestms(msfile);

    # Start timing here
    note('## Start timing')
    note('## Running pimagercomponenttest with ', size, ' by ', size, ' pixel images')
    stime:=time()

    # Make component list file
    clfile:=spaste(testdir, '/','3C273XC1.cl');
    pimagermaketestcl(clfile);

    # Create the pimager object
    note('## Creating pimager object from MeasurementSet ', msfile);
    global anpimagertest:=pimager(msfile);
    if (is_fail(anpimagertest)) throw(anpimagertest::message);

    note('## Set up the image parameters')
    cell:='0.4arcsec'
    include 'measures.g';
    pc:=dm.direction('b1950', '12h26m32.687538', '02d19m34.489993')
    if(doshift) {
      note('## Image will be in galactic coordinates')
      pc:=dm.measure(pc,'gal');
      ok:=anpimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=pc,doshift=T)
    }
    else {
      note('## Image will be in RA,DEC coordinates')
      ok:=anpimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=pc,doshift=T)
    }
    if(is_fail(ok)) throw(ok::status);

    note('## Set up the data selection parameters')
    ok:=anpimagertest.setdata(mode='all', nchan=1, start=1, step=1, fieldid=1,
		   spwid=1);
    if(is_fail(ok)) throw(ok::status);

    note('## Get a summary of the state of the object')
    ok:=anpimagertest.summary();
    if(is_fail(ok)) throw(ok::status);

    note('## Make an empty image')
    ok:=anpimagertest.make(image=spaste(testdir, '/', '3C273XC1.clean'));
    if(is_fail(ok)) throw(ok::status);

    note ('## Fourier transform')
    ok:=anpimagertest.ft(complist=clfile, model=spaste(testdir, '/', '3C273XC1.clean'));
    if(is_fail(ok)) throw(ok::status);

    if(doplot&&have_gui()) {
      note ('## Plot visibilities')
      ok:=anpimagertest.plotvis();
      if(is_fail(ok)) throw(ok::status);
    }

    note ('## Hogbom Clean')
    ok:=anpimagertest.clean(algorithm='hogbom', complist=clfile,
		 model=spaste(testdir, '/', '3C273XC1.clean'), 
		 niter=1000, gain=0.1,
		 image=spaste(testdir, '/', '3C273XC1.clean.restored'));
    if(is_fail(ok)) throw(ok::status);

    # close
    note('## Close the pimager object')
    ok := anpimagertest.close(); 
    if (!ok) {
	throw('Unexpected close error (1)')
    }
    ok := anpimagertest.done(); 
    if (!ok) {
	throw('Unexpected done error (1)')
    }

    etime:=time();
    note(sprintf('## Finished successfully in run time = %5.2f (s) for size = %d ',
	     etime-stime, size));
    return T
}


const pimagerselfcaltest := function(size=256, doshift=F, doplot=T)
{

  include 'calibrater.g';

  global dowait:=T;

    # Variables that define the demonstration
  testdir := 'pimagerselfcaltest';
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
    pimagermaketestms(msfile);

    # Start timing here
    note('## Start timing')
    note('## Running pimagerselfcaltest with ', size, ' by ', size, ' pixel images')
    stime:=time()

    # Create the pimager object
    note('## Creating pimager object from MeasurementSet ', msfile);
    global anpimagertest:=pimager(msfile);
    if (is_fail(anpimagertest)) throw(anpimagertest::message);

    note('## Set up the image parameters')
    cell:='0.4arcsec'
    include 'measures.g';
    pc:=dm.direction('b1950', '12h26m33.248000', '02d19m43.290000');
    if(doshift) {
      note('## Image will be in galactic coordinates')
      pc:=dm.measure(pc,'gal');
      ok:=anpimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=pc,doshift=T)
    }
    else {
      note('## Image will be in RA,DEC coordinates')
      ok:=anpimagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=pc,doshift=T)
    }
    if(is_fail(ok)) throw(ok::status);

    note('## Set up the data selection parameters')
    ok:=anpimagertest.setdata(mode='all', nchan=1, start=1, step=1, fieldid=1,
		   spwid=1);
    if(is_fail(ok)) throw(ok::status);

    note ('## Hogbom Clean')
    ok:=anpimagertest.clean(algorithm='hogbom', 
		 model=spaste(testdir, '/', '3C273XC1.clean'), 
		 niter=1000, gain=0.1,
		 image=spaste(testdir, '/', '3C273XC1.clean.restored'));
    if(is_fail(ok)) throw(ok::status);

    note ('## Clip the image')
    ok:=anpimagertest.clipimage(image=spaste(testdir, '/', '3C273XC1.clean'), 
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
    ok:=ca.setsolve('T', 60.0, T, tjones, F);
    if(is_fail(ok)) throw(ok::status);
    ok:=ca.setsolve('G', 600.0, F, gjones, F);
    if(is_fail(ok)) throw(ok::status);

    note ('## Do the selfcal');
    ok:=anpimagertest.selfcal(caltool=ca, 
		   model=spaste(testdir, '/', '3C273XC1.clean'));
    if(is_fail(ok)) throw(ok::status);

    note ('## Hogbom Clean')
    ok:=anpimagertest.clean(algorithm='hogbom',
		 model=spaste(testdir, '/', '3C273XC1.selfcal.clean'), 
		 niter=1000, gain=0.1,
		 image=spaste(testdir, '/', '3C273XC1.selfcal.clean.restored'));
    if(is_fail(ok)) throw(ok::status);

    # close
    note('## Close the pimager object')
    ok := anpimagertest.close(); 
    if (!ok) {
	throw('Unexpected close error (1)')
    }
    ok := anpimagertest.done(); 
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

const pimagerlongtest := function() {

  global dowait := T;
  ntest := 0;
  results := [=];
  
  testdir := 'pimagerlongtest/';
  
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
  clfile:=spaste(testdir, '3C273XC1.cl');

  # Make the componentlist and MeasurementSet
  pimagermaketestcl(clfile);
  pimagermaketestms(msfile);

  # Start timing here
  note('## Start timing');
  stime:=time()

  #################################################################################

  global mypimager:=pimager(filename=msfile);
  if(is_fail(mypimager)) fail;

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

  #################################################################################

  nametest := 'setimage';
  note('### Test pimager.setimage ###');
  
  for (mode in ['channel', 'velocity', 'mfs']) {
    ntest +:=1;
    ok :=mypimager.setimage(nx=256, ny=256, cellx="0.7arcsec" ,
			   celly="0.7arcsec" , stokes="IV" , doshift=F,
			   phasecenter=[type="direction" , refer="B1950" ,
					m1=[value=0, unit="rad" ], m0=[unit="rad" , value=0]],
			   shiftx="0arcsec" ,
			   shifty="0arcsec" , mode=mode , nchan=1, start=1, step=1,
			   mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1, facets=1);
    
    checkresult(ok, ntest, nametest, results);
  }
  
  #################################################################################
  nametest := 'advise';
  note('### Test pimager.advise ###');
  
  for (amplitudeloss in [-1.0, 0.0, 0.1, 1000.0]) {
    ntest +:=1;
    ok :=mypimager.advise(takeadvice=F, amplitudeloss=amplitudeloss,
			 fieldofview="1arcmin" , pixels=128, cell="1arcsec" , facets=1,
			 phasecenter=[type="direction" , refer="B1950" ,
				      m1=[value=0, unit="rad" ], m0=[unit="rad" , value=0]]);
    checkresult(ok, ntest, nametest, results);
  }
  
  #################################################################################
  nametest := 'setdata';
  note('### Test pimager.setdata ###'); 
  
  ntest +:=1;
  ok :=mypimager.setdata(msselect='ANTENNA1 > 10 && ANTENNA2 > 10');
  checkresult(ok, ntest, nametest, results);

  for (mode in ['channel', 'velocity', 'none']) {
    ntest +:=1;
    ok :=mypimager.setdata(mode=mode , nchan=1, start=1, step=1,
			  mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1);
    checkresult(ok, ntest, nametest, results);
  }
  
  #################################################################################
  nametest := 'setoptions';
  note('### Test pimager.setoptions ###');
  
  ntest +:=1;
  ok :=mypimager.setoptions(ftmachine="gridft" , cache=0, tile=16,
			   gridfunction="SF" ,
			   location=[type="position" , refer="WGS84" ,
				     m2=[value=0, unit="m" ],
				     m1=[unit="rad" , value=0],
				     m0=[unit="rad" , value=0]],
			   padding=1);
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'plotsummary';
  note('### Test pimager.plotsummary ###'); 
  
  ntest +:=1;
  ok :=mypimager.plotsummary();
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'plotuv';
  note('### Test pimager.plotuv ###');
  
  for (rotate in [T, F]) {
    ntest +:=1;
    ok :=mypimager.plotuv(rotate=rotate);
    checkresult(ok, ntest, nametest, results);
  }
  
  #################################################################################
  nametest := 'plotvis';
  note('### Test pimager.plotvis ###');
  
  for (type in ['all', 'observed', 'model', 'corrected', 'residual']) {
    ntest +:=1;
    ok :=mypimager.plotvis(type="all" , increment=1);
    checkresult(ok, ntest, nametest, results);
  }
  
  #################################################################################
  nametest := 'plotweights';
  note('### Test pimager.plotweights ###');

  for (gridded in [T, F]) {
    ntest +:=1;
    ok :=mypimager.plotweights(gridded=gridded, increment=1);
    checkresult(ok, ntest, nametest, results);
  }
  
  #################################################################################
  nametest := 'fitpsf';
  note('### Test pimager.fitpsf ###');
  
  ntest +:=1;
  bmaj := F;
  bmin := F;
  bpa := F;
  ok :=mypimager.fitpsf(psf='', bmaj=bmaj , bmin=bmin , bpa=bpa);
  ok := ok && dq.check(bmaj);
  ok := ok && dq.check(bmin);
  ok := ok && dq.check(bpa);
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'setbeam';
  note('### Test pimager.setbeam ###');
  
  ntest +:=1;
  bmaj := "5arcsec"
  bmin := "5arcsec"
  bpa := "0deg"
  ok :=mypimager.setbeam(bmaj=bmaj , bmin=bmin , bpa=bpa);
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'weight';
  note('### Test pimager.weight ###');
  
  for (type in ['natural', 'uniform']) {
    ntest +:=1;
    ok :=mypimager.weight(type="uniform" , rmode="robust" , noise="0Jy" ,
			 robust=0, fieldofview="0rad" , npixels=100);
    checkresult(ok, ntest, nametest, results);
  }
  
  #################################################################################
  nametest := 'uvrange';
  note('### Test pimager.uvrange ###');
  
  ntest +:=1;
  ok :=mypimager.uvrange(uvmin=0.0, uvmax=1000000.0);
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'filter';
  note('### Test pimager.filter ###');
  
  ntest +:=1;
  ok :=mypimager.filter(type="gaussian" , bmaj="5arcsec" , bmin="5arcsec",
		       bpa="0deg" );
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'make';
  note('### Test pimager.make ###');
  ok:=mypimager.make(spaste(testdir, '3C273XC1.empty'));
  ok := ok && tableexists(spaste(testdir, '3C273XC1.empty'));
  checkresult(ok, ntest, nametest, results);

  #################################################################################
  nametest := 'boxmask';
  note('### Test pimager.boxmask ###');
  ok:=mypimager.boxmask(spaste(testdir, '3C273XC1.mask'),
		       blc=[95,65,1,1], trc=[185,150,2,1]);
  ok := ok && tableexists(spaste(testdir, '3C273XC1.mask'));
  checkresult(ok, ntest, nametest, results);

  #################################################################################
  nametest := 'regionmask';
  note('### Test pimager.regionmask ###');
  ok:=mypimager.regionmask(spaste(testdir, '3C273XC1.regionmask'),
			  region=drm.quarter());
  ok := ok && tableexists(spaste(testdir, '3C273XC1.regionmask'));
  checkresult(ok, ntest, nametest, results);

  #################################################################################
  nametest := 'smooth';
  note('### Test pimager.smooth ###');
  ok:=mypimager.smooth(model=spaste(testdir, '3C273XC1.mask'),
		      image=spaste(testdir, '3C273XC1.mask.smoothed'),
		      bmaj="15arcsec" , bmin="5arcsec",
		      bpa="40deg" );
  ok := ok && tableexists(spaste(testdir, '3C273XC1.mask.smoothed'));
  checkresult(ok, ntest, nametest, results);

  #################################################################################
  nametest := 'exprmask';
  note('### Test pimager.exprmask ###');
  global maskimage_exprmask := image(spaste(testdir, '3C273XC1.mask.smoothed'));
  ok:=is_image(maskimage_exprmask);
  expr:='iif ($maskimage_exprmask > 0.5, $maskimage_exprmask, 0.0)';
  ok:=ok && mypimager.exprmask(spaste(testdir, '3C273XC1.exprmask'), expr);
  ok := ok && tableexists(spaste(testdir, '3C273XC1.exprmask'));
  if(is_image(maskimage_exprmask)) maskimage_exprmask.close();
  maskimage_exprmask.done();
  symbol_delete('maskimage_exprmask');
  checkresult(ok, ntest, nametest, results);

  #################################################################################
  nametest := 'makeimage';
  note('### Test pimager.makeimage ###');
  

  for (type in ['observed', 'model', 'corrected', 'residual', 'psf']) {
    ntest +:=1;
    ok :=mypimager.makeimage(type , image=spaste(testdir, spaste("3C273XC1.", type)) ,
			compleximage=spaste(testdir, spaste("3C273XC1.c", type)) );
    ok := ok && tableexists(spaste(testdir, spaste("3C273XC1.", type)));
    ok := ok && tableexists(spaste(testdir, spaste("3C273XC1.c", type)));
    checkresult(ok, ntest, nametest, results);
  }
  
  #################################################################################
  nametest := 'setscales';
  note('### Test pimager.setscales ###');
  
  ntest +:=1;
  ok := mypimager.setscales(scalemethod='uservector', uservector=[0.0,3.0,10.0]);
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'setmfcontrol';
  note('### Test pimager.setmfcontrol ###');
  
  ntest +:=1;
  ok :=mypimager.setmfcontrol( cyclefactor=3.0, cyclespeedup=-1.0, 
				stoplargenegatives=2, stoppointmode=-1);
  checkresult(ok, ntest, nametest, results);

  #################################################################################  
  note('### Test pimager.clean ###');
  ntest +:=1;
  for (algorithm in ['clark', 'hogbom', 'mfclark', 'mfhogbom',
		    'wfclark', 'wfhogbom']) {
    nametest := algorithm;
    ok :=mypimager.clean(algorithm=algorithm , niter=1000, gain=0.1,
			threshold="0Jy" , displayprogress=F,
			model=spaste(testdir, algorithm, ".clean") , fixed=F,
			complist='', mask=spaste(testdir, '3C273XC1.mask'),
			image=spaste(testdir, algorithm, ".clean.restored") ,
			residual=spaste(testdir, algorithm, ".clean.residual") );
    ok := ok && tableexists(spaste(testdir, algorithm, ".clean"));
    ok := ok && tableexists(spaste(testdir, algorithm, ".clean.restored"));
    ok := ok && tableexists(spaste(testdir, algorithm, ".clean.residual"));
    checkresult(ok, ntest, nametest, results);
  }
 #################################################################################
  
  note('### Test pimager.clean with multiscale ###');
  ntest +:=1;
  ok :=mypimager.setmfcontrol( cyclefactor=3.0, cyclespeedup=40.0);
  for (algorithm in [ 'multiscale', 'mfmultiscale']) {
    nametest := algorithm;
    ok :=mypimager.clean(algorithm=algorithm , niter=200, gain=0.7,
			threshold="0Jy" , displayprogress=F,
			model=spaste(testdir, algorithm, ".clean") , fixed=F,
			complist='', mask=spaste(testdir, '3C273XC1.mask'),
			image=spaste(testdir, algorithm, ".clean.restored") ,
			residual=spaste(testdir, algorithm, ".clean.residual") );
    ok := ok && tableexists(spaste(testdir, algorithm, ".clean"));
    ok := ok && tableexists(spaste(testdir, algorithm, ".clean.restored"));
    ok := ok && tableexists(spaste(testdir, algorithm, ".clean.residual"));
    checkresult(ok, ntest, nametest, results);
  }
  #################################################################################
  # MEM is operating on a single stokes
  mypimager.setimage(nx=256, ny=256, cellx="0.7arcsec" ,
		   celly="0.7arcsec" , stokes="I" , doshift=F,
		   phasecenter=[type="direction" , refer="B1950" ,
		   m1=[value=0, unit="rad" ], m0=[unit="rad" , value=0]],
		   shiftx="0arcsec" ,
		   shifty="0arcsec" , mode='mfs' , nchan=1, start=1, step=1,
		   mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1, facets=1);

  #################################################################################  

  ok:=mypimager.boxmask(spaste(testdir, '3C273XC1.mask.I'),
		       blc=[95,65,1,1], trc=[185,150,1,1]);
  ok :=mypimager.setmfcontrol( cyclefactor=3.0, cyclespeedup=10.0);
  note('### Test pimager.mem ###');
  ntest +:=1;
  for (algorithm in ['entropy', 'emptiness', 'mfentropy', 'mfemptiness']) {
    nametest := algorithm;
    ok :=mypimager.mem(algorithm=algorithm , niter=50, sigma='0.001Jy',
                        targetflux='2.0Jy', constrainflux=F,
                        displayprogress=F,
                        model=spaste(testdir, algorithm, ".mem") , fixed=F,
                        complist='', mask=spaste(testdir, '3C273XC1.mask.I'),
                        image=spaste(testdir, algorithm, ".mem.restored") ,
                        residual=spaste(testdir, algorithm, ".mem.residual") );
    ok := ok && tableexists(spaste(testdir, algorithm, ".mem"));
    ok := ok && tableexists(spaste(testdir, algorithm, ".mem.restored"));
    ok := ok && tableexists(spaste(testdir, algorithm, ".mem.residual"));
    checkresult(ok, ntest, nametest, results);
  }
  # OK, put it back!
  mypimager.setimage(nx=256, ny=256, cellx="0.7arcsec" ,
		   celly="0.7arcsec" , stokes="IV" , doshift=F,
		   phasecenter=[type="direction" , refer="B1950" ,
		   m1=[value=0, unit="rad" ], m0=[unit="rad" , value=0]],
		   shiftx="0arcsec" ,
		   shifty="0arcsec" , mode='mfs' , nchan=1, start=1, step=1,
		   mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1, facets=1);
  #################################################################################

  nametest := 'nnls';
  note('### Test pimager.nnls ###');
  
  ntest +:=1;
  ok:=mypimager.boxmask(spaste(testdir, '3C273XC1.fluxmask'),
		       blc=[120,120,1,1], trc=[136,136,1,1]);
  ok:=ok && mypimager.boxmask(spaste(testdir, '3C273XC1.datamask'),
			     blc=[100,100,1,1], trc=[156,156,1,1]);
  ok :=ok && mypimager.nnls(algorithm='nnls', niter=1000, tolerance=1e-6,
			   model=spaste(testdir, "nnls") , fixed=F,
			   complist='',
			   fluxmask=spaste(testdir, "3C273XC1.fluxmask") ,
			   datamask=spaste(testdir, "3C273XC1.datamask") ,
			   image=spaste(testdir, "nnls.restored") ,
			   residual=spaste(testdir, "nnls.residual") );
  ok := ok && tableexists(spaste(testdir, "nnls"));
  ok := ok && tableexists(spaste(testdir, "nnls.restored"));
  ok := ok && tableexists(spaste(testdir, "nnls.residual"));
  checkresult(ok, ntest, nametest, results);
    #################################################################################
  nametest := 'restore';
  note('### Test pimager.restore ###');
  
  ntest +:=1;
  ok :=mypimager.restore(model=spaste(testdir, "clark.clean") , complist='',
			image=spaste(testdir, "clark.clean.restored1") ,
			residual=spaste(testdir, "clark.clean.residual1") );
  ok := ok && tableexists(spaste(testdir, "clark.clean.restored1"));
  ok := ok && tableexists(spaste(testdir, "clark.clean.residual1"));
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'residual';
  note('### Test pimager.residual ###');
  
  ntest +:=1;
  ok :=mypimager.residual(model=spaste(testdir, "clark.clean") , complist='',
			 image=spaste(testdir, "clark.clean.residual2") );
  ok := ok && tableexists(spaste(testdir, "clark.clean.residual2"));
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'clipimage';
  note('### Test pimager.clipimage ###');
  
  ntest +:=1;
  ok :=mypimager.clipimage(threshold="0.1Jy", 
			  image=spaste(testdir, "clark.clean.restored1") );
  ok := ok && tableexists(spaste(testdir, "clark.clean.restored1"));
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'sensitivity';
  note('### Test pimager.sensitivity ###');
  
  ntest +:=1;
  pointsource:="0Jy";
  relative:=-1.0;
  sumweights:=-1.0;
  ok :=mypimager.sensitivity(pointsource="0Jy" , relative=relative,
			    sumweights=sumweights);
  ok := ok && dq.check(pointsource);
  ok := ok && (relative > 0.9999999);
  ok := ok && (sumweights > 0.0);
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'ft';
  note('### Test pimager.ft ###');
  
  ntest +:=1;
  ok :=mypimager.ft(model=spaste(testdir, "mfclark.clean") ,
		   complist=spaste(testdir, "3C273XC1.cl") , incremental=F);
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'correct';
  note('### Test pimager.correct ###');
  
  ntest +:=1;
  ok :=mypimager.correct(doparallactic=T, timestep='10s');
  ok :=ok && mypimager.correct(doparallactic=F, timestep='10s');
  ok :=ok && mypimager.correct(doparallactic=T, timestep='1000s');
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  nametest := 'clipvis';
  note('### Test pimager.clipvis ###');
  
  ntest +:=1;
  ok :=mypimager.clipvis(threshold='100mJy');
  checkresult(ok, ntest, nametest, results);
  
  #################################################################################
  
  ntest +:=1;
  ok := mypimager.done();
  
  checkresult(ok, ntest, nametest, results);
  #################################################################################

  nfailed := 0;
  for (result in results) {
    if(result!='') {
      nfailed+:=1;
      note(result);
    }
  }
    
  if(nfailed>0) {

    etime:=time();
    note(sprintf('Finished with %d failures in run time = %5.2f (s)', nfailed,
		 (etime - stime)));
  
    return F;
  }
  else {

    etime:=time();
    note(sprintf('Finished with complete success in run time = %5.2f (s)',
		 (etime - stime)));

    return T;
  
  }
}

const pimageralltests:=function() {

  const note := function(...) { defaultlogger.note(...,
						   origin='pimageralltests()') }

  note ('## Running all pimagertests');
  stime:=time()

  pimagertestresult:=pimagertest();
  pimagerlongtestresult:=pimagerlongtest();
  pimagermftestresult:=pimagermftest();
  pimagerpbtestresult:=pimagerpbtest();
  pimagerselfcaltestresult:=pimagerselfcaltest();
  pimagercomponenttestresult:=pimagercomponenttest();
#  pimagerspectraltestresult:=pimagerspectraltest();
  pimagerspectraltestresult:="Skipped";

  etime:=time();
  note(sprintf('## Finished all tests in run time = %5.2f (s)', (etime - stime)));
  
  note('## Status of tests:')
  note('   pimagertest status : ', pimagertestresult);
  note('   pimagerlongtest status : ', pimagerlongtestresult);
  note('   pimagermftest status : ', pimagermftestresult);
  note('   pimagerpbtest status : ', pimagerpbtestresult);
  note('   pimagerselfcaltest status : ', pimagerselfcaltestresult);
  note('   pimagercomponenttest status : ', pimagercomponenttestresult);
  note('   pimagerspectraltest status : ', pimagerspectraltestresult);
  pimagerspectraltestresult := T;

  return pimagertestresult&&
    pimagerlongtestresult&&
    pimagermftestresult&&
    pimagerpbtestresult&&
    pimagerselfcaltestresult&&
    pimagercomponenttestresult&&
    pimagerspectraltestresult;
}


const pimagermultiscale := function(msname='', imsizes=[128, 256], cellsizes=[2, 1], 
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

  mypimager:=pimager(msname);
  ok :=mypimager.setdata(mode="none" , nchan=1, start=1, step=1, 
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
  
    ok :=mypimager.setimage(nx=imsizes[i], ny=imsizes[i], 
      cellx=spaste(cellsizes[i],"arcsec"), celly=spaste(cellsizes[i],"arcsec"),
      stokes="I",  doshift=F,
      shiftx="0arcsec", shifty="0arcsec", mode="mfs" , nchan=1, start=1, step=1, 
      mstart="0km/s", mstep="0km/s", spwid=spwid, fieldid=centerfield, facets=1);

    ok :=mypimager.weight(type="uniform" );
    ok :=mypimager.filter(type="gaussian", bmaj=spaste(taper[i],"arcsec"), bmin=spaste(taper[i],"arcsec"));
    ok :=mypimager.setvp(dovp=T, usedefaultvp=T);
    ok :=mypimager.setscales(scalemethod='uservector', uservector=scales);
  
  # If there is a previous model, regrid it to the current imsizes (large image)
  # and use that as a starting model for the next round of cleaning 
    if (previousmodel != '') {
  	ok := mypimager.makeimage(type='psf', image=tempname);
  	imgsmall := image(previousmodel);
  	imgbig   := image(tempname);
  	imgnew   := imgsmall.regrid(outfile=modname, csys=imgbig.coordsys(), 
  			shape=imgbig.shape(), axes=[1,2]);

  # fix due to image.regrid bug;  remove when this is fixed!
	arrnew := imgnew.getchunk()
	arrnew /:= 4.0;
	imgnew.putchunk(arrnew);
  # end fix

  	ok := imgnew.done();
  	ok := imgbig.done();
  	ok := imgsmall.done();
        print (paste('Regridded ', previousmodel, ' to size of ', modname));
        ok := note (paste('Regridded ', previousmodel, ' to size of ', modname));
    }
  
  # calculate the number of iterations to do this round
    niter := as_integer(nitermult*(imsizes[i]^niterpower));
    speedup := niter/3;

    stoplargenegs := 2
    if (i > 1) stoplargenegs := -1;
    ok := mypimager.setmfcontrol(cyclefactor=2.0, cyclespeedup=speedup,
				stoplargenegatives=stoplargenegs,
			  	stoppointmode=4);
    ok :=mypimager.clean(algorithm=algorithm , niter=niter, gain=0.7,
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
  ok := mypimager.done();

  if (ok && tableexists()) {
	return T;
  }
  return F;
}

