# bimafiller.g: Convert miriad vis file into an AIPS++ MeasurementSet
#
#   Copyright (C) 1999,2000
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
pragma include once;

include "guicomponents.g";
include "guimisc.g";
include "table.g";
include "note.g";

include "bimafillerGUI.g";
   
const bimafiller := function(msname='', mirname='')
{
    private := [=];
    public := [=];

    private.msname := msname;
    private.mirname := mirname;

    public.fill := function(...) {
        if (!has_field(private, 'mirname') || private.mirname == '') {
            private.writeallerror('No input MIRIAD uv dataset specified');
            return F;
        } else if (!has_field(private, 'msname') || private.msname == '') {
            private.writeallerror('No output MS specified');
            return F;
        } else if (tableexists(private.msname)) {
            private.writeallerror(spaste('Output MS ', private.msname, 
					 ' exists'));
            return F;
        } else {
            okdir := sh().command(spaste('test -d ', private.mirname));
            okvis := sh().command(spaste('test -f ', private.mirname, 
					 '/visdata'));
            if (okdir.status != 0) {
                private.writeallerror(spaste('Input MIRIAD uv dataset ',
					     private.mirname, 
					     ' is not a directory'));
                return F;
            } else if (okvis.status != 0) {
                private.writeallerror(spaste('Input dataset ', 
					     private.mirname,
					    ' contains no visdata'));
                return F;
            } else {
                private.writeallinfo(spaste('Filling MS ', private.msname, 
					    ' from MIRIAD uv dataset ',
					    private.mirname));
                bimafillreturn := sh().command(spaste('bimafiller vis=', 
						      private.mirname,
						      ' MS=',
						      private.msname));
		private.writeallinfo(bimafillreturn.lines);
            }
        }
	return T;
    }
    public.setoptions := function(msname='', mirname='') {
        wider public, private;
	if (msname != '') { private.msname := msname; }
	if (mirname != '') { private.mirname := mirname; }
	return T;
    }
    public.gui := function() {
        wider public, private;
	if (!have_gui()) {
	    private.info("Can't start GUI, check DISPLAY environment variable");
	} else {
	    private.makegui();
	}
    }
    public.done := function() {
        wider public, private;
        val private := F;
        val public := F;
    }
    private.info := function(...) {
	wider private;
	note(..., origin='bimafiller()');
    }
    private.error := function(...) {
	wider private;
	note(..., priority='WARN', origin='bimafiller()');
    }
    private.makegui := function() {
	wider private;
	widgetset := dws;
        widgetset.tk_hold();
	private.wholeframe := widgetset.frame(title='Bimafiller', side='top');
	private.wholeworkframe := widgetset.frame(private.wholeframe, 
						  relief='groove', 
						  side='top');
	private.wholelogframe := widgetset.frame(private.wholeframe, 
						 relief='groove', 
						 side='bottom');
	private.wholebottomframe := widgetset.frame(private.wholeframe, 
						    relief='groove', 
						    side='bottom');
	private.writeinfo := function(...) {
	    wider private;
	    private.log->delete('start', 'end');
	    private.log->insert(spaste(...), 'start');
	}
	private.writeerror := function(...) {
	    wider private;
	    private.log->delete('start', 'end');
	    private.log->insert(spaste(...), 'start');
	    private.log->addtag('error', '1.0', '2.0');
	    private.log->config('error', background='white');
	}
	private.workframe := function(new=F) {
	    wider private;
	    if (new || !has_field(private, 'workframe') || 
		!is_agent(private.workframe)) {
		private.workframe := F;
		private.workframe := widgetset.frame(private.wholeworkframe, 
						     side='top');
	    }
	    return ref private.workframe;
	}
	private.msoutframe := function(new=F) {
	    wider private;
	    if (new || !has_field(private, 'msoutframe') || 
		!is_agent(private.msoutframe)) {
		private.msoutframe := F;
		private.msoutframe := widgetset.frame(private.wholeworkframe,
						      side='top');
	    }
	    return ref private.msoutframe;
	}
	private.funclogframe := function(new=F) {
	    wider private;
	    if (new || !has_field(private, 'funclogframe') || 
		!is_agent(private.funclogframe)) {
		private.funclogframe := F;
		private.funclogframe := 
		    widgetset.frame(private.wholelogframe,
				    side='top');
	    }
	    return ref private.funclogframe;
	}
	private.funcbottomframe := function(new=F) {
	    wider private;
	    if (new || !has_field(private, 'funcbottomframe') || 
		!is_agent(private.funcbottomframe)) {
		private.funcbottomframe := F;
		private.funcbottomframe := 
		    widgetset.frame(private.wholebottomframe,
				    side='top');
	    }
	    return ref private.funcbottomframe;
	}
	private.funcbottomleftframe := function(new=F) {
	    wider private;
	    if (new || !has_field(private, 'funcbottomleftframe') || 
		!is_agent(private.funcbottomleftframe)) {
		private.funcbottomleftframe := F;
		private.funcbottomleftframe := 
		    widgetset.frame(private.bottomframe,
				    side='left');
	    }
	    return ref private.funcbottomleftframe;
	}
	private.writeinfo('Bimafiller fills a MIRIAD uv dataset into a MS');
	private.fileframe := widgetset.frame(private.workframe(new=T), 
					     side='left');
	private.filelabel := widgetset.label(private.fileframe,
					     text='Input MIRIAD file:', 
					     width=18);
	private.fileentry := widgetset.entry(private.fileframe, width=40);
	if (has_field(private, 'mirname') && private.mirname != '') {
	    private.fileentry->insert(private.mirname);
	}
	private.browsebutton := widgetset.button(private.fileframe, 
						 'Browse');
	private.outframe  := widgetset.frame(private.msoutframe(new=T), 
					     side='left');
	private.outlabel  := widgetset.label(private.outframe, 
					     text='Output MS:',
					     width=18);
	private.outentry  := widgetset.entry(private.outframe, width=40);
	if (has_field(private, 'msname') && private.msname != '') {
	    private.outentry->insert(private.msname);
	}
	private.logframe := widgetset.frame(private.funclogframe(new=T),
					    side='right');
	private.bottomframe := widgetset.frame(private.funcbottomframe(new=T),
					       side='right');
	private.dismissbutton := widgetset.button(private.bottomframe, 
						  'Dismiss',
						  type='dismiss');
	private.fillbutton := 
	    widgetset.button(private.funcbottomleftframe(new=T), 
			     'Fill',
			     type='action');
	private.log := widgetset.text(private.logframe, height=4,
				      width=50, disabled=T,
				      relief='ridge');
	widgetset.tk_release();
	whenever private.browsebutton->press do {
	    ch := mirchooser();
	    whenever ch->* do {
		if (is_string($value.guiReturns)) {
		    private.fileentry->delete('start', 'end');
		    private.fileentry->insert($value.guiReturns);
		}
	    }
	}
        whenever private.dismissbutton->press, private.wholeframe->killed do {
	    private.wholeframe->unmap();
	}
	whenever private.fillbutton->press do {
	    private.mirname := private.fileentry->get ('start', 'end');
	    private.msname  := private.outentry->get ('start', 'end');
	    public.fill();
	}
    } # makegui
    private.writeallerror := function(logtext) {
        wider private;
	outline := '';
	for (i in 1:length(logtext)) {
	    if (has_field(private, 'log')) {
		outline := spaste(outline, logtext[i], '\n');
	    }
	    private.error(logtext[i]);
	}
	if (has_field(private, 'log')) {
	    private.writeerror(outline);
	}
    }
    private.writeallinfo := function(logtext) {
        wider private;
	outline := '';
	for (i in 1:length(logtext)) {
	    if (has_field(private, 'log')) {
		outline := spaste(outline, logtext[i], '\n');
	    }
	    private.info(logtext[i]);
	}
	if (has_field(private, 'log')) {
	    private.writeinfo(outline);
	}
    }
    return ref public;
} #bimafiller
