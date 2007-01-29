//#LogInfo.cc is part of the Cuttlefish server
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
//# $Id: LogInfo.cc,v 19.1 2004/08/25 05:49:26 gvandiep Exp $
// -----------------------------------------------------------------------------

/*

LogInfo.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the LogInfo{ } class member functions.

Public member functions:
------------------------
LogInfo (3 versions), ~LogInfo, append, dumpASCII, dumpHDS, file, log, name,
readOnly, tool, version.

Private member functions:
-------------------------
loadHDS.

Inherited classes (aips++):
---------------------------
ApplicationObject.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              File created with public member functions LogInfo( ) (null,
              standard, and copy versions), ~LogInfo( ), append( ),
              dumpASCII( ), dumpHDS( ), file( ), log( ), name( ), readOnly( ),
              tool( ), and version( ); and private member function loadHDS( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/Cuttlefish/LogInfo.h> // LogInfo file
#include <casa/iostream.h>

// -----------------------------------------------------------------------------

/*

LogInfo::LogInfo (null)

Description:
------------
This public member function constructs a LogInfo{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

LogInfo::LogInfo( void ) {}

// -----------------------------------------------------------------------------

/*

LogInfo::LogInfo

Description:
------------
This public member function constructs a LogInfo{ } object.

Inputs:
-------
oFileIn     - The HDS file name.
oNameIn     - The log name.
bReadOnlyIn - The read-only flag (default = True).

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

LogInfo::LogInfo( const String& oFileIn, const String& oNameIn,
    const Bool& bReadOnlyIn ) {  
  
  // Load log information from the HDS file and initialize this object
  
  try {
    loadHDS( oFileIn, oNameIn, bReadOnlyIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in loadHDS( )\n" + oAipsError.getMesg(), "LogInfo",
        "LogInfo" ) );
  }
  
  
  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

LogInfo::LogInfo (copy)

Description:
------------
This public member function copies a LogInfo{ } object.

Inputs:
-------
oLogInfoIn - The LogInfo{ } object.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

LogInfo::LogInfo( const LogInfo& oLogInfoIn ) {

  // Copy the LogInfo{ } object and return
  
  poFile = new String( oLogInfoIn.file() );
  
  bReadOnly = oLogInfoIn.readOnly();
  
  poLog = new String( oLogInfoIn.log() );
  poName = new String( oLogInfoIn.name() );  
  
  return;

}

// -----------------------------------------------------------------------------

/*

LogInfo::~LogInfo

Description:
------------
This public member function destructs a LogInfo{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

LogInfo::~LogInfo( void ) {

  // Deallocate the memory and return
  
  delete poFile;
  delete poLog;
  delete poName;

  return;

}

// -----------------------------------------------------------------------------

/*

LogInfo::file

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
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String LogInfo::file( void ) const {

  // Return the file name

  return( String( *poFile ) );

}

// -----------------------------------------------------------------------------

/*

LogInfo::name

Description:
------------
This public member function returns the log name.

Inputs:
-------
None.

Outputs:
--------
The log name, returned via the function value.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String LogInfo::name( void ) const {

  // Return the log name

  return( String( *poName ) );

}

// -----------------------------------------------------------------------------

/*

LogInfo::readOnly

Description:
------------
This public member function returns the read-only flag.

Inputs:
-------
None.

Outputs:
--------
The read-only flag, returned via the function value.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool LogInfo::readOnly( void ) const {

  // Return the readOnly flag

  return( bReadOnly );

}

// -----------------------------------------------------------------------------

/*

LogInfo::log

Description:
------------
This public member function returns the log.

Inputs:
-------
None.

Outputs:
--------
The log, returned via the function value.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String LogInfo::log( void ) const {

  // Return the log

  return( String( *poLog ) );

}

// -----------------------------------------------------------------------------

/*

LogInfo::append

Description:
------------
This public member function returns appends the log.

Inputs:
-------
oLine - The new log line.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void LogInfo::append( const String& oLine ) {

  // Appendable?
  
  if ( bReadOnly ) {
    throw( ermsg( "This is a read-only file\n", "LogInfo", "append" ) );
  }
  

  // Append the log and return
  
  (*poLog) += oLine + String( "\n" );
  
  return;

}

// -----------------------------------------------------------------------------

/*

LogInfo::dumpASCII

Description:
------------
This public member function dumps the log information into an ASCII file.

Inputs:
-------
oFileIn - The ASCII file name.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void LogInfo::dumpASCII( const String& oFileIn ) const {

  // Dump the log to the ASCII file and return
  
  String oFile = String( oFileIn );
  oFile.gsub( RXwhite, "" );
  
  ofstream oStream;
  oStream.open( oFile.chars() );
  
  oStream << *poLog << endl << flush;
  
  oStream.close();
  
  return;

}

// -----------------------------------------------------------------------------

/*

LogInfo::dumpHDS

Description:
------------
This public member function dumps the log information into an HDS file.

Inputs:
-------
oFileIn - The HDS file name (default = "" --> the present HDS file name).

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void LogInfo::dumpHDS( const String& oFileIn ) const {

  // Declare/initialize the local variables
  
  String oFile;              // The HDS file
  
  HDSFile* poHDSFile = NULL; // HDSFile{ } object
  

  // Open the HDS file (create it, if necessary)
  
  if ( !oFileIn.matches( RXwhite ) ) {
    oFile = String( oFileIn );
  } else {
    if ( bReadOnly ) {
      throw( ermsg( "Cannot dump log to same file\n", "LogInfo", "dumpHDS" ) );
    }
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
          "LogInfo", "dumpHDS" ) );
    }
    delete poHDSFile;
  }
  
  try {
    poHDSFile = new HDSFile( HDSAccess( oFile, "UPDATE" ) );
  }
  
  catch( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg( "Cannot open HDS file\n" + oAipsError.getMesg(), "LogInfo",
        "dumpHDS" ) );
  }
  
  
  // Dump the log (create it, if necessary)
  
  if ( poLog->length() > 0 ) {
    poHDSFile->screate_char( HDSName( *poName ), poLog->length(), *poLog,
        True );
  }
  
  
  // Close the HDS file
  
  delete poHDSFile;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

LogInfo::version

Description:
------------
This public member function returns the LogInfo{ } version.

Inputs:
-------
None.

Outputs:
--------
The LogInfo{ } version, returned via the function value.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String LogInfo::version( void ) const {

  // Return the LogInfo{ } version
  
  return( String( "0.0" ) );
  
}

// -----------------------------------------------------------------------------

/*

LogInfo::tool

Description:
------------
This public member function returns the glish tool name (must be "loginfo").

Inputs:
-------
None.

Outputs:
--------
The glish tool name, returned via the function value.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String LogInfo::tool( void ) const {

  // Return the glish tool name
  
  String oTool = className();
  oTool.downcase();
  
  return( oTool );
  
}

// -----------------------------------------------------------------------------

/*

LogInfo::className

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
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String LogInfo::className( void ) const {

  // Return the class name
  
  return( String( "LogInfo" ) );

}

// -----------------------------------------------------------------------------

/*

LogInfo::methods

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
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> LogInfo::methods( void ) const {

  // Return the method names
  
  Vector<String> oMethod = Vector<String>( 10 );
  
  oMethod(0) = String( "file" );
  oMethod(1) = String( "name" );
  oMethod(2) = String( "readOnly" );
  oMethod(3) = String( "log" );
  oMethod(4) = String( "append" );
  oMethod(5) = String( "dumpASCII" );
  oMethod(6) = String( "dumpHDS" );
  oMethod(7) = String( "id" );
  oMethod(8) = String( "version" );
  oMethod(9) = String( "tool" );
  
  return( oMethod );

}

// -----------------------------------------------------------------------------

/*

LogInfo::noTraceMethods

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
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> LogInfo::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}

// -----------------------------------------------------------------------------

/*

LogInfo::runMethod

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
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult LogInfo::runMethod( uInt uiMethod, ParameterSet &oParameters,
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
          throw( ermsg( "file( ) error\n" + oAipsError.getMesg(), "LogInfo",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // name
    case 1: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = name();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "name( ) error\n" + oAipsError.getMesg(), "LogInfo",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // readOnly
    case 2: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = readOnly();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "readOnly( ) error\n" + oAipsError.getMesg(), "LogInfo",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // log
    case 3: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = log();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "log( ) error\n" + oAipsError.getMesg(), "LogInfo",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // append
    case 4: {
      Parameter<String> line( oParameters, "line", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          append( line() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "append( ) error\n" + oAipsError.getMesg(), "LogInfo",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // dumpASCII
    case 5: {
      Parameter<String> file( oParameters, "file", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          dumpASCII( file() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "dumpASCII( ) error\n" + oAipsError.getMesg(),
              "LogInfo", "runMethod" ) );
        }
      }
      break;
    }
    
    // dumpHDS
    case 6: {
      Parameter<String> file( oParameters, "file", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          dumpHDS( file() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "dumpHDS( ) error\n" + oAipsError.getMesg(),
              "LogInfo", "runMethod" ) );
        }
      }
      break;
    }
    
    // id    
    case 7: {
      Parameter<ObjectID> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
	  returnval() = id();
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "id( ) error\n" + oAipsError.getMesg(), "LogInfo",
	      "runMethod" ) );
	}
      }
      break;
    }

    // version
    case 8: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = version();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "version( ) error\n" + oAipsError.getMesg(),
              "LogInfo", "runMethod" ) );
        }
      }
      break;
    }

    // tool
    case 9: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tool();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tool( ) error\n" + oAipsError.getMesg(), "LogInfo",
	      "runMethod" ) );
        }
      }
      break;
    }

    // default
    default: {
      if ( bRunMethod ) {
        throw( ermsg( "Invalid LogInfo{ } method", "LogInfo", "runMethod" ) );
      }
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}

// -----------------------------------------------------------------------------

/*

LogInfo::loadHDS

Description:
------------
This private member function loads the log information from an HDS file.

Inputs:
-------
oFileIn     - The HDS file name.
oNameIn     - The log name.
bReadOnlyIn - The read-only flag.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void LogInfo::loadHDS( const String& oFileIn, const String& oNameIn,
    const Bool& bReadOnlyIn ) {
  
  // Declare/initialize the local variables
  
  HDSFile* poHDSFile = NULL; // The HDSFile{ } object
  
  
  // Intialize the private variables
  
  poFile = new String( oFileIn );
  poFile->gsub( RXwhite, "" );
  
  poName = new String( oNameIn );
  poName->gsub( RXwhite, "" );
  poName->upcase();
  
  bReadOnly = bReadOnlyIn;
  

  // Open the HDS file
  
  if ( access( poFile->chars(), F_OK ) != 0 ) {
    if ( !bReadOnly ) {
      try {
        poHDSFile = new HDSFile( HDSAccess( *poFile, "NEW" ),
            HDSName( "DataSet" ), HDSType( "" ), HDSDim() );
      }
      catch ( AipsError oAipsError ) {
        delete poHDSFile;
        throw( ermsg( "Cannot create HDS file\n" + oAipsError.getMesg(),
            "LogInfo", "dumpHDS" ) );
      }
      delete poHDSFile;
    } else {
      throw( ermsg( "No such log, cannot append file\n", "LogFile",
          "loadHDS" ) );
    }
  }
  
  try {
    poHDSFile = new HDSFile( HDSAccess( *poFile, "READ" ) );
  }
  
  catch( AipsError oAipsError ) {
    throw( ermsg( "Cannot open HDS file\n" + oAipsError.getMesg(), "LogInfo",
        "loadHDS" ) );
  }
  
  
  // Get the log information
  
  if ( poHDSFile->there( HDSName( *poName ) ) ) {
  
    try {
      poLog = new String(
          Vector<String>( poHDSFile->obtain_char( HDSName( *poName ) ) )(0) );
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot load log information\n" + oAipsError.getMesg(), "LogInfo",
          "loadHDS" ) );
    }
    
  } else {
  
    poLog = new String();
    
  }


  // Close the HDS file

  delete poHDSFile;
  
  
  // Return
  
  return;

}
