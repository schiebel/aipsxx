# pgplotter.g: Standalone GUI PGPLOT (etc) window.
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
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: pgplotter.g,v 19.3 2004/08/25 02:00:19 cvsmgr Exp $
#


pragma include once;

include 'note.g'
include 'widgetserver.g'
    
const pgplotter := function(plotfile=unset, size=[600,450],
			    foreground='white', background='black',
			    mincolors=2, maxcolors=100,
			    widgetset=dws)
{
    ### Validate arguments

    if (!is_unset(plotfile) &&
	(!is_string(plotfile) || length(plotfile) !=1 || plotfile=='')) {
      return throw('pgplotter: invalid plotfile: \'', plotfile);
    }
    if (!is_numeric(size) || length(size) != 2 || any(size<1)) {
	note('pgplotter: invalid size: ', size, 
	     ' using [600,450]', priority='WARN');
	size := [600,450];
    }
    if (!is_string(foreground) || length(foreground) != 1 || 
	foreground=='') {
	note('pgplotter: invalid foreground: ', foreground, 
	     ' using default (white)', priority='WARN');
	foreground := 'white';;
    }
    if (!is_string(background) || length(background) != 1 || 
	background=='') {
	note('pgplotter: invalid background: ', background, 
	     ' using default (black)', priority='WARN');
	background := 'black';
    }

    if (!have_gui()) return throw('pgplotter: cannot make plotter. Set DISPLAY?');

    # Check environment variables
    include 'checker.g'
    dch.plotter(F);

    # Do the includes here so they are only done when needed.

    private := [=];
    public := [=];

    private.filecount := 0;

    private.widgetset := widgetset;

    private.guientry := widgetset.guientry();

    include 'printer.g';
    private.printer := printer();

    public.gui := function() {
      wider private, public;
      private.widgetset.tk_hold();
      private.topframe->map();
      for (i in "egui cgui") {
	if (has_field(private, i) && is_record(private[i]) &&
	    has_field(private[i], 'wholeframe') && 
	    is_agent(private[i].wholeframe)) {
	  private[i].wholeframe->map();
	}
      }
      private.widgetset.tk_release();
      return T;
    }

    public.screen := function() {
      wider private, public;
      private.topframe->unmap();
      return T;
    }

    public.title := function(msg) {
      wider private, public;
      private.topframe->title(msg);
      return T;
    }

    public.busy := function(isbusy=T) {
      wider private, public;
      if(isbusy) {
        private.topframe->cursor('watch');
      }
      else {
        private.topframe->cursor('left_ptr');
      }
      return T;
    }

    private.generatefilename := function(base=unset, ext='') {
      wider private;
      originalbase := base;
      if (is_unset(base) || !is_string(base)) {
	base := 'pgplotter';
      }
      include 'quanta.g';
      base := spaste(base, '.', 
		     split(dq.time(dq.quantity('today'),
				   form="dmy local"), '/')[1]);
      base := spaste(base, ':', private.filecount);
      private.filecount := private.filecount + 1;
      if (len(ext) > 0) {
	base := spaste(base, '.', ext);
      }
      include 'os.g';
      if (dos.fileexists(base)) {
	return private.generatefilename(originalbase, ext);
      } else {
	return base;
      }
    }

    private.psgui := function() {
      wider public, private
      private.widgetset.tk_hold()
      private.allframe := private.widgetset.frame(title='PS GUI',side='top')
      private.label1 := private.widgetset.label(private.allframe,'Postscript GUI')
      private.spacer0 := private.widgetset.frame(private.allframe,height=10)
      private.label2frame := private.widgetset.frame(private.allframe,side='left')
      private.label2 := private.widgetset.label(private.label2frame,'Postscript file: ')
      private.entry1 := private.widgetset.entry(private.label2frame,width=20,justify='left')
      private.entry1->insert('myplot.ps')
      private.label3frame := private.widgetset.frame(private.allframe,side='left')
      private.label3 := private.widgetset.label(private.label3frame,'Orientation    : ')
      private.landscapebutton := private.widgetset.button(private.label3frame,'Landscape',type='radio')
      private.portraitbutton := private.widgetset.button(private.label3frame,'Portrait',type='radio')
      private.landscapebutton->state(T)
      private.spacer1 := private.widgetset.frame(private.allframe,height=10)
      private.label4frame := private.widgetset.frame(private.allframe,side='left')
      private.pswrite := private.widgetset.button(private.label4frame, 'Write File',background='green');
      private.space := private.widgetset.label(private.label4frame,'                  ')
      private.psdismiss := private.widgetset.button(private.label4frame, 'Dismiss',type='dismiss');
      private.widgetset.tk_release()

      whenever private.psdismiss->press do
        private.allframe := F
      whenever private.pswrite->press do {
        fname := private.entry1->get()
	if (private.landscapebutton->state()) public.postscript(fname)
	else public.postscript(fname,landscape=F)
	dl.log(message=spaste('Postscript file ',fname,' written.'),priority='NORMAL')
        }
    }

    private.init_gui := function(newcmap=F) {
	wider public, private;
        private.widgetset.tk_hold();
	private.topframe := private.widgetset.frame(title='PGPlotter', side='top',
						    newcmap=newcmap);
	private.topframe.private := ref private;
	private.topframe.public := ref public;
	whenever private.topframe->resize do {
	  if(has_field($agent.public, 'refresh')) {
	    $agent.public.refresh();
	  }
	}


	## menubar
	private.menubar := private.widgetset.frame(private.topframe,expand='x', side='left');
	private.lmenubar := private.widgetset.frame(private.menubar, side='left',expand='x');
	private.rmenubar := private.widgetset.frame(private.menubar, side='right',expand='x');
	private.filemenubutton := private.widgetset.button(private.lmenubar, 'File', type='menu',
					 relief='flat');
	private.filemenubutton.shorthelp := 'File operations (open, save, print, etc.)';
	private.toolmenubutton := private.widgetset.button(private.lmenubar, 'Tools', type='menu',
					 relief='flat');
	private.toolmenubutton.shorthelp := 'Various tools for changing the plot';
	private.toolmenu := [=];
	private.editmenubutton := private.widgetset.button(private.lmenubar,
							   'Edit', type='menu',
							   relief='flat');
	private.editmenubutton.shorthelp := 'Edit the current plot';
	private.editmenubutton.edit := private.widgetset.button(private.editmenubutton, 'Edit');
	whenever private.editmenubutton.edit->press do {
	   public.editgui();
	}

	private.helpmenubutton := private.widgetset.helpmenu(private.menubar, menuitems=['PGPlotter'],
					       refmanitems=['Refman:pgplotter'],
					       helpitems=['AboutPGPlotter']);

	private.filemenu := private.editmenu := private.helpmenu := [=];

 	## file menu
	private.filemenu.open := private.widgetset.button(private.filemenubutton, 'Open pgplot file');
	whenever private.filemenu.open->press do {
	    include 'catalog.g';
            restoreit := function(file) {
	      if (is_string(file)) public.restore(file);
	    }
            private.widgetset.tk_hold();
            dc.gui();
            dc.show(show_types='Plot file');
            dc.setselectcallback(restoreit);                        
            private.widgetset.tk_release();
	}
	private.filemenu.save := private.widgetset.button(private.filemenubutton, 'Save pgplot file');
	private.filemenu.saveps := private.widgetset.button(private.filemenubutton, 'Save to postscript file');
	
	private.filemenu.print := private.widgetset.button(private.filemenubutton, 
					     'Print');
 	private.filemenu.dismiss := private.widgetset.button(private.filemenubutton, 'Dismiss',
							  type='dismiss');
 	private.filemenu.exit := private.widgetset.button(private.filemenubutton, 'Done',
							  type='halt');

	private.pgframe := private.widgetset.frame(private.topframe, side='top');

	include 'pgplotwidget.g';
	private.pgplotwidget :=
	    pgplotwidget(private.pgframe, size,
			 foreground=foreground, background=background,
			 mincolors=mincolors, maxcolors=maxcolors,
			 widgetset=private.widgetset);
	if (is_fail(private.pgplotwidget)) {
	    if (newcmap) {
		# avoid infinite recursion - fail if we have tried a private
		# colormap.
		return throw('pgplotter - could not create pgplot widget',
			     ' (even with a private colormap)');
	    }
	    note('pgplotter - trying to install a private colormap', 
		 priority='WARN');
	    # Clean ourselves up first
	    private.topframe->unmap(); # Make sure we are hidden
	    for (i in field_names(private)) {
		if (is_agent(private[i])) {
		    deactivate whenever_stmts(private[i]).stmt;
		    private[i] := F;
		}
	    }

	    return private.init_gui(T);
	  }
#
        private.userframe := private.widgetset.frame(private.topframe, side='left',expand='x', height=1);
	private.bottomframe := private.widgetset.frame(private.topframe, side='left',expand='x', height=1)
	private.blframe := private.widgetset.frame(private.bottomframe, side='left', expand='x', height=1);
	private.brframe := private.widgetset.frame(private.bottomframe, side='right',expand='x', height=1);
	private.done := private.widgetset.button(private.brframe, 'Done', type='halt');
	private.done.shorthelp := 'Exit this plotter';
 	whenever private.filemenu.exit->press, private.done->press do {
	    wider public, private;
	    public.done();
 	}

	private.dismiss := private.widgetset.button(private.brframe, 'Dismiss',type='dismiss');
	private.dismiss.shorthelp := 'Dismiss this plotter';
	whenever private.dismiss->press, private.filemenu.dismiss->press do {
	  public.screen();
	}

	private.savebutton := private.widgetset.button(private.blframe, 'Save');
	private.savebutton.shorthelp := 'Save the plot';
	whenever private.savebutton->press, private.filemenu.save->press do {
	  private.savefile := private.filelabel.get();
	  if (!is_unset(private.savefile) && private.savefile != '') {
	    public.plotfile(private.savefile);
	  }
	  else {
	    file := private.generatefilename(ext='plot');
	    public.plotfile(file);
	  }
	}
	whenever private.filemenu.saveps->press do {
	  private.psgui()
	}
	private.printbutton := private.widgetset.button(private.blframe, 'Print');
	private.printbutton.shorthelp := 'Print the plot';
	whenever private.printbutton->press, private.filemenu.print->press do {
	  file := private.filelabel.get();
	  if (is_unset(file) || !is_string(file)) {
	    file := private.generatefilename(ext='ps');
	  }
	  note('Writing postscript file ', file, origin='pgplotter.print');
	  public.postscript(file);
	  private.printer.gui(files=file);
	}

	private.filelabel := private.guientry.file(private.blframe, plotfile,
						   types='Plot file',
						   allowunset=T);
        private.filelabel.setwidth(16);
	private.clearbutton := private.widgetset.button(private.blframe, 'Clear');
	private.clearbutton.shorthelp := 'Clear the plot';
	whenever private.clearbutton->press do {
	  public.clear();
	}
	private.unzoombutton := private.widgetset.button(private.blframe, 'Unzoom');
	private.unzoombutton.shorthelp := 'Unzoom the plot; use middle mouse button to zoom';
	whenever private.unzoombutton->press do {
	  public.unzoom();
	}
	private.botspace := private.widgetset.frame(private.blframe, width=1, height=1);
	private.posframe := private.widgetset.frame(private.blframe, height=1,
						    relief='groove',side='left',
						    expand='none');
	private.posframe.shorthelp := 'World coordinates of cursor';
	private.xlabel := private.widgetset.label(private.posframe, '', width=9);
	private.ylabel := private.widgetset.label(private.posframe, '', width=9);
	# world coordinate display
# 	private.worldpos := private.widgetset.message(private.posframe, '', width=300);
        private.widgetset.tk_release();
 	updatepos := function(rec) {
 	    x := rec.world[1];
 	    y := rec.world[2];
 	    x::print.precision := 5;
 	    y::print.precision := 5;
 	    private.xlabel->text(as_string(x));
 	    private.ylabel->text(as_string(y));
	}
 	private.pgplotwidget.setcallback('motion', updatepos);

	whenever private.topframe->killed do {
	    public.done();
	}
    }

    ok := private.init_gui();
    private.savefile := private.filelabel.get();

    if (is_fail(ok)) {
	for (i in field_names(private)) private[i] := F;
	for (i in field_names(public)) public[i] := F;
	private := F;
	public := F;
	fail;
    }
    ### Mirror all the pgplotwidget functions in pgplotter
    for (name in field_names(private.pgplotwidget)) {
	public[name] := ref private.pgplotwidget[name];
    }

    ### override done
    public.done := function() {
	wider private, public;

        if(has_field(private, 'editgui')&&is_record(private.editgui)&&
	   has_field(private.editgui, 'done')) {
	  private.editgui.done();
	}

	for (i in field_names(private)) {
	    if (has_field(private[i], 'done') && # Call dtor's if any
		is_function(private[i].done)) {
		private[i].done();
	    }
	    private[i] := F;
	}
	val public := F;
	val private := F;
	return T;
    }

    ### override to set the file info
    public.plotfile := function(file=unset) {
	wider public, private;
        public.busy(T);
	if (is_unset(file)) {   # short-circuit
	    private.savefile := file;
	    public.busy(F);
	    return T;
	}
	ok := private.pgplotwidget.plotfile(file);
	if (ok) {
	    private.savefile := file;
	    private.lastsave := public.lastchange();
	    public.busy(F);
	    return T;
	} else {
	    public.busy(F);
  	    if(is_fail(ok)) fail;
	    return throw('Error saving file ', file);
	}
    }

    public.restore := function(file) {
	wider public, private;
        public.busy(T);
	ok := private.pgplotwidget.restore(file);
	if (ok) {
	    private.savefile := file;
	    private.lastsave := public.lastchange();
	}
        public.busy(F);
    }

    # TOOL support
    private.tools := [=];
    public.addtool := function(name, ref start, ref suspend)
    {
	wider public, private;
	if (!is_string(name) || !is_function(start) || !is_function(suspend)) {
	    return throw('pgplotwidget.addtool - illegal argument');
	}

	# While we silently overwrite the tool if asked to, we need to make
	# sure there is an entry in the Tools menu the first time we call
	# addtool for a given name.
	if (!has_field(private.tools, name)) {
	    private.toolmenu[name] := private.widgetset.button(private.toolmenubutton,
					     spaste(name, ' ...'));
	    private.toolmenu[name].name := name;
	    whenever private.toolmenu[name]->press do {
		public.tool($agent.name);
	    }
	}

	private.tools[name] := [=];
	private.widgetset.tk_hold();
	private.tools[name].wholeframe := private.widgetset.frame(title=spaste('Tool: ', name), 
						side='top');
	private.tools[name].wholeframe.name := name;
	whenever private.tools[name].wholeframe->killed do {
	    local name := $agent.name;
	    public.tool(name, F);
	    private.tools[name].wholeframe := F;
	    private.tools[name].state := [=];
	}

	private.tools[name].frame := private.widgetset.frame(private.tools[name].wholeframe, 
					   side='top');
	private.tools[name].dismissframe := 
	    private.widgetset.frame(private.tools[name].wholeframe, side='right');
	private.tools[name].dismiss := 
	    private.widgetset.button(private.tools[name].dismissframe, 'Dismiss',
		       type='dismiss');

	private.tools[name].dismiss.name := name;
	whenever private.tools[name].dismiss->press do {
	    local name := $agent.name;
	    public.tool(name, F);
	    private.tools[name].wholeframe->unmap();
	}

	private.tools[name].wholeframe->unmap();
	private.widgetset.tk_release();
	private.tools[name].start := start;
	private.tools[name].suspend := suspend;
	private.tools[name].state := [=];
	return T;
    }

    public.tool := function(name, show=T) {
	wider public, private;
	if (!has_field(private.tools, name))
	    return throw('pgplotwidget.tool -  no tool named ', name);
	if (show) {
	    if (is_agent(private.tools[name].wholeframe) &&
		!has_field(private.tools[name].wholeframe, 'killed')) {
		# Map the frame if it's around
		private.tools[name].wholeframe->map();
	    } else {
		# Otherwise, make it again (probably the user dismissed the
		# frame with the window manager).
		print public.addtool(name, private.tools[name].start,
			       private.tools[name].suspend);
		return public.tool(name); # Recurse (should only be once!)
	    }
	    ok := private.tools[name].start(private.tools[name].frame, 
					    public, private.tools[name].state);
	    # Remove the tool if something bad happened
	    if (is_fail(ok) || !ok) public.tool(name, F);
	    return ok;
	} else {
	    # uMap the frame
	    private.tools[name].wholeframe->unmap();
	    return private.tools[name].suspend(private.tools[name].frame, 
					       public, 
					       private.tools[name].state);
	}
    }

    public.type := function() {
      return 'pgplotter';
    }

    public.displaylist := function() {
      wider private;
      return private.pgplotwidget.displaylist();
    }

    public.canplay := function(value) {
      wider private;
      return private.pgplotwidget.canplay(value);
    }

    public.editgui := function() {
      wider private, public;

      include 'pgplottereditgui.g';
      if(has_field(private, 'editgui')&&is_record(private.editgui)&&
	 has_field(private.editgui, 'map')) {
	private.editgui.map();
      }
      else {
	private.editgui := pgplottereditgui(public, private.widgetset);
      }
      return T;
    }
  
    public.userframe := function () {
      wider private;
      return ref private.userframe;
    }

    plugins.attach('pgplotter', public);

    if (!is_unset(plotfile) && tableexists(plotfile)) {
      public.restore(plotfile);
    }
    private.savefile := plotfile;
    private.lastsave := public.lastchange();

    # Reset initially if nothing has been drawn (other than the initial state).
    if(has_field(public, 'refresh')) {
      if (public.displaylist().ndrawlist() <= 1) public.refresh();
    }

    widgetset.addpopuphelp(private);
    return ref public;
}

const pgplottertest := function(autodestruct=T) {
  global apgplottertest := pgplotter();
  if(has_field(apgplottertest, 'demo')) {
    apgplottertest.busy(T);
    apgplottertest.demo(interactive=F);
    apgplottertest.editgui();
    apgplottertest.busy(F);
    if(autodestruct) apgplottertest.done();
  }
  else {
    apgplottertest.done();
    return throw('pgplotter cannot be tested: demo plugin is not loaded');
  }
  return T;
}
