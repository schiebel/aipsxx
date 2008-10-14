#  uvbrick.g: general-purpose uv-data 'brick' (4D in principle).

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
# $Id: uvbrick.g,v 19.0 2003/07/16 03:38:53 aips2adm Exp $

#---------------------------------------------------------

pragma include once
# print 'include uvbrick.g  w01sep99';

include 'uvbrick_plot.g';		# uvbrick plotting functions
include 'uvbrick_fcs.g';		# uvbrick ops (fit, clip, statistics etc)
include 'uvbrick_decomp.g';		# uvbrick decomposition functions
include 'jenindex.g';		        # index display/control
include 'jenmisc.g';		        # miscellaneous functions
include 'jenmath.g';		        # math functions


# include 'textformatting.g';		
# include 'tracelogger.g';
# include 'buttonscript.g';		# script generation


#=========================================================
test_uvbrick := function () {
    private := [=];
    public := [=];
};


#==========================================================================
#==========================================================================
#==========================================================================

uvbrick := function (brickname='uvbrick', ref tw=F) {
    private := [=];
    public := [=];

    const public.uvbrick := T;			# object recognition (needed!)
    private.type := 'uvbrick';                  # alternative: 'antbrick'
    private.name := brickname;			# input argument
    private.tw := tw;				# input argument (text-window) 
    
# Initialise the object (called at the end of this constructor):
    
    private.init := function (name='uvbrick') {
	wider private;

	private.ident := random();		# 'unique' identification
	private.name := name;			# identification
	private.defined := F;			# not yet defined
	private.sameshape := T;			# switch

	const private.pi := acos(-1);		# use atan()....?
	const private.pi2 := 2*private.pi;	
	const private.rad2deg := 180/private.pi;
	const private.deg2rad := 1/private.rad2deg;

	# include 'tracelogger.g';
	# private.trace := tracelogger(private.name);
	# private.tf := textformatting();	# text-formatting functions
	
	private.jenmath := jenmath();           # cx2real() etc
	private.jenmisc := jenmisc();           # checkfield(), history() etc

	# Initialise the brick history record: 
	private.history := F;                   # force init
	private.jenmisc.history(private.history, descr='brick: init');
	s := spaste('ident=',private.ident);
	s := spaste(s,', sameshape=',private.sameshape);
	private.jenmisc.history(private.history, s);

	private.uvb_plot := uvbrick_plot();	# 
	private.uvb_decomp := uvbrick_decomp();	# 
	private.uvb_fcs := uvbrick_fcs();	# 
	
	private.fitter := F;			# only when needed (numerics.g)
	private.index := F;			# for record-indexing of data-brick
	private.attached := [=];		# attached records with user-info
	private.initattr();			# initialise attributes
	return T;
    }
    
    private.check_fitter := function() {        # used in apply()
	wider private;
	if (is_boolean(private.fitter)) {	# not yet defined
	    include 'mathematics.g';		# new
	    private.fitter := polyfitter();	# fitter object
	}
    }
            
#==========================================================================
# Public interface:
#==========================================================================
    
    public.type := function () {
	return private.type;
    }

    public.name := function (name=F) {
	wider private;
	if (is_string(name)) private.name := name;
	return private.name;
    }
    public.setdefined := function (defined=T) {
	wider private;
	private.defined := defined;
	return private.defined;
    }
    
    public.smooth := function (axis=F, pp=F, replace=T) {
	if (replace) return T;
    }
    public.append := function (ref brick) {
	# append the given brick in a suitable way
    }
    public.merge := function (ref brick) {
    }
    
    #-------------------------------------------------
    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('uvbrick event:',$name,$value);
	# print s;
    }
    whenever public.agent->message do {
	print 'uvbrick message-event:',$value;
    }
    whenever public.agent->abort do {
	print 'uvbrick abort-event:',$value;
	if (is_record(private.index)) {
	    private.index.abort($value);	# abort any index-loops
	}
	if (is_record(private.uvb_plot)) {
	    private.uvb_plot.agent -> abort($value);
	}
    }
    #-------------------------------------------------

    public.message := function (text=F, origin=' ',trace=F) {
	if (is_record(private.tw)) {		# see input argument
	    private.tw.append(text);		# to msbrick textwindow
	} else {
	    trace := T;                         # output something
	}
	if (trace) print text;	                # just print
    }

    public.gui := function (ref parentframe=F) {# make a gui
	return private.gui(parentframe); 
    }
    public.get := function(name, copy=T) {	# get value of named attribute
    	return private.get (name, copy);
    }    
    public.set := function(name, value) {	# set value of named attribute
    	return private.set (name, value);
    }

    public.fMHz := function (mean=T) {          #   
	fMHz := public.get('chan_freq');
	if (is_fail(fMHz)) {
	    print fMHz;
	    fail(fMHz);
	} else if (mean) {
	    return sum(fMHz)/max(1,len(fMHz));  # mean 
	} else {
	    return fMHz;                        # vector
	}
    }

    public.fwhm := function (fMHz=F, unit='rad') {   # beam-width...
	if (is_boolean(fMHz)) {                 # not specified
	    fMHz := public.fMHz();              # mean frequency
	    if (is_fail(fMHz)) fail(fMHz);
	}
	D := 25;				# assume 25 m mirror (WSRT)
	fwhm := 1.22 * 300/(fMHz*D);		# 1.22 lambda/D
	if (unit=='deg') fwhm *:= private.rad2deg;
	if (unit=='arcmin') fwhm *:= private.rad2deg*60;
	if (unit=='arcsec') fwhm *:= private.rad2deg*3600;
	# print 'uvbrick.fwhm()=',fwhm,unit,'for fMHz=',fMHz;
	return fwhm;
    }

    public.convert2Jy := function(mult=1.0) {	# corr.coeff -> Jy
	wider private;
	# NB: Check whether already in Jy?
	# NB: Check whether antbrick etc?
        # NB: Use internal aperteff etc (see decompant)?
        if (!has_field(private.info.unit,'data')) {
	    s := paste('uvbrick.convert2Jy(): no field info.unit.data!');
	    print s;
	    return F;
	}
	unit := private.info.unit.data;         # current value
	if (unit=='Jy') {
	    s := paste('uvbrick.convert2Jy(): already in Jy!');
	} else {
	    private.attr.data *:= mult;         # multiply
	    private.info.unit.data := 'Jy';
	    private.attr.data_unit := 'Jy';          # redundant....?   
	    s := paste('uvbrick.convert2Jy(mult=',mult,'):');
	}
	print s;
	public.addtohistory(s);
	return T;
    }    

    public.getslice := function(index=[=], fname='data') {
	if (has_field(private.attr,fname)) {
	    dim := shape(private.attr[fname]);	# brick shape
	    slice := private.attr[fname][index];
	    if (any(dim==1)) {			# at least one axis=1
		dimout := [];
		for (i in ind(dim)) {
		    if (len(index[i])==0) dimout := [dimout,dim[i]];
		}
		slice::shape := dimout;		# adjust shape...
	    }
	    # s := paste('getslice:',fname,dim);
	    # print s := paste(s,index,'->',shape(slice));
	    return slice;
	}
	return F;
    }
    public.setslice := function(index=[=], slice, fname='data') {
	wider private;
	if (has_field(private.attr,fname)) {
	    private.attr[fname][index] := slice;
	}
	return F;
    }
    public.iscomplex := function() { 
	if (is_complex(private.attr.data)) return T; 
	if (is_dcomplex(private.attr.data)) return T; 
	return F;				# not complex
    }
    public.setattributes := function(attr) {	# Set all attributes of the objec:
	wider private;
	if (is_record(attr)) private.attr := attr;	# check?
	return T;				# ?
    }
    public.getattributes := function(copy=T) {	# Get all attributes of the object
	if (copy) return private.attr;		# return a copy (default)
	return ref private.attr;		# return a reference (access!)
    }
    public.getattrnames := function() {		# Get all attributes names
	return field_names(private.attr);	# return a string vector
    }
    public.private := function(copy=F) {	# access to private part
	if (copy) return private;		# return a copy
	return ref private;			# return a reference
    }
    public.inspect := function () {
	include 'inspect.g';			# only if necessary
	s := spaste(private.type,'.private');
	inspect(private, s);	# 
    }

    public.private := function (copy=F) {
	if (copy) return private;			# copy
	return ref private;				# reference 
    }
    public.attr := function (copy=F) {
	if (copy) return private.attr;			# copy
	return ref private.attr;			# reference 
    }

    public.info := function (copy=F) {
	if (copy) return private.info;			# copy
	return ref private.info;			# reference 
    }

    public.label := function(prefix=F, postfix=F) {
	s := spaste(public.type(),' ');                 # uvbrick/antbrick
	s := paste(s,private.name,'  ');		# e.g. <2>
	s := spaste(s,public.ctif());
	s := paste(s,public.SAF());
	s := spaste(s,' MS=',public.msname());
	s := paste(s,public.get('data_descr'));         # e.g. NFRA_TPOFF
	if (is_string(prefix)) s := paste(prefix,'->',s);
	if (is_string(postfix)) s := paste(s, postfix);
	return s;
    }

    public.ctif := function() {
	wider private;
	s := ' ';
	for (axis in public.axes()) s := spaste(s,split(axis,'')[1]); 
	s := spaste(s,'=',public.shape());
	return s;					# 'cfit=[nc,nf,ni,nt]'
    }

    public.SAF := function () {
	s := paste('SAF=(');
	s := spaste(s,private.attr.spectral_window_id,'/');
	s := spaste(s,private.attr.array_id,'/');
	s := spaste(s,private.attr.field_id,') ');
	return s;					# 'SAF{S/A/F}'
    }
    public.datatypes := function () {
	# e.g. "data model residuals etc";
	return "data";                                  # temporary
    }
    public.msname := function () {
	return private.attr.msname;                     # string
    }
    public.fieldname := function () {                   # e.g. 3C84
	if (has_field(private.attr,'fields')) {
	    return private.attr.fields;                 # string vector
	} else {
	    return s := '...';
	}
    }

    public.legend := function () {			# e.g. plot-legend
	ss := ' '; nss := 0;
	s := paste('MS:',public.msname());
	s := paste(s,' field:',public.fieldname());
	s := spaste(s,' (',public.fMHz(),' MHz)');
	ss[nss+:=1] := s;
	s := spaste(public.type(),' ');                 # uvbrick/antbrick
	s := paste(s,private.name);			# e.g. <2>
	s := paste(s,public.ctif());
	s := paste(s,public.SAF());
	ss[nss+:=1] := paste('\n',s);
	# s := public.get('data_descr');                # e.g. NFRA_TPOFF
	# ss[nss+:=1] := paste('\n',s);                 # not needed here?
	return ss;
    }


    public.shape := function (fname='data') {
	vv := public.get(fname, copy=F);
	if (is_fail(vv)) fail(vv);			#....?
	return shape(vv);
    }
    public.ndata := function () {
	return public.length('data');
    }
    public.nflag := function () {
	ff := public.get('flag', copy=F);
	return len(ff[ff]);
    }
    public.pflag := function () {
	return 100*public.nflag()/max(1,public.ndata());
    }

    public.length := function (axis='time') {
	vv := public.get(axis, copy=F);
	if (is_fail(vv)) fail(vv);			#....?
	return len(vv);
    }

    public.idim := function (axis='time') {
	axes := public.axes();
	if (is_fail(axes)) fail(axes);			#....?
	idim := ind(axes)[axes==axis];
	if (len(idim)<=0) fail(paste(axis,'axis not in axes',axes))
	return idim;
    }

    public.axes := function (fname='data') {
	if (has_field(private.info.axes,fname)) {
	    return private.info.axes.data;
	}
	return F;
    }

    public.size := function () {
	nbytes := 0;
    	for (fname in public.getattrnames()) {
	    nbytes +:= private.jenmisc.nbytes(public.get(fname, copy=F))
    	}
	return nbytes;
    }

