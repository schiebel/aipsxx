# __gdc2token_token.g is part of the GDC server
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
# $Id: __gdc2token_token.g,v 19.0 2003/07/16 06:03:41 aips2adm Exp $
# ------------------------------------------------------------------------------

# __gdc2token_token.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions for tokenizing in gdc2token tools.
# NB: These functions should be called only by gdc2token tools.

# glish function:
# ---------------
# __gdc2token_tokenprivate, __gdc2token_tokengui, __gdc2token_tokengui_update.

# Modification history:
# ---------------------
# 2001 Jan 08 - Nicholas Elias, USNO/NPOI
#               File created with glish function __gdc2token_tokenprivate( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __gdc2token_tokenprivate

# Description:
# ------------
# This glish function creates token private member functions for a gdc2token
# tool.

# Inputs:
# -------
# private - The private variable.

# Outputs:
# --------
# T, returned via the function variable.

# Modification history:
# ---------------------
# 2001 Jan 08 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc2token_tokenprivate := function( ref private ) {  
  
  # Define the 'gettoken' private member function

  val private.gettokenRec :=
      [_method = 'getToken', _sequence = private.id._sequence];
  
  const val private.gettoken := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.gettokenRec ) );
  }
  
  # Define the 'getcolumn' private member function

  val private.getcolumnRec :=
      [_method = 'getColumn', _sequence = private.id._sequence];
  
  const val private.getcolumn := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.getcolumnRec ) );
  }
  
  
  # Define the 'settokencolumn' private member function

  val private.settokencolumnRec :=
      [_method = 'setTokenColumn', _sequence = private.id._sequence];
  
  const val private.settokencolumn := function( token, column ) {
    wider private;
    val private.settokencolumnRec.tokenarg := token;
    val private.settokencolumnRec.columnarg := column;
    return( defaultservers.run( private.agent, private.settokencolumnRec ) );
  }
  
  
  # Define the 'settokencolumndefault' private member function

  val private.settokencolumndefaultRec :=
      [_method = 'setTokenColumnDefault', _sequence = private.id._sequence];
  
  const val private.settokencolumndefault := function( ) {
    wider private;
    return( defaultservers.run( private.agent,
        private.settokencolumndefaultRec ) );
  }
  
  
  # Define the 'addtokencolumn' private member function

  val private.addtokencolumnRec :=
      [_method = 'addTokenColumn', _sequence = private.id._sequence];
  
  const val private.addtokencolumn := function( token, column ) {
    wider private;
    val private.addtokencolumnRec.tokenarg := token;
    val private.addtokencolumnRec.columnarg := column;
    return( defaultservers.run( private.agent, private.addtokencolumnRec ) );
  }
  
  
  # Define the 'removetokencolumn' private member function

  val private.removetokencolumnRec :=
      [_method = 'removeTokenColumn', _sequence = private.id._sequence];
  
  const val private.removetokencolumn := function( token,column ) {
    wider private;
    private.removetokencolumnRec.tokenarg := token;
    private.removetokencolumnRec.columnarg := column;
    return( defaultservers.run( private.agent, private.removetokencolumnRec ) );
  }
  
  
  # Define the 'getcolor' private member function

  val private.getcolorRec :=
      [_method = 'getColor', _sequence = private.id._sequence];
  
  const val private.getcolor := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.getcolorRec ) );
  }
  
  
  # Define the 'setcolor' private member function

  val private.setcolorRec :=
      [_method = 'setColor', _sequence = private.id._sequence];
  
  const val private.setcolor := function( color ) {
    wider private;
    val private.setcolorRec.color := color;
    return( defaultservers.run( private.agent, private.setcolorRec ) );
  }
  
  
  # Define the 'getline' private member function

  val private.getlineRec := [_method = 'getLine',
      _sequence = private.id._sequence];
  
  const val private.getline := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.getlineRec ) );
  }
  
  
  # Define the 'setline' private member function

  val private.setlineRec := [_method = 'setLine',
      _sequence = private.id._sequence];
  
  const val private.setline := function( line ) {
    wider private;
    val private.setlineRec.line := line;
    return( defaultservers.run( private.agent, private.setlineRec ) );
  }
  
  
  # Return T
  
  return( T );
  
}

