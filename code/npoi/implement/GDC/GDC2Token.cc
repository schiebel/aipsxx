//#GDC2Token.cc is part of the GDC server
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
//# $Id: GDC2Token.cc,v 19.0 2003/07/16 06:03:36 aips2adm Exp $
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

GDC2Token::GDC2Token( void ) : GeneralStatus(), poFileASCII( NULL ) {}

// -----------------------------------------------------------------------------

/*

GDC2Token::GDC2Token (standard)

Description:
------------
This public member function constructs a GDC2Token{ } object.

Inputs:
-------
oXin          - The x vector.
oYIn          - The y matrix.
oXErrIn       - The x error vector. If no x errors, then the vector length
                should be 0.
oYErrIn       - The y error matrix. If no y errors, then the matrix length
                should be 0.
oTokenIn      - The token vector.
oColumnIn     - The column ID vector.
oFlagIn       - The flag matrix. If no flags, then the matrix length should be
                0.
oTokenTypeIn  - The token type (default = "").
oColumnTypeIn - The column type (default = "").
bHMSIn        - The HH:MM:SS boolean (default = False);

Outputs:
--------
None.

Modification history:
---------------------
2000 Sep 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC2Token::GDC2Token( const Vector<Double>& oXIn, const Matrix<Double>& oYIn,
    const Vector<Double>& oXErrIn, const Matrix<Double>& oYErrIn,
    const Vector<String>& oTokenIn, const Vector<String>& oColumnIn,
    const Matrix<Bool>& oFlagIn, const String& oTokenTypeIn,
    const String& oColumnTypeIn, const Bool& bHMSIn ) : GeneralStatus(),
    poFileASCII( NULL ) {
  
  // Initialize the private variables
  
  try {
    initialize( oXIn, oYIn, oXErrIn, oYErrIn, oTokenIn, oColumnIn, oFlagIn,
        oTokenTypeIn, oColumnTypeIn );
    String oXLabel = String( "X Axis" );
    String oYLabel = String( "Y Axis" );
    String oTitle = String( "Title" );
    initializePlotAttrib( bHMSIn, oXLabel, oYLabel, oTitle, oXLabel, oYLabel,
        oTitle );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC2Token{ } object\n" + oAipsError.getMesg(),
        "GDC2Token", "GDC2Token" ) );
  }
  
  
  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::GDC2Token (ASCII)

Description:
------------
This public member function constructs a GDC2Token{ } object.

Inputs:
-------
oFileIn           - The ASCII file.
oTokenTypeIn      - The token type (default = "").
oColumnTypeTypeIn - The column type (default = "").
bHMSIn            - The HH:MM:SS boolean (default = False);

Outputs:
--------
None.

Modification history:
---------------------
2000 Jan 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC2Token::GDC2Token( String& oFileIn, const String& oTokenTypeIn,
    const String& oColumnTypeIn, const Bool& bHMSIn ) : GeneralStatus(),
    poFileASCII( NULL ) {

  // Allocate the memory
  
  Vector<Double> oXIn = Vector<Double>();
  Matrix<Double> oYIn = Matrix<Double>();
  Vector<Double> oXErrIn = Vector<Double>();
  Matrix<Double> oYErrIn = Matrix<Double>();
  
  Vector<String> oTokenIn = Vector<String>();
  Vector<String> oColumnIn = Vector<String>();
  
  Matrix<Bool> oFlagIn = Matrix<Bool>();

  
  // Load the data from the ASCII file
  
  try {
    loadASCII( oFileIn, oXIn, oYIn, oXErrIn, oYErrIn, oTokenIn, oColumnIn,
        oFlagIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot load data from ASCII file\n" + oAipsError.getMesg(),
        "GDC2Token", "GDC2Token" ) );
  }
  
  
  // Initialize the private variables

  try {
    initialize( oXIn, oYIn, oXErrIn, oYErrIn, oTokenIn, oColumnIn, oFlagIn,
        oTokenTypeIn, oColumnTypeIn );
    String oXLabel = String( "X Axis" );
    String oYLabel = String( "Y Axis" );
    String oTitle = String( "Title" );
    initializePlotAttrib( bHMSIn, oXLabel, oYLabel, oTitle, oXLabel, oYLabel,
        oTitle );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC2Token{ } object\n" + oAipsError.getMesg(),
        "GDC2Token", "GDC2Token" ) );
  }


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::GDC2Token (clone)

Description:
------------
This public member function constructs a GDC2Token{ } object.

Inputs:
-------
oObjectIDIn - The ObjectID.
dXMinIn     - The minimum x value.
dXMaxIn     - The maximum x value.
oTokenIn    - The tokens.
oColumnIn   - The column IDs.
bKeepIn     - The keep-flagged-data boolean.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 16 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC2Token::GDC2Token( const ObjectID& oObjectIDIn, Double& dXMinIn,
    Double& dXMaxIn, Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bKeepIn ) : GeneralStatus(), poFileASCII( NULL ) {
  
  // Get the pointer to the input GDC2Token{ } object

  ObjectController* poObjectController = NULL;
  GDC2Token* poGDC2TokenIn = NULL;
  
  try {
    poObjectController = ApplicationEnvironment::objectController();
    poGDC2TokenIn = (GDC2Token*) poObjectController->getObject( oObjectIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    String oError = "Cannot get pointer for input GDC2Token{ } object\n";
    oError += oAipsError.getMesg();
    throw( ermsg( oError, "GDC2Token", "GDC2Token" ) );
  }
  
  
  // Initialize this object
  
  GDC2Token* poGDC2TokenClone = NULL; // Keep compiler happy

  try {
    poGDC2TokenClone =
        poGDC2TokenIn->clone( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not clone data\n" + oAipsError.getMesg(), "GDC2Token",
        "GDC2Token" ) );
  }
  
  poFileASCII = new String( poGDC2TokenIn->fileASCII() );

  try {
    initialize(
        poGDC2TokenClone->x( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, True ),
        poGDC2TokenClone->y( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, True,
            False ),
        poGDC2TokenClone->xErr( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, True ),
        poGDC2TokenClone->yErr( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, True,
            False ),
        poGDC2TokenClone->token( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, True ),
        oColumnIn,
        poGDC2TokenClone->flag( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, False ),
        poGDC2TokenClone->tokenType(), poGDC2TokenClone->columnType() );
    initializePlotAttrib( poGDC2TokenClone->hms(),
        poGDC2TokenIn->getXLabel( False ), poGDC2TokenIn->getYLabel( False ),
        poGDC2TokenIn->getTitle( False ), poGDC2TokenIn->getXLabel( True ),
        poGDC2TokenIn->getYLabel( True ), poGDC2TokenIn->getTitle( True ) );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create GDC2Token{ } object\n" + oAipsError.getMesg(),
        "GDC2Token", "GDC2Token" ) );
  }
  
  
  // Deallocate the memory
  
  delete poGDC2TokenClone;


  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::GDC2Token (copy)

Description:
------------
This public member function copies a GDC2Token{ } object.

Inputs:
-------
oGDC2TokenIn - The GDC2Token{ } object.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 17 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC2Token::GDC2Token( const GDC2Token& oGDC2TokenIn ) : GeneralStatus(),
    poFileASCII( NULL ) {

  // Declare the local variables
  
  uInt uiColumn;    // The column counter
  uInt uiNumColumn; // The number of columns
  uInt uiNumToken;  // The number of tokens
  uInt uiToken;     // The token counter
  
  
  // Initialize the private variables
  
  poFileASCII = new String( oGDC2TokenIn.fileASCII() );
  
  Double dXMin = oGDC2TokenIn.xMin( False );
  Double dXMax = oGDC2TokenIn.xMax( False );
  
  Vector<String> oTokenList = oGDC2TokenIn.tokenList();
  Vector<String> oColumnList = oGDC2TokenIn.columnList();
  
  poXOld = new Vector<Double>( oGDC2TokenIn.xOld().copy() );
  poX = new Vector<Double>(
      oGDC2TokenIn.x( dXMin, dXMax, oTokenList, oColumnList, True ).copy() );
  
  poYOrig = new Matrix<Double>( oGDC2TokenIn.y( dXMin, dXMax, oTokenList,
      oColumnList, True, True ).copy() );
  poY = new Matrix<Double>( oGDC2TokenIn.y( dXMin, dXMax, oTokenList,
      oColumnList, True, False ).copy() );
  
  poXErrOld = new Vector<Double>( oGDC2TokenIn.xErrOld().copy() );
  poXErr = new Vector<Double>(
      oGDC2TokenIn.xErr( dXMin, dXMax, oTokenList, oColumnList, True ).copy() );

  poYErrOrig = new Matrix<Double>( oGDC2TokenIn.yErr( dXMin, dXMax, oTokenList,
      oColumnList, True, True ).copy() );
  poYErr = new Matrix<Double>( oGDC2TokenIn.yErr( dXMin, dXMax, oTokenList,
      oColumnList, True, False ).copy() );

  poToken = new Vector<String>( oGDC2TokenIn.token( dXMin, dXMax, oTokenList,
      oColumnList, True ).copy() );

  poFlagOrig = new Matrix<Bool>(
      oGDC2TokenIn.flag( dXMin, dXMax, oTokenList, oColumnList, True ).copy() );
  poFlag = new Matrix<Bool>( oGDC2TokenIn.flag( dXMin, dXMax, oTokenList,
      oColumnList, False ).copy() );

  poInterp = new Matrix<Bool>(
      oGDC2TokenIn.interp( dXMin, dXMax, oColumnList, oTokenList ).copy() );
  
  poTokenType = new String( oGDC2TokenIn.tokenType() );
  poColumnType = new String( oGDC2TokenIn.columnType() );
  
  uiNumToken = oTokenList.nelements();
  poTokenList = new Vector<String>( uiNumToken );
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
    (*poTokenList)(uiToken) = oTokenList(uiToken);
  }
  
  uiNumColumn = oColumnList.nelements();
  poColumnList = new Vector<String>( uiNumColumn );
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    (*poColumnList)(uiColumn) = oColumnList(uiColumn);
  }
  
  bXError = oGDC2TokenIn.xError();
  bYError = oGDC2TokenIn.yError();
  
  bHMSOld = oGDC2TokenIn.hmsOld();
  bHMS = oGDC2TokenIn.hms();
  
  oGDC2TokenIn.history( &poHistoryEvent, &poHistoryIndex, &poHistoryColumn,
      &poHistoryFlag, &poHistoryInterp, &poHistoryY, &poHistoryYErr );
  
  Vector<String> oTokenPlot = oGDC2TokenIn.getToken();
  Vector<String> oColumnPlot = Vector<String>();
  
  uiNumToken = oTokenPlot.nelements();
  poTokenPlot = new Vector<String>( uiNumToken );
  aoColumnPlot = new Vector<String>*[uiNumToken];
  
  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
    (*poTokenPlot)(uiToken) = oTokenPlot(uiToken);
    uiNumColumn = oGDC2TokenIn.getColumn( oTokenPlot(uiToken) ).nelements();
    oColumnPlot.resize( uiNumColumn, False );
    oColumnPlot = oGDC2TokenIn.getColumn( oTokenPlot(uiToken) );
    aoColumnPlot[uiToken] = new Vector<String>( uiNumColumn );
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      (*aoColumnPlot[uiToken])(uiColumn) = oColumnPlot(uiColumn);
    }
  }
  
  dXMinDefault = oGDC2TokenIn.getXMin( True );
  dXMaxDefault = oGDC2TokenIn.getXMax( True );
  dYMinDefault = oGDC2TokenIn.getYMin( True );
  dYMaxDefault = oGDC2TokenIn.getYMax( True );
  
  Double dXMinTemp = oGDC2TokenIn.getXMin();
  Double dXMaxTemp = oGDC2TokenIn.getXMax();
  Double dYMinTemp = oGDC2TokenIn.getYMin();
  Double dYMaxTemp = oGDC2TokenIn.getYMax();
  
  zoomxy( dXMinTemp, dXMaxTemp, dYMinTemp, dYMaxTemp );

  bFlag = oGDC2TokenIn.getFlag();  
  bColor = oGDC2TokenIn.getColor();
  bLine = oGDC2TokenIn.getLine();
  bKeep = oGDC2TokenIn.getKeep();
  
  poXLabelDefault = new String( oGDC2TokenIn.getXLabel( True ) );
  poYLabelDefault = new String( oGDC2TokenIn.getYLabel( True ) );
  poTitleDefault = new String( oGDC2TokenIn.getTitle( True ) );
  
  poXLabel = new String( oGDC2TokenIn.getXLabel() );
  poYLabel = new String( oGDC2TokenIn.getYLabel() );
  poTitle = new String( oGDC2TokenIn.getTitle() );
    
  poXLabelDefaultOld = new String( *poXLabelDefault );
  poXLabelOld = new String( *poXLabel );

  bArgCheck = oGDC2TokenIn.getArgCheck();
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::~GDC2Token

Description:
------------
This public member function destructs a GDC2Token{ } object.

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

GDC2Token::~GDC2Token( void ) {

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
  delete poColumnType;

  delete poTokenList;
  delete poColumnList;

  delete poHistoryEvent;
  delete poHistoryIndex;
  delete poHistoryColumn;
  delete poHistoryFlag;
  delete poHistoryInterp;
  delete poHistoryY;
  delete poHistoryYErr;
  
  delete poInterp;
  
  delete poTokenPlot;
  delete aoColumnPlot;
  
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

GDC2Token::fileASCII

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
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC2Token::fileASCII( void ) const {

  // Return the ASCII file name
  
  return( String( *poFileASCII ) );

}

// -----------------------------------------------------------------------------

/*

GDC2Token::getArgCheck

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
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::getArgCheck( void ) const {

  // Return the check-arguments boolean
  
  return( bArgCheck );

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setArgCheck

Description:
------------
This public member function sets the check-arguments boolean, to increase
speed.  Checking is not performed in the plot( ) member function.  Also, no
checking should be perfromed when a GDC2Token{ } object is created from (and
the arguments checked in) glish.

Inputs:
-------
bArgCheckIn - The check-arguments boolean (default = True).

Outputs:
--------
None.

Modification history:
---------------------
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setArgCheck( const Bool& bArgCheckIn ) {

  // Set the check-arguments boolean and return
  
  bArgCheck = bArgCheckIn;
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::dumpASCII

Description:
------------
This public member function dumps data to an ASCII file.  Interpolated data,
flagged in GDC2Token{ } objects, is dumped as unflagged.  NB: I'm using
functions from stdio.h because I dislike the classes in iostream.h.

Inputs:
-------
oFileIn   - The ASCII file name.
XMinIn    - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean (default = False).

Outputs:
--------
The ASCII file.

Modification history:
---------------------
2001 Jan 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::dumpASCII( String& oFileIn, Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bKeepIn ) const {

  // Declare the local variables
  
  uInt uiColumn;    // The column ID counter
  uInt uiIndex;     // The index counter
  uInt uiNumColumn; // The number of olumn IDs
  
  FILE* pmtStream;  // The data output stream
  
  
  // Get the indices

  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "dumpASCII" ) );
  }
  
  
  // Get the number of column IDs and the column numbers
  
  uiNumColumn = oColumnIn.nelements();
  
  Vector<Int> oColumn = columnNumber( oColumnIn );
  

  // Open the ASCII file

  oFileIn.gsub( RXwhite, "" );
  
  pmtStream = fopen( oFileIn.chars(), "w" );
  
  if ( pmtStream == NULL ) {
    throw( ermsg( "Cannot create ASCII file", "GDC2Token", "dumpASCII" ) );
  }
  
  
  // Dump the column IDs to the ASCII file
  
  fprintf( pmtStream, "%d ", oColumnIn.nelements() );
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    fprintf( pmtStream, "%s ", oColumnIn(uiColumn).chars() );
  }
  
  fprintf( pmtStream, "\n" );
  
  
  // Dump the data to the ASCII file
  
  for ( uiIndex = 0; uiIndex < oIndex.nelements(); uiIndex++ ) {
  
    fprintf( pmtStream, "%20f ", (*poX)(oIndex(uiIndex)) );
    
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      fprintf( pmtStream, "%20f ", (*poY)(oIndex(uiIndex),oColumn(uiColumn)) );
    }
    
    if ( bXError ) {
      fprintf( pmtStream, "%20f ", (*poXErr)(oIndex(uiIndex)) );
    } else {
      fprintf( pmtStream, "%20f ", 0.0 );
    }
    
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      if ( bYError ) {
        fprintf( pmtStream, "%20f ",
            (*poYErr)(oIndex(uiIndex),oColumn(uiColumn)) );
      } else {
        fprintf( pmtStream, "%20f ", 0.0 );
      }
    }
    
    fprintf( pmtStream, "%s ", (*poToken)(oIndex(uiIndex)).chars() );
    
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      fprintf( pmtStream, "%u ",
          (uInt) (*poFlag)(oIndex(uiIndex),oColumn(uiColumn)) );
    }
    
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      fprintf( pmtStream, "%u ",
          (uInt) (*poInterp)(oIndex(uiIndex),oColumn(uiColumn)) );
    }
    
    fprintf( pmtStream, "\n" );

  }
  
  
  // Close the ASCII file
  
  fclose( pmtStream );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::clone

Description:
------------
This public member function returns a cloned GDC2Token{ } object.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.

Outputs:
--------
The cloned GDC2Token{ } object, returned via the function value.

Modification history:
---------------------
2001 Jan 16 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GDC2Token* GDC2Token::clone( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiColumn;    // The column counter
  uInt uiData;      // The data counter
  uInt uiNumColumn; // The number of columns
  uInt uiNumData;   // The number of data
  
  
  // Get the indices and column numbers

  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "clone" ) );
  }
  
  
  // Initialize the Vector<> objects
  
  Vector<Double> oXClone = Vector<Double>();
  Vector<Double> oXErrClone = Vector<Double>();
  
  Matrix<Double> oYClone = Vector<Double>();
  Matrix<Double> oYErrClone = Vector<Double>();
  
  Vector<String> oTokenClone = Vector<String>();
  Vector<String> oColumnClone = Vector<String>();
  
  Matrix<Bool> oFlagClone = Matrix<Bool>();
  
  
  // Get the desired data from this object
  
  uiNumData = oIndex.nelements();
  
  Vector<Int> oColumn = columnNumber( oColumnIn );
  uiNumColumn = oColumn.nelements();
  
  oXClone.resize( uiNumData, False );
  oYClone.resize( uiNumData, uiNumColumn );
  
  oFlagClone.resize( uiNumData, uiNumColumn );
  
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    oXClone(uiData) = (*poX)(oIndex(uiData));
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      oYClone(uiData,uiColumn) = (*poY)(oIndex(uiData),oColumn(uiColumn));
      oFlagClone(uiData,uiColumn) = (*poFlag)(oIndex(uiData),oColumn(uiColumn));
    }
  }
  
  if ( bXError ) {
    oXErrClone.resize( uiNumData, False );
    for ( uiData = 0; uiData < uiNumData; uiData++ ) {
      oXErrClone(uiData) = (*poXErr)(oIndex(uiData));
    }
  }
  
  if ( bYError ) {
    oYErrClone.resize( uiNumData, uiNumColumn );
    for ( uiData = 0; uiData < uiNumData; uiData++ ) {
      for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
        oYErrClone(uiData,uiColumn) =
            (*poYErr)(oIndex(uiData),oColumn(uiColumn));
      }
    }
  }

  oTokenClone.resize( uiNumData, False );
  
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    oTokenClone(uiData) = (*poToken)(oIndex(uiData));
  }
  
  oColumnClone = Vector<String>( oColumnIn.copy() );

  String oTokenType = tokenType();
  String oColumnType = columnType();
  
  
  // Create the cloned GDC2Token{ } object

  GDC2Token* poGDC2TokenClone = NULL;
  
  try {
    poGDC2TokenClone = new GDC2Token( oXClone, oYClone, oXErrClone, oYErrClone,
        oTokenClone, oColumnClone, oFlagClone, oTokenType, oColumnType, bHMS );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg(
        "Cannot create cloned GDC2Token{ } object\n" + oAipsError.getMesg(),
        "GDC2Token", "clone" ) );
  }
  
  
  // Return the cloned GDC2Token{ } object
  
  return( poGDC2TokenClone );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::length

Description:
------------
This public member function returns the length.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.

Outputs:
--------
The length, returned via the function value.

Modification history:
---------------------
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt GDC2Token::length( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bKeepIn ) const {
    
  // Declare the local variables
  
  uInt uiLength; // The length
  
  
  // Determine the length and return
  
  uiLength = 0; // Keep compiler happy
  
  try {
    uiLength =
        index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn ).nelements();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "length" ) );
  }
  
  return( uiLength );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::x

Description:
------------
This public member function returns x values.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.

Outputs:
--------
The x values, returned via the function value.

Modification history:
---------------------
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC2Token::x( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the x values and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
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

GDC2Token::xOld

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

Vector<Double> GDC2Token::xOld( void ) const {

  // Return the old x values
  
  return( Vector<Double>( poXOld->copy() ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::y

Description:
------------
This public member function returns y values.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.
bOrigIn   - The original-data (non-interpolated) boolean.

Outputs:
--------
The y values, returned via the function value.

Modification history:
---------------------
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Matrix<Double> GDC2Token::y( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn, const Bool& bKeepIn,
    const Bool& bOrigIn ) const {
  
  // Declare the local variables
  
  uInt uiColumn; // The column number
  uInt uiData;   // The data counter

  
  // Find the y values and return them

  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "y" ) );
  }
  
  Vector<Int> oColumn = columnNumber( oColumnIn );
  Matrix<Double> oY =
      Matrix<Double>( oIndex.nelements(), oColumn.nelements(), 0.0 );
  
  if ( !bOrigIn ) {
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
        oY(uiData,uiColumn) = (*poY)(oIndex(uiData),oColumn(uiColumn));
      }
    }
  } else {
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
        oY(uiData,uiColumn) = (*poYOrig)(oIndex(uiData),oColumn(uiColumn));
      }
    }
  }
  
  return( oY );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::xErr

Description:
------------
This public member function returns x errors.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.

Outputs:
--------
The x errors, returned via the function value.

Modification history:
---------------------
2001 Jan 02 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> GDC2Token::xErr( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the x errors and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
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

GDC2Token::xErrOld

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

Vector<Double> GDC2Token::xErrOld( void ) const {

  // Return the old x errors
  
  return( Vector<Double>( poXErrOld->copy() ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::yErr

Description:
------------
This public member function returns y errors.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.
bOrigIn   - The original-data (non-interpolated) boolean.

Outputs:
--------
The y errors, returned via the function value.

Modification history:
---------------------
2001 Jan 02 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Matrix<Double> GDC2Token::yErr( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn, const Bool& bKeepIn,
    const Bool& bOrigIn ) const {
  
  // Declare the local variables
  
  uInt uiColumn; // The column number
  uInt uiData;   // The data counter

  
  // Find the y errors and return them
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "yErr" ) );
  }
  
  Vector<Int> oColumn = columnNumber( oColumnIn );
  Matrix<Double> oYErr = Matrix<Double>();
 
  if ( bYError ) {
    oYErr.resize( oIndex.nelements(), oColumn.nelements() );
    if ( !bOrigIn ) {
      for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
        for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
          oYErr(uiData,uiColumn) = (*poYErr)(oIndex(uiData),oColumn(uiColumn));
        }
      }
    } else {
      for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
        for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
          oYErr(uiData,uiColumn) =
              (*poYErrOrig)(oIndex(uiData),oColumn(uiColumn));
        }
      }
    }
  }
  
  return( oYErr );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::xError

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
2001 Jan 02 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::xError( void ) const {

  // Return the x-error boolean
  
  return( bXError );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::yError

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
2001 Jan 02 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::yError( void ) const {

  // Return the y-error boolean
  
  return( bYError );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::token

Description:
------------
This public member function returns tokens.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.

Outputs:
--------
The tokens, returned via the function value.

Modification history:
---------------------
2001 Jan 03 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GDC2Token::token( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find the tokens and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    Vector<String> oTokenList = tokenList();
    oIndex = index( dXMinIn, dXMaxIn, oTokenList, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
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

GDC2Token::tokenType

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
2001 Jan 03 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC2Token::tokenType( void ) const {

  // Return the token type
  
  return( *poTokenType );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::tokenList

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
2001 Jan 03 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GDC2Token::tokenList( void ) const {

  // Return the list of unique tokens
  
  return( poTokenList->copy() );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::columnType

Description:
------------
This public member function returns the column type.

Inputs:
-------
None.

Outputs:
--------
The column type, returned via the function value.

Modification history:
---------------------
2001 Jan 03 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC2Token::columnType( void ) const {

  // Return the column type
  
  return( *poColumnType );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::columnList

Description:
------------
This public member function returns the list of unique columns.

Inputs:
-------
None.

Outputs:
--------
The list of unique columns, returned via the function value.

Modification history:
---------------------
2001 Jan 03 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GDC2Token::columnList( void ) const {

  // Return the list of unique columns
  
  return( poColumnList->copy() );
  
}

// -----------------------------------------------------------------------------

/*

columnNumber (column ID)

Description:
------------
This public member returns the column number.

Inputs:
-------
oColumnIn - The column ID.

Outputs:
--------
The column number, returned via the function value.

Modification history:
---------------------
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt GDC2Token::columnNumber( String& oColumnIn ) const {

  // Declare the local variables
  
  uInt uiColumn; // The column counter
  
  
  // Fix/check the inputs
  
  Vector<String> oColumnTemp = Vector<String>( 1, oColumnIn );
  
  if ( !checkColumn( oColumnTemp ) ) {
    throw( ermsg( "Invalid column ID", "GDC2Token", "columnNumber" ) );
  }
  
  
  // Get the column number and return
  
  oColumnIn = oColumnTemp(0);
  
  for ( uiColumn = 0; uiColumn < poColumnList->nelements(); uiColumn++ ) {
    if ( oColumnIn.matches( (*poColumnList)(uiColumn) ) ) {
      return( uiColumn );
    }
  }
  
  throw( ermsg( "Invalid column ID", "GDC2Token", "columnNumber" ) );

}

// -----------------------------------------------------------------------------

/*

columnNumber (column IDs)

Description:
------------
This public member returns the column numbers.

Inputs:
-------
oColumnIn - The column IDs.

Outputs:
--------
The column numbers, returned via the function value.

Modification history:
---------------------
2000 Dec 21 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> GDC2Token::columnNumber( Vector<String>& oColumnIn ) const {

  // Declare the local variables
  
  uInt uiColumn;  // A column counter
  uInt uiColumn2; // A column counter
  
  
  // Fix/check the inputs
  
  if ( !checkColumn( oColumnIn ) ) {
    throw( ermsg( "Invalid column ID(s)", "GDC2Token", "columnNumber" ) );
  }
  
  
  // Get the column numbers and return
  
  Vector<Int> oColumn = Vector<Int>( oColumnIn.nelements() );

  for ( uiColumn = 0; uiColumn < oColumnIn.nelements(); uiColumn++ ) {
    oColumnIn(uiColumn).gsub( RXwhite, "" );
    oColumnIn(uiColumn).upcase();
    for ( uiColumn2 = 0; uiColumn2 < poColumnList->nelements(); uiColumn2++ ) {
      if ( oColumnIn(uiColumn).matches( (*poColumnList)(uiColumn2) ) ) {
        oColumn(uiColumn) = uiColumn2;
        break;
      }
    }
  }
  
  return( oColumn );

}

// -----------------------------------------------------------------------------

/*

GDC2Token::flag

Description:
------------
This public member function returns flags.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bOrigIn   - The original-flag boolean.

Outputs:
--------
The flags, returned via the function value.

Modification history:
---------------------
2001 Jan 03 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Matrix<Bool> GDC2Token::flag( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bOrigIn ) const {
  
  // Declare the local variables
  
  uInt uiColumn; // The column counter
  uInt uiData;   // The data counter
  
  
  // Find the flags and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "flag" ) );
  }
  
  Vector<Int> oColumn = columnNumber( oColumnIn );
  Matrix<Bool> oFlag =
      Matrix<Bool>( oIndex.nelements(), oColumn.nelements(), 0.0 );

  if ( !bOrigIn ) {
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
        oFlag(uiData,uiColumn) = (*poFlag)(oIndex(uiData),oColumn(uiColumn));
      }
    }
  } else {
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
        oFlag(uiData,uiColumn) =
            (*poFlagOrig)(oIndex(uiData),oColumn(uiColumn));
      }
    }
  }
  
  return( oFlag );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::interp

Description:
------------
This public member function returns interpolation booleans.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.

Outputs:
--------
The interpolation booleans, returned via the function value.

Modification history:
---------------------
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Matrix<Bool> GDC2Token::interp( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn ) const {
  
  // Declare the local variables
  
  uInt uiColumn; // The column counter
  uInt uiData;   // The data counter
  
  
  // Find the interpolation booleans and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "interp" ) );
  }
  
  Vector<Int> oColumn = columnNumber( oColumnIn );
  Matrix<Bool> oInterp =
      Matrix<Bool>( oIndex.nelements(), oColumn.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
      oInterp(uiData,uiColumn) = (*poInterp)(oIndex(uiData),oColumn(uiColumn));
    }
  }
  
  return( oInterp );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::index (column number)

Description:
------------
This public member function returns the indices.

Inputs:
-------
dXMinIn    - The minimum x value.
dXMaxIn    - The maximum x value.
oTokenIn   - The tokens.
uiColumnIn - The column number.
bKeepIn    - The keep-flagged-data boolean.

Outputs:
--------
The indices, returned via the function value.

Modification history:
---------------------
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> GDC2Token::index( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const uInt& uiColumnIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData;      // The data counter
  uInt uiNumData;   // The number of data
  uInt uiNumIndex;  // The number of indices
  uInt uiNumToken;  // The number of tokens
  uInt uiToken;     // The token counter
  
  
  // Fix/check the inputs
  
  if ( uiColumnIn >= poColumnList->nelements() ) {
    throw( ermsg( "Invalid column number", "GDC2Token", "index" ) );
  }
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token argument(s)", "GDC2Token", "index" ) );
  }
  
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "GDC2Token", "index" ) );
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
           ( !(*poFlag)(uiData,uiColumnIn) || bKeepIn ) ) {
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

GDC2Token::index (column numbers)

Description:
------------
This public member function returns the indices.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column numbers.
bKeepIn   - The keep-flagged-data boolean.

Outputs:
--------
The indices, returned via the function value.

Modification history:
---------------------
2000 Dec 21 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> GDC2Token::index( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<Int>& oColumnIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiColumn;    // The column counter
  uInt uiData;      // The data counter
  uInt uiNumColumn; // The number of columns
  uInt uiNumData;   // The number of data
  uInt uiNumIndex;  // The number of indices
  uInt uiNumToken;  // The number of tokens
  uInt uiToken;     // The token counter
  
  
  // Fix/check the inputs
  
  if ( !checkColumn( oColumnIn ) ) {
    throw( ermsg( "Invalid column number(s)", "GDC2Token", "index" ) );
  }
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token argument(s)", "GDC2Token", "index" ) );
  }
  
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "GDC2Token", "index" ) );
  }
  
  
  // Find the indices and return
  
  uiNumData = poX->nelements();
  uiNumToken = oTokenIn.nelements();
  uiNumColumn = oColumnIn.nelements();
  
  uiNumIndex = 0;
  Vector<Int> oIndex = Vector<Int>();

  for ( uiToken = 0; uiToken < uiNumToken; uiToken++ ) {
    for ( uiData = 0; uiData < uiNumData; uiData++ ) {
      if ( (*poX)(uiData) >= dXMinIn && (*poX)(uiData) <= dXMaxIn &&
           (*poToken)(uiData) == oTokenIn(uiToken) ) {
        for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
          if ( (*poFlag)(uiData,oColumnIn(uiColumn)) && !bKeepIn ) {
            break;
          }
        }
        if ( uiColumn >= uiNumColumn ) {
          uiNumIndex += 1;
          oIndex.resize( uiNumIndex, True );
          oIndex(uiNumIndex-1) = uiData;
        }
      }
    }
  }

  Vector<Int> oSortKey = StatToolbox::sortkey( oIndex );
  StatToolbox::sort( oSortKey, oIndex );

  return( oIndex );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::index (column IDs)

Description:
------------
This public member function returns the indices.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.

Outputs:
--------
The indices, returned via the function value.

Modification history:
---------------------
2000 Dec 21 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> GDC2Token::index( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bKeepIn ) const {
  
  // Fix/check the inputs

  if ( !checkColumn( oColumnIn ) ) {
    throw( ermsg( "Invalid column ID(s)", "GDC2Token", "index" ) );
  }
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token argument(s)", "GDC2Token", "index" ) );
  }
  
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "GDC2Token", "index" ) );
  }
  
  
  // Find the indices and return
  
  Vector<Int> oColumn = columnNumber( oColumnIn );
  Vector<Int> oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumn, bKeepIn );
  
  return( oIndex );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::xMax (global)

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
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::xMax( const Bool& bPlotIn ) const {

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

GDC2Token::xMax (specific)

Description:
------------
This public member function returns the maximum x value.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.
bPlotIn   - The plot boolean (include x errors).

Outputs:
--------
The maximum x value, returned via the function value.

Modification history:
---------------------
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::xMax( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn, const Bool& bKeepIn,
    const Bool& bPlotIn ) const {
  
  // Declare the local variables
  
  uInt uiData;  // The data counter
  
  Double dXMax; // The maximum x value
  
  
  // Find and return the maximum x value
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "xMax" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC2Token", "xMax" ) );
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

GDC2Token::xMin (global)

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
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::xMin( const Bool& bPlotIn ) const {

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

GDC2Token::xMin (specific)

Description:
------------
This public member function returns the minimum x value.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.
bPlotIn   - The plot boolean (include x errors).

Outputs:
--------
The minimum x value, returned via the function value.

Modification history:
---------------------
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::xMin( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn, const Bool& bKeepIn,
    const Bool& bPlotIn ) const {
  
  // Declare the local variables
  
  uInt uiData;  // The data counter
  
  Double dXMin; // The minimum x value
  
  
  // Find and return the minimum x value
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "xMin" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC2Token", "xMin" ) );
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

GDC2Token::yMax (global)

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
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::yMax( const Bool& bPlotIn ) const {

  // Declare the local variables

  Double dXMax = xMax(); // The maximum x value
  Double dXMin = xMin(); // The minimum x value

  Double dYMax = 0.0;    // The maximum y value


  // Return the maximum y value
  
  Vector<String> oToken = Vector<String>( poTokenList->copy() );
  Vector<String> oColumn = Vector<String>( poColumnList->copy() );

  try {
    dYMax = yMax( dXMin, dXMax, oToken, oColumn, bKeep, bPlotIn );
  }

  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not find maximum y value" + oAipsError.getMesg(),
        "GDC2Token", "yMax" ) );
  }
  
  return( dYMax );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::yMax (specific)

Description:
------------
This public member function returns the maximum y value.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.
bPlotIn   - The plot boolean (include y errors).

Outputs:
--------
The maximum y value, returned via the function value.

Modification history:
---------------------
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::yMax( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn, const Bool& bKeepIn,
    const Bool& bPlotIn ) const {
  
  // Declare the local variables
  
  uInt uiColumn; // The column counter
  uInt uiData;   // The data counter
  
  Double dYMax;  // The maximum y value
  
  
  // Find and return the maximum y value

  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "yMax" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC2Token", "yMax" ) );
  }
  
  Vector<Int> oColumn = columnNumber( oColumnIn );
  
  Matrix<Double> oY =
      Matrix<Double>( oIndex.nelements(), oColumn.nelements(), 0.0 );
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
      oY(uiData,uiColumn) = (*poY)(oIndex(uiData),oColumn(uiColumn));
    }
  }
  
  if ( !bPlotIn || !bYError ) {
    dYMax = StatToolbox::max( &oY, NULL );
    if ( oY.nelements() == 1 ) {
      dYMax += 1.0;
    }
  } else {
    Matrix<Double> oYErr =
        Matrix<Double>( oIndex.nelements(), oColumn.nelements(), 0.0 );
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
        oYErr(uiData,uiColumn) = (*poYErr)(oIndex(uiData),oColumn(uiColumn));
      }
    }
    dYMax = StatToolbox::max( &oY, &oYErr );
  }
  
  return( dYMax );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::yMin (global)

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
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::yMin( const Bool& bPlotIn ) const {

  // Declare the local variables

  Double dXMax = xMax(); // The maximum x value
  Double dXMin = xMin(); // The minimum y value

  Double dYMin = 0.0;    // The minimum y value


  // Return the minimum y value
  
  Vector<String> oToken = Vector<String>( poTokenList->copy() );
  Vector<String> oColumn = Vector<String>( poColumnList->copy() );

  try {
    dYMin = yMin( dXMin, dXMax, oToken, oColumn, bKeep, bPlotIn );
  }

  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not find minimum y value" + oAipsError.getMesg(),
        "GDC2Token", "yMin" ) );
  }

  return( dYMin );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::yMin (specific)

Description:
------------
This public member function returns the minimum y value.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean).
bPlotIn   - The plot boolean (include y errors).

Outputs:
--------
The minimum y value, returned via the function value.

Modification history:
---------------------
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::yMin( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn, const Bool& bKeepIn,
    const Bool& bPlotIn ) const {
  
  // Declare the local variables
  
  uInt uiColumn; // The column counter
  uInt uiData;   // The data counter
  
  Double dYMin;  // The minimum y value
  
  
  // Find and return the minimum y value
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "yMin" ) );
  }

  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC2Token", "yMin" ) );
  }
  
  Vector<Int> oColumn = columnNumber( oColumnIn );
  
  Matrix<Double> oY =
     Matrix<Double>( oIndex.nelements(), oColumn.nelements(), 0.0 );
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
      oY(uiData,uiColumn) = (*poY)(oIndex(uiData),oColumn(uiColumn));
    }
  }
  
  if ( !bPlotIn || !bYError ) {
    dYMin = StatToolbox::min( &oY, NULL );
    if ( oY.nelements() == 1 ) {
      dYMin -= 1.0;
    }
  } else {
    Matrix<Double> oYErr =
        Matrix<Double>( oIndex.nelements(), oColumn.nelements(), 0.0 );
    for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
        oYErr(uiData,uiColumn) = (*poYErr)(oIndex(uiData),oColumn(uiColumn));
      }
    }
    dYMin = StatToolbox::min( &oY, &oYErr );
  }
  
  return( dYMin );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::xErrMax (global)

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
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::xErrMax( void ) const {

  // Declare the local variables

  Double dXErrMax = 0.0; // The maximum x error

  Double dXMax = xMax(); // The maximum x value
  Double dXMin = xMin(); // The minimum x value


  // Return the maximum x error
  
  Vector<String> oToken = poTokenList->copy();
  Vector<String> oColumn = poColumnList->copy();

  try {
    dXErrMax = xErrMax( dXMin, dXMax, oToken, oColumn, bKeep );
  }

  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not find maximum x error" + oAipsError.getMesg(),
        "GDC2Token", "xErrMax" ) );
  }
  
  return( dXErrMax );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::xErrMax (specific)

Description:
------------
This public member function returns the maximum x error.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.

Outputs:
--------
The maximum x error, returned via the function value.

Modification history:
---------------------
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::xErrMax( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find and return the maximum x error
  
  if ( !bXError ) {
    throw( ermsg( "No x errors", "GDC2Token", "xErrMax" ) );
  }
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "xErrMax" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC2Token", "xErrMax" ) );
  }
  
  Vector<Double> oXErr = Vector<Double>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oXErr(uiData) = (*poXErr)(oIndex(uiData));
  }
  
  return( StatToolbox::max( &oXErr, NULL ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::xErrMin (global)

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
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::xErrMin( void ) const {

  // Declare the local variables

  Double dXErrMin = 0.0; // The minimum x error
  
  Double dXMax = xMax(); // The maximum x value
  Double dXMin = xMin(); // The minimum x value


  // Return the minimum x error
  
  Vector<String> oToken = poTokenList->copy();
  Vector<String> oColumn = poColumnList->copy();

  try {
    dXErrMin = xErrMin( dXMin, dXMax, oToken, oColumn, bKeep );
  }

  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not find minimum x error" + oAipsError.getMesg(),
        "GDC2Token", "xErrMin" ) );
  }
  
  return( dXErrMin );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::xErrMin (specific)

Description:
------------
This public member function returns the minimum x error.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.

Outputs:
--------
The minimum x error, returned via the function value.

Modification history:
---------------------
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::xErrMin( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiData; // The data counter
  
  
  // Find and return the maximum x error
  
  if ( !bXError ) {
    throw( ermsg( "No x errors", "GDC2Token", "xErrMin" ) );
  }
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "xErrMin" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC2Token", "xErrMin" ) );
  }
  
  Vector<Double> oXErr = Vector<Double>( oIndex.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    oXErr(uiData) = (*poXErr)(oIndex(uiData));
  }
  
  return( StatToolbox::min( &oXErr, NULL ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::yErrMax (global)

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
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::yErrMax( void ) const {

  // Declare the local variables

  Double dXMax = xMax(); // The maximum x value
  Double dXMin = xMin(); // The minimum x value

  Double dYErrMax = 0.0; // The maximum y error


  // Return the maximum y error
  
  Vector<String> oToken = poTokenList->copy();
  Vector<String> oColumn = poColumnList->copy();

  try {
    dYErrMax = yErrMax( dXMin, dXMax, oToken, oColumn, bKeep );
  }

  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not find maximum y error" + oAipsError.getMesg(),
        "GDC2Token", "yErrMax" ) );
  }
  
  return( dYErrMax );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::yErrMax (specific)

Description:
------------
This public member function returns the maximum y error.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.

Outputs:
--------
The maximum y error, returned via the function value.

Modification history:
---------------------
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::yErrMax( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiColumn; // The column counter
  uInt uiData;   // The data counter
  
  
  // Find and return the maximum y error
  
  if ( !bYError ) {
    throw( ermsg( "No y errors", "GDC2Token", "yErrMax" ) );
  }
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "yErrMax" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC2Token", "yErrMax" ) );
  }
  
  Vector<Int> oColumn = columnNumber( oColumnIn );
  Matrix<Double> oYErr =
      Matrix<Double>( oIndex.nelements(), oColumn.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
      oYErr(uiData,uiColumn) = (*poYErr)(oIndex(uiData),oColumn(uiColumn));
    }
  }
  
  return( StatToolbox::max( &oYErr, NULL ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::yErrMin (global)

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
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::yErrMin( void ) const {

  // Declare the local variables

  Double dXMax = xMax(); // The maximum x value
  Double dXMin = xMin(); // The minimum x value

  Double dYErrMin = 0.0; // The minimum y error


  // Return the minimum y error
  
  Vector<String> oToken = poTokenList->copy();
  Vector<String> oColumn = poColumnList->copy();

  try {
    dYErrMin = yErrMin( dXMin, dXMax, oToken, oColumn, bKeep );
  }

  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not find minimum y error" + oAipsError.getMesg(),
        "GDC2Token", "yErrMin" ) );
  }
  
  return( dYErrMin );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::yErrMin (specific)

Description:
------------
This public member function returns the minimum y error.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.

Outputs:
--------
The minimum y error, returned via the function value.

Modification history:
---------------------
2001 Jan 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::yErrMin( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bKeepIn ) const {
  
  // Declare the local variables
  
  uInt uiColumn; // The column counter
  uInt uiData;   // The data counter
  
  
  // Find and return the maximum y error
  
  if ( !bYError ) {
    throw( ermsg( "No y errors", "GDC2Token", "yErrMin" ) );
  }
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "yErrMin" ) );
  }
  
  if ( oIndex.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC2Token", "yErrMin" ) );
  }
  
  Vector<Int> oColumn = columnNumber( oColumnIn );
  Matrix<Double> oYErr =
      Matrix<Double>( oIndex.nelements(), oColumn.nelements(), 0.0 );
  
  for ( uiData = 0; uiData < oIndex.nelements(); uiData++ ) {
    for ( uiColumn = 0; uiColumn < oColumn.nelements(); uiColumn++ ) {
      oYErr(uiData,uiColumn) = (*poYErr)(oIndex(uiData),oColumn(uiColumn));
    }
  }
  
  return( StatToolbox::min( &oYErr, NULL ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::flagged

Description:
------------
This public member function returns flagged data indices.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column ID.

Outputs:
--------
The flagged data indices, returned via the function value.

Modification history:
---------------------
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> GDC2Token::flagged( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, String& oColumnIn ) const {
  
  // Declare the local variables
  
  uInt uiColumn;       // The column number
  uInt uiIndex;        // The index counter
  uInt uiNumIndex;     // The number of indices
  uInt uiNumIndexFlag; // The number of True booleans
  
  
  // Get the column number
  
  uiColumn = 0; // Keep compiler happy
  
  try {
    uiColumn = columnNumber( oColumnIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Invalid column ID\n" + oAipsError.getMesg(), "GDC2Token",
        "flagged" ) );
  }
  
  
  // Find the flagged data indices and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, uiColumn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "flagged" ) );
  }
  
  uiNumIndex = oIndex.nelements();
  
  Vector<Int> oIndexFlag = Vector<Int>();
  uiNumIndexFlag = oIndexFlag.nelements();
  
  for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
    if ( !(*poFlag)(oIndex(uiIndex),uiColumn) ) {
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

GDC2Token::interpolated

Description:
------------
This public member function returns interpolated data indices.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column ID.

Outputs:
--------
The interpolated data indices, returned via the function value.

Modification history:
---------------------
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> GDC2Token::interpolated( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, String& oColumnIn ) const {
  
  // Declare the local variables

  uInt uiColumn;         // The column number  
  uInt uiIndex;          // The index counter
  uInt uiNumIndex;       // The number of indices
  uInt uiNumIndexInterp; // The number of True booleans
  
  
  // Get the column number
  
  uiColumn = 0; // Keep compiler happy
  
  try {
    uiColumn = columnNumber( oColumnIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Invalid column ID\n" + oAipsError.getMesg(), "GDC2Token",
        "interpolated" ) );
  }
  
  
  // Find the interpolated data indices and return
  
  Vector<Int> oIndex = Vector<Int>(); // Keep compiler happy
  
  try {
    oIndex = index( dXMinIn, dXMaxIn, oTokenIn, uiColumn, False );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
        "interpolated" ) );
  }
  
  uiNumIndex = oIndex.nelements();
  
  Vector<Int> oIndexInterp = Vector<Int>();
  uiNumIndexInterp = oIndexInterp.nelements();
  
  for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
    if ( !(*poInterp)(oIndex(uiIndex),uiColumn) ) {
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

GDC2Token::mean

Description:
------------
This public member function returns the mean y value.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.
bWeightIn - The weight boolean.

Outputs:
--------
The mean y value, returned via the function value.

Modification history:
---------------------
2001 Jan 17 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::mean( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn, const Bool& bKeepIn,
    const Bool& bWeightIn ) const {
  
  // Declare the local variables
  
  Double dMean; // The mean y value
  
  
  // Find and return the mean y value
  
  Matrix<Double> oY = Matrix<Double>(); // Keep compiler happy
  
  try {
    oY = y( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn, False ).copy();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in y( )\n" + oAipsError.getMesg(), "GDC2Token",
        "mean" ) );
  }
  
  if ( oY.nelements() < 1 ) {
    throw( ermsg( "No data in range", "GDC2Token", "mean" ) );
  }
  
  if ( !bWeightIn || !bYError ) {
    dMean = StatToolbox::mean( &oY, NULL );
  } else {
    Matrix<Double> oYErr = Matrix<Double>(); // Keep compiler happy
    try {
      oYErr =
          yErr( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn, False ).copy();
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in yErr( )\n" + oAipsError.getMesg(), "GDC2Token",
          "mean" ) );
    }
    dMean = StatToolbox::mean( &oY, &oYErr );
  }
  
  return( dMean );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::meanErr

Description:
------------
This public member function returns the y mean error.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.
bWeightIn - The weight boolean.

Outputs:
--------
The y mean error, returned via the function value.

Modification history:
---------------------
2001 Jan 17 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::meanErr( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn, const Bool& bKeepIn,
    const Bool& bWeightIn ) const {
  
  // Declare the local variables
  
  Double dMeanErr; // The y mean error
  
  
  // Find and return the y mean error
  
  Matrix<Double> oY = Matrix<Double>(); // Keep compiler happy
  
  try {
    oY = y( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn, False ).copy();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in y( )\n" + oAipsError.getMesg(), "GDC2Token",
        "meanErr" ) );
  }
  
  if ( oY.nelements() < 2 ) {
    throw( ermsg( "Not enough data in range", "GDC2Token", "meanErr" ) );
  }
  
  if ( !bWeightIn || !bYError ) {
    dMeanErr = StatToolbox::meanerr( &oY, NULL );
  } else {
    Matrix<Double> oYErr = Matrix<Double>(); // Keep compiler happy
    try {
      oYErr =
          yErr( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn, False ).copy();
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in yErr( )\n" + oAipsError.getMesg(), "GDC2Token",
          "meanErr" ) );
    }
    dMeanErr = StatToolbox::meanerr( &oY, &oYErr );
  }
  
  return( dMeanErr );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::stdDev

Description:
------------
This public member function returns the y standard deviation.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.
bWeightIn - The weight boolean.

Outputs:
--------
The y standard deviation, returned via the function value.

Modification history:
---------------------
2001 Jan 17 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::stdDev( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn, const Bool& bKeepIn,
    const Bool& bWeightIn ) const {
  
  // Declare the local variables
  
  Double dStdDev; // The y standard deviation
  
  
  // Find and return the y standard deviation
  
  Matrix<Double> oY = Matrix<Double>(); // Keep compiler happy
  
  try {
    oY = y( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn, False ).copy();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in y( )\n" + oAipsError.getMesg(), "GDC2Token",
        "stdDev" ) );
  }
  
  if ( oY.nelements() < 2 ) {
    throw( ermsg( "Not enough data in range", "GDC2Token", "stdDev" ) );
  }
  
  if ( !bWeightIn || !bYError ) {
    dStdDev = StatToolbox::stddev( &oY, NULL );
  } else {
    Matrix<Double> oYErr = Matrix<Double>(); // Keep compiler happy
    try {
      oYErr =
          yErr( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn, False ).copy();
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in yErr( )\n" + oAipsError.getMesg(), "GDC2Token",
          "stdDev" ) );
    }
    dStdDev = StatToolbox::stddev( &oY, &oYErr );
  }
  
  return( dStdDev );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::variance

Description:
------------
This public member function returns the y variance.

Inputs:
-------
dXMinIn   - The minimum x value.
dXMaxIn   - The maximum x value.
oTokenIn  - The tokens.
oColumnIn - The column IDs.
bKeepIn   - The keep-flagged-data boolean.
bWeightIn - The weight boolean.

Outputs:
--------
The y variance, returned via the function value.

Modification history:
---------------------
2001 Jan 17 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::variance( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn, const Bool& bKeepIn,
    const Bool& bWeightIn ) const {
  
  // Declare the local variables
  
  Double dVariance; // The y variance
  
  
  // Find and return the y variance
  
  Matrix<Double> oY = Matrix<Double>(); // Keep compiler happy
  
  try {
    oY = y( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn, False ).copy();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in y( )\n" + oAipsError.getMesg(), "GDC2Token",
        "variance" ) );
  }
  
  if ( oY.nelements() < 2 ) {
    throw( ermsg( "Not enough data in range", "GDC2Token", "variance" ) );
  }
  
  if ( !bWeightIn || !bYError ) {
    dVariance = StatToolbox::variance( &oY, NULL );
  } else {
    Matrix<Double> oYErr = Matrix<Double>();
    try {
      oYErr =
          yErr( dXMinIn, dXMaxIn, oTokenIn, oColumnIn, bKeepIn, False ).copy();
    }
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in yErr( )\n" + oAipsError.getMesg(), "GDC2Token",
          "variance" ) );
    }
    dVariance = StatToolbox::variance( &oY, &oYErr );
  }
  
  return( dVariance );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token:setFlagX

Description:
------------
This public member function sets flags in a given x range.

Inputs:
-------
dXMinIn      - The minimum x value.
dXMaxIn      - The maximum x value.
oTokenIn     - The tokens.
oColumnIn    - The column IDs.
bFlagValueIn - The flag value (True = set flags, False = unset flags).

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setFlagX( Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bFlagValueIn ) {
  
  // Declare the local variables
  
  Bool bFlagTemp;    // The temporary flag
  Bool bFlagValid;   // The valid-flag boolean
  
  uInt uiColumn;     // The column counter
  uInt uiEvent;      // The event number
  uInt uiIndex;      // The index counter
  uInt uiNumColumn;  // The number of columns
  uInt uiNumHistory; // The number of histories
  uInt uiNumIndex;   // The number of indices
  uInt uiNumIndexX;  // The number of indices, not taking flags into account
  
  
  // Get the column numbers
  
  Vector<Int> oColumn = Vector<Int>(); // Keep compiler happy
  
  try {
    oColumn = columnNumber( oColumnIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Invalid column ID(s)\n" + oAipsError.getMesg(), "GDC2Token",
        "setFlagX" ) );
  }
  
  
  // Initialize variables
  
  uiNumColumn = oColumn.nelements();
  
  Vector<Int> aoIndexX[uiNumColumn]; // Keep compiler happy
  Vector<Int> aoIndex[uiNumColumn];  // Keep compiler happy
  
  
  // Get the indices
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {

    try {
      aoIndexX[uiColumn] =
          index( dXMinIn, dXMaxIn, oTokenIn, oColumn(uiColumn), True );
    }
  
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
          "setFlagX" ) );
    }
  
    uiNumIndexX = aoIndexX[uiColumn].nelements();
    uiNumIndex = aoIndex[uiColumn].nelements();
  
    for ( uiIndex = 0; uiIndex < uiNumIndexX; uiIndex++ ) {
      bFlagTemp = (*poFlag)(aoIndexX[uiColumn](uiIndex),oColumn(uiColumn));
      if ( bFlagTemp != bFlagValueIn ) {
        uiNumIndex += 1;
        aoIndex[uiColumn].resize( uiNumIndex, True );
        aoIndex[uiColumn](uiNumIndex-1) = aoIndexX[uiColumn](uiIndex);
      }
    }

  }


  // Any flags?
  
  bFlagValid = False;
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    if ( aoIndex[uiColumn].nelements() > 0 ) {
      bFlagValid = True;
    }
  }
  
  if ( !bFlagValid ) {
    return;
  }
  
  
  // Initialize the number of histories and the event number
  
  uiNumHistory = poHistoryEvent->nelements();
  
  if ( uiNumHistory < 1 ) {
    uiEvent = 1;
  } else {
    uiEvent = (uInt) (*poHistoryEvent)(uiNumHistory-1) + 1;
  }
  
  
  // Update the histories

  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
  
    uiNumIndex = aoIndex[uiColumn].nelements();

    poHistoryEvent->resize( uiNumIndex+uiNumHistory, True );
    poHistoryIndex->resize( uiNumIndex+uiNumHistory, True );
    poHistoryColumn->resize( uiNumIndex+uiNumHistory, True );
    poHistoryFlag->resize( uiNumIndex+uiNumHistory, True );
    poHistoryInterp->resize( uiNumIndex+uiNumHistory, True );
    poHistoryY->resize( uiNumIndex+uiNumHistory, True );
    poHistoryYErr->resize( uiNumIndex+uiNumHistory, True );
  
    for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
      (*poHistoryEvent)(uiIndex+uiNumHistory) = (Int) uiEvent;
      (*poHistoryIndex)(uiIndex+uiNumHistory) = aoIndex[uiColumn](uiIndex);
      (*poHistoryColumn)(uiIndex+uiNumHistory) = oColumn(uiColumn);
      (*poHistoryFlag)(uiIndex+uiNumHistory) = bFlagValueIn;
      (*poHistoryInterp)(uiIndex+uiNumHistory) = False;
      (*poHistoryY)(uiIndex+uiNumHistory) = 0.0;
      (*poHistoryYErr)(uiIndex+uiNumHistory) = 0.0;
      (*poFlag)(aoIndex[uiColumn](uiIndex),oColumn(uiColumn)) = bFlagValueIn;
      (*poInterp)(aoIndex[uiColumn](uiIndex),oColumn(uiColumn)) = False;
    }
    
    uiNumHistory += uiNumIndex;
    
  }


  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token:setFlagXY

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
oColumnIn    - The column IDs.
bFlagValueIn - The flag value (True = set flags, False = unset flags).

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.


*/

