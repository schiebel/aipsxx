# randomnumbers_meta.g: Meta information for the randomnumbers distributed obj.
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
#   $Id: randomnumbers_meta.g,v 19.2 2004/08/25 01:45:43 cvsmgr Exp $
#

pragma include once;

include 'types.g';
include 'unset.g';

types.class('randomnumbers').includefile('randomnumbers.g');

types.method('ctor_randomnumbers');

types.method('binomial').integer('number', 1).double('probability', 0.5).
  vector_integer('shape', [1]).vector_integer('return');

types.method('discreteuniform').integer('low', -1).integer('high', 1).
  vector_integer('shape', [1]).vector_integer('return');

types.method('erlang').double('mean', 1.0).double('variance', 1.0).
  vector_integer('shape', [1]).vector_double('return');

types.method('geometric').double('probability', 0.5).
  vector_integer('shape', [1]).vector_integer('return');

types.method('hypergeometric').double('mean', 0.5).double('variance', 1.0).
  vector_integer('shape', [1]).vector_double('return');

types.method('normal').double('mean', 0.0).double('variance', 1.0).
  vector_integer('shape', [1]).vector_double('return');

types.method('lognormal').double('mean', 1.0).double('variance', 1.0).
  vector_integer('shape', [1]).vector_double('return');

types.method('negativeexponential').double('mean', 1.0).
  vector_integer('shape', [1]).vector_double('return');

types.method('poisson').double('mean', 1.0).
  vector_integer('shape', [1]).vector_integer('return');

types.method('uniform').double('low', -1.0).double('high', 1.0).
  vector_integer('shape', [1]).vector_double('return');

types.method('weibull').double('alpha', 1.0).double('beta', 1.0).
  vector_integer('shape', [1]).vector_double('return');

types.method('reseed').integer('seed', default=unset, allowunset=T);

# Global functions

types.method('global_randomnumbersdemo');
types.method('global_randomnumberstest');
