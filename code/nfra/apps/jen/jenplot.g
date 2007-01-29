# jenplot.g: A reasonably able plotting tool.

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
# $Id: jenplot.g,v 19.0 2003/07/16 03:38:34 aips2adm Exp $

#---------------------------------------------------------

pragma include once
# print 'include jenplot.g  w01sep99';

include 'jenguic.g';		        # some gui components
include 'pgplotwidget.g';		# pgplot widget
include 'jenplot_pgwaux.g';		# auxiliary pgplot routines
include 'jenplot_datobj.g';		# data object routines
include 'jenplot_help.g';		# help texts
include 'profiler.g';		        # used for profiling etc


#==========================================================================
#==========================================================================
#==========================================================================
#==========================================================================
# jenplot is a self-contained object for plotting graphs.
# It could be turned into a stand-alone object as soon as a good name
# is found.


#=====================================================================
#=====================================================================
jenplot := function (ref pgw=F, 
		     debugging=[menu=T], 
		     flagging=[broadcast=T, receive=F]) {
    private := [=];
    public := [=];

    private.pgw := pgw;				# pgplotter widget
    private.debugging := debugging;             # debugging control
    private.flagging := flagging;               # flagging control


# Initialise the object (called at the end of this constructor):

    private.init := function () {
	wider private;

	private.prof := profiler('jenplot');    # profiler object

	private.pgwaux := jenplot_pgwaux(prof=private.prof);
	whenever private.pgwaux.agent -> * do {
	    s1 := paste($name,type_name($value),shape($value));
	    # print '\njenplot: pgwaux event received:',s1,'\n';
	    ss := "boxcursor clicked_slice_wedge switched_panel";
	    if (any($name==ss)) {          
		r := private[$name]($value);    # execute function
		if (is_fail(r)) print r;
	    } else {
		print 'jenplot: function not recognised:',s1;
	    }
	}

	private.datobj := jenplot_datobj(private.pgwaux, prof=private.prof);
	whenever private.datobj.agent -> * do {
	    s1 := paste($name,type_name($value),shape($value));
	    # print '\njenplot: datobj event received:',s1,'\n';
	    ss := "clicked_line_yannot clicked_slice_yannot";
	    if (any($name==ss)) {          
		r := private[$name]($value);    # execute function
		if (is_fail(r)) print r;
	    } else {
		print 'jenplot: function not recognised:',s1;
	    }
	}

	private.guiframe := F;			# main gui frame
	private.jenguic := jenguic();		# gui-components

	public.clear();				# does what exactly(?)
	public.clipboard();			# initialise clipboard-record
	public.set_cx2real();                  # conversion complex->real

	private.jenplot_help := jenplot_help(); # help functions

	private.continue := F;			# instructions (record)

	private.spawned := F;			# spawned plotter (record)
	private.has_spawned := F;		# switch

	private.index := F;			# see jenplot_index.g
	# private.tapedeck_enabled := F;	# see tapedeck_enable
	public.tapedeck_enable (F);		# disable tapedeck control

	# private.echo := client ('echo_client');	# make client
	# private.timer := client ('timer');	# make client

	return T;
    }



#==========================================================================
# Public interface:
#==========================================================================

    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('jenplot event:',$name);
	s := paste(s,'$value:',type_name($value),shape($value));
	# print s;
    }
    whenever public.agent->message do {
	print 'jenplot message-event:',$value;
    }
    whenever public.agent->flags do {
	s := paste('jenplot flagging-event:');
	s := paste(s,'$value:',type_name($value),shape($value));
	if (is_boolean($value)) {
	    nTrue := len($value[$value]);
	    nFalse := len($value[!$value]);
	    s := spaste(s,' nTrue=',nTrue,' nFalse=',nFalse);
	} else if (!is_record($value)) {
	    s := paste('$value type not recognised:',type_name($value));
	} else if (!has_field($value,'line')) {
	    s := '$value does not have field: line';
	} else if (!is_record($value.line)) {
	    s := paste('$value.line is not a record, but:',type_name($value.line));
	} else {
	    for (line in $value.line) {
		ff := line.ff;
		nTrue := len(ff[ff]);
		nFalse := len(ff[!ff]);
		s1 := spaste(line.label,':');
		s1 := spaste(s1,' selected=',line.selected);
		s1 := spaste(s1,' deleted=',line.deleted);
		s1 := spaste(s1,' visible=',line.visible);
		s1 := spaste(s1,' nTrue=',nTrue,' nFalse=',nFalse);
		print s1;
	    }
	}
	public.message(s);
	print s;
    }
    whenever public.agent->done do {
	print 'jenplot event: done',$value;
    }

    public.done := function (dummy=F) {
	return private.done();
    }

# Clearing and resetting....

    public.clear := function (dummy=F) {		# clear the workspace
	return private.clear();
    }

    # public.init := function () {return public.reset()}	# alternative.?
    public.reset := function (name=F) {
	if (is_boolean(name)) {				# bring into known state
	    private.progress_control('do_abort');	# just in case
	    public.clear();
	    # private.pgwaux.legend(clear=T);
	} if (name=='color' || name=='colors') {
	    return private.pgwaux.reset_plot_color();	# automatic index
	} else {
	    print 'pgw.reset(): not recognised:',name;
	    return F;
	}
    }

# Plotting and printing:


    public.spawn_statistics := function (full=F) {	# plot statistics
	print 'non-implemented function: jenplot.spawn_statistics()'; 
	# return private.spawn('focus', option='statistics');
    }

    public.plot_full := function (name=F, trace=F, 
				  origin='public.plot_full') { 
	return public.plot(name=name, replot=F, full=T, trace=trace,
			   origin=origin);
    }
    public.plot_fast := function (name=F, trace=F, 
				  origin='public.plot_fast') { 
	return public.plot(name=name, replot=F, full=F, trace=trace,
			   origin=origin);
    }
    public.replot := function (name=F, trace=F, origin='public.replot') { 
	return public.plot(name=name, replot=T, trace=trace,
			   origin=origin);
    }
    public.plot := function (name=F, replot=F, full=F,
			     trace=F, origin='public.plot') {
	wider private;
	if (trace) print '\n jenplot.plot(',name,'full=',full,')';
	private.resize_counter := 0;           # see .resize()
	r := private.plot(name=name, full=full, trace=trace, origin=origin);
	if (is_fail(r)) print r;
	if (replot) {                          # ......?
	    # private.pgwaux.draw_clitems();   # NB: causes double yannot!!
	    # private.pgwaux.draw_markers();   # ........??
	}
    }

    public.fullview := function (dummy=F) {         # unzoom
	return private.fullview ();
    }

    public.print := function (dummy=F) {            # hardcopy
	return private.pgwaux.print();
    }

# Set/get the various labels of the given gsb object (or its default...):
# NB: This is usually done 

    public.labels := function (ref gsb=F, trace=F,
			       title=F, legend=F,
			       yannot=F, xannot=F, 
			       xname=F, xdescr=F, xunit=F, 
			       yname=F, ydescr=F, yunit=F) {
	if (!is_record(gsb)) {
	    gsb := private.gsb_get ('focus_parent', trace=trace);
	}
	s := private.datobj.labels(gsb, label=F, trace=trace, 
				   title=title, legend=legend,
				   yannot=yannot, xannot=xannot, 
				   xname=xname, xdescr=xdescr, xunit=xunit, 
				   yname=yname, ydescr=ydescr, yunit=yunit);
	if (is_fail(s)) print s;
	return s;                  # return string vector
    }


# Get (a copy of or a reference to) the value of the named field:

    public.get := function(name, copy=T) {
	if (has_field(private,name)) {
	    if (copy) return private[name];	# return copy of value
	    return ref private[name];		# return reference (access!)
	} else {
	    s := paste('jenplot.get(): not recognised',name);
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
	    s := paste('jenplot.set(): not recognised',name);
	    print s;
	    fail(s);
	}
    }

# Inspection:

    public.pgw := function () {
	return ref private.pgw;			# reference to pgplot widget
    }
    public.pga := function () {
	return ref private.pgwaux;		# reference to pgplot widget functions
    }
    public.pgd := function () {
	return ref private.datobj;		# reference to pg data functions
    }
    public.prof := function () {
	return ref private.prof;		# reference to profiler data functions
    }
    public.trace := function (tf=F) {
	return private.prof.trace(tf);	        # make the profiler trace
    }

    public.private := function(copy=F) {	# access to private part
	if (copy) return private;		# return a copy
	return ref private;			# return a reference
    }
    public.inspect := function (name=F) {	# Inspect various things
	return private.inspect(name);
    }


#========================================================================
# General functions:
#========================================================================


    public.message := function (txt='txt', origin=F, type=F, 
				top=T, bot=F, pri=F, clear=F,
				color='black', error=F, warning=F) {
	s := paste(txt);
	if (is_string(origin)) s := spaste('[',origin,'] ',s);
	if (is_string(type)) {
	    if (clear) {
		s := ' ';
		top := bot := T;                    # override
	    } else if (type=='notrec') {
		s := paste('not recognised:',s);
		top := pri := T;                    # override
	    } else if (type=='error') {
		s := paste('*** error:',s);
		color := 'red';
		top := bot := pri := T;             # override
	    } else if (type=='warning') {
		s := paste('*** warning:',s);
		color := 'green';
		top := bot := pri := T;             # override
	    } else {
		s := paste(type,'(??):',s);
	    }
	}
	if (pri) print s;
	if (top) {
	    if (is_record(private.pgw)) {
		private.pgw.message(s);
	    } else {
		print s,'(jenplot.message(): no private.pgw!)';
	    }
	}
	if (bot) private.write_gui_label(s, color=color);
	return T;
    }

# Write to the bottom label of the gui:

    private.write_gui_label := function (text='text', color='black') {
	wider private;
	if (is_agent(private.gui_label)) {
	    private.gui_label -> foreground(color);	
	    private.gui_label -> text(text);
	} else {
	    print 'jenplot.write_gui_label:',text;
	}
    } 

#---------------------------------------------------------------------
# Done: clean up the plotter anf the data etc:

    private.done := function (dummy=F, trace=F) {
	wider private;
	if (private.tapedeck_enabled) {
	    if (trace) print 'done(): progress_control(do_abort)';
	    private.progress_control('do_abort');	# just in case
	    if (trace) print 'done(): public.tapedeck_enable(F)';
	    public.tapedeck_enable(F);			# disable tapedeck control
	}
	if (is_record(private.index)) {
	    if (trace) print 'done(): public.index()';
	    private.index.agent -> progress_control('do_abort');
	    public.index();
	}
	if (private.has_spawned) {			# any spawned widgets
	    if (trace) print 'done(): spawned.done()';
	    private.has_spawned := F;			# superfluous
	    private.spawned.done();
	}
	if (is_record(private.jenguic)) {
	    if (trace) print 'done(): private.guic.clear_buttons()';
	    private.jenguic.clear_buttons();
	}
	if (trace) print 'done(): private.pgw.clear()';
	private.pgwaux.clear(trace=trace);
	private.pgw.clear();
	if (trace) print 'done(): private.pgw.done()';
	private.pgw.done();
	if (trace) print 'done(): val private.pgw := F';
	val private.pgw := F;
	if (trace) print 'done(): val private.guiframe := F';
	val private.guiframe := F;
	# val private := [=];		        # circular in spawn?
	if (trace) print 'done(): public.agent -> done()';
	public.agent -> done();
	# private.prof.show_profile();          # show profiler result
	# private.prof.show_obsolete(full=T);   # record of obsolete calls
	return T;
    }


#========================================================================
# Deal with groups/slices/bricks (gsb):
#========================================================================

    private.clear := function () {
	wider private;
	private.gsb_init();
	# private.pgwaux.reset_plot_color();	# reset color counter
	# public.tapedeck_enable (F);		# disable tapedeck control
	return T;
    }

    private.gsb_init := function () {
	wider private;
	funcname := 'gsb_init';
	private.prof.start(funcname, text=F, tracelevel=1);
	private.gsb := [=];                     # groups/slices/bricks
	private.gsb_descr := [=];               # corresponding descriptions
	for (i in [1:10]) private.gsb[i] := F;  # safety ....?
	private.mosaick := F;                   # not mosaick_mode
	return private.prof.stop(funcname, result=T);
    }

# Delete gsb objects with given indices 'index' (may be vector):

    private.gsb_delete := function (index=F, trace=F) {
	wider private;
	s := spaste('gsb_delete(index=',index,'):');
	funcname := 'gsb_delete';
	if (is_boolean(index)) return T;        # not needed
	private.prof.start(funcname, text=s, tracelevel=1);

	ngsb := len(private.gsb_descr);         # total nr of gsb objects
	for (i in index) {
	    if (i<=0 || i>ngsb) next;           # out of range
	    if (is_boolean(private.gsb_descr[i])) next;  # deleted already
	    ip := private.gsb_descr[i].parent;  # index of its parent, if any
	    if (is_integer(ip)) {               # remove pointer in its parent
		rr := private.gsb_descr[ip];    # convenience
		if (is_record(rr)) rr.child := rr.child[rr.child!=i];
		private.gsb_descr[ip] := rr;    # put back
	    }
	    private.gsb_descr[i] := F;          # delete descriptor
	    private.gsb[i] := F;                # delete gsb object itself
	    s := spaste(s,' deleted:',i,' (ip=',ip,')');
	    if (trace) print s;
	}
	return private.prof.stop(funcname, result=T);
    } 

# Find an empty slot for storage of a gsb object and its descriptor:

    private.gsb_find_emptyslot := function () {
	wider private;
	for (i in ind(private.gsb_descr)) {
	    if (is_boolean(private.gsb_descr[i])) return i;  # OK, found
	}
	return 1+len(private.gsb_descr);                     # take the next
    }

# Get vector of specific indices into private.gsb/gsb_descr:

    private.gsb_get_indices := function (name='plotted', type='any', trace=F) {
	wider private;
	s := spaste('get_gsb_indices(',name,' type=',type,'):');
	# if (trace) print s;
	funcname := 'get_gsb_indices';
	private.prof.start(funcname, text=s, tracelevel=1);

	ii := [];
	if (name=='all') {                        # all available
	    ii := ind(private.gsb_descr);
	} else if (name=='first') {               # the first one
	    ii := ind(private.gsb_descr);
	    if (len(ii)>0) ii := ii[1];
	} else if (name=='last') {                # the last one
	    ii := ind(private.gsb_descr);
	    if (len(ii)>0) ii := ii[len(ii)];

	} else if (name=='plotted' ||              # all plotted gsb objects
		   name=='plotted_and_parent') {   # their parents too
	    for (i in ind(private.gsb_descr)) {
		if (trace) print i,private.gsb_descr[i];
		if (!is_record(private.gsb_descr[i])) {
		    if (trace) print i,'not a record';
		    next;
		} else if (!private.gsb_descr[i].plotted) {
		    if (trace) print i,'not plotted';
		    next;
		} else {
		    ii := [ii,i];
		    if (name=='plotted_and_parent') {
			ip := private.gsb_descr[i].parent;
			if (is_boolean(ip)) {      # gsb has no parent
			} else if (!any(ii==ip)) { # avoid doubles
			    ii := [ii,ip];         # include parent gsb
			} 
		    }
		    if (trace) print ii;
		}
	    }

	} else if (name=='parents' || 
		   name=='children') {
	    pp := cc := [];
	    for (i in ind(private.gsb_descr)) {
		if (is_boolean(private.gsb_descr[i])) next;
		if (is_boolean(private.gsb_descr[i].parent)) {
		    pp := [pp,i];                  # vector of parents
		} else {
		    cc := [cc,i];                  # vector of children
		}
	    }
	    if (name=='parents') ii := pp;
	    if (name=='children') ii := cc;

	} else if (name=='children') {             # all child gsb objects
	    for (i in ind(private.gsb_descr)) {
		if (is_boolean(private.gsb_descr[i])) next;
		if (is_boolean(private.gsb_descr[i].parent)) next;
		ii := [ii,i];
	    }

	} else if (name=='focus' || 
		   name=='focus_parent' || 
		   name=='focus_and_parent' ||
		   name=='focus_siblings' || 
		   name=='focus_family') {
	    rr := private.pgwaux.get_current_focus(trace=F);
	    for (i in ind(private.gsb_descr)) {
		if (is_boolean(private.gsb_descr[i])) next;
		if (private.gsb_descr[i].irow != rr.irow) next;
		if (private.gsb_descr[i].icol != rr.icol) next;
		ii := i;                             # the gsb that has the focus
		ip := private.gsb_descr[i].parent;   # its parent (may be itself)
		if (is_boolean(ip)) {
		    # Does not have a parent, do nothing.
		} else if (is_boolean(private.gsb_descr[ip])) {
		    print 'parent gsb is not a record!';
		} else if (name=='focus_parent') {   # the parent of the focus gsb
		    ii := ip;
		} else if (name=='focus_and_parent') {   # its parent too
		    if (ip!=i) ii := [ii,ip];            # only if not the same
		} else if (name=='focus_siblings') { # other children of same parent
		    ii := private.gsb_descr[ip].child;
		    ii := ii[ii!=i];                 # exclude focus gsb
		} else if (name=='focus_family') {   # parent and its children
		    ii := [ip,private.gsb_descr[ip].child];
		}
		break;                             # found: escape
	    }

	} else {
	    print 'get_gsb_indices: not recognised:',name;
	}

	# Check the indices ii and the gsbs they represent:
	ngsb := len(private.gsb);
	for (i in ii) {
	    if (i<=0 || i>ngsb) {
		print s,'i out of range:',i,ngsb;
		ii := ii[ii!=i];
		next;                                  # escape
	    }
	    gsb := ref private.gsb[i];                 # convenience
	    if (!is_record(gsb)) {
		print s,'gsb[',i,'] is not a record, but:',type_name(gsb);
		ii := ii[ii!=i];
	    } else if (is_boolean(type) || type=='any') {              
		# OK, gsb type not important
	    } else if (any(type==gsb.type)) {              
		# OK, correct gsb type
	    } else {
		print s,'gsb[',i,'] is wrong type:',gsb.type;
		ii := ii[ii!=i];
	    }
	}
	if (len(ii)<=0) {                              # none found
	    if (trace) print s,'ii=[]: no gsb found.....';
	    return private.prof.stop(funcname, result=[]); # empty vector
	} else {
	    if (trace) print s,' ii=',ii;
	}
	return private.prof.stop(funcname, result=ii);
    }

