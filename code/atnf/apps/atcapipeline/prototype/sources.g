#-----------------------------------------------------------------------------
# sources.g: Identifys targets & calibrators for the ATCA pipeline
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

const set_rec := function(ref rec, vis, doc, alt, value, mode='calc', type='string'){
  rec.vis := vis
  rec.doc := doc
  rec.alt := alt
  rec.val := value
  rec.type := type
  rec.mode := mode
  return T
}

const search_cat := function(sources, cals){
  # return a list of which sources have matches in calibrator list
  matches := [=]

  for(i in 1:len(sources)){
    matches[spaste(i)] := F
    if(sources[i] == '1934-638')
      continue
    for(j in 1:len(cals)){
      if(sources[i] == cals[j]){
        matches[spaste(i)] := T
        break
      }
    }
  }
  return matches
}

const find_ID := function(name, ddescid=unset, con){
  if(is_unset(ddescid)){
    fieldnames := con.fieldNames.val
    fieldids := con.fieldIDs.val
  }
  else{
    fieldnames := con.ddesc[ddescid].fieldNames
    fieldids := con.ddesc[ddescid].fieldIDs
  }
  for(i in 1:len(fieldnames)){
    if(fieldnames[i] == name)
      return fieldids[i]
  }
  printf('WARNING: "%s" is not a valid field name (find_ID)\n', as_string(name))
  return 0
}

const find_IDs := function(names, ddescid=unset, con){
  # given a vector of names, return 
  # a vector of the corresponding IDs

  if(is_unset(ddescid)){
    fieldnames := con.fieldNames.val
    fieldIDs := con.fieldIDs.val
  }
  else{
    fieldnames := con.ddesc[ddescid].fieldNames
    fieldIDs := con.ddesc[ddescid].fieldIDs
  }

  ids := []
  count := 1
  for(i in 1:len(names)){
    match := F
    for(j in 1:len(fieldnames)){
      if(names[i] == fieldnames[j]){
        a := fieldIDs[j]
        ids[count] := fieldIDs[j]
        count +:= 1
        match := T
        break
      }
    }
    if(!match)
      printf('WARNING: "%s" is not a valid field name for ddescid=%s\n', as_string(names[i]), as_string(ddescid))
  }
  return ids
}

const find_primary := function(ddescid, ref con){
  pID := 0
  ddesc := con.ddesc[ddescid]

  if(!is_fail(ddesc.pName) && ddesc.pName.mode == 'override'){
    name := ddesc.pName.val
    pID := find_ID(name, ddescid, con)
  }
  else{
    con.ddesc[ddescid].pName := [=]
    con.ddesc[ddescid].pID := [=]
    name := '1934-638'
    pID := find_ID(name, ddescid, con)
    if(pID == 0){
      name := '0823-500'
      pID := find_ID(name, ddescid, con)
    }
  }

  if(pID == 0){
    pNameval := unset
    pIDval := unset
  }
  else{
    pNameval := name
    pIDval := pID
  }
  if(con.stage.val == CALIB)
    vis := 2
  else if(con.stage.val == IMAGE)
    vis := 1
  set_rec(rec=con.ddesc[ddescid].pName, vis=vis, alt=spaste('primary', ddescid), 
         doc='Name of primary calibrator', type='string', value=pNameval)
  set_rec(rec=con.ddesc[ddescid].pID, vis=0, alt=spaste('pID', ddescid), 
         doc='ID of primary calibrator', type='integer', value=pIDval)
  return T
}

