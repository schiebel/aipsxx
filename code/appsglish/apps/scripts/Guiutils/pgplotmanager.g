# pgplotmanager.g: tool wrapper for the pgplot agent with displaylist.
#
#   Copyright (C) 1998,1999,2000,2001,2002,2003
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
#   675 Massachusetts Ave, Cambridge, MA 02139, USA..
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: pgplotmanager.g,v 19.2 2004/08/25 02:00:07 cvsmgr Exp $
#
pragma include once;

include 'unset.g';

const _PGAGENT_HELP := [
     arro='draw an arrow',
     ask='control new page prompting',
     bbuf='begin batch of output (buffer)',
     beg='begin PGPLOT, open output device',
     bin='histogram of binned data',
     box='draw labeled frame around viewport',
     circ='draw a filled or outline circle',
     clos='close the selected graphics device',
     conb='contour map of a 2D data array, with blanking',
     conl='label contour map of a 2D data array ',
     cons='contour map of a 2D data array (fast algorithm)',
     cont='contour map of a 2D data array (contour-following)',
     ctab='install the color table to be used by PGIMAG',
     draw='draw a line from the current pen position to a point',
     ebuf='end batch of output (buffer)',
     end='terminate PGPLOT',
     env='set window and viewport and draw labeled frame',
     eras='erase all graphics from current page',
     errb='horizontal or vertical error bar',
     errx='horizontal error bar',
     erry='vertical error bar',
     gray='gray-scale map of a 2D data array',
     hi2d='cross-sections through a 2D data array',
     hist='histogram of unbinned data',
     iden='write username, date, and time at bottom of plot',
     imag='color image from a 2D data array',
     lab='write labels for x-axis, y-axis, and top of plot',
     ldev='list available device types',
     len='find length of a string in a variety of units',
     line='draw a polyline (curve defined by line-segments)',
     move='move pen (change current pen position)',
     mtxt='write text at position relative to viewport',
     numb='convert a number into a plottable character string',
     open='open a graphics device',
     page='advance to new page',
     panl='switch to a different panel on the view surface',
     pap='change the size of the view surface ',
     pixl='draw pixels',
     pnts='draw one or more graph markers, not all the same',
     poly='fill a polygonal area with shading',
     pt='draw one or more graph markers',
     ptxt='write text at arbitrary position and angle',
     qah='inquire arrow-head style',
     qcf='inquire character font',
     qch='inquire character height',
     qci='inquire color index',
     qcir='inquire color index range',
     qcol='inquire color capability',
     qcr='inquire color representation',
     qcs='inquire character height in a variety of units',
     qfs='inquire fill-area style',
     qhs='inquire hatching style',
     qid='inquire current device identifier',
     qinf='inquire PGPLOT general information',
     qitf='inquire image transfer function',
     qls='inquire line style',
     qlw='inquire line width',
     qpos='inquire current pen position',
     qtbg='inquire text background color index',
     qtxt='find bounding box of text string',
     qvp='inquire viewport size and position',
     qvsz='find the window defined by the full view surface',
     qwin='inquire window boundary coordinates',
     rect='draw a rectangle, using fill-area attributes',
     rnd='find the smallest \'round\' number greater than x',
     rnge='choose axis limits',
     sah='set arrow-head style',
     save='save PGPLOT attributes',
     unsa='restore PGPLOT attributes',
     scf='set character font',
     sch='set character height',
     sci='set color index',
     scir='set color index range',
     scr='set color representation',
     scrn='set color representation by name',
     sfs='set fill-area style',
     shls='set color representation using HLS system',
     shs='set hatching style',
     sitf='set image transfer function',
     slct='select an open graphics device',
     sls='set line style',
     slw='set line width',
     stbg='set text background color index',
     subp='subdivide view surface into panels',
     svp='set viewport (normalized device coordinates)',
     swin='set window',
     tbox='draw frame and write (DD) HH MM SS.S labelling',
     text='write text (horizontal, left-justified)',
     updt='update display',
     vect='vector map of a 2D data array, with blanking',
     vsiz='set viewport (inches)',
     vstd='set standard (default) viewport',
     wedg='annotate an image plot with a wedge',
     wnad='set window and adjust viewport to same aspect ratio'];

#@global 
# a function that asks the user for confirmation to proceed to the next 
# plot.  This is suitable for passing to the pgplotmanager constructor's 
# askfunction parameter.  
##
pgplotaskviaprompt := function() {
    local ok := readline('Type <RETURN> for next page: ');
    if (is_fail(ok)) return ok;
    return T;
}

#@global 
# a function that asks the user for confirmation to proceed to the next 
# plot.  This is suitable for passing to the pgplotmanager constructor's 
# askfunction parameter.  
##
pgplotaskviagui := function() {
    include 'choice.g';
    local ok := choice('Press <CONTINUE> for next page:', 'CONTINUE');
    if (is_fail(ok)) return ok;
    return T;
}

