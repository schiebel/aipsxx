#-----------------------------------------------------------------------------
# pksreader.g: Controller for the Parkes multibeam data reader.
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
# $Id: pksreader.g,v 19.16 2006/07/13 06:39:06 mcalabre Exp $
#-----------------------------------------------------------------------------
# -------------------------------------------------------------------- <USAGE>
# Handler and optional GUI for the Parkes multibeam data reader.  The client
# reads a Parkes multibeam dataset and emits multibeam Glish records.  It will
# determine for itself whether the input is an MBFITS or SDFITS format file.
#
# Arguments:
#    config            string   'DEFAULTS', 'GENERAL', 'CONTINUUM', 'GASS',
#                               'HIPASS', 'HVC', 'METHANOL', 'ZOA', 'MOPRA',
#                               or 'AUDS'.
#    client_dir        string   Directory containing client executables.  May
#                               be blank to use PATH.
#    directory         string   Directory containing the input file.
#    file              string   Input file (or measurementset directory name).
#    retry             int      MBFITS only: number of times the reader should
#                               retry reading the input file after it
#                               encounters an EOF.  There is a 10s wait
#                               between retries.  This is provided for
#                               realtime reading of the file as it is being
#                               written by the correlator.
#    beamsel           bool[13] Mask of beams selected subject to their
#                               presence in the data.
#    IFsel             bool[16] Mask of IFs selected subject to their presence
#                               in the data.  Usually only one IF is processed
#                               at a time, but two IFs may be selected for
#                               frequency-switched data.
#    startChan         int      Start spectral channel; zero or negative value
#                               specifies an offset from the last channel,
#                      string   can also be specified as 'end' or 'last'.
#    endChan           int      End spectral channel; zero or negative value
#                               specifies an offset from the last channel,
#                      string   can also be specified as 'end' or 'last'.
#                               Spectral inversion may be achieved by setting
#                               endChan < startChan.
#    getXpol           boolean  Read cross-correlation data in addition to the
#                               auto-correlation data?
#    interpolate       int      Do position interpolation?  (MBFITS only.)
#    calibrate         boolean  Apply flux calibration?
#    recalibrate       boolean  Reapply flux calibration?
#    calfctr           double[13][2]  Calibration factors to be applied to
#                               auto-correlation data.  Set zero to defeat.
#    xcalfctr          dcomplex[13]  Calibration factors to be applied to
#                               cross-polarization data.  Set zero to defeat.
#
# Received events:
#    close()             Close the input file.
#    hidegui()           Make the GUI invisible.
#    init(record)        Initialize the reader client; parameter values may
#                        optionally be specified.  The client will respond
#                        with an initialized() event (see below).
#    lock()              Disable parameter entry.
#    printparms()        Print parameters for the reader client.
#    printvalid()        Print parameter validation rules.
#    read()              Read the next record from the input file.
#    setconfig(string)   Set configuration to 'DEFAULTS', 'GENERAL',
#                        'CONTINUUM', 'GASS', 'HIPASS', 'HVC', 'METHANOL',
#                        'ZOA', 'MOPRA', or 'AUDS'.
#    setparm(record)     Set parameter values for the reader client.
#    showgui(agent)      Create the GUI or make it visible if it already
#                        exists.  The parent frame may be specified.
#    terminate()         Close down.
#    unlock()            Enable parameter entry.
#
# Sent events:
#    closed()            Input file closed.
#    data(record)        Record containing data read from the input file.
#    done()              Agent has terminated.
#    eof()               End-of-file encountered on input file (after the
#                        specified number of retries).
#    fail()              Reader client has died.
#    guiready()          GUI construction complete.
#    init_error()        Client initialization error.
#    initialized(record) Sent in response to an init event once the reader
#                        client has been initialized.  The parameters describe
#                        the content of the input data:
#                           format     string    Data format (MBFITS, SDFITS)
#                           beams      bool[]    Mask of beams found in the
#                                                input data.
#                           IFs        bool[]    Mask of IFs found in the
#                                                input data.
#                           npols      int       Number of polarizations
#                                                in the IFs selected.
#                           nchans     int       Number of spectral channels
#                                                in the IFs selected.
#                           xpol       bool      Cross-polarizations present
#                                                in the IFs selected?
#                           utc        double    MJD UTC of first sample, s.
#                           reffreq    double    Reference frequency, Hz.
#                           bandwidth  double    Total bandwidth, Hz.
#    log(record)         Log message.
#    read_error()        Client read error.
# -------------------------------------------------------------------- <USAGE>
#=============================================================================

pragma include once

include 'pkslib.g'

