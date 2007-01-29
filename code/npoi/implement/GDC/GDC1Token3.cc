//#GDC1Token.cc is part of the GDC server
//#Copyright (C) 2000,2001
//#United States Naval Observatory; Washington, DC; USA.
//#
//#This library is free software; you can redistribute it and/or modify it
//#under the terms of the GNU Library General Public License as published by
//#the Free Software Foundation; either version 2 of the License, or (at your
//#option) any later version.
//#
//#This library is designed for use only in AIPS++ (National Radio Astronomy
//#Observatory; Charlottesville, VA; USA) in the hope that it will be useful, but
//#WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//#FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//#License for more details.
//#
//#You should have received a copy of the GNU Library General Public License
//#along with this library; if not, write to the Free Software Foundation,
//#Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//#Correspondence concerning the GDC server should be addressed as follows:
//#       Internet email: nme@nofs.navy.mil
//#       Postal address: Dr. Nicholas Elias
//#                       United States Naval Observatory
//#                       Navy Prototype Optical Interferometer
//#                       P.O. Box 1149
//#                       Flagstaff, AZ 86002-1149 USA
//#
//#Correspondence concerning AIPS++ should be addressed as follows:
//#       Internet email: aips2-request@nrao.edu.
//#       Postal address: AIPS++ Project Office
//#                       National Radio Astronomy Observatory
//#                       520 Edgemont Road
//#                       Charlottesville, VA 22903-2475 USA
//#
//# $Id: GDC1Token3.cc,v 19.0 2003/07/16 06:03:44 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

GDC1Token.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the GDC1Token{ } class member functions.

Public member functions:
------------------------
GDC1Token (7 versions), ~GDC1Token, addToken, average, changeX, checkInterp,
checkToken, checkX, checkY, clone, dumpASCII, fileASCII, flag, flagged,
fullSize, getArgCheck, getColor, getFlag, getKeep, getLine, getTitle, getToken,
getXLabel, getXMax, getXMin, getYLabel, getYMax, getYMin, history, hms, hmsOld,
index, interp, interpolate, interpolated, interpolateX, interpolateXY, length,
mean, meanerr, numEvent, plot, postScript, removeToken, resetHistory, resetX,
setArgCheck, setColor, setFlag, setFlagX, setFlagXY, setKeep, setLine, setTitle
(2 versions), setTitleDefault, setToken, setTokenDefault, setXLabel (2
versions), setXLabelDefault, setYLabel (2 versions), setYLabelDefault, stddev,
token, tokenList, tokenType, tool, variance, version, x, xErr, xErrMax (2
versions), xErrMin (2 versions), xErrOld, xError, xMax (2 versions), xMin (2
versions), xOld, y, yErr, yErrMax (2 versions), yErrMin (2 versions), yError,
yInterpolate, yMax (2 versions), yMin (2 versions), zoomx, zoomy, zoomxy.

Protected member functions:
---------------------------
initialize, initializePlotAttrib.

Private member functions:
-------------------------
loadASCII, plotLine, plotPoints.

Inherited classes (aips++):
---------------------------
ApplicationObject.

Inherited classes (Cuttlefish):
-------------------------------
GeneralStatus.

Modification history:
---------------------
2000 Apr 26 - Nicholas Elias, USNO/NPOI
              File created with public member functions GDC1Token( ) (standard
              and copy versions) and ~GDC1Token( ).
2000 Apr 28 - Nicholas Elias, USNO/NPOI
              Public member functions length( ), x( ), and index( ) added.
2000 May 01 - Nicholas Elias, USNO/NPOI Public member functions y( ), xErr( ),
              yErr( ), xError( ), yError( ), token( ), tokenType( ),
              tokenList( ), flag( ), xMax( ) (global and specific versions),
              xMin( ) (global and specific versions), yMax( ) (specific
              version), yMin( ) (specific version), xErrMax( ) (specific
              version), xErrMin( ) (specific version), yErrMax( ) (specific
              version), yErrMin( ) (specific version), flagged( ), mean( ),
              meanErr( ), stdDev( ), variance( ), version( ).
2000 May 07 - Nicholas Elias, USNO/NPOI
              Public member functions checkToken( ), checkX( ),
              resetHistory( ), setFlagX( ), setFlagXY( ), and undoHistory( )
              added.
