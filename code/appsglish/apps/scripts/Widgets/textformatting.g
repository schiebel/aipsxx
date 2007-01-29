# textformatting.g: some useful text-formatting services (see textwindow.g).

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
# print 'include textformatting.g  01sep99'


#=========================================================
test_textformatting := function () {
    private := [=];
    public := [=];
    public.tf := textformatting();
    return public.tf;
};


#=========================================================
textformatting := function () {
    private := [=];
    public := [=];

    private.init := function() {
	wider private;
	return T;
    }

#=============================================================
# Public interface:
#=============================================================

    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('textformatting event:',$name,$value);
	# print s;
    }

    public.format := function (vv, pattern=F, pprec=F) {
    	return private.format (vv, pattern, pprec);
    }
    public.lineup := function (vv, nchar=F, align=F, header=F, pattern=F) {
    	return private.lineup (vv, nchar, align, header, pattern);
    }
    public.columns := function (...) {
    	return private.columns (...);
    }

    public.summary := function(v, name=F, recurse=F, show=F) {
    	return private.summary (v, name, recurse, show=show);
    }
    public.fully := function(v, name=F, pattern=F) {
    	return private.fully (v, name, pattern);
    }
    public.showrecord := function (ref rd, name='record', recurse=F) {
    	return private.showrecord (rd, name, recurse)
    }
    public.histogram := function (vv, name=F, nbins=10) {
    	return private.histogram (vv, name, nbins);
    }


#=======================================================================
#=======================================================================
# Private functions:
#=======================================================================
#=======================================================================

#-----------------------------------------------------------------------
# Format (sprintf) a vector vv of glish values with the given pattern,
# and return a string vector:

    private.format := function (vv, pattern=F, pprec=F) {
	if (len(vv)<=0) return ' ';		# empty string

	strout := ' ';
	if (is_string(pattern)) {		# conversion pattern given
	    for (i in ind(vv)) {
		strout[i] := sprintf(pattern,vv[i]);	# convert to string
	    }

	} else if (is_numeric(vv)) {
	    if (is_integer(pprec)) vv::print.precision := pprec;
	    for (i in ind(vv)) {
		strout[i] := spaste(vv[i]);	# convert to string
	    }

	} else if (is_string(vv)) {		
	    strout := vv;			# just transfer

	} else {
	    print 'format: type not recognised:',type_name(vv);
	    strout := ' ';
	}
	return strout;
    }


