//#ScanInfo.cc is part of the Cuttlefish server
//#Copyright (C) 2000,2001
//#United States Naval Observatory; Washington, DC; USA.
//#
//#This library is free software; you can redistribute it and/or modify it
//#under the terms of the GNU Library General Public License as published by
//#the Free Software Foundation; either version 2 of the License, or (at your
//#option) any later version.
//#
//#This library is designed for use only in AIPS++ (National Radio Astronomy
//#Observatory; Charlottesville, VA; USA) in the hope that it will be useful, but
//#WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//#FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//#License for more details.
//#
//#You should have received a copy of the GNU Library General Public License
//#along with this library; if not, write to the Free Software Foundation,
//#Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//#Correspondence concerning the Cuttlefish server should be addressed as follows:
//#       Internet email: nme@nofs.navy.mil
//#       Postal address: Dr. Nicholas Elias
//#                       United States Naval Observatory
//#                       Navy Prototype Optical Interferometer
//#                       P.O. Box 1149
//#                       Flagstaff, AZ 86002-1149 USA
//#
//#Correspondence concerning AIPS++ should be addressed as follows:
//#       Internet email: aips2-request@nrao.edu.
//#       Postal address: AIPS++ Project Office
//#                       National Radio Astronomy Observatory
//#                       520 Edgemont Road
//#                       Charlottesville, VA 22903-2475 USA
//#
//# $Id: ScanInfo.cc,v 19.0 2003/07/16 06:02:19 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

ScanInfo.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the ScanInfo{ } class member functions.

Public member functions:
------------------------
ScanInfo (4 versions), ~ScanInfo, addStarID, checkScan, checkStarID, DEC,
derived, dumpASCII, dumpHDS, file, getStarID, length, numScan, RA, removeStarID,
setStarID, setStarIDDefault, scan, scanID, scanTime, starID, starList,
starValid, timeScan, tool, version.

Private member functions:
-------------------------
checkScan, checkStarID, loadHDS.

Inherited classes (aips++):
---------------------------
ApplicationObject.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              File created with public member functions ScanInfo( ) (null,
              HDS, and copy versions), ~ScanInfo( ), DEC( ), dumpASCII( ),
              dumpHDS( ), file( ), length( ), numScan( ), RA( ), scan( ),
              scanID( ), scanTime( ), starID( ), starList( ), starValid( ),
              tool( ), version( ); and private member functions checkScan( ),
              checkStarID( ), and loadHDS( ).
2000 Aug 22 - Nicholas Elias, USNO/NPOI
              Public member functions addStarID( ), checkScan( ),
              checkStarID( ), getStarID( ), removeStarID( ), setStarID( ), and
              setStarIDDefault( ) added.
2001 Mar 20 - Nicholas Elias, USNO/NPOI
              uiStartScanIn, uiStopScanIn, and oStarIDIn arguments added to
              dumpHDS( ).  Public member function timeScan( ) added.
2001 Mar 28 - Nicholas Elias, USNO/NPOI
              Public member functions ScanInfo( ) (derived version) and
              derived( ) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/Cuttlefish/ScanInfo.h> // ScanInfo file

// -----------------------------------------------------------------------------

