# __ibdata1.g is part of the Cuttlefish server
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
# $Id: __ibdata1.g,v 19.0 2003/07/16 06:02:21 aips2adm Exp $
# ------------------------------------------------------------------------------

# __ibdata1.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++

# Description:
# ------------
# This file contains the glish functions for creating 1D input-beam tools.
# These functions are not typically called directly by the user.

# glish functions:
# ----------------
# __ibdata1_define_members, __ibdata1, __ibdata1_average, __ibdata1_clone,
# __ibdata1_interpolate.

# Modification history:
# ---------------------
# 2001 Mar 27 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __ibdata1_define_members( ),
#               __ibdata1( ), __ibdata1_average( ), ibdata1_clone( ), and
#               __ibdata1_interpolate( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'whenever_manager.g' ) {
  throw( 'Cannot include whenever_manager.g ...', origin = '__ibdata1' );
}

if ( !include 'gdc1token.g' ) {
  throw( 'Cannot include gdc1token.g ...', origin = '__ibdata1' );
}

if ( !include 'hds.g' ) {
  throw( 'Cannot include hds.g ...', origin = '__ibdata1' );
}

if ( !include 'ibconfig.g' ) {
  throw( 'Cannot include ibconfig.g ...', origin = '__ibdata1' );
}

if ( !include 'scaninfo.g' ) {
  throw( 'Cannot include scaninfo.g ...', origin = '__ibdata1' );
}

if ( !include '__ibdata1_guimore.g' ) {
  throw( 'Cannot include __ibdata1_guimore.g ...', origin = '__ibdata1' );
}

if ( !include '__ibdata1_public.g' ) {
  throw( 'Cannot include __ibdata1_public.g ...', origin = '__ibdata1' );
}

# ------------------------------------------------------------------------------

# __define_ibdata1_members

# Description:
# ------------
# This glish function defines the member functions for a 1D input-beam tool.
# This function should not be called directly by users.

# Inputs:
# -------
# agent           - The agent.
# id              - The ID.
# constructor     - The C++ constructor name.
# gconstructor    - The glish constructor name.
# function2init   - The function to initialize.
# averagefunc     - The average function.
# clonefunc       - The clone function.
# interpolatefunc - The interpolation function.
# host            - The host name.
# forcenewserver  - The force-new-server boolean.
# gui             - The GUI variable.
# w               - The whenever handler.
# private         - The private record.

# Outputs:
# --------
# The member functions, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Mar 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __define_ibdata1_members := function( ref agent, id, constructor,
    gconstructor, function2init, averagefunc, clonefunc, interpolatefunc, host,
    forcenewserver, ref gui, ref w, ref private ) {
    
  # Define the member functions

  val public := __define_gdc1token_members( agent, id, gconstructor, host,
      forcenewserver, gui, w, private );

  function2init( gui, private, public );
  private.constructor := constructor;  
  
  __ibdata1_public( gui, private, public );

  __ibdata1_public( gui, private, public );
  __ibdata1_guimore( gui, w, private, public );

  if ( public.derived() ) {
    annotation := '***';
  } else {
    annotation := '';
  }
  val private.window.default := spaste( annotation, public.filetail(),
      annotation, ' ', to_lower( public.object() ), ' ', public.inputbeam() );
  
  val private.averagefunc := averagefunc;
  val private.clonefunc := clonefunc;
  val private.interpolatefunc := interpolatefunc;

  private.guimore_killed();


  # Return the structure containing the public member functions

  return( ref public );

}

# ------------------------------------------------------------------------------

# __ibdata1

# Description
# -----------
# This glish function creates a 1D input-beam tool.  This function is typically
# not called directly by the user.

# Inputs:
# -------
# file            - The file name.
# inputbeam       - The input-beam number.
# constructor     - The C++ constructor name.
# function2init   - The function to initialize.
# averagefunc     - The average function.
# clonefunc       - The clone function.
# interpolatefunc - The interpolation function.
# host            - The host name (default = '').
# forcenewserver  - The force-new-server boolean (default = F).

