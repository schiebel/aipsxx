# uvw.g is part of Cuttlefish (NPOI data reduction package)
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
# $Id: uvw.g,v 19.0 2003/07/16 06:02:09 aips2adm Exp $
# ------------------------------------------------------------------------------

# uvw.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish class for manipulating uvw spatial frequencies.

# glish class:
# ------------
# uvw.

# Modification history:
# ---------------------
# 1999 Nov 19 - Nicholas Elias, USNO/NPOI
#               File created with glish class uvw{ }.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'cuttlefish.g' ) {
  fail '%% uvw: Cannot include cuttlefish.g ...';
}

# ------------------------------------------------------------------------------

# uvw

# Description:
# ------------
# This glish class creates an uvw object (interface) for manipulating uvw
# spatial frequencies.

# Inputs:
# -------
# file           - The file name.
# outputbeam     - The output beam number.
# baselineid     - The baseline ID.
# format         - The file format (default = 'HDS').
# host           - The host name (default = '').
# forcenewserver - The 'force new server' flag (default = F).

# Outputs:
# --------
# The uvw object, returned via the glish function value.

# Modification history:
# ---------------------
# 1999 Nov 19 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const uvw := function( file, outputbeam, baselineid, format = 'HDS', host = '',
    forcenewserver = F ) {
  
  # Initialize the variables

  top := F;

  private := [=];
  public := [=];
  
  
  # Fix and check the inputs
  
  if ( !cs( file ) ) {
    fail '%% uvw: Invalid file name ...';
  }
  
  private.file := file;
  
  if ( !cs( format, 5, T  ) ) {
    fail '%% uvw: Invalid file format ...';
  }
  
  if ( format != 'HDS' && format != 'TABLE' && format != 'ASCII' ) {
    fail '%% uvw: Invalid file format ...';
  }
  
  private.format := format;
  
  if ( !cs( host ) ) {
    fail '%% uvw: Invalid host ...';
  }
  
  private.host := host;
  
  if ( !is_boolean( forcenewserver ) ) {
    fail '%% uvw: Invalid \'force-new-server\' boolean flag ...';
  }
  
  private.forcenewserver := forcenewserver;
  
  if ( !cis( outputbeam, 1 ) ) {
    fail '%% uvw: Invalid output beam number ...';
  }
  
  if ( is_fail( obconfigTemp := obconfig( private.file, private.format,
       private.host, private.forcenewserver ) ) ) {
    fail;
  }
  
  private.numoutbeam := obconfigTemp.numoutbeam();
  
  if ( outputbeam > private.numoutbeam ) {
    obconfigTemp.done();
    fail '%% uvw: Invalid output beam number ...';
  }
  
  private.outputbeam := outputbeam;
  
  if ( !cs( baselineid, 7, T ) ) {
    fail '%% uvw: Invalid baseline ID ...';
  }
  
  flag := F;
  
  for ( b in 1:obconfigTemp.numbaseline( private.outputbeam ) ) {
    if ( baselineid == obconfigTemp.baselineid( private.outputbeam, b ) ) {
      flag := T;
      break;
    }
  }
  
  if ( !flag ) {
    obconfigTemp.done();
    fail '%% uvw: Invalid baseline ID ...';
  }
  
  private.baseline := b;
  private.baselineid := baselineid;
  
  private.numspecchan := obconfigTemp.numspecchan( private.outputbeam );
  private.spectrometerid := obconfigTemp.spectrometerid( private.outputbeam );
  private.wavelength := obconfigTemp.wavelength( private.outputbeam );
  private.wavelengtherr := obconfigTemp.wavelengtherr( private.outputbeam );
  
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
  
  
  # Create the private functions for dumping the uvw spatial frequencies
  
  const private.dumpascii := function( replace = F ) {
    fail '%% uvw: ASCII format not implemented yet ...';
  }
  
  const private.dumphds := function( file, replace = F ) {
    wider private;
    if ( is_fail( hds := hdsopen( file, F, host = private.host,
        forcenewserver = private.forcenewserver ) ) ) {
      fail '%% uvw: Could not dump to HDS file ...';
    }
    if ( !hds.there( 'ScanData' ) ) {
      hds.new( 'ScanData', '', 0 );
    } else if ( replace ) {
      hds.new( 'ScanData', '', 0, replace );
    } else {
      fail '%% uvw: Cannot replace in HDS file...';
    }
    hds.find( 'ScanData' );
    if ( !hds.there( 'OutputBeam' ) ) {
      hds.new( 'OutputBeam', '', private.numoutbeam );
    } else if ( replace ) {
      hds.new( 'OutputBeam', '', private.numoutbeam, replace );
    } else {
      fail '%% uvw: Cannot replace in HDS file...';
    }
    hds.find( 'OutputBeam' );
    hds.cell( private.outputbeam );
    hds.create( 'UVW', '_DOUBLE', private.uvw );
    hds.done();
    return( T );
  }
  
  const private.dumptable := function( replace = F ) {
    fail '%% uvw: Aips++ table format not implemented yet ...';
  }
  
  
  # Create the private functions for loading the output beam data
  
  const private.loadascii := function( ) {
    fail '%% uvw: ASCII format not implemented yet ...';
  }
  
  const private.loadhds := function( ) {
    wider private;
    if ( is_fail( private.scaninfo := scaninfo( private.file, private.format,
         private.host, private.forcenewserver ) ) ) {
      fail;
    }
    if ( is_fail( hds := hdsopen( private.file, T, host = private.host,
        forcenewserver = private.forcenewserver ) ) ) {
      fail '%% uvw: Cannot load from HDS file ...';
    }
    hds.find( 'ScanData' );
    if ( hds.there( 'OutputBeam' ) ) {
      hds.find( 'OutputBeam' );
    } else {
      hds.done();
      fail '%% uvw: No output beam data ...';
    }
    hds.cell( private.outputbeam );
    if ( hds.there( 'UVW' ) ) {
      private.uvw := hds.obtain( 'UVW' );
    } else {
      hds.done();
      fail '%% uvw: No uvw spatial frequencies of desired HDS object ...';
    }
    hds.done();
    return( T );
  }
  
  const private.loadtable := function( ) {
    fail '%% uvw: Aips++ table format not implemented yet ...';
  }

  
  # Define the 'done' member function
  
  const public.done := function( ) {
    wider private, public;
    val public := F;
    private := F;
    return( T );
  }
  
  
  # Define the 'file' member function
  
  const public.file := function( ) {
    wider private;
    return( private.file );
  }
  
  
  # Define the 'outputbeam' member function
  
  const public.outputbeam := function( ) {
    wider private;
    return( private.outputbeam );
  }
  
  
  # Define the 'baselineid' member function
  
  const public.baselineid := function( ) {
    wider private;
    return( private.baselineid );
  }
  
  
  # Define the 'baseline' member function
  
  const public.baseline := function( ) {
    wider private;
    return( private.baseline );
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
      if ( is_fail( private.dumphds( file ) ) ) {
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
      fail '%% uvw: Invalid format ...'
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
    fail '%% uvw: web() member function not implemented yet ...'
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
    dialog := label( top, 'GUI for uvw class not implemented yet ...' );
    dismiss := button( top, 'Dismiss' );
    whenever dismiss->press do {
      top := F;
    }
    return( T )
  }
  
  
  # Define the 'numspecchan' member function
  
  const public.numspecchan := function( ) {
    wider private;
    return( private.numspecchan );
  }
   
  
  # Define the 'spectrometerid' member function
  
  const public.spectrometerid := function( ) {
    wider private;
    return( private.spectrometerid );
  }
   
  
  # Define the 'wavelength' member function
  
  const public.wavelength := function( specchan = '' ) {
    wider private;
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% uvw: Invalid spectral channel(s) ...';
    }
    return( private.wavelength[specchan] );
  }
   
  
  # Define the 'wavelengtherr' member function
  
  const public.wavelengtherr := function( specchan = '' ) {
    wider private;
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% uvw: Invalid spectral channel(s) ...';
    }
    return( private.wavelengtherr[specchan] );
  }
  
  
  # Define the 'baselinevec' member function
  
  const public.baselinevec := function( starid ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% uvw: Invalid star ID ...';
    }
    scan := private.scaninfo.scan( starid );
    return( private.uvw[1,private.baseline,,scan] * private.wavelength[1] );
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
      fail '%% uvw: Invalid star ID ...';
    }
    return( private.scaninfo.scan( starid ) );
  }
  
  
  # Define the 'scanid' member function
  
  const public.scanid := function( starid ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% uvw: Invalid star ID ...';
    }
    return( private.scaninfo.scanid( starid ) );
  }
  
  
  # Define the 'scantime' member function
  
  const public.scantime := function( starid ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% uvw: Invalid star ID ...';
    }
    return( private.scaninfo.scantime( starid ) );
  }
  
  
  # Define the 'ra' member function
  
  const public.ra := function( starid ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% uvw: Invalid star ID ...';
    }
    return( private.scaninfo.ra( starid ) );
  }
  
  
  # Define the 'dec' member function
  
  const public.dec := function( starid ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% uvw: Invalid star ID ...';
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
  
  const public.u := function( starid, specchan = '' ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% uvw: Invalid star ID ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% uvw: Invalid spectral channel(s) ...';
    }
    scan := private.scaninfo.scan( starid );
    returnval := private.uvw[specchan,private.baseline,1,scan];
    returnval::shape := [length(specchan),length(scan)];
    return( returnval );
  }
  
  
  # Define the 'v' member function
  
  const public.v := function( starid, specchan = '' ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% uvw: Invalid star ID ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% uvw: Invalid spectral channel(s) ...';
    }
    scan := private.scaninfo.scan( starid );
    returnval := private.uvw[specchan,private.baseline,2,scan];
    returnval::shape := [length(specchan),length(scan)];
    return( returnval );
  }
  
  
  # Define the 'w' member function
  
  const public.w := function( starid, specchan = '' ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% uvw: Invalid star ID ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% uvw: Invalid spectral channel(s) ...';
    }
    scan := private.scaninfo.scan( starid );
    returnval := private.uvw[specchan,private.baseline,3,scan];
    returnval::shape := [length(specchan),length(scan)];
    return( returnval );
  }
  
  
  # Define the 'uv' member function
  
  const public.uv := function( starid, specchan = '' ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% uvw: Invalid star ID ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% uvw: Invalid spectral channel(s) ...';
    }
    scan := private.scaninfo.scan( starid );
    returnval := private.uvw[specchan,private.baseline,1:2,scan];
    returnval::shape := [length(specchan),2,length(scan)];
    return( returnval );
  }
  
  
  # Define the 'uvw' member function
  
  const public.uvw := function( starid, specchan = '' ) {
    wider private;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% uvw: Invalid star ID ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% uvw: Invalid spectral channel(s) ...';
    }
    scan := private.scaninfo.scan( starid );
    returnval := private.uvw[specchan,private.baseline,,scan];
    returnval::shape := [length(specchan),3,length(scan)];
    return( returnval );
  }
  
  
  # Define the 'getstar' member function
  
  const public.getstar := function( starid, specchan = '' ) {
    wider private, public;
    if ( !private.scaninfo.instar( starid ) ) {
      fail '%% uvw: Invalid star ID ...';
    }
    if ( !private.checkspecchan( specchan ) ) {
      fail '%% uvw: Invalid spectral channel(s) ...';
    }
    result := private.scaninfo.getstar( starid );
    result.starid := starid;
    result.outputbeam := private.outputbeam;
    result.baseline := private.baseline;
    result.baselineid := private.baselineid;
    result.numspecchan := length( specchan );
    result.specchan := specchan;
    result.spectrometerid := private.spectrometerid;
    result.wavelength := private.wavelength[specchan];
    result.wavelengtherr := private.wavelengtherr[specchan];
    result.baselinevec := public.baselinevec( starid );
    result.uvw := public.uvw( starid, specchan );
    return( result );
  }
  
  
  
  # Load the uvw spatial frequencies and return the uvw object
  
  public.load();

  return( ref public );

}
