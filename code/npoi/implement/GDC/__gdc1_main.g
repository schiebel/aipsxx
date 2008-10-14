# __gdc1_main.g is part of the GDC server
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
# Correspondence concerning the GDC server should be addressed as follows:
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
# $Id: __gdc1_main.g,v 19.0 2003/07/16 06:03:33 aips2adm Exp $
# ------------------------------------------------------------------------------

# __gdc1_main.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for the main gui in gdc1 tools.  NB:
# These functions should be called only by gdc1 tools.

# glish function:
# ---------------
# __gdc1_maingui, __gdc1_maingui_reset, __gdc1_maingui_topbar,
# __gdc1_maingui_bottombar, __gdc1_maingui_file, __gdc1_maingui_hardcopy,
# __gdc1_maingui_size, __gdc1_maingui_tools, __gdc1_maingui_help.

# Modification history:
# ---------------------
# 2000 Jun 13 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __gdc1_maingui( ) and
#               __gdc1_maingui_reset( ).
# 2000 Jun 14 - Nicholas Elias, USNO/NPOI
#               Glish functions __gdc1_maingui_topbar( ),
#               __gdc1_maingui_bottombar( ), __gdc1_maingui_file( ),
#               __gdc1_maingui_hardcopy( ), __gdc1_maingui_size( ),
#               __gdc1_maingui_tools( ), and __gdc1_maingui_help( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __gdc1_maingui

# Description:
# ------------
# This glish function creates a main GUI for a gdc1 tool.

# Inputs:
# -------
# window  - The window name.
# gui     - The GUI variable.
# w       - The whenever manager variable.
# private - The private variable.
# public  - The public variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2000 Jun 13 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_maingui := function( window, ref gui, ref w, ref private,
    public ) {
  
  # If the main GUI exists but isn't mapped, remap it and return

  if ( is_agent( gui ) ) {
    gui->map();
    w.whenever_activate( 'gui' );
    return( F );
  }


  # Initialize the window names

  if ( window != '' ) {
    private.window.main := window;
  } else {
    private.window.main := private.window.default;
  }
  private.window.dumpascii := spaste( private.window.main, ': dump ascii' );
  private.window.edit := spaste( private.window.main, ': edit' );
  private.window.hardcopy := spaste( private.window.main, ': hardcopy' );
  private.window.label := spaste( private.window.main, ': label' );
  private.window.size := spaste( private.window.main, ': size' );
  private.window.stats := spaste( private.window.main, ': stats' );
  private.window.zoom := spaste( private.window.main, ': zoom' );
  
  
  # Create a new main GUI

  tk_hold();

  val private.trans := T;
  val private.sizetext := 'Transparency';
  
  val gui := frame( title = private.window.main );

  val gui.dumpascii := F;
  val gui.edit := F;
  val gui.hardcopy := F;
  val gui.label := F;
  val gui.pgplot := F;
  val gui.save := F;
  val gui.size := F;
  val gui.stats := F;
  val gui.zoom := F;
  if ( has_field( private, 'guimore_killed' ) ) {
    private.guimore_killed();
  }

  __gdc1_maingui_topbar( gui, w, private, public );

  private.pgplot();

  __gdc1_maingui_bottombar( gui, w, private, public );

  if ( has_field( private, 'guimore' ) ) {
    private.guimore();
  }
  
  whenever gui->resize do {
    private.plot();
  }
  w.whenever_add( 'gui', 'resize' );
  
  whenever gui->killed do {
    val gui.dumpascii := F;
    val gui.edit := F;
    val gui.hardcopy := F;
    val gui.label := F;
    val gui.pgplot := F;
    val gui.save := F;
    val gui.size := F;
    val gui.stats := F;
    val gui.zoom := F;
    if ( has_field( private, 'guimore_killed' ) ) {
      private.guimore_killed();
    }
    val gui := [=];
    w.whenever_delete();
  }
  
  w.whenever_add( 'gui', 'killed' );

  tk_release();

  
  # Return T
 
  return( T );
  
}

# ------------------------------------------------------------------------------

# __gdc1_maingui_reset

# Description:
# ------------
# This glish function resets all GUIs for a gdc1 tool.

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
# 2000 Jun 13 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_maingui_reset := function( ref gui, ref private, public ) {

  # Reset all GUIs
  
  private.setxlabel( private.getxlabel( T ) );
  private.setylabel( private.getylabel( T ) );
  private.settitle( private.gettitle( T ) );
  __gdc1_labelgui_update( gui, private, public );

  private.setline( T );
  private.setkeep( F );
  
  private.fullsize();
  
  public.resethistory();

  private.setflag( T );
  
  
  # Return T
  
  return( T );
  
}

