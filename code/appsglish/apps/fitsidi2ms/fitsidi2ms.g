# fitsidi2ms.g: Glish proxy for fitsidi2ms DO 
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001
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
#   $Id: 
#

pragma include once

include "servers.g"

#defaultservers.suspend(T)
#defaultservers.trace(T)

##############################################################################
# Private function used by constructor
#
const _define_fitsidi2ms := function(msfile, fitsin, ref agent, id) {
   self:= [=];
   public:= [=];

   self.agent:= ref agent;
   self.id:= id;
   self.msfile:= msfile;
   self.fitsin:= fitsin;

#-----------------------------------------------------------------------------
# Method: fill
#
   self.fillRec:= [_method = "fill", _sequence = self.id._sequence];
   public.fill:= function () {
#
      wider self;
      return defaultservers.run (self.agent, self.fillRec);
    }

#-----------------------------------------------------------------------------
# Method: type
#
    public.type := function() {
	return 'fitsidi2ms';
    };

#-----------------------------------------------------------------------------
# Method: id
#
    public.id := function() {
       wider self;
       return self.id.objectid;
    };

#-----------------------------------------------------------------------------
# Method: done
#
    public.done := function() {
       wider self, public;
       ok := defaultservers.done(self.agent, public.id());
       if (ok) {
           self := F;
           val public := F;
       }
       return ok;
    };

   return public;

} #_define_fitsidi2ms()

##############################################################################
# Constructor: create a new server for each invocation
#
   const fitsidi2ms:= function (msfile, fitsin, host = '',
      forcenewserver = T) {
      agent:= defaultservers.activate ("fitsidi2ms", host, forcenewserver);
      id:= defaultservers.create (agent, "fitsidi2ms", "fitsidi2ms", 
         [msfile = msfile, fitsin = fitsin]);
      return _define_fitsidi2ms (msfile, fitsin, agent, id);
    };

##############################################################################
# Test script
#
   const fitsidi2mstest:= function () {
#
      fail "Not yet implemented"
    };

##############################################################################
# Demo script
#
   const fitsidi2msdemo:= function () {
      fail "Not yet implemented"
    };

##############################################################################



