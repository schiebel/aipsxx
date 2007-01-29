# tapedeck.g: a widget to provide play/stop/rewind style buttons
# Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: tapedeck.g,v 19.2 2004/08/25 02:20:57 cvsmgr Exp $

pragma include once;

include 'widgetserver.g';

# The tapedeck subsequence: standard sort of arguments, except
# hasstop, hasplay, hasstep, hasto indicates which sort of buttons
# to include, and hasforward, hasreverse indicates which directions
# to provide.  *color ones are obvious!
const tapedeck := subsequence(parent,
			      background='lightgray',
			      hasstop=T, hasplay=T, hasstep=T, hasto=T,
			      hasforward=T, hasreverse=T,
			      stopcolor='black', playcolor='black',
			      stepcolor='black', tocolor='black',
			      orient='horizontal',
			      widgetset=dws) {
    its := [=];

    ############################################################
    ## whenever pusher                                        ##
    ############################################################
    its.whenevers := [];
    its.pushwhenever := function() {
        wider its;
        its.whenevers[len(its.whenevers) + 1] := last_whenever_executed();
    }

    its.parent := parent;
    its.wdgts := widgetset;
    if (!is_agent(its.parent)) {
	fail 'Parent is not an agent';
    }
    
    its.side := 'left';
    its.horiz := T;
    if (orient == 'vertical') {
	its.side := 'bottom';
	its.horiz := F;
    }

    its.wdgts.tk_hold();
    its.frame := its.wdgts.frame(its.parent, side=its.side,
				 background=background,
				 borderwidth=0, relief='flat',
				 padx=0, pady=0, expand='none');
    its.frame->unmap();
    its.wdgts.tk_release();
    if (hasto && hasforward) {
	if (its.horiz) {
	    its.tostart := its.wdgts.button(its.frame,
					    bitmap='leftleftarrowstop.xbm',
					    text='|<<',
					    foreground=tocolor,
					    background=background);
	} else {
	    its.tostart := 
		its.wdgts.button(its.frame, bitmap='downdownarrowstop.xbm',
				 text='v\nv\n-', foreground=stepcolor,
				 background=background);
	}
	its.wdgts.popuphelp(its.tostart, 'Rewind to start');
	whenever its.tostart->press do {
	    self->tostart();
	} its.pushwhenever();
    }
    if (hasreverse) {
	if (hasstep) {
	    if (its.horiz) {
		its.stepbkwd := 
		    its.wdgts.button(its.frame, bitmap='leftarrowstop.xbm',
				     text='|<', foreground=stepcolor,
				     background=background);
	    } else {
		its.stepbkwd := 
		    its.wdgts.button(its.frame, bitmap='downarrowstop.xbm',
				     text='v\n-', foreground=stepcolor,
				     background=background);
	    }
	    its.wdgts.popuphelp(its.stepbkwd, 'Reverse step');
	    whenever its.stepbkwd->press do {
		self->reversestep();
	    } its.pushwhenever();
	}
	if (hasplay) {
	    if (its.horiz) {
		its.playbkwd := its.wdgts.button(its.frame,
						 bitmap='leftarrow.xbm',
						 text='<',
						 foreground=playcolor,
						 background=background);
	    } else {
		its.playbkwd := its.wdgts.button(its.frame,
						 bitmap='downarrow.xbm',
						 text='v',
						 foreground=playcolor,
						 background=background);
	    }				     
	    its.wdgts.popuphelp(its.playbkwd, 'Reverse play');
	    whenever its.playbkwd->press do {
		self->reverseplay();
	    } its.pushwhenever();
	}
    }
    if (hasstop) {
	its.stop := its.wdgts.button(its.frame,
				     bitmap='square.xbm',
				     text='[]',
				     foreground=stopcolor,
				     background=background);
	its.wdgts.popuphelp(its.stop, 'Stop');
	whenever its.stop->press do {
	    self->stop();
	} its.pushwhenever();
    }
    if (hasforward) {
	if (hasplay) {
	    if (its.horiz) {
		its.playfwd := its.wdgts.button(its.frame,
						bitmap='rightarrow.xbm',
						text='>',
						foreground=playcolor,
						background=background);
	    } else {
		its.playfwd := its.wdgts.button(its.frame,
						bitmap='uparrow.xbm',
						text='^',
						foreground=playcolor,
						background=background);
	    }
	    its.wdgts.popuphelp(its.playfwd, 'Forward play');
	    whenever its.playfwd->press do {
		self->forwardplay();
	    } its.pushwhenever();
	}
	if (hasstep) {
	    if (its.horiz) {
		its.stepfwd := its.wdgts.button(its.frame,
						bitmap='rightarrowstop.xbm',
						text='>|',
						foreground=stepcolor,
						background=background);
	    } else { 
		its.stepfwd := 
		    its.wdgts.button(its.frame, bitmap='uparrowstop.xbm',
				     text='_\n^', foreground=stepcolor,
				     background=background);
	    }
	    its.wdgts.popuphelp(its.stepfwd, 'Forward step');
	    whenever its.stepfwd->press do {
		self->forwardstep();
	    } its.pushwhenever();
	}
    }
    if (hasto && hasreverse) {
	if (its.horiz) {
	    its.toend := its.wdgts.button(its.frame,
					  bitmap='rightrightarrowstop.xbm',
					  text='>>|',
					  foreground=tocolor,
					  background=background);
	} else {
	    its.toend := 
		its.wdgts.button(its.frame, bitmap='upuparrowstop.xbm',
				 text='_\n^\n^', foreground=tocolor,
				 background=background);
	}
	its.wdgts.popuphelp(its.toend, 'Fast-forward to end');
	whenever its.toend->press do {
	    self->toend();
	} its.pushwhenever();
    }
    its.frame->map();

    self.dismiss := function() {
	self.done();
    }

    self.done := function() {
	wider its, self;
	deactivate its.whenevers;
	its.frame := 0;
	val self := 0;
	val its := 0;
    }

    self.enable := function() {
	its.frame->enable();
    }
    self.disable := function() {
	its.frame->disable();
    }

}
