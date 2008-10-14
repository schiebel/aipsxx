#-----------------------------------------------------------------------------
# ddesc.g: Data Description ID management functions for the ATCA pipeline
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
include 'quanta.g'
include 'atcapl.g'

const transfer_primary_ddesc := function(ref con, ddescid, primary){
  con.ddesc[ddescid]['pName'] := [=]
  con.ddesc[ddescid]['pName'].vis := 2
  con.ddesc[ddescid]['pName'].mode := 'override'
  con.ddesc[ddescid]['pName'].alt := spaste('primary',ddescid)
  con.ddesc[ddescid]['pName'].val := primary
  return T
}

const transfer_calibrators_ddesc := function(ref con, ddescid, calibrators){
  con.ddesc[ddescid]['calsForTargetNames'] := [=]
  con.ddesc[ddescid]['calsForTargetNames'].vis := 2
  con.ddesc[ddescid]['calsForTargetNames'].mode := 'override'
  con.ddesc[ddescid]['calsForTargetNames'].alt := spaste('matches', ddescid)
  con.ddesc[ddescid]['calsForTargetNames'].val := [=]


  for(targetName in field_names(calibrators)){
    con.ddesc[ddescid].calsForTargetNames.val[targetName] := calibrators[targetName]
  }
  return T
}

const transfer_targets_ddesc := function(ref con, ddescid, targets){
  con.ddesc[ddescid]['targetNames'] := [=]
  con.ddesc[ddescid]['targetNames'].vis := 2
  con.ddesc[ddescid]['targetNames'].mode := 'override'
  con.ddesc[ddescid]['targetNames'].alt := spaste('targets',ddescid)
  con.ddesc[ddescid]['targetNames'].val := targets
  return T
}

const transfer_to_ddesc := function(ref con, rec, ddescid, parm){
  con.ddesc[ddescid][parm] := [=]
  con.ddesc[ddescid][parm].vis := 2
  con.ddesc[ddescid][parm].mode := 'override'
  con.ddesc[ddescid][parm].alt := spaste(parm,ddescid)
  con.ddesc[ddescid][parm].val := rec[parm]
  return T
}

const transfer_primary :=function(ref con, rec, ddescid=F){
  # transfer primary cal from inddesc to ddesc
  if(has_field(rec, 'primary'))
    primary := rec['primary']
  else{
    return T  
  }
  if(ddescid){
    ok := transfer_primary_ddesc(con, ddescid, primary)
    if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
  }
  else{
    for(ddescid in field_names(con.ddesc)){
      ok := transfer_primary_ddesc(con, ddescid, primary)
      if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
    }
  }
  return T
}

const transfer_calibrators := function(ref con, rec, ddescid=F){
  # transfer cal info from inddesc to ddesc
  if(has_field(rec, 'calibrators'))
    calibrators := rec['calibrators']
  else{
    return T
  }

  if(ddescid){
    ok := transfer_calibrators_ddesc(con, ddescid, calibrators)
    if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
  }
  else{
    for(ddescid in field_names(con.ddesc)){
      ok := transfer_calibrators_ddesc(con, ddescid, calibrators)
      if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
    }
  }
  return T
}

const transfer_targets := function(ref con, rec, ddescid=F){
  # transfer targets info from inddesc to ddesc
  if(has_field(rec, 'targetNames'))
    targets := rec['targetNames']
  else{
    return T
  }

  if(ddescid){
    ok := transfer_targets_ddesc(con, ddescid, targets)
    if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
  }
  else{
    for(ddescid in field_names(con.ddesc)){
      ok := transfer_targets_ddesc(con, ddescid, targets)
      if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
    }
  }
  return T
}

const transfer_parms := function(ref con, rec, ddescid=F){
  # transfer parameters info from inddesc to ddesc

  if(ddescid){
    ddesc := con.ddesc[ddescid]
    for(parm in field_names(rec)){
      if(parm == 'parms')
        continue
      ok := transfer_to_ddesc(con, rec, ddescid, parm)
      if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
    }
  }
  else{
    for(ddescid in field_names(con.ddesc)){
      ddesc := con.ddesc[ddescid]
      for(parm in field_names(rec)){
        if(parm == 'parms')
          continue
        ok := transfer_to_ddesc(con, rec, ddescid, parm)
        if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
      }
    }
  }
  return T
}

const transfer_all := function(ref con, id, ddescid=F){
  if(con.stage.val == EDIT || con.stage.val == IMAGE){
    ok := transfer_parms(con, con.inddesc[id], ddescid)
    if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
  }
  ok := transfer_calibrators(con, con.inddesc[id], ddescid)
  if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)

  ok := transfer_primary(con, con.inddesc[id], ddescid)
  if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)

  ok := transfer_targets(con, con.inddesc[id], ddescid)
  if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
}


const set_ddescto_process := function(ref con, ddescid=F){
  if(ddescid)
    con.ddesc[ddescid].toProcess := T
  else{
    for(ddescid in field_names(con.ddesc))
      con.ddesc[ddescid].toProcess := T
  }
  return T
}

const match_chan := function(inChan, dChan){
  # match channels, including birdie case
  if(inChan == 33){
    if(dChan == 13 || dChan == 14)
      return T
    else
      return F
  }
  else{
    if(inChan == dChan)
      return T
    else
      return F
  }
}

const match_band := function(inBand, dBand, inChan, dChan){
  # match total bandwidth, including birdie case
  if(inChan == 33){
    chanwidth :=  dq.div(inBand, (inChan - 1))
    totalbw := dq.mul(chanwidth, (2 * dChan))
  }
  else
    totalbw := inBand

  if(dq.eq(totalbw, dBand))
    return T
  else
    return F
}

const identify_ddescs := function(ref con){
  if(len(field_names(con.inddesc))==0){
    ok := set_ddescto_process(con)
    if(is_fail(ok)) return fatal(PARMERR, 'Error identifying data sets', ok::)
    return T
  }

  for(i in field_names(con.inddesc)){
    if(con.inddesc[i]['parms'] == 'all'){
      ok := set_ddescto_process(con)
      if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)

      ok := transfer_all(con, i)
      if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
      break
    }
    else{
      parms := split(con.inddesc[i]['parms'], ',')
      match := F
      if(len(parms) != 4){
        print 'Not enough information to identify ddesc ', parms
      }
      else{
        inFreq := dq.quantity(parms[1])
        inBand := dq.quantity(parms[2])
        inChan := as_integer(parms[3])
        inCorr := as_integer(parms[4])

        for(j in field_names(con.ddesc)){
          dFreq := con.ddesc[j].frequency
          dChan := con.ddesc[j].nchan
          dBand := con.ddesc[j].bandwidth
          dCorr := con.ddesc[j].ncorr

          mChan := match_chan(inChan, dChan)
          mBand := match_band(inBand, dBand, inChan, dChan)
          if(mChan == T && mBand == T && dq.eq(inFreq,dFreq) && inCorr == dCorr){
            match := T
            print parms, ' successfully identified as ddesc ', j, dq.tos(dFreq), dChan, dq.tos(dBand), dCorr
            ok := set_ddescto_process(con, ddescid=j)
            if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
            ok := transfer_all(con, i, ddescid=j)
            if(is_fail(ok)) return fatal(PARMERR, 'Error processing data set information', ok::)
            break
          }
        }
        if(match==F)
          print 'No matching ddesc found for ', parms
      }
    }
  }
  return T
}


