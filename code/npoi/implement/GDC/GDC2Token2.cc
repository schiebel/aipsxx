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
//# $Id: GDC2Token2.cc,v 19.0 2003/07/16 06:03:45 aips2adm Exp $
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

GDC2Token::GDC2Token (null)

Description:
------------
This public member function constructs a GDC2Token{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Sep 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

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

MethodResult GDC2Token::runMethod1( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {
    
    // yErrMin
    case 26: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() =
              yErrMin( xmin(), xmax(), tokenarg(), columnarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yErrMin( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // flagged
    case 27: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<String> columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter< Vector<Int> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          uInt uiIndex;
          Vector<Int> oIndex =
              flagged( xmin(), xmax(), tokenarg(), columnarg() );
          for ( uiIndex = 0; uiIndex < oIndex.nelements(); uiIndex++ ) {
            oIndex(uiIndex) += 1;
          }
          returnval() = oIndex;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "flagged( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // interpolated
    case 28: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<String> columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter< Vector<Int> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          uInt uiIndex;
          Vector<Int> oIndex =
              interpolated( xmin(), xmax(), tokenarg(), columnarg() );
          for ( uiIndex = 0; uiIndex < oIndex.nelements(); uiIndex++ ) {
            oIndex(uiIndex) += 1;
          }
          returnval() = oIndex;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "interpolated( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // mean
    case 29: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> weight( oParameters, "weight", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = mean( xmin(), xmax(), tokenarg(), columnarg(), keep(),
              weight() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "mean( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // meanErr
    case 30: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> weight( oParameters, "weight", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = meanErr( xmin(), xmax(), tokenarg(), columnarg(),
              keep(), weight() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "meanErr( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // stdDev
    case 31: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> weight( oParameters, "weight", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = stdDev( xmin(), xmax(), tokenarg(), columnarg(),
              keep(), weight() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "stdDev( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // variance
    case 32: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> weight( oParameters, "weight", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = variance( xmin(), xmax(), tokenarg(), columnarg(),
              keep(), weight() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "variance( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setFlagX
    case 33: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> flagarg( oParameters, "flagarg", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setFlagX( xmin(), xmax(), tokenarg(), columnarg(), flagarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setFlagX( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setFlagXY
    case 34: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter<Double> ymin( oParameters, "ymin", ParameterSet::In );
      Parameter<Double> ymax( oParameters, "ymax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> flagarg( oParameters, "flagarg", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setFlagXY( xmin(), xmax(), ymin(), ymax(), tokenarg(), columnarg(),
              flagarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setFlagXY( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // undoHistory
    case 35: {
      if ( bRunMethod ) {
        try {
          undoHistory();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "undoHistory( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // resetHistory
    case 36: {
      if ( bRunMethod ) {
        try {
          resetHistory();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "resetHistory( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }

    // numEvent
    case 37: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) numEvent();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "numEvent( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }

    // postScript
    case 38: {
      Parameter<String> file( oParameters, "file", ParameterSet::In );
      Parameter<String> device( oParameters, "device", ParameterSet::In );
      Parameter<Bool> trans( oParameters, "trans", ParameterSet::In );
      Parameter< Vector<Int> > ci( oParameters, "ci", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          postScript( file(), device(), trans(), ci() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "postScript( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getXMin
    case 39: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getXMin( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getXMin( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getXMax
    case 40: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getXMax( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getXMax( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getYMin
    case 41: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getYMin( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getYMin( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getYMax
    case 42: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getYMax( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getYMax( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // zoomx
    case 43: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          zoomx( xmin(), xmax() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "zoomx( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // zoomy
    case 44: {
      Parameter<Double> ymin( oParameters, "ymin", ParameterSet::In );
      Parameter<Double> ymax( oParameters, "ymax", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          zoomy( ymin(), ymax() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "zoomy( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // zoomxy
    case 45: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter<Double> ymin( oParameters, "ymin", ParameterSet::In );
      Parameter<Double> ymax( oParameters, "ymax", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          zoomxy( xmin(), xmax(), ymin(), ymax() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "zoomxy( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // fullSize
    case 46: {
      if ( bRunMethod ) {
        try {
          fullSize();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "fullSize( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getToken
    case 47: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getToken();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getToken( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getColumn
    case 48: {
      Parameter<String> tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getColumn( tokenarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getColumn( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setTokenColumn
    case 49: {
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setTokenColumn( tokenarg(), columnarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setTokenColumn( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setTokenColumnDefault
    case 50: {
      if ( bRunMethod ) {
        try {
          setTokenColumnDefault();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg(
              "setTokenColumnDefault( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // default
    default: {
      return runMethod2( uiMethod, oParameters, bRunMethod );
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}
