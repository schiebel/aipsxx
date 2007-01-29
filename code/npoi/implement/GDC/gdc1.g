# gdc1.g is part of the GDC server
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
# $Id: gdc1.g,v 19.0 2003/07/16 06:03:21 aips2adm Exp $
# ------------------------------------------------------------------------------

# gdc1.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++

# Description:
# ------------
# This file contains the glish function for manipulating 1-dimensional data.

# glish functions:
# ----------------
# __gdc1_define_members, gdc1, gdc1_ascii, gdc1_average, gdc1_clone,
# gdc1_interpolate.

# Modification history:
# ---------------------
# 2000 Mar 09 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __gdc1_define_members( ), and
#               gdc1( ).
# 2000 Jun 14 - Nicholas Elias, USNO/NPOI
#               Glish functions gdc1_ascii( ) and gdc1_clone( ) added.
# 2000 Jun 27 - Nicholas Elias, USNO/NPOI
#               Glish functions gdc1_average( ) and gdc1_interpolate( ) added.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'bug.g' ) {
  throw( 'Cannot include bug.g ...', origin = 'gdc1' );
}

if ( !include 'interpolate1d.g' ) {
  throw( 'Cannot include interpolate1d.g ...', origin = 'gdc1' );
}

if ( !include 'note.g' ) {
  throw( 'Cannot include note.g ...', origin = 'gdc1' );
}

if ( !include 'servers.g' ) {
  throw( 'Cannot include servers.g ...', origin = 'gdc1' );
}

if ( !include 'check.g' ) {
  throw( 'Cannot include check.g ...', origin = 'gdc1' );
}

if ( !include 'convert.g' ) {
  throw( 'Cannot include convert.g ...', origin = 'gdc1' );
}

if ( !include 'rgb.g' ) {
  throw( 'Cannot include rgb.g ...', origin = 'gdc1' );
}

if ( !include 'whenever_manager.g' ) {
  throw( 'Cannot include whenever_manager.g ...', origin = 'gdc1' );
}

if ( !include '__gdc1_private.g' ) {
  throw( 'Cannot include __gdc1_private.g ...', origin = 'gdc1' );
}

if ( !include '__gdc1_main.g' ) {
  throw( 'Cannot include __gdc1_main.g ...', origin = 'gdc1' );
}

if ( !include '__gdc1_edit.g' ) {
  throw( 'Cannot include __gdc1_edit.g ...', origin = 'gdc1' );
}

if ( !include '__gdc1_label.g' ) {
  throw( 'Cannot include __gdc1_label.g ...', origin = 'gdc1' );
}

if ( !include '__gdc1_stats.g' ) {
  throw( 'Cannot include __gdc1_stats.g ...', origin = 'gdc1' );
}

if ( !include '__gdc1_zoom.g' ) {
  throw( 'Cannot include __gdc1_zoom.g ...', origin = 'gdc1' );
}

if ( !include '__gdc1_public.g' ) {
  throw( 'Cannot include __gdc1_public.g ...', origin = 'gdc1' );
}

# ------------------------------------------------------------------------------

# __define_gdc1_members

# Description:
# ------------
# This glish function defines the member functions for a gdc1{ } tool.

# Inputs:
# -------
# agent          - The agent.
# id             - The ID.
# gconstructor   - The glish constructor name.
# host           - The host name.
# forcenewserver - The 'force new server' boolean.
# gui            - The GUI variable.
# w              - The whenever handler.
# private        - The private record.

# Outputs:
# --------
# The member functions, returned via the glish function value.

# Modification history:
# ---------------------
# 2000 Mar 09 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __define_gdc1_members := function( ref agent, id, gconstructor, host,
    forcenewserver, ref gui, ref w, ref private ) {
  
  # Initialize the variables

  val private := [=];
  val private.agent := ref agent;
  val private.id := id;
  val private.gconstructor := gconstructor;
  val private.host := host;
  val private.forcenewserver := forcenewserver;
  val private.window := [=];
  val private.window.default := 'gdc1';
  val private.averagefunc := gdc1_average;
  val private.clonefunc := gdc1_clone;
  val private.interpolatefunc := gdc1_interpolate;
  
  public := [=];

  val gui := [=];
  val gui.dumpascii := F;
  val gui.edit := F;
  val gui.hardcopy := F;
  val gui.label := F;
  val gui.pgplot := F;
  val gui.save := F;
  val gui.size := F;
  val gui.stats := F;
  val gui.zoom := F;

  val w := whenever_manager();


  # Define the private member functions (must be called in this order)

  __gdc1_private( gui, private, public );

  __gdc1_editprivate( private );

  __gdc1_labelprivate( private );

  __gdc1_zoomprivate( private );


  # Define the public member functions

  __gdc1_public( gui, w, private, public );


  # Return the structure containing the public member functions

  return( ref public );

}

# ------------------------------------------------------------------------------

# gdc1

# Description:
# ------------
# This glish function creates a standard gdc1{ } tool (interface) for
# manipulating 1-dimensional data.

