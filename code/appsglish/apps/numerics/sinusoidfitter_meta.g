# sinusoidfitter_meta.g: 
# Copyright (C) 1999
# Associated Universities, Inc. Washington DC, USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
# License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: sinusoidfitter_meta.g,v 19.2 2004/08/25 01:46:03 cvsmgr Exp $

pragma include once;

include 'types.g';

types.class('sinusoidfitter').includefile('sinusoidfitter.g');
types.method('ctor_sinusoidfitter');
types.method('fit').
    vector_double("x y").
    vector_double('sigma', 1.0).
    record('state', dir='out').
    boolean('return');
types.method('eval').
    vector_double('x').
    vector_double('y', dir='out').
    boolean('return');
types.method('setstate').record('state').boolean('return');
types.method('getstate').record('state', dir='out').boolean('return');
