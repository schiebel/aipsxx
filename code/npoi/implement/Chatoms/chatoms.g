# chatoms.g:
# Copyright (C) 1999,2000,2001,2002
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: chatoms.g,v 19.0 2003/07/16 06:03:47 aips2adm Exp $

pragma include once

include 'emptyms.g';
include 'hdsfile.g'
include 'measures.g';
include 'note.g';
include 'quanta.g';
include 'table.g';

#chatoms := function(msname, chaname) {
const chatoms := function(msname, chaname) {
# utility function used elesewhere
  const near := function(arg1, arg2, tol=1E-5) {
    return abs(arg1 - arg2) < tol*max(abs(arg1), abs(arg2));
  }
# function specific data ie., a COMMON block!
  local nchan;
  local nant;
  local wavelength;
  local timerange := array(0, 2);
  local numscan;

  const fillmain := function(tabletool, hdstool) {
    wider nant, wavelength, timerange, numscan, nchan;
    hdstool.cdtop(); hdstool.cd('scandata.numscan');
    numscan := hdstool.get();

    hdstool.cdtop(); hdstool.cd('genconfig.inputbeam.stationid');
    const padnames := hdstool.getstring();
    const zeros := array(0, numscan);
    # Determine the scan times and exposures.
    local obstimes, exposure;
    {
      hdstool.cdtop(); hdstool.cd('date');
      local d := hdstool.getstring();
      d ~:= s/-/\//g;
      local day := dq.quantity(d);
      # determine if the exposure time is in the .cha file.
      hdstool.cdtop(); hdstool.cd('scandata'); 
      const scannodes := hdstool.ls();
      const hasexposure := any(scannodes == 'starttime') &
	any(scannodes == 'stoptime');
      if (!hasexposure) {
	exposure := array(90, numscan);
	note ('No exposure data, assuming 90 secs', priority='WARN', 
	     origin='chatoms');
      } else {
	hdstool.cdtop(); hdstool.cd('scandata.starttime');
	local starttime := hdstool.get();
	hdstool.cdtop(); hdstool.cd('scandata.stoptime');
	local stoptime := hdstool.get();
	exposure := stoptime - starttime;
      }
      hdstool.cdtop(); hdstool.cd('scandata.scantime');
      local midtime := hdstool.get();
      obstimes := dq.getvalue(dq.convert
			      (dq.add(day, dq.quantity(midtime, 's')), 's'));
      timerange[1] := min(obstimes);
      timerange[2] := max(obstimes);
    }
    # Determine the scanid's 
    hdstool.cdtop(); hdstool.cd('scandata.scanid');
    const scannumber := hdstool.get();
    # Determine the field id's;
    local fieldid := array(0, numscan);
    {
      hdstool.cdtop(); hdstool.cd('scandata.starid');
      local starids := hdstool.getstring();
      local uniqueids := unique(starids);
      local index := 1:len(uniqueids);
      for (i in 1:numscan) {
	fieldid[i] := index[uniqueids == starids[i]];
      }
      fieldid -:= 1;
    }
    # Determine the baselione id's
    hdstool.cdtop(); hdstool.cd('genconfig.outputbeam.baselineid');
    const allbaselines := hdstool.getstring();
    # Determine the looping parameters
    hdstool.cdtop(); hdstool.cd('genconfig.outputbeam.numoutbeam');
    const noutputbeams := hdstool.get();
    hdstool.cdtop(); hdstool.cd('genconfig.outputbeam.numbaseline');
    const baselines := hdstool.get();
  
    local row := 1;
    local uvw1, uvw2;
    for (bm in 1:noutputbeams) {
      local beamstring := spaste('scandata.outputbeam(', bm, ')');
      hdstool.cdtop(); ok := hdstool.cd(spaste(beamstring, '.uvw'));
      if (is_fail(ok)) fail;
      local alluvw := hdstool.get();
      local inmeters := T;
      if (length(shape(alluvw)) == 4) inmeters := F;
      hdstool.cdtop(); hdstool.cd(spaste(beamstring, '.vissq'));
      local allvis := hdstool.get();
      hdstool.cdtop(); hdstool.cd(spaste(beamstring, '.vissqerr'));
      local allsigma := hdstool.get();
      for (bl in 1:baselines[bm]) {
	local baseline := allbaselines[bl,bm];
	tabletool.addrows(numscan);
# Fill the UVW column
	local thisuvw
	if (inmeters) {
	  thisuvw := alluvw[bl, , ];
	} else { # need to convert from wavelengths to meters
	  thisuvw := alluvw[,bl, , ];
	  for (sc in 1:numscan) {
	    for (uvw in 1:3) {
	      thisuvw[,uvw,sc] *:= wavelength;
	    }
	    if (!all(near(thisuvw[,1,sc], thisuvw[1,1,sc])) || 
		!all(near(thisuvw[,2,sc], thisuvw[1,2,sc])) || 
		!all(near(thisuvw[,3,sc], thisuvw[1,3,sc]))) {
	      throw(spaste('UVW are not the same for scan ', sc, 
			   ' in baseline ', bl, ' in beam ', bm),
		    origin='chatoms.g');
	    }
	  }
	  thisuvw := thisuvw[1,,];
	}
	if (bm == 2) {
	  uvw2 := thisuvw;
	} else if (bm == 3) {
	  uvw1 := thisuvw;
	}
	tabletool.putcol('UVW', thisuvw, startrow=row, nrow=numscan);
	tabletool.putcol('UVW2', thisuvw*0.0, startrow=row, nrow=numscan);
# Fill in the DATA, FLAG, FLAG_CATEGORY, FLAG_ROW, SIGMA & WEIGHT columns.
	local thisvis := allvis[,bl,];
	local oldshape := shape(thisvis);
	local newshape := [1,oldshape];
	{ # This bit of code writes the NS_NPOI_VISSQ column
	  local thisvissq := thisvis;
	  thisvissq::shape := newshape;
	  tabletool.putcol('NS_NPOI_VISSQ', thisvissq, startrow=row,
			   nrow=numscan);
	}
	local thissigma := allsigma[,bl,];
	local thisflag := (thissigma < 0) | (thisvis < 0);
	thisvis[thisflag] := 0;
	thisvis := as_complex(sqrt(thisvis));
# The conversion of closure phase to baseline phase needs a
# significant rework when there are more than three baselines
 	if (bm == 1) { # assign all the triple phase to baseline # 1
	  hdstool.cdtop();hdstool.cd(spaste('scandata.triple(1).triplephase'));
 	  thisvis *:= exp(complex(0, hdstool.get()));
 	}
	thisvis::shape := newshape;
	thissigma::shape := newshape;
	thisflag::shape := newshape;
	tabletool.putcol('DATA', thisvis, startrow=row, nrow=numscan);
	tabletool.putcol('FLAG', thisflag, startrow=row, nrow=numscan);
	newshape := [newshape[1:2], 1, newshape[3]];
	thisflag::shape := newshape
	tabletool.putcol('FLAG_CATEGORY', thisflag, 
			 startrow=row, nrow=numscan);
	tabletool.putcolkeyword('FLAG_CATEGORY', 'CATEGORY', 'CHA_FLAGS');
	local rowflag := array(F, numscan);
	local sigma := array(as_float(1), 1, numscan);
	local weight := array(as_float(0), 1, numscan);
	for (sc in 1:numscan) {
	  rowflag[sc] := all(thisflag[,,,sc]);
	  if (rowflag[sc] == F) {
	    local goodchan := thisflag[,,,sc] == F;
	    local ngood := length(goodchan[goodchan]);
	    sigma[1, sc] := sum(thissigma[1, goodchan, sc])/ngood;
	    weight[1, sc] := 1.0/((sigma[1,sc]/ngood)^2);
	  }
	}
	tabletool.putcol('FLAG_ROW', rowflag, startrow=row, nrow=numscan);
	tabletool.putcol('SIGMA', sigma, startrow=row, nrow=numscan);
	tabletool.putcol('WEIGHT', weight, startrow=row, nrow=numscan);
# Fill the antenna columns
	local ant1 := [1:nant][split(baseline, '-')[1] == padnames] - 1;
	local ant2 := [1:nant][split(baseline, '-')[2] == padnames] - 1;
	tabletool.putcol('ANTENNA1', array(ant1, numscan), 
			 startrow=row, nrow=numscan);
	tabletool.putcol('ANTENNA2', array(ant2, numscan), 
			 startrow=row, nrow=numscan);
	tabletool.putcol('ANTENNA3', array(-1, numscan), 
			 startrow=row, nrow=numscan);
# Fill the TIME, TIME_CENTROID, INTERVAL & EXPOSURE COLUMNS
	tabletool.putcol('TIME', obstimes, startrow=row, nrow=numscan);
	tabletool.putcol('TIME_CENTROID', obstimes, startrow=row, nrow=numscan);
	tabletool.putcol('EXPOSURE', exposure, startrow=row, nrow=numscan);
	tabletool.putcol('INTERVAL', exposure, startrow=row, nrow=numscan);
# Fill the ARRAY_ID
	tabletool.putcol('ARRAY_ID', zeros, startrow=row, nrow=numscan);
	tabletool.putcol('FEED1', zeros, startrow=row, nrow=numscan);
	tabletool.putcol('FEED2', zeros, startrow=row, nrow=numscan);
	tabletool.putcol('FEED3', zeros, startrow=row, nrow=numscan);
	tabletool.putcol('OBSERVATION_ID', zeros, startrow=row, nrow=numscan);
	tabletool.putcol('DATA_DESC_ID', zeros,startrow=row, nrow=numscan);
	tabletool.putcol('PROCESSOR_ID', zeros, startrow=row, nrow=numscan);
	tabletool.putcol('SCAN_NUMBER', scannumber,startrow=row, nrow=numscan);
	tabletool.putcol('FIELD_ID', fieldid ,startrow=row, nrow=numscan);
	row +:= numscan;
      }
    }
# Add the triple products
    {
      hdstool.cdtop(); hdstool.cd('genconfig.triple.numtriple');
      const numtriple := hdstool.get();
      hdstool.cdtop(); hdstool.cd('genconfig.triple.outputbeam');
      const alltriplebeams := hdstool.get();
      hdstool.cdtop(); hdstool.cd('genconfig.triple.baseline');
      const alltriplebaselines := hdstool.get();
      for (t in 1:numtriple) {
	tabletool.addrows(numscan);
	const triplebeams := alltriplebeams[,t];
	const triplebaselines := alltriplebaselines[,t];
	local tripleants :=array(0, 3);
	for (bl in 1:3) {
	  local baseline :=
	    allbaselines[triplebaselines[bl]+1, triplebeams[bl]+1];
	  local ant1 := [1:nant][split(baseline, '-')[1] == padnames] - 1;
	  local ant2 := [1:nant][split(baseline, '-')[2] == padnames] - 1;
	  if (bl == 2) {
	    tripleants[3] := ant2;
	  } else if (bl == 3) {
	    tripleants[1] := ant1;
	    tripleants[2] := ant2;
	  }
	}
	tabletool.putcol('ANTENNA1', array(tripleants[1], numscan), 
			 startrow=row, nrow=numscan);
	tabletool.putcol('ANTENNA2', array(tripleants[2], numscan), 
			 startrow=row, nrow=numscan);
	tabletool.putcol('ANTENNA3', array(tripleants[3], numscan), 
			 startrow=row, nrow=numscan);
	local tripledata := spaste('scandata.triple(', t, ')');
	hdstool.cdtop(); hdstool.cd(spaste(tripledata, '.compltriple'));
	local trpri := hdstool.get();
	hdstool.cdtop(); hdstool.cd(spaste(tripledata, '.compltripleerr'));
	local trprierr := hdstool.get();
	local trp := complex(trpri[1,,], trpri[2,,]);
	local trperr := complex(trprierr[1,,], trprierr[2,,]);
	local trpshape := [1, nchan, numscan];
	trp::shape := trpshape; 
	trperr::shape := trpshape;
	local trpflag := real(trperr) < 0.0;
	tabletool.putcol('UVW', uvw1, startrow=row, nrow=numscan);
	tabletool.putcol('UVW2', uvw2, startrow=row, nrow=numscan);
	tabletool.putcol('DATA', trp, startrow=row, nrow=numscan);
	tabletool.putcol('FLAG', trpflag, startrow=row, nrow=numscan);
	local newshape := [trpshape[1:2], 1, trpshape[3]];
	trpflag::shape := newshape;
	tabletool.putcol('FLAG_CATEGORY', trpflag, startrow=row, 
			 nrow=numscan);
	local rowflag := array(F, numscan);
	local sigma := array(as_float(1), 1, numscan);
	local weight := array(as_float(0), 1, numscan);
	for (sc in 1:numscan) {
	  rowflag[sc] := all(trpflag[,,,sc]);
	  if (rowflag[sc] == F) {
	    local goodchan := trpflag[,,,sc] == F;
	    local ngood := length(goodchan[goodchan]);
	    sigma[1, sc] := sum(real(trperr[1, goodchan, sc]))/ngood;
	    weight[1, sc] := 1.0/((sigma[1,sc]/ngood)^2);
	  }
	}
	tabletool.putcol('FLAG_ROW', rowflag, startrow=row, nrow=numscan);
	tabletool.putcol('SIGMA', sigma, startrow=row, nrow=numscan);
	tabletool.putcol('WEIGHT', weight, startrow=row, nrow=numscan);
	tabletool.putcol('TIME', obstimes, startrow=row, nrow=numscan);
	tabletool.putcol('TIME_CENTROID', obstimes, startrow=row, nrow=numscan);
	tabletool.putcol('EXPOSURE', exposure, startrow=row, nrow=numscan);
	tabletool.putcol('INTERVAL', exposure, startrow=row, nrow=numscan);
	tabletool.putcol('ARRAY_ID', zeros, startrow=row, nrow=numscan);
	tabletool.putcol('FEED1', zeros, startrow=row, nrow=numscan);
	tabletool.putcol('FEED2', zeros, startrow=row, nrow=numscan);
	tabletool.putcol('FEED3', zeros, startrow=row, nrow=numscan);
	tabletool.putcol('OBSERVATION_ID', zeros, startrow=row, nrow=numscan);
	tabletool.putcol('DATA_DESC_ID', zeros,startrow=row, nrow=numscan);
	tabletool.putcol('PROCESSOR_ID', zeros, startrow=row, nrow=numscan);
	tabletool.putcol('SCAN_NUMBER', scannumber,startrow=row, nrow=numscan);
	tabletool.putcol('FIELD_ID', fieldid ,startrow=row, nrow=numscan);
	row +:= numscan;
      }
    }
  }
  const fillantenna := function(tabletool, hdstool) {
    wider nant;
    tabletool.addrows(nant);

    hdstool.cdtop(); hdstool.cd('genconfig.inputbeam.stationid');
    const stationid := hdstool.getstring();
    hdstool.cdtop(); hdstool.cd('genconfig.inputbeam.siderostatid');
    const antid := hdstool.get();
    {
      local stationname := '';
      for (a in 1:nant) {
 	stationname := spaste(stationname, 'NPOI:', stationid[a], ' ');
      }
      tabletool.putcol('STATION', split(stationname), 1, nant);
      tabletool.putcol('NAME', split(as_string(antid)), 1, nant);
    }
# Determining the antenna positions takes a bit of work
    {
      hdstool.cdtop(); hdstool.cd('geoparms.latitude');
      local lat := dq.quantity(hdstool.get(), 'deg');
      hdstool.cdtop(); hdstool.cd('geoparms.longitude');
      local long := dq.quantity(hdstool.get(), 'deg');
      hdstool.cdtop(); hdstool.cd('geoparms.altitude');
      local alt := dq.quantity(hdstool.get() , 'm');
      local refpos := dm.measure(dm.position('WGS84', lat, long, alt), 'ITRF');
      local xyz := dm.addxvalue(refpos);
      local refx := dq.getvalue(dq.convert(xyz[1], 'm'));
      local refy := dq.getvalue(dq.convert(xyz[2], 'm'));
      local refz := dq.getvalue(dq.convert(xyz[3], 'm'));
      hdstool.cdtop(); hdstool.cd('genconfig.inputbeam.stationcoord');
      local antpos := hdstool.get();
      local latr := dq.getvalue(dq.convert(lat, 'rad'));
      local longr := dq.getvalue(dq.convert(long, 'rad'));
      for (a in 1:nant) {
	local east := antpos[1, a];
	local north := antpos[2, a];
	local x := -cos(latr) * east - sin(longr) * north * sin(latr);
	local y :=  sin(latr) * east - sin(longr) * north * sin(latr);
	local z := cos(longr) * north;
	tabletool.putcell('POSITION', a, [refx + x, refy+y, refz+z]);
      }
    }
    tabletool.putcol('OFFSET', array(0.0, 3, nant), 1, nant);
    tabletool.putcol('DISH_DIAMETER', rep(0.12, nant), 1, nant);
    tabletool.putcol('MOUNT', rep('ALT-AZ', nant), 1, nant);
    tabletool.putcol('TYPE', rep('GROUND-BASED', nant), 1, nant);
    tabletool.putcol('FLAG_ROW', rep(F, nant), 1, nant);
  }

  const filldatadescription := function(tabletool, hdstool) {
    tabletool.addrows(1);
    tabletool.putcell('SPECTRAL_WINDOW_ID', 1, 0);
    tabletool.putcell('POLARIZATION_ID', 1, 0);
    tabletool.putcell('FLAG_ROW', 1, F);
  }

  const fillpolarization := function(tabletool, hdstool) {
    tabletool.addrows(1);
    tabletool.putcell('NUM_CORR', 1, 1);
    tabletool.putcell('CORR_TYPE', 1, 5);
    tabletool.putcell('CORR_PRODUCT', 1, array(0, 2, 1));
    tabletool.putcell('FLAG_ROW', 1, F);
  }

  const fillspectralwindow := function(tabletool, hdstool) {
    wider nchan, wavelength;
    tabletool.addrows(1);
    hdstool.cdtop(); hdstool.cd('genconfig.outputbeam.numspecchan');
    tabletool.putcell('NUM_CHAN', 1, nchan);
    local freqs := dq.getvalue(dq.constants('c'))/wavelength;
    tabletool.putcell('CHAN_FREQ', 1, freqs);
    tabletool.putcell('REF_FREQUENCY', 1, freqs[nchan/2]);
    tabletool.putcell('MEAS_FREQ_REF', 1, 5);
    tabletool.putcell('NAME', 1, 'NPOI_USUAL_FREQS');
    local res := rep(0.0, nchan);
    res[2:(nchan-1)] := ((freqs[2:(nchan-1)] - freqs[1:(nchan-2)]) -
			 (freqs[2:(nchan-1)] - freqs[3:nchan]))/2;
    res[1] := res[2];
    res[32] := res[31];
    tabletool.putcell('RESOLUTION', 1, res);
    tabletool.putcell('CHAN_WIDTH', 1, res);
    tabletool.putcell('EFFECTIVE_BW', 1, res);
    tabletool.putcell('TOTAL_BANDWIDTH', 1, freqs[nchan] - freqs[1]);
    tabletool.putcell('NET_SIDEBAND', 1, 1);
    tabletool.putcell('IF_CONV_CHAIN', 1, 0);
    tabletool.putcell('FREQ_GROUP', 1, 1)
    tabletool.putcell('FREQ_GROUP_NAME', 1, 'NPOI_USUAL_FREQS')
    tabletool.putcell('FLAG_ROW', 1, F);
  }

  const fillfeed := function(tabletool, hdstool) {
    wider nant;
    tabletool.addrows(nant);
    tabletool.putcol('ANTENNA_ID', seq(0, nant-1));
    tabletool.putcol('FEED_ID', rep(0, nant));
    tabletool.putcol('SPECTRAL_WINDOW_ID', array(-1,  nant));
    tabletool.putcol('TIME', array(0.0, nant));
    tabletool.putcol('INTERVAL', rep(1E30, nant));
    tabletool.putcol('NUM_RECEPTORS', rep(2, nant));
     tabletool.putcol('BEAM_ID', rep(-1, nant));
    tabletool.putcol('BEAM_OFFSET', array(0.0, 2, 2, nant));
    local resp := array(0+0i, 2, 2); 
    resp[1,1] := resp[2,2] := 1;
    tabletool.putcol('POLARIZATION_TYPE', array("R L", 2, nant));
    tabletool.putcol('POL_RESPONSE', array(resp, 2, 2, nant));
    tabletool.putcol('POSITION', array(0, 3, nant));
    tabletool.putcol('RECEPTOR_ANGLE', array([0.0, pi/2], 2, nant));
  }

  const fillfield := function(tabletool, hdstool) {
    wider numscan;
    local fieldid, uniqueids;
    {
      hdstool.cdtop(); hdstool.cd('scandata.starid');
      local starids := hdstool.getstring();
      uniqueids := unique(starids);
      local index := 1:len(starids);
      for (id in uniqueids) {
	fieldid[id] :=  min(index[starids == id]);
      }
    }
    const nids := len(uniqueids);
    hdstool.cdtop(); hdstool.cd('scandata');
    const scannodes := hdstool.ls();
    const hasradec := any(scannodes == 'ra') & any(scannodes == 'dec');
    local ra := array(0.0, numscan);
    dec := array(pi/2, numscan);
    if (!hasradec) {
      note ('No ra and dec, placing all scans at the North pole',
	    priority='WARN', origin='chatoms');
    } else {
      hdstool.cdtop(); hdstool.cd('scandata.ra');
      ra := dq.getvalue(dq.convert
			(dq.quantity(hdstool.get(), 'h'),'rad'));
      hdstool.cdtop(); hdstool.cd('scandata.dec');
      dec := dq.getvalue(dq.convert
			 (dq.quantity(hdstool.get(), 'deg'),'rad'));
    }
    tabletool.addrows(nids);
    tabletool.putcol('NAME', uniqueids, 1, nids);
    local dirs := array(0.0, 2, 1, nids);
    for (i in 1:nids) {
      local f := fieldid[i];
      dirs[1, 1, i] := ra[f];
      dirs[2, 1, i] := dec[f];
    }
    tabletool.putcol('DELAY_DIR', dirs, 1, nids);
    tabletool.putcol('PHASE_DIR', dirs, 1, nids);
    tabletool.putcol('REFERENCE_DIR', dirs, 1, nids);
    tabletool.putcol('NUM_POLY', array(0, nids), 1, nids);
    tabletool.putcol('TIME', array(0, nids), 1, nids);
    tabletool.putcol('CODE', array('', nids), 1, nids);
    tabletool.putcol('SOURCE_ID', array(-1, nids), 1, nids);
    tabletool.putcol('FLAG_ROW', array(F, nids), 1, nids);
  }

  const fillobservation := function(tabletool, hdstool) {
    wider timerange;
    tabletool.addrows(1);
    hdstool.cdtop(); hdstool.cd('systemid');
    tabletool.putcell('TELESCOPE_NAME', 1, hdstool.getstring());
    tabletool.putcell('TIME_RANGE', 1, timerange);
    hdstool.cdtop(); hdstool.cd('userid');
    tabletool.putcell('OBSERVER', 1, hdstool.getstring());
# The log is not copied because the resulting OBSERVATION table will
# then crash the table browser (and glish).
#    hdstool.cdtop(); hdstool.cd('observerlog');
#    tabletool.putcell('LOG', 1, hdstool.getstring());
    tabletool.putcell('LOG', 1, 'not copied');
    tabletool.putcell('SCHEDULE_TYPE', 1, 'unknown');
    tabletool.putcell('SCHEDULE', 1, 'unknown');
    tabletool.putcell('PROJECT', 1, 'unknown');
    tabletool.putcell('RELEASE_DATE', 1, timerange[2] + 315576000);
  }
  
  local file := hdsfile(chaname);
  if (is_fail(file)) fail;
# Get a few basic things about the data that are used in numerous functions
# 1. The number of array elements
  file.cdtop(); file.cd('genconfig.inputbeam.numsid');
  const nant := file.get();
# 2. The number of spectral channels
  file.cdtop(); file.cd('genconfig.outputbeam.numspecchan');
  const nchan := file.get()[1];
  if (any(file.get() != nchan)) {
    return throw('The number of channels is different for different output',
		 ' beams', origin='chatoms');
  }
# 3. The wavelengths of these channels
  file.cdtop(); file.cd('genconfig.outputbeam.wavelength');
  const wavelength := file.get()[,1];
  {
    local allwavelengths := file.get();
    for (bm in 2:shape(allwavelengths)[2]) {
      if (any(allwavelengths[,bm] != wavelength)) {
	return throw('The wavelengths for different output',
		   ' beams are not the same.', origin='chatoms');
      }
    }
  }
#create an empty measurement set.
  emptyms(msname);
  maintable := table(msname, readonly=F, ack=F);
# add optional columns
  {
    local datadesc := tablecreatearraycoldesc('DATA', as_complex(0), 
					      ndim=2, shape=[1,nchan]);
    local ant3desc := tablecreatescalarcoldesc('ANTENNA3', -1);
    local feed3desc := tablecreatescalarcoldesc('FEED3', -1);
    local uvw2desc := tablecreatearraycoldesc('UVW2', [0.0,0.0,0.0], 1, [3]);
    local vissqdesc := tablecreatearraycoldesc('NS_NPOI_VISSQ', as_float(0.0),
					       ndim=2, shape=[1,nchan]);
    local newcolsdesc :=
      tablecreatedesc(datadesc, ant3desc, feed3desc, uvw2desc, vissqdesc);
    maintable.addcols(newcolsdesc);
    maintable.putcolkeyword('UVW2', 'QuantumUnits', array('m', 3));
    maintable.putcolkeyword('UVW2', 'MEASINFO', [type='uvw', Ref='J2000']);
  }
# Fill all the columns in the main table
  ok := fillmain(maintable, file);
  if (is_fail(ok)) fail;
  {
    local anttable := 
      table(maintable.getkeyword('ANTENNA'), readonly=F, ack=F);
    fillantenna(anttable, file);
    anttable.done();
  }
  {
    local feedtable := 
      table(maintable.getkeyword('FEED'), readonly=F, ack=F);
    fillfeed(feedtable, file);
    feedtable.done();
  }
  {
    local fieldtable := 
      table(maintable.getkeyword('FIELD'), readonly=F, ack=F);
    fillfield(fieldtable, file);
    fieldtable.done();
  }
  {
    local ddtable := 
      table(maintable.getkeyword('DATA_DESCRIPTION'), readonly=F, ack=F);
    filldatadescription(ddtable, file);
    ddtable.done();
  }
  {
    local spwtable := 
      table(maintable.getkeyword('SPECTRAL_WINDOW'), readonly=F, ack=F);
    fillspectralwindow(spwtable, file);
    spwtable.done();
  }
  {
    local poltable := 
      table(maintable.getkeyword('POLARIZATION'), readonly=F, ack=F);
    fillpolarization(poltable, file);
    poltable.done();
  }
  {
    local flagtable := 
      table(maintable.getkeyword('FLAG_CMD'), readonly=F, ack=F);
#    fillflagcmd(flagtable, file);
    flagtable.done();
  }
  {
    local histable := 
      table(maintable.getkeyword('HISTORY'), readonly=F, ack=F);
#    fillhistory(histable, file);
    histable.done();
  }
  {
    local obstable := 
      table(maintable.getkeyword('OBSERVATION'), readonly=F, ack=F);
    fillobservation(obstable, file);
    obstable.done();
  }
  {
    local pointingtable := 
      table(maintable.getkeyword('POINTING'), readonly=F, ack=F);
#    fillpointing(pointingtable, file);
    pointingtable.done();
  }
  {
    local processortable := 
      table(maintable.getkeyword('PROCESSOR'), readonly=F, ack=F);
#    fillprocessor(processortable, file);
    processortable.done();
  }
  {
    local statetable := 
      table(maintable.getkeyword('STATE'), readonly=F, ack=F);
#    fillstate(statetable, file);
    statetable.done();
  }
# Close all the tools 
  maintable.done();
  file.done();
}
