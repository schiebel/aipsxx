
// -----------------------------------------------------------------------------

/*

Cuttlefish.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the main( ) function which starts the Cuttlefish aips++
client.

Functions:
----------
main.

Modification history:
---------------------
1999 Jan 28 - Nicholas Elias, USNO/NPOI
              File created with function main( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include "Cuttlefish.h" // Cuttlefish

#include <casa/namespace.h>
// -----------------------------------------------------------------------------

/*

main

Description:
------------
This function starts the Cuttlefish aips++ client.

Inputs:
-------
iArgC  - The number of arguments.
acArgV - The arguments.

Outputs:
--------
None.

Modification history:
---------------------
1999 Jan 28 - Nicholas Elias, USNO/NPOI
              Function created.

*/

// -----------------------------------------------------------------------------

int main( int iArgC, char* acArgV[] ) {

  // Register the PGPlotter creator.
  ApplicationEnvironment::registerPGPlotter();

  // Create an object of the ObjectController{ } class

  ObjectController Cuttlefish( iArgC, acArgV );


  // Register all of the Cuttlefish classes

  Cuttlefish.addMaker( "DelayJitter", new DelayJitterFactory );
  Cuttlefish.addMaker( "DryDelay", new DryDelayFactory );
  Cuttlefish.addMaker( "FDLPos", new FDLPosFactory );
  Cuttlefish.addMaker( "GeoParms", new GeoParmsFactory );
  Cuttlefish.addMaker( "GrpDelay", new GrpDelayFactory );
  Cuttlefish.addMaker( "IBConfig", new IBConfigFactory );
  Cuttlefish.addMaker( "LogInfo", new LogInfoFactory );
  Cuttlefish.addMaker( "NATJitter", new NATJitterFactory );
  Cuttlefish.addMaker( "OBConfig", new OBConfigFactory );
  Cuttlefish.addMaker( "ScanInfo", new ScanInfoFactory );
  Cuttlefish.addMaker( "SysConfig", new SysConfigFactory );
  Cuttlefish.addMaker( "WetDelay", new WetDelayFactory );


  // Begin the loop

  Cuttlefish.loop();


  // Return 0

  return( 0 );

}
