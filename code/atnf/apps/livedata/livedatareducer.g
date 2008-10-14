#-----------------------------------------------------------------------------
# livedatareducer.g: Controller for Multibeam data reduction.
#-----------------------------------------------------------------------------
# Copyright (C) 1996-2006
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
# $Id: livedatareducer.g,v 19.17 2006/07/13 06:33:06 mcalabre Exp $
#-----------------------------------------------------------------------------
# -------------------------------------------------------------------- <USAGE>
# Controller and optional GUI for Multibeam single-dish data reduction.  It
# directs and regulates the data flow between the following six clients:
#
#    Reader ->
#              Bandpass calibrator
#                                  -> Monitor
#                                  -> Statistics
#                                  -> Writer
#                                                  -> Gridder
#
# where the flow of data is from left to right.  All clients other than the
# reader may be disabled or short-circuited, i.e. any line(s) of the above may
# be deleted other than the first.  The gridder is dependent on the writer
# since it processes its output file.
#
# The gridder may remain active even after the writer has been disabled since
# it is fed via a special purpose queue.  The gridder may run remotely on
# another machine.
#
# Arguments:
#    config            string   'DEFAULTS', 'GENERAL', 'CONTINUUM', 'GASS',
#                               'HIPASS', 'HVC', 'METHANOL', 'ZOA', 'MOPRA',
#                               or 'AUDS'.
#    client_dir        string   Directory containing client executables.  May
#                               be blank to use PATH.
#    reader            boolean  Enable reader by default?  Always true.
#    bandpass          boolean  Enable bandpass calibration by default?
#    monitor           boolean  Enable data display by default?
#    stats             boolean  Enable statistics calculator by default?
#    writer            boolean  Enable writer by default?
#    gridder           boolean  Enable gridder by default?
#    gridhost          string   Host on which to run the gridder.
#    gridqueue         string[] Default list of files queued to the gridder.
#    gridgrp           int      File grouping factor for the gridder.
#    read_dir          string   Directory containing input file.
#    read_file         string   Input file.
#    read_retry        int      Number of times the MBFITS reader should retry
#                               reading the input file after it encounters an
#                               EOF.
#    write_dir         string   Directory containing output file.
#    write_file        string   Output file.
#
# Received events:
#    continue()          Resume processing after a pause.
#    debug(bool)         Debug mode, don't time out waiting for clients.
#    hidegui()           Make the GUI invisible.
#    lock()              Disable parameter entry.
#    pause()             Pause processing.
#    printparms()        Print parameter values.
#    printvalid()        Print parameter validation rules.
#    setconfig(string)   Set configuration to 'DEFAULTS', 'GENERAL',
#                        'CONTINUUM', 'GASS',  'HIPASS', 'HVC', 'METHANOL',
#                        'ZOA', 'MOPRA', or 'AUDS'.
#    setparm(record)     Set parameter values.
#    showgui(agent,agent)
#                        Create the GUI or make it visible if it already
#                        exists.  Parent frames for the writer and other GUIs
#                        may be specified.
#    start(record)       Start processing.  Parameter values may optionally be
#                        specified.
#    stop()              Stop processing this input file now.
#    terminate()         Close down.
#    unlock()            Enable parameter entry.
#
# Sent events:
#    done()              Agent has terminated.
#    fail(string)        One of the data reduction clients has failed.
#    finished()          Processing has finished.
#    guiready()          GUI construction complete.
# -------------------------------------------------------------------- <USAGE>
#-----------------------------------------------------------------------------

pragma include once

include 'pkslib.g'
include 'pksreader.g'
include 'pksbandpass.g'
include 'pksmonitor.g'
include 'pksstats.g'
include 'pkswriter.g'
include 'gridzilla.g'

