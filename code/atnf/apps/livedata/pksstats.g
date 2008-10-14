#-----------------------------------------------------------------------------
# pksstats.g: Controller and plotter for the livedata statistics client.
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
# $Id: pksstats.g,v 19.8 2006/06/23 05:04:08 mcalabre Exp $
#-----------------------------------------------------------------------------
# -------------------------------------------------------------------- <USAGE>
# Controller and plotter for the livedata statistics client.
#
# Arguments:
#    client_dir        string   Directory containing client executable.  May
#                               be blank to use PATH.
#    directory         string   Output directory.
#    file              string   Output file name, without extension.
#    startChan         int      Start spectral channel; zero or negative value
#                               specifies an offset from the last channel,
#                      string   can also be specified as 'end' or 'last'.
#    endChan           int      End spectral channel; zero or negative value
#                               specifies an offset from the last channel,
#                      string   can also be specified as 'end' or 'last'.
#    plottype          string   The statistic to be plotted:
#                                  COUNT     ...Number of unmasked channels.
#                                  TSYS      ...System Temperature (Jy).
#                                  MEAN      ...Spectral mean value (Jy).
#                                  MEDIAN    ...Spectral median value (Jy).
#                                  RMS       ...Spectral RMS value (Jy).
#                                  QUARTILE  ...Interquartile range (Jy).
#                                  MAXIMUM   ...Maximum and,
#                                  MINIMUM   ...Minimum values in the
#                                               spectrum (Jy).
#    plotpols          string   Polarizations selected for plotting:
#                                   A        ...A only.
#                                   B        ...B only.
#                                  A&B       ...A and B aggregated.
#                                  A+B       ...(A+B)/2.
#                                  A-B       ...(A-B)/2 (the difference is
#                                               divided by 2 to give the
#                                               same noise characteristics as
#                                               the average).
#    plotbeam          bool[13] Beams selected for plotting.
#
# Received events:
#    accumulate(record)  Accumulate data.
#    hidegui()           Make the GUI invisible.
#    init()              Initialize the statistics client.  Parameter values
#                        may optionally be specified.
#    lock()              Disable parameter entry.
#    plotparm(string)    Set plot-selection related parameter values; these
#                        may be changed at any time.
#    printparms()        Print parameters for the statistics client.
#    printvalid()        Print parameter validation rules.
#    save()              Save the current plot.
#    setparm(record)     Set parameter values for the statistics client.
#    showgui(agent)      Create the GUI or make it visible if it already
#                        exists.  The parent frame may be specified.
#    stats()             Compute statistics of accumulated data.
#    terminate()         Close down.
#    unlock()            Enable parameter entry.
#
# Sent events:
#    accumulate_error()  Error accumulating data.
#    accumulated()       Data has been accumulated.
#    done()              Agent has terminated.
#    finished()          Finished computing statistics.
#    guiready()          GUI construction complete.
#    initialized()       Initialization complete.
#    log(record)         Log message.
# -------------------------------------------------------------------- <USAGE>
#-----------------------------------------------------------------------------

pragma include once

include 'pkslib.g'

