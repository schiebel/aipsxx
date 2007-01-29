# holog.g: Reduce holographic observation
#
#   Copyright (C) 1998,2000
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
#   $Id: holog.g,v 19.0 2003/07/16 03:38:27 aips2adm Exp $
#

pragma include once

include "servers.g"
include "pgplotter.g"
include 'plugins.g'

#defaultservers.suspend(T)
#defaultservers.trace(T)

# Users aren't to use this.
const _define_holog := function(ref agent, id) {
    self := [=]
    public := [=]
    self.agent := ref agent;
    self.id := id;
    public := defaultservers.init_object(self)

    self.initRec := [_method="init", _sequence=self.id._sequence]
    public.init := function(applytrx=T) {
	wider self;
	self.initRec.applytrx := applytrx;
        return defaultservers.run(self.agent, self.initRec);
    }

    self.getsummaryRec := [_method="getsummary", _sequence=self.id._sequence]
    public.getsummary := function() {
        wider self;
 	return defaultservers.run(self.agent, self.getsummaryRec);
    }

    self.getposRec := [_method="getpos", _sequence=self.id._sequence]
    public.getpos := function() {
        wider self;
 	return defaultservers.run(self.agent, self.getposRec);
    }

    self.findstepsRec := [_method="findsteps", _sequence=self.id._sequence]
    public.findsteps := function (postolerance=0.01, steptolerance=0.05) {
        wider self;
	self.findstepsRec.postolerance := postolerance;
	self.findstepsRec.steptolerance := steptolerance;
 	return defaultservers.run(self.agent, self.findstepsRec);
    }

    self.cleargriddataRec := [_method="cleargriddata", _sequence=self.id._sequence]
    public.cleargriddata := function() {
        wider self;
 	return defaultservers.run(self.agent, self.cleargriddataRec);
    }

    self.setnstepsRec := [_method="setnsteps", _sequence=self.id._sequence]
    public.setnsteps := function (nsteps) {
        wider self;
	self.setnstepsRec.nsteps := nsteps;
 	return defaultservers.run(self.agent, self.setnstepsRec);
    }

    self.sumdataRec := [_method="sumdata", _sequence=self.id._sequence]
    public.sumdata := function(stepantenna, refantenna) {
        wider self;
	self.sumdataRec.stepant := stepantenna;
	self.sumdataRec.refant := refantenna;
 	return defaultservers.run(self.agent, self.sumdataRec);
    }

    self.griddataRec := [_method="griddata", _sequence=self.id._sequence]
    public.griddata := function (returnarrays=F) {
        wider self;
	self.griddataRec.returnarrays := returnarrays;
 	return defaultservers.run(self.agent, self.griddataRec);
    }

    self.rotategriddataRec := [_method="rotategriddata", _sequence=self.id._sequence]
    public.rotategriddata := function (rotdistance=4.95) {
        wider self;
	self.rotategriddataRec.rotdistance := rotdistance;
 	return defaultservers.run(self.agent, self.rotategriddataRec);
    }

    self.getgriddataRec := [_method="getgriddata", _sequence=self.id._sequence]
    public.getgriddata := function() {
        wider self;
 	return defaultservers.run(self.agent, self.getgriddataRec);
    }

    self.fftRec := [_method="fft", _sequence=self.id._sequence]
    public.fft := function (size=128, dishdiameter=25.0, simfreq=0) {
        wider self;
	self.fftRec.size := size;
	self.fftRec.diameter := dishdiameter;
	self.fftRec.simfreq := simfreq;
 	return defaultservers.run(self.agent, self.fftRec);
    }

    self.refinefftRec := [_method="refinefft", _sequence=self.id._sequence]
    public.refinefft := function() {
        wider self;
 	return defaultservers.run(self.agent, self.refinefftRec);
    }

    self.getfftdataRec := [_method="getfftdata", _sequence=self.id._sequence]
    public.getfftdata := function() {
        wider self;
 	return defaultservers.run(self.agent, self.getfftdataRec);
    }

    self.normalizeRec := [_method="normalize", _sequence=self.id._sequence]
    public.normalize := function (amplcrit=0.1) {
        wider self;
	self.normalizeRec.amplcrit := amplcrit;
 	return defaultservers.run(self.agent, self.normalizeRec);
    }

    self.phasejumpsRec := [_method="getphasejumps", _sequence=self.id._sequence]
    public.phasejumps := function() {
        wider self;
 	return defaultservers.run(self.agent, self.phasejumpsRec);
    }

    self.getapRec := [_method="getap", _sequence=self.id._sequence]
    public.getap := function() {
        wider self;
 	return defaultservers.run(self.agent, self.getapRec);
    }

    self.solveRec := [_method="solve", _sequence=self.id._sequence]
    public.solve := function (focallength = 8.75) {
        wider self;
	self.solveRec.focallength := focallength;
 	return defaultservers.run(self.agent, self.solveRec);
    }

    self.getsolutionRec := [_method="getsolution", _sequence=self.id._sequence]
    public.getsolution := function() {
        wider self;
 	return defaultservers.run(self.agent, self.getsolutionRec);
    }

    public.start := function(applytrx=T) {
        public.init(applytrx);
        public.findsteps();
        return public.getsummary();
    }

    public.mapant := function (antennas=F, refantennas=F,
			       types='n', imagename='',
			       rotate=T, rotdistance=4.95) {
        s := public.getsummary();
	nant := length(s.antennas);
	if (is_boolean(antennas)  ||  length(antennas)==0) {
            for (i in [1:nant]) {
	        if (s.antennas[i]) {
	            print "processing step antenna", i-1;
		    if (! is_fail(public.gridant (i-1, refantennas,
						  rotate, rotdistance))) {
			public.gridtoimage (imagename, types);
		    }
                }
            }
        } else {
            for (i in [1:length(antennas)]) {
	        print "processing step antenna", antennas[i];
		if (! is_fail(public.gridant (antennas[i], refantennas,
					      rotate, rotdistance))) {
		    public.gridtoimage (imagename, types);
		}
            }
        }
	if (rotate) {
	    public.rotategriddata (rotdistance);
	}
	return T;
    }

    public.gridant := function (antenna, refantennas=F, rotate=T,
				rotdistance=4.95) {
        s := public.getsummary();
	nant := length(s.antennas);
        if (antenna < 0  ||  antenna >= nant)
                   fail paste("Antenna",antenna,"is an unknown antenna");
        if (!s.antennas[antenna+1])
                   fail paste("Antenna",antenna,"is not a stepping antenna");
        public.cleargriddata();
	if (is_boolean(refantennas)  ||  length(refantennas)==0) {
            s := public.getpos();
            for (i in [1:nant]) {
	        if (s.antindex[i,antenna+1]>=0 || s.antindex[antenna+1,i]>=0) {
	            print "processing reference antenna", i-1;
                    print public.sumdata (antenna, i-1);
                    print public.griddata();
                }
            }
        } else {
            for (i in [1:length(refantennas)]) {
	        print "processing reference antenna", refantennas[i];
                print public.sumdata (antenna, refantennas[i]);
                print public.griddata();
            }
        }
	if (rotate) {
	    public.rotategriddata (rotdistance);
	}
	return T;
    }

    public.reduceant := function (antenna, refantennas=F, niter=3) {
	public.gridant (antenna, refantennas);
	public.fft();
	if (niter > 0) {
	    for (i in [1:niter]) {
		print public.refinefft();
            }
        }
	print public.normalize();
	print public.phasejumps();
	r := public.solve();
	s := public.getsolution();
	print 'surface range = ', range(s.errors*1000), ' mm';
	print '  power range = ', range(s.power*200), ' WU';
	return r;
    }

    public.makecoordsys := function (summary, ant) {
	include 'coordsys.g';
	cs := coordsys (direction=T);
	cs.setreferencecode('direction', 'J2000');
	cs.setobserver ('holog');
	cs.settelescope ('WSRT');
	cs.setparentname (spaste('RT', ant));
	cs.setunits ("rad rad");
	cs.setreferencepixel (value=[(1+summary.ransteps)/2,
				     (1+summary.decnsteps)/2]);
	val1 := cs.referencevalue();
	val1[1] := dq.quantity(paste(summary.ra,'rad'));
	val1[2] := dq.quantity(paste(summary.dec,'rad'));
	cs.setreferencevalue (value=val1);
	val1[1] := dq.quantity(paste(summary.rastep/cos(summary.dec),'rad'));
	val1[2] := dq.quantity(paste(summary.decstep,'rad'));
	cs.setincrement (value=val1);
	return cs;
    }

    public.gridtoimage := function (imagename='', types='n') {
	include 'image.g';
	arr := public.getgriddata();
	rec := public.getsummary();
	cs := public.makecoordsys (rec, arr.stepant);
	if (imagename == '') {
	    imagename := rec.fieldname ~ s/[_ -].*$//;
	    imagename := spaste(imagename,'_RT',arr.stepant);
	}
	global hologimc := imagefromarray (pixels=real(arr.griddata), csys=cs);
	global hologims := imagefromarray (pixels=imag(arr.griddata), csys=cs);
	if (types ~ m/[an]/i) {
	    im := imagecalc (spaste(imagename,'.AMPL'),
			     'sqrt($hologimc*$hologimc+$hologims*$hologims)');
	    im.done();
	}
	if (types ~ m/n/i) {
	    im := imagecalc (spaste(imagename,'.NAMPL'),
			     spaste(imagename,'.AMPL/max(',
				    imagename,'.AMPL)'));
	    im.done();
	}
	if (types ~ m/p/i) {
	    im := imagecalc (spaste(imagename,'.PHASE'),
			     'atan2($hologimc,$hologims)');
	    im.done();
	}
	if (types ~ m/c/i) {
	    im := imagecalc (spaste(imagename,'.COS'), '$hologimc');
	    im.done();
	}
	if (types ~ m/s/i) {
	    im := imagecalc (spaste(imagename,'.SIN'), '$hologims');
	    im.done();
	}
	hologimc.done();
	hologims.done();
    }

    public.plotpos := function (antenna) {
	rec := public.getpos();
	p2 := pgplotter();
	p2.env (0, length(rec.times), min(rec.raoffsets),
                max(rec.raoffsets), 0 ,-1);
	p2.line ([1:length(rec.times)], rec.raoffsets[,antenna+1]);
	p3 := pgplotter();
	p3.env (0, length(rec.times), min(rec.decoffsets),
                max(rec.decoffsets), 0 ,-1);
	p3.line ([1:length(rec.times)], rec.decoffsets[,antenna+1]);
    }

    public.plotmap := function (contour, data, unit, title, title2) {
	shp:= data::shape;
	pp := pgplotter();
	pp.env (1, shp[1], 1, shp[2], 1, 0);
	minmax := range(data);
	if (length(contour) > 1) {
            pp.cont (data, contour, length(contour), [0,1,0,0,0,1]);
	    pp.mtxt ('T', 2, 0, 0, spaste(title, '   ', contour, unit));
            pp.mtxt ('T', 0.5, 0, 0, spaste(title2, '   min = ', minmax[1],
                                                    ',  max = ', minmax[2]));
        } else {
	    pp.imag (data, minmax[1], minmax[2], [0,1,0,0,0,1]);
            pp.ctab([0,1], [0,1], [0,1], [0,1], 1, 0.5);
	    pp.wedg('B', 1, 3, minmax[1], minmax[2], title);
        }
    }

    public.plotgriddata := function(contour=F) {
	rec := public.getgriddata();
	cdata := real(rec.griddata);
	sdata := imag(rec.griddata);
	ampl := sqrt(cdata*cdata + sdata*sdata);
	public.plotmap (contour, ampl, '',
			spaste('AMPL RT',rec.stepant),
			spaste(rec.fieldname,'   ',rec.date));
    }

    public.plotfftdata := function(contour=F) {
	rec := public.getfftdata();
	public.plotmap (contour, real(rec.fftdata), '',
	                spaste('COSINE RT',rec.stepant),
	                spaste(rec.fieldname,'   ',rec.date));
	public.plotmap (contour, imag(rec.fftdata), '',
	                spaste('SINE RT',rec.stepant),
	                spaste(rec.fieldname,'   ',rec.date));
    }

    public.plotap := function(contour=T) {
	rec := public.getap();
	public.plotmap (contour, rec.ampl*200, 'WU',
	                spaste('AMPLITUDE RT',rec.stepant),
	                spaste(rec.fieldname,'   ',rec.date));
	public.plotmap (contour, rec.phase*180/pi, 'deg',
	                spaste('PHASE RT',rec.stepant),
	                spaste(rec.fieldname,'   ',rec.date));
    }

    public.plotsolution := function(contour=T) {
	rec := h.getsolution();
	public.plotmap (contour, rec.errors*1000, 'mm',
	                spaste('SURFACE RT',rec.stepant),
	                spaste(rec.fieldname,'   ',rec.date));
	public.plotmap (contour, rec.power*200, 'WU',
	                spaste('POWER RT',rec.stepant),
	                spaste(rec.fieldname,'   ',rec.date));
    }
    public.plotsurface := function(contour=T) {
	rec := h.getsolution();
	public.plotmap (contour, rec.errors*1000, 'mm',
	                spaste('SURFACE RT',rec.stepant),
	                spaste(rec.fieldname,'   ',rec.date));
    }
    public.plotpower := function(contour=T) {
	rec := h.getsolution();
	public.plotmap (contour, rec.power*200, 'WU',
	                spaste('POWER RT',rec.stepant),
	                spaste(rec.fieldname,'   ',rec.date));
    }


    public.id := function() {
	wider self;
	return self.id.objectid;
    }

    public.type := function() {
        return 'holog';
    }

    public.done := function()
    {
        wider self, public;
        ok := defaultservers.done(self.agent, public.id());
        if (ok) {
            self := F;
            val public := F;
        }
        return ok;
    }

    
    plugins.attach('holog', public);
    return ref public;
} # _define_holog()


const holog := function(msname, spwid=0, channel=0, polnrs=-1, host='', forcenewserver=F) {
    agent := defaultservers.activate('holog', host, forcenewserver)
    id := defaultservers.create(agent, 'holog', 'holog',
                [msname=msname, spwid=spwid, channel=channel, polnrs=polnrs]);
    return ref _define_holog(agent,id);

} # holog()



const hologdemo := function()
{
    return T
}

const hologtest := function()
{
    return T
}
