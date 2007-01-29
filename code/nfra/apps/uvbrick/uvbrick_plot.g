#  uvbrick_plot.g: auxiliary functions for uvbrick.g.

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
# $Id: uvbrick_plot.g,v 19.0 2003/07/16 03:38:55 aips2adm Exp $

#---------------------------------------------------------

pragma include once
# print 'include uvbrick_plot.g  w31au99'

include 'jenindex.g';		        # index display/control
include 'jenplot.g';                    # plotter
include 'jenmisc.g';                    # checkfield()...

include 'profiler.g';
# include 'textformatting.g';		
# include 'tracelogger.g';
# include 'buttonscript.g';		# script generation


#=========================================================
test_uvbrick_plot := function () {
    private := [=];
    public := [=];
    return T;
};


#==========================================================================
#==========================================================================
#==========================================================================

uvbrick_plot := function () {
    private := [=];
    public := [=];


# Initialise the object (called at the end of this constructor):

    private.init := function () {
	wider private;
	const private.pi := acos(-1);		# use atan()....?
	const private.pi2 := 2*private.pi;	
	const private.rad2deg := 180/private.pi;
	const private.deg2rad := 1/private.rad2deg;
	# include 'tracelogger.g';
	# private.trace := tracelogger(private.name);

	private.jenmisc := jenmisc();           # for checkfield()

	private.prof := F;                      # profiler....

	private.pgp := F;			# only when needed (pgplotter.g)
	private.pgw := F;			# only when needed (uvbrick_plot1D.g)
	private.index := F;			# only when needed (jenindex.g)
	private.tf := F;		        # text-formatting function
	return T;
    }

    private.check_pgp := function() {
	wider private;
	if (is_boolean(private.pgp)) {			# no pgplotter yet
	    include 'pgplotter.g';
	    private.pgp := pgplotter();			# make one
	}
    }

#==========================================================================
# Public interface:
#==========================================================================


    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('uvbrick_plot event:',$name,$value);
	# print s;
    }
    whenever public.agent->message do {
	print 'uvbrick_plot message-event:',$value;
    }
    whenever public.agent->abort do {
	print 'uvbrick_plot abort-event:',$value;
	if (is_record(private.index)) {
	    private.index.abort($value);	# abort any index-loops
	}
    }

    public.private := function(copy=F) {	# access to private part
	if (copy) return private;		# return a copy
	return ref private;			# return a reference
    }




