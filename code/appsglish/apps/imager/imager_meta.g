# imager_meta.g: Standard meta information for imager
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
#   $Id: imager_meta.g,v 19.15 2006/10/06 16:06:03 kgolap Exp $
#

pragma include once;

include 'types.g';

types.class('imager').includefile("imager.g imagerwizard.g mosaicwizard.g");

# Constructors
types.method('ctor_imager').
    ms('filename').
    boolean('compress', F).
    string('host', '', help='hostname on which to run imager').
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
    choice('ftmachine', 'ft', options=['ft', 'sd', 'both', 'wfmemoryft','wproject', 'mosaic']).
    integer('cache', 0).
    integer('tile',16).
    choice('gridfunction', 'SF', options=['SF', 'BOX', 'PB']).
    position('location', checkeval=F).
    float('padding', 1.0).
    boolean('usemodelcol', T).
    integer('wprojplanes', 1);

types.method('setsdoptions').
    float('scale', 1.0).
    float('weight', 1.0).
    integer('convsupport', -1);

types.method('setbeam').
    quantity('bmaj', '0rad').
    quantity('bmin', '0rad').
    quantity('bpa', '0deg');

types.method('setscales').
    choice('scalemethod', 'nscales', options=['nscales', 'uservector']).
    integer('nscales', 5).
    vector_float('uservector', [0.0,3.0,10.0]);

types.method('settaylorterms').
  choice('ntaylor', options=[1,2,3]);

types.group('weighting').method('weight').
    choice('type', 'uniform', options=['briggs', 'natural', 'uniform', 'radial']).
    choice('rmode', 'none', options=['none', 'norm', 'abs']).
    quantity('noise', '0.0Jy').
    float('robust', 0.0).
    quantity('fieldofview', '0rad').
    integer('npixels', 0).
    boolean('mosaic', F);

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
	   options=['observed', 'model', 'corrected', 'residual', 'psf', 'singledish', 'coverage', 'holography', 'pb']).
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

types.method('approximatepsf').
    image('model', 'clean').
    image('psf');

types.method('makemodelfromsd').
    image('sdimage', '').
    string('modelimage', '').
    image('sdpsf', '').
    image('maskimage','');

types.method('clean').
    choice('algorithm', 'clark',
	   options=['clark', 'hogbom', 'multiscale', 'mfclark', 'csclean',
		    'csfast', 'mfhogbom', 'mfmultiscale', 'wfclark',
		    'wfhogbom']).
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

types.method('pixon').
    choice('algorithm', 'singledish', options=['singledish', 'synthesis', 'test']).
    quantity('sigma', '0.001Jy').
    image('model', 'pixon');

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

types.group('mosaic').method('setvp').
    boolean('dovp', F).
    boolean('usedefaultvp', T).
    table('vptable', '').
    boolean('dosquint', F).
    quantity('parangleinc', '360deg').
    string('telescope','');

types.group('mosaic').method('setmfcontrol').
    float('cyclefactor', 1.5).
    float('cyclespeedup', -1).
    integer('stoplargenegatives', 2).
    integer('stoppointmode', -1).
    choice('scaletype', 'NONE', options=['NONE', 'SAULT']).
    float('minpb', 0.1).
    float('constpb', 0.4).
    image('fluxscale', '');

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

types.group('calibrate').method('setjy').
    integer('fieldid', -1).
    integer('spwid', -1).
    vector_double('fluxdensity', -1.0).
    choice('standard','Perley-Taylor 99', options=['Baars', 'Perley 90', 'Perley-Taylor 95', 'Perley-Taylor 99']);

types.group('mask').method('boxmask').
    image('mask').
    vector_integer('blc').
    vector_integer('trc').
    float('value', 1.0);

types.method('mask').
    image('image').
    image('mask').
    quantity('threshold', '0Jy');

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


types.group('visibility').method('correct').
    boolean('doparallactic', 'T').
    quantity('timestep', '10s');

types.method('clipvis').quantity('threshold', '0Jy');

types.group('plotting').method('plotuv').
    boolean('rotate', F);

types.method('plotsummary');

types.method('plotvis').
    choice('type', 'all',
	  options=['all', 'observed', 'model', 'corrected', 'residual']).
    integer('increment', 1);

# Since this is the last tool function, close out the grouping
types.method('plotweights').group().
    boolean('gridded', F).
    integer('increment', 1);

types.group().method('global_imagertest');

types.group().method('global_imagersdtest');

types.method('global_imagermaketestms').ms('msfile', '3C273XC1.ms');

types.method('global_imagermaketestmfms').ms('msfile', 'XCAS.ms');

types.method('global_imagermaketestsdms').ms('msfile', 'gbt_cygnus_800MHz.ms');

types.method('global_imagermaketestcl').table('clfile', '3C273XC1.cl');

types.method('global_imagerpbtest').
    integer('size', 256).
    integer('cleanniter', 1000).
    float('cleangain', 0.1);

types.method('global_imagercomponenttest').
    integer('size', 256).
    boolean('doshift', F).
    boolean('doplot', T);

#types.method('global_imagerselfcaltest').
#    integer('size', 256).
#    boolean('doshift', F).
#    boolean('doplot', T);


types.method('global_imageralltests');

types.method('global_imagerwizard');

types.method('global_mosaicwizard');
