# vlafiller.g: Convert VLA archive format data into an AIPS++ measurement set
# Copyright (C) 1999,2000,2001
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
# $Id: vlafiller.g,v 19.4 2005/10/24 23:28:00 kgolap Exp $

pragma include once

include 'note.g';
include 'unset.g';

# Users aren't to use this.
const _define_vlafiller := function(freqTolerance, ref serverid, toolid) {
  private := [=];
  public := [=];
      
  private.freqTolerance := freqTolerance;
  private.serverid := ref serverid;
  private.toolid := toolid;
  private.inputname := 'unset';
  private.outputname := 'unset';
  private.selectproject := unset;
  private.selecttime := unset;
  private.selectfrequency := unset;
  private.selectsource := unset;
  private.selectsubarray := unset;
  private.selectcalibrator := unset;
  
  private.tapeinputRec := 
    [_method='tapeinput', _sequence=private.toolid._sequence];
  const public.tapeinput := function(device, files=[1]){
    wider private;
    private.tapeinputRec.device := device;
    private.tapeinputRec.files := files;
    local firstFile := files[1];
    if (firstFile == 0) {
       note('Assuming you have manually positioned the tape to the start\n',
            'of the first file you want to read.',
            origin='vlafiller.tapeinput');
    } else {
       note('Positioning the tape to the start of file ', firstFile, '.',
            origin='vlafiller.tapeinput');
    }
    ok := defaultservers.run(private.serverid, private.tapeinputRec);
    if (ok) {
      local fstring := 'file '
      if (len(files) > 1) fstring := 'files ';
      private.inputname := 
	spaste(fstring, files, ' from ', device, ' (tape)');
      note('Will read ', private.inputname, origin='vlafiller.tapeinput');
    }
    return ok;
  }

  private.diskinputRec := 
    [_method='diskinput', _sequence=private.toolid._sequence];
  const public.diskinput := function(filename) {
    wider private;
    private.diskinputRec.filename := filename;
    ok := defaultservers.run(private.serverid, private.diskinputRec);
    if (ok) {
      private.inputname := spaste('file ', filename, ' (disk)');
      note('Will read from ', private.inputname, origin='vlafiller.diskinput');
    }
    return ok;
  }

  private.onlineinputRec := 
    [_method='onlineinput', _sequence=private.toolid._sequence];
  const public.onlineinput := function() {
    wider private;
    ok := defaultservers.run(private.serverid, private.onlineinputRec);
    if (ok) {
      private.inputname := spaste('the online computers (realtime)');
      note('Will read from ', private.inputname, origin='vlafiller.onlineinput');
    }
    return ok;
  }

  private.outputRec := 
    [_method='output', _sequence=private.toolid._sequence];
  const public.output := function(msname, overwrite=F) {
    wider private;
    private.outputRec.msname := msname;
    private.outputRec.overwrite := overwrite;
    ok := defaultservers.run(private.serverid, private.outputRec);
    if (ok) {
      private.outputname := spaste('measurement set ', msname);
      note('Writing to ', private.outputname, origin='vlafiller.output');
    }
    return ok;
  }

  private.selectprojectRec := [_method='selectproject', 
			       _sequence=private.toolid._sequence];
  const public.selectproject := function(project = unset) {
    wider private;
    if (is_unset(project)) {
      project := '';
    } 
    private.selectprojectRec.project := project;
    ok := defaultservers.run(private.serverid, private.selectprojectRec);
    if (ok) {
      if (project == '') {
	private.selectproject := 'Selecting data from all projects';
      } else {
	private.selectproject := spaste('Selecting data from project ',
					project);
      }
      note(private.selectproject, origin='vlafiller');
    }
    return ok;
  }

  private.selecttimeRec := [_method='selecttime', 
			    _sequence=private.toolid._sequence];
  const public.selecttime := function(start=unset, stop=unset) {
    wider private;
    if (is_unset(start)) {
      start := '1700/1/1/00:00:00';
    } 
    if (is_unset(start)) {
      start := '1700/1/1/00:00:00';
    } 
    if (is_unset(stop)) {
      stop := '2299/12/31/23:59:59'
    } 
    include 'measures.g'
    if (is_measure(start) && start.type == 'epoch') {
      start := dm.getvalue(start);
    }
    if (is_measure(stop) && stop.type == 'epoch') {
      stop := dm.getvalue(stop);
    }
    if (!is_quantity(start)) {
      start := dq.quantity(start);
    }
    if (!is_quantity(stop)) {
      stop := dq.quantity(stop);
    }
    private.selecttimeRec.start := start;
    private.selecttimeRec.stop := stop;
    ok := defaultservers.run(private.serverid, private.selecttimeRec);
    if (ok) {
      private.selecttime := 'Selecting data observed from ';
      include 'quanta.g';
      if (dq.getvalue(start) < 0) {
	private.selecttime := spaste(private.selecttime, 
				     'the start of the observation')
      } else {
	private.selecttime := spaste(private.selecttime,
				     dq.time(start, 6, form='ymd'));
      }
      if (dq.getvalue(stop) > 125000) {
	private.selecttime := spaste(private.selecttime, 
				     ' to the end of the observation')
      } else {
	private.selecttime := spaste(private.selecttime, ' to ',
				     dq.time(stop, 6, form='ymd'));
      }
      note(private.selecttime, origin='vlafiller.selecttime');
    }
    return ok;
  }

  private.selectfrequencyRec := [_method='selectfrequency', 
			         _sequence=private.toolid._sequence];
  const public.selectfrequency := function(centerfrequency=unset,
					   bandwidth=unset) {
    wider private;
    include 'quanta.g';
    if (is_unset(centerfrequency) || is_unset(bandwidth)) {
      private.selectfrequencyRec.centerfrequency := '1E18Hz';
      private.selectfrequencyRec.bandwidth := '2E18Hz';
    } else {
      private.selectfrequencyRec.centerfrequency := centerfrequency;
      private.selectfrequencyRec.bandwidth := bandwidth;
    }
    ok := defaultservers.run(private.serverid, private.selectfrequencyRec);
    if (ok) {
      if (is_unset(centerfrequency) || is_unset(bandwidth)) {
        private.selectfrequency := 'Selecting all frequencies';
      } else {
        private.selectfrequency := spaste('Selecting any data in the ', 
                                          dq.form.freq(bandwidth), 
                                          ' band around ', 
                                          dq.form.freq(centerfrequency));
      }
      note(private.selectfrequency, origin='vlafiller.selectfrequency');
    }
    return ok;
  }

  const public.selectband := function(bandname=unset) {
    wider private;
    if (is_unset(bandname)) {
      return public.selectfrequency();
    }
    if (!is_string(bandname) || strlen(bandname) != 1) {
      throw('bandname must be a single character string (or unset)')
    }
    if (bandname == '*') {
      return public.selectfrequency();
    }
    if (bandname == '4') {
       return public.selectfrequency('72MHz', '48MHz');
    }
    if (bandname == 'P' || bandname == 'p') {
       return public.selectfrequency('321.5MHz', '47MHz');
    }
    if (bandname == 'L' || bandname == 'l') {
       return public.selectfrequency('1450MHz', '600MHz');
    }
    if (bandname == 'C' || bandname == 'c') {
       return public.selectfrequency('4.65GHz', '900MHz');
    }
    if (bandname == 'X' || bandname == 'x') {
       return public.selectfrequency('8.2GHz', '2.8GHz');
    }
    if (bandname == 'U' || bandname == 'u') {
       return public.selectfrequency('14.9GHz', '2.8GHz');
    }
    if (bandname == 'K' || bandname == 'k') {
       return public.selectfrequency('23.3GHz', '5GHz');
    }
    if (bandname == 'Q' || bandname == 'q') {
       return public.selectfrequency('44.5GHz', '13GHz');
    }
    throw('bandname must be one of 4, P, L, C, X, U, K, Q or *')
  }

  private.selectsourceRec := [_method='selectsource', 
			       _sequence=private.toolid._sequence];
  const public.selectsource := function(source = unset, qualifier=unset) {
    wider private;
    if (is_unset(source)) {
      source := '';
    } 
    if (is_unset(qualifier)) {
      qualifier := -(2^16);
    } 
    private.selectsourceRec.source := source;
    private.selectsourceRec.qualifier := qualifier;
    ok := defaultservers.run(private.serverid, private.selectsourceRec);
    if (ok) {
      if (source == '') {
	private.selectsource := 'Selecting all sources';
      } else {
	private.selectsource := spaste('Selecting data from source ',
					source);
      }
      if (abs(qualifier) > 2^15) {
	private.selectsource := spaste (private.selectsource, 
					' and any qualifier');
      } else {
	private.selectsource := spaste (private.selectsource, 
					' with qualifier ', qualifier);
      }
      note(private.selectsource, origin='vlafiller.selectsource');
    }
    return ok;
  }

  private.selectsubarrayRec := [_method='selectsubarray', 
			       _sequence=private.toolid._sequence];
  const public.selectsubarray := function(subarray = unset) {
    wider private;
    if (is_unset(subarray)) {
      subarray := 0;
    }
# The following is necessary because choice guis only return strings.
    if (is_string(subarray) && strlen(subarray) == 1 && subarray ~m/[0-9]/) {
      subarray := as_integer(subarray);
    }
    if (subarray < 0 || subarray > 5) {
      return throw('The subarray id must be an integer between one and five',
		   origin='vlafiller.selectsubarray');
    }
    private.selectsubarrayRec.subarray := subarray;
    ok := defaultservers.run(private.serverid, private.selectsubarrayRec);
    if (ok) {
      if (subarray == 0) {
	private.selectsubarrays := 'Selecting all subarrays';
      } else {
	private.selectsubarray := spaste('Selecting data from subarray ',
					 subarray);
      }
      note(private.selectsubarray, origin='vlafiller.selectsubarray');
    }
    return ok;
  }

  private.selectcalibratorRec := [_method='selectcalibrator', 
				  _sequence=private.toolid._sequence];
  const public.selectcalibrator := function(calcode = unset) {
    wider private;
    if (is_unset(calcode)) {
      calcode := '#';
    }
# Note that '#' is for internal use only as unset cannot be propagated to C++.
    if ((strlen(calcode) != 1) || (calcode !~ m/[A-Za-z0-9 *\#]/ )) {
      return throw('The calcode must be an alphanumeric letter,',
		   ' an asterix or space character or unset.',
		   origin='vlafiller.selectcalibrator');
    }
    private.selectcalibratorRec.calcode := calcode;
    ok := defaultservers.run(private.serverid, private.selectcalibratorRec);
    if (ok) {
      if (calcode == '*') {
 	private.selectcalibrator := 'Selecting all calibrators';
      } else if (calcode == ' ') {
 	private.selectcalibrator := 'Discarding all calibrators';
      } else if (calcode == '#') {
 	private.selectcalibrator := 'Selecting all calibrators & sources';
      } else {
 	private.selectcalibrator := 
	  spaste('Selecting calibrators with calcode ', 
		 tr('[a-z]', '[A-Z]', calcode));
      }
      note(private.selectcalibrator, origin='vlafiller.selectcalibrator');
    }
    return ok;
  }

  private.fillRec := [_method='fill', _sequence=private.toolid._sequence];
  const public.fill := function(verbose=F, async=F) {
    wider private;
    private.fillRec.verbose := verbose;
    note('Copying the data. Be patient, this may take some time.', 
	 origin='vlafiller.fill');
    ok := defaultservers.run(private.serverid, private.fillRec, async);
    if (ok) {
      private.inputname := 'unset';
    }
    return ok;
  }

  const private.state := function() {
    wider private;
    retval := spaste('Input is ', private.inputname);
    retval := spaste(retval, '\nOutput is ', private.outputname);
    if (!is_unset(private.selectproject)) {
      retval := spaste(retval, '\n', private.selectproject);
    }
    if (!is_unset(private.selecttime)) {
      retval := spaste(retval, '\n', private.selecttime);
    }
    if (!is_unset(private.selectfrequency)) {
      retval := spaste(retval, '\n', private.selectfrequency);
    }
    if (!is_unset(private.selectsource)) {
      retval := spaste(retval, '\n', private.selectsource);
    }
    if (!is_unset(private.selectsubarray)) {
      retval := spaste(retval, '\n', private.selectsubarray);
    }
    if (!is_unset(private.selectcalibrator)) {
      retval := spaste(retval, '\n', private.selectcalibrator);
    }
    return retval;
  }

  const public.state := function() {
    wider private;
    note(private.state(), origin='vlafiller.state');
  }

  const public.stop := function() {
    wider private;
    return defaultservers.stop(private.serverid);
  }

  const public.updatestate := function(ref f, method) {
    include 'widgetserver.g';
    wider private;
    if (method == 'INIT') {
      private.toolstatus := [=];
      private.toolstatus := dws.frame(f, side='left');
      private.toolstatus.text := dws.text(private.toolstatus, disabled=T);
      private.toolstatus.vsb := dws.scrollbar(private.toolstatus);
      whenever private.toolstatus.vsb -> scroll do {
	private.toolstatus.text->view($value);
      }
      whenever private.toolstatus.text -> yscroll do {
	private.toolstatus.vsb -> view($value);
      }
      private.toolstatus.text -> insert(private.state(), 'end');
    } else if (method == 'DONE') {
      private.toolstatus.vsb := F; # cleanup
      private.toolstatus.text := F;
      private.toolstatus := F;
    } else {
      private.toolstatus.text->delete('start', 'end');
      private.toolstatus.text->insert(private.state(), 'start');
    }
    return T;
  }

  const public.done := function() {
    wider private, public;
    ok := defaultservers.done(private.serverid, private.toolid.objectid);
    if (ok) {
      private := F;
      val public := F;
    }
    return ok;
  }

  const public.type := function() {
    return 'vlafiller';
  }

  const public.id := function() {
    wider private;
    return private.toolid.objectid;
  }

  return ref public;

} # _define_vlafiller()


const vlafiller := function( freqTolerance=0.0, host=unset, forcenewserver=F) {
  include 'servers.g';
  if (is_unset(host)) {
    host := '';
  }
  serverid := defaultservers.activate('vlafiller', host, forcenewserver);
  if(is_fail(serverid)) fail;
  toolid := defaultservers.create(serverid, "vlafiller", "vlafiller", [freqTolerance = freqTolerance]);
  if(is_fail(toolid)) fail;
  return ref _define_vlafiller(freqTolerance, serverid, toolid);
} 

const vlafillerfromdisk := function(msname, filename, 
				    project=unset, 
				    start=unset, stop=unset,
				    bandname=unset,
				    source=unset,
				    overwrite=F, verbose=F, async=F, freqTolerance=0.0) {
  local v := vlafiller(freqTolerance, unset, forcenewserver=T);
  if (is_fail(v)) fail;
  if (is_fail(v.diskinput(filename))) {v.done(); fail;}
  if (is_fail(v.selectproject(project))) {v.done(); fail;}
  if (is_fail(v.selecttime(start, stop))) {v.done(); fail;}
  if (is_fail(v.selectband(bandname))) {v.done(); fail;}
  if (is_fail(v.selectsource(source))) {v.done(); fail;}
  if (is_fail(v.output(msname, overwrite))) {v.done(); fail;}
  local ok := v.fill(verbose, async);
  if (is_fail(ok)) {v.done(); fail;}
  if (async && is_numeric(ok) && ok > 0) {
    whenever defaultservers.alerter() -> [as_string(ok)] do {
      deactivate;
      v.done();
    }
  } else {
    v.done();
  }
  return T;
}

const vlafillerfromtape := function(msname, device, files=[1], 
				    project=unset, 
				    start=unset, stop=unset,
				    bandname=unset,
				    source=unset,
				    overwrite=F, verbose=F,
				    async=T, host=unset) {
  local v := vlafiller(host, forcenewserver=T); if (is_fail(v)) return F;
  if (is_fail(v.tapeinput(device, files))) {v.done(); fail;}
  if (is_fail(v.selectproject(project))) {v.done(); fail;}
  if (is_fail(v.selecttime(start, stop))) {v.done(); fail;}
  if (is_fail(v.selectband(bandname))) {v.done(); fail;}
  if (is_fail(v.selectsource(source))) {v.done(); fail;}
  if (is_fail(v.output(msname, overwrite))) {v.done(); fail;}
  local ok := v.fill(verbose, async);
  if (is_fail(ok)) {v.done(); fail;}
  if (async && is_numeric(ok) && ok > 0) {
    whenever defaultservers.alerter() -> [as_string(ok)] do {
      deactivate;
      v.done();
    }
  } else {
    v.done();
  }
  return T;
}

const vlafilleroldweights := function(msname) {
  note('Resetting the WEIGHT and SIGMA columns of the ', msname, 
       ' measurement set\n',
       'to values that depend only on the integration time.',
       origin='vlafilleroldweights');
  maxRows := 10000; 
  include 'table.g';
  vis := table(msname, readonly=F, ack=F);
  visbyinttime := tableiterator(vis, 'EXPOSURE', sort=F);
  visbyinttime.reset();
  while (visbyinttime.next()) {
    nrows := visbyinttime.table().nrows();
    intTime := visbyinttime.table().getcell('EXPOSURE', 1);
    ncorr := shape(visbyinttime.table().getcell('WEIGHT', 1));
    oldWeight := intTime/10.0;
    oldSigma := 1.0/sqrt(oldWeight); 
    startRow := 1;
    nRows := min(maxRows, nrows-startRow+1);
    while (nRows > 0) {
      visbyinttime.table().putcol('WEIGHT', array(oldWeight, ncorr, nRows),
				  startRow, nRows);
      visbyinttime.table().putcol('SIGMA', array(oldSigma, ncorr, nRows),
				  startRow, nRows);
      startRow +:= maxRows;
      nRows := min(maxRows, nrows-startRow+1);
    }
  }
  visbyinttime.done();
  vis.done();
  return T;
}

const vlafillerdemo  := function()
{
  include 'tvlafiller.g';
  return _vlafillerdemo();
}

const vlafillertest := function()
{
  include 'tvlafiller.g';
  return _vlafillertest();
}