/*

ScanInfo::ScanInfo (null)

Description:
------------
This public member function constructs a ScanInfo{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

ScanInfo::ScanInfo( void ) {}

// -----------------------------------------------------------------------------

/*

ScanInfo::ScanInfo (HDS)

Description:
------------
This public member function constructs a ScanInfo{ } object.

Inputs:
-------
oFileIn - The file name.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

ScanInfo::ScanInfo( const String& oFileIn ) {

  // Initialize some objects
  
  bDerived = False;

  poFile = new String( oFileIn );
  
  Vector<Int>* poScanIDTemp = new Vector<Int>();
  Vector<String>* poStarIDTemp = new Vector<String>();
  Vector<Double>* poScanTimeTemp = new Vector<Double>();
  Vector<Double>* poRATemp = new Vector<Double>();
  Vector<Double>* poDECTemp = new Vector<Double>();

  
  // Load scan information from the HDS file
  
  try {
    loadHDS( oFileIn, *poScanIDTemp, *poStarIDTemp, *poScanTimeTemp, *poRATemp,
        *poDECTemp );
  }
  
  catch ( AipsError oAipsError ) {
    delete poScanIDTemp;
    delete poStarIDTemp;
    delete poScanTimeTemp;
    delete poRATemp;
    delete poDECTemp;
    throw( ermsg( "Error in loadHDS( )\n" + oAipsError.getMesg(), "ScanInfo",
        "ScanInfo" ) );
  }
  
  
  // Initialize the private variables
 
  try {
    initialize( *poScanIDTemp, *poStarIDTemp, *poScanTimeTemp, *poRATemp,
        *poDECTemp );
  }

  catch ( AipsError oAipsError ) {
    delete poScanIDTemp;
    delete poStarIDTemp;
    delete poScanTimeTemp;
    delete poRATemp;
    delete poDECTemp;
    throw( ermsg( "Cannot create ScanData{ } object\n" + oAipsError.getMesg(),
        "ScanData", "ScanData" ) );
  }
  
  
  // Deallocate the memory
  
  delete poScanIDTemp;
  delete poStarIDTemp;
  delete poScanTimeTemp;
  delete poRATemp;
  delete poDECTemp;
 
  
  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

ScanInfo::ScanInfo (derived)

Description:
------------
This public member function constructs a ScanInfo{ } object.

Inputs:
-------
oFileIn     - The file name.
oScanIDIn   - The scan IDs.
oStarIDIn   - The star IDs.
oScanTimeIn - The scan times.
oRAIn       - The right ascensions.
oDECIn      - The declinations.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

ScanInfo::ScanInfo( String& oFileIn, const Vector<Int>& oScanIDIn,
    const Vector<String>& oStarIDIn, const Vector<Double>& oScanTimeIn,
    const Vector<Double>& oRAIn, const Vector<Double>& oDECIn ) {

  // Initialize the object

  bDerived = True;
  
  oFileIn.gsub( RXwhite, "" );
  poFile = new String( oFileIn );
 
  try {
    initialize( oScanIDIn, oStarIDIn, oScanTimeIn, oRAIn, oDECIn );
  }

  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot create ScanData{ } object\n" + oAipsError.getMesg(),
        "ScanData", "ScanData" ) );
  }

  
  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

ScanInfo::ScanInfo (copy)

Description:
------------
This public member function copies a ScanInfo{ } object.

Inputs:
-------
oScanInfoIn - The ScanInfo{ } object.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

ScanInfo::ScanInfo( const ScanInfo& oScanInfoIn ) {

  // Declare/initialize the local variables
  
  uInt uiScan;                                     // The scan counter
  uInt uiStartScan;                                // The start scan
  uInt uiStopScan;                                 // The stop scan
  
  String oType = "";                               // The GDC1Token{ } type
 
  Vector<Double> oNullD = Vector<Double>();        // A null Double vector
  Vector<Bool> oNullB = Vector<Bool>();            // A null Bool vector


  // Copy the ScanInfo{ } object and return
  
  bDerived = oScanInfoIn.derived();

  poFile = new String( oScanInfoIn.file() );
  
  uiNumScan = oScanInfoIn.numScan();
  
  uiStartScan = 1;
  uiStopScan = uiNumScan;

  Vector<String> oStarIDList = oScanInfoIn.starList();
  
  Vector<Int> oScanInt =
      oScanInfoIn.scan( uiStartScan, uiStopScan, oStarIDList );
  Vector<Int> oScanIDInt =
      oScanInfoIn.scanID( uiStartScan, uiStopScan, oStarIDList );
  
  Vector<Double> oScan = Vector<Double>( uiNumScan );
  Vector<Double> oScanID = Vector<Double>( uiNumScan );
  
  for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
    oScan(uiScan) = (Double) oScanInt(uiScan);
    oScanID(uiScan) = (Double) oScanIDInt(uiScan);
  }
  
  Vector<Double> oScanTime =
      oScanInfoIn.scanTime( uiStartScan, uiStopScan, oStarIDList );
  Vector<Double> oRA = oScanInfoIn.RA( uiStartScan, uiStopScan, oStarIDList );
  Vector<Double> oDEC = oScanInfoIn.DEC( uiStartScan, uiStopScan, oStarIDList );

  Vector<String> oStarID = oScanInfoIn.starID( uiStartScan, uiStopScan,
      oStarIDList );
  
  poScan = new GDC1Token( oScan, oScanID, oNullD, oNullD, oStarID, oNullB,
     oType );
  poScanTime = new GDC1Token( oScan, oScanTime, oNullD, oNullD, oStarID,
      oNullB, oType );
  poRA = new GDC1Token( oScan, oRA, oNullD, oNullD, oStarID, oNullB, oType );
  poDEC = new GDC1Token( oScan, oDEC, oNullD, oNullD, oStarID, oNullB, oType );
  
  return;

}

// -----------------------------------------------------------------------------

/*

ScanInfo::~ScanInfo

Description:
------------
This public member function destructs an ScanInfo{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

ScanInfo::~ScanInfo( void ) {

  // Deallocate the memory and return
  
  delete poFile;
  
  delete poScan;
  delete poScanTime;
  delete poRA;
  delete poDEC;

  return;

}

// -----------------------------------------------------------------------------

/*

ScanInfo::derived

Description:
------------
This public member function returns the derived-from-file boolean.

Inputs:
-------
None.

Outputs:
--------
The derived-from-file boolean, returned via the function value.

Modification history:
---------------------
2001 Mar 28 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool ScanInfo::derived( void ) const {

  // Return the derived-from-file

  return( bDerived );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::file

Description:
------------
This public member function returns the file name.

Inputs:
-------
None.

Outputs:
--------
The file name, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String ScanInfo::file( void ) const {

  // Return the file name

  return( String( *poFile ) );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::numScan

Description:
------------
This public member function returns the number of scans.

Inputs:
-------
None.

Outputs:
--------
The number of scans, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt ScanInfo::numScan( void ) const {

  // Return the number of scans

  return( uiNumScan );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::length

Description:
------------
This public member function returns the number of scans, given the scan range
and star IDs.

Inputs:
-------
uiStartScanIn - The start scan.
uiStopScanIn  - The stop scan.
oStarIDIn     - The star IDs.

Outputs:
--------
The number of scans, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt ScanInfo::length( uInt& uiStartScanIn, uInt& uiStopScanIn,
    Vector<String>& oStarIDIn ) const {  
  
  // Return the number of scans

  return( scan( uiStartScanIn, uiStopScanIn, oStarIDIn ).nelements() );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::scan

Description:
------------
This public member function returns the scans.

Inputs:
-------
uiStartScanIn - The start scan.
uiStopScanIn  - The stop scan.
oStarIDIn     - The star IDs.

Outputs:
--------
The scans, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> ScanInfo::scan( uInt& uiStartScanIn, uInt& uiStopScanIn,
    Vector<String>& oStarIDIn ) const {
  
  // Declare the local variables
  
  uInt uiNumScanTemp; // The temporary number of scans
  uInt uiScan;        // The scan counter
  
  Double dStartScan;  // The Double version of the start scan.
  Double dStopScan;   // The Double version of the stop scan.
  

  // Check the inputs
  
  if ( !checkScan( uiStartScanIn, uiStopScanIn ) ) {
    throw( ermsg( "Invalid start and/or stop scan", "ScanInfo", "scan" ) );
  }
  
  if ( !checkStarID( oStarIDIn ) ) {
    throw( ermsg( "Invalid star ID(s)", "ScanInfo", "scan" ) );
  }
  

  // Return the scans
  
  dStartScan = (Double) uiStartScanIn;
  dStopScan = (Double) uiStopScanIn;

  Vector<Double> oScanDouble =
      poScan->x( dStartScan, dStopScan, oStarIDIn, True );
  
  uiNumScanTemp = oScanDouble.nelements();
  
  Vector<Int> oScanInt = Vector<Int>( uiNumScanTemp );
  
  for ( uiScan = 0; uiScan < uiNumScanTemp; uiScan++ ) {
    oScanInt(uiScan) = (Int) oScanDouble(uiScan);
  }
  
  return( oScanInt );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::timeScan

Description:
------------
This public member function returns the scans given the start and stop times.

Inputs:
-------
dStartTimeIn - The start time.
dStopTimeIn  - The stop time.
oStarIDIn    - The star IDs.

Outputs:
--------
The scans, returned via the function value.

Modification history:
---------------------
2001 Mar 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> ScanInfo::timeScan( Double& dStartTimeIn, Double& dStopTimeIn,
    Vector<String>& oStarIDIn ) const {

  // Declare the local variables

  uInt uiNumScanTemp; // The temporary number of scans 
  uInt uiScan;        // The scan counter
  
  Double dStartScan;  // The Double version of the start scan.
  Double dStopScan;   // The Double version of the stop scan.


  // Check the inputs
  
  if ( dStartTimeIn < 0.0 ) {
    throw( ermsg( "Invalid start time", "ScanInfo", "timeScan" ) );
  }
  
  if ( dStopTimeIn < 0.0 ) {
    throw( ermsg( "Invalid stop time", "ScanInfo", "timeScan" ) );
  }
  
  if ( dStartTimeIn > dStopTimeIn ) {
    throw( ermsg( "Invalid start and/or stop time", "ScanInfo", "timeScan" ) );
  }
  
  if ( !checkStarID( oStarIDIn ) ) {
    throw( ermsg( "Invalid star ID(s)", "ScanInfo", "timeScan" ) );
  }


  // Get the start and stop scans

  dStartScan = 1.0;
  dStopScan = (Double) uiNumScan;

  Vector<Double> oScanTemp =
      poScanTime->x( dStartScan, dStopScan, oStarIDIn, True );
  Vector<Double> oScanTime =
      poScanTime->y( dStartScan, dStopScan, oStarIDIn, True, True );

  uiNumScanTemp = oScanTemp.nelements();
  
  for ( uiScan = 0; uiScan < uiNumScanTemp; uiScan++ ) {
    if ( dStartTimeIn <= oScanTime(uiScan) ) {
      dStartScan = oScanTemp(uiScan);
      dStartTimeIn = oScanTime(uiScan);
      break;
    }
  }
  
  for ( uiScan = uiNumScanTemp; uiScan >= 1; uiScan-- ) {
    if ( dStopTimeIn >= oScanTime(uiScan-1) ) {
      dStopScan =  oScanTemp(uiScan-1);
      dStopTimeIn = oScanTime(uiScan-1);
      break;
    }
  }
  

  // Return the scans
  
  if ( dStartScan > dStopScan ) {
    return( Vector<Int>( 0 ) );
  }

  Vector<Double> oScanDouble =
      poScan->x( dStartScan, dStopScan, oStarIDIn, True );
  uiNumScanTemp = oScanDouble.nelements();

  Vector<Int> oScanInt = Vector<Int>( uiNumScanTemp );

  for ( uiScan = 0; uiScan < uiNumScanTemp; uiScan++ ) {
    oScanInt(uiScan) = (Int) oScanDouble(uiScan);
  }

  return( oScanInt );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::scanID

Description:
------------
This public member function returns the scan IDs.

Inputs:
-------
uiStartScanIn - The start scan.
uiStopScanIn  - The stop scan.
oStarIDIn     - The star IDs.

Outputs:
--------
The scan IDs, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> ScanInfo::scanID( uInt& uiStartScanIn, uInt& uiStopScanIn,
    Vector<String>& oStarIDIn ) const {
  
  // Declare the local variables
  
  uInt uiNumScanTemp; // The temporary number of scans
  uInt uiScan;        // The scan counter
  
  Double dStartScan;  // The Double version of the start scan.
  Double dStopScan;   // The Double version of the stop scan.
  

  // Check the inputs
  
  if ( !checkScan( uiStartScanIn, uiStopScanIn ) ) {
    throw( ermsg( "Invalid start and/or stop scan", "ScanInfo", "scanID" ) );
  }
  
  if ( !checkStarID( oStarIDIn ) ) {
    throw( ermsg( "Invalid star ID(s)", "ScanInfo", "scanID" ) );
  }
  

  // Return the scan IDs
  
  dStartScan = (Double) uiStartScanIn;
  dStopScan = (Double) uiStopScanIn;

  Vector<Double> oScanIDDouble =
      poScan->y( dStartScan, dStopScan, oStarIDIn, True, True );
  
  uiNumScanTemp = oScanIDDouble.nelements();
  
  Vector<Int> oScanIDInt = Vector<Int>( uiNumScanTemp );
  
  for ( uiScan = 0; uiScan < uiNumScanTemp; uiScan++ ) {
    oScanIDInt(uiScan) = (Int) oScanIDDouble(uiScan);
  }
  
  return( oScanIDInt );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::starID

Description:
------------
This public member function returns the star IDs.

Inputs:
-------
uiStartScanIn - The start scan.
uiStopScanIn  - The stop scan.
oStarIDIn     - The star IDs.

Outputs:
--------
The star IDs, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> ScanInfo::starID( uInt& uiStartScanIn, uInt& uiStopScanIn,
    Vector<String>& oStarIDIn ) const {
  
  // Declare the local variables
  
  uInt uiNumScanTemp; // The temporary number of scans
  uInt uiScan;        // A scan counter
  uInt uiScan2;       // A scan counter
  
  Double dStartScan;  // The Double version of the start scan.
  Double dStopScan;   // The Double version of the stop scan.


  // Check the inputs
  
  if ( !checkScan( uiStartScanIn, uiStopScanIn ) ) {
    throw( ermsg( "Invalid start and/or stop scan", "ScanInfo", "starID" ) );
  }
  
  if ( !checkStarID( oStarIDIn ) ) {
    throw( ermsg( "Invalid star ID(s)", "ScanInfo", "starID" ) );
  }
  

  // Return the star IDs
  
  dStartScan = (Double) uiStartScanIn;
  dStopScan = (Double) uiStopScanIn;
  
  Vector<String> oStarIDTemp =
      poScan->token( dStartScan, dStopScan, oStarIDIn, True );
  Vector<String> oStarIDTemp2 = Vector<String>();
  
  uiNumScanTemp = 0;
  
  for ( uiScan = 0; uiScan < oStarIDTemp.nelements(); uiScan++ ) {
    for ( uiScan2 = 0; uiScan2 < oStarIDIn.nelements(); uiScan2++ ) {
      if ( oStarIDTemp(uiScan).matches( oStarIDIn(uiScan2) ) ) {
        uiNumScanTemp += 1;
        oStarIDTemp2.resize( uiNumScanTemp, True );
        oStarIDTemp2(uiNumScanTemp-1) = oStarIDTemp(uiScan);
        break;
      }
    }
  }

  return( oStarIDTemp2 );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::scanTime

Description:
------------
This public member function returns the scan times.

Inputs:
-------
uiStartScanIn - The start scan.
uiStopScanIn  - The stop scan.
oStarIDIn     - The star IDs.

Outputs:
--------
The scan times, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> ScanInfo::scanTime( uInt& uiStartScanIn, uInt& uiStopScanIn,
    Vector<String>& oStarIDIn ) const {
  
  // Declare the local variables
  
  Double dStartScan; // The Double version of the start scan.
  Double dStopScan;  // The Double version of the stop scan.
  

  // Check the inputs
  
  if ( !checkScan( uiStartScanIn, uiStopScanIn ) ) {
    throw( ermsg( "Invalid start and/or stop scan", "ScanInfo", "scanTime" ) );
  }
  
  if ( !checkStarID( oStarIDIn ) ) {
    throw( ermsg( "Invalid star ID(s)", "ScanInfo", "scanTime" ) );
  }
  

  // Return the scan times
  
  dStartScan = (Double) uiStartScanIn;
  dStopScan = (Double) uiStopScanIn;
  
  return( poScanTime->y( dStartScan, dStopScan, oStarIDIn, True, True ) );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::RA

Description:
------------
This public member function returns the right ascensions.

Inputs:
-------
uiStartScanIn - The start scan.
uiStopScanIn  - The stop scan.
oStarIDIn     - The star IDs.

Outputs:
--------
The right ascensions, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> ScanInfo::RA( uInt& uiStartScanIn, uInt& uiStopScanIn,
    Vector<String>& oStarIDIn ) const {
  
  // Declare the local variables
  
  Double dStartScan; // The Double version of the start scan.
  Double dStopScan;  // The Double version of the stop scan.
  

  // Check the inputs
  
  if ( !checkScan( uiStartScanIn, uiStopScanIn ) ) {
    throw( ermsg( "Invalid start and/or stop scan", "ScanInfo", "RA" ) );
  }
  
  if ( !checkStarID( oStarIDIn ) ) {
    throw( ermsg( "Invalid star ID(s)", "ScanInfo", "RA" ) );
  }
  

  // Return the right ascensions
  
  dStartScan = (Double) uiStartScanIn;
  dStopScan = (Double) uiStopScanIn;
  
  return( poRA->y( dStartScan, dStopScan, oStarIDIn, True, True ) );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::DEC

Description:
------------
This public member function returns the declinations.

Inputs:
-------
uiStartScanIn - The start scan.
uiStopScanIn  - The stop scan.
oStarIDIn     - The star IDs.

Outputs:
--------
The declinations, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> ScanInfo::DEC( uInt& uiStartScanIn, uInt& uiStopScanIn,
    Vector<String>& oStarIDIn ) const {
  
  // Declare the local variables
  
  Double dStartScan; // The Double version of the start scan.
  Double dStopScan;  // The Double version of the stop scan.
  

  // Check the inputs
  
  if ( !checkScan( uiStartScanIn, uiStopScanIn ) ) {
    throw( ermsg( "Invalid start and/or stop scan", "ScanInfo", "DEC" ) );
  }
  
  if ( !checkStarID( oStarIDIn ) ) {
    throw( ermsg( "Invalid star ID(s)", "ScanInfo", "DEC" ) );
  }
  

  // Return the declinations
  
  dStartScan = (Double) uiStartScanIn;
  dStopScan = (Double) uiStopScanIn;
  
  return( poDEC->y( dStartScan, dStopScan, oStarIDIn, True, True ) );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::starList

Description:
------------
This public member function returns the star list.

Inputs:
-------
None.

Outputs:
--------
The star list, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> ScanInfo::starList( void ) const {  

  // Return the star list
  
  return( poScan->tokenList() );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::starValid

Description:
------------
This public member function returns a Vector<Bool>{ } object signifying which
star IDs are valid.

Inputs:
-------
oStarIDIn - The star IDs.

Outputs:
--------
The Vector<Bool>{ } object, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Bool> ScanInfo::starValid( const Vector<String>& oStarIDIn ) const {

  // Declare the local variables
  
  uInt uiNumStar;   // The total number of star IDs
  uInt uiNumStarIn; // The number of input star IDs
  uInt uiStar;      // A star-ID counter
  uInt uiStar2;     // A star-ID counter
  
  
  // Form the Vector<Bool>{ } object and return
  
  uiNumStarIn = oStarIDIn.nelements();
  
  String oStarIDTemp = String();
  
  Vector<Bool> oValid = Vector<Bool>( uiNumStarIn );
  
  Vector<String> oStarIDList = starList();
  uiNumStar = oStarIDList.nelements();
  
  for ( uiStar = 0; uiStar < uiNumStarIn; uiStar++ ) {
    oStarIDTemp = oStarIDIn(uiStar);
    oStarIDTemp.gsub( RXwhite, "" );
    oStarIDTemp.upcase();
    for ( uiStar2 = 0; uiStar2 < uiNumStar; uiStar2++ ) {
      if ( oStarIDTemp == oStarIDList(uiStar2) ) {
        break;
      }
    }
    if ( uiStar2 < uiNumStar ) {
      oValid(uiStar) = True;
    } else {
      oValid(uiStar) = False;
    }
  }
  
  return( oValid );

}

// -----------------------------------------------------------------------------

/*

SCanInfo::dumpHDS

Description:
------------
This public member function dumps the scan information into an HDS file (not the
present one).  If the file and HDS objects already exist, consistency is
checked.

Inputs:
-------
oFileIn       - The HDS file name (not the present one).
uiStartScanIn - The start scan.
uiStopScanIn  - The stop scan.
oStarIDIn     - The star IDs.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.
2001 Mar 20 - Nicholas Elias, USNO/NPOI
              uiStartScanIn, uiStopScanIn, and oStarIDIn arguments added.

*/

