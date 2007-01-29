# newsimulator.g: Make images from AIPS++ MeasurementSets
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#   $Id: newsimulator.g,v 19.14 2006/04/04 02:05:47 mvoronko Exp $
#

pragma include once
    
    include "componentlist.g"
    include "measures.g"
    include "imager.g"
    include "image.g"
    include "ms.g"
    include "servers.g"
    include "widgetserver.g"
    include "note.g"
    
#defaultservers.suspend(T)
#defaultservers.trace(T)

# Users aren't to use this.
    const _define_newsimulator := function(ref agent, id) {
      self := [=]
	  public := [=]
	      private := [=]
		  
		  self.agent := ref agent;
      self.id := id;
      private.pgplotter := F;
      
      const self.updatewarning := function() {
	note('The operation of newsimulator has changed in a number of ways that may affect', priority='warn');
	note('your work. The row argument in setfield and setspwindow is no longer needed.', priority='warn');
	note('Please see the help file for more details', priority='warn');
      }
      
### group('basic')
      
      const public.done := function()
      {
        wider self, public, private;
        ok := defaultservers.done(self.agent, public.id());
	if(is_record(private.pgplotter)) {
	  private.pgplotter.done();
	  private.pgplotter := F;
	}
        if (ok) {
	  self := F;
	  val public := F;
        }
        return ok;
      }
      
      const public.close := function()
      {
        return public.done();
      }
      
      const public.id := function() {
	wider self;
	return self.id.objectid;
      }
      
      self.nameRec := [_method="name", _sequence=self.id._sequence]
	  const public.name := function() {
	    wider self;
	    return defaultservers.run(self.agent, self.nameRec);
	  }
      
      self.summaryRec := [_method="summary", _sequence=self.id._sequence]
	  const public.summary:=function() {
	    wider self;
	    return defaultservers.run(self.agent, self.summaryRec);
	  }
      
      self.stateRec := [_method="state", _sequence=self.id._sequence]
	  const public.state:=function() {
	    wider self;
	    return defaultservers.run(self.agent, self.stateRec);
	  }
      
      const public.type := function() {
	return 'newsimulator';
      }
      
      const public.updatestate := function(ref f, method) {
        if (method == 'INIT') {
	  tf:=dws.frame(f, side='left');
	  f.text := dws.text(tf);
	  vsb:=dws.scrollbar(tf);
	  whenever vsb->scroll do f.text->view($value);
	  whenever f.text->yscroll do vsb->view($value);
	  f.text->insert(public.state(), 'end');
        } else if (method == 'DONE') {
	  f.text := F; # cleanup
        } else if (method == 'close') {
	  f.text->delete('start', 'end');
	  f.text->insert('newsimulator closed', 'start');
        } else {
	  f.text->delete('start', 'end');
	  f.text->insert(public.state(), 'start');
        }
        return T;
      }
      
      
### group('create')
      self.setconfigRec := [_method="setconfig", _sequence=self.id._sequence]
	  const public.setconfig:=function(telescopename='VLA',
					   x=[], y=[], z=[],
					   dishdiameter=[],
					   offset=[],
					   mount=[],
					   antname=[],
					   coordsystem='global',
					   referencelocation=F) {
	    wider self;
	    include 'measures.g';
	    if(is_boolean(referencelocation)) {
	      referencelocation:=dm.observatory('VLA');
	    }
	    if (len(mount) == 1) {
	      oldmount := mount[1];
	      mount := array(oldmount, len(x));
	    }
	    if (len(antname) == 1) {
	      oldname := antname;
	      antname := array( oldname, len(x));
	      for (i in [1:len(x)]) {
		antname[i] := spaste(oldname, i);
	      }
	    }
	    self.setconfigRec.telescopename:=telescopename;
	    self.setconfigRec.x:=x;
	    self.setconfigRec.y:=y;
	    self.setconfigRec.z:=z;
	    self.setconfigRec.dishdiameter:=dishdiameter;
	    self.setconfigRec.mount:=mount;
	    self.setconfigRec.offset:=offset;
	    self.setconfigRec.antname:=antname;
	    self.setconfigRec.coordsystem:=coordsystem;
	    self.setconfigRec.referencelocation:=referencelocation;
	    return defaultservers.run(self.agent, self.setconfigRec);
	  }
      
      const public.setknownconfig:=function(arrayname='VLAA') {
        wider self;
        include 'newsimhelper.g';
	nsh:=newsimhelper();
        rec:=nsh.getarray(arrayname);
        if(is_fail(rec)) fail;
	nsh.done();
	return public.setconfig(telescopename=rec.telescope,
				x=rec.x, y=rec.y, z=rec.z,
				dishdiameter=rec.diam,
				offset=rec.offset,
				mount=rec.mount,
				antname=rec.names,
				coordsystem='global');
      }

#############################################################################      
# setmosaicfield 
# set field parameters for mosiac
# (rectangular mosaic patterns)
# The mosaic pattern is centered around fieldcenter
#
      const public.setmosaicfield := function (
                        sourcename='unknown', calcode='', 
                        fieldcenter=F,
                        xmosp=1, ymosp=1, 
                        mosspacing='1.0arcsec', 
                        distance='0km') {
        wider self;
         
        include 'measures.g';
        if(is_boolean(fieldcenter)) {
          fieldcenter:=dm.direction('j2000', '0deg', '90deg');
        }
        nx := xmosp;
        ny := ymosp;          
        roffsetq := dq.convert(mosspacing, 'rad');
        roffset := roffsetq.value;
        dir0 := fieldcenter;
        
        k:=1;
        for (i in 1:nx) {
          for(j in 1:ny) {
            if((nx/2)!=floor(nx/2)) { # odd number of fields in x direction(ra)
              newraval := dir0.m0.value + (i-ceiling(nx/2))*roffset/cos(dir0.m1.value);
            }
            else {  # even case
              newraval := dir0.m0.value + ((i-ceiling(nx/2)) - 0.5)*roffset/cos(dir0.m1.value);
            }
            if((ny/2)!=floor(ny/2)) {
              newdecval := dir0.m1.value + (j-ceiling(ny/2))*roffset;
            }
            else {
              newdecval := dir0.m1.value + ((j-ceiling(ny/2)) - 0.5)*roffset;
            }
            if(newraval >2*pi) {
              newraval := newraval - 2*pi;
            }
            if(abs(newdecval) >pi/2) {
              if(newdecval<0) {
                 sign := -1;
              }
              else {
                 sign := 1;
              }
              newdecval :=  sign*(pi - abs(newdecval));
              newraval := abs(pi - newraval); 
            } 
            newdirra := dq.quantity(newraval, 'rad');
            newdirdec := dq.quantity(newdecval, 'rad');
            newdir := dm.direction(dir0.refer, newdirra, newdirdec);
  
            public.setfield(spaste(sourcename, '_', k), newdir, calcode); 
    
            k +:= 1;
          }
        }
      }

# -------------------------------------------------------------------
#      const public.setmosaicfield_hex := function (
#                        ) {
#        wider self;
#         
#        include 'measures.g';
#        if(is_boolean(fieldcntr)) {
#          fieldcntr:=dm.direction('j2000', '0deg', '90deg');
#        }
#       }
########################################################################
 
      const self.synthselect := function (synth='') {
#
	taql := synth;
	if (strlen(synth) > 0) {
	  # Check for '0-rel' or '0-REL'
	  zerorel := synth ~ m/0-REL/i;
	  if (zerorel) {
	    synth := synth ~ s/0-REL//gi;
	  } else {
	    # Check for '1-rel' or '1-REL'
	    synth := synth ~ s/1-REL//gi;
	    # Adjust all relevant MS/calibration indices by 1
	    synth := synth ~ s/ANTENNA1/(ANTENNA1+1)/gi;
	    synth := synth ~ s/ANTENNA2/(ANTENNA2+1)/gi;
	    synth := synth ~ s/FEED1/(FEED1+1)/gi;
	    synth := synth ~ s/FEED2/(FEED2+1)/gi;
	    synth := synth ~ s/ARRAY_ID/(ARRAY_ID+1)/gi;
	    synth := synth ~ s/CORRELATOR_ID/(CORRELATOR_ID+1)/gi;
	    synth := synth ~ s/FIELD_ID/(FIELD_ID+1)/gi;
	    synth := synth ~ s/OBSERVATION_ID/(OBSERVATION_ID+1)/gi;
	    synth := synth ~ s/PULSAR_ID/(PULSAR_ID+1)/gi;
	    # Temporary 10/2000; use DATA_DESC_ID directly for now
	    synth := synth ~ s/SPECTRAL_WINDOW_ID/(DATA_DESC_ID+1)/gi;
	    synth := synth ~ s/ANTENNA_ID/(ANTENNA_ID+1)/gi;
	    synth := synth ~ s/ORBIT_ID/(ORBIT_ID+1)/gi;
	    synth := synth ~ s/PHASED_ARRAY_ID/(PHASED_ARRAY_ID+1)/gi;
	    synth := synth ~ s/FEED_ID/(FEED_ID+1)/gi;
	    synth := synth ~ s/BEAM_ID/(BEAM_ID+1)/gi;
	    synth := synth ~ s/PHASED_FEED_ID/(PHASED_FEED_ID+1)/gi;
	    synth := synth ~ s/SOURCE_ID/(SOURCE_ID+1)/gi;
	    taql := synth;
	  };
	};
	return taql;
      };
      
#-----------------------------------------------------------------------------
# Private function to pre-process input selection strings
# 
      const self.validstring := function (inputstring) {
#
	outputstring := inputstring;
	# Guard against "" or " "
	if (shape(outputstring) == 0) {
	  outputstring:= ' ';
	} else {
	  # Convert Glish string arrays 
	  outputstring := paste (outputstring);
	  # Strip spurious start and end quotes (
	  outputstring := outputstring ~ s/^'(.*)'$/$1/;
	  outputstring := outputstring ~ s/^"(.*)"$/$1/;
	};
	return outputstring;
      };
      
      self.setdataRec := [_method="setdata", _sequence=self.id._sequence]
	  public.setdata:=function(spwid=[], fieldid=[], 
				   msselect = ' ', async=!dowait) {
	    wider self;
	    self.setdataRec.spwid:=spwid;
	    self.setdataRec.fieldid:=fieldid;
	    # Pre-process input select string and convert to TAQL
	    self.setdataRec.msselect:= self.synthselect (self.validstring(msselect));
	    return defaultservers.run(self.agent, self.setdataRec, async);
	  }
      
      self.setfieldRec := [_method="setfield", _sequence=self.id._sequence]
	  const public.setfield:=function(sourcename='unknown',
					  sourcedirection=F, calcode='',
					  distance='0km'){
	    wider self;
	    include 'measures.g';
	    if(is_boolean(sourcedirection)) {
	      sourcedirection:=dm.direction('j2000', '0deg', '90deg');
	    }
	    self.setfieldRec.sourcename:=sourcename;
	    self.setfieldRec.sourcedirection:=sourcedirection;
	    self.setfieldRec.calcode:=calcode;
	    self.setfieldRec.distance:=distance;
	    return defaultservers.run(self.agent, self.setfieldRec);
	  }
      
      self.setspwindowRec := [_method="setspwindow", _sequence=self.id._sequence]
	  const public.setspwindow:=function(spwname='XBAND',
					     freq='8.0GHz', deltafreq='50.0MHz',
					     freqresolution='50.0MHz',
					     nchannels=1,
					     stokes='RR LL') {
	    
	    wider self;
	    self.setspwindowRec.spwname:=spwname;
	    self.setspwindowRec.freq:=freq;
	    self.setspwindowRec.deltafreq:=deltafreq;
	    self.setspwindowRec.freqresolution:=freqresolution;
	    self.setspwindowRec.nchannels:=nchannels;
	    self.setspwindowRec.stokes:=stokes;
	    
	    return defaultservers.run(self.agent, self.setspwindowRec);
	  }
      
      
      self.setfeedRec := [_method="setfeed", _sequence=self.id._sequence]
	  const public.setfeed:=function(mode='perfect R L', x=[], y=[], pol=['']) {
	    
	    wider self;
	    self.setfeedRec.mode:=mode;
	    self.setfeedRec.x:=x;
	    self.setfeedRec.y:=y;
	    self.setfeedRec.pol:=pol;
	    
	    return defaultservers.run(self.agent, self.setfeedRec);
	  }
      
      self.settimesRec := [_method="settimes", _sequence=self.id._sequence]
	  const public.settimes:=function(integrationtime='10s', 
					  usehourangle=T,
					  referencetime=F) {
	    
	    wider self;
	    if (!has_field(referencetime, 'type') || referencetime.type!='epoch') {
	      note('Setting the reference time to right now '); 
	      referencetime := dm.epoch('utc', 'today');
	    }
	    self.settimesRec.integrationtime:=integrationtime;
	    self.settimesRec.usehourangle:=usehourangle;
	    self.settimesRec.referencetime:=referencetime;
	    
	    return defaultservers.run(self.agent, self.settimesRec);
	  }
      
      self.observeRec := [_method="observe", _sequence=self.id._sequence]
	  const public.observe:=function(sourcename, spwname,
					 starttime='0s',
					 stoptime='3600s') {
	    
	    wider self;
	    
	    self.observeRec.sourcename:=sourcename;
	    self.observeRec.spwname:=spwname;
	    self.observeRec.starttime:=starttime;
	    self.observeRec.stoptime:=stoptime;
	    return  defaultservers.run(self.agent, self.observeRec, async);
	  }
      
      
## group('predict')
      
      self.predictRec := [_method="predict", _sequence=self.id._sequence]
	  const public.predict:=function(modelimage='', complist='', 
					 incremental=F, async=!dowait) {
	    wider self;
	    self.predictRec.modelimage:=modelimage;
	    self.predictRec.complist:=complist;
	    self.predictRec.incremental:=incremental;
	    return defaultservers.run(self.agent, self.predictRec, async);
	  }
      
      self.setoptionsRec := [_method="setoptions", _sequence=self.id._sequence]
	  const public.setoptions:=function(ftmachine='gridft',
					    cache=0, tile=16,
					    gridfunction='SF',
					    location=F,
					    padding=1.3,
					    facets=1,
					    maxdata=2000,
					    wprojplanes=1) {
	    wider self;
	    if(is_boolean(location)) {
	      location:=dm.position('wgs84', '0m', '0m', '0m');
	    }
	    self.setoptionsRec.ftmachine:=ftmachine;
	    self.setoptionsRec.cache:=cache;
	    self.setoptionsRec.tile:=tile;
	    self.setoptionsRec.gridfunction:=gridfunction;
	    self.setoptionsRec.location:=location;
	    self.setoptionsRec.padding:=padding;
	    self.setoptionsRec.facets:=facets;
	    self.setoptionsRec.maxdata:=maxdata;
	    self.setoptionsRec.wprojplanes:=wprojplanes;
	    return defaultservers.run(self.agent, self.setoptionsRec);
	  }
      
      self.setvpRec := [_method="setvp", _sequence=self.id._sequence]
	  const public.setvp:=function(dovp=T, usedefaultvp=T, vptable='', 
				       dosquint=T,parangleinc='360deg',
				       pblimit=1e-2,skyposthreshold='180deg') {
	    wider self;
	    self.setvpRec.dovp:=dovp;
	    self.setvpRec.usedefaultvp:=usedefaultvp;
	    self.setvpRec.vptable:=vptable;
	    self.setvpRec.dosquint:=dosquint;
	    self.setvpRec.parangleinc:=parangleinc;
	    self.setvpRec.pblimit:=pblimit;
	    self.setvpRec.skyposthreshold:=skyposthreshold;
	    returnval := defaultservers.run(self.agent, self.setvpRec);
	    return returnval;
	  }
      
      self.setlimitsRec := [_method="setlimits", _sequence=self.id._sequence];
      const public.setlimits:=function(shadowlimit=1e-6, elevationlimit="8deg") {
        wider self;
        self.setlimitsRec.shadowlimit:=shadowlimit;
        self.setlimitsRec.elevationlimit:=elevationlimit;
        returnval := defaultservers.run(self.agent, self.setlimitsRec);
        return returnval;
      }
      
      self.setautoRec := [_method="setauto", _sequence=self.id._sequence];
      const public.setauto:=function(autocorrwt=1.0) {
        wider self;
        self.setautoRec.autocorrwt:=autocorrwt;
        returnval := defaultservers.run(self.agent, self.setautoRec);
        return returnval;
      }
      
### group('corrupt')
      
      self.corruptRec := [_method="corrupt", _sequence=self.id._sequence]
	  const public.corrupt:=function(async=!dowait) {
	    wider self;
	    return defaultservers.run(self.agent, self.corruptRec, async);
	  }
      
      self.resetRec := [_method="reset", _sequence=self.id._sequence]
	  const public.reset:=function(async=!dowait) {
	    wider self;
	    return defaultservers.run(self.agent, self.resetRec, async);
	  }
      
      self.setbandpassrec := [_method="setbandpass", _sequence=self.id._sequence]
	  const public.setbandpass:=function(mode='calculate', table='',
					     interval='1h', amplitude=[0., 0.]) {
	    wider self;
	    self.setbandpassrec.mode:=mode;
	    self.setbandpassrec.table:=table;
	    self.setbandpassrec.interval:=interval;
	    self.setbandpassrec.amplitude:=amplitude;
	    return defaultservers.run(self.agent, self.setbandpassrec);
	  }
      const public.setbandpasss:=function(mode='calculate', table='',
					  interval='1h', amplitude=[0., 0.]) {
        wider self, public;
        note('Change the spelling in your script: setbandpasss -> setbandpass','WARN')
	    note(' This misspelled function still works, but will disappear eventually.','WARN')
		return public.setbandpass(mode=mode,table=table,interval=interval,amplitude=amplitude);
      }
      
      self.setgainrec := [_method="setgain", _sequence=self.id._sequence]
	  const public.setgain:=function(mode='calculate', table='',
					 interval='10s', amplitude=[0., 0.]) {
	    wider self;
	    self.setgainrec.mode:=mode;
	    self.setgainrec.table:=table;
	    self.setgainrec.interval:=interval;
	    self.setgainrec.amplitude:=amplitude;
	    return defaultservers.run(self.agent, self.setgainrec);
	  }

      self.setpointingerror := [_method="setpointingerror", _sequence=self.id._sequence]
	  const public.setpointingerror:=function(table='',
						  dopointing=T,
						  dopbcorrection=F) {
	    wider self;
	    self.setpointingerrorrec.table:=table;
	    self.setpointingerrorrec.dopointing:=dopointing;
	    self.setpointingerrorrec.dopbcorrection:=dopbcorrection;

	    return defaultservers.run(self.agent, self.setpointingerrorrec);
	  }
      
      self.setleakagerec := [_method="setleakage", _sequence=self.id._sequence]
	  const public.setleakage:=function(mode='calculate', table='',
					    interval='5h', amplitude=0.0) {
	    wider self;
	    self.setleakagerec.mode:=mode;
	    self.setleakagerec.table:=table;
	    self.setleakagerec.interval:=interval;
	    self.setleakagerec.amplitude:=amplitude;
	    return defaultservers.run(self.agent, self.setleakagerec);
	  }
      
      self.setnoiseRec := [_method="setnoise", _sequence=self.id._sequence]
	  const public.setnoise:=function(mode='calculate', 
					  simplenoise='0.0Jy',
					  table='',
					  antefficiency=0.80,
					  correfficiency=0.85,
					  spillefficiency=0.85,
					  tau=0.0,
					  trx=50,
					  tatmos=250, 
					  tcmb=2.7) {
	    wider self;
	    self.setnoiseRec.mode:=mode;
	    self.setnoiseRec.simplenoise:=simplenoise;
	    self.setnoiseRec.table:=table;
	    self.setnoiseRec.antefficiency:=antefficiency;
	    self.setnoiseRec.correfficiency:=correfficiency;
	    self.setnoiseRec.spillefficiency:=spillefficiency;
	    self.setnoiseRec.tau:=tau;
	    self.setnoiseRec.trx:=trx;
	    self.setnoiseRec.tatmos:=tatmos;
	    self.setnoiseRec.tcmb:=tcmb;
	    
	    return defaultservers.run(self.agent, self.setnoiseRec);
	  }
      
      self.setparec := [_method="setpa", _sequence=self.id._sequence]
	  const public.setpa:=function(mode='calculate', table='',
				       interval='10s') {
	    wider self;
	    self.setparec.mode:=mode;
	    self.setparec.table:=table;
	    self.setparec.interval:=interval;
	    return defaultservers.run(self.agent, self.setparec);
	  }
      
      self.setseedrec := [_method="setseed", _sequence=self.id._sequence]
	  const public.setseed:=function(seed=185349251) {
	    wider self;
	    self.setseedrec.seed:=seed;
	    return defaultservers.run(self.agent, self.setseedrec);
	  }
      
      plugins.attach('newsimulator', public);
      
      return ref public;
      
    } # _define_newsimulator()


