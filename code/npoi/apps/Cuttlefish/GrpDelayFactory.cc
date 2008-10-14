
// -----------------------------------------------------------------------------

/*

GrpDelayFactory.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains GrpDelayFactory::make( ) public member function.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              File created with public member function
	      GrpDelayFactory::make( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include "GrpDelayFactory.h" // GrpDelay factory

#include <casa/namespace.h>
// -----------------------------------------------------------------------------

/*

GrpDelayFactory::make

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
2001 May 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult GrpDelayFactory::make( ApplicationObject*& poObject,
    const String& oWhichConstructor, ParameterSet& oParameters,
    Bool bMakeObject ) {
  
  // Initialize the object and return value

  poObject = NULL;
  
  MethodResult oReturnValue;
  
  
  // Choose the constructor

  if ( oWhichConstructor.matches( "GRPDELAY" ) ) {
  
    // GrpDelay{ } with the standard constructor

    Parameter<String> file( oParameters, "file", ParameterSet::In );
    Parameter<Int> inputbeam( oParameters, "inputbeam", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        poObject = new GrpDelay( file(), (uInt) inputbeam() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "GrpDelay{ } error\n" + oAipsError.getMesg(), "GrpDelayFactory",
            "make" ).getMesg();
      }
    }

  } else if ( oWhichConstructor.matches( "GRPDELAY_AVERAGE" ) ) {

    // GrpDelay{ } with the average constructor

    Parameter<ObjectID> objectid( oParameters, "objectid", ParameterSet::In );
    Parameter< Vector<Double> > x( oParameters, "x", ParameterSet::In );
    Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
    Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
    Parameter< Vector<String> > token( oParameters, "token", ParameterSet::In );
    Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
    Parameter<Bool> weight( oParameters, "weight", ParameterSet::In );
    Parameter<Bool> xcalc( oParameters, "xcalc", ParameterSet::In );
    Parameter<String> interp( oParameters, "interp", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        poObject = new GrpDelay( objectid(), x(), xmin(), xmax(), token(),
            keep(), weight(), xcalc(), interp() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "GrpDelay{ } error\n" + oAipsError.getMesg(), "GrpDelayFactory",
            "make" ).getMesg();
      }
    }

  } else if ( oWhichConstructor.matches( "GRPDELAY_CLONE" ) ) {

    // GrpDelay{ } with the clone constructor

    Parameter<ObjectID> objectid( oParameters, "objectid", ParameterSet::In );
    Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
    Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
    Parameter< Vector<String> > token( oParameters, "token", ParameterSet::In );
    Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        poObject = new GrpDelay( objectid(), xmin(), xmax(), token(), keep() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "GrpDelay{ } error\n" + oAipsError.getMesg(), "GrpDelayFactory",
            "make" ).getMesg();
      }
    }

  } else if ( oWhichConstructor.matches( "GRPDELAY_INTERPOLATE" ) ) {

    // GrpDelay{ } with the interpolate constructor

    Parameter<ObjectID> objectid( oParameters, "objectid", ParameterSet::In );
    Parameter< Vector<Double> > x( oParameters, "x", ParameterSet::In );
    Parameter< Vector<String> > token( oParameters, "token", ParameterSet::In );
    Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
    Parameter<String> interp( oParameters, "interp", ParameterSet::In );
    Parameter<Double> xminbox( oParameters, "xminbox", ParameterSet::In );
    Parameter<Double> xmaxbox( oParameters, "xmaxbox", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        poObject = new GrpDelay( objectid(), x(), token(), keep(), interp(),
            xminbox(), xmaxbox() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "GrpDelay{ } error\n" + oAipsError.getMesg(), "GrpDelayFactory",
            "make" ).getMesg();
      }
    }

  } else {
  
    oReturnValue = GeneralStatus::ermsg(
        "Cannot determine which class/constructor to use ", "GrpDelayFactory",
        "make" ).getMesg();
  
  }
  
  
  // Check if an object was created
  
  if ( oReturnValue.ok() && bMakeObject && poObject == NULL ) {
    oReturnValue = GeneralStatus::ermsg(
        "Insufficient memory to create a new GrpDelay object", "GrpDelayFactory",
        "make" ).getMesg();
  }
  

  // Return the return value

  return( oReturnValue );

}
