# ms2fromms1.g: Convert AIPS++ MeasurementSet from version1 to version2
#
#   Copyright (C) 1999,2000,2001
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
#   $Id: ms2fromms1.g,v 19.2 2004/08/25 01:36:38 cvsmgr Exp $
#

pragma include once

include "servers.g"

#defaultservers.suspend(T)
#defaultservers.trace(T)

# Users aren't to use this.
const _define_ms2fromms1 := function(ref agent, id) {
    self := [=]
    public := [=]

    self.agent := ref agent;
    self.id := id;

    self.convertRec := [_method="convert", _sequence=self.id._sequence]
    public.convert := function() {
	wider self;
        return defaultservers.run(self.agent, self.convertRec);
    }

    return ref public;

} # _define_ms2fromms1()


const ms2fromms1 := function(ms2, ms1, inPlace=F,
			   host='', forcenewserver=F) {
    agent := defaultservers.activate("ms", host, forcenewserver)
    if(is_fail(agent)) fail;

    id := defaultservers.create(agent, "ms2fromms1", "ms2fromms1", 
      [MS2=ms2,MS1=ms1,
       InPlace=inPlace]);
    if(is_fail(id)) fail;
    return ref _define_ms2fromms1(agent,id);
} 




