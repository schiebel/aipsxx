# widgetserver.g: provision of aips++-conformant widgets: buttons, frames, etc.
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
# $Id: widgetserver.g,v 19.2 2004/08/25 02:22:32 cvsmgr Exp $

pragma include once;

include 'note.g';
include 'unset.g';

# include gdisplay.g to make pixelcanvas et al. available in 
# dgtk, and therefore in dws.  Remove this include when 
# transition to dl-specific ddlgtk and ddlws is complete.
include 'gdisplay.g';

# The widgetserver closure object.  The display library (viewer) is
# supported provided the supplied widgetset has it *already* loaded.
# That is, you cannot create a widgetserver, and decide later that
# you want the display library loaded.
const widgetserver := function(whichgtk=dgtk) {
    
    its := [=];
    public := [=];

    # 1. verify that we have a widgetset
    if (!is_record(whichgtk) || !has_field(whichgtk, 'frame')) {
	fail 'No Tk widgets present in supplied gtk record';
    }

    # 2. ensure we are using glishtk client for widgets
    tmp := as_string(whichgtk.frame);
    if (!(tmp~m/gtk->/)) {
	fail 'Only GlishTk widgets now supported by widgetserver';
    }

    # 3. store the basic Tk widgets in a useful place
    its.wdgts := whichgtk;
    for (tmp in field_names(its.wdgts)) {
	public[tmp] := ref its.wdgts[tmp];
    }

    # storage and access for the defaults
    its.defaults := [=];
    its.defaults.app := [=];
    its.defaults.glish := [=];
    include 'aipsrc.g';
    its.arc := drc;

    public.have_gui := function(...) {
	return its.wdgts.have_gui(...);
    }
    public.type := function () {
       return 'widgetserver';
    }

############################################################
## CONTROL OF TOP-LEVEL MODE                              ##
############################################################
    its.arc.find(its.wmode, 'gui.prefs.mode', 'app');
    if ((its.wmode != 'app') && (its.wmode != 'glish')) {
	fail 'unsuitable mode: should be \'app\' or \'glish\'';
    }

    its.wmodes := "";
    public.setmode := function(mode) {
	if ((mode != 'app') && (mode != 'glish')) {
	    fail 'unsuitable mode: should be \'app\' or \'glish\'';
	}
	wider its;
	its.wmodes := paste(its.wmodes, its.wmode);
	its.wmode := mode;
	return T;
    }
    public.unsetmode := function() {
	wider its;
	temp := split(its.wmodes);
	if (len(temp) < 2) {
	    its.wmode := as_string(its.wmodes[1]);
	} else {
	    its.wmodes := paste(temp[1:(len(temp)-1)]);
	    its.wmode := as_string(temp[len(temp)]);
	}
	return T;
    }

############################################################
## QUERY WHAT THE RESOURCES ARE USED                      ##
############################################################
    its.expand := [=];
    its.expand.rf := 'relief';
    its.expand.ft := 'font';
    its.expand.fg := 'foreground';
    its.expand.bg := 'background';
    public.resources := function(widget, type=F) {
	if (!has_field(public, widget)) {
	    fail 'unknown widget';
	} else if (!has_field(its.store, widget)) {
	    fail 'no resources for this widget';
	} else if ((widget == 'button') && 
		   !has_field(its.defaults[its.wmode][its.store[widget]],
			      type)) {
	    fail 'incorrect or missing type button widget';
	}
	if (widget != 'button') {
	    rec := ref its.defaults[its.wmode][its.store[widget]];
	} else {
	    rec := ref its.defaults[its.wmode][its.store[widget]][type];
	}
	copy := [=];
	for (i in field_names(rec)) {
	    if (has_field(its.expand, i)) {
		copy[its.expand[i]] := rec[i];
	    } else {
		copy[i] := rec[i];
	    }
	}
	return copy;
    }

############################################################
## FONTS                                                  ##
############################################################
    its.defaults.app.fonts := [=];
    its.arc.find(its.defaults.app.fonts.small, 
		 'gui.prefs.fonts.small', 
                 '-*-courier-medium-r-normal--10-*');
    its.arc.find(its.defaults.app.fonts.medium, 
		 'gui.prefs.fonts.medium', 
                 '-*-courier-medium-r-normal--12-*');
    its.arc.find(its.defaults.app.fonts.large, 
		 'gui.prefs.fonts.large', 
                 '-*-courier-medium-r-normal--14-*');
    its.arc.find(its.defaults.app.fonts.bold, 
		 'gui.prefs.fonts.bold', 
                 '-*-courier-bold-r-normal--12-*');
    its.defaults.glish.fonts := [=];
    its.defaults.glish.fonts.small := '';
    its.defaults.glish.fonts.medium := '';
    its.defaults.glish.fonts.large := '';
    its.defaults.glish.fonts.bold := '';
    its.defaults.glish.fonts[''] := '';

############################################################
## FRAMES                                                 ##
############################################################
    its.store.frame := 'frames';
    its.defaults.app.frames := [=];
    its.arc.find(its.defaults.app.frames.fg, 
		 'gui.prefs.frame.foreground', 
                 'black');
    its.arc.find(its.defaults.app.frames.bg, 
		 'gui.prefs.frame.background', 
                 'lightgray');
    its.arc.find(its.defaults.app.frames.rf, 
		 'gui.prefs.frame.relief', 
                 'flat');
    its.arc.find(its.defaults.app.frames.ft, 
		 'gui.prefs.frame.font', 
                 'medium');
    its.defaults.glish.frames := [=];
    its.defaults.glish.frames.fg := 'black';
    its.defaults.glish.frames.bg := 'lightgrey';
    its.defaults.glish.frames.rf := 'flat';
    its.defaults.glish.frames.ft := '';
    public.frame := function(parent=F, 
			     relief='xing',
			     borderwidth=2,
			     side='top', padx=0, pady=0, expand='both',
			     background='xing',
			     width=70,
			     height=50, cursor='', title='glish/tk',
			     icon='', newcmap=F, tlead=F, tpos='sw') {
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].frames.rf; }
	if (background == 'xing') {
	    background := its.defaults[its.wmode].frames.bg; }
	return its.wdgts.frame(parent, relief, borderwidth, side, padx, 
			      pady, expand, background, width, height, 
			      cursor, title, icon, newcmap, tlead, tpos);
    }

