#  uvbrick_fcs.g: operations for uvbrick (fit, clip, statistics etc).

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
# $Id: uvbrick_fcs.g,v 19.0 2003/07/16 03:38:55 aips2adm Exp $

#---------------------------------------------------------

pragma include once
# print 'include uvbrick_fcs.g  h01sep99'

include 'jenmath.g';			# math functions 
include 'jenmisc.g';			# .checkfield() etc 
include 'jenindex.g';		        # index display/control

# include 'uvbrick_plot.g';		# uvbrick plotting functions

# include 'textformatting.g';		
# include 'tracelogger.g';
# include 'buttonscript.g';		# script generation


#=========================================================
test_uvbrick_fcs := function () {
    private := [=];
    public := [=];
};


#==========================================================================
#==========================================================================
#==========================================================================

uvbrick_fcs := function () {
    private := [=];
    public := [=];

# Initialise the object (called at the end of this constructor):
    
    private.init := function () {
	wider private;
	const private.pi := acos(-1);		# use atan()....?
	const private.pi2 := 2*private.pi;	
	const private.rad2deg := 180/private.pi;
	const private.deg2rad := 1/private.rad2deg;

	private.jenmath := jenmath();           # use for fft too
	private.jenmisc := jenmisc();           # checkfield() etc
	# private.uvb_plot := uvbrick_plot();

	private.fitter := F;			# only when needed (mathematics.g)
	private.lsf := F;			# only when needed (lsfit.g)
	private.fft := F;			# only when needed (mathematics.g)
	private.index := F;			# only when needed (uvbrick_index.g)

	# private.tf := textformatting();	# text-formatting functions
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
    
    
    #-------------------------------------------------
    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('uvbrick_fcs event:',$name,$value);
	# print s;
    }
    whenever public.agent->message do {
	print 'uvbrick message-event:',$value;
    }
    #-------------------------------------------------

    public.message := function (text=F) {
	if (is_record(private.tw)) {
	    private.tw.append(text);		# see input argument
	} else {
	    print text;				# temporary
	}
    }

    public.private := function (copy=F) {
	if (copy) return private;			# copy
	return ref private;				# reference 
    }


#------------------------------------------------------------------------
# Plot 1D vectors along the specified axis, in the specified style:

    public.statistics := function (ref uvbrick, pp=[=], ref pgw=F) {
	wider private;

	private.jenmisc.checkfield(pp,'variable',F,'statistics');
	private.jenmisc.checkfield(pp,'cx2real','ampl','statistics');
	private.jenmisc.checkfield(pp,'print',F,'statistics');
	private.jenmisc.checkfield(pp,'plot',T,'statistics');

	slice_axes := private.info.axes.data;		# all data-axes
	for (axis in pp.variable) {			# all slice-axes
	    slice_axes := slice_axes[slice_axes!=axis];	# remove step-axis
	}
	private.index := uvbrick.initindex(slice_axes, 'data', 
			origin='statistics', autofinish=T, forwardonly=F);
	if (is_fail(private.index)) fail(private.index);

	rout := [=];					# output record
	debugprint := F;

	s := paste(' \n \n ** Statistics over slices with axes:',slice_axes);
	s := paste(s,', cx2real=',pp.cx2real);
	rout.header := s;
	if (debugprint) print s;

	private.index.agent -> suspend(F);		# start immediately
	n := 0;
	slicesize := 0;
    	while (private.index.next(index)) {
	    n +:= 1;					# counter
	    s2 := private.index.getlabel(full=F);	# current label
	    ns2 := len(split(s2,''));
	    if (n==1) {					# first time only
		fnames := "slice min max mean rms flagged length";
		flen := [3+ns2,rep(10,4),rep(8,2)];	# field widths
		s1 := '';
		fi := 0;
		for (fname in fnames) {
	    	    rout[fname] := [];			# numeric
	    	    fmt := spaste('%',flen[fi+:=1],'s');
	    	    # print fi,fname,fmt
	    	    s1 := paste(s1,sprintf(fmt,fname));
		}
		rout.slice := ' ';			# string
		if (debugprint) print s1;  
		s := paste(s,'\n',s1);			# header
	    }
	    fi := 0;					# field index
	    s1 := '';
	    rout.slice[n] := s2;  
	    fmt := spaste('%-',flen[fi+:=1],'s');
	    s1 := paste(s1,sprintf(fmt,s2));  

	    yy := uvbrick.getslice(index);		
	    slicesize := len(yy);
	    ff := uvbrick.getslice(index, 'flag');	# its flags
	    yy := private.jenmath.cx2real(yy[!ff],pp.cx2real);	# convert to real

	    r := private.jenmath.statistarr(yy);		# data-statistics
	    for (fname in "min max mean rms dmean drms") {
		rout[fname][n] := r[fname];
	    	fmt := spaste('%',flen[fi+:=1],'s');
	    	# print fi,fname,fmt
	    	s1 := paste(s1,sprintf(fmt,spaste(r[fname])));  
	    }

	    r := private.jenmath.statistarr(ff);		# flag-statistics
	    for (fname in "ntrue length") {
		rout[fname][n] := r[fname];
	    	fmt := spaste('%',flen[fi+:=1],'s');
	    	# print fi,fname,fmt
	    	s1 := paste(s1,sprintf(fmt,spaste(r[fname])));  
	    }
	    if (debugprint) print s1;
	    uvbrick.message(s1);				# to text-window
	    s := paste(s,'\n',s1);
    	}
	rout.flagged := rout.ntrue;			# is better name
	rout.string := ' ';				# default: none
	if (pp.print) rout.string := s;			# if required only

	# Plot the result, if required:
	if (pp.plot) {
	    pgw.clear();
	    fname := "rms min mean max drms dmean";
	    for (i in ind(fname)) {
		if (has_field(rout,fname[i])) {
		    pgw.newitem(label=fname[i],yy=rout[fname[i]],
					style='linespoints');
		} else {
		    print 'statistics: rout-field not recognised',fname[i];
		}
	    }
	    nd := spaste(len(slice_axes),'D');
	    title := paste('statistics (non-flagged) for',nd,'data-slices');
	    title := spaste(title,' (size=',slicesize,')');
	    title := paste(title,'with axes:',slice_axes);
	    xlabel := spaste('slice-number (stepping axes: ',pp.variable,')');
	    if (pp.cx2real=='none') pp.cx2real := 'complex';
	    ylabel := paste('statistics of ',pp.cx2real);
	    pgw.labels(title, xlabel, ylabel);
	    pgw.plot();
	}

	return rout;					# record
    }


#------------------------------------------------------------------------
# Fit function (e.g. polynomial) along the specified axis:
# The result is an array with function coefficients, one set for
# each 1D vector in the axis direction.
# Works on complex data too (separate fits on real and imag parts).

    public.fit := function (ref uvbrick, pp=[=], ref pgw=F) {
	wider private;

	private.jenmisc.checkfield(pp,'fitfunc','polynomial','fit');
	private.jenmisc.checkfield(pp,'fitaxis','freq','fit');
	private.jenmisc.checkfield(pp,'ndeg',1,'fit');
	private.jenmisc.checkfield(pp,'clip_nsigma',-1,'fit');
	private.jenmisc.checkfield(pp,'ignore_left',0,'fit');
	private.jenmisc.checkfield(pp,'ignore_centre',0,'fit');
	private.jenmisc.checkfield(pp,'ignore_right',0,'fit');
	private.jenmisc.checkfield(pp,'result','polcoeff','fit');
	private.jenmisc.checkfield(pp,'display',T,'fit');
	print hist := paste('fit',pp.fitfunc,pp.axis,pp.result);

	if (pp.fitfunc=='polynomial') {
	    private.check_fitter();
	    pp.fitaxis := pp.fitaxis[1];		# one only....?
	    ncoeff := 1 + pp.ndeg[1];			# nr of pol.coeff
	} else {
	    print s := paste('fit(): not recognised:',pp.fitfunc);
	    fail(s);
	}

	private.index := uvbrick.initindex(pp.fitaxis, 'data', origin='fit');
	if (is_fail(private.index)) fail(private.index);

	title := paste('fit',pp.fitfunc,'ndeg=',pp.ndeg);	# -> pgw?

	complexdata := uvbrick.iscomplex();		# datatype complex? 

 	# xx := uvbrick.getcoord_old(pp.fitaxis);	# xx coordinate-vector
 	xx := uvbrick.getcoord(pp.fitaxis);		# xx coordinate-vector
	if (is_fail(xx)) fail('no xx-vector found');

	igflag := rep(F,(nxx:=len(xx)));
	if (pp.ignore_left>0) igflag[1:min(pp.ignore_left,nxx)] := T;
	if (pp.ignore_right>0) igflag[nxx:max(nxx-pp.ignore_right+1,1)] := T;
	if (pp.ignore_centre>0) {
	    imid := 1+as_integer(nxx/2);
	    n2 := as_integer(pp.ignore_centre/2);
	    igflag[max(1,imid-n2):min(nxx,imid+n2)] := T;
	}
	if (any(igflag)) print 'fit: iigflag=',ind(igflag)[igflag];

	if (pp.result=='subtract') {
	    rout := T;					# output is boolean (?)
	} else if (pp.result=='replace') {
	    rout := T;					# output is boolean (?)
	} else if (pp.result=='polcoeff') {
	    rout := [=];				# output record
	    rout.type := pp.result;			# identification
	    rout.axes := uvbrick.axes();			# string vector
	    rout.fitaxis := pp.fitaxis;			# e.g. 'time'
	    # rout.cx2real := pp.cx2real;			# conversion....

	    rout.xref := xx[1];				# reference value
	    xx -:= rout.xref; 				# keep numbers small (!)
	    rout.xnorm := max(abs(xx));			# normalising value
	    if (rout.xnorm==0) rout.xnorm := 1;		# just in case
	    xx /:= rout.xnorm; 				# keep numbers small (!)
	    # to be used in apply(): xx := (xx-rout.xref)/rout.xnorm;

	    rout.ifitaxis := ind(rout.axes)[rout.axes==rout.fitaxis];
	    dimout := uvbrick.shape();			# shape of output array
	    dimout[rout.ifitaxis] := ncoeff;		# adjust axis length
	    rout.label := paste(rout.type,rout.fitaxis,dimout,rout.axes);
	    print dimout,rout;
	    rout.data := array(0,prod(dimout));		# output array (with coeff)
	    if (len(dimout)>1) rout.data::shape := dimout;	# adjust shape
	    if (complexdata) {
	    	rout.imagdata := array(0,prod(dimout));	# polcoeff of imaginary part
	    	if (len(dimout)>1) rout.imagdata::shape := dimout;
	    }
	} else {
	    print s := paste(hist,'not recognised:',result);
	    return F;
	}

	niter := 1;					# nr of iterations
	if (pp.clip_nsigma>0) niter := 2;		# clip first

	coeff := []; imagcoeff := F; cerrs := []; chisq := 0; sigma := 1;
    	while (private.index.next(index)) {
	    if (pp.fitfunc=='polynomial') {
	    	yy := uvbrick.getslice(index);		# get 1D array		
	    	ff := uvbrick.getslice(index, 'flag');	# its flags	
		ff |:= igflag;				# OR specified flags

		for (iter in [1:niter]) {
		    yy1 := yy[!ff];			# unflagged
		    nyy1 := len(yy1);			# nr unflagged
		    if (nyy1<(order+1)) {
		    	print s := paste('fitpoly: nyy1=',nyy1,'too small for fit!')
		    	# do what?
		    	next;
		    }
		    xx1 := xx[!ff];			# unflagged xx
		    ff1 := ff[!ff];			# all un-flagged

		    ok := private.fitter.fit(coeff, cerrs, chisq, 
					   xx1, real(yy1), sigma, pp.ndeg);
		    if (complexdata) {
		    	ok := private.fitter.fit(imagcoeff, cerrs, chisq, 
					   xx1, imag(yy1), sigma, pp.ndeg);
		    }

		    if (iter<niter) {			# use the first fit to clip
		    	ok := private.fitter.eval(yyeval, xx1, coeff);	# 
	    		rr := public.getclipflags (real(yy1)-yyeval, 
						   pp.clip_nsigma);	
	    		if (is_fail(rr)) break;			# problem...?
			ff1 := rr.ff;				# new flags
		    	if (complexdata) {
		    	    ok := private.fitter.eval(yyeval, xx1, imagcoeff);	# 
	    		    rr := public.getclipflags (imag(yy1)-yyeval, 
						       pp.clip_nsigma);	
			    ff1 |:= rr.ff;			# OR new flags
			}
			ff[!ff] := ff1;				# total flags
			uvbrick.setslice(index, ff, 'flag');	# replace
		    }
		}

		if (pp.result=='subtract' || pp.result=='replace') {
		    ok := private.fitter.eval(yyeval, xx, coeff);
		    if (complexdata) {
	    		ok := private.fitter.eval(yyimag, xx, imagcoeff);
	    	    	yyeval := complex(yyeval,yyimag);
		    }
		    if (pp.result=='subtract') {	# subtract from data
			uvbrick.setslice(index, yy-yyeval);
		    } else if (pp.result=='replace') {	# replace data with pol
			uvbrick.setslice(index, yyeval);
		    }
		} else if (pp.result=='polcoeff') {	# either/or...........?
	    	    rout.data[index] := coeff;		# store coefficients
		    if (complexdata) rout.imagdata[index] := imagcoeff;
		}
		if (pp.display) {
		    private.plotfit(xx1, yy1, ff1, coeff, imagcoeff, pgw=pgw);
		}
	    }
    	}
	uvbrick.addtohistory(hist);
	return rout;					# return record or T;
    }

# Helper function to plot the fit (see .fit()):

    private.plotfit := function(xx1, yy1, ff1, coeff, imagcoeff=F, ref pgw=F) {
	wider private;
	pgw.clear();
	complexdata := !is_boolean(imagcoeff);
	s := paste('fit:');
	nyy1 := len(yy1);
	yyeval := [];
	ok := private.fitter.eval(yyeval, xx1, coeff);	# 
	pgw.newitem('input', xx=xx1, yy=real(yy1), ff=ff1, 
			    color='blue');
	pgw.newitem('eval', xx=xx1, yy=real(yyeval), 
			    color='blue');
	ylabel := spaste('red=abs(residual)');
	if (complexdata) {
	    ok := private.fitter.eval(yyimag, xx1, imagcoeff);
	    pgw.newitem('iinput', xx=xx1, yy=imag(yy1), 
				color='green');
	    yyeval := complex(yyeval,yyimag);
	    pgw.newitem('ieval', xx=xx1, yy=imag(yyeval), 
				color='green');
	    ylabel := paste(ylabel,'(blue=real, green=imag)');
	}
	pgw.set_display_option('yzero',T);	# show x-axis
	absres := abs(yy1 - yyeval);			# abs(residual)
	pgw.newitem('eval', xx=xx1, yy=absres, color='red');
	rms1 := sum(abs(yy1)^2)/nyy1;			# input rms
	rms2 := sum(absres*absres)/nyy1;		# residual rms
	s := paste(s,'rms=',rms1,'->',rms2);
	pgw.message(s);		
	yunit := ' ';
	xunit := ' ';
	pgw.labels (title=title, ylabel=ylabel, xlabel=xlabel,
			    yunit=yunit, xunit=xunit);
	pgw.plot();
	return T;
    }



#------------------------------------------------------------------------
# Clip the data after differentiate the data along the given diffaxis:
# Works on complex and real data (?).

    public.clip := function (ref uvbrick, pp=[=], ref pgw=F) {
	wider private;
	
	private.jenmisc.checkfield(pp,'diffaxis',F,'clip');
	private.jenmisc.checkfield(pp,'cx2real','ampl','clip');
	private.jenmisc.checkfield(pp,'threshold',0,'clip');
	private.jenmisc.checkfield(pp,'derivn',0,'clip');
	private.jenmisc.checkfield(pp,'nsigma',2,'clip');
	private.jenmisc.checkfield(pp,'display',T,'clip');
	hist := paste('clip', pp.diffaxis, pp.cx2real);

 	# xx := uvbrick.getcoord_old(pp.diffaxis);	# xx coordinate-vector
 	xx := uvbrick.getcoord(pp.diffaxis);		# xx coordinate-vector
	if (is_fail(xx)) fail('no xx-vector found');
	
	private.index := uvbrick.initindex(pp.diffaxis[1], 'data', 
					  origin='clip', autofinish=T, forwardonly=F);
	if (is_fail(private.index)) fail(private.index);

	if (pp.threshold>0) {				# abs threshold given
	    title := 'flag(clip): data: threshold and flags';
	    xlabel := pp.diffaxis; 
	    ylabel := spaste(pp.cx2real);
	} else if (pp.nsigma>0) {			# use nsigma
	    title := 'flag(clip): diff(data): thresholds and flags';
	    xlabel := pp.diffaxis; 
	    ylabel := spaste('diff',pp.derivn,'(',pp.cx2real,')');
	} else {
	    print 'clip: threshold and nsigma both zero!';
	    return F;
	}
	
	pgw.index(private.index);		# progress control
	pgw.set_display_option ('yzero',T);	# include x-axis 
	
	#----------------------------------------------------------------
	# Not used at present (used earlier with .uvp)
	private.menu_ctrl := private.index.user_button('ctrl',menu=T);
	private.index.user_button('nsigma=1', private.nsigma1, private.menu_ctrl);
	private.index.user_button('nsigma=2', private.nsigma2, private.menu_ctrl);
	private.index.user_button('nsigma=3', private.nsigma3, private.menu_ctrl);
 	private.nsigma1 := function(){return private.nsigma(1)};
	private.nsigma2 := function(){return private.nsigma(2)};
	private.nsigma3 := function(){return private.nsigma(3)};
	private.nsigma := function(nsigma) {
	    wider pp;					# necessary!
	    old := pp.nsigma;
	    pp.nsigma := nsigma;
	    return paste('nsigma:',old,'->',pp.nsigma);
	}
	#----------------------------------------------------------------

	nuvdata := uvbrick.ndata();
	newflags := 0;
	nflags := uvbrick.nflag();
	p := as_integer(100*nflags/nuvdata);
	print s1 := spaste(' new=',newflags,' total=',nflags,' (',p,'%)');
	
    	while (private.index.next(index)) {
	    yy := uvbrick.getslice(index);		# get 1D vector	
	    if ((nyy:=len(yy))<3) next;			# too few data-points
	    ff := uvbrick.getslice(index, 'flag');	# its flags	
	    nff1 := len(ff[ff]);
	    yy := private.jenmath.cx2real(yy,pp.cx2real);# convert to real

	    if (pp.threshold>0) {
	    	rr := public.getclipflags (yy, threshold=pp.threshold);
	    	if (is_fail(rr)) next;			# problem
	    } else if (pp.derivn>0) {
		for (i in [1:pp.derivn]) {
	    	    yy := private.jenmath.diff1D (yy,xx,ff);
		}
	    	rr := public.getclipflags (yy, nsigma=pp.nsigma);
	    	if (is_fail(rr)) next;			# problem
	    }

	    pgw.newitem('before', xx=xx, yy=yy, ff=ff, 
				style='dashed', color='red');	
	    pgw.marker(y=rr.level, label='threshold');
	    ff |:= rr.ff;				# OR the new flags
	    uvbrick.setslice(index, ff, 'flag');	# update flags
	    
	    nff := len(ff[ff]);				# nr of flags
	    newflags +:= nff-nff1;			# count 
	    nflags +:= nff;				# count 

	    pgw.newitem('after', xx=xx, yy=yy, ff=ff, color='blue');	
    	    pgw.plot();				# plot the result
	    
	    p := as_integer(100*nflags/nuvdata);
	    s1 := spaste(newflags,'  total=',nflags,' (',p,'%)');
	    s := spaste('+',nff-nff1,' flags:  new=',s1);
	    pgw.message(s);
	    
    	}
	uvbrick.addtohistory(hist);
	uvbrick.addtohistory(paste('new flags:',s1));
	return T;
    }
    
# Helper function to get clip-flags (also used by fit() etc):
    
    public.getclipflags := function (ref yy, nsigma=F, threshold=0) {
	rr := [=];
	rr.nyy := len(yy);
	if (rr.nyy<=0) {
	    print s := '*** getclipflags: nyy=0!';
	    fail(s);
	}
	if (threshold>0) {				# takes precedence
	    rr.threshold := threshold;
	    rr.ff := [abs(yy)>rr.threshold];
    	    rr.level := rr.threshold; 
	} else {
	    rr.mean := sum(yy)/rr.nyy;
	    rr.ms := sum(yy*yy)/rr.nyy;
	    rr.rms := sqrt(max(0,rr.ms-rr.mean*rr.mean));
	    rr.threshold := nsigma*rr.rms;
	    rr.ff := [abs(yy-rr.mean)>rr.threshold];
    	    rr.level := rr.mean + rr.threshold*[-1,1]; 
	}
	return rr;					# return record
    }

#=========================================================================
# Derive suggestions for WSRT attenuator settings from antbrick
# which contains the column NFRA_TPOFF from the MS SYSCAL sub_table.
# (NB: This very WSRT-specific routine really does not belong in this 
#      collection of rather generic uv/ant brick routines:

    public.TOPOR := function (ref antbrick, pp=[=], trace=F) {
	wider private;
	if (trace) print '\n \n uvbrick_fcs.TOPOR(',pp,'):';

	private.jenmisc.checkfield(pp,'TPref',F,'TOPOR');

	data := antbrick.get('data');
	nant := antbrick.length('ant');
	npol := antbrick.length('pol');
	if (trace) print 'data:',type_name(data),shape(data),':',npol,nant;
	
	rr := private.jenmath.statistarr(data);		# data-statistics
	if (trace) print 'data-statistics:';
	for (fname in field_names(rr)) {
	    if (trace) print '-',fname,'=',rr[fname];
	}

	# This routine returns a string with \n:
	ss := '\n \n TOPOR: suggestions for attenuator settings';

	# The Total Power reference value TPref: 
	if (is_boolean(pp.TPref)) {                 # not specified
	    pp.TPref := rr.mean;                    # derive from data
	    ss := paste(ss,'\n TPref=',pp.TPref,'(mean of measured TPOFF)'); 
	} else {
	    ss := paste(ss,'\n TPref=',pp.TPref,'(specified by the user)'); 
	}         
	if (pp.TPref<=0) {                         # problem
	    ss := spaste(ss,'\n NB: invalid TPref=',pp.TPref,', set to 1.0');
	    pp.TPref := 1;                         # safety
	}

	q := 10.0/log(10.0);			   # for taking 10log()
	for (iant in [1:nant]) {
	    ss := paste(ss,'\n');
	    for (ipol in [1:npol]) {
		rcp := antbrick.getrcp_ant(iant,ipol);
		TP := data[ipol,1,iant,1];
		s1 := sprintf(' %5s:',rcp.rcpname);
		s1 := paste(s1,sprintf(' TP=%7.3f',TP));  
		ratio := TP/pp.TPref;                      
		if (ratio>0) {
		    dB := q*log(ratio);            # 10log(ratio)
		    s1 := paste(s1,sprintf(' %7.2f dB',dB));  
		    ddB := 3*floor(0.5+(dB/3));    # integer value
		    s1 := paste(s1,sprintf(' :  change by:%4i dB',ddB));  
		} else {
		    s1 := paste(s1,'   invalid ratio=',ratio);
		}
		s1 := spaste(s1,' ',rcp.rcpname);
		ss := paste(ss,'\n',s1);
		if (trace) print s1;
	    }
	}
	ss := paste(ss,'\n ...\n');
	return ss;                                 # return string
    }

    

#=======================================================================
# Finished. Initialise and return the public interface:

    private.init();			# initialise
    return ref public;				# ref?

};						# closing bracket of uvbrick
#=======================================================================

# uvb := test_uvbrick_fcs();			# run test-routine

#===========================================================
# Remarks and things to do:
#================================================================


