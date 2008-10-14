#-----------------------------------------------------------------------------
# config.g: General Configuration class for the ATCA pipeline
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
include 'atpl_oo.g'

const config := subsequence(pl){
  its := [=]
  const self.__ITS := function(){ return ref its; }

  const its.show_ddesc := function(){
    wider its
    for(i in its.dataDescIDs.val){
      ddesc := its.ddesc[i]
      printf('\nData set %d:\n', i)
      for(j in field_names(ddesc)){
        if(is_fail(ddesc[j].vis))
          continue
        if(ddesc[j].vis >= its.vislevel.val)
          printf('%s = %s\n', ddesc[j].alt, as_string(ddesc[j].val))
      }
    }
    return T
  }

  const its.show_config := function(){
    # show user the current configuration
    wider its
    printf('The current configuration is:\n')
    printf('-----------------------------------------------\n')
    for(i in 1:len(its.attributes)){
      name := its.attributes[i]
      if(name == 'ddesc')
        its.show_ddesc() 
      if(is_fail(its[name].vis))
        continue
      if(its[name].vis >= its.vislevel.val)
        printf('%s = %s\n', its[name].alt, paste(its[name].val, ' '))
    }
    printf('-----------------------------------------------\n')
  }

  const its.create_map := function(){
    map := [=]
    for(name in its.attributes){
      alt := its[name].alt
      if(alt != '')
        map[alt] := name
    }
    return map
  }

  const its.reverse_map := function(){
    rmap := [=]
    for(alt in field_names(its.varmap)){
      name := its.varmap[alt]
      if(name != '')
        rmap[name] := alt
    }
    return rmap
  }

  const its.create_var_map := function(){
    wider its
    vars := [=]
    for(i in its.dataDescIDs.val){
      vars[spaste('plotFlagged', i)] := 'plotFlagged'
      vars[spaste('plotRaw', i)] := 'plotRaw'
      vars[spaste('doFlagging', i)] := 'doFlagging' 
      vars[spaste('useCorrected', i)] := 'useCorrected' 
      vars[spaste('delBirdie', i)] := 'delBirdie'
      vars[spaste('subContinuum', i)] := 'subContinuum'
      vars[spaste('primary', i)] := 'pName'
      vars[spaste('secondaries', i)] := 'sNames'
      vars[spaste('targets', i)] := 'targetNames'      
      vars[spaste('cell', i)] := 'cell'      
    }
    its.ddesc.varmap := vars 
    return T
  }

  const its.parse_cals := function(input){
    wider its
    rec := [=]
    for(set in input){
      sources := split(set, ',')
      rec[sources[1]] := sources[2:len(sources)]
    }
    return rec
  }

  const its.parse_ddesc := function(input){
    wider its
    for(i in field_names(input)){
      its.inddesc[i]['parms'] := input[i].parms 

      if(its.stage.val == EDIT || its.stage.val == CALIB){
        if(has_field(input[i], 'calibrators'))
          its.inddesc[i]['calibrators'] := its.parse_cals(input[i].calibrators)
        if(has_field(input[i], 'primary'))
          its.inddesc[i]['primary'] := input[i].primary

        if(its.stage.val == EDIT){
          if(has_field(input[i], 'plotFlagged'))
            its.inddesc[i]['plotFlagged'] := input[i].plotFlagged
          if(has_field(input[i], 'plotRaw'))
            its.inddesc[i]['plotRaw'] := input[i].plotRaw
          if(has_field(input[i], 'doFlagging'))
            its.inddesc[i]['doFlagging'] := input[i].doFlagging
          if(has_field(input[i], 'useCorrected'))
            its.inddesc[i]['useCorrected'] := input[i].useCorrected
          if(has_field(input[i], 'delBirdie'))
            its.inddesc[i]['delBirdie'] := input[i].delBirdie
          if(has_field(input[i], 'subContinuum'))
            its.inddesc[i]['subContinuum'] := input[i].subContinuum
        }
      }
      else if(its.stage.val == IMAGE){
        if(has_field(input[i], 'targetNames'))
          its.inddesc[i]['targetNames'] := input[i].targetNames
        if(has_field(input[i], 'cell'))
          its.inddesc[i]['cell'] := dq.quantity(input[i].cell)
        if(has_field(input[i], 'nx'))
          its.inddesc[i]['nx'] := as_integer(input[i].nx)
        if(has_field(input[i], 'ny'))
          its.inddesc[i]['ny'] := as_integer(input[i].ny)
      }
    }
    return T
  }

  const its.select_ddesc_to_process := function(){
    wider its
    ddescs := []

    for(i in its.dataDescIDs.val){
      ddescid := spaste(i)
      if(its.ddesc[ddescid].toProcess == F)
        continue

      ok := its.apply_ddesc_conditions(ddescid)
      if(is_fail(ok)) return fatal(PARMERR, 'Error applying ddesc conditions', ok::)

      if(its.ddesc[ddescid].toProcess == T)
        ddescs := [ddescs, i]
    }
    its.ddesctoProcess.val := ddescs
    return T
  }

  const its.load := function(filename, stage){
    wider its
    ok := load_config(filename, its)
    if(is_fail(ok))
      return fatal(IOERR, 'Error loading default configuration file', ok::)

    its.varmap := its.create_map()
    if(is_fail(its.varmap)) 
      return fatal(PARMERR, 'Error creating variable map', its.varmap::)
    its.rvarmap := its.reverse_map()
    if(is_fail(its.rvarmap)) 
      return fatal(PARMERR, 'Error creating variable map', its.rvarmap::)

    ok := self.set_stage(stage)
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting stage', ok::)
    return T
  }

  const self.save := function(){
    # save the current configuration
    suffix := ['filler', 'edit', 'calib', 'image']
    dirname := spaste(its.outdir.val, '/config')
    temp := spaste(its.runid.val, '.', suffix[its.stage.val], '.config')
    fullname := paste(dirname, temp, sep="/")
    
    ok := save_config(fullname, its)
    if(is_fail(ok)) return recover(IOERR, 'Error saving configuration file', ok::)

    printf('Configuration has been saved in %s\n', fullname)
    return T
  }

  const its.idstoNames := function(ids){
    count := 1
    names := ['']
    for(id in ids){
      for(j in 1:len(its.fieldIDs.val)){
        if(id == its.fieldIDs.val[j]){
          names[count] := its.fieldNames.val[j]
          count +:= 1
          break
        }
      }
    }
    return names
  }

  const its.find_cals := function(){
    # determine which of the sources are calibrators
    wider its

    for(i in its.dataDescIDs.val){
      ddescid := spaste(i)
      if(its.ddesc[ddescid].toProcess == F)
        continue

      ok := find_primary(ddescid, its)
      if(is_fail(ok)) return fatal(PARMERR, 'Error finding primary calibrator', ok::)

      ok := find_secondaries(ddescid, its)
      if(is_fail(ok)) return fatal(PARMERR, 'Error finding secondary calibrators', ok::)

      ok := all_calibrators(ddescid, its)
      if(is_fail(ok)) return fatal(PARMERR, 'Error combining calibrator lists', ok::)

      ok := find_targets(ddescid, its)
      if(is_fail(ok)) return fatal(PARMERR, 'Error finding target sources', ok::)
    }
    return T 
  }

  const its.show_settings := function(){
    wider its
    printf('\nThe data sets available for processing are:\n')

    for(ddescid in its.dataDescIDs.val){
      ddesc := its.ddesc[ddescid]
      freq := dq.div(ddesc.frequency, 1e+09).value

      if(its.stage.val == EDIT || its.stage.val == CALIB)
        vrec := [pName='unset', sNames='unset', targetNames='unset']
      else if(its.stage.val == IMAGE)
        vrec := [targetNames='unset']

      for(v in field_names(vrec)){
        if(!has_field(ddesc, v))
          vrec[v] := 'unset'
        else if(is_unset(ddesc[v].val))
          vrec[v] := 'unset'
        else
          vrec[v] := its.ddesc[ddescid][v].val
      }

      if(its.stage.val == CALIB){
        if(!has_field(its.ddesc[ddescid], 'calsForTargetNames'))
          matches := 'unset'
        else if(is_unset(its.ddesc[ddescid].calsForTargetNames.val))
          matches := 'unset'
        else if(is_unset(its.ddesc[ddescid].targetNames.val) || 
                is_unset(its.ddesc[ddescid].sNames.val))
          matches := 'unset'
        else
          matches := spaste(its.ddesc[ddescid].calsForTargetNames.val)
      }

      printf('\n')
      printf('Data set %d (freq = %5.3f GHz):\n', ddescid, freq)
      if(has_field(vrec, 'pName'))
        printf('    Primary = %s\n', vrec.pName)
      if(has_field(vrec, 'sNames'))
        printf('    Secondaries = %s\n', vrec.sNames)
      if(has_field(vrec, 'targetNames'))
        printf('    Targets = %s\n', vrec.targetNames)
      if(matches)
        printf('    Target-secondary matches = %s\n', matches)
    }
    dtoprocess := spaste(its.ddesctoProcess.val)
    n := len(its.ddesctoProcess.val)
    if(n == 0)
      printf('\nThe pipeline can not process any of the data sets\n\n')
    else if(n == 1)
      printf('\nThe pipeline can process data set %s\n\n', dtoprocess)
    else
      printf('\nThe pipeline can process data sets %s\n\n', dtoprocess)
  }

  const its.calc_modes := function(){
    wider its

    for(ddescid in its.dataDescIDs.val){
      nchan := its.ddesc[ddescid].nchan
      if(nchan == 13 || nchan == 14)
        mode := CONTINUUM
      else if(nchan > 14)
        mode := SPECTRAL
      else 
        mode := UNKNOWN

      if(dq.ge(its.ddesc[ddescid].frequency, '20GHz'))
        mode[i] := MILLIMETRE
      its.ddesc[ddescid].mode := mode
    }
    return T
  }

  const its.set := function(name, vis, mode, type, doc, alt, value){
    wider its
    its[name] := [=]
    its[name].vis := vis
    its[name].mode := mode
    its[name].type := type
    its[name].doc := doc
    its[name].alt := alt
    its[name].val := value

    its.attributes[len(its.attributes)+1] := name
    its.varmap[alt] := name
    its.rvarmap[name] := alt
    return T
  }

  const self.set_runid := function(runid){
    return its.set('runid', 0, 'const', 'string', 'ID for current run', 'runID', runid)
  } 

  const self.set_outdir := function(outdir){
    return its.set('outdir',0,'const','string','Directory for output data','outdir',outdir)
  }

  const self.set_msname := function(msname){
    return its.set('msname',0,'const','string','Name of measurement set','msname',msname)
  }

  const self.set_chan0raw := function(msname){
    return its.set('chan0raw',0,'const','string','Name of channel 0 MS','chan0raw',msname)
  }

  const self.set_chan0corr := function(msname){
    return its.set('chan0corr',0,'const','string','Name of channel 0 MS','chan0corr',msname)
  }

  const self.set_level := function(level){
    return its.set('level',0,'const','integer','Level to run pipeline at','level',level)
  }

  const self.set_stage := function(stage){
    return its.set('stage',0,'const','integer','Stage of pipeline','stage',stage)
  }

  const self.set_pidfile := function(pidfile){ 
    wider its
    its.pidfile := pidfile 
  }


  const self.get_msname := function(){ return its.msname.val }
  const self.get_logicvars := function(){ return its.logic }
  const self.get_vars := function(){ return its }
  const self.get_pidfile := function(){ return its.pidfile }

  const self.idtoName := function(id){
    for(i in 1:len(its.fieldIDs.val)){
      if(id == its.fieldIDs.val[i]){
        name := its.fieldNames.val[i]
        break
      }
    }
    return name
  }

  const self.idstoNames := function(ids){
    names := ['']
    for(id in ids){
      name := self.idtoName(id)
      names := [names, name]
    }
    return names
  }

  const self.show_config := function(){
    return its.show_config()
  }

  const self.copy_general_config := function(pl){
    # transfer general config options 
    wider its

    self.set_outdir(pl.get_outdir())
    self.set_msname(pl.get_msname())
    self.set_chan0raw(pl.get_chan0raw())
    self.set_chan0corr(pl.get_chan0corr())
    self.set_runid(pl.get_runid())
    self.set_level(pl.get_level())
    self.set_pidfile(pl.get_pidfile())

    if(its.level.val == BEGINNER)
      its.vislevel.val := 2
    if(its.level.val == EXPERT)
      its.vislevel.val := 1

    its.plotdir.val := spaste(its.outdir.val, '/plots/')
    its.chan0raw.val := spaste(its.outdir.val, '/', its.chan0raw.val)
    its.chan0corr.val := spaste(its.outdir.val, '/', its.chan0corr.val)

    return T
  }

  const self.edit := function(){
    # allow user to edit the current configuration

    its.show_config()
    while(1){
      input := readline(prompt='Change this configuration? (yes/no)>> ')
      doEdit := to_lower(input)

      if(doEdit == 'yes' || doEdit == 'y'){
        ok := interpreter(its)
        if(is_fail(ok)) return fatal(IOERR, 'Error editing configuration', ok::)
        break
      }
      else if(doEdit == 'no' || doEdit == 'n')
        break
    }
    return T
  }

  const self.update_config := function(ws){
    # takes a record holding command line parms
    # and updates appropriate fields
    wider its
    for(name in field_names(ws)){
      if(name == 'ddesc'){
        ok := its.parse_ddesc(ws[name])
        if(is_fail(ok)) return fatal(PARMERR, 'Error parsing ddesc input', ok::)
      }
      else if(name == 'rpfitsnames'){
        ok := its.parse_rpfitsnames(ws[name])
        if(is_fail(ok)) return fatal(PARMERR, 'Error parsing RPFITS names', ok::)
      }
      else{
        its[its.varmap[name]].val := ws[name]
        its[its.varmap[name]].mode := 'override'
      }
    }
    if(its.stage.val != FILL){
      if(!dos.fileexists(its.msname.val))
        return fatal(IOERR, 'Measurement set does not exist')
    }
    return T
  }
}

