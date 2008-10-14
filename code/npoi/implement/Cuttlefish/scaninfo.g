# scaninfo.g is part of the Cuttlefish server
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
# $Id: scaninfo.g,v 19.0 2003/07/16 06:02:11 aips2adm Exp $
# ------------------------------------------------------------------------------

# scaninfo.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++

# Description:
# ------------
# This file contains the glish function for manipulating scan information.

# glish functions:
# ----------------
# __define_scaninfo_members, scaninfo.

# Modification history:
# ---------------------
# 2000 Aug 15 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __define_scaninfo_members( )
#               and scaninfo( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'bug.g' ) {
  throw( 'Cannot include bug.g ...', origin = 'scaninfo' );
}

if ( !include 'note.g' ) {
  throw( 'Cannot include note.g ...', origin = 'scaninfo' );
}

if ( !include 'servers.g' ) {
  throw( 'Cannot include servers.g ...', origin = 'scaninfo' );
}

if ( !include 'check.g' ) {
  throw( 'Cannot include check.g ...', origin = 'scaninfo' );
}

if ( !include 'convert.g' ) {
  throw( 'Cannot include convert.g ...', origin = 'scaninfo' );
}

if ( !include 'hds.g' ) {
  throw( 'Cannot include hds.g ...', origin = 'scaninfo' );
}

if ( !include 'whenever_manager.g' ) {
  throw( 'Cannot include whenever_manager.g ...', origin = 'scaninfo' );
}

if ( !include '__scaninfo_private.g' ) {
  throw( 'Cannot include __scaninfo_private.g ...', origin = 'scaninfo' );
}

if ( !include '__scaninfo_public.g' ) {
  throw( 'Cannot include __scaninfo_public.g ...', origin = 'scaninfo' );
}

if ( !include '__scaninfo_gui.g' ) {
  throw( 'Cannot include __scaninfo_gui.g ...', origin = 'scaninfo' );
}

# ------------------------------------------------------------------------------

# __define_scaninfo_members

# Description:
# ------------
# This glish function defines the member functions for a scaninfo{ } tool.

# Inputs:
# -------
# agent          - The agent.
# id             - The ID.
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The public member functions, returned via the glish function value.

# Modification history:
# ---------------------
# 2000 Aug 15 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __define_scaninfo_members := function( ref agent, id, host,
    forcenewserver ) {

  val private := [=];
  val private.agent := ref agent;
  val private.id := id;
  val private.host := host;
  val private.forcenewserver := forcenewserver;

  public := [=];

  gui := [=];

  w := whenever_manager();
  
  
  # Define the private member functions

  __scaninfo_private( private );


  # Define the public member functions

  __scaninfo_public( gui, w, private, public );

  if ( public.derived() ) {
    annotation := '***';
  } else {
    annotation := '';
  }
  val private.window := spaste( annotation, public.filetail(), annotation,
      ': scaninfo' );


  # Return the structure containing the public member functions

  return( ref public );

}

# ------------------------------------------------------------------------------

# scaninfo

# Description:
# ------------
# This glish function creates a scaninfo{ } tool (interface) for manipulating
# scan information.

# Inputs:
# -------
# file           - The file name.
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The scaninfo{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2000 Aug 15 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const scaninfo := function( file, host = '', forcenewserver = F ) {
  
  # Fix and check the inputs
  
  if ( !cs( file ) ) {
    return( throw( 'Invalid file name ...', origin = 'scaninfo' ) );
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host ...', origin = 'scaninfo' ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid \'force-new-server\' boolean boolean ...',
        origin = 'scaninfo' ) );
  }
  
  
  # Invoke the ScanInfo{ } constructor member function
  
  agent := defaultservers.activate( 'Cuttlefish', host, forcenewserver );
  args := [file = file];

  if ( is_fail( id := defaultservers.create( agent, 'ScanInfo', 'SCANINFO',
      args ) ) ) {
    return( throw( 'Error creating Cuttlefish server ...',
        origin = 'scaninfo' ) );
  }
  
  
  # Return the scaninfo{ } tool
  
  public := __define_scaninfo_members( agent, id, host, forcenewserver );
  
  return( ref public );
  
}

# ------------------------------------------------------------------------------

# scaninfo_derived

# Description:
# ------------
# This glish function creates a derived scaninfo{ } tool (interface) for
# manipulating scan information.  This function is not typically called by the
# user.

# Inputs:
# -------
# file           - The file name.
# scanid         - The scan IDs.
# starid         - The star IDs.
# scantime       - The scan times.
# ra             - The right ascensions.
# dec            - The declinations.
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The derived scaninfo{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Mar 28 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const scaninfo_derived := function( file, scanid, starid, scantime, ra, dec,
    host = '', forcenewserver = F ) {
  
  # Fix and check the inputs
  
  if ( !cs( file ) ) {
    return( throw( 'Invalid file name ...', origin = 'scaninfo' ) );
  }
  
  if ( !is_integer( scanid ) ) {
    return( throw( 'Invalid scan ID(s) ...', origin = 'scaninfo' ) );
  }
  
  numscan := length( scanid );
  
  if ( !is_string( starid ) || length( starid ) != numscan ) {
    return( throw( 'Invalid star ID(s) ...', origin = 'scaninfo' ) );
  }
  
  if ( !is_double( scantime ) || length( scantime ) != numscan ) {
    return( throw( 'Invalid scan time(s) ...', origin = 'scaninfo' ) );
  }
  
  if ( !is_double( ra ) || length( ra ) != numscan ) {
    return( throw( 'Invalid right ascensions(s) ...', origin = 'scaninfo' ) );
  }
  
  if ( !is_double( dec ) || length( dec ) != numscan ) {
    return( throw( 'Invalid declinations(s) ...', origin = 'scaninfo' ) );
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host ...', origin = 'scaninfo' ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid \'force-new-server\' boolean boolean ...',
        origin = 'scaninfo' ) );
  }
  
  
  # Invoke the ScanInfo{ } constructor member function
  
  agent := defaultservers.activate( 'Cuttlefish', host, forcenewserver );
  args := [file = file, scanid = scanid, starid = starid, scantime = scantime,
      ra = ra, dec = dec];

  if ( is_fail( id := defaultservers.create( agent, 'ScanInfo',
      'SCANINFO_DERIVED', args ) ) ) {
    return( throw( 'Error creating Cuttlefish server ...',
        origin = 'scaninfo' ) );
  }
  
  
  # Return the scaninfo{ } tool
  
  public := __define_scaninfo_members( agent, id, host, forcenewserver );
  
  return( ref public );
  
}
