//#NATJitter.cc is part of the Cuttlefish server
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
//# $Id: NATJitter.cc,v 19.1 2004/08/25 05:49:26 gvandiep Exp $
// -----------------------------------------------------------------------------

/*

NATJitter.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the NATJitter{ } class member functions.

Public member functions:
------------------------
NATJitter (5 versions), ~NATJitter, baseTool, dumpHDS, saveHDS, tool, version.

Protected member functions.
---------------------------
initialize.

Private member functions:
-------------------------
initMethods, loadHDS.

Inherited classes:
------------------
__IBData.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              File created with public member functions NATJitter( ) (standard,
              average, clone, interpolate, copy versions), ~NATJitter( ),
              baseTool( ), dumpHDS( ), saveHDS( ), tool( ), and version( ); and
              protected member function initialize( ); and private member
              functions initMethods( ) and loadHDS( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/Cuttlefish/NATJitter.h> // NATJitter class
#include <casa/iostream.h>

// -----------------------------------------------------------------------------

/*

NATJitter::NATJitter (standard)

Description:
------------
This public member function constructs an NATJitter{ } object.

Inputs:
-------
oFileIn       - The file name.
uiInputBeamIn - The input-beam number.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

NATJitter::NATJitter( String& oFileIn, const uInt& uiInputBeamIn ) : __IBData1() {
  
  // Initialize the __IBData1{ } base class
  
  String oObject = String( "NATJITTER" );
  String oXToken = String( "SECONDS" );
  
  try {
    __IBData1::initialize( False, IBConfig( oFileIn ), ScanInfo( oFileIn ),
        oObject, uiInputBeamIn, oXToken, oXToken );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg(
        "Cannot initialize __IBData{ } base class\n" + oAipsError.getMesg(),
        "NATJitter", "NATJitter" ) );
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
    throw( ermsg( "Error in loadHDS( )\n" + oAipsError.getMesg(), "NATJitter",
        "NATJitter" ) );
  }
  
  
  // Initialize the GDC1Token base class
  
  String oTokenType = String( "StarID" );
  
  GDC1Token::initialize( oX, oY, oXErr, oYErr, oToken, oFlag, oTokenType );
  
  String oXLabel = xLabels()( xLabelID( oXToken ) );
  
  Char acYLabel[GDC1Token::LENGTH_MAX];
  sprintf( acYLabel, "Nat Jitter #%u (Airy diameters)", uiInputBeamIn );
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

NATJitter::NATJitter (average)

Description:
------------
This public member function constructs an NATJitter{ } object.

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

NATJitter::NATJitter( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
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

NATJitter::NATJitter (clone)

Description:
------------
This public member function constructs an NATJitter{ } object.

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

NATJitter::NATJitter( const ObjectID& oObjectIDIn, Double& dXMinIn, Double& dXMaxIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn )
    : __IBData1( oObjectIDIn, dXMinIn, dXMaxIn, oTokenIn, bKeepIn ) {
    
 // Initialize this object and return
 
 initialize();
 
 return;
 
}

// -----------------------------------------------------------------------------

/*

NATJitter::NATJitter (interpolate)

Description:
------------
This public member function constructs an NATJitter{ } object.

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

NATJitter::NATJitter( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
    Vector<String>& oTokenIn, const Bool& bKeepIn, String& oInterpIn,
    Double& dXMinBoxIn, Double& dXMaxBoxIn ) : __IBData1( oObjectIDIn, oXIn,
    oTokenIn, bKeepIn, oInterpIn, dXMinBoxIn, dXMaxBoxIn ) {
    
 // Initialize this object and return
 
 initialize();
 
 return;
 
}

// -----------------------------------------------------------------------------

/*

NATJitter::NATJitter (copy)

Description:
------------
This public member function constructs an NATJitter{ } object.

Inputs:
-------
oNATJitterIn - The NATJitter{ } object.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

NATJitter::NATJitter( const NATJitter& oNATJitterIn )
    : __IBData1( (const __IBData1&) oNATJitterIn ) {
  
  // Initialize this class and return
  
  initialize();
  
  return;

}

// -----------------------------------------------------------------------------

/*

NATJitter::~NATJitter

Description:
------------
This public member function destructs an NATJitter{ } object.

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

NATJitter::~NATJitter( void ) {

  // Deallocate the memory and return

  delete poMethod;

  return;

}

// -----------------------------------------------------------------------------

/*

NATJitter::dumpHDS

Description:
------------
This public member function dumps the NAT-jitter data into an HDS file (not the
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
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void NATJitter::dumpHDS( String& oFileIn, Double& dXMinIn, Double& dXMaxIn,
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
    throw( ermsg( "Cannot use dumpHDS( ) with the present file", "NATJitter",
        "dumpHDS" ) );
  }

  if ( !checkToken( oTokenIn ) ) {
    throw( ermsg( "Invalid token argument(s)", "NATJitter", "dumpHDS" ) );
  }

  if ( !checkX( dXMinIn, dXMaxIn ) ) {
    throw( ermsg( "Invalid x argument(s)", "NATJitter", "dumpHDS" ) );
  }
  
  
  // Open/close the HDS file (check if writable)
  
  if ( access( oFileIn.chars(), F_OK ) != 0 ) {
  
    try {
      HDSFile oHDSFile = HDSFile( HDSAccess( oFileIn, "NEW" ),
          HDSName( "DataSet" ), HDSType( "" ), HDSDim() );
    }
    
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Cannot create a new HDS file\n" + oAipsError.getMesg(),
          "NATJitter", "dumpHDS" ) );
    }
    
  } else {
  
    try {
      HDSFile oHDSFile = HDSFile( HDSAccess( oFileIn, "UPDATE" ) );
    }
    
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Cannot update the HDS file\n" + oAipsError.getMesg(),
          "NATJitter", "dumpHDS" ) );
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
  
  
  // Dump the NAT jitters
  
  Vector<Double> oYTemp = y( dXMinIn, dXMaxIn, oTokenIn, True, False ).copy();

  uiNumScan = oYTemp.nelements();
  Vector<Float> oYReal = Vector<Float>( uiNumScan );
  for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
    oYReal(uiScan) = (Float) oYTemp(uiScan);
  }
  
  oHDSFile.create_real( HDSName( object() ), Array<Float>( oYReal ), False );
  
  
  // Dump the NAT-jitter errors (negative values are flagged)
  
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

NATJitter::saveHDS

Description:
------------
This public member function save the NAT-jitter data into the present HDS file.

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

void NATJitter::saveHDS( void ) const {

  // Declare/initialize the local variables
  
  uInt uiNumScan;        // The number of scans
  uInt uiScan;           // The scan counter
  
  Double dXMin;          // The minimum x value
  Double dXMax;          // The maximum x value
  
  Vector<String> oToken; // The token list
  
  
  // Can update the present HDS file?
  
  if ( derived() ) {
    cout << msg( "Cannot save data derived from a file\n", "NATJitter",
        "saveHDS", GeneralStatus::NORMAL ).getMesg() << endl << flush;
    return;
  }
  
  try {
    HDSAccess oAccess = HDSAccess( file(), "UPDATE" );
  }
    
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot update the HDS file\n" + oAipsError.getMesg(),
        "NATJitter", "saveHDS" ) );
  }
  
  
  // Open the present HDS file and go to the InputBeam HDS object
  
  HDSFile oHDSFile = HDSFile( HDSAccess( file(), "UPDATE" ) );
  
  oHDSFile.Goto( hdsPath() );
  
  
  // Get the arguments for y( ) and yErr( )
  
  dXMin = xMin();
  dXMax = xMax();
  
  oToken = tokenList();
  
  
  // Save the NAT jitters
  
  Vector<Double> oYTemp = y( dXMin, dXMax, oToken, True, False ).copy();

  uiNumScan = oYTemp.nelements();
  Vector<Float> oYReal = Vector<Float>( uiNumScan );
  for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
    oYReal(uiScan) = (Float) oYTemp(uiScan);
  }
  oHDSFile.create_real( object(), Array<Float>( oYReal ), True );
  
  
  // Save the NAT-jitter errors
  
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

NATJitter::version

Description:
------------
This public member function returns the NATJitter{ } version.

Inputs:
-------
None.

Outputs:
--------
The NATJitter{ } version, returned via the function value.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String NATJitter::version( void ) const {

  // Return the NATJitter{ } version
  
  return( String( "0.0" ) );
  
}

// -----------------------------------------------------------------------------

/*

NATJitter::baseTool

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
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String NATJitter::baseTool( void ) const {

  // Return the glish base-tool name
  
  String oBaseTool = GDC1Token::className();
  oBaseTool.downcase();
  
  return( oBaseTool );
  
}

// -----------------------------------------------------------------------------

/*

NATJitter::tool

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
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String NATJitter::tool( void ) const {

  // Return the glish tool name
  
  String oTool = className();
  oTool.downcase();
  
  return( oTool );
  
}

// -----------------------------------------------------------------------------

/*

NATJitter::className

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

String NATJitter::className( void ) const {

  // Return the class name
  
  return( String( "NATJitter" ) );

}

// -----------------------------------------------------------------------------

/*

NATJitter::methods

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

Vector<String> NATJitter::methods( void ) const {

  // Return the methods

  return( Vector<String>( poMethod->copy() ) );

}

// -----------------------------------------------------------------------------

/*

NATJitter::noTraceMethods

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

Vector<String> NATJitter::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}

// -----------------------------------------------------------------------------

/*

NATJitter::runMethod

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

MethodResult NATJitter::runMethod( uInt uiMethod, ParameterSet &oParameters,
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
          throw( ermsg( "dumpHDS( ) error\n" + oAipsError.getMesg(), "NATJitter",
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
          throw( ermsg( "saveHDS( ) error\n" + oAipsError.getMesg(), "NATJitter",
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
          throw( ermsg( "version( ) error\n" + oAipsError.getMesg(), "NATJitter",
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
          throw( ermsg( "baseTool( ) error\n" + oAipsError.getMesg(), "NATJitter",
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
          throw( ermsg( "tool( ) error\n" + oAipsError.getMesg(), "NATJitter",
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
        "NATJitter", "runMethod" ) );
  }


  // Return ok( )

  return( ok() );

}

// -----------------------------------------------------------------------------

/*

NATJitter::initialize

Description:
------------
This protected member function initializes an NATJitter{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Protected member function created.

*/

