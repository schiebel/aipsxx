
// -----------------------------------------------------------------------------

/*

GDC.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the main( ) function which starts the GDC aips++ client.

Functions:
----------
main.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              File created with function main( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include "GDC.h" // GDC

#include <casa/namespace.h>
// -----------------------------------------------------------------------------

/*

main

Description:
------------
This function starts the GDC aips++ client.

Inputs:
-------
iArgC  - The number of arguments.
acArgV - The arguments.

Outputs:
--------
None.

Modification history:
---------------------
2000 May 01 - Nicholas Elias, USNO/NPOI
              Function created.

*/

// -----------------------------------------------------------------------------

int main( int iArgC, char* acArgV[] ) {

  // Register the PGPlotter creator.
  ApplicationEnvironment::registerPGPlotter();

  // Create an object of the ObjectController{ } class

  ObjectController GDC( iArgC, acArgV );


  // Register all the GDC classes

  GDC.addMaker( "GDC1", new GDC1Factory );
  GDC.addMaker( "GDC1Token", new GDC1TokenFactory );
  GDC.addMaker( "GDC2Token", new GDC2TokenFactory );


  // Begin the loop

  GDC.loop();


  // Return 0

  return( 0 );

}
