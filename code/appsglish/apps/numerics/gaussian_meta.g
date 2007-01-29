# gaussian_meta.g: Info used by the toolmanager to make a gui for gaussian?d
#
#
#   Copyright (C) 1996,1997,1998,1999,2000
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
#   $Id: gaussian_meta.g,v 19.2 2004/08/25 01:44:17 cvsmgr Exp $
#

pragma include once;

include 'types.g';

types.class('gaussian').includefile('gaussian.g');

types.method('global_gaussian1d').
  vector_double('x', [-1,0,1]).
  double('height', 1.0).
  double('center', 0.0).
  double('fwhm', 1.0).
  vector_double('return', dir='out');

types.method('global_gaussian2d').
  vector_double('x', [-1,0,1]).
  vector_double('y', [0,0,0]).
  double('height', 1.0).
  vector_double('center', [0.0, 0.0]).
  vector_double('fwhm', [2.0, 1.0]).
  double('pa', pi/4).
  vector_double('return', dir='out');
