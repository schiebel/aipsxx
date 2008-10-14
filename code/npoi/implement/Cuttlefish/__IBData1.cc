//#__IBData1.cc is part of the Cuttlefish server
//#Copyright (C) 2001
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
//#Correspondence concerning the Cuttlefish server should be addressed as follows:
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
//# $Id: __IBData1.cc,v 19.0 2003/07/16 06:02:33 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

__IBData1.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the class for manipulating 1D input-beam data.

Public member functions:
------------------------
__IBData1 (5 versions), ~__IBData1, changeX, file, ibConfig, inputBeam,
numInputBeam, object, objectErr, resetX, scanInfo, type, typeErr, xLabelID,
xLabels, xLabelTokens, xToken, xTokenOld.

Protected member functions:
---------------------------
initialize, hdsPath.

Private member functions:
-------------------------
initMethods.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              File created with public member functions __IBData1( ) (null,
              average, clone, interpolate, and copy versions), ~__IBData1( ),
              changeX( ), file( ), ibConfig( ), inputBeam( ), numInputBeam( ),
              object( ), objectErr( ), resetX( ), scanInfo( ), type( ),
              typeErr( ), xLabelID( ), xLabels( ), xLabelTokens( ), xToken( ),
              and xTokenOld( ); and protected member functions initialize( )
              and hdsPath( ); and private member function initMethods( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/Cuttlefish/__IBData1.h> // __IBData1 class

// -----------------------------------------------------------------------------

/*

__IBData1::__IBData1 (null)

Description:
------------
This public member function constructs a __IBData1{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

__IBData1::__IBData1( void ) : GDC1Token() {}

// -----------------------------------------------------------------------------

/*

__IBData1::__IBData1 (average)

Description:
------------
This public member function constructs an __IBData1{ } object.

Inputs:
-------
oObjectIDIn - The ObjectID.
oXIn        - The x vector.
dXMinIn     - The minimum x value.
dXMaxIn     - The maximum x value.
oTokenIn    - The tokens.
bKeepIn     - The keep-flagged-data boolean.
bWeightIn   - The weight boolean.
bXCalcIn    - The recalculate-x boolean.
oInterpIn   - The interpolation method ("CUBIC", "LINEAR", "NEAREST", "SPLINE").

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

__IBData1::__IBData1( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
    Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
    const Bool& bKeepIn, const Bool& bWeightIn, const Bool& bXCalcIn,
    String& oInterpIn ) : GDC1Token( oObjectIDIn, oXIn, dXMinIn, dXMaxIn,
    oTokenIn, bKeepIn, bWeightIn, bXCalcIn, oInterpIn ) {
  
  // Declare the local variables

  uInt uiIndex;     // The index counter  
  uInt uiNumScan;   // The number of scans
  uInt uiScan;      // The scan counter
  uInt uiStartScan; // The start scan
  uInt uiStopScan;  // The stop scan
  uInt uiToken;     // The token counter
  
  Double dRAMean;   // The mean right ascension
  Double dDECMean;  // The mean declination
  
  
  // Get the pointer to the input __IBData1{ } object

  ObjectController* poObjectController = NULL;
  __IBData1* poIBData1In = NULL;
  
  try {
    poObjectController = ApplicationEnvironment::objectController();
    poIBData1In = (__IBData1*) poObjectController->getObject( oObjectIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    String oError = "Cannot get pointer for input __IBData1{ } object\n";
    oError += oAipsError.getMesg();
    throw( ermsg( oError, "__IBData1", "__IBData1" ) );
  }
  
  
  // Initialize this object
  
  Vector<String> oStarID = token( dXMinIn, dXMaxIn, oTokenIn, True );
  Vector<Double> oScanTime = x( dXMinIn, dXMaxIn, oTokenIn, True );
  
  Vector<String> oTokenTemp = Vector<String>( 1 );
  Vector<Int>* poIndex;
  
  uiStartScan = 1;
  uiStopScan = poIBData1In->scanInfo().numScan();
  
  uiNumScan = oStarID.nelements();
  Vector<Int> oScanID = Vector<Int>( uiNumScan );
  
  for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
    oScanID(uiScan) = uiScan + 1;
  }
  
  Vector<Double>* poRA;
  Vector<Double>* poDEC;
  
  Vector<Double> oRA = Vector<Double>( uiNumScan );
  Vector<Double> oDEC = Vector<Double>( uiNumScan );
  
  for ( uiToken = 0; uiToken < oTokenIn.nelements(); uiToken++ ) {
    oTokenTemp = Vector<String>( 1, oTokenIn(uiToken) );
    poRA = new Vector<Double>(
        poIBData1In->scanInfo().RA( uiStartScan, uiStopScan, oTokenTemp ) );
    poDEC = new Vector<Double>(
        poIBData1In->scanInfo().DEC( uiStartScan, uiStopScan, oTokenTemp ) );
    dRAMean = StatToolbox::mean( poRA );
    dDECMean = StatToolbox::mean( poDEC );
    poIndex = new Vector<Int>( index( dXMinIn, dXMaxIn, oTokenTemp, True ) );
    for ( uiIndex = 0; uiIndex < poIndex->nelements(); uiIndex++ ) {
      oRA((*poIndex)(uiIndex)) = dRAMean;
      oDEC((*poIndex)(uiIndex)) = dDECMean;
    }
    delete poRA;
    delete poDEC;
    delete poIndex;
  }
  
  String oFile = String( poIBData1In->file() );
  ScanInfo oScanInfo = ScanInfo( oFile, oScanID, oStarID, oScanTime, oRA,
      oDEC );
  
  String oObject = String( poIBData1In->object() );
  String oXToken = String( poIBData1In->xToken() );
  String oXTokenOld = String( poIBData1In->xTokenOld() );
  
  try {
    initialize( True, poIBData1In->ibConfig(), oScanInfo, oObject,
        poIBData1In->inputBeam(), oXToken, oXTokenOld );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg(
        "Cannot initialize __IBData1{ } object\n" + oAipsError.getMesg(),
        "__IBData1", "__IBData1" ) );
  }


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

__IBData1::__IBData1 (clone)

Description:
------------
This public member function constructs an __IBData1{ } object.

Inputs:
-------
oObjectIDIn - The ObjectID.
dXMinIn     - The minimum x value.
dXMaxIn     - The maximum x value.
oTokenIn    - The tokens.
bKeepIn     - The keep-flagged-data boolean.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

__IBData1::__IBData1( const ObjectID& oObjectIDIn, Double& dXMinIn,
    Double& dXMaxIn, Vector<String>& oTokenIn, const Bool& bKeepIn )
    : GDC1Token( oObjectIDIn, dXMinIn, dXMaxIn, oTokenIn, bKeepIn ) {
  
  // Declare the local variables

  uInt uiIndex;     // The index counter  
  uInt uiNumScan;   // The number of scans
  uInt uiStartScan; // The start scan
  uInt uiStopScan;  // The stop scan
  uInt uiToken;     // The token counter
  
  Double dRAMean;   // The mean right ascension
  Double dDECMean;  // The mean declination
  
  
  // Get the pointer to the input __IBData1{ } object

  ObjectController* poObjectController = NULL;
  __IBData1* poIBData1In = NULL;
  
  try {
    poObjectController = ApplicationEnvironment::objectController();
    poIBData1In = (__IBData1*) poObjectController->getObject( oObjectIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    String oError = "Cannot get pointer for input __IBData1{ } object\n";
    oError += oAipsError.getMesg();
    throw( ermsg( oError, "__IBData1", "__IBData1" ) );
  }
  
  
  // Initialize this object
  
  Vector<String> oStarID = token( dXMinIn, dXMaxIn, oTokenIn, True );
  Vector<Double> oScanTime = x( dXMinIn, dXMaxIn, oTokenIn, True );
  
  Vector<String> oTokenTemp = Vector<String>( 1 );
  Vector<Int>* poIndex;
  
  uiStartScan = 1;
  uiStopScan = poIBData1In->scanInfo().numScan();
  
  uiNumScan = oStarID.nelements();
  Vector<Int> oScanID =
      poIBData1In->scanInfo().scanID( uiStartScan, uiStopScan, oTokenIn );
  
  Vector<Double>* poRA;
  Vector<Double>* poDEC;
  
  Vector<Double> oRA = Vector<Double>( uiNumScan );
  Vector<Double> oDEC = Vector<Double>( uiNumScan );
  
  for ( uiToken = 0; uiToken < oTokenIn.nelements(); uiToken++ ) {
    oTokenTemp = Vector<String>( 1, oTokenIn(uiToken) );
    poRA = new Vector<Double>(
        poIBData1In->scanInfo().RA( uiStartScan, uiStopScan, oTokenTemp ) );
    poDEC = new Vector<Double>(
        poIBData1In->scanInfo().DEC( uiStartScan, uiStopScan, oTokenTemp ) );
    dRAMean = StatToolbox::mean( poRA );
    dDECMean = StatToolbox::mean( poDEC );
    poIndex = new Vector<Int>( index( dXMinIn, dXMaxIn, oTokenTemp, True ) );
    for ( uiIndex = 0; uiIndex < poIndex->nelements(); uiIndex++ ) {
      oRA((*poIndex)(uiIndex)) = dRAMean;
      oDEC((*poIndex)(uiIndex)) = dDECMean;
    }
    delete poRA;
    delete poDEC;
    delete poIndex;
  }
  
  String oFile = String( poIBData1In->file() );
  ScanInfo oScanInfo = ScanInfo( oFile, oScanID, oStarID, oScanTime, oRA,
      oDEC );
  
  String oObject = String( poIBData1In->object() );
  String oXToken = String( poIBData1In->xToken() );
  String oXTokenOld = String( poIBData1In->xTokenOld() );
  
  try {
    initialize( True, poIBData1In->ibConfig(), oScanInfo, oObject,
        poIBData1In->inputBeam(), oXToken, oXTokenOld );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg(
        "Cannot initialize __IBData1{ } object\n" + oAipsError.getMesg(),
        "__IBData1", "__IBData1" ) );
  }


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

__IBData1::__IBData1 (interpolate)

Description:
------------
This public member function constructs an __IBData1{ } object.

Inputs:
-------
oObjectIDIn - The ObjectID.
oXIn        - The x vector.
oTokenIn    - The token vector, corresponding to the x vector.
bKeepIn     - The keep-flagged-data boolean.
oInterpIn   - The interpolation method ("CUBIC", "LINEAR", "NEAREST", "SPLINE").
dXMinBoxIn  - The minimum x-box value.
dXMaxBoxIn  - The maximum x-box value.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

__IBData1::__IBData1( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, String& oInterpIn,
    Double& dXMinBoxIn, Double& dXMaxBoxIn ) : GDC1Token( oObjectIDIn, oXIn,
    oTokenIn, bKeepIn, oInterpIn, dXMinBoxIn, dXMaxBoxIn ) {
  
  // Declare the local variables

  uInt uiIndex;     // The index counter  
  uInt uiNumScan;   // The number of scans
  uInt uiScan;      // The scan counter
  uInt uiStartScan; // The start scan
  uInt uiStopScan;  // The stop scan
  uInt uiToken;     // The token counter
  
  Double dRAMean;   // The mean right ascension
  Double dDECMean;  // The mean declination
  Double dXMin;     // The minimum x-value
  Double dXMax;     // The maximum x-value
  
  
  // Get the pointer to the input __IBData1{ } object

  ObjectController* poObjectController = NULL;
  __IBData1* poIBData1In = NULL;
  
  try {
    poObjectController = ApplicationEnvironment::objectController();
    poIBData1In = (__IBData1*) poObjectController->getObject( oObjectIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    String oError = "Cannot get pointer for input __IBData1{ } object\n";
    oError += oAipsError.getMesg();
    throw( ermsg( oError, "__IBData1", "__IBData1" ) );
  }
  
  
  // Initialize this object
  
  dXMin = oXIn(0);
  dXMax = oXIn(oXIn.nelements()-1);
  
  Vector<String> oTokenTemp = Vector<String>( 1 );
  Vector<Int>* poIndex;
  
  uiStartScan = 1;
  uiStopScan = poIBData1In->scanInfo().numScan();
  
  Vector<String> oStarID = token( dXMin, dXMax, oTokenIn, True );
  Vector<Double> oScanTime = x( dXMin, dXMax, oTokenIn, True );
  
  uiNumScan = oStarID.nelements();
  Vector<Int> oScanID = Vector<Int>( uiNumScan );
  
  for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
    oScanID(uiScan) = uiScan + 1;
  }
  
  Vector<Double>* poRA;
  Vector<Double>* poDEC;
  
  Vector<Double> oRA = Vector<Double>( uiNumScan );
  Vector<Double> oDEC = Vector<Double>( uiNumScan );
  
  for ( uiToken = 0; uiToken < oTokenIn.nelements(); uiToken++ ) {
    oTokenTemp = Vector<String>( 1, oTokenIn(uiToken) );
    poRA = new Vector<Double>(
        poIBData1In->scanInfo().RA( uiStartScan, uiStopScan, oTokenTemp ) );
    poDEC = new Vector<Double>(
        poIBData1In->scanInfo().DEC( uiStartScan, uiStopScan, oTokenTemp ) );
    dRAMean = StatToolbox::mean( poRA );
    dDECMean = StatToolbox::mean( poDEC );
    poIndex = new Vector<Int>( index( dXMin, dXMax, oTokenTemp, True ) );
    for ( uiIndex = 0; uiIndex < poIndex->nelements(); uiIndex++ ) {
      oRA((*poIndex)(uiIndex)) = dRAMean;
      oDEC((*poIndex)(uiIndex)) = dDECMean;
    }
    delete poRA;
    delete poDEC;
    delete poIndex;
  }
  
  String oFile = String( poIBData1In->file() );
  ScanInfo oScanInfo = ScanInfo( oFile, oScanID, oStarID, oScanTime, oRA,
      oDEC );

  String oObject = String( poIBData1In->object() );
  String oXToken = String( poIBData1In->xToken() );
  String oXTokenOld = String( poIBData1In->xTokenOld() );
  
  try {
    initialize( True, poIBData1In->ibConfig(), oScanInfo, oObject,
        poIBData1In->inputBeam(), oXToken, oXTokenOld );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg(
        "Cannot initialize __IBData1{ } object\n" + oAipsError.getMesg(),
        "__IBData1", "__IBData1" ) );
  }


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

__IBData1::__IBData1 (copy)

Description:
------------
This public member function constructs a __IBData1{ } object.

Inputs:
-------
oIBData1In - The __IBData1{ } object.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

__IBData1::__IBData1( const __IBData1& oIBData1In )
    : GDC1Token( (const GDC1Token&) oIBData1In ) {
  
  // Initialize this object and return
  
  String oObject = String( oIBData1In.object() );
  String oXToken = String( oIBData1In.xToken() );
  String oXTokenOld = String( oIBData1In.xTokenOld() );
  
  initialize( oIBData1In.derived(), oIBData1In.ibConfig(),
      oIBData1In.scanInfo(), oObject, oIBData1In.inputBeam(), oXToken,
      oXTokenOld );
  
  return;

}

// -----------------------------------------------------------------------------

/*

__IBData1::~__IBData1

Description:
------------
This public member function destructs a __IBData1{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

__IBData1::~__IBData1( void ) {

  // Deallocate the memory
  
  delete poFile;
  
  delete poIBConfig;
  delete poScanInfo;
  
  delete poObject;
  delete poObjectErr;
  
  delete poType;
  delete poTypeErr;

  delete poXToken;
  delete poXTokenOld;

  delete poMethod;
  
  
  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

__IBData1::derived

Description:
------------
This public member function returns derived-from-file boolean.

Inputs:
-------
None.

Outputs:
--------
The derived-from-file boolean, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool __IBData1::derived( void ) const {

  // Return the derived-from-file boolean
  
  return( bDerived );

}

// -----------------------------------------------------------------------------

/*

__IBData1::file

Description:
------------
This public member function returns the file name.

Inputs:
-------
None.

Outputs:
--------
The file name, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String __IBData1::file( void ) const {

  // Return the file name
  
  return( String( *poFile ) );

}

// -----------------------------------------------------------------------------

/*

__IBData1::ibConfig

Description:
------------
This public member function returns the input-beam configuration.

Inputs:
-------
None.

Outputs:
--------
The input-beam configuration, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

IBConfig __IBData1::ibConfig( void ) const {

  // Return the input-beam configuration
  
  return( IBConfig( *poIBConfig ) );

}

// -----------------------------------------------------------------------------

/*

__IBData1::scanInfo

Description:
------------
This public member function returns the scan information.

Inputs:
-------
None.

Outputs:
--------
The scan information, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

ScanInfo __IBData1::scanInfo( void ) const {

  // Return the scan information
  
  return( ScanInfo( *poScanInfo ) );

}

// -----------------------------------------------------------------------------

/*

__IBData1::object

Description:
------------
This public member function returns the object name.

Inputs:
-------
None.

Outputs:
--------
The object name, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String __IBData1::object( void ) const {

  // Return the object name
  
  return( String( *poObject ) );

}

// -----------------------------------------------------------------------------

/*

__IBData1::objectErr

Description:
------------
This public member function returns the object-error name.

Inputs:
-------
None.

Outputs:
--------
The object-error name, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String __IBData1::objectErr( void ) const {

  // Return the object-error name
  
  return( String( *poObjectErr ) );

}

// -----------------------------------------------------------------------------

/*

__IBData1::type

Description:
------------
This public member function returns the data type.

Inputs:
-------
None.

Outputs:
--------
The data type, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String __IBData1::type( void ) const {

  // Return the data type
  
  return( String( *poType ) );

}

// -----------------------------------------------------------------------------

/*

__IBData1::typeErr

Description:
------------
This public member function returns the data-error type.

Inputs:
-------
None.

Outputs:
--------
The data-error type, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String __IBData1::typeErr( void ) const {

  // Return the data-error type
  
  return( String( *poTypeErr ) );

}

// -----------------------------------------------------------------------------

/*

__IBData1::inputBeam

Description:
------------
This public member function returns the input-beam number.

Inputs:
-------
None.

Outputs:
--------
The input-beam number, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt __IBData1::inputBeam( void ) const {

  // Return the input-beam number
  
  return( uiInputBeam );

}

// -----------------------------------------------------------------------------

/*

__IBData1::numInputBeam

Description:
------------
This public member function returns the number of input beams.

Inputs:
-------
None.

Outputs:
--------
The number of input beams, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt __IBData1::numInputBeam( void ) const {

  // Return the number of input beams
  
  return( uiNumInputBeam );

}

// -----------------------------------------------------------------------------

/*

__IBData1::xToken

Description:
------------
This public member function returns the present x-label token.

Inputs:
-------
None.

Outputs:
--------
The present x-label token, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String __IBData1::xToken( void ) const {

  return( String( *poXToken ) );

}

// -----------------------------------------------------------------------------

/*

__IBData1::xTokenOld

Description:
------------
This public member function returns the old x-label token.

Inputs:
-------
None.

Outputs:
--------
The old x-label token, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String __IBData1::xTokenOld( void ) const {

  return( String( *poXTokenOld ) );

}

// -----------------------------------------------------------------------------

/*

__IBData1::xLabelID

Description:
------------
This public member function returns the x-label ID.

Inputs:
-------
oXTokenIn - The x-label token.

Outputs:
--------
The x-label ID, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Int __IBData1::xLabelID( String& oXTokenIn ) const {

  // Declare the local variables
  
  uInt uiNumXToken; // The number of x-label tokens
  uInt uiXToken;    // The x-label token counter
  

  // Return the x-label ID
  
  oXTokenIn.gsub( RXwhite, "" );
  oXTokenIn.upcase();
  
  Vector<String> oXTokenList = xLabelTokens();
  uiNumXToken = oXTokenList.nelements();
  
  for ( uiXToken = 0; uiXToken < uiNumXToken; uiXToken++ ) {
    if ( oXTokenIn.matches( oXTokenList(uiXToken) ) ) {
      break;
    }
  }
  
  if ( uiXToken < uiNumXToken ) {
    return( (Int) uiXToken );
  } else {
    return( -1 );
  }
  
}

// -----------------------------------------------------------------------------

/*

__IBData1::xLabelTokens

Description:
------------
This public member function returns the x-label tokens.  NB: The elements must
correspond to the elements returned by xLabels().

Inputs:
-------
None.

Outputs:
--------
The x-label tokens, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> __IBData1::xLabelTokens( void ) const {

  // Return the x-label tokens
  
  Vector<String> oXTokens = Vector<String>( 5 );
  
  oXTokens(0) = String( "SECONDS" );
  oXTokens(1) = String( "HOURS" );
  oXTokens(2) = String( "HH:MM:SS" );
  oXTokens(3) = String( "SCAN" );
  oXTokens(4) = String( "SCANID" );
  
  return( oXTokens );
  
}

// -----------------------------------------------------------------------------

/*

__IBData1::xLabels

Description:
------------
This public member function returns the x labels.  NB: The elements must
correspond to the elements returned by xLabelTokens().

Inputs:
-------
None.

Outputs:
--------
The x labels, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> __IBData1::xLabels( void ) const {

  // Return the input-beam y-axis label defaults
  
  Vector<String> oXLabels = Vector<String>( 5 );
  
  oXLabels(0) = String( "Time (s)" );
  oXLabels(1) = String( "Time (h)" );
  oXLabels(2) = String( "Time (hh:mm:ss)" );
  oXLabels(3) = String( "Scan Number" );
  oXLabels(4) = String( "Scan ID Number" );
  
  return( oXLabels );
  
}

// -----------------------------------------------------------------------------

/*

__IBData1::changeX

Description:
------------
This public member function changes the present x vector (and associated x-plot
values), x-error vector, and x-axis label with new versions.

Inputs:
-------
oXTokenIn - The x-label token.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function added.

*/

// -----------------------------------------------------------------------------

void __IBData1::changeX( String& oXTokenIn ) {

  // Declare the local variables
  
  Bool bHMS;        // The HH:MM:SS boolean

  uInt uiNumScan;   // The number of scans
  uInt uiScan;      // The scan counter
  uInt uiStartScan; // The start scan
  uInt uiStopScan;  // The stop scan
  
  Int iXLabelID;    // The x-label ID
  

  // Fix/check the inputs
  
  iXLabelID = xLabelID( oXTokenIn );
  
  if ( iXLabelID < 0 ) {
    throw( ermsg( "Invalid x-label token", "__IBData1", "changeX" ) );
  }
  
  
  // Initialize variables and objects
  
  uiNumScan = scanInfo().numScan();
  
  uiStartScan = 1;
  uiStopScan = uiNumScan;
  
  Vector<String> oStarID = scanInfo().starList();
  
  Vector<Int> oXChangeInt = Vector<Int>();       // Keep compiler happy
  
  Vector<Double> oXChange = Vector<Double>();    // Keep compiler happy
  Vector<Double> oXErrChange = Vector<Double>(); // Keep compiler happy
  
  
  // Get the correct x vector
  
  switch ( iXLabelID ) {
  
    case 0: // Seconds
      bHMS = False;
      oXChange = scanInfo().scanTime( uiStartScan, uiStopScan, oStarID );
      break;
      
    case 2: // HH:MM:SS
      bHMS = True;
      oXChange = scanInfo().scanTime( uiStartScan, uiStopScan, oStarID );
      break;
    
    case 1: // Hours
      bHMS = False;
      oXChange = scanInfo().scanTime( uiStartScan, uiStopScan, oStarID );
      for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
        oXChange(uiScan) /= 3600.0;
      }
      break;
    
    case 3: // Scan
      bHMS = False;
      oXChange.resize( uiNumScan, False );
      oXChangeInt = scanInfo().scan( uiStartScan, uiStopScan, oStarID );
      for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
        oXChange(uiScan) = (Double) oXChangeInt(uiScan);
      }
      break;
    
    case 4: // Scan ID
      bHMS = False;
      oXChange.resize( uiNumScan, False );
      oXChangeInt = scanInfo().scanID( uiStartScan, uiStopScan, oStarID );
      for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
        oXChange(uiScan) = (Double) oXChangeInt(uiScan);
      }
      break;
  
  }
  
  
  // Change the x vector and return
  
  delete poXToken;
  poXToken = new String( xLabelTokens()(iXLabelID) );
  
  GDC1Token::changeX( oXChange, oXErrChange, xLabels()(iXLabelID), bHMS );
  
  return;

}

