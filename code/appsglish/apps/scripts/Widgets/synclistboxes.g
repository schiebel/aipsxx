# synclistboxes: syncronized listboxes.
# Copyright (C) 1998,1999,2001,2003
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
# $Id: synclistboxes.g,v 19.3 2005/04/15 15:33:59 dking Exp $
#
#----------------------------------------------------------------------------

pragma include once;

include 'widgetserver.g';

# todo: 
# o insert needs to accept an optional second argument specifying
#   the insertion point
# o height=same for all listboxes, width=possibly variable across listboxes
#   is only good for left/right packing
#   it should note the side argument and act accordingly
# o Might it be possible to handle the scrolling within a listbox using
#   the mouse by judicious use of bindings and the nearest event?
#   The current situation is that this sort of action can get the listboxes
#   out of apparent sync (i.e. the selections no longer line up).
# o The listbox/leadbox interaction may not be the best in the long run
#   perhaps popuphelp needs to be modified somewhat.


# the arguments after side (except for vscrollbar, hscrollbar
# seeoninsert, height, mode, and widgetset)
# may be either vectors or scalars.  If they are
# scalar values then they apply to all of the listboxes in
# this widget, if they are vectors, then they must have
# a length == nboxes and they apply to each box in turn.
# Boxes are added in the order seen in labels.
# 
# leadbox specifies which listbox is returned by the listbox
# function by default.  Other boxes can be requested by number,
# where the numbering starts at 1 with the first box added to
# the parent frame and proceeds to the last.
# The packing of these listboxes is controlled by the side argument.

