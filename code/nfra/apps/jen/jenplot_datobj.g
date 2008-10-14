# jenplot_datobj.g: auxiliary data functions for jenplot.g.

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
# $Id: jenplot_datobj.g,v 19.0 2003/07/16 03:38:35 aips2adm Exp $

#---------------------------------------------------------

pragma include once
# print 'include jenplot_datobj.g  w01sep99';

include 'jenmath.g';		        # cx2real etc
include 'textformatting.g';		
include 'profiler.g';


#=====================================================================
#=====================================================================
jenplot_datobj := function (ref pgwaux=F, ref prof=F) {
    private := [=];
    public := [=];

    private.pgwaux := pgwaux;		# pgplotter functions (..?)
    private.prof := prof;               # profiler

# Initialise the object (called at the end of this constructor):

    private.init := function () {
	wider private;
	if (is_boolean(private.prof)) {
	    private.prof := profiler('jenplot_datobj');
	}

	if (is_boolean(private.pgwaux)) {       # just in case
	    include 'jenplot_pgwaux.g';		# auxiliary pgplot routines
	    private.pgwaux := jenplot_pgwaux();	# pgplotter routines
	}

	private.jnm := jenmath();	        # cx2real etc
	private.tf := textformatting();
	private.trace := F;
	return T;
    }


#==========================================================================
# Public interface:
#==========================================================================

    public.agent := create_agent();
    whenever public.agent -> * do {
	s := paste('jenplot_datobj event:',$name,$value);
	# print '\n',s,'\n';
    }
    whenever public.agent->message do {
	print 'jenplot_datobj message-event:',$value;
    }
    whenever public.agent->done do {
	print 'jenplot_datobj event: done',$value;
    }

    public.done := function (trace=F) {
	wider private;
	return T;
    }

    public.clear := function (dummy=F) {	# clear the workspace
    }


# Get (a copy of or a reference to) the value of the named field:

    public.get := function(name, copy=T) {
	if (has_field(private,name)) {
	    if (copy) return private[name];	# return copy of value
	    return ref private[name];		# return reference (access!)
	} else {
	    s := paste('plot1D.get(): not recognised',name);
	    print s;
	    fail(s);
	}
    }
    
# Set the named field to the given value vv:

    public.set := function(name, vv=F) {
	wider private;
	if (has_field(private,name)) {
	    print 'uvb.set:',name,'->',type_name(vv),shape(vv);
	    private[name] := vv;		# OK, modify value
	    return T;
	} else {
	    s := paste('plot1D.set(): not recognised',name);
	    print s;
	    fail(s);
	}
    }

# Inspection:

    public.pgw := function () {
	return ref private.pgwaux.pgw();	# reference to pgplot widget
    }
    public.pga := function () {
	return ref private.pgwaux;		# reference to pgplot widget functions
    }
    public.private := function(copy=F) {	# access to private part
	if (copy) return private;		# return a copy
	return ref private;			# return a reference
    }
    public.show := function (dummy=F) {		# print summary of private
	return private.show();
    }
    public.inspect := function (name=F) {	# Inspect various things
	include 'inspect.g';
	if (name=='pga') {
	    inspect(private.pgwaux,'pgwaux');
	} else if (name=='public') {   
	    inspect(public,'uvd');
	} else {   
	    inspect(private,'uvd.private');
	}
	return T;
    }

    public.message := function (txt='***') {
	print txt;
	return F;
    }

#-------------------------------------------------------------------------
# Progress message:

    private.message := function (txt=F) {
	if (!is_record(private.pgwaux)) {
	    print 'jenplot_datobj:',txt;
	} else if (!is_record(private.pgwaux.pgw())) {
	    print 'jenplot_datobj:',txt;
	} else {
	    private.pgwaux.pgw().message(paste(txt));
	}
	return T;
    }

#========================================================================
# Some common helper functions for all data-structures:
#========================================================================

# Initialise the common fields of a data-object (line/group/slice/brick):

    private.init_common_fields := function (type=F, label=F) {
	gsb := [=];
	const gsb.jenplot_gsb := T;	# object recognition
	const gsb.type := type;		# gsb type, e.g. 'slice'
	gsb.label := label;		# label of this data-structure
	gsb.intident := random();	# unique integer identifier

	# Used for special purposes (like jenplot.index...);
	gsb.special := F;

	# Various labels:
	gsb.labels := "title legend xdescr ydescr xunit yunit";
	gsb.labels := [gsb.labels,"xname yname"];
	gsb.labels := [gsb.labels,"xannot yannot"];
	for (fname in gsb.labels) gsb[fname] := F;
	gsb.xname := 'x';                # default
	gsb.yname := 'y';                # default

	# Vector of the names of 'settable' fields (...?)
	gsb.settable := [gsb.labels,"showflags showlegend"];

	# Initialise plot-legend:
	gsb.legend := F;                 # forces initialisation
	private.pgwaux.legend(gsb.legend);  # gsb.legend -> record

	# The rest of the common fields may be reset...?
	public.reset_common_fields(gsb);  # see below....

        # to be used in pgwaux.env() and pgwaux.define_panel():
	gsb.env := [=];            
	gsb.env.xmin := gsb.env.ymin := -12.34;
	gsb.env.xmax := gsb.env.ymax := 12.34;
	gsb.env.xdir := gsb.env.ydir := 1; # -1 if x/y coordinates reversed
	gsb.env.just := 0;               # 0: do not enforce aspect-ratio
	gsb.env.axis := 0;               # 0: draw axes with tick-marks
	gsb.box := F;                    # restricting box (e.g. boxcursor) 

	# Some switches:
	gsb.modified := T;		# if T, re-calculate statistics etc
	gsb.selected := F;		# if T, treat specially
	gsb.visible := T;		# if F, do not plot ...?
	gsb.deleted := F;		# if T, ignore (reversible)

	return gsb;
    }

# Reset some generic values to a known state (used in clear() etc):

    public.reset_common_fields := function (ref gsb=F) {
	gsb.xx := [];		         # vector of x-values
	gsb.yy := [];		         # vector/array of y-values
	gsb.ff := as_boolean([]);	 # vector/array of flags (T=flagged)
	
	gsb.nyy := 0;                    # convenience
	gsb.nline := 0;                  # meaning depends on type
	gsb.xrange := [-1.1,1.1];        # default range of xx
	gsb.yrange := [-1.1,1.1];        # default range of yy

	gsb.xfixed := F;                 # if T, use xfixedrange
	gsb.yfixed := F;                 # if T, use yfixedrange
	gsb.xfixedrange := gsb.xrange;   # x-range, if xfixed=T
	gsb.yfixedrange := gsb.yrange;   # y-range, if yfixed=T

	gsb.xzero := F;                  # if T, plot the y-axis (x=0)
	gsb.yzero := F;                  # if T, plot the x-axis (y=0)
	gsb.xyzero := F;                 # if T, plot both axes

	gsb.xygrid := F;                 # if T, plot a coordinate grid 

	gsb.xratchet := F;               # if T, increase x-range only
	gsb.yratchet := F;               # if T, increase y-range only
	gsb.xratchetrange := gsb.xrange; # x-range, if xratchet=T
	gsb.yratchetrange := gsb.yrange; # y-range, if yratchet=T

	gsb.showflags := F;              # if T, indicate data-flags too
	gsb.showlegend := T;             # if T, display legend (strings)

	gsb.nflagged := 0;		 # nr of flagged points
	gsb.iscomplex := F;              # T if complex/dcomplex
	gsb.cx2real := F;		 # APPLIED cx->real conversion
	gsb.phase_unwrap := F;	         # if phase: unwrapped (continuity) 
	gsb.real2real := F;		 # APPLIED data conversion(s)...?

	gsb.stat := [=];                 # statistics record
	gsb.stat.xx := F;		 # record of xx-statistics
	gsb.stat.yy := F;		 # record of yy-statistics
	gsb.stat.ff := F;		 # record of ff-statistics

	gsb.xplotoffset := 0;            # 
	gsb.yplotoffset := 0;            # used in offset-plotting

	gsb.plotted_full := F;          # T if plotted fully
	gsb.plot_full := F;             # if T, always plot fully

	gsb.clitem_index := F;           # pointers to clickable items
	gsb.marker_index := F;           # pointers to markers.....
	gsb.graphic := [=];              # attached 'graphics' (arrow,circle) 

	gsb.special := F;                # string, e.g. 'index'
	gsb.attached := [=];             # attached user info (record)
	gsb.attached.continue := F;      # continue info for application

	ss := "xzero yzero xyzero xygrid";
	ss := [ss,"xplotoffset yplotoffset"];
	ss := [ss,"showflags showlegend"];
	gsb.display_options := ss;       # used in copy
	return F;
    }

#-------------------------------------------------------------------------------------------
# Input of the various labels: 

    public.labels := function (ref gsb, label=F, trace=F, 
			       title=F, legend=F, append2legend=F,
			       xannot=F, yannot=F,
			       xdescr=F, ydescr=F, 
			       xunit=F, yunit=F,
			       xname=F, yname=F) {
	funcname := 'datobj.labels';
	private.prof.start(funcname, text=F, tracelevel=1);
	if (!public.check_type(gsb,'any',origin='datobj.labels')) {
	    return private.prof.stop(funcname, result=F);
	}
	# Copy the inputs to the data-object (gsb), if defined (i.e. string):
	if (is_string(label)) gsb.label := label;        # object label
	if (is_string(title)) gsb.title := title;        # plot title
	if (is_string(xname)) gsb.xname := xname;        # string (default: 'x')
	if (is_string(yname)) gsb.yname := yname;        # string (default: 'y')
	if (is_string(xdescr)) gsb.xdescr := xdescr;     # root of x-axis label
	if (is_string(ydescr)) gsb.ydescr := ydescr;     # root of y-axis label
	if (is_string(xunit)) gsb.xunit := xunit;        # string (measure?)
	if (is_string(yunit)) gsb.yunit := yunit;        # string (measure?)

	# x/yannot may be string(vector) or T (automatic):
	if (is_boolean(xannot)) {
	    if (xannot) gsb.xannot := xannot;            # if T: automatic
	}
	if (is_boolean(yannot)) {
	    if (yannot) gsb.yannot := yannot;            # if T: automatic
	}
	if (is_string(xannot)) gsb.xannot := xannot;     # string vector
	if (is_string(yannot)) gsb.yannot := yannot;     # string vector
	private.check_xannot(gsb);
	private.check_yannot(gsb);

	# The legend may be a multi-line string or a legend-record:
	if (is_string(legend)) {
	    private.pgwaux.legend(gsb.legend, txt=legend, clear=T);
	} else if (is_record(legend)) {                 
	    if (legend.type=='legend') gsb.legend := legend;
	}

	# It is also possible to append text line(s) to the legend:
	if (is_string(append2legend)) {
	    public.append2legend(gsb, append2legend, trace=trace);
	}

	# Finished: Always return a record with the current label values:
	cc := [=];
	for (fname in "type intident label") cc[fname] := gsb[fname];
	for (fname in gsb.labels) cc[fname] := gsb[fname];
	if (trace) {
	    s := paste('\nCurrent labels of data-object:',gsb.type);
	    s := spaste(s,' (ident=',gsb.intident,' label=',gsb.label,'):');
	    print s;
	    for (fname in gsb.labels) {
		print '-',sprintf('%-12s:',fname),gsb[fname];
	    }
	}
	return private.prof.stop(funcname, result=cc);
    }

#--------------------------------------------------------------------------------
# Check the xy-annotation fields of the given data-object:
# If x/yannot=F: do nothing
# If x/yannot=T: generate automatically (sequence nrs)
# If x/yannot=string vector: check its length.

    private.check_xannot := function (ref gsb=F, enforce=F, trace=F) {
	s := spaste('check_xannot(',gsb.type);
	s := spaste(s,' label=',gsb.label,' enforce=',enforce,'):');
	nxx := len(gsb.xx);
	if (trace) print s,'nxx=',nxx;
	if (nxx<=0) return F;                           # .....?

	if (is_boolean(gsb.xannot)) {
	    if (enforce || gsb.xannot) {
		s1 := spaste('(xannot=',gsb.xannot,' enforce=',enforce,')');
		gsb.xannot := split(paste(seq(nxx)),' ');
		if (trace) print s,s1,'-> seq(',len(gsb.xannot),')';
	    }
	} else if (is_string(gsb.xannot)) {
	    if (len(gsb.xannot) != len(gsb.xx)) {
		print s,'xannot length mismatch:',len(gsb.xannot),nxx,'-> F';
		gsb.xannot := F;
	    }
	} else {
	    print s,'not recognised: xannot type=',type_name(gsb.xannot);
	    gsb.xannot := F;
	}
	return T;
    }
	
    private.check_yannot := function (ref gsb=F, enforce=F, trace=F) {
	s := spaste('check_yannot(',gsb.type);
	s := spaste(s,' label=',gsb.label,' enforce=',enforce,'):');

	if (gsb.type=='group') {                     # unnecessary...?
	    nyy := len(gsb.line);                    # nr of data-lines
	    if (trace) print s,'nyy=',nyy;
	    gsb.yannot := F;                         # stored in lines
	    return T;                               # always OK

	} else if (gsb.type=='slice') {
	    nyy := shape(gsb.yy)[2];                 # gsb.nrow...!
	    if (trace) print s,'nyy=',nyy,'shape(gsb.yy)=',shape(gsb.yy);

	} else {
	    print s,'not recognised gsb.type=',gsb,type;
	    return F;
	}
	if (nyy<=0) return F;                       # .....?

	if (is_boolean(gsb.yannot)) {
	    if (gsb.yannot) {                            # ignore if gsb.yannot=F
		gsb.yannot := split(paste(seq(nyy)),' ');
		if (trace) print s,'yannot=T -> seq(',len(gsb.yannot),')';
	    }
	} else if (is_string(gsb.yannot)) {
	    if (nyy != len(gsb.yannot)) {
		print s,'yannot length mismatch:',len(gsb.yannot),nyy,'-> F';
		gsb.yannot := F;
	    }
	} else {
	    print s,'not recognised: yannot type=',type_name(gsb.yannot);
	    gsb.yannot := F;
	}

	# If enforce=T, make sure that there is at least some annotation:
	if (enforce && is_boolean(gsb.yannot)) {
	    gsb.yannot := split(paste(seq(nyy)),' ');
	    if (trace) print s,'enforced: yannot -> seq(',len(gsb.yannot),')';
	}
	return T;
    }

#-----------------------------------------------------------------------------------
# Deal with the legend of the given data-object:
# NB: This function has the same arguments as pgwaux.legend();

    public.legend := function (ref gsb=F, txt=F, index=F, 
			       clear=F, title=F, trace=F) {
	if (!public.check_type(gsb,'any',origin='legend')) return F;
	return private.pgwaux.legend(gsb.legend, txt=txt, index=index, 
				     clear=clear, title=title, trace=trace);
    }

# Helper function to append text line(s) to the legend of the given gsb:
# Unnecessary???? Seems identical to .legend()...

    public.append2legend := function (ref gsb=F, txt=F, title=F, 
				      clear=F, trace=F) {
	return public.legend (gsb, txt=txt, title=title, 
			      clear=clear, trace=trace); 
    }

#--------------------------------------------------------------------------------
# Helper function to plot the main labels (title, xaxis, yaxis)

    private.plot_labels := function (ref gsb, check=T, trace=F, full=T) {
	funcname := 'datobj.plot_labels';
	private.prof.start(funcname, text=F, tracelevel=1);
	if (check) {
	    r := public.check_type(gsb,'any',origin='plot_labels');
	    if (!r) return private.prof.stop(funcname, result=F);
	}
	if (trace) print 'plot_labels(): full=',full;

	full := private.check_plot_full (gsb, full=full); 

	# Write any x-annotations (rotated) in the top-margin: 
	# NB: Can be time-consuming!
	if (full) {
	    private.check_xannot(gsb);
	    if (is_string(gsb.xannot)) {                 # ignore is boolean
		r := private.pgwaux.annotate (xx=gsb.xx, text=gsb.xannot, trace=trace, 
					      region='top_margin', group='xannot', 
					      userdata=[=], callback=F);
		if (is_fail(r)) print r;
	    }
	}

	# Construct the 'main labels' (plot-title, xlabel, ylabel):
	title := paste(gsb.title);
	if (is_boolean(title)) title := 'title';
	if (!is_boolean(gsb.xannot)) {	                # top margin used by xannot
	    private.pgwaux.legend(gsb.legend, 
				  title, title=T);	#    so use top-most legend-line,
	    title := ' ';				#    and not the top-margin
	}

	ylabel := paste(gsb.ydescr)
	if (is_boolean(ylabel)) ylabel := 'ylabel';
	ylabel := spaste(ylabel,'  (',gsb.yunit,')');

	xlabel := paste(gsb.xdescr)
	if (is_boolean(xlabel)) xlabel := 'xlabel';
	xlabel := spaste(xlabel,'  (',gsb.xunit,')');

	# Keep actually plotted label strings for later (...?):
	gsb.yaxislabel := ylabel;                        # keep for later
	gsb.xaxislabel := xlabel;                        # keep for later
	gsb.plot_title := title;                         # keep for later

	# Do the actual label writing:
	private.pgwaux.pgw().sci(1);			# default color (white)
	private.pgwaux.pgw().slw(1);			# set line width
	private.pgwaux.pgw().sch(1);			# set char height (0-1)
	if (full && gsb.type=='slice') {                 # grey-scale plot
	    private.pgwaux.pgw().lab(xlabel, ' ', title);
	    private.pgwaux.wedg (gsb.cmin, gsb.cmax, ylabel);
	} else {
	    private.pgwaux.pgw().lab(xlabel, ylabel, title);  
	}

	# Write the plot-legend (should be done last!):
	if (full && gsb.showlegend) {             
            # input legend-lines....assumed to be done elsewhere...?
	    private.pgwaux.draw_legend(gsb.legend);  
	}	

	private.pgwaux.pgw().iden();			# write username and date
	return private.prof.stop(funcname, result=T);
    }

# Check the value of gsb.plot_full. Override full if necessary...

    private.check_plot_full := function (ref gsb, full=F, trace=F) {
	if (gsb.plot_full) {                # always plot fully
	    if (trace) print 'check_plot_full(): plot_full, override full=',full;
	    full := T;                      # override       
	}
	gsb.plotted_full := full;           # store what has been done
	return full;                        # possibly overridden value
    }


#------------------------------------------------------------------
# Set the value of a specific display option for the data-object gsb:

    public.set_display_option := function (ref gsb, name=F, value=F, trace=F) {
	s := paste('datobj.set_display_option(',name,value,'):');
	if (trace) print paste(s,'gsb:',gsb.type,gsb.label);

	if (!is_record(gsb)) {
	    print s := paste(s,'gsb not a record:',type_name(gsb));
	    return F;
	} else if (!has_field(gsb,name)) {
	    print s := paste(s,'not recognised:',name);
	    return F;
	} else if (value=='toggle') {            # toggle (negate)
	    gsb[name] := !gsb[name];	      
	} else {                                 # modify value
	    gsb[name] := value;
	}
	if (trace) print paste(s,name,'->',gsb[name]);

	# Show or erase the legend:
	# NB: Should we introduce the concept of a text-data-object....? 
	if (name=='showlegend') {
	    private.pgwaux.draw_legend(gsb.legend, erase=!gsb.showlegend);
	}
	
	# Some switches depend on the state of others:
	if (name=='xyzero') {
	    gsb.xzero := gsb.yzero := gsb.xyzero;
	    s := paste(s,'  x/yzero ->',gsb.xzero,gsb.yzero);
	} else if (name=='xzero') {
	    if (!gsb.xzero) gsb.xyzero := F;
	    s := paste(s,'  xyzero ->',gsb.xyzero);
	} else if (name=='yzero') {
	    if (!gsb.yzero) gsb.xyzero := F;
	    s := paste(s,'  xyzero ->',gsb.xyzero);
	} else if (name=='xygrid') {
	    s := paste(s,'action...?');
	}

	# Adjust gsb-status if necessary (circular?):
	if (gsb.yzero) {			# if x-axis..
	    gsb.yplotoffset := 0;
	    s := paste(s,'  y-offset ->',gsb.yplotoffset);
	}
	if (trace) print s;
	gsb.modified := T;                      # enforce statistics
	return T;
    }


#-------------------------------------------------------------------------------------------
# Get a vector of indices of specific lines/rows in the given data-object:

    public.get_indices := function (ref gsb, index=F, check=T, trace=F) {
	# if (!public.check_type(gsb,'slice', origin='get_indices')) return F;
	if (gsb.type=='group') {
	    return public.group_indices (gsb, index, check=F, trace=trace);
	} else if (gsb.type=='slice') {
	    return public.slice_indices (gsb, index, check=F, trace=trace);
	} else {
	    print 'get_indices(): not recognised gsb.type=',gsb.type;
	}
	return F;
    }

#-------------------------------------------------------------------------------------------
# Modify the status of the given data-object: 

    public.modify := function (ref gsb, action=F, index=F, check=T, trace=F) {
	# if (!public.check_type(gsb,'slice', origin='modify')) return F;
	if (gsb.type=='group') {
	    return public.modify_group (gsb, action, index, check=F, trace=trace);
	} else if (gsb.type=='slice') {
	    return public.modify_slice (gsb, action, index, check=F, trace=trace);
	} else {
	    print 'modify(): not recognised gsb.type=',gsb.type;
	}
	return F;
    }

#-------------------------------------------------------------------------------------------
# Set a named option in the given data-object:

    public.set_option := function (ref gsb=F, name=F, value=F, trace=F) {
	if (!public.check_type(gsb,'any',origin='set_option')) return F;
	retval := T;                                   # return value
	for (fname in name) {                          # may be vector
	    s := paste('set_option(',gsb.type,fname,value,'):');
	    if (any(fname==gsb.settable)) {             # settable options only
		gsb[fname] := value;
		if (any(fname=='showflags') && gsb.type=='group') {
		    ii := public.group_indices(gsb);
		    for (i in ii) {
			if (trace) s := paste(s,i);
			gsb.line[i][fname] := value;
		    }
		if (trace) print s;
		}
	    } else {
		print s,'not recognised:',fname;
	    }
	}
	return retval;                                 # T/F
    }


#-------------------------------------------------------------------------------------------
# Check the type of a given data-object:

    public.check_type := function (ref gsb=F, type=F, origin=F, 
				   trace=F, check=T) {
	s := paste('check_type (',type,';',origin,'):');
	funcname := 'datobj.check_type';
	private.prof.start(funcname, text=s, tracelevel=1, hide=T);
	# return private.prof.stop(funcname, result=F);
	if (trace) print s;
	if (!check) {                                 # checking inhibited
	    return private.prof.stop(funcname, result=T);    # assume OK
	} else if (!is_record(gsb)) {
	    print s,'not a record:',type_name(gsb),':\n',gsb;;
	} else if (!has_field(gsb,'type')) {
	    print s,'gsb does not have a type-field';
	} else if (is_boolean(type) || type=='any') {
	    types := "line group slice brick textobj";
	    if (any(gsb.type==types)) {
		return private.prof.stop(funcname, result=T);
	    }
	    print s,'wrong type:',gsb.type,'!=',types;
	} else if (type=='data') {
	    types := "line group slice brick";
	    if (any(gsb.type==types)) {
		return private.prof.stop(funcname, result=T);
	    }
	    print s,'wrong type:',gsb.type,'!=',types;
	} else if (!any(gsb.type==type)) {             # type may be vector
	    print s,'wrong type:',gsb.type,'!=',type;
	} else {                                      # OK
	    return private.prof.stop(funcname, result=T);
	}
	return private.prof.stop(funcname, result=F);
    }

#--------------------------------------------------------------------------------
# Show a summary of the given data-object:

    public.summary := function (ref gsb=F, full=F, show=T) {
	if (!public.check_type(gsb,'any',origin='summary')) return F;
	s := paste(' \n \n');
	if (gsb.type=='line') {
	    s := paste(s,'Summary of 1D data-line, label=',gsb.label);
	} else if (gsb.type=='group') {
	    s := paste(s,'Summary of group of data-lines, label=',gsb.label);
	} else if (gsb.type=='slice') {
	    s := paste(s,'Summary of 2D data-slice, label=',gsb.label);
	} else if (gsb.type=='brick') {
	    s := paste(s,'Summary of nD data-brick, label=',gsb.label);
	} else if (gsb.type=='textobj') {
	    s := paste(s,'Summary of text-object, label=',gsb.label);
	} 

	# OK, recognised type of data-object:
	s1 := private.tf.summary(gsb, gsb.type, recurse=full);
	if (is_fail(s1)) print s1;                   # report any trouble
	s := paste(s,'\n',s1);
	if (show) { 
	    for (s2 in split(s,'\n')) print s2;      # print line-by-line
	}
	return s;                                    # return the string
    }

#-------------------------------------------------------------------------------
# Return a copy of the given group/slice with the specified data only:
# select may be 'visible', 'selected', 'selected_or_visible' etc

    public.copy := function (gsb, select='visible', trace=F, check=T) {
	s := paste('copy(',gsb.type,gsb.label,select,'):');
	if (trace) print s;
	funcname := 'datobj.copy';
	private.prof.start(funcname, text=s, tracelevel=1);
	if (check) {
	    r := public.check_type(gsb,"group slice", origin='copy');
	    if (!r) return private.prof.stop(funcname, result=F);
	}
	if (is_boolean(select)) select := 'visible';    #...?
	label := spaste('copy_',select);

	if (gsb.type == 'group') {
	    newgsb := public.group(label=label, copy=gsb);
	    ii := public.group_indices(gsb, select);	# selected lines
	    if (len(ii)<=0) {                           # no lines selected
		s := paste('copy: no data-lines',select,'!');
		return private.prof.stop(funcname, result=s);
	    } else if (!is_record(newgsb)) {     
		s := paste('copy group: newgsb not a record!');
		return private.prof.stop(funcname, result=s);
	    }
	    for (i in ii) {	
		line := gsb.line[i];                    # copy
		if (trace) print s,i,line.label;
		if (is_record(gsb.box)) {	        # viewport defined
		    sv := [line.xx >= gsb.box.xmin];	# selection vector
		    sv &:= [line.xx <= gsb.box.xmax];
		    line.yy := line.yy[sv];
		    line.xx := line.xx[sv];
		    line.ff := line.ff[sv];
		}
		public.append_line(newgsb, line);
	    }
	    public.modify_group(newgsb, 'deselect');

	} else if (gsb.type == 'slice') {
	    ii := public.slice_indices(gsb, select, trace=trace);
	    if (len(ii.row)<=0) {                  
		s := paste('copy: no rows selected!');
		return private.prof.stop(funcname, result=s);
	    } else if (len(ii.col)<=0) {           
		s := paste('copy: no cols selected!');
		return private.prof.stop(funcname, result=s);
	    } 
	    newgsb := public.slice (label=label, copy=gsb, 
				    xx=gsb.xx[ii.col], 
				    yy=gsb.yy[ii.col,ii.row], 
				    ff=gsb.ff[ii.col,ii.row], 
				    trace=F);
	    if (!is_record(newgsb)) {     
		s := paste('copy slice: newgsb not a record!');
		return private.prof.stop(funcname, result=s);
	    }
	    if (is_string(gsb.yannot)) {
		newgsb.yannot := gsb.yannot[ii.row];
	    } 
	    if (is_string(gsb.xannot)) {
		newgsb.xannot := gsb.xannot[ii.col];
	    } 
	    public.modify_slice(newgsb, 'deselect');
	}

	# Finishing touches:
	public.statistics(newgsb, full=T, enforce=T);    
	title := paste('copy of:',gsb.type,':',gsb.title);
	label := paste('copied');
	public.labels (newgsb, label=label, trace=trace, 
		       title=title, legend=F, append2legend=F,
		       xannot=F, xname=F, xdescr=F, xunit=F, 
		       yannot=F, yname=F, ydescr=F, yunit=F); 
	return private.prof.stop(funcname, result=newgsb);
    }


#-----------------------------------------------------------------------------
# Make a group with the statistics of the lines/rows of the given data-object:

    public.gsb2statistics  := function (ref gsb, index='selected_or_visible',
					trace=F, check=T) {
	if (check) {
	    if (!public.check_type(gsb,"group slice", 
				   origin='gsb2statistics')) return F;
	}
	s := paste('gsb2statistics(',gsb.type,gsb.label,'):');
	if (trace) print s;

	# Get record of named xyf 'vectors' containing the selected data:
	# NB: the field names of rr are the line/row labels:
	rr := public.get_xyf(gsb, selection=index, trace=trace, check=F);
	if (!is_record(rr)) return F;

	# Make a new empty group, and copy the labels of input gsb.
	newgsb := public.group(label='gsb2statistics', copy=gsb);

	# Fill a record pp with the statistics of the xyf-fields:
	pp := [=];
	ppnames := "min max mean rms";                   # field-names of pp
	for (name in ppnames) pp[name] := [];
	xannot := field_names(rr);                       # xannot of newgsb      
	xx := ind(xannot);                               # xx of newgsb 
	n := 0;
	for (fname in field_names(rr)) {
	    n +:= 1;
	    cc := private.jnm.statistarr(rr[fname].yy[!rr[fname].ff]);
	    for (name in ppnames) pp[name][n] := cc[name];
	}

	# Now make data-lines out of the statistics in pp;
	style := 'linespoints';                         # ..!
	for (name in ppnames) {
	    if (trace) print name, pp[name];
	    line := public.line(label=name, yy=pp[name], xx=xx,
				style='linespoints', trace=F);
	    public.append_line(newgsb, line, trace=trace);
	}

	# Finishing touches:
	public.statistics(newgsb, full=T, enforce=T);    
	xdescr := 'sequence nr, see also the top margin';
	title := paste('line_statistics of:',gsb.type,':',gsb.title);
	legend := paste('gsb2statistics');
	label := paste('statistics');
	public.labels (newgsb, label=label, trace=trace, 
		       title=title, legend=F, append2legend=legend,
		       xannot=xannot, xname=F, xdescr=xdescr, xunit=' ', 
		       yannot=F, yname=F, ydescr=F, yunit=F); 
	return newgsb;
    }

#-----------------------------------------------------------------------------
# Make a group with the average of the lines/rows of the given data-object:

    public.gsb2average  := function (ref gsb, index='selected_or_visible',
				     trace=F, check=T) {
	if (check) {
	    if (!public.check_type(gsb,"group slice", 
				   origin='gsb2average')) return F;
	}
	s := paste('gsb2average(',gsb.type,gsb.label,'):');
	if (trace) print s;

	# Get record of named xyf 'vectors' containing the selected data:
	rr := public.get_xyf(gsb, selection=index, commensurate=T, 
			     trace=trace, check=F);
	if (!is_record(rr)) return F;

	# Make a new empty group, and copy the labels of input gsb.
	newgsb := public.group(label='gsb2average', copy=gsb);

	# Accumulate the values of the xyf-fields in record pp:
	pp := [=];
	for (i in ind(rr)) {
	    if (i==1) xx := rr[i].xx;
	    private.jnm.statacc(pp, vv=rr[i].yy, ff=rr[i].ff);
	}
	private.jnm.statacc(pp, calc=T);                # calculate results

	# Now make data-line(s) out of the statistics in pp;
	ppnames := "mean";                              # field-names of pp
	# ppnames := "min max mean rms";                # confusing...
	for (name in ppnames) {
	    if (trace) print name,len(pp[name]);
	    line := public.line(label=name, yy=pp[name], xx=xx,
				style='lines', trace=F);
	    public.append_line(newgsb, line, trace=trace);
	}

	# Finishing touches:
	public.statistics(newgsb, full=T, enforce=T);    
	title := paste('column_statistics of:',gsb.type,':',gsb.title);
	legend := paste(len(rr),'input lines/rows:',field_names(rr));
	label := paste('average');
	public.labels (newgsb, label=label, trace=trace, 
		       title=title, legend=F, append2legend=legend,
		       xannot=F, xname=F, xdescr=F, xunit=F, 
		       yannot=ppnames, yname=F, ydescr=F, yunit=F); 
	return newgsb;
    }

#-----------------------------------------------------------------------------
# Make a line with the average of the lines/rows of the given data-object:

    public.average2line  := function (ref gsb, trace=F, check=T) {
	if (check) {
	    if (!public.check_type(gsb,"group slice", 
				   origin='average2line')) return F;
	}
	s := paste('average2line(',gsb.type,gsb.label,'):');
	if (trace) print s;

	# Get record of named xyf 'vectors' containing the selected data:
	rr := public.get_xyf(gsb, selection='visible',commensurate=T, 
			     trace=trace, check=F);
	if (!is_record(rr)) return F;

	# Accumulate the values of the xyf-fields in record pp:
	pp := [=];
	for (i in ind(rr)) {
	    if (i==1) xx := rr[i].xx;
	    private.jnm.statacc(pp, vv=rr[i].yy, ff=rr[i].ff);
	}
	private.jnm.statacc(pp, calc=T);                # calculate results

	# Now make a data-line out of the mean in pp:
	line := public.line(label='average2line', yy=pp.mean, xx=xx);
	return line;
    }

#-----------------------------------------------------------------------------
# Get a record with xyf 'vectors' of selected/visible data from slice/group:
# Each xyf-field is a record, named with the line/row/col annotation.

    public.get_xyf  := function (ref gsb, selection='visible', commensurate=F, 
				 trace=F, check=T) {
	s := paste('get_xyf(',gsb.type,gsb.label,selection,'):');
	if (trace) print s;
	funcname := 'datobj.get_xyf';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=T);
	if (check) {
	    r := public.check_type(gsb,"group slice", origin='get_xyf');
	    if (!r) return private.prof.stop(funcname, result=T);
	}

	rr := [=];                                       # output record
	ii := public.get_indices(gsb, selection, trace=trace); 
	if (is_boolean(ii)) {
	    return private.prof.stop(funcname, result=rr);
	} else if (len(ii)<=0) {
	    return private.prof.stop(funcname, result=rr);
	}

	if (gsb.type=='group') {
	    first := T;
	    for (i in ii) {
		line := gsb.line[i];                      # convenience
		fname := line.label;                      # field name
		sv := rep(T,len(line.xx));                # selection vector
		if (is_record(gsb.box)) {	          # viewport defined
		    sv := [line.xx>=gsb.box.xmin] & [line.xx<=gsb.box.xmax];
		}
		if (!any(sv)) {                           # empty
		    if (trace) print 'get_xyf: empty',fname;
		    next;                                 # ignore
		} else if (first) {
		    line1 := line;                        # keep for comparison
		    first := F;
		} else if (commensurate) {                # if required
		    if (!public.commensurate (line, line1)) {
			print 'get_xyf: lines not commensurate',fname;
			next;                             # ignore
		    }
		}
		xyf := [=];
		xyf.xx := line.xx[sv];
		xyf.yy := line.yy[sv];
		xyf.ff := line.ff[sv];
		rr[fname] := xyf;                         # append to record 
		if (trace) print s,i,'(',fname,'):';
	    }

	} else if (gsb.type=='slice') {
	    for (i in ii.row) {
		fname := gsb.yannot[i];                   # field name
		xyf := [=];
		xyf.xx := gsb.xx; 
		if (is_record(gsb.box)) {	          # viewport defined
		    xyf.yy := gsb.yy[ii.col,i];           #   row data
		    xyf.ff := gsb.ff[ii.col,i];           #   row flags
		} else {                                  # entire row
		    xyf.yy := gsb.yy[,i];                 #   row data
		    xyf.ff := gsb.ff[,i];                 #   row flags
		}
		rr[fname] := xyf;                         # append to record
		if (trace) print s,i,'(',fname,'):';
	    }

	} else {                                          # not recognised
	    return private.prof.stop(funcname, result=F);
	}
	return private.prof.stop(funcname, result=rr);    # return record
    }