# ------------------------------------------------------------------------------

# __gdc2token_tokengui

# Description:
# ------------
# This glish function creates a token GUI for a gdc2token tool.

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

const __gdc2token_tokengui := function( ref gui, ref w, ref private, public ) {
  
  # If the token GUI exists but isn't mapped, remap it and return
  
  if ( is_agent( gui.token ) ) {
    gui.token->map();
    w.whenever_activate( 'tokengui' );
    return( F );
  }
  
  
  # Create a new token GUI
    
  tk_hold();
    
  val gui.token := frame( title = private.window.token, side = 'top',
      expand = 'none' );
    
  val gui.token.f1 := frame( gui.token, side = 'left', expand = 'none' );
  
  val gui.token.left := frame( gui.token.f1, side = 'top', expand = 'none' );
 
  val gui.token.llabel := label( gui.token.left, 'Token List' );
      
  val gui.token.llist := frame( gui.token.left, side = 'left',
      expand = 'none' );
  
  val gui.token.llb := listbox( gui.token.llist, mode = 'extended',
      relief = 'sunken', height = 11, width = 15, background = 'black',
      foreground = 'white', font = '10x20' );
  tokenTemp := public.tokenlist();
  for ( t in 1:length(tokenTemp) ) {
    gui.token.llb->insert( tokenTemp[t] );
  }
  whenever gui.token.llb->yscroll do {
    gui.token.lsb->view( $value );
  }
  w.whenever_add( 'tokengui', 'llb' );
  
  val gui.token.lsb := scrollbar( gui.token.llist );
  whenever gui.token.lsb->scroll do {
    gui.token.llb->view( $value );
  }
  w.whenever_add( 'tokengui', 'lsb' );
  
  val gui.token.lbar := frame( gui.token.left, side = 'left' );
  
  val gui.token.add := button( gui.token.lbar, 'Add', borderwidth = 1,
      padx = 5 );
  whenever gui.token.add->press do {
    selection := gui.token.llb->selection()+1;
    if ( length( selection ) > 0 ) {
      private.addtoken( public.tokenlist()[selection] );
      __gdc2token_tokengui_update( gui, private, public );
      __gdc2token_statsgui_update( gui, private, public );
      private.plot();
    }
  }
  w.whenever_add( 'tokengui', 'add' );
  
  val gui.token.remove := button( gui.token.lbar, 'Remove', borderwidth = 1,
      padx = 6 );
  whenever gui.token.remove->press do {
    selection := gui.token.llb->selection()+1;
    token := private.gettoken();
    if ( length( selection ) > 0 && length( selection ) < length( token ) ) {
      private.removetoken( public.tokenlist()[selection] );
      __gdc2token_tokengui_update( gui, private, public );
      __gdc2token_statsgui_update( gui, private, public );
      private.plot();
    }
  }
  w.whenever_add( 'tokengui', 'remove' );
  
  val gui.token.reset := button( gui.token.lbar, 'Reset', borderwidth = 1,
      padx = 5 );
  whenever gui.token.reset->press do {
    private.settokendefault();
    __gdc2token_tokengui_update( gui, private, public );
    __gdc2token_statsgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'tokengui', 'reset' );
  
  val gui.token.right := frame( gui.token.f1, side = 'top', expand = 'none' );
  
  val gui.token.rlabel := label( gui.token.right, 'Plotted' );
  
  val gui.token.rlist := frame( gui.token.right, side = 'left',
      expand = 'none' );
  
  val gui.token.rtext := text( gui.token.rlist, relief = 'sunken', height = 13,
      width = 15, disabled = T, background = 'black', font = '10x20' );
  whenever gui.token.rtext->yscroll do {
    gui.token.rsb->view( $value );
  }
  w.whenever_add( 'tokengui', 'rtext' );
  
  val gui.token.rsb := scrollbar( gui.token.rlist );
  whenever gui.token.rsb->scroll do {
    gui.token.rtext->view( $value );
  }
  w.whenever_add( 'tokengui', 'rsb' );
  
  val gui.token.rbar := frame( gui.token.right, side = 'left' );
  
  val gui.token.color := button( gui.token.rbar, 'Color', type = 'check',
      borderwidth = 1, padx = 13, pady = 4 );
  gui.token.color->state( private.getcolor() );
  whenever gui.token.color->press do {
    private.setcolor( gui.token.color->state() );
    __gdc2token_tokengui_update( gui, private, public );
    __gdc2token_statsgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'tokengui', 'color' );
  
  val gui.token.line := button( gui.token.rbar, 'Line', type = 'check',
      borderwidth = 1, padx = 16, pady = 4 );
  gui.token.line->state( private.getline() );
  whenever gui.token.line->press do {
    private.setline( gui.token.line->state() );
    __gdc2token_tokengui_update( gui, private, public );
    __gdc2token_statsgui_update( gui, private, public );
    private.plot();
  }
  w.whenever_add( 'tokengui', 'line' );
  
  val gui.token.f2 := frame( gui.token, side = 'right' );
  
  val gui.token.dismiss := button( gui.token.f2, 'Dismiss',
      background = 'Orange' );
  whenever gui.token.dismiss->press do {
    gui.token->unmap();
    w.whenever_deactivate( 'tokengui' );
  }
  w.whenever_add( 'tokengui', 'dismiss' );
  
  whenever gui.token->killed do {
    val gui.token := F;
    w.whenever_delete( 'tokengui' );
  }
  w.whenever_add( 'tokengui', 'killed' );
    
  __gdc2token_tokengui_update( gui, private, public );
 
  tk_release();
  
  
  # Return T
  
  return( T );
  
}

