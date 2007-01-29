# jenmath.g: some useful mathematical functions:

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
# $Id: jenmath.g,v 19.0 2003/07/16 03:38:32 aips2adm Exp $

#---------------------------------------------------------

pragma include once
# print 'include jenmath.g  w31aug99';

include 'jenmisc.g';              # temporary?		

# include 'profiler.g';		
# include 'textformatting.g';		


#==========================================================================
#==========================================================================
#==========================================================================

jenmath := function () {
    private := [=];
    public := [=];
    
# Initialise the object (called at the end of this constructor):

    private.init := function (name='uvbrick') {
	wider private;
	const private.pi := acos(-1);		# use atan()....?
	const private.pi2 := 2*private.pi;	
	const private.rad2deg := 180/private.pi;
	const private.deg2rad := 1/private.rad2deg;
	private.jenmisc := jenmisc();
	# include 'tracelogger.g';
	# private.trace := tracelogger(private.name);
	# private.tf := textformatting();		# text-formatting functions
	return T;
    }

    public.interp1D := function() {
	private.check_interp1D();
	return ref private.interp1D;
    }
    public.lsfitter := function() {
	private.check_lsfitter();
	return ref private.lsfitter;
    }
    public.polyfitter := function() {
	private.check_polyfitter();
	return ref private.polyfitter;
    }
    public.fftserver := function() {
	private.check_fftserver();
	return ref private.fftserver;
    }

    private.check_lsfitter := function() {
	wider private;
	if (!has_field(private,'lsfitter')) private.lsfitter := F;
	if (is_boolean(private.lsfitter)) {		# not yet defined
	    include 'lsfit.g';				# only when needed
	    private.lsfitter := lsfit_functions();      # lsfit functions
	    print 'lsfitter fields:',field_names(private.lsfitter);
	}
	return T;
    }

    private.check_polyfitter := function() {
	wider private;
	if (!has_field(private,'polyfitter')) private.polyfitter := F;
	if (is_boolean(private.polyfitter)) {		# not yet defined
	    include 'mathematics.g';			# new
	    private.polyfitter := polyfitter();		# fitter object
	    print 'polyfitter fields:',field_names(private.polyfitter);
	}
	return T;
    }

    private.check_fftserver := function() {
	wider private;
	if (!has_field(private,'fftserver')) private.fftserver := F;
	if (is_boolean(private.fftserver)) {		# not yet defined
	    include 'mathematics.g';			# new
	    private.fftserver := fftserver();		# fft object
	    print 'fftserver fields:',field_names(private.fftserver);
	}
	return T;
    }

    private.check_interp1D := function() {
	wider private;
	if (!has_field(private,'interp1D')) private.interp1D := F;
	if (is_boolean(private.interp1D)) {		# not yet defined
	    include "interpolate1d.g"; 
	    private.interp1D := interpolate1d();        # interpolator object
	    print 'interp1D fields:',field_names(private.interp1D);
	    r := private.interp1D.initialize([1:10], [1:10]);
	    if (!r) {
		print 'check_interp1D: initialisation failed....';
		return F;
	    } 
	}
	return T;
    }



#==========================================================================
# Public interface:
#==========================================================================


    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('jenmath event:',$name,$value);
	# print s;
    }
    whenever public.agent->message do {
	print 'jenmath message-event:',$value;
    }
    public.private := function(copy=F) {	# access to private part
	if (copy) return private;		# return a copy
	return ref private;			# return a reference
    }


#------------------------------------------------------------------------
# Helper function to check a given record (rr) for the presence of a
# named field, and to create it with a default value if not found.

    public.checkfield := function (ref rr=[=], fname=F, dflt=F, origin=F) {
	print 'jenmath.checkfield: obsolete, use jenmisc!',origin;
	return private.jenmisc.checkfield(rr, fname, dflt, origin);
	#=============================================================

	s := paste('** checkfield (',origin,'):'); 
	if (!is_record(rr)) {
	    print '** checkfield: rr is not a record!',fname,origin;
	    return F;
	} else if (has_field(rr,fname)) {
	    s := paste(s,'has field:',fname,':');
	    s := paste(s,type_name(rr[fname]),shape(rr[fname]));
	    if (is_record(rr[fname])) {
		s := paste(s,'\n   fields:',field_names(rr[fname]));
	    } else if (len(rr[fname])<5) {
		s := paste(s,'=',rr[fname]);
	    }
	    print s;
	} else {
	    rr[fname] := dflt;		# create field with given value
	    s := paste(s,'created field:',fname,'=',rr[fname]);
	    s := paste(s,type_name(rr[fname]),shape(rr[fname]));
	    print s;
	}
	return T; 
    }

#-------------------------------------------------------------------------------
# Sort in various ways:

    public.sort := function (xx, desc=F) {
	print 'jenmath.sort: obsolete, use jenmisc!',type_name(xx);
	return private.jenmisc.sort(xx, desc);
	#=============================================================

	if (desc) {                         # descending order
	    return -sort(-xx);
	} else {                            # ascending order
	    return sort(xx);
	}
    }