# Get a reference to (or a copy of) the indicated gsb-object (group/slice/brick).
# If name='focus', this is the plotted gsb that currently 'has the focus'. 
# If name='parent', it is the gsb from which the focus gsb has been derived 
# (this can be either the (real) focus gsb itself, or e.g. a complex gsb).
# A specific gsb type may be specified (may be string vector), 
# e.g. group or slice. 
# NB: This function does not lend itself to using .prof.start/stop because
#     of the return of a REFERENCE to the selected gsb.....(?)

    private.gsb_get := function (name='focus', type='any', copy=F, trace=F) {
	wider private;
	i := private.gsb_get_indices (name, type=type, trace=trace);
	s := spaste('get_gsb(',name,' type=',type,' copy=',copy,') i=',i,':');
	if (trace) print s;
	# funcname := 'get_gsb';
	# private.prof.start(funcname, text=s, tracelevel=1);

	if (len(i)<=0 || i<0 || i>len(private.gsb)) {     # index out of range
	    if (trace) print s,'out of range',len(private.gsb);
	    return F;
	    # return private.prof.stop(funcname, result=F);
	} else if (copy) {                                # return copy
	    return private.gsb[i]; 
	    # return private.prof.stop(funcname, result=gsb);
	} else {                                          # return reference
	    return ref private.gsb[i]; 
	    # return private.prof.stop(funcname, result=private.gsb[i]);
	}
	# return private.prof.stop(funcname, result=F);
	return F;
    }


#----------------------------------------------------------------------------------
# Initialise a gsb plot-description record (in private.gsb_descr):
# NB: If parent=integer, it is a 'child' object, derived from a parent gsb object
#     by conversion (e.g. cx2real)

    private.gsb_descr_init := function (parent=F, igsb=F, ref gsb=F) {
	rr := [=];
	rr.parent := parent;                    # pointer into private.gsb
	rr.igsb := igsb;                        # pointer into private.gsb
	rr.type := F;                           # e.g. 'group' or 'slice'
	rr.label := F;                          # label of corresponding gsb
	if (is_record(gsb)) {
	    rr.type := gsb.type;
	    rr.label := gsb.label;
	}
	rr.child := [];                         # one or more posiible
	rr.conv := F;                           # applied conversion (child)
	rr.icol := F;                           # panel position on plot-window
	rr.irow := F;                           # panel position on plot-window
	rr.plotted := F;                        # T if panel icol/irow defined
	return rr;                              # return record
    }

# Show an overview of the gsb status:

    private.gsb_descr_show := function (full=F, trace=F) {
	s := paste('\n Overview of gsb status (',len(private.gsb_descr),'):');
	if (trace) print s;
	for (i in ind(private.gsb_descr)) {
	    rr := private.gsb_descr[i];
	    if (is_boolean(rr)) {
		if (!full) next;                # deleted: ignore
		s1 := spaste('- ',i,': deleted');
	    } else {
		s1 := spaste('- ',i,' ',rr.igsb,': ');
		s1 := spaste(s1,' (irow=',rr.irow,' icol=',rr.icol,')');
		s1 := spaste(s1,' parent=',rr.parent,' child=',rr.child,':');
		s1 := spaste(s1,' ',rr.type,' label=\'',rr.label,'\'');
		s1 := spaste(s1,' conv=',rr.conv);
	    }
	    if (trace) print s1;
	    s := paste(s,'\n',s1);
	}
	return paste(s,'\n');
    }


# Put (append/replace) a new 'parent' gsb object in the gsb-array.
# NB: If replace is not boolean (default: don't) it is a string
#     like 'first' or 'focus', i.e. the gsb object to be replaced.
# If it contains complex data, set up child-object(s) with real data,
# governed by the current value of private.cx2real (e.g. 'ampl'): 

    private.gsb_put := function (gsb=F, clear=F, replace=F, trace=F,
				 irow=F, icol=F) {
	wider private;
	s := spaste('gsb_put(',gsb.type,' clear=',clear);
	s := spaste(s,' icol=',icol,' irow=',irow);
	s := spaste(s,' replace=',replace,'): ',gsb.type,gsb.label);
	if (trace) print s;
	
	# Check icol/irow against possible mosaick-mode: 
	private.check_mosaick(icol=icol, irow=irow);

	if (is_record(private.mosaick)) {    # mosaick_mode
	    replace := F;                    # used in set_cx2real..
	    i := private.gsb_find_emptyslot();
	    rr := private.gsb_descr_init(igsb=i, gsb=gsb);
	    # NB: Check if gsb is complex -> convert first...?
	    # NB: Check if icol<=private.mosaick.ncol etc...
	    rr.icol := icol;
	    rr.irow := irow;
	    rr.plotted := T;

	} else if (is_boolean(replace)) {    # do NOT replace existing
	    replace := F;                    # used in set_cx2real..
	    if (clear) private.gsb_init();   # use public.clear()...?
	    i := private.gsb_find_emptyslot();
	    rr := private.gsb_descr_init(igsb=i, gsb=gsb);

	} else {                             # usually replace='first';
	    i := private.gsb_get_indices(replace, trace=trace); 
	    if (len(i)<=0) {                 # not found....
		if (trace) print s,'no gsb to replace:',replace;
		i := private.gsb_find_emptyslot();  # continue(?)
		rr := private.gsb_descr_init(igsb=i, gsb=gsb);
	    } else {
		i := i[1];                   # just in case...(?)
		rr := private.gsb_descr[i];  # copy gsb descriptor
		replace := T;                # used in set_cx2real..
	    }
	}
	private.gsb[i] := gsb;               # store
	private.gsb[i].igsb := i;            # it knows its own index
	private.gsb_descr[i] := rr;          # new or copied descriptor 
	s := spaste('new: gsb_descr[',i,']=',private.gsb_descr[i]);
	if (trace) print s;
	public.set_cx2real(gsb=gsb, replace=replace, trace=trace);

	if (is_record(private.mosaick)) {    # mosaick_mode
	    private.gsb_plot (idescr=i, trace=trace, full=T);
	}
	return T;
    }

# Set up 'child' gsb-object(s), e.g. if the parent is complex

    private.gsb_make_child := function (convert=F, parent=F, 
					replace=F, trace=F) {
	wider private;
	if (is_boolean(parent)) {            # should not happen..?
	    parent := private.gsb_get_indices('focus_parent');
	}
	s := spaste('gsb_make_child(',convert,', parent=',parent);
	s := spaste(s,' replace=',replace,'):');
	if (trace) print s;

	if (is_boolean(parent)) {
	    print s,'parent is boolean!';
	    return F;
	} else if (parent<=0 || parent>len(private.gsb_descr)) {
	    print s,'parent out-of-range!',len(private.gsb_descr);
	    return F;
	} else {                             # assume: OK
	    rrp := private.gsb_descr[parent];  # parent descriptor
	}

	# If not replace, delete all its children...
	if (!replace) {
	    private.gsb_delete(rrp.child, trace=trace);
	    rrp.child := [];                 # remove any children
	}

	for (i in ind(convert)) {            # may be vector
	    if (trace) print s,convert[i],':';
	    # Find a slot in the gsb-array for the child gsb object:
	    islot := F;
	    if (!replace) {                  # new child
		islot := private.gsb_find_emptyslot();
		rrc := private.gsb_descr_init(parent=parent, igsb=islot, gsb=gsb);
	    } else {                         # replace existing child
		for (ic in rrp.child) {      # check all children
		    rrc := private.gsb_descr[ic];  # existing child descr
		    if (rrc.conv==convert[i]) {
			islot := ic;
			if (trace) print ic,'...found, islot=',islot;
			break;               # found: escape
		    } else {
			if (trace) print ic,'...not found:',ic,rrc.conv;
			next;                # continue
		    }
		}
	    }

	    if (is_boolean(islot)) {
		print s,'islot not found!';
		return F;
	    } else if (!replace) { 
		private.gsb[islot].igsb := islot;  # child knows its own index
		rrp.child := [rrp.child,islot];  # parent knows its children
		rrc.conv := convert[i];          # child knows its conversion
	    }

	    # Convert the parent gsb, and deal with the resulting child gsb:
	    gsb := private.datobj.copy_cx2real(private.gsb[parent], 
					       cx2real=convert[i],
					       trace=trace);
	    if (!is_record(gsb)) {           # problem with conversion
		rrc.conv := paste(rrc.conv,': conversion problem!');
		print 'gsb_make_child:',rrc.conv;
	    }
	    private.gsb[islot] := gsb;       # store child gsb object

	    private.gsb_descr[islot] := rrc; # store child descr
	    if (trace) print islot,'child descr:',private.gsb_descr[islot];
	}
	private.gsb_descr[parent] := rrp;    # replace parent descr
	if (trace) print 'modified parent descr:',private.gsb_descr[parent];
	return T;
    }

#--------------------------------------------------------------------------
# Change complex->real conversion mode:

    public.set_cx2real := function (cx2real=F, gsb=F, replace=F, trace=F) {
	wider private;
	s := paste('set_cx2real(',cx2real,type_name(gsb),'):');

	# Set the overall control parameter, 
	if (!has_field(private,'cx2real')) private.cx2real := 'not_complex';
	if (!has_field(private,'unwrap')) private.unwrap := F;
	if (is_record(gsb)) {                     # gsb given
	    s := spaste(s,' iscomplex=',gsb.iscomplex);
	    if (!gsb.iscomplex) {                 # real data
		private.cx2real := 'not_complex';	
	    } else if (private.cx2real=='not_complex') {
		private.cx2real := 'ampl';        # default...
	    }
	} else if (is_string(cx2real)) {          # cx2real given
	    private.cx2real := cx2real;           
	} else {                                  # neither given...?
	    private.cx2real := 'not_complex';	
	}
	if (trace) print s,'->',private.cx2real;

	# update the cxreal gui buttons (skipped if no gui yet):
	private.set_cx2real_button_state(trace=trace); 

	# Make new gsb children if necessary: 
	convert := private.cx2real;               # argument for make_child
	if (private.cx2real=='not_complex') {
	    if (trace) print 'set_cx2real(): no further action..';
	    return T;                             # .....sufficient..?
	} else if (private.cx2real=='ampl_phase') {
	    convert := "ampl phase";
	} else if (private.cx2real=='real_imag') {
	    convert := "real_part imag_part";
	} else if (private.cx2real=='all_four') {
	    convert := "ampl phase real_part imag_part";
	}
	if (trace) print private.cx2real,'->',convert;

	# Make (real) children by conversion from complex parent(s):
	iip := private.gsb_get_indices('parents', trace=trace);
	for (i in iip) {
	    private.gsb[i].cx2real := F;         # just in case
	    if (private.gsb[i].iscomplex) {      # complex data only
		private.gsb_make_child(convert=convert, parent=i, 
				       replace=replace, trace=trace);
	    }
	}
	return T;
    }


# Set up the plotting layout (in rows and colums of panels): 
# For the moment: Each 'parent' gsb object gets a column.
# If it has any 'child' objects, they will be placed in this column.
# If not, it will be placed in this column itself.

    private.gsb_panel_setup := function (trace=F) {
	wider private;
	if (trace) print 'gsb_panel_setup:';

	# Go through the gsb plot-descr records:
	rout := [ncol=1, nrow=1];               # return-record
	icol := 0;
	for (i in ind(private.gsb_descr)) {
	    rr := private.gsb_descr[i];         # convenience
	    if (!is_record(rr)) {               # error?
		# ignore
	    } else if (is_integer(rr.parent)) { # child object
		# ignore
	    } else {                            # parent object
		rr.plotted := F;
		irow := 0;                      # row nr of plot-panel
		if (len(rr.child)<=0) {         # no children
		    icol +:= 1;                 # column nr of plot-panel
		    irow := 1;
		    rr.irow := irow;
		    rr.icol := icol;
		    rr.plotted := T;
		    if (trace) print i,'parent:',rr;
		} else {                        # one or more children
		    nc := 0;
		    for (ic in rr.child) {
			rrc := private.gsb_descr[ic];  # convenience
			nc +:= 1;
			if (((nc-1)%2)==0) {
			    icol +:= 1;
			    irow := 0;
			}
			irow +:= 1;
			private.gsb_descr[ic].irow := irow;
			private.gsb_descr[ic].icol := icol;
			private.gsb_descr[ic].plotted := T;
			rr.irow := F;           # undefined in parent descr
			rr.icol := F;           # undefined in parent descr
			if (trace) print ic,'child:',private.gsb_descr[ic];
		    }
		}
		private.gsb_descr[i] := rr;     # replace
		rout.ncol := max(rout.ncol,icol);    # total nr of columns
		rout.nrow := max(rout.nrow,irow);    # total nr of rows
	    }
	}
	if (trace) private.gsb_descr_show (trace=F);
	return rout;
    }

# Do the actual plotting (of specified gsb-objects in private.gsb):
# NB: If full=F, x/yannot, legend and wedge are not plotted...

    private.plot := function (name=F, clear=T, bebuf=T, trace=F, 
			      full=T, origin=F) {
	wider private;
	public.message (clear=T);
	s := spaste('jenplot.plot(',name,' full=',full);
	s := spaste(s,' clear=',clear,' bebuf=',bebuf,'):');
	if (is_string(origin)) s := paste(s,origin);
	if (trace) print '\n\n*******************************',s;
	funcname := 'plot';
	private.prof.start(funcname, text=s, tracelevel=1);

	setup := T;                             # the full treatment     
	if (is_boolean(name)) {                 # not specified
	    if (is_record(private.mosaick)) {   # mosaick_mode
		setup := T;
		rr := [=];
		rr.ncol := private.mosaick.ncol;
		rr.nrow := private.mosaick.nrow;
	    } else {
		setup := T;        
		rr := private.gsb_panel_setup(trace=trace);
		if (trace) print 'plot(): panel definition:',rr;
	    }
	    ii := private.gsb_get_indices ('plotted', trace=trace);
	    if ((rr.ncol*rr.nrow)<=0) {         # problem
		return private.prof.stop(funcname, result=F);
	    }

	} else if (any(name=="focus")) {        # name recognised 
	    setup := F;                         # limited only
	    ii := private.gsb_get_indices (name);

	} else {                                # differentiate?
	    print 'jenplot.plot(): name not recognised:',name;
	    return private.prof.stop(funcname, result=F);
	}

	# Check if there are any gsb's to be plotted:
	if (len(ii)<=0) {
	    print 'jenplot.plot(): no gsb indices for:',name;
	    return private.prof.stop(funcname, result=F);
	}

	private.check_gui();                    # make gui if necessary
	if (bebuf) private.pgwaux.bbuf('plot'); # fill command-buffer
	# NB: DO NOT ESCAPE THE ROUTINE WITHOUT EXECUTING .ebuf()!!!!!!!!!

	if (setup) {
	    if (trace) print 'set up: rr=',rr;
	    private.pgwaux.env();                   # required....!!
	    if (clear) { 
		private.pgwaux.pgw().clear();
		private.pgwaux.clear('jenplot.plot()');  # clitems/markers etc
		# NB: Should clitems/markers be in gsb objects...?
		# Tricky: consider pgwaux.resize and standalone applications..
		# On the other hand, clitems/markers might accumulate....!
		# if too many replots of focus groups!!
	    }
	    private.pgwaux.subp (rr.ncol, rr.nrow); # define sub-panels
	}

	# OK: plot the specified data-objects (gsb) in their sub-panels:
	for (i in ii) {
	    r := private.gsb_plot (idescr=i, trace=trace, full=full);
	    if (is_fail(r)) print r;
	}

	if (bebuf) private.pgwaux.ebuf('plot', flush=T); # execute command-buffer
	public.message('plotting finished');
	return private.prof.stop(funcname, result=T);
    }

# (re-)plot a specific gsb (rr is the descriptor record from private.gsb_descr):

    private.gsb_plot := function (idescr=F, trace=F, full=T) {
	wider private;
	funcname := 'gsb_plot';
	public.message (clear=T);
	rr := private.gsb_descr[idescr];         # descriptor record
	s := spaste(funcname,' irow=',rr.irow,' icol=',rr.icol,':');
	s := spaste(s,' igsb=',rr.igsb,'....');
	public.message(s);
	if (trace) print s;
	private.prof.start(funcname, text=s, tracelevel=1);

	if (is_boolean(rr.igsb)) {
	    return private.prof.stop(funcname, result=F);
	} else if (!rr.plotted) {
	    return private.prof.stop(funcname, result=F);
	} else if (rr.igsb<=0 || rr.igsb>len(private.gsb)) {
	    return private.prof.stop(funcname, result=F);
	}

	gsb := ref private.gsb[rr.igsb];         # data-object itself
	if (!is_record(gsb)) {
	    print s;
	    print 'data-object is not a record: descr=\n',rr;
	    return private.prof.stop(funcname, result=F);
	}

	s := paste(s,type_name(gsb));
	if (is_boolean(gsb)) {
	    return private.prof.stop(funcname, result=F);
	}

	s := paste(s,gsb.type,gsb.label);
	if (trace) print s;
	public.message(s);
	if (gsb.type=='line') {
	    return private.prof.stop(funcname, result=F);
	} else if (gsb.type=='group') {
	    r := private.datobj.plot_group(gsb, full=full, trace=trace,
					   icol=rr.icol, irow=rr.irow);
	} else if (gsb.type=='slice') {
	    r := private.datobj.plot_slice(gsb, full=full, trace=trace,
					   icol=rr.icol, irow=rr.irow);
	} else if (gsb.type=='textobj') {
	    r := private.datobj.plot_textobj(gsb, full=full, trace=trace,
					     icol=rr.icol, irow=rr.irow);
	} else {
	    print funcname,': gsb.type not recognised:',gsb.type;
	    r := F;
	}
	return private.prof.stop(funcname, result=r);
    }


