//#GDC1.cc is part of the GDC server
//#Copyright (C) 2000,2001,2002
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
//# $Id: GDC1.cc,v 19.0 2003/07/16 06:03:29 aips2adm Exp $
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

GDC1::GDC1 (null)

Description:
------------
This public member function constructs a GDC1{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jul 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1::GDC1( void ) : GeneralStatus(), poFileASCII( NULL ) {}

// -----------------------------------------------------------------------------

/*

GDC1::GDC1 (standard)

Description:
------------
This public member function constructs a GDC1{ } object.

Inputs:
-------
oXin    - The x vector.
oYIn    - The y vector.
oXErrIn - The x error vector. If no x errors, then the vector length should be
          0.
oYErrIn - The y error vector. If no y errors, then the vector length should be
          0.
oFlagIn - The flag vector. If no flags, then the vector length should be 0.
bHMSIn  - The HH:MM:SS boolean (default = False);

Outputs:
--------
None.

Modification history:
---------------------
2000 Apr 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1::GDC1( const Vector<Double>& oXIn, const Vector<Double>& oYIn,
    const Vector<Double>& oXErrIn, const Vector<Double>& oYErrIn,
    const Vector<Bool>& oFlagIn, const Bool& bHMSIn ) : GeneralStatus(),
    poFileASCII( NULL ) {
  
  // Initialize the private variables
  
  try {
    initialize( oXIn, oYIn, oXErrIn, oYErrIn, oFlagIn );
    String oXLabel = String( "X Axis" );
    String oYLabel = String( "Y Axis" );
    String oTitle = String( "Title" );
    initializePlotAttrib( bHMSIn, oXLabel, oYLabel, oTitle, oXLabel, oYLabel,
        oTitle );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC1{ } object\n" + oAipsError.getMesg(),
        "GDC1", "GDC1" ) );
  }
  
  
  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::GDC1 (ASCII)

Description:
------------
This public member function constructs a GDC1{ } object.

Inputs:
-------
oFileIn - The ASCII file.
bHMSIn  - The HH:MM:SS boolean (default = False);

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1::GDC1( String& oFileIn, const Bool& bHMSIn ) : GeneralStatus(),
    poFileASCII( NULL ) {

  // Allocate the memory

  Vector<Double> oXIn = Vector<Double>();
  Vector<Double> oYIn = Vector<Double>();
  Vector<Double> oXErrIn = Vector<Double>();
  Vector<Double> oYErrIn = Vector<Double>();
  
  Vector<Bool> oFlagIn = Vector<Bool>();

  
  // Load the data from the ASCII file
  
  try {
    loadASCII( oFileIn, oXIn, oYIn, oXErrIn, oYErrIn, oFlagIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot load data from ASCII file\n" + oAipsError.getMesg(),
        "GDC1", "GDC1" ) );
  }
  
  
  // Initialize the private variables

  try {
    initialize( oXIn, oYIn, oXErrIn, oYErrIn, oFlagIn );
    String oXLabel = String( "X Axis" );
    String oYLabel = String( "Y Axis" );
    String oTitle = String( "Title" );
    initializePlotAttrib( bHMSIn, oXLabel, oYLabel, oTitle, oXLabel, oYLabel,
        oTitle );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC1{ } object\n" + oAipsError.getMesg(),
        "GDC1", "GDC1" ) );
  }


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::GDC1 (clone)

Description:
------------
This public member function constructs a GDC1{ } object.

Inputs:
-------
oObjectIDIn - The ObjectID.
dXMinIn     - The minimum x value.
dXMaxIn     - The maximum x value.
bKeepIn     - The keep-flagged-data boolean.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 21 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1::GDC1( const ObjectID& oObjectIDIn, Double& dXMinIn, Double& dXMaxIn,
    const Bool& bKeepIn ) : GeneralStatus(), poFileASCII( NULL ) {
  
  // Get the pointer to the input GDC1{ } object

  ObjectController* poObjectController = NULL;
  GDC1* poGDC1In = NULL;
  
  try {
    poObjectController = ApplicationEnvironment::objectController();
    poGDC1In = (GDC1*) poObjectController->getObject( oObjectIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    String oError = "Cannot get pointer for input GDC1{ } object\n";
    oError += oAipsError.getMesg();
    throw( ermsg( oError, "GDC1", "GDC1" ) );
  }
  
  
  // Initialize this object
  
  GDC1* poGDC1Clone = NULL; // Keep compiler happy

  try {
    poGDC1Clone = poGDC1In->clone( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not clone data\n" + oAipsError.getMesg(), "GDC1",
        "GDC1" ) );
  }
  
  poFileASCII = new String( poGDC1In->fileASCII() );

  try {
    initialize(
        poGDC1Clone->x( dXMinIn, dXMaxIn, True ),
        poGDC1Clone->y( dXMinIn, dXMaxIn, True, False ),
        poGDC1Clone->xErr( dXMinIn, dXMaxIn, True ),
        poGDC1Clone->yErr( dXMinIn, dXMaxIn, True, False ),
        poGDC1Clone->flag( dXMinIn, dXMaxIn, False ) );
    initializePlotAttrib( poGDC1Clone->hms(), poGDC1In->getXLabel( False ),
        poGDC1In->getYLabel( False ), poGDC1In->getTitle( False ),
        poGDC1In->getXLabel( True ), poGDC1In->getYLabel( True ),
        poGDC1In->getTitle( True ) );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC1{ } object\n" + oAipsError.getMesg(),
        "GDC1", "GDC1" ) );
  }
  
  
  // Deallocate the memory
  
  delete poGDC1Clone;


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::GDC1 (average)

Description:
------------
This public member function constructs a GDC1{ } object.

Inputs:
-------
oObjectIDIn - The ObjectID.
oXIn        - The x vector.
dXMinIn     - The minimum x value.
dXMaxIn     - The maximum x value.
bKeepIn     - The keep-flagged-data boolean.
bWeightIn   - The weight boolean.
bXCalcIn    - The recalculate-x boolean.
oInterpIn   - The interpolation method ("CUBIC", "LINEAR", "NEAREST", "SPLINE").

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1::GDC1( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
    Double& dXMinIn, Double& dXMaxIn, const Bool& bKeepIn,
    const Bool& bWeightIn, const Bool& bXCalcIn, String& oInterpIn )
    : GeneralStatus(), poFileASCII( NULL ) {
  
  // Get the pointer to the input GDC1{ } object
  
  ObjectController* poObjectController = NULL;
  GDC1* poGDC1In = NULL;
  
  try {
    poObjectController = ApplicationEnvironment::objectController();
    poGDC1In = (GDC1*) poObjectController->getObject( oObjectIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    String oError = "Cannot get pointer for input GDC1{ } object\n";
    oError += oAipsError.getMesg();
    throw( ermsg( oError, "GDC1", "GDC1" ) );
  }
  
  
  // Initialize this object
  
  GDC1* poGDC1Ave = NULL;
  
  try {
    poGDC1Ave = poGDC1In->average( oXIn, dXMinIn, dXMaxIn, bKeepIn, bWeightIn,
        bXCalcIn, oInterpIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not average data\n" + oAipsError.getMesg(), "GDC1",
        "GDC1" ) );
  }
  
  poFileASCII = new String( poGDC1In->fileASCII() );

  try {
    initialize(
        poGDC1Ave->x( dXMinIn, dXMaxIn, True ),
        poGDC1Ave->y( dXMinIn, dXMaxIn, True, False ),
        poGDC1Ave->xErr( dXMinIn, dXMaxIn, True ),
        poGDC1Ave->yErr( dXMinIn, dXMaxIn, True, False ),
        poGDC1Ave->flag( dXMinIn, dXMaxIn, False ) );
    initializePlotAttrib( poGDC1Ave->hms(), poGDC1In->getXLabel( False ),
        poGDC1In->getYLabel( False ), poGDC1In->getTitle( False ),
        poGDC1In->getXLabel( True ), poGDC1In->getYLabel( True ),
        poGDC1In->getTitle( True ) );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC1{ } object\n" + oAipsError.getMesg(),
        "GDC1", "GDC1" ) );
  }
  
  
  // Deallocate the memory
  
  delete poGDC1Ave;


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::GDC1 (interpolate)

Description:
------------
This public member function constructs a GDC1{ } object.

Inputs:
-------
oObjectIDIn - The ObjectID.
oXIn        - The x vector.
bKeepIn     - The keep-flagged-data boolean.
oInterpIn   - The interpolation method ("CUBIC", "LINEAR", "NEAREST", "SPLINE").
dXMinBoxIn  - The minimum x-box value.
dXMaxBoxIn  - The maximum x-box value.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1::GDC1( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
    const Bool& bKeepIn, String& oInterpIn, Double& dXMinBoxIn,
    Double& dXMaxBoxIn ) : GeneralStatus(), poFileASCII( NULL ) {
    
  // Sort the input x values and get the interpolation region limits
  
  Vector<Double> oX = oXIn;
  Vector<Int> oSortKey = StatToolbox::sortkey( oX );
  StatToolbox::sort( oSortKey, oX );
  
  Double dXMinIn = oX(0);
  Double dXMaxIn = oX(oX.nelements()-1);
  
  
  // Get the pointer to the input GDC1{ } object
  
  ObjectController* poObjectController = NULL;
  GDC1* poGDC1In = NULL;
  
  try {
    poObjectController = ApplicationEnvironment::objectController();
    poGDC1In = (GDC1*) poObjectController->getObject( oObjectIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    String oError = "Cannot get pointer for input GDC1{ } object\n";
    oError += oAipsError.getMesg();
    throw( ermsg( oError, "GDC1", "GDC1" ) );
  }
  
  
  // Initialize this object
  
  GDC1* poGDC1Interp = NULL; // Keep compiler happy

  try {
    poGDC1Interp = poGDC1In->interpolate( oX, bKeepIn, oInterpIn, dXMinBoxIn,
        dXMaxBoxIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not interpolate data\n" + oAipsError.getMesg(),
        "GDC1", "GDC1" ) );
  }
  
  poFileASCII = new String( poGDC1In->fileASCII() );

  try {
    initialize(
        poGDC1Interp->x( dXMinIn, dXMaxIn, True ),
        poGDC1Interp->y( dXMinIn, dXMaxIn, True, False ),
        poGDC1Interp->xErr( dXMinIn, dXMaxIn, True ),
        poGDC1Interp->yErr( dXMinIn, dXMaxIn, True, False ),
        poGDC1Interp->flag( dXMinIn, dXMaxIn, False ) );
    initializePlotAttrib( poGDC1Interp->hms(), poGDC1In->getXLabel( False ),
        poGDC1In->getYLabel( False ), poGDC1In->getTitle( False ),
        poGDC1In->getXLabel( True ), poGDC1In->getYLabel( True ),
        poGDC1In->getTitle( True ) );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC1{ } object\n" + oAipsError.getMesg(),
        "GDC1", "GDC1" ) );
  }
  
  
  // Deallocate the memory
  
  delete poGDC1Interp;


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::GDC1 (copy)

Description:
------------
This public member function copies a GDC1{ } object.

Inputs:
-------
oGDC1In - The GDC1{ } object.

Outputs:
--------
None.

Modification history:
---------------------
2000 Apr 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1::GDC1( const GDC1& oGDC1In ) : GeneralStatus(), poFileASCII( NULL ) {
  
  // Initialize the private variables
  
  poFileASCII = new String( oGDC1In.fileASCII() );
  
  Double dXMin = oGDC1In.xMin( False );
  Double dXMax = oGDC1In.xMax( False );
  
  poXOld = new Vector<Double>( oGDC1In.xOld().copy() );
  poX = new Vector<Double>( oGDC1In.x( dXMin, dXMax, True ).copy() );
  
  poYOrig = new Vector<Double>( oGDC1In.y( dXMin, dXMax, True, True ).copy() );
  poY = new Vector<Double>( oGDC1In.y( dXMin, dXMax, True, False ).copy() );
  
  poXErrOld = new Vector<Double>( oGDC1In.xErrOld().copy() );
  poXErr = new Vector<Double>( oGDC1In.xErr( dXMin, dXMax, True ).copy() );
  
  poYErrOrig = new Vector<Double>(
      oGDC1In.yErr( dXMin, dXMax, True, True ).copy() );
  poYErr = new Vector<Double>(
      oGDC1In.yErr( dXMin, dXMax, True, False ).copy() );

  poFlagOrig = new Vector<Bool>( oGDC1In.flag( dXMin, dXMax, True ).copy() );
  poFlag = new Vector<Bool>( oGDC1In.flag( dXMin, dXMax, False ).copy() );
  
  poInterp = new Vector<Bool>( oGDC1In.interp( dXMin, dXMax ).copy() );
  
  bXError = oGDC1In.xError();
  bYError = oGDC1In.yError();
  
  bHMSOld = oGDC1In.hmsOld();
  bHMS = oGDC1In.hms();
  
  oGDC1In.history( &poHistoryEvent, &poHistoryIndex, &poHistoryFlag,
      &poHistoryInterp, &poHistoryY, &poHistoryYErr );
    
  dXMinDefault = oGDC1In.getXMin( True );
  dXMaxDefault = oGDC1In.getXMax( True );
  dYMinDefault = oGDC1In.getYMin( True );
  dYMaxDefault = oGDC1In.getYMax( True );
  
  Double dXMinTemp = oGDC1In.getXMin();
  Double dXMaxTemp = oGDC1In.getXMax();
  Double dYMinTemp = oGDC1In.getYMin();
  Double dYMaxTemp = oGDC1In.getYMax();
  
  zoomxy( dXMinTemp, dXMaxTemp, dYMinTemp, dYMaxTemp );

  bFlag = oGDC1In.getFlag();  
  bLine = oGDC1In.getLine();
  bKeep = oGDC1In.getKeep();
  
  poXLabelDefault = new String( oGDC1In.getXLabel( True ) );
  poYLabelDefault = new String( oGDC1In.getYLabel( True ) );
  poTitleDefault = new String( oGDC1In.getTitle( True ) );
  
  poXLabel = new String( oGDC1In.getXLabel() );
  poYLabel = new String( oGDC1In.getYLabel() );
  poTitle = new String( oGDC1In.getTitle() );
    
  poXLabelDefaultOld = new String( *poXLabelDefault );
  poXLabelOld = new String( *poXLabel );

  bArgCheck = oGDC1In.getArgCheck();
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::~GDC1

Description:
------------
This public member function destructs a GDC1{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Apr 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1::~GDC1( void ) {

  // Deallocate the memory and return

  delete poFileASCII;

  delete poXOld;
  delete poX;
  
  delete poYOrig;
  delete poY;
  
  delete poXErr;
  delete poXErrOld;
  
  delete poYErrOrig;
  delete poYErr;
  
  delete poFlagOrig;
  delete poFlag;

  delete poHistoryEvent;
  delete poHistoryIndex;
  delete poHistoryFlag;
  delete poHistoryInterp;
  delete poHistoryY;
  delete poHistoryYErr;
  
  delete poInterp;
  
  delete poXLabel;
  delete poYLabel;
  delete poTitle;

  delete poXLabelDefault;
  delete poYLabelDefault;
  delete poTitleDefault;
  
  delete poXLabelDefaultOld;
  delete poXLabelOld;

  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::fileASCII

Description:
------------
This public member function returns the ASCII file name.

Inputs:
-------
None.

Outputs:
--------
The ASCII file name, returned via the function value.

Modification history:
---------------------
2000 Jul 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC1::fileASCII( void ) const {

  // Return the file name
  
  return( String( *poFileASCII ) );

}

// -----------------------------------------------------------------------------

/*

GDC1::getArgCheck

Description:
------------
This public member function gets the check-arguments boolean.

Inputs:
-------
None.

Outputs:
--------
The check-arguments boolean, returned via the function value.

Modification history:
---------------------
2000 Jun 08 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1::getArgCheck( void ) const {

  // Return the check-arguments boolean
  
  return( bArgCheck );

}

// -----------------------------------------------------------------------------

/*

GDC1::setArgCheck

Description:
------------
This public member function sets the check-arguments boolean, to increase
speed.  Checking is not performed in the plot( ) member function.  Also, no
checking should be perfromed when a GDC1{ } object is created from (and the
arguments checked in) glish.

Inputs:
-------
bArgCheckIn - The check-arguments boolean (default = True).

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 08 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setArgCheck( const Bool& bArgCheckIn ) {

  // Set the check-arguments boolean and return
  
  bArgCheck = bArgCheckIn;
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::dumpASCII

Description:
------------
This public member function dumps data to an ASCII file.  Interpolated data,
flagged in GDC1{ } objects, is dumped as unflagged.  NB: I'm using functions
from stdio.h because I dislike the classes in iostream.h.

Inputs:
-------
oFileIn - The ASCII file name.
XMinIn  - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean (default = False).

Outputs:
--------
The ASCII file.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::dumpASCII( String& oFileIn, Double& dXMinIn, Double& dXMaxIn,
    const Bool& bKeepIn ) const {

  // Declare the local variables
  
  uInt uiIndex;    // The index counter
  
  FILE* pmtStream; // The data output stream
  
  
  // Get the indices

  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "dumpASCII" ) );
  }
  

  // Open the ASCII file

  oFileIn.gsub( RXwhite, "" );
  
  pmtStream = fopen( oFileIn.chars(), "w" );
  
  if ( pmtStream == NULL ) {
    throw( ermsg( "Cannot create ASCII file", "GDC1", "dumpASCII" ) );
  }
  
  
  // Dump the data to the ASCII file
  
  for ( uiIndex = 0; uiIndex < oIndex.nelements(); uiIndex++ ) {
    fprintf( pmtStream, "%18f %18f ", (*poX)(oIndex(uiIndex)),
        (*poY)(oIndex(uiIndex)) );
    if ( bXError ) {
      fprintf( pmtStream, "%18f ", (*poXErr)(oIndex(uiIndex)) );
    } else {
      fprintf( pmtStream, "%18f ", 0.0 );
    }
    if ( bYError ) {
      fprintf( pmtStream, "%18f ", (*poYErr)(oIndex(uiIndex)) );
    } else {
      fprintf( pmtStream, "%18f ", 0.0 );
    }
    fprintf( pmtStream, "%u %u\n", (uInt) (*poFlag)(oIndex(uiIndex)),
        (uInt) (*poInterp)(oIndex(uiIndex)) );
  }
  
  
  // Close the ASCII file
  
  fclose( pmtStream );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::clone

Description:
------------
This public member function returns a cloned GDC1{ } object.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.

Outputs:
--------
The cloned GDC1{ } object, returned via the function value.

Modification history:
---------------------
2000 Jun 21 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1* GDC1::clone( Double& dXMinIn, Double& dXMaxIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData;    // The data counter
  uInt uiNumData; // The number of data
  
  Double dXMax;   // The global maximum x value
  Double dXMin;   // The global minimum x value
  
  
  // Get the indices

  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "clone" ) );
  }
  
  
  // Get the arguments
  
  dXMin = xMin( False );
  dXMax = xMax( False );
  
  
  // Initialize the Vector<> objects
  
  Vector<Double> oXClone = Vector<Double>();
  Vector<Double> oXErrClone = Vector<Double>();
  
  Vector<Double> oYClone = Vector<Double>();
  Vector<Double> oYErrClone = Vector<Double>();
  
  Vector<Bool> oFlagClone = Vector<Bool>();
  
  
  // Get the desired data from this object
  
  uiNumData = oIndex.nelements();
  
  oXClone.resize( uiNumData, False );
  oYClone.resize( uiNumData, False );
  
  oFlagClone.resize( uiNumData, False );
  
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    oXClone(uiData) = (*poXOld)(oIndex(uiData));
    oYClone(uiData) = (*poY)(oIndex(uiData));
    oFlagClone(uiData) = (*poFlag)(oIndex(uiData));
  }
  
  if ( bXError ) {
    oXErrClone.resize( uiNumData, False );
    for ( uiData = 0; uiData < uiNumData; uiData++ ) {
      oXErrClone(uiData) = (*poXErrOld)(oIndex(uiData));
    }
  }
  
  if ( bYError ) {
    oYErrClone.resize( uiNumData, False );
    for ( uiData = 0; uiData < uiNumData; uiData++ ) {
      oYErrClone(uiData) = (*poYErr)(oIndex(uiData));
    }
  }
  
  
  // Create the cloned GDC1{ } object
  
  GDC1* poGDC1Clone = NULL;
  
  try {
    poGDC1Clone = new GDC1( oXClone, oYClone, oXErrClone, oYErrClone,
        oFlagClone, bHMSOld );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg(
        "Cannot created cloned GDC1{ } object\n" + oAipsError.getMesg(),
        "GDC1", "clone" ) );
  }
  
  
  // Return the cloned GDC1{ } object
  
  return( poGDC1Clone );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::average

Description:
------------
This public member function returns an averaged GDC1{ } object.

Inputs:
-------
oXIn      - The x vector.
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
bKeepIn   - The keep-flagged-data boolean.
bWeightIn - The weight boolean.
bXCalcIn  - The recalculate-x boolean.
oInterpIn - The interpolation method ("CUBIC", "LINEAR", "NEAREST", "SPLINE").

Outputs:
--------
The averaged GDC1{ } object, returned via the function value.

Modification history:
---------------------
2000 Jun 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1* GDC1::average( const Vector<Double>& oXIn, Double& dXMinIn,
    Double& dXMaxIn, const Bool& bKeepIn, const Bool& bWeightIn,
    const Bool& bXCalcIn, String& oInterpIn ) {
  
  // Declare the local variables

  uInt uiAve;            // The average counter  
  uInt uiData;           // The data counter
  uInt uiIndex;          // The index counter
  uInt uiNumAve = 0;     // The number of averages
  uInt uiNumData;        // The number of data
  uInt uiNumIndex;       // The number of indices
  uInt uiNumTemp;        // The number of temporary data
  
  Double dXErrAve = 0.0; // The average x error
  Double dXMin;          // The minimum average x value
  Double dXMax;          // The maximum average x value
  Double dYErrAve;       // The average y error
  
  
  // Check the inputs

  uiNumData = oXIn.nelements();

  if ( uiNumData < 1 ) {
    throw( ermsg( "Invalid x vector", "GDC1", "average" ) );
  }
  
  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "average" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1", "average" ) );
  }
  
  if ( !checkInterp( oInterpIn ) ) {
    throw( ermsg( "Invalid interpolation method", "GDC1", "average" ) );
  }
  
  if ( oInterpIn.length() < 1 ) {
    throw( ermsg( "No interpolation method specified", "GDC1", "average" ) );
  }
  
  
  // Initialize the Vector<> objects
  
  Vector<Double> oX = Vector<Double>();
  Vector<Double> oY = Vector<Double>();
  Vector<Double> oXErr = Vector<Double>();
  Vector<Double> oYErr = Vector<Double>();
  
  Vector<Int>* poIndex = NULL;
  
  Vector<Double> oXAve = Vector<Double>();
  Vector<Double> oYAve = Vector<Double>();
  Vector<Double> oXErrAve = Vector<Double>();
  Vector<Double> oYErrAve = Vector<Double>();
  
  Vector<Bool> oFlagAve = Vector<Bool>();
  
  Vector<Bool> oInterpAve = Vector<Bool>();
  
  Vector<Double> oXErrTemp = Vector<Double>();
  Vector<Double> oYErrTemp = Vector<Double>();
  
  
  // Turn off the argument checking
  
  setArgCheck( False );
  
  
  // Calculate the averages
    
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    
    if ( uiData > 0 ) {
      dXMin = 0.5 * ( oXIn(uiData) + oXIn(uiData-1) );
    } else if ( uiNumData > 1 ) {
      dXMin = 0.5 * ( 3.0*oXIn(uiData) - oXIn(uiData+1) );
    } else {
      dXMin = oXIn(uiData);
    }
      
    if ( uiData < uiNumData-1 ) {
      dXMax = 0.5 * ( oXIn(uiData+1) + oXIn(uiData) );
    } else if ( uiNumData > 1 ) {
      dXMax = 0.5 * ( 3.0*oXIn(uiData) - oXIn(uiData-1) );
    } else {
      dXMax = oXIn(uiData);
    }
    
    poIndex = new Vector<Int>( index( dXMin, dXMax, bKeepIn ) );
    uiNumIndex = poIndex->nelements();
      
    uiNumAve += 1;
      
    oXAve.resize( uiNumAve, True );
    oYAve.resize( uiNumAve, True );
    oYErrAve.resize( uiNumAve, True );
    oInterpAve.resize( uiNumAve, True );
      
    if ( uiNumIndex < 2 ) {
      delete poIndex;
      if ( bXCalcIn ) {
        oXErrAve.resize( uiNumAve, True );
        oXAve(uiNumAve-1) = 0.5 * ( dXMin + dXMax );
      } else {
        oXAve(uiNumAve-1) = oXIn(uiData);
      }
      oInterpAve(uiNumAve-1) = True;
      continue;
    }
      
    if ( bXCalcIn ) {
      oXErrAve.resize( uiNumAve, True );
      oX.resize( uiNumIndex, False );
      for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
        oX(uiIndex) = (*poX)((*poIndex)(uiIndex));
      }
      if ( !bWeightIn || !bXError ) {
        oXAve(uiNumAve-1) = StatToolbox::mean( &oX, NULL );
        oXErrAve(uiNumAve-1) = StatToolbox::meanerr( &oX, NULL );
      } else {
        oXErr.resize( uiNumIndex, False );
        for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
          oXErr(uiIndex) = (*poXErr)((*poIndex)(uiIndex));
        }
        oXAve(uiNumAve-1) = StatToolbox::mean( &oX, &oXErr );
        oXErrAve(uiNumAve-1) = StatToolbox::meanerr( &oX, &oXErr );
      }
    } else {
      oXAve(uiNumAve-1) = oXIn(uiData);
    }
      
    oY.resize( uiNumIndex, False );
    for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
      oY(uiIndex) = (*poY)((*poIndex)(uiIndex));
    }
      
    if ( !bWeightIn || !bYError ) {
      oYAve(uiNumAve-1) = StatToolbox::mean( &oY, NULL );
      oYErrAve(uiNumAve-1) = StatToolbox::meanerr( &oY, NULL );
    } else {
      oYErr.resize( uiNumIndex, False );
      for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
        oYErr(uiIndex) = (*poYErr)((*poIndex)(uiIndex));
      }
      oYAve(uiNumAve-1) = StatToolbox::mean( &oY, &oYErr );
      oYErrAve(uiNumAve-1) = StatToolbox::meanerr( &oY, &oYErr );
    }
      
    oInterpAve(uiNumAve-1) = False;
      
    delete poIndex;
  
  }
  
  
  // Check if any data were averaged
  
  if ( uiNumAve < 1 ) {
    setArgCheck( True );
    throw( ermsg( "No data can be averaged with these inputs", "GDC1",
        "average" ) );
  }
  
  
  // Interpolate in the regions with insufficient data
        
  if ( bXCalcIn ) {
    uiNumTemp = 0;
    oXErrTemp.resize( 0, False );
    for ( uiAve = 0; uiAve < uiNumAve; uiAve++ ) {
      if ( oInterpAve(uiAve) ) {
        continue;
      }
      uiNumTemp += 1;
      oXErrTemp.resize( uiNumTemp, True );
      oXErrTemp(uiNumTemp-1) = oXErrAve(uiAve);
    }
    dXErrAve = StatToolbox::mean( &oXErrTemp, NULL );
  }

  uiNumTemp = 0;
  oYErrTemp.resize( 0, False );
  
  for ( uiAve = 0; uiAve < uiNumAve; uiAve++ ) {
    if ( oInterpAve(uiAve) ) {
      continue;
    }
    uiNumTemp += 1;
    oYErrTemp.resize( uiNumTemp, True );
    oYErrTemp(uiNumTemp-1) = oYErrAve(uiAve);
  }
  
  dYErrAve = StatToolbox::mean( &oYErrTemp, NULL );
  
  for ( uiAve = 0; uiAve < uiNumAve; uiAve++ ) {
    if ( !oInterpAve(uiAve) ) {
      continue;
    }
    if ( bXCalcIn ) {
      oXErrAve(uiAve) = dXErrAve;
    }
    dXMin = (*poX)(0);
    dXMax = (*poX)(poX->nelements()-1);
    oYAve(uiAve) = yInterpolate( Vector<Double>( 1, oXAve(uiAve) ), bKeepIn,
        oInterpIn, dXMin, dXMax )(0);
    oYErrAve(uiAve) = dYErrAve;
  }
  
  
  // Turn on the argument checking
  
  setArgCheck( True );
  
  
  // Create the averaged GDC1{ } object
  
  GDC1* poGDC1Ave = NULL;
  
  try {
    poGDC1Ave = new GDC1( oXAve, oYAve, oXErrAve, oYErrAve, oFlagAve );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg(
        "Cannot create averaged GD1{ } object\n" + oAipsError.getMesg(),
        "GDC1", "average" ) );
  }

  
  // Return the averaged GDC1{ } object
  
  return( poGDC1Ave );

}

// -----------------------------------------------------------------------------

/*

GDC1::interpolate

Description:
------------
This public member function returns an interpolated GDC1{ } object.

Inputs:
-------
oXIn       - The x vector.
bKeepIn    - The keep-flagged-data boolean.
oInterpIn  - The interpolation method ("CUBIC", "LINEAR", "NEAREST", "SPLINE").
dXMinBoxIn - The minimum x-box value.
dXMaxBoxIn - The maximum x-box value.

Outputs:
--------
The interpolated GDC1{ } object, returned via the function value.

Modification history:
---------------------
2000 Jun 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1* GDC1::interpolate( const Vector<Double>& oXIn, const Bool& bKeepIn,
    String& oInterpIn, Double& dXMinBoxIn, Double& dXMaxBoxIn ) {
  
  // Declare the local variables

  uInt uiIndex;             // The index counter
  uInt uiMethod = 0;        // The interpolation method number
  uInt uiNumIndex;          // The number of indices
  uInt uiNumIndexBox = 0;   // The number of indices in both boxed regions
  
  Double dYInterp;          // The interpolated y value
  Double dXErrInterp = 0.0; // The interpolated x-error value (the average
                            // error of the boxed regions)
  Double dYErrInterp = 0.0; // The interpolated y-error value (the average
                            // error of the boxed regions)
  
  
  // Check the inputs
  
  Vector<Double> oX = oXIn;
  uiNumIndex = oX.nelements();

  if ( uiNumIndex < 1 ) {
    throw( ermsg( "Invalid x vector", "GDC1", "interpolate" ) );
  }
  
  if ( !checkX( dXMinBoxIn, dXMaxBoxIn ) ) {
    throw( ermsg( "Invalid x value(s) (box)", "GDC1", "interpolate" ) );
  }
  
  Vector<Int> oSortKey = StatToolbox::sortkey( oX );
  StatToolbox::sort( oSortKey, oX );
  
  if ( dXMinBoxIn >= oX(0) || dXMaxBoxIn <= oX(uiNumIndex-1) ) {
    throw( ermsg( "X-box value(s) overlap interpolation value(s)", "GDC1",
        "interpolate" ) );
  }
  
  if ( !checkInterp( oInterpIn ) ) {
    throw( ermsg( "Invalid interpolation method", "GDC1", "interpolate" ) );
  }
  
  if ( oInterpIn.length() < 1 ) {
    throw( ermsg( "No interpolation method specified", "GDC1",
        "interpolate" ) );
  }
  
  
  // Initialize variables and objects
  
  Vector<Int> oIndexBox = Vector<Int>();
  
  if ( oInterpIn.matches( "CUBIC" ) ) {
    uiMethod = Interpolate1D<Double,Double>::cubic;
  } else if ( oInterpIn.matches( "LINEAR" ) ) {
    uiMethod = Interpolate1D<Double,Double>::linear;
  } else if ( oInterpIn.matches( "NEAREST" ) ) {
    uiMethod = Interpolate1D<Double,Double>::nearestNeighbour;
  } else if ( oInterpIn.matches( "SPLINE" ) ) {
    uiMethod = Interpolate1D<Double,Double>::spline;
  }
  
  ScalarSampledFunctional<Double>* poSSFX = NULL;
  ScalarSampledFunctional<Double>* poSSFY = NULL;
  
  Interpolate1D<Double,Double>* poInterpolate1D = NULL;
  
  Vector<Double> oXInterp = Vector<Double>( uiNumIndex );
  Vector<Double> oYInterp = Vector<Double>( uiNumIndex );
  Vector<Double> oXErrInterp = Vector<Double>( uiNumIndex );
  Vector<Double> oYErrInterp = Vector<Double>( uiNumIndex );
  
  Vector<Bool> oFlagInterp = Vector<Bool>( uiNumIndex );
  
  
  // Turn off the argument checking
  
  setArgCheck( False );
  
  
  // Do the interpolation
    
  oIndexBox = index( dXMinBoxIn, dXMaxBoxIn, bKeepIn );
  uiNumIndexBox = oIndexBox.nelements();
    
  if ( uiNumIndexBox < 1 ) {
    String oMessage = "Zero-length box region(s)";
    msg( oMessage, "GDC1", "interpolate", GeneralStatus::WARN );
  }

  Vector<Double> oXTemp = Vector<Double>( uiNumIndexBox );
  Vector<Double> oYTemp = Vector<Double>( uiNumIndexBox );
  Vector<Double> oXErrTemp = Vector<Double>( uiNumIndexBox );
  Vector<Double> oYErrTemp = Vector<Double>( uiNumIndexBox );
    
  for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
    oXTemp(uiIndex) = (*poX)(oIndexBox(uiIndex));
    oYTemp(uiIndex) = (*poY)(oIndexBox(uiIndex));
  }
    
  if ( bXError ) {
    oXErrTemp.resize( uiNumIndexBox, False );
    for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
     oXErrTemp(uiIndex) = (*poXErr)(oIndexBox(uiIndex));
    }
    dXErrInterp = StatToolbox::mean( &oXErrTemp );
  }
    
  if ( bYError ) {
    oYErrTemp.resize( uiNumIndexBox, False );
    for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
     oYErrTemp(uiIndex) = (*poYErr)(oIndexBox(uiIndex));
    }
    dYErrInterp = StatToolbox::mean( &oYErrTemp );
  }
    
  try {
    poSSFX = new ScalarSampledFunctional<Double>( oXTemp.copy() );
    poSSFY = new ScalarSampledFunctional<Double>( oYTemp.copy() );
    poInterpolate1D = new Interpolate1D<Double,Double>( *poSSFX, *poSSFY );
    poInterpolate1D->setMethod( uiMethod );
  }
    
  catch ( AipsError oAipsError ) {
    String oMessage = "Error setting up interpolation\n";
    oMessage += oAipsError.getMesg();
    msg( oMessage, "GDC1", "interpolate", GeneralStatus::WARN );
  }
    
  for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
    try {
      dYInterp = (*poInterpolate1D)(oX(uiIndex));
    }
    catch ( AipsError oAipsError ) {
      String oMessage = "Interpolation error\n";
      oMessage += oAipsError.getMesg();
      msg( oMessage, "GDC1", "interpolate", GeneralStatus::WARN );
      continue;
    }
    oXInterp(uiIndex) = oX(uiIndex);
    oYInterp(uiIndex) = dYInterp;
    if ( bXError ) {
      oXErrInterp(uiIndex) = dXErrInterp;
    } else {
      oXErrInterp(uiIndex) = 0.0;
    }
    if ( bYError ) {
      oYErrInterp(uiIndex) = dYErrInterp;
    } else {
     oYErrInterp(uiIndex) = 0.0;
    }
    oFlagInterp(uiIndex) = False;
  }
    
  delete poSSFX;
  delete poSSFY;
    
  delete poInterpolate1D;
  
  
  // Create the interpolated GDC1{ } object
  
  GDC1* poGDC1Interp = NULL;
  
  try {
    poGDC1Interp = new GDC1( oXInterp, oYInterp, oXErrInterp, oYErrInterp,
        oFlagInterp );
  }
  
  catch ( AipsError oAipsError ) {
    setArgCheck( True );
    String oError = "Cannot create interpolated GDC1{ } object\n";
    oError += oAipsError.getMesg();
    throw( ermsg( oError, "GDC1", "interpolate" ) );
  }
  
  
  // Turn on the argument checking
  
  setArgCheck( True );
  
  
  // Return the interpolated GDC1{ } object
  
  return( poGDC1Interp );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::yInterpolate

Description:
------------
This public member function returns an interpolated y-value vector.

Inputs:
-------
oXIn       - The x vector.
bKeepIn    - The keep-flagged-data boolean.
oInterpIn  - The interpolation method ("CUBIC", "LINEAR", "NEAREST", "SPLINE").
dXMinBoxIn - The minimum x-box value.
dXMaxBoxIn - The maximum x-box value.

Outputs:
--------
The interpolated y-value vector, returned via the function value.

Modification history:
---------------------
2000 Jun 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC1::yInterpolate( const Vector<Double>& oXIn,
    const Bool& bKeepIn, String& oInterpIn, Double& dXMinBoxIn,
    Double& dXMaxBoxIn ) {
  
  // Declare the local variables

  uInt uiIndex;           // An index counter
  uInt uiMethod = 0;      // The interpolation method number
  uInt uiNumIndex;        // The number of indices
  uInt uiNumIndexBox = 0; // The number of indices in both boxed regions
  
  Double dYInterp;        // The interpolated y value
  
  
  // Check the inputs
  
  Vector<Double> oX = oXIn;
  uiNumIndex = oX.nelements();

  if ( uiNumIndex < 1 ) {
    throw( ermsg( "Invalid x vector", "GDC1", "yInterpolate" ) );
  }
  
  if ( !checkX( dXMinBoxIn, dXMaxBoxIn ) ) {
    throw( ermsg( "Invalid x value(s) (box)", "GDC1", "yInterpolate" ) );
  }
  
  Vector<Int> oSortKey = StatToolbox::sortkey( oX );
  StatToolbox::sort( oSortKey, oX );
  
  if ( dXMinBoxIn >= oX(0) || dXMaxBoxIn <= oX(uiNumIndex-1) ) {
    throw( ermsg( "X-box value(s) overlap interpolation value(s)", "GDC1",
        "yInterpolate" ) );
  }
  
  if ( !checkInterp( oInterpIn ) ) {
    throw( ermsg( "Invalid interpolation method", "GDC1", "yInterpolate" ) );
  }
  
  if ( oInterpIn.length() < 1 ) {
    throw( ermsg( "No interpolation method specified", "GDC1",
        "yInterpolate" ) );
  }
  
  
  // Initialize variables and objects
  
  Vector<Int> oIndexBox = Vector<Int>();
  
  if ( oInterpIn.matches( "CUBIC" ) ) {
    uiMethod = Interpolate1D<Double,Double>::cubic;
  } else if ( oInterpIn.matches( "LINEAR" ) ) {
    uiMethod = Interpolate1D<Double,Double>::linear;
  } else if ( oInterpIn.matches( "NEAREST" ) ) {
    uiMethod = Interpolate1D<Double,Double>::nearestNeighbour;
  } else if ( oInterpIn.matches( "SPLINE" ) ) {
    uiMethod = Interpolate1D<Double,Double>::spline;
  }
  
  ScalarSampledFunctional<Double>* poSSFX = NULL;
  ScalarSampledFunctional<Double>* poSSFY = NULL;
  
  Interpolate1D<Double,Double>* poInterpolate1D = NULL;
  
  Vector<Double> oYInterp = Vector<Double>( uiNumIndex );
  
  
  // Turn off the argument checking
  
  setArgCheck( False );
  
  
  // Do the interpolation
    
  oIndexBox = index( dXMinBoxIn, dXMaxBoxIn, bKeepIn );
  uiNumIndexBox = oIndexBox.nelements();
    
  if ( uiNumIndexBox < 1 ) {
    String oMessage = "Zero-length box region(s)\n";
    msg( oMessage, "GDC1", "interpolate", GeneralStatus::WARN );
  }

  Vector<Double> oXTemp = Vector<Double>( uiNumIndexBox );
  Vector<Double> oYTemp = Vector<Double>( uiNumIndexBox );
    
  for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
    oXTemp(uiIndex) = (*poX)(oIndexBox(uiIndex));
    oYTemp(uiIndex) = (*poY)(oIndexBox(uiIndex));
  }
    
  try {
    poSSFX = new ScalarSampledFunctional<Double>( oXTemp.copy() );
    poSSFY = new ScalarSampledFunctional<Double>( oYTemp.copy() );
    poInterpolate1D = new Interpolate1D<Double,Double>( *poSSFX, *poSSFY );
    poInterpolate1D->setMethod( uiMethod );
  }
    
  catch ( AipsError oAipsError ) {
    String oMessage = "Error setting up interpolation\n";
    oMessage += oAipsError.getMesg();
    msg( oMessage, "GDC1", "interpolate", GeneralStatus::WARN );
  }
    
  for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
    try {
      dYInterp = (*poInterpolate1D)(oX(uiIndex));
    }
    catch ( AipsError oAipsError ) {
      String oMessage = "Interpolation error\n";
      oMessage += oAipsError.getMesg();
      msg( oMessage, "GDC1", "interpolate", GeneralStatus::WARN );
      continue;
    }
    oYInterp(uiIndex) = dYInterp;
  }
    
  delete poSSFX;
  delete poSSFY;
    
  delete poInterpolate1D;
  
  
  // Turn on the argument checking
  
  setArgCheck( True );
  
  
  // Return the interpolated y-value vector
  
  return( oYInterp );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::length

Description:
------------
This public member function returns the length.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.

Outputs:
--------
The length, returned via the function value.

Modification history:
---------------------
2000 Apr 28 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt GDC1::length( Double& dXMinIn, Double& dXMaxIn,
    const Bool& bKeepIn ) const {
    
  // Declare the local variables
  
  uInt uiLength = 0; // The length (keep compiler happy)
  
  
  // Determine the length and return
  
  try {
    uiLength = index( dXMinIn, dXMaxIn, bKeepIn ).nelements();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "length" ) );
  }
  
  return( uiLength );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::x

Description:
------------
This public member function returns x values.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.

Outputs:
--------
The x values, returned via the function value.

Modification history:
---------------------
2000 Apr 28 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC1::x( Double& dXMinIn, Double& dXMaxIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the x values and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1", "x" ) );
  }
  
  Vector<Double> oX = Vector<Double>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oX(uiData) = (*poX)(oIndex(uiData));
  }
  
  return( oX );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::xOld

Description:
------------
This public member function returns old x values.

Inputs:
-------
None.

Outputs:
--------
The old x values, returned via the function value.

Modification history:
---------------------
2001 Jan 31 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC1::xOld( void ) const {

  // Return the old x values
  
  return( Vector<Double>( poXOld->copy() ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::y

Description:
------------
This public member function returns y values.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.
bOrigIn - The original-data (non-interpolated) boolean.

Outputs:
--------
The y values, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC1::y( Double& dXMinIn, Double& dXMaxIn, const Bool& bKeepIn,
    const Bool& bOrigIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the y values and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1", "y" ) );
  }
  
  Vector<Double> oY = Vector<Double>( oIndex.nelements(), 0.0 );
  
  if ( !bOrigIn ) {
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      oY(uiData) = (*poY)(oIndex(uiData));
    }
  } else {
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      oY(uiData) = (*poYOrig)(oIndex(uiData));
    }
  }
  
  return( oY );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::xErr

Description:
------------
This public member function returns x errors.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.

Outputs:
--------
The x errors, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC1::xErr( Double& dXMinIn, Double& dXMaxIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the x errors and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "xErr" ) );
  }
  
  Vector<Double> oXErr = Vector<Double>();
  
  if ( bXError ) {
    oXErr.resize( oIndex.nelements(), True );
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      oXErr(uiData) = (*poXErr)(oIndex(uiData));
    }
  }
  
  return( oXErr );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::xErrOld

Description:
------------
This public member function returns old x errors.

Inputs:
-------
None.

Outputs:
--------
The old x errors, returned via the function value.

Modification history:
---------------------
2001 Jan 31 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC1::xErrOld( void ) const {

  // Return the old x errors
  
  return( Vector<Double>( poXErrOld->copy() ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::yErr

Description:
------------
This public member function returns y errors.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.
bOrigIn - The original-data (non-interpolated) boolean.

Outputs:
--------
The y errors, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC1::yErr( Double& dXMinIn, Double& dXMaxIn,
    const Bool& bKeepIn, const Bool& bOrigIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the y errors and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "yErr" ) );
  }
  
  Vector<Double> oYErr = Vector<Double>();
  
  if ( bYError ) {
    oYErr.resize( oIndex.nelements(), True );
    if ( !bOrigIn ) {
      for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
        oYErr(uiData) = (*poYErr)(oIndex(uiData));
      }
    } else {
      for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
        oYErr(uiData) = (*poYErrOrig)(oIndex(uiData));
      }
    }
  }
  
  return( oYErr );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::xError

Description:
------------
This public member function returns the x-error boolean.

Inputs:
-------
None.

Outputs:
--------
The x-error boolean, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1::xError( void ) const {

  // Return the x-error boolean
  
  return( bXError );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::yError

Description:
------------
This public member function returns the y-error boolean.

Inputs:
-------
None.

Outputs:
--------
The y-error boolean, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1::yError( void ) const {

  // Return the y-error boolean
  
  return( bYError );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::flag

Description:
------------
This public member function returns flags.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bOrigIn - The original-flag boolean.

Outputs:
--------
The flags, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Bool> GDC1::flag( Double& dXMinIn, Double& dXMaxIn,
    const Bool& bOrigIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the flags and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "flag" ) );
  }
  
  Vector<Bool> oFlag = Vector<Bool>( oIndex.nelements(), 0.0 );

  if ( !bOrigIn ) {
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      oFlag(uiData) = (*poFlag)(oIndex(uiData));
    }
  } else {
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      oFlag(uiData) = (*poFlagOrig)(oIndex(uiData));
    }
  }
  
  return( oFlag );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::interp

Description:
------------
This public member function returns interpolation booleans.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.

Outputs:
--------
The interpolation booleans, returned via the function value.

Modification history:
---------------------
2000 Aug 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Bool> GDC1::interp( Double& dXMinIn, Double& dXMaxIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the interpolation booleans and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "interp" ) );
  }
  
  Vector<Bool> oInterp = Vector<Bool>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oInterp(uiData) = (*poInterp)(oIndex(uiData));
  }
  
  return( oInterp );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::index

Description:
------------
This public member function returns the indices.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.

Outputs:
--------
The indices, returned via the function value.

Modification history:
---------------------
2000 Apr 28 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> GDC1::index( Double& dXMinIn, Double& dXMaxIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData;     // The data counter
  uInt uiNumData;  // The number of data
  uInt uiNumIndex; // The number of indices
  
  
  // Fix/check the inputs
  
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "GDC1", "index" ) );
  }
  
  
  // Find the indices and return
  
  uiNumData = poX->nelements();
  
  uiNumIndex = 0;
  Vector<Int> oIndex = Vector<Int>();
  
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    if ( (*poX)(uiData) >= dXMinIn && (*poX)(uiData) <= dXMaxIn &&
         ( !(*poFlag)(uiData) || bKeepIn ) ) {
      uiNumIndex += 1;
      oIndex.resize( uiNumIndex, True );
      oIndex(uiNumIndex-1) = uiData;
    }
  }

  Vector<Int> oSortKey = StatToolbox::sortkey( oIndex );
  StatToolbox::sort( oSortKey, oIndex );

  return( oIndex );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::xMax (global)

Description:
------------
This public member function returns the maximum x value.

Inputs:
-------
bPlotIn - The plot boolean (include x errors).

Outputs:
--------
The maximum x value, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::xMax( const Bool& bPlotIn ) const {

  // Return the maximum x value
  
  Double dXMax; // The maximum x value
  
  if ( !bPlotIn || !bXError ) {
    dXMax = StatToolbox::max( poX, NULL );
    if ( poX->nelements() == 1 ) {
      dXMax += 1.0;
    }
  } else {
    dXMax = StatToolbox::max( poX, poXErr );
  }
  
  return( dXMax );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::xMax (specific)

Description:
------------
This public member function returns the maximum x value.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.
bPlotIn - The plot boolean (include x errors).

Outputs:
--------
The maximum x value, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::xMax( Double& dXMinIn, Double& dXMaxIn, const Bool& bKeepIn,
    const Bool& bPlotIn ) const {
  
  // Declare the local variables
  
  uInt uiData;  // The data counter
  
  Double dXMax; // The maximum x value
  
  
  // Find and return the maximum x value
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "xMax" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1", "xMax" ) );
  }
  
  Vector<Double> oX = Vector<Double>( oIndex.nelements(), 0.0 );
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oX(uiData) = (*poX)(oIndex(uiData));
  }
  
  if ( !bPlotIn || !bXError ) {
    dXMax = StatToolbox::max( &oX, NULL );
    if ( oX.nelements() == 1 ) {
      dXMax += 1.0;
    }
  } else {
    Vector<Double> oXErr = Vector<Double>( oIndex.nelements(), 0.0 );
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      oXErr(uiData) = (*poXErr)(oIndex(uiData));
    }
    dXMax = StatToolbox::max( &oX, &oXErr );
  }
  
  return( dXMax );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::xMin (global)

Description:
------------
This public member function returns the minimum x value.

Inputs:
-------
bPlotIn - The plot boolean (include x errors).

Outputs:
--------
The minimum x value, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::xMin( const Bool& bPlotIn ) const {

  // Return the minimum x value
  
  Double dXMin; // The minimum x value
  
  if ( !bPlotIn || !bXError ) {
    dXMin = StatToolbox::min( poX, NULL );
    if ( poX->nelements() == 1 ) {
      dXMin -= 1.0;
    }
  } else {
    dXMin = StatToolbox::min( poX, poXErr );
  }
  
  return( dXMin );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::xMin (specific)

Description:
------------
This public member function returns the minimum x value.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.
bPlotIn - The plot boolean (include x errors).

Outputs:
--------
The minimum x value, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::xMin( Double& dXMinIn, Double& dXMaxIn, const Bool& bKeepIn,
    const Bool& bPlotIn ) const {
  
  // Declare the local variables
  
  uInt uiData;  // The data counter
  
  Double dXMin; // The minimum x value
  
  
  // Find and return the minimum x value
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "xMin" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1", "xMin" ) );
  }
  
  Vector<Double> oX = Vector<Double>( oIndex.nelements(), 0.0 );
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oX(uiData) = (*poX)(oIndex(uiData));
  }
  
  if ( !bPlotIn || !bXError ) {
    dXMin = StatToolbox::min( &oX, NULL );
    if ( oX.nelements() == 1 ) {
      dXMin -= 1.0;
    }
  } else {
    Vector<Double> oXErr = Vector<Double>( oIndex.nelements(), 0.0 );
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      oXErr(uiData) = (*poXErr)(oIndex(uiData));
    }
    dXMin = StatToolbox::min( &oX, &oXErr );
  }
  
  return( dXMin );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::yMax (global)

Description:
------------
This public member function returns the maximum y value.

Inputs:
-------
bPlotIn - The plot boolean (include x errors).

Outputs:
--------
The maximum y value, returned via the function value.

Modification history:
---------------------
2000 Jun 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::yMax( const Bool& bPlotIn ) const {

  // Declare the local variables
  
  Double dXMax = xMax(); // The maximum x value
  Double dXMin = xMin(); // The minimum x value
  
  Double dYMax = 0;      // The maximum y value
  

  // Return the maximum y value
  
  try {
    dYMax = yMax( dXMin, dXMax, bKeep, bPlotIn );
  }

  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not find maximum y value" + oAipsError.getMesg(),
        "GDC1", "yMax" ) );
  }
  
  return( dYMax );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::yMax (specific)

Description:
------------
This public member function returns the maximum y value.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.
bPlotIn - The plot boolean (include y errors).

Outputs:
--------
The maximum y value, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::yMax( Double& dXMinIn, Double& dXMaxIn, const Bool& bKeepIn,
    const Bool& bPlotIn ) const {
  
  // Declare the local variables
  
  uInt uiData;  // The data counter
  
  Double dYMax; // The maximum y value
  
  
  // Find and return the maximum y value
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "yMax" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1", "yMax" ) );
  }
  
  Vector<Double> oY = Vector<Double>( oIndex.nelements(), 0.0 );
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oY(uiData) = (*poY)(oIndex(uiData));
  }
  
  if ( !bPlotIn || !bYError ) {
    dYMax = StatToolbox::max( &oY, NULL );
    if ( oY.nelements() == 1 ) {
      dYMax += 1.0;
    }
  } else {
    Vector<Double> oYErr = Vector<Double>( oIndex.nelements(), 0.0 );
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      oYErr(uiData) = (*poYErr)(oIndex(uiData));
    }
    dYMax = StatToolbox::max( &oY, &oYErr );
  }
  
  return( dYMax );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::yMin (global)

Description:
------------
This public member function returns the minimum y value.

Inputs:
-------
bPlotIn - The plot boolean (include x errors).

Outputs:
--------
The minimum y value, returned via the function value.

Modification history:
---------------------
2000 Jun 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::yMin( const Bool& bPlotIn ) const {

  // Declare the local variables
  
  Double dXMax = xMax(); // The maximum x value
  Double dXMin = xMin(); // The minimum x value
  
  Double dYMin = 0;      // The minimum y value
  

  // Return the minimum y value
  
  try {
    dYMin = yMin( dXMin, dXMax, bKeep, bPlotIn );
  }

  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not find minimum y value" + oAipsError.getMesg(),
        "GDC1", "yMin" ) );
  }
  
  return( dYMin );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::yMin (specific)

Description:
------------
This public member function returns the minimum y value.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean).
bPlotIn - The plot boolean (include y errors).

Outputs:
--------
The minimum y value, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::yMin( Double& dXMinIn, Double& dXMaxIn, const Bool& bKeepIn,
    const Bool& bPlotIn ) const {
  
  // Declare the local variables
  
  uInt uiData;  // The data counter
  
  Double dYMin; // The minimum y value
  
  
  // Find and return the minimum y value
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "yMin" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1", "yMin" ) );
  }
  
  Vector<Double> oY = Vector<Double>( oIndex.nelements(), 0.0 );
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oY(uiData) = (*poY)(oIndex(uiData));
  }
  
  if ( !bPlotIn || !bYError ) {
    dYMin = StatToolbox::min( &oY, NULL );
    if ( oY.nelements() == 1 ) {
      dYMin -= 1.0;
    }
  } else {
    Vector<Double> oYErr = Vector<Double>( oIndex.nelements(), 0.0 );
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      oYErr(uiData) = (*poYErr)(oIndex(uiData));
    }
    dYMin = StatToolbox::min( &oY, &oYErr );
  }
  
  return( dYMin );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::xErrMax (global)

Description:
------------
This public member function returns the maximum x error.

Inputs:
-------
None.

Outputs:
--------
The maximum x error, returned via the function value.

Modification history:
---------------------
2000 Jun 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::xErrMax( void ) const {

  // Return the maximum x error
  
  Double dXMin = xMin();
  Double dXMax = xMax();
  
  return( xErrMax( dXMin, dXMax, bKeep ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::xErrMax (specific)

Description:
------------
This public member function returns the maximum x error.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.

Outputs:
--------
The maximum x error, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::xErrMax( Double& dXMinIn, Double& dXMaxIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find and return the maximum x error
  
  if ( !bXError ) {
    throw( ermsg( "No x errors", "GDC1", "xErrMax" ) );
  }
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "xErrMax" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1", "xErrMax" ) );
  }
  
  Vector<Double> oXErr = Vector<Double>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oXErr(uiData) = (*poXErr)(oIndex(uiData));
  }
  
  return( StatToolbox::max( &oXErr, NULL ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::xErrMin (global)

Description:
------------
This public member function returns the minimum x error

Inputs:
-------
None.

Outputs:
--------
The minimum x error, returned via the function value.

Modification history:
---------------------
2000 Jun 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::xErrMin( void ) const {

  // Return the minimum x error
  
  Double dXMin = xMin();
  Double dXMax = xMax();
  
  return( xErrMin( dXMin, dXMax, bKeep ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::xErrMin (specific)

Description:
------------
This public member function returns the minimum x error.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.

Outputs:
--------
The minimum x error, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::xErrMin( Double& dXMinIn, Double& dXMaxIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find and return the maximum x error
  
  if ( !bXError ) {
    throw( ermsg( "No x errors", "GDC1", "xErrMin" ) );
  }
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "xErrMin" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1", "xErrMin" ) );
  }
  
  Vector<Double> oXErr = Vector<Double>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oXErr(uiData) = (*poXErr)(oIndex(uiData));
  }
  
  return( StatToolbox::min( &oXErr, NULL ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::yErrMax (global)

Description:
------------
This public member function returns the maximum y error.

Inputs:
-------
None.

Outputs:
--------
The maximum y error, returned via the function value.

Modification history:
---------------------
2000 Jun 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::yErrMax( void ) const {

  // Return the maximum y error
  
  Double dXMin = xMin();
  Double dXMax = xMax();
  
  return( yErrMax( dXMin, dXMax, bKeep ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::yErrMax (specific)

Description:
------------
This public member function returns the maximum y error.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.

Outputs:
--------
The maximum y error, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::yErrMax( Double& dXMinIn, Double& dXMaxIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find and return the maximum y error
  
  if ( !bYError ) {
    throw( ermsg( "No y errors", "GDC1", "yErrMax" ) );
  }
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "yErrMax" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1", "yErrMax" ) );
  }
  
  Vector<Double> oYErr = Vector<Double>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oYErr(uiData) = (*poYErr)(oIndex(uiData));
  }
  
  return( StatToolbox::max( &oYErr, NULL ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::yErrMin (global)

Description:
------------
This public member function returns the minimum y error

Inputs:
-------
None.

Outputs:
--------
The minimum y error, returned via the function value.

Modification history:
---------------------
2000 Jun 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::yErrMin( void ) const {

  // Return the minimum y error
  
  Double dXMin = xMin();
  Double dXMax = xMax();
  
  return( yErrMin( dXMin, dXMax, bKeep ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::yErrMin (specific)

Description:
------------
This public member function returns the minimum y error.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
bKeepIn - The keep-flagged-data boolean.

Outputs:
--------
The minimum y error, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::yErrMin( Double& dXMinIn, Double& dXMaxIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find and return the maximum y error
  
  if ( !bYError ) {
    throw( ermsg( "No y errors", "GDC1", "yErrMin" ) );
  }
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "yErrMin" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1", "yErrMin" ) );
  }
  
  Vector<Double> oYErr = Vector<Double>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oYErr(uiData) = (*poYErr)(oIndex(uiData));
  }
  
  return( StatToolbox::min( &oYErr, NULL ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::flagged

Description:
------------
This public member function returns flagged data indices.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.

Outputs:
--------
The flagged data indices, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> GDC1::flagged( Double& dXMinIn, Double& dXMaxIn ) const {
  
  // Declare the local variables
  
  uInt uiIndex;        // The index counter
  uInt uiNumIndex;     // The number of indices
  uInt uiNumIndexFlag; // The number of True booleans
  
  
  // Find the flagged data indices and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "flagged" ) );
  }
  
  uiNumIndex = oIndex.nelements();
  
  Vector<Int> oIndexFlag = Vector<Int>();
  uiNumIndexFlag = oIndexFlag.nelements();
  
  for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
    if ( !(*poFlag)(oIndex(uiIndex)) ) {
      continue;
    }
    uiNumIndexFlag += 1;
    oIndexFlag.resize( uiNumIndexFlag, True );
    oIndexFlag(uiNumIndexFlag-1) = oIndex(uiIndex);
  }
  
  return( oIndexFlag );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::interpolated

Description:
------------
This public member function returns interpolated data indices.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.

Outputs:
--------
The interpolated data indices, returned via the function value.

Modification history:
---------------------
2000 Jul 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> GDC1::interpolated( Double& dXMinIn, Double& dXMaxIn ) const {
  
  // Declare the local variables
  
  uInt uiIndex;          // The index counter
  uInt uiNumIndex;       // The number of indices
  uInt uiNumIndexInterp; // The number of True booleans
  
  
  // Find the interpolated data indices and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, False );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "interpolated" ) );
  }
  
  uiNumIndex = oIndex.nelements();
  
  Vector<Int> oIndexInterp = Vector<Int>();
  uiNumIndexInterp = oIndexInterp.nelements();
  
  for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
    if ( !(*poInterp)(oIndex(uiIndex)) ) {
      continue;
    }
    uiNumIndexInterp += 1;
    oIndexInterp.resize( uiNumIndexInterp, True );
    oIndexInterp(uiNumIndexInterp-1) = oIndex(uiIndex);
  }
  
  return( oIndexInterp );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::mean

Description:
------------
This public member function returns the mean y value.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
bKeepIn   - The keep-flagged-data boolean.
bWeightIn - The weight boolean.

Outputs:
--------
The mean y value, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::mean( Double& dXMinIn, Double& dXMaxIn, const Bool& bKeepIn,
    const Bool& bWeightIn ) const {
  
  // Declare the local variables
  
  Double dMean; // The mean y value
  
  
  // Find and return the mean y value
  
  Vector<Double> oY = Vector<Double>(); // Keep compiler happy
  
  try {
    oY = y( dXMinIn, dXMaxIn, bKeepIn, False ).copy();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in y( )\n" + oAipsError.getMesg(), "GDC1", "mean" ) );
  }
  
  if ( oY.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1", "mean" ) );
  }
  
  if ( !bWeightIn || !bYError ) {
    dMean = StatToolbox::mean( &oY, NULL );
  } else {
    Vector<Double> oYErr = Vector<Double>(); // Keep compiler happy
    try {
      oYErr = yErr( dXMinIn, dXMaxIn, bKeepIn, False ).copy();
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in yErr( )\n" + oAipsError.getMesg(), "GDC1",
          "mean" ) );
    }
    dMean = StatToolbox::mean( &oY, &oYErr );
  }
  
  return( dMean );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::meanErr

Description:
------------
This public member function returns the y mean error.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
bKeepIn   - The keep-flagged-data boolean.
bWeightIn - The weight boolean.

Outputs:
--------
The y mean error, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::meanErr( Double& dXMinIn, Double& dXMaxIn, const Bool& bKeepIn,
    const Bool& bWeightIn ) const {
  
  // Declare the local variables
  
  Double dMeanErr; // The y mean error
  
  
  // Find and return the y mean error
  
  Vector<Double> oY = Vector<Double>(); // Keep compiler happy
  
  try {
    oY = y( dXMinIn, dXMaxIn, bKeepIn, False ).copy();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in y( )\n" + oAipsError.getMesg(), "GDC1",
        "meanErr" ) );
  }
  
  if ( oY.nelements() < 2 ) {
    throw( ermsg( "Not enough data in range", "GDC1", "meanErr" ) );
  }
  
  if ( !bWeightIn || !bYError ) {
    dMeanErr = StatToolbox::meanerr( &oY, NULL );
  } else {
    Vector<Double> oYErr = Vector<Double>(); // Keep compiler happy
    try {
      oYErr = yErr( dXMinIn, dXMaxIn, bKeepIn, False ).copy();
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in yErr( )\n" + oAipsError.getMesg(), "GDC1",
          "meanErr" ) );
    }
    dMeanErr = StatToolbox::meanerr( &oY, &oYErr );
  }
  
  return( dMeanErr );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::stdDev

Description:
------------
This public member function returns the y standard deviation.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
bKeepIn   - The keep-flagged-data boolean.
bWeightIn - The weight boolean.

Outputs:
--------
The y standard deviation, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::stdDev( Double& dXMinIn, Double& dXMaxIn, const Bool& bKeepIn,
    const Bool& bWeightIn ) const {
  
  // Declare the local variables
  
  Double dStdDev; // The y standard deviation
  
  
  // Find and return the y standard deviation
  
  Vector<Double> oY = Vector<Double>(); // Keep compiler happy
  
  try {
    oY = y( dXMinIn, dXMaxIn, bKeepIn, False ).copy();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in y( )\n" + oAipsError.getMesg(), "GDC1",
        "stdDev" ) );
  }
  
  if ( oY.nelements() < 2 ) {
    throw( ermsg( "Not enough data in range", "GDC1", "stdDev" ) );
  }
  
  if ( !bWeightIn || !bYError ) {
    dStdDev = StatToolbox::stddev( &oY, NULL );
  } else {
    Vector<Double> oYErr = Vector<Double>(); // Keep compiler happy
    try {
      oYErr = yErr( dXMinIn, dXMaxIn, bKeepIn, False ).copy();
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in yErr( )\n" + oAipsError.getMesg(), "GDC1",
          "stdDev" ) );
    }
    dStdDev = StatToolbox::stddev( &oY, &oYErr );
  }
  
  return( dStdDev );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::variance

Description:
------------
This public member function returns the y variance.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
bKeepIn   - The keep-flagged-data boolean.
bWeightIn - The weight boolean.

Outputs:
--------
The y variance, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::variance( Double& dXMinIn, Double& dXMaxIn, const Bool& bKeepIn,
    const Bool& bWeightIn ) const {
  
  // Declare the local variables
  
  Double dVariance; // The y variance
  
  
  // Find and return the y variance
  
  Vector<Double> oY = Vector<Double>(); // Keep compiler happy
  
  try {
    oY = y( dXMinIn, dXMaxIn, bKeepIn, False ).copy();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in y( )\n" + oAipsError.getMesg(), "GDC1",
        "variance" ) );
  }
  
  if ( oY.nelements() < 2 ) {
    throw( ermsg( "Not enough data in range", "GDC1", "variance" ) );
  }
  
  if ( !bWeightIn || !bYError ) {
    dVariance = StatToolbox::variance( &oY, NULL );
  } else {
    Vector<Double> oYErr = Vector<Double>();
    try {
      oYErr = yErr( dXMinIn, dXMaxIn, bKeepIn, False ).copy();
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in yErr( )\n" + oAipsError.getMesg(), "GDC1",
          "variance" ) );
    }
    dVariance = StatToolbox::variance( &oY, &oYErr );
  }
  
  return( dVariance );
  
}

// -----------------------------------------------------------------------------

/*

GDC1:setFlagX

Description:
------------
This public member function sets flags in a given x range.

Inputs:
-------
dXMinIn      - The minimum x value.
dXMaxIn      - The maximum x value.
bFlagValueIn - The flag value (True = set flags, False = unset flags).

Outputs:
--------
None.

Modification history:
---------------------
2000 May 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setFlagX( Double& dXMinIn, Double& dXMaxIn,
    const Bool& bFlagValueIn ) {
  
  // Declare the local variables
  
  uInt uiEvent;      // The event number
  uInt uiIndex;      // The index counter
  uInt uiNumHistory; // The number of histories
  uInt uiNumIndex;   // The number of indices
  uInt uiNumIndexX;  // The number of indices, not taking flags into account
  
  
  // Get the indices
  
  Vector<Int> oIndexX = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndexX = index( dXMinIn, dXMaxIn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "setFlagX" ) );
  }
  
  uiNumIndexX = oIndexX.nelements();
  
  Vector<Int> oIndex = Vector<Int>();
  uiNumIndex = oIndex.nelements();
  
  for ( uiIndex = 0; uiIndex < uiNumIndexX; uiIndex++ ) {
    if ( (*poFlag)(oIndexX(uiIndex)) != bFlagValueIn ) {
      uiNumIndex += 1;
      oIndex.resize( uiNumIndex, True );
      oIndex(uiNumIndex-1) = oIndexX(uiIndex);
    }
  }
  
  if ( uiNumIndex < 1 ) {
    return;
  }
  
  
  // Set the histories
  
  uiNumHistory = poHistoryEvent->nelements();
  
  if ( uiNumHistory < 1 ) {
    uiEvent = 1;
  } else {
    uiEvent = (uInt) (*poHistoryEvent)(uiNumHistory-1) + 1;
  }

  poHistoryEvent->resize( uiNumIndex+uiNumHistory, True );
  poHistoryIndex->resize( uiNumIndex+uiNumHistory, True );
  poHistoryFlag->resize( uiNumIndex+uiNumHistory, True );
  poHistoryInterp->resize( uiNumIndex+uiNumHistory, True );
  poHistoryY->resize( uiNumIndex+uiNumHistory, True );
  poHistoryYErr->resize( uiNumIndex+uiNumHistory, True );
  
  for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
    (*poHistoryEvent)(uiIndex+uiNumHistory) = (Int) uiEvent;
    (*poHistoryIndex)(uiIndex+uiNumHistory) = oIndex(uiIndex);
    (*poHistoryFlag)(uiIndex+uiNumHistory) = bFlagValueIn;
    (*poHistoryInterp)(uiIndex+uiNumHistory) = False;
    (*poHistoryY)(uiIndex+uiNumHistory) = 0.0;
    (*poHistoryYErr)(uiIndex+uiNumHistory) = 0.0;
    (*poFlag)(oIndex(uiIndex)) = bFlagValueIn;
    (*poInterp)(oIndex(uiIndex)) = False;
  }


  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1:setFlagXY

Description:
------------
This public member function sets flags in a given x-y range.

Inputs:
-------
dXMinIn      - The minimum x value.
dXMaxIn      - The maximum x value.
dYMinIn      - The minimum y value.
dYMaxIn      - The maximum y value.
bFlagValueIn - The flag value (True = set flags, False = unset flags).

Outputs:
--------
None.

Modification history:
---------------------
2000 May 07 - Nicholas Elias, USNO/NPOI
              Public member function created.


*/

// -----------------------------------------------------------------------------

void GDC1::setFlagXY( Double& dXMinIn, Double& dXMaxIn, Double& dYMinIn,
    Double& dYMaxIn, const Bool& bFlagValueIn ) {
  
  // Declare the local variable
  
  uInt uiEvent;      // The event number
  uInt uiIndex;      // The index counter
  uInt uiNumHistory; // The number of histories
  uInt uiNumIndex;   // The number of indices
  uInt uiNumIndexX;  // The number of indices, not taking y range and flags
                     // into account


  // Check the inputs
  
  if ( !checkY( dYMinIn, dYMaxIn ) ) {
    throw( ermsg( "Invalid y value(s)", "GDC1", "setFlagXY" ) );
  }
  
  
  // Get the indices
  
  Vector<Int> oIndexX = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndexX = index( dXMinIn, dXMaxIn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1",
        "setFlagXY" ) );
  }
  
  uiNumIndexX = oIndexX.nelements();
  
  Vector<Int> oIndex = Vector<Int>();
  uiNumIndex = oIndex.nelements();
  
  for ( uiIndex = 0; uiIndex < uiNumIndexX; uiIndex++ ) {
    if ( (*poFlag)(oIndexX(uiIndex)) != bFlagValueIn &&
         (*poY)(oIndexX(uiIndex)) >= dYMinIn &&
         (*poY)(oIndexX(uiIndex)) <= dYMaxIn ) {
      uiNumIndex += 1;
      oIndex.resize( uiNumIndex, True );
      oIndex(uiNumIndex-1) = oIndexX(uiIndex);
    }
  }
  
  if ( uiNumIndex < 1 ) {
    return;
  }

  
  // Set the histories
  
  uiNumHistory = poHistoryEvent->nelements();
  
  if ( uiNumHistory < 1 ) {
    uiEvent = 1;
  } else {
    uiEvent = (uInt) (*poHistoryEvent)(uiNumHistory-1) + 1;
  }
  
  poHistoryEvent->resize( uiNumIndex+uiNumHistory, True );
  poHistoryIndex->resize( uiNumIndex+uiNumHistory, True );
  poHistoryFlag->resize( uiNumIndex+uiNumHistory, True );
  poHistoryInterp->resize( uiNumIndex+uiNumHistory, True );
  poHistoryY->resize( uiNumIndex+uiNumHistory, True );
  poHistoryYErr->resize( uiNumIndex+uiNumHistory, True );
  
  for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
    (*poHistoryEvent)(uiIndex+uiNumHistory) = (Int) uiEvent;
    (*poHistoryIndex)(uiIndex+uiNumHistory) = oIndex(uiIndex);
    (*poHistoryFlag)(uiIndex+uiNumHistory) = bFlagValueIn;
    (*poHistoryInterp)(uiIndex+uiNumHistory) = False;
    (*poHistoryY)(uiIndex+uiNumHistory) = 0.0;
    (*poHistoryYErr)(uiIndex+uiNumHistory) = 0.0;
    (*poFlag)(oIndex(uiIndex)) = bFlagValueIn;
    (*poInterp)(oIndex(uiIndex)) = False;
  }


  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1:interpolateX

