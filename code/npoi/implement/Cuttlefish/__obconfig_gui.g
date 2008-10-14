# __obconfig_gui.g is part of the Cuttlefish server
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
# $Id: __obconfig_gui.g,v 19.0 2003/07/16 06:02:31 aips2adm Exp $
# ------------------------------------------------------------------------------

# __obconfig_gui.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for the gui in obconfig tools.  NB:
# These functions should be called only by obconfig tools.

# glish function:
# ---------------
# __obconfig_gui, __obconfig_gui_update, __obconfig_gui_dumphds.

# Modification history:
# ---------------------
# 2001 Jan 18 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __obconfig_gui( ),
#               __obconfig_gui_update( ), __obconfig_gui_dumphds( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __obconfig_gui

# Description:
# ------------
# This glish function creates a GUI for an obconfig tool.

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
# 2001 Jan 18 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __obconfig_gui := function( ref gui, w, ref private, public ) {
  
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
  
  val gui.lf := frame( gui.frame1, side = 'top', expand = 'none' );
  
  numoutbeam := public.numoutbeam();
  val gui.numoutbeam := label( gui.lf, spaste( numoutbeam, ' output beams' ) );
  
  val gui.lf1 := frame( gui.lf, side = 'left' );
  
  val gui.lb := listbox( gui.lf1, mode = 'single', relief = 'sunken',
      height = 9, width = 15 );
  for ( o in 1:numoutbeam ) {
    gui.lb->insert( sprintf( "%s", as_string( o ) ) );
  }
  gui.lb->select( as_string( 0 ) );
  whenever gui.lb->select do {
    __obconfig_gui_update( gui, private, public );
  }
  whenever gui.lb->yscroll do {
    gui.sbl->view( $value );
  }
  w.whenever_add( 'gui', 'lb' );
 
  val gui.sbl := scrollbar( gui.lf1 );
  whenever gui.sbl->scroll do {
    gui.lb->view( $value );
  }
  w.whenever_add( 'gui', 'sbl' );
  
  val gui.rf := frame( gui.frame1, side = 'top', expand = 'x' );
  
  val gui.outbeam := label( gui.rf, '' );
  
  val gui.rf1 := frame( gui.rf, side = 'left' );
  
  val gui.text := text( gui.rf1, relief = 'sunken', width = 100, height = 10 );
  whenever gui.text->yscroll do {
    gui.sbr->view( $value );
  }
  w.whenever_add( 'gui', 'text' );
 
  val gui.sbr := scrollbar( gui.rf1 );
  whenever gui.sbr->scroll do {
    gui.text->view( $value );
  }
  w.whenever_add( 'gui', 'sbr' );
  
  val gui.frame2 := frame( gui, side = 'right' );
  
  val gui.dismiss := button( gui.frame2, 'Dismiss', relief = 'raised',
      background = 'orange', fill = 'none' );
  whenever gui.dismiss->press do {
    gui->unmap();
    w.whenever_deactivate( 'gui' );
    if ( is_agent( gui.dumphds ) ) {
      gui.dumphds->unmap();
      w.whenever_deactivate( 'dumphdsgui' );
    }
  }
  w.whenever_add( 'gui', 'dismiss' );
  
  val gui.space := label( gui.frame2, ' ', fill = 'none' );
  
  val gui.help := button( gui.frame2, 'Help', type = 'menu',
      relief = 'raised', fill = 'none' );
  
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
      type = 'menu', fill = 'none' );
  
  val gui.hds := button( gui.dump, 'HDS', relief = 'flat' );
  whenever gui.hds->press do {
    __obconfig_gui_dumphds( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'hds' );
  
  whenever gui->killed do {
    val gui := F;
    w.whenever_delete();
  }
  w.whenever_add( 'gui', 'killed' );

  __obconfig_gui_update( gui, private, public );
  
  tk_release();

  
  # Return T
 
  return( T );
  
}

# ------------------------------------------------------------------------------

# __obconfig_gui_update

# Description:
# ------------
# This glish function updates a GUI for an obconfig tool.

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
# 2001 Jan 18 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __obconfig_gui_update := function( ref gui, ref private, public ) {
  
  # If the GUI doesn't exist, return
  
  if ( !is_agent( gui ) ) {
    return( F );
  }
  
  
  # Update the GUI

  outbeam := gui.lb->selection()+1;
  
  numbaseline := public.numbaseline( outbeam );
  numspecchan := public.numspecchan( outbeam );
  spectrometerid := public.spectrometerid( outbeam );
  baselineid := public.baselineid( outbeam );
  wavelength := public.wavelength( outbeam );
  wavelengtherr := public.wavelengtherr( outbeam );
  chanwidth := public.chanwidth( outbeam );
  chanwidtherr := public.chanwidtherr( outbeam );
  fringemod := public.fringemod( outbeam );
  
  gui.outbeam->text( spaste( 'output beam = ', as_string( outbeam ) ) );
  
  text := spaste( 'Number of baselines         = ', numbaseline, '\n' );
  text := spaste( text, 'Number of spectral channels = ', numspecchan, '\n' );
  text := spaste( text, 'Spectrometer ID             = ', spectrometerid,
      '\n' );
  
  text := spaste( text, '\n' );
  
  for ( b in 1:numbaseline ) {
    text := spaste( text, 'Baseline #', as_string( b ), ': ID = ',
        baselineid[b], '; Fringe modulation = ', fringemod[b], '\n' );
  }
  
  text := spaste( text, '\n' );
  
  for ( s in 1:numspecchan ) {
    text := spaste( text, 'Channel #', as_string( s ), ': Wavelength (m) = ',
        sprintf( '%.4e', wavelength[s] ), ' +/- ',
        sprintf( '%.4e', wavelengtherr[s] ), '; Width (m) = ',
        sprintf( '%.4e', chanwidth[s] ), ' +/- ',
        sprintf( '%.4e', chanwidtherr[s] ), '\n' );
  }
  
  gui.text->disabled( F );
  gui.text->delete( 'start', 'end' );
  gui.text->append( text );
  gui.text->see( '1.0' );
  gui.text->disabled( T );
  
  
  # Return T
  
  return( T );
  
}

# ------------------------------------------------------------------------------

# __obconfig_gui_dumphds

# Description:
# ------------
# This glish function creates the dumphds GUI for an obconfig tool.

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
# 2001 Jan 18 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __obconfig_gui_dumphds := function( ref gui, w, ref private, public ) {

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