#=============================================================================
# Deal with the gsb-clipboard:
# If an gsb (record) is given, append or replace (at index=integer) it.
# If clear=T, clear the collection of stored gsbs.

    public.clipboard := function (gsb=F, get=F, summary=F, clear=F, trace=F) {
	wider private;
	s := spaste('jenplot.clipboard(gsb=',type_name(gsb),' get=',get);
	s := spaste(s,' clear=',clear,' summary=',summary,'):');
	if (trace) print s;
	if (!has_field(private,'clipboard')) clear := T;
	if (clear) {
	    private.clipboard := [=];
	    private.clipboard.gsb := [=];	# plot-gsbs
	    private.clipboard.ngsb := 0;	# nr of gsbs
	    private.clipboard.label := ' ';	# gsb labels
	    private.clipboard.type := ' ';	# gsb types
	    summary := T;
	}
	ngsb := private.clipboard.ngsb;         # convenience

	# Get an entry from the clipboeard:
	if (is_boolean(get)) {			# 
	    if (get) get := 1;                  # first entry 
	}
	if (is_integer(get)) {		        # get by index
	    if (get<0 || get>ngsb) return F;	# out of range
	    return private.clipboard.gsb[get];
	} else if (is_string(get)) {		# get by label
	    ii := seq(ngsb)[get==private.clipboard.label];
	    if (len(ii)==0) return F;		# empty
	    return private.clipboard.gsb[ii[1]];
	}

	# Insert a new entry onto the clipboard:
	if (is_boolean(gsb)) {                  # not needed
	    # do nothing;
	} else if (!private.datobj.check_type(gsb,'line',origin='clipboard')) {
	    return F;                           # wrong gsb type
	} else {                                # OK, proceed
	    private.datobj.statistics(gsb, full=T, enforce=T);
	    # ngsb +:= 1;		        # multiple entries
	    ngsb := 1;		                # one entry only!!
	    private.clipboard.gsb[ngsb] := gsb;
	    private.clipboard.type[ngsb] := gsb.type;
	    private.clipboard.label[ngsb] := gsb.label;
	    private.clipboard.ngsb := ngsb;
	    summary := T;
	}

	# Get a summary of the clipboard contents:
	if (summary) {
	    s := spaste('Clipboard summary (n=',ngsb,'): ');
	    if (private.clipboard.ngsb<=0) {
		s := paste(s,'empty');
	    } else {
		igsb := 1;                      # one only...
		line := ref private.clipboard.gsb[igsb];
		s := spaste(s,' row/line=',line.label,': ');
		s := spaste(s,type_name(line.yy),'[',shape(line.yy),']');
		mean := line.stat.yy.mean;
		if (line.iscomplex) {
		    s1 := sprintf('%.3g+%.3gi',real(mean),imag(mean));
		} else {
		    s1 := sprintf('%.3g',mean);
		}		    
		# s := spaste(s,' mean=',s1);   # line gets too long...!
	    }
	    if (trace) print s;
	    return s;
	}
	return T;
    }

    public.clipboard_empty := function () {
	return (private.clipboard.ngsb==0);            # T/F
    }

#========================================================================
# Attach specific markers (arros, circles) to gsb objects:
#========================================================================

    public.put_axis := function (ref gsb, xy='x', trace=F,
				 color='default', style='lines', size=2) {
	if (!private.datobj.check_type(gsb,'group',origin='put_xaxis')) {
	    return F;
	}
	rr := [=];
	rr.type := 'axis';
	rr.xy := xy;                             # 'x', 'y', 'xy'
	private.pgwaux.decode_plot_attrib(rr, color, style, size); 
	gsb.graphic[1+len(gsb.graphic)] := rr;   # attach to gsb
	return T;
    }

    public.put_marker := function (ref gsb, xy=[0,0], trace=F,
				   label=F, just=0, angle=0,
				   color=F, style=F, size=5) {
	if (!private.datobj.check_type(gsb,'group',origin='put_marker')) {
	    return F;
	}
	rr := [=];
	rr.type := 'marker';
	rr.xy := xy;                             # position
	rr.label := label;                       # text at arrow point
	rr.just := just;                         # text justification
	rr.angle := angle;                       # text angle (degr)
	private.pgwaux.decode_plot_attrib(rr, color, style, size); 
	gsb.graphic[1+len(gsb.graphic)] := rr;   # attach to gsb
	return T;
    }

    public.put_arrow := function (ref gsb, xy1=[0,0], xy2=[1,1],
				  label=F, just=0, trace=F,
				  color='cyan', style='lines', size=1) {
	if (!private.datobj.check_type(gsb,'group',origin='put_arrow')) {
	    return F;
	}
	rr := [=];
	rr.type := 'arrow';
	rr.xy1 := xy1;                           # start point
	rr.xy2 := xy2;                           # end-point (arrow)
	rr.label := label;                       # text at arrow point
	rr.just := just;                         # text justification
	private.pgwaux.decode_plot_attrib(rr, color, style, size); 
	gsb.graphic[1+len(gsb.graphic)] := rr;   # attach to gsb
	return T;
    }

    public.put_circle := function (ref gsb, xy=[0,0], radius=1,
				   posangle=0, phi12=F,trace=F,
				   centre=F, axes=F,
				   color='cyan', style='lines', size=1) {
	if (!private.datobj.check_type(gsb,'group',origin='put_circle')) {
	    return F;
	}
	rr := [=];
	rr.type := 'arc';                        
	rr.xy := xy;                             # centre point
	rr.radius := radius;                     # radius (1 or 2) 
	rr.posangle := posangle;                 # position angle (rad)
	rr.phi12 := phi12;                       # arc start/stop (rad)
	rr.centre := centre;                     # if T, indicate centre
	rr.axes := axes;                         # if T, indicate axes
	private.pgwaux.decode_plot_attrib(rr, color, style, size); 
	gsb.graphic[1+len(gsb.graphic)] := rr;   # attach to gsb
	return T;
    }


#========================================================================
# Input/output of a gsb of any type:
#========================================================================

    public.put_gsb := function (gsb=F, clear=T, plot=T, full=F, 
				trace=F, irow=F, icol=F) {
	wider private;
	funcname := 'put_gsb';
	if (trace) print funcname;
	private.prof.start(funcname, text=F, tracelevel=1);
	if (!is_record(gsb)) {
	    print 'jenplot.put_gsb: not a record:',type_name(gsb);
	    return private.prof.stop(funcname, result=F);
	} 
	private.gsb_put (gsb, clear=clear, replace=F, trace=trace,
			 icol=icol, irow=irow);
	if (is_record(private.mosaick)) plot := F;
	if (plot) private.plot(full=full, origin='put_gsb');    
	return private.prof.stop(funcname, result=T);
    }

    public.get_gsb := function (name='first', trace=F) {
	return private.gsb_get (name=name, type='any', 
				copy=T, trace=trace);
    }

# Set up (or disable) the mosaick-mode:

    public.mosaick := function (gsb=F, ncol=F, nrow=F, trace=F) {
	wider private;
	rr := [ncol=ncol, nrow=nrow];
	ngsb := 0;
	if (is_record(gsb)) {                 # record of gsb objects
	    ngsb := len(gsb);                 # nr of gsb-objects
	    # check whether the fields are gsb objects....
	    # if (ngsb<=0) rr := F;           # ....?
	}

	if (ngsb>0) {                         # gsbs specified
	    nrow := ncol := ceil(sqrt(ngsb));
	    if (ngsb==2) nrow := 1;
	} else if (nrow>1) {                  # rows specified
	    if (ncol<=1) ncol := 1;           # incl ncol==T/F
	} else if (ncol>1) {                  # cols specified
	    if (nrow<=1) nrow := 1;           # incl nrow==T/F
	} else {
	    rr := F;                          # disable mosaick
	}

	private.check_gui();                  # make gui if necessary
	private.pgwaux.env();                 # required....!!
	private.pgwaux.pgw().clear();
	private.pgwaux.clear('jenplot.plot()'); # clitems/markers etc
	if (is_record(rr)) {
	    rr.ncol := ncol;
	    rr.nrow := nrow;
	    rr.used := array(F,rr.ncol,rr.nrow);
	    rr.icol := 0;                     # current icol (..?)
	    rr.irow := 1;                     # current irow (..?)
	    private.pgwaux.subp (rr.ncol, rr.nrow); # define sub-panels
	}    

	# If gsb-objects given, make the mosaick:
	if (ngsb>0) {
	    igsb := 0;
	    for (irow in [1:rr.nrow]) {
		rr.irow := irow;
		for (icol in [1:rr.ncol]) {
		    rr.icol := icol;
		    r := public.put_gsb(gsb[igsb+:=1], 
					icol=rr.icol, irow=rr.irow);
		    if (is_fail(r)) print r;
		    if (trace) print 'mosaick:',igsb,rr.irow,rr.icol;
		}
	    }
	}

	private.mosaick := rr;                # keep for checking
	if (trace) print 'jenplot: mosaick mode set to:',private.mosaick;
	return T;
    }

# NB: This routine might be moved to pgwaux....

    private.check_mosaick := function (icol=F, irow=F, 
				       nextpanel=F, trace=F) {
	wider private;
	s := spaste ('check_mosaick(icol=',icol,' irow=',irow);
	s := spaste(s,' next=',nextpanel,'):');
	s := paste(s,type_name(private.mosaick));
	if (trace) print s;
	if (is_boolean(private.mosaick)) {       # not active
	    if (icol>1 || irow>1 || nextpanel) { # specified
		print s,'mosaick-mode not active!';
	    }
	} else if (nextpanel) {                  # take next panel
	    icol := private.mosaick.icol + 1;
	    if (icol>private.mosaick.ncol) {
		private.mosaick.icol := 1;
		irow := private.mosaick.irow + 1;
		if (irow>private.mosaick.nrow) {
		    print s,'all panels are used!'; 
		    private.mosaick := F;        # disable mode
		}
	    }
	    if (private.mosaick.used[icol,irow]) {  # temporary...
		print s,'next panel already in use(?):',icol,irow; 
		private.mosaick := F;            # disable mode
	    }
	} else if (is_boolean(icol) || is_boolean(irow)) {
	    private.mosaick := F;                # disable mode
	} else if (icol<=0 || icol>private.mosaick.ncol) {
	    print s,'icol out of range!',icol,private.mosaick.ncol; 
	    private.mosaick := F;                # disable mode
	    # return F;
	} else if (irow<=0 || irow>private.mosaick.nrow) {
	    print s,'irow out of range!',irow,private.mosaick.nrow;
	    private.mosaick := F;                # disable mode
	    # return F;
	} 

	# Update the mosaick definition record (if defined):
	if (is_record(private.mosaick)) {
	    private.mosaick.icol := icol;
	    private.mosaick.irow := irow;
	    private.mosaick.used[icol,irow] := T;
	    if (trace) print 'mosaick:',private.mosaick;
	}
	return T;
    }

#------------------------------------------------------------------------
# Helper function to decide whether the argument is a gsb-object:

    public.is_gsb := function (ref rr=[=], origin=' ', mess=T) {
	s := paste('jenplot.is_gsb(',type_name(rr),origin,'):');
	if (!is_record(rr)) {
	    if (mess) print s,'not a record';
	} else if (!has_field(rr,'jenplot_gsb')) {
	    if (mess) print s,'no field jenplot_gsb';
	} else {
	    return T;              # OK, rr is a gsb object
	}
	return F;                  # not a gsb object
    }

# Helper function to get the names of gsb-fields from the fields
# of a sub-record named 'gsb' in the given record:

    public.get_gsb_fields := function (ref rr=[=]) {
	if (!is_record(rr)) return F;
	if (!has_field(rr,'gsb')) return F;
	ss := ' ';
	nss := 0;
	for (fname in field_names(rr.gsb)) {
	    if (public.is_gsb(rr.gsb[fname], fname, mess=T)) {
		ss[nss+:=1] := fname;
		print 'get_gsb_fields:',nss,':',fname;
	    }
	}
	if (nss<=0) return F;
	return ss;
    }


#========================================================================
# Input of a 2D slice of data:
#========================================================================
# Data to be plotted can be input as (a sequence of) 2D slices.
# NB: yy=array(vv,nxx,nyy), i.e. the first dimension is horizontal
# So: nxx >> nyy, because of annotations....

    public.putslice := function (label=F, xx=F, yy=F, ff=F,
				 special=F, attach=F,
				 slice=F, replace=F, plot=F, full=F,
				 clear=T, transpose=F, trace=F,
				 yannot=F, xannot=F, title=F, legend=F,
				 xname=F, xdescr=F, xunit=F, 
				 yname=F, ydescr=F, yunit=F) { 
	wider private;
	funcname := 'putslice';
	private.prof.start(funcname, text=F, tracelevel=1);

	if (is_record(slice)) {
	    # Slice data-object given: use it (NB: more checks here?)
	} else {
	    slice := private.datobj.slice(label=label, xx=xx, yy=yy, ff=ff,
					  transpose=transpose, trace=trace);
	}

	slice.special := special;                          # e.g. 'index';
	if (is_record(attach)) slice.attached := attach;   # user info

	private.datobj.labels(slice, label=label, trace=trace, 
			      yannot=yannot, xannot=xannot, 
			      title=title, legend=legend,
			      xname=xname, xdescr=xdescr, xunit=xunit, 
			      yname=yname, ydescr=ydescr, yunit=yunit);
	if (replace) {                          # replace existing slice
	    private.gsb_put (slice, clear=clear, replace='first', 
			     trace=trace);
	    if (plot) private.plot('focus', full=full, origin='putslice');  
	} else {                                # new slice
	    private.gsb_put (slice, clear=clear, replace=F, 
			     trace=trace);
	    if (plot) private.plot(full=full, origin='putslice');    
	}
	return private.prof.stop(funcname, result=T);
    }

#========================================================================
# Input of REFERENCE TO an ND 'index' data-brick:
#========================================================================

    public.putbrick := function (label=F, xx=F, transpose=F, trace=F,
				 ref yy=F, ref ff=F, ref index=F,
				 yannot=F, xannot=F, title=F, legend=F,
				 xname=F, xdescr=F, xunit=F, 
				 yname=F, ydescr=F, yunit=F) { 
	wider private;
	funcname := 'putbrick';
	private.prof.start(funcname, text=F, tracelevel=1);

	#------------------------------------------------------------
	# The index (record) is mandatory: set it up for navigation..
	#------------------------------------------------------------

	return private.prof.stop(funcname, result=T);
    }



#========================================================================
# Functions dealing with a 'text-object' (for use in mosaick etc):
# Just contains a multi-line string, which may be plotted in a panel.
#========================================================================

    public.textobj := function (label=F, title=F, text=F, trace=F) {
	textobj := private.datobj.textobj(label=label, trace=trace, 
				       title=title, text=text);
	if (is_fail(textobj)) print textobj;
	return textobj;
    }

# Enter a filled textobj (i.e. a text-object filled with text-lines):
# If clear=T, clear the gsb buffer first.

    public.puttextobj := function (textobj=F, title=F, trace=F, 
				   clear=T, plot=F, replace=F) {
	funcname := 'puttextobj';
	s := paste(funcname,textobj.type,textobj.label);
	if (trace) print s;
	private.prof.start(funcname, text=s, tracelevel=1);
	
	private.datobj.labels(textobj, trace=trace, 
			      label=label, title=title); 
	if (replace) {                    # replace existing textobj
	    private.gsb_put (textobj, clear=clear, replace='first', 
			     trace=trace);
	    if (plot) private.plot('focus', origin=funcname);  
	} else {                          # new textobj
	    private.gsb_put (textobj, clear=clear, replace=F, 
			     trace=trace);
	    if (plot) private.plot(origin=funcname);    
	}
	return private.prof.stop(funcname, result=T);
    }

# Append one of more lines of text to the plot-legend:
# NB: This works for ALL gsb-objects.

    public.legend := function (ref gsb, text=F, title=F,
			       index=F, clear=F, trace=F) {
	r := private.datobj.legend(gsb, txt=text, 
				   title=title, index=index,
				   clear=clear, trace=trace);
	if (is_fail(r)) print r;
	return T;
    }


#========================================================================
# Input of data-lines (1D vectors yy and xx, with flags ff:
#========================================================================

# Create an empty group (data-object) and return it:

    public.group := function (label=F, trace=F,
			      yannot=F, xannot=F, title=F, legend=F,
			      xname=F, xdescr=F, xunit=F, 
			      yname=F, ydescr=F, yunit=F) {
	group := private.datobj.group(label=label, trace=trace, 
				      yannot=yannot, xannot=xannot, 
				      title=title, legend=legend,
				      xname=xname, xdescr=xdescr, xunit=xunit, 
				      yname=yname, ydescr=ydescr, yunit=yunit);
	if (is_fail(group)) print group;
	return group;
    }

# Enter a filled group (i.e. a group filled with data-lines):
# If clear=T, clear the group/slice/brick (gsb) buffer first.

    public.putgroup := function (group=F, trace=F, 
				 clear=T, plot=F, full=F, replace=F,
				 special=F, attach=F,
				 yannot=F, xannot=F, title=F, legend=F,
				 xname=F, xdescr=F, xunit=F, 
				 yname=F, ydescr=F, yunit=F) { 
	s := paste('putgroup:',group.type,group.label);
	if (trace) print s;
	funcname := 'putgroup';
	private.prof.start(funcname, text=s, tracelevel=1);

	group.special := special;                          # e.g. 'index';
	if (is_record(attach)) group.attached := attach;   # user info

	private.datobj.labels(group, label=label, trace=trace, 
			      yannot=yannot, xannot=xannot, 
			      title=title, legend=legend,
			      xname=xname, xdescr=xdescr, xunit=xunit, 
			      yname=yname, ydescr=ydescr, yunit=yunit);

	if (replace) {                          # replace existing group
	    private.gsb_put (group, clear=clear, replace='first', 
			     trace=trace);
	    if (plot) private.plot('focus', full=full, 
				   origin='putgroup', trace=trace);  
	} else {                                # new group
	    private.gsb_put (group, clear=clear, replace=F, 
			     trace=trace);
	    if (plot) private.plot(full=full, trace=trace, 
				   origin='putgroup');    
	}
	return private.prof.stop(funcname, result=T);
    }


# Input of a data-line. It is appended to the current data-group:

    public.putline := function (ref group=F, label=F, trace=F,
				xx=F, yy=F, ff=F, line=F,
				style='lines', color=F, size=F,
				selcode=F, descr='descr') {
	funcname := 'putline';
	private.prof.start(funcname, text=F, tracelevel=1);

	if (is_record(line)) {
	    if (trace) print 'putline: using given data-line:',line.label;
	    # Data-line object given: use it
	} else {                              # make a line object
	    line := private.datobj.line(label=label, xx=xx, yy=yy, ff=ff,
					style=style, color=color, size=size,
					selcode=selcode, descr=descr,
					trace=F);
	    if (trace) print 'putline: construct new data-line:',line.label;
	}

	private.datobj.append_line(group, line, trace=trace);
	return private.prof.stop(funcname, result=T);
    }

