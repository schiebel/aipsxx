# e2ethread: useful utilities for e2e imaging
# Copyright (C) 1999,2000,2001,2002
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
# $Id: e2ethread.g,v 19.0 2003/07/16 03:44:51 aips2adm Exp $

pragma include once;

e2ethread := function(msname='', query='', sources=[=],
		      spwid=[], polid=[], nchan=1) {

  public := [=];
  private := [=];

  private.thread := [msname=msname, query=query,
		     sources=sources, 
		     spwid=spwid, nchan=nchan, polid=polid,
		     niter=1000, history=''];
#
# Check thread for validity: i.e. can it be processed sensibly?
#
  private.checkthread := function() {
    wider private, public;
    valid := T;
    valid := valid && all(private.thread.sources.Gcal!='');
    return valid;
  }
#
# Get fields
#
  if(msname!='') {
    include 'e2emsutils.g';
    msutils := e2emsutils(msname);
    for (type in field_names(private.thread.sources)) {
      private.thread.fields[type] := msutils.nametofieldid(private.thread.sources[type]);
    }
    msutils.done();
    private.thread.valid := private.checkthread();
#
# Don't clean spectral images for now
#
    if(private.thread.nchan>1) {
      private.thread.niter:=0;
    }

  }

#
# Provide consistent names
#
  public.name := function(root='', extension='clean') {
    wider private;
    if(root=='') {
      root := private.thread.msname;
    }
    spwid   := unique(private.thread.spwid);
    polid   := unique(private.thread.polid);
    name := spaste(root, '.spwid=', as_evalstr(spwid), '.polid=', as_evalstr(polid));
    if(extension!='') {
      name := spaste(name, '.', extension);
    }
    name ~:= s/ //g;
    return name;
  }

  public.addhistory := function(...) {
    wider private;
    l:=len(private.thread.history);
    l+:=1;
    private.thread.history[l]:=paste(string);
    return T;
  }


  public.caltable := function(type) {
    wider private;
    return public.name(extension=spaste(type, 'cal'));
  }

  public.image := function(source, extension) {
    wider private;
    return public.name(source, extension=extension);
  }
#
# Print a summary of this thread
#
  public.summary := function() {
    wider private, public;
    note('   Valid               : ', private.thread.valid);
    note('   MeasurementSet      : ', private.thread.msname);
    note('   Query               : ', private.thread.query);
    note('   Sources             : ', as_evalstr(private.thread.sources));
    note('   Field id            : ', private.thread.fields);
    note('   Spectral windows id : ', private.thread.spwid);
    note('   Number of channels  : ', private.thread.nchan);
    note('   Polarization id     : ', private.thread.polid);
    note('   History             : ', private.thread.history);
    return T;
  }
#
# Read-only access to data
#
  public.valid    := function() {return private.thread.valid};
  public.msname   := function() {return private.thread.msname};
  public.query    := function() {return private.thread.query};
  public.sources  := function() {return private.thread.sources};
  public.fields   := function() {return private.thread.fields};
  public.spwid    := function() {return private.thread.spwid};
  public.polid    := function() {return private.thread.polid};
  public.nchan    := function() {return private.thread.nchan};
  public.niter    := function() {return private.thread.niter};
  public.history  := function() {return private.thread.history};

  public.torecord := function() {
    return private.thread;
  }

  public.fromrecord := function(rec) {
    wider private;
    private.thread := rec;
    private.thread.valid := private.thread.valid && private.checkthread();
    if(private.thread.nchan>1) {
      private.thread.niter:=0;
    }
    return T;
  }

  public.done := function() {
    return T;
  }
  public.type := function() {
    return "e2ethread";
  }

  return ref public;
}