#-----------------------------------------------------------------------
# Line-up the given vector vv in various ways.
# Return a string vector with equal-sized elements (nr of chars)

    private.lineup := function (vv, nchar=F, align=F, header=F, pattern=F) {
	if (len(vv)<=0) return ' ';		# empty string
	str := public.format(vv, pattern);

	if (is_string(header)) {
	    cc := split(header,'');
	    cc := rep('-',len(cc));
	    if (header==' ') cc := ' ';
	    str := [' ',header,spaste(cc),str,' '];
	    iiheader := [2,3];
	} else {
	    str := [' ',str,' '];		# blank line before/after
	}
	cmax := 0;
	cc := [=];
	for (i in ind(str)) {
	    cc[i] := split(str[i],'');		# split into chars
	    cmax := max(cmax,len(cc[i]));	# max nr of chars 
	    # print i,cmax,cc[i];
	}
	cmax +:= 2;				# extra separ. char(s)
	if (is_integer(nchar)) cmax := max(cmax,nchar);	# nchar given
	if (is_boolean(align)) {
	    align := 'right';			# default
	    if (is_string(vv)) align := 'left';	# align on the left
	    if (is_double(vv)) align := '.';	# align on decimal point
	    if (is_complex(vv)) align := 'i';	# align on i sign
	    if (is_dcomplex(vv)) align := 'i';	# align on i sign
	    # print 'auto-align:',type_name(vv),align;
	}

	ncc := len(cc);
	alcode := rep('r',ncc);			# default
	if (!is_string(align)) {
	} else if (align=='left') {
	    alcode := rep('l',ncc);
	} else if (align=='right') {
	    alcode := rep('r',ncc);
	} else if (align=='centre') {
	    alcode := rep('c',ncc);
	} else if (len(align)==1) {
	    alcode := rep(align,ncc);
	    if (is_string(header)) alcode[iiheader] := 'c'; 
	    kk := []
	    found := F;
	    for (i in ind(cc)) {
		if (alcode[i]!='c') {		# exclude
		    ii := ind(cc[i])[cc[i]==align];
		    kk[i] := 1+len(cc[i]);
		    if (len(ii)>0) {
			kk[i] := ii[1];
			found := T;
		    }
		}
	    }
	    kkmax := max(kk,cmax/2-2);
	    if (!found) {			# no align chars found
		sv := [alcode==align];
		alcode[sv] := 'r';
		if (is_string(vv)) alcode[sv] := 'l';
	    }
	}

	ss := ' ';				# output vector
	k := 1;					# depends on 'align'
	for (i in ind(str)) {
	    s := rep(' ',cmax);
	    n := len(cc[i]);
	    if (alcode[i]=='l') {		# left-justified
	    	k := 1;	
	    } else if (alcode[i]=='r') {	# right-justified
	    	k := cmax-n-1;	
	    } else if (alcode[i]=='c') {	# centered
	    	k := 1+as_integer((cmax-n)/2);
	    } else {				# lined up on specified char
	        k := 1+kkmax-kk[i];
	    }	
	    s[(1+k):(n+k)] := cc[i];		# transfer chars
	    ss[i] := spaste(s);			# concatenate chars again
	    # print i,alcode[i],'n=',n,'k=',k,'   ',ss[i];
	}
	return ss;				# return string vector
    }

#-----------------------------------------------------------------------
# Make a number of side-by-side columns:

    private.columns := function (...) {
	nargs := num_args(...);
	if (nargs==0) return;
	allstring := T;
	for (i in [1:nargs]) {
	    vv := nth_arg(i,...);
	    if (!is_string(vv)) {
		allstring := F;
		break
	    }
	}
	ss := [=];
	ncol := 0;
	nrow := [];
	maxrow := 0;
	blank := ' ';
	for (i in [1:nargs]) {
	    vv := nth_arg(i,...);
	    header := spaste('col',i);
	    if (allstring) header := F;		# may be formatted already
	    s := public.lineup(vv, header=header);	#........!!!!
	    ss[ncol+:=1] := s;
	    cc := split(s[1],'');		# split into chars
	    blank[ncol] := spaste(rep(' ',len(cc)));
	    nrow[ncol] := len(s);
	    maxrow := max(maxrow,nrow[ncol]);
	}
	
	strout := '\n';
	for (i in [1:maxrow]) {
	    s := ' ';
	    for (j in [1:ncol]) {
		if (i<=nrow[j]) {
		    s := paste(s,ss[j][i]);
		} else {
		    s := paste(s,blank[j]);
		}
	    }
	    strout := paste(strout,'\n',s);
	}
	strout := paste(strout,'\n');
	return strout;
    }




