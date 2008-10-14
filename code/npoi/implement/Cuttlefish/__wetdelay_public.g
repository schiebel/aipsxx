# __wetdelay_public.g is part of the Cuttlefish server
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
# $Id: __wetdelay_public.g,v 19.0 2003/07/16 06:02:49 aips2adm Exp $
# ------------------------------------------------------------------------------

# __wetdelay_public.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++

# Description:
# ------------
# This file contains the glish function for adding public member functions to
# the wet-delay tool.

# glish functions:
# ----------------
# __wetdelay_public.

# Modification history:
# ---------------------
# 2001 May 10 - Nicholas Elias, USNO/NPOI
#               File created with glish function __wetdelay_public( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __wetdelay_public

# Description
# -----------
# This glish function adds public member functions to the wet-delay tool.

# Inputs:
# -------
# gui     - The gui variable.
# private - The private variable.
# public  - The public variable.

# Outputs:
# --------
# gui     - The gui variable.
# private - The private variable.
# public  - The public variable.

# Modification history:
# ---------------------
# 2001 May 10 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __wetdelay_public := function( ref gui, ref private, ref public ) {

  # Define the 'basetool' public and private member functions
  
  const val public.basetool := function( ) {
    return( private.basetool() );
  }

  val private.baseToolRec :=
      [_method = 'baseTool', _sequence = private.id._sequence];
  
  const val private.basetool := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.baseToolRec ) );
  }
  

  # Define the 'tool' public and private member functions
  
  const val public.tool := function( ) {
    return( private.tool() );
  }

  val private.toolRec := [_method = 'tool', _sequence = private.id._sequence];
  
  const val private.tool := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.toolRec ) );
  }
  

  # Define the 'version' public and private member functions
  
  const val public.version := function( ) {
    return( private.version() );
  }

  val private.versionRec :=
      [_method = 'version', _sequence = private.id._sequence];
  
  const val private.version := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.versionRec ) );
  }
  
  
  # Define the 'dumphds' public and private member functions
  
  const val public.dumphds := function( file, xmin = [], xmax = [],
      token = "" ) {
    member := spaste( private.constructor, '.dumpascii' );
    if ( !cs( file ) ) {
      return( throw( 'Invalid file name ...', origin = member ) );
    }
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    return( private.dumphds( file, xmin, xmax, token ) );
  }

  val private.dumpHDSRec :=
      [_method = 'dumpHDS', _sequence = private.id._sequence];
  
  const val private.dumphds := function( file, xmin, xmax, token ) {
    wider private;
    val private.dumpHDSRec.file := file;
    val private.dumpHDSRec.xmin := xmin;
    val private.dumpHDSRec.xmax := xmax;
    val private.dumpHDSRec.tokenarg := token;
    return( defaultservers.run( private.agent, private.dumpHDSRec ) );
  }


  # Define the 'savehds' public and private member functions
  
  const val public.savehds := function( ) {
    return( private.savehds() );
  }

  val private.saveHDSRec :=
      [_method = 'saveHDS', _sequence = private.id._sequence];
  
  const val private.savehds := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.saveHDSRec ) );
  }
  
  
  # Return T
  
  return( T );

}