# Outputs:
# --------
# The 1D input-beam tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Mar 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __ibdata1 := function( file, inputbeam, constructor, function2init,
    averagefunc, clonefunc, interpolatefunc, host = '', forcenewserver = F ) {
  
  # Fix and check the inputs
  
  gconstructor := to_lower( constructor );
  
  if ( !cs( file ) ) {
    return( throw( 'Invalid file name ...', origin = gconstructor ) );
  }
  
  if ( !is_integer( inputbeam ) ) {
    return( throw( 'Invalid input-beam number ...', origin = gconstructor ) );
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host ...', origin = gconstructor ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid force-new-server boolean boolean ...',
        origin = gconstructor ) );
  }
  
  
  # Invoke the C++ constructor member function
  
  agent := defaultservers.activate( 'Cuttlefish', host, forcenewserver );
  args := [file = file, inputbeam = inputbeam];

  if ( is_fail( id := defaultservers.create( agent, constructor,
      to_upper( gconstructor ), args ) ) ) {
    return( throw( spaste( 'Error creating', gconstructor, 'tool ...' ),
        origin = gconstructor ) );
  }
  
  
  # Return the 1D input-beam tool

  gui := F;
  w := F;
  private := F;
  
  public := __define_ibdata1_members( agent, id, constructor, gconstructor,
      function2init, averagefunc, clonefunc, interpolatefunc, host,
      forcenewserver, gui, w, private );
  
  return( ref public );

}

# ------------------------------------------------------------------------------

# __ibdata1_average

# Description:
# ------------
# This glish function creates an averaged 1D input-beam tool.  Typically, this
# is not called directly by the user.

# Inputs:
# -------
# objectid        - The ObjectID record.
# constructor     - The C++ constructor name.
# function2init   - The function to initialize.
# averagefunc     - The average function.
# clonefunc       - The clone function.
# interpolatefunc - The interpolation function.
# x               - The x vector.
# xmin            - The minimum x value.
# xmax            - The maximum x value.
# token           - The tokens.
# keep            - The keep-flagged-data boolean.
# weight          - The weight boolean.
# xcalc           - The recalculate-x boolean.
# interp          - The interpolation method ("CUBIC", "LINEAR", "NEAREST",
#                   "SPLINE").
# host            - The host name (default = '').
# forcenewserver  - The force-new-server boolean (default = F).

# Outputs:
# --------
# The averaged 1D input-beam tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Mar 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __ibdata1_average := function( objectid, constructor, function2init,
    averagefunc, clonefunc, interpolatefunc, x, xmin, xmax, token, keep, weight,
    xcalc, interp, host = '', forcenewserver = F ) {
  
  # Fix and check the inputs

  gconstructor := spaste( to_lower( constructor ), '_average' );
  
  if ( !is_record( objectid ) ) {
    return( throw( 'Invalid ObjectID record ...', origin = gconstructor ) );
  }
  
  if ( !has_field( objectid, 'sequence' ) || !has_field( objectid, 'pid' ) ||
       !has_field( objectid, 'time' ) || !has_field( objectid, 'host' ) ) {
    return( throw( 'Invalid ObjectID record fields(s) ...',
        origin = gconstructor ) );
  }
  
  if ( !is_numeric( x ) ) {
    return( throw( 'Invalid x value(s) ...', origin = gconstructor ) );
  }
  
  if ( !is_numeric( xmin ) ) {
    return( throw( 'Invalid minimum x value ...', origin = gconstructor ) );
  }
  
  if ( !is_numeric( xmax ) ) {
    return( throw( 'Invalid maximum x value ...', origin = gconstructor ) );
  }
  
  if ( !is_string( token ) ) {
    return( throw( 'Invalid token(s) ...', origin = gconstructor ) );
  }
  
  if ( !is_boolean( keep ) ) {
    return( throw( 'Invalid keep-flagged-data boolean ...',
        origin = gconstructor ) );
  }
  
  if ( !is_boolean( weight ) ) {
    return( throw( 'Invalid weight boolean ...', origin = gconstructor ) );
  }

  if ( !is_boolean( xcalc ) ) {
    return( throw( 'Invalid recalculate-x boolean ...',
        origin = gconstructor ) );
  }

  if ( !cs( interp, 0, T ) ) {
    return( throw( 'Invalid interpolation method ...',
        origin = gconstructor ) );
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host ...', origin = gconstructor ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid \'force-new-server\' boolean ...',
        origin = gconstructor ) );
  }
  
  
  # Invoke the C++ constructor member function
  
  agent := defaultservers.activate( 'Cuttlefish', host, forcenewserver );
  args := [objectid = objectid, x = x, xmin = xmin, xmax = xmax, token = token,
      keep = keep, weight = weight, xcalc=xcalc, interp=interp];

  if ( is_fail( id := defaultservers.create( agent, constructor,
      to_upper( gconstructor ), args ) ) ) {
    return( throw( 'Error creating Cuttlefish server ...',
        origin = gconstructor ) );
  }
  
  
  # Return the averaged 1D input-beam tool

  gui := F;
  w := F;
  private := F;
  
  public := __define_ibdata1_members( agent, id, constructor, gconstructor,
      function2init, averagefunc, clonefunc, interpolatefunc, host,
      forcenewserver, gui, w, private );
  
  return( ref public );
  
}

