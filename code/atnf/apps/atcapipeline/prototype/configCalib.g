#-----------------------------------------------------------------------------
# configCalib.g: Calibration Configuration class for the ATCA pipeline
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
include 'quanta.g'
include 'config.g'
include 'atcapl.g'
include 'metadata.g'
include 'sources.g'
include 'ddesc.g'
include 'interpreter.g'

configcalib := subsequence(pl){

  par := config(pl)
  INHERIT(self, par)
  its := INTERNAL(par)

  its.logic := [=]
  its.inddesc := [=]

  const its.logic_setJy := function(){
    wider its

    its.logic.setjy1 := []   # basic setJy case for Primary cal = 1934-638
    its.logic.setjy2 := []   # setJy for Primary cal != 1934-638

    for(ddescid in its.ddesctoProcess.val){
      its.logic.setjy1[ddescid] := F
      its.logic.setjy2[ddescid] := F

      if(its.ddesc[spaste(ddescid)].pName.val == '1934-638')
        its.logic.setjy1[ddescid] := T
      else if(its.ddesc[spaste(ddescid)].pName.val == '0823-500')
        its.logic.setjy2[ddescid] := T
    }
    return T
  }

  const its.logic_calib := function(){
    wider its

    its.logic.pG := []    # solve for G using primary
    its.logic.pD := []    # solve for D using primary
    its.logic.pB := []    # solve for B using primary
    its.logic.sG := []    # solve for G using secondary
    its.logic.sGD := []    # solve for D using secondary

    for(ddescid in its.ddesctoProcess.val){
      its.logic.pB[ddescid] := T
      its.logic.pG[ddescid] := F
      its.logic.pD[ddescid] := F
      its.logic.sG[ddescid] := F
      its.logic.sGD[ddescid] := F

      if(its.ddesc[ddescid].pName.val == '1934-638'){
        its.logic.pG[ddescid] := T
        its.logic.sG[ddescid] := T

        if(its.ddesc[ddescid].ncorr > 2)
          its.logic.pD[ddescid] := T
      }
      else if(its.ddesc[ddescid].pName.val == '0823-500'){
        its.logic.pG[ddescid] := T

        if(its.ddesc[ddescid].ncorr > 2)
          its.logic.sG[ddescid] := T
        else
          its.logic.sGD[ddescid] := T
      }
  
      if(its.ddesc[ddescid].mode == SPECTRAL){
        its.logic.sG[ddescid] := T
        its.logic.sGD[ddescid] := F
        its.logic.pD[ddescid] := F
      }
    }

    # These have various conditions - see pg. 84 (Chp 4)
    its.logic.linpol := F

    its.logic.fluxscale := []
    for(ddescid in its.ddesctoProcess.val){
      if(its.ddesc[ddescid].sIDs.val == its.ddesc[ddescid].pID.val)
        its.logic.fluxscale[ddescid] := F
      else 
        its.logic.fluxscale[ddescid] := T
    }
    return T
  }

  const its.apply_ddesc_conditions := function(ddescid){
    wider its 

    # must have a primary, secondary and calibrator
    primary := its.ddesc[ddescid].pName.val
    secondaries := its.ddesc[ddescid].sNames.val
    target := its.ddesc[ddescid].targetNames.val
    if(is_unset(target) || is_unset(primary) || is_unset(secondaries))
      its.ddesc[ddescid].toProcess := F      

    # must have target-secondary match
    calsfortargets := its.ddesc[ddescid].calsForTargetNames.val
    if(is_unset(calsfortargets))
      its.ddesc[ddescid].toProcess := F      

    # if primary is not 1934-638 then source model must be set
    if(primary != '1934-638'){
      if(is_unset(its.ddesc[ddescid].fluxdensity.val))
        its.ddesc[ddescid].toProcess := F      
    }
    return T
  }

  const its.set_source_models := function(){
    wider its
    sources := [=]
    sources['0823-500'] := [=]
    sources['0823-500']['2368MHz'] := 5.03   # all in Janskys
    sources['0823-500']['4800MHz'] := 3.22
    sources['0823-500']['8640MHz'] := 1.39
    s := sources['0823-500']

    for(i in its.dataDescIDs.val){
      ddescid := spaste(i)
      if(its.ddesc[ddescid].toProcess==F)
        continue

      its.ddesc[ddescid].fluxdensity := [=]
      its.ddesc[ddescid].fluxdensity.val := unset
      freq := its.ddesc[ddescid].frequency 
  
      if(its.ddesc[ddescid].pName.val == '0823-500'){
        for(f in field_names(s)){
          if(dq.eq(freq, f)){
            its.ddesc[ddescid].fluxdensity.val := s[f]
            break
          }
        }
      }
    }
    return T
  }

  const its.find_cals_for_targets := function(ddescid){
    wider its
    targetnames := its.ddesc[ddescid].calsForTargetNames.val
    its.ddesc[ddescid].calsForTargetIDs := [=]
    its.ddesc[ddescid].calsForTargetIDs.val := [=]
    its.ddesc[ddescid].calsForTargetNames := [=]
    its.ddesc[ddescid].calsForTargetNames.val := [=]

    for(target in field_names(targetnames)){
      if(is_fail(target)) return fatal(PARMERR, 'Error finding target IDs', target::)

      tid := spaste(find_ID(target, ddescid, its))
      if(is_fail(tid)) return fatal(PARMERR, 'Error finding target IDs', tid::)

      if(as_integer(tid) == 0)
        continue

      secids := find_IDs(targetnames[target], ddescid, its)
      if(is_fail(secids)) return fatal(PARMERR, 'Error finding target IDs', secids::)

      its.ddesc[ddescid].calsForTargetIDs.val[tid] := secids
      its.ddesc[ddescid].calsForTargetNames.val[target] := its.idstoNames(secids)
    }
    return T
  }

  const its.match_one_secondary := function(ddescid){
    wider its
    sName := its.ddesc[ddescid].sNames.val[1]
    sID := its.ddesc[ddescid].sIDs.val[1]
    targetids := its.ddesc[ddescid].targetIDs.val
    targetNames := its.ddesc[ddescid].targetNames.val
    for(i in 1:len(targetids)){
      tid := spaste(targetids[i])
      its.ddesc[ddescid].calsForTargetNames.val[targetNames[i]] := sName
      its.ddesc[ddescid].calsForTargetIDs.val[tid] := sID
    }
    return T
  }

  const its.match_equal_secondaries := function(ddescid){
    wider its
    sNames := its.ddesc[ddescid].sNames.val
    sIDs := its.ddesc[ddescid].sIDs.val
    targetNames := its.ddesc[ddescid].targetNames.val
    targetids := its.ddesc[ddescid].targetIDs.val

    for(i in 1:len(targetNames)){
      tid := spaste(targetids[i])
      its.ddesc[ddescid].calsForTargetNames.val[targetNames[i]] := sNames[i]
      its.ddesc[ddescid].calsForTargetIDs.val[tid] := sIDs[i]
    }
    return T
  }

  const its.match_cals := function(){
    # match each target source with a calibrator
    # will be replaced with Peter Lamb's algorithm
    wider its

    for(ddescid in its.dataDescIDs.val){
      ddesc := its.ddesc[ddescid]
      if(ddesc.toProcess == F)
        continue

      if(ddesc.calsForTargetNames.mode == 'override'){
        ok := its.find_cals_for_targets(ddescid)
        if(is_fail(ok)) 
          return fatal(PARMERR, 'Error finding calibrators for target sources', ok::)     
      }
      else{
        sNames := ddesc.sNames.val
        targetNames := ddesc.targetNames.val
        ddesc.calsForTargetNames := [=]
        ddesc.calsForTargetIDs := [=]

        if(is_unset(sNames)){
          ddesc.calsForTargetNames.val := unset
          ddesc.calsForTargetIDs.val := unset
        }
        else if(len(sNames) == 1){
          ok := its.match_one_secondary(ddescid)
          if(is_fail(ok)) 
            return fatal(PARMERR, 'Error matching secondaries and targets', ok::)
        }
        else if(len(sNames) == len(targetNames)){
          ok := its.match_equal_secondaries(ddescid)
          if(is_fail(ok)) 
            return fatal(PARMERR, 'Error matching secondaries and targets', ok::)
        }
        else{
          printf('Wrong number of calibrators and target sources, can not do matching for ddesc %d \n', ddescid)
          ddesc.calsForTargetNames.val := unset
          ddesc.calsForTargetIDs.val := unset
        }
        ddesc.calsForTargetNames.mode := 'calc'
      }
    }
    return T
  }

  const self.determine_logic := function(){
    ok := its.logic_setJy()
    if(is_fail(ok)) return fatal(PARMERR, 'Error determining logic for setJy', ok::)

    ok := its.logic_calib()
    if(is_fail(ok)) return fatal(PARMERR, 'Error determining logic for calibration', ok::)
    return T
  }

  const self.load_meta := function(){
    wider its

    md := metadata(its.msname.val)
    if(is_fail(md)) 
      return fatal(PARMERR, 'Error reading metadata for configCalib', md::)

    data := md.get_vars()
    its.ddesc := data.ddesc
    its.dataDescIDs.val := data.dataDescIDs
    its.fieldIDs.val := data.fieldIDs
    its.fieldNames.val := data.fieldNames
    its.antennas.val := data.antennas
    its.ignore6.val := data.ignore6
    its.standardCals := data.standardCals

    # set names for calibration tables
    dir := spaste(its.outdir.val, '/calib')
    if(!dos.fileexists(dir) & dos.isvalidpathname(dir)){
      ok := dos.mkdir(dir)
      if(is_fail(ok)) return fatal(IOERR, 'Error creating calib directory', ok::)
    }

    its.tables := [=]
    its.tables.G := [=]
    its.tables.B := [=]
    its.tables.D := [=]
    for(i in its.dataDescIDs.val){
      its.tables.G.val[i] := spaste(dir, '/calG-', i)
      its.tables.B.val[i] := spaste(dir, '/calB-', i)
      its.tables.D.val[i] := spaste(dir, '/calD-', i)
    }

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
    if(is_fail(ok)) return fatal(PARMERR, 'Error finding calibrators', ok::)

    ok := its.match_cals()
    if(is_fail(ok)) return fatal(PARMERR, 'Error matching calibrators', ok::)

    ok := its.set_source_models()
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting source models', ok::)

    ok := its.select_ddesc_to_process()
    if(is_fail(ok)) return fatal(PARMERR, 'Error selecting datadescIDs to calibrate', ok::)

    ok := its.show_settings()
    if(is_fail(ok)) return fatal(PARMERR, 'Error displaying calibration information', ok::)

    ok := its.calc_modes()
    if(is_fail(ok)) return fatal(PARMERR, 'Error determining observation modes', ok::)

    ok := its.create_var_map()
    if(is_fail(ok)) return fatal(PARMERR, 'Error processing calibration information', ok::)
    return T
  }

# Constructor
  ok := its.load('default.calib.config', CALIB)
  if(is_fail(ok)) 
    return fatal(PARMERR, 'Error loading config file for configCalib', ok::)

  ok := self.copy_general_config(pl)
  if(is_fail(ok)) 
    return fatal(PARMERR, 'Error transferring settings to Calib config', ok::)
  return T
}






