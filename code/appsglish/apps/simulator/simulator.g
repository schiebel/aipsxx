# simulator.g: Make images from AIPS++ MeasurementSets
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
#   $Id: simulator.g,v 19.2 2004/08/25 01:52:48 cvsmgr Exp $
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
const _define_simulator := function(ref agent, id) {
    self := [=]
    public := [=]
    private := [=]

    self.agent := ref agent;
    self.id := id;
    private.pgplotter := F;


### group('basic')

    self.closeRec := [_method="close", _sequence=self.id._sequence]
    const public.close := function() {
	wider self;
        return defaultservers.run(self.agent, self.closeRec);
    }

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

    const public.id := function() {
	wider self;
	return self.id.objectid;
    }

    self.nameRec := [_method="name", _sequence=self.id._sequence]
    const public.name := function() {
	wider self;
        return defaultservers.run(self.agent, self.nameRec);
    }

    self.openRec := [_method="open", _sequence=self.id._sequence]
    const public.open := function(thems) {
	wider self;
	self.openRec.thems := thems;
        return defaultservers.run(self.agent, self.openRec);
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
      return 'simulator';
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
            f.text->insert('simulator closed', 'start');
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
	self.setconfigRec.antname:=antname;
	self.setconfigRec.coordsystem:=coordsystem;
	self.setconfigRec.referencelocation:=referencelocation;
	return defaultservers.run(self.agent, self.setconfigRec);
    }


    self.setfieldRec := [_method="setfield", _sequence=self.id._sequence]
	const public.setfield:=function(row=1, sourcename='unknown',
				sourcedirection=F, integrations=1,
				xmospointings=1, ymospointings=1,
				mosspacing=1.0, distance="0m") {
        wider self;
        include 'measures.g';
        if(is_boolean(sourcedirection)) {
          sourcedirection:=dm.direction('b1950', '0deg', '90deg');
        }
	self.setfieldRec.row:=row;
	self.setfieldRec.sourcename:=sourcename;
	self.setfieldRec.sourcedirection:=sourcedirection;
	self.setfieldRec.integrations:=integrations;
	self.setfieldRec.xmospointings:=xmospointings;
	self.setfieldRec.ymospointings:=ymospointings;
	self.setfieldRec.mosspacing:=mosspacing;
	self.setfieldRec.distance:=distance;
	return defaultservers.run(self.agent, self.setfieldRec);
    }

    self.setspwindowRec := [_method="setspwindow", _sequence=self.id._sequence]
	const public.setspwindow:=function(row=1, spwname='XBAND',
				freq='8.0GHz', deltafreq='50.0MHz',
 				freqresolution='50.0MHz',
				nchannels=1,
				stokes='RR LL') {

        wider self;
	self.setspwindowRec.row:=row;
	self.setspwindowRec.spwname:=spwname;
	self.setspwindowRec.freq:=freq;
	self.setspwindowRec.deltafreq:=deltafreq;
	self.setspwindowRec.freqresolution:=freqresolution;
	self.setspwindowRec.nchannels:=nchannels;
	self.setspwindowRec.stokes:=stokes;

	return defaultservers.run(self.agent, self.setspwindowRec);
    }


    self.setfeedRec := [_method="setfeed", _sequence=self.id._sequence]
	const public.setfeed:=function(mode='perfect R L') {

        wider self;
	self.setfeedRec.mode:=mode;
	#  more options in the future for specifying invented feeds

	return defaultservers.run(self.agent, self.setfeedRec);
    }

    self.settimesRec := [_method="settimes", _sequence=self.id._sequence]
	const public.settimes:=function(integrationtime='10s', 
				gaptime='20s',
				usehourangle=T,
				starttime='0s',
				stoptime='3600s',
				referencetime=F) {

        wider self;
	if (!has_field(referencetime, 'type') || referencetime.type!='epoch') {
           note('Setting the reference time to right now '); 
	   referencetime := dm.epoch('utc', 'today');
        }
        self.settimesRec.integrationtime:=integrationtime;
        self.settimesRec.gaptime:=gaptime;
        self.settimesRec.usehourangle:=usehourangle;
        self.settimesRec.starttime:=starttime;
        self.settimesRec.stoptime:=stoptime;
        self.settimesRec.referencetime:=referencetime;

	return defaultservers.run(self.agent, self.settimesRec);
    }

    self.createRec := [_method="create", _sequence=self.id._sequence]
    const public.create:=function(newms='', 
			shadowlimit=1e-6,
			elevationlimit='10deg',
			autocorrwt=0.0,
			async=!dowait) {
        wider self;
	self.createRec.newms:=newms;
	self.createRec.shadowlimit:=shadowlimit;
	self.createRec.elevationlimit:=elevationlimit;
	self.createRec.autocorrwt:=autocorrwt;
	return  defaultservers.run(self.agent, self.createRec, async);
    }

    self.addRec := [_method="add", _sequence=self.id._sequence]
    const public.add:=function(shadowlimit=1e-6,
			elevationlimit='10deg',
			autocorrwt=0.0,
			async=!dowait) {
        wider self;
      	self.addRec.shadowlimit:=shadowlimit;
	self.addRec.elevationlimit:=elevationlimit;
	self.addRec.autocorrwt:=autocorrwt;
	return  defaultservers.run(self.agent, self.addRec, async);
    }

# this doesn't work properly yet, comment out for the release
#    const public.uvplot:=function(ms='') {
#        wider self;
#	wider private;
#
#	include 'pgplotter.g';
#	mytab := table(ms);
#	uvw := mytab.getcol('UVW');
#	flag_row :=mytab.getcol('FLAG_ROW');
#	if (!private.pgplotter) {
#	    private.pgplotter := pgplotter();
#	    print('creating a new pgplotter');
#	}
#
#	maxu := 1.2*max(uvw[1,]);
#	maxv := 1.2*max(uvw[2,]);
#	minu := 1.2*min(uvw[1,]);
#	minv := 1.2*min(uvw[2,]);
#	if (abs(minu) > maxu)
#	   maxu := abs(minu);
#	if (abs(minv) > maxv)
#	   maxv := abs(minv);
#	private.pgplotter.page()
#	private.pgplotter.env(minu, maxu, minv, maxv, 1, 0);
#	private.pgplotter.lab('U (metres)', 'V (metres)', 'UV Tracks');
#	num_pts := len(flag_row);
#	note(paste('Number of (u,v) points: ',num_pts));
#	private.pgplotter.pt(uvw[1,!flag_row], uvw[2,!flag_row], 1)
#	private.pgplotter.pt(-uvw[1,!flag_row], -uvw[2,!flag_row], 1)
#	mytab.done();
#    }


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
				      facets=1) {
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
	return defaultservers.run(self.agent, self.setoptionsRec);
    }

    self.setvpRec := [_method="setvp", _sequence=self.id._sequence]
    const public.setvp:=function(dovp=T, usedefaultvp=T, vptable='', 
        dosquint=T,parangleinc='360deg') {
        wider self;
        self.setvpRec.dovp:=dovp;
        self.setvpRec.usedefaultvp:=usedefaultvp;
        self.setvpRec.vptable:=vptable;
        self.setvpRec.dosquint:=dosquint;
        self.setvpRec.parangleinc:=parangleinc;
        returnval := defaultservers.run(self.agent, self.setvpRec);
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




    plugins.attach('simulator', public);

    return ref public;

} # _define_simulator()