const reducer := subsequence(config       = 'GENERAL',
                             client_dir   = '',
                             reader       = T,
                             bandpass     = F,
                             monitor      = F,
                             stats        = F,
                             writer       = F,
                             gridder      = F,
                             gridhost     = 'localhost',
                             gridqueue    = "",
                             gridgrp      = 1,
                             read_dir     = '.',
                             read_file    = 'unspecified',
                             read_retry   = 0,
                             write_dir    = '.',
                             write_file   = '') : [reflect=T]
{
  # Our identity.
  self.name := 'reducer'

  for (j in system.path.include) {
    self.file := spaste(j, '/livedatareducer.g')
    if (len(stat(self.file))) break
  }

  self.busy := F

  # Clients - will be redefined when invoked.
  self.reader   := [busy=F, msg='inactive', nrec=0]
  self.bandpass := [busy=F, msg='inactive', nrec=0]
  self.monitor  := [busy=F, msg='inactive', nrec=0]
  self.stats    := [busy=F, msg='inactive', nrec=0]
  self.writer   := [busy=F, msg='inactive', nrec=0]
  self.gridder  := [busy=F, msg='inactive', nrec=0]

  # Parameter values.
  parms := [=]

  # Parameter value checking.
  pchek := [
    config     = [string  = [default = 'GENERAL',
                             valid   = "DEFAULTS GENERAL CONTINUUM GASS \
                                        HIPASS HVC METHANOL ZOA MOPRA AUDS"]],
    client_dir = [string  = [default = '']],
    reader     = [boolean = [default = T,
                             valid   = T]],
    bandpass   = [boolean = [default = F]],
    monitor    = [boolean = [default = F]],
    stats      = [boolean = [default = F]],
    writer     = [boolean = [default = F]],
    gridder    = [boolean = [default = F]],
    gridhost   = [string  = [default = 'localhost',
                             invalid = '']],
    gridqueue  = [string  = [default = ""]],
    gridgrp    = [integer = [default = 1,
                             minimum = 1]],
    read_dir   = [string  = [default = '.',
                             invalid = '']],
    read_file  = [string  = [default = 'unspecified',
                             invalid = '']],
    read_retry = [integer = [default = 0,
                             minimum = 0]],
    write_dir  = [string  = [default = '.']],
    write_file = [string  = [default = '']]]

  if (!streq(field_names(pchek), field_names(parameters()))) {
    print spaste(self.file, ': internal inconsistency - pchek field names.')
  }

  # Version information maintained by RCS.
  wrk := [=]
  wrk.RCSid    := "$Revision: 19.17 $$Date: 2006/07/13 06:33:06 $"
  wrk.version  := spaste(wrk.RCSid[2], ', ', wrk.RCSid[4])
  wrk.lastexit := './livedata.lastexit/livedatareducer.lastexit'

  # Work variables.
  wrk.beams     := [F,F,F,F,F,F,F,F,F,F,F,F,F]
  wrk.IFs       := [F,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F]
  wrk.npols     := 0
  wrk.nchans    := 0
  wrk.reffreq   := 0.0
  wrk.bandwidth := 0.0
  wrk.lastutc   := 0.0

  wrk.debug     := F
  wrk.failed    := F
  wrk.gridup    := F
  wrk.ignore    := F
  wrk.inits     := [F,F,F,F]
  wrk.interrupt := F
  wrk.locked    := F
  wrk.logfile   := shell("date +'livedata-%Y%m%d.log'")
  wrk.logger    := pkslogger(title='Livedata logger', file=wrk.logfile, utc=F,
                             reuse=F, share=T)
  wrk.pause     := F
  wrk.resume    := ''
  wrk.stats     := F

  # GUI widgets.
  gui := [f1 = F]

  #---------------------------------------------------------------------------
  # Local function definitions.
  #---------------------------------------------------------------------------
  local alldone, failure, finish, gridq, helpmsg, interrupt, readnext,
        regulate, set := [=], sethelp, setparm, showgui, status

  #------------------------------------------------------------------- alldone

  # Check whether all clients are idle.

  const alldone := function()
  {
    for (cliname in "reader bandpass monitor stats writer") {
      if (parms[cliname] && self[cliname].msg != 'IDLE') {
        status(paste('Waiting for', cliname, 'to finish',
               to_lower(self[cliname].msg)))
        return F
      }
    }

    return T
  }

  #------------------------------------------------------------------- failure

  # Operations to be undertaken when a client fails.

  const failure := function(cliname, msg='')
  {
    wider wrk

    if (wrk.failed) return
    wrk.failed := T
    wrk.interrupt := T

    # Orderly shutdown.
    print cliname, 'client failed', msg
    interrupt(failure=T)
    regulate(cliname, busy=F, msg='Failed')
    status(cliname, 'failed')

    # Send a distress signal.
    sos := paste(cliname, 'client failed')
    if (msg != '') sos := spaste(sos, '\n', msg)
    self->fail(sos)
  }

  #-------------------------------------------------------------------- finish

  # Do process completion operations.

  const finish := function(msg='Processing completed.', priority='NORMAL')
  {
    wider self

    if (is_record(msg)) {
      wrk.logger->log(msg)
      status(msg.message)
    } else {
      wrk.logger->log([location = 'reducer',
                       message  = msg,
                       priority = priority])
      status(msg)
    }

    self.reader.nrec   := 0
    self.bandpass.nrec := 0
    self.monitor.nrec  := 0
    self.stats.nrec    := 0
    self.writer.nrec   := 0

    regulate('reader', busy=F)
    if (parms.bandpass) regulate('bandpass', busy=F)
    if (parms.monitor)  regulate('monitor',  busy=F)
    if (parms.stats)    regulate('stats',    busy=F)
    if (parms.writer)   regulate('writer',   busy=F)

    self->finished(parms.write_file)
    if (!wrk.failed) self->unlock()
    self.busy := F
  }

  #--------------------------------------------------------------------- gridq

  # Process the next job on the gridder queue.

  const gridq := function()
  {
    wider self

    # Has the gridder client been activated?
    if (!is_agent(self.gridder)) return

    # Is the gridder client busy?
    if (self.gridder.busy) return

    # Are there enough files in the gridder queue?
    qlen := length(parms.gridqueue)
    if (qlen < 1) return

    if (parms.config == 'HIPASS' && parms.gridgrp > 1) {
      if (qlen == 1) return

      # Check that the fields are close together.
      ngrid := 1
      dec1  := parms.gridqueue[1] ~ s|.*?(-?\d\d)_\d+[a-e]\.sdfits|$1|
      scan1 := as_integer(parms.gridqueue[1] ~ s|.*_(\d+)[a-e]\.sdfits|$1|)
      for (j in 2:min(parms.gridgrp, qlen)) {
        dec  := parms.gridqueue[j] ~ s|.*?(-?\d\d)_\d+[a-e]\.sdfits|$1|
        scan := as_integer(parms.gridqueue[j] ~ s|.*_(\d+)[a-e]\.sdfits|$1|)
        if (dec != dec1 || abs(scan - scan1) > 7) break
        ngrid := j
      }

      if (ngrid == j && parms.gridgrp < qlen) return

    } else {
      if (qlen < parms.gridgrp) return
      ngrid := parms.gridgrp
    }

    if (is_agent(gui.f1)) {
      # Update gridder host from GUI.
      setparm([gridhost = gui.gridhost.en->get()])
    }

    # Resolve relative directory specification.
    write_dir := shell('cd', parms.write_dir, '&& pwd')

    # Process the job at the head of the queue.
    self.gridder->go([client_host=parms.gridhost,
                      files=parms.gridqueue[1:ngrid],
                      directories=write_dir,
                      selection=[1:ngrid],
                      p_FITSfilename=parms.gridqueue[1] ~ s|\.[^.]*$||])

    self.gridder.busy := T

    if (is_agent(gui.f1)) {
      gui.gridder.sv->text(paste('Processing on', parms.gridhost))
      gui.gridder.sv->foreground('#000000')
    }

    # Remove the job from the queue.
    if (qlen > ngrid) {
      setparm([gridqueue = parms.gridqueue[(ngrid+1):qlen]])
    } else {
      setparm([gridqueue = ""])
    }
  }

  #------------------------------------------------------------------ helpmsg

  # Write a widget help message.

  const helpmsg := function(msg='')
  {
    if (is_agent(gui.helpmsg)) gui.helpmsg->text(msg)
  }

  #----------------------------------------------------------------- interrupt

  # Interrupt processing.

  const interrupt := function(failed=F)
  {
    wider wrk
    wrk.interrupt := T

    # Wait for reader and bandpass to finish their scheduled jobs.
    if (wrk.ignore || self.reader.busy || self.bandpass.busy) {
       status('Stopping...')
       return
    }

    # Close input file.
    regulate('reader', busy=T, msg='Closing')
    self.reader->close()

    # Wait for the bandpass, monitor and stats clients.
    if (parms.bandpass) regulate('bandpass', busy=T, msg='Stopping')
    if (parms.monitor)  regulate('monitor',  busy=T, msg='Stopping')
    if (parms.stats)    regulate('stats',    busy=T, msg='Stopping')

    # Close and delete the output file.
    if (parms.writer) {
      status('Deleting output file')
      regulate('writer', busy=T, msg='Deleting')
      self.writer->delete()

      setparm([write_file = ''])
    }

    # Don't return if a client failed.
    if (!failed) finish('Processing interrupted', 'WARN')
  }

  #------------------------------------------------------------------ readnext

  # readnext() reads the next integration.

  const readnext := function()
  {
    wider wrk

    # Pause processing?
    if (wrk.pause) {
      # Choke the source.
      status('Paused')
      wrk.resume := 'reader'
    } else {
      regulate('reader', busy=T, msg='Reading')
      self.reader->read()
    }
  }

  #------------------------------------------------------------------ regulate

  # regulate() controls the flow of data between clients.  If necessary, it
  # waits for a client to complete an outstanding request.  It also sets the
  # client status indicators.

  const regulate := function(cliname, busy=T, msg='')
  {
    wider self, wrk

    nrec := as_string(self[cliname].nrec)

    if (busy) {
      # Wait up to 10s for the client to become idle.
      delay_count := 0
      while (T) {
        if (!self[cliname].busy && delay_count) {
          # Deregister an interest.
          wrk.delay_timer.listeners -:= 1

          if (wrk.delay_timer.listeners == 0) {
            # Stop the timer (to preserve system resources).
            wrk.delay_timer->stop()
          }

          status('Streaming')

          break
        }

        if (delay_count == 0) {
          if (wrk.delay_timer.listeners == 0) {
            # Wind up the timer.
            wrk.delay_timer->interval(0.02)
          }

          # Register an interest.
          wrk.delay_timer.listeners +:= 1

          status('Waiting for', cliname)
        }

        # Executing this await at least once in the for-loop allows other
        # events to interrupt.
        await wrk.delay_timer->ready

        delay_count +:= 1
        if (delay_count > 500 && !wrk.debug) {
          break
        }
      }

      if (self[cliname].busy) {
        # Uncomment for debug output.
        # print 'Timeout waiting for', cliname

        status('Timeout waiting for', cliname)
      }

      if (msg == '') msg := 'BUSY'

    } else {
      if (msg == '') {
        if (parms[cliname]) {
          msg := 'IDLE'
        } else {
          if (is_agent(self[cliname])) {
            msg := 'disabled'
          } else {
            msg := 'inactive'
          }
        }

        nrec := ''
      }
    }

    # Record status for client.
    self[cliname].busy := busy
    self[cliname].msg  := msg

    # Uncomment for debug output.
    # print cliname, busy, msg

    # Reflect state in GUI.
    if (is_agent(gui.f1)) {
      gui[cliname].sv->text(msg)
      gui[cliname].cv->text(nrec)

      if (busy) {
        gui[cliname].sv->foreground('#b03060')
      } else {
        if (msg == 'disabled') {
          gui[cliname].sv->foreground('#a3a3a3')
        } else {
          gui[cliname].sv->foreground('#000000')
        }
      }
    }
  }

  #------------------------------------------------------------------ sethelp

  # Set up the help message for a widget.

  const sethelp := function(ref widget, msg='')
  {
    if (!gui.dohelp) return

    widget.helpmsg := msg

    widget->bind('<Enter>', 'Enter')
    widget->bind('<Leave>', 'Leave')

    whenever
      widget->Enter do
        helpmsg(widget.helpmsg)

    whenever
      widget->Leave do
        helpmsg('')
  }

  #------------------------------------------------------------------- setparm

  # setparm() updates parameter values, also updating any associated widget(s)
  # using showparm() if the GUI is active.
  #
  # Given:
  #    value      record   Each field name, item, identifies the parameter as
  #
  #                           parms[item]
  #
  #                        The field values are the new parameter settings.

  const setparm := function(value)
  {
    wider parms

    # Do parameter validation.
    value := validate(pchek, parms, value)

    if (len(parms) == 0) {
      # Initialize parms.
      parms := value
    }

    for (item in field_names(value)) {
      if (has_field(set, item)) {
        # Invoke specialized update procedure.
        set[item](value[item])

      } else {
        # Update the parameter value.
        parms[item] := value[item]
      }

      rec := [=]
      rec[item] := parms[item]
      showparm(gui, rec)
    }
  }

  #-------------------------------------------------------------- set.bandpass

  # Invoke, enable/disable the bandpass calibration client.

  const set.bandpass := function(value)
  {
    wider parms, self, wrk

    if (self.busy) return

    parms.bandpass := value

    if (parms.bandpass && !is_agent(self.bandpass)) {
      self.bandpass := pksbandpass(config     = parms.config,
                                   client_dir = parms.client_dir)
      self.bandpass.busy := F
      self.bandpass.msg  := ''
      self.bandpass.nrec := 0
      self.bandpass.buffering := F

      # Bandpass client initialized.
      whenever
        self.bandpass->initialized do {
          self.bandpass.buffering := T
          regulate('bandpass', busy=F, msg='Initialized')
          wrk.inits[1] := T
          if (all(wrk.inits)) readnext()
        }

      # Request for more data.
      whenever
        self.bandpass->need_more_data do {
          regulate('bandpass', busy=F, msg='Waiting for data')

          # Interrupt processing?
          if (wrk.interrupt) interrupt()

          # Get the next chunk of data.
          readnext()
        }

      # Store and display corrected data.
      whenever
        self.bandpass->corrected_data,
        self.bandpass->flushed_data do {
          self.bandpass.buffering := F

          self.bandpass.nrec +:= len($value)
          regulate('bandpass', busy=F, msg='Waiting')

          if (wrk.interrupt) {
            interrupt()

          } else {
            if (parms.monitor) {
              # Send the data to the display client.
              regulate('monitor', busy=T, msg='Displaying')
              self.monitor->newdata($value)
              wrk.lastutc := $value[1][1].TIME
            }

            if (parms.stats) {
              # Send the data to the stats client.
              regulate('stats', busy=T, msg='Accumulating')
              self.stats->accumulate($value)
            }

            if (parms.writer) {
              # Send the data to the writer client.
              regulate('writer', busy=T, msg='Writing')
              self.writer->write($value)
            }

            if ($name == 'corrected_data') {
              # Get the next chunk of data.
              readnext()

            } else if ($name == 'flushed_data') {
              # Pause processing?
              if (wrk.pause) {
                # Choke the flush stream.
                status('Paused')
                wrk.resume := 'bandpass'
              } else {
                regulate('bandpass', busy=T, msg='Flushing buffer')
                self.bandpass->flush()
              }
            }
          }
        }

      # Client has finished processing the last batch.
      whenever
        self.bandpass->finished do {
          regulate('bandpass', busy=F, msg='IDLE')

          self->windup()
          if (alldone()) finish()
        }

      # Client message logging.
      whenever
        self.bandpass->log do
          wrk.logger->log($value)

      # Bandpass calibration failure.
      whenever
        self.bandpass->fail do
          failure('bandpass')
    }

    regulate('bandpass', busy=F)
  }

  #---------------------------------------------------------------- set.config

  # Set processing configuration.

  const set.config := function(value)
  {
    wider parms

    if (value == 'DEFAULTS') {
      parms.config := 'GENERAL'

      for (parm in field_names(pchek)) {
        if (parm == 'config') continue

        # Don't start or stop clients.
        if (any(parm == "reader bandpass monitor stats \
                         writer gridder")) continue

        args[parm] := pchek[parm][1].default
      }
      setparm(args)

    } else {
      parms.config := value
    }

    if (is_agent(self.reader))   self.reader->setconfig(value)
    if (is_agent(self.bandpass)) self.bandpass->setconfig(value)
    if (is_agent(self.monitor))  self.monitor->setconfig(value)
    if (is_agent(self.writer))   self.writer->setconfig(value)
  }

  #--------------------------------------------------------------- set.gridder

  # Enable/disable the gridder client.

  const set.gridder := function(value)
  {
    wider parms, self

    parms.gridder := value

    if (parms.gridder && !is_agent(self.gridder)) {
      # Resolve relative directory specification.
      write_dir := shell('cd', parms.write_dir, '&& pwd')

      # Start the gridder client.
      if (is_agent(gui.f1)) setparm([gridhost = gui.gridhost.en->get()])

      self.gridder := gridzilla(client_dir=parms.client_dir,
                                client_host=parms.gridhost,
                                remote=T,
                                autosize=T,
                                directories=write_dir,
                                write_dir=write_dir,
                                p_FITSfilename='livedata')

      whenever
        self.gridder->finished do {
          self.gridder.busy := F
          if (is_agent(gui.f1)) gui.gridder.sv->text('IDLE')
          gridq()
        }

      self.gridder.busy := F
      self.gridder.msg  := ''
      self.gridder.nrec := 0
      self.gridder->setconfig('GENERAL')
    }
  }

  #--------------------------------------------------------------- set.gridgrp

  # Set the file grouping factor for the gridder client.

  const set.gridgrp := function(value)
  {
    wider parms

    if (value < 1 && parms.config == 'HIPASS') {
      parms.gridgrp := 3
    } else {
      parms.gridgrp := value
    }

    gridq()
  }

  #-------------------------------------------------------------- set.gridhost

  # Set the host on which the gridder client is to run.

  const set.gridhost := function(value)
  {
    wider parms

    if (value == 'localhost') {
      parms.gridhost := system.host ~ s|\..*||
    } else {
      parms.gridhost := value
    }

  }

  #--------------------------------------------------------------- set.monitor

  # Invoke, enable/disable the monitor client.

  const set.monitor := function(value)
  {
    wider parms, self, wrk

    if (self.busy) return

    parms.monitor := value

    if (parms.monitor && !is_agent(self.monitor)) {
      # Invoke the data display client.
      self.monitor := pksmonitor(config     = parms.config,
                                 client_dir = parms.client_dir)
      self.monitor.busy := F
      self.monitor.msg  := ''
      self.monitor.nrec := 0

      # Monitor client initialized.
      whenever
        self.monitor->initProcessed do {
          regulate('monitor', busy=F, msg='Initialized')
          wrk.inits[2] := T
          if (all(wrk.inits)) readnext()
        }

      # Display has been updated.
      whenever
        self.monitor->newdataProcessed do {
          self.monitor.nrec +:= $value
          regulate('monitor', busy=F, msg='Waiting')
        }

      # No more data.
      whenever
        self->windup do {
          if (parms.monitor) {
            # Flush buffers.
            regulate('monitor', busy=T, msg='Flushing')
            self.monitor->flush()
          }
        }

      # Display has been flushed.
      whenever
        self.monitor->flushProcessed do {
          regulate('monitor', busy=F, msg='IDLE')
          if (alldone()) finish()
        }

      # Message logging.
      whenever
        self.monitor->log do
          wrk.logger->log($value)

      # Monitor client failure.
      whenever
        self.monitor->fail do
          failure('monitor')

      # Display client 1 failure.
      whenever
        self.monitor->fail1 do
          failure('monitor', '(Display client 1 died)')

      # Display client 2 failure.
      whenever
        self.monitor->fail2 do
          failure('monitor', '(Display client 2 died)')
    }

    regulate('monitor', busy=F)
  }

  #------------------------------------------------------------ set.read_retry

  # Set the maximum number of retries for the reader client.

  const set.read_retry := function(value)
  {
    wider parms

    parms.read_retry := value

    self.reader->setparm([retry = parms.read_retry])
  }

  #---------------------------------------------------------------- set.reader

  # The pksreader client reads data from an MBFITS or SDFITS file or aips++
  # measurementset (v2).

  const set.reader := function(value)
  {
    wider parms, self, wrk

    if (self.busy) return

    parms.reader := T

    if (parms.reader && !is_agent(self.reader)) {
      self.reader := pksreader(config     = parms.config,
                               client_dir = parms.client_dir)
      self.reader.busy := F
      self.reader.msg  := ''
      self.reader.nrec := 0

      # Reader returns the mask of beams in the input data on initialization.
      whenever
        self.reader->initialized do {
          regulate('reader', busy=F, msg='Initialized')

          # Check that we have something.
          if (sum($value.beams) == 0 ||
              sum($value.IFs) == 0   ||
              $value.npols  == 0     ||
              $value.nchans == 0) {
            finish('No data - job cancelled!', 'WARN')

          } else {
            # The downstream clients must complete their initialization before
            # the first read can be initiated.
            wrk.inits := [T,T,T,T]

            # Disable parameter entry.
            self->lock()

            if (parms.bandpass) {
              wrk.inits[1] := F
              regulate('bandpass', busy=T, msg='Initializing')
              self.bandpass->init([nbeams = sum($value.beams),
                                   nifs   = sum($value.IFs),
                                   npols  = $value.npols,
                                   nchans = $value.nchans])
            }

            if (parms.monitor) {
              # Do we need to reinitialize the monitor?
              if (parms.read_retry == 0             ||
                  $value.beams     != wrk.beams     ||
                  $value.IFs       != wrk.IFs       ||
                  $value.npols     != wrk.npols     ||
                  $value.nchans    != wrk.nchans    ||
                  $value.reffreq   != wrk.reffreq   ||
                  $value.bandwidth != wrk.bandwidth ||
                  $value.utc       <  wrk.lastutc) {
                wrk.inits[2] := F
                regulate('monitor', busy=T, msg='Initializing')
                self.monitor->init([beams  = $value.beams,
                                    IFs    = $value.IFs,
                                    npols  = $value.npols,
                                    nchans = $value.nchans])

                wrk.beams     := $value.beams
                wrk.IFs       := $value.IFs
                wrk.npols     := $value.npols
                wrk.nchans    := $value.nchans
                wrk.reffreq   := $value.reffreq
                wrk.bandwidth := $value.bandwidth
              }

              wrk.lastutc := $value.utc
            }

            if (parms.stats) {
              wrk.inits[3] := F
              regulate('stats', busy=T, msg='Initializing')
              self.stats->init([directory = parms.write_dir,
                                file = parms.write_file ~ s|\.[^.]*$||])
            }

            if (parms.writer) {
              wrk.inits[4] := F
              regulate('writer', busy=T, msg='Initializing')
              self.writer->init([directory = parms.write_dir,
                                 file   = parms.write_file,
                                 beams  = $value.beams,
                                 IFs    = $value.IFs,
                                 npols  = $value.npols,
                                 nchans = $value.nchans,
                                 xpol   = $value.xpol])
            } else {
              setparm([write_file = ''])
            }

            status('Streaming')

            if (all(wrk.inits)) readnext()
          }
        }

      # Reader initialization failure.
      whenever
        self.reader->init_error do {
          regulate('reader', busy=F, msg='Failed')
          setparm([write_file = ''])
          finish($value)
        }


      # Pass data from the reader to the next client in the chain.
      whenever
        self.reader->data do {
          self.reader.nrec +:= len($value)
          regulate('reader', busy=F, msg='Waiting')

          if (wrk.interrupt) {
             interrupt()

          } else {
            # Defer interruptions that may be triggered elsewhere.
            wrk.ignore := T

            if (parms.bandpass) {
              if (self.bandpass.buffering) {
                regulate('bandpass', busy=T, msg='Buffering data')
              } else {
                regulate('bandpass', busy=T, msg='Correcting data')
              }
              self.bandpass->correct($value)

            } else {
              if (parms.monitor) {
                # Send the data to the display client.
                regulate('monitor', busy=T, msg='Displaying')
                self.monitor->newdata($value)
                wrk.lastutc := $value[1][1].TIME
              }

              if (parms.stats) {
                # Send the data to the stats client.
                regulate('stats', busy=T, msg='Accumulating')
                self.stats->accumulate($value)
              }

              if (parms.writer) {
                # Send the data to the writer client.
                regulate('writer', busy=T, msg='Writing')
                self.writer->write($value)
              }

              # Get the next chunk of data.
              readnext()
            }

            wrk.ignore := F
          }
        }

      # End-of-file encountered on the input file.
      whenever
        self.reader->eof,
        self.reader->read_error do {
          # Close the input file.
          if ($name == 'eof') {
            regulate('reader', busy=F, msg='EOF')
          } else {
            regulate('reader', busy=F, msg='READ ERROR')
          }

          regulate('reader', busy=T, msg='Closing')
          self.reader->close()

          if (parms.bandpass) {
            # Tell the bandpass client to start flushing its buffers.
            regulate('bandpass', busy=T, msg='Flushing buffer')
            self.bandpass->flush()
          }
        }

      # Input file closed.
      whenever
        self.reader->closed do {
          regulate('reader', busy=F, msg='IDLE')

          if (!parms.bandpass && !wrk.interrupt) {
            # Finished with this file.
            self->windup()
            if (alldone()) finish()
          }
        }

      # Message logging.
      whenever
        self.reader->log do
          wrk.logger->log($value)

      # Read failure.
      whenever
        self.reader->fail do
          failure('reader')
    }

    regulate('reader', busy=F)
  }

  #----------------------------------------------------------------- set.stats

  # Invoke, enable/disable the statistics client.

  const set.stats := function(value)
  {
    wider parms, self, wrk

    if (self.busy || self.stats.busy) return

    parms.stats := value

    if (parms.stats && !is_agent(self.stats)) {
      # Invoke the client that computes statistics.
      self.stats := pksstats(client_dir=parms.client_dir)
      self.stats.busy := F
      self.stats.msg  := ''
      self.stats.nrec := 0

      # Stats client initialized.
      whenever
        self.stats->initialized do {
          regulate('stats', busy=F, msg='Initialized')
          wrk.inits[3] := T
          if (all(wrk.inits)) readnext()
        }

      # Data has been accumulated.
      whenever
        self.stats->accumulated do {
          self.stats.nrec +:= $value
          regulate('stats', busy=F, msg='Waiting')
        }

      # No more data.
      whenever
        self->windup do {
          if (parms.stats) {
            # Compute statistics.
            regulate('stats', busy=T, msg='Computing')
            self.stats->stats()
          }
        }

      # Stats client finished.
      whenever
        self.stats->finished do {
          regulate('stats', busy=F, msg='IDLE')
          if (alldone()) finish()
        }

      # Message logging.
      whenever
        self.stats->log do
          wrk.logger->log($value)

      # Stats client failure.
      whenever
        self.stats->fail do
          failure('stats')
    }

    regulate('stats', busy=F)
  }

  #---------------------------------------------------------------- set.writer

  # Invoke, enable/disable the writer client.

  const set.writer := function(value)
  {
    wider wrk, parms, self

    if (self.busy) return

    parms.writer := value

    if (parms.writer && !is_agent(self.writer)) {
      self.writer := pkswriter(config     = parms.config,
                               client_dir = parms.client_dir)
      self.writer.busy := F
      self.writer.msg  := ''
      self.writer.nrec := 0

      # Writer client initialized.
      whenever
        self.writer->initialized do {
          regulate('writer', busy=F, msg='Initialized')
          wrk.inits[4] := T
          if (all(wrk.inits)) readnext()
        }

      # Writer initialization failure.
      whenever
        self.writer->init_error do {
          status($value)
          regulate('writer', busy=F, msg='Failed')
          finish('Writer initialization failed.', 'ERROR')
        }

      # Record has been written.
      whenever
        self.writer->write_complete do {
          self.writer.nrec +:= $value
          regulate('writer', busy=F, msg='Waiting')
        }

      # Record has been written.
      whenever
        self.writer->write_error do {
          status($value)
          regulate('writer', busy=F, msg='Error')
        }

      # No more data.
      whenever
        self->windup do {
          if (parms.writer) {
            # Close the output file.
            regulate('writer', busy=T, msg='Closing')
            self.writer->close()
          }
        }

      # Output file closed.
      whenever
        self.writer->closed do {
          regulate('writer', busy=F, msg='IDLE')

          if (parms.gridder && !wrk.interrupt) {
            if (!any(parms.gridqueue == parms.write_file)) {
              # Add file to the gridder queue.
              setparm([gridqueue = [parms.gridqueue, parms.write_file]])

              # Start the queue if necessary.
              gridq()
            }
          }

          # Finished with this file.
          if (alldone()) finish()
        }


      # Message logging.
      whenever
        self.writer->log do
          wrk.logger->log($value)

      # Writer client failure.
      whenever
        self.writer->fail do
          failure('writer', msg='(Disk full or output deleted?)')
    }

    regulate('writer', busy=F)
  }

  #------------------------------------------------------------------- showgui

  # Build a graphical user interface for the livedata data reduction clients.
  # If the parent frame is not specified a separate window will be created.

  const showgui := function(parent=F)
  {
    wider gui, wrk

    if (is_agent(gui.f1)) {
      # Show the GUI and bring it to the top of the window stack.
      gui.f1->map()
      if (gui.f1.top) gui.f1->raise()
      return
    }

    # Check whether DISPLAY is defined.
    if (!has_field(environ, 'DISPLAY')) {
       print 'DISPLAY environment variable is not set, can\'t construct GUI!'
       return
    }

    # Parent window.
    tk_hold()
    if (is_agent(parent)) {
      gui.f1 := parent
      gui.f1->side('top')
      gui.f1->expand('both')
      gui.f1->map()
      gui.f1.top := F

    } else {
      # Create a top-level frame.
      gui.f1 := frame(title='Multibeam data processing', expand='both')

      if (is_fail(gui.f1)) {
        print '\n\nWindow creation failed - check that the DISPLAY',
              'environment variable is set\nsensibly and that you have done',
              '\'xhost +\' as necessary.\n'
        gui.f1 := F
        return
      }

      gui.f1.top := T
    }

    # Screen height, in pixels.
    gui.screenhgt := as_integer(split(shell('xwininfo -root|grep Height'))[2])
    if (gui.screenhgt < 700) gui.screenhgt := 9999

    gui.helpmsg := F
    if (is_record(parent) && has_field(parent, 'helpmsg')) {
      gui.helpmsg := parent.helpmsg
    }
    gui.dohelp := is_agent(gui.helpmsg) || gui.helpmsg

    #=========================================================================
    gui.f11  := frame(gui.f1, relief='ridge', borderwidth=4, expand='x')
    gui.f111 := frame(gui.f11, side='left', borderwidth=0)
    gui.title.ex := button(gui.f111, 'DATA REDUCTION CONTROL', relief='flat',
                           borderwidth=0, foreground='#0000a0')
    sethelp(gui.title.ex, spaste('Control panel (v', wrk.version,
            ') for the data reduction pathway; PRESS FOR USAGE!'))

    whenever
      gui.title.ex->press do
        explain(self.file, 'USAGE')

    gui.read_file.sv := label(gui.f111, '', justify='center', width=60)
    sethelp(gui.read_file.sv, 'The file currently being processed.')

    gui.f1111  := frame(gui.f111, side='right', borderwidth=0)
    gui.f11111 := frame(gui.f1111, relief='ridge', expand='none')
    gui.gridctl.bn := button(gui.f11111, 'Gridder...', width=18,
                             relief='groove')
    sethelp(gui.gridctl.bn,
            'Expose or hide the control panel for an asynchronous gridder.')

    whenever
      gui.gridctl.bn->press do {
        if (wrk.gridup) {
          gui.gridctl.f1->unmap()
          wrk.gridup := F
        } else {
          gui.gridctl.f1->raise()
          gui.gridctl.f1->map()
          wrk.gridup := T
        }
      }

#   Should be a pop-up frame but they're buggy.
    gui.gridctl.f1 := frame(title='Gridder pipeline control')
#    gui.gridctl.f1 := frame(tlead=gui.gridctl.bn, tpos='se', relief='ridge')

    gui.gridctl.f11  := frame(gui.gridctl.f1, side='left', relief='ridge')
    gui.gridctl.f111 := frame(gui.gridctl.f11, borderwidth=0)
    gui.gridder.bn   := button(gui.gridctl.f111, 'Gridding', width=14,
                               type='check')
    sethelp(gui.gridder.bn, 'Enable or disable an asynchronous gridder to \
                             process the output files.')

    whenever
      gui.gridder.bn->press do
        setparm([gridder = gui.gridder.bn->state()])

    gui.gridder.sv := label(gui.gridctl.f111, '')

    gui.gridctl.f112 := frame(gui.gridctl.f11, borderwidth=0)
    gui.gridctl.f1121 := frame(gui.gridctl.f112, side='left', borderwidth=0)
    gui.gridhost.la := label(gui.gridctl.f1121, 'Host')
    gui.gridhost.en := entry(gui.gridctl.f1121, width=12)
    sethelp(gui.gridhost.en, 'Host on which to run the gridder client.')

    whenever
      gui.gridhost.en->return do {
        setparm([gridhost = $value])
        if (is_agent(self.gridder)) {
          self.gridder->setparm([client_host = parms.gridhost])
        }
      }

    gui.gridctl.f1122 := frame(gui.gridctl.f112, side='left', borderwidth=0)

    gui.gridgrp.la := label(gui.gridctl.f1122, 'Grouping')
    gui.gridgrp.bn := button(gui.gridctl.f1122, '', type='menu', width=7,
                             relief='groove')
    sethelp(gui.gridgrp.bn, 'Number of files to collect before gridding.')

    gui.gridgrp1.bn := button(gui.gridgrp.bn, '1', value=1)
    gui.gridgrp2.bn := button(gui.gridgrp.bn, '2', value=2)
    gui.gridgrp3.bn := button(gui.gridgrp.bn, '3', value=3)
    gui.gridgrp4.bn := button(gui.gridgrp.bn, '4', value=4)
    gui.gridgrp5.bn := button(gui.gridgrp.bn, '5', value=5)
    gui.gridgrp6.bn := button(gui.gridgrp.bn, '6', value=6)

    whenever
      gui.gridgrp1.bn->press,
      gui.gridgrp2.bn->press,
      gui.gridgrp3.bn->press,
      gui.gridgrp4.bn->press,
      gui.gridgrp5.bn->press,
      gui.gridgrp6.bn->press do
        setparm([gridgrp = $value])

    gui.gridctl.f12  := frame(gui.gridctl.f1, relief='ridge')
    gui.gridctl.f121 := frame(gui.gridctl.f12, side='left', borderwidth=0)
    gui.gridqueue.lb := listbox(gui.gridctl.f121, width=36, height=7,
                                mode='extended', foreground='#ffff00',
                                background='#000000')
    sethelp(gui.gridqueue.lb, 'Files currently in the gridder queue.')

    whenever
      gui.gridqueue.lb->yscroll do
        gui.gridqueue.sb->view($value)

    gui.gridqueue.sb := scrollbar(gui.gridctl.f121, width=8)

    whenever
      gui.gridqueue.sb->scroll do
        gui.gridqueue.lb->view($value)

    gui.gridctl.f122 := frame(gui.gridctl.f12, side='left', borderwidth=0)
    gui.griddel.bn   := button(gui.gridctl.f122, 'Clear selection')
    sethelp(gui.griddel.bn,
            'Remove the selected file(s) from the gridder queue.')

    whenever
      gui.griddel.bn->press do {
        curr_sel := gui.gridqueue.lb->selection()
        if (length(curr_sel) > 0) {
          gridqueue := parms.gridqueue
          for (j in gui.gridqueue.lb->get(curr_sel)) {
            gridqueue := gridqueue[gridqueue != j]
          }

          setparm([gridqueue = gridqueue])
        }
      }

    gui.gridctl.f1221 := frame(gui.gridctl.f122, side='right', borderwidth=0)
    gui.gridclr.bn := button(gui.gridctl.f1221, 'Clear queue')
    sethelp(gui.gridclr.bn, 'Remove all files from the gridder queue.')

    whenever
      gui.gridclr.bn->press do
        setparm([gridqueue = ""])


    # Reader button (does nothing).
    gui.f112  := frame(gui.f11, side='left', borderwidth=0)
    gui.f1121 := frame(gui.f112, relief='ridge')
    gui.reader.bn := button(gui.f1121, '   Reader   ', fill='x', pady=2)

    gui.f11211 := frame(gui.f1121, side='left', borderwidth=0, expand='x')
    gui.reader.sv := label(gui.f11211, '', width=1, fill='x')
    sethelp(gui.reader.sv, 'Current status of the Multibeam reader client.')

    gui.reader.cv := label(gui.f11211, '', width=3, relief='ridge')
    sethelp(gui.reader.cv, 'Number of records read (one per IF per \
      integration cycle).')

    # Bandpass calibrator selection button.
    gui.f1122 := frame(gui.f112, relief='ridge')
    gui.bandpass.bn := button(gui.f1122, 'Bandpass calibration', type='check',
                              fill='x')
    sethelp(gui.bandpass.bn, 'Enable or disable the bandpass calibration \
                              client.')

    whenever
      gui.bandpass.bn->press do
        setparm([bandpass = gui.bandpass.bn->state()])

    gui.f11221 := frame(gui.f1122, side='left', borderwidth=0, expand='x')
    gui.bandpass.sv := label(gui.f11221, '', width=1, fill='x')
    sethelp(gui.bandpass.sv, 'Current status of the bandpass calibration \
                              client.')

    gui.bandpass.cv := label(gui.f11221, '', width=3, relief='ridge')
    sethelp(gui.bandpass.cv, 'Number of records calibrated (one per IF per \
      integration cycle).')

    # Monitor calibrated data selection button.
    gui.f1123 := frame(gui.f112, relief='ridge')
    gui.monitor.bn := button(gui.f1123, 'Monitor output', type='check',
                             fill='x')
    sethelp(gui.monitor.bn, 'Enable or disable the data monitor client.')

    whenever
      gui.monitor.bn->press do
        setparm([monitor = gui.monitor.bn->state()])

    gui.f11231 := frame(gui.f1123, side='left', borderwidth=0, expand='x')
    gui.monitor.sv := label(gui.f11231, '', width=1, fill='x')
    sethelp(gui.monitor.sv, 'Current status of the data monitor client.')

    gui.monitor.cv := label(gui.f11231, '', width=3, relief='ridge')
    sethelp(gui.monitor.cv, 'Number of records displayed (one per IF per \
      integration cycle).')

    # Compute statistics selection button.
    gui.f1124 := frame(gui.f112, relief='ridge')
    gui.stats.bn := button(gui.f1124, 'Statistics', type='check', fill='x')
    sethelp(gui.stats.bn, 'Enable or disable the statistics calculator \
      client.')

    whenever
      gui.stats.bn->press do
        setparm([stats = gui.stats.bn->state()])

    gui.f11241 := frame(gui.f1124, side='left', borderwidth=0, expand='x')
    gui.stats.sv := label(gui.f11241, '', width=1, fill='x')
    sethelp(gui.stats.sv, 'Current status of the statistics calculator \
      client.')

    gui.stats.cv := label(gui.f11241, '', width=3, relief='ridge')
    sethelp(gui.stats.cv, 'Number of records accumulated (one per IF per \
      integration cycle).')

    # Write data selection button.
    gui.f1125 := frame(gui.f112, relief='ridge')
    gui.writer.bn := button(gui.f1125, 'Write data', type='check', fill='x')
    sethelp(gui.writer.bn, 'Enable or disable the Multibeam writer client.')

    whenever
      gui.writer.bn->press do
        setparm([writer = gui.writer.bn->state()])

    gui.f11251 := frame(gui.f1125, side='left', borderwidth=0, expand='x')
    gui.writer.sv := label(gui.f11251, '', width=1, fill='x')
    sethelp(gui.writer.sv, 'Current status of the Multibeam writer client.')

    gui.writer.cv := label(gui.f11251, '', width=3, relief='ridge')
    sethelp(gui.writer.cv, 'Number of records written (one per IF per \
      integration cycle).')


    # Status panel.
    gui.f113 := frame(gui.f11, borderwidth=0)
    gui.status.sv := label(gui.f113, '', justify='center', fill='x',
                           relief='ridge')
    sethelp(gui.status.sv, 'Current status of the data reduction pathway.')

    #=========================================================================

    # Frame for the logger.
    if (gui.screenhgt < 950) {
      # Small screen - put the logger in a separate window.
      gui.f12 := frame(title='Livedata logger', borderwidth=0, expand='both')
    } else {
      gui.f12 := frame(gui.f1, borderwidth=0, expand='both')
    }
    wrk.logger->showgui(gui.f12)

    #=========================================================================

    # Frames for the client GUIs.
    gui.f13  := frame(gui.f1, side='left', borderwidth=0, expand='x')
    gui.f131 := frame(gui.f13, borderwidth=0)
    gui.f132 := frame(gui.f13, borderwidth=0)
    gui.f133 := frame(gui.f13, borderwidth=0)
    gui.reader.fr   := frame(gui.f131, borderwidth=0)
    gui.bandpass.fr := frame(gui.f132, borderwidth=0)
    gui.monitor.fr  := frame(gui.f133, borderwidth=0)

    # The writer GUI is separate.
    if (has_field(parent, 'writer')) {
      gui.writer.fr := parent.writer
    } else {
      gui.writer.fr := F
    }

    if (!parms.bandpass) gui.f132->unmap()
    if (!parms.monitor)  gui.f133->unmap()

    #=========================================================================
    # Help messages.
    if (gui.dohelp) {
      if (!is_agent(gui.helpmsg)) {
        gui.f14 := frame(gui.f1, relief='ridge', borderwidth=4, expand='x')
        gui.helpmsg := label(gui.f14, '', font='courier', width=1, fill='x',
                             borderwidth=0)
        sethelp(gui.helpmsg, 'Widget help messages.')
      }

      # Widget help for client GUIs.
      gui.reader.fr.helpmsg   := gui.helpmsg
      gui.bandpass.fr.helpmsg := gui.helpmsg
      gui.monitor.fr.helpmsg  := gui.helpmsg
      if (is_agent(gui.writer.fr)) gui.writer.fr.helpmsg := gui.helpmsg
    }


    # Gridder popup frame.
    gui.gridctl.f1->unmap()

    # Activate client GUIs.
    self.reader->showgui(gui.reader.fr)


    # Initialize widgets.
    showparm(gui, parms)

    # Initialize client status values.
    for (cliname in "reader bandpass monitor stats writer") {
      if (self[cliname].busy) {
        gui[cliname].sv->text(self[cliname].msg)
        gui[cliname].sv->foreground('#b03060')
      } else {
        gui[cliname].sv->text(self[cliname].msg)
        if (self[cliname].msg == 'disabled') {
          gui[cliname].sv->foreground('#a3a3a3')
        } else {
          gui[cliname].sv->foreground('#000000')
        }
      }
    }

    tk_release()

    self->guiready()
  }

  #--------------------------------------------------------- gui.bandpass.show

  # Show bandpass calibration client status and show/hide its control panel.

  const gui.bandpass.show := function()
  {
    gui.bandpass.bn->state(parms.bandpass)

    tk_hold()

    if (parms.bandpass) {
      if (parms.monitor) gui.f133->unmap()
      gui.f132->map()
      if (parms.monitor) gui.f133->map()
      self.bandpass->showgui(gui.bandpass.fr)
    } else {
      gui.f132->unmap()
    }

    tk_release()
  }

  #---------------------------------------------------------- gui.gridder.show

  # Show gridder client status and show/hide its control panel.

  const gui.gridder.show := function()
  {
    if (parms.gridder) {
      self.gridder->showgui()
      gui.gridder.sv->text('IDLE')
      gui.gridder.sv->foreground('#000000')
    } else {
      if (is_agent(self.gridder)) self.gridder->hidegui()
      gui.gridder.sv->text('disabled')
      gui.gridder.sv->foreground('#a3a3a3')
    }

    gui.gridder.bn->state(parms.gridder)
  }

  #---------------------------------------------------------- gui.monitor.show

  # Show monitor client status and show/hide its control panel.

  const gui.monitor.show := function()
  {
    gui.monitor.bn->state(parms.monitor)

    tk_hold()

    if (parms.monitor) {
      gui.f133->map()
      self.monitor->showgui(gui.monitor.fr)
    } else {
      gui.f133->unmap()
    }

    tk_release()
  }

  #------------------------------------------------------------ gui.stats.show

  # Show stats client status and show/hide its control panel.

  const gui.stats.show := function()
  {
    gui.stats.bn->state(parms.stats)

    if (parms.stats) {
      self.stats->showgui([helpmsg = gui.helpmsg])
    } else {
      if (is_agent(self.stats)) self.stats->hidegui()
    }
  }

  #----------------------------------------------------------- gui.writer.show

  # Show writer client status and show/hide its control panel.

  const gui.writer.show := function()
  {
    gui.writer.bn->state(parms.writer)

    tk_hold()

    if (parms.writer) {
      self.writer->showgui(gui.writer.fr)
    } else {
      if (is_agent(self.writer)) self.writer->hidegui()
    }

    tk_release()
  }

  #-------------------------------------------------------------------- status

  # Write an informative message regarding processing status.  The function
  # takes a variable number of string arguments.

  const status := function(...)
  {
    if (is_agent(gui.f1)) gui.status.sv->text(paste(...))
  }

  #---------------------------------------------------------------------------
  # Events that we respond to.
  #---------------------------------------------------------------------------

  # Continue after pause.
  whenever
    self->continue do {
      if (wrk.pause) {
        wrk.pause := F
        status('Continuing')

        if (wrk.resume == 'reader') {
          readnext()
        } else if (wrk.resume == 'bandpass') {
          regulate('bandpass', busy=T, msg='Flushing buffer')
          self.bandpass->flush()
        }

        wrk.resume := ''
      }
    }

  # Set debug mode.
  whenever
    self->debug do
      wrk.debug := $value

  # Hide the GUI.
  whenever
    self->hidegui do
      if (is_agent(gui.f1)) gui.f1->unmap()

  # Disable parameter entry.
  whenever
    self->lock do {
      if (!wrk.locked) {
        wrk.locked := T

        self.reader->lock()
        if (is_agent(self.bandpass)) self.bandpass->lock()
        if (is_agent(self.monitor))  self.monitor->lock()
        if (is_agent(self.stats))    self.stats->lock()
        if (is_agent(self.writer))   self.writer->lock()

        if (is_agent(gui.f1)) gui.f112->disable()
      }
    }

  # Pause the pipeline.
  whenever
    self->pause do {
      if (!wrk.pause && !wrk.interrupt) {
        status('Pausing')
        wrk.pause  := T
        wrk.resume := ''
      }
    }

  # Show parameter values.
  whenever
    self->printparms do {
      print ''
      printrecord(parms)
    }

  # Show parameter validation rules.
  whenever
    self->printvalid do {
      print ''
      printrecord(pchek, 'valid')
    }

  # Set parameter set.
  whenever
    self->setconfig do
      if (!wrk.locked) setparm([config = $value])

  # Set parameter values.
  whenever
    self->setparm do
      if (!wrk.locked) setparm($value)

  # Create or expose the GUI.
  whenever
    self->showgui do
      showgui($value)

  # Start the pipeline.
  whenever
    self->start do {
      wrk.interrupt := F
      wrk.pause := F

      self.reader.nrec   := 0
      self.bandpass.nrec := 0
      self.monitor.nrec  := 0
      self.stats.nrec    := 0
      self.writer.nrec   := 0

      setparm($value)

      wrk.logger->log([location = '', message = '', priority = 'NORMAL'])
      wrk.logger->log([location = 'reducer', message = 'Begin processing.',
                       priority = 'HIGHLIGHT'])

      # Check for output = input.
      if (parms.writer &&
          paste(parms.read_dir,  parms.read_file,  sep='/') ==
          paste(parms.write_dir, parms.write_file, sep='/')) {
        finish('Input = Output, job cancelled!', 'WARN')

      } else {
        # Initialize reader (it will respond with an "initialized" event).
        self.busy := T
        status('Initializing')
        regulate('reader', busy=T, msg='Initializing')
        self.reader->init([directory=parms.read_dir,
                           file=parms.read_file,
                           retry=parms.read_retry])
      }
    }

  # Request to stop now.
  whenever
    self->stop do {
      status('Stopping...')
      wrk.interrupt := T

      if (wrk.pause) self->continue()
    }

  # Close down.
  whenever
    self->terminate do {
      store(parms, wrk.lastexit)

      # Tell clients to shut down.
      for (cli in "reader bandpass monitor stats writer gridder") {
        if (is_agent(self[cli])) {
          self[cli]->terminate()
          deactivate whenever_stmts(self[cli]).stmt
          await self[cli]->done
        }
      }

      deactivate wrk.whenevers
      self->done()
      gui  := F
      wrk  := F
      self := F
    }

  # Enable parameter entry.
  whenever
    self->unlock do {
      if (wrk.locked) {
        self.reader->unlock()
        if (is_agent(self.bandpass)) self.bandpass->unlock()
        if (is_agent(self.monitor))  self.monitor->unlock()
        if (is_agent(self.stats))    self.stats->unlock()
        if (is_agent(self.writer))   self.writer->unlock()

        if (is_agent(gui.f1)) gui.f112->enable()

        wrk.locked := F
      }
    }

  wrk.whenevers := whenever_stmts(self).stmt

  #---------------------------------------------------------------------------
  # Initialize.
  #---------------------------------------------------------------------------

  # Set parameters.
  args := [config     = 'GENERAL',
           client_dir = client_dir,
           reader     = T,
           bandpass   = bandpass,
           monitor    = monitor,
           stats      = stats,
           writer     = writer,
           gridder    = gridder,
           gridhost   = gridhost,
           gridqueue  = gridqueue,
           gridgrp    = gridgrp,
           read_dir   = read_dir,
           read_file  = read_file,
           read_retry = read_retry,
           write_dir  = write_dir,
           write_file = write_file]

  if (!streq(field_names(args), field_names(pchek))) {
    print spaste(self.file, ': internal inconsistency - args field names.')
  }

  # Recover last exit state.
  if (len(stat(wrk.lastexit))) {
    last := read_value(wrk.lastexit)

    j := 0
    for (parm in field_names(pchek)) {
      j +:= 1

      # Don't override any non-defaulting arguments.
      if (has_field(args, parm) && has_field(last, parm)) {
        if (missing()[j]) {
          # Parameters not to recover:
          if (parm == 'client_dir') continue
          if (any(parm == "bandpass monitor stats writer gridder")) continue
          if (any(parm == "read_file read_retry write_file")) continue

          args[parm] := last[parm]

        } else {
          # Reset the default value for this parameter.
          pchek[parm][1].default := args[parm]
        }
      }
    }
  }

  setparm(args)

  # Apply parameter restrictions.
  if (config != 'GENERAL') setparm([config = config])

  # Delay timer client.
  wrk.delay_timer := client("timer")
  wrk.delay_timer.listeners := 0

  whenever
    wrk.delay_timer->ready do
      {}
}
