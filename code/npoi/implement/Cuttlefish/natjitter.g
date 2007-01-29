# natjitter.g is part of the Cuttlefish server
# Copyright (C) 2001
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
# $Id: natjitter.g,v 19.0 2003/07/16 06:02:41 aips2adm Exp $
# ------------------------------------------------------------------------------

# natjitter.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++

# Description:
# ------------
# This file contains the glish function for creating NAT-jitter tools.

# glish functions:
# ----------------
# natjitter.

# Modification history:
# ---------------------
# 2001 Mar 27 - Nicholas Elias, USNO/NPOI
#               File created with glish function natjitter( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include '__ibdata1.g' ) {
  throw( 'Cannot include __ibdata1.g ...', origin = 'natjitter' );
}

if ( !include '__natjitter_public.g' ) {
  throw( 'Cannot include __natjitter_public.g ...', origin = 'natjitter' );
}

# ------------------------------------------------------------------------------

# natjitter

# Description
# -----------
# This glish function creates a NAT-jitter tool.

# Inputs:
# -------
# file           - The file name.
# inputbeam      - The input-beam number.
# host           - The host name (default = '').
# forcenewserver - The force-new-server boolean (default = F).

# Outputs:
# --------
# The NAT-jitter tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Mar 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const natjitter := function( file, inputbeam, host = '', forcenewserver = F ) {
  
  return( __ibdata1( file, inputbeam, 'NATJitter', __natjitter_public,
      natjitter_average, natjitter_clone, natjitter_interpolate, host,
      forcenewserver ) );

}

# ------------------------------------------------------------------------------

# natjitter_average

# Description
# -----------
# This glish function creates an averaged NAT-jitter tool.  This function is
# typically not called by the user directly.

# Inputs:
# -------
# objectid       - The ObjectID record.
# x              - The x vector.
# xmin           - The minimum x value.
# xmax           - The maximum x value.
# token          - The tokens.
# keep           - The keep-flagged-data boolean.
# weight         - The weight boolean.
# xcalc          - The recalculate-x boolean.
# interp         - The interpolation method ("CUBIC", "LINEAR", "NEAREST",
#                  "SPLINE").
# host           - The host name (default = '').
# forcenewserver - The force-new-server boolean (default = F).

# Outputs:
# --------
# The averaged NAT-jitter tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Mar 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const natjitter_average := function( objectid, x, xmin, xmax, token, keep, weight,
    xcalc, interp, host = '', forcenewserver = F ) {
  
  return( __ibdata1_average( objectid, 'NATJitter', __natjitter_public,
      natjitter_average, natjitter_clone, natjitter_interpolate, x, xmin, xmax,
      token, keep, weight, xcalc, interp, host = '', forcenewserver = F ) );

}

# ------------------------------------------------------------------------------

# natjitter_clone

# Description
# -----------
# This glish function creates a cloned NAT-jitter tool.  This function is
# typically not called by the user directly.

# Inputs:
# -------
# objectid       - The ObjectID record.
# xmin           - The minimum x value.
# xmax           - The maximum x value.
# token          - The tokens.
# keep           - The keep-flagged-data boolean.
# host           - The host name (default = '').
# forcenewserver - The force-new-server boolean (default = F).

# Outputs:
# --------
# The cloned NAT-jitter tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Mar 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const natjitter_clone := function( objectid, xmin, xmax, token, keep, host = '',
    forcenewserver = F ) {
  
  return( __ibdata1_clone( objectid, 'NATJitter', __natjitter_public,
      natjitter_average, natjitter_clone, natjitter_interpolate, xmin, xmax,
      token, keep, host, forcenewserver ) );

}

# ------------------------------------------------------------------------------

# natjitter_interpolate

# Description
# -----------
# This glish function creates an interpolated NAT-jitter tool.  This function
# is typically not called by the user directly.

# Inputs:
# -------
# objectid       - The ObjectID record.
# x              - The x vector.
# token          - The tokens.
# keep           - The keep-flagged-data boolean.
# interp         - The interpolation method ("CUBIC", "LINEAR", "NEAREST",
#                  "SPLINE").
# xminbox        - The minimum x-box value.
# xmaxbox        - The maximum x-box value.
# host           - The host name (default = '').
# forcenewserver - The force-new-server boolean (default = F).

# Outputs:
# --------
# The interpolated NAT-jitter tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Mar 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const natjitter_interpolate := function( objectid, x, token, keep, interp, xminbox,
    xmaxbox, host = '', forcenewserver = F ) {
  
  return( __ibdata1_interpolate( objectid, 'NATJitter', __natjitter_public,
      natjitter_average, natjitter_clone, natjitter_interpolate, x, token, keep,
      interp, xminbox, xmaxbox, host = '', forcenewserver = F ) );

}
