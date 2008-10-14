# melvin.g is part of Cuttlefish (NPOI data reduction package)
# Copyright (C) 1999,2000
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
#        Internet email: nme@sextans.lowell.edu
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
# $Id: melvin.g,v 19.0 2003/07/16 06:02:03 aips2adm Exp $
# ------------------------------------------------------------------------------

# melvin.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains simple glish functions for getting data from *.cha HDS
# files.  These glish functions are a stop-gap measure.

# Glish functions:
# ----------------
# cvis2, uvis2.

# Modification history:
# ---------------------
# 1999 Feb 26 - Nicholas Elias, USNO/NPOI
#               File created with glish function uvis2( ).
# 1999 Mar 05 - Nicholas Elias, USNO/NPOI
#               Glish function cvis2( ) added.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'cuttlefish.g' ) {
  print '%% melvin: Cannot include cuttlefish.g ...';
  fail;
}

# ------------------------------------------------------------------------------

# cvis2

# Description:
# ------------
# This glish function gets calibrated visibilities from a *.cha HDS file and
# prints them to an ASCII file.  NB: 1) Wavelength channels for each output beam
# are assumed to be the same; 2) One baseline per output beam is assumed.

# Inputs:
# -------
# filecha   - The *.cha HDS file name.  If there is no extension, ".cha" is
#             assumed.
# starid    - The star ID (case insensitive).
# fileascii - The ASCII file name (default is <rootname(filecha)>.starid;
#             "rootname" means no directory and no extension).

# Outputs:
# --------
# T or FAIL event, returned via the function value.

# Modification history:
# ---------------------
# 1999 Feb 26 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const cvis2 := function( filecha, starid, fileascii = '' ) {

  # Fix/check the inputs
  
  filecha := spaste( split( filecha ) );
  
  filesplit := split( filecha, '.' );
  filesplitlen := length(filesplit);
  
  if ( filesplitlen > 1 ) {
    if ( filesplit[filesplitlen] != '' ) {
      if ( filesplit[filesplitlen] != 'cha' ) {
        print '%% cvis2: Non- *.cha HDS file = ', filecha;
        fail;
      }
    } else {
      filecha := spaste( filecha, '.cha' );
    }
  } else {
    filecha := spaste( filecha, 'cha' );
  }
  
  starid := spaste( split( to_upper( starid ) ) );
  
  if ( !is_string( starid ) ) {
    print '%% cvis2: Invalid star ID = ', starid;
    fail;
  }
  
  fileascii := spaste( split( fileascii ) );
  
  if ( fileascii == '' ) {
    filesplit := split( filecha, './' );
    filesplitlen := length(filesplit);
    fileascii := spaste( filesplit[filesplitlen-1], '.C_', starid );
  }
  

  # Open the *.cha HDS file

  if ( is_fail( hds := hdsopen( filecha, T ) ) ) {
    print '%% cvis2: Invalid *.cha HDS file = ', filecha;
    fail;
  }
  
  
  # Obtain the channel wavelengths
  
  hds.goto( 'DataSet.GenConfig.OutputBeam' );
  
  wavelength := 1.0e+09 * hds.obtain( 'Wavelength' );
  
  numchannel := shape( wavelength )[1];
  numoutputbeam := shape( wavelength )[2];
  
  
  # Obtain the scan data
  
  hds.top();
  hds.find( 'ScanData' );

  scantime := hds.obtain( 'ScanTime' ) / 86400.0;
  staridvec := hds.obtain( 'StarID' );
  
  numscan := length( scantime );
  
  hds.find( 'OutputBeam' );
  
  vissq := array( 0, numoutputbeam, numchannel, numscan );
  vissqerr := array( 0, numoutputbeam, numchannel, numscan );
  
  for ( outputbeam in 1:numoutputbeam ) {
    hds.cell( outputbeam );
    vissq[outputbeam,,] := hds.obtain( 'VisSqC' )[1:numchannel,,1:numscan];
    vissqerr[outputbeam,,] :=
        hds.obtain( 'VisSqCErr' )[1:numchannel,,1:numscan];
    hds.annul();
  }
  
  uv := array( 0, numoutputbeam, numchannel, 2, numscan );
  
  for ( outputbeam in 1:numoutputbeam ) {
    hds.cell( outputbeam );
    uvfail := is_fail(
        uv[outputbeam,,,] := hds.obtain( 'UVW' )[1:numchannel,,1:2,1:numscan] );
    if ( uvfail ) {
      print '%% cvis2: No uv data in this *.cha file'
      hds.done();
      fail;
    }
    hds.annul();
  }
  
  uv := uv / 1.0e+06;
  
  
  # Close the *.cha HDS file
  
  hds.done();
  
  
  # Check if starid exists in staridvec
  
  for ( s in 1:length( staridvec ) ) {
    if ( starid == staridvec[s] ) {
      break;
    }
  }
  
  if ( s > length( staridvec ) ) {
    print '%% cvis2: Non-existent starid = ', starid;
    fail;
  }
  
  
  # Print the *.cha HDS file data to the ASCII file
  
  if ( is_fail( handle := open( spaste( '> ', fileascii ) ) ) ) {
    print '%% cvis2: Cannot write ASCII file = ', fileascii;
    fail;
  }
  
  for ( scan in 1:numscan ) {
    if ( starid != staridvec[scan] ) {
      continue;
    }
    for ( channel in 1:numchannel ) {
      fprintf( handle, '%.3f %.1f', scantime[scan], wavelength[channel,1] );
      for ( outputbeam in 1:numoutputbeam ) {
        fprintf( handle, ' %.4f %.4f', vissq[outputbeam,channel,scan],
	    vissqerr[outputbeam,channel,scan] );
      }
      for ( outputbeam in 1:numoutputbeam ) {
        fprintf( handle, ' %.4f %.4f', uv[outputbeam,channel,1,scan],
	    uv[outputbeam,channel,2,scan] );
      }
      fprintf( handle, '\n' );
    }
  }
  
  handle := F;
  
  
  # Return T
  
  return( T );

}