// -----------------------------------------------------------------------------

void GDC2Token::setFlagXY( Double& dXMinIn, Double& dXMaxIn, Double& dYMinIn,
    Double& dYMaxIn, Vector<String>& oTokenIn, Vector<String>& oColumnIn,
    const Bool& bFlagValueIn ) {
  
  // Declare the local variable
  
  Bool bFlagTemp;    // The temporary flag
  Bool bFlagValid;   // The valid-flag boolean
  
  uInt uiColumn;     // The column counter
  uInt uiEvent;      // The event number
  uInt uiIndex;      // The index counter
  uInt uiNumColumn;  // The number of columns
  uInt uiNumHistory; // The number of histories
  uInt uiNumIndex;   // The number of indices
  uInt uiNumIndexX;  // The number of indices, not taking y range and flags
                     // into account


  // Check the inputs
  
  if ( !checkY( dYMinIn, dYMaxIn ) ) {
    throw( ermsg( "Invalid y value(s)", "GDC2Token", "setFlagXY" ) );
  }
  
  
  // Get the column numbers
  
  Vector<Int> oColumn = Vector<Int>(); // Keep compiler happy
  
  try {
    oColumn = columnNumber( oColumnIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Invalid column ID(s)\n" + oAipsError.getMesg(), "GDC2Token",
        "setFlagXY" ) );
  }
  
  
  // Initialize variables
  
  uiNumColumn = oColumn.nelements();
  
  Vector<Int> aoIndexX[uiNumColumn]; // Keep compiler happy
  Vector<Int> aoIndex[uiNumColumn];  // Keep compiler happy
  
  
  // Get the indices
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {

    try {
      aoIndexX[uiColumn] =
          index( dXMinIn, dXMaxIn, oTokenIn, oColumn(uiColumn), True );
    }
  
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error in index( )\n" + oAipsError.getMesg(), "GDC2Token",
          "setFlagXY" ) );
    }
  
    uiNumIndexX = aoIndexX[uiColumn].nelements();
    uiNumIndex = aoIndex[uiColumn].nelements();
  
    for ( uiIndex = 0; uiIndex < uiNumIndexX; uiIndex++ ) {
      bFlagTemp = (*poFlag)(aoIndexX[uiColumn](uiIndex),oColumn(uiColumn));
      if ( bFlagTemp != bFlagValueIn &&
           (*poY)(aoIndexX[uiColumn](uiIndex),oColumn(uiColumn)) >= dYMinIn &&
           (*poY)(aoIndexX[uiColumn](uiIndex),oColumn(uiColumn)) <= dYMaxIn ) {
        uiNumIndex += 1;
        aoIndex[uiColumn].resize( uiNumIndex, True );
        aoIndex[uiColumn](uiNumIndex-1) = aoIndexX[uiColumn](uiIndex);
      }
    }

  }


  // Any flags?
  
  bFlagValid = False;
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    if ( aoIndex[uiColumn].nelements() > 0 ) {
      bFlagValid = True;
    }
  }
  
  if ( !bFlagValid ) {
    return;
  }
  
  
  // Initialize the number of histories and the event number
  
  uiNumHistory = poHistoryEvent->nelements();
  
  if ( uiNumHistory < 1 ) {
    uiEvent = 1;
  } else {
    uiEvent = (uInt) (*poHistoryEvent)(uiNumHistory-1) + 1;
  }
  
  
  // Update the histories

  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
  
    uiNumIndex = aoIndex[uiColumn].nelements();

    poHistoryEvent->resize( uiNumIndex+uiNumHistory, True );
    poHistoryIndex->resize( uiNumIndex+uiNumHistory, True );
    poHistoryColumn->resize( uiNumIndex+uiNumHistory, True );
    poHistoryFlag->resize( uiNumIndex+uiNumHistory, True );
    poHistoryInterp->resize( uiNumIndex+uiNumHistory, True );
    poHistoryY->resize( uiNumIndex+uiNumHistory, True );
    poHistoryYErr->resize( uiNumIndex+uiNumHistory, True );
  
    for ( uiIndex = 0; uiIndex < uiNumIndex; uiIndex++ ) {
      (*poHistoryEvent)(uiIndex+uiNumHistory) = (Int) uiEvent;
      (*poHistoryIndex)(uiIndex+uiNumHistory) = aoIndex[uiColumn](uiIndex);
      (*poHistoryColumn)(uiIndex+uiNumHistory) = oColumn(uiColumn);
      (*poHistoryFlag)(uiIndex+uiNumHistory) = bFlagValueIn;
      (*poHistoryInterp)(uiIndex+uiNumHistory) = False;
      (*poHistoryY)(uiIndex+uiNumHistory) = 0.0;
      (*poHistoryYErr)(uiIndex+uiNumHistory) = 0.0;
      (*poFlag)(aoIndex[uiColumn](uiIndex),oColumn(uiColumn)) = bFlagValueIn;
      (*poInterp)(aoIndex[uiColumn](uiIndex),oColumn(uiColumn)) = False;
    }
    
    uiNumHistory += uiNumIndex;
    
  }


  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::undoHistory

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::undoHistory( void ) {

  // Declare the local variables
  
  uInt uiColumn;     // The column counter
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
    uiColumn = (*poHistoryColumn)(uiHistory-1);
    if ( !(*poHistoryInterp)(uiHistory-1) ) {
      (*poFlag)(uiIndex,uiColumn) = !(*poFlag)(uiIndex,uiColumn);
    } else {
      (*poInterp)(uiIndex,uiColumn) = False;
      (*poY)(uiIndex,uiColumn) = (*poHistoryY)(uiHistory-1);
      if ( bYError ) {
        (*poYErr)(uiIndex,uiColumn) = (*poHistoryYErr)(uiHistory-1);
      }
    }
  }
  
  uiNumHistory = uiHistory;
  
  poHistoryEvent->resize( uiNumHistory, True );
  poHistoryIndex->resize( uiNumHistory, True );
  poHistoryColumn->resize( uiNumHistory, True );
  poHistoryFlag->resize( uiNumHistory, True );
  poHistoryInterp->resize( uiNumHistory, True );
  poHistoryY->resize( uiNumHistory, True );
  poHistoryYErr->resize( uiNumHistory, True );
  
  uiEvent = (*poHistoryEvent)(uiNumHistory-1);
  
  for ( uiHistory = 0; uiHistory < uiNumHistory; uiHistory++ ) {
    uiIndex = (*poHistoryIndex)(uiHistory);
    uiColumn = (*poHistoryColumn)(uiHistory);
    (*poFlag)(uiIndex,uiColumn) = (*poHistoryFlag)(uiHistory);
    (*poInterp)(uiIndex,uiColumn) = (*poHistoryInterp)(uiHistory);
  }
  
  
  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::resetHistory

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::resetHistory( void ) {

  // Declare the local variables
  
  uInt uiColumn;     // The column counter
  uInt uiData;       // The data counter
  uInt uiHistory;    // The history counter
  uInt uiNumColumn;  // The number of columns
  uInt uiNumData;    // The number of data
  uInt uiNumHistory; // The number of histories
  
  
  // Any history?
  
  uiNumHistory = poHistoryEvent->nelements();

  if ( uiNumHistory < 1 ) {
    return;
  }
  
  
  // Reset the flags to their original values
  
  uiNumData = poFlagOrig->nrow();
  uiNumColumn = poFlagOrig->ncolumn();
  
  delete poFlag;
  poFlag = new Matrix<Bool>( uiNumData, uiNumColumn, False );
  
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      (*poFlag)(uiData,uiColumn) = (*poFlagOrig)(uiData,uiColumn);
    }
  }
  
  
  // Reset y, y-error, and interpolation variables to their original values
  
  for ( uiHistory = 0; uiHistory < uiNumHistory; uiHistory++ ) {
    if ( (*poHistoryInterp)(uiHistory) ) {
      uiData = (*poHistoryIndex)(uiHistory);
      uiColumn = (*poHistoryColumn)(uiHistory);
      (*poY)(uiData,uiColumn) = (*poHistoryY)(uiHistory);
      if ( bYError ) {
        (*poYErr)(uiData,uiColumn) = (*poHistoryYErr)(uiHistory);
      }
      (*poInterp)(uiData,uiColumn) = False;
    }
  }
  
  
  // Reset the histories
  
  delete poHistoryEvent;
  poHistoryEvent = new Vector<Int>();
  
  delete poHistoryIndex;
  poHistoryIndex = new Vector<Int>();
  
  delete poHistoryColumn;
  poHistoryColumn = new Vector<Int>();

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

