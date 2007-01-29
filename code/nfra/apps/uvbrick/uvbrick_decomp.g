# uvbrick_decomp.g: antenna decomposition functions for uvbrick.g.

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
# $Id: uvbrick_decomp.g,v 19.0 2003/07/16 03:38:54 aips2adm Exp $

#---------------------------------------------------------

pragma include once
# print 'include uvbrick_decomp.g  w01sep99'

include 'jenmath.g';	         	# math etc
include 'jenmisc.g';	         	# checkfield etc
include 'jenindex.g';	         	# index display/control

# include 'uvbrick_plot.g';		# uvbrick plotting functions

# include 'textformatting.g';		
# include 'tracelogger.g';
# include 'buttonscript.g';		# script generation


#=========================================================
test_uvbrick_decomp := function () {
    private := [=];
    public := [=];
    return ref public.uvb;
};


#==========================================================================
#==========================================================================
#==========================================================================

uvbrick_decomp := function () {
    private := [=];
    public := [=];


# Initialise the object (called at the end of this constructor):

    private.init := function (name='uvbrick') {
	wider private;
	const private.pi := acos(-1);		# use atan()....?
	const private.pi2 := 2*private.pi;	
	const private.rad2deg := 180/private.pi;
	const private.deg2rad := 1/private.rad2deg;
	const private.kBoltzmann := 1.3805e-23;

	private.jenmath := jenmath();
	private.jenmisc := jenmisc();
	# private.uvb_plot := uvbrick_plot();

	private.fitter := F;			# only when needed (numerics.g)
	private.lsf := F;			# only when needed (lsfit.g)
	private.fft := F;			# only when needed (numerics.g)
	private.index := F;			# only when needed (jenindex.g)
   	private.fft := F;			# only when needed (numerics.g)

	# private.tf := textformatting();		# text-formatting functions
	# include 'tracelogger.g';
	# private.trace := tracelogger(private.name);
	return T;
    }


    private.check_lsf := function() {
	wider private;
	if (is_boolean(private.lsf)) {			# not yet defined
	    include 'lsfit.g';				# only when needed
	    private.lsf := lsfit_functions();		# lsfit functions
	}
    }

    private.check_fitter := function() {
	wider private;
	if (is_boolean(private.fitter)) {		# not yet defined
	    include 'mathematics.g';			# new
	    private.fitter := polyfitter();		# fitter object
	}
    }

    private.check_fft := function() {
	wider private;
	if (is_boolean(private.fft)) {			# not yet defined
	    include 'mathematics.g';			# new
	    private.fft := fftserver();			# fft object
	}
    }


#==========================================================================
# Public interface:
#==========================================================================


    #------------------------------------------------------------
    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('uvbrick event:',$name,$value);
	# print s;
    }
    whenever public.agent->message do {
	print 'uvbrick_decomp message-event:',$value;
    }
    whenever public.agent->abort do {
	print 'uvbrick_decomp: index abort-event:',$value;
	if (is_record(private.index)) {
	    private.index.abort($value);	# abort any index-loops
	}
    }
    #------------------------------------------------------------

    public.private := function(copy=F) {	# access to private part
	if (copy) return private;		# return a copy
	return ref private;			# return a reference
    }


#================================================================================
# Helper function to apply the decomposed ant/rcp-effects in the input-record
# to a corr-ifr slice of this particular uvbrick. (see .decompant() for details). 
# NB: This routine should be able to recognise when a new slice is needed or not;
# Assumptions: data has shape [ncorr,nfreq,nifr,ntime]
#              rr.antrcp has shape [nuk,nfreq,ntime]
# 

    public.decomp2slice := function (ref uvbrick, rr=[=], index=[=], ref rext=F) {
	wider private;
	newslice := T;
	newtime := T;
	newfreq := T;
	ix_freq := 2;			# position of freq axis in index (always 2?)
	ix_time := 4;			# position in time axis index (always 4?)
	# ix_freq := uvbrick.idim('freq');	# position of freq axis in index 
	# ix_time := uvbrick.idim('time');	# position of time axis in index
	ifreq := index[ix_freq];		# freq index in index
	itime := index[ix_time];		# time index in index
	s := paste('decomp2slice: index=',index);
	s := spaste(s,' ifreq=',ifreq,' itime=',itime);
	uvbrick.message(s);                     # show progress       
	irrfreq := irrtime := 0;
	if (len(ifreq)==0) {			# e.g. rcp_delay_offset
	    print 'decomp2slice: ifreq==[], index=',index;
	    # always calculate a new slice;	# temporary...!?
	    rrshape := shape(rr.antrcp);	# expected: [nuk,ntime]
	    irrtime := min(rrshape[2],itime);	# time-index in rr.antrcp
	} else if (len(itime)==0) {		# should not happen....
	    print 'decomp2slice: itime==[]??, index=',index;
	    # always calculate a new slice;	# temporary...!?
	    rrshape := shape(rr.antrcp);	# expected: [nuk,nfreq]
	    irrfreq := min(rrshape[2],ifreq);	# freq-index in rr.antrcp
	} else if (ifreq==1 && itime==1) {	# the first time
	    # always calculate a new slice;
	    rrshape := shape(rr.antrcp);	# expected: [nuk,nfreq,ntime]
	    irrfreq := min(rrshape[2],ifreq);	# freq-index in rr.antrcp
	    irrtime := min(rrshape[3],itime);	# time-index in rr.antrcp
	} else {
	    rrshape := shape(rr.antrcp);	# expected: [nuk,nfreq,ntime]
	    irrfreq := min(rrshape[2],ifreq);	# freq-index in rr.antrcp
	    irrtime := min(rrshape[3],itime);	# time-index in rr.antrcp
	    newslice := F;
	    newtime := F;
	    newfreq := F;
	    if (ifreq!=private.d2s_oldindex[ix_freq]) {	# freq-axis
		newfreq := T;
		if (rrshape[2]>1) newslice := T;
	    } 
	    if (itime!=private.d2s_oldindex[ix_time]) {	# time-axis
		newtime := T;
		if (rrshape[3]>1) newslice := T;
	    } 
	}
	# print 'decomp2slice: rrshape=',rrshape,'irrfreq=',irrfreq,'irrtime=',irrtime;
	if (rr.decomp=='ant_pointing') newslice := T; 	# ugly...?
	private.d2s_oldindex := index;		# keep for next time
	if (!newslice) {
	    # print 'no new slice needed';
	    return T;				# OK, current slice is still valid;
	}

	# Make new slice. Start with some decomp-dependent actions.
	# NB: The order of the following is important!

	slice := array(rr.vinit,rr.ncorr,rr.nifr);	# initialise output slice
	brickshape := uvbrick.shape();			# [ncorr,nfreq,nifr,ncorr]
	if (rr.decomp=='ant_pointing') {
	    if (newfreq) {				# rext is for all times
		private.get_BEAM_gain (uvbrick, rr, index, rext);
		print 'rext:',type_name(rext),shape(rext);
		# inspect(rext,'rext');
	    }
	} else if (rrshape[3]>1 && rrshape[3]!=brickshape[ix_time]) {
	    print '*** decomp2slice: ntime mismatch:',rrshape,brickshape[ix_time];
	    return F;
	} else if (rr.decomp=='ant_position') {
	    if (is_boolean(rext)) rext := private.get_MAKECAL_coeff (uvbrick, rr);
	    qq := private.get_MAKECAL_coeff (uvbrick, rr, index, rext); 
	} else if (rr.decomp=='rcp_delay_offset') {	# has different dimensions!
	    ffMHz := uvbrick.get('chan_freq');		# freq vector
	    ffmean := sum(ffMHz)/max(1,len(ffMHz));     # centre freq
	    ffMHz -:= ffmean;                           # subtract 
	    slice := array(rr.vinit,rr.ncorr,rr.nfreq,rr.nifr);
	} else if (rrshape[2]>1 && rrshape[2]!=brickshape[ix_freq]) {
	    print '*** decomp2slice: nfreq mismatch:',rrshape,brickshape[ix_freq];
	    return F;
	}

	add := (rr.combinop=='add');			# if F: multiply
	# print 'init slice:',type_name(slice),shape(slice),rr.decomp,'add=',add;
	# print 'rr.antrcp:',type_name(rr.antrcp),shape(rr.antrcp);


	for (ifr in [1:rr.nifr]) {
	    for (icorr in rr.icorr_apply) {
	    	rcp := uvbrick.getrcp_ifr (ifr, icorr);	# rcp is record
		s := paste(ifr,icorr,rcp.ifrname,rcp.iant,rcp.ipol,':');
		for (i in [1:2]) {			# ant1/2
		    if (rcp.iant[i] > rr.nant) {
			s1 := paste('** warning: decomp2slice():',ifr,icorr,i); 
			s1 := paste(s1,'target slice has too many antennas!');
			print paste(s1,rcp.iant,'>',rr.nant);
			next;				# escape...?
		    }

		    antrcp := 0;
		    if (rr.decomp=='ant_pointing') {
			antrcp := rext.ant_gain[rcp.iant[i],itime];
		    } else if (rr.decomp=='rcp_delay_offset') {
			iuk := public.getiuk(rr,1,rcp.iant[i],rcp.ipol[i]);
			if (is_boolean(iuk)) next;		# invalid, skip
			ukval := rr.antrcp[iuk,irrtime];	# gradient: rad/MHz
			antrcp := ukval * ffMHz;		# phase vector (rad)
		    } else {
		    	for (iukpra in [1:rr.nukpra]) {	# uk per ant/rcp
			    iuk := public.getiuk(rr,iukpra,rcp.iant[i],rcp.ipol[i]);
			    if (is_boolean(iuk)) next;		# invalid, skip
			    ukval := rr.antrcp[iuk,irrfreq,irrtime];
			    if (rr.decomp=='ant_position') {	# nukpra>1
			    	antrcp +:= qq[iukpra]*ukval;	# so: add
			    } else {			# assumed: nukpra=1!!
			    	antrcp := ukval;		# so: replace
			    }
			}
		    }

		    # Combine the two ant/rcp contr into an ifr contribution:
		    if (i==1) {	
		    	v := antrcp*rr.c12[i];
		    } else if (add) {				# additive	
		    	v +:= conj(antrcp)*rr.c12[i];	# NB: conj is for diperr
		    } else {					# multiplicative
			# NB: Assume that rr.c12[2]=1, not -1 ....?
		    	v *:= conj(antrcp);	# NB: conj is for gain_complex
		    }
		}
		# print paste(s,'->',v);
		if (rr.decomp=='rcp_delay_offset') {
		    slice[icorr,,ifr] := v;			# freq-vector 
		} else {
		    slice[icorr,ifr] := v;			# scalar 
		}
	    }
	}

	# Convert the slice to the expected format:
	if (rr.decomp=='rcp_phase' || 
	    rr.decomp=='rcp_pzd' ||
	    rr.decomp=='rcp_delay_offset' ||
	    rr.decomp=='ant_position') {			# phase (rad)
	    # NB: alternative: if (rr.cx2real=='phase_rad') {
	    # NB: if that is used, what about 'logampl' for rcp_gain_real?
	    slice := complex(cos(slice),sin(slice));		# -> complex 
	} else if (rr.decomp=='rcp_ellipticity') {
	    slice *:= complex(0.0,1.0) * rr.stokesI;		# 
	} else if (rr.decomp=='rcp_dipposerr') {
	    # print 'decomp2slice:',rr.decomp,'rr.stokesI=',rr.stokesI;
	    slice *:= complex(1.0,0.0) * rr.stokesI;		# 
	} else if (rr.decomp=='rcp_diperr_complex') {
	    slice *:= rr.stokesI;				# 
	}
	# print 'decomp2slice: new slice:',rr.decomp,type_name(slice),shape(slice);
	return slice;
    }

#------------------------------------------------------------------------
# Determination of WSRT antenna position parameters.

    public.MAKECAL := function (ref uvbrick, pp=[=], ref pgw=F) {
	wider private;

	private.jenmisc.checkfield(pp,'decomp','ant_position','MAKECAL');
	# private.jenmisc.checkfield(pp,'nominal','..','MAKECAL');
	private.jenmisc.checkfield(pp,'display',T,'MAKECAL');
	private.jenmisc.checkfield(pp,'suspend',F,'MAKECAL');
	hist := paste('MAKECAL',pp);

    	rout := public.init_decomprec (uvbrick, pp);	# output record
	if (is_fail(rout)) fail(rout);
	rout.descr := 'MAKECAL';

	sliceaxes := "corr ifr";			# 
	if (is_record(pgw)) {				# plot-widget defined
	    private.index := uvbrick.initindex(sliceaxes, 'data', 
					       origin='MAKECAL', showprogress=F);
	    pgw.index(private.index);			# progress control
	} else {
	    private.index := uvbrick.initindex(sliceaxes, 'data', origin='MAKECAL');
	}
	if (is_fail(private.index)) fail(private.index);
	private.index.suspend(pp.suspend);		# if F, start directly

	private.check_lsf();				# define private.lsf; 
	private.lsf.init(rout.nuk);			# init matrices

	rm := private.get_MAKECAL_coeff (uvbrick, rout);# rm is record 

    	while (private.index.next(index)) {
	    # print '\n',index;
	    pgw.message(private.index.get_progress_message());

	    slice := uvbrick.getslice(index);		# 2D array [corr, ifr] 
	    flag := uvbrick.getslice(index, 'flag');

	    avcx := rep(complex(0,0),rout.nifr);	    
	    for (icorr in rout.icorr_solve) {  		# usually XX/YY only
		avcx +:= slice[icorr,];			# accumulate
	    }
	    avcx /:= max(1,len(rout.icorr_solve));	# mean vis
	    avrad := private.jenmath.cx2real(avcx,'phase_rad');	# convert to phase

	    qq := private.get_MAKECAL_coeff (uvbrick, rout, index, rm); 

	    for (ifr in [1:rout.nifr]) {		# all available ifrs
	    	icorr := rout.icorr_solve[1];  		# solving for ants!
	    	rcp := uvbrick.getrcp_ifr (ifr, icorr);
	    	cc := rep(0.0,rout.nuk);
		for (iukpra in [1:rout.nukpra]) {	# nukpra=3
		    for (i in [1:2]) {			# ant1/2
			iuk := public.getiuk(rout,iukpra,rcp.iant[i],rcp.ipol[i]);
			if (is_boolean(iuk)) next;		# invalid, skip
		    	# iuk := rout.uktable[iukpra,rcp.iant[i],rcp.ipol[i]];	
	    	    	cc[iuk] := qq[iukpra]*rout.c12[i];
		    } 	
		}
		s := private.lsf.accumulate(cc,avrad[ifr]);	# accumulate
		# print rcp.ifrname,':',s;		# print always
	    }

	    # Display per slice[corr,ifr]?
	}						# next slice
	pgw.index();					# disable progress control

	for (k in ind(rout.constrequ)) {		# constraint equation(s):
	    s := private.lsf.accumulate(rout.constrequ[k], 0.0, constreq=T);
	    print s;
	}

	# print s := private.lsf.status();		# debugging
	rout.antrcp := private.lsf.solve();		# solve for rcp
	if (is_fail(rout.antrcp)) {
	    print rout.antrcp;				# temporary
	    print s := private.lsf.status();		# debugging
	    return rout.antrcp;
	}
	print 'rout.antrcp:',rout.antrcp;
	private.decomprec_update_label(rout);
	private.MAKECAL_antsol (uvbrick, rout, pgw);	# display result
	uvbrick.addtohistory(hist);
	return rout;					# return record or T;
    }

