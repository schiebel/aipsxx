//#IBConfig.cc is part of the Cuttlefish server
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
//# $Id: IBConfig.cc,v 19.0 2003/07/16 06:02:17 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

IBConfig.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the IBConfig{ } class member functions.

Public member functions:
------------------------
IBConfig (3 versions), ~IBConfig, bcInputID, delayLineID, dumpHDS, file,
ibObjects, ibObjectErrs, ibTools, ibTypes, ibTypeErrs, ibYLabelDefaults,
inputBeamID, numInputBeam, numSiderostat, siderostatID, starTrackerID,
stationCoord, stationID, tool, version.

Private member functions:
-------------------------
checkInputBeam, loadHDS.

Inherited classes (aips++):
---------------------------
ApplicationObject.

Modification history:
---------------------
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              File created with public member functions IBConfig( ) (null,
              standard, and copy versions), ~IBConfig( ), file( ), tool( ), and
              version( ); and private member function loadHDS( ).
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member functions bcInputID( ), delayLineID( ), dumpHDS( ),
              ibTools( ), inputBeamID( ), numInputBeam( ), numSiderostat( ),
              siderostatID( ), starTrackerID( ), stationCoord( ), and
              stationID( ).
2000 Aug 23 - Nicholas Elias, USNO/NPOI
              Public member function ibYLabelDefaults( ) added.
2001 Jan 30 - Nicholas Elias, USNO/NPOI
              Public member functions ibObjects( ), ibObjectErrs( ),
              ibTypes( ), ibTypeErrs( ) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/Cuttlefish/IBConfig.h> // IBConfig file

// -----------------------------------------------------------------------------

