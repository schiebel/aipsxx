# __ibconfig_gui.g is part of the Cuttlefish server
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
# $Id: __ibconfig_gui.g,v 19.0 2003/07/16 06:02:21 aips2adm Exp $
# ------------------------------------------------------------------------------

# __ibconfig_gui.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for the gui in ibconfig tools.  NB:
# These functions should be called only by ibconfig tools.

# glish function:
# ---------------
# __ibconfig_gui, __ibconfig_gui_update, __ibconfig_gui_dumphds.

# Modification history:
# ---------------------
# 2000 Aug 27 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __ibconfig_gui( ),
#               __ibconfig_gui_update( ), __ibconfig_gui_dumphds( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __ibconfig_gui

# Description:
# ------------
# This glish function creates a GUI for an ibconfig tool.

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
# 2000 Aug 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __ibconfig_gui := function( ref gui, w, ref private, public ) {
  
  # If the GUI exists but isn't mapped, remap it and return

  if ( is_agent( gui ) ) {
    gui->map();
    w.whenever_activate( 'gui' );
    return( F );
  }
  
  
  # Create a new GUI
  
  tk_hold();
  
  val gui := frame( title = private.window, side = 'top' );
  
  val gui.dumphds := F;
  
  val gui.frame1 := frame( gui, side = 'left' );
  
  val gui.lf := frame( gui.frame1, side = 'top' );
  
  numinputbeam := public.numinputbeam();
  val gui.numinputbeam := label( gui.lf,
      spaste( numinputbeam, ' input beams' ) );
  
  val gui.lf1 := frame( gui.lf, side = 'left' );
  
  val gui.lb := listbox( gui.lf1, mode = 'single', relief = 'sunken',
      height = 9, width = 15 );
  for ( i in 1:numinputbeam ) {
    gui.lb->insert( sprintf( "%s", as_string( i ) ) );
  }
  gui.lb->select( as_string( 0 ) );
  whenever gui.lb->select do {
    __ibconfig_gui_update( gui, private, public );
  }
  whenever gui.lb->yscroll do {
    gui.sb->view( $value );
  }
  w.whenever_add( 'gui', 'lb' );
 
  val gui.sb := scrollbar( gui.lf1 );
  whenever gui.sb->scroll do {
    gui.lb->view( $value );
  }
  w.whenever_add( 'gui', 'sb' );
  
  val gui.rf := frame( gui.frame1, side = 'top' );
  
  val gui.inputbeam := label( gui.rf, '' );
  
  val gui.text := text( gui.rf, relief = 'sunken', width = 60, height = 9 );
  
  val gui.frame2 := frame( gui, side = 'right' );
  
  val gui.dismiss := button( gui.frame2, 'Dismiss', relief = 'raised',
      background = 'orange' );
  whenever gui.dismiss->press do {
    gui->unmap();
    w.whenever_deactivate( 'gui' );
    if ( is_agent( gui.dumphds ) ) {
      gui.dumphds->unmap();
      w.whenever_deactivate( 'dumphdsgui' );
    }
  }
  w.whenever_add( 'gui', 'dismiss' );
  
  val gui.space := label( gui.frame2, ' ' );
  
  val gui.help := button( gui.frame2, 'Help', type = 'menu',
      relief = 'raised' );
  
  val gui.aips2 := button( gui.help, 'Aips++', relief = 'flat' );
  whenever gui.aips2->press do {
    public.web();
  }
  w.whenever_add( 'gui', 'aips2' );
  
  val gui.ask := button( gui.help, 'Ask question', relief = 'flat' );
  whenever gui.ask->press do {
    ask();
  }
  w.whenever_add( 'gui', 'ask' );
  
  val gui.bug := button( gui.help, 'Report bug', relief = 'flat' );
  whenever gui.bug->press do {
    bug();
  }
  w.whenever_add( 'gui', 'bug' );
  
  val gui.dump := button( gui.frame2, 'Dump', relief = 'raised',
      type = 'menu' );
  
  val gui.hds := button( gui.dump, 'HDS', relief = 'flat' );
  whenever gui.hds->press do {
    __ibconfig_gui_dumphds( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'hds' );
  
  whenever gui->killed do {
    val gui := F;
    w.whenever_delete();
  }
  w.whenever_add( 'gui', 'killed' );

  __ibconfig_gui_update( gui, private, public );
  
  tk_release();

  
  # Return T
 
  return( T );
  
}