# Helper function: display the result:

    private.MAKECAL_antsol := function (ref uvbrick, ref rout=[=], ref pgw=F) {
	s := paste('Results of MAKECAL:');
	uvbrick.message(paste(' \n \n',s));
	title := s;
	label := 'MAKECAL';
	xdescr := 'antenna';
	ydescr := 'antenna position deviation';
	yunit := 'mm';
	attrec := uvbrick.get_attached('MAKECAL');
	compare_simul := !is_boolean(attrec);
	if (compare_simul) title := paste(title,'[dashed: diff with simulated]');
	color := array("red blue cyan",rout.nukpra);
	shape := array("cross star diamond",rout.nukpra);

	group := pgw.group (label=label, trace=F,
			    xannot=F, yannot=F,
			    title=title, legend=F,
			    xname=F, xdescr=xdescr, xunit=F, 
			    yname=F, ydescr=ydescr, yunit=yunit); 
	for (iukpra in [1:rout.nukpra]) {
	    duk := dduk := [];
	    xannot := ' ';
	    ukname := rout.ukpra_name[iukpra];		# e.g. 'dx'
	    s := paste('\n iukpra=',iukpra,':',ukname);
	    uvbrick.message(s);
	    for (iant in [1:rout.nant]) {
		ipol := 1;				# solving for ants
		iuk := public.getiuk(rout,iukpra,iant,ipol);
		if (is_boolean(iuk)) next;		# invalid, skip
	    	s := spaste('- ant=',rout.ant_name[iant])
	    	s := spaste(s,sprintf('%-12s',spaste(' (iuk=',iuk,'):')));
		duk[iant] := rout.antrcp[iuk]*1000;
		xannot[iant] := rout.ant_fullname[iant];  #....?
	    	s := spaste(s,sprintf('%-20s',spaste('est=',duk[iant],' mm')));
	    	if (compare_simul) {
		    dduk[iant] := duk[iant] + attrec.antrcp[iuk,1,1]*1000;
		    s := paste(s,'(diff with simulated:',dduk[iant],'mm)');
	    	}
	    	uvbrick.message(s);
	    }
	    s := ' ';
	    uvbrick.message(s);				# separate 
	    xx := ind(duk);				# zero-relative
	    label := spaste(ukname);
	    pgw.putline (group, label=label, xx=xx, yy=duk, trace=F,
			 color=color[iukpra], style=shape[iukpra], size=5);
	    if (compare_simul) {
		pgw.putline (group, label=rr.label, xx=xx, yy=dduk, trace=F,
			     color=color[iukpra], style='linespoints', size=5);
	    }
	}
	pgw.labels(group, xannot=xannot);
	pgw.putgroup(group, clear=T, plot=F, trace=F);
	pgw.set_display_option('yzero',T);
	pgw.set_display_option('showlegend',T);
	pgw.plot();
	return T;
    }


# Helper function to calculate the MAKECAL matrix coefficients.
# Used in .MAKECAL() and .decomp2slice();

    private.get_MAKECAL_coeff := function (ref uvbrick, decomp=[=], 
					   index=[=], ref rr=F) {
	wider private;
	if (is_boolean(rr)) {				# initialise
	    rr := [=];
	    rr.basel := uvbrick.get('baseline');	# nominal B (m)
	    rr.fMHz := uvbrick.get('chan_freq');	# function of freq
	    rr.HAdeg := uvbrick.get('HA');		# function of time
	    rr.field_ids := uvbrick.get('field_ids');	# function of time
	    rr.DECdeg := uvbrick.get('DECdeg');		# function of field
	    # print 'get_MAKECAL_coeff() init:',field_names(rr);
	    return rr;					
	} 
	
	ifreq := index[2];
	rr.curr_fMHz := rr.fMHz[ifreq];			# needed later
	fc := rr.curr_fMHz/300;				# f/c := fMHz/300
	# print s := paste('ifreq=',ifreq,'fMHz=',rr.curr_fMHz,'f/c=',fc);

	itime := index[4];
	rr.curr_HArad := rr.HAdeg[itime]*private.deg2rad;
	rr.cosHA := cos(rr.curr_HArad);
	rr.sinHA := sin(rr.curr_HArad);
	s := paste('itime=',itime,'HA(deg)=',rr.HAdeg[itime])
	# print s := paste(s,'cs=',rr.cosHA,rr.sinHA);

	ifield := rr.field_ids[itime];
	rr.curr_DECrad := rr.DECdeg[ifield]*private.deg2rad;
	rr.cosDEC := cos(rr.curr_DECrad);
	rr.sinDEC := sin(rr.curr_DECrad);
	s := paste('ifield=',ifield,'DEC(deg)=',rr.DECdeg[ifield]);
	# print s := paste(s,'cs=',rr.cosDEC,rr.sinDEC);

	# Solve for 3 unknowns per ant (not rcp!): 
	# 1) B.dHA  (=dx?): coeff := -cosHA.cosDEC.(2.pi.c/f) 
	# 2) dB     (=dy): coeff := sinHA.cosDEC.(2.pi); 
	# 3) B.dDEC (=dz?): coeff := sinHA.(2.pi.c/f);
	# NB: B is nominal baseline (m) = L.lambda = L.c/f
	# NB: poolas : sinDEC*cosHA and sinDEC*sinHA.......
	# NB: separate option: dy only (RT verrijden, 1 DEC)

	coeff := [];
	coeff[1] := -2*private.pi*rr.cosHA*rr.cosDEC/fc;
	coeff[2] := 2*private.pi*rr.sinHA*rr.cosDEC;
	coeff[3] := 2*private.pi*rr.sinHA/fc;
	# print paste('MAKECAL coeff=',coeff);
	return coeff;					# return coeff array
    }

#------------------------------------------------------------------------
# Determination of WSRT antenna pointing (and beamshape?) parameters.

    public.BEAM := function (ref uvbrick, pp=[=], ref pgw=F) {
	wider private;

	private.jenmisc.checkfield(pp,'decomp','ant_pointing','BEAM');
	private.jenmisc.checkfield(pp,'display',T,'BEAM');
	private.jenmisc.checkfield(pp,'suspend',F,'BEAM');
	hist := paste('BEAM',pp);

    	rout := public.init_decomprec (uvbrick, pp);	# output record
	if (is_fail(rout)) fail(rout);
	rout.descr := 'BEAM';

	sliceaxes := "corr ifr";			# 
	if (is_record(pgw)) {				# plot-widget defined
	    private.index := uvbrick.initindex(sliceaxes, 'data', origin='BEAM',
					       showprogress=F);
	    pgw.index(private.index);			# progress control
	} else {
	    private.index := uvbrick.initindex(sliceaxes, 'data', origin='BEAM');
	}
	if (is_fail(private.index)) fail(private.index);
	private.index.suspend(pp.suspend);		# if F, start directly

	private.check_lsf();				# define private.lsf; 
	lsf := [=];					# record
	ilsf := [];
	nlsf := 0;
	for (iant in rout.iiant) {
	    ilsf[iant] := (nlsf +:= 1);			# pointer to lsf
	    lsf[ilsf[iant]] := lsfit_functions();		# lsfit objects
	    # print nlsf,'lsf: iant=',iant,':',type_name(lsf[ilsf[iant]]);
	    nuk := 6;					# 6 unknowns (bb)
	    lsf[ilsf[iant]].init(nuk);			# init matrices
	}
	offsource := rep(F,rout.nant);			# switches
	nbothonsource := rep(0,rout.nant);		# counters

	ant_RAdeg := uvbrick.get('ant_RAdeg');		# [nant,ntime] degr;
	ant_DECdeg := uvbrick.get('ant_DECdeg');		# [nant,ntime] degr;
	rout.field_DECdeg := uvbrick.get('DECdeg');	# [nfield] degr;
	rout.field_RAdeg := uvbrick.get('RAdeg');	# [nfield] degr;
	field_ids := uvbrick.get('field_ids');		# [ntime];
	HAdeg := uvbrick.get('HA');			# [ntime];
	dRAref := 0.5 * 0.5 * uvbrick.fwhm(unit='deg');	# smaller than actual step
	dDECref := dRAref;				# the same
	print 'dRA/DECref=',dRAref,dDECref;

	rout.field_meanHAdeg := 0 * rout.field_RAdeg;	# zeroes
	HAfield := rep(0.0,rout.nant);			# accumulator	
	nHAfield := rep(0,rout.nant);			# counter	
 
   	while (private.index.next(index)) {
	    print '\n BEAM:',index;
	    pgw.message(private.index.get_progress_message());
	
	    slice := uvbrick.getslice(index);		# 2D array [corr, ifr] 
	    flag := uvbrick.getslice(index, 'flag');

	    itime := index[4];				# use function?
	    ifield := field_ids[itime];			# use function?
	    lsf_solve := F;
	    if (itime==rout.ntime) {			# the last time-slot
		lsf_solve := T;
	    } else if (field_ids[itime+1]!=ifield) {	# this field finished
		lsf_solve := T;
	    }
	    HAfield := [HAfield,HAdeg[itime]];		# add to vector

	    s := paste(itime,'ifield=',ifield,':');
	    s := paste(s,'RAdeg=',rout.field_RAdeg[ifield]);
	    s := paste(s,'DECdeg=',rout.field_DECdeg[ifield]);

	    avcx := rep(complex(0,0),rout.nifr);	    
	    for (icorr in rout.icorr_solve) {  		# usually XX/YY only
		avcx +:= slice[icorr,];			# accumulate
	    }
	    avcx /:= max(1,len(rout.icorr_solve));	# mean vis
	    lnavamp := private.jenmath.cx2real(avcx,'lnampl');	# convert to ln(ampl)
	    s := paste(s,'range(avcx)=',range(avcx)); 
	    # s := paste(s,'range(lnavamp)=',range(lnavamp));
	    print s; 

	    naccant := rep(0,rout.nant);		# counters
	    for (ifr in [1:rout.nifr]) {		# all available ifrs
	    	icorr := rout.icorr_solve[1];  		# solving for ants...!
	    	rcp := uvbrick.getrcp_ifr (ifr, icorr);

		dRA := dDEC := [];
		s := paste(rcp.ifrname,avcx[ifr],':');
		bothonsource := T;
		bothoffsource := T;
		for (i in [1:2]) {			# ant1/2
		    iant := rcp.iant[i];		# NB: skip if not stepping..!
		    dRA[i] := ant_RAdeg[iant,itime] - rout.field_RAdeg[ifield];
		    dDEC[i] := ant_DECdeg[iant,itime] - rout.field_DECdeg[ifield];
		    offsource[iant] := F;
		    if (abs(dRA[i])>dRAref) offsource[iant] := T;
		    if (abs(dDEC[i])>dDECref) offsource[iant] := T;
		    if (offsource[iant]) {		# at least one off-source
			bothonsource := F;
		    } else {				# at least one on-source
			bothoffsource := F;
		    }
		    s := paste(s,'off:',iant,offsource[iant]);
		}
		# print s := paste(s,'bothon/off:',bothonsource,bothoffsource);

		for (i in [1:2]) {			# ant1/2
		    iant := rcp.iant[i];		# NB: skip if not stepping..!
		    s1 := paste(rcp.ifrname,'iant=',iant,':');
		    if (bothoffsource) {
			# print s := paste(s1,'both off-source: -> skip');
			next;
		    } else if (bothonsource) {
			nbothonsource[iant] +:= 1;	# increment counter
			if (nbothonsource[iant]>1) {
			    s := paste(s1,'both on source:',nbothonsource[iant]);
			    # print paste(s,'-> skip');
			    next;			# skip (once only)
			}
		    } else if (!offsource[iant]) {	# off-source only
			# print s := paste(s1,'not off-source: -> skip');
			next;				# skip		
		    } 

		    naccant[iant] +:= 1;		# increment 
		    if (naccant[iant]>1) {		# only once per slice	
			# print s := paste(s1,'naccant=',naccant[iant],' -> skip');
			next;				# skip		
		    }

		    HAfield[iant] +:= HAdeg[itime];	# accumulate mean
		    nHAfield[iant] +:= 1;		# increment counter

	    	    cc := rep(0.0,nuk);			# coeff-vector
		    # lna := b1.x + b2.y + b3.xx + b4.yy + b5.xy + b6
		    cc[1] := dRA[i];			# x (coeff of b1) 
   		    cc[2] := dDEC[i];			# y (coeff of b2) 
		    cc[3] := dRA[i]*dRA[i];		# xx (coeff of b3) 
		    cc[4] := dDEC[i]*dDEC[i];		# yy (coeff of b4) 
		    cc[5] := dRA[i]*dDEC[i];		# xy (coeff of b5)
		    cc[6] := 1.0;			# (coeff of b6(=b0)) 
		    v := lnavamp[ifr];			# icorr...?
		    s := lsf[ilsf[iant]].accumulate(cc,v);# accumulate
		    print paste(s1,s);			# print always
		}
	    }

	    if (lsf_solve) {
		for (iant in rout.iiant) {
		    print s := paste('\n solve for iant=',iant,'ilsf=',ilsf[iant]);
		    pp.assume_circular := T;		# assume circular beam
		    if (pp.assume_circular) {		# b3-b4=0 -> cx=cy;
	    	    	cc := rep(0.0,nuk);
		        cc[3] := -(cc[4] := 100);	# give high weight (?);
	    		s := lsf[ilsf[iant]].accumulate(cc, 0.0, constreq=T);
	    		print paste('assume circular beam:',s);
		    } 

		    pp.assume_norotation := T;		# assume circular beam
		    if (pp.assume_norotation) {		# b5=0 (xy-term);
	    	    	cc := rep(0.0,nuk);
		        cc[5] := 100;			# give high weight (?);
	    		s := lsf[ilsf[iant]].accumulate(cc, 0.0, constreq=T);
	    		print paste('assume no rotation:',s);
		    }

	    	    # print lsf[ilsf[iant]].status();	# debugging
		    bb := lsf[ilsf[iant]].solve();	# solve for b-coeff
		    if (is_fail(bb)) {
			print s := 'iant=',iant,ilsf[iant],': lsf did not invert!'
			print bb;
	    		print lsf[ilsf[iant]].status();	# debugging
			next;				# try the next one..
		    }
		    print s := paste('solution: bb=',bb);

		    x0 := -500*bb[1]/bb[3];		# HA0 = -b1/(2b3);
		    y0 := -500*bb[2]/bb[4];		# DEC0 = -b2/(2b4);
		    s := paste('x0,y0 (mdeg)=',x0,y0);

		    sx := sqrt(abs(-1/bb[3]));		# gaussian width;
		    sy := sqrt(abs(-1/bb[4]));		# gaussian width;
		    s := paste(s,'sx,sy (deg)=',sx,sy);

		    lna00 := bb[6];
		    lna00 -:= 0.25*bb[1]*bb[1]/bb[3];
		    lna00 -:= 0.25*bb[2]*bb[1]/bb[4];
		    a00 := exp(lna00);
		    print s := paste(s,'a00=',a00);

		    rout.antrcp[1,iant,1,ifield] := x0;	# HA-error (mdeg)
		    rout.antrcp[2,iant,1,ifield] := y0;	# DEC-error (mdeg)

		    q := HAfield[iant]/max(1,nHAfield[iant]);
	    	    rout.field_meanHAdeg[ifield] := q;
		    HAfield[iant] := 0.0;		# reset accumulator
		    nHAfield[iant] := 0;		# reset counter

		    lsf[ilsf[iant]].init(nuk);		# init matrices again
		    nbothonsource[iant] := 0;		# reset counters
		}
	    }

	    # Display per slice[corr,ifr]?              # next slice
	}
	pgw.index();					# disable progress control
	private.decomprec_update_label(rout);
	private.BEAM_antsol(uvbrick, rout, pgw);	# plot all solutions
	uvbrick.addtohistory(hist);
	return rout;					# return record or T;
    }

