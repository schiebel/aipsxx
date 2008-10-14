# bimams_meta.g: Standard meta information for bimams
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
# uncomment when not developing
pragma include once;

include 'types.g';

priv.table := 'table access';
priv.spec := 'spectral window';
priv.polar := 'polarzation';
priv.misc := 'miscellaneous';

types.class('bimams').includefile("bimams.g");

# Constructors
types.method('ctor_bimams').ms('msname',context='ms');

# Methods

types.group(priv.spec).method('chanwidths').string('type','c').
    vector_double('return');

types.group(priv.table).method('ddid').
    integer('spwid').
    string('stokes','YY',allowunset=T).
    integer('polid',allowunset=T).
    integer('return',help='The corresponding 1-based data description id (row number)');
	    
types.group(priv.table).method('ddids'). 
    vector_integer('spwids',unset,allowunset=T).
    vector_integer('polids',unset,allowunset=T).
    vector_integer('return',help='The corresponding 1-based data description ids (row numbers) from the DATA_DESCRIPTION table');

types.group(priv.table).method('ddtable').
    tool('return','ddtable',help='The DATA_DESCRIPTION table as a table tool');

types.group(priv.table).method('doptable').
    tool('return','doptable');

types.group(priv.spec).method('endfreqs').
    vector_double('return',help='A Glish vector of the last frequencies for the multi-channel data windows');

types.group(priv.misc).method('fieldids').
    string('sname').vector_integer('return');

types.group(priv.table).method('fieldtable').tool('return','fieldtable');

types.group(priv.table).method('mcaddids').vector_integer('mcd').
    vector_integer('return');


types.group('underlying tools').method('ms').
    tool('return','bimams_ms',help='The underlying ms on which this tool is built');

types.group(priv.spec).method('namespw').
    string('sb').
    string('type').
    integer('mcn',1).
    string('name').
    boolean('return',help='true if the naming was successful');

types.group(priv.spec).method('namespwid').
    integer('spwid').
    string('name').
    boolean('return',help='True if naming was successful');

types.group(priv.spec).method('nchans').
    vector_integer('return',
		   help='A Glish vector of integers of the number of spectral channels per multi-channel data spectral window, one value for each multi-channel data spectral window in the order they appear in the Spectral Windows table');

types.group(priv.polar).method('npol').
    integer('return',
	    help='The number of all polarizations in the Polarization table (just the number of rows in this table)');

types.group(priv.spec).method('nspw').
    integer('return',
	    help='The number of all (sideband averages, multi-channel averages, multichannel data) spectral windows in the Spectral Windows table (just the number of rows in this table)');

types.group(priv.polar).method('polartable').
	tool('return','polartable',context='table',help='The Polarization table associated with the underlying MS as a tool');

types.group(priv.polar).method('polarids').
    string('stokes').
    vector_integer('return',help='a Glish vector of 1-based ids from the Polarization table matching the specified stokes parameter');

types.group(priv.spec).method('reavg').string('out','').boolean('dosort',T).
    boolean('reset',T).integer('verbosity',1).
    boolean('return',help='T if the function was successful');


types.group(priv.spec).method('reffreqs').vector_double('return',help='A Glish vector of reference frequencies in the order they appear in the Spectral Windows table');

types.group(priv.table).method('sourcetable').tool('return','sourcetable');

types.group(priv.spec).method('spwid').
    string('sb').
    string('type').
    integer('mcn',1).
    integer('return',
	    help='The 1-based id (row number) of the window in the Spectral Windows table');

types.group(priv.spec).method('spwidsbyname').
    vector_string('names',[' ']).
    vector_integer('return',help='A Glish integer vector containing the 1-based ids (row numbers) of the windows in the Spectral Windows table with the specified names');

types.group(priv.spec).method('spwids').
    string('type').
    string('sibeband','b').
    vector_integer('return',help='A Glish vector of ids (row numbers) in the Spectral Windows table for windows of the specified type in the specified sideband');

types.group(priv.spec).method('spwnames').string('type','all').
    vector_string('return',help='A vector of names for all the spectral windows of the specified type');


types.group(priv.table).method('spwtable').tool('return','spwtable');

types.group(priv.spec).method('startfreqs').
    vector_string('return',help='A vector of start frequencies for all the multi-channel data spectral windows');

types.group(priv.spec).method('stokesid').
    string('stokes').
    integer('return',help='An integer representing the specified stokes parameter or -1 if the Stokes parameter is not recognized.');

types.group(priv.table).method('subtable').
    string('tname').
    boolean('readonly',T).
    tool('return','bms_table',help='The specified table as a table tool');

types.group(priv.misc).method('timerange').
    record('return');

types.group(priv.misc).method('totalintegration').double('gaptime',-1).
    record('return');
