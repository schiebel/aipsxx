# simulator_meta.g: Standard meta information for simulator
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
#   $Id: simulator_meta.g,v 19.2 2004/08/25 01:53:08 cvsmgr Exp $
#

pragma include once;

include 'types.g';
include 'measures.g';

types.class('simulator').includefile('simulator.g');

# Constructors
types.method('ctor_simulator');

types.method('ctor_simulatorfromms').table('thems');

types.method('ctor_simulatortester').table('filename', '3C273XC1.ms').
    table('clname', '3C273XC1.cl').
    integer('size', 256).quantity('cell', '0.7arcsec').
    choice('stokes', 'IV', options=['I', 'IV', 'IQUV']).
    choice('coordinates', 'b1950', options=['b1950', 'gal']).
    vector_integer('componentnumbers', 1:4);

# Methods

### group('basic')

types.group('basic').method('close');

types.group('basic').method('done');

types.group('basic').method('name').string('return');

types.group('basic').method('open').
	ms('thems');

types.group('basic').method('summary');


### group('create')

types.group('create').method('create').
    table('newms').
    double('shadowlimit', 1e-6).
    quantity('elevationlimit', '10deg').
    float('autocorrwt', 0.0);

types.group('create').method('add').
    double('shadowlimit', 1e-6).
    quantity('elevationlimit', '10deg').
    float('autocorrwt', 0.0);

types.group('create').method('setconfig').
    string('telescopename', 'VLA').
    vector_double('x', [0.0, 100.0]).
    vector_double('y', [0.0, 0.0]).
    vector_double('z', [0.0, 0.0]).
    vector_float('dishdiameter', [25.0, 25.0]).
    vector_string('mount', ['alt-az']).
    vector_string('antname', ['VLA']).
    choice('coordsystem', 'global', options=['global', 'local', 'longlat']).
    position('referencelocation', dm.observatory('VLA'), dir="in");

types.group('create').method('setfeed').
    choice('mode', 'perfect R L',
	   options=['perfect R L', 'perfect X Y', 'invent one']);

types.group('create').method('setfield').
    integer('row', 1).
    string('sourcename', 'unknown').
    direction('sourcedirection', dm.direction('b1950', '0d', '0d'), dir="in").
    integer('integrations', 1).
    integer('xmospointings',1).
    integer('ymospointings',1).
    float('mosspacing', 1.0);  

types.group('create').method('setspwindow').
    integer('row', 1).
    string('spwname', 'XBAND').
    quantity('freq', '8.0GHz').
    quantity('deltafreq', '50.0MHz').
    quantity('freqresolution', '50.0MHz').
    integer('nchannels', 1).
    choice('stokes', 'RR LL',
	   options=['RR LL', 'XX YY', 'RR RL LR LL', 'XX XY YX YY',
		    'RR', 'LL', 'XX', 'YY']);

types.group('create').method('settimes').
    quantity('integrationtime', '10s').
    quantity('gaptime', '20s').
    boolean('usehourangle', T).
    quantity('starttime', '0s').
    quantity('stoptime', '3600s').
    epoch('referencetime', default=unset, dir='in', allowunset=T, options='UTC', help='reference time for start and stop times e.g 2000/1/1/12:00:00.00');

#types.group('create').method('uvplot').
#    table('ms');


### group('predict')

types.group('predict').method('predict').
    image('modelimage').
    table('complist').
    boolean('incremental', F);

types.group('predict').method('setoptions').
    choice('ftmachine', 'gridft', options=['gridft', 'SD']).
    integer('cache', 0).
    integer('tile',16).
    choice('gridfunction', 'SF', options=['SF', 'BOX', 'PB']).
    position('location', dm.position('wgs84', '0m', '0m', '0m'),
	    checkeval=F).
    float('padding', 1.3);

types.group('predict').method('setvp').
    boolean('dovp', T).
    boolean('usedefaultvp', T).
    table('vptable', '').
    boolean('dosquint', T).
    quantity('parangleinc', '360deg');

### group('corrupt')

types.group('corrupt').method('corrupt');

types.group('corrupt').method('reset');

types.group('corrupt').method('setbandpass').
    choice('mode',  'calculate', options=['calculate', 'table']).
    table('table').
    quantity('interval', '1h').
    double('amplitude', [0.0, 0.0]);

types.group('corrupt').method('setgain').
    choice('mode', 'calculate', options=['calculate', 'table']).
    table('table').
    quantity('interval', '10s').
    vector_double('amplitude', [0.0, 0.0]);

types.group('corrupt').method('setleakage').
    choice('mode', 'calculate', options=['calculate', 'table']).
    table('table').
    quantity('interval', '5h').
    double('amplitude', 0.0);

types.group('corrupt').method('setnoise').
    choice('mode', 'calculate', options=['simplenoise', 'table', 'calculate' ]).
    quantity('simplenoise', '0.0Jy').
    table('table').
    float('antefficiency', 0.80).
    float('correfficiency', 0.85).
    float('spillefficiency', 0.85).
    float('tau', 0.0).
    float('trx', 50).
    float('tatmos', 250).
    float('tcmb', 2.7);

types.group('corrupt').method('setpa').
    choice('mode', 'calculate', options=['calculate', 'table']).
    table('table').
    quantity('interval', '10s');

types.group('corrupt').method('setseed').integer('seed', 185349251);