#-------------------------------------------------------------------------------------------
# Return a copy with converted data (complex to real):
# NB: Use the input gsb, which is a copy already (not a ref).

    public.copy_cx2real := function (gsb, cx2real=F, unwrap=F,
				     trace=F, check=T) {
	s := paste('copy_cx2real(',gsb.type,gsb.label,cx2real,'):');
	funcname := 'datobj.copy_cx2real';
	private.prof.start(funcname, text=s, tracelevel=1);
	if (check) {
	    r := public.check_type(gsb,'data', origin='copy_cx2real');
	    if (!r) return private.prof.stop(funcname, result=F);
	}
	if (trace) print s;

	if (is_boolean(cx2real)) {
	    if (trace) print s,'not required: cx2real=',cx2real;
	    return private.prof.stop(funcname, result=gsb);

	} else if (!gsb.iscomplex) {                     # FIRST!
	    if (trace) print s,'data not complex:',gsb.iscomplex;
	    return private.prof.stop(funcname, result=gsb);

	} else if (is_string(gsb.cx2real)) {             # AFTER iscomplex!
	    if (trace) print s,'already converted:',gsb.cx2real;
	    return private.prof.stop(funcname, result=gsb);

	} else if (gsb.type=='group') {                  # recursive
	    for (i in public.group_indices(gsb)) {
		gsb.line[i] := public.copy_cx2real(gsb.line[i], 
						   cx2real=cx2real,
						   unwrap=unwrap,
						   trace=trace, check=F); 
	    }

	} else if (cx2real=='rvsi') {			# special case
	    if (gsb.type=='line') {
		gsb.xx := private.jnm.cx2real(gsb.yy, cx2real='real_part');
		gsb.yy := private.jnm.cx2real(gsb.yy, cx2real='imag_part');
		gsb.cx2real := cx2real;                  # APPLIED conv
		return private.prof.stop(funcname, result=gsb);
	    }

	} else {                                        # line/slice/brick
	    if (trace) print s,'convert:',cx2real;
	    yy := private.jnm.cx2real(gsb.yy, cx2real=cx2real,
				      unwrap=unwrap);
	    if (is_fail(yy)) {
		print s,'problem: data not changed';
		print yy;
		return private.prof.stop(funcname, result=gsb);
	    }
	    gsb.yy := yy;                                # modify the data
	}
	# Finished successfully: update the labels etc, and return gsb:
	gsb.iscomplex := F;                              # 
	gsb.cx2real := cx2real;                          # APPLIED conv...
	gsb.phase_unwrap := unwrap;                      # APPLIED conv...
	gsb.modified := T;                               # enforce statistics
	public.statistics (gsb, full=T, trace=trace, check=F);
	private.adjust_labels(gsb, cx2real);
	return private.prof.stop(funcname, result=gsb);
    }