# Helper function to plot the pointing solution for all antennas:

    private.BEAM_antsol := function (ref uvbrick, rout=[=], ref pgw=F) {
	title := paste('BEAM: estimated WSRT antenna pointing errors (x1000):');
	print s := paste('\n \n',title);
	label := 'BEAM_antsol';
	uvbrick.message(s);				# tw
	xname := xdescr := 'HA';
	yname := ydescr := 'DEC';
	yunit := 'degr';
	xunit := 'degr';
	yrange := [-90.0,90.0];				# DEC, degr
	xrange := [-90.0,90.0];				# HA, degr

	attrec := uvbrick.get_attached('BEAM');
	compare_simul := !is_boolean(attrec);
	# if (compare_simul) ydescr := paste(ydescr,'[black=sim.diff]');

	# inspect(rout,'rout');				# temporary

	group := pgw.group (label=label, trace=F,
			    xannot=F, yannot=F,
			    title=title, legend=F,
			    xname=xname, xdescr=xdescr, xunit=xunit, 
			    yname=yname, ydescr=ydescr, yunit=yunit); 
	for (iant in rout.iiant) {			# actual ants only
	    s := spaste('\n ant=',rout.ant_name[iant])
	    uvbrick.message(s);
	    xx := xx1 := yy := yy1 := [];
	    for (ifield in [1:rout.nfield]) {
		s := spaste('- field=',ifield,': ');
		HA := rout.field_meanHAdeg[ifield];		
		DEC := rout.field_DECdeg[ifield];
		xx := [xx,HA,HA+rout.antrcp[1,iant,1,ifield]];
		yy := [yy,DEC,DEC+rout.antrcp[2,iant,1,ifield]];
		dHADEC := rout.antrcp[,iant,1,ifield];
	    	s := spaste(s,sprintf('%-30s',spaste('est=',dHADEC,' mdeg')));
	    	if (compare_simul) {
		    dHADEC +:= attrec.antrcp[,iant,1,ifield];
		    xx1 := [xx1,HA,HA+dHADEC[1]];
		    yy1 := [yy1,DEC,DEC+dHADEC[2]];
		    s := paste(s,'(diff.simul:',dHADEC,'mdeg)');
	    	}
		print s;
	    	uvbrick.message(s);
	    }
	    label := spaste('RT',rout.ant_name[iant]); 
	    pgw.putline (group, label=label, xx=xx, yy=yy, trace=F,
			 style='arrows');
	    if (compare_simul) {
		label := spaste('d_RT',rout.ant_name[iant]); 
		pgw.putline (group, label=label, xx=xx1, yy=yy1, trace=F,
			     color='default', style='arrows');
	    }
	}
	pgw.putgroup(group, clear=T, plot=F, trace=F);
	pgw.set_display_option('showlegend',T);
	pgw.set_display_option('xzero',T);
	pgw.set_display_option('yzero',T);
	pgw.plot();
	return T;
    }



# Helper function to calculate the primary beam gain.
# Used in .decomp2slice();

    private.get_BEAM_gain := function (ref uvbrick, decomp=[=], index=[=], ref rr=F) {
	wider private;
	if (is_boolean(rr)) {				# initialise
	    val rr := [=];
	    print s := paste('get_BEAM_gain init:');
	    rr.basel := uvbrick.get('baseline');		# nominal B (m)
	    rr.fMHz := uvbrick.get('chan_freq');		# function of freq
	    rr.fwhm := uvbrick.fwhm(rr.fMHz, unit='deg');# function of freq
	    rr.ln2 := log(2)/log(exp(1));		# ln(2), used below 
	    rr.HAdeg := uvbrick.get('HA');		# function of time
	    rr.field_ids := uvbrick.get('field_ids');	# function of time
	    rr.DECdeg := uvbrick.get('DECdeg');		# function of field
	    rr.RAdeg := uvbrick.get('RAdeg');		# function of field
	    rr.dant_DECdeg := uvbrick.get('ant_DECdeg');	# [nant,ntime]		
	    rr.dant_RAdeg := uvbrick.get('ant_RAdeg');	# [nant,ntime]	
	    rr.nfield := uvbrick.length('field');
	    rr.ntime := uvbrick.length('time');
	    rr.nant := uvbrick.length('ant');
	    s := paste('ant_RA range(deg):',range(rr.dant_RAdeg));
	    s := paste(s,'ant_DEC range(deg):',range(rr.dant_DECdeg));
	    print s;
	    print 'decomp.antrcp:',type_name(decomp.antrcp),shape(decomp.antrcp);
	    for (ifield in [1:rr.nfield]) {
	    	sv := [rr.field_ids==ifield];		# selection vector
		s := paste('- ifield=',ifield,'n=',len(sv[sv]));
		s := paste(s,'DECdeg=',rr.DECdeg[ifield]);
		s := paste(s,'RAdeg=',rr.RAdeg[ifield]);
		print s;
	    	rr.dant_DECdeg[,sv] -:= rr.DECdeg[ifield];# w.r.t. field centre
	    	rr.dant_RAdeg[,sv] -:= rr.RAdeg[ifield];  # w.r.t. field centre
		for (iant in [1:rr.nant]) {
		    rr.dant_RAdeg[iant,sv] +:= decomp.antrcp[1,iant,1,ifield]/1000;
		    rr.dant_DECdeg[iant,sv] +:= decomp.antrcp[2,iant,1,ifield]/1000;
		}
	    }
	    s := paste('dant_RA range(mdeg):',range(rr.dant_RAdeg)*1000);
	    s := paste(s,'dant_DEC range(mdeg):',range(rr.dant_DECdeg)*1000);
	    print s;
	    print 'get_BEAM_gain() init:',field_names(rr);
	} 
	
	ifreq := index[2];
	print 'get_BEAM_gain() ifreq:',ifreq;
	rr.curr_fMHz := rr.fMHz[ifreq];			# needed later
	rr.curr_fwhm := rr.fwhm[ifreq];
	s := paste('ifreq=',ifreq,'fMHz=',rr.curr_fMHz);
	print s := paste(s,'fwhm(deg)=',rr.curr_fwhm);
	syf2 := sxf2 := ((0.5*rr.fwhm[ifreq])^2)/rr.ln2;# sxf^2, syf^2
	print 'cxf=',sxf,syf,rr.fwhm[ifreq];
	rr.ant_gain := array(0.0,rr.nant,rr.ntime);	# array of zeroes
	print s := paste('ant_gain range:',range(rr.ant_gain));
	rr.ant_gain -:= (rr.dant_RAdeg^2)/sxf2;   	# - ((x-x0)/sxf)^2 
	print s := paste('ant_gain range:',range(rr.ant_gain));
	rr.ant_gain -:= (rr.dant_DECdeg^2)/syf2; 	# - ((y-y0)/syf)^2 
	print s := paste('ant_gain range:',range(rr.ant_gain));
	rr.ant_gain := exp(rr.ant_gain); 		# exp() 

	# itime := index[4];
	# rr.curr_HArad := rr.HAdeg[itime]*private.deg2rad;
	# s := paste('itime=',itime,'HA(deg)=',rr.HAdeg[itime]);

	# ifield := rr.field_ids[itime];
	# rr.curr_DECrad := rr.DECdeg[ifield]*private.deg2rad;
	# rr.curr_RArad := rr.RAdeg[ifield]*private.deg2rad;
	# s := paste('ifield=',ifield,'DEC(deg)=',rr.DECdeg[ifield]);
	# print s := paste(s,'RA(deg)=',rr.RAdeg[ifield]);

	return T;					# return coeff array
    }




#------------------------------------------------------------------------
# Determination of WSRT DCB delay offsets.

    public.DELFI := function (ref uvbrick, pp=[=], ref pgw=F) {
	wider private;

	private.jenmisc.checkfield(pp,'decomp','rcp_dcb_delay_offset','DELFI');
	private.jenmisc.checkfield(pp,'step_nsec',10,'DELFI');
	private.jenmisc.checkfield(pp,'display',T,'DELFI');
	private.jenmisc.checkfield(pp,'suspend',F,'DELFI');
	private.jenmisc.checkfield(pp,'simulate',F,'DELFI');
	hist := paste('DELFI',pp);

	antnames := uvbrick.get('ant_shortname');       # assume WSRT 
	nant := uvbrick.length('ant');
	pp.stepant := rep(F,nant);			# T if stepping
	for (ant in pp.stepping_ants) {
	    iant := ind(antnames)[antnames==ant];
	    pp.stepant[iant] := T;
	}
	print nant,':',antnames,'pp.stepant=',pp.stepant;

	pp.display := T;                                # always....!?
	if (pp.display) pgw.clear();                    # necessary for replace?

	if (pp.simulate) {				# simlation only..
	    pp.simul_nsec::shape := [16,2];		# [ant,pol]
	    private.DELFI_simul(uvbrick, pp);		# simulate first
	    if (pp.display) {
		# NB: causes problems if pgw not defined....
		# rr := [xaxis='time', group='ifr', cx2real='ampl'];
		# private.uvb_plot.data_slices (uvbrick, pp=rr, jpl=pgw); 
	    }
	    uvbrick.attach('DELFI',pp);			# keep for later
	    return T;					# escape
	}

    	rout := public.init_decomprec (uvbrick, pp);	# output record
	if (is_fail(rout)) fail(rout);
	rout.descr := 'DELFI';

	private.check_fitter();				# define private.fitter; 
	private.check_lsf();				# define private.lsf; 
	private.lsf.init(rout.nuk);			# init matrices

	sliceaxes := "time";				# 
	if (is_record(pgw)) {				# plot-widget defined
	    private.index := uvbrick.initindex(sliceaxes, 'data', origin='DELFI',
					       showprogress=F);
	    pgw.index(private.index);			# progress control
	} else {
	    private.index := uvbrick.initindex(sliceaxes, 'data', origin='DELFI');
	}
	if (is_fail(private.index)) fail(private.index);
	private.index.suspend(pp.suspend);		# if F, start directly
	
    	while (private.index.next(index)) {
	    # print '\n',index;
	    pgw.message(private.index.get_progress_message());

	    slice := uvbrick.getslice(index);
	    flag := uvbrick.getslice(index, 'flag');
	    slice := private.jenmath.cx2real(slice,'ampl');
	    rcp := uvbrick.getrcp_ifr (index);
	    title := paste('ifr:',rcp.ifrname);
	    if (pp.stepant[rcp.iant[1]] && pp.stepant[rcp.iant[2]]) { 
		title := paste(title,'both ants are stepping: not used');
	    	private.DELFI_timefit(pp, slice, title, dofit=F, pgw=pgw);
		next;					# skip
	    } else if (pp.stepant[rcp.iant[1]]) {	# first only 
	    	dt := private.DELFI_timefit(pp, slice, title, pgw=pgw);
	    } else if (pp.stepant[rcp.iant[2]]) {	# second only 
	    	dt := -private.DELFI_timefit(pp, slice, title, pgw=pgw);
	    } else {	
		title := paste(title,'neither ants are stepping: not used');
	    	private.DELFI_timefit(pp, slice, title, dofit=F, pgw=pgw);
		next;					# skip
	    }
	    cc := rep(0.0,rout.nuk);
	    for (i in [1:2]) {
		iuk := public.getiuk(rout,1,rcp.iant[i],rcp.ipol[i]);
		if (is_boolean(iuk)) next;		# invalid, skip
		# iuk := rout.uktable[1,rcp.iant[i],rcp.ipol[i]];	
	    	cc[iuk] := rout.c12[i]; 		# 
	    }
	    s := private.lsf.accumulate(cc,dt);		# accumulate
	    print s;					# always
	}
	pgw.index();					# disable progress control

	for (k in ind(rout.constrequ)) {		# constraint equation(s):
	    s := private.lsf.accumulate(rout.constrequ[k], 0.0, constreq=T);
	    print s;
	}

	# print s := private.lsf.status();		# debugging
	rout.antrcp := private.lsf.solve();		# solve for rcp
	if (is_fail(rout.antrcp)) {
	    print rout.antrcp;				# temporary
	    print s := private.lsf.status();		# debugging
	    return rout.antrcp;
	}
	# print 'rout.antrcp:',rout.antrcp;
	rout.ndeg := pp.ndeg;				# special .sol record?
	private.decomprec_update_label(rout);
	private.DELFI_antsol (uvbrick, rout, pgw);	# display result
	uvbrick.addtohistory(hist);
	return rout;					# return record;
    }