const load_config := function(filename, ref con){

  errorOnLine := function(filename, line){
    printf('Error reading config file: %s\n', filename)
    printf('  on line: %d\n', linenum)
  }

  # load a config file, checking for correctness
  con.attributes := ['']
  con.records := [=]

  for(path in system.path.include){
    f := open(spaste('< ', path, '/', filename))
    if(is_file(f)) break
  }
  if(!is_file(f)) return fatal(IOERR, 'Error opening config file')

  linenum := 0
  count := 1
  while(line := read(f)){
    linenum +:= 1
    words := split(line, ',')
    if(len(words) < 7){
      errorOnLine(filename, linenum)
      printf('Expecting at least 7 columns, found %d\n', len(words))
      if(len(words) == 0 || len(words) == 1)
        printf('Probably a blank line\n')
      continue 
    }

    local name := words[1]
    local vis := eval(words[2])
    if(type_name(vis) != 'integer'){
      errorOnLine(filename, linenum)
      printf('Vis column (2) must be an integer: %s\n', as_string(vis))
      continue
    }

    local mode := words[3]
    modes := ['const', 'override', 'calc']
    ok := F
    for(m in modes){
      if(mode == m){
        ok := T
        break
      }
    }
    if(!ok){
      errorOnLine(filename, linenum)
      printf('Mode column (3) must be one of; %s : %s\n', modes, as_string(mode))
      continue
    }

    local type := words[4]
    types := ['boolean', 'byte', 'short', 'integer', 'float', 'double', 
              'complex', 'dcomplex', 'string', 'record', 'quantity', 'measure']
    ok := F
    for(t in types){
      if(type == t){
        ok := T
        break
      }
    }
    if(!ok){
      errorOnLine(filename, linenum)
      printf('Type column (4) must be one of; %s : %s\n', types, type)
      continue
    }

    local doc := as_string(words[5])
    local alt := as_string(words[6])
    local value := eval(words[7:len(words)])

    if(is_unset(value))
      value := unset

    if(name ~ m/\./g){
      # record
      parts := split(name, '.')
      root := parts[1]
      subname := parts[2]
 
      if(!has_field(con, root)){
        con.attributes[count] := root
        con.records[root] := 1
        con[root] := [=] 
        count +:= 1
      }
      con[root][subname].vis := vis
      con[root][subname].mode := mode
      con[root][subname].type := type
      con[root][subname].doc := doc
      con[root][subname].alt := alt
      if(type == 'quantity')
        con[name].val := dq.quantity(value)
      else
        con[name].val := value
    }
    else if((type == 'quantity' || type == 'measure') && 
             (type_name(value) != 'string' && !is_unset(value))){
      errorOnLine(filename, linenum)
      printf('Variables of type -quantity-  or -measure- must be entered as strings\n')
      continue
    }
    else if(type != 'quantity' && type != 'measure' && 
            (type_name(value) != type && !is_unset(value))){
      errorOnLine(filename, linenum)
      printf('Type of value is incompatible with listed type: %s, %s\n', type, type_name(value))
      continue
    }
    else{
      # store values in config object
      con.attributes[count] := name
      con[name] := [=]
      con[name].vis := vis
      con[name].mode := mode
      con[name].type := type
      con[name].doc := doc
      con[name].alt := alt
      if(type == 'quantity')
        con[name].val := dq.quantity(value)
      else
        con[name].val := value
      count +:= 1
    }
  }
  printf('Configuration file read successfully\n')
  return T
}

