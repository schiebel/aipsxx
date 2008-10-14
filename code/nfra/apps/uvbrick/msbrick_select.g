# msbrick_select.g: Parameter selection support for msbrick.g 
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
# $Id: msbrick_select.g,v 19.0 2003/07/16 03:38:52 aips2adm Exp $

#---------------------------------------------------------


pragma include once
# print 'include msbrick_select.g  w01sep99'

# include 'tracelogger.g';
include 'textformatting.g'
include 'jenmath.g'

#=========================================================
test_msbrick_select := function () {
    msbs := msbrick_select();
    return ref msbs;
};

#=========================================================
msbrick_select := function (context='WSRT') {
    private := [=];
    public := [=];

    private.context := context;			# input argument

    private.init := function() {
	wider private;
	private.trace := F;			# tracelogger
	private.tf := textformatting();		# text-formatting functions
	private.jenmath := jenmath();           # math functions
	return T;
    }


#=========================================================
# Public interface:

    public.agent := create_agent();	# communication

    public.private := function(copy=F) {	# access to private part
	if (copy) return private;		# return a copy
	return ref private;			# return a reference
    }



#------------------------------------------------------------------------
# Spectral-window selection: 

    public.choice_spwins := function (iirange, icurr=F) {
	rr := [=];				# .paramshape... := 'vector'!
	n := 0;
	if (is_integer(icurr)) rr[n+:=1] := icurr;	# current one
	for (i in iirange) {
	    rr[n+:=1] := i;				# individual ones
	}
	if (len(iirange)>1) rr[n+:=1] := iirange;	# all available 
	return rr;					# return record!
    }

#------------------------------------------------------------------------
# Array selection: 

    public.choice_arrays := function (iirange, icurr=F) {
	return public.choice_spwins (iirange, icurr=F);
    }

#------------------------------------------------------------------------
# Field-selection:

    public.choice_fields := function (names, field_ids) {
	rr := [=];				# .paramshape... := 'vector'!
	n := 0;
	if (len(names)>1) rr[n+:=1] := '*';		# all available 
	for (i in ind(field_ids)) {
	    rr[n+:=1] := names[i];			# use the names!
	}
	return rr;					# return record!
    }

    public.help_fields := function (names, field_ids, radec) {
	s := 'available fields:'
	for (i in ind(field_ids)) {
	    s := paste(s,'\n - id=',field_ids[i])
	    s := paste(s,'  ',names[i]);
	    s := paste(s,'  RA=',radec[1,i]);
	    s := paste(s,'  DEC=',radec[2,i]);
	}
	return s;
    }

    public.decode_fields := function(fields, names, field_ids, test=F) {
	s := paste('selected field(s)',fields);
	s := paste(s,'\n available:',names);
	s := paste(s,'with field_ids:',field_ids);
	rr := [=];
	rr.subset := [];
	if (fields=='*') {
	    rr.subset := field_ids;			# all available ids
	} else if (is_string(fields)) {
	    for (field in fields) {
		if (any(names==field)) {
		    n := 1 + len(rr.subset);		# increment
		    rr.subset[n] := ind(names)[names==field];
		    s := paste(s,'\n -',n,field,'->',rr.subset[n]);
		} else {
		    s := paste(s,'\n - field not recognised:',field);
		}
	    }
	} else if (is_integer(fields)) {
	    rr.subset := fields;			# already field-ids
	} else {
	    s := paste(s,'fields: not recognised:',type_name(fields),fields);
	    print s;
	    fail(s);
	}
	return public.decode_out (rr, field_ids, test=test, stest=s);
    }
 


#------------------------------------------------------------------------
# Corr selection:

    public.choice_corrs := function (cc, ms=F, tel_name='WSRT') {
	ss := '*';				# all available corrs
	ss := [ss,paste(cc)];			# all available corrs
	if (len(cc)==2) {			# only 2 corrs available
	    ss := [ss,cc[1],cc[2]];
	    if (ms) {				# only if MS
		if (tel_name=='WSRT') {
	    	    ss := [ss,'I Q',"I Q"];
		} else {
	    	    ss := [ss,'I V',"I V"];
		}
	    }
	} else if (len(cc)==4) {		# all 4 corrs available
	    ss := [ss,paste(cc[[1,4]]),paste(cc[[2,3]])];
	    ss := [ss,cc[1],cc[2],cc[3],cc[4]];
	    if (ms) {				# only if MS
		ss := [ss,'I Q U V','Q U','I V','U V',"I Q U V"];
	    }
	}
	rr := [=];				# .paramshape... := 'vector'!
	for (i in ind(ss)) {
	    rr[i] := split(ss[i]);		# string vectors
	    # print i,ss[i],'->',rr[i],'len=',len(rr[i]);
	}
	# print 'choice_corrs: rr=',rr;
	return rr;				# return record!
    }

    public.decode_corrs := function(corrs, corr_names, corr_types, test=F) {
	s := paste('selected corr(s)',corrs);
	s := paste(s,'\n available:',corr_names);
	s := paste(s,'with corr_types:',corr_types);
	if (corrs=='*') corrs := corr_names;	# all available
	rr := [=];
	rr.subset := corrs;
	return public.decode_out (rr, corr_names, test=test, stest=s);
    }
 
#------------------------------------------------------------------------
# Pol selection X,Y,R,L (receptor):

    public.choice_pols := function (cc, ms=F, tel_name='WSRT') {
	ss := '*';				# all available pols
	ss := [ss,paste(cc)];			# all available pols
	for (i in ind(cc)) {
	    ss := [ss,cc[i]];                   # individual pol
	}
	rr := [=];				# .paramshape... := 'vector'!
	for (i in ind(ss)) {
	    rr[i] := split(ss[i]);		# string vectors
	    # print i,ss[i],'->',rr[i],'len=',len(rr[i]);
	}
	# print 'choice_pols: rr=',rr;
	return rr;				# return record!
    }

    public.decode_pols := function(pols, pol_names, pol_codes, test=F) {
	s := paste('selected pol(s)',pols);
	s := paste(s,'\n available:',pol_names);
	s := paste(s,'with pol_codes:',pol_codes);
	if (pols=='*') pols := pol_names;	# all available
	rr := [=];
	rr.subset := pols;
	return public.decode_out (rr, pol_names, test=test, stest=s);
    }
 

#------------------------------------------------------------------------
# Time-selection:

    public.help_times := function(MJDtimes) {
	s := paste('\n');
	s := paste(s,'\n the nr of available time-slots is:',len(MJDtimes));
	s := paste(s,'\n the overall time-span is:');
	s := paste(s,(MJDtimes[len(MJDtimes)]-MJDtimes[1])/3600.0,'hrs');
    	s := paste(s,public.help_cs('time-slot',len(MJDtimes)));
	return s;
    }


#------------------------------------------------------------------------
# Freq selection: 

    public.help_fchs := function(chan_freq) {
	s := paste('\n');
	s := paste(s,'\n the nr of available channels is:',len(chan_freq));
	s := paste(s,'\n the freq range is:',chan_freq[1]*1e-6);
	s := paste(s,'<->',chan_freq[len(chan_freq)]*1e-6,'MHz');
    	s := paste(s,public.help_cs('channel',len(chan_freq)));
	return s;
    }


#------------------------------------------------------------------------
# Common functions (cs) for freq-channels (c) and time-slots (s):

# Give a choice (record of vectors) for time/freq specification:

    public.choice_cs := function (cs, default=F) {
	ncs := len(cs);					# nr of chs/slots
	ncs2 := max(1,as_integer(ncs/2));
	nav := min(9,ncs2);
	first := min(5,ncs2);
	last := max(1,ncs-first+1);
	rr := [=]; 
	nrr := 0;
	if (!is_boolean(default)) rr[nrr+:=1] := default;	#...(?)	
	rr[nrr+:=1] := '*';				# string, all
	rr[nrr+:=1] := [ncs,1,1,1];			# integer, all
	rr[nrr+:=1] := [ncs-1,2,1,1];			# except first
	if (ncs>1) {
	    rr[nrr+:=1] := spaste('average');		# string, all
	    rr[nrr+:=1] := spaste('last');		# last one
	    rr[nrr+:=1] := spaste('mid/',nav);		# middle ones, averaged
	    rr[nrr+:=1] := spaste('mid/0.75');          # fractional
	    rr[nrr+:=1] := spaste(first,':',last);	# range
	    rr[nrr+:=1] := spaste(first,':',last,'/',nav); # range, averaged
	    rr[nrr+:=1] := spaste('0.75');              # fractional
	    rr[nrr+:=1] := spaste('0.75/2');            # fractional
	}
	rr[nrr+:=1] := [1,1,ncs,ncs];			# all averaged
	for (q in [0.75]) {				# excluding band-edge
	    first := as_integer(0.5*(1-q)*ncs);
	    last := as_integer(0.5*(1+q)*ncs);
	    nav := as_integer(q*ncs);
	    rr[nrr+:=1] := [last-first+1,first,1,1];	# edges removed
	    rr[nrr+:=1] := [1,first,nav,nav];		# and averaged too
	} 
	for (k in [2,3,5]) {
	    if (ncs<(k*3)) next;			# too few chs/slots
	    first := max(1,as_integer((ncs%k)*0.5));
	    nout := as_integer(ncs/k);
	    rr[nrr+:=1] := [nout,first,k,k];		# average over k
	}
	return rr;
    }

# Generic part of time/freq help-string:

    public.help_cs := function(cstr='channel',ncs=-1) {
	cstrs := spaste(cstr,'s');			# plural
	s := paste(cstr,'selection syntax:')
	s := paste(s,'\n Selection is by means of a vector or 4 numbers:');
	s := paste(s,'\n     [nout, first, nav, ninc]');
	s := paste(s,'\n in which:');
	s := paste(s,'\n     nout  = the number of OUTPUT',cstrs);
	s := paste(s,'\n     first = the',cstr,'where the selection loop starts');
	s := paste(s,'\n     nav   = the number of',cstrs,'to be averaged over');
	s := paste(s,'\n     ninc  = the increment in the selection loop');
	s := paste(s,'\n ');
	s := paste(s,'\n',sprintf('%-15s',spaste([ncs,1,1,1])),paste('all',cstrs));
	if (ncs>(2*(k:=3))) {
	    s := paste(s,'\n',sprintf('%-15s',spaste([ncs-2*k,k+1,1,1])),
		paste('exclude the outer',k,cstrs));
	}
	s := paste(s,'\n',sprintf('%-15s',spaste([1,1,ncs,ncs])),
		paste('all',cstrs,'averaged into one'));
	nav := 3;
	nout := as_integer(ncs/3);
	s := paste(s,'\n',sprintf('%-15s',spaste([nout,1,nav,nav])),
		paste('averaged over groups of',nav,cstrs));
	s := paste(s,'\n',sprintf('%-15s',spaste([ncs-nav+1,1,nav,1])),
		paste('the same, but with a sliding window'));
	s := paste(s,'\n',sprintf('%-15s',spaste('*')),paste('all',cstrs));
	s := paste(s,'\n');
	return paste('\n',s);
    }

# Decode the given (time/freq) specification (can be string or integer).

    public.decode_cs := function (spec, cs, test=F, trace=F) {
	ncs := len(cs);					# nr of chs/slots
	stest := spaste('selection spec= ',spec,' (',type_name(spec),')');
	stest := paste(stest,'\n nr of available channels/timeslots=',ncs);
	if (trace) print 'decode_cs():',stest;
	rr := [=];
	rr.intspec := [ncs,1,1,1];			# default

	if (is_string(spec)) {
	    nout := 1;
	    first := 1;
	    nav := 1;
	    ninc := 1;

	    # Check for averaging specification (/nav):
	    ss := split(spec,'/');			# split on slash(/)
	    if (len(ss)>1) {			        # contained slash
		frac := as_double(ss[2]);               
		if (ss[2]=='*') {                       # all
		    nav := ncs;
		} else if (frac>0 && frac<1) {          # fraction of range
		    nav := as_integer(ncs*frac);
		} else {
		    nav := as_integer(ss[2]);           # nr of chs/slots
		}
		nav := max(1,nav);                      # zero if error!
		nav := min(ncs,nav);
		ninc := nav;                            # non-overlapping...?
		spec := ss[1];                          # drop '/nav' part
	    }

	    ss := split(spec,':');			# split on colon(:)
	    frac := as_double(spec);                    # fraction of range
	    if (len(ss)>1) {			        # range specification
		first := max(1,as_integer(ss[1]));      # assume integer>0
		first := min(first,ncs);	     
		last := as_integer(ss[2]);              # assume integer>0
		if (last<=0) last := ncs;               # assume open-ended
		last := min(last,ncs);
		nout := last-first+1;
		ninc := nav := min(nout,nav);           # .....?
		nout := max(1,as_integer(nout/nav));
		rr.intspec := [nout,first,nav,ninc];	# 

	    } else if (frac>0 && frac<1) {              # fraction of range
		nout := max(1,as_integer(ncs*frac));
		first := max(1,as_integer((ncs-nout+1)/2));    
		first := min(first,ncs-nav+1);
		ninc := nav := min(nout,nav);           # .....?
		nout := max(1,as_integer(nout/nav));
		rr.intspec := [nout,first,nav,ninc];	# 

	    } else if (as_integer(spec)>0) {	        # specific one
		first := as_integer(spec) - as_integer(nav/2);
		first := min(first,ncs-nav+1);
		rr.intspec := [1,first,nav,1];	        # 

	    } else if (as_integer(ss)>0) {	        # open-ended range
		first := as_integer(spec) - as_integer(nav/2);
		first := min(first,ncs-nav+1);
		nout := ncs-first+1;
		nout := max(1,as_integer(nout/nav));
		rr.intspec := [nout,first,nav,ninc];	# 

	    } else if (spec=='*') {			# all, 
		nout := max(1,as_integer(ncs/nav));
		rr.intspec := [nout,1,nav,ninc];	# 
	    } else if (spec=='average' || spec=='mean') { # all averaged
		rr.intspec := [1,1,ncs,1];		# 
	    } else if (spec=='first') {                 # first one
		rr.intspec := [1,1,nav,1];		# 
	    } else if (spec=='last') {                  # last one
		rr.intspec := [1,ncs-nav+1,nav,1];	# 
	    } else if (spec=='mid') {                   # middle one
		first := max(1,as_integer((ncs-nav+1)/2));    
		rr.intspec := [1,first,nav,1];		# 		
	    } else {
	    	stest := paste(stest,'\n not recognised:',spec);
		return public.decode_out (rr, cs, test=test, stest=stest);
	    }


	} else if (is_integer(spec)) {
	    if (len(spec)==4) {				# OK, 4 integers
		for (i in ind(spec)) spec[i] := max(1,min(ncs,spec[i]));
		rr.intspec := spec;
	    } else {
	    	stest := paste(stest,'\n 4 numbers required:',spec);
		return public.decode_out (rr, cs, test=test, stest=stest);
	    }
	} else if (is_double(spec)) {
	    spec := abs(spec[1]);			# one only...?

	} else {
	    stest := paste(stest,'\n not recognised:',type_name(spec),spec);
	    return public.decode_out (rr, cs, test=test, stest=stest);
	}
	return public.decode_out (rr, cs, test=test, stest=stest);
    }

# Helper function, to determine  of channels/slots to be averaged over:

    private.decode_nav := function (spec, ncs) {
	ncs := max(ncs,1);				# safety
	if (is_string(spec)) {
	    spec := split(spec,'/');			# look for /
	    if (len(spec)<2) return nav := 1;		# no / found
	    if (spec[2]=='*') return nav := ncs;	# all 
	    spec := as_double(spec);			# convert
	} else if (!is_numeric(spec)) {
	    print '*** warning: not recognised: spec=',type_name(spec),spec;
	    return nav := 1;
	}

	return nav;
    }

    private.parse_cs := function (spec, ncs) {
	ntot := ncs;
	istart := 1;
	nav := 1;
	ninc := 1;
	nums := '0123456789.';
	cc := split(spec,'');			# split into chars
	ncc := len(cc);
	if (ncc<=0) return [ncs,1,1,1];
	for (k in [1:ncc]) {
	    c := cc[k];
	    if (c=='/') {			# 
		v := as_double(spaste(cc[(k+1):ncc]));
		if (v<=0) {
		    # error?
		} else if (v<1) {		# range
		} else if (v<1) {		# range
		} else {
		}
	    } else if (c=='|') {
	    } else {
	    }
	}
    }

# Helper function to find a number (<=ncs) in the given string (str):

    public.number_cs := function (str, after=F, before=F, ncs=1) {
	ncs := max(1,ncs);			# safety
	if (is_string(after)) {	
	    cc := split(str,'');		# split into chars
	    if (!any(cc==after)) return 0;	# not found
	    ss := split(str,after);		# split on string <after>
	    str := ss[1];			# 
	    if (len(ss)>1) str := ss[2];	# the part after 'after' 
	    if (cc[1]==after) str := ss[1];	# 
	}
	if (is_string(before)) {
	    cc := split(str,'');		# split into chars
	    if (cc[1]==before) return 0;	# no room
	    ss := split(str,before);		# split on string <before>
	    str := ss[1];			# 
	}
	v := as_double(str);			# convert numeric ones
	if (v<0) {
	    # error?
	} else if (v==0) {			# not numeric
	    cc := split(str,'');		# split into chars
	    ncc := len(cc);
	    if (cc[1]=='*') return ncs;		# all
	    if (ncc>=5 && cc[1:5]=='first') return 1;
	    if (ncc>=4 && cc[1:4]=='last') return ncs;
	    if (ncc>=3 && cc[1:3]=='mid') return max(1,as_integer(ncs/2));
	} else if (v<1) {
	    return min(ceiling(v*ncs),ncs);	# fraction of ncs
	} else {
	    return min(as_integer(v),ncs);	# number <= ncs
	}
	return 0;				# not recognised
    }

#---------------------------------------------------------------------------
# Helper function to make the output record for decode-functions:
# NB: Assume that rr is a record, which already has a field 'rr.subset'.

    public.decode_out := function (rr, input, test=F, stest='test') {
	# print '**decode_out: test=',test,stest;
	if (!is_record(rr)) {
	    s := 'decode_out: rr is not a record'
	    print s;
	    fail(s);
	}

	ninput := len(input);				# nr of available
	selrec := [=];					# output record
	selrec.nout := F;				# total nr out
	selrec.first := F;				# loop start item
	selrec.nav := F;				# nr to be averaged
	selrec.ninc := F;				# loop step size
	selrec.copyall := F;				# if T, copy all
	selrec.average := F;				# if T, do average
	selrec.avwgt := F;		# averaging weights. default: uniform

	if (has_field(rr,'intspec')) {			# integer specs
	    # print '**decode_out: intspec=',rr.intspec;
	    selrec.nout := rr.intspec[1];			# total nr out
	    selrec.first := rr.intspec[2];			# loop start item
	    selrec.nav := rr.intspec[3];			# nr to be averaged
	    selrec.ninc := rr.intspec[4];			# loop step size
	    if (selrec.nout==len(input)) selrec.copyall := T;	# copy all items
	    if (selrec.nav>1) selrec.average := T;		# do average
	    selrec.selvec := rep(F,ninput);			# selection vector
	    k1 := selrec.first - selrec.ninc;	
	    k2 := 0;
	    while ((k1+:=selrec.ninc)<=ninput && (k2+:=1)<=selrec.nout) {
	    	ii := [k1:min(ninput,k1+selrec.nav-1)];
		selrec.selvec[ii] := T;				# selected
	    }

	} else if (has_field(rr,'selvec')) {		# explicit selvec given
	    # print '**decode_out: explicit selvec given',len(rr.selvec),len(input);
	    selrec.selvec := rr.selvec;			# just copy it

	} else {					# make selvec if necessary
	    # print '**decode_out: make selvec from subset and input';
	    if (!has_field(rr,'subset')) {
	    	s := 'decode_out: rr does not have field subset'
	    	print s;
	    	fail(s);
	    }  
	    selrec.selvec := [F];			# selection vector
	    for (i in ind(input)) {			# is 'input' length
	    	selrec.selvec[i] := any(input[i]==rr.subset);
	    }
	    if (all(selrec.selvec)) selrec.copyall := T;	# copy all items
	}
	selrec.subset := input[selrec.selvec];		# selected subset of input values

	if (!test) {					# normal mode
	    return selrec;				# return record

	} else {					# test-mode -> string
	    s := paste(stest,'\n\n');
	    if (T) {
	    	s := paste(s,'\n selection loop parameters:')
		s := paste(s,'\n  - nout= ',selrec.nout,'copyall=',selrec.copyall)
		s := paste(s,'\n  - first=',selrec.first)
		s := paste(s,'\n  - nav=  ',selrec.nav,'average=',selrec.average)
		s := paste(s,'\n  - ninc= ',selrec.ninc)
	    	nT := len(selrec.selvec[selrec.selvec]);
	    	s := paste(s,'\n selection vector: nTrue=',nT)
		s := paste(s,'out of',len(selrec.selvec));
	    	if (nT==0) s := paste(s,'\n    the selected subset is empty.....!');
	    }

	    nss := len(selrec.subset);
	    s := paste(s,'\n\n selected subset:',nss,'out of',len(input));
	    if (nss==0) {
	    	s := paste(s,'\n    the selected subset is empty.....!');
	    } else {
	    	s := paste(s,'\n    value(s)=',selrec.subset[1:min(5,nss)]);
		if (nss>5) s := paste(s,'...')
	    }

	    s := paste(s,'\n\n selrec fields:') 
	    for (fname in field_names(rr)) {
		if (any("subset selvec"==fname)) {
		    s := spaste(s,'\n  - selrec.',fname,': ');
		    s := paste(s,type_name(rr[fname]),shape(rr[fname])); 
		} else {
		    s := spaste(s,'\n  - selrec.',fname,'= ',rr[fname]); 
		}
	    }
	    # print s;
	    return s;					# return string (test=T)
	}
    }

#------------------------------------------------------------------------
# Telescope parameters:

    public.choice_Tsys := function (fMHz=1412, tel_name='WSRT') {
	vv := [100];
	if (is_boolean(fMHz) || !is_numeric(fMHz)) {
	    return F;
	} else if (fMHz<200) {
	    vv[1] := 100;             # non-existing
	} else if (fMHz<450) {
	    vv[1] := 170;             # UHF low
	} else if (fMHz<700) {
	    vv[1] := 75;              # 50cm
	} else if (fMHz<1200) {
	    vv[1] := 120;             # UHF high
	} else if (fMHz<1800) {
	    vv[1] := 27;              # 21 cm
	} else if (fMHz<2500) {
	    vv[1] := 60;              # 13 cm
	} else if (fMHz<6000) {
	    vv[1] := 60;              # 6 cm
	} else {
	    vv[1] := 125;             # 3.6 cm
	}
	return vv;
    }


    public.help_Tsys := function (fMHz=1412, tel_name='WSRT') {
	s := paste('Nominal IF system temperarure (Tr+Tsky+Tant)');
	s := paste(s,'\n of telescope:',tel_name);    
	s := paste(s,'\n at an observing frequency of:',fMHz,'MHz');    
	return s;
    }
    public.help_aperteff := function (fMHz=1412, tel_name='WSRT') {
	s := paste('individual aperture efficiency of an antenna');
	s := paste(s,'\n of telescope:',tel_name);    
	s := paste(s,'\n at an observing frequency of:',fMHz,'MHz');    
	return s;
    }

    public.choice_aperteff := function (fMHz=1412, tel_name='WSRT') {
	vv := [0.0,0.40,0.48,0.54,0.59];
	if (is_boolean(fMHz) || !is_numeric(fMHz)) {
	    return F;
	} else if (fMHz<1200) {
	    vv[1] := 0.59;            # >50 cm
	} else if (fMHz<2500) {
	    vv[1] := 0.54;            # 18/21 cm
	} else if (fMHz<6000) {
	    vv[1] := 0.48;            # 6cm
	} else {
	    vv[1] := 0.35;            # 3.6 cm
	}
	return vv;
    }

#------------------------------------------------------------------------
# Calibrator fluxes:

    public.choice_calibrator := function () {
	rout := [=]; 
	n := 0;
	rout[n+:=1] := [1.0,0.0,0.0,0.0];     # first always...?
	rout[n+:=1] := [1.0,0.0,0.1,0.0];
	rout[n+:=1] := [1.0,0.1,0.0,0.0];
	rout[n+:=1] := '3C48';
	# rout[n+:=1] := '3C84';
	rout[n+:=1] := '3C123';
	rout[n+:=1] := '3C147';
	rout[n+:=1] := '3C196';
	rout[n+:=1] := '3C286';
	rout[n+:=1] := '3C295';
	# print 'choice_calibrator:',type_name(rout),len(rout);
	return rout;
    }

    public.help_calibrator := function () {
	s := 'The calibrator source is assumed to be a central point source.';
	s := paste(s,'\n Give the Stokes flux parameters I,Q,U,V (Jy).')
	s := paste(s,'\n Or select one of the standard calibrator sources.');
	s := paste(s,'\n NB: The fluxes of the latter depend on observing freq.')
	return s;
    }

    public.test_calibrator := function (cal, fMHz=1412) {
	s := 'Calibrator flux (Jy) for the 4 Stokes parameters';
	s := paste(s,'\n (for an observing frequency of',fMHz,'MHz):');
	iquv := public.decode_calibrator (cal, fMHz);
	s := paste (s,'\n   I=',iquv[1],'Jy ');
	s := paste (s,'\n   Q=',iquv[2],'Jy =',100*iquv[2]/iquv[1],'%');
	s := paste (s,'\n   U=',iquv[3],'Jy =',100*iquv[3]/iquv[1],'%');
	s := paste (s,'\n   V=',iquv[4],'Jy =',100*iquv[4]/iquv[1],'%');
	return s;
    }


    public.decode_calibrator := function (cal, ref fMHz=1412) {
	iquv := F;		         
	if (is_boolean(cal)) {
	    # should not happen
	} else if (is_numeric(cal)) {                   # assume [I,Q,U,V];
	    iquv := cal;                                # just copy
	} else if (any(cal=="3C48 3C147 3C286 3C295")) { 
	    rr := public.iquv_calibrator (cal);         # get poly
	    if (is_record(rr)) {
		iquv := rep(0.0,4);
		for (i in [1:4]) {            # evaluate for given fMHz
		    if (rr.do_eval[i]) {
			private.jenmath.polyfitter().eval(iquv[i], fMHz, 
							  rr.coeff[i]);
			print cal,fMHz,'MHz: evaluated iquv(',i,')=',iquv[i];
		    }
		}
	    }
	} else if (cal=='3C84') {
	    print '** warning: flux of 3C84 not known, used a guess..'
	    	iquv := [20.0,0.0,0.0,0.0];
	} else if (cal=='3C123' || cal=='DR21') {
	    iquv := [8.16,0.0,0.0,0.0];			# @1425.0 MHz
	    if (fMHz>2000) iquv := [19.5,0.0,0.0,0.0];	# @4866.0 MHz
	} else if (cal=='NGC7027') {
	    iquv := [1.39,0.0,0.0,0.0];			# @1425.0 MHz
	    if (fMHz>2000) iquv := [5.53,0.0,0.0,0.0];	# @4866.0 MHz
	} else if (cal=='3C196') {
	    iquv := [49.0,0.0,0.0,0.0];			# @327.0 MHz
	    if (fMHz>1200) iquv := [14.13,0.0,0.0,0.0];	# @1412.0 MHz
	} 

	# Some checks and conditioning of output vector iquv:
	if (is_boolean(iquv)) {
	    iquv := [1.0,0.0,0.0,0.0];		        # use default
	    s := paste(s,'\n Calibrator not recognised:',cal);
	    s := paste(s,'\n Will use iquv=',iquv);
		print s;
	}
	if (len(iquv)<4) iquv := array(iquv,4);         # pad to 4
	if (len(iquv)>4) iquv := iquv[1:4];             # first 4?
	if (iquv[1]<=0) iquv[1] := 1;                   # I>0
	for (i in [2:4]) {                              # Q,U,V
	    # warning message....?
	    if (abs(iquv[i])>iquv[1]) iquv[i] := 0;
	}
	return iquv;                                # vector [I,Q,U,V]
    }


    public.iquv_calibrator := function (cal=F, ref fMHz=1412) {
	vv := [=];                      # record of vectors 
	n := 0;
	if (cal=='3C48') {
	    vv[n+:=1] := [240,54.0];
	    vv[n+:=1] := [300,47.2];
	    vv[n+:=1] := [350,42.9];
	    vv[n+:=1] := [400,39.4];
	    vv[n+:=1] := [460,35.9];
	    vv[n+:=1] := [560,31.5];
	    vv[n+:=1] := [610,29.7];
	    vv[n+:=1] := [1200,18.0];
	    vv[n+:=1] := [1300,16.9];
	    vv[n+:=1] := [1400,15.9];
	    vv[n+:=1] := [1450,15.5];	
	    vv[n+:=1] := [1590,14.4];
	    vv[n+:=1] := [1670,13.8];
	    vv[n+:=1] := [1750,13.3];
	    vv[n+:=1] := [2215,10.9];
	    vv[n+:=1] := [2295,10.6];
	    vv[n+:=1] := [2375,10.3];
	    vv[n+:=1] := [4770,5.5];
	    vv[n+:=1] := [4860,5.4];
	    vv[n+:=1] := [4940,5.3];
	    vv[n+:=1] := [5020,5.2];
	    vv[n+:=1] := [8150,3.3];
	    vv[n+:=1] := [8400,3.2];
	    vv[n+:=1] := [8650,3.0];

	} else if (cal=='3C147') {
	    vv[n+:=1] := [240,61.3];
	    vv[n+:=1] := [300,55.5];
	    vv[n+:=1] := [350,51.6];
	    vv[n+:=1] := [400,48.2];
	    vv[n+:=1] := [460,44.8];
	    vv[n+:=1] := [560,40.3];
	    vv[n+:=1] := [610,38.3];
	    vv[n+:=1] := [1200,25.0];
	    vv[n+:=1] := [1300,23.6];
	    vv[n+:=1] := [1400,22.4];
	    vv[n+:=1] := [1450,21.9];
	    vv[n+:=1] := [1590,20.5];
	    vv[n+:=1] := [1670,19.7];
	    vv[n+:=1] := [1750,19.0];
	    vv[n+:=1] := [2215,15.9];
	    vv[n+:=1] := [2295,15.5];
	    vv[n+:=1] := [2375,15.1];
	    vv[n+:=1] := [4770,8.3];
	    vv[n+:=1] := [4860,8.2];
	    vv[n+:=1] := [4940,8.1];
	    vv[n+:=1] := [5020,7.9];
	    vv[n+:=1] := [8150,5.0];
	    vv[n+:=1] := [8400,4.9];
	    vv[n+:=1] := [8650,4.7];

	} else if (cal=='3C286') {
	    vv[n+:=1] := [240,29.7];
	    vv[n+:=1] := [300,27.7];
	    vv[n+:=1] := [350,26.3];
	    vv[n+:=1] := [400,25.1];
	    vv[n+:=1] := [460,23.9];
	    vv[n+:=1] := [560,22.2];
	    vv[n+:=1] := [610,21.5];
	    vv[n+:=1] := [1200,16.0];
	    vv[n+:=1] := [1300,15.4];
	    vv[n+:=1] := [1400,14.8];
	    vv[n+:=1] := [1450,14.6];
	    vv[n+:=1] := [1590,13.9];
	    vv[n+:=1] := [1670,13.6];
	    vv[n+:=1] := [1750,13.3];
	    vv[n+:=1] := [2215,11.7];
	    vv[n+:=1] := [2295,11.5];
	    vv[n+:=1] := [2375,11.3];
	    vv[n+:=1] := [4770,7.5];
	    vv[n+:=1] := [4860,7.4];
	    vv[n+:=1] := [4940,7.4];
	    vv[n+:=1] := [5020,7.3];
	    vv[n+:=1] := [8150,5.3];
	    vv[n+:=1] := [8400,5.2];
	    vv[n+:=1] := [8650,5.1];

	} else if (cal=='3C295') {
	    vv[n+:=1] := [240,70.3];
	    vv[n+:=1] := [300,63.2];
	    vv[n+:=1] := [350,58.3];
	    vv[n+:=1] := [400,54.1];
	    vv[n+:=1] := [460,49.9];
	    vv[n+:=1] := [560,44.2];
	    vv[n+:=1] := [610,41.8];
	    vv[n+:=1] := [1200,25.4];
	    vv[n+:=1] := [1300,23.8];
	    vv[n+:=1] := [1400,22.3];
	    vv[n+:=1] := [1450,21.7];
	    vv[n+:=1] := [1590,20.0];
	    vv[n+:=1] := [1670,19.2];
	    vv[n+:=1] := [1750,18.4];
	    vv[n+:=1] := [2215,14.8];
	    vv[n+:=1] := [2295,14.3];
	    vv[n+:=1] := [2375,13.9];
	    vv[n+:=1] := [4770,6.7];
	    vv[n+:=1] := [4860,6.6];
	    vv[n+:=1] := [4940,6.5];
	    vv[n+:=1] := [5020,6.3];
	    vv[n+:=1] := [8150,3.6];
	    vv[n+:=1] := [8400,3.4];
	    vv[n+:=1] := [8650,3.3];
	} else {
	    print 'iquv_calibrator(): not recognised:',cal;
	    return F;
	}

	nvv := len(vv);
	rr := [=];
	rr.cal := cal;
	rr.fMHz := [];
	rr.iquv := array(0.0,4,nvv);
	for (i in ind(vv)) {
	    fiquv := vv[i];
	    fiquv[6] := 0;                     # pad with zeroes
	    rr.fMHz[i] := fiquv[1];
	    rr.iquv[,i] := fiquv[2:5];
	}
	rr.coeff := [=];                       # polynomial coeff
	rr.do_eval := rep(F,4);                # switch
	for (i in [1:4]) {
	    if (sum(rr.iquv[i,])!=0) {
		rr.do_eval[i] := T;
		pp := private.jenmath.fit_poly(yy=rr.iquv[i,], 
					       xx=rr.fMHz, 
					       ndeg=5, eval=T);
		rr.coeff[i] := pp.coeff;       # poly coefficients
		print i,'coeff=',rr.coeff[i],'rmsdiff=',pp.rmsdiff;
		rr.eval[i,] := pp.yyeval;      # evaluated poly
	    } else {
		rr.coeff[i] := 0;
		print i,'coeff=',rr.coeff[i];
		rr.eval[i,] := rr.iquv[i,]*0;  # all zeroes
	    }
	}
	return rr;
    }



#------------------------------------------------------------------------
# Ifr selection:


    public.help_ifrs := function (ifr_number, basel, tel_name='WSRT') {
	rr := public.decode_ifr_info(ifr_number, basel);
	s := ' ';
	s := paste(s,'\n Nr of available ifrs:',rr.nifr);
	s := paste(s,'\n Available antenna1:',rr.zant1);
	s := paste(s,'\n Available antenna2:',rr.zant2);
	if (len(rr.auto)>0) {
	    s := paste(s,'\n Autocorr(s) available for ant(s):',rr.zauto);
	} else {
	    s := paste(s,'\n No auto-correlations available.');
	}
	s := paste(s,'\n Available baseline range:',min(basel),'-',max(basel),'m');
	s := paste(s,'\n');
	s := paste(s,'\n \n ifr-selection syntax:');
	s := paste(s,'\n - Basic ifr specification: ant1.ant2 (i.e. separated by a dot)');
	s := paste(s,'\n - ant1/ant2 are zero-relative integers (like in MS)');
	if (tel_name=='WSRT') {
	    s := paste(s,'\n - NB: for WSRT, they can also be: 0 1 2 3 4 5 6 7 8 9 A B C D E F');
	}
	s := paste(s,'\n - ');
	s := paste(s,'\n - The basic ifr specification is a group of ifrs:');
	s := paste(s,'\n     ant1 and/or ant2 can be a wildcard (*), meaning all available');
	s := paste(s,'\n     ant1 and/or ant2 can be a range: ant11:ant12');
	s := paste(s,'\n     ant1 and/or ant2 can be a sequence: ant11,ant12,ant13,..');
	if (tel_name=='WSRT') {
	    s := paste(s,'\n     lower-case f indicates the 10 fixed WSRT antennas.');
	    s := paste(s,'\n     lower-case m indicates the  4 movable WSRT antennas.');
	}
	s := paste(s,'\n - ');
	s := paste(s,'\n - If a dot is omitted (ant): all ifrs with ant1=ant or ant2=ant');
	s := paste(s,'\n - Autocorrelations are specified as: ant= (no dot needed)');
	s := paste(s,'\n - ');
	s := paste(s,'\n - Multiple ifr-groups can be specified, separated by spaces.');
	s := paste(s,'\n - If a group is preceded by a hyphen (-), its ifrs are excluded.');
	s := paste(s,'\n - (NB: the specified groups are interpreted from left to right)');
	s := paste(s,'\n - ');
	s := paste(s,'\n - Ifrs can also be specfied by baseline length: L>144 -L>1000');
	s := paste(s,'\n - ');
	s := paste(s,'\n');
	return s;
    }

    public.decode_ifr_info := function (ifr_number, basel, tel_name='WSRT') {
	rr := [=];
	rr.nifr := len(ifr_number);
	rr.ants := rep(0,16);
	rr.ant1 := rep(0,16);
	rr.ant2 := rep(0,16);
	rr.auto := rep(0,16);
	rr.nfixfix := 0;			# wsrt: nr of fixed-fixed ifrs
	rr.nfixmov := 0;			# wsrt: nr of fixed-movab ifrs
	rr.nmovmov := 0;			# wsrt: nr of movab-movab ifrs
	for (i in ind(ifr_number)) {
	    ant2 := ifr_number[i]%1000;		# one-relative
	    ant1 := (ifr_number[i]-ant2)/1000;	# one-relative
	    rr.ant1[ant1] := ant1;
	    rr.ant2[ant2] := ant2;
	    rr.ants[ant1] := ant1;
	    rr.ants[ant2] := ant2;
	    if (ant1<=10 && ant2<=10) rr.nfixfix +:= 1;
	    if (ant1<=10 && any(ant2==[11:14])) rr.nfixmov +:= 1;
	    if (any(ant1==[11:14]) && any(ant2==[11:14])) rr.nmovmov +:= 1;
	    if (ant1==ant2) rr.auto[ant1] := ant1;
	}
	rr.wsrtant := "0 1 2 3 4 5 6 7 8 9 A B C D E F";
	rr.wants := rr.wsrtant[rr.ants[1:16]>0];	# wsrt-names
	rr.want1 := rr.wsrtant[rr.ant1[1:16]>0];	# wsrt-names
	rr.want2 := rr.wsrtant[rr.ant2[1:16]>0];	# wsrt-names 
	rr.wauto := rr.wsrtant[rr.auto[1:16]>0];	# wsrt-names
	rr.ants := rr.ants[rr.ants>0];		# one-relative
	rr.ant1 := rr.ant1[rr.ant1>0];		# one-relative
	rr.ant2 := rr.ant2[rr.ant2>0];		# one-relative
	rr.auto := rr.auto[rr.auto>0];		# one-relative
	rr.zants := rr.ants-1;			# zero-relative
	rr.zant1 := rr.ant1-1;			# zero-relative
	rr.zant2 := rr.ant2-1;			# zero-relative
	rr.zauto := rr.auto-1;			# zero-relative
	if (tel_name=='WSRT') {
	    rr.zants := rr.wants;		# WSRT ant-names
	    rr.zant1 := rr.want1;		# 
	    rr.zant2 := rr.want2;		# 
	    rr.zauto := rr.wauto;		# 
	}
	rr.nants := len(rr.zants);
	rr.nant1 := len(rr.zant1);
	rr.nant2 := len(rr.zant2);
	rr.nauto := len(rr.zauto);
	rr.bmin := min(basel);
	rr.bmax := max(basel);
	return rr;				# return record
    }


    public.choice_ifrs := function (ifr_number, basel, tel_name='WSRT') {
	rout := [=]; 
	n := 0;
	rr := public.decode_ifr_info(ifr_number, basel, tel_name);
	if (!is_record(rr)) {
	    rout[n+:=1] := 'problem with choice_ifrs()!';
	    return rout;
	} 

	no_autocorr := ' ';
	if (len(rr.auto)>0) no_autocorr := ' (-*=) ';

	no_WSRT_EF := ' ';
	if (tel_name=='WSRT') {			# WSRT-specific
	    if (any(rr.zants=='E')) no_WSRT_EF := paste(no_WSRT_EF,'(-E)');
	    if (any(rr.zants=='F')) no_WSRT_EF := paste(no_WSRT_EF,'(-F)');
	}	

	rout[n+:=1] := paste('*',no_autocorr,no_WSRT_EF);
	rout[n+:=1] := paste('*');             # all available ifrs
	s := spaste('[',rr.zant1[1],':',rr.zant1[rr.nant1]);
	s := spaste(s,'].[',rr.zant2[1],':',rr.zant2[rr.nant2],']');
	rout[n+:=1] := s;

	s := spaste('L>',as_integer(rr.bmin+0.5)-1);  # baseline length
	s := spaste(s,' L<',as_integer(rr.bmax+0.5)+1);
	rout[n+:=1] := s;

	if (tel_name=='WSRT') {			# WSRT-specific
	    s := ' ';
	    if (rr.nfixmov>0) s := paste(s,'f.m');
	    if (rr.nfixfix>0) s := paste(s,'f.f',no_autocorr);
	    if (rr.nmovmov>0) s := paste(s,'m.m',no_autocorr);
	    if (s!=' ') rout[n+:=1] := s;
	}

	if (len(rr.auto)>0) {			# auto-corrs, if any available
	    rout[n+:=1] := spaste(rr.zauto[1],'=');
	    rout[n+:=1] := spaste('*=');
	}

	for (i in ind(rr.zants)) {
	    rout[n+:=1] := spaste(rr.zants[i]);		# limit the number?
	}
	return rout;
    }

# Generic ifr-decoding function. Returns record with ifr_number and selvec.

    public.decode_ifrs := function (ifrs, ifr_number, basel=F, test=F, context='WSRT') {

	# If the input argument ifrs is an integer vector of ifr_numbers:
	if (is_integer(ifrs)) {                 # list of ifr_numbers
	    stest := paste('decode_ifrs:',len(ifrs),'integers, nifrs=',len(ifr_number));
	    rr := [=];				# output record
	    rr.subset := [];                    # integer vector
	    for (ifrnr in ifrs) {
		if (any(ifr_number==ifrnr)) {  
		    rr.subset := [rr.subset,ifrnr];    # add to subset
		    stest := paste(stest,'\n included: ifr_number=',ifrnr);
		} else {
		    print s := paste('decode_ifrs: not recognised: ifrnr=',ifrnr);
		}
	    }
	    return public.decode_out (rr, ifr_number, test=test, stest=stest);
	}

	# If the input argument ifrs is a string vector: 
	stest := paste('decode_ifrs: spec=',ifrs,'nifrs=',len(ifr_number));
    	sv := rep(F,len(ifr_number));		# ifr selection vector
	num09 := "0 1 2 3 4 5 6 7 8 9";
	alfAF := "A B C D E F";			
	want := [num09,alfAF];			# WSRT ant names..
	nant := len(want);			# temporary....!
	for (s1 in ifrs) {			# assume string vector
	    s2 := split(s1,' ');                # split string on spaces (!)
	                                        # NB: Split on brackets () too?
	    for (s3 in s2) {			# multiple sub-strings
		cc := split(s3,'');		# split into chars
		ncc := len(cc);
		ant := [=];	
		ant[1] := [];			# empty vector	
		ant[2] := [];			# empty vector	
		iant := 1;			# 1 or 2
		exclude := F;			# default: include
		isrange := F;
		issequence := F;		# needed?
		isautocorr := F;
		isbaseline := F;
		refbaseline := F;
		binop := F;			# e.g. =<>
		escape := F;
		k := 0;
		while ((k+:=1)<=ncc) {
		    # print k,cc[k];
		    n := as_integer(spaste(cc[k:ncc]));	# test if integer
		    if (n>0 || cc[k]=='0') {		# numeric
			isinteger := T;
			s := paste('  n=',n,'  k=',k);
			for (i in [k:ncc]) {
			    if (!any(cc[i]==num09)) break;
			    k +:= 1;
			}
			k -:= 1;			# clumsy
			# print s := paste(s,'->',k); 
			if (isbaseline) {
			    refbaseline := n;
			} else if (isrange) {
			    m := ant[iant][len(ant[iant])];
			    ant[iant] := [ant[iant],m:(n+1)];
			    isrange := F;		# reset
			} else {
			    ant[iant] := [ant[iant],n+1];# 1-relative!
			}
		    } else if (any(cc[k]==alfAF)) {	# WSRT 
			n := 10+ind(alfAF)[alfAF==cc[k]];
			if (isrange) {
			    m := ant[iant][len(ant[iant])];
			    ant[iant] := [ant[iant],m:n];
			    isrange := F;		# reset
			} else {
			    ant[iant] := [ant[iant],n];
			}
		    } else if (cc[k]=='-') {	        # minus: exclude
			exclude := T;
		    } else if (cc[k]=='[') {		# opening square bracket
			# ignore for the moment
		    } else if (cc[k]=='(') {		# opening round bracket
			# ignore for the moment
		    } else if (cc[k]=='{') {		# opening curly bracket
			# ignore for the moment
		    } else if (cc[k]=='}') {		# closing curly bracket
			# ignore for the moment
		    } else if (cc[k]==')') {		# closing round bracket
			# ignore for the moment
		    } else if (cc[k]==']') {		# closing square bracket
			# ignore for the moment
		    } else if (cc[k]=='.') {		# ant1/2 separator
			iant +:= 1;			# increment 1->2.......
			if (iant>2) print 'iant=',iant,'>2?';
		    } else if (cc[k]==',') {		# sequence
			issequence := T;		# needed?
		    } else if (cc[k]==':') {		# range
			isrange := T;
		    } else if (cc[k]=='*') {		# all
			ant[iant] := [ant[iant],1:nant];
		    } else if (cc[k]=='L') {		# baseline length
			isbaseline := T;
		    } else if (isbaseline && any(cc[k]=="= > <")) {
			binop := cc[k];			# baseline operator
		    } else if (cc[k]=='=') {		# autocorr
			isautocorr := T;
			# break				# just in case?
		    } else if (cc[k]=='f') {		# fixed (WSRT)
			ant[iant] := [ant[iant],1:10];
		    } else if (cc[k]=='m') {		# movable (WSRT)
			ant[iant] := [ant[iant],11:14];
		    } else if (spaste(cc[k:min(k+3,ncc)])=='auto') {
			k +:= 4;			# example, not relevant
		    } else {
			stest := paste(stest,'\n ** not recognised:',cc[k]);
		    }
		}
		if (escape) break;

		stest := paste(stest,'\n  substring=',spaste(cc));
		stest := paste(stest,'  len=',len(cc),'ant=',ant);
		# print stest;

		for (i in ind(ifr_number)) {
		    ant2 := ifr_number[i]%1000;		# one-relative
		    ant1 := (ifr_number[i]-ant2)/1000;	# one-relative
		    zant1 := ant1-1;			# zero-relative
		    zant2 := ant2-1;			# zero-relative
		    want1 := want[ant1];		# wsrt ant name
		    want2 := want[ant2];		# wsrt ant name
		    s := spaste(ifr_number[i],'(',ant1,',',ant2,'):');
		    if (isbaseline) {
			if (is_boolean(refbaseline)) {
			    print 'isbaseline but refbaseline=',refbaseline;
			    break
			} else if (binop=='=') {
			    if (basel[i]!=refbaseline) next
			} else if (binop=='<') {
			    if (basel[i]>=refbaseline) next;
			} else if (binop=='>') {
			    if (basel[i]<=refbaseline) next;
			} else {
			    print 'isbaseline but binop=',binop;
			    break;
			}
 			sv[i] := !exclude;
			s := paste(s,'baseline=',basel[i],binop,refbaseline);
			stest := paste(stest,'\n',s,'ant12=',zant1,zant2,sv[i]);
		    } else if (isautocorr) {		# auto-correlation
			if (ant1!=ant2) next;
		    	if (!any(ant[1]==ant1)) next;
			sv[i] := !exclude;
		    	stest := paste(stest,'\n autocorr, ant=',zant1,sv[i]);
		    } else if (iant==1) { 		# one (set of) ants specified
		    	if (!any(ant[1]==ant1) && !any(ant[1]==ant2)) next;
			sv[i] := !exclude;
		    	stest := paste(stest,'\n iant=1, ant=',zant1,sv[i]);
		    } else if (iant==2) {		# two (sets of) ants specified
		    	if (!any(ant[1]==ant1)) next;
			if (!any(ant[2]==ant2)) next;
			sv[i] := !exclude;
		    	stest := paste(stest,'\n iant=2, ant12=',zant1,zant2,sv[i]);
		    } else {
		    	stest := paste(stest,'\n ** iant=',iant,', out of range');
			break;
		    }
		}
	    }
	} 
	rr := [=];					# output record
	rr.subset := ifr_number[sv];			# make the selection
	return public.decode_out (rr, ifr_number, test=test, stest=stest);
    }

#-----------------------------------------------------------------------------
# GUI for ifr selection (see msbrick.g):

    public.gui_ifrs := function (ifrs, ifr_number, basel=F, tel_name='WSRT',
				 trace=T) {
	wider private;
	if (trace) {
	    print 'msbrick_select.gui_ifrs():';
	    print '- ifrs=      ',type_name(ifrs),shape(ifrs);
	    print '- ifr_number=',type_name(ifr_number),shape(ifr_number);
	    print '- basel=     ',type_name(basel),shape(basel);
	    print '- tel_name=  ',type_name(tel_name),shape(tel_name),tel_name;
	}
	ifrec := public.decode_ifrs (ifrs, ifr_number, 
				     basel, test=F, 
				     context=tel_name);
	if (trace) print 'ifrec=',ifrec;
	include 'msbrick_selection_gui.g';
	private.selection_gui := msbrick_selection_gui_ifrs(ifrec.subset,
							    ifr_number,
							    basel=basel,
							    tel_name=tel_name);
	private.tempguiagent := create_agent();                 # mandatory
	whenever private.selection_gui.agent -> dismiss do {	# mandatory
	    private.tempguiagent -> dismiss($value);            # send event
	    val private.selection_gui := F;                     # remove gui
	    deactivate whenever_stmts(private.tempguiagent).stmt;
	    val private.tempguiagent := F;                      # ....?    
	}
	if (trace) {
	    print 'selection_gui=',type_name(private.selection_gui),len(private.selection_gui);
	    print 'tempguiagent=',type_name(private.tempguiagent),private.tempguiagent;
	}
	# return ref private.tempguiagent;	# wait for dismiss-event
	return private.tempguiagent;	# wait for dismiss-event
    }



#------------------------------------------------------------------------
# Antenna selection:

    public.help_ants := function (ant_number, ant_pos=F, tel_name='WSRT') {
	rr := public.decode_ant_info(ant_number, ant_pos);
	s := ' ';
	s := paste(s,'\n nr of available antennas:',rr.nants);
	if (!is_boolean(ant_pos)) {
	    s := paste(s,'\n available ant_pos range:',min(ant_pos),'-',max(ant_pos),'m');
	}
	s := paste(s,'\n');
	s := paste(s,'\n \n antenna-selection syntax:');
	s := paste(s,'\n - use zero-relative integers (like in MS)');
	s := paste(s,'\n - NB: for WSRT, they can also be: 0 1 2 3 4 5 6 7 8 9 A B C D E F');
	s := paste(s,'\n - ');
	s := paste(s,'\n - the basic specification is a group of antennas, because:');
	s := paste(s,'\n - it can be a wildcard (*), meaning all available');
	s := paste(s,'\n - it can be a range: ant1:ant2');
	s := paste(s,'\n - it can be a sequence: ant1,ant2,ant3,..');
	s := paste(s,'\n - NB: for WSRT, a lower-case f indicates the 10 fixed antennas.');
	s := paste(s,'\n - NB: for WSRT, a lower-case m indicates the  4 movable antennas.');
	s := paste(s,'\n - ');
	s := paste(s,'\n - multiple antenna-groups can be specified, separated by spaces.');
	s := paste(s,'\n - if a group is preceded by a hyphen (-), its antennas are excluded.');
	s := paste(s,'\n - (the specified groups are interpreted from left to right)');
	s := paste(s,'\n - ');
	s := paste(s,'\n');
	return s;
    }

    public.decode_ant_info := function (ant_number, ant_pos=F, tel_name='WSRT') {
	rr := [=];
	rr.nant := len(ant_number);
	if (rr.nant<=0) {
	    print 'msbrick_select.decode_ant_info: nant=0?';
	    print '- ant_number:',type_name(ant_number),len(ant_number);;
	    print '- ant_pos:   ',type_name(ant_pos),len(ant_pos);
	    ant_number := [1];                  # safe default
	    ant_pos := 0;                       # safe default
	}
	rr.nant := len(ant_number);
	rr.ants := rep(0,16);
	for (i in ant_number) {
	    if (i<=0) {
		print 'decode_ant_info: ant_number=',i;
	    } else {
		rr.ants[i] := i;                # one-relative
	    }
	}
	rr.wsrtant := "0 1 2 3 4 5 6 7 8 9 A B C D E F";
	rr.wants := rr.wsrtant[rr.ants[1:16]>0];	# wsrt-names
	rr.ants := rr.ants[rr.ants>0];		# one-relative
	rr.zants := rr.ants-1;			# zero-relative
	if (tel_name=='WSRT') {
	    rr.zants := rr.wants;		# replace...?
	}
	rr.nants := len(rr.zants);
	# rr.pmin := min(ant_pos);
	# rr.pmax := max(ant_pos);
	# print 'decode_ant_info: rr=',rr;
	return rr;				# return record
    }


    public.choice_ants := function (ant_number, ant_pos=F, tel_name='WSRT') {
	rout := [=]; 
	n := 0;
	rr := public.decode_ant_info(ant_number, ant_pos, tel_name);
	if (!is_record(rr)) {
	    rout[n+:=1] := 'problem with choice_ants()!';
	    return rout;
	} 

	rout[n+:=1] := spaste('*');              # all available ants
	s := spaste(rr.zants[1],':',rr.zants[rr.nants]);
	rout[n+:=1] := s;

	for (i in ind(rr.zants)) {
	    rout[n+:=1] := spaste(rr.zants[i]);	 # limit if more than 16?
	}
	return rout;
    }

    public.choice_refant := function (ant_number, ant_pos=F, tel_name='WSRT') {
	rout := [=]; 
	n := 0;
	rr := public.decode_ant_info(ant_number, ant_pos, tel_name);
	if (!is_record(rr)) {
	    rout[n+:=1] := 'problem with choice_refant()!';
	    return rout;
	} 
	rout[n+:=1] := spaste('mean');
	for (i in ind(rr.zants)) {
	    rout[n+:=1] := spaste(rr.zants[i]);
	}
	return rout;
    }

# Generic antenna-decoding function. Returns record with ant_number and selvec.

    public.decode_ants := function (ants, ant_number, ant_pos=F, test=F, context='WSRT') {
	stest := paste('decode_ants: spec=',ants,'nants=',len(ant_number));
    	sv := rep(F,len(ant_number));		# ifr selection vector
	num09 := "0 1 2 3 4 5 6 7 8 9";
	alfAF := "A B C D E F";			
	want := [num09,alfAF];			# WSRT ant names..
	nant := len(want);			# temporary....!

	for (s1 in ants) {			# assume string vector
	    s2 := split(s1,' ');
	    for (s3 in s2) {			# multiple sub-strings
		cc := split(s3,'');		# split into chars
		ncc := len(cc);
		ant := [];                      # empty vector	
		exclude := F;			# default: include
		isrange := F;
		issequence := F;		# needed?
		binop := F;			# e.g. =<>
		escape := F;
		k := 0;
		while ((k+:=1)<=ncc) {
		    # print k,cc[k];
		    n := as_integer(spaste(cc[k:ncc]));	# test if integer
		    if (n>0 || cc[k]=='0') {		# numeric
			isinteger := T;
			s := paste('  n=',n,'  k=',k);
			for (i in [k:ncc]) {
			    if (!any(cc[i]==num09)) break;
			    k +:= 1;
			}
			k -:= 1;			# clumsy
			# print s := paste(s,'->',k); 
			if (isrange) {
			    m := ant[len(ant)];
			    ant := [ant,m:(n+1)];
			    isrange := F;		# reset
			} else {
			    ant := [ant,n+1];# 1-relative!
			}
		    } else if (any(cc[k]==alfAF)) {	# WSRT 
			n := 10+ind(alfAF)[alfAF==cc[k]];
			if (isrange) {
			    m := ant[len(ant)];
			    ant := [ant,m:n];
			    isrange := F;		# reset
			} else {
			    ant := [ant,n];
			}
		    } else if (cc[k]=='-') {	        # minus: exclude
			exclude := T;
		    } else if (cc[k]=='[') {		# opening square bracket
			# ignore for the moment
		    } else if (cc[k]=='(') {		# opening round bracket
			# ignore for the moment
		    } else if (cc[k]=='{') {		# opening curly bracket
			# ignore for the moment
		    } else if (cc[k]=='}') {		# closing curly bracket
			# ignore for the moment
		    } else if (cc[k]==')') {		# closing round bracket
			# ignore for the moment
		    } else if (cc[k]==']') {		# closing square bracket
			# ignore for the moment
		    } else if (cc[k]==',') {		# sequence
			issequence := T;		# needed?
		    } else if (cc[k]==':') {		# range
			isrange := T;
		    } else if (cc[k]=='*') {		# all
			ant := [ant,1:nant];
		    } else if (cc[k]=='f') {		# fixed (WSRT)
			ant := [ant,1:10];
		    } else if (cc[k]=='m') {		# movable (WSRT)
			ant := [ant,11:14];
		    } else {
			stest := paste(stest,'\n ** not recognised:',cc[k]);
		    }
		}
		if (escape) break;

		stest := paste(stest,'\n  substring=',spaste(cc));
		stest := paste(stest,'  len=',len(cc),'ant=',ant);
		# print stest;

		for (i in ind(ant_number)) {
		    # ant2 := ant_number[i]%1000;		# one-relative
		    # ant1 := (ant_number[i]-ant2)/1000;	# one-relative
		    # zant1 := ant1-1;			# zero-relative
		    # zant2 := ant2-1;			# zero-relative
		    # want1 := want[ant1];		# wsrt ant name
		    # want2 := want[ant2];		# wsrt ant name
		    # s := spaste(ant_number[i],':');
		    if (!any(ant==i)) next;             #...................??
		    sv[i] := !exclude;
		    stest := paste(stest,'\n ant=',i,sv[i]);
		    # stest := paste(stest,'\n ant=',zant1,sv[i]);
		}
	    }
	} 
	rr := [=];					# output record
	rr.subset := ant_number[sv];			# make the selection
	return public.decode_out (rr, ant_number, test=test, stest=stest);
    }


#================================================================================
#================================================================================


#=========================================================
# Finished. Initialise and return the public interface:

    private.init();
    return public
};					# closing bracket
#=========================================================


# msbs := test_msbrick_select();	# run test-routine
msbs := msb_select := msbrick_select();	# create an msb_select object