const synclistboxes := subsequence(ref parent, nboxes=1, labels="",
				   leadbox=1, side='left', hscrollbar=T,
				   vscrollbar=T, vscrollbarright=T,
				   seeoninsert=T, 
				   width=20, height=6, mode='browse', 
				   font='', relief='sunken', borderwidth=2, 
				   foreground='black', background='lightgrey', 
				   exportselection=F, fill='both',
				   widgetset=dws)
{
  include 'unset.g';

    # there's not much point of going on if this is true
    if (nboxes < 1) 
	fail('There must be at least one box in a synclistboxes widget');
    private := [=];

    private.nlb := 0;
    private.lblist := [=];
    private.curr := 0;         # current position
    private.nlines := 0;       # #lines in each listbox
    private.height := height;

    private.vscroll := [=]

    private.outerFrame := widgetset.frame(parent,side=side,borderwidth=0);

    private.checkbox := function(whichbox) {
	return (is_integer(whichbox) &&
		whichbox>=1 && 
		whichbox <= private.nlb);
    }

    private.sendevent := function(theevent, thevalue, whichbox) {
	wider private;
	# watch for two argument values
	if (has_field(thevalue, 'arg1') &&
	    has_field(thevalue, 'arg2')) {
	    private.lblist[whichbox].lb->[theevent](thevalue.arg1,
						  thevalue.arg2);
	} else {
	    private.lblist[whichbox].lb->[theevent](thevalue);
	}
    }
 
    private.seeall := function(thevalue) {
	wider private;
	pos := 0;
	if (thevalue == 'end') {
	    pos := private.nlines - 1;
	} else if (thevalue != 'start') {
	    pos := as_integer(thevalue);
	}
	if (pos < 0) {
	    pos := 0;
	} else if (pos >= private.nlines) {
	    pos := private.nlines - 1;
	}
	private.sendallevent ('see', as_string(pos));
	private.curr := pos;
    }

    private.sendallevent := function(theevent, thevalue) {
	wider private;
	for (i in 1:private.nlb) {
	    private.sendevent(theevent, thevalue, i);
	}
    }

    private.vscrollCallback := function(theValue, lbId)
    {
	wider private;
	for (i in field_names(private.lblist)) {
	    if (private.lblist[i].id != lbId) {
		private.lblist[i].lb->view(theValue);
	    }
	}
    }

    # wait for events to catch up with the listboxes
    private.selectit := function(newSelection) {
	wider private;
	private.sendallevent('clear',[arg1='start',arg2='end']);
	# two argument selection => a range, pass on as is 
	if (is_record(newSelection) && has_field(newSelection,'arg1')) {
	    private.sendallevent('select',newSelection);
	    # jump to the top of the selection
	    private.seeall(newSelection.arg1);
	} else {
	    which := as_string(newSelection);
	    for (sel in which) {
		private.sendallevent('select',sel);
	    }
	    # jump to the top of the selection
	    private.seeall(which[1]);
	}
    }

    private.move := function(increment) {
	private.selectit(private.curr + increment);
    }

    private.findnlines := function() {
	wider private;
	lb := private.lblist[1].lb;
	lb->select('end');
	end := lb->selection();
	if (is_fail(end)) {
	    private.nlines := 0;
	} else {
	    private.nlines := end + 1;
	}
	lb->clear ('end');
    }


    private.setlbarg := function(values, limit) {
	if (len(values) < 1 ||
	    (len(values) > 1 && len(values) != limit)) {
	    fail;
	}
	val thearg := array(values[1], limit);
	if (len(values) > 1) val thearg := values;
	return thearg;
    }

    private.setleadbox := function(whichbox) {
	wider private;
	private.leadbox := whichbox;
	if (!private.checkbox(whichbox)) private.leadbox := 1;
    }

    if (len(labels) > 0) {
	thelabels := private.setlbarg(labels, nboxes);
	if (is_fail(thelabels)) 
	    fail('Invalid number of values for labels argument');
    } else {
	thelabels := array('',nboxes);
    }
    widths := private.setlbarg(width, nboxes);
    if (is_fail(widths)) 
	fail('Invalid number of values for width argument');
    fonts := private.setlbarg(font, nboxes);
    if (is_fail(fonts)) 
	fail('Invalid number of values for font argument');
    reliefs := private.setlbarg(relief, nboxes);
    if (is_fail(reliefs)) 
	fail('Invalid number of values for relief argument');
    borderwidths := private.setlbarg(borderwidth, nboxes);
    if (is_fail(borderwidths)) 
	fail('Invalid number of values for borderwidth argument');
    foregrounds := private.setlbarg(foreground, nboxes);
    if (is_fail(foregrounds)) 
	fail('Invalid number of values for foreground argument');
    backgrounds := private.setlbarg(background, nboxes);
    if (is_fail(backgrounds)) 
	fail('Invalid number of values for background argument');
    exportselections := private.setlbarg(exportselection, nboxes);
    if (is_fail(exportselections)) 
	fail('Invalid number of values for exportselection argument');
    fills := private.setlbarg(fill, nboxes);
    if (is_fail(fills)) 
	fail('Invalid number of values for fills argument');

    if ( vscrollbar && ! vscrollbarright && side == 'left' ||
	 vscrollbar && vscrollbarright && side == 'right' ) {

	private.vscroll.frame := widgetset.frame(private.outerFrame, borderwidth=0, expand='y', side='top');
	private.vscroll.sb := widgetset.scrollbar( private.vscroll.frame )

	whenever private.vscroll.sb->scroll do {
	    for (i in private.lblist ) {
		i.lb->view($value)
	    }
	}

	if ( hscrollbar ) {
	    private.vscroll.cornerpad :=widgetset.frame(private.vscroll.frame, width=23, height=23,
							borderwidth=0, relief='flat', expand='none');
	}
    }
	
    private.nlb := nboxes
    private.masterlb := 1
    for (i in 1:nboxes) {

	private.lblist[i].frame := 
	    widgetset.frame(private.outerFrame, borderwidth=0, expand=fill, side='top');
	private.lblist[i].lb := widgetset.listbox( private.lblist[i].frame,
			widths[i], height, mode, fonts[i], reliefs[i], borderwidths[i],
			foregrounds[i], backgrounds[i], exportselections[i], fills[i] );
	private.lblist[i].lb.id := i

	##  Perform select in other listboxes
	whenever private.lblist[i].lb->select do {
	    private.curr := $value;
	    for (j in private.lblist ) {
		if ( j.lb.id != $agent.id ) {
		    j.lb->clear('start','end')
		    if(len($value)>0) j.lb->select(as_string($value))
		}
	    }
	    # re-emit it
	    self->select(private.curr);
	}

	whenever private.lblist[i].lb->yscroll do {
	    if ( private.masterlb == $agent.id ) {
		if ( has_field( private.vscroll, 'sb' ) )
		    private.vscroll.sb->view($value)
		for ( j in private.lblist ) {
		    if ( j.lb.id != $agent.id ) {
			j.lb->view( spaste( 'yview moveto ',$value[1] ) )
		    }
		}
	    }
	}

	private.lblist[i].lb->bind( '<Enter>', 'enter' )
	whenever private.lblist[i].lb->enter do {
	    private.masterlb := $agent.id
	}

	if ( hscrollbar ) {
	    private.lblist[i].sb := widgetset.scrollbar(private.lblist[i].frame, orient='horizontal');
	    private.lblist[i].sb.id := i
	    whenever private.lblist[i].sb->scroll do {private.lblist[$agent.id].lb->view($value);}
	    whenever private.lblist[i].lb->xscroll do {private.lblist[$agent.id].sb->view($value);}
	}


	# bind up some convinence function for keyboard navigation
	# These go directly to the underlying listbox as having them
	# be forwarded through the scrolllistbox widget crashes glish.
	private.lblist[i].lb->bind('<Key-Up>','up');
	private.lblist[i].lb->bind('<Key-j>','up');
	private.lblist[i].lb->bind('<Key-KP_Up>','up');
	private.lblist[i].lb->bind('<Key-Down>','down');
	private.lblist[i].lb->bind('<Key-k>','down');
	private.lblist[i].lb->bind('<Key-KP_Down>','down');
	private.lblist[i].lb->bind('<Key-Page_Up>','pgup');
	private.lblist[i].lb->bind('<Key-Page_Down>','pgdown');
	private.lblist[i].lb->bind('<Key-Home>','home');
	private.lblist[i].lb->bind('<Key-KP_Home>','home');
	private.lblist[i].lb->bind('<Key-End>','end');
	private.lblist[i].lb->bind('<Key-KP_End>','end');

	whenever private.lblist[i].lb->up do {
	    private.move(-1);
	}

	whenever private.lblist[i].lb->down do {
	    private.move(1);
	}

	whenever private.lblist[i].lb->pgup do {
	    # The first dummy move is needed to keep listboxes aligned.
	    private.move(0);
	    private.move(-private.height);
	}

	whenever private.lblist[i].lb->pgdown do {
	    # The first dummy move is needed to keep listboxes aligned.
	    private.move(0);
	    private.move(private.height);
	}

	whenever private.lblist[i].lb->end do {
	    private.selectit('end');
	}

	whenever private.lblist[i].lb->home do {
	    private.selectit('start');
	}
    }

    if ( vscrollbar &&  vscrollbarright && side == 'left' ||
	 vscrollbar && ! vscrollbarright && side == 'right' ) {

	private.vscroll.frame := widgetset.frame(private.outerFrame, borderwidth=0, expand='y', side='top');
	private.vscroll.sb := widgetset.scrollbar( private.vscroll.frame )

	whenever private.vscroll.sb->scroll do {
	    for (i in private.lblist ) {
		i.lb->view($value)
	    }
	}

	if ( hscrollbar )
	    private.vscroll.cornerpad :=widgetset.frame(private.vscroll.frame, width=23, height=23,
							borderwidth=0, relief='flat', expand='none');
    }

    private.setleadbox(leadbox);

    # handle the events
    whenever self->leadbox do {
	wider private;
	private.setleadbox($value);
    }

    # things which always apply to all listboxes
    whenever self->["hscrollbar mode seeoninsert clear"] do {
	wider private;
	private.sendallevent($name, $value);
    }

    whenever self->height do {
	wider private;
	private.sendallevent($name, $value);
	private.height := as_integer($value);
    }

    whenever self->delete do {
	wider private;
	thevalue := $value;
	private.sendallevent('delete', thevalue);
	if (has_field(thevalue, 'arg1') && has_field(thevalue, 'arg2')) {
	    if (thevalue.arg1 == 'start'  &&  thevalue.arg2 == 'end') {
		private.nlines := 0;
	    } else {
		private.findnlines();
		private.seeall ('start');
	    }
	} else {
	    # An entry is only removed if its index is within the range.
	    for (inx in thevalue) {
		if (as_integer(inx) < private.nlines) {
		    private.nlines -:= 1;
		}
	    }
	}
    }

    whenever self->see do {
	private.seeall($value);
    }

    whenever self->select do {
	wider private;
	private.selectit($value);
    }

    whenever self->vscrollbar do {
	wider private;
	private.lblist[private.nlb].lb->vscrollbar($value);
    }

    # single argument events with an optional second argument indicating
    # which listbox this is to apply to
    whenever self->["background borderwidth exportselection font foreground relief width"] do {
	wider private;
	itsval := $value;
	if (has_field(itsval, 'arg1') && has_field(itsval, 'arg2')) {
	    whichbox := itsval.arg2;
	    itsval := itsval.arg1;
	    if (!private.checkbox(whichbox)) {
		throw(paste('invalid listbox for',$name,'event : ',whichbox));
	    } else {
		private.sendevent($name, itsval, whichbox);
	    }
	} else {
	    private.sendallevent($name, itsval);
	}
    }

    private.bindit := function(xevent, gevent, whichbox=unset) {
	if (!is_unset(whichbox)) {
	    if (!private.checkbox(whichbox)) {
		throw(paste('invalid listbox for bind event : ',whichbox));
	    } else {
		private.lblist[whichbox].lb->bind(xevent, gevent);
		whenever private.lblist[whichbox].lb->[gevent] do {
		    self->[gevent]($value);
		}
	    }
	} else {
	    for (i in private.lblist) {
		i.lb->bind(xevent, gevent);
		whenever i.lb->[gevent] do {
		    self->[gevent]($value);
		}
	    }
	}
    }

    # bind normally has two events, may have an optional third
    whenever self->bind do {
	wider private;
	result := F;
	if (has_field($value, 'arg3')) {
	    result := private.bindit($value.arg1, $value.arg2, $value.arg3);
	} else {
	    result := private.bindit($value.arg1, $value.arg2);
	}
    }

    # insert requires either a matrix of shape [nboxes, x] where
    # x is the number of rows to insert.  If a shape attribute is
    # missing, it is assumed to be [len($value),1].
    whenever self->insert do {
	wider private;
	shape := [0,0];
	theval := $value;
	if (has_field(theval::,'shape')) {
	    shape := theval::shape;
	} else {
	    shape := [len(theval), 1];
	}
	if (shape[1] != private.nlb) {
	    throw(paste('the insert event must have an integer number of values per listbox'));
	} else {
	    theval::shape := shape;
	    for (i in 1:shape[1]) {
		private.sendevent('insert',theval[i,], i);
	    }
	    private.nlines +:= shape[2];
	}
    }

    # get return a record indexed by lb number
    whenever self->get do {
	wider private;
	# get might have two arguments
	theval := $value;
	hasTwoArgs := has_field(theval,'arg1') && has_field(theval, 'arg2');
	result := [=];
	for (i in 1:private.nlb) {
	    if (hasTwoArgs) {
		result[i] := private.lblist[i].lb->get(theval.arg1,
						       theval.arg2);
	    } else {
		result[i] := private.lblist[i].lb->get(theval);
	    }
	}
	# and emit the result by the same name
	self->get(result);
    }

    # selection, nearest, any listbox will do
    whenever self->["selection nearest"] do {
	## it seems like somehow the $name/$value can be lost?
	local ename := $name
	local evalue := $value
	result := private.lblist[1].lb->[ename](evalue);
	self->[ename](result);
    }

    # the only function needed here, as in scrolllistbox, is a 
    # function to return a reference to one of the underlying listboxes
    # return leadbox if the argument is unset
    self.listbox := function(whichbox=unset) {
	wider private;
	usebox := whichbox;
	if (is_unset(whichbox)) { 
	    usebox := private.leadbox;
	} 
	if (!private.checkbox(usebox))
	    fail('invalid listbox number for listbox function');

	return private.lblist[usebox].lb;
    }

    # this is also standard practice
    self.done := function() {
	wider private;
	wider self;
	val private.outerFrame := F;
	val private := [=];
	val self := F;
	return T;
    }
}


