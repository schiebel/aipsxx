# triplephase.g is part of Cuttlefish (NPOI data reduction package)
# Copyright (C) 1999
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
# Correspondence concerning Cuttlefish should be addressed as follows:
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
# $Id: triplephase.g,v 19.0 2003/07/16 06:02:01 aips2adm Exp $
# ------------------------------------------------------------------------------

# triplephase.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish class for manipulating triple (closure) phases.

# glish class:
# ------------
# triplephase.

# Modification history:
# ---------------------
# 1999 Dec 14 - Nicholas Elias, USNO/NPOI
#               File created with glish class triplephase{ }.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'cuttlefish.g' ) {
  fail '%% triplephase: Cannot include cuttlefish.g ...';
}

# ------------------------------------------------------------------------------

# triplephase

# Description:
# ------------
# This glish class creates a triplephase object (interface) for manipulating
# triple (closure) phases, in degrees.

# Inputs:
# -------
# file           - The file name.
# triple         - The triple number.
# loadcalib      - Flag to load calibrated triple phases (default = T).
# format         - The file format (default = 'HDS').
# host           - The host name (default = '').
# forcenewserver - The 'force new server' flag (default = F).

# Outputs:
# --------
# The triplephase object, returned via the glish function value.

# Modification history:
# ---------------------
# 1999 Dec 14 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const triplephase := function( file, triple, loadcalib = T, format = 'HDS',
    host = '', forcenewserver = F ) {
  
  # Initialize the variables
  
  top := F;

  private := [=];
  public := [=];
  
  
  # Fix and check the inputs
  
  if ( !cs( file ) ) {
    fail '%% triplephase: Invalid file name ...';
  }
  
  private.file := file;
  
  if ( !is_boolean( loadcalib ) ) {
    fail '%% triplephase: Invalid calibrated-triple-phases flag ...';
  }
  
  private.loadcalib := loadcalib;
  
  if ( !loadcalib ) {
    private.object := 'TRIPLEPHASE';
  } else {
    private.object := 'TRIPLEPHASEC';
  }
  private.objecterr := spaste( private.object, 'ERR' );
  
  if ( !cs( format, 5, T  ) ) {
    fail '%% triplephase: Invalid file format ...';
  }
  
  if ( format != 'HDS' && format != 'TABLE' && format != 'ASCII' ) {
    fail '%% triplephase: Invalid file format ...';
  }
  
  private.format := format;
  
  if ( !cs( host ) ) {
    fail '%% triplephase: Invalid host ...';
  }
  
  private.host := host;
  
  if ( !is_boolean( forcenewserver ) ) {
    fail '%% triplephase: Invalid \'force-new-server\' boolean flag ...';
  }
  
  private.forcenewserver := forcenewserver;
  
  if ( !cis( triple, 1 ) ) {
    fail '%% triplephase: Invalid triple number...';
  }
  
  if ( is_fail( tripleconfigTemp := tripleconfig( private.file, private.format,
      private.host, private.forcenewserver ) ) ) {
    fail;
  }

  private.numtriple := tripleconfigTemp.numtriple();
  
  if ( triple > private.numtriple ) {
    tripleconfigTemp.done();
    fail '%% triplephase: Invalid triple number ...';
  }
  
  private.triple := triple;
  
  private.outputbeam := tripleconfigTemp.outputbeam( private.triple );
  private.baseline := tripleconfigTemp.baseline( private.triple );
  
  private.numspecchan := tripleconfigTemp.numspecchan( private.triple );
  private.specchan := array( 0.0, 3, private.numspecchan );
  for ( l in 1:3 ) {
    private.specchan[l,] := tripleconfigTemp.specchan( private.triple, l );
  }
  private.specchan::shape := [3,private.numspecchan];
  
  tripleconfigTemp.done();
  
  if ( is_fail( obconfigTemp := obconfig( private.file, private.format,
      private.host, private.forcenewserver ) ) ) {
    fail;
  }
  
  private.baselineid := array( '', 3 );
  private.wavelength := array( 0.0, 3, private.numspecchan );
  private.wavelengtherr := array( 0.0, 3, private.numspecchan );
  private.chanwidth := array( 0.0, 3, private.numspecchan );
  private.chanwidtherr := array( 0.0, 3, private.numspecchan );
  for ( l in 1:3 ) {
    private.baselineid[l] :=
        obconfigTemp.baselineid( private.outputbeam[l], private.baseline[l] );
    private.wavelength[l,] := obconfigTemp.wavelength( private.outputbeam[l] );
    private.wavelengtherr[l,] :=
        obconfigTemp.wavelengtherr( private.outputbeam[l] );
    private.chanwidth[l,] := obconfigTemp.chanwidth( private.outputbeam[l] );
    private.chanwidtherr[l,] :=
        obconfigTemp.chanwidtherr( private.outputbeam[l] );
  }
  private.wavelength::shape := [3,private.numspecchan];
  private.wavelengtherr::shape := [3,private.numspecchan];
  private.chanwidth::shape := [3,private.numspecchan];
  private.chanwidtherr::shape := [3,private.numspecchan];
  
  obconfigTemp.done();
  
  
  # Create auxillary private functions for checking inputs
  
  const private.checkspecchan := function( ref specchan ) {
    wider private;
    if ( specchan == '' ) {
      val specchan := 1:private.numspecchan;
      return( T );
    }
    if ( !is_integer( specchan ) ) {
      return( F );
    }
    numspecchan := length( specchan );
    for ( s in 1:numspecchan ) {
      if ( specchan[s] < 1 || specchan[s] > private.numspecchan ) {
        return( F );
      }
    }
    if ( numspecchan == 1 ) {
      return( T );
    }
    for ( s1 in 1:(numspecchan-1) ) {
      for ( s2 in (s1+1):numspecchan ) {
        if ( specchan[s1] == specchan[s2] ) {
          return( F );
        }
      }
    }
    return( T );
  }
  
  const private.checkleg1 := function( leg ) {
    if ( !is_integer( leg ) ) {
      return( F );
    }
    if ( length( leg ) != 1 ) {
      return( F );
    }
    if ( leg < 1 || leg > 3 ) {
      return( F );
    }
    return( T );
  }
  
  
  # Create the private functions for dumping the triple phases
  
  const private.dumpascii := function( replace = F ) {
    fail '%% triplephase: ASCII format not implemented yet ...';
  }
  
  const private.dumphds := function( file, replace = F ) {
    wider private;
    if ( is_fail( hds := hdsopen( file, F, host = private.host,
        forcenewserver := private.forcenewserver ) ) ) {
      fail '%% triplephase: Could not dump to HDS file ...';
    }
    if ( !hds.there( 'ScanData' ) ) {
      hds.new( 'ScanData', '', 0 );
    } else if ( replace ) {
      hds.new( 'ScanData', '', 0, replace );
    } else {
      fail '%% triplephase: Cannot replace in HDS file ...';
    }
    hds.find( 'ScanData' );
    if ( !hds.there( 'Triple' ) ) {
      hds.new( 'Triple', '', private.numtriple );
    } else if ( replace ) {
      hds.new( 'Triple', '', private.numtriple, replace );
    } else {
      fail '%% triplephase: Cannot replace in HDS file ...';
    }
    hds.find( 'Triple' );
    hds.cell( private.triple );
    hds.create( private.object, '_REAL', private.triplephase );
    hds.create( private.objecterr, '_REAL', private.triplephaseerr );
    hds.done();
    return( T );
  }
  
  const private.dumptable := function( replace = F ) {
    fail '%% triplephase: Aips++ table format not implemented yet ...';
  }
  
  
  # Create the private functions for loading the triple phases
  
  const private.loadascii := function( ) {
    fail '%% triplephase: ASCII format not implemented yet ...';
  }
  
  const private.loadhds := function( ) {
    wider private;
    if ( is_fail( private.scaninfo := scaninfo( private.file, private.format,
         private.host, private.forcenewserver ) ) ) {
      fail;
    }
    private.uvw := [=];
    for ( l in 1:3 ) {
      if ( is_fail( private.uvw[l] := uvw( private.file, private.outputbeam[l],
           private.baselineid[l], private.format, private.host,
           private.forcenewserver ) ) ) {
        private.scaninfo.done();
        fail;
      }
    }
    if ( is_fail( hds := hdsopen( private.file, F, host = private.host,
        forcenewserver = private.forcenewserver ) ) ) {
      private.scaninfo.done()
      for ( l in 1:3 ) {
        private.uvw[l].done();
      }
      fail;
    }
    hds.find( 'ScanData' );
    if ( hds.there( 'Triple' ) ) {
      hds.find( 'Triple' );
    } else {
      hds.done();
      private.scaninfo.done()
      for ( l in 1:3 ) {
        private.uvw[l].done();
      }
      fail '%% triplephase: No triple data ...';
    }
    hds.cell( private.triple );
    if ( hds.there( private.object ) ) {
      private.triplephase := hds.obtain( private.object ) * 180.0 / pi;
      private.triplephase::shape :=
          [private.numspecchan,private.scaninfo.numscan()]
      private.triplephaseerr := hds.obtain( private.objecterr ) * 180.0 / pi;
      private.triplephaseerr::shape :=
          [private.numspecchan,private.scaninfo.numscan()]
    } else {
      hds.done();
      private.scaninfo.done()
      for ( l in 1:3 ) {
        private.uvw[l].done();
      }
      fail '%% triplephase: No triple phases of desired HDS object ...';
    }
    hds.done();
    return( T );
  }
  
  const private.loadtable := function( ) {
    fail '%% triplephase: Aips++ table format not implemented yet ...';
  }

  
  # Define the 'done' member function
  
  const public.done := function( ) {
    wider private, public;
    val public := F;
    private.scaninfo.done();
    for ( l in 1:3 ) {
      private.uvw[l].done();
    }
    private := F;
    return( T );
  }
  
  
  # Define the 'file' member function
  
  const public.file := function( ) {
    wider private;
    return( private.file );
  }
  
  
  # Define the 'triple' member function
  
  const public.triple := function( ) {
    wider private;
    return( private.triple );
  }
  
  
  # Define the 'loadcalib' member function
  
  const public.loadcalib := function( ) {
    wider private;
    return( private.loadcalib );
  }
  
  
  # Define the 'format' member function
  
  const public.format := function( ) {
    wider private;
    return( private.format );
  }
  
  
  # Define the 'host' member function
  
  const public.host := function( ) {
    wider private;
    return( private.host );
  }
  
  
  # Define the 'forcenewserver' member function
  
  const public.forcenewserver := function( ) {
    wider private;
    return( private.forcenewserver );
  }
  
  
  # Define the 'dump' member function
  
  const public.dump := function( file, format = 'HDS' ) {
    wider private;
    if ( format == 'ASCII' ) {
      if ( is_fail( private.dumpascii( file ) ) ) {
        fail;
      } else {
        return( T );
      }
    } else if ( format == 'HDS' ) {
      if ( is_fail( private.dumphds( file, T ) ) ) {
        fail;
      } else {
        return( T );
      }
    } else if ( format == 'TABLE' ) {
      if ( is_fail( private.dumptable( file ) ) ) {
        fail;
      } else {
        return( T );
      }
    } else {
      fail '%% triplephase: Invalid format ...'
    }
  }
  
  
  # Define the 'load' member function
  
  const public.load := function( ) {
    wider private;
    if ( private.format == 'ASCII' ) {
      if ( is_fail( private.loadascii() ) ) {
        fail;
      } else {
        return( T );
      }
    } else if ( private.format == 'HDS' ) {
      if ( is_fail( private.loadhds() ) ) {
        fail;
      } else {
        return( T );
      }
    } else if ( private.format == 'TABLE' ) {
      if ( is_fail( private.loadtable() ) ) {
        fail;
      } else {
        return( T );
      }
    }
  }
  

  # Define the 'web' member function

  const public.web := function( ) {
    fail '%% triplephase: web() member function not implemented yet ...'
#    xt := '/usr/X11R6/bin/xterm -title lynx -e ';
#    command := spaste( 'lynx ', 'hds.html' );
#    return( shell( command ) );
  }


  # Define the 'gui' member function
 
  const public.gui := function( ) {
    wider top;
    if ( top != F ) {
      return;
    }
    top := frame( title = 'Dialog' );
    dialog := label( top, 'GUI for triplephase class not implemented yet ...' );
    dismiss := button( top, 'Dismiss' );
    whenever dismiss->press do {
      top := F;
    }
    return( T )
  }
  
  
  # Define the 'numtriple' member function
  
  const public.numtriple := function( ) {
    wider private;
    return( private.numtriple );
  }
  
  
  # Define the 'outputbeam' member function
  
  const public.outputbeam := function( leg = '' ) {
    wider private;
    if ( leg == '' ) {
      return( private.outputbeam );
    } else {
      if ( !private.checkleg1( leg ) ) {
        fail '%% tripleconfig: Invalid leg number ...';
      }
      return( private.outputbeam[leg] );
    }
  }
  
  
  # Define the 'baseline' member function
  
  const public.baseline := function( leg = '' ) {
    wider private;
    if ( leg == '' ) {
      return( private.baseline );
    } else {
      if ( !private.checkleg1( leg ) ) {
        fail '%% tripleconfig: Invalid leg number ...';
      }
      return( private.baseline[leg] );
    }
  }
  
  
  # Define the 'baselineid' member function
  
  const public.baselineid := function( leg = '' ) {
    wider private;
    if ( leg == '' ) {
      return( private.baselineid );
    } else {
      if ( !private.checkleg1( leg ) ) {
        fail '%% tripleconfig: Invalid leg number ...';
      }
      return( private.baselineid[leg] );
    }
  }
  
  
  # Define the 'numspecchan' member function
  
  const public.numspecchan := function( ) {
    wider private;
    return( private.numspecchan );
  }
   
  
  # Define the 'specchan' member function
  
  const public.specchan := function( leg, specchan = '' ) {
    wider private;
    if ( !private.checkleg1( leg ) ) {
      fail '%% triplephase: Invalid leg number ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    return( private.specchan[leg,specchan] );
  }
   
  
  # Define the 'wavelength' member function
  
  const public.wavelength := function( leg, specchan = '' ) {
    wider private;
    if ( !private.checkleg1( leg ) ) {
      fail '%% triplephase: Invalid leg number ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    return( private.wavelength[leg,specchan] );
  }
   
  
  # Define the 'wavelengtherr' member function
  
  const public.wavelengtherr := function( leg, specchan = '' ) {
    wider private;
    if ( !private.checkleg1( leg ) ) {
      fail '%% triplephase: Invalid leg number ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    return( private.wavelengtherr[leg,specchan] );
  }
   
  
  # Define the 'chanwidth' member function
  
  const public.chanwidth := function( leg, specchan = '' ) {
    wider private;
    if ( !private.checkleg1( leg ) ) {
      fail '%% triplephase: Invalid leg number ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    return( private.chanwidth[leg,specchan] );
  }
   
  
  # Define the 'chanwidtherr' member function
  
  const public.chanwidtherr := function( leg, specchan = '' ) {
    wider private;
    if ( !private.checkleg1( leg ) ) {
      fail '%% triplephase: Invalid leg number ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    return( private.chanwidtherr[leg,specchan] );
  }
 
  
  # Define the 'numscan' member function
  
  const public.numscan := function( ) {
    wider private;
    return( private.scaninfo.numscan() );
  }
  
  
  # Define the 'scan' member function
  
  const public.scan := function( starid ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    return( private.scaninfo.scan( starid ) );
  }
  
  
  # Define the 'scanid' member function
  
  const public.scanid := function( starid ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    return( private.scaninfo.scanid( starid ) );
  }
  
  
  # Define the 'scantime' member function
  
  const public.scantime := function( starid ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    return( private.scaninfo.scantime( starid ) );
  }
  
  
  # Define the 'ra' member function
  
  const public.ra := function( starid ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    return( private.scaninfo.ra( starid ) );
  }
  
  
  # Define the 'dec' member function
  
  const public.dec := function( starid ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    return( private.scaninfo.dec( starid ) );
  }
  
  
  # Define the 'liststar' member function
  
  const public.liststar := function( ) {
    wider private;
    return( private.scaninfo.liststar() );
  }
  
  
  # Define the 'instar' member function
  
  const public.instar := function( starid ) {
    wider private;
    return( private.scaninfo.instar( starid ) );
  }
  
  
  # Define the 'u' member function
  
  const public.u := function( starid, leg, specchan = '' ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    if ( !private.checkleg1( leg ) ) {
      fail '%% triplephase: Invalid leg number ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    scan := private.scaninfo.scan( starid );
    return( private.uvw[leg].u( starid, specchan ) );
  }
  
  
  # Define the 'v' member function
  
  const public.v := function( starid, leg, specchan = '' ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    if ( !private.checkleg1( leg ) ) {
      fail '%% triplephase: Invalid leg number ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    scan := private.scaninfo.scan( starid );
    return( private.uvw[leg].v( starid, specchan ) );
  }
  
  
  # Define the 'w' member function
  
  const public.w := function( starid, leg, specchan = '' ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    if ( !private.checkleg1( leg ) ) {
      fail '%% triplephase: Invalid leg number ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    scan := private.scaninfo.scan( starid );
    return( private.uvw[leg].w( starid, specchan ) );
  }
  
  
  # Define the 'uv' member function
  
  const public.uv := function( starid, leg, specchan = '' ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    if ( !private.checkleg1( leg ) ) {
      fail '%% triplephase: Invalid leg number ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    scan := private.scaninfo.scan( starid );
    return( private.uvw[leg].uv( starid, specchan ) );
  }
  
  
  # Define the 'uvw' member function
  
  const public.uvw := function( starid, leg, specchan = '' ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    if ( !private.checkleg1( leg ) ) {
      fail '%% triplephase: Invalid leg number ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    scan := private.scaninfo.scan( starid );
    return( private.uvw[leg].uvw( starid, specchan ) );
  }
  
  
  # Define the 'triplephase' member function
  
  const public.triplephase := function( starid, specchan = '' ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    scan := private.scaninfo.scan( starid );
    data := private.triplephase[specchan,scan];
    data::shape := [length(specchan),length(scan)];
    return( data );
  }
  
  
  # Define the 'triplephaseerr' member function
  
  const public.triplephaseerr := function( starid, specchan = '' ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    scan := private.scaninfo.scan( starid );
    dataerr := private.triplephaseerr[specchan,scan];
    dataerr::shape := [length(specchan),length(scan)];
    return( dataerr );
  }
  
  
  # Define the 'getstar' member function
  
  const public.getstar := function( starid, specchan = '' ) {
    wider private, public;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% triplephase: Invalid star ID ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% triplephase: Invalid spectral channel(s) ...';
    }
    result := private.scaninfo.getstar( starid );
    result.starid := starid;
    result.triple := private.triple;
    result.loadcalib := private.loadcalib;
    result.outputbeam := private.outputbeam;
    result.baseline := private.baseline;
    result.baselineid := private.baselineid;
    result.numspecchan := length( specchan );
    result.specchan := array( 0.0, 3, result.numspecchan );
    result.wavelength := array( 0.0, 3, result.numspecchan );
    result.wavelengtherr := array( 0.0, 3, result.numspecchan );
    result.chanwidth := array( 0.0, 3, result.numspecchan );
    result.chanwidtherr := array( 0.0, 3, result.numspecchan );
    result.uvw := array( 0.0, 3, result.numspecchan, 3, result.numscan );
    for ( l in 1:3 ) {
      result.specchan[l,] := specchan;
      result.wavelength[l,] := public.wavelength( l, specchan );
      result.wavelengtherr[l,] := public.wavelengtherr( l, specchan );
      result.chanwidth[l,] := public.chanwidth( l, specchan );
      result.chanwidtherr[l,] := public.chanwidtherr( l, specchan );
      result.uvw[l,,,] := public.uvw( starid, l, specchan );
    }
    result.specchan::shape := [3,result.numspecchan];
    result.wavelength::shape := [3,result.numspecchan];
    result.wavelengtherr::shape := [3,result.numspecchan];
    result.chanwidth::shape := [3,result.numspecchan];
    result.chanwidtherr::shape := [3,result.numspecchan];
    result.uvw::shape := [3,result.numspecchan,3,result.numscan];
    result.triplephase := public.triplephase( starid, specchan );
    result.triplephaseerr := public.triplephaseerr( starid, specchan );
    return( result );
  }
  
  
  # Load the triple phases and return the triplephase object
  
  public.load();

  return( ref public );

}
