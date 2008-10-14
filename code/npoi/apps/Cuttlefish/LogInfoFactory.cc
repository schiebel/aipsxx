
// -----------------------------------------------------------------------------

/*

LogInfoFactory.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains LogInfoFactory::make( ) public member function.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              File created with public member function
	      LogInfoFactory::make( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include "LogInfoFactory.h" // LogInfo factory

#include <casa/namespace.h>
// -----------------------------------------------------------------------------

/*

LogInfoFactory::make

Description:
------------
This public member function invokes the constructor of the desired object and
returns the result to aips++/glish.

Inputs:
-------
poObject          - The object name.
oWhichConstructor - The constructor string.
oParamaters       - The parameters.
bMakeObject       - The object make flag. 

Outputs:
--------
A string, returned via the function value.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult LogInfoFactory::make( ApplicationObject*& poObject,
    const String& oWhichConstructor, ParameterSet& oParameters,
    Bool bMakeObject ) {
  
  // Initialize the object and return value

  poObject = NULL;
  
  MethodResult oReturnValue;
  
  
  // Choose the constructor
  
  if ( oWhichConstructor.matches( "LOGINFO" ) ) {
  
    // LogInfo{ } with the standard constructor

    Parameter<String> file( oParameters, "file", ParameterSet::In );
    Parameter<String> name( oParameters, "name", ParameterSet::In );
    Parameter<Bool> readonly( oParameters, "readonly", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        poObject = new LogInfo( file(), name(), readonly() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "LogInfo{ } error\n" + oAipsError.getMesg(), "LogInfoFactory",
            "make" ).getMesg();
      }
    }

  } else {
  
    oReturnValue = GeneralStatus::ermsg(
        "Cannot determine which class/constructor to use", "LogInfoFactory",
        "make" ).getMesg();
  
  }
  
  
  // Check if an object was created
  
  if ( oReturnValue.ok() && bMakeObject && poObject == NULL ) {
    oReturnValue = GeneralStatus::ermsg(
        "Insufficient memory to create a new LogInfo object",
        "LogInfoFactory", "make" ).getMesg();
  }
  

  // Return the return value

  return( oReturnValue );

}
