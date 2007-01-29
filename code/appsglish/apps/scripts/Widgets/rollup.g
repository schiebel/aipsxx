# rollup.g: a widget for hiding and showing a frame and its contents
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
#   $Id: rollup.g,v 19.2 2004/08/25 02:19:04 cvsmgr Exp $

pragma include once;

include 'widgetserver.g';

# The rollup subsequence: standard sort of arguments, with the 
# exceptions of: titleforeground and titlebackground which are
# the colors for the title and surrounding border of the embedded
# frame.
const rollup := subsequence(parent, font='', relief='flat', borderwidth=0,
			    side='top', padx=0, pady=0, expand='both',
			    foreground='black', background='lightgray',
			    title='', 
			    titleforeground='black', 
			    titlebackground='lightgray',
			    show=T, widgetset=dws) {
    prvt := [=];
    prvt.parent := parent;
    prvt.hidden := !show;
    prvt.enabled := T;
    if (!is_agent(prvt.parent)) {
	fail 'Parent is not an agent';
    }
    prvt.hiddenbutton := 'downarrow.xbm';
    prvt.exposedbutton := 'uparrow.xbm';
    prvt.myframe := widgetset.frame(parent, relief=relief,
				    borderwidth=2, side='top',
				    padx=padx, pady=pady, expand=expand,
				    background=titlebackground);
    prvt.topline := widgetset.frame(prvt.myframe, side='left', expand='x',
				    background=titlebackground, 
				    relief='raised');
    prvt.switchbutton_l := widgetset.button(prvt.topline, '.',
					    background=titlebackground,
					    foreground=titleforeground,
					    relief='flat',
					    borderwidth=0,
					    fill='y');
    prvt.title := title;
    prvt.helptext := paste('Click here to hide/show the', prvt.title, 'panel');
    widgetset.popuphelp(prvt.switchbutton_l, prvt.helptext);
    prvt.label := widgetset.button(prvt.topline, text=title,
				   font=font, relief='flat',
				   background=titlebackground, 
				   foreground=titleforeground,
				   fill='x',
				   borderwidth=0, anchor='w');
    widgetset.popuphelp(prvt.label, prvt.helptext);
    prvt.exportedframe := widgetset.frame(prvt.myframe, side=side, 
					  expand='both',
					  background=background,
					  relief='flat',
					  padx=2, pady=2);

    # a binding to pretend we have only one button!
    # commented out 1998/12/02 dbarnes: these bindings stop 
    # popuphelp from working...
#    prvt.switchbutton_l->bind('<Enter>', 'enter');
#    prvt.switchbutton_l->bind('<Leave>', 'leave');
#    whenever prvt.switchbutton_l->enter do {
#	prvt.label->background('#e9e9e9');
#    }
#    whenever prvt.switchbutton_l->leave do {
#	prvt.label->background(titlebackground);
#    }
#    prvt.label->bind('<Enter>', 'enter');
#    prvt.label->bind('<Leave>', 'leave');
#    whenever prvt.label->enter do {
#	prvt.switchbutton_l->background('#e9e9e9');
#    } 
#    whenever prvt.label->leave do {
#	prvt.switchbutton_l->background(titlebackground);
#    }

    # and now the event handling
    # many events are simply forwarded to the entry widget
    whenever self->["background bind borderwidth cursor disable disabled enabled exportselection font foreground justify relief view width"] do {
	wider prvt;
	prvt.exportedframe->[$name]($value);
    }

    # use this to get the frame that you put things in.
    self.frame := function() {
	return ref prvt.exportedframe;
    }
    
    # use this to toggle the view between visible and invisible.
    self.switch := function() {
	wider prvt;
	prvt.hidden := !prvt.hidden;
	prvt.update();
    }

    # use this to show the frame.
    self.down := function() {
	wider prvt;
	if (prvt.hidden) {
	    prvt.hidden := F;
	    prvt.update();
	}
    }
    self.show := function() { self.down(); }

    # use this to hide the frame.
    self.up := function() {
	wider prvt;
	if (!prvt.hidden) {
	    prvt.hidden := T;
	    prvt.update();
	}
    }
    self.hide := function() { self.up(); }
    self.hidden := function () {return prvt.hidden;}
    self.disable := function() 
    {
       if (prvt.enabled) {
          wider prvt;
          prvt.myframe->disable();
          prvt.enabled := F;
       }
       return T;
    }
    self.enable := function() 
    {
       if (!prvt.enabled) {
          wider prvt;
          prvt.myframe->enable();
          prvt.enabled := T;
       }
       return T;
    }
    self.done := function ()
    {
       wider prvt;
       val prvt := F;
       val self := F;
       return T;
     }
    self.setpopuphelp := function (short, long=unset, width=60)
    {
       wider prvt;
       if (strlen(short)>0 && !is_unset(long)) {
          widgetset.popuphelp(prvt.switchbutton_l, long, short, width=width, combi=T);
          widgetset.popuphelp(prvt.label, long, short, width=width, combi=T);
       } else if (strlen(short)>0) {
          widgetset.popuphelp(prvt.switchbutton_l, short, width=width);
          widgetset.popuphelp(prvt.label, short, width=width);
       }
    }

    prvt.update := function() {
	widgetset.tk_hold();
	if (prvt.hidden) {
	    prvt.topline->unmap();
	    prvt.switchbutton_l->bitmap(prvt.hiddenbutton);
	    prvt.switchbutton_l->text('v');
	    prvt.topline->map();
	    prvt.exportedframe->unmap();
	} else {
	    prvt.topline->unmap();
	    prvt.exportedframe->unmap();
	    prvt.switchbutton_l->bitmap(prvt.exposedbutton);
	    prvt.switchbutton_l->text('^');
	    prvt.topline->map();
	    prvt.exportedframe->map();
	}
	widgetset.tk_release();
    }

    whenever prvt.switchbutton_l->press,
	prvt.label->press do {
	self.switch();
    }

    t := prvt.update();
}
