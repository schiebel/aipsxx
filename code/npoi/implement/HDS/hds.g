# hds.g is part of the HDS server
# Copyright (C) 1999,2000
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
# $Id: hds.g,v 19.0 2003/07/16 06:02:55 aips2adm Exp $
# ------------------------------------------------------------------------------

# hds.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++

# Description:
# ------------
# This file contains the glish functions for manipulating any HDS file.

# glish functions:
# ----------------
# _define_hdsmembers, hdsnew, hdsopen.

# Modification history:
# ---------------------
# 1999 Sep 13 - Nicholas Elias, USNO/NPOI
#               File created with glish functions _define_hdsmembers( ),
#               hdsnew( ), and hdsopen( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# Includes

if ( !include 'bug.g' ) {
  throw( 'Cannot include bug.g ...', origin = 'hds' );
}

if ( !include 'note.g' ) {
  throw( 'Cannot include note.g ...', origin = 'hds' );
}

if ( !include 'servers.g' ) {
  throw( 'Cannot include servers.g ...', origin = 'hds' );
}

if ( !include 'check.g' ) {
  throw( 'Cannot include check.g ...', origin = 'hds' );
}

if ( !include 'whenever_manager.g' ) {
  throw( 'Cannot include whenever_manager.g ...', origin = 'hds' );
}

if ( !include '__hds_gui.g' ) {
  throw( 'Cannot include __hds_gui.g ...', origin = 'hds' );
}

# ------------------------------------------------------------------------------

# _define_hdsmembers

# Description:
# ------------
# This glish function defines the member functions for hdsnew and hdsopen.

# Inputs:
# -------
# agent          - The agent.
# id             - The ID.
# constructor    - The constructor name (hdsnew or hdsopen).
# file           - The HDS file name.
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The member functions, returned via the glish function value.

