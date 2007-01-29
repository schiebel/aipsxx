# sdaverager.g: Average SDIterators
# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: sdaverager.g,v 19.2 2006/11/28 19:06:42 bgarwood Exp $

pragma include once;

# first, set up the DO server
include "servers.g";
include "note.g";

include 'sditerator.g';

const sdaverager := function(host='', forcenewserver = F) {
    private := [=];
    public := [=];
    
    private.coercer := sdrecord_coercer();

    private.agent := defaultservers.activate("sditerator", host,
					  forcenewserver);

    private.id := defaultservers.create(private.agent, "sdaverager");

    private.clearRec := [_method="clear", _sequence=private.id._sequence];
    public.clear := function() {
	wider private;
	return defaultservers.run(private.agent, private.clearRec);
    }

    private.setweightingRec := [_method="setweighting", 
			     _sequence=private.id._sequence];
    public.setweighting := function(option) {
	wider private;
	private.setweightingRec.option := option;
	return defaultservers.run(private.agent, private.setweightingRec);
    }

    private.getweightingRec := [_method="getweighting", 
			     _sequence=private.id._sequence];
    public.getweighting := function() {
	wider private;
	return defaultservers.run(private.agent, private.getweightingRec);
    }

    private.setalignmentRec := [_method="setalignment", 
			     _sequence=private.id._sequence];
    public.setalignment := function(option) {
	wider private;
	private.setalignmentRec.option := option;
	return defaultservers.run(private.agent, private.setalignmentRec);
    }

    private.getalignmentRec := [_method="getalignment", 
			     _sequence=private.id._sequence];
    public.getalignment := function() {
	wider private;
	return defaultservers.run(private.agent, private.getalignmentRec);
    }

    private.dorestshiftRec := [_method="dorestshift", 
			       _sequence=private.id._sequence];
    public.dorestshift := function(torf) {
	wider private;
	private.dorestshiftRec.torf := torf;
	return defaultservers.run(private.agent, private.dorestshiftRec);
    }

    private.restshiftstateRec := [_method="restshiftstate", 
				  _sequence=private.id._sequence];
    public.restshiftstate := function() {
	wider private;
	return defaultservers.run(private.agent, private.restshiftstateRec);
    }

    private.accumulateRec := [_method="accumulate", _sequence=private.id._sequence];
    public.accumulate := function(sdrecord) {
	wider private;
	private.coercer.coerce(sdrecord);
	private.accumulateRec.sdrecord := sdrecord;
	return defaultservers.run(private.agent, private.accumulateRec);
    }

    private.accumiterRec := [_method="accumiterator", _sequence=private.id._sequence];
    public.accumiterator := function(sditerator) {
	wider private;
	private.accumiterRec.sditerator := sditerator.id().objectid;
	return defaultservers.run(private.agent, private.accumiterRec);
    }

    private.averageRec := [_method="average", _sequence=private.id._sequence];
    public.average := function(ref sdrecord) {
	wider private;
	private.coercer.coerce(sdrecord);
	private.averageRec.sdrecord := sdrecord;
	returnval :=  defaultservers.run(private.agent, private.averageRec);
	if (returnval) {
	    val sdrecord := private.averageRec.sdrecord;
	}
	return returnval;
    }
    return public;
}

testAverager := function () {
    res := [=];
    res.a := sdaverager();
    y := array(1.0, 10);
    crval := 1.0;
    crpix := 1.0;
    cdelt := 1.0;
    weight := 1.0;
    res.a.accumulate(y,crpix,crval,cdelt,weight);
    y +:= 2.0;
    crpix := 2.0
    res.a.accumulate(y,crpix,crval,cdelt,weight);
    res.avg := res.a.average(y,crpix, crval, cdelt, weight);
    res.y := y;
    res.crpix := crpix;
    res.crval := crval;
    res.cdelt := cdelt;
    res.weight := weight;
}