# Make a new server for every invocation
const newsimulator := function(msname='', host='', forcenewserver=T) {
  
  if(msname=='') return throw('newsimulator constructor now requires an argument - see the help file');
  agent := defaultservers.activate("newsimulator", host, forcenewserver)
      if(is_fail(agent)) fail;
  id := defaultservers.create(agent, "newsimulator", "newsimulator",
			      [msname=msname]);
  if(is_fail(id)) fail;
  return ref _define_newsimulator(agent,id);
} 

# Make a new server for every invocation
const newsimulatorfromms := function(thems, host='', forcenewserver=T) {
  agent := defaultservers.activate("newsimulator", host, forcenewserver);
  if(is_fail(agent)) fail;
  id := defaultservers.create(agent, "newsimulator", "newsimulatorfromms",
			      [thems=thems]);
  if(is_fail(id)) fail;
  return ref _define_newsimulator(agent,id);
} 

const newsimulatormaketestcl:=function(clfile='3C273XC1.sim.cl',
				       componentnumbers=1:4)
{
  cl := emptycomponentlist();
  # These components were generated by model-fitting a 
  # multiscale clean image of 3C273XC1.
  for (i in componentnumbers) {
    if (i > 0 && i < 5) {
      cl.simulate(1);
      which := cl.length();
      if (i == 1) {
        cl.setflux(which, [29.78746076, 0, 0, 0], 'Jy', 'Stokes');
        cl.setrefdir(which, -3.025728405, 'rad', 0.04064334331, 'rad');
        cl.setrefdirframe(which, 'B1950');
        cl.setshape(which, 'Point');
      } else if (i == 2) {
        cl.setflux(which, [2.106918751, 0, 0, 0], 'Jy', 'Stokes');
        cl.setrefdir(which, -3.025795714, 'rad', 0.04056873814, 'rad');
        cl.setrefdirframe(which, 'B1950');
        cl.setshape(which, 'Gaussian', '4.538851045arcsec',
                    '3.474921278arcsec', '0.8395555572rad');
      } else if (i == 3) {
        cl.setflux(which, [0.2837940904, 0, 0, 0], 'Jy', 'Stokes');
        cl.setrefdir(which, -3.025777641, 'rad', 0.04058890373, 'rad');
        cl.setrefdirframe(which, 'B1950');
        cl.setshape(which, 'Gaussian', '3.818249933arcsec',
                    '3.154879884arcsec', '0.5894236379rad');
      } else if (i == 4) {
        cl.setflux(which, [0.220546845, 0, 0, 0], 'Jy', 'Stokes');
        cl.setrefdir(which, -3.025797903, 'rad', 0.04056600744, 'rad');
        cl.setrefdirframe(which, 'B1950');
        cl.setshape(which, 'Gaussian', '1.317486112arcsec',
                    '1.257733114arcsec', '2.856273131rad');
      }
    }
  }
  cl.rename(clfile);
  cl.close();
  cl.done();
}