Description:
------------
This public member function sets flags in a given x range.

Inputs:
-------
dXMinIn    - The minimum x value.
dXMaxIn    - The maximum x value.
bKeepIn    - The keep-flagged-data boolean.
oInterpIn  - The interpolation method ("CUBIC", "LINEAR", "NEAREST", "SPLINE").
dXMinBoxIn - The minimum x-box value.
dXMaxBoxIn - The maximum x-box value.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 16 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::interpolateX( Double& dXMinIn, Double& dXMaxIn, const Bool& bKeepIn,
    String& oInterpIn, Double& dXMinBoxIn, Double& dXMaxBoxIn ) {
  
  // Declare the local variables
  
  uInt uiEvent;             // The event number
  uInt uiIndex;             // The index counter
  uInt uiMethod = 0;        // The interpolation method number
  uInt uiNumHistory;        // The number of histories
  uInt uiNumIndex;          // The number of indices
  uInt uiNumIndexBox;       // The number of indices in both boxed regions
  uInt uiNumIndexHighBox;   // The number of indices in the high box region
  uInt uiNumIndexLowBox;    // The number of indices in the low box region
  
  Double dYInterp;          // The interpolated y value
  Double dYErrInterp = 0.0; // The interpolated y-error value (the average
                            // error of the boxed regions)
  
  
  // Check the inputs
  
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x value(s) (interpolation)", "GDC1",
        "interpolateX" ) );
  }
  
  if ( !checkX( dXMinBoxIn, dXMaxBoxIn ) ) {
    throw( ermsg( "Invalid x value(s) (box)", "GDC1", "interpolateX" ) );
  }
  
  if ( dXMinBoxIn >= dXMinIn || dXMaxBoxIn <= dXMaxIn ) {
    throw( ermsg( "X-box value(s) overlap interpolation value(s)", "GDC1",
        "interpolateX" ) );
  }
  
  if ( !checkInterp( oInterpIn ) ) {
    throw( ermsg( "Invalid interpolation method", "GDC1", "interpolateX" ) );
  }
  
  if ( oInterpIn.length() < 1 ) {
    throw( ermsg( "No interpolation method specified", "GDC1",
        "interpolateX" ) );
  }
  
  
  // Initialize variables and objects
  
  Vector<Int> oIndex = Vector<Int>();
  Vector<Int> oIndexBox = Vector<Int>();
  
  Vector<Int> oIndexLowBox = Vector<Int>();
  Vector<Int> oIndexHighBox = Vector<Int>();
  
  if ( oInterpIn.matches( "CUBIC" ) ) {
    uiMethod = Interpolate1D<Double,Double>::cubic;
  } else if ( oInterpIn.matches( "LINEAR" ) ) {
    uiMethod = Interpolate1D<Double,Double>::linear;
  } else if ( oInterpIn.matches( "NEAREST" ) ) {
    uiMethod = Interpolate1D<Double,Double>::nearestNeighbour;
  } else if ( oInterpIn.matches( "SPLINE" ) ) {
    uiMethod = Interpolate1D<Double,Double>::spline;
  }
  
  Vector<Double> oXTemp = Vector<Double>();
  Vector<Double> oYTemp = Vector<Double>();
  Vector<Double> oYErrTemp = Vector<Double>();
  
  ScalarSampledFunctional<Double>* poSSFX = NULL;
  ScalarSampledFunctional<Double>* poSSFY = NULL;
  
  Interpolate1D<Double,Double>* poInterpolate1D = NULL;
  
  uiNumHistory = poHistoryEvent->nelements();
  
  if ( uiNumHistory < 1 ) {
    uiEvent = 1;
  } else {
    uiEvent = (uInt) (*poHistoryEvent)(uiNumHistory-1) + 1;
  }
  
  
  // Turn off the argument checking
  
  setArgCheck( False );
  
  
  // Get the indices
  
  oIndex = index( dXMinIn, dXMaxIn, bKeepIn );

  oIndexLowBox.resize( 0, False );
  oIndexLowBox = index( dXMinBoxIn, dXMinIn, bKeepIn );
  uiNumIndexLowBox = oIndexLowBox.nelements();
    
  if ( uiNumIndexLowBox < 1 ) {
    setArgCheck( True );
    throw( ermsg( "No data in box (low)", "GDC1", "interpolateX" ) );
  }

  oIndexHighBox.resize( 0, False );
  oIndexHighBox = index( dXMaxIn, dXMaxBoxIn, bKeepIn );
  uiNumIndexHighBox = oIndexHighBox.nelements();
    
  if ( uiNumIndexHighBox < 1 ) {
    setArgCheck( True );
    throw( ermsg( "No data in box (high)", "GDC1", "interpolateX" ) );
  }

  uiNumIndexBox = oIndexBox.nelements();

  for ( uiIndex = 0; uiIndex < uiNumIndexLowBox; uiIndex++ ) {
    uiNumIndexBox += 1;
    oIndexBox.resize( uiNumIndexBox, True );
    oIndexBox(uiNumIndexBox-1) = oIndexLowBox(uiIndex);
  }

  for ( uiIndex = 0; uiIndex < uiNumIndexHighBox; uiIndex++ ) {
    uiNumIndexBox += 1;
    oIndexBox.resize( uiNumIndexBox, True );
    oIndexBox(uiNumIndexBox-1) = oIndexHighBox(uiIndex);
  }
  
  
  // Do the interpolation
  
  uiNumIndex = oIndex.nelements();
  uiNumIndexBox = oIndexBox.nelements();
   
  if ( uiNumIndex < 1 ) {
    String oMessage = "Zero-length interpolation region";
    msg( oMessage, "GDC1", "interpolateX", GeneralStatus::WARN );
  }
    
  if ( uiNumIndexBox < 1 ) {
    String oMessage = "Zero-length box region(s)";
    msg( oMessage, "GDC1", "interpolateX", GeneralStatus::WARN );
  }

  oXTemp.resize( uiNumIndexBox, False );
  oYTemp.resize( uiNumIndexBox, False );
    
  for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
    oXTemp(uiIndex) = (*poX)(oIndexBox(uiIndex));
    oYTemp(uiIndex) = (*poY)(oIndexBox(uiIndex));
  }
    
  if ( bYError ) {
    oYErrTemp.resize( uiNumIndexBox, False );
    for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
     oYErrTemp(uiIndex) = (*poYErr)(oIndexBox(uiIndex));
    }
    dYErrInterp = StatToolbox::mean( &oYErrTemp );
  }
    
  try {
    poSSFX = new ScalarSampledFunctional<Double>( oXTemp.copy() );
    poSSFY = new ScalarSampledFunctional<Double>( oYTemp.copy() );
    poInterpolate1D = new Interpolate1D<Double,Double>( *poSSFX, *poSSFY );
    poInterpolate1D->setMethod( uiMethod );
  }
    
  catch ( AipsError oAipsError ) {
    String oMessage = "Error setting up interpolation\n";
    oMessage += oAipsError.getMesg();
    msg( oMessage, "GDC1", "interpolateX", GeneralStatus::WARN );
  }
    
  for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
    try {
      dYInterp = (*poInterpolate1D)((*poX)(oIndex(uiIndex)));
    }
    catch ( AipsError oAipsError ) {
      String oMessage = "Interpolation error\n";
      oMessage += oAipsError.getMesg();
      msg( oMessage, "GDC1", "interpolateX", GeneralStatus::WARN );
      continue;
    }
    uiNumHistory += 1;
    poHistoryEvent->resize( uiNumHistory, True );
    poHistoryIndex->resize( uiNumHistory, True );
    poHistoryFlag->resize( uiNumHistory, True );
    poHistoryInterp->resize( uiNumHistory, True );
    poHistoryY->resize( uiNumHistory, True );
    poHistoryYErr->resize( uiNumHistory, True );
    (*poHistoryEvent)(uiNumHistory-1) = (Int) uiEvent;
    (*poHistoryIndex)(uiNumHistory-1) = oIndex(uiIndex);
    (*poHistoryFlag)(uiNumHistory-1) = False;
    (*poHistoryInterp)(uiNumHistory-1) = True;
    (*poHistoryY)(uiNumHistory-1) = (*poY)(oIndex(uiIndex));
    (*poY)(oIndex(uiIndex)) = dYInterp;
    if ( bYError ) {
      (*poHistoryYErr)(uiNumHistory-1) = (*poYErr)(oIndex(uiIndex));
      (*poYErr)(oIndex(uiIndex)) = dYErrInterp;
    } else {
      (*poHistoryYErr)(uiNumHistory-1) = 0.0;
    }
    (*poFlag)(oIndex(uiIndex)) = False;
    (*poInterp)(oIndex(uiIndex)) = True;
  }
    
  delete poSSFX;
  delete poSSFY;
    
  delete poInterpolate1D;
  
  
  // Turn on the argument checking
  
  setArgCheck( True );


  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1:interpolateXY