# Emlation of some convenient gplot1d functions (with optional extras):
# Plot a single data-line:

    public.plotxy := function (xx=F, yy=F, label=F, style=F, line=F,
			       ff=F, color=F, size=F, descr=F,
			       yannot=F, xannot=F, title=F, legend=F,
			       xdescr=F, xunit=F, ydescr=F, yunit=F,
			       plot=T, trace=F) {
	funcname := 'plotxy';
	private.prof.start(funcname, text=F, tracelevel=1);

	group := private.gsb_get (name='first', type='group', trace=trace);
	if (!is_record(group)) {
	    group := private.datobj.group(label='plotxy', trace=trace, 
					  yannot=yannot, xannot=xannot, 
					  title=title, legend=legend,
					  xdescr=xdescr, xunit=xunit, 
					  ydescr=ydescr, yunit=yunit);
	    private.gsb_put(group, clear=T, trace=trace);
	    group := private.gsb_get (name='first', type='group', 
				      trace=trace);
	}
	public.putline (group, label=label, xx=xx, yy=yy, ff=ff, 
			line=line,
			style=style, color=color, size=size,
			descr=descr, trace=trace);
	if (plot) public.plot(origin='plotxy');
	return private.prof.stop(funcname, result=T);
    }

#==================================================================================
# Spawning of other plotters with data derived from the current one:
#==================================================================================

# Spawn a secondary plot-widget with the selected lines from the specified gsb.
# Optionally, convert the gsb first, or split it up into s series of line-gsbs.

    public.spawn:= function (name='focus', option=F, aux=[=], trace=F) {
	wider private;
	s := spaste('spawn(',name,' option=',option,'):');
	if (trace) print '\n',s;
	pgw_title := s;                          # default plotter title
	funcname := 'spawn';
	private.prof.start(funcname, text=s, tracelevel=1);

	# Some options do not require a current data-object:
	nogsb := T;
	if (option=='plotxy') {
	    if (private.check_spawned(title=pgw_title)){
		private.spawned.plotxy(line=aux.line, plot=T);
	    }
	    return private.prof.stop(funcname, result=T);

	} else {                                 # data-object needed
	    nogsb := F;
	    gsb := private.gsb_get (name, type="group slice", trace=trace);
	    if (!is_record(gsb)) {
		always := T;
		gsb := private.gsb_get (name, type="group slice", 
					trace=always);
		s1 := paste('no valid gsb found!',type_name(gsb));
		print s,s1;
		public.message(s1);
		return private.prof.stop(funcname, result=F);
	    }
	}

	# Go through the gsb-related options (first generic, then gsb-specific):
	if (nogsb) {
	    # Do nothing here (already done above);

	} else if (option=='copy') {                    # copy selection
	    newgsb := private.datobj.copy(gsb,'selected_or_visible');
	} else if (option=='copy_selected') {           # copy selection
	    newgsb := private.datobj.copy(gsb,'selected');
	} else if (option=='copy_visible') {            # copy all visible
	    newgsb := private.datobj.copy(gsb,'visible');
	} else if (option=='statistics') {              # statistics
	    newgsb := private.datobj.gsb2statistics(gsb);
	} else if (option=='average') {                 # row/line average
	    newgsb := private.datobj.gsb2average(gsb);
	} else if (option=='histogram') {               # histogram
	    newgsb := 'histogram not yet implemented';
	} else if (option=='unop') {                    # unary operation
	    pgw_title := paste(pgw_title,aux.unop);
	    newgsb := private.datobj.mathop(gsb, mathop=aux.unop, aux=aux);
	} else if (option=='binop') {                   # binary operation
	    pgw_title := paste(pgw_title,aux.binop);
	    newgsb := private.datobj.mathop(gsb, mathop=aux.binop, 
					    rhs=aux.gsb, index=aux.index);
	    
	} else if (gsb.type=='slice') {                 # specific slice options
	    if (option=='specific_slice_option') {      # dummy place-holder
		newgsb := 'dummy slice option(?)';
	    } else if (option=='slice2group') {         # -> group
		newgsb := private.datobj.slice2group(gsb);
	    } else {     
		newgsb := paste('not recognised: slice option=',option);
	    }

	} else if (gsb.type=='group') {                 # specific group options
	    if (option=='specific_group_option') {      # dummy place-holder
		newgsb := 'dummy group option(?)';
	    } else {                      
		newgsb := paste('not recognised: group option=',option);
	    }
	}

	# Check the new gsb (newgsb), and spawn a new plotter for it:
	if (is_string(newgsb)) {                          # message
	    public.message(newgsb);
	    if (trace) print newgsb;
	    return private.prof.stop(funcname, result=F);
	} else if (!is_record(newgsb)) {                  # error
	    print s,'no valid newgsb';
	    return private.prof.stop(funcname, result=F);

	} else if (!private.check_spawned(title=pgw_title)){  # spawn...
	    print s,'problem with spawned plotter';
	    return private.prof.stop(funcname, result=F);

	} else if (newgsb.type=='group') {
	    r := private.spawned.putgroup(group=newgsb);  # not plotted yet
	} else if (newgsb.type=='line') {
	    r := private.spawned.plotxy(line=newgsb);     # not plotted yet
	} else if (newgsb.type=='slice') {
	    r := private.spawned.putslice(slice=newgsb);  # not plotted yet
	} else {
	    print s,'not recognised: newgsb type=',newgsb.type;
	    return private.prof.stop(funcname, result=F);
	}
	if (is_fail(r)) print r;

	# Set some overall options in the spawned plotter (...):
	private.spawned.set_display_option('cx2real',private.cx2real);
	if (newgsb.type=='group') {
	    ii := private.datobj.group_indices(newgsb,'all');
	    if (option=='statistics') {      
		private.spawned.set_display_option('yzero',T);
		# private.spawned.set_display_option('xzero',F);
		private.spawned.set_display_option('zero_offset');
	    } else if (len(ii)<=1) {
		private.spawned.set_display_option('zero_offset');
	    } else if (option=='slice2group') {
		private.spawned.set_display_option('auto_offset');
	    }
	} else if (newgsb.type=='slice') {
	    # No special options......?
	}
	if (is_fail(r)) print r;

	private.spawned.plot(origin='spawn');		# plot the result
	return private.prof.stop(funcname, result=T);
    }

# Check whether a spawned pgplotter has been defined. Do so if not;

    private.check_spawned := function (title=F) {
	wider private;
	if (!private.has_spawned) {			# does not exist
	    private.spawned := jenplot();
	    private.has_spawned := T;
	    whenever private.spawned.agent -> * do {
		s1 := paste($name,type_name($value),shape($value));
		print 'private.spawned.agent: event received:',s1;
		if ($name=='done') {
		    private.has_spawned := F;
		    # val private.spawned := F;		# DON'T!!!!
		    print 'private.has_spawned -> F';
		} else if ($name=='clicked_index_slice') {
		    private.clicked_index_slice($value);
		} else if ($name=='flags') {
		    # do what?
		} else {
		    print 'private.spawned.agent: event not recognised:',s1;
		}
	    }

	    private.spawned.gui(paste('spawned:',title));
	    private.spawned.tapedeck_enable(F);		# disable
	} else {					# exists already
	    private.spawned.clear();
	    private.spawned.tapedeck_enable(F);		# disable (?)
	}
	return T;					# OK
    }



#============================================================================ 
# Make the GUI:
#============================================================================ 

    private.check_gui := function() {
	wider private;
	if (is_boolean(private.guiframe)) {		# no guiframe yet
	    public.gui();
	}
    }

    public.gui := function (title='jenplot') {
	wider private;
	funcname := 'gui';
	# private.prof.start(funcname, text=F, tracelevel=1);

	tk_hold();

	# Main gui frame:
	private.guiframe := frame(title=title, side='top');
	# NB: The first plot pruduces a flurry of 4-6 (?) resize events.
	private.resize_counter := 3;
	whenever private.guiframe -> resize do {
	    private.resize($value);
	}
	whenever private.guiframe -> killed do {
	    print s := 'jenplot: guiframe killed event';
	    public.done();
	}

	private.topframe := frame(private.guiframe, side='left',
				  height=10, expand='x');
	private.middleframe := frame(private.guiframe, side='left');
	private.bottomframe := frame(private.guiframe, side='left',
				  height=10, expand='x');

	private.midleftframe := frame(private.middleframe, side='top');
	private.midrightframe := frame(private.middleframe, side='top',
				       width=30, expand='y');

	# midleft-frame: pgplotter widget:
	include 'pgplotwidget.g';
	private.pgw := pgplotwidget(private.midleftframe);
	private.pgwaux.attach_pgw(private.pgw);

	# Mouse-motion callback supersedes default one in pgwaux:
	private.pgwaux.setcallback (action='motion', 
				    callback=private.mousemotion);

	# Mouse-click callback precedes default one in pgwaux:
	# NB: A boxcursor is started if this callback returns F!
	private.pgwaux.setcallback (action='button', button='left',
	 			    region='plot_window', trace=F, 
	 			    callback=private.clicked_plotwindow);

	# midright-frame: buttons
	# dummy1 := frame(private.midrightframe, height=40, expand='none');
	private.make_rightside_menu(private.midrightframe);

	# top-frame:
	private.make_file_menu(private.topframe);
	private.make_display_menu(private.topframe);
	private.make_cx2real_menu(private.topframe);
	private.make_select_menu(private.topframe);
	# private.make_delete_menu(private.topframe);
	private.make_flag_menu(private.topframe);
	# private.make_ops_menu(private.topframe);
	private.make_clipboard_menu(private.topframe);
	private.make_spawn_menu(private.topframe); 

	dummy3 := frame(private.topframe, height=1);	# padding
	if (private.debugging.menu) {
	    private.make_debug_menu(private.topframe);
	}
	private.make_help_menu(private.topframe);

	# bottom-frame: dismiss and label
	private.gui_label := label(private.bottomframe, width=75,
				   background='white', fill='x');
	private.write_gui_label ('gui_label');
	dummy2 := frame(private.bottomframe, height=1);	# padding
	private.jenguic.define_button(private.bottomframe, 'dismiss', 
			      callback=public.done, background='orange'); 

	# tapedeck control:
	if (is_record(private.index)) {                # index defined
	    public.tapedeck_enable(T);                 # enable
	} else {                                       # not defined
	    private.index := F;                        # just in case
	    public.tapedeck_enable (F);		       # disable
	}

	tk_release();

	return T;
	# return private.prof.stop(funcname, result=T);
    }

# Executed upon resize:

    private.resize := function (rec=F, trace=F) { 
	wider private;
	changed := F;                                   # only if changed
	# changed := any(rec.old!=rec.new);               # any change
	ratio := (rec.new/rec.old);
	if (any(ratio>1.1)) changed := T;
	if (any(ratio<0.9)) changed := T;
	s := paste('jenplot.resize(',rec,'): -> changed=',changed);
	s := paste(s,'resize_counter=',private.resize_counter);
	if (trace) print s;
	funcname := 'resize';
	private.prof.start(funcname, text=s, tracelevel=1);
	if (is_record(private.pgw)) {                   # redundant...?
	    private.resize_counter -:= 1;		# decrement
	    # if (changed && (private.resize_counter<=0)) { # ignore initial flurry
	    if (private.resize_counter<=0) {            # ignore initial flurry
		public.replot(origin='resize', trace=trace);
	    }
	    public.message(s);
	}
	return private.prof.stop(funcname, result=T);
    }



#=======================================================================
# Boxcursor (rubber band) events:
#=======================================================================

    private.boxcursor := function (bc=F, trace=F) {
	wider private;
	s := paste('jenplot.boxcursor(): bc.code=',bc.code);
	if (trace) print s;
	funcname := 'boxcursor';
	private.prof.start(funcname, text=s, tracelevel=1);

	if (is_boolean(bc)) {		              # not active (?)
	    print 'jenplot.boxcursor: bc is not active (boolean)??';
	    return private.prof.stop(funcname, result=F);
	}

	replot := F;
	gsb := private.gsb_get ('focus', type="group slice", trace=trace);
	if (is_boolean(gsb)) {                        # gsb problem
	    print 'jenplot.boxcursor: gsb problem (boolean!)';
	    return private.prof.stop(funcname, result=F);

	# Left button: 
	} else if (bc.code==1) {                       # left button
	    #......................................................

	# Other buttons: make a zoom-box (in focus gsb AND its parent!):
	} else if (bc.code==2 || bc.code==3) {         # other button(s)
	    gsb_parent := private.gsb_get ('focus_parent', trace=trace);
	    iinside := private.datobj.set_box(gsb_parent, bc=bc, trace=F,
					      unflagged=T, flagged=F);
	    iinside := private.datobj.set_box(gsb, bc=bc, trace=F,
					      unflagged=T, flagged=F);
	    if (is_fail(iinside)) {
		replot := iinside;                     # i.e: replot=fail
	    } else if (is_boolean(iinside)) {
		s := paste('iinside is boolean...?');
	    } else {
		replot := T;                           # default
		if (gsb.type=='slice') {
		    # OK, do nothing special
		} else if (gsb.type=='group' && len(iinside)<=0) {
		    # Change the viewport only if there are any data inside it:
		    replot := F;
		    s := paste('no points inside box: view-port not changed');
		}
	    }

	# Flagging via box: not used for the moment
	} else if (bc.code==2 || bc.code==3) {         # other button(s)
	    if (gsb.type=='group') {
		replot := private.datobj.bc2flagbox_group(gsb, bc, trace=trace);
		private.sync_family(broadcast=T);
		private.datobj.set_display_option(gsb, 'showflags', value=T); 
	    } else if (gsb.type=='slice') {
		replot := private.datobj.bc2flagbox_slice(gsb, bc, trace=trace);
		private.sync_family(broadcast=T);
	    }

	} else {
	    print 'jenplot.boxcursor(): button-code not recognised:',bc,code;
	}

	# Check the result:
	if (is_fail(replot)) {
	    print 'jenplot.boxcursor()';
	    print replot;
	    return private.prof.stop(funcname, result=F);

	# Re-plot the focus gsb, if required:
	# NB: This would be quicker if the gsb knew its own index nr igsb....!
	} else if (replot) {
	    private.plot('focus', origin='boxcursor');   # re-plot focus gsb only
	    s := paste('defined new view-port, and re-plotted');
	}
	public.message(s);                         # 
	return private.prof.stop(funcname, result=T);
    }


#------------------------------------------------------------------------------
# Executed upon mouse-motion (necessary, but does nothing much):

    private.mousemotion := function (rec) {
	return T;      # disabled, and inhibit default routine in pgwaux	

	#---------------------------------------------------------------
	# Repository of some possibly useful earlier functionality
	#---------------------------------------------------------------
	# Not while earlier calls are being processed:
	if (private.check_processing('mousemotion')) return T;
	# Set the switch that indicates that processing is going on:
	private.check_processing('mousemotion', set=T, active=T, trace=F);
	# Release the function again:
	private.check_processing('mousemotion', set=T, active=F, trace=F);

	#---------------------------------------------------------------
        # Not while one of the mouse-buttons is held down:
	ms := private.pgwaux.mouse_status();    # request mouse status
	if (len(ms.down)>0) return F;           # ignore if any button down
	if (!is_record(private.pgw)) return F;

	#---------------------------------------------------------------
	# Only inside the plot-window:
	x := rec.world[1];			# from pgplotter
	y := rec.world[2];			# from pgplotter
	qwin := private.pgwaux.qwin();
	if (x*qwin.xdir < qwin.xblc*qwin.xdir || 
	    x*qwin.xdir > qwin.xtrc*qwin.xdir) {         
	    s := paste('outside plot-window: x=',x);
	    private.write_gui_label(s);
	    return F;
	} else if (y*qwin.ydir < qwin.yblc*qwin.ydir || 
		   y*qwin.ydir > qwin.ytrc*qwin.ydir) {         
	    s := paste('outside plot-window: y=',y);
	    private.write_gui_label(s);
	    return F;
	}
	#---------------------------------------------------------------
	return private.describe_point(rec);     # does not exist anymore
    }

# Helper function to inhibit multiple processing (e.g. mousemotion()):

    private.check_processing := function (name='noname', set=F, active=F, trace=F) {
	wider private;
	if (!has_field(private,'processing')) {
	    private.processing := [=];
	}
	if (!has_field(private.processing,name)) {
	    rr := [=];
	    rr.active := F;
	    rr.ncheck := 0;
	    rr.dcheck := 0;
	    private.processing[name] := rr;
	}
	if (set) {
	    private.processing[name].active := active;
	    if (trace) print 'check_processing:',name,':',private.processing[name];
	    if (active) private.processing[name].dcheck := 0;
	}
	private.processing[name].ncheck +:= 1;
	private.processing[name].dcheck +:= 1;
	return private.processing[name].active;
    }


#-------------------------------------------------------------------------
# Get the data-line/row point closest to the given x,y (in rec):

    private.get_closest_point := function (ref gsb, ref rec, trace=F) {
	x := rec.world[1];			# from pgplotter
	y := rec.world[2];			# from pgplotter
	rr := [=];                              # return-value

	# Slice:
	if (gsb.type=='slice') {
	    rr.irow := as_integer(y+0.5);
	    rr.irow := max(1,rr.irow);          # closest
	    rr.irow := min(gsb.nrow,rr.irow);   # closest
	    dxx := abs(gsb.xx-x);
	    rr.icol := ind(gsb.xx)[dxx==min(dxx)]; # closest
	    if (trace) print rr;
	    return rr;
	}

	# Assume gsb.type=='group':
	qwin := private.pgwaux.qwin();          # window pars
	dy := qwin.yspan/50;
	dx := qwin.xspan/50;
	xrange := x + [-1,1]*dx;                # capture range
	yrange := y + [-1,1]*dy;                # capture range
	rr.iline := rr.ipoint := F;
	rr.dxmin := dx;
	rr.dymin := dy;
	ii := private.datobj.group_indices(gsb,'visible');
	if (trace) print 'get_closest_point: dx/y=',dx,dy,'ii=',ii;
	ni := 0;
	for (i in ii) {
	    ni +:= 1;                           # counter
	    jj := private.datobj.line_inside_box (gsb.line[i], 
						  xrange=xrange, 
						  yrange=yrange,
						  unflagged=T,
						  flagged=T,
						  trace=F);
	    if (!is_integer(jj)) {              # problem
		next;                           # skip....?
	    } else if (len(jj)>0) {		# some points inside box
		line := ref gsb.line[i];        # convenience
		color := line.color;
		s := paste(gsb.type,i,ni,'njj=',len(jj),':',line.label,color);
		if (trace) print s;

		dy := abs(line.yy[jj]+line.yplotoffset-y);  
		dymin := min(dy);               # min abs value
		if (trace) print 'dymin=',dymin,rr.dymin;
		if (dymin>rr.dymin) next;       # none closer
		j := jj[dy==dymin];             # index in data-line 
		dxmin := abs(line.xx[j]+line.xplotoffset-x);
		if (trace) print 'dxmin=',dxmin,rr.dxmin;
		if (dxmin>rr.dxmin) next;       # not closer

		# OK, found closer point
		rr.iline := i;                  # index of closest data-line 
		rr.ipoint := j;                 # index of closest data-point 
		rr.dymin := dymin;              # new min value
		rr.dxmin := dxmin;              # new min value
		rr.x := line.xx[j];
		rr.y := line.yy[j];
		rr.xplot := rr.x + line.xplotoffset;
		rr.yplot := rr.y + line.yplotoffset;
		if (trace) print rr;
	    }
	}
	return rr;
    }

