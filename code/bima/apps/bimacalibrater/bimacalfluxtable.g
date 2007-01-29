# bimacalfluxtable.g: A tool for retrieving information from the bima-specific calibrator tables in the data repository
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#
pragma include once;

include 'aipsrc.g';
include 'quanta.g';
include 'table.g';

#@
# not to be called directly by users
# @param cals array of calibrater ms names
# @param targets array of target (ie what the calibration will be applied to)
#        ms names 

const _define_bimacalfluxtable := function() {

    private := [=];
    public := [=];

    private.aipsroot := aipsrc().aipsroot();
    private.ctroot := spaste(private.aipsroot,'/data/bima/calibration');
    private.table.positions := table(spaste(private.ctroot,'/mmCalsJ2000.tbl'));
    private.table.fluxes := table(spaste(private.ctroot,'/mmCalsFluxes.tbl'));

    # does the table contain the specified source?

    const public.contains := function(calname) {
        wider private;
        return any(private.table.positions.getcol('Source') == 
                   to_upper(calname));
    }

    # get a list of fluxes and dates for the specifed source

    const public.fluxlist := function(calname) {
        wider private, public;
        if(! public.contains(calname))
            fail spaste(calname,' is not in the BIMA calibrator tables');
        subt := private.table.fluxes.query(spaste('Source == "',calname,'"'));
        rec := [=];
        rec.obsdate := subt.getcol('Obsdate');
        rec.flux := subt.getcol('Flux');
        rec.rms := subt.getcol('Rms');
        rec.freq := subt.getcol('Frequency');
        return rec;
    }

    # return the flux table as a table tool

    const public.fluxtable := function() {
        wider private;
        return private.table.fluxes;
    }

    # get the record nearest in time

    const public.nearestflux := function(calname, date) {
        wider public;
        rec := public.fluxlist(calname);
        if(is_fail(rec)) fail;
        if(is_quantity(date)) 
            dayno := dq.convert(date,'d').value;
        else dayno := date;
        minindex := 1;
        min := abs(dayno - rec.obsdate[1]);
        for (i in 2:len(rec.obsdate)) {
            t := abs(dayno - rec.obsdate[i]);
            if(t < min) {
                min := t;
                minindex := i;
            }
        }
        r := [=];
        for (f in field_names(rec)) 
            r[f] := rec[f][minindex];
        return r;
    }

    # return the position table

    const public.positiontable := function() {
        wider private;
        return private.table.positions;
    }

    return ref public;
}

#@
# constructor users should call
# @param phcals array of phase calibrator ms names
# @param targets array of target ms names
#

const bimacalfluxtable := function() {
    
    return _define_bimacalfluxtable();
}