# ------------------------------------------------------------------------------

# __gdc1_maingui_topbar

# Description:
# ------------
# This glish function creates the top bar for the main GUI of a gdc1 tool.

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
# 2000 Jun 14 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_maingui_topbar := function( ref gui, ref w, ref private, public ) {
  
  # Create the top bar
  
  val gui.topbar := frame( gui, side = 'left', expand = 'x',
      relief = 'raised' );
  
  val gui.topbar1 := frame( gui.topbar, side = 'left', expand = 'x',
      relief = 'flat' );

  val gui.topbar2 := frame( gui.topbar, side = 'right', expand = 'x',
      relief = 'flat' );

  __gdc1_maingui_file( gui, w, private, public );
  
  __gdc1_maingui_tools( gui, w, private, public );
  __gdc1_maingui_help( gui, w, private, public );
  
  
  # Return T
    
  return( T );
    
}

# ------------------------------------------------------------------------------

# __gdc1_maingui_bottombar

# Description:
# ------------
# This glish function creates the bottom bar for the main GUI of a gdc1 tool.

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
# 2000 Jun 14 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_maingui_bottombar := function( ref gui, ref w, ref private,
    public ) {
  
  # Create the bottom bar
  
  val gui.bottombar := frame( gui, side = 'left', expand = 'x',
      relief = 'flat' );
  
  val gui.bottombar1 := frame( gui.bottombar, side = 'left', expand = 'x',
      relief = 'flat' );

  val gui.bottombar2 := frame( gui.bottombar, side = 'right', expand = 'x',
      relief = 'flat' );

  val gui.xy := label( gui.bottombar1,
      text = sprintf( 'x = %+1.6e, y = %+1.6e', 0.0, 0.0 ), relief = 'ridge',
      justify = 'center' );

  gui.pgplot->bind( '<Motion>', 'motion' );
  whenever gui.pgplot->motion do {
    wx := $value.world[1];
    wy := $value.world[2];
    gui.xy->text( sprintf( 'x = %+1.6e, y = %+1.6e', wx, wy ) );
  }
  w.whenever_add( 'gui', 'pgplot_motion' );

  val gui.dismiss := button( gui.bottombar2, 'Dismiss', relief = 'raised',
      background = 'Orange' );
  whenever gui.dismiss->press do {
    gui->unmap();
    w.whenever_deactivate( 'gui' );
    if ( is_agent( gui.dumpascii ) ) {
      gui.dumpascii->unmap();
      w.whenever_deactivate( 'dumpasciigui' );
    }
    if ( is_agent( gui.edit ) ) {
      gui.edit->unmap();
      w.whenever_deactivate( 'editgui' );
    }
    if ( is_agent( gui.label ) ) {
      gui.label->unmap();
      w.whenever_deactivate( 'labelgui' );
    }
    if ( is_agent( gui.hardcopy ) ) {
      gui.hardcopy->unmap();
      w.whenever_deactivate( 'hardcopygui' );
    }
    if ( is_agent( gui.size ) ) {
      gui.size->unmap();
      w.whenever_deactivate( 'sizegui' );
    }
    if ( is_agent( gui.stats ) ) {
      gui.stats->unmap();
      w.whenever_deactivate( 'statsgui' );
    }
    if ( is_agent( gui.zoom ) ) {
      gui.zoom->unmap();
      w.whenever_deactivate( 'zoomgui' );
    }
    if ( has_field( private, 'guimore_unmap' ) ) {
      private.guimore_unmap();
    }
  }
  w.whenever_add( 'gui', 'dismiss' );

  val gui.resetgui := button( gui.bottombar2, 'Reset GUI', relief = 'raised' );
  whenever gui.resetgui->press do {
    if ( has_field( private, 'guimore_reset' ) ) {
      private.guimore_reset();
    }
    __gdc1_maingui_reset( gui, private, public );
  }
  w.whenever_add( 'gui', 'resetgui' );
  
  
  # Return T
    
  return( T );
    
}

# ------------------------------------------------------------------------------

# __gdc1_maingui_file