############################################################
## BUTTONS                                                ##
############################################################
    its.store.button := 'buttons';
    its.defaults.app.buttons := [=];
    its.defaults.glish.buttons := [=];

    its.defaults.app.buttons.plain := [=];
    its.arc.find(its.defaults.app.buttons.plain.fg, 
		 'gui.prefs.plainbutton.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.buttons.plain.bg, 
		 'gui.prefs.plainbutton.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.buttons.plain.rf, 
		 'gui.prefs.plainbutton.relief', 
                 'raised');
    its.arc.find(its.defaults.app.buttons.plain.ft, 
		 'gui.prefs.plainbutton.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.buttons.plain.fg := 'black';
    its.defaults.glish.buttons.plain.bg := 'lightgrey';
    its.defaults.glish.buttons.plain.rf := 'raised';
    its.defaults.glish.buttons.plain.ft := '';

    its.defaults.app.buttons.check := [=];
    its.arc.find(its.defaults.app.buttons.check.fg, 
		 'gui.prefs.checkbutton.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.buttons.check.bg, 
		 'gui.prefs.checkbutton.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.buttons.check.rf, 
		 'gui.prefs.checkbutton.relief', 
                 'raised');
    its.arc.find(its.defaults.app.buttons.check.ft, 
		 'gui.prefs.checkbutton.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.buttons.check.fg := 'black';
    its.defaults.glish.buttons.check.bg := 'lightgrey';
    its.defaults.glish.buttons.check.rf := 'raised';
    its.defaults.glish.buttons.check.ft := '';
    
    its.defaults.app.buttons.radio := [=];
    its.arc.find(its.defaults.app.buttons.radio.fg, 
		 'gui.prefs.radiobutton.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.buttons.radio.bg, 
		 'gui.prefs.radiobutton.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.buttons.radio.rf, 
		 'gui.prefs.radiobutton.relief', 
                 'raised');
    its.arc.find(its.defaults.app.buttons.radio.ft, 
		 'gui.prefs.radiobutton.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.buttons.radio.fg := 'black';
    its.defaults.glish.buttons.radio.bg := 'lightgrey';
    its.defaults.glish.buttons.radio.rf := 'raised';
    its.defaults.glish.buttons.radio.ft := '';
    
    its.defaults.app.buttons.menu := [=];
    its.arc.find(its.defaults.app.buttons.menu.fg, 
		 'gui.prefs.menubutton.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.buttons.menu.bg, 
		 'gui.prefs.menubutton.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.buttons.menu.rf, 
		 'gui.prefs.menubutton.relief', 
                 'flat');
    its.arc.find(its.defaults.app.buttons.menu.ft, 
		 'gui.prefs.menubutton.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.buttons.menu.fg := 'black';
    its.defaults.glish.buttons.menu.bg := 'lightgrey';
    its.defaults.glish.buttons.menu.rf := 'raised';
    its.defaults.glish.buttons.menu.ft := '';
    
    its.defaults.app.buttons.action := [=];
    its.arc.find(its.defaults.app.buttons.action.fg, 
		 'gui.prefs.actionbutton.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.buttons.action.bg, 
		 'gui.prefs.actionbutton.background', 
                 'green');
    its.arc.find(its.defaults.app.buttons.action.rf, 
		 'gui.prefs.actionbutton.relief', 
                 'raised');
    its.arc.find(its.defaults.app.buttons.action.ft, 
		 'gui.prefs.actionbutton.font', 
                 'bold');
    its.defaults.glish.buttons.action.fg := 'black';
    its.defaults.glish.buttons.action.bg := 'lightgrey';
    its.defaults.glish.buttons.action.rf := 'raised';
    its.defaults.glish.buttons.action.ft := '';

    its.defaults.app.buttons.halt := [=];
    its.arc.find(its.defaults.app.buttons.halt.fg, 
		 'gui.prefs.haltbutton.foreground', 
                 'white');
    its.arc.find(its.defaults.app.buttons.halt.bg, 
		 'gui.prefs.haltbutton.background', 
                 'red');
    its.arc.find(its.defaults.app.buttons.halt.rf, 
		 'gui.prefs.haltbutton.relief', 
                 'raised');
    its.arc.find(its.defaults.app.buttons.halt.ft, 
		 'gui.prefs.haltbutton.font', 
                 'bold');
    its.defaults.glish.buttons.halt.fg := 'black';
    its.defaults.glish.buttons.halt.bg := 'lightgrey';
    its.defaults.glish.buttons.halt.rf := 'raised';
    its.defaults.glish.buttons.halt.ft := '';

    its.defaults.app.buttons.dismiss := [=];
    its.arc.find(its.defaults.app.buttons.dismiss.fg, 
		 'gui.prefs.dismissbutton.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.buttons.dismiss.bg, 
		 'gui.prefs.dismissbutton.background', 
                 'orange');
    its.arc.find(its.defaults.app.buttons.dismiss.rf, 
		 'gui.prefs.dismissbutton.relief', 
                 'raised');
    its.arc.find(its.defaults.app.buttons.dismiss.ft, 
		 'gui.prefs.dismissbutton.font', 
                 'bold');
    its.defaults.glish.buttons.dismiss.fg := 'black';
    its.defaults.glish.buttons.dismiss.bg := 'lightgrey';
    its.defaults.glish.buttons.dismiss.rf := 'raised';
    its.defaults.glish.buttons.dismiss.ft := '';

    public.button := function(parent, text='button', type='plain',
			      padx=7, pady=3, width=0, height=0,
			      justify='center', font='xing', 
			      relief='xing',
			      borderwidth=2, 
			      foreground='xing',
			      background='xing',
			      disabled=F, value=T, anchor='c',
			      fill='none', bitmap='',
			      group=parent) {
	type := to_lower(type);
	if (relief == 'xing') {
	    if (has_field(its.defaults[its.wmode].buttons, type))  {
		relief := its.defaults[its.wmode].buttons[type].rf;
	    } else {
		relief := its.defaults.glish.buttons.plain.rf;
	    }
	}
	if (foreground == 'xing') {
	    if (has_field(its.defaults[its.wmode].buttons, type)) {
		foreground := its.defaults[its.wmode].buttons[type].fg;
	    } else {
		foreground := its.defaults.glish.buttons.plain.fg;
	    }
	}
	if (background == 'xing') {
	    if (has_field(its.defaults[its.wmode].buttons, type)) {
		background := its.defaults[its.wmode].buttons[type].bg;
	    } else {
		background := its.defaults.glish.buttons.plain.bg;
	    }
	}
	if (font == 'xing') {
	    if (has_field(its.defaults[its.wmode].buttons, type)) {
		font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
						   buttons[type].ft];
	    } else {
		font := its.defaults.glish.fonts[its.defaults.glish.
						 buttons.plain.ft];
	    }
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	if (!any(type == "plain check radio menu")) {
	    type := 'plain';
	}
	return its.wdgts.button(parent, text, type, padx, pady, width, 
			       height, justify, font, relief, borderwidth, 
			       foreground, background, disabled, value, 
			       anchor, fill, bitmap, group);
    }

############################################################
## SCALE                                                  ##
############################################################
    its.store.scale := 'scales';
    its.defaults.app.scales := [=];
    its.arc.find(its.defaults.app.scales.fg, 
		 'gui.prefs.scale.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.scales.bg, 
		 'gui.prefs.scale.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.scales.rf, 
		 'gui.prefs.scale.relief', 
                 'flat');
    its.arc.find(its.defaults.app.scales.ft, 
		 'gui.prefs.scale.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.scales := [=];
    its.defaults.glish.scales.fg := 'black';
    its.defaults.glish.scales.bg := 'lightgrey';
    its.defaults.glish.scales.rf := 'flat';
    its.defaults.glish.scales.ft := '';
    public.scale := function(parent, start=0.0, end=100.0, value=start,
			     length=110, text='', resolution=1.0,
			     orient='horizontal', width=15, 
			     font='xing',
			     relief='xing',
			     borderwidth=2, 
			     foreground='xing',
			     background='xing',
			     fill='') {
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].scales.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].scales.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].scales.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       scales.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return its.wdgts.scale(parent, start, end, value, length, text, 
			      resolution, orient, width, font, relief, 
			      borderwidth, foreground, background, fill);
    }

############################################################
## TEXT                                                  ##
############################################################
    its.store.text := 'texts';
    its.defaults.app.texts := [=];
    its.arc.find(its.defaults.app.texts.fg, 
		 'gui.prefs.text.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.texts.bg, 
		 'gui.prefs.text.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.texts.rf, 
		 'gui.prefs.text.relief', 
                 'sunken');
    its.arc.find(its.defaults.app.texts.ft, 
		 'gui.prefs.text.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.texts := [=];
    its.defaults.glish.texts.fg := 'black';
    its.defaults.glish.texts.bg := 'lightgrey';
    its.defaults.glish.texts.rf := 'flat';
    its.defaults.glish.texts.ft := '';
    public.text := function(parent, width=30, height=8, wrap='word',
			    font='xing',
			    disabled=F, text='',
			    relief='xing',
			    borderwidth=2,
			    foreground='xing',
			    background='xing',
			    fill='both') {
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].texts.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].texts.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].texts.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       texts.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return its.wdgts.text(parent, width, height, wrap, font, disabled, 
			     text, relief, borderwidth, foreground, 
			     background, fill);
    }

