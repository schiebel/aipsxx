
// -----------------------------------------------------------------------------

/*

IBConfigFactory.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the IBConfigFactory.cc file.

Modification history:
---------------------
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_IBCONFIGFACTORY_H
#define NPOI_IBCONFIGFACTORY_H


// Includes

#include <casa/aips.h>                       // aips++
#include <tasking/Tasking/ApplicationObject.h> // aips++ App...Object class
#include <casa/Exceptions/Error.h>           // aips++ Error classes
#include <tasking/Tasking/MethodResult.h>      // aips++ M...Res definitions
#include <tasking/Tasking/ParameterSet.h>      // aips++ ParameterSet class
#include <tasking/Tasking/Parameter.h>         // aips++ Parameter class
#include <casa/BasicSL/String.h>           // aips++ String class

#include <npoi/Cuttlefish/IBConfig.h>        // IBConfig class


#include <casa/namespace.h>
// Class definition

//class String;
//class ParameterSet;
//class MethodResult;

class IBConfigFactory : public ApplicationObjectFactory {

    virtual MethodResult make( ApplicationObject*& poObject,
        const String& oWhichConstructor, ParameterSet& oParameters,
        Bool bMakeObject );
			    
};


// #endif (Include file?)

#endif // __IBCONFIGFACTORY_H