/*

IBConfig::IBConfig (null)

Description:
------------
This public member function constructs an IBConfig{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

IBConfig::IBConfig( void ) {}

// -----------------------------------------------------------------------------

/*

IBConfig::IBConfig

Description:
------------
This public member function constructs an IBConfig{ } object.

Inputs:
-------
oFileIn - The HDS file name.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

IBConfig::IBConfig( const String& oFileIn ) {  
  
  // Load configuration from the HDS file and initialize this object
  
  try {
    loadHDS( oFileIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in loadHDS( )\n" + oAipsError.getMesg(), "IBConfig",
        "IBConfig" ) );
  }
  
  
  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

IBConfig::IBConfig (copy)

Description:
------------
This public member function copies an IBConfig{ } object.

Inputs:
-------
oIBConfigIn - The IBConfig{ } object.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

IBConfig::IBConfig( const IBConfig& oIBConfigIn ) {

  // Declare the local variables

  uInt uiInputBeam; // The input-beam counter


  // Copy the IBConfig{ } object and return
  
  poFile = new String( oIBConfigIn.file() );
  
  uiNumInputBeam = oIBConfigIn.numInputBeam();
  uiNumSiderostat = oIBConfigIn.numSiderostat();
  
  poBCInputID = new Vector<Int>( uiNumInputBeam );
  poDelayLineID = new Vector<Int>( uiNumInputBeam );
  poInputBeamID = new Vector<Int>( uiNumInputBeam );
  poSiderostatID = new Vector<Int>( uiNumInputBeam );
  poStarTrackerID = new Vector<Int>( uiNumInputBeam );
  
  poStationID = new Vector<String>( uiNumInputBeam );
  
  aoStationCoord = new Vector<Double>* [uiNumInputBeam];

  for ( uiInputBeam = 0; uiInputBeam < uiNumInputBeam; uiInputBeam++ ) {
    (*poBCInputID)(uiInputBeam) = (uInt) oIBConfigIn.bcInputID( uiInputBeam+1 );
    (*poDelayLineID)(uiInputBeam) =
        (uInt) oIBConfigIn.delayLineID( uiInputBeam+1 );
    (*poInputBeamID)(uiInputBeam) =
        (uInt) oIBConfigIn.inputBeamID( uiInputBeam+1 );
    (*poSiderostatID)(uiInputBeam) =
        (uInt) oIBConfigIn.siderostatID( uiInputBeam+1 );
    (*poStarTrackerID)(uiInputBeam) =
        (uInt) oIBConfigIn.starTrackerID( uiInputBeam+1 );
    (*poStationID)(uiInputBeam) = oIBConfigIn.stationID( uiInputBeam+1 );
    aoStationCoord[uiInputBeam] =
        new Vector<Double>( oIBConfigIn.stationCoord( uiInputBeam+1 ) );
  }
  
  return;

}

// -----------------------------------------------------------------------------

/*

IBConfig::~IBConfig

Description:
------------
This public member function destructs an IBConfig{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

IBConfig::~IBConfig( void ) {

  // Declare the local variables
  
  uInt uiInputBeam; // The input-beam counter
  

  // Deallocate the memory and return
  
  delete poFile;
  
  delete poBCInputID;
  delete poDelayLineID;
  delete poInputBeamID;
  delete poSiderostatID;
  delete poStarTrackerID;
  
  delete poStationID;
  
  for ( uiInputBeam = 0; uiInputBeam < uiNumInputBeam; uiInputBeam++ ) {
    delete aoStationCoord[uiInputBeam];
  }
  
  delete aoStationCoord;

  return;

}

// -----------------------------------------------------------------------------

/*

IBConfig::file

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
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String IBConfig::file( void ) const {

  // Return the file name

  return( String( *poFile ) );

}

// -----------------------------------------------------------------------------

/*

IBConfig::numInputBeam

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
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt IBConfig::numInputBeam( void ) const {

  // Return the number of input beams

  return( uiNumInputBeam );

}

// -----------------------------------------------------------------------------

/*

IBConfig::numSiderostat

Description:
------------
This public member function returns the number of siderostats.  NB: This
function returns the same number as numInputBeam( ); it is included for
backwards compatibility.

Inputs:
-------
None.

Outputs:
--------
The number of siderostats, returned via the function value.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt IBConfig::numSiderostat( void ) const {

  // Return the number of siderostats

  return( uiNumSiderostat );

}

// -----------------------------------------------------------------------------

/*

IBConfig::bcInputID

Description:
------------
This public member function returns the beam-combiner input ID.

Inputs:
-------
uiInputBeamIn - The input-beam number.

Outputs:
--------
The beam-combiner input ID, returned via the function value.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt IBConfig::bcInputID( const uInt& uiInputBeamIn ) const {

  // Check the input-beam number
  
  if ( !checkInputBeam( uiInputBeamIn ) ) {
    throw( ermsg( "Invalid input-beam number", "IBConfig", "bcInputID" ) );
  }
  

  // Return the beam-combiner input ID

  return( (*poBCInputID)(uiInputBeamIn-1) );

}

// -----------------------------------------------------------------------------

/*

IBConfig::delayLineID

Description:
------------
This public member function returns the delay-line ID.

Inputs:
-------
uiInputBeamIn - The input-beam number.

Outputs:
--------
The delay-line ID, returned via the function value.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt IBConfig::delayLineID( const uInt& uiInputBeamIn ) const {

  // Check the input-beam number
  
  if ( !checkInputBeam( uiInputBeamIn ) ) {
    throw( ermsg( "Invalid input-beam number", "IBConfig", "delayLineID" ) );
  }
  

  // Return the delay-line ID

  return( (*poDelayLineID)(uiInputBeamIn-1) );

}

// -----------------------------------------------------------------------------

/*

IBConfig::inputBeamID

Description:
------------
This public member function returns the input-beam ID.

Inputs:
-------
uiInputBeamIn - The input-beam number.

Outputs:
--------
The input-beam ID, returned via the function value.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt IBConfig::inputBeamID( const uInt& uiInputBeamIn ) const {

  // Check the input-beam number
  
  if ( !checkInputBeam( uiInputBeamIn ) ) {
    throw( ermsg( "Invalid input-beam number", "IBConfig", "inputBeamID" ) );
  }
  

  // Return the input-beam ID

  return( (*poInputBeamID)(uiInputBeamIn-1) );

}

// -----------------------------------------------------------------------------

/*

IBConfig::siderostatID

Description:
------------
This public member function returns the siderostat ID.  NB: This function
returns the same number as inputBeamID( ); it is included for backwards
compatibility.

Inputs:
-------
uiInputBeamIn - The input-beam number.

Outputs:
--------
The siderostat ID, returned via the function value.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt IBConfig::siderostatID( const uInt& uiInputBeamIn ) const {

  // Check the input-beam number
  
  if ( !checkInputBeam( uiInputBeamIn ) ) {
    throw( ermsg( "Invalid input-beam number", "IBConfig", "siderostatID" ) );
  }
  

  // Return the siderostat ID

  return( (*poSiderostatID)(uiInputBeamIn-1) );

}

// -----------------------------------------------------------------------------

/*

IBConfig::starTrackerID

Description:
------------
This public member function returns the star-tracker ID.

Inputs:
-------
uiInputBeamIn - The input-beam number.

Outputs:
--------
The star-tracker ID, returned via the function value.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt IBConfig::starTrackerID( const uInt& uiInputBeamIn ) const {

  // Check the input-beam number
  
  if ( !checkInputBeam( uiInputBeamIn ) ) {
    throw( ermsg( "Invalid input-beam number", "IBConfig", "starTrackerID" ) );
  }
  

  // Return the star-tracker ID

  return( (*poStarTrackerID)(uiInputBeamIn-1) );

}

// -----------------------------------------------------------------------------

/*

IBConfig::stationID

Description:
------------
This public member function returns the station ID.

Inputs:
-------
uiInputBeamIn - The input-beam number.

Outputs:
--------
The station ID, returned via the function value.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String IBConfig::stationID( const uInt& uiInputBeamIn ) const {

  // Check the input-beam number
  
  if ( !checkInputBeam( uiInputBeamIn ) ) {
    throw( ermsg( "Invalid input-beam number", "IBConfig", "stationID" ) );
  }
  

  // Return the station ID

  return( (*poStationID)(uiInputBeamIn-1) );

}

// -----------------------------------------------------------------------------

/*

IBConfig::stationCoord

Description:
------------
This public member function returns the station coordinates.

Inputs:
-------
uiInputBeamIn - The input-beam number.

Outputs:
--------
The station coordinates, returned via the function value.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> IBConfig::stationCoord( const uInt& uiInputBeamIn ) const {

  // Check the input-beam number
  
  if ( !checkInputBeam( uiInputBeamIn ) ) {
    throw( ermsg( "Invalid input-beam number", "IBConfig", "stationCoord" ) );
  }
  

  // Return the station coordinates

  return( *aoStationCoord[uiInputBeamIn-1] );

}

// -----------------------------------------------------------------------------

/*

IBConfig::dumpHDS

Description:
------------
This public member function dumps the input-beam configuration into an HDS file.

Inputs:
-------
oFileIn - The HDS file name (default = "" --> the present HDS file name).

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void IBConfig::dumpHDS( const String& oFileIn ) const {

  // Declare/initialize the local variables
  
  uInt uiInputBeam;          // The input-beam counter
  uInt uiInputBeam2;         // The HDS input-beam counter
  
  String oFile;              // The HDS file
  
  HDSFile* poHDSFile = NULL; // HDSFile{ } object
  

  // Open the HDS file (create it, if necessary)
  
  if ( !oFileIn.matches( RXwhite ) ) {
    oFile = String( oFileIn );
  } else {
    oFile = String( *poFile );
  }
  
  if ( access( oFile.chars(), F_OK ) != 0 ) {
    try {
      poHDSFile = new HDSFile( HDSAccess( oFile, "NEW" ), HDSName( "DataSet" ),
          HDSType( "" ), HDSDim() );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg( "Cannot create HDS file\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }
    delete poHDSFile;
  }
  
  try {
    HDSAccess oAccess = HDSAccess( oFile, "UPDATE" );
    poHDSFile = new HDSFile( oAccess );
  }
  
  catch( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg( "Cannot open HDS file\n" + oAipsError.getMesg(), "IBConfig",
        "dumpHDS" ) );
  }
  
  
  // Go to the GenConfig HDS object (create it, if necessary)

  if ( !poHDSFile->there( HDSName( "GenConfig" ) ) ) {
    try {
      poHDSFile->New( HDSName( "GenConfig" ), HDSType( "" ), HDSDim(), True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create GenConfig HDS object\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }
  }

  poHDSFile->find( HDSName( "GenConfig" ) );
  
  
  // Go to the InputBeam HDS object (create it, if necessary)

  if ( !poHDSFile->there( HDSName( "InputBeam" ) ) ) {
    try {
      poHDSFile->New( HDSName( "InputBeam" ), HDSType( "" ), HDSDim(), True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create InputBeam HDS object\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }
  }

  poHDSFile->find( HDSName( "InputBeam" ) );
  
  
  // Dump/check the number of siderostats
  
  if ( !poHDSFile->there( HDSName( "NumSid" ) ) ) {

    try {
      poHDSFile->screate_integer( HDSName( "NumSid" ), uiNumSiderostat, True );
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg( "Cannot create NumSid HDS object\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }

  } else {
  
    uInt uiNumSiderostatTemp = 0; // Keep compiler happy
  
    try {
      uiNumSiderostatTemp =
          Vector<Int>( poHDSFile->obtain_integer( HDSName( "NumSid" ) ) )(0);
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      String oError = "Cannot get number of siderostats from HDS file\n";
      oError += oAipsError.getMesg();
      throw( ermsg( oError, "IBConfig", "dumpHDS" ) );
    }
    
    if ( uiNumSiderostatTemp != uiNumSiderostat ) {
      throw( ermsg( "Number of siderostats do not match", "IBConfig",
          "dumpHDS" ) );
    }
  
  }
  
  
  // Dump/check the beam-combiner input IDs
  
  if ( !poHDSFile->there( HDSName( "BCInputID" ) ) ) {

    try {
      poHDSFile->create_integer( HDSName( "BCInputID" ),
          Array<Int>( *poBCInputID ), True );
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create BCInputID HDS object\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }

  } else {
  
    Vector<Int> oBCInputIDTemp; // Keep compiler happy
  
    try {
      oBCInputIDTemp = poHDSFile->obtain_integer( HDSName( "BCInputID" ) );
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get BCInputID from HDS file\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }
    
    if ( oBCInputIDTemp != *poBCInputID ) {
      throw( ermsg( "Beam-combiner input IDs do not match", "IBConfig",
          "dumpHDS" ) );
    }
  
  }
  
  
  // Dump/check the delay-line IDs
  
  if ( !poHDSFile->there( HDSName( "DelayLineID" ) ) ) {

    try {
      poHDSFile->create_integer( HDSName( "DelayLineID" ),
          Array<Int>( *poDelayLineID ), True );
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create DelayLineID HDS object\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }

  } else {
  
    Vector<Int> oDelayLineIDTemp; // Keep compiler happy
  
    try {
      oDelayLineIDTemp = poHDSFile->obtain_integer( HDSName( "DelayLineID" ) );
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get DelayLineID from HDS file\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }
    
    if ( oDelayLineIDTemp != *poDelayLineID ) {
      throw( ermsg( "Delay-line IDs do not match", "IBConfig", "dumpHDS" ) );
    }
  
  }
  
  
  // Dump/check the siderostat IDs
  
  if ( !poHDSFile->there( HDSName( "SiderostatID" ) ) ) {

    try {
      poHDSFile->create_integer( HDSName( "SiderostatID" ),
          Array<Int>( *poSiderostatID ), True );
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create SiderostatID HDS object\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }

  } else {
  
    Vector<Int> oSiderostatIDTemp; // Keep compiler happy
  
    try {
      oSiderostatIDTemp =
          poHDSFile->obtain_integer( HDSName( "SiderostatID" ) );
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get SiderostatID from HDS file\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }
    
    if ( oSiderostatIDTemp != *poSiderostatID ) {
      throw( ermsg( "Siderostat IDs do not match", "IBConfig", "dumpHDS" ) );
    }
  
  }
  
  
  // Dump/check the star-tracker IDs
  
  if ( !poHDSFile->there( HDSName( "StarTrackerID" ) ) ) {

    try {
      poHDSFile->create_integer( HDSName( "StarTrackerID" ),
          Array<Int>( *poStarTrackerID ), True );
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create StarTrackerID HDS object\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }

  } else {
  
    Vector<Int> oStarTrackerIDTemp; // Keep compiler happy
  
    try {
      oStarTrackerIDTemp =
          poHDSFile->obtain_integer( HDSName( "StarTrackerID" ) );
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get StarTrackerID from HDS file\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }
    
    if ( oStarTrackerIDTemp != *poStarTrackerID ) {
      throw( ermsg( "Star-tracker IDs do not match", "IBConfig", "dumpHDS" ) );
    }
  
  }
  
  
  // Dump/check the station IDs
  
  if ( !poHDSFile->there( HDSName( "StationID" ) ) ) {

    try {
      poHDSFile->create_char( HDSName( "StationID" ), 3,
          Array<String>( *poStationID ), True );
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create StationID HDS object\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }

  } else {
  
    Vector<String> oStationIDTemp; // Keep compiler happy
  
    try {
      oStationIDTemp = poHDSFile->obtain_char( HDSName( "StationID" ) );
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get StationID from HDS file\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }
    
    for ( uiInputBeam = 0; uiInputBeam < uiNumInputBeam; uiInputBeam++ ) {
      if ( oStationIDTemp(uiInputBeam) != (*poStationID)(uiInputBeam) ) {
        throw( ermsg( "Station IDs do not match", "IBConfig", "dumpHDS" ) );
      }
    }
  
  }
  
  
  // Dump/check the station coordinates
  
  if ( !poHDSFile->there( HDSName( "StationCoord" ) ) ) {

    try {
      poHDSFile->New( HDSName( "StationCoord" ), HDSType( "_DOUBLE" ),
          HDSDim( 4, uiNumInputBeam ), True );
      poHDSFile->find( HDSName( "StationCoord" ) );
      for ( uiInputBeam = 0; uiInputBeam < uiNumInputBeam; uiInputBeam++ ) {
        uiInputBeam2 = uiInputBeam + 1;
        poHDSFile->slice( HDSDim( 1,uiInputBeam2 ), HDSDim( 4,uiInputBeam2 ) );
        poHDSFile->put_double( *aoStationCoord[uiInputBeam] );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create StationCoord HDS object\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }

  } else {
  
    Vector<Double> aoStationCoordTemp[uiNumInputBeam]; // Keep compiler happy

    try {
      poHDSFile->find( HDSName( "StationCoord" ) );
      for ( uiInputBeam = 0; uiInputBeam < uiNumInputBeam; uiInputBeam++ ) {
        uiInputBeam2 = uiInputBeam + 1;
        poHDSFile->slice( HDSDim( 1,uiInputBeam2 ), HDSDim( 4,uiInputBeam2 ) );
        aoStationCoordTemp[uiInputBeam] =
            poHDSFile->get_double().reform( IPosition(1,4) );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get StationCoord from HDS file\n" + oAipsError.getMesg(),
          "IBConfig", "dumpHDS" ) );
    }
    
    uInt uiCoord;
    
    for ( uiInputBeam = 0; uiInputBeam < uiNumInputBeam; uiInputBeam++ ) {
      for ( uiCoord = 0; uiCoord < 4; uiCoord++ ) {
        if ( aoStationCoordTemp[uiInputBeam](uiCoord) !=
            (*aoStationCoord[uiInputBeam])(uiCoord) ) {
          throw( ermsg( "Station coordinates do not match", "IBConfig",
              "dumpHDS" ) );
        }
      }
    }
      
  }
  
  
  // Close the HDS file
  
  delete poHDSFile;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

IBConfig::version

Description:
------------
This public member function returns the IBConfig{ } version.

Inputs:
-------
None.

Outputs:
--------
The IBConfig{ } version, returned via the function value.

Modification history:
---------------------
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String IBConfig::version( void ) const {

  // Return the IBConfig{ } version
  
  return( String( "0.0" ) );
  
}

// -----------------------------------------------------------------------------

/*

IBConfig::tool

Description:
------------
This public member function returns the glish tool name (must be "ibconfig").

Inputs:
-------
None.

Outputs:
--------
The glish tool name, returned via the function value.

Modification history:
---------------------
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String IBConfig::tool( void ) const {

  // Return the glish tool name
  
  String oTool = className();
  oTool.downcase();
  
  return( oTool );
  
}

// -----------------------------------------------------------------------------

/*

IBConfig::ibToolID

Description:
------------
This public member function returns the input-beam tool ID.

Inputs:
-------
oIBToolIn - The input-beam tool name.

Outputs:
--------
The input-beam tool ID, returned via the function value.

Modification history:
---------------------
2000 Aug 23 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Int IBConfig::ibToolID( String& oIBToolIn ) const {

  // Declare the local variables
  
  uInt uiNumTool; // The number of tools
  uInt uiTool;    // The tool counter
  

  // Return the input-beam tool ID
  
  oIBToolIn.gsub( RXwhite, "" );
  oIBToolIn.upcase();
  
  Vector<String> oIBToolList = ibTools();
  uiNumTool = oIBToolList.nelements();
  
  for ( uiTool = 0; uiTool < uiNumTool; uiTool++ ) {
    if ( oIBToolIn.matches( oIBToolList(uiTool) ) ) {
      break;
    }
  }
  
  if ( uiTool < uiNumTool ) {
    return( (Int) uiTool );
  } else {
    return( -1 );
  }
  
}

// -----------------------------------------------------------------------------

/*

IBConfig::ibTools

Description:
------------
This public member function returns the input-beam tool names.

Inputs:
-------
None.

Outputs:
--------
The input-beam tool names, returned via the function value.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> IBConfig::ibTools( void ) const {

  // Return the input-beam tool names
  
  Vector<String> oTools = Vector<String>( 5 );
  
  oTools(0) = String( "DRYDELAY" );
  oTools(1) = String( "FDLPOS" );
  oTools(2) = String( "GRPDELAY" );
  oTools(3) = String( "NATJITTER" );
  oTools(4) = String( "WETDELAY" );
  
  return( oTools );
  
}

// -----------------------------------------------------------------------------

/*

IBConfig::ibObjects

Description:
------------
This public member function returns the input-beam HDS object names.

Inputs:
-------
None.

Outputs:
--------
The input-beam HDS object names, returned via the function value.

Modification history:
---------------------
2001 Jan 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> IBConfig::ibObjects( void ) const {

  // Return the input-beam HDS object names
  
  Vector<String> oObjects = Vector<String>( 5 );
  
  oObjects(0) = String( "DRYDELAY" );
  oObjects(1) = String( "FDLPOS" );
  oObjects(2) = String( "GRPDELAY" );
  oObjects(3) = String( "NATJITTER" );
  oObjects(4) = String( "WETDELAY" );
  
  return( oObjects );
  
}

// -----------------------------------------------------------------------------

/*

IBConfig::ibObjectErrs

Description:
------------
This public member function returns the input-beam HDS object-error names.

Inputs:
-------
None.

Outputs:
--------
The input-beam HDS object-error names, returned via the function value.

Modification history:
---------------------
2001 Jan 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> IBConfig::ibObjectErrs( void ) const {

  // Return the input-beam HDS object-error names
  
  Vector<String> oObjectErrs = Vector<String>( 5 );
  
  oObjectErrs(0) = String( "DRYDELAYERR" );
  oObjectErrs(1) = String( "FDLPOSERR" );
  oObjectErrs(2) = String( "GRPDELAYERR" );
  oObjectErrs(3) = String( "NATJITTERERR" );
  oObjectErrs(4) = String( "WETDELAYERR" );
  
  return( oObjectErrs );
  
}

// -----------------------------------------------------------------------------

/*

IBConfig::ibTypes

Description:
------------
This public member function returns the input-beam HDS object types.

Inputs:
-------
None.

Outputs:
--------
The input-beam HDS object types, returned via the function value.

Modification history:
---------------------
2001 Jan 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> IBConfig::ibTypes( void ) const {

  // Return the input-beam HDS object types
  
  Vector<String> oTypes = Vector<String>( 5 );
  
  oTypes(0) = String( "_DOUBLE" );
  oTypes(1) = String( "_DOUBLE" );
  oTypes(2) = String( "_DOUBLE" );
  oTypes(3) = String( "_REAL" );
  oTypes(4) = String( "_DOUBLE" );
  
  return( oTypes );
  
}

// -----------------------------------------------------------------------------

/*

IBConfig::ibTypeErrs

Description:
------------
This public member function returns the input-beam HDS object-error types.

Inputs:
-------
None.

Outputs:
--------
The input-beam HDS object-error types, returned via the function value.

Modification history:
---------------------
2001 Jan 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> IBConfig::ibTypeErrs( void ) const {

  // Return the input-beam HDS object-error types
  
  Vector<String> oTypeErrs = Vector<String>( 5 );
  
  oTypeErrs(0) = String( "_REAL" );
  oTypeErrs(1) = String( "_REAL" );
  oTypeErrs(2) = String( "_REAL" );
  oTypeErrs(3) = String( "_REAL" );
  oTypeErrs(4) = String( "_REAL" );
  
  return( oTypeErrs );
  
}

// -----------------------------------------------------------------------------

/*

IBConfig::ibYLabelDefaults

Description:
------------
This public member function returns the input-beam y-axis label defaults.

Inputs:
-------
None.

Outputs:
--------
The input-beam y-axis label defaults, returned via the function value.

Modification history:
---------------------
2000 Aug 23 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> IBConfig::ibYLabelDefaults( void ) const {

  // Return the input-beam y-axis label defaults
  
  Vector<String> oYLabels = Vector<String>( 5 );
  
  oYLabels(0) = String( "Dry Delay (\\gmm)" );
  oYLabels(1) = String( "FDL Position (m)" );
  oYLabels(2) = String( "Group Delay (\\gmm)" );
  oYLabels(3) = String( "NAT Jitter (Airy diameters)" );
  oYLabels(4) = String( "Wet Delay (\\gmm)" );
  
  return( oYLabels );
  
}

// -----------------------------------------------------------------------------

/*

IBConfig::className

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
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String IBConfig::className( void ) const {

  // Return the class name
  
  return( String( "IBConfig" ) );

}

// -----------------------------------------------------------------------------

/*

IBConfig::methods

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
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> IBConfig::methods( void ) const {

  // Return the method names
  
  Vector<String> oMethod = Vector<String>( 21 );
  
  oMethod(0) = String( "file" );
  oMethod(1) = String( "numInputBeam" );
  oMethod(2) = String( "numSiderostat" );
  oMethod(3) = String( "bcInputID" );
  oMethod(4) = String( "delayLineID" );
  oMethod(5) = String( "inputBeamID" );
  oMethod(6) = String( "siderostatID" );
  oMethod(7) = String( "starTrackerID" );
  oMethod(8) = String( "stationID" );
  oMethod(9) = String( "stationCoord" );
  oMethod(10) = String( "dumpHDS" );
  oMethod(11) = String( "id" );
  oMethod(12) = String( "version" );
  oMethod(13) = String( "tool" );
  oMethod(14) = String( "ibTools" );
  oMethod(15) = String( "ibObjects" );
  oMethod(16) = String( "ibObjectErrs" );
  oMethod(17) = String( "ibTypes" );
  oMethod(18) = String( "ibTypeErrs" );
  oMethod(19) = String( "ibYLabelDefaults" );
  oMethod(20) = String( "checkInputBeam" );
  
  return( oMethod );

}

// -----------------------------------------------------------------------------

/*

IBConfig::noTraceMethods

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
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> IBConfig::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}

// -----------------------------------------------------------------------------

/*

IBConfig::runMethod

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
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult IBConfig::runMethod( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {
    
    // file
    case 0: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = file();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "file( ) error\n" + oAipsError.getMesg(), "IBConfig",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // numInputBeam
    case 1: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) numInputBeam();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "numInputBeam( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // numSiderostat
    case 2: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) numSiderostat();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "numSiderostat( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // bcInputID
    case 3: {
      Parameter<Int> inputbeam( oParameters, "inputbeam", ParameterSet::In );
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) bcInputID( (uInt) inputbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "bcInputID( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // delayLineID
    case 4: {
      Parameter<Int> inputbeam( oParameters, "inputbeam", ParameterSet::In );
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) delayLineID( (uInt) inputbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "delayLineID( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // inputBeamID
    case 5: {
      Parameter<Int> inputbeam( oParameters, "inputbeam", ParameterSet::In );
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) inputBeamID( (uInt) inputbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "inputBeamID( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // siderostatID
    case 6: {
      Parameter<Int> inputbeam( oParameters, "inputbeam", ParameterSet::In );
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) siderostatID( (uInt) inputbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "siderostatID( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // starTrackerID
    case 7: {
      Parameter<Int> inputbeam( oParameters, "inputbeam", ParameterSet::In );
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) starTrackerID( (uInt) inputbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "starTrackerID( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // stationID
    case 8: {
      Parameter<Int> inputbeam( oParameters, "inputbeam", ParameterSet::In );
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = stationID( (uInt) inputbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "stationID( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // stationCoord
    case 9: {
      Parameter<Int> inputbeam( oParameters, "inputbeam", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = stationCoord( (uInt) inputbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "stationCoord( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // dumpHDS
    case 10: {
      Parameter<String> file( oParameters, "file", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          dumpHDS( file() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "dumpHDS( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // id    
    case 11: {
      Parameter<ObjectID> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
	  returnval() = id();
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "id( ) error\n" + oAipsError.getMesg(), "IBConfig",
	      "runMethod" ) );
	}
      }
      break;
    }

    // version
    case 12: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = version();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "version( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // tool
    case 13: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tool();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tool( ) error\n" + oAipsError.getMesg(), "IBConfig",
	      "runMethod" ) );
        }
      }
      break;
    }

    // ibTools
    case 14: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = ibTools();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "ibTools( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // ibObjects
    case 15: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = ibObjects();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "ibObjects( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // ibObjectErrs
    case 16: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = ibObjectErrs();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "ibObjectErrs( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // ibTypes
    case 17: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = ibTypes();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "ibTypes( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // ibTypeErrs
    case 18: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = ibTypeErrs();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "ibTypeErrs( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // ibYLabelDefaults
    case 19: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = ibYLabelDefaults();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "ibYLabelDefaults( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // checkInputBeam
    case 20: {
      Parameter<Int> inputbeam( oParameters, "inputbeam", ParameterSet::In );
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = checkInputBeam( (uInt) inputbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "checkInputBeam( ) error\n" + oAipsError.getMesg(),
              "IBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // default
    default: {
      if ( bRunMethod ) {
        throw( ermsg( "Invalid IBConfig{ } method", "IBConfig", "runMethod" ) );
      }
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}

// -----------------------------------------------------------------------------

/*

IBConfig::checkInputBeam

Description:
------------
This private member function checks the input-beam number.

Inputs:
-------
uiInputBeamIn - The input-beam number.

Outputs:
--------
True (if OK) or False (if !OK), returned via the function value.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Private member function created.
              
*/