#  Display the DELFI result:

    private.DELFI_antsol := function (ref uvbrick, ref rout=[=], ref pgw=F) {
	s := paste('Results of \'DELFI\' (ndeg=',rout.ndeg,'):');
	uvbrick.message(paste(' \n \n',s));
	label := 'DELFI_antsol';
	title := s;
	xname := 'ant';
	xdescr := 'antennas';
	xunit := ' ';
	yname := 'delay';
	ydescr := 'estimated WSRT DCB delay offsets';
	yunit := 'nsec';
	attrec := uvbrick.get_attached('DELFI');	# simulation info
	compare_simul := !is_boolean(attrec);		# only if record
	color := array("red blue",2);			# per pol
	style := array("cross star",2);			# per pol

	group := pgw.group (label=label, trace=F,
			    xannot=F, yannot=F,
			    title=title, legend=F,
			    xname=xname, xdescr=xdescr, xunit=xunit, 
			    yname=yname, ydescr=ydescr, yunit=yunit); 
	for (ipol in [1:2]) {
	    ydescr := paste(ydescr,rout.pol_name[ipol]);
	    duk := dduk := array(0.0,rout.nant);
	    sv := rep(F,rout.nant);			# selection vector
	    for (iant in [1:rout.nant]) {
		iuk := public.getiuk(rout,1,iant,ipol);
		if (is_boolean(iuk)) next;		# invalid, skip
		duk[iant] := rout.antrcp[iuk];
		sv[iant] := T;				# solution available
		s := spaste('- rcp=',rout.ant_name[iant],rout.pol_name[ipol])
		s := spaste(s,sprintf('%-12s',spaste(' (iuk=',iuk,'):')));
		s := spaste(s,sprintf('%-20s',spaste('est=',duk[iant],' nsec')));
		if (compare_simul) {
		    dduk[iant] := duk[iant] - attrec.simul_nsec[iant,ipol];
		    s := paste(s,'(diff with simulated:',dduk[iant],')');
		}
		uvbrick.message(s);
	    }
	    print s := ' ';
	    uvbrick.message(s);				# separate rcp1/2
	    xx := ind(duk);				# X/Y at integer
	    label := spaste('est',rout.pol_name[ipol]);
	    pgw.putline (group, label=label, trace=F,
			 xx=xx, yy=duk, ff=!sv,
			 color=color[ipol], style=style[ipol], size=5);
	    if (compare_simul) {
		label := spaste('dsim',rout.pol_name[ipol]);
		pgw.putline (group, label=label, trace=F,
			     xx=xx, yy=dduk, ff=!sv,
			     color=color[ipol], style='linespoints');
	    }
	}
	if (compare_simul) title := paste(title,' [dashed=diff with simulated]');
	xannot := rout.ant_fullname;
	pgw.labels(group, title=title, xdescr=xdescr, xannot=xannot, 
		   ydescr=ydescr, yunit=yunit);
	pgw.putgroup(group, clear=T, plot=F, trace=F);
	pgw.set_display_option('showlegend',T);
	pgw.set_display_option('yzero',T);
	pgw.plot();
	return T;
    }


# Helper function for .DELFI(): fit a parabola to the given time-series vv and
# return the difference between its peak and the centre of the series:

    private.DELFI_timefit := function (pp=[=], vv=[], title=' ', dofit=T, 
				       ref pgw=F) {
	tt := ind(vv)*pp.step_nsec;
	imid := max(1,as_integer(len(tt)/2));		
	tt -:= tmid := tt[imid];	
	dt := 0;					# default return value
	mess := title;					# for uvp.message()

	if (dofit) {
	    title := spaste(title,'(ndeg=',pp.ndeg,')');
	    coeff := cerrs := chisq := sigma := [];	# necessary? 
	    ok := private.fitter.fit(coeff, cerrs, chisq, tt, vv, sigma, pp.ndeg);
	    ok := private.fitter.eval(yy, tt, coeff);
	    if (pp.ndeg==2) {
	    	tmax := -0.5*coeff[2]/coeff[3];		# top: -b/(2a)
		ok := private.fitter.eval(ymax, tmax, coeff);
	    	A := coeff[1] - (coeff[2]^2) / (2*(coeff[3]^2));
	    	B2 := -6*coeff[3] / ((private.pi^2)*ymax);
	    	B := 1000 * sqrt(max(B2,0.));		# bw (MHz)
		s1 := spaste(' -> BW=',B,' MHz'); 
		title := paste(title,s1);
		mess := paste(mess,s1);
	    } else {
	    	tmax := -coeff[pp.ndeg]/(pp.ndeg*coeff[pp.ndeg+1]);
	    }
	    dt := tmax;		# return value (tmax is already w.r.t. the middle)
	}

	print 'DELFI_timefit: pp.display=',pp.display,'(set to T)';
	pp.display := T;
	if (pp.display) {			# remove condition...?
	    label := 'DELFI_timefit';
	    yname := ydescr := 'ampl';
	    yunit := 'cc';
	    xname := 'delay';
	    xdescr := 'nominal differential delay';
	    xunit := 'nsec';
	    group := pgw.group (label=label, trace=F,
				xannot=F, yannot=F,
				title=title, legend=F,
				xname=xname, xdescr=xdescr, xunit=xunit, 
				yname=yname, ydescr=ydescr, yunit=yunit); 
	    pgw.putline (group, label='data', trace=F,
			 xx=tt, yy=vv, color='cyan', style='cross');
	    if (dofit) {
		pgw.putline (group, label='fit', trace=F,
			     xx=tt, yy=yy, color='red', style='dashed');
	    	ydescr := paste(ydescr,'(expected: sinc-function)');
		pgw.putline (group, label='peak', trace=F,
			    xx=[tmax,tmax], yy=[0,max(yy)], 
			    color='yellow', style='dotted');
	    }
	    pgw.labels(group, ydescr=ydescr);
	    pgw.putgroup(group, clear=T, plot=F, replace=T, trace=F);
	    pgw.set_display_option('showlegend',T);
	    pgw.set_display_option('yzero',T)
	    pgw.plot();
	}
	return dt;				# return time-difference
    }


# Simulate the special 'DELFI'-observation for determining the delay-offsets
# of the WSRT Digital Continuum Backend (DCB). 

    private.DELFI_simul := function (ref uvbrick, pp=[=]) {
	wider private;
	private.jenmisc.checkfield(pp,'step_nsec',10,'DELFI_simul');
	private.jenmisc.checkfield(pp,'suspend',F,'BEAM');
	hist := paste('DELFI_simul',pp);

	ntime := uvbrick.length('time');
	imid := max(1,as_integer(ntime/2));		

	bwGHz := 0.001*uvbrick.get('resolution');
	pig := private.pi * bwGHz;

	sliceaxes := "time";				# 
	private.index := uvbrick.initindex(sliceaxes, 'data', origin='DELFI_simul');
	if (is_fail(private.index)) fail(private.index);
	private.index.suspend(pp.suspend);		# if F, start directly

    	while (private.index.next(index)) {
	    slice := uvbrick.getslice(index);		# 1D vector [time]
	    rcp := uvbrick.getrcp_ifr (index);
	    t1 := pp.simul_nsec[rcp.iant[1],rcp.ipol[1]];	# real delay of rcp1
	    t2 := pp.simul_nsec[rcp.iant[2],rcp.ipol[2]];	# real delay of rcp2
	    for (i in [1:ntime]) {
		dt := t1-t2;
		if (pp.stepant[rcp.iant[1]] && pp.stepant[rcp.iant[2]]) {
		    # both are stepping, do nothing; 
		} else if (pp.stepant[rcp.iant[1]]) {	# first only 
		    dt +:= (imid-i)*pp.step_nsec;
		} else if (pp.stepant[rcp.iant[2]]) {	# second only 
		    dt -:= (imid-i)*pp.step_nsec;
		}
		if (dt!=0) slice[i] *:= sin(dt*pig)/(dt*pig);
	    }
	    uvbrick.setslice(index, slice);		# replace
	}
	uvbrick.addtohistory(hist);
    }




#------------------------------------------------------------------------
# Decomposition into receptor ('antenna') contributions.

    public.decompant := function (ref uvbrick, pp=[=], ref pgw) {
	wider private;

	private.jenmisc.checkfield(pp,'decomp','rcp_gain_real','decompant');
	private.jenmisc.checkfield(pp,'iquv',[1.0,0.0,0.0,0.0],'decompant');
	private.jenmisc.checkfield(pp,'ref_ant','mean','decompant');
	private.jenmisc.checkfield(pp,'display',F,'decompant');
	private.jenmisc.checkfield(pp,'suspend',F,'decompant');
	private.jenmisc.checkfield(pp,'auxbrick',[=],'decompant');
	private.jenmisc.checkfield(pp,'convert2Jy',F,'decompant');
	private.jenmisc.checkfield(pp,'Tsys_nominal',100,'decompant');
	private.jenmisc.checkfield(pp,'aperteff',0.5,'decompant');
	print hist := paste('decompant',pp.decomp,pp.iquv);

	# print 'decompant: pp.ref_ant:',type_name(pp.ref_ant),pp.ref_ant;

    	rout := public.init_decomprec (uvbrick, pp, trace=F);
	if (is_fail(rout)) fail(rout);
	rout.descr := 'decompant';
	rout.auxbrick := pp.auxbrick;          # copy any auxiliary bricks
	rout.Tsys_nominal := pp.Tsys_nominal;             
	rout.aperteff := pp.aperteff;
	rout.collarea := 491;                           # WSRT 25m

	# Deal with some special cases:
	if (rout.decomp=='rcp_Tsys') {
	    if (has_field(pp,'antbrick')) {             # NFRA_TPON/OFF
		for (fname in field_names(pp.antbrick)) {
		    print fname,':',type_name(pp.antbrick[fname]);
		}
	    } else {
		print 'no field: antbrick';
		pp.antbrick := [=];
	    }
	} else if (rout.decomp=='rcp_gain_real') {
	    if (pp.convert2Jy) {                        # only if...
		v := rout.Tsys_nominal;      # i.e: sqrt(rout.Tsys_nominal^2);
		v *:= (1.0e+26 * private.kBoltzmann);
		v /:= (rout.aperteff * rout.collarea);
		uvbrick.convert2Jy(v);                  # convert...!
	    }
	}
	rout.data_unit := uvbrick.get('data_unit');

	private.check_lsf();				# least-squares fitter

	sliceaxes := "corr ifr";			# solve per freq/time
	if (rout.decomp=='rcp_delay_offset') {
	    sliceaxes := "corr freq ifr";		# solve per time
	    rout.ffMHz := uvbrick.get('chan_freq');	# freq-vector
	}

	if (is_record(pgw)) {				# plot-widget defined
	    private.index := uvbrick.initindex(sliceaxes, 'data', 
					       origin='decompant',
					       forwardonly=F, showprogress=F);
	    pgw.index(private.index);			# progress control
	} else {
	    private.index := uvbrick.initindex(sliceaxes, 'data', 
					       origin='decompant',
					       forwardonly=F);
	}
	if (is_fail(private.index)) fail(private.index);
	private.index.suspend(pp.suspend);		# if F, start directly

	ixtime := uvbrick.idim('time');			# position in index
	ixfreq := uvbrick.idim('freq');			# position in index

	first := T;
    	while (private.index.next(index)) {
	    print '\n',index;
	    pgw.message(private.index.get_progress_message());

	    slice := uvbrick.getslice(index);		# 2D array [corr,ifr]	
	    flag := uvbrick.getslice(index, 'flag');	# its flags	
	    vv := slice;				# copy
	    if (rout.decomp=='rcp_delay_offset') {
		# deals with phase gradients, see below.
	    } else if (rout.getStokesI2) {		# calc Stokes I
	    	si := sum(vv[rout.iXX,]);	        # XX (RR?) 
	    	si +:= sum(vv[rout.iYY,]);              # YY (LL?)    
	    	si /:= (2*rout.nifr);		        # mean (flags??)
	    	rout.stokesI := 2*si;		        # I=<XX+YY>=<RR+LL>

		# XX_calibrator := rout.compon.xyrl[1]; # I+Q, complex...	
		# U_calibrator := rout.compon.xyrl[2];	# U[+-iV] ~ U

	    	rout.mean_XY := sum(vv[rout.iXY,]);	# XY/LR! 
	    	rout.mean_YX := sum(vv[rout.iYX,]);	# YX/RL!
		rout.mean_XY /:= max(1,rout.nifr);      # flags..? 
		rout.mean_YX /:= max(1,rout.nifr);      # flags..? 
		rout.upzd := (rout.mean_XY + conj(rout.mean_YX))/2;
		if (abs(rout.upzd)==0) {
		    rout.upzd := rout.stokesI/100;      # safety.... 
		    print 'abs(rout.upzd)=0 -> upzd=',rout.upzd;
		}
		rout.stokesU := 2 * abs(rout.upzd);     # U (real!)
		rout.stokesU_pct :=100*rout.stokesU/abs(rout.stokesI);
		rout.PZD := arg(rout.upzd);             # X/Y PhaseZeroDiff     
		rout.PZD_deg := rout.PZD * private.rad2deg;   

		# abs(upzd) is the unknown (real!) U of the source.
		# arg(upzd) is the XY phase-zero difference (PZD).
		# NB: The scatter around upzd gives the size of epsilon*I!
		# It is assumed that the average effect of both
		# ellipticities and dippos errors over all ifrs is zero.
		# This is slightly different from assuming that the
		# average of these quantities over all antennas is zero!

		# vv[rout.iXY,] -:= rout.upzd;            # remove
		# vv[rout.iYX,] -:= conj(rout.upzd);      # remove
		vv[rout.iXY,] -:= rout.mean_XY;         # remove
		vv[rout.iYX,] -:= rout.mean_YX;         # remove

		if (first) {
		    print s := paste('..  mean_XY=',rout.mean_XY);
		    print s := paste('..  mean_YX=',rout.mean_YX);
		    print s := paste('..  upzd=',rout.upzd);
		    pct := 100*rout.stokesU/real(rout.stokesI);
		    s := paste('..  Stokes U=',rout.stokesU);
		    s := paste(s,'=',rout.stokesU_pct,'%');
		    print s := paste(s,'of Stokes I=',rout.stokesI);
		    s := paste('..  PZD=',rout.PZD,'rad');
		    print s := paste(s,'=',rout.PZD_deg,'degr');
		}

		vv /:= rout.stokesI;                   # divide by I
		if (first) {
		    print s := paste('.. divide by stokesI=',rout.stokesI);
		}
	    	vv := private.jenmath.cx2real(vv, rout.cx2real);

	    } else {
		for (i in rout.icorr_solve) {
		    vv[i,] /:= rout.compon.xyrl[i];	# divide by source model
		}
	    	vv := private.jenmath.cx2real(vv, rout.cx2real);
	    }
	    print 'converted input slice (vv):',type_name(vv),shape(vv);

	    do_lsfit := T;
	    if (rout.decomp=='rcp_pzd') {               # special case
		do_lsfit := F;                 # no lsfit needed (use rout.PZD)
	    } else if (first) {				# first time only
	    	private.lsf.init(rout.nuk);		# init matrices
	    } else {
	    	private.lsf.inityonly();		# use existing matrices
	    }

	    uvbrick.message('accumulating the solution matrix....');              
	    for (ifr in [1:rout.nifr]) {
		if (!do_lsfit) next;                    # not needed, skip
		for (icorr in rout.icorr_solve) {	# selected corrs
		    rcp := uvbrick.getrcp_ifr (ifr, icorr);	# receptor record
		    if (rout.ignore_autocorr) {         # ignore auto-correlations
			if (rcp.iant[1]==rcp.iant[2]) {
			    print 'decompant: ignore iant12=',rcp.iant;
			    next;                       # skip
			}
		    }
		    if (rout.decomp=='rcp_delay_offset') {
			spectrum := vv[icorr,,ifr];	# freq-spectrum
			v := private.jenmath.phase_gradient(spectrum, 
							    rout.ffMHz);
		    } else {
			if (flag[icorr,ifr]) next;	# flagged: skip .. problem?
			v := vv[icorr,ifr];		# left-hand value
		    }

		    cc := rep(0.0,rout.nuk);		# initialise coeff-vector
		    for (i in [1:2]) {			# rcp 1/2
			iuk := public.getiuk(rout,1,rcp.iant[i],rcp.ipol[i]);
			if (is_boolean(iuk)) next;	# invalid iuk, skip
	    	    	cc[iuk] := rout.c12[i]; 	# usually 1
		    }
		    s := private.lsf.accumulate(cc,v);	# accumulate
		    # if (first) print s;		# first time only
		}
	    }

	    if (do_lsfit) {
		for (k in ind(rout.constrequ)) {        # constraint equ(s):
		    s := private.lsf.accumulate(rout.constrequ[k], 
						0.0, constreq=T);
		    if (first) print s;
		}
	    }

	    # Generate the vector antrcp, by lsf.solve or otherwise:
	    uvbrick.message('solving for ant/rcp values....');                  
	    if (rout.decomp=='rcp_pzd') {               # no lsf used
		iukpra := 1;
		antrcp := rep(0.0,rout.nuk);            # 
		for (ipol in [1,2]) {
		    v := rout.PZD/2;                    # X
		    if (ipol==2) v := -v;               # Y
		    for (iant in [1:rout.nant]) {
			iuk := public.getiuk(rout,iukpra,iant,ipol);
			if (is_boolean(iuk)) {
			    next;			# invalid, skip
			}
			# print ipol,iant,iuk,': v_pzd=',v;
			antrcp[iuk] := v;               # store
		    }
		}
	    } else if (do_lsfit) {                      # lsf.solve
		# print s := private.lsf.status();	# debugging
		uvbrick.message('solving for ant/rcp values....');                  
		antrcp := private.lsf.solve();		# solve for ant/rcp
		if (is_fail(antrcp)) {
		    uvbrick.message('solution failed');                        
		    print antrcp;			# temporary
		    print s := private.lsf.status();	# debugging
		    return antrcp;
		}
	    }
	    uvbrick.message('solution finished successfully');

	    # Final touches on antrcp vector in some cases:
	    if (rout.cx2real=='logampl') {
		antrcp := 10^antrcp;			# -> gain factors
	    } else if (rout.varyambig) {		# deal with phase ambig.
	    	tryvec := [-2,-1,1,2]*private.pi2;	# trial vector (rad)
		uvbrick.message('looking for phase ambiguities...');
		s := private.lsf.varyambig(tryvec, niter=2, show=F);
		uvbrick.message('finished with phase ambiguities');
		antrcp := private.lsf.solvec();		# final solution
	    } 

	    # Store the result in rout.antrcp:
	    print 'rout.antrcp:',type_name(rout.antrcp),shape(rout.antrcp);
	    print ixfreq,ixtime,index[ixfreq],index[ixtime],' antrcp:',antrcp;
	    if (rout.decomp=='rcp_delay_offset') {
		rout.antrcp[,index[ixtime]] := antrcp;
	    } else {
		rout.antrcp[,index[ixfreq],index[ixtime]] := antrcp;
	    }

	    # Plot the ant/rcp solution (as a jenplot gsb object): 
	    pgw.mosaick(nrow=2, ncol=2);
	    public.decomp2gsb (uvbrick, rout, pgw);     # attach gsb to rout

	    # Check the result (assume that all uv-data should be identical!!):
	    appslice := public.decomp2slice(uvbrick, rout, index);
	    corrslice := public.decompcheck (rout, slice, appslice, 
					     pp.display, pgw);

	    if (pp.apply_corr) {
		uvbrick.setslice(index, corrslice);	# replace with corrected
	    }
	    first := F;					# indicates first time
	}
	pgw.index();					# disable progress control
	uvbrick.addtohistory(hist);
	return rout;					# return record or T;
    }