const find_secondaries := function(ddescid, ref con){
  fieldnames := con.ddesc[ddescid].fieldNames
  fieldids := con.ddesc[ddescid].fieldIDs
  con.ddesc[ddescid].sIDs := [=]

  calsfortargets := con.ddesc[ddescid].calsForTargetNames
  if(!is_fail(calsfortargets) && calsfortargets.mode == 'override'){
    names := ['']
    count := 1
    for(i in field_names(calsfortargets.val)){
      snames := calsfortargets.val[i]
      for(j in 1:len(snames)){      
        names[count] := snames[j]
        count +:= 1
      }
    }
    sIDs := find_IDs(names, ddescid, con)      
  }
  else{
    con.ddesc[ddescid].sNames := [=]
    matches := search_cat(fieldnames, con.standardCals)
    names := ['']
    sIDs := []
    count := 1
    for(i in 1:len(matches)){
      if(matches[i] == T){
        names[count] := fieldnames[i]
        sIDs[count] := fieldids[i]
        count +:= 1
      }
    }
  }

  if(len(sIDs) == 0){
    sNamesval := unset
    sIDsval := unset
  }
  else{
    sIDsval := sIDs
    sNamesval := con.idstoNames(sIDs)
  }

  if(con.stage.val == CALIB)
    vis := 2
  else if(con.stage.val == IMAGE)
    vis := 1
  set_rec(rec=con.ddesc[ddescid].sNames, vis=vis, alt=spaste('secondaries', ddescid), 
         doc='Names of secondary calibrators', type='string', value=sNamesval)
  set_rec(rec=con.ddesc[ddescid].sIDs, vis=0, alt=spaste('sIDs', ddescid), 
         doc='IDs of secondary calibrators', type='integer', value=sIDsval)
  return T
}

const all_calibrators := function(ddescid, ref con){
  # create list of all calibrators
  pname := con.ddesc[ddescid].pName.val
  pid := con.ddesc[ddescid].pID.val
  snames := con.ddesc[ddescid].sNames.val
  sids := con.ddesc[ddescid].sIDs.val

  if(is_unset(pname) && is_unset(snames)){
    calnames := unset
    calids := unset
  }
  else if(is_unset(pname)){
    calnames := snames
    calids := sids
  }
  else if(is_unset(snames)){
    calnames := pname
    calids := pid
  }
  else{
    calnames := [pname, snames]
    calids := [pid, sids]
  }    
  con.ddesc[ddescid].calNames := [=]
  con.ddesc[ddescid].calIDs := [=]

  set_rec(rec=con.ddesc[ddescid].calNames, vis=0, alt=spaste('calibratorNames', ddescid), 
         doc='Names of all calibrators', value=calnames, type='string')
  set_rec(rec=con.ddesc[ddescid].calIDs, vis=0, alt=spaste('calibratorIDs', ddescid), 
         doc='IDs of all calibrators', value=calids, type='integer')
  return T
}


const find_targets := function(ddescid, ref con){
  # make a list of all non-calibrators
  fieldnames := con.ddesc[ddescid].fieldNames
  fieldids := con.ddesc[ddescid].fieldIDs
  calnames := con.ddesc[ddescid].calNames.val

  cals := has_field(con.ddesc[ddescid], 'calsForTargetNames')
  targets := has_field(con.ddesc[ddescid], 'targetNames')

  if(cals==T && con.ddesc[ddescid].calsForTargetNames.mode == 'override'){
    names := field_names(con.ddesc[ddescid].calsForTargetNames.val)
    ids := find_IDs(names, ddescid, con)
  }
  else if(targets==T && con.ddesc[ddescid].targetNames.mode == 'override'){
    # targets have been selected at user interface
    names := con.ddesc[ddescid].targetNames.val
    ids := find_IDs(names, ddescid, con)
  }
  else{
    # targets have not been selected at all
    con.ddesc[ddescid].targetNames := [=]
    con.ddesc[ddescid].targetIDs := [=]
    count := 1
    ids := []
    names := ['']
    for(i in 1:len(fieldnames)){
      target := T
      for(j in 1:len(calnames)){
        if(fieldnames[i] == calnames[j]){
          target := F
          break
        }
      }
      if(target){
        names[count] := fieldnames[i]
        ids[count] := fieldids[i]
        count +:= 1
      }        
    }
  }

  if(len(ids) == 0){
    targetNames := unset
    targetIDs := unset
  }
  else{
    targetIDs := ids
    targetNames := con.idstoNames(ids)
  }
  set_rec(rec=con.ddesc[ddescid].targetNames, vis=2, alt=spaste('targets', ddescid), 
         doc='Names of all target sources', value=targetNames, type='string')
  set_rec(rec=con.ddesc[ddescid].targetIDs, vis=0, alt=spaste('targetIDs', ddescid), 
         doc='IDs of all target sources', value=targetIDs, type='integer')
  return T
}
