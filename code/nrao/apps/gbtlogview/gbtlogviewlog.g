# gbtlogviewlog.g: glish closure object for handling log messages if no dl present
# Copyright (C) 1999,2002
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
# $Id: gbtlogviewlog.g,v 19.0 2003/07/16 03:42:30 aips2adm Exp $

# include guard
pragma include once;

include 'widgetserver.g';

# see if the defaultlogger is already here

if (!is_defined('defaultlogger')) {

# okay, add ours

# the Red Box Of Death - make this portable and in widgets

    const errbox := function()
    {
	self   := [=];
	public := [=];
	self.frame := [=];
	self.gui := F;
	self.count := 0;


	public.addmsg := function(msg)
	{
	    wider self;

	    if (! have_gui()) {
		return T;
	    }

	    if (!is_agent(self.frame) || !self.gui) {
		self.frame := dws.frame(title='SEVERE Errors');
		self.frame.self := ref self;
		self.tf := dws.frame(self.frame,side='left');
		self.text := dws.text(self.tf, background='red', width=80,
				  relief='sunken');
		self.text.self := ref self;
		self.gui := T;

		# Add scrollbars
		self.vsb := dws.scrollbar(self.tf);
		self.vsb.self := ref self;
		whenever self.vsb->scroll do {
		    $agent.self.text->view($value);
		}
		whenever self.text->yscroll do {
		    $agent.self.vsb->view($value);
		}

		self.bottomframe := dws.frame(self.frame, side='left');
		self.msg := dws.message(self.bottomframe, '0 errors');
		self.dismissframe := dws.frame(self.bottomframe, side='right');
		self.dismissbutton := dws.button(self.dismissframe, 'Dismiss');
		self.dismissbutton.self := ref self;
		whenever self.dismissbutton->press do {
		    $agent.self.frame := F;
		    $agent.self.count := 0;
		}
		whenever self.frame->killed do {
		    $agent.self.count := 0;
		    $agent.self.gui := F;
		}

	    }

	    self.count +:= 1;
	    self.text->insert(spaste(msg, '\n\n'), '0.0');
	    self.msg->text(paste(as_string(self.count), 'errors'));
	}

	return public;
    }

    # default to only keep the most recent 50
    gbtlogviewlog := function(length=50) {
	private := [=];
	public := [=];

	private.length := length;
	private.gui := F;
	private.rbod := errbox();

	# identify this as gbtlogviewlog
	public.type := function() { return "gbtlogviewlog";}

	public.clear := function() {
	    wider private;
	    private.next := 1;
	    private.time := "";
	    private.severity := "";
	    private.message := "";
	    private.origin := "";
	    if (is_record(private.gui)) {
		private.gui.txt->delete('start','end');
	    }
	}

	j := public.clear();

	private.append := function(which) {
	    wider private;
	    # currently just severity and message are written
	    msg := spaste(private.severity[which], ': ', 
			  private.message[which]);
	    if (is_record(private.gui)) {
		if (private.severity[which] != 'NORMAL') {
		    private.gui.txt->insert(spaste(msg,'\n'),'end', 'highlight');
		} else {
		    private.gui.txt->insert(spaste(msg,'\n'),'end');
		}
		if (len(private.time) >= private.length) {
		    private.gui.txt->delete('1.0','2.0');
		}
		# Give the Red Box O' Death on SEVERE messages
		if (private.severity[which] == "SEVERE") {
		    private.rbod.addmsg(private.message[which]);
		}
		if (private.gui.endvisible) {
		    private.gui.txt->see('end');
		}
	    }
	}

	# the required log and note interface
	# postglobally, postlocally, and postcli are ignored here
	public.log := function(timeString,severity,message,origin='', 
			       postglobally=T, postlocally=T, postcli=F)
	{
	    wider private;
	    if (private.next > private.length) private.next:=1;
	    private.time[private.next] := timeString;
	    private.severity[private.next] := severity;
	    private.message[private.next] := message;
	    if (len(origin)==0) origin := '';
	    private.origin[private.next] := origin;
	    private.append(private.next);
	    private.next +:= 1;

    	}

	public.note := function(..., origin='',
				postglobally=T, postlocally=T, postcli=F) {
	    wider private;
	    str := "";
	    if (num_args(...) > 0) {
		for (i in 1:num_args(...)) {
		    str := paste(str, as_string(nth_arg(i, ...)));
		}
	    }
	    j := public.log('','NORMAL', str, origin);
	}

	# adjust the length
	public.length := function(length) {
	    wider private;
	    wider public;
	    t := private.time;
	    sev := private.severity;
	    msg := private.message;
	    org := private.origin;
	    nxt := private.next;
	    lastlen := private.length;
	    private.length := length;
	    j := public.clear();
	    if (len(t) >= lastlen) {
		# we have filled up and are wrapping, stuff from nxt
		# on comes first
		if (nxt <= len(t)) {
		    for (i in nxt:len(t)) {
			public.log(t[i],sev[i], msg[i], org[i]);
		    } 
		}
	    }  # stuff from 1 to just before nxt
	    if (nxt > 1) {
		for (i in 1:(nxt-1)) {
		    public.log(t[i],sev[i], msg[i], org[i]);
		}
	    }
	}

	# make the GUI
	public.gui := function(parent=F) {
	    wider private, public;
	    if (is_record(private.gui)) return;
	    private.gui := [=];
	    private.gui.endvisible := T;
	    if (!is_agent(parent)) {
		private.gui.parent := dws.frame();
	    } else {
		private.gui.parent := parent;
	    }

	    private.gui.ru := dws.rollup(private.gui.parent, title='AIPS++ Log Messages',
					 show=F);
	    # this part is certainly generalizable to a useful widget
	    # listbox with scrollbars, (make these auto appearing eventually)

	    private.gui.outf := dws.frame(private.gui.ru.frame(),
					  borderwidth=0,
					  side='top', expand='both');
	    private.gui.txtf := dws.frame(private.gui.outf,
					  side='left', expand='both');
	    private.gui.txt := dws.text(private.gui.txtf,fill='both',
					wrap='none');
	    private.gui.txt->config('highlight', background='LightYellow');
	    private.gui.vsb := dws.scrollbar(private.gui.txtf);
	    private.gui.bf := dws.frame(private.gui.outf, side='right', 
					borderwidth=0, expand='x');
	    private.gui.pad := dws.frame(private.gui.bf,
					 expand='none', width=23, height=23,
					 relief='groove');
	    private.gui.hsb := dws.scrollbar(private.gui.bf, 
					     orient='horizontal');
	    whenever private.gui.vsb->scroll, private.gui.hsb->scroll do
		private.gui.txt->view($value);
	    whenever private.gui.txt->yscroll do {
		wider private;
		private.gui.vsb->view($value);
		private.gui.endvisible := ($value[2] == 1);
	    }
	    whenever private.gui.txt->xscroll do
		private.gui.hsb->view($value);

	    public.length(private.length);
	}

	public.dbg := function() { wider private; return private;}


	return public;
    }

    defaultlogger := gbtlogviewlog();
    dl := ref defaultlogger;
}
 