#------------------------------------------------------------------------
# Helper function: initialise decomprec (record that controls ant-decomposition):

    public.is_decomprec := function (ref rr, fname=F, origin=F) {
	serr := spaste('*** is_decomprec (',origin,'):')
	if (!is_record(rr)) {
	    print serr,'rr not a record:',type_name(rr);
	    return F;
	} else if (!has_field(rr,'type')) {
	    print serr,'not a decomp record (no type-field)';
	    return F;
	} else if (rr.type != 'decomp') {
	    print serr,'not a decomp record: type=',rr.type;
	    return F;
	} else if (!has_field(rr,'decomp')) {
	    print serr,'not a decomp record (no decomp-field)';
	    return F;
	} else if (is_string(fname) && !has_field(rr,fname)) {
	    print serr,'no field',fname;
	    return F;
	}
	return T;					# OK
    }



#--------------------------------------------------------------
# Convey a decompostion result to TMS (copied from mans_cal.g):
# The result is contained in a 'decomp-record' (rr);

    public.decomp2tms := function (ref uvbrick, pp=[=], rr=F) {
	if (!public.is_decomprec(rr)) {
	    print s:= 'decomp2tms: input is not a decomp-record!';
	    fail(s);
	}
	private.jenmisc.checkfield(pp,'send2tms',F,'decomp2tms');

	s1 := spaste('decomp2tms (decomp=',rr.decomp);
	s1 := spaste(s1,', send2tms=',rr.send2tms,'):');
	print s1;
	uvbrick.message(s1);                     # show progress       

	ifreq := 1;		# use solution for first (only?) freq channel
	itime := 1;		# use solution for first (only?) time slot
	dim := shape(rr.antrcp);
	ndim := len(dim);
	iukpra := 1;		# nr of unknowns per ant/rcp (usually 1)
	stms := ' ';		# string for tms

	rets := '\n';         # return-string (to be displayed in msbrick window)
	rets := paste(rets,'\n',s1);
	rets := paste(rets,'\n Results of antenna (receptor) decomposition:');

	tmsvar := T;
	for (ipol in [1,2]) {
	    for (iant in [1:rr.nant]) {
		iuk := public.getiuk(rr,iukpra,iant,ipol);
		if (is_boolean(iuk)) {
		    next;				# invalid, skip
		} 
		if (ndim==2) {				# e.g. rcp_delay_offset
		    v := rr.antrcp[iuk,itime];		# solved value
		} else if (ndim==3) {
		    v := rr.antrcp[iuk,ifreq,itime];	# solved value
		}
		rcp := uvbrick.getrcp_ant (iant, ipol);	# rcp is record
		ukname := spaste(rcp.rcpname);		# e.g. 5X etc....

		unit := ' ';
		if (rr.decomp == 'rcp_gain_real') {
		    v := 1/v;

		} else if (rr.decomp == 'rcp_Tsys') {
		    unit := '(K)';
		    v := 1/(v*v);
		    v *:= (rr.aperteff * rr.collarea);
		    v /:= (1.0e+26 * private.kBoltzmann);
		    v::print.precision := 4;

		} else if (rr.decomp == 'rcp_phase' || 
			   rr.decomp == 'rcp_pzd') {
		    v := -v;				# reverse sign for TMS!
		    unit := ' (degr)';
		    v *:= private.rad2deg;		# convert rad to degr
		    if (abs(v)<0.01) v := 0;		# enough precision (ASCII!)

		} else if (rr.decomp == 'rcp_delay_offset') {
		    v := -v;				# reverse sign for TMS!
		    unit := ' (nsec)';
	            v *:= 500/private.pi;		# rad/MHz -> nsec
		    if (abs(v)<0.01) v := 0;            # sufficient precision

		} else if (rr.decomp == 'rcp_ellipticity' ||
			   rr.decomp == 'rcp_dipposerr') {
		    tmsvar := F;                        # NOT a TMS variable
		    # print s := paste(s1,'not used by TMS:',rr.decomp);
		    # fail(s);

		# } else if (rr.decomp == 'rcp_gain_complex') {
		    # phase and gain together?

		} else {
		    tmsvar := F;                        # NOT a TMS variable
		    print s := paste(s1,'not recognised:',rr.decomp);
		    # fail(s);
		}
		v::print.precision := 4;
		suk := spaste(ukname,'=',v);		# e.g. 5Y=-23.56
		stms := paste(stms,' ',suk);		# for TMS
		rets := spaste(rets,'\n ',rr.TMSname,': ',suk,unit);
	    }
	}

	if (!tmsvar) {
	    rets := paste(rets,'\n \n This is NOT a TMS variable..');
	} else {
	    stms := paste(rr.TMSname,stms);			# string for TMS
	    # s := paste('rsh waw03 HandleMeasurement -d2 -dLogRecord 8');
	    s := paste('rsh waw03 HandleMeasurement -d1');
	    msname := 'test.MS';			# temporary (test)
	    msname := uvbrick.msname();             # get from uvbrick
	    s := paste(s,'-m',msname);
	    spwin := 1;				# temporary (test)...!
	    # s := spaste(s,' spwin=',spwin);       # temporary (TMS implem!)
	    rets := paste(rets,'\n',s);
	    if (pp.send2tms) {			# input parameter (T/F)
		stms := paste(s,stms);              # string for TMS
		print '\n decomp2tms: Send the following string to TMS:\n';
		print stms;
		r := shell(stms);	 		# convey string to TMS
		print 'shell(...) ->',r;            # print the result
		# print '\n decomp2tms: This was IT (i.e. after shell(...))\n';
		rets := paste(rets,'\n The results have been sent to TMS');
	    } else {
		rets := paste(rets,'\n The results have NOT (yet) been sent to TMS');
	    }
	} 
	return paste(rets,'\n');		# return string
    }

#--------------------------------------------------------------
# Make a jenplot data-group (gsb) out of a decompostion result;
# Attach the resulting gsb to the decomp-record rr;

    public.decomp2gsb := function (ref uvbrick, ref rr=F, ref pgw=F, 
				   hardcopy=F, trace=F) {
	if (!public.is_decomprec(rr)) {
	    print s:= 'decomp2gsb: input is not a decomp-record!';
	    fail(s);
	}
	s1 := spaste('decomp2gsb (decomp=',rr.decomp,'):');
	if (trace) print s1;
	uvbrick.message(s1);                     # show progress       
	rr.gsb.antrcp := F;                      # remove any existing

	compare := F;
	fnames := uvbrick.list_attached();
	# print 'uvbrick.list_attached: fnames=',fnames;
	for (fname in fnames) {
	    if (trace) print 'attached=',fname;
	    ss := split(fname,'_');              # split on underscore
	    if (ss[1] != 'simul') next;          # skip
	    rrsim := uvbrick.get_attached(fname);
	    if (!is_record(rrsim)) {
		print 'rrsim is not a record:',type_name(rrsim);
	    } else if (!has_field(rrsim,'simul')) {
		print 'rrsim has no field simul';
	    } else if (!is_record(rrsim.simul)) {
		print 'rrsim.simul is not a record:',type_name(rrsim.simul);
	    } else if (!has_field(rrsim.simul,rr.decomp)) {
		print 'rrsim.simul has no field',rr.decomp;
		print 'field_names:',field_names(rrsim.simul);
	    } else {                 
		sim_antrcp := rrsim.simul[rr.decomp];
		print 'sim_antrcp: shape=',shape(sim_antrcp);
		print ' rr.antrcp: shape=',shape(rr.antrcp);
		compare := T;                    # compare with simulated
	    }
	}

	# The record rr may have an auxiliary ant/uv brick attached:
	auxbrick := F;
	if (!has_field(rr,'auxbrick')) {
	    print 'rr has no field auxbrick';
	} else {
	    for (fname in field_names(rr.auxbrick)) {
		auxbrick := rr.auxbrick[fname];  # one only...?
		print 'auxbrick:',fname,type_name(auxbrick);
		auxbrick_data := auxbrick.get('data');
		print 'auxbrick_data:',fname,shape(auxbrick_data);
	    }
	}


	ifreq := 1;		# use solution for first (only?) freq channel
	itime := 1;		# use solution for first (only?) time slot
	dim := shape(rr.antrcp);
	ndim := len(dim);
	iukpra := 1;		# nr of unknowns per ant/rcp (usually 1)
	npol := rr.npol;        
	nant := rr.nant;
	vv := vvsim := array(0.0,npol*nant);
	tn := vv;               # used for Tnoise (rcp_Tsys)
	xannot := array(' ',npol*nant);
	for (ipol in [1:npol]) {
	    for (iant in [1:nant]) {
		iuk := public.getiuk(rr,iukpra,iant,ipol);
		if (compare) {
		    iuk_sim := public.getiuk(rrsim,iukpra,iant,ipol);
		}
		if (is_boolean(iuk)) {
		    print ipol,iant,'->',iuk,' skip invalid iuk';
		    next;				# invalid, skip
		} 
		# k := iant + (ipol-1)*nant;              # index in vv
		k := ipol + (iant-1)*npol;              # index in vv
		if (ndim==2) {				# e.g. rcp_delay_offset
		    vv[k] := rr.antrcp[iuk,itime];	# solved value
		    if (compare) vvsim[k] := sim_antrcp[iuk,itime];
		} else if (ndim==3) {
		    vv[k] := rr.antrcp[iuk,ifreq,itime];  # solved value
		    if (compare) vvsim[k] := sim_antrcp[iuk,ifreq,itime]; 
		}
		rcp := uvbrick.getrcp_ant (iant, ipol);	# rcp is record
		xannot[k] := spaste(rcp.rcpname);	# e.g. 5X etc....
		s := paste(ipol,iant,'-> iuk=',iuk,'k=',k,xannot[k]);
		s := paste(s,'vv[k]=',vv[k]);
		if (trace) print s;
		
		# Special case: calculate derived values:
		if (rr.decomp == 'rcp_Tsys') {        
		    if (is_boolean(auxbrick)) {
			print rr.decomp,': auxbrick is boolean!';
		    } else {
			jant := auxbrick.get_iant(rcp.antid1);
			if (is_boolean(jant)) {
			    tn[k] := 0;                 # message..?
			} else {
			    tn[k] := auxbrick_data[ipol,1,jant,1];
			}
			print k,ipol,iant,rcp.antid1,'jant=',jant,'->',tn[k];
		    }
		}
	    }
	}

	xname := 'rcp';
	xdescr := paste('receptors (see also the top margin)');
	xunit := ' ';
	title := paste('Results of receptor decomposition:',rr.decomp);
	label := 'decomp2gsb';
	legend := rr.legend;		        # uvbrick info
	yname := 'y';
	ydescr := rr.TMSname;
	yunit := ' ';

	if (rr.decomp == 'rcp_gain_real') {
	    vv := 1/vv;			        # invert for TMS!....?

	} else if (rr.decomp == 'rcp_Tsys') {
	    # ydescr := 'IF Tsys (=Trec+Tsky+Tant)';
	    ydescr := 'IF Tsys';
	    yunit := 'K';
	    vv := 1/(vv*vv);
	    vv *:= (rr.aperteff * rr.collarea);
	    vv /:= (1.0e+26 * private.kBoltzmann);
	    tn *:= vv;                          # Tnoise (K)
	    
	} else if (rr.decomp == 'rcp_phase' || 
		   rr.decomp == 'rcp_pzd') {
	    yunit := 'degr';
	    vv *:= private.rad2deg;	        # convert rad to degr
	    vvsim *:= private.rad2deg;	        # convert rad to degr
	    vv := -vv;			        # reverse sign for TMS!

	} else if (rr.decomp == 'rcp_ellipticity') {
	    ydescr := 'dipole ellipticity';
	    vv := -vv;			        # reverse sign for TMS!

	} else if (rr.decomp == 'rcp_dipposerr') {
	    ydescr := 'dipole position angle error';
	    yunit := 'degr';                    # convert to angle/degr
	    vv := -vv;			        # reverse sign for TMS!
	    vv := asin(vv) * private.rad2deg;   # ....check this...!
	    
	} else if (rr.decomp == 'rcp_delay_offset') {
	    yunit := 'nsec';
	    vv *:= 500/private.pi;	        # rad/MHz -> nsec
	    vvsim *:= 500/private.pi;	        # rad/MHz -> nsec
	    vv := -vv;			        # reverse sign for TMS!

       	# } else if (rr.decomp == 'rcp_gain_complex') {

	} else {
	    vv := -vv;			        # reverse sign for TMS!
	    print s := paste(s1,'\n**** not recognised:',rr.decomp);
	    # fail(s);                          # temporary
	}

	# Make a multi-line 'report' and attach it to rr;
	s := paste('Report of the ant/rcp decomposition:',rr.decomp,':');
	ss := paste('\n \n ',s,'\n');
	ss := paste(s,'\n',legend,'\n');
	ss := paste(s,'\n',rr.decomp,':');
	# vv::print.precision := 4;
	for (k in ind(vv)) {
	    s := paste(xannot[k],':');
	    s1 := sprintf(' %7.3g %s',vv[k],yunit);
	    s := paste(s,sprintf('%-15s',s1));  # left-adjusted
	    if (rr.decomp=='rcp_Tsys') {        # special case
		s1 := sprintf('-> Tnoise= %-5.3g K',tn[k]);
		s := paste(s,sprintf('%-10s',s1));
	    }
	    s := paste(s,' :',xannot[k]); 
	    ss := paste(ss,'\n',s);             # attach line to ss
	}
	ss := paste(ss,'\n');
	rr.report.antrcp := ss;                 # attach to rr;

	# Make a gsb-object (group) and attach it to rr;
	group := pgw.group (label='decomp2gsb', trace=F,
			    xannot=xannot, yannot=F,
			    title=title, legend=legend,
			    xname=xname, xdescr=xdescr, xunit=xunit, 
			    yname=yname, ydescr=ydescr, yunit=yunit);
	pgw.putline (group, label='solution', trace=F,
		     yy=vv, color='red');
	if (compare) {
	    pgw.putline (group, label='simulated', trace=F,
			 yy=vvsim, color='green');
	}
	pgw.gsb_field(group, name='plot_full', value=T);
	pgw.put_gsb(group, irow=1, icol=1);       # plot panel
	rr.gsb.antrcp := group;                   # attach to rr.gsb
	return T;
    }

