# msbrick_help.g: Help functions (and text) for msbrick.g

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
# $Id: msbrick_help.g,v 19.0 2003/07/16 03:38:56 aips2adm Exp $

#---------------------------------------------------------

pragma include once
# print 'include msbrick_help.g  h01sep99';

include 'profiler.g';
include 'jenguic.g';

#=====================================================================
#=====================================================================
msbrick_help := function () {
    private := [=];
    public := [=];


# Initialise the object (called at the end of this constructor):

    private.init := function () {
	wider private;
	private.jenguic := jenguic();           # gui components
	private.prof := profiler();             # contains print routine...?
	# private.messagebox := F;		# see .boxmessage()
	return T;
    }



#==========================================================================
# Public interface:
#==========================================================================

    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('msbrick_help event:',$name,$value);
	# print s;
    }

    public.help := function (name=F, trace=F) {
        if (name=='manual') {                # all available
	    s := '\n msbrick manual:';
	    for (name in field_names(private.help)) {
		if (trace) print 'msbrick_help:',name;
		s := paste(s,'\n',private.help[name]());
	    }

	} else {                             # specific
	    s := '\n';
	    for (nm in name) {               # name can be string vector
		if (trace) print 'msbrick_help:',nm;
		if (has_field(private.help,nm)) {
		    s1 := paste('msbrick_help: section:',nm,'\n');
		    s := paste(s,'\n',s1,'\n',private.help[nm]());
		} else {
		    s1 := paste('msbrick_help: not recognised:',nm);
		    print s1;
		    s := paste(s,'\n',s1);
		}
	    }
	}
	return s;                            # return string (always)
    }

    public.show := function (name=F) {
	txt := public.help(name);
	title := paste('help for msbrick:',name);
	txt := paste('\n',title,'\n',txt);
	private.jenguic.boxmessage(txt, title=title);
	# (maxrows=40, maxcols=80);
	return T;
    }

    public.print := function (name=F, trace=T) {
	txt := public.help(name);
	filename := spaste('/tmp/msbrick_help_',name,'.txt');
	private.prof.print(txt, filename=filename);
	s := paste('written help-text to file:',filename);
	s := paste(s,' (printed & removed)');
	if (trace) print s;
	return s;
    }


#-------------------------------------------------------------------------------
# Help-functions are fields of the record private.help, and return a string:
#-------------------------------------------------------------------------------

    private.help := [=];                        # record of functions
    
#--------------------------------------------------------------------------------

    private.help.msbrick := function() {
	s := paste(' ',
		   '\n msbrick is a user interface for manipulating uvbricks.',
		   '\n ',
		   '\n A uvbrick is a 4D uv-data structure: corr freq ifr time',
		   '\n It may be obtained from an MS, or simulated.',
		   '\n ',
		   '\n Available uvbricks are stored in the \'brick-list\'.',
		   '\n All operations are on the \'current\'uvbrick,',
		   '\n   i.e. the one that is currently visible in the list-window.',
		   '\n ',
		   '\n The result of a uvbrick operation may be a uvbrick or',
		   '\n   a record (e.g. polynomial coeff), or simply boolean.',
		   '\n Results are stored in the \'result-list\'.',
		   '\n uvbricks may be transferred between the lists, usually',
		   '\n   for being inspected, or \'applied\' to another uvbrick.',
		   '\n ',
		   '\n Apart from the basic uvbrick operations like select, average,',
		   '\n   plot, convert, apply etc, there are also packaged routines',
		   '\n   for standard operations like bandpass estimation/division.',
		   '\n ',
		   '\n The idea started from a need to have some simple routines for',
		   '\n   inspecting WSRT data and setting up the instrument.',
		   '\n It evolved into a complete \'mini-package\' which can be used',
		   '\n   to inspect/manipulate uv-data from any telescope, as long',
		   '\n   as it is in an AIPS++ Measurement Set (MS).',
		   ' ');
	return s;
    }

    private.help.DELFI := function() {
	s := paste('DELFI: estimation of WSRT DCB delay offsets',
		   '\n This requires a special observation, in which the delays of',
		   '\n   some of the the antennas are varied in steps of 5-10 nsec.',
		   '\n Interferometers between a stepped and a non-stepped antenna',
		   '\n   (receptor, really) will display a sinc-function in their',
		   '\n   amplitude, which is maximum when the two delays are equal.',
		   '\n By measuring the peaks of the sinc-function, the receptor',
		   '\n   delay-offsets can be found by decomposition.',
		   '\n Note that the calculated delays have an arbitrary zero-point,',
		   '\n   which is different for the X/Y systems if only XX/YY are used.',
		   '\n   This will cause decorrelation in XY/YX. If all 4 polarisations',
		   '\n   (XX,XY,YX,YY) are used for DELFI, the X/Y solutions are coupled,',
		   '\n   so the problem is avoided. In this case, a polarised calibrator',
		   '\n   is needed (U) to get signal into the XY/YX polarisations.',
		   '\n');
	return s;
    }



#=======================================================================
# Finished. Initialise and return the public interface:

    private.init();				# initialise
    return ref public;				# ref?

};				# closing bracket of msbrick
#=======================================================================



#=========================================================
test_msbrick_help := function () {
    private := [=];
    public := [=];
    print '\n\n\n\n ******** test_msbrick_help, iexp=',iexp;
    return T;
};

# print 'msbrick_help: msh=',msh := msbrick_help(); 

#===========================================================
# Remarks and things to do:
#================================================================


