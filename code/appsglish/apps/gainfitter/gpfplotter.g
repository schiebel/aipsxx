# gpfplotter.g: gain table plotter for gainpolyfitter
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
# $Id: gpfplotter.g,v 19.1 2004/08/25 01:16:40 cvsmgr Exp $
pragma include once;

include "note.g";
include 'itemmanager.g';
# include 'gainpolyfitter.g';
include 'unset.g';

const GPFP_COLORS := [white=0, black=1, red=2, green=3, blue=4, cyan=5,
		      magenta=6, yellow=7, orange=8];
const GPFP_MARKERS := [square=0, dot=1, plus=2, asterisk=3, circle=4,
		       x=5, square2=6, triangle=7, circle_plus=8,
		       circle_dot=9, diamond=10, star=12,
		       filledtriangle=13, filledsquare=16,
		       filledstar=18, leftarrow=28, rightarrow=29,
		       uparrow=30, downarrow=31, bigdot=-8];
const GPFP_LINESTYLES := [none = 0, solid = 1, dashed = 2, dotdash = 3,
			  dotted = 4, dashdot = 5];

#@itemcontainer GainPolyFitterPlotterOptionsItem
# contains options for configuring the default behavior of a gainpolyfitter
# plotter.  Users normally do not create these items themselves; they are used
# primarily for creating a gpfplotter tool specialized for 
# certain circumstances.  The gpfplotter.getoptions() function will 
# return an itemcontainer of this type.
# @field type       must be set to 'GainPolyFitterPlotterOptionsItem'
# @field nxsubs     default number of plots per view in the horizontal direction
# @field nysubs     default number of plots per view in the veritcal direction
# @field linestyle  linestyle for plotting gains
# @field errorbar_scale  the scale to give to errorbars
# @field showzero   if true, the zero amp/phase line will be shown
# @field clipfit    if true, the bounds of the box will not be enlarged to 
#                      contain the entire fit curve, but only enough to show
#                      all gain data.
# @field horaxes    a list of the name of the axes to iterate along the 
#                      horizontal plot axis; plots with different combinations 
#                      of axis values will be displayed in different columns.
#                      All other axes will be mapped to the vertical direction.

const DEFAULT_GPFPLOTTEROPTIONS := [type='GainPolyFitterPlotterOptionsItem',
			      linestyle='solid', nxsubs=3, nysubs=4,
			      errorbarscale=0.0, showzero=F, clipfit=F,
			      showfit=T, clipmasked=T,
			      horaxes="Ant", winmar=[0.0, 0.0, 0.0, 0.05],
			      plotmar=[2.05, 0.2, 1.5, 1.5], charht=1.0 ];