#-------------------------------------------------------------------------------------------
# Helper function to adjust labels after conversion:

    private.adjust_labels := function (ref gsb=F, conv=F, unit=F) {
	if (gsb.type=='line') return T;                      # not for data-lines
	xdescr := gsb.xdescr;
	ydescr := paste(conv,'of',gsb.ydescr);
	xunit := gsb.xunit;
	yunit := gsb.yunit;
	if (is_string(unit)) yunit := unit;
	# Some special cases:
	if (is_boolean(conv)) {
	    # should not happen: do nothing.
	    return F;
	} else if (conv=='rvsi') {
	    xdescr := paste('real part of',gsb.ydescr);       # ydescr!
	    ydescr := paste('imag part of',gsb.ydescr);
	    xunit := gsb.yunit;
	} else if (conv=='phase' || conv=='phase_rad') {
	    ydescr := paste('phase of',gsb.ydescr);
	    yunit := 'rad';
	} else if (conv=='phase_deg') {
	    ydescr := paste('phase of',gsb.ydescr);
	    yunit := 'deg';
	}
	gsb.xdescr := xdescr;
	gsb.ydescr := ydescr;
	gsb.xunit := xunit;
	gsb.yunit := yunit;
	return T;
    }

#-------------------------------------------------------------------------------------------
# Convert the data from real to real (if required):

    public.copy_real2real := function (gsb, real2real=F, trace=F, check=T) {
	s := paste('copy_real2real(',gsb.type,gsb.label,real2real,'):'); 
	funcname := 'datobj.copy_real2real';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);
	if (check) {
	    r := public.check_type(gsb,'data', origin='copy_real2real');
	    if (!r) return private.prof.stop(funcname, result=F);
	}

	if (is_boolean(real2real)) {
	    return private.prof.stop(funcname, result=gsb);

	} else if (gsb.iscomplex) {
	    if (trace) print s,'data is complex:',gsb.iscomplex;
	    return private.prof.stop(funcname, result=gsb);

	} else if (gsb.type=='group') {                  # recursive
	    for (i in public.group_indices(gsb)) {
		public.copy_real2real(gsb.line[i], real2real=real2real, 
				      trace=trace, check=F);
	    }

	# Do actual data-conversions:
	} else if (real2real=='loglog') {
	    gsb.yy := private.jnm.real2real(gsb.yy, real2real='log');
	    gsb.xx := private.jnm.real2real(gsb.xx, real2real='log');
	} else {
	    gsb.yy := private.jnm.real2real(gsb.yy, real2real=real2real);
	}

	# Finished successfully: update the labels etc, and return gsb:
	gsb.real2real := real2real;
	gsb.modified := T;                               # enforce statistics
	public.statistics (gsb, full=T, trace=trace, check=F);
	private.adjust_labels(gsb, real2real);
	return private.prof.stop(funcname, result=gsb);
    }


#-------------------------------------------------------------------------------------------
# Plot the given data object:

    public.plot := function (ref gsb, ref pgw=F, check=T, full=T) {
	wider private;
	if (check) {
	    if (!public.check_type(gsb,'any', origin='plot')) return F;
	}
	s := paste('plot(',gsb.type,gsb.label,type_name(pgw),'):'); 

	if (is_boolean(pgw)) {                         # no pgplot-widget supplied
	    private.pgwaux.attach_pgw(trace=F);        # make sure that pga has a pgw
	    public.statistics(gsb);                     # just in case
	    private.pgwaux.env(xmin=gsb.env.xmin, xmax=gsb.env.xmax,
			       ymin=gsb.env.ymin, ymax=gsb.env.ymax,
			       just=gsb.env.just, axis=gsb.env.axis);
	}

	full := private.check_plot_full (gsb, full=full); 

	retval := F;                                    # return value
	if (gsb.type=='line') {
	    retval := public.plot_line(gsb, full=full);
	} else if (gsb.type=='group') {        
	    retval := public.plot_group(gsb, full=full);
	} else if (gsb.type=='slice') {        
	    retval := public.plot_slice(gsb, full=full);
	} else if (gsb.type=='textobj') {        
	    retval := public.plot_textobj(gsb, full=full);
	} else if (gsb.type=='brick') {        
	    retval := public.plot_brick(gsb, full=full);
	}
	if (is_fail(retval)) print retval;
	return retval;					# return converted copy
    }

#-------------------------------------------------------------------------------------------
# Calculate the statistics of the data:

    public.statistics := function (ref gsb, full=T, enforce=F, trace=F, check=T) {
	s := spaste('statistics(',gsb.type,' ',gsb.label,' full=',full,'):');
	funcname := 'datobj.statistics';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);
	if (check) {
	    r := public.check_type(gsb,'data', origin='statistics');
	    if (!r) return private.prof.stop(funcname, result=F);
	}
	if (trace) print s;

	if (enforce) {                                 # enforce new statistics
	    gsb.modified := T; 
	    full := T;
	}

	if (!gsb.modified) {                             # no changes to gsb;
	    if (trace) print s := paste(s,'not necessary....skip...');
	    return private.prof.stop(funcname, result=T);

	} else if (gsb.type=='line') {
	    gsb.stat.yy := private.jnm.statistarr(gsb.yy[!gsb.ff]);
	    gsb.stat.xx := private.jnm.statistarr(gsb.xx[!gsb.ff], 
						    range_only=!full);
	    gsb.stat.ff := private.jnm.statistarr(gsb.ff);
	    gsb.iscomplex := (is_complex(gsb.yy) || is_dcomplex(gsb.yy));
	    
	} else if (gsb.type=='group') {
	    if (full) {                                 # individual lines
		for (i in public.group_indices(gsb)) {
		    r := public.statistics(gsb.line[i], full=T,
					   enforce=enforce,
					   trace=trace, check=F);
		    if (is_fail(r)) print r;
		}
	    }
	    # Collect all line xx/yy/ff values together in 3 vectors:
	    cc := private.xxyyff_group(gsb, unflagged=T, flagged=T, visible=T);
	    if (!is_record(cc)) {	                # problem
		print 'statistics: problem with xxyyff_group() -> ',cc; 
		return private.prof.stop(funcname, result=F);
	    }
	    gsb.stat.yy := private.jnm.statistarr(cc.yy[!cc.ff]);
	    gsb.stat.xx := private.jnm.statistarr(cc.xx[!cc.ff]);
	    gsb.stat.ff := private.jnm.statistarr(cc.ff);
	    # NB: Do statistics for offset etc too...?

	} else {
	    if (gsb.type!='slice') {
		print 'statistics(): not recognised: type=',gsb.type;
		# NB: But continue anyway.....
	    }
	    gsb.iscomplex := (is_complex(gsb.yy) || is_dcomplex(gsb.yy));
	    if (is_record(gsb.box)) {                # box defined
		yy := gsb.yy[gsb.col_visible,gsb.row_visible];
		xx := gsb.xx[gsb.col_visible];
		ff := gsb.ff[gsb.col_visible,gsb.row_visible];
		gsb.stat.yy := private.jnm.statistarr(yy[!ff]);
		gsb.stat.xx := private.jnm.statistarr(xx);
		gsb.stat.ff := private.jnm.statistarr(ff);
	    } else {                                # full slice
		gsb.stat.yy := private.jnm.statistarr(gsb.yy[!gsb.ff]);
		gsb.stat.xx := private.jnm.statistarr(gsb.xx);
		gsb.stat.ff := private.jnm.statistarr(gsb.ff);
	    }
	}

	# General:
	gsb.xrange := gsb.stat.xx.range;
	gsb.yrange := gsb.stat.yy.range;
	gsb.nflagged := gsb.stat.ff.ntrue;
	# gsb.nflagged := len(gsb.ff[gsb.ff])              # alternative

	# To be used in pgw.env():
	gsb.env.xmin := gsb.stat.xx.min;
	gsb.env.xmax := gsb.stat.xx.max;
	gsb.env.ymin := gsb.stat.yy.min;
	gsb.env.ymax := gsb.stat.yy.max;
	if (gsb.type=='group') {
	    private.env_group(gsb);
	} else if (gsb.type=='slice') {
	    private.env_slice(gsb, trace=F);
	}

	# Time-saving switch:
	gsb.modified := F;

	return private.prof.stop(funcname, result=T);
    }


#========================================================================
#========================================================================
#========================================================================
# Functions dealing with 'objects': line
#========================================================================

    public.init_line := function (label=F) {
	line := private.init_common_fields ('line', label=label);;
	public.reset_line(line);
	return line;
    }

    public.reset_line := function (ref line=F) {
	line.seqnr := 0;		# its sequence nr in its group
	line.yplotoffset := 0;		# if plotting with offset
	line.xplotoffset := 0;		# if plotting with offset
	line.clitem_index := F;		# see .plot_line() yannot
	line.marker_index := F;		# see .plot_line();.....?
	return T;
    }

#-------------------------------------------------------------------------------------------
# Make a new data-line from the input one.
# If a box has been defined, only take the data within the box:

    public.copy_line := function (line, box=F, trace=F) {
	s := paste('copy_line():',line.label,'nxx=',len(line.xx));
	if (is_record(box)) {
	    sv := rep(T,len(line.xx));           # selection vector
	    sv &:= [line.xx >= box.xmin];
	    sv &:= [line.xx <= box.xmax];
	    line.xx := line.xx[sv];
	    line.yy := line.yy[sv];
	    line.ff := line.ff[sv];
	    public.statistics(line);
	    s := paste(s,'->',len(line.xx));
	}
	if (trace) print s;
	return line;
    }

#-------------------------------------------------------------------------------------------
# Define a new data-line in detail:

    public.line := function (label=F, xx=F, yy=F, ff=F, 
			     style='lines', color=F, size=F,
			     descr='descr', selcode=F, trace=F) {
	s := paste('new_line: label=',label);
	funcname := 'datobj.line';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);
	if (trace) print s;

	line := public.init_line(label=label);
	line.yannot := label;		# y-annotation label

	line.descr := descr;		# brief description
	line.selcode := selcode;	# user-supplied code (see below)

	rr := private.pgwaux.decode_plot_color (color);
	for (fname in "color cindex") {
	    line[fname] := rr[fname];   # copy
	}

	line.size := size;		# linewidth/pointsize
	rr := private.pgwaux.decode_plot_style (style);
	for (fname in "style linestyle lindex pointstyle pindex") {
	    line[fname] := rr[fname];   # copy
	}

	line.yy := yy;			# input yy vector
	line.nyy := len(yy);
	if (line.nyy<=0) {	        # zero length...?
	    return private.prof.stop(funcname, result=F);
	}
	line.iscomplex := (is_complex(line.yy) || is_dcomplex(line.yy));

	line.xx := xx;			# input xx vector
	if (is_boolean(xx)) line.xx := ind(line.yy);
	if (len(xx) != line.nyy) line.xx := ind(line.yy);

	line.ff := ff;			# input flag vector
	if (len(ff) != line.nyy) line.ff := rep(F,line.nyy);

	public.statistics (line);	# sets line.modified -> F
	return private.prof.stop(funcname, result=line);
    }

#-------------------------------------------------------------------------------------------
# Check whether two data-objects are commensurate:

    public.commensurate := function (ref gsb1, ref gsb2, check=T, origin=F) {
	if (check) {
	    if (!public.check_type(gsb1,"slice group line")) return F;
	}
	diag := ' ';
	if (gsb1.type=='line') {
	    if (!public.check_type(gsb2,gsb1.type)) return F;
	    if (gsb1.nyy != gsb2.nyy) {
		diag := spaste('nyy=',gsb1.nyy,' nyy=',gsb2.nyy);
	    } else {
		dxx := gsb1.xx - gsb2.xx;
		if (any(dxx!=0)) {
		    diag := spaste('nyy=',gsb1.nyy);
		    sv := [dxx!=0];
		    diag := spaste(diag,'ndxx<>0=',len(sv[sv]));
		}
	    }

	} else if (gsb1.type=='group') {
	    if (!public.check_type(gsb2,"group line")) {
		return F;

	    } else if (gsb2.type=='group') {
		ii := public.group_indices(gsb1, 'all');
		if (len(ii) != len(gsb2.line)) {
		    diag := spaste('ncol=',gsb1.ncol,' nyy=',gsb2.nyy);
		} else {
		    for (i in ii) {
			ok := public.commensurate(gsb1.line[i],gsb2.line[i], check=F);
			if (!ok) return F;
		    }
		}

	    } else if (gsb2.type=='line') {
		ii := public.group_indices(gsb1, 'all');
		for (i in ii) {
		    ok := public.commensurate(gsb1.line[i],gsb2, check=F);
		    if (!ok) return F;
		}
	    }

	} else if (gsb1.type=='slice') {
	    if (!public.check_type(gsb2,"slice line")) {
		return F;

	    } else if (gsb2.type=='line') {
		if (gsb1.ncol != gsb2.nyy) {
		    diag := spaste('ncol=',gsb1.ncol,' nyy=',gsb2.nyy);
		} else {
		    dxx := gsb1.xx - gsb2.xx;
		    if (any(dxx!=0)) {
			diag := spaste('ncol=',gsb1.ncol);
			sv := [dxx!=0];
			diag := spaste(diag,'ndxx<>0=',len(sv[sv]));
		    }
		}

	    } else if (gsb2.type=='slice') {
		if (gsb1.ncol != gsb2.ncol) {
		    diag := spaste('ncol=',gsb1.ncol,' ',gsb2.ncol);
		}
		if (gsb1.nrow != gsb2.nrow) {
		    diag := spaste(diag,' nrow=',gsb1.nrow,' ',gsb2.nrow);
		}
	    }
	}

	# If the diagnosis string is not empty, there is a problem:
	if (diag != ' ') {
	    s := paste(gsb1.type,gsb2.type,':');
	    print origin,': not commensurate:',s,diag;
	    return F;                                # not commensurate
	} else {
	    return T;                                # OK, commensurate
	}
    }


