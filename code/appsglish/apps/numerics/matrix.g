# matrix.g: collection of matrix/vector routines
# Copyright (C) 1996,1999
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
# NB: Should go into directory /aips++/code/trial/scripts/

# print 'include matrix.g  h01sep99'
		
#=========================================================
matrix_functions := function () {
    private := [=];
    public := [=];

#---------------------------------------------------------
    private.pi := acos(-1);
    private.Rad2Deg := 180/private.pi;
#---------------------------------------------------------

    public.help := function (){
	s := '\n matrix/vector operations:'
	s := paste(s,'\n mx := matrix_functions()');
	s := paste(s,'\n m := mx.testmatrix(n)');
	s := paste(s,'\n m := mx.make_symmetric(mat, hermitian=F)');
	s := paste(s,'\n m := mx.unitmatrix(n)');
	s := paste(s,'\n m := mx.diagonalmatrix(vec)');
	s := paste(s,'\n m := mx.rotationmatrix(angle,deg=F)');
	s := paste(s,'\n v := mx.rotate(vec,angle,deg=F)  NB: nv=2');
	s := paste(s,'\n m := mx.symbolic(name,nrow,ncol=F)');
	s := paste(s,'\n m := mx.transpose(mat)');
	s := paste(s,'\n m := mx.mult(mat1,mat2)');
	s := paste(s,'\n .    m := mx.multvm(vec,mat)');
	s := paste(s,'\n .    m := mx.multmv(mat,vec)');
	s := paste(s,'\n .    m := mx.multvv(vec,vec)');
	s := paste(s,'\n m := mx.directproduct(mat1,mat2)');
	s := paste(s,'\n s := mx.dotproduct(vec1,vec2)    NB: nv1=nv2');
	s := paste(s,'\n v := mx.crossproduct(vec1,vec2)  NB: nv1=nv2=3');
	s := paste(s,'\n m := mx.invert(mat)');
	s := paste(s,'\n .    mx.svdmp(mat, u, w, v)');
	s := paste(s,'\n .    mx.choldcmp(mat, t, p)');
	s := paste(s,'\n v := mx.cholsol(t, p, b)');

	s := paste(s,'\n s := mx.cosangle(vec1,vec2)');
	s := paste(s,'\n a := mx.angle(vec1,vec2,deg=F)');
	s := paste(s,'\n s := mx.norm(mat)');
	s := paste(s,'\n s := mx.mean(mat)');
	s := paste(s,'\n s := mx.rms(mat)');
	s := paste(s,'\n tf := mx.is_matrix(mat)');
	s := paste(s,'\n tf := mx.is_vector(vec)');
	s := paste(s,'\n tf := mx.is_symmetric(mat)');
	s := paste(s,'\n tf := mx.is_hermitian(mat)');
	s := paste(s,'\n v := mx.diagonal(mat, newdiag=F)');
	s := paste(s,'\n print mx.statistics(mat)');
	s := paste(s,'\n print mx.print(mat, name)');
	s := paste(s,'\n mx.test()');
	s := paste(s,'\n');
	return s;			# return the string
    }

    public.test := function () {
	return private.test();
    }

    public.statistics := function (ref m) {
    	return private.statistics (m);
    }
    public.invert := function (ref m) {
    	private.invert (m);
    }
    public.svdcmp := function(ref a, ref u, ref w, ref v) {
    	return private.svdcmp(a, u, w, v);
    }
    public.choldcmp := function(ref a, ref t, ref p) {
    	return private.choldcmp (a, t, p);
    }
    public.cholsol := function (ref t, ref p, b) {
    	return private.cholsol (t, p, b);
    }
    public.transpose := function(ref m) {
	if (!public.is_matrix(m)) fail('transpose: not a matrix');
	dm := shape(m);
	mt := array(0,dm[2],dm[1]);
	for (i in [1:dm[1]]) {mt[,i] := m[i,]};
	return mt;
    }
    public.directproduct := function(ref m1, ref m2) {
	return private.directproduct(m1,m2);
    }
    public.crossproduct := function(ref v1, ref v2) {
	if (length(v1)!=3) fail('crossproduct: nv1!=3');
	if (length(v2)!=3) fail('crossproduct: nv2!=3');
	v := [0,0,0];
	v[1] := v1[2]*v2[3] - v1[3]*v2[2];
	v[2] := v1[3]*v2[1] - v1[1]*v2[3];
	v[3] := v1[1]*v2[2] - v1[2]*v2[1];
	return v;
    }
    public.dotproduct := function(ref v1, ref v2) {
	if (length(v1)!=length(v2)) fail('dotproduct: nv1!=nv2');
	return sum(v1*v2);
    }
    public.rotate := function(ref v, angle, deg=F) {
	if (length(v)!=2) fail('rotate, not 2-vector')
	rm := public.rotationmatrix(angle,deg);
	return private.multmv(rm,v);
    }
    public.rotationmatrix := function(angle,deg=F) {
	if (deg) angle /:= private.Rad2Deg;
	c := cos(angle);
	s := sin(angle);
	return array([c,s,-s,c],2,2);  
    }
    public.angle := function(ref v1, ref v2, deg=F) {
	c := public.cosangle(v1,v2);
	if (is_fail(c)) fail(c);
	a := acos(c);
	if (deg) return a * private.Rad2Deg;  # degrees
	return a;			   # radians (default)
    }
    public.cosangle := function(ref v1, ref v2) {
	if (length(v1)!=length(v2)) fail('angle: nv1!=nv2');
	v12 := sqrt(sum(v1*v1)*sum(v2*v2));
	if (v12==0) v12 := 1;
	return sum(v1*v2)/v12;		# cos(angle)
    }
    public.symbolic := function(name, nrow, ncol=F) {
    	return private.symbolic (name,nrow,ncol);
    }
    public.norm := function(ref m) {
	if (length(m)==0) return 0;
	return sqrt(sum(m*m));
    }
    public.mean := function(ref m) {
	if ((n:=length(m))==0) return 0;
	return sum(m)/n;
    }
    public.rms := function(ref m) {
	if ((n:=length(m))==0) return 0;
	mean := sum(m)/n;
	return sqrt(max(0,(sum(m*m)/n)-(mean*mean)));
    }
    public.print := function(ref m, name=' ', prec=3, stat=T) {
   	return private.print(m, name, prec, stat);
    }
    public.mtm := function (ref m) {
	return public.mult(m,public.transpose(m));
    }
    public.mult := function (ref m1, ref m2) {
	if (!public.is_matrix(m1)) return public.multvm(m1,m2);
	if (!public.is_matrix(m2)) return public.multmv(m1,m2);
	return private.multMM(m1,m2);
    }
    public.multvm := function(ref v, ref m) {
	if (!public.is_matrix(m)) return public.multvv(v,m);
	return private.multvm(v,m);
    }
    public.multmv := function(ref m, ref v) {
	if (!public.is_matrix(m)) return public.multvv(m,v);
	return private.multmv(m,v);
    }
    public.multvv := function(ref v1, ref v2) {
	if (length(v1) != length(v2)) {
	    fail(paste('multvv: not commensurate',
			length(v1),length(v2)));
	}
	return sum(v1*v2);
    }
    public.unitmatrix := function (n) {
   	return public.diagonalmatrix(array(1,n));
    }
    public.diagonalmatrix := function (ref diag) {
	n := length(diag);
	mat := array(0,n,n);
	for (i in [1:n]) {mat[i,i]:=diag[i];};
	return mat;
    }
    public.diagonal := function (ref m, newdiag=F) {
	return private.diagonal(m, newdiag);
    }

    public.testmatrix := function (nrow=3, ncol=F) {
	return private.testmatrix (nrow, ncol);
    }
    public.make_symmetric := function (ref m, hermitian=F) {
	return private.make_symmetric (m, hermitian);
    }
    public.is_matrix := function (ref m) {
	if (length(shape(m))!=2) return F;
	return T;
    }
    public.is_vector := function (ref v) {
	if (length(shape(v))!=1) return F;
	return T;
    }
    public.is_square := function (ref m) {
	dim := shape(m);
	if (length(dim)!=2) return F;
	if (dim[1]!=dim[2]) return F;
	return T;
    }
    public.is_symmetric := function (ref m, tol=0.0) {
	return private.is_symmetric(m, tol);
    }
    public.is_hermitian := function (ref m, tol=0.0) {
	return private.is_hermitian(m, tol);
    }



#---------------------------------------------------------
#---------------------------------------------------------
# Private functions:
#---------------------------------------------------------
#---------------------------------------------------------
# Various tests:

    private.is_symmetric := function (ref m, tol=0.0) {
	if (!public.is_square(m)) return F;
	n := shape(m)[1];
	for (i in [1:n]) {
	    for (j in [i:n]) {
		if (abs(m[i,j]-m[j,i])>tol) return F;
	    }
	}
	return T;
    }

    private.is_hermitian := function (ref m, tol=0.0) {
	if (!public.is_square(m)) return F;
	if (is_complex(m) || is_dcomplex(m)) {
	    n := shape(m)[1];
	    for (i in [1:n]) {
		for (j in [i:n]) {
		    if (abs(m[i,j]-conj(m[j,i]))>tol) return F;
		}
	    }
	} else {
	    if (public.is_symmetric(m, tol)) return T;
	}
	return F;
    }

#---------------------------------------------------------
# Multiplication of matrices and/or vectors:

    private.multMM := function (ref m1, ref m2) {
	d1 := shape(m1);
	d2 := shape(m2);
	if (d1[2] != d2[1]) {
	    fail(paste('multMM: not commensurate',d1,d2));
	}
	mat := array(0,d1[1],d2[2]);
	for (i in [1:d1[1]]) {
	    for (j in [1:d2[2]]) {
		mat[i,j] := sum(m1[i,]*m2[,j]);
	    }
	}
	return mat;
    }

    private.multvm := function(ref v, ref m) {
	if (!public.is_matrix(m)) return public.multvv(v,m);
	dm := shape(m);
	nv := length(v);
	if (nv != dm[1]) {
	    fail(paste('multvm: not commensurate',nv,dm));
	}
	vec := [1:dm[2]];
	for (i in [1:dm[2]]) {
		vec[i] := sum(v*m[,i]);
	}
	return vec;
    }

    private.multmv := function(ref m, ref v) {
	if (!public.is_matrix(m)) return public.multvv(m,v);
	dm := shape(m);
	nv := length(v);
	if (nv != dm[2]) {
	    fail(paste('multmv: not commensurate',dm,nv));
	}
	vec := [1:dm[1]];
	for (i in [1:dm[1]]) {
		vec[i] := sum(v*m[i,]);
	}
	return vec;
    }

#--------------------------------------------------------
# Get the diagonal (of a square matrix).
# If newdiag is supplied, replace the diagonal first.

    private.diagonal := function (ref m, newdiag=F) {
	if (length(m)<=0) {
	    return [];
	} else if (!public.is_square(m)) {
	    fail(paste('diagonal: matrix not square:',shape(m)));
	}
	n := shape(m)[1];
	if (!is_boolean(newdiag)) {
	    nd := length(newdiag);
	    if (nd != n) {
		fail(paste('diagonal: length mismatch:',nd,n));
	    }
	    for (i in [1:n]) {m[i,i] := newdiag[i];};
	}
	v := rep(0,n);
	for (i in [1:n]) {v[i]:=m[i,i];};
	return v;
    }

#---------------------------------------------------------------
# Make a test-matrix, and fill it with index-related numbers:

    private.testmatrix := function (nrow=3, ncol=F) {
	nrow := max(1,nrow);
	if (is_boolean(ncol)) ncol := nrow;
	m := array(0,nrow,ncol);
	for (i in [1:nrow]) {
	    i10 := 10*i;
	    for (j in [1:ncol]) {
		m[i,j] := i10 + j;
	    }
	}
	return m;
    }

# Make a (square) matrix symmetric, or hermitian:

    private.make_symmetric := function (ref m, hermitian=F) {
	if (!public.is_square(m)) return F;
	dim := shape(m);
	for (i in [1:dim[1]]) {
	    if (hermitian) m[i,i] := real(m[i,i]);
	    for (j in [i:dim[2]]) {
		m[j,i] := m[i,j];
		if (hermitian) m[j,i] := conj(m[i,j]);
	    }
	}
	return T;
    }

#--------------------------------------------------------
# Direct matrix product (Kronecker product):

    private.directproduct := function(ref m1, ref m2) {
	if (!public.is_matrix(m1)) {
	    fail('directproduct: m1 not a matrix');
	} else if (!public.is_matrix(m2)) {
	    fail('directproduct: m2 not a matrix');
	}
	dm1 := shape(m1);
	dm2 := shape(m2);
	cm2 := conj(m2);		# complex conjugate
	m := array(0,dm1[1]*dm2[1],dm1[2]*dm2[2]);
	for (i in [1:dm1[1]]) {
	    ii := [(1+2*(i-1)):(2*i)];
	    for (j in [1:dm1[2]]) {
		jj := [(1+2*(j-1)):(2*j)]; 
		m[ii,jj] := m1[i,j]*cm2;
	    }
 	}
	return m;
    }

#-----------------------------------------------------------
# Make a matrix with symbolic elements (useful?):

    private.symbolic := function(name,nrow,ncol=F) {
	if (is_boolean(ncol)) {
	    m := ' ';
	    for (i in [1:nrow]) {
		m[i] := spaste(name,i);
	    }
	} else {
	    m := array('.',nrow,ncol);
	    for (i in [1:nrow]) {
	    	for (j in [1:ncol]) {
		    m[i,j] := spaste(name,i,j);
	    	}
	    }
	}
	return m;
    }

#-----------------------------------------------------------
# Print a matrix in an organised manner:

    private.print := function(m, name=' ', prec=3, stat=T) {
	s1 := private.statistics(m);
	if (is_fail(s1)) fail(paste('empty matrix',name));
	if (!stat) s1 := ' ';		# no statistics
	m[abs(m)<1.0e-10] := 0;
	(m)::print.precision := prec;
	s := spaste('\n',name,':\n',m);
	return paste(s,'\n',s1);
    }

    private.statistics := function (ref m) {
	if ((n:=len(m))<=0) fail('empty');
	s := type_name(m);
	if (is_boolean(dim:=shape(m))) {
	    s := spaste(s,' vector[',n,']');
	} else {
	    s := spaste(s,' matrix',dim);
	}
	a := [min(m),max(m),sum(m)/n,sum(m*m)/n];
	a[4] := sqrt(max(0,a[4]-a[3]*a[3]))
	a::print.precision := 3;
	s := spaste(s,' (min=',a[1],' max=',a[2]);
	s := spaste(s,' mean=',a[3],' rms=',a[4],')');
	return s;
    }


    private.printmat := function(ref m, name=' ',prec=0) {
	dm := shape(m);
	if (!dm) dm := length(m);
	s := spaste('(',dm,')');
	s := spaste(s,' min=',min(m));
	s := spaste(s,' max=',max(m));
	s := spaste(s,' absmin=',min(abs(m)));
	absmax := max(abs(m));
	absmin := absmax/100000;
	m[abs(m)<absmin] := 0;	# ignore small values..?
	if (prec>0) {
	    (m)::print.precision := prec;			
	}
	print paste('matrix ',name,s);
	print m;
	return T
    }


#----------------------------------------------------------
# Matrix inversion

    private.invert := function (ref m) {
	dm := shape(m); 
	if (!dm) { 
	    s := 'invert: not a 2D matrix';
	    fail(paste(s,'m=',m));
	} else if (length(dm)!=2) {
	    s := 'invert: not a 2D matrix';
	    fail(paste(s,'dm=',dm));
	} else if (dm[1]<dm[2]) {	# rectangular
	    s := 'invert: underdetermined';
	    fail(paste(s,'nrows<ncols:',dm));
	} else if (dm[1]==dm[2]) {	# square matrix
	    return private.invertGJ(m);    # Gauss-Jordan
	} else {			# rectangular
	    mt := public.transpose(m);
	    minv := private.invertGJ(private.multMM(mt,m)); 
	    if (is_fail(minv)) fail(minv);
	    return private.multMM(minv,mt);
	}  
    }

#---------------------------------------------------------
# Gauss-Jordan (square) matrix inversion:

    private.invertGJ := function (m) {
	n := shape(m)[1];	  # assume square non-zero
	iicol := 0*[1:n];
	iirow := 0*[1:n];
	ipiv := 0*[1:n];
	for (i in [1:n]) {
	    big := 0;
	    ipiv0 := [ipiv==0];
	    for (j in [1:n]) {
		if (ipiv[j] == 0) {
		    absrow := abs(m[j,]);
		    absrow[!ipiv0] := 0;  	# ignore
		    if ((maxabs:= max(absrow))>big) {
			big := maxabs;
			irow := j;
			icol := ind(absrow)[absrow==maxabs];
		    }
		}; # if ipiv[j]
	    }; # next j
	    ipiv[icol] +:= 1;		# increment
	    if (any(ipiv>1)) {
		fail(paste('invert: matrix is singular'))
	    }
	    if (irow != icol) {		# if necessary,
		row := m[irow,];	#   interchange rows
		m[irow,] := m[icol,];
		m[icol,] := row;
	    }
	    iirow[i] := irow;
	    iicol[i] := icol;
	    if (m[icol,icol] == 0) {
		fail(paste('invert: singular matrix'))
	    }
	    pvinv := 1/m[icol,icol];	# inverse pivot
	    m[icol,icol] := 1;
	    m[icol,] *:= pvinv;		# divide row by pivot 
	
	    row := m[icol,];		# pivot row
	    for (j in [1:n]) {		# ignore pivot row
		if (j != icol) {
		    dum := m[j,icol];
		    m[j,icol] := 0;
		    m[j,] -:= row*dum;	# reduce row
		}
	    }
	}; # next i

	for (i in [n:1]) {		# inverse order!
	    icol := iicol[i]; 
	    irow := iirow[i];
	    if (icol != irow) {		# if necessary,
		col := m[,icol];	#   interchange cols
		m[,icol] := m[,irow];
		m[,irow] := col;
	    } 
	}   
	return m;
    };

#------------------------------------------------------------
# Choleski decomposition: a 2-stage process:
# Copied from Numerical Recipes (C-version, 2nd edition)

# Decompose the (square symmetric) input matrix a:

    private.choldcmp := function(ref a, ref t, ref p) {
	dim := shape(a);
	if ((n:=dim[1])!=dim[2]) {
	    fail('input matrix not square');
	}
	val t := a;			# copy the input matrix
	val p := array(0,n);		# diagonal
	for (i in [1:n]) {
	    for (j in [i:n]) {
		s := t[i,j];
		if (i>1) {
		    kk := [1:(i-1)];
		    s -:= sum(t[i,kk]*t[j,kk]);
		}
		if (i==j) {
		    if (s<=0) fail('not positive definite');
		    p[i] := sqrt(s);
		} else {
		    t[j,i] := s/p[i];
		}
	    }
	}
    }

# Solve for vector b, using the LLT matrix t and vector p
# resulting from private.choldcmp() as input:

    private.cholsol := function (ref t, ref p, b) {
	n := shape(t)[1];		# square matrix
	x := rep(0,n);			# solution vector
	for (i in [1:n]) {
	    s := b[i];
	    if (i>1) {
		kk := [1:(i-1)];
		s -:= sum(t[i,kk]*x[kk]);
	    }
	    x[i] := s/p[i];
	}
	for (i in [n:1]) {
	    s := x[i];
	    if (i<n) {
		kk := [(i+1):n];
		s -:= sum(t[kk,i]*x[kk]);
	    }
	    x[i] := s/p[i];
	}
	return x;			# solution vector
    }

#------------------------------------------------------------
# Singular Value Decomposition (SVD) of input matrix a.
# Copied from Numerical Recipes (C-version, 2nd edition)

    private.svdcmp := function(ref a, ref u, ref w, ref v) {
	m := shape(a)[1];		#.....?
	n := shape(a)[2];		#.....?
	nn := [1:n];
	mm := [1:m];
	val u := a;
	val w := array(0,n);
	val v := array(0,n,n);

	# Householder reduction to bidiagonal form:

	rv1 := rep(1,n);
	g := scale := anorm := 0.0;
	for (i in nn) {
	    im := [i:m]; if (i>m) im := [];
	    l := i+1;
	    ln := [l:n]; if (l>n) ln := [];
	    lm := [l:m]; if (l>m) lm := [];
	    rv1[i] := scale * g;
	    g := s := scale := 0.0;
	    if (i<=m) {
		for (k in im) scale +:= abs(u[k,i]);
		if (scale!=0) {
		    for (k in im) {
			u[k,i] /:= scale;
			s +:= u[k,i] * u[k,i];
		    }
		    f := u[i,i];
		    g := -private.sign(sqrt(s),f);
		    h := f*g-s;
		    u[i,i] := f-g;
		    for (j in ln) {
			s := 0.0;
			for (k in im) s +:= u[k,i]*u[k,j];
			f := s/h;
			for (k in im) u[k,j] +:= f*u[k,i];
		    }
		    for (k in im) u[k,i] *:= scale;
		}
	    }
	    w[i] := scale*g;
	    g := s := scale := 0.0;
	    if (i<=m && i!=n) {
		for (k in ln) scale +:= abs(u[i,k]);
		if (scale!=0) {
		    for (k in ln) {
			u[i,k] /:= scale;
			s +:= u[i,k] * u[i,k];
		    }
		    f := u[i,l];
		    g := -private.sign(sqrt(s),f);
		    h := f*g-s;
		    u[i,l] := f-g;
		    for (k in ln) rv1[k] := u[i,k]/h;
		    for (j in lm) {
			s := 0.0;
			for (k in ln) s +:= u[j,k]*u[i,k];
			for (k in ln) u[j,k] +:= s*rv1[k];
		    }
		    for (k in ln) u[i,k] *:= scale;
		}
	    }
	    anorm := max(anorm,(abs(w[i])+abs(rv1[i])));
	}

	# Accumulation of right-hand transformations

	for (i in [n:1]) {
	    ln := [l:n]; if (l>n) ln := [];
	    if (i<n) {
		if (g!=0) {
		    for (j in ln) v[j,i] := (u[i,j]/u[i,l])/g;
		    for (j in ln) {
		        s := 0.0;
			for (k in ln) s +:= u[i,k]*v[k,j];
			for (k in ln) v[k,j] +:= s*v[k,i];
		    }
		}
		for (j in ln) v[i,j] := v[j,i] := 0.0;
	    }
	    v[i,i] := 1.0;
	    g := rv1[i];
	    l := i;
	}

	# Accumulation of left-hand transformations

	for (i in [min(m,n):1]) {
	    im := [i:m]; if (i>m) im := [];
	    l := i+1;
	    ln := [l:n]; if (l>n) ln := [];
	    lm := [l:m]; if (l>m) lm := [];
	    g := w[i];
	    for (j in ln) u[i,j] := 0.0;
	    if (g!=0) {
		g := 1.0/g;
		for (j in ln) {
		    s := 0.0;
		    for (k in lm) s +:= u[k,i]*u[k,j];
		    f := (s/u[i,i])*g;
		    for (k in im) u[k,j] +:= f*u[k,i];
		}
		for (j in im) u[j,i] *:= g;
	    } else {
		for (j in im) u[j,i] := 0.0;
	    }
	    u[i,i] +:= 1;	
	}

	# Diagonalisation of the bidiagonal form:
	# Loop over singular values, and over allowed iterations.

	for (k in [n:1]) {
	    for (its in [1:30]) {
		flag := 1;
		for (l in [k:1]) {
		    nm := l-1;
		    if ((abs(rv1[l])+anorm)==anorm) {
			flag := 0;
			break;
		    }
		    if ((abs(w[nm])+anorm)==anorm) break;
	        }
	   	if (flag!=0) {
		    c := 0.0;
		    s := 1.0;
		    for (i in [l:k]) {
		    	f := s * rv1[i];
		    	rv1[i] := c*rv1[i];
		    	if ((abs(f)+anorm)==anorm) break;
		        g := w[i];
		        h := private.pythag(f,g);
		        w[i] := h;
		        h := 1.0/h;
			c := g*h;
		        s := -f*h;
		        for (j in mm) {
			    y := u[j,nm];
			    z := u[j,i];
			    u[j,nm] := y*c+z*s;
			    u[j,i] := z*c-y*s;
		        }
		    }
	        }

	        z := w[k];
	        if (l==k) {	  # convergence
		    if (z<0.0) {  # make singular value non-neg.
		        w[k] := -z;
		        for (j in nn) v[j,k] := -v[j,k]; 
		    }
		    break;
	        }
	        if (its==30) {
		    s := 'error: no convergence after 30'
		    s := paste(s,'svdcmp iterations');
	            fail (s);
	        }

	    	x := w[l];	# shift from bottom 2-by-2 minor
	    	nm := k-1;
	    	y := w[nm];
	    	g := rv1[nm];
	    	h := rv1[k];
	    	f := ((y-z)*(y+z)+(g-h)*(g+h))/(2.0*h*y);
	    	g := private.pythag(f,1.0);
	    	f := ((x-z)*(x+z)+h*((y/(f+private.sign(g,f)))-h))/x;
	    	c := s := 1.0;
	    	for (j in [l:nm]) {
		    i := j+1;
		    g := rv1[i];
		    y := w[i];
		    h := s*g;
		    g := c*g;
		    z := private.pythag(f,h);
		    rv1[j] := z;
		    c := f/z;
		    s := h/z;
		    f := x*c+g*s;
		    g := g*c-x*s;
		    h := y*s;
		    y *:= c;
		    for (jj in nn) {
		    	x := v[jj,j];
		    	z := v[jj,i];
		    	v[jj,j] := x*c+z*s;
		    	v[jj,i] := z*c-x*s;
		    }
		    z := private.pythag(f,h);
		    w[j] := z;
		    if (z!=0) {
		    	z := 1.0/z;
		    	c := f*z;
		    	s := h*z;
		    }
		    f := c*g+s*y;
		    x := c*y-s*g;
		    for (jj in mm) {
		    	y := u[jj,j];
		    	z := u[jj,i];
		    	u[jj,j] := y*c+z*s;
		    	u[jj,i] := z*c-y*s;
		    }
	    	}
	    	rv1[l] := 0.0;
	    	rv1[k] := f;
	    	w[k] := x;
	    }
	}
    };


# Helper function for svdcmp:
# Computes sqrt(a*a+b*b) without descructive under/overflow

    private.pythag := function(a,b) {
	absa := abs(a);
	absb := abs(b);
	if (absa>absb) { 
	    q := absb/absa;
	    return absa * sqrt(1.0+q*q);
	} else if (absb==0) {
	    return 0.0;		# because absb==0>=absa
	} else {
	    q := absa/absb;
	    return absb * sqrt(1.0+q*q);
	}
    }

# C sign function

    private.sign := function (value, sval) {
	if (sval<0) {
	    return -abs(value);
	} else {
	    return abs(value);
	}
    }

#=========================================================

    private.test := function () {
	print public.diagonalmatrix([1:5]);
	print public.unitmatrix(5);
	m1 := array([1:6],2,3);
	m2 := array([1:12],3,4);
	v1 := [1:3];
	v2 := [1:4];
	v3 := [1:2];
	v4 := [6:8];
	print 'mx.mult(m1,m2): ',public.mult(m1,m2);
	print 'mx.mult(v,m): ',public.mult(v1,m2);
	# print 'mx.mult(v,m): ',public.mult(v2,m2); # should fail
	print 'mx.mult(m,v): ',public.mult(m1,v1);
	# print 'mx.mult(m,v): ',public.mult(m1,v2); # should fail
	# print 'mx.mult(v1,v2): ',public.mult(v1,v2); # should fail
	print 'mx.mult(v1,v2): ',public.mult(v1,v4);

	m := public.diagonalmatrix([1,3,5+2i]); 
	m[3,1] := -10;
	print public.print(m,'to be inverted');
	print public.print(minv:=public.invert(m),'inverted');
	print public.print(public.mult(m,minv),'m*minv');

	angle := 0.9;
	print 'v=',v := [2,-3];
	print 'rot by',angle,'rad:',vr := public.rotate(v,angle);
	print 'angle:',public.angle(v,vr);

	m := public.testmatrix();
	public.make_symmetric(m);
	tf := public.is_symmetric(m);
	print 'symmetric test-matrix:',tf;

	m := public.testmatrix();
	public.make_symmetric(m, hermitian=T);
	tf := public.is_hermitian(m);
	print 'hermitian test-matrix:',tf;

	m := public.testmatrix(2,3);
	mtm := public.mtm(m);
	print public.print(mtm,'(2,3) -> mtm');
	m := public.testmatrix(3,2);
	mtm := public.mtm(m);
	print public.print(mtm,'(3,2) -> mtm');

    };


#---------------------------------------------------------
    return public
};				# closing bracket of make_matrix
#=========================================================

const mx := matrix_functions();	# Make default matrix object...
# mx := matrix_functions();		# Make default matrix object...

# mx.test();				# run the test-routine
