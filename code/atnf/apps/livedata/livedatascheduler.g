#-----------------------------------------------------------------------------
# livedatascheduler.g: Scheduler for Parkes multibeam data reduction.
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
# $Id: livedatascheduler.g,v 19.13 2006/05/18 08:09:51 mcalabre Exp $
#-----------------------------------------------------------------------------
# -------------------------------------------------------------------- <USAGE>
# Scheduler and optional GUI for realtime (live) and offline data reduction of
# Parkes multibeam data.  Realtime reduction differs from offline reduction in
# that files newly created by the correlator may be discovered automatically
# (auto-queued) and that several attempts are made to read files that may be
# incomplete.
#
# Arguments:
#    config            string   'DEFAULTS', 'GENERAL', 'CONTINUUM', 'GASS',
#                               'HIPASS', 'HVC', 'METHANOL', 'ZOA', 'MOPRA',
#                               or 'AUDS'.
#    client_dir        string   Directory containing client executables.  May
#                               be blank to use PATH.
#    read_dir          string   Default input directory.
#    read_mask         string   Wildcard specification(s) for input files.
#    read_retry        int      Number of times the reader should retry
#                               reading the input file after it encounters an
#                               EOF.
#    write_dir         string   Default output directory.
#    autoqueue         boolean  Automatically check for new files that may
#                               appear in the input directory and add them to
#                               the processing queue.
#    files             string[] Default list of input files.
#    queue             string[] Default list of queued files.
#    done              string[] Default list of output files.
#
# Received events:
#    continue()          Continue processing after a pause.
#    dequeue(string[])   Remove the specified files from the input queue.
#    enqueue(string[])   Add the specified files to the input queue.
#    hidegui()           Make the GUI invisible.
#    pause()             Pause processing.
#    printparms()        Print parameter values.
#    printvalid()        Print parameter validation rules.
#    setconfig(string)   Set configuration to 'DEFAULTS', 'GENERAL',
#                        'CONTINUUM', 'GASS',  'HIPASS', 'HVC', 'METHANOL',
#                        'ZOA', 'MOPRA', or 'AUDS'.
#    setparm(record)     Set parameter values.
#    showgui(agent)      Create the GUI or make it visible if it already
#                        exists.  The parent frame may be specified.
#    start(record)       Start processing.  Parameter values may optionally be
#                        specified.
#    stopafter(boolean)  Stop processing when this file is complete.
#    stopnow()           Stop processing this file now.
#    terminate()         Close down.
#    updatefiles()       Set the input file list from a wildcard listing of
#                        input directory.
#
# Sent events:
#    done()              Agent has terminated.
#    guiready()          GUI construction complete.
# -------------------------------------------------------------------- <USAGE>
#-----------------------------------------------------------------------------

pragma include once

include 'pkslib.g'
include 'livedatareducer.g'