# Helper function that counts the bytes in a record recursively:

    public.nbytes := function (ref v) {
	print 'jenmath.nbytes: obsolete, use jenmisc!',type_name(v);
	return private.jenmisc.nbytes(v);
	#=============================================================

	nbytes := 0;
	if (is_record(v)) {
	    nbytes +:= 16;				# record-overhead (?)
	    for (f in v) nbytes +:= public.nbytes(f);	# recursive
	} else if (is_string(v)) {
	    for (s in v) nbytes +:= len(split(s,''));	# count the chars
	} else if (any(type_name(v)=="dcomplex")) {
	    nbytes +:= 16 * len(v);
	} else if (any(type_name(v)=="complex double")) {
	    nbytes +:= 8 * len(v);
	} else {					# integer, boolean, ....?
	    nbytes +:= 4 * len(v);			# ....?
	}
	return nbytes;
    }


#=========================================================================
#=========================================================================

# Fit a polynomial:

    public.fit_poly := function (ref yy=F, ref xx=F, ndeg=2,
				 ref ff=F, ref ww=F, 
				 eval=F, xscale=F,
				 name=F, trace=F) {

	# If complex, fit separate polynomials to the real and imaginary
	# parts of yy, using the routine recursively. Return complex.
	if (is_complex(yy) || is_dcomplex(yy)) {
	    rr := public.fit_poly(yy=real(yy), xx=xx, ndeg=ndeg,
				   ff=ff, ww=ww, 
				   name=spaste(name,'_real_part'),
				   eval=eval, trace=trace);
	    rri := public.fit_poly(yy=imag(yy), xx=xx, ndeg=ndeg,
				   ff=ff, ww=ww, 
				   name=spaste(name,'_imag_part'),
				   eval=eval, trace=trace);
	    rr.name := name;
	    ss := "yy yyeval yydiff coeff cerrs chisq";
	    for (fname in ss) {
		rr[fname] := complex(rr[fname],rri[fname]);
	    }
	    return rr;                                  # combined
	}

	ndeg := max(0,ndeg);
	ndeg := min(10,ndeg);
	private.check_polyfitter();                     # private.polyfitter
	rr := [type='jnm.fitpoly()',name=name, ndeg=ndeg, eval=eval, message=' '];
	if (trace) print rr,'nyy=',len(yy),'nxx=',len(xx);
	nyy := len(yy);
	rr.yy := yy;
	rr.xx := xx;
	rr.yydiff := rr.yyeval := [];
	if (is_boolean(xx) || len(xx)!=nyy) rr.xx := ind(yy);
	if (is_boolean(ff) && len(ff)==nyy) {
	    rr.xx := rr.xx[!ff];                        # ignore [ff=T]
	    rr.yy := rr.yy[!ff];
	}
	# NB: allow weights(ww)? (not supported by fitter);
	# NB: condition xx.....
	rr.status := [fitter=F, eval=F];
	rr.coeff := rr.cerrs := rr.chisq := [];
	rr.sigma := 1.0;                                # ....?
	rr.nyy := len(rr.yy);                           # AFTER flagging
	if (rr.nyy<=ndeg) {
	    rr.message := paste('not enough data-points:',rr.nyy);
	    if (trace) print rr.type,rr.name,':',rr.message;
	    return rr;      
	}
	rr.xmult := 1;
	rr.xsub := 0;
	rr.xadd := 0;
	xscale := F;                                    # disable        
	if (xscale) {                                   # scale xx
	    xrange := range(rr.xx);
	    xspan := abs(xrange[2]-xrange[1]);
	    rr.xmult := 1.0/xspan;
	    rr.xsub := xrange[1];
	    rr.xadd := 0.5;
	    rr.xx := rr.xadd + (rr.xx-rr.xsub)*rr.xmult;
	    rr.message := spaste('xx has been scaled!');
	    if (trace) print rr.message,'xrange=',xrange,'->',range(rr.xx);
	}
	r := private.polyfitter.fit(rr.coeff, rr.cerrs, rr.chisq, 
				    rr.xx, rr.yy, rr.sigma, rr.ndeg);
	rr.status.fitter := r;
	if (is_fail(r)) print r;
	if (trace) print 'coeff=',rr.coeff;

	if (eval) {                                     # evaluate
	    xxeval := rr.xadd + (xx-rr.xsub)*rr.xmult;
	    r := private.polyfitter.eval(rr.yyeval, xxeval, rr.coeff);
	    rr.status.eval := r;
	    if (is_fail(r)) {
		print r;
	    } else {
		rr.yydiff := yy - rr.yyeval;            # difference
		pp := public.statistarr(rr.yydiff);     # statistics
		rr.rmsdiff := pp.rms;
	    } 
	}
	return rr;                                      # return record
    }

# General helper function: data-conversion from real to real:
# If copy=T, the return value is the converted input (vv), and the input itself
# is not affected. If copy=F, the input (vv) is converted in-place (saves space).

    public.real2real := function (ref vv, real2real='none', copy=T, mess=T) {
	if (real2real=='none') {				# no conversion
	    if (copy) return val vv;
	} else if (real2real=='abs') {
	    if (copy) return abs(vv);
	    val vv := abs(vv);				# modify the input
	} else if (real2real=='log' || real2real=='ln' || real2real=='log2') {
	    q := 1.0;					# assume 10log
 	    if (real2real=='ln') q := log(exp(1));	# log(e), for elog 
 	    if (real2real=='log2') q := log(2);	        # log(2), for 2log 
	    ww := vv;	  			        # ....
	    if (max(ww)==0.0) return ww;		# return zeroes...?
	    sv := [ww<=0.0];				# find ampl=0
	    ww[sv] := min(ww[!sv]);			# now safe to take log
	    if (copy) return log(ww)/q;
	    val vv := log(ww)/q;			# modify the input
	} else if (mess) {				# message
	    print 'real2real: not recognised:',real2real;
	    # if (copy) return val vv;			# default
	    return F;					# not recognised
	} else {
	    return F;					# not recognised
	}
	return T;					# OK if copy=F
    }


