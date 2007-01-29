# pimager_meta.g: Standard meta information for pimager
#
#   Copyright (C) 1996,1997,1998,1999
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
#   $Id: pimager_meta.g,v 19.1 2004/08/25 01:47:25 cvsmgr Exp $
#

pragma include once;

include 'types.g';

types.class('pimager').
    includefile('pimager.g');

# Constructors
types.method('ctor_pimager').
    ms('filename').
    method('ctor_pimagertester').
    ms('filename', '3C273XC1.ms').
    integer('size', 256).
    quantity('cell', '0.7arcsec').
    choice('stokes', 'IV', options=['I', 'IV', 'IQUV']).
    choice('coordinates', 'b1950', options=['b1950', 'gal']);

# Methods
types.method('open').
    ms('thems');

types.method('close');

types.method('name').
    ms('return');

types.method('summary');

types.method('setimage').
    integer('nx',128).
    integer('ny',128).
    quantity('cellx','1arcsec').
    quantity('celly','1arcsec').
    choice('stokes', 'IV', options=['I', 'IV', 'IQUV']).
    boolean('doshift', F).
    direction('phasecenter').
    quantity('shiftx', '0arcsec').
    quantity('shifty', '0arcsec').
    choice('mode', 'mfs', options=['mfs', 'channel', 'velocity']).
    integer('nchan', 1).
    integer('start', 1).
    integer('step', 1).
    quantity('mstart', '0km/s').
    quantity('mstep', '0km/s').
    vector_integer('spwid', 1).
    vector_integer('fieldid', 1).
    integer('facets', 1);

types.method('advise').
    boolean('takeadvice', F).
    float('amplitudeloss', 0.05).
    quantity('fieldofview', '1arcmin').
    integer('pixels', 128, dir='out').
    quantity('cell', '1arcsec', dir='out').
    integer('facets', 1, dir='out').
    direction('phasecenter', dir='out');

types.method('setdata').
    choice('mode', 'none', options=['none', 'channel', 'velocity']).
    integer('nchan', 1).
    integer('start', 1).
    integer('step', 1).
    quantity('mstart', '0km/s').
    quantity('mstep', '0km/s').
    vector_integer('spwid', 1).
    vector_integer('fieldid', 1);

types.method('setvp').
    boolean('dovp', F).
    boolean('usedefaultvp', T).
    string('vptable', '').
    boolean('dosquint', T).
    quantity('parangleinc', '360deg');

types.method('setoptions').
    choice('ftmachine', 'gridft', options=['gridft', 'SD']).
    integer('cache', 0).
    integer('tile',16).
    choice('gridfunction', 'SF', options=['SF', 'BOX']).
    position('location', checkeval=F).
    float('padding', 1.0);

types.method('weight').
    choice('type', 'uniform', options=['briggs', 'natural', 'uniform']).
    choice('rmode', 'robust', options=['none', 'robust', 'abs']).
    quantity('noise', '0.0Jy').
    float('robust', 0.0).
    quantity('fieldofview', '0rad').
    integer('npixels', 0);

types.method('sensitivity').
    quantity('pointsource', '0.0Jy', dir='out').
    float('relative', 0.0, dir='out').
    float('sumweights', 0.0, dir='out');

types.method('filter').
    choice('type', 'gaussian', options=['gaussian']).
    quantity('bmaj', '0rad').
    quantity('bmin', '0rad').
    quantity('bpa', '0deg');

types.method('uvrange').
    float('uvmin', 0.0).
    float('uvmax', 0.0);

types.method('image').
    choice('type', 'corrected',
	   options=['observed', 'model', 'corrected', 'residual', 'psf', 'singledish', 'coverage', 'holography']).
    image('image').
    image('compleximage');

types.method('restore').
    image('model', 'clean').
    table('complist').
    image('image', 'clean.restored').
    image('residual', 'clean.residual');

types.method('setbeam').
    quantity('bmaj', '0rad').
    quantity('bmin', '0rad').
    quantity('bpa', '0deg');

types.method('residual').
    image('model', 'clean').
    table('complist').
    image('image');

