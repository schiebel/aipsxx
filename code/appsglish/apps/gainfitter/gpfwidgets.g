# gpfwidgets.g: megawidgets for the gainpolyfittergui
# Copyright (C) 2000,2001,2002
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
# $Id: gpfwidgets.g,v 19.1 2004/08/25 01:16:50 cvsmgr Exp $
pragma include once;

include 'widgetserver.g';
include 'rdelete.g';

const CURSORS := ['dot', 'arrow', 'center_ptr', 'circle', 'crosshair',
		  'cross_reverse', 'dotbox', 'draft_large', 'draft_small',
		  'hand1', 'hand2', 'left_ptr', 'right_ptr',
		  'sb_down_arrow', 'target', 'tcross', 'top_left_arrow',
		  'xterm'];

# const PGCURSORS := [ "norm line rect yrng xrng hline vline cross"];
const PGCURSORS := [ "norm cross"];

#@
# create an gain axis value selection widget.  This allows the user to select
# which gains along a "gain axis" (e.g. antenna)
# @param parent    the parent frame to attach to
# @param title     the title of the axis
# @param values    a list of axis values to make selectable
# @param state     the initial state for each of values given in labels
# @param action    a callback function to execute when values are selected. Its
#                  signiture should be function(title= '', state=T, values=[]),
#                  where
#                       title   the title associated with this widget (allows
#                                 single function to handle several widgets).
#                       state   is true if the selection is on, and 
#                       values  is an array of values whose state has been 
#                                 updated.
# @param buttonsperrow   the maximum number of value selection buttons to put
#                    in a row across the widget
# @param widgetset  the widget set to use to create this widget with.
gpf_axisvalselection := function(parent=F, title='Items', values=[], state=[], 
				 labels=[], action=F, doallnone=T, showtitle=T,
				 buttonsperrow=12, widgetset=dws)
{
    its := [title=title, action=action];
    gui := [parent=parent];
    public := [=];

    its.buildgui := function(parent, title, values, state, labels, ws, action,
			     doallnone, showtitle, buttonsperrow=12) 
    {
	wider gui;

	gui.topFrame := ws.frame(parent, side='left', expand='x',
				 relief='raised');
	gui.topFrame->unmap();
	if (showtitle && is_string(title) && strlen(title) > 0) 
	    gui.label := ws.label(gui.topFrame, title);

	if (doallnone) {
	    if (length(labels) > buttonsperrow) {
		gui.butfr := ws.frame(gui.topFrame, side='top', expand='none');
	    }
	    else {
		gui.butfr := ws.frame(gui.topFrame, side='left', expand='none');
	    }

	    gui.nonebut := ws.button(gui.butfr, 'None', value=F, 
				     relief='raised');
	    gui.allbut := ws.button(gui.butfr, 'All', value=T, relief='raised');
	    whenever gui.allbut->press, gui.nonebut->press do {
		for(i in 1:length(gui.valbuts)) 
		    gui.valbuts[i]->state($value);
		if (is_function(action)) action(its.title, $value, gui.values);
	    }
	}

	gui.values := values;
	gui.labels := as_string(values);
	if (length(labels) > 0) 
	    gui.labels[1:min(length(labels),length(values))] := labels;

	gui.valrowsfr := ws.frame(gui.topFrame, side='top');
	gui.valbuts := [=];
	gui.valrows := [=];

	local i, f := 0;
	local bstate := rep(F, length(values));
	if (length(state) > 0) 
	    bstate[1:min(length(state),length(values))] := state;

	for(i in 1:length(values)) {
	    local l := as_string(gui.labels[i]);
	    local b := as_string(gui.values[i]);

	    if (((i-1) % buttonsperrow) == 0) {
		f +:= 1;
		gui.valrows[f] := frame(gui.valrowsfr, side='left');
	    }

	    gui.valbuts[b] := ws.button(gui.valrows[f], l, relief='flat', 
					justify='center', type='check', 
					value=gui.values[i]);
	    gui.valbuts[b]->state(bstate[i]);
	    if (is_function(action)) {
		whenever gui.valbuts[b]->press do {
		    action(its.title, $agent->state(), $value);
		}
	    }
	}

	gui.topFrame->map();
	return T;
    }

    #@
    # return a mask array indicating which buttons are turned on
    # @param values   an array of the values of interest.  If not given
    #                    (or empty), the state for all values will be returned.
    ##
    public.getstate := function(values=[]) {
	wider gui;
	if (length(values) == 0) values := gui.values;
	local value;
	local out := as_boolean([]);
	local i := 1;
	for(value in values) {
	    out[i] := gui.valbuts[as_string(value)]->state();
	    i +:= 1;
	}
	return out;
    }

    #@
    # set the state of the buttons with the given values
    # @param values   an array of the values of interest.  If not given
    #                    (or empty), the state for all values will be returned.
    ##
    public.setstate := function(values=[], state=T, docallback=F) {
	wider gui, its;
	if (! is_boolean(state)) 
	    fail paste('state parameter not a boolean:', state);
	if (length(values) == 0) values := gui.values;
	local value;
	local out := as_boolean([]);
	local i := 1;
	for(value in values) {
	    out[i] := gui.valbuts[as_string(value)]->state(state);
	    i +:= 1;
	}
	if (docallback) {
	    gui.action(its.title, state, values);
	}

	return out;
    }

    if (is_fail(its.buildgui(parent, title, values, state, labels, widgetset, 
			     action, doallnone, showtitle, buttonsperrow))) 
    {
	print 'Trouble building widget.';
    }

    public.done := function() {
	wider public, gui;
#	rdelete(gui);
	gui := F;
	public := F;
	return T;
    }

    public.its := its;
    public.gui := gui;
    return ref public;
}