# Initialise the decomposition record (should be cleaned up at some point)

    public.init_decomprec := function (ref uvbrick, pp=[=], trace=F) {
	private.jenmisc.checkfield(pp,'decomp',F,'init_decomprec');
	private.jenmisc.checkfield(pp,'iquv',[1.0,0,0,0],'init_decomprec');
	private.jenmisc.checkfield(pp,'calibrator','?','init_decomprec');
	private.jenmisc.checkfield(pp,'ref_ant',F,'init_decomprec');

	rr := [=];				# decomprec
	rr.type := 'decomp';			# identification
	rr.decomp := pp.decomp;			# decompose what
	rr.TMSname := rr.decomp;                # default, see below

	rr.descr := 'init_decomprec';           # temporary descr
	rr.msname := uvbrick.msname();          # MS name

	rr.legend := uvbrick.legend();		# plot-legend
	nlegend := len(rr.legend);
	# rr.legend[nlegend+:=1] := spaste('\n .....'); # example

	rr.ref_ant := pp.ref_ant;		# reference antenna
	rr.compon := [=];			# source component
	rr.compon.iquv := pp.iquv;		# Stokes I,Q,U,V
	rr.compon.lm := [0.0,0.0];		# field-centre only
	uvbrick.iquv2corr (rr.compon);		# convert iquv to XX,XY,RL etc
	rr.calibrator := pp.calibrator;		# calibrator (may be string)
	s := spaste('\n calibrator=',pp.calibrator,' IQUV=',rr.compon.iquv);
	rr.legend[nlegend+:=1] := s;

	# Get information from the uvbrick:
	rr.nifr := uvbrick.length('ifr'); 
	rr.ncorr := uvbrick.length('corr'); 
	rr.nfreq := uvbrick.length('freq'); 
	rr.ntime := uvbrick.length('time'); 
	rr.nant := uvbrick.length('ant');
	rr.nfield := uvbrick.length('field');
	rr.ant_name := uvbrick.get('ant_shortname');	# WSRT: 0,1,..,A,B,C,D
	rr.ant_fullname := uvbrick.get('ant_name');	# WSRT0, WSRTA, etc
	rr.pol_name := uvbrick.get('pol_name');		# WSRT: X,Y
	rr.ifr_name := uvbrick.get('ifr_shortname');	# WSRT: 01, 6A etc
	rr.ifr_fullname := uvbrick.get('ifr_name');	# WSRT0-WSRT1 etc
	rr.corr_name := uvbrick.get('corr_name');	# WSRT: XX, XY etc

	# Generic default values for the various decomp-parameters: 
	private.uktable(uvbrick, rr, trace=trace);	# attach table of unknowns
	rr.axes := "nuk freq time";			# string vector
	dimout := [rr.nuk,rr.nfreq,rr.ntime];		# default shape of result
	rr.apply_sliceaxes := "corr ifr";		# used in uvbrick.apply()
	rr.cx2real := 'none';				# cx->real conv.
	rr.c12 := [1,1];				# matrix coeff.
	rr.combinop := 'add';				# rcp combination operation
	rr.vinit := 0.0;				# see decomp2slice()
	rr.applyop := 'divide';				# ifr correction operation.
	rr.corr_solve := "XX XY YX YY RR RL LR LL";	# corrs used for solving (all)
	rr.corr_apply := "XX XY YX YY RR RL LR LL";	# corrs used for applying (all)
	rr.ignore_autocorr := T;                        # ignore auto-correlations
	rr.varyambig := F;				# deal with phase.ambig
	rr.getStokesI2 := F;				# if T, get stokesI from XX/YY
	rr.stokesI := 1.0;				# default, just in case
	rr.stokesU := 0.0;				# default, just in case
	rr.Tsys_nominal := 100;                         # WSRT, default (K)
	rr.aperteff := 0.5;                             # WSRT, default
	rr.collarea := 491;                             # WSRT, 25m mirror (m2)

	# Adjust the decomp-parameters according to the specific application:
	if (rr.decomp=='rcp_gain_real' ||
	    rr.decomp=='rcp_Tsys') {
	    if (rr.decomp=='rcp_gain_real') rr.TMSname := 'GainFactor';
	    rr.vinit := 1.0;
	    rr.combinop := 'multiply';			# rcp combination operation
	    rr.cx2real := 'logampl';
	    rr.corr_solve := "XX YY RR LL";		# corr-selection
	    rr.constrequ := [=];			# constraint equ. record
	    rr.constrequ[1+len(rr.constrequ)] := rep(0.0001,rr.nuk); # universal?

	} else if (rr.decomp=='rcp_gain_complex') {
	    rr.vinit := complex(1.0,0.0);		# see decomp2slice()
	    rr.combinop := 'multiply';			# rcp combination operation
	    rr.corr_solve := "XX YY RR LL";		# corr-selection
	    rr.constrequ := [=];			# constraint equ. record
	    # constraints ??

	} else if (rr.decomp=='rcp_phase') {
	    rr.TMSname := 'PhaseZero';                  # see decomp2tms()
	    rr.cx2real := 'phase_rad';		        # to radians
	    rr.corr_solve := "XX YY RR LL";		# corr-selection
	    rr.c12 := [1,-1];
	    rr.varyambig := T;				# deal with phase ambig.
	    # NB: uses rr.constreq made in private.uktable();
	    rr.legend[nlegend+:=1] := spaste('\n reference antenna=',rr.ref_ant);

	} else if (rr.decomp=='rcp_diperr_complex') {
	    rr.corr_solve := "XY YX RL LR";		# corr-selection
	    rr.corr_apply := "XY YX RL LR";		# corr-selection
	    rr.applyop := 'subtract';			# ifr correction operation.
	    rr.vinit := complex(0.0,0.0);		# see decomp2slice()
	    rr.getStokesI2 := T;			# get I/2 for solve/apply
	    rr.c12 := [1,-1];
	    rr.constrequ := [=];			# constraint equ. record
	    rr.constrequ[1+len(rr.constrequ)] := rep(1.0,rr.nuk);	# mean
	    # rr.constrequ[1+len(rr.constrequ)] := rep(0.0001,rr.nuk); 
	    rr.legend[nlegend+:=1] := spaste('\n reference antenna: mean over all');

	} else if (rr.decomp=='rcp_ellipticity') {
	    rr.corr_solve := "XY YX RL LR";		# corr-selection
	    rr.corr_apply := "XY YX RL LR";		# corr-selection
	    rr.applyop := 'subtract';			# ifr correction operation.
	    rr.getStokesI2 := T;			# get I/2 for solve/apply
	    rr.cx2real := 'imag_part';
	    rr.constrequ := [=];			# constraint equ. record
	    rr.constrequ[1+len(rr.constrequ)] := rep(1.0,rr.nuk);	# mean
	    # rr.constrequ[1+len(rr.constrequ)] := rep(0.0001,rr.nuk); 
	    rr.legend[nlegend+:=1] := spaste('\n reference antenna: mean over all');

	} else if (rr.decomp=='rcp_dipposerr') {
	    rr.corr_solve := "XY YX RL LR";		# corr-selection
	    rr.corr_apply := "XY YX RL LR";		# corr-selection
	    rr.applyop := 'subtract';			# ifr correction operation.
	    rr.c12 := [1,-1];
	    rr.getStokesI2 := T;			# get I/2 for solve/apply
	    rr.cx2real := 'real_part';
	    rr.constrequ := [=];			# constraint equ. record
	    rr.constrequ[1+len(rr.constrequ)] := rep(1.0,rr.nuk);	# mean
	    # rr.constrequ[1+len(rr.constrequ)] := rep(0.0001,rr.nuk);
	    rr.legend[nlegend+:=1] := spaste('\n reference antenna: mean over all');

	} else if (rr.decomp=='ant_dipposerr') {
	    rr.corr_solve := "XY YX RL LR";		# corr-selection
	    rr.corr_apply := "XY YX RL LR";		# corr-selection
	    rr.applyop := 'subtract';			# ifr correction operation.
	    rr.c12 := [1,-1];
	    rr.getStokesI2 := T;			# get I/2 for solve/apply
	    rr.constrequ := [=];			# constraint equ. record
	    rr.constrequ[1+len(rr.constrequ)] := rep(1.0,rr.nant);	# mean
	    # rr.constrequ[1+len(rr.constrequ)] := array(antpos,rr.nant);# slope
	    rr.legend[nlegend+:=1] := spaste('\n reference antenna: mean over all');

	} else if (rr.decomp=='rcp_pzd') {              # Preferred
	    rr.TMSname := 'XYPhaseZeroOffset';          # see decomp2tms()
	    rr.cx2real := 'phase_rad';		        # not relevant....?
	    rr.getStokesI2 := T;			# get I/2 for solve/apply
	    rr.corr_solve := "XY YX RL LR";		# corr-selection
	    # rr.corr_solve := "XY YX";		        # corr-selection....?
	    rr.c12 := [1,-1];
	    rr.constrequ := [=];			# no constraint equ.

	} else if (rr.decomp=='rcp_pzd') {              # Alternative....?
	    rr.TMSname := 'XYPhaseZeroDiff';            # see decomp2tms()
	    rr.cx2real := 'phase_rad';		        # to radians
	    rr.corr_solve := "XY YX RL LR";		# corr-selection
	    rr.c12 := [1,-1];
	    rr.varyambig := T;				# deal with phase ambig. (?)
	    rr.constrequ := [=];			# constraint equ. record
	    for (ipol in [1,2]) {
		for (iant in [1:rr.nant]) {
		    iuk := public.getiuk(rr,1,iant,ipol);
		    if (is_boolean(iuk)) next;		# invalid, skip
		    # iuk := rr.uktable[1,iant,ipol];	# NB: iukpra=1
		    if (ipol==1 && iant==1) {
			iukref := iuk;			# reference iuk
		    } else {
			cc := rep(0.0,rr.nuk);
			cc[iukref] := 1;
			if (ipol==1) cc[iuk] := -1;
			if (ipol==2) cc[iuk] := 1;
			# print rr.decomp,ipol,iant,iuk,'constraint coeff:',cc;
	    	    	rr.constrequ[1+len(rr.constrequ)] := cc;
		    }
		}
	    }


	} else if (rr.decomp=='rcp_delay_offset') {
	    rr.TMSname := 'DelayOffset';                # see decomp2tms()
	    rr.corr_solve := "XX YY RR LL";		# corr-selection
	    rr.axes := "rcp time";			# uses freq phase-gradient
	    dimout := [rr.nuk,rr.ntime];		# default shape of result
	    rr.c12 := [1,-1];
	    rr.apply_sliceaxes := "corr freq ifr";	# used in uvbrick.apply()
	    # NB: uses rr.constreq made in private.uktable();
	    rr.legend[nlegend+:=1] := spaste('\n reference antenna=',rr.ref_ant);

	} else if (rr.decomp=='rcp_dcb_delay_offset') {	# i.e. DELFI (WSRT)
	    rr.cx2real := 'ampl';			# cx->real conv.
	    rr.c12 := [1,-1];				# matrix coeff.
	    rr.corr_apply := "XX YY RR LL";		# corrs used for applying 
	    rr.constrequ := [=];			# constraint equ. record
	    rr.constrequ[1+len(rr.constrequ)] := rep(0.0001,rr.nuk); # universal?

	} else if (rr.decomp=='ant_pointing') {
	    rr.axes := "nuk nant freq field";		# string vector
	    dimout := [2,rr.nant,rr.nfreq,rr.nfield];	# 
	    rr.cx2real := 'ampl';			# cx->real conv.
	    rr.combinop := 'multiply';			# rcp combination operation
	    rr.applyop := 'multiply';			# ifr correction operation.
	    rr.corr_solve := "XX YY RR LL";		# corrs used for solving 
	    rr.ukpra_name := "bx by bxx byy bxy b0";	# parameter labels
	    private.uktable(uvbrick, rr, uktype='ant', nukpra=6);# special table of unknowns
	    rr.constrequ := [=];			# constraint equ. record

	} else if (rr.decomp=='ant_position') {		# i.e. MAKECAL (WSRT)
	    rr.cx2real := 'phase_rad';			# cx->real conv.
	    rr.c12 := [1,-1];
	    rr.corr_solve := "XX YY RR LL";		# corrs used for solving
	    private.uktable(uvbrick, rr, uktype='ant', nukpra=3);# special table of unknowns
	    rr.ukpra_name := "dx dy dz";		# parameter labels
	    rr.constrequ := [=];			# constraint equ. record
	    for (i in seq(shape(rr.ccpra)[2])) {	# [nuk,nukpra,npol];
	    	# print 'iukra=',i,'constreq=',rr.ccpra[,i,1];
	    	rr.constrequ[1+len(rr.constrequ)] := rr.ccpra[,i,1];
	    }
	    # rr.constrequ[1+len(rr.constrequ)] := rep(0.0001,rr.nuk); # universal?

	} else {
	    print s := paste('not recognised',rr.decomp);
	    fail(s);
	}

    	r := private.decomp_selcorr (uvbrick, rr);	# icorr_solve/apply
	if (is_fail(r)) fail(r);			# corrs not available

	rr.antrcp := array(0.0,prod(dimout));		# output array (with coeff)
	if (len(dimout)>1) rr.antrcp::shape := dimout;# adjust shape
	# print 'rr.antrcp:',type_name(rr.antrcp),shape(rr.antrcp);
	private.decomprec_update_label(rr);

	rr.simul := [=];        # for attaching simulated error values
	rr.auxbrick := [=];     # for attaching auxiliary ant/uv brick(s)
	rr.gsb := [=];          # for attaching gsb data-objects (jenplot)
	rr.report := [=];       # for attaching multi-line reports

	return rr;					# decomprec
    }

