# __hds_gui.g is part of the HDS server
# Copyright (C) 1999,2000,2001
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
# Correspondence concerning the HDS server should be addressed as follows:
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
# $Id: __hds_gui.g,v 19.0 2003/07/16 06:03:17 aips2adm Exp $
# ------------------------------------------------------------------------------

# __hds_gui.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for GUI of the hdsopen/hdsnew tools.
# NB: These functions should be called only by hdsnew/hdsopen tools.

# glish function:
# ---------------
# __hds_gui_private, __hds_gui, _hds_gui_update.

# Modification history:
# ---------------------
# 2000 Aug 30 - Nicholas Elias, USNO/NPOI
#               File created with glish functions __hds_gui_private( ),
#               __hds_gui( ), _hds_gui_update( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __hds_gui_private

# Description:
# ------------
# This glish function creates private member functions for the GUI of the
# hdsnew/hdsopen tools.

# Inputs:
# -------
# private - The private variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2000 Aug 30 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __hds_gui_private := function( ref private, ref public ) {

  # Define the private member variables
  
  val private.sizemax := 1000;
  
  
  # Define the 'checkslice' private member function

  val private.checkSliceRec :=
      [_method = 'checkSlice', _sequence = private.id._sequence];
      
  const val private.checkslice := function( dims1, dims2 ) {
    wider private;
    private.checkSliceRec.dims1 := dims1;
    private.checkSliceRec.dims2 := dims2;
    return( defaultservers.run( private.agent, private.checkSliceRec ) );
  }
  
  
  # Define the 'checksameslice' private member function

  val private.checkSameSliceRec :=
      [_method = 'checkSameSlice', _sequence = private.id._sequence];
      
  const val private.checksameslice := function( dims1, dims2 ) {
    wider private;
    private.checkSameSliceRec.dims1 := dims1;
    private.checkSameSliceRec.dims2 := dims2;
    return( defaultservers.run( private.agent, private.checkSameSliceRec ) );
  }
  
  
  # Define the 'namestring' private member function
  
  const val private.namestring := function( ) {
    wider public;
    pathList := split( public.path(), '.' );
    nameString := pathList[length(pathList)];
    return( nameString );
  }
  
  
  # Define the 'shapestring' private member function
  
  const val private.shapestring := function( ) {
    wider public;
    local shape := public.shape();
    if ( length( shape ) > 1 ) {
      shapeString := spaste( shape );
    } else {
      if ( shape > 0 ) {
        shapeString := spaste( '[', shape, ']' );
      } else {
        shapeString := '[0]';
      }
    }
    return( shapeString );
  }


  # Define the 'character' private member function

  const val private.character := function( ) {
    wider private, public;
    type := public.type();
    if ( type ~ m/^\s+$/ ) {
      type := '';
    }
    if ( public.prim() ) {
      object := ' PRIMITIVE';
    } else {
      object := ' STRUCTURE';
    }
    character := spaste( private.shapestring(), type, object );
    return( character );
  }
  
  
  # Define the 'titlebar' private member function
  
  const val private.titlebar := function( ) {
    wider private, public;
    titlebar := spaste( public.filetail(), ' ', private.namestring(), ' ',
        public.locator(), ': ', private.character() );
    return( titlebar );
  }
  
  
  # Define the 'increment' private member function
  
  const val private.increment := function( ref dims, dimsMin, dimsMax,
      dim = 1 ) {
    wider private;
    if ( all( dims >= dimsMax ) ) {
      return( T );
    }
    tmp := dims[dim];
    tmpMax := dimsMax[dim];
    if ( tmp < tmpMax ) {
      val dims[dim] := tmp + 1;
      return( T );
    } else {
      private.increment( dims, dimsMin, dimsMax, dim+1 );
      val dims[dim] := dimsMin[dim];
      return( T );
    }
  }
  
  
  # Return T
  
  return( T );

}

# ------------------------------------------------------------------------------

# __hds_gui

