# __obdata1_public.g is part of the Cuttlefish server
# Copyright (C) 2001
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
# Correspondence concerning the Cuttlefish server should be addressed as follows:
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
# $Id: __obdata1_public.g,v 19.0 2003/07/16 06:02:49 aips2adm Exp $
# ------------------------------------------------------------------------------

# __obdata1_public.g

# USNO/NRL Optical Interferometer
# United States Naval Observatory
# 3450 Massachusetts Avenue, NW
# Washington, DC  20392-5420

# Package:
# --------
# aips++

# Description:
# ------------
# This file contains the glish function for adding public member functions to
# the 1D output-beam tool.

# glish functions:
# ----------------
# __obdata1_public.

# Modification history:
# ---------------------
# 2001 May 11 - Nicholas Elias, USNO/NPOI
#               File created with glish function __obdata1_public( ).

# ------------------------------------------------------------------------------

# Pragmas

pragma include once;

# ------------------------------------------------------------------------------

# __obdata1_public

# Description
# -----------
# This glish function adds public member functions to the 1D output-beam tool.

# Inputs:
# -------
# gui     - The GUI variable.
# private - The private variable.
# public  - The public variable.

# Outputs:
# --------
# gui     - The GUI variable.
# private - The private variable.
# public  - The public variable.

# Modification history:
# ---------------------
# 2001 May 11 - Nicholas Elias, USNO/NPOI
#               Glish function created.

# ------------------------------------------------------------------------------