types.method('clean').
    choice('algorithm', 'clark', options=['clark', 'hogbom', 'multiscale', 'mfclark', 
	'mfhogbom', 'mfmultiscale', 'wfclark', 'wfhogbom']).
    integer('niter', 1000).
    float('gain', 0.1).
    quantity('threshold', '0Jy').
    boolean('displayprogress', F).
    image('model', 'clean').
    vector_boolean('fixed', F).
    table('complist').
    image('mask').
    image('image', 'clean.restored').
    image('residual', 'clean.residual');

types.method('mem').
    choice('algorithm', 'entropy', options=['entropy', 'emptiness', 'mfentropy', 'mfemptiness']). 
    integer('niter', 20).
    quantity('sigma', '0.001Jy').
    quantity('targetflux', '1.0Jy').
    boolean('constrainflux', F).
    boolean('displayprogress', F).
    image('model', 'mem').
    vector_boolean('fixed', F).
    table('complist','').
    image('prior', '').
    image('mask', '').
    image('image', 'mem.restored').
    image('residual', 'mem.residual');

types.method('nnls').
    choice('algorithm', 'nnls', options=['nnls']).
    integer('niter', 1000).
    float('tolerance', 0.0000001).
    image('model', 'nnls').
    vector_boolean('fixed', F).
    table('complist').
    image('fluxmask').
    image('datamask').
    image('image', 'nnls.restored').
    image('residual', 'nnls.residual');

types.method('ft').
    image('model', 'clean').
    table('complist').
    boolean('incremental', F);

types.method('setjy').
    integer('fieldid', -1).
    integer('spwid', -1).
    vector_double('fluxdensity', 1.0);

types.method('make').
    image('image');

types.method('boxmask').
    image('mask').
    vector_integer('blc').
    vector_integer('trc').
    float('value', 1.0);

types.method('regionmask').
    image('mask').
    region('region').
    untyped('value', 1.0);

types.method('exprmask').
    image('mask').
    string('expr', '');

types.method('clipimage').
    image('image').
    quantity('threshold', '0Jy');

types.method('clipvis').quantity('threshold', '0Jy');

types.method('fitpsf').
    image('psf').
    quantity('bmaj', '0rad', dir='out').
    quantity('bmin', '0rad', dir='out').
    quantity('bpa', '0deg', dir='out');

types.method('correct').
    boolean('doparallactic', 'T').
    quantity('timestep', '10s');

types.method('smooth').
    image('model').
    image('image').
    quantity('bmaj', '0rad').
    quantity('bmin', '0rad').
    quantity('bpa', '0deg').
    boolean('normalize', T);

types.method('mask').
    image('image').
    image('mask').
    quantity('threshold', '0Jy');

types.method('plotuv').
    boolean('rotate', F);

types.method('plotsummary');

types.method('plotvis').
    choice('type', 'all',
	  options=['all', 'observed', 'model', 'corrected', 'residual']).
    integer('increment', 1);

types.method('plotweights').
    boolean('gridded', F).
    integer('increment', 1);

types.method('setscales').
    choice('scalemethod', 'nscales', options=['nscales', 'uservector']).
    integer('nscales', 5).
    vector_float('uservector', [0.0,3.0,10.0]);

types.method('global_pimagertest').
    integer('cleanniter', 1000).
    float('cleangain', 0.1).
    boolean('doshift', F).
    boolean('doplot', T).
    integer('cache', 1024*1024).
    choice('algorithm', 'clark', options=['clark', 'hogbom', 'multiscale', 'mfclark', 
					  'mfhogbom', 'mfmultiscale', 'wfclark',
					  'wfhogbom']);

types.method('global_pimagermaketestms').ms('msfile', '3C273XC1.ms');

types.method('global_pimagermaketestcl').table('clfile', '3C273XC1.cl');

types.method('global_pimagerpbtest').
    integer('size', 256).
    integer('cleanniter', 1000).
    float('cleangain', 0.1);

types.method('global_pimagerspectraltest').
    integer('size', 128).
    integer('cleanniter', 100).
    float('cleangain', 0.2);

types.method('global_pimagermftest').
    boolean('doshift', F).
    boolean('doplot', T);

types.method('global_pimagercomponenttest').
    integer('size', 256).
    boolean('doshift', F).
    boolean('doplot', T);

types.method('global_pimagerselfcaltest').
    integer('size', 256).
    boolean('doshift', F).
    boolean('doplot', T);

types.method('global_pimagerlongtest');

types.method('global_pimageralltests');