# Description:
# ------------
# This glish function creates a GUI for the hdsnew/hdsopen tools.

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
# 2000 Aug 30 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __hds_gui := function( ref gui, ref w, ref private, public ) {

  # If the GUI exists but isn't mapped, remap it and return

  if ( is_agent( gui ) ) {
    gui->map();
    w.whenever_activate( 'gui' );
    return( F );
  }
  
  
  # Create the GUI window
  
  tk_hold();
  
  val gui := frame( side = 'top' );
  
  val gui.frame1 := frame( gui, side = 'left' );
  
  
  # Create the litsbox and scrollbars
  
  val gui.lb := listbox( gui.frame1, mode = 'single', relief = 'sunken',
      fill = 'both', height = 10, width = 85 );
  
  whenever gui.lb->xscroll do {
    gui.sbx->view( $value );
  }
  w.whenever_add( 'gui', 'lbx' );
  
  whenever gui.lb->yscroll do {
    gui.sby->view( $value );
  }
  w.whenever_add( 'gui', 'lby' );

  whenever gui.lb->select do {
    wider gui, public;
    if ( public.struc() && length( $value ) > 0 ) {
      element := gui.lb->get( $value ) ~ s/^(.+)\*$/$1/;
      if ( element !~ m/^.+\([0-9,]+\)$/ ) {
        name := as_string( element ~ s/^(.+)\(.+$/$1/ )
        public.find( name );
      } else {
        cell := as_integer( split( element ~ s/^.+\(([0-9,]+)\)$/$1/, ',' ) );
        public.cell( cell );
      }
    }
  }
  
  val gui.sby := scrollbar( gui.frame1, orient = 'vertical' );
  whenever gui.sby->scroll do {
    gui.lb->view( $value );
  }
  w.whenever_add( 'gui', 'sby' );

  val gui.frame2 := frame( gui, side = 'right', expand = 'x' );
  
  val gui.space1 := label( gui.frame2, '  ' );
  
  val gui.sbx := scrollbar( gui.frame2, orient = 'horizontal' );
  whenever gui.sbx->scroll do {
    gui.lb->view( $value );
  }
  w.whenever_add( 'gui', 'sbx' );
  
  
  # Create the slicer

  val gui.frame3 := frame( gui, side = 'left', expand = 'x' );
  
  val gui.frame3l := frame( gui.frame3, side = 'top', expand = 'none' );
  
  val gui.frame4low := frame( gui.frame3l, side = 'left' );
  val gui.labellow := label( gui.frame4low, 'Low: ' );
  val gui.entrylow := entry( gui.frame4low, width = 20, relief = 'sunken' );
  
  val gui.frame4high := frame( gui.frame3l, side = 'left' );
  val gui.labelhigh := label( gui.frame4high, 'High: ' );
  val gui.entryhigh := entry( gui.frame4high, width = 20, relief = 'sunken' );
  
  val gui.slice := button( gui.frame3, 'Slice', relief = 'raised' );
  
  whenever gui.slice->press do {
    slicelow := as_integer( split( gui.entrylow->get(), ' ,' ) );
    slicehigh := as_integer( split( gui.entryhigh->get(), ' ,' ) );
    if ( private.checkslice( slicelow, slicehigh ) &&
         !private.checksameslice( slicelow, slicehigh ) ) {
      public.slice( slicelow, slicehigh );
    }
  }
  w.whenever_add( 'gui', 'slice' );
  
  
  # Create the annul, top, and dismiss buttons

  val gui.frame3r := frame( gui.frame3, side = 'right' );
  
  val gui.dismiss := button( gui.frame3r, 'Dismiss', relief = 'raised',
      background = 'Orange' );
  whenever gui.dismiss->press do {
    gui->unmap();
    w.whenever_deactivate( 'gui' );
  }
  w.whenever_add( 'gui', 'dismiss' );

  val gui.space2 := label( gui.frame3r, ' ' );
  
  val gui.help := button( gui.frame3r, 'Help', type = 'menu',
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
  
  val gui.space3 := label( gui.frame3r, ' ' );
  
  val gui.top := button( gui.frame3r, 'Top', relief = 'raised' );
  whenever gui.top->press do {
    if ( public.locator() > 1 ) {
      public.top();
    }
  }
  w.whenever_add( 'gui', 'top' );
  
  val gui.annul := button( gui.frame3r, 'Annul', relief = 'raised' );
  whenever gui.annul->press do {
    if ( public.locator() > 1 ) {
      public.annul();
    }
  }
  w.whenever_add( 'gui', 'annul' );
  
  
  # Set the killed-window behavior
  
  whenever gui->killed do {
    val gui := F;
    w.whenever_delete( 'gui' );
  }
  w.whenever_add( 'gui', 'killed' );
  
  tk_release();
  
  
  # Initialize the GUI

  __hds_gui_update( gui, private, public );
  
  
  # Return T
  
  return( T );

}

# ------------------------------------------------------------------------------

# __hds_gui_update

# Description:
# ------------
# This glish function updates the GUI for the hdsnew/hdsopen tools.

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
# 2000 Aug 30 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __hds_gui_update := function( ref gui, ref private, public ) {

  # If the GUI doesn't exist, return

  if ( !is_agent( gui ) ) {
    return( F );
  }
  
  
  # Update the GUI
  
  gui->title( private.titlebar() );
  
  numdim := public.numdim();
  
  if ( public.struc() || numdim == 0 ) {
    gui.entrylow->delete( 'start', 'end' );
    gui.entrylow->disabled( T );
    gui.entryhigh->delete( 'start', 'end' );
    gui.entryhigh->disabled( T );
    gui.slice->disabled( T );
  } else {
    local shape := public.shape();
    slicelow := paste( as_string( array( 1, numdim ) ) );
    slicehigh := paste( as_string( shape ) );
    gui.entrylow->disabled( F );
    gui.entrylow->delete( 'start', 'end' );
    gui.entrylow->insert( slicelow );
    gui.entryhigh->disabled( F );
    gui.entryhigh->delete( 'start', 'end' );
    gui.entryhigh->insert( slicehigh );
    gui.slice->disabled( F );
    if ( length( shape ) > 3 ) {
      gui.entrylow->disabled( T );
      gui.entryhigh->disabled( T );
      gui.slice->disabled( T );
    }
  }
  
  if ( public.locator() > 1 ) {
    gui.annul->disabled( F );
    gui.top->disabled( F );
  } else {
    gui.annul->disabled( T );
    gui.top->disabled( T );
  }
  
  gui.lb->delete( 'start', 'end' );
  
  if ( public.struc() ) {
    list := public.list();
    for ( l in list ) {
      gui.lb->insert( l );
    }
  } else {
    if ( length( public.shape() ) > 3 ) {
      gui.lb->insert(
          'HDS does not support slices into >3-dimensional arrays, sorry ...' );
    } else if ( public.size() <= private.sizemax ) {
      list := public.get();
      if ( public.type() ~ m/^_CHAR\*[0-9]+$/i && all( list ~ m/\n/g ) ) {
        list := split( list, '\n' );
        for ( l in list ) {
          gui.lb->insert( as_string( l ) );
        }
      } else {
        if ( public.size() > 1 ) {
          dimsMax := public.shape();
        } else {
          dimsMax := 1;
        }
        dimsMin := array( 1, length(dimsMax) );
        dims := dimsMin;
        for ( l in list ) {
          gui.lb->insert( as_string( spaste( dims, ':  ', l ) ) );
          private.increment( dims, dimsMin, dimsMax );
        }
      }
    } else {
      text := spaste( 'This HDS primitive has more than ', private.sizemax,
          ' elements.  Please use the slicer ...' );
      gui.lb->insert( text );
    }
  }
  
  
  # Return T
  
  return( T );
  
}
