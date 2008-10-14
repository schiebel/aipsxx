# __ibconfig_public.g is part of the Cuttlefish server
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
# $Id: __ibconfig_public.g,v 19.0 2003/07/16 06:02:20 aips2adm Exp $
# ------------------------------------------------------------------------------

# __ibconfig_public.g

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
# private) member functions for ibconfig{ } tools.  NB: These functions should
# be called only by ibconfig{ } tools.

# glish function:
# ---------------
# __ibconfig_public.

# Modification history:
# ---------------------
# 2000 Aug 14 - Nicholas Elias, USNO/NPOI
#               File created with glish function __ibconfig_public( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __ibconfig_public

# Description:
# ------------
# This glish function creates public (and associated private) member functions
# for an ibconfig{ } tool.

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
# 2000 Aug 14 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __ibconfig_public := function( ref gui, ref w, ref private, ref public ) {

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
    return( __ibconfig_gui( gui, w, private, public ) );
  }
 
 
  # Define the 'web' public member function
 
  const val public.web := function( ) {
    return( web() );
  }


  # Define the 'numinputbeam' public and private member functions
  
  const val public.numinputbeam := function( ) {
    wider private;
    return( private.numinputbeam() );
  }

  val private.numInputBeamRec :=
      [_method = 'numInputBeam', _sequence = private.id._sequence];
  
  const val private.numinputbeam := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.numInputBeamRec ) );
  }


  # Define the 'numsiderostat' public and private member functions
  
  const val public.numsiderostat := function( ) {
    wider private;
    return( private.numsiderostat() );
  }

  val private.numSiderostatRec :=
      [_method = 'numSiderostat', _sequence = private.id._sequence];
  
  const val private.numsiderostat := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.numSiderostatRec ) );
  }


  # Define the 'bcinputid' public and private member functions
  
  const val public.bcinputid := function( inputbeam ) {
    wider private;
    if ( !private.checkinputbeam( inputbeam ) ) {
      return( throw( 'Invalid input-beam number ...',
          origin = 'ibconfig.bcinputid' ) );
    }
    return( private.bcinputid( inputbeam ) );
  }

  val private.bcInputIDRec :=
      [_method = 'bcInputID', _sequence = private.id._sequence];
  
  const val private.bcinputid := function( inputbeam ) {
    wider private;
    val private.bcInputIDRec.inputbeam := inputbeam;
    return( defaultservers.run( private.agent, private.bcInputIDRec ) );
  }


  # Define the 'delaylineid' public and private member functions
  
  const val public.delaylineid := function( inputbeam ) {
    wider private;
    if ( !private.checkinputbeam( inputbeam ) ) {
      return( throw( 'Invalid input-beam number ...',
          origin = 'ibconfig.delaylineid' ) );
    }
    return( private.delaylineid( inputbeam ) );
  }

  val private.delayLineIDRec :=
      [_method = 'delayLineID', _sequence = private.id._sequence];
  
  const val private.delaylineid := function( inputbeam ) {
    wider private;
    val private.delayLineIDRec.inputbeam := inputbeam;
    return( defaultservers.run( private.agent, private.delayLineIDRec ) );
  }


  # Define the 'inputbeamid' public and private member functions
  
  const val public.inputbeamid := function( inputbeam ) {
    wider private;
    if ( !private.checkinputbeam( inputbeam ) ) {
      return( throw( 'Invalid input-beam number ...',
          origin = 'ibconfig.inputbeamid' ) );
    }
    return( private.inputbeamid( inputbeam ) );
  }

  val private.inputBeamIDRec :=
      [_method = 'inputBeamID', _sequence = private.id._sequence];
  
  const val private.inputbeamid := function( inputbeam ) {
    wider private;
    val private.inputBeamIDRec.inputbeam := inputbeam;
    return( defaultservers.run( private.agent, private.inputBeamIDRec ) );
  }


  # Define the 'siderostatid' public and private member functions
  
  const val public.siderostatid := function( inputbeam ) {
    wider private;
    if ( !private.checkinputbeam( inputbeam ) ) {
      return( throw( 'Invalid input-beam number ...',
          origin = 'ibconfig.siderostatid' ) );
    }
    return( private.siderostatid( inputbeam ) );
  }

  val private.siderostatIDRec :=
      [_method = 'siderostatID', _sequence = private.id._sequence];
  
  const val private.siderostatid := function( inputbeam ) {
    wider private;
    val private.siderostatIDRec.inputbeam := inputbeam;
    return( defaultservers.run( private.agent, private.siderostatIDRec ) );
  }


  # Define the 'startrackerid' public and private member functions
  
  const val public.startrackerid := function( inputbeam ) {
    wider private;
    if ( !private.checkinputbeam( inputbeam ) ) {
      return( throw( 'Invalid input-beam number ...',
          origin = 'ibconfig.startrackerid' ) );
    }
    return( private.startrackerid( inputbeam ) );
  }

  val private.starTrackerIDRec :=
      [_method = 'starTrackerID', _sequence = private.id._sequence];
  
  const val private.startrackerid := function( inputbeam ) {
    wider private;
    val private.starTrackerIDRec.inputbeam := inputbeam;
    return( defaultservers.run( private.agent, private.starTrackerIDRec ) );
  }


  # Define the 'stationid' public and private member functions
  
  const val public.stationid := function( inputbeam ) {
    wider private;
    if ( !private.checkinputbeam( inputbeam ) ) {
      return( throw( 'Invalid input-beam number ...',
          origin = 'ibconfig.stationid' ) );
    }
    return( private.stationid( inputbeam ) );
  }

  val private.stationIDRec :=
      [_method = 'stationID', _sequence = private.id._sequence];
  
  const val private.stationid := function( inputbeam ) {
    wider private;
    val private.stationIDRec.inputbeam := inputbeam;
    return( defaultservers.run( private.agent, private.stationIDRec ) );
  }


  # Define the 'stationcoord' public and private member functions
  
  const val public.stationcoord := function( inputbeam ) {
    wider private;
    if ( !private.checkinputbeam( inputbeam ) ) {
      return( throw( 'Invalid input-beam number ...',
          origin = 'ibconfig.stationcoord' ) );
    }
    return( private.stationcoord( inputbeam ) );
  }

  val private.stationCoordRec :=
      [_method = 'stationCoord', _sequence = private.id._sequence];
  
  const val private.stationcoord := function( inputbeam ) {
    wider private;
    val private.stationCoordRec.inputbeam := inputbeam;
    return( defaultservers.run( private.agent, private.stationCoordRec ) );
  }
  
  
  # Define the 'dumphds' public and private member functions
  
  const val public.dumphds := function( file ) {
    if ( !cs( file ) ) {
      return( throw( 'Invalid file name ...', origin = 'ibconfig.dumphds' ) );
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


  # Define the 'ibtools' public member function

  val private.ibToolsRec :=
      [_method = 'ibTools', _sequence = private.id._sequence];

  const val public.ibtools := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.ibToolsRec ) );
  }


  # Define the 'ibobjects' public member function

  val private.ibObjectsRec :=
      [_method = 'ibObjects', _sequence = private.id._sequence];

  const val public.ibobjects := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.ibObjectsRec ) );
  }


  # Define the 'ibobjecterrs' public member function

  val private.ibObjectErrsRec :=
      [_method = 'ibObjectErrs', _sequence = private.id._sequence];

  const val public.ibobjecterrs := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.ibObjectErrsRec ) );
  }


  # Define the 'ibtypes' public member function

  val private.ibTypesRec :=
      [_method = 'ibTypes', _sequence = private.id._sequence];

  const val public.ibtypes := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.ibTypesRec ) );
  }


  # Define the 'ibtypeerrs' public member function

  val private.ibTypeErrsRec :=
      [_method = 'ibTypeErrs', _sequence = private.id._sequence];

  const val public.ibtypeerrs := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.ibTypeErrsRec ) );
  }


  # Define the 'ibylabeldefaults' public member function

  val private.ibYLabelDefaultsRec :=
      [_method = 'ibYLabelDefaults', _sequence = private.id._sequence];

  const val public.ibylabeldefaults := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.ibYLabelDefaultsRec ) );
  }


  # Return T
  
  return( T );
  
}