# Interact with attached user-info:

    public.attach := function (fname, v=[=], trace=F) {
	wider private;
	private.attached[fname] := v;			# attach
	s := paste('attached:',fname,type_name(v),shape(v));
	if (trace) print s;
	public.addtohistory(s);
	return T;
    }

    public.list_attached := function () {
	return field_names(private.attached);
    }
    public.get_attached := function (fname) {
	if (has_field(private.attached,fname)) {
	    return private.attached[fname];
	} else {
	    s := paste('** uvbrick.get_attached(): no field',fname);
	    print s;
	    return F;
	}
    }

#------------------------------------------------------------------------
# Plot 1D vectors from the uvbrick, grouped as slices:

    public.plot_data_slices := function (pp=[=], ref pgw=F) {
    	return private.uvb_plot.data_slices (public, pp=pp, jpl=pgw); 
    }

#------------------------------------------------------------------------
# Plot uv-coverage:

    public.plot_uvcoverage := function (pp=[=], ref pgw=F) {
    	return private.uvb_plot.uvcoverage (public, pp=pp, jpl=pgw); 
    }

#------------------------------------------------------------------------
# Make a summary of the uvbrick:

    public.summary := function (origin=F, doprint=F) {
	s := paste(' \n Attributes of brick:',public.label());
	s := spaste(s,' (',private.defined,',',private.ident,'):')
	if (is_string(origin)) s := paste(s,origin);
	if (doprint) print s;

	for (fname in field_names(private.info)) {
	    s1 := ' - ';
	    v := private.info[fname];
	    s1 := spaste(s1,sprintf('%-20s',spaste('info.',fname,':')));
	    s1 := spaste(s1,sprintf('%9s',type_name(v)))
	    if (len(shape(v))==1) {
		s1 := spaste(s1,sprintf('%-12s',spaste('[',shape(v),']')));
	    } else {
		s1 := spaste(s1,sprintf('%-12s',paste(shape(v))));
	    }
	    if (doprint) print s1;
	    s := paste(s,'\n',s1);		# append
	}

    	fnames := public.getattrnames();
    	for (fname in fnames) {
	    s1 := ' - ';
	    v := public.get(fname, copy=F);
	    s1 := spaste(s1,sprintf('%-15s',spaste(fname,':')));
	    s1 := spaste(s1,sprintf('%9s',type_name(v)))
	    if (len(shape(v))==1) {
		s1 := spaste(s1,sprintf('%-12s',spaste('[',shape(v),']')));
	    } else {
		s1 := spaste(s1,sprintf('%-12s',paste(shape(v))));
	    }
	    axes := private.info.axes[fname];
	    s1 := paste(s1,sprintf('%-20s',paste(axes)));
	    kind := private.info.kind[fname];
	    s1 := paste(s1,sprintf('%-8s',paste(kind)));
	    unit := private.info.unit[fname];
	    s1 := spaste(s1,sprintf('unit=%-10s',spaste(unit)));
	    label := private.info.label[fname];
	    if (label!=fname) {
		s1 := spaste(s1,sprintf('label=%-15s',spaste(label)));
	    }
	    if (doprint) print s1;
	    s := paste(s,'\n',s1);		# append
    	}
	s := paste(s,s1:=paste('\n Size of brick:',public.size(),'(bytes)'));
	if (doprint) print s1;
	# s := paste(s,s1:=public.history());
	# if (doprint) print s1;
	return paste(s,'\n');
    }

#------------------------------------------------------------------------
# Display the contents of the data-array etc (for testing):

    public.showdata := function(origin=F, doprint=F) {
	dim := shape(private.attr.data);
	s := paste(' \n \n Data of:',public.label())
	if (is_string(origin)) s := paste(s,'(',origin,')');
	s := paste(s,'\n Values in data-array:',dim)
	toobig := F;
	index := [=];			# if toobig==T, show a small part only	
	for (i in ind(dim)) {
	    index[i] := [];
	    if (i<=2) index[i] := [1:min(dim[i],30)];
	    if (i>=3) index[i] := [1:3];
	    if (i==1 && dim[i]>30) toobig := T;
	    if (i==2 && dim[i]>50) toobig := T;
	    if (i>=3 && prod(dim[1],dim[3:i])>50) toobig := T;
	}
	if (toobig) {
	    s := paste(s,'\n NB: DATA-ARRAY TOO BIG, SHOWING JUST A SAMPLE!');
	    s := paste(s,'\n',private.attr.data[index]);
	} else {						# small enough
	    s := paste(s,'\n',private.attr.data);		# 4D
	}
	if (doprint) print s; 

	s1 := public.showaxisinfo (origin=F, doprint=doprint);
	return paste(s,s1,'\n');
    }

# Show axis info:

    public.showaxisinfo := function(origin=F, doprint=F) {
	s := paste(' \n \n Axis info of:',public.label())
	if (is_string(origin)) s := paste(s,'(',origin,')');
	axes := field_names(private.info.axisfields);		# all axes
	for (axis in axes) {
	    naxis := public.length(axis);
	    if (!is_integer(naxis)) naxis := type_name(naxis);
	    s1 := spaste('\n axis=',axis,' (',naxis,'):');
	    nmax := 100;
	    for (fname in public.getattrnames()) {
		if (has_field(private.info.axes,fname)) {
		    if (private.info.axes[fname]==axis) {
			if (len(shape(private.attr[fname]))>1) next;	# 1D only
			n := len(private.attr[fname]);
	    		s2 := sprintf('%-15s',spaste(fname,':'));
	    	    	s1 := spaste(s1,'\n  - ',s2,type_name(private.attr[fname]));
			if (n<=nmax) {
			    s1 := paste(s1,private.attr[fname]);
			} else {
			    s1 := paste(s1,private.attr[fname][1:3],'...');
			    s1 := paste(s1,private.attr[fname][n],' length=',n);
			    if (is_numeric(private.attr[fname])) {
			    	s1 := paste(s1,'min=',min(private.attr[fname]));
			    	s1 := paste(s1,'max=',max(private.attr[fname]));
			    }
			}
		    }
		}
	    }
	    if (doprint) print s1;
	    s := paste(s,s1);
	}
	return paste(s,'\n');
    }

# Show the detailed size of the various parts of the uvbrick:

    public.showsize := function () {
	s := paste(' \n \n Size of:',public.label());
	dim := public.shape();
	s := paste(s,'cfit:',dim,'->',prod(dim));
	nsize := public.size();
	nmin := as_integer(nsize/100);			# threshold
	nbytes := 0;
	nmisc := 0;
	nbmisc := 0;
	s := paste(s,'\n Fields larger than one percent of total:'); 
    	for (fname in public.getattrnames()) {
	    n := private.jenmisc.nbytes(public.get(fname, copy=F))
	    if (n>nmin) {				# large enough
	    	s := paste(s,'\n -',sprintf('%-15s',spaste(fname,':')));
		p := as_integer(100*n/nsize);
		s := spaste(s,n,' bytes (',p,'%)');
	    } else {					# small fry
		nbmisc +:= n;				# 
		nmisc +:= 1;				# 
	    }
	    nbytes +:= n;
    	}
	p := as_integer(100*nbmisc/nsize)
	s := spaste(s,'\n Small fry: ',nbmisc,' bytes (',p,'%)');
	s := paste(s,'in',nmisc,'fields'); 
	return paste(s,'\n *** Total size=',nbytes,'bytes *** \n');
    }

#------------------------------------------------------------------------
# History of the uvbrick:

    public.history := function () {
	wider private;
	s := private.jenmisc.history(private.history,
				     descr=public.label());
	return paste('\n',s);                           # necessary?
    }

    public.addtohistory := function (text=F, trace=F) {
	wider private;
	private.jenmisc.history(private.history, text, trace=trace);
	ss := split(text,'\n');
	public.message(ss[1]);
	return T;
    }


#------------------------------------------------------------------------
# Return a sub-brick, with a selection/average of specified axes.
# The given 'pp' is a record, with fields named for the affected axes:
# - for uvbrick:  corr freq ifr time;
# - for antbrick: pol freq ant time;
# If an axis is not specified, it is just copied as a whole.
# The following fields are expected in a specified axis-record:
# - pp[axis].selvec 			# boolean, explicit, usually irregular
# - pp[axis].nout/.first/.nav/.ninc	# regular sel/av parameters  
# - pp[axis].copyall			# boolean T/F 
# - pp[axis].average			# boolean T/F (look at .nav?)
# - pp[axis].avwgt=F			# averaging weight (uniform if F)


    public.selav := function (pp=[=], trace=F) {
	s := paste('uvbrick.selav(',field_names(pp),'):');
	if (trace) print s;
	name := spaste('{',private.name,'}');       # enclose in brackets
	newuvb := uvbrick(name);	            # new brick, empty
	newuvb.setdefined(T);			    # check first...?

	s := paste('Derived from brick:',private.name);
	s := paste(s,', with the following history:');
	newuvb.addtohistory(s);
	newuvb.addtohistory(public.history());      # add its history
	newuvb.addtohistory('Axis reduction by selection/averaging:');

	first := T;
	dim2 := dim1 := public.shape();		    # for history
	for (axis in public.axes()) {               # data-axes
	    selavop := 'copied';                    # for history
	    if (has_field(pp,axis)) {
		ii := [];
		for (s in "nout first nav ninc") ii := [ii,pp[axis][s]];
		selavop := 'selected';
		if (pp[axis].average) selavop := paste('averaged',ii);
	    }
	    if (!has_field(pp,axis)) {
		if (trace) print 'axis=',axis,': not specified';
	    } else if (pp[axis].copyall) {          
		if (trace) print 'axis=',axis,': pp[axis].copyall';
	    } else if (first) {		            # first axis: copy
		if (trace) print 'axis=',axis,selavop,'(first)';
		first := F;
	    	newuvb.copy(public, axis, trace=trace);	# copy info/attr
		if (pp[axis].average) {
	    	    newuvb.private().average(axis, pp[axis], 
					     private.attr, trace=trace);
		} else {                            # not first axis
	    	    newuvb.private().reduce(axis, pp[axis], 
					    private.attr, trace=trace);
		}
	    	dim2 := newuvb.shape();		    # for history
	    } else {				    # works on newuvb itself
		if (trace) print 'axis=',axis,selavop;
		if (pp[axis].average) {
	    	    newuvb.private().average(axis, pp[axis], trace=trace);
		} else {
	    	    newuvb.private().reduce(axis, pp[axis], trace=trace);
		}
	    	dim2 := newuvb.shape();		    # for history
	    }
	    hist := spaste('- axis=',axis,':');
	    hist := spaste(hist,' shape=',dim1,' -> ',dim2);
	    hist := spaste(hist,' (',selavop,')');
	    newuvb.addtohistory(hist, trace=trace);  
	    dim1 := dim2;
	}
	# Finished:
	if (first) {                                  # nothing changed
	    newuvb.copy(public);	   	      # copy entire brick
	    # newuvb.name(name);                      # necessary?
	    newuvb.setdefined(T);		      # check first...?
	    newuvb.addtohistory(trace=trace);         # re-init history
	    # newuvb.addtohistory(paste('copy of brick:',private.name));
	}
	return newuvb;				      # return sub-brick
    }