#---------------------------------------------------------------------------
# Helper function: return the indices of the (un)flagged (x,y) points 
# that lie within the rectangular box defined by (xrange,yrange):

    public.line_inside_box := function (ref line, xrange, yrange,
					unflagged=T, flagged=T, trace=F) {
	if (trace) {
	    s := paste('\n line_inside_box:',line.label);
	    print paste(s,'xrange=',xrange,'yrange=',yrange);
	    print 'x/yplotoffset=',line.xplotoffset,line.yplotoffset;
	}
	ii := [];                                       # return value

	# Shortcut (only if UNFLAGGED points only):
	if (!flagged) {
	    if (trace) print '-  line.yrange=',line.yrange,line.yplotoffset;
	    if ((line.yrange[1]+line.yplotoffset) > yrange[2]) return []; 
	    if ((line.yrange[2]+line.xplotoffset) < yrange[1]) return [];
	    if (trace) print '-- line.xrange=',line.xrange,line.xplotoffset;
	    if ((line.xrange[1]+line.yplotoffset) > xrange[2]) return [];
	    if ((line.xrange[2]+line.xplotoffset) < xrange[1]) return [];
	}

	sv := [(line.yy+line.yplotoffset) < yrange[2]];	# selection vector
	if (flagged && unflagged) {			# all
	    # OK
	} else if (unflagged) {				# unflagged only
	    sv &:= [!line.ff];
	} else if (flagged) {				# flagged only				
	    sv &:= [line.ff];	
	} else {					# neither (?)
	    print 'line_inside_box: none required?? :',unflagged,flagged;
	    return [];					# return empty
	}
	if (!any(sv)) return [];			# outside
	ii := ind(sv)[sv];				# indices
	if (trace) print '-   ',ii;


	xx := line.xx[sv]+line.xplotoffset;             # selection
	sv := [(line.yy[sv]+line.yplotoffset) > yrange[1]];
	if (!any(sv)) return [];			# outside
	ii := ii[sv];					# select indices
	if (trace) print '--  ',ii;
	xx := xx[sv];					# selection
	sv := [xx < xrange[2]];
	if (!any(sv)) return [];			# outside
	ii := ii[sv];					# select indices
	if (trace) print '--- ',ii;
	xx := xx[sv];					# selection
	sv := [xx > xrange[1]];
	if (!any(sv)) return [];			# outside
	ii := ii[sv];					# select indices
	if (trace) print '---*',ii;
	return ii;					# return indices
    }


#-------------------------------------------------------------------------------------------
# Plot the given line on the given pgplot-widget (pgw):

    public.plot_line := function (ref line, erase=F, check=T, trace=F, full=T) {
	s := paste('plot_line:',line.label); 
	funcname := 'datobj.plot_line';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);
	if (check) {
	    r := public.check_type(line,'line',origin='plot_line');
	    if (!r) return private.prof.stop(funcname, result=F);
	}
	if (trace) print s;

	cindex := line.cindex;				# color index (integer)
	if (erase) cindex := 0;				# background color
	private.pgwaux.pgw().sci(cindex);		# set color index

	style := line.style;				# copy
	npts := len(line.xx[!line.ff]);
	if (npts==1) style := 'points';			# change to points

	if (npts<=0) {
	    print 'plot_line:',line.label,': no unflagged points'; 

	} else if (style=='lines') {
	    if (line.selected) {                        # mark with horizontal line
		ypos := line.stat.yy.mean + line.yplotoffset;
		index := pgwaux.marker(y=ypos, color=cindex, trace=trace);
		line.marker_index := index;
		private.pgwaux.pgw().slw(5);		# AFTER marker
	    } else {
		if (!is_boolean(line.marker_index)) {   # erase any marker
		    pgwaux.draw_markers(index=line.marker_index, 
					erase=T, delete=T, trace=trace);
		    line.marker_index := F;
		}
		private.pgwaux.pgw().slw(1);		# AFTER marker
	    }
	    if (erase) private.pgwaux.pgw().slw(5);     # (kludge..)
	    private.pgwaux.pgw().sci(cindex);		# set color index
	    private.pgwaux.pgw().sls(line.lindex);	# line index (1-5)
	    private.pgwaux.pgw().line(line.xx[!line.ff]+line.xplotoffset, 
				      line.yy[!line.ff]+line.yplotoffset);

	} else if (style=='points') {
	    private.pgwaux.pgw().slw(5);		# determines marker size
	    if (erase || line.selected) private.pgwaux.pgw().slw(10); # emphasize
	    private.pgwaux.pgw().pt(line.xx[!line.ff]+line.xplotoffset, 
				    line.yy[!line.ff]+line.yplotoffset,
				    line.pindex);		# 	 

	} else if (style=='linespoints') {
	    private.pgwaux.pgw().sls(line.lindex);	# line index (1-5)
	    private.pgwaux.pgw().slw(1);		# line-width<
	    if (erase || line.selected) private.pgwaux.pgw().slw(5); # emphasize
	    private.pgwaux.pgw().line(line.xx[!line.ff]+line.xplotoffset, 
				      line.yy[!line.ff]+line.yplotoffset);
	    private.pgwaux.pgw().slw(3);		# determines marker size
	    if (erase || line.selected) private.pgwaux.pgw().slw(5); # emphasize
	    private.pgwaux.pgw().pt(line.xx[!line.ff]+line.xplotoffset, 
				    line.yy[!line.ff]+line.yplotoffset,
				    line.pindex);	# 	 

	} else if (style=='arrows') {
	    private.pgwaux.pgw().sls(line.lindex);	# line index (1-5)
	    private.pgwaux.pgw().slw(1);			# line-width
	    if (erase || line.selected) private.pgwaux.pgw().slw(5); # emphasize
	    private.pgwaux.pgw().sah(1);		# arrow head style (filled)
	    xx := line.xx;			        #  
	    yy := line.yy;			        #  
	    nyy := len(yy);
	    for (k in [ind(yy)*2]) {
		if (k>nyy) break;			# escape
		if (line.ff[k] || line.ff[k-1]) next;	# flagged
		private.pgwaux.pgw().arro(xx[k-1]+line.xplotoffset,
					  yy[k-1]+line.yplotoffset,
					  xx[k]+line.xplotoffset,
					  yy[k]+line.yplotoffset);
	    }
	}

	# Deal with flags, if any, and if enabled:
	if (full && line.showflags && (line.nflagged>0)) {	
	    private.pgwaux.pgw().slw(1);		# determines marker size
	    if (line.selected) private.pgwaux.pgw().slw(5);	# emphasize
	    if (erase) private.pgwaux.pgw().sci(0);	# background color index
	    private.pgwaux.pgw().pt(line.xx[line.ff]+line.xplotoffset, 
				    line.yy[line.ff]+line.yplotoffset, 
				    5);	                # 5 is (x)
	}

	# Draw y-annotation label (right margin):
	# NB: It would be nice if ypos take the presence of a group.box
	#     into account, but that causes a 'perverse link' between 
	#     group and its lines.... In any case, the annotations appear.
	if (full && is_boolean(line.clitem_index)) {
	    ypos := line.stat.yy.last;                  # last value (rightmost?)
	    yval := F;
	    if (line.yplotoffset != 0) {
		yval := line.stat.yy.mean;
		ypos := line.stat.yy.mean + line.yplotoffset;
	    }
	    ud := [=];                                  # userdata
	    ud.seqnr := line.seqnr;
	    ud.label := line.label;
	    index := private.pgwaux.yannot(y=ypos, yval=yval,
					   label=line.yannot, 
					   emphasize=line.selected,
					   color=line.cindex, 
					   userdata=ud,
					   callback=private.clicked_line_yannot);
	    line.clitem_index := index;
	    if (trace) print 'plot_line: yannot:',line.label,ypos,yval,'->',index;
	} else {
	    if (trace) print 'plot_line: yannot:',line.label,'skipped';
	}
	return private.prof.stop(funcname, result=T);
    }

#-------------------------------------------------------------------------------------------
# Callback function, executed when y-annotation label is clicked;
# The event is picked up in jenplot()

    private.clicked_line_yannot := function (cf=F) {
	s := paste('datobj.clicked_line_yannot(',type_name(cf),'):');
	if (!is_record(cf)) {
	    print s,'cf is not a record';
	} else if (!has_field(cf,'userdata')) {
	    print s,'cf has no field userdata';
	} else {                                        # send event
	    public.agent -> clicked_line_yannot(cf.userdata);
	}
	return T;                                       # required (T)!   
    }


#--------------------------------------------------------------------------------
# Flag the given line:

    public.flag_line := function (ref line) {
	return T;
    }

#========================================================================
#========================================================================
#========================================================================
# Functions dealing with 'objects': textobj (of lines)
# NB: For simplicity, this jus makes use of the legend-mechanism.
#========================================================================

    public.init_textobj := function (label=F) {
	textobj := private.init_common_fields ('textobj', label=label);
	public.clear_textobj(textobj);
	return textobj;
    }

    public.clear_textobj := function (ref textobj) {
	public.reset_common_fields(textobj);            # ....?
	textobj.text := ' ';
	return T;
    }

    public.textobj := function (label=F, trace=F, copy=F,
				title=F, text=F) {
	s := paste('new textobj: label=',label);
	if (trace) print s;
	funcname := 'datobj.textobj';
	private.prof.start(funcname, text=s, tracelevel=1);
	textobj := public.init_textobj(label=label);
	# private.copy_attributes (from=copy, gsb=textobj); #....?
	# private.pgwaux.reset_plot_color();              # .....?

	# It is possible to input (initial) text at creation.
	# Alternative: use jenplot.legend().
	if (is_string(text)) {
	    private.pgwaux.legend(textobj.legend, txt=text, clear=T);
	}
	return private.prof.stop(funcname, result=textobj);
    }

#--------------------------------------------------------------------------------
# Plot the given text-object:

    public.plot_textobj := function (ref textobj, trace=F, full=T, 
				   icol=1, irow=1) {
	funcname := 'datobj.plot_textobj';
	s := paste(funcname,textobj.label,'icol=',icol,'irow=',irow);
	if (trace) print s;
	private.prof.start(funcname, text=s, tracelevel=1);

	if (!public.check_type(textobj,'textobj', origin='plot_textobj')) {
	    return private.prof.stop(funcname, result=F);
	}

	private.pgwaux.bbuf('plot_textobj');		# fill command-buffer
	# NB: DO NOT ESCAPE THE ROUTINE WITHOUT EXECUTING .ebuf()!!!!!!!!!

	private.pgwaux.define_panel(icol=icol, irow=irow, trace=F,
				    axis='none');       # as it should be!
	#			    axis=-2);           # temporary....!

	textobj.showlegend := T;                        # always?
	if (textobj.showlegend) {             
	    private.pgwaux.draw_legend(textobj.legend);  
	}	

	private.pgwaux.ebuf('plot_textobj');		# execute command-buffer
	return private.prof.stop(funcname, result=T);
    }



#========================================================================
#========================================================================
#========================================================================
# Functions dealing with 'objects': group (of lines)
#========================================================================

    public.init_group := function (label=F) {
	group := private.init_common_fields ('group', label=label);;
	public.clear_group(group);
	return group;
    }

    public.clear_group := function (ref group) {
	public.reset_common_fields(group);      # ....?
	group.line := [=];
	group.line_modified := as_boolean([]);	# if T, re-calc statistics
	group.line_selected := as_boolean([]);	# if T, emphasize line
	group.line_visible := as_boolean([]);	# if F, do not plot line
	group.line_deleted := as_boolean([]);	# if T, ignore line
	group.box := F;                         # zoom box
	return T;
    }

#---------------------------------------------------------------------------------
# Make a empty new group, i.e. without any data-lines in it:

    public.group := function (label=F, trace=F, copy=F,
			      yannot=F, xannot=F, title=F, legend=F,
			      xname=F, xdescr=F, xunit=F, 
			      yname=F, ydescr=F, yunit=F) {
	s := paste('new group: label=',label);
	if (trace) print s;
	funcname := 'datobj.group';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	group := public.init_group(label=label);

	private.copy_attributes (from=copy, gsb=group);

	# After copy (because input arguments override copied values):
	public.labels(group, trace=trace, 
		      yannot=yannot, xannot=xannot, 
		      title=title, legend=legend,
		      xname=xname, xdescr=xdescr, xunit=xunit, 
		      yname=yname, ydescr=ydescr, yunit=yunit);

	private.pgwaux.reset_plot_color();  # reset color counter
	return private.prof.stop(funcname, result=group);
    }

# Copy labels and display_options  etc from 'copy' (if gsb) to gsb:

    private.copy_attributes := function (ref from, ref gsb, trace=F) {
	if (is_record(from)) {
	    if (trace) {
		s := paste('attributes copied from:',from.type,from.label);
		print s := paste(s,'to',gsb.type,gsb.label);
	    }
	    fnames := from.labels;
	    fnames := [fnames,from.display_options];
	    fnames := [fnames,'graphic'];
	    for (fname in fnames) {
		gsb[fname] := from[fname];              # copy fields
		if (trace) print fname,'->',gsb[fname];
	    }
	} else {
	    if (trace) print 'copy_attributes: from=',type_name(from),from;
	}
	return T;
    }