# ------------------------------------------------------------------------------

# uvis2

# Description:
# ------------
# This glish function gets uncalibrated visibilities from a *.cha HDS file and
# prints them # to an ASCII file.  NB: 1) Wavelength channels for each output
# beam are assumed to be the same; 2) One baseline per output beam is assumed.

# Inputs:
# -------
# filecha   - The *.cha HDS file name.  If there is no extension, ".cha" is
#             assumed.
# starid    - The star ID (case insensitive).
# fileascii - The ASCII file name (default is <rootname(filecha)>.starid;
#             "rootname" means no directory and no extension).

# Outputs:
# --------
# T or FAIL event, returned via the function value.

# Modification history:
# ---------------------
# 1999 Feb 26 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const uvis2 := function( filecha, starid, fileascii = '' ) {

  # Fix/check the inputs
  
  filecha := spaste( split( filecha ) );
  
  filesplit := split( filecha, '.' );
  filesplitlen := length(filesplit);
  
  if ( filesplitlen > 1 ) {
    if ( filesplit[filesplitlen] != '' ) {
      if ( filesplit[filesplitlen] != 'cha' ) {
        print '%% uvis2: Non- *.cha HDS file = ', filecha;
        fail;
      }
    } else {
      filecha := spaste( filecha, '.cha' );
    }
  } else {
    filecha := spaste( filecha, 'cha' );
  }
  
  starid := spaste( split( to_upper( starid ) ) );
  
  if ( !is_string( starid ) ) {
    print '%% uvis2: Invalid star ID = ', starid;
    fail;
  }
  
  fileascii := spaste( split( fileascii ) );
  
  if ( fileascii == '' ) {
    filesplit := split( filecha, './' );
    filesplitlen := length(filesplit);
    fileascii := spaste( filesplit[filesplitlen-1], '.', starid );
  }
  

  # Open the *.cha HDS file

  if ( is_fail( hds := hdsopen( filecha, T ) ) ) {
    print '%% uvis2: Invalid *.cha HDS file = ', filecha;
    fail;
  }
  
  
  # Obtain the channel wavelengths
  
  hds.goto( 'DataSet.GenConfig.OutputBeam' );
  
  wavelength := 1.0e+09 * hds.obtain( 'Wavelength' );
  
  numchannel := shape( wavelength )[1];
  numoutputbeam := shape( wavelength )[2];
  
  
  # Obtain the scan data
  
  hds.top();
  hds.find( 'ScanData' );

  scantime := hds.obtain( 'ScanTime' ) / 86400.0;
  staridvec := hds.obtain( 'StarID' );
  
  numscan := length( scantime );
  
  hds.find( 'OutputBeam' );
  
  vissq := array( 0, numoutputbeam, numchannel, numscan );
  vissqerr := array( 0, numoutputbeam, numchannel, numscan );
  
  for ( outputbeam in 1:numoutputbeam ) {
    hds.cell( outputbeam );
    vissq[outputbeam,,] := hds.obtain( 'VisSq' )[1:numchannel,,1:numscan];
    vissqerr[outputbeam,,] := hds.obtain( 'VisSqErr' )[1:numchannel,,1:numscan];
    hds.annul();
  }
  
  uv := array( 0, numoutputbeam, numchannel, 2, numscan );
  
  for ( outputbeam in 1:numoutputbeam ) {
    hds.cell( outputbeam );
    uvfail := is_fail(
        uv[outputbeam,,,] := hds.obtain( 'UVW' )[1:numchannel,,1:2,1:numscan] );
    if ( uvfail ) {
      print '%% uvis2: No uv data in this *.cha file'
      hds.done();
      fail;
    }
    hds.annul();
  }
  
  uv := uv / 1.0e+06;
  
  
  # Close the *.cha HDS file
  
  hds.done();
  
  
  # Check if starid exists in staridvec
  
  for ( s in 1:length( staridvec ) ) {
    if ( starid == staridvec[s] ) {
      break;
    }
  }
  
  if ( s > length( staridvec ) ) {
    print '%% uvis2: Non-existent starid = ', starid;
    fail;
  }
  
  
  # Print the *.cha HDS file data to the ASCII file
  
  if ( is_fail( handle := open( spaste( '> ', fileascii ) ) ) ) {
    print '%% uvis2: Cannot write ASCII file = ', fileascii;
    fail;
  }
  
  for ( scan in 1:numscan ) {
    if ( starid != staridvec[scan] ) {
      continue;
    }
    for ( channel in 1:numchannel ) {
      fprintf( handle, '%.3f %.1f', scantime[scan], wavelength[channel,1] );
      for ( outputbeam in 1:numoutputbeam ) {
        fprintf( handle, ' %.4f %.4f', vissq[outputbeam,channel,scan],
	    vissqerr[outputbeam,channel,scan] );
      }
      for ( outputbeam in 1:numoutputbeam ) {
        fprintf( handle, ' %.4f %.4f', uv[outputbeam,channel,1,scan],
	    uv[outputbeam,channel,2,scan] );
      }
      fprintf( handle, '\n' );
    }
  }
  
  handle := F;
  
  
  # Return T
  
  return( T );

}
