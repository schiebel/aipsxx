# gdc2token.g is part of the GDC server
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
# $Id: gdc2token.g,v 19.0 2003/07/16 06:03:42 aips2adm Exp $
# ------------------------------------------------------------------------------

# gdc2token.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++

# Description:
# ------------
# This file contains the glish function for manipulating tokenized
# 2-dimensional data.

# glish functions:
# ----------------
# __gdc2token_define_members, gdc2token, gdc2token_ascii, gdc2token_clone.

# Modification history:
# ---------------------
# 2000 Dec 21 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __gdc2token_define_members( )
#               and gdc2token( ).
# 2000 Jan 10 - Nicholas Elias, USNO/NPOI
#               Glish function gdc2token_ascii( ).
# 2000 Jan 16 - Nicholas Elias, USNO/NPOI
#               Glish function gdc2token_clone( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'bug.g' ) {
  throw( 'Cannot include bug.g ...', origin = 'gdc2token' );
}

if ( !include 'interpolate1d.g' ) {
  throw( 'Cannot include interpolate1d.g ...', origin = 'gdc2token' );
}

if ( !include 'note.g' ) {
  throw( 'Cannot include note.g ...', origin = 'gdc2token' );
}

if ( !include 'servers.g' ) {
  throw( 'Cannot include servers.g ...', origin = 'gdc2token' );
}

if ( !include 'check.g' ) {
  throw( 'Cannot include check.g ...', origin = 'gdc2token' );
}

if ( !include 'convert.g' ) {
  throw( 'Cannot include convert.g ...', origin = 'gdc2token' );
}

if ( !include 'rgb.g' ) {
  throw( 'Cannot include rgb.g ...', origin = 'gdc2token' );
}

if ( !include 'whenever_manager.g' ) {
  throw( 'Cannot include whenever_manager.g ...', origin = 'gdc2token' );
}

if ( !include '__gdc2token_private.g' ) {
  throw( 'Cannot include __gdc2token_private.g ...', origin = 'gdc2token' );
}

if ( !include '__gdc2token_main.g' ) {
  throw( 'Cannot include __gdc2token_main.g ...', origin = 'gdc2token' );
}

if ( !include '__gdc2token_edit.g' ) {
  throw( 'Cannot include __gdc2token_edit.g ...', origin = 'gdc2token' );
}

if ( !include '__gdc2token_label.g' ) {
  throw( 'Cannot include __gdc2token_label.g ...', origin = 'gdc2token' );
}

if ( !include '__gdc2token_stats.g' ) {
  throw( 'Cannot include __gdc2token_stats.g ...', origin = 'gdc2token' );
}

if ( !include '__gdc2token_token.g' ) {
  throw( 'Cannot include __gdc2token_token.g ...', origin = 'gdc2token' );
}

if ( !include '__gdc2token_zoom.g' ) {
  throw( 'Cannot include __gdc2token_zoom.g ...', origin = 'gdc2token' );
}

if ( !include '__gdc2token_public.g' ) {
  throw( 'Cannot include __gdc2token_public.g ...', origin = 'gdc2token' );
}

# ------------------------------------------------------------------------------

# __define_gdc2token_members

# Description:
# ------------
# This glish function defines the member functions for a gdc2token{ } tool.

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
# 2000 Dec 21 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __define_gdc2token_members := function( ref agent, id, gconstructor, host,
    forcenewserver, ref gui, ref w, ref private ) {
  
  # Initialize the variables

  val private := [=];
  val private.agent := ref agent;
  val private.id := id;
  val private.gconstructor := gconstructor;
  val private.host := host;
  val private.forcenewserver := forcenewserver;
  val private.window := [=];
  val private.window.default := 'gdc2token';
#  val private.averagefunc := gd21token_average;
  val private.clonefunc := gdc2token_clone;
#  val private.interpolatefunc := gdc2token_interpolate;
  
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
  val gui.token := F;
  val gui.zoom := F;

  val w := whenever_manager();


  # Define the private member functions (must be called in this order)

  __gdc2token_private( gui, private, public );

  __gdc2token_editprivate( private );

  __gdc2token_labelprivate( private );

  __gdc2token_tokenprivate( private );

  __gdc2token_zoomprivate( private );


  # Define the public member functions

  __gdc2token_public( gui, w, private, public );


  # Return the structure containing the public member functions

  return( ref public );

}

