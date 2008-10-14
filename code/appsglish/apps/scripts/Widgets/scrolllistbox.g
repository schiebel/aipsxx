# scrolllistbox.g: a TK widget consisting of a listbox with optional scrollbars
# Copyright (C) 1998,1999,2001
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
#  $Id: scrolllistbox.g,v 19.2 2004/08/25 02:19:29 cvsmgr Exp $

pragma include once;

include 'widgetserver.g';
include 'unset.g';
include 'note.g';

# The scrolllistbox subsequence.  This is a listbox.  All events
# sent to this subsequence are forwarded to the underlying listbox.

const scrolllistbox := subsequence(ref parent, hscrollbar=T, 
				   vscrollbar=T, vscrollbarright=T,
				   seeoninsert=T,
				   width=20, height=6,
				   mode='browse', font='', relief='sunken', 
				   borderwidth=2, foreground='black',
				   background='lightgrey', 
				   exportselection=F, fill='both',
				   widgetset=dws)
{
    private := [=];

    private.ws := widgetset;
    private.isseenoninsert := seeoninsert;

    private.seeoninsert := function(torf) {
	wider private;
	private.isseenoninsert := torf;
    }

    if (vscrollbarright) {
	private.outerFrame := private.ws.frame(parent,
					       borderwidth=borderwidth, 
					       side='left', expand=fill);
    } else {
	private.outerFrame := private.ws.frame(parent,
					       borderwidth=borderwidth, 
					       side='right', expand=fill);
    }
    private.lbframe := private.ws.frame(private.outerFrame, side='top',
					borderwidth=2, expand='both');
    private.listbox := private.ws.listbox (private.lbframe, width, height, 
					   mode, font, relief, 2, foreground, 
					   background, exportselection,
					   fill='both');
    private.vsbframe := F;
    private.hsbframe := F;
    private.hsb := F;
    private.vsb := F;
    private.cornerpad := F;

    private.updateCornerpad := function() {
	wider private;
	if (is_agent(private.hsb) && is_agent(private.vsb)) {
	    # do we need to add one
	    if (!is_agent(private.cornerpad)) {
		private.cornerpad := private.ws.frame(private.vsbframe,
						      width=23, height=23,
						      borderwidth=0,
						      relief='flat',
						      expand='none');
	    }
	} else {
	    # it's not really necessary, remove one if it's there
	    private.cornerpad := F;
	}
    }
		

    private.hscrollbar := function(makeOne) {
	wider private;
	if (makeOne && !is_agent(private.hsb)) {
	    private.hsbframe := private.ws.frame(private.lbframe,
						 borderwidth=0,
						 expand='x');
	    private.hsb := private.ws.scrollbar(private.hsbframe, 
						orient='horizontal');
	    whenever private.hsb->scroll do {private.listbox->view($value);}
	    private.hsb.e1 := last_whenever_executed();
	    whenever private.listbox->xscroll do {private.hsb->view($value);}
	    private.hsb.e2 := last_whenever_executed();
	} else {
	    if (!makeOne && is_agent(private.hsb)) {
		deactivate private.hsb.e1;
		deactivate private.hsb.e2;
		private.hsb := F;
		private.hsbframe := F;
	    }
	}
	# update the cornerpad
	private.updateCornerpad();
    }

    private.vscrollbar := function(makeOne) {
	wider private;
	wider self;
	if (makeOne && !is_agent(private.vsb)) {
	    private.vsbframe := private.ws.frame(private.outerFrame,
						 borderwidth=0, expand='y');
	    private.vsbtoppad := private.ws.frame(private.vsbframe,
						  borderwidth=0, expand='none',
						  height=2, width=1);
	    private.vsb := private.ws.scrollbar(private.vsbframe);
	    whenever private.vsb->scroll do {
		# update this lisbox
		private.listbox->view($value);
		# and emit it so that it can be used elsewhere
		self->vscroll($value);
	    }
	    private.vsb.e1 := last_whenever_executed();
	    whenever private.listbox->yscroll do {private.vsb->view($value);}
	    private.vsb.e2 := last_whenever_executed();
	} else {
	    if (!makeOne && is_agent(private.vsb)) {
		deactivate private.vsb.e1;
		deactivate private.vsb.e2;
		private.vsb := F;
		private.vsbframe := F;
	    }
	}
	# update the cornerpad
	private.updateCornerpad();
    }

    private.hscrollbar(hscrollbar);
    private.vscrollbar(vscrollbar);

    # forward most events
    whenever self->* do {
	wider private;
	has_result := F;
	thisname := $name;
	thisvalue := $value;
      # watch for events unique to this widget
	if (any(thisname == ["hscrollbar vscrollbar seeoninsert"])) {
	    private[thisname](thisvalue);
	} else {
	    if (thisname == "vscrollview") {
		# the vscrollview event is used to move the vscrollbar
		whenever self->vscrollview do {
		    wider private;
		    if (is_agent(private.vsb)) {
			private.vsb->view(thisvalue);
		    }
		}
	    } else {
		# everything else goes off to the internal listboxes
		# for some of these, we care about the result
		if (any(thisname == ["get nearest selection"])) {
		    has_result := T;
		}

		# watch for multi-argument events
		# there should only be one or two argument events here
		if (is_record(thisvalue) && has_field(thisvalue, 'arg1') &&
		    has_field(thisvalue, 'arg2')) {
 		    result := private.listbox->[thisname](thisvalue.arg1, thisvalue.arg2);
		} else {
		    # pass everything else along, view events are records, but
		    # thats okay
		    result := private.listbox->[thisname](thisvalue);
		}
		if (private.isseenoninsert && thisname == "insert") 
		    private.listbox->see('end');
	    }
	}
	# emit a reply if one was called for by this event
	if (has_result) {
	    self->[thisname](result);
	}
    }

    # all events from lb are re-emitted by self
    whenever private.listbox->* do { 
	self->[$name]($value);
    }

    # This is necessary for popuphelp.  popuphelp needs to know what
    # the lead widget is and "self" isn't a widget so we need a way
    # to get at that lead widget.
    const self.listbox := function() { 
	wider private; 
	return ref private.listbox;
    }

    # the standard done function
    const self.done := function() {
	wider private, self;
	val private.listbox := F; # Do this until defect 2881 is resolved
	val private := F;
	val self := F;
	return T;
    }
} 