#------------------------------------------------------------------------
# Plot the given brick as a (controlled) sequence of 2D slices:

    public.data_slices := function (ref brick, pp=[=], ref jpl=F, trace=T) { 
	wider private;
	if (trace) {
	    print 'plot_slices: jpl=',type_name(jpl),'brick=',type_name(brick);
	    print 'input parameters: pp=',pp;
	}
	private.jenmisc.checkfield(pp,'xaxis','time','data_slices');
	private.jenmisc.checkfield(pp,'group','ifr','data_slices');   # ant?
	private.jenmisc.checkfield(pp,'cx2real','ampl','data_slices');
	private.jenmisc.checkfield(pp,'unwrap',F,'data_slices');
	private.jenmisc.checkfield(pp,'suspend',T,'data_slices');
	private.jenmisc.checkfield(pp,'unit',F,'data_slices');

	jpl.clear();					# bring into known state..

	ydescr := 'corr.coeff';
	yunit := '..';
	ydescr := brick.get('data_descr');
	yunit := brick.get('data_unit');
	yname := F;

	legend := brick.legend();
	title := paste(brick.type(),'slice');
	title := spaste(title,' (',brick.get('data_descr'),'):');

	xdescr := paste(pp.xaxis);
	xunit := '..';
	xname := F;

	xx := brick.getcoord(pp.xaxis, xunit, xdescr);
	if (any(pp.xaxis=="HA UT LAST MJD97")) {
	    pp.xaxis := 'time';				# AFTER getting xx!
	} else if (pp.xaxis=="uvdist") {
	    # pp.group := 'ifr';			# ....?
	    pp.xaxis := 'time';				# AFTER getting xx!
	} else if (any(pp.xaxis=="RA DEC")) {
	    pp.xaxis := 'time';				# AFTER getting xx!
	    pp.group := 'ant';
	    print 'not supported yet, try again later'
	    return F;
	}
	if (is_fail(xx)) {                              # try again..
	    xx := brick.getcoord(pp.xaxis, xunit, xdescr);
	    s := paste(pp.xaxis,': no xx-vector found');
	    if (is_fail(xx)) fail(s);                   # hopeless...
	    xdescr := paste(pp.xaxis);
        }
	if (trace) print 'xx-vector:',pp.xaxis,len(xx),type_name(xx);

	yannot := brick.getlabel(pp.group);
	if (trace) print 'yannot:',yannot;		# string vector

	xannot := F;					# x-annotations
	if (any(pp.xaxis=="ifr corr ant pol")) {
	    xannot := brick.getlabel(pp.xaxis);
	    if (trace) print 'xannot:',xannot;		# string vector
	}

	# Transpose the data-slice if necessary (done by jpl.putslice()):
	# NB: Transposition will only affect yy,xx,ff, but NOT labels etc
	# axes := "corr freq ifr time";
	axes := brick.axes();                         # antbrick too
	ix_group := ind(axes)[axes==pp.group];		# index of group
	ix_xaxis := ind(axes)[axes==pp.xaxis];		# index of x-axis
	transpose := F;
	if (pp.xaxis==pp.group) {			# AFTER renaming xaxis!
	    s := paste('data_slices(): xaxis should differ from group-axis:');
	    print s := paste(s,pp.group,pp.xaxis);
	    # return F;
	} else if (ix_xaxis<ix_group) {
	    transpose := F;
	} else {
	    transpose := T;
	}
	if (trace) print 'ix_group/xaxis=',ix_group,ix_xaxis,'transpose=',transpose;

	# index: controls slice selection by record-indexing of brick:
	private.index := brick.initindex([pp.xaxis,pp.group], 'data', 
					 origin='uvbrick_plot.data_slices',
					 showprogress=F,
					 autofinish=F, forwardonly=F);
	if (is_fail(private.index)) fail(private.index);

	jpl.index(private.index);			# progress control
	jpl.set_display_option('cx2real',pp.cx2real);
	# jpl.set_display_option('unwrap',pp.unwrap);     # unwrap phases

	# Main loop: plot slice-by-slice:
	once_only := F;                                 # 
	clear := T;					# first time
	replace := F;
	first := T;
    	while (private.index.next(index)) {		# for all data_slices
	    if (trace) print '\n index=',index;
	    s := private.index.get_progress_message();
	    if (trace) print s;
	    r := jpl.putslice (label='slice', xx=xx, 
			       plot=T, full=F,
			       yy=brick.getslice(index), 
			       ff=brick.getslice(index, 'flag'), 
			       clear=clear, replace=replace, 
			       transpose=transpose, trace=F,
			       yannot=yannot, xannot=xannot, 
			       title=paste(title,s), legend=legend,
			       xname=xname, xdescr=xdescr, xunit=xunit, 
			       yname=yname, ydescr=ydescr, yunit=yunit); 
	    if (is_fail(r) || !r) {
		private.index.abort('problem with jpl.putslice()');
	        break;
	    }
	    jpl.message(s);				# progress message
	    # clear := F;
	    replace := T;
	    if (once_only) break;			# escape
	    if (first) private.index.suspend(pp.suspend);     
	    first := F;
    	}

	# Finished:
	jpl.index();					# disable progress control
	if (trace) print 'data_slices: finished';
	return F;
    }


