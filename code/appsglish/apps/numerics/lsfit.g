# lsfit.g: least-squares fit by matrix inversion
# Copyright (C) 1996,1998,1999,2001
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


pragma include once
# NB: Should go to directory /aips++/code/trial/Mathematics/

# print 'include lsfit.g  h01sep99'
include "matrix.g"


#=========================================================
const lsfit_functions := function () {
   private := [=];
   public := [=];

#---------------------------------------------------------
# Get some results:

    public.help := function () {
    	return private.help ();
    }
    public.init := function (nuk=0, keep=T, mode='chol') {
    	return private.init (nuk, keep, mode);
    }
    public.inityonly := function () {
    	return private.inityonly();
    }
    public.accumulate := function (xx, y, wgt=1.0, constreq=F, show=F) {
    	return private.accumulate(xx, y, wgt, constreq, show);
    }
    public.weak_link := function (xx=F, y=0, wgt=0.0001, show=T) {
	if (is_boolean(xx)) {
	    if (private.nuk<=0) fail ('weak_link: nuk=0');
	    xx := rep(1.0, private.nuk);
	}
	print 'add weak_link constraint:',xx;
    	return private.accumulate(xx, y, wgt, constreq=T, show=show);
    }
    public.solve := function (yy=F) {
    	return private.solve (yy);
    }
    public.check := function () {
    	return private.check ();
    }
    public.resid := function () {
	return private.resid;
    }
    public.rms := function () {
	return private.rms;
    }
    public.solvec := function () {
	return private.solvec;
    }
    public.reconstyy := function () {
	return private.reconstyy;
    }
    public.status := function (name=' ', full=F) {
    	return private.status (name, full);
    }
    public.show := function(name) {
    	return private.print (name);
    }
    public.yy := function () {
	return private.yy;
    }
    public.wy := function () {
	return private.wy;
    }
    public.isconstreq := function () {
	return private.isconstreq;
    }
    public.ata := function () {
	return private.ata;
    }
    public.inv := function () {
	return private.inv;
    }
    public.nullspace := function () {
	return private.nullspace;
    }
    public.sv := function () {
	return private.svd_w;
    }
    public.svu := function () {
	return private.svd_u;
    }
    public.svv := function () {
	return private.svd_v;
    }
    public.cholp := function () {
	return private.chol_p;
    }
    public.cholt := function () {
	return private.chol_t;
    }
    public.a := function () {
	if (private.naccx<=0) fail ('nacc=0');
	if (private.nuk<=0) fail ('nuk=0');
	aa := array(0,private.naccx,private.nuk);
	for (i in [1:private.naccx]) {
	    aa[i,] := private.a[i];
	}
	return aa;
    }
    public.varyambig := function (tryval=F, niter=1, show=F) {
    	return private.varyambig (tryval, niter, show);
    }
    public.varyambig_rms := function () {
    	return private.varyambig_rms;	# vector of rms-values
    }
    public.test := function (nuk=5, keep=F, mode='chol', ambig=0) {
    	return private.test(nuk, keep, mode, ambig);
    }

#-----------------------------------------------------------
# Initialise the lsf-object (solution matrices etc):
# If keep=T, keep the input coefficient matrix.


    private.init := function (nuk=0, keep=T, mode='chol') {
	wider private;
	if (nuk<=0) {
	    fail('nr of ubknowns should be >0');
	}
	private.nuk := max(1,nuk);	# nr of unknowns
	private.keep := keep;	# keep full input matrix 
	private.mode := mode;	# inversion mode
	if (private.mode=='chol') {
	} else if (private.mode=='svd') {
	} else if (private.mode=='gauss') {
	} else {
	    private.mode := 'chol';	# default mode
	}
	private.naccx := 0;	# nr of accumulated equations.
	private.checksumx := 0;	# sum of input coefficients
	private.a := [=];	# for keeping input coeff vectors
	private.nconstreq := 0;	# nr of constraint equations
	private.constreq := [=];# coeff vectors of constr equs
	private.isconstreq := F;# boolean vector of length naccx
	private.ata := array(0,private.nuk,private.nuk);
	private.wy := [];	# for keeping input y-weights
	private.doInvert := T;	# new inverse needed
	private.inv := F;	# matrix: inverse of private.ata
	private.var := F;	# variance vector
	private.covar := F;	# covariance matrix
	private.svd_u := F;	# SVD decomposition matrix
	private.svd_v := F;	# SVD decomposition matrix
	private.svd_w := F;	# SVD singular values
	private.nullspace := F;	# null space (SVD only)
	private.chol_p := F;	# Choleski decomp. vector
	private.chol_t := F;	# Choleski decomp. matrix
	private.inity();	# 
	private.varyambig_rms := F;# history of varyambig rms values
	return T;
   }

# Initialise the driving vector only:

    private.inityonly := function () {
	wider private;
	private.inity();		# but NOT private.initx()!
	private.yonly := T;	# comes AFTER inity()!
	private.keep := F;		# save room ...?
	private.a := [=];		# save room ...?
	return T;
    }

# Initialise quantities related to the driving vector y:

    private.inity := function () {
	wider private;
	private.naccy := 0;	# nr of accumulated y-values.
	private.checksumy := 0;	# sum of input coefficients
	private.yy := [];		# for keeping input y-values
	private.aty := rep(0,private.nuk); 
	private.yonly := F;	# .....?

	private.solvec := F;	# most recent solution vector
	private.reconstyy := [];	# reconstructed from solvec
	private.resid := F;	# residuals: reconstyy-yy
	private.rms := F;		# rms residuals
	return T;
    }

#---------------------------------------------------------

    private.help := function () {
	s := '\n Least-squares fitting functions:'
	s := paste(s,'\n lsf := make_lsfit()');
	s := paste(s,'\n lsf.test()');
	s := paste(s,'\n lsf.init(nuk, keep=T, mode=chol)');
	s := paste(s,'\n . keep=T: keep full input matrix');
	s := paste(s,'\n . NB: convenient, but takes space.');
	s := paste(s,'\n lsf.inityonly()');
	s := paste(s,'\n lsf.accumulate(xx,y,wgt=1,constreq=F,show=F)');
	s := paste(s,'\n . xx is coefficient vector');
	s := paste(s,'\n . y  is driving (rhs) value');
	s := paste(s,'\n . constreq=T: constraint equation');
	s := paste(s,'\n . show=T: print one-line message');
	s := paste(s,'\n lsf.solve(yy=F)');
	s := paste(s,'\n . solve for nuk unknowns');
	s := paste(s,'\n . if yy not given, use internal');
	s := paste(s,'\n solvec := lsf.solvec()');
	s := paste(s,'\n rms := lsf.rms(), only if keep=T!');
	s := paste(s,'\n resid := lsf.resid(), only if keep=T!');
	s := paste(s,'\n reconstyy := lsf.reconstyy()');
	s := paste(s,'\n print lsf.status([name])');
	s := paste(s,'\n lsf.printPrivate()');
	s := paste(s,'\n');
	return s;
    }

# Return the current status of the lsf-object as a string:

    private.status := function (name=' ', full=F) {
	s := spaste('\n Status of lsf object',name,':');
	s := spaste(s,'\n nr of unknowns=',private.nuk);
	s := spaste(s,'\n accumulated equs: naccx=',private.naccx);
	if (private.naccx != private.naccy) {
	    s := spaste(s,'naccy:',private.naccy,'!)');
	}
	s := spaste(s,'(doInvert=',private.doInvert,')');
	s := spaste(s,'\n private.ata: dim=',private.ata::shape);
	s := spaste(s,' min=',min(private.ata),' max=',max(private.ata));
	s := spaste(s,'\n private.aty: len=',length(private.aty));
	s := spaste(s,' min=',min(private.aty),' max=',max(private.aty));

	s := spaste(s,'\n private.keep=',private.keep);
	s := spaste(s,' len(a)= ',len(private.a));
	if (len(private.a)>0) {
	    s := spaste(s,' na[1]= ',len(private.a[1]));
	}
	s := spaste(s,' nyy=',len(private.yy));

	s := spaste(s,'\n weights: nwy=',len(private.wy));
	s := spaste(s,' min=',min(private.wy),' max=',max(private.wy));

	if (full | private.nconstreq>0) {
	    s := spaste(s,'\n nconstreq=',private.nconstreq);
	    s := spaste(s,' isconstreq=',private.isconstreq);
	}
	if (full | private.yonly) {
	    s := spaste(s,'\n yonly=',private.yonly);
	    s := spaste(s,' checksumx=',private.checksumx);
	    s := spaste(s,' checksumy=',private.checksumy);
	}

	s := spaste(s,'\n inversion mode=',private.mode);
	if (private.mode=='chol') {
	    s := spaste(s,'\n private.chol_p: ',private.chol_p);
	} else if (private.mode=='svd') {
	    s := spaste(s,'\n private.svd_w: ',private.svd_w);
	}
	s := spaste(s,'\n private.inv: dim=',private.inv::shape);
	s := spaste(s,' min=',min(private.inv),' max=',max(private.inv));

	s := spaste(s,'\n private.solvec: n=',len(private.solvec));
	s := spaste(s,' nresid=',len(private.resid));
	s := spaste(s,' rms=',private.rms);
	return spaste(s,'\n');
    }

    public.print := function(name) {
	if (name=='ata') {
	    mx.print(private.ata,'private.ata');
	} else if (name=='inv') {
	    mx.print(private.inv,'private.inv');
	} else if (name=='aty') {
	    print 'private.aty:',private.aty;
	} else if (name=='status') {
	    print public.status();
	} else if (name=='private') {
	    print '\n lsf record private:\n',private,'\n';
	}
    }

#------------------------------------------------------------
# Accumulate a new equation to the solution matrix. 
# xx is a coefficient vector. y is the driving value.
# If constr==T, the input represents a constraint equation.


    private.accumulate := function (xx, y, wgt=1.0, constreq=F, show=F) {
	wider private;
	if ((nxx:=length(xx))!=private.nuk) {
	    fail(spaste('nxx=',nxx,'!=',private.nuk));
	}
	if (wgt!=1.0) xx *:= wgt;	# mult coeff by weights 
	private.aty +:= xx*(y*wgt);	# accumulate vector aty
	private.naccy +:= 1;		# increment counter
	sumabsxx := sum(abs(xx));
	private.checksumy +:= sumabsxx;
	private.yy[private.naccy] := y;	# keep input y's 
	s := spaste('lsf.acc: ',private.naccy,': y=',y);

	if (private.yonly) {		# re-use existing ata/inv
	    if (show) print s;
	    return T;

	} else {			# accumulate matrix ata
	    for (j in [1:nxx]) {private.ata[,j] +:= xx * xx[j]};
	    private.doInvert := T;		# new inversion needed
	    private.naccx := private.naccy;	# the same at this point
	    private.checksumx +:= sumabsxx;# := private.checksumy;
	    private.wy[private.naccy] := wgt;	# keep input weights's 
	    if (private.keep) {		# see solve(yy) below
		private.a[private.naccx] := xx;	# keep xx-vectors
	    }
	    s := spaste(s,' xx=',xx);

	    if (constreq) {		# constraint equation
		private.nconstreq +:= 1;
		private.constreq[private.nconstreq] := xx;
		private.isconstreq[private.naccx] := T;
		s := spaste(s,' (constreq)');
	    } else {
		private.isconstreq[private.naccx] := F;
	    }
	    if (show) print s;
	}
	return s;		# return progress message (string)
    }

#---------------------------------------------------------------
# Solve for the accumulated y-values, and return the
# solution vector (quality?). 
# First invert the solution matrix, if necessary. 

    private.solve := function (yy=F) {
	wider private;
	if (private.naccx<=0) {
	    fail('naccx=0: nothing accumulated');
	} else if (is_boolean(yy)) {	# no new yy-vector
	    # OK, solve for accumulated private.yy
	} else if (len(yy) != len(private.a)) {
	    fail('len(yy) != len(private.a)')
	} else {			# solve for given yy
	    private.inity();
	    private.yonly := F;		# overridden
	    for (i in [1:len(yy)]) {
		private.yy[i] := yy[i];
		private.naccy +:= 1;
		# private.checksumy +:= sum(abs(private.a[i])); 
		private.aty +:= private.a[i] * (private.yy[i]*private.wy[i]);
	    }
	}

	if (private.yonly) {
	    if (private.checksumx != private.checksumy) {
	    	fail('checksums x/y differ');
	    }
	} else if (private.naccy != private.naccx) {
	    fail('private.naccy != private.naccx')
	} else if (private.doInvert) {
	    if (is_fail(private.invert())) fail('invert');
	}

	private.dosolve();			# solve for private.aty
	if (private.keep) {
	    rms := public.check();	# calculate resid etc
	    if (is_fail(rms)) fail('dosolve, check');
	}
	return private.solvec;
    }

# Prepare for solution by inversion or decomposition:
# If inversion/decomposition fails, try adding a weak_link constraint:

    private.invert := function () {
	wider private;
	if (private.mode=='gauss') {
	    private.inv := mx.invert(private.ata);
	    if (is_fail(private.inv)) {
		# print 'invert failed, try adding weak_link:'
		public.weak_link();	# try constraint equation
		private.inv := mx.invert(private.ata);
		if (is_fail(private.inv)) fail(paste('mode=',private.mode));
	    } 

	} else if (private.mode=='chol') {
    	    private.chol_t := private.chol_p := 0.0;
	    ata := private.ata;         # keep a local copy
    	    r := mx.choldcmp(private.ata, 
			     private.chol_t, private.chol_p);
	    if (is_fail(r)) {
		# print 'invert failed, try adding weak_link:';
		private.ata := ata;     # recover the original (see above)
		public.weak_link();	# try constraint equation
		r := mx.choldcmp(private.ata, 
				 private.chol_t, private.chol_p);
		if (is_fail(r)) fail(paste('mode=',private.mode));
	    }

	} else if (private.mode=='svd') {
    	    private.svd_u := private.svd_v := private.svd_w := 0.0;	
    	    r := mx.svdcmp(private.ata, 
			   private.svd_u, private.svd_w, private.svd_v);
	    if (is_fail(r)) fail(paste('mode=',private.mode));

	    w := private.svd_w;	
	    sv := [abs(w)<max(abs(w))*1.0e-6];
	    w[sv] := 1;			# replace small sv's
	    # private.svd_w[sv] := 0;	# for recognition?
	    ww := mx.diagonalmatrix(1/w);
    	    private.inv := mx.mult(mx.mult(private.svd_v, ww),
			        mx.transpose(private.svd_u));
	}
	private.doInvert := F;
    }

# Do the actual solution for vector private.aty:

    private.dosolve := function () {
	wider private;
	if (private.mode=='chol') {
    	    private.solvec := mx.cholsol(private.chol_t,
				      private.chol_p, private.aty);	
	} else {
	    private.solvec := mx.multmv(private.inv, private.aty);
	}
	return T;
    }
   
#--------------------------------------------------------------
# Asses the accuracy of the most recent solution....

    private.check := function () {
	wider private;
	if (private.nuk<=0) {
	    fail ('nr of unknowns nuk=0');
	} else if (private.naccx<=0) {
	    fail ('nothing accumulated: naccx=0')
	} else if (is_boolean(private.aty)) {
	    fail ('vector aty not defined')
	} else if (!private.keep) {
	    fail ('input matrix (a) not kept')
	} else if (is_boolean(private.solvec)) {
	    fail ('no solution vector')
	}
	private.resid := private.yy;
	private.reconstyy := [];
	for (i in [1:private.naccy]) {
	    private.reconstyy[i] := sum(private.a[i] * private.solvec);
	    if (private.wy[i]!=0) private.reconstyy[i] /:= private.wy[i];
	    private.resid[i] -:= private.reconstyy[i];
	    # print i,private.resid[i];
	}
	private.rms := sqrt(sum(private.resid*private.resid)/private.naccy);
	return private.rms;
    }

#================================================================
# Routine to deal iteratively with 2pi phase ambiguities in the input
# (or any other imput ambiguities, if we can think of them).

    private.varyambig := function (tryval=F, niter=1, show=F) {
	wider private;
	yy := public.yy();		# get input y-vector
	if ((nyy:=len(yy))<=0) fail('input yy has zero length');
	rms := public.check();
	solvec := public.solvec();
	resid := public.resid();
	isconstreq := public.isconstreq();
	if (is_boolean(rms)) fail('boolean rms');
	if (!private.keep) fail('xx and y have not been kept');

	if (is_boolean(tryval)) {
	    pi2 := 2*acos(-1);          # 2pi = 6.28... 
	    tryval := [-1,1]*pi2;       # assume phase(rad)..?
	}

	s := paste('\n lsf.varyambig(): initial: rms=',rms);
	if (show) print s;

	rr := rms;			# rms 'history'
	nrr := 1;
	niter := max(1,niter);          # at least one 

	finished := F;
	for (iter in [1:niter]) {       # niter iterations
	    for (i in [1:nyy]) {
		if (isconstreq[i]) {
		    if (show) print i,'skip constraint equation';
		    next;
		}
		yi := yy[i];		# current yy[i]-value
		yinew := yi;		# new yy[i]-value
		for (dy in tryval) {
		    yy[i] := yi + dy;	# change y[i]
		    public.solve(yy);	# solve for new yy-vector
		    rms1 := public.rms();# new rms
		    if (rms1<rms) {	# better solution
			yinew := yy[i];	# better value for yy[i]
			solvec := public.solvec();
			resid := public.resid();
			s1 := spaste(i,': dy=',dy);
			if (rms1<(rms/30)) {  # big drop
			    s1 := paste(s1,'big drop in rms:');
			    s1 := spaste(s1,'  final rms=',rms1); 
			    finished := T;    # ok, escape
			} else {
			    rms := rms1;      # new best rms
			    s1 := spaste(s1,'  new rms=',rms); 
			}
			if (show) print s1;
			s := spaste(s,'\n',s1);
		    }
		    rr[nrr+:=1] := rms;	# add to history
		    if (finished) break;
		}
		yy[i] := yinew;	# use best value for yy[i]
		if (finished) break;
	    }
	}
	private.varyambig_rms := rr;	# store
	    
	# Bring the lsf-object in its best possible state:

	public.solve(yy);	# solve again for final yy-vector
	return s;		# return the log-string
    };

#=========================================================

    private.test := function (nuk=5, keep=F, mode='chol', ambig=0) {
	xxin := [1:nuk];
	print '\n lsf.test(): Simulated values: xxin=',xxin;
	if (ambig>0) keep := T;
	public.init(nuk, keep, mode=mode); 
	# print public.status();
	phase := T;
	yyin := [];
	noise := random(nuk*nuk);
	noise := 0.1*((noise/max(noise))-0.5);
	n := 0;
	for (i in [1:(nuk-1)]) {
    	    for (j in [(i+1):nuk]) {
		n +:= 1;
		cc := rep(0,nuk);
		cc[i] := 1;
		cc[j] := 1;
		if (phase) cc[j] := -1;
		y := xxin[i]*cc[i] + xxin[j]*cc[j];
		# y +:= noise[n];
		yyin := [yyin,y];
		if (ambig>0) {
		    dy := 0;
		    if (i==1 && j==2) dy := ambig;
		    if (i==1 && j==nuk) dy := ambig;
		    if (i==(nuk-1) && j==nuk) dy := -ambig;
		    if (dy!=0) {
			print 'lsf.test: corrupt:',n,':',i,j,'y=',y,'->',y+dy;
			y +:= dy;	# add ambiguity-value
		    }
		}
		wgt := 1.0;		# default weight if not given
		# wgt := 2.0;		# test
		# if (i==2 | j==2) wgt:= 0;	# test
		public.accumulate(cc, y, wgt, show=T);
	    }
	}
	if (phase & (mode!='svd')) {
	    # NB: If no constraint given, it is done automatically!
	    # cc := rep(1,nuk);		# sum of inputs
	    # y := sum(xxin);		# sum of inputs
	    # public.accumulate(cc, y, show=T, constreq=T);
	    # public.weak_link(y=y);    # weak-link cosntraint
	    # yyin := [yyin,y];         # NB: Only if explicit constraint!
	}
	public.solve();			# solve for input yy
	xxout := public.solvec();	# solution vector

	print ' ';
	print 'Solution:  xxout=',xxout;
	print 'Compare:   xxin= ',xxin;
	print 'Difference:      ',xxout-xxin;
	print ' ';
	print 'input yy:      yyin=   ',yyin;
	print 'input yy:  lsf.yy()=   ',public.yy();
	print 'residuals: lsf.resid()=',public.resid();
	print 'rms resid:   lsf.rms()=',public.rms();
	print ' ';
	print public.status();

	if (ambig>0) {
	    public.varyambig([-ambig,ambig], niter=1, show=T);
	    # print public.status();
	    print 'final rms=',public.rms();
	    print 'final solvec=',public.solvec();
	    print 'final resid=',public.resid();
	    print 'final yy=',public.yy();
	    print 'reconstyy=   ',public.reconstyy();
	    print 'perfect yyin=',yyin;
	    yyout := public.reconstyy();
	    n := len(yyout) - len(yyin);        # e.g. implicit constraint
	    if (n>0) yyin := [yyin,rep(0,n)];   # make the same length
	    print 'difference=  ',yyout-yyin;
	}
    };


#---------------------------------------------------------
    public.init(1);		# bring into a known state
    return public;

};		# closing bracket of make_lsfit
#=========================================================

const lsf := lsfit_functions();		# make lsf object
# lsf.test(nuk=6, keep=T, mode='chol', ambig=1)	# temporary