# Modification history:
# ---------------------
# 1999 Sep 15 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const _define_hdsmembers := function( ref agent, id, constructor, file, mode,
    host, forcenewserver ) {
  
  # Initialize variables

  private := [=];
  private.agent := ref agent;
  private.id := id;
  private.constructor := constructor;
  private.file := file;
  private.mode := mode;
  private.host := host;
  private.forcenewserver := forcenewserver;
  
  public := [=];
  
  gui := F;
  
  w := whenever_manager();
  
  __hds_gui_private( private, public );

  
  # Define the 'done' public member function 
  
  const public.done := function( ) {
    wider gui, private, public, w;
    ok := defaultservers.done( private.agent, private.id.objectid );
    if ( ok ) {
      w.done();
      val gui := F;
      val private := F;
      val public := F;
    }
    return( ok );
  }
  
  
  # Define the 'gui' public member function
  
  const public.gui := function( ) {
    wider gui, private, public, w;
    return( __hds_gui( gui, w, private, public ) );
  }


  # Define the 'alter' private and public member functions

  const public.alter := function( lastdim ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.alter' );
    if ( !cis( lastdim ) ) {
      return( throw( 'Invalid HDS locator last dimension ...',
          origin = member ) );
    }
    ret := private.alter( lastdim );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.alterRec := [_method = 'alter', _sequence = private.id._sequence];

  const private.alter := function( lastdim ) {
    wider private;
    private.alterRec.lastdim := lastdim;
    return( defaultservers.run( private.agent, private.alterRec ) );
  }


  # Define the 'annul' private and public member functions

  const public.annul := function( locatorannul = 1 ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.annul' );
    if ( !cis( locatorannul ) ) {
      return( throw( 'Invalid number of HDS locators to annul ...',
          origin = member ) );
    }
    ret := private.annul( locatorannul );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.annulRec := [_method = 'annul', _sequence = private.id._sequence];

  const private.annul := function( locatorannul ) {
    wider private;
    private.annulRec.locatorannul := locatorannul;
    return( defaultservers.run( private.agent, private.annulRec ) );
  }


  # Define the 'cell' private and public member functions

  const public.cell := function( dims ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.cell' );
    if ( !civ( dims ) ) {
      return( throw( 'Invalid HDS locator cell ...', origin = member ) );
    }
    ret := private.cell( dims );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.cellRec := [_method = 'cell', _sequence = private.id._sequence];

  const private.cell := function( dims ) {
    wider private;
    private.cellRec.dims := dims;
    return( defaultservers.run( private.agent, private.cellRec ) );
  }


  # Define the 'clen' private and public member functions

  const public.clen := function( ) {
    wider private;
    return( private.clen() );
  }

  private.clenRec := [_method = 'clen', _sequence = private.id._sequence];

  const private.clen := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.clenRec ) );
  }


  # Define the 'constructor' public member function

  const public.constructor := function( ) {
    wider private;
    return( private.constructor );
  }


  # Define the 'copy' private and public member functions

  const public.copy := function( name, other = '' ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.copy' );
    if ( !cs( name, private.sizename(), T ) ) {
      return( throw( 'Invalid HDS locator name ...', origin = member ) );
    }
    if ( is_record( other ) ) {
      if ( is_fail( otherid := other.id() ) ) {
        return( throw( 'Invalid HDS glish tool ...', origin = member ) );
      }
    } else {
      otherid := public.id();
    }
    ret := private.copy( name, otherid );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.copyRec := [_method = 'copy', _sequence = private.id._sequence];

  const private.copy := function( name, otherid ) {
    wider private;
    private.copyRec.name := name;
    private.copyRec.otherid := otherid;
    return( defaultservers.run( private.agent, private.copyRec ) );
  }


  # Define the 'copy2file' private and public member functions

  const public.copy2file := function( file, name ) {
    wider private;
    member := spaste( private.constructor, '.copy2file' );
    if ( !cs( file ) ) {
      return( throw( 'Invalid HDS file name ...', origin = member ) );
    }
    if ( !cs( name, private.sizename(), T ) ) {
      return( throw( 'Invalid HDS locator name ...', origin = member ) );
    }
    return( private.copy2file( file, name ) );
  }

  private.copy2fileRec :=
      [_method = 'copy2file', _sequence = private.id._sequence];

  const private.copy2file := function( file, name ) {
    wider private;
    private.copy2fileRec.file := file;
    private.copy2fileRec.name := name;
    return( defaultservers.run( private.agent, private.copy2fileRec ) );
  }


  # Define the 'create' private and public member functions

  const public.create := function( name, type, data, replace = F ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.create' );
    if ( !cs( name, private.sizename(), T ) ) {
      return( throw( 'Invalid HDS locator name ...', origin = member ) );
    }
    if ( !cs( type, private.sizetype(), T ) ) {
      return( throw( 'Invalid HDS locator type ...', origin = member ) );
    }
    if ( !is_boolean( replace ) ) {
      return( throw( 'Invalid HDS locator replace boolean ...',
          origin = member ) );
    }
    ret := private.create( name, type, data, replace );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  const private.create := function( name, type, data, replace ) {
    wider private;
    member := spaste( private.constructor, '.create' );
    if ( type == '_BYTE' ) {
      private.createRec := [_method = 'create_byte',
          _sequence = private.id._sequence];
    } else if ( type == '_DOUBLE' ) {
      private.createRec := [_method = 'create_double',
          _sequence = private.id._sequence];
    } else if ( type == '_INTEGER' ) {
      private.createRec := [_method = 'create_integer',
          _sequence = private.id._sequence];
    } else if ( type == '_LOGICAL' ) {
      private.createRec := [_method = 'create_logical',
          _sequence = private.id._sequence];
    } else if ( type == '_REAL' ) {
      private.createRec := [_method = 'create_real',
          _sequence = private.id._sequence];
    } else if ( type == '_UBYTE' ) {
      private.createRec := [_method = 'create_ubyte',
          _sequence = private.id._sequence];
    } else if ( type == '_UWORD' ) {
      private.createRec := [_method = 'create_uword',
          _sequence = private.id._sequence];
    } else if ( type == '_WORD' ) {
      private.createRec := [_method = 'create_word',
          _sequence = private.id._sequence];
    } else if ( type ~ m/^((?i)_CHAR)(\*)[0-9]+$/ ) {
      private.createRec := [_method = 'create_char',
          _sequence = private.id._sequence];
      private.createRec.length := max( strlen( data ) );
      if ( private.createRec.length > ( type ~ s/^((?i)_CHAR)(\*)// ) ) {
        return( throw( 'Invalid HDS locator element(s) too long ...',
            origin = member ) );
      }
    } else {
      return( throw( 'Invalid HDS locator primitive type ...',
          origin = member ) );
    }
    private.createRec.name := name;
    private.createRec.data := data;
    private.createRec.replace := replace;
    return( defaultservers.run( private.agent, private.createRec ) );
  }


  # Define the 'erase' private and public member functions

  const public.erase := function( name ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.erase' );
    if ( !cs( name, private.sizename(), T ) ) {
      return( throw( 'Invalid HDS locator name ...', origin = member ) );
    }
    ret := private.erase( name );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.eraseRec := [_method = 'erase', _sequence = private.id._sequence];

  const private.erase := function( name ) {
    wider private;
    private.eraseRec.name := name;
    return( defaultservers.run( private.agent, private.eraseRec ) );
  }


  # Define the 'file' public member function

  const public.file := function( ) {
    wider private;
    return( private.file );
  }


  # Define the 'filetail' public member function

  const val public.filetail := function( ) {
    tree := split( public.file(), '/' );
    numbranch := length( tree );
    if ( numbranch < 1 ) {
      return( '' );
    }
    return( tree[numbranch] );
  }


  # Define the 'find' private and public member functions

  const public.find := function( name ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.find' );
    if ( !cs( name, private.sizename(), T ) ) {
      return( throw( 'Invalid HDS locator name ...', origin = member ) );
    }
    ret := private.find( name );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.findRec := [_method = 'find', _sequence = private.id._sequence];

  const private.find := function( name ) {
    wider private;
    private.findRec.name := name;
    return( defaultservers.run( private.agent, private.findRec ) );
  }


  # Define the 'forcenewserver' public member function

  const public.forcenewserver := function( ) {
    wider private;
    return( private.forcenewserver );
  }


  # Define the 'get' private and public member functions

  const public.get := function( ) {
    return( private.get() );
  }

  const private.get := function( ) {
    wider private;
    member := spaste( private.constructor, '.get' );
    type := public.type();
    if ( type == '_BYTE' ) {
      private.getRec := [_method = 'get_byte',
          _sequence = private.id._sequence];
    } else if ( type == '_DOUBLE' ) {
      private.getRec := [_method = 'get_double',
          _sequence = private.id._sequence];
    } else if ( type == '_INTEGER' ) {
      private.getRec := [_method = 'get_integer',
          _sequence = private.id._sequence];
    } else if ( type == '_LOGICAL' ) {
      private.getRec := [_method = 'get_logical',
          _sequence = private.id._sequence];
    } else if ( type == '_REAL' ) {
      private.getRec := [_method = 'get_real',
          _sequence = private.id._sequence];
    } else if ( type == '_UBYTE' ) {
      private.getRec := [_method = 'get_ubyte',
          _sequence = private.id._sequence];
    } else if ( type == '_UWORD' ) {
      private.getRec := [_method = 'get_uword',
          _sequence = private.id._sequence];
    } else if ( type == '_WORD' ) {
      private.getRec := [_method = 'get_word',
          _sequence = private.id._sequence];
    } else if ( type ~ m/^((?i)_CHAR)(\*)[0-9]+$/ ) {
      private.getRec := [_method = 'get_char',
          _sequence = private.id._sequence];
    } else {
      return( throw( 'Invalid HDS locator primitive type ...',
          origin = member ) );
    }
    return( defaultservers.run( private.agent, private.getRec ) );
  }


  # Define the 'goto' private and public member functions

  const public.goto := function( path ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.goto' );
    if ( !cs( path ) ) {
      return( throw( 'Invalid HDS path name ...', origin = member ) );
    }
    ret := private.goto( path );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.gotoRec := [_method = 'Goto', _sequence = private.id._sequence];

  const private.goto := function( path ) {
    wider private;
    private.gotoRec.path := path;
    return( defaultservers.run( private.agent, private.gotoRec ) );
  }


  # Define the 'host' public member function

  const public.host := function( ) {
    wider private;
    return( private.host );
  }


  # Define the 'id' private and public member functions

  const public.id := function( ) {
    wider private;
    return( private.ID() );
  }

  private.IDRec := [_method = 'id', _sequence = private.id._sequence];

  const private.ID := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.IDRec ) );
  }


  # Define the 'index' private and public member functions

  const public.index := function( index ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.index' );
    if ( !cis( index ) ) {
      return( throw( 'Invalid HDS locator index ...', origin = member ) );
    }
    ret := private.index( index );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.indexRec := [_method = 'index', _sequence = private.id._sequence];

  const private.index := function( index ) {
    wider private;
    private.indexRec.index := index;
    return( defaultservers.run( private.agent, private.indexRec ) );
  }


  # Define the 'len' private and public member functions

  const public.len := function( ) {
    wider private;
    return( private.len() );
  }

  private.lenRec := [_method = 'len', _sequence = private.id._sequence];

  const private.len := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.lenRec ) );
  }


  # Define the 'list' private and public member functions

  const public.list := function( ) {
    wider private;
    return( private.list() );
  }

  private.listRec := [_method = 'list', _sequence = private.id._sequence];

  const private.list := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.listRec ) );
  }


  # Define the 'locator' private and public member functions

  const public.locator := function( ) {
    wider private;
    return( private.locator() );
  }

  private.locatorRec := [_method = 'locator', _sequence = private.id._sequence];

  const private.locator := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.locatorRec ) );
  }


  # Define the 'mode' private and public member functions

  const public.mode := function( ) {
    wider private;
    return( private.mode() );
  }

  private.modeRec := [_method = 'mode', _sequence = private.id._sequence];

  const private.mode := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.modeRec ) );
  }


  # Define the 'move' private and public member functions

  const public.move := function( name, other = '' ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.move' );
    if ( !cs( name, private.sizename(), T ) ) {
      return( throw( 'Invalid HDS locator name ...', origin = member ) );
    }
    if ( is_record( other ) ) {
      if ( is_fail( otherid := other.id() ) ) {
        return( throw( 'Invalid HDS glish tool ...', origin = member ) );
      }
    } else {
      otherid := public.id();
    }
    ret := private.move( name, otherid );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.moveRec := [_method = 'move', _sequence = private.id._sequence];

  const private.move := function( name, otherid ) {
    wider private;
    private.moveRec.name := name;
    private.moveRec.otherid := otherid;
    return( defaultservers.run( private.agent, private.moveRec ) );
  }


  # Define the 'name' private and public member functions

  const public.name := function( ) {
    wider private;
    return( private.name() );
  }

  private.nameRec := [_method = 'name', _sequence = private.id._sequence];

  const private.name := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.nameRec ) );
  }


  # Define the 'ncomp' private and public member functions

  const public.ncomp := function( ) {
    wider private;
    return( private.ncomp() );
  }

  private.ncompRec := [_method = 'ncomp', _sequence = private.id._sequence];

  const private.ncomp := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.ncompRec ) );
  }


  # Define the 'new' private and public member functions

  const public.new := function( name, type, dims, replace = F ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.new' );
    if ( !cs( name, private.sizename(), T ) ) {
      return( throw( 'Invalid HDS locator name ...', origin = member ) );
    }
    if ( !cs( type, private.sizetype(), T ) ) {
      return( throw( 'Invalid HDS locator type ...', origin = member ) );
    }
    if ( !civ( dims ) ) {
      return( throw( 'Invalid HDS locator cell ...', origin = member ) );
    }
    if ( !is_boolean( replace ) ) {
      return( throw( 'Invalid HDS locator replace boolean ...',
          origin = member ) );
    }
    ret := private.new( name, type, dims, replace );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.newRec := [_method = 'New', _sequence = private.id._sequence];

  const private.new := function( name, type, dims, replace ) {
    wider private;
    private.newRec.name := name;
    private.newRec.type := type;
    private.newRec.dims := dims;
    private.newRec.replace := replace;
    return( defaultservers.run( private.agent, private.newRec ) );
  }


  # Define the 'numdim' private and public member functions

  const public.numdim := function( ) {
    wider private;
    return( private.numdim() );
  }

  private.numDimRec := [_method = 'numDim', _sequence = private.id._sequence];

  const private.numdim := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.numDimRec ) );
  }


  # Define the 'obtain' private and public member functions

  const public.obtain := function( name ) {
    wider private;
    member := spaste( private.constructor, '.obtain' );
    if ( !cs( name, private.sizename(), T ) ) {
      return( throw( 'Invalid HDS locator name ...', origin = member ) );
    }
    return( private.obtain( name ) );
  }

  const private.obtain := function( name ) {
    wider private;
    member := spaste( private.constructor, '.obtain' );
    public.find( name );
    type := public.type();
    public.annul();
    if ( type == '_BYTE' ) {
      private.obtainRec := [_method = 'obtain_byte',
          _sequence = private.id._sequence];
    } else if ( type == '_DOUBLE' ) {
      private.obtainRec := [_method = 'obtain_double',
          _sequence = private.id._sequence];
    } else if ( type == '_INTEGER' ) {
      private.obtainRec := [_method = 'obtain_integer',
          _sequence = private.id._sequence];
    } else if ( type == '_LOGICAL' ) {
      private.obtainRec := [_method = 'obtain_logical',
          _sequence = private.id._sequence];
    } else if ( type == '_REAL' ) {
      private.obtainRec := [_method = 'obtain_real',
          _sequence = private.id._sequence];
    } else if ( type == '_UBYTE' ) {
      private.obtainRec := [_method = 'obtain_ubyte',
          _sequence = private.id._sequence];
    } else if ( type == '_UWORD' ) {
      private.obtainRec := [_method = 'obtain_uword',
          _sequence = private.id._sequence];
    } else if ( type == '_WORD' ) {
      private.obtainRec := [_method = 'obtain_word',
          _sequence = private.id._sequence];
    } else if ( type ~ m/^((?i)_CHAR)(\*)[0-9]+$/ ) {
      private.obtainRec := [_method = 'obtain_char',
          _sequence = private.id._sequence];
    } else {
      return( throw( 'Invalid HDS locator primitive type ...',
          origin = member ) );
    }
    private.obtainRec.name := name;
    return( defaultservers.run( private.agent, private.obtainRec ) );
  }


  # Define the 'path' private and public member functions

  const public.path := function( ) {
    wider private;
    return( private.path() );
  }

  private.pathRec := [_method = 'path', _sequence = private.id._sequence];

  const private.path := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.pathRec ) );
  }


  # Define the 'prec' private and public member functions

  const public.prec := function( ) {
    wider private;
    return( private.prec() );
  }

  private.precRec := [_method = 'prec', _sequence = private.id._sequence];

  const private.prec := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.precRec ) );
  }


  # Define the 'prim' private and public member functions

  const public.prim := function( ) {
    wider private;
    return( private.prim() );
  }

  private.primRec := [_method = 'prim', _sequence = private.id._sequence];

  const private.prim := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.primRec ) );
  }


  # Define the 'put' private and public member functions

  const public.put := function( data ) {
    wider gui, private, public;
    ret := private.put( data );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  const private.put := function( data ) {
    wider private;
    member := spaste( private.constructor, '.put' );
    type := public.type();
    if ( type == '_BYTE' ) {
      private.putRec := [_method = 'put_byte',
          _sequence = private.id._sequence];
    } else if ( type == '_DOUBLE' ) {
      private.putRec := [_method = 'put_double',
          _sequence = private.id._sequence];
    } else if ( type == '_INTEGER' ) {
      private.putRec := [_method = 'put_integer',
          _sequence = private.id._sequence];
    } else if ( type == '_LOGICAL' ) {
      private.putRec := [_method = 'put_logical',
          _sequence = private.id._sequence];
    } else if ( type == '_REAL' ) {
      private.putRec := [_method = 'put_real',
          _sequence = private.id._sequence];
    } else if ( type == '_UBYTE' ) {
      private.putRec := [_method = 'put_ubyte',
          _sequence = private.id._sequence];
    } else if ( type == '_UWORD' ) {
      private.putRec := [_method = 'put_uword',
          _sequence = private.id._sequence];
    } else if ( type == '_WORD' ) {
      private.putRec := [_method = 'put_word',
          _sequence = private.id._sequence];
    } else if ( type ~ m/^((?i)_CHAR)(\*)[0-9]+$/ ) {
      private.putRec := [_method = 'put_char',
          _sequence = private.id._sequence];
      if ( max( strlen( data ) ) > ( type ~ s/^((?i)_CHAR)(\*)// ) ) {
        return( throw( 'Invalid HDS locator element(s) too long ...',
            origin = member ) );
      }
    } else {
      return( throw( 'Invalid HDS locator primitive type ...',
          origin = member ) );
    }
    private.putRec.data := data;
    return( defaultservers.run( private.agent, private.putRec ) );
  }


  # Define the 'recover' private and public member functions

  const public.recover := function( ) {
    wider gui, private, public;
    ret := private.recover();
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.recoverRec := [_method = 'recover', _sequence = private.id._sequence];

  const private.recover := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.recoverRec ) );
  }


  # Define the 'renam' private and public member functions

  const public.renam := function( name ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.renam' );
    if ( !cs( name, private.sizename(), T ) ) {
      return( throw( 'Invalid HDS locator name ...', origin = member ) );
    }
    ret := private.renam( name );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.renamRec := [_method = 'renam', _sequence = private.id._sequence];

  const private.renam := function( name ) {
    wider private;
    private.renamRec.name := name;
    return( defaultservers.run( private.agent, private.renamRec ) );
  }


  # Define the 'reset' private and public member functions

  const public.reset := function( ) {
    wider gui, private, public;
    ret := private.reset();
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.resetRec := [_method = 'reset', _sequence = private.id._sequence];

  const private.reset := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.resetRec ) );
  }


  # Define the 'retyp' private and public member functions

  const public.retyp := function( type ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.retyp' );
    if ( !cs( type, private.sizetype(), T ) ) {
      return( throw( 'Invalid HDS locator type ...', origin = member ) );
    }
    ret := private.retyp( type );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.retypRec := [_method = 'retyp', _sequence = private.id._sequence];

  const private.retyp := function( type ) {
    wider private;
    private.retypRec.type := type;
    return( defaultservers.run( private.agent, private.retypRec ) );
  }


  # Define the 'save' private and public member functions

  const public.save := function( ) {
    wider private;
    return( private.save() );
  }

  private.saveRec := [_method = 'save', _sequence = private.id._sequence];

  const private.save := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.saveRec ) );
  }


  # Define the 'screate' private and public member functions

  const public.screate := function( name, type, datum, replace = F ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.screate' );
    if ( !cs( name, private.sizename(), T ) ) {
      return( throw( 'Invalid HDS locator name ...', origin = member ) );
    }
    if ( !cs( type, private.sizetype(), T ) ) {
      return( throw( 'Invalid HDS locator type ...', origin = member ) );
    }
    if ( !is_boolean( replace ) ) {
      return( throw( 'Invalid HDS locator replace boolean ...',
          origin = member ) );
    }
    ret := private.screate( name, type, datum, replace );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  const private.screate := function( name, type, datum, replace ) {
    wider private;
    member := spaste( private.constructor, '.screate' );
    if ( type == '_BYTE' ) {
      private.screateRec := [_method = 'screate_byte',
          _sequence = private.id._sequence];
    } else if ( type == '_DOUBLE' ) {
      private.screateRec := [_method = 'screate_double',
          _sequence = private.id._sequence];
    } else if ( type == '_INTEGER' ) {
      private.screateRec := [_method = 'screate_integer',
          _sequence = private.id._sequence];
    } else if ( type == '_LOGICAL' ) {
      private.screateRec := [_method = 'screate_logical',
          _sequence = private.id._sequence];
    } else if ( type == '_REAL' ) {
      private.screateRec := [_method = 'screate_real',
          _sequence = private.id._sequence];
    } else if ( type == '_UBYTE' ) {
      private.screateRec := [_method = 'screate_ubyte',
          _sequence = private.id._sequence];
    } else if ( type == '_UWORD' ) {
      private.screateRec := [_method = 'screate_uword',
          _sequence = private.id._sequence];
    } else if ( type == '_WORD' ) {
      private.screateRec := [_method = 'screate_word',
          _sequence = private.id._sequence];
    } else if ( type ~ m/^((?i)_CHAR)(\*)[0-9]+$/ ) {
      private.screateRec := [_method = 'screate_char',
          _sequence = private.id._sequence];
      private.screateRec.length := max( strlen( datum ) );
      if ( private.screateRec.length > ( type ~ s/^((?i)_CHAR)(\*)// ) ) {
        return( throw( 'Invalid HDS locator element(s) too long ...',
            origin = member ) );
      }
    } else {
      return( throw( 'Invalid HDS locator primitive type ...',
          origin = member ) );
    }
    private.screateRec.name := name;
    private.screateRec.datum := datum;
    private.screateRec.replace := replace;
    return( defaultservers.run( private.agent, private.screateRec ) );
  }


  # Define the 'shape' private and public member functions

  const public.shape := function( ) {
    wider private;
    return( private.shape() );
  }

  private.shapeRec := [_method = 'shape', _sequence = private.id._sequence];

  const private.shape := function( ) {
    wider private;
    shape := defaultservers.run( private.agent, private.shapeRec );
    return( shape );
  }


  # Define the 'size' private and public member functions

  const public.size := function( ) {
    wider private;
    return( private.size() );
  }

  private.sizeRec := [_method = 'size', _sequence = private.id._sequence];

  const private.size := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.sizeRec ) );
  }


  # Define the 'slice' private and public member functions

  const public.slice := function( dims1, dims2 ) {
    wider gui, private, public;
    member := spaste( private.constructor, '.slice' );
    if ( !civ( dims1 ) ) {
      return( throw( 'Invalid lower HDS locator dimensions ...',
          origin = member ) );
    }
    if ( !civ( dims2 ) ) {
      return( throw( 'Invalid upper HDS locator dimensions ...',
          origin = member ) );
    }
    if ( length( dims1 ) != length( dims2 ) ) {
      return( throw( 'HDS locator dimensions unequal...', origin = member ) );
    }
    if ( any( dims1 > dims2 ) ) {
      return( throw( 'HDS locator dimensions, lower greater than upper...',
          origin = member ) );
    }
    ret := private.slice( dims1, dims2 );
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.sliceRec := [_method = 'slice', _sequence = private.id._sequence];

  const private.slice := function( dims1, dims2 ) {
    wider private;
    private.sliceRec.dims1 := dims1;
    private.sliceRec.dims2 := dims2;
    return( defaultservers.run( private.agent, private.sliceRec ) );
  }


  # Define the 'state' private and public member functions

  const public.state := function( ) {
    wider private;
    return( private.state() );
  }

  private.stateRec := [_method = 'state', _sequence = private.id._sequence];

  const private.state := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.stateRec ) );
  }


  # Define the 'struc' private and public member functions

  const public.struc := function( ) {
    wider private;
    return( private.struc() );
  }

  private.strucRec := [_method = 'struc', _sequence = private.id._sequence];

  const private.struc := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.strucRec ) );
  }


  # Define the 'there' private and public member functions

  const public.there := function( name ) {
    wider private;
    member := spaste( private.constructor, '.there' );
    if ( !cs( name, private.sizename(), T ) ) {
      return( throw( 'Invalid HDS locator name...', origin = member ) );
    }
    return( private.there( name ) );
  }

  private.thereRec := [_method = 'there', _sequence = private.id._sequence];

  const private.there := function( name ) {
    wider private;
    private.thereRec.name := name;
    return( defaultservers.run( private.agent, private.thereRec ) );
  }


  # Define the 'top' private and public member functions

  const public.top := function( ) {
    wider gui, private, public;
    ret := private.top();
    __hds_gui_update( gui, private, public );
    return( ret );
  }

  private.topRec := [_method = 'top', _sequence = private.id._sequence];

  const private.top := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.topRec ) );
  }


  # Define the 'type' private and public member functions

  const public.type := function( ) {
    wider private;
    return( private.type() );
  }

  private.typeRec := [_method = 'type', _sequence = private.id._sequence];

  const private.type := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.typeRec ) );
  }


  # Define the 'valid' private and public member functions

  const public.valid := function( ) {
    wider private;
    return( private.valid() );
  }

  private.validRec := [_method = 'valid', _sequence = private.id._sequence];

  const private.valid := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.validRec ) );
  }


  # Define the 'version' private and public member functions

  const public.version := function( ) {
    wider private;
    return( private.version() );
  }

  private.versionRec := [_method = 'version', _sequence = private.id._sequence];

  const private.version := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.versionRec ) );
  }


  # Define the 'web' public member function

  const public.web := function( ) {
    return( web() );
  }
  
  
  # Define the 'dimmax' private and public member functions

  const public.dimmax := function( ) {
    wider private;
    return( private.dimmax() );
  }

  private.dimMaxRec := [_method = 'dimMax', _sequence = private.id._sequence];

  const private.dimmax := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.dimMaxRec ) );
  }
  
  
  # Define the 'locatormax' private and public member functions

  const public.locatormax := function( ) {
    wider private;
    return( private.locatormax() );
  }

  private.locatorMaxRec :=
      [_method = 'locatorMax', _sequence = private.id._sequence];

  const private.locatormax := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.locatorMaxRec ) );
  }
  
  
  # Define the 'nolocator' private and public member functions

  const public.nolocator := function( ) {
    wider private;
    return( private.nolocator() );
  }

  private.noLocatorRec :=
      [_method = 'noLocator', _sequence = private.id._sequence];

  const private.nolocator := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.noLocatorRec ) );
  }
  
  
  # Define the 'sizelocator' private and public member functions

  const public.sizelocator := function( ) {
    wider private;
    return( private.sizelocator() );
  }

  private.sizeLocatorRec :=
      [_method = 'sizeLocator', _sequence = private.id._sequence];

  const private.sizelocator := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.sizeLocatorRec ) );
  }
  
  
  # Define the 'sizemode' private and public member functions

  const public.sizemode := function( ) {
    wider private;
    return( private.sizemode() );
  }

  private.sizeModeRec :=
      [_method = 'sizeMode', _sequence = private.id._sequence];

  const private.sizemode := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.sizeModeRec ) );
  }
  
  
  # Define the 'sizename' private and public member functions

  const public.sizename := function( ) {
    wider private;
    return( private.sizename() );
  }

  private.sizeNameRec :=
      [_method = 'sizeName', _sequence = private.id._sequence];

  const private.sizename := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.sizeNameRec ) );
  }
  
  
  # Define the 'sizetype' private and public member functions

  const public.sizetype := function( ) {
    wider private;
    return( private.sizetype() );
  }

  private.sizeTypeRec :=
      [_method = 'sizeType', _sequence = private.id._sequence];

  const private.sizetype := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.sizeTypeRec ) );
  }
  
  
  # Return the public variable
  
  return( ref public );
  
}

