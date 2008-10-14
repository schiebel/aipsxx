# __obdata1_guimore.g is part of the Cuttlefish server
# Copyright (C) 2001
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
# $Id: __obdata1_guimore.g,v 19.0 2003/07/16 06:02:48 aips2adm Exp $
# ------------------------------------------------------------------------------

# __obdata1_guimore.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for the gui in __obdata1 tools
# (augmenting the gui for gdc1token tools).  NB: These functions should be
# called only by __obdata1 tools.

# glish function:
# ---------------
# __obdata1_guimore, __obdata1_guimore_dumphds, __obdata1_guimore_xaxis,
# __obdata1_guimore_xaxis_update.

# Modification history:
# ---------------------
# 2001 May 11 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __obdata1_guimore( ),
#               __obdata1_guimore_dumphds( ), __obdata1_guimore_xaxis( ) and
#               __obdata1_guimore_xaxis_update( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __obdata1_guimore

# Description:
# ------------
# This glish function creates more private member functions for the GUI of an
# __obdata1 tool (an augmented gdc1token tool).

# Inputs:
# -------
# gui     - The GUI variable.
# w       - The whenever manager variable.
# private - The private variable.
# public  - The public variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2001 May 11 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __obdata1_guimore := function( ref gui, ref w, ref private, public ) {
  
  # Define the 'guimore' private member function
  
  const val private.guimore := function( ) {
    wider gui, w, private, public;
    private.bdumphds( gui, w, private, public );
    private.bxaxis( gui, w, private, public );
    private.bsave( gui, w, private, public );
    private.bsavehds( gui, w, private, public );
    return( T );
  }
  
  # Define the 'guimore_reset' private member function
  
  const val private.guimore_reset := function( ) {
    wider gui, w, private, public;
    __obdata1_guimore_xaxis_update( public.xlabeltokens()[1], gui, private,
        public );
    return( T );
  }
  

  # Define the 'guimore_killed' private member function
  
  const val private.guimore_killed := function ( ) {
    wider gui, w, private, public;
    val gui.dumphds := F;
    val gui.xaxis := F;
    return( T );
  }
  
  
  # Define the 'guimore_enable' private member function
  
  const val private.guimore_enable := function( ) {
    wider gui, w, private, public;
    if ( is_agent( gui.bxaxis ) ) {
      gui.bxaxis->disabled( F );
    }
    return( T );
  }
  
  
  # Define the 'guimore_disable' private member function
  
  const val private.guimore_disable := function( ) {
    wider gui, w, private, public;
    if ( is_agent( gui.bxaxis ) ) {
      gui.bxaxis->disabled( T );
    }
    return( T );
  }
  
  
  # Define the 'guimore_unmap' private member function
  
  const val private.guimore_unmap := function( ) {
    wider gui, w, private, public;
    if ( is_agent( gui.dumphds ) ) {
      gui.dumphds->unmap();
      w.whenever_deactivate( 'dumphdsgui' );
    }
    if ( is_agent( gui.xaxis ) ) {
      gui.xaxis->unmap();
      w.whenever_deactivate( 'xaxisgui' );
    }
    return( T );
  }
  
  
  # Define the 'bdumphds' private member function
  
  const val private.bdumphds := function( ref gui, ref w, ref private,
      public ) {
    val gui.bdumphds := button( private.dumpmenu(), 'HDS', relief = 'flat' );
    whenever gui.bdumphds->press do {
      __obdata1_guimore_dumphds( gui, w, private, public );
    }
    w.whenever_add( 'gui', 'hds' );
    return( T );
  }
  
  
  # Define the 'bxaxis' private member function

  const val private.bxaxis := function( ref gui, ref w, ref private,
      public ) {
    val gui.bxaxis := button( private.toolmenu(), 'X-Axis', relief = 'flat' );
    whenever gui.bxaxis->press do {
      __obdata1_guimore_xaxis( gui, w, private, public );
    }
    w.whenever_add( 'gui', 'xaxis' );
    return( T );
  }
  
  
  # Define the 'bsave' private member function
  
  const val private.bsave := function( ref gui, ref w, ref private,
      public ) {
    val gui.bsave := button( private.filemenu(), 'Save', type = 'menu',
        relief = 'flat' );
    return( T );
  }
  
  
  # Define the 'bsavehds' private member function
  
  const val private.bsavehds := function( ref gui, ref w, ref private,
      public ) {
    val gui.bsavehds := button( gui.bsave, 'HDS', relief = 'flat' );
    whenever gui.bsavehds->press do {
      public.savehds();
    }
    w.whenever_add( 'gui', 'savehds' );
    return( T );
  }

  
  # Return T
 
  return( T );
  
}

# ------------------------------------------------------------------------------

# __obdata1_guimore_dumphds

# Description:
# ------------
# This glish function creates the dumphds GUI for an __obdata1 tool (augmented
# to a gdc1token tool).

