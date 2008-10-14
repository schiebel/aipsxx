# choice.g: Get an answer from a user
# Copyright (C) 1996,1997,1998,1999,2001,2002
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
# $Id: choice.g,v 19.2 2004/08/25 01:58:03 cvsmgr Exp $

# result := choice(description,choices,interactive=have_gui(),timeout=30)

pragma include once;

include 'widgetserver.g';
include 'unset.g';

# If interactive is true, puts up a window with a text string and a set of
# buttons and returns the users selection. If !interactive, return the 
# default choice.  If no default choice is explicitly given, return
# the first choice in the list of choices when !interactive or 
# the widget times out.  The types of buttons can be optionally
# set through the types argument.  The button types default to
# "plain" unless types is set.  Other aips++ specific types
# include "halt", "dismiss", and "action" although there is no
# verification that the given types are valid types.
# When specified, default is element of choices to return.

const choice := function(description, choices, types=unset, default=1,
			 interactive=have_gui(), timeout=30,
			 widgetset=dws)
{
    include 'timer.g';
    include 'note.g';
    include 'alert.g';
    if (!is_string(description) || !is_string(choices)) {
	return throw('::choice(description,choices) : description and choices ',
		     'must be strings');
    }

    if (is_unset(types)) types := array('plain',len(choices));
    else if (!is_string(types) || len(types) != len(choices)) {
	return throw('::choice(description,choices,types) : types must be ',
		     'a string with the same number of elements as choices ',
		     'if types is set');
    }

    if (!is_integer(default) || len(default) != 1) {
	return throw('::choice(description,choices,types,default) : ',
		     'default must be an integer if it is set.');
    }

    if (default < 1 || default > len(choices)) {
	return throw('::choice(description,choices,types,default) : ',
		     'default element must be a valid index into choices');
    }

    if (!interactive || !have_gui()) {
        return default;
    }

    if (length(choices) > 5) {
	note('cannot handle >5 choices - returning default', priority='WARN');
	return default;
    }

    side := 'top';
    expand := 'y';
    nlcount := sum(split(description, '') == '\n');
    dlen := length(split(description,''));
    if (nlcount) dlen /:= nlcount; # average length per line
    if (dlen < 25) {
	side := 'left';
	expand := 'x';
    }
 
    widgetset.tk_hold();
    wholeframe := widgetset.frame(side='top', title='User Choice (AIPS++)');
    wholeframe->unmap();
    widgetset.tk_release();
    f := widgetset.frame(wholeframe, side=side);
    af := widgetset.frame(f,side='top',height=1,width=1,expand='none');
    a := alert(af, label='CHOICE');
    lf := widgetset.frame(f,side='top');
    l := widgetset.label(lf, description);
    bf := widgetset.frame(lf,side='left',expand=expand);
    timewin := widgetset.message(wholeframe, as_string(timeout),relief='groove');
   

    b := [=];
    for (i in [1:length(choices)]) {
	if (i == default) {
	    bf2 := widgetset.frame(bf,relief='sunken',expand='none');
            b[i] := widgetset.button(bf2, choices[i],type=types[i]);
	} else {
            b[i] := widgetset.button(bf, choices[i],type=types[i]);
	}
        b[i].count := i;
    }
    wholeframe->map();

    last := time();
    time_left := timeout;
    done := create_agent();   # An event will be sent to this when we time out
    done.count := default; # When we time out, always return the default choice;
    update_time := function(interval, name) {
	wider time_left, last, b;
	now := time();
	time_left -:= now - last;
	last := now;
	tmp := as_integer(time_left + 0.5);
	timewin->text(as_string(tmp));
	if (tmp <= 0) {
	    done->done();
	}
    }
    tag1 := timer.execute(update_time, interval=1, oneshot=F);

    if (length(choices) == 1)
	await b[1]->press, done->done, wholeframe->killed;
    else if (length(choices) == 2)
	await b[1]->press, b[2]->press, done->done, wholeframe->killed;
    else if (length(choices) == 3)
	await b[1]->press, b[2]->press, b[3]->press, done->done, wholeframe->killed;
    else if (length(choices) == 4)
	await b[1]->press, b[2]->press, b[3]->press, b[4]->press, done->done, wholeframe->killed;
    else if (length(choices) == 5)
	await b[1]->press, b[2]->press, b[3]->press, b[4]->press,b[5]->press, done->done, wholeframe->killed;
    which := default;

    if ($name == 'killed') {
	$agent.count := which; # Handle frame being killed like others
    }	

    if (!has_field($agent, 'count')) {
	note('choice: agent does not have count field, returning first choice!',
	     priority='SEVERE');
    } else {
	which := $agent.count; # Save right away
    }
    timer.remove(tag1);
    done := F;
    wholeframe := F;
    return choices[which];
}

# a few useful types of choices

# from a Done action.
const donechoice := function(description='Really destroy this tool?',
			     widgetset=dws) {
    doit := choice(description,"Yes Cancel", "halt dismiss", 2,
		   widgetset=widgetset);
    return (doit=='Yes');
}

const exitchoice := function(widgetset=dws) {
    return donechoice(paste('Pressing the \"Yes\" button will end this glish',
			    'session.\nAre you sure you want to do that?'),
		      widgetset=widgetset);
}
			    
    