# Helper function to update the decomprec label (after filling rr.antrcp)

    private.decomprec_update_label := function (ref rr=[=]) {
	if (!public.is_decomprec(rr)) return F;
	dim := shape(rr.antrcp);
	rr.label := spaste('decomprec (',rr.decomp,') ',dim);
	return T;
    } 


# Helper function that makes the fields rr.icorr_solve and rr.icorr_apply
# from the already existing fields rr.corr_solve/apply, and the available corrs.
# Used by .decompant() above, but also by msbrick.corrupt(). 

    private.decomp_selcorr := function (ref uvbrick, ref rr, corrs=F) {
	if (is_boolean(corrs)) corrs := uvbrick.get('corr_name');# default
	allcorrs := "XX XY YX YY RR RL LR LL";			# all corrs
	if (!has_field(rr,'corr_solve')) rr.corr_solve := allcorrs;	# ..?
	if (!has_field(rr,'corr_apply')) rr.corr_apply := allcorrs;	# ..?

	for (i in ind(corrs)) {
	    fname := spaste('i',corrs[i]);
	    rr[fname] := i;				 # e.g. rr.iXY:=3;
	    # print spaste('decomp_selcorr: rr.',fname,'=',rr[fname]);
	}

	rr.icorr_solve := [];				 # corr-selection
	rr.icorr_apply := [];				 # corr-selection
	for (i in ind(corrs)) {
	    if (any(corrs[i]==rr.corr_solve)) {
		rr.icorr_solve := [rr.icorr_solve,i];
	    }
	    if (any(corrs[i]==rr.corr_apply)) {
		rr.icorr_apply := [rr.icorr_apply,i];
	    }
	}

	rr.cifr_name := ' ';                        # ifr_corr names 
	rr.cifr_name_solve := ' ';                  # 'solve' ifrs only 
	rr.cifr_name_apply := ' ';                  # 'apply' ifrs only
	ncifr_apply := ncifr_solve := ncifr := 0;   # counter       
	for (ifr in [1:rr.nifr]) {
	    for (icorr in [1:rr.ncorr]) {
		s := spaste(rr.ifr_name[ifr],'_');
		s := spaste(s,rr.corr_name[icorr]); # e.g. 0A_XY
		rr.cifr_name[ncifr+:=1] := s;
		if (any(icorr==rr.icorr_solve)) {
		    rr.cifr_name_solve[ncifr_solve+:=1] := s;
		}
		if (any(icorr==rr.icorr_apply)) {
		    rr.cifr_name_apply[ncifr_apply+:=1] := s;
		}
	    }
	}

	s := paste('rr.icorr_solve:',rr.corr_solve,'->',rr.icorr_solve);
	# print s := paste(s,corrs[rr.icorr_solve]);
	s := paste('rr.icorr_apply:',rr.corr_apply,'->',rr.icorr_apply);
	# print s := paste(s,corrs[rr.icorr_apply]);
	if (len(rr.icorr_solve)<=0) {
	    s := '\n ****************************\n'
	    s := spaste(s,'Required corrs (',rr.corr_solve,')')
	    s := paste(s,'not available, only:',corrs);
	    s := paste(s,'\n ****************************\n');
	    fail(paste('decomp_selcorr:',s));
	}
	return T;
    }

#============================================================================
# Helper function: make a translation table from the 1D vector of 'unknowns' in
# an ant/rcp decomposition to a 2D corr-ifr slice of this particular uvbrick:
# The 'unknown' can be either receptors (rcp) or antennas (ant) (feeds, really):
# Usually nukpra, the nr of unknowns (nuk) to be solved per rcp/ant is 1, but 
# in some cases it can be more (e.g. MAKECAL has 3-6);
# Attach all to the (existing!) decomp-record (rr); 

    private.uktable := function (ref uvbrick, ref rr=[=], 
				 uktype='rcp', nukpra=1, trace=F) {
	rr.nifr := uvbrick.length('ifr'); 
	rr.ncorr := uvbrick.length('corr'); 
	rr.nant := uvbrick.length('ant');
	rr.npol := 2;					# always
	rr.iiant := [];					# actual ants
	rr.iipol := [];					# actual pols
	rr.nukpra := nukpra;
	rr.ukpra_name := ' ';				# parameter labels
	rr.uktype := uktype;
	rr.uktable := array(0, rr.nukpra, rr.nant, rr.npol);	# 3D array
	nuk := 0;
	uk := [];					# 1D vector
	rcp := [];
	for (ifr in [1:rr.nifr]) {
	    for (icorr in [1:rr.ncorr]) {
		rcp := uvbrick.getrcp_ifr (ifr, icorr);	# rcp is record
		nn := (rcp.iant-1)*rr.nukpra;		# 2 unique ant nrs 
		if (rr.uktype=='rcp') nn +:= (rcp.ipol-1)*rr.nukpra*rr.nant;
		for (i in [1:2]) {
		    rr.iiant[rcp.iant[i]] := rcp.iant[i];	# actual iants
		    rr.iipol[rcp.ipol[i]] := rcp.ipol[i];	# actual ipols
		}
		for (iukpra in [1:rr.nukpra]) {
		    rr.ukpra_name[iukpra] := spaste('par',iukpra);	# default
		    for (i in ind(nn)) {
			iuk := iukpra + nn[i];
		    	if (iuk>len(uk)) uk[iuk] := 0;	# extend vector
		    	uk[iuk] +:= 1;			# count occurence
		    	rr.uktable[iukpra, rcp.iant[i], rcp.ipol[i]] := iuk;
		    	if (uk[iuk]==1) {
			    # s := paste('uktable:',iukpra,rcp.iant[i],rcp.ipol[i]);
			    # print s := paste(s,'-> iuk=',iuk);
			}
		    }
		}
	    }
	}
	if (trace) print rr.iiant := rr.iiant[rr.iiant>0];	# actual iants only
	if (trace) print rr.iipol := rr.iipol[rr.iipol>0];	# actual iants only

	# print rr.uktable;
	ii := ind(uk)[uk>0];				# all non-zero uk
	for (iuk in ind(ii)) {	
	    sv := [rr.uktable==ii[iuk]];		# i.e. k==rcp   
	    rr.uktable[sv] := iuk;
	    # print 'uktable: iuk=',iuk,'rcp=',ii[iuk],'nsv=',len(sv);
	}
	rr.nuk := max(rr.uktable);			# total nr of unknowns
	if (trace) print 'rr.uktable:\n',rr.uktable;

	private.ccpra (rr, trace=trace);                # constrain coeff

	return T;
    }

# Helper function called from private.uktable():
# Deals with a possible reference antenna (using the string rr.ref_ant), and
# fill in the array rr.ccpra with coefficients for solution constraint equations:

    private.ccpra := function (ref rr, trace=F) {
	rr.ref_iant := F;
	if (is_boolean(rr.ref_ant)) {
	    # no ref_ant supplied: use the mean (...?)
	} else if (rr.ref_ant=='mean') {
	    # use the mean over all antennas (default)
	} else if (is_string(rr.ref_ant)) {             # assume: ant_name
	    sv := (rr.ant_name==rr.ref_ant);            # selection vector
	    if (any(sv)) {
		rr.ref_iant := ind(sv)[sv];             # ant nr of ref_ant
	    }
	} else {
	    # not recognised: use the mean (....?)
	}
	# print 'ccpra(): ant_name=',rr.ant_name;
	s := spaste('ref_ant=',rr.ref_ant,' -> ref_iant=',rr.ref_iant);
	if (trace) print s;

	# Fill the array of constraint coefficients:
	rr.ccpra := array(0,rr.nuk,rr.nukpra,rr.npol);  # init with zeroes
	for (iukpra in [1:rr.nukpra]) {                 # nuk/rcp or nuk/ant
	    for (ipol in [1:rr.npol]) {
		s := paste('ccpra(): iukpra=',iukpra,'ipol=',ipol,':');
	    	for (iant in [1:rr.nant]) {
		    if (is_boolean(rr.ref_iant)) {      # no reference antenna
			iuk := public.getiuk(rr,iukpra,iant,ipol);
			if (is_boolean(iuk)) next;	# invalid iuk
			rr.ccpra[iuk,iukpra,ipol] := 1;
		    } else {                            # reference antenna
			iuk := public.getiuk(rr,iukpra,rr.ref_iant,ipol);
			if (is_boolean(iuk)) next;	# invalid iuk
			rr.ccpra[iuk,iukpra,ipol] := 1;
			break;                          # escape
		    }
		}
		if (trace) print s,rr.ccpra[,iukpra,ipol];
	    }
	}

	# Make default constraint equation record:
	rr.constrequ := [=];                            # init empty record
	for (iukpra in [1:rr.nukpra]) {                 # in this case: rr.nukpra=1
	    for (ipol in [1:rr.npol]) {
		rr.constrequ[1+len(rr.constrequ)] := rr.ccpra[,iukpra,ipol];
	    }
	}
	
	return T;
    }

# Helper function to get (and check!) the index nr of a specific 'unknown':

    public.getiuk := function (ref rr=[=], iukpra, iant, ipol) {
    if (!public.is_decomprec(rr,'uktable')) {
	    return F;
	}
	dim := shape(rr.uktable);
	if (iukpra<=0 || iukpra>dim[1]) {
	    print '*** getiuk: iukpra=',iukpra,': out of range:',1,dim[1];
	    return F;
	} else if (iant<=0 || iant>dim[2]) {
	    print '*** getiuk: iant=',iant,': out of range:',1,dim[2];
	    return F;
	} else if (ipol<=0 || ipol>dim[3]) {
	    print '*** getiuk: ipol=',ipol,': out of range:',1,dim[3];
	    return F;
	}
	iuk := rr.uktable[iukpra,iant,ipol];		# index of unknown
	if (iuk<=0) {
	    # print '*** getiuk: iuk=',iuk,'<=0!',dim,iukpra,iant,ipol;
	    return F;
	}
	return iuk;
    }

#===========================================================================
# Helper function to check the decomposition solution:
# NB: Assumes central point source and no noise. Just checks whether the numbers
#     for all ifrs are the same after correction (separately for each correlation).
# NB: A slice is usually 2D [ncorr,nifr], but can als be 3D [ncorr,nfreq,nifr].

    public.decompcheck := function (ref rout, slice, appslice, 
                                    display=F, ref pgw=F, trace=F) {
	s := paste('decompcheck:',type_name(slice),shape(slice));
	s := paste(s,type_name(appslice),shape(appslice));
	if (trace) print s;
	if (rout.applyop=='*' || rout.applyop=='multiply') {
	    corrslice := slice * appslice;
	} else if (rout.applyop=='/' || rout.applyop=='divide') {
	    sv := [abs(appslice)==0.0];			# check zeroes
	    corrslice := (slice/appslice);		# if zero -> NaN
	    corrslice[sv] *:= 0.0;			# ......? 
	} else if (rout.applyop=='+' || rout.applyop=='add') {
	    corrslice := slice + appslice;
	} else if (rout.applyop=='-' || rout.applyop=='subtract') {
	    corrslice := slice - appslice;
	} else {
	    print 'rout.applyop not recognised:',rout.rout.applyop;
	    return F;
	}


	# For each corr (XX,XY etc), the numbers for all ifrs should be the same 
	# (within the noise), because we assume a central point-source.
	dim := shape(slice);
	ndim := len(dim);
	if (ndim==1) {					# if one corr only
	    dim := [1,dim];
	    ndim := 2;
	}
	ncorr := dim[1];
	if (ndim==2) {					# [ncorr, nifr]
	    nifr := dim[2];
	} else if (ndim==3) {				# [ncorr, nfreq, nifr]
	    nifr := dim[3];
	} else {
	    s := paste('decompcheck: unrecognised ndim=',ndim,' dim=',dim);
	    print s;
	    return F;
	}

	s := paste('decompcheck:',rout.applyop,dim,ncorr,nifr,'rms=');
	mean_solved := 0;
	rms_solved := 0;
	for (icorr in [1:ncorr]) {
	    n := max(1,nifr);
	    if (ndim==2) {
		mean := sum(corrslice[icorr,])/n;
		diff := abs(corrslice[icorr,] - mean);
	    } else if (ndim==3) {
		mean := sum(corrslice[icorr,,])/n;		
		diff := abs(corrslice[icorr,,] - mean);
	    }
	    rms := sqrt(sum(abs(diff*diff))/n);     # store in rout?
	    s := paste(s,rms);
	    if (any(icorr==rout.icorr_solve)) {     # if more than 1?
		mean_solved := mean;                # used in plot
		rms_solved := rms;                  # used in plot
	    }
	}
	print s;

	# Make gsb plotting object(s), and attach them to rout:
	if (display) {
	    private.decompcheck2gsb(rout, slice, corrslice, 
				    ndim, ncorr, nifr, pgw);
	}
	return corrslice;			# return corrected slice
    }

