# atomsatnf.g: help atoms for the atnf package. 
# Copyright (C) 1999
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
# $Id: atomsatnf.g,v 19.949 2006/09/29 01:49:20 wyoung Exp $

pragma include once
val help::pkg.atnf := [=];
help::pkg.atnf::d := 'ATNF-related modules and tools';

help::pkg.atnf.atca := [=];
help::pkg.atnf.atca.objs := [=];
help::pkg.atnf.atca.funs := [=];
help::pkg.atnf.atca.d := 'Module for Australia Telescope Compact Array data processing';
help::pkg.atnf.atca.objs.atcafiller := [=];
help::pkg.atnf.atca.objs.atcafiller.m := [=];
help::pkg.atnf.atca.objs.atcafiller.c := [=];
help::pkg.atnf.atca.objs.atcafiller.d := 'A tool for converting ATNF/ATCA RPFITS files to a MeasurementSet';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller := [=];
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.d := 'Construct the ATCA filler tool';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.msname := [=];
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.msname.d := 'Filename for MeasurementSet to create';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.msname.def := '\' \' ';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.msname.a := 'String';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.filenames := [=];
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.filenames.d := 'Existing RPFITS files to read;    wild cards accepted, don\' t use commas';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.filenames.def := '\' \' ';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.filenames.a := 'String or Vector of Strings';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.options := [=];
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.options.d := 'birdie, reweight, noxycorr,compress,fastmosaic,hires';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.options.def := '\' \' ';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.options.a := 'Vector of Strings';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.shadow := [=];
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.shadow.d := 'dish size for flagging shadowed data';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.shadow.def := '22.0';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.a.shadow.a := 'Float';
help::pkg.atnf.atca.objs.atcafiller.c.atcafiller.s := 'atcafiller(msname, filenames, options, shadow)';
help::pkg.atnf.atca.objs.atcafiller.m.fill := [=];
help::pkg.atnf.atca.objs.atcafiller.m.fill.d := 'Fill the data';
help::pkg.atnf.atca.objs.atcafiller.m.fill.s := 'fill()';
help::pkg.atnf.atca.objs.atcafiller.m.select := [=];
help::pkg.atnf.atca.objs.atcafiller.m.select.d := 'Select the data to fill';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.firstscan := [=];
help::pkg.atnf.atca.objs.atcafiller.m.select.a.firstscan.d := 'first scan to read';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.firstscan.def := '1';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.firstscan.a := 'Positive Int';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.lastscan := [=];
help::pkg.atnf.atca.objs.atcafiller.m.select.a.lastscan.d := 'last scan to read';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.lastscan.def := '9999';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.lastscan.a := 'Positive Int';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.lowfreq := [=];
help::pkg.atnf.atca.objs.atcafiller.m.select.a.lowfreq.d := 'lowest reference freq to select in GHz';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.lowfreq.def := '0.1';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.lowfreq.a := 'Double';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.highfreq := [=];
help::pkg.atnf.atca.objs.atcafiller.m.select.a.highfreq.d := 'highest reference freq to select in GHz';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.highfreq.def := '1000.0';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.highfreq.a := 'Double';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.freqchain := [=];
help::pkg.atnf.atca.objs.atcafiller.m.select.a.freqchain.d := 'select one of the simultaneous frequencies, 0=both';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.freqchain.def := '0';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.freqchain.a := 'Int';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.fields := [=];
help::pkg.atnf.atca.objs.atcafiller.m.select.a.fields.d := 'list of field names (sources) to select';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.fields.def := '\' \' ';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.fields.a := 'Vector of Strings';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.bandwidth1 := [=];
help::pkg.atnf.atca.objs.atcafiller.m.select.a.bandwidth1.d := 'select on bandwidth (MHz) of the first frequency chain, 0=all';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.bandwidth1.def := '0';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.bandwidth1.a := 'Int';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.numchan1 := [=];
help::pkg.atnf.atca.objs.atcafiller.m.select.a.numchan1.d := 'select on number of channels in first frequency chain, 0=all';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.numchan1.def := '0';
help::pkg.atnf.atca.objs.atcafiller.m.select.a.numchan1.a := 'Int';
help::pkg.atnf.atca.objs.atcafiller.m.select.s := 'select(firstscan, lastscan, lowfreq, highfreq, freqchain, fields, bandwidth1, numchan1)';

help::pkg.atnf.multibeam := [=];
help::pkg.atnf.multibeam.objs := [=];
help::pkg.atnf.multibeam.funs := [=];
help::pkg.atnf.multibeam.d := 'Module for Multibeam receiver data processing';

help::pkg.atnf.rfi := [=];
help::pkg.atnf.rfi.objs := [=];
help::pkg.atnf.rfi.funs := [=];
help::pkg.atnf.rfi.d := 'Radio Frequency Interference';

