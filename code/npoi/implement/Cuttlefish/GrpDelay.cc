//#GrpDelay.cc is part of the Cuttlefish server
//#Copyright (C) 2001,2002
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
//# $Id: GrpDelay.cc,v 19.1 2004/08/25 05:49:26 gvandiep Exp $
// -----------------------------------------------------------------------------

/*

GrpDelay.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the GrpDelay{ } class member functions.

Public member functions:
------------------------
GrpDelay (5 versions), ~GrpDelay, baseTool, dumpHDS, saveHDS, tool, version.

Protected member functions.
---------------------------
initialize.

Private member functions:
-------------------------
initMethods, loadHDS.

Inherited classes:
------------------
__IBData1.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              File created with public member functions GrpDelay( ) (standard,
              average, clone, interpolate, copy versions), ~GrpDelay( ),
              baseTool( ), dumpHDS( ), saveHDS( ), tool( ), and version( ); and
              protected member function initialize( ); and private member
              functions initMethods( ) and loadHDS( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/Cuttlefish/GrpDelay.h> // GrpDelay class
#include <casa/iostream.h>

// -----------------------------------------------------------------------------

/*

GrpDelay::GrpDelay (standard)

Description:
------------
This public member function constructs a GrpDelay{ } object.

Inputs:
-------
oFileIn       - The file name.
uiInputBeamIn - The input-beam number.

Outputs:
--------
None.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GrpDelay::GrpDelay( String& oFileIn, const uInt& uiInputBeamIn )
    : __IBData1() {
  
  // Initialize the __IBData1{ } base class
  
  String oObject = String( "GRPDELAY" );
  String oXToken = String( "SECONDS" );
  
  try {
    __IBData1::initialize( False, IBConfig( oFileIn ), ScanInfo( oFileIn ),
        oObject, uiInputBeamIn, oXToken, oXToken );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg(
        "Cannot initialize __IBData1{ } base class\n" + oAipsError.getMesg(),
        "GrpDelay", "GrpDelay" ) );
  }
  
  
  // Load the data from the file
  
  Vector<Double> oX = Vector<Double>();
  Vector<Double> oY = Vector<Double>();
  
  Vector<Double> oXErr = Vector<Double>();
  Vector<Double> oYErr = Vector<Double>();
  
  Vector<String> oToken = Vector<String>();
  
  Vector<Bool> oFlag = Vector<Bool>();
  
  try {
    loadHDS( oFileIn, uiInputBeamIn, oX, oY, oXErr, oYErr, oToken, oFlag );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in loadHDS( )\n" + oAipsError.getMesg(), "GrpDelay",
        "GrpDelay" ) );
  }
  
  
  // Initialize the GDC1Token base class
  
  String oTokenType = String( "StarID" );
  
  GDC1Token::initialize( oX, oY, oXErr, oYErr, oToken, oFlag, oTokenType );
  
  String oXLabel = xLabels()( xLabelID( oXToken ) );
  
  Char acYLabel[GDC1Token::LENGTH_MAX];
  sprintf( acYLabel, "Group Delay #%u (m)", uiInputBeamIn );
  String oYLabel = String( acYLabel );
  
  String oTitle = String( "" );
  
  GDC1Token::initializePlotAttrib( False, oXLabel, oYLabel, oTitle, oXLabel,
      oYLabel, oTitle );
  
  
  // Initialize this class and return
  
  initialize();
  
  return;

}

// -----------------------------------------------------------------------------

/*

GrpDelay::GrpDelay (average)

Description:
------------
This public member function constructs a GrpDelay{ } object.

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
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GrpDelay::GrpDelay( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
    Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
    const Bool& bKeepIn, const Bool& bWeightIn, const Bool& bXCalcIn,
    String& oInterpIn ) : __IBData1( oObjectIDIn, oXIn, dXMinIn, dXMaxIn,
    oTokenIn, bKeepIn, bWeightIn, bXCalcIn, oInterpIn ) {
    
 // Initialize this object and return
 
 initialize();
 
 return;
 
}

// -----------------------------------------------------------------------------

/*

GrpDelay::GrpDelay (clone)

Description:
------------
This public member function constructs a GrpDelay{ } object.

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
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GrpDelay::GrpDelay( const ObjectID& oObjectIDIn, Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn )
    : __IBData1( oObjectIDIn, dXMinIn, dXMaxIn, oTokenIn, bKeepIn ) {
    
 // Initialize this object and return
 
 initialize();
 
 return;
 
}

// -----------------------------------------------------------------------------

/*

GrpDelay::GrpDelay (interpolate)

Description:
------------
This public member function constructs a GrpDelay{ } object.

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
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GrpDelay::GrpDelay( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, String& oInterpIn,
    Double& dXMinBoxIn, Double& dXMaxBoxIn ) : __IBData1( oObjectIDIn, oXIn,
    oTokenIn, bKeepIn, oInterpIn, dXMinBoxIn, dXMaxBoxIn ) {
    
 // Initialize this object and return
 
 initialize();
 
 return;
 
}

// -----------------------------------------------------------------------------

/*

GrpDelay::GrpDelay (copy)

Description:
------------
This public member function constructs a GrpDelay{ } object.

Inputs:
-------
oGrpDelayIn - The GrpDelay{ } object.

Outputs:
--------
None.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GrpDelay::GrpDelay( const GrpDelay& oGrpDelayIn )
    : __IBData1( (const __IBData1&) oGrpDelayIn ) {
  
  // Initialize this class and return
  
  initialize();
  
  return;

}

// -----------------------------------------------------------------------------

/*

GrpDelay::~GrpDelay

Description:
------------
This public member function destructs a GrpDelay{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GrpDelay::~GrpDelay( void ) {

  // Deallocate the memory and return

  delete poMethod;

  return;

}

// -----------------------------------------------------------------------------

/*

GrpDelay::dumpHDS

Description:
------------
This public member function dumps the group-delay data into an HDS file (not the
present one).

Inputs:
-------
oFileIn  - The HDS file name (not the present one).
dXMinIn  - The minimum x value.
dXMaxIn  - The maximum x value.
oTokenIn - The tokens.

Outputs:
--------
None.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GrpDelay::dumpHDS( String& oFileIn, Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn ) const {
  
  // Declare the local variables
  
  uInt uiNumScan;   // The number of scans
  uInt uiScan;      // The scan counter
  uInt uiStartScan; // The start scan
  uInt uiStopScan;  // The stop scan
 
 
  // Fix/check the inputs

  oFileIn.gsub( RXwhite, "" );
  String oFile = file();  
  
  if ( oFileIn.matches( oFile ) ) {
    throw( ermsg( "Cannot use dumpHDS( ) with the present file", "GrpDelay",
        "dumpHDS" ) );
  }

  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token argument(s)", "GrpDelay", "dumpHDS" ) );
  }

  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "GrpDelay", "dumpHDS" ) );
  }
  
  
  // Open/close the HDS file (check if writable)
  
  if ( access( oFileIn.chars(), F_OK ) != 0 ) {
  
    try {
      HDSFile oHDSFile = HDSFile( HDSAccess( oFileIn, "NEW" ),
          HDSName( "DataSet" ), HDSType( "" ), HDSDim() );
    }
    
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Cannot create a new HDS file\n" + oAipsError.getMesg(),
          "GrpDelay", "dumpHDS" ) );
    }
    
  } else {
  
    try {
      HDSFile oHDSFile = HDSFile( HDSAccess( oFileIn, "UPDATE" ) );
    }
    
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Cannot update the HDS file\n" + oAipsError.getMesg(),
          "GrpDelay", "dumpHDS" ) );
    }
    
  }
  
  
  // Dump the input-beam configuration and scan information to the HDS file
  // (create a new file, if necessary)
  
  ibConfig().dumpHDS( oFileIn );
  
  Vector<Int> oIndex = index( dXMinIn, dXMaxIn, oTokenIn, True );
  uiStartScan = oIndex(0)+1;
  uiStopScan = oIndex(oIndex.nelements()-1)+1;
  
  scanInfo().dumpHDS( oFileIn, uiStartScan, uiStopScan, oTokenIn );
  
  
  // Open the HDS file again and go to the InputBeam HDS object (create
  // InputBeam, if necessary)
  
  HDSFile oHDSFile = HDSFile( HDSAccess( oFileIn, "UPDATE" ) );
  
  oHDSFile.find( HDSName( "ScanData" ) );
  
  if ( !oHDSFile.there( HDSName( "INPUTBEAM" ) ) ) {
    oHDSFile.New( HDSName( "INPUTBEAM" ), HDSType( "" ),
        HDSDim( numInputBeam() ), True );
  }
  
  oHDSFile.find( HDSName( "INPUTBEAM" ) );
  oHDSFile.cell( HDSDim( inputBeam() ) );
  
  
  // Dump the group delays
  
  Vector<Double> oYTemp = y( dXMinIn, dXMaxIn, oTokenIn, True, False ).copy();
  
  oHDSFile.create_double( HDSName( object() ), Array<Double>( oYTemp ), False );
  
  
  // Dump the group-delay errors (negative values are flagged)
  
  Vector<Double> oYErrTemp =
      yErr( dXMinIn, dXMaxIn, oTokenIn, True, False ).copy();
  Vector<Bool> oFlagTemp = flag( dXMinIn, dXMaxIn, oTokenIn, False );
  
  uiNumScan = oYErrTemp.nelements();
  Vector<Float> oYErrReal = Vector<Float>( uiNumScan );
  for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
    if ( !oFlagTemp(uiScan) ) {
      oYErrReal(uiScan) = (Float) oYErrTemp(uiScan);
    } else {
      oYErrReal(uiScan) = (Float) -1.0 * oYErrTemp(uiScan);
    }
  }
  
  oHDSFile.create_real( HDSName( objectErr() ), Array<Float>( oYErrReal ),
      False );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GrpDelay::saveHDS

Description:
------------
This public member function save the group-delay data into the present HDS file.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GrpDelay::saveHDS( void ) const {

  // Declare/initialize the local variables
  
  uInt uiNumScan;        // The number of scans
  uInt uiScan;           // The scan counter
  
  Double dXMin;          // The minimum x value
  Double dXMax;          // The maximum x value
  
  Vector<String> oToken; // The token list
  
  
  // Can update the present HDS file?
  
  if ( derived() ) {
    cout << msg( "Cannot save data derived from a file\n", "GrpDelay",
        "saveHDS", GeneralStatus::NORMAL ).getMesg() << endl << flush;
    return;
  }
  
  try {
    HDSAccess oAccess = HDSAccess( file(), "UPDATE" );
  }
    
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot update the HDS file\n" + oAipsError.getMesg(),
        "GrpDelay", "saveHDS" ) );
  }
  
  
  // Open the present HDS file and go to the InputBeam HDS object
  
  HDSFile oHDSFile = HDSFile( HDSAccess( file(), "UPDATE" ) );
  
  oHDSFile.Goto( hdsPath() );
  
  
  // Get the arguments for y( ) and yErr( )
  
  dXMin = xMin();
  dXMax = xMax();
  
  oToken = tokenList();
  
  
  // Save the group delays
  
  Vector<Double> oYTemp = y( dXMin, dXMax, oToken, True, False ).copy();

  oHDSFile.create_double( object(), Array<Double>( oYTemp ), True );
  
  
  // Save the group-delay errors
  
  Vector<Double> oYErrTemp = yErr( dXMin, dXMax, oToken, True, False ).copy();
  Vector<Bool> oFlagTemp = flag( dXMin, dXMax, oToken, False );
  
  uiNumScan = oYErrTemp.nelements();
  Vector<Float> oYErrReal = Vector<Float>( uiNumScan );
  for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
    if ( !oFlagTemp(uiScan) ) {
      oYErrReal(uiScan) = (Float) oYErrTemp(uiScan);
    } else {
      oYErrReal(uiScan) = (Float) -1.0 * oYErrTemp(uiScan);
    }
  }
  
  oHDSFile.create_real( objectErr(), Array<Float>( oYErrReal ), True );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GrpDelay::version

Description:
------------
This public member function returns the GrpDelay{ } version.

Inputs:
-------
None.

Outputs:
--------
The GrpDelay{ } version, returned via the function value.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GrpDelay::version( void ) const {

  // Return the GrpDelay{ } version
  
  return( String( "0.0" ) );
  
}

// -----------------------------------------------------------------------------

/*

GrpDelay::baseTool

Description:
------------
This public member function returns the glish base-tool name.

Inputs:
-------
None.

Outputs:
--------
The glish base-tool name, returned via the function value.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GrpDelay::baseTool( void ) const {

  // Return the glish base-tool name
  
  String oBaseTool = GDC1Token::className();
  oBaseTool.downcase();
  
  return( oBaseTool );
  
}

// -----------------------------------------------------------------------------

/*

GrpDelay::tool

Description:
------------
This public member function returns the glish tool name.

Inputs:
-------
None.

Outputs:
--------
The glish tool name, returned via the function value.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GrpDelay::tool( void ) const {

  // Return the glish tool name
  
  String oTool = className();
  oTool.downcase();
  
  return( oTool );
  
}

// -----------------------------------------------------------------------------

/*

GrpDelay::className

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
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GrpDelay::className( void ) const {

  // Return the class name
  
  return( "GrpDelay" );

}

// -----------------------------------------------------------------------------

/*

GrpDelay::methods

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
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GrpDelay::methods( void ) const {

  // Return the methods

  return( Vector<String>( poMethod->copy() ) );

}

// -----------------------------------------------------------------------------

/*

GrpDelay::noTraceMethods

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
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GrpDelay::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}

// -----------------------------------------------------------------------------

/*

GrpDelay::runMethod

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
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult GrpDelay::runMethod( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method (this class)

  switch ( uiMethod ) {

    // dumpHDS
    case 0: {
      Parameter<String> file( oParameters, "file", ParameterSet::In );
      Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
      Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
      Parameter< Vector<String> >
          tokenarg( oParameters, "tokenarg", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          dumpHDS( file(), xmin(), xmax(), tokenarg() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "dumpHDS( ) error\n" + oAipsError.getMesg(), "GrpDelay",
              "runMethod" ) );
        }
      }
      return( ok() );
    }

    // saveHDS
    case 1: {
      if ( bRunMethod ) {
        try {
          saveHDS();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "saveHDS( ) error\n" + oAipsError.getMesg(), "GrpDelay",
              "runMethod" ) );
        }
      }
      return( ok() );
    }

    // version
    case 2: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = version();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "version( ) error\n" + oAipsError.getMesg(), "GrpDelay",
              "runMethod" ) );
        }
      }
      return( ok() );
    }

    // baseTool
    case 3: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = baseTool();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "baseTool( ) error\n" + oAipsError.getMesg(), "GrpDelay",
              "runMethod" ) );
        }
      }
      return( ok() );
    }

    // tool
    case 4: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tool();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tool( ) error\n" + oAipsError.getMesg(), "GrpDelay",
              "runMethod" ) );
        }
      }
      return( ok() );
    }

  }
  
  
  // Parse the method parameters and run the desired method (__IBData1{ } base
  // class)

  try {
    __IBData1::runMethod( uiMethod-uiNumMethod, oParameters, bRunMethod );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in __IBData1{ } base class\n" + oAipsError.getMesg(),
        "GrpDelay", "runMethod" ) );
  }


  // Return ok( )

  return( ok() );

}

// -----------------------------------------------------------------------------

/*

GrpDelay::initialize

Description:
------------
This protected member function initializes a GrpDelay{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              Protected member function created.

*/