#@tool public pgplotmanager
#  a tool for managing a pgplot session.  
#
#@constructor
# create a pgplotmanager session tool
# @param  pgpagent    the pgplot agent to attach to.
# @param  closeable   if true (the default), the agent will be 
#                    	explicitly closed before it is released, either 
#                    	via done() or a subsequent setagent() call.  Set 
#                    	this to false, if the agent is begin shared with
#                    	another tool.
# @param  
##
const pgplotmanager := function(ref pgpagent=F, closeable=T, interactive=T, 
				record=F, ref playlist=F, ownplaylist=T, 
				askfunction=F, widgetset=F) 
{
    include 'note.g';

    pg := F;
    public := [=];
    private := [interactive=interactive, askfunction=askfunction, ask=F,
		record=T, plots_per_page=1, plot_number=0, devnull=F,
		refreshing=F, id=random(), closeable=closeable];
    private::isa := "pgplotmanager";

    if (is_boolean(private.askfunction)) 
	private.askfunction := pgplotaskviaprompt;
    if (! is_function(private.askfunction)) 
	throw('non-function passed for askfunction', origin='pgplotmanager');

    #@
    # return a short help message describing the function of pgplot 
    # method
    # @param name  a recognized pgplot agent event name; see the Glish/PGPLOT
    #              documentation for a list of supported events
    # @return string   the help text or name if not recognized
    public.help := function(name) {
        text := name;
        if (has_field(_PGAGENT_HELP, name)) text := _PGAGENT_HELP[name];
        return text;
    }

    # The displaylist is used to save the plot commands for redrawing when the
    # screen is resized, saving to postscript, etc. private.record is used to
    # see if plot commands are saved or not, and public.record is the users
    # access to changing this state.
    include 'displaylist.g';
    if (is_boolean(playlist)) {
	if (is_boolean(widgetset)) widgetset := dws;
	private.displaylist := 
	    displaylist(formatfunction=function(rec){return rec._method},
			shorthelp=public.help, widgetset=widgetset);
	if (! is_record(private.displaylist))
	    fail paste('Failed to create displaylist:', private.displaylist);
    } 
    else if (! is_record(displaylist) || !has_field(displaylist,'ndrawlist')) {
	throw('Non-displaylist tool passed to constructor',
	      origin='pgplotmanager');
    }
    else {
	private.displaylist := ref playlist;
	if (ownplaylist) private.displaylist.owner := private.id;
    }

    private.redrawfuncs := [=]; # Functions for redrawing a particular command 
                             # from the display list.

    #### Non-PGPLOT functions

    #@
    # Return a the pgplot agent being managed.  
    ##
    public.getagent := function() { 
	wider pg; 
	if (private.devnull) 
	    return F;
	else
	    return ref pg; 
    }

    #@
    # Set the pgplot agent to be managed by this tool
    # @param  pgpagent   the pgplot agent.  If none is provided, this tool will 
    #                      no longer manage a specific agent.  
    # @param  closeable  if true (the default), the agent will be 
    #                      explicitly closed before it is released, either 
    #                      via done() or a subsequent setagent() call.  Set 
    #                      this to false, if the agent is begin shared with
    #                      another tool.
    ##
    public.setagent := function(ref pgpagent=F, closeable=T) {
	wider pg, private;
	if (!is_boolean(pgpagent) && !is_agent(pgpagent)) 
	    fail 'pgplotmanager: pgpagent not an agent';

	if (is_agent(pg) && private.closeable && ! private.devnull)
	    pg->clos();
	if (is_boolean(pgpagent)) {
	    pg := pgplot('/dev/null/PS');
	    private.devnull := T;
	} else {
	    pg := pgpagent;
	    private.devnull := F;
	}

	private.closeable := closeable;
	return T;
    }

    #@
    # reset the internal plot number counter to 0.  The pgplotwidget 
    # maintains an internal counter which is used to determine when to 
    # prompt the user (when function ask(T) has been called).  When prompting 
    # is desired, it's usually only necessary to do so after the first plot 
    # has been presented.  This function resets to 0 the counter that tracks 
    # how many plots have been presented so far; thus, for the next plot after 
    # calling this function, you won't be prompted. 
    ##
    public.resetplotnumber := function ()
    {
       wider private;

       # This function needs to go into the display list as
       # it's called like a real pgplot function (i.e. one that
       # affects the plot)

       if (private.record) private.displaylist.add(
                [_method='resetplotnumber', rec=[=]])

       private.plot_number := 0;
       return T;
    }
    private.redrawfuncs.resetplotnumber := function (rec)
    {
       return public.resetplotnumber();
    }

    public.displaylist := function() {
        wider private;
        return ref private.displaylist;
    }

    public.record := function(newstate)
    {
        wider private;
        if (!is_boolean(newstate)) 
            fail 'pgplotwidget.record(newstante): newstate is not boolean';
        oldstate := private.record;
        private.record := newstate;
        return oldstate;
    }

    #@ 
    # return true if recording is currently turned on
    ##
    public.recording := function() { return private.record; }

    public.canplay := function(command) {
      wider private;
      return any(field_names(private.redrawfuncs)==command);
    }

    public.play := function(ref commands, record=T)
    {
        wider public, private, pg;
	if (! is_agent(pg)) return T;

        if (!is_record(commands)) {
            fail 'pgplotwidget.play: illegal argument';
        }
        if (has_field(commands, 'ndrawlist') && has_field(commands, 'get')) {
            # It's a draw list!
            if (commands.ndrawlist()==0) return T;
            oldrecord := public.record(record);
            pg->bbuf();
            for (i in 1:(commands.ndrawlist())) {
                rec := private.displaylist.get(i);
                mthd := rec._method;
                if (!has_field(private.redrawfuncs, mthd)) {
                    note('pgplotwidget.play - skipping item #', i, 
                         ' cannot redraw the function: ', mthd, priority='WARN');
                    } else {
                        private.redrawfuncs[mthd](rec);
                    }
            }
            pg->ebuf();
            public.record(oldrecord);
        } else {
            # Assume it's a raw record (e.g. from C++), with one command
            # per field
            old := public.record(record);
            if (length(commands) == 0) return T;
            pg->bbuf();
            for (name in field_names(commands)) {
                private.redrawfuncs[commands[name]._method](commands[name]);
            }
            pg->ebuf();
            public.record(old);
        }
        pg->ebuf();
        return T;
    }

    public.plotfile := function(file='aipsplot.plot')
    {
        wider private;
        return private.displaylist.save(file);
    }

    public.refresh := function()
    {
        wider public, private;
	if(private.refreshing) return T;
	private.refreshing := T;
        public.play(private.displaylist, F);
	private.refreshing := F;
	return T;
    }

    public.restore := function(file='aipsplot.plot')
    {
        wider public, private;
        ok := private.displaylist.restore(file);
        if (is_fail(ok) || !ok) fail;
        public.refresh();
    }

    public.isa := function() { return private::isa; }
    public.type := function() { return private::isa[1]; }

    public.done := function()
    {
        wider public, private, pg;

	if (is_agent(pg) && private.closeable && ! private.devnull) 
	    pg->clos();
        pg := F;

	if (has_field(private.displaylist, 'owner') && 
	    type_name(private.displaylist.owner) == type_name(private.id) &&
	    private.displaylist.owner == private.displaylist.id) 
	  private.displaylist.done();
        private := F;
        val public := F;
	return T;
    }

    private.stretch := function(minmax) {
    # Stretch by a bit
        delta := (minmax[2] - minmax[1]) * 0.05;
        absmax := max(abs(minmax));
        if (is_double(minmax)) {
           if (delta <= 1.0e-10*absmax) delta := 0.01 * absmax;
        } else {
           if (delta <= 1.0e-5*absmax) delta := 0.01 * absmax;
        }
        if (delta == 0.0) delta := 1;
        minmax[1] -:= delta;
        minmax[2] +:= delta;
        return minmax;
    }

    ### If you change this function, do not forget to change the meta info.

    public.plotxy := function(x,y,plotlines=T,newplot=T,xtitle='',ytitle='',
			      title='',linecolor=2,ptsymbol=2,mask=F)
    {
	wider public, private;

	local nx := len(x);
	local ny := len(y);
	local nxy := nx
	if (nx != ny) {
	    nxy := min(nx,ny);
	    note('plotxy: x and y length differ, using the shorter length of ',
		 nxy, priority='WARN');
	    if (nxy > 0) {
		x := x[1:nxy];
		y := y[1:nxy];
	    } 
	    else {
		x := [];
		y := x;
	    }
	}

	# allow zero-length arrays
	if (length(x) == 0) return T;

	if (!is_numeric(x) || !is_numeric(y) || is_complex(x) || is_complex(y))
	    return throw('plotxy: x and y must be real arrays');

	if (!is_boolean(plotlines) || length(plotlines) != 1 ||
	    !is_boolean(newplot) || length(newplot) != 1)
	    return throw('plotxy: plotlines and newplot must be T or F',
			 origin='pgplotmanager');

	if (!is_string(xtitle) || !is_string(ytitle) || !is_string(title))
	    return throw('plotxy: xtitle, ytitle, and title must be strings',
			 origin='pgplotmanager');

	local nm := len(mask);
	if (nm > 1) {
	    if (!is_boolean(mask))
		return throw('plotxy: mask must be boolean',
			     origin='pgplotmanager');

	    if (nm < nxy) {
		note('plotxy: length of mask (', nm, ') < length of arrays (',
		     nxy, '); missing masked set to T', priority='WARN',
		     origin='pgplotmanager');
		local newmask := rep(T, nxy);
		newmask[1:nm] |:= mask;
		mask := newmask;
		nm := nxy;
	    }
	    else if (nm > nxy) {
		note('plotxy: length of mask (', nm, ') > length of arrays (',
		     nxy, '); ignoring extra masks', priority='WARN',
		     origin='pgplotmanager');
		mask := mask[1:nxy];
		nm := nxy;
	    }

# Note: this check removed in old version of pgplotwidget 
#
#  	    if (plotlines) {
#  		contig := F;
#  		for (i in 1:(len(mask)-1))
#  		    if (mask[i]&mask[i+1]) contig := T;
#  		if (!contig)
#  		    return throw('plotxy: no contiguous T segments in mask',
#  				 origin='pgplotmanager');
#  	    }
#  	    else if (sum(mask)==0)
#  		note('plotxy: all points excluded by mask',
#  		     priority='WARN', origin='pgplotmanager');

  	}

	if (newplot) {
	    local xrange, yrange;
	    if (len(mask)<2) {
		xrange := range(x);
		yrange := range(y);
	    }
	    else {
		xrange := range(x[mask]);
		yrange := range(y[mask]);
	    }
	    yrange := private.stretch(yrange); 
	    public.env(xrange[1], xrange[2], yrange[1], yrange[2], 0, 0);
	    public.lab(xtitle, ytitle, title);
	}

	local oldlinecolor := public.qci();
	public.sci(linecolor);
	if (plotlines) {
	    if (nm > 1) {
		public.maskline(x, y, mask);
	    } else {
		public.line(x,y);
	    }
	}
	else {
	    if (nm > 1) {
		public.pt(x[mask],y[mask],ptsymbol);
	    } else {
		public.pt(x,y,ptsymbol);
	    }
	}

	public.sci(oldlinecolor);
	return T;
    }

    private.redrawfuncs.plotxy := function(rec) {
        wider public;
        public.plotxy(rec.x, rec.y, rec.plotlines, rec.newplot, 
                      rec.xtitle, rec.ytitle, rec.title, rec.linecolor,
		      rec.ptsymbol, rec.mask);
    }

                              
    public.maskline := function(x, y, mask=unset, decimate=10) 
    #
    # mask = T is good
    # mask = F is bad
    #
    {
	wider public, private;

	if (len(x) != len(y)) 
	    return throw('maskline: inconsistant lengths for input arrays',
			 origin='pgplotmanager');
	if (length(x) == 0) return T;
	if (!is_numeric(x) || !is_numeric(y) || is_complex(x) || is_complex(y)) 
	    return throw('maskline: x and y must be real arrays', 
			 origin='pgplotwidget.maskline');

	n := len(x);
	if (len(x) != len(y)) {
	    n := min(len(x), len(y));
	    note('maskline: x and y lengths differ, using shorter length (', 
		 n, ')', origin='pgplotmanager', priority='WARN');
	    x := x[1:minl];
	    y := y[1:minl];
	}

	# Short cut if no mask
	if (is_unset(mask)) {
	    return public.line(x,y);     
	}

	if (!is_boolean(mask)) {
	    return throw('maskline: mask must be boolean', 
			 origin='pgplotmanager');
	}

	# Short cut if mask all good (T).  
	if (all(mask)) {
	    return public.line(x,y);     
	}

	# Take shortest length
	n2 := n;
	if (len(mask) != n2) {
	    n := min(len(x), len(y), len(mask));
	    if (n2 != n) {
		x := x[1:n];
		y := y[1:n];
		mask := mask[1:n];
	    }
	}

	# We are going to chop the spectrum into equal chunks of length 'size'
        # and look for unmasked segments within each chunk
	local size;
	d := max(1,as_integer(decimate));
	if (d>1 && d<n) {
	    size := max(1,as_integer(n / d));
	} else {
	    size := n;                           # No decimation
	}

	# Loop while we have not inspected all of the spectrum
	iStart := 1;
	iEnd := iStart + size - 1;

	iSeg := 0;
	starts := [];
	ends := [];

	more := T;
	while (more) {
	    if (all(mask[iStart:iEnd])) {

		# All good in this chunk.  Take short cut.
		if (iSeg > 0 && iStart==ends[iSeg]+1) {

		    # This segment starts adjacent to where the last one ended
		    # (a chunk boundary) so don't start a new segment.  Just
		    # push up the end of the current segment

		    ends[iSeg] := iEnd;

		} else {
		    iSeg +:= 1;
		    starts[iSeg] := iStart;
		    ends[iSeg] := iEnd;
		}
	    } else {

		# Some masked points in this chunk.  Find them.
		rec := private.findSegments (mask[iStart:iEnd]);
		if (rec.iSeg==0) {

		    # This means all points were bad so we don't want to 
		    # see them

		} else {
		    for (j in 1:(rec.iSeg)) {
			start := rec.starts[j] + iStart - 1; 
			if (iSeg > 0 && start==ends[iSeg]+1) {

			    # This segment starts adjacent to where the 
			    # last one ended (a chunk boundary) so don't 
			    # start a new segment.  Just push up the end 
			    # of the current segment

			    ends[iSeg] := rec.ends[j] + iStart - 1;
			} else {
			    iSeg +:= 1;
			    starts[iSeg] := start;
			    ends[iSeg] := rec.ends[j] + iStart - 1;
			}
		    }
		}
	    }

	    # Update counters
	    iStart := iEnd + 1;
	    iEnd := min(iStart+size-1, n);

	    more := iStart <= n;
	}

	if (iSeg==0) {
	    note ('The mask is all bad (F) - no data to plot',
		  origin='pgplotwidget.maskline', priority='WARN');
	    return T;
	}


	# Loop over list of segments and plot.  Use buffering to speed plotting.
	ok := T;
	public.bbuf();
	for (i in 1:iSeg) {
	    if (ends[i] - starts[i] + 1 == 1) {
		ok := public.pt(x[starts[i]], y[starts[i]], 1);
	    } else {
		ok := public.line(x[starts[i]:ends[i]], y[starts[i]:ends[i]]);
	    }
	    if (is_fail(ok)) {
		public.ebuf();
		fail;
	    }	
	}

	public.ebuf();
	return ok;
    }

    private.findSegments := function (mask) {
	n := length(mask);

	rec := [=];
	rec.starts := [];
	rec.ends   := [];   
	rec.iSeg := 0;

	findStart := T; 
	for (i in 1:n) {
	    if (findStart) {
		if (mask[i]) {
		    rec.iSeg +:= 1;
		    rec.starts[rec.iSeg] := i;
		    findStart := F;
		}
	    } else {
		if (!mask[i]) {
		    rec.ends[rec.iSeg] := i - 1;
		    findStart := T;
		} else {
		    if (i == n) {
			rec.ends[rec.iSeg] := n;
		    }
		}
	    }   
	}   
	# pathological case, start happens at the last element of
	# mask, hence ends for the last iSeg never gets set
	if (len(rec.ends) != rec.iSeg) {
            rec.ends[rec.iSeg] := rec.starts[rec.iSeg];
        }

	return rec;
    }

    private.redrawfuncs.maskline := function(rec) {
	wider public;
	public.maskline(rec.x, rec.y, rec.mask);
    }
                              

    public.clear := function()
    {
        wider public, private;
        private.displaylist.clear();
        public.refresh();
        # Set the default settings
        public.settings();
        if (is_agent(pg)) pg->eras();
    }

    public.settings := function(ask=F, nxsub=1, nysub=1,
                                arrowfs=1, arrowangle=45, arrowvent=0.3,
                                font=1,ch=1,ci=1,fs=1,
                                hsangle=45, hssepn=1, hsphase=0,
                                ls=1,lw=1,tbci=-1) {
        wider public, private;
        oldrecord := public.record(F);
        public.ask(ask);
        public.subp(nxsub,nysub);
        public.sah(arrowfs,arrowangle,arrowvent);
        public.scf(font);
        public.sch(ch);
        public.sci(ci);
        public.sfs(fs);
        public.shs(hsangle,hssepn,hsphase);
        public.sls(ls);
        public.slw(lw);
        public.stbg(tbci);
        public.vstd();
        if (oldrecord) private.displaylist.add([_method='settings',
                     ask=ask,nxsub=nxsub,nysub=nysub,
                     arrowfs=arrowfs,arrowangle=arrowangle,arrowvent=arrowvent,
                     font=font,ch=ch,ci=ci,fs=fs,
                     hsangle=hsangle,hssepn=hssepn,hsphase=hsphase,
                     ls=ls,lw=lw,tbci=tbci]);
        public.record(oldrecord);
    }
    private.redrawfuncs.settings := function(rec) {
        wider public, private;
        public.settings(ask=rec.ask, nxsub=rec.nxsub,nysub=rec.nysub,
                        arrowfs=rec.arrowfs,arrowangle=rec.arrowangle,
                        arrowvent=rec.arrowvent,
                        font=rec.font,
                        ch=rec.ch,ci=rec.ci,fs=rec.fs,hsangle=rec.hsangle,
                        hssepn=rec.hssepn,
                        hsphase=rec.hsphase,ls=rec.ls,lw=rec.lw,tbci=rec.tbci);
    }

    # Report a number that is incremented every time the plot is changed so
    # we can, e.g., know whether or not we have to change the plot. The change
    # number is only incremented if we are recording changes.
    public.lastchange := function()
    {
        wider private;
        return private.displaylist.lastchange();
    }

    public.addredrawfunction := function(method, redrawfunction) {
        wider private;
        if (!is_string(method) || length(method) != 1 || 
            !is_function(redrawfunction)) {
            return throw('addredrawawfunction: improper type',
                         ' for method or redrawfunction',
			 origin='pgplotmanager');
        }
        if (has_field(private.redrawfuncs, method)) {
            return throw('addredrawfunction: method ', method,
                         ' has already been defined',
			 origin='pgplotmanager');
        }
        private.redrawfuncs[method] := redrawfunction;
        return T;
    }

    #### Standard pgplot functions
    ########### arro
    public.arro := function(x1,y1,x2,y2)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->arro(x1,y1,x2,y2)
        if (private.record) private.displaylist.add(
                [_method='arro', 
                 x1=x1,y1=y1,x2=x2,y2=y2]);
        return ok;
    }
    private.redrawfuncs.arro := function(rec)
    {
        wider public;
        public.arro(rec.x1,rec.y1,rec.x2,rec.y2)
    }
    ########### ask (# Special implementation)
    public.ask := function(flag)
    {
        wider private, pg;
	local ok := T;
        private.ask := flag;
        if (private.record) private.displaylist.add(
                [_method='ask', flag=flag]);
	return T;
    }
    private.redrawfuncs.ask := function(rec)
    {
        wider public;
        public.ask(rec.flag)
    }

    #@ 
    # return true if "ask" prompting is turned on
    ##
    public.asking := function() { return private.ask; }

    ########### bbuf
    public.bbuf := function()
    {
        wider pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->bbuf();
        return ok;
    }
    private.redrawfuncs.bbuf := function(rec)
    {
        wider public;
        public.bbuf()
    }

    ########### bin
    public.bin := function(x, data, center)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->bin(x,data,center);
        if (private.record) private.displaylist.add(
                [_method='bin', x=x, data=data, center=center])
        return ok;
    }
    private.redrawfuncs.bin := function(rec)
    {
        wider public;
        public.bin(rec.x, rec.data, rec.center);
    }

    ########### box
    public.box := function(xopt, xtick, nxsub, yopt, ytick, nysub)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->box(xopt, xtick, nxsub, yopt, ytick, nysub)
        if (private.record) {
            private.displaylist.add([_method='box', 
             xopt=xopt, xtick=xtick, nxsub=nxsub, yopt=yopt, ytick=ytick,
              nysub=nysub])
        }
        return T
    }
    private.redrawfuncs.box := function(rec)
    {
        wider public;
        public.box(rec.xopt, rec.xtick, rec.nxsub, rec.yopt, rec.ytick, 
                   rec.nysub)
    }

    ########### circ
    public.circ := function(xcent, ycent, radius)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->circ(xcent, ycent, radius)
        if (private.record) {
            private.displaylist.add([_method='circ', 
             xcent=xcent,ycent=ycent,radius=radius])
        }
        return ok;
    }
    private.redrawfuncs.circ := function(rec)
    {
        wider public;
        public.circ(rec.xcent,rec.ycent,rec.radius)
    }

    ########### conb
    public.conb := function(a, c, tr, blank)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->conb(a, c, tr, blank);
        if (private.record)
            private.displaylist.add([_method='conb',
                                 a=a,c=c,tr=tr,blank=blank]);
        return ok;
    }
    private.redrawfuncs.conb := function(rec) {
        wider public; 
        public.conb(rec.a, rec.c, rec.tr, rec.blank);
    }

    ########### conl
    public.conl := function(a, c, tr, label, intval, minint)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->conl(a, c, tr, label, intval, minint);
        if (private.record)
            private.displaylist.add([_method='conl',
                                 a=a,c=c,tr=tr,label=label,intval=intval,
                                 minint=minint]);
        return ok;
    }
    private.redrawfuncs.conl := function(rec) {
        wider public; 
        public.conl(rec.a, rec.c, rec.tr, rec.label,rec.intval,rec.minint);
    }

    ########### cons
    public.cons := function(a, c, tr)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->cons(a, c, tr)
        if (private.record)
            private.displaylist.add([_method='cons',
                                 a=a,c=c,tr=tr]);
        return ok;
    }
    private.redrawfuncs.cons := function(rec) {
        wider public; 
        public.cons(rec.a, rec.c, rec.tr);
    }

    
    ########### cont
    public.cont := function(a, c, nc, tr)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->cont(a, c, nc, tr)
        if (private.record)
            private.displaylist.add([_method='cont',
                                 a=a,c=c,nc=nc, tr=tr]);
        return ok;
    }
    private.redrawfuncs.cont := function(rec) {
        wider public; 
        public.cont(rec.a, rec.c, rec.nc, rec.tr);
    }

    
    ########### ctab
    public.ctab := function(l, r, g, b, contra, bright)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->ctab(l, r, g, b, contra, bright)
        if (private.record) {
            private.displaylist.add([_method='ctab', 
                l=l, r=r, g=g, b=b, contra=contra, bright=bright])
        }
        return ok;
    }
    private.redrawfuncs.ctab := function(rec)
    {
        wider public;
        public.ctab(rec.l, rec.r, rec.g, rec.b, rec.contra, rec.bright)
    }

    ########### draw
    public.draw := function(x,y)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->draw(x, y)
        if (private.record) private.displaylist.add(
                [_method='draw', x=x,y=y])
        return ok;
    }
    private.redrawfuncs.draw := function(rec)
    {
        wider public;
        public.draw(rec.x,rec.y)
    }

    ########### ebuf
    public.ebuf := function()
    {
        wider private;
	local ok := T;
        if (is_agent(pg)) ok := pg->ebuf()
        return ok;
    }
    private.redrawfuncs.ebuf := function(rec)
    {
        wider public;
        public.ebuf()
    }

    ########### env
    public.env := function(xmin,xmax,ymin,ymax,just,axis)
    {
        wider private, pg;
	local ok := T;
        if (private.ask && private.interactive && private.plot_number != 0 &&
            (private.plot_number%private.plots_per_page)==0) 
	{
	    private.askfunction();
        }
        private.plot_number +:= 1;
        if (is_agent(pg)) ok := pg->env(xmin,xmax,ymin,ymax,just,axis)
        if (private.record) {
            private.displaylist.add([_method='env', 
               xmin=xmin,xmax=xmax,ymin=ymin,ymax=ymax,just=just,axis=axis])
        }
        return ok;
    }
    private.redrawfuncs.env := function(rec)
    {
        wider public;
        public.env(rec.xmin,rec.xmax,rec.ymin,rec.ymax,rec.just,rec.axis)
    }
    
    ########### eras (clears displaylist)
    public.eras := function()
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->eras()
        if (private.record) private.displaylist.add(
                [_method='eras'])
        return ok;
    }
    private.redrawfuncs.eras := function(rec)
    {
        wider public;
        public.eras()
    }

    ########### errb
    public.errb := function(dir, x, y, e, t)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->errb(dir, x, y, e, t)
        if (private.record) private.displaylist.add(
                [_method='errb', 
                dir=dir, x=x, y=y, e=e, t=t])
        return ok;
    }
    private.redrawfuncs.errb := function(rec)
    {
        wider public;
        public.errb(rec.dir,rec.x,rec.y,rec.e,rec.t)
    }

    ########### errx
    public.errx := function(x1, x2, y, t)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->errx(x1, x2, y, t)
        if (private.record) private.displaylist.add(
                [_method='errx', 
                x1=x1,x2=x2,y=y,t=t])
        return ok;
    }
    private.redrawfuncs.errx := function(rec)
    {
        wider public;
        public.errx(rec.x1, rec.x2, rec.y, rec.t)
    }

    ########### erry
    public.erry := function(x, y1, y2, t)
    {
        wider private, pg;
	local ok := T;

	if (len(x) != len(y1) || len(x) != len(y2)) 
	    return throw('erry: inconsistant lengths for input arrays',
			 origin='pgplotmanager');
	if (length(x) == 0) return T;
	if (!is_numeric(x) || !is_numeric(y1) || !is_numeric(y2) || 
	     is_complex(x) ||  is_complex(y2) ||  is_complex(y2)   )
	    return throw('erry: x and y must be real arrays',
			 origin='pgplotmanager');

        if (is_agent(pg)) ok := pg->erry(x, y1, y2, t)
        if (private.record) private.displaylist.add(
                [_method='erry', 
                x=x,y1=y1,y2=y2,t=t])
        return ok;
    }
    private.redrawfuncs.erry := function(rec)
    {
        wider public;
        public.erry(rec.x, rec.y1, rec.y2, rec.t)
    }

    ########### gray
    public.gray := function(a, fg, bg, tr) {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->gray(a, fg, bg, tr);
        if (private.record) private.displaylist.add([_method='gray',
                                               a=a,fg=fg,bg=bg,tr=tr]);
        return ok;
    }
    private.redrawfuncs.gray := function(rec) {
        wider public;
        public.gray(rec.a, rec.fg, rec.bg, rec.tr);
    }

    ########### hi2d
    public.hi2d := function(data, x, ioff, bias, center, ylims) {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->hi2d(data, x, ioff, bias, center, ylims);
        if (private.record) private.displaylist.add([_method='hi2d',
           data=data, x=x, ioff=ioff, bias=bias, center=center, ylims=ylims]);
        return ok;
    }
    private.redrawfuncs.hi2d := function(rec) {
        wider public;
        public.hi2d(rec.data, rec.x, rec.ioff, rec.bias, rec.center, rec.ylims);
    }

    ########### hist
    public.hist := function(data, datmin, datmax, nbin, pgflag)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->hist(data, datmin, datmax, nbin, pgflag)
        if (private.record) private.displaylist.add(
                [_method='hist', 
                data=data, datmin=datmin, datmax=datmax, nbin=nbin, 
                 pgflag=pgflag])
        return ok;
    }
    private.redrawfuncs.hist := function(rec)
    {
        wider public;
        public.hist(rec.data, rec.datmin, rec.datmax, rec.nbin, rec.pgflag)
    }

    ########### iden
    public.iden := function()
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->iden()
        if (private.record) private.displaylist.add(
                [_method='iden'])
        return ok;
    }
    private.redrawfuncs.iden := function(rec)
    {
        wider public;
        public.iden()
    }

    ########### imag
    public.imag := function(a, a1, a2, tr)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->imag(a, a1, a2, tr)
        if (private.record) private.displaylist.add(
                [_method='imag', 
                a=a, a1=a1, a2=a2, tr=tr])
        return ok;
    }
    private.redrawfuncs.imag := function(rec)
    {
        wider public;
        public.imag(rec.a, rec.a1, rec.a2, rec.tr)
    }

    ########### lab
    public.lab := function(xlbl, ylbl, toplbl)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->lab(xlbl, ylbl, toplbl)
        if (private.record) private.displaylist.add(
                [_method='lab', xlbl=xlbl, ylbl=ylbl, toplbl=toplbl])
        return ok;
    }
    private.redrawfuncs.lab := function(rec)
    {
        wider public;
        public.lab(rec.xlbl,rec.ylbl,rec.toplbl)
    }

    ########### ldev   (Query, not logged)
    public.ldev := function() {
        wider pg;
        return pg->ldev()
    }
    private.redrawfuncs.ldev := function(ref rec)
    {
        wider public;
        rec.return := public.ldev();
    }

    ########### len   (Query, not logged)
    public.len := function(units, string) {
        wider pg;
        return pg->len(units, string)
    }
    private.redrawfuncs.len := function(ref rec)
    {
        wider public;
        rec.return := public.len(rec.units, rec.string);
    }

    ########### line
    public.line := function(xpts,ypts)
    {
        wider private, pg;
	local ok := T;

	if (len(xpts) != len(ypts)) 
	    return throw('line: inconsistant lengths for input arrays',
			 origin='pgplotmanager');
	if (length(xpts) == 0) return T;
        if (!is_numeric(xpts) || !is_numeric(ypts) || is_complex(xpts) ||
            is_complex(ypts)) 
	{
            return throw('line: x and y must be real arrays',
			 origin='pgplotmanager');
        }

        if (is_agent(pg)) ok := pg->line(xpts, ypts)
        if (private.record) private.displaylist.add(
                [_method='line', xpts=xpts,ypts=ypts])
        return ok;
    }
    private.redrawfuncs.line := function(rec)
    {
        wider public;
        public.line(rec.xpts,rec.ypts)
    }

    ########### move
    public.move := function(x,y)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->move(x, y)
        if (private.record) private.displaylist.add(
                [_method='move', x=x,y=y])
        return ok;
    }
    private.redrawfuncs.move := function(rec)
    {
        wider public;
        public.move(rec.x,rec.y)
    }

    ########### mtxt
    public.mtxt := function(side, disp, coord, fjust, text)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->mtxt(side, disp, coord, fjust, text)
        if (private.record) private.displaylist.add(
            [_method='mtxt', 
            side=side,disp=disp,coord=coord,fjust=fjust,text=text])
        return ok;
    }
    private.redrawfuncs.mtxt := function(rec)
    {
        wider public;
        public.mtxt(rec.side,rec.disp,rec.coord,rec.fjust,rec.text)
    }

    ########### numb   (Query, not logged)
    public.numb := function(mm, pp, form) {
        wider pg;
        return pg->numb(mm, pp, form)
    }
    private.redrawfuncs.numb := function(ref rec) {
        wider public;
        rec.return := public.numb(mm, pp, form)
    }
    

    ########### page 
    public.page := function()
    {
        wider private, pg;
	local ok := T;
        if (private.ask && private.interactive && private.plot_number != 0 &&
            (private.plot_number%private.plots_per_page)==0) 
	{
	    private.askfunction();
        }
        private.plot_number +:= 1;
        if (is_agent(pg)) ok := pg->page();
        if (private.record) private.displaylist.add(
                [_method='page'])
        return ok;
    }
    private.redrawfuncs.page := function(rec)
    {
        wider public;
        public.page()
    }

    ########### panl
    public.panl := function(ix, iy) {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->panl(ix,iy);
        if (private.record) private.displaylist.add([_method='panl',ix=ix,iy=iy]);
        return ok;
    }
    private.redrawfuncs.panl := function(rec) {
        wider public;
        public.panl(rec.ix, rec.iy);
    }
    
    ########### pap
    public.pap := function(width, aspect) {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->pap(width,aspect);
        if (private.record) private.displaylist.add([_method='pap',
                                               width=width,aspect=aspect]);
        return ok;
    }
    private.redrawfuncs.pap := function(rec) {
        wider public;
        public.pap(rec.width, rec.aspect);
    }
    
    ########### pixl
    public.pixl := function(ia, x1, x2, y1, y2) {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->pixl(ia, x1, x2, y1, y2);
        if (private.record) private.displaylist.add([_method='pixl',
                       ia=ia, x1=x1, x2=x2, y1=y1, y2=y2])
        return ok;
    }
    private.redrawfuncs.pixl := function(rec) {
        wider public;
        public.pixl(rec.ia, rec.x1, rec.x2, rec.y1, rec.y2);
    }

    ########### pnts
    public.pnts := function(x,y,symbol)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->pnts(x, y, symbol)
        if (private.record) private.displaylist.add(
                [_method='pnts', x=x,y=y,symbol=symbol])
        return ok;
    }
    private.redrawfuncs.pnts := function(rec)
    {
        wider public;
        public.pnts(rec.x,rec.y,rec.symbol)
    }

    ########### poly
    public.poly := function(xpts,ypts)
    {
        wider private, pg;
	local ok := T;

	if (len(xpts) != len(ypts)) 
	    return throw('plotxy: inconsistant lengths for input arrays',
			 origin='pgplotmanager');
	if (length(xpts) == 0) return T;
        if (!is_numeric(xpts) || !is_numeric(ypts) || is_complex(xpts) ||
            is_complex(ypts)) 
	{
            return throw('line: x and y must be real arrays',
			 origin='pgplotmanager');
        }

        if (is_agent(pg)) ok := pg->poly(xpts,ypts)
        if (private.record) private.displaylist.add(
                [_method='poly', xpts=xpts,ypts=ypts])
        return ok;
    }
    private.redrawfuncs.poly := function(rec)
    {
        wider public;
        public.poly(rec.xpts,rec.ypts)
    }

    ########### pt
    public.pt := function(xpts,ypts,symbol)
    {
        wider private, pg;
	local ok := T;

	if (len(xpts) != len(ypts)) 
	    return throw('pt: inconsistant lengths for input arrays',
			 origin='pgplotmanager');
	if (length(xpts) == 0) return T;
        if (!is_numeric(xpts) || !is_numeric(ypts) || is_complex(xpts) ||
            is_complex(ypts)) 
	{
            return throw('pt: x and y must be real arrays',
			 origin='pgplotmanager');
        }

        if (is_agent(pg)) ok := pg->pt(xpts, ypts,symbol)
        if (private.record) private.displaylist.add(
                [_method='pt', xpts=xpts,ypts=ypts,symbol=symbol])
        return ok;
    }
    private.redrawfuncs.pt := function(rec)
    {
        wider public;
        public.pt(rec.xpts,rec.ypts,rec.symbol)
    }

    ########### ptxt
    public.ptxt := function(x, y, angle, fjust, text)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->ptxt(x, y, angle, fjust, text)
        if (private.record) private.displaylist.add(
            [_method='ptxt', 
            x=x,y=y,angle=angle,fjust=fjust,text=text])
        return ok;
    }
    private.redrawfuncs.ptxt := function(rec)
    {
        wider public;
        public.ptxt(rec.x,rec.y,rec.angle,rec.fjust,rec.text)
    }

    ########### qah (Query - not logged)
    public.qah := function() {
        wider pg;
        return pg->qah();
    }
    private.redrawfuncs.qah := function(ref rec) {
        wider public;
        rec.return := public.qah();
    }

    ########### qcf (Query - not logged)
    public.qcf := function() {
        wider pg;
        return pg->qcf();
    }
    private.redrawfuncs.qcf := function(ref rec) {
        wider public;
        rec.return := public.qcf();
    }

    ########### qch (Query - not logged)
    public.qch := function() {
        wider pg;
        return pg->qch();
    }
    private.redrawfuncs.qch := function(ref rec) {
        wider public;
        rec.return := public.qch();
    }

    ########### qci (Query - not logged)
    public.qci := function() {
        wider pg;
        return pg->qci();
    }
    private.redrawfuncs.qci := function(ref rec) {
        wider public;
        rec.return := public.qci();
    }

    ########### qcir (Query - not logged)
    public.qcir := function() {
        wider pg;
        return pg->qcir();
    }
    private.redrawfuncs.qcir := function(ref rec) {
        wider public;
        rec.return := public.qcir();
    }

    ########### qcol (Query - not logged)
    public.qcol := function() {
        wider pg;
        return pg->qcol();
    }
    private.redrawfuncs.qcol := function(ref rec) {
        wider public;
        rec.return := public.qcol();
    }

    ########### qcr (Query - not logged)
    public.qcr := function(ci) {
        wider pg;
        return pg->qcr(ci);
    }
    private.redrawfuncs.qcr := function(ref rec) {
        wider public;
        rec.return := public.qcr(rec.ci);
    }

    ########### qcs (Query - not logged)
    public.qcs := function(units) {
        wider pg;
        return pg->qcs(units);
    }
    private.redrawfuncs.qcs := function(ref rec) {
        wider public;
        rec.return := public.qcs(rec.units);
    }

    ########### qfs (Query - not logged)
    public.qfs := function() {
        wider pg;
        return pg->qfs();
    }
    private.redrawfuncs.qfs := function(ref rec) {
        wider public;
        rec.return := public.qfs();
    }

    ########### qhs (Query - not logged)
    public.qhs := function() {
        wider pg;
        return pg->qhs();
    }
    private.redrawfuncs.qhs := function(ref rec) {
        wider public;
        rec.return := public.qhs();
    }

    ########### qid (Query - not logged)
    public.qid := function() {
        wider pg;
        return pg->qid();
    }
    private.redrawfuncs.qid := function(ref rec) {
        wider public;
        rec.return := public.qid();
    }

    ########### qinf (Query - not logged)
    public.qinf := function(item) {
        wider pg;
        return pg->qinf(item);
    }
    private.redrawfuncs.qinf := function(ref rec) {
        wider public;
        rec.return := public.qinf(rec.item);
    }

    ########### qitf (Query - not logged)
    public.qitf := function() {
        wider pg;
        return pg->qitf();
    }
    private.redrawfuncs.qitf := function(ref rec) {
        wider public;
        rec.return := public.qitf();
    }

    ########### qls (Query - not logged)
    public.qls := function() {
        wider pg;
        return pg->qls();
    }
    private.redrawfuncs.qls := function(ref rec) {
        wider public;
        rec.return := public.qls();
    }

    ########### qlw (Query - not logged)
    public.qlw := function() {
        wider pg;
        return pg->qlw();
    }
    private.redrawfuncs.qlw := function(ref rec) {
        wider public;
        rec.return := public.qlw();
    }

    ########### qpos (Query - not logged)
    public.qpos := function() {
        wider pg;
        return pg->qpos();
    }
    private.redrawfuncs.qpos := function(ref rec) {
        wider public;
        rec.return := public.qpos();
    }

    ########### qtbg (Query - not logged)
    public.qtbg := function() {
        wider pg;
        return pg->qtbg();
    }
    private.redrawfuncs.qtbg := function(ref rec) {
        wider public;
        rec.return := public.qtbg();
    }

    ########### qtxt (Query - not logged)
    public.qtxt := function(x, y, angle, fjust, text) {
        wider pg;
        return pg->qtxt(x, y, angle, fjust, text);
    }
    private.redrawfuncs.qtxt := function(ref rec) {
        wider public;
        rec.return := public.qtxt(rec.x,rec.y,rec.angle,rec.fjust,rec.text);
    }

    ########### qvp (Query - not logged)
    public.qvp := function(units) {
        wider pg;
        return pg->qvp(units);
    }
    private.redrawfuncs.qvp := function(ref rec) {
        wider public;
        rec.return := public.qvp(rec.units);
    }

    ########### qvsz (Query - not logged)
    public.qvsz := function(units) {
        wider pg;
        return pg->qvsz(units);
    }
    private.redrawfuncs.qvsz := function(ref rec) {
        wider public;
        rec.return := public.qvsz(rec.units);
    }

    ########### qwin (Query - not logged)
    public.qwin := function() {
        wider pg;
        return pg->qwin();
    }
    private.redrawfuncs.qwin := function(ref rec) {
        wider public;
        rec.return := public.qwin();
    }

    ########### rect
    public.rect := function(x1,x2,y1,y2)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->rect(x1,x2,y1,y2)
        if (private.record) private.displaylist.add(
                [_method='rect', 
                 x1=x1,x2=x2,y1=y1,y2=y2])
        return ok;
    }
    private.redrawfuncs.rect := function(rec)
    {
        wider public;
        public.rect(rec.x1,rec.x2,rec.y1,rec.y2)
    }

    ########### rnd (Query - not logged)
    public.rnd := function(x, nsub) {
        wider pg;
        return pg->rnd(x, nsub);
    }
    private.redrawfuncs.rnd := function(ref rec) {
        wider public;
        rec.return := public.rnd(x, nsub);
    }

    ########### rnge (Query - not logged)
    public.rnge := function(x1, x2) {
        wider pg;
        return pg->rnge(x1, x2);
    }
    private.redrawfuncs.rnge := function(ref rec) {
        wider public;
        rec.return := public.rnge(rec.x1, rec.x2);
    }

    ########### sah
    public.sah := function(fs, angle, vent)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->sah(fs, angle, vent)
        if (private.record) private.displaylist.add(
                [_method='sah', fs=fs, angle=angle, vent=vent])
        return ok;
    }
    private.redrawfuncs.sah := function(rec)
    {
        wider public;
        public.sah(rec.fs, rec.angle, rec.vent)
    }

    ########### save
    public.save := function()
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->save()
        if (private.record) private.displaylist.add(
                [_method='save'])
        return ok;
    }
    private.redrawfuncs.save := function(rec)
    {
        wider public;
        public.save()
    }

    ########### scf
    public.scf := function(font)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->scf(font)
        if (private.record) private.displaylist.add(
                [_method='scf', font=font])
        return ok;
    }
    private.redrawfuncs.scf := function(rec)
    {
        wider public;
        public.scf(rec.font)
    }

    ########### sch
    public.sch := function(size)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->sch(size)
        if (private.record) private.displaylist.add(
                [_method='sch', size=size])
        return ok;
    }
    private.redrawfuncs.sch := function(rec)
    {
        wider public;
        public.sch(rec.size)
    }

    ########### sci
    public.sci := function(ci)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->sci(ci)
        if (private.record) private.displaylist.add(
                [_method='sci', ci=ci])
        return ok;
    }
    private.redrawfuncs.sci := function(rec)
    {
        wider public;
        public.sci(rec.ci)
    }

    ########### scir
    public.scir := function(icilo, icihi)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->scir(icilo, icihi)
        if (private.record) private.displaylist.add(
                [_method='scir', icilo=icilo, icihi=icihi])
        return ok;
    }
    private.redrawfuncs.scir := function(rec)
    {
        wider public;
        public.scir(rec.icilo, rec.icihi)
    }

    ########### scr
    public.scr := function(ci, cr, cg, cb)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->scr(ci,cr,cg,cb)
        if (private.record) private.displaylist.add(
                [_method='scr', ci=ci,cr=cr,cg=cg,cb=cb])
        return ok;
    }
    private.redrawfuncs.scr := function(rec)
    {
        wider public;
        public.scr(rec.ci,rec.cr,rec.cg,rec.cb)
    }

    ########### scrn
    public.scrn := function(ci, name)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->scrn(ci, name)
        if (private.record) private.displaylist.add(
                [_method='scrn', ci=ci, name=name])
        return ok;
    }
    private.redrawfuncs.scrn := function(rec)
    {
        wider public;
        public.scrn(rec.ci, rec.name)
    }

    ########### sfs
    public.sfs := function(fs)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->sfs(fs)
        if (private.record) private.displaylist.add(
                [_method='sfs', fs=fs])
        return ok;
    }
    private.redrawfuncs.sfs := function(rec)
    {
        wider public;
        public.sfs(rec.fs)
    }

    ########### shls
    public.shls := function(ci, ch, cl, cs)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->shls(ci,ch,cl,cs)
        if (private.record) private.displaylist.add(
                [_method='shls', ci=ci,ch=ch,cl=cl,cs=cs])
        return ok;
    }
    private.redrawfuncs.shls := function(rec)
    {
        wider public;
        public.shls(rec.ci,rec.ch,rec.cl,rec.cs)
    }

    ########### shs
    public.shs := function(angle, sepn, phase)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->shs(angle, sepn, phase)
        if (private.record) private.displaylist.add(
                [_method='shs', angle=angle, sepn=sepn, phase=phase])
        return ok;
    }
    private.redrawfuncs.shs := function(rec)
    {
        wider public;
        public.shs(rec.angle, rec.sepn, rec.phase)
    }

    ########### sitf
    public.sitf := function(itf)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->sitf(itf)
        if (private.record) private.displaylist.add(
                [_method='sitf', itf=itf])
        return ok;
    }
    private.redrawfuncs.sitf := function(rec)
    {
        wider public;
        public.sitf(rec.itf)
    }

    ########### sls
    public.sls := function(ls)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->sls(ls)
        if (private.record) private.displaylist.add(
                [_method='sls', ls=ls])
        return ok;
    }
    private.redrawfuncs.sls := function(rec)
    {
        wider public;
        public.sls(rec.ls)
    }

    ########### slw
    public.slw := function(lw)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->slw(lw)
        if (private.record) private.displaylist.add(
                [_method='slw', lw=lw])
        return ok;
    }
    private.redrawfuncs.slw := function(rec)
    {
        wider public;
        public.slw(rec.lw)
    }

    ########### stbg
    public.stbg := function(tbci)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->stbg(tbci)
        if (private.record) private.displaylist.add(
                [_method='stbg', tbci=tbci])
        return ok;
    }
    private.redrawfuncs.stbg := function(rec)
    {
        wider public;
        public.stbg(rec.tbci)
    }

    ########### subp
    public.subp := function(nxsub,nysub)
    {
        wider private, pg;
        private.plots_per_page := abs(nxsub*nysub);
	local ok := T;
        if (is_agent(pg)) ok := pg->subp(nxsub,nysub)
        if (private.record) private.displaylist.add(
                [_method='subp', nxsub=nxsub,nysub=nysub])
        return ok;
    }
    private.redrawfuncs.subp := function(rec)
    {
        wider public;
        public.subp(rec.nxsub,rec.nysub)
    }

    ########### svp
    public.svp := function(xleft,xright,ybot,ytop)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->svp(xleft,xright,ybot,ytop)
        if (private.record) private.displaylist.add(
                [_method='svp', 
                 xleft=xleft,xright=xright,ybot=ybot,ytop=ytop])
        return ok;
    }
    private.redrawfuncs.svp := function(rec)
    {
        wider public;
        public.svp(rec.xleft,rec.xright,rec.ybot,rec.ytop)
    }

    ########### swin
    public.swin := function(x1,x2,y1,y2)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->swin(x1,x2,y1,y2)
        if (private.record) private.displaylist.add(
                [_method='swin', 
                 x1=x1,x2=x2,y1=y1,y2=y2])
        return ok;
    }
    private.redrawfuncs.swin := function(rec)
    {
        wider public;
        public.swin(rec.x1,rec.x2,rec.y1,rec.y2)
    }

    ########### tbox
    public.tbox := function(xopt, xtick, nxsub, yopt, ytick, nysub)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->tbox(xopt, xtick, nxsub, yopt, ytick, nysub)
        if (private.record) {
            private.displaylist.add([_method='tbox', 
             xopt=xopt, xtick=xtick, nxsub=nxsub, yopt=yopt, ytick=ytick,
              nysub=nysub])
        }
        return ok;
    }
    private.redrawfuncs.tbox := function(rec)
    {
        wider public;
        public.tbox(rec.xopt, rec.xtick, rec.nxsub, rec.yopt, rec.ytick, 
                   rec.nysub)
    }

    ########### text
    public.text := function(x, y, text)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->text(x, y, text)
        if (private.record) private.displaylist.add(
            [_method='text', x=x,y=y,text=text])
        return ok;
    }
    private.redrawfuncs.text := function(rec)
    {
        wider public;
        public.text(rec.x,rec.y,rec.text)
    }

    ########### unsa
    public.unsa := function()
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->unsa()
        if (private.record) private.displaylist.add(
                [_method='unsa'])
        return ok;
    }
    private.redrawfuncs.unsa := function(rec)
    {
        wider public;
        public.unsa()
    }

    ########### updt
    public.updt := function()
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->updt()
        if (private.record) private.displaylist.add(
                [_method='updt'])
        return ok;
    }
    private.redrawfuncs.updt := function(rec)
    {
        wider public;
        public.updt()
    }

    ########### vect
    public.vect := function(a, b, c, nc, tr, blank)
    {
	wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->vect(a, b, c, nc, tr, blank);
        if (private.record)
            private.displaylist.add([_method='vect',
                                 a=a,b=b,c=c,nc=nc,tr=tr,blank=blank]);
        return ok;
    }
    private.redrawfuncs.vect := function(rec) {
        wider public; 
        public.vect(rec.a, rec.b, rec.c, rec.nc, rec.tr, rec.blank);
    }

    ########### vsiz
    public.vsiz := function(xleft,xright,ybot,ytop)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->vsiz(xleft,xright,ybot,ytop)
        if (private.record) private.displaylist.add(
                [_method='vsiz', 
                 xleft=xleft,xright=xright,ybot=ybot,ytop=ytop])
        return ok;
    }
    private.redrawfuncs.vsiz := function(rec)
    {
        wider public;
        public.vsiz(rec.xleft,rec.xright,rec.ybot,rec.ytop)
    }

    ########### vstd
    public.vstd := function()
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->vstd()
        if (private.record) private.displaylist.add(
                [_method='vstd'])
        return ok;
    }
    private.redrawfuncs.vstd := function(rec)
    {
        wider public;
        public.vstd()
    }

    ########### wedg
    public.wedg := function(side, disp, width, fg, bg, label)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->wedg(side, disp, width, fg, bg, label)
        if (private.record) private.displaylist.add(
                [_method='wedg', 
                side=side, disp=disp, width=width, fg=fg, bg=bg, label=label])
        return ok;
    }
    private.redrawfuncs.wedg := function(rec)
    {
        wider public;
        public.wedg(rec.side, rec.disp, rec.width, rec.fg, rec.bg, rec.label)
    }

    ########### wnad
    public.wnad := function(x1,x2,y1,y2)
    {
        wider private, pg;
	local ok := T;
        if (is_agent(pg)) ok := pg->wnad(x1,x2,y1,y2)
        if (private.record) private.displaylist.add(
                [_method='wnad', 
                 x1=x1,x2=x2,y1=y1,y2=y2])
        return ok;
    }
    private.redrawfuncs.wnad := function(rec)
    {
        wider public;
        public.wnad(rec.x1,rec.x2,rec.y1,rec.y2)
    }

    public.pgpa := function() { 
	wider pgpagent;
	return pgpagent;
    }

    public.setagent(pgpagent, closeable);
    pgpagent := F;               # this is important: must make sure there
                                 #   are no extra references to the agent!
    public.settings();