const pksstats := subsequence(client_dir = '',
                              directory  = '.',
                              file       = 'unspecified',
                              startChan  = 1,
                              endChan    = 0,
                              plottype   = 'Tsys',
                              plotpols   = 'A&B',
                              plotbeam   = array(T,13)) : [reflect=T]
{
  # Our identity.
  self.name := 'stats'

  for (j in system.path.include) {
    self.file := spaste(j, '/pksstats.g')
    if (len(stat(self.file))) break
  }

  # Parameter values.
  parms := [=]

  # Parameter value checking.
  pchek := [
    client_dir = [string  = [default = '']],
    directory  = [string  = [default = '.',
                             invalid = '']],
    file       = [string  = [default = 'unspecified',
                             invalid = '']],
    startChan  = [integer = [default = 1,
                             minimum = -4096,
                             maximum =  4096],
                  string  = [valid   = "end last"]],
    endChan    = [integer = [default = 0,
                             minimum = -4096,
                             maximum =  4096],
                  string  = [valid   = "end last"]],
    plottype   = [string  = [default = 'Tsys',
                             valid   = "COUNT TSYS MEAN MEDIAN RMS QUARTILE \
                                        MAXIMUM MINIMUM"]],
    plotpols   = [string  = [default = 'A&B',
                             valid   = "A B A&B A+B A-B"]],
    plotbeam   = [boolean = [default = [T,T,T,T,T,T,T,T,T,T,T,T,T]]]]

  if (!streq(field_names(pchek), field_names(parameters()))) {
    print spaste(self.file, ': internal inconsistency - pchek field names.')
  }

  # Version information maintained by RCS.
  wrk := [=]
  wrk.RCSid    := "$Revision: 19.8 $$Date: 2006/06/23 05:04:08 $"
  wrk.version  := spaste(wrk.RCSid[2], ', ', wrk.RCSid[4])
  wrk.lastexit := './livedata.lastexit/pksstats.lastexit'

  # Work variables.
  wrk.locked := F

  # Colour palette for each beam and polarization.
  wrk.palette := [
    backg = '#000000',
    foreg = '#ffffff',
    b01p1 = '#ffcc00',
    b02p1 = '#ffaa00',
    b03p1 = '#ff8800',
    b04p1 = '#ff6600',
    b05p1 = '#ff4400',
    b06p1 = '#ff2211',
    b07p1 = '#ff0033',
    b08p1 = '#ff0055',
    b09p1 = '#ff0077',
    b10p1 = '#ff0099',
    b11p1 = '#ff00bb',
    b12p1 = '#ff00dd',
    b13p1 = '#ff00ff',
    b01p2 = '#00ffff',
    b02p2 = '#00ffdd',
    b03p2 = '#00ffbb',
    b04p2 = '#00ff99',
    b05p2 = '#00ff77',
    b06p2 = '#00ff55',
    b07p2 = '#00ff33',
    b08p2 = '#00cc55',
    b09p2 = '#00aa77',
    b10p2 = '#007799',
    b11p2 = '#0044bb',
    b12p2 = '#0011dd',
    b13p2 = '#0000ff']

  wrk.beams    := [T,T,T,T,T,T,T,T,T,T,T,T,T]
  wrk.dindx    := 0
  wrk.dmin     := 0.0
  wrk.dmax     := 1.0
  wrk.pindx    := 1
  wrk.plotpols := 'A&B'
  wrk.polcode  := 1:2
  wrk.pols     := [T,T]
  wrk.pscount  := 0
  wrk.t0       := 0.0
  wrk.tinteg   := 0.0
  wrk.tspan    := 0.0

  wrk.time     := array(0.0,120)
  wrk.COUNT    := array(  0,13,2,120)
  wrk.TSYS     := array(0.0,13,2,120)
  wrk.MEAN     := array(0.0,13,2,120)
  wrk.MEDIAN   := array(0.0,13,2,120)
  wrk.RMS      := array(0.0,13,2,120)
  wrk.QUARTILE := array(0.0,13,2,120)
  wrk.MAXIMUM  := array(0.0,13,2,120)
  wrk.MINIMUM  := array(0.0,13,2,120)

  # GUI widgets.
  gui := [f1 = F]

  #---------------------------------------------------------------------------
  # Local function definitions.
  #---------------------------------------------------------------------------
  local encache, helpmsg, hex2dec, hexcol, lock, plot, readgui, reset, save,
        set := [=], sethelp, setparm, showgui

  #------------------------------------------------------------------- encache

  # encache() saves data for subsequent plotting.
  #
  # Given:
  #    value      record   Data record returned from the stats client.  The
  #                        record may contain multiple fields with names of
  #                        the form
  #
  #                          intNN
  #
  #                        where 'NN' is the integration number.  The value of
  #                        these fields is also a record containing
  #
  #                          TIME
  #                          COUNT
  #                          TSYS
  #                          MEAN
  #                          MEDIAN
  #                          RMS
  #                          QUARTILE
  #                          MAXIMUM
  #                          MINIMUM
  #
  #                        where TIME is a double containing the MJD(UTC) in
  #                        seconds and the others are arrays of dimension
  #                        [13,2] containing one value per beam and
  #                        polarization.

  const encache := function(value)
  {
    wider wrk

    if (wrk.dindx == 0) {
      # Set time origin.
      wrk.t0 := 86400.0 * as_integer(value[1].TIME / 86400.0)

      # What beams and polarizations are present?
      present   := value[1].TSYS != 0.0
      wrk.beams := present[1:13,1] | present[1:13,2]
      beams     := (1:13)[wrk.beams]
      wrk.pols  := [[all(present[beams,1]), all(present[beams,2])]]

      # Update plot selection based on availability.
      setparm([plotpols = wrk.plotpols, plotbeam = parms.plotbeam])
    }

    for (int in ind(value)) {
      if (wrk.dindx == 120) {
        # X-scroll by 20.
        wrk.time[1:100] := wrk.time[21:120]

        wrk.COUNT[1:13,1:2,1:100]    := wrk.COUNT[1:13,1:2,21:120]
        wrk.TSYS[1:13,1:2,1:100]     := wrk.TSYS[1:13,1:2,21:120]
        wrk.MEAN[1:13,1:2,1:100]     := wrk.MEAN[1:13,1:2,21:120]
        wrk.MEDIAN[1:13,1:2,1:100]   := wrk.MEDIAN[1:13,1:2,21:120]
        wrk.RMS[1:13,1:2,1:100]      := wrk.RMS[1:13,1:2,21:120]
        wrk.QUARTILE[1:13,1:2,1:100] := wrk.QUARTILE[1:13,1:2,21:120]
        wrk.MAXIMUM[1:13,1:2,1:100]   := wrk.MAXIMUM[1:13,1:2,21:120]
        wrk.MINIMUM[1:13,1:2,1:100]   := wrk.MINIMUM[1:13,1:2,21:120]

        wrk.dindx := 100
        wrk.pindx := 1
      }

      # Store the data.
      wrk.dindx +:= 1
      wrk.time[wrk.dindx] := value[int].TIME - wrk.t0
      wrk.COUNT[1:13,1:2,wrk.dindx]    := value[int].COUNT
      wrk.TSYS[1:13,1:2,wrk.dindx]     := value[int].TSYS
      wrk.MEAN[1:13,1:2,wrk.dindx]     := value[int].MEAN
      wrk.MEDIAN[1:13,1:2,wrk.dindx]   := value[int].MEDIAN
      wrk.RMS[1:13,1:2,wrk.dindx]      := value[int].RMS
      wrk.QUARTILE[1:13,1:2,wrk.dindx] := value[int].QUARTILE
      wrk.MAXIMUM[1:13,1:2,wrk.dindx]  := value[int].MAXIMUM
      wrk.MINIMUM[1:13,1:2,wrk.dindx]  := value[int].MINIMUM
    }
  }

  #------------------------------------------------------------------ helpmsg

  # Write a widget help message.

  const helpmsg := function(msg='')
  {
    if (is_agent(gui.helpmsg)) gui.helpmsg->text(msg)
  }

  #------------------------------------------------------------------- hex2dec

  # Hexadecimal to decimal integer conversion.
  #
  # Given
  #    hexval   string[]   Hexadecimal values.
  #
  # Returned
  #    Vector of decimal integers.

  const hex2dec := function(hexval)
  {
    s := []
    for (j in ind(hexval)) {
      h := split(hexval[j], '')

      h ~:= s/a|A/10/g
      h ~:= s/b|B/11/g
      h ~:= s/c|C/12/g
      h ~:= s/d|D/13/g
      h ~:= s/e|E/14/g
      h ~:= s/f|F/15/g

      h := as_integer(h)

      s[j] := 0
      for (i in 1:len(h)) {
        s[j] := 16*s[j] + h[i]
      }
    }

    return s
  }

  #-------------------------------------------------------------------- hexcol

  # Hexadecimal colour to decimal conversion.
  #
  # Given
  #    colour   string     Hexadecimal RGB colour representation (e.g. white
  #                        is '#ffffff').
  #
  # Returned
  #    Floating point triplet containing RGB values between 0 and 1.

  const hexcol := function(colour)
  {
    h := split(colour, '')
    if (h[1] != '#') return [0,0,0]
    if (len(h) != 7) return [0,0,0]

    return hex2dec(split(colour ~ s|.(..)(..)(..)|$1 $2 $3|))/255
  }

  #---------------------------------------------------------------------- lock

  # Lock/unlock parameter entry.

  const lock := function(disabled=T)
  {
    wider wrk

    wrk.locked := disabled

    if (is_agent(gui.f1)) {
      if (wrk.locked) {
        gui.chanRange.la->foreground('#a3a3a3')
        gui.startChan.en->disabled(T)
        gui.startChan.en->foreground('#a3a3a3')
        gui.endChan.en->disabled(T)
        gui.endChan.en->foreground('#a3a3a3')
      } else {
        gui.chanRange.la->foreground('#000000')
        gui.startChan.en->disabled(F)
        gui.startChan.en->foreground('#000000')
        gui.endChan.en->disabled(F)
        gui.endChan.en->foreground('#000000')
      }
    }
  }

  #---------------------------------------------------------------------- plot

  # plot() plots cached data.

  const plot := function(ps=F)
  {
    wider wrk

    if (wrk.dindx < 1) return

    beams := (1:13)[wrk.beams & parms.plotbeam]

    i1 := wrk.pindx
    i2 := wrk.dindx

    # Check domain.
    t0 := wrk.time[1]
    if (i2 == 1) {
      wrk.tspan := 120 * wrk.tinteg
      i1 := 1
    } else {
      nint := 20 * (as_integer((wrk.time[i2] - t0) / (20 * wrk.tinteg)) + 1)
      if (nint < 120) nint := 120
      tspan := nint * wrk.tinteg

      if (tspan != wrk.tspan) {
        # Data probably contains time jumps.
        wrk.tspan := tspan
        i1 := 1
      }
    }

    # Check range.
    if (len(beams)) {
      if (all(wrk.polcode < 3)) {
        dmin := min(wrk[parms.plottype][beams,wrk.polcode,1:i2])
        dmax := max(wrk[parms.plottype][beams,wrk.polcode,1:i2])

      } else {
        # Combine polarizations.
        if (wrk.polcode == 3) {
          dmin := min(wrk[parms.plottype][beams,1,1:i2] +
                      wrk[parms.plottype][beams,2,1:i2])
          dmax := max(wrk[parms.plottype][beams,1,1:i2] +
                      wrk[parms.plottype][beams,2,1:i2])

        } else if (wrk.polcode == 4) {
          dmin := min(wrk[parms.plottype][beams,1,1:i2] -
                      wrk[parms.plottype][beams,2,1:i2])
          dmax := max(wrk[parms.plottype][beams,1,1:i2] -
                      wrk[parms.plottype][beams,2,1:i2])
        }

        dmin /:= 2
        dmax /:= 2
      }

      if (i1 == 1 || dmin < wrk.dmin || dmax > wrk.dmax) {
        wrk.dmin := dmin - 0.1*(dmax - dmin)
        wrk.dmax := dmax + 0.1*(dmax - dmin)
        i1 := 1
      }

    } else {
      dmin := wrk.dmin
      dmax := wrk.dmax
      i1   := 1
    }
    zeroRange := dmax == dmin

    gui.stats.pg->bbuf()

    if (i1 == 1) {
      # Initialize or rescale.
      gui.stats.pg->sci(1)

      if (gui.stats.pg->qinf('HARDCOPY') == 'YES') {
        # Static PostScript output.

        ymin := dmin - 0.025*(dmax - dmin)
        ymax := dmax + 0.025*(dmax - dmin)
        if (zeroRange) {
          if (ymin < 0.0) {
            ymin *:= 1.05
            ymax *:= 0.95
          } else if (ymin > 0.0) {
            ymin *:= 0.95
            ymax *:= 1.05
          } else {
            ymin *:= -1.0
            ymax *:=  1.0
          }
        }

        gui.stats.pg->env(t0, wrk.time[i2]+15, ymin, ymax, 0, -2)
        title := spaste('Polarizations: ', parms.plotpols, ',  File: ',
                        parms.file, ', #', wrk.pscount)
        gui.stats.pg->lab('UTC', paste(parms.plottype, '(Jy)'), title)

        # Identify beams on the title line by colour.
        csz := gui.stats.pg->qcs(4)[2]
        gui.stats.pg->text(t0, ymax + 0.5*csz, 'Beams')
        xy := gui.stats.pg->qpos()


        for (pol in wrk.polcode) {
          if (len(wrk.polcode) > 1) {
            text := spaste(', (pol ', pol, '):  ')
          } else {
            text := ':  '
          }
          gui.stats.pg->text(xy[1], xy[2], text)
          xy := gui.stats.pg->qpos()

          for (beam in beams) {
            if (beam != beams[1]) {
              gui.stats.pg->text(xy[1], xy[2], ', ')
              xy := gui.stats.pg->qpos()
            }

            if (pol == 3) {
              colour := 1 + beam
              ylab := (wrk[parms.plottype][beam,1,i2] +
                       wrk[parms.plottype][beam,2,i2]) / 2

            } else if (pol == 4) {
              colour := 1 + beam
              ylab := (wrk[parms.plottype][beam,1,i2] -
                       wrk[parms.plottype][beam,2,i2]) / 2

            } else {
              colour := 1 + 13*(pol - 1) + beam
              ylab := wrk[parms.plottype][beam,pol,i2]
            }

            gui.stats.pg->sci(colour)
            gui.stats.pg->text(xy[1], xy[2], as_string(beam))
            xy := gui.stats.pg->qpos()

            # Also identify beams on the plot itself.
            xlab := wrk.time[i2] + 1
            if (len(wrk.polcode) > 1 && pol == 2) xlab +:= 5
            ylab -:= 0.15*csz
            gui.stats.pg->sch(0.4)
            gui.stats.pg->text(xlab, ylab, as_string(beam))
            gui.stats.pg->sch(1)

            gui.stats.pg->sci(1)
          }
        }

      } else {
        # Dynamic XTK output.
        gui.stats.pg->svp(0.08, 0.99, 0.1, 0.97)

        ymin := wrk.dmin
        ymax := wrk.dmax
        if (zeroRange) {
          if (ymin < 0.0) {
            ymin *:= 1.05
            ymax *:= 0.95
          } else if (ymin > 0.0) {
            ymin *:= 0.95
            ymax *:= 1.05
          } else {
            ymin *:= -1.0
            ymax *:=  1.0
          }
        }
        gui.stats.pg->swin(t0, t0 + wrk.tspan, ymin, ymax)

        gui.stats.pg->page()
      }

      gui.stats.pg->tbox('BCHNSTXYZ', 0.0, 0, 'BCNSTV', 0.0, 0)
    }

    if (i2 > i1) {
      # Update the plot.
      x := wrk.time[i1:i2]

      for (pol in wrk.polcode) {
        for (beam in beams) {
          if (pol == 3) {
            colour := 1 + beam
            y := (wrk[parms.plottype][beam,1,i1:i2] +
                  wrk[parms.plottype][beam,2,i1:i2]) / 2

          } else if (pol == 4) {
            colour := 1 + beam
            y := (wrk[parms.plottype][beam,1,i1:i2] -
                  wrk[parms.plottype][beam,2,i1:i2]) / 2

          } else {
            colour := 1 + 13*(pol - 1) + beam
            y := wrk[parms.plottype][beam,pol,i1:i2]
          }

          gui.stats.pg->sci(colour)
          if (zeroRange) {
            gui.stats.pg->pt(x, y, 2)

          } else {
            # Account for time jumps.
            lx  := len(x)
            idx := 1:(lx-1)
            jump := [idx[(x[idx+1] - x[idx]) > 1.5*wrk.tinteg], lx]

            j1 := 1
            for (i in 1:len(jump)) {
              j2 := jump[i]
              gui.stats.pg->line(x[j1:j2], y[j1:j2])
              j1 := j2 + 1
            }
          }
        }
      }
    }

    wrk.pindx := wrk.dindx

    gui.stats.pg->ebuf()
  }

  #------------------------------------------------------------------- readgui

  # Read values from entry boxes.

  const readgui := function() {
    wider parms

    if (is_agent(gui.f1)) {
      setparm([startChan = gui.startChan.en->get(),
               endChan   = gui.endChan.en->get()])
    }
  }

  #--------------------------------------------------------------------- reset

  # Reset the plot and enable selection widgets.

  const reset := function()
  {
    wider wrk

    # Reset array pointers.
    wrk.dindx := 0
    wrk.pindx := 1

    # Assume all beams and polarizations will be present.
    wrk.beams := [T,T,T,T,T,T,T,T,T,T,T,T,T]
    wrk.pols  := [T,T]

    # Reset PostScript output file count.
    wrk.pscount := 0

    if (is_agent(gui.f1)) {
      # Flash the "Reset" button.
      gui.reset.bn->background('#ffffff')

      # Erase the plot window.
      gui.stats.pg->eras()

      # Enable all polarization selections.
      gui.plotpols1.bn->disabled(F)
      gui.plotpols2.bn->disabled(F)
      gui.plotpols3.bn->disabled(F)
      gui.plotpols4.bn->disabled(F)
      gui.plotpols5.bn->disabled(F)

      # Enable all beam selections.
      for (i in 1:13) {
        gui.plotbeam.bn[i]->disabled(F)
      }

      # Recall/reinitialize parameters.
      setparm([plotpols = wrk.plotpols, plotbeam = parms.plotbeam])

      # Unflash the "Reset" button.
      gui.reset.bn->background('#d9d9d9')
    }

    lock(F)
  }

  #---------------------------------------------------------------------- save

  # save() produces a PostScript file of the plot currently displayed.
  #
  # Because of a limitation in Glish/PGPLOT the GUI must have been created
  # though it need not be visible.

  const save := function()
  {
    wider wrk

    if (!is_agent(gui.f1)) {
      print 'Stats plotter not enabled.'
      return
    }

    if (wrk.dindx < 1) {
      print 'No plot to save.'
      return
    }

    # Find a unique file name.
    while (T) {
      wrk.pscount +:= 1
      psfile := spaste(parms.directory, '/', parms.file, '.stats_',
                       wrk.pscount, '.ps')
      if (len(stat(psfile)) == 0) break
    }

    # Open the colour PostScript output file.
    istat := gui.stats.pg->open(spaste(psfile, '/CPS'))
    if (istat <= 0) {
      print 'Failed to open PostScript output file.'
      return
    }

    # Colours to be used.
    for (j in ind(wrk.palette)) {
      t := hexcol(wrk.palette[j])
      gui.stats.pg->scr(j-1, t[1], t[2], t[3])
    }

    # Reset to black text on white background.
    gui.stats.pg->scr(0, 1, 1, 1)
    gui.stats.pg->scr(1, 0, 0, 0)

    # Replot to the new device.
    wrk.pindx := 1
    plot()

    # Flush and close the output file.
    gui.stats.pg->clos()
    print 'Wrote', psfile

    # Select XTK device.
    wrk.pindx := 1
    gui.stats.pg->slct(1)
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

  #-------------------------------------------------------------- set.plotpols

  # Set polarization plot selection.

  const set.plotpols := function(value)
  {
    wider parms, wrk

    # Save requested value.
    wrk.plotpols := value

    # Check that polarizations are present.
    if (all(wrk.pols)) {
      parms.plotpols := value

    } else {
      if (wrk.pols[1]) {
        parms.plotpols := 'A'
      } else if (wrk.pols[2]) {
        parms.plotpols := 'B'
      } else {
        parms.plotpols := 'A&B'
      }
    }

    if (parms.plotpols == 'A') {
      wrk.polcode := 1
    } else if (parms.plotpols == 'B') {
      wrk.polcode := 2
    } else if (parms.plotpols == 'A&B') {
      wrk.polcode := 1:2
    } else if (parms.plotpols == 'A+B') {
      wrk.polcode := 3
    } else if (parms.plotpols == 'A-B') {
      wrk.polcode := 4
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

  # Build a graphical (PGPLOT) display window for the statistics client.
  # If the parent frame is not specified a separate window will be created.

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
      gui.f1 := frame(title='Multibeam stats plotter', relief='ridge',
                      borderwidth=4, expand='none')

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

    gui.f11 := frame(gui.f1, relief='ridge')
    ncol := len(wrk.palette)
    gui.stats.pg := pgplot(gui.f11, padx=0, pady=0, height=200, width=600,
                     mincolors=ncol, maxcolors=ncol, relief='flat')
    sethelp(gui.stats.pg, 'The selected statistic calculated at each \
                           integration for each beam and polarization \
                           plotted versus UTC.')

    gui.stats.pg->ask(F)

    # Set character size.
    gui.stats.pg->sch(2)

    # Colours to be used.
    for (j in ind(wrk.palette)) {
      t := hexcol(wrk.palette[j])
      gui.stats.pg->scr(j-1, t[1], t[2], t[3])
    }


    # Plotter control panel.
    gui.f12  := frame(gui.f1, relief='ridge', side='left')

    gui.f121  := frame(gui.f12, borderwidth=0)
    gui.f1211  := frame(gui.f121, side='left', borderwidth=0)
    gui.title.ex := button(gui.f1211, 'PLOT SELECTION', relief='flat',
                           borderwidth=0, foreground='#0000a0')
    sethelp(gui.title.ex, spaste('Plot selection panel (v', wrk.version,
            ') for the statistics client; PRESS FOR USAGE!'))

    whenever
      gui.title.ex->press do
        explain(self.file, 'USAGE')

    # Channel range over which to compute statistics -------------------------
    gui.f1212  := frame(gui.f121, side='left', borderwidth=0)
    gui.chanRange.la := label(gui.f1212, 'Channels')
    sethelp(gui.chanRange.la, 'Subset of channels for which statistics are \
      to be computed.')
    gui.startChan.en := entry(gui.f1212, justify='right', width=5,
                              relief='sunken')
    sethelp(gui.startChan.en, 'First channel in range; use zero or a \
      negative value for offset from last channel in data.')

    whenever
      gui.startChan.en->return do
        setparm([startChan = $value])

    gui.range.la := label(gui.f1212, '-')

    gui.endChan.en := entry(gui.f1212, justify='right', width=5,
                            relief='sunken')

    sethelp(gui.endChan.en, 'Last channel in range; use zero or a negative \
      value for offset from last channel in data.')

    whenever
      gui.endChan.en->return do
        setparm([endChan = $value])

    # Statistic to plot ------------------------------------------------------
    gui.f122  := frame(gui.f12, borderwidth=0)
    gui.f1221 := frame(gui.f122, side='left', borderwidth=0)
    gui.plottype.la := label(gui.f1221, 'Statistic', anchor='e', width=12)
    gui.plottype.bn := button(gui.f1221, type='menu', width=8,
                              relief='groove')
    sethelp(gui.plottype.bn, 'The statistic to be plotted.')

    gui.plottype1.bn := button(gui.plottype.bn, 'COUNT',    value='COUNT')
    gui.plottype2.bn := button(gui.plottype.bn, 'TSYS',     value='TSYS')
    gui.plottype3.bn := button(gui.plottype.bn, 'MEAN',     value='MEAN')
    gui.plottype4.bn := button(gui.plottype.bn, 'MEDIAN',   value='MEDIAN')
    gui.plottype5.bn := button(gui.plottype.bn, 'RMS',      value='RMS')
    gui.plottype6.bn := button(gui.plottype.bn, 'QUARTILE', value='QUARTILE')
    gui.plottype7.bn := button(gui.plottype.bn, 'MAXIMUM',  value='MAXIMUM')
    gui.plottype8.bn := button(gui.plottype.bn, 'MINIMUM',  value='MINIMUM')

    whenever
      gui.plottype1.bn->press,
      gui.plottype2.bn->press,
      gui.plottype3.bn->press,
      gui.plottype4.bn->press,
      gui.plottype5.bn->press,
      gui.plottype6.bn->press,
      gui.plottype7.bn->press,
      gui.plottype8.bn->press do
        self->plotparm([plottype = $value])


    # Polarization selection -------------------------------------------------
    gui.f1222 := frame(gui.f122, side='left', borderwidth=0)
    gui.plotpols.la := label(gui.f1222, 'Polarization', anchor='e', width=12)
    gui.plotpols.bn := button(gui.f1222, type='menu', width=8,
                              relief='groove')
    sethelp(gui.plotpols.bn, 'Polarization(s) (or combination thereof) to be \
      plotted (subject to availability).')

    gui.plotpols1.bn := button(gui.plotpols.bn, 'A',   value='A')
    gui.plotpols2.bn := button(gui.plotpols.bn, 'B',   value='B')
    gui.plotpols3.bn := button(gui.plotpols.bn, 'A&B', value='A&B')
    gui.plotpols4.bn := button(gui.plotpols.bn, 'A+B', value='A+B')
    gui.plotpols5.bn := button(gui.plotpols.bn, 'A-B', value='A-B')

    whenever
      gui.plotpols1.bn->press,
      gui.plotpols2.bn->press,
      gui.plotpols3.bn->press,
      gui.plotpols4.bn->press,
      gui.plotpols5.bn->press do
        self->plotparm([plotpols = $value])


    # Beam selection.
    gui.plotbeam.la := label(gui.f12, '   Beams ')
    sethelp(gui.plotbeam.la,
            'Beam(s) to be plotted (subject to availability).')

    gui.f123 := frame(gui.f12, side='left', expand='none')

    # Define a record with 13 fields.
    gui.plotbeam.bn := [=]
    for (j in 1:13) gui.plotbeam.bn[j] := F

    gui.f1231  := frame(gui.f123, borderwidth=0)
    gui.f12311 := frame(gui.f1231, height=17, width=0, expand='none')
    gui.plotbeam.bn[8]  := button(gui.f1231,  '8', value=8, width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')

    gui.f1232 := frame(gui.f123, borderwidth=0)
    gui.plotbeam.bn[13] := button(gui.f1232, '13', value=13, width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')
    gui.plotbeam.bn[7]  := button(gui.f1232,  '7', value=7,  width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')
    gui.plotbeam.bn[2]  := button(gui.f1232,  '2', value=2,  width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')
    gui.plotbeam.bn[9]  := button(gui.f1232,  '9', value=9,  width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')

    gui.f1233  := frame(gui.f123, borderwidth=0)
    gui.f12331 := frame(gui.f1233, height=5, width=0, expand='none')
    gui.plotbeam.bn[6]  := button(gui.f1233,  '6', value=6,  width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')
    gui.plotbeam.bn[1]  := button(gui.f1233,  '1', value=1,  width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')
    gui.plotbeam.bn[3]  := button(gui.f1233,  '3', value=3,  width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')

    gui.f1234 := frame(gui.f123, borderwidth=0)
    gui.plotbeam.bn[12] := button(gui.f1234, '12', value=12, width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')
    gui.plotbeam.bn[5]  := button(gui.f1234,  '5', value=5,  width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')
    gui.plotbeam.bn[4]  := button(gui.f1234,  '4', value=4,  width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')
    gui.plotbeam.bn[10] := button(gui.f1234, '10', value=10, width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')

    gui.f1235  := frame(gui.f123, borderwidth=0)
    gui.f12351 := frame(gui.f1235, height=17, width=0, expand='none')
    gui.plotbeam.bn[11] := button(gui.f1235, '11', value=11, width=2, padx=0,
                                  pady=0, borderwidth=0, font='5x7')

    for (i in 1:13) {
      sethelp(gui.plotbeam.bn[i],
              spaste('Select or deselect the plot for beam ', i, '.'))
    }

    whenever
      gui.plotbeam.bn[1]->press,
      gui.plotbeam.bn[2]->press,
      gui.plotbeam.bn[3]->press,
      gui.plotbeam.bn[4]->press,
      gui.plotbeam.bn[5]->press,
      gui.plotbeam.bn[6]->press,
      gui.plotbeam.bn[7]->press,
      gui.plotbeam.bn[8]->press,
      gui.plotbeam.bn[9]->press,
      gui.plotbeam.bn[10]->press,
      gui.plotbeam.bn[11]->press,
      gui.plotbeam.bn[12]->press,
      gui.plotbeam.bn[13]->press do {
        p := parms.plotbeam
        p[$value] := !p[$value]
        self->plotparm([plotbeam = p])
      }

    # Reset plot.
    gui.f124 := frame(gui.f12, side='right')
    gui.reset.bn := button(gui.f124, 'Reset')
    sethelp(gui.reset.bn, 'Reset the plot and enable all selection buttons.')

    whenever
      gui.reset.bn->press do
        reset()


    # Print plot.
    gui.save.bn := button(gui.f124, 'Save')
    sethelp(gui.save.bn,
            'Save the plot currently displayed as a colour PostScript file.')

    whenever
      gui.save.bn->press do
        save()

    # Lock parameter entry?  (Must precede showparm.)
    if (wrk.locked) lock()

    # Initialize widgets.
    showparm(gui, parms)

    tk_release()

    self->guiready()
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

  #--------------------------------------------------------- gui.plotbeam.show

  # Show beams selected for plotting (subject to their presence in the data).

  const gui.plotbeam.show := function()
  {
    for (j in 1:13) {
      if (wrk.beams[j]) {
        if (parms.plotbeam[j]) {
           if (parms.plotpols == 'A&B') {
             back := wrk.palette[sprintf('b%.2dp1',j)]
             fore := wrk.palette[sprintf('b%.2dp2',j)]
           } else {
             if (parms.plotpols == 'B') {
               back := wrk.palette[sprintf('b%.2dp2',j)]
             } else {
               back := wrk.palette[sprintf('b%.2dp1',j)]
             }
             fore := '#000000'
           }

           gui.plotbeam.bn[j]->background(back)
           gui.plotbeam.bn[j]->foreground(fore)

        } else {
           gui.plotbeam.bn[j]->background('#bbbbbb')
           gui.plotbeam.bn[j]->foreground('#000000')
        }

      } else {
        gui.plotbeam.bn[j]->background('#d9d9d9')
        gui.plotbeam.bn[j]->disabled(T)
      }
    }
  }

  #--------------------------------------------------------- gui.plotpols.show

  # Show polarizations selected for plotting (subject to their presence in the
  # data).

  const gui.plotpols.show := function()
  {
    gui.plotpols.bn->text(parms.plotpols)

    if (!all(wrk.pols)) {
      if (wrk.pols[1]) {
        gui.plotpols2.bn->disabled(T)
      } else if (wrk.pols[2]) {
        gui.plotpols1.bn->disabled(T)
      }

      gui.plotpols3.bn->disabled(T)
      gui.plotpols4.bn->disabled(T)
      gui.plotpols5.bn->disabled(T)
    }

    gui.plotbeam.show()
  }

  #-------------------------------------------------------- gui.startChan.show

  # Show the lower channel selection.

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

  # Set plot parameter values.
  whenever
    self->plotparm do {
      p := [=]
      for (parm in field_names($value)) {
        if (parm ~ m|plot.*|) p[parm] := $value[parm]
      }

      if (len(p)) {
        setparm(p)
        wrk.pindx := 1
        plot()
      }
    }

  # Show parameter values.
  whenever
    self->printparms do {
      readgui()
      print ''
      print parms
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
      lock(T)

  # Enable parameter entry.
  whenever
    self->unlock do
      lock(F)

  # Initialize the client.
  whenever
    self->init do {
      reset()
      setparm($value)
      readgui()
      wrk.client->init(parms)
    }

  # Accumulate data.
  whenever
    self->accumulate do {
      wrk.tinteg := $value.int01.beam01.INTERVAL
      wrk.client->accumulate($value)
    }

  # Compute statistics.
  whenever
    self->stats do
      wrk.client->stats()

  # Save the plot.
  whenever
    self->save do
      save()

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
  args := [client_dir = client_dir,
           directory  = directory,
           file       = file,
           startChan  = startChan,
           endChan    = endChan,
           plottype   = plottype,
           plotpols   = plotpols,
           plotbeam   = plotbeam]

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

  #-------------------------------------------------------------- stats client

  if (parms.client_dir == '') {
    wrk.client := client('pksstats')
  } else {
    wrk.client := client(spaste(parms.client_dir, '/pksstats'))
  }
  wrk.client.name := 'pksstats'

  # Process messages from the client.
  whenever
    wrk.client->* do {
      if ($name == 'accumulated') {
        encache($value)
        self->accumulated(len($value))
        plot()

      } else {
        self->[$name]($value)
      }
    }
}