#-------------------------------------------------------------------------------------------
# Append the given line to the given group:

    public.append_line := function (ref group=F, ref line=F, clear=F, trace=F) {
	funcname := 'datobj.append_line';
	private.prof.start(funcname, text=F, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	if (clear || is_boolean(group)) {
	    val group := public.group(label='default', trace=trace);
	    group.descr := 'made by append_line()';
	}

	if (!public.check_type(group,'group', origin='append_line')) {
	    return private.prof.stop(funcname, result=F);
	} else if (!public.check_type(line,'line', origin='append_line')) {
	    return private.prof.stop(funcname, result=F);
	}

	i := 1 + len(group.line);       	# increment
	if (trace) print 'append_line: label=',line.label,'index=',i;
	group.line[i] := line;                  # append item
	group.nline := i;
	group.line_modified[i] := line.modified;
	group.line_selected[i] := line.selected;
	group.line_visible[i] := line.visible;
	group.line_deleted[i] := line.deleted;

	if (line.iscomplex) group.iscomplex := T;   # Complex nrs

	dx := [line.xx,0] - [0,line.xx];       # dx=xx[i+1]-xx[i]
	dx := dx[2:(len(dx)-1)];               # remove end-points
	group.env.xdir := 1;                   # assume xx is increasing
	if (all(dx<0)) {                       # xx is decreasing
	    group.env.xdir := -1;              # plot in reverse order
	    if (trace) print 'plot in reverse xx order';
	} else {
	    if (trace) print 'plot in given xx order';
	}

	group.line[i].seqnr := i;	       # sequence nr in group.line
	if (is_boolean(line.selcode)) {	       # if not supplied by user
	    group.line[i].selcode := i;	       # can be used for selection etc
	}

	# If the xx-vectors of all data-lines are identical, store it in group.xx:
	if (i==1) {                            # first data-line in group
	    group.xx := line.xx;
	} else if (len(group.xx) != len(line.xx)) {   # different length
	    # Do what?
	} else if (!all(group.xx==line.xx)) {  # same length, different value(s)
	    # Do what?
	}

	group.modified := T;                   # enforce new statistics
	return private.prof.stop(funcname, result=T);
    }


#--------------------------------------------------------------------------------
# Plot the given group:

    public.plot_group := function (ref group, trace=F, full=T, 
				   icol=1, irow=1) {
	s := paste('plot_group:',group.label,'icol=',icol,'irow=',irow);
	if (trace) print s;
	funcname := 'datobj.plot_group';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	if (!public.check_type(group,'group', origin='plot_group')) {
	    return private.prof.stop(funcname, result=F);
	}

	public.statistics(group);

	private.pgwaux.bbuf('plot_group');		# fill command-buffer
	# NB: DO NOT ESCAPE THE ROUTINE WITHOUT EXECUTING .ebuf()!!!!!!!!!

	private.pgwaux.define_panel(icol=icol, irow=irow, trace=F,
				    xmin=group.env.xmin, xmax=group.env.xmax,
				    ymin=group.env.ymin, ymax=group.env.ymax,
				    xdir=group.env.xdir, ydir=group.env.ydir,
				    just=group.env.just, axis=group.env.axis);

	# Get the indices of the visible data-lines:
	ii := public.group_indices (group, index='visible', check=F);
	nii := len(ii);

	full := private.check_plot_full (group, full=full); 

	private.pgwaux.yannot(reset=T, nslot=nii);      # reset y-annotation

	# Plot data line-by-line:
	yplotoffset := 0;
	for (i in ii) {
	    line := ref group.line[i];                  # convenience
	    if (trace) print i,'..data-line=',line.label;
	    if (group.yplotoffset != 0) {               # offset plotting
		ymean := line.stat.yy.mean;             # average of line
		line.yplotoffset := yplotoffset - ymean;
		yplotoffset -:= group.yplotoffset;      # from y=0 downwards
	    } else {
		line.yplotoffset := 0;
	    }
	    line.clitem_index := F;                     # enforce new clitem
	    line.showflags := group.showflags;          # synchronise
	    public.plot_line(line, check=F, full=full);
	}

	# Plot markers (arrows, lines) if any:
	if (group.yplotoffset == 0) {                   # only if no offset
	    for (rr in group.graphic) {
		private.pgwaux.draw_graphic(rr, trace=trace);
	    }
	}

	private.plot_labels(group, full=full);	        # plot title etc
	private.pgwaux.ebuf('plot_group');		# execute command-buffer
	return private.prof.stop(funcname, result=T);
    }



#----------------------------------------------------------------------------
# Adjust the .env parameter values of the given group, 

    private.env_group := function (ref group, trace=F) {
	wider private;
	s := paste('env_group(',group.label,'): ');

	xdir := group.env.xdir;           # -1 if xx reversed

	# Default x/yrange (may be modified below):
	if (is_record(group.box)) {
	    box_defined := T;
	    xrange := range(group.box.xmin,group.box.xmax);
	    yrange := range(group.box.ymin,group.box.ymax);
	} else {
	    box_defined := F;
	    xrange := range(group.env.xmin,group.env.xmax);
	    yrange := range(group.env.ymin,group.env.ymax);
	}
	if (trace) print s,'box=',box_defined,' xrange=',xrange,'  yrange=',yrange;

    # Special restrictions on the x-range:

	if (box_defined) {	
	    xspan := abs(xrange[2]-xrange[1]);
	    if (xdir>0) xrange[1] -:= xspan/50;   # leave room for new boxcursor
	    if (xdir<0) xrange[2] +:= xspan/50;   # xx reversed...

	} else if (group.xfixed) {	
	    xrange := group.xfixedrange;
	    if (trace) print s,'xfixed';

	} else {
	    if (group.xratchet) {		    # increase only
		if (is_boolean(group.xratchetrange)) {
		    # use current xrange
		} else {
		    xrange := range(xrange, group.xratchetrange);
		    group.xratchetrange := xrange;
		}
		if (trace) print s,'xratchet';
	    }
	    if (group.xzero) {		           # include y-axis (x=0)
		dx := abs(xrange[2]-xrange[1])/20;
		xrange := range(xrange,0+dx,0-dx);
		group.env.axis := 1;		# as axis=0, but with coordinate axes
		if (trace) print s,'xzero';
	    }
	}

    # Special restrictions on the y-range:

	if (group.yplotoffset != 0) {             # offset-plotting
	    ii := public.group_indices(group, 'visible');
	    if (len(ii)==0) {                     # no visible data-lines
		# do what?
	    # } else if (len(ii)==1) {              # only one data-line
	    #	yrange[1] := group.line[ii[1]].stat.yy.mean - group.yplotoffset;
	    #	yrange[2] := group.line[ii[1]].stat.yy.mean + group.yplotoffset;
	    #	group.yplotoffset := 0;           # set offset to zero
	    } else {
		yrange := range(-max(1,len(ii))*group.yplotoffset,group.yplotoffset);
		xspan := abs(xrange[2]-xrange[1]);
		if (xdir>0) xrange[2] +:= xspan/15;  # accomodate plotted number (ymean)
		if (xdir<0) xrange[1] -:= xspan/15;  # xx reversed...
	    }
	    if (trace) print paste(s,'yoffset=',group.yplotoffset,'nii=',len(ii));

	} else if (box_defined) {
	    # do nothing

	} else if (group.yfixed) {
	    yrange := group.yfixedrange;
	    if (trace) print s,'yfixed';

	} else {
	    if (group.yratchet) {		# increase only
		if (is_boolean(group.yratchetrange)) {
		    # use current yrange
		} else {
		    yrange := range(yrange, group.yratchetrange);
		    group.yratchetrange := yrange;
		}
		if (trace) print s,'yratchet';
	    } 
	    if (group.yzero) {		           # include y-ayis (y=0)
		dy := abs(yrange[2]-yrange[1])/20;
		yrange := range(yrange,0+dy,0-dy);
		group.env.axis := 1;	        # as axis=0, but with coordinate axes
		if (trace) print s,'yzero';
	    }
	}

	# Draw a grid:
	if (group.xygrid) {		        # draw a grid
	    group.env.axis : 2;                 # as axis=1, but with grid lines
	    if (trace) print s,'xygrid';
	}

	# Update group.env with new x/yrange:
	group.env.xmin := xrange[1];
	group.env.xmax := xrange[2];
	group.env.ymin := yrange[1];
	group.env.ymax := yrange[2];

	if (trace) print 'group.env=',group.env;
	return T;
    }

#-------------------------------------------------------------------------------------------
# Flag the given group:

    public.flag_group := function (ref line) {
	if (!public.check_type(group,'group', origin='flag_group')) return F;
	for (i in ind(group.line)[group.selected]) {
	    public.flag_line(group.line[i]);
	}
	return T;
    }



#-------------------------------------------------------------------------------------------
# Get the collected xx, yy and ff values for all relevant lines in the group:

    private.xxyyff_group := function (ref group, unflagged=T, flagged=F, 
				      visible=T, check=T, trace=F) {
	funcname := 'datobj.xxyyff_group';
	private.prof.start(funcname, text=F, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	if (check) {
	    r := public.check_type(group,'group', origin='xxyyff_group');
	    if (!r) return private.prof.stop(funcname, result=F);
	}
	if (visible) {
	    ii := public.group_indices (group, index='visible', check=F);
	} else {
	    ii := public.group_indices (group, index='undeleted', check=F);
	}

	rr := [=];					# return-record
	rr.xx := rr.yy := rr.ff := [];
	if (!flagged && !unflagged) {                   # none required
	    return private.prof.stop(funcname, result=F);
	}

	for (i in ii) {
	    rr.xx := [rr.xx, group.line[i].xx];         # append
	    rr.yy := [rr.yy, group.line[i].yy];         # append
	    rr.ff := [rr.ff, group.line[i].ff];         # append
	    if (trace) print i,'xxyyff_group: len(rr.yy)=',len(rr.yy);
	}

	if (!flagged) {
	    rr.xx := rr.xx[!rr.ff];                     # unflagged only	
	    rr.yy := rr.yy[!rr.ff];                     # unflagged only
	    rr.ff := rep(F,len(rr.yy));			# same length as xx/yy
	}	
	return private.prof.stop(funcname, result=rr);
    }    


#-------------------------------------------------------------------------------------------
# Set a limiting box (e.g. boxcursor):

    public.set_box := function (ref gsb, ref bc=F,  
				trace=F, unflagged=T, flagged=F) { 
	if (gsb.type=='group') {
	    r := public.box_group (gsb, bc=bc, trace=trace, 
				   unflagged=unflagged, flagged=flagged); 
	} else if (gsb.type=='slice') {
	    r := public.box_slice (gsb, bc=bc, trace=trace,  
				   unflagged=unflagged, flagged=flagged); 
	} else {
	    print 'box_group: not recognised:',gsb.type;
	    return F;
	}
	if (is_fail(r)) print r;
	return r;
    }

#-------------------------------------------------------------------------------------------
# Set a limiting box (e.g. boxcursor):

    public.box_group := function (ref group, ref bc=F, 
				  trace=F, unflagged=T, flagged=F) { 
	if (!public.check_type(group,'group', origin='box_group')) return F;

	iinside := [];                         # nr of lines inside box
	if (is_boolean(bc)) {
	    group.box := F;                    # disable the box
	    public.modify_group(group, 'unhide', index='undeleted');

	} else if (is_record(bc)) {
	    ii := public.group_indices (group, index='visible', check=F);
	    iinside := [];                     # lines inside the box
	    outside := [];                     # lines outside the box
	    for (i in ii) {
		jj := public.line_inside_box (group.line[i], 
					      xrange=bc.xrange, 
					      yrange=bc.yrange,
					      unflagged=unflagged, 
					      flagged=flagged, 
					      trace=trace);
		if (len(jj)>0) {               # some ponits inside box
		    iinside := [iinside,i];
		} else {                       # no points inside box
		    outside := [outside,i];
		}
	    }
	    if (len(iinside)==0) {             # no lines inside box
		# do nothing
	    } else {                           # some lines inside box
		group.box := bc;               # set new box
		if (len(outside)>0) {          # hide any lines outside box
		    public.modify_group(group, 'hide', index=outside);
		}
	    }
	    if (trace) {
		print len(iinside),'iinside=',iinside;
		print len(outside),'outside=',outside;
	    }

	} else {
	    print 'datobj.box_group: bc is not a record, but',type_name(bc);
	    return F;
	}
	public.modify_group(group,'sync');     # not really needed...?
	public.statistics(group);
	return iinside;                        # empty if none inside
    }

#-------------------------------------------------------------------------------------------
# Set a limiting box (e.g. boxcursor):

    public.box_slice := function (ref slice, ref bc=F,  
				  trace=F, unflagged=T, flagged=F) { 
	if (!public.check_type(slice,'slice', origin='box_slice')) return F;
	s := paste('box_slice(',slice.label,'): bc=',bc);
	if (trace) print s;

	ii_inside := [row=[],col=[]];          # nr of rows/cols inside box
	if (is_boolean(bc)) {
	    slice.box := F;                    # disable the box
	    public.modify_slice(slice, 'unhide');

	} else if (is_record(bc)) {            # new box 
	    ii_outside := [=];
	    svcol := [slice.xx >= bc.xmin];
	    svcol &:= [slice.xx <= bc.xmax];
	    if (!any(svcol)) {                 # no cols inside
		dx := abs(slice.xx - bc.xmin);
		i := ind(dx)[dx==min(dx)];     # the closest one
		svcol[i[1]] := T;              # at least/most one col
	    }
	    ii_outside.col := ind(svcol)[!svcol];

	    iirow := seq(slice.nrow); 
	    svrow := [iirow >= bc.ymin];
	    svrow &:= [iirow <= bc.ymax];
	    if (!any(svrow)) {                 # no rows inside
		i := max(1,as_integer(bc.ymin));
		svrow[i] := T;                 # at least one row
	    }
	    ii_outside.row := iirow[!svrow];

	    slice.box := bc;                   # set new box
	    public.modify_slice(slice, 'hide', index=ii_outside, trace=trace);

	} else {
	    print 'datobj.box_slice: bc is not a record, but',type_name(bc);
	}
	public.statistics(slice, enforce=T);   # just env...?
	return public.slice_indices(slice, 'visible', check=F, trace=trace);   
    }


#--------------------------------------------------------------------------------
# Flag the points of (selected) data-lines inside the box bc:

    public.bc2flagbox_group := function (ref group=F, bc=F, trace=F) {
	wider private;
	funcname := 'bc2flagbox_group';
	private.prof.start(funcname, text=F, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	ii := public.group_indices(group,'selected');
	modified := F;
	nflags := 0;
	for (i in ii) {
	    line := ref group.line[i];          # convenience  
	    jj := public.line_inside_box (line, 
						  bc.xrange, bc.yrange,
						  unflagged=T, flagged=F, 
						  trace=F);
	    if (len(jj)<=0) {			# none inside
		# do nothing
	    } else {				# some inside
		jj1n := [jj[1]:jj[len(jj)]];	# from first to last...!?
		line.ff[jj1n] := T;	        # flag them
		modified := T;                  # force replot
		line.modified := T;             # force new statistics
		nflags +:= len(jj1n);           # new flags (flagged=F)
		print i,': flagged:',line.label,len(jj1n),'jj1n=',jj1n;
	    }
	}
	s := paste('flagging box: new flags=',nflags,modified);
	private.message(s);
	replot := modified;                     # return value!
	return private.prof.stop(funcname, result=replot);
    }

#--------------------------------------------------------------------------------
# Flag the part of the given slice inside the box bc:

    public.bc2flagbox_slice := function (ref slice=F, bc=F, trace=F) {
	wider private;
	print funcname := 'bc2flagbox_slice';
	private.prof.start(funcname, text=F, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	print bc;
	ii := public.slice_indices(slice,'visible');
	svcol := [slice.xx>=bc.xmin] & [slice.xx<=bc.xmax];
	print 'svcol:',len(svcol),len(svcol[svcol]);
	irowmin := as_integer(bc.ymin+0.5);
	irowmax := as_integer(bc.ymax+0.5);
	print 'ii.row=',ii.row;
	print 'irowmin/max=',irowmin,irowmax;
	svrow := [ii.row>=irowmin] & [ii.row<=irowmax];
	print 'len(svcol/row)=',len(svcol),len(svrow),shape(slice.ff);
	
	modified := F;
	if (!any(svcol)) {
	    s := paste('empty svcol');
	} else if (!any(svrow)) {
	    s := paste('empty svrow: irowmin/max=',irowmin,irowmax);
	} else {
	    slice.ff[svcol,svrow] := T;         # set flags
	    modified := T;                      # force replot
	    slice.modified := T;                # force new statistics
	    slice.showflags := T;
	    ninbox := len(svcol[svcol]) * len(svrow[svrow]);
	    ntotal := len(slice.ff[slice.ff]);
	    s := paste('slice flagging: in box=',ninbox,'total=',ntotal);
	}
	print s;
	private.message(s);
	replot := modified;                     # return value!
	return private.prof.stop(funcname, result=replot);
    }

#-------------------------------------------------------------------------------------------
# Select/deselect lines in the given group according to a given criterion:
# NB: See also modify_group() for some simple selection-functions. 

    public.select_lines := function (ref group, crit=F, index=F, value=F, 
				     check=T, trace=F) {
	if (!public.check_type(group,'group', origin='select_lines')) return F;
	s := spaste('select_lines(crit=',crit,' index=',index,' value=',value,'):');
	ii := public.group_indices (group, index, check=check);
	s := paste(s,'affected lines:',len(ii),'range=',range(ii));
	if (trace) print s;

	iimod := ii;                          # return-value
	if (is_boolean(crit)) {
	    if (is_boolean(value)) {	      # T/F
		for (i in ii) group.line[i].selected := value; 
	    } else if (value=='negate') {
		for (i in ii) {
		    group.line[i].selected := !group.line[i].selected;
		}
	    } else {
		print s,'select-value not recognised:',value;
		return [];
	    }

	} else if (crit=='low_absmean') {
	    print 'select_lines(): not yet implemented:',crit;
	    return [];
	    # Copied from plot1D:
	    # crit := abs(private.item[i].ymean);
	    # irow := private.plov.irow;
	    # threshold := private.plov.yrms[irow];	# .....?
	    # select := (crit<threshold);
	    # if (currsel != select) {
	    # 	private.select_item(private.item[i], select, T);
	    # }

	} else if (crit=='same_label') {
	    print 'select_lines(): not yet implemented:',crit;
	    return [];
	    # Copied from plot1D:
	    # if (!currsel) next;			# not selected
	    # label := private.item[i].label;		# current label
	    # for (j in ind(private.item)) {
	    # 	if (!private.switch.visible[j]) next;	# skip
	    # 	if (label != private.item[j].label) next;	# different
	    # 	if (!private.item[j].selected) {	# not yet selected
	    # 	    private.select_item(private.item[j], T, T);
	    # 	}
	    # }

	} else {
	    print 'select_lines(): crit not recognised:',crit;
	    return [];
	}

	# Finish of (include modify_group(group,'sync') ....!!!
	if (len(iimod)>0) {
	} else {
	}

	return iimod;                         # indices of MODIFIED lines
    }

#-------------------------------------------------------------------------------------------
# Modify the status of specific data-lines in the given group,
# and synchronise the overall group info accordingly: 

    public.modify_group := function (ref group, action=F, index=F, 
				     check=T, trace=F) {
	s := spaste('modify_group(',action,' index=',index,'):');
	funcname := 'datobj.modify_group';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);
	ii := public.group_indices (group, index, check=check);
	s := paste(s,'affected lines:',len(ii),'range=',range(ii));
	if (trace) print s;

	iimod := ii;                                    # return-value
	if (is_boolean(ii)) {                           # problem
	    print 'modify_group(): ii is boolean: problem....';
	    return private.prof.stop(funcname, result=[]);
	} else if (len(ii)==0) {                        # empty
	    if (trace) print 'modify_group(): ii is empty';
	    return private.prof.stop(funcname, result=[]);
	} else if (action=='hide') {
	    for (i in ii) group.line[i].visible := F;
	} else if (action=='unhide') {
	    for (i in ii) group.line[i].visible := T;
	} else if (action=='delete') {
	    for (i in ii) { 
		group.line[i].deleted := T;
		group.line[i].visible := F;
		# group.line[i].ff := rep(T,len(group.line[i].ff));
	    }
	} else if (action=='undelete') {
	    for (i in ii) { 
		group.line[i].deleted := F;
		group.line[i].visible := T;
		group.line[i].modified := T;
		if (all(group.line[i].ff)) {            # only if all
		    group.line[i].ff := rep(F,len(group.line[i].ff));
		}
	    }
	} else if (action=='select') {
	    for (i in ii) group.line[i].selected := T; 
	} else if (action=='deselect') {
	    for (i in ii) group.line[i].selected := F; 
	} else if (action=='negate' || action=='toggle' ) {
	    for (i in ii) {
		group.line[i].selected := !group.line[i].selected;
	    }
	} else if (action=='showflags') {
	    for (i in ii) group.line[i].showflags := T; 
	} else if (action=='hideflags') {
	    for (i in ii) group.line[i].showflags := F; 
	} else if (action=='modified') {
	    group.modified := T;                        # enforce statistics
	    for (i in ii) group.line[i].modified := T; 
	} else if (action=='recalculate') {
	    group.modified := T;                        # enforce statistics
	    for (i in ii) group.line[i].modified := T;
	    public.statistics(group, full=T);           # recalculate statistics
	} else if (action=='sync') {                    # synchronise
	    ii := public.group_indices (group, 'all', check=check);
	} else {					# not recognised
	    print 'modify_group(): not recognised',action;
	    return private.prof.stop(funcname, result=[]);
	}

	# Synchronise the group-switches with the line-switches:
	for (i in ii) {
	    if (group.line[i].deleted) {
		# group.line[i].ff := rep(T,len(group.line[i].ff));
	    } else if (all(group.line[i].ff)) {
		group.line[i].deleted := T;
	    }
	    group.line_modified[i] := group.line[i].modified;
	    group.line_deleted[i] := group.line[i].deleted;
	    group.line_selected[i] := group.line[i].selected;
	    group.line_visible[i] := group.line[i].visible;
	}

	# NB: Should this be less automatic? 
	group.modified := T;                   # force new statistics

	# Return vector of MODIFIED lines   
	return private.prof.stop(funcname, result=iimod);
    }

# Synchronise the status of the given slice with the input slice:

    public.sync_group := function (ref group, ref input=F, index=F, trace=F) {
	s := paste('sync_group:',input.type,input.label,' index=',index);
	ii := public.group_indices(group, index=index);
	# ii := public.group_indices(group, index='all');   # temporary...
	if (trace) print s,'->',group.type,group.label,'\n ii=',ii;
	if (!public.commensurate(group,input)) {
	    print 'sync_group: groups not commensurate!';
	    return F;
	}
	ss := "ff box selected deleted visible";    # field names
	for (i in ii) {
	    for (fname in ss) {
		group.line[i][fname] := input.line[i][fname]; # copy fields
		group.line[i].modified := T;
	    }
	}	
	public.modify_group(group, 'sync');
	public.statistics(group, full=T, enforce=T);  # recalculate statistics
	return T;
    }


#-------------------------------------------------------------------------------------------
# Get a vector of indices of specific lines in the given group:

    public.group_indices := function (ref group, index=F, value=F, 
				      check=T, trace=F) {
	s := paste('group_indices(',group.type,index,'):');
	funcname := 'datobj.group_indices';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);
	if (check) {
	    r := public.check_type(group,'group', origin='group_indices');
	    if (!r) return private.prof.stop(funcname, result=F);
	}

	ii := [];				        # default: none
	if (is_boolean(index)) {
	    ii := ind(group.line);			# all (?)

	} else if (is_string(index)) {
	    if (index=='all') {
		ii := ind(group.line);
	    } else if (index=='none' || index=='empty') {
		ii := [];
	    } else if (index=='modified') {
		ii := ind(group.line)[group.line_modified];

	    } else if (index=='selected') { 
		sv := group.line_selected & group.line_visible;
		ii := ind(group.line)[sv];

	    } else if (index=='selected_or_visible') { 
		sv := group.line_selected & group.line_visible;
		if (!any(sv)) {
		    # print index,': no lines selected, taking all visible';
		    sv := group.line_visible;
		}
		ii := ind(group.line)[sv];

	    } else if (index=='visible') {
		ii := ind(group.line)[group.line_visible];
	    } else if (index=='deleted') {
		ii := ind(group.line)[group.line_deleted];
	    } else if (index=='undeleted') {
		ii := ind(group.line)[!group.line_deleted];
	    } else if (index=='labels') {
		if (is_string(value)) {
		    for (label in value) {      # value is string vector
			for (i in ind(group.line)) {
			    if (label==group.line[i].label) {
				ii := [ii,i];           # include
				break;                  # escape
			    }
			}
		    }
		} else {
		    print 'group_indices(labels): value not string',type_name(value);
		}
	    } else {
		print 'group_indices(): index not recognised',index;
		ii := [];                               # none 
	    }
	} else if (is_integer(index)) {
	    ii := index[index>0];
	    ii := ii[ii<=len(group.line)];
	}
	if (trace) print s,'-> ii=',ii;
	return private.prof.stop(funcname, result=ii);
    }


#========================================================================
# Functions dealing with 'objects': slice
#========================================================================

    public.init_slice := function (label=F) {
	slice := private.init_common_fields ('slice', label=label);;
	slice.dim := F;
	public.clear_slice(slice);
	return slice;
    }

    public.clear_slice := function (ref slice) {
	public.reset_common_fields(slice);              # ....?
	slice.cfixed := F;                              # color wedge
	slice.row_selected := as_boolean([]);
	slice.col_selected := as_boolean([]);
	slice.row_visible := as_boolean([]);
	slice.col_visible := as_boolean([]);
	slice.row_deleted := as_boolean([]);
	slice.col_deleted := as_boolean([]);
	slice.box := F;                                 # zoom box
	return T;
    }


#-------------------------------------------------------------------------------------------
# Make a new slice in detail:

    public.slice := function (label=F, xx=F, yy=F, ff=F, 
			      transpose=F, copy=F, trace=F) {
	s := paste('new slice: label=',label);
	if (trace) print s;
	funcname := 'datobj.slice';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	slice := public.init_slice(label=label);

	private.copy_attributes (from=copy, gsb=slice, trace=trace);

	# Check dimensions of data-array yy:
	ydim := shape(yy);				# e.g. [2,3];
	nyy := prod(ydim);				# 
	if (len(ydim) == 1) {				# 1D
	    if (len(xx)>1) {                            # what if xx==F?
		yy::shape := [nyy,1];                   # make 2D
	    } else {
		yy::shape := [1,nyy];                   # make 2D
	    }
	} else if (len(ydim) != 2) {			# assume 2D...?
	    print 'new_slice: should be 2D: shape=',ydim;
	    return private.prof.stop(funcname, result=F);
	}
	ydim := shape(yy);				# may have changed

	# Check flag-array ff:
	fdim := shape(ff);				# e.g. [2,3];
	nff := prod(fdim);				# 
	if (len(ff)==1) {				# not given
	    ff := array(F,ydim[1],ydim[2]);             # safe default
	} else if ((len(fdim)==1) && (nff==nyy)) {
	    ff::shape := [nff,1];                       # make 2D
	} else if (!all(fdim==ydim)) {                  # wrong shape
	    ff := array(F,ydim[1],ydim[2]);             # safe default
	}
	fdim := shape(ff);				# may have changed

	# Check coordinate-vector xx:
	xdim := shape(xx);				# expected: 1D;
	nxx := prod(xdim);				# 
	if (is_boolean(xx)) {				# xx not given
	    xx := seq(ydim[1]);                         # default: 1,2,3,...
	    if (transpose) xx := seq(ydim[2]);
	} else if (len(xdim)==1) {                      # OK, 1D expected
	    # NB: deal with the situation: nxx==1...!
	    if (nxx==ydim[1]) {
		#.............do what....?
	    } else if (nxx==ydim[2]) {
		transpose := T;                         # transpose
	    } else {
		xx := seq(ydim[1]);
	    }
	} else {                                        # ND: make 1D!
	    xx := seq(ydim[1]);                         # fastest ydim
	    if (transpose) xx := seq(ydim[2]);
	}
	xdim := shape(xx);				# may have changed
	slice.xx := xx;                     # already transposed, if required
	
	# The data-slice may be transposed:
	if (!transpose) {				# not transposed
	    slice.yy := yy;				# just copy array
	    slice.ff := ff;				# just copy array
	    # slice.xx                                  # vector, see above

	} else {                                        # transposed
	    slice.yy := array(0,ydim[2],ydim[1]);
	    slice.ff := array(F,ydim[2],ydim[1]);
	    # slice.xx                                  # see above
	    for (i in [1:ydim[1]]) {
		slice.yy[,i] := yy[i,];                 # transpose yy-array
		slice.ff[,i] := ff[i,];                 # transpose ff-array
		# slice.xx ......?                      # see above
	    };
	    ydim := shape(yy);
	    if (trace) print 'transpose: ydim=',ydim;
	}

	# Some book-keeping information:
	slice.dim := shape(slice.yy);                   # final shape
	slice.ncol := slice.dim[1];                     # nr of data-columns
	slice.nrow := slice.dim[2];                     # nr of data-rows
	slice.row_selected := rep(F,slice.nrow);        # switches
	slice.col_selected := rep(F,slice.ncol);        # switches
	slice.row_deleted := rep(F,slice.nrow);         # switches
	slice.col_deleted := rep(F,slice.ncol);         # switches
	slice.row_visible := rep(T,slice.nrow);         # switches
	slice.col_visible := rep(T,slice.ncol);         # switches
	slice.nline := slice.nrow;                      # type-independent (..?) 

	public.statistics (slice);	                # sets line.modified -> F
	return private.prof.stop(funcname, result=slice);
    }


#-------------------------------------------------------------------------------------------
# Plot the given slice (2D):

    public.plot_slice := function (ref slice, trace=F, full=T,
				   icol=1, irow=1) {
	s := paste('plot_slice:',slice.label,'icol=',icol,'irow=',irow);
	if (trace) print s;
	funcname := 'datobj.plot_slice';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);
	if (!public.check_type(slice,'slice', origin='plot_slice')) {
	    return private.prof.stop(funcname, result=F);
	}

	public.statistics(slice);

	private.pgwaux.bbuf('plot_slice');		# fill command-buffer
	# NB: DO NOT ESCAPE THE ROUTINE WITHOUT EXECUTING .ebuf()!!!!!!!!!

	# NB: Different char-size used for printing. Is reset by clear()!

	private.pgwaux.define_panel(icol=icol, irow=irow, trace=F,
				    xmin=slice.env.xmin, xmax=slice.env.xmax,
				    ymin=slice.env.ymin, ymax=slice.env.ymax,
				    just=slice.env.just, axis=slice.env.axis);

	# Color table (intensity, R, G, B, contrast, centre brightness):
	private.pgwaux.pgw().ctab([0,1], [0,1],[ 0,1], [0,1], 1, 0.5);

	# Plot the slice as a gray-scale or color image:
	if (trace) print 'imag(): cmin/max=',slice.cmin, slice.cmax, 'trm=', slice.trm;
	if (is_record(slice.box)) {
	    ii := public.slice_indices(slice,'visible');
	    yy := slice.yy[ii.col,ii.row];
	    # yy := slice.yy[slice.col_selected,slice.row_selected];
	    if (trace) print 'imag(box=T):',shape(yy),'ii=',ii;
	    private.pgwaux.pgw().imag(yy, slice.cmin, slice.cmax, slice.trm); 
	} else {
	    if (trace) print 'imag(box=F):',shape(slice.yy);
	    private.pgwaux.pgw().imag(slice.yy, slice.cmin, slice.cmax, slice.trm); 
	}

	full := private.check_plot_full (slice, full=full); 

	# Deal with flags, if any, and if enabled:
	if (full && slice.showflags && (slice.nflagged>0)) {	
	    xx := yy := [];
	    dim := shape(slice.yy);
	    for (i in [1:dim[2]]) {
		ffif := slice.ff[,i];
		if (any(ffif)) {
		    xxif := slice.xx[ffif];
		    xx := [xx,xxif];
		    yy := [yy,rep(i,len(xxif))];
		}
	    }
	    private.pgwaux.pgw().slw(1);		# determines marker size
	    # if (selected) private.pgwaux.pgw().slw(5);  # emphasize
	    private.pgwaux.pgw().sci(2);		# 2 is red
	    private.pgwaux.pgw().pt(xx, yy, 5);	        # 5 is (x)
	}

	# y-annotation along the right margin:
	slice.clitem_index := F;
	if (full) {
	    private.check_yannot(slice);
	    if (is_string(slice.yannot)) {              # ignore if boolean
		if (is_record(slice.box)) {
		    ii := public.slice_indices(slice,'visible');
		    yannot := slice.yannot[ii.row];     # selection only
		    yrow := ii.row;                     # pos of labels
		    emphasize := slice.row_selected[ii.row];
		} else {
		    yannot := slice.yannot;             # entire vector
		    yrow := ind(yannot);                # pos of labels
		    emphasize := slice.row_selected;
		}
		nrow := len(yrow);                      # nr of labels
		ud := [=];
		ud.label := slice.label;
		ud.intident := slice.intident;
		ud.iirow := yrow;             # used in clicked_slice_yannot etc
		ii := private.pgwaux.annotate(xx=yrow, text=yannot,
					      emphasize=emphasize,
					      region='right_margin',
					      userdata=ud, trace=F,
					      callback=private.clicked_slice_yannot);
		if (is_fail(ii)) print ii;
		slice.clitem_index := ii;           # attach clitem indices
	    }
	}

	private.plot_labels(slice, full=full);		# plot title etc
	private.pgwaux.ebuf('plot_slice');		# execute command-buffer
	return private.prof.stop(funcname, result=T);
    }


#----------------------------------------------------------------------------
# Adjust the .env (and .trm) parameter values of the given slice, 

    private.env_slice := function (ref slice, trace=F) {
	wider private;
	s := paste('env_slice(',slice.label,'): ');
	if (trace) print s;

	# If a box (e.g. boxcursor) has been defined, this affects slice.env:
	if (is_record(slice.box)) {                       # 
	    ii := public.slice_indices (slice, index='visible', check=F, trace=trace);
	    # xx := slice.xx[slice.col_visible];          # faster...
	    xx := slice.xx[ii.col];
	    xblc := xx[1];                                # first point
	    dx := xx[2] - xx[1];                          # x-increment 
	    xtrc := xx[len(xx)];                          # last point
	    irow1 := ii.row[1];
	    nrow := len(ii.row);
	} else {                                          # entire slice
	    xblc := slice.xx[1];
	    dx := slice.xx[2] - slice.xx[1];         # signed! 
	    xtrc := slice.xx[slice.ncol];
	    irow1 := 1;
	    nrow := slice.nrow;
	}

	# pgplot imag transformation matrix:
	slice.trm := rep(0.0,6);	
	slice.trm[1] := xblc - dx;		 
	slice.trm[2] := dx;		             # dx (signed!)
	slice.trm[4] := irow1 - 1;	             # y1
	slice.trm[6] := 1;             		     # dy

	# Range of color wedge (grayscale for the time being..):
	if (!slice.cfixed) {
	    slice.cmin := slice.stat.yy.min;         # min shade level
	    slice.cmax := slice.stat.yy.max;         # max shade level
	    if (slice.cmin==slice.cmax) {            # if identical
		dc := 0.0001;                        #   enforce different
		slice.cmin -:= dc;                   #   a little less
		slice.cmax +:= dc;                   #   a little more
	    }
	}

	slice.env.ydir := 1;
	slice.env.xdir := 1;
	if (xtrc<xblc) slice.env.xdir := -1;         # xx reversed
	slice.env.xmin := min(xblc,xtrc) - 0.5*dx;
	slice.env.xmax := max(xblc,xtrc) + 0.5*dx;
	slice.env.ymin := irow1 - 1 + 0.5;
	slice.env.ymax := irow1 - 1 + nrow + 0.5;
	if (trace) {
	    print s,'nrow=',nrow,'xblc=',xblc,'xtrc=',xtrc,'dx=',dx;
	    print 'slice.trm=',slice.trm;
	    print 'slice.env=',slice.env;
	    print 'slice.cmin/max=',slice.cmin,slice.cmax,' cfixed:',slice.cfixed;
	}

	return T;
    }


#-------------------------------------------------------------------------------------------
# Callback function, executed when y-annotation label is clicked;
# The event is picked up in jenplot.g

    private.clicked_slice_yannot := function (cf=F) {
	# print '\n datobj.clicked_slice_yannot():\n';    # clitem record
	# private.tf.summary(cf, 'cf', recurse=F, show=T);
	# inspect(cf,'cf');
	public.agent -> clicked_slice_yannot(cf.userdata);
	return T;                                       # required (T)!   
    }


#-------------------------------------------------------------------------------------------
# Modify the status of the given slice: 

    public.modify_slice := function (ref slice, action=F, index=F, 
				     check=T, trace=F) {
	s := spaste('modify_slice(',action,' index=',index,'):');
	funcname := 'datobj.modify_slice';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	ii := public.slice_indices (slice, index, check=check, trace=F);
	docol := is_integer(ii.col);                # ignore ii.col if F;      
	dorow := is_integer(ii.row);                # ignore ii.row if F
	if (trace) print s;
	s := paste('affected rows:',len(ii.row),'range=',range(ii.row));
	s := paste(s,'affected cols:',len(ii.col),'range=',range(ii.col));
	if (trace) print s;

	empty := [row=[],col=[]];                   # returned if problems
	sync := T;
	if (!is_record(ii)) {                    
	    print 'modify_slice(): ii is not a record, but',type_name(ii);
	    return private.prof.stop(funcname, result=empty);
	} else if (!has_field(ii,'row') || !has_field(ii,'col')) {
	    print 'modify_slice(): ii has wrong fields',field_names(ii);
	    return private.prof.stop(funcname, result=empty);
	} else if (len(ii.row)==0 && len(ii.col)==0) {  
	    if (trace) print 'modify_slice(): ii is empty';
	    return private.prof.stop(funcname, result=empty);

	} else if (action=='select') {
	    if (dorow) slice.row_selected[ii.row] := T;
	    if (docol) slice.col_selected[ii.col] := T;
	} else if (action=='deselect') {
	    if (dorow) slice.row_selected[ii.row] := F;
	    if (docol) slice.col_selected[ii.col] := F;
	} else if (action=='negate' || action=='toggle' ) {
	    if (dorow) slice.row_selected[ii.row] := !slice.row_selected[ii.row];
	    if (docol) slice.col_selected[ii.col] := !slice.col_selected[ii.col];

	} else if (action=='delete') {
	    if (dorow) slice.row_deleted[ii.row] := T;
	    if (docol) slice.col_deleted[ii.col] := T;
	} else if (action=='undelete') {
	    if (dorow) slice.row_deleted[ii.row] := F;
	    if (docol) slice.col_deleted[ii.col] := F;

	} else if (action=='hide') {
	    if (dorow) slice.row_visible[ii.row] := F;
	    if (docol) slice.col_visible[ii.col] := F;
	} else if (action=='unhide') {
	    if (dorow) slice.row_visible[ii.row] := T;
	    if (docol) slice.col_visible[ii.col] := T;

	} else if (action=='showflags') {
	    slice.showflags := T; 
	    sync := F;
	} else if (action=='hideflags') {
	    slice.showflags := F;
	    sync := F;

	} else if (action=='recalculate') {
	    slice.modified := T;                        # enforce statistics
	    public.statistics(slice, full=T);           # recalculate statistics

	} else if (action=='sync') {                    # synchronise
	    sync := T;
	    ii := public.slice_indices (slice, 'all', check=check, trace=F);

	} else {					# not recognised
	    print 'modify_slice(): not recognised',action;
	    return private.prof.stop(funcname, result=empty);
	}

	# Synchronise various indicators with each other:
	if (sync) {
	    for (irow in ii.row) {
		slice.row_deleted[irow] := all(slice.ff[,irow]);
	    }
	    slice.row_selected &:= !slice.row_deleted;  # vector
	    slice.col_selected &:= !slice.col_deleted;  # vector
	}

	# NB: Should this be less automatic? 
	# slice.modified := T;                   # force new statistics
	return private.prof.stop(funcname, result=ii);
    }

# Synchronise the status of the given slice with the input slice:

    public.sync_slice := function (ref slice, ref input=F, trace=F) {
	s := paste('sync_slice:',input.type,input.label);
	if (trace) print s,'->',slice.type,slice.label;
	if (!public.commensurate(slice,input)) {
	    print 'sync_slice: slices not commensurate!';
	    return F;
	}
	ss := "ff box";                             # field names
	ss := [ss,"row_selected col_selected"];
	ss := [ss,"row_visible col_visible"];
	ss := [ss,"row_deleted col_deleted"];
	for (fname in ss) {
	    slice[fname] := input[fname];           # copy slice fields
	}
	public.statistics(slice, full=T, enforce=T);  # recalculate statistics
	return T;
    }


#-------------------------------------------------------------------------------------------
# Get a vector of indices of specific rows/columns in the given slice:

    public.slice_indices := function (ref slice, index=F, check=T, trace=F) {
	s := paste('slice_indices(',slice.type,'index=',index,'):');
	if (trace) print s;
	funcname := 'datobj.slice_indices';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);
	if (check) {
	    r := public.check_type(slice,'slice', origin='slice_indices');
	    if (!r) return private.prof.stop(funcname, result=F);
	}
	
	ii := [=];                    		        # record
	ii.col := [];                                   # default: none
	ii.row := [];                                   # default: none
	if (slice.nrow<=0 || slice.ncol<=0) {           # empty slice...?
	    # return the default ii record (defined above)

	} else if (is_boolean(index)) {                 # no index given
	    ii.row := seq(slice.nrow);                  # all (?)
	    ii.col := seq(slice.ncol);                  # all (?)

	} else if (is_string(index)) {
	    if (index=='all') {
		ii.row := seq(slice.nrow);
		ii.col := seq(slice.ncol);

	    } else if (index=='none' || index=='empty') {
		ii.row := [];
		ii.col := [];

	    } else if (index=='selected' || 
		       index=='selected_or_visible' ||
		       index=='selected_or_all') {
		svcol := slice.col_visible & slice.col_selected;
		if (!any(svcol)) svcol := slice.col_visible;
		svrow := slice.row_visible & slice.row_selected;
		if (index=='selected_or_visible') {
		    if (!any(svrow)) svrow := slice.row_visible;
		} else if (index=='selected_or_all') {  # not encouraged...
		    svrow &:= !slice.row_deleted;       # exclude deleted
		    if (!any(svrow)) {
			svrow := slice.row_visible;
			svrow &:= !slice.row_deleted;   # exclude deleted
		    }
		} else {
		    svrow &:= !slice.row_deleted;       # exclude deleted
		}
		ii.row := seq(slice.nrow)[svrow];
		ii.col := seq(slice.ncol)[svcol];



	    } else if (index=='visible') {
		ii.row := seq(slice.nrow)[slice.row_visible];
		ii.col := seq(slice.ncol)[slice.col_visible];

	    } else if (index=='deleted') {
		ii.row := seq(slice.nrow)[slice.row_deleted];
		ii.col := seq(slice.ncol)[slice.col_deleted];
	    } else if (index=='undeleted') {
		ii.row := seq(slice.nrow)[!slice.row_deleted];
		ii.col := seq(slice.ncol)[!slice.col_deleted];

	    # } else if (index=='modified') {
	    #	ii.row := seq(slice.nrow)[slice.row_modified];
	    #	ii.col := seq(slice.ncol)[slice.col_modified];

	    } else {
		print 'slice_indices(): index not recognised',index;
	    }

	} else if (is_record(index)) {                  # ii-record
	    for (fname in "row col") {
		iimax := slice.nrow;
		if (fname=='col') iimax := slice.ncol;
		if (trace) print fname,'iimax=',iimax,type_name(index[fname]);
		if (!has_field(index,fname)) {
		    print s,'index-record does not have field:',fname;
		} else if (is_boolean(index[fname])) {  # selection vector
		    n := len(index[fname]);             # nr of items
		    if (n==iimax) {                     # 
			ii[fname] := seq(iimax)[index[fname]];
		    } else if (n==1) {                  # one item only
			ii[fname] := F;                 # ignore [fname]....?
		    } else {
			print s,fname,'(boolean): length mismatch:',n,iimax;
		    }
		} else if (is_integer(index[fname])) {  # selection indices
		    ii[fname] := index[fname][index[fname] >= 1];
		    ii[fname] := ii[fname][ii[fname] <= iimax];
		} else {
		    print s,fname,': not recognised index type:',type_name(index[fname]);
		}
	    }

	} else if (is_integer(index)) {                 # assume iirow....?
	    ii.row := index[index>=1];
	    ii.row := ii.row[ii.row<=slice.nrow];

	}
	if (trace) {
	    s1 := paste('ii.col: len=',len(ii.col),' range=',range(ii.col));
	    s2 := paste('ii.row: len=',len(ii.row),' range=',range(ii.row));
	    print s,'->',s1;
	    print s,'->',s2;
	}
	return private.prof.stop(funcname, result=ii);
    }


