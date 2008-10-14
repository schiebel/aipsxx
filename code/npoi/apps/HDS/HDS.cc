
// -----------------------------------------------------------------------------

/*

HDS.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the main( ) function which starts the HDS aips++ client.

Functions:
----------
main.

Modification history:
---------------------
2000 Apr 28 - Nicholas Elias, USNO/NPOI
              File created with function main( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include "HDS.h" // HDS

#include <casa/namespace.h>
// -----------------------------------------------------------------------------

/*

main

Description:
------------
This function starts the HDS aips++ client.

Inputs:
-------
iArgC  - The number of arguments.
acArgV - The arguments.

Outputs:
--------
None.

Modification history:
---------------------
2000 Apr 28 - Nicholas Elias, USNO/NPOI
              Function created.

*/

// -----------------------------------------------------------------------------

int main( int iArgC, char* acArgV[] ) {

  // Create an object of the ObjectController{ } class

  ObjectController HDS( iArgC, acArgV );


  // Register all the HDS classes

  HDS.addMaker( "HDSFile", new HDSFactory );


  // Begin the loop

  HDS.loop();


  // Return 0

  return( 0 );

}