#=================================================================
# Make a summary of the given glish variable:


    private.summary := function(v=F, name=F, recurse=F, show=F) {
 	if (is_string(v)) {
	    s := private.summary_string(v, name); 
 	} else if (is_numeric(v)) {
	    s := private.summary_numeric(v, name); 
 	} else if (is_function(v)) {
	    s := private.summary_function(v, name); 
 	} else if (is_record(v)) {
	    s := private.showrecord(v, name, recurse);
	    s := paste(s,'\n');
	} else {
	    s := paste('textformatting.summary: type not recognised');
	    print s := paste(s,type_name(v),'name=',name);
	    return s;
	}
	# If required, print the string line-by-line:
	if (show) for (s1 in split(s,'\n')) {print s1};
	return s;
    }

    private.summary_string := function (v, name=F, nf=20) {
	fmt := spaste(' - %-',nf,'s: ');
	s := sprintf(fmt,spaste(name));
	if ((n:=len(v))<=0) {return s := paste(s,'empty')}
	dim := shape(v);
	s := spaste(s,type_name(v),' ');
	statistics := F;
	if (n==1) {
	    cc := split(v,'');			# characters
	    nc := len(cc);			# nr of chars
	    if (nc<30) {
	    	s := spaste(s,' value= \'',v,'\'');
	    } else {
	    	s := spaste(s,' value= \'',spaste(cc[1:20]),' ... \'');
	    }
	} else if (len(dim)==1) {
	    s := spaste(s,' vector[',n,']');
	    statistics := T;
	} else {
	    s := spaste(s,' array',dim);
	    statistics := T;
	}
	return s;
    }

    private.summary_numeric := function (v, name=F, nf=20) {
	fmt := spaste(' - %-',nf,'s: ');
	s := sprintf(fmt,spaste(name));
	if ((n:=len(v))<=0) {return s := paste(s,'empty')}
	dim := shape(v);
	s := spaste(s,type_name(v));
	statistics := F;
	if (n==1) {
	    if (is_integer(v) || is_boolean(v)) {
		s := spaste(s,' value= ',v);
	    } else if (is_complex(v) || is_dcomplex(v)) {
		s := spaste(s,' value= ',v);
		# s := paste(s,sprintf('value= (%.5g i%.5g)',real(v),imag(v)));
	    } else {
		s := spaste(s,' value= ',v);
		# s := paste(s,sprintf('value= %.5g',v));
	    }
	} else if (len(dim)==1) {
	    s := spaste(s,' vector[',n,']: ');
	    if (n<=5) {
		if (is_integer(v) || is_boolean(v)) {
		    s := paste(s,v);
		} else if (is_complex(v) || is_dcomplex(v)) {
		    s := paste(s,v);
		} else {
		    for (i in [1:n]) s := paste(s,sprintf('%.5g',v[i]));
		}
	    } else {
		statistics := T;
	    }
	} else {
	    s := spaste(s,' array',dim);
	    statistics := T;
	}

	if (statistics) {
	    if (is_boolean(v)) {
		s := spaste(s,' true=',len(v[v]));
		s := spaste(s,' false=',len(v[!v]));
	    } else {
		mm[1] := min(v); 
		mm[2] := max(v);
		s := paste(s,sprintf('min=%.3g',mm[1]));
		s := paste(s,sprintf('max=%.3g',mm[2]));
		# s := spaste(s,' min=',mm[1],' max=',mm[2]);
		mm[3] := mean := sum(v)/n;
		# s := spaste(s,' mean=',mm[3]);
		s := paste(s,sprintf('mean=%.3g',mm[3]));

		if (is_complex(v) || is_dcomplex(v)) {
		    # rms not defined: do nothing.
		} else {
		    ms := (sum(v*v)/n) - (mean*mean);	# mean square
		    if (ms>=0) {
		    	mm[4] := rms := sqrt(ms);
		    	# s := spaste(s,' rms=',mm[4]);
			s := paste(s,sprintf('rms=%.3g',mm[4]));
		    } else {
		    	s := spaste(s,' rms=? (ms<0!)');
		    }
		}
	    }
	}
	return s;
    } 

    private.summary_function := function (v, name) {
	sf := as_string(v);				# convert to string
	sf := paste(split(sf,')')[1],')');
	sf := split(sf,'(');
	sarg := sf; 
	if (len(sf)>1) sarg := sf[2];
	# sarg := private.replace(sarg,'val ');		#.....useful?
	# sarg := private.replace(sarg,' = ','=');	#.....useful?
	s := paste('function',name,'(',sarg);
	return s;
    }


