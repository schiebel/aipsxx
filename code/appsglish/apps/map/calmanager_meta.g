# calmanager_meta.g: Standard meta information for calibrationmanager
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
#   $Id: calmanager_meta.g,v 19.1 2004/08/25 01:23:16 cvsmgr Exp $
#

pragma include once;

include 'types.g';

types.class('calibrationmanager').
    includefile('calmanager.g');

# Constructors
types.method('ctor_calibrationmanager');

# Methods
types.method('general').
    float('t',0.0).
    table('table','',options='Calibration').
    taql('select','',options='Calibration').
    calibration('return', 'mycalibration', dir='inout');

types.method('vp').
    boolean('usedefaultvp', T).
    string('vptable', '').
    boolean('dosquint', T).
    quantity('parangleinc', '360deg').
    calibration('return', 'mycalibration', dir='inout');