#--------------------------------------------------------------------------------
# Clicked in plot-window: check if clicked on one of the plotted items:

    private.clicked_plotwindow := function (rec, trace=F) {
	wider private;
	if (trace) print 'jenplot.clicked_plotwindow(): rec=',rec;
	funcname := 'clicked_plotwindow';
	private.prof.start(funcname, text=F, tracelevel=1);

	x := rec.world[1];			# from pgplotter
	y := rec.world[2];			# from pgplotter

	s := 'clicked in plot_window...';       # indicate something
	private.write_gui_label(s,color='black');
	public.message(s);                      # indicate

	# This is a callback function, attached to a mouse-button click.  
	# If the return-value is F: start a boxcursor (see pgwaux)
	# If it is T: do not start a boxcursor (always in this function) 
	result := T;                            # inhibit boxcursor

	gsb := private.gsb_get ('focus', type="group slice", trace=F);
	if (is_boolean(gsb)) {
	    return private.prof.stop(funcname, result=result);

	} else if (gsb.type=='group') {
	    rr := private.get_closest_point (gsb, rec, trace=F);
	    if (is_boolean(rr.iline)) {         # not clicked on line
		return private.prof.stop(funcname, result=result);

	    } else {                            # clicked on a line
		line := ref gsb.line[rr.iline]; # convenience
		private.select_line (rr.iline, select=!line.selected);
		private.pgw.sci(line.cindex);	# 
		private.pgw.slw(10);		# line width (unit=0.13 mm)
		private.pgw.pt(rr.xplot,rr.yplot,-1);	# mark item (x,y) point
		# private.pgw.pt(x,y,-1);	        # mark mouse [x,y] too.....? 

		s := private.datobj.format_point_descr (gsb, trace=F,
							colpnt=rr.ipoint, 
							rowline=rr.iline);
		private.write_gui_label(s,color='black');

		s := private.datobj.format_line_descr(line, box=gsb.box);
		# Alternative for the same thing:
		# s := private.datobj.format_line_descr(gsb, rowline=rr.iline);
		public.message(s);         # display statistics
	    }

	} else if (gsb.type=='slice') {
	    rr := private.get_closest_point (gsb, rec, trace=F);
	    s := private.datobj.format_point_descr (gsb, trace=F,
						    colpnt=rr.icol, 
						    rowline=rr.irow);
	    private.write_gui_label(s,color='black');
	    # NB: Select row rr.irow....?
	    s := private.datobj.format_line_descr(gsb, rowline=rr.irow);
	    public.message(s);             # display statistics

	    # Special case (see tapedeck control below):
	    if (gsb.special=='index') {
		code := gsb.yy[rr.icol,rr.irow];
		public.agent -> clicked_index_slice(code);
	    }
	}

	return private.prof.stop(funcname, result=result);    #.....?
    }


#------------------------------------------------------------------------------
# Executed if data-line annotation (yannot) label has been clicked on:
# If relevant, the entire gsb 'family' of the focus gsb is synchronised.
# The argument is a 'userdata' record:

    private.clicked_line_yannot := function (ud=F, trace=F) {
	wider private;
	if (trace) print 'jenplot.clicked_line_yannot():',ud;
	group := private.gsb_get ('focus', type="group");
	if (is_boolean(group)) return F;              # ....?

	iseq := ud.seqnr;			      # line nr in group
	line := ref group.line[iseq];                 # convenience
	private.select_line (iseq, select=!line.selected, trace=trace);

	# Display the vital statistics of the visible part of the line
	s := private.datobj.format_line_descr(line, box=group.box);
	public.message(s);
	return T;
    }

#------------------------------------------------------------------------------
# Executed if data-slice annotation (yannot) label has been clicked on:
# Gets here via an event from jenplot.datobj.
# If relevant, the entire gsb 'family' of the focus gsb is synchronised.
# The argument is a 'userdata' record, which was attached to the clitem:

    private.clicked_slice_yannot := function (ud=F, trace=F) {
	wider private;
	if (trace) print 'jenplot.clicked_slice_yannot():',ud;
	slice := private.gsb_get ('focus', type="slice");
	if (is_boolean(slice)) return F;                # .....?

	ii := private.datobj.slice_indices(slice,'visible', trace=trace);
	irow := ii.row[ud.iannot];                    # row nr in FULL slice
	private.select_row (irow, select='negate', trace=trace);

	# Display the vital statistics of the visible part of the row
	s := private.datobj.format_line_descr(slice, rowline=irow);
	public.message(s);                      
	return T;	
    }

#------------------------------------------------------------------------------
# Executed if data-slice color wedge has been clicked on:
# This causes a replot of the slice, with a different color wedge. 

    private.clicked_slice_wedge := function (ud=F, trace=F) {
	wider private;
	if (trace) print '\n jenplot.clicked_slice_wedge():',ud;
	if (!is_boolean(ud.cmin)) {                     # cmin specified
	    if (!is_boolean(ud.cmax)) {                 # cmax also 
		private.set_color_wedge('set_crange', trace=trace, 
					value=[ud.cmin,ud.cmax]);
	    } else {                                    # cmin only
		private.set_color_wedge('set_cmin', value=ud.cmin, trace=trace);
	    }
	} else if (!is_boolean(ud.cmax)) {              # cmax only
	    private.set_color_wedge('set_cmax', value=ud.cmax, trace=trace);
	} else if (!is_boolean(ud.cval)) {              # cval specified
	    if (ud.code==1) {                           # used left button
		private.set_color_wedge('set_cmax', value=ud.cval, trace=trace);
	    } else if (ud.code==2) {                    # used middle button
		private.set_color_wedge('auto_color_wedge', trace=trace);
	    } else if (ud.code==3) {                    # used right button
		private.set_color_wedge('set_cmin', value=ud.cval, trace=trace);
	    }
	} 
	return T;	
    }


#------------------------------------------------------------------------------
# Executed if plot-panel has been switched by clicking the mouse:

    private.switched_panel := function (dummy=F, trace=F) {
	wider private;
	if (trace) print 'jenplot.switched_panel():',dummy;
	gsb := private.gsb_get ('focus', type="any");
	if (is_record(gsb)) {
	    private.set_display_button_state (gsb, trace=trace);
	}
	return T;
    }


#------------------------------------------------------------------------------
# (De-)select one or more data-lines iseq (throughout its family, if any).
# If a family-member is currently plotted, update the relevant line on the plot.

    private.select_line := function (iseq=F, select=F, trace=F) {
	wider private;
	funcname := 'select_line';
	private.prof.start(funcname, text=F, tracelevel=1);

	# Decode the argument: select
	if (is_boolean(select)) {                       # T/F
	    if (select) action := 'select';             # see modify_group
	    if (!select) action := 'deselect';
	} else if (select=='negate') {
	    action := 'negate';
	} else {
	    print 'select_line: not recognised: select=',select;
	    return private.prof.stop(funcname, result=F);
	}

	# Update the line-selection (of the entire family):
	group := private.gsb_get('focus', trace=trace);
	private.datobj.modify_group(group, action, index=iseq, trace=trace);
	private.sync_family (trace=trace);              # 

	# Update the plotted status of the entire family:
	ii := private.gsb_get_indices ('focus_family', trace=trace);
	was := private.pgwaux.get_current_focus();      # keep for restore            
	for (i in ii) {                                 # gsb family members
	    rr := ref private.gsb_descr[i];             # convenience
	    if (trace) print rr;
	    if (rr.plotted) {                           # might not be plotted
		group := ref private.gsb[i];            # convenience
		private.pgwaux.select_panel(icol=rr.icol, irow=rr.irow);
		private.pgwaux.bbuf('select_line');	# fill command-buffer
		for (j in iseq) {                       # data-line number(s)
		    line := ref group.line[j];          # convenience
		    private.datobj.plot_line(line, erase=T);
		    private.datobj.plot_line(line);
		    k := line.clitem_index;
		    private.pgwaux.draw_clitems(index=k, erase=T);
		    cf := private.pgwaux.get_clitem(index=k, copy=F);
		    cf.emphasize := line.selected;
		    private.pgwaux.draw_clitems(index=k, trace=trace);
		    # if (trace) print j,k,'clitem:',cf.text,cf.emphasize;
		}
		private.pgwaux.ebuf('select_line');	# execute command-buffer
	    }
	}
	private.pgwaux.select_panel(icol=was.icol, irow=was.irow);   # restore
	s := paste('select_line(',select,'):',iseq);
	if (trace) print s;
	return private.prof.stop(funcname, result=s);
    }

#------------------------------------------------------------------------------
# (De-)select one or more slice-rows irow (throughout its family, if any).
# NB: Unlike select_line(), the plotted family members are NOT directly updated,
#     because the rows are easily distinguished from each other.

    private.select_row := function (irow=F, select=F, trace=F) {
	wider private;
	funcname := 'select_row';
	s := paste(funcname,'(',irow,select,'):');
	if (trace) print s;
	private.prof.start(funcname, text=s, tracelevel=1);

	# Decode the argument: select
	if (is_boolean(select)) {                       # T/F
	    if (select) action := 'select';             # see modify_group
	    if (!select) action := 'deselect';
	} else if (select=='negate') {
	    action := 'negate';
	} else {
	    print 'select_row: not recognised: select=',select;
	    return private.prof.stop(funcname, result=F);
	}

	# Update the row-selection (of the entire family):
	slice := private.gsb_get('focus', trace=trace);
	index := irow;
	# index := [col=F,row=irow];                # alternative (better?)
	private.datobj.modify_slice(slice, action, index=index, trace=trace);
	private.sync_family (trace=trace);              # 

	# Update the yannot emphasis (i.e. color) of the family:
	ii := private.gsb_get_indices ('focus_family', trace=trace);
	was := private.pgwaux.get_current_focus();      # keep for restore
	if (trace) print 'current focus:',was;
	for (i in ii) {                                 # gsb family members
	    rr := ref private.gsb_descr[i];             # convenience
	    if (trace) print rr;
	    if (rr.plotted) {                           # only if plotted
		private.pgwaux.select_panel(icol=rr.icol, irow=rr.irow);
		slice := ref private.gsb[i];            # convenience
		if (is_integer(slice.clitem_index)) {
		    private.pgwaux.bbuf('select_row');	# fill command-buffer
		    nci := len(slice.clitem_index);
		    for (j in index) {
			if (j<=0 || j>nci) next;        # message...?
			k := slice.clitem_index[j];     # 
			private.pgwaux.draw_clitems(index=k, erase=T);
			cf := private.pgwaux.get_clitem(index=k, copy=F);
			cf.emphasize := slice.row_selected[j];  
			if (trace) print j,k,'clitem:',cf.text,cf.emphasize;
			r := private.pgwaux.draw_clitems(index=k, trace=trace);
			if (is_fail(r)) print r;
		    }
		    private.pgwaux.ebuf('select_row');	# execute command-buffer
		}
	    }
	}
	private.pgwaux.select_panel(icol=was.icol, irow=was.irow);   # restore
	s := paste('select_row(',select,'):',index);
	if (trace) print s;
	return private.prof.stop(funcname, result=s);
    }

#------------------------------------------------------------------------------
# Synchronise the flags, selection, deletion etc  of the entire gsb family with 
# those of the focus gsb. NB: Do not replot straight-away.

    private.sync_family := function (iseq=F, broadcast=F, trace=F) {
	wider private;
	funcname := 'sync_family';
	s := paste(funcname,'(',iseq,broadcast,'):');
	if (trace) print s;
	private.prof.start(funcname, text=s, tracelevel=1);

	# First deal with the focus gsb:
	gsbfocus := private.gsb_get ('focus', trace=trace);          # 
	ifocus := private.gsb_get_indices ('focus', trace=trace);
	s1 := paste(s,'focus:',ifocus,gsbfocus.type,gsbfocus.label);
	if (gsbfocus.type=='group') {
	    jjfocus := private.datobj.group_indices(gsbfocus,iseq);
	    if (trace) print s1,': jjfocus=',jjfocus;
	    if (broadcast) public.agent -> flags(gsbfocus);  # entire group
	} else if (gsbfocus.type=='slice') {
	    if (broadcast) public.agent -> flags(gsbfocus.ff);
	}

	# Then deal with its family:
	ii := private.gsb_get_indices ('focus_family', trace=trace);
	ii := ii[ii!=ifocus];                           # exclude ifocus
	for (i in ii) {                                 # gsb family members
	    if (trace) print s,'family(focus excluded):',ii;
	    gsb := ref private.gsb[i];                  # convenience
	    if (gsb.type=='slice') {
		private.datobj.sync_slice(gsb, gsbfocus, trace=trace);
	    } else if (gsb.type=='group') {
		private.datobj.sync_group(gsb, gsbfocus, index=iseq,
					  trace=trace);
	    } else {
		print s1,'gsb type not recognised:',gsb.type;
	    }
	}
	return private.prof.stop(funcname, result=T);
    }
	

#==================================================================================
# Various user-menus:
#==================================================================================

#-------------------------------------------------------------------------------
# Make some menu-buttons on the right side:

    private.make_rightside_menu := function (ref bframe=F) {
	funcname := 'make_rightside_menu';
	private.prof.start(funcname, text=F, tracelevel=1);

	private.jenguic.define_button(bframe, ' ', btype='space');
	private.make_plot_menu(bframe); 

	private.jenguic.define_button(bframe, ' ', btype='space'); 
	private.make_print_menu(bframe); 

	private.jenguic.define_button(bframe, ' ', btype='space'); 
	private.make_appl_menu(bframe); 

	private.jenguic.define_button(bframe, ' ', btype='space'); 
	private.make_tapedeck_menu (bframe);
	return private.prof.stop(funcname, result=T);
    }

#----------------------------------------------------------------------------------
# Print-menu: 

    private.make_print_menu := function (ref bframe=F) {
	bmenu := private.jenguic.define_button(bframe, 'print', btype='menu');
    	private.jenguic.define_button(bmenu, 'print_hardcopy', 'hardcopy', 
				      callback=public.print);
	return T;
    }


#----------------------------------------------------------------------------------
# Application (feedback) menu: 

    private.make_appl_menu := function (ref bframe=F) {
	bmenu := private.jenguic.define_button(bframe, 'appl.', btype='menu');
	for (name in "continue cancel inspect") {
	    private.jenguic.define_button(bmenu, spaste('appl_',name), name, 
					  callback=private.do_applic);
	}
	private.jenguic.add_menu_help(bmenu, 'appl', 
				      callback=private.do_applic);
	return T;
    }

    private.do_applic := function (name=F, trace=F) {
	wider private;
	s := spaste('do_applic(',name,')');               
	if (trace) print s;
	public.message(s);

	option := private.strip_off(name, 'appl', trace=trace);
	gsb := private.gsb_get('focus_parent', trace=trace);

	if (option=='help') {    
	    r := private.jenplot_help.show('appl');
	} else if (!is_record(gsb)) {
	    public.message('no focus_parent gsb!');
	} else if (!has_field(gsb,'attached')) {
	    public.message('gsb does not have field: attached!');
	} else if (!is_record(gsb.attached)) {
	    public.message('gsb.attached is not a record!');
	} else if (option=='continue') {
	    if (has_field(gsb.attached,option)) {
		public.agent -> appl_continue(gsb.attached[option]);
	    } else {
		public.message('gsb.attached does not have field: continue!');
	    }
	} else if (option=='cancel') {
	    if (has_field(gsb.attached,option)) {
		public.agent -> appl_continue(gsb.attached[option]);
	    } else {
		public.message('gsb.attached does not have field: cancel!');
	    }
	} else if (option=='inspect') {
	    include 'inspect.g';
	    inspect(gsb.attached,'gsb.attached');
	} else {
	    print 'do_applic: not recognised:',option;
	    return F;
	}
	return T;
    }


#----------------------------------------------------------------------------------
# Plot-menu: 

    private.make_plot_menu := function (ref bframe=F) {
	bmenu := private.jenguic.define_button(bframe, 'plot', btype='menu');
	for (name in "replot unzoom fullview full fast same_box") {
	    private.jenguic.define_button(bmenu, spaste('plot_',name), name, 
					  callback=private.do_plot);
	} 
	private.jenguic.add_menu_help(bmenu, 'plot', 
				      callback=private.do_plot);
	return T;
    }

    private.do_plot := function (name=F, trace=F) {
	wider private;
	s := spaste('do_plot(',name,')');               
	public.message(s);
               
	if (name=='plot_replot') {
	    public.replot(origin='do_plot', trace=trace);
	} else if (name=='plot_same_box') {
	    private.samebox(trace=trace);
	} else if (name=='plot_unzoom') {
	    private.fullview('focus', trace=trace);
	} else if (name=='plot_fullview') {
	    private.fullview(trace=trace);
	} else if (name=='plot_full') {
	    public.plot_full(trace=trace);
	} else if (name=='plot_fast') {
	    public.plot_fast(trace=trace);
	} else if (name=='plot_help') {    
	    r := private.jenplot_help.show('plot');
	} else {
	    print 'do_plot: not recognised:',name;
	    return F;
	}
	return T;
    }