// -----------------------------------------------------------------------------

void ScanInfo::dumpHDS( String& oFileIn, uInt& uiStartScanIn,
    uInt& uiStopScanIn, Vector<String>& oStarIDIn ) const {

  // Declare/initialize the local variables

  uInt uiScan; // The scan counter
  
  
  // Fix/check the inputs
  
  oFileIn.gsub( RXwhite, "" );
  
  if ( oFileIn.matches( *poFile ) ) {
    return;
  }
  
  if ( !checkScan( uiStartScanIn, uiStopScanIn ) ) {
    throw( ermsg( "Invalid start and/or stop scan", "ScanInfo", "dumpHDS" ) );
  }
  
  if ( !checkStarID( oStarIDIn ) ) {
    throw( ermsg( "Invalid star ID(s)", "ScanInfo", "dumpHDS" ) );
  }
  
  
  // Open/close the HDS file (check if writable)
  
  if ( access( oFileIn.chars(), F_OK ) != 0 ) {
  
    try {
      HDSFile oHDSFile = HDSFile( HDSAccess( oFileIn, "NEW" ),
          HDSName( "DataSet" ), HDSType( "" ), HDSDim() );
    }
    
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Cannot create a new HDS file\n" + oAipsError.getMesg(),
          "ScanInfo", "dumpHDS" ) );
    }
    
  } else {
  
    try {
      HDSFile oHDSFile = HDSFile( HDSAccess( oFileIn, "UPDATE" ) );
    }
    
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Cannot update the HDS file\n" + oAipsError.getMesg(),
          "ScanInfo", "dumpHDS" ) );
    }
    
  }
  
  
  // Open the HDS file again and go to the ScanData HDS object (create
  // ScanData, if necessary)
  
  HDSFile oHDSFile = HDSFile( HDSAccess( oFileIn, "UPDATE" ) );
  
  if ( !oHDSFile.there( HDSName( "ScanData" ) ) ) {
    oHDSFile.New( HDSName( "ScanData" ), HDSType( "" ), HDSDim(), True );
  }
  
  oHDSFile.find( HDSName( "ScanData" ) );
  
  
  // Check/dump the number of scans
  
  if ( !oHDSFile.there( HDSName( "NumScan" ) ) ) {
  
    oHDSFile.screate_integer( HDSName( "NumScan" ),
        length( uiStartScanIn, uiStopScanIn, oStarIDIn ), False );
    
  } else {
  
    uInt uiNumScanTemp =
        Vector<Int>( oHDSFile.obtain_integer( HDSName( "NumScan" ) ) )(0);
        
    if ( uiNumScanTemp != uiNumScan ) {
      throw( ermsg( "Inconsistent numbers of scans\n", "ScanInfo",
          "dumpHDS" ) );
    }
    
  }
  
  
  // Check/dump the scan IDs
  
  if ( !oHDSFile.there( HDSName( "ScanID" ) ) ) {
  
    oHDSFile.create_integer( HDSName( "ScanID" ),
        Array<Int>( scanID( uiStartScanIn, uiStopScanIn, oStarIDIn ) ), False );
  
  } else {
  
    Vector<Int> oScanIDTemp = oHDSFile.obtain_integer( HDSName( "ScanID" ) );
    
    if ( oScanIDTemp != scanID( uiStartScanIn, uiStopScanIn, oStarIDIn ) ) {
      throw( ermsg( "Inconsistent scan ID(s)", "ScanInfo", "dumpHDS" ) );
    }
  
  }
  
  
  // Check/dump the star IDs
  
  if ( !oHDSFile.there( HDSName( "StarID" ) ) ) {
  
    oHDSFile.create_char( HDSName( "StarID" ), 7,
        Array<String>( starID( uiStartScanIn, uiStopScanIn, oStarIDIn ) ),
        False );
  
  } else {
  
    Vector<String> oStarIDTemp1 = oHDSFile.obtain_char( HDSName( "StarID" ) );
    Vector<String> oStarIDTemp2 = starID( uiStartScanIn, uiStopScanIn,
        oStarIDIn );
    
    for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
      if ( !oStarIDTemp1(uiScan).matches( oStarIDTemp2(uiScan) ) ) {
        throw( ermsg( "Inconsistent star ID(s)", "ScanInfo", "dumpHDS" ) );
      }
    }
  
  }
  
  
  // Check/dump the scan times
  
  if ( !oHDSFile.there( HDSName( "ScanTime" ) ) ) {
  
    oHDSFile.create_double( HDSName( "ScanTime" ),
        Array<Double>( scanTime( uiStartScanIn, uiStopScanIn, oStarIDIn ) ),
        False );
  
  } else {
  
    Vector<Double> oScanTimeTemp1 =
        oHDSFile.obtain_double( HDSName( "ScanTime" ) );
    Vector<Double> oScanTimeTemp2 = scanTime( uiStartScanIn, uiStopScanIn,
        oStarIDIn );
    
    for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
      if ( oScanTimeTemp1(uiScan) != oScanTimeTemp2(uiScan) ) {
        throw( ermsg( "Inconsistent scan time(s)", "ScanInfo", "dumpHDS" ) );
      }
    }
  
  }
  
  
  // Check/dump the right ascensions
  
  if ( !oHDSFile.there( HDSName( "RA" ) ) ) {
  
    oHDSFile.create_double( HDSName( "RA" ),
        Array<Double>( RA( uiStartScanIn, uiStopScanIn, oStarIDIn ) ), False );
  
  } else {
  
    Vector<Double> oRATemp1 = oHDSFile.obtain_double( HDSName( "RA" ) );
    Vector<Double> oRATemp2 = RA( uiStartScanIn, uiStopScanIn, oStarIDIn );
    
    for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
      if ( oRATemp1(uiScan) != oRATemp2(uiScan) ) {
        throw( ermsg( "Inconsistent right ascensions(s)", "ScanInfo",
            "dumpHDS" ) );
      }
    }
  
  }
  
  
  // Check/dump the declinations
  
  if ( !oHDSFile.there( HDSName( "DEC" ) ) ) {
  
    oHDSFile.create_double( HDSName( "DEC" ),
        Array<Double>( DEC( uiStartScanIn, uiStopScanIn, oStarIDIn ) ), False );
  
  } else {
  
    Vector<Double> oDECTemp1 = oHDSFile.obtain_double( HDSName( "DEC" ) );
    Vector<Double> oDECTemp2 = DEC( uiStartScanIn, uiStopScanIn, oStarIDIn );
    
    for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
      if ( oDECTemp1(uiScan) != oDECTemp2(uiScan) ) {
        throw( ermsg( "Inconsistent declinations(s)", "ScanInfo", "dumpHDS" ) );
      }
    }
  
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

