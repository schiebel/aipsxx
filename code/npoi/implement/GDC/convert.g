# convert.g is part of the GDC server
# Copyright (C) 2000
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
# Correspondence concerning GDC should be addressed as follows:
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
# $Id: convert.g,v 19.0 2003/07/16 06:03:20 aips2adm Exp $
# ------------------------------------------------------------------------------

# convert.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains assorted glish conversion functions.

# glish functions:
# ----------------
# as_hexdigit, capfirst, d2dms, h2hms, ms2hms, s2hms, unique_order.

# Modification history:
# ---------------------
# 2000 Apr 10 - Nicholas Elias, USNO/NPOI
#               File created with glish functions as_hexdigit{ } and
#               unique_order{ }.
# 2000 Apr 13 - Nicholas Elias, USNO/NPOI
#               Glish function capfirst{ } added.
# 2000 Aug 22 - Nicholas Elias, USNO/NPOI
#               Glish functions d2dms{ }, h2hms{ }, ms2hms{ }, s2hms{ } added.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# as_hexdigit

# Description:
# ------------
# This function converts a number between 0 and 15 (inclusive) to a hex digit.

# Inputs:
# -------
# x - A number between 0 and 15, inclusive.

# Outputs:
# --------
# The hex digit (string).

# Modification history:
# ---------------------
# 2000 Apr 10 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const as_hexdigit := function( x ) {

  # Check the input

  if ( !is_numeric( x ) || is_boolean( x ) ) {
    fail '%% as_hexdigit: Input not numeric ...';
  }

  if ( x < 0 || x > 15 ) {
    fail '%% as_hexdigit: Out of range for single hex digit ...';
  }
  
  
  # Convert from decimal to hex and return

  if ( x == 10 ) {
    return( 'A' );
  } else if ( x == 11 ) {
    return( 'B' );
  } else if ( x == 12 ) {
    return( 'C' );
  } else if ( x == 13 ) {
    return( 'D' );
  } else if ( x == 14 ) {
    return( 'E' );
  } else if ( x == 15 ) {
    return( 'F' );
  } else {
    return( as_string( x ) );
  }

}

# ------------------------------------------------------------------------------

# capfirst

# Description:
# ------------
# This function capitalizes the first letter of a string.

# Inputs:
# -------
# x - The string.

# Outputs:
# --------
# The string with the first letter capitalized.

# Modification history:
# ---------------------
# 2000 Apr 13 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const capfirst := function( x ) {

  # Check the input

  if ( !is_string( x ) ) {
    fail '%% capfirst: Input not a string ...';
  }
  
  
  # Capitalize the first letter and return
  
  xsplit := split( x, '' );
  
  return( spaste( to_upper( xsplit[1] ), xsplit[2:length(xsplit)] ) );

}

# ------------------------------------------------------------------------------

# unique_order

# Description:
# ------------
# This function finds the unique elements in a one-dimensional array, sorts
# them in ascending order, and returns their original indices.

# Inputs:
# -------
# x - The one-dimensional array.

# Outputs:
# --------
# The one-dimensional array of indices.

# Modification history:
# ---------------------
# 2000 Apr 10 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const unique_order := function( x ) {

  # Find the unique elements, sort them, and return their original indices

  xu := unique( x );

  i3 := 0;
  xuo := F;

  for ( i1 in 1:length(xu) ) {
    for ( i2 in 1:length(x) ) {
      if ( xu[i1] == x[i2] ) {
        i3 +:= 1;
        xuo[i3] := i2;
        break;
      }
    }
  }

  return( xuo );

}

# ------------------------------------------------------------------------------

# s2hms

# Description:
# ------------
# This function converts times in decimal seconds to strings in HH:MM:SS.SSSS
# format.

# Inputs:
# -------
# seconds - The time(s) in decimal seconds.

# Outputs:
# --------
# The string(s) in HH:MM:SS.SSSS format.

# Modification history:
# ---------------------
# 2000 Aug 22 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const s2hms := function( seconds ) {

  # Form and return the string(s) in HH:MM:SS.SSSS format
  
  dec_hours := seconds / 3600.0;
  int_hours := as_integer( dec_hours );
  
  dec_minutes := 60 * ( dec_hours - int_hours );
  int_minutes := as_integer( dec_minutes );
  
  dec_seconds := 60 * ( dec_minutes - int_minutes );
  
  return( sprintf( "%2dh %2dm %7.4fs", dec_hours, dec_minutes, dec_seconds ) );

}

# ------------------------------------------------------------------------------

# ms2hms

# Description:
# ------------
# This function converts times in decimal milliseconds to strings in
# HH:MM:SS.SSSS format.

# Inputs:
# -------
# milliseconds - The time(s) in milliseconds.

# Outputs:
# --------
# The string(s) in HH:MM:SS.SSSS format.

# Modification history:
# ---------------------
# 2000 Aug 22 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const ms2hms := function( milliseconds ) {

  return( s2hms( milliseconds / 1000.0 ) );

}

# ------------------------------------------------------------------------------

# h2hms

# Description:
# ------------
# This function converts times and right ascensions in decimal hours to strings
# in HH:MM:SS.SSSS format.

# Inputs:
# -------
# hours - The time(s) or right ascension(s) in decimal hours.

# Outputs:
# --------
# The string(s) in HH:MM:SS.SSSS format.

# Modification history:
# ---------------------
# 2000 Aug 22 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const h2hms := function( hours ) {

  return( s2hms( 3600.0 * hours ) );

}

# ------------------------------------------------------------------------------

# d2dms

# Description:
# ------------
# This function converts angles in decimal degrees to strings in DD:MM:SS.SSSS
# format.

# Inputs:
# -------
# degrees - The angle(s) in decimal degrees.

# Outputs:
# --------
# The string(s) in DD:MM:SS.SSSS format.

# Modification history:
# ---------------------
# 2000 Aug 22 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const d2dms := function( degrees ) {

  # Form and return the string(s) in DD:MM:SS.SSSS format
  
  int_degrees := as_integer( degrees );
  
  dec_minutes := 60 * abs( degrees - int_degrees );
  int_minutes := as_integer( dec_minutes );
  
  dec_seconds := 60 * ( dec_minutes - int_minutes );
  
  return( sprintf( "%+3dd %2d' %7.4f\"", degrees, dec_minutes, dec_seconds ) );

}
