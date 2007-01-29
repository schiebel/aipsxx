# __scaninfo_private.g is part of the Cuttlefish server
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
# $Id: __scaninfo_private.g,v 19.0 2003/07/16 06:02:23 aips2adm Exp $
# ------------------------------------------------------------------------------

# __scaninfo_private.g

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
# for scaninfo{ } tools.  NB: These functions should be called only by
# scaninfo{ } tools.

# glish function:
# ---------------
# __scaninfo_private.

# Modification history:
# ---------------------
# 2000 Aug 15 - Nicholas Elias, USNO/NPOI
#               File created with glish function __scaninfo_private( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __scaninfo_private

# Description:
# ------------
# This glish function creates private member functions for a scaninfo{ } tool.

# Inputs:
# -------
# private - The private variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2000 Aug 15 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __scaninfo_private := function( ref private ) {
  
  # Define the 'checkscan' private member function

  val private.checkScanRec :=
      [_method = 'checkScan', _sequence = private.id._sequence];
   
  const val private.checkscan := function( ref startscan, ref stopscan ) {
    wider private;
    if ( is_numeric( startscan ) ) {
      scannum := length( startscan );
      if ( scannum == 1 ) {
        startscanTemp := startscan;
      } else if ( scannum == 0 ) {
        startscanTemp := 1;
      } else {
        return( F );
      }
    } else {
      return( F );
    }
    if ( is_numeric( stopscan ) ) {
      scannum := length( stopscan );
      if ( scannum == 1 ) {
        stopscanTemp := stopscan;
      } else if ( scannum == 0 ) {
        stopscanTemp := private.numscan();
      } else {
        return( F );
      }
    } else {
      return( F );
    }
    val private.checkScanRec.startscan := startscanTemp;
    val private.checkScanRec.stopscan := stopscanTemp;
    scanList := defaultservers.run( private.agent, private.checkScanRec );
    check := as_boolean( scanList[1] );
    if ( check ) {
      val startscan := scanList[2];
      val stopscan := scanList[3];
    }
    return( check );
  }
  
  
  # Define the 'checkstarid' private member function

  val private.checkStarIDRec :=
      [_method = 'checkStarID', _sequence = private.id._sequence];
  
  const val private.checkstarid := function( ref starid ) {
    wider private;
    val private.checkStarIDRec.starid := split( starid );
    starIDList := defaultservers.run( private.agent, private.checkStarIDRec );
    check := as_boolean( starIDList[1] );
    if ( check ) {
      val starid := starIDList[2:length(starIDList)];
    }
    return( check );
  }
  
  
  # Define the 'getstarid' private member function

  val private.getstaridRec :=
      [_method = 'getStarID', _sequence = private.id._sequence];
  
  const val private.getstarid := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.getstaridRec ) );
  }
  
  
  # Define the 'setstarid' private member function

  val private.setstaridRec :=
      [_method = 'setStarID', _sequence = private.id._sequence];
  
  const val private.setstarid := function( starid ) {
    wider private;
    val private.setstaridRec.starid := starid;
    return( defaultservers.run( private.agent, private.setstaridRec ) );
  }
  
  
  # Define the 'setstariddefault' private member function

  val private.setstariddefaultRec :=
      [_method = 'setStarIDDefault', _sequence = private.id._sequence];
  
  const val private.setstariddefault := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.setstariddefaultRec ) );
  }
  
  
  # Define the 'addstarid' private member function

  val private.addstaridRec :=
      [_method = 'addStarID', _sequence = private.id._sequence];
  
  const val private.addstarid := function( starid ) {
    wider private;
    val private.addstaridRec.starid := starid;
    return( defaultservers.run( private.agent, private.addstaridRec ) );
  }
  
  
  # Define the 'removestarid' private member function

  val private.removestaridRec :=
      [_method = 'removeStarID', _sequence = private.id._sequence];
  
  const val private.removestarid := function( starid ) {
    wider private;
    private.removestaridRec.starid := starid;
    return( defaultservers.run( private.agent, private.removestaridRec ) );
  }


  # Return T
  
  return( T );
  
}