# Inputs:
# -------
# x              - The 1-dimensional x vector.  It must be a real vector.
# y              - The 1-dimensional y vector.  It must be a real vector.
# xerr           - The 1-dimensional x-error vector (default = [], no errors).
#                  If errors, it must be a real vector.
# yerr           - The 1-dimensional y-error vector (default = [], no errors).
#                  If errors, it must be a real vector.  Any negative errors
#                  are automatically flagged.
# flag           - The 1-dimensional flag vector (default = [], no flags).  If
#                  flags, it must be a boolean vector.
# hms            - The HH:MM:SS boolean (default = False).
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The gdc1{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2000 Mar 09 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const gdc1 := function( x, y, xerr = [], yerr = [], flag=[], hms = F,
    host = '', forcenewserver = F ) {
  
  # Fix and check the inputs

  gconstructor := 'gdc1';
  
  if ( !is_real( x ) ) {
    return( throw( 'Invalid x vector ...', origin = gconstructor ) );
  }
  
  if ( !is_real( y ) || length( y ) != length( x ) ) {
    return( throw( 'Invalid y vector ...', origin = gconstructor ) );
  }
  
  if ( length( xerr ) > 0 ) {
    if ( !is_real( xerr ) || length( xerr ) != length( x ) ) {
      return( throw( 'Invalid x-error vector ...', origin = gconstructor ) );
    }
  } else {
    xerr := as_double( [] );
  }
  
  if ( length( yerr ) > 0 ) {
    if ( !is_real( yerr ) || length( yerr ) != length( x ) ) {
      return( throw( 'Invalid y-error vector ...', origin = gconstructor ) );
    }
  } else {
    yerr := as_double( [] );
  }
  
  if ( length( flag ) > 0 ) {
    if ( !is_boolean( flag ) || length( flag ) != length( x ) ) {
      return( throw( 'Invalid flag vector ...', origin = gconstructor ) );
    }
  } else {
    flag := as_boolean( [] );
  }
  
  if ( !is_boolean( hms ) ) {
    return( throw( 'Invalid HH:MM:SS boolean ...', origin = gconstructor ) );
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host ...', origin = gconstructor ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid \'force-new-server\' boolean boolean ...',
        origin = gconstructor ) );
  }
  
  
  # Invoke the GDC1{ } constructor member function
  
  agent := defaultservers.activate( 'GDC', host, forcenewserver );
  args := [x = x, y = y, xerr = xerr, yerr = yerr, flag = flag, hms = hms];

  if ( is_fail( id := defaultservers.create( agent, 'GDC1',
      to_upper( gconstructor ), args ) ) ) {
    return( throw( 'Error creating GDC server ...', origin = gconstructor ) );
  }
  
  
  # Return the gdc1{ } tool

  gui := F;
  w := F;
  private := F;
  
  public := __define_gdc1_members( agent, id, gconstructor, host,
      forcenewserver, gui, w, private );

  return( ref public );
  
}

# ------------------------------------------------------------------------------

# gdc1_ascii

# Description:
# ------------
# This glish function creates a gdc1_ascii{ } tool (interface) for manipulating
# 1-dimensional data.

# Inputs:
# -------
# file           - The ASCII file name.  The rows represent time stamps.  The
#                  columns are: x (double), y (double), xerr (double), yerr
#                  (double), flag (0=unflagged, 1=flagged).
# hms            - The HH:MM:SS boolean (default = False).
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The gdc1_ascii{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2000 Jun 14 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const gdc1_ascii := function( file, hms = F, host = '', forcenewserver = F ) {
  
  # Fix and check the inputs

  gconstructor := 'gdc1_ascii';

  if ( !cs( file ) ) {
    return( throw( 'Invalid ASCII file name ...', origin = gconstructor ) );
  }
  
  if ( !is_boolean( hms ) ) {
    return( throw( 'Invalid HH:MM:SS boolean ...', origin = gconstructor ) );
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host ...', origin = gconstructor ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid \'force-new-server\' boolean ...',
        origin = gconstructor ) );
  }
  
  
  # Invoke the GDC1{ } constructor member function
  
  agent := defaultservers.activate( 'GDC', host, forcenewserver );
  args := [file = file, hms = hms];

  if ( is_fail( id := defaultservers.create( agent, 'GDC1',
      to_upper( gconstructor ), args ) ) ) {
    return( throw( 'Error creating GDC server ...', origin = gconstructor ) );
  }
  
  
  # Return the gdc1_ascii{ } tool

  gui := F;
  w := F;
  private := F;
 
  public := __define_gdc1_members( agent, id, gconstructor, host,
      forcenewserver, gui, w, private );
  
  return( ref public );
  
}

# ------------------------------------------------------------------------------

# gdc1_average

# Description:
# ------------
# This glish function creates a gdc1_average{ } tool (interface) for
# manipulating 1-dimensional data.  Typically, this is not called directly by
# the user.