// -----------------------------------------------------------------------------

/*

__IBData1::resetX

Description:
------------
This public member function resets the present x vector (and associated x-plot
values), x-error vector, and x-axis label to the old version.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function added.

*/

// -----------------------------------------------------------------------------

void __IBData1::resetX( void ) {

  // Reset the x vector and return
  
  delete poXToken;
  poXToken = new String( *poXTokenOld );
  
  GDC1Token::resetX();
  
  return;

}

// -----------------------------------------------------------------------------

/*

__IBData1::className

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
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String __IBData1::className( void ) const {

  // Return the class name
  
  return( String( "__IBData1" ) );

}

// -----------------------------------------------------------------------------

/*

__IBData1::methods

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
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> __IBData1::methods( void ) const {

  // Return the method names

  return( Vector<String>( poMethod->copy() ) );

}

// -----------------------------------------------------------------------------

/*

__IBData1::noTraceMethods

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
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> __IBData1::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}

// -----------------------------------------------------------------------------

/*

__IBData1::runMethod

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
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult __IBData1::runMethod( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method (this class)

  switch ( uiMethod ) {

    // derived
    case 0: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = derived();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "derived( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // file
    case 1: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = file();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "file( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // object
    case 2: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = object();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "object( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // objectErr
    case 3: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = objectErr();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "objectErr( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // type
    case 4: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = type();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "type( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // typeErr
    case 5: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = typeErr();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "typeErr( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // inputBeam
    case 6: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) inputBeam();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "inputBeam( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // numInputBeam
    case 7: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) numInputBeam();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "numInputBeam( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // xToken
    case 8: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xToken();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xToken( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // xTokenOld
    case 9: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xTokenOld();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xTokenOld( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // xLabelID
    case 10: {
      Parameter<String> xtoken( oParameters, "xtoken", ParameterSet::In );
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xLabelID( xtoken() ) + 1;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xLabelID( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // xLabelTokens
    case 11: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xLabelTokens();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xLabelTokens( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // xLabels
    case 12: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = xLabels();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "xLabels( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // changeX
    case 13: {
      Parameter<String> xtoken( oParameters, "xtoken", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          changeX( xtoken() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "changeX( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

    // resetX
    case 14: {
      if ( bRunMethod ) {
        try {
          resetX();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "resetX( ) error\n" + oAipsError.getMesg(),
              "__IBData1", "runMethod" ) );
        }
      }
      return( ok() );
    }

  }
  
  
  // Parse the method parameters and run the desired method (GDC1Token{ } base
  // class)
  
  try {
    GDC1Token::runMethod( uiMethod-uiNumMethod, oParameters, bRunMethod );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in GDC1Token{ } base class\n" + oAipsError.getMesg(),
        "__IBData1", "runMethod" ) );
  }


  // Return ok( )

  return( ok() );

}

// -----------------------------------------------------------------------------

/*

__IBData1::initialize

Description:
------------
This protected member function initializes a __IBData1{ } object.

Inputs:
-------
bDerivedIn    - The derived-from-file boolean.
oIBConfigIn   - The input-beam configuration object.
oScanInfoIn   - The scan information object.
oObjectIn     - The input-beam object name.
uiInputBeamIn - The input-beam number.
oXTokenIn     - The x-label token.
oXTokenOldIn  - The old x-label token.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Protected member function created.

*/
  
