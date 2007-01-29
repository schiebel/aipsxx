//#SysConfig.cc is part of the Cuttlefish server
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
//# $Id: SysConfig.cc,v 19.0 2003/07/16 06:02:27 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

SysConfig.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the SysConfig{ } class member functions.

Public member functions:
------------------------
SysConfig (3 versions), ~SysConfig, beamCombinerID, date, dumpHDS, file,
format, instrCohInt, refStation, systemID, tool, userID, version.

Private member functions:
-------------------------
loadHDS.

Inherited classes (aips++):
---------------------------
ApplicationObject.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              File created with public member functions SysConfig( ) (null,
              standard, and copy versions), ~SysConfig( ), beamCombinerID( ),
              date( ), dumpHDS( ), file( ), format( ), instrCohInt( ),
              refStation( ), systemID( ), tool( ), userID( ), and version( );
              and private member function loadHDS( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/Cuttlefish/SysConfig.h> // SysConfig file

// -----------------------------------------------------------------------------

/*

SysConfig::SysConfig (null)

Description:
------------
This public member function constructs a SysConfig{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

SysConfig::SysConfig( void ) {}

// -----------------------------------------------------------------------------

/*

SysConfig::SysConfig (standard)

Description:
------------
This public member function constructs a SysConfig{ } object.

Inputs:
-------
oFileIn - The HDS file name.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

SysConfig::SysConfig( const String& oFileIn ) {  
  
  // Load configuration from the HDS file and initialize this object
  
  try {
    loadHDS( oFileIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in loadHDS( )\n" + oAipsError.getMesg(), "SysConfig",
        "SysConfig" ) );
  }
  
  
  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

SysConfig::SysConfig (copy)

Description:
------------
This public member function copies a SysConfig{ } object.

Inputs:
-------
oSysConfigIn - The SysConfig{ } object.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

SysConfig::SysConfig( const SysConfig& oSysConfigIn ) {

  // Copy the SysConfig{ } object and return
  
  poFile = new String( oSysConfigIn.file() );
  
  uiBeamCombinerID = oSysConfigIn.beamCombinerID();
  uiRefStation = oSysConfigIn.refStation();
  
  poDate = new String( oSysConfigIn.date() );
  poFormat = new String( oSysConfigIn.format() );
  poSystemID = new String( oSysConfigIn.systemID() );
  poUserID = new String( oSysConfigIn.userID() );
  
  dInstrCohInt = oSysConfigIn.instrCohInt();
 
  return;

}

// -----------------------------------------------------------------------------

/*

SysConfig::~SysConfig

Description:
------------
This public member function destructs a SysConfig{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

SysConfig::~SysConfig( void ) {

  // Deallocate the memory and return
  
  delete poFile;
  
  delete poDate;
  delete poFormat;
  delete poSystemID;
  delete poUserID;

  return;

}

// -----------------------------------------------------------------------------

/*

SysConfig::file

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
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String SysConfig::file( void ) const {

  // Return the file name

  return( String( *poFile ) );

}

// -----------------------------------------------------------------------------

/*

SysConfig::beamCombinerID

Description:
------------
This public member function returns the beam-combiner ID.

Inputs:
-------
None.

Outputs:
--------
The beam-combiner ID, returned via the function value.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt SysConfig::beamCombinerID( void ) const {

  // Return the beam-combiner ID

  return( uiBeamCombinerID );

}

// -----------------------------------------------------------------------------

/*

SysConfig::date

Description:
------------
This public member function returns the date.

Inputs:
-------
None.

Outputs:
--------
The date, returned via the function value.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String SysConfig::date( void ) const {

  // Return the date

  return( String( *poDate ) );

}

// -----------------------------------------------------------------------------

/*

SysConfig::format

Description:
------------
This public member function returns the format.

Inputs:
-------
None.

Outputs:
--------
The format, returned via the function value.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String SysConfig::format( void ) const {

  // Return the format

  return( String( *poFormat ) );

}

// -----------------------------------------------------------------------------

/*

SysConfig::instrCohInt

Description:
------------
This public member function returns the instrument coherent integration.

Inputs:
-------
None.

Outputs:
--------
The instrument coherent integration, returned via the function value.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double SysConfig::instrCohInt( void ) const {

  // Return the instrument coherent integration

  return( dInstrCohInt );

}

// -----------------------------------------------------------------------------

/*

SysConfig::refStation

Description:
------------
This public member function returns the reference station.

Inputs:
-------
None.

Outputs:
--------
The reference station, returned via the function value.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt SysConfig::refStation( void ) const {

  // Return the reference station

  return( uiRefStation );

}

// -----------------------------------------------------------------------------

/*

SysConfig::systemID

Description:
------------
This public member function returns the system ID.

Inputs:
-------
None.

Outputs:
--------
The system ID, returned via the function value.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String SysConfig::systemID( void ) const {

  // Return the system ID

  return( String( *poSystemID ) );

}

// -----------------------------------------------------------------------------

/*

SysConfig::userID

Description:
------------
This public member function returns the user ID.

Inputs:
-------
None.

Outputs:
--------
The user ID, returned via the function value.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String SysConfig::userID( void ) const {

  // Return the user ID

  return( String( *poUserID ) );

}

// -----------------------------------------------------------------------------

/*

SysConfig::dumpHDS

Description:
------------
This public member function dumps the system configuration into an HDS file.

Inputs:
-------
oFileIn - The HDS file name (default = "" --> the present HDS file name).

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void SysConfig::dumpHDS( const String& oFileIn ) const {

  // Declare/initialize the local variables
  
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
          "SysConfig", "dumpHDS" ) );
    }
    delete poHDSFile;
  }
  
  try {
    HDSAccess oAccess = HDSAccess( oFile, "UPDATE" );
    poHDSFile = new HDSFile( oAccess );
  }
  
  catch( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg( "Cannot open HDS file\n" + oAipsError.getMesg(), "SysConfig",
        "dumpHDS" ) );
  }
  
  
  // Dump/check the top-level system configuration information
  
  if ( !poHDSFile->there( HDSName( "Date" ) ) ) {
    try {
      poHDSFile->screate_char( HDSName( "Date" ), 10, *poDate, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create Date HDS object\n" + oAipsError.getMesg(),
          "SysConfig", "dumpHDS" ) );
    }
  }
  
  if ( !poHDSFile->there( HDSName( "Format" ) ) ) {
    try {
      poHDSFile->screate_char( HDSName( "Format" ), 9, *poFormat, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create Format HDS object\n" + oAipsError.getMesg(),
          "SysConfig", "dumpHDS" ) );
    }
  }
  
  if ( !poHDSFile->there( HDSName( "SystemID" ) ) ) {
    try {
      poHDSFile->screate_char( HDSName( "SystemID" ), 4, *poSystemID, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create SystemID HDS object\n" + oAipsError.getMesg(),
          "SysConfig", "dumpHDS" ) );
    }
  }
  
  if ( !poHDSFile->there( HDSName( "UserID" ) ) ) {
    try {
      poHDSFile->screate_char( HDSName( "UserID" ), 3, *poUserID, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create UserID HDS object\n" + oAipsError.getMesg(),
          "SysConfig", "dumpHDS" ) );
    }
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
          "SysConfig", "dumpHDS" ) );
    }
  }

  poHDSFile->find( HDSName( "GenConfig" ) );
  
  
  // Dump/check the second-level system configuration information
  
  if ( !poHDSFile->there( HDSName( "BeamCombinerID" ) ) ) {
    try {
      poHDSFile->screate_integer(
          HDSName( "BeamCombinerID" ), (Int) uiBeamCombinerID, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create BeamCombinerID HDS object\n" + oAipsError.getMesg(),
          "SysConfig", "dumpHDS" ) );
    }
  }
  
  if ( !poHDSFile->there( HDSName( "RefStation" ) ) ) {
    try {
      poHDSFile->screate_integer(
          HDSName( "RefStation" ), (Int) uiRefStation, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create RefStation HDS object\n" + oAipsError.getMesg(),
          "SysConfig", "dumpHDS" ) );
    }
  }
  
  if ( !poHDSFile->there( HDSName( "InstrCohInt" ) ) ) {
    try {
      poHDSFile->screate_double( HDSName( "InstrCohInt" ), dInstrCohInt, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create InstrCohInt HDS object\n" + oAipsError.getMesg(),
          "SysConfig", "dumpHDS" ) );
    }
  }
  
  
  // Close the HDS file
  
  delete poHDSFile;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

SysConfig::version

Description:
------------
This public member function returns the SysConfig{ } version.

Inputs:
-------
None.

Outputs:
--------
The SysConfig{ } version, returned via the function value.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String SysConfig::version( void ) const {

  // Return the SysConfig{ } version
  
  return( String( "0.0" ) );
  
}

// -----------------------------------------------------------------------------

/*

SysConfig::tool

Description:
------------
This public member function returns the glish tool name (must be "sysconfig").

Inputs:
-------
None.

Outputs:
--------
The glish tool name, returned via the function value.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String SysConfig::tool( void ) const {

  // Return the glish tool name
  
  String oTool = className();
  oTool.downcase();
  
  return( oTool );
  
}

// -----------------------------------------------------------------------------

/*

SysConfig::className

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
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String SysConfig::className( void ) const {

  // Return the class name
  
  return( String( "SysConfig" ) );

}

// -----------------------------------------------------------------------------

/*

SysConfig::methods

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
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> SysConfig::methods( void ) const {

  // Return the method names
  
  Vector<String> oMethod = Vector<String>( 12 );
  
  oMethod(0) = String( "file" );
  oMethod(1) = String( "beamCombinerID" );
  oMethod(2) = String( "date" );
  oMethod(3) = String( "format" );
  oMethod(4) = String( "instrCohInt" );
  oMethod(5) = String( "refStation" );
  oMethod(6) = String( "systemID" );
  oMethod(7) = String( "userID" );
  oMethod(8) = String( "dumpHDS" );
  oMethod(9) = String( "id" );
  oMethod(10) = String( "version" );
  oMethod(11) = String( "tool" );
  
  return( oMethod );

}

// -----------------------------------------------------------------------------

/*

SysConfig::noTraceMethods

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
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> SysConfig::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}

// -----------------------------------------------------------------------------

/*

SysConfig::runMethod

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
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult SysConfig::runMethod( uInt uiMethod, ParameterSet &oParameters,
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
          throw( ermsg( "file( ) error\n" + oAipsError.getMesg(), "SysConfig",
              "runMethod" ) );
        }
      }
      break;
    }
  
    // beamCombinerID
    case 1: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) beamCombinerID();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "beamCombinerID( ) error\n" + oAipsError.getMesg(),
              "SysConfig", "runMethod" ) );
        }
      }
      break;
    }
  
    // date
    case 2: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = date();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "date( ) error\n" + oAipsError.getMesg(), "SysConfig",
              "runMethod" ) );
        }
      }
      break;
    }
  
    // format
    case 3: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = format();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "format( ) error\n" + oAipsError.getMesg(), "SysConfig",
              "runMethod" ) );
        }
      }
      break;
    }
  
    // instrCohInt
    case 4: {
      Parameter<Double> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = instrCohInt();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "instrCohInt( ) error\n" + oAipsError.getMesg(),
              "SysConfig", "runMethod" ) );
        }
      }
      break;
    }
  
    // refStation
    case 5: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) refStation();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "refStation( ) error\n" + oAipsError.getMesg(),
              "SysConfig", "runMethod" ) );
        }
      }
      break;
    }
  
    // systemID
    case 6: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = systemID();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "systemID( ) error\n" + oAipsError.getMesg(),
              "SysConfig", "runMethod" ) );
        }
      }
      break;
    }
  
    // userID
    case 7: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = userID();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "userID( ) error\n" + oAipsError.getMesg(), "SysConfig",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // dumpHDS
    case 8: {
      Parameter<String> file( oParameters, "file", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          dumpHDS( file() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "dumpHDS( ) error\n" + oAipsError.getMesg(),
              "SysConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // id    
    case 9: {
      Parameter<ObjectID> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
	  returnval() = id();
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "id( ) error\n" + oAipsError.getMesg(), "SysConfig",
	      "runMethod" ) );
	}
      }
      break;
    }

    // version
    case 10: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = version();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "version( ) error\n" + oAipsError.getMesg(),
              "SysConfig", "runMethod" ) );
        }
      }
      break;
    }

    // tool
    case 11: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tool();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tool( ) error\n" + oAipsError.getMesg(), "SysConfig",
	      "runMethod" ) );
        }
      }
      break;
    }

    // default
    default: {
      if ( bRunMethod ) {
        throw( ermsg( "Invalid SysConfig{ } method", "SysConfig", "runMethod" ) );
      }
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}

// -----------------------------------------------------------------------------

/*

SysConfig::loadHDS

Description:
------------
This private member function loads the system configuration from an HDS file.

Inputs:
-------
oFileIn - The HDS file name.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void SysConfig::loadHDS( const String& oFileIn ) {
  
  // Declare/initialize the local variables
  
  HDSFile* poHDSFile = NULL; // The HDSFile{ } object
  

  // Open the HDS file
  
  poFile = new String( oFileIn );
  poFile->gsub( RXwhite, "" );
  
  try {
    HDSAccess oAccess = HDSAccess( *poFile, "READ" );
    poHDSFile = new HDSFile( oAccess );
  }
  
  catch( AipsError oAipsError ) {
    throw( ermsg( "Cannot open HDS file\n" + oAipsError.getMesg(), "SysConfig",
        "loadHDS" ) );
  }
  
  
  // Get the system configuration
  
  try {
    poDate = new String( Vector<String>(
        poHDSFile->obtain_char( HDSName( "Date" ) ) )(0) );
    poFormat = new String( Vector<String>(
        poHDSFile->obtain_char( HDSName( "Format" ) ) )(0) );
    poSystemID = new String( Vector<String>(
        poHDSFile->obtain_char( HDSName( "SystemID" ) ) )(0) );
    poUserID = new String( Vector<String>( 
        poHDSFile->obtain_char( HDSName( "UserID" ) ) )(0) );
  }
  
  catch ( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg(
        "Cannot load top-level system configutation\n" + oAipsError.getMesg(),
        "SysConfig", "loadHDS" ) );
  }
  
  try {
    poHDSFile->find( HDSName( "GenConfig" ) );
  }
  
  catch ( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg( "Cannot find GenConfig HDS object" + oAipsError.getMesg(),
        "SysConfig", "loadHDS" ) );
  }
  
  try {
    uiBeamCombinerID = (uInt) Vector<Int>(
        poHDSFile->obtain_integer( HDSName( "BeamCombinerID" ) ) )(0);
    uiRefStation = (uInt) Vector<Int>(
        poHDSFile->obtain_integer( HDSName( "RefStation" ) ) )(0);
    dInstrCohInt = Vector<Double>(
        poHDSFile->obtain_double( HDSName( "InstrCohInt" ) ) )(0);
  }
  
  catch ( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg(
        "Cannot load second-level system configutation\n"+oAipsError.getMesg(),
        "SysConfig", "loadHDS" ) );
  }
  

  // Close the HDS file

  delete poHDSFile;
  
  
  // Return
  
  return;

}