#------------------------------------------------------------------------
# Plot the uv-coverage:

    public.uvcoverage := function (ref uvbrick, pp=[=], ref jpl=F, trace=F) { 
	wider private;
	if (trace) {
	    print 'uvcoverage: jpl=',type_name(jpl),'uvbrick=',type_name(uvbrick);
	    print 'input parameters: pp=',pp;
	}
	private.jenmisc.checkfield(pp,'unit',F,'uvcoverage');
	private.jenmisc.checkfield(pp,'aspectratio',F,'uvcoverage');

	jpl.reset();					# bring into known state..

	title := 'uv-coverage:';
	legend := uvbrick.legend();                     # string vector

	nifr := uvbrick.length('ifr'); 
	ntime := uvbrick.length('time'); 
	uuu := uvbrick.get('ifr_ucoord',copy=F);	# ref
	if (is_fail(uuu)) {
	    print 'uvcoverage: uvbrick does not contain uv-coord';
	    return F;
	}
	vvv := uvbrick.get('ifr_vcoord',copy=F);	# ref
	udim := shape(uuu);
	vdim := shape(vvv);
	if (!all(udim==[nifr,ntime])) {
	    print 'uvcoverage: udim != [ntime,nifr]:',udim,[nifr,ntime];
	    return F;
	} else if (!all(udim==vdim)) {
	    print 'uvcoverage: udim != vdim:',udim,vdim;
	    return F;
	} 

	xdescr := 'u-coord';
	ydescr := 'v-coord';
	xunit := yunit := 'm';
	xname := 'u';
	yname := 'v';
	if (pp.unit=='wavelength') {
	    fMHz := uvbrick.get('chan_freq', copy=F);
	    xunit := yunit := 'wavelengths';
	}

	yannot := uvbrick.getlabel('ifr');
	if (trace) print 'uvcoverage: yannot:',yannot;	# string vector
	xannot := F;

	# index: controls slice selection by record-indexing of uvbrick:
	private.index := uvbrick.initindex("time ifr", 'data', 
					   origin='uvbrivk_plot.uvcoverage',
					   showprogress=F,
					   autofinish=F, forwardonly=F);
	if (is_fail(private.index)) fail(private.index);
	jpl.index(private.index);			# progress control


	# Main loop: plot uvcoverage slice-by-slice:
	clear := T;					# first time
	once_only := T;                                 # one slice only
    	while (private.index.next(index)) {		# for all slices
	    if (trace) print '\n index=',index;
	    flags := uvbrick.getslice(index, 'flag');	# slice flags	
	    xx := uuu;				        # 2D
	    yy := vvv;				        # 2D
	    if (pp.unit=='wavelength') {
		ix_freq := index[2];		        # freq-axis index
		lambda := 299.79/fMHz[ix_freq];	        # lambda=c/f
		xx /:= lambda;
		yy /:= lambda;
		s := spaste('wavelengths=',sprintf('%.3g',lambda),'m');
		xunit := yunit := s;
	    }

	    # Make a data-group out of 2D 
	    s := private.index.get_progress_message();
	    if (trace) print s;
	    group := jpl.group (label='uvcoverage', trace=F,
				xannot=xannot, yannot=yannot,
				title=paste(title,s), 
				legend=legend,
				xname=xname, xdescr=xdescr, xunit=xunit, 
				yname=yname, ydescr=ydescr, yunit=yunit); 
	    for (i in [1:nifr]) {
		jpl.putline (group, label=yannot[i], xx=xx[i,], yy=yy[i,], 
			     style='points', trace=F); 
	    } 
	    jpl.putgroup(group, clear=F, plot=T, trace=trace);
	    jpl.set_display_option('xyzero', T);	# show x/y axes
	
	    jpl.message(s);				# progress message
	    clear := F;                                 # .....?
	    if (once_only) break;			# escape
    	}
	jpl.index();					# disable progress control
	return F;
    }


#=======================================================================
# Finished. Initialise and return the public interface:

    private.init();				# initialise
    return ref public;				# ref?

};						# closing bracket of uvbrick
#=======================================================================






