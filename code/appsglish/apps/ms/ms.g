# ms.g: Manipulate AIPS++ MeasurementSets
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
#   $Id: ms.g,v 19.18 2005/11/24 00:50:12 kgolap Exp $
#

pragma include once;

include 'servers.g';
include 'unset.g';
include 'table.g';
include 'note.g';
include 'plugins.g';
    
#defaultservers.suspend(T)
#defaultservers.trace(T)

# Users aren't to use this.
const _define_ms := function(ref agent, id) {
  private := [=];
  public := [=];

  private.agent := ref agent;
  private.id := id;
  
  public := defaultservers.init_object(private);

  private.tofitsRec := [_method='tofits', _sequence=private.id._sequence];
  const public.tofits := function(fitsfile, column='CORRECTED', fieldid=[], 
				  spwid=[], start=-1, nchan=-1, width=-1, 
				  writesyscal=F,
				  multisource=F, combinespw=F, writestation=F) {
    wider private;
    private.tofitsRec.fitsfile := fitsfile;
    private.tofitsRec.column := column;
    private.tofitsRec.fieldid := fieldid; 
    private.tofitsRec.spwid := spwid;
    private.tofitsRec.start:= start-1;  # The c++ code take zero relative chan
    private.tofitsRec.nchan:=nchan;
    private.tofitsRec.width:=width;
    private.tofitsRec.writesyscal := writesyscal;
    private.tofitsRec.multisource := multisource;
    private.tofitsRec.combinespw  := combinespw;
    private.tofitsRec.writestation:= writestation;
    return defaultservers.run(private.agent, private.tofitsRec);
  }

  const public.tosdfits := function(fitsfile) {
    include 'ms2sdfits.g';
    converter := ms2sdfits();
    if (is_fail(converter) || !has_field(converter,'convert') || 
        !is_function(converter.convert)) {
      return throw('Start of ms2sdfits converter client failed');
    }
    result := converter.convert(fitsfile, public.name());
    if (!result) return throw('Execution of ms2sdfits.convert failed');
    converter.done();
    return result;
  }
  
  private.openRec := [_method='open', _sequence=private.id._sequence];
  const public.open := function(thems, readonly=T, lock=T) {
    wider private;
    private.openRec.thems := thems;
    private.openRec.readonly := readonly;
    private.openRec.lock := lock;
    return defaultservers.run(private.agent, private.openRec);
  }
  
  private.closeRec := [_method='close', _sequence=private.id._sequence];
  const public.close := function() {
    wider private;
    return defaultservers.run(private.agent, private.closeRec);
  }
  
  private.summaryRec := [_method='summary', _sequence=private.id._sequence];
  const public.summary:=function(verbose=F, ref header=[=]) {
    wider private;
    private.summaryRec.verbose:=verbose;
    returnval := defaultservers.run(private.agent, private.summaryRec);
    val header := private.summaryRec.header;
    return returnval;
  }
  
  private.listhistoryRec := [_method='listhistory', _sequence=private.id._sequence];
  const public.listhistory:=function() {
    return defaultservers.run(private.agent, private.listhistoryRec);
  }
  
  private.listerRec := [_method='lister', _sequence=private.id._sequence];
  public.lister := function(starttime, stoptime) {
    wider private;
    private.listerRec.starttime := starttime;
    private.listerRec.stoptime := stoptime;
    return defaultservers.run(private.agent, private.listerRec);
  }   

  private.writehistoryRec := [_method='writehistory', _sequence=private.id._sequence];
  public.writehistory:=function(message, parms='', origin='ms::writehistory()', msname='', app='ms') {
    wider private;
    private.writehistoryRec.message := message;
    private.writehistoryRec.parms   := parms;
    private.writehistoryRec.origin  := origin;
    private.writehistoryRec.msname  := msname;
    private.writehistoryRec.app     := app;
    return defaultservers.run(private.agent, private.writehistoryRec);
  }
  
  private.concatenateRec := [_method='concatenate',
			     _sequence=private.id._sequence];
  public.concatenate := function(msfile, freqtol='1Hz', dirtol='1mas') {
    wider private;
    private.concatenateRec.msfile := msfile;
    private.concatenateRec.freqtol := freqtol;
    private.concatenateRec.dirtol:= dirtol;
    return defaultservers.run(private.agent, private.concatenateRec);
  }   

  private.splitRec := [_method='split',
			     _sequence=private.id._sequence];

  public.split := function( outputms, fieldids=[-1], spwids=[-1], nchan=[-1], 
			   start=[1], step=[1], antennaids=[-1], 
			   antennanames=[''], timebin='0s', timerange='', 
			   whichcol='DATA'){

    if (!public.iswritable()) {
      note('MS tool is not writable',priority='WARN');
      note('Please done the MS tool, and restart with readonly=F',
	   priority='WARN');
      return F;
    }

    wider private;
    private.splitRec.outputms := outputms;
    private.splitRec.fieldids := fieldids;
    private.splitRec.spwids := spwids;
    private.splitRec.nchan := nchan;
    private.splitRec.start := start;
    private.splitRec.step := step;
    private.splitRec.antennaids := antennaids;
    private.splitRec.antennanames := antennanames;
    private.splitRec.timebin := timebin;
    private.splitRec.timerange := timerange;
    private.splitRec.whichcol := whichcol;
    
    return defaultservers.run(private.agent, private.splitRec);
    

  } 

  private.continuumsubRec := [_method='continuumsub',
			     _sequence=private.id._sequence];

  public.continuumsub := function(fldid=F, spwid=[], chans=[], 
			          solint=0.0,fitorder=0,mode='sub'){

# do some checking
    if (!public.iswritable()) {
      note('MS tool is not writable',priority='WARN');
      note('Please done the MS tool, and restart with readonly=F',
	   priority='WARN');
      return F;
    }

    t:=table(public.name(),ack=F);
    cols:=t.colnames();
    t.done();
    scrcols:=any(cols=='CORRECTED_DATA') && any(cols=='MODEL_DATA');
    if (!scrcols) {
      note('This MS has no scratch columns',priority='WARN');
      note('Please done the MS tool and start an imager or calibrater', priority='WARN');
      note('tool to add them; then try again.',priority='WARN');
      return F;
    }

    tmpmode:=as_string(mode);
    if (tmpmode ~ m/sub/) {
      tmpmode := "subtract";
    } else if (tmpmode ~ m/mod/) {
      tmpmode := "model";
    } else if (tmpmode ~ m/rep/) {
      tmpmode := "replace";
    } else {
       return throw ('Illegal value for mode parameter', origin='ms.continuumsub');
    }
    
    if (is_boolean(fldid)) {
      return throw('Please specify a field id.', origin='ms.continuumsub');
    };
    
    # assume all ddis:
    dditab:=table(spaste(public.name(),'/DATA_DESCRIPTION'),ack=F);  
    allspws:= dditab.getcol('SPECTRAL_WINDOW_ID')+1;
    nddi:=dditab.nrows();
    ddis:=seq(nddi);
    dditab.done();

    # if spwid specified, find out which subset of ddis:
    if (!is_boolean(spwid) && len(spwid)> 0) {
      ddimask:=array(F,nddi);
      for (ispw in [spwid]) {
        ddimask[allspws==ispw]:=T;
      }
      ddis:=ddis[ddimask];
    }
    nddi:=shape(ddis);

    if (nddi < 1) {
      return throw('Specified spwids not found in data.', origin='ms.continuumsub');
    }

    tmpchans:=chans;
    if (is_boolean(chans)) {
      tmpchans:=[];
    }
    wider private;
    private.continuumsubRec.fieldids := fldid;
    private.continuumsubRec.ddids := ddis;
    private.continuumsubRec.chans := tmpchans;
    private.continuumsubRec.solint := solint;
    private.continuumsubRec.fitorder := fitorder;
    private.continuumsubRec.mode := tmpmode;   
    return defaultservers.run(private.agent, private.continuumsubRec);    
  } 


  private.nameRec := [_method='name', _sequence=private.id._sequence];
  const public.name := function() {
    wider private;
    return defaultservers.run(private.agent, private.nameRec);
  }
  
  private.nrowRec := [_method='nrow', _sequence=private.id._sequence];
  const public.nrow := function(selected=F) {
    wider private;
    private.nrowRec.selected := selected;
    return defaultservers.run(private.agent, private.nrowRec);
  }
  
  private.iswritableRec := [_method='iswritable', _sequence=private.id._sequence];
  const public.iswritable := function() {
    wider private;
    return defaultservers.run(private.agent, private.iswritableRec);
  }
  
#  private.concatenateRec := [_method='concatenate',
#			     _sequence=private.id._sequence];
#  const public.concatenate := function(msfile) {
#    wider private;
#    private.concatenateRec.msfile := msfile;
#    return defaultservers.run(private.agent, private.concatenateRec);
#  }

  private.commandRec := [_method='command', _sequence=private.id._sequence];
  const public.command := function(msfile, command, readonly=T) {
    wider private;
    private.commandRec.msfile := msfile;
    private.commandRec.command := command;
    private.commandRec.readonly := readonly;
    id :=  defaultservers.run(private.agent, private.commandRec);
    id2 := defaultservers.add(private.agent, id);
    return _define_ms(private.agent, id2);
  }

  private.selectinitRec := [_method='selectinit',
			    _sequence=private.id._sequence];
  const public.selectinit := function (arrayid = unset, datadescid = 0, 
				       reset = F) {
    wider private;
    if (!is_unset(arrayid)) {
      note('The arrayid argument is no longer used\n', 
	   'and will be removed in a future release of aips++', 
	   priority='WARN', 
	   origin='ms.selectinit');
    }
    private.selectinitRec.datadescid := datadescid;
    private.selectinitRec.reset := reset;
    return defaultservers.run(private.agent, private.selectinitRec);
  }
  private.rangeRec := [_method='range', _sequence=private.id._sequence];
  const public.range := function (items, useflags = T, blocksize = 10) {
    wider private;
    private.rangeRec.items := items;
    private.rangeRec.useflags := useflags;
    private.rangeRec.blocksize := blocksize;
    private.rangeRec.returnval :=[=]; # empty out before call
    return defaultservers.run(private.agent, private.rangeRec);
  }
  private.selectRec := [_method='select', _sequence=private.id._sequence];
  const public.select := function (items) {
    wider private;
    private.selectRec.items := items;
    private.selectRec.returnval :=[=]; # empty out before call
    return defaultservers.run(private.agent, private.selectRec);
  }
  private.selecttaqlRec := [_method='selecttaql', _sequence=private.id._sequence];
  const public.selecttaql := function (msselect) {
    wider private;
    private.selecttaqlRec.msselect := msselect;
    private.selecttaqlRec.returnval :=[=]; # empty out before call
    return defaultservers.run(private.agent, private.selecttaqlRec);
  }
  private.getdataRec := [_method='getdata', _sequence=private.id._sequence];
  const public.getdata := function (items, ifraxis = F, ifraxisgap = 0,
                                    increment = 1, average = F) {
    wider private;
    private.getdataRec.items := items;
    private.getdataRec.ifraxis := ifraxis;
    private.getdataRec.ifraxisgap := ifraxisgap;
    private.getdataRec.increment := increment;
    private.getdataRec.average := average;
    private.getdataRec.returnval :=[=]; # empty out before call
    ok := defaultservers.run(private.agent, private.getdataRec);
    private.getdataRec.returnval :=[=]; # empty out after call as it may be big
    return ok;
  }
  private.putdataRec := [_method='putdata', _sequence=private.id._sequence];
  const public.putdata := function (items) {
    wider private;
    private.putdataRec.items := items;
    ok := defaultservers.run(private.agent, private.putdataRec);
    private.putdataRec.items := [=]; # empty out after call as it may be big
    return ok;
  }
  private.iterinitRec := [_method='iterinit', _sequence=private.id._sequence];
  const public.iterinit := function (columns,interval,maxrows=0,
				     adddefaultsortcolumns=T) {
    wider private;
    private.iterinitRec.columns:=columns;
    private.iterinitRec.interval:=interval;
    private.iterinitRec.maxrows:=maxrows;
    private.iterinitRec.adddefaultsortcolumns:=adddefaultsortcolumns;
    return defaultservers.run(private.agent, private.iterinitRec);
  }
  private.iteroriginRec := [_method='iterorigin',
			    _sequence=private.id._sequence];
  const public.iterorigin := function () {
    wider private;
    return defaultservers.run(private.agent, private.iteroriginRec);
  }
  private.iternextRec := [_method='iternext',
			  _sequence=private.id._sequence];
  const public.iternext := function () {
    wider private;
    return defaultservers.run(private.agent, private.iternextRec);
  }
  private.iterendRec := [_method='iterend',
			 _sequence=private.id._sequence];
  const public.iterend := function () {
    wider private;
    return defaultservers.run(private.agent, private.iterendRec);
  }
  private.selectchannelRec := [_method='selectchannel',
			       _sequence=private.id._sequence];
  const public.selectchannel := function (nchan,start,width,inc) {
    wider private;
    private.selectchannelRec.nchan:=nchan;
    private.selectchannelRec.start:=start;
    private.selectchannelRec.width:=width;
    private.selectchannelRec.inc:=inc;
    return defaultservers.run(private.agent, private.selectchannelRec);
  }
  private.selectpolarizationRec := [_method='selectpolarization', 
				    _sequence=private.id._sequence];
  const public.selectpolarization := function (wantedpol) {
    wider private;
    private.selectpolarizationRec.wantedpol:=wantedpol;
    return defaultservers.run(private.agent, private.selectpolarizationRec);
  }
  private.createflaghistoryRec := [_method='createflaghistory', 
				   _sequence=private.id._sequence];
  const public.createflaghistory := function (numlevel = 2) {
    wider private;
    private.createflaghistoryRec.numlevel:=numlevel;
    return defaultservers.run(private.agent, private.createflaghistoryRec);
  }
  private.saveflagsRec := [_method='saveflags',
			   _sequence=private.id._sequence];
  const public.saveflags := function (newlevel = F) {
    wider private;
    private.saveflagsRec.newlevel:=newlevel;
    return defaultservers.run(private.agent, private.saveflagsRec);
  }
  private.restoreflagsRec := [_method='restoreflags',
			      _sequence=private.id._sequence];
  const public.restoreflags := function (level = 0) {
    wider private;
    private.restoreflagsRec.level:=level;
    return defaultservers.run(private.agent, private.restoreflagsRec);
  }
  private.flaglevelRec := [_method='flaglevel',
			   _sequence=private.id._sequence];
  const public.flaglevel := function () {
    wider private;
    return defaultservers.run(private.agent, private.flaglevelRec);
  }
  private.fillbufferRec := [_method='fillbuffer',
			    _sequence=private.id._sequence];
  const public.fillbuffer := function (item, ifraxis = F) {
    wider private;
    private.fillbufferRec.item:=item;
    private.fillbufferRec.ifraxis:=ifraxis;
    return defaultservers.run(private.agent, private.fillbufferRec);
  }
  private.diffbufferRec := [_method='diffbuffer',
			    _sequence=private.id._sequence];
  const public.diffbuffer := function (direction, window, domedian = F) {
    wider private;
    private.diffbufferRec.direction:=direction;
    private.diffbufferRec.window:=window;
    private.diffbufferRec.domedian:=domedian;
    return defaultservers.run(private.agent, private.diffbufferRec);
  }
  private.getbufferRec := [_method='getbuffer',
			   _sequence=private.id._sequence];
  const public.getbuffer := function () {
    wider private;
    return defaultservers.run(private.agent, private.getbufferRec);
  }
  private.clipbufferRec := [_method='clipbuffer', 
			    _sequence=private.id._sequence];
  const public.clipbuffer := function (pixellevel, timelevel, channellevel) {
    wider private;
    private.clipbufferRec.pixellevel:=pixellevel;
    private.clipbufferRec.timelevel:=timelevel;
    private.clipbufferRec.channellevel:=channellevel;
    return defaultservers.run(private.agent, private.clipbufferRec);
  }
  private.setbufferflagsRec := [_method='setbufferflags',
				_sequence=private.id._sequence];
  const public.setbufferflags := function (flags) {
    wider private;
    private.setbufferflagsRec.flags:=flags;
    return defaultservers.run(private.agent, private.setbufferflagsRec);
  }
  private.writebufferflagsRec := [_method='writebufferflags',
				  _sequence=private.id._sequence];
  const public.writebufferflags := function () {
    wider private;
    return defaultservers.run(private.agent, private.writebufferflagsRec);
  }
  private.clearbufferRec := [_method='clearbuffer',
			     _sequence=private.id._sequence];
  const public.clearbuffer := function () {
    wider private;
    return defaultservers.run(private.agent, private.clearbufferRec);
  }

# use new C++ version
  const public.uvlsf := ref public.continuumsub

#
  const public.olduvlsf := function (fldid=F, spwid=F,
                                  chans=F, solint=0.0,
                                  fitorder=0, mode='sub') {   

    if (!public.iswritable()) {
      note('MS tool is not writable',priority='WARN');
      note('Please done the MS tool, and restart with readonly=F',priority='WARN')
      return F;
    }

    t:=table(public.name(),ack=F);
    cols:=t.colnames();
    t.done();
    scrcols:=any(cols=='CORRECTED_DATA') && any(cols=='MODEL_DATA');
    if (!scrcols) {
      note('This MS has no scratch columns',priority='WARN');
      note('Please done the MS tool and start an imager or calibrater', priority='WARN');
      note('tool to add them; then try again.',priority='WARN');
      return F;
    }

# CHeck mode

    local self:=[=];
    self.mode:=as_string(mode);
    if (! (self.mode ~ m/sub/ || 
           self.mode ~ m/mod/ ||
           self.mode ~ m/rep/) ) {
       return throw ('Illegal value for mode parameter', origin='ms.uvlsf');
    }

    include 'fitting.g'
    include 'pgplotter.g'
    include 'mathematics.g'

    if (is_boolean(fldid)) {
      return throw('Please specify a field id.');
    };
    self.fldid:=fldid;

    # Can procede by default from here

    self.fchans:=chans;

    # assume all ddis
    self.spwid:=spwid;
    # if spwid specified, find out which subset of ddis:
    t:=table(spaste(public.name(),'/DATA_DESCRIPTION'),ack=F);  
    allspws:= t.getcol('SPECTRAL_WINDOW_ID')+1;
    self.nddi:=shape(allspws);
    self.ddis:=seq(self.nddi);
    t.done();
    if (!is_boolean(self.spwid)) {
      ddimask:=array(F,self.nddi);
      for (ispw in [self.spwid]) {
        ddimask[allspws==ispw]:=T;
      };
      self.ddis:=self.ddis[ddimask];
      self.nddi:=shape(self.ddis);
    };

    self.order:=fitorder;
    self.solint:=solint;
    self.coherent:=T;   # for now, force coherent
    
    # Loop over DDIs:
    for (iddi in [self.ddis]) {
      public.selectinit(datadescid=iddi)

      self.nchan:=public.range("num_chan").num_chan;
      self.polname:=public.range("corr_names").corr_names;

      if (is_boolean(self.fchans)) {
        self.fchans:=seq(self.nchan);
      };

      # channels and mask for this ddi:
      channels:=seq(self.nchan);
      chmask:=array(F,self.nchan);
      chmask[self.fchans]:=T;

      # select only parallel hands (ok?)
      polsel := m/(RR|LL|XX|YY)+/
      pols := self.polname[,1][self.polname[,1] ~ polsel];

      npol:=shape(pols)

      ok:=(npol > 0);

      staql:=spaste('(FIELD_ID+1) IN ',   as_evalstr(self.fldid), ' && ',
                    'ANTENNA1!=ANTENNA2');
      ok:=ok & public.selecttaql(msselect=staql);

      # only continue if there is data to process.
      if (ok) {
        public.selectpolarization(pols);
        public.iterinit(columns="ARRAY_ID SCAN_NUMBER FIELD_ID DATA_DESC_ID TIME",
                         interval=self.solint,adddefaultsortcolumns=F);
        public.iterorigin();

        iter:=1;
        while (public.iternext()) {
          iter+:=1;
        };
        print 'There are ',iter,' slots to process.';

        public.iterorigin();
        iter:=0;
        done:=F;
        while (!done) { 
          iter:=iter+1;

          # get averaged and unaveraged data and bookkeeping info
          recave:=public.getdata("corrected_data",ifraxis=T,average=T);
          rec:=public.getdata("model_data corrected_data",ifraxis=T,average=F);
          recbk:=public.getdata("time ifr_number axis_info",ifraxis=T,average=F);

          ntime:=shape(recbk.time);
          nifr:=shape(recbk.ifr_number);

          x:= ref self.fchans;    
	  fctnl:=dfs.poly(self.order);
          printf('Slot=%3i: ',iter);
          for (iifr in [1:nifr]) {
            if (iifr%as_integer(nifr/10)==1) printf('%2i%%..',as_integer(100*iifr/nifr));

            for (ipol in [1:npol]) {
              y:=[=];
              sol:=[=];

              if (self.coherent) {
                # A is real part, B is imag part
                y['A']:=real(recave.corrected_data[ipol,chmask,iifr]);
                y['B']:=imag(recave.corrected_data[ipol,chmask,iifr]);
              } else {
                # A in amplitude, B is phase
                y['A']:=abs(recave.corrected_data[ipol,chmask,iifr]);
                y['B']:=arg(recave.corrected_data[ipol,chmask,iifr]);
              };
              for (part in "A B") {

# 040909 (gmoellen) : fitpoly() is currently broken, use functional()
#                     for now
#                ok:=dfit.fitpoly(self.order,x,y[part]);   # not fast but fastest option
                dfit.functional(fctnl,x,y[part]);    # slow
#                dfit.fitspoly(self.order,x,y[part]);              # very slow!

                sol[part]:=dfit.solution();
              };
              y:=[=];

              if (self.coherent) {
                rp:=array(0.0,len(channels));
                ip:=array(0.0,len(channels));
                for (i in [(self.order+1):1]) {
                  rp:=(rp*channels)+sol['A'][i];
                  ip:=(ip*channels)+sol['B'][i];
                };
                ymodel:=complex(rp,ip);
              } else {
                amp:=array(0.0,len(channels));
                pha:=array(0.0,len(channels));
                for (i in [(self.order+1):1]) {
                  amp:=(amp*channels)+sol['A'][i];
                  pha:=(pha*channels)+sol['B'][i];
                };
                ymodel:=amp*complex(cos(pha),sin(pha));
              };

              for (itime in [1:ntime]) {
                if (self.mode ~ m/(mod|sub)/i) {rec.model_data[ipol,,iifr,itime]:=ymodel;};
                if (self.mode ~ m/rep/i) {rec.corrected_data[ipol,,iifr,itime]:=ymodel;};
                if (self.mode ~ m/sub/i) {rec.corrected_data[ipol,,iifr,itime]-:=ymodel;};
              };

              ymodel:=[=];

            };  # npol
          };  # nifr
          printf('done.\n');

	  rec.corrected_data := as_complex(rec.corrected_data);
	  rec.model_data := as_complex(rec.model_data);

          public.putdata(rec);
          rec:=[=];
          recave:=[=];
          recbk:=[=];

          done:=!public.iternext();
        };
        public.iterend();
      };
    };
    self:=[=];
    return T;
  };

  const public.ptsrc := function (fldid=[], spwid=[]) {

    wider private, public;
  
    local self:=[=];

    self.fldid:=fldid;
    # check user-specified fields
    fldtab:=table(spaste(public.name(),'/FIELD'),ack=F);
    self.allflds:=seq(fldtab.nrows())[!fldtab.getcol('FLAG_ROW')];
    fldtab.done();
    # if fields specified, match with fields in data
    taql:=F;
    if (len(self.fldid) > 0) {
      fldmask:=array(F,shape(self.allflds));
      for (ifld in [1:shape(self.allflds)]) {
        fldmask[ifld]:=any(self.fldid==self.allflds[ifld]);
      }
      # exit if not found
      if (sum(fldmask) < 1) {
         return throw('Specified fldid not found in data.');
      }
      self.fldid:=self.allflds[fldmask];
      taql:=spaste('( (FIELD_ID+1) IN ',as_evalstr(self.fldid),' )');
    } else {
      self.fldid:=self.allflds;
    }
    self.nfld:=shape(self.fldid);

    # Initialize selection
#    public.selectinit();

    self.spwid:=spwid;
    # assume all ddis:
    dditab:=table(spaste(public.name(),'/DATA_DESCRIPTION'),ack=F);  
    self.allspws:= dditab.getcol('SPECTRAL_WINDOW_ID')+1;
    self.nddi:=dditab.nrows();
    self.ddis:=seq(self.nddi);
    dditab.done();

    # if spwid specified, find out which subset of ddis:
    if (len(self.spwid)> 0) {
      ddimask:=array(F,self.nddi);
      for (ispw in [self.spwid]) {
        ddimask[self.allspws==ispw]:=T;
      }
      self.ddis:=self.ddis[ddimask];
    } else {
      self.spwid:=self.allspws;
    }
    self.nddi:=shape(self.ddis);

    if (self.nddi < 1) {
      return throw('Specified spwid not found in data.');
    }

    # all looks ok at this point
    note(paste('Processing fldids: ',self.fldid));
    note(paste('Processing spwids: ',self.spwid));

    # will store iquv results here
    self.iquv:=array(0.0,4,self.nddi,self.nfld);
    self.ok:=array(F,4,self.nddi,self.nfld);

    # check if CORRECTED_DATA column is present
    mstab:=table(public.name(),ack=F);
    self.cald:=any(mstab.colnames() ~ m/CORRECTED_DATA/);
    mstab.done();
    self.gditems:="corrected_data field_id axis_info"
    if (!self.cald) {
      self.gditems:="data field_id axis_info"
      note('Using DATA column, which may not be calibrated.',priority='WARN');
    }

    # form complete taql:
    if (!is_boolean(taql)) {
      taql:=spaste(taql,' && (ANTENNA1 != ANTENNA2)');
    } else {
      taql:=spaste('(ANTENNA1 != ANTENNA2)');
    };

    # loop over ddis
    outpols:=array('I Q U V',self.nddi);
    for (iddi in 1:self.nddi) {

      public.selectinit(datadescid=self.ddis[iddi]);


      # only extract flux densities if data found in selection
      if (public.selecttaql(taql)) {

       # average all channels (for now)
       nchan:=public.range("num_chan").num_chan;
       public.selectchannel(nchan=1,start=1,width=nchan,inc=1)

       # If there is only one native polarization, just get it,
       #  otherwise, select full Stokes
       obspols:=public.getdata('axis_info',average=T,ifraxis=F).axis_info.corr_axis;
       if (len(obspols)==1) {
         outpols[iddi]:=obspols;
       };
       public.selectpolarization(split(outpols[iddi]));

       # iterate over fields, storing averaged flux densities
       public.iterinit(columns="FIELD_ID",interval=0.0,adddefaultsortcolumns=F);
       public.iterorigin();
       done:=F;
       while (!done) {
         data:=public.getdata(items=self.gditems,ifraxis=F,average=T); 
         thisfld:=unique(data.field_id);
         ifld:=ind(self.fldid)[self.fldid==thisfld];
         self.ok[[1:len(split(outpols[iddi]))],iddi,ifld]:=T;
         if (self.cald) {
           self.iquv[,iddi,ifld][self.ok[,iddi,ifld]]:=real(data.corrected_data[,1]);
         } else {
           self.iquv[,iddi,ifld][self.ok[,iddi,ifld]]:=real(data.data[,1]);
         };      
         done:=!public.iternext();
       };    
       public.iterend();
      };
    };

    for (ifld in 1:self.nfld) {
      for (iddi in 1:self.nddi) {
       if (any(self.ok[,iddi,ifld])) {
        note(spaste('FieldID=',self.fldid[ifld],
                    ', SpwID=',self.spwid[iddi],
                    ': ',outpols[iddi],'= ',as_evalstr(self.iquv[,iddi,ifld][self.ok[,iddi,ifld]])));
        if (len(split(outpols[iddi]))>2) {
          m:=100*sqrt(self.iquv[2,iddi,ifld]^2 + self.iquv[3,iddi,ifld]^2)/self.iquv[1,iddi,ifld];
          x:=atan(self.iquv[3,iddi,ifld]/self.iquv[2,iddi,ifld])*180/pi;
          if (self.iquv[2,iddi,ifld] < 0.0) {
            if (self.iquv[3,iddi,ifld] < 0.0) {
              x-:=180.0;
            } else {
              x+:=180.0;
            };
          };
          x:=x/2;
          note(spaste('        ',' ',
                      '        ',' ',
                      '  FPol= ',m,'%,   ','P.A.= ',x,'deg'));
        };
       };
      };
    };
    if (self.nfld*self.nddi==1) {
      iquv:=self.iquv[,1,1][self.ok[,1,1]];
      self:=[=];
      return iquv;
    } else {
      self:=[=];
      return T;
    };
  };


  const public.done := function() { 
    wider private, public; 

    ok := defaultservers.done(private.agent, private.id.objectid);
    if (ok) { 
      private := F; 
      val public := F; 
    }
    return ok; 
  }   
  
  const public.type := function() {
    return 'ms';
  }
  
  plugins.attach('ms', public);
  
  return ref public;
} # _define_ms()


