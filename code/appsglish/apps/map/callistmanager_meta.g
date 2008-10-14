# callistmanager_meta.g: Standard meta information for calibrationlistmanager
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
#   $Id: callistmanager_meta.g,v 19.1 2004/08/25 01:23:01 cvsmgr Exp $
#

pragma include once;

include 'types.g';

types.class('calibrationlistmanager').
    includefile('callistmanager.g');

# Constructors
types.method('ctor_calibrationlistmanager');

# Methods
types.method('calibrationlist').
    choice('type1','T',options=['T','G','D','B','VP']).
    calibration('calibration1').
    choice('type2','G',options=['T','G','D','B','VP']).
    calibration('calibration2').
    choice('type3','D',options=['T','G','D','B','VP']).
    calibration('calibration3').
    choice('type4','B',options=['T','G','D','B','VP']).
    calibration('calibration4').
    choice('type5','VP',options=['T','G','D','B','VP']).
    calibration('calibration5').
    calibrationlist('return', 'mycalibrationlist', dir='inout');

