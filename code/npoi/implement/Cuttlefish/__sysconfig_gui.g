# __sysconfig_gui.g is part of the Cuttlefish server
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
# $Id: __sysconfig_gui.g,v 19.0 2003/07/16 06:02:33 aips2adm Exp $
# ------------------------------------------------------------------------------

# __sysconfig_gui.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for the gui in sysconfig tools.  NB:
# These functions should be called only by sysconfig tools.

# glish function:
# ---------------
# __sysconfig_gui, __sysconfig_gui_dumphds.

# Modification history:
# ---------------------
# 2001 Jan 26 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __sysconfig_gui( ) and
#               __sysconfig_gui_dumphds( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __sysconfig_gui

# Description:
# ------------
# This glish function creates a GUI for a sysconfig tool.

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
# 2001 Jan 26 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __sysconfig_gui := function( ref gui, w, ref private, public ) {
  
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
  
  val gui.frame1 := frame( gui, side = 'left', borderwidth = 0, padx = 0,
      pady = 0 );
  caption := spaste( 'Date                                         = ',
      public.date() );
  val gui.label1 := label( gui.frame1, caption );
  
  val gui.frame2 := frame( gui, side = 'left', borderwidth = 0, padx = 0,
      pady = 0 );
  caption := spaste( 'System ID                                = ',
      public.systemid() );
  val gui.label2 := label( gui.frame2, caption );
  
  val gui.frame3 := frame( gui, side = 'left', borderwidth = 0, padx = 0,
      pady = 0 );
  caption := spaste( 'User ID                                    = ',
      public.userid() );
  val gui.label3 := label( gui.frame3, caption );
  
  val gui.frame4 := frame( gui, side = 'left', borderwidth = 0, padx = 0,
      pady = 0 );
  caption := spaste( 'Format                                     = ',
      public.format() );
  val gui.label4 := label( gui.frame4, caption );
  
  val gui.frame5 := frame( gui, side = 'left', borderwidth = 0, padx = 0,
      pady = 0 );
  caption := spaste( 'Reference station                     = ', public.refstation() );
  val gui.label5 := label( gui.frame5, caption );
  
  val gui.frame6 := frame( gui, side = 'left', borderwidth = 0, padx = 0,
      pady = 0 );
  caption := spaste( 'Beam-combiner ID                   = ',
      public.beamcombinerid() );
  val gui.label6 := label( gui.frame6, caption );
  
  val gui.frame7 := frame( gui, side = 'left', borderwidth = 0, padx = 0,
      pady = 0 );
  caption := spaste( 'Instrument coherent integration = ',
      public.instrcohint(), ' (ms)' );
  val gui.label7 := label( gui.frame7, caption );
  
  val gui.frame := frame( gui, side = 'right' );
  
  val gui.dismiss := button( gui.frame, 'Dismiss', relief = 'raised',
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
  
  val gui.space := label( gui.frame, ' ', fill = 'none' );
  
  val gui.help := button( gui.frame, 'Help', type = 'menu',
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
  
  val gui.dump := button( gui.frame, 'Dump', relief = 'raised',
      type = 'menu', fill = 'none' );
  
  val gui.hds := button( gui.dump, 'HDS', relief = 'flat' );
  whenever gui.hds->press do {
    __sysconfig_gui_dumphds( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'hds' );
  
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

# __sysconfig_gui_dumphds

# Description:
# ------------
# This glish function creates the dumphds GUI for a sysconfig tool.

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
# 2001 Jan 26 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __sysconfig_gui_dumphds := function( ref gui, w, ref private, public ) {

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