# This makes the same model components, but puts them at 
# ra = 0.0, dec = 0.04064334331
const newsimulatormaketestcl0:=function(clfile='Dummy.sim.cl',
					componentnumbers=1:4)
{
  cl := emptycomponentlist();
  # These components were generated by model-fitting a 
  # multiscale clean image of 3C273XC1.
  for (i in componentnumbers) {
    if (i > 0 && i < 5) {
      cl.simulate(1);
      which := cl.length();
      if (i == 1) {
        cl.setflux(which, [29.78746076, 0, 0, 0], 'Jy', 'Stokes');
        cl.setrefdir(which, 0.0, 'rad', 0.04064334331, 'rad');
        cl.setrefdirframe(which, 'B1950');
        cl.setshape(which, 'Point');
      } else if (i == 2) {
        cl.setflux(which, [2.106918751, 0, 0, 0], 'Jy', 'Stokes');
        cl.setrefdir(which, -6.7309e-05, 'rad', 0.04056873814, 'rad');
        cl.setrefdirframe(which, 'B1950');
        cl.setshape(which, 'Gaussian', '4.538851045arcsec',
                    '3.474921278arcsec', '0.8395555572rad');
      } else if (i == 3) {
        cl.setflux(which, [0.2837940904, 0, 0, 0], 'Jy', 'Stokes');
        cl.setrefdir(which, -4.9236e-05, 'rad', 0.04058890373, 'rad');
        cl.setrefdirframe(which, 'B1950');
        cl.setshape(which, 'Gaussian', '3.818249933arcsec',
                    '3.154879884arcsec', '0.5894236379rad');
      } else if (i == 4) {
        cl.setflux(which, [0.220546845, 0, 0, 0], 'Jy', 'Stokes');
        cl.setrefdir(which, -6.9498e-05, 'rad', 0.04056600744, 'rad');
        cl.setrefdirframe(which, 'B1950');
        cl.setshape(which, 'Gaussian', '1.317486112arcsec',
                    '1.257733114arcsec', '2.856273131rad');
      }
    }
  }
  cl.rename(clfile);
  cl.close();
  cl.done();
}

