# sensorconfig.g is part of Cuttlefish (NPOI data reduction package)
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
# $Id: sensorconfig.g,v 19.0 2003/07/16 06:02:00 aips2adm Exp $
# ------------------------------------------------------------------------------

# sensorconfig.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish class for manipulating environmental sensor
# configurations.

# glish class:
# ------------
# sensorconfig.

# Modification history:
# ---------------------
# 2000 Jan 18 - Nicholas Elias, USNO/NPOI
#               File created with glish class sensorconfig{ }.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'cuttlefish.g' ) {
  fail '%% sensorconfig: Cannot include cuttlefish.g ...';
}

# ------------------------------------------------------------------------------

# sensorconfig

# Description:
# ------------
# This glish class creates a sensorconfig object (interface) for manipulating
# environmental sensor configurations.

# Inputs:
# -------
# file           - The file name.
# subsystem      - The subsystem (no configid = 'LABSOLIDTMP', 'LABAIRTEMP',
#                  'LABPRESS', 'LABHUM', 'DLPRESS', 'FBPRESS', 'WXAIRTEMP',
#                  'WXPRESS', 'WXHUM'; 1-D configid = 'METSOLIDTMP',
#                  'METAIRTEMP', 'METPRESS', 'METHUM', 'FBAIRTEMP',
#                  'FBSOLIDTMP').
# configid       - The environmental sensor configuration ID (specify '' for
#                  labsolidtmp-like subsystems and N for metsolidtmp-like
#                  systems.
# format         - The file format ('ASCII', 'HDS', 'TABLE'; default = 'HDS').
# host           - The host name (default = '').
# forcenewserver - The 'force new server' flag (default = F).

# Outputs:
# --------
# The sensorconfig object, returned via the glish function value.

