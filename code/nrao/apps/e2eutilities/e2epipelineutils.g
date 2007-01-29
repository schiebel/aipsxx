# e2epipelineutils: useful utilities for e2e imaging
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
# $Id: e2epipelineutils.g,v 19.0 2003/07/16 03:44:59 aips2adm Exp $

pragma include once;

e2epipelineutils := function() {

  public := [=];
  private := [=];
  public.start := function() {
    
    global environ;
    global e2edir := environ.E2EROOT;
    shell('mkdir -p pipelinestate');
    include "logger.g";
    if(is_record(dl)) dl.screen();
    global system;
    system.output.pager := F;
    include "servers.g";
    whenever defaultservers.alerter()->["fail error"] do {
      print "Script exited because a server failed ", $value.value;
      exit(1);
    };
    include 'sysinfo.g';
    for (f in field_names(sysinfo())) note(f, ":", sysinfo()[f]());
    return T;
  }
  public.done := function() {
  }

  return ref public;
}