2000 Jun 02 - Nicholas Elias, USNO/NPOI
              Public member function zoomxy( ) added.
2000 Jun 05 - Nicholas Elias, USNO/NPOI
              Public member functions plot( ), postScript( ), getToken( ),
              setToken( ) added.
2000 Jun 07 - Nicholas Elias, USNO/NPOI Public member functions GDC1Token( )
              (ASCII version), getXMin( ), getXMax( ), getYMin( ), getYMax( ),
              fillSize( ), setTokenDefault( ), getColor( ), setColor( ),
              getLine( ), setLine( ), getKeep( ), setKeep( ), getXLabel( ),
              setXLabel( ) (default and arbitrary versions),
              setXLabelDefault( ), getYLabel( ), setYLabel( ) (default and
              arbitrary versions), setYLabelDefault( ), getTitle( ),
              setTitle( ) (default and arbitrary versions), and
              setTitleDefault( ) added.  Protected member function
              initialize( ) added.  Private member function loadASCII( ) added.
2000 Jun 08 - Nicholas Elias, USNO/NPOI
              Public member functions checkY( ), dumpASCII( ), getArgCheck( ),
              history( ), and setArgCheck( ) added.
2000 Jun 12 - Nicholas Elias, USNO/NPOI
              Public member functions addToken( ) and removeToken( ) added.
2000 Jun 13 - Nicholas Elias, USNO/NPOI
              Public member functions getFlag( ) and setFlag( ) added.  Public
              member function setKeep( ) modified.
2000 Jun 19 - Nicholas Elias, USNO/NPOI
              Public member function numEvent( ) added.
2000 Jun 21 - Nicholas Elias, USNO/NPOI
              Public member functions GDC1Token( ) (clone version) and clone( )
              added.
2000 Jun 27 - Nicholas Elias, USNO/NPOI
              Public member functions GDC1Token( ) (average and interpolate
              versions), average( ), checkInterp( ), and interpolate( ) added.
2000 Jun 29 - Nicholas Elias, USNO/NPOI
              Public member function yInterpolate( ) added.
2000 Jun 30 - Public member functions xErrMax( ) (global version), xErrMin( )
              (global version), yErrMax( ) (global version), yErrMin( ) (global
              version), yErrMax( ) (global version), yMax( ) (global version),
              yMin( ) (global version) added.
2000 Jul 04 - Nicholas Elias, USNO/NPOI
              Public member function interpolated( ) added.
2000 Jul 06 - Nicholas Elias, USNO/NPOI
              Private member functions plotLine( ) and plotPoints( ) added.
2000 Jul 07 - Nicholas Elias, USNO/NPOI
              Public member functions zoomx( ), and zoomy( ) added.
2000 Jul 11 - Nicholas Elias, USNO/NPOI
              Public member function GDC1Token( ) (null version) added.
2000 Aug 07 - Nicholas Elias, USNO/NPOI
              Public member function fileASCII( ) added.
2000 Aug 10 - Nicholas Elias, USNO/NPOI
              Public member function tool( ) added.
2000 Aug 16 - Nicholas Elias, USNO/NPOI
              Public member functions interpolateX( ) and interpolateXY( )
              added.
2000 Aug 20 - Nicholas Elias, USNO/NPOI
              Public member function interp( ) added.
2000 Aug 24 - Nicholas Elias, USNO/NPOI
              Public member functions changeX( ) and resetX( ) added.
2000 Aug 25 - Nicholas Elias, USNO/NPOI
              Public member function hms( ) added.
2001 Jan 31 - Nicholas Elias, USNO/NPOI
              Public member functions hmsOld( ), xErrOld( ), and xOld( ) added.
2001 Mar 23 - Nicholas Elias, USNO/NPOI
              Protected member function initializePlotAttrib( ) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/GDC/GDC1Token.h> // GDC1Token file

// -----------------------------------------------------------------------------