# Modification history:
# ---------------------
# 2000 Jan 18 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const sensorconfig := function( file, subsystem, configid, format = 'HDS',
    host = '', forcenewserver = F ) {
  
  # Initialize the variables
  
  top := F;
  
  subsystemlist := array( '', 2 );
  subsystemlist[1] := 'LABSOLIDTMP LABAIRTEMP LABPRESS LABHUM DLPRESS FBPRESS';
  spaste( subsystemlist[1], ' WXAIRTEMP WXPRESS WXHUM' );
  subsystemlist[2] := 'METSOLIDTMP METAIRTEMP METPRESS METHUM FBAIRTEMP';
  spaste( subsystemlist[2], ' FBSOLIDTMP' );

  private := [=];
  public := [=];
  
  
  # Fix and check the inputs
  
  if ( !cs( file ) ) {
    fail '%% sensorconfig: Invalid file name ...';
  }
  
  private.file := file;
  
  format := to_upper( format );
  for ( f in 1:length( format_const ) ) {
    if ( format == format_const[f] ) {
      break;
    }
  }
  
  if ( f > length( format_const ) ) {
    fail '%% sensorconfig: Invalid file format ...';
  }

  private.format := format;
  
  if ( !cs( host ) ) {
    fail '%% sensorconfig: Invalid host ...';
  }
  
  private.host := host;
  
  if ( !is_boolean( forcenewserver ) ) {
    fail '%% sensorconfig: Invalid \'force-new-server\' boolean flag ...';
  }
  
  private.forcenewserver := forcenewserver;
  
  flag := F;
  subsystem := to_upper( subsystem );
  
  for ( s1 in 1:2 ) {
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
  
  if ( s1 > 2 ) {
    fail '%% sensorconfig: Invalid subsystem ...';
  }

  private.subsystem := subsystem;
  
  if ( is_integer( configid ) ) {
    if ( length( configid ) + 1 != s1 ) {
      fail '%% sensorconfig: Invalid environmental sensor ID(s) ...';
    }
    private.configid := configid;
  } else {
    private.configid := '';
  }
  
  
  # Do further checking of inputs and initialize related variables
  
  genConfigTemp := genconfig( private.file, private.format, private.host,
      private.forcenewserver );
  
  if ( private.configid == '' ) {
    private.pathshort :=
        to_upper( paste( private.subsystem, 'Conf', sep = '' ) );
    private.configidmax := '';
    private.plate := 0;
    private.path := to_upper( paste( 'Session', '.', 'MetroConfig', '.',
        private.subsystem, 'Conf', sep = '' ) );
  } else {
    numplate := genConfigTemp.numplate();
    private.pathshort :=
        to_upper( paste( private.subsystem, 'Conf', sep = '' ) );
    if ( private.configid < 1 || private.configid > numplate ) {
      genConfigTemp.done();
      fail '%% sensorconfig: Invalid plate number ...';
    }
    private.configidmax := numplate;
    private.plate := private.configid[1];
    private.path := to_upper( paste( 'Session', '.', 'MetroConfig', '.',
        private.subsystem, 'Conf(', private.configid[1], ')', sep = '' ) );
  }
  
  genConfigTemp.done();
  
  
  # Create the private functions for dumping the environmental sensor
  # configuration
  
  const private.dumpascii := function( replace = F ) {
    fail '%% sensorconfig: ASCII format not implemented yet ...';
  }
  
  const private.dumphds := function( file, replace = F ) {
    wider private;
    if ( is_fail( hds := hdsopen( file, F, host = private.host,
        forcenewserver = private.forcenewserver ) ) ) {
      fail '%% sensorconfig: Could not dump environmental sensor configuration to HDS file ...';
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
      fail '%% sensorconfig: Cannot overwrite environmental sensor configuration ...';
    }
    hds.screate( 'NumSensor', '_INTEGER', private.numsensor, replace );
    hds.screate( 'PacketNumber', '_INTEGER', private.packetnumber, replace );
    if ( private.numsensor < 1 ) {
      hds.done();
      return( T );
    }
    hds.screate( 'BitsPerDatum', '_INTEGER', private.bitsperdatum, replace );
    hds.screate( 'SampleInterval', '_INTEGER', private.sampleinterval,
        replace );
    hds.create( 'Chain', '_INTEGER', private.chain, replace );
    hds.create( 'BRAD', '_INTEGER', private.brad, replace );
    hds.create( 'Offset', '_DOUBLE', private.offset, replace );
    hds.create( 'OffsetErr', '_DOUBLE', private.offseterr, replace );
    hds.create( 'Scale', '_DOUBLE', private.scale, replace );
    hds.create( 'ScaleErr', '_DOUBLE', private.scaleerr, replace );
    hds.create( 'Cross', '_DOUBLE', private.cross, replace );
    hds.create( 'SerialNumber', '_INTEGER', private.serialnumber, replace );
    desclen := 0;
    for ( l in 1:length(private.description) ) {
      if ( length( split( private.description[l], '' ) ) > desclen ) {
        desclen := length( split( private.description[l], '' ) );
      }
    }
    hds.create( 'Description', spaste( '_CHAR*', desclen ),
        private.description, replace );
    hds.create( 'Loc', '_DOUBLE', private.loc, replace );
    hds.create( 'LocErr', '_DOUBLE', private.locerr, replace );
    hds.done();
    return( T );
  }
  
  const private.dumptable := function( replace = F ) {
    fail '%% sensorconfig: Aips++ table format not implemented yet ...';
  }
  
  
  # Create the private functions for loading the environmental sensor
  # configuration
  
  const private.loadascii := function( ) {
    fail '%% sensorconfig: ASCII format not implemented yet ...';
  }
  
  const private.loadhds := function( ) {
    wider private;
    if ( is_fail( hds := hdsopen( private.file, host = private.host,
        forcenewserver = private.forcenewserver ) ) ) {
      fail '%% sensorconfig: Could not load environmental sensor configuration from HDS file ...';
    }
    hds.goto( private.path );
    private.numsensor := hds.obtain( 'NumSensor' );
    if ( private.numsensor < 1 ) {
      hds.done();
      return( T );
    }
    private.packetnumber := hds.obtain( 'PacketNumber' );
    private.bitsperdatum := hds.obtain( 'BitsPerDatum' );
    private.sampleinterval := hds.obtain( 'SampleInterval' );
    private.chain := hds.obtain( 'Chain' );
    private.brad := hds.obtain( 'BRAD' );
    private.offset := hds.obtain( 'Offset' );
    private.offseterr := hds.obtain( 'OffsetErr' );
    private.scale := hds.obtain( 'Scale' );
    private.scaleerr := hds.obtain( 'ScaleErr' );
    private.cross := hds.obtain( 'Cross' );
    private.serialnumber := hds.obtain( 'SerialNumber' );
    private.description := hds.obtain( 'Description' );
    private.loc := hds.obtain( 'Loc' );
    private.locerr := hds.obtain( 'LocErr' );
    hds.done();
    return( T );
  }
  
  const private.loadtable := function( ) {
    fail '%% sensorconfig: Aips++ table format not implemented yet ...';
  }
  
  
  # Create the private functions for checking inputs to public member functions
  
  const private.checksensor1 := function( sensor ) {
    wider private;
    if ( !is_integer( sensor ) ) {
      return( F );
    }
    if ( length( sensor ) != 1 ) {
      return( F );
    }
    if ( sensor < 1 || sensor > private.numsensor ) {
      return( F );
    }
    return( T );
  }
  
  const private.checksensor := function( sensor ) {
    wider private;
    numsensor := length( sensor );
    for ( s in 1:numsensor ) {
      if ( !private.checksensor1( sensor[s] ) ) {
        return( F );
      }
    }
    if ( numsensor == 1 ) {
      return( T );
    }
    for ( s1 in 1:(numsensor-1) ) {
      for ( s2 in (s1+1):numsensor ) {
        if ( sensor[s1] == sensor[s2] ) {
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
    return( private.subsystem );
  }
  
  
  # Define the 'configid' member function
  
  const public.configid := function( ) {
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
      fail '%% sensorconfig: Invalid replace flag ...';
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
      fail '%% sensorconfig: Invalid format ...'
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
    fail '%% sensorconfig: web() member function not implemented yet ...'
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
    dialog := label( top,'GUI for sensorconfig class not implemented yet ...' );
    dismiss := button( top, 'Dismiss' );
    whenever dismiss->press do {
      top := F;
    }
    return( T )
  }
    
  
  # Define the 'plate' member function
  
  const public.plate := function( ) {
    return( private.plate );
  }
  
  
  # Define the 'path' member function
  
  const public.path := function( ) {
    return( private.path );
  }
  
  
  # Define the 'numsensor' member function
  
  const public.numsensor := function( ) {
    return( private.numsensor );
  }
  
  
  # Define the 'packetnumber' member function
  
  const public.packetnumber := function( ) {
    wider private;
    return( sprintf( '0x%04X', private.packetnumber ) );
  }
  
  
  # Define the 'sampleinterval' member function
  
  const public.sampleinterval := function( ) {
    wider private;
    if ( private.numsensor < 1 ) {
      fail '%% sensorconfig: No environmental sensors ...';
    }
    return( private.sampleinterval );
  }
  
  
  # Define the 'bitsperdatum' member function
  
  const public.bitsperdatum := function( ) {
    wider private;
    if ( private.numsensor < 1 ) {
      fail '%% sensorconfig: No environmental sensors ...';
    }
    return( private.bitsperdatum );
  }
  
  
  # Define the 'chain' member function
  
  const public.chain := function( sensor = '' ) {
    wider private;
    if ( private.numsensor < 1 ) {
      fail '%% sensorconfig: No environmental sensors ...';
    }
    if ( sensor == '' ) {
      return( private.chain );
    } else {
      if ( private.checksensor( sensor ) ) {
        return( private.chain[sensor] );
      } else {
        fail '%% sensorconfig: Invalid environmental sensor number(s) ...';
      }
    }
  }
  
  
  # Define the 'brad' member function
  
  const public.brad := function( sensor = '' ) {
    wider private;
    if ( private.numsensor < 1 ) {
      fail '%% sensorconfig: No environmental sensors ...';
    }
    if ( sensor == '' ) {
      return( private.brad );
    } else {
      if ( private.checksensor( sensor ) ) {
        return( private.brad[sensor] );
      } else {
        fail '%% sensorconfig: Invalid environmental sensor number(s) ...';
      }
    }
  }
  
  
  # Define the 'loc' member function
  
  const public.loc := function( sensor ) {
    wider private;
    if ( private.numsensor < 1 ) {
      fail '%% sensorconfig: No environmental sensors ...';
    }
    if ( !private.checksensor1( sensor ) ) {
      fail '%% sensorconfig: Invalid environmental sensor number ...';
    }
    return( private.loc[,sensor] );
  }
  
  
  # Define the 'locerr' member function
  
  const public.locerr := function( sensor ) {
    wider private;
    if ( private.numsensor < 1 ) {
      fail '%% sensorconfig: No environmental sensors ...';
    }
    if ( !private.checksensor1( sensor ) ) {
      fail '%% sensorconfig: Invalid environmental sensor number ...';
    }
    return( private.locerr[,sensor] );
  }
  
  
  # Load the environmental sensor and return the sensorconfig object
  
  public.load();

  return( ref public );

}
