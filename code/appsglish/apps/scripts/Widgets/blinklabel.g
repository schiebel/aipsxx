# blinklabel.g: a simple Glish/Tk label which can be made to blink
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
# $Id: blinklabel.g,v 19.2 2004/08/25 02:11:45 cvsmgr Exp $

pragma include once;

include 'widgetserver.g';

blinklabel := subsequence(ref parent, text='label', justify='left',
			  hlp='',
			  padx=4, pady=2, font='', width=0, relief='flat',
			  borderwidth=2, foreground='black',
			  background='lightgrey', anchor='c', 
			  fill='none', blink=F, interval=1,
			  widgetset=dws) {
    its := [=];
    its.blink.on := F;
    its.blink.state := F;

    its.label := widgetset.label(parent, text, justify, padx, pady, font,
				 width, relief, borderwidth, foreground,
				 background, anchor, fill);
    
    widgetset.popuphelp(its.label, hlp);

    const its.blinker := function(interval, name) {
	wider its;
	its.blink.state := !its.blink.state;
	widgetset.tk_hold();
	if (its.blink.state) {
	    its.label->foreground(background);
	    its.label->background(foreground);
	} else {
	    its.label->foreground(foreground);
	    its.label->background(background);
	}
	widgetset.tk_release();
    }

    const self.blink := function(on=T, interval=1) {
	wider its;
	t := eval('include \'misc.g\'');
	if (its.blink.on == on) {
	    return;
	}
	its.blink.on := on;
	if (its.blink.on) {
	    its.blinker(F, F);
	    its.blink.id := timer.execute(its.blinker, 
					  interval=interval, 
					  oneshot=F);
	} else {
	    timer.remove(its.blink.id);
	    if (its.blink.state) {
		its.blinker(F, F);
	    }
	}
    }

    const self.done := function ()
    {
       wider its, self;
       val its := F;
       val self := F;
       return T;
    }

    if (blink) {
	self.blink(blink, interval);
    }

}
