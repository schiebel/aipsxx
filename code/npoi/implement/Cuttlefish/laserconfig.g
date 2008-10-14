# laserconfig.g is part of Cuttlefish (NPOI data reduction package)
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
# $Id: laserconfig.g,v 19.0 2003/07/16 06:02:08 aips2adm Exp $
# ------------------------------------------------------------------------------

# laserconfig.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish class for manipulating laser interferometer
# configurations.

# glish class:
# ------------
# laserconfig.

# Modification history:
# ---------------------
# 1999 Sep 07 - Nicholas Elias, USNO/NPOI
#               File created with glish class laserconfig{ }.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'cuttlefish.g' ) {
  fail '%% laserconfig: Cannot include cuttlefish.g ...';
}

# ------------------------------------------------------------------------------

# laserconfig

# Description:
# ------------
# This glish class creates a laserconfig object (interface) for manipulating
# laser interferometer configurations.

# Inputs:
# -------
# file           - The file name.
# subsystem      - The subsystem (no configid = 'PIER2PIER'; 1-D configid =
#                  'SIDMET', 'EXTCATEYE', 'PLATEEXP', 'CONSTTERM'; 2-D
#                  configid = 'OPTANCH').
# configid       - The laser interferometer configuration ID (specify '' for
#                  pier2pier-like subsystems, N for sidmet-like systems, and
#                  [M,N] for optanch-like systems).
# format         - The file format ('ASCII', 'HDS', 'TABLE'; default = 'HDS').
# host           - The host name (default = '').
# forcenewserver - The 'force new server' flag (default = F).

# Outputs:
# --------
# The laserconfig object, returned via the glish function value.