############################################################
## SCROLLBAR                                                  ##
############################################################
    its.store.scrollbar := 'scrollbars';
    its.defaults.app.scrollbars := [=];
    its.arc.find(its.defaults.app.scrollbars.fg, 
		 'gui.prefs.scrollbar.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.scrollbars.bg, 
		 'gui.prefs.scrollbar.background', 
                 its.defaults.app.frames.bg);
    its.defaults.glish.scrollbars := [=];
    its.defaults.glish.scrollbars.fg := 'black';
    its.defaults.glish.scrollbars.bg := 'lightgrey';
    public.scrollbar := function(parent, orient='vertical', width=15, 
				 foreground='xing',
				 background='xing', jump=F) {
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].scrollbars.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].scrollbars.bg;
	}
	return its.wdgts.scrollbar(parent, orient, width, foreground, 
				  background, jump);
    }

############################################################
## LABEL                                                  ##
############################################################
    its.store.label := 'labels';
    its.defaults.app.labels := [=];
    its.arc.find(its.defaults.app.labels.fg, 
		 'gui.prefs.label.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.labels.bg, 
		 'gui.prefs.label.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.labels.rf, 
		 'gui.prefs.label.relief', 
                 'flat');
    its.arc.find(its.defaults.app.labels.ft, 
		 'gui.prefs.label.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.labels := [=];
    its.defaults.glish.labels.fg := 'black';
    its.defaults.glish.labels.bg := 'lightgrey';
    its.defaults.glish.labels.rf := 'flat';
    its.defaults.glish.labels.ft := '';
    public.label := function(parent, text='label', justify='left',
			     padx=4, pady=2, 
			     font='xing',
			     width=0, 
			     relief='xing',
			     borderwidth=2,
			     foreground='xing',
			     background='xing',
			     anchor='c', fill='none') {
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].labels.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].labels.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].labels.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       labels.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return its.wdgts.label(parent, text, justify, padx, pady, font, 
			      width, relief, borderwidth, foreground, 
			      background, anchor, fill);
    }

############################################################
## ENTRY                                                  ##
############################################################
    its.store.entry := 'entries';
    its.defaults.app.entries := [=];
    its.arc.find(its.defaults.app.entries.fg, 
		 'gui.prefs.entry.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.entries.bg, 
		 'gui.prefs.entry.background', 
                 'white');
    its.arc.find(its.defaults.app.entries.rf, 
		 'gui.prefs.entry.relief', 
                 'sunken');
    its.arc.find(its.defaults.app.entries.ft, 
		 'gui.prefs.entry.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.entries := [=];
    its.defaults.glish.entries.fg := 'black';
    its.defaults.glish.entries.bg := 'lightgrey';
    its.defaults.glish.entries.rf := 'sunken';
    its.defaults.glish.entries.ft := '';
    public.entry := function(parent, width=30, justify='left', 
			     font='xing',
			     relief='xing',
			     borderwidth=2, 
			     foreground='xing',
			     background='xing',
			     disabled=F,
			     show=T, exportselection=T, fill='x') {
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].entries.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].entries.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].entries.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       entries.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return its.wdgts.entry(parent, width, justify, font, relief, 
			      borderwidth, foreground, background, disabled, 
			      show, exportselection, fill);
    }
		 
############################################################
## MESSAGE                                                ##
############################################################
    its.store.message := 'messages';
    its.defaults.app.messages := [=];
    its.arc.find(its.defaults.app.messages.fg, 
		 'gui.prefs.message.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.messages.bg, 
		 'gui.prefs.message.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.messages.rf, 
		 'gui.prefs.message.relief', 
                 'sunken');
    its.arc.find(its.defaults.app.messages.ft, 
		 'gui.prefs.message.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.messages := [=];
    its.defaults.glish.messages.fg := 'black';
    its.defaults.glish.messages.bg := 'lightgrey';
    its.defaults.glish.messages.rf := 'flat';
    its.defaults.glish.messages.ft := '';
    public.message := function(parent, text='message', width=180,
			       justify='left', 
			       font='xing',
			       padx=4, pady=2, 
			       relief='xing',
			       borderwidth=3, 
			       foreground='xing',
			       background='xing',
			       anchor='c',
			       fill='none', aspect=-1) {
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].messages.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].messages.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].messages.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       messages.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return its.wdgts.message(parent, text, width, justify, font, padx,
				pady, relief, borderwidth, foreground,
				background, anchor, fill, aspect=aspect);
    }
		 
############################################################
## LISTBOX                                                  ##
############################################################
    its.store.listbox := 'listboxes';
    its.defaults.app.listboxes := [=];
    its.arc.find(its.defaults.app.listboxes.fg, 
		 'gui.prefs.listbox.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.listboxes.bg, 
		 'gui.prefs.listbox.background', 
                 'white');
    its.arc.find(its.defaults.app.listboxes.rf, 
		 'gui.prefs.listbox.relief', 
                 'sunken');
    its.arc.find(its.defaults.app.listboxes.ft, 
		 'gui.prefs.listbox.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.listboxes := [=];
    its.defaults.glish.listboxes.fg := 'black';
    its.defaults.glish.listboxes.bg := 'lightgrey';
    its.defaults.glish.listboxes.rf := 'sunken';
    its.defaults.glish.listboxes.ft := '';
    public.listbox := function(parent, width=20, height=6, mode='browse',
			       font='xing',
			       relief='xing',
			       borderwidth=2, 
			       foreground='xing',
			       background='xing',
			       exportselection=F,
			       fill='x') {
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].listboxes.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].listboxes.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].listboxes.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       listboxes.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return its.wdgts.listbox(parent, width, height, mode, font, relief, 
				borderwidth, foreground, background, 
				exportselection, fill);
    }

############################################################
## CANVAS                                                  ##
############################################################
    its.store.canvas := 'canvases';
    its.defaults.app.canvases := [=];
    its.arc.find(its.defaults.app.canvases.bg, 
		 'gui.prefs.canvas.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.canvases.rf, 
		 'gui.prefs.canvas.relief', 
                 'sunken');
    its.defaults.glish.canvases := [=];
    its.defaults.glish.canvases.bg := 'lightgrey';
    its.defaults.glish.canvases.rf := 'sunken';
    public.canvas := function(parent, width=200, height=150, 
			      region=[0,0,1000,400], 
			      relief='xing',
			      borderwidth=2, 
			      background='xing',
			      fill='both') {
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].canvases.rf;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].canvases.bg;
	}
	return its.wdgts.canvas(parent, width, height, region, relief, 
			       borderwidth, background, fill);
    }


############################################################
## AIPS++ WIDGETS                                         ##
############################################################

############################################################
## ROLLUP                                                 ##
############################################################
    its.store.rollup := 'rollups';
    its.defaults.app.rollups := [=];
    its.arc.find(its.defaults.app.rollups.fg, 
		 'gui.prefs.rollup.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.rollups.bg, 
		 'gui.prefs.rollup.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.rollups.rf, 
		 'gui.prefs.rollup.relief', 
                 'ridge');
    its.arc.find(its.defaults.app.rollups.ft, 
		 'gui.prefs.rollup.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.rollups := [=];
    its.defaults.glish.rollups.fg := 'black';
    its.defaults.glish.rollups.bg := 'lightgrey';
    its.defaults.glish.rollups.rf := 'ridge';
    its.defaults.glish.rollups.ft := '';
    public.rollup := function(parent,
			      font='xing',
			      relief='xing',
			      borderwidth=0, side='top', padx=0, pady=0,
			      expand='both', 
			      foreground='xing',
			      background='xing',
			      titleforeground='xing',
			      titlebackground='xing',
			      title='', show=T) {
        include 'rollup.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].rollups.rf;
	}
	if (titleforeground == 'xing') {
	    titleforeground := its.defaults[its.wmode].rollups.fg;
	}
	if (titlebackground == 'xing') {
	    titlebackground := its.defaults[its.wmode].rollups.bg;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].frames.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].frames.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       rollups.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return rollup(parent, font, relief, borderwidth, side, padx, 
		      pady, expand, foreground, background, title,
		      titleforeground, titlebackground, show,
		      public);
    }


