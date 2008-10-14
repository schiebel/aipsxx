# ttimer.g: Test functions in timer.g
#
#   Copyright (C) 1996,1997
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
#   $Id: ttimer.g,v 19.2 2004/08/25 02:10:43 cvsmgr Exp $
#

include 'timer.g';
include 'note.g';

# Test timer singleton object

const ttimer := function()
{
    # Make sure timer exists
    if (!any(symbol_names(is_record) == 'timer')) {
	return throw('ttimer - no timer object exists');
    }
    # See if timer appears to be OK
    if (!is_const(timer) || !has_field(timer, 'wait') || 
	!has_field(timer, 'execute') || !has_field(timer, 'remove')) {
	return throw('ttimer - timer object is garbled');
    }

    # timer.wait()
    start := time();
    timer.wait(1.5);
    diff := time() - start;
    if (diff + 1.0e-6 < 1.5) { # Allow a microsecond slop
	return throw('ttimer - waited ', diff, ' seconds instead of 1.5');
    }

    count := 0;
    tag := '';
    badinterval := F;
    callback := function(interval, name) {
	wider count, badinterval;
	count +:= 1;
	if (abs(interval - 0.1) > 1.0e-6) {
	    badinterval := T;
	}
	return T;
    }

    finishcallback := function(interval, name) {
	wider tag, badinterval;
	# timer.remove()
	timer.remove(tag);
	if (abs(interval - 0.55) > 1.0e-6) {
	    badinterval := T;
	}
	return T;
    }
    # timer.execute()
    tag := timer.execute(callback, interval=0.1, oneshot=F);
    tag2 := timer.execute(finishcallback, interval=0.55);
    if (is_fail(tag) || is_fail(tag2)) {
	return throw('ttimer - got a fail from timer.execute()');
    }
    timer.wait(1);
    if (count != 5) {
	return throw('ttimer - expected count to be 5, not ', count);
    }
    if (badinterval) {
	return throw('ttimer - got an incorrect interval in a callback');
    }

    count := 0;
    callback := function(interval, name) {
	wider count;
	count +:= 1;
	return T;
    }

    # Add a whole bunch of callbacks to make sure that the garbage-collection
    # code doesn't make anything bad happen.
    for (i in 1:250) timer.execute(callback, interval=1.0);
    timer.wait(2); # Hopefully this is long enough on all hosts

    if (count != 250) {
	return throw('ttimer - expected count to be 250, not ', count);
    }

    note('ttimer - OK', origin='ttimer()');
    return T;
}
