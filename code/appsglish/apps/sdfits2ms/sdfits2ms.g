# sdfits2ms.g: glish closure for the sdfits2ms DO in sdfits2ms.cc
# Copyright (C) 2000
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
# $Id: sdfits2ms.g,v 19.1 2004/08/25 01:50:18 cvsmgr Exp $

# include guard
pragma include once
 
include "servers.g";
include "unset.g";
include "os.g";

const sdfits2ms := function(host='', forcenewserver = F) {
    private := [=];
    public := [=];


    # fire up the server and create a filler
    private.agent := defaultservers.activate("sdfits2ms",host,
                                          forcenewserver);

    private.id := defaultservers.create(private.agent, "sdfits2ms");

    if (!is_record(private.id)) 
	fail "sdfits2ms: unable to start sdfits2ms client";

    private.convertRec := 
	[_method="convert", _sequence=private.id._sequence];
    public.convert := function(msname, sdfitsfile) {
       wider private;
       private.convertRec["msname"] := msname;
       private.convertRec["sdfitsfile"] := sdfitsfile;
       return defaultservers.run(private.agent, private.convertRec);
    }

    public.done := function()
    {
	wider private, public;
	ok := defaultservers.done(private.agent, private.id.objectid);
	if (ok) {
	    private := F;
	    val public := F;
	}
	return ok;
    }

    public.type := function() { return 'sdfits2ms';}

    return public;
}