// -----------------------------------------------------------------------------

void NATJitter::initialize( void ) {
  
  // Initialize the private variables and return
  
  initMethods();
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

NATJitter::loadHDS

Description:
------------
This private member function loads the NAT-jitter data from an HDS file.

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
2001 Mar 27 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void NATJitter::loadHDS( String& oFileIn, const uInt& uiInputBeamIn,
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
        "NATJitter", "initialize" ) );
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
        "NATJitter", "loadHDS" ) );
  }
  
  
  // Load the NAT jitters
  
  oYOut.resize( uiNumScan, False );
  
  try {
    Vector<Float> oYReal = Vector<Float>( uiNumScan );
    oYReal = Vector<Float>( oHDSFile.obtain_real( HDSName( object() ) ) );
    for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
      oYOut(uiScan) = (Double) oYReal(uiScan);
    }
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot load NAT jitters\n" + oAipsError.getMesg(),
        "NATJitter", "loadHDS" ) );
  }
  
  
  // Load the NAT-jitter errors
  
  oYErrOut.resize( uiNumScan, False );
  
  try {
    Vector<Float> oYErrReal = Vector<Float>( uiNumScan );
    oYErrReal = Vector<Float>( oHDSFile.obtain_real( HDSName( objectErr() ) ) );
    for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
      oYErrOut(uiScan) = (Double) oYErrReal(uiScan);
    }
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot load NAT-jitter errors\n" + oAipsError.getMesg(),
        "NATJitter", "loadHDS" ) );
  }
  
  
  // Load the flag vector
  
  oFlagOut.resize( uiNumScan, False );
  oFlagOut = Vector<Bool>( uiNumScan, False );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

NATJitter::initMethods

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

void NATJitter::initMethods( void ) {

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
