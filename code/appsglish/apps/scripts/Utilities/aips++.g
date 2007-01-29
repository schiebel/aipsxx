# aips++.g -- Startup script for aips++, Include standard aips++ utilities
#
#   Copyright (C) 1996-2003
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
#   $Id: aips++.g,v 19.2 2004/08/25 02:06:55 cvsmgr Exp $
#

pragma include once

_starttime := time();

print ''
print '************************* Welcome to AIPS++ *****************************'
print 'Copyright (C) 1995-2003, Associated Universities, Inc. Washington DC, USA'
print '               AIPS++ comes with ABSOLUTELY NO WARRANTY'

# Avoid polluting global namespace with variables
_init := symbol_delete('_init') # just to be safe
_init := function()
{

    # Try to include the supplied file in the global scope. Return T
    # or F depending on whether it succeeds.
    loadfile := function(file,suffix='')
    {
	if (suffix != '') file := spaste(file, suffix);
	command := spaste('include \'', file, '\'');
	ok := eval(command);
	if (is_fail(ok)) {
	    return F;
	} else {
	    return T;
	}
    }

    # load the system packages first. Use the shell rather than
    # the aipsrc DO in case the aips package is not wanted!
    sh := shell("sh", async=T);
    sh->stdin("getrc system.packages");
    await sh->stdout,sh->stderr;
    if ($name == 'stdout') {
      packages := split($value);
      }
    else {
      packages := 'utility';
    }
    good := "";
    bad := "";
    for (i in packages) {
	ok := loadfile(i, '.g');
	if (ok) good[length(good) +1] := i; else bad[length(bad)+1] := i;
    }

    sh->stdin("getrc user.display.memory");
    await sh->stdout,sh->stderr;
    if ($name == 'stdout' && $value ~ m/[TtYy]+/) {
      ok := loadfile('memory.g');
      if (ok) {
	good[length(good) +1] := i;
	global defaultmemory := memory();
	defaultmemory.gui();
      } else {
	bad[length(bad)+1] := i;
      }
    }

    major := F; minor := F; 
    include 'sysinfo.g';
    sysinfo().version(major, minor, dolog=F);
    arch := sysinfo().arch();
    printf('                Version %1.1f (build %d) on %s\n', major/10, minor, arch)

    if (any(symbol_names(is_function) == 'about'))  {
	print '                 for more details, type about()';
    }
    print ''
    if (length(good) > 0) print 'Loaded system packages:', good;
    if (length(bad) > 0) print 'FAILED to load packages:', bad;
    sh->stdin("getrc user.initfiles");
    await sh->stdout,sh->stderr;
    files := "";
    if ($name == 'stdout') files := split($value);
    good := "";
    bad := "";
    if (length(files) > 0) {
	for (i in files) {
	    ok := loadfile(i);
	    if (ok) good[length(good) +1] := i; else bad[length(bad)+1] := i;
	}
    }

    if (length(good) > 0) print 'Loaded user files:', good;
    if (length(bad) > 0) print 'FAILED to load user files:', bad;
    sh->EOF();
    sh:=F;

    include 'memoryassay.g';
    memoryassay(verbose=F);

    include 'checker.g';
    dch.all();

    return T    
}
_init := _init() # Avoid polluting global scope

## Say how to get help if it is defined
if (any(symbol_names(is_function) == 'help')) print 'Type help() for help';

note(paste("Time to initialize AIPS++ = ", as_integer(time()-_starttime), "seconds"));

