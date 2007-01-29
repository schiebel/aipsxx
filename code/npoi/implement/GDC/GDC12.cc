//#GDC1.cc is part of the GDC server
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
//# $Id: GDC12.cc,v 19.0 2003/07/16 06:03:42 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

GDC1.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the GDC1{ } class member functions.

Public member functions:
------------------------
GDC1 (7 versions), ~GDC1, average, changeX, checkInterp, checkX, checkY, clone,
dumpASCII, fileASCII, flag, flagged, fullSize, getArgCheck, getFlag, getKeep,
getLine, getTitle, getXLabel, getXMax, getXMin, getYLabel, getYMax, getYMin,
history, hms, hmsOld, index, interp, interpolate, interpolated, interpolateX,
interpolateXY, length, mean, meanerr, numEvent, plot, postScript, resetHistory,
resetX, setArgCheck, setFlag, setFlagX, setFlagXY, setKeep, setLine, setTitle
(2 versions), setTitleDefault, setXLabel (2 versions), setXLabelDefault,
setYLabel (2 versions), setYLabelDefault, stddev, tool, variance, version, x,
xErr, xErrMax (2 versions), xErrMin (2 versions), xErrOld, xError, xMax (2
versions), xMin (2 versions), xOld, y, yErr, yErrMax (2 versions), yErrMin (2
versions), yError, yInterpolate, yMax (2 versions), yMin (2 versions), zoomx,
zoomy, zoomxy.

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
              File created with public member functions GDC1( ) (standard and
              copy versions) and ~GDC1( ).
2000 Apr 28 - Nicholas Elias, USNO/NPOI
              Public member functions length( ), x( ), and index( ) added.
2000 May 01 - Nicholas Elias, USNO/NPOI Public member functions y( ), xErr( ),
              yErr( ), xError( ), yError( ), flag( ), xMax( ) (global and
              specific versions), xMin( ) (global and specific versions),
              yMax( ) (specific version), yMin( ) (specific version),
              xErrMax( ) (specific version), xErrMin( ) (specific version),
              yErrMax( ) (specific version), yErrMin( ) (specific version),
              flagged( ), mean( ), meanErr( ), stdDev( ), variance( ),
              version( ).
2000 May 07 - Nicholas Elias, USNO/NPOI
              Public member functions checkX( ), resetHistory( ), setFlagX( ),
              setFlagXY( ), and undoHistory( ) added.
2000 Jun 02 - Nicholas Elias, USNO/NPOI
              Public member function zoomxy( ) added.
2000 Jun 05 - Nicholas Elias, USNO/NPOI
              Public member functions plot( ) and postScript( ) added.
2000 Jun 07 - Nicholas Elias, USNO/NPOI Public member functions GDC1( ) (ASCII
              version), getXMin( ), getXMax( ), getYMin( ), getYMax( ),
              fillSize( ), getLine( ), setLine( ), getKeep( ), setKeep( ),
              getXLabel( ), setXLabel( ) (default and arbitrary versions),
              setXLabelDefault( ), getYLabel( ), setYLabel( ) (default and
              arbitrary versions), setYLabelDefault( ), getTitle( ),
              setTitle( ) (default and arbitrary versions), and
              setTitleDefault( ) added.  Protected member function
              initialize( ) added.  Private member function loadASCII( ) added.
2000 Jun 08 - Nicholas Elias, USNO/NPOI
              Public member functions checkY( ), dumpASCII( ), getArgCheck( ),
              history( ), and setArgCheck( ) added.
2000 Jun 13 - Nicholas Elias, USNO/NPOI
              Public member functions getFlag( ) and setFlag( ) added.  Public
              member function setKeep( ) modified.
2000 Jun 19 - Nicholas Elias, USNO/NPOI
              Public member function numEvent( ) added.
2000 Jun 21 - Nicholas Elias, USNO/NPOI
              Public member functions GDC1( ) (clone version) and clone( )
              added.
