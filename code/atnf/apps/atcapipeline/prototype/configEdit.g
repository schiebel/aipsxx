#-----------------------------------------------------------------------------
# configEdit.g: Editing Configuration class for the ATCA pipeline
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
include 'autoflag.g'
include 'config.g'
include 'atcapl.g'
include 'metadata.g'
include 'sources.g'
include 'ddesc.g'
include 'interpreter.g'

configedit := subsequence(pl){

  par := config(pl)
  INHERIT(self, par)
  its := INTERNAL(par)

  its.logic := [=]
  its.inddesc := [=]

  const its.logic_plotting := function(){
    wider its
    its.logic.plotps := T
    its.logic.plotgui := F
    if(its.level.val == BEGINNER || its.level.val == EXPERT)
      its.logic.plotgui := F      #XX taken this out for now, will change
                                  #XX back when gui plotting works

    its.logic.plot_flagged := []
    its.logic.plot_raw := [] 
    its.logic.use_corrected := []
    its.logic.plot_primary := []
    its.logic.plot_secondaries := []
    its.logic.plot_targets := []
    its.logic.plot_all := []

    for(ddescid in its.ddesctoProcess.val){
      ddesc := its.ddesc[ddescid]
      its.logic.plot_flagged[ddescid] := F
      its.logic.plot_raw[ddescid] := F
      its.logic.use_corrected[ddescid] := F
      its.logic.plot_primary[ddescid] := F
      its.logic.plot_secondaries[ddescid] := F
      its.logic.plot_targets[ddescid] := F
      its.logic.plot_all[ddescid] := F

      if(has_field(ddesc, 'plotFlagged')){
        if(ddesc.plotFlagged.val == T)
          its.logic.plot_flagged[ddescid] := T
      }
      if(has_field(ddesc, 'plotRaw')){
        if(ddesc.plotRaw.val == T)
          its.logic.plot_raw[ddescid] := T
      }
      if(has_field(ddesc, 'useCorrected')){
        if(ddesc.useCorrected.val == T)
          its.logic.use_corrected[ddescid] := T
      }

      if(!is_fail(ddesc.pID.val) && !is_unset(ddesc.pID.val))
        its.logic.plot_primary[ddescid] := T

      if(!is_fail(ddesc.sIDs.val) && !is_unset(ddesc.sIDs.val))
        its.logic.plot_secondaries[ddescid] := T

      if(!is_fail(ddesc.targetIDs.val) && !is_unset(ddesc.targetIDs.val))
        its.logic.plot_targets[ddescid] := T
    }
    return T
  }

  const its.logic_whichplots := function(){
    wider its
    its.logic.plot_uv := []
    its.logic.plot_ri := []
    its.logic.plot_phasetime := []

    for(ddescid in its.ddesctoProcess.val){
      ddesc := its.ddesc[ddescid]
      its.logic.plot_uv[ddescid] := F
      its.logic.plot_ri[ddescid] := F
      its.logic.plot_phasetime[ddescid] := F

      if(its.logic.use_corrected[ddescid] == F && 
              its.logic.plot_raw[ddescid] == T &&
              !is_fail(ddesc.targetIDs.val))
        its.logic.plot_uv[ddescid] := T

      if(its.logic.use_corrected[ddescid]){
        its.logic.plot_ri[ddescid] := T
        its.logic.plot_phasetime[ddescid] := T
      }
    }
    return T
  }

  const its.logic_spectral := function(){
    wider its
    # temporary: set options for spectral line testing
    its.logic.form_chan0 := F
    its.logic.chan0 := []

    for(ddescid in its.ddesctoProcess.val){
      ddesc := its.ddesc[ddescid]
      if(ddesc.mode != SPECTRAL){
        its.logic.chan0[ddescid] := F
        continue
      }
      its.logic.form_chan0 := T
      its.logic.chan0[ddescid] := T
   
      its.logic.do_flagging[ddescid] := F
      its.logic.flag_primary[ddescid] := F
      its.logic.flag_secondaries[ddescid] := F
      its.logic.flag_targets[ddescid] := F

      if(has_field(ddesc, 'delBirdie')){
        if(ddesc.delBirdie.val == T)
          its.logic.remove_birdie[ddescid] := T
      }
      if(has_field(ddesc, 'subContinuum')){
        if(ddesc.subContinuum.val == T)
          its.logic.subtract_continuum[ddescid] := T
      }
    }
    return T
  }

  const its.logic_flagging := function(){
    wider its
    its.logic.do_flagging := []
    its.logic.flag_primary := []
    its.logic.flag_secondaries := []
    its.logic.flag_targets := []    
    its.logic.remove_birdie := []
    its.logic.subtract_continuum := []

    for(ddescid in its.ddesctoProcess.val){
      ddesc := its.ddesc[ddescid]
      its.logic.do_flagging[ddescid] := F
      its.logic.flag_primary[ddescid] := F
      its.logic.flag_secondaries[ddescid] := F
      its.logic.flag_targets[ddescid] := F
      its.logic.subtract_continuum[ddescid] := F
      its.logic.remove_birdie[ddescid] := F

      if(has_field(ddesc, 'doFlagging')){
        if(ddesc.doFlagging.val == T){
          its.logic.do_flagging[ddescid] := T

          if(its.logic.use_corrected[ddescid]){
            if(!is_unset(ddesc.targetIDs.val))
              its.logic.flag_targets[ddescid] := T
          }
          else{
            if(!is_unset(ddesc.pID.val))
              its.logic.flag_primary[ddescid] := T

            if(!is_unset(ddesc.sIDs.val))
              its.logic.flag_secondaries[ddescid] := T
          }
        }
      }
    }
    return T
  }

  const its.apply_ddesc_conditions := function(ddescid){
    wider its 
    its.ddesc[ddescid].toProcess := T    
    return T
  }

  const its.set_axes := function(){
    wider its
    its.axes := [=]

    setax := function(name, vis, mode, type, doc, alt, value){
      wider its
      its.axes[name] := [=]
      its.axes[name].vis := vis
      its.axes[name].mode := mode
      its.axes[name].type := type
      its.axes[name].doc := doc
      its.axes[name].alt := alt
      its.axes[name].val := value
    }

    setax('u',0,'const','string','Label for U axis','axislabelU','U (m)')
    setax('v',0,'const','string','Label for V axis','axislabelV','V (m)')
    setax('uvdist',0,'const','string','Label for UVdist axis','axislabelUVdist','UV distance -- sqrt(u^2 + v^2)')
    setax('amp',0,'const','string','Label for amplitude axis','axislabelAmp','Amplitude (Jy)')
    setax('real',0,'const','string','Label for real axis','axislabelRe','Real')
    setax('imag',0,'const','string','Label for imaginary axis','axislabelIm','Imaginary')
    return T
  }

  const self.get_threshold := function(){ return its.threshold.val }

  const self.determine_logic := function(){
    ok := its.logic_plotting()
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting logic for plotting', ok::)

    ok := its.logic_flagging()
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting logic for flagging', ok::)

    ok := its.logic_whichplots()
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting logic for plotting', ok::)

    # XXX temporary
    ok := its.logic_spectral()
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting logic for spectral', ok::)    
    return T
  }

  const self.load_meta := function(){
    wider its

    md := metadata(its.msname.val)
    if(is_fail(md)) return fatal(PARMERR, 'Error reading metadata for Edit', md::)

    data := md.get_vars()
    its.ddesc := data.ddesc
    its.dataDescIDs.val := data.dataDescIDs
    its.ndataDescIDs.val := as_integer(data.ndataDescIDs)
    its.project.val := data.project
    its.fieldIDs.val := data.fieldIDs
    its.fieldNames.val := data.fieldNames
    its.antennas.val := data.antennas
    its.ignore6.val := data.ignore6
    its.standardCals := data.standardCals

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

    ok := its.select_ddesc_to_process()
    if(is_fail(ok)) return fatal(PARMERR, 'Error selecting datadescIDs to edit', ok::)

    ok := its.show_settings()
    if(is_fail(ok)) return fatal(PARMERR, 'Error displaying calibration information', ok::)

    ok := its.calc_modes()
    if(is_fail(ok)) return fatal(PARMERR, 'Error determining observation modes', ok::)

    ok := its.create_var_map()
    if(is_fail(ok)) return fatal(PARMERR, 'Error processing calibration information', ok::)
    return T
  }


# Constructor
  ok := its.load('default.edit.config', EDIT)
  if(is_fail(ok)) 
    return fatal(PARMERR, 'Error loading default config for Editing', ok::)

  ok := self.copy_general_config(pl)
  if(is_fail(ok))
    return fatal(PARMERR, 'Error transferring settings to Edit config', ok::)

  ok := its.set_axes()
  if(is_fail(ok))
    return fatal(PARMERR, 'Error setting up axes for plotting', ok::)
  return T
}