# ------------------------------------------------------------------------------

# hdsnew

# Description:
# ------------
# This glish function defines the hdsnew( ) tool for creating new HDS files.

# Inputs:
# -------
# file           - The HDS file name.
# name           - The HDS top-locator object name.
# type           - The HDS top-locator object type (default = '').
# dims           - The HDS top-locator object dimensions (default = 0, a
#                  scalar; there may be up to seven dimensions).
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The member functions, returned via the glish function value.

# Modification history:
# ---------------------
# 1999 Sep 15 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const hdsnew := function( file, name, type = '', dims = 0, host = '',
    forcenewserver = F ) {
  
  # Fix and check the inputs #
  
  constructor := 'hdsnew';
  
  if ( !cs( file ) ) {
    return( throw( 'Invalid HDS file name ...', origin = constructor ) );
  }
  
  if ( !cs( name ) ) {
    return( throw( 'Invalid HDS top-locator name ...', origin = constructor ) );
  }
  
  if ( !civ( dims ) ) {
    return( throw( 'Invalid HDS top-locator dimensions ...',
        origin = constructor ) );
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host name ...', origin = constructor ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid \'force-new-server\' boolean ...',
        origin = constructor ) );
  }


  # Invoke the HDSFile{ } constructor member function
  
  agent := defaultservers.activate( 'HDS', host, forcenewserver );
  
  if ( is_fail( id := defaultservers.create( agent, 'HDSFile',
      to_upper(constructor),
      [file = file, mode = 'NEW', name = name, type = type, dims = dims] ) ) ) {
    val public := F;
    return( throw( 'Error creating server ...', origin = constructor ) );
  }
  
  
  # Return the structure containing the public member functions
  
  public := _define_hdsmembers( agent, id, constructor, file, 'NEW', host,
      forcenewserver );
  
  return( ref public );
  
}

