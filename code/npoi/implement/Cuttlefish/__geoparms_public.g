# __geoparms_public.g is part of the Cuttlefish server
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
# $Id: __geoparms_public.g,v 19.0 2003/07/16 06:02:30 aips2adm Exp $
# ------------------------------------------------------------------------------

# __geoparms_public.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions that define public (and associated
# private) member functions for geoparms{ } tools.  NB: These functions should
# be called only by geoparms{ } tools.

# glish function:
# ---------------
# __geoparms_public.

# Modification history:
# ---------------------
# 2001 Jan 26 - Nicholas Elias, USNO/NPOI
#               File created with glish function __geoparms_public( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __geoparms_public

# Description:
# ------------
# This glish function creates public (and associated private) member functions
# for a geoparms{ } tool.

# Inputs:
# -------
# gui     - The GUI variable.
# w       - The whenever manager.
# private - The private variable.
# public  - The public variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2001 Jan 26 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __geoparms_public := function( ref gui, ref w, ref private, ref public ) {

  # Define the 'tool' public and private member functions

  val private.toolRec := [_method = 'tool', _sequence = private.id._sequence];

  const val public.tool := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.toolRec ) );
  }


  # Define the 'version' public member function

  val private.versionRec :=
      [_method = 'version', _sequence = private.id._sequence];

  const val public.version := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.versionRec ) );
  }


  # Define the 'file' public and private member functions
  
  const val public.file := function( ) {
    wider private;
    return( private.file() );
  }

  val private.fileRec := [_method = 'file', _sequence = private.id._sequence];
  
  const val private.file := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.fileRec ) );
  }


  # Define the 'filetail' public member function

  const val public.filetail := function( ) {
    tree := split( public.file(), '/' );
    numbranch := length( tree );
    if ( numbranch < 1 ) {
      return( '' );
    }
    return( tree[numbranch] );
  }


  # Define the 'host' public member function

  const val public.host := function( ) {
    wider private;
    return( private.host );
  }


  # Define the 'forcenewserver' public member function

  const val public.forcenewserver := function( ) {
    wider private;
    return( private.forcenewserver );
  }


  # Define the 'id' public and private member functions

  const val public.id := function( ) {
    wider private;
    return( private.ID() );
  }

  val private.idRec := [_method = 'id', _sequence = private.id._sequence];

  const val private.ID := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.idRec ) );
  }


  # Define the 'done' public member function

  const val public.done := function( ) {
    wider gui, private, public, w;
    wider private, public;
    ok := defaultservers.done( private.agent, private.id.objectid );
    if ( ok ) {
      w.done();
      val gui := F;
      val private := F;
      val public := F;
    }
    return( ok );
  }
  
  
  # Define the 'gui' public member function
  
  const val public.gui := function( ) {
    wider gui, private, public, w;
    return( __geoparms_gui( gui, w, private, public ) );
  }
 
 
  # Define the 'web' public member function
 
  const val public.web := function( ) {
    return( web() );
  }


  # Define the 'altitude' public and private member functions
  
  const val public.altitude := function( ) {
    wider private;
    return( private.altitude() );
  }

  val private.altitudeRec :=
      [_method = 'altitude', _sequence = private.id._sequence];
  
  const val private.altitude := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.altitudeRec ) );
  }


  # Define the 'earthradius' public and private member functions
  
  const val public.earthradius := function( ) {
    wider private;
    return( private.earthradius() );
  }

  val private.earthRadiusRec :=
      [_method = 'earthRadius', _sequence = private.id._sequence];
  
  const val private.earthradius := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.earthRadiusRec ) );
  }


  # Define the 'j2' public and private member functions
  
  const val public.j2 := function( ) {
    wider private;
    return( private.j2() );
  }

  val private.j2Rec := [_method = 'j2', _sequence = private.id._sequence];
  
  const val private.j2 := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.j2Rec ) );
  }


  # Define the 'latitude' public and private member functions
  
  const val public.latitude := function( ) {
    wider private;
    return( private.latitude() );
  }

  val private.latitudeRec :=
      [_method = 'latitude', _sequence = private.id._sequence];
  
  const val private.latitude := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.latitudeRec ) );
  }


  # Define the 'longitude' public and private member functions
  
  const val public.longitude := function( ) {
    wider private;
    return( private.longitude() );
  }

  val private.longitudeRec :=
      [_method = 'longitude', _sequence = private.id._sequence];
  
  const val private.longitude := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.longitudeRec ) );
  }


  # Define the 'taiminusutc' public and private member functions
  
  const val public.taiminusutc := function( ) {
    wider private;
    return( private.taiminusutc() );
  }

  val private.taiMinusUTCRec :=
      [_method = 'taiMinusUTC', _sequence = private.id._sequence];
  
  const val private.taiminusutc := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.taiMinusUTCRec ) );
  }


  # Define the 'tdtminustai' public and private member functions
  
  const val public.tdtminustai := function( ) {
    wider private;
    return( private.tdtminustai() );
  }

  val private.tdtMinusTAIRec :=
      [_method = 'tdtMinusTAI', _sequence = private.id._sequence];
  
  const val private.tdtminustai := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.tdtMinusTAIRec ) );
  }
  
  
  # Define the 'dumphds' public and private member functions
  
  const val public.dumphds := function( file ) {
    if ( !cs( file ) ) {
      return( throw( 'Invalid file name ...', origin = 'geoparms.dumphds' ) );
    }
    return( private.dumphds( file ) );
  }

  val private.dumpHDSRec :=
      [_method = 'dumpHDS', _sequence = private.id._sequence];
  
  const val private.dumphds := function( file ) {
    wider private;
    val private.dumpHDSRec.file := file;
    return( defaultservers.run( private.agent, private.dumpHDSRec ) );
  }


  # Define the 'hdsopen' public member function

  const val public.hdsopen := function( ) {
    wider public;
    file := public.file();
    return( hdsopen( file, T ) );
  }


  # Return T
  
  return( T );
  
}
