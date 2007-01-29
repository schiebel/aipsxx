# scrolltext.g: a TK widget consisting of a text widget with optional scrollbars
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
#  $Id: scrolltext.g,v 19.2 2004/08/25 02:19:40 cvsmgr Exp $

pragma include once;

include 'widgetserver.g';
include 'unset.g';
include 'note.g';


const scrolltext := subsequence(ref parent, hscrollbar=T, 
    			        vscrollbar=T, 
                                width=30, height=8, wrap='none',
			        font='', disabled=F, text='', 
                                relief='flat', borderwidth=2, 
                                foreground='black',
                                background='lightgrey', 
				fill='both',   widgetset=dws)
{
    private := [=];

    private.ws := widgetset;
    private.outerFrame := private.ws.frame(parent, borderwidth=borderwidth, 
					   side='left', expand=fill);
    private.lbframe := private.ws.frame(private.outerFrame, side='top',
					borderwidth=2, expand='both');
    private.text := private.ws.text (private.lbframe, width, height, 
   			             wrap, font, disabled, text, relief, 
                                     borderwidth, foreground, background, 
                                     fill);
    if (is_fail(private.text)) fail;
#
    private.vsbframe := F;
    private.hsbframe := F;
    private.hsb := F;
    private.vsb := F;
    private.cornerpad := F;

###
    private.updateCornerpad := function() 
    {
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
	    # its not really necessary, remove one if its there
	    private.cornerpad := F;
	}
    }
		
###
    private.hscrollbar := function(makeOne) 
    {
	wider private;
#
	if (makeOne && !is_agent(private.hsb)) {
	    private.hsbframe := private.ws.frame(private.lbframe,
						 borderwidth=0,
						 expand='x');
	    private.hsb := private.ws.scrollbar(private.hsbframe, 
						orient='horizontal');
#
	    whenever private.hsb->scroll do {
               private.text->view($value);
            }
	    private.hsb.e1 := last_whenever_executed();
#
	    whenever private.text->xscroll do {
               private.hsb->view($value);
            }
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


###
    private.vscrollbar := function(makeOne) 
    {
	wider private;
	wider self;
#
	if (makeOne && !is_agent(private.vsb)) {
	    private.vsbframe := private.ws.frame(private.outerFrame,
						 borderwidth=0, expand='y');
	    private.vsbtoppad := private.ws.frame(private.vsbframe,
						  borderwidth=0, expand='none',
						  height=2, width=1);
#
	    private.vsb := private.ws.scrollbar(private.vsbframe);
	    whenever private.vsb->scroll do {
		private.text->view($value);
		self->vscroll($value);
	    }
	    private.vsb.e1 := last_whenever_executed();
#
	    whenever private.text->yscroll do {
               private.vsb->view($value);
            }
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

###
    const self.text := function() 
#
# This is necessary for popuphelp.  popuphelp needs to know what
# the lead widget is and "self" isn't a widget so we need a way
# to get at that lead widget.
#
    { 

	wider private; 
	return ref private.text;
    }

###
    const self.done := function() 
    {
	wider private, self;
#
	val private.text := F; 
	val private := F;
	val self := F;
	return T;
    }


### Constructor

    private.hscrollbar(hscrollbar);
    private.vscrollbar(vscrollbar);

    # forward most events
    whenever self->* do {
	wider private;
	has_result := F;
	thisname := $name;
	thisvalue := $value;

      # watch for events unique to this widget
	if (any(thisname == ["hscrollbar vscrollbar"])) {
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
		# everything else goes off to the internal text widget
		# for some of these, we care about the result
		if (any(thisname == ["get ranges"])) {
		    has_result := T;
		}

		# watch for multi-argument events
		# there should only be one, two or three argument events here
		if (is_record(thisvalue) && has_field(thisvalue, 'arg1') &&
		    has_field(thisvalue, 'arg2') && has_field(thisvalue, 'arg3')) {
 		    result := private.text->[thisname](thisvalue.arg1, thisvalue.arg2, thisvalue.arg3);
		} else if (is_record(thisvalue) && has_field(thisvalue, 'arg1') &&
		    has_field(thisvalue, 'arg2')) {
 		    result := private.text->[thisname](thisvalue.arg1, thisvalue.arg2);
		} else {
		    # pass everything else along, view events are records, but
		    # thats okay
		    result := private.text->[thisname](thisvalue);
		}
	    }
	}
	# emit a reply if one was called for by this event
	if (has_result) {
	    self->[thisname](result);
	}
    }

    # all events from text are re-emitted by self
    whenever private.text->* do { 
	self->[$name]($value);
    }
} 