# Replot all plotted gsb's, after removing zoom-boxes (if any);
# NB: The zoom-box is also removed from any parent gsb's.

    private.fullview := function (name=F, trace=F) {
	wider private;
	s := spaste('jenplot.fullview(',name,'):');
	if (is_boolean(name) || name=='all') {
	    name := F;
	    gsbname := 'plotted_and_parent';
	} else if (name=='focus') {
	    gsbname := 'focus_and_parent';
	}
	ii := private.gsb_get_indices (gsbname, trace=F);
	s := paste(s,gsbname,'-> ii=',ii);
	if (trace) print s;

	replot := F;                                # only if necessary
	for (i in ii) {
	    gsb := ref private.gsb[i];
	    if (is_record(gsb.box)) replot := T;    # necessary
	    if (trace) print i,'box=',type_name(gsb.box),'->',replot;
	    private.datobj.set_box(gsb, trace=F);   # remove box (if any)
	    gsb.cfixed := F;                        # restore auto-wedge (slice) 
	} 
	# private.resize_counter := 0;                # see .resize()
	if (replot) public.replot(name, origin='fullview');
	return T;
    }

# Replot the entire plotted family with the same zoom-box as the focus gsb:

    private.samebox := function (trace=F) {
	wider private;
	k := private.gsb_get_indices('focus');
	ii := private.gsb_get_indices('focus_family');
	if (trace) print 'same_box: k=',k,'ii=',ii;
	replot := F;                                # only if necessary
	for (i in ii) {
	    replot := T;                            # necessary
	    private.datobj.set_box(private.gsb[i], 
				   bc=private.gsb[k].box);
	}
	if (replot) public.plot(origin='samebox');
    }

#----------------------------------------------------------------------------------
# Spawn: Generate another plotter with data derived from the current one: 

    private.make_spawn_menu := function (ref bframe=F) {
	bmenu := private.jenguic.define_button(bframe, 'spawn', btype='menu');

	private.jenguic.define_button(bmenu, btype='menusep');
	for (name in "complex") {
	    private.jenguic.define_button(bmenu, spaste('spawn_',name), name, 
					  btype='check',
					  callback=private.do_spawn);
	}
	private.set_spawn_button_state();

	private.jenguic.define_button(bmenu, btype='menusep');
	ss := "slice2group copy";
	for (name in ss) {
	    private.jenguic.define_button(bmenu, spaste('spawn_',name), name, 
					  callback=private.do_spawn);
	} 

	private.jenguic.define_button(bmenu, btype='menusep');
	ss := "average statistics histogram";
	for (name in ss) {
	    private.jenguic.define_button(bmenu, spaste('spawn_',name), name, 
					  callback=private.do_spawn);
	} 

	private.jenguic.define_button(bmenu, btype='menusep');
	ss := "smooth differentiate integrate"; 
	ss := [ss, "fft_forward fft_backward autocorr"];
	ss := [ss, "fit_poly subtract_poly"];
	for (name in ss) {
	    private.jenguic.define_button(bmenu, spaste('spawn_',name), name, 
					  callback=private.do_spawn);
	} 

	private.jenguic.add_menu_help(bmenu, 'spawn', 
				      callback=private.do_spawn);
	return T;
    }

# Helper function to update the state of the gui spawn buttons with
# the values in private.spawn:

    private.set_spawn_button_state := function (complex=T, trace=F) {
	if (is_boolean(private.guiframe)) return F;          # no gui (yet)
	wider private;
	if (!has_field(private,'spawning')) private.spawning := [=];
	private.spawning.button := [=];                
	private.spawning.button.spawn_complex := complex;
	private.jenguic.button_state(private.spawning.button, set=T, 
				     trace=trace);
	return T;
    } 

# Helper function to strip off a given substring from string 'name':

    private.strip_off := function (name=F, sub=F, sep='_', trace=F) {
	ss := split(name,sep);               # split into substrings
	ss := ss[ss != sub];                 # remove substring
	sout := paste(ss,sep=sep);
	if (trace) {
	    s := spaste('split_off(',name,' sub=',sub,' sep=',sep,'):');
	    print s := paste(s,'->',sout);
	}
	return sout;
    }

# Deal with the various spawn options:

    private.do_spawn := function (name=F, trace=F) {
	option := private.strip_off(name,'spawn');

	# Various groups of spawn operations need different treatment: 
	spops := "copy slice2group average";     # general ops
	spops := [spops,"statistics histogram autocorr"];
	unops := "differentiate integrate";      # unary ops
	unops := [unops,"autocorr fft_forward fft_backward"];           

	# Some options always require complex or real data:
	realops := "statistics histogram autocorr";  # specific real data ops
	cxops := "fft_backward";                     # complex data ops

	# Determine which gsb to use (gsb='focus' or 'focus_parent'):
	complex := private.spawning.button.spawn_complex;  
	if (any(option==realops)) {
	    gsbname := 'focus';                  # use focus gsb (real)
	} else if (any(option==cxops)) {
	    gsbname := 'focus_parent';           # use its complex parent
	    # NB: check if parent is actually complex....?
	} else if (complex) {
	    gsbname := 'focus_parent';           # use parent
	} else {
	    gsbname := 'focus';                  # use focus gsb (real)
	}

	# Message:
	s := paste('do_spawn(',name,'): complex=',complex,gsbname);
	if (trace) print s;
	public.message(s);
               
 
	if (name=='spawn_complex') {
	    return private.set_spawn_button_state(complex=!complex);

	} else if (option=='help') {    
	    r := private.jenplot_help.show('spawn');

	} else if (any(option==spops)) {         # spawn ops      
	    r := public.spawn(gsbname, option=option);

	} else if (any(option==unops)) {
	    aux := [unop=option];
	    r := public.spawn(gsbname, option='unop', aux=aux);

	} else if (option=='smooth') {    
	    aux := [unop=option, ww=[1,1,1,1,1]];
	    r := public.spawn(gsbname, option='unop', aux=aux);

	} else if (option=='fit_poly' ||
		   option=='subtract_poly') {    
	    aux := [unop=option, ndeg=4];        # default....?
	    r := public.spawn(gsbname, option='unop', aux=aux);

	# } else if (name=='spawn_split_into_panels') {
	#     r := public.spawn(gsbname, option='split');

	} else {
	    s := paste('do_spawn: option not recognised:',option);
	    print s;
	    public.message(s);
	    return F;
	}
	if (is_fail(r)) {
	    print s;
	    print r;
	}
	return T;
    }

#-------------------------------------------------------------------------------
# Make a menu-button for clipboard operations:

    private.make_clipboard_menu := function (ref bframe=F) {
	bmenu := private.jenguic.define_button(bframe, 'clipboard', btype='menu'); 
	for (name in "complex") {
	    private.jenguic.define_button(bmenu, spaste('cpb_',name), name, 
					  btype='check',
					  callback=private.do_clipboard);
	}
	private.set_clipboard_button_state();

	ss := "sep status clear"; 
	ss := [ss,'sep',"copy_selected copy_average"];
	ss := [ss,"copy_from_spawned_plotter"]; 
	ss := [ss,'sep',"subtract divide add multiply"]; 
	ss := [ss,"crosscorr convolve"]; 
	for (name in ss) {
	    if (name=='sep') {
		private.jenguic.define_button(bmenu, btype='menusep');  
	    } else {
		private.jenguic.define_button(bmenu, spaste('cpb_',name), name, 
					      callback=private.do_clipboard);
	    }
	}

	private.jenguic.add_menu_help(bmenu, 'clipboard', 
				      callback=private.do_clipboard);
	return T;
    }

# Helper function to update the state of the gui buttons with

    private.set_clipboard_button_state := function (complex=T, trace=F) {
	wider private;
	if (is_boolean(private.guiframe)) return F;          # no gui (yet)
	if (!has_field(private,'cpb')) public.clipboard();
	private.cpb.button := [cpb_complex=complex];                
	private.jenguic.button_state(private.cpb.button, set=T, trace=trace);
	rr := [clipboard='yellow'];                          # not empty                
	if (public.clipboard_empty()) rr.clipboard := F;
	private.jenguic.button_color(rr, set=T, trace=trace);
	return T;
    } 

# Callback function for operating on items:

    private.do_clipboard := function (name=F, trace=F) {
	complex := private.cpb.button.cpb_complex;  
	gsbname := 'focus';                      # use focus gsb
	if (complex) gsbname := 'focus_parent';  # use its complex parent
	s := spaste('do_clipboard(',name,'): complex=',complex,' ',gsbname);
	if (trace) print '\n\n',s;
	public.message(s);               
	cpb_binops := "cpb_subtract cpb_divide";
	cpb_binops := [cpb_binops,"cpb_add cpb_multiply"];


	if (name=='cpb_complex') {
	    complex := !complex;                 # toggle
	} else if (name=='cpb_help') {    
	    r := private.jenplot_help.show('clipboard');
	} else if (name=='cpb_clear') {
	    s := public.clipboard(clear=T);
	} else if (name=='cpb_status') {
	    s := public.clipboard(summary=T);

	} else if (name=='cpb_copy_from_spawned_plotter') { 
	    if (!private.has_spawned) {
		s := public.clipboard(clear=T);
		return public.message('no plotter spawned!');
	    }
	    gsb := private.spawned.clipboard(get=T);
	    if (!is_record(gsb)) {
		s := 'clipboard of spawned plotter is empty!';
		return public.message(s);
	    } else {
		private.copy_to_clipboard(gsb, trace=trace);
	    }

	} else if (name=='cpb_copy_selected') {		# 
	    gsb := private.gsb_get (gsbname, type="group slice", trace=trace);
	    line := private.datobj.get_line(gsb, trace=trace);
	    private.copy_to_clipboard(line, from=gsb, trace=trace);

	} else if (name=='cpb_copy_average') {		# 
	    gsb := private.gsb_get (gsbname, type="group slice", trace=trace);
	    line := private.datobj.average2line(gsb, trace=trace);
	    private.copy_to_clipboard(line, from=gsb, trace=trace);

	} else if (any(name==cpb_binops)) {
	    private.binop_clipboard(gsbname, name, trace=trace);

	# } else if (name=='cpb_plot') {
	#     Does not work very well. And what about complex...?
	#     aux := [=];
	#     aux.line := private.get_from_clipboard();
	#     if (!is_record(aux.line)) return F;
	#     public.spawn(option='plotxy', aux=aux, trace=trace);

	} else {
	    print 'do_clipboard: not recognised:',name;
	    return F;
	}

	# Finished: some common actions:
	private.set_clipboard_button_state(complex=complex);
	s := public.clipboard(summary=T);
	public.message(s);
	return T;
    }

# Helper functions for do_clipboard: Execute a binary operation:

    private.binop_clipboard := function (name='focus', binop='subtract', trace=F) {
	s := paste('binop_clipboard(',name,binop,'):');
	if (trace) print s;
	aux := [=];                                 # info record for .spawn()
	aux.binop := split(binop,'_')[2];           # strip off leading 'cpb_'
	aux.index :='selected_or_visible';
	aux.gsb := private.get_from_clipboard();
	if (!is_record(aux.gsb)) {
	    s := paste(s,'gsb is not a record');
	    return public.message(s);
	}
	r := public.spawn(name, option='binop', aux=aux, trace=trace);
	if (is_fail(r)) {
	    s := paste(s,': spawning problem');
	    print r;
	} else {
	    s := paste(s,': spawned new plotter');
	}
	return public.message(s);
    }

# Helper function to copy the given gsb (line) to the clipboard:

    private.copy_to_clipboard := function (gsb=F, ref from=F, trace=F) {
	s := paste('copy_to_clipboard(',type_name(gsb),type_name(from),'):');
	if (trace) print s;
	if (!is_record(gsb)) {
	    s := public.clipboard(clear=T, trace=trace);
	} else if (!has_field(gsb,'type')) {
	    s := paste(s,'gsb record has no type-field!');
	} else if (gsb.type != 'line') {
	    s := paste(s,'gsb type should be line, not:',gsb.type);
	} else {
	    if (is_record(from)) {           # 'from' may be group/slice
		if (trace) print 'copied from',from.type,from.label;
		for (fname in "xunit yunit xdescr ydescr xannot") {
		    gsb[fname] := from[fname];
		    if (trace) print '-',fname,':',gsb[fname];
		}
	    }
	    s := public.clipboard(gsb, trace=trace);
	}
	return public.message(s);
    } 

# Helper function to get a gsb (line) from the clipboard:

    private.get_from_clipboard := function (trace=F) {
	gsb := public.clipboard(get=T, trace=trace);
	if (is_record(gsb)) {
	    s := paste('got from clipboard:',gsb.type,gsb.label);
	} else {
	    s := public.clipboard(clear=T, trace=trace);
	}
	if (trace) print s;
	public.message(s);
	return gsb;
    } 

#-------------------------------------------------------------------------------
# Make a menu-button for item-operations:

    private.make_ops_menu := function (ref bframe=F) {
	bmenu := private.jenguic.define_button(bframe, 'ops', btype='menu'); 
	s := "subtract_clipboard divide_clipboard"; 
	s := [s,"fitpoly_0 fitpoly_1 fitpoly_2 fitpoly_auto"];
	s := [s,"subtract_poly_0 subtract_poly_1 subtract_poly_2"];
	for (name in s) {
	    private.jenguic.define_button(bmenu, name, 
				  callback=private.do_ops);
	}
	return T;
    }

# Callback function for operating on items:

    private.do_ops := function (name=F) {
	wider private;
	public.message(spaste('do_ops(',name,')'));               
	group := private.gsb_get ('focus');             # focus group
	if (is_boolean(group)) return F;
	ii := private.datobj.group_indices(group,'selected');

	if (len(ii)==0) {				# none selected
	    return T;			

	} else if (name=='subtract_clipboard' || 
		   name=='divide_clipboard') {
	    nitem := public.clipboard();		# nr of items
	    if (nitem<=0) {
		print s := paste('no items in/on clipboard!');
		public.message(s);
		return F;
	    }
	    cline := public.clipboard(get=1);		# temporary
	    if (name=='subtract_clipboard') {
		s1 := paste(cline.label,'subtracted from data-line:');
	    } else if (name=='divide_clipboard') {
		s1 := paste('divided by data-line',cline.label,':');
	    }
	    for (i in ii) {
		line := group.line[i];                  # convenience
		if (!private.datobj.commensurate(cline, line)) {
		    print s := paste('items not commensurate:',line.label);
		} else {
		    line.yy -:= cline.yy;
		    s1 := paste(s1,line.label);
		    line.modified := T;
		    group.modified := T;
		}
	    }
	    # private.pgwaux.legend(s1);		# add to legend...

	} else {
	    print 'do_ops: not recognised:',name;
	    return F;
	}
	# Take suitable action if modified:
	if (group.modified) private.plot(origin='do_ops');
	return T;
    }


#---------------------------------------------------------------------------------
# Tape-deck control panel
#---------------------------------------------------------------------------------

    private.make_tapedeck_menu := function (ref bframe=F) {
	wider private;
	private.jenguic.define_button(bframe, ' ', btype='space'); 
	private.tapedeckframe := frame(bframe,relief='groove',side='top',
				       height=10);

	private.freerunframe := frame(private.tapedeckframe,side='left',
				      height=1);
	private.jenguic.define_button(private.freerunframe, 
				      'go_backward', '<<',
				      callback=private.progress_control); 
	private.jenguic.define_button(private.freerunframe, 
				      'go_forward', '>>',
				      callback=private.progress_control, 
				      background='green'); 

	private.jenguic.define_button(private.tapedeckframe, 
				      'do_suspend', '.suspend.',
				      width=9,
				      callback=private.progress_control, 
				      background='yellow'); 

	private.onestepframe := frame(private.tapedeckframe,side='left',
				      height=10);
	private.jenguic.define_button(private.onestepframe, 
				      'step_backward', '|<',
				      callback=private.progress_control); 
	private.jenguic.define_button(private.onestepframe, 
				      'step_forward', '>|',
				      callback=private.progress_control); 

	private.jenguic.define_button(private.tapedeckframe, 
				      'plot_index', 'index',
				      callback=private.plot_index); 

	private.strideframe := frame(private.tapedeckframe,side='top',
				     relief='groove');
	private.jenguic.define_button(private.strideframe, 
				      'stride_dim', 'stride=1',
				      width=10,
				      callback=private.stride_control, 
				      background='pink', disabled=F);
 
	# private.sstrideframe := frame(private.strideframe,side='left',
	# 			     height=10);
	# private.jenguic.define_button(private.sstrideframe, 
	# 			      'stride_decr', '<s',
	# 			      background='pink', 
	# 			      callback=private.progress_control); 
	# private.jenguic.define_button(private.sstrideframe, 
	# 			      'stride_incr', 's>',
	# 			      background='pink', 
	# 			      callback=private.progress_control); 

	private.jenguic.define_button(private.tapedeckframe, 
				      'do_abort', 'break',
				      callback=private.progress_control, 
				      background='red'); 
	private.jenguic.define_button(bframe, ' ', btype='space'); 
	return T;
    }    

# Generate and plot an overview of the data-slices available with .index. 

    private.plot_index := function (name=F, trace=F) {
	if (trace) print 'plot_index:',name;
	if (!is_record(private.index)) {
	    return public.message('no index active');
	}
	rr := private.index.get_encoded();
	if (trace) print rr;
	if (!is_record(rr)) return F;

	title := 'overview of available slices';
	if (!private.check_spawned(title=title)) return F;
	r := private.spawned.putslice('index', plot=T, trace=trace,
				      special='index',
				      yy=rr.encoded, xx=F, 
				      transpose=F,
				      yannot=rr.yannot, xannot=rr.xannot, 
				      title=title, legend=F,
				      xname=F, xdescr=rr.xdescr, xunit=F, 
				      yname=F, ydescr=rr.ydescr, yunit=F);
	if (is_fail(r)) print r;
	return T;
    }

# Function called when spawned plotter generates event 'clicked_index_slice': 

    private.clicked_index_slice := function (code, trace=F) {
	s := paste('jenplot.clicked_index(code=',code,'):');
	s := paste(s,'.index=',type_name(private.index));
	if (trace) print s;
	if (is_record(private.index)) {
	    s1 := private.index.set_to_index(code=code);
	    public.message(s1);                # display new status
	    private.progress_control ('step_forward');
	}
	return T;
    }
	

