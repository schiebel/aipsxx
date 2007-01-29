# measuresdata.g: Help methods for creating data tables for Measures
# Copyright (C) 1996-2001,2003,2005,2006
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
# $Id: measuresdata.g,v 19.15 2006/01/12 16:19:25 wbrouw Exp $
#
pragma include once
# Stop gui logging and measures gui etc
system.use_gui := F;
{
  local s_have_gui := have_gui;
  func have_gui( ) system.use_gui && s_have_gui();
}
global_use_gui := 0;	
# Necessary includes

include 'table.g';
include 'os.g';
include 'sh.g';
include 'measures.g';
include 'note.g';
include 'sysinfo.g';

##defaultservers.trace(T)
##defaultservers.suspend(T)
#-----------------------------------------------------------------------------
# Create and open a table from name, descriptor, version, type and subtype
#-----------------------------------------------------------------------------
  const mdat_create_table := function(name, desc, vs, typ, subt, renew=F) {
#
# Test presence and renewal of table
#
    if (tableexists(name)) {
      if (renew || !tableiswritable(name)) {
	t := table(name);
	vs := as_integer(t.getkeyword("VS_VERSION")) + 1.0;
	t.close();
	if (tableexists(spaste(name, '.old'))) {
	  tabledelete(spaste(name, '.old'));
	};
	tablerename(name, spaste(name, '.old'));
      };
    };
#
# Create/open table
#
    if (tableexists(name)) {
      t := table(name, readonly=F);
    } else {
      t := table(name, tabledesc=desc, readonly=F);
      if (is_table(t)) {
	t.putkeyword('VS_CREATE', dq.time('today', prec=4, form="ymd clean"));
	t.putkeyword('VS_DATE', dq.time('today', prec=4, form="ymd clean"));
	t.putkeyword('VS_VERSION', sprintf('%09.4f',vs)); 
	t.putkeyword('VS_TYPE', typ);
	t.putinfo([type='IERS', subType=subt]);
      };
    };
    return t;
  };
#-----------------------------------------------------------------------------
# Open existing writable table with name
#-----------------------------------------------------------------------------
  const mdat_open_table := function(name) {
    if (!mdat_test_table(name)) {
      note(paste('No writeable', name, 'table present'), 
	   priority='SEVERE');
      return F;
    };
    return table(name, readonly=F);
  };
#-----------------------------------------------------------------------------
# Open existing table with name
#-----------------------------------------------------------------------------
  const mdat_openr_table := function(name) {
    if (!mdat_testr_table(name)) {
      note(paste('No ', name,'table present'),
	   priority='SEVERE');
      return F;
    };
    return table(name);
  };
#-----------------------------------------------------------------------------
# Test if writable table name present
#-----------------------------------------------------------------------------
  const mdat_test_table := function(name) {
    return (tableexists(name) &&
	    tableiswritable(name));
  };
#-----------------------------------------------------------------------------
# Test if table name present
#-----------------------------------------------------------------------------
  const mdat_testr_table := function(name) {
    return (tableexists(name));
  };
#-----------------------------------------------------------------------------
# Check if table object present
#-----------------------------------------------------------------------------
  if (!is_defined('is_table')) {
    const is_table := function(t) {
      return (is_record(t) && 
	      has_field(t,'ok') &&
	      is_function(t.ok) && 
	      t.ok());
    };
  };
#-----------------------------------------------------------------------------
# Close table t and update version if vsup > 0
#-----------------------------------------------------------------------------
  const mdat_close_table := function(name, t, vsup, timup=T, timshow=T) {
    vs := as_double(t.getkeyword("VS_VERSION"));
    n := t.nrows();
    if (timshow) {
      tim := mdat_last_mjd(t);
    } else {
      tim := 0;
    };
    if (vsup > 0) {
      vs +:= vsup;
      t.putkeyword('VS_VERSION', sprintf('%09.4f',vs));
    };
    if (timup) {
      t.putkeyword('VS_DATE', dq.time('today', prec=4, form="ymd clean"));
    };
    t.close();
    if (timshow) {
      note(sprintf(paste(name, 'table %09.4f now with %i entries',
			 'till %10s'),
		   vs, n, dq.time(dq.quantity(tim, 'd'),
				  form="ymd no_time")));
    } else {
      note(sprintf(paste(name, 'table %09.4f now with %i entries'),
		   vs, n));
    };
    return T;
  };
#-----------------------------------------------------------------------------
# ftp information from file at dir at node into ftp_file.in
#-----------------------------------------------------------------------------
  const mdat_ftp_file := function(node, dir, file, nout='ftp_file.in') {
  if (dos.fileexists(nout)) {
      dos.remove(paste("rm", nout), mustexist=F);
    };
    note(paste('Connecting to',
	       node, 'for',
	       file, '...'));
    nn := paste(node, dir, file, nout);
    cmd := spaste("(FTPDATA='",nn,
		  "'; export FTPDATA; measures_ftp.sh)");
    mysh := sh();
    if (mysh.command(cmd).status != 0) {
      note(paste('Cannot obtain', file), priority='SEVERE');
      mysh.done();
      return F;
    };
    mysh.done();
    if (!dos.fileexists(nout)) {
      note(paste('Did not obtain', file), priority='SEVERE');
      return F;
    };
    note(paste('Obtained', file, 'from', node), 
	 priority='NORMAL');
    return T;
  };
#-----------------------------------------------------------------------------
# Read ftp data
#-----------------------------------------------------------------------------
  const mdat_read_data := function(tnam, fnam='ftp_file.in', d=T, s=' ', m=F) {
    b := [=];
    if (!dos.fileexists(fnam)) {
      note(paste('Cannot open', tnam, 'data file'), priority='SEVERE');
    } else {
      a := open(['<', fnam]);   
      i := 1;
      while (c := read(a)) {
	b[i] := split(c,s);
	if (m) {
	    b[i] =~ s/-/$$-/g;
	    b[i] := split(paste(b[i]));
	};
	i +:= 1;
      };
      a := F;
      if (d) dos.remove(paste("rm", fnam), mustexist=F);
    };
    return b;
  };
#-----------------------------------------------------------------------------
# Read ftp data line
#-----------------------------------------------------------------------------
  const mdat_read_line := function(ref b, f) {
    val b := [=];
    if (c := read(f)) {
      val b := split(c);
      return T;
    } else {
      return F;
    };
  };
#-----------------------------------------------------------------------------
# Current mjd
#-----------------------------------------------------------------------------
  const mdat_today_mjd := function() {
    return as_integer(dq.floor('today')['value']);
  };
#-----------------------------------------------------------------------------
# Last table mjd
#-----------------------------------------------------------------------------
  const mdat_last_mjd := function(t) {
    n := t.nrows();
    if (n < 1) return 0;
    return as_integer(t.getcell('MJD', n));
  };
#-----------------------------------------------------------------------------
# Check presence of file in system
#-----------------------------------------------------------------------------
  const mdat_check_file := function(nam) {
    rt := sysinfo().root();
# Check in ./ for nam and nam.gz
    if (!dos.fileexists(nam)) {
      if (dos.fileexists(spaste(nam,'.gz'))) {
	mysh := sh();
	if (mysh.command(paste("gunzip", spaste(nam,'.gz'))).status != 0) {
	  note(paste('Cannot gunzip', nam), priority='SEVERE');
	};
	mysh.done();
      };
    };
    if (dos.fileexists(nam)) return nam;
# Try same in AipsRoot/code/trial/apps/measures
    namor := nam;
    nam := spaste(rt, '/code/trial/apps/measures/', nam);
    if (!dos.fileexists(nam)) {
      if (dos.fileexists(spaste(nam,'.gz'))) {
	mysh := sh();
	if (mysh.command(paste("cp", spaste(nam,'.gz'),
			       ".")).status != 0) {
	  note(paste('Cannot copy', nam), priority='SEVERE');
	};
	nam := namor;
	if (dos.fileexists(spaste(nam, '.gz'))) {
	  if (mysh.command(paste("gunzip", spaste(nam,'.gz'))).status != 0) {
	    note(paste('Cannot gunzip', nam), priority='SEVERE');
	  };
	};
	mysh.done();
      };
    };
    if (dos.fileexists(nam)) return nam;
    return F;
  }
#=============================================================================
#
# Function to read TAI-UTC seconds into table
#
#=============================================================================
  const TAI_UTC := function() {
#
# File description data
#
    ftpd := "maia.usno.navy.mil ser7 tai-utc.dat";
    tnam := 'TAI_UTC';
#
# Create table description
#
    td0 := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
    td1 := tablecreatescalarcoldesc("dUTC", 0.0, "IncrementalStMan");
    td2 := tablecreatescalarcoldesc("Offset", 0.0, "IncrementalStMan");
    td3 := tablecreatescalarcoldesc("Multiplier", 0.0, "IncrementalStMan");
    td  := tablecreatedesc(td0, td1, td2, td3);
#
# Test if necessary to update
#
    if (mdat_testr_table(tnam)) {
      t := mdat_openr_table(tnam);
      i := mdat_today_mjd() - dq.quantity(t.getkeyword("VS_DATE")).value;
      if (i < 31) {
	note(paste(tnam, 'is up-to-date'));
	mdat_close_table(tnam, t, 0, timup=F);
	return T;
      };	
      t.close();
    };
#
# Get data from Naval Observatory
#
    if (!mdat_ftp_file(ftpd[1], ftpd[2], ftpd[3])) return F;
# 
# Read data
#
    b := mdat_read_data(tnam);
#
# Parse data
#
    if (length(b) < 10 ||
	length(b[1]) != length(b[length(b)]) ||
	length(b[1]) < 15) {
      note(paste('Incorrect', tnam, 'data file obtained'));
      return F;
    };
    mjd := []; dut := []; off := []; mul := [];
    for (i in 1:length(b)) {
      mjd[i] := as_double(b[i][5]) - 2400000.5;
      dut[i] := as_double(b[i][7]);
      off[i] := as_double(b[i][12]);
      mul[i] := as_double(b[i][14]);
    };
#
# Test if looks ok
#
    if (mjd[1] != 37300 || mul[1] != 0.001296) {
      d.log('', 'SEVERE', paste('Format of', tnam, 'data file obtained wrong'));
      return F;
    };
#
# Move existing table to old and create new one
#
    t := mdat_create_table(tnam, td, 1.0,
			   'TAI-UTC difference obtained from USNO',
			   'leapSecond', renew=T);
    if (!is_table(t)) {
      note(paste('Cannot create', tnam, 'table'));
      return F;
    };
#
# Fill table keywords
#
    t.putkeyword('MJD0', 37300);
    t.putkeyword('dMJD', 0.0);
    t.putcolkeyword('MJD', 'UNIT', 'd');
    t.putcolkeyword('dUTC', 'UNIT', 's');
    t.putcolkeyword('Offset', 'UNIT', 'd');
    t.putcolkeyword('Multiplier', 'UNIT', 's');
#
# Fill Table
#
    t.addrows(length(mjd) - t.nrows());
    t.putcol('MJD', mjd);
    t.putcol('dUTC', dut);
    t.putcol('Offset', off);
    t.putcol('Multiplier', mul);
#
# Ready
#
    j := mdat_close_table(tnam, t, 0);
    return T;
  };