# Description:
# ------------
# This glish function creates the file menu for the main GUI of a gdc1 tool.

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
# 2000 Jun 14 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_maingui_file := function( ref gui, ref w, ref private, public ) {

  # Create the file menu
  
  val gui.file := button( gui.topbar1, 'File', type = 'menu',
      relief = 'flat' );
  
  val gui.bdump := button( gui.file, 'Dump', type = 'menu', relief = 'flat' );

  val gui.bdumpascii := button( gui.bdump, 'ASCII', relief = 'flat' );
  whenever gui.bdumpascii->press do {
    __gdc1_maingui_dumpascii( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'ascii' );
  
  val gui.postscript := button( gui.file, 'PostScript', type = 'menu',
      relief = 'flat' );
  
  val gui.bsize := button( gui.postscript,
      spaste( 'Size = ', private.sizetext ), relief = 'flat' );
  whenever gui.bsize->press do {
    __gdc1_maingui_size( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'size' );
  
  val gui.preview := button( gui.postscript, 'Preview', relief = 'flat' );
  whenever gui.preview->press do {
    private.preview();
  }
  w.whenever_add( 'gui', 'preview' );
  
  val gui.print := button( gui.postscript, 'Print', relief = 'flat' );
  whenever gui.print->press do {
    private.print();
  }
  w.whenever_add( 'gui', 'print' );
  
  val gui.bhardcopy := button( gui.postscript, 'Hardcopy', relief = 'flat' );
  whenever gui.bhardcopy->press do {
    __gdc1_maingui_hardcopy( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'hardcopy' );
  
  
  # Return T
    
  return( T );
    
}

# ------------------------------------------------------------------------------

# __gdc1_maingui_dumpascii

# Description:
# ------------
# This glish function creates the dumpascii GUI for the main GUI of a gdc1 tool.

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
# 2000 Jun 21 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_maingui_dumpascii := function( ref gui, ref w, ref private,
    public ) {

  # If the dumpascii GUI exists but isn't mapped, remap it and return
  
  if ( is_agent( gui.dumpascii ) ) {
    gui.dumpascii->map();
    w.whenever_activate( 'dumpasciigui' );
    return( F );
  }
  
  
  # Create the dumpascii menu
    
  tk_hold();
  
  val gui.dumpascii := frame( title = private.window.dumpascii, side = 'left' );
    
  val gui.dumpascii.label := label( gui.dumpascii, 'File: ' );

  val gui.dumpascii.entry := entry( gui.dumpascii, width = 30 );
  gui.dumpascii.entry->insert( 'file.ascii' );
  whenever gui.dumpascii.entry->return do {
    ret := public.dumpascii( gui.dumpascii.entry->get(), private.getxmin(),
        private.getxmax(), private.getkeep() );
    if ( !is_fail( ret ) ) {
      gui.dumpascii->unmap();
    }
  }
  w.whenever_add( 'dumpasciigui', 'entry' );
    
  val gui.dumpascii.space1 := label( gui.dumpascii, ' ' );
    
  val gui.dumpascii.dump := button( gui.dumpascii, 'Dump' );
  whenever gui.dumpascii.dump->press do {
    ret := public.dumpascii( gui.dumpascii.entry->get(), private.getxmin(),
        private.getxmax(), private.getkeep() );
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

# __gdc1_maingui_hardcopy

# Description:
# ------------
# This glish function creates the hardcopy GUI for the main GUI of a gdc1 tool.

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
# 2000 Jun 14 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_maingui_hardcopy := function( ref gui, ref w, ref private,
    public ) {

  # If the hardcopy GUI exists but isn't mapped, remap it and return
  
  if ( is_agent( gui.hardcopy ) ) {
    gui.hardcopy->map();
    w.whenever_activate( 'hardcopygui' );
    return( F );
  }
  
  
  # Create the hardcopy menu
    
  tk_hold();

  val gui.hardcopy := frame( title = private.window.hardcopy, side = 'left' );
    
  val gui.hardcopy.label := label( gui.hardcopy, 'File: ' );
  val gui.hardcopy.entry := entry( gui.hardcopy, width = 30 );
  gui.hardcopy.entry->insert( 'pgplot.ps' );
  whenever gui.hardcopy.entry->return do {
    file := gui.hardcopy.entry->get();
    if ( file ~ m/^(.+)(\.)(ps|PS)$/ ) {
      ret := private.postscript( file, '/cps' );
      if ( !is_fail( ret ) ) {
        gui.hardcopy->unmap();
      }
    } else {
      member := spaste( private.gconstructor, '.hardcopy' );
      return( throw( 'Invalid file name ...', origin = member ) );
    }
  }
  w.whenever_add( 'hardcopygui', 'entry' );
    
  val gui.hardcopy.space1 := label( gui.hardcopy, ' ' );
    
  val gui.hardcopy.save := button( gui.hardcopy, 'Save' );
  whenever gui.hardcopy.save->press do {
    file := gui.hardcopy.entry->get();
    if ( file ~ m/^(.+)(\.)(ps|PS)$/ ) {
      ret := private.postscript( file, '/cps' );
      if ( !is_fail( ret ) ) {
        gui.hardcopy->unmap();
      }
    } else {
      member := spaste( private.gconstructor, '.hardcopy' );
      return( throw( 'Invalid file name ...', origin = member ) );
    }
  }
  w.whenever_add( 'hardcopygui', 'save' );
    
  val gui.hardcopy.dismiss := button( gui.hardcopy, 'Dismiss',
      background = 'Orange' );
  whenever gui.hardcopy.dismiss->press do {
    gui.hardcopy->unmap();
    w.whenever_deactivate( 'hardcopygui' );
  }
  w.whenever_add( 'hardcopygui', 'dismiss' );
    
  whenever gui.hardcopy->killed do {
    val gui.hardcopy := F;
    w.whenever_delete( 'hardcopygui' );
  }
  w.whenever_add( 'hardcopygui', 'killed' );
    
  tk_release();
  
  
  # Return T
    
  return( T );
    
}

# ------------------------------------------------------------------------------

# __gdc1_maingui_size

# Description:
# ------------
# This glish function creates the size GUI for the main GUI of a gdc1 tool.

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
# 2000 Jun 14 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_maingui_size := function( ref gui, ref w, ref private,
    public ) {

  # If the size GUI exists but isn't mapped, remap it and return
  
  if ( is_agent( gui.size ) ) {
    gui.size->map();
    w.whenever_activate( 'sizegui' );
    return( F );
  }
  
  
  # Create the size menu
  
  tk_hold();

  val gui.size := frame( title = private.window.size, side = 'left' );
  
  val gui.size.trans := button( gui.size, 'Transparency', type = 'radio' );
  whenever gui.size.trans->press do {
    val private.trans := T;
    val private.sizetext := 'Transparency';
    gui.bsize->text( spaste( 'Size = ', private.sizetext ) );
  }
  w.whenever_add( 'sizegui', 'trans' );
  
  val gui.size.pub := button( gui.size, 'Publication', type = 'radio' );
  whenever gui.size.pub->press do {
    val private.trans := F;
    val private.sizetext := 'Publication ';
    gui.bsize->text( spaste( 'Size = ', private.sizetext ) );
  }
  w.whenever_add( 'sizegui', 'pub' );
  
  val gui.size.dismiss := button( gui.size, 'Dismiss', background = 'Orange' );
  whenever gui.size.dismiss->press do {
    gui.size->unmap();
    w.whenever_deactivate( 'sizegui' );
  }
  w.whenever_add( 'sizegui', 'dismiss' );
  
  whenever gui.size->killed do {
    val gui.size := F;
    val private.trans := T;
    val private.sizetext := 'Transparency';
    gui.bsize->text( spaste( 'Size = ', private.sizetext ) );
    w.whenever_delete( 'sizegui' );
  }
  w.whenever_add( 'sizegui', 'killed' );
  
  gui.size.trans->state( T );
  val private.trans := T;
  val private.sizetext := 'Transparency';
  gui.bsize->text( spaste( 'Size = ', private.sizetext ) );
  
  tk_release();
  
  
  # Return T
    
  return( T );
    
}

# ------------------------------------------------------------------------------

# __gdc1_maingui_tools

# Description:
# ------------
# This glish function creates the tools menu for the main GUI of a gdc1 tool.

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
# 2000 Jun 14 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_maingui_tools := function( ref gui, ref w, ref private,
    public ) {
  
  # Create the tools menu
  
  val gui.tools := button( gui.topbar1, 'Tools', type = 'menu',
      relief = 'flat' );
  
  val gui.bedit := button( gui.tools, 'Edit', relief = 'flat' );
  whenever gui.bedit->press do {
    __gdc1_editgui( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'edit' );
  
  val gui.blabel := button( gui.tools, 'Label', relief = 'flat' );
  whenever gui.blabel->press do {
    __gdc1_labelgui( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'label' );
  
  val gui.bstats := button( gui.tools, 'Stats', relief = 'flat' );
  whenever gui.bstats->press do {
    __gdc1_statsgui( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'stats' );
  
  val gui.bzoom := button( gui.tools, 'Zoom', relief = 'flat' );
  whenever gui.bzoom->press do {
    __gdc1_zoomgui( gui, w, private, public );
  }
  w.whenever_add( 'gui', 'zoom' );
  
  
  # Return T
    
  return( T );
    
}

# ------------------------------------------------------------------------------

# __gdc1_maingui_help

# Description:
# ------------
# This glish function creates the help menu for the main GUI of a gdc1 tool.

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
# 2000 Jun 14 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_maingui_help := function( ref gui, ref w, ref private, public ) {
  
  # Create the help menu
  
  val gui.help := button( gui.topbar2, 'Help', type = 'menu', relief = 'flat' );
  
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
  
  
  # Return T
    
  return( T );
    
}
