# __sysconfig_public.g is part of the Cuttlefish server
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
# $Id: __sysconfig_public.g,v 19.0 2003/07/16 06:02:34 aips2adm Exp $
# ------------------------------------------------------------------------------

# __sysconfig_public.g

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
# private) member functions for sysconfig{ } tools.  NB: These functions should
# be called only by sysconfig{ } tools.

# glish function:
# ---------------
# __sysconfig_public.

# Modification history:
# ---------------------
# 2001 Jan 26 - Nicholas Elias, USNO/NPOI
#               File created with glish function __sysconfig_public( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __sysconfig_public

# Description:
# ------------
# This glish function creates public (and associated private) member functions
# for a sysconfig{ } tool.

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

const __sysconfig_public := function( ref gui, ref w, ref private, ref public ) {

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
    return( __sysconfig_gui( gui, w, private, public ) );
  }
 
 
  # Define the 'web' public member function
 
  const val public.web := function( ) {
    return( web() );
  }


  # Define the 'beamcombinerid' public and private member functions
  
  const val public.beamcombinerid := function( ) {
    wider private;
    return( private.beamcombinerid() );
  }

  val private.beamCombinerIDRec :=
      [_method = 'beamCombinerID', _sequence = private.id._sequence];
  
  const val private.beamcombinerid := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.beamCombinerIDRec ) );
  }


  # Define the 'date' public and private member functions
  
  const val public.date := function( ) {
    wider private;
    return( private.date() );
  }

  val private.dateRec := [_method = 'date', _sequence = private.id._sequence];
  
  const val private.date := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.dateRec ) );
  }


  # Define the 'format' public and private member functions
  
  const val public.format := function( ) {
    wider private;
    return( private.format() );
  }

  val private.formatRec :=
      [_method = 'format', _sequence = private.id._sequence];
  
  const val private.format := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.formatRec ) );
  }


  # Define the 'instrcohint' public and private member functions
  
  const val public.instrcohint := function( ) {
    wider private;
    return( private.instrcohint() );
  }

  val private.instrCohIntRec :=
      [_method = 'instrCohInt', _sequence = private.id._sequence];
  
  const val private.instrcohint := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.instrCohIntRec ) );
  }


  # Define the 'refstation' public and private member functions
  
  const val public.refstation := function( ) {
    wider private;
    return( private.refstation() );
  }

  val private.refStationRec :=
      [_method = 'refStation', _sequence = private.id._sequence];
  
  const val private.refstation := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.refStationRec ) );
  }


  # Define the 'systemid' public and private member functions
  
  const val public.systemid := function( ) {
    wider private;
    return( private.systemid() );
  }

  val private.systemIDRec :=
      [_method = 'systemID', _sequence = private.id._sequence];
  
  const val private.systemid := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.systemIDRec ) );
  }


  # Define the 'userid' public and private member functions
  
  const val public.userid := function( ) {
    wider private;
    return( private.userid() );
  }

  val private.userIDRec :=
      [_method = 'userID', _sequence = private.id._sequence];
  
  const val private.userid := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.userIDRec ) );
  }
  
  
  # Define the 'dumphds' public and private member functions
  
  const val public.dumphds := function( file ) {
    if ( !cs( file ) ) {
      return( throw( 'Invalid file name ...', origin = 'sysconfig.dumphds' ) );
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