# Make a new server for every invocation
const simulator := function(host='', forcenewserver=T) {
    agent := defaultservers.activate("simulator", host, forcenewserver)
    if(is_fail(agent)) fail;
    id := defaultservers.create(agent, "simulator", "simulator",
				[=]);
    if(is_fail(id)) fail;
    return ref _define_simulator(agent,id);
} 

# Make a new server for every invocation
const simulatorfromms := function(thems, host='', forcenewserver=T) {
    agent := defaultservers.activate("simulator", host, forcenewserver)
    if(is_fail(agent)) fail;
    id := defaultservers.create(agent, "simulator", "simulatorfromms",
				[thems=thems]);
    if(is_fail(id)) fail;
    return ref _define_simulator(agent,id);
} 

const simulatortester := function(filename='3C273XC1.ms', clname='3C273XC1.cl',
				  size=256, cell='0.7arcsec', stokes='I',
				  coordinates='b1950', componentnumbers=1:4,
				  host='', forcenewserver=F)
{
  mcore:=dm.direction('b1950', '12h26m33.248000', '02d19m43.290000');
  pc:=dm.measure(mcore,coordinates);
  if(is_fail(imagermaketestms(filename))) fail;
  if(is_fail(simulatormaketestcl(clname))) fail;

  # Predict from the cl
  global newimager:=imager(filename);
  if(is_fail(newimager.setimage(nx=size,ny=size,cellx=cell,celly=cell,
				stokes=stokes,phasecenter=pc,doshift=T))) fail;
  if(is_fail(newimager.make('empty'))) fail;
  if(is_fail(newimager.ft(model='empty', complist=clname))) fail;
  if(is_fail(newimager.close())) fail;
  if(is_fail(newimager.done())) fail;

  # Now make the simulator
  agent := defaultservers.activate("simulator", host, forcenewserver);
  id := defaultservers.create(agent, "simulator", "simulatorfromms",
				  [thems=filename]);
  
  global newsimulator :=  _define_simulator(agent,id);   
  newsimulator.corrupt();
  return ref newsimulator;
}