const scheduler := subsequence(config     = 'GENERAL',
                               client_dir = '',
                               read_dir   = '.',
                               read_mask  = '*.hpf   *.mbf   *.rpf   \
                                             *.sdfits',
                               read_retry = 3,
                               write_dir  = '.',
                               autoqueue  = F,
                               files      = "",
                               queue      = "",
                               done       = "") : [reflect=T]
{
  # Our identity.
  self.name := 'scheduler'

  for (j in system.path.include) {
    self.file := spaste(j, '/livedatascheduler.g')
    if (len(stat(self.file))) break
  }

  # Parameter values.
  parms := [=]

  # Parameter value checking.
  pchek := [
    config     = [string  = [default = 'GENERAL',
                             valid   = "DEFAULTS GENERAL CONTINUUM GASS \
                                        HIPASS HVC METHANOL ZOA MOPRA AUDS"]],
    client_dir = [string  = [default = '']],
    read_dir   = [string  = [default = '.']],
    read_mask  = [string  = [default = '*.hpf *.mbf *.rpf']],
    read_retry = [integer = [default = 3,
                             minimum = 1,
                             maximum = 10]],
    write_dir  = [string  = [default = '.']],
    autoqueue  = [boolean = [default = F]],
    files      = [string  = [default = ""]],
    queue      = [string  = [default = ""]],
    done       = [string  = [default = ""]]]

  if (!streq(field_names(pchek), field_names(parameters()))) {
    print spaste(self.file, ': internal inconsistency - pchek field names.')
  }

  # Version information maintained by RCS.
  wrk := [=]
  wrk.RCSid    := "$Revision: 19.13 $$Date: 2006/05/18 08:09:51 $"
  wrk.version  := spaste(wrk.RCSid[2], ', ', wrk.RCSid[4])
  wrk.lastexit := './livedata.lastexit/livedatascheduler.lastexit'

  # Work variables.
  wrk.active       := F
  wrk.reconfigable := T
  wrk.enabled      := F
  wrk.read_file    := ''
  wrk.read_retry   := 0
  wrk.write_file   := ''
  wrk.write_ext    := [SDFITS = 'sdfits']

  # GUI widgets.
  gui := [f1 = F]

  #---------------------------------------------------------------------------
  # Local function definitions.
  #---------------------------------------------------------------------------
  local auto_queue, dirlist, helpmsg, readgui, set := [=], sethelp, setparm,
        showgui, start, updatefiles

  #---------------------------------------------------------------- auto_queue

  const auto_queue := function()
  {
    wider parms

    if (is_agent(gui.f1)) {
      # Flash the autoqueue button.
      gui.autoqueue.bn->background('#ffffff')
    }

    readgui()
    newlist := dirlist()

    for (j in ind(newlist)) {
      # Only consider new files.
      if (any(parms.files == newlist[j])) next

      # Avoid queueing the same file twice.
      if (any(parms.queue == newlist[j])) next

      # Add file to queue.
      parms.queue := [parms.queue, newlist[j]]
    }

    setparm([files = newlist, queue = parms.queue])

    if (is_agent(gui.f1)) {
      # Unflash the autoqueue button.
      gui.autoqueue.bn->background('#d9d9d9')
    }
  }

  #------------------------------------------------------------------- dirlist

  # Wildcard listing of files in the input directory.

  const dirlist := function()
  {
    readgui()
    return split(shell('cd', parms.read_dir, '&& ls -d', parms.read_mask,
                       '2>/dev/null'))
  }

  #------------------------------------------------------------------ helpmsg

  # Write a widget help message.

  const helpmsg := function(msg='')
  {
    if (is_agent(gui.helpmsg)) gui.helpmsg->text(msg)
  }

  #------------------------------------------------------------------- readgui

  # Read values from entry boxes.
  const readgui := function()
  {
    if (is_agent(gui.f1)) {
      setparm([read_dir  = gui.read_dir.en->get(),
               read_mask = gui.read_mask.en->get(),
               write_dir = gui.write_dir.en->get()])
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

  #------------------------------------------------------------- set.autoqueue

  # Enable or disable automatic queueing of files as they are created by the
  # correlator.

  const set.autoqueue := function(value)
  {
    wider parms, wrk

    parms.autoqueue := as_boolean(value)

    if (parms.autoqueue) {
      # Do it now then at 2min intervals.
      auto_queue()
      wrk.read_retry := parms.read_retry
      wrk.queue_timer->interval(120)
    } else {
      # Stop the queue timer.
      wrk.read_retry := 0
      wrk.queue_timer->stop()
    }

    if (has_field(self, 'reducer')) {
      # Propagate the retry value to the reducer.
      self.reducer->setparm([read_retry = wrk.read_retry])
    }
  }

  #---------------------------------------------------------------- set.config

  # Set parameters collectively for particular processing configurations.

  const set.config := function(value)
  {
    wider parms

    parms.config := value

    if (parms.config == 'DEFAULTS') {
      for (parm in field_names(pchek)) {
        args[parm] := pchek[parm][1].default
      }
      setparm(args)
      updatefiles()

    } else if (parms.config == 'AUDS') {
      setparm([read_mask = '*.fits'])
      updatefiles()

    } else if (parms.config == 'GASS') {
      setparm([read_mask = '*.mbf'])
      updatefiles()

    } else if (any(parms.config == "HIPASS ZOA")) {
      setparm([read_mask = '*.hpf'])
      updatefiles()

    } else if (parms.config == "HVC") {
      setparm([read_mask = '*.hpf *.mbf'])
      updatefiles()

    } else if (any(parms.config == "METHANOL MOPRA")) {
      setparm([read_mask = '*.rpf'])
      updatefiles()
    }

    if (has_field(self, 'reducer')) {
      self.reducer->setparm([config = value])
    }
  }

  #------------------------------------------------------------------- showgui

  # Build a graphical user interface for the bandpass calibration client.
  # If the parent frame is not specified a separate window will be created.

  const showgui := function(parent=F)
  {
    wider gui

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
      gui.f1 := frame(title='LiveData - Parkes Multibeam Data Reduction',
                      icon='livedata.xbm', expand='both')

      if (is_fail(gui.f1)) {
        print '\n\nWindow creation failed - check that the DISPLAY',
              'environment variable is set\nsensibly and that you have done',
              '\'xhost +\' as necessary.\n'
        gui.f1 := F
        return
      }

      gui.f1.top := F
    }

    gui.helpmsg := T
    if (is_record(parent) && has_field(parent, 'helpmsg')) {
      gui.helpmsg := parent.helpmsg
    }
    gui.dohelp := is_agent(gui.helpmsg) || gui.helpmsg

    #=========================================================================
    # Action panel.
    gui.f11  := frame(gui.f1, relief='ridge', borderwidth=4, expand='both')

    gui.f111 := frame(gui.f11, side='left', borderwidth=0, expand='x')

    # ATNF logo.
    gui.f1111 := frame(gui.f111, borderwidth=0, expand='none')
    gui.ATNF.bn := button(gui.f1111, bitmap='ATNF.xbm', padx=0, pady=0,
                          borderwidth=0, foreground='#00a0b3',
                          background='#ffffff', hlcolor='#ffffff')
    sethelp(gui.ATNF.bn, 'Australia Telescope National Facility')

    gui.f1112 := frame(gui.f111, relief='ridge', expand='x')
    gui.f11121 := frame(gui.f1112, side='left', borderwidth=0)
    gui.action.ex := button(gui.f11121, 'SCHEDULER', relief='flat',
                            borderwidth=0, foreground='#0000a0')
    sethelp(gui.action.ex, spaste('Control panel (v', wrk.version,
            ') for the data reduction scheduler; PRESS FOR USAGE!'))

    whenever
      gui.action.ex->press do
        explain(self.file, 'USAGE')

    # Buttons.
    gui.f11122  := frame(gui.f1112, side='left', borderwidth=0)

    # Configuration.
    gui.f111221 := frame(gui.f11122, side='left', borderwidth=0)
    gui.config.la := label(gui.f111221, 'Configuration', foreground='#b03060')
    sethelp(gui.config.la, 'Predefined processing configurations.')

    gui.config.bn := button(gui.f111221, type='menu', width=10,
                            relief='groove', disabled=!wrk.reconfigable)
    sethelp(gui.config.bn, 'Processing configuration currently selected \
                            (may be locked if set via LIVEDATA_MODE).')

    gui.config_0.bn := button(gui.config.bn,
                              'Factory defaults',
                              value='DEFAULTS')
    gui.config_1.bn := button(gui.config.bn,
                              'GENERAL - no restrictions',
                              value='GENERAL')
    gui.config_2.bn := button(gui.config.bn,
                              'CONTINUUM - set continuum parameters',
                              value='CONTINUUM')
    gui.config_3.bn := button(gui.config.bn,
                              'GASS - Parkes Galactic All Sky Survey',
                              value='GASS')
    gui.config_4.bn := button(gui.config.bn,
                              'HIPASS - HI Parkes All Sky Survey',
                              value='HIPASS')
    gui.config_5.bn := button(gui.config.bn,
                              'HVC - Parkes High Velocity Cloud survey',
                              value='HVC')
    gui.config_6.bn := button(gui.config.bn,
                              'METHANOL - Parkes Methanol survey',
                              value='METHANOL')
    gui.config_7.bn := button(gui.config.bn,
                              'ZOA - Parkes Zone Of Avoidance survey',
                              value='ZOA')
    gui.config_8.bn := button(gui.config.bn,
                              'MOPRA - Mopra on-the-fly mapping',
                              value='MOPRA')
    gui.config_9.bn := button(gui.config.bn,
                              'AUDS - Arecibo ALFA Ultra Deep Survey',
                              value='AUDS')

    whenever
      gui.config_0.bn->press,
      gui.config_1.bn->press,
      gui.config_2.bn->press,
      gui.config_3.bn->press,
      gui.config_4.bn->press,
      gui.config_5.bn->press,
      gui.config_6.bn->press,
      gui.config_7.bn->press,
      gui.config_8.bn->press,
      gui.config_9.bn->press do
        setparm([config = $value])

    # Spacer.
    gui.f1112211 := frame(gui.f111221, expand='none', height = 0, width=10,
                          borderwidth=0)

    # Start processing.
    gui.start.bn := button(gui.f111221, 'START', foreground='DarkGreen')
    sethelp(gui.start.bn, 'Start processing the queued files.')

    whenever
      gui.start.bn->press do
        self->start()

    # Pause/resume processing.
    gui.pause.bn := button(gui.f111221, 'Pause', type='check', disabled=T)
    sethelp(gui.pause.bn, 'Pause processing at the next opportunity.')

    whenever
      gui.pause.bn->press do
        if (gui.pause.bn->state()) {
          self->pause()
        } else {
          self->continue()
        }

    # Stop after this file is file is processed.
    gui.stopafter.bn := button(gui.f111221, 'Stop after this', type='check',
                               disabled=T)
    sethelp(gui.stopafter.bn, 'Stop processing when this file is finished.')

    whenever
      gui.stopafter.bn->press do
        self->stopafter(gui.stopafter.bn->state())

    # Stop now!
    gui.stopnow.bn := button(gui.f111221, 'STOP NOW', foreground='#b03060',
                             disabled=T)
    sethelp(gui.stopnow.bn, 'Stop processing now.')

    whenever
      gui.stopnow.bn->press do
        self->stopnow()

    # Exit.
    gui.f111222  := frame(gui.f11122, side='right', borderwidth=0)
    gui.exit.bn := button(gui.f111222, 'EXIT', foreground='#b03060')
    sethelp(gui.exit.bn, 'Exit from LiveData, killing any active clients.')

    whenever
      gui.exit.bn->press do
        self->terminate()

    # CSIRO logo.
    gui.f1113 := frame(gui.f111, borderwidth=0, expand='none')
    gui.CSIRO.bn := button(gui.f1113, bitmap='CSIRO.xbm', padx=0, pady=0,
                           borderwidth=0, foreground='#00a0b3',
                           background='#ffffff', hlcolor='#ffffff')
    sethelp(gui.CSIRO.bn, 'Commonwealth Scientific and Industrial Research \
      Organization, Australia')

    #=========================================================================
    # File panel.
    gui.f112  := frame(gui.f11, relief='ridge')

    # Column 1.
    gui.f1121  := frame(gui.f112, side='left', borderwidth=0, expand='x')
    gui.f11211 := frame(gui.f1121)

    # Input directory.
    gui.f112111 := frame(gui.f11211, side='left', borderwidth=0)
    gui.read_dir.la := label(gui.f112111, 'Read directory', width=13,
                             anchor='e')
    gui.read_dir.en := entry(gui.f112111, width=36, fill='both')
    sethelp(gui.read_dir.en, 'Directory where input files reside (set via \
                              LIVEDATA_READ_DIR).')

    whenever
      gui.read_dir.en->return do
        setparm([read_dir = $value])

    whenever
      gui.read_dir.en->return do {
        setparm([read_dir = $value])
        updatefiles()
      }

    # Input file mask.
    gui.f112112 := frame(gui.f11211, side='left', borderwidth=0)
    gui.read_mask.la := label(gui.f112112, 'File wildcard(s)', width=13,
                              anchor='e')
    gui.read_mask.en := entry(gui.f112112, width=36, fill='both')
    sethelp(gui.read_mask.en, 'Wildcard specification(s) for input files.')

    whenever
      gui.read_mask.en->return do {
        setparm([read_mask = $value])
        updatefiles()
      }


    # Column 2.
    gui.f11212 := frame(gui.f1121)

    # Output directory.
    gui.f112121 := frame(gui.f11212, side='left', height=40, borderwidth=0,
                         expand='x')
    gui.write_dir.la := label(gui.f112121, 'Write directory', width=13,
                              anchor='e', pady=3)
    gui.write_dir.en := entry(gui.f112121, width=36, fill='both')
    sethelp(gui.write_dir.en, 'Directory where output files will be placed \
                               (set via LIVEDATA_WRITE_DIR).')

    whenever
      gui.write_dir.en->return do
        setparm([write_dir = $value])

    # Space for the writer client GUI.
    gui.f112122 := frame(gui.f11212, height=24, borderwidth=0)

    # Input files ------------------------------------------------------------
    gui.f1122    := frame(gui.f112, side='left', borderwidth=0)
    gui.f11221   := frame(gui.f1122, relief='ridge')
    gui.f112211  := frame(gui.f11221, side='left', borderwidth=0)
    gui.files.la := label(gui.f112211, 'Raw files', foreground='#b03060')
    sethelp(gui.files.la, 'Input file selection panel.')

    # Spacer.
    gui.f1122111 := frame(gui.f112211, width=0, height=0, borderwidth=0)

    # Move the selected files into the processing queue.
    gui.enqueue.bn := button(gui.f112211, 'Queue selection')
    sethelp(gui.enqueue.bn, 'Append the selected files to the input queue.')

    whenever
      gui.enqueue.bn->press do {
        curr_sel := gui.files.lb->selection()
        if (length(curr_sel) > 0) {
          self->enqueue(gui.files.lb->get(curr_sel))

          # Clear selection.
          gui.files.lb->clear('start', 'end')
        }
      }

    # Rescan for files in the input directory.
    gui.updatefiles.bn := button(gui.f112211, 'Update')
    sethelp(gui.updatefiles.bn, 'Rescan the input directory for files \
                                 matching the wildcard specification.')

    whenever
      gui.updatefiles.bn->press do
        updatefiles()

    # List of input files.
    gui.f112212 := frame(gui.f11221, side='left', borderwidth=0)
    gui.files.lb := listbox(gui.f112212, width=36, height=6, mode='extended',
                            foreground='#000000', background='#00a0b3',
                            fill='both')
    sethelp(gui.files.lb, 'List of files in the input directory that match \
                           the input wildcard.')

    whenever
      gui.files.lb->yscroll do
        gui.files.sb->view($value)

    gui.files.sb := scrollbar(gui.f112212, width=8)

    whenever
      gui.files.sb->scroll do
        gui.files.lb->view($value)


    # Queued files -----------------------------------------------------------
    gui.f11222  := frame(gui.f1122, relief='ridge')
    gui.f112221 := frame(gui.f11222, side='left', borderwidth=0)
    gui.queue.la := label(gui.f112221, 'Queued files', foreground='#b03060')
    sethelp(gui.queue.la, 'Processing queue control panel.')

    # Spacer.
    gui.f1122211 := frame(gui.f112221, width=0, height=0, borderwidth=0)

    # Automatically queue files as they are written by the correlator.
    gui.autoqueue.bn := button(gui.f112221, 'Auto-Queue', type='check')
    sethelp(gui.autoqueue.bn, 'Check for new files in the input directory \
                               every 2min and add them to the input queue \
                               (realtime mode).')

    whenever
      gui.autoqueue.bn->press do
        setparm([autoqueue = gui.autoqueue.bn->state()])

    # Remove files from the processing queue.
    gui.dequeue.bn := button(gui.f112221, 'Dequeue')
    sethelp(gui.dequeue.bn, 'Remove the selected file(s) from the input \
                             queue.')

    whenever
      gui.dequeue.bn->press do {
        curr_sel := gui.queue.lb->selection()
        if (length(curr_sel) > 0) {
          self->dequeue(gui.queue.lb->get(curr_sel))
        }
      }

    # List of queued files.
    gui.f112222 := frame(gui.f11222, side='left', borderwidth=0)
    gui.queue.lb := listbox(gui.f112222, width=36, height=6, mode='extended',
                            foreground='#000000', background='#00a0b3',
                            fill='both')
    sethelp(gui.queue.lb, 'List of files queued for processing.')

    whenever
      gui.queue.lb->yscroll do
        gui.queue.sb->view($value)

    gui.queue.sb := scrollbar(gui.f112222, width=8)

    whenever
      gui.queue.sb->scroll do
        gui.queue.lb->view($value)


    # Processed files --------------------------------------------------------
    gui.f11223  := frame(gui.f1122, relief='ridge')
    gui.f112231 := frame(gui.f11223, side='left', borderwidth=0)

    gui.proc.la := label(gui.f112231, 'Processed files', foreground='#b03060')
    sethelp(gui.proc.la, 'Processed files panel.')

    gui.f1122311 := frame(gui.f112231, side='right', borderwidth=0)

    # Clear the list of processed files.
    gui.cleardone.bn := button(gui.f1122311, 'Clear')
    sethelp(gui.cleardone.bn, 'Clear the list of processed files.')

    whenever
      gui.cleardone.bn->press do
        setparm([done = ""])

    # List of processed files.
    gui.f112232 := frame(gui.f11223, side='left', borderwidth=0)
    gui.done.lb := listbox(gui.f112232, width=36, height=6, mode='extended',
                           foreground='#000000', background='#00a0b3',
                           fill='both')
    sethelp(gui.done.lb, 'List of files that have been processed.')

    whenever
      gui.done.lb->yscroll do
        gui.done.sb->view($value)

    gui.done.sb := scrollbar(gui.f112232, width=8)

    whenever
      gui.done.sb->scroll do
        gui.done.lb->view($value)


    #=========================================================================
    # Panel for reader, bandpass and monitor clients
    gui.f12 := frame(gui.f1, borderwidth=0, expand='both')

    # Writer client GUI.
    gui.f12.writer := frame(gui.f112122, borderwidth=0)
    gui.f12.writer->unmap()

    #=========================================================================
    # Help messages.
    if (gui.dohelp) {
      if (!is_agent(gui.helpmsg)) {
        gui.f13 := frame(gui.f1, relief='ridge', borderwidth=4, expand='x')
        gui.helpmsg := label(gui.f13, '', font='courier', width=1, fill='x',
                             borderwidth=0)
        sethelp(gui.helpmsg, 'Widget help messages.')
      }

      # Widget help for client GUIs.
      gui.f12.helpmsg := gui.helpmsg
    }


    # Initialize widgets.
    setparm(parms)
    tk_release()
  }

  #------------------------------------------------------------ gui.queue.show

  # Show the processing queue.

  const gui.queue.show := function()
  {
    gui.queue.lb->delete('start', 'end')
    if (len(parms.queue)) {
      gui.queue.lb->insert(parms.queue)
      gui.queue.lb->see('start')
    }
  }

  #--------------------------------------------------------------------- start

  # Initiate processing of the file at the head of the queue.

  const start := function()
  {
    wider parms, wrk

    readgui()
    if (parms.autoqueue) {
      auto_queue()
    }

    if (wrk.enabled && !wrk.active && length(parms.queue)) {
      wrk.read_file  := parms.queue[1]
      wrk.write_file := spaste(parms.queue[1] ~ s|\.[^.]*$||)

      # Dequeue the file.
      setparm([queue = parms.queue[parms.queue != parms.queue[1]]])

      if (!any(parms.config == "GASS METHANOL MOPRA AUDS")) {
        # Configurations that are not enforced.
        self.reducer->setconfig(parms.config)
      }

      wrk.active := T
      self.reducer->start(read_dir   = parms.read_dir,
                          read_file  = wrk.read_file,
                          read_retry = wrk.read_retry,
                          write_dir  = parms.write_dir,
                          write_file = wrk.write_file)

      if (is_agent(gui.f1)) {
        gui.config.bn->disabled(T)
        gui.start.bn->disabled(T)
        gui.pause.bn->disabled(F)
        gui.stopafter.bn->disabled(F)
        gui.stopnow.bn->disabled(F)
      }
    }
  }

  #--------------------------------------------------------------- updatefiles

  # Update the input file list.

  const updatefiles := function()
  {
    if (is_agent(gui.f1)) gui.f1->cursor('watch')
    setparm([files = dirlist()])
    if (is_agent(gui.f1)) gui.f1->cursor('')
  }

  #---------------------------------------------------------------------------
  # Events that we respond to.
  #---------------------------------------------------------------------------

  # Set parameter values.
  whenever
    self->setparm do
      setparm($value)

  # Set parameter set.
  whenever
    self->setconfig do
      setparm([config = $value])

  # Show parameter values.
  whenever
    self->printparms do {
      readgui()
      print ''
      printrecord(parms)
    }

  # Show parameter validation rules.
  whenever
    self->printvalid do {
      print ''
      printrecord(pchek, 'valid')
    }

  # Start processing.
  whenever
    self->start do {
      wrk.enabled := T
      start()
    }

  # Pause processing.
  whenever
    self->pause do
      self.reducer->pause()

  # Resume processing after a pause.
  whenever
    self->continue do
      self.reducer->continue()

  # Stop processing after this file is finished.
  whenever
    self->stopafter do
      if (is_boolean($value)) wrk.enabled := !$value

  # Stop immediately.
  whenever
    self->stopnow do {
      wrk.enabled := F

      if (is_agent(gui.f1)) {
        gui.pause.bn->disabled(T)
        gui.pause.bn->state(F)
        gui.stopafter.bn->disabled(T)
        gui.stopafter.bn->state(F)
      }

      if (wrk.active) {
        self.reducer->stop()
      } else {
        gui.config.bn->disabled(F)
        gui.start.bn->disabled(F)
        gui.stopnow.bn->disabled(T)
      }
    }

  # Add the specified files to the queue.
  whenever
    self->enqueue do {
      for (j in ind($value)) {
        # Don't queue the same file twice.
        if (any(parms.queue == $value[j])) next

        # Add file to queue.
        parms.queue := [parms.queue, $value[j]]
      }

      setparm([queue = parms.queue])

      start()
    }

  # Update the input file list.
  whenever
    self->updatefiles do
      updatefiles()

  # Remove the specified files from the queue.
  whenever
    self->dequeue do {
      for (j in ind($value)) {
        parms.queue := parms.queue[parms.queue != $value[j]]
      }

      setparm([queue = parms.queue])
    }

  # Create or expose the GUI.
  whenever
    self->showgui do {
      showgui($value)
      self.reducer->showgui(gui.f12)
    }

  # Hide the GUI.
  whenever
    self->hidegui do
      if (is_agent(gui.f1)) gui.f1->unmap()

  # Close down.
  whenever
    self->terminate do {
      readgui()
      store(parms, wrk.lastexit)

      self.reducer->terminate()
      deactivate whenever_stmts(self.reducer).stmt
      await self.reducer->done

      deactivate wrk.whenevers
      self->done()
      gui  := F
      wrk  := F
      self := F
    }

  wrk.whenevers := whenever_stmts(self).stmt

  #---------------------------------------------------------------------------
  # Initialize.
  #---------------------------------------------------------------------------

  # Timer controlling the automatic queueing of files.
  wrk.queue_timer := client('timer')

  whenever
    wrk.queue_timer->ready do {
      auto_queue()

      if (wrk.enabled && !wrk.active) {
        start()
      }
    }


  # Set parameters.
  args := [config     = 'GENERAL',
           client_dir = client_dir,
           read_dir   = read_dir,
           read_mask  = read_mask,
           read_retry = read_retry,
           write_dir  = write_dir,
           autoqueue  = autoqueue,
           files      = files,
           queue      = queue,
           done       = done]

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
          if (any(parm == "client_dir read_retry autoqueue done")) continue

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
  if (config != 'GENERAL') {
    # A specific configuration was specified at startup.
    setparm([config = config])

    # Disallow change.
    wrk.reconfigable := F
  }

  # Update the directory listing if not specified as a subsequence argument.
  wrk.pindx := pindx(pchek)
  if (missing()[wrk.pindx.files]) setparm([files = dirlist()])


  # Client that processes each file.
  self.reducer := reducer(config     = parms.config,
                          client_dir = parms.client_dir)

  # GUI construction complete.
  whenever
    self.reducer->guiready do
     self->guiready()

  # Reducer has finished processing this file.
  whenever
    self.reducer->finished do {
      wrk.active := F

      # Transfer file out.
      wrk.read_file := ''
      if ($value != '') {
        setparm([done = [parms.done[parms.done != $value], $value]])
      }

      # Process the next file.
      if (wrk.enabled && (length(parms.queue) || parms.autoqueue)) {
        start()
      } else {
        # Disable processing.
        wrk.enabled := F

        if (is_agent(gui.f1)) {
          gui.config.bn->disabled(F)
          gui.start.bn->disabled(F)
          gui.pause.bn->disabled(T)
          gui.pause.bn->state(F)
          gui.stopafter.bn->disabled(T)
          gui.stopafter.bn->state(F)
          gui.stopnow.bn->disabled(T)
        }
      }
    }

  # Reducer failed.
  whenever
    self.reducer->fail do {
      # Freeze up.
      deactivate whenever_stmts(self).stmt

      if (is_agent(gui.f1)) {
        # Disable the GUI.
        gui.f11->disable()
        self.reducer->lock()

        # Provide an escape route.
        gui.f2 := frame(title='LiveData', borderwidth=20, cursor='pirate',
                        background='#d00000')
        gui.abort.la := label(gui.f2, $value, justify='center',
                              background='#d00000')
        gui.abort.fr := frame(gui.f2, height=10, background='#d00000')
        gui.abort.bn := button(gui.f2, 'ABORT!', foreground='#ff0000')

        whenever
          gui.abort.bn->press do
            exit
      }
    }
}