# General helper function: data-conversion from complex to real:
# If copy=T, the return value is the converted input (vv), and the input itself
# is not affected. If copy=F, the input (vv) is converted in-place (saves space).
# NB: Phases may be optionally unwrapped (1D only!).

    public.cx2real := function (ref vv, cx2real='ampl', unwrap=F, 
				copy=T, mess=T) {
	if (cx2real=='none') {				# no conversion
	    if (copy) return val vv;
	} else if (cx2real=='complex') {		# assure complex
	    if (copy) return as_complex(vv);
	    val vv := as_complex(vv);
	} else if (cx2real=='abs' || cx2real=='ampl') {
	    if (copy) return abs(vv);
	    val vv := abs(vv);				# modify the input
	} else if (cx2real=='logampl' || cx2real=='lnampl' || cx2real=='log2ampl') {
	    q := 1.0;					# assume 10log
 	    if (cx2real=='lnampl') q := log(exp(1));	# log(e), for elog 
 	    if (cx2real=='log2ampl') q := log(2);	# log(2), for 2log 
	    ww := abs(vv);				# ampl
	    if (max(ww)==0.0) return ww;		# return zeroes...?
	    sv := [ww<=0.0];				# find ampl=0
	    ww[sv] := min(ww[!sv]);			# now safe to take log
	    if (copy) return log(ww)/q;
	    val vv := log(ww)/q;			# modify the input
	} else if (cx2real=='phase' || cx2real=='phase_rad' || 
		   cx2real=='phase_deg') {
	    if (unwrap) {
		ww := public.unwrap(vv);                # rad, 
	    } else {
		sv := [abs(vv)==0.0];			# find ampl=0
		ww := arg(vv);				# -> rad
		ww[sv] := 0.0;				# NaN -> 0
	    }
	    if (cx2real=='phase_deg') ww *:= (180.0/acos(-1));# -> degr
	    if (copy) return ww;
	    val vv := ww;				# modify the input
	} else if (cx2real=='real' || cx2real=='real_part') {
	    if (copy) return real(vv);
	    val vv := real(vv);				# modify the input
	} else if (cx2real=='imag' || cx2real=='imag_part') {
	    if (copy) return imag(vv);	
	    val vv := imag(vv);				# modify the input
	} else if (mess) {				# message
	    print 'cx2real: not recognised:',cx2real;
	    # if (copy) return val vv;			# default
	    return F;					# not recognised
	} else {
	    return F;					# not recognised
	}
	return T;					# OK if copy=F
    }

# Calculate the phase gradient (rad) of the given complex vector:
# The xx-vector will often be the frequency-vector:


    public.phase_gradient := function (cc, xx=F) {
	if (is_boolean(xx)) xx := ind(cc);	# default: 1,2,3,...,ncc
	pp := public.unwrap (cc);		# unwrapped phase
	dp := public.diff1D (pp, xx);		# differentiate
	grad := sum(dp)/max(1,len(dp));		# gradient
	return grad;
    } 


