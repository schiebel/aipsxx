# flagger.g: Flag visibility data
#
#   Copyright (C) 1998,1999,2000,2001,2002
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: flagger.g,v 19.2 2004/08/25 01:15:27 cvsmgr Exp $

pragma include once;
    
include "ms.g";
include "misc.g";
include 'note.g';
include 'table.g';
include 'statistics.g';
include 'quanta.g';
include 'measures.g';
include 'unset.g';

flaggertester := function(msfile='3C273XC1.ms') {
  include 'imager.g';
  imagermaketestms(msfile);
  return flagger(msfile);
};

flagger := function(msfile) {
  public := [=];
  private := [=];

  private.msfile := msfile;

  # Get ms summary information
  private.ms := ms(msfile);
  private.ms.summary();
  private.numval := private.ms.range("num_chan num_corr");
  private.ms.done();
  private.ms := F;
  private.nchan := private.numval.num_chan;
  private.ncorr := private.numval.num_corr;

  private.tab := table(msfile, readonly=F);
  private.st:=F;
  if (!is_table(private.tab)) {
    return throw('Table ', msfile, ' cannot be opened');
  };


  const private.subtable := function(query=F) {
    wider private;

    # finish old subtable, if necessary
    if (is_table(private.st)) {
       private.st.done();
    }

    aquery := F;

    # OR together the time-related queries
    private.alltimequery:=F;
    for (quer in "timequery timerangequery") {
      if (is_string(private[quer])) {
        if (is_boolean(private.alltimequery)) {
          private.alltimequery := spaste('(',private[quer],')');
        } else {
          private.alltimequery := spaste(private.alltimequery,
                                         '||',
                                         spaste('(',private[quer],')'));
        };
      };
    };

    # OR together the antenna-related queries
    private.allantquery:=F;
    for (quer in "antquery blquery") {
      if (is_string(private[quer])) {
        if (is_boolean(private.allantquery)) {
          private.allantquery := spaste('(',private[quer],')');
        } else {
          private.allantquery := spaste(private.allantquery,
                                        '||',
                                        spaste('(',private[quer],')'));
        };
      };
    };
   

    # AND together the alltime, allant, and other queries
    for (quer in "alltimequery allantquery feedquery idquery uvrquery miscquery") {
      if (is_string(private[quer])) {
	if (is_boolean(aquery)) {
	  aquery := spaste('(',private[quer],')');

	} else {
	  aquery := spaste(aquery, 
                           '&&',
                           spaste('(',private[quer],')'));

	};
      };
    };
    private.lastquery := aquery;
    if (is_boolean(aquery)) {
      private.st:= private.tab.query('TIME > 0.0');
    } else {
      private.st := private.tab.query(aquery);
      if (!is_table(private.st)) {
	return throw('Table query ', query, ' failed : ', private.st::message,
		     origin='flagger.query');
      };
    };
  };


  const private.ddid := function (msfile, spwid) {
  # Private function to look up DATA_DESC_ID's for a given SPW_ID
    # Open the DATA_DESCRIPTION sub-table
    ddtab:= table (spaste (msfile,'/','DATA_DESCRIPTION'));
    ddspwid:= ddtab.getcol ('SPECTRAL_WINDOW_ID');
    ddflagrow:= ddtab.getcol ('FLAG_ROW');
    nddrow:= ddtab.nrows();
    ddtab.done();

    # Iterate through non-flagged rows, to find SPW_ID matches
    if (nddrow > 0) {
       dd:= [];
       ndd:= 0;
       for (i in 1:nddrow) {
          if (!ddflagrow[i] && (ddspwid[i])==spwid) {
             ndd:= ndd + 1;
             dd[ndd]:= i-1;
          };
       };
    };	
    return dd;
  };

  const public.flag := function (trial=F) {
    wider public, private;
    public.setflagmode('flag');
    public.state();
    return private.doflag(trial);
  };

  const public.unflag := function (trial=F) {
    wider public, private;
    public.setflagmode('unflag');
    public.state();
    return private.doflag(trial);
  };

  const private.doflag := function (trial=F) {
    wider private;

    # realize data selection in private.st
    private.subtable();


    nrows:= private.st.nrows();
    if (nrows) {
      if (trial) {
	if (private.flagval) {
	  note('Flagging would flag ', nrows, ' rows');
	} else {
	  note('Flagging would unflag ', nrows, ' rows');
	};
        return T;
      } else {
	if (private.flagval) {
	  note('Flagging ', nrows, ' rows');
	} else {
	  note('Unflagging ', nrows, ' rows');
	};
      };

      ti := tableiterator(private.st, 'TIME');
      ti.reset();
      nlines := 0;
      total := 0;
      while (ti.next()) {
	tf := ti.table().getcol('FLAG');

	if (private.dopol&&private.dochan) {
	  tf[private.pol,private.chan,] := private.flagval;

	} else if (!private.dopol&&private.dochan) {
	  tf[,private.chan,] := private.flagval;

	} else if (private.dopol&&!private.dochan) {
	  tf[private.pol,,] := private.flagval;

	} else if (!private.dopol&&!private.dochan) {
	  tf[,,] := private.flagval;
	};
	ti.table().putcol('FLAG', tf);
        tf := F;
      };
      ti.terminate();
      ti.done();
      return T;
    } else {
      note('Query selects no rows');
      return F;
    };
  };

  const public.setflagmode := function(mode='flag') {
    wider private;
    if (mode == 'flag' || mode == 'unflag') {
      private.flagmode := mode;
      private.flagval := private.flagmode=='flag';
      private.flagtxt := spaste(private.flagmode, 'ged ');
    } else {
      return throw('Unknown flagmode: ', mode,
		   origin='flagger.setflagmode');
    };
    return T;
  };

  const public.setids := function(fieldid=[], spectralwindowid=[],
				  arrayid=[]) {
    wider private;
    if (!is_numeric(fieldid)) {
      return throw('fieldid must be numeric', origin='flagger.setids');
    };
    if (!is_numeric(spectralwindowid)) {
      return throw('spectralwindowid must be numeric',
		   origin='flagger.setids');
    };
    if (!is_numeric(arrayid)) {
      return throw('arrayid must be numeric', origin='flagger.setids');
    };
    private.fieldid := fieldid-1;
    if (any(fieldid<1)) {
      private.fieldid := fieldid[fieldid>0]-1;
      note('Removed some fieldid that were out of range',
	   priority='WARN',
	   origin='flagger.setids');
    };
    private.spectralwindowid := spectralwindowid-1;
    if (any(spectralwindowid<1)) {
      private.spectralwindowid := spectralwindowid[spectralwindowid>0]-1;
      note('Removed some spectralwindowid that were out of range',
	   priority='WARN',
	   origin='flagger.setids');
    };
    private.arrayid := arrayid-1;
    if (any(arrayid<1)) {
      private.arrayid := arrayid[arrayid>0]-1;
      note('Removed some arrayid that were out of range',
	   priority='WARN',
	   origin='flagger.setids');
    };

    private.idquery := F;
    if (length(private.fieldid)>0) {
      if (is_boolean(private.idquery)) {
	private.idquery := spaste('(');
      } else {
	private.idquery := spaste(private.idquery, ' && (');
      };
      if (length(private.fieldid)==1) {
	private.idquery := spaste(private.idquery,
				  'FIELD_ID in [', as_evalstr(private.fieldid), ']');
      }
      else {
	private.idquery := spaste(private.idquery,
				  'FIELD_ID in ', as_evalstr(private.fieldid));
      };
      private.idquery := spaste(private.idquery, ')');
    };
    if (length(private.spectralwindowid)>0) {
      if (is_boolean(private.idquery)) {
	private.idquery := spaste('(');
      } else {
	private.idquery := spaste(private.idquery, ' && (');
      };
      dds := [];
      i:=0;
      for (id in private.spectralwindowid) {
 	# Find the associated DATA_DESC_ID's
	i+:=1;
	dds[i] := private.ddid(private.msfile, id);
      };
      if (length(dds)==1) {
	private.idquery := spaste(private.idquery,
				  'DATA_DESC_ID in [', as_evalstr(dds), ']');
      }
      else {
	private.idquery := spaste(private.idquery,
				  'DATA_DESC_ID in ', as_evalstr(dds));
      };
      private.idquery := spaste(private.idquery, ')');
    };
    if (length(private.arrayid)>0) {
      if (is_boolean(private.idquery)) {
	private.idquery := spaste('(');
      } else {
	private.idquery := spaste(private.idquery, ' && (');
      };
      if (length(private.arrayid)==1) {
	private.idquery := spaste(private.idquery,
				  'ARRAY_ID in [', as_evalstr(private.arrayid), ']');
      }
      else {
	private.idquery := spaste(private.idquery,
				  'ARRAY_ID in ', as_evalstr(private.arrayid));
      };
      private.idquery := spaste(private.idquery, ')');
    };
    if (!is_boolean(private.idquery)) {
      private.idquery := spaste('(', private.idquery, ')');
    };
    return T;
  };

  const public.setpol := function(pol=[], polnames=unset) {
    wider private;
    if (is_string(polnames)) {
      return throw('Polarization names not yet implemented');
    } else {
      if (is_numeric(pol)) {
	private.pol := pol;
	if ( length(pol)>0 && (any(pol<1) || any(pol>private.ncorr)) ) {
	  private.pol := pol[pol>0 & pol<=private.ncorr];
	  note('Removed some pol that were out of range',
	       priority='WARN',
	       origin='flagger.setpol');
	};
	private.dopol := as_boolean(length(private.pol));
      } else {
	return throw('pol must be numeric', origin='flagger.setpol');
      };
      return T;
    };
  };

  const public.setchan := function(chan=[], channames=unset) {
    wider private;
    if (is_string(channames)) {
      return throw('Channel names not yet implemented');
    } else {
      if (is_numeric(chan)) {
	private.chan := chan;
	if (length(chan)>0 && (any(chan<1) || any(chan>private.nchan)) ) {
	  private.chan := chan[chan>0 & chan<=private.nchan];
	  note('Removed some chan that were out of range',
	       priority='WARN',
	       origin='flagger.setchan');
	};
	private.dochan := as_boolean(length(private.chan));
      } else {
	return throw('chan must be numeric', origin='flagger.setchan');
      };
      return T;
    };
  };

  const public.setantennas := function(ants=[], antnames=unset) {
    wider private;
    if (is_string(antnames)) {
      return throw('Antenna names not yet implemented');
    } else {

      if (is_numeric(ants)) {
        # remove those less than zero
	if (any(ants<1)) {
	  ants := ants[ants>0];
	  note('Removed some ants that were out of range',
	       priority='WARN',
	       origin='flagger.setantennas');
	};

        # correct for zero-based counting
	private.ants := ants-1;

	private.antquery := F;

        if (shape(private.ants > 0)) {
          private.antquery := spaste( '( (ANTENNA1 IN ',
                                           as_evalstr(private.ants),')',
                                        ' || ',
                                        '(ANTENNA2 IN ',
                                           as_evalstr(private.ants),'))');
        };
      } else {
	return throw('ants must be numeric', origin='flagger.setantennas');
      };
    };
    return T;
  };

  const public.setbaselines := function(ants=[], antnames=unset) {
    wider private;
    if (is_string(antnames)) {
      return throw('Antenna names not yet implemented');
    } else {
      if (is_numeric(ants)) {
        # remove those less than zero
	if (any(ants<1)) {
	  ants := ants[ants>0];
	  note('Removed some ants that were out of range',
	       priority='WARN',
	       origin='flagger.setantennas');
	};

        # correct for zero-based counting
	private.bls := ants-1;

	private.blquery := F;

        if (shape(private.bls > 0)) {
          private.blquery := spaste( '( (ANTENNA1 IN ',
                                           as_evalstr(private.bls),')',
                                        ' && ',
                                        '(ANTENNA2 IN ',
                                           as_evalstr(private.bls),'))');
        };
      } else {
	return throw('ants must be numeric', origin='flagger.setantennas');
      };
    };
    return T;
  };

  const public.setfeeds := function(feeds=[]) {
    wider private;
    if (is_numeric(feeds)) {
      private.feeds := feeds-1;
      if (any(feeds<1)) {
	private.feeds := feeds[feeds>0]-1;;
	note('Removed some feeds that were out of range',
	     priority='WARN',
	     origin='flagger.setfeeds');
      };
      private.feedquery := F;
      for (feed in private.feeds) {
	if (is_boolean(private.feedquery)) {
          private.feedquery := spaste('((FEED1==', feed, ')||(FEED2==',
				      feed, '))');
	} else {
          private.feedquery := spaste(private.feedquery, '||((FEED1==',
				      feed, ')||(FEED2==', feed, '))');
	};
      };
    } else {
      return throw('feeds must be numeric', origin='flagger.setfeeds');
    };
    return T;
  };

  const public.setuvrange := function(uvmin="0.0m", uvmax="0.0m") {
    wider private;
    private.uvrquery:=F;
    if (dq.check(uvmin) && dq.check(uvmax)) {
      uvr1:=dq.getvalue(dq.convert(uvmin,'m'));
      uvr2:=dq.getvalue(dq.convert(uvmax,'m'));
      if (uvr1==0.0 && uvr2==0.0) {
        private.uvsel:='[]';
      } else {
	private.uvsel:=spaste(uvmin,',');
        private.uvrquery:= spaste(
         '(sqrt(UVW[1]*UVW[1]+UVW[2]*UVW[2])>=',uvr1,')')
        if (uvr2 > uvr1) {
	  private.uvsel:=spaste('[',private.uvsel,uvmax,']');
          private.uvrquery:=spaste( private.uvrquery, 
           ' && (sqrt(UVW[1]*UVW[1]+UVW[2]*UVW[2])<=',uvr2,')')
        } else {
          private.uvsel:=spaste('[',private.uvsel,']');
        };

	note(spaste('Selected uvrange: ',private.uvsel),
          priority='NORMAL',origin='flagger.setuvrange');      
      };
      return T;

    } else {
      return throw('Please specify uvmin and uvmax as string quantities.',
          origin='flagger.setuvrange');
    };
  };

  const public.settime := function(centertime=[], delta='10s') {
    wider private;
    if (!dq.check(delta)) {
      return throw(paste('Delta ', delta, 'must be a quantity'));
    };
    private.delta := delta;
    dtdays:=dq.getvalue(dq.convert(delta, '1.0d'));
    private.centertime := centertime;
    private.timequery:=F;

    if (is_string(private.centertime)) {
      for (i in 1:length(centertime)) {
        if (is_boolean(private.timequery)) {
          private.timequery := spaste('(TIME',
                                      '>= 86400*(MJD(',centertime[i],')-',dtdays,')',
                                      ')&&(TIME',
                                      '<=86400*(MJD(',centertime[i],')+',dtdays,'))');
        } else {
          private.timequery := spaste(private.timequery,'||',
                                      '(TIME',
                                      '>= 86400*(MJD(', centertime[i],')-',dtdays,')',
                                      ')&&(TIME',
                                      '<=86400*(MJD(',centertime[i],')+',dtdays,'))');
        };
      };
    } else {
#      return throw(paste('Time', centertime,'must be a string'),
#		   origin='flagger.time');
    };
    return T;
  };

  const public.settimerange := function(starttime=[], endtime=[]) {

    wider private;

    if (shape(starttime) != shape(endtime)) {
      return throw('Please specify the same number of starttimes and endtimes!');
    };

    private.starttime := starttime
    private.endtime := endtime
    private.timerangequery:=F;

    if (is_string(private.starttime) && is_string(private.endtime)) {
      for (i in 1:shape(starttime)) {
        if (dq.quantity(starttime[i]).value > dq.quantity(endtime[i]).value) {
          public.settimerange();   # this clears current bogus values from private
          return throw(spaste('starttime = ',starttime[i],' is later than ',
                               'endttime = ',endtime[i]));
        }; 
      };

      for (i in 1:length(starttime)) {
        if (is_boolean(private.timerangequery)) {
          private.timerangequery := spaste('(TIME',
                                           '>=86400*MJD(',starttime[i],')',
                                           ')&&(TIME',
                                           '<=86400*MJD(',endtime[i],')',')');
        } else {
          private.timerangequery := spaste(private.timerangequery,'||',
                                           '(TIME',
                                           '>=86400*MJD(',starttime[i],')',
                                           ')&&(TIME',
                                           '<=86400*MJD(',endtime[i],')',')');
        };
      };
    } else {
#      return throw(paste('Time', centertime,'must be a string'),
#		   origin='flagger.time');
    };
    return T;
  };

  const private.setquery := function(query=F,comb=F) {
    wider private;
    if (!is_boolean(query)) {
      if (is_boolean(private.miscquery) || is_boolean(comb)) {
        private.miscquery := query;
      } else {
        private.miscquery := spaste(private.miscquery, comb, query);
      };
    } else {
      private.miscquery:=F;
    };
    return T;
  };


# Old methods (query, time, timerange) still work (maybe using new methods)
  const public.query := function(query=F,trial=F) {
    wider public, private;
    if (!is_boolean(query)) {
      private.setquery(query,F)
      public.flag(trial);
      private.setquery(F,F);
    } else {
      return throw('Please specify a query string.', origin='flagger.query');
    };
    return T;
  };


  const public.time := function(centertime=F, delta='10s', trial=F) {
    wider private;
    if (!dq.check(delta)) {
      return throw(paste('Delta ', delta, 'must be a quantity'));
    };
    dt := dq.getvalue(dq.convert(delta, '1.0d'));
    if (is_string(centertime)) {
      for (i in 1:length(centertime)) {

	query := spaste('((TIME/(24*3600)+',dt,'>=MJD(',centertime[i],')',
			 ')&&(TIME/(24*3600)-',
			 dt,'<=MJD(',centertime[i],')))');
        if (trial) {
	  note('Flagging would occur for ', centertime[i], ' +/- ',
	       dq.convert(delta, 's').value, 's');
	} else {
	  note('Flagging ', centertime[i], ' +/- ',
	       dq.convert(delta, 's').value, 's');
	};
	result := public.query(query,trial=trial);
	if(is_fail(result)) return result;
      };
    } else {
      return throw(paste('Time', centertime,'must be a string'),
		   origin='flagger.time');
    };
    return T;
  };

  const public.timerange := function(starttime=F, endtime=F, trial=F) {
    wider private;
    if (is_string(starttime)&&is_string(endtime)) {
      for(i in 1:length(starttime)) {
	query := spaste('((TIME/(24*3600)>=MJD(',starttime[i],
			'))&&(TIME/(24*3600)<=MJD(',endtime[i],')))');
        if (trial) {
          note('Flagging would occur for ', starttime[i], ' to ', endtime[i]);
        } else {
          note('Flagging ', starttime[i], ' to ', endtime[i]);
        };
	result := public.query(query,trial=trial);
	if(is_fail(result)) return result;
      };
    } else {
      return throw('Times must be strings', origin='flagger.timerange');
    };
    return T;
  };

  # Heuristic methods (quack, flagac)

  const public.quack := function(delta='0s', 
                                 begin=T, end=F, 
                                 scaninterval='0s', trial=F) {
    wider private;

    if (!dq.check(delta)) {
      return throw(paste('Delta ', delta, 'must be a quantity'));
    };
    dt := dq.convert(delta, 's').value;

    if (!dq.check(scaninterval)) {
       return throw(paste('scaninterval must be a quantity'));
    };
    si := dq.convert(scaninterval, 's').value;

    if(is_fail(private.subtable())) fail;

    note('Finding scan boundaries');

    ti:=tableiterator(private.st, 'SCAN_NUMBER');
    ti.reset();

    btimes:= [''];
    etimes:= [''];
    itimes:=0;
    while (ti.next()) {
      times := sort(unique(ti.table().getcol('TIME')));  
      expos:=min(unique(ti.table().getcol('EXPOSURE')));
      ntimes:=shape(times);

      # use expos if it is larger than dt
      thisdt:=max(dt,expos);

      if (begin) {
        # First times in scan should be quacked
        note('Scan starts at ', dq.time(dq.quantity(times[1],'s')));
        itimes +:=1;
        btimes[itimes]:=dq.time(dq.quantity(times[1]-expos/2,'s'),form='ymd');
        etimes[itimes]:=dq.time(dq.quantity(times[1]+thisdt-expos/2,'s'),form='ymd');
      };

      if (end) {
        # last times in scan to be quacked
        note('Scan ends at   ', dq.time(dq.quantity(times[ntimes],'s')));
        itimes +:=1;
        btimes[itimes]:=dq.time(dq.quantity(times[ntimes]-thisdt+expos/2,'s'),form='ymd');
        etimes[itimes]:=dq.time(dq.quantity(times[ntimes]+expos/2,'s'),form='ymd');
      };

      # If desired, check for any gaps within the scan
      if (si > 0) {
        for (i in 2:length(times)) {
          if((times[i]-times[i-1])>si) {
            note('Scan gap at ', dq.time(dq.quantity(times[i],'s')));
            if (begin) {
              itimes +:=1;
              btimes[itimes]:=dq.time(dq.quantity(times[i]-expos/2,'s'),form='ymd');
              etimes[itimes]:=dq.time(dq.quantity(times[i]+thisdt-expos/2,'s'),form='ymd');
            };
            if (end) {
              itimes +:=1;
              btimes[itimes]:=dq.time(dq.quantity(times[i-1]-thisdt+expos/2,'s'),form='ymd');
              etimes[itimes]:=dq.time(dq.quantity(times[i-1]+expos/2,'s'),form='ymd');
            };
          };
        };
      };
    };
    ti.terminate();
    ti.done();
    if (itimes>0) {
      result:=public.timerange(starttime=btimes,endtime=etimes,trial=trial);
      if(is_fail(result)) return result;
    };
    return T;
  };

  const public.flagac := function(trial=F) {
    wider public;
    private.setquery('ANTENNA1==ANTENNA2',F);
    public.flag(trial=trial);
    private.setquery(F,F);
  };

  const public.auto := function(trial=F) {
    wider public;
    return public.flagac(trial);
  };

  const public.filter := function(column='CORRECTED_DATA', operation='median',
				  comparison='Amplitude', 
				  range=['0Jy', '1E6Jy'],
				  threshold=[0.0, 5.0],
				  fullpol=F, fullchan=F, trial=F) {
    wider private;

    if (operation=='range') {
      range := split(range);
      if (length(range)!=2) {
	return throw ('Range must have two elements: min and max allowed');
      };
      if (!is_string(range[1])) {
	return throw('Range must be in form of strings e.g. \"1e-6Jy 100Jy\"');
      };
      
      if (comparison=='Phase') {
	value := dq.convert(range[1], 'rad');
	if (is_fail(value)) {
	  return throw('First element of range is wrong for ',
		       comparison, ' comparisons');
	};
	rmin := value.value;
	value := dq.convert(range[2], 'rad');
	if (is_fail(value)) {
	  return throw('Second element of range is wrong for ',
		       comparison, ' comparisons');
	};
	rmax := value.value;
      } else {
	value := dq.convert(range[1], 'Jy');
	if (is_fail(value)) {
	  return throw('First element of range is wrong for ',
		       comparison, ' comparisons');
	};
	rmin := value.value;
	value := dq.convert(range[2], 'Jy');
	if (is_fail(value)) {
	  return throw('Second element of range is wrong for ',
		       comparison, ' comparisons');
	};
	rmax := value.value;
      };
    } else if (operation=='median') {
      if (length(threshold)!=2) {
	return throw ('threshold must have two elements: min and max allowed');
      };
      if (!is_numeric(threshold[1])) {
	return throw ('Threshold must be in form of numbers e.f. [0.0, 5.0]');
      };
      rmax := threshold[1];
      rmin := threshold[2];
    } else {
      return throw('Unknown filtering operation ', operation,
		   origin='flagger.filter');
    };

    
    if(is_fail(private.subtable())) fail;

    ti := tableiterator(private.st, 'TIME');
    ti.reset();

    nlines := 0;
    total := 0;
    while(ti.next()) {
      if (column=='RESIDUAL_DATA') {
	td := ti.table().getcol('CORRECTED_DATA');
	if (is_fail(td)) return throw(td::message);
	td -:= ti.table().getcol('MODEL_DATA');
      } else {
	td := ti.table().getcol(column);
	if (is_fail(td)) return throw(td::message);
      };
      if (is_fail(td)) return throw(td::message);
      nlines +:= td::shape[length(td::shape)];
      if (comparison=='Phase') {
        td := arg(td);
      } else if (comparison=='Real') {
        td := real(td);
      } else if (comparison=='Imaginary') {
        td := imag(td);
      } else {
        td := abs(td);
      };

      # extract flag column:
      tf := ti.table().getcol('FLAG');

      # make a mask array that covers all of td:
      tdshape:=shape(td);
      npol:=ref tdshape[1];
      nchan:=ref tdshape[2];
      nrow:=ref tdshape[3];
      mask:=array(F,npol,nchan,nrow);
 
      if (private.dopol) {   # test only some polarizations

        if (private.dochan) {   # test only some channels

          if (operation=='median') { # median filter
            med:=median(td[private.pol,private.chan,]);
            mask[private.pol,private.chan,]:=(td[private.pol,private.chan,]<=rmin*med)|
                                             (td[private.pol,private.chan,]>=rmax*med);
          } else {                   # clip
            mask[private.pol,private.chan,]:=(td[private.pol,private.chan,]<=rmin)|
                                             (td[private.pol,private.chan,]>=rmax);
          };

        } else {                # test all channels
          if (operation=='median') { # median filter
            med:=median(td[private.pol,,]);
            mask[private.pol,            ,]:=(td[private.pol,            ,]<=rmin*med)|
                                             (td[private.pol,            ,]>=rmax*med);
          } else {                   # clip
            mask[private.pol,            ,]:=(td[private.pol,            ,]<=rmin)|
                                             (td[private.pol,            ,]>=rmax);
          };

        };

      } else {               # test all polarizations

        if (private.dochan) {   # test only some channels

          if (operation=='median') { # median filter
            med:=median(td[private.pol,,]);
            mask[           ,private.chan,]:=(td[           ,private.chan,]<=rmin*med)|
                                             (td[           ,private.chan,]>=rmax*med);
          } else {                   # clip:
            mask[           ,private.chan,]:=(td[           ,private.chan,]<=rmin)|
                                             (td[           ,private.chan,]>=rmax);
          };

        } else {                # test all channels

          if (operation=='median') { # median filter
            med:=median(td[,,]);
            mask[           ,            ,]:=(td[           ,            ,]<=rmin*med)|
                                             (td[           ,            ,]>=rmax*med);
          } else {                   # clip:
            mask[           ,            ,]:=(td[           ,            ,]<=rmin)|
                                             (td[           ,            ,]>=rmax);
          };

        };

      };

      # expand editing scope over pol and/or channel
      #  (if any flags to expand, and axes to expand over)
      if ( any(mask) & (fullpol | fullchan) & (nchan*npol > 1) ) {

        # either axis of length one, then full* makes faster
        if (nchan==1) fullchan:=T;
        if (npol==1) fullpol:=T;

        # loop over rows:
        if (fullpol & fullchan) {  # expand over both pol and chan
          for (irow in 1:nrow) {
            mask[,,irow]:=any(mask[,,irow]);
          };
        } else {
          if (fullpol & !fullchan) {  # expand only over pol
            # loop over channel:
            for (ichan in 1:nchan) {
              for (irow in 1:nrow) {
                mask[,ichan,irow]:=any(mask[,ichan,irow]);
              };
            };
          } else if (!fullpol & fullchan) {  # expand only over chan
            # loop over pol:
            for (ipol in 1:npol) {
              for (irow in 1:nrow) {
                mask[ipol,,irow]:=any(mask[ipol,,irow]);
              };
            };
          };
        };
      };

      # increment total of *new* (un-)flags:
      if (private.flagval) {   # flagging
        total +:= sum(mask & !tf);  # passed test and not yet flagged
      } else {                  # unflagging
        total +:= sum(mask & tf);   # passed test and already flagged
      };

      # apply (un-)flags:
      if (!trial & any(mask)) {
        tf[mask] := private.flagval;
        ti.table().putcol('FLAG', tf);
      };

    };  # (iterator)
    ti.terminate();
    ti.done();
    if (trial) {
      note('Filtering (in ', operation, ' mode) would have ', private.flagtxt,
	   total, ' additional data points');
    } else {
      note('Filtering (in ', operation, ' mode) has ', private.flagtxt,
	   total, ' additional data points');
    };
    return T;
  };

  const public.calsolutions := function(gaintable='',
					threshold=5.0, mode='time',
					trial=F) {
    wider private;

    if ((gaintable=='')||!is_string(gaintable)) {
	return throw('You must specify a gaintable',
		     origin='flagger.calsolutions');
    };
    gt := table(gaintable);
    if (!is_table(gt)) {
      return throw (spaste('Failed to open gaintable ', gaintable),
		    origin='flagger.calsolutions');
    };

    total := 0;

    delta := dq.quantity(gt.getcol('INTERVAL')[1], 's');
    if (mode=='time') {
      afits := gt.getcol('FIT');
      med:= median(afits[afits>0.0]);
      note('Median fit per interval = ', med, ' Jy');
      times := gt.getcol('TIME');
      mask := (afits>threshold*med);
      times := times[mask];
      tlast := 0.0;
      atimes := "";
      for (i in 1:length(times)) {
	if (times[i]!=tlast) {
	  total +:= 1;
          atimes[total] := dq.time(dq.quantity(times[i], 's'), form='ymd');
	  tlast := times[i];
	};
      };
      if (!trial&&(total>0)) {
	return public.time(centertime=atimes, delta=delta);
      };
    } else if (mode=='antenna') {
      gt.close();
      return throw (spaste('Mode antenna not yet implemented',
		    origin='flagger.calsolutions'));
    } else {
      gt.close();
      return throw (spaste('Unknown mode ', mode, 'for editing cal solutions'),
		    origin='flagger.calsolutions');
    };
    if (trial) {
      note('Calibration filtering of gain solutions would have ',
	   private.flagtxt, total, ' times');
    } else {
      note('Calibration filtering of gain solutions has ', 
	   private.flagtxt, total, ' times');
    };
    gt.close();
    return T;
  };

  const public.flush := function() {
    wider private;
    private.tab.flush();
    return T;
  };

  const public.done := function() {
    wider public, private;
    private.tab.flush();
    if (is_table(private.st)) {
      private.st.flush();
      private.st.done();
    };
    if (is_table(private.tab)) {
      private.tab.flush();
      private.tab.done();
    };

    val private :=F;
    val public :=F;
    return T;
  };

  const public.close := ref public.done;

  const public.reset := function() {
    wider private, public;
    public.settime();
    public.settimerange();
    public.setchan();
    public.setpol();
    public.setantennas();
    public.setbaselines();
    public.setfeeds();
    public.setuvrange();
    public.setids();
    public.setflagmode();
    private.setquery();
    private.lastquery := '';
    return T;
  };

  const public.state := function(ref state=[=]) {
    wider private, public;
    val state := [table=private.msfile, chan=private.chan, pol=private.pol,
		 antennas=private.ants,
		 feeds=private.feeds];
    str := spaste(     'Measurement Set      : ',
		       as_evalstr(private.msfile), '\n\n');

    str := spaste(str, 'Timerange:  starttime: ',
                  as_evalstr(private.starttime),'\n');
    str := spaste(str, '              endtime: ',
                  as_evalstr(private.endtime),'\n');
    str := spaste(str, 'Times:          times: ',
                  as_evalstr(private.centertime),'\n');
    str := spaste(str, '                delta: ',
                  as_evalstr(private.delta),'\n\n');

    str := spaste(str, 'Antennas             : ',
		  as_evalstr(private.ants+1), '\n');
    str := spaste(str, 'Baselines            : ',
		  as_evalstr(private.bls+1), '\n');
    str := spaste(str, 'Feeds                : ',
		  as_evalstr(private.feeds+1), '\n');
    str := spaste(str, 'UV-Range             : ',
                  private.uvsel, '\n\n');

    str := spaste(str, 'Array IDs            : ',
		  as_evalstr(private.arrayid+1), '\n');
    str := spaste(str, 'Field IDs            : ',
		  as_evalstr(private.fieldid+1), '\n');
    str := spaste(str, 'Spectral window IDs  : ',
		  as_evalstr(private.spectralwindowid+1), '\n');
    str := spaste(str, 'Channels             : ',
		  as_evalstr(private.chan), '\n');
    str := spaste(str, 'Polarizations        : ',
		  as_evalstr(private.pol), '\n\n');

#    str := spaste(str, 'Misc. query          : ',
#		  as_evalstr(private.miscquery), '\n\n');

    str := spaste(str, 'Flagmode             : ',
		  as_evalstr(private.flagtxt), '\n');
    str := spaste(str, 'Last query           : ',
		  as_evalstr(private.lastquery), '\n');
    return str;
  };

  public.updatestate := function(ref f, method) {
    include "widgetserver.g";
    if (method == 'INIT') {
      tf := dws.frame(f, side='left');
      f.text := dws.text(tf);
      vsb := dws.scrollbar(tf);
      whenever vsb->scroll do f.text->view($value);
      whenever f.text->yscroll do vsb->view($value);
      f.text->insert(public.state(), 'end');
    } else if (method == 'DONE') {
      f.text := F; 
# cleanup
    } else if (method == 'close') {
      f.text->delete('start', 'end');
      f.text->insert('flagger closed', 'start');
    } else {
      f.text->delete('start', 'end');
      f.text->insert(public.state(), 'start');
    };
    return T;
  };

  const public.type := function() {return "flagger";}

# Reset the flagger

  public.reset();

  public.priv := ref private;
  return ref public;
}