// -----------------------------------------------------------------------------

void __IBData1::initialize( const Bool& bDerivedIn, const IBConfig& oIBConfigIn,
    const ScanInfo& oScanInfoIn, String& oObjectIn, const uInt& uiInputBeamIn,
    String& oXTokenIn, String& oXTokenOldIn ) {
  
  // Declare the local variables
  
  Int iIBToolID;    // The input-beam tool ID
  Int iXTokenID;    // The x-label token ID
  Int iXTokenIDOld; // The x-label token ID
    
  
  // Check the inputs
  
  oObjectIn.gsub( RXwhite, "" );
  oObjectIn.upcase();
  
  iIBToolID = oIBConfigIn.ibToolID( oObjectIn );
  if ( iIBToolID < 0 ) {
    throw( ermsg( "Invalid input-beam object name\n", "__IBData1",
        "initialize" ) );
  }
  
  if ( uiInputBeamIn > oIBConfigIn.numInputBeam() ) {
    throw( ermsg( "Invalid input-beam number\n", "__IBData1", "initialize" ) );
  }
  
  oXTokenIn.gsub( RXwhite, "" );
  oXTokenIn.upcase();
  
  iXTokenID = xLabelID( oXTokenIn );
  if ( iXTokenID < 0 ) {
    throw( ermsg( "Invalid x-label token", "__IBData1", "initialize" ) );
  }
  
  iXTokenIDOld = xLabelID( oXTokenOldIn );
  if ( iXTokenIDOld < 0 ) {
    throw( ermsg( "Invalid old x-label token", "__IBData1", "initialize" ) );
  }
  
  
  // Initialize the private variables
  
  bDerived = bDerivedIn;
  
  poFile = new String( oIBConfigIn.file() );
  
  poIBConfig = new IBConfig( oIBConfigIn );
  poScanInfo = new ScanInfo( oScanInfoIn );
  
  poObject = new String( oIBConfigIn.ibObjects()(iIBToolID) );
  poObjectErr = new String( oIBConfigIn.ibObjectErrs()(iIBToolID) );
  
  poType = new String( oIBConfigIn.ibTypes()(iIBToolID) );
  poTypeErr = new String( oIBConfigIn.ibTypeErrs()(iIBToolID) );
  
  uiInputBeam = uiInputBeamIn;
  uiNumInputBeam = oIBConfigIn.numInputBeam();
  
  poXToken = new String( xLabelTokens()(iXTokenID) );
  poXTokenOld = new String( xLabelTokens()(iXTokenIDOld) );

  initMethods();
  
  
  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

__IBData1::hdsPath

Description:
------------
This protected member function returns the HDS path.

Inputs:
-------
None.

Outputs:
--------
The HDS path, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Protected member function created.

*/

// -----------------------------------------------------------------------------

String __IBData1::hdsPath( void ) const {

  // Declare the local variables
  
  char acPath[HDSFile::SZPATH]; // The HDS path
  
  
  // Form the HDS path and return it
  
  sprintf( acPath, "DataSet.ScanData.InputBeam(%u)", inputBeam() );
  
  return( String( acPath ) );

}  

// -----------------------------------------------------------------------------

/*

__IBData1::initMethods

Description:
------------
This private member function initializes the method names.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
	      Private member function created.

*/

// -----------------------------------------------------------------------------

void __IBData1::initMethods( void ) {

  // Declare the local variables
  
  uInt uiMethodGDC;    // The GDC1Token{ } method counter
  uInt uiNumMethodGDC; // The number of methods in the GDC1Token{ } base class
  

  // Load the methods of this class into the method list
  
  uiNumMethod = 15;
  
  poMethod = new Vector<String>( uiNumMethod );
  
  (*poMethod)(0) = String( "derived" );
  (*poMethod)(1) = String( "file" );
  (*poMethod)(2) = String( "object" );
  (*poMethod)(3) = String( "objectErr" );
  (*poMethod)(4) = String( "type" );
  (*poMethod)(5) = String( "typeErr" );
  (*poMethod)(6) = String( "inputBeam" );
  (*poMethod)(7) = String( "numInputBeam" );
  (*poMethod)(8) = String( "xToken" );
  (*poMethod)(9) = String( "xTokenOld" );
  (*poMethod)(10) = String( "xLabelID" );
  (*poMethod)(11) = String( "xLabelTokens" );
  (*poMethod)(12) = String( "xLabels" );
  (*poMethod)(13) = String( "changeX" );
  (*poMethod)(14) = String( "resetX" );

  
  // Load the methods of the GDC1Token{ } base class into the method list
  
  Vector<String> oMethodGDC = Vector<String>( GDC1Token::methods() );
  
  uiNumMethodGDC = oMethodGDC.nelements();
  
  poMethod->resize( uiNumMethod+uiNumMethodGDC, True );
  
  for ( uiMethodGDC = 0; uiMethodGDC < uiNumMethodGDC; uiMethodGDC++ ) {
    (*poMethod)(uiMethodGDC+uiNumMethod) = oMethodGDC(uiMethodGDC);
  }


  // Return

  return;

}