const gpfplotter := function(ref gpftool, options=F) {
    gpf := gpftool;
    private := [=];
    public := [=];

    private.opts := itemmanager(type='GainPolyFitterPlotterOptionsItem',
				name='gpfpoptions');
    private.opts.fromrecord(DEFAULT_GPFPLOTTEROPTIONS);
    if (is_record(options)) private.opts.fromrecord(options);
    private.opts.settell(T);

    private.sellisteners := listenermanager('gpfpselection');
    private.axes := [=];
    private.selupd := T;
    private.panels := [vp=array([0.1,0.9,0.1,0.9],1,1,4), 
		       win=array([0.0,1.0,0.0,1.0],1,1,4), nxy=[1,1],
		       winmar=rep(0.0, 4), plotmar=rep(0.0, 4), 
		       pansz=[1.0,1.0], tlc=[1,1]];

    private.initgpf := function() {
	wider gpf, private, public;
	local axnames := gpf.fitsetaxes();
	local axn, axvals, axv;

	private.axes.Component := [=];
	private.axes.Component.vals := GPF_COMPVALUES;
	private.axes.Component.sel := rep(T, len(GPF_COMPVALUES));
	for (axn in axnames) {
	    private.axes[axn] := [=];
	    private.axes[axn].vals := gpf.axisvals(axn);
	    private.axes[axn].sel  := rep(T, len(private.axes[axn].vals));
	}

	private.istime := F;
	if (gpf.getdomaintype() == 'epoch') private.istime := T;
	private.xrange := gpf.getdomain(absolute=F);
	local tmp := private.xrange[2] - private.xrange[1];
	private.xrange[1] -:= tmp / 20.0;
	private.xrange[2] +:= tmp / 20.0;

#	public.selectall();
	private.updateplotindex();

	return T;
    }

    private.updateplotindex := function() {
	wider gpf, private;

	private.lookup := [rows=[=], rowtags=[=], cols=[=], coltags=[=], 
			   engine=[=], plot=[=], tlc=[1,1]];

	# initialize our iterator ant get the state of the buttons
	local ax, axv, ok;
	local axvals := [=];
	local selected := [=];
	local axnames := field_names(private.axes);
	local iter := [=];
	local lim := [=]; 
	local tags := [=];
	for(ax in axnames) {
	    axvals[ax] := private.axes[ax].vals;
	    selected[ax] := private.axes[ax].sel;
	    tags[ax] := gpf.getaxisdecoritem(ax, 'tags');

	    iter[ax] := 1;
	    lim[ax] := length(axvals[ax]);

	    # if all buttons are off for any axis, then we have no plots;
	    # short-circuit.
	    if (! any(private.axes[ax].sel)) {
		return T;
	    }
	}

	# check the config option specifying which axes appear along 
	# the horizontal direction in the plot display
	local i;
	local rec, tag;
	local horaxes := "";
	for(ax in private.opts.get('horaxes')) {
	    if (any(ax == axnames)) horaxes[length(horaxes)+1] := ax;
	}
	if (length(horaxes) == 0) horaxes := axnames[1];

	# work out columns: iterate over axes to appear along the horizontal
	# direction.
	i := 1;
	local nax := length(horaxes);
	while (iter[horaxes[nax]] <= lim[horaxes[nax]]) {
	    rec := [=];
	    tag := [=];
	    for (ax in horaxes) {
		rec[ax] := axvals[ax][iter[ax]];
		tag[ax] := tags[ax][iter[ax]];
		if (! selected[ax][iter[ax]]) {
		    rec := F;
		    break;
		}
	    }
	    if (! is_boolean(rec)) {
		private.lookup.cols[i] := rec;
		private.lookup.coltags[i] := tag;
		i +:= 1;
	    }

	    iter[horaxes[1]] +:= 1;
	    if (iter[horaxes[1]] > lim[horaxes[1]] && nax > 1) {
		for(j in 1:(nax-1)) {
		    if (iter[horaxes[j]] > lim[horaxes[j]]) {
			iter[horaxes[j+1]] +:= 1;
			iter[horaxes[j]] := 1;
		    }
		}
	    }
	}

	# now work out rows: step through all the axes not incremented
	# along the horizontal direction.
	local veraxes := "";
	i := 1;
	for (ax in axnames) {
	    if (! any(ax == horaxes)) {
		veraxes[i] := ax;
		i +:= 1;
	    }
	}

	local nax := length(veraxes);
	i := 1;
	while (iter[veraxes[nax]] <= lim[veraxes[nax]]) {
	    rec := [=];
	    tag := [=];
	    for (ax in veraxes) {
		rec[ax] := axvals[ax][iter[ax]];
		tag[ax] := tags[ax][iter[ax]];
		if (! selected[ax][iter[ax]]) {
		    rec := F;
		    break;
		}
	    }
	    if (! is_boolean(rec)) {
		private.lookup.rows[i] := rec;
		private.lookup.rowtags[i] := tag;
		i +:= 1;
	    }

	    iter[veraxes[1]] +:= 1;
	    if (iter[veraxes[1]] > lim[veraxes[1]] && nax > 1) {
		for(j in 1:(nax-1)) {
		    if (iter[veraxes[j]] > lim[veraxes[j]]) {
			iter[veraxes[j+1]] +:= 1;
			iter[veraxes[j]] := 1;
		    }
		}
	    }
	}

	# now create the direct index to the fit engine
	local dispshape := [length(field_names(private.lookup.cols)), 
			    length(field_names(private.lookup.rows)) ];
	private.lookup.engine := [=];
	private.lookup.plot  := [=];
	local panel, idx;
	for (i in 1:(dispshape[1])) {
	    for (j in 1:(dispshape[2])) {
		rec := private.lookup.rows[j];
		panel := [i, j];
		for(ax in field_names(private.lookup.cols[i])) 
		    rec[ax] := private.lookup.cols[i][ax];
		idx := gpf.indexbyname(rec);
		private.lookup.engine[paste(as_string(panel))] :=
		    [fit=idx, comp=rec.Component];
		private.lookup.plot[paste(as_string(idx),rec.Component)] :=
		    panel;
	    }
	}

	private.selupd := F;
	return T;
    }

    #@ 
    # return the number of plots currently selected for display in the 
    # horizontal and vertical directions
    # @return 2-element integer array containing the number of plots in 
    #            the x- and y-directions, respectively.
    ##
    public.getselectshape := function() {
	return [length(field_names(private.lookup.cols)), 
		length(field_names(private.lookup.rows)) ];
    }

    #@
    # update the internal parameters (for the latest changes in 
    # plot selection).  This will update the selection shape returned 
    # by getselectshape().
    ##
    public.updatetoselect := function() {
	wider private;
	local ok := T;
	if (private.selupd) ok := private.updateplotindex();
	return ok;
    }

    #@ 
    # reset the viewport to the given panel
    # @param pgp    the pgplotmanager tool to plot to
    # @param xpan   the panel index along the horizontal direction
    # @param ypan   the panel index along the vertical direction
    ##
    public.setpanelvp := function(pgp, xpan, ypan) {
	wider private;
	if (xpan > private.panels.vp::shape[1] || xpan < 1 ||
	    ypan > private.panels.vp::shape[2] || ypan < 1 ||
	    all(private.panels.vp[xpan, ypan, 1:4] == 0.0))
	  fail paste('setpanelvp: requested panel not visible:', [xpan, ypan]);

	local vp := private.panels.vp[xpan, ypan, 1:4];
	local win := private.panels.win[xpan, ypan, 1:4];
	pgp.svp(vp[1], vp[2], vp[3], vp[4]);
	pgp.swin(win[1], win[2], win[3], win[4]);
	    
	return T;
    }

    #@ 
    # return the panel at a given device coordinate position
    # @param pgp  the pgplotmanager tool in use
    # @param x    the x position in device pixel coordinates
    # @param y    the y position in device pixel coordinates
    # @return 2-element integer array identifying the panel
    ##
    public.devicetopanel := function(pgp, x, y) {
	wider private;
	local n := [1,1];

	# convert to normalized device coordinates
	local ndc := pgp.qvsz(3);
	x /:= 1.0*ndc[2];
	y /:= 1.0*ndc[4];

	x -:= private.panels.winmar[1];
	y -:= private.panels.winmar[3];
	local n := as_integer(ceil( [ 1.0 * x / private.panels.pansz[1],
				      1.0 * y / private.panels.pansz[2] ] ));
	if (n[1] < 1) 
	    n[1] := 1;
	else if (n[1] > private.panels.nxy[1]) 
	    n[1] := private.panels.nxy[1];
	if (n[2] < 1) 
	    n[2] := 1;
	else if (n[2] > private.panels.nxy[2]) 
	    n[2] := private.panels.nxy[2];

	return n;
    }

    #@
    # determine the (sub-panel) world coordinates associated with the position 
    # specified by an X-event position.  This implicitly calls setpanelvp().
    # @param pgp        the pgplotwidget that produced the event
    # @param input      the $value record from pgplotwidget X-event.
    # @param full       if true, add extra information to the returned record,
    #                      including whether it is inside the plot box, the
    #                      plot's title, and the nearest 
    # @return record containing the device, world, and panel positions.  F is
    #                   is returned if the position is undefined.
    ##
    public.inputtoworld := function(pgp, input, full=F) {
	wider private, public;
	local out := [device=input.device];

	# determine which panel the position falls in.
	out.panel := public.devicetopanel(pgp,input.device[1],input.device[2]);
	if (is_fail(out.panel)) {
	    print out.panel;
	    return F;
	}

	# Move the "pen" to the position of the event
	pgp.move(input.world[1], input.world[2]);

	# reset the world coordinate space to that of the panel
	public.setpanelvp(pgp, out.panel[1], out.panel[2]);

	# get the world coordinates
	out.world := pgp.qpos();

	if (! full) return out;

	# is it inside the plot box?
	out.insidebox := (out.world[1]>=private.panels.win[out.panel[1],
							   out.panel[2],1] &&
			  out.world[1]<=private.panels.win[out.panel[1],
							   out.panel[2],2] &&
			  out.world[2]>=private.panels.win[out.panel[1],
							   out.panel[2],3] &&
			  out.world[2]<=private.panels.win[out.panel[1],
							   out.panel[2],4]   );

	# panel title, fitindex, & isampreal
	public.panelinfo(out.panel[1], out.panel[2], out);

	# nearest point
	if (out.insidebox) {
	    wider gpf;
	    local data := gpf.getdata(out.fitindex);
	    out.nearest := as_double([]);
            out.nearest[1] := gpfnearestvalue(out.world[1], data.x);
	
            local ydata := data.g2;
            if (out.isampreal) ydata := data.g1;
            ydata := ydata[data.x == out.nearest[1]];
            if (len(ydata) == 1) {
                out.nearest[2] := ydata;
            } else {
                out.nearest[2] := gpfnearestvalue(out.world[2], ydata);
            }
	}

	return out;
    }

    #@ 
    # return various info about the plot at the given panel position.
    # The returned record contains field names fitindex, isampreal, & title.
    # @param xpan   the panel index along the horizontal direction
    # @param ypan   the panel index along the vertical direction
    # @param rec   a record that, if provided, will be filled with the 
    #                 information.  
    # @return record containging information.  If rec was provided is will
    #                 be the record that is returned.
    ##
    public.panelinfo := function(xpan, ypan, ref rec=[=]) {
	wider private;
	if (!is_record(rec)) rec := [=];
	local panidx := paste(as_string([xpan, ypan]));
	if (! has_field(private.panels.atts, panidx)) return F;
	rec.fitindex := private.panels.atts[panidx].fitindex;
	rec.isampreal := private.panels.atts[panidx].isampreal;
	rec.title := private.panels.atts[panidx].title;
	return rec;
    }

    #@
    # return the fit engine and gain component associated with a given panel
    # @param xpan   the panel index along the horizontal direction
    # @param ypan   the panel index along the vertical direction
    # @return record  with fields fit=fit index and comp=fit component 
    #                   (Amp or Phase).
    ## 
    public.paneltofit := function(xpan, ypan) {
	wider private;
	wider private;
	local panidx := paste(as_string([xpan,ypan]));
	if (! has_field(private.panels.atts, panidx)) 
	    fail paste('paneltofit: panel out of range:', panidx);

	local out := [fit=private.panels.atts[panidx].fitindex];
	out.comp := GPF_COMPVALUES[1];
	if (private.panels.atts[panidx].isampreal) 
	    out.comp := GPF_COMPVALUES[2];
	return out;
    }

    #@ 
    # return the fit engine index associated with a given panel
    # @param xpan   the panel index along the horizontal direction
    # @param ypan   the panel index along the vertical direction
    ##
    public.paneltofitindex := function(xpan, ypan) {
	wider private;
	local panidx := paste(as_string([xpan,ypan]));
	if (! has_field(private.panels.atts, panidx)) 
	    fail paste('paneltofit: panel out of range:', panidx);
	return private.panels.atts[panidx].fitindex;
    }

    #@
    # @param plotidx  the 2-element integer vector identifier for plot
    ##
    private.plottofit := function(plotidx) {
	wider private;
	local plot := paste(as_string(plotidx));
	if (! has_field(private.lookup.engine, plot)) {
	    fail paste('plottofit: plot index out of range:', plot);
	}
	return private.lookup.engine[plot];
    }

    #@
    # return the panel location associated with a given fit engine index and 
    #    component.
    # @param fitindex   the fit engine index (as returned by 
    #                      gainpolyfitter.indexbyname()).
    # @param ampreal    if true, the panel associated with the amplitude (or
    #                      real) component of the fit; otherwise, return the
    #                      phase (or imaginary) component.  The default is F.
    # @return 2-element integer vector representing the x and y location of
    #                      the panel.
    ##
    public.fittopanel := function(fitindex, ampreal=F) {
	wider private;
	local comp := GPF_COMPVALUES[1];
	if (ampreal) comp := GPF_COMPVALUES[2]; 
	local idxstr := paste(fitindex,comp);
	if (! has_field(private.panels.whereis, idxstr)) {
	    fail paste('fittopanel: fit engine index/component not selected:',
		       fitindex, comp);
	}
	return private.panels.whereis[idxstr];
    }

    private.fittoplot := function(fitindex, ampreal=F) {
	local comp := GPF_COMPVALUES[1];
	if (ampreal) comp := GPF_COMPVALUES[2]; 
	local idxstr := paste(as_string(fitindex),comp);
	if (! has_field(private.lookup.plot, idxstr))  return F;

	return private.lookup.plot[idxstr];
    }

    #@ 
    # create a plot title string from the associated axis labels.  The 
    # string returned is ultimately controled by the axis decoration
    # options set with the gainpolyfitter tool.
    # @param plot  a 2-element array giving x and y positions of panel
    ##
    private.createtitleforplot := function(plot) {
	wider private;
	local title := as_string([]);
	local f;
	for(f in field_names(private.lookup.coltags[plot[1]])) 
	    title[length(title)+1] := private.lookup.coltags[plot[1]][f];
	for(f in field_names(private.lookup.rowtags[plot[2]])) 
	    title[length(title)+1] := private.lookup.rowtags[plot[2]][f];
	title := spaste(title, sep='  ');

	return title;
    }

    #@ 
    # create a plot title string from a given fit.  The 
    # string returned is ultimately controled by the axis decoration
    # options set with the gainpolyfitter tool.
    # @param fitindex   the fit engine index (as returned by 
    #                      gainpolyfitter.indexbyname()).
    # @param ampreal    if true, the panel associated with the amplitude (or
    #                      real) component of the fit; otherwise, return the
    #                      phase (or imaginary) component.  The default is F.
    ##
    public.createtitleforfit := function(fitindex, ampreal=F) {
	wider private;
	local plot := private.fittoplot(fitindex, ampreal);
	if (is_boolean(plot)) {
	    fail paste('createtitleforfit: fit engine index/component', 
		       'not selected:', fitindex, comp);
	}
	return private.createtitleforplot(plot);
    }

    #@
    # erase the current panel
    # @param pgp   the pgplotmanager tool send erase commands to
    ##
    public.erase := function(pgp, plotmar=F) {
	local vp := F;
	pgp.save();
	pgp.bbuf();

	pgp.sci(0);
	pgp.sfs(1);

	if (! is_boolean(plotmar)) {
	    vp := pgp.qvp(0);
	    local tmp := pgp.qcs(0);
	    plotmar[[1,2]] *:= tmp[1];
	    plotmar[[3,4]] *:= tmp[2];
	    pgp.svp(vp[1]-plotmar[1], vp[2]+plotmar[2], 
		    vp[3]-plotmar[3], vp[4]+plotmar[4]);
	}

	local win := pgp.qwin();
	pgp.rect(win[1], win[2], win[3], win[4]);

	if (! is_boolean(vp)) 
	    pgp.svp(vp[1],vp[2],vp[3],vp[4]);

	pgp.ebuf();
	pgp.unsa();
	return T;
    }

    #@ 
    # draw the plot for one gain component into the current window
    # @param pgp        the pgplotmanager tool to plot to
    # @param fitindex   the index to the fitengine to plot
    # @param doampreal  if true, plot the first--amplitude or real--component
    #                      of the gains; otherwise, plot the second--phase
    #                      or imaginary--component.
    # @param labelx     if true (the default), include the x-axis labels
    # @param title      the title string to place at the top of the plot.  If
    #                      unset (the default), a default will be created.
    # @param window     if provided, this float array will be filled with the
    #                      the world coordinate space covered by the plot's 
    #                      viewport.
    ##
    public.drawplot := function(pgp, fitindex, doampreal, labelx=T, 
				title=unset, ref window=0.0) 
    {
	wider private, public, gpf;

	local samp := gpf.getsampling(fitindex);
	local obs :=  gpf.getdata(fitindex);
	local comp := "g2";
	if (doampreal) comp := "g1";
	if (! has_field(obs, 'mask')) obs.mask := rep(T, length(obs.x));
	if (is_unset(title)) 
	    title := public.createtitleforfit(fitindex, doampreal);
	if (len(title) > 0) title := paste(title);

	# set error data (needed for yrange)
	local edata;
	local escale := private.opts.get('errorbarscale', 0.0);
	if (comp == 'g2') {
	    if (has_field(obs, 'err2')) {
		edata := obs.err2;
	    } else if (has_field(obs, 'err')) {
		edata := obs.err;
	    }
	}
	else if (has_field(obs, 'err')) {
	    edata := obs.err;
	}
	else {
	    escale := 0.0;
	    edata := rep(0.0, len(obs[comp]));
	}
	edata[edata == 1.0/0] := 0.0;

	# determine world coordinate space
	local tmp := edata;
	if (private.opts.get('clipmasked', T)) tmp[!obs.mask] := 0.0;
	local yrange := [min(obs[comp] - escale*tmp), 
			 max(obs[comp] + escale*tmp)];
	if (! private.opts.get('clipfit', F)) {
	    tmp := min(samp[comp]);
	    if (yrange[1] > tmp) yrange[1] := tmp;
	    tmp := max(samp[comp]);
	    if (yrange[2] < tmp) yrange[2] := tmp;
	}
	if (private.opts.get('showzero', F)) {
	    if (yrange[1] > 0.0) 
		yrange[1] := 0.0;
	    else if (yrange[2] < 0.0)
		yrange[2] := 0.0;
	}
	tmp := yrange[2] - yrange[1];
	yrange[1] -:= tmp / 20.0;
	yrange[2] +:= tmp / 20.0;
	val window := [ private.xrange[1], private.xrange[2], 
		        yrange[1], yrange[2] ];

#	public.erase(pgp);
	pgp.swin(window[1], window[2], window[3], window[4]);

	# remember old plot environment
	pgp.save();
	pgp.bbuf();
	
	# draw the box
	local ls, marker, lw, msz;
	local box := "";
	if (labelx) {
	    if (gpf.getdomaintype() == 'epoch') 
		box[1] := 'BCNSTZYHO';
	    else 
		box[1] := 'BCNST';
	} else {
	    box[1] := 'BCST';
	}
	box[2] := 'BCNST';
	local yt := 0.0;
	local yst := 0;
	if (yrange[2]-yrange[1] < 0.1) {
	    local p := 10;
	    while (p*(yrange[2]-yrange[1]) < 1) {
		p *:= 10;
	    }
	    yt := floor(p*(yrange[2]-yrange[1]))/(2.0*p);
	    yst := 5;
	}

	lw := private.opts.get('linewidth', 1);
	pgp.slw(lw);
#	pgp.sch(1.25);
	pgp.tbox(box[1], 0, 0, box[2], yt, yst);
	if (strlen(title) > 0) pgp.mtxt('T', 0.3, 0, 0, title);

	# plot the data
	pgp.sci(private.decodeColor(private.opts.get('unmaskedcolor', 
						     'black')));
	marker := private.decodeMarker(private.opts.get('unmaskedmarkertype', 
							'dot'));
	ls := private.decodeLinestyle(private.opts.get('linestyle', 'solid'));
	msz := private.opts.get('unmaskedmarker_size', 1);

	# put down unmasked data markers
	local xdata := obs.x;
	if (has_field(obs, 'xscale')) xdata *:= obs.xscale;
	if (! is_numeric(xdata) || ! is_numeric(obs[comp])) {
	    note('non-numeric data found for plot "', title, '"',
		 priority='WARN', origin='gpfplotter');
	    pgp.ebuf(); pgp.unsa();
	    return F;
	}
	if (len(obs.mask) != len(xdata) || len(obs.mask) != len(obs[comp])) {
	    note('inconsistant amount of data for plot "', title, '"',
		 priority='WARN', origin='gpfplotter');
	    pgp.ebuf(); pgp.unsa();
	    return F;
	}
	private.plotpts(pgp, xdata[obs.mask], obs[comp][obs.mask], marker, 
			msz, lw);

	if (escale > 0) {
	    local mask := obs.mask & (edata != 0);
	    pgp.erry(xdata[mask],
		     obs[comp][mask]-(escale*edata[mask]),
		     obs[comp][mask]+(escale*edata[mask]),
		     private.opts.get('errorhatlength', 3.0)); 
	}

	# connect data with lines as necessary
	if (ls > 0) {
	    pgp.sls(ls);
	    pgp.line(xdata[obs.mask], obs[comp][obs.mask]);
	}
	    
	# put down masked data markers
	if (length(xdata[!obs.mask]) > 0) {
	    pgp.sci(private.decodeColor(private.opts.get('maskedcolor', 
							 'red')));
	    marker :=private.decodeMarker(private.opts.get('maskedmarkertype', 
							   'dot'));
	    msz := private.opts.get('maskedmarker_size', msz);

	    private.plotpts(pgp, xdata[!obs.mask], obs[comp][!obs.mask], 
			    marker, msz, lw);
	    if (escale > 0) {
		local mask := (!obs.mask) & edata!=0.0;
#		if (any(edata == (1.0/0))) mask &:= edata != (1.0/0);
		if (any(mask))
		    pgp.erry(xdata[mask],
			     obs[comp][mask]-(escale*edata[mask]),
			     obs[comp][mask]+(escale*edata[mask]),
			     private.opts.get('errorhatlength', 3.0));
	    }
	}

	# plot breakpoints
	data := gpf.getbreakpoints(fitindex);
	if (len(data) > 0) {
	    pgp.sci(private.decodeColor(private.opts.get('breakcolor', 
							'yellow')));
	    pgp.sls(1);
	    for (x in data) {
		if (x >= private.xrange[1] && x <= private.xrange[2])
		    pgp.line([x,x], yrange);
	    }
	}

	# plot sampled data, breaking them up into intervals between
	# break points
	if (private.opts.get('showfit')) {
	    pgp.sci(private.decodeColor(private.opts.get('samplecolor', 
							 'magenta')));
	    pgp.sls(GPFP_LINESTYLES.solid);
	    local min := min(samp.x);
	    local maxi := ind(data)[data>min];
	    if (len(maxi) == 0) {
		pgp.line(samp.x[samp.mask],samp[comp][samp.mask]);
	    }
	    else {
		local mask;
		local max := max(samp.x);
		maxi := maxi[1];
		while (min < max && maxi <= len(data)) {
		    mask := (samp.mask & samp.x >= min & samp.x < data[maxi]);
		    pgp.line(samp.x[mask], samp[comp][mask]);
		    min := data[maxi];
		    maxi +:= 1;
		}
		if (min < max) {
		    mask := (samp.mask & samp.x >= min & samp.x < max);
		    pgp.line(samp.x[mask], samp[comp][mask]);
		}
	    }
	}

	pgp.ebuf();
	pgp.unsa();

	return T;
    }

    private.plotpts := function(pgp, xdata, ydata, marker, size, lw=1) {
	pgp.save();
	if (marker < 0 && size > lw) 
	    pgp.slw(floor(size+0.5));
	else if (size > 1) 
	    pgp.sch(pgp.qch()*size);

	pgp.pt(xdata, ydata, marker);
	pgp.unsa();

	return T;
    }

    #@
    # plot the currently selected fit sets onto a grid within the plot device
    # @param pgp        the pgplotmanager tool to plot to
    # @param nxsubs   the number of plots in the horizontal direction per page;
    #                    if not specified, the value of the nxsubs option will
    #                    be used.
    # @param nysubs   the number of plots in the vertical direction per page;
    #                    if not specified, the value of the nysubs option will
    #                    be used.
    # @param title    the title string to place at the top of the page; if an
    #                    empty string (the default), no title will be 
    #                    displayed.
    # @param page     if true (the default), include a tag indicating the 
    #                    page number.
    # @param xlabfreq the frequency with which to place the x-axis labeling. A
    #                    value of 1 puts labeling on every plot, while a value
    #                    equal to nysubs puts labeling only along the 
    #                    bottom-most row.  The default is the value of nysubs.
    # @param charht   the character height to use for the plot labels.  If
    #                    not provided the value set by the charht option
    #                    will be used.
    # @param winmar   the window margins to use; this is given as a 4-element
    #                    numeric array giving, in order, the left, right, 
    #                    bottom, and top margins in fractional units of the 
    #                    viewable window (i.e. NDC units).
    # @param plotmar  the plot margins to use in units of character height; 
    #                    this is given as a 4-element numeric array giving, 
    #                    in order, the left, right, bottom, and top margins.  
    #                    These margins mark the distance from the plot panel 
    #                    edges to its viewport box.
    ##
    public.plotfits := function(pgp, nxsubs=F, nysubs=F, title='', page=T,
				xlabfreq=F, charht=F, winmar=F, plotmar=F) 
    {
	wider public, private, gpf;
	if (! is_string(title)) title := '';
	if (len(title) > 0) title := paste(title);
	if (! is_boolean(page)) page := F;

	# update the plot index (if necessary);
	if (private.selupd) private.updateplotindex();

	# determine layout per page
	if (! is_integer(nxsubs)) nxsubs := private.opts.get('nxsubs');
	if (! is_integer(nysubs)) nysubs := private.opts.get('nysubs');
	if (! is_integer(xlabfreq)) xlabfreq := nysubs;
	private.panels.nxy := [nxsubs, nysubs];

	local mar := private.opts.get('winmar');
	if (is_boolean(winmar)) winmar := mar;
	if (! is_numeric(winmar)) 
	    fail paste('plotfits: non-numeric winmar margins:', winmar);
	winmar := 1.0 * winmar;
	if (len(winmar) < 4) {
	    mar[1:len(winmar)] := winmar;
	    winmar := mar;
	}
	private.panels.winmar := winmar;

	mar := private.opts.get('plotmar');
	if (is_boolean(plotmar)) plotmar := mar;
	if (! is_numeric(plotmar)) 
	    fail paste('plotfits: non-numeric plotmar margins:', plotmar);
	plotmar := 1.0 * plotmar;
	if (len(plotmar) < 4) {
	    mar[1:len(plotmar)] := plotmar;
	    plotmar := mar;
	}
	private.panels.plotmar := plotmar;

	local pansz := [ (1.0-winmar[1]-winmar[2])/nxsubs, 
			 (1.0-winmar[3]-winmar[4])/nysubs ];
	private.panels.pansz := pansz;

	if (is_boolean(charht)) charht := private.opts.get('charht');
	private.panels.charht := charht;
	mar := pgp.qcs(0);
	plotmar[[1,2]] *:= mar[1];
	plotmar[[3,4]] *:= mar[2];

	pgp.save();
	pgp.sch(charht);
	private.panels.charht := charht;

#	# clear the page
#	public.erase();

	# step through each selected fit set
	local i, j, fit, comp, vp, subtitle, panidx;
	local labelx := T;
	local n := [1, 1];
	private.lookup.tlc := n;
	local np := [len(private.lookup.cols), len(private.lookup.rows)];
	local npg := ceil(1.0*np / [nxsubs, nysubs]);
	npg := npg[1]*npg[2];
	local pg := 1;
	np +:= 1;

	private.panels.vp := array(0.0, np[1], np[2], 4);
	private.panels.win := array(0.0, np[1], np[2], 4);
	private.panels.atts := [=];
	private.panels.whereis := [=];

	while (n[1] < np[1]) {

	  # go to new page (subject to ASK prompt state)
	  pgp.page();
	  pgp.svp(winmar[1], 1.0-winmar[2], winmar[3], 1.0-winmar[4]);
	  pgp.swin(0, 1.0, 0, 1.0);
#	  pgp.box('BC', 0, 0, 'BC', 0, 0);    # for debugging layout
	  if (strlen(title) > 0) {
	      pgp.save();
	      pgp.sch(1.25);
	      pgp.mtxt('T', 0.5, 0.5, 0.5, title);
	      pgp.unsa();
	  }
	  if (page) pgp.mtxt('T', 0.5, 1.0, 1.0, paste('page', pg, 'of', npg));

	  n := private.lookup.tlc;
	  for (i in 1:nxsubs) {
	    n[2] := private.lookup.tlc[2];
	    for (j in 1:nysubs) {
#		fitidx := public.paneltoindex(n[1], n[2]);
		panidx := paste(as_string(n));
		if (! has_field(private.lookup.engine, panidx)) {
		    fail paste('plotfits: prog. error: plot index out of', 
			       'range:', panidx);
		}
		fit := private.lookup.engine[panidx];
		private.panels.atts[panidx].fitindex := fit.fit;
		private.panels.atts[panidx].plot := n;
		private.panels.whereis[paste(fit.fit, fit.comp)] := n;

		# determine which component this is 
		comp := (fit.comp == GPF_AMP || fit.comp == GPF_REAL);
		private.panels.atts[panidx].isampreal := comp;

		# set the panel (storing away the vp parameters)
		vp := ref private.panels.vp[n[1], n[2], 1:4];
		val vp := [ winmar[1] + (i-1)*pansz[1] + plotmar[1],        
			    winmar[1] + i*pansz[1]     - plotmar[2],        
			    winmar[3] + (nysubs-j)*pansz[2]   + plotmar[3], 
			    winmar[3] + (nysubs-j+1)*pansz[2] - plotmar[4]  ];
		pgp.svp(vp[1], vp[2], vp[3], vp[4]);

		# place x-axis label on this one?
		labelx := ((j % xlabfreq) == 0);
		private.panels.atts[panidx].labelx := labelx;

		# get (and remember) a title for the subplot
		subtitle := private.createtitleforplot(n);
		private.panels.atts[panidx].title := subtitle;

		# draw plot into panel
		public.drawplot(pgp, fit.fit, comp, labelx, title=subtitle,
				window=private.panels.win[n[1],n[2],1:4]);

		n[2] +:= 1;
		if (n[2] >= np[2]) break;
	    }
	    n[1] +:= 1;
	    if (n[1] >= np[1]) break;
#	    n[2] := private.lookup.tlc[2];
	  }

	  if (n[2] < np[2]) {
	      private.lookup.tlc[2] := n[2];
	  } else if (n[1] < np[1]) {
	      private.lookup.tlc[1] := n[1];
	      private.lookup.tlc[2] := 1;
#	      n[2] := private.lookup.tlc[2];
	  }
	  pg +:= 1;
        }

	pgp.svp(winmar[1], 1.0-winmar[2], winmar[3], 1.0-winmar[4]);
	pgp.swin(0, 1.0, 0, 1.0);

	pgp.unsa();
	return T;
    }

    #@
    # return the layout parameters in use for the current matrix of plots
    # @return record containing the fields:
    #                <pre>
    #                  winmar   an array giving the left, right, bottom, and
    #                              top margins for the full canvas (see 
    #                              winmar options description).
    #                  plotmar  an array giving the margins for each individual
    #                              plot panel (see plotmar options 
    #                              description).
    #                  charht   the character height
    #                  nxy      a 2-element array giving the number of plot
    #                              panels along the x and y axes.
    #                  panelsize  a 2-element array giving the width and height
    #                              of each individual plot panel.
    #                </pre>
    ##
    public.getlayout := function() {
	wider private;
	return [winmar=private.panels.winmar, plotmar=private.panels.plotmar,
		charht=private.panels.charht, nxy=private.panels.nxy, 
		panelsize=private.panels.pansz];
    }

    #@ 
    # redraw the given panel
    # @param pgp   the pgplotmanager to draw to
    # @param xpan   the panel index along the horizontal direction
    # @param ypan   the panel index along the vertical direction
    # @return F  if the panel is not currently visible
    ##
    public.redrawpanel := function(pgp, xpan, ypan) {
	wider private, gpf, public;

	# make sure requested panel is visible
	local fit := public.paneltofit(xpan, ypan);
	if (is_fail(fit)) return F;
	local ok := public.setpanelvp(pgp, xpan, ypan);
	if (is_fail(ok) || ! ok) return F;

	local atts := private.panels.atts[paste(as_string([xpan, ypan]))];

	public.erase(pgp, plotmar=private.panels.plotmar);
	pgp.save();
	pgp.sch(private.panels.charht);

	ok := public.drawplot(pgp, fit.fit, fit.comp==GPF_COMPVALUES[2], 
			      labelx=atts.labelx, title=atts.title,
			      window=private.panels.win[xpan, ypan, 1:4]);
	pgp.unsa();
	return ok;
    }

    #@
    # plot one component of a given fit to occupy the entire canvas
    # @param pgp        the pgplotmanager tool to plot to
    # @param fitindex   the index to the fitengine to plot
    # @param doampreal  if true, plot the first--amplitude or real--component
    #                      of the gains; otherwise, plot the second--phase
    #                      or imaginary--component.
    # @param title      the title string to place at the top of the plot; if 
    #                      not provided, no title will be displayed.
    # @param charht     the character height to use for the plot labels.  If
    #                      not provided the value set by the charht option
    #                      will be used.
    # @param winmar   	the window margins to use; this is given as a 4-element
    #                 	   numeric array giving, in order, the left, right, 
    #                 	   bottom, and top margins in fractional units of the 
    #                 	   viewable window (i.e. NDC units).
    # @param plotmar  	the plot margins to use in units of character height 
    #                 	   (as specified by the charht parameter)
    #                 	   this is given as a 4-element numeric array giving, 
    #                 	   in order, the left, right, bottom, and top margins.
    #                 	   These margins mark the distance from the plot panel 
    #                 	   edges to its viewport box.
    ##
    public.plotfitcomp := function(pgp, fitindex, doampreal, title=F, 
				   charht=F, winmar=F, plotmar=F) 
    {
	wider public, private, gpf;
	local panidx := paste(as_string([1, 1]));
	private.panels.atts := [=];
	private.panels.whereis := [=];

	# update the plot index (if necessary);
	if (private.selupd) private.updateplotindex();

	private.panels.nxy := [1, 1];
	private.panels.vp := array(0.0, 1,1,4);
	private.panels.win := array(0.0, 1,1,4);
	private.panels.atts[panidx].fitindex := fitindex;
	private.panels.atts[panidx].plot := 
	    private.fittoplot(fitindex, doampreal);
	local comp := GPF_COMPVALUES[1];
	if (doampreal) comp := GPF_COMPVALUES[2];
	private.panels.whereis[paste(fitindex, comp)] := [1,1];

	pgp.save();
	if (is_boolean(charht)) charht := private.opts.get('charht');
	pgp.sch(charht);
	private.panels.charht := charht;

	local mar := private.opts.get('winmar');
	if (is_boolean(winmar)) winmar := mar;
	if (! is_numeric(winmar)) 
	    fail paste('plotfits: non-numeric winmar margins:', winmar);
	winmar := 1.0 * winmar;
	if (len(winmar) < 4) {
	    mar[1:len(winmar)] := winmar;
	    winmar := mar;
	}
	private.panels.winmar := winmar;

	mar := private.opts.get('plotmar');
	if (is_boolean(plotmar)) plotmar := mar;
	if (! is_numeric(plotmar)) 
	    fail paste('plotfits: non-numeric plotmar margins:', plotmar);
	plotmar := 1.0 * plotmar;
	if (len(plotmar) < 4) {
	    mar[1:len(plotmar)] := plotmar;
	    plotmar := mar;
	}
	private.panels.plotmar := plotmar;
	mar := pgp.qcs(0);
	plotmar[[1,2]] *:= mar[1];
	plotmar[[3,4]] *:= mar[2];
#	mar := winmar + plotmar;
	mar := winmar;

	private.panels.pansz := [1.0 - mar[1] - mar[3], 1.0 - mar[2] - mar[4]];
	mar +:= plotmar;

	local vp := [mar[1], winmar[1]+private.panels.pansz[1]-plotmar[2], 
		     mar[3], winmar[3]+private.panels.pansz[2]-plotmar[4]];
	private.panels.vp[1,1,1:4] := vp;
	pgp.svp(vp[1], vp[2], vp[3], vp[4]);

	private.panels.atts[panidx].isampreal := doampreal;
	private.panels.atts[panidx].labelx := T;

	if (! is_string(title)) title := '';   # fix
	if (len(title) > 0) title := paste(title);
	private.panels.atts[panidx].title := title;

	# now draw the plot
	local ok := public.drawplot(pgp, fitindex, doampreal, T, title=title,
				    window=private.panels.win[1,1,1:4]);
	pgp.unsa();
	return ok;
    }

    #@
    # plot both components of a given fit, together occupying the entire 
    # canvas.
    # @param pgp        the pgplotmanager tool to plot to
    # @param fitindex   the index to the fitengine to plot
    # @param xlabelboth if true, the x-axis label will be included for both
    #                      plots; otherwise, only the bottom plot will get 
    #                      the labeling.  The default is F.
    # @param amptitle   the title string to place at the top of the amplitude 
    #                      plot; if not provided, no title will be displayed.
    # @param phtitle    the title string to place at the top of the phase
    #                      plot; if not provided, no title will be displayed.
    # @param charht     the character height to use for the plot labels.  If
    #                      not provided the value set by the charht option
    #                      will be used.
    # @param winmar   	the window margins to use; this is given as a 4-element
    #                 	   numeric array giving, in order, the left, right, 
    #                 	   bottom, and top margins in fractional units of the 
    #                 	   viewable window (i.e. NDC units).
    # @param plotmar  	the plot margins to use in units of character height 
    #                 	   (as specified by the charht parameter)
    #                 	   this is given as a 4-element numeric array giving, 
    #                 	   in order, the left, right, bottom, and top margins. 
    #                 	   These margins mark the distance from the plot panel 
    #                 	   edges to its viewport box.
    ##
    public.plotfitpair := function(pgp, fitindex, xlabelboth=F, amptitle=F, 
				   phtitle=F, charht=F, winmar=F, plotmar=F) 
    {
	wider public, private, gpf;
	private.panels.atts := [=];
	private.panels.whereis := [=];

	# update the plot index (if necessary);
	if (private.selupd) private.updateplotindex();

	private.panels.nxy := [1, 2];
	private.panels.vp := array(0.0, 1,2,4);
	private.panels.win := array(0.0, 1,2,4);

	pgp.save();
	if (is_boolean(charht)) charht := private.opts.get('charht');
	pgp.sch(charht);
	private.panels.charht := charht;

	local mar := private.opts.get('winmar');
	if (is_boolean(winmar)) winmar := mar;
	if (! is_numeric(winmar)) 
	    fail paste('plotfits: non-numeric winmar margins:', winmar);
	winmar := 1.0 * winmar;
	if (len(winmar) < 4) {
	    mar[1:len(winmar)] := winmar;
	    winmar := mar;
	}
	private.panels.winmar := winmar;

	mar := private.opts.get('plotmar');
	if (is_boolean(plotmar)) plotmar := mar;
	if (! is_numeric(plotmar)) 
	    fail paste('plotfits: non-numeric plotmar margins:', plotmar);
	plotmar := 1.0 * plotmar;
	if (len(plotmar) < 4) {
	    mar[1:len(plotmar)] := plotmar;
	    plotmar := mar;
	}
	private.panels.plotmar := plotmar;
	mar := pgp.qcs(0);
	plotmar[[1,2]] *:= mar[1];
	plotmar[[3,4]] *:= mar[2];
#	mar := winmar + plotmar;
	mar := winmar;

	private.panels.pansz := [1.0-mar[1]-mar[3], (1.0-mar[2]-mar[4])/2];
	mar +:= plotmar;

	# draw the phase plot
	local panidx := paste(as_string([1, 1]));
	private.panels.atts[panidx].isampreal := F;
	private.panels.atts[panidx].labelx := xlabelboth;
	private.panels.atts[panidx].fitindex := fitindex;
	private.panels.atts[panidx].plot := private.fittoplot(fitindex, F);
	private.panels.whereis[paste(fitindex, GPF_COMPVALUES[1])] := [1,1];

	if (! is_string(phtitle)) phtitle := '';   # fix
	if (len(phtitle) > 0) phtitle := paste(phtitle);
	private.panels.atts[panidx].title := phtitle;

	local vp := [mar[1], winmar[1]+private.panels.pansz[1]-plotmar[2], 
		     mar[3]+private.panels.pansz[2], 
		     winmar[3]+2*private.panels.pansz[2]-plotmar[4]];
	private.panels.vp[1,1,1:4] := vp;
	pgp.svp(vp[1], vp[2], vp[3], vp[4]);

	local ok := public.drawplot(pgp, fitindex, F, xlabelboth, 
				    title=phtitle,
				    window=private.panels.win[1,1,1:4]);

	# draw the amplitude plot
	panidx := paste(as_string([1, 2]));
	private.panels.atts[panidx].isampreal := T;
	private.panels.atts[panidx].labelx := T;
	private.panels.atts[panidx].fitindex := fitindex;
	private.panels.atts[panidx].plot := private.fittoplot(fitindex, T);
	private.panels.whereis[paste(fitindex, GPF_COMPVALUES[2])] := [1,2];

	if (! is_string(amptitle)) amptitle := '';   # fix
	if (len(amptitle) > 0) amptitle := paste(amptitle);
	private.panels.atts[panidx].title := amptitle;

	vp[[3,4]] -:= private.panels.pansz[2];
	private.panels.vp[1,2,1:4] := vp;
	pgp.svp(vp[1], vp[2], vp[3], vp[4]);

	ok := public.drawplot(pgp, fitindex, T, T, title=amptitle,
			      window=private.panels.win[1,2,1:4]);

	pgp.unsa();
	return ok;
    }

    private.decodeColor := function(color, defcolor=-1) {
	local clr := defcolor;
	c := color;
	color := private.lc(color);

	if(is_numeric(color))
	    clr := color;
	else {
	    if(is_string(color)	&& has_field(GPFP_COLORS, color))
		clr := GPFP_COLORS[color];
	    else
		clr := defcolor;
	}
	return clr;
    }

    private.decodeMarker := function(marker, defmarker=1) {
	if(is_numeric(marker))
	   return marker;
	else {
	    marker := private.lc(marker);
	    if(is_string(marker) && has_field(GPFP_MARKERS, marker))
		return GPFP_MARKERS[marker];
	    else
		return defmarker;
	}
	return defmarker;
    }

    private.decodeLinestyle := function(linestyle, deflinestyle=1) {
	local ls := deflinestyle;
	if(is_numeric(linestyle))
	    ls := linestyle;
	else {
	    linestyle := private.lc(linestyle);
	    if(is_string(linestyle) && has_field(GPFP_LINESTYLES,linestyle))
		ls := GPFP_LINESTYLES[linestyle];
	}
	return ls;
    }

    private.lc := function(s) {
	if(!is_string(s))
	    return s;
	else
	    return tr('[A-Z]', '[a-z]', s);
    }

    #@
    # return the options being used by this tool
    ##
    public.getoptions := function() {
	wider private;
	return private.opts.torecord();
    }

    #@ 
    # return the value of an option
    # @param name     the option name
    ##
    public.getoption := function(name) { 
	wider private; 
	return private.opts.get(name);
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
	wider private;
	if (! private.opts.has_item(name)) 
	    fail paste('setoption: unrecognized option:', name);
	private.opts.set(name, value, who=who, skipwho=skipwho);
	return T;
    }

    #@ 
    # update the selection of subplots to display
    # @param axis    the name of the gain axis being selected on
    # @param state   if true, the values are being selected; otherwise,
    #               	 they are being deselected
    # @param values  an array of axis values being selected or deselected
    # @param who     the actor requesting the selection change
    public.select := function(axis, state, values, who='') {
	wider private;
	local v, i;
	if (! has_field(private.axes, axis))
	    fail paste('select: unrecognized gain axis:', axis);
	if (! is_boolean(state)) 
	    fail paste('state parameter not a boolean:', state);
	if (len(values) == 0) return T;

	local used := values[1];
	local j := 1;
	for (v in values) {
	    i := ind(private.axes[axis].vals)[v == private.axes[axis].vals];
	    if (len(i) > 0) {
		private.axes[axis].sel[i] := state;
		used[j] := v;
		j +:= 1;
	    }
	}

	private.selupd := T;
	private.sellisteners.tell([axis=axis, state=state, values=used],
				  who=who, skipwho=T);
	return T;
    }

    #@
    # select all values for given axes
    # @param axis   string array containing the names of the axis to select on; 
    #                  if F, select all axes.
    # @param state   if true (the default), the values are being selected; 
    #               	 otherwise, they are being deselected
    # @param who     the actor requesting the selection change
    ##
    public.selectall := function(axis=F, state=T, who='') {
	wider private, public;
	local ax, axvals, ok;
	if (is_boolean(axis)) axis := field_names(private.axes);

	for (ax in axis) {
	    ok := public.select(ax, state, private.axes[ax].vals, who);
	    if (is_fail(ok)) return ok;
	}

	return T;
    }

    #@ 
    # return the values selected along a given axis.
    # @param name   the name of the axis to inquire about
    ##
    public.getselection := function(axis) {
	wider private;
	local v;
	if (! has_field(private.axes, axis))
	    fail paste('select: unrecognized gain axis:', axis);

	return private.axes[axis].vals[private.axes[axis].sel];
    }

#      #@ 
#      # return the pgplot agent that plot commands are being sent to
#      ##
#      public.getpgplotmanager := function() {
#  	wider pgp;
#  	return ref pgp;
#      }

    #@ 
    # add a listener
    # @param callback   a function to be called when an option or selection 
    #                     is updated.  This function should have the following 
    #                     signature:
    #                     <pre>
    #                        function(state=[=], name='', who='')
    #                     where 
    #                        state    a record desribing the change (see
    #                                   below)
    #                        name     the name associated with the change. If 
    #                                   an option was changed, this will be
    #                                   'gpfpoptions'; if a selection was made,
    #                                   this will be 'gpfpselection'.
    #                        who      the name of the actor that requested the 
    #                                   chang; an empty string means "unknown".
    #                     </pre>
    #                     For an option change, the state record will have the 
    #                     following fields:
    #                     <pre>
    #                        item     the name of the option that was changed.
    #                        old      the old value
    #                        new      the new value
    #                     </pre>
    #                     For a selection update, the state record will have
    #                     following fields:
    #                     <pre>
    #                        axis     the name of the axis selected on
    #                        state    T if selected values are turned on
    #                        values   an array of values that were updated
    #                     </pre>
    # @param who        the name to associate with the listener.  This will
    #                     be returned by this function.  If a name is not 
    #                     provided, a unique name will be provided and returned.
    # @return string  represting the name given to the new listener.  
    ##
    public.addlistener := function(callback, who='') {
	wider private;
	local name := private.opts.addlistener(callback, who);
	private.sellisteners.addlistener(callback, who=name);
	return name;
    }

    #@
    # remove a listener.  The callback associated with the given name will
    # be thrown away.
    # @param who   the name of the listener to remove
    ##
    public.removelistener := function(who) {
	wider private;
	private.sellisteners.removelistener(who);
	return private.opts.removelistener(who);
    }	

    #@
    # shut down this tool.  
    ##
    public.done := function() {
	wider private, public;
	private.opts.done();
	private.sellisteners.done();
	private := F;
	val public := F;
    }

    private.initgpf();

    public.private := ref private;
    public.gpf := ref gpf;
    public.pgp := ref pgp;

    return ref public;
}