ScanInfo::dumpASCII

Description:
------------
This public member function dumps the scan information to an ASCII file.  NB:
I'm using functions from stdio.h because I dislike the classes in iostream.h.

Inputs:
-------
oFileIn       - The ASCII file name.
uiStartScanIn - The start scan.
uiStopScanIn  - The stop scan.
oStarIDIn     - The star IDs.

Outputs:
--------
The ASCII file.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void ScanInfo::dumpASCII( const String& oFileIn, uInt& uiStartScanIn,
    uInt& uiStopScanIn, Vector<String>& oStarIDIn ) const {

  // Declare the local variables
  
  uInt uiScan;     // The scan counter
  
  FILE* pmtStream; // The data output stream
  
  
  // Get the scan information
  
  Vector<Int> oScan;        // Keep compiler happy
  Vector<Int> oScanID;      // Keep compiler happy
  Vector<String> oStarID;   // Keep compiler happy
  Vector<Double> oScanTime; // Keep compiler happy
  Vector<Double> oRA;       // Keep compiler happy
  Vector<Double> oDEC;      // Keep compiler happy
  
  try {
    oScan = scan( uiStartScanIn, uiStopScanIn, oStarIDIn );
    oScanID = scanID( uiStartScanIn, uiStopScanIn, oStarIDIn );
    oStarID = starID( uiStartScanIn, uiStopScanIn, oStarIDIn );
    oScanTime = scanTime( uiStartScanIn, uiStopScanIn, oStarIDIn );
    oRA = RA( uiStartScanIn, uiStopScanIn, oStarIDIn );
    oDEC = DEC( uiStartScanIn, uiStopScanIn, oStarIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Cannot get scan information\n" + oAipsError.getMesg(),
        "ScanInfo", "dumpASCII" ) );
  }
  

  // Open the ASCII file
  
  pmtStream = fopen( oFileIn.chars(), "w" );
  
  if ( pmtStream == NULL ) {
    throw( ermsg( "Cannot create ASCII file", "ScanInfo", "dumpASCII" ) );
  }
  
  
  // Dump the scan information to the ASCII file
  
  for ( uiScan = 0; uiScan < oScan.nelements(); uiScan++ ) {
    fprintf( pmtStream, "%d %d %s %19.17f %19.17f %19.17f\n", oScan(uiScan),
        oScanID(uiScan), oStarID(uiScan).chars(), oScanTime(uiScan),
        oRA(uiScan), oDEC(uiScan) );
  }
  
  
  // Close the ASCII file
  
  fclose( pmtStream );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

