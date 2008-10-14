#==========================================================================
# closure object: profiler.g: Used for profiling glish functions.

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
# $Id: profiler.g,v 19.2 2004/08/25 02:17:44 cvsmgr Exp $

#---------------------------------------------------------

pragma include once
# print 'include profiler.g  h01sep99';

# include 'tracelogger.g'		# log tracing messages....

#=========================================================
# Definition of the closure object:

profiler := function (object='object', level=1) {
    public := [=];			# public interface record
    private := [=];			# private functions/data

# Transfer input arguments (if any)

    private.object := object;           # name of object it profiles
    private.proflevel := level;         # profiler is recursive 

# Object initialisation (called at end of this definition):

    private.init := function () {
	wider private;
	private.signature := spaste('profiler(',private.object,'):');
	private.profiling := T;         # if T: do profile 
	private.recursive := F;         # recursive profiling
	private.profile_only := F;      # list of expected names
	private.tracing := F;           # if T, trace inputs
	private.tracinglevel := 0;     
	private.reftime := time();      # reference time (sec)
	public.clear();                 # clear private.item
	private.clear_obsolete();       # ....?
	return T;
    }

#=========================================================
# Specific public functions (if any):
#=========================================================

    public.clear := function () {
        return private.clear ();
    }

# Call at the input of a routine: starts the clock and does tracing.
# Main input functions (used at beginning and end of routines):

    public.start := function (name='undef', text=F, tracelevel=1, hide=F) {
	entry_time := private.time();		   # first statement!
	if (private.tracing) private.trace_start (name, text, tracelevel);
	if (!private.profiling) return T;
	return private.start (entry_time, name, text, hide);
    }

# Call at the exit of a routine that has called .start() at the beginning.
# It stops the clock, fills in the statistics, and does tracing.
# NB: This function passes on the result: so routines should ALWAYS exit with:
#     return profiler.stop(<name>,[text],[result]); 

    public.stop := function (name='undef', text=F, result=T,
			     error=F, warning=F, message=F) {
	entry_time := private.time();                 # first statement!
	private.trace_stop (name, text, result, error, warning, message);
	if (!private.profiling) return result;        # passes on the result!
	return private.stop (entry_time, name, text, result);
    }

# Show the profiling result:

    public.show := function () {
	public.warn_obsolete('profiler.show', use='profiler.show_profile');
	return T;
	return public.show_profile();
    }
    public.show_profile := function () {
	s := private.show_item (private.item, toplevel=T, trace=T);
	return T;
    }

    public.print_profile := function (full=T, trace=T) {
	s := private.show_item (private.item, toplevel=T, trace=F);
	return public.print(s, filename='print_profile', trace=T);
    }

# Set/reset the profiler 'active' switch;
# NB: If not active, tracing is still possible. 

    public.profiling := function (tf=T) {
	wider private;
	private.profiling := tf;
	return private.profiling;
    }

# Set the tracing 'active' switch, ad the tracing-level:
# NB: A higher level means a lower priority.....?
# The higher the level, the more messages.

    public.tracing := function (level=1) {
	wider private;
	if (is_boolean(level)) {
	    private.tracing := level;                        # T/F
	    if (private.tracing) private.tracinglevel := 1;  # ..?
	} else if (is_integer(level)) {
	    private.tracing := T;               
	    if (private.tracing) private.tracinglevel := level;
	} else {
	    print private.signature,'tracing(): not recognised: level=',level;
	    private.tracing := F;               
	}
	return private.tracinglevel;
    }


#--------------------------------------------------------------------------------
# Helper functions to keep track of any calls to 'obsolete' functions,
# to make sure that they can be removed safely.

    public.warn_obsolete := function (name='undef', text=F, use=F) {
	return private.warn_obsolete (name, text, use);
    }

    public.show_obsolete := function (full=T, trace=T) {
	return private.show_obsolete (full, trace);
    }
    public.print_obsolete := function (full=T, trace=T) {
	s := private.show_obsolete (full, trace);
	return public.print(s, filename='print_obsolete');
    }

#--------------------------------------------------------------------------------
# Miscellaneous:

    public.inspect := function () {
	include 'inspect.g';
	inspect(private,spaste('private'));
	return T;
    }

    public.private := function () {
	return ref private;
    }


#=========================================================
# Specific private functions (if any):
#=========================================================

# Returns the current time (sec), relative to profiler reftime 
    private.time := function() {
        return time() - private.reftime;
    } 

# Clear the profiler:

    private.clear := function () {
	wider private;
	private.item := [=];            # accumulator items
	private.active := [];           # integer vector
	private.startstop := 0;  
	private.overhead := 0;
	private.elapsed := 0;
	return T;
    }


#----------------------------------------------------------------------
#----------------------------------------------------------------------
#----------------------------------------------------------------------
# Create/init a new item:

    private.init_item := function (name=F, trace=F) {
	rr := [=];                     # record in private.index
	rr.name := name;               # its field-name
	rr.index := F;                 # its field-index (obsolete)
	rr.nstart := 0;                # nr of starts
	rr.nstop := 0;                 # nr of stops
	rr.startstop := 0;             # counter
	rr.starttime := 0;             # last start time
	rr.elapsed := 0;               # sum of time intervals dt
	rr.overhead := 0;              # estimate of overhead
	rr.ok := T;                    # indicates any problems
	rr.tracinglevel := 0;          # current tracing-level 
	rr.result := [=];              # log of results (fail etc)
	rr.profiler := F;              # record if recursive
	rr.item := [=];                # start of its own item tree
	rr.hide := F;                  # if T, do not show result
	s := paste(private.signature,'created new item:');
	if (trace) print spaste(s,' name=',rr.name,' index=',rr.index);
	return rr;
    }


#----------------------------------------------------------------
# To be called at start of routine 'name':

    private.start := function (entry_time, name='undef', text=F, hide=F) {
	wider private;
	rr := private.find_item_start(name, private.item, private.active);
	rr.hide := hide;                           # set switch
	rr.nstart +:= 1;                           # increment counter
	rr.startstop +:= 1;                        # item counter
	private.startstop +:= 1;                   # overall counter
	rr.starttime := entry_time;                # in public.start()
	now := private.time();                     # the time now
	overhead := now - entry_time;              # overhead of .start()
	rr.overhead +:= overhead;                  # add to item overhead
	private.overhead +:= overhead;             # add to overall overhead
	return T;
    }

#----------------------------------------------------------------
# To be called at end of routine 'name':

    private.stop := function (entry_time, name='undef', text=F, result=T) {
	wider private;
	rr := private.find_item_stop(name, private.item, private.active);
	if (!is_record(rr)) {
	    print 'profiler.stop(',name,'): problem encountered!';
	    return result;                         # passes on the result!
	}
	rr.nstop +:= 1;                            # increment counter
	rr.startstop -:= 1;                        # item counter
	private.startstop -:= 1;                   # overall counter
	now := private.time();                     # the time now
	elapsed := now - rr.starttime;             # incl overhead
	rr.elapsed +:= elapsed;                    # add to item-elapsed
	private.elapsed +:= elapsed;               # add to overall elapsed
	overhead := now - entry_time;              # overhead of .stop()
	rr.overhead +:= overhead;                  # add to item overhead 
	private.overhead +:= overhead;             # add to overall overhead 
	return result;                             # passes on the result!
    }

# Recursive routine for finding a (existing or new) item at the level
# of THE currently active item (indicated by the integer vector 'active').

    private.find_item_start := function (name=F, ref item=F, active=[], trace=F) {
	wider private;
	n := len(active);                          # length of vector
	if (n>1) {                                 # recursive
	    if (trace) print 'find_item_start: active=',active, name;
	    return private.find_item_start(name, item[active[1]].item, 
				      active[2:n], trace=trace);
	} else if (n==1) {                         # recursive
	    if (trace) print 'find_item_start: active=',active, name;
	    return private.find_item_start(name, item[active[1]].item, 
				      active=[], trace=trace);
	} else {                                   # length is zero
	    if (!is_record(item)) {
		print 'find_item_start: item not a record, but:',type_name(item);
		return F;
	    } else if (has_field(item,name)) {     # exists already
		i := ind(item)[field_names(item)==name];
		private.active := [private.active,i];
		if (trace) print 'find_item_start(old):',name,'private.active=',private.active;
		return ref item[name];             # to be accumulated
	    } else {                               # create a new one
		item[name] := private.init_item(name);
		private.active := [private.active,len(item)];
		if (trace) print 'find_item_start(new):',name,'private.active=',private.active;
		return ref item[name];             # to be accumulated
	    }
	}
	return F;                                  # should not happen
    }

# Recursive routine for finding an EXISTING and ACTIVE item:
# This is returned to be 

    private.find_item_stop := function (name=F, ref item=F, active=[], trace=F) {
	wider private;
	n := len(active);                          # length of vector
	if (n>1) {                                 # recursive
	    if (trace) print 'find_item_stop: active=',active, name;
	    return private.find_item_stop(name, item[active[1]].item, 
				     active[2:n], trace=trace);
	} else {                                   # length is zero
	    if (trace) print 'find_item_stop: field_names=',field_names(item);
	    if (!is_record(item)) {
		print 'find_item_stop: item not a record, but:',type_name(item);
		return F;
	    } else if (!has_field(item,name)) {    # does not exist
		print 'find_item_stop: named item does not exist:',name;
		return F;
	    } else {                               # OK, exists
		k := len(private.active);          # overall length
		if (k>1) {
		    private.active := private.active[1:(k-1)]; # reduce
		} else {
		    private.active := [];          # bottom level
		}
		if (trace) print 'find_item_stop: private.active=',private.active;
		return ref item[name];             # to be accumulated
	    }
	}
	return F;                                  # should not happen
    }

#----------------------------------------------------------------
# Recursive routine to show the profiling result:
#----------------------------------------------------------------

    private.show_item := function (ref item=F, prefix='.', toplevel=F, trace=F) {
	s := ' ';
	if (toplevel) {
	    s := private.make_header();
	    if (trace) print s;
	}
	if (!is_record(item)) {
	    s := paste(s,'\nThe item is not a record, but:',type_name(item));
	    return s;              # message?
	}
	for (name in field_names(item)) {
	    s1 := ' ';
	    private.item_statistics(item[name]);     
	    rr := item[name];                        # convenience
	    if (rr.hide) next;                       # do not show
	    if (rr.startstop != 0) {
		s2 := paste('startstop=',rr.startstop,'!!?');
		s1 := spaste(s1,sprintf('%20s',s2));
	    } else if (!rr.ok) {
		s2 := paste('NOT ok!!');
		s1 := spaste(s1,sprintf('%20s',s2));
	    } else {
		s1 := spaste(s1,sprintf('%6i',rr.nstart));
		s1 := spaste(s1,sprintf('%8i',rr.msec_mean));
		if (is_boolean(rr.msec_mean_pure)) {
		    s1 := spaste(s1,sprintf('%8s','-'));
		} else {
		    s1 := spaste(s1,sprintf('%8i',rr.msec_mean_pure));
		}
		s1 := spaste(s1,sprintf('%8i',rr.msec_mean_overhead));
		s1 := spaste(s1,sprintf('%8i',rr.msec_total));
	    }
	    s2 := sprintf('    %-20s',spaste(prefix, name,'()'));
	    s1 := spaste(s1,s2);
	    if (trace) {
		if (toplevel) print ' ';            # skip line
		print s1;
	    }
	    # Recursive: show the sub-items of the current item
	    s3 := private.show_item (item[name].item, spaste(prefix,'.'),
				     trace=trace);
	    if (s3 == ' ') {                        # no sub-items
		if (toplevel) s := paste(s,'\n');   # skip line
		s := spaste(s,'\n',s1);
	    } else {                                # some sub-items
		if (toplevel) s := paste(s,'\n');   # skip line
		s := spaste(s,'\n',s1);
		s := spaste(s,s3);
	    }
	}
	if (toplevel) {
	    s1 := private.make_legend();
	    s := spaste(s,s1);
	    if (trace) print s1;
	} 
	return s;
    }

    private.make_header := function () {
	s := spaste('\n',rep('***',20));
	s := paste(s,'\nProfiling record for:',private.object,':');
	if (private.startstop != 0) {
	   s := spaste(s,' (startstop=',private.startstop,'!!?)');
	}
	s1 := sprintf(' %6s%8s%8s%8s%8s    %-20s',
		     'ntimes','mean','pure','ovh','total','function')
	return paste(s,'\n',s1);
    }

    private.make_legend := function () {
	s := paste('\n\nProfiler legend:',
	'\n-  nested sub-functions are preceded by more dots (..)',
	'\n-  ntimes: nr of times that this function has been called.',
	'\n-  mean:   mean elapsed time (msec, corrected for profiler overhead).',
	'\n-  pure:   mean without the contribution of any sub-function(s).',
	'\n-  ovh:    indication of mean profiler overhead time (noisy).',
	'\n-  total:  total elapsed time spent on this function (incl overhead).',
	'\n ');	
	s := spaste(s,rep('***',20),'\n');
	return s;
    }

#--------------------------------------------------------------
# Calculate statistics of given item, and add result-fields to it:

    private.item_statistics := function (ref item) {
	norm := max(1,item.nstop);                      # safety
	acc_overhead := private.get_overhead(item);     # recursive
	mean := (item.elapsed-acc_overhead)/norm;       # 

	pure := item.elapsed-item.overhead;             # subtr. its own overhead
	fsub := field_names(item.item);                 # any sub-functions
	for (name in fsub) {                            # DIRECT ones only!
	    pure -:= item.item[name].elapsed;           # this includes overheads
	}

	item.msec_mean := as_integer(1000*mean);
	item.msec_mean_pure := as_integer(1000*pure/norm);
	if (len(fsub)<=0) item.msec_mean_pure := F;     # see .show()
	item.msec_mean_overhead := as_integer(1000*acc_overhead/norm);
	item.msec_total := as_integer(1000*item.elapsed);
	return T;
    }

#----------------------------------------------------------------
# Recursive routine to get the total profiler overhead time for the
# given item (i.e. including the items in its own sub-tree...):

    private.get_overhead := function (ref item=F) {
	if (!is_record(item)) {
	    print 'profiler.get_overhead(): item not a record, but',type_name(item);
	    return 0;                                   #.....?    
	}
	overhead := item.overhead;                      # its own
	for (name in field_names(item.item)) {          # its sub-tree
	    overhead +:= private.get_overhead(item.item[name]);
	}
	return overhead;
    }


#=========================================================================
# Optional tracing functions (use tracelogger?) 
#=========================================================================

    private.trace_start := function (name, text=F, level=1) {
	wider private;
	s := spaste('*** ',private.object,'.',name,'(start):');
	if (!is_boolean(text)) s := paste(s,text);
	print s;
	# Use tracelogger?
	return T;
    }

    private.trace_stop := function (name, text=F, result=T,
				    error=F, warning=F, message=F) {
	wider private;
	if (private.tracing) { 
	    s := spaste('*** ',private.object,'.',name,'(stop):');
	    if (!is_boolean(text)) s := paste(s,text);
	    s := paste(s,'->',type_name(result));
	    if (is_boolean(result)) {
		s := paste(s,result);
	    } else if (is_fail(result)) {
	    } else if (is_record(result)) {
		s := paste(s,len(result));
	    } else if (is_string(result)) {
	    } else if (len(result)<5) {
		s := paste(s,':',result);
	    } else {
		s := paste(s,shape(result));
	    }
	    print s;       
	    # Use tracelogger?
	}
	if (is_string(error)) {
	    s := spaste('*** ',private.object,'.',name);
	    print s := paste(s,': (error): ',error);
	}
	if (is_string(warning)) {
	    s := spaste('*** ',private.object,'.',name);
	    print s := paste(s,': (warning): ',warning);
	}
	if (is_string(message)) {
	    s := spaste('*** ',private.object,'.',name);
	    print s := paste(s,': (message): ',message);
	}
	if (is_fail(result)) {
	    s := spaste('*** ',private.object,'.',name);
	    print s := paste(s,': (failed): ');
	    print result;
	}
	return T;
    }

#=========================================================================
# Warning and tracking of calls to obsolescent functions.
# (a bit of a side-issue, but useful for phasing out functions safely):
#=========================================================================

    private.clear_obsolete := function () {
	wider private;
	private.obsolete := [=];
	return T;
    }

    private.warn_obsolete := function (name='undef', text=F, use=F) {
	wider private;
	if (!has_field(private.obsolete,name)) {
	    private.obsolete[name] := ' ';
	}
	n := 1 + len(private.obsolete[name]);
	private.obsolete[name][n] := paste(text); 
	s1 := spaste(private.object,'.',name,'(): ');
	s := paste('... obsolescent function: ',s1);
	if (is_string(use)) s := paste(s,'(use',use,'instead)');
	print s;
	return T;
    }

    private.show_obsolete := function (full=T, trace=T) {
	wider private;
	s := paste('\n Obsolescent function calls to object:',private.object);
	if (len(private.obsolete)<=0) s := paste(s,':: none recorded');
	if (trace) print s;
	for (name in field_names(private.obsolete)) {
	    n := len(private.obsolete[name]) - 1;
	    s1 := spaste('*** ',private.object,'.',name,'(): ncalls=',n,':');
	    if (trace) print s1;
	    s := paste(s,'\n',s1);
	    if (full) {
		for (s2 in private.obsolete[name]) {
		    if (s2==' ') next;
		    if (trace) print '--',s2;
		    s := paste(s,'\n  --',s2);
		}
	    }
	}
	if (trace) print '\n';
	return paste(s,'\n');
    }

#======================================================================
#======================================================================
# Function that counts the bytes in the given Glish value (any type):

    public.size_report := function (ref v, name=F) {
	nb := public.nbytes(v);
	s := sprintf('%-20s',paste(name));
	s := paste(s,sprintf('%-10s',type_name(v)));
	dim := shape(v);
	sdim := spaste(dim);
	if (len(dim)==1) sdim := spaste('[',dim,']');
	s := paste(s,sprintf('%-10s',sdim));
	s := paste(s,sprintf('%10i bytes',nb));
	return s;
    }

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

#===============================================================================
# Print the given (multi-line) text in a file:
#===============================================================================

    public.print := function (txt=F, filename='/tmp/print.txt', trace=F, test=F) {
	# Check the filename:
	cc := split(filename,'');                       # split into chars
	if (!any(cc=='/')) {                            # check directory
	    s := filename;
	    filename := spaste('/tmp/',filename);
	    print 'filename:',s,'->',filename;
	}
	if (!any(cc=='.')) {                            # check extension
	    s := filename;
	    filename := spaste(filename,'.txt');
	    print 'filename:',s,'->',filename;
	}
	# Open the file:
	file := open(s := paste('>',filename));
	s := paste(s,'->',type_name(file));
	if (trace) print 'open file:',s;
	if (!is_file(file)) {
	    print s := paste('open_file problem:',s); 
	    fail(s);
	}
	# If txt is not a string, make it so:
	if (!is_string(txt)) {
	    txt := paste(txt);                         # just in case
	} 
	# OK: Write txt to file:
	write(file, '\n');       
	for (s in txt) {                         # txt may be string vector
	    write(file, s);                      # s may contain \n chars etc
	    if (trace) print 'write to file:',s;
	}

	# Finished: close, print and remove the file:
	if (trace) print 'close file:',filename;
	val file := F;                                 # close the file
	printcommand := 'pri';		               # aips++ default
	s := 'temporarily disabled (for testing)';
	if (!test) shell(s := paste(printcommand, filename));  # print the file
	if (trace) print 'print file:',s;
	if (!test) shell(s := paste('rm -f', filename));       # remove the file
	if (trace) print 'remove file:',s;
	return T;
    }


#===============================================================================
# Test the timer:
#===============================================================================

    public.test_timer := function (n=10000, niter=1) {
	include 'pgplotter.g';
	pgp := pgplotter();
        ii := [1:n];
        tt := rep(0,n);
	niter := 1;
	for (iter in [1:niter]) {
	    print iter,'n=',n;
	    for (i in ii) {
		tt[i] := time();
	    }
	    tt -:= tt[1];
	    # pgp.sci(iter);
	    pgp.plotxy(ii,tt);
	    pgp.lab('i','time(sec)','test of Glish function time()');
	}
	return T;
    }

#=========================================================
# Finished:

    private.init();			# initialise (always!)
    return ref public;			# return public interface (ref!)
}					# end of object definition 



