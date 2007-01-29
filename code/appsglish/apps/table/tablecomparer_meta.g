# tablecomparer_meta.g: Standard meta information for tablecomparer
#
#   Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
#

pragma include once;

include 'types.g';

types.class('tablecomparer').includefile('tablecomparer.g');

types.method('ctor_tablecomparer').
    table('test').
    table('model').
    string('label','TABLE').
    integer('verbose',1);

types.method('checkcoldata').
    boolean('checksubtables',T).
    boolean('return');

types.method('checkcolkeywordnames').
    boolean('checksubtables',T).
    boolean('return');

types.method('checkcolnames').
    boolean('checksubtables',T).
    boolean('return');

types.method('checkkeywordnames').
    boolean('checksubtables',T).
    boolean('return');

types.method('close').
    boolean('return');

types.method('compare').
    boolean('checksubtables',T).
    boolean('checkcolnames',T).
    boolean('checkcolkeywordnames',T).
    boolean('checkcoldata',T).
    boolean('checktablekeywordnames',T).
    boolean('return');

types.method('details').
    record('return');

types.method('done').
    boolean('return');

types.method('select').
    vector_string('checkonlycols','').
    vector_string('nocheckcols','').
    boolean('return');

types.method('settolerance').
    float('float',0).
    double('double',0).
    float('complex',0).
    double('dcomplex',0).
    record('cols',[=]).
    boolean('return');

types.method('summary').
    boolean('dolog',T).
    record('return');

types.method('tolerance').
    string('col').
    string('tlabel','').
    double('return');

