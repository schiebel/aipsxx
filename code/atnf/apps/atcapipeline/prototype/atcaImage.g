#-----------------------------------------------------------------------------
# atcaImage.g: Imaging class for the ATCA pipeline
#-----------------------------------------------------------------------------
# Copyright (C) 1996-2004
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id:
#-----------------------------------------------------------------------------
#

pragma include once

include 'imager.g'
include 'image.g'
include 'atcapl.g'
include 'configImage.g'


atcaimager := subsequence(config){

# Private variables and functions

  its := [=]
  its.imager := [=]

  const its.make_imager := function(config){
    wider its
    its.imager := imager(config.get_msname())
    if(is_fail(its.imager)) return fatal(PARMERR, 'Error creating imager', its.imager::)

    fprintf(config.get_pidfile(), '%d imager\n', its.imager.id().pid)
    return T
  }

  const its.getpids := function(config){
    # get the process IDs of all the default servers started
    servers := ['drc', 'dq', 'dm']
    for(s in servers){
      if(is_record(eval(s))){
        pid := eval(s).id().pid
        fprintf(config.get_pidfile(), '%d %s\n', pid, s)
      }
    }
    return T
  }

  const its.done := function(){
    ok := its.imager.done()
    if(is_fail(ok)) return fatal(PARMERR, 'Error closing imager object', ok::)
  }

  const its.tofits := function(imname){
    im := image(imname)
    if(is_fail(im)) return fatal(PARMERR, 'Error initialising image object for tofits', im::)

    fitsname := spaste(imname, '.fits')
    ok := im.tofits(fitsname, overwrite=T)
    if(is_fail(ok)) return fatal(PARMERR, 'Error writing to FITS file', ok::)
    im.done()

    print 'IMAGE: Image written to FITS file', fitsname
    return T
  }

  const its.set_data := function(config, ddescid){
    # setup data for imaging
    c := config.get_vars()
    logic := config.get_logicvars()
    ddesc := c.ddesc[ddescid]
    ddid := spaste(ddescid)
    selectstr := spaste('ANTENNA2 in ', as_evalstr(c.antennas.val))

    if(logic.channel[ddid] == T || logic.mfs[ddid] == T){
      # channel mode
      fieldid := as_integer(c.currentSourceID.val)
      ok := its.imager.setdata(mode='channel', nchan=ddesc.nchan, start=1, step=1, 
                               spwid=ddescid, fieldid=fieldid, async=F,
                               msselect=selectstr)
      if(is_fail(ok))
        return fatal(PARMERR, 'Error in setdata for imaging', ok::)
    }
    else if(logic.velocity[ddid] == T){
      # velocity mode
      fieldid := as_integer(c.currentSourceID.val)
      ok := its.imager.setdata(mode='velocity', nchan=ddesc.nchan, 
                               mstart=c.mstart.val, mstep=c.mstep.val, 
                               spwid=ddescid, fieldid=fieldid, async=F)
      if(is_fail(ok))
        return fatal(PARMERR, 'Error in setdata for imaging', ok::)
    }
    else
      return fatal(PARMERR, 'Error: logic flags not set correctly')
    return T
  }

  const its.set_image := function(config, ddescid){
    # setup imaging parameters
    c := config.get_vars()
    logic := config.get_logicvars()
    ddesc := c.ddesc[ddescid]
    ddid := spaste(ddescid)
    nchan := ddesc.nchan

    # set image parameters
    fieldid := as_integer(c.currentSourceID.val)

    if(logic.channel[ddid] == T){
      # channel mode
      ok := its.imager.setimage(mode='channel', nx=ddesc.nx.val, ny=ddesc.ny.val, 
                                cellx=ddesc.cell.val, celly=ddesc.cell.val, 
                                stokes=c.stokes.val, doshift=F, 
                                shiftx=c.shiftx.val, shifty=c.shifty.val, 
                                nchan=ddesc.imchan.val, spwid=ddescid, 
                                start=ddesc.start.val, step=ddesc.step.val, 
                                fieldid=fieldid, facets=c.facets.val)
    }
    else if(logic.mfs[ddid] == T){
      # mfs mode
      ok := its.imager.setimage(mode='mfs', nx=ddesc.nx.val, ny=ddesc.ny.val, 
                                cellx=ddesc.cell.val, celly=ddesc.cell.val, 
                                stokes=c.stokes.val, doshift=F, 
                                shiftx=c.shiftx.val, shifty=c.shifty.val, 
                                nchan=1, spwid=ddescid, 
                                start=ddesc.start.val, step=ddesc.step.val, 
                                fieldid=fieldid, facets=c.facets.val)
      if(is_fail(ok)) return fatal(PARMERR, 'Error in imager.setimage', ok::)
    }
    else if(logic.velocity[ddid] == T){
      # velocity mode
      return fatal(PARMERR, 'Velocity mode not implemented yet')
    }
    else
      return fatal(PARMERR, 'Error: logic flags not set correctly')

    if(logic.weight == T){
      # apply weighting
      i := spaste(c.currentSourceID.val)
      ok := its.imager.weight(type=c.weights[i])
      if(is_fail(ok)) return fatal(PARMERR, 'Error in imager.weight', ok::)
    }

    # select a uvrange
    if(logic.uvrange == T){
      ok := its.imager.uvrange(uvmin=c.uvmin.val, uvmax=c.uvmax.val)
      if(is_fail(ok)) return fatal(PARMERR, 'Error in uvrange', ok::)
    }

    # apply filtering 
    if(logic.filter == T){
#      ok := its.imager.filter(type='gaussian', bmaj='1arcsec', bmin='1arcsec')
      ok := its.imager.filter(type=c.filtertype.val, bmaj=c.bmaj.val, 
                              bmin=c.bmin.val, bpa=c.bpa.val)
      if(is_fail(ok)) return fatal(PARMERR, 'Error in filtering', ok::)
    }

    return T
  }


  const its.deconvolve := function(config, ddescid){
    c := config.get_vars()
    logic := config.get_logicvars()
    ddid := spaste(ddescid)
    fieldid := as_integer(c.currentSourceID.val)
    source := c.fieldNames.val[fieldid]

    print '--------------------------------------'
    print 'Imaging with the following parameters:'
    print 'npixels = ', c.ddesc[ddescid].nx.val, c.ddesc[ddescid].ny.val
    print 'cellsize = ', c.ddesc[ddescid].cell.val
    print 'stokes = ', c.stokes.val
    print '--------------------------------------'

    if(logic.clean[ddid][spaste(fieldid)] == T){
      print 'Running CLEAN using the ', c.algorithm.val, ' algorithm'
      if(logic.sensitivity == T){
        # work out cutoff for cleaning  
        local sens, rel, sum
        ok := its.imager.sensitivity(pointsource=sens, relative=rel, 
                                     sumweights=sum, async=F)
        if(is_fail(ok))
          return fatal(PARMERR, 'Error in imager.sensitivity', ok::)
        # 10 sigma 
        cut := dq.mul(sens, 10.0)
        # set niters high so threshold activated
        niter := 1000000
      }
      else{
        cut := c.threshold.val
        niter := c.niter.val
      }

      model := c.images.model[source][ddid]
      restored := c.images.restored[source][ddid]
      residual := c.images.residual[source][ddid]

      ok := dos.remove(model, mustexist=F)
      if(is_fail(ok)) return fatal(PARMERR, 'Error deleting model image directory', ok::)

      if(logic.interactive)
        inter := c.interactive.val
      else
        inter := F

      ok := its.imager.clean(algorithm=c.algorithm.val, niter=niter,
                             gain=c.gain.val, threshold=cut, async=F, 
                             displayprogress=c.displayprogress.val, model=model,
                             fixed=c.fixed.val, image=restored, residual=residual,
                             interactive=inter, npercycle=c.npercycle.val)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running CLEAN', ok::)
   
      ok := its.tofits(restored)
      if(is_fail(ok))
        return fatal(IOERR, 'Error writing restored image to FITS file', ok::)
    }
    else if(logic.mem[ddid][spaste(fieldid)] == T){
      print 'Running MEM using the ', c.malgorithm.val, ' algorithm'
      model := c.images.model[source][ddid]
      restored := c.images.restored[source][ddid]
      residual := c.images.residual[source][ddid]
      ok := dos.remove(model, mustexist=F)
      if(is_fail(ok))
        return fatal(PARMERR, 'Error deleting model image directory', ok::)

      ok := its.imager.mem(algorithm=c.malgorithm.val, niter=c.mniter.val,
                             sigma=c.sigma.val, targetflux=c.targetflux.val, async=F,
                             displayprogress=c.displayprogress.val, model=model,
                             fixed=c.fixed.val, image=restored, residual=residual)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running CLEAN', ok::)
   
      ok := its.tofits(restored)
      if(is_fail(ok)) return fatal(IOERR, 'Error writing restored image to FITS file', ok::)
    }
    else{
      print 'Running without any deconvolution'
      image := c.images.image[source][ddid]

      ok := dos.remove(image, mustexist=F)
      if(is_fail(ok)) return fatal(PARMERR, 'Error deleting model image directory', ok::)
   
      ok := its.imager.makeimage(image=image, type='corrected')
      if(is_fail(ok)) return fatal(PARMERR, 'Error running makeimage', ok::)
      
      ok := its.tofits(image)
      if(is_fail(ok)) return fatal(IOERR, 'Error writing image to FITS file', ok::)
    }
    return T
  }

# Public variables and functions

  const self.image := function(config){
    c := config.get_vars()

    for(ddescid in c.ddesctoProcess.val){
      ddesc := c.ddesc[spaste(ddescid)]

# XXXX Changed this for testing
#      if(ddesc.mode != CONTINUUM && ddesc.mode != SPECTRAL){
      if(ddesc.mode != CONTINUUM){
        print 'Cant image non-continuum data, skipping Spectral Window ', ddescid
        continue
      }  

      for(targetid in ddesc.targetIDs.val){
        config.set_current_source_id(targetid)

        print 'Imaging source: ', config.idtoName(targetid), 'in spectral window: ', ddescid

        ok := its.make_imager(config)
        if(is_fail(ok)) return fatal(PARMERR, 'Error initialising imager', ok::)

        ok := its.set_data(config, ddescid)
        if(is_fail(ok)) return fatal(PARMERR, 'Error setting data for imaging', ok::)
    
        ok := its.set_image(config, ddescid)
        if(is_fail(ok)) return fatal(PARMERR, 'Error setting imaging parameters', ok::)

        ok := its.deconvolve(config, ddescid)
        if(is_fail(ok)) return fatal(PARMERR, 'Error deconvolving image', ok::)

        ok := its.done()
        if(is_fail(ok)) return fatal(PARMERR, 'Error closing imaging tool', ok::)
      }
    }
  }

  const self.done := function(config){
    ok := its.getpids(config)
    if(is_fail(ok)) return fatal(PARMERR, 'Error getting server pids', ok::)
    return T
  }
}






