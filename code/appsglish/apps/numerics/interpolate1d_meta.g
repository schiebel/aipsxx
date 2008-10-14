# interpolate1d_meta.g: Meta information for the interpolat1d distributed obj.
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
#   $Id: interpolate1d_meta.g,v 19.2 2004/08/25 01:44:32 cvsmgr Exp $
#
pragma include once;

include 'types.g';

types.class('interpolate1d').includefile('interpolate1d.g');
types.method('ctor_interpolate1d');
types.method('interpolate').
    vector_float("x").
    vector_float("return");
types.method('initialize').
    vector_float("x y").
    choice('method', 'linear', options=['linear', 'nearest', 'cubic',
					'spline']).boolean('return');
types.method('setmethod').
    choice('method', 'linear', options=['linear', 'nearest', 'cubic',
					'spline']);
