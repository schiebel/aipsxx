# __gdc2token_label.g is part of the GDC server
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
# $Id: __gdc2token_label.g,v 19.0 2003/07/16 06:03:37 aips2adm Exp $
# ------------------------------------------------------------------------------

# __gdc2token_label.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for labelling in gdc2token tools.  NB:
# These functions should be called only by gdc2token tools.

# glish function:
# ---------------
# __gdc2token_labelprivate, __gdc2token_labelgui, __gdc2token_labelgui_update.

# Modification history:
# ---------------------
# 2001 Jan 09 - Nicholas Elias, USNO/NPOI
#               File created with glish function __gdc2token_labelprivate( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __gdc2token_labelprivate

# Description:
# ------------
# This glish function creates label private member functions for a gdc2token
# tool.

# Inputs:
# -------
# private - The private variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2001 Jan 09 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc2token_labelprivate := function( ref private ) {
  
  # Define the 'getxlabel' private member function

  val private.getxlabelRec :=
      [_method = 'getXLabel', _sequence = private.id._sequence];
  
  const val private.getxlabel := function( default = F ) {
    wider private;
    val private.getxlabelRec.default := default;
    return( defaultservers.run( private.agent, private.getxlabelRec ) );
  }
  
  
  # Define the 'setxlabel' private member function

  val private.setxlabelRec :=
      [_method = 'setXLabel', _sequence = private.id._sequence];
  
  const val private.setxlabel := function( xlabel ) {
    wider private;
    val private.setxlabelRec.xlabel := xlabel;
    return( defaultservers.run( private.agent, private.setxlabelRec ) );
  }
  
  
  # Define the 'setxlabeldefault' private member function

  val private.setxlabeldefaultRec :=
      [_method = 'setXLabelDefault', _sequence = private.id._sequence];
  
  const val private.setxlabeldefault := function( xlabel ) {
    wider private;
    val private.setxlabeldefaultRec.xlabel := xlabel;
    return( defaultservers.run( private.agent, private.setxlabeldefaultRec ) );
  }
  
  
  # Define the 'getylabel' private member function

  val private.getylabelRec :=
      [_method = 'getYLabel', _sequence = private.id._sequence];
  
  const private.getylabel := function( default = F ) {
    wider private;
    val private.getylabelRec.default := default;
    return( defaultservers.run( private.agent, private.getylabelRec ) );
  }
  
  
  # Define the 'setylabel' private member function

  val private.setylabelRec :=
      [_method = 'setYLabel', _sequence = private.id._sequence];
  
  const val private.setylabel := function( ylabel ) {
    wider private;
    val private.setylabelRec.ylabel := ylabel;
    return( defaultservers.run( private.agent, private.setylabelRec ) );
  }
  
  
  # Define the 'setylabeldefault' private member function

  val private.setylabeldefaultRec :=
      [_method = 'setYLabelDefault', _sequence = private.id._sequence];
  
  const val private.setylabeldefault := function( ylabel ) {
    wider private;
    val private.setylabeldefaultRec.ylabel := ylabel;
    return( defaultservers.run( private.agent, private.setylabeldefaultRec ) );
  }
  
  
  # Define the 'gettitle' private member function

  val private.gettitleRec :=
      [_method = 'getTitle', _sequence = private.id._sequence];
  
  const val private.gettitle := function( default = F ) {
    wider private;
    val private.gettitleRec.default := default;
    return( defaultservers.run( private.agent, private.gettitleRec ) );
  }
  
  
  # Define the 'settitle' private member function

  val private.settitleRec :=
      [_method = 'setTitle', _sequence = private.id._sequence];
  
  const val private.settitle := function( title ) {
    wider private;
    val private.settitleRec.title := title;
    return( defaultservers.run( private.agent, private.settitleRec ) );
  }
  
  
  # Define the 'settitledefault' private member function

  val private.settitledefaultRec :=
      [_method = 'setTitleDefault', _sequence = private.id._sequence];
  
  const private.settitledefault := function( title ) {
    wider private;
    val private.settitledefaultRec.title := title;
    return( defaultservers.run( private.agent, private.settitledefaultRec ) );
  }
  
  
  # Return T
  
  return( T );
  
}

