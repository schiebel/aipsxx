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
//# $Id: GDC1Token2.cc,v 19.0 2003/07/16 06:03:44 aips2adm Exp $
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

MethodResult GDC1Token::runMethod1( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {
    
    // flagged
    case 26: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<Int> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          uInt uiIndex;
          Vector<Int> oIndex = flagged( xmin(), xmax(), tokenarg() );
          for ( uiIndex = 0; uiIndex < oIndex.nelements(); uiIndex++ ) {
            oIndex(uiIndex) += 1;
          }
          returnval() = oIndex;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "flagged( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // interpolated
    case 27: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter< Vector<Int> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          uInt uiIndex;
          Vector<Int> oIndex = interpolated( xmin(), xmax(), tokenarg() );
          for ( uiIndex = 0; uiIndex < oIndex.nelements(); uiIndex++ ) {
            oIndex(uiIndex) += 1;
          }
          returnval() = oIndex;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "interpolated( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // mean
    case 28: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> weight( oParameters, "weight", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = mean( xmin(), xmax(), tokenarg(), keep(), weight() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "mean( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // meanErr
    case 29: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> weight( oParameters, "weight", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = meanErr( xmin(), xmax(), tokenarg(), keep(), weight() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "meanErr( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // stdDev
    case 30: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> weight( oParameters, "weight", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = stdDev( xmin(), xmax(), tokenarg(), keep(), weight() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "stdDev( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // variance
    case 31: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<Bool> weight( oParameters, "weight", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() =
              variance( xmin(), xmax(), tokenarg(), keep(), weight() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "variance( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setFlagX
    case 32: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> flagarg( oParameters, "flagarg", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setFlagX( xmin(), xmax(), tokenarg(), flagarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setFlagX( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setFlagXY
    case 33: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter<Double> ymin( oParameters, "ymin", ParameterSet::In );
      Parameter<Double> ymax( oParameters, "ymax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> flagarg( oParameters, "flagarg", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setFlagXY( xmin(), xmax(), ymin(), ymax(), tokenarg(), flagarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setFlagXY( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // interpolateX
    case 34: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<String> interp( oParameters, "interp", ParameterSet::In );
      Parameter<Double> xminbox( oParameters, "xminbox", ParameterSet::In );
      Parameter<Double> xmaxbox( oParameters, "xmaxbox", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          interpolateX( xmin(), xmax(), tokenarg(), keep(), interp(),
              xminbox(), xmaxbox() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "interpolateX( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // interpolateXY
    case 35: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      Parameter<String> interp( oParameters, "interp", ParameterSet::In );
      Parameter<Double> ymin( oParameters, "ymin", ParameterSet::In );
      Parameter<Double> ymax( oParameters, "ymax", ParameterSet::In );
      Parameter<Double> xminbox( oParameters, "xminbox", ParameterSet::In );
      Parameter<Double> xmaxbox( oParameters, "xmaxbox", ParameterSet::In );
      Parameter<Double> yminbox( oParameters, "yminbox", ParameterSet::In );
      Parameter<Double> ymaxbox( oParameters, "ymaxbox", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          interpolateXY( xmin(), xmax(), tokenarg(), keep(), interp(),
              ymin(), ymax(), xminbox(), xmaxbox(), yminbox(), ymaxbox() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "interpolateXY( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // undoHistory
    case 36: {
      if ( bRunMethod ) {
        try {
          undoHistory();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "undoHistory( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // resetHistory
    case 37: {
      if ( bRunMethod ) {
        try {
          resetHistory();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "resetHistory( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }

    // numEvent
    case 38: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) numEvent();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "numEvent( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }

    // postScript
    case 39: {
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
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getXMin
    case 40: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getXMin( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getXMin( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getXMax
    case 41: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getXMax( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getXMax( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getYMin
    case 42: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getYMin( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getYMin( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getYMax
    case 43: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getYMax( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getYMax( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // zoomx
    case 44: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          zoomx( xmin(), xmax() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "zoomx( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // zoomy
    case 45: {
      Parameter<Double> ymin( oParameters, "ymin", ParameterSet::In );
      Parameter<Double> ymax( oParameters, "ymax", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          zoomy( ymin(), ymax() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "zoomy( ) error\n" + oAipsError.getMesg(), "GDC1Token",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // zoomxy
    case 46: {
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
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // fullSize
    case 47: {
      if ( bRunMethod ) {
        try {
          fullSize();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "fullSize( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // getToken
    case 48: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getToken();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getToken( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setToken
    case 49: {
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setToken( tokenarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setToken( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
        }
      }
      break;
    }
    
    // setTokenDefault
    case 50: {
      if ( bRunMethod ) {
        try {
          setTokenDefault();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setTokenDefault( ) error\n" + oAipsError.getMesg(),
              "GDC1Token", "runMethod" ) );
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