// -----------------------------------------------------------------------------

void GrpDelay::initialize( void ) {
  
  // Initialize the private variables and return
  
  initMethods();
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

GrpDelay::loadHDS

Description:
------------
This private member function loads the group-delay data from an HDS file.

Inputs:
-------
oFileIn       - The HDS file name.
uiInputBeamIn - The input-beam number.

Outputs:
--------
oXOut     - The x values.
oYOut     - The y values.
oXErrOut  - The x errors.
oYErrOut  - The y errors.
oTokenOut - The tokens.
oFlagOut  - The flags.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void GrpDelay::loadHDS( String& oFileIn, const uInt& uiInputBeamIn,
    Vector<Double>& oXOut, Vector<Double>& oYOut, Vector<Double>& oXErrOut,
    Vector<Double>& oYErrOut, Vector<String>& oTokenOut,
    Vector<Bool>& oFlagOut ) {
  
  // Declare the local variables
  
  uInt uiNumScan;   // The number of scans
  uInt uiScan;      // The scan counter
  uInt uiStartScan; // The start scan
  uInt uiStopScan;  // The stop scan
  
  
  // Check the file name
  
  oFileIn.gsub( RXwhite, "" );
  
  try {
    ScanInfo oScanInfo = ScanInfo( oFileIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg(
        "Cannot create scan data information\n" + oAipsError.getMesg(),
        "GrpDelay", "initialize" ) );
  }
  
  
  // Get the scan information
  
  ScanInfo oScanInfo = ScanInfo( oFileIn );
  
  uiNumScan = oScanInfo.numScan();
  uiStartScan = 1;
  uiStopScan = uiNumScan;
  
  Vector<String> oStarID = oScanInfo.starList();
  
  oXOut.resize( uiNumScan, False );
  oXOut = oScanInfo.scanTime( uiStartScan, uiStopScan, oStarID );
  
  oXErrOut.resize( 0, False );
  
  oTokenOut.resize( uiNumScan, False );
  oTokenOut = oScanInfo.starID( uiStartScan, uiStopScan, oStarID );
  

  // Go to the InputBeam HDS object
  
  HDSFile oHDSFile = HDSFile( HDSAccess( oFileIn, "READ" ) );
  
  try {
    oHDSFile.Goto( hdsPath() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot go to ScanData HDS object\n" + oAipsError.getMesg(),
        "GrpDelay", "loadHDS" ) );
  }
  
  
  // Load the group delays
  
  oYOut.resize( uiNumScan, False );
  
  try {
    oYOut = Vector<Double>( oHDSFile.obtain_double( HDSName( object() ) ) );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot load group delays\n" + oAipsError.getMesg(),
        "GrpDelay", "loadHDS" ) );
  }
  
  
  // Load the group-delay errors
  
  oYErrOut.resize( uiNumScan, False );
  
  try {
    Vector<Float> oYErrReal = Vector<Float>( uiNumScan );
    oYErrReal = Vector<Float>( oHDSFile.obtain_real( HDSName( objectErr() ) ) );
    for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
      oYErrOut(uiScan) = (Double) oYErrReal(uiScan);
    }
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot load group-delay errors\n" + oAipsError.getMesg(),
        "GrpDelay", "loadHDS" ) );
  }
  
  
  // Load the flag vector
  
  oFlagOut.resize( uiNumScan, False );
  oFlagOut = Vector<Bool>( uiNumScan, False );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GrpDelay::initMethods

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
2001 May 10 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void GrpDelay::initMethods( void ) {

  // Declare the local variables
  
  uInt uiMethodBD;    // The __IBData1{ } method counter
  uInt uiNumMethodBD; // The number of methods in the __IBData1{ } base class
  

  // Load the methods of this class into the method list
  
  uiNumMethod = 5;
  
  poMethod = new Vector<String>( uiNumMethod );
  
  (*poMethod)(0) = String( "dumpHDS" );
  (*poMethod)(1) = String( "saveHDS" );
  (*poMethod)(2) = String( "version" );
  (*poMethod)(3) = String( "baseTool" );
  (*poMethod)(4) = String( "tool" );
  
  
  // Load the methods of the __IBData1{ } base class into the method list
  
  Vector<String> oMethodBD = Vector<String>( __IBData1::methods() );
  
  uiNumMethodBD = oMethodBD.nelements();
  
  poMethod->resize( uiNumMethod+uiNumMethodBD, True );
  
  for ( uiMethodBD = 0; uiMethodBD < uiNumMethodBD; uiMethodBD++ ) {
    (*poMethod)(uiMethodBD+uiNumMethod) = oMethodBD(uiMethodBD);
  }


  // Return

  return;

}