# Modification history:
# ---------------------
# 1999 Sep 07 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const laserconfig := function( file, subsystem, configid, format = 'HDS',
    host = '', forcenewserver = F ) {
  
  # Initialize the variables
  
  top := F;
  
  subsystemlist := array( '', 3 );
  subsystemlist[1] := 'PIER2PIER';
  subsystemlist[2] := 'SIDMET EXTCATEYE PLATEEXP CONSTTERM';
  subsystemlist[3] := 'OPTANCH';

  private := [=];
  public := [=];
  
  
  # Fix and check the inputs
  
  if ( !cs( file ) ) {
    fail '%% laserconfig: Invalid file name ...';
  }
  
  private.file := file;
  
  format := to_upper( format );
  for ( f in 1:length( format_const ) ) {
    if ( format == format_const[f] ) {
      break;
    }
  }
  
  if ( f > length( format_const ) ) {
    fail '%% laserconfig: Invalid file format ...';
  }
  
  private.format := format;
  
  if ( !cs( host ) ) {
    fail '%% laserconfig: Invalid host ...';
  }
  
  private.host := host;
  
  if ( !is_boolean( forcenewserver ) ) {
    fail '%% laserconfig: Invalid \'force-new-server\' boolean flag ...';
  }
  
  private.forcenewserver := forcenewserver;
  
  flag := F;
  subsystem := to_upper( subsystem );
  
  for ( s1 in 1:3 ) {
    subsystemlisttemp := split( subsystemlist[s1] );
    for ( s2 in 1:length( subsystemlisttemp ) ) {
      if ( subsystem == subsystemlisttemp[s2] ) {
        flag := T;
        break;
      }
    }
    if ( flag ) {
      break;
    }
  }
  
  if ( s1 > 3 ) {
    fail '%% laserconfig: Invalid subsystem ...';
  }
  
  private.subsystem := subsystem;
  
  if ( length( configid ) + 1 != s1 ) {
    fail '%% laserconfig: Invalid laser interferometer ID(s) ...';
  }
  
  private.configid := configid;
  
  
  # Do further checking of inputs and initialize related variables
  
  genConfigTemp := genconfig( private.file, private.format, private.host,
      private.forcenewserver );
  
  if ( configid == '' ) {
  
    private.pathshort :=
        to_upper( paste( private.subsystem, 'Config', sep = '' ) );
    private.configidmax := '';
    private.plate := 0;
    private.cluster := 0;
    private.path := to_upper( paste( 'Session', '.', 'MetroConfig', '.',
        private.subsystem, 'Config', sep = '' ) );

  } else if ( length( configid ) == 1 ) {

    private.pathshort :=
        to_upper( paste( private.subsystem, 'Config', sep = '' ) );
    numplate := genConfigTemp.numplate();
    if ( configid[1] < 1 || configid[1] > numplate ) {
      genConfigTemp.done();
      fail '%% laser: Invalid plate number ...';
    }
    private.configidmax := numplate;
    private.plate := configid[1];
    private.cluster := 0;
    private.path := to_upper( paste( 'Session', '.', 'MetroConfig', '.',
        private.subsystem, 'Config(', configid[1], ')', sep = '' ) );

  } else {

    private.pathshort :=
        to_upper( paste( private.subsystem, 'Config', sep = '' ) );
    numplate := genConfigTemp.numplate();
    if ( configid[1] < 1 || configid[1] > numplate ) {
      genConfigTemp.done();
      fail '%% laser: Invalid plate number ...';
    }
    numcluster := genConfigTemp.numcluster( configid[1] );
    if ( configid[2] < 1 || configid[2] > numcluster ) {
      genConfigTemp.done();
      fail '%% laser: Invalid cluster number ...';
    }
    private.configidmax := [numplate,numcluster];
    private.plate := configid[1];
    private.cluster := configid[2];
    private.path := to_upper( paste( 'Session', '.', 'MetroConfig', '.',
        private.subsystem, 'Config(', configid[1], ',', configid[2], ')',
        sep = '' ) );

  }
  
  genConfigTemp.done();
  
  
  # Create the private functions for dumping the laser interferometer
  # configuration
  
  const private.dumpascii := function( replace = F ) {
    fail '%% laserconfig: ASCII format not implemented yet ...';
  }
  
  const private.dumphds := function( file, replace = F ) {
    wider private;
    if ( is_fail( hds := hdsopen( file, F, host = private.host,
        forcenewserver = private.forcenewserver ) ) ) {
      fail '%% laserconfig: Could not dump laser interferometer configuration to HDS file ...';
    }
    if ( !hds.there( 'MetroConfig' ) ) {
      hds.new( 'MetroConfig', '', 0 );
    }
    hds.find( 'MetroConfig' );
    if ( !hds.there( private.pathshort ) ) {
      if ( !is_integer( private.configidmax ) ) {
        hds.new( private.pathshort, '', 0 );
      } else {
        hds.new( private.pathshort, '', private.configidmax );
      }
    }
    hds.find( private.pathshort );
    if ( is_integer( private.configid ) ) {
      hds.cell( private.configid );
    }
    if ( hds.ncomp() > 0 && !replace ) {
      hds.done();
      fail '%% laserconfig: Cannot overwrite laser interferometer configuration ...';
    }
    hds.screate( 'NumLaser', '_INTEGER', private.numlaser, replace );
    hds.screate( 'PacketNumber', '_INTEGER', private.packetnumber, replace );
    if ( private.numlaser < 1 ) {
      hds.done();
      return( T );
    }
    hds.screate( 'CountsPerWaveln', '_INTEGER', private.countsperwaveln,
        replace );
    hds.screate( 'LaserWavelength', '_DOUBLE', private.laserwavelength,
        replace );
    hds.screate( 'SampleInterval', '_INTEGER', private.sampleinterval,
        replace );
    hds.screate( 'BitsPerDatum', '_INTEGER', private.bitsperdatum, replace );
    hds.create( 'IFBox', '_INTEGER', private.ifbox, replace );
    hds.create( 'Channel', '_INTEGER', private.channel, replace );
    hds.create( 'Theta', '_DOUBLE', private.theta, replace );
    hds.create( 'ThetaErr', '_DOUBLE', private.thetaerr, replace );
    hds.create( 'Phi', '_DOUBLE', private.phi, replace );
    hds.create( 'PhiErr', '_DOUBLE', private.phierr, replace );
    hds.new( 'LaunchInfo', '', private.numlaser, replace );
    hds.find( 'LaunchInfo' );
    for ( l in 1:private.numlaser ) {
      hds.cell( l );
      hds.create( 'Loc', '_DOUBLE', private.launch[l].loc, replace );
      hds.create( 'LocErr', '_DOUBLE', private.launch[l].locerr, replace );
      hds.screate( 'NumAirGap', '_INTEGER', private.launch[l].numairgap,
          replace );
      if ( private.launch[l].numairgap > 0 ) {
        hds.create( 'AirGapThick', '_DOUBLE', private.launch[l].airgapthick,
            replace );
        hds.create( 'AirGapThickErr', '_DOUBLE',
            private.launch[l].airgapthickerr, replace );
      }
      hds.screate( 'NumGlass', '_INTEGER', private.launch[l].numglass,
          replace );
      if ( private.launch[l].numglass > 0 ) {
        hds.create( 'GlassThick', '_DOUBLE', private.launch[l].glassthick,
            replace );
        hds.create( 'GlassThickErr', '_DOUBLE',
            private.launch[l].glassthickerr, replace );
        hds.create( 'GlassCode', '_INTEGER', private.launch[l].glasscode,
            replace );
        hds.create( 'ExFrac', '_DOUBLE', private.launch[l].exfrac, replace );
        hds.create( 'ExFracErr', '_DOUBLE', private.launch[l].exfracerr,
            replace );
      }
      hds.annul();
    }
    hds.annul();
    hds.new( 'RetroInfo', '', private.numlaser, replace );
    hds.find( 'RetroInfo' );
    for ( l in 1:private.numlaser ) {
      hds.cell( l );
      hds.create( 'Loc', '_DOUBLE', private.retro[l].loc, replace );
      hds.create( 'LocErr', '_DOUBLE', private.retro[l].locerr, replace );
      hds.screate( 'NumAirGap', '_INTEGER', private.retro[l].numairgap,
          replace );
      if ( private.retro[l].numairgap > 0 ) {
        hds.create( 'AirGapThick', '_DOUBLE', private.retro[l].airgapthick,
            replace );
        hds.create( 'AirGapThickErr', '_DOUBLE',
            private.retro[l].airgapthickerr, replace );
      }
      hds.screate( 'NumGlass', '_INTEGER', private.retro[l].numglass, replace );
      if ( private.retro[l].numglass > 0 ) {
        hds.create( 'GlassThick', '_DOUBLE', private.retro[l].glassthick,
            replace );
        hds.create( 'GlassThickErr', '_DOUBLE',
            private.retro[l].glassthickerr, replace );
        hds.create( 'GlassCode', '_INTEGER', private.retro[l].glasscode,
            replace );
        hds.create( 'ExFrac', '_DOUBLE', private.retro[l].exfrac, replace );
        hds.create( 'ExFracErr', '_DOUBLE', private.retro[l].exfracerr,
            replace );
      }
      hds.annul();
    }
    hds.done();
    return( T );
  }
  
  const private.dumptable := function( replace = F ) {
    fail '%% laserconfig: Aips++ table format not implemented yet ...';
  }
  
  
  # Create the private functions for loading the laser interferometer
  # configuration
  
  const private.loadascii := function( ) {
    fail '%% laserconfig: ASCII format not implemented yet ...';
  }
  
  const private.loadhds := function( ) {
    wider private;
    if ( is_fail( hds := hdsopen( private.file, host = private.host,
        forcenewserver = private.forcenewserver ) ) ) {
      fail '%% laserconfig: Could not load laser interferometer configuration from HDS file ...';
    }
    hds.goto( private.path );
    private.numlaser := hds.obtain( 'NumLaser' );
    if ( private.numlaser < 1 ) {
      hds.done();
      return( T );
    }
    private.packetnumber := hds.obtain( 'PacketNumber' );
    private.countsperwaveln := hds.obtain( 'CountsPerWaveln' );
    private.laserwavelength := hds.obtain( 'LaserWavelength' );
    private.sampleinterval := hds.obtain( 'SampleInterval' );
    private.bitsperdatum := hds.obtain( 'BitsPerDatum' );
    private.ifbox := hds.obtain( 'IFBox' );
    private.channel := hds.obtain( 'Channel' );
    private.theta := hds.obtain( 'Theta' );
    private.thetaerr := hds.obtain( 'ThetaErr' );
    private.phi := hds.obtain( 'Phi' );
    private.phierr := hds.obtain( 'PhiErr' );
    private.launch := [=];
    hds.find( 'LaunchInfo' );
    for ( l in 1:private.numlaser ) {
      hds.cell( l );
      private.launch[l] := [=];
      private.launch[l].loc := hds.obtain( 'Loc' );
      private.launch[l].locerr := hds.obtain( 'LocErr' );
      private.launch[l].numairgap := hds.obtain( 'NumAirGap' );
      if ( private.launch[l].numairgap > 0 ) {
        private.launch[l].airgapthick := hds.obtain( 'AirGapThick' );
        private.launch[l].airgapthickerr := hds.obtain( 'AirGapThickErr' );
      }
      private.launch[l].numglass := hds.obtain( 'NumGlass' );
      if ( private.launch[l].numglass > 0 ) {
        private.launch[l].glassthick := hds.obtain( 'GlassThick' );
        private.launch[l].glassthickerr := hds.obtain( 'GlassThickErr' );
        private.launch[l].glasscode := hds.obtain( 'GlassCode' );
        private.launch[l].exfrac := hds.obtain( 'ExFrac' );
        private.launch[l].exfracerr := hds.obtain( 'ExFracErr' );
      }
      hds.annul();
    }
    hds.annul();
    private.retro := [=];
    hds.find( 'RetroInfo' );
    for ( l in 1:private.numlaser ) {
      hds.cell( l );
      private.retro[l] := [=];
      private.retro[l].loc := hds.obtain( 'Loc' );
      private.retro[l].locerr := hds.obtain( 'LocErr' );
      private.retro[l].numairgap := hds.obtain( 'NumAirGap' );
      if ( private.retro[l].numairgap > 0 ) {
        private.retro[l].airgapthick := hds.obtain( 'AirGapThick' );
        private.retro[l].airgapthickerr := hds.obtain( 'AirGapThickErr' );
      }
      private.retro[l].numglass := hds.obtain( 'NumGlass' );
      if ( private.retro[l].numglass > 0 ) {
        private.retro[l].glassthick := hds.obtain( 'GlassThick' );
        private.retro[l].glassthickerr := hds.obtain( 'GlassThickErr' );
        private.retro[l].glasscode := hds.obtain( 'GlassCode' );
        private.retro[l].exfrac := hds.obtain( 'ExFrac' );
        private.retro[l].exfracerr := hds.obtain( 'ExFracErr' );
      }
      hds.annul();
    }
    hds.done();
    return( T );
  }
  
  const private.loadtable := function( ) {
    fail '%% laserconfig: Aips++ table format not implemented yet ...';
  }
  
  
  # Create the private functions for checking inputs to public member functions
  
  const private.checklaser1 := function( laser ) {
    wider private;
    if ( !is_integer( laser ) ) {
      return( F );
    }
    if ( length( laser ) != 1 ) {
      return( F );
    }
    if ( laser < 1 || laser > private.numlaser ) {
      return( F );
    }
    return( T );
  }
  
  const private.checklaser := function( laser ) {
    wider private;
    numlaser := length( laser );
    for ( l in 1:numlaser ) {
      if ( !private.checklaser1( laser[l] ) ) {
        return( F );
      }
    }
    if ( numlaser == 1 ) {
      return( T );
    }
    for ( l1 in 1:(numlaser-1) ) {
      for ( l2 in (l1+1):numlaser ) {
        if ( laser[l1] == laser[l2] ) {
          return( F );
        }
      }
    }
    return( T );
  }
  
  const private.checkend := function( ref end ) {
    if ( !is_string( val end ) ) {
      return( F );
    }
    val end := split( to_upper( val end ), '' )[1];
    if ( val end == 'L' || val end == 'R' ) {
      return( T );
    } else {
      return( F );
    }
  }
  
  const private.checkairgap := function( laser, end, airgap ) {
    wider private;
    if ( !private.checklaser1( laser ) ) {
      return( F );
    }
    if ( !private.checkend( end ) ) {
      return( F );
    }
    if ( !is_integer( airgap ) ) {
      return( F );
    }
    numairgap := length( airgap );
    if ( end == 'L' ) {
      for ( a in 1:numairgap ) {
        if ( airgap[a] < 1 || airgap[a] > private.launch[laser].numairgap ) {
          return( F );
        }
      }
    } else {
      for ( a in 1:numairgap ) {
        if ( airgap[a] < 1 || airgap[a] > private.retro[laser].numairgap ) {
          return( F );
        }
      }
    }
    for ( a1 in 1:(numairgap-1) ) {
      for ( a2 in (a1+1):numairgap ) {
        if ( airgap[a1] == airgap[a2] ) {
          return( F );
        }
      }
    }
    return( T );
  }
  
  const private.checkglass := function( laser, end, glass ) {
    wider private;
    if ( !private.checklaser1( laser ) ) {
      return( F );
    }
    if ( !private.checkend( end ) ) {
      return( F );
    }
    if ( !is_integer( glass ) ) {
      return( F );
    }
    numglass := length( glass );
    if ( end == 'L' ) {
      for ( g in 1:numglass ) {
        if ( glass[g] < 1 || glass[g] > private.launch[laser].numglass ) {
          return( F );
        }
      }
    } else {
      for ( g in 1:numglass ) {
        if ( glass[g] < 1 || glass[g] > private.retro[laser].numglass ) {
          return( F );
        }
      }
    }
    for ( g1 in 1:(numglass-1) ) {
      for ( g2 in (g1+1):numglass ) {
        if ( glass[g1] == glass[g2] ) {
          return( F );
        }
      }
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
  
  
  # Define the 'subsystem' member function
  
  const public.subsystem := function( ) {
    wider private;
    return( private.subsystem );
  }
  
  
  # Define the 'configid' member function
  
  const public.configid := function( ) {
    wider private;
    return( private.configid );
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
      fail '%% laserconfig: Invalid replace flag ...';
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
      fail '%% laserconfig: Invalid format ...'
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
    fail '%% laserconfig: web() member function not implemented yet ...'
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
    dialog := label( top, 'GUI for laserconfig class not implemented yet ...' );
    dismiss := button( top, 'Dismiss' );
    whenever dismiss->press do {
      top := F;
    }
    return( T )
  }
    
  
  # Define the 'plate' member function
  
  const public.plate := function( ) {
    wider private;
    return( private.plate );
  }

  
  # Define the 'cluster' member function
  
  const public.cluster := function( ) {
    wider private;
    return( private.cluster );
  }
  
  
  # Define the 'path' member function
  
  const public.path := function( ) {
    wider private;
    return( private.path );
  }
  
  
  # Define the 'numlaser' member function
  
  const public.numlaser := function( ) {
    wider private;
    return( private.numlaser );
  }
  
  
  # Define the 'packetnumber' member function
  
  const public.packetnumber := function( ) {
    wider private;
    return( sprintf( '0x%04X', private.packetnumber ) );
  }
  
  
  # Define the 'countsperwaveln' member function
  
  const public.countsperwaveln := function( ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    return( private.countsperwaveln );
  }
  
  
  # Define the 'laserwavelength' member function
  
  const public.laserwavelength := function( ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    return( private.laserwavelength );
  }
  
  
  # Define the 'sampleinterval' member function
  
  const public.sampleinterval := function( ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    return( private.sampleinterval );
  }
  
  
  # Define the 'bitsperdatum' member function
  
  const public.bitsperdatum := function( ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    return( private.bitsperdatum );
  }
  
  
  # Define the 'ifbox' member function
  
  const public.ifbox := function( laser = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( laser == '' ) {
      return( private.ifbox );
    } else {
      if ( private.checklaser( laser ) ) {
        return( private.ifbox[laser] );
      } else {
        fail '%% laserconfig: Invalid laser interferometer number(s) ...';
      }
    }
  }
  
  
  # Define the 'channel' member function
  
  const public.channel := function( laser = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( laser == '' ) {
      return( private.channel );
    } else {
      if ( private.checklaser( laser ) ) {
        return( private.channel[laser] );
      } else {
        fail '%% laserconfig: Invalid laser interferometer number(s) ...';
      }
    }
  }
  
  
  # Define the 'theta' member function
  
  const public.theta := function( laser = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( laser == '' ) {
      return( private.theta );
    } else {
      if ( private.checklaser( laser ) ) {
        return( private.theta[laser] );
      } else {
        fail '%% laserconfig: Invalid laser interferometer number(s) ...';
      }
    }
  }
   
  
  # Define the 'thetaerr' member function
  
  const public.thetaerr := function( laser = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( laser == '' ) {
      return( private.thetaerr );
    } else {
      if ( private.checklaser( laser ) ) {
        return( private.thetaerr[laser] );
      } else {
        fail '%% laserconfig: Invalid laser interferometer number(s) ...';
      }
    }
  }
   
  
  # Define the 'phi' member function
  
  const public.phi := function( laser = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( laser == '' ) {
      return( private.phi );
    } else {
      if ( private.checklaser( laser ) ) {
        return( private.phi[laser] );
      } else {
        fail '%% laserconfig: Invalid laser interferometer number(s) ...';
      }
    }
  }
   
  
  # Define the 'phierr' member function
  
  const public.phierr := function( laser = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( laser == '' ) {
      return( private.phierr );
    } else {
      if ( private.checklaser( laser ) ) {
        return( private.phierr[laser] );
      } else {
        fail '%% laserconfig: Invalid laser interferometer number(s) ...';
      }
    }
  }
  
  
  # Define the 'loc' member function
  
  const public.loc := function( laser, end ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( !private.checklaser1( laser ) ) {
      fail '%% laserconfig: Invalid laser interferometer number ...';
    }
    if ( !private.checkend( end ) ) {
      fail '%% laserconfig: Invalid end ...';
    }
    if ( end == 'L' ) {
      return( private.launch[laser].loc );
    } else {
      return( private.retro[laser].loc );
    }
  }
  
  
  # Define the 'locerr' member function
  
  const public.locerr := function( laser, end ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( !private.checklaser1( laser ) ) {
      fail '%% laserconfig: Invalid laser interferometer number ...';
    }
    if ( !private.checkend( end ) ) {
      fail '%% laserconfig: Invalid end ...';
    }
    if ( end == 'L' ) {
      return( private.launch[laser].locerr );
    } else {
      return( private.retro[laser].locerr );
    }
  }
  
  
  # Define the 'numairgap' member function
  
  const public.numairgap := function( laser, end ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( !private.checklaser1( laser ) ) {
      fail '%% laserconfig: Invalid laser interferometer number ...';
    }
    if ( !private.checkend( end ) ) {
      fail '%% laserconfig: Invalid end ...';
    }
    if ( end == 'L' ) {
      return( private.launch[laser].numairgap );
    } else {
      return( private.retro[laser].numairgap );
    }
  }
  
  
  # Define the 'airgapthick' member function
  
  const public.airgapthick := function( laser, end, airgap = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( !private.checklaser1( laser ) ) {
      fail '%% laserconfig: Invalid laser interferometer number ...';
    }
    if ( !private.checkend( end ) ) {
      fail '%% laserconfig: Invalid end ...';
    }
    if ( end == 'L' ) {
      if ( private.launch[laser].numairgap < 1 ) {
        fail '%% laserconfig: No air gaps ...';
      }
      if ( airgap == '' ) {
        return( private.launch[laser].airgapthick );
      } else {
        if ( private.checkairgap( laser, end, airgap ) ) {
          return( private.launch[laser].airgapthick[airgap] );
        } else {
          fail '%% laserconfig: Invalid air gap number(s) ...';
        }
      }
    } else {
      if ( private.retro[laser].numairgap < 1 ) {
        fail '%% laserconfig: No air gaps ...';
      }
      if ( airgap == '' ) {
        return( private.retro[laser].airgapthick );
      } else {
        if ( private.checkairgap( laser, end, airgap ) ) {
          return( private.retro[laser].airgapthick[airgap] );
        } else {
          fail '%% laserconfig: Invalid air gap number(s) ...';
        }
      }
    }
  }
  
  
  # Define the 'airgapthickerr' member function
  
  const public.airgapthickerr := function( laser, end, airgap = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( !private.checklaser1( laser ) ) {
      fail '%% laserconfig: Invalid laser interferometer number ...';
    }
    if ( !private.checkend( end ) ) {
      fail '%% laserconfig: Invalid end ...';
    }
    if ( end == 'L' ) {
      if ( private.launch[laser].numairgap < 1 ) {
        fail '%% laserconfig: No air gaps ...';
      }
      if ( airgap == '' ) {
        return( private.launch[laser].airgapthickerr );
      } else {
        if ( private.checkairgap( laser, end, airgap ) ) {
          return( private.launch[laser].airgapthickerr[airgap] );
        } else {
          fail '%% laserconfig: Invalid air gap number(s) ...';
        }
      }
    } else {
      if ( private.retro[laser].numairgap < 1 ) {
        fail '%% laserconfig: No air gaps ...';
      }
      if ( airgap == '' ) {
        return( private.retro[laser].airgapthickerr );
      } else {
        if ( private.checkairgap( laser, end, airgap ) ) {
          return( private.retro[laser].airgapthickerr[airgap] );
        } else {
          fail '%% laserconfig: Invalid air gap number(s) ...';
        }
      }
    }
  }
  
  
  # Define the 'numglass' member function
  
  const public.numglass := function( laser, end ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( !private.checklaser1( laser ) ) {
      fail '%% laserconfig: Invalid laser interferometer number ...';
    }
    if ( !private.checkend( end ) ) {
      fail '%% laserconfig: Invalid end ...';
    }
    if ( end == 'L' ) {
      return( private.launch[laser].numglass );
    } else {
      return( private.retro[laser].numglass );
    }
  }
  
  
  # Define the 'glassthick' member function
  
  const public.glassthick := function( laser, end, glass = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( !private.checklaser1( laser ) ) {
      fail '%% laserconfig: Invalid laser interferometer number ...';
    }
    if ( !private.checkend( end ) ) {
      fail '%% laserconfig: Invalid end ...';
    }
    if ( end == 'L' ) {
      if ( private.launch[laser].numglass < 1 ) {
        fail '%% laserconfig: No glass ...';
      }
      if ( glass == '' ) {
        return( private.launch[laser].glassthick );
      } else {
        if ( private.checkglass( laser, end, glass ) ) {
          return( private.launch[laser].glassthick[glass] );
        } else {
          fail '%% laserconfig: Invalid glass number(s) ...';
        }
      }
    } else {
      if ( private.retro[laser].numglass < 1 ) {
        fail '%% laserconfig: No glass ...';
      }
      if ( glass == '' ) {
        return( private.retro[laser].glassthick );
      } else {
        if ( private.checkglass( laser, end, glass ) ) {
          return( private.retro[laser].glassthick[glass] );
        } else {
          fail '%% laserconfig: Invalid glass number(s) ...';
        }
      }
    }
  }
  
  
  # Define the 'glassthickerr' member function
  
  const public.glassthickerr := function( laser, end, glass = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( !private.checklaser1( laser ) ) {
      fail '%% laserconfig: Invalid laser interferometer number ...';
    }
    if ( !private.checkend( end ) ) {
      fail '%% laserconfig: Invalid end ...';
    }
    if ( end == 'L' ) {
      if ( private.launch[laser].numglass < 1 ) {
        fail '%% laserconfig: No glass ...';
      }
      if ( glass == '' ) {
        return( private.launch[laser].glassthickerr );
      } else {
        if ( private.checkglass( laser, end, glass ) ) {
          return( private.launch[laser].glassthickerr[glass] );
        } else {
          fail '%% laserconfig: Invalid glass number(s) ...';
        }
      }
    } else {
      if ( private.retro[laser].numglass < 1 ) {
        fail '%% laserconfig: No glass ...';
      }
      if ( glass == '' ) {
        return( private.retro[laser].glassthickerr );
      } else {
        if ( private.checkglass( laser, end, glass ) ) {
          return( private.retro[laser].glassthickerr[airgap] );
        } else {
          fail '%% laserconfig: Invalid glass number(s) ...';
        }
      }
    }
  }
  
  
  # Define the 'glasscode' member function
  
  const public.glasscode := function( laser, end, glass = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( !private.checklaser1( laser ) ) {
      fail '%% laserconfig: Invalid laser interferometer number ...';
    }
    if ( !private.checkend( end ) ) {
      fail '%% laserconfig: Invalid end ...';
    }
    if ( end == 'L' ) {
      if ( private.launch[laser].numglass < 1 ) {
        fail '%% laserconfig: No glass ...';
      }
      if ( glass == '' ) {
        return( private.launch[laser].glasscode );
      } else {
        if ( private.checkglass( laser, end, glass ) ) {
          return( private.launch[laser].glasscode[glass] );
        } else {
          fail '%% laserconfig: Invalid glass number(s) ...';
        }
      }
    } else {
      if ( private.retro[laser].numglass < 1 ) {
        fail '%% laserconfig: No glass ...';
      }
      if ( glass == '' ) {
        return( private.retro[laser].glasscode );
      } else {
        if ( private.checkglass( laser, end, glass ) ) {
          return( private.retro[laser].glasscode[glass] );
        } else {
          fail '%% laserconfig: Invalid glass number(s) ...';
        }
      }
    }
  }
  
  
  # Define the 'exfrac' member function
  
  const public.exfrac := function( laser, end, glass = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( !private.checklaser1( laser ) ) {
      fail '%% laserconfig: Invalid laser interferometer number ...';
    }
    if ( !private.checkend( end ) ) {
      fail '%% laserconfig: Invalid end ...';
    }
    if ( end == 'L' ) {
      if ( private.launch[laser].numglass < 1 ) {
        fail '%% laserconfig: No glass ...';
      }
      if ( glass == '' ) {
        return( private.launch[laser].exfrac );
      } else {
        if ( private.checkglass( laser, end, glass ) ) {
          return( private.launch[laser].exfrac[glass] );
        } else {
          fail '%% laserconfig: Invalid glass number(s) ...';
        }
      }
    } else {
      if ( private.retro[laser].numglass < 1 ) {
        fail '%% laserconfig: No glass ...';
      }
      if ( glass == '' ) {
        return( private.retro[laser].exfrac );
      } else {
        if ( private.checkglass( laser, end, glass ) ) {
          return( private.retro[laser].exfrac[glass] );
        } else {
          fail '%% laserconfig: Invalid glass number(s) ...';
        }
      }
    }
  }
  
  
  # Define the 'exfracerr' member function
  
  const public.exfracerr := function( laser, end, glass = '' ) {
    wider private;
    if ( private.numlaser < 1 ) {
      fail '%% laserconfig: No laser interferometers ...';
    }
    if ( !private.checklaser1( laser ) ) {
      fail '%% laserconfig: Invalid laser interferometer number ...';
    }
    if ( !private.checkend( end ) ) {
      fail '%% laserconfig: Invalid end ...';
    }
    if ( end == 'L' ) {
      if ( private.launch[laser].numglass < 1 ) {
        fail '%% laserconfig: No glass ...';
      }
      if ( glass == '' ) {
        return( private.launch[laser].exfracerr );
      } else {
        if ( private.checkglass( laser, end, glass ) ) {
          return( private.launch[laser].exfracerr[glass] );
        } else {
          fail '%% laserconfig: Invalid glass number(s) ...';
        }
      }
    } else {
      if ( private.retro[laser].numglass < 1 ) {
        fail '%% laserconfig: No glass ...';
      }
      if ( glass == '' ) {
        return( private.retro[laser].exfracerr );
      } else {
        if ( private.checkglass( laser, end, glass ) ) {
          return( private.retro[laser].exfracerr[airgap] );
        } else {
          fail '%% laserconfig: Invalid glass number(s) ...';
        }
      }
    }
  }

  
  # Load the laser configuration and return the laserconfig object
  
  public.load();

  return( ref public );

}