#-------------------------------------------------------------------------------------------
# Convert slice into data-group (for 1D graphics):

    public.slice2group := function (slice, trace=F) {
	funcname := 'datobj.slice2group';
	private.prof.start(funcname, text=F, tracelevel=1);
	# return private.prof.stop(funcname, result=F);
	if (!public.check_type(slice,'slice', origin='slice2group')) {
	    return private.prof.stop(funcname, result=F);
	}
	ii := public.slice_indices(slice,'selected_or_visible', 
				   check=F, trace=trace);
	if (len(ii.row)<=0) {
	    return private.prof.stop(funcname, result=F);
	}

	# Make an empty data-group, and copy the slice labels:
	newgsb := public.group (label='slice2group', copy=slice, trace=trace);

	# Make sure that yannot is a string vector of the right length:
	if (is_boolean(slice.yannot)) {                 # not defined
	    yannot := split(seq(max(ii.row)),' ');
	} else {                                        # defined
	    yannot := slice.yannot;
	}

	# Transfer in REVERSE order, to synchronise slices and offset plots:
	xx := slice.xx[ii.col];                         # selected cols only
	for (i in [len(ii.row):1]) {                    # reverse order
	    irow := ii.row[i];
	    line := public.line (label=yannot[irow], xx=xx, 
				 yy=slice.yy[ii.col,irow], 
				 ff=slice.ff[ii.col,irow]); 
	    public.append_line (newgsb, line, trace=trace);
	}

	# Finishing touches:
	public.statistics(newgsb, full=T, enforce=T);    
	# title := paste('group from:',slice.type,':',slice.title);
	title := slice.title;
	label := paste('slice2group');
	public.labels (newgsb, label=label, trace=trace, 
		       title=title, legend=F, append2legend=F,
		       xannot=F, xname=F, xdescr=F, xunit=F, 
		       yannot=F, yname=F, ydescr=F, yunit=F); 
	return private.prof.stop(funcname, result=newgsb);
    }


