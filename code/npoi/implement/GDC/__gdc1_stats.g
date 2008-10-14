# __gdc1_stats.g is part of the GDC server
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
# $Id: __gdc1_stats.g,v 19.0 2003/07/16 06:03:34 aips2adm Exp $
# ------------------------------------------------------------------------------

# __gdc1_stats.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for statistics in gdc1 tools.  NB:
# These functions should be called only by gdc1 tools.

# glish function:
# ---------------
# __gdc1_statsgui, __gdc1_statsgui_update.

# Modification history:
# ---------------------
# 2000 Jun 13 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __gdc1_statsgui{ } and
#               __gdc1_statsgui_update{ } added.

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __gdc1_statsgui

# Description:
# ------------
# This glish function creates a statistics GUI for a gdc1 tool.

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

const __gdc1_statsgui := function( ref gui, ref w, ref private, public ) {
  
  # If the stats GUI exists but isn't mapped, remap it and return
  
  if ( is_agent( gui.stats ) ) {
    gui.stats->map();
    w.whenever_activate( 'statsgui' );
    return( F );
  }
  
  
  # Create a new stats GUI
  
  xmin := private.getxmin();
  xmax := private.getxmax();

  tk_hold();
  
  val gui.stats := frame( title = private.window.stats, side = 'top',
      expand = 'none' );
  
  val gui.stats.fm := frame( gui.stats, side = 'left', borderwidth = 0 );
  
  val gui.stats.fm.message := message( gui.stats.fm, borderwidth = 0,
      width = 600 );
      
  val gui.stats.xrange := frame( gui.stats, side = 'left', borderwidth = 0 );
  
  val gui.stats.xrange.label1 := label( gui.stats.xrange, 'X range = ' );
  
  val gui.stats.xrange.min := entry( gui.stats.xrange, width = 10 );
  gui.stats.xrange.min->insert( as_string( xmin ) );
  whenever gui.stats.xrange.min->return do {
    xmin := as_double( gui.stats.xrange.min->get() );
    xmax := as_double( gui.stats.xrange.max->get() );
    private.zoomx( xmin, xmax );
    __gdc1_statsgui_update( gui, private, public );
    __gdc1_editgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'statsgui', 'xrange_min_return' );
  gui.stats.xrange.min->bind( '<Escape>', 'escape' );
  whenever gui.stats.xrange.min->escape do {
    xmin := private.getxmin( T );
    xmax := as_double( gui.stats.xrange.max->get() );
    private.zoomx( xmin, xmax );
    gui.stats.xrange.min->delete( 'start', 'end' );
    gui.stats.xrange.min->insert( as_string( xmin ) );
    __gdc1_statsgui_update( gui, private, public );
    __gdc1_editgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'statsgui', 'xrange_min_escape' );
  
  val gui.stats.xrange.label2 := label( gui.stats.xrange, ' to ' );
  
  val gui.stats.xrange.max := entry( gui.stats.xrange, width = 10 );
  gui.stats.xrange.max->insert( as_string( xmax ) );
  whenever gui.stats.xrange.max->return do {
    xmin := as_double( gui.stats.xrange.min->get() );
    xmax := as_double( gui.stats.xrange.max->get() );
    private.zoomx( xmin, xmax );
    __gdc1_statsgui_update( gui, private, public );
    __gdc1_editgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'statsgui', 'xrange_max_return' );
  gui.stats.xrange.max->bind( '<Escape>', 'escape' );
  whenever gui.stats.xrange.max->escape do {
    xmin := as_double( gui.stats.xrange.min->get() );
    xmax := private.getxmax( T );
    private.zoomx( xmin, xmax );
    gui.stats.xrange.max->delete( 'start', 'end' );
    gui.stats.xrange.max->insert( as_string( xmax ) );
    __gdc1_statsgui_update( gui, private, public );
    __gdc1_editgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'statsgui', 'xrange_max_escape' );
  
  val gui.stats.xrange.label3 := label( gui.stats.xrange, ' ' );
  
  val gui.stats.xrange.keep := button( gui.stats.xrange, 'Keep',
      type = 'check' );
  gui.stats.xrange.keep->state( keep );
  whenever gui.stats.xrange.keep->press do {
    private.setkeep( gui.stats.xrange.keep->state() );
    __gdc1_statsgui_update( gui, private, public );
    __gdc1_editgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'statsgui', 'xrange_keep' );
  
  val gui.stats.xrange.label4 := label( gui.stats.xrange, ' ' );
  
  val gui.stats.xrange.weight := button( gui.stats.xrange, 'Weight',
      type = 'check' );
  gui.stats.xrange.weight->state( F );
  gui.stats.xrange.weight->disabled( !public.yerror() );
  whenever gui.stats.xrange.weight->press do {
    __gdc1_statsgui_update( gui, private, public );
    __gdc1_editgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'statsgui', 'xrange_weight' );
  
  val gui.stats.vspace := label( gui.stats, ' ', borderwidth = 0 );
  
  val gui.stats.bar := frame( gui.stats, side = 'right' );
  
  val gui.stats.bar.dismiss := button( gui.stats.bar, 'Dismiss',
      background = 'Orange' );
  whenever gui.stats.bar.dismiss->press do {
    gui.stats->unmap();
    w.whenever_deactivate( 'statsgui' );
  }
  w.whenever_add( 'statsgui', 'bar_dismiss' );
  
  whenever gui.stats->killed do {
    val gui.stats := F;
    w.whenever_delete( 'statsgui' );
  }
  w.whenever_add( 'statsgui', 'killed' );
  
  private.zoomx( xmin, xmax );
  __gdc1_statsgui_update( gui, private, public );
 
  tk_release();
  
  
  # Return T
  
  return( T );
  
}

