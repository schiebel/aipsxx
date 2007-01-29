# dparams.g: Dish parameter saving closure
#------------------------------------------------------------------------------
#   Copyright (C) 1997,1998,1999,2000,2002,2003
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
#    $Id: dparams.g,v 19.1 2004/08/25 01:12:10 cvsmgr Exp $
#
#------------------------------------------------------------------------------

pragma include once;

include 'note.g';
include 'aipsrc.g';
include 'os.g';

dparams := function()
{
    public := private := [=];

    private.dparams := [=]; # [name] =[type=string, value=value, time=double]
    private.lastchange := 0;
    private.lastsave := 0;
    private.ok := F;

    defaultFile := '$HOME/aips++/dishstate/default';
    private.paramfile := defaultFile;
    drc.find(private.paramfile, 'dish.statefile', defaultFile);
    private.paramfile := dos.fullname(private.paramfile);
    if (!dos.isvalidpathname(dos.dirname(private.paramfile))) {
	note('dish.statefile aipsrc parameter has an illegal value, using default value',
	     priority='WARN',origin='dparms');
	private.paramfile := dos.fullname(defaultFile);
    }

    private.namevalid := function(name) {
        if (!is_string(name) || length(name) != 1) return F;
        return (name ~ m/^([a-zA-Z0-9]+)+(\.[a-zA-Z0-9]+)*$/);
    }

    private.makedir := function()
    {
	wider private;
	result := F;
	paramdir := dos.dirname(private.paramfile);
	if (!dos.fileexists(paramdir)) {
	    junk := dos.mkdir(paramdir);
	    if (is_fail(junk) || !junk) {
		result := F;
	    } else {
		note('Created parameter directory ', paramdir,
		     origin='dparams');
		result := T;
	    }
	} else {
	    result := T;
	}
	return result;
    }

    public.setparamfile := function(name)
    {
	wider private;
	wider public;

	# Validate arguments.
	name := dos.fullname(name);
	if (!dos.isvalidpathname(name)) {
	    # this may fail if the dirname of name doesn't exist, which
	    # would still be okay
	    if (!dos.isvalidpathname(dos.dirname(name))) {
		# if we get to here, its really a problem
		return throw(name,' can not be created',
			     origin='dparams.setparamfile()');
	    }
	}
	private.paramfile := dos.fullname(name);
	# make sure we read things from this file
	# this resets the internal contents
	public.read();
	return T;
    }

    public.getparamfile := function() { wider private; return private.paramfile;}

    public.set := function(name, type, value)
    {
	wider private;

	# Validate argumemnts.
	if (!is_string(type) || length(type) != 1) {
	    return throw('dparams.set - type must be a scalar string');
	}
	if (! private.namevalid(name)) {
	    return throw('dparams.set - name must be a scalar string ',
			 'of the form xxx[.yyy...zzz]');
	}
	if (is_fail(value)) {
	    return throw('dparams.set - value for ', name, ' is a fail!');
	}
	private.dparams[name] := [type=type, value=value, time=time()];
	private.lastchange := private.dparams[name].time;

	return T;
    }
	
    public.get := function(name, ref error='') {
	wider private;

	if (! private.namevalid(name)) {
	    val error := spaste('dparams.get - name must be of the form',
				' xxx[.yyy...zzz]');
	    fail error;
	}

	if (!has_field(private.dparams, name)) {
	    val error := spaste('No such parameter: ', name);
	    fail error;
	}

	return private.dparams[name];
    }


    public.find := function(name=unset, type=unset, aftertime=unset,
			    nametype='string') {
	wider private;
	if (!is_string(nametype) || length(nametype) != 1) {
		return throw('dparams.find - nametype must be a scalar ',
			     'string');
	}
	if (!is_unset(type) && (!is_string(type) || length(type) != 1)) {
		return throw('dparams.find - type must be unset or scalar ',
			     'string');
	}
	if (!is_unset(aftertime) && (!is_numeric(aftertime) || 
				     length(aftertime) != 1)) {
		return throw('dparams.find - aftertime must be unset or a ',
			     'number');
	}
	nametype := to_lower(nametype);
	if (nametype == 'string') {
	    if (!is_unset(name) && !private.namevalid(name)) {
		return throw('dparams.find - name must be a scalar string ',
			     'of the form xxx[.yyy...zzz]');
	    }
	} else if (nametype == 'regex') {
	    # Nothing (yet)
	} else {
	    return throw('dparams.find - nametype must be a \'string\' ',
			 ' or \'regex\'');
	}

	if (is_unset(name)) {
	    candidates := field_names(private.dparams);
	} else {
	    if (nametype == 'string') {
		if (has_field(private.dparams, name)) {
		    candidates := name;
		} else {
		    candidates := "";
		}
	    } else if (nametype == 'regex') {
		candidates := field_names(private.dparams);
		mask := candidates ~ eval(spaste('m/',name,'/'));
		candidates := candidates[mask];
	    } else {
		return throw('dparams: NOTREACHED');
	    }
	}

	# Now do the type check
	if (!is_unset(type) && length(candidates)) {
	    mask := array(T, length(candidates));
	    for (i in ind(candidates)) {
		if (private.dparams[candidates[i]].type != type) {
		    mask[i] := F;
		}
	    }
	    candidates := candidates[mask];
	}

	
	# Now the time check
	if (!is_unset(aftertime) && length(candidates)) {
	    mask := array(T, length(candidates));
	    for (i in ind(candidates)) {
		if (private.dparams[candidates[i]].time < aftertime) {
		    mask[i] := F;
		}
	    }
	    candidates := candidates[mask];
	}

	return candidates;
    }
			    
    
    public.save := function(force=F)
    {
	wider public;
	wider private;

	if (force || private.lastchange > private.lastsave) {
	    ok := private.makedir();
	    if (is_fail(ok) || !ok) {
		# attempt a fallback position
		# first, basename in current dir
		bname := dos.basename(public.getparamfile());
		tmp := spaste('./',bname);
		note('Unable to save to ',public.getparamfile(),
		     ' -  tryin to save to ',tmp,origin='dparams',priority='WARN');
		public.setparamfile(tmp);
		ok := private.makedir();
		if (is_fail(ok) || !ok) {
		    # second fallback, in /tmp
		    tmp := spaste('/tmp/',bname);
		    note('Unable to save to ',public.getparamfile(),
			 ' - trying to save to ',tmp,origin='dparams',priority='WARN');
		    public.setparamfile(tmp);
		    ok := private.makedir();
		    if (is_fail(ok) || !ok) {
			fail;
		    }
		}
	    }
	    ok := write_value(private.dparams, private.paramfile);
	    if (!ok) {
		return throw('dparams.save - Error writing ', 
			     private.paramfile);
	    }
	    private.lastsave := time();
	}
	return T;
    }

    public.read := function()
    {
	wider private;
	if (!dos.fileexists(private.paramfile)) {
	    # Assume it hasn't been saved yet
	    return T;
	}

	candidate := read_value(private.paramfile);
	if (is_boolean(candidate) && !candidate) {
	    return throw('dparams.read: error reading file ',
			 private.paramfile);
	}

	if (!is_record(candidate)) {
	    return throw('dparams.read: error reading file ',
			 private.paramfile, ' - wrong format');
	}

	save := time();
	change := 0;
	for (name in field_names(candidate)) {
	    if (!private.namevalid(name)) {
		note('dparams.read: error reading file ',
		     private.paramfile, ' - illegal parameter name',
		     name, '\nIgnoring this parameter and continuing',
		     priority='WARN', origin='dparams.read');
	    } else {
		# Make sure valid 
		rec := candidate[name];
		if (!is_record(rec) || !has_field(rec, 'type') || 
		    !has_field(rec, 'time') || !has_field(rec, 'value')) {
		    return throw('dparams.read: bad parameter value in ',
				 'file ', private.paramfile, '\nParameter ',
				 name, ' is bad ',rec);
				 
		} else {
		    change := max(change, rec.time);
		}
	    }
	}

	private.dparams := candidate;
	private.lastsave := save;
	private.lastchange := change;
	return T;
    }

    # this just tracks the status of things during construction
    # if the initial read returns ok, then this returns ok
    # after that, its up to the user to check the return state
    # of each function
#    public.ok := function() {wider private; return private.ok;}

#    public.debug := function() {wider private;return private;}

    private.ok := public.read(); # Read initial values, if any

    return ref public;
}

dparams := dparams();
const dparams := const dparams;