# ------------------------------------------------------------------------------

# __ibconfig_gui_update

# Description:
# ------------
# This glish function updates a GUI for an ibconfig tool.

# Inputs:
# -------
# gui     - The GUI variable.
# private - The private variable.
# public  - The public variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2000 Aug 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __ibconfig_gui_update := function( ref gui, ref private, public ) {
  
  # If the GUI doesn't exist, return
  
  if ( !is_agent( gui ) ) {
    return( F );
  }
  
  
  # Update the GUI

  inputbeam := gui.lb->selection()+1;
  
  inputbeamid := public.inputbeamid( inputbeam );
  bcinputid := public.bcinputid( inputbeam );
  delaylineid := public.delaylineid( inputbeam );
  startrackerid := public.startrackerid( inputbeam );
  stationid := public.stationid( inputbeam );
  stationcoord := public.stationcoord( inputbeam );
  
  gui.inputbeam->text( spaste( 'input beam = ', as_string( inputbeam ) ) );
  
  text := spaste( 'Input-beam ID            = ', inputbeamid, '\n' );
  text := spaste( text, 'Beam-combiner input ID   = ', bcinputid, '\n' );
  text := spaste( text, 'Delay-line ID            = ', delaylineid, '\n' );
  text := spaste( text, 'Star-tracker ID          = ', startrackerid, '\n' );
  text := spaste( text, 'Station ID               = ', stationid, '\n' );
  text := spaste( text, 'X station coordinate (m) = ', stationcoord[1], '\n' );
  text := spaste( text, 'Y station coordinate (m) = ', stationcoord[2], '\n' );
  text := spaste( text, 'Z station coordinate (m) = ', stationcoord[3], '\n' );
  text := spaste( text, 'Constant term (m)        = ', stationcoord[4] );
  
  gui.text->disabled( F );
  gui.text->delete( 'start', 'end' );
  gui.text->append( text );
  gui.text->disabled( T );
  
  
  # Return T
  
  return( T );
  
}

# ------------------------------------------------------------------------------

# __ibconfig_gui_dumphds

# Description:
# ------------
# This glish function creates the dumphds GUI for an ibconfig tool.

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
# 2000 Aug 27 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __ibconfig_gui_dumphds := function( ref gui, w, ref private, public ) {

  # If the dumphds GUI exists but isn't mapped, remap it and return
  
  if ( is_agent( gui.dumphds ) ) {
    gui.dumphds->map();
    w.whenever_activate( 'dumphdsgui' );
    return( F );
  }
  
  
  # Create the dumphds GUI
    
  tk_hold();
  
  val gui.dumphds := frame( title = spaste( private.window, ' dump hds' ),
      side = 'left' );
    
  val gui.dumphds.label := label( gui.dumphds, 'File: ' );
  
  val gui.dumphds.entry := entry( gui.dumphds, width = 30 );
  gui.dumphds.entry->insert( 'file.sdf' );
  whenever gui.dumphds.entry->return do {
    ret := public.dumphds( gui.dumphds.entry->get() );
    if ( !is_fail( ret ) ) {
      gui.dumphds->unmap();
    }
  }
  w.whenever_add( 'dumphdsgui', 'entry' );
    
  val gui.dumphds.space1 := label( gui.dumphds, ' ' );
  
  val gui.dumphds.dump := button( gui.dumphds, 'Dump' );
  whenever gui.dumphds.dump->press do {
    ret := public.dumphds( gui.dumphds.entry->get() );
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
