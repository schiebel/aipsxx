# __gdc1token_private.g is part of the GDC server
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
# $Id: __gdc1token_private.g,v 19.0 2003/07/16 06:03:27 aips2adm Exp $
# ------------------------------------------------------------------------------

# __gdc1token_private.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions that define private member functions
# for gdc1token tools.  NB: These functions should be called only by gdc1token
# tools.

# glish function:
# ---------------
# __gdc1token_private.

# Modification history:
# ---------------------
# 2000 Jun 13 - Nicholas Elias, USNO/NPOI
#               File created with glish function __gdc1token_private( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __gdc1token_private

# Description:
# ------------
# This glish function creates private member functions for a gdc1token tool.

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

const __gdc1token_private := function( ref gui, ref private, ref public ) { 
  
  # Define the 'checkgdc1token' private member function
  
  const val private.checkgdc1token := function( tool ) {
    if ( !is_function( tool ) ) {
      return( F );
    }
    if ( !has_field( tool, 'tool' ) ) {
      return( F );
    }
    if ( tool.tool() != 'gdc1token' ) {
      return( F );
    }
    return( T );
  }
  
  
  # Define the 'checkx' private member function

  val private.checkXRec :=
      [_method = 'checkX', _sequence = private.id._sequence];
   
  const val private.checkx := function( ref xmin, ref xmax ) {
    wider private;
    if ( !private.getargcheck() ) {
      return( T );
    }
    if ( is_numeric( xmin ) ) {
      xnum := length( xmin );
      if ( xnum == 1 ) {
        xminTemp := xmin;
      } else if ( xnum == 0 ) {
        xminTemp := private.getxmin( T );
      } else {
        return( F );
      }
    } else {
      return( F );
    }
    if ( is_numeric( xmax ) ) {
      xnum := length( xmax );
      if ( xnum == 1 ) {
        xmaxTemp := xmax;
      } else if ( xnum == 0 ) {
        xmaxTemp := private.getxmax( T );
      } else {
        return( F );
      }
    } else {
      return( F );
    }
    val private.checkXRec.xmin := xminTemp;
    val private.checkXRec.xmax := xmaxTemp;
    XList := defaultservers.run( private.agent, private.checkXRec );
    check := as_boolean( XList[1] );
    if ( check ) {
      val xmin := XList[2];
      val xmax := XList[3];
    }
    return( check );
  }
  
  
  # Define the 'checkxvec' private member function
 
  const val private.checkxvec := function( ref x, ref xmin, ref xmax ) {
    wider private;
    if ( !private.getargcheck() ) {
      return( T );
    }
    if ( !is_real( x ) ) {
      return( F );
    }
    if ( !private.checkx( xmin, xmax ) ) {
      return( F );
    }
    for ( i in 1:length(x) ) {
      if ( x[i] < xmin || x[i] > xmax ) {
        return( F );
      }
    }
    val x := sort( x );
    return( T );
  }
  
  
  # Define the 'checky' private member function

  val private.checkYRec :=
      [_method = 'checkY', _sequence = private.id._sequence];
   
  const val private.checky := function( ref ymin, ref ymax ) {
    wider private;
    if ( !private.getargcheck() ) {
      return( T );
    }
    if ( is_numeric( ymin ) ) {
      ynum := length( ymin );
      if ( ynum == 1 ) {
        yminTemp := ymin;
      } else if ( ynum == 0 ) {
        yminTemp := private.getymin( T );
      } else {
        return( F );
      }
    } else {
      return( F );
    }
    if ( is_numeric( ymax ) ) {
      ynum := length( ymax );
      if ( ynum == 1 ) {
        ymaxTemp := ymax;
      } else if ( ynum == 0 ) {
        ymaxTemp := private.getymax( T );
      } else {
        return( F );
      }
    } else {
      return( F );
    }
    val private.checkYRec.ymin := yminTemp;
    val private.checkYRec.ymax := ymaxTemp;
    val private.checkYRec.tokenarg := private.tokenlist();
    YList := defaultservers.run( private.agent, private.checkYRec );
    check := as_boolean( YList[1] );
    if ( check ) {
      val ymin := YList[2];
      val ymax := YList[3];
    }
    return( check );
  }
  
  
  # Define the 'checktoken' private member function

  val private.checkTokenRec :=
      [_method = 'checkToken', _sequence = private.id._sequence];
  
  const val private.checktoken := function( ref token ) {
    wider private;
    if ( !private.getargcheck() ) {
      return( T );
    }
    val private.checkTokenRec.tokenarg := split( token );
    tokenList := defaultservers.run( private.agent, private.checkTokenRec );
    check := as_boolean( tokenList[1] );
    if ( check ) {
      val token := tokenList[2:length(tokenList)];
    }
    return( check );
  }
  
  
  # Define the 'checkinterp' private member function

  val private.checkInterpRec :=
      [_method = 'checkInterp', _sequence = private.id._sequence];
    
  const val private.checkinterp := function( ref interp ) {
    wider private;
    if ( !private.getargcheck() ) {
      return( T );
    }
    interpTemp := interp;
    if ( !cs( interpTemp, 0, T ) ) {
      return( F );
    }
    val private.checkInterpRec.interp := interpTemp;
    interpList := defaultservers.run( private.agent, private.checkInterpRec );
    check := as_boolean( interpList[1] );
    if ( check ) {
      val interp := interpList[2];
    }
    return( check );
  }


  # Define the 'getargcheck' private member function

  val private.getargcheckRec :=
      [_method = 'getArgCheck', _sequence = private.id._sequence];

  const val private.getargcheck := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.getargcheckRec ) );
  }


  # Define the 'setargcheck' private member function

  val private.setargcheckRec :=
      [_method = 'setArgCheck', _sequence = private.id._sequence];

  const val private.setargcheck := function( check ) {
    wider private;
    val private.setargcheckRec.check := check;
    return( defaultservers.run( private.agent, private.setargcheckRec ) );
  }


  # Define the 'nexttmpfile' private member function
  
  const val private.nexttmpfile := function( ) {
    listtmp := shell( 'ls /tmp' );
    if ( length( listtmp ) == 0 ) {
      return( '/tmp/pgplot000.ps' );
    } else if ( !any( listtmp ~ m/^pgplot[0-9]+\.ps$/ ) ) {
      return( '/tmp/pgplot000.ps' );
    } else {
      listtmp := split( sort( shell( 'ls /tmp/pgplot*.ps' ) ) );
      arg := ( listtmp[length(listtmp)] ~ s/^\/tmp\/pgplot// ) ~ s/\.ps$//;
      number := as_integer( arg ) + 1;
      if ( number > 999 ) {
        number := 0;
      }
      return( spaste( '/tmp/pgplot', sprintf( '%03d', number ), '.ps' ) );
    }
  }
  
  
  # Define the 'pgplot' private member function

  const val private.pgplot := function( ) {
    wider gui, private, public;
    val gui.pgplot := pgplot( gui, height = 450, width = 600 );
    val gui.qid := gui.pgplot->qid();
    val private.colortable := ci2x( gui.pgplot );
    private.plot();
    return( T );
  }
  
  const val private.plot := function( ) {
    wider gui, private, public;
    if ( !is_agent( gui.pgplot ) ) {
      return( F );
    }
    token := private.gettoken();
    if ( length( token ) < 1 ) {
      gui.pgplot->page();
      return;
    }
    xminAll := private.getxmin( T );
    xmaxAll := private.getxmax( T );
    tokenAll := public.tokenlist();
    color := private.getcolor();
    line := private.getline();
    keep := private.getkeep();
    xerror := public.xerror();
    yerror := public.yerror();
    xmin := public.xmin( private.getxmin(), private.getxmax(), token, keep,
        xerror );
    xmax := public.xmax( private.getxmin(), private.getxmax(), token, keep,
        xerror );
    ymin := public.ymin( private.getxmin(), private.getxmax(), token, keep,
        yerror );
    ymax := public.ymax( private.getxmin(), private.getxmax(), token, keep,
        yerror );
    gui.pgplot->slct( gui.qid );
    gui.pgplot->bbuf();
    gui.pgplot->sci( 1 );
    gui.pgplot->scf( 2 );
    gui.pgplot->sch( 1.25 );
    xdelta := 0.05 * ( xmax - xmin );
    ydelta := 0.05 * ( ymax - ymin );
    if ( !public.hms() ) {
      gui.pgplot->env( xmin-xdelta, xmax+xdelta, ymin-ydelta, ymax+ydelta, 0,
          0 );
    } else {
      gui.pgplot->page();
      gui.pgplot->svp( 0.1, 0.9, 0.1, 0.9 )
      gui.pgplot->swin( xmin-xdelta, xmax+xdelta, ymin-ydelta, ymax+ydelta );
      gui.pgplot->tbox( 'BCNTHZ', 0.0, 0, 'BCNT', 0.0, 0 );
    }
    gui.pgplot->lab( private.getxlabel(), private.getylabel(),
        private.gettitle() );
    private.setargcheck( F );
    if ( color ) {
      numtoken := length( token );
    } else {
      numtoken := 1;
    }
    for ( t in 1:numtoken ) {
      if ( color ) {
        tokenTemp := token[t];
      } else {
        tokenTemp := token;
      }
      index := public.index( xmin, xmax, tokenTemp, keep );
      if ( length( index ) > 0 ) {
        x := public.x( xmin, xmax, tokenTemp, keep );
        y := public.y( xmin, xmax, tokenTemp, keep );
        gui.pgplot->sci( private.colortable.ci[t] );
        gui.pgplot->pt( x, y, 17 );
        if ( xerror ) {
          xerr := public.xerr( xmin, xmax, tokenTemp, keep );
          gui.pgplot->errb( 5, x, y, xerr, 1.0 );
        }
        if ( yerror ) {
          yerr := public.yerr( xmin, xmax, tokenTemp, keep );
          gui.pgplot->errb( 6, x, y, yerr, 1.0 );
        }
        if ( line ) {
          gui.pgplot->line( x, y );
        }
      }
      if ( keep ) {
        flagged := public.flagged( xmin, xmax, tokenTemp );
        if ( length( flagged ) > 0 ) {
          x := public.x( xminAll, xmaxAll, tokenAll, T )[flagged];
          y := public.y( xminAll, xmaxAll, tokenAll, T )[flagged];
          gui.pgplot->sci( 2 );
          gui.pgplot->pt( x, y, 17 );
          if ( xerror ) {
            xerr := public.xerr( xminAll, xmaxAll, tokenAll, T )[flagged];
            gui.pgplot->errb( 5, x, y, xerr, 1.0 );
          }
          if ( yerror ) {
            yerr := public.yerr( xminAll, xmaxAll, tokenAll, T )[flagged];
            gui.pgplot->errb( 6, x, y, yerr, 1.0 );
          }
        }
      }
      interpolated := public.interpolated( xmin, xmax, tokenTemp );
      if ( length( interpolated ) > 0 ) {
        x := public.x( xminAll, xmaxAll, tokenAll, T )[interpolated];
        y := public.y( xminAll, xmaxAll, tokenAll, T )[interpolated];
        gui.pgplot->sci( 3 );
        gui.pgplot->pt( x, y, 17 );
        if ( xerror ) {
          xerr := public.xerr( xminAll, xmaxAll, tokenAll, T )[interpolated];
          gui.pgplot->errb( 5, x, y, xerr, 1.0 );
        }
        if ( yerror ) {
          yerr := public.yerr( xminAll, xmaxAll, tokenAll, T )[interpolated];
          gui.pgplot->errb( 6, x, y, yerr, 1.0 );
        }
      }
    }
    gui.pgplot->ebuf();
    private.setargcheck( T );
    return( T );
  }
  
    
  # Define the 'postscript' private member function

  val private.postscriptRec :=
      [_method = 'postScript', _sequence = private.id._sequence];
  
  const val private.postscript := function( file, device ) {
    wider private;
    val private.postscriptRec.file := file;
    val private.postscriptRec.device := device;
    val private.postscriptRec.trans := private.trans;
    val private.postscriptRec.ci := private.colortable.ci;
    return( defaultservers.run( private.agent, private.postscriptRec ) );
  }
  
  
  # Define the 'preview' private member function
  
  const val private.preview := function( ) {
    wider private;
    nexttmpfile := private.nexttmpfile();
    private.postscript( nexttmpfile, '/cps' );
    shell( spaste( 'ghostview ', nexttmpfile ) );
    return( T );
  }
  
  
  # Define the 'print' private member function
  
  const val private.print := function( ) {
    wider private;
    nexttmpfile := private.nexttmpfile();
    private.postscript( nexttmpfile, '/cps' );
    shell( spaste( 'lpr ', nexttmpfile ) );
    return( T );
  }
  

  # Define the 'save' private member function 
  
  const val private.save := function( file ) {
    wider private;
    private.postscript( as_string( file ), '/cps' );
    return( T );
  }


  # Define the 'buttonbar' private member function
  
  const val private.buttonbar := function( ) {
    wider gui, private;
    if ( has_field( gui, 'topbar1' ) ) {
      return( gui.topbar1 );
    } else {
      return( F );
    }
  }


  # Define the 'filemenu' private member function
  
  const val private.filemenu := function( ) {
    wider gui, private;
    if ( has_field( gui, 'file' ) ) {
      return( gui.file );
    } else {
      return( F );
    }
  }


  # Define the 'dumpmenu' private member function
  
  const val private.dumpmenu := function( ) {
    wider gui, private;
    if ( has_field( gui, 'bdump' ) ) {
      return( gui.bdump );
    } else {
      return( F );
    }
  }


  # Define the 'toolmenu' private member function

  const val private.toolmenu := function( ) {
    wider gui, private;
    if ( has_field( gui, 'tools' ) ) {
      return( gui.tools );
    } else {
      return( F );
    }
  }
  
  
  # Return T
  
  return( T );
  
}
