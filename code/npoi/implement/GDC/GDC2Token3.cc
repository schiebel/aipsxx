//#GDC2Token.cc is part of the GDC server
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
//# $Id: GDC2Token3.cc,v 19.0 2003/07/16 06:03:46 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

GDC2Token.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the GDC2Token{ } class member functions.

Public member functions:
------------------------
GDC2Token (4 versions), ~GDC2Token, addTokenColumn, changeX, checkColumn (2
versions), checkToken, checkX, checkY, columnList, columnNumber (2 versions),
columnType, dumpASCII, fileASCII, flag, flagged, fullSize, getArgCheck,
getColor, getColumn, getFlag, getKeep, getLine, getTitle, getToken, getXLabel,
getXMax, getXMin, getYLabel, getYMax, getYMin, history, hms, hmsOld, index (3
versions), interp, interpolated, length, numEvent, mean, meanErr, plot,
postScript, removeTokenColumn, resetHistory, resetX, setArgCheck, setColor,
setFlag, setFlagX, setFlagXY, setKeep, setLine, setTitle (2 versions),
setTitleDefault, setTokenColumn, setTokenColumnDefault, setXLabel, (2 versions)
setXLabelDefault, setYLabel (2 versions), setYLabelDefault, stdDev, token,
tokenList, tokenType, tool, undoHistory, variance, version, x, xErr, xErrMax,
xErrMin, xErrOld, xError, xMax, xMin, xOld, y, yErr, yErrMax, yErrMin, yError,
yMax, yMin, zoomx, zoomxy, zoomy.

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
2000 Sep 13 - Nicholas Elias, USNO/NPOI
              File created with public member functions GDC2Token( ) (null and
              standard versions) and ~GDC2Token( ).
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Public member functions fileASCII( ), getArgCheck( ), length( ),
              setArgCheck( ), x( ), and y( ) added.  Protected member function
              initialize( ) added.
2000 Dec 21 - Nicholas Elias, USNO/NPOI
              Public member functions checkToken( ), checkX( ), columnNumber( )
              (column IDs versions), and index( ) (column numbers and column IDs
              versions) added.
2000 Dec 29 - Nicholas Elias, USNO/NPOI
              Public member functions checkColumn( ) (column numbers and column
              IDs versions), tool( ), and version( ) added.
2000 Dec 30 - Nicholas Elias, USNO/NPOI
              Public member functions getXMin( ) and getXMax( ) added.
2001 Jan 02 - Nicholas Elias, USNO/NPOI
              Public member functions xErr( ), xError( ), yErr( ), and
              yError( ) added.
2001 Jan 03 - Nicholas Elias, USNO/NPOI
              Public member functions columnList( ), columnType( ), flag( ),
              token( ), tokenList( ), and tokenType( ) added.
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member functions xErrMax( ) (global and specific versions),
              xErrMin( ) (global and specific versions), xMax( ) (global and
              specific versions), xMin( ) (global and specific versions),
              yErrMax( ) (global and specific versions), yErrMin( ) (global and
              specific versions), yMax( ) (global and specific versions), and
              yMin( ) (global and specific versions).
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member functions checkY( ), columnNumber( ) (column ID
              version), flagged( ), fullSize( ), getKeep( ), getYMax( ),
              getYMin( ), history( ), hms( ), index( ) (column number version),
              interp( ), interpolated( ), numEvent( ), resetHistory( ),
              setFlagX( ), setFlagXY( ), setKeep( ), undoHistory( ), zoomx( ),
              zoomxy( ), and zoomy( ), added.
2001 Jan 08 - Nicholas Elias, USNO/NPOI
              Public member functions getColor( ), getFlag( ), getLine( ),
              getToken( ), setColor( ), setFlag( ), and setLine( ) added.
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member functions addTokenColumn( ), changeX( ),
              getColumn( ), getTitle( ), getXLabel( ), getYLabel( ), plot( ),
              postScript( ), removeTokenColumn( ), resetX( ), setTitle( )
              (default and arbitrary versions), setTitleDefault( ),
              setTokenColumn( ), setTokenColumnDefault( ), setXLabel( )
              (default and arbitrary versions), setXLabelDefault( ),
              setYLabel( ) (default and arbitrary versions), and
              setYLabelDefault( ) added.  Private member functions plotLine( )
              and plotPoints( ) added.
2001 Jan 10 - Nicholas Elias, USNO/NPOI
              Public member functions GDC2Token( ) (ASCII version) and
              dumpASCII( ) added.  Private member function loadASCII( ) added.
2001 Jan 16 - Nicholas Elias, USNO/NPOI
              Public member functions GDC2Token( ) (clone version) and clone( )
              added.
2001 Jan 17 - Nicholas Elias, USNO/NPOI
              Public member functions GDC2Token( ) (copy version), mean( ),
              meanErr( ), stdDev( ), and variance( ) added.
2001 Jan 31 - Nicholas Elias, USNO/NPOI
              Public member functions hmsOld( ), xErrOld( ), and xOld( ) added.
2001 Mar 23 - Nicholas Elias, USNO/NPOI
              Protected member function initializePlotAttrib( ) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/GDC/GDC2Token.h> // GDC2Token file

// -----------------------------------------------------------------------------

/*

GDC2Token::runMethod

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
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult GDC2Token::runMethod2( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {
    
    // addTokenColumn
    case 51: {
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          addTokenColumn( tokenarg(), columnarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "addTokenColumn( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // removeTokenColumn
    case 52: {
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          removeTokenColumn( tokenarg(), columnarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "removeTokenColumn( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
              "GDC2Token", "runMethod" ) );
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
          throw( ermsg( "hms( ) error\n" + oAipsError.getMesg(), "GDC2Token",
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
	  throw( ermsg( "id( ) error\n" + oAipsError.getMesg(), "GDC2Token",
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
              "GDC2Token", "runMethod" ) );
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
          throw( ermsg( "tool( ) error\n" + oAipsError.getMesg(), "GDC2fToken",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // checkColumn
    case 74: {
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          Vector<String> oColumn = columnarg();
          Bool bCheck = checkColumn( oColumn );
          uInt uiColumn;
          uInt uiNumColumn = oColumn.nelements();
          Vector<String> oColumn2 = Vector<String>( uiNumColumn + 1 );
          oColumn2(0) = (String) bCheck;
          for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
            oColumn2(uiColumn+1) = oColumn(uiColumn);
          }
          returnval() = oColumn2;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "checkColumn( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // checkToken
    case 75: {
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
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // checkX
    case 76: {
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
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // checkY
    case 77: {
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
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }

    // default
    default: {
      if ( bRunMethod ) {
        throw(
            ermsg( "Invalid GDC2Token{ } method", "GDC2Token", "runMethod" ) );
      }
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}
