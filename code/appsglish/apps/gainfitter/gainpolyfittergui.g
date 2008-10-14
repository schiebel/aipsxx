# gainpolyfittergui.g: gui for the gainpolyfitter tool
# Copyright (C) 2001,2002
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
# $Id: gainpolyfittergui.g,v 19.1 2004/08/25 01:16:30 cvsmgr Exp $
pragma include once;

include "note.g";
include "guimisc.g";
include "unset.g";
include "aips2help.g";
include "widgetserver.g";
include "popuphelp.g";
include "itemcontainer.g";

include "gpfwidgets.g";
include "gpfframework.g";
include "gpfplotter.g";

#@itemcontainer GainPolyFitterGuiOptionsItem
# contains options for configurging the default behavior of a gainpolyfitter
# GUI.  Users normally do not create these items themselves; they are used
# primarily for creating a gainpolyfittergui tool specialized for 
# certain circumstances.  The gainpolyfittergui.getoptions() function will 
# return an itemcontainer of this type.
# @field type      must be set to 'GainPolyFitterGuiOptionsItem'
# @field title     a string to appear at the top of the GUI frame.
# @field menus     a menus guiframework record, or F to use a default set
# @field actions   an actions guiframework record, or F to use a default set
# @field help      a help guiframework record, or F to use a default set
# @field axisbuttonlayout   a frame layout record for arranging axis buttons
# @field axisinfo                 
##

const DEFAULT_GPFKEYACTIONS := [zoomplot='z', zoompair='Z', 
			  fit0='0', fit1='1', fit2='2', fit3='3', fit4='4', 
			  fit5='5', fit6='6', fit7='7', fit8='8', fit9='9', 
			  scrollleft="Left \\", scrollright="Right `", 
			  plotleft=',', plotright='.', 
			  pageleft="Prior - _", pageright="Next + =", 
			  endleft="Home <", endright="End >",
			  addbreakpair='b', addbreakcol='B',
			  delbreakpair='j', delbreakcol='J',
			  flaggain='f', unflaggain='u', 
			  flagcol='F', unflagcol='U', 
			  redraw='r', redrawall='R'];

const DEFAULT_GPFGUIOPTIONS := [type='GainPolyFitterGuiOptionsItem',
			  title="gainpolyfitter", menus=F, help=F, actions=F,
			  axisbuttonlayout=F, 
			  cursor='left_ptr', pgcursor='cross', 
			  canvassize=[650, 450], nxyplots=[3, 4],
			  keyactions=DEFAULT_GPFKEYACTIONS];

