# __loginfo_gui.g is part of the Cuttlefish server
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
# $Id: __loginfo_gui.g,v 19.0 2003/07/16 06:02:29 aips2adm Exp $
# ------------------------------------------------------------------------------

# __loginfo_gui.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for the gui in loginfo tools.  NB:
# These functions should be called only by loginfo tools.

# glish function:
# ---------------
# __loginfo_gui, __loginfo_gui_dumpascii, __loginfo_gui_dumphds.

# Modification history:
# ---------------------
# 2001 Jan 29 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __loginfo_gui( ),
#               __loginfo_gui_dumpascii( ), __loginfo_gui_dumphds( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __loginfo_gui

# Description:
# ------------
# This glish function creates a GUI for a loginfo tool.

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
# 2001 Jan 29 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __loginfo_gui := function( ref gui, w, ref private, public ) {
  
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
  val gui.dumpascii := F;
  
  val gui.frame1 := frame( gui, side = 'left' );
  
  val gui.text := text( gui.frame1, relief = 'sunken', width = 100,
      height = 15, wrap = 'word' );
  gui.text->insert( public.log(), 'end' );
  gui.text->disabled( T );
  whenever gui.text->yscroll do {
    gui.sb->view( $value );
  }
  w.whenever_add( 'gui', 'text' );
  
  val gui.sb := scrollbar( gui.frame1 );
  whenever gui.sb->scroll do {
    gui.text->view( $value );
  }
  w.whenever_add( 'gui', 'sb' );
  
  val gui.frame2 := frame( gui, side = 'left' );
  
  val gui.label := label( gui.frame2, 'New Line: ' );
  
  val gui.entry := entry( gui.frame2, width = 80, fill = 'x',
      disabled = public.readonly() );
  whenever gui.entry->return do {
    public.append( gui.entry->get() );
    gui.text->disabled( F );
    gui.text->insert( spaste( gui.entry->get(), '\n' ), 'end' );
    gui.text->disabled( T );
    gui.text->see( 'end' );
    gui.entry->delete( 'start', 'end' );
  }
  w.whenever_add( 'gui', 'entry' );
  
  val gui.space1 := label( gui.frame2, ' ' );
  
  val gui.clear := button( gui.frame2, 'Clear', disabled = public.readonly() );
  whenever gui.clear->press do {
    gui.entry->delete( 'start', 'end' );
  }
  w.whenever_add( 'gui', 'clear' );
  
  val gui.append := button( gui.frame2, 'Append',
      disabled = public.readonly() );
  whenever gui.append->press do {
    public.append( gui.entry->get() );
    gui.text->disabled( F );
    gui.text->insert( spaste( gui.entry->get(), '\n' ), 'end' );
    gui.text->disabled( T );
    gui.text->see( 'end' );
    gui.entry->delete( 'start', 'end' );
  }
  w.whenever_add( 'gui', 'append' );
  
  val gui.frame3 := frame( gui, side = 'right' );
  
  val gui.dismiss := button( gui.frame3, 'Dismiss', relief = 'raised',
      background = 'orange', fill = 'none' );
  whenever gui.dismiss->press do {
    gui->unmap();
    w.whenever_deactivate( 'gui' );
    if ( is_agent( gui.dumphds ) ) {
      gui.dumphds->unmap();
      w.whenever_deactivate( 'dumphdsgui' );
    }
    if ( is_agent( gui.dumpascii ) ) {
      gui.dumpascii->unmap();
      w.whenever_deactivate( 'dumpasciigui' );
    }
  }
  w.whenever_add( 'gui', 'dismiss' );
  
  val gui.space2 := label( gui.frame3, ' ', fill = 'none' );
  
  val gui.help := button( gui.frame3, 'Help', type = 'menu',
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
  
  val gui.dump := button( gui.frame3, 'Dump', relief = 'raised',
      type = 'menu', fill = 'none' );
  
  val gui.ascii := button( gui.dump, 'ASCII', relief = 'flat' );
  whenever gui.ascii->press do {
    __loginfo_gui_dumpascii( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'ascii' );
  
  val gui.hds := button( gui.dump, 'HDS', relief = 'flat' );
  whenever gui.hds->press do {
    __loginfo_gui_dumphds( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'hds' );
  
  val gui.print := button( gui.dump, 'Print', relief = 'flat' );
  whenever gui.print->press do {
    public.print();
  }
  w.whenever_add( 'gui', 'print' );
  
  whenever gui->killed do {
    val gui := F;
    w.whenever_delete();
  }
  w.whenever_add( 'gui', 'killed' );
  
  tk_release();

  
  # Return T
 
  return( T );
  
}

# ------------------------------------------------------------------------------

# __loginfo_gui_dumpascii

# Description:
# ------------
# This glish function creates the dumpascii GUI for a loginfo tool.

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
# 2001 Jan 29 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __loginfo_gui_dumpascii := function( ref gui, w, ref private, public ) {

  # If the dumpascii GUI exists but isn't mapped, remap it and return
  
  if ( is_agent( gui.dumpascii ) ) {
    gui.dumpascii->map();
    w.whenever_activate( 'dumpasciigui' );
    return( F );
  }
  
  
  # Create the dumpascii GUI
    
  tk_hold();
  
  val gui.dumpascii := frame( title = spaste( private.window, ' dump ascii' ),
      side = 'left' );
    
  val gui.dumpascii.label := label( gui.dumpascii, 'File: ' );
  
  val gui.dumpascii.entry := entry( gui.dumpascii, width = 30 );
  gui.dumpascii.entry->insert( 'file.ascii' );
  whenever gui.dumpascii.entry->return do {
    ret := public.dumpascii( gui.dumpascii.entry->get() );
    if ( !is_fail( ret ) ) {
      gui.dumpascii->unmap();
    }
  }
  w.whenever_add( 'dumpasciigui', 'entry' );
    
  val gui.dumpascii.space1 := label( gui.dumpascii, ' ' );
  
  val gui.dumpascii.dump := button( gui.dumpascii, 'Dump' );
  whenever gui.dumpascii.dump->press do {
    ret := public.dumpascii( gui.dumpascii.entry->get() );
    if ( !is_fail( ret ) ) {
      gui.dumpascii->unmap();
    }
  }
  w.whenever_add( 'dumpasciigui', 'dump' );
    
  val gui.dumpascii.space2 := label( gui.dumpascii, ' ' );
    
  val gui.dumpascii.dismiss := button( gui.dumpascii, 'Dismiss',
      background = 'Orange' );
  whenever gui.dumpascii.dismiss->press do {
    gui.dumpascii->unmap();
    w.whenever_deactivate( 'dumpasciigui' );
  }
  w.whenever_add( 'dumpasciigui', 'dismiss' );
    
  whenever gui.dumpascii->killed do {
    val gui.dumpascii := F;
    w.whenever_delete( 'dumpasciigui' );
  }
  w.whenever_add( 'dumpasciigui', 'killed' );
    
  tk_release();
  
  
  # Return T
    
  return( T );
    
}

# ------------------------------------------------------------------------------

# __loginfo_gui_dumphds

# Description:
# ------------
# This glish function creates the dumphds GUI for a loginfo tool.

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
# 2001 Jan 29 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __loginfo_gui_dumphds := function( ref gui, w, ref private, public ) {

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
  if ( public.readonly() ) {
    file := 'file.hds';
  } else {
    file := public.file();
  }
  gui.dumphds.entry->insert( file );
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