#-------------------------------------------------------------------------------
# Mathematical operation on rows/lines of the given slice/group gsb.
# If a 'right-hand-side' (rhs) record is given, the operation is binary.
# Otherwise it us unary (i.e. on itself);
# The result is a NEW group/slice, with the selected and modified lines/rows.

    public.mathop := function (gsb, mathop=F, aux=[=], rhs=F,
			       index='selected_or_visible', trace=F) {
	funcname := 'datobj.mathop';
	s := paste(funcname,'(', gsb.type, mathop, '):');
	if (trace) print s;
	private.prof.start(funcname, text=s, tracelevel=1);
	if (!public.check_type(gsb,"group slice", origin=funcname)) {
	    s := paste(s);
	    return private.prof.stop(funcname, result=s);
	}

	# Prepare the input record (modified by do_unop/do_binop):
	lhs := [=];                         
	for (fname in gsb.labels) lhs[fname] := gsb[fname];
	lhs.title := paste(mathop,'of',gsb.type,':',gsb.title);
	lhs.legend := spaste('unop=',mathop);

	# Check the presence of a 'right-hand side' record:
	binop := F;                                  # assume unary mathop
	if (is_record(rhs)) {                        # rhs specified
	    binop := T;                              # binary mathop
	    if (mathop=='divide') {                  # special case
		sv := [abs(rhs.yy)==0];              # avoid zeroes
		if (any(sv)) rhs.yy[sv] := 1;        # converted if complex
	    }
	    rhs.yy[rhs.ff] := sum(rhs.yy)/max(1,len(rhs.yy));  # replace with mean....?
	    s := paste('data-vector:',rhs.label);
	    s := spaste(s,' (',type_name(rhs.yy),'[',len(rhs.yy),'])');
	    lhs.legend := s;
	}

	# Get the indices of the rows/lines to be processed:
	if (gsb.type=='slice') index := 'visible';   # ......?
	ii := public.get_indices(gsb, index=index, trace=trace);
	if (len(ii)<=0) {
	    return private.prof.stop(funcname, result=F);
	} 

	# Make a new gsb, and fill it with modified rows/lines:
	if (gsb.type=='group') {
	    newgsb := public.group (label=label, copy=gsb, trace=trace);
	    pms := spaste('mathop=',mathop,': line=');
	    for (i in ii) {
		pms := paste(pms,i);
		if (trace) print pms;
		private.message(pms);
		newline := gsb.line[i];             # copy		
		for (fname in "yy xx ff") lhs[fname] := newline[fname];
		if (binop) {
		    rr := private.do_binop (mathop, lhs=lhs, rhs=rhs, trace=trace);
		} else {
		    rr := private.do_unop (mathop, lhs=lhs, aux=aux, trace=trace);
		}
		if (is_fail(rr)) {                   # trouble
		    print rr;
		    return private.prof.stop(funcname, result=F);
		} else if (is_string(rr)) {          # error message
		    return private.prof.stop(funcname, result=rr);
		} else if (is_record(rr)) {          # record
		    newline.yy := rr.yy;             # replace
		    newline.xx := rr.xx;             # replace
		} else {                             # unexpected...
		    s := paste('do_unop returned',type_name(rr));
		    return private.prof.stop(funcname, result=s);
		}
		public.append_line (newgsb, newline, trace=trace);
	    }

	} else if (gsb.type=='slice') {
	    newgsb := gsb;                           # just copy
	    pms := spaste('mathop=',mathop,': row=');
	    for (irow in ii.row) {
		pms := paste(pms,irow);
		if (trace) print pms;
		private.message(pms);
		lhs.yy := newgsb.yy[,irow];
		lhs.xx := newgsb.xx; 
		lhs.ff := newgsb.ff[,irow];
		if (binop) {
		    rr := private.do_binop (mathop, lhs=lhs, rhs=rhs, trace=trace);
		} else {
		    rr := private.do_unop (mathop, lhs=lhs, aux=aux, trace=trace);
		}
		if (is_fail(rr)) {                   # trouble
		    print rr;
		    return private.prof.stop(funcname, result=F);
		} else if (is_string(rr)) {          # error message
		    return private.prof.stop(funcname, result=rr);
		} else if (is_record(rr)) {          # record
		    newgsb.yy[,irow] := rr.yy;
		    newgsb.xx := rr.xx;
		} else {                             # unexpected...
		    s := paste('do_unop returned',type_name(rr));
		    return private.prof.stop(funcname, result=s);
		}
	    }
	}
	public.modify(newgsb, 'deselect');

	# Finishing touches:
	public.statistics(newgsb, full=T, enforce=T);    
	label := spaste('mathop=',mathop);
	public.labels (newgsb, label=label, trace=trace, 
		       title=rr.title, legend=F, 
		       append2legend=rr.legend,
		       xannot=rr.xannot, xname=rr.xname, 
		       xdescr=rr.xdescr, xunit=rr.xunit, 
		       yannot=rr.yannot, yname=rr.yname, 
		       ydescr=rr.ydescr, yunit=rr.yunit);
	return private.prof.stop(funcname, result=newgsb);
    }


# Helper function that does the actual unary operation on a 1D vector.
# The relevant input info is in the records lhs and aux.
# The routine returns a modified copy of input record lhs.

    private.do_unop := function (unop=F, lhs=F, aux=[=], trace=F) {
	funcname := 'do_unop';
	s := paste(funcname,'(',unop,'aux=',aux,'):');
	if (trace) print s;
	if (unop=='smooth') {
	    if (!has_field(aux,'ww')) aux.ww := [1,1,1];
	    lhs.yy := private.jnm.smooth (yy=lhs.yy, ww=aux.ww);
	    lhs.legend := spaste(lhs.legend,', filter=',aux.ww);
	} else if (unop=='differentiate') {
	    lhs.yy := private.jnm.diff1D (yy=lhs.yy, xx=lhs.xx);
	} else if (unop=='integrate') {
	    lhs.yy := private.jnm.integrate (yy=lhs.yy, xx=lhs.xx);
	} else if (any(unop=="fft_forward fft_backward")) {
	    if (unop=='fft_forward') {
		lhs.ydescr := paste('forward fft of',lhs.ydescr);
		dir := 1;
	    } else {
		lhs.ydescr := paste('backward fft of',lhs.ydescr);
		dir := -1;
	    }
	    rr := private.jnm.fft (yy=lhs.yy, xx=lhs.xx, dir=dir);
	    lhs.yy := rr.yy;
	    lhs.xx := rr.xx;
	    lhs.xdescr := paste('fft freq');
	    lhs.xname := spaste('1/',lhs.xname);
	    lhs.xunit := spaste('1/',lhs.xunit);
	    lhs.yname := 'value';
	    lhs.yunit := ' ';
	} else if (unop=='autocorr') {
	    rr := private.jnm.autocorr (yy=lhs.yy, xx=lhs.xx);
	    lhs.yy := rr.yy;
	    lhs.xx := rr.xx;
	    lhs.xdescr := paste(lhs.xdescr,'shift');
	    lhs.ydescr := paste('autocorr of',lhs.ydescr);
	    lhs.yname := 'cc';
	    lhs.yunit := ' ';
	} else if (unop=='fit_poly') {
	    if (!has_field(aux,'ndeg')) aux.ndeg := 2;
	    rr := private.jnm.fit_poly (yy=lhs.yy, xx=lhs.xx, ff=lhs.ff,
					ndeg=aux.ndeg, eval=T);
	    lhs.yy := rr.yyeval;
	} else if (unop=='subtract_poly') {
	    if (!has_field(aux,'ndeg')) aux.ndeg := 2;
	    rr := private.jnm.fit_poly (yy=lhs.yy, xx=lhs.xx, ff=lhs.ff,
					ndeg=aux.ndeg, eval=T);
	    lhs.yy := rr.yydiff;

	} else if (unnop=='dummy_unop') {
	    return paste(s,'binop: not yet implemented:',unop);
	} else {
	    s := paste('do_unop: not recognised:',unop);
	    return s;
	}
	return lhs;                     # modified copy of input record lhs
    }


# Helper function that does the actual binary operation on a 1D vector.
# The relevant input info is in the records lhs, rhs and aux.
# The routine returns a modified copy of input record lhs.

    private.do_binop := function (binop=F, lhs=F, rhs=F, aux=F, trace=F) {
	funcname := 'do_binop';
	s := paste(funcname,'(',binop,'aux=',aux,'):');
	if (trace) print s;
	if (binop=='subtract') {
	    lhs.yy -:= rhs.yy;
	    lhs.legend := paste('subtracted by:',lhs.legend);
	    lhs.ydescr := paste('relative',lhs.ydescr);
	} else if (binop=='divide') {
	    lhs.yy /:= rhs.yy;
	    lhs.yunit := spaste(lhs.yunit,'/',rhs.yunit);
	    lhs.legend := paste('divided by:',lhs.legend);
	    lhs.ydescr := paste('normalised',lhs.ydescr);
	} else if (binop=='add') {
	    lhs.yy +:= rhs.yy;
	    lhs.legend := paste('added to:',lhs.legend);
	} else if (binop=='multiply') {
	    lhs.yy *:= rhs.yy;
	    lhs.yunit := spaste(lhs.yunit,'*',rhs.yunit);
	    lhs.legend := paste('multiplied by:',lhs.legend);
	} else if (binop=='crosscorr') {
	    rr := private.jnm.crosscorr (yy1=lhs.yy, yy2=rhs.yy,
					 xx=lhs.xx);
	    lhs.legend := paste('cross-correlated with:',lhs.legend);
	    lhs.xdescr := paste(lhs.xdescr,'shift');
	    lhs.ydescr := paste('crosscorr of',lhs.ydescr);
	    lhs.yname := 'cc';
	    lhs.yunit := ' ';
	} else if (binop=='convolve') { # NB: commensurate not required!
	    rr := private.jnm.convolve (yy1=lhs.yy, yy2=rhs.yy,
					xx=lhs.xx);
	    lhs.legend := paste('convolved with:',lhs.legend);
	} else {
	    return paste(s,'binop: not recognised:',binop);
	}
	return lhs;                     # modified copy of input record lhs
    }