# ------------------------------------------------------------------------------

# __gdc1_statsgui_update

# Description:
# ------------
# This glish function updates the stats GUI for a gdc1 tool.

# Inputs:
# -------
# gui     - The GUI variable.
# private - The private variable.
# public  - The public variable.

# Outputs:
# --------
# T, returned via the function value.

# Modification history:
# ---------------------
# 2000 Jun 13 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------
  
const __gdc1_statsgui_update := function( ref gui, ref private, public ) {
  
  # If the stats GUI doesn't exist, return
  
  if ( !is_agent( gui.stats ) ) {
    return( F );
  }
  
  
  # Get the initial parameters
  
  numberInitial := public.length( keep = T );

  flaggedInitial :=
      length( split( as_string( public.flag( orig = T ) ) ~ s/[F+]//g ) );
  
  unflaggedInitial := numberInitial - flaggedInitial;
  
  
  # Get the present parameters

  keep := private.getkeep();
  xmin := private.getxmin();
  xmax := private.getxmax();
  
  number := public.length( xmin, xmax, keep = T );
  
  unflagged := public.length( xmin, xmax, keep = F );
  flagged := number - unflagged;
  
  weight := gui.stats.xrange.weight->state();
  
  
  # Update the stats GUI

  statsgui_message := spaste( 'Data = ', numberInitial, '  Unflagged = ',
      unflaggedInitial, '  Flagged = ', flaggedInitial,
      ' (Initial values)\n\n' );

  statsgui_message := spaste( statsgui_message, '  Data = ', number,
      '  Unflagged = ', unflagged, '  Flagged = ', flagged, '\n' );

  if ( number == 0 || ( unflagged == 0 && !keep ) ) {
    statsgui_message := spaste( statsgui_message, 'Y range = no data\n' );
    statsgui_message := spaste( statsgui_message,
        'Y-error range = no data\n' );
    statsgui_message := spaste( statsgui_message,
        'Mean = undefined mean and mean error\n' );
    statsgui_message := spaste( statsgui_message,
        'Standard Deviation = undefined standard deviation\n' );
    statsgui_message := spaste( statsgui_message,
        'Variance = undefined variance' );
  } else if ( number == 1 || ( unflagged == 1 && !keep ) ) {
    statsgui_message := spaste( statsgui_message, 'Y range = ',
        public.ymin( xmin, xmax, keep ), ' to ',
        public.ymax( xmin, xmax, keep ), '\n' );
    statsgui_message := spaste( statsgui_message, 'X-error range = ' );
    if ( public.xerror() ) {
      statsgui_message := spaste( statsgui_message,
          public.xerrmin( xmin, xmax, keep ), ' to ',
          public.xerrmax( xmin, xmax, keep ), '\n' );
    } else {
      statsgui_message := spaste( statsgui_message, 'no x errors\n' );
    }
    statsgui_message := spaste( statsgui_message, 'Y-error range = ' );
    if ( public.yerror() ) {
      statsgui_message := spaste( statsgui_message,
          public.yerrmin( xmin, xmax, keep ), ' to ',
          public.yerrmax( xmin, xmax, keep ), '\n' );
    } else {
      statsgui_message := spaste( statsgui_message, 'no y errors\n' );
    }
    statsgui_message := spaste( statsgui_message, 'Mean = ',
        public.mean( xmin, xmax, keep, weight ),
        ' +/- undefined mean error\n' );
    statsgui_message := spaste( statsgui_message,
        'Standard Deviation = undefined standard deviation\n' );
    statsgui_message := spaste( statsgui_message,
        'Variance = undefined variance' );
  } else {
    statsgui_message := spaste( statsgui_message, 'Y range = ',
        public.ymin( xmin, xmax, keep ), ' to ',
        public.ymax( xmin, xmax, keep ), '\n' );
    statsgui_message := spaste( statsgui_message, 'X-error range = ' );
    if ( public.xerror() ) {
      statsgui_message := spaste( statsgui_message,
          public.xerrmin( xmin, xmax, keep ), ' to ',
          public.xerrmax( xmin, xmax, keep ), '\n' );
    } else {
      statsgui_message := spaste( statsgui_message, 'no x errors\n' );
    }
    statsgui_message := spaste( statsgui_message, 'Y-error range = ' );
    if ( public.yerror() ) {
      statsgui_message := spaste( statsgui_message,
          public.yerrmin( xmin, xmax, keep ), ' to ',
          public.yerrmax( xmin, xmax, keep ), '\n' );
    } else {
      statsgui_message := spaste( statsgui_message, 'no y errors\n' );
    }
    statsgui_message := spaste( statsgui_message, 'Mean = ',
        public.mean( xmin, xmax, keep, weight ), ' +/- ',
        public.meanerr( xmin, xmax, keep, weight ), '\n' );
    statsgui_message := spaste( statsgui_message, 'Standard Deviation = ',
        public.stddev( xmin, xmax, keep, weight ), '\n' );
    statsgui_message := spaste( statsgui_message, 'Variance = ',
        public.variance( xmin, xmax, keep, weight ) );
  }
  
  gui.stats.fm.message->text( statsgui_message );

  gui.stats.xrange.min->delete( 'start', 'end' );
  gui.stats.xrange.min->insert( as_string( xmin ) );

  gui.stats.xrange.max->delete( 'start', 'end' );
  gui.stats.xrange.max->insert( as_string( xmax ) );

  gui.stats.xrange.keep->state( private.getkeep() );
  
  
  # Return T
  
  return( T );
  
}