# ------------------------------------------------------------------------------

# hdsopen

# Description:
# ------------
# This glish function defines the hdsopen( ) tool for reading or updating HDS
# files.

# Inputs:
# -------
# file           - The HDS file name.
# readonly       - The read-only boolean (default = T).
# host           - The host name (default = '').
# forcenewserver - The 'force-new-server' boolean (default = F).

# Outputs:
# --------
# The member functions, returned via the glish function value.

# Modification history:
# ---------------------
# 1999 Sep 15 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const hdsopen := function( file, readonly = T, host = '', forcenewserver = F ) {
  
  # Fix and check the inputs #
  
  constructor := 'hdsopen';

  if ( !cs( file ) ) {
    return( throw( 'Invalid HDS file name ...', origin = constructor ) );
  }
  
  if ( !is_boolean( readonly ) ) {
    return( throw( 'Invalid read-only boolean ...', origin = constructor ) );
  }
  
  if ( readonly ) {
    mode := 'READ';
  } else {
    mode := 'UPDATE';
  }
  
  if ( !cs( host ) ) {
    return( throw( 'Invalid host name ...', origin = constructor ) );
  }
  
  if ( !is_boolean( forcenewserver ) ) {
    return( throw( 'Invalid \'force-new-server\' boolean ...',
        origin = constructor ) );
  }


  # Invoke the HDSFile{ } constructor member function
  
  agent := defaultservers.activate( 'HDS', host, forcenewserver );
  
  if ( is_fail( id := defaultservers.create( agent, 'HDSFile',
      to_upper(constructor), [file = file, mode = mode] ) ) ) {
    val public := F;
    return( throw( 'Error creating server ...', origin = constructor ) );
  }
  
  
  # Return the structure containing member functions

  public := _define_hdsmembers( agent, id, constructor, file, mode, host,
      forcenewserver );
  
  return( ref public );
  
}
