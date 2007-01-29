#-----------------------------------------------------------------------------
# metadata.g: Metadata functions for the ATCA pipeline
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
include 'table.g'
include 'ms.g'
include 'quanta.g'
include 'autoflag.g'

metadata := subsequence(msname){

# Private variables and functions
  its := [=]
  its.ddesc := [=]
  its.fieldIDs := unset
  its.fieldNames := unset

  its.antennadiameter := unset
  its.maxbaseline := unset
  its.pixels := [=]

  const its.composite := function(number){
    # ensure that the number passed in is composite
    # ie: a power of 2, 3 and 5

    i := 1
    comp := array(0, 12*9*7)
    for(i2 in 1:12){
      for(i3 in 0:8){
        for(i5 in 0:6){
          comp[i] := 2^i2 * 3^i3 * 5^i5
          i +:= 1
        }
      }
    }
    comp := sort(comp)
    for(i in 1:(12*9*7)){
      if(comp[i] >= number) return comp[i]
    }
    return number
  }

  const its.calc_fov := function(freq){
    # calulate the field of view at a given frequency
    return dq.quantity(30*1.4e9/freq, 'arcmin')
  }

  const its.create_default_corrnames := function(ddescid){
    names := ['']    
    if(its.ncorr[ddescid] >= 1)
      names[1] := 'XX'
    if(its.ncorr[ddescid] >= 2)
      names[2] := 'YY'
    if(its.ncorr[ddescid] >= 4){
      names[3] := 'XY'
      names[4] := 'YX'
    }

    if(its.ncorr[ddescid] != 1 && its.ncorr[ddescid] != 2 && its.ncorr[ddescid] != 4){
      for(i in 1:its.ncorr[ddescid])
        names[i] := spaste('CORR', i)
    }
    return names
  }

  const its.get_datadescids := function(){
    wider its
    m := ms(its.msname)
    if(is_fail(m)) return fatal(IOERR, 'Error reading measurement set', m::)

    m.selectinit(datadescid=0, reset=T)
    its.dataDescIDs := m.range('data_desc_id').data_desc_id
    its.ndataDescIDs := len(its.dataDescIDs)

    its.fieldIDs := m.range(items='FIELD_ID').field_id
    its.fieldNames := m.range(items='FIELDS').fields

    if(is_fail(its.fieldIDs) || is_fail(its.fieldNames) || is_fail(its.dataDescIDs))
	return fatal(IOERR, 'Error reading measurement set - it is incomplete or corrupted')

    for(i in its.dataDescIDs){
      m.selectinit(reset=T)
      m.selectinit(datadescid=i)
      ddesc := spaste(i)      

      its.ddesc[ddesc] := [=]
      its.ddesc[ddesc].toProcess := F
      its.ddesc[ddesc].fieldIDs := m.range(items='FIELD_ID').field_id
      its.ddesc[ddesc].fieldNames := its.fieldNames[its.ddesc[ddesc].fieldIDs]

      its.ddesc[ddesc].ncorr := m.range(items='num_corr').num_corr
      its.ddesc[ddesc].nchan := m.range(items='num_chan').num_chan
      its.ddesc[ddesc].corrnames := m.range(items='corr_names').corr_names[,1]

      if(is_fail(its.ddesc[ddesc].ncorr) || is_fail(its.ddesc[ddesc].nchan))
        return fatal(IOERR, 'Error reading measurement set - it is incomplete or corrupted')

      if(is_fail(its.ddesc[ddesc].corrnames))
        its.ddesc[ddesc].corrnames := its.create_default_corrnames(i)
    }
    m.done()

    # get wavelength and frequency information
    t := table(spaste(its.msname, '/SPECTRAL_WINDOW'), ack=F)
    if(is_fail(t)) return fatal(IOERR, 'Error reading SPECTRAL_WINDOW table', t::)

    freq := t.getcol('REF_FREQUENCY')
    if(is_fail(freq)) return fatal(IOERR, 'Error reading REF_FREQUENCY table', freq::)
    bandwidth := t.getcol('TOTAL_BANDWIDTH')
    if(is_fail(bandwidth)) return fatal(IOERR, 'Error reading REF_FREQUENCY table', bandwidth::)
    t.done()
    
    for(i in its.dataDescIDs){
      ddescid := spaste(i)
      its.ddesc[ddescid].wavelength := dq.quantity((3.0E8/freq[i]), 'm')
      its.ddesc[ddescid].bandwidth := dq.quantity(bandwidth[i], 'Hz')
      its.ddesc[ddescid].frequency := dq.quantity(freq[i], 'Hz')
      its.ddesc[ddescid].fieldofview := its.calc_fov(freq[i])
    }
    return T
  }

  const its.get_obs_times := function(){
    # get the length of time each target is observed for
    wider its
    m := ms(its.msname)
    if(is_fail(m)) return fatal(IOERR, 'Error reading measurement set', m::)

    for(i in its.dataDescIDs){
      ddesc := spaste(i)      
      its.ddesc[ddesc].obstime := [=]
      for(j in its.ddesc[ddesc].fieldIDs){
        m.selectinit(reset=T)
        m.selectinit(datadescid=i)
        m.selecttaql(spaste('FIELD_ID==', j-1))

        obstime := m.getdata(['TIME']).time
        tmin := min(obstime)
        tmax := max(obstime)
        lenobs := dq.quantity(tmax - tmin, 's')
        its.ddesc[ddesc].obstime[spaste(j)] := dq.convert(lenobs, 'min')
      }
    }
    m.done()
    return T
  }


  const its.get_station_distances := function(){
    # read in the positions of each antenna station
    for(path in system.path.include){
      fname := spaste(path, '/antenna_stations.txt')
      f := open(spaste('<', fname))
      if(is_file(f)) break
    }
    if(is_fail(f)) return fatal(IOERR, 'Error reading stations table', f::)

    stations := [=]
    while(1){
      line := read(f) ~ s/\n$//
      words := split(line)
      if(len(words) == 0) break
      stations[words[1]] := as_float(words[2])
    }
    return stations
  }

  const its.calc_image_parms := function(){
    wider its 
    for(i in its.dataDescIDs){
      ddescid := spaste(i)
      cell := dq.quantity(dq.getvalue(its.ddesc[ddescid].wavelength)/
                         (3*dq.getvalue(its.maxbaseline)), 'rad')
      its.cell[ddescid] := dq.convert(cell, 'arcmin')

      x := dq.div(its.ddesc[ddescid].fieldofview, its.cell[ddescid])
      its.pixels[ddescid] := its.composite(as_integer(x.value+1))
    }

    for(i in its.dataDescIDs){
      ddescid := spaste(i)
      if(its.pixels[ddescid] > 1024){
        its.pixels[ddescid] := 1024
        its.ddesc[ddescid].fieldofview := dq.mul(its.pixels[ddescid], its.cell[ddescid])
      }
      if(its.pixels[ddescid] < 128){
        its.pixels[ddescid] := 128
        its.ddesc[ddescid].fieldofview := dq.mul(its.pixels[ddescid], its.cell[ddescid])
      }
    }
    return T
  }

  const its.get_antenna_info := function(){
    # read in the antenna information
    wider its

    at := table(spaste(its.msname, '/ANTENNA'), ack=F)
    if(!is_table(at)) return fatal(IOERR, 'Error reading ANTENNA table')
    ad := at.getcol('DISH_DIAMETER')
    its.antennadiameter := dq.quantity(min(ad), 'm')

    its.antennastation := at.getcol('STATION')
    its.antennaname := at.getcol('NAME')
    at.done()  

    distances := its.get_station_distances()
    its.antennadistance := []
    for(i in 1:len(its.antennastation))
      its.antennadistance[i] := distances[its.antennastation[i]]
    return T    
  }

  const its.get_obs_info := function(){
    # read in information about the observation
    wider its

    obstable := table(spaste(its.msname, '/OBSERVATION'), ack=F)
    if(!is_table(obstable)) return fatal(IOERR, 'Error reading OBSERVATION table')

    its.telescope_name := obstable.getcol('TELESCOPE_NAME')
    its.observer := obstable.getcol('OBSERVER')
    its.project := obstable.getcol('PROJECT')
    obstable.done()
    return T
  }

  const its.old_max_baseline := function(){
    # read in the maximum baseline in metres
    wider its
    t := table(its.msname, ack=F)
    if(!is_table(t)) return fatal(PARMERR, 'Error opening Measurement set')
    uvw := t.getcol('UVW')
    t.done()

    maxbaseline := max(sqrt(uvw[1,]*uvw[1,]+uvw[2,]*uvw[2,]))
    if(maxbaseline > 6000)
      maxbaseline := 6000
    its.maxbaseline := dq.quantity(maxbaseline, 'm')
    return T
  }

  const its.get_max_baseline := function(){
    # calculate the maximum baseline in metres
    wider its

    nantenna := len(its.antennaname)
    maxbaseline := its.antennadistance[nantenna] - its.antennadistance[1]
    its.antennas := array(1:nantenna)

    if(nantenna == 6){
      maxwithout6 := its.antennadistance[5] - its.antennadistance[1]
      if(maxwithout6 < 2000){
        its.ignore6 := T
        maxbaseline := maxwithout6
        its.antennas := array(1:5)
      }
      else
        its.ignore6 := F
    }
    its.maxbaseline := dq.quantity(maxbaseline, 'm')
    return T
  }

  const its.get_standard_cals := function(){
    wider its
    for(path in system.path.include){
      fname := spaste(path, '/atca_cals.txt')
      f := open(spaste('<', fname))
      if(is_file(f)) break
    }

    if(is_fail(f)) return fatal(IOERR, 'Error reading calibrator tables', f::)

    cals := ['']
    i := 1
    while(line := read(f)){
      cals[i] := line ~ s/\n//
      i +:= 1
    }

    its.standardCals := cals    
    return T
  }


# Public variables and functions

  const self.get_vars := function(){ return its }

  const self.get_ms_info := function(msname){
    wider its

    its.msname := msname

    ok := its.get_datadescids()
    if(is_fail(ok)) return fatal(PARMERR, 'Error reading dataDescIDs from MS', ok::)
    ok := its.get_obs_times()
    if(is_fail(ok)) return fatal(PARMERR, 'Error calculating obs time', ok::)
    ok := its.get_antenna_info()
    if(is_fail(ok)) return fatal(PARMERR, 'Error reading antenna info from MS', ok::)
    ok := its.get_max_baseline()
    if(is_fail(ok)) return fatal(PARMERR, 'Error reading max baseline from MS', ok::)
    ok := its.get_obs_info()
    if(is_fail(ok)) return fatal(PARMERR, 'Error reading obs info from MS', ok::)
    ok := its.calc_image_parms()
    if(is_fail(ok)) return fatal(PARMERR, 'Error reading antenna info from MS', ok::)
    ok := its.get_standard_cals()
    if(is_fail(ok)) return fatal(PARMERR, 'Error get standard cals from table', ok::)

    return T
  }

# Constructor

  return self.get_ms_info(msname)
}