# ------------------------------------------------------------------------------

# __ibdata1_clone

# Description:
# ------------
# This glish function creates a cloned 1D input-beam tool.  Typically, this is
# not called directly by the user.

# Inputs:
# -------
# objectid        - The ObjectID record.
# constructor     - The C++ constructor name.
# function2init   - The function to initialize.
# averagefunc     - The average function.
# clonefunc       - The clone function.
# interpolatefunc - The interpolation function.
# xmin            - The minimum x value.
# xmax            - The maximum x value.
# token           - The tokens.
# keep            - The keep-flagged-data boolean.
# host            - The host name (default = '').
# forcenewserver  - The force-new-server boolean (default = F).

# Outputs:
# --------
# The cloned 1D input-beam tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Mar 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __ibdata1_clone := function( objectid, constructor, function2init,
    averagefunc, clonefunc, interpolatefunc, xmin, xmax, token, keep, host = '',
    forcenewserver = F ) {
  
  # Fix and check the inputs

  gconstructor := spaste( to_lower( constructor ), '_clone' );
  
  if ( !is_record( objectid ) ) {
    return( throw( 'Invalid ObjectID record ...', origin = gconstructor ) );
  }
  
  if ( !has_field( objectid, 'sequence' ) || !has_field( objectid, 'pid' ) ||
       !has_field( objectid, 'time' ) || !has_field( objectid, 'host' ) ) {
    return( throw( 'Invalid ObjectID record fields(s) ...',
        origin = gconstructor ) );
  }
  
  if ( !is_numeric( xmin ) ) {
    return( throw( 'Invalid minimum x value ...', origin = gconstructor ) );
  }
  
  if ( !is_numeric( xmax ) ) {
    return( throw( 'Invalid maximum x value ...', origin = gconstructor ) );
  }
  
  if ( !is_string( token ) ) {
    return( throw( 'Invalid token(s) ...', origin = gconstructor ) );
  }
  
  if ( !is_boolean( keep ) ) {
    return( throw( 'Invalid keep-flagged-data boolean ...',
        origin = gconstructor ) );
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host ...', origin = gconstructor ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid force-new-server boolean boolean ...',
        origin = gconstructor ) );
  }
  
  
  # Invoke the C++ constructor member function
  
  agent := defaultservers.activate( 'Cuttlefish', host, forcenewserver );
  args := [objectid = objectid, xmin = xmin, xmax = xmax, token = token,
      keep = keep];

  if ( is_fail( id := defaultservers.create( agent, constructor,
      to_upper( gconstructor ), args ) ) ) {
    return( throw( 'Error creating Cuttlefish server ...',
        origin = gconstructor ) );
  }
  
  
  # Return the cloned 1D input-beam tool

  gui := F;
  w := F;
  private := F;
  
  public := __define_ibdata1_members( agent, id, constructor, gconstructor,
      function2init, averagefunc, clonefunc, interpolatefunc, host,
      forcenewserver, gui, w, private );
  
  return( ref public );
  
}