# Copy the attr and info records of the given input brick to its own.
# If is_string(axis), e.g. 'time', do NOT copy the relevant attributes.

    public.copy := function (ref brick, axis=F, trace=F) {
	wider private;
	if (trace) print 'uvbrick.copy(',type_name(brick),'axis=',axis,'):';
	if (!is_record(brick)) {			# ....??
	    print 'uvbrick.copy: brick is not a record, but',type_name(brick);
	} else {
	    private.type := brick.type();               # e.g. 'uvbrick'
	    private.info := brick.info(copy=T);		# copy
	    fnames := brick.list_attached();
	    for (fname in fnames) {
		private.attached[fname] := brick.get_attached(fname);
	    }
	    if (trace) print 'copied private.info, fields:',field_names(private.info);
	    if (is_boolean(axis)) {                     # no specific axis
		private.attr := brick.attr(copy=T);
	    } else {                                    # except specific axis
	    	for (fname in field_names(brick.attr())) {
		    s := paste('copy',axis,fname);
		    if (any(private.info.axisfields[axis]==fname)) {
		    	private.attr[fname] := F;
			s := paste(s,'              not defined yet');
		    } else {
		    	private.attr[fname] := brick.attr(copy=T)[fname];
			s := paste(s,type_name(private.attr[fname]));
			s := paste(s,shape(private.attr[fname]));
		    }
		    # if (trace) print s;	
		} 
	    }
	}
	return T;
    }

#------------------------------------------------------------------------
# Worker-function to reduce the internal attribute-record (private.attr).
# If is_record(attr), use this as input (this saves physical copying).
# Using the given selection vector along the indicated axis (e.g. time).
# NB: Checks of axis and sv are assumed unnecessary (see public.select)!

    private.reduce := function (axis, ref selrec=F, ref attr=F, trace=F) {
	wider private;
	s := paste('uvbrick.reduce(',axis,')');
	if (trace) print s,type_name(selrec),'attr=',type_name(attr);
	if (axis=='ant') {
	    sv := private.ifrnr2antsv(trace=trace);     # selection vector
	} else if (axis=='pol') {
	    sv := private.corrcp2polsv(trace=trace);    # selection vector
	} else if (is_boolean(selrec)) {
	    sv := selrec;				# selection vector
	} else if (is_record(selrec)) {
	    sv := selrec.selvec;			# selection vector
	} else {
	    print s := paste(s,'selrec not recognised:',type_name(selrec));
	    fail(s);
	}
	if (is_fail(sv)) {
	    print sv;
	    fail(s);
	}

	nsv := len(sv);                                 # length of sv
	newlength := len(sv[sv]);			# new length of axis 
	for (fname in private.info.axisfields[axis]) {	# selected fields
	    dim := public.getdim(fname, axis, attr=attr);
	    s := paste('reduce:',axis,fname,dim.shape);
	    sel := private.makesel (dim, sv);		# selection vector/record 
	    if (is_record(attr)) {			# use external attr
		private.attr[fname] := attr[fname][sel];
	    } else {					# use its own attr
		private.attr[fname] := private.attr[fname][sel];
	    }

	    newshape := dim.shape;			# original shape
	    newshape[dim.idim] := newlength;		# new axis length
	    if (dim.ndim>1) {				# record-indexing bug!
		private.attr[fname]::shape := newshape;	# restore dimensionality
	    }
	    if (trace) {
		s := paste(s,'->',type_name(private.attr[fname]));
		print s := paste(s,shape(private.attr[fname]));
	    }
	}

	# Some special cases:
	if (axis=='ifr') {
	    r := private.reduce('ant', attr=attr, trace=trace);  # recursive
	    if (is_fail(r)) print r;
	} else if (axis=='corr') {
	    r := private.reduce('pol', attr=attr, trace=trace);  # recursive
	    if (is_fail(r)) print r;
	}
	return T;
    }

# Helper function to make a slice selector:

    private.makesel := function (ref dim, ref selvec) {
	if (dim.ndim==1) {				# vector (1D)
	    # special case needed because of record-indexing bug.....
	    sel := selvec;				# selection vector
	} else {					# array (ND)
	    sel := [=];					# record indexing
	    for (i in dim.iidim) sel[i] := [];		# entire dimension
	    sel[dim.idim] := selvec;			# selection vector
	}
	return sel;
    }


# Helper function to put together the antenna selection vector
# from the vector of available ifr_numbers (private.attr.ifr_number).  

    private.ifrnr2antsv := function (trace=F) {
	wider private;
	s := paste('uvbrick.ifrnr2antsv():');
	if (trace) print s;
	if (!has_field(private.attr,'ant_id1')) {
	    print s,'no field: attr.ant_id1';
	    fail(s);
	} else if (!has_field(private.attr,'ifr_number')) {
	    print s,'no field: attr.ifr_number';
	    fail(s);
	}

	# Fill an antenna selection vector sv:
	sv := rep(F,len(private.attr.ant_id1));      # selection vector
	ii := ind(private.attr.ant_id1);             # convenience
	niiant := len(iiant:=[]);                       # book-keeping
	for (ifrnr in private.attr.ifr_number) {
	    ant12 := public.ifr2ant(ifrnr);	        # 1-relative
	    # if (trace) print 'ifrnr=',ifrnr,'  iant12=',ant12;
	    for (iant in ant12) {                       # [1:2]
		if (iant<=0) next;                      # message?
		if (iant<=niiant && iiant[iant]>0) next; # already
		i := ii[private.attr.ant_id1==iant]; # look for match
		if (len(i)>0) sv[i[1]] := T;            # else?
		iiant[iant] := iant;
		niiant := len(iiant);
		if (trace) print 'iiant=',iiant;
	    }
	}
	return sv;              # return the antenna selection vector
    }

# Helper function to put together the polarisation selection vector
# from the vector of available corrs (private.attr.corr_rcp1/2).  

    private.corrcp2polsv := function (trace=F) {
	wider private;
	s := paste('uvbrick.corr2polsv():');
	if (trace) print s;

	# Fill a polarisation selection vector sv:
	sv := rep(F,2);                                 # selection vector
	for (ircp in [1:2]) {
	    fname := spaste('corr_rcp',ircp);
	    if (!has_field(private.attr,fname)) {
		print s,'no field:',fname;
		fail(s);
	    }
	    if (trace) print fname,private.attr[fname];
	    for (ipol in private.attr[fname]) {
		sv[ipol] := T;
	    }
	}
	if (trace) print s,'sv=',sv;
	return sv;              # return the polarisation selection vector
    }


#-------------------------------------------------------------------------
# Sort the uv-brick in the given order (usually along the baseline-axis):

    public.sort := function (sort_axis='baselength', order='ascending') {
	wider private;

	if (sort_axis=='baselength') {
	    axis := 'ifr';
	    sortarr := private.attr.baseline;		# sorting array
	} else {
	    s := paste('sort(): sort_axis not recognised:',sort_axis);
	    print s;
	    fail(s);
	}

	first := T;
	nex := 0;
	for (fname in private.info.axisfields[axis]) {	# selected fields
	    dim := public.getdim(fname, axis, attr=attr);
	    # print s := paste('sort:',axis,fname,dim.shape);
	    index1 := [=];				# record indexing
	    for (i in dim.iidim) index1[i] := [];	# entire dimension
	    index2 := index1;

	    sarr := sortarr;				# copy sortarr again
	    nsarr := len(sarr);
	    for (i in [1:(nsarr-1)]) {
		for (j in [(i+1):nsarr]) {
		    if (sarr[j]<sarr[i]) {		# not right order
			nex +:= 1;			# counter
			v := sarr[i];
			sarr[i] := sarr[j];
			sarr[j] := v;			# exchange sarr itself
			if (first) {			# show only once
			    # print '- sort:',i,j,'exchange:',sarr[i],sarr[j];
			}

			if (dim.ndim==1) {			# 1D vector
		    	    v := private.attr[fname][i];
		    	    private.attr[fname][i] := private.attr[fname][j];
			    private.attr[fname][j] := v;	# exchange
			} else {				# ND array
	    	    	    index1[dim.idim] := i;		# old slice nr
	    	    	    index2[dim.idim] := j;		# new slice nr
		    	    v := private.attr[fname][index1];
		    	    private.attr[fname][index1] := private.attr[fname][index2];
			    private.attr[fname][index2] := v;	# exchange
			}
		    }
		}						# next j
	    }							# next i
	    first := F;
	    if (nex==0) {					# no exchanges
		print 'sort(): no sorting is needed'
		return T;					# escape
	    }
	}							# next field
	hist := spaste('sorted: sort_axis=',sort_axis,' (=',axis,')');
	hist := paste(hist,'order=',order);
	public.addtohistory(hist);
	return T;
    }

