# __loginfo_private.g is part of the Cuttlefish server
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
# $Id: __loginfo_private.g,v 19.0 2003/07/16 06:02:29 aips2adm Exp $
# ------------------------------------------------------------------------------

# __loginfo_private.g

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
# for loginfo{ } tools.  NB: These functions should be called only by
# loginfo{ } tools.

# glish function:
# ---------------
# __loginfo_private.

# Modification history:
# ---------------------
# 2001 Jan 26 - Nicholas Elias, USNO/NPOI
#               File created with glish function __loginfo_private( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __loginfo_private

# Description:
# ------------
# This glish function creates private member functions for a loginfo{ } tool.

# Inputs:
# -------
# private - The private variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2001 Jan 26 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __loginfo_private := function( ref private ) {

  # Define the 'nexttmpfile' private member function
 
  const val private.nexttmpfile := function( ) {
    listtmp := shell( 'ls /tmp' );
    if ( length( listtmp ) == 0 ) {
      return( '/tmp/log000.ascii' );
    } else if ( !any( listtmp ~ m/^log[0-9]+\.ascii$/ ) ) {
      return( '/tmp/log000.ascii' );
    } else {
      listtmp := split( sort( shell( 'ls /tmp/log*.ascii' ) ) );
      arg := ( listtmp[length(listtmp)] ~ s/^\/tmp\/log// ) ~ s/\.ascii$//;
      number := as_integer( arg ) + 1;
      if ( number > 999 ) {
        number := 0;
      }
      return( spaste( '/tmp/log', sprintf( '%03d', number ), '.ascii' ) );
    }
  }


  # Return T
  
  return( T );
  
}
