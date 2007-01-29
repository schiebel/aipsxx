# finclude.g: "Fast" include via caching
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#          Postal address: AIPS++/ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: finclude.g,v 19.2 2004/08/25 02:08:26 cvsmgr Exp $
#

pragma include once;

const finclude := function() {

  include 'getrc.g';
  include 'misc.g';
  include 'sysinfo.g';

  private := [=];
  public  := [=];

  # Is caching disabled?
  private.disablecache := F;
  getrc.find(private.disablecache, 'user.disablecache', F);
  if(is_string(private.disablecache)) {
    if(private.disablecache=='T') {
      private.disablecache:=T;
    }
    else {
      private.disablecache:=F;
    }
  }

  # Is the cache defined?
  private.defaultaipsdir := '$HOME/aips++';
  private.aipsdir := '$HOME/aips++';
  getrc.find(private.aipsdir, 'user.aipsdir', private.defaultaipsdir);

  private.defaultcachehome := spaste(private.aipsdir, '/cache');
  private.cachehome := spaste(private.aipsdir, '/cache');
  getrc.find(private.cachehome, 'user.cache', private.defaultcachehome);

  include 'os.g';
  # Cache does not exist
  if(!dos.fileexists(private.cachehome, T)) {
    # If it's the standard place, we'll try to create it
    if(private.cachehome==private.defaultcachehome) {
      if(!dos.fileexists(private.aipsdir, T)) {
	# Top level does not exist
	note('Making aips++ directory ', private.aipsdir, origin='finclude.g');
	if(!dos.mkdir(private.aipsdir)) {
	  private.cachehome := '.';
	  note('Failed to create ', private.aipsdir, ', using current directory',
	       priority='WARN', origin='finclude.g');
	}
	else {
	  # Top level does exist: create the cache itself
	  note('Making aips++ cache directory ', private.cachehome,
	       origin='finclude.g');
	  if(!dos.mkdir(private.cachehome)) {
	    private.cachehome := '.';
	    note('Failed to create cache directory, using current directory',
		 priority='WARN', origin='finclude.g');
	  }
	}
      }
      else {
	# $HOME/aips++ does exist, does the cache exist?
	if(!dos.fileexists(private.cachehome, T)) {
	  note('Making cache directory ', private.cachehome, origin='finclude.g');
          # No, create it
	  if(!dos.mkdir(private.cachehome)) {
	    private.cachehome := '.';
	    note('Failed to create cache directory, using current directory', priority='WARN',
		 origin='finclude.g');
	  }
	}
      }
    }
    else {
      note('Making cache directory ', private.cachehome, origin='finclude.g');
      if(!dos.mkdir(private.cachehome)) {
	private.cachehome := '.';
	note('Failed to create cache directory, using current directory', priority='WARN',
	     origin='finclude.g');
      }
    }
  }
  private.cachehome := dms.thisdir(private.cachehome);
  
  # What version is to be used
  if(is_defined('sysinfo')&&is_function(sysinfo)) {
    major := F;
    minor := F;
    sysinfo().version(major, minor, dolog=F);
    private.version := spaste(major, '.', minor);
  }
  else {
    private.version := F;
  }
    
  private.cachefile := function(cachefile) {
    wider private;
    # Now find the cache 
    if(private.version) {
      if(cachefile!='') {
	cachefile := spaste(private.cachehome, '/', cachefile, '.', private.version);
      }
      else {
	fail "finclude: Need name for cache file";
      }
    }
    else {
      if(cachefile!='') {
	cachefile := spaste(private.cachehome, '/', cachefile);
      }
      else {
	fail "finclude: Need name for cache file";
      }
    }
    return cachefile;
  }
      
# Is the cachefile up to date?
  public.uptodate := function(files, cachefile) {
    wider public, private;
    
    if(!public.exists(cachefile)) return F;

    uptodate := T;

    if(!private.disablecache) {
      # First find the list of files to include with full
      # path name since we need to check the dates
      files := which_include(files);
      
      # Check the cache against every file in the list
      icachefile := private.cachefile(cachefile);
      cachestat := stat(icachefile);
      uptodate := T;
      if(has_field(cachestat, 'time')) {
	for (file in files) {
	  filestat  := stat(file);
	  if(has_field(filestat, 'time')&&
	     (cachestat.time.modify<filestat.time.modify)) {
	    uptodate := F;
	    break;
	  }
	}
      }
      else {
	uptodate := F;
      }
      return uptodate;
    }
    else {
      return F;
    }
  }

# If cachefile is newer than the files, it is read. Otherwise
# the files are read and variable written into the cachefile.
# This assumes that the include files actually do update
# variable.
  public.include := function(ref variable, files, cachefile) {
    wider public, private;
    
    uptodate := T;

    if(!private.disablecache) {
      if(!public.uptodate(files, cachefile)) {
	# Now we can strip the directories off
	for (i in 1:length(files)) {
	  files[i] ~:=  s/.*\///;
	}
	# Only keep the unique ones.
	files := unique(files);
	for (file in files) {
	  tmp := eval(spaste('include \'', file, '\''));
	  if(is_fail(tmp)) {
	    note(paste('Error in', file, ':', tmp::message), priority='WARN');
	  }
	}
	# Presumably at this point, variable has been updated
	icachefile := private.cachefile(cachefile);
	note(paste('Updating cache file', icachefile));
	write_value(variable, icachefile);
      }
      # Everything was up to date so we can just read the cache
      # file
      else {
	icachefile := private.cachefile(cachefile);
	val variable := read_value(icachefile);
	note(icachefile, ': ', sizeof(variable), ' bytes');
      }
    }
    else {
      note('Caching of glish files disabled');
      for (file in files) {
	tmp := eval(spaste('include \'', file, '\''));
      }
    }
    # DONE!
    return !uptodate;
  }

  public.exists := function(cachefile) {
    wider private;
    include 'os.g';
    return dos.fileexists(private.cachefile(cachefile), T);
  }


  public.read := function(ref variable, cachefile) {
    wider public, private;
    
    if(!public.exists(cachefile)) {
      note(cachefile, ': does not exist', priority='WARN');
      return F;
    }

    icachefile := private.cachefile(cachefile);

    val variable := read_value(icachefile);
    note(icachefile, ': ', sizeof(variable), ' bytes');
    return T;
  }

  public.write := function(ref variable, cachefile) {
    wider private;
    
    icachefile := private.cachefile(cachefile);

    note(paste('Updating cache file', icachefile));
    write_value(variable, icachefile);
    return T;
  }
  return public;
}

const defaultfinclude := finclude();
const dfi := const defaultfinclude;
