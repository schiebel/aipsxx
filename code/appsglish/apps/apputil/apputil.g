# apputil.g: Glish proxy for apputil DO
#
#   Copyright (C) 1996,1997,1998,1999
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

include "utility.g";
include "servers.g";

#defaultservers.suspend(T)
#defaultservers.trace(T)

##############################################################################
# Private function used by constructor
#
const _define_apputil := function(ref agent, id) {
   private:= [=];
   public:= [=];

   private.agent:= ref agent;
   private.id:= id;

#-----------------------------------------------------------------------------
# Method: format
#
   private.formatRec := [_method = "format", _sequence = private.id._sequence];
   public.format := function (method, parms, width, gap) {
#
      wider private;
      private.formatRec.method := method;
      private.formatRec.parms := parms;
      private.formatRec.width := width;
      private.formatRec.gap := gap;
      retval := defaultservers.run (private.agent, private.formatRec);
      return retval;
    };

#-----------------------------------------------------------------------------
# Method: readcmd
#
   private.readcmdRec := [_method = "readcmd", 
      _sequence = private.id._sequence];
   public.readcmd := function () {
#
      wider private;
      retval := defaultservers.run (private.agent, private.readcmdRec);
      return retval;   
    };

#-----------------------------------------------------------------------------
# Method: parse
#
   private.parseRec := [_method = "parse", _sequence = private.id._sequence];
   public.parse := function (parms, cmd) {
#
      wider private;
      private.parseRec.parms := parms;
      private.parseRec.cmd := cmd;
      retval := defaultservers.run (private.agent, private.parseRec);
      return retval;
    };

   return public;

} #_define_apputil()

##############################################################################
# Constructor: create a new server for each invocation
#
   const apputil:= function (glishmeta, host = '', forcenewserver = T) {
      agent:= defaultservers.activate ("apputil", host, forcenewserver);
      id:= defaultservers.create (agent, "apputil", "apputil", 
         [meta = glishmeta]);
      return _define_apputil (agent, id);
    };

##############################################################################

