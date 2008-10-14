#-----------------------------------------------------------------------------
# configImage.g: Imaging Configuration class for the ATCA pipeline
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

include 'os.g'
include 'config.g'
include 'atcapl.g'
include 'metadata.g'
include 'sources.g'
include 'ddesc.g'
include 'interpreter.g'

configimage := subsequence(pl){

  par := config(pl)
  INHERIT(self, par)
  its := INTERNAL(par)

  its.logic := [=]
  its.inddesc := [=]

  const its.logic_setimage := function(){
    # use imaging settings and data
    # to work out which setimage options to run
    wider its

    its.logic.uvrange := F 
    its.logic.filter := F
    its.logic.weight := T

    its.logic.channel := [=]
    its.logic.mfs := [=]
    its.logic.velocity := [=]

    for(i in its.ddesctoProcess.val){
      ddescid := spaste(i)
      its.logic.channel[ddescid] := F
      its.logic.mfs[ddescid] := F
      its.logic.velocity[ddescid] := F

      if(its.ddesc[ddescid].mode == CONTINUUM) 
        its.logic.mfs[ddescid] := T
      else if(its.ddesc[ddescid].mode == SPECTRAL) 
        its.logic.channel[ddescid] := T
    }
    return T
  }

  const its.logic_image := function(){
    # work out what imaging options to run
    wider its

    its.logic.mem := [=]
    its.logic.clean := [=]
    its.logic.sensitivity := F
    its.logic.interactive := F
    timecutoff := dq.quantity('180min')

    if(its.doClean.val == T){
      if(is_unset(its.threshold.val) && its.niter.val == 0)
        its.logic.sensitivity := T
    }

    for(i in its.ddesctoProcess.val){
      ddescid := spaste(i)
      its.logic.clean[ddescid] := [=]
      its.logic.mem[ddescid] := [=]

      for(j in its.ddesc[ddescid].fieldIDs){
        fieldid := spaste(j)
        its.logic.mem[ddescid][fieldid] := F
        its.logic.clean[ddescid][fieldid] := F

        if(its.doClean.mode == 'override'){
          if(its.doClean.val == T){
            its.logic.clean[ddescid][fieldid] := T
            its.logic.mem[ddescid][fieldid] := F
          }
          else if(its.doMem.val == T){
            its.logic.mem[ddescid][fieldid] := T
            its.logic.clean[ddescid][fieldid] := F
          }
          else if(its.doClean.val == F)
            its.logic.clean[ddescid][fieldid] := F
          else if(its.doMem.val == F)
            its.logic.mem[ddescid][fieldid] := F
        }
        else{
          if(dq.gt(its.ddesc[ddescid].obstime[fieldid], timecutoff))
            its.logic.clean[ddescid][fieldid] := T
          else
            its.logic.clean[ddescid][fieldid] := F  
        }
      }
    }
    if(its.level.val == AUTO || its.level.val == WS)
      its.logic.interactive := F
    else
      its.logic.interactive := F
##XX should change this back to interactive eventually
    return T 
  }

  const its.set_image_weights := function(){
    # work out weighting options for each source
    wider its
    its.weights := [=]
    for(i in 1:len(its.fieldIDs.val))
      its.weights[spaste(its.fieldIDs.val[i])] := its.weighttype.val
    return T
  }

  const its.set_image_stokes := function(){
    wider its
    stokes := ['I','IV','IQU','IQUV']
    allowed := F
    for(s in stokes){
      if(its.stokes.val == s){
        allowed := T
        break
      }
    }
    if(!allowed){
      printf('  Warning: Invalid Stokes parameters selected for imaging ( %s )\n', its.stokes.val)
      printf('  Using Stokes = I instead\n')
      its.stokes.val := 'I'
    }

    for(ddescid in its.dataDescIDs.val){
      if(its.ddesc[ddescid].mode != CONTINUUM)
        its.stokes.val := 'I'
    }
    return T
  }

  const its.set_image_chans := function(){
    wider its

    for(ddescid in its.dataDescIDs.val){
      nchan := its.ddesc[ddescid].nchan
      its.ddesc[ddescid].start := [=]
      its.ddesc[ddescid].step := [=]
      its.ddesc[ddescid].imchan := [=]

      if(its.ddesc[ddescid].mode == SPECTRAL){
        plow := floor(0.1*nchan + 0.5)
        phigh := floor(0.9*nchan + 0.5)
        step := 1
        imchan := 256
        while(imchan > 128){          
          step *:= 2
          imchan := ceiling((phigh - plow) / step)
        }
        its.ddesc[ddescid].start.val := plow
        its.ddesc[ddescid].step.val := step
        its.ddesc[ddescid].imchan.val := imchan
      }
      else{
        its.ddesc[ddescid].start.val := its.start.val
        its.ddesc[ddescid].step.val := its.step.val
        its.ddesc[ddescid].imchan.val := nchan
      }
    }
    return T
  }

  const its.set_image_size := function(){
    wider its

    for(ddescid in its.dataDescIDs.val){
      if(has_field(its.ddesc[ddescid], 'nx')){
        if(its.ddesc[ddescid].nx.mode != 'override')
          its.ddesc[ddescid].nx.val := its.pixels.val[ddescid]
      }
      else{
        its.ddesc[ddescid].nx := [=]
        its.ddesc[ddescid].nx.val := its.pixels.val[ddescid]
      }
      if(has_field(its.ddesc[ddescid], 'ny')){
        if(its.ddesc[ddescid].ny.mode != 'override')
          its.ddesc[ddescid].ny.val := its.ddesc[ddescid].nx.val
      }
      else{
        its.ddesc[ddescid].ny := [=]
        its.ddesc[ddescid].ny.val := its.ddesc[ddescid].nx.val
      }
      if(has_field(its.ddesc[ddescid], 'cell')){
        if(its.ddesc[ddescid].cell.mode != 'override')
          its.ddesc[ddescid].cell.val := its.cell.val[ddescid]
      }
      else{
        its.ddesc[ddescid].cell := [=]
        its.ddesc[ddescid].cell.val := its.cell.val[ddescid]
      }
    }
    return T
  }

  const its.set_image_parms := function(){
    wider its
    ok := its.set_image_weights()
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting weights for image', ok::)

    ok := its.set_image_stokes()
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting stokes parms for image', ok::)

    ok := its.set_image_chans()
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting channel parms for image', ok::)

    ok := its.set_image_size()
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting image size', ok::)

    return T
  }

  const its.apply_ddesc_conditions := function(ddescid){
    wider its

    # must have a target source
    target := its.ddesc[ddescid].targetNames.val
    if(is_unset(target))
      its.ddesc[ddescid].toProcess := F      
    return T
  }

  const its.create_fits_filenames := function(){
    wider its

    its.images := [=]
    its.images.model := [=]
    its.images.residual := [=] 
    its.images.restored := [=]
    its.images.image := [=]

    dir := spaste(its.outdir.val, '/images/')

    for(source in its.fieldNames.val){
      its.images.model[source] := [=]
      its.images.restored[source] := [=]
      its.images.residual[source] := [=]
      its.images.image[source] := [=]
      for(ddesc in its.dataDescIDs.val){
        d := spaste(ddesc)
        freq := dq.convertfreq(its.ddesc[ddesc].frequency, 'MHz').value
        npol := len(its.ddesc[ddesc].corrnames)
        nchan := its.ddesc[ddesc].nchan
        namehead := spaste(dir, source, ':', freq, '-', nchan, '-', npol)
        its.images.model[source][d] := spaste(namehead, '-s', d, '.model')
        its.images.restored[source][d] := spaste(namehead, '-s', d, '.restored')
        its.images.residual[source][d] := spaste(namehead, '-s', d, '.residual')
        its.images.image[source][d] := spaste(namehead, '-s', d, '.image')
      }
    }
    return T
  }

  const its.setval := function(name, value){
    wider its
    its[name].val := value
    return T
  }

  const self.set_current_source := function(sourceName){
    return its.setval('currentSource', sourceName)
  }

  const self.set_current_source_id := function(sourceID){
    return its.setval('currentSourceID', sourceID)
  }

  const self.set_phasecenter := function(phasecenter){
    return its.setval('phasecenter', phasecenter)
  }

  const self.determine_logic := function(){
    # run all the routines to decide the logic 
    its.logic_setimage()
    its.logic_image()
    return T
  }

  const self.load_meta := function(){
    wider its

    md := metadata(its.msname.val)
    if(is_fail(md)) return fatal(PARMERR, 'Error reading metadata for configImage', md::)

    data := md.get_vars()
    its.ddesc := data.ddesc
    its.dataDescIDs.val := data.dataDescIDs
    its.fieldIDs.val := data.fieldIDs
    its.fieldNames.val := data.fieldNames
    its.antennadiameter.val := data.antennadiameter
    its.antennas.val := data.antennas
    its.ignore6.val := data.ignore6
    its.maxbaseline.val := data.maxbaseline
    its.pixels.val := data.pixels
    its.cell.val := data.cell
    its.standardCals := data.standardCals

    ok := its.create_fits_filenames()
    if(is_fail(ok)) fail

    # add a ddesc field to the attributes list
    its.attributes[len(its.attributes)+1] := 'ddesc'
    return T
  }

  const self.calc := function(){
    # calculate additional parameters 
    # based on config options and metadata

    ok := identify_ddescs(its)
    if(is_fail(ok)) return fatal(PARMERR, 'Error identifying ddescs from CL parms', ok::)

    ok := its.find_cals()
    if(is_fail(ok)) 
      return fatal(PARMERR, 'Error finding/matching sources for configImage', ok::)

    ok := its.select_ddesc_to_process()
    if(is_fail(ok)) return fatal(PARMERR, 'Error selecting datadescIDs to image', ok::)

    ok := its.calc_modes()
    if(is_fail(ok)) return fatal(PARMERR, 'Error determining observation modes', ok::)

    ok := its.set_image_parms()
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting parameters for image', ok::)

    ok := its.show_settings()
    if(is_fail(ok)) return fatal(PARMERR, 'Displaying imaging information', ok::)

    ok := its.create_var_map()
    if(is_fail(ok)) return fatal(PARMERR, 'Error processing imaging information', ok::)
    return T
  }


# Constructor
  ok := its.load('default.image.config', IMAGE)
  if(is_fail(ok)) 
    return fatal(PARMERR, 'Error loading config file for configImage', ok::)

  ok := self.copy_general_config(pl)
  if(is_fail(ok)) 
    return fatal(PARMERR, 'Error transferring settings to Image config', ok::)
  return T
}