gpf_axisvalselection_demo := function(nvals=4, buttonsperrow=8, doallnone=T) {
    local action := function(title='', state=T, values=[]) {
	local position := "off";
	if (state) position := "on";
	print "Turning", title, values, position;
	return T;
    }

    top := dws.frame(F, side='top');
#    top->unmap();
    wjt := gpf_axisvalselection(top, 'Antennas', [1:nvals], action=action,
				buttonsperrow=buttonsperrow, 
				doallnone=doallnone);

    whenever top->killed do {
	wjt.done();
    }
#    top->map();

    return ref wjt;
}

#@
# create a message display widget 
gpf_messagedisplay := function(parent=F, height=2, minwidth=45) {
    its := [count=0];
    gui := [=];
    public := [=];

    its.buildframe := function(parent, height, width) {
	wider gui;

	gui.top := frame(parent, side='left', relief='sunken', expand='x',
			 width=width);
#	gui.top->unmap();
	gui.text := text(gui.top, text='', fill='x', height=height, 
			 wrap='none');
	gui.text->disable();
#	gui.top->map();

	return T;
    }

    #@
    # append a message as a new line of text in the display
    public.append := function(msg) {
	wider gui, its;
	local n := gui.text->height();

#	gui.text->enable();
	its.count +:= 1;

	local pos := its.count;
	if(its.count > n) {
	    gui.text->delete('0.0', '2.0');
	    pos := n;
	} 

	gui.text->insert(paste(msg, '\n'), spaste(pos, '.0'));
	gui.text->see(spaste(pos, '.0'));
#	gui.text->disable();

	return T;
    }

    its.buildframe(parent, height, minwidth);

    return ref public;
}