# Calculate 'unwrapped' phases (rad) from complex input vector,
# by first dividing the preceding value form each value, 
# and 'integrating the phases':

    public.unwrap := function (cc, unit='rad') {
	ncc := len(cc);
	pp := [];
	for (i1 in [1:ncc]) {
	    pp[i1] := 0;
	    if (abs(cc[i1])>0) {		# ampl>0: phase defined
		pp[i1] := arg(cc[i1]);		# -> rad
		break;				# escape
	    }
	}
	if (i1>=ncc) return pp;			# empty vector []

	for (i2 in [(i1+1):ncc]) {
	    if (abs(cc[i2])==0) {		# phase undefined: ignore
		pp[i2] := pp[i1];		# same phase (?)
		# pp[i2] := 0;			# better?
		next;
	    } else {
		pp[i2] := pp[i1] + arg(cc[i2]/cc[i1]);	# -> rad and 'integrate'
		i1 := i2;				# new reference
	    } 
	}
	if (unit=='deg' || unit=='degr' || unit=='phase_deg') {
	    pp *:= (180.0/acos(-1));			# -> degr
	}
	return pp;					# phase-vector (rad)
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


#---------------------------------------------------------------------------
# Calculate the statistics of the input vector/array:

    public.statistarr := function (vv, name=F, diff=F, range_only=F) {
	r := [=];
	r.name := name;
	r.length := len(vv);
	r.shape := shape(vv);
	r.type := type_name(vv);
	r.iscomplex := (is_complex(vv) || is_dcomplex(vv)); 
	ss := "first last range min max mean ms rms";
	ss := [ss,"dmean dms drms ntrue nfalse"];
	for (fname in ss) r[fname] := F;
	if (r.length<=0) return r;			# empty vector

	n := max(1,r.length);				# safety
	r.first := vv[1];				# first value
	r.last := vv[n];				# last value
	if (is_boolean(vv)) {
	    r.ntrue := len(vv[vv]);			# nr of T values
	    r.nfalse := r.length - r.ntrue;		# nr of F values

	} else if (is_numeric(vv)) {
	    r.range := range(vv);
	    r.min := r.range[1]; 
	    r.max := r.range[2];
	    if (range_only) return r;			# escape
	    r.mean := sum(vv)/n;
	    if (r.iscomplex) {
		r.ms := sum(vv*vv)/n;			# separate real/imag??
		r.rms := sqrt(max(0,(r.ms-r.mean*r.mean)));	# ??
	    } else {
		r.ms := sum(vv*vv)/n;
		r.rms := sqrt(max(0,(r.ms-r.mean*r.mean)));
	    }
	    if (diff) {
		dv := [0,vv]-[vv,0];			# difference
		dv := dv[2:(len(dv)-1)];		# remove ends
		r.dmean := sum(dv)/n;
		if (r.iscomplex) {
		    r.dms := sum(dv*dv)/n;		# separate real/imag??
		    r.drms := sqrt(max(0,(r.dms-r.dmean*r.dmean))); # ??
		} else {
		    r.dms := sum(dv*dv)/n;
		    r.drms := sqrt(max(0,(r.dms-r.dmean*r.dmean)));
		}
	    }
	} else {					
	    # type not recognised....?
	}
	return r;					# record
    }

#-------------------------------------------------------------------------------
# Accumulate individual (weighted) statistics for points of input vectors vv:
# Provide a holding record rr for this.
# If calc=T, calculate the statistics, and store in same record

    public.statacc := function (ref rr=F, ref vv=F, ff=F, ww=1, 
				name='noname', init=F, calc=F, trace=F) {
	# Some checks:
	if (!is_record(rr)) {
	    init := T;
	} else if (!has_field(rr,'type')) {
	    init := T;
	} else if (rr.type != 'statacc') {
	    init := T;
	}

	# Initialise the accumulation record (if required);
	if (init) {
	    val rr := [=];
	    rr.type := 'statacc';
	    rr.name := name;
	    rr.nvv := F;
	    rr.sum := F; 
	    rr.ssum := F;
	    rr.wacc := F;
	    rr.nacc := 0;
	    rr.ncalc := 0;
	    rr.min := F;
	    rr.max := F;
	    rr.mean := F;
	    rr.ms := F;
	    rr.rms := F;
	    if (trace) print 'statacc(init): rr=',rr;
	}

	# Accumulate data (if valid vv provided):
	nvv := len(vv);                                 # data
	if (nvv<=0) {
	    # empty data vector....? 
	} else if (is_boolean(vv)) {
	    # ignore 
	} else if (is_numeric(vv)) {
	    if (trace) print 'statacc(acc): nvv=',nvv;
	    nww := len(ww);                             # weights (if any)
	    if (nww==1) {
		ww := rep(ww,nvv);
		nww := len(ww);                         # weights (if any)
	    }
	    nff := len(ff);                             # flags (if any)
	    if (nff==nvv) ww[ff] := 0;                  # ignore flagged (..?)
	    if (trace) print 'statacc(acc): ww=',ww;

	    if (rr.nacc==0) {                           # first time
		rr.nacc := 1;
		rr.min := vv;
		rr.max := vv;
		rr.nvv := nvv;                          # store length
		rr.sum := vv*ww;
		rr.ssum := vv*vv*ww;
		rr.wacc := ww;
	    } else if (nww!=rr.nvv) {                   # wrong length
		s := paste(rr.nacc+1,'statacc: ww length mismatch:',nww,rr.nvv);
		print s;
	    } else if (nvv!=rr.nvv) {                   # same length: OK
		s := paste(rr.nacc+1,'statacc: vv length mismatch:',nvv,rr.nvv);
		print s;
	    } else {                                    # OK: accumulate
		rr.nacc +:= 1;
		sv := [vv<rr.min];                      # selection vector
		rr.min[sv] := vv[sv];
		sv := [vv>rr.max];                      # selection vector
		rr.max[sv] := vv[sv];
		rr.sum +:= vv*ww;
		rr.ssum +:= vv*vv*ww;
		rr.wacc +:= ww;
	    }
	}

	# Calculate (intermediate) result(s), if required and necessary:
	if (calc && (rr.nacc>rr.ncalc)) {
	    rr.ncalc := rr.nacc;                        # current nacc
	    ww := rr.wacc;                              # accumulated weights
	    ww[ww==0] := 1;                             # safety
	    rr.mean := rr.sum/ww;                       # mean
	    rr.ms := rr.ssum/ww;                        # mean squares
	    msms := rr.ms - rr.mean*rr.mean;            # mean subtracted
	    msms[msms<0] := 0;                          # safety
	    rr.rms := sqrt(msms);                       # rms (around mean)
	}
	return T;
    }

#-------------------------------------------------------------------------------
# Differentiate a 1D data-vector:
# NB: We also need one that takes the difference of the difference.
#     This routine already has the right structure for that because it.
#     use the TWO points on each side!

    public.diff1D := function (yy, xx=F) {
	n := len(yy);
	if (n <= 0) {                                   # empty
	    return [];
	} else if (n < 3) {			        # too few data points
	    return yy*0;
	} else if (is_complex(yy) || is_dcomplex(yy)) {
	    yyr := public.diff1D(real(yy),xx);          # real part
	    yyi := public.diff1D(imag(yy),xx);          # imag part
	    return complex(yyr,yyi);
	}

	xx := public.check_xx (xx, yy, trace=trace);

	yy0 := yy[1] - (yy[2]-yy[1]);			# extrapolate
	yyn1 := yy[n] + (yy[n]-yy[n-1]);		# extrapolate

	xx0 := xx[1] - (xx[2]-xx[1]);			# extrapolate
	xxn1 := xx[n] + (xx[n]-xx[n-1]);		# extrapolate

	dy := [yy,yyn1] - [yy0,yy];			# n+1 y-differences
	dx := [xx,xxn1] - [xx0,xx];			# n+1 x-differences
	dxy := dy/dx;					# divide (n+1 values)

	dxy0 := dxy[1] - (dxy[2]-dxy[1]);		# extrapolate
	dxyn2 := dxy[n+1] + (dxy[n+1]-dxy[n]);		# extrapolate

	ss := ([dxy0,dxy] + [dxy,dxyn2])/2;		# average over 2 

	# print len(yy),'yy=',yy;
	# print len(xx),'xx=',xx;
	# print len(dy),'dy=',dy;
	# print len(dx),'dx=',dx;
	# print len(dxy),'dxy=',dxy;
	# print len(ss),'ss=',ss;

	return ss[2:(n+1)];				# return n values
    }

#-------------------------------------------------------------------------------
# Autocorrelate a 1D data-vector:

    public.autocorr := function (yy, xx=F, trace=F) {
	if (trace) print '\n jnmath.autocorr:';
	private.check_fftserver();
	if (trace) {
	    print 'jnmath.autocorr input:',type_name(yy),len(yy);
	    print 'yy=',yy;
	}

	if (is_complex(yy) || is_dcomplex(yy)) {       #.....?
	    print 'jnmath.autocorr: yy should be real...!';
	    yy := abs(yy);                  # take amplitudes.....?
	}
	yy := private.fftserver.autocorr(yy); 
	if (is_fail(yy)) print yy;

	# Deal with the result:
	if (trace) {
	    print 'jnmath.autocorr -> ',type_name(yy),len(yy);
	    print 'yy=',yy;
	}

	# Return a RECORD with the new yy, and xx-shifts:
	xx := public.check_xx (xx, yy, trace=trace);
	xxshift := public.xxshift(xx, trace=trace);
	return [yy=yy, xx=xxshift];          # return record!
    }

#-------------------------------------------------------------------------------
# Crosscorrelate two 1D data-vectors:

    public.crosscorr := function (yy1, yy2, xx=F, trace=F) {
	if (trace) print '\n jnmath.autocorr:';
	private.check_fftserver();
	if (trace) {
	    print 'jnmath.crosscorr input yy1:',type_name(yy1),len(yy1);
	    print 'jnmath.crosscorr input yy2:',type_name(yy2),len(yy2);
	}

	# Do some checks:
	if (is_complex(yy1) || is_dcomplex(yy1)) { 
	    print 'jnmath.crosscorr: yy1 should be real...!';
	    yy1 := abs(yy1);               # take amplitudes.....?
	}
	if (is_complex(yy2) || is_dcomplex(yy2)) { 
	    print 'jnmath.crosscorr: yy2 should be real...!';
	    yy2 := abs(yy2);               # take amplitudes.....?
	} 
	yy := private.fftserver.crosscorr(yy1,yy2); 
	if (is_fail(yy)) print yy;

	# Deal with the result:
	if (trace) {
	    print 'jnmath.crosscorr -> ',type_name(yy),len(yy);
	}

	# Return a RECORD with the new yy, and xx-shifts:
	xx := public.check_xx (xx, yy1, trace=trace);
	xxshift := public.xxshift(xx, trace=trace);
	return [yy=yy, xx=xxshift];          # return record!
    }

#-------------------------------------------------------------------------------
# Convolve two 1D data-vectors:

    public.convolve := function (yy1, yy2, xx=F, trace=F) {
	if (trace) print '\n jnmath.convolve:';
	private.check_fftserver();
	if (trace) {
	    print 'jnmath.convolve input yy1:',type_name(yy1),len(yy1);
	    print 'jnmath.convolve input yy2:',type_name(yy2),len(yy2);
	}

	# Do some checks:
	if (is_complex(yy1) || is_dcomplex(yy1)) { 
	    print 'jnmath.convolve: yy1 should be real...!';
	    yy1 := abs(yy1);               # take amplitudes.....?
	}
	if (is_complex(yy2) || is_dcomplex(yy2)) { 
	    print 'jnmath.convolve: yy2 should be real...!';
	    yy2 := abs(yy2);               # take amplitudes.....?
	}
	nyy1 := len(yy1);
	nyy2 := len(yy2);
	if (nyy2>nyy1) {
	    print 'jnmath.convolve: nyy2 reduced to nyy1=',nyy1;
	    yy2 := yy2[1:nyy1];
	}

	yy := private.fftserver.convolve(yy1,yy2); 
	if (is_fail(yy)) print yy;

	# Deal with the result:
	if (trace) {
	    print 'jnmath.convolve -> ',type_name(yy),len(yy);
	}

	# Return a RECORD with the new yy, and xx:
	xx := public.check_xx (xx, n=nyy1, trace=trace);
	return [yy=yy, xx=xx];          # return record!
    }

#-------------------------------------------------------------------------------
# FFT a 1D data-vector:

    public.fft := function (yy, xx=F, dir=1, trace=F) {
	if (trace) print '\n jnmath.fft:';
	private.check_fftserver();
	if (trace) {
	    print 'jnmath.fft input:',type_name(yy),len(yy);
	    print 'real:',real(yy);
	    print 'imag:',imag(yy);
	}

	# NB: Note the difference in return-behaviour!
	if (is_complex(yy) || is_dcomplex(yy)) {
	    r := private.fftserver.complexfft(yy, dir=dir); 
	    if (is_fail(r)) print r;
	} else {
	    # NB: forward only....?
	    yy := private.fftserver.realtocomplexfft(yy); 
	    if (is_fail(yy)) print yy;
	}

	# Deal with the result:
	if (trace) {
	    print 'jnmath.fft -> ',type_name(yy),len(yy);
	    print 'real:',real(yy);
	    print 'imag:',imag(yy);
	}

	# Return a RECORD with the new yy, and 'inverted' xx:
	xx := public.check_xx (xx, yy, trace=trace);
	xxfft := public.xxfft(xx, trace=trace);
	return [yy=yy, xx=xxfft];          # return record!
    }

# Helper function to calculate the output xx for fft:

    public.xxfft := function (xx, trace=F) {
	n := len(xx);
	if (n<=0) return [];
	if (n==1) return [0];
	imid := as_integer((n+1)/2);       # mid-point
	ii := ind(xx) - imid;

	xrange := range(xx);
	xspan := xrange[2]-xrange[1];
	xincr := xspan/(n-1);              # increment
	if (xincr==0) xincr := 1;          # safety

	xxfft := ii/xincr;                 # fft 'frequencies'
	# xxfft *:= private.pi2;

	if (trace) {
	    print 'jnmath.xxfft:',type_name(xx),len(xx),xrange,xspan,xincr;
	    print 'xxfft=',xxfft;
	}
	return xxfft;
    }

# Helper function to calculate the output xx for auto/crosscorr:

    public.xxshift := function (xx, trace=F) {
	n := len(xx);
	if (n<=0) return [];
	if (n==1) return [0];
	imid := as_integer((n+1)/2);       # mid-point
	xmid := xx[imid];                  # the middle value
	xxshift := xx - xmid;              # just subtract it
	# NB: Check the regularity....?
	if (trace) {
	    print 'jnmath.xxshift:',type_name(xx),len(xx),imid,'xmid=',xmid;
	    print 'xxshift=',xxshift;
	}
	return xxshift;
    }

# Helper function to calculate the statistics of the separations between
# successive values of the given vector xx. Returns a RECORD: 

    public.stat_sep := function (xx) {
	rr := [mean=0, rms=0];
	n := len(xx);
	if (n<=1) return rr;
	# zero := 0*xx[1];                   # zero of correct type
	dxx := xx[2:n]-xx[1:(n-1)];         # differences
	rr.mean := sum(dxx)/n;
	rr.ms := sum(dxx*dxx)/n;
	rr.rms := sqrt(max(0,rr.ms-rr.mean*rr.mean));
	return rr;
    }



#-------------------------------------------------------------------------------
# Fit a cubic spline to the 1D data-vector:
# NB: This does not seem to be a 

    public.fit_cubic_spline := function (yy=F, xx=F, trace=F) {
	n := len(yy);
	if (n<=0) {                        # too few points
	    return yy;
	}
	xx := public.check_xx (xx, yy, trace=trace);
	return public.interpolate1D(newxx=xx, yy=yy, xx=xx, 
				    setmethod='spline', trace=trace);
    }

#-------------------------------------------------------------------------------
# Helper function to make sure that xx is numeric and has the same length
# as yy, or the number n:

    public.check_xx := function (xx=F, yy=F, n=F, trace=F) {
	nyy := nxx := len(xx);
	if (!is_boolean(n) && n>0) {         # length specified
	    nyy := n;
	} else if (!is_boolean(yy)) {        # yy-vector specified
	    nyy := len(yy);
	}
	if (trace) s := paste('jnmath.check_xx(',nyy,nxx,'):');
	if (nyy<=0) {
	    if (trace) print s,'not enough information: -> xx=[]';
	    return [];
	} else if (is_boolean(xx)) {         # no xx-vector supplied
	    if (trace) print s,'xx is boolean: -> xx=seq(',nyy,')';
	    return seq(nyy);
	} else if (nxx != nyy) {             # xx incorrevt length
	    if (trace) print s,'xx/yy length mismatch: -> xx=seq(',nyy,')';
	    return seq(nyy);
	} else {                             #  OK
	    return xx;
	}
    }

#-------------------------------------------------------------------------------
# Interpolate a 1D data-vector:

    public.interpolate1D := function (newxx=F, yy=F, xx=F, setmethod=F, trace=F) {
	if (trace) print '\n jnmath.interpolate1D:';
	private.check_interp1D();

	# Initialize the interpolation object, if required:
	n := len(yy);
	if (is_boolean(yy)) {                  # no yy given
	    # OK, assume initialisation
	} else if (n<=0) {                     # empty
	    return F;
	} else {                               # yy given: initialize
	    xx := public.check_xx (xx, yy, trace=trace);
	    r := private.interp1D.initialize(xx, yy);
	    if (!r) {
		print 'interp1D: initialisation failed....';
		return F;
	    } else if (trace) {
		print 'interp1D.initialize() ->',r;
		print len(xx),': xx=',xx;
		print len(yy),': yy=',yy;
	    }
	}

	# Set a new interpolation function, if given:
	if (is_string(setmethod)) {
	    if (!any(setmethod=="linear nearest cubic spline")) {
		print 'interp1D: setmethod not recognised:',setmethod;
		setmethod := 'linear';
	    }
	    r := private.interp1D.setmethod(setmethod);
	    if (trace) print 'interp1D.setmethod(',setmethod,') ->',r;
	}

	# Interpolate for newxx, if given:
	if (is_boolean(newxx)) {
	    return T;
	} else {
	    if (trace) print 'newxx=',newxx;
	    newyy := private.interp1D.interpolate(newxx);
	    if (trace) print 'newyy=',newyy;
	    return newyy;
	}
    }

#-------------------------------------------------------------------------------
# Integrate a 1D data-vector:

    public.integrate := function (yy, xx=F, trace=F) {
	n := len(yy);
	if (n <= 0) {                           # empty
	    return [];
	} else if (n < 2) {			# too few data points
	    return yy*0;
	} 

	xx := public.check_xx (xx, yy, trace=trace);

	dy := yy[2:n] - yy[1:(n-1)];
	dx := xx[2:n] - xx[1:(n-1)];

	ss := (yy[1:(n-1)]+0.5*dy)*dx;

	if (trace) {
	    print len(yy),'yy=',yy;
	    print len(xx),'xx=',xx;
	    print len(dy),'dy=',dy;
	    print len(dx),'dx=',dx;
	    print len(ss),'ss=',ss;
	    print 'sum=',sum(ss);
	}

	# return sum(ss);                         # one number

	ss := [0*ss[1],ss];           # prepend zero of right type
	for (i in [2:n]) {
	    ss[i] +:= ss[i-1];
	}

	if (trace) {
	    print len(ss),'ss=',ss;
	}

	return ss;                              # vector
    }

#-------------------------------------------------------------------------------
# Smooth a 1D data-vector, using a given smoothing function (ww):

    public.smooth := function (yy, ww=[1,1,1], trace=F) {
	if (trace) print 'jenmath.smooth(',ww,')';
	nyy := len(yy);
	if (nyy <= 0) {                        # empty
	    return yy;
	}
	if (len(ww)<=0) ww := 1.0;             # smoothing function
	nww := len(ww);
	iwwmid := 1+as_integer(nww/2);         # ww 'mid'-point
	nacc := nyy + nww - 1;
	if (trace) print 'ww=',ww,'iwwmid=',iwwmid,'->',nacc;

	vv := rep(0,nacc);
	wtot := rep(0,nacc);
	for (k in [1:nww]) {
	    i1 := k;
	    i2 := k+nyy-1;
	    if (trace) print i1,i2,ww[k];
	    vv[i1:i2] +:= yy*ww[k];
	    wtot[i1:i2] +:= ww[k];
	}
	if (trace) print 'wtot=',wtot;
	sv := [wtot==0];
	if (all(sv)) {
	    print 'jenmath.smooth(): wtot all zeroes! ww=',ww;
	    return yy;                         # no change
	} else if (any(sv)) {
	    nz := len(sv[sv]);                 # nr of zeroes
	    print 'jenmath.smooth():',nz,'wtot are zeroes! ww=',ww;
	    wtot[sv] := 1;                     # avoid zeroes
	} 
	vv /:= wtot;                           # normalise
	return vv[iwwmid:(iwwmid+nyy-1)];      # return nyy values
    }

#=======================================================================
# Finished. Initialise and return the public interface:

    private.init();				# initialise
    return ref public;				# ref?

};						# closing bracket of uvbrick
#=======================================================================


