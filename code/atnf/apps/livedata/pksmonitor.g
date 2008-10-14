#-----------------------------------------------------------------------------
# pksmonitor.g: Controller for the Parkes multibeam data monitor.
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
# $Id: pksmonitor.g,v 19.21 2006/07/13 06:34:35 mcalabre Exp $
#-----------------------------------------------------------------------------
# -------------------------------------------------------------------- <USAGE>
# Handler and optional GUI for the Parkes multibeam data monitor.
#
# Arguments:
#    config            string   'DEFAULTS', 'GENERAL', 'CONTINUUM', 'GASS',
#                               'HIPASS', 'HVC', 'METHANOL', 'ZOA', 'MOPRA',
#                               or 'AUDS'.
#    client_dir        string   Directory containing client executable.  May
#                               be blank to use PATH.
#    beams             bool[13] Mask of beams present in data.
#    IFs               bool[16] Mask of IFs   present in data; maximum two,
#                               each with the same number of channels and
#                               polarizations.
#    npols             int      Number of polarizations in input data.
#    nchans            int      Number of spectral channels in input data.
#    beamsel           bool[13] Mask of beams to use for averaging, display,
#                               etc. (if present in data).
#    maxspec           int      Number of spectra to display.
#    if1               string   IF(s) to display in monitor windows 1 and 2:
#    if2               string      NONE
#                                  1st
#                                  2nd  (if present)
#                                  BOTH (if present)
#                               When two IFs are displayed together in one
#                               monitor window, as is usual for frequency-
#                               switched data, they must have the same channel
#                               spacing, and the spectra will be staggered
#                               appropriately in frequency.
#    pol1              string   Polarization to display in monitor windows 1
#    pol2              string   and 2:
#                                  A
#                                  B
#                                  (A+B)/2
#                                  (A-B)/2
#                                  NONE
#    timemode          string   Time averaging method:
#                                  NONE        ...no averaging
#                               The following calculate the relevant statistic
#                               for each channel over N integrations; one
#                               spectrum is displayed for every N
#                               integrations:
#                                  MEAN
#                                  MEDIAN
#                                  MAXIMUM
#                                  RMS
#    averlength        int      Number of 5 second scans to use in time
#                               averaging.  Ignored for timemode "NONE".
#    freqmode          string   Frequency smoothing:
#                                  NONE
#                                  HANNING
#    chanstart         int      Start spectral channel; zero or negative value
#                               specifies an offset from the last channel,
#                      string   can also be specified as 'end' or 'last'.
#    chanend           int      End spectral channel; zero or negative value
#                               specifies an offset from the last channel,
#                      string   can also be specified as 'end' or 'last'.
#    chanskip          int      Skip every Nth channel of the input spectra.
#                               If set to zero a suitable value will be chosen
#                               so as not to overload the display windows.
#    cfreq             boolean  If true, treat the x-axis as a frequency axis,
#                               interleaving frequency-switched data.  Else
#    ctime             boolean  If true, process scans in time (i.e. output
#                               frames have a time axis).
#                               channel.
#    flagblank         boolean  If true, set flagged data values to blank.
#    sumspec           boolean  If true, display the sum of the selected
#                               channel range in the first channel of the
#                               display.
#
# Received events:
#    flush()             Flush the display buffer.
#    hidegui()           Make the GUI invisible.
#    init(record)        Initialize the data monitor client.  Parameter values
#                        may optionally be specified.
#    lock()              Disable parameter entry.
#    newdata(record)     Process and display a multibeam record.
#    printparms()        Print parameters for the data monitor client.
#    printvalid()        Print parameter validation rules.
#    setconfig(string)   Set configuration to 'DEFAULTS', 'GENERAL',
#                        'CONTINUUM', 'GASS', 'HIPASS', 'HVC', 'ZOA',
#                        'METHANOL', 'MOPRA', or 'AUDS'.
#    setparm(record)     Set parameter values for the monitor client.
#    showgui(agent)      Create the GUI or make it visible if it already
#                        exists.  The parent frame may be specified.
#    terminate()         Close down.
#    unlock()            Enable parameter entry.
#
# Sent events:
#    done()              Agent has terminated.
#    error(string)       Error.
#    fail()              Monitor client failed.
#    fail1()             Display client 1 failed.
#    fail2()             Display client 2 failed.
#    flushProcessed()    Display buffers flushed.
#    guiready()          GUI construction complete.
#    init_error(string)  Initialization error.
#    initProcessed()     Initialization complete.
#    log(record)         Log message.
#    newdataProcessed(int)  Display complete, number of records processed.
# -------------------------------------------------------------------- <USAGE>
#=============================================================================

