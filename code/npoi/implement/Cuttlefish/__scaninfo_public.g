# __scaninfo_public.g is part of the Cuttlefish server
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
# $Id: __scaninfo_public.g,v 19.0 2003/07/16 06:02:24 aips2adm Exp $
# ------------------------------------------------------------------------------

# __scaninfo_public.g

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
# private) member functions for scaninfo{ } tools.  NB: These functions should
# be called only by scaninfo{ } tools.

# glish function:
# ---------------
# __scaninfo_public.

# Modification history:
# ---------------------
# 2000 Aug 15 - Nicholas Elias, USNO/NPOI
#               File created with glish function __scaninfo_public( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __scaninfo_public

# Description:
# ------------
# This glish function creates public (and associated private) member functions
# for a scaninfo{ } tool.

# Inputs:
# -------
# gui     - The GUI variable.
# w       - The whenever manager variable.
# private - The private variable.
# public  - The public variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2000 Aug 15 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __scaninfo_public := function( ref gui, ref w, ref private, ref public ) {

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


  # Define the 'derived' public and private member functions
  
  const val public.derived := function( ) {
    wider private;
    return( private.derived() );
  }

  val private.derivedRec :=
      [_method = 'derived', _sequence = private.id._sequence];
  
  const val private.derived := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.derivedRec ) );
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
    return( __scaninfo_gui( gui, w, private, public ) );
  }
 
 
  # Define the 'web' public member function
 
  const val public.web := function( ) {
    return( web() );
  }


  # Define the 'numscan' public and private member functions
  
  const val public.numscan := function( ) {
    wider private;
    return( private.numscan() );
  }

  val private.numScanRec :=
      [_method = 'numScan', _sequence = private.id._sequence];
  
  const val private.numscan := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.numScanRec ) );
  }


  # Define the 'length' public and private member functions
  
  const val public.length := function( startscan = [], stopscan = [],
      starid = "" ) {
    wider private;
    if ( !private.checkscan( startscan, stopscan ) ) {
      return( throw( 'Invalid start and/or stop scans ...',
          origin = 'scaninfo.length' ) );
    }
    if ( !private.checkstarid( starid ) ) {
      return( throw( 'Invalid star ID ...', origin = 'scaninfo.length' ) );
    }
    return( private.length( startscan, stopscan, starid ) );
  }

  val private.lengthRec :=
      [_method = 'length', _sequence = private.id._sequence];
  
  const val private.length := function( startscan, stopscan, starid ) {
    wider private;
    val private.lengthRec.startscan := startscan;
    val private.lengthRec.stopscan := stopscan;
    val private.lengthRec.starid := starid;
    return( defaultservers.run( private.agent, private.lengthRec ) );
  }


  # Define the 'scan' public and private member functions
  
  const val public.scan := function( startscan = [], stopscan = [],
      starid = "" ) {
    wider private;
    if ( !private.checkscan( startscan, stopscan ) ) {
      return( throw( 'Invalid start and/or stop scans ...',
          origin = 'scaninfo.scan' ) );
    }
    if ( !private.checkstarid( starid ) ) {
      return( throw( 'Invalid star ID ...', origin = 'scaninfo.scan' ) );
    }
    return( private.scan( startscan, stopscan, starid ) );
  }

  val private.scanRec := [_method = 'scan', _sequence = private.id._sequence];
  
  const val private.scan := function( startscan, stopscan, starid ) {
    wider private;
    val private.scanRec.startscan := startscan;
    val private.scanRec.stopscan := stopscan;
    val private.scanRec.starid := starid;
    return( defaultservers.run( private.agent, private.scanRec ) );
  }


  # Define the 'timescan' public and private member functions
  
  const val public.timescan := function( starttime, stoptime, starid = "" ) {
    wider private;
    if ( !is_numeric( starttime ) ) {
      return( throw( 'Invaid start time ...', origin = 'scaninfo.timescan' ) );
    }
    if ( !is_numeric( stoptime ) ) {
      return( throw( 'Invaid stop time ...', origin = 'scaninfo.timescan' ) );
    }
    if ( starttime > stoptime ) {
      return( throw( 'Invalid start and/or stop time ...',
          origin = 'scaninfo.timescan' ) );
    }
    if ( !private.checkstarid( starid ) ) {
      return( throw( 'Invalid star ID ...', origin = 'scaninfo.scan' ) );
    }
    starttime := as_double( starttime );
    stoptime := as_double( stoptime );
    return( private.timescan( starttime, stoptime, starid ) );
  }

  val private.timescanRec :=
      [_method = 'timeScan', _sequence = private.id._sequence];
  
  const val private.timescan := function( starttime, stoptime, starid ) {
    wider private;
    val private.timescanRec.starttime := starttime;
    val private.timescanRec.stoptime := stoptime;
    val private.timescanRec.starid := starid;
    return( defaultservers.run( private.agent, private.timescanRec ) );
  }


  # Define the 'scanid' public and private member functions
  
  const val public.scanid := function( startscan = [], stopscan = [],
      starid = "" ) {
    wider private;
    if ( !private.checkscan( startscan, stopscan ) ) {
      return( throw( 'Invalid start and/or stop scans ...',
          origin = 'scaninfo.scanid' ) );
    }
    if ( !private.checkstarid( starid ) ) {
      return( throw( 'Invalid star ID ...', origin = 'scaninfo.scanid' ) );
    }
    return( private.scanid( startscan, stopscan, starid ) );
  }

  val private.scanIDRec :=
      [_method = 'scanID', _sequence = private.id._sequence];
  
  const val private.scanid := function( startscan, stopscan, starid ) {
    wider private;
    val private.scanIDRec.startscan := startscan;
    val private.scanIDRec.stopscan := stopscan;
    val private.scanIDRec.starid := starid;
    return( defaultservers.run( private.agent, private.scanIDRec ) );
  }


  # Define the 'starid' public and private member functions
  
  const val public.starid := function( startscan = [], stopscan = [],
      starid = "" ) {
    wider private;
    if ( !private.checkscan( startscan, stopscan ) ) {
      return( throw( 'Invalid start and/or stop scans ...',
          origin = 'scaninfo.starid' ) );
    }
    if ( !private.checkstarid( starid ) ) {
      return( throw( 'Invalid star ID ...', origin = 'scaninfo.starid' ) );
    }
    return( private.starid( startscan, stopscan, starid ) );
  }

  val private.starIDRec :=
      [_method = 'starID', _sequence = private.id._sequence];
  
  const val private.starid := function( startscan, stopscan, starid ) {
    wider private;
    val private.starIDRec.startscan := startscan;
    val private.starIDRec.stopscan := stopscan;
    val private.starIDRec.starid := starid;
    return( defaultservers.run( private.agent, private.starIDRec ) );
  }


  # Define the 'scantime' public and private member functions
  
  const val public.scantime := function( startscan = [], stopscan = [],
      starid = "", hms = F ) {
    wider private;
    if ( !private.checkscan( startscan, stopscan ) ) {
      return( throw( 'Invalid start and/or stop scans ...',
          origin = 'scaninfo.scantime' ) );
    }
    if ( !private.checkstarid( starid ) ) {
      return( throw( 'Invalid star ID ...', origin = 'scaninfo.scantime' ) );
    }
    if ( !is_boolean( hms ) ) {
      return( throw( 'Invalid hms boolean ...',
          origin = 'scaninfo.scantime' ) );
    }
    scantime := private.scantime( startscan, stopscan, starid );
    if ( hms ) {
      scantime := s2hms( scantime );
    }
    return( scantime );
  }

  val private.scanTimeRec :=
      [_method = 'scanTime', _sequence = private.id._sequence];
  
  const val private.scantime := function( startscan, stopscan, starid ) {
    wider private;
    val private.scanTimeRec.startscan := startscan;
    val private.scanTimeRec.stopscan := stopscan;
    val private.scanTimeRec.starid := starid;
    return( defaultservers.run( private.agent, private.scanTimeRec ) );
  }


  # Define the 'ra' public and private member functions
  
  const val public.ra := function( startscan = [], stopscan = [],
      starid = "", hms = F ) {
    wider private;
    if ( !private.checkscan( startscan, stopscan ) ) {
      return( throw( 'Invalid start and/or stop scans ...',
          origin = 'scaninfo.ra' ) );
    }
    if ( !private.checkstarid( starid ) ) {
      return( throw( 'Invalid star ID ...', origin = 'scaninfo.ra' ) );
    }
    if ( !is_boolean( hms ) ) {
      return( throw( 'Invalid hms boolean ...', origin = 'scaninfo.ra' ) );
    }
    ra := private.ra( startscan, stopscan, starid );
    if ( hms ) {
      ra := h2hms( ra );
    }
    return( ra );
  }

  val private.RARec := [_method = 'RA', _sequence = private.id._sequence];
  
  const val private.ra := function( startscan, stopscan, starid ) {
    wider private;
    val private.RARec.startscan := startscan;
    val private.RARec.stopscan := stopscan;
    val private.RARec.starid := starid;
    return( defaultservers.run( private.agent, private.RARec ) );
  }


  # Define the 'dec' public and private member functions
  
  const val public.dec := function( startscan = [], stopscan = [],
      starid = "", dms = F ) {
    wider private;
    if ( !private.checkscan( startscan, stopscan ) ) {
      return( throw( 'Invalid start and/or stop scans ...',
          origin = 'scaninfo.dec' ) );
    }
    if ( !private.checkstarid( starid ) ) {
      return( throw( 'Invalid star ID ...', origin = 'scaninfo.dec' ) );
    }
    if ( !is_boolean( dms ) ) {
      return( throw( 'Invalid dms boolean ...', origin = 'scaninfo.dec' ) );
    }
    dec := private.dec( startscan, stopscan, starid );
    if ( dms ) {
      dec := d2dms( dec );
    }
    return( dec );
  }

  val private.DECRec := [_method = 'DEC', _sequence = private.id._sequence];
  
  const val private.dec := function( startscan, stopscan, starid ) {
    wider private;
    val private.DECRec.startscan := startscan;
    val private.DECRec.stopscan := stopscan;
    val private.DECRec.starid := starid;
    return( defaultservers.run( private.agent, private.DECRec ) );
  }


  # Define the 'starlist' public and private member functions
  
  const val public.starlist := function( ) {
    wider private;
    return( private.starlist() );
  }

  val private.starListRec :=
      [_method = 'starList', _sequence = private.id._sequence];
  
  const val private.starlist := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.starListRec ) );
  }


  # Define the 'starvalid' public and private member functions
  
  const val public.starvalid := function( starid ) {
    wider private;
    starid := split( starid );
    return( private.starvalid( starid ) );
  }

  val private.starValidRec :=
      [_method = 'starValid', _sequence = private.id._sequence];
  
  const val private.starvalid := function( starid ) {
    wider private;
    val private.starValidRec.starid := starid;
    return( defaultservers.run( private.agent, private.starValidRec ) );
  }
  
  
  # Define the 'dumphds' public and private member functions
  
  const val public.dumphds := function( file, startscan = [], stopscan = [],
      starid = "" ) {
    wider private;
    if ( !cs( file ) ) {
      return( throw( 'Invalid file name ...', origin = 'ibconfig.dumphds' ) );
    }
    if ( !private.checkscan( startscan, stopscan ) ) {
      return( throw( 'Invalid start and/or stop scans ...',
          origin = 'scaninfo.dumphds' ) );
    }
    if ( !private.checkstarid( starid ) ) {
      return( throw( 'Invalid star ID ...', origin = 'scaninfo.dumphds' ) );
    }
    return( private.dumphds( file, startscan, stopscan, starid ) );
  }

  val private.dumpHDSRec :=
      [_method = 'dumpHDS', _sequence = private.id._sequence];
  
  const val private.dumphds := function( file, startscan, stopscan, starid ) {
    wider private;
    val private.dumpHDSRec.file := file;
    val private.dumpHDSRec.startscan := startscan;
    val private.dumpHDSRec.stopscan := stopscan;
    val private.dumpHDSRec.starid := starid;
    return( defaultservers.run( private.agent, private.dumpHDSRec ) );
  }
  
  
  # Define the 'dumpascii' public and private member functions
  
  const val public.dumpascii := function( file, startscan = [], stopscan = [],
      starid = "" ) {
    wider private;
    if ( !cs( file ) ) {
      return( throw( 'Invalid file name ...', origin = 'scaninfo.dumpascii' ) );
    }
    if ( !private.checkscan( startscan, stopscan ) ) {
      return( throw( 'Invalid start and/or stop scans ...',
          origin = 'scaninfo.dumpascii' ) );
    }
    if ( !private.checkstarid( starid ) ) {
      return( throw( 'Invalid star ID ...', origin = 'scaninfo.dumpascii' ) );
    }
    return( private.dumpascii( file, startscan, stopscan, starid ) );
  }

  val private.dumpASCIIRec :=
      [_method = 'dumpASCII', _sequence = private.id._sequence];
  
  const val private.dumpascii := function( file, startscan, stopscan, starid ) {
    wider private;
    val private.dumpASCIIRec.file := file;
    val private.dumpASCIIRec.startscan := startscan;
    val private.dumpASCIIRec.stopscan := stopscan;
    val private.dumpASCIIRec.starid := starid;
    return( defaultservers.run( private.agent, private.dumpASCIIRec ) );
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
