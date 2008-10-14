//# HDSLocator.cc is part of Cuttlefish (NPOI data reduction package)
//# Copyright (C) 1999,2000
//# United States Naval Observatory; Washington, DC; USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is designed for use only in AIPS++ (National Radio Astronomy
//# Observatory; Charlottesville, VA; USA) in the hope that it will be useful,
//# but WITHOUT ANY WARRANTY; without even the implied warranty of
//# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//# See the GNU Library General Public License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning Cuttlefish should be addressed as follows:
//#        Internet email: nme@nofs.navy.mil
//#        Postal address: Dr. Nicholas Elias
//#                        United States Naval Observatory
//#                        Navy Prototype Optical Interferometer
//#                        P.O. Box 1149
//#                        Flagstaff, AZ 86002-1149 USA
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: HDSLocator.cc,v 19.0 2003/07/16 06:03:07 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

HDSLocator.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the HDSLocator{ } class member functions.

Public member functions:
------------------------
HDSLocator (2 versions), ~HDSLocator, alter, clen, get, len, name, path, ploc,
pploc, prec, prim, put, recover, renam, reset, retyp, shape, size, state, struc,
type, valid, operator=.

Inherited classes (Cuttlefish):
-------------------------------
HDSStatus.

Modification history:
---------------------
1998 Nov 06 - Nicholas Elias, USNO/NPOI
              File created with public member functions HDSLocator( ) and
              ~HDSLocator( ).
1998 Nov 10 - Nicholas Elias, USNO/NPOI
              Public member functions ploc( ), prim( ), and struc( ) added.
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member functions alter( ), clen( ), len( ), name( ),
              prec( ), renam( ), reset( ), retyp( ), shape( ), size( ),
              state( ), type( ), and valid( ) added.
1998 Nov 15 - Nicholas Elias, USNO/NPOI
              Public member function path( ) added.
1998 Nov 25 - Nicholas Elias, USNO/NPOI
              Public member functions get( ) and put( ) added.
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member functions HDSLocator( ) (copy version) and pploc( )
	      added.
1999 Feb 14 - Nicholas Elias, USNO/NPOI
              Public member function recover( ) added.
1999 Sep 15 - Nicholas Elias, USNO/NPOI
              Public member function operator=( ) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/HDS/HDSLocator.h> // HDS locator

// -----------------------------------------------------------------------------

