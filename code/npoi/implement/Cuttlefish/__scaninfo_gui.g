# __scaninfo_gui.g is part of the Cuttlefish server
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
# $Id: __scaninfo_gui.g,v 19.0 2003/07/16 06:02:23 aips2adm Exp $
# ------------------------------------------------------------------------------

# __scaninfo_gui.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for the gui in scaninfo tools.  NB:
# These functions should be called only by scaninfo tools.

# glish function:
# ---------------
# __scaninfo_gui, __scaninfo_gui_update, __scaninfo_gui_dumpascii,
# __scaninfo_gui_dumphds.

# Modification history:
# ---------------------
# 2000 Aug 22 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __scaninfo_gui( ),
#               __scaninfo_gui_update( ), __scaninfo_gui_dumpascii( ),
#               __scaninfo_gui_dumphds( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __scaninfo_gui

# Description:
# ------------
# This glish function creates a GUI for a scaninfo tool.

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
# 2000 Aug 22 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __scaninfo_gui := function( ref gui, w, ref private, public ) {
  
  # If the GUI exists but isn't mapped, remap it and return

  if ( is_agent( gui ) ) {
    gui->map();
    w.whenever_activate( 'gui' );
    return( F );
  }
  
  
  # Create a new GUI
  
  tk_hold();
  
  val gui := frame( title = private.window, side = 'top' );

  val gui.dumpascii := F;
  val gui.dumphds := F;
  
  val gui.frame1 := frame( gui, side = 'left' );
  
  val gui.lf := frame( gui.frame1, side = 'top' );
  
  private.setstariddefault();
  starid := public.starlist();
  val gui.starid := label( gui.lf, spaste( length(starid), ' star IDs' ) );
  
  val gui.lf1 := frame( gui.lf, side = 'left' );

  val gui.llb := listbox( gui.lf1, mode = 'extended', relief = 'sunken',
      height = 12, width = 20 );
  for ( s in 1:length(starid) ) {
    line := sprintf( "%s", starid[s] );
    gui.llb->insert( line );
  }
  whenever gui.llb->yscroll do {
    gui.lsb->view( $value );
  }
  w.whenever_add( 'gui', 'llb' );
 
  val gui.lsb := scrollbar( gui.lf1 );
  whenever gui.lsb->scroll do {
    gui.llb->view( $value );
  }
  w.whenever_add( 'gui', 'lsb' );
  
  val gui.lf2 := frame( gui.lf, side = 'left' );
  
  val gui.add := button( gui.lf2, 'Add', relief = 'raised' );
  whenever gui.add->press do {
    selection := gui.llb->selection()+1;
    if ( length( selection ) > 0 ) {
      private.addstarid( public.starlist()[selection] );
      __scaninfo_gui_update( gui, private, public );
    }
  }
  w.whenever_add( 'gui', 'add' );
  
  val gui.remove := button( gui.lf2, 'Remove', relief = 'raised' );
  whenever gui.remove->press do {
    selection := gui.llb->selection()+1;
    starid := private.getstarid();
    if ( length( selection ) > 0 ) {
      private.removestarid( public.starlist()[selection] );
      __scaninfo_gui_update( gui, private, public );
    }
  }
  w.whenever_add( 'gui', 'remove' );
  
  val gui.reset := button( gui.lf2, 'Reset', relief = 'raised' );
  whenever gui.reset->press do {
    private.setstariddefault();
    __scaninfo_gui_update( gui, private, public );
  }
  w.whenever_add( 'gui', 'reset' );
  
  val gui.rf := frame( gui.frame1, side = 'top' );
  
  val gui.numscan := label( gui.rf, '0 scans' );
  
  val gui.rf1 := frame( gui.rf, side = 'left' );

  val gui.rlb := listbox( gui.rf1, mode = 'extended', relief = 'sunken',
      height = 12, width = 75 );
  whenever gui.rlb->yscroll do {
    gui.rsb->view( $value );
  }
  w.whenever_add( 'gui', 'rlb' );
 
  val gui.rsb := scrollbar( gui.rf1 );
  whenever gui.rsb->scroll do {
    gui.rlb->view( $value );
  }
  w.whenever_add( 'gui', 'rsb' );
  
  val gui.rf2 := frame( gui.rf, side = 'left' );
  
  val gui.sort := label( gui.rf2, 'Sort by: ' );
  
  val gui.timeonly := button( gui.rf2, 'Time Only', relief = 'raised',
      type = 'radio' );
  gui.timeonly->state( T );
  whenever gui.timeonly->press do {
    __scaninfo_gui_update( gui, private, public );
  }
  w.whenever_add( 'gui', 'time' );
  
  val gui.starandtime := button( gui.rf2, 'Star and Time', relief = 'raised',
      type = 'radio' );
  whenever gui.starandtime->press do {
    __scaninfo_gui_update( gui, private, public );
  }
  w.whenever_add( 'gui', 'star' );
  
  val gui.frame2 := frame( gui, side = 'right' );
  
  val gui.dismiss := button( gui.frame2, 'Dismiss', relief = 'raised',
      background = 'orange' );
  whenever gui.dismiss->press do {
    gui->unmap();
    w.whenever_deactivate( 'gui' );
    if ( is_agent( gui.dumpascii ) ) {
      gui.dumpascii->unmap();
      w.whenever_deactivate( 'dumpasciigui' );
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
  
  val gui.ascii := button( gui.dump, 'ASCII', relief = 'flat' );
  whenever gui.ascii->press do {
    __scaninfo_gui_dumpascii( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'ascii' );
  
  val gui.hds := button( gui.dump, 'HDS', relief = 'flat' );
  whenever gui.hds->press do {
    __scaninfo_gui_dumphds( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'hds' );
  
  whenever gui->killed do {
    val gui := F;
    private.setstariddefault();
    w.whenever_delete();
  }
  w.whenever_add( 'gui', 'killed' );

  __scaninfo_gui_update( gui, private, public );
  
  tk_release();

  
  # Return T
 
  return( T );
  
}

# ------------------------------------------------------------------------------

# __scaninfo_gui_update

# Description:
# ------------
# This glish function updates a GUI for a scaninfo tool.

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
# 2000 Aug 22 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __scaninfo_gui_update := function( ref gui, ref private, public ) {
  
  # If the GUI doesn't exist, return
  
  if ( !is_agent( gui ) ) {
    return( F );
  }
  
  
  # Update the GUI
  
  gui.rlb->delete( 'start', 'end' );
    
  starid := private.getstarid();

  if ( length( starid ) == 0 ) {
    gui.numscan->text( '0 scans' );
    return( T );
  }
  
  scan := public.scan( starid = starid );
  scanid := public.scanid( starid = starid );
  starid := public.starid( starid = starid );
  scantime := public.scantime( starid = starid, hms = T );
  ra := public.ra( starid = starid, hms = T );
  dec := public.dec( starid = starid, dms = T );
  
  if ( gui.starandtime->state() ) {
    o := order( starid );
    scan := scan[o];
    scanid := scanid[o];
    starid := starid[o];
    scantime := scantime[o];
    ra := ra[o];
    dec := dec[o];
  }
  
  gui.numscan->text( spaste( length(scan), ' scans' ) );
  
  for ( s in 1:length(scan) ) {
    line := sprintf( "%03d %03d %11s %20s %20s %21s", scan[s], scanid[s],
        starid[s], scantime[s], ra[s], dec[s] );
    gui.rlb->insert( line );
  }
  
  
  # Return T
  
  return( T );
  
}

# ------------------------------------------------------------------------------

# __scaninfo_gui_dumpascii

# Description:
# ------------
# This glish function creates the dumpascii GUI for a scaninfo tool.

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
# 2000 Aug 22 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __scaninfo_gui_dumpascii := function( ref gui, w, ref private, public ) {

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
    ret := public.dumpascii( gui.dumpascii.entry->get(),
        starid = private.getstarid() );
    if ( !is_fail( ret ) ) {
      gui.dumpascii->unmap();
    }
  }
  w.whenever_add( 'dumpasciigui', 'entry' );
    
  val gui.dumpascii.space1 := label( gui.dumpascii, ' ' );
  
  val gui.dumpascii.dump := button( gui.dumpascii, 'Dump' );
  whenever gui.dumpascii.dump->press do {
    ret := public.dumpascii( gui.dumpascii.entry->get(),
        starid = private.getstarid() );
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

# __scaninfo_gui_dumphds

# Description:
# ------------
# This glish function creates the dumphds GUI for a scaninfo tool.

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
# 2000 Aug 22 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __scaninfo_gui_dumphds := function( ref gui, w, ref private, public ) {

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