# Helper function to make gsb plotting object(s), attaching them to rout:

    private.decompcheck2gsb := function (ref rout, ref slice, ref corrslice, 
					 ndim=F, ncorr=F, nifr=F, 
					 ref pgw=F, trace=F) {
	s := paste('decompcheck2gsb:');
	if (trace) print s; 

	s1 := paste('Results of receptor decomposition:',rout.decomp);
	title := s1;
	legend := s1;
	legend := paste(legend,'\n',rout.legend);   # uvbrick info
	legend := paste(legend,'\n');               # space
	xname := 'ifr';
	xdescr := paste('ifrs (see also the top margin)');
	xunit := ' ';
	style_before := [=];
	style_before.XX := style_before.RR := 'plus';
	style_before.YY := style_before.LL := 'cross';
	style_before.XY := style_before.RL := style_before.XX;
	style_before.YX := style_before.LR := style_before.YY;
	style_after := [=];
	style_after.XX := style_after.RR := 'star';
	style_after.YY := style_after.LL := 'triangle';
	style_after.XY := style_after.RL := style_after.XX;
	style_after.YX := style_after.LR := style_after.YY;
	label := 'decompcheck2gsb';
	yname := 'y';
	cx2real := 'ampl';                          # default	
	ydescr := 'amplitude';
	yunit := rout.data_unit;

	textobj := pgw.textobj(label=label, title=title,
			       text=F, trace=F);
	group := pgw.group (label=label, trace=F,
			    xannot=F, yannot=F,
			    title=title, legend=legend,
			    xname=xname, xdescr=xdescr, xunit=xunit, 
			    yname=yname, ydescr=ydescr, yunit=yunit); 
	
	# iscomplex := (is_complex(slice) || is_dcomplex(slice));
	rvsi_group := T;                            # make rvsi group
	if (rout.decomp=='rcp_phase') {
	    cx2real := 'phase_deg';		    # conversion 
	    ydescr := 'phase';
	    yunit := 'deg';
	    legend := paste(legend,'\n receptor phase errors');
	} else if (rout.decomp=='rcp_gain_real') {
	    s := paste('nominal Tsys=',rout.Tsys_nominal,'K');
	    legend := paste(legend,'\n',s);
	    s := paste('aperture eff=',rout.aperteff);
	    legend := paste(legend,'\n',s);
	    legend := paste(legend,'\n');
       	    legend := paste(legend,'\n receptor gain errors');
	} else if (rout.decomp=='rcp_Tsys') {
	    yunit := 'Jy';
	    s := paste('nominal Tsys=',rout.Tsys_nominal,'K');
	    legend := paste(legend,'\n',s);
	    s := paste('aperture eff=',rout.aperteff);
	    legend := paste(legend,'\n',s);
	    s := paste('antenna physical area=',rout.collarea,'m2');
	    legend := paste(legend,'\n',s);
	    legend := paste(legend,'\n');
       	    legend := paste(legend,'\n receptor (IF) Tsys estimation');
	} else if (rout.decomp=='rcp_delay_offset') {
	    rvsi_group := F;                        # not relevant
	    cx2real := 'phase_rad';		    # conversion 
	    ydescr := paste('phase gradient');
	    yunit := paste('rad/MHz');
	    s := paste('\n NB: 1 rad/MHz ~ 160 nsec delay'); 
	    legend := paste(legend,s);
	} else if (rout.decomp=='rcp_pzd') {
	    cx2real := 'phase_deg';		    # conversion 
	    ydescr := 'phase';
	    yunit := 'deg';
	    legend := paste(legend,'\n X/Y phase zero difference');
	    rout.upzd::print.precision := 2;
	    s := spaste('upzd=',rout.upzd);
	    legend := paste(legend,'\n',s);
	    rout.PZD::print.precision := 2;
	    rout.PZD_deg::print.precision := 6;
	    s := spaste('PZD= (+/-)',rout.PZD,' rad');
	    s := spaste(s,' = (+/-)',rout.PZD_deg,' deg');
	    legend := paste(legend,'\n',s);
	    rout.stokesI::print.precision := 2;
	    s := paste('stokes I=',rout.stokesI);
	    legend := paste(legend,'\n',s);
	    rout.stokesU::print.precision := 2;
	    rout.stokesU_pct::print.precision := 2;
	    s := spaste('stokes U= (+/-)',rout.stokesU);
	    s := spaste(s,' = (+/-)',rout.stokesU_pct,'%');
	    legend := paste(legend,'\n',s);
	} else if (rout.decomp=='rcp_dipposerr') {
	    cx2real := 'real_part';
	    ydescr := 'real part of cross-pols';
	    legend := paste(legend,'\n dipole position angle errors');
	} else if (rout.decomp=='rcp_ellipticity') {
	    cx2real := 'imag_part';
	    ydescr := 'imaginary part of cross-pols';
	    legend := paste(legend,'\n dipole ellipticity factors');
	} else {
	    cx2real := 'ampl';	
	    ydescr := 'amplitude (???)';
	    legend := paste(legend,'\n not recognised:',rout.decomp);
	}
	
	# Get the relevant data from the slice(s) and convert:
	if (ndim==2) {				# [ncorr,nifr]
	    vv1 := vv2 := yy1 := yy2 := [=];
	    yy2_solve := [];
	    for (icorr in rout.icorr_solve) {
		fname := rout.corr_name[icorr];
		vv1[fname] := slice[icorr,];
		yy1[fname] := private.jenmath.cx2real(vv1[fname],cx2real);
		vv2[fname] := corrslice[icorr,];
		yy2[fname] := private.jenmath.cx2real(vv2[fname],cx2real);
		solve_stat := private.jenmath.statistarr(yy2[fname]);
		solve_stat.rms::print.precision := 2;
		s := spaste(fname,': rms=',solve_stat.rms);
		legend := paste(legend,'\n solution:',s,yunit);

		yy2_solve := [yy2_solve,yy2[fname]];
	    }
	    
	    yy2_solve_stat := private.jenmath.statistarr(yy2_solve);
	    # yy2_solve_stat.rms::print.precision := 2;
	    # print s := spaste('rms=',yy2_solve_stat.rms);
	    # legend := paste(legend,'\n solution:',s,yunit);
	    
	} else if (ndim==3) {  # [ncorr,nfreq,nifr]: assume rcp_delay_offset
	    yy1 := yy2 := [=];
	    for (icorr in rout.icorr_solve) {   # solved corrs only
		fname := rout.corr_name[icorr];
		yy1[fname] := yy2[fname] := [];
		for (ifr in [1:nifr]) {
		    vv1 := slice[icorr,,ifr];       # vector!
		    g1 := private.jenmath.phase_gradient(vv1, rout.ffMHz);
		    yy1[fname][ifr] := g1;
		    vv2 := corrslice[icorr,,ifr];   # vector!
		    g2 := private.jenmath.phase_gradient(vv2, rout.ffMHz);
		    yy2[fname][ifr] := g2;
		}
	    }
	}
	
	
	# Append data-lines to the jenplot 'group':
	for (fname in field_names(yy1)) {
	    label := spaste(fname,'_in');
	    pgw.putline (group, label=label, trace=F,
			 yy=yy1[fname], 
			 style=style_before[fname], color='red'); 
	    label := spaste(fname,'_out');
	    pgw.putline (group, label=label, trace=F,
			 yy=yy2[fname],
			 style='lines', color='green');
	}
	
	# Indicate the minimum and maximum 'acceptable' values:
	plot_minmax := T;
	label_minmax := ' ';
	if (rout.decomp=='rcp_delay_offset') {
	    yy_minmax := [-1,1]/160;               # nsec
	    label_minmax[1] := paste('-1 nsec');
	    label_minmax[2] := paste('+1 nsec');
	} else if (rout.decomp=='rcp_phase') {
	    yy_minmax := [-1,1]/10;                # 0.1 rad
	    label_minmax[1] := paste('-5 degr');
	    label_minmax[2] := paste('+5 degr');
	} else if (rout.decomp=='rcp_gain_real' ||
		   rout.decomp=='rcp_Tsys') {
	    yy_minmax := yy2_solve_stat.mean * [0.9,1.1];  
	    label_minmax[1] := paste('0.9');
	    label_minmax[2] := paste('1.1');
	} else {
	    plot_minmax := F;
	}
	if (plot_minmax) {                  
	    for (i in [1:2]) {
		pgw.putline (group, label=label_minmax[i], 
			     yy=rep(yy_minmax[i],2), xx=[1,nifr], 
			     style='dashed', color='blue'); 
	    }
	}
	
	# Transfer the plot-labels:
	xannot := rout.ifr_name;                    # ifr names
	legend := paste(legend,'\n');
 	legend1 := legend;                          # copy
	legend1 := paste(legend1,'\n separate points: before correction');
	legend1 := paste(legend1,'\n connected points: after correction');
	pgw.labels(group, trace=F,
		   xannot=xannot, yannot=F,
		   title=title, legend=legend1,
		   xname=xname, xdescr=xdescr, xunit=xunit, 
		   yname=yname, ydescr=ydescr, yunit=yunit);
	pgw.gsb_field(group, name='plot_full', value=T);
	pgw.gsb_field(group, name='showlegend', value=F);
	pgw.put_gsb(group, irow=2, icol=1, full=T); # plot panel
	rout.gsb.decompcheck := group;              # keep for later
	
	# Make another plot with real vs imaginary data:
	if (rvsi_group) {
	    label := 'decompcheck_rvsi';
	    xdescr := 'real part of XX and YY';
	    ydescr := 'imaginary part of XX and YY';
	    xunit := yunit := rout.data_unit;
	    legend2 := legend;                      # copy
	    group := pgw.group (label=label, trace=F);
	    for (fname in field_names(vv1)) {
		s1 := paste(fname,'before correction:',style_before[fname]);
		legend2 := paste(legend2,'\n',s1);
		legend := paste(legend,'\n',s1);
		s1 := paste(fname,' after correction:',style_after[fname]);
		legend2 := paste(legend2,'\n',s1);
		legend := paste(legend,'\n',s1);
		label := spaste(fname,'_in');
		pgw.putline (group, label=label, trace=F,
			     yy=imag(vv1[fname]), xx=real(vv1[fname]),
			     style=style_before[fname], color='red'); 
		label := spaste(fname,'_out');
		pgw.putline (group, label=label, trace=F,
			     yy=imag(vv2[fname]), xx=real(vv2[fname]),
			     style=style_after[fname], color='green');
	    }
	    for (k in [1,4]) {                     # XX/YY
		XXYY := rout.compon.xyrl[k];       # calibrator 	
		label := 'XX=(I+Q)/2';
		if (k==4) label := 'YY=(I-Q)/2';
		pgw.put_arrow (group, label=label,trace=F,
			       xy1=[0,0], xy2=[real(XXYY),imag(XXYY)],
			       size=5, color='cyan');
	    }
	    if (rout.decomp=='rcp_ellipticity' ||
		rout.decomp=='rcp_dipposerr' ||
		rout.decomp=='rcp_pzd') {
		xdescr := 'real part of XY and YX';
		ydescr := 'imaginary part of XY and YX';
		for (k in [-1,1]) {
		    xx := [0.0,k*rout.stokesU/2];
		    xy1 := [0.0, 0.0];
		    xy2 := [k*rout.stokesU/2, 0.0];
		    label := 'U/2';
		    if (k<0) label := '-U/2';
		    pgw.put_arrow (group, label=label,trace=F,
				   xy1=xy1, xy2=xy2, size=5);
		    yy := [0.0,k*imag(rout.upzd)];
		    xx := [0.0,real(rout.upzd)];
		    label := 'upzd';
		    if (k<0) label := 'upzd*';
		}
		for (fname in "mean_XY mean_YX") {
		    xy2 := [real(rout[fname]),imag(rout[fname])];
		    pgw.put_arrow (group, label=fname, trace=F,
				   xy1=[0,0], xy2=xy2, size=5);
		}
		xx := yy := [0:100]*private.pi/50;
		r := abs(rout.upzd);
		pgw.put_circle (group, xy=[0,0], trace=F,
				radius=abs(rout.upzd),
				style='dashed');
		xx := [0.0,real(rout.stokesI/2)];
		yy := [0.0,imag(rout.stokesI/2)];
		xy2 := [real(rout.stokesI/2),imag(rout.stokesI/2)];
		pgw.put_arrow (group, label='I/2', trace=F,
			       xy1=[0,0], xy2=xy2, size=5);
	    }
	    pgw.legend(textobj,legend, clear=T); 
	    pgw.labels(group, trace=F,
		       xannot=F, yannot=F,
		       title=title, legend=legend2,
		       xname=F, xdescr=xdescr, xunit=xunit, 
		       yname=F, ydescr=ydescr, yunit=yunit); 
	    pgw.gsb_field(group, name='showlegend', value=F);
	    pgw.gsb_field(group, name='plot_full', value=T);
	    pgw.put_gsb(group, irow=2, icol=2, full=T);   # plot panel
	    rout.gsb.decompcheck_rvsi := group;     # keep
	}

	# Deal with the mosaick-legend (in textobj):
	# NB: Should come last (otherwise an axis-box is drawn..?)
	legend := paste(legend,'\n ');
	for (icorr in rout.icorr_solve) {
	    name := rout.corr_name[icorr];
	    if (name=='XX') {
		s1 := 'XXij = gxi gxj (I + Q)';
	    } else if (name=='YY') {
		s1 := 'YYij = gyi gyj (I - Q)';
	    } else if (name=='XY') {
		s1 := 'XYij = gxi gyj (U + iV + Dxiyj I) exp(iPZD)';
	    } else if (name=='YX') {
		s1 := 'YXij = gyi gxj (U - iV + Dyixj I) exp(-iPZD)';
	    } else {
		next;
	    }
	    legend := paste(legend,'\n',s1);
	}
	legend := paste(legend,'\n ');
	legend := paste(legend,'\n user=',shell('whoami'));
	legend := paste(legend,'\n reduction date: ',shell('date'));
	pgw.legend(textobj,legend, clear=T);
	pgw.put_gsb(textobj, plot=T, irow=1, icol=2, trace=trace);	
	rout.gsb.decomp_legend := textobj;          # keep
	hardcopy := T;                              # argument?
	if (hardcopy) pgw.print();                  # 
	return T;
    }

#-------------------------------------------------------------------------
# Generic functin to display stuff, depending on value of rr.decomp 

    public.decompshow := function (ref uvbrick, ref rr=[=], ref pgw=F) {
	if (!public.is_decomprec(rr)) {
	    return F;
	} else if (rr.decomp=='rcp_dcb_delay_offset') {
	    return private.DELFI_antsol (uvbrick, rr, pgw);
	} else if (rr.decomp=='ant_pointing') {
	    return private.BEAM_antsol (uvbrick, rr, pgw);
	} else if (rr.decomp=='ant_position') {
	    return private.MAKECAL_antsol (uvbrick, rr, pgw);
	} else {
	    print '*** decompshow: not recognised:',rr.decomp;
	    return F;
	}
    }


#=======================================================================
# Finished. Initialise and return the public interface:

    private.init();				# initialise
    return ref public;				# ref?

};						# closing bracket of uvbrick
#=======================================================================

# inspect(uvbrick_decomp(),'uvb_decomp');		# create and inspect

#===========================================================
# Remarks and things to do:
#================================================================