gpf_plotterwidget := function(ref parent=F, width=400, height=300, 
			      cursor='cross', ref widgetset=dws) 
{
    include 'pgplotwidget.g';
    its := [=];
    gui := [pgp=F, parent=F, ws=ref widgetset, 
	    dpwidth=width, dpheight=height, pwidth=width, pheight=height, 
	    cwidth=width, cheight=height, cursor='cross', callback=[=]];
    public := [=];

    #@
    # build the initial gui
    ##
    its.build := function(width, height, parent=F) {
	wider gui, its;

	if (! is_boolean(parent)) gui.parent := parent;

	gui.top := gui.ws.frame(gui.parent, side='top');
	if (! is_boolean(parent)) gui.top->unmap();
	gui.northf := gui.ws.frame(gui.top, side='left');
	gui.canvas := gui.ws.canvas(gui.northf, 
				    width=gui.cwidth, height=gui.cheight,
				    region=[0,0,gui.cwidth,gui.cheight]);
	gui.vsb := gui.ws.scrollbar(gui.northf);
	gui.southf := gui.ws.frame(gui.top, side='right',
				   borderwidth=0, expand='x');
	gui.pad := gui.ws.frame(gui.southf, expand='none', width=23, height=23,
				relief='groove');
	gui.hsb := gui.ws.scrollbar(gui.southf, orient='horizontal');

	# Track current scroll position.
	gui.canvpos := [0.0, 0.0];

	whenever gui.vsb->scroll, gui.hsb->scroll do {
	    gui.canvas->view($value);
#	    print 'sb->', $value, full_type_name($value);
	}

	whenever gui.canvas->yscroll do {
	    gui.vsb->view($value);
	    gui.canvpos[2] := $value[2];
	}

	whenever gui.canvas->xscroll do {
	    gui.hsb->view($value);
	    gui.canvpos[1] := $value[1];
	}

	# What gets scrolled.. Holds the pgplot.
	gui.tabletop := gui.canvas->frame(0,0, background='blue');
	gui.tabletop->side('top');

	its.newplotter(width, height);
	if (! is_boolean(parent)) gui.top->map();

	return T;
    }

    #@
    # replace the plotter with a new one of a given size.
    ##
    its.newplotter := function(width, height, charheight=12) {
	wider gui;

	if (! is_boolean(gui.pgp)) {
	    gui.pgp.done();
	    gui.pgp := F;
	}

	if(has_field(gui, 'plotter') && !is_boolean(gui.plotter)) {
	    gui.plotter.done();
	    gui.plotter := F;
	}

	gui.pgpf := gui.ws.frame(gui.tabletop, side='top');

	if (width <= 0 || height <= 0) {
	    local region := gui.canvas->region();
	    width := region[3];
	    height := region[4];
	} else {
	    width := as_integer(width);
	    height := as_integer(height);
	}

	gui.pgp := pgplotwidget(gui.pgpf, size=[width, height], havemessages=F);
	gui.pgp.sch(1.0);

	gui.pgp.record(F);
	gui.pgp.cursor(mode=gui.cursor);
	gui.pgp.page();
	gui.pgp.vstd();

	for(cb in field_names(gui.callback)) 
	    gui.pgp.setcallback(cb, gui.callback[cb]);

	return T;
    }

    #@
    # change to a new cursor
    # @param name   the cursor name
    ##
    public.setcursor := function(name) {
	wider gui, PGCURSORS;
	if (! any(name == PGCURSORS)) 
	    fail spaste(name, ': unsupported cursor');
	gui.cursor := cursor;
	if (has_field(gui, 'pgp')) {
	    print '####DBG: now updating cursor';
	    gui.pgp.cursor(mode=gui.cursor);
	}
	return T;
    }

    #@ 
    # set a callback function to be associated with a gui event type
    ##
    public.setcallback := function(name, callback) {
	wider gui;

	gui.callback[name] := callback;
	if (has_field(gui, 'pgp') && ! is_boolean(gui.pgp)) 
	    gui.pgp.setcallback(name, callback);
	return T;
    }

    #@
    # resize the plot canvas
    # @param width   the width; if <= 0, reset to default
    # @param height  the height; if <= 0, reset to default
    # @param charheight   the character height to set in pixels
    ##
    public.resize := function(width=0, height=0, charheight=12) {
	wider its, gui;
	local ok := T;
	if (width <= 0) width := gui.dpwidth;
	if (height <= 0) height := gui.dpheight;
	if (width != gui.pwidth || height != gui.pheight) {
	    gui.canvas->region(0, 0, width, height);
	    ok := its.newplotter(width, height, charheight);
	    gui.pwidth := width;
	    gui.pheight := height;
	}

	return ok;
    }

    #@ 
    # return a reference to the pgplot widget
    public.getpgplotter := function() {
	wider gui;
	return ref gui.pgp;
    }

    #@ 
    # return the view position of the canvas as set by the current position
    # of the scrollbars.
    ##
    public.getscrollpos := function() {
	wider gui;
	return gui.canvpos;
    }

    #@
    # return the size of the viewable portion of the canvas
    ##
    public.getviewsize := function() {
	wider gui;

	# The '12' is the inevitable fudge factor.
	local width :=  gui.northf->width() - 2*gui.northf->borderwidth() -
	                   gui.vsb->width() - 20;
	local height := gui.northf->height() - 2*gui.northf->borderwidth();
	return [width, height];
    }

    #@
    # return the size of the full plot size (beyond what is viewable)
    ##
    public.getplotsize := function() {
	wider gui;
	return [gui.pwidth, gui.pheight];
    }

    #@
    # slide the viewable portion of the plot horizontally show a given position
    # @param pos   the position 
    ##
    public.viewx := function(pos) {
	wider gui;
	gui.canvas->view(paste('xview moveto ', pos));
	return T;
    }

    #@ 
    # delete this widget
    ##
    public.done := function() {
	wider public, gui;
#	rdelete(gui);
	gui := F;
	public := F;
	return T;
    }

    if (cursor != gui.cursor) public.setcursor(cursor);
    its.build(width,height,parent);

    public.its := ref its;
    public.gui := ref gui;
    return ref public;
}

gpfwidgetsdemo := function(nants=9, pwidth=650, height=425) {
    top := dws.frame(F, side='top');

    ant := gpf_axisvalselection(top, 'Antenna', [1:15]);

    colf := dws.frame(top, side='left');
    pol := gpf_axisvalselection(colf, 'Polarization', "R L", doallnone=F);
    sb := gpf_axisvalselection(colf, 'Sideband', "USB LSB", doallnone=F);
    comp := gpf_axisvalselection(colf, '', "Amp Phase Real Imag", doallnone=F);

    msg := gpf_messagedisplay(top);

    pwj := gpf_plotterwidget(top, 650, 450);
    pwj.resize(800,512);
    pwj.getpgplotter().arro(0,0,50,50);

    action := function(input) { print input; }
    pwj.setcallback('button', action);

    msg.append("hello");
    msg.append("world!");

    return T;
}

# wjt := gpf_axisvalselection_demo(8, 4);

#  include 'gainpolyfitter_plotter.g';
#  pltr := gainpolyfitter_plotter(15, 4, winargs, panargs, pgp)


# action := function(input) { print input; }
# wj.setcallback('key', action);



#  include 'pgplotwidget.g';
#  pgpf := dws.frame(top, side='top');