# ------------------------------------------------------------------------------

# __gdc2token_labelgui

# Description:
# ------------
# This glish function creates a label GUI for a gdc2token tool.

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
# 2000 Jun 12 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc2token_labelgui := function( ref gui, ref w, ref private, public ) {
  
  # If the label GUI exists but isn't mapped, remap it and return
  
  if ( is_agent( gui.label ) ) {
    gui.label->map();
    w.whenever_activate( 'labelgui' );
    return( F );
  }
  
  
  # Create a new label GUI
  
  tk_hold();
  
  val gui.label := frame( title = private.window.label, side = 'top' );
  
  val gui.label.f1 := frame( gui.label, side = 'left' );
  val gui.label.xlabel := label( gui.label.f1, 'x     = ' );
  val gui.label.xentry := entry( gui.label.f1, width = 50 );
  gui.label.xentry->insert( private.getxlabel() );
  
  val gui.label.f2 := frame( gui.label, side = 'left' );
  val gui.label.ylabel := label( gui.label.f2, 'y     = ' );
  val gui.label.yentry := entry( gui.label.f2, width = 50 );
  gui.label.yentry->insert( private.getylabel() );
  
  val gui.label.f3 := frame( gui.label, side = 'left' );
  val gui.label.titlelabel := label( gui.label.f3, 'title = ' );
  val gui.label.titleentry := entry( gui.label.f3, width = 50 );
  gui.label.titleentry->insert( private.gettitle() );
  
  val gui.label.f4 := frame( gui.label, side = 'right' );
  val gui.label.dismiss := button( gui.label.f4, 'Dismiss',
      background = 'Orange' );
  whenever gui.label.dismiss->press do {
    gui.label->unmap();
    w.whenever_deactivate( 'labelgui' );
  }
  w.whenever_add( 'labelgui', 'dismiss' );

  whenever gui.label->killed do {
    val gui.label := F;
    w.whenever_delete( 'labelgui' );
  }
  w.whenever_add( 'labelgui', 'killed' );
  
  val gui.label.hspace1 := label( gui.label.f4, ' ' );
  
  val gui.label.default := button( gui.label.f4, 'Default' );
  whenever gui.label.default->press do {
    gui.label.xentry->delete( 'start', 'end' );
    gui.label.yentry->delete( 'start', 'end' );
    gui.label.titleentry->delete( 'start', 'end' );
    private.setxlabel( private.getxlabel( T ) );
    private.setylabel( private.getylabel( T ) );
    private.settitle( private.gettitle( T ) );
    __gdc2token_labelgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'labelgui', 'default' );
  
  val gui.label.apply := button( gui.label.f4, 'Apply' );
  whenever gui.label.apply->press do {
    private.setxlabel( gui.label.xentry->get() );
    private.setylabel( gui.label.yentry->get() );
    private.settitle( gui.label.titleentry->get() );
    __gdc2token_labelgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'labelgui', 'apply' );
  
  __gdc2token_labelgui_update( gui, private, public );

  tk_release();
  
  
  # Return T
  
  return( T );
  
}

# ------------------------------------------------------------------------------

# __gdc2token_labelgui_update

# Description:
# ------------
# This glish function updates a label GUI for a gdc2token tool.

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

const __gdc2token_labelgui_update := function( ref gui, ref private, public ) {
  
  # If the label GUI doesn't exist, return
  
  if ( !is_agent( gui.label ) ) {
    return( F );
  }
  

  # Update the label GUI
  
  gui.label.xentry->delete( 'start', 'end' );
  gui.label.xentry->insert( private.getxlabel() );
  
  gui.label.yentry->delete( 'start', 'end' );
  gui.label.yentry->insert( private.getylabel() );
  
  gui.label.titleentry->delete( 'start', 'end' );
  gui.label.titleentry->insert( private.gettitle() );
    
  
  # Return T
  
  return( T );

}