const taiutc := TAI_UTC;
#=============================================================================
#
# Function to read IERS EOP97 C04 into table
#
#=============================================================================
  const IERSeop97 := function() {
#
# File description data
#
# wnb 990223: changed filename from eop97c04 to eopc04
#
    ftpd := "hpiers.obspm.fr iers/eop/eopc04 eopc04.xx";
    tnam := 'IERSeop97';
#
# Create table description
#
      td0 := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
      td1 := tablecreatescalarcoldesc("x", 0.0, "IncrementalStMan");
      td1a:= tablecreatescalarcoldesc("Dx", 0.0, "IncrementalStMan");
      td2 := tablecreatescalarcoldesc("y", 0.0, "IncrementalStMan");
      td2a:= tablecreatescalarcoldesc("Dy", 0.0, "IncrementalStMan");
      td3 := tablecreatescalarcoldesc("dUT1", 0.0, "IncrementalStMan");
      td3a:= tablecreatescalarcoldesc("DdUT1", 0.0, "IncrementalStMan");
      td4 := tablecreatescalarcoldesc("LOD", 0.0, "IncrementalStMan");
      td4a:= tablecreatescalarcoldesc("DLOD", 0.0, "IncrementalStMan");
      td5 := tablecreatescalarcoldesc("dPsi", 0.0, "IncrementalStMan");
      td5a:= tablecreatescalarcoldesc("DdPsi", 0.0, "IncrementalStMan");
      td6 := tablecreatescalarcoldesc("dEps", 0.0, "IncrementalStMan");
      td6a:= tablecreatescalarcoldesc("DdEps", 0.0, "IncrementalStMan");
      td  := tablecreatedesc(td0, td1, td1a,
			     td2, td2a, td3, td3a,
			     td4, td4a, td5, td5a,
			     td6, td6a);
#
# Test if necessary to update
#
    if (mdat_testr_table(tnam)) {
      t := mdat_openr_table(tnam);
      i := mdat_today_mjd() - mdat_last_mjd(t);
      if (i < 8) {
	note(paste(tnam, 'is up-to-date'));
	mdat_close_table(tnam, t, 0, timup=F);
	return T;
      };
      t.close();
    };
#
# Create Table
#
    t := mdat_create_table(tnam, td, 1.0,
			   'IERS EOP97C04 Earth Orientation Data from IERS',
			   'eop97');
    if (!is_table(t)) {
      note(paste('Cannot create', tnam, 'table'), priority='SEVERE');
      return F;
    };
#
# Fill table keywords
#
    t.putkeyword('MJD0', 37664);
    t.putkeyword('dMJD', 1);
    t.putcolkeyword('MJD', 'UNIT', 'd');
    t.putcolkeyword('x', 'UNIT', 'arcsec');
    t.putcolkeyword('Dx', 'UNIT', 'arcsec');
    t.putcolkeyword('y', 'UNIT', 'arcsec');
    t.putcolkeyword('Dy', 'UNIT', 'arcsec');
    t.putcolkeyword('dUT1', 'UNIT', 's');
    t.putcolkeyword('DdUT1', 'UNIT', 's');
    t.putcolkeyword('LOD', 'UNIT', 's');
    t.putcolkeyword('DLOD', 'UNIT', 's');
    t.putcolkeyword('dPsi', 'UNIT', 'arcsec');
    t.putcolkeyword('DdPsi', 'UNIT', 'arcsec');
    t.putcolkeyword('dEps', 'UNIT', 'arcsec');
    t.putcolkeyword('DdEps', 'UNIT', 'arcsec');
#
# Determine what to read
#
    mjd0 := t.getkeyword('MJD0');
    ml := max(mdat_last_mjd(t), mjd0);
    mn := mdat_today_mjd();
#
# Get all missing data
#
    while (mn - ml >= 7) {
      yrtd := as_integer(split(dq.time(dq.quantity(ml+1, 'd'),
				       form="ymd no_time"),'/')[1]);
      ytd := yrtd%100;
      if (ytd < 10) {
	ftpd[3] := spaste('eopc04.', '0', ytd);
      } else {
	ftpd[3] := spaste('eopc04.', ytd);
      };
#
# Get data from Paris Observatory
#
      if (!mdat_ftp_file(ftpd[1], ftpd[2], ftpd[3])) {
	t.close();
	return F;
      };
# 
# Read data
#
      b := mdat_read_data(tnam, m=T);
#
# Parse data
#
      j := length(b);
      while (j>=20 && length(b[j-1]) < 2) j := j-1;
      if (length(b) < 20 ||
	  length(b[j-1]) != 9) {
	t.close();
	note(paste('Incorrect', tnam, 'data file obtained'), priority='SEVERE');
	return F;
      };
      mjd := []; x := []; y := []; dut := [];
      lod := []; dpsi := []; deps := [];
      k := 0;
      for (i in 1:length(b)) {
	if (length(b[i]) == 9 && as_integer(b[i][3]) >= 37665) {
	  k +:=1;
	  mjd[k] := as_double(b[i][3]);
	  x[k]   := as_double(b[i][4]);
	  y[k]   := as_double(b[i][5]);
	  dut[k] := as_double(b[i][6]);
	  lod[k] := as_double(b[i][7]);
	  dpsi[k]:= as_double(b[i][8]);
	  deps[k]:= as_double(b[i][9]);
	};
      };
#
# Fill table
#
      nml := mjd[length(mjd)];
      if (nml - ml > 0) {
	t.addrows(nml-ml);
	for (i in 1:length(mjd)) {
	  if (mjd[i] > ml) {
	    j := mjd[i] - mjd0;
	    t.putcell('MJD', j, mjd[i]);
	    t.putcell('x', j, x[i]);
	    t.putcell('y', j, y[i]);
	    t.putcell('dUT1', j, dut[i]);
	    t.putcell('LOD', j, lod[i]);
	    t.putcell('dPsi', j, dpsi[i]);
	    t.putcell('dEps', j, deps[i]);
	    if (yrtd < 1968) {
	      t.putcell('Dx', j, 0.030);
	      t.putcell('Dy', j, 0.030);
	      t.putcell('DdUT1', j, 0.002);
	      t.putcell('DLOD', j, 0.0014);
	      t.putcell('DdPsi', j, 0.012);
	      t.putcell('DdEps', j, 0.002);
	    } else if (yrtd < 1972) {
	      t.putcell('Dx', j, 0.020);
	      t.putcell('Dy', j, 0.020);
	      t.putcell('DdUT1', j, 0.0015);
	      t.putcell('DLOD', j, 0.0010);
	      t.putcell('DdPsi', j, 0.009);
	      t.putcell('DdEps', j, 0.002);
	    } else if (yrtd < 1980) {
	      t.putcell('Dx', j, 0.015);
	      t.putcell('Dy', j, 0.015);
	      t.putcell('DdUT1', j, 0.0010);
	      t.putcell('DLOD', j, 0.0007);
	      t.putcell('DdPsi', j, 0.005);
	      t.putcell('DdEps', j, 0.002);
	    } else if (yrtd < 1984) {
	      t.putcell('Dx', j, 0.002);
	      t.putcell('Dy', j, 0.002);
	      t.putcell('DdUT1', j, 0.0004);
	      t.putcell('DLOD', j, 0.00015);
	      t.putcell('DdPsi', j, 0.003);
	      t.putcell('DdEps', j, 0.002);
	    } else if (yrtd < 1996) {
	      t.putcell('Dx', j, 0.0007);
	      t.putcell('Dy', j, 0.0007);
	      t.putcell('DdUT1', j, 0.00004);
	      t.putcell('DLOD', j, 0.00003);
	      t.putcell('DdPsi', j, 0.0006);
	      t.putcell('DdEps', j, 0.0006);
	    } else {
	      t.putcell('Dx', j, 0.0003);
	      t.putcell('Dy', j, 0.0003);
	      t.putcell('DdUT1', j, 0.00002);
	      t.putcell('DLOD', j, 0.00002);
	      t.putcell('DdPsi', j, 0.0003);
	      t.putcell('DdEps', j, 0.0003);
	    };
	  };
	};
	ml := max(mdat_last_mjd(t), mjd0);
      };
    };
#
# Ready
#
    j := mdat_close_table(tnam, t, 0.0001);
    return T;
  };
