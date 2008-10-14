# obconfig.g is part of the Cuttlefish server
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
# $Id: obconfig.g,v 19.0 2003/07/16 06:02:09 aips2adm Exp $
# ------------------------------------------------------------------------------

# obconfig.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++

# Description:
# ------------
# This file contains the glish function for manipulating output-beam
# configurations.

# glish functions:
# ----------------
# __define_obconfig_members, obconfig.

# Modification history:
# ---------------------
# 2001 Jan 18 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __define_obconfig_members( )
#               and obconfig( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'bug.g' ) {
  throw( 'Cannot include bug.g ...', origin = 'obconfig' );
}

if ( !include 'note.g' ) {
  throw( 'Cannot include note.g ...', origin = 'obconfig' );
}

if ( !include 'servers.g' ) {
  throw( 'Cannot include servers.g ...', origin = 'obconfig' );
}

if ( !include 'check.g' ) {
  throw( 'Cannot include check.g ...', origin = 'obconfig' );
}

if ( !include 'hds.g' ) {
  throw( 'Cannot include hds.g ...', origin = 'obconfig' );
}

if ( !include 'whenever_manager.g' ) {
  throw( 'Cannot include whenever_manager.g ...', origin = 'obconfig' );
}

if ( !include '__obconfig_private.g' ) {
  throw( 'Cannot include __obconfig_private.g ...', origin = 'obconfig' );
}

if ( !include '__obconfig_public.g' ) {
  throw( 'Cannot include __obconfig_public.g ...', origin = 'obconfig' );
}

if ( !include '__obconfig_gui.g' ) {
  throw( 'Cannot include __obconfig_gui.g ...', origin = 'obconfig' );
}

# ------------------------------------------------------------------------------

# __define_obconfig_members

# Description:
# ------------
# This glish function defines the member functions for an obconfig{ } tool.

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
# 2001 Jan 18 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __define_obconfig_members := function( ref agent, id, host,
    forcenewserver ) {

  val private := [=];
  val private.agent := ref agent;
  val private.id := id;
  val private.host := host;
  val private.forcenewserver := forcenewserver;

  public := [=];

  gui := [=];

  w := whenever_manager();
  
  
  # Define the public member functions

  __obconfig_public( gui, w, private, public );
  
  
  # Define the private member functions
  
  __obconfig_private( private );

  val private.window := spaste( public.filetail(), ': obconfig' );
  

  # Return the structure containing the public member functions

  return( ref public );

}

# ------------------------------------------------------------------------------

# obconfig

# Description:
# ------------
# This glish function creates an obconfig{ } tool (interface) for manipulating
# output-beam configurations.

# Inputs:
# -------
# file           - The file name.
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The obconfig{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Jan 18 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const obconfig := function( file, host = '', forcenewserver = F ) {
  
  # Fix and check the inputs
  
  if ( !cs( file ) ) {
    return( throw( 'Invalid file name ...', origin = 'obconfig' ) );
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host ...', origin = 'obconfig' ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid \'force-new-server\' boolean boolean ...',
        origin = 'obconfig' ) );
  }
  
  
  # Invoke the OBConfig{ } constructor member function
  
  agent := defaultservers.activate( 'Cuttlefish', host, forcenewserver );
  args := [file = file];

  if ( is_fail( id := defaultservers.create( agent, 'OBConfig', 'OBCONFIG',
      args ) ) ) {
    return( throw( 'Error creating Cuttlefish server ...',
        origin = 'obconfig' ) );
  }
  
  
  # Return the obconfig{ } tool
  
  public := __define_obconfig_members( agent, id, host, forcenewserver );
  
  return( ref public );
  
}
