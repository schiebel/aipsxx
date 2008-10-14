# dynamicsched.g: definition of dynamic scheduler simulator
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: dynamicsched.g,v 19.1 2004/08/25 01:51:43 cvsmgr Exp $
#

# pragma include once;

include 'quanta.g'
include 'measures.g'
include 'pgplotter.g'

# const
dynamicsched := subsequence () {

  private :=[=];
  private.sitedatainitialized := F;
  private.taudatainitialized := F;
  private.phasecalinitialized := F;
  private.pg := F;
  private.sensitivityinitialized := F;
  private.sensitivityb := F;
  private.sensitivitya := F;
  private.sensitivity := [=];
  private.sensitivity.nbands := 0;
  private.sensitivity.bands := [=];
  for (i in [1:100]) {
     private.sensitivity.bands[i] := F;
  }
  private.schedule := [=];
  private.schedule.list := [=];
  private.schedule.nlist := 0;
  private.schedcriteria := [=];
  private.changeinfo := [=];

# public functions

  const self.type := function() {
      return 'dynamicsched';
  }

  const self.setsitedata := function(sitedatafile='CH.9506.INT+ALL',
			headerfile='header.sitedata',
			observatory='ALMA',
			seeinglambda='26.79mm',
			seeingel='36deg',
                        seeingbaseline='300m') {
    wider self, private;
    private.seeinglambda := seeinglambda;
    private.seeingel     := seeingel;
    private.seeingbaseline := seeingbaseline;
    private.siteposition :=  dm.observatory(observatory) 
    private.epoch := 'J2000';
    private.sitedataascii := sitedatafile;
    private.siteheader := headerfile;
    private.sitedatatable := spaste( private.sitedataascii, ".TAB");

    private.readsitedata();

    private.sitedatainitialized := T;
    return T;
  }

# set the name of the file which contains the tau terms in it
# and read in those terms

  const self.settaudata := function(tautermsfile='CH.LIEBE.TERMS') {
    wider self, private;

    private.tautermsascii := tautermsfile;
    private.tautermstable :=  spaste( private.tautermsascii, ".TAB" );
    private.readtauterms();
    private.taudatainitialized := T;
    return T;
  }


# set some variables associated with overhead with each
# spource change

  const self.setchangeinfo := function(azslewrate='2deg/s', 
				elslewrate='1deg/s',
				changeoverhead='60s') {
	wider self, private;

	private.changeinfo.azslewrate := dq.quantity( azslewrate );
	private.changeinfo.elslewrate := dq.quantity( elslewrate );
	private.changeinfo.overhead := dq.quantity( changeoverhead );

	return T;
  }

# set the starting time for the schedule, the duration of the schedule,
# the increment of the scheduling

  const self.settimes := function(dt='0.25h', 
			timeref='relative',
			absolutestart=F,
			relativestart='0.0h',
			duration='-1.0h') {
	wider self, private;
	if (!private.sitedatainitialized) {
	    note('You need to run setsitedata first');
	    return F;
	}
	private.schedule.dt := dq.quantity(dt,'h');
	if (timeref=='relative') {
	    private.schedule.starttime := dm.epoch('utc', 
	       dq.add( private.sitedata.starttime.m0, dq.quantity(relativestart) ) );
	} else {
	    private.schedule.starttime := absolutestart;
	}

	if (dq.convert(duration, 'd').value < 0) {
	    private.schedule.stoptime := private.sitedata.stoptime;
	}  else {
	    private.schedule.stoptime := dm.epoch('utc', 
		dq.add( private.schedule.starttime.m0, dq.quantity(duration) ));
	}

	note(paste('Schedule is to start on: ', private.schedule.starttime));
	note(paste('Schedule is to stop on: ', private.schedule.stoptime));
  }

  const self.setphasecalinfo := function(phasecalmethod='RADIOMETRIC',
				baselevel='50um',	
				fraclevel=0.10,
				windvelocity='10m/s',
				timescale='30s') {	
    wider self, private;				
    private.phasecalinfo := [=];
    private.phasecalinfo.method := phasecalmethod;
    private.phasecalinfo.radbaselevel := dq.convert(dq.quantity(baselevel), 'um');
    private.phasecalinfo.radfraclevel := fraclevel;
    private.phasecalinfo.radvelocity  := dq.convert(windvelocity);
    private.phasecalinfo.radtimescale := timescale;
    private.phasecalinitialized := T;
    return T;
  }


 
# set the criteria to determine which project gets chosen
# at which time 
# There need to be items such as frequency bias and stay-on-current-project bias
#
#
#

  const self.setschedcriteria := function(hatozenith='2h', hafromzenith='1.5h', phasecutoff='30deg') {
	wider self, private
	private.schedcriteria.angletozenith := dq.toangle( dq.quantity(  hatozenith ) );
	private.schedcriteria.anglefromzenith := dq.toangle( dq.quantity(  hafromzenith ) );
	private.schedcriteria.phasecutoff := dq.quantity(  phasecutoff );
	return T;
  }

  const self.setsensitivity := function(dishdiameter='12m',
				nantennas=64,
				npol=2) {
	wider self, private;
	private.sensitivity.diameter := dishdiameter;
	private.sensitivity.npol := npol;
	private.sensitivity.nants := nantennas;
	private.sensitivity.nbaselines := (nantennas-1)*nantennas/2;

	private.sensitivitya := T;
	if (private.sensitivitya && private.sensitivityb) private.sensitivityinitialized := T;
	return T;
  }

# add (or overwrite) the band-specific sensitivity information
  const self.setbandsensitivity := function(whichband=1,
					bandname='band1',
					freqlow='100GHz', 
					freqhigh='1000GHz',
					bandwidth='8GHz',
					tsys='100K',
					efficiency=0.80) {
	wider self, private;
	sens := [=];
	sens.band := bandname;
	sens.freqlow := dq.quantity(freqlow);
	sens.freqhigh := dq.quantity(freqhigh);
	sens.bandwidth := dq.quantity(bandwidth);
	sens.tsys := dq.quantity(tsys);
	sens.efficiency := efficiency;
	private.sensitivity.bands[whichband] := sens;
	if (private.sensitivity.nbands < whichband) private.sensitivity.nbands := whichband;
	private.sensitivityb := T
	if (private.sensitivitya && private.sensitivityb) private.sensitivityinitialized := T;
	return T;
  }

  const self.viewsensitivity  := function() {
	wider self, private;

	if (!private.sensitivitya) {
		note('You must run setsensitivity() first');
		return F;
	}
	note('Sensitivity Parameters: ');
	note( paste(" dishdiameter = ", private.sensitivity.diameter));
	note( paste(" npol = ", private.sensitivity.npol));
	note( paste(" nantennas = ", private.sensitivity.nantennas));

	if (!private.sensitivityb) {
		note('You must run setbandsensitivity() first');
		return F;
	}
	if (private.sensitivity.nbands > 0) {
  	  note( paste(" band-dependent parameters: "));
	  for (i in [1:private.sensitivity.nbands]) {
	    sens := private.sensitivity.bands[i];	   
	    if (sens == F) {
	      note(paste("Band ", i, " has not been defined"));
	    }   else  {
 	      note( paste(" band = ", sens.band));
 	      note( paste(" freqlow = ", sens.freqlow));
 	      note( paste(" freqhigh = ", sens.freqhigh));
 	      note( paste(" bandwidth = ", sens.bandwidth));
 	      note( paste(" tsys = ", sens.tsys));
 	      note( paste(" efficiency = ", sens.efficiency));
	    }
	  }
	}  else  {
 	  note('No bands set');
	  return F;
	}
	return T;
  }

  const self.generateprojects := function(nprojects=100,
				ratingmin=1, ratingmax=10,
				timemode='5h', timesigma='5h', timemax='20h',
				freqtransexponent=2.0, freqwt=2.0, freqexponent=1.5, 
				decmin='-90deg', decmax='52deg') {
	wider self, private;
	private.projects := F;
	private.projects := [=];

	note (paste("Generating ", nprojects, " projects"));
	private.makefreqdist(transexp=freqtransexponent, freqwt=freqwt, freqexp=freqexponent) 
	private.makeratingdist(ratingmin=ratingmin, ratingmax=ratingmax);
	private.maketimedist(timemode=timemode, timesigma=timesigma, timemax=timemax);
	private.makeradecdist(decmin=decmin, decmax=decmax);
	for (i in [1:nprojects]) {
	     private.projects[i] := private.makeoneproject();
        }
	private.projects.nprojects := nprojects;
	note(paste('Generated ', nprojects,  'projects'));
	return T;
  }


# plots a graph of the probability distributions
  const self.probview :=function(whichone) {
    wider self, private;
    private.donepgplotter();
    which := [=];
    if (whichone == 'rating')  {
      which := ref private.ratingdist;
    } else if (whichone == 'freq')  {
      which := ref private.freqdist;
    } else if (whichone == 'radec')  {
      which := ref private.radecdist;
    } else if (whichone == 'time')  {
      which := ref private.timedist;
    } else {
      note (paste("Hey, dude, I don't KNOW about ", whichone));
      note ('Try rating, freq, time, or radec');
      fail;
    }
    private.getpgplotter();
    private.pg.page();
    private.pg.sci(15);
    private.pg.plotxy1(which.value, which.cumprobability);
    private.pg.sci(0);
    probability := which.probability / max(which.probability);
    private.pg.plotxy1(which.value, probability);
    note('green: differential probability');
    note('red: cumulative probability');
    return T;
  }


  const self.saveprojects := function(projecttable='', allprojects=T, whichprojects=[] ) {
     if (allprojects) {
	private.record2table( private.projects, projecttable, 'projects' );
     } else {
	newprojects := [=];
	newprojects := private.getprojects( private.projects, whichprojects );
	private.record2table( newprojects, projecttable, 'projects' );
	newprojects := F;
     }
     return T;
  }

  const self.recoverprojects := function(projecttable='') {
    wider self, private;
    private.projects := F;
    private.projects := private.table2record(projecttable, 'projects');
    if (is_fail(private.projects)) {
	return F;
    } else {
	return T;
    }
  }

  const self.saveschedule := function(scheduletable='') {
	private.record2table( private.schedule, scheduletable, 'schedule' );
     return T;
  }

  const self.recoverschedule := function(scheduletable='') {
    wider self, private;
    private.schedule := F;
    private.schedule := private.table2record(scheduletable, 'schedule');
    if (is_fail(private.schedule)) {
	return F;
    } else {
	return T;
    }
  }

  const self.defaultinitialize := function() {
    wider self, private;
    private.sitedataascii := "CH.9506.INT+ALL";
    private.siteheader := "header.sitedata";
    private.sitedatatable := spaste( private.sitedataascii, ".TAB");
    private.readsitedata();

    private.tautermsascii := "CH.LIEBE.TERMS";
    private.tautermstable :=  spaste( private.tautermsascii, ".TAB" );
    private.readtauterms();

    private.siteposition :=  dm.observatory('ALMA') 
    private.epoch := 'J2000';

    private.sensitivityinitialized := F;
    self.initializesensitivity();
    private.schedule.dt := dq.quantity(0.25, "d");

    private.phasecalinitialized := T;
    private.phasecalinfo := [=];
    private.phasecalinfo.method := "RADIOMETRIC";
    private.phasecalinfo.radbaselevel := dq.quantity(50, "um");
    private.phasecalinfo.radfraclevel := 0.10;
    private.phasecalinfo.radvelocity  := dq.quantity(10, "m/s");
    private.phasecalinfo.radtimescale := dq.quantity(30, "s");

    private.setsitedata();
    private.setchangeinfo();
    private.settimes();

    private.pg := pgplotter();

    return T;
  }

  const self.done := function() {
	wider self, private;
	if (private.pg != F) private.pg.done();
	self := F;
        val public := F;
        return T;
  }

# get self
# this is only used for debugging purposes
  const self.getprivate := function() {
	return ref private;
  }


  const self.schedule := function() {
    wider self, private;
    
    private.schedule.timenow := private.schedule.starttime;
    keepgoing := T;
    nsegments := 0;
    lastproject := -1;
    
    while (keepgoing)  {
      nsegments +:= 1;
      
      lst := private.getlst( private.schedule.timenow );
      print "LST now = ", dq.convert(dq.totime(lst), 'h').value, " hours";

# OK:  get the projects which are closest to the current LST
# in the future: make sure the project is not already completed!

      conditionsnow  := private.getconditions( private.schedule.timenow );
	    
# if no conditions are available, dont schedule the telescope now
      if (!is_fail(conditionsnow)) {
	projectlist := private.getneartransit( private.projects, lst, 
					    private.schedcriteria.angletozenith, 
					    dq.quantity(0.0, 'deg'));
	if ( is_fail(  projectlist ) ) {
	  private.addnulltoschedule( private.schedule.timenow, private.schedule.dt );
	  note(paste("Time: ", private.schedule.timenow,
		     "    NO PROJECTS AVAILABLE IN QUE!"));
	} else {
	  projectlist2 := private.getunobservedprojects( private.projects, projectlist );
	  
	  if (is_fail(projectlist2) ) {
	    
	    private.addnulltoschedule( private.schedule.timenow, private.schedule.dt );
	    note(paste("Time: ", private.schedule.timenow,
		       "    NO PROJECTS AVAILABLE IN QUE!"));
	  } else {
	    goodness := projectlist2 * 0.0;
	    for (i in [1:len(projectlist2)]) {
	      goodness[i] := private.getgoodness( conditionsnow, 
					       private.projects[projectlist2[i]],
					       private.projects[lastproject],
					       private.schedule.timenow );
	    }
	    badness := -goodness;  #  minimum badness = maximum goodness
	    dothisproject := sort_pair(badness, projectlist2)[1];
	    
	    if (sort(badness)[1] >= 0) {
	      private.addnulltoschedule( private.schedule.timenow, private.schedule.dt );
	      note(paste("Time: ", private.schedule.timenow,
			 "    BAD CONDITIONS, NO PROJECT!"));
	    } else {
	      if (lastproject < 1) lastproject := dothisproject
	      noiserec := private.getsensitivity( conditionsnow, 
					       private.projects[dothisproject],
					       private.projects[lastproject],
					       private.schedule.timenow,
					       private.schedule.dt);
	      lastproject := dothisproject;
	      
	      private.addtoschedule( private.projects[dothisproject], 
				  private.schedule.timenow,
				  private.schedule.dt,
				  noiserec.dtactual);
	      totalsens := private.addsensitivity(private.projects[dothisproject], 
					       noiserec.sigma, 
					       noiserec.dtactual);
	      note(paste("Time: ",  dq.time(private.schedule.timenow.m0, form="ymd time"),
			 "   LST: ", dq.convert(dq.totime(lst), 'h').value ));
	      dir := private.projects[dothisproject].direction;
	      note(paste(".....",dothisproject,
			 "  .....Freq: ", private.projects[dothisproject].freq.value,
			 "  RA: ", dq.angle(dir.m0), " DEC: ", dq.angle(dir.m1) ));
	      note(paste(".....Tobs: ",private.projects[dothisproject].timeobserved.value,
			 "  Treq: ", private.projects[dothisproject].timerequired.value));
	      note(paste( ".....Phase: ", private.projects[dothisproject].phase,
			 "  sig1: ", noiserec.sigma,
			 "  total sigma: ",totalsens));
	    }
	  }
	}
      }
# is it time to stop?
      private.schedule.timenow := dm.epoch('utc', dq.add( private.schedule.timenow.m0, private.schedule.dt ));
      diff := dq.sub(private.schedule.stoptime.m0, private.schedule.timenow.m0).value;
      if ( dq.convert(diff, 'h').value <= 0.0) keepgoing := F;
    }
    note(paste("A total of", nsegments,"observing segments where scheduled"));
    return T;
  }




# if we read in a foreign observing schedule, we can recalculate
# the sensitivity for the list of projects
  const self.reobserveschedule := function() {
	note('reobserveschedule hasn\'t yet been implemented!');
	return F;
  }


  const self.evaluateobservations := function() {
    note('evaluateobservations hasn\'t yet been implemented!');
    return F;
  }


  
#==================== private functions ================================================


# for now, use a very simple algorithm: assign a zero goodness
# to any project which has phase noise in excess of the cutoff;
# assign the observing frequency of the project to any project which
# has phase noise less than the cutoff.
  
  const private.getgoodness := function( ref conditionsnow, 
				ref project,
				ref lastproject,
				ref timenow ) 
  {
    
    phasestructure := conditionsnow.phasestructure;
    freq := project.freq;
    el := private.getelevation( timenow, project.direction );
    phase := private.phasecalphase(freq, el, phasestructure, private.phasecalinfo.method);
    project.phase := phase;

    if (dq.convert(phase, 'rad').value < 
	dq.convert(private.schedcriteria.phasecutoff, 'rad').value)  {
	  
	  return ( dq.convert( freq, 'GHz').value );
	}  else {
	  return 0;
	}
  }

  const private.getpgplotter := function() 
  {
    wider self, private;
    if (private.pg != F) private.pg.done();
    private.pg := pgplotter();
    return T;
  }

  const private.donepgplotter := function() 
  {
    wider self, private;
    if (private.pg ) private.pg.done();
    return T;
  }

  const private.readsitedata := function() 
  {
    wider self, private; 
    private.sitedata := [=];
    if (! tableexists(private.sitedatatable) )
    {
      tab := tablefromascii( private.sitedatatable, private.sitedataascii, private.siteheader);
      tab.done();
    }
    tab := table( private.sitedatatable );
    private.sitedata.yr := tab.getcol("yr");
    private.sitedata.mo := tab.getcol("mo");
    private.sitedata.da := tab.getcol("da");
    private.sitedata.fhr:= tab.getcol("fhr");
    private.sitedata.fday1 := tab.getcol("fday1");	
    private.sitedata.rms := tab.getcol("rms");
# NOTE: this data was taken at 36 deg el: convert to zenith:
    airmass := 1.0/sin( dq.convert( private.seeingel, 'rad' ).value );
    private.sitedata.rms /:= sqrt( airmass );
# Now convert rms from degrees phase at 11.2 GHz to pathlength in microns
    private.sitedata.rmspath := private.sitedata.rms * 
        dq.convert( private.seeinglambda, 'um' ).value / 360.0;     
    private.sitedata.alpha := tab.getcol("alpha");
    private.sitedata.p1 := tab.getcol("P1");
    private.sitedata.t0 := tab.getcol("T0");
    private.sitedata.tau := tab.getcol("tau");
    private.sitedata.temp := tab.getcol("Temp");
    private.sitedata.windv := tab.getcol("WindV");
    private.sitedata.dtdt := tab.getcol("dTdt");
    private.sitedata.dvdt := tab.getcol("dVdt");
    tab.done();
    private.fixtau();
    private.sitedata.n := len(private.sitedata.fday1);
    
#	for (i in [1:private.sitedata.n]) {
#	   private.sitedata.time[i] := private.fday2utc( private.sitedata.fday1[i] );
#	}
    
    myepoch := private.fday2utc( private.sitedata.fday1[1] );
    myepoch2 := private.fday2utc( private.sitedata.fday1[private.sitedata.n] );
    private.sitedata.starttime := myepoch;
    private.sitedata.stoptime := myepoch2;
    note (paste( "Starting time for site data = ", myepoch));
    note (paste( "Stopping time for site data = ", myepoch2));
    
    return T;
  }
  
# get the conditions associated with the current time
# (closest time within dt days of timenow)
# returns fail if:  siteconditions dont exist yet
#                   time is too far away from a valid data point
  
# Future improvement: provide a guess as to what the starting index is


  const private.getconditions := function( timenow, dt=0.007 )
  {
    if(!private.sitedatainitialized) {
      note ("Need to run setsitedata()");
      fail;
    }
    
    fdaynow := private.utc2fday( timenow );
    tdiff := abs(private.sitedata.fday1 - fdaynow);
    index := [1:len(tdiff)];
    iclosest := sort_pair( tdiff, index )[1];
    if (tdiff[iclosest] >  dt) {
      fail;
    }
    
    conditionsnow := [=];
    conditionsnow.rms := private.sitedata.rms[iclosest];
    conditionsnow.rmspath := private.sitedata.rmspath[iclosest];
    conditionsnow.alpha := private.sitedata.alpha[iclosest]; 
    conditionsnow.p1 := private.sitedata.p1[iclosest];
    conditionsnow.t0 := private.sitedata.t0[iclosest];
    conditionsnow.tau := private.sitedata.tau[iclosest];
    conditionsnow.temp := private.sitedata.temp[iclosest];
    conditionsnow.windv := private.sitedata.windv[iclosest];
    conditionsnow.dtdt := private.sitedata.dtdt[iclosest]; 
    conditionsnow.dvdt := private.sitedata.dvdt[iclosest]; 

    conditionsnow.phasestructure := private.getstructurefunction(conditionsnow ) 


    return ref conditionsnow;
  }
  
  
  # Need to do a better way of fixing in the future
  # Replace tau = -999 with earlier valid values
  
  const private.fixtau := function() {
    wider self, private;
    n := len(private.sitedata.yr);
    lasttau := private.sitedata.tau[1];
    lasttemp := private.sitedata.temp[1];
    lastwindv:= private.sitedata.windv[1];
    lastdtdt := private.sitedata.dtdt[1];
    lastdvdt := private.sitedata.dvdt[1];
    for (i in [2:n]) {
      if (private.sitedata.tau[i] < 0.0) {
	private.sitedata.tau[i] := lasttau;
	private.sitedata.temp[i] := lasttemp;
	private.sitedata.windv[i] := lastwindv;
	private.sitedata.dtdt[i] := lastdtdt;
	private.sitedata.dvdt[i] := lastdvdt;
      } else {
	lasttau := private.sitedata.tau[i];
	lasttemp := private.sitedata.temp[i];
	last:= private.sitedata.windv[i];
	lastdtdt := private.sitedata.dtdt[i];
	lastdvdt := private.sitedata.dvdt[i];
      }
    }
    return T;
  }

  #  ASSUMPTION: freq lies on a grid of [1:1000] GHz
  # If this is not true, we must interpolate, which is not coded now
  const private.readtauterms := function() {
    wider self, private; 
    private.tauterms := [=];
    tab := tablefromascii( private.tautermstable, private.tautermsascii );
    private.tauterms.freq := tab.getcol("FREQ");
    private.tauterms.dry  := tab.getcol("DRY");
    private.tauterms.wet  := tab.getcol("WET");
    private.tauterms.fmin := private.tauterms.freq[1]
    private.tauterms.fmax := private.tauterms.freq[ len(private.tauterms.freq) ]
    tab.done();
    if (  (len(private.tauterms.freq) != 1000) ||
	  (private.tauterms.fmin != 1)         ||
	  (private.tauterms.fmax != 1000)       ) {
	    note('Tau terms table does not meet the assumptions of [1:1000] GHz grid');
	    note('Code will not work as is!  Please create a new ASCII table');
	  }
    return T;
  }

  # get tau from freq & pwv;  assumes [1:1000] GHz grid
  const private.gettau := function(freq='230GHz', pwv='1mm') {
    tau := 0.0;
    q1 := dq.quantity(freq);
    gfreq := dq.convert(q1, 'GHz').value;
    q1 := dq.quantity(pwv);
    mmpwv := dq.convert(q1, 'mm').value;
    if (gfreq < 1.0) {
      tau := 0.0;
    } else if (gfreq <= private.tauterms.fmax) {
      tau := private.tauterms.dry[as_integer(gfreq)] +
      mmpwv * private.tauterms.wet[as_integer(gfreq)];
    }
    return tau;
  }

  # get transmission from freq & pwv
  const private.gettransmission := function(freq='230GHz', pwv='1mm') {
    tau := gettau(freq, pwv);
    trans := 0.0;
    if (tau > 0.0) {
      trans := exp(-tau);
    } else {
      trans := 1.0;
    }
    return trans;
  }

  # get pwv given tau and freq
  # IF wet is very small, return 0.0 for pwv
  const private.getpwv := function(freq='230GHz', tau=0.5) {
    q1 := dq.quantity(freq);
    gfreq := dq.convert(q1, 'GHz').value;
    dry := private.tauterms.dry[as_integer(gfreq)];
    wet := private.tauterms.wet[as_integer(gfreq)];
    pwv := '0.0mm';
    if (wet > 0.000001) {
      mmpwv := ( tau - dry )/ wet;
      pwv := spaste( mmpwv, 'mm' );
    }
    return pwv;
  }
  


#------------------- Time, AZ/EL, etc ---------------------------------------

# convert our fday1 into MJD, name it UTC (precision is not important)
# MJD is returned
  const private.fday2utc := function(fday=0.0) {
    tt := dq.quantity( (49717.0 + fday), 'd');
    myepoch := dm.epoch('utc', tt);
    return ref myepoch;
  }

# convert MJD into fday1
  const private.utc2fday := function(ref myepoch) {
    fday1 := myepoch.m0.value - 49717.0;
    return  fday1;
  }
  
# return a date and time string
  const private.showtime := function(ref myepoch=[=]) {
    dq.time(dm.measure(myepoch, 'utc').m0, form="ymd time")
  }
  
# return LST as a quantity
  const private.getlst := function(ref myepoch=[=]) {
    dm.doframe(myepoch);
    dm.doframe(private.siteposition);
    last := dm.measure(myepoch,'last');
    m0 := 2*pi*(last.m0.value - as_integer(last.m0.value));
    return (ref dq.quantity(m0, 'rad'));
  }
  
# return the elevation as a quantity
  const private.getelevation := function(ref myepoch=[=], ref direction=[=]) {
    dm.doframe(myepoch);
    dm.doframe(private.siteposition);
    azel := dm.measure(direction, 'azel');
    return (ref azel.m1);
  }
  
# return the azimuth as a quantity
  const private.getazimuth := function(ref myepoch=[=], ref direction=[=]) {
    dm.doframe(myepoch);
    dm.doframe(private.siteposition);
    azel := dm.measure(direction, 'azel');
    return (ref azel.m0);
  }
  
  
  
#------------------- Manipulate Schedules ------------------------------------
  
# add this project to the schedule
  const private.addtoschedule := function( ref project, ref timenow, ref dtelapsed, ref dtactual ) {
    wider self, private;
    
    private.schedule.nlist +:= 1;
    listitem := [=];
    listitem.freq := project.freq;
    listitem.direction := project.direction;
    listitem.time := timenow;
    listitem.dtelapsed := dtelapsed;
    listitem.dtactual  := dtactual;
    listitem.status := T;
    
    private.schedule.list[private.schedule.nlist] := listitem;
    return T;
  }
  
# add a blank to the schedule (ie, no project could be found)
  const private.addnulltoschedule := function( ref timenow, ref dtelapsed ) {
    wider self, private;
    
    private.schedule.nlist +:= 1;
    listitem := [=];
    listitem.freq := dq.quantity( 0.0, 'GHz' );
    listitem.direction := dm.direction(private.epoch, '0rad', '0rad');
    listitem.time := timenow;
    listitem.dtelapsed := dtelapsed;
    listitem.dtactual  := dq.quantity(0.0, 'h');
    listitem.status := F;
    
    private.schedule.list[private.schedule.nlist] := listitem;
    return T;
  }
  
  
#------------------- Manipulate projects -------------------------------------
  

# return a vector of project indexes which have not been observed
  const private.getunobservedprojects := function( ref projects=[=],  ref projectlist=[] ){
    newlist := [];
    jj := 0;
    for (ii in projectlist) {
      if(  projects[ii].status != "C" )  {
	jj +:= 1;
	newlist[jj] := ii;
      }
    }
    if ( jj == 0 ) {
      note ('No unobserved projects');
      fail;
    } else {
      return newlist;
    }
  }
  
# return a vector of project indexes which are within dHA of zenith for the
# given LST; -(dHA + bias) through +(dHA - bias)
# inprojects -- record of projects to search
# lst        -- quantity
# dHA        -- quantity
  const private.getneartransit := function (ref projects=[=], lst=[=], dha=[=], bias=[=]) {
    whichone := [];
    distance := [];
    jj := 0;
    dharad := abs( dq.convert( dha, 'rad' ).value );
    lst := dq.convert( lst, 'rad' );
    bias := dq.convert( bias, 'rad' );
    for (ii in [1:projects.nprojects]) {
      project := private.getoneproject( projects, ii );
      qra := dq.convert( project.direction.m0, 'rad' );
      target := dq.convert( dq.add(lst, bias) );
      diff   := dq.convert( dq.abs( dq.sub(target, qra) ) );
      diffrad := dq.convert( dq.norm( diff ), 'rad' ).value;
      if (abs(diffrad) < dharad) {
	jj +:= 1;
	whichone[jj] := ii;
	distance[jj] := abs(diffrad);
      } 
    }
    if (jj > 0) {
       whichonesorted := sort_pair(distance, whichone);
       return ref whichonesorted;
    } else {
      note ('No projects found near transit');
      fail;
    }
  }


# return a single project, fail if not available
# for example, myproject := private.getoneproject(private.projects, 22);
  const private.getoneproject := function(ref projects=[=], iproject=0) {
    if (iproject > projects.nprojects) {
      fail;
    }
    return (ref private.projects[iproject]);
  }

# return a structure of projects, fail if not available
# for example, myprojects := private.getprojects(private.projects, [1,10,22]);
  const private.getprojects := function(ref inprojects=[=], ref iprojects=[]) {
    n := len(iprojects);
    outprojects := [=];
    for (i in [1:n]) {
      p := ref private.getoneproject(inprojects, iprojects[i]);
      if (is_fail(p))  fail;
      outprojects[i] := ref p;
    }
    outprojects.nprojects := n;
    return ref outprojects;
  }

#------------------- Generate projects and distributions ----------------------
  
# make a single project
  const private.makeoneproject := function() 
  {
    project := [=];
    project.rating	:= private.getrating();		# number
    project.freq	:= private.getfreq();		# quantity
    project.direction	:= private.getradec();		# measure
    project.timerequired := private.gettime();		# quantity
    project.timeobserved := dq.quantity( 0.0, 'h');	# quantity
    project.requiredtau	:= 1.0;				# not implemented
    project.requiredphi	:= dq.quantity( 1.0, 'rad');	# not implemented
    project.sigma	:= 0.0 * [1:50];		# vector of noise values, one per obs segment
    project.dimsegments	:= 50;
    project.nsegments	:= 0;
    project.totalsigma	:= 0.0;				# integrated noise
    project.status	:= "P";			        #  P = proposed, U=underway, C=completed
    project.phase	:= -1.0;			# rms phase durng current-subobs
    return ref project;
  }


#--------------------- project distributions -------------------------------------
#  NOTE:  all distributions [time, rating, freq, radec] have:
#         value, probability, cumprobability
#
# ratings have a uniform distribution of integer values ranging from min to max

  const private.makeratingdist := function(ratingmin=1, ratingmax=10) {
    wider self, private;
    private.ratingdist := [=];
    if (ratingmax < ratingmin) {
      ratingmax := ratingmin;
    }
    private.ratingdist.value := [ratingmin:ratingmax];
    private.ratingdist.probability := 0 * [ratingmin:ratingmax] + 1/( ratingmax - ratingmin + 1 );
    private.ratingdist.cumprobability := private.cumulate(private.ratingdist.probability);
    return T
  }

  const private.getrating := function() {
    rating := 0.0;
    zero2one := private.random1();
    ii := private.getprobindex(private.ratingdist.cumprobability, zero2one);
    if (ii > 0) {
      rating := private.ratingdist.value[ii];
    }
    return rating;
  }

# observing time required; this is a Gaussian truncated into integer hours
  const private.maketimedist := function(timemode='5h', timesigma='5h', timemax='25h') {
    wider self, private;
    private.timedist := [=];
    q1 := dq.quantity(timemax);
    hmaxtime := dq.convert(q1, 'h').value;
    q1 := dq.quantity(timemode);
    hmodetime := dq.convert(q1, 'h').value;
    q1 := dq.quantity(timesigma);
    hsigmatime := dq.convert(q1, 'h').value;
    hmaxtime := as_integer( max (1, hmaxtime) );
    hsigmatime := ( max (0.1, hsigmatime) );
    
    private.timedist.value := [1:hmaxtime];
    private.timedist.probability :=  exp(- (((private.timedist.value - hmodetime)/hsigmatime)^2) );
    private.timedist.probability :=  private.timedist.probability /  sum( private.timedist.probability)
    private.timedist.cumprobability := private.cumulate(private.timedist.probability);
    return T;
  }
  const private.gettime := function() {
    time := 0.0;
    zero2one := private.random1();
    ii := private.getprobindex(private.timedist.cumprobability, zero2one);
    if (ii > 0) {
      time := private.timedist.value[ii];
    }
    return ( ref dq.quantity(time, 'h') );
  }


# RA/DEC distribution: currently this is not fully implemented;
# ONLY DEC is implemented here
  const private.makeradecdist := function(decmin='-90deg', decmax='52deg'){
    wider self, private;
    private.radecdist := [=];
    q1 := dq.quantity(decmin);
    ddecmin0 := dq.convert(q1, 'rad').value;
    q1 := dq.quantity(decmax);
    ddecmax0 := dq.convert(q1, 'rad').value;
    ddecmin := min( ddecmin0, ddecmax0 );
    ddecmax := max( ddecmin0, ddecmax0 );
    if (ddecmin == ddecmax) {  # fudge to avoid disaster
			       ddecmax := ddecmax + 0.01;
    }
    private.radecdist.value := [0:100]/100.0 * (ddecmax - ddecmin) + ddecmin;
    private.radecdist.probability := cos( private.radecdist.value );
    private.radecdist.probability := private.radecdist.probability / 
    sum( private.radecdist.probability );
    private.radecdist.cumprobability := private.cumulate(private.radecdist.probability);
    return T;
  }

  const private.getradec := function() {
    ra := spaste( private.random1() * 2.0 * pi, 'rad') ;
    zero2one := private.random1();
    ii := private.getprobindex(private.radecdist.cumprobability, zero2one);	
    dec := '0.0 rad';
    if (ii > 0) {
      dec := spaste( private.radecdist.value[ii], 'rad' );
    }
    direction := dm.direction(private.epoch, ra, dec);
    return ref direction;
  }


# make the frequency distribution
# This is a complete fudge!  For now, say our freq demand is like
# Trans(PWV=1mm)^transexp * (1 + freqwt * (freq/freqmax)^freqexp)
  const private.makefreqdist := function(transexp=2, freqwt=5, freqexp=1.5) {
    wider self, private;
    if (!private.taudatainitialized) {
      note('Need to initialize tau data before a frequency distribution is made');
      fail;
    }
    private.freqdist := [=];
    private.freqdist.value := private.tauterms.freq;
    trans := exp( - (private.tauterms.dry + 1.0 * private.tauterms.wet) );
    private.freqdist.probability := (trans^transexp) * (1 + freqwt * 
						     (private.tauterms.freq/private.tauterms.fmax)^freqexp )
    private.freqdist.probability := private.freqdist.probability / 
    sum( private.freqdist.probability );
    private.freqdist.cumprobability := private.cumulate(private.freqdist.probability);
    return T;
  }

# returns freq as a Quanta
  const private.getfreq := function() {
    freq := 0.0;
    zero2one := private.random1();
    ii := private.getprobindex(private.freqdist.cumprobability, zero2one);
    if (ii > 0) {
      freq := private.freqdist.value[ii];
    }
    return ( ref dq.quantity(freq, 'GHz') );
  }
  
  
#-----------Sensitivity Functions-----------------------------------------------
  

# high level function to get sensitivity

const private.getsensitivity := function( ref conditionsnow, 
				 ref project, 
				 ref lastproject, 
				 ref timenow, 
				 ref dt ) 
{
  
#  still need to consider the source change penalty
				   
  myrec := [=];
  freq := project.freq;
  el := private.getelevation( timenow, project.direction );
  el0 := private.getelevation( timenow, lastproject.direction );
  az := private.getazimuth( timenow, project.direction );
  az0 := private.getazimuth( timenow, lastproject.direction );
  daz := dq.convert(dq.abs( dq.sub( az0, az )), 'deg');
  del := dq.convert(dq.abs( dq.sub( el0, el )), 'deg');
  daz := dq.norm( daz );
  tel := dq.convert( dq.div( del, private.changeinfo.elslewrate), 's');
  taz := dq.convert( dq.div( daz, private.changeinfo.azslewrate), 's');
  tmove := taz;
  if ( tel.value > taz.value) {
    tmove := tel;
  }
  toverhead := dq.add(tmove, private.changeinfo.overhead);
  dt2 := dq.sub( dq.convert(dt, 's'), dq.convert(toverhead, 's') );
  if (dt2.value <= 0.0) {
    note('Trying to calculate sensitivity with dt <= 0.0');
    fail;
  }
  
  t := conditionsnow.temp;
  if (t < -100) t := 0.0;
  tatmos := dq.quantity( (t + 273), 'K');
  tau :=  conditionsnow.tau;
  
  phasestructure := conditionsnow.phasestructure;
  
  sigma := private.getsensitivity2( freq=freq, el=el, dt=dt2, tatmos=tatmos, 
				 phasestructure=phasestructure, tau=tau, 
				 phasecal=private.phasecalinfo.method );
  
  myrec.sigma := sigma;
  myrec.dtelapsed := dt;
  myrec.dtactual  := dt2;
  return myrec;
}

  
# get phase structure function as a record
  
  const private.getstructurefunction := function( ref conditionsnow ) 
  {
    phasestructure := [=];
    fact := (dq.convert(private.seeingbaseline, 'm').value) ^ (conditionsnow.alpha); 
    phasestructure.amp := dq.quantity( (conditionsnow.rmspath / fact), 'um');
    phasestructure.alpha := conditionsnow.alpha;
    return ref phasestructure;
  }
  
  
# lower level function to get sensitivity
  
# given a freq(quanta), an elevation(quanta), a time interval(quanta), a
# phasecal strategy, calculate the
# noise level in Jy and return;
# Fail if el < 0, dt <0
  const private.getsensitivity2 := function( freq=[=], el=[=], dt=[=], tatmos=[=],
				    phasestructure=[=], tau=0.0, phasecal='RADIOMETRIC') 
  {
    sens := private.whichband(freq);
    if (is_fail(sens)) {
      note(paste('No valid band for Freq', freq));
      fail;
    }
    if (is_fail(sens)) fail;	
    
    sinel := sin( dq.convert(el, "rad").value );
    if (sinel <= 0.0) {
      note('Sen elevation <= 0 in getsensitivity2!');
      fail;
    }
    airmass := 1/(sinel);
    
    dtsec := dq.convert(dt, "s").value;
    if (dtsec <= 0.0) {
      note('tsec <= 0 in getsensitivity2!');
      fail;
    }
    
    tatmosk := dq.convert(tatmos, "K").value;
    if (tatmosk <= 0.0) {
      note('Tatmos <= 0.0 in getsensitivity2!');
      fail;
    }

    tsys := dq.convert(sens.tsys, "K").value + tatmosk * (1.0 - exp(-tau*airmass));
    factor := 1.38062e-16 * 1e+23;

    area := (pi/4 * dq.convert( private.sensitivity.diameter, "cm" ).value)^2;
    
    bwhz := dq.convert( sens.bandwidth, "Hz").value;
    
    sigma := tsys * factor / 
    ( sens.efficiency * area * sqrt( private.sensitivity.npol * 
				     private.sensitivity.nbaselines * dtsec * bwhz ) );
    phasefactor := private.phasecalnoise(freq, el, phasestructure, phasecal);
    if ( is_fail(phasefactor) ) fail;
    sigma := sigma * phasefactor;
    
    return sigma;
  }

# given details of the phase calibration, return the increase in
# noise (as a multiplicative factor)
  const private.phasecalnoise := function (freq=[=], el=[=], phasestructure=[=], 
				  phasecal='RADIOMETRIC', scal=1.0, sdist=[=]) 
  {
    rmsphaserad := private.phasecalphase (freq, el, phasestructure, phasecal, scal, sdist);
    if (is_fail( rmsphaserad )) fail;
    decorr := exp( -  (rmsphaserad^2)/2 );
    noiseincrease := 1.0/decorr;
    return noiseincrease;
}
  
# given details of the phase calibration, return the rms phase error
  const private.phasecalphase := function(freq=[=], el=[=], phasestructure=[=], 
				 phasecal='RADIOMETRIC', scal=1.0, sdist=[=])
  {
    amp := dq.convert(phasestructure.amp, "um").value;
    alpha := phasestructure.alpha;
    wavelength := 3e+5 / dq.convert( freq, "GHz" ).value;  # in microns
    
    if ( phasecal=='RADIOMETRIC') {
      sinel := sin( dq.convert(el, "rad").value );
      if (sinel <= 0.0) {
	note('Sen elevation <= 0 in phasecalnoise!');
	fail;
      }
      airmass := 1/(sinel);
      path1 := private.phasecalinfo.radfraclevel * 
      sqrt( airmass ) * amp * 
      (dq.convert(private.phasecalinfo.radtimescale, "s").value *
       dq.convert(private.phasecalinfo.radvelocity, "m/s").value) ^
      alpha;
      
      residualpath := sqrt( path1^2 + (private.phasecalinfo.radbaselevel.value)^2 );
      rmsphaserad  := 2 * pi * residualpath / wavelength;
      return rmsphaserad;
    } else {
      note('Only radiometric phase cal is recognized at this time');
      fail;
    }
  }  
  


# find out which band and return a reference to the appropriate sensitivity record
  const private.whichband := function( freq=[=] ) 
  {
    if (!private.sensitivityinitialized) {
      note('Need to initialize sensitivity record');
      fail;
    }
    if (private.sensitivity.nbands <= 0) {
      note('No bands available in sensitivity record');
      fail;
    }
    freqghz := dq.convert( freq, "GHz" ).value;
    whichone := 0;
    for (i in [1:private.sensitivity.nbands]) {
      freqlowghz := dq.convert(private.sensitivity.bands[i].freqlow, "GHz").value;
      freqhighghz := dq.convert(private.sensitivity.bands[i].freqhigh, "GHz").value;
      if (freqghz >= freqlowghz && freqghz < freqhighghz) {
	whichone := i;
	break;
      }
    }
    if (whichone == 0) {
      note(paste("No sensitivity information for freq = ", freqghz, " GHz"));
      fail;
    }
    return ref private.sensitivity.bands[whichone];
  }

# create the sensitivity record
  const self.initializesensitivity := function() 
  {
    private.sensitivity := F;
    private.sensitivity := [=];
    private.sensitivity.bands := [=];	
    
    self.setsensitivity(dishdiameter='12m', nantennas=64, npol=2);

    i:=0
    sens := [=];
    sens.band := 'band1';
    sens.freqlow := dq.quantity(30, 'GHz');
    sens.freqhigh := dq.quantity(50, 'GHz');
    sens.tsys :=  dq.quantity(25, 'K');       # not including atmosphere
    sens.efficiency :=  0.80;
    i +:=1;
    private.sensitivity.bands[i] := ref sens;
    
    sens := F;
    sens := [=];
    sens.band := 'band2';
    sens.freqlow := dq.quantity(60, 'GHz');
    sens.freqhigh := dq.quantity(90, 'GHz');
    sens.tsys :=  dq.quantity(30, 'K');       # not including atmosphere
    sens.efficiency :=  0.80;
    i +:=1;
    private.sensitivity.bands[i] := sens;
    
    sens := F;
    sens := [=];
    sens.band := 'band3';
    sens.freqlow := dq.quantity(90, 'GHz');
    sens.freqhigh := dq.quantity(115, 'GHz');
    sens.tsys :=  dq.quantity(35, 'K');       # not including atmosphere
    sens.efficiency :=  0.80;
    i +:=1;
    private.sensitivity.bands[i] := sens;
    
    sens := F;
    sens := [=];
    sens.band := 'band4';
    sens.freqlow := dq.quantity(115, 'GHz');
    sens.freqhigh := dq.quantity(150, 'GHz');
    sens.tsys :=  dq.quantity(40, 'K');       # not including atmosphere
    sens.efficiency :=  0.80;
    i +:=1;
    private.sensitivity.bands[i] := sens;
    
    sens := F;
    sens := [=];
    sens.band := 'band5';
    sens.freqlow := dq.quantity(150, 'GHz');
    sens.freqhigh := dq.quantity(200, 'GHz');
    sens.tsys :=  dq.quantity(50, 'K');       # not including atmosphere
    sens.efficiency :=  0.80;
    i +:=1;
    private.sensitivity.bands[i] := sens;
    
    sens := F;
    sens := [=];
    sens.band := 'band6';
    sens.freqlow := dq.quantity(200, 'GHz');
    sens.freqhigh := dq.quantity(270, 'GHz');
    sens.tsys :=  dq.quantity(90, 'K');       # not including atmosphere
    sens.efficiency :=  0.80;
    i +:=1;
    private.sensitivity.bands[i] := sens;
    
    sens := F;
    sens := [=];
    sens.band := 'band7';
    sens.freqlow := dq.quantity(270, 'GHz');
    sens.freqhigh := dq.quantity(350, 'GHz');
    sens.tsys :=  dq.quantity(120, 'K');       # not including atmosphere
    sens.efficiency :=  0.75;
    i +:=1;
    private.sensitivity.bands[i] := sens;
    
    sens := F;
    sens := [=];
    sens.band := 'band8';
    sens.freqlow := dq.quantity(350, 'GHz');
    sens.freqhigh := dq.quantity(430, 'GHz');
    sens.tsys :=  dq.quantity(180, 'K');       # not including atmosphere
    sens.efficiency :=  0.70;
    i +:=1;
    private.sensitivity.bands[i] := sens;
    
    sens := F;
    sens := [=];
    sens.band := 'band9';
    sens.freqlow := dq.quantity(430, 'GHz');
    sens.freqhigh := dq.quantity(650, 'GHz');
    sens.tsys :=  dq.quantity(220, 'K');       # not including atmosphere
    sens.efficiency :=  0.65;
    i +:=1;
    private.sensitivity.bands[i] := sens;
    
    sens := F;
    sens := [=];
    sens.band := 'band10';
    sens.freqlow := dq.quantity(650, 'GHz');
    sens.freqhigh := dq.quantity(1000, 'GHz');
    sens.tsys :=  dq.quantity(300, 'K');       # not including atmosphere
    sens.efficiency :=  0.60;
    i +:=1;
    private.sensitivity.bands[i] := sens;
    
    private.sensitivity.nbands := i;
    private.sensitivity.diameter := dq.quantity(12.0, "m");
    private.sensitivity.npol := 2;
    private.sensitivity.nants := 64;
    private.sensitivity.nbaselines := 64*63/2;
    private.sensitivityinitialized := T;

    return T;
  }
  
# add the sensitivity to this project, return integrated sensitivity
# sigma is a quantity, in units of "Jy".
  const private.addsensitivity := function ( ref project=[=], sigma=[=], dt=[=] ) {
    wider self, private;
    project.timeobserved := dq.add(project.timeobserved, dq.convert(dt, "h")) ;
    if (project.timeobserved.value >= project.timerequired.value) {
      project.status := "C";
    } else {
      project.status := "U";
    }
    
    if (project.nsegments >= project.dimsegments) {
      note ('Observed segments has exceeded the dimension of the project in sensadd!');
      fail;
    }
    if (sigma == 0) {
      note('sigma == 0 in sensadd, not allowed');
      fail;
    }
    project.nsegments +:= 1;
    project.sensitivity[project.nsegments] := sigma;
    
    myvec := project.sensitivity[1:project.nsegments];
    myvec2 := 1/(myvec^2);
    project.totalsensitivity := sqrt(1.0/sum(myvec2));
    return  project.totalsensitivity;
  }
  

#-----------Sumarize Projects----------------------------------------------------

# summarize frequency distribution
  const private.sumarizefreqs := function(freqres=20) {
    wider self, private;
    if (freqres <= 1) freqres := 1;
    nbins := private.tauterms.fmax / freqres;
    if (private.pg == F) private.pg := pgplotter()
    private.pg.page();
#	private.pg.save();
    
    freqs := [1:private.projects.nprojects];
    for (i in  [1:private.projects.nprojects]) {
      freqs[i] := dq.convert( private.projects[i].freq, "GHz").value;
    }
    private.pg.hist(data=freqs, datmin=0.0, datmax=private.tauterms.fmax,
		 nbin=nbins, pgflag=0);
  }

# summarize time distribution
  const private.sumarizetime := function( timeres=1 ) {
    wider self, private;
    if (timeres <= 1) timeres := 1;
    
    if (private.pg == F) private.pg := pgplotter()
    private.pg.page();
#	private.pg.save();
    
    times := [1:private.projects.nprojects];
    for (i in  [1:private.projects.nprojects]) {
      times[i] := dq.convert( private.projects[i].timerequired, "h").value;
    }
    nbins := max(times)/timeres;
    private.pg.hist(data=times, datmin=0.0, datmax=max(times),
		 nbin=nbins, pgflag=0);
  }
  

#-----------MISC Helper Functions------------------------------------------------

# unwrap an angle
# return unwrapped angle
  const private.unwrap := function( ref myangle=[=] ) {
    myangledeg := dq.convert( myangle, 'deg' ).value;
    if (myangledeg > 0) {
      myangledeg := private.mod( (myangledeg+180), 360) -180;
      return (dq.quantity( myangledeg, 'deg'));
    } else {
      myangledeg := private.mod( (myangledeg-180), 360) +180;
      return (dq.quantity( myangledeg, 'deg'));
    }
  }

# x modulo y
  const private.mod := function( x, y ) {
    n := as_integer ( x/y );
    return (x - n*y);
  }

# get the index of a cumulative probability (bad description)
  const private.getprobindex := function( ref cumprob=[], zero2one=0.0 ) {
    ii := 0;
    for (i in [1:(len(cumprob))]) {
      if (cumprob[i] > zero2one) {
	ii := i;
	break;
      }
    }
    return ii;
  }

# get a random number from 0.0 to 1.0
  const private.random1 := function() {
    return ( random()/ (2^31) );
  }
  
# cumulate probability: just a helper function
  const private.cumulate := function( ref prob=[]) {
    cumprob := prob;
    cumprob[1] := prob[1];
    n := len(prob);
    for (i in [2:n]) {
      cumprob[i] := cumprob[i-1] + prob[i];
    }
    return ref cumprob;
  }
  
# turn a record into a table
  const private.record2table := function( ref myrecord=[=], tablename='', type='unknown' ){
    myrecord.type := type;
    scd:=tablecreatescalarcoldesc("dummy",[=]);
    td:=tablecreatedesc(scd);
    tab:=table(tablename, tabledesc=td, nrow=0)
    tab.putkeyword("datarecord", myrecord);
    tab.done();
    return T;	
  }
  
# read in a record from a table,  return it
# fails if not in our format (ie, record in a keyword called "datarecord")
  const private.table2record := function( tablename='', type='') {
    tab:=table(tablename);
    myrecord := tab.getkeyword("datarecord");
    if (is_fail(myrecord)) {
      note(paste("Failed to read table", tablename));
      fail;
    }
    if (type != '') {
      if (myrecord.type != type) {
	note(paste("table", tablename, "is not of correct type", type));
	fail;
      }
    }	
    tab.done();
    
    return ref myrecord;
  }

}
# end of constructor



