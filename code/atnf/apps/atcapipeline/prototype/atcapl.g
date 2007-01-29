#-----------------------------------------------------------------------------
# atcapl.g: Overall pipeline class for the ATCA pipeline
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

include 'ms.g'
include 'logger.g'
include 'unset.g'
include 'misc.g'
include 'configFiller.g'
include 'configEdit.g'
include 'configCalib.g'
include 'configImage.g'
include 'atcaFill.g'
include 'atcaEdit.g'
include 'atcaCalib.g'
include 'atcaImage.g'
include 'plgui.g'
include 'error.g'

# set global constants
global EXIT := 5
const EXIT := EXIT
global DEBUG := F


# level
global BEGINNER := 1
global EXPERT := 2
global AUTO := 3
global WS := 4
const BEGINNER := BEGINNER
const EXPERT := EXPERT
const AUTO := AUTO
const WS := WS

# mode
global CONTINUUM := 1
global SPECTRAL := 2
global MOSAIC := 3
global PULSAR := 4
global MILLIMETRE := 5
global UNKNOWN := 6
const CONTINUUM := CONTINUUM
const SPECTRAL := SPECTRAL
const MOSAIC := MOSAIC
const PULSAR := PULSAR
const MILLIMETRE := MILLIMETRE
const UNKNOWN := UNKNOWN

# stage 
global FILL := 1
global EDIT := 2
global CALIB := 3
global IMAGE := 4
const FILL := FILL
const EDIT := EDIT
const CALIB := CALIB
const IMAGE := IMAGE

# flow
global ONE := 1
const ONE := ONE