############################################################
## TWODACTIONOPTIONMENU                                   ##
############################################################

    its.store.twodactionoptionmenu := 'twodactionoptiomenus';
    its.defaults.app.twodactionoptionmenus := [=];
    its.arc.find(its.defaults.app.twodactionoptionmenus.fg, 
		 'gui.prefs.optionmenu.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.twodactionoptionmenus.bg, 
		 'gui.prefs.optionmenu.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.twodactionoptionmenus.rf, 
		 'gui.prefs.optionmenu.relief', 
                 'groove');
    its.arc.find(its.defaults.app.twodactionoptionmenus.ft, 
		 'gui.prefs.optionmenu.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.twodactionoptionmenus := [=];
    its.defaults.glish.twodactionoptionmenus.fg := 'black';
    its.defaults.glish.twodactionoptionmenus.bg := 'lightgrey';
    its.defaults.glish.twodactionoptionmenus.rf := 'raised';
    its.defaults.glish.twodactionoptionmenus.ft := '';
    public.twodactionoptionmenu := function(ref parent, names="", 
					   values="", images="", 
					   altimages=F, altind=0,
					   buttonvalue=F,
					   ncolumn=3, nrow=3,
					   hlp='', hlp2='', padx=7, 
					   pady=3, width=-1,
					   height=1, justify='center', 
					    font='xing',
					   relief='xing', borderwidth=2,
					   foreground='xing', 
					   background='xing',
					   disabled=F, anchor='c',
					    fill='none', widgetset=dws) {


        include 'twodactionoptionmenu.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].twodactionoptionmenus.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].twodactionoptionmenus.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].twodactionoptionmenus.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       twodactionoptionmenus.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return twodactionoptionmenu(parent, names, 
					   values, images, 
					   altimages, altind,
					   buttonvalue,
					   ncolumn, nrow,
					   hlp, hlp2, padx, 
					   pady, width,
					   height, justify, 
					    font,
					   relief, borderwidth,
					   foreground, 
					   background,
					   disabled, anchor,
					    fill, widgetset);
    }

############################################################
## OPTIONMENU                                             ##
############################################################
    its.store.optionmenu := 'optionmenus';
    its.defaults.app.optionmenus := [=];
    its.arc.find(its.defaults.app.optionmenus.fg, 
		 'gui.prefs.optionmenu.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.optionmenus.bg, 
		 'gui.prefs.optionmenu.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.optionmenus.rf, 
		 'gui.prefs.optionmenu.relief', 
                 'groove');
    its.arc.find(its.defaults.app.optionmenus.ft, 
		 'gui.prefs.optionmenu.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.optionmenus := [=];
    its.defaults.glish.optionmenus.fg := 'black';
    its.defaults.glish.optionmenus.bg := 'lightgrey';
    its.defaults.glish.optionmenus.rf := 'raised';
    its.defaults.glish.optionmenus.ft := '';
    public.optionmenu := function(ref parent, labels="", names="", values="",
                                  hlp='', hlp2='', nbreak=20, padx=7, pady=3, 
                                  width=-1, updatelabel=T,
                                  height=1, justify='center', font='xing',
                                  relief='xing', borderwidth=2,
                                  foreground='xing', background='xing',
                                  disabled=F, anchor='c',
                                  fill='none') {
        include 'optionmenu.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].optionmenus.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].optionmenus.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].optionmenus.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       optionmenus.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return optionmenu(parent, labels, names, values, hlp, hlp2, 
			  nbreak, padx, pady, width, updatelabel, height, 
                          justify, font, relief, borderwidth, 
                          foreground, background, 
			  disabled, anchor, fill, public);
    }

############################################################
## EXTENDOPTIONMENU                                       ##
############################################################
    its.store.extendoptionmenu := 'extendoptionmenus';
    its.defaults.app.extendoptionmenus := [=];
    its.arc.find(its.defaults.app.extendoptionmenus.fg, 
		 'gui.prefs.extendoptionmenu.foreground', 
                 its.defaults.app.optionmenus.fg);
    its.arc.find(its.defaults.app.extendoptionmenus.bg, 
		 'gui.prefs.extendoptionmenu.background', 
                 its.defaults.app.optionmenus.bg);
    its.arc.find(its.defaults.app.extendoptionmenus.rf, 
		 'gui.prefs.extendoptionmenu.relief', 
                 its.defaults.app.optionmenus.rf);
    its.arc.find(its.defaults.app.extendoptionmenus.ft, 
		 'gui.prefs.extendoptionmenu.font', 
                 its.defaults.app.optionmenus.ft);
    its.defaults.glish.extendoptionmenus := [=];
    its.defaults.glish.extendoptionmenus.fg := 'black';
    its.defaults.glish.extendoptionmenus.bg := 'lightgrey';
    its.defaults.glish.extendoptionmenus.rf := 'raised';
    its.defaults.glish.extendoptionmenus.ft := '';
    public.extendoptionmenu := function(ref parent, labels="", 
                                        hlp='', hlp2='', nbreak=20,
                                        symbol='...', 
                                        callback1=F, callback2=F,  
                                        callbackdata=F,
                                        dialoglabel='Item',
                                        dialogtitle='Enter new item <CR>',
                                        padx=7, pady=3, width=-1,
                                        updatelabel=T,
                                        height=1, justify='center', 
                                        font='xing', relief='xing', 
					borderwidth=2,
                                        foreground='xing', background='xing',
                                        disabled=F, anchor='c',
                                        fill='none') {
        include 'extendoptionmenu.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].extendoptionmenus.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].extendoptionmenus.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].extendoptionmenus.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       extendoptionmenus.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return extendoptionmenu(parent, labels, hlp, hlp2, nbreak, symbol, 
                                callback1, callback2, callbackdata,
                                dialoglabel, dialogtitle, padx, pady,
                                width, height, updatelabel, justify, 
                                font, relief, 
                                borderwidth, foreground, background, 
                                disabled, anchor, fill, public);
    }


############################################################
## ACTIONOPTIONMENU                                       ##
############################################################
    its.store.actionoptionmenu := 'actionoptionmenus';
    its.defaults.app.actionoptionmenus := [=];
    its.arc.find(its.defaults.app.actionoptionmenus.fg, 
		 'gui.prefs.actionoptionmenu.foreground', 
                 its.defaults.app.optionmenus.fg);
    its.arc.find(its.defaults.app.actionoptionmenus.bg, 
		 'gui.prefs.actionoptionmenu.background', 
                 its.defaults.app.optionmenus.bg);
    its.arc.find(its.defaults.app.actionoptionmenus.rf, 
		 'gui.prefs.actionoptionmenu.relief', 
                 'raised');
    its.arc.find(its.defaults.app.actionoptionmenus.ft, 
		 'gui.prefs.actionoptionmenu.font', 
                 its.defaults.app.optionmenus.ft);
    its.defaults.glish.actionoptionmenus := [=];
    its.defaults.glish.actionoptionmenus.fg := 'black';
    its.defaults.glish.actionoptionmenus.bg := 'lightgrey';
    its.defaults.glish.actionoptionmenus.rf := 'raised';
    its.defaults.glish.actionoptionmenus.ft := '';
    public.actionoptionmenu := function(ref parent, labels="", names="", 
					values="", hlp='', hlp2='', 
                                        nbreak=20, padx=7, pady=3, 
					width=-1, updatelabel=T,
					height=1, justify='center', 
					font='xing',
					relief='xing', borderwidth=2,
					foreground='xing', background='xing',
					disabled=F, anchor='c',
					fill='none') {
        include 'optionmenu.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].actionoptionmenus.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].actionoptionmenus.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].actionoptionmenus.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       actionoptionmenus.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return optionmenu(parent, labels, names, values, hlp, hlp2, 
			  nbreak, padx, pady, width, updatelabel, height, 
                          justify, font, relief, borderwidth, 
                          foreground, background, 
			  disabled, anchor, fill, public);
    }

