# __gdc1_edit.g is part of the GDC server
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
# $Id: __gdc1_edit.g,v 19.0 2003/07/16 06:03:32 aips2adm Exp $
# ------------------------------------------------------------------------------

# __gdc1_edit.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for editing in gdc1 tools.  NB: These
# functions should be called only by gdc1 tools.

# glish function:
# ---------------
# __gdc1_editprivate, __gdc1_editgui, __gdc1_editgui_update.

# Modification history:
# ---------------------
# 2000 Jun 13 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __gdc1_editprivate( ) and
#               __gdc1_editgui{ }.
# 2000 Jun 19 - Nicholas Elias, USNO/NPOI
#               Glish function __gdc1_editgui_update( ) added.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __gdc1_editprivate

# Description:
# ------------
# This glish function creates edit private member functions for a gdc1 tool.

# Inputs:
# -------
# private - The private variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2000 Jun 13 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_editprivate := function( ref private ) {

  # Define the private variables
  
  val private.xorxy := 'XY';
  val private.interpmethod := '';
  
  
  # Define the 'getflag' private member function

  val private.getflagRec :=
      [_method = 'getFlag', _sequence = private.id._sequence];
  
  const val private.getflag := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.getflagRec ) );
  }
  
  
  # Define the 'setflag' private member function

  val private.setflagRec :=
      [_method = 'setFlag', _sequence = private.id._sequence];
  
  const val private.setflag := function( flag ) {
    wider private;
    val private.setflagRec.flag := flag;
    return( defaultservers.run( private.agent, private.setflagRec ) );
  }
  
  
  # Define the 'numevent' private member function

  val private.numeventRec :=
      [_method = 'numEvent', _sequence = private.id._sequence];
  
  const val private.numevent := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.numeventRec ) );
  }
  
  
  # Define the 'getkeep' private member function

  val private.getkeepRec :=
      [_method = 'getKeep', _sequence = private.id._sequence];
  
  const val private.getkeep := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.getkeepRec ) );
  }
  
  
  # Define the 'setkeep' private member function

  val private.setkeepRec := [_method = 'setKeep',
      _sequence = private.id._sequence];
  
  const val private.setkeep := function( keep ) {
    wider private;
    val private.setkeepRec.keep := keep;
    return( defaultservers.run( private.agent, private.setkeepRec ) );
  }
  
  
  # Return T
  
  return( T );
  
}

# ------------------------------------------------------------------------------

# __gdc1_editgui

