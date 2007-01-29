# delayjitter.g is part of the Cuttlefish server
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
# $Id: delayjitter.g,v 19.0 2003/07/16 06:02:50 aips2adm Exp $
# ------------------------------------------------------------------------------

# delayjitter.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++

# Description:
# ------------
# This file contains the glish function for creating delay-jitter tools.

# glish functions:
# ----------------
# delayjitter.

# Modification history:
# ---------------------
# 2001 May 11 - Nicholas Elias, USNO/NPOI
#               File created with glish function delayjitter( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include '__obdata1.g' ) {
  throw( 'Cannot include __obdata1.g ...', origin = 'delayjitter' );
}

if ( !include '__delayjitter_public.g' ) {
  throw( 'Cannot include __delayjitter_public.g ...', origin = 'delayjitter' );
}

# ------------------------------------------------------------------------------

# delayjitter

# Description
# -----------
# This glish function creates a delay-jitter tool.

# Inputs:
# -------
# file           - The file name.
# inputbeam      - The input-beam number.
# baseline       - The baseline number.
# host           - The host name (default = '').
# forcenewserver - The force-new-server boolean (default = F).

# Outputs:
# --------
# The delay-jitter tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 May 11 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const delayjitter := function( file, inputbeam, baseline, host = '',
    forcenewserver = F ) {
  
  return( __obdata1( file, inputbeam, baseline, 'DelayJitter',
      __delayjitter_public, delayjitter_average, delayjitter_clone,
      delayjitter_interpolate, host, forcenewserver ) );

}

# ------------------------------------------------------------------------------

# delayjitter_average

# Description
# -----------
# This glish function creates an averaged delay-jitter tool.  This function is
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
# The averaged delay-jitter tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 May 11 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const delayjitter_average := function( objectid, x, xmin, xmax, token, keep,
    weight, xcalc, interp, host = '', forcenewserver = F ) {
  
  return( __obdata1_average( objectid, 'DelayJitter', __delayjitter_public,
      delayjitter_average, delayjitter_clone, delayjitter_interpolate, x, xmin,
      xmax, token, keep, weight, xcalc, interp, host = '',
      forcenewserver = F ) );

}

# ------------------------------------------------------------------------------

# delayjitter_clone

# Description
# -----------
# This glish function creates a cloned delay-jitter tool.  This function is
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
# The cloned delay-jitter tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 May 11 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const delayjitter_clone := function( objectid, xmin, xmax, token, keep,
    host = '', forcenewserver = F ) {
  
  return( __obdata1_clone( objectid, 'DelayJitter', __delayjitter_public,
      delayjitter_average, delayjitter_clone, delayjitter_interpolate, xmin,
      xmax, token, keep, host, forcenewserver ) );

}

# ------------------------------------------------------------------------------

# delayjitter_interpolate

# Description
# -----------
# This glish function creates an interpolated delay-jitter tool.  This function
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
# The interpolated delay-jitter tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 May 11 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const delayjitter_interpolate := function( objectid, x, token, keep, interp,
    xminbox, xmaxbox, host = '', forcenewserver = F ) {
  
  return( __obdata1_interpolate( objectid, 'DelayJitter', __delayjitter_public,
      delayjitter_average, delayjitter_clone, delayjitter_interpolate, x, token,
      keep, interp, xminbox, xmaxbox, host = '', forcenewserver = F ) );

}