const ms := function(filename, readonly=T, lock=F, host='', forcenewserver=F) {
  agent := defaultservers.activate('ms', host, forcenewserver);
  id := defaultservers.create(agent, 'ms', 'ms',
			      [thems=filename, readonly=readonly, lock=lock]);
  return _define_ms(agent,id);
  
} # ms()

const fitstoms := function(msfile, fitsfile, whichhdu=1, readonly=T, lock=F,
			   obstype=0, host='', forcenewserver=F) {
  agent := defaultservers.activate('ms', host, forcenewserver);
  id := defaultservers.create(agent, 'ms', 'fitstoms',
			      [msfile=msfile, readonly=readonly, lock=lock, 
			       obstype=obstype, fitsfile=fitsfile]);
  return _define_ms(agent,id);
} # fitstoms()

const sdfitstoms := function(msfile, fitsfile, readonly=T, lock=F,
			     host='', forcenewserver=F) {
  include 'sdfits2ms.g';
  converter := sdfits2ms();
  if (is_fail(converter) || !has_field(converter,'convert') || 
      !is_function(converter.convert)) {
    return throw('Start of sdfits2ms converter client failed');
  }
  result := converter.convert(msfile, fitsfile);
  if (!result) return throw('Execution of sdfits2ms.convert failed');
  converter.done();
  return ms(msfile, readonly=readonly, lock=lock, host=host, 
	    forcenewserver=forcenewserver);
} # sdfitstoms()