#=================================================================
# Fully display the given glish variable:

    private.fully := function(v, name=F, pattern=F) {
	if (is_string(v)) {
	    return private.fully_string(v, name, pattern)
	} else if (is_numeric(v)) {
	    return private.fully_numeric(v, name, pattern)
	} else if (is_function(v)) {
	    return private.fully_function(v, name)
	} else {
	    s := paste('textformatting.fully: type not recognised');
	    s := paste(s,type_name(v),'name=',name);
	    print s;
	    return s;
	}
    }


    private.fully_function := function(v, name='function') {
	ss := private.summary_function(v,name);
	ff := as_string(v);                     # convert to string
	ff := split(ff,';');                    # split on semi-colons
	for (s in ff) {
	    ss := paste(ss,'\n',s);	        # statement-by-statement
	}
	return ss;				# return string-vector
    }

    private.fully_file := function(v, name='file') {
	ss := name;				# temporary
	return ss;				# return string-vector
    }

    private.fully_string := function(v, name='string', pattern=F) {
	ss := private.summary_string(v,name);
	if ((n:=len(v))<=1) return ss; 
	dim := shape(v);
	if (len(dim)==1) {
	    return ss := paste(ss,private.fully_stringvector(v, pattern))
	} else if (len(dim)==2) {
	    return ss := paste(ss,private.fully_stringmatrix(v, pattern))
	} else {
	    return ss := paste(ss,private.fully_ndim(v, pattern))
	}
	return ss;				# return string-vector
    }

    private.fully_numeric := function(v, name='value', pattern=F) {
	ss := private.summary_numeric(v,name);
	if ((n:=len(v))<=1) return ss; 
	dim := shape(v);
	if (n>(nmax:=10000)) {
	    ss := paste('There are more than',nmax,'elements!')
	    ss := paste(ss,'\n Think of another way to visualise them')
	    return ss;
	}
	if (len(dim)==1) {
	    return ss := paste(ss,private.fully_vector(v, pattern))
	} else if (len(dim)==2) {
	    return ss := paste(ss,private.fully_matrix(v, pattern))
	} else {
	    return ss := paste(ss,private.fully_ndim(v, pattern))
	}
	return ss;				# return string-vector
    }

    private.fully_vector := function(v, pattern=F) {
	n := len(v);
	if (n<20) {
	    ss := paste(v);
	} else {
	    ncol := 10;				# nr of columns
	    nrow := 1+as_integer((n-1)/ncol);	# nr of rows
	    nrem := n%ncol;			# remainder
	    vv := array(0,nrow,ncol);
	    k := 0;
	    for (i in [1:nrow]) {
		for (j in [1:ncol]) {
		    if ((k+:=1)<=n) vv[i,j] := v[k];
		}
	    }
	    ss := paste(vv);
	    sv := spaste('Vector[',n,']');
	    sa := spaste('array[',nrow,',',ncol,']');
	    ss := paste(ss,'\n\n NB:',sv,'has been displayed as',sa);
	    if (nrem>0) {
		ss := paste(ss,'\n     Ignore the last',ncol-nrem,'elements');
	    }
	}
	return paste('\n',ss);
    }
    private.fully_stringvector := function(v, pattern=F) {
	ss := ' ';
	for (s in v) {
	    ss := paste(ss,' \n',s);
	}
	return paste('\n',ss);
    }
    private.fully_matrix := function(v, pattern=F) {
	ss := paste(v);
	return paste('\n',ss);
    }
    private.fully_stringmatrix := function(v, pattern=F) {
	ss := ' ';
	n := shape(v)[1];
	for (i in [1:n]) {
	    ss := paste(ss,' \n',v[i,]);
	}
	return paste('\n',ss);
    }
    private.fully_ndim := function(v, pattern=F) {
	ss := paste(v);
	return paste('\n',ss);
    }


