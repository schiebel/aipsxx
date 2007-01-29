#-----------------------------------------------------------------------------
# runws.g: Script to run the ATCA pipeline in web services (CL) mode
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

if(environ.pipepath)
  system.path.include:=[environ.pipepath, system.path.include]

include 'logger.g'
dl.attach('')
include 'plgui.g'
include 'unset.g'

const read_args := function(){
  if(len(argv) == 2)
    display_quick_help()
  else if(len(argv) == 3 && argv[3] == '--help')
    display_ws_help()
  else if(len(argv) > 3){
    args := argv[3:len(argv)]
    if(is_string(args)){
      return args
    }
    else
      return fatal(IOERR, 'ERROR reading command line arguments')
  }
  else
    return fatal(IOERR, 'ERROR: no command line arguments')
}

const determine_stage := function(rec){
  if(!has_field(rec, 'stage'))
    return fatal(IOERR, 'Must supply a stage to run (eg. --stage FILL)')

  inStage := to_lower(rec.stage)

  if(inStage == 'fill' || inStage == 'load')
    rec.stage := FILL
  else if(inStage == 'edit' || inStage == 'flag')
    rec.stage := EDIT
  else if(inStage == 'calibrate' || inStage == 'calib' || inStage == 'cal')
    rec.stage := CALIB
  else if(inStage == 'image')
    rec.stage := IMAGE 
  else 
    return fatal(IOERR, spaste('ERROR: unknown stage ', inStage))
  return rec
}

const check_required_args := function(rec){
  # check that the necessary args are present 
  stage := rec.stage

  if(!has_field(rec, 'outdir'))
    return fatal(IOERR, 'Must supply an output directory (outdir) for results')

  if(stage == FILL){
    # Filling
    if(!has_field(rec, 'rpfitsnames'))
      return fatal(IOERR, 'Must supply an input filename (rpfitsnames) for filling')
    if(!has_field(rec, 'msname'))
      return fatal(IOERR, 'Must supply an output directory (msname)')
  }
  else if(stage == CALIB){
    if(!has_field(rec, 'msname'))
      return fatal(IOERR, 'Must supply an input msname (msname)')
    if(!has_field(rec, 'ddesc'))
      return fatal(IOERR, 'Must supply an ddesc value (can use --ddesc all)')
  }
  else if(stage == EDIT){
    if(!has_field(rec, 'msname'))
      return fatal(IOERR, 'Must supply an input msname (msname)')
    if(!has_field(rec, 'ddesc'))
      return fatal(IOERR, 'Must supply an ddesc value (can use --ddesc all)')
  }
  else if(stage == IMAGE){
    if(!has_field(rec, 'msname'))
      return fatal(IOERR, 'Must supply an input msname (msname)')
    if(!has_field(rec, 'ddesc'))
      return fatal(IOERR, 'Must supply an ddesc value (can use --ddesc all)')
  }    
  else
    return fatal(IOERR, 'Invalid stage selected')
  return T
}

const check_bools := function(value){
  if(value == 'T' || value == 'True' || value == 'TRUE')
    return T
  else 
    return F
}

const check_args_format := function(rec){
  # lowfreq/highfreq
  if(has_field(rec, 'lowfreq') && has_field(rec, 'highfreq')){
    low := dq.quantity(rec.lowfreq)
    high := dq.quantity(rec.highfreq)
    if(dq.ge(low, high))
      return fatal(IOERR, 'ERROR: lowfreq must be lower than highfreq')
  }
  if(has_field(rec, 'bandwidth'))
    rec.bandwidth := dq.quantity(rec.bandwidth)
  if(has_field(rec, 'numchan'))
    rec.numchan := as_integer(rec.numchan)
  if(has_field(rec, 'niter'))
    rec.niter := as_integer(rec.niter)

  if(has_field(rec, 'doMem'))
    rec.doMem := check_bools(rec.doMem)
  if(has_field(rec, 'doClean'))
    rec.doClean := check_bools(rec.doClean)
  return rec
}