// -----------------------------------------------------------------------------

Bool IBConfig::checkInputBeam( const uInt& uiInputBeamIn ) const {

  // Check the input-beam number and return the boolean
  
  if ( uiInputBeamIn >= 1 && uiInputBeamIn <= numInputBeam() ) {
    return( True );
  } else {
    return( False );
  }

}

// -----------------------------------------------------------------------------

/*

IBConfig::loadHDS

Description:
------------
This private member function loads the input-beam configuration from an HDS
file.

Inputs:
-------
oFileIn - The HDS file name.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void IBConfig::loadHDS( const String& oFileIn ) {
  
  // Declare/initialize the local variables
  
  uInt uiInputBeam;          // The input-beam counter
  uInt uiInputBeam2;         // The HDS input-beam counter
  
  HDSFile* poHDSFile = NULL; // The HDSFile{ } object
  

  // Open the HDS file
  
  poFile = new String( oFileIn );
  poFile->gsub( RXwhite, "" );
  
  try {
    HDSAccess oAccess = HDSAccess( *poFile, "READ" );
    poHDSFile = new HDSFile( oAccess );
  }
  
  catch( AipsError oAipsError ) {
    throw( ermsg( "Cannot open HDS file\n" + oAipsError.getMesg(), "IBConfig",
        "loadHDS" ) );
  }
  
  
  // Go to the input-beam configuration
  
  try {
    poHDSFile->Goto( "DataSet.GenConfig.InputBeam" );
  }
  
  catch ( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg( "No input-beam configuration\n" + oAipsError.getMesg(),
        "IBConfig", "loadHDS" ) );
  }
  
  
  // Get the input-beam configuration
  
  try {
    uiNumSiderostat = (uInt) Vector<Int>(
        poHDSFile->obtain_integer( HDSName( "NumSid" ) ) )(0);
    uiNumInputBeam = uiNumSiderostat;
    poBCInputID = new Vector<Int>(
        poHDSFile->obtain_integer( HDSName( "BCInputID" ) ) );
    poDelayLineID = new Vector<Int>(
        poHDSFile->obtain_integer( HDSName( "DelayLineID" ) ) );
    poSiderostatID = new Vector<Int>(
        poHDSFile->obtain_integer( HDSName( "SiderostatID" ) ) );
    poInputBeamID = new Vector<Int>( *poSiderostatID );
    poStarTrackerID = new Vector<Int>(
        poHDSFile->obtain_integer( HDSName( "StarTrackerID" ) ) );
    poStationID = new Vector<String>(
        poHDSFile->obtain_char( HDSName( "StationID" ) ) );
    poHDSFile->find( HDSName( "StationCoord" ) );
    aoStationCoord = new Vector<Double>* [uiNumInputBeam];
    for ( uiInputBeam = 0; uiInputBeam < uiNumInputBeam; uiInputBeam++ ) {
      uiInputBeam2 = uiInputBeam + 1;
      poHDSFile->slice( HDSDim( 1, uiInputBeam2 ), HDSDim( 4, uiInputBeam2 ) );
      aoStationCoord[uiInputBeam] = new Vector<Double>(
          poHDSFile->get_double().reform( IPosition(1,4) ) );
      poHDSFile->annul();
    }
    poHDSFile->annul();
  }
  
  catch ( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg(
        "Cannot load input-beam configuration\n" + oAipsError.getMesg(),
        "IBConfig", "loadHDS" ) );
  }


  // Close the HDS file

  delete poHDSFile;
  
  
  // Return
  
  return;

}
