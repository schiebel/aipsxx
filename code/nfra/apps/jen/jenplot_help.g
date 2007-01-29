# jenplot_help.g: Help functions (and text) for jenplot.g

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
# $Id: jenplot_help.g,v 19.0 2003/07/16 03:38:36 aips2adm Exp $

#---------------------------------------------------------

pragma include once
# print 'include jenplot_help.g h01seo99';

include 'profiler.g';
include 'jenguic.g';

#=====================================================================
#=====================================================================
jenplot_help := function () {
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
	s := paste('jenplot_help event:',$name,$value);
	# print s;
    }

    public.help := function (name=F, trace=F) {
        if (name=='manual') {                # all available
	    s := '\n jenplot manual:';
	    for (name in field_names(private.help)) {
		if (trace) print 'jenplot_help:',name;
		s := paste(s,'\n',private.help[name]());
	    }

	} else {                             # specific
	    s := '\n';
	    for (nm in name) {               # name can be string vector
		if (trace) print 'jenplot_help:',nm;
		if (has_field(private.help,nm)) {
		    s := paste(s,'\n',private.help[nm]());
		} else {
		    s1 := paste('jenplot_help: not recognised:',nm);
		    print s1;
		    s := paste(s,'\n',s1);
		}
	    }
	}
	return s;                            # return string (always)
    }

    public.show := function (name=F) {
	txt := public.help(name);
	title := paste('help for jenplot:',name);
	txt := paste('\n',title,'\n',txt);
	private.jenguic.boxmessage(txt, title=title);
	# (maxrows=40, maxcols=80);
	return T;
    }

    public.print := function (name=F, trace=T) {
	txt := public.help(name);
	filename := spaste('/tmp/jenplot_help_',name,'.txt');
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
    for (name in "general spawn flag") {
	private.help[name] := function (dummy=F) {
	    return 'help not (yet) implemented';
	}
    }

#--------------------------------------------------------------------------------

    private.help.general := function (dummy=F) {
	s := paste('\n\n',
		   '\n\n * Overview:',
		   '\n   - Each plot contains zero or more plot-items (or \'items\'),',
		   '\n     i.e. 1D collections of points that belong together.',
		   '\n\n * Slices:',
		   '\n\n * Gray-scale (slices):',
		   '\n   - This may be modfied by clicking the mouse on or near the',
		   '\n     gray-scale wedge along the left margin of a slice:',
		   '\n   - Left mouse button in wedge:   becomes new value for cmax',
		   '\n   - Right mouse button in wedge:  becomes new value for cmin',
		   '\n   - Middle mouse button in wedge: automatic cmin/cmax',
		   '\n   - Any mouse button above wedge: extend cmax upwards',
		   '\n   - Any mouse button below wedge: extend cmin downwards',
		   '\n\n * Groups:',
		   '\n   - Each item has a label in the right margin, which has the same.',
		   '\n     color as the item, and is placed near its last point.',
		   '\n   - If an item is \'selected\', it is emphasised (thicker line or points).',
		   '\n   - Items may be (de-) selected with the mouse (see below),',
		   '\n     or with the various options of the \'select\' menu.',
		   '\n   - Selected items may be deleted with the \'delete\' menu.',
		   '\n\n * Data values and statistics:',
		   '\n   - Clicking with the left mouse button inside the plot-window will:',
		   '\n     - display the essential values of that point below the plot',
		   '\n     - display the statistics of the relevant line or row above the plot',
		   '\n     - for groups, (de-)select the clicked data-line',
		   '\n   -',
		   '\n   -',
		   '\n\n * Zooming in and out:',
		   '\n   - The right button may be used to draw a rubber box in the plot-window', 
		   '\n     after which the relevant subset will be plotted only',
		   '\n   - The entire plot can be retrieved with \'fullview\' button.',

		   '\n   - Click on x-label (along top margin, if defined): draws marker',

		   '\n   - Draw rubber box: flags all points inside (selected items only).',
		   '\n     NB: Flags are made visible with the \'show_flags\' option.',
		   '\n   - The \'flag\' menu offers some more flagging options',
		   '\n   -',
		   '\n\n * cx2real menu:',
		   '\n   - Complex input data may be plotted in various ways.',
		   '\n   - NB: This does NOT affect the values of the input data.',
		   '\n   - The displayed statistics are for the converted values.',
		   '\n   -',
		   '\n\n * Display menu:',
		   '\n   - Items may be plotted w.r.t. their means, separated by a constant offset.',
		   '\n   - (This is useful for separating items that are plotted on top of each other).',
		   '\n   - Note that the value of the averages are written to the right.',
		   '\n   -',
		   '\n\n * Ops menu:',
		   '\n   - Some often-used mathematical operations on SELECTED items.',
		   '\n     NB: The affected item values are changed permanently.',
		   '\n   -',
		   '\n\n * Clipboard menu:',
		   '\n   - One or more items may be copied to a clip-board',
		   '\n     e.g. for use in mathematical operations.',
		   '\n   -',
		   '\n\n * Help menu:',
		   '\n   -',
		   '\n\n * Plot button:',
		   '\n   -',
		   '\n\n * Spawn button:',
		   '\n   - A separate plotter may be \'spawned\' for various purposes:',
		   '\n   - Selected_items copies the VISIBLE parts of selected items.',
		   '\n   - Statistics visualises the vital statistics of all items.',
		   '\n   -',
		   '\n\n * Print button:',
		   '\n   - Hardcopy prints a post-script version of the current plot.',
		   '\n   - NB: This uses the print-command \'pri\', which AIPS++ assumes to be defined.',
		   '\n   - NB: The intermediate ps-file \'/tmp/aipsplot.ps\' is deleted again.',
		   '\n   -',
		   '\n\n * Tapedeck control buttons:',
		   '\n   - These buttons (on the lower right) will \'light up\' when active.',
		   '\n   - They can be used to control the progress of certain operations.',
		   '\n');
	# print 'help:',s;
	return s;
    }






#=======================================================================
# Finished. Initialise and return the public interface:

    private.init();				# initialise
    return ref public;				# ref?

};				# closing bracket of jenplot
#=======================================================================



#=========================================================
test_jenplot_help := function () {
    private := [=];
    public := [=];
    print '\n\n\n\n ******** test_jenplot_help, iexp=',iexp;
    return T;
};

#===========================================================
# Remarks and things to do:
#================================================================