const pksreader := subsequence(config      = 'GENERAL',
                               client_dir  = '',
                               directory   = '.',
                               file        = 'unspecified',
                               retry       = 0,
                               beamsel     = [T,T,T,T,T,T,T,T,T,T,T,T,T],
                               IFsel       = [T,T,F,F,F,F,F,F,F,F,F,F,F,F,F,F],
                               startChan   = 1,
                               endChan     = 'end',
                               getXpol     = F,
                               interpolate = T,
                               calibrate   = F,
                               recalibrate = F,
                               calfctr     = array(0.0,13,2),
                               xcalfctr    = array(0+0i,13)) : [reflect=T]
{
  # Our identity and state.
  self.name := 'reader'

  for (j in system.path.include) {
    self.file := spaste(j, '/pksreader.g')
    if (len(stat(self.file))) break
  }

  self.open := F

  # Parameter values.
  parms := [=]

  # Parameter value checking.
  pchek := [
    config      = [string   = [default = 'GENERAL',
                               valid   = "DEFAULTS GENERAL CONTINUUM GASS \
                                          HIPASS HVC METHANOL ZOA MOPRA \
                                          AUDS"]],
    client_dir  = [string   = [default = '']],
    directory   = [string   = [default = '.',
                               invalid = '']],
    file        = [string   = [default = 'unspecified',
                               invalid = '']],
    retry       = [integer  = [default = 0,
                               minimum = 0,
                               maximum = 10]],
    beamsel     = [boolean  = [default = [T,T,T,T,T,T,T,T,T,T,T,T,T]]],
    IFsel       = [boolean  = [default = [T,T,F,F,F,F,F,F,F,F,F,F,F,F,F,F]]],
    startChan   = [integer  = [default = 1,
                               minimum = -256*1024,
                               maximum =  256*1024],
                   string   = [valid   = "end last"]],
    endChan     = [integer  = [default = 0,
                               minimum = -256*1024,
                               maximum =  256*1024],
                   string   = [valid   = "end last"]],
    getXpol     = [boolean  = [default = F]],
    interpolate = [boolean  = [default = T]],
    calibrate   = [boolean  = [default = F]],
    recalibrate = [boolean  = [default = F]],
    calfctr     = [double   = [default = array(0.0,13,2)]],
    xcalfctr    = [dcomplex = [default = array(0+0i,13)]]]

  if (!streq(field_names(pchek), field_names(parameters()))) {
    print spaste(self.file, ': internal inconsistency - pchek field names.')
  }

  # Version information maintained by RCS.
  wrk := [=]
  wrk.RCSid    := "$Revision: 19.16 $$Date: 2006/07/13 06:39:06 $"
  wrk.version  := spaste(wrk.RCSid[2], ', ', wrk.RCSid[4])
  wrk.lastexit := './livedata.lastexit/pksreader.lastexit'

  # Work variables.
  wrk.beams  := [T,T,T,T,T,T,T,T,T,T,T,T,T]
  wrk.IFs    := [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T]
  wrk.IFage  := [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
  wrk.caldir := '.'
  wrk.fd     := F
  wrk.header := [=]
  wrk.locked := F
  wrk.unwarn := F

  # GUI widgets.
  gui := [f1 = F, f2 = F]

  #---------------------------------------------------------------------------
  # Local function definitions.
  #---------------------------------------------------------------------------
  local format, helpmsg, readgui, set := [=], sethelp, setparm, showgui

  #-------------------------------------------------------------------- format

  # Record the input file type.

  const format := function(type)
  {
    wider wrk

    wrk.client.format := type

    # Record the type on the GUI.
    if (is_agent(gui.f1)) {
      gui.format.sv->text(wrk.client.format)

      if (wrk.client.format == 'MBFITS') {
        gui.retry.la->foreground('#000000')
        gui.retry.sv->foreground('#000000')

      } else {
        gui.retry.la->foreground('#a3a3a3')
        gui.retry.sv->foreground('#a3a3a3')
      }
    }
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
    wider parms

    if (is_agent(gui.f1)) {
      setparm([startChan = gui.startChan.en->get(),
               endChan   = gui.endChan.en->get() ])

      if (is_agent(gui.f2)) {
        calfctr  := array(0.0,13,2)
        xcalfctr := array(0+0i,13)

        j := 0
        for (pol in 1:2) {
          for (beam in 1:13) {
            j +:= 1
            calfctr[beam,pol] := as_double(gui.calfctr.en[j]->get())
          }
        }

        for (beam in 1:13) {
          xcalfctr[beam] := as_dcomplex(gui.xcalfctr.en[beam]->get())
        }

        setparm([calfctr  = calfctr,
                 xcalfctr = xcalfctr])
      }
    }
  }

  #------------------------------------------------------------------- sethelp

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

    } else if (any(parms.config == "HIPASS HVC ZOA GASS")) {
      setparm([beamsel     = [T,T,T,T,T,T,T,T,T,T,T,T,T],
               IFsel       = [T,T,F,F,F,F,F,F,F,F,F,F,F,F,F,F],
               getXpol     = F,
               interpolate = T,
               calibrate   = F])

      if (parms.config == 'HVC') {
        setparm([startChan = 45, endChan = 175])
      } else if (parms.config == 'GASS') {
        setparm([startChan = 1, endChan = 2049])
      } else {
        setparm([startChan = 1, endChan = 1024])
      }

      if (parms.config != 'GASS') self->lock()

    } else if (parms.config == 'METHANOL') {
      a := [2.43,1.87,4.29,2.60,3.42,3.99,1.97,0.00,0.00,0.00,0.00,0.00,0.00]
      b := [2.39,1.73,4.06,3.25,3.98,3.55,1.67,0.00,0.00,0.00,0.00,0.00,0.00]
      setparm([beamsel     = [T,T,T,T,T,T,T,F,F,F,F,F,F],
               IFsel       = [T,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F],
               startChan   = 1,
               endChan     = 0,
               getXpol     = F,
               interpolate = T,
               calibrate   = T,
               calfctr     = array([a,b],13,2)])

    } else if (parms.config == 'MOPRA') {
      setparm([beamsel     = [T,F,F,F,F,F,F,F,F,F,F,F,F],
               IFsel       = [T,T,F,F,F,F,F,F,F,F,F,F,F,F,F,F],
               startChan   = 1,
               endChan     = 1024,
               getXpol     = F,
               interpolate = T,
               calibrate   = F])

    } else if (parms.config == 'AUDS') {
      setparm([beamsel     = [T,T,T,T,T,T,T,T,F,F,F,F,F],
               IFsel       = [T,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F],
               startChan   = 1,
               endChan     = 4096,
               getXpol     = F,
               interpolate = T,
               calibrate   = F])

      self->unlock()

    } else {
      self->unlock()
    }
  }

  #------------------------------------------------------------- set.directory

  # Set the directory containing the input file.

  const set.directory := function(value)
  {
    wider parms

    parms.directory := value ~ s|(.+?)/+$|$1| ~ s|//+|/|g
  }

  #--------------------------------------------------------------- set.endChan

  # Set the upper channel range selection.

  const set.endChan := function(value)
  {
    wider parms

    if (is_integer(value)) {
      parms.endChan := value
    } else {
      parms.endChan := 0
    }
  }

  #------------------------------------------------------------------ set.file

  # Set the input file.

  const set.file := function(value)
  {
    wider parms

    if (value ~ m|^/|) {
      # Absolute path name.
      tmp := value
    } else {
      # Path name relative to the currently specified directory.
      tmp := spaste(parms.directory, '/', value)
    }
    parms.directory := tmp ~ s|[^/]*$|| ~ s|(.+?)/+$|$1| ~ s|//+|/|g
    parms.file      := tmp ~ s|.*/||
  }

  #----------------------------------------------------------------- set.IFsel

  # Set IF selection mask, ensuring that no more than two IFs are selected.

  const set.IFsel := function(value)
  {
    wider parms, wrk

    parms.IFsel := value

    # Increment the selection count for selected IFs.
    wrk.IFage +:= parms.IFsel
    wrk.IFage[!parms.IFsel] := 0

    while (sum(parms.IFsel) > 2) {
      # Disable the stalest IF.
      stalest := ind(wrk.IFage)[wrk.IFage == max(wrk.IFage)]
      i := stalest[len(stalest)]
      parms.IFsel[i] := F
      wrk.IFage[i]  := 0
    }
  }

  #----------------------------------------------------------- set.interpolate

  # Set MBFITS position interpolation.

  const set.interpolate := function(value)
  {
    wider parms, wrk

    parms.interpolate := value

    if (!parms.interpolate) {
      self->log([
        location = 'reader',
        message  = 'WARNING MBFITS position interpolation was disabled!',
        priority = 'WARN'])
      print('WARNING MBFITS position interpolation was disabled!')
      wrk.unwarn := T

    } else if (wrk.unwarn) {
      self->log([
        location = 'reader',
        message  = 'MBFITS position interpolation re-enabled.',
        priority = 'NORMAL'])
      print('MBFITS position interpolation re-enabled.')
      wrk.unwarn := F
    }
  }

  #------------------------------------------------------------- set.startChan

  # Set the lower channel range selection.

  const set.startChan := function(value)
  {
    wider parms

    if (is_integer(value)) {
      parms.startChan := value
    } else {
      parms.startChan := 0
    }
  }

  #------------------------------------------------------------------- showgui

  # Build a graphical user interface for the reader client.
  # If the parent frame is not specified a separate window will be created.

  const showgui := function(parent=F)
  {
    wider gui, parms

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
      gui.f1 := frame(title='Parkes multibeam reader', expand='none')

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
    gui.f11  := frame(gui.f1, relief='ridge', borderwidth=4, expand='x')
    gui.f111 := frame(gui.f11, relief='ridge', expand='x')

    gui.title.ex := button(gui.f111, 'MULTIBEAM READER', relief='flat',
                           borderwidth=0, foreground='#0000a0')
    sethelp(gui.title.ex, spaste('Control panel (v', wrk.version,
      ') for the Multibeam reader client; PRESS FOR USAGE!'))

    whenever
      gui.title.ex->press do
        explain(self.file, 'USAGE')

    # Input data format.
    gui.f1111 := frame(gui.f111, side='left', expand='none')

    gui.format.la := label(gui.f1111, 'Format:')
    gui.format.sv := label(gui.f1111, '', width=6)
    sethelp(gui.format.sv, 'Format of the file being read.')

    # Maximum number of retries.
    gui.f1112 := frame(gui.f111, side='left', expand='none', borderwidth=0)
    gui.retry.la := label(gui.f1112, 'Max retries:')
    gui.retry.sv := label(gui.f1112, justify='right', width=2)
    sethelp(gui.retry.sv, 'No. of times to retry reading the file as it is \
      being written in realtime mode (set via LIVEDATA_READ_RETRY).')

    #=========================================================================
    # Beam selection panel.
    gui.f112 := frame(gui.f11, relief='ridge', expand='x')

    # Beam selection.
    gui.f1121 := frame(gui.f112, expand='none')
    gui.beamsel.la := label(gui.f1121, 'Input data selection', padx=0,
                            foreground='#b03060')
    sethelp(gui.beamsel.la, 'Input data selection panel.')

    gui.f11211 := frame(gui.f1121, side='left', expand='none')
    sethelp(gui.f11211, 'Select beams to be read, subject to their presence \
      in the data.')

    # Define a record with 13 fields.
    gui.beamsel.bn := [=]
    for (j in 1:13) gui.beamsel.bn[j] := F

    gui.f112111  := frame(gui.f11211, borderwidth=0)
    gui.f1121111 := frame(gui.f112111, height=31, width=0, expand='none')
    gui.beamsel.bn[8]  := button(gui.f112111,  '8', value=8,  width=1, padx=3,
                                 pady=1)

    gui.f112112 := frame(gui.f11211, borderwidth=0)
    gui.beamsel.bn[13] := button(gui.f112112, '13', value=13, width=1, padx=3,
                                 pady=0)
    gui.beamsel.bn[7]  := button(gui.f112112,  '7', value=7,  width=1, padx=3,
                                 pady=0)
    gui.beamsel.bn[2]  := button(gui.f112112,  '2', value=2,  width=1, padx=3,
                                 pady=0)
    gui.beamsel.bn[9]  := button(gui.f112112,  '9', value=9,  width=1, padx=3,
                                 pady=0)

    gui.f112113  := frame(gui.f11211, borderwidth=0)
    gui.f1121131 := frame(gui.f112113, height=10, width=0, expand='none')
    gui.beamsel.bn[6]  := button(gui.f112113,  '6', value=6,  width=1, padx=3,
                                 pady=0)
    gui.beamsel.bn[1]  := button(gui.f112113,  '1', value=1,  width=1, padx=3,
                                 pady=0)
    gui.beamsel.bn[3]  := button(gui.f112113,  '3', value=3,  width=1, padx=3,
                                 pady=0)

    gui.f112114 := frame(gui.f11211, borderwidth=0)
    gui.beamsel.bn[12] := button(gui.f112114, '12', value=12, width=1, padx=3,
                                 pady=0)
    gui.beamsel.bn[5]  := button(gui.f112114,  '5', value=5,  width=1, padx=3,
                                 pady=0)
    gui.beamsel.bn[4]  := button(gui.f112114,  '4', value=4,  width=1, padx=3,
                                 pady=0)
    gui.beamsel.bn[10] := button(gui.f112114, '10', value=10, width=1, padx=3,
                                 pady=0)

    gui.f112115  := frame(gui.f11211, borderwidth=0)
    gui.f1121151 := frame(gui.f112115, height=31, width=0, expand='none')
    gui.beamsel.bn[11] := button(gui.f112115, '11', value=11, width=1, padx=3,
                                 pady=0)

    for (i in 1:13) {
      sethelp(gui.beamsel.bn[i],
              spaste('Select or deselect input for beam ', i,
                     ' (if available).'))
    }

    whenever
      gui.beamsel.bn[1]->press,
      gui.beamsel.bn[2]->press,
      gui.beamsel.bn[3]->press,
      gui.beamsel.bn[4]->press,
      gui.beamsel.bn[5]->press,
      gui.beamsel.bn[6]->press,
      gui.beamsel.bn[7]->press,
      gui.beamsel.bn[8]->press,
      gui.beamsel.bn[9]->press,
      gui.beamsel.bn[10]->press,
      gui.beamsel.bn[11]->press,
      gui.beamsel.bn[12]->press,
      gui.beamsel.bn[13]->press do {
        p := parms.beamsel
        p[$value] := !p[$value]
        setparm([beamsel = p])
      }


    # IF selection.
    gui.f11212   := frame(gui.f1121, relief='sunken', borderwidth=1,
                          expand='x')

    gui.f112121   := frame(gui.f11212, side='right', borderwidth=0,
                           expand='x')

    gui.f1121211  := frame(gui.f112121, borderwidth=0, expand='none')
    gui.f11212111 := frame(gui.f1121211, side='left', borderwidth=0,
                           expand='none')
    gui.f11212112 := frame(gui.f1121211, side='left', borderwidth=0,
                           expand='none')
    gui.f11212113 := frame(gui.f1121211, side='left', borderwidth=0,
                           expand='none')
    gui.f11212114 := frame(gui.f1121211, side='left', borderwidth=0,
                           expand='none')

    # Define a record with 8 fields.
    gui.IFsel.bn := [=]
    for (j in 1:16) gui.IFsel.bn[j] := F

    gui.IFsel.bn[1]  := button(gui.f11212111,  '1', value= 1, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[2]  := button(gui.f11212111,  '2', value= 2, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[3]  := button(gui.f11212111,  '3', value= 3, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[4]  := button(gui.f11212111,  '4', value= 4, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[5]  := button(gui.f11212112,  '5', value= 5, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[6]  := button(gui.f11212112,  '6', value= 6, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[7]  := button(gui.f11212112,  '7', value= 7, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[8]  := button(gui.f11212112,  '8', value= 8, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[9]  := button(gui.f11212113,  '9', value= 9, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[10] := button(gui.f11212113, '10', value=10, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[11] := button(gui.f11212113, '11', value=11, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[12] := button(gui.f11212113, '12', value=12, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[13] := button(gui.f11212114, '13', value=13, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[14] := button(gui.f11212114, '14', value=14, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[15] := button(gui.f11212114, '15', value=15, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)
    gui.IFsel.bn[16] := button(gui.f11212114, '16', value=16, font=fonts.Vb8,
                               borderwidth=1, width=3, padx=0, pady=0)

    for (i in 1:16) {
      sethelp(gui.IFsel.bn[i],
              spaste('Select or deselect input for IF ', i,
                     ' (if available).'))
    }

    whenever
      gui.IFsel.bn[1]->press,
      gui.IFsel.bn[2]->press,
      gui.IFsel.bn[3]->press,
      gui.IFsel.bn[4]->press,
      gui.IFsel.bn[5]->press,
      gui.IFsel.bn[6]->press,
      gui.IFsel.bn[7]->press,
      gui.IFsel.bn[8]->press,
      gui.IFsel.bn[9]->press,
      gui.IFsel.bn[10]->press,
      gui.IFsel.bn[11]->press,
      gui.IFsel.bn[12]->press,
      gui.IFsel.bn[13]->press,
      gui.IFsel.bn[14]->press,
      gui.IFsel.bn[15]->press,
      gui.IFsel.bn[16]->press do {
        p := parms.IFsel
        p[$value] := !p[$value]
        setparm([IFsel = p])
      }

    gui.IFsel.la := label(gui.f112121, 'IFs', padx=2, fill='both')
    sethelp(gui.IFsel.la, 'IF selection panel; at most 2 IFs may be selected \
      and they must have the same number of channels and polarizations.')


    # Spectral range.
    gui.chanRange.la := label(gui.f1121, 'Channel range')
    sethelp(gui.chanRange.la, 'Input channel range selection.')

    gui.f11213 := frame(gui.f1121, side='left', borderwidth=0, expand='x')
    gui.startChan.en := entry(gui.f11213, width=6, justify='right',
                              fill='x')
    sethelp(gui.startChan.en, 'First channel of spectrum; use zero or a \
      negative value for offset from last channel in data.')

    whenever
      gui.startChan.en->return do
        setparm([startChan = $value])

    gui.chan_sep.la := label(gui.f11213, '-', padx=0)

    gui.endChan.en  := entry(gui.f11213, width=6, justify='right', fill='x')
    sethelp(gui.endChan.en, 'Last channel of spectrum; use zero or a \
      negative value for offset from last channel in data.')

    whenever
      gui.endChan.en->return do
        setparm([endChan = $value])


    # Read cross-polarization data?
    gui.getXpol.bn := button(gui.f1121, 'Read X-pol', type='check',
                             justify='left', width=12)
    sethelp(gui.getXpol.bn, 'Read cross-correlation data in addition to \
      auto-correlation data?')

    whenever
      gui.getXpol.bn->press do
        setparm([getXpol = gui.getXpol.bn->state()])

    #=========================================================================
    # Processing options.
    gui.f113 := frame(gui.f11, relief='ridge', expand='x')
    gui.f1131 := frame(gui.f113, expand='none')

    # Interpolate?
    gui.interpolate.bn := button(gui.f1131, 'Interpolate', type='check',
                                 justify='left', width=12)
    sethelp(gui.interpolate.bn, 'Do position interpolation for MBFITS files? \
      (Don\'t disable this unless you understand the consequences!)')

    whenever
      gui.interpolate.bn->press do
        setparm([interpolate = gui.interpolate.bn->state()])


    # Calibrate?
    gui.calibrate.bn := button(gui.f1131, 'Calibrate...', type='check',
                               fill='x')
    sethelp(gui.calibrate.bn, 'Apply flux calibration?  (Invokes options \
      window.)')

    whenever
      gui.calibrate.bn->press do
        setparm([calibrate = gui.calibrate.bn->state()])

    #=========================================================================
    # Widget help messages.
    if (gui.dohelp) {
      if (!is_agent(gui.helpmsg)) {
        gui.f113 := frame(gui.f11, relief='ridge')
        gui.helpmsg := label(gui.f113, '', font=fonts.Fm12, width=1, fill='x',
                             borderwidth=0)
        sethelp(gui.helpmsg, 'Widget help messages.')
      }
    }


    # Lock parameter entry?
    if (wrk.locked) gui.f1->disable()

    # Initialize widgets.
    showparm(gui, parms)

    tk_release()

    self->guiready()
  }

  #---------------------------------------------------------- gui.beamsel.show

  # Show the mask of beams selected (subject to their presence in the data).

  const gui.beamsel.show := function()
  {
    for (j in 1:13) {
      if (wrk.beams[j]) {
        gui.beamsel.bn[j]->foreground('#000000')
        if (parms.beamsel[j]) {
          gui.beamsel.bn[j]->background('#00a0b3')
        } else {
          gui.beamsel.bn[j]->background('#d4d4d4')
        }
        gui.beamsel.bn[j]->relief('raised')

      } else {
        # (Button foreground colour is set by tk when disabled.)
        gui.beamsel.bn[j]->background('#d4d4d4')
        gui.beamsel.bn[j]->relief('flat')
      }
    }
  }

  #-------------------------------------------------------- gui.calibrate.show

  # Build a separate calibration control window.

  const gui.calibrate.show := function()
  {
    wider gui, wrk

    gui.calibrate.bn->state(parms.calibrate)

    if (is_agent(gui.f2)) {
      if (parms.calibrate) {
        gui.f2->map()
        gui.f2->raise()
      } else {
        gui.f2->unmap()
      }

      return
    }

    if (!parms.calibrate) return

    tk_hold()

    gui.f2 := frame(title='Calibration factors', relief='ridge',
                    borderwidth=4, expand='none')

    # Reapply factors?
    gui.f21  := frame(gui.f2, side='left', borderwidth=0)
    gui.f211 := frame(gui.f21, borderwidth=0, expand='none')
    gui.recalibrate.bn := button(gui.f211, 'Recalibrate', type='check')
    sethelp(gui.recalibrate.bn, 'If the data has already been calibrated \
      then undo it and apply the new factors; alternative is to leave as is.')

    whenever
      gui.recalibrate.bn->press do
        setparm([recalibrate = gui.recalibrate.bn->state()])


    # Load calibration factors from file.
    gui.loadfile.bn := button(gui.f211, 'Load file...', pady=2, fill='x')
    sethelp(gui.loadfile.bn, 'Load calibration factors from disk file \
      (invokes file browser).')

    gui.loadfile.fb := F
    whenever
      gui.loadfile.bn->press do {
        if (is_boolean(gui.loadfile.fb)) {
          gui.loadfile.fb := filebrowser(title='Load calibration factors',
                                         dir=wrk.caldir)

          whenever
            gui.loadfile.fb->selection do {
              wrk.caldir := $value.dir

              calfctr  := parms.calfctr
              xcalfctr := parms.xcalfctr

              wrk.fd := open(spaste('< ', $value.dir, '/', $value.file))
              if (is_file(wrk.fd)) {
                while (line := read(wrk.fd)) {
                  line := split(line ~ s|#.*||)
                  if (len(line) < 3) continue

                  beam := as_integer(line[1])
                  calfctr[beam,1:2] := as_double(line[2:3])

                  if (len(line) >= 4) xcalfctr[beam] := as_dcomplex(line[4])
                }
                wrk.fd := F

                setparm([calfctr = calfctr, xcalfctr = xcalfctr])
                print 'Read calibration factors from', $value.file

              } else {
                print 'Failed to open', $value.file
              }
            }

          whenever
            gui.loadfile.fb->done do {
              wrk.caldir := $value.dir
              gui.loadfile.fb := F
            }

        } else {
          # Bring file browser to the top.
          gui.loadfile.fb->raise()
        }
      }


    # Save calibration factors to file.
    gui.savefile.bn := button(gui.f211, 'Save file...', pady=2, fill='x')
    sethelp(gui.savefile.bn, 'Save calibration factors to disk file (invokes \
      file browser).')

    gui.savefile.fb := F
    whenever
      gui.savefile.bn->press do {
        if (is_boolean(gui.savefile.fb)) {
          gui.savefile.fb := filebrowser(title='Save calibration factors',
                                         create=T, dir=wrk.caldir)
          whenever
            gui.savefile.fb->selection do {
              readgui()
              wrk.caldir := $value.dir

              wrk.fd := open(spaste('> ', $value.dir, '/', $value.file))
              if (is_file(wrk.fd)) {
                t := shell('date \'+%Y/%m/%d %T %Z (%a)\'')
                write (wrk.fd, '# Parkes Multibeam calibration factors.\n#')
                write (wrk.fd, spaste('# Written on: ', t, '\n#'))
                write (wrk.fd, '#             Polarization')
                write (wrk.fd, '# Beam    A      B       X-pol')
                write (wrk.fd, '# ----  ------------------------')

                for (beam in 1:13) {
                  fprintf(wrk.fd, '%5d%7.2f%7.2f%7.2f%+.2fi\n', beam,
                          parms.calfctr[beam,1], parms.calfctr[beam,2],
                          real(parms.xcalfctr[beam]),
                          imag(parms.xcalfctr[beam]))
                }
                wrk.fd := F

                print 'Saved calibration factors in', $value.file

              } else {
                print 'Failed to open', $value.file
              }
            }

          whenever
            gui.savefile.fb->done do {
              wrk.caldir := $value.dir
              gui.savefile.fb := F
            }

        } else {
          # Bring file browser to the top.
          gui.savefile.fb->raise()
        }
      }


    # Panel of entry boxes for calibration factors.
    gui.f22 := frame(gui.f2, side='left', relief='ridge')

    gui.f221 := frame(gui.f22, borderwidth=0)
    gui.beam.la := label(gui.f221, '')

    gui.beamno.la := [=]
    for (beam in 1:13) {
      gui.beamno.la[beam] := label(gui.f221, sprintf('%2d', beam))
    }

    gui.f222 := frame(gui.f22, borderwidth=0)
    gui.f223 := frame(gui.f22, borderwidth=0)

    gui.pol.la := [=]
    gui.calfctr.en := [=]

    j := 0
    for (pol in 1:2) {
      if (pol == 1) {
        f := gui.f222
      } else {
        f := gui.f223
      }

      gui.pol.la[pol] := label(f, "A B"[pol])
      for (beam in 1:13) {
        j +:= 1
        gui.calfctr.en[j] := entry(f, width=4)
        gui.calfctr.en[j].index  := j
        gui.calfctr.en[j].format := '%.2f'
        sethelp(gui.calfctr.en[j], spaste('Calibration factor for beam ',
          beam, ', polarization ', "A B"[pol], ' (set 0.0 to leave as is).'))

        whenever
          gui.calfctr.en[j]->return do {
            t := parms.calfctr
            t[$agent.index] := as_double($value)
            setparm([calfctr = t])
          }
      }
    }

    # Cross-polarization factors.
    gui.f224 := frame(gui.f22, borderwidth=0)

    gui.xcalfctr.en := [=]
    gui.xpol.la := label(gui.f224, 'X-pol')
    for (beam in 1:13) {
      gui.xcalfctr.en[beam] := entry(gui.f224, width=9)
      gui.xcalfctr.en[beam].beam := beam
      gui.xcalfctr.en[beam].format := '%.2f%+.2fi'
      sethelp(gui.xcalfctr.en[beam], spaste('Cross-polarization calibration \
        factor for beam ', beam, ' (set 0+0i to leave as is).'))

      whenever
        gui.xcalfctr.en[beam]->return do {
          t := parms.xcalfctr
          t[$agent.beam] := as_dcomplex($value)
          setparm([xcalfctr = t])
        }
    }


    # Dismiss.
    gui.f23 := frame(gui.f2, side='right', borderwidth=0)
    gui.dismiss.bn := button(gui.f23, 'Dismiss', pady=2)
    sethelp(gui.dismiss.bn, 'Dismiss calibration window.')

    whenever
      gui.dismiss.bn->press do
        gui.f2->unmap()


    # Initialize widgets.
    showparm(gui, parms)

    tk_release()
  }

  #---------------------------------------------------------- gui.endChan.show

  # Show the upper channel selection.

  const gui.endChan.show := function()
  {
    gui.endChan.en->delete('start', 'end')
    if (parms.endChan == 0) {
      gui.endChan.en->insert('end')
    } else {
      gui.endChan.en->insert(as_string(parms.endChan))
    }
  }

  #---------------------------------------------------------- gui.getXpol.show

  # Show the cross-polarization data selection state.

  const gui.getXpol.show := function()
  {
    gui.getXpol.bn->state(parms.getXpol)

    if (is_agent(gui.f2)) {
      tk_hold()

      if (parms.getXpol) {
        gui.f224->map()
      } else {
        gui.f224->unmap()
      }

      tk_release()
    }
  }

  #------------------------------------------------------------ gui.IFsel.show

  # Show the mask of IFs selected (subject to their presence in the data).

  const gui.IFsel.show := function()
  {
    for (j in 1:16) {
      if (wrk.IFs[j]) {
        gui.IFsel.bn[j]->foreground('#000000')
        if (parms.IFsel[j]) {
          gui.IFsel.bn[j]->background('#00a0b3')
        } else {
          gui.IFsel.bn[j]->background('#d4d4d4')
        }
        gui.IFsel.bn[j]->relief('raised')

      } else {
        # (Button foreground colour is set by tk when disabled.)
        gui.IFsel.bn[j]->background('#d4d4d4')
        gui.IFsel.bn[j]->relief('flat')
      }
    }
  }

  #-------------------------------------------------------- gui.startChan.show

  # Show the upper channel selection.

  const gui.startChan.show := function()
  {
    gui.startChan.en->delete('start', 'end')
    if (parms.startChan == 0) {
      gui.startChan.en->insert('end')
    } else {
      gui.startChan.en->insert(as_string(parms.startChan))
    }
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
      readgui()
      print ''
      printrecord(parms, 'parms')
    }

  # Show parameter validation rules.
  whenever
    self->printvalid do {
      print ''
      printrecord(pchek, 'valid')
    }

  # Show parameter validation rules.
  whenever
    self->printvalid do {
      print ''
      printrecord(pchek, 'valid')
    }

  # Disable parameter entry.
  whenever
    self->lock do {
      if (!wrk.locked) {
        wrk.locked := T
        if (is_agent(gui.f1)) gui.f1->disable()
      }
    }

  # Enable parameter entry.
  whenever
    self->unlock do {
      if (wrk.locked &&
        any(parms.config == "GENERAL CONTINUUM GASS METHANOL MOPRA AUDS")) {
        wrk.locked := F
        if (is_agent(gui.f1)) gui.f1->enable()
      }

      wrk.beams := [T,T,T,T,T,T,T,T,T,T,T,T,T]
      setparm([beamsel = parms.beamsel])

      wrk.IFs := [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T]
      setparm([IFsel = parms.IFsel])
    }

  # Open the input file.
  whenever
    self->init do {
      setparm($value)
      readgui()

      # Client init returns information about the content of the data.
      self.open := T
      wrk.client->init(parms)
    }

  # Read the next record.
  whenever
    self->read do
      if (self.open) wrk.client->read()

  # Close the input file.
  whenever
    self->close do {
      if (self.open) {
        self.open := F
        wrk.client->close()

        if (is_agent(gui.f1)) {
          gui.retry.la->foreground('#000000')
          gui.retry.sv->foreground('#000000')
        }
      }
    }

  # Create or expose the GUI.
  whenever
    self->showgui do
      showgui($value)

  # Hide the GUI.
  whenever
    self->hidegui do
      if (is_agent(gui.f1)) gui.f1->unmap()

  # Close down.
  whenever
    self->terminate do {
      readgui()
      store(parms, wrk.lastexit)

      deactivate whenever_stmts(wrk.client).stmt

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

  # Set parameters.
  args := [config      = 'GENERAL',
           client_dir  = client_dir,
           directory   = directory,
           file        = file,
           retry       = retry,
           beamsel     = beamsel,
           IFsel       = IFsel,
           startChan   = startChan,
           endChan     = endChan,
           getXpol     = getXpol,
           interpolate = interpolate,
           calibrate   = calibrate,
           recalibrate = recalibrate,
           calfctr     = calfctr,
           xcalfctr    = xcalfctr]

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

  #------------------------------------------------------------- reader client

  # Start reader client.
  if (parms.client_dir == '') {
    wrk.client := client('pksreader')
  } else {
    wrk.client := client(spaste(parms.client_dir, '/pksreader'))
  }
  wrk.client.name := 'pksreader'

  whenever
    wrk.client->init_error do {
      # Client initialization failed.
      self.open := F
    }

  # Pass events through.
  whenever
    wrk.client->* do {
      if ($name == 'initialized') {
        # Data description information.
        wrk.header := $value

        # Record input file type on the GUI.
        format($value.format)

        # Update beam selection buttons.
        wrk.beams := $value.beams
        if (len(wrk.beams) < 13) wrk.beams[(len(wrk.beams)+1):13] := F
        setparm([beamsel = parms.beamsel])

        # Update IF selection buttons.
        wrk.IFs := $value.IFs
        if (len(wrk.IFs) < 16) wrk.IFs[(len(wrk.IFs)+1):16] := F
        setparm([IFsel = parms.IFsel])

        # Mask of beams and IFs present and selected.
        wrk.header.beams := wrk.beams & parms.beamsel
        wrk.header.IFs   := wrk.IFs   & parms.IFsel
        self->initialized(wrk.header)

      } else {
        self->[$name]($value)
      }
    }
}
