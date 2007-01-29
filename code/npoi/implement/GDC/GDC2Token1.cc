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
//# $Id: GDC2Token1.cc,v 19.0 2003/07/16 06:03:45 aips2adm Exp $
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

MethodResult GDC2Token::runMethod( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {
    
    // fileASCII
    case 0: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = fileASCII();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "fileASCII( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getArgCheck
    case 1: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getArgCheck();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getArgCheck( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setArgCheck
    case 2: {
      Parameter<Bool> check( oParameters, "check", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setArgCheck( check() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setArgCheck( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }

    // dumpASCII
    case 3: {
      Parameter<String> file( oParameters, "file", ParameterSet::In );
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          dumpASCII( file(), xmin(), xmax(), tokenarg(), columnarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "dumpASCII( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }

    // length
    case 4: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() =
              (Int) length( xmin(), xmax(), tokenarg(), columnarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "length( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // x
    case 5: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = x( xmin(), xmax(), tokenarg(), columnarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "x( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // y
    case 6: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> orig( oParameters, "orig", ParameterSet::In );
      Parameter< Array<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = Array<Double>(
              y( xmin(), xmax(), tokenarg(), columnarg(), keep(), orig() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "y( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // xErr
    case 7: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xErr( xmin(), xmax(), tokenarg(), columnarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xErr( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // yErr
    case 8: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> orig( oParameters, "orig", ParameterSet::In );
      Parameter< Array<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = Array<Double>(
              yErr( xmin(), xmax(), tokenarg(), columnarg(), keep(), orig() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yErr( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // xError
    case 9: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xError();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xError( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // yError
    case 10: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = yError();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yError( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // token
    case 11: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = token( xmin(), xmax(), tokenarg(), columnarg(),
              keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "token( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // tokenType
    case 12: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tokenType();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tokenType( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // tokenList
    case 13: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tokenList();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tokenList( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // columnType
    case 14: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = columnType();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "columnType( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // columnList
    case 15: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = columnList();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "columnList( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // flag
    case 16: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> orig( oParameters, "orig", ParameterSet::In );
      Parameter< Array<Bool> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = Array<Bool>(
              flag( xmin(), xmax(), tokenarg(), columnarg(), orig() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "flag( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // interp
    case 17: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter< Array<Bool> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() =
              Array<Bool>( interp( xmin(), xmax(), tokenarg(), columnarg() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "interp( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // index
    case 18: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter< Vector<Int> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          uInt uiIndex;
          Vector<Int> oIndex =
              index( xmin(), xmax(), tokenarg(), columnarg(), keep() );
          for ( uiIndex = 0; uiIndex < oIndex.nelements(); uiIndex++ ) {
            oIndex(uiIndex) += 1;
          }
          returnval() = oIndex;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "index( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // xMax
    case 19: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> plot( oParameters, "plot", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() =
              xMax( xmin(), xmax(), tokenarg(), columnarg(), keep(), plot() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xMax( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // xMin
    case 20: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> plot( oParameters, "plot", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() =
              xMin( xmin(), xmax(), tokenarg(), columnarg(), keep(), plot() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xMin( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // yMax
    case 21: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> plot( oParameters, "plot", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() =
              yMax( xmin(), xmax(), tokenarg(), columnarg(), keep(), plot() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yMax( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // yMin
    case 22: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<String> >
          columnarg( oParameters, "columnarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> plot( oParameters, "plot", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() =
              yMin( xmin(), xmax(), tokenarg(), columnarg(), keep(), plot() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yMin( ) error\n" + oAipsError.getMesg(), "GDC2Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // xErrMax
    case 23: {
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
              xErrMax( xmin(), xmax(), tokenarg(), columnarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xErrMax( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // xErrMin
    case 24: {
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
              xErrMin( xmin(), xmax(), tokenarg(), columnarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xErrMin( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // yErrMax
    case 25: {
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
              yErrMax( xmin(), xmax(), tokenarg(), columnarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yErrMax( ) error\n" + oAipsError.getMesg(),
              "GDC2Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // default
    default: {
      return runMethod1( uiMethod, oParameters, bRunMethod );
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}
