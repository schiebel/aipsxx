# memory.g: a tool for for accessing the server memory usage.
# Copyright (C) 2001
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
#        Postal address: APS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: memory.g,v 19.2 2004/08/25 02:03:27 cvsmgr Exp $

const memory := function() {
  include 'servers.g';
  private := [=];
  public := [=];

  public.gui := function() {
    wider private;
    if (has_field(private, 'gui')  && is_record(private.gui)) return T;
    include 'aipsrc.g';
    defaultaipsrc.findfloat(memorysize, 'system.resources.memory', 128.0);
    include 'barchart.g';
    private.gui := 
      barchart(title='AIPS++ Server Memory Usage (MB)', large=memorysize,
	       show=T);
    whenever private.gui->done do {
      defaultservers.stopmemoryevents();
      deactivate;
      private.gui := F;
    }
    private.gui.whenever := last_whenever_executed();
    private.gui.gui();
    private.update(defaultservers.memory());
    defaultservers.sendmemoryevents();
    return T;
  }

  private.remove := function(server) {
    wider private;
    if (has_field(private, 'gui') && is_record(private.gui)) {
      private.gui.remove(server);
    }
  }

  private.update := function(memory) {
    wider private;
    if (has_field(private, 'gui') && is_record(private.gui)) {
      local servers := field_names(memory);
      local values := [];
      for (i in ind(servers)) {
	values[i] := memory[servers[i]];
      }
      private.gui.chart(servers, values);
    }
  }

  public.remove := function(server) {
    wider private;
    if (!is_string(server) || length(server) != 1) {
      return throw('The server name must be a string.', origin='memory');
    }
    private.remove(server);
  }

  public.update := function(memory) {
    wider private;
    if (!is_record(memory)) {
      return throw('The memory argument must be a record',
		   origin='memory.update');
    } 
    private.update(memory);
  }

  public.dismiss := function() {
    wider private;
    if (has_field(private, 'gui') && is_record(private.gui)) {
      defaultservers.stopmemoryevents();
      deactivate private.gui.whenever;
      private.gui.done();
    }
  }

  public.done := function() {
    wider public, private;
    public.dismiss();
    deactivate private.whenevers;
    val private := F;
    val public := F;
  }

  private.whenevers := [];
  whenever defaultservers->remove do {
    local server := $value;
    private.remove(server);
  }
  private.whenevers[1] := last_whenever_executed();
  
  whenever defaultservers->memory do {
    local memory := $value;
    private.update(memory);
  }
  private.whenevers[2] := last_whenever_executed();

  return ref public;
}