############################################################
## CHECKMENU                                              ##
############################################################
    its.store.checkmenu := 'checkmenus';
    its.defaults.app.checkmenus := [=];
    its.arc.find(its.defaults.app.checkmenus.fg, 
		 'gui.prefs.checkmenu.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.checkmenus.bg, 
		 'gui.prefs.checkmenu.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.checkmenus.rf, 
		 'gui.prefs.checkmenu.relief', 
                 'groove');
    its.arc.find(its.defaults.app.checkmenus.ft, 
		 'gui.prefs.checkmenu.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.checkmenus := [=];
    its.defaults.glish.checkmenus.fg := 'black';
    its.defaults.glish.checkmenus.bg := 'lightgrey';
    its.defaults.glish.checkmenus.rf := 'raised';
    its.defaults.glish.checkmenus.ft := '';  
    public.checkmenu := function (ref parent, label='checkmenu', names="", 
                                  values="", hlp='', hlp2='', padx=7, 
                                  pady=3, width=0,
                                  height=1, justify='center', font='xing',
                                  relief='xing', borderwidth=2,
                                  foreground='xing', background='xing',
                                  disabled=F, anchor='c',
                                  fill='none') {
      include 'checkmenu.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].checkmenus.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].checkmenus.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].checkmenus.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       checkmenus.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
        return checkmenu(parent, label, names, values, hlp, hlp2, padx,
                         pady, width, height, justify, font, relief,
                         borderwidth, foreground, background,
                         disabled, anchor, fill, public);
    }

############################################################
## DIALOGBOX                                              ##
############################################################
    its.store.dialogbox := 'dialogboxes';
    its.defaults.app.dialogboxes := [=];
    public.dialogbox := function(label=unset, title='Dialog box',
				 type='entry', value=unset,
                                 hlp='', helpOnLabel=T) {
      include 'dialogbox.g';
	return dialogbox(label, title, type, value, hlp, helpOnLabel, public);
    }


############################################################
## TAPEDECK                                               ##
############################################################
    its.store.tapedeck := 'tapedecks';
    its.defaults.app.tapedecks := [=];
    its.arc.find(its.defaults.app.tapedecks.fg, 
		 'gui.prefs.tapedeck.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.tapedecks.bg, 
		 'gui.prefs.tapedeck.background', 
                 its.defaults.app.frames.bg);
    its.defaults.glish.tapedecks := [=];
    its.defaults.glish.tapedecks.fg := its.defaults.glish.frames.fg;
    its.defaults.glish.tapedecks.bg := its.defaults.glish.frames.bg;
    public.tapedeck := function(parent,
				background='xing',
				hasstop=T, hasplay=T, hasstep=T, hasto=T,
				hasforward=T, hasreverse=T,
				stopcolor='xing', playcolor='xing',
				stepcolor='xing', tocolor='xing',
				orient='horizontal') {
        include 'tapedeck.g';
	if (background == 'xing') {
	    background := its.defaults[its.wmode].tapedecks.bg;
	}
	if (stopcolor == 'xing') {
	    stopcolor := its.defaults[its.wmode].buttons.halt.bg;
	}
	if (playcolor == 'xing') {
	    playcolor := its.defaults[its.wmode].buttons.action.bg;
	}
	if (stepcolor == 'xing') {
	    stepcolor := its.defaults[its.wmode].tapedecks.fg;
	}
	if (tocolor == 'xing') {
	    tocolor := its.defaults[its.wmode].tapedecks.fg;
	}
	return tapedeck(parent, background, hasstop, hasplay, hasstep,
			hasto, hasforward, hasreverse, stopcolor,
			playcolor, stepcolor, tocolor, orient, public);
    }

############################################################
## MESSAGELINE                                            ##
############################################################
    its.store.messageline := 'messagelines';
    its.defaults.app.messagelines := [=];
    its.arc.find(its.defaults.app.messagelines.fg, 
		 'gui.prefs.messageline.foreground', 
                 its.defaults.app.messages.fg);
    its.arc.find(its.defaults.app.messagelines.bg, 
		 'gui.prefs.messageline.background', 
                 its.defaults.app.messages.bg);
    its.arc.find(its.defaults.app.messagelines.rf, 
		 'gui.prefs.messageline.relief', 
                 its.defaults.app.messages.rf);
    its.arc.find(its.defaults.app.messagelines.ft, 
		 'gui.prefs.messageline.font', 
                 its.defaults.app.messages.ft);
    its.defaults.glish.messagelines := [=];
    its.defaults.glish.messagelines.fg := its.defaults.glish.messages.fg;
    its.defaults.glish.messagelines.bg := its.defaults.glish.messages.bg;
    its.defaults.glish.messagelines.rf := its.defaults.glish.messages.rf;
    its.defaults.glish.messagelines.ft := its.defaults.glish.messages.ft;
    public.messageline := function(parent, width=30,
				   justify='left', 
				   font='xing', relief='xing', borderwidth=2, 
				   foreground='xing',
				   background='xing',
				   exportselection=T,
				 hlp='Messages of interest will appear here.',
				   messagenote=note) {
        include 'messageline.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].messagelines.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].messagelines.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].messagelines.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       messagelines.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return messageline(parent, width, justify, font, relief, borderwidth, 
			   foreground, background, exportselection,
			   hlp, messagenote, public);
    }
		 
############################################################
## SCROLLLISTBOX                                          ##
############################################################
    its.store.scrolllistbox := 'scrolllistboxes';
    its.defaults.app.scrolllistboxes := [=];
    its.arc.find(its.defaults.app.scrolllistboxes.fg, 
		 'gui.prefs.scrolllistbox.foreground', 
                 its.defaults.app.listboxes.fg);
    its.arc.find(its.defaults.app.scrolllistboxes.bg, 
		 'gui.prefs.scrolllistbox.background', 
                 its.defaults.app.listboxes.bg);
    its.arc.find(its.defaults.app.scrolllistboxes.rf, 
		 'gui.prefs.scrolllistbox.relief', 
                 its.defaults.app.listboxes.rf);
    its.arc.find(its.defaults.app.scrolllistboxes.ft, 
		 'gui.prefs.scrolllistbox.font', 
                 its.defaults.app.listboxes.ft);
    its.defaults.glish.scrolllistboxes := [=];
    its.defaults.glish.scrolllistboxes.fg := its.defaults.glish.listboxes.fg;
    its.defaults.glish.scrolllistboxes.bg := its.defaults.glish.listboxes.bg;
    its.defaults.glish.scrolllistboxes.rf := its.defaults.glish.listboxes.rf;
    its.defaults.glish.scrolllistboxes.ft := its.defaults.glish.listboxes.ft;
    public.scrolllistbox := function(parent, hscrollbar=T,
				     vscrollbar=T, vscrollbarright=T,
				     seeoninsert=T, width=20, height=6,
				     mode='browse', font='xing', 
				     relief='xing', borderwidth=2, 
				     foreground='xing', background='xing',
				     exportselection=F, fill='both') {
        include 'scrolllistbox.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].scrolllistboxes.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].scrolllistboxes.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].scrolllistboxes.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       scrolllistboxes.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return scrolllistbox(parent, hscrollbar, vscrollbar,
			     vscrollbarright, seeoninsert,
			     width, height, mode, font, relief, borderwidth, 
			     foreground, background, exportselection, fill,
			     public);
    }


