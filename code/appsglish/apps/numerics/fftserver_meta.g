# fftserver_meta.g: Meta information for the fftserver distributed object
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
#   $Id: fftserver_meta.g,v 19.2 2004/08/25 01:43:39 cvsmgr Exp $
#
pragma include once;

include 'types.g';

types.class('fftserver').includefile('fftserver.g');
types.method('ctor_fftserver');
types.method('complexfft').
    integer('dir', 1).
    vector_complex('a', dir='inout');
types.method('realtocomplexfft').
    vector_float('a').
    vector_complex('return');
types.method('convolve').
    vector_float("a b").
    vector_float("return");
types.method('crosscorr').
    vector_float("a b").
    vector_float("return");
types.method('autocorr').
    vector_float("a").
    vector_float("return");
types.method('shift').
    vector_float("a").
    vector_float("shift").
    vector_float("return");
types.method('mfft').
    vector_complex("a").
    vector_boolean("axes").
    boolean("forward").
    vector_complex("return");