const ierseop97 := IERSeop97;
#=============================================================================
#
# Function to read IERS EOP2000 C04 into table
#
#=============================================================================
  const IERSeop2000 := function() {
#
# File description data
#
    ftpd := "hpiers.obspm.fr iers/eop/eopc04 eopc04_IAU2000.xx";
    tnam := 'IERSeop2000';
#
# Create table description
#
      td0 := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
      td1 := tablecreatescalarcoldesc("x", 0.0, "IncrementalStMan");
      td1a:= tablecreatescalarcoldesc("Dx", 0.0, "IncrementalStMan");
      td2 := tablecreatescalarcoldesc("y", 0.0, "IncrementalStMan");
      td2a:= tablecreatescalarcoldesc("Dy", 0.0, "IncrementalStMan");
      td3 := tablecreatescalarcoldesc("dUT1", 0.0, "IncrementalStMan");
      td3a:= tablecreatescalarcoldesc("DdUT1", 0.0, "IncrementalStMan");
      td4 := tablecreatescalarcoldesc("LOD", 0.0, "IncrementalStMan");
      td4a:= tablecreatescalarcoldesc("DLOD", 0.0, "IncrementalStMan");
      td5 := tablecreatescalarcoldesc("dPsi", 0.0, "IncrementalStMan");
      td5a:= tablecreatescalarcoldesc("DdPsi", 0.0, "IncrementalStMan");
      td6 := tablecreatescalarcoldesc("dEps", 0.0, "IncrementalStMan");
      td6a:= tablecreatescalarcoldesc("DdEps", 0.0, "IncrementalStMan");
      td  := tablecreatedesc(td0, td1, td1a,
			     td2, td2a, td3, td3a,
			     td4, td4a, td5, td5a,
			     td6, td6a);
#
# Test if necessary to update
#
    if (mdat_testr_table(tnam)) {
      t := mdat_openr_table(tnam);
      i := mdat_today_mjd() - mdat_last_mjd(t);
      if (i < 8) {
	note(paste(tnam, 'is up-to-date'));
	mdat_close_table(tnam, t, 0, timup=F);
	return T;
      };
      t.close();
    };
#
# Create Table
#
    t := mdat_create_table(tnam, td, 1.0,
			   'IERS EOP2000C04 Earth Orientation Data from IERS',
			   'eop2000');
    if (!is_table(t)) {
      note(paste('Cannot create', tnam, 'table'), priority='SEVERE');
      return F;
    };
#
# Fill table keywords
#
    t.putkeyword('MJD0', 37664);
    t.putkeyword('dMJD', 1);
    t.putcolkeyword('MJD', 'UNIT', 'd');
    t.putcolkeyword('x', 'UNIT', 'arcsec');
    t.putcolkeyword('Dx', 'UNIT', 'arcsec');
    t.putcolkeyword('y', 'UNIT', 'arcsec');
    t.putcolkeyword('Dy', 'UNIT', 'arcsec');
    t.putcolkeyword('dUT1', 'UNIT', 's');
    t.putcolkeyword('DdUT1', 'UNIT', 's');
    t.putcolkeyword('LOD', 'UNIT', 's');
    t.putcolkeyword('DLOD', 'UNIT', 's');
    t.putcolkeyword('dPsi', 'UNIT', 'arcsec');
    t.putcolkeyword('DdPsi', 'UNIT', 'arcsec');
    t.putcolkeyword('dEps', 'UNIT', 'arcsec');
    t.putcolkeyword('DdEps', 'UNIT', 'arcsec');
#
# Determine what to read
#
    mjd0 := t.getkeyword('MJD0');
    ml := max(mdat_last_mjd(t), mjd0);
    mn := mdat_today_mjd();
#
# Get all missing data
#
    while (mn - ml >= 7) {
      yrtd := as_integer(split(dq.time(dq.quantity(ml+1, 'd'),
				       form="ymd no_time"),'/')[1]);
      ytd := yrtd%100;
      linelen := 9;
      if (ytd < 10) {
	ftpd[3] := spaste('eopc04_IAU2000.', '0', ytd);
      } else {
	if (yrtd == 1962) {
	  ytd := '62-now';
	  linelen +:= 1;
	};
	ftpd[3] := spaste('eopc04_IAU2000.', ytd);
      };
#
# Get data from Paris Observatory
#
      if (!mdat_ftp_file(ftpd[1], ftpd[2], ftpd[3])) {
	t.close();
	return F;
      };
# 
# Read data
#
      b := mdat_read_data(tnam, m=T);
#
# Parse data
#
      j := length(b);
      while (j>=20 && length(b[j-1]) == 0) j := j-1;
      if (length(b) < 20 || length(b[j-1]) != linelen) {
	t.close();
	note(paste('Incorrect', tnam, 'data file obtained'),
	     priority='SEVERE');
	return F;
      };
      mjd := []; x := []; y := []; dut := [];
      lod := []; dpsi := []; deps := [];
      k := 0;
      for (i in 1:length(b)) {
	if (length(b[i]) == linelen && as_integer(b[i][linelen-6]) >= 37665) {
	  k +:=1;
	  mjd[k] := as_double(b[i][linelen-6]);
	  x[k]   := as_double(b[i][linelen-5]);
	  y[k]   := as_double(b[i][linelen-4]);
	  dut[k] := as_double(b[i][linelen-3]);
	  lod[k] := as_double(b[i][linelen-2]);
	  dpsi[k]:= as_double(b[i][linelen-1]);
	  deps[k]:= as_double(b[i][linelen]);
	};
      };
#
# Fill table
#
	nml := mjd[length(mjd)];
      if (nml - ml > 0) {
	t.addrows(nml-ml);
	for (i in 1:length(mjd)) {
	  if (mjd[i] > ml) {
	    j := mjd[i] - mjd0;
	    t.putcell('MJD', j, mjd[i]);
	    t.putcell('x', j, x[i]);
	    t.putcell('y', j, y[i]);
	    t.putcell('dUT1', j, dut[i]);
	    t.putcell('LOD', j, lod[i]);
	    t.putcell('dPsi', j, dpsi[i]);
	    t.putcell('dEps', j, deps[i]);
	    if (yrtd < 1968) {
	      t.putcell('Dx', j, 0.030);
	      t.putcell('Dy', j, 0.030);
	      t.putcell('DdUT1', j, 0.002);
	      t.putcell('DLOD', j, 0.0014);
	      t.putcell('DdPsi', j, 0.012);
	      t.putcell('DdEps', j, 0.002);
	    } else if (yrtd < 1972) {
	      t.putcell('Dx', j, 0.020);
	      t.putcell('Dy', j, 0.020);
	      t.putcell('DdUT1', j, 0.0015);
	      t.putcell('DLOD', j, 0.0010);
	      t.putcell('DdPsi', j, 0.009);
	      t.putcell('DdEps', j, 0.002);
	    } else if (yrtd < 1980) {
	      t.putcell('Dx', j, 0.015);
	      t.putcell('Dy', j, 0.015);
	      t.putcell('DdUT1', j, 0.0010);
	      t.putcell('DLOD', j, 0.0007);
	      t.putcell('DdPsi', j, 0.005);
	      t.putcell('DdEps', j, 0.002);
	    } else if (yrtd < 1984) {
	      t.putcell('Dx', j, 0.002);
	      t.putcell('Dy', j, 0.002);
	      t.putcell('DdUT1', j, 0.0004);
	      t.putcell('DLOD', j, 0.00015);
	      t.putcell('DdPsi', j, 0.003);
	      t.putcell('DdEps', j, 0.002);
	    } else if (yrtd < 1996) {
	      t.putcell('Dx', j, 0.0007);
	      t.putcell('Dy', j, 0.0007);
	      t.putcell('DdUT1', j, 0.00004);
	      t.putcell('DLOD', j, 0.00003);
	      t.putcell('DdPsi', j, 0.0006);
	      t.putcell('DdEps', j, 0.0006);
	    } else {
	      t.putcell('Dx', j, 0.0003);
	      t.putcell('Dy', j, 0.0003);
	      t.putcell('DdUT1', j, 0.00002);
	      t.putcell('DLOD', j, 0.00002);
	      t.putcell('DdPsi', j, 0.0003);
	      t.putcell('DdEps', j, 0.0003);
	    };
	  };
	};
	ml := max(mdat_last_mjd(t), mjd0);
      };
    };
#
# Ready
#
    j := mdat_close_table(tnam, t, 0.0001);
    return T;
  };
const ierseop2000 := IERSeop2000;
#=============================================================================
#
# Function to read IERS PREDICT into table
#
#=============================================================================
  const IERSpredict := function() {
#
# File description data
#
    ftpd := "maia.usno.navy.mil ser7 mark3.out";
    tnam := 'IERSpredict';
#
# Create table description
#
    td0  := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
    td1  := tablecreatescalarcoldesc("x", 0.0, "IncrementalStMan");
    td1a := tablecreatescalarcoldesc("Dx", 0.0, "IncrementalStMan");
    td2  := tablecreatescalarcoldesc("y", 0.0, "IncrementalStMan");
    td2a := tablecreatescalarcoldesc("Dy", 0.0, "IncrementalStMan");
    td3  := tablecreatescalarcoldesc("dUT1", 0.0, "IncrementalStMan");
    td3a := tablecreatescalarcoldesc("DdUT1", 0.0, "IncrementalStMan");
    td4  := tablecreatescalarcoldesc("LOD", 0.0, "IncrementalStMan");
    td4a := tablecreatescalarcoldesc("DLOD", 0.0, "IncrementalStMan");
    td5  := tablecreatescalarcoldesc("dPsi", 0.0, "IncrementalStMan");
    td5a := tablecreatescalarcoldesc("DdPsi", 0.0, "IncrementalStMan");
    td6  := tablecreatescalarcoldesc("dEps", 0.0, "IncrementalStMan");
    td6a := tablecreatescalarcoldesc("DdEps", 0.0, "IncrementalStMan");
    td   := tablecreatedesc(td0, td1, td1a,
			    td2, td2a, td3, td3a,
			    td4, td4a, td5, td5a,
			    td6, td6a);
#
# Test if necessary to update
#
    if (mdat_testr_table(tnam)) {
      t := mdat_openr_table(tnam);
      i := mdat_today_mjd() - dq.quantity(t.getkeyword("VS_DATE")).value;
      if (i < 4) {
	note(paste(tnam, 'is up-to-date'));
	mdat_close_table(tnam, t, 0, timup=F);
	return T;
      };
      t.close();
    };
#
# Create Table
#
    t := mdat_create_table(tnam, td, 1.0,
			   'IERS Earth Orientation Data predicted from NEOS',
			   'predict');
    if (!is_table(t)) {
      note(paste('Cannot create', tnam, 'table'), priority='SEVERE');
      return F;
    };
#
# Fill table keywords
#
    x := as_integer(0);
    if (t.nrows() > 0)
      x := as_integer((t.getcell('MJD', 1)) - 1);
    t.putkeyword('MJD0', x);
    t.putkeyword('dMJD', 1);
    t.putcolkeyword('MJD', 'UNIT', 'd');
    t.putcolkeyword('x', 'UNIT', 'arcsec');
    t.putcolkeyword('Dx', 'UNIT', 'arcsec');
    t.putcolkeyword('y', 'UNIT', 'arcsec');
    t.putcolkeyword('Dy', 'UNIT', 'arcsec');
    t.putcolkeyword('dUT1', 'UNIT', 's');
    t.putcolkeyword('DdUT1', 'UNIT', 's');
    t.putcolkeyword('LOD', 'UNIT', 's');
    t.putcolkeyword('DLOD', 'UNIT', 's');
    t.putcolkeyword('dPsi', 'UNIT', 'arcsec');
    t.putcolkeyword('DdPsi', 'UNIT', 'arcsec');
    t.putcolkeyword('dEps', 'UNIT', 'arcsec');
    t.putcolkeyword('DdEps', 'UNIT', 'arcsec');
#
# Get data from Naval Observatory
#
    if (!mdat_ftp_file(ftpd[1], ftpd[2], ftpd[3])) {
      t.close();
      return F;
    };
# 
# Read data
#
    b := mdat_read_data(tnam);
#
# Parse data
#
    if (length(b) < 20 ||
	length(b[length(b)-10]) != 11) {
      t.close();
      note(paste('Incorrect', tnam, 'data file obtained'), priority='SEVERE');
      return F;
    };
    mjd := []; x := []; y := []; dut := [];
    dx := []; dy := []; ddut := [];
    k := 0;
    for (i in 1:length(b)) {
      if ((length(b[i]) == 10 && as_integer(b[i][4]) >= 40000) ||
	  (length(b[i]) == 11 && as_integer(b[i][5]) >= 40000)) {
	j:=0;
	if (length(b[i]) == 11) j:=1;
	k +:=1;
	mjd[k] := as_double(b[i][j+4]);
	x[k]   := as_double(b[i][j+5]);
	y[k]   := as_double(b[i][j+7]);
	dut[k] := as_double(b[i][j+9]);
	dx[k]   := as_double(b[i][j+6]);
	dy[k]   := as_double(b[i][j+8]);
	ddut[k] := as_double(b[i][j+10]);
      };
    };
#
# Fill table
#
    if (t.getkeyword('MJD0') == 0)
      t.putkeyword('MJD0', as_integer(mjd[1]-1));
    t.flush();
    mjd0 := t.getkeyword('MJD0');
    ml := max(mdat_last_mjd(t), mjd0);
    nml := mjd[length(mjd)];
    if (nml - ml > 0) {
      t.addrows(nml-ml);
      for (i in 1:length(mjd)) {
	j := mjd[i] - mjd0;
#
# Add new values
#
	if (mjd[i] > ml) {
	  t.putcell('MJD', j, mjd[i]);
	  t.putcell('x', j, x[i]);
	  t.putcell('y', j, y[i]);
	  t.putcell('dUT1', j, dut[i]);
	  t.putcell('LOD', j, 0.0);
	  t.putcell('dPsi', j, 0.0);
	  t.putcell('dEps', j, 0.0);
	  t.putcell('Dx', j, dx[i]);
	  t.putcell('Dy', j, dy[i]);
	  t.putcell('DdUT1', j, ddut[i]);
	  t.putcell('DLOD', j, 0.0);
	  t.putcell('DdPsi', j, 0.0);
	  t.putcell('DdEps', j, 0.0);
#
# Replace values
#
	} else if (j > 0) {
	  t.putcell('x', j, x[i]);
	  t.putcell('y', j, y[i]);
	  t.putcell('dUT1', j, dut[i]);
	  t.putcell('Dx', j, dx[i]);
	  t.putcell('Dy', j, dy[i]);
	  t.putcell('DdUT1', j, ddut[i]);
	};
      };
    };
#
# Ready with EOP
#
# Try to add dEps and dPsi from gpsrapid.out
#
    ftpd := "maia.usno.navy.mil ser7 gpsrapid.out";
#
# Get data from Naval Observatory
#
    if (!mdat_ftp_file(ftpd[1], ftpd[2], ftpd[3])) {
      note(paste('No', ftpd[3], 'data file obtained'), priority='SEVERE');
    } else {
# 
# Read data
#
      b := mdat_read_data(tnam);
#
# Parse data and fill table
#
      if (length(b) < 10 ||
	length(b[length(b)-5]) != 11) {
	note(paste('Incorrect', ftpd[3], 'data file obtained'),
	     priority='SEVERE');
      } else {
	mjd0 := t.getkeyword('MJD0');
	n := t.nrows();
	last := 0;
	lastval := [];
	for (i in 1:length(b)) {
	  if (length(b[i]) == 11) {
	    a:=split(b[i][1], '');
	    if (a[1] < '0' || a[1] > '9') {
	      b[i][1] := '';
	      for (i1 in 2:length(a)) b[i][1] := spaste(b[i][1],a[i1]);
	    };
	    mjd := as_double(b[i][1]);
	    j := mjd - mjd0;
	    if (j > 0 && j < n) {
	      t.putcell('dPsi', j, as_double(b[i][8]));
	      t.putcell('dEps', j, as_double(b[i][10]));
	      t.putcell('DdPsi', j, as_double(b[i][9]));
	      t.putcell('DdEps', j, as_double(b[i][11]));
	      last := max(last, j);
	      lastval[1] := as_double(b[i][8]);
	      lastval[2] := as_double(b[i][10]);
	    };
	  };
	};
	if (last > 0 && last < n) {
	  for (j in (last+1):n) {
	    t.putcell('dPsi', j, lastval[1]);
	    t.putcell('dEps', j, lastval[2]);
	    t.putcell('DdPsi', j, 0.01);
	    t.putcell('DdEps', j, 0.01);
	  };
	};
      };
    };
#
# Ready
#
    j := mdat_close_table(tnam, t, 0.0001);
    return T;
  };