ScanInfo::version

Description:
------------
This public member function returns the ScanInfo{ } version.

Inputs:
-------
None.

Outputs:
--------
The ScanInfo{ } version, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String ScanInfo::version( void ) const {

  // Return the ScanInfo{ } version
  
  return( String( "0.0" ) );
  
}

// -----------------------------------------------------------------------------

/*

ScanInfo::tool

Description:
------------
This public member function returns the glish tool name (must be "scaninfo").

Inputs:
-------
None.

Outputs:
--------
The glish tool name, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String ScanInfo::tool( void ) const {

  // Return the glish tool name
  
  String oTool = className();
  oTool.downcase();
  
  return( oTool );
  
}

// -----------------------------------------------------------------------------

/*

ScanInfo::getStarID

Description:
------------
This public member function returns the selected star IDs.

Inputs:
-------
None.

Outputs:
--------
The selected star IDs, returned via the function value.

Modification history:
---------------------
2000 Aug 22 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> ScanInfo::getStarID( void ) const {
  
  // Return the selected star IDs
  
  return( poScan->getToken() );
  
}

// -----------------------------------------------------------------------------

/*

ScanInfo::setStarID

Description:
------------
This public member function sets the selected star IDs.

Inputs:
-------
oStarIDIn - The star IDs.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 22 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void ScanInfo::setStarID( Vector<String>& oStarIDIn ) {

  // Set the selected star IDs and return
  
  try {
    poScan->setToken( oStarIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "GDC1Token::setToken() error\n" + oAipsError.getMesg(),
        "ScanInfo", "setStarID" ) );
  }
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

ScanInfo::setStarIDDefault

Description:
------------
This public member function sets the selected star IDs to the default (all star
IDs).

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 22 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void ScanInfo::setStarIDDefault( void ) {

  // Set the selected star IDs to the default and return
  
  poScan->setTokenDefault();
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

ScanInfo::addStarID

Description:
------------
This public member function adds unique selected star IDs.

Inputs:
-------
oStarIDIn - The star IDs.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 22 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void ScanInfo::addStarID( Vector<String>& oStarIDIn ) {

  // Add the unique selected star IDs and return
  
  try {
    poScan->addToken( oStarIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in GDC1Token::addToken()\n" + oAipsError.getMesg(),
        "ScanInfo", "addStarID" ) );
  }
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

ScanInfo::removeStarID

Description:
------------
This public member function removes selected star IDs.

Inputs:
-------
oStarIDIn - The star IDs.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 22 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void ScanInfo::removeStarID( Vector<String>& oStarIDIn ) {

  // Remove the selected tokens and return
  
  try {
    poScan->removeToken( oStarIDIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in GDC1Token::removeToken()\n" + oAipsError.getMesg(),
        "ScanInfo", "removeStarID" ) );
  }
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

ScanInfo::checkScan

Description:
------------
This public member function checks/fixes the start and stop scans.

Inputs:
-------
uiStartScanIn - The start scan.
uiStopScanIn  - The stop scan.

Outputs:
--------
uiStartScanIn - The start scan.
uiStopScanIn  - The stop scan.
The check boolean (True = OK, False = NOT OK).

Modification history:
---------------------
2000 Aug 22 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool ScanInfo::checkScan( uInt& uiStartScanIn, uInt& uiStopScanIn ) const {

  // Declare the local variables
  
  Bool bCheck;       // The check boolean
  
  Double dStartScan; // The Double version of the start scan
  Double dStopScan;  // The Double version of the stop scan
  
  
  // Check/fix the start and stop scans
  
  dStartScan = (Double) uiStartScanIn;
  dStopScan = (Double) uiStopScanIn;
  
  bCheck = poScan->checkX( dStartScan, dStopScan );
  
  uiStartScanIn = (uInt) dStartScan;
  uiStopScanIn = (uInt) dStopScan;
  
  
  // Return the check boolean
  
  return( bCheck );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::checkStarID

Description:
------------
This public member function checks/fixes star IDs.  NB: Duplicate tokens will
be purged.

Inputs:
-------
oStarIDIn - The star IDs.

Outputs:
--------
oStarIDIn - The checked/fixed star IDs.
The check boolean (True = OK, False = NOT OK).

Modification history:
---------------------
2000 Aug 22 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool ScanInfo::checkStarID( Vector<String>& oStarIDIn ) const {

  // Check/fix the star IDs and return the check boolean

  return( poScan->checkToken( oStarIDIn ) );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::className

Description:
------------
This public member function returns the class name.

Inputs:
-------
None.

Outputs:
--------
The class name, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String ScanInfo::className( void ) const {

  // Return the class name
  
  return( String( "ScanInfo" ) );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::methods

Description:
------------
This public member function returns the method names.

Inputs:
-------
None.

Outputs:
--------
The method names, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> ScanInfo::methods( void ) const {

  // Return the method names
  
  Vector<String> oMethod = Vector<String>( 25 );
  
  oMethod(0) = String( "derived" );
  oMethod(1) = String( "file" );
  oMethod(2) = String( "numScan" );
  oMethod(3) = String( "length" );
  oMethod(4) = String( "scan" );
  oMethod(5) = String( "timeScan" );
  oMethod(6) = String( "scanID" );
  oMethod(7) = String( "starID" );
  oMethod(8) = String( "scanTime" );
  oMethod(9) = String( "RA" );
  oMethod(10) = String( "DEC" );
  oMethod(11) = String( "starList" );
  oMethod(12) = String( "starValid" );
  oMethod(13) = String( "dumpHDS" );
  oMethod(14) = String( "dumpASCII" );
  oMethod(15) = String( "id" );
  oMethod(16) = String( "version" );
  oMethod(17) = String( "tool" );
  oMethod(18) = String( "getStarID" );
  oMethod(19) = String( "setStarID" );
  oMethod(20) = String( "setStarIDDefault" );
  oMethod(21) = String( "addStarID" );
  oMethod(22) = String( "removeStarID" );
  oMethod(23) = String( "checkScan" );
  oMethod(24) = String( "checkStarID" );
  
  return( oMethod );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::noTraceMethods

Description:
------------
This public member function returns the method names that are not traced.

Inputs:
-------
None.

Outputs:
--------
The method names, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> ScanInfo::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::runMethod

Description:
------------
This public member function provides the glish/aips++ interface for running the
methods of this class.

Inputs:
-------
uiMethod    - The method number.
oParameters - The method parameters.
bRunMethod  - The method run boolean.

Outputs:
--------
The method result, returned via the function value.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult ScanInfo::runMethod( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {
    
    // derived
    case 0: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = derived();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "derived( ) error\n" + oAipsError.getMesg(), "ScanInfo",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // file
    case 1: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = file();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "file( ) error\n" + oAipsError.getMesg(), "ScanInfo",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // numScan
    case 2: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) numScan();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "numScan( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }

    // length
    case 3: {
      Parameter<Int> startscan( oParameters, "startscan", ParameterSet::In );
      Parameter<Int> stopscan( oParameters, "stopscan", ParameterSet::In );
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) length( (uInt&) startscan(), (uInt&) stopscan(),
              starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "length( ) error\n" + oAipsError.getMesg(), "ScanInfo",
              "runMethod" ) );
        }
      }
      break;
    }

    // scan
    case 4: {
      Parameter<Int> startscan( oParameters, "startscan", ParameterSet::In );
      Parameter<Int> stopscan( oParameters, "stopscan", ParameterSet::In );
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      Parameter< Vector<Int> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = scan( (uInt&) startscan(), (uInt&) stopscan(),
              starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "scan( ) error\n" + oAipsError.getMesg(), "ScanInfo",
              "runMethod" ) );
        }
      }
      break;
    }

    // timeScan
    case 5: {
      Parameter<Double> starttime( oParameters, "starttime", ParameterSet::In );
      Parameter<Double> stoptime( oParameters, "stoptime", ParameterSet::In );
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      Parameter< Vector<Int> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = timeScan( starttime(), stoptime(), starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "timeScan( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }

    // scanID
    case 6: {
      Parameter<Int> startscan( oParameters, "startscan", ParameterSet::In );
      Parameter<Int> stopscan( oParameters, "stopscan", ParameterSet::In );
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      Parameter< Vector<Int> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = scanID( (uInt&) startscan(), (uInt&) stopscan(),
              starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "scanID( ) error\n" + oAipsError.getMesg(), "ScanInfo",
              "runMethod" ) );
        }
      }
      break;
    }

    // starID
    case 7: {
      Parameter<Int> startscan( oParameters, "startscan", ParameterSet::In );
      Parameter<Int> stopscan( oParameters, "stopscan", ParameterSet::In );
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = starID( (uInt&) startscan(), (uInt&) stopscan(),
              starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "starID( ) error\n" + oAipsError.getMesg(), "ScanInfo",
              "runMethod" ) );
        }
      }
      break;
    }

    // scanTime
    case 8: {
      Parameter<Int> startscan( oParameters, "startscan", ParameterSet::In );
      Parameter<Int> stopscan( oParameters, "stopscan", ParameterSet::In );
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = scanTime( (uInt&) startscan(), (uInt&) stopscan(),
              starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "scanTime( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }

    // RA
    case 9: {
      Parameter<Int> startscan( oParameters, "startscan", ParameterSet::In );
      Parameter<Int> stopscan( oParameters, "stopscan", ParameterSet::In );
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = RA( (uInt&) startscan(), (uInt&) stopscan(), starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "RA( ) error\n" + oAipsError.getMesg(), "ScanInfo",
              "runMethod" ) );
        }
      }
      break;
    }

    // DEC
    case 10: {
      Parameter<Int> startscan( oParameters, "startscan", ParameterSet::In );
      Parameter<Int> stopscan( oParameters, "stopscan", ParameterSet::In );
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = DEC( (uInt&) startscan(), (uInt&) stopscan(),
              starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "DEC( ) error\n" + oAipsError.getMesg(), "ScanInfo",
              "runMethod" ) );
        }
      }
      break;
    }

    // starList
    case 11: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = starList();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "starList( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }

    // starValid
    case 12: {
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      Parameter< Vector<Bool> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = starValid( starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "starValid( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }
    
    // dumpHDS
    case 13: {
      Parameter<String> file( oParameters, "file", ParameterSet::In );
      Parameter<Int> startscan( oParameters, "startscan", ParameterSet::In );
      Parameter<Int> stopscan( oParameters, "stopscan", ParameterSet::In );
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          dumpHDS( file(), (uInt&) startscan(), (uInt&) stopscan(), starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "dumpHDS( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }
    
    // dumpASCII
    case 14: {
      Parameter<String> file( oParameters, "file", ParameterSet::In );
      Parameter<Int> startscan( oParameters, "startscan", ParameterSet::In );
      Parameter<Int> stopscan( oParameters, "stopscan", ParameterSet::In );
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          dumpASCII( file(), (uInt&) startscan(), (uInt&) stopscan(),
              starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "dumpASCII( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }
    
    // id    
    case 15: {
      Parameter<ObjectID> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
	  returnval() = id();
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "id( ) error\n" + oAipsError.getMesg(), "ScanInfo",
	      "runMethod" ) );
	}
      }
      break;
    }

    // version
    case 16: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = version();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "version( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }

    // tool
    case 17: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tool();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tool( ) error\n" + oAipsError.getMesg(), "ScanInfo",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // getStarID
    case 18: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = getStarID();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "getStarID( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }
    
    // setStarID
    case 19: {
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          setStarID( starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setStarID( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }
    
    // setStarIDDefault
    case 20: {
      if ( bRunMethod ) {
        try {
          setStarIDDefault();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "setStarIDDefault( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }
    
    // addStarID
    case 21: {
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          addStarID( starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "addStarID( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }
    
    // removeStarID
    case 22: {
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          removeStarID( starid() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "removeStarID( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }
    
    // checkScan
    case 23: {
      Parameter<Int> startscan( oParameters, "startscan", ParameterSet::In );
      Parameter<Int> stopscan( oParameters, "stopscan", ParameterSet::In );
      Parameter< Vector<Int> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          uInt uiStartScan = (uInt) startscan();
          uInt uiStopScan = (uInt) stopscan();
          Bool bCheck = checkScan( uiStartScan, uiStopScan );
          Vector<Int> oScan = Vector<Int>( 3 );
          oScan(0) = (Int) bCheck;
          oScan(1) = (Int) uiStartScan;
          oScan(2) = (Int) uiStopScan;
          returnval() = oScan;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "checkScan( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }
    
    // checkStarID
    case 24: {
      Parameter< Vector<String> >
          starid( oParameters, "starid", ParameterSet::In );
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          Vector<String> oStarID = starid();
          Bool bCheck = checkStarID( oStarID );
          uInt uiStarID;
          uInt uiNumStarID = oStarID.nelements();
          Vector<String> oStarID2 = Vector<String>( uiNumStarID + 1 );
          oStarID2(0) = (String) bCheck;
          for ( uiStarID = 0; uiStarID < uiNumStarID; uiStarID++ ) {
            oStarID2(uiStarID+1) = oStarID(uiStarID);
          }
          returnval() = oStarID2;
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "checkStarID( ) error\n" + oAipsError.getMesg(),
              "ScanInfo", "runMethod" ) );
        }
      }
      break;
    }

    // default
    default: {
      if ( bRunMethod ) {
        throw( ermsg( "Invalid ScanInfo{ } method", "ScanInfo", "runMethod" ) );
      }
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}

// -----------------------------------------------------------------------------

/*

ScanInfo::loadHDS

Description:
------------
This private member function loads the scan information from an HDS file.

Inputs:
-------
oFileIn - The HDS file name.

Outputs:
--------
oScanIDOut   - The scan IDs.
oStarIDOut   - The star IDs.
oScanTimeOut - The scan times.
oRAOut       - The right ascensions.
oDECOut      - The declinations.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void ScanInfo::loadHDS( const String& oFileIn, Vector<Int>& oScanIDOut,
    Vector<String>& oStarIDOut, Vector<Double>& oScanTimeOut,
    Vector<Double>& oRAOut, Vector<Double>& oDECOut ) {
  
  // Declare the local variables
  
  uInt uiNumScanTemp; // The temporary number of scans

  // Open the HDS file
  
  HDSFile* poHDSFile = NULL; // Keep compiler happy
  
  try {
    poHDSFile = new HDSFile( HDSAccess( oFileIn, "READ" ) );
  }
  
  catch( AipsError oAipsError ) {
    throw( ermsg( "Cannot open HDS file\n" + oAipsError.getMesg(), "ScanInfo",
        "loadHDS" ) );
  }
  
  
  // Go to the scan information
  
  try {
    poHDSFile->Goto( "DataSet.ScanData" );
  }
  
  catch ( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg( "No scan information\n" + oAipsError.getMesg(), "ScanInfo",
        "loadHDS" ) );
  }
  
  
  // Get the scan information
  
  try {
    uiNumScanTemp =
        Vector<Int>( poHDSFile->obtain_integer( HDSName( "NumScan" ) ) )(0);
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Could not get number of scans\n" + oAipsError.getMesg(),
        "ScanInfo", "loadHDS" ) );
  }
  
  oScanIDOut.resize( uiNumScanTemp, True );
  oStarIDOut.resize( uiNumScanTemp, True );
  oScanTimeOut.resize( uiNumScanTemp, True );
  oRAOut.resize( uiNumScanTemp, True );
  oDECOut.resize( uiNumScanTemp, True );
  
  try {
    oScanIDOut =
        Vector<Int>( poHDSFile->obtain_integer( HDSName( "ScanID" ) ) );
    oStarIDOut =
        Vector<String>( poHDSFile->obtain_char( HDSName( "StarID" ) ) );
    oScanTimeOut =
        Vector<Double>( poHDSFile->obtain_double( HDSName( "ScanTime" ) ) );
    oRAOut = Vector<Double>( poHDSFile->obtain_double( HDSName( "RA" ) ) );
    oDECOut = Vector<Double>( poHDSFile->obtain_double( HDSName( "DEC" ) ) );
  }
  
  catch ( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg( "Cannot load scan information\n" + oAipsError.getMesg(),
        "ScanInfo", "loadHDS" ) );
  }


  // Close the HDS file

  delete poHDSFile;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

ScanInfo::initialize

Description:
------------
This private member function initializes the private variables.

Inputs:
-------
oScanIDIn   - The scan IDs.
oStarIDIn   - The star IDs.
oScanTimeIn - The scan times.
oRAIn       - The right ascensions.
oDECIn      - The declinations.

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 21 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void ScanInfo::initialize( const Vector<Int>& oScanIDIn,
    const Vector<String>& oStarIDIn, const Vector<Double>& oScanTimeIn,
    const Vector<Double>& oRAIn, const Vector<Double>& oDECIn ) {
  
  // Declare/initialize the local variables
  
  uInt uiScan;       // The scan counter
  
  String oType = ""; // The GDC1Token{ } type
  
  
  // Check the inputs
  
  uiNumScan = oScanIDIn.nelements();
  
  if ( oStarIDIn.nelements() != uiNumScan ) {
    throw( ermsg( "Invalid scan and/or star ID", "ScanInfo", "initialize" ) );
  }
  
  if ( oScanTimeIn.nelements() != uiNumScan ) {
    throw( ermsg( "Invalid scan times", "ScanInfo", "initialize" ) );
  }
  
  if ( oRAIn.nelements() != uiNumScan ) {
    throw( ermsg( "Invalid right ascensions", "ScanInfo", "initialize" ) );
  }
  
  if ( oDECIn.nelements() != uiNumScan ) {
    throw( ermsg( "Invalid declinations", "ScanInfo", "initialize" ) );
  }

  
  // Form the GDC1Token{ } objects
  
  Vector<Double> oNullD = Vector<Double>();
  Vector<Bool> oNullB = Vector<Bool>();
  
  Vector<Double> oScan = Vector<Double>( uiNumScan );
  Vector<Double> oScanID = Vector<Double>( uiNumScan );
  
  for ( uiScan = 0; uiScan < uiNumScan; uiScan++ ) {
    oScan(uiScan) = (Double) uiScan + 1;
    oScanID(uiScan) = (Double) oScanIDIn(uiScan);
  }
  
  poScan = NULL;
  poScanTime = NULL;
  poRA = NULL;
  poDEC = NULL;
  
  try {
    poScan = new GDC1Token( oScan, oScanID, oNullD, oNullD, oStarIDIn, oNullB,
        oType );
    poScanTime = new GDC1Token( oScan, oScanTimeIn, oNullD, oNullD, oStarIDIn,
        oNullB, oType );
    poRA = new GDC1Token( oScan, oRAIn, oNullD, oNullD, oStarIDIn, oNullB,
        oType );
    poDEC = new GDC1Token( oScan, oDECIn, oNullD, oNullD, oStarIDIn, oNullB,
        oType );
  }
  
  catch ( AipsError oAipsError ) {
    if ( poScan != NULL ) {
      delete poScan;
    }
    if ( poScanTime != NULL ) {
      delete poScanTime;
    }
    if ( poRA != NULL ) {
      delete poRA;
    }
    if ( poDEC != NULL ) {
      delete poDEC;
    }
    throw( ermsg(
        "Cannot create GDC1Token{ } objects\n" + oAipsError.getMesg(),
        "ScanInfo", "loadHDS" ) );
  }
  
  
  // Return
  
  return;

}