#    public.pg := ref pg;
#    public.private := ref private;

#    widgetset.addpopuphelp(agents=private);
    return ref public;
}

#@constructor
# create a pgplotmanager tool attached to an output PostScript file
# that can be sent to a printer. Interactive prompting will be
# disabled, so the pgplot function ask() will have no effect.  
# @param psfile     the name of the output file
# @param overwrite  whether to allow a previously existing file with 
#                      the same name to be overwritten
# @param color      if true, output is color postscript; otherwise,
#                      colors are converted to black-and-white or greyscale 
# @param landscape  if true, plot is written in landscape mode
#                      (i.e. with the bottom axis of the plot oriented
#                      along the long axis of the paper); otherwise,
#                      portrait mode is used.  
# @param playlist   a displaylist tool to use to store plot
#                      commands. This allows pre-record commands to be
#                      attached to this pgplotmanager. 
# @param record     sets whether recording is initially turned on
# @param widgetset  the widgetserver tool to use when creating an
#                      internal displaylist. This is used only when a
#                      displaylist is not provided via the playlist
#                      parameter. 
const pgplotps := function(psfile='pgplot.ps', overwrite=F, color=T, 
			   landscape=T, playlist=F, record=F, widgetset=F)
{
    include 'os.g';
    if (!overwrite && dos.fileexists(psfile)) 
	return throw(psfile, ': file exists; will not overwrite!', 
		     origin='pgplotps');

    local device := '/cps';
    if      (color==T && landscape==T) device := '/cps';
    else if (color==T && landscape==F) device := '/vcps';
    else if (color==F && landscape==T) device := '/ps';
    else if (color==F && landscape==F) device := '/vps';
    pgpa := pgplot(spaste(psfile,device));

    pgpm := pgplotmanager(pgpa, T, F, record, playlist, widgetset=widgetset);
    pgpa := F;

    return ref pgpm;
}

