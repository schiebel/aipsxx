# e2emsutils: useful utilities for e2e imaging
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
# $Id: e2emsutils.g,v 19.0 2003/07/16 03:44:58 aips2adm Exp $

pragma include once;

e2emsutils := function(msname) {

  public := [=];
  private := [=];

  public.getsources:=function(query='') {
    wider private, public;

    fieldids := public.fieldids(query);

    include 'e2estandards.g';
    fluxsources := e2estandards().fluxcalibrators();

    nall := 0; ncal:=0; ntarget := 0; nflux :=0;
    result.all := ''; result.Gcal := ''; result.Target := ''; result.Fluxcal := '';
    result.Bcal := ''; result.Dcal := '';

    for (fieldid in fieldids) {
      source := private.names[fieldid];
      nall +:= 1;
      result.all[nall] := source;
      if(private.codes[fieldid]!='') {
	ncal +:= 1;
	result.Gcal[ncal] := source;
	result.Bcal[ncal] := source;
	if(any(fluxsources==source)) {
	  nflux +:=1;
	  result.Fluxcal[nflux]:=source;
	}
      }
      else {
	ntarget +:= 1;
	result.Target[ntarget] := source;
      }
    }
    return result;
  }

  public.nametofieldid:=function(names) {
    wider private;

    ids := array(-1, length(names));
    i := 0;
    for (source in names) {
      i+:=1;
      if(any(private.names==source)) {
	ids[i] := (1:length(private.names))[private.names==source];
      }
    }
    return ids;
  }

  public.config:=function(query='') {
    wider private;
    telescope:=public.telescope(query);
    antids := public.antids(query);
    config := '';
    i:=0;
    for (tel in telescope) {
      i+:=1;
      # Figure out the configuration for the VLA
      if(tel=='VLA') {
	antnames := private.stations[antids] ~ s/VLA:N// ~ s/VLA:W// ~ s/VLA:E//;
	ant := max(as_integer(antnames));
        if(ant<10) {
	  config[i] := 'D';
	}
        else if(ant<20) {
	  config[i] := 'C';
	}
        else if(ant<40) {
	  config[i] := 'B';
	}
        else {
	  config[i] := 'A';
	}
      }
      else {
	config[i] := 'STD';
      }
    }
    return config;
  }

  public.telescope:=function(query='') {
    wider private;
    obsids := public.obsids(query);
    if(is_fail(obsids)) fail;
    return private.telescopes[obsids];
  }

  public.spwids:=function(query='') {
    wider private;
    ddids := public.datadescids(query);
    if(is_fail(ddids)) fail;
    return private.spwids[ddids];
  }

  public.frequency:=function(query='') {
    wider private;
    spwids := public.spwids(query);
    if(is_fail(spwids)) fail;
    return private.qfrequencies[spwids];
  }

  public.polids:=function(query='') {
    wider private;
    ddids := public.datadescids(query);
    if(is_fail(ddids)) fail;
    return private.polids[ddids];
  }

  public.nchan:=function(query='') {
    wider private;
    ddids := public.datadescids(query);
    if(is_fail(ddids)) fail;
    return private.nchan[ddids];
  }

  private.getcol:=function(query='', col='ANTENNA1') {
    wider private;
    fullms := table(private.msname, ack=F, lockoptions='usernoread');
    fullms.lock();
    if(query!='') {
      subms := fullms.query(query);
    }
    else {
      subms := ref fullms;
    }
    if(is_fail(subms)) return throw('Query ', query, ' failed : ', subms::message);
    if(subms.nrows()) {
      ids := unique(subms.getcol(col))+1;
      fullms.unlock();
      fullms.done();
      return ids;
    }
    else {
      fullms.unlock();
      fullms.done();
      return [];
    }
  }

  public.antids:=function(query='') {
    wider private;
    return unique([private.getcol(query, 'ANTENNA1'), private.getcol(query, 'ANTENNA2')]);
  }

  public.fieldids:=function(query='') {
    wider private;
    return private.getcol(query, 'FIELD_ID');
  }

  public.interval:=function(query='') {
    wider private;
    return private.getcol(query, 'INTERVAL');
  }

  public.obsids:=function(query='') {
    wider private;
    return private.getcol(query, 'OBSERVATION_ID');
  }

  public.datadescids:=function(query='') {
    wider private;
    return private.getcol(query, 'DATA_DESC_ID');
  }

  private.finddescidgroups := function(algorithm='separate') {
    wider private, public;
    rec := [=];
    if(algorithm=='spwnames') {
      note('Basing threads on spectral window names');
      thread := 1;
      threadnames := unique(private.spwnames);
      for (thread in 1:len(threadnames)) {
	rec[thread] := [1:len(private.spwnames)][threadnames[thread]==private.spwnames];
      }
    }
    else {
      note('Basing threads on spectral windows only');
      for (thread in 1:len(private.datadescids)) {
	rec[thread] := [thread];
      }
    }
    return rec;
  }

  public.getthreads := function(algorithm='separate') {
    wider private;

    include 'e2ethread.g';
#
# Assume that different Data Descriptors have different intent. This is
# clearly wrong but a place to start.
#
    query := '';
    threads := [=];
    fullms := table(private.msname, ack=F, lockoptions='usernoread');
    fullms.lock();
#
# Look for continuity in frequency
#
    descidgroups := private.finddescidgroups(algorithm);

    for (thread in 1:len(descidgroups)) {
      query := spaste('DATA_DESC_ID in ', as_evalstr(descidgroups[thread]-1));
      if(query!='') {
	subms := fullms.query(query);
      }
      else {
	subms := ref fullms;
      }
      if(is_fail(subms)) fail;
      if(subms.nrows()) {
	threads[thread] := e2ethread(private.msname, query=query, 
				     spwid=private.spwids[descidgroups[thread]],
				     polid=private.polids[descidgroups[thread]],
				     sources=public.getsources(query),
				     nchan=private.nchan[descidgroups[thread]]);
      }
    }
    fullms.unlock();
    fullms.done();

    return threads;
  }

  public.summary := function(algorithm='separate') {
    wider private, public;
    threads := public.getthreads(algorithm);
    for (thread in 1:len(threads)) {
      note('Thread : ', thread);
      threads[thread].summary();
    }
    return T;
  }

  public.writethreads := function(algorithm='separate', file='threads.g') {
    wider private, public;
    threads := public.getthreads(algorithm);
    f := open(spaste('> ', file));
    fprintf(f, '%s\n', spaste('include \'e2ethread.g\''));
    fprintf(f, '%s\n', spaste('threads := [=];'));
    for (thread in 1:len(threads)) {
      fprintf(f, '%s\n', spaste('threads[', thread, ']:=e2ethread()'));
      fprintf(f, '%s\n', spaste('threads[', thread, '].fromrecord(', as_evalstr(threads[thread].torecord()), ')'));
    }
    f := F;
    return T;
  }

  public.done := function() {
    wider private, public;
    return T;
  }


  include 'table.g';
  include 'note.g';
  if(!tableexists(msname)) {
    return throw('MeasurementSet ', msname, ' does not exist');
  }
  private.msname := msname;

#
# Get subtable information
#
# ANTENNA
  at := table(spaste(private.msname, '/ANTENNA'), ack=F);
  if(!is_table(at)) {
    return throw('Cannot open ANTENNA table for ', private.msname);
  }
  private.stations := at.getcol('STATION');
  at.done();

# DATA DESCRIPTION
  dt := table(spaste(private.msname, '/DATA_DESCRIPTION'), ack=F);
  if(!is_table(dt)) {
    return throw('Cannot open DATA_DESCRIPTION table for ', private.msname);
  }
  private.spwids := dt.getcol('SPECTRAL_WINDOW_ID')+1;
  private.polids := dt.getcol('POLARIZATION_ID')+1;
  private.datadescids := 1:len(private.spwids);
  dt.done();

# OBSERVATION
  ot := table(spaste(private.msname, '/OBSERVATION'), ack=F);
  if(!is_table(ot)) {
    return throw('Cannot open OBSERVATION table for ', private.msname);
  }
  private.telescopes := ot.getcol('TELESCOPE_NAME');
  ot.done();

# SPECTRAL WINDOW
  st := table(spaste(private.msname, '/SPECTRAL_WINDOW'), ack=F);
  if(!is_table(st)) {
    return throw('Cannot open SPECTRAL_WINDOW table for ', private.msname);
  }
  private.frequencies := st.getcol('REF_FREQUENCY');
  private.spwnames := st.getcol('NAME');
  private.nchan := st.getcol('NUM_CHAN');
  private.qfrequencies := [=];
  include 'quanta.g';
  for (i in 1:len(private.frequencies)) {
    private.qfrequencies[i] := spaste(private.frequencies[i]/1e9, 'GHz');
  }
  st.done();

# FIELD
  ft := table(spaste(private.msname, '/FIELD'), ack=F);
  if(!is_table(ft)) {
    return throw('Cannot open FIELD table for ', private.msname);
  }
  private.fieldids := 1:len(ft.nrows());
  private.names    := ft.getcol('NAME');
  private.codes    := ft.getcol('CODE') ~ s/ //g;
  ft.done();

# Naughty, Naughty...
  public.debug := ref private;

  return ref public;
}
  
  
  
  
  
  
  
  
  
  
  
  
