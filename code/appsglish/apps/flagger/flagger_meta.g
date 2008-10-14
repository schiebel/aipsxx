# flagger_meta.g: Standard meta information for flagger
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
#   $Id: flagger_meta.g,v 19.1 2004/08/25 01:15:38 cvsmgr Exp $
#

pragma include once;

include 'types.g';

types.class('flagger').includefile('flagger.g');

types.method('ctor_flagger').ms('msfile', context='ms');

types.method('ctor_flaggertester').ms('msfile', '3C273XC1.ms',
				      context='ms');

types.method('setids').
    fields('fieldid').
    spectralwindows('spectralwindowid').
    vector_integer('arrayid', []).
    boolean('return');

types.method('setchan').
    vector_integer('chan', []).
    boolean('return');

types.method('setpol').
    vector_integer('pol', []).
    boolean('return');

types.method('setantennas').
    antennas('ants', []).
    boolean('return');

types.method('setbaselines').
    antennas('ants', []).
    boolean('return');

types.method('setfeeds').
    vector_integer('feeds', []).
    boolean('return');

types.method('setuvrange').
    quantity('uvmin','0.0m').
    quantity('uvmax','0.0m').
    boolean('return');

types.method('setflagmode').
    choice('mode', options=['flag', 'unflag']).
    boolean('return');

types.method('settimerange').
    time('starttime', unset, allowunset=T).
    time('endtime', unset, allowunset=T).
    boolean('return');

types.method('settime').
    time('centertime', unset, allowunset=T).
    quantity('delta', '10s').
    boolean('return');

#types.method('setquery').
#    msselect('query', unset, allowunset=T).
#    boolean('comb').
#    boolean('return');

types.method('flag').
    boolean('trial', F).
    boolean('return');

types.method('unflag').
    boolean('trial', F).
    boolean('return');

types.method('quack').
    quantity('delta', '0s').
    boolean('begin', T).
    boolean('end', F).
    quantity('scaninterval','0s').
    boolean('trial', F).
    boolean('return');

types.method('flagac').
    boolean('trial', F).
    boolean('return');

types.method('auto').
    boolean('trial', F).
    boolean('return');

types.method('query').
    msselect('query', unset, allowunset=T).
    boolean('trial', F).
    boolean('return');

types.method('time').
    time('centertime', unset, allowunset=T).
    quantity('delta', '10s').
    boolean('trial', F).
    boolean('return');

types.method('timerange').
    time('starttime', unset, allowunset=T).
    time('endtime', unset, allowunset=T).
    boolean('trial', F).boolean('return');

types.method('filter').
    choice('column', options=['CORRECTED_DATA',
			      'MODEL_DATA',
			      'RESIDUAL_DATA',
			      'DATA']).
    choice('operation', options=['median', 'range']).
    choice('comparison', options=['Amplitude', 'Phase', 'Real', 'Imaginary']).
    vector_string('range', ['0Jy', '1E6Jy']).
    vector_double('threshold', [0.0, 5.0]).
    boolean('fullpol',F).
    boolean('fullchan',F).
    boolean('trial', F).
    boolean('return');

types.method('calsolutions').
    table('gaintable', '', options='Calibration').
    float('threshold', 5.0).
    choice('mode', options=['time', 'antenna']).
    boolean('trial', F).
    boolean('return');

types.method('flush').boolean('return');

types.method('reset').boolean('return');

types.method('state').record('state', dir='out').string('return');
