# __gdc2token_zoom.g is part of the GDC server
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
# $Id: __gdc2token_zoom.g,v 19.0 2003/07/16 06:03:41 aips2adm Exp $
# ------------------------------------------------------------------------------

# __gdc2token_zoom.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for zooming in gdc2token tools.  NB:
# These functions should be called only by gdc2token tools.

# glish function:
# ---------------
# __gdc2token_zoomprivate, __gdc2token_zoomgui.

# Modification history:
# ---------------------
# 2000 Dec 30 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __gdc2token_zoomprivate( )
#               and __gdc2token_zoomgui{ }.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __gdc2token_zoomprivate

# Description:
# ------------
# This glish function creates zoom private member functions for a gdc2token
# tool.

# Inputs:
# -------
# private - The private variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2000 Dec 30 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc2token_zoomprivate := function( ref private ) {
  
  # Define the 'getxmin' private member function

  val private.getxminRec :=
      [_method = 'getXMin', _sequence = private.id._sequence];
  
  const val private.getxmin := function( default = F ) {
    wider private;
    val private.getxminRec.default := default;
    return( defaultservers.run( private.agent, private.getxminRec ) );
  }
  
  
  # Define the 'getxmax' private member function

  val private.getxmaxRec :=
      [_method = 'getXMax', _sequence = private.id._sequence];
  
  const val private.getxmax := function( default = F ) {
    wider private;
    val private.getxmaxRec.default := default;
    return( defaultservers.run( private.agent, private.getxmaxRec ) );
  }
  
  
  # Define the 'getymin' private member function

  val private.getyminRec :=
      [_method = 'getYMin', _sequence = private.id._sequence];
  
  const val private.getymin := function( default = F ) {
    wider private;
    val private.getyminRec.default := default;
    return( defaultservers.run( private.agent, private.getyminRec ) );
  }
  
  
  # Define the 'getymax' private member function

  val private.getymaxRec :=
      [_method = 'getYMax', _sequence = private.id._sequence];
  
  const val private.getymax := function( default = F ) {
    wider private;
    val private.getymaxRec.default := default;
    return( defaultservers.run( private.agent, private.getymaxRec ) );
  }
  
  
  # Define the 'zoomx' private member function

  val private.zoomxRec := [_method = 'zoomx', _sequence = private.id._sequence];
  
  const val private.zoomx := function( xmin = [], xmax = [] ) {
    wider private;
    if ( length( xmin ) < 1 ) {
      xmin := private.getxmin();
    }
    if ( length( xmax ) < 1 ) {
      xmax := private.getxmax();
    }
    val private.zoomxRec.xmin := xmin;
    val private.zoomxRec.xmax := xmax;
    return( defaultservers.run( private.agent, private.zoomxRec ) );
  }
  
  
  # Define the 'zoomy' private member function

  val private.zoomyRec := [_method = 'zoomy', _sequence = private.id._sequence];
  
  const val private.zoomy := function( ymin = [], ymax = [] ) {
    wider private;
    if ( length( ymin ) < 1 ) {
      ymin := private.getymin();
    }
    if ( length( ymax ) < 1 ) {
      ymax := private.getymax();
    }
    val private.zoomyRec.ymin := ymin;
    val private.zoomyRec.ymax := ymax;
    return( defaultservers.run( private.agent, private.zoomyRec ) );
  }
  
  
  # Define the 'zoomxy' private member function

  val private.zoomxyRec :=
      [_method = 'zoomxy', _sequence = private.id._sequence];
  
  const val private.zoomxy := function( xmin = [], xmax = [], ymin = [],
      ymax = [] ) {
    wider private;
    if ( length( xmin ) < 1 ) {
      xmin := private.getxmin();
    }
    if ( length( xmax ) < 1 ) {
      xmax := private.getxmax();
    }
    if ( length( ymin ) < 1 ) {
      ymin := private.getymin();
    }
    if ( length( ymax ) < 1 ) {
      ymax := private.getymax();
    }
    val private.zoomxyRec.xmin := xmin;
    val private.zoomxyRec.xmax := xmax;
    val private.zoomxyRec.ymin := ymin;
    val private.zoomxyRec.ymax := ymax;
    return( defaultservers.run( private.agent, private.zoomxyRec ) );
  }
  
  
  # Define the 'fullsize' private member function

  val private.fullsizeRec :=
      [_method = 'fullSize', _sequence = private.id._sequence];
  
  const val private.fullsize := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.fullsizeRec ) );
  }
  
  
  # Return T
  
  return( T );
  
}

