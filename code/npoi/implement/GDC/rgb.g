# rgb.g is part of the GDC server
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
# Correspondence concerning the GDC server should be addressed as follows:
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
# $Id: rgb.g,v 19.0 2003/07/16 06:03:22 aips2adm Exp $
# ------------------------------------------------------------------------------

# rgb.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains a glish function for converting from PGPLOT color indices
# to X color representations.

# glish function:
# ---------------
# ci2x.

# Modification history:
# ---------------------
# 2000 Apr 10 - Nicholas Elias, USNO/NPOI
#               File created with glish function ci2x{ }.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'convert.g' ) {
  throw( 'Cannot include convert.g ...', origin = 'rgb.g' );
}

# ------------------------------------------------------------------------------

# ci2x

# Description:
# ------------
# This glish function converts the color indices in a pgplot( ) agent to their
# X color representations.

# Inputs:
# -------
# pgplot_agent - The pgplot( ) agent.
# back         - Boolean to include background color in list; default = F;
# flag         - Boolean to include flag color (red) in list; default = F.
# interp       - Boolean to include interpolation color (green) in list;
#                default = F.

# Outputs:
# --------
# The glish record containing:
# number - The number of colors.
# ci     - The PGPLOT color indices.
# rgb    - The X color representations.

# Modification history:
# ---------------------
# 2000 Apr 10 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const ci2x := function( pgplot_agent, back = F, flag = F, interp = F ) {

  # Check the inputs

  if ( is_fail( pgplot_agent->height() ) ) {
    fail '%% ci2x: Input must be pgplot( ) agent ...';
  }
  
  if ( !is_boolean( back ) ) {
    fail '%% ci2x: Invalid background boolean ...';
  }
  
  if ( !is_boolean( flag ) ) {
    fail '%% ci2x: Invalid flag boolean ...';
  }
  
  if ( !is_boolean( interp ) ) {
    fail '%% ci2x: Invalid interpolation boolean ...';
  }
  
  
  # Create the glish record containing the PGPLOT color indices and X color
  # representations

  c2 := 0;
  for ( c in 0:pgplot_agent->qcol()[2] ) {
    if ( c == 0 && !back ) continue;
    if ( c == 2 && !flag ) continue;
    if ( c == 3 && !interp ) continue;
    c2 +:= 1;
    rgbInt := as_integer( 255 * pgplot_agent->qcr( c ) );
    for ( i in 1:3 ) {
      numSixteen := as_integer( rgbInt[i] / 16.0 );
      numOne := rgbInt[i] - 16*numSixteen;
      hex[i] := spaste( as_hexdigit( numSixteen ), as_hexdigit( numOne ) );
    }
    rgb[c2] := spaste( '#', hex[1], hex[2], hex[3] );
    ci[c2] := c;
  }
  
  
  # Eliminate redundant X color representations and sort according to PGPLOT
  # color index

  o := order( rgb );
  rgb := rgb[o];
  ci := ci[o];

  uo := unique_order( rgb );
  rgb := rgb[uo];
  ci := ci[uo];

  o := order( ci );
  rgb := rgb[o];
  ci := ci[o];

  record.number := length( ci );
  record.ci := ci;
  record.rgb := rgb;
  
  
  # Return the glish record

  return( record );

}