atcapl := subsequence(){

# Private variables and functions
  its := [=]

  const its.init_pipeline := function(){
    wider its
    its.runid := its.create_runid()
    its.uid := its.create_uid()

    # set pipeline defaults
    its.defaultmsname := 'data.ms'
    its.msname := its.defaultmsname
    its.chan0raw := 'chan0raw.ms'
    its.chan0corr := 'chan0corr.ms'
    its.defaultoutdir := spaste(dms.thisdir('.'), '/results')
    its.outdir := its.defaultoutdir

    ok := its.log_setup()
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting up logging', ok::)
    return T
  }

  const its.create_runid := function(){
    # sets an id for the whole run
    return shell("date +%d%m%y_%H%M%S")
  }

  const its.create_uid := function(){
    # get the user id
    uid := shell('whoami')
    if(is_fail(uid)){
      printf('Error: cant get uid using whoami\n')
      uid := 'nouid'
    }
    return uid
  }

  const its.create_pidfile := function(){
    # create a file to store process ids in
    wider its
    filename := spaste(its.outdir, '/logs/', its.runid, '.pids')
    its.pidfile := fopen(filename, 'w')
    if(!is_file(its.pidfile)) return fatal(IOERR, 'Error opening pid file', its.pidfile::)

    # store glish script pid and parent pid
    fprintf(its.pidfile, '%d glish\n', system.pid)
    fprintf(its.pidfile, '%d parent\n', system.ppid)
    return T
  }

  const its.log_setup := function(){
    # empty current AIPS++ standard log
    ok := dl.purge(keeplast=0)
    if(is_fail(ok)) fail
    return T
  }

  const its.save_log := function(){
    if(!is_unset(its.outdir)){
      dirname := spaste(its.outdir, '/logs')
      temp := spaste(its.runid, '.log')
      logdir := paste(dirname, temp, sep='/')
      if(is_fail(temp) || is_fail(logdir))
        return fatal(IOERR, 'Error saving log file', logdir::)

      ok := dl.printtofile(filename=logdir)
      if(is_fail(ok)) printf('Error: no log has been saved\n')
      printf('A log of your session has been printed to\n')
      printf('%s\n', logdir)
    }
    return T
  }

  const its.run_filler := function(config){
    wider its
    printf('Running filler...\n')
    note('atcafiller')

    fill := atcafill(config)
    if(is_fail(fill)) fail

    ok := fill.fill(config)
    if(is_fail(ok)) fail

    ok := fill.done(config)
    if(is_fail(ok)) fail

    its.defaultmsname := its.msname
    its.laststage := FILL
    printf('Filler done\n')
    return T
  }

  const its.run_edit := function(config){
    wider its
    printf('Running editing\n')
    note('atcaeditor')

    af := atcaeditor(config)
    if(is_fail(af)) fail

    ok := af.edit(config)
    if(is_fail(ok)) fail

    ok := af.done(config)
    if(is_fail(ok)) fail

    its.defaultmsname := its.msname
    its.laststage := EDIT
    printf('Flagging finished successfully\n')
    return T
  }

  const its.run_calib := function(config){
    wider its
    printf('Running calibration\n')
    cal := atcacalibrater(config)
    if(is_fail(cal)) fail

    ok := cal.calibrate(config)
    if(is_fail(ok)) fail

    ok := cal.done(config)
    if(is_fail(ok)) fail

    its.defaultmsname := its.msname
    its.laststage := CALIB
    printf('Calibration finished successfully\n')
    return T
  }

  const its.run_image := function(config){
    wider its
    printf('Running imaging\n')

    im := atcaimager(config)
    if(is_fail(im)) fail

    ok := im.image(config)
    if(is_fail(ok)) fail

    ok := im.done(config)
    if(is_fail(ok)) fail

    its.laststage := IMAGE
    its.defaultmsname := its.msname
    printf('Imaging finished successfully\n')
    return T
  }

  const its.check_obs_type := function(config, stage){
    c := config.get_vars()

    if(stage == FILL)
      return T
    else
      ddesclist := c.ddesctoProcess.val

    good := F
    for(ddesc in ddesclist){
      freq := dq.tos(dq.convertfreq(c.ddesc[ddesc].frequency, 'GHz'))
      nchan := c.ddesc[ddesc].nchan
      ncorr := c.ddesc[ddesc].ncorr
      printf('\n')
      if(c.ddesc[ddesc].mode == MILLIMETRE){
        printf('Spectral Window %d (%s, %d chan, %d poln) is a MM observation\n', 
                ddesc, freq, nchan, ncorr)
        printf('This spectral window can not be processed with the current pipeline\n')
      }
      else if(c.ddesc[ddesc].mode == CONTINUUM){
        printf('Spectral Window %d (%s, %d chan, %d poln) is a Continuum observation\n', 
               ddesc, freq, nchan, ncorr)
        printf('This spectral window can be processed with the current pipeline\n')
        good := T
      }
      else if(c.ddesc[ddesc].mode == SPECTRAL){
        printf('Spectral Window %d (freq = %s, nchan = %d) is a Spectral Line observation\n', 
                ddesc, freq, nchan)
        printf('This spectral window can not be processed with the current pipeline\n')
## XXX This good should be removed until spectral line is public
        good := T
      }
      else{
        printf('Spectral Window %d (freq = %s, nchan = %d) is an observation of unknown type\n', 
                ddesc, freq, nchan)
        printf('This spectral window can not be processed with the current pipeline\n')
      }
    }
    if(good == F){
      printf('There are no spectral windows that can be processed by the current pipeline\n')
      self.done()
    }
    return T
  }

  const its.check_valid := function(parm, allowed){
    if(parm == EXIT)
      self.done()
    for(value in allowed){
      if(parm == value)
        return T
    }
    printf('Invalid level selected\n')
    return F
  }

  const its.choose_level := function(){
    # choose beginner/expert
    wider its
    valid := F
    while(!valid){
      level := to_lower(display_level())
      if(level == '' || level == 'b')
        level := BEGINNER
      else if(level == 'a')
        level := EXPERT
      else if(level == 'x')
        level := EXIT
      valid := its.check_valid(level, [BEGINNER, EXPERT])
    }
    its.level := level
    return its.level
  }

  const its.choose_mode := function(){
    # choose synthesis/spectral line/pulsar
    wider its
    valid := F
    while(!valid){
      mode := to_lower(display_mode())
      if(mode == '' || mode == 's')
        mode := CONTINUUM
      else if(mode == 'x')
        mode := EXIT
      valid := its.check_valid(mode, [CONTINUUM])
    }
    its.mode := mode
    return its.mode
  }

  const its.choose_flow := function(){
    # choose preset/stage/load configs
    wider its
    valid := F
    while(!valid){
      flow := to_lower(display_flow())
      if(flow == '' || flow == 'o')
        flow := ONE
      else if(flow == 'x')
        flow := EXIT
      valid := its.check_valid(flow, [ONE])
    }
    its.flow := flow
    return its.flow
  }
  
  const its.choose_stage := function(){
    # choose load/edit/flag/calib/image/end
    wider its
    valid := F
    while(!valid){
      stage := to_lower(display_stage())
      if(stage == '' || stage == 'f')
        stage := FILL
      else if(stage == 'e')
        stage := EDIT
      else if(stage == 'c')
        stage := CALIB
      else if(stage == 'i')
        stage := IMAGE
      else if(stage == 'x')
        stage := EXIT
      valid := its.check_valid(stage, [FILL,EDIT,CALIB,IMAGE])
    }
    its.stage := stage
    return its.stage
  }

  const its.choose_outdir := function(){
    wider its
    if(is_string(its.defaultoutdir))
      msg := spaste('Name of directory for results (default = current dir) >> ')
    else
      msg := spaste('Name of directory for results (no default) >> ')

    valid := F
    while(!valid){
      dir := readline(prompt=msg)
      if(dir == '')
        dir := its.defaultoutdir
      valid := its.check_working(dir)
    }
    return its.outdir
  }

  const its.choose_msname := function(){
    wider its
    if(is_string(its.defaultmsname))
      msg := spaste('Name of measurement set (', its.defaultmsname, ')>> ')
    else
      msg := spaste('Name of measurement set (no default) >> ')

    valid := F
    while(!valid){
      msname := readline(prompt=msg)
      if(msname == '')
        msname := its.defaultmsname
      if(its.stage == FILL)
        valid := dos.isvalidpathname(msname)
      else
        valid := dos.fileexists(msname)
      if(!valid)
        printf('Error: chosen measurement set does not exist\n')
    }
    its.msname := msname
    return its.msname
  }

  const its.check_new_dir := function(dir){
    if(dos.isvalidpathname(dir))
      return dos.mkdir(dir)
    return F
  }

  const its.check_dir := function(dir){
     printf('%s\n', dir)
     if(dos.fileexists(dir))
        return T
     else 
        return its.check_new_dir(dir)
  }

  const its.check_working := function(wd){
    wider its
    its.outdir := wd
    printf('Results will be put in the following directories:\n')
    dirok := its.check_dir(wd) &&
           its.check_dir(spaste(wd, '/config')) &&
           its.check_dir(spaste(wd, '/logs')) &&
           its.check_dir(spaste(wd, '/images')) &&
           its.check_dir(spaste(wd, '/calib')) &&
           its.check_dir(spaste(wd, '/plots'))        
    if(dirok == T){
      ok := its.create_pidfile()
      if(is_fail(ok)) return fatal(IOERR, 'Error creating pid file', ok::)
    }
    return dirok
  }

  const its.check_working_ws := function(wd){
    if(!its.check_working(wd))
      return fatal(IOERR, 'Results directory (outdir) is invalid')
    else
      return T
  }

  const its.setval := function(name, value){
    wider its
    its[name] := value
    return T
  }

# Public variables and functions 
  const self.setlevel := function(level){
    return its.setval('level', level)
  }

  const self.setlaststage := function(laststage){
    wider its
    its.laststage := as_integer(laststage)
    return T
  }

  const self.get_runid := function(){ return its.runid }
  const self.get_msname := function(){ return its.msname }
  const self.get_chan0raw := function(){ return its.chan0raw }
  const self.get_chan0corr := function(){ return its.chan0corr }
  const self.get_outdir := function(){ return its.outdir }
  const self.get_level := function(){ return its.level }
  const self.get_flow := function(){ return its.flow }
  const self.get_stage := function(){ return its.stage }
  const self.get_pidfile := function(){ return its.pidfile }

  const self.choose_global_options := function(){
    level := its.choose_level()
    mode := its.choose_mode()
    flow := its.choose_flow()
    stage := its.choose_stage() 
    outdir := its.choose_outdir()
    msname := its.choose_msname()
    return T
  }

  const self.load_config := function(stage){
    if(stage == FILL)
      return configfiller(self)
    else if(stage == EDIT)
      return configedit(self)
    else if(stage == CALIB) 
      return configcalib(self)
    else if(stage == IMAGE)
      return configimage(self)
    else
      return fatal(PARMERR, 'Invalid stage')
  }

  const self.run := function(stage, config){
    if(stage == FILL)
      return its.run_filler(config)
    else if(stage == EDIT)
      return its.run_edit(config) 
    else if(stage == CALIB)
      return its.run_calib(config)
    else if(stage == IMAGE)
      return its.run_image(config)
    else
      return fatal(PARMERR, 'Invalid stage')
  }

  const self.run_auto := function(stage){
     config := self.load_config(stage)
     config.load_meta()
     config.calc()
     config.show_config()
     config.determine_logic()
     self.run(stage, config)
#     config.save()
  }

  const self.run_ws := function(stage, ws){
     ok := its.check_working_ws(ws.outdir)
     if(is_fail(ok)) report_error_ws(self)
 
     config := self.load_config(stage)
     if(is_fail(config)) report_error_ws(self)

     ok := config.update_config(ws)
     if(is_fail(ok)) report_error_ws(self)

     ok := config.load_meta()
     if(is_fail(ok)) report_error_ws(self)

     ok := config.calc()
     if(is_fail(ok)) report_error_ws(self)

     ok := its.check_obs_type(config, stage)
     if(is_fail(ok)) report_error_ws(self)

     ok := config.determine_logic()
     if(is_fail(ok)) report_error_ws(self)
  
     ok := self.run(stage, config)
     if(is_fail(ok)) report_error_ws(self)

     ok := config.save()
     if(is_fail(ok)) report_error_ws(self)
  }

  const self.run_ui := function(stage){
     config := self.load_config(stage)
     if(is_fail(config)) report_error_ui(self)

     ok := config.load_meta()
     if(is_fail(ok)) report_error_ui(self)

     ok := config.calc()
     if(is_fail(ok)) report_error_ui(self)

     ok := config.edit()
     if(is_fail(ok)) report_error_ui(self)

     ok := config.calc()
     if(is_fail(ok)) report_error_ui(self)       

     ok := config.determine_logic()
     if(is_fail(ok)) report_error_ui(self)

     ok := self.run(stage, config)
     if(is_fail(ok)) report_error_ui(self)

     ok := config.save()
     if(is_fail(ok)) report_error_ui(self)
  }

  const self.runautopl := function(){
    for(stage in FILL:IMAGE){
      ok := self.run_auto(stage)
      if(is_fail(ok)) fail
      self.setlaststage(stage)
    }
    return T
  }

  const self.choose_stage := function(){
    return its.choose_stage()
  }

  const self.done := function(){
    stages := ['']
    stages[FILL] := 'Filling'
    stages[EDIT] := 'Editing'
    stages[CALIB] := 'Calibration'
    stages[IMAGE] := 'Imaging'

    fclose(its.pidfile)

    ok := its.save_log()
    if(is_fail(ok)) fail

    if(its.laststage)
      printf('The last stage you completed successfully was %s\n', stages[its.laststage])
    else{
      printf('-----------------------------------------------\n')
      printf('ERROR: You have not done any data reduction.\n')
      printf('-----------------------------------------------\n')
    }
    exit
  }

# constructor

  ok := its.init_pipeline()
  if(is_fail(ok)) fail
  return T
}






