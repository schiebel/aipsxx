# genconfig.g is part of Cuttlefish (NPOI data reduction package)
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
# $Id: genconfig.g,v 19.0 2003/07/16 06:02:00 aips2adm Exp $
# ------------------------------------------------------------------------------

# genconfig.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish class for manipulating general metrology
# configurations.

# glish class:
# ------------
# genconfig.

# Modification history:
# ---------------------
# 2000 Jan 20 - Nicholas Elias, USNO/NPOI
#               File created with glish class genconfig{ }.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'cuttlefish.g' ) {
  fail '%% genconfig: Cannot include cuttlefish.g ...';
}

# ------------------------------------------------------------------------------

# genconfig

# Description:
# ------------
# This glish class creates a genconfig object (interface) for manipulating
# general metrology configurations.

# Inputs:
# -------
# file           - The file name.
# format         - The file format ('ASCII', 'HDS', 'TABLE'; default = 'HDS').
# host           - The host name (default = '').
# forcenewserver - The 'force new server' flag (default = F).

# Outputs:
# --------
# The genconfig object, returned via the glish function value.

# Modification history:
# ---------------------
# 2000 Jan 20 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const genconfig := function( file, format = 'HDS', host = '',
    forcenewserver = F ) {
  
  # Initialize the variables
  
  top := F;

  private := [=];
  public := [=];
  
  
  # Fix and check the inputs
  
  if ( !cs( file ) ) {
    fail '%% genconfig: Invalid file name ...';
  }
  
  private.file := file;
  
  format := to_upper( format );
  for ( f in 1:length( format_const ) ) {
    if ( format == format_const[f] ) {
      break;
    }
  }
  
  if ( f > length( format_const ) ) {
    fail '%% genconfig: Invalid file format ...';
  }
  
  private.format := format;
  
  if ( !cs( host ) ) {
    fail '%% genconfig: Invalid host ...';
  }
  
  private.host := host;
  
  if ( !is_boolean( forcenewserver ) ) {
    fail '%% genconfig: Invalid \'force-new-server\' boolean flag ...';
  }
  
  private.forcenewserver := forcenewserver;
  
  
  # Create the private functions for dumping the general metrology
  # configuration
  
  const private.dumpascii := function( replace = F ) {
    fail '%% genconfig: ASCII format not implemented yet ...';
  }
  
  const private.dumphds := function( file, replace = F ) {
    wider private;
    if ( is_fail( hds := hdsopen( file, F, host = private.host,
        forcenewserver = private.forcenewserver ) ) ) {
      fail '%% genconfig: Could not dump general metrology configuration to HDS file ...';
    }
    if ( !hds.there( 'GenConfig' ) ) {
      hds.new( 'GenConfig', '', 0 );
    }
    hds.find( 'GenConfig' );
    if ( hds.ncomp() > 0 && !replace ) {
      hds.done();
      fail '%% genconfig: Cannot overwrite general metrology configuration ...';
    }
    hds.screate( 'NumPlate', '_INTEGER', private.numplate, replace );
    if ( private.numplate > 0 ) {
      type := spaste( '_CHAR*', length( split( private.masterplateid, '' ) ) );
      hds.screate( 'MasterPlateID', type, private.masterplateid, replace );
      hds.new( 'Plate', '', private.numplate, replace );
      hds.find( 'Plate' );
      for ( p in 1:private.numplate ) {
        hds.cell( p );
        hds.screate( 'NumCluster', '_INTEGER', private.numcluster[p], replace );
        hds.screate( 'PlateEmbedded', '_INTEGER', private.plateembedded[p],
            replace );
        type := spaste( '_CHAR*', length( split( private.plateid[p], '' ) ) );
        hds.screate( 'PlateID', type, private.plateid[p], replace );
        hds.create( 'PlateLoc', '_DOUBLE', private.plateloc[p,], replace );
        hds.create( 'PlateLocErr', '_DOUBLE', private.platelocerr[p,],
            replace );
        hds.annul();
      }
      hds.annul();
      hds.screate( 'NumLaserP2P', '_INTEGER', private.numlaserp2p, replace );
      hds.create( 'P2PLaunchPlate', '_INTEGER', private.p2plaunchplate,
          replace );
      hds.create( 'P2PRetroPlate', '_INTEGER', private.p2pretroplate, replace );
    }
    hds.new( 'InputBeam', '', 0, replace );
    hds.find( 'InputBeam' );
    hds.screate( 'NumSid', '_INTEGER', private.numsid, replace );
    if ( private.numsid > 0 ) {
      hds.create( 'SiderostatID', '_INTEGER', private.sidembedded, replace );
    }
    hds.done();
    return( T );
  }
  
  const private.dumptable := function( replace = F ) {
    fail '%% genconfig: Aips++ table format not implemented yet ...';
  }
  
  
  # Create the private functions for loading the general metrology
  # configuration
  
  const private.loadascii := function( ) {
    fail '%% genconfig: ASCII format not implemented yet ...';
  }
  
  const private.loadhds := function( ) {
    wider private;
    if ( is_fail( hds := hdsopen( private.file, host = private.host,
        forcenewserver = private.forcenewserver ) ) ) {
      fail '%% genconfig: Could not load general metrology configuration from HDS file ...';
    }
    hds.find( 'GenConfig' );
    private.numplate := hds.obtain( 'NumPlate' );
    if ( private.numplate > 0 ) {
      private.masterplateid := hds.obtain( 'MasterPlateID' );
      hds.find( 'Plate' );
      private.plateloc := array( 0.0, private.numplate, 3 );
      private.platelocerr := array( 0.0, private.numplate, 3 );
      for ( p in 1:private.numplate ) {
        hds.cell( p );
        private.numcluster[p] := hds.obtain( 'NumCluster' );
        private.plateembedded[p] := hds.obtain( 'PlateEmbedded' );
        private.plateid[p] := hds.obtain( 'PlateID' );
        private.plateloc[p,] := hds.obtain( 'PlateLoc' );
        private.platelocerr[p,] := hds.obtain( 'PlateLocErr' );
        hds.annul();
      }
      hds.annul();
      private.numlaserp2p := hds.obtain( 'NumLaserP2P' );
      private.p2plaunchplate := hds.obtain( 'P2PLaunchPlate' );
      private.p2pretroplate := hds.obtain( 'P2PRetroPlate' );
    }
    hds.find( 'InputBeam' );
    private.numsid := hds.obtain( 'NumSid' );
    if ( private.numsid > 0 ) {
      private.sidembedded := hds.obtain( 'SiderostatID' );
    }
    hds.done();
    return( T );
  }
  
  const private.loadtable := function( ) {
    fail '%% genconfig: Aips++ table format not implemented yet ...';
  }
  
  
  # Create the private functions for checking inputs to public member functions
  
  const private.checkplate1 := function( plate ) {
    wider private;
    if ( !is_integer( plate ) ) {
      return( F );
    }
    if ( length( plate ) != 1 ) {
      return( F );
    }
    if ( plate < 1 || plate > private.numplate ) {
      return( F );
    }
    return( T );
  }
  
  const private.checklaserp2p1 := function( laserp2p ) {
    wider private;
    if ( !is_integer( laserp2p ) ) {
      return( F );
    }
    if ( length( laserp2p ) != 1 ) {
      return( F );
    }
    if ( laserp2p < 1 || laserp2p > private.numlaserp2p ) {
      return( F );
    }
    return( T );
  }
  
  const private.checksid1 := function( sid ) {
    wider private;
    if ( !is_integer( sid ) ) {
      return( F );
    }
    if ( length( sid ) != 1 ) {
      return( F );
    }
    if ( sid < 1 || sid > private.numsid ) {
      return( F );
    }
    return( T );
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
  
  const public.dump := function( file, format = 'HDS', replace = F ) {
    wider private;
    if ( !is_boolean( replace ) ) {
      fail '%% genconfig: Invalid replace flag ...';
    }
    if ( format == 'ASCII' ) {
      if ( is_fail( private.dumpascii( file, replace ) ) ) {
        fail;
      } else {
        return( T );
      }
    } else if ( format == 'HDS' ) {
      if ( is_fail( private.dumphds( file, replace ) ) ) {
        fail;
      } else {
        return( T );
      }
    } else if ( format == 'TABLE' ) {
      if ( is_fail( private.dumptable( file, replace ) ) ) {
        fail;
      } else {
        return( T );
      }
    } else {
      fail '%% genconfig: Invalid format ...'
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
    fail '%% genconfig: web() member function not implemented yet ...'
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
    dialog := label( top, 'GUI for genconfig class not implemented yet ...' );
    dismiss := button( top, 'Dismiss' );
    whenever dismiss->press do {
      top := F;
    }
    return( T )
  }
  
  
  # Define the 'numplate' member function
  
  const public.numplate := function( ) {
    wider private;
    return( private.numplate );
  }
  
  
  # Define the 'numlaserp2p' member function
  
  const public.numlaserp2p := function( ) {
    wider private;
    if ( private.numplate < 1 ) {
      fail '%% genconfig: No plates ...';
    }
    return( private.numlaserp2p );
  }
  
  
  # Define the 'numsid' member function
  
  const public.numsid := function( ) {
    wider private;
    return( private.numsid );
  }
  
  
  # Define the 'masterplate' member function
  
  const public.masterplate := function( ) {
    wider private;
    if ( private.numplate < 1 ) {
      fail '%% genconfig: No plates ...';
    }
    for ( p in 1:private.numplate ) {
      if ( private.plateid[p] == private.masterplateid ) {
        return( p );
      }
    }
    fail '%% genconfig: Error determining master plate number ...';
  }
  
  
  # Define the 'masterplateid' member function
  
  const public.masterplateid := function( ) {
    wider private;
    if ( private.numplate < 1 ) {
      fail '%% genconfig: No plates ...';
    }
    return( private.masterplateid );
  }

  
  # Define the 'numcluster' member function
  
  const public.numcluster := function( plate = '' ) {
    wider private;
    if ( private.numplate < 1 ) {
      fail '%% genconfig: No plates ...';
    }
    if ( plate == '' ) {
      return( private.numcluster );
    } else {
      if ( private.checkplate1( plate ) ) {
        return( private.numcluster[plate] );
      } else {
        fail '%% genconfig: Invalid plate number ...';
      }
    }
  }

  
  # Define the 'plateembedded' member function
  
  const public.plateembedded := function( plate = '' ) {
    wider private;
    if ( private.numplate < 1 ) {
      fail '%% genconfig: No plates ...';
    }
    if ( plate == '' ) {
      return( private.plateembedded );
    } else {
      if ( private.checkplate1( plate ) ) {
        return( private.plateembedded[plate] );
      } else {
        fail '%% genconfig: Invalid plate number ...';
      }
    }
  }

  
  # Define the 'plateid' member function
  
  const public.plateid := function( plate = '' ) {
    wider private;
    if ( private.numplate < 1 ) {
      fail '%% genconfig: No plates ...';
    }
    if ( plate == '' ) {
      return( private.plateid );
    } else {
      if ( private.checkplate1( plate ) ) {
        return( private.plateid[plate] );
      } else {
        fail '%% genconfig: Invalid plate number ...';
      }
    }
  }

  
  # Define the 'plateloc' member function
  
  const public.plateloc := function( plate ) {
    wider private;
    if ( private.numplate < 1 ) {
      fail '%% genconfig: No plates ...';
    }
    if ( private.checkplate1( plate ) ) {
      return( private.plateloc[plate,] );
    } else {
      fail '%% genconfig: Invalid plate number ...';
    }
  }

  
  # Define the 'platelocerr' member function
  
  const public.platelocerr := function( plate ) {
    wider private;
    if ( private.numplate < 1 ) {
      fail '%% genconfig: No plates ...';
    }
    if ( private.checkplate1( plate ) ) {
      return( private.platelocerr[plate,] );
    } else {
      fail '%% genconfig: Invalid plate number ...';
    }
  }
  
  
  # Define the 'p2plaunchplate' member function
  
  const public.p2plaunchplate := function( laserp2p = '' ) {
    wider private;
    if ( private.numlaserp2p < 1 ) {
      fail '%% genconfig: No pier-to-pier laser interferometers ...';
    }
    if ( laserp2p == '' ) {
      return( private.p2plaunchplate );
    } else {
      if ( private.checklaserp2p1( laserp2p ) ) {
        return( private.p2plaunchplate[laserp2p] );
      } else {
        fail '%% genconfig: Invalid pier-to-pier laser interferometer number ...';
      }
    }
  }
  
  
  # Define the 'p2pretroplate' member function
  
  const public.p2pretroplate := function( laserp2p = '' ) {
    wider private;
    if ( private.numlaserp2p < 1 ) {
      fail '%% genconfig: No pier-to-pier laser interferometers ...';
    }
    if ( laserp2p == '' ) {
      return( private.p2pretroplate );
    } else {
      if ( private.checklaserp2p1( laserp2p ) ) {
        return( private.p2pretroplate[laserp2p] );
      } else {
        fail '%% genconfig: Invalid pier-to-pier laser interferometer number ...';
      }
    }
  }
  
  
  # Define the 'p2plaunchlaser' member function
  
  const public.p2plaunchlaser := function( plate ) {
    wider private;
    if ( private.numplate < 1 ) {
      fail '%% genconfig: No plates ...';
    }
    if ( private.checkplate1( plate ) ) {
      flag := F;
      l2 := 0;
      for ( l in 1:private.numlaserp2p ) {
        if ( private.p2plaunchplate[l] == plate ) {
          flag := T;
          l2 +:= 1;
          launchlaser[l2] := l;
        }
      }
      if ( flag ) {
        return( launchlaser );
      } else {
        return( 0 );
      }
    } else {
      fail '%% genconfig: Invalid plate number ...';
    }
  }
  
  
  # Define the 'p2pretrolaser' member function
  
  const public.p2pretrolaser := function( plate ) {
    wider private;
    if ( private.numplate < 1 ) {
      fail '%% genconfig: No plates ...';
    }
    if ( private.checkplate1( plate ) ) {
      flag := F;
      l2 := 0;
      for ( l in 1:private.numlaserp2p ) {
        if ( private.p2pretroplate[l] == plate ) {
          flag := T;
          l2 +:= 1;
          retrolaser[l2] := l;
        }
      }
      if ( flag ) {
        return( retrolaser );
      } else {
        return( 0 );
      }
    } else {
      fail '%% genconfig: Invalid plate number ...';
    }
  }

  
  # Define the 'sidembedded' member function
  
  const public.sidembedded := function( sid = '' ) {
    wider private;
    if ( private.numsid < 1 ) {
      fail '%% genconfig: No siderostats ...';
    }
    if ( sid == '' ) {
      return( private.sidembedded );
    } else {
      if ( private.checksid1( sid ) ) {
        return( private.sidembedded[sid] );
      } else {
        fail '%% genconfig: Invalid siderostat number ...';
      }
    }
  }
  
  
  # Load the general metrology configuration and return the genconfig object
  
  public.load();

  return( ref public );

}