# simulate from model components
const newsimulatortest:=function(noise='0.01Jy') 
{
  testdir := 'newsimulatortest2';
  note('Cleaning up directory ', testdir);
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); }
  ok := shell(paste("mkdir", testdir))
  if (ok::status) { throw("mkdir", testdir, "fails!") }
  
  msname   := spaste(testdir, '/','NEW1.MS');
  clfile   := spaste(testdir, '/','Dummy.sim.cl');
  simdirty := spaste(testdir, '/','SIM.DIRTY');
  simpsf   := spaste(testdir, '/','SIM.PSF');
  simclean := spaste(testdir, '/','SIM.CLEAN');
  simrest  := spaste(testdir, '/','SIM.RESTORED');
  simresid := spaste(testdir, '/','SIM.RESID');
  
  note('Create the empty measurementset');
  
  mysim := newsimulator(msname);
  
  dir0 := dm.direction('b1950',  '0h0m0.0', '2d19m43.291332');
  mysim.setfield(sourcename='Test_A', sourcedirection=dir0);
  
  mysim.setknownconfig('VLAA');
  
  mysim.setspwindow(spwname='XBAND', freq='8.0GHz', deltafreq='50.0MHz',
		    freqresolution='50.0MHz', nchannels=1, stokes='RR RL LR LL');
  
  mysim.setlimits(shadowlimit=0.001, elevationlimit='8.0deg');
  mysim.setauto(autocorrwt=0.5);
  
  reftime := dm.epoch('utc', '51483.1877d');
  
  print mysim.settimes(integrationtime='1800s', usehourangle=F,
		 referencetime=reftime);
  
  print mysim.observe('Test_A', 'XBAND', starttime='0s', stoptime='15000s');

  print mysim.done();

  note('Make components');
  newsimulatormaketestcl0( clfile=clfile, componentnumbers=1:4);

  mysim := newsimulatorfromms(msname);

  mysim.predict(complist=clfile);
  
  note('Add noise');
  
  mysim.setnoise(mode='simplenoise', simplenoise=noise);
  mysim.corrupt();
  mysim.done();
  
  note('Now make the simulated multiscale clean image');
  
  
  include 'imager.g';
  myimager := imager(msname);
  myimager.setdata(mode="none" , nchan=1, start=1, step=1,
		   mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1);
  myimager.setimage(nx=256, ny=256, cellx="0.5arcsec" ,
		    celly="0.5arcsec" , stokes="I" , doshift=F,
		    shiftx="0arcsec" ,
		    shifty="0arcsec" , mode="mfs" , nchan=1, start=1, step=1,
		    mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1,
		    facets=1);
  myimager.weight(type="briggs" , robust=0);
  myimager.makeimage('observed', simdirty);
  myimager.makeimage('psf', simpsf);
  myimager.setscales(scalemethod='uservector', uservector=[0.0,3.0,10.0]);
  myimager.clean(algorithm='multiscale', niter=500, gain=0.7,
		 threshold='1mJy' , displayprogress=T,
		 model=simclean, image=simrest, residual=simresid);
  myimager.done();
  
  note(paste('The final deconvolved image is in ', simrest));
  
}