flaggertest := function() {

  include 'imager.g'

  global dowait := T;
  ntest := 0;
  results := [=];
  
  testdir := 'flaggertest/';
  
  note('Cleaning up directory ', testdir);
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); };
  
  # Make the directory
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw("rm fails!") }
  ok := shell(paste("mkdir", testdir));
  if (ok::status) { throw("mkdir", testdir, "fails!") }
  
  # Make the data
  msfile := spaste(testdir, '3C273XC1.ms');
  
  # Make the measurementSet
  imagermaketestms(msfile);
  
  ############################################################################
  
  global myflagger := flagger(msfile);
  if (is_fail(myflagger)) fail;
  
  checkresult := function(ok, ntest, nametest, ref results) {
    
    results[ntest] := '';
    
    if (is_fail(ok)) {
      results[ntest] := paste("Test", ntest, " on ", nametest, "failed ",
			      ok::message);
    } else if (is_boolean(ok)) {
      if (!ok) results[ntest] := paste("Test", ntest, " on ", nametest,
				      "failed ", ok::message);
    } else {
      results[ntest] := paste("Test", ntest, " on ", nametest, "returned", ok);
    };
  };
  
  ############################################################################
  
  nametest := 'auto';
  note('### Test flagger.auto ###');
      
  ntest +:= 1;
  ok := myflagger.auto(trial=F);
  checkresult(ok, ntest, nametest, results);
};