const ierspredict := IERSpredict;
#=============================================================================
#
# Function to read IERS PREDICT2000 into table
#
#=============================================================================
  const IERSpredict2000 := function() {
#
# File description data
#
    ftpd := "maia.usno.navy.mil ser7 mark3.out";
    tnam := 'IERSpredict2000';
#
# Create table description
#
    td0  := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
    td1  := tablecreatescalarcoldesc("x", 0.0, "IncrementalStMan");
    td1a := tablecreatescalarcoldesc("Dx", 0.0, "IncrementalStMan");
    td2  := tablecreatescalarcoldesc("y", 0.0, "IncrementalStMan");
    td2a := tablecreatescalarcoldesc("Dy", 0.0, "IncrementalStMan");
    td3  := tablecreatescalarcoldesc("dUT1", 0.0, "IncrementalStMan");
    td3a := tablecreatescalarcoldesc("DdUT1", 0.0, "IncrementalStMan");
    td4  := tablecreatescalarcoldesc("LOD", 0.0, "IncrementalStMan");
    td4a := tablecreatescalarcoldesc("DLOD", 0.0, "IncrementalStMan");
    td5  := tablecreatescalarcoldesc("dPsi", 0.0, "IncrementalStMan");
    td5a := tablecreatescalarcoldesc("DdPsi", 0.0, "IncrementalStMan");
    td6  := tablecreatescalarcoldesc("dEps", 0.0, "IncrementalStMan");
    td6a := tablecreatescalarcoldesc("DdEps", 0.0, "IncrementalStMan");
    td   := tablecreatedesc(td0, td1, td1a,
			    td2, td2a, td3, td3a,
			    td4, td4a, td5, td5a,
			    td6, td6a);
#
# Test if necessary to update
#
    if (mdat_testr_table(tnam)) {
      t := mdat_openr_table(tnam);
      i := mdat_today_mjd() - dq.quantity(t.getkeyword("VS_DATE")).value;
      if (i < 4) {
	note(paste(tnam, 'is up-to-date'));
	mdat_close_table(tnam, t, 0, timup=F);
	return T;
      };
      t.close();
    };
#
# Create Table
#
    t := mdat_create_table(tnam, td, 1.0,
			   'IERS Earth Orientation Data predicted from NEOS',
			   'predict2000');
    if (!is_table(t)) {
      note(paste('Cannot create', tnam, 'table'), priority='SEVERE');
      return F;
    };
#
# Fill table keywords
#
    x := as_integer(0);
    if (t.nrows() > 0)
      x := as_integer((t.getcell('MJD', 1)) - 1);
    t.putkeyword('MJD0', x);
    t.putkeyword('dMJD', 1);
    t.putcolkeyword('MJD', 'UNIT', 'd');
    t.putcolkeyword('x', 'UNIT', 'arcsec');
    t.putcolkeyword('Dx', 'UNIT', 'arcsec');
    t.putcolkeyword('y', 'UNIT', 'arcsec');
    t.putcolkeyword('Dy', 'UNIT', 'arcsec');
    t.putcolkeyword('dUT1', 'UNIT', 's');
    t.putcolkeyword('DdUT1', 'UNIT', 's');
    t.putcolkeyword('LOD', 'UNIT', 's');
    t.putcolkeyword('DLOD', 'UNIT', 's');
    t.putcolkeyword('dPsi', 'UNIT', 'arcsec');
    t.putcolkeyword('DdPsi', 'UNIT', 'arcsec');
    t.putcolkeyword('dEps', 'UNIT', 'arcsec');
    t.putcolkeyword('DdEps', 'UNIT', 'arcsec');
#
# Get data from Naval Observatory
#
    if (!mdat_ftp_file(ftpd[1], ftpd[2], ftpd[3])) {
      t.close();
      return F;
    };
# 
# Read data
#
    b := mdat_read_data(tnam);
#
# Parse data
#
    if (length(b) < 20 ||
	length(b[length(b)-10]) != 11) {
      t.close();
      note(paste('Incorrect', tnam, 'data file obtained'), priority='SEVERE');
      return F;
    };
    mjd := []; x := []; y := []; dut := [];
    dx := []; dy := []; ddut := [];
    k := 0;
    for (i in 1:length(b)) {
      if ((length(b[i]) == 10 && as_integer(b[i][4]) >= 40000) ||
	  (length(b[i]) == 11 && as_integer(b[i][5]) >= 40000)) {
	j:=0;
	if (length(b[i]) == 11) j:=1;
	k +:=1;
	mjd[k] := as_double(b[i][j+4]);
	x[k]   := as_double(b[i][j+5]);
	y[k]   := as_double(b[i][j+7]);
	dut[k] := as_double(b[i][j+9]);
	dx[k]   := as_double(b[i][j+6]);
	dy[k]   := as_double(b[i][j+8]);
	ddut[k] := as_double(b[i][j+10]);
      };
    };
#
# Fill table
#
    if (t.getkeyword('MJD0') == 0)
      t.putkeyword('MJD0', as_integer(mjd[1]-1));
    t.flush();
    mjd0 := t.getkeyword('MJD0');
    ml := max(mdat_last_mjd(t), mjd0);
    nml := mjd[length(mjd)];
    if (nml - ml > 0) {
      t.addrows(nml-ml);
      for (i in 1:length(mjd)) {
	j := mjd[i] - mjd0;
#
# Add new values
#
	if (mjd[i] > ml) {
	  t.putcell('MJD', j, mjd[i]);
	  t.putcell('x', j, x[i]);
	  t.putcell('y', j, y[i]);
	  t.putcell('dUT1', j, dut[i]);
	  t.putcell('LOD', j, 0.0);
	  t.putcell('dPsi', j, 0.0);
	  t.putcell('dEps', j, 0.0);
	  t.putcell('Dx', j, dx[i]);
	  t.putcell('Dy', j, dy[i]);
	  t.putcell('DdUT1', j, ddut[i]);
	  t.putcell('DLOD', j, 0.0);
	  t.putcell('DdPsi', j, 0.0);
	  t.putcell('DdEps', j, 0.0);
#
# Replace values
#
	} else if (j > 0) {
	  t.putcell('x', j, x[i]);
	  t.putcell('y', j, y[i]);
	  t.putcell('dUT1', j, dut[i]);
	  t.putcell('Dx', j, dx[i]);
	  t.putcell('Dy', j, dy[i]);
	  t.putcell('DdUT1', j, ddut[i]);
	};
      };
    };
#
# Ready with EOP
#
# Try to add dEps and dPsi from gpsrapid.out
#
    ftpd := "maia.usno.navy.mil ser7 gpsrapid.out";
#
# Get data from Naval Observatory
#
    if (!mdat_ftp_file(ftpd[1], ftpd[2], ftpd[3])) {
      note(paste('No', ftpd[3], 'data file obtained'), priority='SEVERE');
    } else {
# 
# Read data
#
      b := mdat_read_data(tnam);
#
# Parse data and fill table
#
      if (length(b) < 10 ||
	length(b[length(b)-5]) != 11) {
	note(paste('Incorrect', ftpd[3], 'data file obtained'),
	     priority='SEVERE');
      } else {
	mjd0 := t.getkeyword('MJD0');
	n := t.nrows();
	last := 0;
	lastval := [];
	for (i in 1:length(b)) {
	  if (length(b[i]) == 11) {
	    a:=split(b[i][1], '');
	    if (a[1] < '0' || a[1] > '9') {
	      b[i][1] := '';
	      for (i1 in 2:length(a)) b[i][1] := spaste(b[i][1],a[i1]);
	    };
	    mjd := as_double(b[i][1]);
	    j := mjd - mjd0;
	    if (j > 0 && j < n) {
	      t.putcell('dPsi', j, as_double(b[i][8]));
	      t.putcell('dEps', j, as_double(b[i][10]));
	      t.putcell('DdPsi', j, as_double(b[i][9]));
	      t.putcell('DdEps', j, as_double(b[i][11]));
	      last := max(last, j);
	      lastval[1] := as_double(b[i][8]);
	      lastval[2] := as_double(b[i][10]);
	    };
	  };
	};
	if (last > 0 && last < n) {
	  for (j in (last+1):n) {
	    t.putcell('dPsi', j, lastval[1]);
	    t.putcell('dEps', j, lastval[2]);
	    t.putcell('DdPsi', j, 0.01);
	    t.putcell('DdEps', j, 0.01);
	  };
	};
      };
    };
#
# Ready
#
    j := mdat_close_table(tnam, t, 0.0001);
    return T;
  };
