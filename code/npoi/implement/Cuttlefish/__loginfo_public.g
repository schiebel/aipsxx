# __loginfo_public.g is part of the Cuttlefish server
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
# $Id: __loginfo_public.g,v 19.0 2003/07/16 06:02:31 aips2adm Exp $
# ------------------------------------------------------------------------------

# __loginfo_public.g

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
# private) member functions for loginfo{ } tools.  NB: These functions should
# be called only by loginfo{ } tools.

# glish function:
# ---------------
# __loginfo_public.

# Modification history:
# ---------------------
# 2001 Jan 29 - Nicholas Elias, USNO/NPOI
#               File created with glish function __loginfo_public( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __loginfo_public

# Description:
# ------------
# This glish function creates public (and associated private) member functions
# for a loginfo{ } tool.

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
# 2001 Jan 29 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __loginfo_public := function( ref gui, ref w, ref private, ref public ) {

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
    return( __loginfo_gui( gui, w, private, public ) );
  }
 
 
  # Define the 'web' public member function
 
  const val public.web := function( ) {
    return( web() );
  }


  # Define the 'name' public and private member functions
  
  const val public.name := function( ) {
    wider private;
    return( private.name() );
  }

  val private.nameRec := [_method = 'name', _sequence = private.id._sequence];
  
  const val private.name := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.nameRec ) );
  }


  # Define the 'readonly' public and private member functions
  
  const val public.readonly := function( ) {
    wider private;
    return( private.readonly() );
  }

  val private.readOnlyRec :=
      [_method = 'readOnly', _sequence = private.id._sequence];
  
  const val private.readonly := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.readOnlyRec ) );
  }


  # Define the 'log' public and private member functions
  
  const val public.log := function( ) {
    wider private;
    return( private.log() );
  }

  val private.logRec := [_method = 'log', _sequence = private.id._sequence];
  
  const val private.log := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.logRec ) );
  }


  # Define the 'append' public and private member functions
  
  const val public.append := function( line ) {
    wider private;
    line := as_string( line );
    return( private.append( line ) );
  }

  val private.appendRec :=
      [_method = 'append', _sequence = private.id._sequence];
  
  const val private.append := function( line ) {
    wider private;
    val private.appendRec.line := line;
    return( defaultservers.run( private.agent, private.appendRec ) );
  }
  
  
  # Define the 'dumpascii' public and private member functions
  
  const val public.dumpascii := function( file ) {
    if ( !cs( file ) ) {
      return( throw( 'Invalid file name ...', origin = 'loginfo.dumpascii' ) );
    }
    return( private.dumpascii( file ) );
  }

  val private.dumpASCIIRec :=
      [_method = 'dumpASCII', _sequence = private.id._sequence];
  
  const val private.dumpascii := function( file ) {
    wider private;
    val private.dumpASCIIRec.file := file;
    return( defaultservers.run( private.agent, private.dumpASCIIRec ) );
  }
  
  
  # Define the 'dumphds' public and private member functions
  
  const val public.dumphds := function( file = '' ) {
    if ( !cs( file ) ) {
      return( throw( 'Invalid file name ...', origin = 'loginfo.dumphds' ) );
    }
    if ( file == '' ) {
      file := public.file();
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
  
  
  # Define the 'print' public member function
  
  const val public.print := function( ) {
    wider private, public;
    file := private.nexttmpfile();
    public.dumpascii( file );
    shell( spaste( 'lpr ', file ) );
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