#-------------------------------------------------------------------------
# Worker-function to average the internal attribute-record (private.attr),
# using the averaging loop parameters supplied in the record selrec.
# If is_record(attr), use this as input (this saves physical copying).
# Average only along along the indicated axis (e.g. time), using the given
# weight-function (if supplied, in selrec):

    private.average := function (axis, ref selrec, ref attr=F, normalise=T, trace=F) {
	wider private;

	for (fname in private.info.axisfields[axis]) {	# selected fields
	    dim := public.getdim(fname, axis, attr=attr);
	    s := paste('average:',axis,fname,dim.shape);
	    if (trace) print s;

	    # If external attr, initialise a vector array of the right shape
	    if (is_record(attr)) {			# copy external attr
		newdim := dim.shape;			# old shape
		newdim[dim.idim] := selrec.nout;	# new shape
		q := private.attr[fname][1];		# for correct type
		if (is_numeric(q) && !is_boolean(q)) q *:= 0;	# zero of correct type 
		private.attr[fname] := rep(q,prod(newdim));     # init with zeroes
		private.attr[fname]::shape := newdim;	# adjust array shape
		if (trace) print fname,'newdim=',newdim,shape(private.attr[fname]);
	    }

	    # Calculate the average along the given axis, using selrec:
	    naxis := dim.shape[dim.idim];		# or: naxis:=dim.nidim
	    k1 := selrec.first - selrec.ninc;
	    k2 := 0;	
	    nout := 0;
	    while ((k1+:=selrec.ninc)<=naxis && (k2+:=1)<=selrec.nout) {
		nout +:= 1;				# output-counter
	    	ii := [k1:min(naxis,k1+selrec.nav-1)];	# slice indices
		s1 := paste('...',nout,'ii=',ii);

		if (dim.ndim==1) {			# 1D vector
		    if (is_record(attr)) {              # copy external attr
		    	vv := attr[fname][ii];
		    } else {                            # in-place
		    	vv := private.attr[fname][ii];
		    }
		    kind := private.info.kind[fname];	# coord/label/width etc 
		    v := private.av1(fname, kind, vv, selrec.avwgt, normalise);
		    private.attr[fname][nout] := v;
		    s1 := paste(s1,'vv=',vv,'->',v)

		} else {				# ND array
	    	    index1 := [=];			# record indexing
	    	    for (i in dim.iidim) index1[i] := [];# entire dimension
		    index2 := index1;
		    index2[dim.idim] := nout;		# new slice nr
		    wtot := 0;
		    for (i in ii) {			# relevant slices
		    	index1[dim.idim] := i;		# slice nr
			wgt := 1.0;			# not yet used
			if (is_record(attr)) {		# use external
			    private.attr[fname][index2] +:= wgt*attr[fname][index1];
			} else {			# use itself
		    	    private.attr[fname][index2] +:= wgt*private.attr[fname][index1]; 
			}
			wtot +:= wgt;			# total weight
		    }
		    if (normalise) private.attr[fname][index2] /:= wtot;
		    s1 := paste(s1,'wtot=',wtot)
		}
		if (trace) print s1;
	    }						# end of while

	    # If averaging was done in-place, the averaged vector/array was
	    # filled up from the start. Now remove the useless end part:
	    if (!is_record(attr)) {			# if done in-place
		newdim := dim.shape;			# old shape
		newdim[dim.idim] := nout;	        # first nout only
		sv := rep(F,naxis);			# full size
		sv[1:nout] := T;			# first nout only
		sel := private.makesel (dim, sv);	# selection vector/record
		private.attr[fname] := private.attr[fname][sel];
		private.attr[fname]::shape := newdim;   # adjust shape
	    }
	    if (trace) print s := paste(s,'->',shape(private.attr[fname]));
	}
	return T;
    }

# Average the given 1D vector:

    private.av1 := function (fname, kind, ref vv, ref wgt=F, normalise=T) {
	nav := len(vv);
	if (nav<=0) {
	    s := paste('** warning: .av1():',fname,'len(vv)=0!?')
	    print s;
	    v := vv;
	} else if (is_string(vv)) {			
	    if (len(vv)<=5) {				# if short:
		v := paste(split(paste(vv)),sep='+');	# 'A+B+C'
		v := spaste('(',v,')/',nav);  		# '(A+B+C)/3'
	    } else {					# if long:
		v := spaste(vv[1],'...',vv[len(vv)]);	# 'A...Z'
		v := spaste('sum(',v,')/',nav);  	# 'sum(A...Z)/3'
	    }
	} else if (is_boolean(vv)) {
	    v := all(vv);				# ...?
	} else if (is_numeric(vv)) {
	    v := sum(vv);				# take the sum
	    if (kind!='width') v /:= nav;		# normalise
	    # NB: so for kind=='width' (i.e. bandwidth), keep the sum....!?
	    # As to (uv-data!) time/freq coord, flux is in W/Hz 
	    # As to channel nrs (integer kind=='label'), they should be averaged   
	} else {
	    s := paste(fname,'type not recognised:',type_name(vv));
	    print '** warning .av1():',s;
	    v := vv;					# ...? 
	}
	return v;					# single value
    }


#------------------------------------------------------------------------
# Apply the given unary operation (conversion): 

    public.convert := function (pp=[=]) {
	wider private;

	print 'convert():',pp;

	private.jenmisc.checkfield(pp,'conversion','nop','convert');

	smallpositive := 1e-38;
	unit1 := private.info.unit.data;		# current unit
	unit2 := spaste(pp.conversion,'(',unit1,')');		# new unit(?)

	r := private.jenmath.cx2real(private.attr.data, pp.conversion, copy=F, mess=F);
	if (r) {
	    # OK, recognised and converted by cx2real
	    unit2 := unit1;				# not changed
	    if (pp.conversion=='phase_deg') unit2 := 'deg';	# except
	    if (pp.conversion=='phase_rad') unit2 := 'rad';	# except
	} else if (pp.conversion=='nop') {			# test...?
	    # no operation
	} else if (pp.conversion=='abs') {
	    private.attr.data := abs(private.attr.data);
	    unit2 := unit1;				# not changed
	} else if (pp.conversion=='log' || pp.conversion=='ln' || 
		   pp.conversion=='2log') {
	    private.attr.data[private.attr.data<=0] := smallpositive;
	    private.attr.data := log(private.attr.data);
	    if (pp.conversion=='2log') private.attr.data /:= log(2);
	    if (pp.conversion=='ln') private.attr.data /:= log(exp(1));
	} else if (pp.conversion=='exp') {
	    private.attr.data := exp(private.attr.data);
	} else if (pp.conversion=='cos') {
	    private.attr.data := cos(private.attr.data);
	} else if (pp.conversion=='sin') {
	    private.attr.data := sin(private.attr.data);
	} else {
	    print 'convert(): not recognised:',pp.conversion;
	    return F;					# no conversion
	}
	unit2 := private.info.unit.data;		# new unit
	hist := paste('convert()',pp.conversion)
	if (unit2 != unit1) {
	    hist := paste(hist,'->',unit2);
	    private.info.unit.data := unit2;		# new unit
	}
	public.addtohistory(hist);
	return T;
    }


#------------------------------------------------------------------------
# Make a (small) image-cube:

    public.imagecube := function (ll=0, mm=0) {
	uu := private.attr.ifr_ucoord;
	vv := private.attr.ifr_vcoord;
	dim := shape(uu);
	nll := len(ll);					# nr of l-points
	nmm := len(mm);					# nr of m-points
	fMHz := private.attr.chan_freq[1]
	nff := len(fMHz);
	lm := array(0,nll,nmm,nff);			# empty image (cube)
	icorr := 1;					# one corr...???
	for (i in ind(ll)) {
	    ul := uu *ll[i];				# u*l 
	    for (j in ind(mm)) {
		ulvm := ul + (vv * mm[j]);		# u*l+v*m; 
		for (k in ind(fMHz)) {
		    factor := fMHz[k] * 1.;		# complete....!
	    	    fk := exp(factor*uvlm);		# fourier kernel 
		    lm[i,j,k] := sum(fk * private.attr.data[icorr,k,,]);
		}
	    }
	}
	lm /:= prod(dim);				# normalise
	return lm;					# return image 
    }