const ierspredict2000 := IERSpredict2000;
#=============================================================================
#
# Function to read JPL DE into table
#
#=============================================================================
  const JPLDE := function(v=200, st=1990, nd=0) {
#
# Make default end
#
    if (nd == 0) {
      nd := as_integer(split(dq.time(dq.quantity("today"),
				     form="ymd"), "/")[1]);
      nd +:= 5;
      nd := max(nd, st+1);
    };
#
# Check range
#
    if ((v != 200 && v != 405) || st < 1600 || nd > 2160 || nd < st) {
      note(spaste('Illegal arguments to JPLDE: v=',
		  v, '; start=', st,
		  '; end=', nd), priority='SEVERE');
      return F;
    };
    note(spaste('Creating DE', v, ' table for ', st, '-', nd));
    stdat := dq.quantity(spaste(st,'/1/1')).value;
    nddat := dq.quantity(spaste(nd,'/1/1')).value;
#
# File description data
#
    ftpd := split(paste("ssd.jpl.nasa.gov pub/eph/export/ascii",
			spaste('ascpxxxx.',v)));
    tnam := spaste('DE',v);
    hnam := spaste('header.',v);
#
# Test if necessary to update
#
    if (mdat_testr_table(tnam)) {
      t := mdat_openr_table(tnam);
      if (stdat < t.getkeyword("MJD0") || mdat_last_mjd(t) == 0) {
	t.close();
	tabledelete(tnam);
      } else if (nddat > mdat_last_mjd(t) + t.getkeyword("dMJD")) {
	stdat := mdat_last_mjd(t) + t.getkeyword("dMJD");
	st := as_integer(split(dq.time(dq.quantity(stdat-1+
						   t.getkeyword("dMJD"), 'd'),
				       form="ymd"), "/")[1]);
	t.close();
      } else {
        note(paste(tnam, 'is up-to-date'));
        mdat_close_table(tnam, t, 0, timup=F);
        return T;
      };
    };
#
# Get header file
#
    chnam := mdat_check_file(hnam);
    if (!is_string(chnam) || !dos.fileexists(chnam)) {
      if (!mdat_ftp_file(ftpd[1], ftpd[2], hnam, hnam)) {
	note(paste('No', hnam, 'header file obtained'), priority='SEVERE');
	return F;
      };
    } else {
      hnam := chnam;
    };
#
# Read header
#
    b := mdat_read_data(hnam, fnam=hnam, d=F, m=F);
    bl := length(b); bc := 0;
    ksize := 0; ncoeff := 0;
    n := 0; kwl := [=]; kwln := 0; kwlv := []; kwlvn := 0;
    stepo := 0; endepo := 0; incepo := 0; ptt := []; pttn := 0;
    while (bc < bl) {
      bc +:=1;
      if (length(b[bc]) >= 2 && b[1] == 'KSIZE=') {
	ksize := as_integer(b[bc][2]); ncoeff := as_integer(b[bc][4]);
	break;
      };
    };
    while (bc < bl) {
      bc +:=1;
      if (length(b[bc]) < 2 ||
	  b[bc][1] != 'GROUP' || as_integer(b[bc][2]) != 1030) continue;
      while (bc < bl) {
	bc +:=1;
	if (length(b[bc]) < 3) continue;
	stepo := as_double(b[bc][1]) - 2400000.5;
	endepo := as_double(b[bc][2]) - 2400000.5;
	incepo := as_integer(b[bc][3]);
	break;
      };
      break;
    };
    while (bc < bl) {
      bc +:=1;
      if (length(b[bc]) < 2 ||
	  b[bc][1] != 'GROUP' || as_integer(b[bc][2]) != 1040) continue;
      while (bc < bl) {
	bc +:=1;
	if (length(b[bc]) < 1 || as_integer(b[bc][1]) == 0) continue;
	n := as_integer(b[bc][1]);
	while (bc < bl) {
	  bc +:=1;
	  for (i in 1:length(b[bc])) {
	    if (length(split(b[bc][i], '')) > 1) {
	      kwln +:= 1;
	      kwl[kwln] := b[bc][i];
	    };
	  };
	  if (kwln >= n) break;
	};
	break;
      };
      break;
    };
    while (bc < bl) {
      bc +:=1;
      if (length(b[bc]) < 2 ||
	  b[bc][1] != 'GROUP' || as_integer(b[bc][2]) != 1041) continue;
      while (bc < bl) {
	bc +:=1;
	if (length(b[bc]) < 1 || as_integer(b[bc][1]) == 0) continue;
	if (n != as_integer(b[bc][1])) break;
	while (bc < bl) {
	  bc +:=1;
	  for (i in 1:length(b[bc])) {
	    b0 := split(b[bc][i], 'D');
	    if (length(b0) != 2) continue;
	    kwlvn +:= 1;
	    kwlv[kwlvn] := as_double(paste(b0[1], b0[2], sep='e'));
	  };
	  if (kwlvn >= kwln) break;
	};
	break;
      };
      break;
    };
    while (bc < bl) {
      bc +:=1;
      if (length(b[bc]) < 2 ||
	  b[bc][1] != 'GROUP' || as_integer(b[bc][2]) != 1050) continue;
      while (bc < bl) {
	bc +:=1;
	if (length(b[bc]) < 1 || as_integer(b[bc][1]) == 0) continue;
	for (i in 1:length(b[bc])) {
	  if (i < 14) {
	    pttn +:= 1;
	    ptt[pttn] := as_integer(b[bc][i]);
	  };
	};
	if (pttn >= 3*13) break;
      };
      break;
    };
    if (ksize == 0 || n == 0 || n > kwln || incepo == 0 ||
	n == 0 || n > kwlvn || pttn != 3*13) {
      note(paste('Illegal header file', hnam), priority='SEVERE');
      note(paste('ksize, n, kwln, kwlvn, incepo, pttn = ',
		 ksize, n, kwln, kwlvn, incepo, pttn));
      t.close();
      return F;
    };
#
# Create table description
#
    td0  := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
    td1  := tablecreatearraycoldesc("x", 0.0, 1, ncoeff, "IncrementalStMan",
				    options='FixedShape');
    td   := tablecreatedesc(td0, td1);
#
# Create Table
#
    t := mdat_create_table(tnam, td, 1.0,
			   spaste('JPL Planetary ephemeris', tnam),
			   tnam);
    if (!is_table(t)) {
      note(paste('Cannot create', tnam, 'table'), priority='SEVERE');
      return F;
    };
#
# Fill table keywords
#
    if (t.nrows() == 0) t.putkeyword('MJD0', 0.0);
    t.putkeyword('dMJD', incepo);
    t.putcolkeyword('MJD', 'UNIT', 'd');
#
# Write constant values
#
    for (i in 1:n) {
      if (kwl[i] != 'QQQQQQ')
	t.putkeyword(kwl[i], kwlv[i]);
    };
    t.putcolkeyword('x', 'Rows', 3)
    t.putcolkeyword('x', 'Columns', 13)
    t.putcolkeyword('x', 'Description', ptt)
#
# Determine what to read
#
    mjd0 := t.getkeyword('MJD0');
    if (mjd0 == 0) {
      mjd0 := as_integer((stdat - stepo)/incepo - 1)*incepo + stepo;
      t.putkeyword('MJD0', mjd0);
    };
    mjdinc := t.getkeyword('dMJD');
    while (st < nd) {
      ml := mdat_last_mjd(t);
      if (ml == 0) ml := mjd0;
      fnm := as_integer(st/20)*20;
      st := fnm + 20; 
      fnm := spaste('ascp',fnm,'.',v);
      chnam := mdat_check_file(fnm);
      if (!is_string(chnam) || !dos.fileexists(chnam)) {
	if (!mdat_ftp_file(ftpd[1], ftpd[2], fnm, fnm)) {
	  note(paste('No', fnm, 'data file obtained'), priority='SEVERE');
	  t.close();
	  return F;
	};
      } else {
	fnm := chnam;
      };
      f := open(['<', fnm]);
      b := [=];
      while (mdat_read_line(b, f)) {
	if (length(b) < 2) continue;
	if (as_integer(b[2]) != ncoeff) continue;
	cnt := 0; st0 := 0; st1 := 0; res := [];
	while (mdat_read_line(b, f)) {
	  for (i in 1:length(b)) {
	    b0 := split(b[i], 'D');
	    if (length(b0) != 2) continue;
	    if (cnt == 0 && i<3) {
	      if (i == 1) {
		st0 := as_double(paste(b0[1], b0[2], sep='e')) - 2400000.5;
		continue;
	      } else {
		st1 := as_double(paste(b0[1], b0[2], sep='e')) - 2400000.5;
		continue;
	      };
	    };
	    if (st0 <= ml) break;
	    cnt +:= 1;
	    res[cnt] := as_double(paste(b0[1], b0[2], sep='e'));
	  };
	  if (st0 <= ml) break;
	  if (cnt >= ncoeff) {
	    t.addrows(1);
	    j := t.nrows();
	    t.putcell('MJD', j, st0);
	    t.putcell('x', j, res);
	    ml +:= mjdinc;
	    break;
	  };
	};
	if (st1 >= nddat) break; 
      };
      f := F;
    };
#
# Ready
#
    j := mdat_close_table(tnam, t, 0.0001);
    return T;
  };
const jplde := JPLDE;
#=============================================================================
#
# Function to add an Observatories table entry. Arguments:
#	name, type, {long, lat, height}|{x, y ,z} , source, comment
# Example:
#	addObservatory('BIMA', 'WGS84', '-121.28.08', '40.49.02',
#			'1021m', 'GPS rx close to T', 'Precision: 7ft or 0.1"')
#
#=============================================================================
  const addObservatory := function(nam, typ='', long='', lat='', ht='',
				   src='edit', com='', delnam=F, ctable=F) {
#
# File description data
#
    tnam := 'Observatories';
#
# Create table description
#
    td0  := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
    td1  := tablecreatescalarcoldesc("Name", "", "IncrementalStMan");
    td2  := tablecreatescalarcoldesc("Type", "", "IncrementalStMan");
    td3  := tablecreatescalarcoldesc("Long", 0.0, "IncrementalStMan");
    td4  := tablecreatescalarcoldesc("Lat", 0.0, "IncrementalStMan");
    td5  := tablecreatescalarcoldesc("Height", 0.0, "IncrementalStMan");
    td6  := tablecreatescalarcoldesc("X", 0.0, "IncrementalStMan");
    td7  := tablecreatescalarcoldesc("Y", 0.0, "IncrementalStMan");
    td8  := tablecreatescalarcoldesc("Z", 0.0, "IncrementalStMan");
    td9  := tablecreatescalarcoldesc("Source", "", "IncrementalStMan");
    td10 := tablecreatescalarcoldesc("Comment", "", "IncrementalStMan");
    td   := tablecreatedesc(td0, td1, td2, td3, td4, td5,
			    td6, td7, td8, td9, td10);
#
# Open table
#
    t := F;
    nl := [=]; nlo := [];
    ndat := [=];
    if (!mdat_test_table(tnam)) {
      if (is_boolean(ctable) && ctable) {
	n := 0;
      } else {
	note(paste('No writeable', tnam, 'table present'), 
	     priority='SEVERE');
	return F;
      };
    } else {
      t := mdat_open_table(tnam);
      if (!is_table(t)) return F;
      n := t.nrows();
#
# Read existing data
#
      if (n > 0) {
	for (i in 1:n) {
	  nl[i] := to_upper(t.getcell('Name', i));
	  ndat[i] := [=];
	  ndat[i].mjd := t.getcell('MJD', i);
	  ndat[i].typ := t.getcell('Type', i);
	  ndat[i].long := t.getcell('Long', i);
	  ndat[i].lat := t.getcell('Lat', i);
	  ndat[i].height := t.getcell('Height', i);
	  ndat[i].x := t.getcell('X', i);
	  ndat[i].y := t.getcell('Y', i);
	  ndat[i].z := t.getcell('Z', i);
	  ndat[i].source := t.getcell('Source', i);
	  ndat[i].comment := t.getcell('Comment', i);
	};
      };
      j := mdat_close_table(tnam, t, 0.0000);
    };
#
# Backup and create table
#
    t := mdat_create_table(tnam, td, 1.0,
			   'List of Observatory positions',
			   'observatory', renew=T);
    if (!is_table(t)) {
      note(paste('Cannot act on', tnam, 'table'), priority='SEVERE');
      return F;
    };
#
# Fill table keywords
#
    t.putkeyword('MJD0', 0);
    t.putkeyword('dMJD', 0.0);
    t.putcolkeyword('MJD', 'UNIT', 'd');
    t.putcolkeyword('Long', 'UNIT', 'deg');
    t.putcolkeyword('Lat', 'UNIT', 'deg');
    t.putcolkeyword('Height', 'UNIT', 'm');
    t.putcolkeyword('X', 'UNIT', 'm');
    t.putcolkeyword('Y', 'UNIT', 'm');
    t.putcolkeyword('Z', 'UNIT', 'm');
#
# Delete if necessary
#
    deln := 0;
    if (is_boolean(delnam) && delnam) {
      dnam := to_upper(nam);
      if (length(nl) > 0) {
	for (i in 1:length(nl)) {
	  if (dnam == nl[i]) {
	    nl[i] := '___';
	    deln +:= 1;
	  };
	};
      };
    } else {
#
# Get new position
#
      pos := dm.position(typ, long, lat, ht);
      if (!is_measure(pos)) {
	note(paste('Illegal observatory specified:', long,
		   lat, ht), priority='SEVERE');
	j := mdat_close_table(tnam, t, 0.0000);
	return F;
      };
#
# Where to put
#
      nam := to_upper(nam);
      nn := 0;
      for (i in 1:length(nl)) {
	if (nl[i] == nam) {
	  nn := i; break;
	};
      };
      if (nn == 0) {
	n +:= 1;
	nn := n;
      };
      i := nn;
      nl[i] := nam;
      ndat[i] := [=];
      ndat[i].mjd := dq.quantity('today')['value'];
      ndat[i].typ := pos.refer;
      ndat[i].long := dq.convert(pos.m0, 'deg').value;
      ndat[i].lat := dq.convert(pos.m1, 'deg').value;
      ndat[i].height := dq.convert(pos.m2, 'm').value;
      ev := dm.addxvalue(pos);
      ndat[i].x := dq.convert(ev[1], 'm').value;
      ndat[i].y := dq.convert(ev[2], 'm').value;
      ndat[i].z := dq.convert(ev[3], 'm').value;
      ndat[i].source := src;
      ndat[i].comment := com;
    };
#
# Sort
#
    nlo := seq(length(nl));
    if (length(nl) > 1) {
      for (i1 in 1:(length(nl)-1)) { 
	for (j1 in (length(nl)-1):i1) {
	  if (nl[nlo[j1]]>nl[nlo[j1+1]]) {
	  aa:=nlo[j1]; nlo[j1]:=nlo[j1+1]; nlo[j1+1]:=aa;
	  };
	};
      };
    };
#
# Fill
#
    if (n>0) {
      if ((n-deln)>t.nrows()) 
	t.addrows((n-deln)-t.nrows());
      j := 1;
      for (i in 1:n) {
	if (nl[nlo[i]] != '___') {
	  t.putcell('MJD',  j, ndat[nlo[i]].mjd);
	  t.putcell('Name', j, nl[nlo[i]]);
	  t.putcell('Type', j, to_upper(ndat[nlo[i]].typ));
	  t.putcell('Long', j, ndat[nlo[i]].long);
	  t.putcell('Lat', j, ndat[nlo[i]].lat);
	  t.putcell('Height', j, ndat[nlo[i]].height);
	  t.putcell('X', j, ndat[nlo[i]].x);
	  t.putcell('Y', j, ndat[nlo[i]].y);
	  t.putcell('Z', j, ndat[nlo[i]].z);
	  t.putcell('Source', j, ndat[nlo[i]].source);
	  t.putcell('Comment', j, ndat[nlo[i]].comment);
	  j +:= 1;
	};
      };
    };
#
# Ready
#
    j := mdat_close_table(tnam, t, 0.0001);
    return T;
  };