# Description:
# ------------
# This glish function creates an edit GUI for a gdc1 tool.

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
# 2000 Jun 13 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_editgui := function( ref gui, ref w, ref private, public ) {
  
  # If the edit GUI exists but isn't mapped, remap it and return
  
  if ( is_agent( gui.zoom ) ) {
    gui.zoom->unmap();
    w.whenever_deactivate( 'zoomgui' );
  }
  
  if ( is_agent( gui.edit ) ) {
    gui.edit->map();
    w.whenever_activate( 'editgui' );
    return( F );
  }
  
  
  # Create a new edit GUI
  
  tk_hold();
  
  val gui.edit := frame( title = private.window.edit, side = 'left' );
  
  val gui.edit2 := frame( gui.edit, side = 'left' );
  
  val gui.edit2.x := button( gui.edit2, 'X', type = 'radio' );
  if ( private.xorxy == 'X' ) {
    gui.edit2.x->state( T );
  } else {
    gui.edit2.x->state( F );
  }
  whenever gui.edit2.x->press do {
    private.xorxy := 'X';
  }
  w.whenever_add( 'editgui', 'x' );
  
  val gui.edit2.xy := button( gui.edit2, 'XY', type = 'radio' );
  if ( private.xorxy == 'XY' ) {
    gui.edit2.xy->state( T );
  } else {
    gui.edit2.xy->state( F );
  }
  whenever gui.edit2.xy->press do {
    private.xorxy := 'XY';
  }
  w.whenever_add( 'editgui', 'xy' );
  
  val gui.edit.label1 := label( gui.edit, ' ' );
  
  val gui.edit.interpolate := button( gui.edit, 'Interpolate: None',
      type = 'menu', foreground = 'red', width = 18 );
      
  val gui.edit.nearest := button( gui.edit.interpolate, 'Nearest',
      type = 'radio' );
  whenever gui.edit.nearest->press do {
    private.interpmethod := 'NEAREST';
    gui.edit.interpolate->text( 'Interpolate: Nearest' );
    gui.edit.interpolate->foreground( 'green' );
    gui.edit.flag->disabled( T );
    gui.edit.unflag->disabled( T );
  }
  w.whenever_add( 'editgui', 'nearest' );
  
  val gui.edit.linear := button( gui.edit.interpolate, 'Linear',
      type = 'radio' );
  whenever gui.edit.linear->press do {
    private.interpmethod := 'LINEAR';
    gui.edit.interpolate->text( 'Interpolate: Linear' );
    gui.edit.interpolate->foreground( 'green' );
    gui.edit.flag->disabled( T );
    gui.edit.unflag->disabled( T );
  }
  w.whenever_add( 'editgui', 'linear' );
  
  val gui.edit.cubic := button( gui.edit.interpolate, 'Cubic', type = 'radio' );
  whenever gui.edit.cubic->press do {
    private.interpmethod := 'CUBIC';
    gui.edit.interpolate->text( 'Interpolate: Cubic' );
    gui.edit.interpolate->foreground( 'green' );
    gui.edit.flag->disabled( T );
    gui.edit.unflag->disabled( T );
  }
  w.whenever_add( 'editgui', 'cubic' );
  
  val gui.edit.spline := button( gui.edit.interpolate, 'Spline',
      type = 'radio' );
  whenever gui.edit.spline->press do {
    private.interpmethod := 'SPLINE';
    gui.edit.interpolate->text( 'Interpolate: Spline' );
    gui.edit.interpolate->foreground( 'green' );
    gui.edit.flag->disabled( T );
    gui.edit.unflag->disabled( T );
  }
  w.whenever_add( 'editgui', 'spline' );
  
  val gui.edit.none := button( gui.edit.interpolate, 'None', type = 'radio' );
  gui.edit.none->state( T );
  whenever gui.edit.none->press do {
    private.interpmethod := '';
    gui.edit.interpolate->text( 'Interpolate: None' );
    gui.edit.interpolate->foreground( 'red' );
    gui.edit.flag->disabled( F );
    gui.edit.unflag->disabled( F );
  }
  w.whenever_add( 'editgui', 'none' );

  val gui.edit.flag := button( gui.edit, 'Flag', type = 'radio' );
  gui.edit.flag->state( private.getflag() );
  whenever gui.edit.flag->press do {
    private.setflag( gui.edit.flag->state() );
    __gdc1_editgui_update( gui, private, public );
    __gdc1_statsgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'editgui', 'flag' );
 
  val gui.edit.unflag := button( gui.edit, 'Unflag', type = 'radio' );
  gui.edit.unflag->state( !private.getflag() );
  whenever gui.edit.unflag->press do {
    private.setflag( !gui.edit.unflag->state() );
    private.setkeep( T );
    __gdc1_editgui_update( gui, private, public );
    __gdc1_statsgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'editgui', 'unflag' );
  
  val gui.edit.label2 := label( gui.edit, ' ' );
  
  val gui.edit.keep := button( gui.edit, 'Keep', type = 'check' );
  gui.edit.keep->state( private.getkeep() );
  whenever gui.edit.keep->press do {
    if ( !private.getflag() ) {
      private.setflag( T );
    }
    private.setkeep( gui.edit.keep->state() );
    __gdc1_editgui_update( gui, private, public );
    __gdc1_statsgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'editgui', 'keep' );
  
  val gui.edit.undo := button( gui.edit, 'Undo' );
  if ( private.numevent() < 1 ) {
    gui.edit.undo->disabled( T );
  }
  whenever gui.edit.undo->press do {
    public.undohistory();
  }
  w.whenever_add( 'editgui', 'undo' );
  
  val gui.edit.reset := button( gui.edit, 'Reset' );
  if ( private.numevent() < 1 ) {
    gui.edit.reset->disabled( T );
  }
  whenever gui.edit.reset->press do {
    public.resethistory();
  }
  w.whenever_add( 'editgui', 'reset' );
  
  val gui.edit.label3 := label( gui.edit, ' ' );
  
  val gui.edit.zoom := button( gui.edit, 'Zoom' );
  whenever gui.edit.zoom->press do {
    __gdc1_zoomgui( gui, w, private, public );
  }
  
  val gui.edit.label4 := label( gui.edit, ' ' );
  
  val gui.edit.dismiss := button( gui.edit, 'Dismiss', background = 'Orange' );
  whenever gui.edit.dismiss->press do {
    gui.edit->unmap();
    w.whenever_deactivate( 'editgui' );
  }
  w.whenever_add( 'editgui', 'dismiss' );
  
  whenever gui.edit->killed do {
    val gui.edit := F;
    w.whenever_delete( 'editgui' );
  }
  w.whenever_add( 'editgui', 'killed' );
  
  gui.pgplot->bind( '<Button-1>', 'fdown' );
  whenever gui.pgplot->fdown do {
    val gui.edit.curs1 := $value.world;
    gui.pgplot->cursor( 'rect', gui.edit.curs1[1], gui.edit.curs1[2], 2 );
  }
  w.whenever_add( 'editgui', 'pgplot_fdown' );
  
  gui.pgplot->bind( '<ButtonRelease-1>', 'fup' );
  whenever gui.pgplot->fup do {
    val gui.edit.curs2 := $value.world;
    gui.pgplot->cursor( 'rect', gui.edit.curs2[1], gui.edit.curs2[2], 2 );
    xmin := min( [gui.edit.curs1[1],gui.edit.curs2[1]] );
    xmax := max( [gui.edit.curs1[1],gui.edit.curs2[1]] );
    ymin := min( [gui.edit.curs1[2],gui.edit.curs2[2]] );
    ymax := max( [gui.edit.curs1[2],gui.edit.curs2[2]] );
    if ( private.interpmethod == '' ) {
      if ( private.xorxy == 'X' ) {
        public.setflagx( xmin, xmax, gui.edit.flag->state() );
      } else {
        public.setflagxy( xmin, xmax, ymin, ymax, gui.edit.flag->state() );
      }
    } else {
      if ( private.xorxy == 'X' ) {
        public.interpolatex( xmin, xmax, private.getkeep(),
            private.interpmethod, private.getxmin( F ), private.getxmax( F ) );
      } else {
        public.interpolatexy( xmin, xmax, private.getkeep(),
            private.interpmethod, ymin, ymax, private.getxmin( F ),
            private.getxmax( F ), private.getymin( F ), private.getymax( F ) );
      }
    }
    gui.pgplot->cursor( 'norm' );
  }
  w.whenever_add( 'editgui', 'pgplot_fup' );
  
  __gdc1_editgui_update( gui, private, public );
 
  tk_release();
  
  
  # Return T
  
  return( T );
  
}

# ------------------------------------------------------------------------------

# __gdc1_editgui_update

# Description:
# ------------
# This glish function updates an edit GUI for a gdc1 tool.

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
# 2000 Jun 19 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc1_editgui_update := function( ref gui, ref private, public ) {
  
  # If the edit GUI doesn't exist, return
  
  if ( !is_agent( gui.edit ) ) {
    return( F );
  }
  

  # Update the edit GUI

  gui.edit.flag->state( private.getflag() );
  gui.edit.unflag->state( !private.getflag() );
  
  gui.edit.keep->state( private.getkeep() );
  
  if ( private.numevent() > 0 ) {
    gui.edit.undo->disabled( F );
    gui.edit.reset->disabled( F );
  } else {
    gui.edit.undo->disabled( T );
    gui.edit.reset->disabled( T );
  }
    
  
  # Return T
  
  return( T );

}
