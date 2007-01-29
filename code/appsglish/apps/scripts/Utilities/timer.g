# timer.g: Execute functions periodically or once, and wait for specified time
#
#   Copyright (C) 1998,1999,2001
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
#   $Id: timer.g,v 19.2 2004/08/25 02:10:33 cvsmgr Exp $
#


# Summary
# timer.wait(interval);
# name := public.execute(callback, interval=60, oneshot=T);
# public.remove(name); # turn off if oneshot==F
#
# The callback must be a function that takes two input arguments:
#    1. The interval
#    2. The name ("tag") that generated this call.
# It can return anything except a fail.

pragma include once;
include 'note.g';

timer := function()
{
    private := public := [=];
    private.timer := F;
    private.nvalid := 0; # Count of how many active callbacks we have
    private.callbacks := [=];

    private.handleTimerEvents := function(name, value)
    {
	wider private;
	if (has_field(private.callbacks, name) &&
	    is_record(private.callbacks[name])) {
	    ok := private.callbacks[name].callback(value, name);
	    # We need to check again that it is a record in case the
	    # callback removed itself.
	    if (has_field(private.callbacks, name) &&
		is_record(private.callbacks[name]) &&
		private.callbacks[name].oneshot == T) {
		private.timer->unregister(name);
		private.callbacks[name] := F;
		private.nvalid -:= 1;
	    }
	    if (is_fail(ok)) {
		return throw('timer - callback ', name, ' failed\n', ok);
	    }
	} else {
	    # Unregister it - no callback. This is harmless even if it is
	    # a oneshot
	    private.timer->unregister(name);
	}
	return T;
    }

    private.init := function() {
        wider private;
        private.timer := client('timer');
        if (!is_agent(private.timer)) {
            return throw('timer - could not start timing client!');
        }

	## Attempt some sort of restart on failure.
	whenever private.timer->fail do {
	    wider private;
	    throw(spaste(
'timer: The timer process has died unexpectedly. This is a serious error and\n',
'       should be reported as a bug, especially if it can be repeated. I am\n',
'       attempting to restart the executable, but registered callbacks are\n',
'       lost, and your session might have to be restarted.\n'));
	    private.init();
	}

        private.callbacks := [=]; # name=[callback=function, oneshot=boolean]

	whenever private.timer->* do {
	    wider private;
	    private.handleTimerEvents($name, $value);
	}
    }


    public.execute := function(callback, interval=60, oneshot=T) {
        wider private;
        if (is_boolean(private.timer)) private.init();
        if (!is_numeric(interval) || length(interval) != 1 ||
        interval < 0.01) {
            return throw('timer.execute - interval must be a scalar > 0.01s');
        }
        if (!is_function(callback)) {
            return throw('timer.execute - callback must be a function');
        }
        if (!is_boolean(oneshot) || length(oneshot) != 1) {
            return throw('timer.execute - oneshot must be a boolean scalar');
        }
        name := private.timer->register(interval)
        private.callbacks[name] := [callback=callback, oneshot=oneshot];
	private.nvalid +:= 1;

	# When we have > 100 removed callbacks, collect garbage
	if (length(private.callbacks) > (private.nvalid + 100)) {
	    tmp := [=];
	    for (name in field_names(private.callbacks)) {
		if (is_record(private.callbacks[name])) {
		    tmp[name] := private.callbacks[name];
		}
	    }
	    private.callbacks := tmp;
	    private.nvalid := length(private.callbacks);
	}

        return name;
    }

    public.remove := function(name) {
        wider private;
        if (is_boolean(private.timer)) private.init();
        if (!is_string(name) || length(name) != 1) {
            return throw('timer.remove - name must be a scalar string');
        }
        private.timer->unregister(name);
        if (!has_field(private.callbacks, name) || 
	    !is_record(private.callbacks[name])) {
            return F; # Return quietly, but signal
        }
	private.nvalid -:= 1;
        private.callbacks[name] := F;
        return T;
    }

    public.wait := function(interval) {
        wider private;
        if (is_boolean(private.timer)) private.init();
        if (!is_numeric(interval) || length(interval) != 1 ||
        interval < 0.01) {
            return throw('timer.wait - interval must be a scalar > 0.01s');
        }
        tag := private.timer->register(interval);
        await private.timer->[tag];
        private.timer->unregister(tag);
        return T;
    }

    return ref public;
}

timer := timer();            # singleton
const timer := const timer;  # Make it constant