# ------------------------------------------------------------------------------

# __gdc2token_tokengui_update

# Description:
# ------------
# This glish function updates a token GUI for a gdc2token tool.

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
# 2000 Jun 12 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __gdc2token_tokengui_update := function( ref gui, ref private, public ) {
  
  # If the token GUI doesn't exist, return
  
  if ( !is_agent( gui.token ) ) {
    return( F );
  }
  

  # Get the tokens
    
  tokenTemp := private.gettoken();
  
  
  # Remove the tokens from the token GUI
  
  gui.token.rtext->delete( 'start', 'end' );
  
  for ( t in 1:length(tokenTemp) ) {
    gui.token.rtext->deltag( tokenTemp[t] );
  }
  
  
  # Update the token GUI

  gui.token.color->state( private.getcolor() );
  gui.token.line->state( private.getline() );
  
  for ( t in 1:length(tokenTemp) ) {
    gui.token.rtext->addtag( tokenTemp[t], 'end' );
    if ( private.getcolor() ) {
      gui.token.rtext->config( tokenTemp[t],
          foreground = private.colortable.rgb[t] );
    } else {
      gui.token.rtext->config( tokenTemp[t],
          foreground = private.colortable.rgb[1] );
    }
    gui.token.rtext->insert( spaste( tokenTemp[t], '\n' ), 'end',
        tokenTemp[t] );
  }
  
  if ( length( tokenTemp ) >= length( public.tokenlist() ) ) {
    gui.token.add->disabled( T );
  } else {
    gui.token.add->disabled( F );
  }
  
  if ( length( tokenTemp ) <= 1 ) {
    gui.token.remove->disabled( T );
  } else {
    gui.token.remove->disabled( F );
  }
  
  
  # Return T
  
  return( T );
  
}