# ------------------------------------------------------------------------------

# __ibdata1_interpolate

# Description:
# ------------
# This glish function creates an interpolated 1D input-beam tool.  Typically,
# this is not called directly by the user.

# Inputs:
# -------
# objectid        - The ObjectID record.
# constructor     - The C++ constructor name.
# function2init   - The function to initialize.
# averagefunc     - The average function.
# clonefunc       - The clone function.
# interpolatefunc - The interpolation function.
# x               - The x vector.
# token           - The tokens.
# keep            - The keep-flagged-data boolean.
# interp          - The interpolation method ("CUBIC", "LINEAR", "NEAREST",
#                   "SPLINE").
# xminbox         - The minimum x-box value.
# xmaxbox         - The maximum x-box value.
# host            - The host name (default = '').
# forcenewserver  - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The interpolated 1D input-beam tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Mar 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __ibdata1_interpolate := function( objectid, constructor, function2init,
    averagefunc, clonefunc, interpolatefunc, x, token, keep, interp, xminbox,
    xmaxbox, host = '', forcenewserver = F ) {
  
  # Fix and check the inputs

  gconstructor := spaste( to_lower( constructor ), '_interpolate' );
  
  if ( !is_record( objectid ) ) {
    return( throw( 'Invalid ObjectID record ...', origin = gconstructor ) );
  }
  
  if ( !has_field( objectid, 'sequence' ) || !has_field( objectid, 'pid' ) ||
       !has_field( objectid, 'time' ) || !has_field( objectid, 'host' ) ) {
    return( throw( 'Invalid ObjectID record fields(s) ...',
        origin = gconstructor ) );
  }
  
  if ( !is_numeric( x ) ) {
    return( throw( 'Invalid x value(s) ...', origin = gconstructor ) );
  }
  
  if ( !is_string( token ) ) {
    return( throw( 'Invalid token(s) ...', origin = gconstructor ) );
  }
  
  if ( !is_boolean( keep ) ) {
    return( throw( 'Invalid keep-flagged-data boolean ...',
        origin = gconstructor ) );
  }
  
  if ( !cs( interp, 0, T ) ) {
    return( throw( 'Invalid interpolation method ...', origin = gconstructor ) );
  }
  
  if ( !is_numeric( xminbox ) ) {
    return( throw( 'Invalid minimum x-box value ...', origin = gconstructor ) );
  }
  
  if ( !is_numeric( xmaxbox ) ) {
    return( throw( 'Invalid maximum x-box value ...', origin = gconstructor ) );
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host ...', origin = gconstructor ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid \'force-new-server\' boolean boolean ...',
        origin = gconstructor ) );
  }
  
  
  # Invoke the C++ constructor member function
  
  agent := defaultservers.activate( 'Cuttlefish', host, forcenewserver );
  args := [objectid = objectid, x = x, token = token, keep = keep,
      interp = interp, xminbox = xminbox, xmaxbox = xmaxbox];

  if ( is_fail( id := defaultservers.create( agent, constructor,
      to_upper( gconstructor ), args ) ) ) {
    return( throw( 'Error creating Cuttlefish server ...',
        origin = gconstructor ) );
  }
  
  
  # Return the interpolated 1D input-beam tool

  gui := F;
  w := F;
  private := F;
  
  public := __define_ibdata1_members( agent, id, constructor, gconstructor,
      function2init, averagefunc, clonefunc, interpolatefunc, host,
      forcenewserver, gui, w, private );
  
  return( ref public );
  
}