# Callback for tapedeck control buttons:

    private.progress_control := function (name=F, trace=F) {
	if (trace) print 'progress_control:',name;
	if (is_record(private.index)) {
	    private.index.agent -> progress_control(name);
	    if (name=='do_abort') {
		public.index();				# disable
		return T;
	    } else if (name=='do_suspend') {
		# private.plot();			# replot (?)
	    }
	    private.pgwaux.delay(0.2);		        # essential!
	    s := private.index.get_progress_message();
	    public.message(s);
	    s := private.index.get_stride_message();
	    b := private.jenguic.get_button('stride_dim');  
	    b -> text(s);                               
	}
	return T;
    }

# Callback for tapedeck control buttons:

    private.stride_control := function (name=F, trace=F) {
	s := paste('stride_control(',name,')');
	if (trace) print s
	if (is_record(private.index)) {
	    if (name=='stride_dim'  || 
		name=='stride_incr' ||
		name=='stride_deccr') {
		private.index.agent -> stride_control(name);
		public.message(name,s);              # temporary
	    } else {
		return public.message(name,s, type='notrec');
	    }
	    private.pgwaux.delay(0.2);	              # essential!
	    s := private.index.get_stride_message();  # 'stride=n'
	    b := private.jenguic.get_button('stride_dim'); 
	    b -> text(s);                             # button caption  
	}
	return T;
    }

# Attach/detach an indexing object (record) to the plotter:

    public.index := function (ref index=F) {
	wider private;
	if (is_record(index)) {                        # index given:
	    private.index := index;                    #   establish
	    whenever private.index.agent -> suspend do {
		# print 'jenplot.index(): suspend event received from index',$value;
		if (is_record(private.index)) {        # ncessary check...!?
		    s := private.index.get_suspend_message();
		    b := private.jenguic.get_button('do_suspend');  
		    b -> text(s);                          
		}     
	    }
	    public.tapedeck_enable(T);                 #   enable
	} else {                                       # no argument:
	    private.index := F;                        #   delete 
	    public.tapedeck_enable(F);                 #   disable
	}
    }

# Enable/disable the tape-deck control buttons (see putslice()):

    public.tapedeck_enable := function (enable=T) {
	wider private;
	if (is_boolean(private.pgw)) return F;	       # not yet defined
	ss := "go_forward step_forward go_backward step_backward";
	ss := [ss,"do_suspend do_abort"];
	ss := [ss,"plot_index stride_dim"];
	# ss := [ss,"stride_incr stride_decr"];        # obsolete?
	if (enable) {
	    # enable := F;
	    # print 'tapedeck_enable(T): inhibited temporarily:',enable;
	}
	for (name in ss) {
	    c := private.jenguic.get_ctrl(name);
	    if (!is_record(c)) next;
	    if (enable) {
		c.button -> disabled(F);
		c.button -> foreground(c.foreground);
		c.button -> background(c.background);
	    } else {
		c.button -> disabled(T);
		c.button -> foreground('lightgrey');
		c.button -> background('lightgrey');
	    }
	}
	private.tapedeck_enabled := enable;	# status
	return T;
    }

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# Make a menu-button for help:

    private.make_help_menu := function (ref bframe=F) {
	bmenu := private.jenguic.define_button(bframe, 'help', btype='menu'); 
	for (name in "general full manual") {
	    private.jenguic.define_button(bmenu, spaste('help_',name), name,
					  callback=private.show_help); 
	}
	# private.jenguic.define_button(bmenu, btype='menusep'); 
	# add the standard/required aips++ help items
	return T;
    }

    private.show_help := function (name=F) {
	wider private;
	if (name=='help_general') {
	    private.jenplot_help.show('general');
	} else if (name=='help_full') {
	    private.jenplot_help.show('manual');
	} else if (name=='help_manual') {
	    s := private.jenplot_help.print('manual');
	    public.message(s);
	} else {
	    print 'show_help: not recognised:',name;
	}
	return T;
    }

#-------------------------------------------------------------------------------
# Make a menu-button for display options:

    private.make_display_menu := function (ref bframe=F) {
	wider private;
	bmenu := private.jenguic.define_button(bframe, 'display', btype='menu'); 

	name := ' '; caption := ' '; n := 0;
	name[n+:=1] := 'showlegend'; caption[n] := 'show legend';
	name[n+:=1] := 'showflags'; caption[n] := 'show flags';
	name[n+:=1] := 'sep';
	name[n+:=1] := 'yzero'; caption[n] := 'x-axis (y=0)';
	name[n+:=1] := 'xzero'; caption[n] := 'y-axis (x=0)';
	name[n+:=1] := 'xyzero'; caption[n] := 'both axes';
	# name[n+:=1] := 'xygrid'; caption[n] := 'xy-grid';
	# name[n+:=1] := 'yratchet'; caption[n] := 'y-ratchet';
	# name[n+:=1] := 'xratchet'; caption[n] := 'x-ratchet';
	for (i in ind(name)) {
	    if (name[i]=='sep') {
		private.jenguic.define_button(bmenu, btype='menusep'); 
	    } else {
		private.jenguic.define_button(bmenu, name[i], 
					      caption[i], btype='check',   
					      callback=private.do_display);
	    }
	}

	private.jenguic.define_button(bmenu, btype='menusep');
	for (name in "zero_offset auto_offset") {
	    private.jenguic.define_button(bmenu, name, btype='radio', 
					  callback=private.set_yoffset);
	}
	modmenu := private.jenguic.define_button(bmenu, 'modify_offset',
						 btype='menu');
	for (name in "*10 *5 *2 /2 /5 /10") {
	    private.jenguic.define_button(modmenu, spaste('offset_',name), 
					  caption=name, 
					  callback=private.set_yoffset);
	}
	private.jenguic.add_menu_help(bmenu, 'display', 
				      callback=private.do_display);
	return T;
    }

# Helper function to update the state of the gui display menu buttons with
# the values of the given gsb data-object (a bit of a kludge):

    private.set_display_button_state := function (ref gsb, trace=F) {
	if (is_boolean(private.guiframe)) return F;          # no gui (yet)
	if (!is_record(gsb)) {
	    print 'set_display_button_state: gsb is not a record!'; 
	    return F;
	} else {
	    button := [=];
	    ss := "showflags showlegend xzero yzero xyzero";
	    for (name in ss) { 
		button[name] := gsb[name];
	    }
	    button.zero_offset := [gsb.yplotoffset==0];
	    private.jenguic.button_state(button, set=T, trace=trace);
	}
	return T;
    } 

# Callback function to adjust group y-offset (plotted w.r.t. mean):

    private.set_yoffset := function (name=F, replot=T, trace=F) {
	wider private;
	s := spaste('set_yoffset(',name,' replot=',replot,'):'); 
	if (trace) print s;
	group := private.gsb_get ('focus', type='group');
	if (is_boolean(group)) {
	    s := 'set_yoffset: only valid for gsb type: group';
	    public.message(s);
	    if (trace) print s;
	    return F;
	}
	was := group.yplotoffset;                 # original value 
	if (name=='zero_offset') {
	    group.yplotoffset := 0;
	} else if (name=='offset_*2') {
	    group.yplotoffset *:= 2;
	} else if (name=='offset_*5') {
	    group.yplotoffset *:= 5;
	} else if (name=='offset_*10') {
	    group.yplotoffset *:= 10;
	} else if (name=='offset_/2') {
	    group.yplotoffset /:= 2;
	} else if (name=='offset_/5') {
	    group.yplotoffset /:= 5;
	} else if (name=='offset_/10') {
	    group.yplotoffset /:= 10;
	} else if (name=='auto_offset') {
	    offset := 1;	                  # temporary
	    if (offset<=0) offset := 1;		  # safety
	    group.yplotoffset := offset;
	# } else if (name=='radial') {            # not implemented
	} else {
	    print 'set_yoffset: not recognised:',name;
	    return F;
	}
	s := paste('group.yplotoffset:',was,'->',group.yplotoffset);
	public.message(s);
	if (group.yplotoffset != 0) {             # no x-axis
	    private.datobj.set_display_option(gsb, 'yzero', value=F); 
	}
	private.set_display_button_state (group, trace=F);
	group.modified := T;                      # for replot
	if (replot) private.plot('focus', origin='set_yoffset');
	return T;
    }

# Callback function to toggle the display-option switch in the focus object:

    private.do_display := function (name=F, value='toggle', replot=T, trace=F) {
	s := spaste('\n do_display(',name,' value=',value,'):');
	gsb := private.gsb_get('focus');
	if (trace) print s;
	public.message(s);
               
	ok := T;
	if (!is_record(gsb)) {
	    return F;
	} else if (gsb.type=='group') {
	    ok := T;                        # all options valid for data-groups
	} else if (gsb.type=='slice') {
	    ss := "xzero yzero xyzero";
	    if (any(name==ss)) {
		s := paste('option not valid for gsb type:',gsb.type);
		ok := F;                    # not OK
	    }
	} else {
	    s := paste('gsb type not recognised:',gsb.type);
	    ok := F;
	}
	# Only change things if ok:
	if (ok) {
	    private.datobj.set_display_option(gsb, name, value=value, 
					      trace=trace);
	    if (replot) private.plot('focus', origin='do_display');
	}
	# Make sure that the gui buttons are set in accordance with the gsb!
	# (Radio and check buttons have changed even though gsb may not have)
	private.set_display_button_state (gsb, trace=trace);    # always!
	public.message(s);                                 # last
	return T;
    }

# Set/get value of gsb field (while checking its presence!).
# If no gsb-object given, try the first stored one.....

    public.gsb_field := function (ref gsb=F, name=F, value=T, trace=F) {
	s := paste('jenplot.gsb_field(',name,value,'):');
	s := paste(s,'gsb=',type_name(gsb));
	if (trace) print s;
	if (!is_record(gsb)) {
	    gsb := private.gsb_get('first');    #.....?
	    if (!is_record(gsb)) {
		print s,'no gsb available (yet)..';
		return F;                       
	    }
	} 
	if (!has_field(gsb,name)) {
	    print s,'gsb has no field:',name;
	    return F;                       
	} else {                       # only if value != unset?
	    was := gsb[name];
	    gsb[name] := value;
	    s1 := spaste('gsb.',name,':',was,' -> ',value);
	    if (trace) print s1;
	    return gsb[name];
	}
    }

# Set display option (may need some more thought).

    public.set_display_option := function (name, value=T, trace=F) {
	wider private;
	s := paste('jenplot.set_display_option(',name,value,'):');
	if (trace) print s;

	if (any(name=="zero_offset auto_offset")) {
	    return private.set_yoffset(name, replot=F, trace=trace);

	} else if (name=='cx2real') {
	    return public.set_cx2real (value, trace=trace);

	} else {
	    gsb := private.gsb_get('first');    #.....?
	    if (!is_record(gsb)) {
		print s,'no gsb available (yet)..';
		return F;                       
	    }
	    if (trace) print s,gsb.type,gsb.label;
	    private.datobj.set_display_option(gsb, name, value=value, 
					      trace=trace);
	    public.message(s);
	    private.set_display_button_state (gsb, trace=F);
	}
	return T;
    }


# Callback function to influence the color (grayscale) wedge for slices:

    private.set_color_wedge := function (name=F, value=F, replot=T, trace=F) {
	wider private;
	slice := private.gsb_get ('focus', type='slice');
	if (is_boolean(slice)) {
	    return F;
	} else if (name=='set_crange') {
	    slice.cfixed := T;                   
	    value := range(value);                     # sort...?
	    slice.cmin := value[1];
	    slice.cmax := value[2];
	    s := paste('color wedge: crange set to',value); 
	} else if (name=='set_cmax') {
	    slice.cfixed := T;                      
	    slice.cmax := value;
	    s := paste('color wedge: cmax set to',slice.cmax); 
	} else if (name=='set_cmin') {
	    slice.cfixed := T;                     
	    slice.cmin := value;
	    s := paste('color wedge: cmin set to',slice.cmin);
	} else if (name=='auto_color_wedge') {
	    replot := slice.cfixed;                    # only if was fixed
	    slice.cfixed := F;                     
	    s := paste('color wedge: set to automatic');
	} else {
	    print 'set_color_wedge: not recognised:',name;
	    return F;
	}
	private.datobj.statistics(slice, full=T, enforce=T, trace=trace);
	if (replot) private.plot('focus',origin='set_color_wedge'); 
	public.message(s);                         # after plot!
	s := spaste('color wedge:  cmin=',slice.cmin,'  cmax=',slice.cmax);
	private.write_gui_label (s);
	return T;
    }

#-------------------------------------------------------------------------------
# Make a menu-button for item-flagging:

    private.make_flag_menu := function (ref bframe=F) {
	bmenu := private.jenguic.define_button(bframe, 'flag', btype='menu'); 
	for (name in "unflag test broadcast") {
	    private.jenguic.define_button(bmenu, spaste('flag_',name), 
					  name, btype='check',
					  callback=private.do_flag);
	}
	private.set_flag_button_state(broadcast=private.flagging.broadcast);

	private.jenguic.define_button(bmenu, btype='menusep');
	ss := "inside_zoom_box outside_zoom_box all_selected";
	for (name in ss) {
	    private.jenguic.define_button(bmenu, name,
					  callback=private.do_flag);
	}

	private.jenguic.define_button(bmenu, btype='menusep');
	ss := "above_wedge_max below_wedge_min inside_wedge_range";
	for (name in ss) {
	    private.jenguic.define_button(bmenu, name,
					  callback=private.do_flag);
	}

	private.jenguic.define_button(bmenu, btype='menusep');
	private.jenguic.define_button(bmenu, 'undo_last',
				      caption='undo_last (slice only)',
				      callback=private.do_flag);
	private.jenguic.define_button(bmenu, 'undelete',
				      caption='undelete (group only)',
				      callback=private.do_flag);
	private.jenguic.define_button(bmenu, 'count_flags',
				      callback=private.do_flag);

	private.jenguic.add_menu_help(bmenu, 'flag', 
				      callback=private.do_flag);
	return T;
    }

# Helper function to update the state of the gui flag buttons with
# the values in private.flagging:

    private.set_flag_button_state := function (unflag=F, test=F, 
					       broadcast=T, trace=F) {
	wider private;
	if (is_boolean(private.guiframe)) return F;    # no gui (yet)
	if (!has_field(private,'flagging')) private.flagging := [=];
	private.flagging.fflast := [];                 # undo disabled
	private.flagging.button := [=];                
	private.flagging.button.flag_unflag := unflag;
	private.flagging.button.flag_test := test;
	broadcast &:= private.flagging.broadcast;      # not if disabled
	private.flagging.button.flag_broadcast := broadcast;
	private.jenguic.button_state(private.flagging.button, set=T, 
				     trace=trace);
	return T;
    } 

# Callback function for flagging (points in) items:

    private.do_flag := function (name=F, trace=F) {
	wider private;
	s := paste('do_flag(',name,'):');
	public.message(s);               
	test := private.flagging.button.flag_test;            # convenience
	unflag := private.flagging.button.flag_unflag;        # convenience
	broadcast := private.flagging.button.flag_broadcast;  # convenience
	if (trace) print '\n\n',s,unflag,test,private.flagging.button;

	# First some options that do not require a gsb data-object:
	if (name=='flag_unflag') {
	    return private.set_flag_button_state(unflag=!unflag, test=test,
						 broadcast=broadcast);
	} else if (name=='flag_test') {
	    return private.set_flag_button_state(unflag=unflag, test=!test,
						 broadcast=broadcast);
	} else if (name=='flag_broadcast') {
	    return private.set_flag_button_state(unflag=unflag, test=test,
						 broadcast=!broadcast);
	} else if (name=='flag_help') {
	    return private.jenplot_help.show('flag');
	} 

	# Options that require a gsb data-object to be flagged:
	gsb := private.gsb_get ('focus', type="group slice");
	if (is_boolean(gsb)) {
	    private.flagging.fflast := [];                  # disable undo
	    return public.message('no data-object available for flagging');            

	} else if (name=='count_flags') {
	    s := private.datobj.format_flag_descr (gsb, trace=trace);
	    return public.message(s);            

	} else if (gsb.type=='slice') {
	    if (name=='undo_last') {
		if (len(private.flagging.fflast)==0) {
		    return public.message('no flags available for undo!');            
		} else {
		    rr := private.flag_slice (gsb, option='replace', 
					      ff=private.flagging.fflast, 
					      trace=trace);
		}
	    } else {
		rr := private.flag_slice (gsb, option=name, unflag=unflag, 
					  test=test, trace=trace);
	    }

	} else if (gsb.type=='group') {
	    rr := private.flag_group (gsb, option=name, unflag=unflag, 
				      test=test, trace=trace);
	}

	# Finish off, using the record rr returned by flag_slice/group():
	private.flagging.fflast := [];                    # disable undo
	if (is_record(rr)) {
	    private.flagging.fflast := rr.ffold;          # keep for undo
	    if (rr.modified) {                              # flags modified
		if (rr.unzoom) {
		    private.fullview('focus', trace=F);   # replot unzoomed
		} else {
		    private.plot('focus', origin='do_flag');  # replot
		}
		private.sync_family (broadcast=broadcast, trace=F);
	    } 
	    public.message(rr.message);                   # after plot!
	    private.write_gui_label(rr.message);          # ....?
	} else if (is_string(rr)) {                       # error message
	    public.message(rr);                           # 
	    private.write_gui_label(rr);                  # ....?
	}
	return T;
    }

