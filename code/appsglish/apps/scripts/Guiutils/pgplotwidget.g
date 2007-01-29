# pgplotwidget.g: Embeddable PGPLOT widget with displaylist.
#
#   Copyright (C) 1998,1999,2000,2001,2002
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
#   $Id: pgplotwidget.g,v 19.2 2004/08/25 02:00:49 cvsmgr Exp $
#
pragma include once;

include 'widgetserver.g';
include 'unset.g';

### Main documentation is in the reference manual.

const pgplotwidget := function(ref parentframe, size=[600,450],
				foreground='white', background='black',
				padx=2, pady=2,                        
				mincolors=2, maxcolors=100, havemessages=T,
				widgetset=dws)
{
    include 'note.g';
    include 'pgplotmanager.g';

    if (!have_gui()) 
        return throw('No pgplot gui possible. Set DISPLAY?',
		     origin='pgplotwidget');

    # Validate arguments
    if (!is_agent(parentframe)) fail 'pgplotwidget: invalid parentframe';
    if (!is_numeric(size) || length(size) != 2 || any(size<1))
        return throw('pgplotwidget: invalid size:', size, 
		     origin='pgplotwidget');
    if (!is_numeric(mincolors) || !is_numeric(maxcolors) || 
        length(mincolors) != 1 || length(maxcolors) != 1 ||
        mincolors < 1 || maxcolors < 1) 
    {
        return throw('invalid mincolors or maxcolors', mincolors, maxcolors,
		     origin='pgplotwidget');
    }
    if (!is_string(foreground) || length(foreground) != 1 || foreground=='') {
        note('invalid foreground: ', foreground, 
             ' using default (white)', priority='WARN', origin='pgplotwidget');
        foreground := 'white';
    }
    if (!is_string(background) || length(background) != 1 || background=='') {
        note('pgplotwidget: invalid background: ', background, 
             ' using default (black)', priority='WARN');
        background := 'black';
    }

    if (maxcolors < mincolors) maxcolors := mincolors; # Fix silently
    # 16 is the number of pgplot colors. We can probably share about this
    # many without degradation.
    cmapfail := mincolors > 16;  

    private := [=];

    # build the widget.  Start with the message window followed by the 
    # plot canvas
    private.text := F;
    if (havemessages) {
        private.lrtextframe := widgetset.frame(parentframe, side='left', 
					       expand='x');
        private.textframe := widgetset.frame(private.lrtextframe, side='left');
        private.text := widgetset.text(private.textframe,height=1, 
				       relief='sunken', foreground='blue',
				       disabled=T);
        private.text.shorthelp := 
            'Programs write messages here with plotter.message()'
    }    
    private.pgplot := widgetset.pgplot(parentframe, 
				       width=size[1], height=size[2],
                                       mincolors=mincolors, 
				       maxcolors=maxcolors,
                                       padx=padx, pady=pady,
                                       foreground=foreground,
                                       background=background,
                                       cmapfail=cmapfail);
    if (is_fail(private.pgplot)) {
        for (i in field_names(private)) {
            if (is_agent(private[i])) {
                deactivate whenever_stmts(private[i]).stmt;
            }
        }
        txt := paste ('pgplotwidget - cannot allocate ', mincolors,
                     ' colors');
        return throw(txt, origin='pgplotwidget.g');
    }

    # inherit functions from pgplotmanager
    public := pgplotmanager(private.pgplot, closeable=F, 
			    askfunction=pgplotaskviagui, widgetset=widgetset);
    private::isa := ['pgplotwidget', public.isa()];

    private.parentframe := ref parentframe;

    # Popup help function. We should really put this somewhere else since
    # it wastes space in every pgplotter here.
    public.shortnametofullname := function(name, index=F) {
	public.help(name);
    }

    private.callbacks := [=]; # Holds functions for cursor etc.
#    private.pgplot.private := ref private;
    private.pgplot->bind('<Motion>', 'motion');
    private.pgplot->bind('<Button-1>', 'button1');
    private.pgplot->bind('<Control-Button-1>', 'ctrlb1');
    private.pgplot->bind('<Button-2>', 'button2');
    private.pgplot->bind('<Control-Button-2>', 'ctrlb2');
    private.pgplot->bind('<Button-3>', 'button3');
    private.pgplot->bind('<Control-Button-3>', 'ctrlb3');
    private.pgplot->bind('<ButtonRelease>', 'buttonup');
    private.pgplot->bind('<Key>', 'key');

    # Save the id so we can tell when we are plotting on the GUI as opposed
    # to (e.g.) PostScript
    private.tkid := private.pgplot->qid();

    # The displaylist is used to save the plot commands for redrawing when the
    # screen is resized, saving to postscript, etc. public.recording() is used 
    # to see if plot commands are saved or not, and public.record is the users
    # access to changing this state.
    private.displaylist := public.displaylist();

    # Returns the callback number, so it can be removed in removecallback.

    public.getcallbacks := function () {
       wider private;
       rec := [=];
       indices := whenever_stmts(private.pgplot).stmt;
       n := length(indices);
       if (n > 0) {
          for (i in 1:length(indices)) {
             rec[i] := [=];
             rec[i].index := indices[i];
             rec[i].active := whenever_active(indices[i]);
          }
       }
#
       return rec;
    }
   
    private.redrawfuncs := [=]; # Functions for redrawing a particular command 
                             # from the display list.

    #### Non-PGPLOT functions

    # Returns the callback number, so it can be removed in removecallback.

    public.setcallback := function(onames, callback) {
        wider private;
        if (!is_function(callback)) {
            return throw('setcallback: callback must be a function!', 
			 origin='pgplotwidget');
        }

        if (!is_string(onames) || length(onames) < 1) {
            return throw('setcallback: names must be a string array of ',
			 'length >= 1', origin='pgplotwidget');
        }

        names := "";
        for (name in onames) {
            if (name == 'button') {
                if ( ! any( names == 'button1' ) )
                    names := [ names, 'button1' ]
                if ( ! any( names == 'button2' ) )
                    names := [ names, 'button2' ]
                if ( ! any( names == 'button3' ) )
                    names := [ names, 'button3' ]
            } else {
                if (name != 'motion' && 
		    name !~ m/^(?:button[1-3]|ctrlb[1-3])$/ && 
                    name != 'key' && name != 'buttonup')
                    return throw('name must be one of motion,',
                                 'button, buttonup, ctrlb or key', 
				 origin='pgplotwidget');
                else if ( ! any( names == name ) )
                        names := [ names, name ]
            }
        }

        before := sort(whenever_stmts(private.pgplot).stmt);
        whenever private.pgplot->[names] do {
           callback($value);
        }
        after := sort(whenever_stmts(private.pgplot).stmt);

        # It's probably the last one
        if (! any(before == after[length(after)])) {
            return after[length(after)];
        } else {
            # Alas, let's search for it. Quadratic, but we'll probably never
            # execute this.
            found := -1;
            for (i in after) if (!any(before == i)) { found := i; break;}
            if (found < 0) {
                return throw('Cannot find the callback number!', 
			     origin='pgplotwidget');
            }
            return found;
        }
    }
        
    public.deactivatecallback := function(which) {
        wider private;
        if (!is_numeric(which)) {
            return throw('illegal argument - you must ',
                         'remove callbacks by number', 
			 origin='pgplotwidget');
        }
        stmts := whenever_stmts(private.pgplot).stmt;
        for (i in which) {
            if (!any(stmts==i))
                return throw('no whenever matches callback #', i, 
			     origin='pgplotwidget');
        }
        deactivate which;
        return T;
    }

    public.activatecallback := function(which) {
        wider private;
        if (!is_numeric(which)) {
            return throw('illegal argument - you must ',
                         'remove callbacks by number', 
			 origin='pgplotwidget');
        }
        stmts := whenever_stmts(private.pgplot).stmt;
        for (i in which) {
            if (!any(stmts==i))
                return throw('no whenever matches callback #', i, 
			     origin='pgplotwidget');
        }
        activate which;
        return T;
    }

    public.postscript := function(file='aipsplot.ps', color=T, landscape=T)
    {
        wider private, public;
        if (!is_boolean(color) || !is_boolean(landscape) || !is_string(file) ||
            !length(file) == 1) {
            fail 'pgplotwidget.postscript: illegal parameters';
        }
        device := '/cps';
        if      (color==T && landscape==T) device := '/cps';
        else if (color==T && landscape==F) device := '/vcps';
        else if (color==F && landscape==T) device := '/ps';
        else if (color==F && landscape==F) device := '/vps';
        file := spaste(file, device);
        oldid := private.pgplot->qid();
        idev := private.pgplot->open(file);
        if (idev > 0) {
            private.pgplot->slct(idev);
            public.play(private.displaylist, F);
            dummy := private.pgplot->clos();

	    # The dummy assignment above is critical to avoid a bug whereby the
	    # print file gets sent before it is fully written to disk, for
	    # large (> 1MB) files

            private.pgplot->slct(oldid);
        } else {
            fail paste('pgplotwidet.postscript: error opening pgplot device-',
                       file);
        }
        return T;
    }

    public.plotfile := function(file='aipsplot.plot')
    {
        wider public;
        return private.displaylist.save(file);
    }

    public.isa := function() { return private::isa; }
    public.type := function() { return private::isa[1]; }

    private.superdone := public.done;
    public.done := function()
    {
        wider public, private, parentframe;
        private.pgplot := F;
	private.parentframe := F;
	private.superdone();
	if (! is_boolean(private.text)) {
	    private.textframe := F;
	    private.lrtextframe := F;
	    private.text := F;
	}
        private := F;
        val parentframe := F;   # wish this didn't have to be here
        val public := F;
	return T;
    }

    #@
    # print a message to the message window.  An empty string clears the 
    # message window.
    ##
    public.message := function(text) {
        wider private, public;

        if (has_field(private, 'text') && is_agent(private.text)) {

            # Only write message if we have a message widget!
            private.text->delete('start', 'end');
	    private.text->insert(text, 'start');
            nlcount := text ~ m/\n/g;
	    if (nlcount > 0) {
		note('Message in pgplotter only supports one line of text',
		     priority='WARN', origin='pgplotwidget');
		note('Full message is as follows:', priority='WARN', 
		     origin='pgplotwidget');
		note(text, priority='WARN', origin='pgplotwidget');
	    }
        }

        # But always record it so we can replay it.
        if (public.recording()) 
            private.displaylist.add([_method='message',text=text]);
        return T;
    }
    private.redrawfuncs.message := function(rec) {
        wider public;
        public.message(rec.text);
    }

    # Set the cursor
    public.cursor := function(mode='norm', x=0, y=0, color=1) {
        wider public, private;
        return private.pgplot->cursor(mode=mode, x, y, color);
    }

    #### "Emulated" standard pgplot functions. Returns a record. *BLOCKS*
    #### until a key is typed in the pgplot window.
    # [ok=bool, x=float, y=float, ch=string]. Not recorded.
    public.curs := function(x=0,y=0) {
        wider private;
	local proceed := F
	while (!proceed) {
	    await private.pgplot->key,private.pgplot->button1,private.pgplot->button2,private.pgplot->button3;
	    retval := [ok=T, x=$value.world[1], y=$value.world[2]];
	    if (has_field($value, 'key')) {
		retval.ch := $value.key;
	    } else {
		buttons := "A D X";
		#!! if/else should be removed, and if portion
		#!! retained after rivet et al. is removed
		if (has_field($value, 'code'))
		    retval.ch := buttons[$value.code];
		else
		    retval.ch := buttons[$value.button];
	    }
	    if (retval.ch >= ' ' && retval.ch <= '~') proceed := T;
        }
        return retval;
    }
    private.redrawfuncs.curs := function(ref rec)
    {
        wider public;
        rec.return := public.curs(rec.x, rec.y);
    }

    # Return the current size in pixels of the PGPLOT draw surface.
    public.size := function() {
        wider private;
        x := private.pgplot->width();
        y := private.pgplot->height();
        return [x,y];
    }

    #### Standard pgplot functions are covered by pgplotmanager

    #### Finish setup
    widgetset.addpopuphelp(agents=private);
    include 'plugins.g';
    plugins.attach('pgplotwidget', public);
    
    return ref public;
}

