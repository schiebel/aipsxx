# barchart.g: Simple AIPS++ Barchart display
#------------------------------------------------------------------------------
#   Copyright (C) 1997,1999,2001
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#    $Id: barchart.g,v 19.2 2004/08/25 01:57:43 cvsmgr Exp $
#
#------------------------------------------------------------------------------

pragma include once
include 'unset.g'; 
include 'defaultattributes.g';
include 'widgetserver.g';

## Constructor
## bar   := barchart(title, width=400, height=200, large=1.0e+38, show=T)
##          title:         gui window title
##          width, height: size in pixels if the barchart display area
##          large:         Value which is shown in red if color display
##          show:          Show the GUI if possible. Note, however, that the
##                         GUI isn't shown until the first call to chart.
##
## Member functions
## chart(name, value)   # Add the specified name=value pair. Create if
##                        necessary.
## remove(name)         # Remove the bar 'name'.
## values()             # Get all name=value pairs as a record
## gui()/nogui()        # Turn on/off the GUI display
## large(newval=unset)  # If given a number, this is the "large" value, i.e.
##                      # the value that shows up in red in a colour display.
##                      # Returns the large value, which is unchanged by 
##                      # default.

## A lot TODO - this is a quick and dirty.
##	o Better check on number of characters needed for formatted values?
##	o Only redraw changed rectangles if size etc. hasn't changed?
##        Probably not worth the bother.

