# __gdc1token_public.g is part of the GDC server
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
# $Id: __gdc1token_public.g,v 19.0 2003/07/16 06:03:28 aips2adm Exp $
# ------------------------------------------------------------------------------

# __gdc1token_public.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++/Cuttlefish

# Description:
# ------------
# This file contains the glish functions that define public (and associated
# private) member functions for gdc1token tools.  NB: These functions should be
# called only by gdc1token tools.

# glish function:
# ---------------
# __gdc1token_public.

# Modification history:
# ---------------------
# 2000 Jun 13 - Nicholas Elias, USNO/NPOI
#               File created with glish function __gdc1token_public( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __gdc1token_public

# Description:
# ------------
# This glish function creates public (and associated private) member functions
# for a gdc1token tool.

# Inputs:
# -------
# gui     - The gui variable.
# w       - The whenever variable.
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

const __gdc1token_public := function( ref gui, ref w, ref private,
    ref public ) { 
  
  # Define the 'tool' public and private member functions

  if ( spaste( split( private.gconstructor, '' )[1:9] ) == 'gdc1token' ) {

    val private.toolRec := [_method = 'tool', _sequence = private.id._sequence];
  
    const val public.tool := function( ) {
      wider private;
      return( defaultservers.run( private.agent, private.toolRec ) );
    }

  }
  
  
  # Define the 'version' public member function

  if ( spaste( split( private.gconstructor, '' )[1:9] ) == 'gdc1token' ) {

    val private.versionRec :=
        [_method = 'version', _sequence = private.id._sequence];
  
    const val public.version := function( ) {
      wider private;
      return( defaultservers.run( private.agent, private.versionRec ) );
    }

  }


  # Define the 'fileascii' public member function

  if ( private.gconstructor == 'gdc1token_ascii' ) {

    val private.fileASCIIRec :=
        [_method = 'fileASCII', _sequence = private.id._sequence];
  
    const val public.fileascii := function( ) {
      wider private;
      return( defaultservers.run( private.agent, private.fileASCIIRec ) );
    }

  }


  # Define the 'filetailascii' public member function

  if ( private.gconstructor == 'gdc1token_ascii' ) {

    const val public.filetailascii := function( ) {
      tree := split( public.fileascii(), '/' );
      numbranch := length( tree );
      if ( numbranch < 1 ) {
        return( '' );
      }
      return( tree[numbranch] );
    }

  }
  
  
  # Define the 'host' public member function
  
  const val public.host := function( ) {
    wider private;
    return( private.host );
  }
  
  
  # Define the 'forcenewserver' public member function
  
  const val public.forcenewserver := function( ) {
    wider private;
    return( private.forcenewserver );
  }
  
  
  # Define the 'id' public and private member functions
  
  const val public.id := function( ) {
    wider private;
    return( private.ID() );
  }

  val private.idRec := [_method = 'id', _sequence = private.id._sequence];
  
  const val private.ID := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.idRec ) );
  }

  
  # Define the 'done' public member function
  
  const val public.done := function( ) {
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
  
  
  # Define the 'maingui' public member function
  
  const val public.maingui := function( window = '' ) {
    wider gui, private, public, w;
    member := spaste( private.gconstructor, '.maingui' );
    if ( !cs( window ) ) {
      return( throw( 'Invalid window name ...', origin = member ) );
    }
    return( __gdc1token_maingui( window, gui, w, private, public ) );
  }
  
  
  # Define the 'web' public member function
  
  const val public.web := function( ) {
    return( web() );
  }
  
  
  # Define the 'dumpascii' public and private member functions
  
  const val public.dumpascii := function( file, xmin = [], xmax = [],
      token = "", keep = F ) {
    member := spaste( private.gconstructor, '.dumpascii' );
    if ( !cs( file ) ) {
      return( throw( 'Invalid file name ...', origin = member ) );
    }
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    return( private.dumpascii( file, xmin, xmax, token, keep ) );
  }

  val private.dumpasciiRec :=
      [_method = 'dumpASCII', _sequence = private.id._sequence];
  
  const val private.dumpascii := function( file, xmin, xmax, token, keep ) {
    wider private;
    val private.dumpasciiRec.file := file;
    val private.dumpasciiRec.xmin := xmin;
    val private.dumpasciiRec.xmax := xmax;
    val private.dumpasciiRec.tokenarg := token;
    val private.dumpasciiRec.keep := keep;
    return( defaultservers.run( private.agent, private.dumpasciiRec ) );
  }


  # Define the 'clone' public member function

  if ( spaste( split( private.gconstructor, '' )[1:9] ) == 'gdc1token' ) {

    const val public.clone := function( xmin = [], xmax = [], token = "",
        keep = F ) {
      wider private, public;
      member := spaste( private.gconstructor, '.clone' );
      if ( !private.checkx( xmin, xmax ) ) {
        return( throw( 'Invalid x argument(s) ...', origin = member ) );
      }
      if ( !private.checktoken( token ) ) {
        return( throw( 'Invalid token(s) ...', origin = member ) );
      }
      if ( !is_boolean( keep ) ) {
        return( throw( 'Invalid \'keep-flags\' boolean ...',
            origin = member ) );
      }
      return( private.clonefunc( public.id(), xmin, xmax, token, keep,
          public.host(), public.forcenewserver() ) );
    }

  }


  # Define the 'average' public member function

  if ( spaste( split( private.gconstructor, '' )[1:9] ) == 'gdc1token' ) {

    const val public.average := function( x, xmin = [], xmax = [], token = "",
        keep = F, weight = F, xcalc = F, interp = 'SPLINE' ) {
      wider private, public;
      member := spaste( private.gconstructor, '.average' );
      if ( !private.checkx( xmin, xmax ) ) {
        return( throw( 'Invalid x argument(s) ...', origin = member ) );
      }
      if ( !private.checkxvec( x, xmin, xmax ) ) {
        return( throw( 'Invalid x vector ...', origin = member ) );
      }
      if ( !private.checktoken( token ) ) {
        return( throw( 'Invalid token(s) ...', origin = member ) );
      }
      if ( !is_boolean( keep ) ) {
        return( throw( 'Invalid \'keep-flags\' boolean ...',
            origin = member ) );
      }
      if ( !is_boolean( weight ) ) {
        return( throw( 'Invalid weight boolean ...', origin = member ) );
      }
      if ( !is_boolean( xcalc ) ) {
        return( throw( 'Invalid recalculate-x boolean ...', origin = member ) );
      }
      if ( !private.checkinterp( interp ) ) {
        return( throw( 'Invalid interpolation method ...', origin = member ) );
      }
      return( private.averagefunc( public.id(), x, xmin, xmax, token, keep,
          weight, xcalc, interp, public.host(), public.forcenewserver() ) );
    }

  }


  # Define the 'uaverage' public member function

  const val public.uaverage := function( xdelta, xmin = [], xmax = [],
      token = "", keep = F, weight = F, xcalc = F, interp = 'SPLINE' ) {
    wider private, public;
    member := spaste( private.gconstructor, '.uaverage' );
    if ( !cds( xdelta ) ) {
      return( throw( 'Invalid delta x ...', origin = member ) );
    }
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( !is_boolean( weight ) ) {
      return( throw( 'Invalid weight boolean ...', origin = member ) );
    }
    if ( !is_boolean( xcalc ) ) {
      return( throw( 'Invalid recalculate-x boolean ...', origin = member ) );
    }
    if ( !private.checkinterp( interp ) ) {
      return( throw( 'Invalid interpolation method ...', origin = member ) );
    }
    x := seq( xmin, xmax, xdelta );
    return( private.averagefunc( public.id(), x, xmin, xmax, token, keep,
        weight, xcalc, interp, public.host(), public.forcenewserver() ) );
  }


  # Define the 'interpolate' public member function

  if ( spaste( split( private.gconstructor, '' )[1:9] ) == 'gdc1token' ) {

    const val public.interpolate := function( x, token = "", keep = F,
        interp = 'SPLINE', xminbox = [], xmaxbox = [] ) {
      wider private, public;
      member := spaste( private.gconstructor, '.interpolate' );
      if ( !private.checktoken( token ) ) {
        return( throw( 'Invalid token(s) ...', origin = member ) );
      }
      if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
      }
      if ( !private.checkinterp( interp ) ) {
        return( throw( 'Invalid interpolation method ...', origin = member ) );
      }
      if ( !private.checkx( xminbox, xmaxbox ) ) {
        return( throw( 'Invalid x-box argument(s) ...', origin = member ) );
      }
      if ( !private.checkxvec( x, xminbox, xmaxbox ) ) {
        return( throw( 'Invalid x vector ...', origin = member ) );
      }
      return( private.interpolatefunc( public.id(), x, token, keep, interp,
          xminbox, xmaxbox, public.host(), public.forcenewserver() ) );
    }
    
  }


  # Define the 'uinterpolate' public member function

  const val public.uinterpolate := function( xdelta, xmin = [], xmax = [],
      token = "", keep = F, interp = 'SPLINE', xminbox = [], xmaxbox = [] ) {
    wider private, public;
    member := spaste( private.gconstructor, '.uinterpolate' );
    if ( !cds( xdelta ) ) {
      return( throw( 'Invalid delta x ...', origin = member ) );
    }
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( !private.checkinterp( interp ) ) {
      return( throw( 'Invalid interpolation method ...', origin = member ) );
    }
    if ( !private.checkx( xminbox, xmaxbox ) ) {
      return( throw( 'Invalid x-box argument(s) ...', origin = member ) );
    }
    x := seq( xmin, xmax, xdelta );
    return( private.interpolatefunc( public.id(), x, token, keep, interp,
        xminbox, xmaxbox, public.host(), public.forcenewserver() ) );
  }


  # Define the 'yinterpolate' public and private member functions

  const val public.yinterpolate := function( x, token = "", keep = F,
      interp = 'SPLINE', xminbox = [], xmaxbox = [] ) {
    wider private, public;
    member := spaste( private.gconstructor, '.yinterpolate' );
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( !private.checkinterp( interp ) ) {
      return( throw( 'Invalid interpolation method ...', origin = member ) );
    }
    if ( !private.checkx( xminbox, xmaxbox ) ) {
      return( throw( 'Invalid x-box argument(s) ...', origin = member ) );
    }
    if ( !private.checkxvec( x, xminbox, xmaxbox ) ) {
      return( throw( 'Invalid x vector ...', origin = member ) );
    }
    return( private.yinterpolate( x, token, keep, interp, xminbox, xmaxbox ) );
  }

  val private.yinterpolateRec := [_method = 'yInterpolate',
      _sequence = private.id._sequence];
  
  const val private.yinterpolate := function( x, token, keep, interp, xminbox,
      xmaxbox ) {
    wider private;
    val private.yinterpolateRec.xarg := x;
    val private.yinterpolateRec.tokenarg := token;
    val private.yinterpolateRec.keep := keep;
    val private.yinterpolateRec.interp := interp;
    val private.yinterpolateRec.xminbox := xminbox;
    val private.yinterpolateRec.xmaxbox := xmaxbox;
    return( defaultservers.run( private.agent, private.yinterpolateRec ) );
  }
    
  
  # Define the 'calc' public member function
  
  const val public.calc := function( myfunc, ..., xmin = [], xmax = [],
      token = "", keep = F, tokentype = 'Token' ) {
    wider private, public;
    member := spaste( private.gconstructor, '.calc' );
    if ( !is_function( myfunc ) ) {
      return( throw( 'Invalid function ...', origin = member ) );
    }
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    xTemp := private.x( xmin, xmax, token, keep );
    if ( length( xTemp ) < 1 ) {
      return( throw( 'No data in range ...', origin = member ) );
    }
    xerrTemp := private.xerr( xmin, xmax, token, keep );
    yTemp := private.y( xmin, xmax, token, keep );
    yerrTemp := private.yerr( xmin, xmax, token, keep );
    tokenTemp := private.token( xmin, xmax, token, keep );
    retval := [=];
    retval.x := as_double([]);
    retval.y := as_double([]);
    retval.xerr := as_double([]);
    retval.yerr := as_double([]);
    retval.token := "";
    if ( is_fail( myfunc( xTemp, yTemp, xerrTemp, yerrTemp, retval.x,
        retval.y, retval.xerr, retval.yerr, retval.token, ... ) ) ) {
      return( throw( 'Calculation error ...', origin = member ) );
    }
    gdc1tokenTemp := gdc1token_standard( retval.x, retval.y, retval.xerr,
        retval.yerr, retval.token, tokentype = tokentype );
    return( ref gdc1tokenTemp );
  }
    
  
  # Define the 'ycalc' public member function
  
  const val public.ycalc := function( myfunc, ..., xmin = [], xmax = [],
      token = "", keep = F ) {
    wider private, public;
    member := spaste( private.gconstructor, '.ycalc' );
    if ( !is_function( myfunc ) ) {
      return( throw( 'Invalid function ...', origin = member ) );
    }
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    xTemp := private.x( xmin, xmax, token, keep );
    if ( length( xTemp ) < 1 ) {
      return( throw( 'No data in range ...', origin = member ) );
    }
    xerrTemp := private.xerr( xmin, xmax, token, keep );
    yTemp := private.y( xmin, xmax, token, keep );
    yerrTemp := private.yerr( xmin, xmax, token, keep );
    tokenTemp := private.token( xmin, xmax, token, keep );
    retval := [=];
    retval.x := as_double([]);
    retval.y := as_double([]);
    retval.xerr := as_double([]);
    retval.yerr := as_double([]);
    retval.token := as_string([]);
    if ( is_fail( myfunc( xTemp, yTemp, xerrTemp, yerrTemp, retval.x,
        retval.y, retval.xerr, retval.yerr, retval.token, ... ) ) ) {
      return( throw( 'Calculation error ...', origin = member ) );
    }
    return( retval );
  }


  # Define the 'length' public and private member functions

  const val public.length := function( xmin = [], xmax = [], token = "",
      keep = F ) {
    wider private;
    member := spaste( private.gconstructor, '.length' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    return( private.length( xmin, xmax, token, keep ) );
  }

  val private.lengthRec := [_method = 'length',
      _sequence = private.id._sequence];
  
  const val private.length := function( xmin, xmax, token, keep ) {
    wider private;
    val private.lengthRec.xmin := xmin;
    val private.lengthRec.xmax := xmax;
    val private.lengthRec.tokenarg := token;
    val private.lengthRec.keep := keep;
    return( defaultservers.run( private.agent, private.lengthRec ) );
  }


  # Define the 'x' public and private member functions

  const val public.x := function( xmin = [], xmax = [], token = "", keep = F ) {
    wider private;
    member := spaste( private.gconstructor, '.x' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    return( private.x( xmin, xmax, token, keep ) );
  }

  val private.xRec := [_method = 'x', _sequence = private.id._sequence];
  
  const val private.x := function( xmin, xmax, token, keep ) {
    wider private;
    val private.xRec.xmin := xmin;
    val private.xRec.xmax := xmax;
    val private.xRec.tokenarg := token;
    val private.xRec.keep := keep;
    return( defaultservers.run( private.agent, private.xRec ) );
  }


  # Define the 'y' public and private member functions

  const val public.y := function( xmin = [], xmax = [], token = "", keep = F,
      orig = F ) {
    wider private;
    member := spaste( private.gconstructor, '.y' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( orig ) ) {
      return( throw(
          'Invalid \'original-data (non-interpolated)\' boolean ...',
          origin = member ) );
    }
    return( private.y( xmin, xmax, token, keep, orig ) );
  }

  val private.yRec := [_method = 'y', _sequence = private.id._sequence];
  
  const val private.y := function( xmin, xmax, token, keep, orig ) {
    wider private;
    val private.yRec.xmin := xmin;
    val private.yRec.xmax := xmax;
    val private.yRec.tokenarg := token;
    val private.yRec.keep := keep;
    val private.yRec.orig := orig;
    return( defaultservers.run( private.agent, private.yRec ) );
  }


  # Define the 'xerr' public and private member functions

  const val public.xerr := function( xmin = [], xmax = [], token = "",
      keep = F ) {
    wider private;
    member := spaste( private.gconstructor, '.xerr' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    return( private.xerr( xmin, xmax, token, keep ) );
  }

  val private.xErrRec := [_method = 'xErr', _sequence = private.id._sequence];
  
  const val private.xerr := function( xmin, xmax, token, keep ) {
    wider private;
    val private.xErrRec.xmin := xmin;
    val private.xErrRec.xmax := xmax;
    val private.xErrRec.tokenarg := token;
    val private.xErrRec.keep := keep;
    return( defaultservers.run( private.agent, private.xErrRec ) );
  }


  # Define the 'yerr' public and private member functions

  const val public.yerr := function( xmin = [], xmax = [], token = "",
      keep = F, orig = F ) {
    wider private;
    member := spaste( private.gconstructor, '.yerr' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( orig ) ) {
      return( throw( 'Invalid \'original-data\' boolean ...',
          origin = member ) );
    }
    return( private.yerr( xmin, xmax, token, keep, orig ) );
  }

  val private.yErrRec := [_method = 'yErr', _sequence = private.id._sequence];
  
  const val private.yerr := function( xmin, xmax, token, keep, orig ) {
    wider private;
    val private.yErrRec.xmin := xmin;
    val private.yErrRec.xmax := xmax;
    val private.yErrRec.tokenarg := token;
    val private.yErrRec.keep := keep;
    val private.yErrRec.orig := orig;
    return( defaultservers.run( private.agent, private.yErrRec ) );
  }
  
  
  # Define the 'xerror' public and private member functions
  
  const val public.xerror := function( ) {
    wider private;
    return( private.xerror() );
  }

  val private.xErrorRec := [_method = 'xError',
      _sequence = private.id._sequence];
  
  const val private.xerror := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.xErrorRec ) );
  }
  
  
  # Define the 'yerror' public and private member functions
  
  const val public.yerror := function( ) {
    wider private;
    return( private.yerror() );
  }

  val private.yErrorRec := [_method = 'yError',
      _sequence = private.id._sequence];
  
  const val private.yerror := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.yErrorRec ) );
  }
  
  
  # Define the 'token' public and private member functions

  const val public.token := function( xmin = [], xmax = [], token = "",
      keep = F ) {
    wider private;
    member := spaste( private.gconstructor, '.token' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    return( private.token( xmin, xmax, token, keep ) );
  }

  val private.tokenRec := [_method = 'token', _sequence = private.id._sequence];
  
  const val private.token := function( xmin, xmax, token, keep ) {
    wider private;
    val private.tokenRec.xmin := xmin;
    val private.tokenRec.xmax := xmax;
    val private.tokenRec.tokenarg := token;
    val private.tokenRec.keep := keep;
    return( defaultservers.run( private.agent, private.tokenRec ) );
  }
  
  
  # Define the 'tokentype' public and private member functions

  val private.tokenTypeRec :=
      [_method = 'tokenType', _sequence = private.id._sequence];
  
  const val public.tokentype := function( ) {
    wider private;
    return( private.tokentype() );
  }
  
  const val private.tokentype := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.tokenTypeRec ) );
  }
  
  
  # Define the 'tokenlist' public and private member functions

  val private.tokenListRec :=
      [_method = 'tokenList', _sequence = private.id._sequence];
  
  const val public.tokenlist := function( ) {
    wider private;
    return( private.tokenlist() );
  }
  
  const val private.tokenlist := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.tokenListRec ) );
  }


  # Define the 'flag' public and private member functions

  const val public.flag := function( xmin = [], xmax = [], token = "",
      orig = F ) {
    wider private;
    member := spaste( private.gconstructor, '.flag' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( orig ) ) {
      return( throw( 'Invalid \'original-flags\' boolean ...',
          origin = member ) );
    }
    return( private.flag( xmin, xmax, token, orig ) );
  }

  val private.flagRec := [_method = 'flag', _sequence = private.id._sequence];
  
  const val private.flag := function( xmin, xmax, token, orig ) {
    wider private;
    val private.flagRec.xmin := xmin;
    val private.flagRec.xmax := xmax;
    val private.flagRec.tokenarg := token;
    val private.flagRec.orig := orig;
    return( defaultservers.run( private.agent, private.flagRec ) );
  }


  # Define the 'interp' public and private member functions

  const val public.interp := function( xmin = [], xmax = [], token = "" ) {
    wider private;
    member := spaste( private.gconstructor, '.interp' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    return( private.interp( xmin, xmax, token ) );
  }

  val private.interpRec :=
      [_method = 'interp', _sequence = private.id._sequence];
  
  const val private.interp := function( xmin, xmax, token ) {
    wider private;
    val private.interpRec.xmin := xmin;
    val private.interpRec.xmax := xmax;
    val private.interpRec.tokenarg := token;
    return( defaultservers.run( private.agent, private.interpRec ) );
  }
  
  
  # Define the 'index' public and private member functions

  const val public.index := function( xmin = [], xmax = [], token = "",
      keep = F ) {
    wider private;
    member := spaste( private.gconstructor, '.index' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    return( private.index( xmin, xmax, token, keep ) );
  }

  val private.indexRec := [_method = 'index', _sequence = private.id._sequence];
  
  const val private.index := function( xmin, xmax, token, keep ) {
    wider private;
    val private.indexRec.xmin := xmin;
    val private.indexRec.xmax := xmax;
    val private.indexRec.tokenarg := token;
    val private.indexRec.keep := keep;
    return( defaultservers.run( private.agent, private.indexRec ) );
  }


  # Define the 'xmin' public and private member functions

  const val public.xmin := function( xmin = [], xmax = [], token = "", keep = F,
      plot = F ) {
    wider private;
    member := spaste( private.gconstructor, '.xmin' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( plot ) ) {
      return( throw( 'Invalid plot boolean ...', origin = member ) );
    }
    return( private.xmin( xmin, xmax, token, keep, plot ) );
  }

  val private.xminRec := [_method = 'xMin', _sequence = private.id._sequence];
  
  const val private.xmin := function( xmin, xmax, token, keep, plot ) {
    wider private;
    val private.xminRec.xmin := xmin;
    val private.xminRec.xmax := xmax;
    val private.xminRec.tokenarg := token;
    val private.xminRec.keep := keep;
    val private.xminRec.plot := plot;
    return( defaultservers.run( private.agent, private.xminRec ) );
  }


  # Define the 'xmax' public and private member functions

  const val public.xmax := function( xmin = [], xmax = [], token = "", keep = F,
      plot = F ) {
    wider private;
    member := spaste( private.gconstructor, '.xmax' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( plot ) ) {
      return( throw( 'Invalid plot boolean ...', origin = member ) );
    }
    return( private.xmax( xmin, xmax, token, keep, plot ) );
  }

  val private.xmaxRec := [_method = 'xMax', _sequence = private.id._sequence];
  
  const val private.xmax := function( xmin, xmax, token, keep, plot ) {
    wider private;
    val private.xmaxRec.xmin := xmin;
    val private.xmaxRec.xmax := xmax;
    val private.xmaxRec.tokenarg := token;
    val private.xmaxRec.keep := keep;
    val private.xmaxRec.plot := plot;
    return( defaultservers.run( private.agent, private.xmaxRec ) );
  }
  

  # Define the 'xerrmin' public and private member functions

  const val public.xerrmin := function( xmin = [], xmax = [], token = "",
      keep = F ) {
    wider private;
    member := spaste( private.gconstructor, '.xerrmin' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    return( private.xerrmin( xmin, xmax, token, keep ) );
  }

  val private.xErrMinRec := [_method = 'xErrMin',
      _sequence = private.id._sequence];
  
  const val private.xerrmin := function( xmin, xmax, token, keep ) {
    wider private;
    val private.xErrMinRec.xmin := xmin;
    val private.xErrMinRec.xmax := xmax;
    val private.xErrMinRec.tokenarg := token;
    val private.xErrMinRec.keep := keep;
    return( defaultservers.run( private.agent, private.xErrMinRec ) );
  }


  # Define the 'xerrmax' public and private member functions

  const val public.xerrmax := function( xmin = [], xmax = [], token = "",
      keep = F ) {
    wider private;
    member := spaste( private.gconstructor, '.xerrmax' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    return( private.xerrmax( xmin, xmax, token, keep ) );
  }

  val private.xErrMaxRec := [_method = 'xErrMax',
      _sequence = private.id._sequence];
  
  const val private.xerrmax := function( xmin, xmax, token, keep ) {
    wider private;
    val private.xErrMaxRec.xmin := xmin;
    val private.xErrMaxRec.xmax := xmax;
    val private.xErrMaxRec.tokenarg := token;
    val private.xErrMaxRec.keep := keep;
    return( defaultservers.run( private.agent, private.xErrMaxRec ) );
  }


  # Define the 'ymin' public and private member functions

  const val public.ymin := function( xmin = [], xmax = [], token = "", keep = F,
      plot = F ) {
    wider private;
    member := spaste( private.gconstructor, '.ymin' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( plot ) ) {
      return( throw( 'Invalid plot boolean ...', origin = member ) );
    }
    return( private.ymin( xmin, xmax, token, keep, plot ) );
  }

  val private.yminRec := [_method = 'yMin', _sequence = private.id._sequence];
  
  const val private.ymin := function( xmin, xmax, token, keep, plot ) {
    wider private;
    val private.yminRec.xmin := xmin;
    val private.yminRec.xmax := xmax;
    val private.yminRec.tokenarg := token;
    val private.yminRec.keep := keep;
    val private.yminRec.plot := plot;
    return( defaultservers.run( private.agent, private.yminRec ) );
  }


  # Define the 'ymax' public and private member functions

  const val public.ymax := function( xmin = [], xmax = [], token = "", keep = F,
      plot = F ) {
    wider private;
    member := spaste( private.gconstructor, '.ymax' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( plot ) ) {
      return( throw( 'Invalid plot boolean ...', origin = member ) );
    }
    return( private.ymax( xmin, xmax, token, keep, plot ) );
  }

  val private.ymaxRec := [_method = 'yMax', _sequence = private.id._sequence];
  
  const val private.ymax := function( xmin, xmax, token, keep, plot ) {
    wider private;
    val private.ymaxRec.xmin := xmin;
    val private.ymaxRec.xmax := xmax;
    val private.ymaxRec.tokenarg := token;
    val private.ymaxRec.keep := keep;
    val private.ymaxRec.plot := plot;
    return( defaultservers.run( private.agent, private.ymaxRec ) );
  }
  

  # Define the 'yerrmin' public and private member functions

  const val public.yerrmin := function( xmin = [], xmax = [], token = "",
      keep = F ) {
    wider private;
    member := spaste( private.gconstructor, '.yerrmin' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    return( private.yerrmin( xmin, xmax, token, keep ) );
  }

  val private.yErrMinRec := [_method = 'yErrMin',
      _sequence = private.id._sequence];
  
  const val private.yerrmin := function( xmin, xmax, token, keep ) {
    wider private;
    val private.yErrMinRec.xmin := xmin;
    val private.yErrMinRec.xmax := xmax;
    val private.yErrMinRec.tokenarg := token;
    val private.yErrMinRec.keep := keep;
    return( defaultservers.run( private.agent, private.yErrMinRec ) );
  }


  # Define the 'yerrmax' public and private member functions

  const val public.yerrmax := function( xmin = [], xmax = [], token = "",
      keep = F ) {
    wider private;
    member := spaste( private.gconstructor, '.yerrmax' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( private.getargcheck() && !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    return( private.yerrmax( xmin, xmax, token, keep ) );
  }

  val private.yErrMaxRec := [_method = 'yErrMax',
      _sequence = private.id._sequence];
  
  const val private.yerrmax := function( xmin, xmax, token, keep ) {
    wider private;
    val private.yErrMaxRec.xmin := xmin;
    val private.yErrMaxRec.xmax := xmax;
    val private.yErrMaxRec.tokenarg := token;
    val private.yErrMaxRec.keep := keep;
    return( defaultservers.run( private.agent, private.yErrMaxRec ) );
  }
  
  
  # Define the 'flagged' public and private member functions

  const val public.flagged := function( xmin = [], xmax = [], token = "" ) {
    wider private;
    member := spaste( private.gconstructor, '.flagged' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    return( private.flagged( xmin, xmax, token ) );
  }

  val private.flaggedRec := [_method = 'flagged',
      _sequence = private.id._sequence];
  
  const val private.flagged := function( xmin, xmax, token ) {
    wider private;
    val private.flaggedRec.xmin := xmin;
    val private.flaggedRec.xmax := xmax;
    val private.flaggedRec.tokenarg := token;
    return( defaultservers.run( private.agent, private.flaggedRec ) );
  }
  
  
  # Define the 'interpolated' public and private member functions

  const val public.interpolated := function( xmin = [], xmax = [],
      token = "" ) {
    wider private;
    member := spaste( private.gconstructor, '.interpolated' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    return( private.interpolated( xmin, xmax, token ) );
  }

  val private.interpolatedRec := [_method = 'interpolated',
      _sequence = private.id._sequence];
  
  const val private.interpolated := function( xmin, xmax, token ) {
    wider private;
    val private.interpolatedRec.xmin := xmin;
    val private.interpolatedRec.xmax := xmax;
    val private.interpolatedRec.tokenarg := token;
    return( defaultservers.run( private.agent, private.interpolatedRec ) );
  }
  
  
  # Define the 'hms' public member function

  val private.hmsRec := [_method = 'hms', _sequence = private.id._sequence];
  
  const val public.hms := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.hmsRec ) );
  }
  
  
  # Define the 'mean' public and private member functions

  const val public.mean := function( xmin = [], xmax = [], token = "", keep = F,
      weight = F ) {
    wider private;
    member := spaste( private.gconstructor, '.mean' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( !is_boolean( weight ) ) {
      return( throw( 'Invalid weight boolean ...', origin = member ) );
    }
    return( private.mean( xmin, xmax, token, keep, weight ) );
  }

  val private.meanRec := [_method = 'mean', _sequence = private.id._sequence];
  
  const val private.mean := function( xmin, xmax, token, keep, weight ) {
    wider private;
    val private.meanRec.xmin := xmin;
    val private.meanRec.xmax := xmax;
    val private.meanRec.tokenarg := token;
    val private.meanRec.keep := keep;
    val private.meanRec.weight := weight;
    return( defaultservers.run( private.agent, private.meanRec ) );
  }
  
  
  # Define the 'meanerr' public and private member functions

  const val public.meanerr := function( xmin = [], xmax = [], token = "",
      keep = F, weight = F ) {
    wider private;
    member := spaste( private.gconstructor, '.meanerr' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( !is_boolean( weight ) ) {
      return( throw( 'Invalid weight boolean ...', origin = member ) );
    }
    return( private.meanerr( xmin, xmax, token, keep, weight ) );
  }

  val private.meanErrRec := [_method = 'meanErr',
      _sequence = private.id._sequence];
  
  const val private.meanerr := function( xmin, xmax, token, keep, weight ) {
    wider private;
    val private.meanErrRec.xmin := xmin;
    val private.meanErrRec.xmax := xmax;
    val private.meanErrRec.tokenarg := token;
    val private.meanErrRec.keep := keep;
    val private.meanErrRec.weight := weight;
    return( defaultservers.run( private.agent, private.meanErrRec ) );
  }
  
  
  # Define the 'variance' public and private member functions

  const val public.variance := function( xmin = [], xmax = [], token = "",
      keep = F, weight = F ) {
    wider private;
    member := spaste( private.gconstructor, '.variance' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( !is_boolean( weight ) ) {
      return( throw( 'Invalid weight boolean ...', origin = member ) );
    }
    return( private.variance( xmin, xmax, token, keep, weight ) );
  }

  val private.varianceRec :=
      [_method = 'variance', _sequence = private.id._sequence];
  
  const val private.variance := function( xmin, xmax, token, keep, weight ) {
    wider private;
    val private.varianceRec.xmin := xmin;
    val private.varianceRec.xmax := xmax;
    val private.varianceRec.tokenarg := token;
    val private.varianceRec.keep := keep;
    val private.varianceRec.weight := weight;
    return( defaultservers.run( private.agent, private.varianceRec ) );
  }
  
  
  # Define the 'stddev' public and private member functions

  const val public.stddev := function( xmin = [], xmax = [], token = "",
      keep = F, weight = F ) {
    wider private;
    member := spaste( private.gconstructor, '.stddev' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( !is_boolean( weight ) ) {
      return( throw( 'Invalid weight boolean ...', origin = member ) );
    }
    return( private.stddev( xmin, xmax, token, keep, weight ) );
  }

  val private.stdDevRec := [_method = 'stdDev',
      _sequence = private.id._sequence];
  
  const val private.stddev := function( xmin, xmax, token, keep, weight ) {
    wider private;
    val private.stdDevRec.xmin := xmin;
    val private.stdDevRec.xmax := xmax;
    val private.stdDevRec.tokenarg := token;
    val private.stdDevRec.keep := keep;
    val private.stdDevRec.weight := weight;
    return( defaultservers.run( private.agent, private.stdDevRec ) );
  }
  
  
  # Define the 'setflagx' public and private member functions

  const val public.setflagx := function( xmin = [], xmax = [], token = "",
      flag = T ) {
    wider private;
    member := spaste( private.gconstructor, '.setflagx' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( flag ) ) {
      return( throw( 'Invalid flag boolean ...', origin = member ) );
    }
    return( private.setflagx( xmin, xmax, token, flag ) );
  }

  val private.setFlagXRec :=
      [_method = 'setFlagX', _sequence = private.id._sequence];
  
  const val private.setflagx := function( xmin, xmax, token, flag ) {
    wider gui, private, public;
    member := spaste( private.gconstructor, '.setflagx' );
    val private.setFlagXRec.xmin := xmin;
    val private.setFlagXRec.xmax := xmax;
    val private.setFlagXRec.tokenarg := token;
    val private.setFlagXRec.flagarg := flag;
    if ( is_fail( retval := defaultservers.run( private.agent,
        private.setFlagXRec ) ) ) {
      return( throw( 'Cannot set flag(s) ...', origin = member ) );
    }
    __gdc1token_editgui_update( gui, private, public );
    __gdc1token_statsgui_update( gui, private, public );
    private.plot();
    return( retval );
  }
  
  
  # Define the 'setflagxy' public and private member functions

  const val public.setflagxy := function( xmin = [], xmax = [], ymin = [],
      ymax = [], token = "", flag = T ) {
    wider private;
    member := spaste( private.gconstructor, '.setflagxy' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checky( ymin, ymax ) ) {
      return( throw( 'Invalid y argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( flag ) ) {
      return( throw( 'Invalid flag boolean ...', origin = member ) );
    }
    return( private.setflagxy( xmin, xmax, ymin, ymax, token, flag ) );
  }

  val private.setFlagXYRec :=
      [_method = 'setFlagXY', _sequence = private.id._sequence];
  
  const val private.setflagxy := function( xmin, xmax, ymin, ymax, token,
      flag ) {
    wider gui, private, public;
    member := spaste( private.gconstructor, '.setflagxy' );
    val private.setFlagXYRec.xmin := xmin;
    val private.setFlagXYRec.xmax := xmax;
    val private.setFlagXYRec.ymin := ymin;
    val private.setFlagXYRec.ymax := ymax;
    val private.setFlagXYRec.tokenarg := token;
    val private.setFlagXYRec.flagarg := flag;
    if ( is_fail( retval := defaultservers.run( private.agent,
        private.setFlagXYRec ) ) ) {
      return( throw( 'Cannot set flag(s) ...', origin = member ) );
    }
    __gdc1token_editgui_update( gui, private, public );
    __gdc1token_statsgui_update( gui, private, public );
    private.plot();
    return( retval );
  }
  
  
  # Define the 'interpolatex' public and private member functions

  const val public.interpolatex := function( xmin = [], xmax = [], token = "",
      keep = F, interp = 'spline', xminbox = [], xmaxbox = [] ) {
    wider private;
    member := spaste( private.gconstructor, '.interpolatex' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( !private.checkinterp( interp ) ) {
      return( throw( 'Invalid interpolation method ...', origin = member ) );
    }
    if ( interp == '' ) {
      return( throw( 'No interpolation method specified...',
          origin = member ) );
    }
    if ( !private.checkx( xminbox, xmaxbox ) ) {
      return( throw( 'Invalid x-box argument(s) ...', origin = member ) );
    }
    return( private.interpolatex( xmin, xmax, token, keep, interp, xminbox,
        xmaxbox ) );
  }

  val private.interpolateXRec :=
      [_method = 'interpolateX', _sequence = private.id._sequence];
  
  const val private.interpolatex := function( xmin, xmax, token, keep, interp,
      xminbox, xmaxbox ) {
    wider gui, private, public;
    member := spaste( private.gconstructor, '.interpolatex' );
    val private.interpolateXRec.xmin := xmin;
    val private.interpolateXRec.xmax := xmax;
    val private.interpolateXRec.tokenarg := token;
    val private.interpolateXRec.keep := keep;
    val private.interpolateXRec.interp := interp;
    val private.interpolateXRec.xminbox := xminbox;
    val private.interpolateXRec.xmaxbox := xmaxbox;
    if ( is_fail( retval := defaultservers.run( private.agent,
        private.interpolateXRec ) ) ) {
      return( throw( 'Cannot set interpolate ...', origin = member ) );
    }
    __gdc1token_editgui_update( gui, private, public );
    __gdc1token_statsgui_update( gui, private, public );
    private.plot();
    return( retval );
  }
  
  
  # Define the 'interpolatexy' public and private member functions

  const val public.interpolatexy := function( xmin = [], xmax = [], token = "",
      keep = F, interp = 'spline', ymin = [], ymax = [], xminbox = [],
      xmaxbox = [], yminbox = [], ymaxbox = [] ) {
    wider private;
    member := spaste( private.gconstructor, '.interpolatexy' );
    if ( !private.checkx( xmin, xmax ) ) {
      return( throw( 'Invalid x argument(s) ...', origin = member ) );
    }
    if ( !private.checktoken( token ) ) {
      return( throw( 'Invalid token(s) ...', origin = member ) );
    }
    if ( !is_boolean( keep ) ) {
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    if ( !private.checkinterp( interp ) ) {
      return( throw( 'Invalid interpolation method ...', origin = member ) );
    }
    if ( !private.checky( ymin, ymax ) ) {
      return( throw( 'Invalid y argument(s) ...', origin = member ) );
    }
    if ( interp == '' ) {
      return( throw( 'No interpolation method specified...',
          origin = member ) );
    }
    if ( !private.checkx( xminbox, xmaxbox ) ) {
      return( throw( 'Invalid x-box argument(s) ...', origin = member ) );
    }
    if ( !private.checky( yminbox, ymaxbox ) ) {
      return( throw( 'Invalid y-box argument(s) ...', origin = member ) );
    }
    return( private.interpolatexy( xmin, xmax, token, keep, interp, ymin, ymax,
        xminbox, xmaxbox, yminbox, ymaxbox ) );
  }

  val private.interpolateXYRec :=
      [_method = 'interpolateXY', _sequence = private.id._sequence];
  
  const val private.interpolatexy := function( xmin, xmax, token, keep, interp,
      ymin, ymax, xminbox, xmaxbox, yminbox, ymaxbox ) {
    wider gui, private, public;
    member := spaste( private.gconstructor, '.interpolatexy' );
    val private.interpolateXYRec.xmin := xmin;
    val private.interpolateXYRec.xmax := xmax;
    val private.interpolateXYRec.tokenarg := token;
    val private.interpolateXYRec.keep := keep;
    val private.interpolateXYRec.interp := interp;
    val private.interpolateXYRec.ymin := ymin;
    val private.interpolateXYRec.ymax := ymax;
    val private.interpolateXYRec.xminbox := xminbox;
    val private.interpolateXYRec.xmaxbox := xmaxbox;
    val private.interpolateXYRec.yminbox := yminbox;
    val private.interpolateXYRec.ymaxbox := ymaxbox;
    if ( is_fail( retval := defaultservers.run( private.agent,
        private.interpolateXYRec ) ) ) {
      return( throw( 'Cannot interpolate ...', origin = member ) );
    }
    __gdc1token_editgui_update( gui, private, public );
    __gdc1token_statsgui_update( gui, private, public );
    private.plot();
    return( retval );
  }
  
  
  # Define the 'undohistory' public and private member functions

  const val public.undohistory := function( ) {
    wider private;
    return( private.undohistory() );
  }

  val private.undoHistoryRec :=
      [_method = 'undoHistory', _sequence = private.id._sequence];

  const val private.undohistory := function( ) {
    wider gui, private, public;
    member := spaste( private.gconstructor, '.undohistory' );
    if ( is_fail( retval := defaultservers.run( private.agent,
        private.undoHistoryRec ) ) ) {
      return( throw( 'Cannot undo flag(s) ...', origin = member ) );
    }
    __gdc1token_editgui_update( gui, private, public );
    __gdc1token_statsgui_update( gui, private, public );
    private.plot();
    return( retval );
  }
  
  
  # Define the 'resethistory' public and private member functions

  const val public.resethistory := function( ) {
    wider private;
    return( private.resethistory() );
  }

  val private.resetHistoryRec :=
      [_method = 'resetHistory', _sequence = private.id._sequence];

  const val private.resethistory := function( ) {
    wider gui, private, public;
    member := spaste( private.gconstructor, '.resethistory' );
    if ( is_fail( retval := defaultservers.run( private.agent,
        private.resetHistoryRec ) ) ) {
      return( throw( 'Cannot reset flag(s) ...', origin = member ) );
    }
    __gdc1token_editgui_update( gui, private, public );
    __gdc1token_statsgui_update( gui, private, public );
    private.plot();
    return( retval );
  }
  
  
  # Return T
  
  return( T );
  
}