#@tool public gpfittergui.g
# a graphical user interface to the gainpolyfitter tool.
#
# Users do not create this tool directly, but rather through the 
# gainpolyfitter.gui() function.  This tool is a driver layer that sits on
# top of gpfitterwidget, the main display widget, and gpfitterframe, the 
# surrounding frame.
#
# @constructor
# @param gpftool   the gainpolyfitter tool to drive
# @param options   the GUI options
# @param parent    a parent frame to connect the gui to, or F if the gui
#                    should be parentless.
# @param ws        the widgetserver to use.
gainpolyfittergui := function(ref gpftool, options=DEFAULT_GPFGUIOPTIONS,
			      parent=F, ref ws=dws) 
{
    public := [=];
    private := [gpf=ref gpftool, prnum=0, browsers=[=], keyfuncs=[=]];
    gui := [axisinfo=[=], busy=F, needRedraw=F, zoomed=[=],
	    mouseBusy=F, pendingMouse=F, buttonPressed=rep(F, 3),
	    actmap=[=], keyfuncs=[=]];

    # initialize the options
    {
	local opts := itemmanager();
	local defopts := DEFAULT_GPFGUIOPTIONS;
	defopts.plotopts := DEFAULT_GPFPLOTTEROPTIONS;
	opts.fromrecord(defopts);
	if (is_record(options)) opts.fromrecord(options);
	private.opts := opts.torecord();
	opts.done();

	# guard against some mistakes with options
	if (len(private.opts.nxyplots) < 2 || 
	    ! is_integer(private.opts.nxyplots))
	    fail paste('Bad values given for option nxyplots:', 
		       private.opts.nxyplots);
	
	if (len(private.opts.canvassize) < 2 || 
	    ! is_integer(private.opts.canvassize))
	    fail paste('Bad values given for option canvassize:', 
		       private.opts.canvassize);
    }
    # this is so we can use pgplotmanager's options manager to watch these
    # options for us.
    private.opts.plotopts.cursor := private.opts.cursor;
    private.opts.plotopts.pgcursor := private.opts.pgcursor;
    private.opts.plotopts.nxyplots := private.opts.nxyplots;

    #@
    # handle plot view selection requests from gui's selection buttons
    ##
    private.plotsselected := function(title='', state=F, values=[]) {
	wider private;
	local position := "off";
	if (state) position := "on";
	print "Turning", title, values, position;

	ok := gui.plotter.select(title, state, values, 'gpfgui');
	if (is_fail(ok)) 
	    note('gpfgui programming error: ', ok::message, priority='WARN',
		 origin='gpfgui');
	else 
	    private.redraw();

	return T;
    }

    private.fitterupdated := function(state=[=], name='', who='') {
	wider private, gui, public;

	if (name == 'gpfaction') {
	    if (has_field(state, 'fitindex') && ! is_unset(state.fitindex))
		public.redraw(state.fitindex);
	    else
		public.redraw();
	}

	return T;
    }

    private.plotterupdated := function(state=[=], name='', who='') {
	wider private, gui;

	if (name == 'gpfpoptions' && has_field(state, 'new')) {
	    if (state.item == 'clipfit') {
		gui.framework.setbuttonstate('display','clipfit',state.new);
	    } else if (state.item == 'clipmasked') {
		gui.framework.setbuttonstate('display','clipmasked',state.new);
	    } else if (state.item == 'showzero') {
		gui.framework.setbuttonstate('display','showyzero',state.new);
	    } else if (state.item == 'showfit') {
		gui.framework.setbuttonstate('display','showfit',state.new);
	    } else if (state.item == 'mirmode') {
		gui.framework.setbuttonstate('options','mirmode',state.new);
	    } else if (state.item == 'autofit') {
		gui.framework.setbuttonstate('options','autofit',state.new);
	    } else if (state.item == 'nxyplots') {
		local menu := "display plotsperview horizontally";
		private.switchradiobutton(menu, state.old[1], state.new[1]);
		menu[3] := 'vertically';
		private.switchradiobutton(menu, state.old[2], state.new[2]);
	    } else if (state.item == 'extrapolate') {
		gui.framework.setbuttonstate('options','autofit',state.new);
	    }
	    private.redraw();
	}
	else if (name == 'gpfpselection' && has_field(state, 'axis')) {
	    # update the selection button state
	    if (has_field(gui.axbut, state.axis)) 
		gui.axbut[state.axis].setstate(state.values, state.state);
	    else 
		print '###DBG: button panel not found for', state.axis;
	    private.redraw();
	}

	return T;
    }
    private.switchradiobutton := function(menu, old, new) {
	wider gui;

	local newstate := gui.framework.setbuttonstate(menu, as_string(new));

	if (is_fail(newstate)) {
	    if (newstate::message ~ m/no such button/) {
		# there is no button for the new value; just turn off the 
		# button for the old value
		local oldstate := 
		    gui.framework.setbuttonstate(menu, as_string(old), F);
		if (is_fail(oldstate)) {
		    if (oldstate::message ~ m/no such button/) {
			# ther is no button for the old value; turn off all 
			# buttons
			local buts := gui.framework.getbuttonnames(menu);
			local but;
			for (but in buts) {
			    oldstate:=gui.framework.setbuttonstate(menu,but,F);
			}
		    } else { return oldstate; }
		}
	    } else { return newstate; }
	}
    }

    private.build := function(ref parent, ref ws) {
	wider private, gui;

	# top frame
	gui.framework := gpfframework("GainPolyFitter",
				      menus=private.menus(),
				      helpmenu=private.helpmenu(),
				      actions=F);
	if (is_fail(gui.framework)) return gui.framework;
	if (is_boolean(gui.framework)) fail 'Failed to create gui framework';
#	gui.top := ws.frame(parent, side='top');
	gui.top := gui.framework.newworkframe();
	gui.axbut := [=];
	gui.miscf := [=];

	local axnames := [ private.gpf.fitsetaxes(), 'Component' ];
	local axdecor, axn;
	for(axn in axnames) gui.axbut[axn] := F;

	# build button panels according to layout option
	if (is_record(private.opts.axisbuttonlayout)) {
	    local fram, f, row;
	    local rows := field_names(private.opts.axisbuttonlayout);
	    for(row in rows) {
		if (length(private.opts.axisbuttonlayout[row]) == 0) continue;

		fram := ref gui.top;
		if (length(private.opts.axisbuttonlayout[row]) > 1) {
		    f := length(gui.miscf)+1;
		    gui.miscf[f] := ws.frame(gui.top, side='left');
		    fram := ref gui.miscf[f];
		}

		for(axn in private.opts.axisbuttonlayout[row]) {
		    if (! any(axn == axnames)) continue;
		    axdecor := private.gpf.axisdecoration(axn);

		    n := length(axdecor.values);
		    gui.axbut[axn] := 
			gpf_axisvalselection(fram, title=axn, 
					     values=axdecor.values, 
					     state=axdecor.initstate, 
					     labels=axdecor.labels, 
					     action=private.plotsselected, 
					     showtitle=axdecor.showtitle,
					     doallnone=(n > 4));
		}
	    }
	}

	# Now add any non-degenerate axes that were missed
	local axvals;
	for(axn in axnames) {
	    axdecor := private.gpf.axisdecoration(axn);
	    n := length(axdecor.values);
	    if (n <= 1) continue;

	    if (is_boolean(gui.axbut[axn])) {
		gui.axbut[axn] := 
		    gpf_axisvalselection(gui.top, title=axn, 
					 values=axdecor.values, 
					 state=axdecor.initstate, 
					 labels=axdecor.labels, 
					 action=private.plotsselected, 
					 showtitle=axdecor.showtitle,
					 doallnone=(n > 4));
	    }
	}

	gui.msg := gpf_messagedisplay(gui.top);

	gui.disp := gpf_plotterwidget(gui.top, private.opts.canvassize[1], 
				      private.opts.canvassize[2]);
	gui.pgp := gui.disp.getpgplotter();
	gui.plotter := gpfplotter(private.gpf, private.opts.plotopts);

	# now tell the plotter what plots are selected
	local state;
	for (axn in field_names(gui.axbut)) {
	    if (is_boolean(gui.axbut[axn])) continue;
	    gui.plotter.selectall(axn, F, who='gpfgui');
	    state := gui.axbut[axn].getstate();
	    axdecor := private.gpf.axisdecoration(axn);
	    gui.plotter.select(axn, T, axdecor.values[state], 
			       who='gpfgui');
	}

	gui.disp.setcallback('key', private.handlekey);
	gui.disp.setcallback('button1', private.handlebuttonpress);
	gui.disp.setcallback('button2', private.handlebuttonpress);
	gui.disp.setcallback('button3', private.handlebuttonpress);
	gui.disp.setcallback('buttonup', private.handlebuttonpress);
	gui.disp.setcallback('motion', private.handlemousemove);

	gui.plotter.addlistener(private.plotterupdated, who='gpfgui');
	private.gpf.addlistener(private.fitterupdated, who='gpfgui');

	private.redraw();
	return T;
    }

    #@
    # handle a button press event
    ##
    private.handlebuttonpress := function(rec) {
	wider gui, private;
	local type := rec.type;
	local button := rec.code;

	if((button <= 0) || (button > 3)) {
	    note(paste('buttonHandler: bad code (expected 1..3) ', rec),
		 origin='gainpolyfittergui', priority='WARN');
	    return F;
	}

	if(type == 'ButtonPress') {
	    val gui.buttonPressed[button] := T;
							    
	    if(button == 1)
		private.displayPosition(rec);
	    else if(button == 3) 
		gui.msg.append(rec.device);
	}
	else if(type == 'ButtonRelease') {
	    val gui.buttonPressed[button] := F;
	}

	return T;
    }

    #@
    # handle mouse movement
    ##
    private.handlemousemove := function(rec) {
	wider gui, private;

	# Try to minimize running the handler when already processing
	# an event. If we're called while busy, remember the most recent
	# event and handle it when current is done.
	if(gui.mouseBusy) {
	    gui.pendingMouse := rec;
	    return T;
	}
	gui.mouseBusy := T;

	if (gui.buttonPressed[1]) private.displayPosition(rec);

	while (is_record(gui.pendingMouse)) {
	    private.displayPosition(gui.pendingMouse);
	    gui.pendingMouse := F;
	}

	gui.mouseBusy := F;
	return T;
    }

    #@
    # display the cursor position in the message window
    ##
    private.displayPosition := function(rec) {
	wider gui;
	if (is_boolean(rec)) return F;
	local where := gui.plotter.inputtoworld(gui.pgp, rec, full=T);
	if (is_boolean(where)) return F;
	local which := where.title;

	if (where.insidebox && has_field(where,'nearest')) {
	    local str;
	    local pos := as_string(where.world);
	    dq.setformat('long', 'hms');
	    str := spaste(pos[1], 's');
	    str := paste(dq.form.long(dq.quantity(str)), pos[2]);
	    pos := as_string(where.nearest);
	    str := paste(str, '  Nearest gain:', 
			 dq.form.long(dq.quantity(spaste(pos[1],'s'))), pos[2]);

	    if (is_string(which)) str := spaste(which, ' ', str);

	    if (! where.insidebox) str := spaste('(', str, ')');

	    gui.msg.append(str);
	}
	return T;
    }

    #@
    # handle a key press
    ##
    private.handlekey := function(rec) {
	wider gui;

	# lock out key strokes if we're busy
	if (gui.busy) return F;

	local action := F;
	if (has_field(gui.keyfuncs, rec.key)) 
	    action := gui.keyfuncs[rec.key];
	else if (has_field(gui.keyfuncs, rec.sym)) 
	    action := gui.keyfuncs[rec.sym];
	if (is_boolean(action)) return T;

	# Convert raw position information to world coords. (& other data)
	# This call also displays the position in the message window.
	local info := gui.plotter.inputtoworld(gui.pgp, rec, full=T);
	if (is_boolean(info)) return F;

	if (! has_field(gui.actmap, action)) {
	    note(paste('No binding defined for action', action),
		 priority='WARN', origin='gainpolyfittergui');
	    return F;
	}
	local ok := gui.actmap[action](action, info);
	if (is_fail(ok)) {
	    note(action, ' failed: ', ok::message, priority='WARN',
		 origin='gainpolyfittergui');
	    return F;
	}
	return ok
    }

    #@
    # handle a fit request
    ##
    private.handleFitOrder := function(action, info) {
	wider private;
	if (action !~ m/^fit\d$/ || ! info.insidebox) return T;

	action =~ s/^fit//;
	local order := 0;
	if (action ~ m/^\d+$/) order := as_integer(action);

	local fitidx := gui.plotter.paneltofitindex(info.panel[1], 
						    info.panel[2]);

	local intv := private.gpf.getinterval(info.world[1], fitidx);
	private.gpf.setorder(order, fitidx, info.isampreal, 
			     interval=intv, refit=T, who='gpfgui');

	return gui.plotter.redrawpanel(gui.pgp, info.panel[1], info.panel[2]);
    }

    #@
    # handle add breakpoint request
    ##
    private.handleAddBreak := function(action, info) {
	local ok := T;
	if (! info.insidebox) return T;
	local ypans := as_integer([]);
	local i, fit;

	if (action == 'addbreakpair') {
	    fit := gui.plotter.paneltofit(info.panel[1], info.panel[2]);
	    local other := gui.plotter.fittopanel(fit.fit, 
						  fit.comp==GPF_COMPVALUES[1]);
	    ypans := info.panel[2];
	    if (! is_fail(other)) ypans[2] := other[2];
	}
	else if (action == 'addbreakcol') {
	    local layout := gui.plotter.getlayout();
	    if (layout.nxy[2] > 0) ypans := [1:layout.nxy[2]];
	}

	local fits := [=];
	for (i in ypans) {
	    fit := gui.plotter.paneltofit(info.panel[1], i);

	    if (private.uniquefitidx(fits, fit.fit)) {
		ok := private.gpf.addbreakpoint(info.world[1], fit.fit,
						refit=T, who='gpfgui');
		if (is_fail(ok)) 
		    note('trouble adding breakpoint interactively for panel ',
			 [info.panel[1], i], ': ', ok::message,
			 priority='WARN', origin='gainpolyfittergui');
	    }	    

	    ok := gui.plotter.redrawpanel(gui.pgp, info.panel[1], i);
	    if (is_fail(ok)) 
		note('trouble redrawing panel ', [info.panel[1], i], ': ', 
		     ok::message, priority='WARN', origin='gainpolyfittergui');
	}

	return T;
    }

    #@
    # handle add breakpoint request
    ##
    private.handleDeleteBreak := function(action, info) {
	local ok := T;
	if (! info.insidebox) return T;
	local ypans := as_integer([]);
	local i, fit;

	if (action == 'delbreakpair') {
	    fit := gui.plotter.paneltofit(info.panel[1], info.panel[2]);
	    local other := gui.plotter.fittopanel(fit.fit, 
						  fit.comp==GPF_COMPVALUES[1]);
	    ypans := info.panel[2];
	    if (! is_fail(other)) ypans[2] := other[2];
	}
	else if (action == 'delbreakcol') {
	    local layout := gui.plotter.getlayout();
	    if (layout.nxy[2] > 0) ypans := [1:layout.nxy[2]];
	}

	local fits := [=];
	local bp, nbp, x, win, vppix, fivepix;
	for (i in ypans) {
	    fit := gui.plotter.paneltofit(info.panel[1], i);

	    if (private.uniquefitidx(fits, fit.fit)) {
		bp := private.gpf.getbreakpoints(fit.fit);
		if (len(bp) == 0) next;
		nbp := gpfnearestindex(info.world[1], bp);

		# make sure we've hit within 5 pixels of the breakpoint.
		gui.plotter.setpanelvp(gui.pgp, info.panel[1], info.panel[2]);
		win := gui.pgp.qwin();
		vppix := gui.pgp.qvp(3);
		local fivepix := 5 * (win[2] - win[1]) / (vppix[2] - vppix[1]);
		if (abs(bp[nbp]-info.world[1]) > abs(fivepix)) next;

		# determine value to send to gpf.deleteinterval.
		if (nbp == 1) {
		    x := private.gpf.getdomain();
		    if (bp[nbp] < x[1])
			x := bp[nbp] - (x[2]-x[1])/20.0;
		    else 
			x := (x[1]+bp[nbp])/2.0;
		}
		else {
		    x := (bp[nbp]+bp[nbp-1])/2.0;
		}

		ok := private.gpf.deleteinterval(x, fit.fit, refit=T, 
						 who='gpfgui');
		if (is_fail(ok)) 
		    note('trouble deleting breakpoint interactively for panel ',
			 [info.panel[1], i], ': ', ok::message,
			 priority='WARN', origin='gainpolyfittergui');
	    }

	    ok := gui.plotter.redrawpanel(gui.pgp, info.panel[1], i);
	    if (is_fail(ok)) 
		note('trouble redrawing panel ', [info.panel[1], i], ': ', 
		     ok::message, priority='WARN', origin='gainpolyfittergui');
	}

	return T;
    }

    private.uniquefitidx := function(ref fitlist, fit) {
	local i;
	local found := F;
	local n := len(fitlist);
	if (n > 0) {
	  for (i in [1:n]) {
	    if (all(fitlist[i] == fit)) {
		found := T;
		break;
	    }
	  }
        }
	if (!found) fitlist[len(fitlist)+1] := fit;
	return !found;
    }

    #@ 
    # handle a flag/unflag request
    ##
    private.handleFlag := function(action, info) {
	wider private, gui;
	local ok := T;
	if (! info.insidebox) return T;
	local ypans := as_integer([]);
	local i, fit;

	local tf := F;
	if (action ~ m/^un/) tf := T;

	# determine whether selection was close enough.  If the nearest data
	# point is within 5 pixels, we'll call it a hit.
	# 
	# setpanelvp() call should not be needed
#       gui.plotter.setpanelvp(gui.pgp, info.panel[1], info.panel[2])	
	local win := gui.pgp.qwin();
	local vppix := gui.pgp.qvp(3);
	local tmp := 5 * (win[2] - win[1]) / (vppix[2] - vppix[1]);
	if (abs(info.nearest[1]-info.world[1]) > abs(tmp)) return T;
	tmp := 5 * (win[4] - win[3]) / (vppix[4] - vppix[3]);
	if (abs(info.nearest[2]-info.world[2]) > abs(tmp)) return T;

	fit := gui.plotter.paneltofit(info.panel[1], info.panel[2]);
	local data := private.gpf.getdata(fit.fit);
	local which := ind(data.x)[data.x == info.nearest[1]];
	if (len(which) == 0) fail 'handleFlag: programmer error!';

	if (action ~ m/flaggain$/) {
	    print '###DBG: fit:', fit;
	    local other := gui.plotter.fittopanel(fit.fit, 
						  fit.comp==GPF_COMPVALUES[1]);
	    ypans := info.panel[2];
	    if (! is_fail(other)) ypans[2] := other[2];
	    print '###DBG: panels to redraw:', ypans;
	}
	if (action ~ m/flagcol$/) {
	    local layout := gui.plotter.getlayout();
	    if (layout.nxy[2] > 0) ypans := [1:layout.nxy[2]];
	} 
	    
	local fits := [=];
	for (i in ypans) {
	    fit := gui.plotter.paneltofit(info.panel[1], i);

	    if (private.uniquefitidx(fits, fit.fit)) {
		ok := private.gpf.setmask(which, fit.fit, tf, refit=T,
					  who='gpfgui');
		if (is_fail(ok)) 
		    note('trouble adjusting mask interactively for panel ',
			 [info.panel[1], i], ':', ok::message,
			 priority='WARN', origin='gainpolyfittergui');
	    }	    

	    print '###DBG: redrawing', [info.panel[1], i];
	    ok := gui.plotter.redrawpanel(gui.pgp, info.panel[1], i);
	    if (is_fail(ok)) 
		note('trouble redrawing panel ', [info.panel[1], i], ': ', 
		     ok::message, priority='WARN', origin='gainpolyfittergui');
	}

	return T;
    }

    #@
    # handle a scroll request
    ##
    private.handleWinScroll := function(action, info) {
	wider private, gui;
	local step := 1;

	if (action ~ m/^page/) {
	    # Step size is <viewable window width>/<canvas width>
#	    step := gui.disp.getviewsize()[1] / gui.disp.getplotsize()[1];
	    local layout := gui.plotter.getlayout();
	    step := gui.plotter.getoption('nxyplots')[1] / layout.nxy[1];
	}
	else if (action ~  m/^plot/ || action ~ m/^scroll/) {
	    local layout := gui.plotter.getlayout();
	    if (layout.nxy[1] == 0) return T;
	    step := layout.pansz[1];
	}
	else if (action !~ m/^end/) {
	    return F;
	}

	local cp := gui.disp.getscrollpos()[1];
	local value;
	if(action == 'pageright') 
	    value := cp + step;
	else if(action == 'pageleft') 
	    value := cp - step;
	else if(action == 'endleft')
	    value := 0.0;
	else if(action == 'endright')
	    value := 1.0;
	else if(action == 'plotleft')
	    value := cp - step;
	else if(action == 'plotright')
	    value := cp + step;
	else if(action == 'scrollleft')
	    value := cp - .1*step;
	else if(action == 'scrollright')
	    value := cp + .1*step;

	if(value < 0.0)
	    value := 0.0;
	else if(value > 1.0)
	    value := 1.0;

	gui.disp.viewx(value);
	return T;
    }

    #@
    # handle a zoom request
    ##
    private.handleZoom := function(action, info) {
	wider gui;
	local current := gui.zoomed;

	if (! has_field(gui.zoomed, 'doampreal') && action ~ m/plot$/) {
	    # zoom in on one component
	    gui.zoomed := [=];
	    if (has_field(current, 'unzpos')) {
		gui.zoomed.unzpos := current.unzpos;
	    } else {
		gui.zoomed.unzpos := gui.disp.getscrollpos();
	    }
	    gui.zoomed.fitindex := info.fitindex;
	    gui.zoomed.title := info.title;
	    gui.zoomed.doampreal := info.isampreal;
	}
	else if (! has_field(gui.zoomed, 'phtitle') && action ~ m/pair$/) {
	    # zoom in on a fit pair
	    gui.zoomed := [=];
	    if (has_field(current, 'unzpos')) {
		gui.zoomed.unzpos := current.unzpos;
	    } else {
		gui.zoomed.unzpos := gui.disp.getscrollpos();
	    }
	    gui.zoomed.fitindex := info.fitindex;
	    if (info.isampreal) {
		gui.zoomed.amptitle := info.title;
		gui.zoomed.phtitle := 
		    gui.plotter.createtitleforfit(info.fitindex, F);
	    } else {
		gui.zoomed.phtitle := info.title;
		gui.zoomed.amptitle := 
		    gui.plotter.createtitleforfit(info.fitindex, T);
	    }
	}
	else {
	    # unzoom
	    gui.zoomed := [=];
	    if (has_field(current, 'unzpos')) 
		gui.zoomed.scrpos := current.unzpos;
	}

	private.redraw();
	return T;
    }

    #@
    # handle a redraw request
    private.handleRedraw := function(action, info) {
	wider private;
	return private.redraw();
    }

    #@
    # return a guiframework menu
    private.menus := function() {
	wider private;
	local out := [=];
	out.file := private.filemenu();
	out.options := private.optionsmenu();
	out.display := private.displaymenu();
	return ref out;
    }

    private.filemenu := function() {
	wider private, public;
	local file := [=];
	file::text := 'File';

	file.save := [=];
	file.save.text := 'Save...';
	file.save.relief := 'flat';
	file.save.action := function() {
	    wider private;
	    private.gpf.save();
	}

	file.evaluate := [=];
	file.evaluate.text := 'Evaluate...';
	file.evaluate.relief := 'flat';
	file.evaluate.action := function() {
	    wider private;
	    print "Evaluate...TBI";
	}

	file.browsein := [=];
	file.browsein.text := 'Browse Gains...';
	file.browsein.relief := 'flat';
	file.browsein.action := function() {
	    wider private;
	    return private.browse(private.gpf.gaintable());
	}

	file.print := [=];
	file.print.text := 'Print...';
	file.print.relief := 'flat';
	file.print.action := function() {
	    wider private;

	    return T;
	}

	file.script := [=];
	file.script.text := 'Create Script';
	file.script.relief := 'flat';
	file.script.action := function() {
	    wider private;
	    local fn := spaste(private.gpf.gaintable(), '_gpf.g');
	    print "Script Creation ... TBI";
	    return F;
	}

#  	file.blank := [=];
#  	file.blank.text := '';
#  	file.blank.relief :='flat';
#  	file.blank.disable :=T;

#  	file.bug := [=];
#  	file.bug.text :='Report Bug...';
#  	file.bug.relief :='flat';
#  	file.bug.action := function() {
#  	    include 'bug.g';
#  	    bug();
#  	} 
	
#  	file.blank1 := [=];
#  	file.blank1.text := '';
#  	file.blank1.relief :='flat';
#  	file.blank1.disable :=T;
	
	file.dismiss := [=];
	file.dismiss.text := 'Dismiss';
	file.dismiss.relief := 'flat';
	file.dismiss.action := public.done;
	file.dismiss.background := 'orange';

	file.done := [=];
	file.done.text := 'Done';
	file.done.relief := 'flat';
	file.done.action := function() {
	    wider private, public;
	    private.gpf.removelistener('gpfgui');
	    private.gpf.done();
	    public.done();
	}
	file.done.background := 'red';

	return ref file;
    }

    private.optionsmenu := function() {
	wider private;
	global CURSORS, PGCURSORS;
	local options := [=];
	options::text := 'Options';

	# Auto fit
	options.autofit::text := 'Auto Fit';
	options.autofit.text := 'Auto Fit';
	options.autofit.type := 'check';
	options.autofit.relief := 'flat';
	options.autofit.state := private.gpf.getoption('autofit');
	options.autofit.action := function(rec) {
	    wider private;
	    private.gpf.setoption('autofit', rec.state, who='gpfgui');
	    if (rec.state) return private.redraw();
	    return T;
	}
	options.autofit.actionstate := T;

	# Miriad Mode
	private.state.mirmode := F;
	options.mirmode::text := 'Miriad Mode';
	options.mirmode.text :=  'Miriad Mode';
	options.mirmode.type := 'check';
	options.mirmode.relief := 'flat';
	options.mirmode.state := private.state.mirmode;
	options.mirmode.actionstate := T;
	options.mirmode.action := function(rec) {
	    wider private;
	    print '###DBG: togglemirmode:', rec;
#	    private.togglemirmode();
	    return T;
	}

	# extrapolation
	options.extrapolate.text := 'Extrapolate fits';
	options.extrapolate::text := options.extrapolate.text;
	options.extrapolate.type := 'check';
	options.extrapolate.relief := 'flat';
	options.extrapolate.state := private.gpf.getoption('extrapolate');
	options.extrapolate.action := function(rec) {
	    private.gpf.setoption('extrapolate', rec.state, who='gpfgui');
	    return private.redraw();
	}
	options.extrapolate.actionstate := T;

	options.cursor := private.cursors('Frame cursor', 'cursor', CURSORS);
	options.pgcursor := private.cursors('Plot cursor', 'pgcursor',
					    PGCURSORS);

	return ref options;
    }

    private.displaymenu := function() {
	wider private, gui;

	local display := [=];
	display::text := 'Display';
	display.plotsperview := [=];
	display.plotsperview.menu := [=];
	display.plotsperview.text := 'Plots per view';
	display.plotsperview::text := display.plotsperview.text;
	display.plotsperview.type := 'menu';
	display.plotsperview.relief := 'flat';
  	display.plotsperview.menu.horizontally := 
	    private.scalebuts("Horizontally", T, [1:8]);
  	display.plotsperview.menu.vertically := 
	    private.scalebuts("Vertically", F, [1:8]);

	display.errorbarscale := [=];
	display.errorbarscale.text := 'Errorbar Scale';
	display.errorbarscale::text := display.errorbarscale.text;
	display.errorbarscale.type := 'menu';
	display.errorbarscale.relief := 'flat';
	display.errorbarscale.menu := [=];

	local tval;
	local init := private.opts.plotopts.errorbarscale; 
	for (i in [0:5]) {
	    tval := as_string(i);
	    display.errorbarscale.menu[tval] := 
		[text=tval, type='radio', relief='flat', state=F];
	    if (i == init) display.errorbarscale.menu[tval].state := T;

	    display.errorbarscale.menu[tval].action := function(v) {
		wider private;
		gui.plotter.setoption('errorbarscale', v, who='gpfgui');
		return private.redraw();
	    }
	    display.errorbarscale.menu[tval].actionarg := i;
	}
	display.errorbarscale.menu['0'].text := '0 (no bars)';

	display.showfit := [text='Show Fitted Curves', type='check', 
			    relief='raised', 
			    state=private.opts.plotopts.showfit];
	display.showfit::text := display.showfit.text;
	display.showfit.action := function(rec) {
	    wider private;
	    gui.plotter.setoption('showfit', rec.state, who='gpfgui');
	    return private.redraw();
	}
	display.showfit.actionstate := T;

	display.showyzero := [text='Show Y=0 axis', type='check', 
			      relief='raised', 
			      state=private.opts.plotopts.showzero];
	display.showyzero::text := display.showyzero.text;
	display.showyzero.action := function(rec) {
	    wider private;
	    gui.plotter.setoption('showzero', rec.state, who='gpfgui');
	    return private.redraw();
	}
	display.showyzero.actionstate := T;

	display.clipmasked := [text='Clip Flagged Gains', type='check', 
			       relief='raised', 
			       state=private.opts.plotopts.clipmasked];
	display.clipmasked::text := display.clipmasked.text;
	display.clipmasked.action := function(rec) {
	    wider private;
	    gui.plotter.setoption('clipmasked', rec.state, who='gpfgui');
	    return private.redraw();
	}
	display.clipmasked.actionstate := T;

	display.clipfit := [text='Clip Fitted Curves', type='check', 
			    relief='raised', 
			    state=private.opts.plotopts.clipfit];
	display.clipfit::text := display.clipfit.text;
	display.clipfit.action := function(rec) {
	    wider private;
	    gui.plotter.setoption('clipfit', rec.state, who='gpfgui');
	    return private.redraw();
	}
	display.clipfit.actionstate := T;

	return display;
    }

    # create a sub-menu for plots-per-view
    private.scalebuts := function(label, isx, values) {
	wider private, gui;
	local value, tval;
	local btns := [text=label, type='menu', menu=[=]];
	local i := 2;
	if (isx) i := 1;
	local init := private.opts.nxyplots;

	for (value in values) {
	    tval := as_string(value);
	    btns.menu[tval] := [text=tval, type='radio', value=value, 
				relief='flat', state=F];
	    if (value == init[i]) btns.menu[tval].state := T;

	    btns.menu[tval].action := function(v) {
		wider private;
		local nxy := gui.plotter.getoption('nxyplots');
		nxy[i] := v;
		gui.plotter.setoption('nxyplots', nxy, who='gpfgui');
		return private.redraw();
	    }
	    btns.menu[tval].actionarg := value;
	}
		
	return btns;
    }

    # Create a sub-menu for a cursor.
    private.cursors := function(label, option, cursors) {
	wider private;
	return private.makeradiobuttons(label, option, cursors);
    }

    # Create a sub-menu for the plot cursor.
    private.plotcursors := function(label, option, cursors) {
	wider private;
	return private.makeradiobuttons(label, option, cursors);
    }

    # Create a submenu of radio buttons.
    # label	- Label for menu.
    # option	- Option name.
    # values	- List of button labels/values.
    # doeval	- If T, values contains strings that need to be evaluted.
    #		  (eg '1/4' rather than 0.25).
   private.makeradiobuttons := function(label, option, values, doeval=F) {
	wider private;
	local btns := [text=label, type='menu', menu=[=]];

	local currentvalue := private.opts[option];

	for(value in values) {
	    btns.menu[as_string(value)] := 
		[text=as_string(value), type='radio', 
		 value=value, relief='flat', option=option, state=F];
		 

	    if (value == currentvalue) btns.menu[as_string(value)].state := T;

	    btns.menu[value].action := function(rec) {
		wider private;
		private.opts[option] := rec.value;
		private.redraw();
	    }
	    btns.menu[value].actionarg := ref btns.menu[value];
	}

	return btns;
    }

    private.helpmenu := function() {
	wider private;
	local hmenu := [=];
	hmenu::text := 'Help';

	return ref hmenu;
    }

    private.browse := function(table) {
	wider private;
	include 'tablebrowser.g';
	local ok := tablebrowser(table);
	if (is_fail(ok)) {
	    note(spaste('Failed to open table browser\n', ok::message),
		 priority="SEVERE", origin="gainpolyfittergui");
	    return F;
	}

	private.browsers[length(private.browsers) + 1] := ok;
	return T;
    }

    private.killbrowsers := function() {
	wider private;
	if (length(private.browsers) < 1) return T;
	for(i in 1:length(private.browsers)) {
	    if (! is_boolean(private.browsers[i])) {
		private.browsers[i]->done();
		private.browsers[i] := F;
	    }
	}
    }

    #@
    # toggle miriad-like key bindings
    ##
    private.togglemirmode := function() {
	wider private;
	private.state.mirmode := ! private.state.mirmode;
	# fix bindings
	return T;
    }

    #@
    # redraw the plot in its current state.  Steps:
    #  1. Avoid being reentrant.
    #  2. Check to see if plot area needs resizing.
    #  3. Scan the buttons to find out how many & which are set.
    #  4. Make the appropriate # of subpanels
    #  5. Redraw each antenna.
    #  6. See if we need to do it again.
    ##
    private.redraw := function() {
	wider gui, private;
	local winmar := rep(0.0, 4);
	winmar[3] := 0.01;

	# Attempt to ensure redraw doesn't get called during a redraw.
	if(gui.busy) {
	    # Remember if another redraw was requested.
	    gui.needRedraw := T;
	    return T;
	}
	gui.busy := T;

	gui.plotter.updatetoselect();
	local nxy := gui.plotter.getselectshape();
	winmar[2] := 0.01*gui.plotter.getoption('nxyplots')[1]/nxy[1];
	if (nxy[1] <= 0 && nxy[2] <= 0) {
	    if (is_boolean(gui.pgp)) gui.pgp.clear();
	    gui.busy := F;
	    private.redrawIfNeeded();
	    return T;
	}
	gui.top->disable();

	local visxy := gui.plotter.getoption('nxyplots');
	if (len(gui.zoomed) > 1) {
	    private.resize(visxy[1], visxy[2]);
	    gui.pgp.page();

	    if (has_field(gui.zoomed, 'doampreal')) {

		# just one gain component
		gui.plotter.plotfitcomp(gui.pgp, gui.zoomed.fitindex, 
					gui.zoomed.doampreal,
					gui.zoomed.title, charht=1.25,
					winmar=winmar);
	    }
	    else {

		# a plot pair
		gui.plotter.plotfitpair(gui.pgp, gui.zoomed.fitindex, 
					amptitle=gui.zoomed.amptitle,
					phtitle=gui.zoomed.phtitle, 
					charht=1.25, winmar=winmar);
	    }
	}
	else {
	    private.resize(nxy[1], nxy[2]);
	    gui.pgp.page();

	    if (has_field(gui.zoomed, 'scrpos')) 
		gui.disp.viewx(gui.zoomed.scrpos[1]);
	    gui.plotter.plotfits(gui.pgp, nxy[1], nxy[2], xlabfreq=visxy[2],
				 winmar=winmar, page=F);
	}

	gui.top->enable();
	gui.busy := F;
	private.redrawIfNeeded();

	return T;
    }

    #@
    # redraw if a redraw event came in while in the middle of a redraw
    ##
    private.redrawIfNeeded := function() {
	wider gui;
	if (gui.needRedraw) {
	    gui.needRedraw := F;
	    print '###DBG: Double redraw';
	    return private.redraw();
	}
	return T;
    }

    #@ 
    # resize if necessary
    ##
    private.resize := function(ncols, nrows) {
	wider private, gui;
	local visxy := gui.plotter.getoption('nxyplots');
	local w := private.opts.canvassize[1] * ncols / visxy[1];
	local h := private.opts.canvassize[2] * nrows / visxy[2];
	if (w <= 1 || h <= 1) return T;  # don't allow 0 size

	# this will resize only if necessary
	local ok := gui.disp.resize(w, h);
	if (is_fail(ok)) {
	    note(paste('resize failure:', ok::message), priority='SEVERE',
		 origin='gainpolyfittergui');
	}
	gui.pgp := gui.disp.getpgplotter();
	return ok;
    }

    #@
    # redraw the plots currently being viewed.
    # @param fitindex   if set, it is only necessary to redraw the panels
    #                      associated with this fit index.
    ##
    public.redraw := function(fitindex=unset) {
	wider private;
	local ok := T;
	if (! is_unset(fitindex)) {
	    wider gui;
	    local pan := gui.plotter.fittopanel(fitindex, F);
	    if (!is_fail(pan)) 
		ok := gui.plotter.redrawpanel(gui.pgp, pan[1], pan[2]);
	    pan := gui.plotter.fittopanel(fitindex, T);
	    if (!is_fail(pan)) 
		ok := gui.plotter.redrawpanel(gui.pgp, pan[1], pan[2]);
	}
	else {
	    ok := private.redraw();
	}

	return ok;
    }

    #@ 
    # delete this widget
    ##
    public.done := function() {
	wider public, gui, private;
	private.killbrowsers();

	gui.framework.done();
	gui.plotter.done();
	if (is_record(private.gpf)) 
	    private.gpf.removelistener('gpfgui');

#	rdelete(gui);
	gui := F;
	val public := F;
	return T;
    }

    private.setkeyfuncs := function() {
	wider private;
	for(i in [0:9]) 
	    private.keyfuncs[as_string(i)] := private.handleFitOrder;

	for (key in "- = _ + , . < > \\ `") 
	    private.keyfuncs[key] := private.handleWinScroll;

	for (key in "z Z") 
	    private.keyfuncs[key] := private.handleZoom;
	return T;
    }

    private.bindkeys := function() {
	wider gui, private;
	local i, f, n;
	local p := ref private;
	gui.actmap := [zoomplot=p.handleZoom, zoompair=p.handleZoom];

	local scrollers := ["scrollleft scrollright plotleft plotright",
			    "pageleft pageright endleft endright"];
	for (n in scrollers) 
	    gui.actmap[n] := p.handleWinScroll;
	for (i in [0:9]) 
	    gui.actmap[spaste('fit', i)] := p.handleFitOrder;
	gui.actmap.addbreakpair := p.handleAddBreak;
	gui.actmap.addbreakcol  := p.handleAddBreak;
	gui.actmap.delbreakpair := p.handleDeleteBreak;
	gui.actmap.delbreakcol  := p.handleDeleteBreak;

	gui.actmap.redraw := p.handleRedraw;
	gui.actmap.redrawall := p.handleRedraw;

	for (f in "flaggain flagcol unflaggain unflagcol") 
	    gui.actmap[f] := p.handleFlag;

	for (f in field_names(gui.actmap)) {
	    for (n in private.opts.keyactions[f]) 
		gui.keyfuncs[n] := f;
	}

	return T;
    }

    #@
    # return the options being used by this tool
    ##
    public.getoptions := function() {
	wider gui;
	return gui.plotter.getoptions();
    }

    #@ 
    # return the value of an option
    # @param name     the option name
    ##
    public.getoption := function(name) { 
	wider gui; 
	return gui.plotter.getoptions(name);
    }

    #@
    # set the value of an option.  Listeners will be notified about change
    # @param name     the option name
    # @param value    the new value to assign
    # @param who      the name of the actor setting this change.  This 
    #                     will be sent to listeners.  The default is an 
    #                     empty string, indicating that the actor is 
    #                     anonymous.
    # @param skipwho  if true (the default), the listener associated
    #                     this name will not be notified.
    ##
    public.setoption := function(name, value, who='', skipwho=T) {
	wider gui;
	local old := gui.plotter.getoption(name);
	if (is_fail(old)) {
	    if (old::message ~ m/unrecognized option/) 
		fail paste('setoption: unrecognized or static option:', name);
	    else 
		return old;
	}
	gui.plotter.setoption(name, value, who=who, skipwho=skipwho);
	return T;
    }

    #@
    # select axis values for display
    # @param axis     the name of the axis.
    # @param state  if true, the values will be turned on.
    # @param values   the values to select
    # @param who      the name of the actor requesting the selection.  This 
    #                     change will be sent to listeners.  The default is an 
    #                     empty string, indicating that the actor is 
    #                     anonymous.
    ##
    public.select := function(axis, state, values, who='') {
	wider gui;
	if (! is_boolean(state)) 
	    fail paste('state parameter not a boolean:', state);
	if (len(values) == 0) return T;
	return gui.plotter.select(axis, state, values, who);
    }

    #@
    # select axis values for display
    # @param axis     the name of the axis.
    # @param state  if true, the values will be turned on.
    # @param who      the name of the actor requesting the selection.  This 
    #                     change will be sent to listeners.  The default is an 
    #                     empty string, indicating that the actor is 
    #                     anonymous.
    ##
    public.selectall := function(axis, state, who='') {
	wider gui, private;
	if (! is_boolean(state)) 
	    fail paste('state parameter not a boolean:', state);
	local values := private.gpf.axisvals(axis);
	if (is_fail(values)) return values;
	return gui.plotter.select(axis, state, values, who);
    }

    ok := private.build(F, ws);
    if (is_fail(ok)) return ok;
    private.bindkeys();

    public.private := ref private;
    public.gui := ref gui;
    return ref public;
}