const barchart := subsequence(title='Bar Chart (AIPS++)', width=400,height=200,
			large=1.0e+38, show=T, widgetset=dws)
{
    private := [=];

    private.values := [=];    # name=value pairs
    private.lastmax := 0;
    private.large := large;
    private.title := title;
    private.show := show && have_gui();
    private.doing_init := F;  # prevent refreshes while we're initializing
    private.pgplot := F;      # used to see if we need to init
    private.width := width;
    private.height := height;
    private.wdgts := widgetset;

    self.chart := function(name, value) {
	wider private;
	wider self;

	if (!is_string(name) || !is_numeric(value) ||
	    length(name) != length(value) || length(name)==0) {
	        fail 'barchart.chart - illegal arguments';
	}
	
	changed := F;
	count := 1;
	for (i in name) {
	    if (!has_field(private.values, i)) {
	        private.values[i] := value[count];
		changed := T;
	    } else {
	        # Quick return if no change
                if (private.values[i] != value[count]) {
		    changed := T;
	            private.values[i] := value[count];
		}
	    }
	    count +:= 1;
	}
	if (changed)
	    return private.redraw();
	else
	    return T;
    }

    self.remove := function(name) {
	wider private;
	if (!has_field(private.values, name)) fail('self.remove - no such name');
	names := field_names(private.values);
	names := names[names != name];

	copy := private.values;
	private.values := [=];
	
	for (i in names) private.values[i] := copy[i];
	return private.redraw();
    }

    private.initframes := function() {
	wider private;
	wider self;
	if (!private.show) return T;
	if (!have_gui() || length(private.values)==0) return F;
	if (!is_record(private.wdgts)) return F;
	if(!has_field(private, 'frame') || !is_agent(private.frame)) {
	    tk_hold();
	    private.frame := private.wdgts.frame(title=private.title, side='top',
					   relief='flat');
	    private.pgframe := private.wdgts.frame(private.frame,relief='flat');
	    t := private.wdgts.resources('frame');
	    private.pgplot := pgplot(private.pgframe, width=private.width, 
				  height=private.height, region=[0,1,0,1], axis=0,
				  maxcolors=4, background=t.background,
				  foreground=t.foreground);
	    private.bframe := private.wdgts.frame(private.frame, side='right', 
					    expand='x');
	    private.button := private.wdgts.button(private.bframe, 'Dismiss',
					     type='dismiss');
	    tmp := private.pgplot->qcol();
	    if (tmp[2] - tmp[1] >= 3) {
		private.color := T;
		private.pgplot->scr(2, 0, 1, 0); # green
		private.pgplot->scr(3, 1, 0, 0); # red
		private.pgplot->sfs(1);  # filled
	    } else {
		private.color := F;
		private.pgplot->sfs(2);  # outline
	    }
	    tk_release();
	}
	private.pgplot->eras();

	private.frame.self := ref self;
	private.frame.private := ref private;
	private.button.self := ref self;
	whenever private.frame->resize do {
	    tk_hold();
	    $agent.private.redraw();
	    tk_release();
	}
 	whenever private.frame->killed, private.button->press do {
	  self->done();
	  $agent.self.nogui();
 	}

	return private.redraw();
    }

    private.redraw := function() {
	wider private;
	if (!private.show || length(private.values)==0 || private.doing_init) return T;
	if (!is_record(private.wdgts)) return F;
	# Init frames if necessary
	if (!is_agent(private.pgplot)) {
	    private.doing_init := T
	    ok := private.initframes();
	    private.doing_init := F
	    if (!ok) return F;
	}

	const names := sort(field_names(private.values));

	# Find the maximum value using only the changed entries
	maxval := 0;
	for (i in names) {
	    if (private.values[i] > maxval) maxval := private.values[i];
	}
	if (maxval == 0) maxval := 1; # Avoid PGPLOT whining

	if (maxval > private.lastmax) private.lastmax := maxval;
	
	# OK we need to redraw all if there are new entries or if we have
	# resized.
	private.pgplot->bbuf();
	w := private.pgplot->width();
	h := private.pgplot->height();
	private.pgplot->page();
        if(is_numeric(h)&&is_numeric(w)) {
	  ch := min(4, min(h,w)/35);        # character height
	}
	else {
          ch := 4;
	}
        if(!is_numeric(ch)) ch:=4;	  # Could have fail in h, w
	private.pgplot->sch(ch);
	chdev := private.pgplot->qcs(0)[1];  # character height device units
	
	# How much to offset the characters so they are centered on the middle
	# of the bar
        # Don't know why /3 works better than /2. Maybe a character
        # has asymmetrical white space.
	choffset := private.pgplot->qcs(4)[2]/3; 

	# Find out the longest name
	# 1+ for the leading space
	namelen := max(strlen(names))+1;

	# Don't let the names take up too much leading space (0.5 in x)
	if (namelen*chdev > 0.5) {
	    chdev := 0.5/namelen;
	}
	# Set the viewport leaving room for the names at the front and 5
	private.pgplot->svp(namelen*chdev,1-5*chdev,0.05,0.95);
	# Set the plot window in worl coordinates
	private.pgplot->swin(0, 1.01*private.lastmax, length(private.values)+0.5, 0.5);

	chdev := private.pgplot->qcs(4)[1]; # character width world units
	count := 1;
	for (i in names) {
	    tmp := private.values[i];
	    tmp::print.precision := 2;
	    # Name and value
	    private.pgplot->sci(1);
	    private.pgplot->ptxt(as_float(-chdev), as_float(count-choffset),
			      0.0, 1.0, as_string(i));
	    private.pgplot->ptxt(as_float(tmp+chdev), as_float(count-choffset),
			      0.0, 0.0, as_string(tmp));
			      
	    if (private.color && tmp <= private.large) {
		private.pgplot->sci(2);
	    } else {
		private.pgplot->sci(3);
	    }

	    private.pgplot->rect(0, tmp, count-0.4, count+0.4);
	    count +:= 1;
	}
	private.pgplot->ebuf();

	return T;
    }

    self.values := function() {
	wider private;
	return private.values;
    }

    self.nogui := function() {
	wider private;
	if (!private.show) return T;
	tk_hold();
	private.show := F;
	private.frame := private.pgrame := private.bframe := private.pgplot := 
	    private.button := F;
	tk_release();
	return T;
    }

    self.gui := function() {
	wider self;
	wider private;
	self.nogui();  # Make sure turned off
	private.show := T && have_gui();
	return private.redraw();
    }

    self.type := function() {
        return 'barchart';
    }

    self.large := function(newval = unset) {
	wider private;
	if (is_numeric(newval)) {
	    private.large := newval;
	}
	if (private.show) private.redraw();
	return private.large;
    }

    self.done := function() {
	wider self, private;
	self.nogui();
	val self := F;
	val private := F;
    }

#    defaultattributes(self);
}