Description:
------------
This public member function sets flags in a given x-y range.

Inputs:
-------
dXMinIn    - The minimum x value.
dXMaxIn    - The maximum x value.
bKeepIn    - The keep-flagged-data boolean.
oInterpIn  - The interpolation method ("CUBIC", "LINEAR", "NEAREST", "SPLINE").
dYMinIn    - The minimum y value.
dYMaxIn    - The maximum y value.
dXMinBoxIn - The minimum x-box value.
dXMaxBoxIn - The maximum x-box value.
dYMinBoxIn - The minimum y-box value.
dYMaxBoxIn - The maximum y-box value.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 16 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::interpolateXY( Double& dXMinIn, Double& dXMaxIn, const Bool& bKeepIn,
    String& oInterpIn, Double& dYMinIn, Double& dYMaxIn, Double& dXMinBoxIn,
    Double& dXMaxBoxIn, Double& dYMinBoxIn, Double& dYMaxBoxIn ) {
  
  // Declare the local variables
  
  uInt uiEvent;             // The event number
  uInt uiIndex;             // The index counter
  uInt uiMethod = 0;        // The interpolation method number
  uInt uiNumHistory;        // The number of histories
  uInt uiNumIndex;          // The number of indices
  uInt uiNumIndexBox;       // The number of indices in both boxed regions
  uInt uiNumIndexHighBox;   // The number of indices in the high box region
  uInt uiNumIndexLowBox;    // The number of indices in the low box region
   
  Double dYInterp;          // The interpolated y value
  Double dYErrInterp = 0.0; // The interpolated y-error value (the average
                            // error of the boxed regions)
  
  
  // Check the inputs
  
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x value(s) (interpolation)", "GDC1",
        "interpolateXY" ) );
  }
  
  if ( !checkX( dXMinBoxIn, dXMaxBoxIn ) ) {
    throw( ermsg( "Invalid x value(s) (box)", "GDC1", "interpolateXY" ) );
  }
  
  if ( dXMinBoxIn >= dXMinIn || dXMaxBoxIn <= dXMaxIn ) {
    throw( ermsg( "X-box value(s) overlap interpolation value(s)", "GDC1",
        "interpolateXY" ) );
  }
  
  if ( !checkY( dYMinIn, dYMaxIn ) ) {
    throw( ermsg( "Invalid y value(s) (interpolation)", "GDC1",
        "interpolateXY" ) );
  }
  
  if ( !checkY( dYMinBoxIn, dYMaxBoxIn ) ) {
    throw( ermsg( "Invalid y value(s) (box)", "GDC1", "interpolateXY" ) );
  }
  
  if ( dYMinBoxIn > dYMinIn || dYMaxBoxIn < dYMaxIn ) {
    throw( ermsg( "Y-box value(s) overlap interpolation value(s)", "GDC1",
        "interpolateXY" ) );
  }
  
  if ( !checkInterp( oInterpIn ) ) {
    throw( ermsg( "Invalid interpolation method", "GDC1", "interpolateXY" ) );
  }
  
  if ( oInterpIn.length() < 1 ) {
    throw( ermsg( "No interpolation method specified", "GDC1",
        "interpolateXY" ) );
  }
  
  
  // Initialize variables and objects
  
  Vector<Int> oIndexTemp = Vector<Int>();
  
  Vector<Int> oIndex;
  Vector<Int> oIndexBox;
  
  Vector<Int> oIndexLowBox = Vector<Int>();
  Vector<Int> oIndexHighBox = Vector<Int>();
  
  if ( oInterpIn.matches( "CUBIC" ) ) {
    uiMethod = Interpolate1D<Double,Double>::cubic;
  } else if ( oInterpIn.matches( "LINEAR" ) ) {
    uiMethod = Interpolate1D<Double,Double>::linear;
  } else if ( oInterpIn.matches( "NEAREST" ) ) {
    uiMethod = Interpolate1D<Double,Double>::nearestNeighbour;
  } else if ( oInterpIn.matches( "SPLINE" ) ) {
    uiMethod = Interpolate1D<Double,Double>::spline;
  }
  
  Vector<Double> oXTemp = Vector<Double>();
  Vector<Double> oYTemp = Vector<Double>();
  Vector<Double> oYErrTemp = Vector<Double>();
  
  ScalarSampledFunctional<Double>* poSSFX = NULL;
  ScalarSampledFunctional<Double>* poSSFY = NULL;
  
  Interpolate1D<Double,Double>* poInterpolate1D = NULL;
  
  uiNumHistory = poHistoryEvent->nelements();
  
  if ( uiNumHistory < 1 ) {
    uiEvent = 1;
  } else {
    uiEvent = (uInt) (*poHistoryEvent)(uiNumHistory-1) + 1;
  }
  
  
  // Turn off the argument checking
  
  setArgCheck( False );
  
  
  // Get the indices
  
  oIndexTemp.resize( 0, False );
  oIndexTemp = index( dXMinIn, dXMaxIn, bKeepIn );
    
  uiNumIndex = oIndex.nelements();
    
  for ( uiIndex = 0; uiIndex < oIndexTemp.nelements(); uiIndex++ ) {
    if ( (*poY)(oIndexTemp(uiIndex)) < dYMinIn ||
         (*poY)(oIndexTemp(uiIndex)) > dYMaxIn ) {
      continue;
    }
    uiNumIndex += 1;
    oIndex.resize( uiNumIndex, True );
    oIndex(uiNumIndex-1) = oIndexTemp(uiIndex);
  }

  oIndexLowBox.resize( 0, False );
  oIndexLowBox = index( dXMinBoxIn, dXMinIn, bKeepIn );
  uiNumIndexLowBox = oIndexLowBox.nelements();
    
  if ( uiNumIndexLowBox < 1 ) {
    setArgCheck( True );
    throw( ermsg( "No data in box (low)", "GDC1", "interpolateXY" ) );
  }

  oIndexHighBox.resize( 0, False );
  oIndexHighBox = index( dXMaxIn, dXMaxBoxIn, bKeepIn );
  uiNumIndexHighBox = oIndexHighBox.nelements();
    
  if ( uiNumIndexHighBox < 1 ) {
    setArgCheck( True );
    throw( ermsg( "No data in box (high)", "GDC1", "interpolateXY" ) );
  }
 
  uiNumIndexBox = oIndexBox.nelements();

  for ( uiIndex = 0; uiIndex < uiNumIndexLowBox; uiIndex++ ) {
    if ( (*poY)(oIndexLowBox(uiIndex)) < dYMinBoxIn ) {
      continue;
    }
    uiNumIndexBox += 1;
    oIndexBox.resize( uiNumIndexBox, True );
    oIndexBox(uiNumIndexBox-1) = oIndexLowBox(uiIndex);
  }

  for ( uiIndex = 0; uiIndex < uiNumIndexHighBox; uiIndex++ ) {
    if ( (*poY)(oIndexHighBox(uiIndex)) > dYMaxBoxIn ) {
      continue;
    }
    uiNumIndexBox += 1;
    oIndexBox.resize( uiNumIndexBox, True );
    oIndexBox(uiNumIndexBox-1) = oIndexHighBox(uiIndex);
  }
  
  
  // Do the interpolation
  
  uiNumIndex = oIndex.nelements();
  uiNumIndexBox = oIndexBox.nelements();
    
  if ( uiNumIndex < 1 ) {
    String oMessage = "Zero-length interpolation region";
    msg( oMessage, "GDC1", "interpolateX", GeneralStatus::WARN );
  }
    
  if ( uiNumIndexBox < 1 ) {
    String oMessage = "Zero-length box region(s)";
    msg( oMessage, "GDC1", "interpolateX", GeneralStatus::WARN );
  }

  oXTemp.resize( uiNumIndexBox, False );
  oYTemp.resize( uiNumIndexBox, False );
    
  for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
    oXTemp(uiIndex) = (*poX)(oIndexBox(uiIndex));
    oYTemp(uiIndex) = (*poY)(oIndexBox(uiIndex));
  }
    
  if ( bYError ) {
    oYErrTemp.resize( uiNumIndexBox, False );
    for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
      oYErrTemp(uiIndex) = (*poYErr)(oIndexBox(uiIndex));
    }
    dYErrInterp = StatToolbox::mean( &oYErrTemp );
  }
    
  try {
    poSSFX = new ScalarSampledFunctional<Double>( oXTemp.copy() );
    poSSFY = new ScalarSampledFunctional<Double>( oYTemp.copy() );
    poInterpolate1D = new Interpolate1D<Double,Double>( *poSSFX, *poSSFY );
    poInterpolate1D->setMethod( uiMethod );
  }
    
  catch ( AipsError oAipsError ) {
    String oMessage = "Error setting up interpolation\n";
    oMessage += oAipsError.getMesg();
    msg( oMessage, "GDC1", "interpolateX", GeneralStatus::WARN );
  }
    
  for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
    try {
      dYInterp = (*poInterpolate1D)((*poX)(oIndex(uiIndex)));
    }
    catch ( AipsError oAipsError ) {
      String oMessage = "Interpolation error\n";
      oMessage += oAipsError.getMesg();
      msg( oMessage, "GDC1", "interpolateX", GeneralStatus::WARN );
      continue;
    }
    uiNumHistory += 1;
    poHistoryEvent->resize( uiNumHistory, True );
    poHistoryIndex->resize( uiNumHistory, True );
    poHistoryFlag->resize( uiNumHistory, True );
    poHistoryInterp->resize( uiNumHistory, True );
    poHistoryY->resize( uiNumHistory, True );
    poHistoryYErr->resize( uiNumHistory, True );
    (*poHistoryEvent)(uiNumHistory-1) = (Int) uiEvent;
    (*poHistoryIndex)(uiNumHistory-1) = oIndex(uiIndex);
    (*poHistoryFlag)(uiNumHistory-1) = False;
    (*poHistoryInterp)(uiNumHistory-1) = True;
    (*poHistoryY)(uiNumHistory-1) = (*poY)(oIndex(uiIndex));
    (*poY)(oIndex(uiIndex)) = dYInterp;
    if ( bYError ) {
      (*poHistoryYErr)(uiNumHistory-1) = (*poYErr)(oIndex(uiIndex));
      (*poYErr)(oIndex(uiIndex)) = dYErrInterp;
    } else {
      (*poHistoryYErr)(uiNumHistory-1) = 0.0;
    }
    (*poFlag)(oIndex(uiIndex)) = False;
    (*poInterp)(oIndex(uiIndex)) = True;
  }
    
  delete poSSFX;
  delete poSSFY;
    
  delete poInterpolate1D;
  
  
  // Turn on the argument checking
  
  setArgCheck( True );


  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::undoHistory