# Inputs:
# -------
# objectid       - The ObjectID record.
# x              - The x vector.
# xmin           - The minimum x value.
# xmax           - The maximum x value.
# keep           - The keep-flagged-data boolean.
# weight         - The weight boolean.
# xcalc          - The recalculate-x boolean.
# interp         - The interpolation method ("CUBIC", "LINEAR", "NEAREST",
#                  "SPLINE").
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The gdc1_average{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2000 Jun 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const gdc1_average := function( objectid, x, xmin, xmax, keep, weight, xcalc,
    interp, host = '', forcenewserver = F ) {
  
  # Fix and check the inputs

  gconstructor := 'gdc1_average';
  
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
  
  
  # Invoke the GDC1{ } constructor member function
  
  agent := defaultservers.activate( 'GDC', host, forcenewserver );
  args := [objectid = objectid, x = x, xmin = xmin, xmax = xmax, keep = keep,
      weight = weight, xcalc=xcalc, interp=interp];

  if ( is_fail( id := defaultservers.create( agent, 'GDC1',
      to_upper( gconstructor ), args ) ) ) {
    return( throw( 'Error creating GDC server ...', origin = gconstructor ) );
  }
  
  
  # Return the gdc1_average{ } tool

  gui := F;
  w := F;
  private := F;
  
  public := __define_gdc1_members( agent, id, gconstructor, host,
      forcenewserver, gui, w, private );
  
  return( ref public );
  
}

# ------------------------------------------------------------------------------

# gdc1_clone

# Description:
# ------------
# This glish function creates a gdc1_clone{ } tool (interface) for manipulating
# 1-dimensional data.  Typically, this is not called directly by the user.

# Inputs:
# -------
# objectid       - The ObjectID record.
# xmin           - The minimum x value.
# xmax           - The maximum x value.
# keep           - The keep-flagged-data boolean.
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The gdc1_clone{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2000 Jun 14 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const gdc1_clone := function( objectid, xmin, xmax, keep, host = '',
    forcenewserver = F ) {
  
  # Fix and check the inputs

  gconstructor := 'gdc1_clone';
  
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
  
  if ( !is_boolean( keep ) ) {
    return( throw( 'Invalid keep-flagged-data boolean ...',
        origin = gconstructor ) );
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host ...', origin = gconstructor ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid \'force-new-server\' boolean boolean ...',
        origin = gconstructor ) );
  }
  
  
  # Invoke the GDC1{ } constructor member function
  
  agent := defaultservers.activate( 'GDC', host, forcenewserver );
  args := [objectid = objectid, xmin = xmin, xmax = xmax, keep = keep];

  if ( is_fail( id := defaultservers.create( agent, 'GDC1',
      to_upper( gconstructor ), args ) ) ) {
    return( throw( 'Error creating GDC server ...', origin = gconstructor ) );
  }
  
  
  # Return the gdc1_clone{ } tool

  gui := F;
  w := F;
  private := F;
  
  public := __define_gdc1_members( agent, id, gconstructor, host,
      forcenewserver, gui, w, private );
  
  return( ref public );
  
}

# ------------------------------------------------------------------------------

# gdc1_interpolate

# Description:
# ------------
# This glish function creates a gdc1_interpolate{ } tool (interface) for
# manipulating 1-dimensional data.  Typically, this is not called directly by
# the user.

# Inputs:
# -------
# objectid       - The ObjectID record.
# x              - The x vector.
# keep           - The keep-flagged-data boolean.
# interp         - The interpolation method ("CUBIC", "LINEAR", "NEAREST",
#                  "SPLINE").
# xminbox        - The minimum x-box value.
# xmaxbox        - The maximum x-box value.
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The gdc1_interpolate{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2000 Jun 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const gdc1_interpolate := function( objectid, x, keep, interp, xminbox,
    xmaxbox, host = '', forcenewserver = F ) {
  
  # Fix and check the inputs

  gconstructor := 'gdc1_interpolate';
  
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
  
  if ( !is_boolean( keep ) ) {
    return( throw( 'Invalid keep-flagged-data boolean ...',
        origin = gconstructor ) );
  }
  
  if ( !cs( interp, 0, T ) ) {
    return( throw( 'Invalid interpolation method ...',
        origin = gconstructor ) );
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
  
  
  # Invoke the GDC1{ } constructor member function
  
  agent := defaultservers.activate( 'GDC', host, forcenewserver );
  args := [objectid = objectid, x = x, keep = keep, interp = interp,
      xminbox = xminbox, xmaxbox = xmaxbox];

  if ( is_fail( id := defaultservers.create( agent, 'GDC1',
      to_upper( gconstructor ), args ) ) ) {
    return( throw( 'Error creating GDC server ...', origin = gconstructor ) );
  }
  
  
  # Return the gdc1_interpolate{ } tool

  gui := F;
  w := F;
  private := F;
  
  public := __define_gdc1_members( agent, id, gconstructor, host,
      forcenewserver, gui, w, private );
  
  return( ref public );
  
}