############################################################
## SCROLLTEXT                                             ##
############################################################
    its.store.scrolltext := 'scrolltexts';
    its.defaults.app.scrolltexts := [=];
    its.arc.find(its.defaults.app.scrolltexts.fg, 
		 'gui.prefs.scrolltext.foreground', 
                 its.defaults.app.listboxes.fg);
    its.arc.find(its.defaults.app.scrolltexts.bg, 
		 'gui.prefs.scrolltext.background', 
                 its.defaults.app.listboxes.bg);
    its.arc.find(its.defaults.app.scrolltexts.rf, 
		 'gui.prefs.scrolltext.relief', 
                 its.defaults.app.listboxes.rf);
    its.arc.find(its.defaults.app.scrolltexts.ft, 
		 'gui.prefs.scrolltext.font', 
                 its.defaults.app.listboxes.ft);
    its.defaults.glish.scrolltexts := [=];
    its.defaults.glish.scrolltexts.fg := its.defaults.glish.listboxes.fg;
    its.defaults.glish.scrolltexts.bg := its.defaults.glish.listboxes.bg;
    its.defaults.glish.scrolltexts.rf := its.defaults.glish.listboxes.rf;
    its.defaults.glish.scrolltexts.ft := its.defaults.glish.listboxes.ft;
    public.scrolltext := function(parent, hscrollbar=T, vscrollbar=T,
				  width=30, height=8,
				  wrap='none', font='xing', 
    			          disabled=F, text='', relief='xing', 
                                  borderwidth=2, foreground='xing', 
                                  background='xing',
   			          fill='both') 
{
    private := [=];   

        include 'scrolltext.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].scrolltexts.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].scrolltexts.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].scrolltexts.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       scrolltexts.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return scrolltext(parent, hscrollbar, vscrollbar, width,
			  height, wrap, font, disabled, text, relief, 
                          borderwidth, foreground, background, fill, public);
    }


############################################################
## SELECTABLELIST                                         ##
############################################################
    its.store.selectablelist := 'selectablelists';
    its.defaults.app.selectablelists := [=];
    its.arc.find(its.defaults.app.selectablelists.fg, 
		 'gui.prefs.selectablelist.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.selectablelists.bg, 
		 'gui.prefs.selectablelist.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.selectablelists.rf, 
		 'gui.prefs.selectablelist.relief', 
                 'groove');
    its.arc.find(its.defaults.app.selectablelists.ft, 
		 'gui.prefs.selectablelist.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.selectablelists := [=];
    its.defaults.glish.selectablelists.fg := 'black';
    its.defaults.glish.selectablelists.bg := 'lightgrey';
    its.defaults.glish.selectablelists.rf := 'groove';
    its.defaults.glish.selectablelists.ft := '';
    public.selectablelist := function(parent, lead, list, nbreak=20,
                                      label='Label', updatelabel=F,
                                      casesensitive=F,
                                      hlp='', padx=7, pady=3, width=0,
                                      height=1, justify='center', font='xing',
                                      relief='xing', borderwidth=2,
                                      foreground='xing', background='xing',
                                      disabled=F, anchor='c',
                                      fill='none') {
        include 'selectablelist.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].selectablelists.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].selectablelists.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].selectablelists.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       selectablelists.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return selectablelist(parent, lead, list, nbreak,
                              label, updatelabel,
                              casesensitive, hlp,
                              padx, pady, width,
                              height, justify, font,
                              relief, borderwidth,
                              foreground, background,
                              disabled, anchor,
                              fill, public);
    }

############################################################
## COMBOBOX                                               ##
############################################################
    its.store.combobox := 'comboboxes';
    its.defaults.app.comboboxes := [=];
    its.arc.find(its.defaults.app.comboboxes.fg, 
		 'gui.prefs.combobox.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.comboboxes.bg, 
		 'gui.prefs.combobox.background', 
                 its.defaults.app.frames.bg);
    its.defaults.app.comboboxes.label := [=];
    its.arc.find(its.defaults.app.comboboxes.label.rf, 
		 'gui.prefs.combobox.label.relief', 
                 its.defaults.app.labels.rf);
    its.arc.find(its.defaults.app.comboboxes.label.ft,
		 'gui.prefs.combobox.label.font',
		 its.defaults.app.labels.ft);
    its.defaults.app.comboboxes.entry := [=];
    its.arc.find(its.defaults.app.comboboxes.entry.rf, 
		 'gui.prefs.combobox.entry.relief', 
                 its.defaults.app.entries.rf);
    its.arc.find(its.defaults.app.comboboxes.entry.ft, 
		 'gui.prefs.combobox.entry.font', 
                 'medium');
    its.defaults.glish.comboboxes := [=];
    its.defaults.glish.comboboxes.fg := 'black';
    its.defaults.glish.comboboxes.bg := 'lightgrey';
    its.defaults.glish.comboboxes.label.rf := its.defaults.glish.labels.rf;
    its.defaults.glish.comboboxes.label.ft := '';
    its.defaults.glish.comboboxes.entry.rf := its.defaults.glish.entries.rf;
    its.defaults.glish.comboboxes.entry.ft := '';
    public.combobox := function(parent, labeltext='label', items=F,
				addonreturn=T, entrydisabled=F,
				canclearpopup=F, autoinsertorder='tail',
				disabled=F, borderwidth=2, exportselection=T, 
				vscrollbar='ondemand', hscrollbar='none',
				labelwidth=0, labelfont='xing',
				labelrelief='xing', labeljustify='left',
				labelbackground='xing', labelforeground='xing',
				labelanchor='c',
				entrywidth=30, entryfont='xing',
				entryrelief='xing', entryjustify='left',
				entrybackground='xing', entryforeground='xing',
				arrowbutton='downarrow.xbm',
				arrowbackground='xing', arrowforeground='xing',
				listboxheight=6, help='') {
        include 'combobox.g';
	if (labelrelief == 'xing') {
	    labelrelief := its.defaults[its.wmode].comboboxes.label.rf;
	}
	if (labelforeground == 'xing') {
	    labelforeground := its.defaults[its.wmode].comboboxes.fg;
	}
	if (labelbackground == 'xing') {
	    labelbackground := its.defaults[its.wmode].comboboxes.bg;
	}
	if (labelfont == 'xing') {
	    labelfont := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
							 comboboxes.label.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    labelfont := its.defaults[its.wmode].fonts[font];
	}
	if (entryrelief == 'xing') {
	    entryrelief := its.defaults[its.wmode].comboboxes.entry.rf;
	}
	if (entryforeground == 'xing') {
	    entryforeground := its.defaults[its.wmode].comboboxes.fg;
	}
	if (entrybackground == 'xing') {
	    entrybackground := its.defaults[its.wmode].comboboxes.bg;
	}
	if (entryfont == 'xing') {
	    entryfont := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
							 comboboxes.entry.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    entryfont := its.defaults[its.wmode].fonts[font];
	}
	if (arrowforeground == 'xing') {
	    arrowforeground := its.defaults[its.wmode].comboboxes.fg;
	}
	if (arrowbackground == 'xing') {
	    arrowbackground := its.defaults[its.wmode].comboboxes.bg;
	}
	return combobox(parent, labeltext, items, addonreturn, entrydisabled,
			canclearpopup, autoinsertorder, disabled, borderwidth,
			exportselection, vscrollbar, hscrollbar, 
			labelwidth, labelfont, labelrelief, labeljustify, 
			labelbackground, labelforeground, labelanchor,
			entrywidth, entryfont, entryrelief, entryjustify,
			entrybackground, entryforeground,
			arrowbutton, arrowbackground, arrowforeground,
			listboxheight, help, public);
    }
		 
