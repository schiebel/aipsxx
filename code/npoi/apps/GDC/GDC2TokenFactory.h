
// -----------------------------------------------------------------------------

/*

GDC2TokenFactory.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the GDC2TokenFactory.cc file.

Modification history:
---------------------
2000 Dec 20 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_GDC2TOKENFACTORY_H
#define NPOI_GDC2TOKENFACTORY_H


// Includes

#include <casa/aips.h>                       // aips++
#include <tasking/Tasking/ApplicationObject.h> // aips++ App...Object class
#include <casa/Exceptions/Error.h>           // aips++ Error classes
#include <tasking/Tasking/MethodResult.h>      // aips++ M...Res definitions
#include <casa/Arrays/Matrix.h>              // aips++ Matrix class
#include <tasking/Tasking/Parameter.h>         // aips++ Parameter class
#include <tasking/Tasking/ParameterSet.h>      // aips++ ParameterSet class
#include <casa/BasicSL/String.h>           // aips++ String class

#include <npoi/HDS/GeneralStatus.h>          // General status

#include <npoi/GDC/GDC2Token.h>              // GDC2Token


#include <casa/namespace.h>
// Class definition

//class String;
//class ParameterSet;
//class MethodResult;

class GDC2TokenFactory : public ApplicationObjectFactory {

    virtual MethodResult make( ApplicationObject*& poObject,
        const String& oWhichConstructor, ParameterSet& oParameters,
        Bool bMakeObject );
			    
};


// #endif (Include file?)

#endif // __GDC2TOKENFACTORY_H
