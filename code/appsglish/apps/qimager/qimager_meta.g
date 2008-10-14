# qimager_meta.g: Standard meta information for qimager
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
#   $Id: qimager_meta.g,v 1.5 2004/08/25 01:48:32 cvsmgr Exp $
#

pragma include once;

include 'types.g';

types.class('qimager').includefile("qimager.g");

# Constructors
types.method('ctor_qimager').
    ms('filename').
    boolean('compress', F).
    string('host', '', help='hostname on which to run qimager').
  boolean('forcenewserver', T, help='Force creation of a new server');

# Methods

types.group('basic').method('open').
    ms('thems').
    boolean('compress', F);


#  Currently, close() causes a core dump, but only when accessed from
#  the gui; reasons are totally unknown; so we are removing it from the meta info
#
#  types.method('close');

types.method('name').
    ms('return');

types.method('summary');

types.group('setup').method('setimage').
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
    integer('facets', 1).
    quantity('distance', '0m');

types.method('setdata').
    choice('mode', 'none', options=['none', 'channel', 'velocity']).
    vector_integer('nchan', [1]).
    vector_integer('start', [1]).
    vector_integer('step', [1]).
    quantity('mstart', '0km/s').
    quantity('mstep', '0km/s').
    vector_integer('spwid', 1).
    vector_integer('fieldid', 1).
    taql('msselect', '', options='Measurement Set');

types.method('setoptions').
    choice('ftmachine', 'ft', options=['ft', 'mosaic', 'wproject']).
    integer('cache', 0).
    integer('tile',16).
    position('location', checkeval=F).
    float('padding', 1.2);

types.method('setsdoptions').
    float('scale', 1.0).
    float('weight', 1.0);

types.method('setbeam').
    quantity('bmaj', '0rad').
    quantity('bmin', '0rad').
    quantity('bpa', '0deg');

types.method('setscales').
    vector_float('uservector', [0.0,3.0,10.0]);

types.group('weighting').method('weight').
    choice('type', 'uniform',
	   options=['briggs', 'natural', 'uniform', 'radial']).
    choice('rmode', 'norm', options=['norm', 'abs']).
    quantity('noise', '0.0Jy').
    float('robust', 0.0).
    quantity('fieldofview', '0rad').
    integer('npixels', 0);

types.method('filter').
    choice('type', 'gaussian', options=['gaussian']).
    quantity('bmaj', '0rad').
    quantity('bmin', '0rad').
    quantity('bpa', '0deg');

types.method('uvrange').
    float('uvmin', 0.0).
    float('uvmax', 0.0);

types.method('sensitivity').
    quantity('pointsource', '0.0Jy', dir='out').
    float('relative', 0.0, dir='out').
    float('sumweights', 0.0, dir='out');

types.method('fitpsf').
    image('psf').
    quantity('bmaj', '0rad', dir='out').
    quantity('bmin', '0rad', dir='out').
    quantity('bpa', '0deg', dir='out');

types.group('helpers').method('advise').
    boolean('takeadvice', F).
    float('amplitudeloss', 0.05).
    quantity('fieldofview', '1arcmin').
    integer('pixels', 128, dir='out').
    quantity('cell', '1arcsec', dir='out').
    integer('facets', 1, dir='out').
    direction('phasecenter', dir='out');

types.method('smooth').
    image('model').
    image('image').
    boolean('usefit',T).
    quantity('bmaj', '0rad').
    quantity('bmin', '0rad').
    quantity('bpa', '0deg').
    boolean('normalize', T);

types.method('make').
    image('image');

types.group('image').method('makeimage').
    choice('type', 'corrected',
	   options=['observed', 'model', 'corrected', 'residual', 'psf', 'singledish', 'coverage', 'holography']).
    image('image').
    image('compleximage');

types.method('restore').
    image('model', 'clean').
    table('complist').
    image('image', 'clean.restored').
    image('residual', 'clean.residual');

types.method('residual').
    image('model', 'clean').
    table('complist').
    image('image');

types.method('clean').
    choice('algorithm', 'clark',
	   options=['clark', 'hogbom', 'multiscale', 'mfclark', 'csclean',
		    'csfast', 'mfhogbom', 'mfmultiscale']).
    integer('niter', 1000).
    float('gain', 0.1).
    quantity('threshold', '0Jy').
    boolean('displayprogress', F).
    image('model', 'clean').
    vector_boolean('fixed', F).
    table('complist').
    image('mask').
    image('image', 'clean.restored', allowunset=T).
    image('residual', 'clean.residual', allowunset=T).
    boolean('interactive',F).
    integer('npercycle',100).
    image('masktemplate','');

types.method('mem').
    choice('algorithm', 'entropy', options=['entropy', 'emptiness',
					    'mfentropy', 'mfemptiness']). 
    integer('niter', 20).
    quantity('sigma', '0.001Jy').
    float('gain', 0.3).
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

types.method('predict').
    image('model', 'clean').
    table('complist').
    boolean('incremental', F);

types.group('mosaic').method('setvp').
    boolean('dovp', F).
    boolean('usedefaultvp', T).
    string('vptable', '').
    boolean('dosquint', F).
    quantity('parangleinc', '360deg');

types.group('mosaic').method('setmfcontrol').
    float('cyclefactor', 1.5).
    float('cyclespeedup', -1).
    integer('stoplargenegatives', 2).
    integer('stoppointmode', -1);

types.group('mosaic').method('feather').
    image('image', 'feathered.image').
    image('highres').
    image('lowres');

types.group('mosaic').method('pb').
    image('inimage', '').
    image('outimage', '').
    table('incomps', '').
    table('outcomps', '').
    choice('operation', 'apply', options=['apply', 'correct']).
    direction('pointingcenter'). 
    quantity('parangle', '0deg').
    choice('pborvp', 'pb', options=['pb', 'vp']);

types.group('mosaic').method('linearmosaic').
    image('mosaic', '').
    image('fluxscale', '').
    image('sensitivity', '').
    image('images', '').
    vector_integer('fieldid', [1]);

types.method('regionmask').
    image('mask').
    region('region').
    untyped('value', 1.0);

types.method('exprmask').
    image('mask').
    string('expr', '');

