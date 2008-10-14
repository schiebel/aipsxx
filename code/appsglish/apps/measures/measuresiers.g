# measuresiers.g: Create/update all IERS tables
# Copyright (C) 1996,1997,2000,2003
# Associated Universities, Inc. Washington DC, USA.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: measuresiers.g,v 19.2 2004/08/25 01:30:02 cvsmgr Exp $
#
pragma include once
# Include helper functions
#
  include 'measuresdata.g'
#
# Get leap seconds
#
TAI_UTC();
#
# Get IERS solution
#
IERSeop97();
#
# Get NEOS predictions
#
IERSpredict();
#
# Get IERS solution IAU2000
#
IERSeop2000();
#
# Get NEOS predictions IAU2000
#
IERSpredict2000();
#
# Get JPL DE200 table
#
JPLDE(200, 1960);
#
# Get JPL DE405 table
#
JPLDE(405, 1960);
#
# Ready
#
exit;
