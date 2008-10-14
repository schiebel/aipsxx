#-----------------------------------------------------------------------------
# pkswriter.g: Controller for the Parkes multibeam data writer.
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
# $Id: pkswriter.g,v 19.9 2006/07/13 06:35:38 mcalabre Exp $
#-----------------------------------------------------------------------------
# -------------------------------------------------------------------- <USAGE>
# Handler for the Parkes multibeam data writer.
#
# NOTE: Direct MS2 output is only supported in the full version of livedata
# (i.e. not in the distributed 'pks' version).
#
# Arguments:
#    config            string   'DEFAULTS', 'GENERAL', 'CONTINUUM', 'GASS',
#                               'HIPASS', 'HVC', 'METHANOL', 'ZOA', 'MOPRA',
#                               or 'AUDS'.
#    client_dir        string   Directory containing client executable.  May
#                               be blank to use PATH.
#    format            string   Output format, now only 'SDFITS'; 'MS2' is no
#                               longer handled.
#    directory         string   Output directory.
#    file              string   Output file, without extension.
#    beams             bool[13] Mask of beams present in data.
#    IFs               bool[16] Mask of IFs   present in data; maximum two,
#                               each with the same number of channels and
#                               polarizations.
#    npols             int      Number of polarizations in input data.
#    nchans            int      Number of spectral channels in input data.
#    xpol              bool     Cross-polarization data present?
#
# Received events:
#    close()             Close the output file.
#    delete()            Close and delete the output file.
#    hidegui()           Make the GUI invisible.
#    init(record)        Initialize the writer client; parameter values may
#                        optionally be specified.
#    lock()              Disable parameter entry.
#    printparms()        Print parameters for the writer client.
#    printvalid()        Print parameter validation rules.
#    setconfig(string)   Set configuration to 'DEFAULTS', 'GENERAL',
#                        'CONTINUUM', 'GASS', 'HIPASS', 'HVC', 'METHANOL',
#                        'ZOA', 'MOPRA', or 'AUDS'.
#    setparm(record)     Set parameter values for the writer client
#    showgui(agent)      Create the GUI or make it visible if it already
#                        exists.  The parent frame may be specified.
#    terminate()         Close down.
#    unlock()            Enable parameter entry.
#    write(record)       Write out a data record.
#
# Sent events:
#    closed()            The output file has been closed.
#    deleted()           The output file has been closed and deleted.
#    done()              Agent has terminated.
#    fail()              Writer client has died.
#    guiready()          GUI construction complete.
#    init_error()        Client initialization error.
#    initialized()       Client initialization complete.
#    log(record)         Log message.
#    write_complete()    Data has been written.
#    write_error()       Client write error.
# -------------------------------------------------------------------- <USAGE>
#-----------------------------------------------------------------------------

pragma include once

include 'pkslib.g'