#----------------------------------------------------------
# Print the contents (summary) of a Glish record in an organised way.

    private.showrecord := function (ref rd, name='record', recurse=F) {
	ast := '';
	level := 1;
	if (level>1) ast := rep('**',level-1);
	s := spaste('\n ',ast,' Contents of Glish record: ',name,':');

	ast := rep('**',level);	
	if (!is_record(rd)) {
	    s := paste(s,'\n not a record, but:',type_name(rd));
	    if (level==1) s := paste(s,'\n');
	    return s;
	};

	fn := field_names(rd);
	nfields := len(fn);		# NB: do not use len(rd)!
	if (nfields <= 0) {
	    s := paste(s,' \n [=] (empty)');
	    if (level==1) s := paste(s,'\n');
	    return s;
	}	

	iif := [];
	iia := [];
	iin := [];
	iib := [];
	iir := [];
	iis := [];
	iifail := [];
	n1 := 0;
	for (i in [1:nfields]) {
	    if (is_function(rd[i])) {
		iif:=[iif,i];
	    } else if (is_agent(rd[i])) {   # NB: before record!
		iia:=[iia,i];
	    } else if (is_record(rd[i])) {
		iir:=[iir,i];
	    } else if (is_boolean(rd[i])) {
		iib:=[iib,i];
	    } else if (is_numeric(rd[i])) {
		iin:=[iin,i];
	    } else if (is_string(rd[i])) {
		iis:=[iis,i];
	    } else if (is_fail(rd[i])) {
		iis:=[iifail,i];
	    } else {
		n1 +:= 1;
	        s := paste(s,'\n ',ast,' unaccounted field(?): ',
				fn[i],type_name(rd[i]));
	    }
	}

	for (i in iia) {
	    s1 := spaste(name,'.',fn[i]);
	    s := paste(s,'\n',ast,s1,' ',rd[i]);
	}
	for (i in iif) {
	    s1 := spaste(name,'.',fn[i])
	    s := paste(s,'\n',ast,private.summary_function(rd[i],s1))
	}
	for (i in iifail) {
	    s1 := spaste(name,'.',fn[i]);
	    s := spaste(s,'\n ',ast,' fail(!): ',fn[i],' ',rd[i]);
	}
	if (len(iib)>0) s := paste(s,'\n \n',ast,'  boolean fields:');
	for (i in iib) {
	    s1 := spaste(name,'.',fn[i])
	    s := paste(s,'\n',ast,private.summary_numeric(rd[i],s1))
	}
	if (len(iin)>0) s := paste(s,'\n \n',ast,'  numeric fields:');
	for (i in iin) {
	    s1 := spaste(name,'.',fn[i])
	    s := paste(s,'\n',ast,private.summary_numeric(rd[i],s1))
	}
	if (len(iis)>0) s := paste(s,'\n \n',ast,'  string fields:');
	for (i in iis) {
	    s1 := spaste(name,'.',fn[i])
	    s := paste(s,'\n',ast,private.summary_string(rd[i],s1))
	}

	if (len(iir)>0) s := paste(s,'\n \n',ast,' (sub-)record fields:');
	for (i in iir) {
	    s1 := spaste(name,'.',fn[i]);
	    if (recurse) {
		s := paste(s,'\n',private.showrecord(rd[i],s1,recurse));
	    } else {
	    	s := spaste(s,'\n ',ast,' record: ',s1);
	    }
	}
	if (level==1) s := paste(s,'\n');
	return s;
    }