#------------------------------------------------------------------------
# Apply the given binary operation. The right-hand value (rhv) may be:
# - scalar:
# - vector:  apply along the given axes
# - uvbrick: use its data-array
# - record:
# - polcoeff:
# - boolean: flags

    public.apply := function (pp=[=], trace=F) {
	wider private;

	private.jenmisc.checkfield(pp,'operation','nop','apply');
	private.jenmisc.checkfield(pp,'apply',T,'apply');
	private.jenmisc.checkfield(pp,'rhv',[=],'apply');
	private.jenmisc.checkfield(pp,'axes',F,'apply');
	private.jenmisc.checkfield(pp,'suspend',F,'apply');

	hist := paste('apply()',pp.operation);
	if (!pp.apply) {
	    pp.operation := 'nop';		# test: data not affected
	    hist := paste(hist,'(testing only, data unaffected)');
	}
	dataxes := public.axes();		# usually: "corr freq ifr time"
	datashape := public.shape();		# e.g. [4,256,91,720]
	if (trace) print hist,'data:',datashape,dataxes;	# temporary

	evalpoly := F;				# T for polcoeff
	slice := F;				# 
	rhv_type := F;
	if (!is_record(pp.rhv)) {
	    rhv_type := 'numeric';		# see below
	    sliceaxes := pp.axes;		# should be string vector
	    slice := pp.rhv;			# assumed numeric (boolean?)
	    sliceshape := shape(slice);		# length may differ from sliceaxes..
	    # print 'pp.rhv slice:',type_name(slice),sliceshape,sliceaxes;
	    sv := [sliceshape>1];		# select all dims>1 
	    sliceaxes := sliceaxes[sv];		# remove from slice axes 
	    slice::shape := sliceshape[sv];	# adjust shape of slice
	    sliceshape := shape(slice);		# 
	    # print 'slice:',sliceshape,sliceaxes,'(after weeding out 1-axes)'

	} else if (has_field(pp.rhv,'uvbrick')) {	# pp.rhv is uvbrick
	    rhv_type := 'uvbrick';		# see below
	    sliceaxes := pp.rhv.axes();		# data-axes of input brick 
	    slice := pp.rhv.get('data', copy=T);# data-array from rhv uvbrick
	    sliceshape := shape(slice);		# length may differ from sliceaxes..
	    if (trace) print 'uvbrick: slice:',type_name(slice),sliceshape,sliceaxes;
	    sv := [sliceshape>1];		# select all dims>1 
	    sliceaxes := sliceaxes[sv];		# remove from slice axes 
	    slice::shape := sliceshape[sv];	# adjust shape of slice
	    sliceshape := shape(slice);		# 
	    if (trace) print 'slice:',sliceshape,sliceaxes,'(after weeding out 1-axes)'

	} else if (!has_field(pp.rhv,'type')) {
	    print hist,'pp.rhv does not have field type:',field_names(pp.rhv);
	    return F;

	} else if (pp.rhv.type=='decomp') {	# record with ant/rcp effects
	    rhv_type := pp.rhv.type;		# see below
	    sliceaxes := pp.rhv.apply_sliceaxes;
	    if (trace) print 'apply: pp.rhv.type==decomp: sliceaxes=',sliceaxes;
	    if (pp.operation=='automatic') {
	    	pp.operation := pp.rhv.applyop;	# apply-operation
	    }

	} else if (pp.rhv.type=='polcoeff') {	# record with polynomial coeff
	    rhv_type := pp.rhv.type;		# see below
	    sliceaxes := pp.rhv.axes;		# assume: dataxes==pp.rhv.axes...!
	    slice := pp.rhv.data;
	    sliceshape := shape(slice);		# length may differ from sliceaxes..
	    # print 'record: slice:',type_name(slice),sliceshape,sliceaxes;

	    evalpoly := T;
	    private.check_fitter();

 	    # xx := public.getcoord_old(pp.rhv.fitaxis);	#...old_()...?
 	    xx := public.getcoord(pp.rhv.fitaxis);
	    if (is_fail(xx)) fail('no xx-vector found');
	    xx := (xx-pp.rhv.xref)/pp.rhv.xnorm;	# to keep xx-values small)

	    sliceshape[pp.rhv.ifitaxis] := 1;		# for weeding out..
	    sv := [sliceshape==1];			# select all dims==1 
	    sliceaxes := sliceaxes[sv];			# remove from slice axes
	    ifitaxis := ind(sliceaxes)[sliceaxes==pp.rhv.fitaxis];
	    # print 'polcoeff: slice:',sliceaxes,'ifitaxis=',ifitaxis,len(xx);

	    d1 := 0.0;					# data type template
	    complexdata := F;
	    if (public.iscomplex()) {
	    	d1 := complex(1.0,0.0);			# data type template
		complexdata := T;
		if (!has_field(pp.rhv,'imagdata')) {
		    print hist,': missing pp.rhv field: imagdata';
		    return F;
		}
	    } 
	    slice := rep(d1,prod(datashape[sv]));
	    slice::shape := datashape[sv];		# adjust shape of slice
	    sliceshape := shape(slice);			# 
	    # print 'slice:',type_name(slice),sliceshape,sliceaxes;

	    if (sliceshape[ifitaxis]!=len(xx)) {
		print hist,'fitaxis not the same length as xx!'
		return F; 
	    }

	} else {
	    print hist,'pp.rhv.type not recognised:',pp.rhv.type;
	    return F;
	}
	if (trace) print hist := paste(hist,'rhv_type=',rhv_type);

	private.index := public.initindex (sliceaxes, 'data', origin=hist);
	if (is_fail(private.index)) fail(private.index);
	private.index.agent -> suspend(pp.suspend);	# if F, start immediately

	check_zeroes := T;				# for divide
	rext := F;					# for decomp2slice()
	while (private.index.next(index)) {		# all data-slices
	    if (trace) print '\n apply: index=',index;
	    s := hist;
	    if (is_boolean(rhv_type)) {
		print 'apply: rhv_type is boolean...'
		next;
	    } else if (rhv_type=='uvbrick') {		# 
		# OK, slice defined above...
	    } else if (rhv_type=='numeric') {		# 
		# OK, slice defined above...

	    } else if (rhv_type=='polcoeff') {		# polynomial coeff
		s := paste(s,index,'ifitaxis=',pp.rhv.ifitaxis); 
		coeff := pp.rhv.data[index];		#
		s := paste(s,'ncoeff=',len(coeff),complexdata); 
		yy := xx;				# temporary
		ok := private.fitter.eval(yy, xx, coeff);
		s := spaste(s,' ok=',ok);
		if (complexdata) {
		    imagcoeff := pp.rhv.imagdata[index];	#
	    	    ok := private.fitter.eval(yyimag, xx, imagcoeff);
	    	    yy := complex(yy, yyimag);
		}
		# now expand to slice, in two different ways....
		sindex := [=];
		for (i in ind(sliceshape)) sindex[i] := [];
		for (i in [1:sliceshape[ifitaxis]]) {
		    sindex[ifitaxis] := i;
		    slice[sindex] := yy[i];
		}
		if (!pp.apply) {			# testing-mode
		    dindex := index;
		    ii := ind(dindex)[ind(dindex)!=pp.rhv.ifitaxis];
		    for (i in ind(dindex)) {
			if (i==pp.rhv.ifitaxis) next;
			if (len(dindex[i])==0) dindex[i] := 1;
		    }
		    yydata := public.getslice(dindex);
		    # print '..dindex=',dindex,'yyshape=',shape(yydata);
		    private.plotfit(xx,yydata,coeff,imagcoeff);
		}
		check_zeroes := T;			# new slice contents

	    } else if (rhv_type=='decomp') {		# ant/rcp decomp
		r := private.uvb_decomp.decomp2slice(public, pp.rhv, index, rext);
		if (is_boolean(r)) {
		    if (!r) {
		    	print '** warning:',hist,'problem with decomp2slice';
			return private.index.abort(s);		# escape
		    }
		    s := paste('apply(',pp.operation,'): old slice:');
		} else {
		    slice := r;				# new slice
		    s := paste('apply(',pp.operation,'): new slice:');
		}
		s := paste(s,type_name(slice),shape(slice));
		# print s := paste(s,'minmax=',min(slice),max(slice));
	    }

	    # Now do the actual apply of the current slice:

	    if (pp.operation=='nop') {				# 
		# no-operation: just print s (debugging);
		print s;
	    } else if (pp.operation=='+' || pp.operation=='add') {
	    	private.attr.data[index] +:= slice;
	    } else if (pp.operation=='-' || pp.operation=='subtract') {
	    	private.attr.data[index] -:= slice;
	    } else if (pp.operation=='*' || pp.operation=='multiply') {
	    	private.attr.data[index] *:= slice;
	    } else if (pp.operation=='/' || pp.operation=='divide') {
		if (check_zeroes) {
 	    	    sv := [abs(slice)==0.0]; 		# check for zeroes
		    zeroes := any(sv);			# switch (T/F)
		    check_zeroes := F;			# reset
		}
	    	private.attr.data[index] /:= slice;	# /0 -> Infinity
		if (zeroes) private.attr.data[index] := 0.0;
	    } else if (pp.operation=='^' || pp.operation=='power') {
	    	private.attr.data[index] ^:= slice;
	    } else {
	    	print s := paste('apply(): not recognised:',pp.operation);
		return private.index.abort(s);		# escape
	    }
	}
	public.addtohistory(hist);
	return T;
    }


#------------------------------------------------------------------------
# Decomposition into receptor ('antenna') contributions.
# - generic: phase zeroes and gain factors;
# - a bit WSRT specific: ellipticities and dipole rotation error

    public.decompant := function (pp=[=], ref pgw=F) {
	return private.uvb_decomp.decompant (public, pp, pgw=pgw);
    }

#------------------------------------------------------------------------
# Determination of WSRT antenna position and other parameters.

    public.MAKECAL := function (pp=[=], ref pgw=F) {
	return private.uvb_decomp.MAKECAL (public, pp, pgw);
    }

#------------------------------------------------------------------------
# Determination of suggestions for WSRT attenuator settings.

    public.TOPOR := function (pp=[=]) {
	return private.uvb_fcs.TOPOR (public, pp);
    }

#------------------------------------------------------------------------
# Determination of WSRT antenna pointing (and beamshape?) parameters.

    public.BEAM := function (pp=[=], ref pgw=F) {
	return private.uvb_decomp.BEAM (public, pp, pgw);
    }

#------------------------------------------------------------------------
# Determination of WSRT DCB delay offsets.

    public.DELFI := function (pp=[=], ref pgw=F) {
	return private.uvb_decomp.DELFI (public, pp, pgw);
    }

#------------------------------------------------------------------------
# Show the decomposition result (in decomp record decomprec):

    public.decompshow := function (ref decomprec=[=]) {
	return private.uvb_decomp.decompshow (public, decomprec);
    }
    public.is_decomprec := function (ref decomprec=[=]) {
	return private.uvb_decomp.is_decomprec (decomprec);
    }
    public.getiuk := function (ref rr=[=], iukpra, iant, ipol=1) {
	return private.uvb_decomp.getiuk (rr, iukpra, iant, ipol);
    }

#------------------------------------------------------------------------
# Helper function: initialise decomprec (record that controls ant-decomposition):

    public.init_decomprec := function (pp=[=]) {
	return private.uvb_decomp.init_decomprec (public, pp);
    }

    public.is_decomprec := function (rr=F) {
	return private.uvb_decomp.is_decomprec(rr);
    }

# Send ant/rcp decomposition results (in rr) to TMS:

    public.decomp2tms := function (pp=[=], rr=F) {
	return private.uvb_decomp.decomp2tms (public, pp, rr);
    }


#------------------------------------------------------------------------
# Fit function (e.g. polynomial) along the specified axis:
# The result is an array with function coefficients, one set for
# each 1D vector in the axis direction.
# Works on complex data too (separate fits on real and imag parts).

    public.fit := function (pp=[=], ref pgw=F) {
	return private.uvb_fcs (public, pp, pgw);
    }

#------------------------------------------------------------------------
# Clip the data after differentiate the data along the given diffaxis:
# Works on complex and real data (?).

    public.clip := function (pp=[=], ref pgw=F) {
	return private.uvb_fcs( public, pp, pgw);
    }

#------------------------------------------------------------------------
# Plot 1D vectors along the specified axis, in the specified style:

    public.statistics := function (pp=[=], ref pgw=F) {
	return private.uvb_fcs (public, pp, pgw);
    }


#-------------------------------------------------------------------------
# Helper function: convert Stokes parameters I,Q,U,V of the given source component
# to correlation products XX,YY,XY,YX or RR,LL,LR,RL, as given by the vector corrs.
# If corrs not given (i.e. F), use the internal corr_name of the uvbrick.
# Attach the result to the component record as the vector 'xyrl':
# Used by .decompant() above, but also by msbrick.corrupt(). 

    public.iquv2corr := function (ref compon=[=], corrs=F, trace=F) {
	s := paste('iquv2corr: source component');
	s := paste(s,'iquv=',compon.iquv,'lm=',compon.lm);
	s := paste(s,'corrs=',corrs);
	if (trace) print s;
	if (is_boolean(corrs)) corrs := public.get('corr_name');
	cxr := complex(1.0,0.0);
	cxi := complex(0.0,1.0);
	rr := [=];
	compon.xyrl := [];
	rr.XX := cxr*(compon.iquv[1] + compon.iquv[2])/2;	#...?
	rr.YY := cxr*(compon.iquv[1] - compon.iquv[2])/2;	#...?
	rr.XY := (compon.iquv[3] + cxi*compon.iquv[4])/2;	#...?
	rr.YX := (compon.iquv[3] - cxi*compon.iquv[4])/2;	#...?

	rr.RR := (compon.iquv[1] + cxi*compon.iquv[4])/2;	#...?
	rr.LL := (compon.iquv[1] - cxi*compon.iquv[4])/2;	#...?
	rr.RL := cxr*(compon.iquv[2] - compon.iquv[3])/2;	#...?
	rr.LR := cxr*(compon.iquv[2] + compon.iquv[3])/2;	#...?

	compon.corrs := corrs;					# attach
	for (i in ind(compon.corrs)) {
	    compon.xyrl[i] := rr[compon.corrs[i]];
	    s := paste(' - ',i,compon.corrs[i],compon.xyrl[i]);
	    if (trace) print s;
	}
	return T;
    }



    