/*

GDC1Token::runMethod

Description:
------------
This public member function provides the glish/aips++ interface for running the
methods of this class.

Inputs:
-------
uiMethod    - The method number.
oParameters - The method parameters.
bRunMethod  - The method run boolean.

Outputs:
--------
The method result, returned via the function value.

Modification history:
---------------------
2000 Apr 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult GDC1Token::runMethod2( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {
    
    // addToken
    case 51: {
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          addToken( tokenarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "addToken( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // removeToken
    case 52: {
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          removeToken( tokenarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "removeToken( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getFlag
    case 53: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getFlag();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getFlag( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setFlag
    case 54: {
      Parameter<Bool> flag( oParameters, "flag", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setFlag( flag() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setFlag( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getColor
    case 55: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getColor();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getColor( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setColor
    case 56: {
      Parameter<Bool> color( oParameters, "color", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setColor( color() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setColor( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getLine
    case 57: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getLine();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getLine( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setLine
    case 58: {
      Parameter<Bool> line( oParameters, "line", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setLine( line() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setLine( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getKeep
    case 59: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getKeep();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getKeep( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setKeep
    case 60: {
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setKeep( keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setKeep( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getXLabel
    case 61: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getXLabel( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getXLabel( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setXLabel
    case 62: {
      Parameter<String> xlabel( oParameters, "xlabel", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setXLabel( xlabel() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setXLabel( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setXLabelDefault
    case 63: {
      Parameter<String> xlabel( oParameters, "xlabel", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setXLabelDefault( xlabel() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setXLabelDefault( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getYLabel
    case 64: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getYLabel( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getYLabel( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setYLabel
    case 65: {
      Parameter<String> ylabel( oParameters, "ylabel", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setYLabel( ylabel() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setYLabel( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setYLabelDefault
    case 66: {
      Parameter<String> ylabel( oParameters, "ylabel", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setYLabelDefault( ylabel() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setYLabelDefault( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getTitle
    case 67: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getTitle( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getTitle( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setTitle
    case 68: {
      Parameter<String> title( oParameters, "title", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setTitle( title() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setTitle( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setTitleDefault
    case 69: {
      Parameter<String> title( oParameters, "title", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setTitleDefault( title() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setTitleDefault( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }

    // hms
    case 70: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = hms();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "hms( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // id    
    case 71: {
      Parameter<ObjectID> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
	  returnval() = id();
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "id( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
	}
      }
      break;
    }

    // version
    case 72: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = version();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "version( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }

    // tool
    case 73: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tool();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tool( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // checkToken
    case 74: {
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          Vector<String> oToken = tokenarg();
          Bool bCheck = checkToken( oToken );
          uInt uiToken;
          uInt uiNumToken = oToken.nelements();
          Vector<String> oToken2 = Vector<String>( uiNumToken + 1 );
          oToken2(0) = (String) bCheck;
          for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
            oToken2(uiToken+1) = oToken(uiToken);
          }
          returnval() = oToken2;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "checkToken( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // checkX
    case 75: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          Double dXMin = xmin();
          Double dXMax = xmax();
          Bool bCheck = checkX( dXMin, dXMax );
          Vector<Double> oX = Vector<Double>( 3 );
          oX(0) = (Double) bCheck;
          oX(1) = dXMin;
          oX(2) = dXMax;
          returnval() = oX;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "checkX( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // checkY
    case 76: {
      Parameter<Double> ymin( oParameters, "ymin", ParameterSet::In );
      Parameter<Double> ymax( oParameters, "ymax", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          Double dYMin = ymin();
          Double dYMax = ymax();
          Bool bCheck = checkY( dYMin, dYMax );
          Vector<Double> oY = Vector<Double>( 3 );
          oY(0) = (Double) bCheck;
          oY(1) = dYMin;
          oY(2) = dYMax;
          returnval() = oY;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "checkY( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // checkInterp
    case 77: {
      Parameter<String> interp( oParameters, "interp", ParameterSet::In );
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          String oInterp = interp();
          Bool bCheck = checkInterp( oInterp );
          Vector<String> oInterp2 = Vector<String>( 2 );
          oInterp2(0) = (String) bCheck;
          oInterp2(1) = oInterp;
          returnval() = oInterp2;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "checkInterp( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }

    // default
    default: {
      if ( bRunMethod ) {
        throw(
            ermsg( "Invalid GDC1Token{ } method", "GDC1Token", "runMethod" ) );
      }
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}