const check_allowed_args := function(rec){
  ws := [=]

  # acceptable command line args
  fields := [=]
  fields[paste(FILL)] := [stage=1, msname=1, outdir=1, rpfitsnames=1, options=1,
                          sourceNames=1, ifchain=1, lowfreq=1, highfreq=1, numchan=1,
                          firstscan=1, lastscan=1, bandwidth=1, shadow=1] 
  fields[paste(EDIT)] := [stage=1, msname=1, outdir=1, ddesc=1, primary=1, 
                          plotFlagged=1, plotRaw=1, doFlagging=1, 
                          useCorrected=1, threshold=1, calibrators=1,
                          delBirdie=1, subContinuum=1]
  fields[paste(CALIB)] := [stage=1, msname=1, outdir=1, primary=1, ddesc=1,
                           calibrators=1, refant=1, average=1, avmode=1,
                           intervalP=1, intervalG=1, intervalD=1, intervalB=1]
  fields[paste(IMAGE)] := [stage=1, msname=1, outdir=1, ddesc=1, targetNames=1, mode=1, 
                           stokes=1, nx=1, ny=1, cell=1, doClean=1, algorithm=1, 
                           niter=1, loopgain=1, threshold=1, doMem=1, malgorithm=1, 
                           mniter=1, sigma=1, targetflux=1]

  stage := as_integer(rec.stage)
  for(name in field_names(rec)){
    if(has_field(fields[stage], name))
      ws[name] := rec[name]
    else{
      printf('WARNING %s is not a valid parameter for stage %d\n', name, stage)
      printf('Ignoring this parameter\n')
    }
  }
  return ws
}

const process_args := function(args){
  rec := [=]
  argc := len(args)
  i := 1
  dcount := 1
  firstCal := T
  current := unset
  while(i <= argc){
    parameter := args[i]
    i +:= 1
    if(parameter ~ m/--/g){
      count := 1
      value := ['']
      name := parameter ~s/--//g
      while(i <= argc){
        if(args[i] ~ m/--/g)
          break
        value[count] := args[i]
        count +:= 1
        i +:= 1
      }
      if(name == 'debug'){
        global DEBUG := T
      }
      else if(name == 'ddesc'){
        if(!has_field(rec, 'ddesc'))
          rec['ddesc'] := [=]
        if(!is_unset(current)){
          rec.ddesc[spaste(dcount)] := current
          dcount +:= 1
        }
        current := [=]
        current['parms'] := value
      }
      else if(name == 'calibrators'){
        if(is_unset(current)) return fatal(PARMERR, 'Calibrator flag must follow a ddesc flag')
        if(has_field(current, 'calibrators')){
          n := len(current['calibrators']) + 1
          current['calibrators'][n] := value
        }
        else{
          current['calibrators'] := [value]
        }
      }
      else if(name == 'primary' || name == 'targetNames'
            || name == 'nx' || name == 'ny' || name == 'cell'){
        msg := spaste(name, ' flag must follow a ddesc flag')
        if(is_unset(current)) return fatal(PARMERR, msg)
        current[name] := value
      }
      else if(name == 'plotFlagged' || name == 'plotRaw' 
            || name == 'doFlagging' || name == 'useCorrected'
            || name == 'delBirdie' || name == 'subContinuum'){
        msg := spaste(name, ' flag must follow a ddesc flag')
        if(is_unset(current)) return fatal(PARMERR, msg)

        value := check_bools(value)
        current[name] := value
      }
      else
        rec[name] := value
    }
    else{
      printf('Lone parameter with no handle %s', parameter)
      printf('Ignoring this parameter\n')
    }
  }
  if(!is_unset(current)){
    rec.ddesc[spaste(dcount)] := current
  }
  return rec
}


# Main program
global level := WS

args := read_args()

include 'atcapl.g'

rec := process_args(args)
if(is_fail(rec)) report_error_ws()

rec := determine_stage(rec)
if(is_fail(rec)) report_error_ws()

ok := check_required_args(rec)
if(is_fail(ok)) report_error_ws()

rec := check_args_format(rec)
if(is_fail(rec)) report_error_ws()

ws := check_allowed_args(rec)
if(is_fail(ws)) report_error_ws()

stage := as_integer(ws.stage)
pl := atcapl()
if(is_fail(pl)) report_error_ws()
pl.setlevel(WS)

ok := pl.run_ws(stage, ws)
if(is_fail(ok)) report_error_ws()

pl.done()



