# atcafiller.g: Convert atca rpfits data into an AIPS++ MeasurementSet
#
#   Copyright (C) 1999,2000,2001,2003
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
#   $Id: atcafiller.g,v 19.1 2003/09/22 03:18:02 mwiering Exp $
#

pragma include once

include "servers.g"
include "logger.g"

#defaultservers.suspend(T)
#defaultservers.trace(T)

# Users aren't to use this.
const _define_atcafiller := function(ref agent, id) {
    self := [=]
    public := [=]

    self.agent := ref agent;
    self.id := id;

    self.fillRec := [_method="fill", _sequence=self.id._sequence]
    public.fill := function() {
	wider self;
        return defaultservers.run(self.agent, self.fillRec);
    }

    self.selectRec := [_method="select", _sequence=self.id._sequence]
    public.select := function(firstscan = 1, lastscan=9999, freqchain = 0,
			      lowfreq = 0.1, highfreq= 1000.0,
			      fields = "", bandwidth1=0, numchan1=0) {
	wider self;
	self.selectRec.firstscan := firstscan;
	self.selectRec.lastscan := lastscan;
	self.selectRec.freqchain := freqchain;
	self.selectRec.lowfreq := lowfreq;
	self.selectRec.highfreq := highfreq;
	self.selectRec.fields := fields;
        self.selectRec.bandwidth1 := bandwidth1;
        self.selectRec.numchan1 := numchan1;
        return defaultservers.run(self.agent, self.selectRec);
    }

    self.closeRec := [_method="close", _sequence=self.id._sequence]
    public.close := function() {
	wider self;
        return defaultservers.run(self.agent, self.closeRec);
    }

    public.id := function() {
	wider self;
	return self.id.objectid;
    }

    public.done := function()
    {
        wider self, public;
        ok := defaultservers.done(self.agent, public.id());
        if (ok) {
            self := F;
            val public := F;
        }
        return ok;
    }

    public.type := function() {
      return 'atcafiller';
    }

    return ref public;

} # _define_atcafiller()


const atcafiller := function(msname, filenames, options='', 
			     shadow = 22.0, online=F,
			     host='', forcenewserver=F) {
    agent := defaultservers.activate("atcafiller", host, forcenewserver)
    if(is_fail(agent)) fail;

    id := defaultservers.create(agent, "atcafiller", "atcafiller", 
      [MeasurementSetName=msname,RPFitsFiles=filenames,
       Options=options,
       ShadowLimit=shadow,
       OnLine=online]);
    if(is_fail(id)) fail;
    return ref _define_atcafiller(agent,id);

} 
