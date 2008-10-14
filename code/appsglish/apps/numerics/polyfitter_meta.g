# polyfitter_meta.g: Meta information for the polyfitter distributed object
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
#   $Id: polyfitter_meta.g,v 19.2 2004/08/25 01:45:28 cvsmgr Exp $
#
pragma include once;

include 'types.g';

types.class('polyfitter').includefile('polyfitter.g');
types.method('ctor_polyfitter');
types.method('fit').
  vector_double('x').  
  vector_double('y').
  vector_double('sigma', 1.0).
  integer('order', 2).
  vector_double('coeff', dir='out').
  vector_double('coefferrs', dir='out').
  double('chisq', dir='out').
  boolean('return');

# The following should really have 
#types.method('multifit').
#  vector_double('x').
#  array_double('y').
#  vector_double('sigma', 1.0).
#  integer('order', 2).
#  array_double('coeff', dir='out').
#  array_double('coefferrs', dir='out').
#  vector_double('chisq', dir='out').
#  boolean('return');
types.method('multifit').
  vector_double('x').
  vector_double('y').
  vector_double('sigma', 1.0).
  integer('order', 2).
  vector_double('coeff', dir='out').
  vector_double('coefferrs', dir='out').
  vector_double('chisq', dir='out').
  boolean('return');

# The following should really have 
#types.method('eval').
#  double('x').
#  array_double('coeff').
#  vector_double('y', dir='out').
#  boolean('return');
types.method('eval').
  vector_double('x').
  vector_double('coeff').
  vector_double('y', dir='out').
  boolean('return');