# Inputs:
# -------
# gui     - The GUI variable.
# w       - The whenever manager variable.
# private - The private variable.
# public  - The public variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2001 May 11 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __obdata1_guimore_dumphds := function( ref gui, ref w, ref private,
    public ) {

  # If the dumphds GUI exists but isn't mapped, remap it and return
  
  if ( is_agent( gui.dumphds ) ) {
    gui.dumphds->map();
    w.whenever_activate( 'dumphdsgui' );
    return( F );
  }
  
  
  # Create the dumphds GUI
    
  tk_hold();
  
  val gui.dumphds := frame( title = spaste( private.window.main, ': dump hds' ),
      side = 'left' );
    
  val gui.dumphds.label := label( gui.dumphds, 'File: ' );
  
  val gui.dumphds.entry := entry( gui.dumphds, width = 30 );
  gui.dumphds.entry->insert( 'file.sdf' );
    
  val gui.dumphds.space1 := label( gui.dumphds, ' ' );
  
  val gui.dumphds.dump := button( gui.dumphds, 'Dump' );
  whenever gui.dumphds.dump->press do {
    ret := public.dumphds( gui.dumphds.entry->get(), private.getxmin(),
        private.getxmax(), private.gettoken() );
    if ( !is_fail( ret ) ) {
      gui.dumphds->unmap();
    }
  }
  w.whenever_add( 'dumphdsgui', 'dump' );
    
  val gui.dumphds.space2 := label( gui.dumphds, ' ' );
    
  val gui.dumphds.dismiss := button( gui.dumphds, 'Dismiss',
      background = 'Orange' );
  whenever gui.dumphds.dismiss->press do {
    gui.dumphds->unmap();
    w.whenever_deactivate( 'dumphdsgui' );
  }
  w.whenever_add( 'dumphdsgui', 'dismiss' );
    
  whenever gui.dumphds->killed do {
    val gui.dumphds := F;
    w.whenever_delete( 'dumphdsgui' );
  }
  w.whenever_add( 'dumphdsgui', 'killed' );
    
  tk_release();
  
  
  # Return T
    
  return( T );
    
}

# ------------------------------------------------------------------------------

# __obdata1_guimore_xaxis

# Description:
# ------------
# This glish function creates the x-axis GUI for an __obdata1 tool (augmented to
# a gdc1token tool).

# Inputs:
# -------
# gui     - The GUI variable.
# w       - The whenever manager variable.
# private - The private variable.
# public  - The public variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2001 May 11 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __obdata1_guimore_xaxis := function( ref gui, ref w, ref private,
    public ) {

  # If the x-axis GUI exists but isn't mapped, remap it and return

  if ( is_agent( gui.xaxis ) ) {
    gui.xaxis->map();
    w.whenever_activate( 'xaxisgui' );
    return( F );
  }
  
  
  # Create the x-axis GUI

  tk_hold();
  
  val gui.xaxis := frame( title = spaste( private.window.main, ': x-axis' ),
      side = 'left' );
  
  xtokens := public.xlabeltokens();
  val gui.xaxis.xtoken := [=];
  
  for ( x in xtokens ) {
    val gui.xaxis.xtoken[x] := button( gui.xaxis, x, type = 'radio',
        relief = 'raised', value = x );
    whenever gui.xaxis.xtoken[x]->press do {
      public.changex( $value );
    }
    w.whenever_add( 'xaxisgui', spaste( 'xtoken_', x ) );
  }
  
  gui.xaxis.xtoken[public.xtoken()]->state( T );
    
  val gui.xaxis.space := label( gui.xaxis, ' ' );
    
  val gui.xaxis.dismiss := button( gui.xaxis, 'Dismiss',
      background = 'Orange' );
  whenever gui.xaxis.dismiss->press do {
    gui.xaxis->unmap();
    w.whenever_deactivate( 'xaxisgui' );
  }
  w.whenever_add( 'xaxisgui', 'dismiss' );
    
  whenever gui.xaxis->killed do {
    val gui.xaxis := F;
    w.whenever_delete( 'xaxisgui' );
  }
  w.whenever_add( 'xaxisgui', 'killed' );
    
  tk_release();
  
  
  # Return T

  return( T );
    
}

# ------------------------------------------------------------------------------

# __obdata1_guimore_xaxis_update

# Description:
# ------------
# This glish function update the x-axis GUI for an __obdata1 tool (augmented to
# a gdc1token tool).

# Inputs:
# -------
# xtoken  - The x-label token.
# gui     - The GUI variable.
# private - The private variable.
# public  - The public variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2001 May 11 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __obdata1_guimore_xaxis_update := function( xtoken, ref gui, ref private,
    public ) {

  # If the x-axis GUI doesn't exist, return
  
  if ( !is_agent( gui.xaxis ) ) {
    return( F );
  }
  
  
  # Update the x-axis GUI
  
  gui.xaxis.xtoken[public.xlabelid(xtoken)]->state( T );
  
  val private.changeXRec.xtoken := xtoken;
  if ( xtoken != 'HH:MM:SS' ) {
    val private.changeXRec.hms := F;
  } else {
    val private.changeXRec.hms := T;
  }
  defaultservers.run( private.agent, private.changeXRec );
  
  
  # Return T
    
  return( T );
    
}
