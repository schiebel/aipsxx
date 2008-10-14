
// -----------------------------------------------------------------------------

/*

HDSFactory.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains HDSFactory::make( ) public member function.

Modification history:
---------------------
2000 Apr 28 - Nicholas Elias, USNO/NPOI
              File created with public member function HDSFactory::make( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include "HDSFactory.h" // HDS factory

#include <casa/namespace.h>
// -----------------------------------------------------------------------------

/*

HDSFactory::make

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
2000 Apr 28 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult HDSFactory::make( ApplicationObject*& poObject,
    const String& oWhichConstructor, ParameterSet& oParameters,
    Bool bMakeObject ) {
  
  // Initialize the object and return value

  poObject = NULL;
  
  MethodResult oReturnValue;
  
  
  // Choose the constructor
  
  if ( oWhichConstructor.matches( "HDSNEW" ) ) {
  
    // HDSFile{ } with the hds_new() constructor

    Parameter<String> file( oParameters, "file", ParameterSet::In );
    Parameter<String> mode( oParameters, "mode", ParameterSet::In );
    Parameter<String> name( oParameters, "name", ParameterSet::In );
    Parameter<String> type( oParameters, "type", ParameterSet::In );
    Parameter< Vector<Int> > dims( oParameters, "dims", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        HDSAccess oAccess = HDSAccess( file(), mode() );
        HDSName oName = HDSName( name() );
        HDSType oType = HDSType( type() );
        HDSDim oDims = HDSDim( dims() );
        poObject = new HDSFile( oAccess, oName, oType, oDims );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "HDSFile{ } error\n" + oAipsError.getMesg(), "HDSFactory",
            "make" ).getMesg();
      }
    }
  
  } else if ( oWhichConstructor.matches( "HDSOPEN" ) ) {
  
    // HDSFile{ } with the hds_open() constructor

    Parameter<String> file( oParameters, "file", ParameterSet::In );
    Parameter<String> mode( oParameters, "mode", ParameterSet::In );

    if ( bMakeObject ) {
      try {
        poObject = new HDSFile( HDSAccess( file(), mode() ) );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "HDSFile{ } error\n" + oAipsError.getMesg(), "HDSFactory",
            "make" ).getMesg();
      }
    }
  
  } else {
  
    oReturnValue = GeneralStatus::ermsg(
        "Cannot determine which class/constructor to use", "HDSFactory",
        "make" ).getMesg();
  
  }
  
  
  // Check if an HDSFile{ } object was created
  
  if ( oReturnValue.ok() && bMakeObject && poObject == NULL ) {
    oReturnValue = GeneralStatus::ermsg(
        "Insufficient memory to create a new HDS object", "HDSFactory",
        "make" ).getMesg();
  }
  

  // Return the return value

  return( oReturnValue );

}
