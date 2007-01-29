# plugins.g: Find and load glish plugin modules
#
#   Copyright (C) 1998,1999,2000,2001
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
#   $Id: plugins.g,v 19.2 2004/08/25 02:09:38 cvsmgr Exp $
#

pragma include once;

include 'note.g'

plugins := function()
{
    public := private := [=];

    public.rescan := function()
    {
	wider private;
	private.available := [=];
	private.loaded := [=];
	private.uptodate := [=];

	note('Looking for plugin files...', origin='plugins.rescan()');

	result := shell('rm -f /tmp/aips_pluginlist.$$ /tmp/aips_list.$$');
	command := 'ls'
	global system;
	if (!has_field(system, 'path')) system.path := [=];
	if (!has_field(system.path, 'include')) system.path.include := '.';
	for (dir in system.path.include) {
	    command := spaste(command, ' ', dir, '/*.gp');
	}
        command := spaste(command, ' 2> /dev/null ');
        found := shell(command);
	nfound := length(found);
	if (nfound == 0) return 0;
	for (i in 1:nfound) {
	    found[i] ~:=  s/.*\///
	}
	found := unique(found);

	# Make sure it has at least one underscore
	bad := !as_boolean(found ~ m/^[a-z].*_/);
	# Make sure it has only one "."
	bad := bad | (1 != (found ~ m/\./g));

	if (any(bad)) {
	    note('plugins.rescan() - rejecting: ', found[bad], 
		 ' (illegal names)', priority='WARN');
	    found := found[!bad];
	}
	
	for (file in found) {
	    tmp := file ~ s/\.gp//; # Drop the .gp
	    tmp := split(tmp, '_');
	    type := tmp[1];
	    private.uptodate[type] := F;
	    category := paste(tmp[2:(length(tmp))], sep='.');
	    if (!has_field(private.available, type))
		private.available[type] := [files="", categories=""];
	    if (!has_field(private.loaded, type))
		private.loaded[type] := [files="", categories="", names=""];
	    n := length(private.available[type].files) + 1;
	    private.available[type].files[n] := file;
	    private.available[type].categories[n] := category;
	}
    }

    public.loadplugins := function(type) {
	wider private;
	if (! has_field(private.available, type)) return T;
	if (has_field(private.uptodate, type) && private.uptodate[type])
	    return T;
	if (length(private.available[type].files) == 0) return T;
	
	for (i in 1:length(private.available[type].files)) {
	    file := private.available[type].files[i];
	    category := private.available[type].categories[i];
	    if (!any(private.loaded[type].files == file) &&
		!any(private.loaded[type].categories == category)) {
		ok := eval(spaste('include \'', file, '\''));
		if (ok) {
		    # Make sure that the plugin has loaded
		    name := spaste(type,'_', category ~ s/\./_/g);
		    if (!any(symbol_names(is_record) == name)) {
			note('Plugin ', name, ' was not found in file ',file,
			     origin='plugins.loadplugins()', priority='WARN');
		    } else {
			# Make sure the plugin has an attach function or
			# we can't do anything with it.
			command := spaste('has_field(',name,', \'attach\')');
			ok := eval(command);
			if (ok) {
			    # Run its init function if necessary
			    command := spaste(
				      'if (has_field(',name,', \'init\')) ',
					  name, '.init();');
			    ok := eval(command);
			    # if no init function exists then ok is an
			    # integer variable with zero length - weird huh!
			    if (is_fail(ok) || (length(ok) > 0 && !ok)) {
				note('Possible error running init function for: ',
				     name,	 origin='plugins.loadplugins()', 
				     priority='WARN');
			    }
			    n := length(private.loaded[type].files) + 1;
			    private.loaded[type].files[n] := file;
			    private.loaded[type].categories[n] := category;
			    private.loaded[type].names[n] := name;
			} else {
			    note('No attach() function in plugin ', name,
				 ' - ignoring plugin', priority='WARN', 
				 origin='plugins.loadplugins()');
			}
		    }
		  } else if(is_fail(ok)) {
		    note('Error including plugin file=',file, ' : ', ok::message,
			 origin='plugins.loadplugins()', priority='WARN');
  		  } else {
		    note('Error including plugin file=',file,
			 origin='plugins.loadplugins()', priority='WARN');
		}
	    }
	}
	private.uptodate[type] := T;
	return T;
    }
    
    public.loaded := function(type) {
	wider private;
	if (!has_field(private.loaded, type)) {
	    return [names="", categories="", files=""]
	} else {
	    return private.loaded[type];
	}
    }

    public.attach := function(type, ref objpublic) {
	wider public, private;
	public.loadplugins(type);

	# Man, is this yucky!
	global _objpublic;
	_objpublic := ref objpublic;

	for (name in  public.loaded(type).names) {
	    command := spaste(name, '.attach(_objpublic);');
	    ok := eval(command);
	    if (!ok) {
		note('Possible error attaching plugin ', name, ' to object.',
		     origin='plugins.attach()', priority='WARN');
	    }
	}
    }

    public.rescan();
    return ref public;
}

# Make it a singleton object
plugins := plugins();
#const plugins := const plugins; # make it const
