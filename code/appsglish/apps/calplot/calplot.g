# calibrater.g: Glish proxy for calibrater DO 
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
#   $Id: calplot.g,v 1.2 2006/01/03 05:24:39 kgolap Exp $
#

pragma include once

include "servers.g"
include "table.g"


#defaultservers.suspend(T)
#defaultservers.trace(T)

##############################################################################
# Private function used by constructor
#
const _define_calplot := function(caltable, ref agent, id) {
   self:= [=];
   public:= [=];

   self.agent:= ref agent;
   self.id:= id;
   self.caltable:= caltable;

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
# Method: setparameters
#
   self.setparametersRec:= [_method = "setparameters", _sequence = self.id._sequence];
   public.setparameters:= function (nxpanels = 1, nypanels = 1, 
				    iteraxis='antenna', multiplot=F) {
#
      wider self;
      self.setparametersRec.nxpanels:= nxpanels;
      self.setparametersRec.nypanels:= nypanels;
      self.setparametersRec.iteraxis:= iteraxis;
      self.setparametersRec.multiplot:= multiplot;
    
    

      return defaultservers.run (self.agent, self.setparametersRec);
    }
#-----------------------------------------------------------------------------
# Method: setselect
#
   self.setselectRec:= [_method = "setselect", _sequence = self.id._sequence];
   public.setselect:= function (antennas = [], caldescids = [], 
				    plottype='PHASE') {
#
      wider self;
      self.setselectRec.antennas:= antennas;
      self.setselectRec.caldescids:= caldescids;
      self.setselectRec.plottype:= plottype;
    
    

      return defaultservers.run (self.agent, self.setselectRec);
    }

#-----------------------------------------------------------------------------
# Method: plot
#
   self.plotRec:= [_method = "plot", _sequence = self.id._sequence];
   public.plot:= function () {
      wider self;
      return defaultservers.run (self.agent, self.plotRec);
    };

#-----------
#-----------------------------------------------------------------------------
# Method: next
#
   self.nextRec:= [_method = "next", _sequence = self.id._sequence];
   public.next:= function () {
      wider self;
      return defaultservers.run (self.agent, self.nextRec);
    };

#-----------
#-----------------------------------------------------------------------------
# Method: stopiter
#
   self.stopiterRec:= [_method = "stopiter", _sequence = self.id._sequence];
   public.stopiter:= function () {
      wider self;
      return defaultservers.run (self.agent, self.stopiterRec);
    };

#-----------
# Method: type
#
    public.type := function() {
	return 'calplot';
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

} #_define_calplot()

##############################################################################
# Constructor: create a new server for each invocation
#
   const calplot:= function (caltable, host = '', 
                                forcenewserver = T) {
#      defaultservers.suspend(T);
      agent:= defaultservers.activate ("calplot", host, forcenewserver);
      id:= defaultservers.create (agent, "calplot", "calplot", 
				  [caltable = caltable]);
#      defaultservers.suspend(F);
      return _define_calplot (caltable, agent, id);
    };