const addobservatory := addObservatory;
#=============================================================================
#
# Function to read IGRF Earth magnetic model into table
#
#=============================================================================
  const IGRF := function(fmt=1) {
#
# File description data
#
    if (fmt == 1) {
##      ftpd := "ftp.ngdc.noaa.gov IAGA/IGRF igrf2000all";
      ftpd := "ftp.atnf.csiro.au pub/people/wbrouw/data igrf10coeffs.txt";
    } else if (fmt == 2) {
      ftpd := "ftp.atnf.csiro.au pub/people/wbrouw/data igrf10coeffs.txt";
##      ftpd := "ftp.ngdc.noaa.gov Solid_Earth/Mainfld_Mag/Models/IAGA IGRF.COF";
    } else {
      note(paste('Unknown IGRF fmt of', fmt, 'sepcified'), 
	   priority='SEVERE');
      return F;
    };
    tnam := 'IGRF';
# Number of cooefficients in series expected
    ncoeff := 195;
#
# Create table description
#
    td0 := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
    td1  := tablecreatearraycoldesc("COEF", 0.0, 1, ncoeff, "IncrementalStMan",
				    options='FixedShape');
    td2  := tablecreatearraycoldesc("dCOEF", 0.0, 1, ncoeff, "IncrementalStMan",
				    options='FixedShape');
    td   := tablecreatedesc(td0, td1, td2);
#
# Test if necessary to update
#
    if (mdat_testr_table(tnam)) {
      t := mdat_openr_table(tnam);
      i := mdat_today_mjd() - dq.quantity(t.getkeyword("VS_DATE")).value;
      if (i < 180) {
	note(paste(tnam, 'is up-to-date'));
	mdat_close_table(tnam, t, 0, timup=F);
	return T;
      };	
      t.close();
    };
#
# Get data from Goddard data centre
#
    if (!mdat_ftp_file(ftpd[1], ftpd[2], ftpd[3])) return F;
# 
# Read data
#
    b := mdat_read_data(tnam);
#
# Parse data
#
    if (length(b) < 10) {
      note(paste('Incorrect', tnam, 'data file obtained'), priority='SEVERE');
      return F;
    };
    epok := []; valu := [=];
    cnt := 0;
    i := 0;
    if (fmt == 1 ) {
      i +:= 1;
      if (as_double(b[i][4]) != 1900.0) {
	note(paste('IGRF table does not start in 1900.0'), priority='SEVERE');
	return F;
      };
      kl := 0;
      while (i < length(b)) {
	i +:= 1;
	if (i > length(b)) {
	  note(paste('Incorrect', tnam, 'data length set', cnt), 
	       priority='SEVERE');
	  return F;
	};
	if (length(b[i]) > 3 && b[i][1] ~ m/^[gh]/) { # found a coeff line
 	  cnt +:= 1;
	  j := 0;
	  valu[cnt] := [];
	  k := 3;
	  while (k < length(b[i])) {
	    j +:= 1;
	    k +:= 1;
	    valu[cnt][j] := as_double(b[i][k]);
	  };
	  if (kl == 0) {
	    kl := length(valu[cnt]);
	  } else if (kl != length(valu[cnt])) {
	    if (length(valu[cnt]) == kl-1) { # Set SV to 0
	      valu[cnt][j+1] := as_double(0);
	    } else if (length(valu[cnt]) == 2) {
	      while (j < kl) {
		j +:= 1;
		valu[cnt][j] := as_double(0);
	      };
	      for (i1 in 1:2) {
		valu[cnt][kl+i1-3] := valu[cnt][i1];
		valu[cnt][i1] := as_double(0);
	      };
	    } else {
	      note(paste('Illegal line for coefficient',
			 cnt), priority='SEVERE');
	      return F;
	    };
	  };
        };					# if line
      };					# while
      if (cnt != ncoeff) {
	note(paste('Incorrect', tnam, 'number of coefficients', cnt), 
	     priority='SEVERE');
	return F;
      };
      if (kl < 22) {
	note(paste('Incorrect', tnam, 'number of years', cnt), 
	     priority='SEVERE');
	return F;
      };
    } else {
      note(paste('In the igrf() reading, fmt == 2 is not supported at ',
		 'the moment. Use fmt=1.'),
	   priority='SEVERE');	  
      return F;			  
      while (i < length(b)) {
	i +:= 1;
	if (i > length(b)) {
	  note(paste('Incorrect', tnam, 'data length set', cnt), 
	       priority='SEVERE');
	  return F;
	};
	if (b[i][1] ~ m/^.GRF[12]/) {		# found a year
	  cnt +:= 1;
	  i +:= 1;
	  if (i > length(b)) {
	    note(paste('Incorrect', tnam, 'data length set', cnt), 
		 priority='SEVERE');
	    return F;
	  };
	  epok[cnt] := as_double(b[i][1]);
	  nc := as_double(b[i][2]);
	  if (nc != ncoeff) {
	    note(paste('Incorrect', tnam, 'data for', epok[cnt]), 
		 priority='SEVERE');
	    return F;
	  };
	  j := 0;
	  valu[cnt] := [];
	  while (j < ncoeff) {
	    i +:= 1;
	    if (i > length(b)) {
	      note(paste('Incorrect', tnam, 'data length set', cnt), 
		   priority='SEVERE');
	      return F;
	    };
	    k :=0;
	    while (k < length(b[i])) {
	      j +:= 1;
	      k +:= 1;
	      valu[cnt][j] := as_double(b[i][k]);
	    };
	  };
	} else if (b[i][1] ~ m/^SV[12]/) {	# found last
	  cnt +:= 1;
	  epok[cnt] := as_double(1);
	  j := 0;
	  valu[cnt] := [];
	  while (j < ncoeff) {
	    i +:= 1;
	    if (i > length(b)) {
	      note(paste('Incorrect', tnam, 'data length set', cnt), 
		   priority='SEVERE');
	      return F;
	    };
	    k :=0;
	    while (k < length(b[i])) {
	      j +:= 1;
	      k +:= 1;
	      valu[cnt][j] := as_double(b[i][k]);
	    };
	  };
	};
      };
#
# Test if looks ok
#
      if (cnt < 10 || epok[1] != 1900 ||
	  epok[cnt] != 1) {
	note(paste('Format of', tnam, 'data file obtained short'), 
	     priority='SEVERE');
	return F;
      };
    };				# fmt test
#
# Move existing table to old and create new one
#
    t := mdat_create_table(tnam, td, 1.0,
			   'IGRF10 reference magnetic field',
			   'earthField', renew=T);
    if (!is_table(t)) {
      note(paste('Cannot create', tnam, 'table'), priority='SEVERE');
      return F;
    };
#
# Fill table keywords
#
    y1900 := dq.unit('1900/1/1/0:0').value;
    t.putkeyword('MJD0', y1900 - 5*365.25);
    t.putkeyword('dMJD', 5*365.25);
    t.putcolkeyword('MJD', 'UNIT', 'd');
    t.putcolkeyword('COEF', 'UNIT', '');
    t.putcolkeyword('dCOEF', 'UNIT', '');
#
# Fill Table
#
    if (fmt == 1) {
      t.addrows(kl - 1 - t.nrows());
      for (i in 1:(kl-1)) {
	t.putcell('MJD', i, as_double(((i-1)*5)*365.25) + y1900);
	vals := [];
	for (j in 1:ncoeff) vals[j] := valu[j][i];
	t.putcell('COEF', i, vals);
	if (i == kl-1) {
	  for (j in 1:ncoeff) vals[j] := valu[j][kl];
	} else {
	  for (j in 1:ncoeff) vals[j] := (valu[j][i+1] - valu[j][i])/5;
	};
	t.putcell('dCOEF', i, vals);
      };
    } else {
      t.addrows(length(epok) - 1 - t.nrows());
      for (i in 1:(cnt-1)) {
	t.putcell('MJD', i, as_double((epok[i]-1900)*365.25) + y1900);
	t.putcell('COEF', i, valu[i]);
	if (i == cnt-1) {
	  t.putcell('dCOEF', i, valu[cnt]);
	} else {
	  t.putcell('dCOEF', i, (valu[i+1] - valu[i])/5);
	};
      };
   };
#
# Ready
#
    j := mdat_close_table(tnam, t, 0);
    return T;
  };
