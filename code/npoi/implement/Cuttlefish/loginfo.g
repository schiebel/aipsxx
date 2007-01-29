# loginfo.g is part of the Cuttlefish server
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
# $Id: loginfo.g,v 19.0 2003/07/16 06:02:07 aips2adm Exp $
# ------------------------------------------------------------------------------

# loginfo.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++

# Description:
# ------------
# This file contains the glish function for manipulating log information.

# glish functions:
# ----------------
# __define_loginfo_members, loginfo, constrictorlog, observerlog, syslog.

# Modification history:
# ---------------------
# 2001 Jan 29 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __define_loginfo_members( )
#               loginfo( ), constrictorlog( ), observerlog( ), and syslog( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'bug.g' ) {
  throw( 'Cannot include bug.g ...', origin = 'loginfo' );
}

if ( !include 'note.g' ) {
  throw( 'Cannot include note.g ...', origin = 'loginfo' );
}

if ( !include 'servers.g' ) {
  throw( 'Cannot include servers.g ...', origin = 'loginfo' );
}

if ( !include 'check.g' ) {
  throw( 'Cannot include check.g ...', origin = 'loginfo' );
}

if ( !include 'convert.g' ) {
  throw( 'Cannot include convert.g ...', origin = 'loginfo' );
}

if ( !include 'hds.g' ) {
  throw( 'Cannot include hds.g ...', origin = 'loginfo' );
}

if ( !include 'whenever_manager.g' ) {
  throw( 'Cannot include whenever_manager.g ...', origin = 'loginfo' );
}

if ( !include '__loginfo_private.g' ) {
  throw( 'Cannot include __loginfo_private.g ...', origin = 'loginfo' );
}

if ( !include '__loginfo_public.g' ) {
  throw( 'Cannot include __loginfo_public.g ...', origin = 'loginfo' );
}

if ( !include '__loginfo_gui.g' ) {
  throw( 'Cannot include __loginfo_gui.g ...', origin = 'loginfo' );
}

# ------------------------------------------------------------------------------

# __define_loginfo_members

# Description:
# ------------
# This glish function defines the member functions for a loginfo{ } tool.

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
# 2001 Jan 29 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __define_loginfo_members := function( ref agent, id, host,
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

  __loginfo_public( gui, w, private, public );
  
  
  # Define the private member functions

  __loginfo_private( private );

  val private.window := spaste( public.filetail(), ': ', public.name() );
  

  # Return the structure containing the public member functions

  return( ref public );

}

# ------------------------------------------------------------------------------

# loginfo

# Description:
# ------------
# This glish function creates a loginfo{ } tool (interface) for manipulating
# log information.

# Inputs:
# -------
# file           - The file name.
# name           - The log name.
# readonly       - The read-only flag (default = T).
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The loginfo{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Jan 29 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const loginfo := function( file, name, readonly = T, host = '',
    forcenewserver = F ) {
  
  # Fix and check the inputs
  
  if ( !cs( file ) ) {
    return( throw( 'Invalid file name ...', origin = 'loginfo' ) );
  }
  
  if ( !cs( name, cap = T ) ) {
    return( throw( 'Invalid log name ...', origin = 'loginfo' ) );
  }
  
  if ( !is_boolean( readonly ) ) {
    return( throw( 'Invalid read-only flag ...', origin = 'loginfo' ) );
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host ...', origin = 'loginfo' ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid \'force-new-server\' boolean boolean ...',
        origin = 'loginfo' ) );
  }
  
  if ( ( name == 'CONSTRICTORLOG' || name == 'OBSERVERLOG' || name == 'SYSLOG' ) && !readonly ) {
    return( throw( 'Cannot update a constrictor, observer, or system log ...',
        origin = 'loginfo' ) );
  }
  
  
  # Invoke the LogInfo{ } constructor member function
  
  agent := defaultservers.activate( 'Cuttlefish', host, forcenewserver );
  args := [file = file, name = name, readonly = readonly];

  if ( is_fail( id := defaultservers.create( agent, 'LogInfo', 'LOGINFO',
      args ) ) ) {
    return( throw( 'Error creating Cuttlefish server ...',
        origin = 'loginfo' ) );
  }
  
  
  # Return the loginfo{ } tool
  
  public := __define_loginfo_members( agent, id, host, forcenewserver );
  
  return( ref public );
  
}

# ------------------------------------------------------------------------------

# constrictorlog

# Description:
# ------------
# This glish function creates a constrictorlog{ } tool (interface) for
# manipulating constrictor log information.

# Inputs:
# -------
# file           - The file name.
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The constrictorlog{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Jan 29 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const constrictorlog := function( file, host = '', forcenewserver = F ) {

  # Create a loginfo( ) tool
  
  return( loginfo( file, 'CONSTRICTORLOG', T, host, forcenewserver ) );
  
}

# ------------------------------------------------------------------------------

# observerlog

# Description:
# ------------
# This glish function creates an observerlog{ } tool (interface) for
# manipulating system log information.

# Inputs:
# -------
# file           - The file name.
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The observerlog{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Jan 29 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const observerlog := function( file, host = '', forcenewserver = F ) {

  # Create a loginfo( ) tool
  
  return( loginfo( file, 'OBSERVERLOG', T, host, forcenewserver ) );
  
}

# ------------------------------------------------------------------------------

# syslog

# Description:
# ------------
# This glish function creates a syslog{ } tool (interface) for manipulating
# system log information.

# Inputs:
# -------
# file           - The file name.
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The syslog{ } tool, returned via the glish function value.

# Modification history:
# ---------------------
# 2001 Jan 29 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const syslog := function( file, host = '', forcenewserver = F ) {

  # Create a loginfo( ) tool
  
  return( loginfo( file, 'SYSLOG', T, host, forcenewserver ) );
  
}
