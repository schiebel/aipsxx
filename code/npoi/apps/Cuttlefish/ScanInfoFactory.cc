
// -----------------------------------------------------------------------------

/*

ScanInfoFactory.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains ScanInfoFactory::make( ) public member function.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              File created with public member function
	      ScanInfoFactory::make( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include "ScanInfoFactory.h" // ScanInfo factory

#include <casa/namespace.h>
// -----------------------------------------------------------------------------

/*

ScanInfoFactory::make

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
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult ScanInfoFactory::make( ApplicationObject*& poObject,
    const String& oWhichConstructor, ParameterSet& oParameters,
    Bool bMakeObject ) {
  
  // Initialize the object and return value

  poObject = NULL;
  
  MethodResult oReturnValue;
  
  
  // Choose the constructor
  
  if ( oWhichConstructor.matches( "SCANINFO" ) ) {
  
    // ScanInfo{ } with the standard constructor

    Parameter<String> file( oParameters, "file", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        poObject = new ScanInfo( file() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "ScanInfo{ } error\n" + oAipsError.getMesg(), "ScanInfoFactory",
            "make" ).getMesg();
      }
    }
  
  } else if ( oWhichConstructor.matches( "SCANINFO_DERIVED" ) ) {
  
    // ScanInfo{ } with the derived constructor

    Parameter<String> file( oParameters, "file", ParameterSet::In );
    Parameter< Vector<Int> > scanid( oParameters, "scanid", ParameterSet::In );
    Parameter< Vector<String> >
        starid( oParameters, "starid", ParameterSet::In );
    Parameter< Vector<Double> >
        scantime( oParameters, "scantime", ParameterSet::In );
    Parameter< Vector<Double> > ra( oParameters, "ra", ParameterSet::In );
    Parameter< Vector<Double> > dec( oParameters, "dec", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        poObject = new ScanInfo( file(), scanid(), starid(), scantime(), ra(),
            dec() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "ScanInfo{ } error\n" + oAipsError.getMesg(), "ScanInfoFactory",
            "make" ).getMesg();
      }
    }

  } else {
  
    oReturnValue = GeneralStatus::ermsg(
        "Cannot determine which class/constructor to use", "ScanInfoFactory",
        "make" ).getMesg();
  
  }
  
  
  // Check if an object was created
  
  if ( oReturnValue.ok() && bMakeObject && poObject == NULL ) {
    oReturnValue = GeneralStatus::ermsg(
        "Insufficient memory to create a new ScanInfo object",
        "ScanInfoFactory", "make" ).getMesg();
  }
  

  // Return the return value

  return( oReturnValue );

}
