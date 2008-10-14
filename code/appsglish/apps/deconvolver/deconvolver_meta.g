# deconvolver_meta.g: Standard meta information for deconvolver
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2003
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
#   $Id: deconvolver_meta.g,v 19.2 2004/08/25 01:08:04 cvsmgr Exp $
#

pragma include once;

include 'types.g';

types.class('deconvolver').includefile('deconvolver.g');

# Constructors
types.method('ctor_deconvolver').
    table('dirtyname').
    table('psfname');

types.method('ctor_deconvolvertester').
    table('filename', '3C273XC1.ms').
    integer('size', 256).
    quantity('cell', '0.7arcsec').
    choice('stokes', 'I', options=['I', 'IV', 'IQUV']).
    choice('coordinates', 'b1950', options=['b1950','gal']);

# Methods
types.method('open').
    table('dirtyname', '').
    table('psfname', '');

#  These two methods display a curiosity: 
#  the run fine from the glish cli, but crash the system
#  when run from the gui.  We are keeping them out of the
#  gui for now.
#
#types.method('reopen');

# types.method('close');

types.method('dirtyname').table('return');

types.method('psfname').table('return');

types.method('summary');

types.method('restore').
    table('model', 'clean').
    table('image', '').
    quantity('bmaj', '0rad').
    quantity('bmin', '0rad').
    quantity('bpa', '0deg');

types.method('residual').
    table('model', 'clean').table('image', '');

types.method('clean').
    choice('algorithm', 'msclean', options=['hogbom','msclean', 'fullmsclean']).integer('niter', 1000).
    float('gain', 0.1).quantity('threshold', '0Jy').boolean('displayprogress', F).
    table('model', 'clean').table('mask', '');

types.method('make').
    table('image', '');

types.method('clarkclean').
    integer('niter', 1000).float('gain', 0.1).quantity('threshold', '0Jy').
    boolean('displayprogress', F).
    table('model', 'clean').table('mask', '').integer('histbins', 500).
    vector_integer('psfpatchsize', [51,51]).float('maxextpsf', 0.2).float('speedup', 0.0).
    integer('maxnumpix', 10000).integer('maxnummajcycles', -1).
    integer('maxnummineriter', -1);

types.method('pixon').
    integer('niter', 1000).float('gain', 0.1).quantity('threshold', '0Jy').
    boolean('displayprogress', F).
    table('model', 'clean').table('mask', '').integer('histbins', 500).
    vector_integer('psfpatchsize', [51,51]).float('maxextpsf', 0.2).float('speedup', 0.0).
    integer('maxnumpix', 10000).integer('maxnummajcycles', -1).
    integer('maxnummineriter', -1);

types.method('mem').
    choice('entropy', 'entropy', options=['entropy', 'emptiness']).
    integer('niter', 20).
    quantity('sigma', '0.001Jy').
    quantity('targetflux', '1.0Jy').
    boolean('constrainflux', F).
    boolean('displayprogress', F).
    table('model', 'mem').
    table('prior', '').
    table('mask', '').
    boolean('imageplane', F);

types.method('makeprior').
    table('prior', '').
    table('templateimage', '').
    quantity('lowclipfrom', '0.0Jy').
    quantity('lowclipto', '0.0Jy').
    quantity('highclipfrom', '9e20Jy').
    quantity('highclipto', '9e20Jy').
    vector_integer('blc').
    vector_integer('trc');

types.method('setscales').
    choice('scalemethod', 'nscales', options=['nscales', 'uservector']).
    integer('nscales', 5).
    vector_float('uservector', [0.0,3.0,10.0]);

types.method('ft').
    table('model', 'clean').
    table('transform', '');

types.method('smooth').
    table('model', '').
    table('image', '').
    quantity('bmaj', '0rad').
    quantity('bmin', '0rad').
    quantity('bpa', '0deg').
    boolean('normalize', T);

types.method('boxmask').
    table('mask', '').
    vector_integer('blc').
    vector_integer('trc').
    quantity('fillvalue', '1.0Jy').
    quantity('outsidevalue', '0.0Jy');

types.method('clipimage').
    table('clippedimage', '').
    table('inputimage', '').
    quantity('threshold', '0.0Jy');

types.method('makegaussian').
    table('gaussianimage', '').
    quantity('bmaj', '0rad').
    quantity('bmin', '0rad').
    quantity('bpa', '0deg').
    boolean('normalize', T);

types.method('convolve').
    table('convolvedmodel', '').
    table('model', '');