# ------------------------------------------------------------------------------

# gdc2token

# Description:
# ------------
# This glish function creates a standard gdc2token{ } tool (interface) for
# manipulating tokenized 2-dimensional data.

# Inputs:
# -------
# x              - The 1-dimensional x vector.  It must be a real vector.
# y              - The 2-dimensional y matrix.  It must be a real matrix.
# xerr           - The 1-dimensional x-error vector (default = [], no errors).
#                  If errors, it must be a real vector.
# yerr           - The 2-dimensional y-error matrix (default = [], no errors).
#                  If errors, it must be a real matrix.  Any negative errors
#                  are automatically flagged.
# token          - The 1-dimensional token vector (same dimension as x).
# column         - The 1-dimensional column ID vector (default =
#                  1:shape(y)[2]).  It can be any type of vector (it will be
#                  converted to a string vector internally).
# flag           - The 2-dimensional flag matrix (default = [], no flags).  If
#                  flags, it must be a boolean matrix.
# tokentype      - The token type (default = 'Token').
# columntype     - The column type (default = 'Column');.
# hms            - The HH:MM:SS boolean (default = False).
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The gdc2token{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2000 Dec 21 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const gdc2token := function( x, y, xerr = [], yerr = [], token, column = [],
    flag=[], tokentype = 'Token', columntype = 'Column', hms = F, host = '',
    forcenewserver = F ) {
  
  # Fix and check the inputs

  gconstructor := 'gdc2token';
  
  if ( !is_real( x ) ) {
    return( throw( 'Invalid x vector ...', origin = gconstructor ) );
  }
  
  if ( !is_real( y ) || length( shape( y ) ) != 2 ||
       shape( y )[1] != length( x ) ) {
    return( throw( 'Invalid y matrix ...', origin = gconstructor ) );
  }
  
  if ( length( xerr ) > 0 ) {
    if ( !is_real( xerr ) || length( xerr ) != length( x ) ) {
      return( throw( 'Invalid x-error vector ...', origin = gconstructor ) );
    }
  } else {
    xerr := as_double( [] );
  }
  
  if ( length( yerr ) > 0 ) {
    if ( !is_real( yerr ) || length( shape( yerr ) ) != 2 ||
         shape( yerr )[1] != length( x ) ||
         shape( yerr )[2] != shape( y )[2] ) {
      return( throw( 'Invalid y-error matrix ...', origin = gconstructor ) );
    }
  } else {
    yerr := as_double( [] );
  }

  if ( !is_string( token ) || length( token ) != length( x ) ) {
    return( throw( 'Invalid token vector ...', origin = gconstructor ) );
  }

  if ( length( column ) < 1 ) {
    column := seq( 1, shape( y )[2] );
  }

  column := as_string( column );

  if ( length( column ) != shape( y )[2] ) {
    return( throw( 'Invalid column ID vector ...', origin = gconstructor ) );
  }

  if ( length( flag ) > 0 ) {
    if ( !is_boolean( flag ) || length( shape( flag ) ) != 2 ||
         shape( flag )[1] != length( x ) ||
         shape( flag )[2] != shape( y )[2] ) {
      return( throw( 'Invalid flag matrix ...', origin = gconstructor ) );
    }
  } else {
    flag := as_boolean( [] );
  }
  
  if ( length( tokentype ) > 1 || !is_string( tokentype ) ) {
    return( throw( 'Invalid token name ...', origin = gconstructor ) );
  }
  
  if ( length( columntype ) > 1 || !is_string( columntype ) ) {
    return( throw( 'Invalid column name ...', origin = gconstructor ) );
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
  
  
  # Invoke the GDC2Token{ } constructor member function
  
  agent := defaultservers.activate( 'GDC', host, forcenewserver );
  args := [x = x, y = y, xerr = xerr, yerr = yerr, token = token,
      column = column, flag = flag, tokentype = tokentype,
      columntype = columntype, hms = hms];

  if ( is_fail( id := defaultservers.create( agent, 'GDC2Token',
      to_upper( gconstructor ), args ) ) ) {
    return( throw( 'Error creating GDC server ...', origin = gconstructor ) );
  }
  
  
  # Return the gdc2token{ } tool

  gui := F;
  w := F;
  private := F;
  
  public := __define_gdc2token_members( agent, id, gconstructor, host,
      forcenewserver, gui, w, private );

  return( ref public );
  
}

# ------------------------------------------------------------------------------

# gdc2token_ascii

# Description:
# ------------
# This glish function creates a gdc2token_ascii{ } tool (interface) for
# manipulating tokenized 1-dimensional data.

# Inputs:
# -------
# file           - The ASCII file name.  The rows represent time stamps.  The
#                  columns are: x (double), y (multiple double), xerr (double),
#                  yerr (multiple double), token (string), column (multiple
#                  string), flag (multiple; 0=unflagged, 1=flagged).
# tokentype      - The token type (default = 'Token');
# columntype     - The column type (default = 'Column');
# hms            - The HH:MM:SS boolean (default = False).
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The gdc2token_ascii{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Jan 10 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const gdc2token_ascii := function( file, tokentype = 'Token',
    columntype = 'Column', hms = F, host = '', forcenewserver = F ) {
  
  # Fix and check the inputs

  gconstructor := 'gdc2token_ascii';

  if ( !cs( file ) ) {
    return( throw( 'Invalid ASCII file name ...', origin = gconstructor ) );
  }
  
  if ( length( tokentype ) > 1 || !is_string( tokentype ) ) {
    return( throw( 'Invalid token name ...', origin = gconstructor ) );
  }
  
  if ( length( columntype ) > 1 || !is_string( columntype ) ) {
    return( throw( 'Invalid column ID name ...', origin = gconstructor ) );
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
  
  
  # Invoke the GDC2Token{ } constructor member function
  
  agent := defaultservers.activate( 'GDC', host, forcenewserver );
  args := [file = file, tokentype = tokentype, columntype = columntype,
      hms = hms];

  if ( is_fail( id := defaultservers.create( agent, 'GDC2Token',
      to_upper( gconstructor ), args ) ) ) {
    return( throw( 'Error creating GDC server ...', origin = gconstructor ) );
  }
  
  
  # Return the gdc2token_ascii{ } tool

  gui := F;
  w := F;
  private := F;
 
  public := __define_gdc2token_members( agent, id, gconstructor, host,
      forcenewserver, gui, w, private );
  
  return( ref public );
  
}

# ------------------------------------------------------------------------------

# gdc2token_clone

# Description:
# ------------
# This glish function creates a gdc2token_clone{ } tool (interface) for
# manipulating tokenized 1-dimensional data.  Typically, this is not called
# directly by the user.

# Inputs:
# -------
# objectid       - The ObjectID record.
# xmin           - The minimum x value.
# xmax           - The maximum x value.
# token          - The tokens.
# column         - The column IDs.
# keep           - The keep-flagged-data boolean.
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The gdc2token_clone{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Jan 16 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const gdc2token_clone := function( objectid, xmin, xmax, token, column, keep,
    host = '', forcenewserver = F ) {
  
  # Fix and check the inputs

  gconstructor := 'gdc2token_clone';
  
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
  
  if ( !is_string( column ) ) {
    return( throw( 'Invalid column ID(s) ...', origin = gconstructor ) );
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
  
  
  # Invoke the GDC2Token{ } constructor member function
  
  agent := defaultservers.activate( 'GDC', host, forcenewserver );
  args := [objectid = objectid, xmin = xmin, xmax = xmax, token = token,
      column = column, keep = keep];

  if ( is_fail( id := defaultservers.create( agent, 'GDC2Token',
      to_upper( gconstructor ), args ) ) ) {
    return( throw( 'Error creating GDC server ...', origin = gconstructor ) );
  }
  
  
  # Return the gdc2token_clone{ } tool

  gui := F;
  w := F;
  private := F;
  
  public := __define_gdc2token_members( agent, id, gconstructor, host,
      forcenewserver, gui, w, private );
  
  return( ref public );
  
}
