//#GeoParms.cc is part of the Cuttlefish server
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
//# $Id: GeoParms.cc,v 19.0 2003/07/16 06:02:24 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

GeoParms.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the GeoParms{ } class member functions.

Public member functions:
------------------------
GeoParms (3 versions), ~GeoParms, altitude, dumpHDS, earthRadius, file, j2,
latitude, longitude, taiMinusUTC, tdtMinusTAI, tool, version.

Private member functions:
-------------------------
loadHDS.

Inherited classes (aips++):
---------------------------
ApplicationObject.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              File created with public member functions GeoParms( ) (null,
              standard, and copy versions), ~GeoParms( ), altitude( ),
              dumpHDS( ), earthRadius( ), file( ), j2( ), latitude( ),
              longitude( ), taiMinusUTC( ), tdtMinusTAI( ), tool( ), and
              version( ); and private member function loadHDS( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/Cuttlefish/GeoParms.h> // GeoParms file

// -----------------------------------------------------------------------------

/*

GeoParms::GeoParms (null)

Description:
------------
This public member function constructs a GeoParms{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GeoParms::GeoParms( void ) {}

// -----------------------------------------------------------------------------

/*

GeoParms::GeoParms (standard)

Description:
------------
This public member function constructs a GeoParms{ } object.

Inputs:
-------
oFileIn - The HDS file name.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GeoParms::GeoParms( const String& oFileIn ) {  
  
  // Load geodetic parameters from the HDS file and initialize this object
  
  try {
    loadHDS( oFileIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in loadHDS( )\n" + oAipsError.getMesg(), "GeoParms",
        "GeoParms" ) );
  }
  
  
  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

GeoParms::GeoParms (copy)

Description:
------------
This public member function copies a GeoParms{ } object.

Inputs:
-------
oGeoParmsIn - The GeoParms{ } object.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GeoParms::GeoParms( const GeoParms& oGeoParmsIn ) {

  // Copy the GeoParms{ } object and return
  
  poFile = new String( oGeoParmsIn.file() );
  
  dAltitude = oGeoParmsIn.altitude();
  dEarthRadius = oGeoParmsIn.earthRadius();
  dJ2 = oGeoParmsIn.j2();
  dLatitude = oGeoParmsIn.latitude();
  dLongitude = oGeoParmsIn.longitude();
  dTAIMinusUTC = oGeoParmsIn.taiMinusUTC();
  dTDTMinusTAI = oGeoParmsIn.tdtMinusTAI();
  
  return;

}

// -----------------------------------------------------------------------------

/*

GeoParms::~GeoParms

Description:
------------
This public member function destructs a GeoParms{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GeoParms::~GeoParms( void ) {

  // Deallocate the memory and return
  
  delete poFile;

  return;

}

// -----------------------------------------------------------------------------

/*

GeoParms::file

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
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GeoParms::file( void ) const {

  // Return the file name

  return( String( *poFile ) );

}

// -----------------------------------------------------------------------------

/*

GeoParms::altitude

Description:
------------
This public member function returns the altitude.

Inputs:
-------
None.

Outputs:
--------
The altitude, returned via the function value.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GeoParms::altitude( void ) const {

  // Return the altitude

  return( dAltitude );

}

// -----------------------------------------------------------------------------

/*

GeoParms::earthRadius

Description:
------------
This public member function returns the earth radius.

Inputs:
-------
None.

Outputs:
--------
The earth radius, returned via the function value.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GeoParms::earthRadius( void ) const {

  // Return the earth radius

  return( dEarthRadius );

}

// -----------------------------------------------------------------------------

/*

GeoParms::j2

Description:
------------
This public member function returns J2.

Inputs:
-------
None.

Outputs:
--------
J2, returned via the function value.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GeoParms::j2( void ) const {

  // Return j2

  return( dJ2 );

}

// -----------------------------------------------------------------------------

/*

GeoParms::latitude

Description:
------------
This public member function returns the latitude.

Inputs:
-------
None.

Outputs:
--------
The latitude, returned via the function value.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GeoParms::latitude( void ) const {

  // Return the latitude

  return( dLatitude );

}

// -----------------------------------------------------------------------------

/*

GeoParms::longitude

Description:
------------
This public member function returns the longitude.

Inputs:
-------
None.

Outputs:
--------
The longitude, returned via the function value.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GeoParms::longitude( void ) const {

  // Return the longitude

  return( dLongitude );

}

// -----------------------------------------------------------------------------

/*

GeoParms::taiMinusUTC

Description:
------------
This public member function returns TAI minus UTC.

Inputs:
-------
None.

Outputs:
--------
TAI minus UTC, returned via the function value.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GeoParms::taiMinusUTC( void ) const {

  // Return the TAI minus UTC

  return( dTAIMinusUTC );

}

// -----------------------------------------------------------------------------

/*

GeoParms::tdtMinusTAI

Description:
------------
This public member function returns TDT minus TAI.

Inputs:
-------
None.

Outputs:
--------
TDT minus TAI, returned via the function value.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Double GeoParms::tdtMinusTAI( void ) const {

  // Return the TDT minus TAI

  return( dTDTMinusTAI );

}

// -----------------------------------------------------------------------------

/*

GeoParms::dumpHDS

Description:
------------
This public member function dumps the geodetic parameters into an HDS file.

Inputs:
-------
oFileIn - The HDS file name (default = "" --> the present HDS file name).

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void GeoParms::dumpHDS( const String& oFileIn ) const {

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
          "GeoParms", "dumpHDS" ) );
    }
    delete poHDSFile;
  }
  
  try {
    HDSAccess oAccess = HDSAccess( oFile, "UPDATE" );
    poHDSFile = new HDSFile( oAccess );
  }
  
  catch( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg( "Cannot open HDS file\n" + oAipsError.getMesg(), "GeoParms",
        "dumpHDS" ) );
  }
  
  
  // Go to the GeoParms HDS object (create it, if necessary)

  if ( !poHDSFile->there( HDSName( "GeoParms" ) ) ) {
    try {
      poHDSFile->New( HDSName( "GeoParms" ), HDSType( "" ), HDSDim(), True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create GeoParms HDS object\n" + oAipsError.getMesg(),
          "GeoParms", "dumpHDS" ) );
    }
  }

  poHDSFile->find( HDSName( "GeoParms" ) );
  
  
  // Dump/check the geodetic parameters
  
  if ( !poHDSFile->there( HDSName( "Altitude" ) ) ) {
    try {
      poHDSFile->screate_double( HDSName( "Altitude" ), dAltitude, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create Altitude HDS object\n" + oAipsError.getMesg(),
          "GeoParms", "dumpHDS" ) );
    }
  }
  
  if ( !poHDSFile->there( HDSName( "EarthRadius" ) ) ) {
    try {
      poHDSFile->screate_double( HDSName( "EarthRadius" ), dEarthRadius, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create EarthRadius HDS object\n" + oAipsError.getMesg(),
          "GeoParms", "dumpHDS" ) );
    }
  }
  
  if ( !poHDSFile->there( HDSName( "J2" ) ) ) {
    try {
      poHDSFile->screate_double( HDSName( "J2" ), dJ2, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create J2 HDS object\n" + oAipsError.getMesg(),
          "GeoParms", "dumpHDS" ) );
    }
  }
  
  if ( !poHDSFile->there( HDSName( "Latitude" ) ) ) {
    try {
      poHDSFile->screate_double( HDSName( "Latitude" ), dLatitude, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create Latitude HDS object\n" + oAipsError.getMesg(),
          "GeoParms", "dumpHDS" ) );
    }
  }
  
  if ( !poHDSFile->there( HDSName( "Longitude" ) ) ) {
    try {
      poHDSFile->screate_double( HDSName( "Longitude" ), dLongitude, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create Longitude HDS object\n" + oAipsError.getMesg(),
          "GeoParms", "dumpHDS" ) );
    }
  }
  
  if ( !poHDSFile->there( HDSName( "TAI-UTC" ) ) ) {
    try {
      poHDSFile->screate_double( HDSName( "TAI-UTC" ), dTAIMinusUTC, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create TAI-UTC object\n" + oAipsError.getMesg(), "GeoParms",
          "dumpHDS" ) );
    }
  }
  
  if ( !poHDSFile->there( HDSName( "TDT-TAI" ) ) ) {
    try {
      poHDSFile->screate_double( HDSName( "TDT-TAI" ), dTDTMinusTAI, True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create TDT-TAI object\n" + oAipsError.getMesg(), "GeoParms",
          "dumpHDS" ) );
    }
  }
  
  
  // Close the HDS file
  
  delete poHDSFile;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

GeoParms::version

Description:
------------
This public member function returns the GeoParms{ } version.

Inputs:
-------
None.

Outputs:
--------
The GeoParms{ } version, returned via the function value.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GeoParms::version( void ) const {

  // Return the GeoParms{ } version
  
  return( String( "0.0" ) );
  
}

// -----------------------------------------------------------------------------

/*

GeoParms::tool

Description:
------------
This public member function returns the glish tool name (must be "geoparms").

Inputs:
-------
None.

Outputs:
--------
The glish tool name, returned via the function value.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GeoParms::tool( void ) const {

  // Return the glish tool name
  
  String oTool = className();
  oTool.downcase();
  
  return( oTool );
  
}

// -----------------------------------------------------------------------------

/*

GeoParms::className

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
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String GeoParms::className( void ) const {

  // Return the class name
  
  return( String( "GeoParms" ) );

}

// -----------------------------------------------------------------------------

/*

GeoParms::methods

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

Vector<String> GeoParms::methods( void ) const {

  // Return the method names
  
  Vector<String> oMethod = Vector<String>( 12 );
  
  oMethod(0) = String( "file" );
  oMethod(1) = String( "altitude" );
  oMethod(2) = String( "earthRadius" );
  oMethod(3) = String( "j2" );
  oMethod(4) = String( "latitude" );
  oMethod(5) = String( "longitude" );
  oMethod(6) = String( "taiMinusUTC" );
  oMethod(7) = String( "tdtMinusTAI" );
  oMethod(8) = String( "dumpHDS" );
  oMethod(9) = String( "id" );
  oMethod(10) = String( "version" );
  oMethod(11) = String( "tool" );
  
  return( oMethod );

}

// -----------------------------------------------------------------------------

/*

GeoParms::noTraceMethods

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
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> GeoParms::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}

// -----------------------------------------------------------------------------

/*

GeoParms::runMethod

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
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult GeoParms::runMethod( uInt uiMethod, ParameterSet &oParameters,
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
          throw( ermsg( "file( ) error\n" + oAipsError.getMesg(), "GeoParms",
              "runMethod" ) );
        }
      }
      break;
    }
  
    // altitude
    case 1: {
      Parameter<Double> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = altitude();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "altitude( ) error\n" + oAipsError.getMesg(),
              "GeoParms", "runMethod" ) );
        }
      }
      break;
    }
  
    // earthRadius
    case 2: {
      Parameter<Double> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = earthRadius();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "earthRadius( ) error\n" + oAipsError.getMesg(),
              "GeoParms", "runMethod" ) );
        }
      }
      break;
    }
  
    // j2
    case 3: {
      Parameter<Double> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = j2();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "j2( ) error\n" + oAipsError.getMesg(), "GeoParms",
              "runMethod" ) );
        }
      }
      break;
    }
  
    // latitude
    case 4: {
      Parameter<Double> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = latitude();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "latitude( ) error\n" + oAipsError.getMesg(),
              "GeoParms", "runMethod" ) );
        }
      }
      break;
    }
  
    // longitude
    case 5: {
      Parameter<Double> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = longitude();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "longitude( ) error\n" + oAipsError.getMesg(),
              "GeoParms", "runMethod" ) );
        }
      }
      break;
    }
  
    // taiMinusUTC
    case 6: {
      Parameter<Double> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = taiMinusUTC();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "taiMinusUTC( ) error\n" + oAipsError.getMesg(),
              "GeoParms", "runMethod" ) );
        }
      }
      break;
    }
  
    // tdtMinusTAI
    case 7: {
      Parameter<Double> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tdtMinusTAI();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tdtMinusTAI( ) error\n" + oAipsError.getMesg(),
              "GeoParms", "runMethod" ) );
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
              "GeoParms", "runMethod" ) );
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
	  throw( ermsg( "id( ) error\n" + oAipsError.getMesg(), "GeoParms",
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
              "GeoParms", "runMethod" ) );
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
          throw( ermsg( "tool( ) error\n" + oAipsError.getMesg(), "GeoParms",
	      "runMethod" ) );
        }
      }
      break;
    }

    // default
    default: {
      if ( bRunMethod ) {
        throw( ermsg( "Invalid GeoParms{ } method", "GeoParms", "runMethod" ) );
      }
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}

// -----------------------------------------------------------------------------

/*

GeoParms::loadHDS

Description:
------------
This private member function loads the geodetic parameters from an HDS file.

Inputs:
-------
oFileIn - The HDS file name.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 25 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void GeoParms::loadHDS( const String& oFileIn ) {
  
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
    throw( ermsg( "Cannot open HDS file\n" + oAipsError.getMesg(), "GeoParms",
        "loadHDS" ) );
  }
  
  
  // Go to the geodetic parameters
  
  try {
    poHDSFile->Goto( "DataSet.GeoParms" );
  }
  
  catch ( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg( "No geodetic parameters\n" + oAipsError.getMesg(),
        "GeoParms", "loadHDS" ) );
  }
  
  
  // Get the geodetic parameters
  
  try {
    dAltitude = Vector<Double>(
        poHDSFile->obtain_double( HDSName( "Altitude" ) ) )(0);  
    dEarthRadius = Vector<Double>(
        poHDSFile->obtain_double( HDSName( "EarthRadius" ) ) )(0);  
    dJ2 = Vector<Double>( poHDSFile->obtain_double( HDSName( "J2" ) ) )(0);  
    dLatitude = Vector<Double>(
        poHDSFile->obtain_double( HDSName( "Latitude" ) ) )(0);  
    dLongitude = Vector<Double>(
        poHDSFile->obtain_double( HDSName( "Longitude" ) ) )(0);  
    dTAIMinusUTC = Vector<Double>(
        poHDSFile->obtain_double( HDSName( "TAI-UTC" ) ) )(0);  
    dTDTMinusTAI = Vector<Double>(
        poHDSFile->obtain_double( HDSName( "TDT-TAI" ) ) )(0);  
  }
  
  catch ( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg( "Cannot load geodetic parameters\n" + oAipsError.getMesg(),
        "GeoParms", "loadHDS" ) );
  }


  // Close the HDS file

  delete poHDSFile;
  
  
  // Return
  
  return;

}