# Whole-slice flagging, using the given option (usually string): 

    private.flag_slice := function (ref gsb, option=F, ff=F, 
				    unflag=F, test=T, trace=F) {
	if (trace) print paste('flag_slice(',option,unflag,test,'):');

	unzoom := F;                                  # plot-option 
	rrout := [modify=F, ffold=[]];                # default
	rrout.message := option;                      # default

	if (gsb.type!='slice') {
	    return paste('gsb is not a slice');
	} else if (option=='replace') {               # use given ff
	    rrout.ffmod := ff;
	    rrout.modified := T;
	} else {                                      # calculate ffnew  
	    ffnew := array(F,gsb.ncol,gsb.nrow);      # boolean array
	    select := 'selected_or_visible';          # incl deleted rows!
	    if (option=='all_selected') select := 'selected';
	    ii := private.datobj.get_indices(gsb, select, trace=trace);
	    ffnew[ii.col,ii.row] := T;                # new flags
	    # fast alternative: ffnew[gsb.col_visible,gsb.row_visible] := T; 
	    if (option=='above_wedge_max') { 
		ffnew &:= [gsb.yy>gsb.cmax];      
	    } else if (option=='below_wedge_min') { 
		ffnew &:= [gsb.yy<gsb.cmin];        
	    } else if (option=='inside_wedge_range') { 
		ffnew &:= [gsb.yy>=gsb.cmin] & [gsb.yy<=gsb.cmax];       
	    } else if (option=='inside_zoom_box' ||
		       option=='all_selected' || 
		       option=='all_visible') { 
		# use ffnew as it is
		if (is_record(gsb.box)) unzoom := T;  # plot-option
	    } else if (option=='outside_zoom_box') { 
		if (!is_record(gsb.box)) {
		    return paste('no zoom_box defined!');            
		} else {
		    unzoom := T;                      # plot-option 
		    ffnew := !ffnew;
		}
	    } else {
		return paste('flag_slice: option not recognised:',option);
	    }
	    rrout := private.flag_modify (ffold=gsb.ff, ffnew=ffnew, 
				       unflag=unflag, test=test, trace=trace);
	}
	# Actually modify the flags and update statistics etc:
	if (is_record(rrout) && rrout.modified) {
	    gsb.ff := rrout.ffmod;                    # modified flags
	    private.datobj.modify_slice(gsb, 'sync', trace=trace);
	    private.datobj.statistics(gsb, full=T, enforce=T); 
	    private.datobj.set_display_option(gsb, 'showflags', value=T);
	} 
	rrout.unzoom := unzoom;                    # add parameter
	return rrout;                                 # return record
    }


# Group flagging (line-by-line), using the given option (string): 

    private.flag_group := function (ref gsb, option=F, 
				    unflag=F, test=T, trace=F) {
	if (gsb.type!='group') {
	    return paste('gsb is not a group, but:',gsb.type);
	} 

	# Select (indices ii of) data-lines:
	select := 'selected_or_visible';
	if (option=='all_selected') select := 'selected';
	if (option=='all_visible') select := 'visible';
	if (option=='undelete') select := 'deleted';
	ii := private.datobj.group_indices(gsb, select, trace=trace);
	if (len(ii)<=0) {
	    return paste('no data-lines found, selection=:',select);
	}

	# The output record rrout is used in jenplot.do_flag()
	unzoom := F;                               # plot-option
	rrout := [modify=F, ffold=[]];             # default
	rrout.message := 'no data-lines modified'; # default
  
	# Some special cases:
	if (option=='outside_zoom_box' ||
	    option=='inside_zoom_box') {
	    if (gsb.yplotoffset != 0) {
		# return paste('option requires zero_offset display:',option);
	    }
	} else if (option=='undelete') {
	    private.datobj.modify_group(gsb, 'undelete', index=ii,
					trace=trace);
	    rrout.modified := T;
	    rrout.message := paste('undeleted: lines:',len(ii),'range=',range(ii));
	    ii := [];                              # no longer needed
	}

	# Deal with the affected data-lines (ii), if any:
	for (i in ii) {
	    line := ref gsb.line[i];               # convenience
	    if (option=='outside_zoom_box') {
		if (!is_record(gsb.box)) {
		    return paste('no zoom_box specified');
		}
		unzoom := T;                       # plot-option
		box := gsb.box;                    # convenience
		ffnew := rep(F,len(line.ff));      #
		yyplotted := line.yy + line.yplotoffset;
		xxplotted := line.xx + line.xplotoffset;
		ffnew[yyplotted<box.ymin] := T;    # flag outside
		ffnew[yyplotted>box.ymax] := T;    # flag outside
		ffnew[xxplotted<box.xmin] := F;    # ignore outside
		ffnew[xxplotted>box.xmax] := F;    # ignore outside
	    } else if (option=='inside_zoom_box' || 
		       option=='all_selected' || 
		       option=='all_visible') {
		box := gsb.box;                    # convenience
		ffnew := rep(F,len(line.ff));      # 
		if (is_record(box)) {
		    unzoom := T;                   # plot-option
		    ffnew |:= [line.xx>=box.xmin] & [line.xx<=box.xmax];
		} else {
		    ffnew := rep(T,len(line.ff));
		}
	    } else {
		return paste('flag_group: option not recognised:',option);
	    }

	    rrout := private.flag_modify (ffold=line.ff, ffnew=ffnew, 
					  unflag=unflag, test=test, 
					  trace=trace);
	    if (is_record(rrout)) {
		if (rrout.modified) {
		    line.ff := rrout.ffmod;        # modified line flags
		    rrout.modified := T;             # causes replot
		    rrout.message := 'some lines modified';
		    if (all(line.ff)) {            # entire line flagged
			private.datobj.modify_group(gsb, 'delete', index=i,
						    trace=trace);
		    }
		}
		if (trace) print line.label,rrout.message;
	    } else {
		return paste('rrout not a record, but:',type_name(rrout));
	    }
	}

	# Finished:
	private.datobj.modify_group(gsb, 'sync', trace=trace);
	private.datobj.statistics(gsb, full=T, enforce=T); 
	private.datobj.set_display_option(gsb, 'showflags', value=T); 
	rrout.unzoom := unzoom;                    # add parameter
	return rrout;                              # return record
    }

# Helper function that modifies flags (independent of gsb type):

    private.flag_modify := function (ref ffold, ref ffnew, 
				     unflag=F, test=T, trace=F) {
        # Do some tests:
	if (F) {                                   # test shape.....
	    rr.message := paste('ffnew has the wrong shape');
	    return F;
	}

	rr := [=];                                 # return record
	rr.ffnew := ffnew;                         # returned....
	rr.ffold := ffold;                         # used in undo
	rr.nold := len(ffold[ffold]);              # nr of old flags
	rr.nnew := len(ffnew[ffnew]);              # nr of new flags
	s := paste('flagshape:',shape(ffold));
	s := spaste(s,' old=',rr.nold);
	if (unflag) {
	    rr.ffmod := ffold;   
	    rr.ffmod[ffnew] := F;                  # unflag 
	    s := spaste(s,' unflag=',rr.nnew);
	} else {
	    rr.ffmod := ffold | ffnew;             # combined flag array
	    s := spaste(s,' new=',rr.nnew);
	}
	rr.ntot := len(rr.ffmod[rr.ffmod]);        # new total
	rr.ndiff := len(rr.ffmod[rr.ffmod!=ffold]);   # nr of differences
	s := spaste(s,' diff=',rr.ndiff);

	if (test) {                                # test mode
	    rr.modified := F;                      # do not change
	    s := paste(s,' (test: flags not modified)');
	} else {                                   # flag mode
	    rr.modified := [rr.ndiff>0];           # indicate change
	    rr.ptot := as_integer((rr.ntot/len(rr.ffmod))*100); # percentage
	    s := spaste(s,' new total=',rr.ntot,' (',rr.ptot,'%)');
	}
	rr.message := s;
	if (trace) {
	    rr1 := rr;                             # copy rr
	    for (name in "ffnew ffold ffmod") rr1[name] := shape(rr1[name]);           
	    rr1.message := '...'; 
	    print 'flag_modify: rr=',rr1;
	}
	return rr;                                 # return record
    }


#-------------------------------------------------------------------------------
# Make a menu-button for item-deletion (obsolete?):

    private.make_delete_menu := function (ref bframe=F) {
	bmenu := private.jenguic.define_button(bframe, 'delete', btype='menu'); 
	s := "selected undo";
	for (name in s) {
	    private.jenguic.define_button(bmenu, name, 
				  callback=private.do_delete);
	}
	return T;
    }

# Callback function for deleting data-lines (family-wise if required):

    private.do_delete := function (name=F, trace=F) {
	wider private;
	public.message(spaste('do_delete(',name,')'));               

	ii := private.gsb_get_indices ('focus_family');
	for (i in ii) {
	    group := ref private.gsb[i];                # convenience
	    if (is_boolean(group)) next;

	    iimod := [];			        # vector of indices
	    if (name=='selected') {
		jj := private.datobj.group_indices(group,'selected');
		iimod := private.datobj.modify_group(group, 'delete', index=jj);
	    } else if (name=='undo') {
		iimod := private.datobj.modify_group(group, 'undelete');
	    } else {
		print 'do_delete: not recognised:',name;
		return F;
	    }

	    # Only replot if any data-lines have been modified:
	    if (len(iimod)>0) {
		s := paste('modified: line nr',iimod);
		private.gsb_plot(idescr=i);
	    } else {
		s := paste('no lines modified');
	    }
	    if (trace) print s;
	    public.message(s);
	}
	return T;
    }

#-------------------------------------------------------------------------------
# Make a menu-button for data-selection:

    private.make_select_menu := function (ref bframe=F) {
	bmenu := private.jenguic.define_button(bframe, 'select', btype='menu'); 
	ss := "all_visible none negate";
	for (name in ss) {
	    private.jenguic.define_button(bmenu, spaste('select_',name), 
					  name, callback=private.do_select);
	}
	private.jenguic.define_button(bmenu, btype='menusep');	 
	ss := "low_absmean same_label";
	for (name in ss) {
	    # private.jenguic.define_button(bmenu, spaste('select_',name), 
	    # 				  callback=private.do_select);
	}
	private.jenguic.add_menu_help(bmenu, 'select', 
				      callback=private.do_select);
	return T;
    }

# Callback function for (de-)selection of plot-items:

    private.do_select := function (name=F, replot=F, trace=F) {
	wider private;
	s := spaste('do_select(',name,'): ');
	if (trace) print s;
	public.message(s);               

	if (name=='select_help') {
	    return private.jenplot_help.show('select');
	}

	gsb := private.gsb_get('focus', type="group slice", trace=trace);
	ii := private.datobj.get_indices (gsb, index='visible', 
					  trace=trace);
	if (name=='select_all_visible') {
	    s := private.select_rowline(gsb, ii, select=T, trace=trace);
	} else if (name=='select_none') {
	    s := private.select_rowline(gsb, ii, select=F, trace=trace);
	} else if (name=='select_negate') {
	    s := private.select_rowline(gsb, ii, select='negate', 
					 trace=trace);
	} else if (any(name=="low_absmean same_label")) {
	    ii := private.datobj.select_lines(gsb, crit=name);
	    s := private.select_rowline(gsb, ii, select=T, trace=trace);
	} else {
	    s := paste('do_select: option not recognised:',name);
	    replot := F;
	}
	if (trace) print s;
	public.message(s);                    # after plot!
	return T;
    }

# Helper function to actually select lines/rows in group/slice:

    private.select_rowline := function (ref gsb, ii=F, select=F, trace=F) {
	if (!is_record(gsb)) {
	    return paste('select_rowline: gsb is not a record!');
	} else if (gsb.type=='group') {
	    private.select_line(iseq=ii, select=select, trace=trace);
	} else if (gsb.type=='slice') {
	    private.select_row(irow=ii.row, select=select, trace=trace);
	}
	return T;
    }

#-------------------------------------------------------------------------------
# Make a menu-button for complex->real data-conversion:

    private.make_cx2real_menu := function (ref bframe=F) {
	wider private;
	bmenu := private.jenguic.define_button(bframe, 'cx2real', 
					       btype='menu'); 
	ss := "not_complex";
	ss := [ss,"ampl phase_rad phase_deg real_part imag_part"];
	ss := [ss,"rvsi"];                        # data-group only
	ss := [ss,"ampl_phase real_imag all_four"];		
	private.cx2real_names := ss;
	for (name in private.cx2real_names) {
	    private.jenguic.define_button(bmenu, spaste('cx2real_',name),
					  name, btype='radio', 
					  callback=private.do_cx2real);
	}
	private.set_cx2real_button_state();
	private.jenguic.add_menu_help(bmenu, 'cx2real', 
				      callback=private.do_cx2real);
	return T;
    }

# Common callback function for data complex->real conversion buttons:

    private.do_cx2real := function (name=F, trace=F) {
	wider private;
	s := paste('do_cx2real(',name,'):');
	name := split(name,'_');
	name := paste(name[2:len(name)], sep='_');           
	if (trace) s := paste(s,'->',name);
	if (trace) print s;
	public.message(s);

	if (name=='help') {
	    return private.jenplot_help.show('cx2real');
	} else if (name=='not_complex') {
	    private.set_cx2real_button_state();
	    s := paste('do_cx2real: not settable:',name);
	    return public.message(s);
	}

	gsb := private.gsb_get ('focus_parent');
	if (is_record(gsb) && !gsb.iscomplex) {
	    public.set_cx2real(gsb=gsb, trace=trace);
	    return public.message('The data are not complex!');
	} else if (any(name==private.cx2real_names)) {
	    public.set_cx2real(name, trace=trace);
	} else {
	    s := paste('do_cx2real: not recognised',name);
	    return public.message(s);
	}
	private.plot(origin='do_cx2real');
	return T;
    }

# Helper function to update the state of the gui cx2real menu buttons with
# the values of the given gsb data-object (a bit of a kludge):

    private.set_cx2real_button_state := function (trace=F) {
	if (is_boolean(private.guiframe)) return F;          # no gui (yet)
	button := [=];
	name := spaste('cx2real_',private.cx2real);
	button[name] := T;
	private.jenguic.button_state(button, set=T, trace=trace);
	return T;
    } 


#-------------------------------------------------------------------------------
# Make a 'file' menu-button:

    private.make_file_menu := function (ref bframe=F) {
	bmenu := private.jenguic.define_button(bframe, 'file', btype='menu'); 

	# Save/restore:
	for (name in "open save_as") {
	    private.jenguic.define_button(bmenu, name, 
					  callback=private.do_file);
	} 

	# Plotting:
	# private.jenguic.define_button(bmenu, btype='menusep'); 
	# for (name in "replot fullview") {
	    # private.jenguic.define_button(bmenu, spaste('plot_',name), 
	    # 				  callback=private.do_plot);
	# } 

	# Printing:
	# private.jenguic.define_button(bmenu, btype='menusep'); 
	# private.jenguic.define_button(bmenu, 'print_hardcopy', 
	# 			      callback=public.print); 

	# Alternative dismiss button:
	private.jenguic.define_button(bmenu, btype='menusep'); 
	private.jenguic.define_button(bmenu, 'file_dismiss', 'dismiss', 
				      callback=public.done);

	return T;
    }

# Call-back function for save/restore etc:

    private.do_file := function (name=F) {
	print s := paste('do_file: not implemented yet:',name);
	public.message(s);
	return F;
    }

#-------------------------------------------------------------------------------
# Make a menu-button for debugging inspection:

    private.make_debug_menu := function (ref bframe=F) {
	bmenu := private.jenguic.define_button(bframe, 'debug', btype='menu'); 
	# Plot colors and point-styles:
	private.jenguic.define_button(bmenu, 'plot_colors', 'show colors', 
			      callback=private.pgwaux.show_plot_colors);
	private.jenguic.define_button(bmenu, 'point_styles', 'show point-styles', 
			      callback=private.pgwaux.show_point_styles);
	# private.jenguic.define_button(bmenu, 'legend', 'plot-legend',  
	#		      callback=private.not_implemented);

	# Various data-objects (gsb=group/slice/brick):
	private.jenguic.define_button(bmenu, btype='menusep'); 
	s := "gsb_descr gsb_focus gsb_parent gsb";
	for (name in s) {
	    private.jenguic.define_button(bmenu, spaste('inspect_',name),  
				  callback=private.inspect);
	}

	# Overall jenplot records:
	private.jenguic.define_button(bmenu, btype='menusep'); 
	s := "private public pgwidget pgwaux";
	s := [s,"clipboard clipboard_1"];
	for (name in s) {
	    private.jenguic.define_button(bmenu, spaste('inspect_',name),  
				  callback=private.inspect);
	}
	# Profiler:
	private.jenguic.define_button(bmenu, btype='menusep'); 
	s := "show_profile print_profile clear_profiler";
	s := [s,"enable_profiling inhibit_profiling"];
	s := [s,"enable_tracing inhibit_tracing"];
	for (name in s) {
	    private.jenguic.define_button(bmenu, spaste(name),  
				  callback=private.inspect);
	}
	return T;
    }

    private.callback_not_implemented := function (dummy=F) {
	s := paste('not implemented:',dummy);
	print s;
	public.message(s);
	return T;
    }

# Callback function:

    private.inspect := function (name=F) {	# Inspect various things
	include 'inspect.g';
	if (name=='inspect_public') {
	    inspect(public,'jpl');
	} else if (name=='inspect_pgwidget') {
	    inspect(private.pgw,'jpl.pgw()');
	} else if (name=='inspect_pgwaux') {
	    print private.pgwaux.status();
	} else if (name=='inspect_gsb_focus') {
	    gsb := private.gsb_get ('focus');
	    inspect(gsb,'gsb_focus');
	} else if (name=='inspect_gsb_parent') {
	    gsb := private.gsb_get ('focus_parent');
	    inspect(gsb,'gsb_parent');
	} else if (name=='inspect_gsb_descr') {
	    always := T;
	    private.gsb_descr_show(full=T, trace=always);
	    inspect(private.gsb_descr,'gsb_descr');
	} else if (name=='inspect_gsb') {
	    inspect(private.gsb,'gsb');
	} else if (name=='inspect_clipboard') {
	    inspect(private.clipboard,'clipboard');
	} else if (name=='inspect_clipboard_1') {
	    gsb := public.clipboard(get=1);
	    inspect(gsb,'clipboard_1');
	} else if (name=='show_profile') {
	    private.prof.show_profile();
	} else if (name=='print_profile') {
	    private.prof.print_profile();
	} else if (name=='clear_profiler') {
	    private.prof.clear();
	} else if (name=='inhibit_profiling') {
	    private.prof.profiling(F);
	} else if (name=='enable_profiling') {
	    private.prof.profiling(T);
	} else if (name=='inhibit_tracing') {
	    private.prof.tracing(F);
	} else if (name=='enable_tracing') {
	    private.prof.tracing(T);
	} else {
	    inspect(private,'jpl.private');
	}
	return T;
    }


#=======================================================================
# Finished. Initialise and return the public interface:

    private.init();				# initialise
    return ref public;				# ref?

};				# closing bracket of jenplot
#=======================================================================

# const jpl := jenplot();
# print 'global (const) symbol jpl created';


#=========================================================
test_jenplot := function (iexp=3, full=F, trace=F) {
    private := [=];
    public := [=];
    print '\n\n\n\n ******** test_jenplot, iexp=',iexp;
    return T;
};

#===========================================================
# Remarks and things to do:
#================================================================


