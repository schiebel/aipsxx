# sh.g: A persistent shell client
#
#   Copyright (C) 1998,1999
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
#   $Id: sh.g,v 19.2 2004/08/25 02:10:08 cvsmgr Exp $
#

pragma include once

include "note.g";

sh := function(start_now=T)
{
    private := [=];
    public := [=];

    private.sh := F
    private.agent := F

    private.counter := 0;

    private.lines := "";
    private.errlines := "";
    private.exit_status := 0;

    private.log := function(severity, message, origin='sh.g') {
      if (severity == '') { severity := 'NORMAL'; }
      note(message,priority=severity,origin=origin);
    }

    private.startagent := function() {
      wider private;
      if (is_boolean(private.agent)) {
        private.agent := create_agent();
        if (! is_agent(private.agent)) fail;
      }
      return T;
    }

    private.makeshell := function() {
      this := shell('exec sh', async=T);
      if (! is_agent(this)) fail;
      whenever this->fail do {
          this::Died := T;
          private.log('','SEVERE',
            'persistent shell server died: restarting','sh.makeshell');
      }
      return ref this;
    }

    private.starttimer := function() {
        wider private;
        private.timer := client('timer');
        if (!is_agent(private.timer)) {
            return throw('timer - could not start timing client!');
        }

	## Attempt some sort of restart on failure.
	whenever private.timer->fail do {
	    wider private;
	    throw(spaste(
'sh: The timer process has died unexpectedly. This is a serious error and\n',
'    should be reported as a bug, especially if it can be repeated. I am\n',
'    attempting to restart the executable, but registered callbacks are\n',
'    lost, and your session might have to be restarted.\n'));
            private.starttimer();
	}

    }


    private.startshell := function() {
      wider private;
      if (is_boolean(private.sh) || private.sh::Died) {
        val private.sh := private.makeshell();

	whenever private.sh->stdout do {

            parts := split($value, ',');
           if (length(parts)==3&&parts[1] ~ m/I_AM_DONE/) {
	      private.this_counter := as_integer(parts[2]);
              if(private.this_counter!=private.counter) {
                note("Misordered sequence of events in sh()", origin='sh.startshell',
		     priority='WARN');
	      }
	      private.exit_status := as_integer(parts[3]);
	      private.agent->[as_string(private.this_counter)]();
	    } else {
	      private.lines[length(private.lines) + 1] := $value;
	    }
	}
    
	whenever private.sh->stderr do {
	    private.errlines[length(private.errlines) + 1] := $value;
	}
    
      }
      return T;
    }

    public.command := function(commandline, timeout=0) {
	wider private;

	private.startagent();
	private.startshell();

        private.counter +:=1;
        fullcommandline := spaste(commandline, ';tmpstatus=$?; echo I_AM_DONE, ', private.counter,
				  ', $tmpstatus');
        if(timeout>0) {
	  private.starttimer();
          name := private.timer->register(timeout);
	  private.sh->stdin(fullcommandline);
	  await private.agent->[as_string(private.counter)], private.timer->[name];
	  if($name==name) {
	    private.log('','SEVERE', spaste('Command \'', commandline,
					    '\' timed out'),
			'sh.command');
	    private.exit_status := 1;
	    private.errlines := spaste('Command \'', commandline,
				       '\' timed out');
	  }
	}
        else {
	  private.sh->stdin(fullcommandline);
	  await private.agent->[as_string(private.counter)];
	}
	retval := [lines=private.lines, status=private.exit_status,
            errlines=private.errlines];
	private.lines := ""; private.errlines := "";
	return retval;
    }

    public.done := function() {
	wider public, private;
	deactivate (whenever_stmts(private.agent)).stmt
	if (!is_agent(private.sh)) {
	  private.log('SEVERE','shell has already been closed','sh.delete');
	} else {
	  private.sh->EOF();
        }
	private := F;
	val public := F;
    }

# debugging only
#    public.priv := function () {
#        return ref private;
#    }

    if (start_now) {
      private.startagent();
      private.startshell();
    }

    return ref public;
}

defaultsh:=sh();
defaultsh.done := function() {
  note('Cannot kill defaultsh', priority='WARN');
}
const sh := sh;
const defaultsh := defaultsh;
const dsh:=ref defaultsh;

note('defaultsh (dsh) ready', priority='NORMAL', origin='sh');