pragma include once

include 'pkslib.g'

const pksmonitor := subsequence(config     = 'GENERAL',
                                client_dir = '',
                                beams      = [F,F,F,F,F,F,F,F,F,F,F,F,F],
                                IFs        = [F,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F],
                                npols      = 0,
                                nchans     = 0,
                                beamsel    = [T,T,T,T,T,T,T,T,T,T,T,T,T],
                                maxspec    = 100,
                                if1        = 'BOTH',
                                if2        = 'BOTH',
                                pol1       = 'A',
                                pol2       = 'B',
                                timemode   = 'NONE',
                                averlength = 12,
                                freqmode   = 'NONE',
                                chanstart  = 1,
                                chanend    = 0,
                                chanskip   = 1,
                                cfreq      = T,
                                ctime      = T,
                                flagblank  = F,
                                sumspec    = F) : [reflect=T]
{
  # Our identity.
  self.name := 'monitor'

  for (j in system.path.include) {
    self.file := spaste(j, '/pksmonitor.g')
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
    beams      = [boolean = [default = [F,F,F,F,F,F,F,F,F,F,F,F,F]]],
    IFs        = [boolean = [default = [F,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F]]],
    npols      = [integer = [default = 0,
                             minimum = 1,
                             maximum = 2]],
    nchans     = [integer = [default = 0,
                             minimum = 1,
                             maximum = 256*1024]],
    beamsel    = [boolean = [default = [T,T,T,T,T,T,T,T,T,T,T,T,T]]],
    maxspec    = [integer = [default = 100,
                             minimum = 1,
                             maximum = 100]],
    if1        = [string  = [default = 'BOTH',
                             valid   = "BOTH 1st 2nd NONE"]],
    if2        = [string  = [default = 'BOTH',
                             valid   = "BOTH 1st 2nd NONE"]],
    pol1       = [string  = [default = 'A',
                             valid   = "A B (A+B)/2 (A-B)/2 NONE"]],
    pol2       = [string  = [default = 'B',
                             valid   = "A B (A+B)/2 (A-B)/2 NONE"]],
    timemode   = [string  = [default = 'NONE',
                             valid   = "NONE MEAN MEDIAN MAXIMUM RMS"]],
    averlength = [integer = [default = 12,
                             minimum = 1]],
    freqmode   = [string  = [default = 'NONE',
                             valid   = "NONE HANNING"]],
    chanstart  = [integer = [default = 1,
                             minimum = -32*1024,
                             maximum =  32*1024],
                  string  = [valid   = "end last"]],
    chanend    = [integer = [default = 0,
                             minimum = -32*1024,
                             maximum =  32*1024],
                  string  = [valid   = "end last"]],
    chanskip   = [integer = [default = 0,
                             minimum = 0,
                             maximum = 256]],
    cfreq      = [boolean = [default = T]],
    ctime      = [boolean = [default = T]],
    flagblank  = [boolean = [default = F]],
    sumspec    = [boolean = [default = F]]]

  if (!streq(field_names(pchek), field_names(parameters()))) {
    print spaste(self.file, ': internal inconsistency - pchek field names.')
  }

  # Version information maintained by RCS.
  wrk := [=]
  wrk.RCSid    := "$Revision: 19.21 $$Date: 2006/07/13 06:34:35 $"
  wrk.version  := spaste(wrk.RCSid[2], ', ', wrk.RCSid[4])
  wrk.lastexit := './livedata.lastexit/pksmonitor.lastexit'

  # Work variables.
  wrk.locked   := F
  wrk.newdata  := F
  wrk.nrec     := 0
  wrk.begun    := [F,F]
  wrk.failed   := [F,F]
  wrk.reset1   := [=]
  wrk.reset2   := [=]
  wrk.imageID  := array(0,6)	# Allow three MBVis history buffers.
  wrk.MBVprefs :=
    ['topForm.twinviewpopup.form.sliceMenu.setChoice:XZ',
     'topForm.twinviewpopup.form.profileDirMenu.setChoice:X',
     'topForm.zoomPolicyPopup.form.fixAspectToggle.state:False']
     # Also, but MultibeamView doesn't recognise the following:
     # 'topForm.dressingControlPopup.form.displayAxisLabelsToggle.state:True'

  # GUI widgets.
  gui := [f1 = F]

  #---------------------------------------------------------------------------
  # Local function definitions.
  #---------------------------------------------------------------------------
  local getdisp, helpmsg, readgui, set := [=], sethelp, setparm, showgui,
        showmenu

  #------------------------------------------------------------------- getdisp

  # Pop up a GUI to choose between viewers.

  const getdisp := function()
  {
    wider wrk

    wrk.useMBView := F
    wrk.useMBVis  := F
    wrk.useViewer := F

    if (has_field(environ, 'LIVEDATA_VIEWER')) {
      if (environ.LIVEDATA_VIEWER == 'MultibeamVis') {
        wrk.useMBVis  := T
        return
      } else if (environ.LIVEDATA_VIEWER == 'MultibeamView') {
        wrk.useMBView := T
        return
      } else if (environ.LIVEDATA_VIEWER == 'aips++ Viewer') {
        wrk.useViewer := T
        return
      }
    }

    if (has_field(environ, 'KARMALIBPATH')) {
      if (len(stat(spaste(environ.KARMALIBPATH,
                          '/shared-objects/kvis-multibeam.so'))) != 0) {
        # MultibeamVis is available.
        MBVis := T
      }
    }

    if (len(shell('hash MultibeamView 2>&1')) == 0) {
      # MultibeamView is available.
      MBView := T
    }

    if (len(shell('hash viewer 2>&1')) == 0) {
      # The aips++ viewer is available.
      Viewer := T
    }

    t := MBView + MBVis + Viewer
    if (t == 0) {
      fail 'ERROR: No viewer appears to be available.'
      return

    } else if (t == 1) {
      wrk.useMBView := MBView
      wrk.useMBVis  := MBVis
      wrk.useViewer := Viewer
      return
    }

    gui := [=]

    tk_hold()
    gui.f1 := frame(title='Display selection')
    gui.f1->grab('local')

    gui.f11  := frame(gui.f1, borderwidth=4, relief='ridge')
    gui.f111 := frame(gui.f11, padx=20, pady=10)
    gui.la   := label(gui.f111, 'Please select the display type to use',
                     justify='center')

    gui.f1111 := frame(gui.f111, relief='ridge')
    gui.MBVis.bn  := button(gui.f1111, 'MultibeamVis (kvis)', fill='x',
                            value='useMBVis',  disabled=!MBVis)
    gui.MBView.bn := button(gui.f1111, 'MultibeamView (kview)', fill='x',
                            value='useMBView', disabled=!MBView)
    gui.Viewer.bn := button(gui.f1111, 'aips++ Viewer', fill='x',
                            value='useViewer', disabled=!Viewer)

    whenever
      gui.MBView.bn->press,
      gui.MBVis.bn->press,
      gui.Viewer.bn->press do
        wrk[$value] := T


    tk_release()
    await gui.MBView.bn->press, gui.MBVis.bn->press, gui.Viewer.bn->press

    gui := F
    return
  }

  #------------------------------------------------------------------- helpmsg

  # Write a widget help message.

  const helpmsg := function(msg='')
  {
    if (is_agent(gui.helpmsg)) gui.helpmsg->text(msg)
  }

  #------------------------------------------------------------------- readgui

  # Read values from entry boxes.

  const readgui := function() {
    wider parms

    if (is_agent(gui.f1)) {
      setparm([maxspec    = gui.maxspec.en->get(),
               averlength = gui.averlength.en->get(),
               chanstart  = gui.chanstart.en->get(),
               chanend    = gui.chanend.en->get(),
               chanskip   = gui.chanskip.en->get()])
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

  #----------------------------------------------------------------- set.beams

  # Set the mask of beams present in the data.

  const set.beams := function(value)
  {
    wider parms

    parms.beams := value

    setparm([beamsel = parms.beamsel])
  }

  #--------------------------------------------------------------- set.chanend

  # Set the upper channel range selection.

  const set.chanend := function(value)
  {
    wider parms

    if (is_integer(value)) {
      parms.chanend := value
    } else {
      parms.chanend := 0
    }
  }

  #------------------------------------------------------------- set.chanstart

  # Set the lower channel range selection.

  const set.chanstart := function(value)
  {
    wider parms

    if (is_integer(value)) {
      parms.chanstart := value
    } else {
      parms.chanstart := 0
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

    } else if (parms.config == 'CONTINUUM') {
      setparm([sumspec = T])

    } else if (any(parms.config == "GASS HIPASS HVC ZOA")) {
      setparm([sumspec = F])

    } else if (parms.config == 'MOPRA') {
      setparm([beamsel = [T,F,F,F,F,F,F,F,F,F,F,F,F],
               sumspec = F])

    } else if (parms.config == 'METHANOL') {
      setparm([beamsel = [T,T,T,T,T,T,T,F,F,F,F,F,F],
               sumspec = F])

    } else if (parms.config == 'AUDS') {
      setparm([beamsel   = [T,T,T,T,T,T,T,T,F,F,F,F,F],
               chanskip  = 1,
               cfreq     = T,
               ctime     = T,
               flagblank = T,
               sumspec   = F])
    }
  }

  #------------------------------------------------------------------- showgui

  # Build a graphical user interface for the monitor client.
  #
  # If the GUI was created and still exists from a previous invokation it will
  # simply be raised to the top of the window stack.
  #
  # If the GUI needs to be created and the parent frame is not specified a
  # separate window will be created.
  #
  # If the help variable is T a separate label will be created for widget help
  # messages.  Alternatively, an agent variable may be specified for a help
  # message label widget created elsewhere.

  const showgui := function(parent=F)
  {
    wider gui, parms, wrk

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
      gui.f1 := frame(title='Parkes multibeam data monitor', expand='none')

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

    gui.f11  := frame(gui.f1, relief='ridge', borderwidth=4, expand='both')
    gui.f111  := frame(gui.f11, relief='ridge')

    gui.title.ex := button(gui.f111, 'DATA MONITOR', relief='flat',
                           borderwidth=0, foreground='#0000a0')
    sethelp(gui.title.ex, spaste('Control panel (v', wrk.version,
      ') for the monitor client; PRESS FOR USAGE!'))

    whenever
      gui.title.ex->press do
        explain(self.file, 'USAGE')

    gui.f1111 := frame(gui.f111, side='left', expand='none')

    # Beam selection ---------------------------------------------------------
    gui.f11111 := frame(gui.f1111, borderwidth=0)
    gui.f111111 := frame(gui.f11111, borderwidth=0, expand='none')
    gui.beamsel.la := label(gui.f111111, 'Beams', padx=5,
                            foreground='#b03060')
    sethelp(gui.beamsel.la, 'Beam selection panel.')
    gui.f111112 := frame(gui.f11111, width=0)

    # Define a record with 13 fields.
    gui.beamsel.bn := [=]
    for (j in 1:13) gui.beamsel.bn[j] := F

    gui.f11112 := frame(gui.f1111, borderwidth=0)
    gui.f111121 := frame(gui.f11112, height=35, width=0, expand='none')
    gui.beamsel.bn[8]  := button(gui.f11112, '8', value=8,  width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[8], 'Select or deselect display for beam 8.')

    gui.f11113 := frame(gui.f1111, borderwidth=0)
    gui.beamsel.bn[13] := button(gui.f11113, '13', value=13, width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[13], 'Select or deselect display for beam 13.')
    gui.beamsel.bn[7]  := button(gui.f11113,  '7', value=7,  width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[7], 'Select or deselect display for beam 7.')
    gui.beamsel.bn[2]  := button(gui.f11113,  '2', value=2,  width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[2], 'Select or deselect display for beam 2.')
    gui.beamsel.bn[9]  := button(gui.f11113,  '9', value=9,  width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[9], 'Select or deselect display for beam 9.')

    gui.f11114  := frame(gui.f1111, borderwidth=0)
    gui.f111141 := frame(gui.f11114, height=10, width=0, expand='none')
    gui.beamsel.bn[6]  := button(gui.f11114,  '6', value=6,  width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[6], 'Select or deselect display for beam 6.')
    gui.beamsel.bn[1]  := button(gui.f11114,  '1', value=1,  width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[1], 'Select or deselect display for beam 1.')
    gui.beamsel.bn[3]  := button(gui.f11114,  '3', value=3,  width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[3], 'Select or deselect display for beam 3.')

    gui.f11115 := frame(gui.f1111, borderwidth=0)
    gui.beamsel.bn[12] := button(gui.f11115, '12', value=12, width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[12], 'Select or deselect display for beam 12.')
    gui.beamsel.bn[5]  := button(gui.f11115,  '5', value=5,  width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[5], 'Select or deselect display for beam 5.')
    gui.beamsel.bn[4]  := button(gui.f11115,  '4', value=4,  width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[4], 'Select or deselect display for beam 4.')
    gui.beamsel.bn[10] := button(gui.f11115, '10', value=10, width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[10], 'Select or deselect display for beam 10.')

    gui.f11116  := frame(gui.f1111, borderwidth=0)
    gui.f111161 := frame(gui.f11116, height=35, width=0, expand='none')
    gui.beamsel.bn[11] := button(gui.f11116, '11', value=11, width=1,
                                 padx=4, pady=1)
    sethelp(gui.beamsel.bn[11], 'Select or deselect display for beam 11.')

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

    #=========================================================================
    # Processing options.
    gui.f112  := frame(gui.f11, relief='ridge', expand='x')
    gui.f1121 := frame(gui.f112, expand='none', borderwidth=0)

    # Number of spectra to display -------------------------------------------
    gui.f11211 := frame(gui.f1121, side='right', borderwidth=0)
    gui.maxspec.en := entry(gui.f11211, justify='right', width=4,
                            relief='sunken')
    sethelp(gui.maxspec.en, 'Maximum number of spectra to display.')
    gui.maxspec.la := label(gui.f11211, 'Number of spectra')

    whenever
      gui.maxspec.en->return do
        setparm([maxspec = $value])

    # IF selection -----------------------------------------------------------
    gui.f11212 := frame(gui.f1121, side='left', borderwidth=0, expand='x')

    gui.if.la  := label(gui.f11212, 'IF(s)', anchor='e', fill='x')
    gui.if1.bn := button(gui.f11212, type='menu', width=6, relief='groove')
    sethelp(gui.if1.bn, 'IF selection for monitor window 1.')
    showmenu('if1')

    gui.if2.bn := button(gui.f11212, type='menu', width=6, relief='groove')
    sethelp(gui.if2.bn, 'IF selection for monitor window 2.')
    showmenu('if2')

    # Polarization selection -------------------------------------------------
    gui.f11213 := frame(gui.f1121, side='left', borderwidth=0, expand='x')

    gui.pol.la  := label(gui.f11213, 'Polarization', anchor='e', width=10)
    gui.pol1.bn := button(gui.f11213, type='menu', width=6, relief='groove')
    sethelp(gui.pol1.bn, 'Polarization selection for window 1.')
    showmenu('pol1')

    gui.pol2.bn := button(gui.f11213, type='menu', width=6, relief='groove')
    sethelp(gui.pol2.bn, 'Polarization selection for window 2.')
    showmenu('pol2')

    # Time averaging ---------------------------------------------------------
    gui.f11214 := frame(gui.f1121, side='left', borderwidth=0, expand='x')

    gui.timemode.la := label(gui.f11214, 'Averaging', anchor='e', width=10)
    gui.timemode.bn := button(gui.f11214, type='menu', width=9, pady=2,
                              relief='groove')
    sethelp(gui.timemode.bn, 'Statistic computed for each channel over the \
      specified no. of integrations; one spectrum is displayed for each \
      group.')
    showmenu('timemode')

    gui.averlength.en := entry(gui.f11214, justify='right', width=3,
                               relief='sunken', fill='x')
    sethelp(gui.averlength.en, 'Number of integrations to combine in time \
                                averaging display modes.')

    whenever
      gui.averlength.en->return do
        setparm([averlength = $value])

    # Spectral filtering -----------------------------------------------------
    gui.f11215 := frame(gui.f1121, side='left', borderwidth=0, expand='x')

    gui.freqmode.la := label(gui.f11215, 'Filtering', anchor='e', width=10)
    gui.freqmode.bn := button(gui.f11215, type='menu', width=12,
                              relief='groove', pady=2, fill='x')
    sethelp(gui.freqmode.bn, 'Spectral filtering mode.')
    showmenu('freqmode')

    # Channel range to display -----------------------------------------------
    gui.f11216 := frame(gui.f1121, side='left', borderwidth=0, expand='x')

    gui.chanRange.la := label(gui.f11216, 'Channels', padx=2)
    gui.chanstart.en := entry(gui.f11216, justify='right', width=5,
                              relief='sunken')
    sethelp(gui.chanstart.en, 'First channel to display; use zero or a \
      negative value for offset from last channel in data.')

    whenever
      gui.chanstart.en->return do
        setparm([chanstart = $value])

    gui.range.la := label(gui.f11216, '-', padx=2)

    gui.chanend.en := entry(gui.f11216, justify='right', width=5,
                            relief='sunken')

    sethelp(gui.chanend.en, 'Last channel to display; use zero or a negative \
      value for offset from last channel in data.')

    whenever
      gui.chanend.en->return do
        setparm([chanend = $value])

    gui.chanskip.la := label(gui.f11216, ':', padx=2)
    gui.chanskip.en := entry(gui.f11216, justify='right', width=3,
                             relief='sunken')
    sethelp(gui.chanskip.en, 'Channel increment, display every Nth channel \
      (for efficiency).  If zero, choose a suitable value.')

    whenever
      gui.chanskip.en->press do
        setparm([chanskip = $value])

    #=========================================================================
    # Display options.

    # Display frequency axis? ------------------------------------------------
    gui.cfreq.bn := button(gui.f1121, 'Frequency axis', anchor='w',
                           type='check', pady=2, fill='x')
    sethelp(gui.cfreq.bn, 'Display scans with a frequency axis, interleaved \
      for frequency-switched data?  Else channel.')

    whenever
      gui.cfreq.bn->press do
        setparm([cfreq = gui.cfreq.bn->state()])

    # Display in time sequence? ----------------------------------------------
    gui.ctime.bn := button(gui.f1121, 'Time axis', anchor='w', type='check',
                           pady=2, fill='x')
    sethelp(gui.ctime.bn, 'Display scans in timestamp sequence?  Else in \
      scan sequence.')

    whenever
      gui.ctime.bn->press do
        setparm([ctime = gui.ctime.bn->state()])

    # Blank flagged data? ----------------------------------------------------
    gui.flagblank.bn := button(gui.f1121, 'Blank flagged data', anchor='w',
                               type='check', pady=2, fill='x')
    sethelp(gui.flagblank.bn, 'Set flagged data values to blank for display \
      as a means of identifying them?')

    whenever
      gui.flagblank.bn->press do
        setparm([flagblank = gui.flagblank.bn->state()])

    # Display sum spectrum? --------------------------------------------------
    gui.sumspec.bn := button(gui.f1121, 'Show sum spectrum', anchor='w',
                             type='check', pady=2, fill='x')
    sethelp(gui.sumspec.bn, 'Display the sum of the selected channel range \
      in the first channel of the display?')

    whenever
      gui.sumspec.bn->press do
        setparm([sumspec = gui.sumspec.bn->state()])

    #=========================================================================
    # Widget help messages.
    if (gui.dohelp) {
      if (!is_agent(gui.helpmsg)) {
        gui.f113 := frame(gui.f11, relief='ridge')
        gui.helpmsg := label(gui.f113, '', font='courier', width=1, fill='x',
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

  #------------------------------------------------------------------ showmenu

  # Build a menu for a parameter from its valid values.

  const showmenu := function(parm, labels="", add=T)
  {
    wider gui

    if (field_names(pchek[parm])[1] == 'boolean') {
      valid := [T, F]
    } else {
      valid := ref(pchek[parm][1].valid)
    }

    dolbl := (len(labels) == len(valid))
    verbatim := dolbl & !add

    i := 0
    for (v in valid) {
      i +:= 1
      t := spaste(parm, '_', i)

      if (verbatim) {
        lbl := labels[i]
      } else {
        lbl := as_string(v)
        if (dolbl) {
          lbl := spaste(lbl, ': ', labels[i])
        }
      }

      gui[t].bn := button(gui[parm].bn, lbl, value=v)

      whenever
        gui[t].bn->press do {
          rec[parm] := $value
          setparm(rec)
        }
    }
  }

  #---------------------------------------------------------- gui.beamsel.show

  # Show the mask of beams which are selected (subject to their presence in
  # the data).

  const gui.beamsel.show := function()
  {
    tk_hold()
    if (wrk.locked) gui.f1->enable()

    for (j in 1:13) {
      if (parms.beams[j]) {
        gui.beamsel.bn[j]->foreground('#000000')
        gui.beamsel.bn[j]->disabled(F)
        if (parms.beamsel[j]) {
          gui.beamsel.bn[j]->background('#00b3a0')
        } else {
          gui.beamsel.bn[j]->background('#d9d9d9')
        }
        gui.beamsel.bn[j]->relief('raised')
      } else {
        gui.beamsel.bn[j]->disabled(T)
        gui.beamsel.bn[j]->background('#d9d9d9')
        gui.beamsel.bn[j]->relief('flat')
      }
    }

    if (wrk.locked) gui.f1->disable()
    tk_release()
  }

  #---------------------------------------------------------- gui.chanend.show

  # Show the upper channel selection.

  const gui.chanend.show := function()
  {
    gui.chanend.en->delete('start', 'end')
    if (parms.chanend == 0) {
      gui.chanend.en->insert('end')
    } else {
      gui.chanend.en->insert(as_string(parms.chanend))
    }
  }

  #-------------------------------------------------------- gui.chanstart.show

  # Show the lower channel selection.

  const gui.chanstart.show := function()
  {
    gui.chanstart.en->delete('start', 'end')
    if (parms.chanstart == 0) {
      gui.chanstart.en->insert('end')
    } else {
      gui.chanstart.en->insert(as_string(parms.chanstart))
    }
  }

  #--------------------------------------------------------- gui.timemode.show

  # Show the time averaging mode.

  const gui.timemode.show := function()
  {
    tk_hold()
    if (wrk.locked) gui.f1->enable()

    gui.timemode.bn->text(parms.timemode)
    if (parms.timemode == 'NONE') {
      gui.averlength.la->foreground('#a3a3a3')
      gui.averlength.en->foreground('#a3a3a3')
      gui.averlength.en->disabled(T)
    } else {
      gui.averlength.la->foreground('#000000')
      gui.averlength.en->foreground('#000000')
      gui.averlength.en->disabled(F)
    }

    if (wrk.locked) gui.f1->disable()
    tk_release()
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
    self->lock do {
      if (!wrk.locked) {
        wrk.locked := T
        if (is_agent(gui.f1)) gui.f1->disable()
      }
    }

  # Enable parameter entry.
  whenever
    self->unlock do {
      if (wrk.locked) {
        if (is_agent(gui.f1)) gui.f1->enable()
        wrk.locked := F
      }

      setparm([beams = [T,T,T,T,T,T,T,T,T,T,T,T,T]])
    }

  # Initialize the monitor client.
  whenever
    self->init do {
      setparm($value)
      readgui()
      wrk.client->init(parms)

      # Signal reinitialization of the display clients.
      wrk.newdata := F
      wrk.nrec    := 0
      wrk.begun   := [F,F]
      wrk.reset1  := [=]
      wrk.reset2  := [=]

      if (wrk.useMBVis && (nID := len(wrk.imageID)) > 2) {
        # We maintain a number of history buffers in MultibeamVis.
        for (iID in wrk.imageID[[-1,0]+nID]) {
          if (iID != 0) wrk.display1->scrollBufDestroy(iID)
        }

        wrk.imageID[3:nID] := wrk.imageID[1:(nID-2)]
      }
      wrk.imageID[1:2] := 0
    }

  # Display data.
  whenever
    self->newdata do {
      if (any(wrk.failed)) {
        self->newdataProcessed(0)
      } else {
        wrk.client->newdata($value)
      }
    }

  # Flush data.
  whenever
    self->flush do {
      if (any(wrk.failed)) {
        self->flushProcessed()
      } else {
        wrk.client->flush($value)
      }
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
      readgui()
      store(parms, wrk.lastexit)

      deactivate whenever_stmts(wrk.client).stmt
      deactivate whenever_stmts(wrk.display1).stmt
      deactivate whenever_stmts(wrk.display2).stmt

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
  args := [config     = 'GENERAL',
           client_dir = client_dir,
           beams      = beams,
           IFs        = IFs,
           npols      = npols,
           nchans     = nchans,
           beamsel    = beamsel,
           maxspec    = maxspec,
           if1        = if1,
           if2        = if2,
           pol1       = pol1,
           pol2       = pol2,
           timemode   = timemode,
           averlength = averlength,
           freqmode   = freqmode,
           chanstart  = chanstart,
           chanend    = chanend,
           chanskip   = chanskip,
           cfreq      = cfreq,
           ctime      = ctime,
           flagblank  = flagblank,
           sumspec    = sumspec]

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

  #------------------------------------------------------------ monitor client

  # Determine the type of display to use.
  getdisp()

  if (parms.client_dir == '') {
    wrk.client := client('pksmonitor')
  } else {
    wrk.client := client(spaste(parms.client_dir, '/pksmonitor'))
  }
  wrk.client.name := 'pksmonitor'

  # Pass most events through.
  whenever
    wrk.client->* do {
      if ($name == 'scrollBuf1') {
        if (wrk.begun[1]) {
          if (wrk.imageID[1] == 0) {
            # Wait till display1 has been reset.
            wrk.reset1[len(wrk.reset1)+1] := $value
            await self->reset1
          }

          wrk.display1->scrollBufAddImage(wrk.imageID[1], $value)

        } else {
          wrk.display1->scrollBufBegin($value, parms.maxspec)
          wrk.begun[1] := T
        }

      } else if ($name == 'scrollBuf2') {
        if (wrk.begun[2]) {
          if (wrk.imageID[2] == 0) {
            # Wait till display2 has been reset.
            wrk.reset2[len(wrk.reset2)+1] := $value
            await self->reset2
          }

          wrk.display2->scrollBufAddImage(wrk.imageID[2], $value)

        } else {
          wrk.display2->scrollBufBegin($value, parms.maxspec)
          wrk.begun[2] := T
        }

      } else if ($name == 'newdataProcessed' &&
                 any(wrk.imageID[1:2][wrk.begun] == 0)) {
        # Defer acknowledgement until the displays are initialized.
        wrk.newdata := T
        wrk.nrec +:= $value

      } else {
        self->[$name]($value)
      }
    }

  #---------------------------------------------------------- Display client 1

  # Start the first display client.
  if (wrk.useMBVis) {
    # kvis in its MultibeamVis incarnation.
    wrk.display1 := client("kvis -MultiBeam -no_initial_data_browser",
         "-xrm *advancedDataBrowserShell*showNewDataAsImageToggle.state:True",
         "-xrm *ZoomPolicy*fixAspectToggle.state:False",
         "-xrm *displayAxisLabelsToggle.state:True",
         "-xrm *sliceMenu.setChoice:XZ",
         "-xrm *profileDirMenu.setChoice:X",
         "-create_at_init -new_window slave_cmap")

  } else if (wrk.useMBView) {
    wrk.display1 := client("MultibeamView -num_colours 160")

  } else {
    include 'pksviewer.g'
    wrk.display1 := pksviewer(ID=1, title='Polarization A')
  }

  if (is_fail(wrk.display1)) {
    fail 'Failed to start display client #1.'
  }
  wrk.display1.name := 'display1'

  if (wrk.useMBView || wrk.useMBVis) {
    print 'Awaiting karmaPortNumber'
    await wrk.display1->karmaPortNumber
    wrk.port1 := $value

    if (wrk.useMBVis) {
      print 'Awaiting MultibeamVis initialization'
    } else {
      print 'Awaiting MultibeamView initialization'
    }

    await wrk.display1->initialised

    # Set MultibeamVis/View display preferences.
    if (wrk.useMBView) {
      for (pref in wrk.MBVprefs) {
        wrk.display1->setXtResource(pref)
      }
    }
  }

  # Display 1 has been reset.
  whenever
    wrk.display1->imageID do {
      # For MultibeamVis, wrk.display2 is a reference to wrk.display1
      # so we need to discard this event when it is triggered in response to
      # wrk.display2->scrollBufBegin.

      if (wrk.begun[1] && wrk.imageID[1] == 0) {
        if (wrk.useMBView) {
          # MultibeamView does not return a value.
          wrk.imageID[1] := 1
        } else {
          wrk.imageID[1] := $value
        }

        if (wrk.imageID[2] != 0 || !wrk.begun[2]) {
          # The other display has also been reset or is not being used.
          if (wrk.newdata) self->newdataProcessed(wrk.nrec)
        }

        # Unwind the reset1 await stack.
        i := 1
        while (i <= len(wrk.reset1)) {
          self->reset1(wrk.reset1[i])
          i +:= 1
        }
        wrk.reset1 := [=]
      }
    }

  # Display failure.
  whenever
    wrk.display1->fail do {
      wrk.failed[1] := T
      self->fail1($value)
    }

  #---------------------------------------------------------- Display client 2

  # Start the second display client.
  if (wrk.useMBVis) {
    # Create a reference to wrk.display1.
    wrk.display2 := ref wrk.display1

  } else if (wrk.useMBView) {
    # Use shared colourmap.
    wrk.display2 := client("MultibeamView", '-cmap_master',
                            spaste('unix:', as_string(wrk.port1)))

    if (is_fail(wrk.display2)) {
      fail 'Failed to start display client #2.'
    }
    wrk.display2.name := 'display2'

    print 'Awaiting MultibeamView initialization'
    whenever wrk.display2->karmaPortNumber do {}
    await wrk.display2->initialised

    # Set MultibeamView display preferences.
    for (pref in wrk.MBVprefs) {
      wrk.display2->setXtResource(pref)
    }

  } else {
    wrk.display2 := pksviewer(ID=2, title='Polarization B')

    if (is_fail(wrk.display2)) {
      fail 'Failed to start display client #2.'
    }
    wrk.display2.name := 'display2'
  }

  # Display 2 has been reset.
  whenever
    wrk.display2->imageID do {
      # For MultibeamVis, wrk.display2 is just a reference to wrk.display1
      # so we need to discard this event when it is triggered in response to
      # wrk.display1->scrollBufBegin.

      if (!wrk.useMBVis || (wrk.begun[2] && wrk.imageID[1] != $value)) {
        if (wrk.useMBView) {
          # MultibeamView does not return a value.
          wrk.imageID[2] := 1
        } else {
          wrk.imageID[2] := $value
        }

        if (wrk.imageID[1] != 0 || !wrk.begun[1]) {
          # The other display has also been reset or is not being used.
          if (wrk.newdata) self->newdataProcessed(wrk.nrec)
        }

        # Unwind the reset2 await stack.
        i := 1
        while (i <= len(wrk.reset2)) {
          self->reset2(wrk.reset2[i])
          i +:= 1
        }
        wrk.reset2 := [=]
      }
    }

  # Display failure.
  whenever
    wrk.display2->fail do {
      wrk.failed[2] := T
      self->fail2($value)
    }
}