const save_config := function(filename, ref con){
  f := open(spaste('> ', filename))
  if(!is_file(f)) return fatal(IOERR, 'Error opening config file for saving')

  for(name in con.attributes){
    if(name == 'ddesc')
      continue
    if(has_field(con.records, name)){
      rec := con[name]
      for(subname in field_names(rec)){
        namestring := spaste(name, '.', subname)
        valstring := spaste(rec[subname].val)
        fprintf(f, '%s,%1d,%s,%s,%s,%s,%s\n', namestring, rec[subname].vis, rec[subname].mode, 
                rec[subname].type, rec[subname].doc, rec[subname].alt, valstring)
      }
    }
    else if(type_name(con[name].val) == 'string'){
      value := con[name].val
      if(len(value) == 1)
        valstring := paste('\'', value, '\'', sep='')
      else
        valstring := paste('\"', value, '\"', sep='')
      fprintf(f, '%s,%1d,%s,%s,%s,%s,%s\n', name, con[name].vis, con[name].mode, 
              con[name].type, con[name].doc, con[name].alt, valstring)
    }
    else{
      valstring := spaste(con[name].val)
      fprintf(f, '%s,%1d,%s,%s,%s,%s,%s\n', name, con[name].vis, con[name].mode, 
              con[name].type, con[name].doc, con[name].alt, valstring)
    }
  }
  return T
}