#=========================================================

test_jenmath := function ( ) {
    # include 'plotter.g';
    include 'pgplotter.g';
    private := [=];
    public := [=];
    global jnm, jnm_pgw;
    jnm := jenmath();
    jnm_pgw.done();                             # check existence?
    jnm_pgw := pgplotter();
    print '\n\n**********************************';
    print 'global symbols jnm and jnm_pgw created';
    print '**********************************\n\n';

    # Interpolation:
    if (F) {
	xx := [-10:10];
	yy := (xx/10)*3;
	vv := jnm.interpolate1D(yy=yy, xx=xx, trace=T);
	newxx := xx-0.5;
	vv := jnm.interpolate1D(newxx, trace=T);
	vv := jnm.interpolate1D(newxx, setmethod='linnar', trace=T);
	vv := jnm.interpolate1D(newxx, setmethod='cubic', trace=T);
	vv := jnm.interpolate1D(newxx, setmethod='spline', trace=T);
	vv := jnm.interpolate1D(newxx, setmethod='nearest', trace=T);
    }

    # Integration:
    if (F) {
	yy := [-10:10];
	vv := jnm.integrate(yy=yy, trace=T);
	print vv;
    }

    # Smoothing:
    if (F) {
	yy := [-10:10];
	ww := [-0.2,-0.3,1,-0.3,-0.2];
	# ww := [];
	print yy;
	vv := jnm.smooth(yy=yy, ww=ww, trace=T);
	dyy := vv-yy;
	dyy[abs(dyy)<0.00001] := 0;
	print dyy;
    }

    # Fit_cubic_spline:
    if (F) {
	xx := [-10:10];
	yyr := 5 + xx + (xx^2)/10;
	yyi := 1 - xx + (xx^2)/20;
	rms := 0.1;
	yyr +:= jnm.gaussnoise (len(yyr), rms=rms, mean=0);
	yyi +:= jnm.gaussnoise (len(yyi), rms=rms, mean=0);
	yyc := complex(yyr,yyi);
	yy := jnm.fit_cubic_spline(yyr, xx, trace=T);
	print yy;
    }

    # Fit_poly:
    if (F) {
	xx := [1000:1010];
	yyr := 5 + xx + (xx^2)/10;
	yyi := 1 - xx + (xx^2)/20;
	yyc := complex(yyr,yyi);
	ndeg := 10;
	for (xscale in [F,T]) {
	    print '\n\n ******************* xscale=',xscale,'ndeg=',ndeg;
	    rr := jnm.fit_poly(yy=yyr, xx=xx, ndeg=ndeg, 
			       eval=T, xscale=xscale, trace=T);
	    for (name in field_names(rr)) {
		if (any(name=="yy xx yyeval yydiff")) {
		    print name,': range=',range(rr[name]);
		} else {
		    print name,': value=',rr[name];
		}
	    }
	}
    }

    # Conversion cx2real:
    if (F) {
	pp := [-20:20]*pi/10;
	cc := complex(cos(pp),sin(pp));
	cc[3:5] := complex(0,0);
	yy := jnm.cx2real(cc,'phase');
	dp.clear();
	dp.plotxy(pp,yy);
	yy := jnm.unwrap(cc);
	dp.plotxy(pp,yy);
    }

    # FFT:
    if (F) {
	pp := [-20:20]*pi/10;               # symmetric
	pp +:= 1;                           # make asymmetric
	if (F) {
	    cc := complex(cos(pp),sin(pp));
	    rr := jnm.fft(cc, dir=1, trace=T);     # complexfft
	} else {
	    rr := jnm.fft(pp, trace=T);     # realtocomplexfft
	}
	print 'field_names(rr)=',field_names(rr);
	jnm_pgw.clear();
	jnm_pgw.plotxy(real(rr.xx),real(rr.yy));
    }

    # auto-correlation:
    if (F) {
	xx := [1:100]*0.1;
	n := len(xx);
	yy := jnm.gaussnoise (n, rms=1.0, mean=0);
	rr := jnm.autocorr(yy, xx=xx, trace=T); 
	print 'field_names(rr)=',field_names(rr);
	jnm_pgw.clear();
	jnm_pgw.plotxy(rr.xx,rr.yy);
    }

    # cross-correlation:
    if (F) {
	xx := [1:100]*0.1;
	n := len(xx);
	yy1 := jnm.gaussnoise (n, rms=1.0, mean=0);
	shift := 10;
	yy2 := rep(0.0,n);
	yy2[(shift+1):n] := yy1[1:(n-shift)];
	yy2[1:(shift+1)] := yy1[(n-shift):n];
	yy2 := [yy2,0.0];               # different length.....
	rr := jnm.crosscorr(yy1, yy2, xx=xx, trace=T); 
	print 'field_names(rr)=',field_names(rr);
	jnm_pgw.clear();
	jnm_pgw.plotxy(rr.xx,rr.yy);
    }

    # convolution:
    if (T) {
	xx := [1:100]*0.1;
	n := len(xx);
	yy1 := jnm.gaussnoise (n, rms=1.0, mean=0);
	shift := 10;
	yy2 := rep(0.0,n);
	yy2[(shift+1):n] := yy1[1:(n-shift)];
	yy2[1:(shift+1)] := yy1[(n-shift):n];
	yy2 := [yy2,0.0];               # longer than yy1
	# yy2 := yy2[1:(n-1)];            # shorter than yy1
	rr := jnm.convolve(yy1, yy2, xx=xx, trace=T); 
	print 'field_names(rr)=',field_names(rr);
	jnm_pgw.clear();
	jnm_pgw.plotxy(rr.xx,rr.yy);
    }

    # Statacc:
    if (F) {
	rr := F;
	for (i in [1:10]) {
	    nvv := 10;
	    vv := i*[1:nvv];
	    ww := rep(0.3,nvv);
	    ff := rep(F,nvv);
	    ff[[3,7,min(i,nvv)]] := T;
	    jnm.statacc(rr, vv=vv, ff=ff, ww=ww, name='test',trace=T);
	}
	print '\n before calc:';
	for (fname in field_names(rr)) {print fname,':',rr[fname];}
	jnm.statacc(rr,calc=T,trace=T);
	print '\n after calc:';
	for (fname in field_names(rr)) {print fname,':',rr[fname];}
    }


    return T;
};
# test_jenmath();
# inspect(jnm,'jnm');		# try and inspect

#===========================================================
# Remarks and things to do:
#================================================================