#---------------------------------------------------------
# Make a histogram:

    private.histogram := function (vv, name=F, nbins=10) {
	vmin := min(vv);			# minimum value
	vmax := max(vv);			# maximum value
	nbins := max(1,nbins);			# just in case

	if (is_integer(vv)) {
	    nbins := min(nbins,vmax-vmin+1);
	    binwidth := 1+as_integer((vmax-vmin)/nbins);# bin-width
	    bev := (vmin-0.5) + [0:nbins]*binwidth;	# bin-edge values
	} else {
	    binwidth := (vmax-vmin)/nbins;	# bin-width
	    bev := vmin + [0:nbins]*binwidth;	# bin-edge values
	}

	bw2 := binwidth/2;			#
	npb := [];				# nr per bin
	nacc := [];				# accumulated bins
	vcbin := [];				# value at bin centre		
	npbmax := 0;				# max nr per bin 
	for (i in [1:nbins]) {
	    if (i==1) {
	        sv := [vv>=bev[i]] & [vv<=bev[i+1]];
	    } else {
	        sv := [vv>bev[i]] & [vv<=bev[i+1]];
	    }
	    vcbin[i] := bev[i]+bw2;
	    npb[i] := len(sv[sv]);		
	    nacc[i] := npb[i];
	    if (i>1) nacc[i] +:= nacc[i-1];
	    npbmax := max(npbmax,npb[i]);	    
	}

	svcbin := ' ';
	snpb := ' ';
	snacc := ' ';
	shist := ' ';
	nsmax := 20;
	for (i in [1:nbins]) {
	    svcbin[i] := spaste(vcbin[i]);
	    snpb[i] := spaste(npb[i]);
	    snacc[i] := spaste(nacc[i]);
	    if (npbmax<=nsmax) {
		ns := npb[i];
	    } else {
		ns := 1+as_integer(nsmax*((npb[i]-1)/npbmax));
	    } 
	    shist[i] := spaste('|',spaste(rep('*',ns)));
	    # print i,svcbin[i],ns,shist[i],snpb[i],snacc[i];
	}
	svcbin := public.lineup(vcbin, align='.', header='vbin')
	shist := public.lineup(shist, align='left', 
			header=spaste('histogram (',nbins,' bins)'))
	snpb := public.lineup(npb, align='right', header='nbin')
	snacc := public.lineup(nacc, align='right', header='nacc')

	s := public.columns(svcbin,shist,snpb,snacc);
	s := paste(s,'\n histogram of:',name);
	s := paste(s,'\n  nr of bins=',nbins,', bin-width=',binwidth);
	s := paste(s,'\n');
	return s;
    }

#=======================================================================
# Helper function to replace all occurrences of a substring in string
# with another substring (with nothing if substr2=F).  

# alternative: ss := split(str,substr1) and paste(ss,sep=substr2)
# NB: still provide the service of dealing with string vectors

    public.replace := function(str, substr1, substr2=F) {
    	return private.replace (str, substr1, substr2);
    }

    private.replace := function(str, substr1, substr2=F) {
	if ((nstr:=len(str))<=0) return str;	# no input string
	ss1 := split(substr1,'');		# split into chars
	if ((nss1:=len(ss1))<=0) return str;	# no chars

	for (k in [1:nstr]) {
	    s := split(str[k],'');		# split into chars
	    if ((ns:=len(s))<=0) return str;	# no chars
	    i := 0;
	    while ((i+:=1)<(ns-nss1)) {
		if (s[i]==ss1[1]) {		# 1st chars match
		    match := T;
		    for (j in [2:nss1]) {
			if (s[i+j-1]!=ss1[j]) {
			    match := F;
			    break;
			}
		    }
		    if (match) {
			s1 := ' ';
			if (i>1) s1 := s[1:(i-1)];
			s2 := s[(i+j):ns];
			if (is_string(substr2)) {
			    s := [s1,substr2,s2];
			} else {
			    s := [s1,s2];
			}
			ns := len(s);		# adjust lenght
		    }
		}
	    }
	    str[k] := spaste(s);		# paste chars
	}
	return str;
    }


#=========================================================
# Finished. Initialise and return the public interface:

    public.private := function() {	# 
	return ref private;
    }

    private.init();
    return ref public;

};				# closing bracket of textformatting
#=========================================================

twf := test_textformatting();		# run test-routine