Description:
------------
This public member function undoes the histories from the most recent event.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 May 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::undoHistory( void ) {

  // Declare the local variables
  
  uInt uiEvent;      // The event number
  uInt uiHistory;    // The history counter
  uInt uiIndex;      // The index counter
  uInt uiNumHistory; // The number of histories
  
  
  // Any history?

  uiNumHistory = poHistoryEvent->nelements();
  
  if ( uiNumHistory < 1 ) {
    return;
  }
  
  
  // Undo the histories and return
  
  uiEvent = (*poHistoryEvent)(uiNumHistory-1);
  
  for ( uiHistory = uiNumHistory; uiHistory > 0; uiHistory-- ) {
    if ( (*poHistoryEvent)(uiHistory-1) != (Int) uiEvent ) {
      break;
    }
    uiIndex = (*poHistoryIndex)(uiHistory-1);
    if ( !(*poHistoryInterp)(uiHistory-1) ) {
      (*poFlag)(uiIndex) = !(*poFlag)(uiIndex);
    } else {
      (*poInterp)(uiIndex) = False;
      (*poY)(uiIndex) = (*poHistoryY)(uiHistory-1);
      if ( bYError ) {
        (*poYErr)(uiIndex) = (*poHistoryYErr)(uiHistory-1);
      }
    }
  }
  
  uiNumHistory = uiHistory;
  
  poHistoryEvent->resize( uiNumHistory, True );
  poHistoryIndex->resize( uiNumHistory, True );
  poHistoryFlag->resize( uiNumHistory, True );
  poHistoryInterp->resize( uiNumHistory, True );
  poHistoryY->resize( uiNumHistory, True );
  poHistoryYErr->resize( uiNumHistory, True );
  
  uiEvent = (*poHistoryEvent)(uiNumHistory-1);
  
  for ( uiHistory = 0; uiHistory < uiNumHistory; uiHistory++ ) {
    uiIndex = (*poHistoryIndex)(uiHistory);
    (*poFlag)(uiIndex) = (*poHistoryFlag)(uiHistory);
    (*poInterp)(uiIndex) = (*poHistoryInterp)(uiHistory);
  }
  
  
  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::resetHistory

Description:
------------
This public member function resets the histories.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 May 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::resetHistory( void ) {

  // Declare the local variables
  
  uInt uiData;       // The data counter
  uInt uiHistory;    // The history counter
  uInt uiNumData;    // The number of data
  uInt uiNumHistory; // The number of histories
  
  
  // Any history?
  
  uiNumHistory = poHistoryEvent->nelements();

  if ( uiNumHistory < 1 ) {
    return;
  }
  
  
  // Reset the flags to their original values
  
  delete poFlag;
  uiNumData = poFlagOrig->nelements();
  poFlag = new Vector<Bool>( uiNumData, False );
  
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    (*poFlag)(uiData) = (*poFlagOrig)(uiData);
  }
  
  
  // Reset y, y-error, and interpolation variables to their original values
  
  for ( uiHistory = 0; uiHistory < uiNumHistory; uiHistory++ ) {
    if ( (*poHistoryInterp)(uiHistory) ) {
      (*poY)((*poHistoryIndex)(uiHistory)) = (*poHistoryY)(uiHistory);
      if ( bYError ) {
        (*poYErr)((*poHistoryIndex)(uiHistory)) = (*poHistoryYErr)(uiHistory);
      }
      (*poInterp)((*poHistoryIndex)(uiHistory)) = False;
    }
  }
  
  
  // Reset the histories
  
  delete poHistoryEvent;
  poHistoryEvent = new Vector<Int>();
  
  delete poHistoryIndex;
  poHistoryIndex = new Vector<Int>();

  delete poHistoryFlag;
  poHistoryFlag = new Vector<Bool>();
  
  delete poHistoryInterp;
  poHistoryInterp = new Vector<Bool>();
  
  delete poHistoryY;
  poHistoryY = new Vector<Double>();
  
  delete poHistoryYErr;
  poHistoryYErr = new Vector<Double>();
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::history

Description:
------------
This public member function gets the history vectors.

Inputs:
-------
None.

Outputs:
--------
poHistoryEventIn  - The flag event numbers.
poHistoryIndexIn  - The flag indices.
poHistoryFlagIn   - The history flags.
poHistoryInterpIn - The flag interpolation booleans.
poHistoryY        - The flag old y values (before interpolation).
poHistoryYErr     - The flag old y values (before interpolation).

Modification history:
---------------------
2000 Jun 08 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::history( Vector<Int>* *poHistoryEventIn,
    Vector<Int>* *poHistoryIndexIn, Vector<Bool>* *poHistoryFlagIn,
    Vector<Bool>* *poHistoryInterpIn, Vector<Double>* *poHistoryYIn,
    Vector<Double>* *poHistoryYErrIn ) const {
    
  // Copy the flag-history vectors and return
  
  *poHistoryEventIn = new Vector<Int>( poHistoryEvent->copy() );
  *poHistoryIndexIn = new Vector<Int>( poHistoryIndex->copy() );
  *poHistoryFlagIn = new Vector<Bool>( poHistoryFlag->copy() );
  *poHistoryInterpIn = new Vector<Bool>( poHistoryInterp->copy() );
  *poHistoryYIn = new Vector<Double>( poHistoryY->copy() );
  *poHistoryYErrIn = new Vector<Double>( poHistoryYErr->copy() );
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::numEvent

Description:
------------
This public member function gets the number of events in the history.

Inputs:
-------
None.

Outputs:
--------
The number of events in the history, returned via the function value.

Modification history:
---------------------
2000 Jun 19 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt GDC1::numEvent( void ) const {
    
  // Return the number of events in the history

  if ( poHistoryEvent->nelements() > 0 ) {
    return( (*poHistoryEvent)( poHistoryEvent->nelements() - 1 ) );
  } else {
    return( 0 );
  }
  
}

// -----------------------------------------------------------------------------

/*

GDC1::postScript

Description:
------------
This public member function creates a PostScript plot with the present plot
parameters.

Inputs:
-------
oFileIn   - The file name.
oDeviceIn - The PostScript device type ("/PS", "/VPS", "/CPS", "/VCPS").
bTrans    - The size flag (T = transparency, F = publication).

Outputs:
--------
The PostScript plot.

Modification history:
---------------------
2000 Jun 05 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::postScript( String& oFileIn, const String& oDeviceIn,
    const Bool& bTrans ) {
  
  // Declare the local variables
  
  Int iQID; // The PGPLOT QID
  
  
  // Create the PostScript file and return

  oFileIn.gsub( RXwhite, "" );

  iQID = cpgopen( String(oFileIn + " " + oDeviceIn).chars() );

  if ( !bTrans ) {
    cpgpap( 8.0, 0.773 );
  }
  
  if ( iQID > 0 ) {
    try {
      plot( iQID );
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg(
          "Error while creating PostScript file\n" + oAipsError.getMesg(),
          "GDC1", "postScript" ) );
    }
  } else {
    throw( ermsg( "Could not create PostScript file", "GDC1", "postScript" ) );
  }
  
  cpgclos();
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::plot

Description:
------------
This public member function plots data to a PGPLOT device.

Inputs:
-------
iQIDIn - The PGPLOT QID.

Outputs:
--------
The plot.

Modification history:
---------------------
2000 Jun 05 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::plot( const Int& iQIDIn ) {
  
  // Declare the local variables
  
  Double dXDelta;       // The x-axis plotting margin
  Double dXMax;         // The maximum plot x-value
  Double dXMin;         // The minimum plot x-value
  Double dYDelta;       // The y-axis plotting margin
  Double dYMax;         // The maximum plot y-value
  Double dYMin;         // The minimum plot y-value
  
  Vector<Int>* poIndex; // The index vector
  
  
  // Check the inputs
  
  if ( iQIDIn < 1 ) {
    throw( ermsg( "Invalid PGPLOT device number", "GDC1", "plot" ) );
  }
  
  
  // Turn off argument checking, for speed
  
  setArgCheck( False );
  
  
  // Initialize some local variables
  
  dXMin = dXMinPlot;
  dXMax = dXMaxPlot;
  dYMin = dYMinPlot;
  dYMax = dYMaxPlot;


  // Initialize the plot
  
  cpgslct( iQIDIn );

  cpgbbuf();
  
  cpgsci( 1 );
  cpgscf( 2 );
  cpgsch( 1.25 );
  
  dXDelta = 0.05 * ( dXMax - dXMin );
  dYDelta = 0.05 * ( dYMax - dYMin );
  
  if ( !bHMS ) {
    cpgenv( (Float) dXMin-dXDelta, (Float) dXMax+dXDelta,
        (Float) dYMin-dYDelta, (Float) dYMax+dYDelta, 0, 0 );
  } else {
    cpgpage();
    cpgsvp( 0.1, 0.9, 0.1, 0.9 );
    cpgswin( (Float) dXMin-dXDelta, (Float) dXMax+dXDelta,
        (Float) dYMin-dYDelta, (Float) dYMax+dYDelta );
    cpgtbox( "BCNTHZ", 0.0, 0, "BCNT", 0.0, 0 );
  }

  cpglab( poXLabel->chars(), poYLabel->chars(), poTitle->chars() );
  
  
  // Make the plot
    
  poIndex = new Vector<Int>( index( dXMin, dXMax, bKeep ).copy() );
        
  if ( poIndex->nelements() > 1 ) {
    plotPoints( poIndex, 1 );
    if ( bLine ) {
      plotLine( poIndex, 1 );
    }
  }
    
  delete poIndex;
    
  if ( bKeep ) {
    poIndex = new Vector<Int>( flagged( dXMin, dXMax ).copy() );
    if ( poIndex->nelements() > 1 ) {
      plotPoints( poIndex, 2 );
    }
    delete poIndex;
  }
    
  poIndex = new Vector<Int>( interpolated( dXMin, dXMax ).copy() );
    
  if ( poIndex->nelements() > 1 ) {
    plotPoints( poIndex, 3 );
  }
    
  delete poIndex;
  
  
  // Finish the plot
  
  cpgebuf();
  
  
  // Turn on argument checking
  
  setArgCheck( True );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::getXMin

Description:
------------
This public member function gets the minimum plotted x value.

Inputs:
-------
bDefaultIn = The default boolean.

Outputs:
--------
The minimum plotted x value, returned via the function value.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::getXMin( const Bool& bDefaultIn ) const {

  // Return the minimum plotted x value

  if ( !bDefaultIn ) {
    return( dXMinPlot );
  } else {
    return( dXMinDefault );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1::getXMax

Description:
------------
This public member function gets the maximum plotted x value.

Inputs:
-------
bDefaultIn = The default boolean.

Outputs:
--------
The maximum plotted x value, returned via the function value.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::getXMax( const Bool& bDefaultIn ) const {

  // Return the maximum plotted x value

  if ( !bDefaultIn ) {
    return( dXMaxPlot );
  } else {
    return( dXMaxDefault );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1::getYMin

Description:
------------
This public member function gets the minimum plotted y value.

Inputs:
-------
bDefaultIn = The default boolean.

Outputs:
--------
The minimum plotted y value, returned via the function value.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::getYMin( const Bool& bDefaultIn ) const {

  // Return the minimum plotted y value
  
  if ( !bDefaultIn ) {
    return( dYMinPlot );
  } else {
    return( dYMinDefault );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1::getYMax

Description:
------------
This public member function gets the maximum plotted y value.

Inputs:
-------
bDefaultIn = The default boolean.

Outputs:
--------
The maximum plotted y value, returned via the function value.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1::getYMax( const Bool& bDefaultIn ) const {

  // Return the maximum plotted y value
  
  if ( !bDefaultIn ) {
    return( dYMaxPlot );
  } else {
    return( dYMaxDefault );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1::zoomx

Description:
------------
This public member function zooms (x) for the PGPLOT device.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jul 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::zoomx( Double& dXMinIn, Double& dXMaxIn ) {

  // Fix/check the inputs
  
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "GDC1", "zoomx" ) );
  }
  
  
  // Save the x limits and return
  
  dXMinPlot = dXMinIn;
  dXMaxPlot = dXMaxIn;

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::zoomy

Description:
------------
This public member function zooms (y) for the PGPLOT device.

Inputs:
-------
dYMinIn - The minimum y value.
dYMaxIn - The maximum y value.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jul 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::zoomy( Double& dYMinIn, Double& dYMaxIn ) {

  // Fix/check the inputs
  
  if ( !checkY( dYMinIn, dYMaxIn ) ) {
    throw( ermsg( "Invalid y value(s)", "GDC1", "zoomy" ) );
  }
  
  
  // Save the y limits and return
  
  dYMinPlot = dYMinIn;
  dYMaxPlot = dYMaxIn;

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::zoomxy

Description:
------------
This public member function zooms (x and y) for the PGPLOT device.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.
dYMinIn - The minimum y value.
dYMaxIn - The maximum y value.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 02 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::zoomxy( Double& dXMinIn, Double& dXMaxIn, Double& dYMinIn,
    Double& dYMaxIn ) {  

  // Fix/check the inputs
    
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "GDC1", "zoomxy" ) );
  }
  
  if ( !checkY( dYMinIn, dYMaxIn ) ) {
    throw( ermsg( "Invalid y value(s)", "GDC1", "zoomxy" ) );
  }
  
  
  // Save the x and y limits and return
  
  dXMinPlot = dXMinIn;
  dXMaxPlot = dXMaxIn;
  
  dYMinPlot = dYMinIn;
  dYMaxPlot = dYMaxIn;

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::fullSize

Description:
------------
This public member function returns the zoom (x and y) to full size for the
PGPLOT device.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 02 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::fullSize( void ) {
  
  // Modify the x and y limits to their default values and return

  zoomxy( dXMinDefault, dXMaxDefault, dYMinDefault, dYMaxDefault );

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::getFlag

Description:
------------
This public member function gets the flagging boolean.

Inputs:
-------
None.

Outputs:
--------
The flagging boolean, returned via the function value.

Modification history:
---------------------
2000 Jun 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1::getFlag( void ) const {

  // Return the flagging boolean
  
  return( bFlag );

}

// -----------------------------------------------------------------------------

/*

GDC1::setFlag

Description:
------------
This public member function sets the flagging boolean.

Inputs:
-------
bFlagIn - The flagging boolean.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setFlag( const Bool& bFlagIn ) {

  // Set the flagging boolean and return
  
  bFlag = bFlagIn;
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::getLine

Description:
------------
This public member function gets the plot-line boolean.

Inputs:
-------
None.

Outputs:
--------
The plot-line boolean, returned via the function value.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1::getLine( void ) const {

  // Return the plot-line boolean
  
  return( bLine );

}

// -----------------------------------------------------------------------------

/*

GDC1::setLine

Description:
------------
This public member function sets the plot-line boolean.

Inputs:
-------
bLineIn - The plot-line boolean.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setLine( const Bool& bLineIn ) {

  // Set the plot-line boolean and return
  
  bLine = bLineIn;
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::getKeep

Description:
------------
This public member function gets the keep-flag boolean.

Inputs:
-------
None.

Outputs:
--------
The keep-flag boolean, returned via the function value.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1::getKeep( void ) const {

  // Return the keep-flag boolean
  
  return( bKeep );

}

// -----------------------------------------------------------------------------

/*

GDC1::setKeep

Description:
------------
This public member function sets the keep-flag boolean (and the flagging flag,
if necessary).

Inputs:
-------
bKeepIn - The keep-flag boolean.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.
2000 Jun 13 - Nicholas Elias, USNO/NPOI
              Flagging-boolean capability added.

*/

// -----------------------------------------------------------------------------

void GDC1::setKeep( const Bool& bKeepIn ) {

  // Set the keep-flag boolean and return
  
  bKeep = bKeepIn;
  
  if ( !bKeep && !bFlag ) {
    bFlag = True;
  }
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::getXLabel

Description:
------------
This public member function gets the x-axis label.

Inputs:
-------
bDefaultIn - The default-label boolean (default = False).

Outputs:
--------
The x-axis label, returned via the function value.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC1::getXLabel( const Bool& bDefaultIn ) const {

  // Return the x-axis label
  
  if ( !bDefaultIn ) {
    return( String( *poXLabel ) );
  } else {
    return( String( *poXLabelDefault ) );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1::setXLabel (default)

Description:
------------
This public member function sets the x-axis label to its default value.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setXLabel( void ) {

  // Set the x-axis label to its default value and return
  
  if ( poXLabel != NULL ) {
    delete poXLabel;
  }
  poXLabel = new String( *poXLabelDefault );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::setXLabel (arbitrary)

Description:
------------
This public member function sets the x-axis label.

Inputs:
-------
oXLabelIn - The x-axis label.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setXLabel( const String& oXLabelIn ) {

  // Set the x-axis label and return
  
  if ( poXLabel != NULL ) {
    delete poXLabel;
  }
  poXLabel = new String( oXLabelIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::setXLabelDefault

Description:
------------
This public member function sets the default x-axis label.

Inputs:
-------
oXLabelIn - The x-axis label.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setXLabelDefault( const String& oXLabelIn ) {

  // Set the default x-axis label and return
  
  if ( poXLabelDefault != NULL ) {
    delete poXLabelDefault;
  }
  poXLabelDefault = new String( oXLabelIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::getYLabel

Description:
------------
This public member function gets the y-axis label.

Inputs:
-------
bDefaultIn - The default-label boolean (default = False).

Outputs:
--------
The y-axis label, returned via the function value.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC1::getYLabel( const Bool& bDefaultIn ) const {

  // Return the y-axis label
  
  if ( !bDefaultIn ) {
    return( String( *poYLabel ) );
  } else {
    return( String( *poYLabelDefault ) );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1::setYLabel (default)

Description:
------------
This public member function sets the y-axis label to its default value.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setYLabel( void ) {

  // Set the y-axis label to its default value and return
  
  if ( poYLabel != NULL ) {
    delete poYLabel;
  }
  poYLabel = new String( *poYLabelDefault );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::setYLabel (arbitrary)

Description:
------------
This public member function sets the y-axis label.

Inputs:
-------
oYLabelIn - The y-axis label.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setYLabel( const String& oYLabelIn ) {

  // Set the y-axis label and return
  
  if ( poYLabel != NULL ) {
    delete poYLabel;
  }
  poYLabel = new String( oYLabelIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::setYLabelDefault

Description:
------------
This public member function sets the default y-axis label.

Inputs:
-------
oYLabelIn - The y-axis label.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setYLabelDefault( const String& oYLabelIn ) {

  // Set the default y-axis label and return
  
  if ( poYLabelDefault != NULL ) {
    delete poYLabelDefault;
  }
  poYLabelDefault = new String( oYLabelIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::getTitle

Description:
------------
This public member function gets the title label.

Inputs:
-------
bDefaultIn - The default-label boolean (default = False).

Outputs:
--------
The title label, returned via the function value.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC1::getTitle( const Bool& bDefaultIn ) const {

  // Return the title label
  
  if ( !bDefaultIn ) {
    return( String( *poTitle ) );
  } else {
    return( String( *poTitleDefault ) );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1::setTitle (default)

Description:
------------
This public member function sets the title label to its default value.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setTitle( void ) {

  // Set the title label to its default value and return
  
  if ( poTitle != NULL ) {
    delete poTitle;
  }
  poTitle = new String( *poTitleDefault );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::setTitle (arbitrary)

Description:
------------
This public member function sets the title label.

Inputs:
-------
oTitleIn - The title label.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setTitle( const String& oTitleIn ) {

  // Set the title label and return
  
  if ( poTitle != NULL ) {
    delete poTitle;
  }
  poTitle = new String( oTitleIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::setTitleDefault

Description:
------------
This public member function sets the default title label.

Inputs:
-------
oTitleIn - The title label.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::setTitleDefault( const String& oTitleIn ) {

  // Set the default title label and return
  
  if ( poTitleDefault != NULL ) {
    delete poTitleDefault;
  }
  poTitleDefault = new String( oTitleIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::hms

Description:
------------
This public member function returns the HH:MM:SS boolean.

Inputs:
-------
None.

Outputs:
--------
The HH:MM:SS boolean, returned via the function value.

Modification history:
---------------------
2000 Aug 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1::hms( void ) const {

  // Return the HH:MM:SS boolean
  
  return( bHMS );

}

// -----------------------------------------------------------------------------

/*

GDC1::hmsOld

Description:
------------
This public member function returns the old HH:MM:SS boolean.

Inputs:
-------
None.

Outputs:
--------
The old HH:MM:SS boolean, returned via the function value.

Modification history:
---------------------
2001 Jan 31 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1::hmsOld( void ) const {

  // Return the old HH:MM:SS boolean
  
  return( bHMSOld );

}

// -----------------------------------------------------------------------------

/*

GDC1::version

Description:
------------
This public member function returns the GDC1{ } version.

Inputs:
-------
None.

Outputs:
--------
The GDC1{ } version, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC1::version( void ) const {

  // Return the GDC1{ } version
  
  return( String( "0.2" ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::tool

Description:
------------
This public member function returns the glish tool name (must be "gdc1").

Inputs:
-------
None.

Outputs:
--------
The glish tool name, returned via the function value.

Modification history:
---------------------
2000 Aug 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC1::tool( void ) const {

  // Return the glish tool name
  
  String oTool = className();
  oTool.downcase();
  
  return( oTool );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::checkX

Description:
------------
This public member function checks/fixes x values.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.

Outputs:
--------
dXMinIn  - The checked/fixed minimum x value.
dXMaxIn  - The checked/fixed maximum x value.
The check boolean (True = OK, False = NOT OK).

Modification history:
---------------------
2000 May 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1::checkX( Double& dXMinIn, Double& dXMaxIn ) const {

  // Declare the local variables

  Double dXMinTemp; // The temporary minimum x value
  Double dXMaxTemp; // The temporary maximum x value


  // Proceed?
  
  if ( !bArgCheck ) {
    return( True );
  }
  

  // Check/fix the x values

  dXMinTemp = dXMinIn;
  dXMaxTemp = dXMaxIn;
  
  if ( dXMinTemp < dXMinDefault ) {
    dXMinTemp = dXMinDefault;
  }
  
  if ( dXMinTemp > dXMaxDefault ) {
    return( False );
  }
  
  if ( dXMaxTemp > dXMaxDefault ) {
    dXMaxTemp = dXMaxDefault;
  }
  
  if ( dXMaxTemp < dXMinDefault ) {
    return( False );
  }

  if ( dXMinTemp > dXMaxTemp ) {
    return( False );
  }

  
  // (Re)set the input variables and return True

  dXMinIn = dXMinTemp;
  dXMaxIn = dXMaxTemp;
  
  return( True );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::checkY

Description:
------------
This public member function checks/fixes y values.

Inputs:
-------
dYMinIn - The minimum y value.
dYMaxIn - The maximum y value.

Outputs:
--------
dYMinIn - The minimum y value.
dYMaxIn - The maximum y value.
The check boolean (True = OK, False = NOT OK).

Modification history:
---------------------
2000 Jun 08 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1::checkY( Double& dYMinIn, Double& dYMaxIn ) const {

  // Declare the local variables

  Double dYMinTemp; // The temporary minimum y value
  Double dYMaxTemp; // The temporary maximum y value

  
  // Proceed?
  
  if ( !bArgCheck ) {
    return( True );
  }
  

  // Check/fix the y values

  dYMinTemp = dYMinIn;
  dYMaxTemp = dYMaxIn;
  
  if ( dYMinTemp < dYMinDefault ) {
    dYMinTemp = dYMinDefault;
  }
  
  if ( dYMinTemp > dYMaxDefault ) {
    return( False );
  }
  
  if ( dYMaxTemp > dYMaxDefault ) {
    dYMaxTemp = dYMaxDefault;
  }
  
  if ( dYMaxTemp < dYMinDefault ) {
    return( False );
  }

  if ( dYMinTemp > dYMaxTemp ) {
    return( False );
  }

  
  // (Re)set the input variables and return True

  dYMinIn = dYMinTemp;
  dYMaxIn = dYMaxTemp;
  
  return( True );
  
}

// -----------------------------------------------------------------------------

/*

GDC1::checkInterp

Description:
------------
This public member function fixes/checks the interpolation method.

Inputs:
-------
oInterpIn - The interpolation method ("", "LINEAR", "NEAREST", "CUBIC",
            "SPLINE").

Outputs:
--------
oInterpIn - The interpolation method ("", "LINEAR", "NEAREST", "CUBIC",
            "SPLINE").
The check boolean (True = OK, False = NOT OK).

Modification history:
---------------------
2000 Jun 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1::checkInterp( String& oInterpIn ) const {
  
  // Fix/check the interpolation method and return the check boolean
  
  oInterpIn.gsub( RXwhite, "" );
  oInterpIn.upcase();
  
  if ( oInterpIn.length() < 1 || oInterpIn.matches( "LINEAR" ) ||
       oInterpIn.matches( "NEAREST" ) || oInterpIn.matches( "CUBIC" ) ||
       oInterpIn.matches( "SPLINE" ) ) {
    return( True );
  } else {
    return( False );
  }
  
}

// -----------------------------------------------------------------------------

/*

GDC1::changeX

Description:
------------
This public member function changes the present x vector (and associated x-plot
values), x-error vector, and x-axis label with new versions.  NB: The length of
the new x vector must be the same as the present x vector.

Inputs:
-------
oXIn      - The new x vector.
oXErrIn   - The new x-error vector.
oXLabelIn - The new x-axis label
bHMSIn    - The HH:MM:SS boolean (default = False ).

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 24 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::changeX( const Vector<Double>& oXIn, const Vector<Double>& oXErrIn,
    const String& oXLabelIn, const Bool& bHMSIn ) {
  
  // Declare the local variables
  
  uInt uiData;       // The data(-error) counter
  uInt uiNumData;    // The number of data
  uInt uiNumDataErr; // The number of data errors;


  // Check the inputs
 
  uiNumData = poX->nelements();
  
  if ( oXIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid x vector", "GDC1", "changeX" ) );
  }
  
  uiNumDataErr = oXErrIn.nelements();
  
  if ( uiNumDataErr != 0 && uiNumDataErr != uiNumData ) {
    throw( ermsg( "Invalid x-error vector", "GDC1", "changeX" ) );
  }
  
  
  // Change the private variables
  
  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    oIndex = index( dXMinPlot, dXMaxPlot, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not get indices\n" + oAipsError.getMesg(), "GDC1",
        "changeX" ) );
  }
  
  dXMinDefault = oXIn(0);
  dXMaxDefault = oXIn(uiNumData-1);
  
  dXMinPlot = oXIn(oIndex(0));
  dXMaxPlot = oXIn(oIndex(oIndex.nelements()-1));

  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    (*poX)(uiData) = oXIn(uiData);
  }
  
  poXErr->resize( uiNumDataErr, False );
  for ( uiData = 0; uiData < uiNumDataErr; uiData++ ) {
    (*poXErr)(uiData) = oXErrIn(uiData);
  }
  
  bHMS = bHMSIn;
  
  setXLabelDefault( oXLabelIn );
  setXLabel( getXLabel( True ) );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::resetX

Description:
------------
This public member function resets the present x vector (and associated x-plot
values), x-error vector, and x-axis label to their old versions.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 24 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::resetX( void ) {
  
  // Declare the local variables
  
  uInt uiData;       // The data(-error) counter
  uInt uiNumData;    // The number of data
  uInt uiNumDataErr; // The number of data errors;
  
  
  // Change the private variables
  
  uiNumData = poXOld->nelements();
  uiNumDataErr = poXErrOld->nelements();
  
  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    oIndex = index( dXMinPlot, dXMaxPlot, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not get indices\n" + oAipsError.getMesg(), "GDC1",
        "resetX" ) );
  }
  
  dXMinDefault = (*poXOld)(0);
  dXMaxDefault = (*poXOld)(uiNumData-1);
  
  dXMinPlot = (*poXOld)(oIndex(0));
  dXMaxPlot = (*poXOld)(oIndex(oIndex.nelements()-1));
  
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    (*poX)(uiData) = (*poXOld)(uiData);
  }
  
  poXErr->resize( uiNumDataErr, False );
  for ( uiData = 0; uiData < uiNumDataErr; uiData++ ) {
    (*poXErr)(uiData) = (*poXErrOld)(uiData);
  }
  
  bHMS = bHMSOld;
  
  setXLabelDefault( *poXLabelDefaultOld );
  setXLabel( *poXLabelOld );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::className

Description:
------------
This public member function returns the class name.

Inputs:
-------
None.

Outputs:
--------
The class name, returned via the function value.

Modification history:
---------------------
2000 Apr 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC1::className( void ) const {

  // Return the class name
  
  return( String( "GDC1" ) );

}

// -----------------------------------------------------------------------------

/*

GDC1::methods

Description:
------------
This public member function returns the method names.

Inputs:
-------
None.

Outputs:
--------
The method names, returned via the function value.

Modification history:
---------------------
2000 Apr 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GDC1::methods( void ) const {

  // Return the method names
  
  Vector<String> oMethod(67);
  
  oMethod(0) = String( "fileASCII" );
  oMethod(1) = String( "getArgCheck" );
  oMethod(2) = String( "setArgCheck" );
  oMethod(3) = String( "dumpASCII" );
  oMethod(4) = String( "yInterpolate" );
  oMethod(5) = String( "length" );
  oMethod(6) = String( "x" );
  oMethod(7) = String( "y" );
  oMethod(8) = String( "xErr" );
  oMethod(9) = String( "yErr" );
  oMethod(10) = String( "xError" );
  oMethod(11) = String( "yError" );
  oMethod(12) = String( "flag" );
  oMethod(13) = String( "interp" );
  oMethod(14) = String( "index" );
  oMethod(15) = String( "xMax" );
  oMethod(16) = String( "xMin" );
  oMethod(17) = String( "yMax" );
  oMethod(18) = String( "yMin" );
  oMethod(19) = String( "xErrMax" );
  oMethod(20) = String( "xErrMin" );
  oMethod(21) = String( "yErrMax" );
  oMethod(22) = String( "yErrMin" );
  oMethod(23) = String( "flagged" );
  oMethod(24) = String( "interpolated" );
  oMethod(25) = String( "mean" );
  oMethod(26) = String( "meanErr" );
  oMethod(27) = String( "stdDev" );
  oMethod(28) = String( "variance" );
  oMethod(29) = String( "setFlagX" );
  oMethod(30) = String( "setFlagXY" );
  oMethod(31) = String( "interpolateX" );
  oMethod(32) = String( "interpolateXY" );
  oMethod(33) = String( "undoHistory" );
  oMethod(34) = String( "resetHistory" );
  oMethod(35) = String( "numEvent" );
  oMethod(36) = String( "postScript" );
  oMethod(37) = String( "getXMin" );
  oMethod(38) = String( "getXMax" );
  oMethod(39) = String( "getYMin" );
  oMethod(40) = String( "getYMax" );
  oMethod(41) = String( "zoomx" );
  oMethod(42) = String( "zoomy" );
  oMethod(43) = String( "zoomxy" );
  oMethod(44) = String( "fullSize" );
  oMethod(45) = String( "getFlag" );
  oMethod(46) = String( "setFlag" );
  oMethod(47) = String( "getLine" );
  oMethod(48) = String( "setLine" );
  oMethod(49) = String( "getKeep" );
  oMethod(50) = String( "setKeep" );
  oMethod(51) = String( "getXLabel" );
  oMethod(52) = String( "setXLabel" );
  oMethod(53) = String( "setXLabelDefault" );
  oMethod(54) = String( "getYLabel" );
  oMethod(55) = String( "setYLabel" );
  oMethod(56) = String( "setYLabelDefault" );
  oMethod(57) = String( "getTitle" );
  oMethod(58) = String( "setTitle" );
  oMethod(59) = String( "setTitleDefault" );
  oMethod(60) = String( "hms" );
  oMethod(61) = String( "id" );
  oMethod(62) = String( "version" );
  oMethod(63) = String( "tool" );
  oMethod(64) = String( "checkX" );
  oMethod(65) = String( "checkY" );
  oMethod(66) = String( "checkInterp" );

  return( oMethod );

}

// -----------------------------------------------------------------------------

/*

GDC1::noTraceMethods

Description:
------------
This public member function returns the method names that are not traced.

Inputs:
-------
None.

Outputs:
--------
The method names, returned via the function value.

Modification history:
---------------------
2000 Apr 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GDC1::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}

// -----------------------------------------------------------------------------

/*

GDC1::initialize

Description:
------------
This protected member function initializes the private variables.

Inputs:
-------
oXin    - The x vector.
oYIn    - The y vector.
oXErrIn - The x error vector. If no x errors, then the vector length should be
          0.
oYErrIn - The y error vector. If no y errors, then the vector length should be
          0.
oFlagIn - The flag vector. If no flags, then the vector length should be 0.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Protected member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::initialize( const Vector<Double>& oXIn, const Vector<Double>& oYIn,
    const Vector<Double>& oXErrIn, const Vector<Double>& oYErrIn,
    const Vector<Bool>& oFlagIn ) {
  
  // Declare the local variables
  
  uInt uiData;    // A data counter
  uInt uiNumData; // The number of data
  
  
  // Check the inputs

  uiNumData = oXIn.nelements();
  
  if ( uiNumData < 1 ) {
    throw( ermsg( "Invalid x vector", "GDC1", "initialize" ) );
  }
  
  if ( oYIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid y vector", "GDC1", "initialize" ) );
  }
  
  if ( oXErrIn.nelements() > 0 && oXErrIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid x error vector", "GDC1", "initialize" ) );
  }

  if ( oXErrIn.nelements() > 0 ) {
    if ( oXErrIn(0) != 0.0 ) {
      bXError = True;
    } else {
      bXError = False;
    }
    for ( uiData = 1; uiData < oXErrIn.nelements(); uiData++ ) {
      if ( ( oXErrIn(uiData) == 0.0 && bXError ) ||
           ( oXErrIn(uiData) != 0.0 && !bXError ) ) {
        throw( ermsg( "Invalid x error(s)", "GDC1", "initialize" ) );
      }
    }
  } else {
    bXError = False;
  }
  
  if ( oYErrIn.nelements() > 0 && oYErrIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid y error vector", "GDC1", "initialize" ) );
  }
  
  if ( oYErrIn.nelements() > 0 ) {
    if ( oYErrIn(0) != 0.0 ) {
      bYError = True;
    } else {
      bYError = False;
    }
    for ( uiData = 1; uiData < oYErrIn.nelements(); uiData++ ) {
      if ( ( oYErrIn(uiData) == 0.0 && bYError ) ||
           ( oYErrIn(uiData) != 0.0 && !bYError ) ) {
        throw( ermsg( "Invalid y error(s)", "GDC1", "initialize" ) );
      }
    }
  } else {
    bYError = False;
  }
  
  if ( oFlagIn.nelements() > 0 && oFlagIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid flag vector", "GDC1", "initialize" ) );
  }


  // Initialize the ASCII file name

  if ( poFileASCII == NULL ) {
    poFileASCII = new String();
  }
  
  
  // Initialize the Vector<T> private variables
  
  poX = new Vector<Double>( oXIn.copy() );
  poXOld = new Vector<Double>( oXIn.copy() );
  
  poYOrig = new Vector<Double>( oYIn.copy() );
  poY = new Vector<Double>( oYIn.copy() );
  
  if ( bXError ) {
    poXErr = new Vector<Double>( oXErrIn.copy() );
  } else {
    poXErr = new Vector<Double>();
  }
  poXErrOld = new Vector<Double>( poXErr->copy() );
  
  if ( bYError ) {
    poYErrOrig = new Vector<Double>( oYErrIn.copy() );
  } else {
    poYErrOrig = new Vector<Double>();
  }
  poYErr = new Vector<Double>( poYErrOrig->copy() );
  
  poFlagOrig = new Vector<Bool>( oFlagIn.copy() );
  poFlag = new Vector<Bool>( oFlagIn.copy() );
  
  poInterp = new Vector<Bool>( uiNumData, False );
  
  
  // Deal with the flag-related objects
  
  if ( poFlagOrig->nelements() < 1 ) {
    poFlagOrig->resize( uiNumData, True );
    poFlag->resize( uiNumData, True );
    for ( uiData = 0; uiData < uiNumData; uiData++ ) {
      (*poFlagOrig)(uiData) = False;
      (*poFlag)(uiData) = False;
    }
  }
  
  if ( bYError ) {
    for ( uiData = 0; uiData < poYErr->nelements(); uiData++ ) {
      if ( (*poYErr)(uiData) < 0.0 ) {
        (*poYErr)(uiData) = fabs( (*poYErr)(uiData) );
        (*poYErrOrig)(uiData) = fabs( (*poYErrOrig)(uiData) );
        (*poFlagOrig)(uiData) = True;
        (*poFlag)(uiData) = True;
      }
    }
  }
  
  
  // Sort data according to the x values
  
  Vector<Int> oSortKey = StatToolbox::sortkey( *poX );
  
  StatToolbox::sort( oSortKey, *poXOld );
  StatToolbox::sort( oSortKey, *poX );
  StatToolbox::sort( oSortKey, *poYOrig );
  StatToolbox::sort( oSortKey, *poY );
  
  if ( bXError ) {
    StatToolbox::sort( oSortKey, *poXErrOld );
    StatToolbox::sort( oSortKey, *poXErr );
  }
  if ( bYError ) {
    StatToolbox::sort( oSortKey, *poYErrOrig );
    StatToolbox::sort( oSortKey, *poYErr );
  }
  
  StatToolbox::sort( oSortKey, *poFlagOrig );
  StatToolbox::sort( oSortKey, *poFlag );
  
  
  // Initialize the flag history
  
  poHistoryEvent = new Vector<Int>();
  poHistoryIndex = new Vector<Int>();
  poHistoryFlag = new Vector<Bool>();
  poHistoryInterp = new Vector<Bool>();
  poHistoryY = new Vector<Double>();
  poHistoryYErr = new Vector<Double>();
  
  
  // Initialize the plotting limits
  
  dXMinDefault = xMin( False );
  dXMaxDefault = xMax( False );
  
  dXMinPlot = xMin( True );
  dXMaxPlot = xMax( True );

  dYMinDefault = yMin( dXMinDefault, dXMaxDefault, True, False );
  dYMaxDefault = yMax( dXMinDefault, dXMaxDefault, True, False );

  dYMinPlot = yMin( dXMinDefault, dXMaxDefault, True, True );
  dYMaxPlot = yMax( dXMinDefault, dXMaxDefault, True, True );
  
  setKeep( False );
  
  
  // Enable the argument checking

  setArgCheck( True );

  
  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::initializePlotAttrib

Description:
------------
This protected member function initializes the plotting attributes.

Inputs:
-------
bHMSIn           - The HH:MM:SS boolean.
oXLabelIn        - The x-axis label.
oYLabelIn        - The y-axis label.
oTitleIn         - The title label.
oXLabelDefaultIn - The x-axis label.
oYLabelDefaultIn - The y-axis label.
oTitleDefaultIn  - The title label.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 23 - Nicholas Elias, USNO/NPOI
              Protected member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::initializePlotAttrib( const Bool& bHMSIn, const String& oXLabelIn,
    const String& oYLabelIn, const String& oTitleIn,
    const String& oXLabelDefaultIn, const String& oYLabelDefaultIn,
    const String& oTitleDefaultIn ) {
  
  // Initialize the plotting attributes

  bHMSOld = bHMSIn;  
  bHMS = bHMSIn;
  
  setFlag( True );
  setLine( True );
  
  poXLabel = NULL;
  setXLabel( oXLabelIn );
  
  poYLabel = NULL;
  setYLabel( oYLabelIn );
  
  poTitle = NULL;
  setTitle( oTitleIn );
  
  poXLabelDefault = NULL;
  setXLabelDefault( oXLabelDefaultIn );
  
  poYLabelDefault = NULL;
  setYLabelDefault( oYLabelDefaultIn );
  
  poTitleDefault = NULL;
  setTitleDefault( oTitleDefaultIn );
  
  poXLabelOld = new String( oXLabelIn );
  poXLabelDefaultOld = new String( oXLabelDefaultIn );
  
  
  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::loadASCII

Description:
------------
This private member function loads data from an ASCII file.  NB: I'm using
functions from stdio.h because I dislike the classes in iostream.h.

Inputs:
-------
oFileIn - The ASCII file name.

Outputs:
--------
oXOut    - The x vector.
oYOut    - The y vector.
oXErrOut - The x-error vector.
oYErrOut - The y-error vector.
oFlagOut - The flag vector.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::loadASCII( String& oFileIn, Vector<Double>& oXOut,
    Vector<Double>& oYOut, Vector<Double>& oXErrOut, Vector<Double>& oYErrOut,
    Vector<Bool>& oFlagOut ) {

  // Declare the local variables

  Bool bFlag;                // The temporary flag boolean
 
  uInt uiData;               // The data counter
  uInt uiNumData;            // The number of data
  
  FILE* pmtStream;           // The data input stream
  
  Char acLine[LENGTH_MAX+1]; // The temporary line variable


  // Find the number of lines in the file (kludge, since feof does not appear
  // to work correctly under RedHat 6.1)

  oFileIn.gsub( RXwhite, "" );

  pmtStream = fopen( oFileIn.chars(), "r" );
  
  if ( pmtStream == NULL ) {
    throw( ermsg( "Invalid ASCII file", "GDC1", "loadASCII" ) );
  }

  poFileASCII = new String( oFileIn );
  
  uiNumData = 0;

  while ( !feof( pmtStream ) ) {
    fgets( acLine, LENGTH_MAX, pmtStream );
    if ( acLine[0] == '#' ) {
      continue;
    }
    uiNumData += 1;
  }

  uiNumData -= 1;
  
  fclose( pmtStream );

  if ( uiNumData < 1 ) {
    throw( ermsg( "Empty ASCII file", "GDC1", "loadASCII" ) );
  }


  // Resize the vectors

  oXOut.resize( uiNumData, True );
  oYOut.resize( uiNumData, True );
  oXErrOut.resize( uiNumData, True );
  oYErrOut.resize( uiNumData, True );
  oFlagOut.resize( uiNumData, True );

  
  // Load the data from the ASCII file

  pmtStream = fopen( oFileIn.chars(), "r" );

  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    fgets( acLine, LENGTH_MAX, pmtStream );
    if ( acLine[0] == '#' ) {
      continue;
    }
    sscanf( acLine, "%lf %lf %lf %lf %u", &oXOut(uiData),
        &oYOut(uiData), &oXErrOut(uiData), &oYErrOut(uiData), (uInt*) &bFlag );
    oFlagOut(uiData) = bFlag;
  }
  
  fclose( pmtStream );
  
  
  // Return
 
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1::plotPoints

Description:
------------
This private member function plots points to a PGPLOT device.

Inputs:
-------
poIndexIn - The data indices.
iCIIn     - The PGPLOT color index.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jul 06 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::plotPoints( const Vector<Int>* const poIndexIn,
    const Int& iCIIn ) const {

  // Declare the local variables
  
  uInt uiData;    // The data counter
  uInt uiNumData; // The number of data
  
  Float* afX;     // The plotted x vector
  Float* afXErr;  // The plotted x-error vector
  Float* afY;     // The plotted y vector
  Float* afYErr;  // The plotted y-error vector
  
  
  // Plot the points
    
  cpgsci( iCIIn );
  
  uiNumData = poIndexIn->nelements();
    
  afX = new Float [uiNumData];
  afY = new Float [uiNumData];
  
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    afX[uiData] = (Float) (*poX)((*poIndexIn)(uiData));
    afY[uiData] = (Float) (*poY)((*poIndexIn)(uiData));
  }
    
  cpgpt( uiNumData, afX, afY, 17 );

  if ( bXError ) {
    afXErr = new Float [uiNumData];
    for ( uiData = 0; uiData < uiNumData; uiData++ ) {
      afXErr[uiData] = (Float) (*poXErr)((*poIndexIn)(uiData));
    }
    cpgerrb( 5, uiNumData, afX, afY, afXErr, 1.0 );
    delete [] afXErr;
  }
    
  if ( bYError ) {
    afYErr = new Float [uiNumData];
    for ( uiData = 0; uiData < uiNumData; uiData++ ) {
      afYErr[uiData] = (Float) (*poYErr)((*poIndexIn)(uiData));
    }
    cpgerrb( 6, uiNumData, afX, afY, afYErr, 1.0 );
    delete [] afYErr;
  }
    
  delete [] afX;
  delete [] afY;


  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1::plotLine

Description:
------------
This private member function plots a line to a PGPLOT device.

Inputs:
-------
poIndexIn - The data indices.
iCIIn     - The PGPLOT color index.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jul 06 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void GDC1::plotLine( const Vector<Int>* const poIndexIn,
    const Int& iCIIn ) const {

  // Declare the local variables
  
  uInt uiData;    // The data counter
  uInt uiNumData; // The number of data
  
  Float* afX;     // The plotted x vector
  Float* afY;     // The plotted y vector
  
  
  // Plot the line
    
  cpgsci( iCIIn );
  
  uiNumData = poIndexIn->nelements();
    
  afX = new Float [uiNumData];
  afY = new Float [uiNumData];
  
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    afX[uiData] = (Float) (*poX)((*poIndexIn)(uiData));
    afY[uiData] = (Float) (*poY)((*poIndexIn)(uiData));
  }
    
  cpgline( uiNumData, afX, afY );
    
  delete [] afX;
  delete [] afY;


  // Return
  
  return;
  
}