############################################################
## GUIENTRY                                           ##
############################################################
    its.store.guientry := 'guientry';
    its.defaults.app.guientry := [=];
    its.arc.find(its.defaults.app.guientry.fg, 
		 'gui.prefs.guientry.foreground', 
                 its.defaults.app.entries.fg);
    its.arc.find(its.defaults.app.guientry.bg, 
		 'gui.prefs.guientry.background', 
                 its.defaults.app.entries.bg);
    its.arc.find(its.defaults.app.guientry.rf, 
		 'gui.prefs.guientry.relief', 
                 its.defaults.app.entries.rf);
    its.arc.find(its.defaults.app.guientry.ft, 
		 'gui.prefs.guientry.font', 
                 its.defaults.app.entries.ft);
    its.defaults.glish.guientry := [=];
    its.defaults.glish.guientry.fg := its.defaults.glish.entries.fg;
    its.defaults.glish.guientry.bg := its.defaults.glish.entries.bg;
    its.defaults.glish.guientry.rf := its.defaults.glish.entries.rf;
    its.defaults.glish.guientry.ft := its.defaults.glish.entries.ft;
    public.guientry := function(width=30, foreground='xing', background='xing',
                                font='xing', relief='xing',
				editablecolor='xing',
				uneditablecolor='xing',
				unsetcolor='xing',
				expand='xing') {
        include 'guientry.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].guientry.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].guientry.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].guientry.bg;
	}
	if (editablecolor == 'xing') {
	    editablecolor := 'white';
	}
	if (uneditablecolor == 'xing') {
	    uneditablecolor := its.defaults[its.wmode].guientry.bg;
	}
	if (unsetcolor == 'xing') {
  	    unsetcolor := 'yellow';
	}
	if (expand == 'xing') {
	    expand := 'none';
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       guientry.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
        return guientry (width=width, relief=relief, font=font,
			 foreground=foreground,
			 background=background,
			 editablecolor=editablecolor,
			 uneditablecolor=uneditablecolor,
			 unsetcolor=unsetcolor,
			 expand=expand,
			 widgetset=public);
    }

############################################################
## RECORDBROWSERWIDGET                                    ##
############################################################
    its.defaults.app.recordbrowser := [=];
    its.arc.find(its.defaults.app.recordbrowser.fg, 
		 'gui.prefs.recordbrowser.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.recordbrowser.bg, 
		 'gui.prefs.recordbrowser.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.recordbrowser.rf, 
		 'gui.prefs.recordbrowser.relief', 
                 its.defaults.app.messages.rf);
    its.arc.find(its.defaults.app.recordbrowser.ft, 
		 'gui.prefs.recordbrowser.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.recordbrowser := [=];
    its.defaults.glish.recordbrowser.fg := its.defaults.glish.frames.fg;
    its.defaults.glish.recordbrowser.bg := its.defaults.glish.frames.bg;
    its.defaults.glish.recordbrowser.rf := its.defaults.glish.frames.rf;
    its.defaults.glish.recordbrowser.ft := its.defaults.glish.frames.ft;
    public.recordbrowser := function(parent=unset, ref therecord=F, 
				     readonly=T, show=T,
				     width=400, font='xing', title='Record Browser(AIPS++)') {
        include 'recordbrowserwidget.g';
	relief := '';
	foreground := '';
	background := '';
        if (relief == 'xing') {
            relief := its.defaults[its.wmode].recordbrowser.rf;
        }
        if (foreground == 'xing') {
            foreground := its.defaults[its.wmode].recordbrowser.fg;
        }
        if (background == 'xing') {
            background := its.defaults[its.wmode].recordbrowser.bg;
        }
        if (font == 'xing') {
            font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
						  recordbrowser.ft];
        } else if (has_field(its.defaults[its.wmode].fonts, font)) {
            font := its.defaults[its.wmode].fonts[font];
        }
        return recordbrowserwidget (parent=parent, therecord=therecord,
                                    readonly=readonly, show=show,
                                    width=width, font=font, 
				    widgetset=public, title=title);
    }
		 
############################################################
## FONTCHOOSERWIDGET                                      ##
############################################################
    its.defaults.app.fontchooser := [=];
    its.arc.find(its.defaults.app.fontchooser.fg, 
		 'gui.prefs.fontchooser.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.fontchooser.bg, 
		 'gui.prefs.fontchooser.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.fontchooser.rf, 
		 'gui.prefs.fontchooser.relief', 
                 its.defaults.app.frames.rf);
    its.arc.find(its.defaults.app.fontchooser.ft, 
		 'gui.prefs.fontchooser.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.fontchooser := [=];
    its.defaults.glish.fontchooser.fg := its.defaults.glish.frames.fg;
    its.defaults.glish.fontchooser.bg := its.defaults.glish.frames.bg;
    its.defaults.glish.fontchooser.rf := its.defaults.glish.frames.rf;
    its.defaults.glish.fontchooser.ft := its.defaults.glish.frames.ft;
    public.fontchooser := function(parent=unset, font='xing')
    { 
      include 'fontchooserwidget.g';
      relief := '';
      foreground := '';
      background := '';
      if (relief == 'xing') {
	  relief := its.defaults[its.wmode].fontchooser.rf;
        }
        if (foreground == 'xing') {
            foreground := its.defaults[its.wmode].fontchooser.fg;
        }
        if (background == 'xing') {
            background := its.defaults[its.wmode].fontchooser.bg;
        }
        if (font == 'xing') {
            font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
                                               fontchooser.ft];
        } else if (has_field(its.defaults[its.wmode].fonts, font)) {
            font := its.defaults[its.wmode].fonts[font];
        }
        return fontchooserwidget (parent=parent, font=font, ws=public);
    }

############################################################
## BLINKLABEL                                             ##
############################################################
    its.store.blinklabel := 'blinklabels';
    its.defaults.app.blinklabels := [=];
    its.arc.find(its.defaults.app.blinklabels.fg, 
		 'gui.prefs.blinklabel.foreground', 
                 its.defaults.app.labels.fg);
    its.arc.find(its.defaults.app.blinklabels.bg, 
		 'gui.prefs.blinklabel.background', 
                 its.defaults.app.labels.bg);
    its.arc.find(its.defaults.app.blinklabels.rf, 
		 'gui.prefs.blinklabel.relief', 
                 its.defaults.app.labels.rf);
    its.arc.find(its.defaults.app.blinklabels.ft, 
		 'gui.prefs.blinklabel.font', 
                 its.defaults.app.labels.ft);
    its.defaults.glish.blinklabels := [=];
    its.defaults.glish.blinklabels.fg := 'black';
    its.defaults.glish.blinklabels.bg := 'lightgrey';
    its.defaults.glish.blinklabels.rf := 'flat';
    its.defaults.glish.blinklabels.ft := '';
    public.blinklabel := function(parent, text='label', justify='left',
				  hlp='',
				  padx=4, pady=2, 
				  font='xing',
				  width=0, 
				  relief='xing',
				  borderwidth=2,
				  foreground='xing',
				  background='xing',
				  anchor='c', fill='none',
				  blink=F, interval=1) {
        include 'blinklabel.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].blinklabels.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].blinklabels.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].blinklabels.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       blinklabels.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return blinklabel(parent, text, justify, hlp, padx, pady, font, 
			  width, relief, borderwidth, foreground, 
			  background, anchor, fill, blink,
			  interval, public);
    }

############################################################
## MULTISCALE                                             ##
############################################################
    its.store.multiscale := 'multiscales';
    its.defaults.app.multiscales := [=];
    its.arc.find(its.defaults.app.multiscales.fg, 
		 'gui.prefs.multiscale.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.multiscales.bg, 
		 'gui.prefs.multiscale.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.multiscales.rf, 
		 'gui.prefs.multiscale.relief', 
                 'flat');
    its.arc.find(its.defaults.app.multiscales.ft, 
		 'gui.prefs.multiscale.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.multiscales := [=];
    its.defaults.glish.multiscales.fg := 'black';
    its.defaults.glish.multiscales.bg := 'lightgrey';
    its.defaults.glish.multiscales.rf := 'flat';
    its.defaults.glish.multiscales.ft := '';
    public.multiscale := function(parent, start=0.0, end=100.0, 
				  values=[50.0],
				  names=[''],
                                  helps="",
				  constrain=F,
				  entry=F, extend=F,
				  length=110, resolution=1.0,
				  orient='horizontal', width=15, 
				  font='xing', relief='xing', borderwidth=2,
				  foreground='xing', background='xing',
				  fill='both') {
        include 'multiscale.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].multiscales.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].multiscales.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].multiscales.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       multiscales.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return multiscale(parent, start, end, values, names, helps,
			  constrain, entry, extend, length, resolution,
			  orient, width, font, relief, borderwidth,
			  foreground, background, fill, public);;
    }

