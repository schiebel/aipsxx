# __obconfig_private.g is part of the Cuttlefish server
# Copyright (C) 2000,2001
# United States Naval Observatory; Washington, DC; USA.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This library is designed for use only in AIPS++ (National Radio Astronomy
# Observatory; Charlottesville, VA; USA) in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation,
# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
# Correspondence concerning the Cuttlefish server should be addressed as follows:
#        Internet email: nme@nofs.navy.mil
#        Postal address: Dr. Nicholas Elias
#                        United States Naval Observatory
#                        Navy Prototype Optical Interferometer
#                        P.O. Box 1149
#                        Flagstaff, AZ 86002-1149 USA
#
# Correspondence concerning AIPS++ should be addressed as follows:
#        Internet email: aips2-request@nrao.edu.
#        Postal address: AIPS++ Project Office
#                        National Radio Astronomy Observatory
#                        520 Edgemont Road
#                        Charlottesville, VA 22903-2475 USA
#
# $Id: __obconfig_private.g,v 19.0 2003/07/16 06:02:31 aips2adm Exp $
# ------------------------------------------------------------------------------

# __obconfig_private.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions that define private member functions
# for obconfig{ } tools.  NB: These functions should be called only by
# obconfig{ } tools.

# glish function:
# ---------------
# __obconfig_private.

# Modification history:
# ---------------------
# 2001 Jan 18 - Nicholas Elias, USNO/NPOI
#               File created with glish function __obconfig_private( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __obconfig_private

# Description:
# ------------
# This glish function creates private member functions for an obconfig{ } tool.

# Inputs:
# -------
# private - The private variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2001 Jan 18 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __obconfig_private := function( ref private ) {

  # Define the 'checkoutbeam' private member function

  val private.checkOutBeamRec :=
      [_method = 'checkOutBeam', _sequence = private.id._sequence];
 
  const val private.checkoutbeam := function( outbeam ) {
    wider private;
    val private.checkOutBeamRec.outbeam := outbeam;
    return( defaultservers.run( private.agent, private.checkOutBeamRec ) );
  }


  # Define the 'checkbaseline' private member function

  val private.checkBaselineRec :=
      [_method = 'checkBaseline', _sequence = private.id._sequence];
 
  const val private.checkbaseline := function( outbeam, baseline ) {
    wider private;
    val private.checkBaselineRec.outbeam := outbeam;
    val private.checkBaselineRec.baseline := baseline;
    return( defaultservers.run( private.agent, private.checkBaselineRec ) );
  }


  # Return T
  
  return( T );
  
}