# ------------------------------------------------------------------------------

# __gdc2token_zoomgui

# Description:
# ------------
# This glish function creates a zoom GUI for a gdc2token tool.

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
# 2000 Jun 02 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc2token_zoomgui := function( ref gui, ref w, ref private, public ) {
  
  # If the zoom GUI exists but isn't mapped, remap it and return
  
  if ( is_agent( gui.edit ) ) {
    gui.edit->unmap();
    w.whenever_deactivate( 'editgui' );
  }
  
  if ( is_agent( gui.zoom ) ) {
    gui.zoom->map();
    w.whenever_activate( 'zoomgui' );
    return( F );
  }
  
  
  # Create a new zoom GUI
  
  tk_hold();
  
  val gui.zoom := frame( title = private.window.zoom, side = 'left' );
  
  val gui.zoom.zoomx := button( gui.zoom, 'X zoom', type = 'check' );
  gui.zoom.zoomx->state( T );
  whenever gui.zoom.zoomx->press do {
    if ( !gui.zoom.zoomx->state() && !gui.zoom.zoomy->state() ) {
      gui.zoom.zoomy->state( T );
    }
  }
  w.whenever_add( 'zoomgui', 'zoomx' );
  
  val gui.zoom.zoomy := button( gui.zoom, 'Y zoom', type = 'check' );
  gui.zoom.zoomy->state( T );
  whenever gui.zoom.zoomy->press do {
    if ( !gui.zoom.zoomx->state() && !gui.zoom.zoomy->state() ) {
      gui.zoom.zoomx->state( T );
    }
  }
  w.whenever_add( 'zoomgui', 'zoomy' );
  
  val gui.zoom.fullsize := button( gui.zoom, 'Full size' );
  whenever gui.zoom.fullsize->press do {
    private.fullsize();
    __gdc2token_statsgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'zoomgui', 'fullsize' );
  
  val gui.zoom.label1 := label( gui.zoom, ' ' );
  
  val gui.zoom.edit := button( gui.zoom, 'Edit' );
  whenever gui.zoom.edit->press do {
    __gdc2token_editgui( gui, w, private, public );
  }
  
  val gui.zoom.label2 := label( gui.zoom, ' ' );
  
  val gui.zoom.dismiss := button( gui.zoom, 'Dismiss', background = 'Orange' );
  whenever gui.zoom.dismiss->press do {
    gui.zoom->unmap();
    w.whenever_deactivate( 'zoomgui' );
  }
  w.whenever_add( 'zoomgui', 'dismiss' );
  
  whenever gui.zoom->killed do {
    gui.zoom := F;
    w.whenever_delete( 'zoomgui' );
  }
  w.whenever_add( 'zoomgui', 'killed' );
  
  gui.pgplot->bind( '<Button-1>', 'zdown' );
  whenever gui.pgplot->zdown do {
    val gui.zoom.curs1 := $value.world;
    gui.pgplot->cursor( 'rect', gui.zoom.curs1[1], gui.zoom.curs1[2], 2 );
  }
  w.whenever_add( 'zoomgui', 'pgplot_zdown' );
  
  gui.pgplot->bind( '<ButtonRelease-1>', 'zup' );
  whenever gui.pgplot->zup do {
    val gui.zoom.curs2 := $value.world;
    gui.pgplot->cursor( 'rect', gui.zoom.curs2[1], gui.zoom.curs2[2], 2 );
    xmin := min( [gui.zoom.curs1[1],gui.zoom.curs2[1]] );
    xmax := max( [gui.zoom.curs1[1],gui.zoom.curs2[1]] );
    ymin := min( [gui.zoom.curs1[2],gui.zoom.curs2[2]] );
    ymax := max( [gui.zoom.curs1[2],gui.zoom.curs2[2]] );
    if ( gui.zoom.zoomx->state() && gui.zoom.zoomy->state() ) {
      private.zoomxy( xmin, xmax, ymin, ymax );
    } else if ( gui.zoom.zoomx->state() && !gui.zoom.zoomy->state() ) {
      private.zoomx( xmin, xmax );
    } else {
      private.zoomy( ymin, ymax );
    }
    __gdc2token_statsgui_update( gui, private, public );
    private.plot();
    gui.pgplot->cursor( 'norm' );
  }
  w.whenever_add( 'zoomgui', 'pgplot_zup' );
 
  tk_release();
  
  
  # Return T
  
  return( T );
  
}