############################################################
## POPUP                                                  ##
############################################################
    its.store.popup := 'popups';
    its.defaults.app.popups := [=];
    its.arc.find(its.defaults.app.popups.fg, 
		 'gui.prefs.popup.foreground', 
                 its.defaults.app.frames.fg);
    its.arc.find(its.defaults.app.popups.bg, 
		 'gui.prefs.popup.background', 
                 its.defaults.app.frames.bg);
    its.arc.find(its.defaults.app.popups.rf, 
		 'gui.prefs.popup.relief', 
                 'flat');
    its.arc.find(its.defaults.app.popups.ft, 
		 'gui.prefs.popup.font', 
                 its.defaults.app.frames.ft);
    its.defaults.glish.popups := [=];
    its.defaults.glish.popups.fg := 'black';
    its.defaults.glish.popups.bg := 'lightgrey';
    its.defaults.glish.popups.rf := 'flat';
    its.defaults.glish.popups.ft := '';
    public.popupselectmenu := function(parent, labels="",
				       background='xing', foreground='xing',
				       font='xing', relief='xing') {
      include 'popupselectmenu.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].popups.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].popups.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].popups.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       popups.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return popupselectmenu(parent, labels, background, foreground,
			       font, relief, public);
    }

############################################################
## RESTOREREGIONS                                         ##
############################################################
#
# The include is deferred because of a nasty circular dependency.
#
    public.restoreregions := function(ref parent=F, table='', 
                                      changenames=T, globalrestore=F) {
      include 'restoreregions.g';
      return restoreregions (parent, table, changenames, 
			     globalrestore, public);
    }
############################################################
## SAVEREGIONS                                            ##
############################################################
#
# The include is deferred because of a nasty circular dependency.
#
    public.saveregions := function(ref parent=F, table='', 
                                   ref regions=[=],
                                   changenames=T,
                                   globalsave=F) {
        include 'saveregions.g';
	return saveregions (parent, table, regions, changenames,
                            globalsave, public);
    }
############################################################
## DELETEREGIONS                                          ##
############################################################
#
# The include is deferred because of a nasty circular dependency.
#
    public.deleteregions := function(ref parent=F, table='', 
                                     ref regions="", source='table') {
        include 'deleteregions.g';
	return deleteregions (parent, table, regions, source, public);
    }

############################################################
## SYNCLISTBOXES                                          ##
############################################################
    its.store.synclistboxes := 'synclistboxes';
    its.defaults.app.synclistboxes := [=];
    its.arc.find(its.defaults.app.synclistboxes.fg, 
		 'gui.prefs.synclistboxes.foreground', 
                 its.defaults.app.listboxes.fg);
    its.arc.find(its.defaults.app.synclistboxes.bg, 
		 'gui.prefs.synclistboxes.background', 
                 its.defaults.app.listboxes.bg);
    its.arc.find(its.defaults.app.synclistboxes.rf, 
		 'gui.prefs.synclistboxes.relief', 
                 its.defaults.app.listboxes.rf);
    its.arc.find(its.defaults.app.synclistboxes.ft, 
		 'gui.prefs.synclistboxes.font', 
                 its.defaults.app.listboxes.ft);
    its.defaults.glish.synclistboxes := [=];
    its.defaults.glish.synclistboxes.fg := its.defaults.glish.listboxes.fg;
    its.defaults.glish.synclistboxes.bg := its.defaults.glish.listboxes.bg;
    its.defaults.glish.synclistboxes.rf := its.defaults.glish.listboxes.rf;
    its.defaults.glish.synclistboxes.ft := its.defaults.glish.listboxes.ft;
    public.synclistboxes := function(parent, nboxes=1, labels="",
				     leadbox=1, side='left', hscrollbar=T, 
				     vscrollbar=T, vscrollbarright=T,
				     seeoninsert=T, 
				     width=20, height=6, mode='browse', 
				     font='xing', relief='xing', borderwidth=2,
				     foreground='xing', background='xing',
				     exportselection=F, fill='both') {
        include 'synclistboxes.g';
	if (relief == 'xing') {
	    relief := its.defaults[its.wmode].synclistboxes.rf;
	}
	if (foreground == 'xing') {
	    foreground := its.defaults[its.wmode].synclistboxes.fg;
	}
	if (background == 'xing') {
	    background := its.defaults[its.wmode].synclistboxes.bg;
	}
	if (font == 'xing') {
	    font := its.defaults[its.wmode].fonts[its.defaults[its.wmode].
					       synclistboxes.ft];
	} else if (has_field(its.defaults[its.wmode].fonts, font)) {
	    font := its.defaults[its.wmode].fonts[font];
	}
	return synclistboxes(parent, nboxes, labels, leadbox, side,
			     hscrollbar, vscrollbar, vscrollbarright,
			     seeoninsert,
			     width, height, mode, font, relief, borderwidth, 
			     foreground, background, exportselection, fill,
			     public);
    }

    

############################################################
## HELPMENU                                               ###
###########################################################
    public.helpmenu := function(parent, menuitems=unset, refmanitems=unset, 
				callback=unset, helpitems=unset) {
        include 'helpmenu.g';
	return helpmenu(parent, menuitems, refmanitems, callback, 
			helpitems, public);
    }


############################################################
## MENUFRAMES                                             ##
############################################################
    public.menuframes := function(parent, menubutton, exclusive=T) {
        include 'menuframes.g';
	return menuframes(parent, menubutton, exclusive, public);
    }

############################################################
## TABDIALOG                                              ##
############################################################
    public.tabdialog := function(ref parent, colmax=5, 
				 hlthickness=5, title='Select') {
        include 'tabdialog.g'
	return tabdialog(parent, colmax, title, hlthickness, public);
    }

############################################################
## POPUPHELP functions                                    ##
############################################################

    public.popuphelp := function(ref fr, txt=F, hlp=F, combi=F,
				 width=60) {
        include 'popuphelp.g';
	return popuphelp(fr, txt, hlp, combi, width, public);
    }
    public.addpopuphelp := function(ref agents, maxlevels=4) {
        include 'popuphelp.g';
	return addpopuphelp(agents, maxlevels, public);
    }
    public.popupmenu := function(ref agent, deflt=F, relief='flat',
				 buttonlabel='?') {
        include 'popuphelp.g';
	return popupmenu(agent, deflt, relief, buttonlabel, public);
    }
    # popupremove doesn't actually need the widgetserver/glishtk
    # instance, but it is provided in the widgetserver for consistency.
    public.popupremove := function(ref ag=F, mxlevels=8) {
        include 'popuphelp.g';
	return popupremove(ag, mxlevels);
    }

############################################################
## busy cursor functions                                  ##
############################################################
    public.busy := function(busyframe, disable=T, busycursor='watch') {
	busyframe->cursor(busycursor);
	if (disable) busyframe->disable();
	return T;
    }

    public.notbusy := function(busyframe, enable=T, normalcursor='') {
	busyframe->cursor(normalcursor);
	if (enable) busyframe->enable();
	return T;
    }
	    

    return public;
}

const is_widgetserver := function(tool) {
  return is_record(tool) && has_field(tool, 'type') &&
    is_function(tool.type) && tool.type() == 'widgetserver';
}

dws := 0; # hack so that files included while constructing
          # dws believe it exists already.  This will always
          # work, PROVIDED no widgets are actually generated
          # until after dws is made.
const defaultwidgetserver := widgetserver();
const dws := ref defaultwidgetserver;

# We've supported aips++-specific widgets, so we better include
# them here:
#include 'popuphelp.g';

if (is_widgetserver(dws)) {
  note('defaultwidgetserver (dws) ready', priority='NORMAL', 
       origin='widgetserver.g');
} else {
  note('creation of defaultwidgetserver (dws) failed', priority='SEVERE',
       origin='widgetserver.g');
}
