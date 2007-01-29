# dragon_meta.g: Standard meta information for dragon
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001
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
#   $Id: dragon_meta.g,v 19.1 2004/08/25 01:19:35 cvsmgr Exp $
#

pragma include once;

include 'types.g';
include 'measures.g';

types.class('dragon').includefile('dragon.g');

types.method('global_dragontest').fits('filename').boolean('doimage', T).boolean('dofind', T);

types.method('ctor_dragon').ms('filename');

types.method('setimage').
    string('name', 'dragon').
    integer('nx',128).
    integer('ny',128).
    quantity('cellx','1arcsec').
    quantity('celly','1arcsec').
    choice('stokes', 'I', options=['I', 'IV', 'IQUV']).
    boolean('doshift', F).
    direction('phasecenter', dm.direction('b1950', '0d', '0d')).
    choice('mode', 'mfs', options=['mfs', 'channel', 'velocity']).
    integer('nchan', 1).
    integer('start', 1).
    integer('step', 1).
    vector_integer('spwid', 1).
    vector_integer('fieldid', 1).
    integer('facets', 1);

types.method('setoutlier').
    string('name').
    integer('nx',128).
    integer('ny',128).
    quantity('cellx','1arcsec').
    quantity('celly','1arcsec').
    choice('stokes', 'I', options=['I', 'IV', 'IQUV']).
    boolean('doshift', F).
    direction('phasecenter', dm.direction('b1950', '0d', '0d')).
    choice('mode', 'mfs', options=['mfs', 'channel', 'velocity']).
    integer('nchan', 1).
    integer('start', 1).
    integer('step', 1).
    vector_integer('spwid', 1).
    vector_integer('fieldid', 1);

types.method('advise').
    float('amplitudeloss', 0.05).
    quantity('fieldofview', '1arcmin').
    integer('pixels', 128, dir='out').
    quantity('cell', '1arcsec', dir='out').
    integer('facets', 1, dir='out').
    direction('phasecenter', dm.direction('b1950', '0d', '0d'),
	      dir='out');

types.method('setoptions').
    integer('cache', 0).
    float('padding', 1.0);

types.method('weight').
    choice('type', 'uniform', options=['natural', 'uniform', 'briggs']).
    choice('rmode', 'none', options=['none', 'robust', 'abs']).
    quantity('noise', '0.0Jy').
    float('robust', 0.0).
    quantity('fieldofview', '0rad').
    integer('npixels', 0);

types.method('filter').
    quantity('bmaj', '0rad').
    quantity('bmin', '0rad').
    quantity('bpa', '0deg');

types.method('uvrange').
    float('uvmin', 0.0).
    float('uvmax', 0.0);

types.method('setbeam').
    quantity('bmaj', '0rad').
    quantity('bmin', '0rad').
    quantity('bpa', '0deg');
types.method('image').
    string('levels').
    quantity('amplitudelevel', '0Jy').
    vector_string('timescales', ['10s']).
    integer('niter', 1000).
    float('gain', 0.1).
    quantity('threshold', '0.0Jy').
    boolean('plot', T).
    boolean('display', T).
    table('complist').
    image('models', dir='out').
    image('images', dir='out').
    image('residuals', dir='out').
    region('statsregion', unset, allowunset=T).
    record('statsout', dir='out').
    choice('algorithm','wfclark',options=['wfclark', 'wfhogbom']).
    choice('maskmodification', 'none', options=['none', 'auto', 'interactive']);
types.method('reset');