#=============================================================================
# Helper function: initialise indexing for the given data-array and axes:
# If forwardonly=T, only forward movement is possible by step=1. 
    
    public.initindex := function (slice_axes=" ", dataname='data', origin='...',
				  showprogress=T, autofinish=T, forwardonly=T) {
	if (!is_string(slice_axes)) {
	    s := paste('initindex: slice_axes not string:');
	    print s := paste(s,type_name(slice_axes),slice_axes);
	    fail(s);
	} 
	data_axes := private.info.axes[dataname];	# e.g. "corr freq etc"
	dim := shape(private.attr[dataname]);
	slice_dims := [];				# 
	for (axis in slice_axes) {
	    slice_dims := [slice_dims,ind(data_axes)[data_axes==axis]];
	}
    	axes_label := [=];
    	for (i in ind(data_axes)) {
	    axis := data_axes[i];
  	    axes_label[axis] := F;
	    if (!any(axis==slice_axes)) {
	    	ii := seq(dim[i]);
	    	ss := ' ';
	    	for (j in seq(dim[i])) ss[j] := spaste(j);	# fallback?
	    	axes_label[axis] := public.getlabel(axis);	# real labels
	    } 
    	}
	
	index := jenindex(origin, showprogress=showprogress, 
			  autofinish=autofinish,
			  forwardonly=forwardonly);
	r := index.init(dim, slice_dims, axes_label);
    	if (is_fail(r)) {
	    print s := paste('initindex: axes=',axes,dataname,origin);
	    fail(r);					# something wrong
	}
	s := paste('initindex:',dataname,dim,data_axes,'axes=',axes);
	s := paste(s,'slice_dims=',slice_dims);
	# print s;
	return index;					# OK
    }


# Helper function: get the/a coordinate-vector for the given axis (e.g. 'time'):

    public.getcoord := function (axis, ref unit=F, ref label=F) {
	n := 0;
	if (has_field(private.attr,axis)) {
	    xx := private.attr[axis];
	    if (!is_numeric(xx) || is_boolean(xx)) {
		xx := ind(xx);
	    }
	    val label := axis;				# default
	    val unit := 'unit?';	
	    if (axis=='UT') {
		xx /:= 3600.0;				# convert to hours
		val label := 'UT';	
		val unit := 'hr';	
	    } else if (axis=='HA') {
		val label := 'HA';	
		val unit := 'deg';	
	    } else if (axis=='LAST') {
		val label := 'LAST';	
		val unit := 'sec';	
	    } else if (axis=='corr') {
		# xx := private.attr.corr_type;		# ...?
		# val label := 'corr type-code'
		val label := paste('corr (',private.attr.corr_name,')');
		val unit := ' ';	
	    } else if (axis=='freq') {
		resMHz := private.attr.resolution[1];
		fmt := spaste('freq (bw=%.',3,'g)');
		val label := sprintf(fmt,resMHz);	
		val unit := 'MHz';	
	    } else if (axis=='time') {
		xx -:= xx[1];				# relative to start
		val label := 'relative time';
		val unit := 'sec';	
	    }	
	} else if (axis=='baselength') {		# ifr-axis
	    xx := private.attr.baseline;
	    val label := 'nominal baseline length';
	    val unit := 'm';	
	} else if (axis=='uvdist') {			# time-axis
	    # uu := private.attr.ifr_ucoord[1,];	# use 1st ifr only....
	    # vv := private.attr.ifr_vcoord[1,];	# use 1st ifr only....
	    uu := private.attr.ifr_ucoord;		# 2D: [ifr,time]
	    vv := private.attr.ifr_vcoord;		# 2D: [ifr,time]
	    xx := sqrt(uu*uu+vv*vv);
	    val label := 'uv-distance'
	    val unit := 'm';	
	} else if (axis=='MJD97') {			# time-axis
	    xx := private.attr.MJDseconds;
	    spd := 24*3600.0;				# sec/day
	    xx -:= 50448.0*spd;				# seconds since 0 jan 97
	    xx /:= spd;					# days since 0 jan 97
	    val label := 'MJD since 0 January 1997'
	    val unit := 'days';	
	} else {
	    print s := paste('getcoord',axis,': no xx found');
	    val label := s;	
	    val unit := '??';	
	    fail(s);
	}
	return xx;
    }


# Helper function: get the/a label-vector for the given axis (e.g 'ifr'):

    public.getlabel := function (axis, origin=F) {
	n := 0;
	for (fname in public.getattrnames()) {
	    # print fname;
	    if (has_field(private.info.axes,fname)) {
	    	if (private.info.axes[fname]==axis) {
		    vv := private.attr[fname];			# the vector itself
		    n := len(vv);
		    # print 'getlabel:',axis,fname,n,type_name(vv),shape(vv);
	    	    if (private.info.kind[fname]=='label') {
		    	ll := private.attr[fname];
		    	# print axis,fname,'len(ll)=',len(ll),'first=',ll[1];
		    	return ll;				# OK
		    }
		}
	    }
	}
	if (n>0) {
	    ll := split(paste(seq(n)));				# use 1,2,3,...
	    # print axis,'len(ll)=',len(ll),'first=',ll[1];
	    return ll;						# OK
	} 
	print s := paste('getlabel',axis,': no ll found');
	fail(s);
    }

# Helper function to decode ifr/icorr, returns record:

    public.getrcp_ifr := function (ifr, icorr=F, full=T) {
	# print 'uvbrick.getrcp_ifr:',ifr,icorr;
	if (is_record(ifr)) {				# ifr==index
	    icorr := ifr[1];				# 
	    ifr := ifr[3];				# 
	}
	rcp := [=];
	rcp.antid1 := public.ifr2ant(private.attr.ifr_number[ifr]);
	rcp.antid0 := rcp.antid1 - 1;                   # 0-relative
	ii := ind(private.attr.ant_id1);
	rcp.iant[1] := ii[private.attr.ant_id1==rcp.antid1[1]];
	rcp.iant[2] := ii[private.attr.ant_id1==rcp.antid1[2]];
	rcp.ipol[1] := private.attr.corr_rcp1[icorr];	# ant1: 1(X) or 2(Y)
	rcp.ipol[2] := private.attr.corr_rcp2[icorr];	# ant2: 1(X) or 2(Y)
	if (full) {                                     # save time
	    ants := private.attr.ant_shortname;
	    pols := private.attr.pol_name;		# e.g. "X Y"
	    rcp.polname[1] := spaste(pols[rcp.ipol[1]]);
	    rcp.polname[2] := spaste(pols[rcp.ipol[2]]);
	    rcp.antname[1] := spaste(ants[rcp.iant[1]]);
	    rcp.antname[2] := spaste(ants[rcp.iant[2]]);
	    rcp.rcpname[1] := spaste(rcp.antname[1],rcp.polname[1]);
	    rcp.rcpname[2] := spaste(rcp.antname[2],rcp.polname[2]);
	    rcp.ifrname := spaste(rcp.rcpname[1],rcp.rcpname[2]);
	}
	return rcp;
    }

# Helper function to get iant (index into data-array etc)
# from a given antid1 (1-relative) or antid0 (0-relative):

    public.get_iant := function (antid1=F, antid0=F, trace=F) {
	s := paste('uvbrick.get_iant(',antid1,antid0,'):');
	if (trace) print s;
	if (is_boolean(antid1)) {
	    if (is_boolean(antid0)) {
		print s,'no valid inputs!';
		return F;
	    } else {                         # 0-relative given
		antid1 := antid0 + 1;        # make 1-relative
	    }
	}
	ii := ind(private.attr.ant_id1);     # [1:nant]
	iant := ii[private.attr.ant_id1==antid1];
	if (trace) print s,'-> iant=',iant;
	if (len(iant)==1) {                  # one found
	    return iant;                     # OK 
	} else if (len(iant)>1) {            # more than one?
	    print s,'-> multiple iant=',iant,'?, first is used';
	    return iant[1];                  # use the first 
	} else {                             # none found
	    print s,'-> not found in ant_id1=',private.attr.ant_id1;
	    return F;
	}
    }

# Helper function to decode iant/ipol, returns record:

    public.getrcp_ant := function (iant, ipol, full=T) {
	# print 'uvbrick.getrcp_ant:',iant,ipol;
	rcp := [=];
	rcp.antid1 := private.attr.ant_id1[iant];       # 1-relative
	rcp.antid0 := rcp.antid1 - 1;                   # 0-relative
	if (full) {                                     # save time
	    ants := private.attr.ant_shortname;
	    pols := private.attr.pol_name;		# e.g. "X Y"
	    rcp.polname := spaste(pols[ipol]);
	    rcp.antname := spaste(ants[iant]);
	    rcp.rcpname := spaste(rcp.antname,rcp.polname);
	}
	return rcp;
    }


# Helper function: convert ifrnr (=1000*ant1+ant2) to [ant1,ant2]:

    public.ifr2ant := function(ifrnr) {
	ant2 := ifrnr%1000;			# 1-relative
	ant1 := (ifrnr-ant2)/1000;		# 1-relative
	return [ant1,ant2];
    }


#=======================================================================
# Helper functions for main appliications:
#=======================================================================

# Get some dimension-related quantities: 

    public.getdim := function (fname, axis=F, naxis=F, ref attr=F) {
	dim := [=];
	if (is_record(attr)) {
	    dim.shape := shape(attr[fname]);	# shape of attribute
	} else {
	    dim.shape := shape(private.attr[fname]);# shape of attribute
	}
	dim.ndim := len(dim.shape);		# nr of dimensions
	dim.iidim := ind(dim.shape);		# indices of dimensions
	dim.idim := F;				# index of specified axis
	dim.nidim := F;				# length of idim-axis
	if (is_string(axis)) {
	    axes := private.info.axes[fname];
	    dim.idim := ind(axes)[axes==axis];
	}
	if (is_integer(naxis)) {
	    ii := dim.shape[dim.shape==naxis];
	    if (is_integer(dim.idim)) {
		if (dim.shape[dim.idim]!=naxis) {
		    print 'getdim: naxis=',naxis,'!=',dim.shape[dim.idim];
		    return F;
		}
	    } else if (len(ii)==1) {		# ok, unique 
		dim.idim := ii; 
	    } else if (len(ii)==0) {		# more of the same length
		dim.idim := ii[1]; 		# take the first (?)
	    } else {
		print 'getdim: naxis=',naxis,'not in',dim.shape;
		return F;
	    }
	}
	if (is_integer(dim.idim)) dim.nidim := dim.shape[dim.idim]; 
	# print s := paste(fname,dim.shape,axis,dim)
	return dim;
    }

