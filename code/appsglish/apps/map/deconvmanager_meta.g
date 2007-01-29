# deconvmanager_meta.g: Standard meta information for deconvolutionmanager
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: deconvmanager_meta.g,v 19.1 2004/08/25 01:23:36 cvsmgr Exp $
#

pragma include once;

include 'types.g';

types.class('deconvolutionmanager').
   includefile('deconvmanager.g');

# Constructors
types.method('ctor_deconvolutionmanager');

# Methods
types.method('clean').
   choice('algorithm', 'clark', options=['clark', 'hogbom', 'multiscale', 
          'mfclark', 'mfhogbom', 'mfmultiscale', 'wfclark', 'wfhogbom']).
   integer('niter', 1000).
   float('gain', 0.1).
   quantity('threshold', '0Jy').
   choice('scalemethod', 'nscales', options=['nscales', 'uservector']).
   integer('nscales', 5).
   vector_float('uservector', [0.0,3.0,10.0]).
   float('cyclefactor', 3.0).
   float('cyclespeedup', -1).
   integer('stoplargenegatives', 2).
   integer('stoppointmode', -1).
   boolean('displayprogress', F).
   deconvolution('return', 'mydeconvolution', dir='inout');

types.method('mem').
   choice('algorithm', 'entropy', options=['entropy', 'emptiness', 
          'mfentropy', 'mfemptiness']). 
   integer('niter', 20).
   quantity('sigma', '0.001Jy').
   quantity('targetflux', '1.0Jy').
   boolean('constrainflux', F).
   choice('scalemethod', 'nscales', options=['nscales', 'uservector']).
   integer('nscales', 5).
   vector_float('uservector', [0.0,3.0,10.0]).
   float('cyclefactor', 3.0).
   float('cyclespeedup', -1).
   integer('stoplargenegatives', 2).
   integer('stoppointmode', -1).
   boolean('displayprogress', F).
   deconvolution('return', 'mydeconvolution', dir='inout');

types.method('nnls').
   choice('algorithm', 'nnls', options=['nnls']).
   integer('niter', 1000).
   float('tolerance', 0.0000001).
   choice('scalemethod', 'nscales', options=['nscales', 'uservector']).
   integer('nscales', 5).
   vector_float('uservector', [0.0,3.0,10.0]).
   float('cyclefactor', 3.0).
   float('cyclespeedup', -1).
   integer('stoplargenegatives', 2).
   integer('stoppointmode', -1).
   boolean('displayprogress', F).
   deconvolution('return', 'mydeconvolution', dir='inout');



