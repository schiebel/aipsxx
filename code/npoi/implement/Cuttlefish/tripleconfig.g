# tripleconfig.g is part of Cuttlefish (NPOI data reduction package)
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
# $Id: tripleconfig.g,v 19.0 2003/07/16 06:02:12 aips2adm Exp $
# ------------------------------------------------------------------------------

# tripleconfig.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish class for manipulating triple configurations.

# glish class:
# ------------
# tripleconfig.

# Modification history:
# ---------------------
# 1999 Nov 01 - Nicholas Elias, USNO/NPOI
#               File created with glish class tripleconfig{ }.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'cuttlefish.g' ) {
  fail '%% tripleconfig: Cannot include cuttlefish.g ...';
}

# ------------------------------------------------------------------------------

# tripleconfig

# Description:
# ------------
# This glish class creates a tripleconfig object (interface) for manipulating
# triple configurations.

# Inputs:
# -------
# file           - The file name.
# format         - The file format ('ASCII', 'HDS', 'TABLE'; default = 'HDS').
# host           - The host name (default = '').
# forcenewserver - The 'force new server' flag (default = F).

# Outputs:
# --------
# The tripleconfig object, returned via the glish function value.

# Modification history:
# ---------------------
# 1999 Nov 01 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const tripleconfig := function( file, format = 'HDS', host = '',
    forcenewserver = F ) {
  
  # Initialize the variables
  
  top := F;

  private := [=];
  public := [=];
  
  
  # Fix and check the inputs
  
  if ( !cs( file ) ) {
    fail '%% tripleconfig: Invalid file name ...';
  }
  
  private.file := file;
  
  format := to_upper( format );
  for ( f in 1:length( format_const ) ) {
    if ( format == format_const[f] ) {
      break;
    }
  }
  
  if ( f > length( format_const ) ) {
    fail '%% tripleconfig: Invalid file format ...';
  }
  
  private.format := format;
  
  if ( !cs( host ) ) {
    fail '%% tripleconfig: Invalid host ...';
  }
  
  private.host := host;
  
  if ( !is_boolean( forcenewserver ) ) {
    fail '%% tripleconfig: Invalid \'force-new-server\' boolean flag ...';
  }
  
  private.forcenewserver := forcenewserver;
  
  
  # Create the private functions for dumping the triple configuration
  
  const private.dumpascii := function( replace = F ) {
    fail '%% tripleconfig: ASCII format not implemented yet ...';
  }
  
  const private.dumphds := function( file, replace = F ) {
    wider private;
    if ( is_fail( hds := hdsopen( file, F, host = private.host,
        forcenewserver = private.forcenewserver ) ) ) {
      fail '%% tripleconfig: Could not dump triple configuration to HDS file ...';
    }
    if ( !hds.there( 'GenConfig' ) ) {
      hds.new( 'GenConfig', '', 0 );
    }
    hds.find( 'GenConfig' );
    if ( hds.there( 'Triple' ) && !replace ) {
      hds.done();
      fail '%% tripleconfig: Cannot overwrite triple configuration ...';
    }
    hds.new( 'Triple', '', 0, replace );
    hds.find( 'Triple' );
    hds.screate( 'NumTriple', '_INTEGER', private.numtriple, replace );
    hds.create( 'OutputBeam', '_INTEGER', private.outputbeam, replace );
    hds.create( 'Baseline', '_INTEGER', private.baseline, replace );
    hds.create( 'SpecChan', '_INTEGER', private.specchan, replace );
    hds.create( 'NumSpecChan', '_INTEGER', private.numspecchan, replace );
    hds.done();
    return( T );
  }
  
  const private.dumptable := function( replace = F ) {
    fail '%% tripleconfig: Aips++ table format not implemented yet ...';
  }
  
  
  # Create the private functions for loading the triple configuration
  
  const private.loadascii := function( ) {
    fail '%% tripleconfig: ASCII format not implemented yet ...';
  }
  
  const private.loadhds := function( ) {
    wider private;
    if ( is_fail( hds := hdsopen( private.file, host = private.host,
        forcenewserver = private.forcenewserver ) ) ) {
      fail '%% tripleconfig: Could not load triple configuration from HDS file ...';
    }
    if ( !hds.there( 'GenConfig' ) ) {
      hds.done();
      fail '%% tripleconfig: No GenConfig HDS 0bject ...';
    }
    hds.find( 'GenConfig' );
    hds.find( 'Triple' );
    private.numtriple := hds.obtain( 'NumTriple' );
    private.outputbeam := hds.obtain( 'OutputBeam' );
    private.outputbeam2 := private.outputbeam + 1; # Kludge
    private.baseline := hds.obtain( 'Baseline' );
    private.baseline2 := private.baseline + 1; # Kludge
    private.specchan := hds.obtain( 'SpecChan' );
    private.numspecchan := hds.obtain( 'NumSpecChan' );
    hds.done();
    return( T );
  }
  
  const private.loadtable := function( ) {
    fail '%% tripleconfig: Aips++ table format not implemented yet ...';
  }
  
  
  # Create the private functions for checking inputs to public member functions
  
  const private.checktriple1 := function( triple ) {
    wider private;
    if ( !is_integer( triple ) ) {
      return( F );
    }
    if ( length( triple ) != 1 ) {
      return( F );
    }
    if ( triple < 1 || triple > private.numtriple ) {
      return( F );
    }
    return( T );
  }

  const private.checktriple := function( triple ) {
    wider private;
    numtriple := length( triple );
    for ( t in 1:numtriple ) {
      if ( !private.checktriple1( triple[t] ) ) {
        return( F );
      }
    }
    if ( numtriple == 1 ) {
      return( T );
    }
    for ( t1 in 1:(numtriple-1) ) {
      for ( t2 in (t1+1):numtriple ) {
        if ( triple[t1] == triple[t2] ) {
          return( F );
        }
      }
    }
    return( T );
  }
  
  const private.checkleg1 := function( triple, leg ) {
    wider private;
    if ( !private.checktriple1( triple ) ) {
      return( F );
    }
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
  
  const private.checkleg := function( triple, leg ) {
    wider private;
    numleg := length( leg );
    for ( l in 1:numleg ) {
      if ( !private.checkleg1( triple, leg[l] ) ) {
        return( F );
      }
    }
    if ( numleg == 1 ) {
      return( T );
    }
    for ( l1 in 1:(numleg-1) ) {
      for ( l2 in (l1+1):numleg ) {
        if ( leg[l1] == leg[l2] ) {
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
      fail '%% tripleconfig: Invalid replace flag ...';
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
      fail '%% tripleconfig: Invalid format ...'
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
    fail '%% tripleconfig: web() member function not implemented yet ...'
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
    dialog := label( top, 'GUI for tripleconfig class not implemented yet ...' );
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
  
  const public.outputbeam := function( triple, leg = '' ) {
    wider private;
    if ( leg == '' ) {
      if ( !private.checktriple1( triple ) ) {
        fail '%% tripleconfig: Invalid triple number ...';
      }
      return( private.outputbeam2[,triple] );
    } else {
      if ( !private.checkleg( triple, leg ) ) {
        fail '%% tripleconfig: Invalid triple number or leg number(s) ...';
      }
      return( private.outputbeam2[leg,triple] );
    }
  }
  
  
  # Define the 'baseline' member function
  
  const public.baseline := function( triple, leg = '' ) {
    wider private;
    if ( leg == '' ) {
      if ( !private.checktriple1( triple ) ) {
        fail '%% tripleconfig: Invalid triple number ...';
      }
      return( private.baseline2[,triple] );
    } else {
      if ( !private.checkleg( triple, leg ) ) {
        fail '%% tripleconfig: Invalid triple number or leg number(s) ...';
      }
      return( private.baseline2[leg,triple] );
    }
  }
  
  
  # Define the 'specchan' member function
  
  const public.specchan := function( triple, leg, specchan = '' ) {
    wider private;
    if ( !private.checkleg1( triple, leg ) ) {
      fail '%% tripleconfig: Invalid triple or leg number ...';
    }
    if ( specchan == '' ) {
      return( private.specchan[,leg,triple] );
    } else {
      if ( !is_integer( specchan ) ) {
        fail '%% tripleconfig: Invalid spectral channel(s) ...';
      }
      numspecchan := length( specchan );
      for ( s in 1:numspecchan ) {
        if ( specchan[s] < 1 || specchan[s] > private.numspecchan[triple] ) {
          fail '%% tripleconfig: Invalid spectral channel(s) ...';
        }
      }
      if ( numspecchan > 1 ) {
        for ( s1 in 1:(numspecchan-1) ) {
          for ( s2 in (s1+1):numspecchan ) {
            if ( specchan[s1] == specchan[s2] ) {
              return( F );
            }
          }
        }
      }
      returnval := private.specchan[specchan,leg,triple];
      returnval::shape := [length(specchan),length(leg)];
      return( returnval );
    }
  }
  
  
  # Define the 'numspecchan' member function
  
  const public.numspecchan := function( triple = '' ) {
    wider private;
    if ( triple == '' ) {
      return( private.numspecchan );
    } else {
      if ( !private.checktriple( triple ) ) {
        fail '%% tripleconfig: Invalid triple number(s) ...';
      }
      return( private.numspecchan[triple] );
    }
  }
  
  
  # Load the triple configuration and return the tripleconfig object
  
  public.load();

  return( ref public );

}
