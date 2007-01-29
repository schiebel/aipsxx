# check.g is part of Cuttlefish (NPOI data reduction package)
# Copyright (C) 1999,2000,2001
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
# Correspondence concerning Cuttlefish should be addressed as follows:
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
# $Id: check.g,v 19.0 2003/07/16 06:03:12 aips2adm Exp $
# ------------------------------------------------------------------------------

# check.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for checking glish variables.

# glish functions:
# ----------------
# cds, c2ds, cis, civ, cs, cunits, is_real.

# Modification history:
# ---------------------
# 1999 Mar 18 - Nicholas Elias, USNO/NPOI
#               File created with glish functions cds( ), c2ds( ), cis( ),
#               civ( ), and cs( ).
# 1999 May 07 - Nicholas Elias, USNO/NPOI
#               Glish function cunits( ) added.
# 2000 Feb 02 - Nicholas Elias, USNO/NPOI
#               Glish function is_real( ) added.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# cds

# Description:
# ------------
# This glish function checks for a valid double scalar.

# Inputs:
# -------
# doublescalar - The (hopefully) double scalar.
# min          - The minimum value of the double scalar (default = 0).

# Outputs:
# --------
# The double scalar boolean flag, returned via the function value.

# Modification history:
# ---------------------
# 1999 Mar 18 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------
 
const cds := function( doublescalar, min = 0 ) {

  # Check the inputs

  if ( length( doublescalar ) != 1 ) {
    return F;
  }

  if ( !is_numeric( doublescalar ) ) {
    return F;
  }

  if ( doublescalar < min ) {
    return F;
  }


  # Return T

  return T;

}

# ------------------------------------------------------------------------------

const c2ds := function( doublescalar1, doublescalar2, min = 0 ) {

  if ( !is_numeric( doublescalar1 ) && !is_numeric( doublescalar2 ) ) {
    return T;
  }

  if ( ( !is_numeric( doublescalar1 ) &&  is_numeric( doublescalar2 ) ) ||
       (  is_numeric( doublescalar1 ) && !is_numeric( doublescalar2 ) ) ) {
    return F;
  }

  if ( !cds( doublescalar1 ) ) {
    return F;
  }

  if ( !cds( doublescalar2 ) ) {
    return F;
  }

  if ( !cds( doublescalar2, doublescalar1 ) ) {
    return F;
  }


  # Return T

  return T;

}

# ------------------------------------------------------------------------------

const cis := function( intscalar, min = 1 ) {

  # Check the inputs

  if ( length( intscalar ) != 1 ) {
    return F;
  }

  if ( !is_integer( intscalar ) ) {
    return F;
  }

  if ( intscalar < min ) {
    return F;
  }


  # Return T

  return T;

}

# ------------------------------------------------------------------------------

const civ := function( intvector ) {

  # Check the inputs

  if ( length( intvector ) > 7 ) {
    return F;
  }

  if ( !is_integer( intvector ) ) {
    return F;
  }

  if ( length( intvector ) > 1 ) {
    for ( i in length( intvector ) ) {
      if ( intvector[i] < 1 ) {
        return F;
      }
    }
  } else {
    if ( intvector < 0 ) {
      return F;
    }
  }


  # Return T

  return T;

}

# ------------------------------------------------------------------------------

const cs := function( ref string, length_max = 0, cap = F ) {

  # Check the inputs

  if ( !is_string( string ) ) {
    return F;
  }

  if ( !is_integer( length_max ) ) {
    return F;
  }

  if ( length_max > 0 && strlen( string ) > length_max ) {
    return F;
  }

  if ( !is_boolean( cap ) ) {
    return F;
  }


  # Fix the string

  val string := spaste( split( string ) );

  if ( cap ) {
    val string := to_upper( string );
  }


  # Return T

  return T;

}

# ------------------------------------------------------------------------------

const cunits := function( ref units ) {

  # Initialize the authorized units list

  const unitslist := "MS S M H";


  # Check the inputs

  if ( !cs( units, cap = T ) ) {
    return F;
  }
  
  
  # Determine if the units are valid
  
  if ( units == '' ) {
    return T;
  }
  
  flag := F;
  
  for ( u in 1:length( unitslist ) ) {
    if ( units == unitslist[u] ) {
      flag := T;
      break;
    }
  }
  
  
  # Return the units flag
  
  return( flag );

}

# ------------------------------------------------------------------------------

# is_real

# Description:
# ------------
# This glish function checks to see if a variable is real (non-complex,
# non-boolean).

# Inputs:
# -------
# var - The variable.

# Outputs:
# --------
# A boolean flag, returned via the function value.

# Modification history:
# ---------------------
# 2000 Feb 02 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------
 
const is_real := function( var ) {

  # Check if the variable is real and return the flag

  if ( is_complex( var ) || is_dcomplex( var ) || is_boolean( var ) ||
      !is_numeric( var ) ) {
    return( F );
  } else {
    return( T );
  }

}