const __obdata1_public := function( ref gui, ref private, ref public ) {

  # Define the 'xlabelid' public member function

  const val public.xlabelid := function( xtoken ) {
    wider private;
    if ( !cs( xtoken, 0, T ) ) {
      member := spaste( private.gconstructor, '.changex' );
      return( throw( 'Invalid x-label token ...', origin = member ) );
    }
    return( private.xlabelid( xtoken ) );
  }

  val private.xLabelIDRec :=
      [_method = 'xLabelID', _sequence = private.id._sequence];

  const val private.xlabelid := function( xtoken ) {
    wider private;
    val private.xLabelIDRec.xtoken := xtoken;
    return( defaultservers.run( private.agent, private.xLabelIDRec ) );
  }


  # Define the 'xlabeltokens' public member function

  const val public.xlabeltokens := function( ) {
    wider private;
    return( private.xlabeltokens() );
  }

  val private.xLabelTokensRec :=
      [_method = 'xLabelTokens', _sequence = private.id._sequence];

  const val private.xlabeltokens := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.xLabelTokensRec ) );
  }


  # Define the 'xlabels' public member function

  const val public.xlabels := function( ) {
    wider private;
    return( private.xlabels() );
  }

  val private.xLabelsRec :=
      [_method = 'xLabels', _sequence = private.id._sequence];

  const val private.xlabels := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.xLabelsRec ) );
  }


  # Define the 'xtoken' public member function

  const val public.xtoken := function( ) {
    wider private;
    return( private.xtoken() );
  }

  val private.xTokenRec :=
      [_method = 'xToken', _sequence = private.id._sequence];

  const val private.xtoken := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.xTokenRec ) );
  }


  # Define the 'xtokenold' public member function

  const val public.xtokenold := function( ) {
    wider private;
    return( private.xtokenold() );
  }

  val private.xTokenOldRec :=
      [_method = 'xTokenOld', _sequence = private.id._sequence];

  const val private.xtokenold := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.xTokenOldRec ) );
  }
  

  # Define the 'changex' public member function

  const val public.changex := function( xtoken ) {
    wider gui, private, public;
    if ( !cs( xtoken, 0, T ) ) {
      member := spaste( private.gconstructor, '.changex' );
      return( throw( 'Invalid x-label token ...', origin = member ) );
    }
    ret := private.changex( xtoken );
    if ( !is_fail( ret ) ) {
      __obdata1_guimore_xaxis_update( xtoken, gui, private, public );
      private.plot();
      return( ret );
    } else {
      member := spaste( private.gconstructor, '.changex' );
      return( throw( 'Could not change x vector', origin = member ) );
    }
  }

  val private.changeXRec :=
      [_method = 'changeX', _sequence = private.id._sequence];

  const val private.changex := function( xtoken ) {
    wider private;
    val private.changeXRec.xtoken := xtoken;
    return( defaultservers.run( private.agent, private.changeXRec ) );
  }


  # Define the 'resetx' public member function

  const val public.resetx := function( ) {
    wider gui, private, public;
    ret := private.resetx();
    if ( !is_fail( ret ) ) {
      __obdata1_guimore_xaxis_update( public.xlabeltokens()[1], gui, private,
          public );
      private.plot();
      return( ret );
    } else {
      member := spaste( private.gconstructor, '.resetx' );
      return( throw( 'Could not change x vector', origin = member ) );
    }
  }

  val private.resetXRec :=
      [_method = 'resetX', _sequence = private.id._sequence];

  const val private.resetx := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.resetXRec ) );
  }


  # Define the 'derived' public and private member functions
  
  const val public.derived := function( ) {
    wider private;
    return( private.derived() );
  }

  val private.derivedRec :=
      [_method = 'derived', _sequence = private.id._sequence];
  
  const val private.derived := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.derivedRec ) );
  }


  # Define the 'file' public and private member functions
  
  const val public.file := function( ) {
    wider private;
    return( private.file() );
  }

  val private.fileRec := [_method = 'file', _sequence = private.id._sequence];
  
  const val private.file := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.fileRec ) );
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


  # Define the 'object' public and private member functions
  
  const val public.object := function( ) {
    wider private;
    return( private.object() );
  }

  val private.objectRec :=
      [_method = 'object', _sequence = private.id._sequence];
  
  const val private.object := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.objectRec ) );
  }


  # Define the 'objecterr' public and private member functions
  
  const val public.objecterr := function( ) {
    wider private;
    return( private.objecterr() );
  }

  val private.objectErrRec :=
      [_method = 'objectErr', _sequence = private.id._sequence];
  
  const val private.objecterr := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.objectErrRec ) );
  }


  # Define the 'type' public and private member functions
  
  const val public.type := function( ) {
    wider private;
    return( private.type() );
  }

  val private.typeRec := [_method = 'type', _sequence = private.id._sequence];
  
  const val private.type := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.typeRec ) );
  }


  # Define the 'typeerr' public and private member functions
  
  const val public.typeerr := function( ) {
    wider private;
    return( private.typeerr() );
  }

  val private.typeErrRec :=
      [_method = 'typeErr', _sequence = private.id._sequence];
  
  const val private.typeerr := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.typeErrRec ) );
  }


  # Define the 'outbeam' public and private member functions
  
  const val public.outbeam := function( ) {
    wider private;
    return( private.outbeam() );
  }

  val private.outBeamRec :=
      [_method = 'outBeam', _sequence = private.id._sequence];
  
  const val private.outbeam := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.outBeamRec ) );
  }


  # Define the 'numoutbeam' public and private member functions
  
  const val public.numoutbeam := function( ) {
    wider private;
    return( private.numoutbeam() );
  }

  val private.numOutBeamRec :=
      [_method = 'numOutBeam', _sequence = private.id._sequence];
  
  const val private.numoutbeam := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.numOutBeamRec ) );
  }


  # Define the 'baseline' public and private member functions
  
  const val public.baseline := function( ) {
    wider private;
    return( private.baseline() );
  }

  val private.baselineRec :=
      [_method = 'baseline', _sequence = private.id._sequence];
  
  const val private.baseline := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.baselineRec ) );
  }


  # Define the 'numbaseline' public and private member functions
  
  const val public.numbaseline := function( ) {
    wider private;
    return( private.numbaseline() );
  }

  val private.numBaselineRec :=
      [_method = 'numBaseline', _sequence = private.id._sequence];
  
  const val private.numbaseline := function( ) {
    wider private;
    return( defaultservers.run( private.agent, private.numBaselineRec ) );
  }
  
  
  # Define the 'clone' public member function
  
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
      return( throw( 'Invalid \'keep-flags\' boolean ...', origin = member ) );
    }
    return( private.clonefunc( public.id(), xmin, xmax, token, keep,
        public.host(), public.forcenewserver() ) );
  }
  
  
  # Define the 'average' public member function

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
    return( private.averagefunc( public.id(), x, xmin, xmax, token, keep,
        weight, xcalc, interp, public.host(), public.forcenewserver() ) );
  }


  # Define the 'interpolate' public member function

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
  

  # Define the 'hdsopen' public member function

  const val public.hdsopen := function( ) {
    wider public;
    file := public.file();
    host := public.host();
    forcenewserver := public.forcenewserver();
    return( hdsopen( file, T, host, forcenewserver ) );
  }


  # Define the 'obconfig' public member function

  const val public.obconfig := function( ) {
    wider public;
    file := public.file();
    host := public.host();
    forcenewserver := public.forcenewserver();
    return( obconfig( file, host, forcenewserver ) );
  }


  # Define the 'scaninfo' public member function

  const val public.scaninfo := function( ) {
    wider public;
    file := public.file();
    host := public.host();
    forcenewserver := public.forcenewserver();
    return( scaninfo( file, host, forcenewserver ) );
  }


  # Return T
  
  return( T );

}
