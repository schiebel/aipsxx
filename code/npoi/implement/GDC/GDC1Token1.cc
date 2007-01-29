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
//# $Id: GDC1Token1.cc,v 19.0 2003/07/16 06:03:43 aips2adm Exp $
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

MethodResult GDC1Token::runMethod( uInt uiMethod, ParameterSet &oParameters,
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
              "GDC1Token", "runMethod" ) );
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
              "GDC1Token", "runMethod" ) );
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
              "GDC1Token", "runMethod" ) );
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
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          dumpASCII( file(), xmin(), xmax(), tokenarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "dumpASCII( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // yInterpolate
    case 4: {
      Parameter< Vector<Double> > xarg( oParameters, "xarg", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<String> interp( oParameters, "interp", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Double> xminbox( oParameters, "xminbox", ParameterSet::In );
      Parameter<Double> xmaxbox( oParameters, "xmaxbox", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = yInterpolate( xarg(), tokenarg(), keep(), interp(),
              xminbox(), xmaxbox() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yInterpolate( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }

    // length
    case 5: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) length( xmin(), xmax(), tokenarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "length( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // x
    case 6: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = x( xmin(), xmax(), tokenarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "x( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // y
    case 7: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> orig( oParameters, "orig", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = y( xmin(), xmax(), tokenarg(), keep(), orig() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "y( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // xErr
    case 8: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xErr( xmin(), xmax(), tokenarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xErr( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // yErr
    case 9: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> orig( oParameters, "orig", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = yErr( xmin(), xmax(), tokenarg(), keep(), orig() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yErr( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // xError
    case 10: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xError();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xError( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // yError
    case 11: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = yError();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yError( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // token
    case 12: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = token( xmin(), xmax(), tokenarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "token( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // tokenType
    case 13: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tokenType();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tokenType( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // tokenList
    case 14: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tokenList();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tokenList( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // flag
    case 15: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> orig( oParameters, "orig", ParameterSet::In );
      Parameter< Vector<Bool> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = flag( xmin(), xmax(), tokenarg(), orig() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "flag( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // interp
    case 16: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<Bool> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = interp( xmin(), xmax(), tokenarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "interp( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // index
    case 17: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter< Vector<Int> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          uInt uiIndex;
          Vector<Int> oIndex = index( xmin(), xmax(), tokenarg(), keep() );
          for ( uiIndex = 0; uiIndex < oIndex.nelements(); uiIndex++ ) {
            oIndex(uiIndex) += 1;
          }
          returnval() = oIndex;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "index( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // xMax
    case 18: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> plot( oParameters, "plot", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xMax( xmin(), xmax(), tokenarg(), keep(), plot() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xMax( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // xMin
    case 19: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> plot( oParameters, "plot", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xMin( xmin(), xmax(), tokenarg(), keep(), plot() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xMin( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // yMax
    case 20: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> plot( oParameters, "plot", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = yMax( xmin(), xmax(), tokenarg(), keep(), plot() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yMax( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // yMin
    case 21: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> plot( oParameters, "plot", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = yMin( xmin(), xmax(), tokenarg(), keep(), plot() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yMin( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // xErrMax
    case 22: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xErrMax( xmin(), xmax(), tokenarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xErrMax( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // xErrMin
    case 23: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xErrMin( xmin(), xmax(), tokenarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xErrMin( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // yErrMax
    case 24: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = yErrMax( xmin(), xmax(), tokenarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yErrMax( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // yErrMin
    case 25: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = yErrMin( xmin(), xmax(), tokenarg(), keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "yErrMin( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
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
