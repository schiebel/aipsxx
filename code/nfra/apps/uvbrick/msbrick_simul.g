# msbrick_simul.g: uvbrick simulation support for msbrick
# J.E.Noordam, oct 1998

# Copyright (C) 1996,1997,1998,1999
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

#---------------------------------------------------------


pragma include once
# print 'include msbrick_simul.g  w01sep99'

include 'msbrick_select.g';

# include 'tracelogger.g';
# include 'textformatting.g';
# include 'uvbrick.g';		# uvdata-bricks 


#=========================================================
test_msbrick_simul := function () {
    msbsim := msbrick_simul();
    return ref msbsim;
};

#=========================================================
msbrick_simul := function (context='WSRT') {
    private := [=];
    public := [=];

    private.context := context;				# input argument

    private.init := function() {
	wider private;
	private.pi := acos(-1);				# 3.14....
	private.deg2rad := private.pi/180.0;		# conversion factor
	private.rad2deg := 1.0/private.deg2rad;		# conversion factor
    	public.init_simavail('WSRT');
	private.msb_select := msbrick_select(private.context);	
	# private.uvbrick := uvbrick();	  # empty brick, for functions only;
    }


#=========================================================
# Public interface:

    public.agent := create_agent();	# communication




#=======================================================================
# The available antennas etc for WSRT, VLA, ATCA etc:

    public.init_simavail := function (tel_name='WSRT') {
	wider private;
	private.simavail := [=];
	if (tel_name=='WSRT') {
	    ant_shortname := "0 1 2 3 4 5 6 7 8 9 A B C D";
	    ant_id1 := ind(ant_shortname);          # one-relative
	    for (i in ind(ant_shortname)) {
	    	ant_name[i] := spaste('WSRT',ant_shortname[i]);
	    }
	    ant_pos1D := (ind(ant_shortname)-1)*144;     # default...
	    pol_name := "X Y";
	    pol_code := [-1,-1];
	} else {
	    print '***init_simavail: not recognised:',tel_name;
	    return F;
	}

	private.simavail.tel_name := tel_name;
	private.simavail.ant_id1 := ant_id1;
	private.simavail.ant_pos1D := ant_pos1D;
	private.simavail.ant_name := ant_name;
	private.simavail.ant_shortname := ant_shortname;
	private.simavail.pol_name := pol_name;
	private.simavail.pol_code := pol_code;
	private.simavail.ifr_number := [];
	private.simavail.ifr_name := ' ';
	private.simavail.ifr_shortname := ' ';
	nant := len(ant_name);				# nr of available ants	
	nifr := 0;					# nr of available ifrs
	for (iant1 in [1:nant]) {			# include auto-corrs
	    for (iant2 in [iant1:nant]) {
		nifr +:= 1;
		private.simavail.ifr_number[nifr] := iant2 + 1000*iant1;
		private.simavail.ifr_name[nifr] := spaste(
				ant_name[iant1],'-',ant_name[iant2]) 
		private.simavail.ifr_shortname[nifr] := spaste(
				ant_shortname[iant1],ant_shortname[iant2]) 
	    }
	}
	if (tel_name=='WSRT') {
	    public.set_simavail_sep9A();		# 72 m
	} else {
	    public.update_simavail_basel();		# private.simavail.basel
	}
	return T;
    }

    public.get_simavail := function (fname) {
	if (has_field(private.simavail, fname)) {
	    return private.simavail[fname];
	} else {
	    print 'getsimavail: not recognised:',fname; 	
	}
	return F;
    }

    public.update_simavail_basel := function (rms_pos=0.001) {
	wider private;
	ifr_number := private.simavail.ifr_number;
	ant_pos1D := private.simavail.ant_pos1D;
	if (rms_pos>0) {				# rms pos errors
	    ant_pos1D +:= public.gaussnoise(len(ant_pos1D), rms=rms_pos, mean=0.0);

	    private.simavail.ant_pos1D := ant_pos1D;
	}
	basel := ind(ifr_number);
	for (ifr in ind(ifr_number)) {
	    iant2 := ifr_number[ifr]%1000;		# one-relative
	    iant1 := (ifr_number[ifr]-iant2)/1000;	# one-relative
	    # print 'ifr=',ifr,ifr_number[ifr],iant1,iant2;
	    basel[ifr] := ant_pos1D[iant2] - ant_pos1D[iant1]; 
	}
	private.simavail.basel := basel;		# updated
	return T;
    }

    public.set_simavail_sep9A := function (sep9A=72) {
	wider private;
	# print 'set_simavail_sep9A:',sep9A; 
	if (private.simavail.tel_name != 'WSRT') {
	    print '*** private.set_simavail_sep9A: only valid for WSRT'
	    return F;
	}	
	nant := len(private.simavail.ant_name);
	ant_pos1D := rep(-1,nant);			# incl E/F
	ant_pos1D[1:10] := [0:9]*144;
	ant_pos1D[11] := ant_pos1D[10] + sep9A;		# 9A
	ant_pos1D[12] := ant_pos1D[11] + 72;
	ant_pos1D[13] := ant_pos1D[10] + (ant_pos1D[11]-ant_pos1D[1]); 	# 9C=0A
	ant_pos1D[14] := ant_pos1D[13] + 72;
	private.simavail.ant_pos1D := ant_pos1D;		# updated
	public.update_simavail_basel();
	return T;
    }

#---------------------------------------------------------------------------

    public.decode_ifrs := function (ifrs, test=F) {
	ifr_number := public.get_simavail('ifr_number');
	basel := public.get_simavail('basel');
	tel_name := public.get_simavail('tel_name');
    	return private.msb_select.decode_ifrs(ifrs, ifr_number, 
					      basel, test, tel_name);
    }

#---------------------------------------------------------------------------

    public.decode_ants := function (ants, test=F) {
	ant_id1 := public.get_simavail('ant_id1');
	antpos := public.get_simavail('ant_pos1D');
	tel_name := public.get_simavail('tel_name');
    	return private.msb_select.decode_ants(ants, ant_id1, 
					      antpos, test, tel_name);
    }


#---------------------------------------------------------------------------
# Actually fill the given (empty) antbrick, as specified by the record simrec:
# NB: An antbrick is a special version of am uvbrick, with antenna-related
#     data rather than uv-data.
 
    public.simulate_antbrick := function (ref antbrick, simrec, trace=F) {
	
	simrec.ants := public.decode_ants(simrec.ants).subset;

	antbrick.addtohistory('Simulated antenna-data:');
	for (fname in field_names(simrec)) {
	    s := spaste(' - simrec.',fname,':');
	    s := paste(s,simrec[fname]);
	    if (trace) print s;
	    antbrick.addtohistory(s);
	}

	aux := [=];					# auxiliary info
	antbrick.addtoaux (aux, 'tel_name', 'WSRT');		
	antbrick.addtoaux (aux, 'msname', '<noMS>');		
	antbrick.addtoaux (aux, 'spectral_window_id', 1);		
	antbrick.addtoaux (aux, 'array_id', 1);		

	antbrick.addtoaux (aux, 'data_descr', 
			   'simulated ant-data');    
	antbrick.addtoaux (aux, 'data_unit', ' ');      # ....?

	msrec := [=];
	msrec.axis_info := [=];

	axes := 'pol';
	if (trace) print axes;
	msrec.axis_info.pol_axis := [=];
	avpol_name := public.get_simavail('pol_name');  # available pols
	avpol_code := public.get_simavail('pol_code');
	sv := rep(F,2);                                 # selection vector
	for (i in ind(avpol_name)) {
	    if (any(avpol_name[i]==simrec.pols)) sv[i] := T;
	}
	npol := len(sv[sv]);
	if (trace) print 'sv=',sv,' npol=',npol;
	msrec.axis_info.pol_axis.pol_name := avpol_name[sv];	
	msrec.axis_info.pol_axis.pol_code := avpol_code[sv];	


	axes := 'ant';
	if (trace) print axes; 
	avant_id1 := public.get_simavail('ant_id1'); # available ants
	if (trace) print 'simrec.ants  =',simrec.ants;
	if (trace) print 'avant_id1=',avant_id1;
	sv := rep(F,len(avant_id1));                 # selection vector
	for (i in ind(avant_id1)) {
	    if (any(avant_id1[i]==simrec.ants)) sv[i] := T;
	}
	nant := len(sv[sv]);				# nr of ants in sub-set
	if (trace) print 'sv=',sv,'nant=',nant;
	msrec.axis_info.ant_axis := [=];
	for (fname in "ant_id1 ant_shortname ant_name ant_pos1D") {
	    vv := public.get_simavail(fname);
	    if (trace) print '-',fname,type_name(vv),len(vv);
	    msrec.axis_info.ant_axis[fname] := vv[sv];	# selection
	}	

	axes := "time";
	if (trace) print axes;
	ntime := max(1,as_integer(simrec.HAdeg[1]));	# nr of time-slots
	if (len(simrec.HAdeg)<4) simrec.HAdeg[4] := simrec.HAdeg[3];
	hadeg := simrec.HAdeg[2] + [0:(ntime-1)]*simrec.HAdeg[4];
	secs := (hadeg - hadeg[1]) * 240;		# 1 degr = 4 min
	inttime := rep(simrec.HAdeg[3]*240,ntime);	# sec
	msrec.axis_info.time_axis := [=];
	msrec.axis_info.time_axis.HA := hadeg;		# deg
	spd := 24 * 3600.0;				# sec/day
	MJDsec97 := 50448.0 * spd;			# 0 January 1997
	msrec.axis_info.time_axis.MJDseconds := MJDsec97 + 400*spd + secs;
	msrec.axis_info.time_axis.UT := secs;		# sec?
	msrec.axis_info.time_axis.LAST := secs;		# sec?
	antbrick.addtoaux (aux, 'inttime', inttime, axes);		

	axes := 'freq';
	if (trace) print axes;
	nfreq := max(1,as_integer(simrec.fMHz[1]));	# nr of freq channels
	wfreq := rep(1.0,nfreq);			# freq weights
	if (simrec.bandpass) {
	    antbrick.addtohistory('bandpass');  
	    width := min(5,1+as_integer(nfreq/2));	# gaussian half-width 
	    k := 1 + as_integer(3*width);
	    if (k>nfreq) {
		print 'too few freq channels: no bandpass simulated!';
		break;
	    }
	    # if (trace) print 'bandpass: width=',width,k;
	    for (i in [1:k]) {
	    	w := exp(-(((i-k)/width)^2));		# gaussian edge
	    	w := max(w,0.1);			# limit
	    	wfreq[i] *:= w;
	    	wfreq[nfreq-i+1] *:= w;
	    }
	    if (simrec.centralpeak) {
		print '*** central peak in bandpass not yet supported'
	    }
	} 
	if (len(simrec.fMHz)<4) simrec.fMHz[4] := simrec.fMHz[3]; 
	freqMHz := simrec.fMHz[2] + simrec.fMHz[4]*[0:(nfreq-1)];
	bwMHz := array(simrec.fMHz[3],nfreq);
	msrec.axis_info.freq_axis := [=];
	msrec.axis_info.freq_axis.chan_freq := 1e6 * freqMHz;
	msrec.axis_info.freq_axis.resolution := 1e6 * bwMHz;

	axes := "field";
	if (trace) print axes;
	nfield := 1;
	antbrick.addtoaux (aux, 'field_id', seq(nfield), axes);		
	antbrick.addtoaux (aux, 'field_ids', rep(1,ntime), 'time');
	antbrick.addtoaux (aux, 'field_name', 'dummy', axes);		
	# antbrick.addtoaux (aux, 'DECdeg', 45, axes);		
	# antbrick.addtoaux (aux, 'RAdeg', 45, axes);		
	# antbrick.addtoaux (aux, 'sinDEC', sin(simrec.DECdeg * private.deg2rad));

	axes := "pol freq ant time";
	if (trace) print axes; 
	datashape := [npol,nfreq,nant,ntime];
	zero := complex(0.0);                  # complex data
	zero := 0.0;                           # real data
	msrec.data := array(zero,npol,nfreq,nant,ntime);
	for (iant in [1:nant]) {
	    for (ipol in [1:npol]) {
		vv := iant*seq(ntime)/ntime;   # dummy data (linear)
		if (ipol>1) vv := -vv;         # negative, descending  
		msrec.data[ipol,1,iant,] := vv;
	    }
	}

	msrec.flag := array(F,npol,nfreq,nant,ntime);
	# msrec.weight := array(1.0,npol,nfreq,nant,ntime);	# 4D weights?
	msrec.weight := array(1.0,ntime);			# 1D weights?

	antbrick.fill_antbrick (msrec, aux);		# fill the given antbrick
	return T;
    }

#---------------------------------------------------------------------------
# Actually fill the given (empty) uvbrick, as specified by the record simrec:
 
    public.simulate_uvbrick := function (ref uvbrick, simrec, trace=F) {
	
	simrec.ifrs := public.decode_ifrs(simrec.ifrs).subset;

	uvbrick.addtohistory('Simulated uv-data:');
	for (fname in field_names(simrec)) {
	    s := spaste(' - simrec.',fname,':');
	    s := paste(s,simrec[fname]);
	    if (trace) print s;
	    uvbrick.addtohistory(s);
	}

	aux := [=];					# auxiliary info
	uvbrick.addtoaux (aux, 'tel_name', 'WSRT');		
	uvbrick.addtoaux (aux, 'msname', '<noMS>');		
	uvbrick.addtoaux (aux, 'spectral_window_id', 1);		
	uvbrick.addtoaux (aux, 'array_id', 1);		

	uvbrick.addtoaux (aux, 'data_descr', 
			  'simulated uv-data'); 
	uvbrick.addtoaux (aux, 'data_unit', 'corr.coeff');        

	msrec := [=];
	msrec.axis_info := [=];

	axes := 'corr';
	if (trace) print axes; 
	ncorr := len(simrec.corrs);
	msrec.axis_info.corr_axis := simrec.corrs;		# e.g. "XX YY"

	axes := 'pol';
	if (trace) print axes; 
	pol_name := public.get_simavail('pol_name');
	pol_code := public.get_simavail('pol_code');
	uvbrick.addtoaux (aux, 'pol_name', pol_name, axes);	# first!	
	uvbrick.addtoaux (aux, 'pol_code', pol_code, axes);	

	axes := "time";
	if (trace) print axes;
	ntime := max(1,as_integer(simrec.HAdeg[1]));		# nr of time-slots
	if (len(simrec.HAdeg)<4) simrec.HAdeg[4] := simrec.HAdeg[3];
	hadeg := simrec.HAdeg[2] + [0:(ntime-1)]*simrec.HAdeg[4];
	secs := (hadeg - hadeg[1]) * 240;			# 1 degr = 4 min
	inttime := rep(simrec.HAdeg[3]*240,ntime);		# sec
	msrec.axis_info.time_axis := [=];
	msrec.axis_info.time_axis.HA := hadeg;			# deg
	spd := 24 * 3600.0;					# sec/day
	MJDsec97 := 50448.0 * spd;				# 0 January 1997
	msrec.axis_info.time_axis.MJDseconds := MJDsec97 + 400*spd + secs;
	msrec.axis_info.time_axis.UT := secs;			# sec?
	msrec.axis_info.time_axis.LAST := secs;			# sec?
	uvbrick.addtoaux (aux, 'inttime', inttime, axes);		

	axes := "field";
	if (trace) print axes; 
	nfield := len(simrec.DECdeg);				
	fields := ' '
	field_ids := rep(nfield,ntime);
	ntpf := max(1,as_integer(ntime/nfield));		# time-slots/field 
	for (i in ind(simrec.DECdeg)) {
	    fields[i] := spaste('DEC',simrec.DECdeg[i]);	# default name
	    k1 := 1+(i-1)*ntpf;
	    k2 := min(ntime,(i*ntpf));
	    field_ids[k1:k2] := rep(i,k2-k1+1);
	}
	simrec.RAdeg := ind(simrec.DECdeg);			# temporary...!
	uvbrick.addtoaux (aux, 'field_id', ind(fields), axes);		
	uvbrick.addtoaux (aux, 'field_ids', field_ids, 'time');	# axes=time!	
	uvbrick.addtoaux (aux, 'field_name', fields, axes);		
	uvbrick.addtoaux (aux, 'DECdeg', simrec.DECdeg, axes);		
	uvbrick.addtoaux (aux, 'RAdeg', simrec.RAdeg, axes);		
	# uvbrick.addtoaux (aux, 'sinDEC', sin(simrec.DECdeg * private.deg2rad));

	axes := 'ifr';
	if (trace) print axes; 
	nifr := 0;
	ifr_name := ' ';
	ifr_shortname := ' ';
	ifr_baseline := [];
	ifr_number := simrec.ifrs;			# specified ifr_nrs
	avifr_number := public.get_simavail('ifr_number');	# available
	avifr_name := public.get_simavail('ifr_name');		# available
	avifr_shortname := public.get_simavail('ifr_shortname');# available
	avifr_baseline := public.get_simavail('basel');	# available
	aviant := rep(F,len(public.get_simavail('ant_name')));	# ALL array ants
	ii := ind(avifr_number);			# ifr_number indices
	for (ifrnr in ifr_number) {
	    ifrindex := ii[avifr_number==ifrnr];	# index in available
	    nifr +:= 1;					# increment
	    iant2 := ifr_number[nifr]%1000;		# one-relative
	    iant1 := (ifr_number[nifr]-iant2)/1000;	# one-relative
	    # if (trace) print nifr,'ifrnr=',ifrnr,'index=',
	    #                  ifrindex,'id12=',iant1,iant2;
	    aviant[iant1] := T;
	    aviant[iant2] := T;
	    ifr_name[nifr] := avifr_name[ifrindex];
	    ifr_shortname[nifr] := avifr_shortname[ifrindex];
	    ifr_baseline[nifr] := avifr_baseline[ifrindex];
	}
	msrec.axis_info.ifr_axis := [=];
	msrec.axis_info.ifr_axis.ifr_number := ifr_number;
	msrec.axis_info.ifr_axis.ifr_name := ifr_name;
	msrec.axis_info.ifr_axis.ifr_shortname := ifr_shortname;
	msrec.axis_info.ifr_axis.baseline := ifr_baseline;


	axes := 'ant';
	if (trace) print axes;
	# ii := ind(aviant)[aviant];			# indices of sub-set
	ii := ind(aviant);				# indices of ALL!
	nant := len(ii);				# nr of ants in sub-set
	if (trace) print 'nant=',nant,'ii=',ii;
	for (fname in "ant_id1 ant_shortname ant_name ant_pos1D") {
	    vv := public.get_simavail(fname)[ii];
	    uvbrick.addtoaux (aux, fname, vv, axes);
	}	

	axes := "ant time";
	if (trace) print axes;
	ant_RAdeg := ant_DECdeg := array(0.0,nant,ntime);
	for (ifield in [1:nfield]) {
	    sv := [field_ids==ifield];			# selection vector
	    ant_DECdeg[,sv] := simrec.DECdeg[ifield];	# same for all ants
	    ant_RAdeg[,sv] := simrec.RAdeg[ifield];	# same for all ants
	}
	uvbrick.addtoaux (aux, 'ant_RAdeg', ant_RAdeg, axes, 
			  kind='coord', unit='deg');
	uvbrick.addtoaux (aux, 'ant_DECdeg', ant_DECdeg, axes, 
			  kind='coord', unit='deg');

	# pointing....?


	axes := 'freq';
	if (trace) print axes; 
	nfreq := max(1,as_integer(simrec.fMHz[1]));	# nr of freq channels
	wfreq := rep(1.0,nfreq);			# freq weights
	if (simrec.bandpass) {
	    uvbrick.addtohistory('bandpass');  
	    width := min(5,1+as_integer(nfreq/2));	# gaussian half-width 
	    k := 1 + as_integer(3*width);
	    if (k>nfreq) {
		print 'too few freq channels: no bandpass simulated!';
		break;
	    }
	    # if (trace) print 'bandpass: width=',width,k;
	    for (i in [1:k]) {
	    	w := exp(-(((i-k)/width)^2));		# gaussian edge
	    	w := max(w,0.1);			# limit
	    	wfreq[i] *:= w;
	    	wfreq[nfreq-i+1] *:= w;
	    }
	    if (simrec.centralpeak) {
		print '*** central peak in bandpass not yet supported';
	    }
	} 
	if (len(simrec.fMHz)<4) simrec.fMHz[4] := simrec.fMHz[3]; 
	freqMHz := simrec.fMHz[2] + simrec.fMHz[4]*[0:(nfreq-1)];
	bwMHz := array(simrec.fMHz[3],nfreq);
	msrec.axis_info.freq_axis := [=];
	msrec.axis_info.freq_axis.chan_freq := 1e6 * freqMHz;
	msrec.axis_info.freq_axis.resolution := 1e6 * bwMHz;

	axes := "ifr time";
	if (trace) print axes; 
	ww := vv := uu := array(0,nifr,ntime);
	harad := hadeg * private.deg2rad;		# HA (rad)
	sinDEC := sin(simrec.DECdeg[field_ids] * private.deg2rad);
	cosDEC := cos(simrec.DECdeg[field_ids] * private.deg2rad);
	for (i in seq(nifr)) {
	    uu[i,] := cos(harad) * ifr_baseline[i];				
	    vv[i,] := sinDEC * sin(harad) * ifr_baseline[i];
	    # ww[i,] := cosDEC * sin(harad) * ifr_baseline[i];
	}
	uvbrick.addtoaux (aux, 'ifr_ucoord', uu, axes, kind='coord');		
	uvbrick.addtoaux (aux, 'ifr_vcoord', vv, axes, kind='coord');		
	# uvbrick.addtoaux (aux, 'ifr_wcoord', ww, axes, kind='coord');		


	axes := "corr freq ifr time";
	if (trace) print axes; 
	datashape := [ncorr,nfreq,nifr,ntime];
	if (simrec.source=='testdata_complex') {
	    msrec.data := private.testarr(datashape, type='complex');
	    uvbrick.addtohistory(paste(simrec.source,datashape));
	} else if (simrec.source=='testdata_real') {
	    msrec.data := private.testarr(datashape, type='real');
	    uvbrick.addtohistory(paste(simrec.source,datashape));

	} else {					# simulated uvdata
	    minbasel := max(1.0,min(ifr_baseline));	# minimum baseline (m)
	    meanfMHz := sum(freqMHz)/len(freqMHz);	# mean frequency (MHz)
	    alpha := 2e5 * (300.0/(meanfMHz*minbasel));	# arcsec
	    s := paste('simulate: minbasel(m)=',minbasel);
	    s := paste(s,'  meanfMHz=',meanfMHz,' sinDEC=',sinDEC);
	    s := paste(s,'  alpha(arcsec)=',alpha);
	    lm_close := 0.1 * [alpha, alpha/sinDEC];
	    lm_far := 2 * [alpha, alpha/sinDEC];
	    compon := [=];
	    compon[1] := [=];
    	    compon[1].iquv := private.msb_select.decode_calibrator (
					simrec.flux_IQUV, 
					fMHz=sum(freqMHz)/nfreq);
	    compon[1].lm := [0.0,0.0];			# central (l=m=0)
	    s := paste('simulated source:',simrec.source, simrec.flux_IQUV);
	    if (simrec.source=='point_central') {
		# OK, default, do nothing
	    } else if (simrec.source=='point_close') {
	    	compon[1].lm := lm_close;
	    } else if (simrec.source=='point_far') {
	    	compon[1].lm := lm_far;
	    } else if (simrec.source=='double_close') {
	    	compon[2] := compon[1];			# copy
	    	compon[2].iquv *:= [0.1,0,0,0];		# unpolarised
	    	compon[2].lm := 0.9 * lm_close;
	    	compon[1].lm := -0.1 * lm_close;
	    } else if (simrec.source=='double_far') {
	    	compon[2] := compon[1];			# copy
	    	compon[2].iquv *:= [0.1,0,0,0];		# unpolarised
	    	compon[2].lm := 0.9 * lm_far;
	    	compon[1].lm := -0.1 * lm_far;
	    } else if (simrec.source=='double_equal') {
	    	compon[2] := compon[1];			# copy
	    	compon[2].iquv *:= [1,0,0,0];		# unpolarised
	    	compon[2].lm := 0.7 * lm_far;
	    	compon[1].lm := -0.3 * lm_far;
	    } else if (simrec.source=='extended_just') {
		s1 := 'not supported yet, will use central point source...';
		s := paste(s,':',s1);
	    } else if (simrec.source=='extended_very') {
		s1 := 'not supported yet, will use central point source...';
		s := paste(s,':',s1);
	    } else {
		s1 := 'not supported yet, will use central point source...';
		s := paste(s,':',s1);
	    }
	    uvbrick.addtohistory(s);

	    for (i in ind(compon)) {
		s := paste('simulated source component',i);
		s := paste(s,'iquv=',compon[i].iquv,'lm=',compon[i].lm);
		uvbrick.iquv2corr (compon[i], simrec.corrs, trace=F);
		# print '\n',s,'compon[i]=',compon[i],'\n';   # temporary
		for (k in ind(compon[i].corrs)) {
		    s := spaste(s,'\n  ',compon[i].corrs[k],'=',compon[i].xyrl[k]);
		    # print s;
		}
	    	uvbrick.addtohistory(s);
	    }

	    pi2 := private.pi^2;			# pi squared
	    q := 2 * pi2 / (300.0 * 3600.0 * 180.0);	# factor
	    msrec.data := array(complex(0.0),ncorr,nfreq,nifr,ntime);
	    for (ifreq in seq(nfreq)) {
	    	for (icomp in ind(compon)) {
		    pp := uu*compon[icomp].lm[1];	# u(m)*l(arcsec)
		    pp +:= vv*compon[icomp].lm[2];	# v(m)*m(arcsec)
		    pp *:= q * freqMHz[ifreq];		# f(MHz)
		    cc := complex(cos(pp),sin(pp));	#
		    # s := paste(ifreq,icomp,q,freqMHz[ifreq])
		    # s := paste(s,'cc:',type_name(cc),shape(cc)); 
		    # s := paste(s,'pp:',type_name(pp),shape(pp));
		    # if (trace) print s; 
		    for (icorr in seq(ncorr)) {
			xyrl := compon[icomp].xyrl[icorr];
			if (abs(xyrl) != 0) {
			    msrec.data[icorr,ifreq,,] +:= xyrl * cc;
			}
		    }
		}
		msrec.data[,ifreq,,] *:= wfreq[ifreq];	# bandpass
	    }
	}

	# Convert Jy to corr.coeff (i.e. correlated fractions):
	# NB: Only correct if Tsys>>Tant
	msrec.data *:= (simrec.sensitivity/simrec.Tsys);

	meanabs := sum(abs(msrec.data))/len(msrec.data);

	msrec.flag := array(F,ncorr,nfreq,nifr,ntime);
	# msrec.weight := array(1.0,ncorr,nfreq,nifr,ntime);	# 4D weights?
	msrec.weight := array(1.0,ntime);			# 1D weights?

	uvbrick.fill (msrec, aux);			# fill the given uvbrick
	return T;
    }


# Helper function: make a test-array (see .simulate_xxx()):

    private.testarr := function(dim, type='real', trace=F) {
	if (trace) print '---- testarr: dim=',dim,'type=',type;
	zero := 0.0;
	if (type=='complex') zero := complex(0,0);
	testarr := array(zero,prod(dim));
	testarr::shape := dim;
	for (idim in ind(dim)) {
	    index := [=];
	    for (i in ind(dim)) index[i] := [];
	    for (i in seq(dim[idim])) {
	    	index[idim] := i;
		q := i*(10^(idim-1));
		# print 'addtestarr:',type_name(testarr),i,q;
		if (is_complex(testarr) || is_dcomplex(testarr)) {
		    testarr[index] +:= complex(q,i);
		} else {
		    testarr[index] +:= q;
		}
	    }
	}
	return testarr;
    }

# Make a vector/array of gaussian noise, with given rms and mean.
# Dimarr can be a number, a shape (e.g. shape(aa)) or a template array (aa).

    public.gaussnoise := function (ref dimarr, rms=0, mean=0, type='double') {
	dim := shape(dimarr);				# assume input was array
	if (len(dim)==1) dim := dimarr;			# input was shape already
	n := prod(dim);					# total nr of values
	iscomplex := (type=='complex' || type=='dcomplex');
	rr := rep(0.0,n);
	if (iscomplex) rr := array(0.0,n,2);
	nrr := len(rr);
	for (i in [1:(niter:=9)]) {
	    rr +:= as_double(random(nrr)); 
	}
	rr -:= sum(rr)/nrr;				# adjust mean -> 0 
	rr *:= (rms/sqrt(sum(rr*rr)/nrr));		# adjust rms -> rms
	if (mean!=0) rr +:= mean;			# adjust mean -> mean
	if (iscomplex) rr := complex(rr[,1],rr[,2]);	# make complex
	if (len(dim)>1) rr::shape := dim;		# make array
	return rr;
    }


#===============================================================================
# Corrupt the given uvbrick with the specified effects:

# Complex gain errors (gain, phase):

    public.corrupt_pgerr := function (ref uvbrick, pp) {
	if (!has_field(pp,'rms_loggain')) pp.rms_loggain := 0;
	if (!has_field(pp,'rms_phase')) pp.rms_phase := 0;
	if (!has_field(pp,'pzd')) pp.pzd := 0;
	if (!has_field(pp,'suspend')) pp.suspend := F;

	pp.decomp := 'rcp_gain_complex';
	rr := uvbrick.init_decomprec (pp);		# decomp record
	rr.descr := 'corrupt_pgerr';

	vv := public.gaussnoise(rr.nuk, rms=pp.rms_phase, mean=0.0);
	rr.simul.rcp_phase := vv;                       # keep for comparison
	rr.simul.rcp_pzd := array(0.0,rr.nuk);          # keep for comparison
	dim := shape(rr.uktable);			# [nukpra=1,npol,nant]
	for (ipol in [1:dim[3]]) {			# ipol=1,2 (X/Y or R/L)
	    pzd2 := (ipol-1.5)*pp.pzd;		        # +/- pp.pzd/2
	    for (iant in [1:dim[2]]) {			# all ants
		iuk := uvbrick.getiuk(rr,1,iant,ipol);	# iukpra=1
		if (is_boolean(iuk)) next;		# invalid iuk, escape..
		vv[iuk] +:= pzd2;			# add to ANT phase
		rr.simul.rcp_pzd[iuk] := pzd2;          # keep for comparison
		print ipol,iant,iuk,pzd2,'phase[iuk]=',vv[iuk],'rad';
	    }
	}
	rr.antrcp := complex(cos(vv),sin(vv));		# vv was in rad

	vv := public.gaussnoise(rr.nuk, rms=pp.rms_loggain, mean=0.0)
	rr.simul.rcp_gain_real := 10^vv;                # keep for comparison
	rr.antrcp *:= 10^vv;				# vv was log(gain)
	rr.simul.rcp_gain_complex := rr.antrcp;         # keep for comparison

	dimout := [rr.nuk,1,1];                         # [nuk,nfreq,ntime]
	rr.antrcp::shape := dimout;	
	rr.simul.rcp_phase::shape := dimout;
	rr.simul.rcp_pzd::shape := dimout;
	rr.simul.rcp_gain_real::shape := dimout;
	rr.simul.rcp_gain_complex::shape := dimout;

	hist := paste('uvdata corruption for gain/phase:');
	hist := spaste(hist,'\n - rms_loggain=',pp.rms_loggain);
	hist := spaste(hist,'\n - rms_phase=',pp.rms_phase);
	hist := spaste(hist,'\n - pzd=',pp.pzd);
	r := private.apply_corrupt(uvbrick, pp, rr, hist);
	if (is_fail(r)) fail(r);
	return rr;					# return record!
    }

# Delay offsets (phase-gradients over the freq-spectrum):

    public.corrupt_deloff := function (ref uvbrick, pp) {
	if (!has_field(pp,'mean_nsec')) pp.mean_nsec := 0;
	if (!has_field(pp,'rms_nsec')) pp.rms_nsec := 0;
	if (!has_field(pp,'suspend')) pp.suspend := F;

	pp.decomp := 'rcp_delay_offset';
	rr := uvbrick.init_decomprec (pp);		# decomp record
	rr.descr := 'corrupt_deloff';

	vv := public.gaussnoise(rr.nuk, rms=pp.rms_nsec, 
				mean=pp.mean_nsec);
	vv *:= private.pi/500;				# -> rad/MHz
	rr.antrcp := vv;
	rr.simul.rcp_delay_offset := rr.antrcp;         # keep for comparison

	dimout := [rr.nuk,1];                           # [nuk,ntime]
	rr.antrcp::shape := dimout;	
	rr.simul.rcp_delay_offset::shape := dimout;

	hist := paste('uvdata corruption for delay offsets:');
	hist := spaste(hist,'\n - rms_nsec=',pp.rms_nsec);
	r := private.apply_corrupt(uvbrick, pp, rr, hist);
	if (is_fail(r)) fail(r);
	return rr;					# return record!
    }


# Dipole errors (position error and ellipticity):
# NB: Should be applied BEFORE complex gain errors!

    public.corrupt_diperr := function (ref uvbrick, pp) {
	if (!has_field(pp,'rms_dipposerr')) pp.rms_dipposerr := 0;
	if (!has_field(pp,'rms_ellipticity')) pp.rms_ellipticity := 0;
	if (!has_field(pp,'suspend')) pp.suspend := F;

	pp.decomp := 'rcp_diperr_complex';
	rr := uvbrick.init_decomprec (pp);		# decomp record
	rr.descr := 'corrupt_dipperr';

	dd := public.gaussnoise(rr.nuk, rms=pp.rms_dipposerr, mean=0.0)
	ee := public.gaussnoise(rr.nuk, rms=pp.rms_ellipticity, mean=0.0)
	rr.simul.rcp_dipposerr := dd;
	rr.simul.rcp_ellipticity := ee;
	rr.antrcp := complex(dd,ee);		# linear approximation.....!
	rr.simul.rcp_dipperr_complex := rr.antrcp;

	dimout := [rr.nuk,1,1];                         # [nuk,nfreq,ntime]
	rr.antrcp::shape := dimout;	
	rr.simul.rcp_dipperr_complex::shape := dimout;  # keep for comparison
	rr.simul.rcp_dipposerr::shape := dimout;        # keep for comparison
	rr.simul.rcp_ellipticity::shape := dimout;      # keep for comparison

	hist := paste('uvdata corruption for diperr:');
	hist := spaste(hist,'\n - rms_dipposerr=',pp.rms_dipposerr);
	hist := spaste(hist,'\n - rms_ellipticity=',pp.rms_ellipticity);
	r := private.apply_corrupt(uvbrick, pp, rr, hist);
	if (is_fail(r)) fail(r);
	return rr;					# return record!
    }

# Baseline errors (phase) for MAKECAL:

    public.corrupt_MAKECAL := function (ref uvbrick, pp) {
	if (!has_field(pp,'rms_antpos_dx')) pp.rms_antpos_dx := 0;
	if (!has_field(pp,'rms_antpos_dy')) pp.rms_antpos_dy := 0;
	if (!has_field(pp,'rms_antpos_dz')) pp.rms_antpos_dz := 0;
	if (!has_field(pp,'suspend')) pp.suspend := F;

	pp.decomp := 'ant_position';
	rr := uvbrick.init_decomprec (pp);		# decomp record
	rr.descr := 'corrupt_MAKECAL';

	rms := mean := [];
	rms[1] := pp.rms_antpos_dx;
	rms[2] := pp.rms_antpos_dy;
	rms[3] := pp.rms_antpos_dz;
	mean[1] := pp.mean_antpos_dx;
	mean[2] := pp.mean_antpos_dy;
	mean[3] := pp.mean_antpos_dz;

	rr.antrcp := array(0.0,rr.nuk,1,rr.ntime);	# [nuk,nfreq,ntime!]
	for (iukpra in [1:rr.nukpra]) {
	    vv := public.gaussnoise(rr.nant, rms=rms[iukpra]);
	    vsum := 0;
	    iiuk := [];
	    for (iant in [1:rr.nant]) {
		iuk := uvbrick.getiuk(rr,iukpra,iant,1);
		if (is_boolean(iuk)) next;		# invalid iuk
		rr.antrcp[iuk,1,] := vv[iant];
		vsum +:= vv[iant];			# actual sum
		iiuk := [iiuk,iuk];			# relevant iuks
	    }
	    vadj := mean[iukpra] - (vsum/len(iiuk)); 
	    rr.antrcp[[iiuk],1,] +:= vadj;		# adjust mean	
	}
	uvbrick.attach('MAKECAL',rr);			# keep for comparison

	hist := paste('uvdata corruption for MAKECAL:');
	hist := spaste(hist,'\n - rms_antpos_dx=',pp.rms_antpos_dx);
	hist := spaste(hist,'\n - rms_antpos_dy=',pp.rms_antpos_dy);
	hist := spaste(hist,'\n - rms_antpos_dz=',pp.rms_antpos_dz);
	hist := spaste(hist,'\n - mean_antpos_dx=',pp.mean_antpos_dx);
	hist := spaste(hist,'\n - mean_antpos_dy=',pp.mean_antpos_dy);
	hist := spaste(hist,'\n - mean_antpos_dz=',pp.mean_antpos_dz);
	r := private.apply_corrupt(uvbrick, pp, rr, hist);
	if (is_fail(r)) fail(r);
	return rr;					# return record!
    }

# Pointing errors (ampl):

    public.corrupt_POINTING := function (ref uvbrick, pp, trace=F) {
	if (!has_field(pp,'rms_polycoeff_HA')) pp.rms_polycoeff_HA := 0;
	if (!has_field(pp,'rms_polycoeff_DEC')) pp.rms_polycoeff_DEC := 0;
	if (!has_field(pp,'suspend')) pp.suspend := F;

	pp.decomp := 'ant_pointing';
	rr := uvbrick.init_decomprec (pp);		# decomp record
	rr.descr := 'corrupt_POINTING';

	include 'mathematics.g';			# new
	# include 'numerics.g';				# old
	fitter := polyfitter();				# fitter object

	HAdeg := uvbrick.get('HA');			# function of time
	DECdeg := uvbrick.get('DECdeg');		# function of field
	fid := uvbrick.get('field_ids');		# function of time
	ant_RAdeg := uvbrick.get('ant_RAdeg');		# [nant,ntime] degr;
	ant_DECdeg := uvbrick.get('ant_DECdeg');	# [nant,ntime] degr;

	RAstep := 0.72 * 0.5 * uvbrick.fwhm(unit='deg');
	DECstep := RAstep;				# the same
	if (trace) print 'RA/DECstep=',RAstep,DECstep,'degr';
	if (trace) print cycle_RA := [0,-1,1,0,-1,1] * RAstep;
	if (trace) print cycle_DEC := [0,1,1,0,-1,-1] * DECstep;
	nRA := len(cycle_RA);
	nDEC := len(cycle_DEC);
	dRA := array(0,2*nRA,2);
	dDEC := array(0,2*nDEC,2);
	if (trace) print dRA[,1] := [cycle_RA,rep(0,nRA)];
	if (trace) print dRA[,2] := [rep(0,nRA),cycle_RA];
	if (trace) print dDEC[,1] := [cycle_DEC,rep(0,nDEC)];
	if (trace) print dDEC[,2] := [rep(0,nDEC),cycle_DEC];
	if (trace) print antgrp := array([1,2],rr.nant); # two groups of ants

	vv := array(0.0,2,rr.nfield);
	for (ifield in [1:rr.nfield]) {
	    sv := [fid==ifield];			# selection vector
	    n := len(sv[sv]);				# nr of time-slots
	    if (n<0) {
	    	print 'ifield=',ifield,': no time-slots!?';
	    	next;
	    } 
	    vv[1,ifield] := sum(HAdeg[sv])/n;		# mean HA for field
	    vv[2,ifield] := DECdeg[ifield];	    	# DEC of field
	    s := paste('ifield=',ifield,'n=',n);
	    s := paste(s,'HAdeg=',vv[1,ifield],'(',vv[1,ifield]/90,')')
	    s := paste(s,'DECdeg=',vv[2,ifield],'(',vv[2,ifield]/90,')');
	    if (trace) print s;

	    ii := ind(fid)[sv];				# indices for ifield
	    jj := [1:min(2*nRA,len(ii))]
	    ii := ii[jj];
	    if (trace) print s := paste('jj=',jj,'ii=',ii);
	    for (iant in [1:rr.nant]) {
	    	iantgrp := antgrp[iant];		# 1 or 2
	    	ant_RAdeg[iant,ii] +:= dRA[jj,iantgrp];
	    	ant_DECdeg[iant,ii] +:= dDEC[jj,iantgrp];
	    }
	}
	HADECnorm := vv/90;				# normalised: =<1	
	uvbrick.set('ant_RAdeg',ant_RAdeg);		# replace
	uvbrick.set('ant_DECdeg',ant_DECdeg);		# replace;

	rr.antrcp := array(0.0,2,rr.nant,1,rr.nfield);	# [dxy[2],nant,nfreq,nfield]
	bb := rep(0.0,rr.nukpra);			# in principle: 6
	ndeg := [pp.ndeg_poly_HA, pp.ndeg_poly_DEC];
	rms := [pp.rms_polycoeff_HA, pp.rms_polycoeff_DEC];
	for (iant in [1:rr.nant]) {
	    for (ixy in [1:2]) {			# 1:x(HA), 2:y(DEC)
	    	coeff := public.gaussnoise(ndeg[ixy]+1, rms=rms[ixy], mean=0.0);
	    	for (ifield in [1:rr.nfield]) {
	    	    sv := [fid==ifield];		# selection vector
	    	    xy := HADECnorm[ixy,ifield];	# normalised: |xy|<=1
	    	    ok := fitter.eval(dxy, xy, coeff);
	    	    rr.antrcp[ixy,iant,1,ifield] := dxy;
	    	}
	    	s := paste('iant=',iant,'ixy=',ixy,':');
	    	s := paste(s,'range=',range(rr.antrcp[ixy,iant,1,]),'milli-degr');
	    	if (trace) print s;
	    }
	}
	uvbrick.attach('BEAM',rr);			# keep for comparison

	hist := paste('uvdata corruption for BEAM:');
	hist := spaste(hist,'\n - ndeg_poly_HA=',pp.ndeg_poly_HA);
	hist := spaste(hist,'\n - ndeg_poly_DEC=',pp.ndeg_poly_DEC);
	hist := spaste(hist,'\n - rms_polycoeff_HA=',pp.rms_polycoeff_HA);
	hist := spaste(hist,'\n - rms_polycoeff_DEC=',pp.rms_polycoeff_DEC);
	r := private.apply_corrupt(uvbrick, pp, rr, hist);
	if (is_fail(r)) fail(r);
	return rr;					# return record!
    }

# Helper function: apply the uv-data corruption in decomprec rr:

    private.apply_corrupt := function (ref uvbrick, pp=[=], rr=[=], hist=' ') {
	apprec := [=];					# apply parameters
	apprec.operation := 'automatic';		# apply operation
	apprec.suspend := pp.suspend;			# if F, start automatically
	apprec.rhv := rr;

	r := uvbrick.apply(apprec);			# apply

	if (is_fail(r) || (r==F)) {
	    print '\n\n .apply(rr), inspect rr';
	    inspect(rr,'rr');
	    fail('apply() has failed!');
	} 
	# Attach the simulation-info to the uvbrick for comparison:
	fname := spaste('simul_',rr.decomp);            # field-name
	uvbrick.attach(fname, rr, trace=T);             # attach rr

	uvbrick.addtohistory(hist);
	s := paste('\n corrupt:',rr.decomp);
	s := paste(s,'rhv.antrcp:',type_name(rr.antrcp),shape(rr.antrcp));
	# print s := paste(s,'\n antrcp[,1,1]=',rr.antrcp[,1,1]);
	return T;
    }

#====================================================================
# Add noise etc to existing data:

    public.addnoise := function (ref uvbrick, pp=[=]) {
	if (!has_field(pp,'SNR')) pp.SNR := 0;
	if (pp.SNR<=0) return F;			# unreasonable
	if (pp.SNR>1000000) return F;			# insignificant

	uvdata := uvbrick.get('data',copy=F);		# get a reference
	meanabs := sum(abs(uvdata))/len(uvdata);
	rmsnoise := meanabs/pp.SNR;	
	val uvdata +:= public.gaussnoise(uvdata, rms=rmsnoise, 
				     type=type_name(uvdata));
	s := paste('added noise: SNR=',pp.SNR,' rms=',rmsnoise)
	uvbrick.message(s);
	uvbrick.addtohistory(s);
	return T;
    }


    public.addspikes := function (ref uvbrick, pp=[=]) {
	if (!has_field(pp,'perc_spikes')) pp.perc_spikes := 0;
	if (!has_field(pp,'rms_spikes')) pp.rms_spikes := 0;
	if (!has_field(pp,'mean_spikes')) pp.mean_spikes := 0;
	if (pp.perc_spikes<=0) return F;		# none needed
	if (pp.rms_spikes<=0) return F;			# none needed

	uvdata := uvbrick.get('data',copy=T);		# get a copy
	nuv := len(uvdata);				# nr of uv-data
	nspikes := as_integer(nuv*pp.perc_spikes/100);	# percentage of nuv
	xx := random(nspikes);				# random nrs
	xx := as_integer(1+nuv*(xx/(1+max(xx))));	# normalise
	uvdata[xx] +:= public.gaussnoise(len(xx), rms=pp.rms_spikes, 
			  mean=pp.mean_spikes, type=type_name(uvdata));
	uvbrick.set('data',uvdata);
	s := paste('added',nspikes,'spikes, rms=',pp.rms_spikes)
	uvbrick.message(s);
	uvbrick.addtohistory(s);
	return T;
    }

#=========================================================
# Finished. Initialise and return the public interface:

    private.init();
    return public
};				# closing bracket
#=========================================================


# msb := test_msbrick_simul();	# run test-routine
# msbsim := msbrick_simul();	# create an msbsimul object













