# jenmisc.g: some useful mathematical functions:

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
# $Id: jenmisc.g,v 19.0 2003/07/16 03:38:33 aips2adm Exp $

#---------------------------------------------------------

pragma include once
# print 'include jenmisc.g  h01sep99';

# include 'profiler.g';		
# include 'textformatting.g';		


#==========================================================================
#==========================================================================
#==========================================================================

jenmisc := function () {
    private := [=];
    public := [=];
    
# Initialise the object (called at the end of this constructor):

    private.init := function (name='uvbrick') {
	wider private;
	const private.pi := acos(-1);		# use atan()....?
	const private.pi2 := 2*private.pi;	
	const private.rad2deg := 180/private.pi;
	const private.deg2rad := 1/private.rad2deg;
	# include 'tracelogger.g';
	# private.trace := tracelogger(private.name);
	# private.tf := textformatting();		# text-formatting functions
	return T;
    }


#==========================================================================
# Public interface:
#==========================================================================


    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('jenmisc event:',$name,$value);
	# print s;
    }
    whenever public.agent->message do {
	print 'jenmisc message-event:',$value;
    }
    public.private := function(copy=F) {	# access to private part
	if (copy) return private;		# return a copy
	return ref private;			# return a reference
    }


#------------------------------------------------------------------------
# Helper function to check a given record (rr) for the presence of a
# named field, and to create it with a default value if not found.

    public.checkfield := function (ref rr=[=], fname=F, dflt=F, origin=F) {
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

#-------------------------------------------------------------------
# Function that counts the bytes in a record recursively:

    public.nbytes := function (ref v) {
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



#-------------------------------------------------------------------------------
# Sort in various ways:

    public.sort := function (xx, desc=F) {
	if (desc) {                         # descending order
	    return -sort(-xx);
	} else {                            # ascending order
	    return sort(xx);
	}
    }

#------------------------------------------------------------------------
# History accumulation (to be completed):

    public.history := function (ref rr=F, txt=F, descr=F,
				clear=F, show=F, boxmessage=F, 
				trace=F) {
	if (!is_record(rr)) {	                # initialiase
	    val rr := [=];			# record
	    rr.type := 'history';               # identification
	    rr.descr := 'descr';                # description
	    if (trace) print 'history() init:',rr;
	    clear := T;				# see below
	}
	if (clear) {
	    rr.text := ' ';			# string vector...
	    if (trace) print 'history() clear:';
	}

	# Modify the header, if required: 
	if (is_string(descr)) {
	    rr.descr := descr;
	}
	rr.text[1] := paste('\n ** History of:',rr.descr); # always

	# Add a new line to the history, if required:
	if (is_string(txt)) {			# new line given
	    prefix := '\n  .  ';                # 
	    ss := split(txt,'\n');		# split on line-breaks
	    # if (len(ss)>1) prefix := '\n.  '; # multi-line
	    for (i in ind(ss)) {                # line-by-line
	    	if (i>1) prefix := '\n    ';    # 
		s1 := ss[i]; 
		rr.text[1+len(rr.text)] := spaste(prefix,s1);
		if (trace) print paste('->history:',s1);
	    }
	} else if (is_boolean(txt)) {		# ignore
	    # unless len(txt)>1?
	    # use unset?
	} else {		                # unexpected type
	    prefix := '\n  ?? ';                # 
	    s1 := spaste(type_name(txt));
	    s1 := spaste(s1,', shape=',shape(txt));
	    s1 := spaste(s1,', range=',range(txt));
	    rr.text[1+len(rr.text)] := spaste(prefix,s1);
	    if (trace) print paste('->history:',s1);
	} 

	# Show the contents of the history-record:
	postfix := '\n ** \n';
	if (show) print paste(rr.text,postfix);
	if (boxmessage) {
	    include 'jenguic.g';
	    jng := jenguic();
	    jng.boxmessage(paste(rr.text,postfix),
			   title=rr.text[1]);
	}
	return paste(rr.text,postfix);
    }


#=======================================================================
# Finished. Initialise and return the public interface:

    private.init();				# initialise
    return ref public;				# ref?

};						# closing bracket of uvbrick
#=======================================================================


#=========================================================

test_jenmisc := function ( ) {
    private := [=];
    public := [=];
    global jnmisc;
    jnmisc := jenmisc();
    print '\n\n*************************';
    print 'global symbol jnmisc created';
    print '*************************\n\n';

    if (T) {
	rr := F;                        # forces init
	jnmisc.history(rr,descr='test_jenmisc');
	for (i in [1:40]) {
	    jnmisc.history(rr,paste('line',i));
	}
	jnmisc.history(rr,[1:11]);      # wrong type
	jnmisc.history(rr,"vector a b c");
	jnmisc.history(rr,'aa \n bb \n cc');
	jnmisc.history(rr,rep('*',40));
	# jnmisc.history(rr,show=T);
	jnmisc.history(rr,descr='new descr');
	jnmisc.history(rr,boxmessage=T);
	# print jnmisc.history(rr);
    }
    return T;
};

# test_jenmisc();
# inspect(jnmisc,'jnmisc');		# try and inspect

#===========================================================
# Remarks and things to do:
#================================================================