# Deal with the special case where the new length along 
# the specified axis (idim) is one (e.g. after selection or averaging):

    private.adjustdim := function (fname, dim, newidim, ref v) {
	wider private;
	s := paste(fname,dim.shape,'(idim=',dim.idim,dim.nidim,') ');
	# print 'adjustdim:',s;
	if (private.sameshape) {		# retain dimensionality
	    newshape := dim.shape;		# original shape
	    newshape[dim.idim] := newidim;		# new axis length
	    if (dim.ndim>1) v::shape := newshape;	# record-indexing bug!

	} else {				# reduced dimensionality
	    # if ((dim.ndim==1) v::shape := len(v);	# record-indexing bug!
	    private.info.axes[fname] := axes[axes!=axis];
	}

	s := paste(fname,dim.shape,'(idim=',dim.idim,dim.nidim,') ');
	s := paste(s,'->',shape(v),private.info.axes[fname]);
	# print s;					# for debugging
	return T;
    }

# Check whether the attribute 'name' is equal to the given value (vv): 

    private.isequal := function (name, vv) {
	if (!has_field(private.attr,name)) {
	    s := paste('uvbrick.isequal(): no such field:',name);
	    print s;
	    return F;	
	} else if (len(private.attr[name])!=len(vv)) {
	    return F;
	} else if (all(private.attr[name]==vv)) {
	    return T;
	} else {
	    return F;
	}
    }

# Perform some checks on the uvbrick object:

    public.check := function (full=F) {
	if (!has_name(public,'uvbrick')) {
	    print 'uvbrick.check(): object is not a uvbrick!'
	} else if (!private.defined) {
	    print 'uvbrick.check(): uvbrick is not defined yet!'
	} else if (!full) {
	    return T;				# OK
	}
	return F;				# not OK
    }


#=======================================================================
# Dealing with object attributes:
#=======================================================================

# Get (a copy of or a reference to) the value of the named attribute:

    private.get := function(name, copy=T) {
	fname := private.checkattrname(name,'get');
	if (is_fail(fname)) {
	    print s := paste('uvbrick.get(',name,'): not recognised');
	    fail(s);
	}		
	if (copy) return private.attr[name];	# return copy of value
	return ref private.attr[name];		# return reference (access!)
    }
    
# Set the named attribute to the given value vv:

    private.set := function(name, vv) {
	wider private;
	name := private.checkattrname(name,'set');
	if (is_fail(name)) fail(name);		
	if (shape(private.attr[name])!=shape(vv)) {
	    s := paste('uvbrick set:',name,'shape:');
	    s := paste(s,shape(private.attr[name]),'!=',shape(vv));
	    print s;
    	    fail(s);
	}
	private.attr[name] := vv;		# OK, modify value
	# print 'uvbrick.set:',name,type_name(vv),shape(vv);
	return T;
    }

# Check whether the named attribute is a field of private.attr.
# This function avoids the printing of the entire private record if wrong.

    private.checkattrname := function (name, origin=F) {
	if (!has_field(private.attr,name)) {
	    s := paste('uvbrick.attr does not have field:',name);
	    print s;
    	    fail(s);
	}
	return name;
    }

# Define the units of the specified axis and adjust the attribute of that name:
# NB: Some more thought is needed to deal with coord/width etc

    public.setunit := function (axis, attr=F) {
    }
    public.setwidth := function (axis, attr=F) {
    }

    public.setaxis := function (axis, attr=F) {
	wider private;
	attrin := attr;					# for message
	if (!has_field(private.info.axisattr,axis)) {
	    print s := paste('setaxis: axis not recognised:',axis);
	    fail(s)
	} else if (is_boolean(attr)) {			# not specified
	    attr := private.info.axisattr[axis][1];	# default is the first
	}
	unit := ' ';					# default: undefined
	label := attr;					# default: attr name
	if (any(attr==private.info.axisattr[axis])) {
	    vv := private.attr[attr];
	    unit := private.info.unit[attr];
	    label := private.info.label[attr];
	} else if (attr=='MJD') {			# MJD days
	    vv := private.attr.MJDseconds/(3600*24);
	    unit := 'day';
	} else {
	    print s := paste('setaxis: attr not recognised:',attr);
	    fail(s)
	}
	private.attr[axis] := vv;			# set new value
	private.info.unit[axis] := unit;		# set new unit-string
	private.info.label[axis] := label;		# set new label-string
	print 'setaxis:',axis,attrin,'->',attr,'unit=',unit,'label=',label;
	return T;
    }

# Initialise the attribute-record:

    private.initattr := function () {
	wider private;
	private.attr := [=];			# attributes
	private.info := [=];			# organising information
	private.info.kind := [=];		# 'coord'/'width'/'label'/'flag' 
	private.info.unit := [=];		# unit-strings 
	private.info.label := [=];		# label-strings
	private.info.width := [=];		# points to width-attr...?
	private.info.axes := [=];		# list of axes ...?
	private.info.axisattr := [=];		# relevant attr name(s) per axis
	private.info.axisfields := [=];		# fields affected by an axis
	private.info.naxis := [=];		# length of each axis (checks)
	return T;
    }

# Helper function: add field (=definition) to aux-record (used externally):

    public.addtoaux := function (ref aux, fname, vv, axes=F, 
				 kind=F, unit=F, label=F, trace=F) {
	aux[fname] := [=];
	aux[fname].value := vv;
	aux[fname].axes := axes;
	aux[fname].kind := kind;
	aux[fname].unit := unit;
	aux[fname].label := label;
	if (trace) print 'addtoaux (axes=',axes,'):',fname;
    }

# Store the attribute value vv under the field-name fname.
# Also keep track of the meaning of the various axes. 

    private.storeattr := function (fname, vv, axes=F, kind=F, unit=F, label=F) {
	wider private;
	ndim := len(dim:=shape(vv));

	s := paste('storeattr():',fname,type_name(vv),dim,axes)
	s := paste(s,'kind=',kind,'unit=',unit,'label=',label);	
	# print s;						# temporary

	if (has_field(private.attr,fname)) {			# already exists(?)
	    print '** warning: field already exists:',fname;
	    # return F;						# ....?
	}

	# vv::shape := shape(vv);		# for vectors (not entirely safe!?)
	private.attr[fname] := vv;				# store data

	if (is_boolean(kind)) {
	    if (any(fname==["data weight flag"])) {
		kind := fname;
	    } else if (is_boolean(axes)) {
		kind := 'info';
	    } else if (is_string(vv)) {
		kind := 'label';
	    } else if (is_boolean(vv)) {
		kind := 'flag';
	    } else if (is_numeric(vv)) {
		if (ndim==1) kind := 'coord';
	    } else {
		#.....?
	    }
	}

	private.info.kind[fname] := kind;			# 
	private.info.unit[fname] := unit;			# 
	if (is_boolean(label)) label := fname;			# default label
	private.info.label[fname] := label;			# create
	private.info.axes[fname] := axes;			# axes-indication

	#----------------------------
	if (is_boolean(axes)) return T;				# skip
	# if (axes=='-') return T;				# skip
	#----------------------------

	if (ndim != len(axes)) {
	    s := paste('** warning:',fname,dim,axes);
	    s := paste(s,': ndim=',ndim,'!= len(axes)=',len(axes));
	    print s;
	}

	for (i in ind(axes)) {
	    axis := axes[i];					# e.g. 'time'
	    naxis := dim[i];					#
	    if (ndim==1) {					# vectors only 
	    	if (!has_field(private.attr,axis)) {		# does not exist yet
	    	    private.attr[axis] := vv;			# vector 
	    	    private.info.kind[axis] := kind;		# e.g. 'coord'
	    	    private.info.unit[axis] := unit;		# e.g. 'MHz'
	    	    private.info.label[axis] := label;		# e.g. 'MJD'
		    private.info.axes[axis] := axis;		# axes-indication
		    private.info.axisattr[axis] := fname;	# create
		} else {
		    s := private.info.axisattr[axis];
		    private.info.axisattr[axis] := [s,fname];	# append
		}
	    }
	    if (!has_field(private.info.naxis,axis)) {		# does not exist yet
	    	private.info.naxis[axis] := naxis;		# create
	    } else {
		if (private.info.naxis[axis] != naxis) {
		    print '***warning: different naxis from before!!',axis,fname;
		}
	    }
	    if (!has_field(private.info.axisfields,axis)) {	# does not exist yet
		# print '*** create in .info.axisfields:',axis;
		private.info.axisfields[axis] := axis;		# create
	    }
	    n := 1 + len(private.info.axisfields[axis]);	# increment
	    private.info.axisfields[axis][n] := fname;		# store
	    # print i,axis,naxis,n,':',fname;			# temporary
	}
	return T;
    } 