const simulatormaketestcl:=function(clfile='3C273XC1.sim.cl',
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
const simulatormaketestcl0:=function(clfile='Dummy.sim.cl',
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

# pass in an image and simulate away;
const simulatortest1:=function(modfile='', noise='10Jy') 
{
  testdir := 'simulatortest1';
  note('Cleaning up directory ', testdir);
  ok := shell(paste("rm -fr ", testdir));
  if (ok::status) { throw('Cleanup of ', testdir, 'fails!'); };
  ok := shell(paste("mkdir", testdir));
  if (ok::status) { throw("mkdir", testdir, "fails!") };

  img1name := modfile;
  msname   := spaste(testdir, '/','NEW1.MS');
  img2name := spaste(testdir, '/','REAL.MODEL');
  simdirty := spaste(testdir, '/','SIM.DIRTY');
  simpsf   := spaste(testdir, '/','SIM.PSF');
  simclean := spaste(testdir, '/','SIM.CLEAN');
  simrest  := spaste(testdir, '/','SIM.RESTORED');
  simresid := spaste(testdir, '/','SIM.RESID');

#
#  This is how you would read in an ASCII table; but we
#  won't bother right now
#
#  tabname := 'VLAC.LOCAL.TAB';  asciifile := 'VLAC.LOCAL.STN'
#  mytab := tablefromascii(tabname, asciifile);
#  xx:=[]; yy:=[]; zz:=[]; diam:=[];
#  xx := mytab.getcol('X');  
#  yy := mytab.getcol('Y');
#  zz := mytab.getcol('Z');
#  diam := mytab.getcol('DIAM');
#  mytab.done();
#
# 
#  Define VLA C array by hand, local coordinates
#
  xx := [41.1100006,134.110001,268.309998,439.410004,644.210022,880.309998,
	 1147.10999,1442.41003,1765.41003,-36.7900009,-121.690002,-244.789993,
	 -401.190002,-588.48999,-804.690002,-1048.48999,-1318.48999,-1613.98999,
	 -4.38999987,-11.29,-22.7900009,-37.6899986,-55.3899994,-75.8899994,
	 -99.0899963,-124.690002,-152.690002];
  yy := [3.51999998,-39.8300018,-102.480003,-182.149994,-277.589996,-387.839996,
	 -512.119995,-649.76001,-800.450012,-2.58999991,-59.9099998,-142.889999,
	 -248.410004,-374.690002,-520.599976,-685,-867.099976,-1066.42004,77.1500015,
	 156.910004,287.980011,457.429993,660.409973,894.700012,1158.82996,1451.43005,
	 1771.48999];
  zz := [0.25,-0.439999998,-1.46000004,-3.77999997,-5.9000001,-7.28999996,
	 -8.48999977,-10.5,-9.56000042,0.25,-0.699999988,-1.79999995,-3.28999996,
	 -4.78999996,-6.48999977,-9.17000008,-12.5299997,-15.3699999,1.25999999,
	 2.42000008,4.23000002,6.65999985,9.5,12.7700005,16.6800003,21.2299995,
	 26.3299999];
  diam := 0.0* [1:27] + 25.0;

  note('Create the empty measurementset');

  reftime := dm.epoch('utc', '51483.1877d');

  mysim := simulator();
  mysim.settimes( integrationtime='1800s', gaptime='0s', usehourangle=F,
		starttime='0s', stoptime='15000s', 
		referencetime=reftime);
  dir0 := dm.direction('b1950',  '0h0m0.0', '0h0m0.0') 
  mysim.setfield( row=1, sourcename='Test_A', sourcedirection=dir0,
		integrations=1, xmospointings=1, ymospointings=1,
		 mosspacing=1.0);

  posvla := dm.observatory('vla');  #  dm.observatory('ALMA') also works!
  mysim.setconfig(telescopename='VLA', x=xx, y=yy, z=zz, dishdiameter=diam, 
                mount='alt-az', antname='VLA',
		coordsystem='local', referencelocation=posvla);

  mysim.setspwindow(row=1, spwname='XBAND', freq='8.0GHz', deltafreq='50.0MHz',
 		freqresolution='50.0MHz', nchannels=1, stokes='RR RL LR LL');

  mysim.create(newms=msname, shadowlimit=0.001, 
		elevationlimit='8.0deg', autocorrwt=0.5);
  mysim.done();


 note('Make an empty image from the MS, and fill it with the');
 note('the model image;  this is to get all the coordinates to be right');
 
   myimg1 := image(img1name);   # this is the model image with bad coordinates
   imgshape := myimg1.shape()
   imsize := imgshape[1];
 
   myimager := imager(msname);
   myimager.setdata(mode="none" , nchan=1, start=1, step=1,
                           mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1)
   myimager.setimage(nx=imsize, ny=imsize, cellx="1arcsec" ,
		     celly="1arcsec" , stokes="I" , doshift=F,
		     shiftx="0arcsec" ,
		     shifty="0arcsec" , mode="mfs" , nchan=1, start=1, step=1,
		     mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1, facets=1);
   myimager.weight(type="uniform" , rmode="robust" , noise="0Jy" ,
                 robust=0, fieldofview="0rad" , npixels=100);
   myimager.makeimage('observed', img2name);
   myimager.done();

  myimg2 := image( img2name );  #  this is the dummy image with correct coordinates
  arr1 := myimg1.getchunk();
  myimg2.putchunk( arr1 );      #  now this image has the model pixels and 
                              #  the correct coordinates
  myimg1.done();
  myimg2.done();


note('Read in the MS again and predict from this new image');

  mysim := simulatorfromms(msname);
  mysim.predict( img2name );

note('Add noise');

  mysim.setnoise(mode='simplenoise', simplenoise=noise);
  mysim.corrupt();
  mysim.done();


note('Now make the simulated multiscale clean image');

  myimager := imager(msname);
  myimager.setdata(mode="none" , nchan=1, start=1, step=1,
                          mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1)
  myimager.setimage(nx=imsize, ny=imsize, cellx="1arcsec" ,
		    celly="1arcsec" , stokes="I" , doshift=F,
		    shiftx="0arcsec" ,
		    shifty="0arcsec" , mode="mfs" , nchan=1, start=1, step=1,
		    mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1, facets=1);
  myimager.weight(type="uniform" , rmode="robust" , noise="0Jy" ,
                robust=0, fieldofview="0rad" , npixels=100);
  myimager.makeimage('observed', simdirty);
  myimager.makeimage('psf', simpsf);
  myimager.setscales(scalemethod='uservector', uservector=[0.0,3.0,10.0]);
  myimager.clean(algorithm='multiscale' , niter=500, gain=0.7,
                threshold='0Jy' , displayprogress=T,
                model=simclean , fixed=F, complist='', mask='',
                image=simrest, residual=simresid);
  myimager.done();

note(paste('The final deconvolved image is in ', simrest));

#  evaluate the image

  include 'imageevaluator.g';
  include 'regionmanager.g';

  ime := imageevaluator(simrest);  
  r := drm.box(blc="50 50 1 1", trc="70 70 1 1")
  ime.dynamicrange(r);
  ime.fidelity(img2name, 0.1);
  ime.done();

}



# simulate from model components
const simulatortest2:=function(noise='1Jy') 
{
    testdir := 'simulatortest2';
    note('Cleaning up directory ', testdir)
    ok := shell(paste("rm -fr ", testdir))
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

#
#  This is how you would read in an ASCII table; but we
#  won't bother right now
#
#  tabname := 'VLAC.LOCAL.TAB';  asciifile := 'VLAC.LOCAL.STN'
#  mytab := tablefromascii(tabname, asciifile);
#  xx:=[]; yy:=[]; zz:=[]; diam:=[];
#  xx := mytab.getcol('X');  
#  yy := mytab.getcol('Y');
#  zz := mytab.getcol('Z');
#  diam := mytab.getcol('DIAM');
#  mytab.done();
#
# 
#  Define VLA C array by hand, local coordinates
#
xx := [41.1100006,134.110001,268.309998,439.410004,644.210022,880.309998,
1147.10999,1442.41003,1765.41003,-36.7900009,-121.690002,-244.789993,
-401.190002,-588.48999,-804.690002,-1048.48999,-1318.48999,-1613.98999,
-4.38999987,-11.29,-22.7900009,-37.6899986,-55.3899994,-75.8899994,
-99.0899963,-124.690002,-152.690002]  
yy := [3.51999998,-39.8300018,-102.480003,-182.149994,-277.589996,-387.839996,
-512.119995,-649.76001,-800.450012,-2.58999991,-59.9099998,-142.889999,
-248.410004,-374.690002,-520.599976,-685,-867.099976,-1066.42004,77.1500015,
156.910004,287.980011,457.429993,660.409973,894.700012,1158.82996,1451.43005,
1771.48999]  
zz := [0.25,-0.439999998,-1.46000004,-3.77999997,-5.9000001,-7.28999996,
-8.48999977,-10.5,-9.56000042,0.25,-0.699999988,-1.79999995,-3.28999996,
-4.78999996,-6.48999977,-9.17000008,-12.5299997,-15.3699999,1.25999999,
2.42000008,4.23000002,6.65999985,9.5,12.7700005,16.6800003,21.2299995,
26.3299999]  
diam := 0.0* [1:27] + 25.0;

note('Create the empty measurementset');

  reftime := dm.epoch('utc', '51483.1877d');

  mysim := simulator();
  mysim.settimes( integrationtime='1800s', gaptime='0s', usehourangle=F,
		starttime='0s', stoptime='15000s', 
		referencetime=reftime);
  dir0 := dm.direction('b1950',  '0h0m0.0', '2d19m43.291332') 
  mysim.setfield( row=1, sourcename='Test_A', sourcedirection=dir0,
		integrations=1, xmospointings=1, ymospointings=1,
		mosspacing=1.0);

  posvla := dm.observatory('vla');  #  dm.observatory('ALMA') also works!
  mysim.setconfig(telescopename='VLA', x=xx, y=yy, z=zz, dishdiameter=diam, 
                mount='alt-az', antname='VLA',
		coordsystem='local', referencelocation=posvla);

  mysim.setspwindow(row=1, spwname='XBAND', freq='8.0GHz', deltafreq='50.0MHz',
 		freqresolution='50.0MHz', nchannels=1, stokes='RR RL LR LL');

  mysim.create(newms=msname, shadowlimit=0.001, 
		elevationlimit='8.0deg', autocorrwt=0.5);

note('Make components');
  simulatormaketestcl0( clfile=clfile, componentnumbers=1 );
  mysim.predict( complist=clfile );

note('Add noise');

  mysim.setnoise(mode='simplenoise', simplenoise=noise);
  mysim.corrupt();
  mysim.done();


note('Now make the simulated multiscale clean image');


  myimager := imager(msname);
  myimager.setdata(mode="none" , nchan=1, start=1, step=1,
                          mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1)
  myimager.setimage(nx=256, ny=256, cellx="1arcsec" ,
                           celly="1arcsec" , stokes="I" , doshift=F,
                           shiftx="0arcsec" ,
                           shifty="0arcsec" , mode="mfs" , nchan=1, start=1, step=1,
                           mstart="0km/s" , mstep="0km/s" , spwid=1, fieldid=1, facets=1);
  myimager.weight(type="uniform" , rmode="robust" , noise="0Jy" ,
                robust=0, fieldofview="0rad" , npixels=100);
  myimager.makeimage('observed', simdirty);
  myimager.makeimage('psf', simpsf);
  myimager.setscales(scalemethod='uservector', uservector=[0.0,3.0,10.0]);
  myimager.clean(algorithm='multiscale' , niter=500, gain=0.7,
                threshold='0Jy' , displayprogress=T,
                model=simclean , fixed=F, complist='', mask='',
                image=simrest, residual=simresid);
  myimager.done();

note(paste('The final deconvolved image is in ', simrest));

}