#=========================================================
# Test-routine:

test_profiler := function () {
    public := [=];		# public interface record
    private := [=];		# private functions/data

    p := profiler('test_profiler');
    p.tracing(F);

    private.dummy := function (n=100, hide=F) {
	s := spaste('dummy_',n,'_',hide);
	p.start(s, hide=hide);
	for (i in [1:n]) a := time();
	private.doomy(100);
	p.stop(s);
    }
    private.doomy := function (n=100) {
	s := spaste('doomy_',n);
	p.start(s);
	for (i in [1:n]) a := time();
	p.stop(s);
    }

    # Profile the dummy functions:
    if (T) {
	niter := 5;             # nr of iterations
	for (i in [1:niter]) {
	    for (n in 100*[1:5]) {
		hide := [n==300]; 
		private.dummy(n=n, hide=hide);
	    }
	}
	p.show();               # obsolete
	p.show_profile();
	p.print_profile();
    }

    # Test the start/stop functions:
    if (F) {
	niter := 1;             # nr of iterations
	nfunc := 3;             # nr of (nested) functions
	for (i in [1:niter]) {
	    for (j in [1:nfunc]) {
		name := spaste('func_',j);
		p.start(name);
	    }
	    for (j in [nfunc:1]) {
		name := spaste('func_',j);
		p.stop(name);
	    }
	}
	p.stop('deliberate_error');            # test of checking
	p.show_profile();
    }

    # Test the obsolete function:
    if (T) {
	name := 'test';
	p.start(name);
	p.stop(name, result=T, error='error message',
	       warning='warning message', message='message message');
    }

    # Test the obsolete function:
    if (F) {
       for (i in [1:3]) {
	   p.warn_obsolete('init',paste('test',i));
	   p.warn_obsolete('initt',paste('test',i));
       }
       p.show_obsolete(full=T);
       p.print_obsolete(full=T);               # always
    }

    # Test the timer function:
    if (F) {
       p := profiler();
       p.test_timer();
    }

    # Always show the status of the obsolete-counter:
    p.show_obsolete(full=T);                   # always

    return ref p;	                       # return object
}

#----------------------------------------------------------------
# Run the test-function:
if (F) { 
   pf := test_profiler();
   print 'created profiler object: pf';
}










