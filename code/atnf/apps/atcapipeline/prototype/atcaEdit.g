#-----------------------------------------------------------------------------
# atcaEdit.g: Editing class for the ATCA pipeline
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
include 'pgplotwidget.g'
include 'pgplotmanager.g'
include 'quanta.g'
include 'atcapl.g'
include 'configEdit.g'

atcaeditor := subsequence(config){

# Private variables and functions

  its := [=]
  its.plotFlagged := F

  const its.getpids := function(config){
    # get the process IDs of all the default servers started
    servers := ['drc', 'dq', 'dm']
    for(s in servers){
      if(is_record(eval(s))){
        pid := eval(s).id().pid
        fprintf(config.get_pidfile(), '%d %s\n', pid, s)
      }
    }
    return T
  }

  const its.set_minmax := function(column, mask=unset){
    if(!is_unset(mask)){
      ndim := len(column.data::shape)
      if(ndim == 1){
        column.min := min(column.data[mask])
        column.max := max(column.data[mask])
      } 
      else if(ndim == 2){
        column.min := min(column.data[,mask])
        column.max := max(column.data[,mask])
      }
      else if(ndim == 3){
        column.min := min(column.data[,,mask])
        column.max := max(column.data[,,mask])
      }
    }
    else{
      column.min := min(column.data)
      column.max := max(column.data)
    }
    return column
  }

  const its.set_uvmasks := function(udata, vdata){
    # mask bad data with strange (very large) UV values
    # doing this separately because I don't want to apply the other flags
    # put in a buffer of 500m that I probably don't need
    ndata := len(udata)
    mask := array(T, ndata)    

    for(i in 1:ndata){
      if(abs(udata[i]) > 6500.0 || abs(vdata[i]) > 6500.0)
        mask[i] := F
    }
    return mask
  }

  const its.set_masks := function(m){
    flag := m.getdata(['FLAG']).flag
    flagshape := flag::shape
    mask := array(T, flagshape[3])

    if(its.plotFlagged == T){
      for(i in 1:flagshape[1]){
        for(j in 1:flagshape[2]){
          mask &:= flag[i,j,]
        }
      }
      mask := !mask
    }
    return mask
  }

  const its.create_title := function(c, ddescid, titlestring, corrected=F, flagged=F){
    freq := dq.tos(dq.convertfreq(c.ddesc[ddescid].frequency, 'GHz'))

    codestring := ' '
    if(corrected)
      codestring := spaste(codestring, '(Calibrated) ')
    if(flagged)
      codestring := spaste(codestring, '(Flagged) ')
    title := spaste(c.project.val, ' ', titlestring, ' Freq=', freq, codestring)
    return title
  }

  const its.create_filename := function(c, ddescid, suffix, code){
    freq := dq.convertfreq(c.ddesc[ddescid].frequency, 'MHz').value
    npol := len(c.ddesc[ddescid].corrnames)
    nchan := c.ddesc[ddescid].nchan

    namehead := spaste(c.plotdir.val, freq, '-', nchan, '-', npol, '-', ddescid, '-')

    if(its.plotFlagged == T)
      return spaste(namehead, code, 'f.', suffix)
    else
      return spaste(namehead, code, '-.', suffix)
  }

  const its.plot_uv := function(config, m, ddescid){
    wider its
    note('Plotting UV coverage')

    const do_plot := function(p, x, y, mask){
      p.pap(width=0.0, aspect=1.0)
      p.env(x.min, x.max, y.min, y.max, 0, 0)
      p.lab(x.axis, y.axis, x.title)
      p.sci(1)
      p.pt(x.data[mask], y.data[mask], -1)
      p.sci(2)
      p.pt(-x.data[mask], -y.data[mask], -1)
      p.done()
    }

    c := config.get_vars()
    logic := config.get_logicvars()

    m.selectinit(datadescid=0, reset=T)
    m.selectinit(datadescid=ddescid)
    m.selectpolarization("XX")
    m.select([field_id=c.ddesc[ddescid].targetIDs.val])
    data := m.getdata(['U', 'V'])
    if(is_fail(data)) return fatal(PARMERR, 'Error selecting data in uvdata', data::)

    x := [=]
    y := [=]
    x.data := data.u
    y.data := data.v

    mask := its.set_uvmasks(x.data, y.data)
    if(is_fail(mask))
      return fatal(PARMERR, 'Error setting flag masks for plotting', mask::)
    x := its.set_minmax(x, mask)
    if(is_fail(x)) return fatal(PARMERR, 'Error calculating MinMax in amptime', x::)
    y := its.set_minmax(y, mask)
    if(is_fail(y)) return fatal(PARMERR, 'Error calculating MinMax in amptime', y::)

    x.max := max(abs(x.max), abs(x.min), abs(y.max), abs(y.min))
    y.max := x.max
    x.min := -x.max
    y.min := -x.max

    x.axis := c.axes.u.val
    y.axis := c.axes.v.val

    x.title := its.create_title(c, ddescid, 'UV Coverage')
    if(is_fail(x.title)) return fatal(PARMERR, 'Error creating title in uvdata', x.title::)

    file := its.create_filename(c, ddescid, 'uv.ps', 't-')
    if(is_fail(file)) return fatal(PARMERR, 'Error creating filename in uvdata', file::)

    if(logic.plotps == T){
      p := pgplotps(file, overwrite=T)
      if(is_fail(p)) return fatal(PARMERR, 'Error starting pgplotps in uvdata', p::)
      ok := do_plot(p, x, y, mask)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running do_plot in uvdata', ok::)
      print 'PLOT: A plot of UV coverage has been saved in', file
    }
    if(logic.plotgui == T){
      f := frame()
      p := pgplotwidget(f, background='white', foreground='black')
      if(is_fail(p)) return fatal(PARMERR, 'Error starting pgplotwidget in uvdata', p::)
      ok := do_plot(p, x, y, mask)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running do_plot in uvdata', ok::)
    }
    return T
  }

  const its.plot_ri := function(config, m, ddescid){
    wider its
    note('Plotting real vs. imaginary visibilities')

    const do_plot := function(p, x, y){
      p.pap(width=0.0, aspect=1.0)
      p.env(x.min, x.max, y.min, y.max, 0, 0)
      p.lab(x.axis, y.axis, x.title)

      for(i in 1:x.data::shape[1]){
        p.sci(i)
        p.pt(x.data[i,,], y.data[i,,], -1)
      }
      p.done()
    }
 
    c := config.get_vars()
    logic := config.get_logicvars()

    m.selectinit(datadescid=0, reset=T)
    m.selectinit(datadescid=ddescid)
    m.select([field_id=c.ddesc[ddescid].pID.val])
    m.selectpolarization("I Q U V")
    d := m.getdata('CORRECTED_DATA')
    if(is_fail(d)) return fatal(PARMERR, 'Error selecting data in realimag', d::)

    # calculate amplitudes and phases
    x := [=]
    y := [=]
    x.data := real(d.corrected_data)
    y.data := imag(d.corrected_data)

    x := its.set_minmax(x)
    if(is_fail(x)) return fatal(PARMERR, 'Error calculating MinMax in realimag', x::)

    y := its.set_minmax(y)
    if(is_fail(y)) return fatal(PARMERR, 'Error calculating MinMax in realimag', y::)

    x.axis := c.axes.real.val
    y.axis := c.axes.imag.val

    file := its.create_filename(c, ddescid, 'ri.ps', 'pc')
    if(is_fail(file)) return fatal(PARMERR, 'Error creating filename in realimag', file::)

    x.title := its.create_title(c, ddescid, 'Real vs. Imaginary Visibilities', corrected=T)
    if(is_fail(x.title)) return fatal(PARMERR, 'Error creating title in realimag', x.title::)

    if(logic.plotps == T){
      p := pgplotps(file, overwrite=T)
      if(is_fail(p)) return fatal(PARMERR, 'Error starting pgplotps in realimag', p::)
      ok := do_plot(p, x, y)
      if(is_fail(ok)) return fatal(PARMERR, 'Error plotting realimag', ok::)
      print 'PLOT: A Real vs. Imaginary plot has been saved in', file
    }
    if(logic.plotgui == T){
      f := frame()
      p := pgplotwidget(f, background='white', foreground='black')
      p.ask(T)
      if(is_fail(p)) return fatal(PARMERR, 'Error starting pgplotwidget in realimag', p::)
      ok := do_plot(p, x, y)
      if(is_fail(ok)) return fatal(PARMERR, 'Error plotting realimag', ok::)
    }
    return T
  }

  const its.plot_amptime := function(config, m, ddescid, fieldids=F, code='a', corrected=F){
    wider its
    note('Plotting Amplitude vs Time')

    const do_plot := function(p, ddescid, fieldids=F, tstring, corrected){
      baseline := 0 
      for(i in 0:(its.nAntenna-2)){
        for(j in (i+1):(its.nAntenna-1)){
          baseline := baseline + 1
          bstring := spaste('CA0',(i+1),'-CA0',(j+1))
          query := spaste('ANTENNA1==',i,'&& ANTENNA2==',j)
          title := spaste(tstring, ' Baseline=', bstring) 
          m.selectinit(reset=T)
          m.selectinit(datadescid=ddescid)
          if(fieldids)
            m.select([field_id=fieldids])
          m.selecttaql(query)

          pol := ['']
          if(corrected){
            m.selectpolarization("I Q U V")
            data := m.getdata(['CORRECTED_AMPLITUDE', 'TIME'])
            if(is_fail(data)) return fatal(PARMERR, 'Error selecting data in amptime', data::)

            pol[1] := 'I'
            pol[2] := 'Q'
            pol[3] := 'U'
            pol[4] := 'V'
            x.data := (data.time - min(data.time))/3600.0
            y.data := data.corrected_amplitude
          }
          else{
            m.selectpolarization("XX YY XY YX")
            data := m.getdata(['AMPLITUDE', 'TIME'])
            if(is_fail(data)) return fatal(PARMERR, 'Error selecting data in amptime', data::)

            pol[1] := 'XX'
            pol[2] := 'YY'
            pol[3] := 'XY'
            pol[4] := 'YX'
            x.data := (data.time - min(data.time))/3600.0
            y.data := data.amplitude
          }

          mask := its.set_masks(m)
          if(is_fail(mask))
            return fatal(PARMERR, 'Error setting flag masks for plotting', mask::)

          x := its.set_minmax(x, mask)
          if(is_fail(x))
            return fatal(PARMERR, 'Error calculating MinMax in amptime', x::)
          y := its.set_minmax(y, mask)
          if(is_fail(y))
            return fatal(PARMERR, 'Error calculating MinMax in amptime', y::)

          timestring := sprintf('%s', dq.time(dq.quantity(min(data.time), 's'), form='ymd'))
          xlabel := spaste('Time: hours since ', timestring)

          p.sci(1)
          p.env(x.min, x.max, y.min, y.max, 0, 0)
          p.lab(xlabel, 'Amplitude', title)

          yinc := (y.max - y.min) / 15
          xinc := (x.max - x.min) / 20
          yshape := y.data::shape
          p.sch(2)
          p.text(x.min + xinc/2, y.max - yinc, 'Key:')
          for(k in 1:yshape[1]){
            p.sci(k)
            p.text(x.min + xinc + (k+1)*xinc, y.max - yinc, pol[k])
            for(l in 1:yshape[2])
              p.pt(x.data[mask], y.data[k,l,mask], -1)
          }
          p.sch(1)
        }
      }
      return T
    }

    c := config.get_vars()
    logic := config.get_logicvars()

    m.selectinit(reset=T)
    m.selectinit(datadescid=ddescid)
    d := m.getdata("axis_info", ifraxis=T)

    if(c.ignore6.val)
      its.nAntenna := len(c.antennas.val)
    else
      its.nAntenna := len(m.range('ANTENNA1').antenna1) + 1

    if(corrected){
      code := spaste(code, 'c')
      if(its.plotFlagged == T)
        title := its.create_title(c, ddescid, 'Amplitude vs. Time', corrected=T, flagged=T)
      else
        title := its.create_title(c, ddescid, 'Amplitude vs. Time', corrected=T)
    }
    else{
      code := spaste(code, '-')
      if(its.plotFlagged == T)
        title := its.create_title(c, ddescid, 'Amplitude vs. Time', flagged=T)
      else
        title := its.create_title(c, ddescid, 'Amplitude vs. Time')
    }
    file := its.create_filename(c, ddescid, 'at.ps', code)

    if(logic.plotps == T){
      p := pgplotps(file, overwrite=T)
      if(is_fail(p)) return fatal(PARMERR, 'Error starting pgplotps', p::)
      p.subp(3,3)
      ok := do_plot(p, ddescid, fieldids, title, corrected)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running do_plot', ok::)
      print 'PLOT: An amplitude-time plot has been saved in', file
      p.done()
    }
    if(logic.plotgui == T){
      f := frame()
      p := pgplotwidget(f, background='white', foreground='black')
      if(is_fail(p)) return fatal(PARMERR, 'Error starting pgplotps', p::)
      p.ask(T)
      p.subp(3,3)
      ok := do_plot(p, ddescid, fieldids, tstring, corrected)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running do_plot', ok::)
      p.done()
    }
  }

  const its.plot_phasetime := function(config, m, ddescid, fieldids=F, code='a'){
    wider its
    note('Plotting Phase vs Time')

    const do_plot := function(p, ddescid, fieldids=F, tstring){
      baseline := 0 
      for(i in 0:(its.nAntenna-2)){
        for(j in (i+1):(its.nAntenna-1)){
          baseline := baseline + 1
          bstring := spaste('CA0',(i+1),'-CA0',(j+1))
          query := spaste('ANTENNA1==',i,'&& ANTENNA2==',j)
          title := spaste(tstring, ' Baseline=', bstring) 
          m.selectinit(reset=T)
          m.selectinit(datadescid=ddescid)
          if(fieldids)
            m.select([field_id=fieldids])
          m.selecttaql(query)

          m.selectpolarization("I")
          data := m.getdata(['CORRECTED_PHASE', 'TIME'])
          if(is_fail(data)) return fatal(PARMERR, 'Error selecting data in amptime', data::)

          x.data := (data.time - min(data.time))/3600.0
          y.data := data.corrected_phase

          mask := its.set_masks(m)
          if(is_fail(mask))
            return fatal(PARMERR, 'Error setting flag masks for plotting', mask::)

          x := its.set_minmax(x, mask)
          if(is_fail(x))
            return fatal(PARMERR, 'Error calculating MinMax in amptime', x::)

          # x range is -Pi to Pi
          y.min := -3.5
          y.max := 3.5

          timestring := sprintf('%s', dq.time(dq.quantity(min(data.time), 's'), form='ymd'))
          xlabel := spaste('Time: hours since ', timestring)

          p.sci(1)
          p.env(x.min, x.max, y.min, y.max, 0, 0)
          p.lab(xlabel, 'Phase', title)

          yshape := y.data::shape
          for(k in 1:yshape[1]){
            p.sci(k)
            for(l in 1:yshape[2])
              p.pt(x.data[mask], y.data[k,l,mask], -1)
          }
        }
      }
      return T
    }

    c := config.get_vars()
    logic := config.get_logicvars()

    m.selectinit(reset=T)
    m.selectinit(datadescid=ddescid)
    d := m.getdata("axis_info", ifraxis=T)

    if(c.ignore6.val)
      its.nAntenna := len(c.antennas.val)
    else
      its.nAntenna := len(m.range('ANTENNA1').antenna1) + 1

    freqstring := dq.tos(dq.convertfreq(c.ddesc[ddescid].frequency, 'GHz'))
    if(its.plotFlagged == T)
      tstring := spaste(c.project.val, ' (Flagged) Phase vs. Time: Freq=', freqstring)
    else
      tstring := spaste(c.project.val, ' (Raw) Phase vs. Time: Freq=', freqstring)

    code := spaste(code, 'c')
    file := its.create_filename(c, ddescid, 'pt.ps', code)

    if(logic.plotps == T){
      p := pgplotps(file, overwrite=T)
      if(is_fail(p)) return fatal(PARMERR, 'Error starting pgplotps', p::)
      p.subp(3,3)
      ok := do_plot(p, ddescid, fieldids, tstring)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running do_plot', ok::)
      print 'PLOT: An phase-time plot has been saved in', file
      p.done()
    }
    if(logic.plotgui == T){
      f := frame()
      p := pgplotwidget(f, background='white', foreground='black')
      if(is_fail(p)) return fatal(PARMERR, 'Error starting pgplotps', p::)
      p.ask(T)
      p.subp(3,3)
      ok := do_plot(p, ddescid, fieldids, tstring)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running do_plot', ok::)
      p.done()
    }
  }

  const its.plot_ampuvdist := function(config, m, ddescid, fieldids=F, code='a', corrected=F){
    wider its
    note('Plot Amplitude vs. UVdist')

    const do_plot := function(p, x, y, mask){
      p.sci(1)
      p.env(x.min, x.max, y.min, y.max, 0, 0)
      p.lab(x.axis, y.axis, x.title)

      yshape := y.data::shape

      for(i in 1:yshape[1]){
        p.sci(i)
        for(j in 1:yshape[2]){
          ok := p.pt(x.data[mask], y.data[i,j,mask], -1)
          if(is_fail(ok)) return fatal(PARMERR, 'Error plotting data in ampuvdist', ok::)
        }
      }
      return T
    }

    c := config.get_vars()
    logic := config.get_logicvars()

    m.selectinit(datadescid=0, reset=T)
    m.selectinit(datadescid=ddescid)
    if(fieldids)
      m.select([field_id=fieldids])

    if(corrected){
      data := m.getdata(['U', 'V', 'CORRECTED_AMPLITUDE'])
      if(is_fail(data)) return fatal(IOERR, 'Error reading data from measurement set', data::)

      y.data := data.corrected_amplitude
    }
    else{
      data := m.getdata(['U', 'V', 'AMPLITUDE'])
      if(is_fail(data)) return fatal(IOERR, 'Error reading data from measurement set', data::)

      y.data := data.amplitude
    }
    x.data := sqrt(data.u^2 + data.v^2)

    x.axis := c.axes.uvdist.val
    y.axis := c.axes.amp.val

    if(corrected){
      code := spaste(code, 'c')
      if(its.plotFlagged == T)
        x.title := its.create_title(c, ddescid, 'Amplitude vs. UV Distance', corrected=T, flagged=T)
      else
        x.title := its.create_title(c, ddescid, 'Amplitude vs. UV Distance', corrected=T)
    }
    else{
      code := spaste(code, '-')
      if(its.plotFlagged == T)
        x.title := its.create_title(c, ddescid, 'Amplitude vs. UV Distance', flagged=T)
      else
        x.title := its.create_title(c, ddescid, 'Amplitude vs. UV Distance')
    }
    file := its.create_filename(c, ddescid, 'ad.ps', code)

    mask := its.set_masks(m)
    if(is_fail(mask)) 
      return fatal(PARMERR, 'Error setting flag masks for plotting', mask::)

    x := its.set_minmax(x, mask)
    if(is_fail(x))
      return fatal(PARMERR, 'Error setting min/max values for plotting', x::)

    y := its.set_minmax(y, mask)
    if(is_fail(y))
      return fatal(PARMERR, 'Error setting min/max values for plotting', y::)

    if(logic.plotps == T){
      p := pgplotps(file, overwrite=T)
      if(is_fail(p)) return fatal(PARMERR, 'Error starting psplotps', p::)
      ok := do_plot(p, x, y, mask)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running do_plot', ok::)
      print 'PLOT: An amplitude vs UV distance plot has been saved in', file
      p.done()
    }
    if(logic.plotgui == T){
      f := frame()
      p := pgplotwidget(f, background='white', foreground='black')
      if(is_fail(p)) return fatal(PARMERR, 'Error starting pgplotwidget', p::)
      p.ask(T)
      ok := do_plot(p, x, y, mask)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running do_plot', ok::)
      p.done()
    }
    return T    
  }

  const its.do_plots := function(config, ddescid, flagged=F){
    wider its
    note('Doing plotting')
    its.plotFlagged := flagged

    c := config.get_vars()
    logic := config.get_logicvars()

    cflag := logic.use_corrected[ddescid]

    if(logic.chan0[ddescid] == T){
      if(cflag == T)
        m := ms(c.chan0corr.val)
      else
        m := ms(c.chan0raw.val)
    }
    else
      m := ms(c.msname.val)
    if(is_fail(m)) return fatal(PARMERR, 'Error opening measurement set', m::)

    if(logic.plot_ri[ddescid] == T && its.plotFlagged == T){
      ok := its.plot_ri(config, m, ddescid)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running plot_ri', ok::)
    }

    if(logic.plot_uv[ddescid] == T && its.plotFlagged == F){
      ok := its.plot_uv(config, m, ddescid)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running plot_uv', ok::)
    }

    ddesc := c.ddesc[ddescid]

    if(logic.plot_primary[ddescid]){
      ok := its.plot_amptime(config, m, ddescid, fieldids=ddesc.pID.val, 
                             code='p', corrected=cflag)
      if(is_fail(ok)) return fatal(PARMERR, 'Error doing Amplitude vs. Time plot', ok::)

      ok := its.plot_ampuvdist(config, m, ddescid, fieldids=ddesc.pID.val, 
                               code='p', corrected=cflag)
      if(is_fail(ok)) return fatal(PARMERR, 'Error doing Amplitude vs. UVDist', ok::)

    }

    if(logic.plot_secondaries[ddescid]){
      ok := its.plot_amptime(config, m, ddescid, fieldids=ddesc.sIDs.val, 
                             code='s', corrected=cflag)
      if(is_fail(ok)) return fatal(PARMERR, 'Error doing Amplitude vs. Time plot', ok::)

      if(logic.plot_phasetime[ddescid]){
        ok := its.plot_phasetime(config, m, ddescid, fieldids=ddesc.sIDs.val, code='s')
        if(is_fail(ok)) return fatal(PARMERR, 'Error doing Amplitude vs. Time plot', ok::)
      }

      ok := its.plot_ampuvdist(config, m, ddescid, fieldids=ddesc.sIDs.val, 
                               code='s', corrected=cflag)
      if(is_fail(ok)) return fatal(PARMERR, 'Error doing Amplitude vs. UVDist', ok::)
    }

    if(logic.plot_targets[ddescid]){
      ok := its.plot_amptime(config, m, ddescid, fieldids=ddesc.targetIDs.val, 
                             code='t', corrected=cflag)
      if(is_fail(ok)) return fatal(PARMERR, 'Error doing Amplitude vs. Time plot', ok::)   

      ok := its.plot_ampuvdist(config, m, ddescid, fieldids=ddesc.targetIDs.val, 
                               code='t', corrected=cflag)
      if(is_fail(ok)) return fatal(PARMERR, 'Error doing Amplitude vs. UVDist', ok::)
    }

    if(logic.plot_all[ddescid]){
      ok := its.plot_amptime(config, m, ddescid, code='a', corrected=cflag)
      if(is_fail(ok)) return fatal(PARMERR, 'Error doing Amplitude vs. Time plot', ok::)
    }

    m.done()
    return T
  }

  const its.check_for_corrdata := function(config){
    # check whether the corrected data column is present
    c := config.get_vars()
    t := table(c.msname.val)
    if(is_fail(t)) return fatal(PARMERR, 'Error opening measurement set', t::)
    cols := t.colnames()
    t.done()
    for(col in cols){
      if(col == 'CORRECTED_DATA')
        return T
    }
    return F
  }

  const its.copy_data_col := function(msname){
    # copy DATA to CORRECTED_DATA in the split MS
    t := table(msname, readonly=F)
    if(is_fail(t)) return fatal(PARMERR, 'Error opening table', t::)

    olddesc := t.getcoldesc('DATA')
    ok := t.addcols([name='CORRECTED_DATA', desc=olddesc])
    if(is_fail(ok)) return fatal(PARMERR, 'Error adding data column', ok::)

    data := t.getcol('DATA')
    ok := t.putcol('CORRECTED_DATA', data)
    if(is_fail(ok)) return fatal(PARMERR, 'Error adding data column', ok::)   
    t.done()
    return T
  }

  const its.calc_chan0_band := function(config){
    # calculate which channels to include in channel 0 averaging
    c := config.get_vars()
    rec := [=]
    rec.start := []
    rec.step := []
    rec.nchan := []
    for(ddescid in c.dataDescIDs.val){
      nchan := c.ddesc[ddescid].nchan
      rec.start[ddescid] := floor(0.05*nchan + 0.5)
      rec.step[ddescid] := floor(0.9*nchan + 0.5)
      rec.nchan[ddescid] := 1
    }      
    return rec
  }

  const its.form_chan0 := function(config){
    # create a measurement set with channel 0 data
    c := config.get_vars()

    band := its.calc_chan0_band(config)
    if(is_fail(band)) return fatal(PARMERR, 'Error selecting chan0 channels', band::)

    corrected := its.check_for_corrdata(config)
    if(is_fail(corrected)) return fatal(PARMERR, 'Error checking for corrdata', corrected::)

    m := ms(c.msname.val, readonly=F)
    if(is_fail(m)) return fatal(PARMERR, 'Error opening measurement set', m::)

    ok := m.split(c.chan0raw.val, fieldids=c.fieldIDs.val, whichcol='DATA',
                  nchan=band.nchan, start=band.start, step=band.step)
    if(is_fail(ok)) return fatal(PARMERR, 'Error spliting MS', ok::)

    if(corrected){
      ok := m.split(c.chan0corr.val, fieldids=c.fieldIDs.val, whichcol='CORRECTED_DATA',
                    nchan=band.nchan, start=band.start, step=band.step) 
      if(is_fail(ok)) return fatal(PARMERR, 'Error spliting MS', ok::)
  
      ok := its.copy_data_col(msname=c.chan0corr.val)
      if(is_fail(ok)) return fatal(PARMERR, 'Error renaming DATA to CORRECTED_DATA', ok::)
    }
    m.done()
    return T
  }

  const its.calc_cont_chans := function(config, ddescid){
    # set continuum channels to cover 
    # the 10-30% and 70-90% pixel regions
    c := config.get_vars()
    nchan := c.ddesc[ddescid].nchan

    ch1 := floor(0.1*nchan + 0.5)
    ch2 := floor(0.3*nchan + 0.5)
    ch3 := floor(0.7*nchan + 0.5)
    ch4 := floor(0.9*nchan + 0.5)
    return [ch1, ch2, ch3, ch4]
  }

  const its.subtract_continuum := function(config, ddescid, fieldids){
    # subtract continuum from spectral line data

    msname := config.get_msname()
    m := ms(msname, readonly=F)
    if(is_fail(m)) return fatal(PARMERR, 'Error opening measurement set for uvlsf', m::)

    ch := its.calc_cont_chans(config, ddescid)
    if(is_fail(ch)) return fatal(PARMERR, 'Error finding continuum channels', ch::)

    ok := m.uvlsf(fldid=fieldids, spwid=ddescid, mode='subtract', fitorder=1, 
                  chans=[ch[1]:ch[2], ch[3]:ch[4]]) 
    if(is_fail(ok)) return fatal(PARMERR, 'Error doing continuum subtraction', ok::)

    m.done()
    return T
  }

  const its.remove_birdie := function(config, ddescid){
    # remove birdie from spectral line data
    birdie := unset
    msname := config.get_msname()
    m := ms(msname)
    if(is_fail(m)) return fatal(PARMERR, 'Error opening measurement set for flagging', m::)

    chan_freq := m.range("chan_freq").chan_freq
    m.done()
    for(i in 1:len(chan_freq)){
      if(chan_freq[i] == 1.408e+09){ 
        birdie := i
      }
    }
    if(is_unset(birdie)) 
      return T

    cmin := birdie - 1
    cmax := birdie + 1

    af := autoflag(msname)
    if(is_fail(af)) return fatal(PARMERR, 'Error initialising autoflag', af::)

    ok := af.setdata(mode='spwids',spwid=ddescid)
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting flag parameters', ok::)

    ok := af.setselect(spwid=ddescid, chan=[cmin,cmax])
    if(is_fail(ok)) return fatal(PARMERR, 'Error setting flag parameters', ok::)

    ok := af.run(plotscr=F, plotdev=F)
    if(is_fail(ok)) return fatal(PARMERR, 'Error removing birdie', ok::)

    af.done()
    return T
  }

  const its.flag_polns := function(config, ddescid, fieldids=F){
    # once autoflag has run, flag polns where XX & YY are flagged
    # try new method: flag polns where any poln is flagged.

    m := ms(config.get_msname(), readonly=F)
    m.selectinit(datadescid=ddescid)
    if(fieldids)
      m.select([field_id=fieldids])
    data := m.getdata(['FLAG', 'FLAG_ROW'])

    flagshape :=  data.flag::shape
    npol := flagshape[1]
    nchan := flagshape[2]
    nrows := flagshape[3]

    for(i in 1:nrows){
      for(j in 1:nchan){
        if(data.flag[1,j,i] == T || data.flag[2,j,i] == T || 
           data.flag[3,j,i] == T || data.flag[4,j,i] == T){
          for(k in 1:npol)
            data.flag[k,j,i] := T
        }
      }
    }
    m.putdata(data)
    m.done()
    return T
  }

  const its.flag := function(config, ddescid, fieldids=F, code='cals'){
    note('Doing Flagging')

    logic := config.get_logicvars()
    if(logic.use_corrected[ddescid] == T)
      col := 'CORR'
    else
      col := 'DATA'

    af:=autoflag(config.get_msname())
    if(is_fail(af)) return fatal(PARMERR, 'Error initialising autoflag', af::)

    if(fieldids){
      ok := af.setdata(mode='spwids & fieldids', spwid=ddescid, fieldid=fieldids)
      if(is_fail(ok)) return fatal(PARMERR, 'Error selecting data for autoflag', ok::)
    }
    else{
      ok := af.setdata(mode='spwids', spwid=ddescid);
      if(is_fail(ok)) return fatal(PARMERR, 'Error selecting data for autoflag', ok::)
    }

    if(code == 'cals'){
      ok := af.setnewtimemed(thr=5, expr="ABS I", fignore=T, column=col)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running setnewtimemed', ok::)

      ok := af.settimemed(thr=4, hw=5, expr="ABS I", fignore=T, column=col)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running settimemed', ok::)
    }
    else if(code == 'targets'){
      # remove extreme outliers
      ok := af.setuvbin(thr=0.04, expr="ABS I", fignore=T, column=col)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running setuvbin', ok::)

      # remove points where V is high
      ok := af.settimemed(thr=4, hw=5, expr="- ABS XY YX", fignore=T, column=col)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running settimemed', ok::) 

      ok := af.setnewtimemed(thr=5, expr="- ABS XY YX", fignore=T, column=col)
      if(is_fail(ok)) return fatal(PARMERR, 'Error running setnewtimemed', ok::)
    }
    else
      return T

    ok := af.run(plotscr=F, plotdev=F)
    if(is_fail(ok)) return fatal(PARMERR, 'Error running autoflagging', ok::)

    af.done()

    ok := its.flag_polns(config, ddescid, fieldids)
    if(is_fail(ok)) return fatal(PARMERR, 'Error running flagging', ok::)

    return T
  }


# Public variables and functions

  const self.edit := function(config){

    c := config.get_vars()
    logic := config.get_logicvars()

    if(logic.form_chan0 == T){
      ok := its.form_chan0(config) 
      if(is_fail(ok)) return fatal(PARMERR, 'Error forming channel 0 dataset', ok::)
    }

    for(ddescid in c.ddesctoProcess.val){
      ddesc := c.ddesc[spaste(ddescid)]

## XXX modifying this to include spectral for testing purposes
##      if(ddesc.mode != CONTINUUM && ddesc.mode != SPECTRAL){
      if(ddesc.mode != CONTINUUM){
        printf('Cant edit non-continuum data, skipping Spectral Window %d\n', ddescid)
        continue
      }
      printf('Editing DDESC %d\n', ddescid)

      if(logic.plot_raw[ddescid] == T){ 
        printf('Plotting raw visibilities for Dataset %d\n', ddescid)
        ok := its.do_plots(config, ddescid, flagged=F)
        if(is_fail(ok)) return fatal(PARMERR, 'Error plotting raw visibilities', ok::)
      }

      if(logic.remove_birdie[ddescid] == T){
        ok := its.remove_birdie(config, ddescid)
        if(is_fail(ok)) return fatal(PARMERR, 'Error removing birdie', ok::)
      }

      if(logic.subtract_continuum[ddescid] == T){
        ok := its.subtract_continuum(config, ddescid, fieldids=ddesc.targetIDs.val)
        if(is_fail(ok)) return fatal(PARMERR, 'Error subtracting continuum', ok::)
      }

      if(logic.do_flagging[ddescid] == T){
        if(logic.flag_primary[ddescid] == T){
          ok := its.flag(config, ddescid=ddescid, fieldids=ddesc.pID.val, code='cals')
          if(is_fail(ok)) return fatal(PARMERR, 'Error flagging data', ok::)
        }
        if(logic.flag_secondaries[ddescid] == T){
          ok := its.flag(config, ddescid=ddescid, fieldids=ddesc.sIDs.val, code='cals')
          if(is_fail(ok)) return fatal(PARMERR, 'Error flagging data', ok::)
        }
        if(logic.flag_targets[ddescid] == T){
          ok := its.flag(config, ddescid=ddescid, fieldids=ddesc.targetIDs.val, code='targets')
          if(is_fail(ok)) return fatal(PARMERR, 'Error flagging data', ok::)
        }
      }

      if(logic.plot_flagged[ddescid] == T){
        printf('Plotting flagged visibilities for Dataset %d\n', ddescid)
        ok := its.do_plots(config, ddescid, flagged=T)
        if(is_fail(ok)) return fatal(PARMERR, 'Error plotting flagged visibilities', ok::)
      }
    }
    return T
  }

  const self.done := function(config){
    ok := its.getpids(config)
    if(is_fail(ok)) return fatal(PARMERR, 'Error getting server pids', ok::)
    return T
  }
}
