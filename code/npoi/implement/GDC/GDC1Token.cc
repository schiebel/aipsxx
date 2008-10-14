//#GDC1Token.cc is part of the GDC server
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
//# $Id: GDC1Token.cc,v 19.0 2003/07/16 06:03:23 aips2adm Exp $
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

GDC1Token::GDC1Token (null)

Description:
------------
This public member function constructs a GDC1Token{ } object.

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

GDC1Token::GDC1Token( void ) : GeneralStatus(), poFileASCII( NULL ) {}

// -----------------------------------------------------------------------------

/*

GDC1Token::GDC1Token (standard)

Description:
------------
This public member function constructs a GDC1Token{ } object.

Inputs:
-------
oXin         - The x vector.
oYIn         - The y vector.
oXErrIn      - The x error vector. If no x errors, then the vector length
               should be 0.
oYErrIn      - The y error vector. If no y errors, then the vector length
               should be 0.
oTokenIn     - The token vector.
oFlagIn      - The flag vector. If no flags, then the vector length should be
               0.
oTokenTypeIn - The token type (default = "").
bHMSIn       - The HH:MM:SS boolean (default = False);

Outputs:
--------
None.

Modification history:
---------------------
2000 Apr 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1Token::GDC1Token( const Vector<Double>& oXIn, const Vector<Double>& oYIn,
    const Vector<Double>& oXErrIn, const Vector<Double>& oYErrIn,
    const Vector<String>& oTokenIn, const Vector<Bool>& oFlagIn,
    const String& oTokenTypeIn, const Bool& bHMSIn ) : GeneralStatus(),
    poFileASCII( NULL ) {
  
  // Initialize the private variables
  
  try {
    initialize( oXIn, oYIn, oXErrIn, oYErrIn, oTokenIn, oFlagIn, oTokenTypeIn );
    String oXLabel = String( "X Axis" );
    String oYLabel = String( "Y Axis" );
    String oTitle = String( "Title" );
    initializePlotAttrib( bHMSIn, oXLabel, oYLabel, oTitle, oXLabel, oYLabel,
        oTitle );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC1Token{ } object\n" + oAipsError.getMesg(),
        "GDC1Token", "GDC1Token" ) );
  }
  
  
  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::GDC1Token (ASCII)

Description:
------------
This public member function constructs a GDC1Token{ } object.

Inputs:
-------
oFileIn      - The ASCII file.
oTokenTypeIn - The token type (default = "").
bHMSIn       - The HH:MM:SS boolean (default = False);

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1Token::GDC1Token( String& oFileIn, const String& oTokenTypeIn,
    const Bool& bHMSIn ) : GeneralStatus(), poFileASCII( NULL ) {

  // Initialize the objects

  Vector<Double> oXIn = Vector<Double>();
  Vector<Double> oYIn = Vector<Double>();
  Vector<Double> oXErrIn = Vector<Double>();
  Vector<Double> oYErrIn = Vector<Double>();
  Vector<String> oTokenIn = Vector<String>();
  Vector<Bool> oFlagIn = Vector<Bool>();

  
  // Load the data from the ASCII file
  
  try {
    loadASCII( oFileIn, oXIn, oYIn, oXErrIn, oYErrIn, oTokenIn, oFlagIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot load data from ASCII file\n" + oAipsError.getMesg(),
        "GDC1Token", "GDC1Token" ) );
  }
  
  
  // Initialize the private variables

  try {
    initialize( oXIn, oYIn, oXErrIn, oYErrIn, oTokenIn, oFlagIn, oTokenTypeIn );
    String oXLabel = String( "X Axis" );
    String oYLabel = String( "Y Axis" );
    String oTitle = String( "Title" );
    initializePlotAttrib( bHMSIn, oXLabel, oYLabel, oTitle, oXLabel, oYLabel,
        oTitle );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC1Token{ } object\n" + oAipsError.getMesg(),
        "GDC1Token", "GDC1Token" ) );
  }


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::GDC1Token (average)

Description:
------------
This public member function constructs a GDC1Token{ } object.

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
2000 Jun 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1Token::GDC1Token( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
    Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
    const Bool& bKeepIn, const Bool& bWeightIn, const Bool& bXCalcIn,
    String& oInterpIn ) : GeneralStatus(), poFileASCII( NULL ) {
  
  // Get the pointer to the input GDC1Token{ } object
  
  ObjectController* poObjectController = NULL;
  GDC1Token* poGDC1TokenIn = NULL;
  
  try {
    poObjectController = ApplicationEnvironment::objectController();
    poGDC1TokenIn = (GDC1Token*) poObjectController->getObject( oObjectIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    String oError = "Cannot get pointer for input GDC1Token{ } object\n";
    oError += oAipsError.getMesg();
    throw( ermsg( oError, "GDC1Token", "GDC1Token" ) );
  }
  
  
  // Initialize this object
  
  GDC1Token* poGDC1TokenAve = NULL;
  
  try {
    poGDC1TokenAve = poGDC1TokenIn->average( oXIn, dXMinIn, dXMaxIn, oTokenIn,
        bKeepIn, bWeightIn, bXCalcIn, oInterpIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not average data\n" + oAipsError.getMesg(),
        "GDC1Token", "GDC1Token" ) );
  }
  
  poFileASCII = new String( poGDC1TokenIn->fileASCII() );

  try {
    initialize(
        poGDC1TokenAve->x( dXMinIn, dXMaxIn, oTokenIn, True ),
        poGDC1TokenAve->y( dXMinIn, dXMaxIn, oTokenIn, True, False ),
        poGDC1TokenAve->xErr( dXMinIn, dXMaxIn, oTokenIn, True ),
        poGDC1TokenAve->yErr( dXMinIn, dXMaxIn, oTokenIn, True, False ),
        poGDC1TokenAve->token( dXMinIn, dXMaxIn, oTokenIn, True ),
        poGDC1TokenAve->flag( dXMinIn, dXMaxIn, oTokenIn, False ),
        poGDC1TokenAve->tokenType() );
    initializePlotAttrib( poGDC1TokenAve->hms(),
        poGDC1TokenIn->getXLabel( False ), poGDC1TokenIn->getYLabel( False ),
        poGDC1TokenIn->getTitle( False ), poGDC1TokenIn->getXLabel( True ),
        poGDC1TokenIn->getYLabel( True ), poGDC1TokenIn->getTitle( True ) );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC1Token{ } object\n" + oAipsError.getMesg(),
        "GDC1Token", "GDC1Token" ) );
  }
  
  
  // Deallocate the memory
  
  delete poGDC1TokenAve;


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::GDC1Token (clone)

Description:
------------
This public member function constructs a GDC1Token{ } object.

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
2000 Jun 21 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1Token::GDC1Token( const ObjectID& oObjectIDIn, Double& dXMinIn,
    Double& dXMaxIn, Vector<String>& oTokenIn, const Bool& bKeepIn )
    : GeneralStatus(), poFileASCII( NULL ) {
  
  // Get the pointer to the input GDC1Token{ } object

  ObjectController* poObjectController = NULL;
  GDC1Token* poGDC1TokenIn = NULL;
  
  try {
    poObjectController = ApplicationEnvironment::objectController();
    poGDC1TokenIn = (GDC1Token*) poObjectController->getObject( oObjectIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    String oError = "Cannot get pointer for input GDC1Token{ } object\n";
    oError += oAipsError.getMesg();
    throw( ermsg( oError, "GDC1Token", "GDC1Token" ) );
  }
  
  
  // Initialize this object
  
  GDC1Token* poGDC1TokenClone = NULL; // Keep compiler happy

  try {
    poGDC1TokenClone =
        poGDC1TokenIn->clone( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not clone data\n" + oAipsError.getMesg(), "GDC1Token",
        "GDC1Token" ) );
  }
  
  poFileASCII = new String( poGDC1TokenIn->fileASCII() );

  try {
    initialize(
        poGDC1TokenClone->x( dXMinIn, dXMaxIn, oTokenIn, True ),
        poGDC1TokenClone->y( dXMinIn, dXMaxIn, oTokenIn, True, False ),
        poGDC1TokenClone->xErr( dXMinIn, dXMaxIn, oTokenIn, True ),
        poGDC1TokenClone->yErr( dXMinIn, dXMaxIn, oTokenIn, True, False ),
        poGDC1TokenClone->token( dXMinIn, dXMaxIn, oTokenIn, True ),
        poGDC1TokenClone->flag( dXMinIn, dXMaxIn, oTokenIn, False ),
        poGDC1TokenClone->tokenType() );
    initializePlotAttrib( poGDC1TokenClone->hms(),
        poGDC1TokenIn->getXLabel( False ), poGDC1TokenIn->getYLabel( False ),
        poGDC1TokenIn->getTitle( False ), poGDC1TokenIn->getXLabel( True ),
        poGDC1TokenIn->getYLabel( True ), poGDC1TokenIn->getTitle( True ) );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC1Token{ } object\n" + oAipsError.getMesg(),
        "GDC1Token", "GDC1Token" ) );
  }
  
  
  // Deallocate the memory
  
  delete poGDC1TokenClone;


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::GDC1Token (interpolate)

Description:
------------
This public member function constructs a GDC1Token{ } object.

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
2000 Jun 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1Token::GDC1Token( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, String& oInterpIn,
    Double& dXMinBoxIn, Double& dXMaxBoxIn ) : GeneralStatus(),
    poFileASCII( NULL ) {
    
  // Sort the input x values and get the interpolation region limits

  Vector<Double> oX = oXIn;
  Vector<Int> oSortKey = StatToolbox::sortkey( oX );
  StatToolbox::sort( oSortKey, oX );
  
  Double dXMinIn = oX(0);
  Double dXMaxIn = oX(oX.nelements()-1);
  
  
  // Get the pointer to the input GDC1Token{ } object
  
  ObjectController* poObjectController = NULL;
  GDC1Token* poGDC1TokenIn = NULL;
  
  try {
    poObjectController = ApplicationEnvironment::objectController();
    poGDC1TokenIn = (GDC1Token*) poObjectController->getObject( oObjectIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    String oError = "Cannot get pointer for input GDC1Token{ } object\n";
    oError += oAipsError.getMesg();
    throw( ermsg( oError, "GDC1Token", "GDC1Token" ) );
  }
  
  
  // Initialize this object
  
  GDC1Token* poGDC1TokenInterp = NULL; // Keep compiler happy

  try {
    poGDC1TokenInterp = poGDC1TokenIn->interpolate( oX, oTokenIn, bKeepIn,
        oInterpIn, dXMinBoxIn, dXMaxBoxIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not interpolate data\n" + oAipsError.getMesg(),
        "GDC1Token", "GDC1Token" ) );
  }
  
  poFileASCII = new String( poGDC1TokenIn->fileASCII() );

  try {
    initialize(
        poGDC1TokenInterp->x( dXMinIn, dXMaxIn, oTokenIn, True ),
        poGDC1TokenInterp->y( dXMinIn, dXMaxIn, oTokenIn, True, False ),
        poGDC1TokenInterp->xErr( dXMinIn, dXMaxIn, oTokenIn, True ),
        poGDC1TokenInterp->yErr( dXMinIn, dXMaxIn, oTokenIn, True, False ),
        poGDC1TokenInterp->token( dXMinIn, dXMaxIn, oTokenIn, True ),
        poGDC1TokenInterp->flag( dXMinIn, dXMaxIn, oTokenIn, False ),
        poGDC1TokenInterp->tokenType() );
    initializePlotAttrib( poGDC1TokenInterp->hms(),
        poGDC1TokenIn->getXLabel( False ), poGDC1TokenIn->getYLabel( False ),
        poGDC1TokenIn->getTitle( False ), poGDC1TokenIn->getXLabel( True ),
        poGDC1TokenIn->getYLabel( True ), poGDC1TokenIn->getTitle( True ) );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC1Token{ } object\n" + oAipsError.getMesg(),
        "GDC1Token", "GDC1Token" ) );
  }
  
  
  // Deallocate the memory
  
  delete poGDC1TokenInterp;


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::GDC1Token (copy)

Description:
------------
This public member function copies a GDC1Token{ } object.

Inputs:
-------
oGDC1TokenIn - The GDC1Token{ } object.

Outputs:
--------
None.

Modification history:
---------------------
2000 Apr 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1Token::GDC1Token( const GDC1Token& oGDC1TokenIn ) : GeneralStatus(),
    poFileASCII( NULL ) {

  // Declare the local variables
  
  uInt uiNumToken; // The number of tokens
  uInt uiToken;    // The token counter
  
  
  // Initialize the private variables
  
  poFileASCII = new String( oGDC1TokenIn.fileASCII() );
  
  Double dXMin = oGDC1TokenIn.xMin( False );
  Double dXMax = oGDC1TokenIn.xMax( False );
  
  Vector<String> oTokenList = oGDC1TokenIn.tokenList();
  
  poXOld = new Vector<Double>( oGDC1TokenIn.xOld().copy() );
  poX = new Vector<Double>(
      oGDC1TokenIn.x( dXMin, dXMax, oTokenList, True ).copy() );

  poYOrig = new Vector<Double>(
      oGDC1TokenIn.y( dXMin, dXMax, oTokenList, True, True ).copy() );
  poY = new Vector<Double>(
      oGDC1TokenIn.y( dXMin, dXMax, oTokenList, True, False ).copy() );

  poXErrOld = new Vector<Double>( oGDC1TokenIn.xErrOld().copy() );
  poXErr = new Vector<Double>(
      oGDC1TokenIn.xErr( dXMin, dXMax, oTokenList, True ).copy() );

  poYErrOrig = new Vector<Double>(
      oGDC1TokenIn.yErr( dXMin, dXMax, oTokenList, True, True ).copy() );
  poYErr = new Vector<Double>(
      oGDC1TokenIn.yErr( dXMin, dXMax, oTokenList, True, False ).copy() );

  poToken = new Vector<String>(
      oGDC1TokenIn.token( dXMin, dXMax, oTokenList, True ).copy() );

  poFlagOrig = new Vector<Bool>(
      oGDC1TokenIn.flag( dXMin, dXMax, oTokenList, True ).copy() );
  poFlag = new Vector<Bool>(
      oGDC1TokenIn.flag( dXMin, dXMax, oTokenList, False ).copy() );

  poInterp = new Vector<Bool>(
      oGDC1TokenIn.interp( dXMin, dXMax, oTokenList ).copy() );
  
  poTokenType = new String( oGDC1TokenIn.tokenType() );
  
  uiNumToken = oTokenList.nelements();
  poTokenList = new Vector<String>( uiNumToken );
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
    (*poTokenList)(uiToken) = oTokenList(uiToken);
  }
  
  bXError = oGDC1TokenIn.xError();
  bYError = oGDC1TokenIn.yError();
  
  bHMSOld = oGDC1TokenIn.hmsOld();
  bHMS = oGDC1TokenIn.hms();
  
  oGDC1TokenIn.history( &poHistoryEvent, &poHistoryIndex, &poHistoryFlag,
      &poHistoryInterp, &poHistoryY, &poHistoryYErr );
  
  Vector<String> oTokenPlot = oGDC1TokenIn.getToken();
  uiNumToken = oTokenPlot.nelements();
  poTokenPlot = new Vector<String>( uiNumToken );
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
    (*poTokenPlot)(uiToken) = oTokenPlot(uiToken);
  }
  
  dXMinDefault = oGDC1TokenIn.getXMin( True );
  dXMaxDefault = oGDC1TokenIn.getXMax( True );
  dYMinDefault = oGDC1TokenIn.getYMin( True );
  dYMaxDefault = oGDC1TokenIn.getYMax( True );
  
  Double dXMinTemp = oGDC1TokenIn.getXMin();
  Double dXMaxTemp = oGDC1TokenIn.getXMax();
  Double dYMinTemp = oGDC1TokenIn.getYMin();
  Double dYMaxTemp = oGDC1TokenIn.getYMax();
  
  zoomxy( dXMinTemp, dXMaxTemp, dYMinTemp, dYMaxTemp );

  bFlag = oGDC1TokenIn.getFlag();  
  bColor = oGDC1TokenIn.getColor();
  bLine = oGDC1TokenIn.getLine();
  bKeep = oGDC1TokenIn.getKeep();
  
  poXLabelDefault = new String( oGDC1TokenIn.getXLabel( True ) );
  poYLabelDefault = new String( oGDC1TokenIn.getYLabel( True ) );
  poTitleDefault = new String( oGDC1TokenIn.getTitle( True ) );
  
  poXLabel = new String( oGDC1TokenIn.getXLabel() );
  poYLabel = new String( oGDC1TokenIn.getYLabel() );
  poTitle = new String( oGDC1TokenIn.getTitle() );
    
  poXLabelDefaultOld = new String( *poXLabelDefault );
  poXLabelOld = new String( *poXLabel );

  bArgCheck = oGDC1TokenIn.getArgCheck();
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::~GDC1Token

Description:
------------
This public member function destructs a GDC1Token{ } object.

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

GDC1Token::~GDC1Token( void ) {

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
  
  delete poToken;
  
  delete poFlagOrig;
  delete poFlag;
 
  delete poTokenType;

  delete poTokenList;

  delete poHistoryEvent;
  delete poHistoryIndex;
  delete poHistoryFlag;
  delete poHistoryInterp;
  delete poHistoryY;
  delete poHistoryYErr;
  
  delete poInterp;
  
  delete poTokenPlot;
  
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

GDC1Token::fileASCII

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

String GDC1Token::fileASCII( void ) const {

  // Return the ASCII file name
  
  return( String( *poFileASCII ) );

}

// -----------------------------------------------------------------------------

/*

GDC1Token::getArgCheck

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

Bool GDC1Token::getArgCheck( void ) const {

  // Return the check-arguments boolean
  
  return( bArgCheck );

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setArgCheck

Description:
------------
This public member function sets the check-arguments boolean, to increase
speed.  Checking is not performed in the plot( ) member function.  Also, no
checking should be perfromed when a GDC1Token{ } object is created from (and
the arguments checked in) glish.

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

void GDC1Token::setArgCheck( const Bool& bArgCheckIn ) {

  // Set the check-arguments boolean and return
  
  bArgCheck = bArgCheckIn;
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::dumpASCII

Description:
------------
This public member function dumps data to an ASCII file.  Interpolated data,
flagged in GDC1Token{ } objects, is dumped as unflagged.  NB: I'm using
functions from stdio.h because I dislike the classes in iostream.h.

Inputs:
-------
oFileIn  - The ASCII file name.
XMinIn   - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean (default = False).

Outputs:
--------
The ASCII file.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1Token::dumpASCII( String& oFileIn, Double& dXMinIn,
    Double& dXMaxIn, Vector<String>& oTokenIn, const Bool& bKeepIn ) const {

  // Declare the local variables
  
  uInt uiIndex;    // The index counter
  
  FILE* pmtStream; // The data output stream
  
  
  // Get the indices

  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "dumpASCII" ) );
  }
  

  // Open the ASCII file

  oFileIn.gsub( RXwhite, "" );
  
  pmtStream = fopen( oFileIn.chars(), "w" );
  
  if ( pmtStream == NULL ) {
    throw( ermsg( "Cannot create ASCII file", "GDC1Token", "dumpASCII" ) );
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
    fprintf( pmtStream, "%s %u %u\n", (*poToken)(oIndex(uiIndex)).chars(),
        (uInt) (*poFlag)(oIndex(uiIndex)),
        (uInt) (*poInterp)(oIndex(uiIndex)) );
  }
  
  
  // Close the ASCII file
  
  fclose( pmtStream );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::clone

Description:
------------
This public member function returns a cloned GDC1Token{ } object.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.

Outputs:
--------
The cloned GDC1Token{ } object, returned via the function value.

Modification history:
---------------------
2000 Jun 21 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1Token* GDC1Token::clone( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData;    // The data counter
  uInt uiNumData; // The number of data
  
  
  // Get the indices

  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "clone" ) );
  }
  
  
  // Initialize the Vector<> objects
  
  Vector<String> oTokenList = tokenList();
  
  Vector<Double> oXClone = Vector<Double>();
  Vector<Double> oXErrClone = Vector<Double>();
  
  Vector<Double> oYClone = Vector<Double>();
  Vector<Double> oYErrClone = Vector<Double>();
  
  Vector<String> oTokenClone = Vector<String>();
  
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

  oTokenClone.resize( uiNumData, False );
  
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    oTokenClone(uiData) = (*poToken)(oIndex(uiData));
  }

  String oTokenType = tokenType();
  
  
  // Create the cloned GDC1Token{ } object
  
  GDC1Token* poGDC1TokenClone = NULL;
  
  try {
    poGDC1TokenClone = new GDC1Token( oXClone, oYClone, oXErrClone, oYErrClone,
        oTokenClone, oFlagClone, oTokenType, bHMSOld );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg(
        "Cannot created cloned GDC1Token{ } object\n" + oAipsError.getMesg(),
        "GDC1Token", "clone" ) );
  }
  
  
  // Return the cloned GDC1Token{ } object
  
  return( poGDC1TokenClone );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::average

Description:
------------
This public member function returns an averaged GDC1Token{ } object.

Inputs:
-------
oXIn      - The x vector.
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
bKeepIn   - The keep-flagged-data boolean.
bWeightIn - The weight boolean.
bXCalcIn  - The recalculate-x boolean.
oInterpIn - The interpolation method ("CUBIC", "LINEAR", "NEAREST", "SPLINE").

Outputs:
--------
The averaged GDC1Token{ } object, returned via the function value.

Modification history:
---------------------
2000 Jun 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1Token* GDC1Token::average( const Vector<Double>& oXIn, Double& dXMinIn,
    Double& dXMaxIn, Vector<String>& oTokenIn, const Bool& bKeepIn,
    const Bool& bWeightIn, const Bool& bXCalcIn, String& oInterpIn ) {
  
  // Declare the local variables

  uInt uiAve;            // The average counter  
  uInt uiData;           // The data counter
  uInt uiIndex;          // The index counter
  uInt uiNumAve = 0;     // The number of averages
  uInt uiNumData;        // The number of data
  uInt uiNumIndex;       // The number of indices
  uInt uiNumTemp;        // The number of temporary data
  uInt uiToken;          // The token counter
  
  Double dXErrAve = 0.0; // The average x error
  Double dXMin;          // The minimum average x value
  Double dXMax;          // The maximum average x value
  Double dYErrAve;       // The average y error
  
  
  // Check the inputs
  
  uiNumData = oXIn.nelements();

  if ( uiNumData < 1 ) {
    throw( ermsg( "Invalid x vector", "GDC1Token", "average" ) );
  }
  
  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "average" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1Token", "average" ) );
  }
  
  if ( !checkInterp( oInterpIn ) ) {
    throw( ermsg( "Invalid interpolation method", "GDC1Token", "average" ) );
  }
  
  if ( oInterpIn.length() < 1 ) {
    throw( ermsg( "No interpolation method specified", "GDC1Token",
        "average" ) );
  }
  
  
  // Initialize the Vector<> objects
  
  Vector<Double> oX = Vector<Double>();
  Vector<Double> oY = Vector<Double>();
  Vector<Double> oXErr = Vector<Double>();
  Vector<Double> oYErr = Vector<Double>();
  
  Vector<String> oToken = Vector<String>( 1 );
  
  Vector<Int>* poIndex = NULL;
  
  Vector<Double> oXAve = Vector<Double>();
  Vector<Double> oYAve = Vector<Double>();
  Vector<Double> oXErrAve = Vector<Double>();
  Vector<Double> oYErrAve = Vector<Double>();
  
  Vector<String> oTokenAve = Vector<String>();
  
  Vector<Bool> oFlagAve = Vector<Bool>();
  
  Vector<Bool> oInterpAve = Vector<Bool>();
  
  Vector<Double> oXErrTemp = Vector<Double>();
  Vector<Double> oYErrTemp = Vector<Double>();
  
  
  // Turn off the argument checking
  
  setArgCheck( False );
  
  
  // Calculate the averages
  
  for ( uiToken = 0; uiToken < oTokenIn.nelements(); uiToken++ ) {
  
    oToken = Vector<String>( 1, oTokenIn(uiToken) );
    
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
    
      poIndex = new Vector<Int>( index( dXMin, dXMax, oToken, bKeepIn ) );
      uiNumIndex = poIndex->nelements();
      
      uiNumAve += 1;
      
      oXAve.resize( uiNumAve, True );
      oYAve.resize( uiNumAve, True );
      oYErrAve.resize( uiNumAve, True );
      oTokenAve.resize( uiNumAve, True );
      oInterpAve.resize( uiNumAve, True );
      
      if ( uiNumIndex < 2 ) {
        delete poIndex;
        if ( bXCalcIn ) {
          oXErrAve.resize( uiNumAve, True );
          oXAve(uiNumAve-1) = 0.5 * ( dXMin + dXMax );
        } else {
          oXAve(uiNumAve-1) = oXIn(uiData);
        }
        oTokenAve(uiNumAve-1) = oTokenIn(uiToken);
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
      
      oTokenAve(uiNumAve-1) = oTokenIn(uiToken);
      
      oInterpAve(uiNumAve-1) = False;
      
      delete poIndex;
      
    }
    
  }
  
  
  // Check if any data were averaged
  
  if ( uiNumAve < 1 ) {
    setArgCheck( True );
    throw( ermsg( "No data can be averaged with these inputs", "GDC1Token",
        "average" ) );
  }
  
  
  // Interpolate in the regions with insufficient data
  
  for ( uiToken = 0; uiToken < oTokenIn.nelements(); uiToken++ ) {
  
    oToken = Vector<String>( 1, oTokenIn(uiToken) );
    
    uiNumTemp = 0;
    for ( uiAve = 0; uiAve < uiNumAve; uiAve++ ) {
      if ( oInterpAve(uiAve) ||
           !oTokenAve(uiAve).matches( oTokenIn(uiToken) ) ) {
        continue;
      }
      uiNumTemp += 1;
    }
    if ( uiNumTemp < 1 ) {
      continue;
    }
    
    if ( bXCalcIn ) {
      uiNumTemp = 0;
      oXErrTemp.resize( 0, False );
      for ( uiAve = 0; uiAve < uiNumAve; uiAve++ ) {
        if ( oInterpAve(uiAve) ||
             !oTokenAve(uiAve).matches( oTokenIn(uiToken) ) ) {
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
      if ( oInterpAve(uiAve) ||
           !oTokenAve(uiAve).matches( oTokenIn(uiToken) ) ) {
        continue;
      }
      uiNumTemp += 1;
      oYErrTemp.resize( uiNumTemp, True );
      oYErrTemp(uiNumTemp-1) = oYErrAve(uiAve);
    }
    dYErrAve = StatToolbox::mean( &oYErrTemp, NULL );
    
    for ( uiAve = 0; uiAve < uiNumAve; uiAve++ ) {
      if ( !oInterpAve(uiAve) ||
           !oTokenAve(uiAve).matches( oTokenIn(uiToken) ) ) {
        continue;
      }
      if ( bXCalcIn ) {
        oXErrAve(uiAve) = dXErrAve;
      }
      dXMin = (*poX)(0);
      dXMax = (*poX)(poX->nelements()-1);
      oYAve(uiAve) = yInterpolate( Vector<Double>( 1, oXAve(uiAve) ),
          oToken, bKeepIn, oInterpIn, dXMin, dXMax )(0);
      oYErrAve(uiAve) = dYErrAve;
      oTokenAve(uiAve) = oTokenIn(uiToken);
    }
    
  }
  
  
  // Turn on the argument checking
  
  setArgCheck( True );
  
  
  // Create the averaged GDC1Token{ } object
  
  GDC1Token* poGDC1TokenAve = NULL;
  
  try {
    poGDC1TokenAve = new GDC1Token( oXAve, oYAve, oXErrAve, oYErrAve,
        oTokenAve, oFlagAve, *poTokenType );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg(
        "Cannot create averaged GD1Token{ } object\n" + oAipsError.getMesg(),
        "GDC1Token", "average" ) );
  }
  
  
  // Return the averaged GDC1Token{ } object
  
  return( poGDC1TokenAve );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::interpolate

Description:
------------
This public member function returns an interpolated GDC1Token{ } object.

Inputs:
-------
oXIn       - The x vector.
oTokenIn   - The tokens.
bKeepIn    - The keep-flagged-data boolean.
oInterpIn  - The interpolation method ("CUBIC", "LINEAR", "NEAREST", "SPLINE").
dXMinBoxIn - The minimum x-box value.
dXMaxBoxIn - The maximum x-box value.

Outputs:
--------
The interpolated GDC1Token{ } object, returned via the function value.

Modification history:
---------------------
2000 Jun 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC1Token* GDC1Token::interpolate( const Vector<Double>& oXIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, String& oInterpIn,
    Double& dXMinBoxIn, Double& dXMaxBoxIn ) {
  
  // Declare the local variables

  uInt uiIndex;             // An index counter (one token)
  uInt uiIndexInterp;       // An index counter (for all tokens)  
  uInt uiMethod = 0;        // The interpolation method number
  uInt uiNumIndex;          // The number of indices
  uInt uiNumIndexBox = 0;   // The number of indices in both boxed regions
  uInt uiNumToken;          // The number of tokens
  uInt uiToken;             // The token counter
  
  Double dYInterp;          // The interpolated y value
  Double dXErrInterp = 0.0; // The interpolated x-error value (the average
                            // error of the boxed regions)
  Double dYErrInterp = 0.0; // The interpolated y-error value (the average
                            // error of the boxed regions)
  
  
  // Check the inputs

  Vector<Double> oX = oXIn;
  uiNumIndex = oX.nelements();

  if ( uiNumIndex < 1 ) {
    throw( ermsg( "Invalid x vector", "GDC1Token", "interpolate" ) );
  }
  
  if ( !checkX( dXMinBoxIn, dXMaxBoxIn ) ) {
    throw( ermsg( "Invalid x value(s) (box)", "GDC1Token", "interpolate" ) );
  }
  
  Vector<Int> oSortKey = StatToolbox::sortkey( oX );
  StatToolbox::sort( oSortKey, oX );
  
  if ( dXMinBoxIn >= oX(0) || dXMaxBoxIn <= oX(uiNumIndex-1) ) {
    throw( ermsg( "X-box value(s) overlap interpolation value(s)", "GDC1Token",
        "interpolate" ) );
  }
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token(s)", "GDC1Token", "interpolate" ) );
  }
  
  if ( !checkInterp( oInterpIn ) ) {
    throw( ermsg( "Invalid interpolation method", "GDC1Token",
        "interpolate" ) );
  }
  
  if ( oInterpIn.length() < 1 ) {
    throw( ermsg( "No interpolation method specified", "GDC1Token",
        "interpolate" ) );
  }
  
  
  // Initialize variables and objects

  uiNumToken = oTokenIn.nelements();
  
  Vector<String> oTokenTemp = Vector<String>( 1 );
  
  Vector<Int> oIndexBox[uiNumToken]; // Default constructor
  
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
  Vector<Double> oXErrTemp = Vector<Double>();
  Vector<Double> oYErrTemp = Vector<Double>();
  
  ScalarSampledFunctional<Double>* poSSFX = NULL;
  ScalarSampledFunctional<Double>* poSSFY = NULL;
  
  Interpolate1D<Double,Double>* poInterpolate1D = NULL;
  
  Vector<Double> oXInterp = Vector<Double>( uiNumToken*uiNumIndex );
  Vector<Double> oYInterp = Vector<Double>( uiNumToken*uiNumIndex );
  Vector<Double> oXErrInterp = Vector<Double>( uiNumToken*uiNumIndex );
  Vector<Double> oYErrInterp = Vector<Double>( uiNumToken*uiNumIndex );
  
  Vector<String> oTokenInterp = Vector<String>( uiNumToken*uiNumIndex );
  
  Vector<Bool> oFlagInterp = Vector<Bool>( uiNumToken*uiNumIndex );
  
  
  // Turn off the argument checking
  
  setArgCheck( False );
  
  
  // Do the interpolation
  
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {

    oTokenTemp(0) = oTokenIn(uiToken);
    
    oIndexBox[uiToken] = index( dXMinBoxIn, dXMaxBoxIn, oTokenTemp, bKeepIn );
    uiNumIndexBox = oIndexBox[uiToken].nelements();
    
    if ( uiNumIndexBox < 1 ) {
      String oMessage = "Zero-length box region(s) for token = ";
      oMessage += oTokenIn(uiToken);
      msg( oMessage, "GDC1Token", "interpolate", GeneralStatus::WARN );
      continue;
    }

    oXTemp.resize( uiNumIndexBox, False );
    oYTemp.resize( uiNumIndexBox, False );
    
    for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
      oXTemp(uiIndex) = (*poX)(oIndexBox[uiToken](uiIndex));
      oYTemp(uiIndex) = (*poY)(oIndexBox[uiToken](uiIndex));
    }
    
    if ( bXError ) {
      oXErrTemp.resize( uiNumIndexBox, False );
      for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
       oXErrTemp(uiIndex) = (*poXErr)(oIndexBox[uiToken](uiIndex));
      }
      dXErrInterp = StatToolbox::mean( &oXErrTemp );
    }
    
    if ( bYError ) {
      oYErrTemp.resize( uiNumIndexBox, False );
      for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
       oYErrTemp(uiIndex) = (*poYErr)(oIndexBox[uiToken](uiIndex));
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
      String oMessage = "Error setting up interpolation for token = ";
      oMessage += oTokenIn(uiToken);
      oMessage += "\n";
      oMessage += oAipsError.getMesg();
      msg( oMessage, "GDC1Token", "interpolate", GeneralStatus::WARN );
      continue;
    }
    
    for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
      try {
        dYInterp = (*poInterpolate1D)(oX(uiIndex));
      }
      catch ( AipsError oAipsError ) {
        String oMessage = "Interpolation error for token = ";
        oMessage += oTokenIn(uiToken);
        oMessage += "\n";
        oMessage += oAipsError.getMesg();
        msg( oMessage, "GDC1Token", "interpolate", GeneralStatus::WARN );
        continue;
      }
      uiIndexInterp = ( uiToken * uiNumIndex ) + uiIndex;
      oXInterp(uiIndexInterp) = oX(uiIndex);
      oYInterp(uiIndexInterp) = dYInterp;
      if ( bXError ) {
        oXErrInterp(uiIndexInterp) = dXErrInterp;
      } else {
        oXErrInterp(uiIndexInterp) = 0.0;
      }
      if ( bYError ) {
        oYErrInterp(uiIndexInterp) = dYErrInterp;
      } else {
        oYErrInterp(uiIndexInterp) = 0.0;
      }
      oTokenInterp(uiIndexInterp) = oTokenIn(uiToken);
      oFlagInterp(uiIndexInterp) = False;
    }
    
    delete poSSFX;
    delete poSSFY;
    
    delete poInterpolate1D;
  
  }
  
  
  // Create the interpolated GDC1Token{ } object
  
  GDC1Token* poGDC1TokenInterp = NULL;
  
  try {
    poGDC1TokenInterp = new GDC1Token( oXInterp, oYInterp, oXErrInterp,
        oYErrInterp, oTokenInterp, oFlagInterp, *poTokenType );
  }
  
  catch ( AipsError oAipsError ) {
    setArgCheck( True );
    String oError = "Cannot create interpolated GDC1Token{ } object\n";
    oError += oAipsError.getMesg();
    throw( ermsg( oError, "GDC1Token", "interpolate" ) );
  }
  
  
  // Turn on the argument checking
  
  setArgCheck( True );
  
  
  // Return the interpolated GDC1Token{ } object
  
  return( poGDC1TokenInterp );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::yInterpolate

Description:
------------
This public member function returns an interpolated y-value vector.

Inputs:
-------
oXIn       - The x vector.
oTokenIn   - The tokens.
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

Vector<Double> GDC1Token::yInterpolate( const Vector<Double>& oXIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, String& oInterpIn,
    Double& dXMinBoxIn, Double& dXMaxBoxIn ) {
  
  // Declare the local variables

  uInt uiIndex;             // An index counter (one token)
  uInt uiIndexInterp;       // An index counter (for all tokens)  
  uInt uiMethod = 0;        // The interpolation method number
  uInt uiNumIndex;          // The number of indices
  uInt uiNumIndexBox = 0;   // The number of indices in both boxed regions
  uInt uiNumToken;          // The number of tokens
  uInt uiToken;             // The token counter
  
  Double dYInterp;          // The interpolated y value
  
  
  // Check the inputs
  
  Vector<Double> oX = oXIn;
  uiNumIndex = oX.nelements();

  if ( uiNumIndex < 1 ) {
    throw( ermsg( "Invalid x vector", "GDC1Token", "yInterpolate" ) );
  }
  
  if ( !checkX( dXMinBoxIn, dXMaxBoxIn ) ) {
    throw( ermsg( "Invalid x value(s) (box)", "GDC1Token", "yInterpolate" ) );
  }
  
  Vector<Int> oSortKey = StatToolbox::sortkey( oX );
  StatToolbox::sort( oSortKey, oX );
  
  if ( dXMinBoxIn >= oX(0) || dXMaxBoxIn <= oX(uiNumIndex-1) ) {
    throw( ermsg( "X-box value(s) overlap interpolation value(s)", "GDC1Token",
        "yInterpolate" ) );
  }
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token(s)", "GDC1Token", "yInterpolate" ) );
  }
  
  if ( !checkInterp( oInterpIn ) ) {
    throw( ermsg( "Invalid interpolation method", "GDC1Token",
        "yInterpolate" ) );
  }
  
  if ( oInterpIn.length() < 1 ) {
    throw( ermsg( "No interpolation method specified", "GDC1Token",
        "yInterpolate" ) );
  }
  
  
  // Initialize variables and objects
  
  uiNumToken = oTokenIn.nelements();
  
  Vector<String> oTokenTemp = Vector<String>( 1 );
  
  Vector<Int> oIndexBox[uiNumToken]; // Default constructor
  
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
  
  ScalarSampledFunctional<Double>* poSSFX = NULL;
  ScalarSampledFunctional<Double>* poSSFY = NULL;
  
  Interpolate1D<Double,Double>* poInterpolate1D = NULL;
  
  Vector<Double> oYInterp = Vector<Double>( uiNumToken*uiNumIndex );
  
  
  // Turn off the argument checking
  
  setArgCheck( False );
  
  
  // Do the interpolation
  
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
  
    oTokenTemp(0) = oTokenIn(uiToken);
    
    oIndexBox[uiToken] = index( dXMinBoxIn, dXMaxBoxIn, oTokenTemp, bKeepIn );
    uiNumIndexBox = oIndexBox[uiToken].nelements();
    
    if ( uiNumIndexBox < 1 ) {
      String oMessage = "Zero-length box region(s) for token = ";
      oMessage += oTokenIn(uiToken);
      msg( oMessage, "GDC1Token", "interpolate", GeneralStatus::WARN );
      continue;
    }

    oXTemp.resize( uiNumIndexBox, False );
    oYTemp.resize( uiNumIndexBox, False );
    
    for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
      oXTemp(uiIndex) = (*poX)(oIndexBox[uiToken](uiIndex));
      oYTemp(uiIndex) = (*poY)(oIndexBox[uiToken](uiIndex));
    }
    
    try {
      poSSFX = new ScalarSampledFunctional<Double>( oXTemp.copy() );
      poSSFY = new ScalarSampledFunctional<Double>( oYTemp.copy() );
      poInterpolate1D = new Interpolate1D<Double,Double>( *poSSFX, *poSSFY );
      poInterpolate1D->setMethod( uiMethod );
    }
    
    catch ( AipsError oAipsError ) {
      String oMessage = "Error setting up interpolation for token = ";
      oMessage += oTokenIn(uiToken);
      oMessage += "\n";
      oMessage += oAipsError.getMesg();
      msg( oMessage, "GDC1Token", "interpolate", GeneralStatus::WARN );
      continue;
    }
    
    for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
      try {
        dYInterp = (*poInterpolate1D)(oX(uiIndex));
      }
      catch ( AipsError oAipsError ) {
        String oMessage = "Interpolation error for token = ";
        oMessage += oTokenIn(uiToken);
        oMessage += "\n";
        oMessage += oAipsError.getMesg();
        msg( oMessage, "GDC1Token", "interpolate", GeneralStatus::WARN );
        continue;
      }
      uiIndexInterp = ( uiToken * uiNumIndex ) + uiIndex;
      oYInterp(uiIndexInterp) = dYInterp;
    }
    
    delete poSSFX;
    delete poSSFY;
    
    delete poInterpolate1D;
  
  }
  
  
  // Turn on the argument checking
  
  setArgCheck( True );
  
  
  // Return the interpolated y-value vector
  
  return( oYInterp );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::length

Description:
------------
This public member function returns the length.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.

Outputs:
--------
The length, returned via the function value.

Modification history:
---------------------
2000 Apr 28 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt GDC1Token::length( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn ) const {
    
  // Declare the local variables
  
  uInt uiLength = 0; // The length (keep compiler happy)
  
  
  // Determine the length and return
  
  try {
    uiLength = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn ).nelements();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "length" ) );
  }
  
  return( uiLength );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::x

Description:
------------
This public member function returns x values.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.

Outputs:
--------
The x values, returned via the function value.

Modification history:
---------------------
2000 Apr 28 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC1Token::x( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the x values and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "x" ) );
  }
  
  Vector<Double> oX = Vector<Double>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oX(uiData) = (*poX)(oIndex(uiData));
  }
  
  return( oX );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::xOld

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

Vector<Double> GDC1Token::xOld( void ) const {

  // Return the old x values
  
  return( Vector<Double>( poXOld->copy() ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::y

Description:
------------
This public member function returns y values.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.
bOrigIn  - The original-data (non-interpolated) boolean.

Outputs:
--------
The y values, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC1Token::y( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, const Bool& bOrigIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the y values and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "y" ) );
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

GDC1Token::xErr

Description:
------------
This public member function returns x errors.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.

Outputs:
--------
The x errors, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC1Token::xErr( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the x errors and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
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

GDC1Token::xErrOld

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

Vector<Double> GDC1Token::xErrOld( void ) const {

  // Return the old x errors
  
  return( Vector<Double>( poXErrOld->copy() ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::yErr

Description:
------------
This public member function returns y errors.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.
bOrigIn  - The original-data (non-interpolated) boolean.

Outputs:
--------
The y errors, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC1Token::yErr( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, const Bool& bOrigIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the y errors and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
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

GDC1Token::xError

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

Bool GDC1Token::xError( void ) const {

  // Return the x-error boolean
  
  return( bXError );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::yError

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

Bool GDC1Token::yError( void ) const {

  // Return the y-error boolean
  
  return( bYError );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::token

Description:
------------
This public member function returns tokens.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.

Outputs:
--------
The tokens, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GDC1Token::token( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the tokens and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "token" ) );
  }
  
  Vector<String> oToken = Vector<String>( oIndex.nelements() );

  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oToken(uiData) = (*poToken)(oIndex(uiData));
  }
  
  return( oToken );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::tokenType

Description:
------------
This public member function returns the token type.

Inputs:
-------
None.

Outputs:
--------
The token type, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC1Token::tokenType( void ) const {

  // Return the token type
  
  return( *poTokenType );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::tokenList

Description:
------------
This public member function returns the list of unique tokens.

Inputs:
-------
None.

Outputs:
--------
The list of unique tokens, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GDC1Token::tokenList( void ) const {

  // Return the list of unique tokens
  
  return( *poTokenList );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::flag

Description:
------------
This public member function returns flags.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bOrigIn  - The original-flag boolean.

Outputs:
--------
The flags, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Bool> GDC1Token::flag( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bOrigIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the flags and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
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

GDC1Token::interp

Description:
------------
This public member function returns interpolation booleans.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.

Outputs:
--------
The interpolation booleans, returned via the function value.

Modification history:
---------------------
2000 Aug 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Bool> GDC1Token::interp( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the interpolation booleans and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
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

GDC1Token::index

Description:
------------
This public member function returns the indices.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.

Outputs:
--------
The indices, returned via the function value.

Modification history:
---------------------
2000 Apr 28 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> GDC1Token::index( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData;     // The data counter
  uInt uiNumData;  // The number of data
  uInt uiNumIndex; // The number of indices
  uInt uiNumToken; // The number of tokens
  uInt uiToken;    // The token counter
  
  
  // Fix/check the inputs
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token argument(s)", "GDC1Token", "index" ) );
  }
  
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "GDC1Token", "index" ) );
  }
  
  
  // Find the indices and return
  
  uiNumData = poX->nelements();
  uiNumToken = oTokenIn.nelements();
  
  uiNumIndex = 0;
  Vector<Int> oIndex = Vector<Int>();
  
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
    for ( uiData = 0; uiData < uiNumData; uiData++ ) {
      if ( (*poX)(uiData) >= dXMinIn && (*poX)(uiData) <= dXMaxIn &&
           (*poToken)(uiData) == oTokenIn(uiToken) &&
           ( !(*poFlag)(uiData) || bKeepIn ) ) {
        uiNumIndex += 1;
        oIndex.resize( uiNumIndex, True );
        oIndex(uiNumIndex-1) = uiData;
      }
    }
  }

  Vector<Int> oSortKey = StatToolbox::sortkey( oIndex );
  StatToolbox::sort( oSortKey, oIndex );

  return( oIndex );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::xMax (global)

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

Double GDC1Token::xMax( const Bool& bPlotIn ) const {

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

GDC1Token::xMax (specific)

Description:
------------
This public member function returns the maximum x value.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.
bPlotIn  - The plot boolean (include x errors).

Outputs:
--------
The maximum x value, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1Token::xMax( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, const Bool& bPlotIn ) const {
  
  // Declare the local variables
  
  uInt uiData;  // The data counter
  
  Double dXMax; // The maximum x value
  
  
  // Find and return the maximum x value
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "xMax" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1Token", "xMax" ) );
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

GDC1Token::xMin (global)

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

Double GDC1Token::xMin( const Bool& bPlotIn ) const {

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

GDC1Token::xMin (specific)

Description:
------------
This public member function returns the minimum x value.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.
bPlotIn  - The plot boolean (include x errors).

Outputs:
--------
The minimum x value, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1Token::xMin( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, const Bool& bPlotIn ) const {
  
  // Declare the local variables
  
  uInt uiData;  // The data counter
  
  Double dXMin; // The minimum x value
  
  
  // Find and return the minimum x value
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "xMin" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1Token", "xMin" ) );
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

GDC1Token::yMax (global)

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

Double GDC1Token::yMax( const Bool& bPlotIn ) const {

  // Declare the local variables
  
  Double dXMax = xMax(); // The maximum x value
  Double dXMin = xMin(); // The minimum x value
  
  Double dYMax = 0;      // The maximum y value
  

  // Return the maximum y value
  
  Vector<String> oToken = Vector<String>( poTokenList->copy() );
  
  try {
    dYMax = yMax( dXMin, dXMax, oToken, bKeep, bPlotIn );
  }

  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not find maximum y value" + oAipsError.getMesg(),
        "GDC1Token", "yMax" ) );
  }
  
  return( dYMax );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::yMax (specific)

Description:
------------
This public member function returns the maximum y value.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.
bPlotIn  - The plot boolean (include y errors).

Outputs:
--------
The maximum y value, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1Token::yMax( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, const Bool& bPlotIn ) const {
  
  // Declare the local variables
  
  uInt uiData;  // The data counter
  
  Double dYMax; // The maximum y value
  
  
  // Find and return the maximum y value
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "yMax" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1Token", "yMax" ) );
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

GDC1Token::yMin (global)

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

Double GDC1Token::yMin( const Bool& bPlotIn ) const {

  // Declare the local variables
  
  Double dXMax = xMax(); // The maximum x value
  Double dXMin = xMin(); // The minimum x value
  
  Double dYMin = 0;      // The minimum y value
  

  // Return the minimum y value
  
  Vector<String> oToken = Vector<String>( poTokenList->copy() );
  
  try {
    dYMin = yMin( dXMin, dXMax, oToken, bKeep, bPlotIn );
  }

  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not find minimum y value" + oAipsError.getMesg(),
        "GDC1Token", "yMin" ) );
  }
  
  return( dYMin );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::yMin (specific)

Description:
------------
This public member function returns the minimum y value.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean).
bPlotIn  - The plot boolean (include y errors).

Outputs:
--------
The minimum y value, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1Token::yMin( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, const Bool& bPlotIn ) const {
  
  // Declare the local variables
  
  uInt uiData;  // The data counter
  
  Double dYMin; // The minimum y value
  
  
  // Find and return the minimum y value
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "yMin" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1Token", "yMin" ) );
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

GDC1Token::xErrMax (global)

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

Double GDC1Token::xErrMax( void ) const {

  // Return the maximum x error
  
  Double dXMin = xMin();
  Double dXMax = xMax();
  
  Vector<String> oToken = poTokenList->copy();
  
  return( xErrMax( dXMin, dXMax, oToken, bKeep ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::xErrMax (specific)

Description:
------------
This public member function returns the maximum x error.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.

Outputs:
--------
The maximum x error, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1Token::xErrMax( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find and return the maximum x error
  
  if ( !bXError ) {
    throw( ermsg( "No x errors", "GDC1Token", "xErrMax" ) );
  }
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "xErrMax" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1Token", "xErrMax" ) );
  }
  
  Vector<Double> oXErr = Vector<Double>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oXErr(uiData) = (*poXErr)(oIndex(uiData));
  }
  
  return( StatToolbox::max( &oXErr, NULL ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::xErrMin (global)

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

Double GDC1Token::xErrMin( void ) const {

  // Return the minimum x error
  
  Double dXMin = xMin();
  Double dXMax = xMax();
  
  Vector<String> oToken = poTokenList->copy();
  
  return( xErrMin( dXMin, dXMax, oToken, bKeep ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::xErrMin (specific)

Description:
------------
This public member function returns the minimum x error.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.

Outputs:
--------
The minimum x error, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1Token::xErrMin( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find and return the maximum x error
  
  if ( !bXError ) {
    throw( ermsg( "No x errors", "GDC1Token", "xErrMin" ) );
  }
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "xErrMin" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1Token", "xErrMin" ) );
  }
  
  Vector<Double> oXErr = Vector<Double>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oXErr(uiData) = (*poXErr)(oIndex(uiData));
  }
  
  return( StatToolbox::min( &oXErr, NULL ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::yErrMax (global)

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

Double GDC1Token::yErrMax( void ) const {

  // Return the maximum y error
  
  Double dXMin = xMin();
  Double dXMax = xMax();
  
  Vector<String> oToken = poTokenList->copy();
  
  return( yErrMax( dXMin, dXMax, oToken, bKeep ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::yErrMax (specific)

Description:
------------
This public member function returns the maximum y error.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.

Outputs:
--------
The maximum y error, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1Token::yErrMax( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find and return the maximum y error
  
  if ( !bYError ) {
    throw( ermsg( "No y errors", "GDC1Token", "yErrMax" ) );
  }
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "yErrMax" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1Token", "yErrMax" ) );
  }
  
  Vector<Double> oYErr = Vector<Double>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oYErr(uiData) = (*poYErr)(oIndex(uiData));
  }
  
  return( StatToolbox::max( &oYErr, NULL ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::yErrMin (global)

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

Double GDC1Token::yErrMin( void ) const {

  // Return the minimum y error
  
  Double dXMin = xMin();
  Double dXMax = xMax();
  
  Vector<String> oToken = poTokenList->copy();
  
  return( yErrMin( dXMin, dXMax, oToken, bKeep ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::yErrMin (specific)

Description:
------------
This public member function returns the minimum y error.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.
bKeepIn  - The keep-flagged-data boolean.

Outputs:
--------
The minimum y error, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC1Token::yErrMin( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find and return the maximum y error
  
  if ( !bYError ) {
    throw( ermsg( "No y errors", "GDC1Token", "yErrMin" ) );
  }
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
        "yErrMin" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1Token", "yErrMin" ) );
  }
  
  Vector<Double> oYErr = Vector<Double>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oYErr(uiData) = (*poYErr)(oIndex(uiData));
  }
  
  return( StatToolbox::min( &oYErr, NULL ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::flagged

Description:
------------
This public member function returns flagged data indices.

Inputs:
-------
dXMinIn    - The minimum x value.
dXMaxIn    - The maximum x value.
oTokenIn   - The tokens.

Outputs:
--------
The flagged data indices, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> GDC1Token::flagged( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn ) const {
  
  // Declare the local variables
  
  uInt uiIndex;        // The index counter
  uInt uiNumIndex;     // The number of indices
  uInt uiNumIndexFlag; // The number of True booleans
  
  
  // Find the flagged data indices and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
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

GDC1Token::interpolated

Description:
------------
This public member function returns interpolated data indices.

Inputs:
-------
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.

Outputs:
--------
The interpolated data indices, returned via the function value.

Modification history:
---------------------
2000 Jul 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> GDC1Token::interpolated( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn ) const {
  
  // Declare the local variables
  
  uInt uiIndex;          // The index counter
  uInt uiNumIndex;       // The number of indices
  uInt uiNumIndexInterp; // The number of True booleans
  
  
  // Find the interpolated data indices and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, False );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
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

GDC1Token::mean

Description:
------------
This public member function returns the mean y value.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
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

Double GDC1Token::mean( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn,
    const Bool& bWeightIn ) const {
  
  // Declare the local variables
  
  Double dMean; // The mean y value
  
  
  // Find and return the mean y value
  
  Vector<Double> oY = Vector<Double>(); // Keep compiler happy
  
  try {
    oY = y( dXMinIn, dXMaxIn, oTokenIn, bKeepIn, False ).copy();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in y( )\n" + oAipsError.getMesg(), "GDC1Token",
        "mean" ) );
  }
  
  if ( oY.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC1Token", "mean" ) );
  }
  
  if ( !bWeightIn || !bYError ) {
    dMean = StatToolbox::mean( &oY, NULL );
  } else {
    Vector<Double> oYErr = Vector<Double>(); // Keep compiler happy
    try {
      oYErr = yErr( dXMinIn, dXMaxIn, oTokenIn, bKeepIn, False ).copy();
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in yErr( )\n" + oAipsError.getMesg(), "GDC1Token",
          "mean" ) );
    }
    dMean = StatToolbox::mean( &oY, &oYErr );
  }
  
  return( dMean );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::meanErr

Description:
------------
This public member function returns the y mean error.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
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

Double GDC1Token::meanErr( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn,
    const Bool& bWeightIn ) const {
  
  // Declare the local variables
  
  Double dMeanErr; // The y mean error
  
  
  // Find and return the y mean error
  
  Vector<Double> oY = Vector<Double>(); // Keep compiler happy
  
  try {
    oY = y( dXMinIn, dXMaxIn, oTokenIn, bKeepIn, False ).copy();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in y( )\n" + oAipsError.getMesg(), "GDC1Token",
        "meanErr" ) );
  }
  
  if ( oY.nelements() < 2 ) {
    throw( ermsg( "Not enough data in range", "GDC1Token", "meanErr" ) );
  }
  
  if ( !bWeightIn || !bYError ) {
    dMeanErr = StatToolbox::meanerr( &oY, NULL );
  } else {
    Vector<Double> oYErr = Vector<Double>(); // Keep compiler happy
    try {
      oYErr = yErr( dXMinIn, dXMaxIn, oTokenIn, bKeepIn, False ).copy();
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in yErr( )\n" + oAipsError.getMesg(), "GDC1Token",
          "meanErr" ) );
    }
    dMeanErr = StatToolbox::meanerr( &oY, &oYErr );
  }
  
  return( dMeanErr );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::stdDev

Description:
------------
This public member function returns the y standard deviation.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
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

Double GDC1Token::stdDev( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn,
    const Bool& bWeightIn ) const {
  
  // Declare the local variables
  
  Double dStdDev; // The y standard deviation
  
  
  // Find and return the y standard deviation
  
  Vector<Double> oY = Vector<Double>(); // Keep compiler happy
  
  try {
    oY = y( dXMinIn, dXMaxIn, oTokenIn, bKeepIn, False ).copy();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in y( )\n" + oAipsError.getMesg(), "GDC1Token",
        "stdDev" ) );
  }
  
  if ( oY.nelements() < 2 ) {
    throw( ermsg( "Not enough data in range", "GDC1Token", "stdDev" ) );
  }
  
  if ( !bWeightIn || !bYError ) {
    dStdDev = StatToolbox::stddev( &oY, NULL );
  } else {
    Vector<Double> oYErr = Vector<Double>(); // Keep compiler happy
    try {
      oYErr = yErr( dXMinIn, dXMaxIn, oTokenIn, bKeepIn, False ).copy();
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in yErr( )\n" + oAipsError.getMesg(), "GDC1Token",
          "stdDev" ) );
    }
    dStdDev = StatToolbox::stddev( &oY, &oYErr );
  }
  
  return( dStdDev );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::variance

Description:
------------
This public member function returns the y variance.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
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

Double GDC1Token::variance( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn,
    const Bool& bWeightIn ) const {
  
  // Declare the local variables
  
  Double dVariance; // The y variance
  
  
  // Find and return the y variance
  
  Vector<Double> oY = Vector<Double>(); // Keep compiler happy
  
  try {
    oY = y( dXMinIn, dXMaxIn, oTokenIn, bKeepIn, False ).copy();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in y( )\n" + oAipsError.getMesg(), "GDC1Token",
        "variance" ) );
  }
  
  if ( oY.nelements() < 2 ) {
    throw( ermsg( "Not enough data in range", "GDC1Token", "variance" ) );
  }
  
  if ( !bWeightIn || !bYError ) {
    dVariance = StatToolbox::variance( &oY, NULL );
  } else {
    Vector<Double> oYErr = Vector<Double>();
    try {
      oYErr = yErr( dXMinIn, dXMaxIn, oTokenIn, bKeepIn, False ).copy();
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in yErr( )\n" + oAipsError.getMesg(), "GDC1Token",
          "variance" ) );
    }
    dVariance = StatToolbox::variance( &oY, &oYErr );
  }
  
  return( dVariance );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token:setFlagX

Description:
------------
This public member function sets flags in a given x range.

Inputs:
-------
dXMinIn      - The minimum x value.
dXMaxIn      - The maximum x value.
oTokenIn     - The tokens.
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

void GDC1Token::setFlagX( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bFlagValueIn ) {
  
  // Declare the local variables
  
  uInt uiEvent;      // The event number
  uInt uiIndex;      // The index counter
  uInt uiNumHistory; // The number of histories
  uInt uiNumIndex;   // The number of indices
  uInt uiNumIndexX;  // The number of indices, not taking flags into account
  
  
  // Get the indices
  
  Vector<Int> oIndexX = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndexX = index( dXMinIn, dXMaxIn, oTokenIn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
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

GDC1Token:setFlagXY

Description:
------------
This public member function sets flags in a given x-y range.

Inputs:
-------
dXMinIn      - The minimum x value.
dXMaxIn      - The maximum x value.
dYMinIn      - The minimum y value.
dYMaxIn      - The maximum y value.
oTokenIn     - The tokens.
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

void GDC1Token::setFlagXY( Double& dXMinIn, Double& dXMaxIn, Double& dYMinIn,
    Double& dYMaxIn, Vector<String>& oTokenIn, const Bool& bFlagValueIn ) {
  
  // Declare the local variable
  
  uInt uiEvent;      // The event number
  uInt uiIndex;      // The index counter
  uInt uiNumHistory; // The number of histories
  uInt uiNumIndex;   // The number of indices
  uInt uiNumIndexX;  // The number of indices, not taking y range and flags
                     // into account


  // Check the inputs
  
  if ( !checkY( dYMinIn, dYMaxIn ) ) {
    throw( ermsg( "Invalid y value(s)", "GDC1Token", "setFlagXY" ) );
  }
  
  
  // Get the indices
  
  Vector<Int> oIndexX = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndexX = index( dXMinIn, dXMaxIn, oTokenIn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC1Token",
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

GDC1Token:interpolateX

Description:
------------
This public member function sets flags in a given x range.

Inputs:
-------
dXMinIn    - The minimum x value.
dXMaxIn    - The maximum x value.
oTokenIn   - The tokens.
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

void GDC1Token::interpolateX( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, String& oInterpIn,
    Double& dXMinBoxIn, Double& dXMaxBoxIn ) {
  
  // Declare the local variables
  
  uInt uiEvent;             // The event number
  uInt uiIndex;             // The index counter
  uInt uiMethod = 0;        // The interpolation method number
  uInt uiNumHistory;        // The number of histories
  uInt uiNumIndex;          // The number of indices
  uInt uiNumIndexBox;       // The number of indices in both boxed regions
  uInt uiNumIndexHighBox;   // The number of indices in the high box region
  uInt uiNumIndexLowBox;    // The number of indices in the low box region
  uInt uiNumToken;          // The number of tokens
  uInt uiToken;             // The token counter
  
  Double dYInterp;          // The interpolated y value
  Double dYErrInterp = 0.0; // The interpolated y-error value (the average
                            // error of the boxed regions)
  
  
  // Check the inputs
  
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x value(s) (interpolation)", "GDC1Token",
        "interpolateX" ) );
  }
  
  if ( !checkX( dXMinBoxIn, dXMaxBoxIn ) ) {
    throw( ermsg( "Invalid x value(s) (box)", "GDC1Token", "interpolateX" ) );
  }
  
  if ( dXMinBoxIn >= dXMinIn || dXMaxBoxIn <= dXMaxIn ) {
    throw( ermsg( "X-box value(s) overlap interpolation value(s)", "GDC1Token",
        "interpolateX" ) );
  }
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token(s)", "GDC1Token", "interpolateX" ) );
  }
  
  if ( !checkInterp( oInterpIn ) ) {
    throw( ermsg( "Invalid interpolation method", "GDC1Token",
        "interpolateX" ) );
  }
  
  if ( oInterpIn.length() < 1 ) {
    throw( ermsg( "No interpolation method specified", "GDC1Token",
        "interpolateX" ) );
  }
  
  
  // Initialize variables and objects
  
  uiNumToken = oTokenIn.nelements();
  
  Vector<String> oTokenTemp = Vector<String>( 1 );
  
  Vector<Int> oIndex[uiNumToken];    // Default constructor
  Vector<Int> oIndexBox[uiNumToken]; // Default constructor
  
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
  
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
  
    oTokenTemp(0) = oTokenIn(uiToken);
  
    oIndex[uiToken] = index( dXMinIn, dXMaxIn, oTokenTemp, bKeepIn );

    oIndexLowBox.resize( 0, False );
    oIndexLowBox = index( dXMinBoxIn, dXMinIn, oTokenTemp, bKeepIn );
    uiNumIndexLowBox = oIndexLowBox.nelements();
    
    if ( uiNumIndexLowBox < 1 ) {
      setArgCheck( True );
      throw( ermsg( "No data in box (low)", "GDC1Token", "interpolateX" ) );
    }

    oIndexHighBox.resize( 0, False );
    oIndexHighBox = index( dXMaxIn, dXMaxBoxIn, oTokenTemp, bKeepIn );
    uiNumIndexHighBox = oIndexHighBox.nelements();
    
    if ( uiNumIndexHighBox < 1 ) {
      setArgCheck( True );
      throw( ermsg( "No data in box (high)", "GDC1Token", "interpolateX" ) );
    }

    uiNumIndexBox = oIndexBox[uiToken].nelements();

    for ( uiIndex = 0; uiIndex < uiNumIndexLowBox; uiIndex++ ) {
      uiNumIndexBox += 1;
      oIndexBox[uiToken].resize( uiNumIndexBox, True );
      oIndexBox[uiToken](uiNumIndexBox-1) = oIndexLowBox(uiIndex);
    }

    for ( uiIndex = 0; uiIndex < uiNumIndexHighBox; uiIndex++ ) {
      uiNumIndexBox += 1;
      oIndexBox[uiToken].resize( uiNumIndexBox, True );
      oIndexBox[uiToken](uiNumIndexBox-1) = oIndexHighBox(uiIndex);
    }

  }
  
  
  // Do the interpolation
  
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
  
    uiNumIndex = oIndex[uiToken].nelements();
    uiNumIndexBox = oIndexBox[uiToken].nelements();
    
    if ( uiNumIndex < 1 ) {
      String oMessage = "Zero-length interpolation region for token = ";
      oMessage += oTokenIn(uiToken);
      msg( oMessage, "GDC1Token", "interpolateX", GeneralStatus::WARN );
      continue;
    }
    
    if ( uiNumIndexBox < 1 ) {
      String oMessage = "Zero-length box region(s) for token = ";
      oMessage += oTokenIn(uiToken);
      msg( oMessage, "GDC1Token", "interpolateX", GeneralStatus::WARN );
      continue;
    }

    oXTemp.resize( uiNumIndexBox, False );
    oYTemp.resize( uiNumIndexBox, False );
    
    for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
      oXTemp(uiIndex) = (*poX)(oIndexBox[uiToken](uiIndex));
      oYTemp(uiIndex) = (*poY)(oIndexBox[uiToken](uiIndex));
    }
    
    if ( bYError ) {
      oYErrTemp.resize( uiNumIndexBox, False );
      for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
       oYErrTemp(uiIndex) = (*poYErr)(oIndexBox[uiToken](uiIndex));
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
      String oMessage = "Error setting up interpolation for token = ";
      oMessage += oTokenIn(uiToken);
      oMessage += "\n";
      oMessage += oAipsError.getMesg();
      msg( oMessage, "GDC1Token", "interpolateX", GeneralStatus::WARN );
      continue;
    }
    
    for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
      try {
        dYInterp = (*poInterpolate1D)((*poX)(oIndex[uiToken](uiIndex)));
      }
      catch ( AipsError oAipsError ) {
        String oMessage = "Interpolation error for token = ";
        oMessage += oTokenIn(uiToken);
        oMessage += "\n";
        oMessage += oAipsError.getMesg();
        msg( oMessage, "GDC1Token", "interpolateX", GeneralStatus::WARN );
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
      (*poHistoryIndex)(uiNumHistory-1) = oIndex[uiToken](uiIndex);
      (*poHistoryFlag)(uiNumHistory-1) = False;
      (*poHistoryInterp)(uiNumHistory-1) = True;
      (*poHistoryY)(uiNumHistory-1) = (*poY)(oIndex[uiToken](uiIndex));
      (*poY)(oIndex[uiToken](uiIndex)) = dYInterp;
      if ( bYError ) {
        (*poHistoryYErr)(uiNumHistory-1) = (*poYErr)(oIndex[uiToken](uiIndex));
        (*poYErr)(oIndex[uiToken](uiIndex)) = dYErrInterp;
      } else {
        (*poHistoryYErr)(uiNumHistory-1) = 0.0;
      }
      (*poFlag)(oIndex[uiToken](uiIndex)) = False;
      (*poInterp)(oIndex[uiToken](uiIndex)) = True;
    }
    
    delete poSSFX;
    delete poSSFY;
    
    delete poInterpolate1D;
    
  }
  
  
  // Turn on the argument checking
  
  setArgCheck( True );


  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token:interpolateXY

Description:
------------
This public member function sets flags in a given x-y range.

Inputs:
-------
dXMinIn    - The minimum x value.
dXMaxIn    - The maximum x value.
oTokenIn   - The tokens.
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

void GDC1Token::interpolateXY( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, String& oInterpIn,
    Double& dYMinIn, Double& dYMaxIn, Double& dXMinBoxIn,
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
  uInt uiNumToken;          // The number of tokens
  uInt uiToken;             // The token counter
   
  Double dYInterp;          // The interpolated y value
  Double dYErrInterp = 0.0; // The interpolated y-error value (the average
                            // error of the boxed regions)
  
  
  // Check the inputs
  
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x value(s) (interpolation)", "GDC1Token",
        "interpolateXY" ) );
  }
  
  if ( !checkX( dXMinBoxIn, dXMaxBoxIn ) ) {
    throw( ermsg( "Invalid x value(s) (box)", "GDC1Token", "interpolateXY" ) );
  }
  
  if ( dXMinBoxIn >= dXMinIn || dXMaxBoxIn <= dXMaxIn ) {
    throw( ermsg( "X-box value(s) overlap interpolation value(s)", "GDC1Token",
        "interpolateXY" ) );
  }
  
  if ( !checkY( dYMinIn, dYMaxIn ) ) {
    throw( ermsg( "Invalid y value(s) (interpolation)", "GDC1Token",
        "interpolateXY" ) );
  }
  
  if ( !checkY( dYMinBoxIn, dYMaxBoxIn ) ) {
    throw( ermsg( "Invalid y value(s) (box)", "GDC1Token", "interpolateXY" ) );
  }
  
  if ( dYMinBoxIn > dYMinIn || dYMaxBoxIn < dYMaxIn ) {
    throw( ermsg( "Y-box value(s) overlap interpolation value(s)", "GDC1Token",
        "interpolateXY" ) );
  }
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token(s)", "GDC1Token", "interpolateXY" ) );
  }
  
  if ( !checkInterp( oInterpIn ) ) {
    throw( ermsg( "Invalid interpolation method", "GDC1Token",
        "interpolateXY" ) );
  }
  
  if ( oInterpIn.length() < 1 ) {
    throw( ermsg( "No interpolation method specified", "GDC1Token",
        "interpolateXY" ) );
  }
  
  
  // Initialize variables and objects
  
  uiNumToken = oTokenIn.nelements();
  
  Vector<String> oTokenTemp = Vector<String>( 1 );
  
  Vector<Int> oIndexTemp = Vector<Int>();
  
  Vector<Int> oIndex[uiNumToken];    // Default constructor
  Vector<Int> oIndexBox[uiNumToken]; // Default constructor
  
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
  
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
  
    oTokenTemp(0) = oTokenIn(uiToken);
  
    oIndexTemp.resize( 0, False );
    oIndexTemp = index( dXMinIn, dXMaxIn, oTokenTemp, bKeepIn );
    
    uiNumIndex = oIndex[uiToken].nelements();
    
    for ( uiIndex = 0; uiIndex < oIndexTemp.nelements(); uiIndex++ ) {
      if ( (*poY)(oIndexTemp(uiIndex)) < dYMinIn ||
           (*poY)(oIndexTemp(uiIndex)) > dYMaxIn ) {
        continue;
      }
      uiNumIndex += 1;
      oIndex[uiToken].resize( uiNumIndex, True );
      oIndex[uiToken](uiNumIndex-1) = oIndexTemp(uiIndex);
    }

    oIndexLowBox.resize( 0, False );
    oIndexLowBox = index( dXMinBoxIn, dXMinIn, oTokenTemp, bKeepIn );
    uiNumIndexLowBox = oIndexLowBox.nelements();
    
    if ( uiNumIndexLowBox < 1 ) {
      setArgCheck( True );
      throw( ermsg( "No data in box (low)", "GDC1Token", "interpolateXY" ) );
    }

    oIndexHighBox.resize( 0, False );
    oIndexHighBox = index( dXMaxIn, dXMaxBoxIn, oTokenTemp, bKeepIn );
    uiNumIndexHighBox = oIndexHighBox.nelements();
    
    if ( uiNumIndexHighBox < 1 ) {
      setArgCheck( True );
      throw( ermsg( "No data in box (high)", "GDC1Token", "interpolateXY" ) );
    }
 
    uiNumIndexBox = oIndexBox[uiToken].nelements();

    for ( uiIndex = 0; uiIndex < uiNumIndexLowBox; uiIndex++ ) {
      if ( (*poY)(oIndexLowBox(uiIndex)) < dYMinBoxIn ) {
        continue;
      }
      uiNumIndexBox += 1;
      oIndexBox[uiToken].resize( uiNumIndexBox, True );
      oIndexBox[uiToken](uiNumIndexBox-1) = oIndexLowBox(uiIndex);
    }

    for ( uiIndex = 0; uiIndex < uiNumIndexHighBox; uiIndex++ ) {
      if ( (*poY)(oIndexHighBox(uiIndex)) > dYMaxBoxIn ) {
        continue;
      }
      uiNumIndexBox += 1;
      oIndexBox[uiToken].resize( uiNumIndexBox, True );
      oIndexBox[uiToken](uiNumIndexBox-1) = oIndexHighBox(uiIndex);
    }

  }
  
  
  // Do the interpolation
  
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
  
    uiNumIndex = oIndex[uiToken].nelements();
    uiNumIndexBox = oIndexBox[uiToken].nelements();
    
    if ( uiNumIndex < 1 ) {
      String oMessage = "Zero-length interpolation region for token = ";
      oMessage += oTokenIn(uiToken);
      msg( oMessage, "GDC1Token", "interpolateX", GeneralStatus::WARN );
      continue;
    }
    
    if ( uiNumIndexBox < 1 ) {
      String oMessage = "Zero-length box region(s) for token = ";
      oMessage += oTokenIn(uiToken);
      msg( oMessage, "GDC1Token", "interpolateX", GeneralStatus::WARN );
      continue;
    }

    oXTemp.resize( uiNumIndexBox, False );
    oYTemp.resize( uiNumIndexBox, False );
    
    for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
      oXTemp(uiIndex) = (*poX)(oIndexBox[uiToken](uiIndex));
      oYTemp(uiIndex) = (*poY)(oIndexBox[uiToken](uiIndex));
    }
    
    if ( bYError ) {
      oYErrTemp.resize( uiNumIndexBox, False );
      for ( uiIndex = 0; uiIndex < uiNumIndexBox; uiIndex++ ) {
       oYErrTemp(uiIndex) = (*poYErr)(oIndexBox[uiToken](uiIndex));
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
      String oMessage = "Error setting up interpolation for token = ";
      oMessage += oTokenIn(uiToken);
      oMessage += "\n";
      oMessage += oAipsError.getMesg();
      msg( oMessage, "GDC1Token", "interpolateX", GeneralStatus::WARN );
      continue;
    }
    
    for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
      try {
        dYInterp = (*poInterpolate1D)((*poX)(oIndex[uiToken](uiIndex)));
      }
      catch ( AipsError oAipsError ) {
        String oMessage = "Interpolation error for token = ";
        oMessage += oTokenIn(uiToken);
        oMessage += "\n";
        oMessage += oAipsError.getMesg();
        msg( oMessage, "GDC1Token", "interpolateX", GeneralStatus::WARN );
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
      (*poHistoryIndex)(uiNumHistory-1) = oIndex[uiToken](uiIndex);
      (*poHistoryFlag)(uiNumHistory-1) = False;
      (*poHistoryInterp)(uiNumHistory-1) = True;
      (*poHistoryY)(uiNumHistory-1) = (*poY)(oIndex[uiToken](uiIndex));
      (*poY)(oIndex[uiToken](uiIndex)) = dYInterp;
      if ( bYError ) {
        (*poHistoryYErr)(uiNumHistory-1) = (*poYErr)(oIndex[uiToken](uiIndex));
        (*poYErr)(oIndex[uiToken](uiIndex)) = dYErrInterp;
      } else {
        (*poHistoryYErr)(uiNumHistory-1) = 0.0;
      }
      (*poFlag)(oIndex[uiToken](uiIndex)) = False;
      (*poInterp)(oIndex[uiToken](uiIndex)) = True;
    }
    
    delete poSSFX;
    delete poSSFY;
    
    delete poInterpolate1D;
    
  }
  
  
  // Turn on the argument checking
  
  setArgCheck( True );


  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::undoHistory

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

void GDC1Token::undoHistory( void ) {

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

GDC1Token::resetHistory

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

void GDC1Token::resetHistory( void ) {

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

GDC1Token::history

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

void GDC1Token::history( Vector<Int>* *poHistoryEventIn,
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

GDC1Token::numEvent

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

uInt GDC1Token::numEvent( void ) const {
    
  // Return the number of events in the history

  if ( poHistoryEvent->nelements() > 0 ) {
    return( (*poHistoryEvent)( poHistoryEvent->nelements() - 1 ) );
  } else {
    return( 0 );
  }
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::postScript

Description:
------------
This public member function creates a PostScript plot with the present plot
parameters.

Inputs:
-------
oFileIn   - The file name.
oDeviceIn - The PostScript device type ("/PS", "/VPS", "/CPS", "/VCPS").
bTrans    - The size flag (T = transparency, F = publication).
oCI       - The PGPLOT color indices.

Outputs:
--------
The PostScript plot.

Modification history:
---------------------
2000 Jun 05 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1Token::postScript( String& oFileIn, const String& oDeviceIn,
    const Bool& bTrans, const Vector<Int>& oCI ) {
  
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
      plot( iQID, oCI );
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg(
          "Error while creating PostScript file\n" + oAipsError.getMesg(),
          "GDC1Token", "postScript" ) );
    }
  } else {
    throw( ermsg( "Could not create PostScript file", "GDC1Token",
        "postScript" ) );
  }
  
  cpgclos();
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::plot

Description:
------------
This public member function plots data to a PGPLOT device.

Inputs:
-------
iQIDIn - The PGPLOT QID.
oCI    - The PGPLOT color indices.

Outputs:
--------
The plot.

Modification history:
---------------------
2000 Jun 05 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1Token::plot( const Int& iQIDIn, const Vector<Int>& oCI ) {
  
  // Declare the local variables
  
  uInt uiNumToken;      // The temporary number of tokens
  uInt uiToken;         // The token counter
  
  Double dXDelta;       // The x-axis plotting margin
  Double dXMax;         // The maximum plot x-value
  Double dXMin;         // The minimum plot x-value
  Double dYDelta;       // The y-axis plotting margin
  Double dYMax;         // The maximum plot y-value
  Double dYMin;         // The minimum plot y-value
  
  Vector<Int>* poIndex; // The index vector
  
  
  // Possible to make a plot?
  
  if ( iQIDIn < 1 ) {
    throw( ermsg( "Invalid PGPLOT device number", "GDC1Token", "plot" ) );
  }
  
  if ( poTokenPlot->nelements() < 1 ) {
    msg( "No tokens selected", "GDC1Token", "plot", NORMAL );
    return;
  }
  
  
  // Turn off argument checking, for speed
  
  setArgCheck( False );
  
  
  // Initialize some local variables
  
  Double dXMinPlotTemp = getXMin();
  Double dXMaxPlotTemp = getXMax();
  
  Vector<String> oToken = getToken();
  
  dXMin = xMin( dXMinPlotTemp, dXMaxPlotTemp, oToken, bKeep, bXError );
  dXMax = xMax( dXMinPlotTemp, dXMaxPlotTemp, oToken, bKeep, bXError );
  dYMin = yMin( dXMinPlotTemp, dXMaxPlotTemp, oToken, bKeep, bYError );
  dYMax = yMax( dXMinPlotTemp, dXMaxPlotTemp, oToken, bKeep, bYError );

  
//  Vector<String> oToken = Vector<String>();

  if ( bColor ) {
    uiNumToken = oToken.nelements();
  } else {
    uiNumToken = 1;
  }


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
  
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
  
    if ( bColor ) {
      oToken.resize( 1, False );
      oToken = Vector<String>( 1, (*poTokenPlot)(uiToken) );
    } else {
      oToken.resize( poTokenPlot->nelements(), False );
      oToken = *poTokenPlot;
    }
    
    poIndex = new Vector<Int>( index( dXMin, dXMax, oToken, bKeep ).copy() );
        
    if ( poIndex->nelements() > 1 ) {
      plotPoints( poIndex, oCI(uiToken) );
      if ( bLine ) {
        plotLine( poIndex, oCI(uiToken) );
      }
    }
    
    delete poIndex;
    
    if ( bKeep ) {
      poIndex =
          new Vector<Int>( flagged( dXMin, dXMax, oToken ).copy() );
      if ( poIndex->nelements() > 1 ) {
        plotPoints( poIndex, 2 );
      }
      delete poIndex;
    }
    
    poIndex = new Vector<Int>( interpolated( dXMin, dXMax, oToken ).copy() );
    
    if ( poIndex->nelements() > 1 ) {
      plotPoints( poIndex, 3 );
    }
    
    delete poIndex;
    
  }
  
  
  // Finish the plot
  
  cpgebuf();
  
  
  // Turn on argument checking
  
  setArgCheck( True );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::getXMin

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

Double GDC1Token::getXMin( const Bool& bDefaultIn ) const {

  // Return the minimum plotted x value

  if ( !bDefaultIn ) {
    return( dXMinPlot );
  } else {
    return( dXMinDefault );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1Token::getXMax

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

Double GDC1Token::getXMax( const Bool& bDefaultIn ) const {

  // Return the maximum plotted x value

  if ( !bDefaultIn ) {
    return( dXMaxPlot );
  } else {
    return( dXMaxDefault );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1Token::getYMin

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

Double GDC1Token::getYMin( const Bool& bDefaultIn ) const {

  // Return the minimum plotted y value
  
  if ( !bDefaultIn ) {
    return( dYMinPlot );
  } else {
    return( dYMinDefault );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1Token::getYMax

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

Double GDC1Token::getYMax( const Bool& bDefaultIn ) const {

  // Return the maximum plotted y value
  
  if ( !bDefaultIn ) {
    return( dYMaxPlot );
  } else {
    return( dYMaxDefault );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1Token::zoomx

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

void GDC1Token::zoomx( Double& dXMinIn, Double& dXMaxIn ) {

  // Fix/check the inputs
  
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "GDC1Token", "zoomx" ) );
  }
  
  
  // Save the x limits and return
  
  dXMinPlot = dXMinIn;
  dXMaxPlot = dXMaxIn;

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::zoomy

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

void GDC1Token::zoomy( Double& dYMinIn, Double& dYMaxIn ) {

  // Fix/check the inputs
  
  if ( !checkY( dYMinIn, dYMaxIn ) ) {
    throw( ermsg( "Invalid y value(s)", "GDC1Token", "zoomy" ) );
  }
  
  
  // Save the y limits and return
  
  dYMinPlot = dYMinIn;
  dYMaxPlot = dYMaxIn;

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::zoomxy

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

void GDC1Token::zoomxy( Double& dXMinIn, Double& dXMaxIn, Double& dYMinIn,
    Double& dYMaxIn ) {  

  // Fix/check the inputs
    
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "GDC1Token", "zoomxy" ) );
  }
  
  if ( !checkY( dYMinIn, dYMaxIn ) ) {
    throw( ermsg( "Invalid y value(s)", "GDC1Token", "zoomxy" ) );
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

GDC1Token::fullSize

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

void GDC1Token::fullSize( void ) {
  
  // Modify the x and y limits to their default values and return

  zoomxy( dXMinDefault, dXMaxDefault, dYMinDefault, dYMaxDefault );

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::getToken

Description:
------------
This public member function returns the plotted tokens.

Inputs:
-------
None.

Outputs:
--------
The plotted tokens, returned via the function value.

Modification history:
---------------------
2000 Jun 05 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GDC1Token::getToken( void ) const {
  
  // Return the plotted tokens
  
  return( Vector<String>( *poTokenPlot ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::setToken

Description:
------------
This public member function sets the plotted tokens.

Inputs:
-------
oTokenIn - The tokens.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 05 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1Token::setToken( Vector<String>& oTokenIn ) {

  // Check the inputs
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token argument(s)", "GDC1Token", "setToken" ) );
  }
  
  
  // Set the tokens and return
  
  if ( poTokenPlot != NULL ) {
    delete poTokenPlot;
  }
  poTokenPlot = new Vector<String>( oTokenIn );
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::setTokenDefault

Description:
------------
This public member function sets the plotted tokens to the default (all
tokens).

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 05 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1Token::setTokenDefault( void ) {
  
  // Set the tokens to the default and return
  
  if ( poTokenPlot != NULL ) {
    delete poTokenPlot;
  }
  
  poTokenPlot = new Vector<String>();
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::addToken

Description:
------------
This public member function adds unique plotted tokens.

Inputs:
-------
oTokenIn - The tokens.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 12 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1Token::addToken( Vector<String>& oTokenIn ) {

  // Declare the local variables
  
  uInt uiNumToken1; // A number of tokens
  uInt uiNumToken2; // A number of tokens
  uInt uiToken1;    // A token counter
  uInt uiToken2;    // A token counter
  

  // Check the inputs
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token argument(s)", "GDC1Token", "addToken" ) );
  }
  
  
  // Add the unique tokens and return
  
  uiNumToken1 = oTokenIn.nelements();
  uiNumToken2 = poTokenPlot->nelements();
  
  for ( uiToken1 = 0; uiToken1 < uiNumToken1; uiToken1++ ) {
    for ( uiToken2 = 0; uiToken2 < uiNumToken2; uiToken2++ ) {
      if ( oTokenIn(uiToken1).matches( (*poTokenPlot)(uiToken2) ) ) {
        break;
      }
    }
    if ( uiToken2 >= uiNumToken2 ) {
      uiNumToken2 += 1;
      poTokenPlot->resize( uiNumToken2, True );
      (*poTokenPlot)(uiNumToken2-1) = oTokenIn(uiToken1);
    }
  }
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::removeToken

Description:
------------
This public member function removes plotted tokens.

Inputs:
-------
oTokenIn - The tokens.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 12 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1Token::removeToken( Vector<String>& oTokenIn ) {

  // Declare the local variables
  
  uInt uiNumToken1; // A number of tokens
  uInt uiNumToken2; // A number of tokens
  uInt uiToken1;    // A token counter
  uInt uiToken2;    // A token counter
  uInt uiToken3;    // A token counter
  

  // Check the inputs
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token argument(s)", "GDC1Token", "removeToken" ) );
  }
  
  
  // Remove the tokens and return
  
  uiNumToken1 = oTokenIn.nelements();
  uiNumToken2 = poTokenPlot->nelements();
  
  for ( uiToken1 = 0; uiToken1 < uiNumToken1; uiToken1++ ) {
    for ( uiToken2 = 0; uiToken2 < uiNumToken2; uiToken2++ ) {
      if ( oTokenIn(uiToken1).matches( (*poTokenPlot)(uiToken2) ) ) {
        break;
      }
    }
    if ( uiToken2 < uiNumToken2 ) {
      uiNumToken2 -= 1;
      for ( uiToken3 = uiToken2; uiToken3 < uiNumToken2; uiToken3++ ) {
        (*poTokenPlot)(uiToken3) = (*poTokenPlot)(uiToken3+1);
      }
      poTokenPlot->resize( uiNumToken2, True );
    }
  }
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::getFlag

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

Bool GDC1Token::getFlag( void ) const {

  // Return the flagging boolean
  
  return( bFlag );

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setFlag

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

void GDC1Token::setFlag( const Bool& bFlagIn ) {

  // Set the flagging boolean and return
  
  bFlag = bFlagIn;
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::getColor

Description:
------------
This public member function gets the plot-color boolean.

Inputs:
-------
None.

Outputs:
--------
The plot-color boolean, returned via the function value.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1Token::getColor( void ) const {

  // Return the plot-color boolean
  
  return( bColor );

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setColor

Description:
------------
This public member function sets the plot-color boolean.

Inputs:
-------
bColorIn - The plot-color boolean.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC1Token::setColor( const Bool& bColorIn ) {

  // Set the plot-color boolean and return
  
  bColor = bColorIn;
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::getLine

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

Bool GDC1Token::getLine( void ) const {

  // Return the plot-line boolean
  
  return( bLine );

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setLine

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

void GDC1Token::setLine( const Bool& bLineIn ) {

  // Set the plot-line boolean and return
  
  bLine = bLineIn;
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::getKeep

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

Bool GDC1Token::getKeep( void ) const {

  // Return the keep-flag boolean
  
  return( bKeep );

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setKeep

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

void GDC1Token::setKeep( const Bool& bKeepIn ) {

  // Set the keep-flag boolean and return
  
  bKeep = bKeepIn;
  
  if ( !bKeep && !bFlag ) {
    bFlag = True;
  }
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::getXLabel

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

String GDC1Token::getXLabel( const Bool& bDefaultIn ) const {

  // Return the x-axis label
  
  if ( !bDefaultIn ) {
    return( String( *poXLabel ) );
  } else {
    return( String( *poXLabelDefault ) );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setXLabel (default)

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

void GDC1Token::setXLabel( void ) {

  // Set the x-axis label to its default value and return
  
  if ( poXLabel != NULL ) {
    delete poXLabel;
  }
  poXLabel = new String( *poXLabelDefault );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setXLabel (arbitrary)

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

void GDC1Token::setXLabel( const String& oXLabelIn ) {

  // Set the x-axis label and return
  
  if ( poXLabel != NULL ) {
    delete poXLabel;
  }
  poXLabel = new String( oXLabelIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setXLabelDefault

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

void GDC1Token::setXLabelDefault( const String& oXLabelIn ) {

  // Set the default x-axis label and return
  
  if ( poXLabelDefault != NULL ) {
    delete poXLabelDefault;
  }
  poXLabelDefault = new String( oXLabelIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::getYLabel

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

String GDC1Token::getYLabel( const Bool& bDefaultIn ) const {

  // Return the y-axis label
  
  if ( !bDefaultIn ) {
    return( String( *poYLabel ) );
  } else {
    return( String( *poYLabelDefault ) );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setYLabel (default)

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

void GDC1Token::setYLabel( void ) {

  // Set the y-axis label to its default value and return
  
  if ( poYLabel != NULL ) {
    delete poYLabel;
  }
  poYLabel = new String( *poYLabelDefault );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setYLabel (arbitrary)

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

void GDC1Token::setYLabel( const String& oYLabelIn ) {

  // Set the y-axis label and return
  
  if ( poYLabel != NULL ) {
    delete poYLabel;
  }
  poYLabel = new String( oYLabelIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setYLabelDefault

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

void GDC1Token::setYLabelDefault( const String& oYLabelIn ) {

  // Set the default y-axis label and return
  
  if ( poYLabelDefault != NULL ) {
    delete poYLabelDefault;
  }
  poYLabelDefault = new String( oYLabelIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::getTitle

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

String GDC1Token::getTitle( const Bool& bDefaultIn ) const {

  // Return the title label
  
  if ( !bDefaultIn ) {
    return( String( *poTitle ) );
  } else {
    return( String( *poTitleDefault ) );
  }

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setTitle (default)

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

void GDC1Token::setTitle( void ) {

  // Set the title label to its default value and return
  
  if ( poTitle != NULL ) {
    delete poTitle;
  }
  poTitle = new String( *poTitleDefault );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setTitle (arbitrary)

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

void GDC1Token::setTitle( const String& oTitleIn ) {

  // Set the title label and return
  
  if ( poTitle != NULL ) {
    delete poTitle;
  }
  poTitle = new String( oTitleIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::setTitleDefault

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

void GDC1Token::setTitleDefault( const String& oTitleIn ) {

  // Set the default title label and return
  
  if ( poTitleDefault != NULL ) {
    delete poTitleDefault;
  }
  poTitleDefault = new String( oTitleIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::hms

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

Bool GDC1Token::hms( void ) const {

  // Return the HH:MM:SS boolean
  
  return( bHMS );

}

// -----------------------------------------------------------------------------

/*

GDC1Token::hmsOld

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

Bool GDC1Token::hmsOld( void ) const {

  // Return the old HH:MM:SS boolean
  
  return( bHMSOld );

}

// -----------------------------------------------------------------------------

/*

GDC1Token::version

Description:
------------
This public member function returns the GDC1Token{ } version.

Inputs:
-------
None.

Outputs:
--------
The GDC1Token{ } version, returned via the function value.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC1Token::version( void ) const {

  // Return the GDC1Token{ } version
  
  return( String( "0.2" ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::tool

Description:
------------
This public member function returns the glish tool name (must be "gdc1token").

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

String GDC1Token::tool( void ) const {

  // Return the glish tool name
  
  String oTool = className();
  oTool.downcase();
  
  return( oTool );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::checkToken

Description:
------------
This public member function checks/fixes tokens.  NB: Duplicate tokens will be
purged.

Inputs:
-------
oTokenIn - The tokens.

Outputs:
--------
oTokenIn - The checked/fixed tokens.
The check boolean (True = OK, False = NOT OK).

Modification history:
---------------------
2000 May 07 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC1Token::checkToken( Vector<String>& oTokenIn ) const {
  
  // Declare the local variables
  
  uInt uiData;         // The data counter
  uInt uiNumData;      // The number of data
  uInt uiNumToken;     // The number of tokens
  uInt uiNumTokenTemp; // The number of tokens
  uInt uiToken;        // A token counter
  uInt uiToken2;       // A token counter
  
  
  // Proceed?
  
  if ( !bArgCheck ) {
    return( True );
  }
  
  
  // Check the inputs

  uiNumToken = oTokenIn.nelements();

  if ( uiNumToken < 1 ) {
    oTokenIn = Vector<String>( *poTokenList );
    return( True );
  }


  // Eliminate white spaces and convert to upper case

  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
    oTokenIn(uiToken).gsub( RXwhite, "" );
    oTokenIn(uiToken).upcase();
  }


  // Eliminate duplicate tokens
  
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
    if ( oTokenIn(uiToken).length() < 1 ) {
      continue;
    }
    for ( uiToken2 = uiToken+1; uiToken2 < uiNumToken; uiToken2++ ) {
      if ( oTokenIn(uiToken2).length() < 1 ) {
        continue;
      }
      if ( oTokenIn(uiToken2).matches( oTokenIn(uiToken) ) ) {
        oTokenIn(uiToken2) = "";
      }
    }
  }
  
  uiNumTokenTemp = 0;
  Vector<String> oTokenInTemp = Vector<String>();
  
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
    if ( oTokenIn(uiToken).length() > 0 ) {
      uiNumTokenTemp += 1;
      oTokenInTemp.resize( uiNumTokenTemp, True );
      oTokenInTemp(uiNumTokenTemp-1) = oTokenIn(uiToken);
    }
  }
  
  oTokenIn.resize( uiNumTokenTemp, False );
  oTokenIn = oTokenInTemp;


  // Check/fix the tokens and return the check boolean
  
  uiNumToken = oTokenIn.nelements();
  uiNumData = poToken->nelements();
  
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
    for ( uiData = 0; uiData < uiNumData; uiData++ ) {
      if ( oTokenIn(uiToken).matches( (*poToken)(uiData) ) ) {
        break;
      }
    }
    if ( uiData >= uiNumData ) {
      return( False );
    }
  }
  
  return( True );
  
}

// -----------------------------------------------------------------------------

/*

GDC1Token::checkX

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

Bool GDC1Token::checkX( Double& dXMinIn, Double& dXMaxIn ) const {

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

GDC1Token::checkY

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

Bool GDC1Token::checkY( Double& dYMinIn, Double& dYMaxIn ) const {

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

GDC1Token::checkInterp

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

Bool GDC1Token::checkInterp( String& oInterpIn ) const {
  
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

GDC1Token::changeX

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

void GDC1Token::changeX( const Vector<Double>& oXIn,
    const Vector<Double>& oXErrIn, const String& oXLabelIn,
    const Bool& bHMSIn ) {
  
  // Declare the local variables
  
  uInt uiData;       // The data(-error) counter
  uInt uiNumData;    // The number of data
  uInt uiNumDataErr; // The number of data errors;


  // Check the inputs
 
  uiNumData = poX->nelements();
  
  if ( oXIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid x vector", "GDC1Token", "changeX" ) );
  }
  
  uiNumDataErr = oXErrIn.nelements();
  
  if ( uiNumDataErr != 0 && uiNumDataErr != uiNumData ) {
    throw( ermsg( "Invalid x-error vector", "GDC1Token", "changeX" ) );
  }
  
  
  // Change the private variables
  
  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    Vector<String> oToken = tokenList();
    oIndex = index( dXMinPlot, dXMaxPlot, oToken, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not get indices\n" + oAipsError.getMesg(),
        "GDC1Token", "changeX" ) );
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

GDC1Token::resetX

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

void GDC1Token::resetX( void ) {
  
  // Declare the local variables
  
  uInt uiData;       // The data(-error) counter
  uInt uiNumData;    // The number of data
  uInt uiNumDataErr; // The number of data errors;
  
  
  // Change the private variables
  
  uiNumData = poXOld->nelements();
  uiNumDataErr = poXErrOld->nelements();
  
  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    Vector<String> oToken = tokenList();
    oIndex = index( dXMinPlot, dXMaxPlot, oToken, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not get indices\n" + oAipsError.getMesg(),
        "GDC1Token", "resetX" ) );
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

GDC1Token::className

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

String GDC1Token::className( void ) const {

  // Return the class name
  
  return( String( "GDC1Token" ) );

}

// -----------------------------------------------------------------------------

/*

GDC1Token::methods

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

Vector<String> GDC1Token::methods( void ) const {

  // Return the method names
  
  Vector<String> oMethod(80);
  
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
  oMethod(12) = String( "token" );
  oMethod(13) = String( "tokenType" );
  oMethod(14) = String( "tokenList" );
  oMethod(15) = String( "flag" );
  oMethod(16) = String( "interp" );
  oMethod(17) = String( "index" );
  oMethod(18) = String( "xMax" );
  oMethod(19) = String( "xMin" );
  oMethod(20) = String( "yMax" );
  oMethod(21) = String( "yMin" );
  oMethod(22) = String( "xErrMax" );
  oMethod(23) = String( "xErrMin" );
  oMethod(24) = String( "yErrMax" );
  oMethod(25) = String( "yErrMin" );
  oMethod(26) = String( "flagged" );
  oMethod(27) = String( "interpolated" );
  oMethod(28) = String( "mean" );
  oMethod(29) = String( "meanErr" );
  oMethod(30) = String( "stdDev" );
  oMethod(31) = String( "variance" );
  oMethod(32) = String( "setFlagX" );
  oMethod(33) = String( "setFlagXY" );
  oMethod(34) = String( "interpolateX" );
  oMethod(35) = String( "interpolateXY" );
  oMethod(36) = String( "undoHistory" );
  oMethod(37) = String( "resetHistory" );
  oMethod(38) = String( "numEvent" );
  oMethod(39) = String( "postScript" );
  oMethod(40) = String( "getXMin" );
  oMethod(41) = String( "getXMax" );
  oMethod(42) = String( "getYMin" );
  oMethod(43) = String( "getYMax" );
  oMethod(44) = String( "zoomx" );
  oMethod(45) = String( "zoomy" );
  oMethod(46) = String( "zoomxy" );
  oMethod(47) = String( "fullSize" );
  oMethod(48) = String( "getToken" );
  oMethod(49) = String( "setToken" );
  oMethod(50) = String( "setTokenDefault" );
  oMethod(51) = String( "addToken" );
  oMethod(52) = String( "removeToken" );
  oMethod(53) = String( "getFlag" );
  oMethod(54) = String( "setFlag" );
  oMethod(55) = String( "getColor" );
  oMethod(56) = String( "setColor" );
  oMethod(57) = String( "getLine" );
  oMethod(58) = String( "setLine" );
  oMethod(59) = String( "getKeep" );
  oMethod(60) = String( "setKeep" );
  oMethod(61) = String( "getXLabel" );
  oMethod(62) = String( "setXLabel" );
  oMethod(63) = String( "setXLabelDefault" );
  oMethod(64) = String( "getYLabel" );
  oMethod(65) = String( "setYLabel" );
  oMethod(66) = String( "setYLabelDefault" );
  oMethod(67) = String( "getTitle" );
  oMethod(68) = String( "setTitle" );
  oMethod(69) = String( "setTitleDefault" );
  oMethod(70) = String( "hms" );
  oMethod(71) = String( "id" );
  oMethod(72) = String( "version" );
  oMethod(73) = String( "tool" );
  oMethod(74) = String( "checkToken" );
  oMethod(75) = String( "checkX" );
  oMethod(76) = String( "checkY" );
  oMethod(77) = String( "checkInterp" );
  
  return( oMethod );

}

// -----------------------------------------------------------------------------

/*

GDC1Token::noTraceMethods

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

Vector<String> GDC1Token::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}


// -----------------------------------------------------------------------------

/*

GDC1Token::initialize

Description:
------------
This protected member function initializes the private variables.

Inputs:
-------
oXin         - The x vector.
oYIn         - The y vector.
oXErrIn      - The x error vector. If no x errors, then the vector length
               should be 0.
oYErrIn      - The y error vector. If no y errors, then the vector length
               should be 0.
oTokenIn     - The token vector. If no tokens, then the vector length should be
               0.
oFlagIn      - The flag vector. If no flags, then the vector length should be
               0.
oTokenTypeIn - The token type.

Outputs:
--------
None.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Protected member function created.

*/