GDC2Token::history

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
poHistoryColumnIn - The flag columns.
poHistoryFlagIn   - The history flags.
poHistoryInterpIn - The flag interpolation booleans.
poHistoryYIn      - The flag old y values (before interpolation).
poHistoryYErrIn   - The flag old y values (before interpolation).

Modification history:
---------------------
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::history( Vector<Int>* *poHistoryEventIn,
    Vector<Int>* *poHistoryIndexIn, Vector<Int>* *poHistoryColumnIn,
    Vector<Bool>* *poHistoryFlagIn, Vector<Bool>* *poHistoryInterpIn,
    Vector<Double>* *poHistoryYIn, Vector<Double>* *poHistoryYErrIn ) const {
    
  // Copy the flag-history vectors and return
  
  *poHistoryEventIn = new Vector<Int>( poHistoryEvent->copy() );
  *poHistoryIndexIn = new Vector<Int>( poHistoryIndex->copy() );
  *poHistoryColumnIn = new Vector<Int>( poHistoryColumn->copy() );
  *poHistoryFlagIn = new Vector<Bool>( poHistoryFlag->copy() );
  *poHistoryInterpIn = new Vector<Bool>( poHistoryInterp->copy() );
  *poHistoryYIn = new Vector<Double>( poHistoryY->copy() );
  *poHistoryYErrIn = new Vector<Double>( poHistoryYErr->copy() );
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::numEvent

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt GDC2Token::numEvent( void ) const {
    
  // Return the number of events in the history

  if ( poHistoryEvent->nelements() > 0 ) {
    return( (*poHistoryEvent)( poHistoryEvent->nelements() - 1 ) );
  } else {
    return( 0 );
  }
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::postScript

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::postScript( String& oFileIn, const String& oDeviceIn,
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
          "GDC2Token", "postScript" ) );
    }
  } else {
    throw( ermsg( "Could not create PostScript file", "GDC2Token",
        "postScript" ) );
  }
  
  cpgclos();
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::plot

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::plot( const Int& iQIDIn, const Vector<Int>& oCI ) {
  
  // Declare the local variables
  
  uInt uiColumn;        // The column ID counter
  uInt uiColumn2;       // The column ID number
  uInt uiNumColumn;     // The number of column IDs
  uInt uiNumToken;      // The temporary number of tokens
  uInt uiToken;         // The token counter
  
  Int iColor;           // The color counter
  
  Double dXDelta;       // The x-axis plotting margin
  Double dXMax;         // The maximum plot x-value
  Double dXMin;         // The minimum plot x-value
  Double dYDelta;       // The y-axis plotting margin
  Double dYMax;         // The maximum plot y-value
  Double dYMin;         // The minimum plot y-value
  
  Vector<Int>* poIndex; // The index vector
  
  
  // Check the inputs
  
  if ( iQIDIn < 1 ) {
    throw( ermsg( "Invalid PGPLOT device number", "GDC2Token", "plot" ) );
  }
  
  
  // Turn off argument checking, for speed
  
  setArgCheck( False );
  
  
  // Initialize some local variables
  
  dXMin = dXMinPlot;
  dXMax = dXMaxPlot;
  dYMin = dYMinPlot;
  dYMax = dYMaxPlot;
  
  iColor = -1;
  
  uiNumToken = poTokenPlot->nelements();
  
  Vector<String> oToken = Vector<String>( 1 );
  String oColumn = String();


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
    
    oToken = Vector<String>( 1, (*poTokenPlot)(uiToken) );
    uiNumColumn = aoColumnPlot[uiToken]->nelements();
    
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    
      iColor += 1;
      
      oColumn = (*aoColumnPlot[uiToken])(uiColumn);
      uiColumn2 = columnNumber( oColumn ); 
      
      poIndex = new Vector<Int>(
          index( dXMin, dXMax, oToken, uiColumn2, bKeep ).copy() );
        
      if ( poIndex->nelements() > 1 ) {
        if ( bColor ) {
          plotPoints( poIndex, uiColumn2, oCI(iColor) );
        } else {
          plotPoints( poIndex, uiColumn2, 1 );
        }
        if ( bLine ) {
          if ( bColor ) {
            plotLine( poIndex, uiColumn2, oCI(iColor) );
          } else {
            plotLine( poIndex, uiColumn2, 1 );
          }
        }
      }
    
      delete poIndex;
    
      if ( bKeep ) {
        poIndex = new Vector<Int>(
            flagged( dXMin, dXMax, oToken, oColumn ).copy() );
        if ( poIndex->nelements() > 1 ) {
          plotPoints( poIndex, uiColumn2, 2 );
        }
        delete poIndex;
      }
    
      poIndex = new Vector<Int>(
          interpolated( dXMin, dXMax, oToken, oColumn ).copy() );
      if ( poIndex->nelements() > 1 ) {
        plotPoints( poIndex, uiColumn2, 3 );
      }
    
      delete poIndex;
      
    }
    
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