const igrf := IGRF;
#=============================================================================
#
# Function to add a spectral Line  table entry. Arguments:
#	name, freq, source, comment
# Example:
#	addLine('OH1612', '1612.231MHz',
#			'Allen', 'Precision: 1kHz')
#
#=============================================================================
  const addLine := function(nam, freq='',
			    src='edit', com='', delnam=F, ctable=F) {
#
# File description data
#
    tnam := 'Lines';
#
# Create table description
#
    td0  := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
    td1  := tablecreatescalarcoldesc("Name", "", "IncrementalStMan");
    td2  := tablecreatescalarcoldesc("Type", "", "IncrementalStMan");
    td3  := tablecreatescalarcoldesc("Freq", 0.0, "IncrementalStMan");
    td9  := tablecreatescalarcoldesc("Source", "", "IncrementalStMan");
    td10 := tablecreatescalarcoldesc("Comment", "", "IncrementalStMan");
    td   := tablecreatedesc(td0, td1, td2, td3,
			    td9, td10);
#
# Open table
#
    t := F;
    nl := [=]; nlo := [];
    ndat := [=];
    if (!mdat_test_table(tnam)) {
      if (is_boolean(ctable) && ctable) {
	n := 0;
      } else {
	note(paste('No writeable', tnam, 'table present'), 
	     priority='SEVERE');
	return F;
      };
    } else {
      t := mdat_open_table(tnam);
      if (!is_table(t)) return F;
      n := t.nrows();
#
# Read existing data
#
      if (n > 0) {
	for (i in 1:n) {
	  nl[i] := to_upper(t.getcell('Name', i));
	  ndat[i] := [=];
	  ndat[i].mjd := t.getcell('MJD', i);
	  ndat[i].typ := t.getcell('Type', i);
	  ndat[i].freq := t.getcell('Freq', i);
	  ndat[i].source := t.getcell('Source', i);
	  ndat[i].comment := t.getcell('Comment', i);
	};
      };
      j := mdat_close_table(tnam, t, 0.0000);
    };
#
# Backup and create table
#
    t := mdat_create_table(tnam, td, 1.0,
			   'List of spectral line rest frequencies',
			   'line', renew=T);
    if (!is_table(t)) {
      note(paste('Cannot act on', tnam, 'table'), priority='SEVERE');
      return F;
    };
#
# Fill table keywords
#
    t.putkeyword('MJD0', 0);
    t.putkeyword('dMJD', 0.0);
    t.putcolkeyword('MJD', 'UNIT', 'd');
    t.putcolkeyword('Freq', 'UNIT', 'GHz');
#
# Delete if necessary
#
    deln := 0;
    if (is_boolean(delnam) && delnam) {
      dnam := to_upper(nam);
      if (length(nl) > 0) {
	for (i in 1:length(nl)) {
	  if (dnam == nl[i]) {
	    nl[i] := '___';
	    deln +:= 1;
	  };
	};
      };
    } else {
#
# Get new frequency
#
      pos := dm.frequency('rest', freq);
      if (!is_measure(pos)) {
	note(paste('Illegal spectral line specified:', freq),
		   priority='SEVERE');
	j := mdat_close_table(tnam, t, 0.0000);
	return F;
      };
#
# Where to put
#
      nam := to_upper(nam);
      nn := 0;
      for (i in 1:length(nl)) {
	if (nl[i] == nam) {
	  nn := i; break;
	};
      };
      if (nn == 0) {
	n +:= 1;
	nn := n;
      };
      i := nn;
      nl[i] := nam;
      ndat[i] := [=];
      ndat[i].mjd := dq.quantity('today')['value'];
      ndat[i].typ := pos.refer;
      ndat[i].freq := dq.convert(pos.m0, 'GHz').value;
      ndat[i].source := src;
      ndat[i].comment := com;
    };
#
# Sort
#
    nlo := seq(length(nl));
    if (length(nl) > 1) {
      for (i1 in 1:(length(nl)-1)) { 
	for (j1 in (length(nl)-1):i1) {
	  if (nl[nlo[j1]]>nl[nlo[j1+1]]) {
	  aa:=nlo[j1]; nlo[j1]:=nlo[j1+1]; nlo[j1+1]:=aa;
	  };
	};
      };
    };
#
# Fill
#
    if (n>0) {
      if ((n-deln)>t.nrows()) 
	t.addrows((n-deln)-t.nrows());
      j := 1;
      for (i in 1:n) {
	if (nl[nlo[i]] != '___') {
	  t.putcell('MJD',  j, ndat[nlo[i]].mjd);
	  t.putcell('Name', j, nl[nlo[i]]);
	  t.putcell('Type', j, to_upper(ndat[nlo[i]].typ));
	  t.putcell('Freq', j, ndat[nlo[i]].freq);
	  t.putcell('Source', j, ndat[nlo[i]].source);
	  t.putcell('Comment', j, ndat[nlo[i]].comment);
	  j +:= 1;
	};
      };
    };
#
# Ready
#
    j := mdat_close_table(tnam, t, 0.0001);
    return T;
  };
const addline := addLine;
#=============================================================================
#
# Function to add a Source table entry. Arguments:
#	nami, typi, longi, lati, srci, comi
# Example:
#	addSource('3c847', 'J2000', '12:13:14', '40.49.02',
#			 'VLBI reference', 'Precision: 0.01as')
#
#=============================================================================
  const addSource := function(nami='unknown', typi='', longi='', lati='',
			      srci='edit', comi='', delnam=F, ctable=F,
			      vref=F) {
#
# File description data
#
    ftpd := "hpiers.obspm.fr iers/icrf/iau/icrf_rsc  icrf.rsc";
    tnam := 'Sources';
#
# Create table description
#
    td0  := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
    td1  := tablecreatescalarcoldesc("Name", "", "IncrementalStMan");
    td2  := tablecreatescalarcoldesc("Type", "", "IncrementalStMan");
    td3  := tablecreatescalarcoldesc("Long", 0.0, "IncrementalStMan");
    td4  := tablecreatescalarcoldesc("Lat", 0.0, "IncrementalStMan");
    td9  := tablecreatescalarcoldesc("Source", "", "IncrementalStMan");
    td10 := tablecreatescalarcoldesc("Comment", "", "IncrementalStMan");
    td   := tablecreatedesc(td0, td1, td2, td3, td4,
			    td9, td10);
#
# Test if necessary to update
#
    if (is_boolean(vref) && vref) { 
      if (mdat_testr_table(tnam)) {
	t := mdat_openr_table(tnam);
	i := mdat_today_mjd() - dq.quantity(t.getkeyword("VS_DATE")).value;
	if (i < 31) {
	  note(paste(tnam, 'is up-to-date'));
	  mdat_close_table(tnam, t, 0, timup=F);
	  return T;
	};
	t.close();
      };
    };
#
# Open table
#
    t := F;
    nl := [=]; nlo := [];
    ndat := [=];
    if (!mdat_test_table(tnam)) {
      if (is_boolean(ctable) && ctable) {
	n := 0;
      } else {
	note(paste('No writeable', tnam, 'table present'), 
	     priority='SEVERE');
	return F;
      };
    } else {
      t := mdat_open_table(tnam);
      if (!is_table(t)) return F;
      n := t.nrows();
#
# Read existing data
#
      if (n > 0) {
	for (i in 1:n) {
	  nl[i] := to_upper(t.getcell('Name', i));
	  ndat[i] := [=];
	  ndat[i].mjd := t.getcell('MJD', i);
	  ndat[i].typ := t.getcell('Type', i);
	  ndat[i].long := t.getcell('Long', i);
	  ndat[i].lat := t.getcell('Lat', i);
	  ndat[i].source := t.getcell('Source', i);
	  ndat[i].comment := t.getcell('Comment', i);
	};
      };
      j := mdat_close_table(tnam, t, 0.0000);
    };
#
# Backup and create table
#
    t := mdat_create_table(tnam, td, 1.0,
			   'List of Source positions',
			   'source', renew=T);
    if (!is_table(t)) {
      note(paste('Cannot act on', tnam, 'table'), priority='SEVERE');
      return F;
    };
#
# Fill table keywords
#
    t.putkeyword('MJD0', 0);
    t.putkeyword('dMJD', 0.0);
    t.putcolkeyword('MJD', 'UNIT', 'd');
    t.putcolkeyword('Long', 'UNIT', 'deg');
    t.putcolkeyword('Lat', 'UNIT', 'deg');
#
# Make lists
#
    nam := [=];
    pos := [=];
    src := [=];
    com := [=];
#
# Delete if necessary
#
    deln := 0;
    if (is_boolean(delnam) && delnam) {
      dnam := to_upper(nami);
      if (length(nl) > 0) {
	for (i in 1:length(nl)) {
	  if (dnam == nl[i]) {
	    nl[i] := '___';
	    deln +:= 1;
	  };
	};
      };
    } else {
#
# Get new position
#
      if (is_boolean(vref) && vref) {
#
# Get VLBI positions from IERS (icrf.rsc)
#	
	if (mdat_ftp_file(ftpd[1], ftpd[2], ftpd[3])) {
# 
# Read data
#
	    b := mdat_read_data(tnam, s='');
#
# Parse data
#
	  if (length(b) < 10) {
	    t.close();
	    note(paste('Incorrect', tnam, 'data file obtained'),
		 priority='SEVERE');
	    return F;
	  };
	  k := 0;
	  for (i in 1:length(b)) {
	    if (len(b[i]) > 100) {
	      while (b[i][1] == ' ') b[i] := b[i][2:len(b[i])];
	    };
	    if (length(b[i]) >= 76 && spaste(b[i][1:6]) == 'ICRF J') {
	      k +:=1;
	      pos[k] := dm.direction('ICRS',
				     paste(split(spaste(b[i][45:46])),
					   split(spaste(b[i][48:49])),
					   split(spaste(b[i][51:59])),
					   sep=':'),
				     paste(spaste(b[i][62],
						  split(spaste(b[i][63:64]))),
					   split(spaste(b[i][66:67])),
					   split(spaste(b[i][69:76])),
					   sep='.'));
	      if (!is_measure(pos[k])) {
		note(paste('Illegal VLBI source specified:',
			   spaste(b[i][6:21])),
		     priority='WARN');
		k -:= 1;
	      } else {
		nam[k] := to_upper(spaste(b[i][25:32]));
		src[k] := 'IERS icrf.rsc';
		com[k] := to_upper(b[i][35:42]);
#
# Aliases
#
		k1 := k;
		k +:=1;
		pos[k] := pos[k1];
		nam[k] := to_upper(spaste(b[i][6:21]));
		src[k] := src[k1];
		com[k] := com[k1];
	      };
	    };
	  };
	};
      } else {
	pos[1] := dm.direction(typi, longi, lati);
	if (!is_measure(pos[1])) {
	  note(paste('Illegal source specified:', longi, lati), 
	       priority='SEVERE');
	  j := mdat_close_table(tnam, t, 0.0000);
	  return F;
	};
	nam[1] := to_upper(nami);
	src[1] := srci;
	com[1] := comi;
      };
#
# Where to put
#
      if (length(nam) > 0) {
	for (iv in 1:length(nam)) {
	  nn := 0;
	  if (length(nl) > 0) {
	    for (i in 1:length(nl)) {
	      if (nl[i] == nam[iv]) {
		nn := i; break;
	      };
	    };
	  };
	  if (nn == 0) {
	    n +:= 1;
	    nn := n;
	  };
	  i := nn;
	  nl[i] := nam[iv];
	  ndat[i] := [=];
	  ndat[i].mjd := dq.quantity('today')['value'];
	  ndat[i].typ := pos[iv].refer;
	  ndat[i].long := dq.norm(dq.convert(pos[iv].m0, 'deg'),0).value;
	  ndat[i].lat := dq.convert(pos[iv].m1, 'deg').value;
	  ndat[i].source := src[iv];
	  ndat[i].comment := com[iv];
	};
      };
    };
#
# Sort
#
    nl0 := [];
    if (length(nl)>0) nlo := seq(length(nl));
    if (length(nl) > 1) {
      for (i1 in 1:(length(nl)-1)) { 
	for (j1 in (length(nl)-1):i1) {
	  if (nl[nlo[j1]]>nl[nlo[j1+1]]) {
	  aa:=nlo[j1]; nlo[j1]:=nlo[j1+1]; nlo[j1+1]:=aa;
	  };
	};
      };
    };
#
# Fill
#
    if (n>0) {
      if ((n-deln)>t.nrows()) 
	t.addrows((n-deln)-t.nrows());
      j := 1;
      for (i in 1:n) {
	if (nl[nlo[i]] != '___') {
	  t.putcell('MJD',  j, ndat[nlo[i]].mjd);
	  t.putcell('Name', j, nl[nlo[i]]);
	  t.putcell('Type', j, to_upper(ndat[nlo[i]].typ));
	  t.putcell('Long', j, ndat[nlo[i]].long);
	  t.putcell('Lat', j, ndat[nlo[i]].lat);
	  t.putcell('Source', j, ndat[nlo[i]].source);
	  t.putcell('Comment', j, ndat[nlo[i]].comment);
	  j +:= 1;
	};
      };
    };
#
# Ready
#
    j := mdat_close_table(tnam, t, 0.0001);
    return T;
  };
