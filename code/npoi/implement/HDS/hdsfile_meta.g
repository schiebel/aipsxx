# hdsfile_meta.g:
# Copyright (C) 1998,1999
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
# $Id: hdsfile_meta.g,v 19.0 2003/07/16 06:02:52 aips2adm Exp $

pragma include once;

include 'types.g';

types.class('hdsfile').includefile('hdsfile.g');

# Constructors
types.method('ctor_hdsfile').file('filename', 'data.sdf', 'in').
  boolean('readonly', T, 'in');

# Methods
types.method('ls').vector_string('return');
types.method('cd').string('node', '.');
types.method('cdup');
types.method('cdtop');
types.method('name').string('return');
types.method('fullname').string('return');
types.method('type').string('return');
types.method('shape').vector_integer('return');
types.method('get').vector_double('return');
types.method('getstring').string('return');
types.method('structure');