GDC2Token::getXMin

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
2000 Dec 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::getXMin( const Bool& bDefaultIn ) const {

  // Return the minimum plotted x value

  if ( !bDefaultIn ) {
    return( dXMinPlot );
  } else {
    return( dXMinDefault );
  }

}

// -----------------------------------------------------------------------------

/*

GDC2Token::getXMax

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
2000 Dec 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::getXMax( const Bool& bDefaultIn ) const {

  // Return the maximum plotted x value

  if ( !bDefaultIn ) {
    return( dXMaxPlot );
  } else {
    return( dXMaxDefault );
  }

}

// -----------------------------------------------------------------------------

/*

GDC2Token::getYMin

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::getYMin( const Bool& bDefaultIn ) const {

  // Return the minimum plotted y value
  
  if ( !bDefaultIn ) {
    return( dYMinPlot );
  } else {
    return( dYMinDefault );
  }

}

// -----------------------------------------------------------------------------

/*

GDC2Token::getYMax

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GDC2Token::getYMax( const Bool& bDefaultIn ) const {

  // Return the maximum plotted y value
  
  if ( !bDefaultIn ) {
    return( dYMaxPlot );
  } else {
    return( dYMaxDefault );
  }

}

// -----------------------------------------------------------------------------

/*

GDC2Token::zoomx

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::zoomx( Double& dXMinIn, Double& dXMaxIn ) {

  // Fix/check the inputs
  
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "GDC2Token", "zoomx" ) );
  }
  
  
  // Save the x limits and return
  
  dXMinPlot = dXMinIn;
  dXMaxPlot = dXMaxIn;

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::zoomy

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::zoomy( Double& dYMinIn, Double& dYMaxIn ) {

  // Fix/check the inputs
  
  if ( !checkY( dYMinIn, dYMaxIn ) ) {
    throw( ermsg( "Invalid y value(s)", "GDC2Token", "zoomy" ) );
  }
  
  
  // Save the y limits and return
  
  dYMinPlot = dYMinIn;
  dYMaxPlot = dYMaxIn;

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::zoomxy

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::zoomxy( Double& dXMinIn, Double& dXMaxIn, Double& dYMinIn,
    Double& dYMaxIn ) {  

  // Fix/check the inputs
    
  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "GDC2Token", "zoomxy" ) );
  }
  
  if ( !checkY( dYMinIn, dYMaxIn ) ) {
    throw( ermsg( "Invalid y value(s)", "GDC2Token", "zoomxy" ) );
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

GDC2Token::fullSize

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::fullSize( void ) {
  
  // Modify the x and y limits to their default values and return

  zoomxy( dXMinDefault, dXMaxDefault, dYMinDefault, dYMaxDefault );

  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::getToken

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
2001 Jan 08 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GDC2Token::getToken( void ) const {
  
  // Return the plotted tokens
  
  return( Vector<String>( poTokenPlot->copy() ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::getColumn

Description:
------------
This public member function returns the plotted column IDs for a given token.

Inputs:
-------
oTokenIn - The token.

Outputs:
--------
The plotted column IDs, returned via the function value.

Modification history:
---------------------
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GDC2Token::getColumn( String& oTokenIn ) const {

  // Declare the local variables
  
  uInt uiToken; // The token number
  

  // Get the token number
  
  oTokenIn.gsub( RXwhite, "" );
  oTokenIn.upcase();
  
  for ( uiToken = 0; uiToken < poTokenPlot->nelements(); uiToken++ ) {
    if ( oTokenIn.matches( (*poTokenPlot)(uiToken) ) ) {
      break;
    }
  }
  
  if ( uiToken >= poTokenPlot->nelements() ) {
    throw( ermsg( "Invalid token argument\n", "GDC2Token", "getColumn" ) );
  }
  
  
  // Return the plotted column IDs
  
  return( aoColumnPlot[uiToken]->copy() );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::setTokenColumn

Description:
------------
This public member function sets the plotted tokens and column IDs.

Inputs:
-------
oTokenIn  - The tokens.
oColumnIn - The column IDs.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setTokenColumn( Vector<String>& oTokenIn,
    Vector<String>& oColumnIn ) {
    
  // Declare the local variables
  
  uInt uiToken; // The token counter
  

  // Check the inputs
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token argument(s)", "GDC2Token",
        "setTokenColumn" ) );
  }
  
  if ( !checkColumn( oColumnIn ) ) {
    throw( ermsg( "Invalid column ID argument(s)", "GDC2Token",
        "setTokenColumn" ) );
  }
  
  
  // Set the token and column IDs and return
  
  if ( poTokenPlot != NULL ) {
    for ( uiToken = 0; uiToken < poTokenPlot->nelements(); uiToken++ ) {
      delete aoColumnPlot[uiToken];
    }
    delete poTokenPlot;
  }
  
  poTokenPlot = new Vector<String>( oTokenIn.copy() );
  aoColumnPlot = new Vector<String>*[oTokenIn.nelements()];
  
  for ( uiToken = 0; uiToken < oTokenIn.nelements(); uiToken++ ) {
    aoColumnPlot[uiToken] = new Vector<String>( oColumnIn.copy() );
  }
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::setTokenColumnDefault

Description:
------------
This public member function sets the plotted tokens and column IDs to the
default (all tokens and column IDs).

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setTokenColumnDefault( void ) {

  // Declare the local variables

  uInt uiToken; // The token counter

  
  // Set the tokens and column IDs to the default and return
  
  if ( poTokenPlot != NULL ) {
    for ( uiToken = 0; uiToken < poTokenPlot->nelements(); uiToken++ ) {
      delete aoColumnPlot[uiToken];
    }
    delete poTokenPlot;
    delete aoColumnPlot;
  }

  poTokenPlot = new Vector<String>( poTokenList->copy() );
  aoColumnPlot = new Vector<String>*[poTokenList->nelements()];

  for ( uiToken = 0; uiToken < poTokenList->nelements(); uiToken++ ) {
    aoColumnPlot[uiToken] = new Vector<String>( poColumnList->copy() );
  }
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::addTokenColumn

Description:
------------
This public member function adds unique plotted tokens and column IDs.

Inputs:
-------
oTokenIn  - The tokens.
oColumnIn - The column IDs.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::addTokenColumn( Vector<String>& oTokenIn,
    Vector<String>& oColumnIn ) {

  // Declare the local variables
  
  uInt uiColumn1;    // A column ID counter
  uInt uiColumn2;    // A column ID counter
  uInt uiNumColumn1; // A number of column IDs
  uInt uiNumColumn2; // A number of column IDs
  uInt uiNumToken1;  // A number of tokens
  uInt uiNumToken2;  // A number of tokens
  uInt uiToken1;     // A token counter
  uInt uiToken2;     // A token counter
  

  // Check the inputs
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token argument(s)", "GDC2Token",
        "addTokenColumn" ) );
  }
  
  if ( !checkColumn( oColumnIn ) ) {
    throw( ermsg( "Invalid column argument(s)", "GDC2Token",
        "addTokenColumn" ) );
  }
  
  
  // Add the unique tokens and column IDs and return
  
  uiNumToken1 = oTokenIn.nelements();
  uiNumToken2 = poTokenPlot->nelements();
  
  uiNumColumn1 = oColumnIn.nelements();
  
  String oColumnTemp = String();
  
  Vector<String>* *aoColumnTemp;
  
  for ( uiToken1 = 0; uiToken1 < uiNumToken1; uiToken1++ ) {
    for ( uiToken2 = 0; uiToken2 < uiNumToken2; uiToken2++ ) {
      if ( oTokenIn(uiToken1).matches( (*poTokenPlot)(uiToken2) ) ) {
        break;
      }
    }
    if ( uiToken2 < uiNumToken2 ) {
      uiNumColumn2 = aoColumnPlot[uiToken2]->nelements();
      for ( uiColumn1 = 0; uiColumn1 < uiNumColumn1; uiColumn1++ ) {
        for ( uiColumn2 = 0; uiColumn2 < uiNumColumn2; uiColumn2++ ) {
          oColumnTemp = (*aoColumnPlot[uiToken2])(uiColumn2);
          if ( oColumnIn(uiColumn1).matches( oColumnTemp ) ) {
            break;
          }
        }
        if ( uiColumn2 >= uiNumColumn2 ) {
          uiNumColumn2 += 1;
          aoColumnPlot[uiToken2]->resize( uiNumColumn2, True );
          (*aoColumnPlot[uiToken2])(uiNumColumn2-1) = oColumnIn(uiColumn1);
        }
      }
    } else {
      aoColumnTemp = new Vector<String>*[uiNumToken2];
      for ( uiToken2 = 0; uiToken2 < uiNumToken2; uiToken2++ ) {
        aoColumnTemp[uiToken2] =
            new Vector<String>( aoColumnPlot[uiToken2]->copy() );
        delete aoColumnPlot[uiToken2];
      }
      delete aoColumnPlot;
      aoColumnPlot = new Vector<String>*[uiNumToken2+1];
      for ( uiToken2 = 0; uiToken2 < uiNumToken2; uiToken2++ ) {
        aoColumnPlot[uiToken2] =
            new Vector<String>( aoColumnTemp[uiToken2]->copy() );
        delete aoColumnTemp[uiToken2];
      }
      delete aoColumnTemp;
      uiNumToken2 += 1;
      poTokenPlot->resize( uiNumToken2, True );
      (*poTokenPlot)(uiNumToken2-1) = oTokenIn(uiToken1);
      aoColumnPlot[uiNumToken2-1] = new Vector<String>( oColumnIn.copy() );
    }
  }
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::removeTokenColumn

Description:
------------
This public member function removes plotted tokens and column IDs.

Inputs:
-------
oTokenIn  - The tokens.
oColumnIn - The column IDs.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::removeTokenColumn( Vector<String>& oTokenIn,
    Vector<String>& oColumnIn ) {

  // Declare the local variables
  
  uInt uiColumn1;    // A column ID counter
  uInt uiColumn2;    // A column ID counter
  uInt uiColumn3;    // A column ID counter
  uInt uiNumColumn1; // A number of column IDs
  uInt uiNumColumn2; // A number of column IDs
  uInt uiNumToken1;  // A number of tokens
  uInt uiNumToken2;  // A number of tokens
  uInt uiToken1;     // A token counter
  uInt uiToken2;     // A token counter
  uInt uiToken3;     // A token counter
  

  // Check the inputs
  
  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token argument(s)", "GDC2Token",
        "removeTokenColumn" ) );
  }
  
  if ( !checkColumn( oColumnIn ) ) {
    throw( ermsg( "Invalid column argument(s)", "GDC2Token",
        "removeTokenColumn" ) );
  }
  
  
  // Remove the tokens and column IDs and return
  
  uiNumToken1 = oTokenIn.nelements();
  uiNumToken2 = poTokenPlot->nelements();
  
  uiNumColumn1 = oColumnIn.nelements();
  
  String oColumnTemp = String();
  
  for ( uiToken1 = 0; uiToken1 < uiNumToken1; uiToken1++ ) {
    for ( uiToken2 = 0; uiToken2 < uiNumToken2; uiToken2++ ) {
      if ( oTokenIn(uiToken1).matches( (*poTokenPlot)(uiToken2) ) ) {
        break;
      }
    }
    if ( uiToken2 < uiNumToken2 ) {
      uiNumColumn2 = aoColumnPlot[uiToken2]->nelements();
      for ( uiColumn1 = 0; uiColumn1 < uiNumColumn1; uiColumn1++ ) {
        for ( uiColumn2 = 0; uiColumn2 < uiNumColumn2; uiColumn2++ ) {
          oColumnTemp = (*aoColumnPlot[uiToken2])(uiColumn2);
          if ( oColumnIn(uiColumn1).matches( oColumnTemp ) ) {
            break;
          }
        }
        if ( uiColumn2 < uiNumColumn2 ) {
          uiNumColumn2 -= 1;
          for ( uiColumn3 = uiColumn2; uiColumn3 < uiNumColumn2; uiColumn3++ ) {
            (*aoColumnPlot[uiToken2])(uiColumn3) =
                (*aoColumnPlot[uiToken2])(uiColumn3+1);
          }
          aoColumnPlot[uiToken2]->resize( uiNumColumn2, True );
        }
      }
      if ( uiNumColumn2 < 1 ) {
        uiNumToken2 -= 1;
        for ( uiToken3 = uiToken2; uiToken3 < uiNumToken2; uiToken3++ ) {
          (*poTokenPlot)(uiToken3) = (*poTokenPlot)(uiToken3+1);
        }
        poTokenPlot->resize( uiNumToken2, True );
      }
    }
  }
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::getFlag

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
2001 Jan 08 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::getFlag( void ) const {

  // Return the flagging boolean
  
  return( bFlag );

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setFlag

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
2001 Jan 08 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setFlag( const Bool& bFlagIn ) {

  // Set the flagging boolean and return
  
  bFlag = bFlagIn;
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::getColor

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
2001 Jan 08 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::getColor( void ) const {

  // Return the plot-color boolean
  
  return( bColor );

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setColor

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
2001 Jan 08 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setColor( const Bool& bColorIn ) {

  // Set the plot-color boolean and return
  
  bColor = bColorIn;
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::getLine

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
2001 Jan 08 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::getLine( void ) const {

  // Return the plot-line boolean
  
  return( bLine );

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setLine

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
2001 Jan 08 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setLine( const Bool& bLineIn ) {

  // Set the plot-line boolean and return
  
  bLine = bLineIn;
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::getKeep

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::getKeep( void ) const {

  // Return the keep-flag boolean
  
  return( bKeep );

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setKeep

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setKeep( const Bool& bKeepIn ) {

  // Set the keep-flag boolean and return
  
  bKeep = bKeepIn;
  
  if ( !bKeep && !bFlag ) {
    bFlag = True;
  }
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::getXLabel

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC2Token::getXLabel( const Bool& bDefaultIn ) const {

  // Return the x-axis label
  
  if ( !bDefaultIn ) {
    return( String( *poXLabel ) );
  } else {
    return( String( *poXLabelDefault ) );
  }

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setXLabel (default)

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setXLabel( void ) {

  // Set the x-axis label to its default value and return
  
  if ( poXLabel != NULL ) {
    delete poXLabel;
  }
  poXLabel = new String( *poXLabelDefault );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setXLabel (arbitrary)

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setXLabel( const String& oXLabelIn ) {

  // Set the x-axis label and return
  
  if ( poXLabel != NULL ) {
    delete poXLabel;
  }
  poXLabel = new String( oXLabelIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setXLabelDefault

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setXLabelDefault( const String& oXLabelIn ) {

  // Set the default x-axis label and return
  
  if ( poXLabelDefault != NULL ) {
    delete poXLabelDefault;
  }
  poXLabelDefault = new String( oXLabelIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::getYLabel

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC2Token::getYLabel( const Bool& bDefaultIn ) const {

  // Return the y-axis label
  
  if ( !bDefaultIn ) {
    return( String( *poYLabel ) );
  } else {
    return( String( *poYLabelDefault ) );
  }

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setYLabel (default)

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setYLabel( void ) {

  // Set the y-axis label to its default value and return
  
  if ( poYLabel != NULL ) {
    delete poYLabel;
  }
  poYLabel = new String( *poYLabelDefault );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setYLabel (arbitrary)

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setYLabel( const String& oYLabelIn ) {

  // Set the y-axis label and return
  
  if ( poYLabel != NULL ) {
    delete poYLabel;
  }
  poYLabel = new String( oYLabelIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setYLabelDefault

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setYLabelDefault( const String& oYLabelIn ) {

  // Set the default y-axis label and return
  
  if ( poYLabelDefault != NULL ) {
    delete poYLabelDefault;
  }
  poYLabelDefault = new String( oYLabelIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::getTitle

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC2Token::getTitle( const Bool& bDefaultIn ) const {

  // Return the title label
  
  if ( !bDefaultIn ) {
    return( String( *poTitle ) );
  } else {
    return( String( *poTitleDefault ) );
  }

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setTitle (default)

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setTitle( void ) {

  // Set the title label to its default value and return
  
  if ( poTitle != NULL ) {
    delete poTitle;
  }
  poTitle = new String( *poTitleDefault );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setTitle (arbitrary)

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setTitle( const String& oTitleIn ) {

  // Set the title label and return
  
  if ( poTitle != NULL ) {
    delete poTitle;
  }
  poTitle = new String( oTitleIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::setTitleDefault

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::setTitleDefault( const String& oTitleIn ) {

  // Set the default title label and return
  
  if ( poTitleDefault != NULL ) {
    delete poTitleDefault;
  }
  poTitleDefault = new String( oTitleIn );
  
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::hms

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::hms( void ) const {

  // Return the HH:MM:SS boolean
  
  return( bHMS );

}

// -----------------------------------------------------------------------------

/*

GDC2Token::hmsOld

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

Bool GDC2Token::hmsOld( void ) const {

  // Return the old HH:MM:SS boolean
  
  return( bHMSOld );

}

// -----------------------------------------------------------------------------

/*

GDC2Token::version

Description:
------------
This public member function returns the GDC2Token{ } version.

Inputs:
-------
None.

Outputs:
--------
The GDC2Token{ } version, returned via the function value.

Modification history:
---------------------
2000 Dec 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC2Token::version( void ) const {

  // Return the GDC2Token{ } version
  
  return( String( "0.0" ) );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::tool

Description:
------------
This public member function returns the glish tool name (must be "gdc2token").

Inputs:
-------
None.

Outputs:
--------
The glish tool name, returned via the function value.

Modification history:
---------------------
2000 Dec 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC2Token::tool( void ) const {

  // Return the glish tool name
  
  String oTool = className();
  oTool.downcase();
  
  return( oTool );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::checkColumn (column numbers)

Description:
------------
This public member function checks/fixes column numbers.  NB: Duplicate column
numbers will be purged.

Inputs:
-------
oColumnIn - The column numbers.

Outputs:
--------
oColumnIn - The checked/fixed column numbers.
The check boolean (True = OK, False = NOT OK).

Modification history:
---------------------
2000 Dec 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::checkColumn( Vector<Int>& oColumnIn ) const {
  
  // Declare the local variables
  
  uInt uiNumColumn;     // The number of columns
  uInt uiNumColumnTemp; // The number of tokens
  uInt uiColumn;        // A column counter
  uInt uiColumn2;       // A column counter
  
  
  // Proceed?
  
  if ( !bArgCheck ) {
    return( True );
  }
  
  
  // Check the inputs

  uiNumColumn = oColumnIn.nelements();

  if ( uiNumColumn < 1 ) {
    oColumnIn = Vector<Int>( poColumnList->nelements() );
    for ( uiColumn = 0; uiColumn < poColumnList->nelements(); uiColumn++ ) {
      oColumnIn(uiColumn) = uiColumn;
    }
    return( True );
  }


  // Eliminate duplicate column IDs
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    if ( oColumnIn(uiColumn) < 0 ) {
      continue;
    }
    for ( uiColumn2 = uiColumn+1; uiColumn2 < uiNumColumn; uiColumn2++ ) {
      if ( oColumnIn(uiColumn2) < 0 ) {
        continue;
      }
      if ( oColumnIn(uiColumn2) == oColumnIn(uiColumn) ) {
        oColumnIn(uiColumn2) = -1;
      }
    }
  }
  
  uiNumColumnTemp = 0;
  Vector<Int> oColumnInTemp = Vector<Int>();
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    if ( oColumnIn(uiColumn) > -1 ) {
      uiNumColumnTemp += 1;
      oColumnInTemp.resize( uiNumColumnTemp, True );
      oColumnInTemp(uiNumColumnTemp-1) = oColumnIn(uiColumn);
    }
  }
  
  oColumnIn.resize( uiNumColumnTemp, False );
  oColumnIn = oColumnInTemp;


  // Check the column numbers and return the check boolean
  
  uiNumColumn = oColumnIn.nelements();
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    if ( oColumnIn(uiColumn) > (Int) poColumnList->nelements()-1 ) {
      return( False );
    }
  }
  
  return( True );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::checkColumn (column IDs)

Description:
------------
This public member function checks/fixes column IDs.  NB: Duplicate column IDs
will be purged.

Inputs:
-------
oColumnIn - The column IDs.

Outputs:
--------
oColumnIn - The checked/fixed column IDs.
The check boolean (True = OK, False = NOT OK).

Modification history:
---------------------
2000 Dec 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::checkColumn( Vector<String>& oColumnIn ) const {
  
  // Declare the local variables
  
  uInt uiNumColumn;     // The number of columns
  uInt uiNumColumnTemp; // The number of tokens
  uInt uiColumn;        // A column counter
  uInt uiColumn2;       // A column counter
  
  
  // Proceed?
  
  if ( !bArgCheck ) {
    return( True );
  }
  
  
  // Check the inputs

  uiNumColumn = oColumnIn.nelements();

  if ( uiNumColumn < 1 ) {
    oColumnIn = Vector<String>( *poColumnList );
    return( True );
  }


  // Eliminate white spaces and convert to upper case

  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    oColumnIn(uiColumn).gsub( RXwhite, "" );
    oColumnIn(uiColumn).upcase();
  }


  // Eliminate duplicate column IDs
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    if ( oColumnIn(uiColumn).length() < 1 ) {
      continue;
    }
    for ( uiColumn2 = uiColumn+1; uiColumn2 < uiNumColumn; uiColumn2++ ) {
      if ( oColumnIn(uiColumn2).length() < 1 ) {
        continue;
      }
      if ( oColumnIn(uiColumn2).matches( oColumnIn(uiColumn) ) ) {
        oColumnIn(uiColumn2) = "";
      }
    }
  }
  
  uiNumColumnTemp = 0;
  Vector<String> oColumnInTemp = Vector<String>();
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    if ( oColumnIn(uiColumn).length() > 0 ) {
      uiNumColumnTemp += 1;
      oColumnInTemp.resize( uiNumColumnTemp, True );
      oColumnInTemp(uiNumColumnTemp-1) = oColumnIn(uiColumn);
    }
  }
  
  oColumnIn.resize( uiNumColumnTemp, False );
  oColumnIn = oColumnInTemp;


  // Check the column IDs and return the check boolean
  
  uiNumColumn = oColumnIn.nelements();
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    for ( uiColumn2 = 0; uiColumn2 < poColumnList->nelements(); uiColumn2++ ) {
      if ( oColumnIn(uiColumn).matches( (*poColumnList)(uiColumn2) ) ) {
        break;
      }
    }
    if ( uiColumn2 >= poColumnList->nelements() ) {
      return( False );
    }
  }
  
  return( True );
  
}

// -----------------------------------------------------------------------------

/*

GDC2Token::checkToken

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
2000 Dec 21 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::checkToken( Vector<String>& oTokenIn ) const {
  
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
    oTokenIn = Vector<String>( poTokenList->copy() );
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
  oTokenIn = Vector<String>( oTokenInTemp.copy() );


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

GDC2Token::checkX

Description:
------------
This public member function checks/fixes x values.

Inputs:
-------
dXMinIn - The minimum x value.
dXMaxIn - The maximum x value.

Outputs:
--------
dXMinIn  - The checked/fixed minimum x value.
dXMaxIn  - The checked/fixed maximum x value.
The check boolean (True = OK, False = NOT OK).

Modification history:
---------------------
2000 Dec 21 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::checkX( Double& dXMinIn, Double& dXMaxIn ) const {

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

GDC2Token::checkY

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
2001 Jan 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool GDC2Token::checkY( Double& dYMinIn, Double& dYMaxIn ) const {

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

GDC2Token::changeX

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::changeX( const Vector<Double>& oXIn,
    const Vector<Double>& oXErrIn, const String& oXLabelIn,
    const Bool& bHMSIn ) {
  
  // Declare the local variables
  
  uInt uiData;       // The data(-error) counter
  uInt uiNumData;    // The number of data
  uInt uiNumDataErr; // The number of data errors;


  // Check the inputs
 
  uiNumData = poX->nelements();
  
  if ( oXIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid x vector", "GDC2Token", "changeX" ) );
  }
  
  uiNumDataErr = oXErrIn.nelements();
  
  if ( uiNumDataErr != 0 && uiNumDataErr != uiNumData ) {
    throw( ermsg( "Invalid x-error vector", "GDC2Token", "changeX" ) );
  }
  
  
  // Change the private variables
  
  Vector<Int> oIndex; // Keep compiler happy
  
  try {
    Vector<String> oToken = tokenList();
    Vector<String> oColumn = columnList();
    oIndex = index( dXMinPlot, dXMaxPlot, oToken, oColumn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not get indices\n" + oAipsError.getMesg(),
        "GDC2Token", "changeX" ) );
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

GDC2Token::resetX

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
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::resetX( void ) {
  
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
    Vector<String> oColumn = columnList();
    oIndex = index( dXMinPlot, dXMaxPlot, oToken, oColumn, True );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not get indices\n" + oAipsError.getMesg(),
        "GDC2Token", "resetX" ) );
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

GDC2Token::className

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
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GDC2Token::className( void ) const {

  // Return the class name
  
  return( String( "GDC2Token" ) );

}

// -----------------------------------------------------------------------------

/*

GDC2Token::methods

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
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GDC2Token::methods( void ) const {

  // Return the method names
  
  Vector<String> oMethod(78);
  
  oMethod(0) = String( "fileASCII" );
  oMethod(1) = String( "getArgCheck" );
  oMethod(2) = String( "setArgCheck" );
  oMethod(3) = String( "dumpASCII" );
  oMethod(4) = String( "length" );
  oMethod(5) = String( "x" );
  oMethod(6) = String( "y" );
  oMethod(7) = String( "xErr" );
  oMethod(8) = String( "yErr" );
  oMethod(9) = String( "xError" );
  oMethod(10) = String( "yError" );
  oMethod(11) = String( "token" );
  oMethod(12) = String( "tokenType" );
  oMethod(13) = String( "tokenList" );
  oMethod(14) = String( "columnType" );
  oMethod(15) = String( "columnList" );
  oMethod(16) = String( "flag" );
  oMethod(17) = String( "interp" );
  oMethod(18) = String( "index" );
  oMethod(19) = String( "xMax" );
  oMethod(20) = String( "xMin" );
  oMethod(21) = String( "yMax" );
  oMethod(22) = String( "yMin" );
  oMethod(23) = String( "xErrMax" );
  oMethod(24) = String( "xErrMin" );
  oMethod(25) = String( "yErrMax" );
  oMethod(26) = String( "yErrMin" );
  oMethod(27) = String( "flagged" );
  oMethod(28) = String( "interpolated" );
  oMethod(29) = String( "mean" );
  oMethod(30) = String( "meanErr" );
  oMethod(31) = String( "stdDev" );
  oMethod(32) = String( "variance" );
  oMethod(33) = String( "setFlagX" );
  oMethod(34) = String( "setFlagXY" );
  oMethod(35) = String( "undoHistory" );
  oMethod(36) = String( "resetHistory" );
  oMethod(37) = String( "numEvent" );
  oMethod(38) = String( "postScript" );
  oMethod(39) = String( "getXMin" );
  oMethod(40) = String( "getXMax" );
  oMethod(41) = String( "getYMin" );
  oMethod(42) = String( "getYMax" );
  oMethod(43) = String( "zoomx" );
  oMethod(44) = String( "zoomy" );
  oMethod(45) = String( "zoomxy" );
  oMethod(46) = String( "fullSize" );
  oMethod(47) = String( "getToken" );
  oMethod(48) = String( "getColumn" );
  oMethod(49) = String( "setTokenColumn" );
  oMethod(50) = String( "setTokenColumnDefault" );
  oMethod(51) = String( "addTokenColumn" );
  oMethod(52) = String( "removeTokenColumn" );
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
  oMethod(74) = String( "checkColumn" );
  oMethod(75) = String( "checkToken" );
  oMethod(76) = String( "checkX" );
  oMethod(77) = String( "checkY" );

  return( oMethod );

}

// -----------------------------------------------------------------------------

/*

GDC2Token::noTraceMethods

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
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GDC2Token::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}


// -----------------------------------------------------------------------------

/*

GDC2Token::initialize

Description:
------------
This protected member function initializes the private variables.

Inputs:
-------
oXin          - The x vector.
oYIn          - The y matrix.
oXErrIn       - The x error vector. If no x errors, then the vector length
                should be 0.
oYErrIn       - The y error matrix. If no y errors, then the matrix length
                should be 0.
oTokenIn      - The token vector.
oColumnIn     - The column vector.
oFlagIn       - The flag matrix. If no flags, then the matrix length should be
                0.
oTokenTypeIn  - The token type.
oColumnTypeIn - The column type.

Outputs:
--------
None.

Modification history:
---------------------
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              Protected member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::initialize( const Vector<Double>& oXIn,
    const Matrix<Double>& oYIn, const Vector<Double>& oXErrIn,
    const Matrix<Double>& oYErrIn, const Vector<String>& oTokenIn,
    const Vector<String>& oColumnIn, const Matrix<Bool>& oFlagIn,
    const String& oTokenTypeIn, const String& oColumnTypeIn ) {
  
  // Declare the local variables
  
  Bool bUnique;     // Unique token flag
  
  uInt uiColumn;    // A column counter
  uInt uiColumn2;   // A column counter
  uInt uiData;      // A data counter
  uInt uiData2;     // A data counter
  uInt uiNumColumn; // The number of columns
  uInt uiNumData;   // The number of data
  uInt uiNumToken;  // The number of tokens
  uInt uiToken1;    // A token counter
  uInt uiToken2;    // A token counter
  
  
  // Check the inputs

  uiNumData = oXIn.nelements();
  
  if ( uiNumData < 1 ) {
    throw( ermsg( "Invalid x vector", "GDC2Token", "initialize" ) );
  }
  
  uiNumColumn = oColumnIn.nelements();
  
  if ( uiNumColumn < 1 ) {
    throw( ermsg( "Invalid number of columns", "GDC2Token", "initialize" ) );
  }
  
  String oColumnTemp = String();

  for ( uiColumn = 0; uiColumn < oColumnIn.nelements(); uiColumn++ ) {
    oColumnTemp = oColumnIn(uiColumn);
    oColumnTemp.gsub( RXwhite, "" );
    if ( oColumnTemp == String() ) {
      throw( ermsg( "Invalid column ID(s)", "GDC2Token", "initialize" ) );
    }
  }
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    for ( uiColumn2 = uiColumn+1; uiColumn2 < uiNumColumn; uiColumn2++ ) {
      if ( oColumnIn(uiColumn2).matches( oColumnIn(uiColumn) ) ) {
        throw( ermsg( "Duplicate column IDs", "GDC2Token", "initialize" ) );
      }
    }
  }
  
  if ( oYIn.nrow() != uiNumData || oYIn.ncolumn() != uiNumColumn ) {
    throw( ermsg( "Invalid y vector", "GDC2Token", "initialize" ) );
  }
  
  if ( oXErrIn.nelements() > 0 && oXErrIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid x error vector", "GDC2Token", "initialize" ) );
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
        throw( ermsg( "Invalid x error(s)", "GDC2Token", "initialize" ) );
      }
    }
  } else {
    bXError = False;
  }
  
  if ( ( oYErrIn.nrow() > 0 && oYErrIn.nrow() != uiNumData ) ||
       ( oYErrIn.ncolumn() > 0 && oYErrIn.ncolumn() != uiNumColumn ) ) {
    throw( ermsg( "Invalid y error vector", "GDC2Token", "initialize" ) );
  }
  
  if ( oYErrIn.nrow() > 0 ) {
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      if ( oYErrIn(0,uiColumn) != 0.0 ) {
        bYError = True;
      } else {
        bYError = False;
      }
      for ( uiData = 1; uiData < oYErrIn.nrow(); uiData++ ) {
        if ( ( oYErrIn(uiData,uiColumn) == 0.0 && bYError ) ||
             ( oYErrIn(uiData,uiColumn) != 0.0 && !bYError ) ) {
          throw( ermsg( "Invalid y error(s)", "GDC2Token", "initialize" ) );
        }
      }
    }
  } else {
    bYError = False;
  }
  
  if ( oTokenIn.nelements() != uiNumData ) {
    throw( ermsg( "Invalid token vector", "GDC2Token", "initialize" ) );
  }
  
  String oTokenTemp = String();
  
  for ( uiData = 0; uiData < oTokenIn.nelements(); uiData++ ) {
    oTokenTemp = oTokenIn(uiData);
    oTokenTemp.gsub( RXwhite, "" );
    if ( oTokenTemp == String( "" ) ) {
      throw( ermsg( "Invalid token(s)", "GDC2Token", "initialize" ) );
    }
  }
  
  for ( uiData = 0; uiData < uiNumData; uiData++ ) {
    for ( uiData2 = uiData+1; uiData2 < uiNumData; uiData2++ ) {
      if ( oXIn(uiData2) == oXIn(uiData) &&
           oTokenIn(uiData2).matches( oTokenIn(uiData) ) ) {
        throw( ermsg( "Duplicate x value(s) for a given token", "GDC2Token",
            "initialize" ) );
      }
    }
  }
  
  if ( oFlagIn.nelements() > 0 &&
     ( oFlagIn.nrow() != uiNumData || oFlagIn.ncolumn() != uiNumColumn ) ) {
    throw( ermsg( "Invalid flag matrix", "GDC2Token", "initialize" ) );
  }


  // Initialize the ASCII file name

  if ( poFileASCII == NULL ) {
    poFileASCII = new String();
  }

  
  // Initialize the Vector<T> and Matrix<T> private variables
  
  poX = new Vector<Double>( oXIn.copy() );
  poXOld = new Vector<Double>( oXIn.copy() );
  
  poYOrig = new Matrix<Double>( oYIn.copy() );
  poY = new Matrix<Double>( oYIn.copy() );
  
  if ( bXError ) {
    poXErr = new Vector<Double>( oXErrIn.copy() );
  } else {
    poXErr = new Vector<Double>();
  }
  poXErrOld = new Vector<Double>( poXErr->copy() );
  
  if ( bYError ) {
    poYErrOrig = new Matrix<Double>( oYErrIn.copy() );
  } else {
    poYErrOrig = new Matrix<Double>();
  }
  poYErr = new Matrix<Double>( poYErrOrig->copy() );

  poToken = new Vector<String>( oTokenIn.copy() );
  poColumnList = new Vector<String>( oColumnIn.copy() );
  
  poFlagOrig = new Matrix<Bool>( oFlagIn.copy() );
  poFlag = new Matrix<Bool>( oFlagIn.copy() );
  
  poInterp = new Matrix<Bool>( uiNumData, uiNumColumn, False );

  
  // Deal with token-related objects

  poTokenType = new String( oTokenTypeIn );
  poTokenType->gsub( RXwhite, "" );
    
  for ( uiData = 0; uiData < poToken->nelements(); uiData++ ) {
    (*poToken)(uiData).gsub( RXwhite, "" );
    (*poToken)(uiData).upcase();
    if ( (*poToken)(uiData).length() > LENGTH_MAX ) {
      throw( ermsg( "Token(s) too long", "GDC2Token", "initialize" ) );
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
  
  
  // Deal with column-related objects
  
  poColumnType = new String( oColumnTypeIn );
  poColumnType->gsub( RXwhite, "" );
  
  for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
    (*poColumnList)(uiColumn).gsub( RXwhite, "" );
    (*poColumnList)(uiColumn).upcase();
    if ( (*poColumnList)(uiColumn).length() > LENGTH_MAX ) {
      throw( ermsg( "Column(s) too long", "GDC2Token", "initialize" ) );
    }
  }
  
  
  // Deal with the flag-related objects
  
  IPosition oShape = IPosition( 2, uiNumData, uiNumColumn );
  
  if ( poFlagOrig->nelements() < 1 ) {
    poFlagOrig->resize( oShape );
    poFlag->resize( oShape );
    for ( uiData = 0; uiData < uiNumData; uiData++ ) {
      for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
        (*poFlagOrig)(uiData,uiColumn) = False;
        (*poFlag)(uiData,uiColumn) = False;
      }
    }
  }
  
  if ( bYError ) {
    for ( uiData = 0; uiData < poYErr->nrow(); uiData++ ) {
      for ( uiColumn = 0; uiColumn < poYErr->ncolumn(); uiColumn++ ) {
        if ( (*poYErr)(uiData,uiColumn) < 0.0 ) {
          (*poYErr)(uiData,uiColumn) = fabs( (*poYErr)(uiData,uiColumn) );
          (*poYErrOrig)(uiData,uiColumn) =
              fabs( (*poYErrOrig)(uiData,uiColumn) );
          (*poFlagOrig)(uiData,uiColumn) = True;
          (*poFlag)(uiData,uiColumn) = True;
        }
      }
    }
  }
  
  
  // Sort data according to the x values
  
  Vector<Int> oSortKey = StatToolbox::sortkey( *poX );
  
  StatToolbox::sort( oSortKey, *poX );
  StatToolbox::sort( oSortKey, *poXOld );
  StatToolbox::sort( oSortKey, *poY );
  StatToolbox::sort( oSortKey, *poYOrig );
  
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
  poHistoryColumn = new Vector<Int>();
  poHistoryFlag = new Vector<Bool>();
  poHistoryInterp = new Vector<Bool>();
  poHistoryY = new Vector<Double>();
  poHistoryYErr = new Vector<Double>();
  
  
  // Initialize the plotting limits
  
  poTokenPlot = NULL;
  aoColumnPlot = NULL;
  setTokenColumnDefault();
  
  dXMinDefault = xMin( False );
  dXMaxDefault = xMax( False );
  
  dXMinPlot = xMin( True );
  dXMaxPlot = xMax( True );

  dYMinDefault = yMin( dXMinDefault, dXMaxDefault, *poTokenList, *poColumnList,
      True, False );
  dYMaxDefault = yMax( dXMinDefault, dXMaxDefault, *poTokenList, *poColumnList,
      True, False );

  dYMinPlot = yMin( dXMinDefault, dXMaxDefault, *poTokenList, *poColumnList,
      True, True );
  dYMaxPlot = yMax( dXMinDefault, dXMaxDefault, *poTokenList, *poColumnList,
      True, True );
  
  setKeep( False );
  
  
  // Enable the argument checking

  setArgCheck( True );

  
  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::initializePlotAttrib

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

void GDC2Token::initializePlotAttrib( const Bool& bHMSIn,
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

GDC2Token::loadASCII

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
oXOut      - The x vector.
oYOut      - The y matrix.
oXErrOut   - The x-error vector.
oYErrOut   - The y-error matrix.
oTokenOut  - The token vector.
oColumnOut - The column ID vector.
oFlagOut   - The flag matrix.

Modification history:
---------------------
2001 Jan 10 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::loadASCII( String& oFileIn, Vector<Double>& oXOut,
    Matrix<Double>& oYOut, Vector<Double>& oXErrOut, Matrix<Double>& oYErrOut,
    Vector<String>& oTokenOut, Vector<String>& oColumnOut,
    Matrix<Bool>& oFlagOut ) {

  // Declare the local variables
  
  uInt uiColumn;              // The column ID counter
  uInt uiFlag;                // The uInt version of a Bool flag
  uInt uiNumColumn;           // The number of column IDs
 
  uInt uiData;                // The data counter
  uInt uiNumData;             // The number of data
  
  FILE* pmtStream;            // The data input stream
  
  fpos_t tPosition;           // The file position
  
  Char acLine[LENGTH_MAX+1];  // The temporary line variable
  Char acToken[LENGTH_MAX+1]; // The temporary token variable


  // Get the column IDs and find the number of lines in the file (kludge, since
  // feof does not appear to work correctly under RedHat 6.1)

  oFileIn.gsub( RXwhite, "" );

  pmtStream = fopen( oFileIn.chars(), "r" );
  
  if ( pmtStream == NULL ) {
    throw( ermsg( "Invalid ASCII file", "GDC2Token", "loadASCII" ) );
  }

  poFileASCII = new String( oFileIn );
  
  while ( !feof( pmtStream ) ) {
    fgetpos( pmtStream, &tPosition );
    fgets( acLine, LENGTH_MAX, pmtStream );
    if ( acLine[0] == '#' ) {
      continue;
    }
    fsetpos( pmtStream, &tPosition );
    fscanf( pmtStream, "%u", &uiNumColumn );
    if ( uiNumColumn < 1 ) {
      throw( ermsg( "Invalid number of column IDs", "GDC2Token",
          "loadASCII" ) );
    }
    oColumnOut.resize( uiNumColumn, False );
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      fscanf( pmtStream, "%s", acToken );
      oColumnOut(uiColumn) = String( acToken );
    }
    fgets( acLine, LENGTH_MAX, pmtStream );
    break;
  }
  
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
    throw( ermsg( "Empty ASCII file", "GDC2Token", "loadASCII" ) );
  }
  
  
  // Resize the vectors and matrices

  oXOut.resize( uiNumData, True );
  oYOut.resize( uiNumData, uiNumColumn );
  oXErrOut.resize( uiNumData, True );
  oYErrOut.resize( uiNumData, uiNumColumn );
  oTokenOut.resize( uiNumData, True );
  oFlagOut.resize( uiNumData, uiNumColumn );

  
  // Load the data from the ASCII file

  pmtStream = fopen( oFileIn.chars(), "r" );

  for ( ; ; ) {
    fgets( acLine, LENGTH_MAX, pmtStream );
    if ( acLine[0] == '#' ) {
      continue;
    }
    break;
  }

  uiData = 0;

  while ( uiData < uiNumData ) {
    fgetpos( pmtStream, &tPosition );
    fgets( acLine, LENGTH_MAX, pmtStream );
    if ( acLine[0] == '#' ) {
      continue;
    }
    fsetpos( pmtStream, &tPosition );
    fscanf( pmtStream, "%lf", &oXOut(uiData) );
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      fscanf( pmtStream, "%lf", &oYOut(uiData,uiColumn) );
    }
    fscanf( pmtStream, "%lf", &oXErrOut(uiData) );
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      fscanf( pmtStream, "%lf", &oYErrOut(uiData,uiColumn) );
    }
    fscanf( pmtStream, "%s", acToken );
    oTokenOut(uiData) = String( acToken );
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      fscanf( pmtStream, "%u", &uiFlag );
      oFlagOut(uiData,uiColumn) = (Bool) uiFlag;
    }
    for ( uiColumn = 0; uiColumn < uiNumColumn; uiColumn++ ) {
      fscanf( pmtStream, "%u", &uiFlag ); // Parse interpolation flags
    }
    fgets( acLine, LENGTH_MAX, pmtStream );
    uiData += 1;
  }
  
  fclose( pmtStream );
  
  
  // Return
 
  return;

}

// -----------------------------------------------------------------------------

/*

GDC2Token::plotPoints

Description:
------------
This private member function plots points to a PGPLOT device.

Inputs:
-------
poIndexIn - The data indices.
uiColumn  - The column number.
iCIIn     - The PGPLOT color index.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::plotPoints( const Vector<Int>* const poIndexIn,
    const uInt& uiColumn, const Int& iCIIn ) const {

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
    afY[uiData] = (Float) (*poY)((*poIndexIn)(uiData),uiColumn);
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
      afYErr[uiData] = (Float) (*poYErr)((*poIndexIn)(uiData),uiColumn);
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

GDC2Token::plotLine

Description:
------------
This private member function plots a line to a PGPLOT device.

Inputs:
-------
poIndexIn - The data indices.
uiColumn  - The column number.
iCIIn     - The PGPLOT color index.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 09 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void GDC2Token::plotLine( const Vector<Int>* const poIndexIn,
    const uInt& uiColumn, const Int& iCIIn ) const {

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
    afY[uiData] = (Float) (*poY)((*poIndexIn)(uiData),uiColumn);
  }
    
  cpgline( uiNumData, afX, afY );
    
  delete [] afX;
  delete [] afY;


  // Return
  
  return;
  
}
