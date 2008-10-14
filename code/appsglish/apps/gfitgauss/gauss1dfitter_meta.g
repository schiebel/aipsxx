# gauss1dfitter_meta.g: Meta information for the gauss1dfitter tool
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
#   $Id: gauss1dfitter_meta.g,v 19.1 2004/08/25 01:17:41 cvsmgr Exp $
#
pragma include once;

include 'types.g';

types.class('gauss1dfitter').includefile('gfitgauss.g');

types.method('ctor_gauss1dfitter');

types.method('gauss1dfitter.fit').
    vector_double('x').
    vector_double('y').
    record('return');

types.method('gauss1dfitter.eval').
    vector_double('x').
    vector_double('return');

types.method('gauss1dfitter.setheight').
    vector_double('height').
    boolean('return');

types.method('gauss1dfitter.setcenter').
    vector_double('center').
    boolean('return');

types.method('gauss1dfitter.setwidth').
    vector_double('width').
    boolean('return');

types.method('gauss1dfitter.setmaxiter').
    integer('maxiter', 30).
    boolean('return');

types.method('gauss1dfitter.setcriteria').
    double('criteria', 0.001).
    boolean('return');

types.method('gauss1dfitter.getstate').
    record('return');

types.method('gauss1dfitter.setstate').
    record('state').
    boolean('return');