const is_ms := function(tool) {
  return is_record(tool) && has_field(tool, 'type') && 
    is_function(tool.type) && tool.type() == 'ms';
}

const msfiles := function(files='.', strippath=T)
{
   include 'catalog.g';
   if (!serverexists('dc', 'catalog', dc)) {
      return throw('The catalog server "dc" is not running',
                    origin='imagefiles');
   }
#   
   local types;
   types := ['Measurement Set'];
   return dc.list(listtypes=types, files=files, strippath=strippath);
}


const msdemo := function() {
  fail "Not yet implemented";
}

const mstest := function() {
  local testdir := 'mstest';
  local timeout := 10;
  note('This test will create files in a subdirectory, called ',testdir,',\n',
       'of the current directory. This directory will be created and then\n',
       'deleted by this function. If you have files in this directory\n',
       'hit ^C within the next ', timeout, 
       ' seconds to prevent them being clobbered!', 
       origin='mstest', priority='WARN');
  include 'timer.g';
  timer.wait(timeout);
  include 'os.g';
  if (dos.fileexists(testdir)) {
    note('Cleaning up the test directory ', origin='mstest');
    if (is_fail(dos.remove(testdir))) fail;
  } else {
    note('Creating the test directory ', origin='mstest');
  }
  if (is_fail(dos.mkdir(testdir))) fail;

  note('Testing the ms (measurement set) tool', origin='mstest');
  local testms := F;
  include 'sysinfo.g';
  local aipsroot := sysinfo().root();
  local testfits := spaste(aipsroot, '/data/demo/3C273XC1.fits');
  local msfile := spaste(testdir, '/3C273XC1.ms');
  {
    local test := 'Test 1: Tool construction from UVFITS:\t\t';
    testms := fitstoms(msfile, testfits, readonly=F);
    if (is_fail(testms) | !is_record(testms)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not convert a demo UVFITS file to an ms');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='mstest');
  }
  {
    local test := 'Test 2: Tool manipulation functions:\t\t';
    local ok := testms.close();
    if (is_fail(ok) | !is_boolean(ok) | ok != T) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould close the testms tool');
      fail test;
    }
    local ok := testms.open(msfile, readonly = T, lock=T);
    if (is_fail(ok) | !is_boolean(ok) | ok != T) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not open a measurement set using the ',
 		    'testms tool');
      fail test;
    }
    local ok := testms.done();
    if (is_fail(ok) | !is_boolean(ok) | ok != T) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not shut down the ms server');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='mstest');
  }
  {
    local test := 'Test 3: Tool construction from a table\t\t';
    testms := ms(msfile, readonly=F, lock=F);
    if (is_fail(testms) | !is_record(testms)) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not create the ms tool from a table');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='mstest');
  }
  {
    local test := 'Test 4: Basic table properties\t\t\t';
    local ok := testms.name();
    if (is_fail(ok) | !is_string(ok) | ok != msfile) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get the table name');
      fail test;
    }
    local ok := testms.nrow();
    if (is_fail(ok) | !is_numeric(ok) | ok != 7669) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get the table name');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='mstest');
  }
  {
    local test := 'Test 5: Summary\t\t\t\t\t';
    local rec := [=];
    local ok := testms.summary(verbose=F,header=rec);
    if (is_fail(ok) | !is_boolean(ok) | ok != T | 
	!is_record(rec) | all(field_names(rec) != "name nrow")) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a brief summary');
      fail test;
    }
    rec := [=];
    local ok := testms.summary(verbose=T,header=rec);
    if (is_fail(ok) | !is_boolean(ok) | ok != T | 
	!is_record(rec) | all(field_names(rec) != "name nrow")) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not get a full summary');
      fail test;
    }
    test := paste(test, '\tOK');
    note(test, origin='mstest');
  }
  {
    local test := 'Test 6: Conversion to UVFITS\t\t\t';
    local convfitsfile := spaste(testdir, '/msto3C273XC1.fits')
    local ok := testms.tofits(convfitsfile, column='DATA');
    if (is_fail(ok) | !is_boolean(ok) | ok != T) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not convert the ms to UVFITS');
      fail test;
    }
    local convmsfile := spaste(testdir, '/msto3C273XC1.ms');
    convms := fitstoms(convmsfile, convfitsfile, readonly=F);
    if (is_fail(convms) | !is_record(convms) | convms.nrow() != 7669) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not verify that the UVFITS file is OK');
      fail test;
    }
    convms.done(); 
    dos.remove(convfitsfile);
    dos.remove(convmsfile);
    test := paste(test, '\tOK');
    note(test, origin='mstest');
  }
  {
    local test := 'Test 7: The command function\t\t\t';
    local submsfile := spaste(testdir, '/3C273XC1.subms');
    local ok := testms.command(submsfile, command='ANTENNA1 == 1', readonly=T);
    if (is_fail(ok) | !is_record(ok) | ok.nrow() != 544) {
      test := paste(test, '\tFAILED');
      test := paste(test, '\nCould not generate a sub-ms with ANTENNA1 == 1');
      fail test;
    }
    ok.done()
    test := paste(test, '\tOK');
    note(test, origin='mstest');
  }
  testms.done()
  return T;
}