#=======================================================================
# Fill the uv-brick with uv-data from the given msrec (from msdo):
#=======================================================================

    public.fill := function (ref msrec, pp=[=], trace=F) {
	wider private;
	private.type := 'uvbrick';              # recognition string
	private.initattr();			# reset attribute record
	
	if (!is_record(msrec)) {
	    s := paste('uvbrick.fill(): msrec not a record');
	    print s;
	    return F;				# problem
	} else if (!has_field(msrec,'axis_info')) {
	    s := paste('uvbrick.fill(): missing field axis_info');
	    print s;
	    return F;				# problem
	} else if (has_field(msrec,'uvbrick_aux')) {        # obsolete?
	    pp := msrec.uvbrick_aux;		# auxiliary info
	}
	
# The axes should come first (because default is the first):
	
	axes := 'corr';
	vv := msrec.axis_info.corr_axis;			# first!
    	private.storeattr ('corr_name', vv, axes);
	ncorr := len(vv);
	corr_rcp2 := corr_rcp1 := array(0,ncorr);
	for (i in ind(vv)) {
	    cc := split(vv[i],'');		# split into chars
	    for (j in ind(cc)) {
		if (j>2) {
		    print i,j,'corr has more than 2 pols:',cc;
		} else if (any(cc[j]=="X R")) {
		    if (j==1) corr_rcp1[i] := 1;
		    if (j==2) corr_rcp2[i] := 1;
		} else if (any(cc[j]=="Y L")) {
		    if (j==1) corr_rcp1[i] := 2;
		    if (j==2) corr_rcp2[i] := 2;
		} else {
		    print i,j,'pol not recognised:',cc[j];
		}
	    }
	}
    	private.storeattr ('corr_rcp1', corr_rcp1, axes, kind='label');
    	private.storeattr ('corr_rcp2', corr_rcp2, axes, kind='label');
	corr_type := array(-1,ncorr);				# place-holder!!
    	private.storeattr ('corr_type', corr_type, axes, kind='label');
	
	axes := 'freq';
	vv := msrec.axis_info.freq_axis.chan_freq * 1e-6;	# first!
	if (len(shape(vv))>1) vv := vv[,1];			# ....!
    	private.storeattr ('chan_freq', vv, axes, unit='MHz');
	nfreq := len(vv);
	vv := msrec.axis_info.freq_axis.resolution * 1e-6;
	if (len(shape(vv))>1) vv := vv[,1];			# ....!
    	private.storeattr ('resolution', vv, axes, unit='MHz', kind='width');
    	private.storeattr ('chan_number', ind(vv), axes, kind='label');
	
	axes := 'time';
	vv := msrec.axis_info.time_axis.MJDseconds;		# first!
    	private.storeattr ('MJDseconds', vv, axes, unit='sec');
	ntime := len(vv);
        if (has_field(msrec.axis_info.time_axis,'HA')) {
	    vv := msrec.axis_info.time_axis.HA;	
    	    private.storeattr ('HA', vv, axes, unit='deg');
	}
        if (has_field(msrec.axis_info.time_axis,'UT')) {
	    vv := msrec.axis_info.time_axis.UT;	
    	    private.storeattr ('UT', vv, axes, unit='sec');
	}
        if (has_field(msrec.axis_info.time_axis,'LAST')) {
	    vv := msrec.axis_info.time_axis.LAST;	
    	    private.storeattr ('LAST', vv, axes, unit='sec');
	}
	
	axes := 'ifr';
	vv := msrec.axis_info.ifr_axis.ifr_shortname;		# first!
    	private.storeattr ('ifr_shortname', vv, axes);
	nifr := len(vv);
	vv := msrec.axis_info.ifr_axis.ifr_name;
    	private.storeattr ('ifr_name', vv, axes);
	ifr_number := msrec.axis_info.ifr_axis.ifr_number;
    	private.storeattr ('ifr_number', ifr_number, axes, 
			   unit='ant2+1000*ant1', kind='label');
	vv := msrec.axis_info.ifr_axis.baseline;
    	private.storeattr ('baseline', vv, axes, unit='m');
	
	# Data-bricks (4D):
	
	axes := "corr freq ifr time";
	fnames := "data corrected_data model_data";		# data-bricks
	found := F;
	for (fname in fnames) {
            if (has_field(msrec,fname)) {
		if (found) {
		    s := 'fill: only one data-cube per uv-brick allowed.';
		    print s := paste(s,'Skipped:',fname); 
		    next;
		}
    		private.storeattr ('data', msrec[fname], axes, 
				   label=fname, unit='corr.coeff');
	    }
	}
	
	fname := 'flag';
	flag := [=];
	flag.ifr := rep(F,nifr);
	flag.corr := rep(F,ncorr);
	flag.time := rep(F,ntime);
	flag.freq := rep(F,nfreq);
        if (has_field(msrec,fname)) {
    	    private.storeattr (fname, msrec[fname], axes, kind='flag'); 
	    # adjust 1D flag-arrays using msrec.flag?
	}
	for (fname in field_names(flag)) {
    	    private.storeattr (spaste('flag_',fname), flag[fname], fname, kind='flag'); 
	} 
	
	fname := 'weight';
        if (has_field(msrec,fname)) {
	    dim := shape(msrec[fname]);
	    if (len(dim)==1) axes := 'time';              # 1D weights...?
    	    private.storeattr (fname, msrec[fname], axes) 
	    }
	
	# uv-coordinates (2D):
	
	axes := "ifr time";
	fnames := "u v w uvdist";	   	          # coord-planes
	for (fname in fnames) {
            if (has_field(msrec,fname)) {
		name := spaste('ifr_',fname,'coord');     # (used in uvbrick/_plot)
    		private.storeattr (name, msrec[fname], axes, 
				   label=name, unit='m');
	    }
	}
	
	# Auxiliary fields (not directly taken from msrec from msdo):

	for (fname in field_names(pp)) {
    	    private.storeattr (fname, pp[fname].value, 
			       axes=pp[fname].axes,
			       kind=pp[fname].kind,
			       unit=pp[fname].unit,
			       label=pp[fname].label);
	}

	public.label();
	private.defined := T;

	# Make the (derived) ant and pol axes consistent with the 
	# ifr and corr axes:
	for (axis in "ant pol") {
	    r := private.reduce(axis, trace=F); 
	    if (is_fail(r)) print r;
	}
	return T;
    }

#=======================================================================
# Fill an 'antenna-brick (a special kind of uvbrick) with antenna-data 
# from the given msrec (from msdo):
#=======================================================================

    public.fill_antbrick := function (ref msrec, pp=[=]) {
	wider private;
	private.type := 'antbrick';             # recognition string
	private.initattr();			# reset attribute record
	
	if (!has_field(msrec,'axis_info')) {
	    s := paste('uvbrick.fill_antbrick(): missing field axis_info');
	    print s;
	    return F;				# problem
	} else if (has_field(msrec,'uvbrick_aux')) {
	    pp := msrec.uvbrick_aux;		# auxiliary info
	}
	
# The axes should come first (because default is the first):
	
	axes := 'pol';
	vv := msrec.axis_info.pol_axis.pol_name;	# first!
    	private.storeattr ('pol_name', vv, axes);
	npol := len(vv);
	vv := msrec.axis_info.pol_axis.pol_code;
    	private.storeattr ('pol_code', vv, axes);
	
	axes := 'freq';
	vv := msrec.axis_info.freq_axis.chan_freq * 1e-6;	# first!
	if (len(shape(vv))>1) vv := vv[,1];			# ....!
    	private.storeattr ('chan_freq', vv, axes, unit='MHz');
	nfreq := len(vv);
	vv := msrec.axis_info.freq_axis.resolution * 1e-6;
	if (len(shape(vv))>1) vv := vv[,1];			# ....!
    	private.storeattr ('resolution', vv, axes, unit='MHz', kind='width');
    	private.storeattr ('chan_number', ind(vv), axes, kind='label');
	
	axes := 'time';
	vv := msrec.axis_info.time_axis.MJDseconds;		# first!
    	private.storeattr ('MJDseconds', vv, axes, unit='sec');
	ntime := len(vv);
        if (has_field(msrec.axis_info.time_axis,'HA')) {
	    vv := msrec.axis_info.time_axis.HA;	
    	    private.storeattr ('HA', vv, axes, unit='deg');
	}
        if (has_field(msrec.axis_info.time_axis,'UT')) {
	    vv := msrec.axis_info.time_axis.UT;	
    	    private.storeattr ('UT', vv, axes, unit='sec');
	}
        if (has_field(msrec.axis_info.time_axis,'LAST')) {
	    vv := msrec.axis_info.time_axis.LAST;	
    	    private.storeattr ('LAST', vv, axes, unit='sec');
	}
	
	axes := 'ant';
	vv := msrec.axis_info.ant_axis.ant_shortname;          # first!
    	private.storeattr ('ant_shortname', vv, axes);
	nant := len(vv);
	vv := msrec.axis_info.ant_axis.ant_name;
    	private.storeattr ('ant_name', vv, axes);
	vv := msrec.axis_info.ant_axis.ant_id1;
    	private.storeattr ('ant_id1', vv, axes, 
			   unit='antnr(1-rel)', kind='label');
	vv := msrec.axis_info.ant_axis.ant_pos1D;
    	private.storeattr ('ant_pos1D', vv, axes, unit='m');
	
	# Data-bricks (4D):
	
	axes := "pol freq ant time";
	fnames := "data";		                # data-bricks
	found := F;
	for (fname in fnames) {
            if (has_field(msrec,fname)) {
		if (found) {
		    s := 'fill: only one data-cube per uv-brick allowed.';
		    print s := paste(s,'Skipped:',fname); 
		    next;
		}
    		private.storeattr ('data', msrec[fname], axes, 
				   label=fname, unit='corr.coeff');
	    }
	}
	
	fname := 'flag';
	flag := [=];
	flag.ant := rep(F,nant);
	flag.pol := rep(F,npol);
	flag.time := rep(F,ntime);
	flag.freq := rep(F,nfreq);
        if (has_field(msrec,fname)) {
    	    private.storeattr (fname, msrec[fname], axes, kind='flag'); 
	    # adjust 1D flag-arrays using msrec.flag?
	}
	for (fname in field_names(flag)) {
    	    private.storeattr (spaste('flag_',fname), flag[fname], 
			       fname, kind='flag'); 
	} 
	
	fname := 'weight';
        if (has_field(msrec,fname)) {
	    dim := shape(msrec[fname]);
	    if (len(dim)==1) axes := 'time';              # 1D weights...?
    	    private.storeattr (fname, msrec[fname], axes);
	}
		
	# Auxiliary fields (not directly taken from msrec from msdo):

	for (fname in field_names(pp)) {
    	    private.storeattr (fname, pp[fname].value, 
			       axes=pp[fname].axes,
			       kind=pp[fname].kind,
			       unit=pp[fname].unit,
			       label=pp[fname].label);
	}

	public.label();
	private.defined := T;
	return T;
    }


#=======================================================================
# Finished. Initialise and return the public interface:

    private.init(private.name);			# initialise
    return ref public;				# ref?

};						# closing bracket of uvbrick
#=======================================================================

# uvb := test_uvbrick();			# run test-routine

#===========================================================
# Remarks and things to do:
#  - copy (name etc);

#  - private.attr.curraxes[axis='ifr'] := [=]
#	fields: coord, width, unit [,label?] are REFERENCES  
#  - setaxis() -> setcoord(axis, name), setwidth(), setunit();
#  - private.info.axisattr[axis='time'] := "MJDseconds UT HA LAST etc"	# now
#  - private.attr.coord[axis='ifr'] := [=]
#	fields: coord, width, unit [,label?] are REFERENCES (what about MJD?) 
#  - setaxis() -> setcoord(axis, name), setwidth(), setunit();

#  - average/integrate: use coord/flag/width etc (1D only?)
#  - 1D axis flag-vectors....
#  - take simulate outside?
#  - convert/pp.conversion()
#  - public.tofase(vv, todeg)	(offer a hidden service)
#  - (phase)gradient()
#  - polynomial() -> record (xx,yy,polcoeff) -> apply/operation
#  - datagroup()  2D bricks only?
#  - plot()	  2D bricks only?
#  - uvplot()	  
#  - edit()	  flags 
#  - gui?
#  - apply (operation) rm (may be vector): 
#	returns (vector of) total linear pol P
#  - automatic antenna-attrbutes in fill()
#  - apply multiply, axis='ant': first make ifr-vector
#	assume correct ant-order?
#	what about feed/receptor-numbers?
#  - decompant()
#  - statistics (per axis?), flags also
#  - flag only per axis? 
#	faster, and greater granularity is possible in small bricks
#  - uvclean much easier with uvbricks? 	 
#================================================================


