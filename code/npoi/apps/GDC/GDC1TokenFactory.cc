
// -----------------------------------------------------------------------------

/*

GDC1TokenFactory.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains GDC1TokenFactory::make( ) public member function.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              File created with public member function
              GDC1TokenFactory::make( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include "GDC1TokenFactory.h" // GDC1Token factory

#include <casa/namespace.h>
// -----------------------------------------------------------------------------

/*

GDC1TokenFactory::make

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
2000 May 01 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult GDC1TokenFactory::make( ApplicationObject*& poObject,
    const String& oWhichConstructor, ParameterSet& oParameters,
    Bool bMakeObject ) {
  
  // Initialize the object and return value

  poObject = NULL;
  
  MethodResult oReturnValue;
  
  
  // Choose the constructor
  
  if ( oWhichConstructor.matches( "GDC1TOKEN" ) ) {
  
    // GDC1Token{ } with the standard constructor
    
    Parameter< Vector<Double> > x( oParameters, "x", ParameterSet::In );
    Parameter< Vector<Double> > y( oParameters, "y", ParameterSet::In );
    Parameter< Vector<Double> > xerr( oParameters, "xerr", ParameterSet::In );
    Parameter< Vector<Double> > yerr( oParameters, "yerr", ParameterSet::In );
    Parameter< Vector<String> > token( oParameters, "token", ParameterSet::In );
    Parameter< Vector<Bool> > flag( oParameters, "flag", ParameterSet::In );
    Parameter<String> tokentype( oParameters, "tokentype", ParameterSet::In );
    Parameter<Bool> hms( oParameters, "hms", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        poObject = new GDC1Token( x(), y(), xerr(), yerr(), token(), flag(),
            tokentype(), hms() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "GDC1Token{ } error\n" + oAipsError.getMesg(), "GDC1TokenFactory",
            "make" ).getMesg();
      }
    }

  } else if ( oWhichConstructor.matches( "GDC1TOKEN_ASCII" ) ) {

    // GDC1Token{ } with the ASCII constructor

    Parameter<String> file( oParameters, "file", ParameterSet::In );
    Parameter<String> tokentype( oParameters, "tokentype", ParameterSet::In );
    Parameter<Bool> hms( oParameters, "hms", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        poObject = new GDC1Token( file(), tokentype(), hms() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "GDC1Token{ } error\n" + oAipsError.getMesg(), "GDC1TokenFactory",
            "make" ).getMesg();
      }
    }

  } else if ( oWhichConstructor.matches( "GDC1TOKEN_CLONE" ) ) {

    // GDC1Token{ } with the clone constructor

    Parameter<ObjectID> objectid( oParameters, "objectid", ParameterSet::In );
    Parameter<Double> xmin( oParameters, "xmin", ParameterSet::In );
    Parameter<Double> xmax( oParameters, "xmax", ParameterSet::In );
    Parameter< Vector<String> > token( oParameters, "token", ParameterSet::In );
    Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        poObject = new GDC1Token( objectid(), xmin(), xmax(), token(), keep() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "GDC1Token{ } error\n" + oAipsError.getMesg(), "GDC1TokenFactory",
            "make" ).getMesg();
      }
    }

  } else if ( oWhichConstructor.matches( "GDC1TOKEN_AVERAGE" ) ) {

    // GDC1Token{ } with the average constructor

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
        poObject = new GDC1Token( objectid(), x(), xmin(), xmax(), token(),
            keep(), weight(), xcalc(), interp() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "GDC1Token{ } error\n" + oAipsError.getMesg(), "GDC1TokenFactory",
            "make" ).getMesg();
      }
    }

  } else if ( oWhichConstructor.matches( "GDC1TOKEN_INTERPOLATE" ) ) {

    // GDC1Token{ } with the interpolate constructor

    Parameter<ObjectID> objectid( oParameters, "objectid", ParameterSet::In );
    Parameter< Vector<Double> > x( oParameters, "x", ParameterSet::In );
    Parameter< Vector<String> > token( oParameters, "token", ParameterSet::In );
    Parameter<Bool> keep( oParameters, "keep", ParameterSet::In );
    Parameter<String> interp( oParameters, "interp", ParameterSet::In );
    Parameter<Double> xminbox( oParameters, "xminbox", ParameterSet::In );
    Parameter<Double> xmaxbox( oParameters, "xmaxbox", ParameterSet::In );
    
    if ( bMakeObject ) {
      try {
        poObject = new GDC1Token( objectid(), x(), token(), keep(), interp(),
            xminbox(), xmaxbox() );
      }
      catch ( AipsError oAipsError ) {
        if ( poObject != NULL ) {
          delete poObject;
        }
        oReturnValue = GeneralStatus::ermsg(
            "GDC1Token{ } error\n" + oAipsError.getMesg(), "GDC1TokenFactory",
            "make" ).getMesg();
      }
    }
  
  } else {
  
    oReturnValue = GeneralStatus::ermsg(
        "Cannot determine which class/constructor to use", "GDC1TokenFactory",
        "make" ).getMesg();
  
  }
  
  
  // Check if a GDC{ } object was created
  
  if ( oReturnValue.ok() && bMakeObject && poObject == NULL ) {
    oReturnValue = GeneralStatus::ermsg(
        "Insufficient memory to create a new GDC object", "GDC1TokenFactory",
        "make" ).getMesg();
  }
  

  // Return the return value

  return( oReturnValue );

}
