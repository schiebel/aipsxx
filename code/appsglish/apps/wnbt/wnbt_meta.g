# wnbt_meta.g: Standard meta information for wnbt.g
#
#   Copyright (C) 2000
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
#   $Id: wnbt_meta.g,v 19.2 2004/08/25 01:57:38 cvsmgr Exp $

pragma include once

include 'types.g';

types.class('wnbt').includefile('wnbt.g');

# Constructors
types.method('ctor_wnbt');

# Functions

types.method('wnbt.imop').
    image('infile');

types.method('wnbt.imcl');

types.method('wnbt.imph');

types.method('wnbt.imel').
    vector_integer('index',[0,0,0,0]).
    double('return');

types.method('wnbt.imfd').
    integer('number', 20).
    double('maplim', 0.1).
    boolean('afind', F).
    vector_double('return');

types.method('wnbt.compdef').
    file('compl').
    boolean('return');

types.method('wnbt.comprem').
    boolean('return');

types.method('wnbt.compmak').
    vector_dcomplex('deriv').
    vector_dcomplex('dat').
    boolean('return');

types.method('wnbt.compsol').
    vector_double('sol', dir='inout').
    vector_double('err', dir='inout');


