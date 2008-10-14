# aips++init.g -- Initialize glish as needed for aips++
#
#   Copyright (C) 1996,1997,1999,2002,2003
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
#   $Id: aips++init.g,v 19.2 2004/08/25 02:07:00 cvsmgr Exp $
#

pragma include once;

# Run everything inside a function named _init to avoid polluting the global
# namespace.
_init := symbol_delete('_init');

# This scripts is used to set up glish as needed for AIPS++, without setting
# up any clients etc. That is, this script should be very cheap to run. At
# present it:
#    1. Makes all the glish builtins const so they cannot be accidentally
#       overwritten; and
#    2. Set system.include.path to include $AIPSROOT/ARCH/libex

# Make all functions const, as well as numeric and string variables.
_init := function() {
    for (i in symbol_names(func (x) {return is_function(x) ||
					 is_string(x) ||
					     is_numeric(x)}) ) {
      if (i != '_init') tmp := eval(paste('const', i, ':=', i));
    }
    return T;
  }
_init := _init();  # avoid making new global variable

# Set system.include.path to include $AIPSROOT/ARCH/libexec, etc. Include it at the
# end if system.include.path is already set.

# If system.path.include does not exist, make it.
if (! has_field(system, 'path')) {
    system.path := [=];
}
if (! has_field(system.path, 'include') || (length(system.path.include)==0)) {
    system.path.include := '.';
}

_init := function() {
    global system, bug;

    # Make sure AIPSPATH exists
    if (! has_field(environ, 'AIPSPATH')) {
        print 'aips++init.g: No AIPSPATH set!';
        # Would it be better to exit?
	return F;
    } else {
        # Make sure AIPSPATH looks reasonable
        aipspath := split(environ.AIPSPATH)
        if (length(aipspath) != 4) {
    	    print 'Unrecognized or corrupted AIPSPATH: ', aipspath;
            # Would it be better to exit?
	    return F;
        }
    }
    
    # Add "." if not already in path
    if (!any(system.path.include == '.')) {
	system.path.include := ['.', system.path.include];
    }

    # User's path
    # Don't add it if it is already in the path
    libexec := spaste(environ.HOME, '/aips++/', aipspath[2], '/libexec');
    if (!any(system.path.include == libexec)) {
	# stat the directory and make sure it is a directory
	tmp := stat(libexec);
	if (has_field(tmp, 'type') && tmp.type == 'directory') {
	    # OK, just add it to the end
	    system.path.include[length(system.path.include) + 1] := libexec;
	}
    }

    # System path
    # Don't add it if it is already in the path
    libexec := spaste(aipspath[1], '/', aipspath[2], '/libexec');
    if (!any(system.path.include == libexec)) {
	# stat the directory and make sure it is a directory
	tmp := stat(libexec);
	if (has_field(tmp, 'type') && tmp.type == 'directory') {
	    # OK, just add it to the end
	    system.path.include[length(system.path.include) + 1] := libexec;
	}
    }

    # Unilaterally set the icon path.
    if ( have_gui( ) ) {
	tmp := ['.', spaste(libexec, '/icons')];
	tk_iconpath(tmp);
    }

    # Set debug function (uses _init_bug( ) hook defined in askme.g)
    const bug := func( ) {
	if ( include 'bug.g' ) { return _int_bug( ); }
    }

    return T;
}
_init := _init();
if (!_init) {
    print 'Adding the aips++ libexec directory to the include path failed.'
    print 'You might want to exit and try again.'
}

# Done!