const pkswriter := subsequence(config     = 'GENERAL',
                               client_dir = '',
                               format     = 'SDFITS',
                               directory  = '.',
                               file       = 'livedata',
                               beams      = [F,F,F,F,F,F,F,F,F,F,F,F,F],
                               IFs        = [F,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F],
                               npols      = 0,
                               nchans     = 0,
                               xpol       = F) : [reflect=T]
{
  # Our identity.
  self.name := 'writer'

  for (j in system.path.include) {
    self.file := spaste(j, '/pkswriter.g')
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
    format     = [string  = [default = 'SDFITS',
                             valid   = "SDFITS"]],
    directory  = [string  = [default = '.',
                             invalid = '']],
    file       = [string  = [default = 'livedata',
                             invalid = '']],
    beams      = [boolean = [default = [F,F,F,F,F,F,F,F,F,F,F,F,F]]],
    IFs        = [boolean = [default = [F,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F]]],
    npols      = [integer = [default = 0,
                             minimum = 1,
                             maximum = 2]],
    nchans     = [integer = [default = 0,
                             minimum = 1,
                             maximum = 256*1024]],
    xpol       = [boolean = [default = F]]]

  if (!streq(field_names(pchek), field_names(parameters()))) {
    print spaste(self.file, ': internal inconsistency - pchek field names.')
  }

  # Version information maintained by RCS.
  wrk := [=]
  wrk.RCSid    := "$Revision: 19.9 $$Date: 2006/07/13 06:35:38 $"
  wrk.version  := spaste(wrk.RCSid[2], ', ', wrk.RCSid[4])
  wrk.lastexit := './livedata.lastexit/pkswriter.lastexit'

  # Work variables.
  wrk.delete := F
  wrk.locked := F

  # GUI widgets.
  gui := [f1 = F]

  #---------------------------------------------------------------------------
  # Local function definitions.
  #---------------------------------------------------------------------------
  local helpmsg, sethelp, set := [=], setparm, showgui

  #------------------------------------------------------------------ helpmsg

  # Write a widget help message.

  const helpmsg := function(msg='')
  {
    if (is_agent(gui.helpmsg)) gui.helpmsg->text(msg)
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

  # setparm() updates parameter values.
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

  #------------------------------------------------------------------ set.file

  # Set the output file name.

  const set.file := function(value)
  {
    wider parms

    parms.file := spaste(value, '.', to_lower(parms.format))
  }

  #---------------------------------------------------------------- set.format

  # Set the output file format

  const set.format := function(value)
  {
    wider parms

    parms.format := value
    setparm([file = parms.file])
  }

  #------------------------------------------------------------------- showgui

  # Build a graphical user interface for the writer client.
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
      gui.f1 := frame(title='Parkes multibeam writer', side='top',
                      expand='both')

      if (is_fail(gui.f1)) {
        print '\n\nWindow creation failed - check that the DISPLAY',
              'environment variable is set\nsensibly and that you have done',
              '\'xhost +\' as necessary.\n'
        gui.f1 := F
        return
      }

      gui.f1.top := T
    }

    gui.helpmsg := F
    if (is_record(parent) && has_field(parent, 'helpmsg')) {
      gui.helpmsg := parent.helpmsg
    }
    gui.dohelp := is_agent(gui.helpmsg) || gui.helpmsg

    #=========================================================================

    gui.f11 := frame(gui.f1, side='left', relief='ridge', expand='x')
    gui.title.ex := button(gui.f11, 'MULTIBEAM WRITER', relief='flat',
                           borderwidth=0, pady=1, foreground='#0000a0')
    sethelp(gui.title.ex, spaste('Control panel (v', wrk.version,
      ') for the multibeam writer client; PRESS FOR USAGE!'))

    whenever
      gui.title.ex->press do
        explain(self.file, 'USAGE')

    # Output file format
    gui.f111 := frame(gui.f11, side='right', borderwidth=0)
    gui.format.bn := button(gui.f111, type='menu', width=10, relief='groove',
                            pady=1)
    sethelp(gui.format.bn, 'Output file format.')

    gui.format1.bn := button(gui.format.bn, 'SDFITS', value='SDFITS')

    whenever
      gui.format1.bn->press do
        setparm([format = $value])

    gui.format.la := label(gui.f111, 'Output format', pady=0)

    #=========================================================================
    # Widget help messages.
    if (gui.dohelp) {
      if (!is_agent(gui.helpmsg)) {
        gui.f12 := frame(gui.f1, relief='ridge')
        gui.helpmsg := label(gui.f12, '', font='courier', width=1, fill='x',
                             borderwidth=0)
        sethelp(gui.helpmsg, 'Widget help messages.')
      }
    }


    # Lock parameter entry?  (Must precede showparm.)
    if (wrk.locked) gui.f1->disable()

    # Initialize widgets.
    showparm(gui, parms)

    tk_release()

    self->guiready()
  }

  #---------------------------------------------------------------------------
  # Events that we respond to.
  #---------------------------------------------------------------------------

  # Set parameter values.
  whenever
    self->setparm do
      if (!wrk.locked) setparm($value)

  # Set parameter set.
  whenever
    self->setconfig do
      setparm([config = $value])

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

  # Disable parameter entry.
  whenever
    self->lock do
      ldr.locked := T

  # Enable parameter entry.
  whenever
    self->unlock do
      ldr.locked := F

  # Initialize the writer.
  whenever
    self->init do {
      setparm($value)
      wrk.client->init(parms)
    }

  # Write out a block of data.
  whenever
    self->write do
      wrk.client->write($value)

  # Close the output file.
  whenever
    self->close do {
      wrk.delete := F
      wrk.client->close()
    }

  # Delete the output file.
  whenever
    self->delete do {
      # Signal pending deletion.
      wrk.delete := T
      wrk.client->close()
    }

  # Create or expose the GUI.
  whenever
    self->showgui do
      showgui($value)

  # Hide the GUI.
  whenever
    self->hidegui do
      if (is_agent(gui.f1)) {
        gui.f1->unmap()
      }

  # Close down.
  whenever
    self->terminate do {
      store(parms, wrk.lastexit)

      deactivate whenever_stmts(wrk.client).stmt

      deactivate wrk.whenevers
      self->done()
      wrk  := F
      self := F
    }

  wrk.whenevers := whenever_stmts(self).stmt

  #---------------------------------------------------------------------------
  # Initialize.
  #---------------------------------------------------------------------------

  # Set parameters.
  args := [config     = 'GENERAL',
           client_dir = client_dir,
           format     = format,
           directory  = directory,
           file       = file,
           beams      = beams,
           IFs        = IFs,
           npols      = npols,
           nchans     = nchans,
           xpol       = xpol]

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

  #------------------------------------------------------------- writer client

  if (parms.client_dir == '') {
    wrk.client := client('pkswriter')
  } else {
    wrk.client := client(spaste(parms.client_dir, '/pkswriter'))
  }
  wrk.client.name := 'pkswriter'

  # Pass events through.
  whenever
    wrk.client->* do {
      if ($name == 'closed' && wrk.delete) {
        # File deletion is implemented here synchronously.
        shell(spaste('rm -rf ', parms.directory, '/', parms.file))
        self->log([location = 'writer',
                   message  = 'Output file deleted.',
                   priority = 'BOLD'])
        self->deleted()
        wrk.delete := F

      } else {
        self->[$name]($value)
      }
    }
}
