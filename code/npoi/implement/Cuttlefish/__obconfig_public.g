# __obconfig_public.g is part of the Cuttlefish server
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
# $Id: __obconfig_public.g,v 19.0 2003/07/16 06:02:32 aips2adm Exp $
# ------------------------------------------------------------------------------

# __obconfig_public.g

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
# private) member functions for obconfig{ } tools.  NB: These functions should
# be called only by obconfig{ } tools.

# glish function:
# ---------------
# __obconfig_public.

# Modification history:
# ---------------------
# 2001 Jan 18 - Nicholas Elias, USNO/NPOI
#               File created with glish function __obconfig_public( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __obconfig_public

# Description:
# ------------
# This glish function creates public (and associated private) member functions
# for an obconfig{ } tool.

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
# 2001 Jan 18 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __obconfig_public := function( ref gui, ref w, ref private, ref public ) {

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
    return( __obconfig_gui( gui, w, private, public ) );
  }
 
 
  # Define the 'web' public member function
 
  const val public.web := function( ) {
    return( web() );
  }


  # Define the 'numoutbeam' public and private member functions
  
  const val public.numoutbeam := function( ) {
    wider private;
    return( private.numoutbeam() );
  }

  val private.numOutBeamRec :=
      [_method = 'numOutBeam', _sequence = private.id._sequence];
  
  const val private.numoutbeam := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.numOutBeamRec ) );
  }


  # Define the 'numbaseline' public and private member functions
  
  const val public.numbaseline := function( outbeam ) {
    wider private;
    if ( !private.checkoutbeam( outbeam ) ) {
      return( throw( 'Invalid output-beam number ...',
          origin = 'obconfig.numbaseline' ) );
    }
    return( private.numbaseline( outbeam ) );
  }

  val private.numBaselineRec :=
      [_method = 'numBaseline', _sequence = private.id._sequence];
  
  const val private.numbaseline := function( outbeam ) {
    wider private;
    val private.numBaselineRec.outbeam := outbeam;
    return( defaultservers.run( private.agent, private.numBaselineRec ) );
  }


  # Define the 'numspecchan' public and private member functions
  
  const val public.numspecchan := function( outbeam ) {
    wider private;
    if ( !private.checkoutbeam( outbeam ) ) {
      return( throw( 'Invalid output-beam number ...',
          origin = 'obconfig.numspecchan' ) );
    }
    return( private.numspecchan( outbeam ) );
  }

  val private.numSpecChanRec :=
      [_method = 'numSpecChan', _sequence = private.id._sequence];
  
  const val private.numspecchan := function( outbeam ) {
    wider private;
    val private.numSpecChanRec.outbeam := outbeam;
    return( defaultservers.run( private.agent, private.numSpecChanRec ) );
  }


  # Define the 'spectrometerid' public and private member functions
  
  const val public.spectrometerid := function( outbeam ) {
    wider private;
    if ( !private.checkoutbeam( outbeam ) ) {
      return( throw( 'Invalid output-beam number ...',
          origin = 'obconfig.spectrometerid' ) );
    }
    return( private.spectrometerid( outbeam ) );
  }

  val private.spectrometerIDRec :=
      [_method = 'spectrometerID', _sequence = private.id._sequence];
  
  const val private.spectrometerid := function( outbeam ) {
    wider private;
    val private.spectrometerIDRec.outbeam := outbeam;
    return( defaultservers.run( private.agent, private.spectrometerIDRec ) );
  }


  # Define the 'baselineid' public and private member functions
  
  const val public.baselineid := function( outbeam ) {
    wider private;
    if ( !private.checkoutbeam( outbeam ) ) {
      return( throw( 'Invalid output-beam number ...',
          origin = 'obconfig.baselineid' ) );
    }
    return( private.baselineid( outbeam ) );
  }

  val private.baselineIDRec :=
      [_method = 'baselineID', _sequence = private.id._sequence];
  
  const val private.baselineid := function( outbeam ) {
    wider private;
    val private.baselineIDRec.outbeam := outbeam;
    return( defaultservers.run( private.agent, private.baselineIDRec ) );
  }


  # Define the 'wavelength' public and private member functions
  
  const val public.wavelength := function( outbeam ) {
    wider private;
    if ( !private.checkoutbeam( outbeam ) ) {
      return( throw( 'Invalid output-beam number ...',
          origin = 'obconfig.wavelength' ) );
    }
    return( private.wavelength( outbeam ) );
  }

  val private.wavelengthRec :=
      [_method = 'wavelength', _sequence = private.id._sequence];
  
  const val private.wavelength := function( outbeam ) {
    wider private;
    val private.wavelengthRec.outbeam := outbeam;
    return( defaultservers.run( private.agent, private.wavelengthRec ) );
  }


  # Define the 'wavelengtherr' public and private member functions
  
  const val public.wavelengtherr := function( outbeam ) {
    wider private;
    if ( !private.checkoutbeam( outbeam ) ) {
      return( throw( 'Invalid output-beam number ...',
          origin = 'obconfig.wavelengtherr' ) );
    }
    return( private.wavelengtherr( outbeam ) );
  }

  val private.wavelengthErrRec :=
      [_method = 'wavelengthErr', _sequence = private.id._sequence];
  
  const val private.wavelengtherr := function( outbeam ) {
    wider private;
    val private.wavelengthErrRec.outbeam := outbeam;
    return( defaultservers.run( private.agent, private.wavelengthErrRec ) );
  }


  # Define the 'chanwidth' public and private member functions
  
  const val public.chanwidth := function( outbeam ) {
    wider private;
    if ( !private.checkoutbeam( outbeam ) ) {
      return( throw( 'Invalid output-beam number ...',
          origin = 'obconfig.chanwidth' ) );
    }
    return( private.chanwidth( outbeam ) );
  }

  val private.chanWidthRec :=
      [_method = 'chanWidth', _sequence = private.id._sequence];
  
  const val private.chanwidth := function( outbeam ) {
    wider private;
    val private.chanWidthRec.outbeam := outbeam;
    return( defaultservers.run( private.agent, private.chanWidthRec ) );
  }


  # Define the 'chanwidtherr' public and private member functions
  
  const val public.chanwidtherr := function( outbeam ) {
    wider private;
    if ( !private.checkoutbeam( outbeam ) ) {
      return( throw( 'Invalid output-beam number ...',
          origin = 'obconfig.chanwidtherr' ) );
    }
    return( private.chanwidtherr( outbeam ) );
  }

  val private.chanWidthErrRec :=
      [_method = 'chanWidthErr', _sequence = private.id._sequence];
  
  const val private.chanwidtherr := function( outbeam ) {
    wider private;
    val private.chanWidthErrRec.outbeam := outbeam;
    return( defaultservers.run( private.agent, private.chanWidthErrRec ) );
  }


  # Define the 'fringemod' public and private member functions
  
  const val public.fringemod := function( outbeam ) {
    wider private;
    if ( !private.checkoutbeam( outbeam ) ) {
      return( throw( 'Invalid output-beam number ...',
          origin = 'obconfig.fringemod' ) );
    }
    return( private.fringemod( outbeam ) );
  }

  val private.fringeModRec :=
      [_method = 'fringeMod', _sequence = private.id._sequence];
  
  const val private.fringemod := function( outbeam ) {
    wider private;
    val private.fringeModRec.outbeam := outbeam;
    return( defaultservers.run( private.agent, private.fringeModRec ) );
  }
  
  
  # Define the 'dumphds' public and private member functions
  
  const val public.dumphds := function( file ) {
    if ( !cs( file ) ) {
      return( throw( 'Invalid file name ...', origin = 'obconfig.dumphds' ) );
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


  # Define the 'obtools' public member function

  val private.obToolsRec :=
      [_method = 'obTools', _sequence = private.id._sequence];

  const val public.obtools := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.obToolsRec ) );
  }


  # Define the 'obobjects' public member function

  val private.obObjectsRec :=
      [_method = 'obObjects', _sequence = private.id._sequence];

  const val public.obobjects := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.obObjectsRec ) );
  }


  # Define the 'obobjecterrs' public member function

  val private.obObjectErrsRec :=
      [_method = 'obObjectErrs', _sequence = private.id._sequence];

  const val public.obobjecterrs := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.obObjectErrsRec ) );
  }


  # Define the 'obtypes' public member function

  val private.obTypesRec :=
      [_method = 'obTypes', _sequence = private.id._sequence];

  const val public.obtypes := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.obTypesRec ) );
  }


  # Define the 'obtypeerrs' public member function

  val private.obTypeErrsRec :=
      [_method = 'obTypeErrs', _sequence = private.id._sequence];

  const val public.obtypeerrs := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.obTypeErrsRec ) );
  }


  # Define the 'obylabeldefaults' public member function

  val private.obYLabelDefaultsRec :=
      [_method = 'obYLabelDefaults', _sequence = private.id._sequence];

  const val public.obylabeldefaults := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.obYLabelDefaultsRec ) );
  }


  # Return T
  
  return( T );
  
}
