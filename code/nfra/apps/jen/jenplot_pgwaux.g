# jenplot_pgwaux.g: auxiliary functions for use of pgplotter widget

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
# $Id: jenplot_pgwaux.g,v 19.0 2003/07/16 03:38:35 aips2adm Exp $

#---------------------------------------------------------

pragma include once
# print 'include jenplot_pgwaux.g  w01sep99';

include 'textformatting.g';
include 'profiler.g';

#==========================================================================
#==========================================================================
#==========================================================================
#==========================================================================
# jenplot_pgwaux is a self-contained object for plotting graphs.
# It could be turned into a stand-alone object as soon as a good name
# is found.


#=====================================================================
#=====================================================================
jenplot_pgwaux := function (ref prof=F) {
    private := [=];
    public := [=];

    private.prof := prof;                       # profiler

# Initialise the object (called at the end of this constructor):

    private.init := function (dummy=F) {
	wider private;
	if (!is_record(private.prof)) {
	    private.prof := profiler('jenplot_pgwaux');
	}
	private.tf := textformatting();
	private.trace := F;			# ....?
	private.guiframe := F;			# ....?
	public.clear();				# item-related
	private.define_plot_colors();
	private.define_plot_styles();
	public.subp();
	return T;
    }

#==========================================================================
# Public interface:
#==========================================================================

    public.agent := create_agent();
    whenever public.agent->* do {
	s := paste('jenplot_pgwaux event: ',$name);
	if (is_record($value)) {
	    s := paste(s,'  value=\n',$value);
	} else {
	    s := paste(s,'  value=',$value);
	}	    
	# print s;
    }
    whenever public.agent->message do {
	s := paste( 'jenplot_pgwaux message-event:',$value);
	# print s;
    }
    whenever public.agent->done do {
	s := paste('jenplot_pgwaux event: done',$value);
	# print s;
    }

    public.clear := function (origin=F, trace=F) {	# clear the workspace
	wider private;
	if (trace) print '\n pgwaux.clear(',origin,'):';
	if (F) {                                        # inhibited
	    if (trace) print '- reset_plot_color()';
	    public.reset_plot_color();		        # reset color counter
	}
	if (trace) print '- clear_clitem()';
	private.clear_clitem();				# 
	if (trace) print '- clear_marker()';
	private.clear_marker();				# 
	if (trace) print '\n';
	return T;
    }

    public.status := function () {
	s := '\nSummary of jenplot_pgwaux status:';
	s := spaste(s,'\n - clitems: n=',len(private.clitem));
	s := spaste(s,'\n - markers: n=',len(private.marker));
	s := spaste(s,'\n - panel:',private.panel);
	return paste(s,'\n');
    }

    public.reset := function (name=F) {
	if (is_boolean(name)) {				# bring into known state
	    private.progress_control('do_abort');	# just in case
	    public.clear('pgwaux.reset');
	} if (name=='color' || name=='colors') {
	    return public.reset_plot_color();		# automatic index
	} else {
	    print 'pgw.reset(): not recognised:',name;
	    return F;
	}
    }

# Print a hardcopy of the current plot.
# Future: collect a mosaic of plots and print them together with psmulti? 

    public.print := function (dummy=F, remove=F) {
	wider private;
	if (!private.check_pgw('pgwaux.print')) return F;

	# Rotate over a limited number (5) of intermediate files:
	if (!has_field(private,'printindex')) private.printindex := -1;
	private.printindex +:= 1;                       # increment
	i := private.printindex % 7;                    # 8 files....
	psfile := spaste('/tmp/jenplot_',i,'.ps');      # ps file-name

	r := shell(s:=paste('rm -f',psfile));	# remove any existing 
	s := paste(s,'->',r);
	delay_sec := 1.0;
	print s := paste(s,'(delay by:',delay_sec,'sec)');
	public.message(s);
	public.delay(delay_sec);                        # sec (needed..?) 

	# NB: The pgplotter needs a few seconds to write the file.
        #     especially if its a large one (e.g. mosaick).
        #     Without some delay, it is not printed properly. 
	r := private.pgw.postscript(file=psfile, color=T, landscape=T);
	s := paste('written to ps file:',psfile,' -> ',r);
	delay_sec := 5.0;                               # sufficient?
	print s := paste(s,'(delay by:',delay_sec,'sec)');
	public.message(s);
	public.delay(delay_sec);                        # sec (needed!) 

	# NB: If more than 8 ps-files are written in quick succession,
        #     some might be removed before having been printed...?
        #     That is why a small extra delay has been built in....
	r := shell(s:=paste('pri',psfile));		# print file ...
	# r := shell(s:=paste('lpr',psfile));		# print file ...
	# r := shell(s:=paste('lpr -s',psfile));	# print file ...
	s := paste(s,'->',r);
	delay_sec := 1.0;                               # necessary?
	print s := paste(s,'(delay by:',delay_sec,'sec)');
	public.message(s);
	public.delay(delay_sec);                        # sec (needed..?) 

	# Obsolete option?
	if (remove) {                                   # clean up
	    public.delay(2.0);                          # sec (needed..?) 
	    r := shell(s:=paste('rm',psfile));	        # remove file
	    print s,'->',r;
	}
	return T;
    }


# Inspection:

    public.private := function(copy=F) {	# access to private part
	if (copy) return private;		# return a copy
	return ref private;			# return a reference
    }
    public.show := function (dummy=F) {		# print summary of private
	# return private.show();
    }
    public.inspect := function (name=F) {	# Inspect various things
	include 'inspect.g';
	inspect(public,'pgwaux');
	inspect(private,'pgwaux.private');
	# return private.inspect(name);
    }

    public.message := function (txt='***') {
	if (!private.check_pgw('pgwaux.message')) return F;
	private.pgw.message(txt);		# to pgplot widget
	return F;
    }

# Finished:

    public.done := function (dummy=F, notify=T, trace=F) {
	wider private;
	if (!private.check_pgw('pgwaux.done')) return F;
	if (trace) print 'done(): private.pgw.clear()';
	private.pgw.clear();
	if (trace) print 'done(): private.pgw.done()';
	private.pgw.done();
	if (trace) print 'done(): val private.pgw := F';
	val private.pgw := F;				# .....?
	private.has_pgw := F;				# indicator (safety)
	if (trace) print 'done(): val private.guiframe := F';
	if (notify) public.agent -> done();		# outside world...
	val private.guiframe := F;
	return T;
    }

#========================================================================
# General functions:
#========================================================================


# Helper function: delay for given nr of seconds: 

    public.delay := function(sec=0.1, txt=' ', trace=F) {
	wider private;
	if (!has_field(private,'echo')) private.echo := client ('echo_client');
	if (!has_field(private,'timer')) private.timer := client ('timer');

	if (trace) print txt,': start delay: sec=',sec;
	private.echo -> echo();				# allow events
	if (trace) print txt,': delay: await echo....';
	await private.echo -> echo;			# wait
	private.timer -> interval(sec);
	if (trace) print txt,':delay: await timer....';
	await private.timer -> ready;
	private.timer -> interval(0);			# disable timer
	if (trace) print txt,': delay: finished';
	return T;
    }



#============================================================================
# Functions dealing with the pgplotter widget attched to private.pgw: 
#============================================================================

# Return a reference to the attached pg-plotter. This makes it possible to
# issue straight pgplot commands: pga.pgw().xxx() etc

    public.pgw := function (ref pgw=F) {
	if (!private.check_pgw('pgwaux.pgw')) return F;
	return ref private.pgw;			# reference to pgplot widget
    }

# Attach a pgplotter widget to private.pgw, and set the default callback functions:

    public.attach_pgw := function (ref pgw=F, trace=F, title='jenplot_pgwaux') {
	wider private;
	if (trace) s := spaste('pgwaux.attach_pgw(pgw=',type_name(pgw),'):');
	if (!has_field(private,'has_pgw')) private.has_pgw := F;

	if (is_boolean(pgw)) {			# attach local pgplotter widget
	    if (trace) print s, 'make and attach local private.pgw';
	    return public.gui(title=title);	# make a default gui

	} else if (is_record(pgw)) {
	    private.pgw := pgw;			# attach given pgplotter widget
	    private.has_pgw := T;		# indicator
	    if (trace) print s, 'attach given pgw';
	    public.env(clear=T);
	    public.setcallback('default');

	} else {
	    print s,'not recognised',pgw; 
	    private.has_pgw := F;		# indicator
	    return F;
	}
	return T;
    }

# Check whether a pg-plotter has been attached. If not: attach one.

    private.check_pgw := function(origin=F, trace=F) {
	wider private;
	if (trace) s := paste('pgwaux: check_pgw (',origin,'):');
	if (!has_field(private,'has_pgw')) private.has_pgw := F;
	if (!private.has_pgw) {	
	    if (trace) print s, 'no pgplot widget attached (yet)';
	    return F;
	} else {
	   if (trace) print s,'private.pgw already exists';
	}
	return T;
    }

#-----------------------------------------------------------------------
# Make the gui with the (local) pgplotter:
#-----------------------------------------------------------------------

    public.gui := function (title='jenplot_pgwaux', trace=F) {
	wider private;

	if (!has_field(private,'guiframe')) {
	    private.guiframe := F;
	} else if (is_agent(private.guiframe)) {
	    s:= paste('pgwaux.gui(): already exists');
	    if (trace) print s;
	    return T;
	}

	tk_hold();
	private.guiframe := frame(title=title, side='top');
	whenever private.guiframe -> resize do {
	    private.callback_resize();
	}
	whenever private.guiframe -> killed do {
	    print s := 'pgwaux: guiframe killed event';
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
	private.has_pgw := T;					# indicator
	public.env();
	public.setcallback('default');

	# bottom-frame: dismiss and label
	private.gui_label := label(private.bottomframe, width=75,
				   background='white',
				   fill='x');
	private.gui_label -> text('gui_label');
	dummy2 := frame(private.bottomframe, height=1);		# padding
	private.button_dismiss := button(private.bottomframe,'dismiss',
	 				 background='orange');
	whenever private.button_dismiss->press do {
	    public.done();
	}

	tk_release();
	return T;
    }

# Default resize function:

    private.callback_resize := function (dummy=F, trace=F) {
	wider private;
	if (!has_field(private,'resize_counter')) {
	    # NB: The first plot pruduces a flurry of 2-6 (?) resize events.
	    private.resize_counter := 2;		# .....?
	}
	if (is_record(private.pgw)) {
	    private.resize_counter -:= 1;		# decrement
	    s := spaste('.....',private.resize_counter,': resize event');
	    s := paste(s,'size=',private.pgw.size(),'(?)'); 
	    s := paste(s,'enable=',private.resize_enable);
	    if (trace) print s;
	    if (private.resize_counter<=0) {	# ignore initial flurry
		if (trace) print 'callback_resize: public.env(resize=T):';
		r := public.env(resize=T, trace=trace);
		if (is_fail(r)) print r;
		if (trace) print 'callback_resize: public.draw_clitems():';
		r := public.draw_clitems(trace=trace);
		if (is_fail(r)) print r;
		if (trace) print 'callback_resize: public.draw_markers():';
		r := public.draw_markers(trace=trace);
		if (is_fail(r)) print r;
	    }
	    public.message(s);
	}
	return T;
    }


#===========================================================================
# Functions dealing with call-back functions:
#===========================================================================


    public.setcallback := function (action=F, region=F, button=F, 
				    ref callback=F, trace=F) {
	wider private;
	s := paste('pgwaux.setcallback:',action,region,button,type_name(callback),':');
	if (trace) print s;
	if (!has_field(private,'callback')) private.callback := [=];
	if (!private.check_pgw('pgwaux.setcallback')) return F;

	# Check button argument:
	if (is_boolean(button)) {			# not defined
	    button := [1:3];				# all three
	} else if (is_string(button)) {	
	    if (button=='left') button := 1;
	    if (button=='middle') button := 2;		# ...?
	    if (button=='right') button := 3;		# ...?
	    if (is_string(button)) button := [1:3];	# all three?
	} 
	button := button[[button>0] & [button<=3]];

	if (is_boolean(callback)) {			# Some default functions
	    if (action=='default') action := "button buttonup motion key";
	    for (act in action) {
		if (act=='button') {
		    private.pgw.setcallback('button', ref private.mouse_down);
		} else if (act=='buttonup') {
		    private.pgw.setcallback('buttonup', ref private.mouse_up);
		} else if (act=='motion') {
		    private.pgw.setcallback('motion', ref private.mousemotion);
		} else if (act=='key') {
		    private.pgw.setcallback('key', ref private.keypress);
		} else {
		    print s,'not recognised:',act;
		    next;
		}
		if (trace) print s,act;
	    }

	} else if (!is_function(callback)) {		# should be function!
	    print s,'callback function not recognised:',type_name(callback);
	    return F;

	} else if (is_string(region)) {			# region specified
	    if (!has_field(private.callback,region)) {
		private.callback[region] := [=];
		for (butt in [1:3]) private.callback[region][butt] := [=];
	    }
	    for (butt in button) {			# may be vector
		n := 1 + len(private.callback[region][butt]);
		private.callback[region][butt][n] := callback;
		s1 := spaste('private.callback.',region,'.[',butt,'][',n,']');
		if (trace) print s,' -> ',s1;
	    }

	} else {					# ......?
	    private.pgw.setcallback(action, callback);
	    if (trace) print s,action,': -> pgw.setcallback: function provided';
	}
	return T;
    }

# Helper function to set/request mouse status:

    public.mouse_status := function (down=F, trace=F) {
	wider private;
	if (!has_field(private,'mouse_status')) {
	    private.mouse_status := [=];
	    private.mouse_status.down := [];
	}
	if (is_integer(down)) private.mouse_status.down := down;
	if (trace) print 'mouse_status:',private.mouse_status;
	return private.mouse_status;
    }

# General action upon mouse-down:

    private.mouse_down := function (rec, trace=F) {
	wider private;
	if (!has_field(rec,'button')) rec.button := rec.code;
	x := rec.world[1];				# from pgplotter
	y := rec.world[2];				# from pgplotter
	button := rec.button;				# from pgplotter
	public.mouse_status(down=button, trace=F);

	qwin := public.qwin();			        # get window range
	if (private.switch_panel(rec)) {                # to other panel
	    return T;
	} else if (qwin.xdir*x < qwin.xdir*qwin.xblc) {	# in left margin
	    region := 'left_margin';
	    if (private.clicked_wedge(rec)) return T;
	} else if (qwin.xdir*x > qwin.xdir*qwin.xtrc) {	# in right margin
	    region := 'right_margin';
	} else if (qwin.ydir*y < qwin.ydir*qwin.yblc) {	# in bottom margin
	    region := 'bottom_margin';
	} else if (qwin.ydir*y > qwin.ydir*qwin.ytrc) {	# in top margin
	    region := 'top_margin';
	} else {					# inside window
	    region := 'plot_window';
	}
	s := spaste('\n ppwaux.mouse_down(): clicked in region: ');
	s := spaste(s,region,'  button=',button);
	if (trace) print s; 
	public.message(s);

	# Append information about the current panel to rec:
	rec.icol := private.panel.icol;
	rec.irow := private.panel.irow;
	    
	# Check whether a clicakble item has been clicked on:
	if (private.clicked_clitem(rec, region=region)) return T;

	# Then execute any other specified callback functions.
	# NB: They are executed in the order in which they have
	# been specified with .setcallback(), and if one of them
	# returns a T status, the later ones will be ignored.
	if (has_field(private.callback,region)) {
	    ii := ind(private.callback[region][button]);
	    if (trace) print 'region=',region,button,'ii=',ii;
	    for (i in ii) {
		s := spaste('private.callback.');
		s := spaste(s,region,'[',button,'][',i,'](rec)');
		if (trace) print 'mouse_down: execute',s;
		r := private.callback[region][button][i](rec); 
		if (trace || is_fail(r)) print 'mouse_down:',s,'->',r;
		if (r) {
		    if (trace) print 'r=T: succes -> escape';
		    return T;			# exit if T!
		}
	    }
	}
	if (trace) print 'no succes with private.callback functions';

	# If required (and if we get to here) start a boxcursor:
	if (region=='plot_window') {
	    if (trace) print 'mouse_down: markerinput_start(rec):';
	    private.markerinput_start(rec);
	    if (trace) print 'mouse_down: boxcursor_start(rec):';
	    private.boxcursor_start(rec);		# start viewing box
	}
	return T;
    }

    private.mouse_up := function (rec, trace=F) {
	wider private;
	# if (!private.check_pgw('pgwaux.mouse_up')) return F;
	if (!has_field(rec,'button')) rec.button := rec.code;
	bc := private.boxcursor_stop(rec);             # handle if active
	private.markerinput_stop(rec);                 # handle if active
	if (rec.button==1) {                           # left button
	} else if (rec.button==2) {                    # 'middle' button (?)
	} else if (rec.button==3) {                    # 'right' button (?)
	} else {
	    public.message(paste(rec));  	       # ....?
	}
	public.mouse_status(down=[], trace=F);     # all up
	return T;
    }

    private.mousemotion := function (rec) {
	wider private;
	s := paste(rec);
	private.gui_label -> text(s);			# in bottom label
	return T;
    }

    private.keypress := function (rec) {
	wider private;
	private.markerinput_accumulate(rec);
	# s := paste(rec);
	# public.message(s);
	return T;
    }


#==================================================================================
# Various options need a 'boxcursor', i.e. a rubber-band box drawn on the screen.
# The two following functions are called at mouse_down and mouse_up: 
#==================================================================================

# Activate marker input. Called in mouse_down callback.

    private.markerinput_start := function (rec) {
	wider private;
	# print 'markerinput_start';
	if (!has_field(private,'markerinput')) private.markerinput  := [=];
	private.markerinput.active := T;   
	private.markerinput.x := rec.world[1];   
	private.markerinput.y := rec.world[2];   
	private.markerinput.text := '';   
	return T;
    }

# De-activate marker input. Called in mouse_up callback.

    private.markerinput_stop := function (rec=F) {
	wider private;
	if (!has_field(private,'markerinput')) {
	    # Does not exist, so certainly not active: do nothing.
	} else if (private.markerinput.active) {
	    private.markerinput.active := F;   
	    text := private.markerinput.text;   
	    s := paste('markerinput_stop: text=',text);
	    if (text != '') {
		public.clitem (x=private.markerinput.x, 
			       y=private.markerinput.y, 
			       text=text, offset=0,  
			       region='plot_window', 
			       group='markerinput'); 
	    }
	    public.message(s);
	} else {
	    # Not active: do nothing.
	}
	return T;
    }

# Accumulate marker input (if active). Called in keypress callback.

    private.markerinput_accumulate := function (rec) {
	wider private;
	if (!has_field(private,'markerinput')) {
	    # Does not exist, so certainly not active: do nothing.
	} else if (private.markerinput.active) {
	    # print 'markerinput_accumulate: rec=\n',rec;
	    text := private.markerinput.text;
	    char := private.code2char(rec.code);
	    if (is_string(char)) {
		text := spaste(text, char);   
	    } else if (is_integer(char)) {        # special: key code
		if (char==22) {                   # backspace
		    ss := split(text,'');         # split into chars
		    text := spaste(ss[1:max(1,len(ss)-1)]);
		}
	    }   
	    private.markerinput.text := text;
	    s := paste('accumulated marker text:',text);
	    public.message(s);
	}
	return T;
    }

# Helper function: translate key-code (see marker input) to ascii charecter:

    private.code2char := function (code=F) {
	ccundef := '#';                           # undefined chars
	special := '@';                           # special chars
	# cc := rep(ccundef,70);
	cc[10:21] := "1 2 3 4 5 6 7 8 9 0 - =";
	cc[24:35] := "q w e r t y u i o p [ ]";	
	cc[38:47] := "a s d f g h j k l ;";
	cc[52:61] := "z x c v b n m , . /";
	cc[65] := ' ';                            # space
	cc[22] := special;
	# print cc;
	if (code<=0 || code>len(cc)) {
	    print 'code2char: out of range: key code=',code;
	} else if (cc[code]==special) { 
	    print 'code2char: key code=',code,'(special,integer)';
	    return code;
	} else if (cc[code]==ccundef) {
	    print 'code2char: not recognised: key code=',code;
	} else {
	    print 'code2char: key code=',code,'->',cc[code];
	    return cc[code];
	}
    
    }


#==================================================================================
# Various options need a 'boxcursor', i.e. a rubber-band box drawn on the screen.
# The two following functions are called at mouse_down and mouse_up: 
#==================================================================================

    private.boxcursor_start := function (rec, trace=F) {
	wider private;
	if (!has_field(private,'boxcursor')) {          # should not happen?
	    # OK, will be created here.
	} else if (is_record(private.boxcursor)) {      # already active
	    print 'pgwaux.boxcursor already active...';
	    return F;	                                # 
	}
	if (!has_field(rec,'button')) rec.button := rec.code;
	private.pgw.cursor ('rect', x=rec.world[1], y=rec.world[2]);
	bc := [=];
	bc.start := rec.world;				# [x,y]
	bc.code := bc.button := rec.button;		# 1,2,3
	private.boxcursor := bc;			# activate
	return T;
    }

    private.boxcursor_stop := function (rec, trace=F) {
	wider private;
	if (!has_field(rec,'button')) rec.button := rec.code;
	if (!has_field(private,'boxcursor')) return F;	# not active
	if (is_boolean(private.boxcursor)) return F;	# not active
	private.pgw.cursor ('norm');			# release cursor
	bc := private.boxcursor;			# see boxcursor_start()
	private.boxcursor := F;				# de-activate
	bc.stop := rec.world;
	bc.xrange := range(bc.start[1], bc.stop[1]);
	bc.yrange := range(bc.start[2], bc.stop[2]);	
	bc.xmin := bc.xrange[1];
	bc.xmax := bc.xrange[2];
	bc.ymin := bc.yrange[1];
	bc.ymax := bc.yrange[2];
	# Also include some information about the panel that has the focus!
	bc.icol := private.panel.icol;                  
	bc.irow := private.panel.irow;
	rr := private.panel.def[private.panel.ipanel];
	bc.xdir := rr.xdir;
	bc.ydir := rr.ydir;
	if (trace) print 'boxcursor_stop:',bc;
	public.agent -> boxcursor(bc);			# to outside world
	return bc;					# return record
    }

#==================================================================================
# Color wedge (along the left margin L (B/T/R/L)):
# NB: Store the wedge definition as part of the current panel definition,
#     so that it can be used in a callback function (click in left margin) 

    public.wedg := function (cmin=-1, cmax=1, ylabel=' ') {
	wider private;
	wdisp := 0.2;                               # wedge displacement
	width := 3;                                 # wedge width
	private.pgw.wedg('L', wdisp, width, cmin, cmax, ylabel);
	wdr := [=];                                 # wedge definition record
	wdr.cmin := cmin;                           # min color value (black..)
	wdr.cmax := cmax;                           # max color value (white..)
	qwin := public.qwin();                      # current window parameters
	for (s in "xblc xtrc xdir yblc ytrc ydir") {
	    wdr[s] := qwin[s];                      # copy fields from qwin
	}
	wdr.xtrc -:= qwin.xdir * qwin.xspan/100;    # xtrc of wedge
	wdr.xblc -:= qwin.xdir * qwin.xspan/20;     # xblc of wedge
	# print 'pgwaux.wedg: wdr=',wdr;
	ipanel := private.panel.ipanel;             # current panel nr
	private.panel.def[ipanel].wedge := wdr;     # attach to panel definition
	return T;
    }

# Check if color wedge has been clicked on:

    private.clicked_wedge := function (rec, trace=F) {
	wider private;
	if (!has_field(rec,'button')) rec.button := rec.code;
	x := rec.world[1];				# from pgplotter
	y := rec.world[2];				# from pgplotter

	funcname := 'pgwaux.clicked_wedge';
	s := spaste(rec);
	private.prof.start(funcname, text=s, tracelevel=1);
	if (trace) print funcname,s;

	ipanel := private.panel.ipanel;                 # current panel
	wdr := private.panel.def[ipanel].wedge;         # definition record
	if (!is_record(wdr)) {                          # no wedge defined
	    print funcname,'no color wedge defined';    # problem, escape
	    return private.prof.stop(funcname, result=F);
	}
	cmean := (wdr.cmin+wdr.cmax)/2;
	cspan := abs(wdr.cmax-wdr.cmin);
	wfrac := (y-wdr.yblc)/(wdr.ytrc-wdr.yblc);      # wedge fraction

	rr := [=];                                      # output record
	rr.code := rr.button := rec.button;             # copy which button
	rr.cval := rr.cmin := rr.cmax := F;

	if (wdr.xdir*x < wdr.xdir*wdr.xblc) {	        # missed wesge
	    # do nothing
	} else if (wdr.xdir*x > wdr.xdir*wdr.xtrc) {	# missed wedge
	    # do nothing
	
        # yblc/ytrc checks should come AFTER xblc/xtrc checks!
	} else if (wdr.ydir*y > wdr.ydir*wdr.ytrc) {	# clicked above wedge
	    rr.cmax := wdr.cmax + cspan;
	    public.agent -> clicked_slice_wedge(rr);    # send message
	    return private.prof.stop(funcname, result=T); # OK, escape

	} else if (wdr.ydir*y < wdr.ydir*wdr.yblc) {	# clicked below wedge
	    rr.cmin := wdr.cmin - cspan;
	    public.agent -> clicked_slice_wedge(rr);    # send message
	    return private.prof.stop(funcname, result=T); # OK, escape

	} else {					# clicked on wedge
	    rr.cval := wdr.cmin + wfrac*(wdr.cmax-wdr.cmin);  # wedge value
	    public.agent -> clicked_slice_wedge(rr);    # send message
	    return private.prof.stop(funcname, result=T); # OK, escape
	}
	return private.prof.stop(funcname, result=F);	# not clicked on any
    }


#==================================================================================
# Set up the plotting 'environment' (env) in a forgiving sort of way:
#==================================================================================
# NB: This is the 'simple' (single-panel) version.
# See define_panel() for a multi-panel one.

    public.env := function (xmin=-1, xmax=1, ymin=-1, ymax=1, 
			    xrange=F, yrange=F, xdir=1, ydir=1,
			    just=0, axis=0, 
			    xmargin=0.05, ymargin=0.05,
			    trace=F, clear=F, resize=F,
			    icol=1, irow=1) {
	wider private;
	funcname := 'pgwaux.env';
	private.prof.start(funcname, text=F, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	s := paste('pgwaux.env: xrange=',xmin,xmax,' yrange=',ymin,ymax);
	s := paste(s,'just=',just,' axis=',axis);
	s := paste(s,'pgw=',r := private.check_pgw('pgwaux.env()'));
	if (trace) print s;
	if (!r) return private.prof.stop(funcname, result=F);

	public.bbuf('pgwaux.env');		# fill command-buffer
	if (clear) {
	    private.pgw.clear();		# 
	}

	private.pgw.sci(1);			# color index
	private.pgw.sls(1);			# line-style
	private.pgw.slw(1);			# line-width
	private.pgw.sch(1);			# character height
	if (resize) {                           # resize only
	    rr := private.env_resize;		# use existing
	} else {                                # decode input args        
	    rr := [=];
	    rr := private.decode_xy (rr, xrange, yrange, 
				     xmin, xmax, xdir,
				     ymin, ymax, ydir,
				     xmargin, ymargin);
	    rr := private.decode_axis (rr, axis, just);
	    private.env_resize := rr;		# keep for later
	}

	if (trace) print '\n rr for env():\n',rr,'\n';

	public.subp (ncol=1, nrow=1, resize=resize, trace=trace);  # one panel...!?
	retval := private.pgw.env(rr.xblc, rr.xtrc, rr.yblc, rr.ytrc, 
	                          rr.just, rr.axis);
	if (is_fail(retval)) print retval;

	public.ebuf('pgwaux.env');		# execute command-buffer
	return private.prof.stop(funcname, result=retval);
    }

#-----------------------------------------------------------------------------
# Helper function to calculate xmin, xmax, ymin, ymax from inputs:

    private.decode_xy := function (rr=F, xrange=F, yrange=F,
				   xmin=-1, xmax=1, xdir=1,
				   ymin=-1, ymax=1, ydir=1,
				   xmargin=0.05, ymargin=0.05) {
	if (is_boolean(rr)) rr := [=];
	rr.xmin := xmin;
	rr.xmax := xmax;
	rr.ymin := ymin;
	rr.ymax := ymax;
	if (!is_boolean(xrange)) {
	    rr.xmin := min(xrange);
	    rr.xmax := max(xrange);
	}
	if (!is_boolean(yrange)) {
	    rr.ymin := min(yrange);
	    rr.ymax := max(yrange);
	}
	if (rr.xmin==rr.xmax) {
	    dx := max(abs(rr.xmin),0.001);
	    rr.xmin -:= dx;
	    rr.xmax +:= dx;
	}
	if (rr.ymin==rr.ymax) {
	    dy := max(abs(rr.ymin),0.001);
	    rr.ymin -:= dy;
	    rr.ymax +:= dy;
	}
	if (!is_boolean(xmargin)) {
	    dx := abs(rr.xmax-rr.xmin)*xmargin;
	    rr.xmin -:= dx;
	    rr.xmax +:= dx;
	}
	if (!is_boolean(ymargin)) {
	    dy := abs(rr.ymax-rr.ymin)*ymargin;
	    rr.ymin -:= dy;
	    rr.ymax +:= dy;
	}
	# The coordinates may run in the reverse order:
	# This is indicated by negative xdir and/or ydir.
	rr.xblc := rr.xmin;
	rr.xtrc := rr.xmax;
	rr.xdir := xdir;                    # -1 if reversed
	if (rr.xdir<0) {
	    rr.xdir := -1;                  # just in case
	    rr.xblc := rr.xmax;             # blc = bottom left corner
	    rr.xtrc := rr.xmin;             # trc = top right corner
	}
	rr.yblc := rr.ymin;
	rr.ytrc := rr.ymax;
	rr.ydir := ydir;                    # -1 if reversed
	if (rr.ydir<0) {
	    rr.ydir := -1;                  # just in case
	    rr.yblc := rr.ymax;
	    rr.ytrc := rr.ymin;
	}
	return rr;                          # return record
    }

#-----------------------------------------------------------------------------
# Helper function to decode axis input:

    private.decode_axis := function (rr=F, axis=0, just=0) {
	if (is_boolean(rr)) rr := [=];
	rr.xopt := rr.yopt := 'BCNST';   # used by box() 
	rr.axis := axis;                 # used by env()
	rr.just := just;                 # used by env()

	# print 'decode_axis: rr=',rr;

	# Decode axis (controls xy-axis rendering):
	if (rr.axis=='xlog') {
	    rr.axis := 10;
	} else if (rr.axis=='ylog') {
	    rr.axis := 20;
	} else if (rr.axis=='xylog') {
	    rr.axis := 30;
	} else if (rr.axis=='xyzero') {
	    rr.axis := 1;
	    rr.xopt := rr.yopt := 'ABCNST'; 
	} else if (rr.axis=='xygrid') {
	    rr.axis := 2;
	    rr.xopt := rr.yopt := 'ABCGNST';
	} else if (rr.axis=='none') {
	    rr.axis := -2;
	} else if (rr.axis=='box') {
	    rr.axis := -1;
	    rr.xopt := rr.yopt := 'BC'; 
	} else if (rr.axis=='axes' || rr.axis=='xy') {
	    rr.axis := 0;
	} else if (!any(rr.axis==[-2,-1,0,1,10,20,30])) {
	    rr.axis := 0;
	}

	# Decode just (controls the aspect-ratio):
	if (rr.just=='equal') {
	    rr.just := 1;		# aspect-ratio = 1;
	} else if (!is_integer(rr.just)) {
	    rr.just := 0;
	}

	return rr;                        # return record
    }

#-----------------------------------------------------------------------------
# Select a panel [icol,irow], (re-)define a window and draw a box around it:

    public.define_panel := function (icol=1, irow=1,
				     xmin=-1, xmax=1, xdir=1,
				     ymin=-1, ymax=1, ydir=1,
				     xrange=F, yrange=F,
				     xmargin=0.05, ymargin=0.05,
				     just=0, axis=0, color=1,
				     trace=F, clear=F) {
	wider private;
	s := paste('pgwaux.define_panel(icol=',icol,'irow=',irow,'):'); 
	if (trace) print s;
	funcname := 'pgwaux.define_panel';
	private.prof.start(funcname, text=s, tracelevel=1);

	# Decode input arguments and store the new panel definition:
	rr := [=];
	rr := private.decode_xy (rr, xrange, yrange, 
				 xmin, xmax, xdir,
				 ymin, ymax, ydir,
				 xmargin, ymargin);
	rr := private.decode_axis (rr, axis, just);
	rr.wedge := F;                                  # color-wedge
	ipanel := private.panel.seqnr[icol,irow];       # checks??
	private.panel.def[ipanel] := rr;                # store for later use...
	if (trace) print 'ipanel=',ipanel,'def=\n',rr,'\n';
	public.select_panel(icol, irow, erase=T);
	return private.prof.stop(funcname, result=T);
    }


# Select a plot-panel by col/row nr (i.e. it gets the focus): 

    public.select_panel := function (icol=1, irow=1, erase=F, trace=F) {
	wider private;
	s := paste('pgwaux.select_panel(icol=',icol,'irow=',irow,'):');
	if (trace) print s;
	funcname := 'pgwaux.define_panel';
	private.prof.start(funcname, text=s, tracelevel=1);

	if (!private.check_panel(icol, irow, trace=trace)) {
	    return private.prof.stop(funcname, result=F);
	} else if (!private.check_pgw('pgwaux.select_panel()')) {
	    return private.prof.stop(funcname, result=F);
	}

	icol := max(1,icol);
	irow := max(1,irow);
	icol := min(private.panel.ncol,icol);
	irow := min(private.panel.nrow,irow);
	ipanel := private.panel.seqnr[icol,irow];
	if (is_boolean(ipanel) || ipanel<=0) {
	    print s,'ipanel out of range:',ipanel;
	    return private.prof.stop(funcname, result=F);
	}
	rr := private.panel.def[ipanel];
	if (trace) print s,'ipanel=',ipanel,'def[ipanel]=\n',rr;

	# Update the overall 'state' (used by other functions)
	private.panel.icol := icol;                     # current column nr
	private.panel.irow := irow;                     # current row nr
	private.panel.ipanel := ipanel;                 # current panel nr

	public.bbuf('pgwaux.select_panel');		# fill command-buffer

	# Remove the focus from the current panel (if necessary):
	if (private.panel.focus) {                      # a panel has focus 
	    private.box(focus=F);                       # remove focus
	}
	private.panel.focus := T;                       # do from now on

	private.pgw.panl(icol, irow);                   # select panel
	if (erase) private.pgw.eras();                  # erase

	# NB: swin() must be called BEFORE box()!
	private.pgw.swin (rr.xblc, rr.xtrc, rr.yblc, rr.ytrc);

	# Indicate that this panel now has got the focus: 
	private.box(focus=T);                           # indicate focus
	public.ebuf('pgwaux.select_panel');	        # execute command-buffer
	public.agent -> switched_panel();               # outside world
	return private.prof.stop(funcname, result=T);
    }

# Get information about the panel that has the focus:

    public.get_current_focus := function (trace=F) {
	rr := [=];
	rr.icol := private.panel.icol;
	rr.irow := private.panel.irow;
	if (trace) print 'pgwaux.get_current_focus() -> ',rr;
	return rr;
    }

# Draw a box for the current panel:

    private.box := function (focus=T, trace=F) {
	wider private;

	ipanel := private.panel.ipanel;
	axis := private.panel.def[ipanel].axis;  # use existing
	xopt := private.panel.def[ipanel].xopt;  # use existing
	yopt := private.panel.def[ipanel].yopt;  # use existing
	private.panel.def[ipanel].focus := focus; # store for later use...

	s := paste('pgwaux.box(focus=',focus,') ipanel=',ipanel);
	s := paste(s,': xopt=',xopt,' yopt=',yopt,' axis=',axis);
	if (trace) print s;

	if (axis<0) {
	    if (trace) print 'pgwaux.box(): axis=',axis,': no box required';
	    return T;
	}

	private.pgw.sci(1);			# color index
	private.pgw.sls(1);			# line-style
	private.pgw.slw(1);			# line-width
	private.pgw.sch(1);			# character height

	# If more than one panel defined, indicate which has the focus:
	if ((private.panel.ncol*private.panel.nrow)>1) {
	    # if (focus) private.pgw.sci(7);      # yellow if has focus
	    if (focus) private.pgw.sci(5);      # cyan if has focus
	}

	xtick := ytick := nxsub := nysub := 0;  # automatic
	private.pgw.box (xopt, xtick, nxsub, yopt, ytick, nysub);
	private.pgw.sci(1);			# back to default color
	return T;
    }

# Subdivide the pgplot surface into nrow*ncol panels: 

    public.subp := function (ncol=1, nrow=1, resize=F, trace=F) {
	wider private;
	s := paste('pgwaux.subp(ncol=',ncol,'nrow=',nrow,'):');
	if (trace) print s;
	if (!has_field(private,'panel')) private.panel := [=];
	nrow := max(1,nrow);
	ncol := max(1,ncol);
	private.panel.ncol := ncol;                     # nr of columns
	private.panel.nrow := nrow;                     # nr of rows
	private.panel.def := [=];
	private.panel.seqnr := array(0,ncol,nrow);
	private.panel.occupied := array(F,ncol,nrow);   # use .def?
	ipanel := 0;               
	for (irow in [1:nrow]) {
	    for (icol in [1:ncol]) {
		ipanel +:= 1;                           # panel seq nr
		private.panel.seqnr[icol,irow] := ipanel;
		private.panel.def[ipanel] := F;         # undefined as yet
		private.panel.npanel := ipanel;         # total nr of panels
	    }
	}
	icol := 1;
	irow := 1;
	private.panel.icol := icol;                     # current column nr
	private.panel.irow := irow;                     # current row nr
	private.panel.ipanel := private.panel.seqnr[icol,irow];
	private.panel.focus := F;                       # none has focus yet
	if (trace) print 'pgwaux.panel:',private.panel;

	# Clear all clickable items and markers:
	if (!resize) {
	    private.clear_clitem();
	    private.clear_marker();
	}

	if (!private.check_pgw('pgwaux.subp')) return F;
	private.pgw.subp (ncol, nrow);
	return T;
    }

# Switch panel if required (called by mouse_down):

    private.switch_panel := function (rec, trace=F) {
	wider private;
	x := rec.world[1];				# from pgplotter
	y := rec.world[2];				# from pgplotter

	qwin := public.qwin();			        # get window range
	dcol := as_integer(qwin.xdir*(x-qwin.xmid)/qwin.xspan);
	drow := as_integer(qwin.ydir*(qwin.ymid-y)/qwin.yspan);
	s := spaste('pgwaux.switch_panel(): dcol=',dcol,' drow=',drow);
	if (trace) print s; 

	# Determine icol/irow of new panel:
	icol := max(1,dcol+private.panel.icol);
	icol := min(icol,private.panel.ncol);
	irow := max(1,drow+private.panel.irow);
	irow := min(irow,private.panel.nrow);
	ipanel := private.panel.seqnr[icol,irow];       # checks??

	s := spaste('pgwaux.switch_panel(): icol=',icol,' irow=',irow);
	s := paste(s,'ipanel=',ipanel,type_name(private.panel.def[ipanel])); 
	if (trace) print s;

	# Determine whether or not to switch panel:
	switch := F;
	if (is_record(private.panel.def[ipanel])) {     # defined
	    if (icol != private.panel.icol) switch := T;
	    if (irow != private.panel.irow) switch := T;
	} else {
	    s := spaste('switch_panel(): icol=',icol,' irow=',irow);
	    s := paste(s,': panel',ipanel,'not yet defined'); 
	    if (trace) print s;
	    public.message(s);
	    return T;                                   # required!
	}

	if (switch) {
	    public.select_panel(icol, irow);            # switch panel
	    s := spaste('switched focus to panel: icol=',icol,' irow=',irow);
	    if (trace) print s; 
	    public.message(s);
	}
	return switch;
    }


# Helper function:

    private.check_panel := function (icol=1, irow=1, trace=F) {
	wider private;
	s := paste('pgwaux.check_panel(icol=',icol,'irow=',irow,'):');
	if (!has_field(private,'panel')) {             # .....
	    print s,'calling subp() first...!?';       # should not happen?
	    public.subp(ncol=icol, nrow=irow);         # initialise
	} else if (icol<=0 || icol>private.panel.ncol) {
	    print s,'icol out of range';
	    return F;
	} else if (irow<=0 || irow>private.panel.nrow) {
	    print s,'irow out of range';
	    return F;
	} else if (private.panel.seqnr[icol,irow]==0) {
	    print s,'panel not yet defined';
	    return F;
	}
	if (trace) print s,'OK, ipanel=',private.panel.seqnr[icol,irow];
	return T;                                      # panel OK
    } 


#================================================================================
# Functions dealing with clickable fields (clitems):
#================================================================================

# Define a clickable field NEAR the given point (x,y). The offset depends on the 
# orientation angle (allowed: 0,90,-90 degr) and the window size.
# The angle is in degrees. Default left-justification (fjust=0);
# The offset (dx,dy) is in units of window-size/100.  


    public.clitem := function (x=0, y=0, text=' ', 
			       region='plot_window', group=F, 
			       color='default', background=0,
			       angle=0, fjust=0, offset=1, 
			       toggle=T, emphasize=F, marker=F,
			       font=F, charsize=1,
			       ref callback=F, ref userdata=F, 
			        draw=T, clear=F, trace=F) {
	wider private;
	if (trace) print 'pgwaux.clitem: text=',text;
	if (clear || !has_field(private,'clitem')) private.clear_clitem();

	cf := [=];					# definition record
	cf.text := text;				# field text
	cf.charsize := charsize;                        #                         

	rr := public.decode_plot_color(color);
	cf.color := rr.color;
	cf.cindex := rr.cindex;

	rr := public.decode_plot_color(background);
	cf.background := rr.color;
	cf.bcindex := rr.cindex;

	cf.region := region;		# e.g. 'left_margin'
	cf.group := group;		# e.g. 'xannot'

	cf.emphasize := emphasize;	# if T, high-light
	cf.toggle := toggle;		# if T, toggle emphasize
	cf.count := 0;			# count nr of times clicked

	cf.marker := marker;		# if specified, mark if emphasized
	cf.marker_index := F;		# pointer into private.marker

	cf.angle := angle;		# orientation (degr)

	if (is_string(fjust)) {
	    if (fjust == 'left') {
		fjust := 0;
	    } else if (fjust == 'right') {
		fjust := 1.0;
	    } else if (fjust == 'centre') {
		fjust := 0.5;
	    } else {
		fjust := 0;
	    }
	}

	cf.fjust := fjust;				# justification (0-1)

	xxyy := private.pgw.qwin();			# get window coord
	dx := offset * abs(xxyy[2]-xxyy[1])/100;	# x-offset 
	dy := offset * abs(xxyy[4]-xxyy[3])/100;	# y-offset
	if (angle==0) {
	    dy := 0;
	} else if (angle==90) {
	    dx := 0;
	} else if (angle == -90) {
	    dx := 0;
	    dy := -dy;
	} else {
	    print 'clitem_define:',text,': illegal angle=',angle;
	    angle := 0;					# default
	    dy := 0;
	}
	cf.x := x + dx;					# x-pos of label-field
	cf.y := y + dy;					# y-pos of label-field

	# Boxpnts is vector: [x1,x2,x3.x4,y1,y2,y3,y4]
	# Clockwise 1,2,3,4, starting in bottom-left corner (cf.angle=0);
	# The entire scheme rotates with cf.angle.
	cf.boxpnts := private.pgw.qtxt(cf.x,cf.y,cf.angle,cf.fjust,cf.text); 
	cf.xmin := min(cf.boxpnts[1:4]);
	cf.xmax := max(cf.boxpnts[1:4]);
	cf.ymin := min(cf.boxpnts[5:8]);
	cf.ymax := max(cf.boxpnts[5:8]);

	if (is_function(callback)) {		# executed when clicked
	    cf.callback := callback;		# user-provided
	} else {
	    cf.callback := private.callback_default;	# see below
	}
	
	# Userdata may be used by the callback function:
	# print 'clitem:',cf.text,'userdata:',type_name(userdata),shape(userdata);
	cf.userdata := userdata;		# can be used by callback

	cf.draw := draw;			# if F, do not draw
	private.clitem_draw (cf);		# draw the clitem

	# Each clitem belongs to a specific plot-panel:
	cf.irow := private.panel.irow;
	cf.icol := private.panel.icol;
	cf.ipanel := private.panel.ipanel;

	# Store the newly defined clitem:
	index := 1+len(private.clitem);
	cf.index := index;			# it knows its own index
	private.clitem[index] := cf;		# add to internal list
	if (trace) print 'pgwaux.clitem(): cf=\n',cf;
	# Collect clitem indices per region for quicker lookup:
	private.clitem_indices(region=cf.region, index=index);


	return index;			        # return storage index
    }

# Helper function to clear the clitem list (and related stuff):

    private.clear_clitem := function (trace=F) {
	wider private;
	if (trace) print 'pgwaux.clear_clitem()';
	private.clitem := [=];				# clear the list
	private.clitem_indices (init=T);		# see below
	return T;
    }

# Helper function to make a list of relevant clitem-indices, 
# i.e. the clitems in a specified region (e.g. left_margin etc).
# Only clitems of the current plot-panel (icol,irow) are selected.

    private.clitem_indices := function (region=F, index=F, init=F, trace=F) {
	wider private;
	s := paste('clitem_indices (',region,index,init,'): ');
	if (trace) print s;
	private.check_panel();                          # make sure panel defined
	if (init || !has_field(private,'clitem_index')) {
	    private.clitem_index := [=];		# initialise
	    for (i in seq(private.panel.npanel)) {      # per panel
		private.clitem_index[i] := [=];		# initialise
		if (trace) print 'private.clitem_index[',i,'] := [=]';
	    }
	}
	if (is_boolean(region)) return F;		# init only

	ipanel := private.panel.ipanel;                 # current panel nr
	if (is_boolean(ipanel) || ipanel<=0) {
	    print 'pgwaux.clitem_indices: ipanel undefined...!?';
	} 

	if (!has_field(private.clitem_index[ipanel], region)) {
	    private.clitem_index[ipanel][region] := [];	# empty vector
	    if (is_boolean(index)) {
		if (trace) print s,'len(ii)=',len(private.clitem);
		return ind(private.clitem);		# all...!
	    }
	}

	# If index not specified: return indices for specified region.
	if (is_boolean(index)) {
	    if (trace) print s,'len(ii)=',len(private.clitem_index[ipanel][region]);
	    return private.clitem_index[ipanel][region];

	# If index is specified, append it to the relevant stored ii: 
	} else if (index>0 && index<=len(private.clitem)) {
	    ii := private.clitem_index[ipanel][region];
	    private.clitem_index[ipanel][region] := [ii,index];	# append
	    if (trace) print s,'append index, new length=',1+len(ii);
	}
	if (trace) print s,'len(ii)=',len(private.clitem_index[ipanel][region]);
	return private.clitem_index[ipanel][region];	# always
    }


# Print an overview of clitems:

    public.list_clitems := function (full=F) {
	print s := paste('\n Overview of clickable items:');
	for (ipanel in [1:private.panel.npanel]) {
	    rr := private.clitem_index[ipanel];        # copy for convenience
	    print s1 := paste('..ipanel=',ipanel);
	    s := paste(s,'\n',s1);
	    for (fname in field_names(rr)) {
		print s2 := paste('....',fname,': ii=',rr[fname]);
		s := paste(s,'\n',s2);
		if (full) {
		    # show the text-strings and position of each clitem...
		}
	    }
	}
	return paste(s,'\n');
    }

# Draw the given clitem (record cf):

    private.clitem_draw := function (ref cf, erase=F, trace=F,
				     emphasize='unchanged') {
	if (is_boolean(emphasize)) cf.emphasize := emphasize[1];
	if (trace) print 'clitem_draw:',cf.text,cf.color,cf.emphasize;
	if (!cf.draw) return T;				# do nothing
	if (!private.check_pgw('pgwaux.clitem_draw')) return F;

	public.bbuf('pgwaux.clitem_draw');		# fill command-buffer
	if (cf.bcindex != 0) {                          # special backgound
	    private.pgw.sci(cf.bcindex);		# rectangle color
	    private.pgw.rect(cf.xmin,cf.xmax,cf.ymin,cf.ymax);
	}
	private.pgw.sch(cf.charsize);                   # set char-size
	if (cf.emphasize) {
	    private.pgw.slw(5);				# thicker lines
	} else {					# erase first
	    private.pgw.slw(5);				# thicker lines
	    private.pgw.sci(0);				# same as background
	    private.pgw.ptxt(cf.x,cf.y,cf.angle,cf.fjust,cf.text); # erase
	    private.pgw.slw(1);				# thin lines
	}
	private.pgw.sci(cf.cindex);			# text color index
	if (erase) {
	    private.pgw.sci(0);			        # same as background
	} else if (cf.emphasize && cf.cindex==1) {      # if not colored
	    private.pgw.sci(7);			        #   empasize with yellow
	    private.pgw.slw(1);				#   use thin lines
	}
	private.pgw.ptxt(cf.x,cf.y,cf.angle,cf.fjust,cf.text);	# write text
	public.ebuf('pgwaux.clitem_draw');		# execute command-buffer
	return T;
    }

# Draw/erase one or more stored clitems, specified by their indices:

    public.draw_clitems := function (index=F, erase=F, trace=F,
				     emphasize='unchanged') {
	wider private;
	funcname := 'pgwaux.draw_clitems';
	s := paste(funcname,'(',index,erase,emphasize,')');
	if (trace) print s;
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	if (!has_field(private,'clitem')) {
	    return private.prof.stop(funcname, result=F);
	} else if (is_boolean(private.clitem)) {
	    return private.prof.stop(funcname, result=F);
	} else if (!private.check_pgw('pgwaux.draw_clitems')) {
	    return private.prof.stop(funcname, result=F);
	}

	ii := [];					# empty
	if (is_boolean(index)) {
	    ii := ind(private.clitem);			# all
	    if (trace) print 'draw_clitems(): all',len(private.clitem),erase;
	} else if (is_string(index)) {
	    print 'draw_clitems(), not recpgnised:',index;
	    return private.prof.stop(funcname, result=F);
	} else if (index<0 || index>len(private.clitem)) {
	    print 'draw_clitems(), out of range:',index,len(private.clitem);
	    return private.prof.stop(funcname, result=F);
	} else {
	    ii := index;				# input, may be vector
	    if (trace) print funcname,'ii=',ii,'erase=',erase;
	}

	# Make sure that emphasize has the right length:
	nii := len(ii);
	if (nii>0 && (len(emphasize)!=nii)) {
	    emphasize := rep(emphasize[1],nii);         # repeat first value..
	}

	# Draw/erase the specified clitem(s):
	public.bbuf('pgwaux.draw_clitems');		# fill command-buffer
	for (k in ind(ii)) {
	    cf := ref private.clitem[ii[k]];            # convenience
	    if (!is_record(cf)) {                       # deleted
		if (trace) print k,ii[k],'clitem not a record:',type_name(cf);
		next;	                                # ignore
	    }
	    if (trace) print k,ii[k],'clitem:',cf.text,erase,emphasize[k];
	    r := private.clitem_draw (cf, erase=erase, trace=trace,
				      emphasize=emphasize[k]);
	    if (is_fail(r)) print r;
	}
	public.ebuf('pgwaux.draw_clitems');		# execute command-buffer
	return private.prof.stop(funcname, result=T);
    }

# Check if item-label has been clicked on, and execute callback:
# NB: The search is narrowed down if group and/or margin are specified. 

    private.clicked_clitem := function (rec, region=F, group=F) {
	wider private;
	funcname := 'pgwaux.clicked_clitem';
	private.prof.start(funcname, text=F, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	x := rec.world[1];				# from pgplotter
	y := rec.world[2];				# from pgplotter
	icol := rec.icol;                               # current focus
	irow := rec.irow;                               # current focus
	ii := private.clitem_indices(region=region);
	for (i in ii) {
	    if (is_string(region) && region!=private.clitem[i].region) next;
	    if (is_string(group) && group!=private.clitem[i].group) next;
	    cf := private.clitem[i];			# copy for convenience
	    if (!is_record(cf)) {
		print 'clicked_item: cf not a record';
	    } else if (y > cf.ymax) {			# missed
	    } else if (y < cf.ymin) {			# missed
	    } else if (x < cf.xmin) {			# missed
	    } else if (x > cf.xmax) {			# missed
	    } else {					# OK, clicked on one
		private.clitem_draw (private.clitem[i], erase=T);
		private.clitem[i].count +:= 1;		# increment counter
		if (private.clitem[i].toggle) {		# if toggling enabled
		    private.clitem[i].emphasize := !private.clitem[i].emphasize;
		}
		s := paste(private.clitem[i].index);
		s := spaste(s,' (',private.clitem[i].count);
		s := spaste(s,' , ',private.clitem[i].toggle);
		s := spaste(s,' , ',private.clitem[i].emphasize,'): ');
		s1 := private.clitem[i].text;
		s := paste(s,'clicked on field: \'',s1,'\'');
		public.message(s);
		private.clitem_draw (private.clitem[i]);

		# If a marker has been specified, draw/erase it as required:
		if (is_string(cf.marker)) {		# e.g. 'x' or 'y'...?
		    x := y := F;
		    if (cf.marker=='x') {		# vertical line
			x := cf.x;
		    } else if (cf.marker=='y') {	# horizontal line
			y := cf.y;
		    } else {
			print 'clitem marker not recognised:',cf.marker;
		    }
		    if (private.clitem[i].emphasize) {	# draw the marker
			index := public.marker(x=x, y=y, userdata=cf.index);
			private.clitem[i].marker_index := index;
		    } else {				# erase/delete the marker
			index := private.clitem[i].marker_index;
			k := private.marker[index].userdata;
			if (k==cf.index) {
			    public.draw_markers(index, erase=T, delete=T);
			} else {
			    print 'clitem/marker index difference:',k,cf.index;
			}
		    }
		}

		# NB: What arguments should we give the callback function...?
		private.clitem[i].callback(cf);
		return private.prof.stop(funcname, result=T); # OK, escape
	    }
	}
	return private.prof.stop(funcname, result=F);	# not clicked on any
    }

# Default callback function (does nothing special):

    private.callback_default := function (ref cf=F, trace=F) {
	if (trace) print '\n pgwaux: callback_default:\n';
	# private.tf.summary(cf, 'cf', recurse=F, show=T);
	# inspect(cf,'cf');
	return T;
    }


#================================================================================
# Functions dealing with markers:
#================================================================================
	
    public.marker := function (x=F, y=F, label=F, group=F, userdata=F, 
			       color='yellow', style='dotted', charsize=1,
			       clear=F, draw=T, erase=F, trace=F) {
	wider private;
	if (!has_field(private,'marker')) private.marker := [=];
	if (trace) print '\nmarker: x=',x,'y=',y,erase,color,style,label,group;
	if (clear) private.clear_marker();	# clear the list
	cf := [=];				# marker definition record
	cf.xx := [0,0];
	cf.yy := [0,0];

	cf.group := group;			# ....?
	cf.userdata := userdata;		# supplied by user...?

	cf.label := label;			# no label (yet)
	cf.xposlabel := 0;
	cf.yposlabel := 0;
	cf.angle := 0;				# label angle
	cf.just := 0;				# label left-justified

	rr := public.decode_plot_color(color);
	cf.color := rr.color;			# not used, info only
	cf.cindex := rr.cindex;

	rr := public.decode_plot_style(style);
	cf.style := rr.style;
	cf.linestyle := rr.linestyle;		# not used, info only
	cf.lindex := rr.lindex;
	cf.pointstyle := rr.pointstyle;		# not used, info only
	cf.pindex := rr.pindex;

	cf.charsize := charsize;

	ii := [];				# new marker index/indices

	qwin := public.qwin();			# get window coord
	if (is_boolean(x)) {			# x undefined
	    if (is_boolean(y)) {		# y undefined
		print 'marker: neither x nor y defined (!?)';
		return F;
	    } else {				# y defined: horizontal line(s)
		cf.style := 'lines';
		for (i in ind(y)) {		# y may be vector
		    cf.xx := qwin.xrange;
		    cf.yy := [y[i],y[i]];
		    ii := [ii, private.marker_store(cf, draw, trace)];
		}
	    }
	} else {				# x defined
	    if (is_boolean(y)) {		# y undefined: vertical line(s)
		cf.style := 'lines';
		for (i in ind(x)) {		# x may be vector
		    cf.yy := qwin.yrange;
		    cf.xx := [x[i],x[i]];
		    cf.angle := 90;
		    ii := [ii, private.marker_store(cf, draw, trace)];
		}
	    } else {				# x and y defined: point(s)
		cf.style := 'points';
		cf.yy := y;			# y may be vector
		if (len(x) != len(y)) {
		}
		cf.xx := x;			# x may be vector
		cf.yposlabel := cf.yy;
		cf.xposlabel := cf.xx + qwin.dxchar;
		ii := [ii, private.marker_store(cf, draw, trace)];
	    }
	}
	if (trace) print 'pgwaux.marker: new indices ii=',ii;
	return ii;					# return vector of indices
    }


# Helper function to clear the market list (and related stuff):

    private.clear_marker := function (trace=F) {
	wider private;
	if (trace) print 'pgwaux.clear_marker()';
	private.marker := F;		        # clear the list
	return T;
    }


# Helper function to store new marker (and do some bookkeeping):

    private.marker_store := function (cf=F, draw=F, trace=F) {
	wider private;
	if (trace) print 'marker_store';
	if (!has_field(private,'marker')) private.marker := [=];
	if (is_boolean(private.marker)) private.marker := [=];
	n := 1+len(private.marker);			# append 
	for (i in ind(private.marker)) {
	    if (is_boolean(private.marker[i])) {	# empty slot
		n := i;					# insert
		break;
	    }
	}
	if (trace) print 'marker_store at:',n,'(',len(private.marker),'): ';
	private.marker[n] := [=];
	private.marker[n] := cf;
	if (trace) print 'marker_store:',type_name(cf);
	if (draw) private.marker_draw (cf);		# draw the marker
	# if (trace) print 'marker_store',n,':\n',cf;
	return n;					# return index
    }



# Draw/erase one or more stored markers, specified by their indices:

    public.draw_markers := function (index=F, erase=F, delete=T, trace=F) {
	wider private;
	funcname := 'pgwaux.draw_markers';
	private.prof.start(funcname, text=F, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	if (!has_field(private,'marker')) {
	    return private.prof.stop(funcname, result=F);
	} else if (is_boolean(private.marker)) {
	    return private.prof.stop(funcname, result=F);
	} else if (!private.check_pgw('pgwaux.draw_markers')) {
	    return private.prof.stop(funcname, result=F);
	}

	ii := [];					# empty
	if (is_boolean(index)) {
	    ii := ind(private.marker);			# all
	    if (trace) print 'draw_markers: all',len(private.marker),erase,delete;
	} else if (is_string(index)) {
	    print 'draw_marker(), not recognised:',index;
	    return private.prof.stop(funcname, result=F);
	} else if (index<0 || index>len(private.marker)) {
	    print 'draw_marker(), out of range:',index,len(private.marker);
	    return private.prof.stop(funcname, result=F);
	} else {
	    ii := index;				# input, may be vector
	    if (trace) print 'draw_markers: ii=',ii,'erase=',erase,delete;
	}

	# Draw/erase the specified marker(s):
	public.bbuf('pgwaux.draw_markers');		# fill command-buffer
	for (i in ii) {
	    if (is_boolean(private.marker[i])) next;	# deleted
	    private.marker_draw (private.marker[i], erase=erase, trace=trace);
	    if (erase && delete) private.marker[i] := F;
	}
	public.ebuf('pgwaux.draw_markers');		# execute command-buffer
	return private.prof.stop(funcname, result=T);
    }


# Draw/erase the specified marker:

    private.marker_draw := function (ref cf=F, erase=F, trace=F) {
	if (trace) print 'marker_draw:',cf.label,' erase=',erase;
	if (!private.check_pgw('pgwaux.marker_draw')) return F;
	if (is_boolean(cf)) return F;		# not defined

	public.bbuf('pgwaux.marker_draw');	# fill command-buffer
	private.pgw.sci(cf.cindex);
	if (erase) private.pgw.sci(0);		# background
	private.pgw.slw(1);			# line-width
	private.pgw.sch(cf.charsize);		# char height

	if (cf.style=='lines') {
	    private.pgw.sls(cf.lindex);		# line index
	    private.pgw.line(cf.xx, cf.yy);
	    if (is_string(cf.label)) {		# label specified
		private.pgw.ptxt(cf.xposlabel,cf.yposlabel,
				 cf.angle,cf.just,cf.label);	
	    }

	} else if (cf.style=='points') {
	    private.pgw.pt(cf.xx, cf.yy, cf.pindex);
	    if (is_string(cf.label)) {		# label specified
		for (i in ind(cf.label)) {	# may be vector!
		    private.pgw.ptxt(cf.xposlabel[i], cf.yposlabel[i],
				     cf.angle, cf.just, cf.label[i]);
		}	
	    }

	} else {
	    print 'marker_draw: not recognised:',cf.style;
	}
	public.ebuf('pgwaux.marker_draw');	# execute command-buffer
	return T;
    }

#=============================================================
# Draw/erase a 'graphic' defined by a given record rr:
#=============================================================

    public.draw_graphic := function (ref rr=F, erase=F, trace=F) {
	wider private;
	if (trace) print 'draw_graphic:',rr.type,' erase=',erase;
	if (!private.check_pgw('pgwaux.draw_graphic')) return F;
	if (is_boolean(rr)) return F;		# not defined

	public.bbuf('pgwaux.draw_graphic');	# fill command-buffer
	private.pgw.sci(rr.cindex);
	if (erase) private.pgw.sci(0);		# background....?
	private.pgw.slw(rr.size);		# line-width
	# private.pgw.sch(rr.charsize);		# char height
	private.pgw.sls(rr.lindex);		# line index

	if (rr.type=='arrow') {
	    private.pgw.arro(rr.xy1[1], rr.xy1[2],
			     rr.xy2[1], rr.xy2[2]);
	    if (is_string(rr.label)) {		# label specified
		qwin := public.qwin (dummy=F);
		xoffset := yoffset := angle := just := 0;
		xoffset := qwin.dxchar;
		dx := rr.xy2[1] - rr.xy1[1];
		dy := rr.xy2[2] - rr.xy1[2];
		if (dx<0) {                     # points to the left
		    just := 1;
		    xoffset := -xoffset;
		}
		yoffset := qwin.dychar;
		if (dy<0) {                     # points downwards
		    yoffset := -yoffset;
		}
		private.pgw.slw(1);		# line-width
		private.pgw.ptxt(rr.xy2[1]+xoffset, rr.xy2[2]+yoffset, 
				 angle, just, rr.label);	
	    }

	} else if (rr.type=='marker') {
	    private.pgw.pt(rr.xy[1], rr.xy[2], rr.pindex);
	    qwin := public.qwin (dummy=F);
	    xoffset := qwin.dxchar;
	    yoffset := qwin.dychar;
	    private.pgw.ptxt(rr.xy[1]+xoffset, rr.xy[2]+yoffset, 
			     rr.angle, rr.just, rr.label);	

	} else if (rr.type=='axis') {
	    xaxis := (rr.xy=='x');
	    yaxis := (rr.xy=='y');
	    if (rr.xy=='xy') xaxis := yaxis := T;
	    qwin := public.qwin (dummy=F);
	    if (xaxis) private.pgw.line(qwin.xrange, [0,0]);
	    if (yaxis) private.pgw.line([0,0], qwin.yrange);

	} else if (rr.type=='arc') {
	    # rr.posangle := posangle;          # position angle (rad)
	    # rr.phi12 := phi12;                # arc start/stop (rad)
	    aa := [0:100]*pi/50;                # use global pi
	    xx := rr.xy[1] + rr.radius * cos(aa);
	    yy := rr.xy[2] + rr.radius * sin(aa);
	    private.pgw.line(xx, yy);
	    if (rr.centre) {                    # indicate centre
		private.pgw.pt(rr.xy[1], rr.xy[2], rr.pindex);
	    }
	    if (rr.axes) {                      # indicate axes
		xx := [rr.xy[1]-rr.radius, rr.xy[1]+rr.radius];
		yy := [rr.xy[2], rr.xy[2]];
		private.pgw.line(xx, yy);
		yy := [rr.xy[2]-rr.radius, rr.xy[2]+rr.radius];
		xx := [rr.xy[1], rr.xy[1]];
		private.pgw.line(xx, yy);
	    }
	    

	} else {
	    print 'draw_graphic: type not recognised:',rr.type;
	}
	public.ebuf('pgwaux.draw_graphic');	# execute command-buffer
	return T;
    }

# Helper function, called when graphic is defined (in jenplot):
# Decodes the given fields 'color' and 'style' for quicker drawing.

    public.decode_plot_attrib := function (ref rr, color=F, style=F,
					   size=F, trace=F) {
	if (!is_boolean(color)) rr.color := color;   # supplied
	if (!is_boolean(style)) rr.style := style;   # supplied 
	if (!is_boolean(size)) rr.size := size;      # supplied
	if (trace) print 'decode_plot_attr:',rr;

	if (!has_field(rr,'color')) rr.color := 'cyan';
	cc := public.decode_plot_color(rr.color);
	rr.color := cc.color;
	rr.cindex := cc.cindex;

	if (!has_field(rr,'style')) rr.style := 'lines';
	cc := public.decode_plot_style(rr.style);
	rr.style := cc.style;
	rr.linestyle := cc.linestyle;	# not used, info only
	rr.lindex := cc.lindex;
	rr.pointstyle := cc.pointstyle;	# not used, info only
	rr.pindex := cc.pindex;

	if (!has_field(rr,'size')) rr.size := 1;
	return T;
    }


#===============================================================================
# Some groups of standard clickable items
#===============================================================================

# Make clickable items (clitems) for all x-axis annotation labels:

    public.annotate := function (xx=F, text=F, emphasize=F, trace=F,
				 region='top_margin', group='annotate', 
				 userdata=[=], ref callback=F) {
	wider private;
	nxx := len(xx);
	s := paste('pgwaux.annotate(',nxx,text[1],region,group,
		   type_name(userdata),')');
	if (trace) print s;
	funcname := 'pgwaux.annotate';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	if (!private.check_pgw('pgwaux.annotate')) {
	    return private.prof.stop(funcname, result=F);
	} else if (nxx<=0) {
	    print 'pgwaux.annotate: empty input vector';
	    return private.prof.stop(funcname, result=F);
	} else if (is_boolean(text)) {
	    text := split(spaste(ind(xx)),' ');
	} else if (!is_string(text)) {
	    text := split(spaste(ind(xx)),' ');
	} else if (nxx != len(text)) {
	    text := split(spaste(ind(xx)),' ');
	}

	qwin := public.qwin();		        # get window coord
	# xxyy := private.pgw.qwin();		# get window coord
	vv := xx;
	if (region=='top_margin') {
	    angle := 90;                        # vertical text
	    offset := 2*qwin.ydir; 
	    yy := rep(qwin.ytrc,nxx);           # top edge of plot-window
	    vmin := qwin.xmin;
	    vmax := qwin.xmax;
	} else if (region=='right_margin') {
	    angle := 0;                         # horizontal text
	    offset := 2*qwin.xdir; 
	    yy := xx;
	    yy -:= qwin.dychar/2;               # align with char centre
	    xx := rep(qwin.xtrc,nxx);           # right edge of plot-window
	    vmin := qwin.ymin;
	    vmax := qwin.ymax;	    
	    userdata := [=];                    # ....?
	} else {
	    print 'pgwaux.annotate: region not recognised:',region;
	    return private.prof.stop(funcname, result=F);
	}
	if (trace) print 'vmin/max=',vmin,vmax,' angle=',angle;

	# Determine the character size:
	sv := [vv>=vmin] & [vv<=vmax];          # selection vector
	n := max(1,len(sv[sv]));                # nr inside window
	charsize := 1;                          # default size
	if (n>40) charsize := 40/n;             # reduce size if many
	charsize := max(charsize,0.10);         # not too small....
	if (trace) print 'n=',n,nxx,'charsize=',charsize;

	# Make sure that userdata is a record (for attaching iannot..!):
	if (!is_record(userdata)) {
	    tmp := userdata;                    # might be important
	    userdata := [=];
	    if (!is_boolean(tmp)) userdata.userdata := tmp;
	} else if (has_field(userdata,'iannot')) {
	    print 'annotate: overwritten field iannot in userdata=',userdata;
	} 
	userdata.iannot := F;                   # make sure it has this field

	# Check the emphasize array (should be boolean, and same length as xx)
	if (!is_boolean(emphasize)) {
	    emphasize := rep(F,len(xx));
	} else if (len(emphasize) != len(xx)) {
	    emphasize := rep(F,len(xx));
	}

	# OK, make the clickable annotation items (clitems):
	public.bbuf('pgwaux.annotate');		# fill command-buffer
	ii := [];				# points into private.clitem
	for (i in ind(xx)) {
	    if (!sv[i]) next;                   # outside window
	    if (trace) print i,yy[i],'annotate:',text[i];
	    userdata.iannot := i;               # recognition field
	    j := public.clitem (x=xx[i], y=yy[i], text=text[i],
				angle=angle, offset=offset, 
				emphasize=emphasize[i],
				charsize=charsize,
				draw=T, marker='x', 
				region=region, group=group,
				userdata=userdata,
				callback=callback, marker='x');
	    ii := [ii,j];			# append index to vector
	}
	public.ebuf('pgwaux.annotate');		# execute command-buffer
	return private.prof.stop(funcname, result=ii); # return index-vector
    }


# Older (specific, obsolete) version of .annotate:

    public.xannot := function (xx, xannot=F, ref callback=F) {
	private.prof.warn_obsolete('pgwaux.xannot');
	return public.annotate (xx=xx, text=xannot, trace=F,
				region='top_margin', group='xannot', 
				userdata=[=], callback=callback);
    }


# Write the colored item label in the right margin, at pos y:
# NB: It is assumed that the correct panel has been chosen.

    public.yannot := function (y=F, label=F, color=F,
			       ref userdata=F, emphasize=F,
			       yval=F, reset=F, nslot=36,
			       ref callback=F, trace=F) {
	wider private;
	s := paste('pgwaux.yannot: y=',y,yval,color,':',label);
	if (trace) print s;
	funcname := 'pgwaux.annotate';
	private.prof.start(funcname, text=s, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	if (!private.check_pgw('pgwaux.yannot')) {
	    return private.prof.stop(funcname, result=F);
	} else if (!has_field(private,'yannot')) {
	    reset := T;
	}

	# If reset=T (or no y-value given) reset the book-keeping record:
	qwin := public.qwin();			        # get window coord
	if (reset || is_boolean(y)) {			# reset-mode
	    rr := [=];
	    # rr.charsize := private.pgw.qch();		# rel.char-size
	    rr.charsize := 1;                           # defaultxann
	    rr.yblc := qwin.yblc;
	    rr.ytrc := qwin.ytrc;
	    rr.yspan := qwin.yspan;
	    rr.nslot := max(36,nslot);                  # nr of slots
	    if (rr.nslot>36) {                          # if too many
		rr.charsize := 36/rr.nslot;             # reduce size (<1)
		rr.charsize := max(rr.charsize,0.10);   # minimum size
	    }
	    rr.dy := qwin.ydir * rr.yspan/rr.nslot;	# slot height
	    rr.islot := array(0,rr.nslot);
	    rr.yslot := rr.yblc + ([1:rr.nslot]-0.5)*rr.dy; # slot ypos
	    private.yannot := rr;			# keep
	    # public.reset_plot_color();		# reset color index (..!?)
	    if (trace) print 'reset: private.yannot=\n',private.yannot;
	} 
	if (is_boolean(y)) {
	    return private.prof.stop(funcname, result=T); # escape
	}

	# Find an empty slot to put the label in:
	rr := private.yannot;				# convenience
	islot := 1+as_integer(abs(y-rr.yblc)/rr.dy);	# ideal slot nr
	found := F;
	for (k in [0:rr.nslot]) {
	    for (i in [max(0,islot-k),min(rr.nslot,islot+k)]) {
		if (rr.islot[i]==0) {			# not occupied
		    rr.islot[i] := i;
		    y := rr.yslot[i];
		    found := T;
		    if (trace) print k,i,y,'found',label;
		    break;				# escape
		}
	    }
	    if (found) break;
	}
	if (!found) print 'pgwaux.yannot:',label,': not found, y=',y; 
	private.yannot := rr;				# replace...

	# OK, define the label as a clickable feauture (clitem) and draw it:
	# print 'pgwaux.yannot(): userdata=',type_name(userdata),len(userdata);
	public.bbuf('pgwaux.yannot');			# fill command-buffer
	x := qwin.xtrc;					# right edge
	y1 := y - qwin.dychar/2;                        # align with char centre
	index := public.clitem(x=x, y=y1, text=label, color=color,
			       offset=qwin.xdir,
			       userdata=userdata, trace=F,
			       emphasize=emphasize, charsize=rr.charsize,
			       region='right_margin', callback=callback);

	# In y-value given, write it inside the plot-window:
	if (!is_boolean(yval)) {
	    dx := qwin.xdir * qwin.xspan/50;
	    s := sprintf('%.3g',yval);			# format the value
	    # private.pgw.sci(cindex);			# use its own color (?) 
	    private.pgw.sci(1);				# use white (clearer)
	    private.pgw.slw(1);
	    private.pgw.sch(rr.charsize);
	    private.pgw.ptxt(x-dx,y,0,1,s);		# just=1 (right-justified)
	}
	public.ebuf('pgwaux.yannot');			# execute command-buffer

	if (trace) print 'end of pgwaux.yannot()';
	return private.prof.stop(funcname, result=index); # return clitem index
    }





#=========================================================================
# Helper function to get current window range (world coordinates) in various ways: 
# blc = bottom left corner, trc = top right corner.

    public.qwin := function (dummy=F) {
	if (!private.check_pgw('pgwaux.qwin')) return F;
	xxyy := private.pgw.qwin();		# get window coord
	rr := [=];
	rr.xblc := xxyy[1];
	rr.xtrc := xxyy[2];
	rr.xdir := 1;
	if (rr.xblc>rr.xtrc) rr.xdir := -1;     # xx reversed
	rr.yblc := xxyy[3];
	rr.ytrc := xxyy[4];
	rr.ydir := 1;
	if (rr.yblc>rr.ytrc) rr.ydir := -1;     # yy reversed
	rr.xrange := range(rr.xblc, rr.xtrc);
	rr.xmin := rr.xrange[1];
	rr.xmax := rr.xrange[2];
	rr.yrange := range(rr.yblc, rr.ytrc);
	rr.ymin := rr.yrange[1];
	rr.ymax := rr.yrange[2];
	rr.xspan := abs(rr.xtrc-rr.xblc);
	rr.yspan := abs(rr.ytrc-rr.yblc);
	rr.xmid := (rr.xtrc+rr.xblc)/2;
	rr.ymid := (rr.ytrc+rr.yblc)/2;
	cs := private.pgw.qch();		# current char-height
	rr.dychar := rr.yspan/39;
	rr.dxchar := 0.6 * rr.xspan/60;		# ...?
	rr.nxchar := max(1,as_integer(rr.xspan/rr.dxchar));
	rr.nychar := max(1,as_integer(rr.yspan/rr.dychar));
	return rr;				# return record
    }

#=============================================================================	
#=============================================================================
# Deal with the plot-legend (contained in the input record rr):
# If the input record (rr) is boolean, it is initialised.
# If a txt-line (string) is given, append or replace (at index=integer) it.
# If clear=T, clear the collection of stored legend-lines.
# NB: This routine is self-contained (except private.pgw).

    public.legend := function (ref rr=F, txt=F, index=F, 
			       clear=F, title=F, trace=F) {
	if (!is_record(rr)) {	                # initialiase
	    val rr := [=];			# record
	    rr.type := 'legend';                # identification
	    rr.font := F;
	    rr.color := 'default';
	    rr.cindex := 1;
	    rr.refpos := 'tlc';			# top left corner
	    # rr.refpos := 'trc';		# top right corner
	    rr.show := T;
	    clear := T;				# see below
	    if (trace) print 'pgwaux.legend() init:',rr;
	}
	if (clear) {
	    rr.text := [=];			# record...?
	    rr.text[1] := ' ';			# special: used for plot-title
	    rr.nlines := len(rr.text);		# nr of text-lines
	    rr.maxchars := 0;			# max nr of chars in any line
	    if (trace) print 'pgwaux.legend() clear:',rr;
	}

	# Add a new line to the legend:
	if (is_string(txt)) {			# new line given
	    if (title) {			# used if no room for plot-title
		# if (rr.nlines>1) public.draw_legend(rr, erase=T);
		rr.text[1] := txt;		# top-most line
		# if (rr.nlines>1) public.draw_legend(rr);
	    } else if (is_integer(index) && index>1 && index<=rr.nlines) {
		# public.draw_legend(rr, erase=T);
		rr.text[index] := txt;		# replace line;
		# public.draw_legend(rr);       # not here....?
	    } else {
		for (s in txt) {		# may be multi-line
		    ss := split(s,'\n');        # split on line-breaks
		    for (s1 in ss) {
			rr.text[rr.nlines+:=1] := s1; # append line;
		    } 
		}
	    }
	    rr.nlines := len(rr.text);		# update nr of lines
	    rr.maxchars := 0;
	    for (i  in [1:rr.nlines]) {
		nchars := len(split(rr.text[i],''));	# nr of chars in line
		rr.maxchars := max(rr.maxchars,nchars);	# max line length
	    }
	    if (trace) print 'pgwaux.legend():',rr.nlines,':',rr.text[rr.nlines];
	}
	return rr.nlines;			# return nlines!!
    }

# Plot/erase the internally stored legend:

    public.draw_legend := function (ref rr=F, erase=F, trace=F) {
	funcname := 'draw_legend';
	private.prof.start(funcname, text=F, tracelevel=1);
	# return private.prof.stop(funcname, result=F);

	if (!private.check_pgw('pgwaux.draw_legend')) {
	    return private.prof.stop(funcname, result=F);
	} else if (!is_record(rr)) {
	    print 'pgwaux.draw_legend(): rr is not a record!';
	    return private.prof.stop(funcname, result=F);
	}
	if (trace) print 'pgwaux.draw_legend():',rr.nlines, 'erase=',erase;
	if (rr.nlines<=0) {	                # no lines stored
	    return private.prof.stop(funcname, result=F);
	}

	public.bbuf('pgwaux.draw_legend');	# fill command-buffer
	original_charsize := private.pgw.qch();
	charsize := 1;				# legend charsize
	private.pgw.sch(charsize);

	qwin := public.qwin();
	x0 := qwin.xblc + qwin.xdir * qwin.xspan/40;
	dy := charsize * qwin.ydir * qwin.yspan/30;
	y0 := qwin.ytrc - dy;
	if (rr.refpos=='tlc') {                 # top-left corner
	    # OK, default
	} else if (rr.refpos=='trc') {          # top-right corner
	    xsize := (1+rr.maxchars) * qwin.dxchar;
	    x0 := qwin.xtrc - qwin.xdir * xsize;
	} else if (rr.refpos=='brc') {          # bottom-right corner
	} else if (rr.refpos=='blc') {          # bottom-left corner
	}

	private.pgw.slw(1);			# line width
	for (i in [1:rr.nlines]) {
	    # print 'legend: plot line:',rr.text[i];
	    if (erase) {
		private.pgw.sci(0);		# color index: background
	    } else {
		private.pgw.sci(1);		# color index: white
	    }
	    y := y0 - i*dy;
	    private.pgw.ptxt(x0,y,0,0,rr.text[i]);
	    # private.pgw.text(x0,y,rr.text[i]);
	}
	private.pgw.sch(original_charsize);	# restore
	public.ebuf('pgwaux.draw_legend');	# execute command-buffer
	return private.prof.stop(funcname, result=T);
    }


#==================================================================================
# Miscellaneous:
#==================================================================================






#=======================================================================
# Helper functions dealing with plot-colors:
#=======================================================================

# Define the available colors by name, in order of PGPLOT color index:

    private.define_plot_colors := function (dummy=F) {
	wider private;
	s := "default red green blue cyan magenta yellow orange";
	s := [s,'green yellow'];
	s := [s,'medium turquoise'];
	s := [s,'medium blue'];
	s := [s,'purple'];
	s := [s,'medium orchid'];
	s := [s,'grey'];
	s := [s,'light grey'];
	private.colors := s;
	public.reset_plot_color();
	return T;
    }

# Helper routine: display all plot colors on the pgplot-widget:

    public.show_plot_colors := function (dummy=F) {
	if (!private.check_pgw('pgwaux.show_plot_colors')) return F;
	public.bbuf('pgwaux.show_plot_colors');	# fill command-buffer
	public.env(0,10,0,16, axis='none');
	for (i in [0:15]) {
	    s := sprintf('%2i: %-20s',i,private.colors[i]);
	    rgb := private.pgw.qcr(i);		# RGB represenation
	    s := spaste(s,' RGB=',rgb);
	    private.pgw.sci(i);
	    private.pgw.text(1,i,s);
	}
	public.ebuf('pgwaux.show_plot_colors');	# execute command-buffer
	return T;
    }

# Reset the automatic plot color selector:

    public.reset_plot_color := function (dummy=F, trace=F) {
	wider private;
	if (trace) print 'reset_plot_color()';
	return private.auto_cindex := 1;
    } 

# Decode the given 'color', and return a record (rr):

    public.decode_plot_color := function (color=F, reset=F, trace=F) {
	wider private;

	rr := [=];					# return record
	rr.color := color;				# copy input
	rr.cindex := 1;					# default

	if (reset) public.reset_plot_color(trace=trace); # reset

	if (is_boolean(color)) {			# automatic color
	    private.auto_cindex +:= 1;			# increment
	    if (private.auto_cindex>15) private.auto_cindex := 2;
	    rr.cindex := private.auto_cindex;		# assign
	    rr.color := private.colors[rr.cindex];	# 
		
	} else if (is_numeric(color)) {			# 
	    if (len(color)==1) { 			# color index given
		sv := [color==ind(private.colors)];
		if (color==0) {
		    rr.color := 'background';
		    rr.cindex := 0;
		} else if (any(sv)) {
		    rr.cindex := ind(sv)[sv];
		    rr.color := private.colors[rr.cindex];	# 
		} else {
		    print 'decode_plot_color: color index not recognised:',color;
		}
	    } else if (len(color)==3) { 		# RGB numbers given
		print 'decode_plot_color: color RGB not yet supported:',color;
	    } else {
		print 'decode_plot_color: color index/RGB not recognised:',color;
	    }

	} else if (is_string(color)) {			# color name given
	    sv := [color==private.colors];
	    if (any(sv)) {				# recognised
		rr.cindex := ind(sv)[sv];		#
	    } else if (color=='default' || color=='white') {
		rr.cindex := 1;			        # default color
	    } else if (color=='background' || color=='black') {
		rr.cindex := 0;			        # background color
	    } else {
		print 'decode_plot_color: color not recognised:',color;
	    }
	} else {
	    print 'decode_plot_color: color type not recognised:',type_name(color);
	}
	if (trace) {
	    s := spaste('decode_plot_color(color=',color);
	    s := spaste(s,' reset=',reset,') -> ',rr);
	    print s;
	}
	return rr;				# return record
    }

#=======================================================================
# Helper functions dealing with plot-styles:
#=======================================================================

    private.define_plot_styles := function (dummy=F) {
	wider private;
	ps := [=];
	ps.dot := -1;
	ps.plus := 2;
	ps.star := 12;
	ps.triangle := 7;
	ps.cross := 5;
	ps.square := 0;
	ps.circle := 4;
	ps.diamond := 11;
	ps.dirprod := 8;
	private.pointstyles := ps;

	ls := [=];
	ls.solid := 1;
	ls.dashed := 2;
	ls.dotdash := 3;
	ls.dotted := 4;
	ls.dashdotdotdot := 5;
	private.linestyles := ls;

	public.decode_plot_style(reset=T);
	return T;
    }

    public.decode_plot_style := function (style=F, reset=T, trace=F) {
	if (reset) {
	    # no reset-action, maybe later.
	}
	rr := [=];					# return-record
	rr.style := style;				# copy
	rr.linestyle := 'solid';			# default
	rr.lindex := private.linestyles[rr.linestyle];
	rr.pointstyle := 'star';	
	rr.pindex := private.pointstyles[rr.pointstyle];

	if (is_boolean(style)) {			# not defined
	    rr.style := 'lines';
	    rr.linestyle := 'solid';			# default
	    rr.lindex := private.linestyles[rr.linestyle];
	} else if (is_integer(style)) {			# style index given
	    rr.style := 'points';
	    rr.pointstyle := style;			# assume 0-18....
	} else if (style=='lines') {
	    rr.style := style;
	    rr.linestyle := 'solid';			# default
	    rr.lindex := private.linestyles[rr.linestyle];
	} else if (style=='points') {
	    rr.style := style;
	    rr.pointstyle := 'dot';			# default
	    rr.pindex := private.pointstyles[rr.pointstyle];
	} else if (style=='linespoints') {
	    rr.style := style;
	    rr.linestyle := 'dotted';			# ..?	
	    rr.lindex := private.linestyles[rr.linestyle];
	    # rr.pointstyle := 'star';	
	    rr.pointstyle := 'dot';	
	    rr.pindex := private.pointstyles[rr.pointstyle];
	} else if (style=='arrows') {
	    rr.style := style;
	    rr.linestyle := 'solid';			# default
	    rr.lindex := private.linestyles[rr.linestyle];
	} else if (has_field(private.linestyles,style)) {
	    rr.style := 'lines';
	    rr.linestyle := style;
	    rr.lindex := private.linestyles[style];
	} else if (has_field(private.pointstyles,style)) {
	    rr.style := 'points';
	    rr.pointstyle := style;
	    rr.pindex := private.pointstyles[style];
	} else {
	    print 'decode_plot_style: style not recognised:',style;
	    rr.style := 'lines';
	    rr.linestyle := 'solid';			# default
	    rr.lindex := private.linestyles[rr.linestyle];
	}
	# print 'decode_plot_style:',style,'->',rr;
	return rr;				# return record
    }	    

# Helper routine: display all point styles on the pgplot-widget:

    public.show_point_styles := function (dummy=F) {
	if (!private.check_pgw('pgwaux.show_point_styles')) return F;
	public.bbuf('pgwaux.show_point_styles'); # fill command-buffer
	n := 0;
	npl := 10;
	x := 0;
	public.env(0,npl+2,0,18, axis='none');	# new environment
	for (i in [-31:128]) {
	    n +:= 1;				# increment
	    y := ceil(n/npl);			# 1,2,3,...
	    x +:= 1;
	    if (x > npl) x := 1;
	    s := sprintf('%3i:',i);
	    if (any(i==[-3:-31])) cindex := 2;	# regular polygons
	    if (any(i==[-1:-2])) cindex := 3;	# single dot (current line-width)
	    if (any(i==[0:31])) cindex := 4;	# standard marker symbols
	    if (any(i==[32:127])) cindex := 5;	# ASCII chars
	    if (i > 127) cindex := 6;		# Hershey symbol nr
	    private.pgw.sci(cindex);		# set color index (color)
	    private.pgw.text(x,y,s);
	    private.pgw.sci(1);			# set color index (white)
	    private.pgw.pt(x+0.7,y+0.2,i);
	    # print s,'n=',n,'(x,y)=',x,y;
	}
	public.ebuf('pgwaux.show_point_styles');  # execute command-buffer
	return T;
    }

#=======================================================================
# Helper functions to set and get values:
#=======================================================================
# Get (a copy of or a reference to) the value of the named field:

    public.get := function(name, copy=T) {
	if (has_field(private,name)) {
	    if (copy) return private[name];	# return copy of value
	    return ref private[name];		# return reference (access!)
	} else {
	    s := paste('pgwaux.get(): not recognised',name);
	    print s;
	    fail(s);
	}
    }

    public.get_clitem := function(index=F, fname=F, copy=T) {
	if (!private.check_namindex(index, fname, 'clitem')) return F;
	if (is_string(fname)) {				# field-name
	    return private.clitem[index][fname];	# value
	} else {
	    if (copy) return private.clitem[index];	# return copy of record
	    return ref private.clitem[index];		# return reference (access!)
	}
    }
    public.get_marker := function(index=F, fname=F, copy=T) {
	if (!private.check_namindex(index, fname, 'marker')) return F;
	if (is_string(fname)) {				# field-name
	    return private.marker[index][fname];	# value
	} else {
	    if (copy) return private.marker[index];	# return copy of record
	    return ref private.marker[index];		# return reference (access!)
	}
    }

    private.check_namindex := function (ref index=F, fname=F, rname='clitem') {
	s := spaste('pgwaux.namindex: private.',rname);
	if (!has_field(private,rname)) {
	    print s,'not recognised:',rname;
	    return F;	
	}
	n := len(private[rname]);
	if (is_boolean(index)) val index := n;		# last one
	s := spaste(s,'[',index,'].',fname,':');
	if (index<=0 || index>n) {
	    print s,'out of range:',index,n;
	    return F;	
	} else if (is_string(fname) && !has_field(private[rname][index],fname)) {
	    fnames := field_names(private[rname][index]);
	    print fnames;
	    print [fnames==fname];
	    print s,'not recognised:',fname;
	    return F;	
	}
	return T;					# OK
    }

    
# Set the named field to the given value vv:

    public.set := function(name, vv=F) {
	wider private;
	if (has_field(private,name)) {
	    print 'uvb.set:',name,'->',type_name(vv),shape(vv);
	    private[name] := vv;		# OK, modify value
	    return T;
	} else {
	    s := paste('pgwaux.set(): not recognised',name);
	    print s;
	    fail(s);
	}
    }

    public.set_clitem := function(index=F, name=F, value=F) {
	wider private;
	if (!private.check_namindex(index, fname, 'clitem')) return F;
	if (is_string(name)) {					# field-name
	    private.clitem[index].name := value;		# value
	} else if (is_record(value)) {
	    private.clitem[index] := value;			# clitem record
	} else {
	    return F;
	} 
	return T;
    }

    public.set_marker := function(index=F, name=F, value=F) {
	wider private;
	if (!private.check_namindex(index, fname, 'marker')) return F;
	if (is_string(name)) {					# field-name
	    private.marker[index].name := value;		# value
	} else if (is_record(value)) {
	    private.marker[index] := value;			# marker record
	} else {
	    return F;
	} 
	return T;
    }


#=======================================================================
# Helper functions to deal with command-buffer status:
#=======================================================================

    public.bbuf := function (origin=F, trace=F) {
	wider private; 
	private.check_bebuf();
	private.bebuf.count +:= 1;
	private.pgw.bbuf();				# fill command-buffer
	if (trace || private.bebuf.trace) {
	    s := paste('pgwaux.bbuf(',origin,'):');
	    print s := paste(s,'count=',private.bebuf.count);
	}
	return T;
    }

    public.ebuf := function (origin=F, flush=F, trace=F) {
	wider private; 
	private.check_bebuf();
	private.bebuf.count -:= 1;
	private.pgw.ebuf();				# execute command-buffer
	if (trace || private.bebuf.trace) {
	    s := paste('pgwaux.ebuf(',origin,'):');
	    print s := paste(s,'count=',private.bebuf.count);
	}
	if (flush) public.flush_bebuf(origin=origin, trace=trace);
	return T;
    }

    public.flush_bebuf := function (origin=F, trace=F) {
	wider private;
	trace := (trace || private.bebuf.trace); 
	s := paste('pgwaux.flush_bebuf(',origin,'):');
	if (trace) print s := paste(s,'count=',private.bebuf.count);
	while (private.bebuf.count>0) {
	    private.bebuf.count -:= 1;
	    private.pgw.ebuf();				# execute command-buffer
	    if (trace) print s := paste(s,'ebuf(): count=',private.bebuf.count);
	}
    }

    private.check_bebuf := function () {
	wider private;
	if (!has_field(private,'bebuf')) {
	    private.bebuf := [=];
	    private.bebuf.count := 0;
	    private.bebuf.trace := F;           # set T for debugging
	}
	return T;
    }

#=======================================================================
# Finished. Initialise and return the public interface:

    private.init();				# initialise
    return ref public;				# ref?

};				# closing bracket of jenplot_pgwaux
#=======================================================================




#=========================================================
test_jenplot_pgwaux := function (nexp=1) {
    private := [=];
    public := [=];
    print '\n\n\n\n ******** test_jenplot_pgwaux, nexp=',nexp;

    include 'jenplot_plot1D.g';

    pga := jenplot_pgwaux();

    private.callback := function (rec=F) {
	print '\n\n inside user callback: rec=\n',rec,'\n\n';
	return 'user return-value';
    }

    private.legend := F;

    if (nexp==1) {
	pga.attach_pgw();
	pga.env();				# draws axes
	pga.setcallback(action='button', region='left_margin',
			button=1, callback=private.callback);
	pga.clitem(x=0, y=0, text='xy=[0,0]');
	pga.xannot(xx=[-5:7]/10);
	for (i in [1:3]) pga.legend(private.legend,
				    paste('legend line',i));
	pga.legend(private.legend, 'plot-title',title=T);
	pga.draw_legend(private.legend);
	pga.marker(x=0);
	pga.marker(y=0);
	pga.yannot();				# reset
	yy := [];
	label := ' ';
	n := 0;
	for (y in [-2,-1,1,2]/3) {
	    yy[n+:=1] := y;
	    label[n] := spaste('y=',yy[n]);
	    pga.yannot(y=yy[n], label=label[n], yval=yy[n]);
	}
	pga.marker(x=-yy, y=yy, label=label);
				    

    } else if (nexp==2) {
	uvp := jenplot_plot1D();
	uvp.gui('test_jenplot_pgwaux');
	pga.attach_pgw(uvp);

    } else if (nexp==3) {
	pga.env(axis='none');

    } else if (nexp==4) {
	pga.show_plot_colors();

    } else if (nexp==5) {
	pga.show_point_styles();

    }
     
    return ref pga;
};




#===========================================================
#===========================================================

# pga := test_jenplot_pgwaux();		# run test-routine
# inspect(jenplot_pgwaux(),'jenplot_pgwaux');# create and inspect

#===========================================================
# Remarks and things to do:
#================================================================


