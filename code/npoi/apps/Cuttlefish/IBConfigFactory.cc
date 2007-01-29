
// -----------------------------------------------------------------------------

/*

IBConfigFactory.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains IBConfigFactory::make( ) public member function.

Modification history:
---------------------
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              File created with public member function
	      IBConfigFactory::make( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include "IBConfigFactory.h" // IBConfig factory

#include <casa/namespace.h>
// -----------------------------------------------------------------------------

/*

IBConfigFactory::make

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
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult IBConfigFactory::make( ApplicationObject*& poObject,
    const String& oWhichConstructor, ParameterSet& oParameters,
    Bool bMakeObject ) {
  
  // Initialize the object and return value

  poObject = NULL;
  
  MethodResult oReturnValue;
  
  
  // Choose the constructor
  
  if ( oWhichConstructor.matches( "IBCONFIG" ) ) {
  
    // IBConfig{ } with the standard constructor

    Parameter<String> file( oParameters, "file", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        poObject = new IBConfig( file() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "IBConfig{ } error\n" + oAipsError.getMesg(), "IBConfigFactory",
            "make" ).getMesg();
      }
    }

  } else {
  
    oReturnValue = GeneralStatus::ermsg(
        "Cannot determine which class/constructor to use", "IBConfigFactory",
        "make" ).getMesg();
  
  }
  
  
  // Check if an object was created
  
  if ( oReturnValue.ok() && bMakeObject && poObject == NULL ) {
    oReturnValue = GeneralStatus::ermsg(
        "Insufficient memory to create a new IBConfig object",
        "IBConfigFactory", "make" ).getMesg();
  }
  

  // Return the return value

  return( oReturnValue );

}
