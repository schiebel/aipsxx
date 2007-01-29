# imager.g: Make images from AIPS++ MeasurementSets
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
#   $Id: imager.g,v 19.23 2006/10/05 20:38:39 rurvashi Exp $
#

pragma include once

include 'plugins.g'
include 'servers.g'
include 'note.g'

#defaultservers.suspend(T)
#defaultservers.trace(T)

# Users aren't to use this.
const _define_imager := function(ref agent, id) {
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
			      facets=1, distance='0m',
			      pastep=5.0, pblimit=5e-2) {
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
	self.setimageRec.pastep:=pastep;
	self.setimageRec.pblimit:=pblimit;
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
    public.setdata:=function(msname='', mode='none', nchan=[1], start=[1], step=[1],
               		     mstart='0km/s',
                             mstep='0km/s',
			     spwid=[1], fieldid=[1], 
			     msselect = ' ', async=!dowait) {
        wider self;
	self.setdataRec.msname:=msname;
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
				padding=1.0,
				usemodelcol=T,
				wprojplanes=1,
				pointingtable='',dopointing=T,dopbcorr=T,
				cfcache='') {
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
	self.setoptionsRec.usemodelcol:=usemodelcol;

	self.setoptionsRec.wprojplanes:=wprojplanes;
	self.setoptionsRec.pointingtable:=pointingtable;
	self.setoptionsRec.dopointing:=dopointing;
	self.setoptionsRec.dopbcorr:=dopbcorr;
	self.setoptionsRec.cfcache:=cfcache;
	return defaultservers.run(self.agent, self.setoptionsRec);
    }

    self.weightRec := [_method="weight", _sequence=self.id._sequence]
    public.weight:=function(type="uniform", rmode="none", noise='0.0Jy',
			    robust=0.0, fieldofview="0rad", npixels=0,
			    mosaic=F, async=!dowait) {
        wider self;
	if(type=='briggs' && (rmode=='none' || rmode==''))
	  rmode:='norm';
	self.weightRec.type:=type;
	self.weightRec.rmode:=rmode;
	self.weightRec.noise:=noise;
	self.weightRec.robust:=robust;
	self.weightRec.fieldofview:=fieldofview;
	self.weightRec.npixels:=npixels;

	#durned DS interface request
        if (mosaic) {
		saved.setdataRec:=self.setdataRec;
		for (field in self.setdataRec.fieldid) {
		   public.setdata(fieldid=field,spwid=self.setdataRec.spwid);
		   public.weight(type=self.weightRec.type,
			rmode=self.weightRec.rmode,
			noise=self.weightRec.noise,
			robust=self.weightRec.robust,
			fieldofview=self.weightRec.fieldofview,
			npixels=self.weightRec.npixels,mosaic=F);
		};
                public.setdata(mode=saved.setdataRec.mode,
			nchan=saved.setdataRec.nchan,
			start=saved.setdataRec.start,
			step=saved.setdataRec.step,
			mstart=saved.setdataRec.mstart,
			mstep=saved.setdataRec.mstep,
			spwid=saved.setdataRec.spwid,
			fieldid=saved.setdataRec.fieldid,
			msselect=saved.setdataRec.msselect);
		return T;
	};

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

    self.approximatepsfRec := [_method="approximatepsf", _sequence=self.id._sequence]
    public.approximatepsf:=function(model='', psf='', async=!dowait) {
        wider self;
	self.approximatepsfRec.model:=model;
	self.approximatepsfRec.psf:=psf;
	return defaultservers.run(self.agent, self.approximatepsfRec, async);
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
	  if(len(residual) > 1 || len(mask) > 1 || len(model) > 1){

	    note('Cannot use interactive mode with multifield imaging', 
	    priority='WARN');
	    note('Please use interactive=F with multifield', priority='WARN');
	     note('You may use interactivemas to draw the mask explicitly', 
		  priority='WARN');
	    return F;
          }	    

	
	  
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

    self.pixonRec := [_method="pixon", _sequence=self.id._sequence]
    public.pixon:=function(algorithm='singledish',  sigma='1mJy',
			   model='',  async=!dowait) {
        wider self;
	self.pixonRec.algorithm:=algorithm;
	self.pixonRec.sigma:=sigma;
	self.pixonRec.model:=model;
	returnval := defaultservers.run(self.agent, self.pixonRec, async);
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
      			stoplargenegatives=2, stoppointmode=-1, minpb=0.1,
			scaletype='NONE', constpb=0.3, fluxscale='',
			async=!dowait) {
	wider self;
	self.setmfcontrolRec.cyclefactor:=cyclefactor;
	self.setmfcontrolRec.cyclespeedup:=cyclespeedup;
	self.setmfcontrolRec.stoplargenegatives:=stoplargenegatives;
	self.setmfcontrolRec.stoppointmode:=stoppointmode;
	self.setmfcontrolRec.scaletype:=scaletype;
	self.setmfcontrolRec.minpb:=minpb;
	self.setmfcontrolRec.constpb:=constpb;
	self.setmfcontrolRec.fluxscale:=fluxscale;
	returnval := defaultservers.run(self.agent, self.setmfcontrolRec, async);
        return returnval;
    }

    self.setsdoptionsRec := [_method="setsdoptions", _sequence=self.id._sequence];
    public.setsdoptions:=function(scale=1.0, weight=1.0, convsupport=-1, 
                                  async=!dowait) {
      wider self;
      self.setsdoptionsRec.scale:=scale;
      self.setsdoptionsRec.weight:=weight;
      self.setsdoptionsRec.convsupport:=convsupport;
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
	standard='', async=!dowait) {
        wider self;
	self.setjyRec.fieldid:=fieldid;
	self.setjyRec.spwid:=spwid;

        self.setjyRec.fluxdensity:=fluxdensity;
        i:=len(self.setjyRec.fluxdensity);
	if (i < 4) self.setjyRec.fluxdensity[(i+1):4]:=0.0;

        self.setjyRec.standard:=standard;

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
	dosquint=F,parangleinc='360deg', telescope='',skyposthreshold='180deg') {
        wider self;
	self.setvpRec.dovp:=dovp;
	self.setvpRec.usedefaultvp:=usedefaultvp;
	self.setvpRec.vptable:=vptable;
	self.setvpRec.dosquint:=dosquint;
	self.setvpRec.parangleinc:=parangleinc;
	self.setvpRec.telescope:=telescope;
	self.setvpRec.skyposthreshold:=skyposthreshold;
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
	lelExpr:=spaste('iif(',expr,', 1.0, 0.0)');
        if(is_fail(im.calc(lelExpr))) 
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

    self.settaylortermsRec := [_method="settaylorterms", _sequence=self.id._sequence]
    public.settaylorterms:=function(ntaylor=2, async=!dowait) {
        wider self;
        self.settaylortermsRec.ntaylor:=ntaylor;
        returnval := defaultservers.run(self.agent, self.settaylortermsRec, async);
        return returnval;
    }


    self.makemodelfromsdRec := [_method="makemodelfromsd", _sequence=self.id._sequence]
      public.makemodelfromsd:=function(sdimage='', modelimage='', sdpsf='',  maskimage='',
			       async=!dowait) {
        wider self;
	if(maskimage==''){

	  maskimage:=spaste(modelimage,'.mask');
	}
	self.makemodelfromsdRec.sdimage:=sdimage;
	self.makemodelfromsdRec.modelimage:=modelimage;
	self.makemodelfromsdRec.sdpsf:=sdpsf;
	self.makemodelfromsdRec.maskimage:=maskimage;
	return defaultservers.run(self.agent, self.makemodelfromsdRec, async);
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
            f.text->insert('imager closed', 'start');
        } else {
            f.text->delete('start', 'end');
            f.text->insert(public.state(), 'start');
        }
        return T;
    }

    public.type := function() {
      return 'imager';
    }

#    plugins.attach('imager', public);
    return ref public;

} # _define_imager()


# Make a new server for every invocation
const imager := function(filename='', compress=F, host='', forcenewserver=T) {
  include 'os.g';
  if (filename=='') {
    # No ms okay
#    throw('Must supply a measurementset filename');
#    return F;
  } else if (!dos.fileexists(filename)) {
    throw('Measurementset ', filename, ' nonexistent!');
    return F;	
  }
  agent := defaultservers.activate("imager", host, forcenewserver);
  if(is_fail(agent)) fail;
  id := defaultservers.create(agent, "imager", "imager", 
	[thems=filename, compress=compress]);
  if(is_fail(id)) fail;
  return ref _define_imager(agent,id);

} 

##############################################################################
# Test script
#
const imagertest:= function (level='all') {
# 
  # Create a imagertester tool
  include 'imagertester.g';
  mytester := imagertester();   
  if(level=='all' || level == 'beta')
     testlist:=['sftest', 'mftest', 'wftest', 'spectraltest', 'memtest',
	     'utiltest'];
  else
     testlist:=['utiltest'];
  mytester.runtests(testlist);
  mytester.done();
  return T;
};


const imagermaketestcl:=function(clfile='3C273XC1.cl', refer='b1950')
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

const imagermaketestms := function(msfile='3C273XC1.ms') {

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

const imagermaketestsdms := function(msfile='gbt_cygnus_800MHz.ms') {

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
const imagermaketestmfms := function(msfile='XCAS.ms') {

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

const imagerpbtest := function(size=256, cleanniter=1000, cleangain=0.1)
{
  global dowait:=T;

    # Variables that define the demonstration
  testdir := 'imagerpbtest';

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
    imagermaketestms(msfile);

    # Start timing here
    note('## Start timing')
    note('## Running imagerpbtest with ', size, ' by ', size, ' pixel images')
    stime:=time()

    # Create the imager object
    note('## Creating imager object from MeasurementSet ', msfile);
    global animagertest:=imager(msfile);
    if (is_fail(animagertest)) throw(animagertest::message);

    note('## Set up the image parameters')
    cell:='0.4arcsec'
    include 'measures.g';
    mcore:=dm.direction('b1950', '12h26m33.248000', '02d19m43.290000');
    note('## Image will be in RA,DEC coordinates')
    ok:=animagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=mcore,doshift=T)
    if(is_fail(ok)) throw(ok::status);

    note('## Set up the data selection parameters')
    ok:=animagertest.setdata(mode='none', nchan=1, start=1, step=1);
    if(is_fail(ok)) throw(ok::status);

    note('## Switching on Primary beam correction')
    ok:=animagertest.setvp(dovp=T, usedefaultvp=T);
    if(is_fail(ok)) throw(ok::status);

    note('## Make an empty image')
    ok:=animagertest.make(image=spaste(testdir, '/', '3C273XC1.dirty'));
    if(is_fail(ok)) throw(ok::status);

    note('## Weight the data')
    ok:=animagertest.weight(type='briggs');
    if(is_fail(ok)) throw(ok::status);

    note('## Filter the data')
    ok:=animagertest.filter(type="gaussian", bmaj="2arcsec", bmin="2arcsec");
    if(is_fail(ok)) throw(ok::status);

    note ('## MF Clean')
    ok:=animagertest.setbeam(bmaj="5arcsec", bmin="5arcsec");
    if(is_fail(ok)) throw(ok::status);
    ok:=animagertest.clean(algorithm='mfclark',
			   model=spaste(testdir, '/', '3C273XC1.clean'), 
			   niter=cleanniter, gain=cleangain,
			   threshold='1Jy',
			   image=spaste(testdir, '/', '3C273XC1.restored'));
    if(is_fail(ok)) throw(ok::status);

    # close
    note('## Close the imager object')
    ok := animagertest.close(); 
    if (!ok) {
	throw('Unexpected close error (1)')
    }
    ok := animagertest.done(); 
    if (!ok) {
	throw('Unexpected done error (1)')
    }

    etime:=time();
    note(sprintf('## Finished successfully in run time = %5.2f (s) for size = %d ',
	     etime-stime, size));

    return T
}





#const imagersdtest:=function() {
#
#  global dowait:=T;
#
#  # Variables that define the demonstration
#  const testdir := 'imagersdtest';
#  
#  note('Cleaning up directory ', testdir);
#  ok := shell(paste("rm -fr ", testdir));
#  if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); };
#
#  # Make the directory
#  ok := shell(paste("rm -fr ", testdir));
#  if (ok::status) { throw("rm fails!") };
#  ok := shell(paste("mkdir", testdir));
#  if (ok::status) { throw("mkdir", testdir, "fails!") };
#
#  # Make the data
#  msfile:=spaste(testdir, '/gbt_cygnus_800MHz.ms');
#  if(is_fail(imagermaketestsdms(msfile))) fail;
#
#  imagefile:=spaste(testdir, '/gbt_cygnus_800MHz.image');
#  weightfile:=spaste(testdir, '/gbt_cygnus_800MHz.scanweight');
#  gridfile:=spaste(testdir, '/gbt_cygnus_800MHz.scanimage');
#
#  # Create the imager object
#  note('## Creating imager object from MeasurementSet ', msfile);
#  global animagertest:=imager(msfile);
#  if (is_fail(animagertest)) throw(animagertest::message);
#  #
#  # Use the data from one cal phase only
#  #
#  animagertest.setdata(fieldid=1,spwid=1,
#		       msselect='NRAO_GBT_RECEIVER_ID==0&&NRAO_GBT_STATE_ID==1');
#  #
#  dir:=dm.direction('J2000', '20:15:00.00', '+040.30.00');
#
#  animagertest.setimage(nx=144, ny=100,
#			cellx='4arcmin',celly='4arcmin',
#			stokes='I',
#			doshift=T, phasecenter=dir, spwid=1);
#      
#  animagertest.setoptions(gridfunction='PB')
#  #
#  # Make the coverage image
#  #
#  animagertest.makeimage(image=weightfile, type='coverage');
#  #
#  #
#  include 'image.g';
#  s:=0;
#  imcov := image(weightfile); imcov.statistics(s); imcov.done();
#  threshold := s.max / 100.0;
#  #
#  animagertest.makeimage(image=gridfile, type='singledish');
#  #
#  # Threshold coverage image to avoid undersampled points
#  #
#  lweightfile := weightfile ~ s!/!\\/!g;
#  lgridfile   := gridfile ~ s!/!\\/!g;
#
#  command := spaste(lgridfile,'[',lweightfile,'>', threshold,
#			    ']/',lweightfile,'[',lweightfile,'>',
#		    threshold, ']');
#  note('Thresholding using image calculator command ', command);
#  imf:=imagecalc(imagefile, command); imf.statistics(); imf.done();
#
#  ok := animagertest.close(); 
#  if (!ok) {
#    throw('Unexpected close error (1)');
#  }
#  ok := animagertest.done(); 
#  if (!ok) {
#    throw('Unexpected done error (1)');
#  }
#  
#  return T;
#}

const imagercomponenttest := function(size=256, doshift=F, doplot=T)
{

  global dowait:=T;

    # Variables that define the demonstration
  testdir := 'imagercomponenttest';
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
    imagermaketestms(msfile);

    # Start timing here
    note('## Start timing')
    note('## Running imagercomponenttest with ', size, ' by ', size, ' pixel images')
    stime:=time()

    # Make component list file
    clfile:=spaste(testdir, '/','3C273XC1.cl');
    imagermaketestcl(clfile);

    # Create the imager object
    note('## Creating imager object from MeasurementSet ', msfile);
    global animagertest:=imager(msfile);
    if (is_fail(animagertest)) throw(animagertest::message);

    note('## Set up the image parameters')
    cell:='0.4arcsec'
    include 'measures.g';
    pc:=dm.direction('b1950', '12h26m32.687538', '02d19m34.489993')
    if(doshift) {
      note('## Image will be in galactic coordinates')
      pc:=dm.measure(pc,'gal');
      ok:=animagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=pc,doshift=T)
    }
    else {
      note('## Image will be in RA,DEC coordinates')
      ok:=animagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
        stokes='IV',phasecenter=pc,doshift=T)
    }
    if(is_fail(ok)) throw(ok::status);

    note('## Set up the data selection parameters')
    ok:=animagertest.setdata(mode='none', nchan=1, start=1, step=1, fieldid=1,
		   spwid=1);
    if(is_fail(ok)) throw(ok::status);

    note('## Get a summary of the state of the object')
    ok:=animagertest.summary();
    if(is_fail(ok)) throw(ok::status);

    note('## Make an empty image')
    ok:=animagertest.make(image=spaste(testdir, '/', '3C273XC1.clean'));
    if(is_fail(ok)) throw(ok::status);

    note ('## Fourier transform')
    ok:=animagertest.ft(complist=clfile, model=spaste(testdir, '/', '3C273XC1.clean'));
    if(is_fail(ok)) throw(ok::status);

    if(doplot&&have_gui()) {
      note ('## Plot visibilities')
      ok:=animagertest.plotvis();
      if(is_fail(ok)) throw(ok::status);
    }

    note ('## Hogbom Clean')
    ok:=animagertest.clean(algorithm='hogbom', complist=clfile,
		 model=spaste(testdir, '/', '3C273XC1.clean'), 
		 niter=1000, gain=0.1,
		 image=spaste(testdir, '/', '3C273XC1.clean.restored'));
    if(is_fail(ok)) throw(ok::status);

    # close
    note('## Close the imager object')
    ok := animagertest.close(); 
    if (!ok) {
	throw('Unexpected close error (1)')
    }
    ok := animagertest.done(); 
    if (!ok) {
	throw('Unexpected done error (1)')
    }

    etime:=time();
    note(sprintf('## Finished successfully in run time = %5.2f (s) for size = %d ',
	     etime-stime, size));
    return T
}


#const imagerselfcaltest := function(size=256, doshift=F, doplot=T)
#{
#
#  include 'calibrater.g';
#
#  global dowait:=T;
#
#    # Variables that define the demonstration
#  testdir := 'imagerselfcaltest';
#  if(doshift) testdir:=spaste(testdir,'-shifted');
#
#    note('Cleaning up directory ', testdir)
#    ok := shell(paste("rm -fr ", testdir))
#    if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); }
#
#    # Make the directory
#    ok := shell(paste("rm -fr ", testdir))
#    if (ok::status) { throw("rm fails!") }
#    ok := shell(paste("mkdir", testdir))
#    if (ok::status) { throw("mkdir", testdir, "fails!") }
#
#    # Make the data
#    msfile:=spaste(testdir, '/','3C273XC1.ms');
#    imagermaketestms(msfile);
#
#    # Start timing here
#    note('## Start timing')
#    note('## Running imagerselfcaltest with ', size, ' by ', size, ' pixel images')
#    stime:=time()
#
#    # Create the imager object
#    note('## Creating imager object from MeasurementSet ', msfile);
#    global animagertest:=imager(msfile);
#    if (is_fail(animagertest)) throw(animagertest::message);
#
#    note('## Set up the image parameters')
#    cell:='0.4arcsec'
#    include 'measures.g';
#    pc:=dm.direction('b1950', '12h26m33.248000', '02d19m43.290000');
#    if(doshift) {
#      note('## Image will be in galactic coordinates')
#      pc:=dm.measure(pc,'gal');
#      ok:=animagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
#        stokes='IV',phasecenter=pc,doshift=T)
#    }
#    else {
#      note('## Image will be in RA,DEC coordinates')
#      ok:=animagertest.setimage(nx=size,ny=size,cellx=cell,celly=cell,
#        stokes='IV',phasecenter=pc,doshift=T)
#    }
#    if(is_fail(ok)) throw(ok::status);
#
#    note('## Set up the data selection parameters')
#    ok:=animagertest.setdata(mode='none', nchan=1, start=1, step=1, fieldid=1,
#		   spwid=1);
#    if(is_fail(ok)) throw(ok::status);
#
#    note ('## Hogbom Clean')
#    ok:=animagertest.clean(algorithm='hogbom', 
#		 model=spaste(testdir, '/', '3C273XC1.clean'), 
#		 niter=1000, gain=0.1,
#		 image=spaste(testdir, '/', '3C273XC1.clean.restored'));
#    if(is_fail(ok)) throw(ok::status);
#
#    note ('## Clip the image')
#    ok:=animagertest.clipimage(image=spaste(testdir, '/', '3C273XC1.clean'), 
#		     threshold='750mJy')
#    if(is_fail(ok)) throw(ok::status);
#   
#    # Create the cal object
#    ok := eval('include \'calibrater.g\'');
#    note('## Creating calibrater object from MeasurementSet ', msfile);
#    ca:=calibrater(msfile);
#    if (is_fail(ca)) throw(ca::message);
#
#    note ('## Set up calibrater object');
#    tjones:=spaste(testdir, '/', '3C273XC1.tjones');
#    gjones:=spaste(testdir, '/', '3C273XC1.gjones');
#    ok:=ca.setsolve(type='T', t=60.0, phaseonly=T, table=tjones, append=F);
#    if(is_fail(ok)) throw(ok::status);
#    ok:=ca.setsolve(type='G', t=600.0, phaseonly=F, table=gjones, append=F);
#    if(is_fail(ok)) throw(ok::status);
#
#    note ('## Do the selfcal');
#    ok:=animagertest.selfcal(caltool=ca, 
#		   model=spaste(testdir, '/', '3C273XC1.clean'));
#    if(is_fail(ok)) throw(ok::status);
#
#    note ('## Hogbom Clean')
#    ok:=animagertest.clean(algorithm='hogbom',
#		 model=spaste(testdir, '/', '3C273XC1.selfcal.clean'), 
#		 niter=1000, gain=0.1,
#		 image=spaste(testdir, '/', '3C273XC1.selfcal.clean.restored'));
#    if(is_fail(ok)) throw(ok::status);
#
#    # close
#    note('## Close the imager object')
#    ok := animagertest.close(); 
#    if (!ok) {
#	throw('Unexpected close error (1)')
#    }
#    ok := animagertest.done(); 
#    if (!ok) {
#	throw('Unexpected done error (1)')
#    }
#
#    # close
#    note('## Close the cal object')
#    ok := ca.close(); 
#    if (!ok) {
#	throw('Unexpected close error (1)')
#    }
##    ok := ca.done(); 
##    if (!ok) {
##	throw('Unexpected done error (1)')
##    }
#
#    etime:=time();
#    note(sprintf('## Finished successfully in run time = %5.2f (s) for size = %d ',
#	     etime-stime, size));
#    return T
#}


const imagerbetatests := function(){return imageralltests('beta');}
const imagerlitetests := function(){return imageralltests('lite');}

const imageralltests:=function(level='all') {

 include 'logger.g'

  const note := function(...) { defaultlogger.note(...,
						   origin='imageralltests()') }

  note ('## Running all imagertests');
  stime:=time()

  imagertestresult:=imagertest(level);
  imagerpbtestresult:=imagerpbtest();
# imagerselfcaltestresult:=imagerselfcaltest();
  imagercomponenttestresult:=imagercomponenttest();

  etime:=time();
  note(sprintf('## Finished all tests in run time = %5.2f (s)', (etime - stime)));
  
  note('## Status of tests:')
  note('   imagertest status : ', imagertestresult);
  note('   imagerpbtest status : ', imagerpbtestresult);
#  note('   imagerselfcaltest status : ', imagerselfcaltestresult);
  note('   imagercomponenttest status : ', imagercomponenttestresult);
  imagerspectraltestresult := T;

  return imagertestresult&&
    imagerpbtestresult&&
      #imagerselfcaltestresult&&
      imagercomponenttestresult;
}


const imagermultiscale := function(msname='', imsizes=[128, 256], cellsizes=[2, 1], 
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

  myimager:=imager(msname);
  ok :=myimager.setdata(mode="none" , nchan=1, start=1, step=1, 
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
  
    ok :=myimager.setimage(nx=imsizes[i], ny=imsizes[i], 
      cellx=spaste(cellsizes[i],"arcsec"), celly=spaste(cellsizes[i],"arcsec"),
      stokes="I",  doshift=F,
      shiftx="0arcsec", shifty="0arcsec", mode="mfs" , nchan=1, start=1, step=1, 
      mstart="0km/s", mstep="0km/s", spwid=spwid, fieldid=centerfield, facets=1);

    ok :=myimager.weight(type="uniform" );
    ok :=myimager.filter(type="gaussian", bmaj=spaste(taper[i],"arcsec"), bmin=spaste(taper[i],"arcsec"));
    ok :=myimager.setvp(dovp=T, usedefaultvp=T);
    ok :=myimager.setscales(scalemethod='uservector', uservector=scales);
  
  # If there is a previous model, regrid it to the current imsizes (large image)
  # and use that as a starting model for the next round of cleaning 
    if (previousmodel != '') {
  	ok := myimager.makeimage(type='psf', image=tempname);
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
    ok := myimager.setmfcontrol(cyclefactor=1.5, cyclespeedup=speedup,
				stoplargenegatives=stoplargenegs,
			  	stoppointmode=4);
    ok :=myimager.clean(algorithm=algorithm , niter=niter, gain=0.7,
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
  ok := myimager.done();

  if (ok && tableexists()) {
	return T;
  }
  return F;
}

