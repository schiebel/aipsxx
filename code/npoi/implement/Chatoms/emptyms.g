# emptyms.g:
# Copyright (C) 2000,2001
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
# $Id: emptyms.g,v 19.0 2003/07/16 06:03:48 aips2adm Exp $

pragma include once

include 'table.g';

const emptyms := function(filename) {
  local verbose := F;
#emptyms := function(filename) {
#  local verbose := T;

  const createboolcol := function(colname) {
    return tablecreatescalarcoldesc(colname, T);
  }

  const createintcol := function(colname) {
    return tablecreatescalarcoldesc(colname, 1);
  }

  const createfltcol := function(colname) {
    return tablecreatescalarcoldesc(colname, as_float(1.0));
  }

  const createdblcol := function(colname) {
    return tablecreatescalarcoldesc(colname, 1.0);
  }

  const createstringcol := function(colname) {
    return tablecreatescalarcoldesc(colname, 'abc');
  }

  const createboolarrcol := function(colname, ndim) {
    return tablecreatearraycoldesc(colname, T, ndim);
  }

  const createintarrcol := function(colname, ndim) {
    return tablecreatearraycoldesc(colname, 1, ndim);
  }

  const createfltarrcol := function(colname, ndim) {
    return tablecreatearraycoldesc(colname, as_float(0.0), ndim);
  }

  const createdblarrcol := function(colname, ndim) {
    return tablecreatearraycoldesc(colname, 0.0, ndim);
  }

  const createcomplexarrcol := function(colname, ndim) {
    return tablecreatearraycoldesc(colname, as_complex(1+1i), ndim);
  }

  const createstringarrcol := function(colname, ndim) {
    return tablecreatearraycoldesc(colname, 'abc', ndim);
  }

  const createposcol := function(colname) {
    return tablecreatearraycoldesc(colname, [0.0,0.0,0.0], 1, [3]);
  }

  const createepochcol := function(colname) {
    return createdblcol(colname);
  }

  const createepocharrcol := function(colname, ndim) {
    return createdblarrcol(colname, ndim);
  }

  const createuvwcol := function(colname) {
    return tablecreatearraycoldesc(colname, [0.0,0.0,0.0], 1, [3]);
  }

  const createdircol := function(colname) {
    return tablecreatearraycoldesc(colname, 0.0, 1, [2]);
  }

  const createdirarrcol := function(colname, ndim) {
    return createdblarrcol(colname, ndim);
  }

  const createfreqcol := function(colname) {
    return createdblcol(colname);
  }

  const createfreqarrcol := function(colname, ndim) {
    return createdblarrcol(colname, ndim);
  }

  const addtimekey := function(table, colname) {
    return table.putcolkeyword(colname, 'QuantumUnits', 's');
  }

  const addlengthkey := function(table, colname) {
    return table.putcolkeyword(colname, 'QuantumUnits', 'm');
  }

  const addanglekey := function(table, colname) {
    return table.putcolkeyword(colname, 'QuantumUnits', 'rad');
  }

  const addtempkey := function(table, colname) {
    table.putcolkeyword(colname, 'QuantumUnits', 'K');
    return T;
  }

  const addhzkey := function(table, colname) {
    return table.putcolkeyword(colname, 'QuantumUnits', 'Hz');
  }

  const addepochkey := function(table, colname) {
    addtimekey(table, colname);
    return table.putcolkeyword(colname, 'MEASINFO',
			       [type='epoch', Ref='TAI']);
  }

  const addposkey := function(table, colname) {
    table.putcolkeyword(colname, 'QuantumUnits', array('m', 3));
    return table.putcolkeyword(colname, 'MEASINFO', 
			       [type='position', Ref='ITRF']);
  }

  const adddirkey := function(table, colname) {
    table.putcolkeyword(colname, 'QuantumUnits', array('rad', 2));
    return table.putcolkeyword(colname, 'MEASINFO',
			       [type='direction', Ref='J2000']);
  }

  const addfreqkey := function(table, colname) {
    addhzkey(table, colname);
    return table.putcolkeyword(colname, 'MEASINFO', 
			       [type='frequency', Ref='LSRK']);
  }

  const adduvwkey := function(table, colname) {
    table.putcolkeyword(colname, 'QuantumUnits', array('m', 3));
    return table.putcolkeyword(colname, 'MEASINFO', [type='uvw', Ref='J2000']);
  }

  const newmaintable := function(filename) {
    const time := createepochcol('TIME');
    const ant1 := createintcol('ANTENNA1');
    const ant2 := createintcol('ANTENNA2');
    const feed1 := createintcol('FEED1');
    const feed2 := createintcol('FEED2');
    const ddid := createintcol('DATA_DESC_ID');
    const prid := createintcol('PROCESSOR_ID');
    const fldid := createintcol('FIELD_ID');
    const interval := createdblcol('INTERVAL');
    const exp := createdblcol('EXPOSURE');
    const timec := createepochcol('TIME_CENTROID');
    const scan := createintcol('SCAN_NUMBER');
    const arrid := createintcol('ARRAY_ID');
    const obsid := createintcol('OBSERVATION_ID');
    const stateid := createintcol('STATE_ID');
    const uvw := createuvwcol('UVW');
    const sigma := createfltarrcol('SIGMA', 1);
    const weight := createfltarrcol('WEIGHT', 1);
    const flag := createboolarrcol('FLAG', 2);
    const flagcat := createboolarrcol('FLAG_CATEGORY', 3);
    const flagrow := createboolcol('FLAG_ROW');
    
    const td := tablecreatedesc(time, ant1, ant2, feed1, feed2, 
				ddid, prid, fldid, interval, exp, timec,
				scan, arrid, obsid, stateid, 
				uvw, sigma, weight, flag, flagcat, flagrow);
    local ms := table(filename, tabledesc=td, nrow=0, ack=verbose);
    addtimekey(ms, 'EXPOSURE');
    addtimekey(ms, 'INTERVAL');
    addepochkey(ms, 'TIME');
    addepochkey(ms, 'TIME_CENTROID');
    adduvwkey(ms, 'UVW');
    return ms;
  }
  
  const newantennasubtable := function(ms) {
    const name := createstringcol('NAME');
    const station := createstringcol('STATION');
    const type := createstringcol('TYPE');
    const mount := createstringcol('MOUNT');
    const pos := createposcol('POSITION');
    const offset := createposcol('OFFSET');
    const dish := createdblcol('DISH_DIAMETER');
    const flagrow := createboolcol('FLAG_ROW');
    const td := tablecreatedesc(name, station, type, mount, 
				pos, offset, dish, flagrow);
    const tablename := spaste(filename, '/ANTENNA');
    local tab := table(tablename, tabledesc=td, nrow=0, ack=verbose);
    addlengthkey(tab, 'DISH_DIAMETER');
    addposkey(tab, 'OFFSET');
    addposkey(tab, 'POSITION');
    tab.close();
    ms.putkeyword('ANTENNA', spaste('Table: ', tablename));
    return T;
  }
  
  const newdatadescriptionsubtable := function(ms) {
    const spwid := createintcol('SPECTRAL_WINDOW_ID');
    const polid := createintcol('POLARIZATION_ID');
    const flagrow := createboolcol('FLAG_ROW');

    const td := tablecreatedesc(spwid, polid, flagrow);
    const tablename := spaste(ms.name(), '/DATA_DESCRIPTION');
    local tab := table(tablename, tabledesc=td, nrow=0, ack=verbose);
    tab.close();
    ms.putkeyword('DATA_DESCRIPTION', spaste('Table: ', tablename));
    return T;
  }
  
  const newfeedsubtable := function(ms) {
    const antid := createintcol('ANTENNA_ID');
    const feedid := createintcol('FEED_ID');
    const spwid := createintcol('SPECTRAL_WINDOW_ID');
    const time := createepochcol('TIME');
    const interval := createdblcol('INTERVAL');
    const nrec := createintcol('NUM_RECEPTORS');
    const beamid := createintcol('BEAM_ID');
    const beamoff := createdirarrcol('BEAM_OFFSET', 2);
    const poltype := createstringarrcol('POLARIZATION_TYPE', 1);
    const polresp := createcomplexarrcol('POL_RESPONSE', 2);
    const pos := createposcol('POSITION');
    const reca := createdblarrcol('RECEPTOR_ANGLE', 1);

    const td := tablecreatedesc(antid, feedid, spwid, time, interval,
				nrec, beamid, beamoff, 
				poltype, polresp, pos, reca);
    const tablename := spaste(filename, '/FEED');
    local tab := table(tablename, tabledesc=td, nrow=0, ack=verbose);
    addtimekey(tab, 'INTERVAL');
    addepochkey(tab, 'TIME');
    adddirkey(tab, 'BEAM_OFFSET');
    addposkey(tab, 'POSITION');
    addanglekey(tab, 'RECEPTOR_ANGLE');
    tab.close();
    ms.putkeyword('FEED', spaste('Table: ', tablename));
    return T;
  }

  const newfieldsubtable := function(ms) {
    const name := createstringcol('NAME');
    const code := createstringcol('CODE');
    const time := createepochcol('TIME');
    const npoly := createintcol('NUM_POLY');
    const dly := createdirarrcol('DELAY_DIR', 2);
    const phase := createdirarrcol('PHASE_DIR', 2);
    const refer := createdirarrcol('REFERENCE_DIR', 2);
    const srcid := createintcol('SOURCE_ID');
    const flagrow := createboolcol('FLAG_ROW');

    const td := tablecreatedesc(name, code, time, npoly,
				dly, phase, refer, srcid, flagrow);
    const tablename := spaste(filename, '/FIELD');
    local tab := table(tablename, tabledesc=td, nrow=0, ack=verbose);
    adddirkey(tab, 'DELAY_DIR');
    adddirkey(tab, 'PHASE_DIR');
    adddirkey(tab, 'REFERENCE_DIR');
    addepochkey(tab, 'TIME');
    tab.close();
    ms.putkeyword('FIELD', spaste('Table: ', tablename));
    return T;
  }
  
  const newflagcmdsubtable := function(ms) {
    const time := createepochcol('TIME');
    const interval := createdblcol('INTERVAL');
    const type := createstringcol('TYPE');
    const reason := createstringcol('REASON');
    const level := createintcol('LEVEL');
    const severity := createintcol('SEVERITY');
    const applied := createboolcol('APPLIED');
    const command := createstringcol('COMMAND');
    const td := tablecreatedesc(time, interval, type, reason, level, 
				severity, applied, command);
    const tablename := spaste(ms.name(), '/FLAG_CMD');
    local tab := table(tablename, tabledesc=td, nrow=0, ack=verbose);
    addepochkey(tab, 'TIME');
    addtimekey(tab, 'INTERVAL');
    tab.close();
    ms.putkeyword('FLAG_CMD', spaste('Table: ', tablename));
    return T;
  }
  
  const newhistorysubtable := function(ms) {
    const time := createepochcol('TIME');
    const obsid := createintcol('OBSERVATION_ID');
    const message := createstringcol('MESSAGE');
    const priority := createstringcol('PRIORITY');
    const origin := createstringcol('ORIGIN');
    const objectid := createintcol('OBJECT_ID');
    const application := createstringcol('APPLICATION');
    const clicommand := createstringarrcol('CLI_COMMAND', 1);
    const appparms := createstringarrcol('APP_PARAMS', 1);

    const td := tablecreatedesc(time, obsid, message, priority, origin,
				objectid, application, clicommand, appparms);
    const tablename := spaste(filename, '/HISTORY');
    local tab := table(tablename, tabledesc=td, nrow=0, ack=verbose);
    addepochkey(tab, 'TIME');
    tab.close();
    ms.putkeyword('HISTORY', spaste('Table: ', tablename));
    return T;
  }
  
  const newobservationsubtable := function(ms) {
    const telname := createstringcol('TELESCOPE_NAME');
    const trange := createepocharrcol('TIME_RANGE', 1);
    const obs := createstringcol('OBSERVER');
    const log := createstringarrcol('LOG', 1);
    const stype := createstringcol('SCHEDULE_TYPE');
    const sched := createstringarrcol('SCHEDULE', 1);
    const project := createstringcol('PROJECT');
    const rdate := createepochcol('RELEASE_DATE');
    const flagrow := createboolcol('FLAG_ROW');

    const td := tablecreatedesc(telname, trange, obs, log, stype, 
				sched, project, rdate, flagrow);
    const tablename := spaste(filename, '/OBSERVATION');
    local tab := table(tablename, tabledesc=td, nrow=0, ack=verbose);
    addepochkey(tab, 'TIME_RANGE');
    addepochkey(tab, 'RELEASE_DATE');
    tab.close();
    ms.putkeyword('OBSERVATION', spaste('Table: ', tablename));
    return T;
  }
  
  const newpointingsubtable := function(ms) {
    const antid := createintcol('ANTENNA_ID');
    const time := createepochcol('TIME');
    const interval := createdblcol('INTERVAL');
    const name := createstringcol('NAME');
    const npoly := createintcol('NUM_POLY');
    const torigin := createepochcol('TIME_ORIGIN');
    const dir := createdirarrcol('DIRECTION', 2);
    const target := createdirarrcol('TARGET', 2);
    const tracking := createboolcol('TRACKING');

    const td := tablecreatedesc(antid, time, interval, name, npoly,
				torigin, dir, target, tracking);
    const tablename := spaste(filename, '/POINTING');
    local tab := table(tablename, tabledesc=td, nrow=0, ack=verbose);
    addepochkey(tab, 'TIME');
    addepochkey(tab, 'TIME_ORIGIN');
    addtimekey(tab, 'INTERVAL');
    adddirkey(tab, 'DIRECTION');
    adddirkey(tab, 'TARGET');
    tab.close();
    ms.putkeyword('POINTING', spaste('Table: ', tablename));
    return T;
  }
  
  const newpolarizationsubtable := function(ms) {
    const ncorr := createintcol('NUM_CORR');
    const ctype := createintarrcol('CORR_TYPE', 1);
    const cprod := createintarrcol('CORR_PRODUCT', 2);
    const flagrow := createboolcol('FLAG_ROW');

    const td := tablecreatedesc(ncorr, ctype, cprod, flagrow);
    const tablename := spaste(filename, '/POLARIZATION');
    local tab := table(tablename, tabledesc=td, nrow=0, ack=verbose);
    tab.close();
    ms.putkeyword('POLARIZATION', spaste('Table: ', tablename));
    return T;
  }
  
  const newprocessorsubtable := function(ms) {
    const type := createstringcol('TYPE');
    const subtype := createstringcol('SUB_TYPE');
    const typeid := createintcol('TYPE_ID');
    const modeid := createintcol('MODE_ID');
    const flagrow := createboolcol('FLAG_ROW');

    const td := tablecreatedesc(type, subtype, typeid, modeid, flagrow);
    const tablename := spaste(filename, '/PROCESSOR');
    local tab := table(tablename, tabledesc=td, nrow=0, ack=verbose);
    tab.close();
    ms.putkeyword('PROCESSOR', spaste('Table: ', tablename));
    return T;
  }
  
  const newspectralwindowsubtable := function(ms) {
    const nchan := createintcol('NUM_CHAN');
    const name := createstringcol('NAME');
    const reffreq := createfreqcol('REF_FREQUENCY');
    const cfreq := createfreqarrcol('CHAN_FREQ', 1);
    const cwidth := createfreqarrcol('CHAN_WIDTH', 1);
    const freqref := createintcol('MEAS_FREQ_REF');
    const effbw := createdblarrcol('EFFECTIVE_BW', 1);
    const res := createdblarrcol('RESOLUTION', 1);
    const bw := createdblcol('TOTAL_BANDWIDTH');
    const sideband := createintcol('NET_SIDEBAND');
    const ifc := createintcol('IF_CONV_CHAIN');
    const fgroup := createintcol('FREQ_GROUP');
    const fgroupname := createstringcol('FREQ_GROUP_NAME');
    const flagrow := createboolcol('FLAG_ROW');

    const td := tablecreatedesc(nchan, name, reffreq, cfreq, cwidth, freqref,
				effbw, res, bw, sideband, ifc, fgroup,
				fgroupname, flagrow);
    const tablename := spaste(filename, '/SPECTRAL_WINDOW');
    local tab := table(tablename, tabledesc=td, nrow=0, ack=verbose);
    addfreqkey(tab, 'REF_FREQUENCY');
    addfreqkey(tab, 'CHAN_FREQ');
    addhzkey(tab, 'CHAN_WIDTH');
    addhzkey(tab, 'EFFECTIVE_BW');
    addhzkey(tab, 'RESOLUTION');
    addhzkey(tab, 'TOTAL_BANDWIDTH');
    tab.close();
    ms.putkeyword('SPECTRAL_WINDOW', spaste('Table: ', tablename));
    return T;
  }
  
  const newstatesubtable := function(ms) {
    const sig := createboolcol('SIG');
    const refer := createboolcol('REF');
    const cal := createdblcol('CAL');
    const load := createdblcol('LOAD');
    const sscan := createintcol('SUB_SCAN');
    const obsmode := createstringcol('OBS_MODE');
    const flagrow := createboolcol('FLAG_ROW');

    const td := tablecreatedesc(sig, refer, cal, load, sscan, obsmode, flagrow);
    const tablename := spaste(filename, '/STATE');
    local tab := table(tablename, tabledesc=td, nrow=0, ack=verbose);
    addtempkey(tab, 'CAL');
    addtempkey(tab, 'LOAD');
    tab.close();
    ms.putkeyword('STATE', spaste('Table: ', tablename));
    return T;
  }
  
  local ms := newmaintable(filename);
  ms.putkeyword('MS_VERSION', as_float(2.0));
  newantennasubtable(ms);
  newdatadescriptionsubtable(ms);
  newfeedsubtable(ms);
  newfieldsubtable(ms);
  newflagcmdsubtable(ms);
  newhistorysubtable(ms);
  newobservationsubtable(ms);
  newpointingsubtable(ms);
  newpolarizationsubtable(ms);
  newprocessorsubtable(ms);
  newspectralwindowsubtable(ms);
  newstatesubtable(ms);
  ms.close();
}