#-------------------------------------------------------------------------------------------
# Get a data-line from the given group/slice:

    public.get_line := function (gsb, index='selected', trace=F) {
	funcname := 'datobj.get_line';
	s := paste(funcname,'(',gsb.type,index,'):');
	if (trace) print s;
	private.prof.start(funcname, text=s, tracelevel=1);
	if (!public.check_type(gsb,"group slice", origin=funcname)) {
	    return private.prof.stop(funcname, result=F);
	} 
	ii := public.get_indices(gsb, index=index, trace=trace);
	if (gsb.type=='group') {
	    if (len(ii)<=0) return private.prof.stop(funcname, result=F);
	    line := gsb.line[ii[1]];
	} else if (gsb.type=='slice') {
	    if (len(ii.row)<=0) return private.prof.stop(funcname, result=F);
	    line := public.row2line(gsb, ii.row[1], trace=trace);
	}
	if (trace) print s,'->',line.type,line.label;
	return private.prof.stop(funcname, result=line);
    }

#-------------------------------------------------------------------------------------------
# Convert a slice row into data-line (for clipboard):

    public.row2line := function (slice, irow=F, trace=F) {
	funcname := 'datobj.row2line';
	s := paste(funcname,'(',slice.type,'irow=',irow,'):');
	if (trace) print s;
	private.prof.start(funcname, text=F, tracelevel=1);
	# return private.prof.stop(funcname, result=F);
	if (!public.check_type(slice,'slice', origin=funcname)) {
	    return private.prof.stop(funcname, result=F);
	} else if (irow<=0 || irow>slice.nrow) {
	    return private.prof.stop(funcname, result=F);
	}

	label := spaste('row_',irow);
	if (is_string(slice.yannot)) label := slice.yannot[irow];

	line := public.line (label=label, 
			     xx=slice.xx, 
			     yy=slice.yy[,irow], 
			     ff=slice.ff[,irow]); 
	return private.prof.stop(funcname, result=line);
    }

#-------------------------------------------------------------------------------------------
# Convert group into a slice (for 2D plotting)    
# If lines not commensurate, they are interpolated and padded........

    public.group2slice := function (ref group) {
	funcname := 'datobj.group2slice';
	private.prof.start(funcname, text=F, tracelevel=1);
	# return private.prof.stop(funcname, result=F);
	if (!public.check_type(group,'group', origin='group2slice')) {
	    return private.prof.stop(funcname, result=F);
	}
	print 'group2slice: not implemented yet';
	return private.prof.stop(funcname, result=F);

	slice := public.slice(label='group2slice');
	return private.prof.stop(funcname, result=slice);
    }


#========================================================================
# Functions dealing with 'objects': brick
#========================================================================

    public.init_brick := function (label=F) {
	brick := private.init_common_fields ('brick', label=label);;
	return brick;
    }


    public.brick := function (label=F, yy=F, ff=F, xx=F) {
	brick := public.init_brick(label=label);
	# brick.nline := ...;
	return brick;
    }


#========================================================================
# Getting data-values in an organised way, and formatting them:
#========================================================================

#-------------------------------------------------------------------------------------------
# Get specific (ii,jj,kk) data-value(s) from the given data-object gsb:
# NB: Also used by format_point_descr() and format_line_descr() below. 

    public.data_value := function (ref gsb, ii=F, jj=F, kk=F, 
				   check=T, trace=F) {
	if (check) {
	    if (!public.check_type(gsb,'data', origin='data_value')) return F;
	}
	cc := [=];                              # return-record
	cc.type := gsb.type;
	cc.label := gsb.label;
	cc.ii := ii;
	cc.jj := jj;
	cc.kk := kk;
	cc.iirange := [1,len(gsb.xx)];
	cc.jjrange := [1,gsb.nline];
	cc.kkrange := [0,0];
	for (fname in "xx yy zz ff error") cc[fname] := F;
	
	# Check the various coordinates:
	for (fname in "ii jj") {                # later: add kk
	    vrange := cc[spaste(fname,'range')];
	    if (is_boolean(cc[fname])) {
		cc.error := paste(fname,'is boolean!');
	    } else {
		cc[fname] := cc[fname][cc[fname]>=vrange[1]];
		cc[fname] := cc[fname][cc[fname]<=vrange[2]];
		if (len(cc[fname])==0) {
		    cc[fname] := F;
		    cc.error := paste(fname,'is empty or out-of-range!');
		}
	    }
	}

	# read the x-value(s), if possible
	if (!is_boolean(cc.ii)) cc.xx := gsb.xx[cc.ii];

	# Read the y-value(s), if possible:
	if (is_boolean(cc.ii)) {
	    # do nothing
	} else if (gsb.type=='line') {
	    cc.yy := gsb.yy[cc.ii];
	    cc.ff := gsb.ff[cc.ii];
	} else if (is_boolean(cc.jj)) {
	    # do nothing
	} else if (gsb.type=='group') {
	    cc.xx := cc.yy := [];
	    cc.ff := as_boolean([]);
	    for (j in jj) {
		cc.yy := [cc.yy,gsb.line[j].yy[cc.ii]];
		cc.xx := [cc.xx,gsb.line[j].xx[cc.ii]];
		cc.ff := [cc.ff,gsb.line[j].ff[cc.ii]];
	    }
	} else if (gsb.type=='slice') {
	    cc.yy := gsb.yy[cc.ii, cc.jj];
	    cc.ff := gsb.ff[cc.ii, cc.jj];
	    cc.xx := array(cc.xx,len(cc.ii),len(cc.jj));
	} else if (is_boolean(cc.kk)) {
	    # do nothing
	} else if (gsb.type=='brick') {
	    cc.error := 'brick not supported yet';
	    cc.jj := F;
	}

	return cc;                              # record
    }

#------------------------------------------------------------------------------
# Format the vital statistics of the specified part of a data-line/row/col:

    public.format_line_descr := function (ref gsb, icol=F, rowline=F, box=F,
					  visible=T, check=T, trace=F) {
	if (check) {
	    if (!public.check_type(gsb,'data', 
				   origin='format_line_descr')) return F;
	}

	ii := F;
	if (gsb.type=='line') {
	    s := spaste(gsb.label,':');
	    if (visible && is_record(box)) {      # group-box defined
		sv := rep(T,len(gsb.xx));         # all 
		sv &:= [gsb.xx >= box.xmin];      # selection vector
		sv &:= [gsb.xx <= box.xmax];      # selection vector
		yy := gsb.yy[sv];
		ff := gsb.ff[sv];
		ii := ind(sv)[sv];                # selected indices
	    } else {
		yy := gsb.yy;
		ff := gsb.ff;
	    }

	} else if (gsb.type=='group') {
	    iline := rowline;
	    if (is_boolean(iline)) {
		return paste('iline is boolean!');
	    } else if (iline<=0 || iline>len(gsb.line)) {
		return paste('iline out of range!',iline,len(gsb.line));
	    } else if (visible) {                 # visible points only
		s := public.format_line_descr (gsb.line[iline], 
					       visible=T, box=gsb.box, 
					       check=F, trace=trace);
		return spaste('line=',iline,': ',s);
	    } else {                              # all points
		s := public.format_line_descr (gsb.line[iline], visible=F, 
					       check=F, trace=trace);
		return spaste('line=',iline,': ',s);
	    }

	} else if (gsb.type=='slice') {
	    irow := rowline;
	    s := spaste('row=',irow,': ');
	    if (is_string(gsb.yannot)) s := spaste(s,gsb.yannot[irow],': ');
	    if (visible && is_record(gsb.box)) {      # group-box defined
		sv := rep(T,len(gsb.xx));             # all 
		sv &:= [gsb.xx >= gsb.box.xmin];      # selection vector
		sv &:= [gsb.xx <= gsb.box.xmax];      # selection vector
		yy := gsb.yy[sv,irow];
		ff := gsb.ff[sv,irow];
		ii := ind(sv)[sv];                    # selected indices
	    } else {
		yy := gsb.yy[,irow];
		ff := gsb.ff[,irow];
	    }

	} else {
	    return s := paste('gsb.type not recognised:',gsb.type);
	}

	nyy := len(yy);
	nflagged := len(ff[ff]);
	cc := private.jnm.statistarr(yy[!ff]);
	if (is_integer(ii)) {
	    s := spaste(s,'(i=',min(ii),'-',max(ii),'):');
	} else {
	    s := spaste(s,'(i=1-',nyy,'):');
	}
	s := paste(s,sprintf(' mean=%.3g',cc.mean));
	s := paste(s,sprintf(' rms=%.3g',cc.rms));
	s := paste(s,sprintf(' range=%.3g<->%.3g',cc.min,cc.max));
	if (nflagged>0) {
	    s := spaste(s,' ff=',nflagged);
	    fp := as_integer(100*nflagged/nyy);        # percentage
	    s := spaste(s,'(',fp,'%)');
	}
	return s;                                # return string
    }

#--------------------------------------------------------------------------
# Return a string with the description of the flags:

    public.format_flag_descr := function (ref gsb=F, trace=F) {
	s := paste('format_flag_descr(',gsb.type,'):');
	if (trace) print s;

	s := paste(gsb.type,'flags:');
	nff := nTrue := nFalse := 0;
	nline := nvis := ndel := nsel := 0;
	if (gsb.type=='group') {
	    for (i in ind(gsb.line)) {
		line := ref gsb.line[i];        # convenience
		if (line.selected) nsel +:= 1;
		if (line.visible) nvis +:= 1;
		if (line.deleted) {
		    ndel +:= 1;
		    next;                       # skip
		}
		ff := line.ff;
		nff +:= len(ff);
		nTrue +:= len(ff(ff));
		nFalse +:= len(ff(!ff));
		nline +:= 1;
	    }
	    s := spaste(s,' n=',nline);
	    s := spaste(s,' (deleted=',ndel,')');

	} else if (gsb.type=='slice') {
	    ff := slice.ff;
	    nff := len(ff);
	    nTrue := len(ff(ff));
	    nFalse := len(ff(!ff));
	}

	s := spaste(s,' flagged=',nTrue,'/',nff);
	fp := as_integer(100*nTrue/max(1,nff)); # percentage
	s := spaste(s,'(',fp,'%)');
	if (trace) print s;
	return s;                               # return string
    }

#--------------------------------------------------------------------------
# Return a string with the description of the given data-point:

    public.format_point_descr := function (ref gsb=F, colpnt=F, rowline=F, trace=F) {
	s := paste('format_point_descr(',gsb.type,colpnt,rowline,'):');
	if (trace) print s;

	if (gsb.type=='group') {
	    iline := rowline;
	    ipnt := colpnt;
	    if (is_boolean(rowline)) {             # none close enough
		# Just use the string s above
	    } else {                                # show closest point
		line := ref gsb.line[iline];     # convenience
		color := line.color;
		s := spaste(line.label,': ');
		s := spaste(s,' (',line.color,'): '); 
		if (is_string(gsb.xannot)) {
		    s := spaste(s,' (\'',gsb.xannot[ipnt],'\') ');
		} else {
		    s := spaste(s,'   ',gsb.xname,'=');
		    x := line.xx[ipnt];
		    fmt := public.make_fmt(line.xx, trace=F);
		    s := spaste(s,sprintf(fmt,x),' (',gsb.xunit,') ');
		}
		s := spaste(s,'  ',gsb.yname,'=');
		y := line.yy[ipnt];
		# fmt := public.make_fmt(line.yy, trace=F);
		fmt := '%.3g';  
		s := spaste(s,sprintf(fmt,y),' (',gsb.yunit,') ');
		if (line.ff[ipnt]) {
		    s := paste(s,' (flagged) ');
		}
		s := spaste(s,'   [i=',ipnt,']');
	    }

	} else if (gsb.type=='slice') {
	    irow := rowline;
	    icol := colpnt;
	    s1 := spaste('   [icol=',icol,' irow=',irow,']');
	    if (irow<=0 || irow>gsb.nrow) {             # in plot-window margin
		s := paste(s1,'irow out of range');
	    } else if (icol<=0 || icol>gsb.ncol) {      # in plot-window margin
		s := paste(s1,'icol out of range');
	    } else {
		if (is_string(gsb.yannot)) {
		    s := spaste(gsb.yannot[irow],': ');
		} else {
		    s := spaste('..',':  ');
		}
		y := gsb.yy[icol,irow];
		x := gsb.xx[icol];
		s := spaste(s,'   ',gsb.xname,'=');
		fmt := public.make_fmt(gsb.xx, trace=F);
		s := spaste(s,sprintf(fmt,x),' (',gsb.xunit,') ');
		# s := spaste(s,'   ',gsb.yname,'=');
		s := spaste(s,'   value=');
		# fmt := public.make_fmt(gsb.yy, trace=F);
		fmt := '%.3g';  
		s := spaste(s,sprintf(fmt,y),' (',gsb.yunit,') ');
		if (gsb.ff[icol,irow]) {
		    s := paste(s,' (flagged) ');
		}
		s := paste(s,s1);
	    }
	}
	if (trace) print s;
	return s;                                  # return string
    }

# Helper function to make a suitable format-string for sprintf();
# The idea is to give sufficient resolution to just distinguish the
# different values of the given vector xx;

    public.make_fmt := function (xx=F, trace=F) {
	ng := 3;                                   # default
	fmt := spaste('%.',ng,'g');                # default
	if (is_boolean(xx)) return fmt;
	nxx := len(xx);
	if (nxx<=0) return fmt;
	xrange := range(xx);
	dx := abs(xrange[2]-xrange[1])/nxx;        # mean incr
	if (dx==0) return fmt;
	xabsmax := max(abs(xrange));
	ng := 1 + as_integer(log(xabsmax/dx));
	ng := min(ng,10);                          # limit
	fmt := spaste('%.',ng,'g');                
	if (trace) print 'make_fmt: dx=',dx,' xabsmax=',xabsmax,'->',fmt;
	return fmt;
    }


#=======================================================================
# Finished. Initialise and return the public interface:

    private.init();				# initialise
    return ref public;				# ref?

};				# closing bracket of jenplot_datobj
#=======================================================================




#=========================================================
test_jenplot_datobj := function (iexp=1, full=F, plot=T, trace=F) {
    private := [=];
    public := [=];
    print '\n\n\n\n **** test_jenplot_datobj(iexp=',iexp,')';

    include 'jenplot_pgwaux.g';
    include 'inspect.g';

    private.show_common := function (ref gsb, full=F, plot=F) {
	# print 'test: show_common(',type_name(gsb),'full=',full,')';
	if (is_fail(gsb)) print gsb;
	if (full) inspect(gsb,spaste(gsb.type));
	s := dob.summary(gsb, full=F, show=T);
	if (is_fail(s)) print s;
	if (plot) dob.plot(gsb);
	return gsb
    }


    global dob;
    private.pga := jenplot_pgwaux();
    dob := jenplot_datobj(private.pga);
    print 'created global symbol dob:    r := dob.xxx()';


    retval := ref public;              # return value
    if (iexp==1) {
	
    } else if (iexp==2) {

    } else if (iexp=='line') {
	line := dob.line(label='iexp=1',
			 yy=[1:10], xx=F, ff=F,
			 style='lines', color=F, size=F,
			 selcode=F, descr='descr', 
			 trace=trace);
	retval := private.show_common(line, full=full, plot=plot);

    } else if (iexp=='group') {
	xannot := F;
	xannot := "a b c d e f g";
	group := dob.group(label='iexp=1', trace=trace);
	dob.labels(group, label=F, 
		   title='the rain in spain',
		   legend="aaa bbb ccc",
		   xdescr='xxx', xunit='xun', 
		   ydescr='yyy', yunit='yun', 
		   xannot=xannot, yannot=F,
		   trace=trace);
	dob.set_option(group,'showflags',T);
	dob.set_option(group,'showlegend',T);
	for (i in [1:5]) {
	    yy := [i:10];
	    ff := array([T,F,F,F],len(yy));
	    line := dob.line(label=spaste('line',i),
			     style='linespoints',
			     xx=F, yy=yy, ff=ff, 
			     trace=trace);
	    dob.append_line(group, line=line, trace=trace);
	}
	r := dob.statistics(group, full=T, trace=trace);  # only needed for group!!
	if (is_fail(r)) print r;
	retval := private.show_common(group, full=full, plot=plot);

	
    } else if (iexp=='slice') {
	ncol := 5;                        # nr of 'lines'
	nrow := 100;                       # nxx
	yy := array(1.0*seq(ncol*nrow),nrow,ncol);
	xx := [1:nrow]*0.1;
	ff := array([T,F,F,F,F],nrow,ncol);
	yannot := split(paste(seq(ncol)),' ');
	print 'ncol(horizontal)=',ncol,'nrow(vertical)=',nrow;
	slice := dob.slice(label='iexp=1', yy=yy, xx=xx, ff=ff,
			   transpose=F, trace=trace);
	dob.labels(slice, label=F, 
		   title='the rain in spain',
		   legend="aaa bbb ccc",
		   xdescr='xxx', xunit='xun', 
		   ydescr='yyy', yunit='yun', 
		   xannot=F, yannot=yannot,
		   trace=trace);
	dob.set_option(slice,'showflags',T);
	dob.set_option(slice,'showlegend',T);
	retval := private.show_common(slice, full=full, plot=plot);


    } else if (iexp=='brick') {
	brick := dob.brick(label='iexp=1', yy=[1:10], trace=trace);
	retval := private.show_common(brick, full=full, plot=plot);

    } else {
	print 'not recognised: iexp=',iexp;

    }

    return retval;
};






#===========================================================
#===========================================================

# test_jenplot_datobj();		# run test-routine
# inspect(jenplot_datobj(),'jenplot_datobj');# create and inspect

#===========================================================
# Remarks and things to do:
#================================================================