2000 Jun 27 - Nicholas Elias, USNO/NPOI
              Public member functions GDC1( ) (average and interpolate
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
              Public member functions zoomx( ) and zoomy( ) added.
2000 Jul 11 - Nicholas Elias, USNO/NPOI
              Public member function GDC1( ) (null version) added.
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

#include <npoi/GDC/GDC1.h> // GDC1 file

// -----------------------------------------------------------------------------

/*

GDC1::runMethod

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

MethodResult GDC1::runMethod1( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {
    
    // resetHistory
    case 34: {
      if ( bRunMethod ) {
        try {
          resetHistory();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "resetHistory( ) error\n" + oAipsError.getMesg(),
              "GDC1", "runMethod" ) );
        }
      }
      break;
    }

    // numEvent
    case 35: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) numEvent();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "numEvent( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }

    // postScript
    case 36: {
      Parameter<String> file( oParameters, "file", ParameterSet::In );
      Parameter<String> device( oParameters, "device", ParameterSet::In );
      Parameter<Bool> trans( oParameters, "trans", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          postScript( file(), device(), trans() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "postScript( ) error\n" + oAipsError.getMesg(),
              "GDC1", "runMethod" ) );
        }
      }
      break;
    }
    
    // getXMin
    case 37: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getXMin( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getXMin( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // getXMax
    case 38: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getXMax( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getXMax( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // getYMin
    case 39: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getYMin( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getYMin( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // getYMax
    case 40: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<Double>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getYMax( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getYMax( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // zoomx
    case 41: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          zoomx( xmin(), xmax() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "zoomx( ) error\n" + oAipsError.getMesg(), "GDC1",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // zoomy
    case 42: {
      Parameter<Double> ymin( oParameters, "ymin", ParameterSet::In );
      Parameter<Double> ymax( oParameters, "ymax", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          zoomy( ymin(), ymax() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "zoomy( ) error\n" + oAipsError.getMesg(), "GDC1",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // zoomxy
    case 43: {
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter<Double> ymin( oParameters, "ymin", ParameterSet::In );
      Parameter<Double> ymax( oParameters, "ymax", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          zoomxy( xmin(), xmax(), ymin(), ymax() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "zoomxy( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // fullSize
    case 44: {
      if ( bRunMethod ) {
        try {
          fullSize();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "fullSize( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // getFlag
    case 45: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getFlag();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getFlag( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // setFlag
    case 46: {
      Parameter<Bool> flag( oParameters, "flag", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setFlag( flag() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setFlag( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // getLine
    case 47: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getLine();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getLine( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // setLine
    case 48: {
      Parameter<Bool> line( oParameters, "line", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setLine( line() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setLine( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // getKeep
    case 49: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getKeep();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getKeep( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // setKeep
    case 50: {
      Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setKeep( keep() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setKeep( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // getXLabel
    case 51: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getXLabel( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getXLabel( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // setXLabel
    case 52: {
      Parameter<String> xlabel( oParameters, "xlabel", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setXLabel( xlabel() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setXLabel( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // setXLabelDefault
    case 53: {
      Parameter<String> xlabel( oParameters, "xlabel", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setXLabelDefault( xlabel() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setXLabelDefault( ) error\n" + oAipsError.getMesg(),
              "GDC1", "runMethod" ) );
        }
      }
      break;
    }
    
    // getYLabel
    case 54: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getYLabel( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getYLabel( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // setYLabel
    case 55: {
      Parameter<String> ylabel( oParameters, "ylabel", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setYLabel( ylabel() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setYLabel( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // setYLabelDefault
    case 56: {
      Parameter<String> ylabel( oParameters, "ylabel", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setYLabelDefault( ylabel() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setYLabelDefault( ) error\n" + oAipsError.getMesg(),
              "GDC1", "runMethod" ) );
        }
      }
      break;
    }
    
    // getTitle
    case 57: {
      Parameter<Bool> def( oParameters, "default", ParameterSet::In );
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getTitle( def() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getTitle( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // setTitle
    case 58: {
      Parameter<String> title( oParameters, "title", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setTitle( title() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setTitle( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // setTitleDefault
    case 59: {
      Parameter<String> title( oParameters, "title", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setTitleDefault( title() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setTitleDefault( ) error\n" + oAipsError.getMesg(),
              "GDC1", "runMethod" ) );
        }
      }
      break;
    }

    // hms
    case 60: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = hms();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "hms( ) error\n" + oAipsError.getMesg(), "GDC1",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // id    
    case 61: {
      Parameter<ObjectID> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
	  returnval() = id();
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "id( ) error\n" + oAipsError.getMesg(), "GDC1",
	      "runMethod" ) );
	}
      }
      break;
    }

    // version
    case 62: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = version();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "version( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }

    // tool
    case 63: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tool();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tool( ) error\n" + oAipsError.getMesg(), "GDC1",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // checkX
    case 64: {
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
              "GDC1", "runMethod" ) );
        }
      }
      break;
    }
    
    // checkY
    case 65: {
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
          throw( ermsg( "checkY( ) error\n" + oAipsError.getMesg(), "GDC1",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // checkInterp
    case 66: {
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
              "GDC1", "runMethod" ) );
        }
      }
      break;
    }

    // default
    default: {
      if ( bRunMethod ) {
        throw( ermsg( "Invalid GDC1{ } method", "GDC1", "runMethod" ) );
      }
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}