const addsource := addSource;
#=============================================================================
#
# Function to create a position table (e.g. for comets) from list. Arguments:
#	table name, file name 
# Example:
#	create Comet('C1978C', 'inC1978c.txt');
#
#=============================================================================
const createComet := function(nam, fil) {

#
# File description data
#
  tnam := nam;
  fnam := fil;
#
# Read file
#
  b := mdat_read_data(tnam, fnam, d=F);
#
# Parse data
#
  if (length(b) < 5) {
    note(paste('Incorrect', tnam, 'data file obtained'), priority='SEVERE');
    return F;
  };
#
# Analyse header
#
  hdr := T;
  lng := 0;
  lat := 0;
  dst := 0;
  nm  := '';
  k := 0;
  for (i in 1:length(b)) {
    if (length(b[i]) < 6) continue;
    if (k == 0) {
      nm := b[i][2];
      k := 1;
      continue;
    };
    if (k == 1 && length(b[i]) > 9 && b[i][7] == '=') {
      lng := as_double(b[i][8]);
      lat := as_double(b[i][9]);
      dst := as_double(b[i][10]);
      hdr := F;
      k := i+1;
      break;
    };
  };
  if (k > length(b) || hdr) {
    note(paste('Cannot find header in', tnam, 'data file'), priority='SEVERE');
    return F;
  };
  c := [=];
  for (i in k:length(b)) {
    if (length(b[i]) < 15) continue;
    a := split(b[i][1], '');
    if (a[1] < '0' || a[1] > '9') continue;
    n := length(c)+1;
    c[n] := [=];
    c[n].et := as_double(b[i][1]) - 2400000.5;
    c[n].ra := ((as_double(b[i][8])/60 + as_double(b[i][7]))/60 +
		as_double(b[i][6]))*15;
    x := +1;
    if (split(b[i][9], '')[1] == '-') {
      b[i][9] := spaste(split(b[i][9], '')[2:strlen(b[i][9])]);
      x := -1;
    };
    c[n].dec := ((as_double(b[i][11])/60 + as_double(b[i][10]))/60 +
		 as_double(b[i][9]))*x;
    c[n].rho := as_double(b[i][12]);
    c[n].rv  := as_double(b[i][13]);
    c[n].dlg := as_double(b[i][14]);
    c[n].dlt := as_double(b[i][15]);
  };
  if (length(c) < 2) {
    note(paste('Cannot find data in', tnam, 'data file'), priority='SEVERE');
    return F;
  };
  dmjd := (c[length(c)].et - c[1].et)/(length(c)-1);
  mjd0 := c[1].et - dmjd;
  for (i in 1:length(c)) {
    if (abs(c[i] - (mjd0 + i*dmjd)) > 2e-6) {
      note(paste('Incorrect time increment in',tnam, 'data file'),
	   priority='SEVERE');
      return F;
    };
  };
#
# Create table description
#
  td0 := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
  td1 := tablecreatescalarcoldesc("RA", 0.0, "IncrementalStMan");
  td2 := tablecreatescalarcoldesc("DEC", 0.0, "IncrementalStMan");
  td3 := tablecreatescalarcoldesc("Rho", 0.0, "IncrementalStMan");
  td4 := tablecreatescalarcoldesc("RadVel", 0.0, "IncrementalStMan");
  td5 := tablecreatescalarcoldesc("DiskLong", 0.0, "IncrementalStMan");
  td6 := tablecreatescalarcoldesc("DiskLat", 0.0, "IncrementalStMan");
  td  := tablecreatedesc(td0, td1, td2, td3, td4, td5, td6);
#
# Move existing table to old and create new one
#
  t := mdat_create_table(tnam, td, 1.0,
			 'Table of comet/planetary positions',
			 'Comet', renew=T);
  if (!is_table(t)) {
    note(paste('Cannot create', tnam, 'table'), priority='SEVERE');
    return F;
  };
#
# Fill table keywords
#
  t.putkeyword('MJD0', mjd0);
  t.putkeyword('dMJD', dmjd);
  t.putkeyword('NAME', nm);
  t.putkeyword('GeoLong', lng);
  t.putkeyword('GeoLat',  lat);
  t.putkeyword('GeoDist', dst);
  t.putcolkeyword('MJD', 'UNIT', 'd');
  t.putcolkeyword('RA', 'UNIT', 'deg');
  t.putcolkeyword('DEC', 'UNIT', 'deg');
  t.putcolkeyword('Rho', 'UNIT', 'AU');
  t.putcolkeyword('RadVel', 'UNIT', 'AU/d');
  t.putcolkeyword('DiskLong', 'UNIT', 'deg');
  t.putcolkeyword('DiskLat', 'UNIT', 'deg');
#
# Fill Table
#
  t.addrows(length(c) - t.nrows());
  for (i in 1:length(c)) {
    t.putcell('MJD', i, c[i].et);
    t.putcell('RA', i, c[i].ra);
    t.putcell('DEC', i, c[i].dec);
    t.putcell('Rho', i, c[i].rho);
    t.putcell('RadVel', i, c[i].rv);
    t.putcell('DiskLong', i, c[i].dlg);
    t.putcell('DiskLat', i, c[i].dlt);
  };
#
# Ready
#
  j := mdat_close_table(tnam, t, 0.0001);
  return T;
};
const createcomet := createComet;
#=============================================================================
#
# Function to create a position table (e.g. for comets) from list. Arguments:
#	table name, file name. The list is e.g. output from TRAKSTAR
# Example:
#	createfromnorad('NOAA12', 'ECI21263.509');
#
#=============================================================================
const createfromnorad := function(nam, fil) {

#
# File description data
#
  tnam := nam;
  fnam := fil;
#
# Read file
#
  b := mdat_read_data(tnam, fnam, d=F);
#
# Parse data
#
  if (length(b) < 2) {
    note(paste('Incorrect', tnam, 'data file obtained'), priority='SEVERE');
    return F;
  };
#
# Analyse data
#
  lng := 0;
  lat := 0;
  dst := 0;
  nm  := '';
  k := 1;
  c := [=];
  dm.doframe(dm.observatory('wsrt'));
  for (i in k:length(b)) {
    if (length(b[i]) > 9) {
      n := length(c)+1;
      c[n] := [=];
      c[n].et := as_double(dq.unit(spaste(paste(b[i][1],b[i][2],b[i][3],sep='-'),
					  '/',b[i][4])).value);
      pos := dm.position('itrf', dq.unit(as_double([b[i][5], b[i][6], b[i][7]]), 'km'));
      utc := dm.epoch('utc',dq.unit(c[n].et,'d'));
      dm.doframe(utc);
      gmst := dm.measure(utc,'gmst');
      gmstv := (gmst.m0.value-gmst.m0.value%10)*2*pi;
      pos := dm.position('itrf',dq.unit(pos.m0.value-gmstv,'rad'),pos.m1,pos.m2);
      dir := dm.direction('itrf', pos.m0, pos.m1);
      app := dm.measure(dir,'app');
      c[n].ra := as_double(dq.convert(app.m0,'deg').value);
      c[n].dec := as_double(dq.convert(app.m1,'deg').value);
      c[n].rho := as_double(dq.convert(pos.m2,'AU').value);
      c[n].rv  := as_double(1000*sum([b[i][5],b[i][6],b[i][7]]*
				     [b[i][8],b[i][9],b[i][10]]))
      c[n].dlg := as_double(0);
      c[n].dlt := as_double(0);
    };
  };
  if (length(c) < 2) {
    note(paste('Cannot find enough data in', tnam, 'data file'), priority='SEVERE');
    return F;
  };
  dmjd := (c[length(c)].et - c[1].et)/(length(c)-1);
  mjd0 := c[1].et - dmjd;
  for (i in 1:length(c)) {
    if (abs(c[i] - (mjd0 + i*dmjd)) > 2e-6) {
      note(paste('Incorrect time increment in',tnam, 'data file'),
	   priority='SEVERE');
      return F;
    };
  };
#
# Create table description
#
  td0 := tablecreatescalarcoldesc("MJD", 0.0, "IncrementalStMan");
  td1 := tablecreatescalarcoldesc("RA", 0.0, "IncrementalStMan");
  td2 := tablecreatescalarcoldesc("DEC", 0.0, "IncrementalStMan");
  td3 := tablecreatescalarcoldesc("Rho", 0.0, "IncrementalStMan");
  td4 := tablecreatescalarcoldesc("RadVel", 0.0, "IncrementalStMan");
  td5 := tablecreatescalarcoldesc("DiskLong", 0.0, "IncrementalStMan");
  td6 := tablecreatescalarcoldesc("DiskLat", 0.0, "IncrementalStMan");
  td  := tablecreatedesc(td0, td1, td2, td3, td4, td5, td6);
#
# Move existing table to old and create new one
#
  t := mdat_create_table(tnam, td, 1.0,
			 'Table of satellite positions',
			 'Comet', renew=T);
  if (!is_table(t)) {
    note(paste('Cannot create', tnam, 'table'), priority='SEVERE');
    return F;
  };
#
# Fill table keywords
#
  t.putkeyword('MJD0', mjd0);
  t.putkeyword('dMJD', dmjd);
  t.putkeyword('NAME', 'UNKNOWN');
  t.putkeyword('GeoLong', lng);
  t.putkeyword('GeoLat',  lat);
  t.putkeyword('GeoDist', dst);
  t.putcolkeyword('MJD', 'UNIT', 'd');
  t.putcolkeyword('RA', 'UNIT', 'deg');
  t.putcolkeyword('DEC', 'UNIT', 'deg');
  t.putcolkeyword('Rho', 'UNIT', 'AU');
  t.putcolkeyword('RadVel', 'UNIT', 'AU/d');
  t.putcolkeyword('DiskLong', 'UNIT', 'deg');
  t.putcolkeyword('DiskLat', 'UNIT', 'deg');
#
# Fill Table
#
  t.addrows(length(c) - t.nrows());
  for (i in 1:length(c)) {
    t.putcell('MJD', i, c[i].et);
    t.putcell('RA', i, c[i].ra);
    t.putcell('DEC', i, c[i].dec);
    t.putcell('Rho', i, c[i].rho);
    t.putcell('RadVel', i, c[i].rv);
    t.putcell('DiskLong', i, c[i].dlg);
    t.putcell('DiskLat', i, c[i].dlt);
  };
#
# Ready
#
  j := mdat_close_table(tnam, t, 0.0001);
  return T;
};