// -----------------------------------------------------------------------------

void GDC1Token::initialize( const Vector<Double>& oXIn,
    const Vector<Double>& oYIn, const Vector<Double>& oXErrIn,
    const Vector<Double>& oYErrIn, const Vector<String>& oTokenIn,
    const Vector<Bool>& oFlagIn, const String& oTokenTypeIn ) {
  
  // Declare the local variables
  
  Bool bUnique;    // Unique token flag
  
  uInt uiData;     // A data counter
  uInt uiData2;    // A data counter
  uInt uiNumData;  // The number of data
  uInt uiNumToken; // The number of tokens
  uInt uiToken1;   // A token counter
  uInt uiToken2;   // A token counter
  
  
  // Check the inputs

  uiNumData = oXIn.nelements();
  
  if ( uiNumData < 1 ) {
    throw( ermsg( "Invalid x vector", "GDC1Token", "initialize" ) );
  }
  
  if ( oYIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid y vector", "GDC1Token", "initialize" ) );
  }
  
  if ( oXErrIn.nelements() > 0 && oXErrIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid x error vector", "GDC1Token", "initialize" ) );
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
        throw( ermsg( "Invalid x error(s)", "GDC1Token", "initialize" ) );
      }
    }
  } else {
    bXError = False;
  }
  
  if ( oYErrIn.nelements() > 0 && oYErrIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid y error vector", "GDC1Token", "initialize" ) );
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
        throw( ermsg( "Invalid y error(s)", "GDC1Token", "initialize" ) );
      }
    }
  } else {
    bYError = False;
  }
  
  if ( oTokenIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid token vector", "GDC1Token", "initialize" ) );
  }
  
  String oTokenTemp = String();
  
  for ( uiData = 0; uiData < oTokenIn.nelements(); uiData++ ) {
    oTokenTemp = oTokenIn(uiData);
    oTokenTemp.gsub( RXwhite, "" );
    if ( oTokenTemp == String( "" ) ) {
      throw( ermsg( "Invalid token(s)", "GDC1Token", "initialize" ) );
    }
  }
  
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    for ( uiData2 = uiData+1; uiData2 < uiNumData; uiData2++ ) {
      if ( oXIn(uiData2) == oXIn(uiData) &&
           oTokenIn(uiData2).matches( oTokenIn(uiData) ) ) {
        throw( ermsg( "Duplicate x value(s) for a given token", "GDC1Token",
            "initialize" ) );
      }
    }
  }
  
  if ( oFlagIn.nelements() > 0 && oFlagIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid flag vector", "GDC1Token", "initialize" ) );
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

  poToken = new Vector<String>( oTokenIn.copy() );
  
  poFlagOrig = new Vector<Bool>( oFlagIn.copy() );
  poFlag = new Vector<Bool>( oFlagIn.copy() );
  
  poInterp = new Vector<Bool>( uiNumData, False );

  
  // Deal with token-related objects
  
  poTokenType = new String( oTokenTypeIn );
  poTokenType->gsub( RXwhite, "" );
    
  for ( uiData = 0; uiData < poToken->nelements(); uiData++ ) {
    (*poToken)(uiData).gsub( RXwhite, "" );
    (*poToken)(uiData).upcase();
    if ( (*poToken)(uiData).length() > LENGTH_MAX ) {
      throw( ermsg( "Token(s) too long", "GDC1Token", "initialize" ) );
    }
  }
  
  uiNumToken = 0;
  poTokenList = new Vector<String>();

  for ( uiToken1 = 0; uiToken1 < uiNumData; uiToken1++ ) {
    bUnique = True;
    for ( uiToken2 = 0; uiToken2 < uiToken1; uiToken2++ ) {
      if ( (*poToken)(uiToken2).matches( (*poToken)(uiToken1) ) ) {
        bUnique = False;
        break;
      }
    }
    if ( bUnique ) {
      uiNumToken += 1;
      poTokenList->resize( uiNumToken, True );
      (*poTokenList)(uiNumToken-1) = (*poToken)(uiToken1);
    }
  }
  
  
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
  
  StatToolbox::sort( oSortKey, *poToken );
  
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
  
  poTokenPlot = NULL;
  setTokenDefault();
  
  dXMinDefault = xMin( False );
  dXMaxDefault = xMax( False );
  
  dXMinPlot = xMin( True );
  dXMaxPlot = xMax( True );

  dYMinDefault = yMin( dXMinDefault, dXMaxDefault, *poTokenList, True, False );
  dYMaxDefault = yMax( dXMinDefault, dXMaxDefault, *poTokenList, True, False );

  dYMinPlot = yMin( dXMinDefault, dXMaxDefault, *poTokenList, True, True );
  dYMaxPlot = yMax( dXMinDefault, dXMaxDefault, *poTokenList, True, True );
  
  setKeep( False );
  
  
  // Enable the argument checking

  setArgCheck( True );

  
  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::initializePlotAttrib

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

void GDC1Token::initializePlotAttrib( const Bool& bHMSIn,
    const String& oXLabelIn, const String& oYLabelIn, const String& oTitleIn,
    const String& oXLabelDefaultIn, const String& oYLabelDefaultIn,
    const String& oTitleDefaultIn ) {
  
  // Initialize the plotting attributes

  bHMSOld = bHMSIn;  
  bHMS = bHMSIn;
  
  setFlag( True );
  setColor( True );
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

GDC1Token::loadASCII

Description:
------------
This private member function loads data from an ASCII file.  If the tokens are
"no_token", then the token vector will be returned with zero length.  NB: I'm
using functions from stdio.h because I dislike the classes in iostream.h.

Inputs:
-------
oFileIn - The ASCII file name.

Outputs:
--------
oXOut     - The x vector.
oYOut     - The y vector.
oXErrOut  - The x-error vector.
oYErrOut  - The y-error vector.
oTokenOut - The token String array (!).
oFlagOut  - The flag vector.

Modification history:
---------------------
2000 Jun 07 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void GDC1Token::loadASCII( String& oFileIn, Vector<Double>& oXOut,
    Vector<Double>& oYOut, Vector<Double>& oXErrOut, Vector<Double>& oYErrOut,
    Vector<String>& oTokenOut, Vector<Bool>& oFlagOut ) {

  // Declare the local variables

  Bool bFlag;                 // The temporary flag boolean
 
  uInt uiData;                // The data counter
  uInt uiNumData;             // The number of data
  
  FILE* pmtStream;            // The data input stream
  
  Char acLine[LENGTH_MAX+1];  // The temporary line variable
  Char acToken[LENGTH_MAX+1]; // The temporary token variable


  // Find the number of lines in the file (kludge, since feof does not appear
  // to work correctly under RedHat 6.1)

  oFileIn.gsub( RXwhite, "" );

  pmtStream = fopen( oFileIn.chars(), "r" );
  
  if ( pmtStream == NULL ) {
    throw( ermsg( "Invalid ASCII file", "GDC1Token", "loadASCII" ) );
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


  // Is the file empty?

  if ( uiNumData < 1 ) {
    throw( ermsg( "Empty ASCII file", "GDC1Token", "loadASCII" ) );
  }

  
  // Load the data from the ASCII file

  pmtStream = fopen( oFileIn.chars(), "r" );

  oXOut.resize( uiNumData, True );
  oYOut.resize( uiNumData, True );
  oXErrOut.resize( uiNumData, True );
  oYErrOut.resize( uiNumData, True );
  oTokenOut.resize( uiNumData, True );
  oFlagOut.resize( uiNumData, True );

  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    fgets( acLine, LENGTH_MAX, pmtStream );
    if ( acLine[0] == '#' ) {
      continue;
    }
    sscanf( acLine, "%lf %lf %lf %lf %s %u", &oXOut(uiData), &oYOut(uiData),
        &oXErrOut(uiData), &oYErrOut(uiData), acToken, (uInt*) &bFlag );
    oFlagOut(uiData) = bFlag;
    oTokenOut(uiData) = String( acToken );
  }
  
  fclose( pmtStream );
  
  
  // Return
 
  return;

}

// -----------------------------------------------------------------------------

/*

GDC1Token::plotPoints

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

void GDC1Token::plotPoints( const Vector<Int>* const poIndexIn,
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

GDC1Token::plotLine

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

void GDC1Token::plotLine( const Vector<Int>* const poIndexIn,
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
