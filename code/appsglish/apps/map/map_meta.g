# map_meta.g: Standard meta information for map
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
#   $Id: map_meta.g,v 19.1 2004/08/25 01:25:16 cvsmgr Exp $
#

pragma include once;

include 'types.g';

types.class('map').
    includefile('map.g');

# Constructors
types.method('ctor_map').
   ms('msfile');

# Methods
types.method('solvecal').
   modellist('sourcemodels').
   selection('selection').
   calibrationlist('calibration').
   solverlist('solvers');

types.method('applycal').
  selection('selection').
  calibrationlist('calibration');

types.method('makemap').
  selection('selection').
  calibrationlist('calibration').
  transform('ftmachine').
  imagingfieldlist('imagingfields').
  table('complist').
  imagingweight('weighting').
  deconvolution('deconvolver').
  restoringbeam('restoringbeam');

types.method('view').
  string('modelentry', '').
  choice('type', 'restored', options=['model','mask','restored','residual']);

# Contained methods from calibrater and imager below this point.
# These meta data need to track changes in imager_meta.g and
# calibrater_meta.g accordingly.

# Contained method: imager.plotuv()
types.method('plotuv').
  boolean('rotate', F);

# Contained method: imager.plotvis()
types.method('plotvis').
  choice('type', 'all',
     options=['all', 'observed', 'model', 'corrected', 'residual']).
  integer('increment', 1);

# Contained method: imager.plotweights()
types.method('plotweights').
  boolean('gridded', F).
  integer('increment', 1);

# Contained method: imager.summary()
types.method('summary');

# Contained method: imager.sensitivity()
types.method('sensitivity').
  quantity('pointsource', '0.0Jy', dir='out').
  float('relative', 0.0, dir='out').
  float('sumweights', 0.0, dir='out');

# Contained method: calibrater.plotcal()
types.method('plotcal').
  choice('plottype', 'AMP', options=['AMP', 'PHASE', 'RI', 'DAMP', 'DPHASE',
                                     'DRI', 'FIT', 'FITWGT', 'TOTALFIT']).
  table('tablename', '', options='Calibration').
  vector_integer('antennas', []).
  integer('polarization', 1).
  vector_integer('spwids', []).
  integer('timeslot', 1);
