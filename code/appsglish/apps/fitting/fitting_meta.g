# fitting_meta.g: Standard meta information for fitting.g
#
#   Copyright (C) 2000,2001
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
#   $Id: fitting_meta.g,v 19.2 2004/08/25 01:14:51 cvsmgr Exp $

pragma include once

include 'types.g';

types.class('fitter').includefile('fitting.g');

# Constructors
types.method('ctor_fitter').
    integer('n', 0).
    integer('m', 1).
    integer('type', 0).
    untyped('fnct', unset).
    untyped('vfnct', unset).
    vector_double('guess', unset).
    double('colfac', 1e-8).
    double('lmfac', 1e-3);

# Tool functions
# Initialisations
types.method('init').
    integer('n', unset, allowunset=T).
    integer('m', 1).
    string('type', 'real').
    untyped('fnct', unset).
    untyped('vfnct', unset).
    vector_double('guess', unset, allowunset=T).
    double('colfac', 1e-8).
    double('lmfac', 1e-3).
    integer('id', 0).
    boolean('return');
types.method('set').
    integer('n', unset, allowunset=T).
    integer('m', unset, allowunset=T).
    string('type', unset, allowunset=T).
    untyped('fnct', unset).
    untyped('vfnct', unset).
    vector_double('guess', unset, allowunset=T).
    double('colfac', unset, allowunset=T).
    double('lmfac', unset, allowunset=T).
    integer('id', 0).
    boolean('return');
types.method('fitter').
    integer('n', 0).
    integer('m', 1).
    string('type', 'real').
    untyped('fnct', unset).
    untyped('vfnct', unset).
    vector_double('guess', unset, allowunset=T).
    double('colfac', 1e-8).
    double('lmfac', 1e-3).
    integer('return');
types.method('reset').
    integer('id', 0).
    boolean('return');
# Types
types.method('real').
    integer('return');
types.method('complex').
    integer('return');
types.method('separable').
    integer('return');
types.method('asreal').
    integer('return');
types.method('conjugate').
    integer('return');
# State
types.method('getstate').
    integer('id', 0).
    record('return');
# Make
types.method('make').
    vector_double('ce', help='Condition equation(s)').
    vector_double('y', help='Known right-hand side(s)').
    vector_double('sd', unset, allowunset=T, help='sd per ce').
    vector_double('wt', 1, help='weight if no sd given').
    integer('id', 0).
    boolean('return');

# Global functions