/*

HDSLocator::HDSLocator

Description:
------------
This public member function constructs the HDSLocator{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSLocator::HDSLocator( void ) : HDSStatus() {

  // Initialize the HDS locator and return

  poLocator = new Block<Char>( SZLOC );
  memcpy( (void*) poLocator->storage(), (const void*) NOLOC, (size_t) SZLOC );

  return;

}

// -----------------------------------------------------------------------------

/*

HDSLocator::HDSLocator (copy)

Description:
------------
This public member function copies the HDSLocator{ } object.

Inputs:
-------
oLocatorIn - The HDSLocator{ } locator.

Outputs:
--------
None.

Modification history:
---------------------
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSLocator::HDSLocator( const HDSLocator& oLocatorIn )
    : HDSStatus( oLocatorIn.status() ) {

  // Initialize the HDS locator

  poLocator = new Block<Char>( SZLOC );
  HDSWrapper::dat_clone( (const char* const) oLocatorIn.pploc(),
      (char* const) poLocator->storage(), (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_clone( ) error", "HDSLocator",
        "HDSLocator" ) );
  }


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSLocator::~HDSLocator

Description:
------------
This public member function destructs the HDSLocator{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 06 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSLocator::~HDSLocator( void ) {

  // Deallocate the memory and return
  
  delete poLocator;
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSLocator::alter

Description:
------------
This public member function alters the last dimension of the HDS locator.

Inputs:
-------
uiLastDim - The new HDS locator last dimension.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSLocator::alter( const uInt uiLastDim ) {

  // Declare the local variables

  Bool bPrim;           // The HDS locator primitive flag
  Bool bValid;          // The HDS locator validity flag

  HDSDim* poDim = NULL; // The HDS locator dimensions
  

  // Check the HDS status and locator

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator",
        "alter" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "alter" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "alter" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "alter" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSLocator", "alter" ) );
  }

  try {
    poDim = new HDSDim( shape() );
  }

  catch ( AipsError oAipsError ) {
    if ( poDim != NULL ) {
      delete poDim;
    }
    throw( ermsg( "HDSDim{ } error\n" + oAipsError.getMesg(), "HDSLocator",
        "alter" ) );
  }
  
  if ( poDim->nelements() < 1 ) {
    delete poDim;
    throw( ermsg( "Cannot alter an HDS scalar locator", "HDSLocator",
        "alter" ) );
  }
  
  
  // Check the inputs
  
  if ( uiLastDim < 1 ) {
    delete poDim;
    throw( ermsg( "Invalid HDS locator last dimension", "HDSLocator",
        "alter" ) );	
  }


  // Alter the last dimension of the HDS locator and return
  
  (*poDim)(poDim->nelements() - 1) = uiLastDim;
  
  HDSWrapper::dat_alter( (const char* const) poLocator->storage(),
      (const int) poDim->nelements(), (const int* const) poDim->ppdim(),
      (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_alter( ) error", "HDSLocator", "alter" ) );
  }

  delete poDim;

  return;
      
}

// -----------------------------------------------------------------------------

/*

HDSLocator::clen

Description:
------------
This public member function returns the HDS locator character length.

Inputs:
-------
None.

Outputs:
--------
The HDS locator character length, returned via the public member function value.

Modification history:
---------------------
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

const uInt HDSLocator::clen( void ) {

  // Declare the local variables
  
  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag

  uInt uiCLen; // The HDS locator character length


  // Check the HDS status, locator, and primitive flag

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator", "clen" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "clen" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "clen" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "clen" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSLocator", "clen" ) );
  }


  // Get and return the HDS locator character length

  HDSWrapper::dat_clen( (const char* const) poLocator->storage(),
      (int* const) &uiCLen, (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_clen( ) error", "HDSLocator", "clen" ) );
  }

  return( (const uInt) uiCLen );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::get

Description:
------------
This public member function gets data from the HDS locator.  The data is in a
single uChar* block of memory (independent of the HDS type, which means you need
to know the size of each HDS locator element in bytes), in FORTRAN order
(yuck!).  NB: The memory for the output is allocated in this public member
function, but it must be deallocated elsewhere.

Inputs:
-------
None.

Outputs:
--------
(*aucData) - The HDS locator data.

Modification history:
---------------------
1998 Nov 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSLocator::get( uChar* (*aucData) ) {

  // Declare the local variables
  
  Bool bPrim;     // The HDS locator primitive flag
  Bool bValid;    // The HDS locator validity flag
  
  uInt uiDim;     // The HDS locator dimension counter
  uInt uiNumChar; // The number of characters in the array
  

  // Check the HDS status and locator

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator", "get" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "get" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "get" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "get" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSLocator", "get" ) );
  }


  // Get the HDS locator data and return

  uiNumChar = len();
  for ( uiDim = 0; uiDim < shape().nelements(); uiDim++ ) {
    uiNumChar *= (shape())(uiDim);
  }
  (*aucData) = new uChar[uiNumChar];

  HDSWrapper::dat_get( (const char* const) poLocator->storage(),
      (const char* const) type().chars(), (const int) shape().nelements(),
      (const int* const) shape().ppdim(), (unsigned char**) aucData,
      (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_get( ) error", "HDSLocator", "get" ) );
  }

  return;

}

// -----------------------------------------------------------------------------

/*

HDSLocator::len

Description:
------------
This public member function returns the HDS locator length.

Inputs:
-------
None.

Outputs:
--------
The HDS locator length, returned via the public member function value.

Modification history:
---------------------
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

const uInt HDSLocator::len( void ) {

  // Declare the local variables
  
  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag

  uInt uiLen;  // The HDS locator length


  // Check the HDS status, locator, and primitive flag

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator", "len" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "len" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "len" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "len" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSLocator", "len" ) );
  }


  // Get and return the HDS locator length

  HDSWrapper::dat_len( (const char* const) poLocator->storage(),
      (int* const) &uiLen, (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_len( ) error", "HDSLocator", "len" ) );
  }

  return( (const uInt) uiLen );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::name

Description:
------------
This public member function returns the HDS locator name.

Inputs:
-------
None.

Outputs:
--------
The HDS locator name, returned via the public member function value.

Modification history:
---------------------
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

const HDSName HDSLocator::name( void ) {

  // Declare the local variables
  
  Bool bValid;                     // The HDS locator validity flag

  Char acName[HDSName::SZNAM + 1]; // The HDS locator name


  // Check the HDS status and locator

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator", "name" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "name" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "name" ) );
  }


  // Get and return the HDS locator name

  HDSWrapper::dat_name( (const char* const) poLocator->storage(),
      (char* const) acName, (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_name( ) error", "HDSLocator", "name" ) );
  }

  return( (const HDSName) HDSName( (const char* const) acName ) );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::path

Description:
------------
This public member function returns the HDS path.

Inputs:
-------
None.

Outputs:
--------
The HDS path, returned via the public member function value.

Modification history:
---------------------
1998 Nov 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

const String HDSLocator::path( void ) {

  // Declare the local variables
  
  Bool bValid;                   // The HDS locator validity flag
  
  uInt uiLocator;                // The HDS locator
  
  Char acFile[NUM_CHAR_MAX + 1]; // The HDS file name
  Char acPath[NUM_CHAR_MAX + 1]; // The fully resolved HDS path


  // Check the HDS status and locator

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator", "path" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "path" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "path" ) );
  }
  
  
  // Get and return the HDS path
  
  HDSWrapper::hds_trace( (const char* const) poLocator->storage(),
      (int*) &uiLocator, (char*) acPath, (char*) acFile,
      (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::hds_trace( ) error", "HDSLocator", "path" ) );
  }

  return( (const String) String( acPath ) );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::ploc

Description:
------------
This public member function returns the HDS locator pointer.

Inputs:
-------
None.

Outputs:
--------
The HDS locator pointer, returned via the public member function value.

Modification history:
---------------------
1998 Nov 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Char* const HDSLocator::ploc( void ) {

  // Return the HDS locator pointer

  return( (Char* const) poLocator->storage() );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::pploc

Description:
------------
This public member function returns the HDS locator pointer (cannot be changed).

Inputs:
-------
None.

Outputs:
--------
The HDS locator pointer, returned via the public member function value.

Modification history:
---------------------
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

const Char* const HDSLocator::pploc( void ) const {

  // Return the HDS locator pointer

  return( (const Char* const) poLocator->storage() );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::prec

Description:
------------
This public member function returns the HDS locator precision.

Inputs:
-------
None.

Outputs:
--------
The HDS locator precision, returned via the public member function value.

Modification history:
---------------------
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

const uInt HDSLocator::prec( void ) {

  // Declare the local variables
  
  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag

  uInt uiPrec; // The HDS locator precision


  // Check the HDS status, locator, and primitive flag

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator", "prec" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "prec" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "prec" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "prec" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSLocator", "prec" ) );
  }


  // Get and return the HDS locator precision

  HDSWrapper::dat_prec( (const char* const) poLocator->storage(),
      (int* const) &uiPrec, (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_prec( ) error", "HDSLocator", "prec" ) );
  }

  return( (const uInt) uiPrec );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::prim

Description:
------------
This public member function returns the HDS locator primitive flag.

Inputs:
-------
None.

Outputs:
--------
The HDS locator primitive flag, returned via the public member function value.

Modification history:
---------------------
1998 Nov 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool HDSLocator::prim( void ) {

  // Declare the local variables

  bool bPrim;  // The HDS locator primitive flag
  
  Bool bValid; // The HDS locator validity flag


  // Check the HDS status and locator

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator", "prim" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "prim" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "prim" ) );
  }


  // Get and return the HDS locator primitive flag

  HDSWrapper::dat_prim( (const char* const) poLocator->storage(), &bPrim,
      (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_prim( ) error", "HDSLocator", "prim" ) );
  }

  return( (Bool) bPrim );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::put

Description:
------------
This public member function puts data into the HDS locator.  The data is in a
single uChar* block of memory (independent of the HDS type, which means you need
to know the size of each HDS locator element in bytes), in FORTRAN order
(yuck!).

Inputs:
-------
aucData - The HDS locator data.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSLocator::put( const uChar* const aucData ) {

  // Declare the local variables
  
  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag
  

  // Check the HDS status and locator

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator", "put" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "put" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "put" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "put" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSLocator", "put" ) );
  }


  // Put the HDS locator data and return

  HDSWrapper::dat_put( (const char* const) poLocator->storage(),
      (const char* const) type().chars(), (const int) shape().nelements(),
      (const int* const) shape().ppdim(), (const unsigned char* const) aucData,
      (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_put( ) error", "HDSLocator", "put" ) );
  }

  return;

}

// -----------------------------------------------------------------------------

/*

HDSLocator::recover

Description:
------------
This public member function sets the HDS status to OK and resets the HDS locator
to NOLOC.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSLocator::recover( void ) {

  // Set the HDS status to OK, reset the HDS locator to NOLOC, and return

  if ( status() != OK ) {
    on();
    memcpy( (void*) poLocator->storage(), (const void*) NOLOC, (size_t) SZLOC );
  }
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSLocator::renam

Description:
------------
This public member function renames the HDS locator.

Inputs:
-------
oNameIn - The new HDS locator name.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSLocator::renam( const HDSName& oNameIn ) {

  // Declare the local variables
  
  Bool bValid; // The HDS locator validity flag

  
  // Check the HDS status and locator

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator",
        "renam" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "renam" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "renam" ) );
  }


  // Rename the HDS locator and return
  
  HDSWrapper::dat_renam( (const char* const) poLocator->storage(),
      (const char* const) oNameIn.chars(), (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_renam( ) error", "HDSLocator", "renam" ) );
  }
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSLocator::reset

Description:
------------
This public member function resets the HDS locator state.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSLocator::reset( void ) {

  // Declare the local variables
  
  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag

  
  // Check the HDS status, locator, and primitive flag

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator",
        "reset" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "reset" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "reset" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "reset" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSLocator", "reset" ) );
  }
  
  
  // Reset the HDS locator state and return
  
  HDSWrapper::dat_reset( (const char* const) poLocator->storage(),
      (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_reset( ) error", "HDSLocator", "reset" ) );
  }
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

HDSLocator::retyp

Description:
------------
This public member function retypes the HDS locator.

Inputs:
-------
oTypeIn - The new HDS locator type.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSLocator::retyp( const HDSType& oTypeIn ) {

  // Declare the local variables
  
  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag

  
  // Check the HDS status and locator

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator",
        "retyp" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "retyp" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "retyp" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "retyp" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSLocator", "retyp" ) );
  }


  // Retype the HDS locator and return
  
  HDSWrapper::dat_retyp( (const char* const) poLocator->storage(),
      (const char* const) oTypeIn.chars(), (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_retyp( ) error", "HDSLocator", "retyp" ) );
  }
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSLocator::shape

Description:
------------
This public member function returns the HDS locator shape.

Inputs:
-------
None.

Outputs:
--------
The HDS locator shape, returned via the public member function value.

Modification history:
---------------------
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

const HDSDim HDSLocator::shape( void ) {

  // Declare the local variables
  
  Bool bValid;                // The HDS locator validity flag

  uInt uiDim;                 // The HDS locator dimension counter
  uInt uiNumDim;              // The HDS locator number of dimensions
  
  uInt auiDim[HDSDim::MXDIM]; // The dimension numbers in the HDS locator


  // Check the HDS status and locator

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator",
        "shape" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "shape" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "shape" ) );
  }
  
  
  // Get and return the HDS locator shape
  
  HDSWrapper::dat_shape( (const char* const) poLocator->storage(),
      (int* const) &uiNumDim, (int* const) auiDim, (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_shape( ) error", "HDSLocator", "shape" ) );
  }

  HDSDim oDim = HDSDim();

  if ( uiNumDim > 0 ) {  
    oDim.resize( uiNumDim, True );
    for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
      oDim(uiDim) = auiDim[uiDim];
    }
  }

  return( (const HDSDim) oDim );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::size

Description:
------------
This public member function returns the HDS locator size.

Inputs:
-------
None.

Outputs:
--------
The HDS locator size, returned via the public member function value.

Modification history:
---------------------
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

const uInt HDSLocator::size( void ) {

  // Declare the local variables
  
  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag

  uInt uiSize; // The HDS locator size


  // Check the HDS status, locator, and primitive flag

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator", "size" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "size" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "size" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "size" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSLocator", "size" ) );
  }


  // Get and return the HDS locator size

  HDSWrapper::dat_size( (const char* const) poLocator->storage(),
      (int* const) &uiSize, (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_size( ) error", "HDSLocator", "size" ) );
  }

  return( (const uInt) uiSize );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::state

Description:
------------
This public member function returns the HDS locator state flag.

Inputs:
-------
None.

Outputs:
--------
The HDS locator state flag, returned via the public member function value.

Modification history:
---------------------
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool HDSLocator::state( void ) {

  // Declare the local variables

  bool bState; // The HDS locator state flag
  
  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag


  // Check the HDS status, locator, and primitive flag

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator",
        "state" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "state" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "state" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "state" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSLocator", "state" ) );
  }


  // Get and return the HDS locator state flag

  HDSWrapper::dat_state( (const char* const) poLocator->storage(), &bState,
      (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_state( ) error", "HDSLocator", "state" ) );
  }

  return( (Bool) bState );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::struc

Description:
------------
This public member function returns the HDS locator structure flag.

Inputs:
-------
None.

Outputs:
--------
The HDS locator structure flag, returned via the public member function value.

Modification history:
---------------------
1998 Nov 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool HDSLocator::struc( void ) {

  // Declare the local variables

  bool bStruc; // The HDS locator structure flag
  
  Bool bValid; // The HDS locator validity flag


  // Check the HDS status and locator

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator",
        "struc" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "struc" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "struc" ) );
  }


  // Get and return the HDS locator structure flag

  HDSWrapper::dat_struc( (const char* const) poLocator->storage(), &bStruc,
      (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_struc( ) error", "HDSLocator", "struc" ) );
  }

  return( (Bool) bStruc );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::type

Description:
------------
This public member function returns the HDS locator type.

Inputs:
-------
None.

Outputs:
--------
The HDS locator type, returned via the public member function value.

Modification history:
---------------------
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

const HDSType HDSLocator::type( void ) {

  // Declare the local variables
  
  Bool bValid;                     // The HDS locator validity flag

  Char acType[HDSType::SZTYP + 1]; // The HDS locator type


  // Check the HDS status and locator

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator", "type" ) );
  }
  
  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSLocator",
        "type" ) );
  }

  if ( !bValid ) {
    throw( ermsg( "Invalid HDS locator", "HDSLocator", "type" ) );
  }


  // Get and return the HDS locator type

  HDSWrapper::dat_type( (const char* const) poLocator->storage(),
      (char* const) acType, (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_type( ) error", "HDSLocator", "type" ) );
  }

  return( (const HDSType) HDSType( acType ) );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::valid

Description:
------------
This public member function returns the HDS locator validity flag.

Inputs:
-------
None.

Outputs:
--------
The HDS locator validity flag, returned via the public member function value.

Modification history:
---------------------
1998 Nov 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool HDSLocator::valid( void ) {

  // Declare the local variables

  bool bValid; // The HDS locator validity flag


  // Check the HDS status

  if ( status() != OK ) {
    throw( ermsg( "Error associated with HDS locator", "HDSLocator",
        "valid" ) );
  }


  // Get and return the HDS locator validity flag

  HDSWrapper::dat_valid( (const char* const) poLocator->storage(), &bValid,
      (int* const) pstatus() );

  if ( status() != OK ) {
    throw( ermsg( "HDSWrapper::dat_valid( ) error", "HDSLocator", "valid" ) );
  }

  return( (Bool) bValid );

}

// -----------------------------------------------------------------------------

/*

HDSLocator::operator=

Description:
------------
This public member function redfines operator=( ).

Inputs:
-------
oLocatorIn - The HDSLocator{ } object.

Outputs:
--------
None.

Modification history:
---------------------
1999 Sep 15 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSLocator::operator=( const HDSLocator& oLocatorIn ) {

  // Reset the HDS locator and return
  
  memcpy( (void*) poLocator->storage(), (const void*) oLocatorIn.pploc(),
      SZLOC );
  
  return;

}
