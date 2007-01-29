//#HDSFile.cc is part of Cuttlefish (NPOI data reduction package)
//#Copyright (C) 1999,2000,2001,2002
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
//#Correspondence concerning Cuttlefish should be addressed as follows:
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
//# $Id: HDSFile.cc,v 19.1 2004/08/25 05:49:26 gvandiep Exp $
// -----------------------------------------------------------------------------

/*

HDSFile.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the HDSFile{ } class member functions.

Public member functions:
------------------------
HDSFile (3 versions), ~HDSFile, alter, annul, cell, checkSlice, checkSameSlice,
clen, clone, copy, copy2file, create_byte, create_char, create_double,
create_integer, create_logical, create_real, create_ubyte, create_uword,
create_word, erase, file, find, get_byte, get_char, get_double, get_integer,
get_logical, get_real, get_ubyte, get_uword, get_word, Goto, index, len, list,
locator, locatord, locators, mode, move, name, ncomp, New, numDim, obtain_byte,
obtain_char, obtain_double, obtain_integer, obtain_logical, obtain_real,
obtain_ubyte, obtain_uword, obtain_word, path, prec, prim, put_byte, put_char,
put_double, put_integer, put_logical, put_real, put_ubyte, put_uword, put_word,
recover, renam, reset, retyp, save, screate_byte, screate_char, screate_double,
screate_integer, screate_logical, screate_real, screate_ubyte, screate_uword,
screate_word, shape, size, slice, state, struc, there, top, type, valid,
version.

Static public member functions:
-------------------------------
dimMax, locatorMax, noLocator, sizeLocator, sizeMode, sizeName, sizetype.

Inherited classes (aips++):
---------------------------
ApplicationObject.

Inherited classes (Cuttlefish):
-------------------------------
GeneralStatus.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              File created with public member functions HDSFile (hds_new and
	      hds_open versions), ~HDSFile, annul( ), cell( ), copy( ),
	      copy2file( ), erase( ), file( ), find( ), index( ), mode( ),
	      move( ), ncomp( ), New( ), locator( ), save( ), slice( ),
              there( ), and top().
1998 Nov 23 - Nicholas Elias, USNO/NPOI
              Public member function list( ) added.
1998 Nov 29 - Nicholas Elias, USNO/NPOI
              Public member functions alter( ), clen( ), shape( ), and valid( )
	      added.
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member functions get( ), len( ), name( ), path( ), prec( ),
	      prim( ), put( ), renam( ), reset( ), retyp( ), size( ), state( ),
	      struc( ), and type( ) added.
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member functions HDSFile( ) (copy version) locatord( ),
              and locators( ) added.
1999 Jan 28 - Nicholas Elias, USNO/NPOI
              Public member function clone( ) added.
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member functions get( ) and put( ) eliminated.  Public
	      member functions create_byte( ), create_char( ), create_double( ),
	      create_integer( ), create_logical( ), create_real( ),
	      create_ubyte( ), create_uword( ), create_word( ), get_byte( ),
	      get_char( ), get_double( ), get_integer( ), get_logical( ),
	      get_real( ), get_ubyte( ), get_uword( ), get_word( ),
	      obtain_byte( ), obtain_char( ), obtain_double( ),
	      obtain_integer( ), obtain_logical( ), obtain_real( ),
	      obtain_ubyte( ), obtain_uword( ), obtain_word( ), put_byte( ),
	      put_char( ), put_double( ), put_integer( ), put_logical( ),
	      put_real( ), put_ubyte( ), put_uword( ), and put_word( ) added.
1999 Feb 14 - Nicholas Elias, USNO/NPOI
              Public member functions Goto( ), recover( ), and version( ) added.
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member functions screate_byte( ), screate_char( ),
              screate_double( ), screate_integer( ), screate_logical( ),
              screate_real( ), screate_ubyte( ), screate_uword( ), and
              screate_word( ) added.
2000 Aug 29 - Nicholas Elias, USNO/NPOI
              Static public member functions locatorMax( ), noLocator( ),
              sizeLocator( ), sizeMode( ), sizeName( ), and sizeType( ) added.
2000 Aug 31 - Nicholas Elias, USNO/NPOI
              Public member functions checkSlice( ) and numDim( ) added. 
              Static public member function dimMax( ) added.
2001 May 30 - Nicholas Elias, USNO/NPOI
              Public member function checkSameSlice( ) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include <casa/iostream.h>
#include <npoi/HDS/HDSFile.h> // HDS file

// -----------------------------------------------------------------------------

/*

HDSFile::HDSFile (hds_new)

Description:
------------
This public member function constructs the HDSFile{ } object.

Inputs:
-------
oAccessIn - The HDS access (file and mode).
oNameIn   - The HDS locator name.
oTypeIn   - The HDS locator type.
oDimIn    - The HDS locator dimensions.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSFile::HDSFile( const HDSAccess& oAccessIn, const HDSName& oNameIn,
    const HDSType& oTypeIn, const HDSDim& oDimIn ) : GeneralStatus(),
    uiLocator( 0 ) {

  // Declare the local variables

  HDSDim* poDimTemp; // The temporary HDS dimension object


  // Check the inputs

  if ( !oAccessIn.mode().matches( "NEW" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "HDSFile" ) );
  }


  // Initialize the private variable pointers

  poAccess = new HDSAccess( oAccessIn );

  poLocatorSave = new HDSLocator();
  aoLocator = new HDSLocator[NUM_LOCATOR_MAX + 1];
  
  
  // Create the HDS file and get its locator
  
  poDimTemp = new HDSDim( oDimIn );
  
  uiLocator += 1;

  HDSWrapper::hds_new( (const char* const) poAccess->file().chars(),
      (const char* const) oNameIn.chars(), (const char* const) oTypeIn.chars(),
      (const int) poDimTemp->nelements(), (const int* const) poDimTemp->ppdim(),
      (char* const) aoLocator[uiLocator].ploc(),
      (int* const) aoLocator[uiLocator].pstatus() );
  
  if ( aoLocator[uiLocator].status() != OK ) {
    delete poAccess;
    delete poLocatorSave;
    delete [] aoLocator;
    throw( ermsg( "HDSWrapper::hds_new( ) error", "HDSFile", "HDSFile" ) );
  }
  
  
  // Lock the HDS file
  
  try {
    poAccess->setinode();
  }
  
  catch ( AipsError oAipsError ) {
    delete poAccess;
    delete poLocatorSave;
    delete [] aoLocator;
    throw( ermsg( "HDSAccess::setinode( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "HDSFile" ) );
  }
  
//  if ( flock( poAccess->inode(), LOCK_EX ) != 0 ) {
//    delete poAccess;
//    delete poLocatorSave;
//    delete [] aoLocator;
//    throw( ermsg( "Cannot lock HDS file", "HDSFile", "HDSFile" ) );
//  }
  
  
  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

HDSFile::HDSFile (hds_open)

Description:
------------
This public member function constructs the HDSFile{ } object.

Inputs:
-------
oAccessIn - The HDS access (file and mode).

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSFile::HDSFile( const HDSAccess& oAccessIn ) : GeneralStatus(),
    uiLocator( 0 ) {

  // Check the inputs

  if ( oAccessIn.mode().matches( "NEW" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "HDSFile" ) );
  }


  // Initialize the private variable pointers

  poAccess = new HDSAccess( oAccessIn );

  poLocatorSave = new HDSLocator();
  aoLocator = new HDSLocator[NUM_LOCATOR_MAX + 1];


  // Open the HDS file and get its locator
  
  uiLocator += 1;

  HDSWrapper::hds_open( (const char* const) poAccess->file().chars(),
      (const char* const) poAccess->mode().chars(),
      (char* const) aoLocator[uiLocator].ploc(),
      (int* const) aoLocator[uiLocator].pstatus() );
  
  if ( aoLocator[uiLocator].status() != OK ) {
    delete poAccess;
    delete poLocatorSave;
    delete [] aoLocator;
    throw( ermsg( "HDSWrapper::hds_open( ) error", "HDSFile", "HDSFile" ) );
  }
  
  
  // Lock the HDS file
  
//  if ( flock( poAccess->inode(), LOCK_EX ) != 0 ) {
//    delete poAccess;
//    delete poLocatorSave;
//    delete [] aoLocator;
//    throw( ermsg( "Cannot lock HDS file", "HDSFile", "HDSFile" ) );
//  }
  
  
  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

HDSFile::HDSFile (copy)

Description:
------------
This public member function copies the HDSFile{ } object.

Inputs:
-------
oFileIn - The HDSFile{ } object.

Outputs:
--------
None.

Modification history:
---------------------
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSFile::HDSFile( const HDSFile& oFileIn ) : GeneralStatus() {
  
  // Initialize the private variables
  
  poAccess = new HDSAccess( oFileIn.file(), oFileIn.mode() );
  
  poLocatorSave = new HDSLocator();
  
  HDSWrapper::dat_clone( (const char* const) oFileIn.locators().pploc(),
      (char* const) poLocatorSave->ploc(),
      (int* const) poLocatorSave->pstatus() );
      
  if ( poLocatorSave->status() != OK ) {
    delete poAccess;
    delete poLocatorSave;
    throw( ermsg( "HDSWrapper::dat_clone() error", "HDSFile", "HDSFile" ) );
  }
  
  aoLocator = new HDSLocator[NUM_LOCATOR_MAX + 1];
  
  memcpy( (void*) aoLocator[0].ploc(), (const void*) NOLOC, (size_t) SZLOC );
  
  for ( uiLocator = 1; uiLocator <= oFileIn.locator(); uiLocator++ ) {
    HDSWrapper::dat_clone(
        (const char* const) oFileIn.locatord( uiLocator ).pploc(),
        (char* const) aoLocator[uiLocator].ploc(),
	(int* const) aoLocator[uiLocator].pstatus() );
    if ( aoLocator[uiLocator].status() != OK ) {
      delete poAccess;
      delete poLocatorSave;
      delete [] aoLocator;
      throw( ermsg( "HDSWrapper::dat_clone() error", "HDSFile", "HDSFile" ) );
    }
  }
  
  for ( uiLocator = oFileIn.locator() + 1; uiLocator <= NUM_LOCATOR_MAX;
      uiLocator++ ) {
    memcpy( (void*) aoLocator[uiLocator].ploc(), (const void*) NOLOC,
        (size_t) SZLOC );
  }

  uiLocator = oFileIn.locator();
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::~HDSFile

Description:
------------
This public member function destructs the HDSFile{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSFile::~HDSFile( void ) {

  // Unlock the file

//  if ( flock( poAccess->inode(), LOCK_UN ) ) {
//    ermsg( "Cannot unlock HDS file", "HDSFile", "~HDSFile" );
//  }
    

  // Annul all HDS locators except the top one
  
  try{
    if ( uiLocator > 1 ) {
      top();
    }
  }
  
  catch ( AipsError oAipsError ) {
    ermsg( "top( ) error" + oAipsError.getMesg(), "HDSFile", "~HDSFile" );
  }
  
  
  // Annul the top HDS locator to close the file

  if ( aoLocator[uiLocator].status() == OK ) {
    HDSWrapper::dat_annul( (char* const) aoLocator[uiLocator].ploc(),
        (int* const) aoLocator[uiLocator].pstatus() );
    if ( aoLocator[uiLocator].status() != OK ) {
      ermsg( "HDSWrapper::dat_annul( ) error (top locator)", "HDSFile",
          "~HDSFile" );
    }
  }


  // Deallocate the memory and return

  delete poAccess;

  delete poLocatorSave;
  delete [] aoLocator;

  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::alter

Description:
------------
This public member function alters the last dimension of the present HDS locator.

Inputs:
-------
uiLastDim - The new HDS locator last dimension.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::alter( const uInt& uiLastDim ) {

  // Declare the local variables
  
  Bool bPrim;           // The HDS locator primitive flag
  Bool bValid;          // The HDS locator validity flag
  
  HDSDim* poDim = NULL; // The HDS locator dimensions
  

  // Check the access mode, present HDS status, and locator

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "alter" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "alter" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "alter" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "alter" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "alter" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "alter" ) );
  }

  try {
    poDim = new HDSDim( shape() );
  }
  
  catch ( AipsError oAipsError ) {
    if ( poDim != NULL ) {
      delete poDim;
    }
    throw( ermsg( "HDSDim{ } or shape() error\n" + oAipsError.getMesg(),
        "HDSFile", "alter" ) );
  }
  
  if ( poDim->nelements() < 1 ) {
    delete poDim;
    throw( ermsg( "Cannot alter an HDS scalar locator", "HDSFile", "alter" ) );
  }
  
  delete poDim;


  // Check the inputs

  if ( uiLastDim < 1 ) {
    throw( ermsg( "Invalid HDS locator last dimension", "HDSFile", "alter" ) );
  }


  // Alter the last dimension of the HDS locator and return
  
  try {
    aoLocator[uiLocator].alter( uiLastDim );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::alter( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "alter" ) );
  }

  return;
      
}

// -----------------------------------------------------------------------------

/*

HDSFile::annul

Description:
------------
This public member function annuls one or more HDS locators.

Inputs:
-------
uiLocatorAnnul - The number of HDS locators to annul.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::annul( const uInt& uiLocatorAnnul ) {

  // Declare the local variables
  
  Bool bValid;         // The HDS locator validity flag
  
  uInt uiLocatorLocal; // The HDSLocator{ } counter

  Int iLocatorDelta;   // The difference between the present number of HDS
                       // locators and the number of HDS locators to annul
  

  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "annul" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "annul" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "annul" ) );
  }
  
  
  // Check the HDS locator number and inputs

  iLocatorDelta = ( (Int) uiLocator ) - ( (Int) uiLocatorAnnul );

  if ( iLocatorDelta < 1 ) {
    throw( ermsg( "Not enough HDS locators to annul", "HDSFile", "annul" ) );
  }
  
  
  // Annul the HDS locator(s)
  
  for ( uiLocatorLocal = 0; uiLocatorLocal < uiLocatorAnnul;
      uiLocatorLocal++ ) {

    HDSWrapper::dat_annul( (char* const) aoLocator[uiLocator].ploc(),
        (int* const) aoLocator[uiLocator].pstatus() );
    
    uiLocator -= 1;
    
    if ( aoLocator[uiLocator].status() != OK ) {
      ermsg( "HDSWrapper::dat_annul( ) error", "HDSFile", "annul" );
      if ( uiLocatorLocal < ( uiLocatorAnnul - 1 ) ) {
        aoLocator[uiLocator].recover();
      }
    }
    
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::cell

Description:
------------
This public member function "cells" into an HDS locator.

Inputs:
-------
oDimIn - The HDS locator cell.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::cell( const HDSDim& oDimIn ) {

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "cell" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "cell" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "cell" ) );
  }


  // Check the HDS locator number
  
  if ( uiLocator >= NUM_LOCATOR_MAX ) {
    throw( ermsg( "Maximum number of HDS locators reached", "HDSFile",
        "cell" ) );
  }

  
  // "Cell" into the HDS locator and get its locator
  
  HDSWrapper::dat_cell( (const char* const) aoLocator[uiLocator].ploc(),
      (const int) oDimIn.nelements(), (const int* const) oDimIn.ppdim(),
      (char* const) aoLocator[uiLocator + 1].ploc(),
      (int* const) aoLocator[uiLocator + 1].pstatus() );
  
  if ( aoLocator[uiLocator + 1].status() != OK ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "HDSWrapper::dat_cell( ) error", "HDSFile", "cell" ) );
  }
  
  uiLocator += 1;
  
  
  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

HDSFile::clen

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
1998 Nov 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::clen( void ) const {

  // Declare the local variables

  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "clen" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "clen" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "clen" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "clen" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "clen" ) );
  }


  // Get and return the HDS locator character length
  
  try {
    return( aoLocator[uiLocator].clen() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::clen( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "clen" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::clone

Description:
------------
This public member function clones the present HDS locator (as an
HDSLocator{ }).

Inputs:
-------
None.

Outputs:
--------
The HDS locator (as an HDSLocator{ }), returned via the function value.

Modification history:
---------------------
1999 Jan 28 - Nicholas Elias, USNO/NPOI
              Piblic member function created.

*/

// -----------------------------------------------------------------------------

HDSLocator HDSFile::clone( void ) const {

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "clone" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "clone" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "clone" ) );
  }
  
  
  // Return the HDS locator as an HDSLocator{ }

  return( aoLocator[uiLocator] );

}

// -----------------------------------------------------------------------------

/*

HDSFile::copy

Description:
------------
This public member function recursively copies the present HDS locator to the
saved HDS locator (see HDSFile::save( ) ) in the present object or in another
object (need the result of id() ).

Inputs:
-------
oNameIn - The HDS locator name.
poFile  - The HDSFile{ } pointer to the other object (default = NULL).

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::copy( const HDSName& oNameIn, HDSFile* poFile ){

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access modes

  if ( poFile == NULL ) {
    if ( poAccess->mode().matches( "READ" ) ) {
      throw( ermsg( "Invalid HDS access mode", "HDSFile", "copy" ) );
    }
  } else {
    if ( poFile->mode().matches( "READ" ) ) {
      throw( ermsg( "Invalid HDS access mode", "HDSFile", "copy" ) );
    }
  }


  // Check the present HDS status and locator
  
  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "copy" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "copy" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "copy" ) );
  }


  // Check the saved HDS status and locator

  if ( poFile == NULL ) {  
  
    if ( poLocatorSave->status() != OK ) {
      throw( ermsg( "Error associated with saved HDS locator", "HDSFile",
          "copy" ) );
    }

    try {
      bValid = poLocatorSave->valid();
    }
  
    catch ( AipsError oAipsError ) {
      throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
          "copy" ) );
    }
  
    if ( !bValid ) {
      throw( ermsg( "Invalid saved HDS locator", "HDSFile", "copy" ) );
    }
    
  } else {
  
    if ( poFile->locators().status() != OK ) {
      throw( ermsg( "Error associated with other HDS locator", "HDSFile",
          "copy" ) );
    }

    try {
      bValid = poFile->valid();
    }
  
    catch ( AipsError oAipsError ) {
      throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
          "copy" ) );
    }
  
    if ( !bValid ) {
      throw( ermsg( "Invalid other HDS locator", "HDSFile", "copy" ) );
    }
      
  }
  
  
  // Compare the present and saved HDS locators
  
  if ( poFile == NULL ) {
    
    if ( !memcmp( (const void*) aoLocator[uiLocator].ploc(),
         (const void*) poLocatorSave->pploc(), (size_t) SZLOC ) ) {
      throw( ermsg( "Indentical present/saved HDS locators", "HDSFile",
          "copy" ) );
    }
    
  } else {
    
    if ( !memcmp( (const void*) aoLocator[uiLocator].ploc(),
         (const void*) poFile->locators().pploc(), (size_t) SZLOC ) ) {
      throw( ermsg( "Indentical present/saved HDS locators", "HDSFile",
          "copy" ) );
    }
    
  }

  
  // Recursively copy the HDS locator(s)

  if ( poFile == NULL ) {
    HDSWrapper::dat_copy( (const char* const) aoLocator[uiLocator].ploc(),
        (const char* const) poLocatorSave->pploc(),
        (const char* const) oNameIn.chars(),
	(int* const) poLocatorSave->pstatus() );
    if ( poLocatorSave->status() != OK ) {
      poLocatorSave->recover();
      throw( ermsg( "HDSWrapper::dat_copy( ) error", "HDSFile", "copy" ) );
    }
  } else {
    HDSWrapper::dat_copy( (const char* const) aoLocator[uiLocator].ploc(),
        (const char* const) poFile->locators().pploc(),
        (const char* const) oNameIn.chars(),
	(int* const) poFile->locators().pstatus() );
    if ( poFile->locators().status() != OK ) {
      poFile->locators().recover();
      throw( ermsg( "HDSWrapper::dat_copy( ) error", "HDSFile", "copy" ) );
    }
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::copy2file

Description:
------------
This public member function recursively copies the present HDS locator to
another HDS file.

Inputs:
-------
oAccessIn - The HDS access (file and mode).
oNameIn   - The HDS locator name.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::copy2file( const HDSAccess& oAccessIn, const HDSName& oNameIn ) {

  // Declare the local variables
  
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the inputs

  if ( oAccessIn.mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "copy2file" ) );
  }
  

  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "copy2file" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "copy2file" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "copy2file" ) );
  }
  
  
  // Recursively copy the HDS locator(s) to a new file

  HDSWrapper::hds_copy( (const char* const) aoLocator[uiLocator].ploc(),
      (const char* const) oAccessIn.file().chars(),
      (const char* const) oNameIn.chars(),
      (int* const) aoLocator[uiLocator].pstatus() );

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "HDSWrapper::hds_copy( ) error", "HDSFile", "copy2file" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::create_byte

Description:
------------
This public member function creates a new _BYTE HDS locator and puts a data array
into it.

Inputs:
-------
oNameIn  - The HDS locator name.
oArray   - The data array.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::create_byte( const HDSName& oNameIn, const Array<Int>& oArray,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "create_byte" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "create_byte" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_byte" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "create_byte" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_byte" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "create_byte" ) );
  }
  
  
  // Create the _BYTE HDS locator and put the data array into it
  
  try {
    New( oNameIn, HDSType( "_BYTE" ), HDSDim( oArray.shape().asVector() ),
        bReplace );
    find( oNameIn );
    put_byte( oArray );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _BYTE HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "create_byte" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::create_char

Description:
------------
This public member function creates a new _CHAR*N HDS locator and puts a data
array into it.

Inputs:
-------
oNameIn  - The HDS locator name.
uiLength - The HDS locator element length.
oArray   - The data array.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::create_char( const HDSName& oNameIn, const uInt& uiLength,
    const Array<String>& oArray, const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc;                     // The HDS locator structure flag
  Bool bValid;                     // The HDS locator validity flag
  
  Char acType[HDSName::SZNAM + 1]; // The HDS locator type
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "create_char" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "create_char" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_char" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "create_char" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_char" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "create_char" ) );
  }
  
  
  // Create the _CHAR*N HDS locator and put the data array into it
  
  try {
    sprintf( acType, "_CHAR*%d", (int) uiLength );
    New( oNameIn, HDSType( acType ), HDSDim( oArray.shape().asVector() ),
        bReplace );
    find( oNameIn );
    put_char( oArray );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _CHAR*N HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "create_char" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::create_double

Description:
------------
This public member function creates a new _DOUBLE HDS locator and puts a data
array into it.

Inputs:
-------
oNameIn  - The HDS locator name.
oArray   - The data array.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::create_double( const HDSName& oNameIn,
    const Array<Double>& oArray, const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "create_double" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "create_double" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_double" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile",
        "create_double" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_double" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "create_double" ) );
  }
  
  
  // Create the _DOUBLE HDS locator and put the data array into it
  
  try {
    New( oNameIn, HDSType( "_DOUBLE" ), HDSDim( oArray.shape().asVector() ),
        bReplace );
    find( oNameIn );
    put_double( oArray );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _DOUBLE HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "create_double" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::create_integer

Description:
------------
This public member function creates a new _INTEGER HDS locator and puts a data
array into it.

Inputs:
-------
oNameIn  - The HDS locator name.
oArray   - The data array.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::create_integer( const HDSName& oNameIn, const Array<Int>& oArray,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "create_integer" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "create_integer" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_integer" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile",
        "create_integer" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_integer" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "create_integer" ) );
  }
  
  
  // Create the _INTEGER HDS locator and put the data array into it
  
  try {
    New( oNameIn, HDSType( "_INTEGER" ), HDSDim( oArray.shape().asVector() ),
        bReplace );
    find( oNameIn );
    put_integer( oArray );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg(
        "Error creating _INTEGER HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "create_integer" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::create_logical

Description:
------------
This public member function creates a new _LOGICAL HDS locator and puts a data
array into it.

Inputs:
-------
oNameIn  - The HDS locator name.
oArray   - The data array.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::create_logical( const HDSName& oNameIn, const Array<Bool>& oArray,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "create_logical" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "create_logical" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_logical" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile",
        "create_logical" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_logical" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "create_logical" ) );
  }
  
  
  // Create the _LOGICAL HDS locator and put the data array into it
  
  try {
    New( oNameIn, HDSType( "_LOGICAL" ), HDSDim( oArray.shape().asVector() ),
        bReplace );
    find( oNameIn );
    put_logical( oArray );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg(
        "Error creating _LOGICAL HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "create_logical" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::create_real

Description:
------------
This public member function creates a new _REAL HDS locator and puts a data
array into it.

Inputs:
-------
oNameIn  - The HDS locator name.
oArray   - The data array.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::create_real( const HDSName& oNameIn, const Array<Float>& oArray,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "create_real" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "create_real" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_real" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "create_real" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_real" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "create_real" ) );
  }
  
  
  // Create the _REAL HDS locator and put the data array into it
  
  try {
    New( oNameIn, HDSType( "_REAL" ), HDSDim( oArray.shape().asVector() ),
        bReplace );
    find( oNameIn );
    put_real( oArray );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _REAL HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "create_real" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::create_ubyte

Description:
------------
This public member function creates a new _UBYTE HDS locator and puts a data
array into it.

Inputs:
-------
oNameIn  - The HDS locator name.
oArray   - The data array.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::create_ubyte( const HDSName& oNameIn, const Array<Int>& oArray,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "create_ubyte" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "create_ubyte" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_ubyte" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "create_ubyte" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_ubyte" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "create_ubyte" ) );
  }
  
  
  // Create the _UBYTE HDS locator and put the data array into it
  
  try {
    New( oNameIn, HDSType( "_UBYTE" ), HDSDim( oArray.shape().asVector() ),
        bReplace );
    find( oNameIn );
    put_ubyte( oArray );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _UBYTE HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "create_ubyte" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::create_uword

Description:
------------
This public member function creates a new _UWORD HDS locator and puts a data
array into it.

Inputs:
-------
oNameIn  - The HDS locator name.
oArray   - The data array.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::create_uword( const HDSName& oNameIn, const Array<Int>& oArray,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "create_uword" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "create_uword" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_uword" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "create_uword" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_uword" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "create_uword" ) );
  }
  
  
  // Create the _UWORD HDS locator and put the data array into it
  
  try {
    New( oNameIn, HDSType( "_UWORD" ), HDSDim( oArray.shape().asVector() ),
        bReplace );
    find( oNameIn );
    put_uword( oArray );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _UWORD HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "create_uword" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::create_word

Description:
------------
This public member function creates a new _WORD HDS locator and puts a data
array into it.

Inputs:
-------
oNameIn  - The HDS locator name.
oArray   - The data array.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::create_word( const HDSName& oNameIn, const Array<Int>& oArray,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "create_word" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "create_word" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_word" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "create_word" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "create_word" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "create_word" ) );
  }
  
  
  // Create the _WORD HDS locator and put the data array into it
  
  try {
    New( oNameIn, HDSType( "_WORD" ), HDSDim( oArray.shape().asVector() ),
        bReplace );
    find( oNameIn );
    put_word( oArray );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _WORD HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "create_word" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::erase

Description:
------------
This public member function erases an HDS locator.

Inputs:
-------
oNameIn - The HDS locator name.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::erase( const HDSName& oNameIn ) {

  // Declare the local variables

  Bool bThere; // The HDS locator existence flag
  Bool bValid; // The HDS locator validity flag


  // Check the access mode, present HDS status, and locator

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "erase" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "erase" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "erase" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "erase" ) );
  }
  
  
  // Check the HDS locator number and inputs
  
  if ( uiLocator >= NUM_LOCATOR_MAX ) {
    throw( ermsg( "Maximum number of HDS locators reached", "HDSFile",
        "erase" ) );
  }
  
  try {
    bThere = there( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "erase" ) );
  }
  
  if ( !bThere ) {
    throw( ermsg( "Nonexistent HDS locator", "HDSFile", "erase" ) );
  }
  
  
  // Erase the HDS locator
  
  HDSWrapper::dat_erase( (const char* const) aoLocator[uiLocator].ploc(),
      (const char* const) oNameIn.chars(),
      (int* const) aoLocator[uiLocator].pstatus() );
  
  if ( aoLocator[uiLocator].status() != OK ) {
    aoLocator[uiLocator].on();
    throw( ermsg( "HDSWrapper::dat_erase( ) error", "HDSFile", "erase" ) );
  }
  
  
  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

HDSFile::file

Description:
------------
This public member function returns the HDS file name.

Inputs:
-------
None.

Outputs:
--------
The HDS file name, returned via the function value.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String HDSFile::file( void ) const {

  // Return the HDS file name

  return( poAccess->file() );

}

// -----------------------------------------------------------------------------

/*

HDSFile::find

Description:
------------
This public member function finds an HDS locator.

Inputs:
-------
oNameIn - The HDS locator name.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::find( const HDSName& oNameIn ) {

  // Declare the local variables

  Bool bThere; // The HDS locator existence flag
  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "find" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "find" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "find" ) );
  }

  
  // Check the HDS locator number and inputs
  
  if ( uiLocator >= NUM_LOCATOR_MAX ) {
    throw( ermsg( "Maximum number of HDS locators reached", "HDSFile",
        "find" ) );
  }

  try {
    bThere = there( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "find" ) );
  }
  
  if ( !bThere ) {
    throw( ermsg( "Nonexistent HDS locator", "HDSFile", "find" ) );
  }
  
  
  // Find the HDS locator and get its locator
  
  HDSWrapper::dat_find( (const char* const) aoLocator[uiLocator].ploc(),
      (const char* const) oNameIn.chars(),
      (char* const) aoLocator[uiLocator + 1].ploc(),
      (int* const) aoLocator[uiLocator + 1].pstatus() );
  
  if ( aoLocator[uiLocator + 1].status() != OK ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "HDSWrapper::dat_find( ) error", "HDSFile", "find" ) );
  }
  
  uiLocator += 1;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

get_byte

Description:
------------
This public member function gets a data array from a _BYTE HDS locator.

Inputs:
-------
None.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Int> HDSFile::get_byte() const {

  // Declare the local variables
  
  Bool bPrim;             // The HDS locator primitive flag
  Bool bValid;            // The HDS locator validity flag

  uInt uiDim;             // The HDS locator dimension counter
  uInt uiElement;         // The HDS locator element counter
  
  Char* acData = NULL;    // The data block
  
  Int* aiData;            // The Int version of the data array
  
  IPosition* poIPosition; // The aips++ IPosition{ } object


  // Check the present HDS status, locator, and primitive flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "get_byte" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_byte" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "get_byte" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_byte" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "get_byte" ) );
  }
  
  
  // Create the aips++ IPosition{ } object

  try {
    uInt uiNumDim = numDim();
    HDSDim oShape = HDSDim( shape() );
    if ( uiNumDim > 0 ) {
      poIPosition = new IPosition( uiNumDim );
      for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
        (*poIPosition)(uiDim) = oShape(uiDim);
      }
    } else {
      poIPosition = new IPosition( 1, 1 );
    }
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "shape( ) and/or IPosition{ } error\n" + oAipsError.getMesg(),
        "HDSFile", "get_byte" ) );
  }
  
  
  // Get the data block and place it into the aips++ Array<Int> data array

  try {
    aoLocator[uiLocator].get( (uChar**) &acData );
  }
  
  catch ( AipsError oAipsError ) {
    if ( acData != NULL ) {
      delete [] acData;
    }
    throw( ermsg( "get( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_byte" ) );
  }
  
  aiData = new Int[poIPosition->product()];
  
  for ( uiElement = 0; uiElement < (uInt) poIPosition->product();
      uiElement++ ) {
    aiData[uiElement] = (Int) acData[uiElement];
  }
  
  Array<Int> oArray = Array<Int>( *poIPosition, (const Int*) aiData );
  
  
  // Free the memory
  
  delete poIPosition;
  
  delete [] acData;
  delete [] aiData;
  
  
  // Return the data array
  
  return( oArray );

}

// -----------------------------------------------------------------------------

/*

get_char

Description:
------------
This public member function gets a data array from a _CHAR*N HDS locator.

Inputs:
-------
None.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<String> HDSFile::get_char() const {

  // Declare the local variables
  
  Bool bPrim;             // The HDS locator primitive flag
  Bool bValid;            // The HDS locator validity flag

  uInt uiDim;             // The HDS locator dimension counter
  uInt uiElement;         // The HDS locator element counter
  uInt uiLength;          // The HDS locator length
  
  uChar* aucData = NULL;  // The data block
  uChar* aucDataTemp;     // The temporary pointer to the data block
  
  String* aoData;         // The String version of the data array
  
  IPosition* poIPosition; // The aips++ IPosition{ } object


  // Check the present HDS status, locator, and primitive flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "get_char" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_char" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "get_char" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_char" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "get_char" ) );
  }
  
  
  // Create the aips++ IPosition{ } object

  try {
    uInt uiNumDim = numDim();
    HDSDim oShape = HDSDim( shape() );
    if ( uiNumDim > 0 ) {
      poIPosition = new IPosition( uiNumDim );
      for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
        (*poIPosition)(uiDim) = oShape(uiDim);
      }
    } else {
      poIPosition = new IPosition( 1, 1 );
    }
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "shape( ) and/or IPosition{ } error\n" + oAipsError.getMesg(),
        "HDSFile", "get_char" ) );
  }
  
  
  // Get the data block and place it into the aips++ Array<String> data array

  try {
    aoLocator[uiLocator].get( (uChar**) &aucData );
  }
  
  catch ( AipsError oAipsError ) {
    if ( aucData != NULL ) {
      delete [] aucData;
    }
    throw( ermsg( "get( ) error" + oAipsError.getMesg(), "HDSFile",
        "get_char" ) );
  }
  
  try {
    uiLength = (uInt) len();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "len( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_char" ) );
  }
  
  aucDataTemp = aucData;
  aoData = new String[poIPosition->product()];
  
  for ( uiElement = 0; uiElement < (uInt) poIPosition->product();
      uiElement++ ) {
    aoData[uiElement] = String( (const char*) aucDataTemp, (int) uiLength );
    aucDataTemp += uiLength;
  }
  
  Array<String> oArray = Array<String>( *poIPosition, (String*) aoData );
  
  
  // Free the memory
  
  delete poIPosition;
  
  delete [] aucData;
  delete [] aoData;
  
  
  // Return the data array
  
  return( oArray );

}

// -----------------------------------------------------------------------------

/*

get_double

Description:
------------
This public member function gets a data array from a _DOUBLE HDS locator.

Inputs:
-------
None.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Double> HDSFile::get_double() const {

  // Declare the local variables
  
  Bool bPrim;             // The HDS locator primitive flag
  Bool bValid;            // The HDS locator validity flag

  uInt uiDim;             // The HDS locator dimension counter
  
  Double* adData = NULL;  // The data block
  
  IPosition* poIPosition; // The aips++ IPosition{ } object


  // Check the present HDS status, locator, and primitive flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "get_double" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_double" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "get_double" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_double" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile",
        "get_double" ) );
  }
  
  
  // Create the aips++ IPosition{ } object

  try {
    uInt uiNumDim = numDim();
    HDSDim oShape = HDSDim( shape() );
    if ( uiNumDim > 0 ) {
      poIPosition = new IPosition( uiNumDim );
      for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
        (*poIPosition)(uiDim) = oShape(uiDim);
      }
    } else {
      poIPosition = new IPosition( 1, 1 );
    }
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "shape( ) and/or IPosition{ } error\n" + oAipsError.getMesg(),
        "HDSFile", "get_double" ) );
  }
  
  
  // Get the data block and place it into the aips++ Array<Double> data array

  try {
    aoLocator[uiLocator].get( (uChar**) &adData );
  }
  
  catch ( AipsError oAipsError ) {
    if ( adData != NULL ) {
      delete [] adData;
    }
    throw( ermsg( "get( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_double" ) );
  }
  
  Array<Double> oArray = Array<Double>( *poIPosition, (const Double*) adData );
  
  
  // Free the memory
  
  delete poIPosition;

  delete [] adData;
  
  
  // Return the data array
  
  return( oArray );

}

// -----------------------------------------------------------------------------

/*

get_integer

Description:
------------
This public member function gets a data array from an _INTEGER HDS locator.

Inputs:
-------
None.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Int> HDSFile::get_integer() const {

  // Declare the local variables
  
  Bool bPrim;             // The HDS locator primitive flag
  Bool bValid;            // The HDS locator validity flag

  uInt uiDim;             // The HDS locator dimension counter
  
  Int* aiData = NULL;     // The data block
  
  IPosition* poIPosition; // The aips++ IPosition{ } object


  // Check the present HDS status, locator, and primitive flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "get_integer" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_integer" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "get_integer" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_integer" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile",
        "get_integer" ) );
  }
  
  
  // Create the aips++ IPosition{ } object

  try {
    uInt uiNumDim = numDim();
    HDSDim oShape = HDSDim( shape() );
    if ( uiNumDim > 0 ) {
      poIPosition = new IPosition( uiNumDim );
      for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
        (*poIPosition)(uiDim) = oShape(uiDim);
      }
    } else {
      poIPosition = new IPosition( 1, 1 );
    }
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "shape( ) and/or IPosition{ } error\n" + oAipsError.getMesg(),
        "HDSFile", "get_integer" ) );
  }
  
  
  // Get the data block and place it into the aips++ Array<Int> data array

  try {
    aoLocator[uiLocator].get( (uChar**) &aiData );
  }
  
  catch ( AipsError oAipsError ) {
    if ( aiData != NULL ) {
      delete [] aiData;
    }
    throw( ermsg( "get( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_integer" ) );
  }
  
  Array<Int> oArray = Array<Int>( *poIPosition, (const Int*) aiData );
  
  
  // Free the memory
  
  delete poIPosition;

  delete [] aiData;
  
  
  // Return the data array
  
  return( oArray );

}

// -----------------------------------------------------------------------------

/*

get_logical

Description:
------------
This public member function gets a data array from a _LOGICAL HDS locator.

Inputs:
-------
None.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Bool> HDSFile::get_logical() const {

  // Declare the local variables
  
  Bool bPrim;             // The HDS locator primitive flag
  Bool bValid;            // The HDS locator validity flag

  uInt uiDim;             // The HDS locator dimension counter
  
  Bool* abData = NULL;    // The data block
  
  IPosition* poIPosition; // The aips++ IPosition{ } object


  // Check the present HDS status, locator, and primitive flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "get_logical" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_logical" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "get_logical" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_logical" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile",
        "get_logical" ) );
  }
  
  
  // Create the aips++ IPosition{ } object

  try {
    uInt uiNumDim = numDim();
    HDSDim oShape = HDSDim( shape() );
    if ( uiNumDim > 0 ) {
      poIPosition = new IPosition( uiNumDim );
      for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
        (*poIPosition)(uiDim) = oShape(uiDim);
      }
    } else {
      poIPosition = new IPosition( 1, 1 );
    }
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "shape( ) and/or IPosition{ } error\n" + oAipsError.getMesg(),
        "HDSFile", "get_logical" ) );
  }
  
  
  // Get the data block and place it into the aips++ Array<Bool> data array

  try {
    aoLocator[uiLocator].get( (uChar**) &abData );
  }
  
  catch ( AipsError oAipsError ) {
    if ( abData != NULL ) {
      delete [] abData;
    }
    throw( ermsg( "get( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_logical" ) );
  }
  
  Array<Bool> oArray = Array<Bool>( *poIPosition, (const Bool*) abData );
  
  
  // Free the memory
  
  delete poIPosition;

  delete [] abData;
  
  
  // Return the data array
  
  return( oArray );

}

// -----------------------------------------------------------------------------

/*

get_real

Description:
------------
This public member function gets a data array from a _REAL HDS locator.

Inputs:
-------
None.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Float> HDSFile::get_real() const {

  // Declare the local variables
  
  Bool bPrim;             // The HDS locator primitive flag
  Bool bValid;            // The HDS locator validity flag

  uInt uiDim;             // The HDS locator dimension counter
  
  Float* afData = NULL;   // The data block
  
  IPosition* poIPosition; // The aips++ IPosition{ } object


  // Check the present HDS status, locator, and primitive flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "get_real" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_real" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "get_real" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_real" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "get_real" ) );
  }
  
  
  // Create the aips++ IPosition{ } object

  try {
    uInt uiNumDim = numDim();
    HDSDim oShape = HDSDim( shape() );
    if ( uiNumDim > 0 ) {
      poIPosition = new IPosition( uiNumDim );
      for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
        (*poIPosition)(uiDim) = oShape(uiDim);
      }
    } else {
      poIPosition = new IPosition( 1, 1 );
    }
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "shape( ) and/or IPosition{ } error\n" + oAipsError.getMesg(),
        "HDSFile", "get_real" ) );
  }
  
  
  // Get the data block and place it into the aips++ Array<Float> data array

  try {
    aoLocator[uiLocator].get( (uChar**) &afData );
  }
  
  catch ( AipsError oAipsError ) {
    if ( afData != NULL ) {
      delete [] afData;
    }
    throw( ermsg( "get( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_real" ) );
  }
  
  Array<Float> oArray = Array<Float>( *poIPosition, (const Float*) afData );
  
  
  // Free the memory
  
  delete poIPosition;

  delete [] afData;
  
  
  // Return the data array
  
  return( oArray );

}

// -----------------------------------------------------------------------------

/*

get_ubyte

Description:
------------
This public member function gets a data array from a _UBYTE HDS locator.

Inputs:
-------
None.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Int> HDSFile::get_ubyte() const {

  // Declare the local variables
  
  Bool bPrim;             // The HDS locator primitive flag
  Bool bValid;            // The HDS locator validity flag

  uInt uiDim;             // The HDS locator dimension counter
  uInt uiElement;         // The HDS locator element counter
  
  uChar* aucData = NULL;  // The data block
  
  Int* aiData;            // The Int version of the data array
  
  IPosition* poIPosition; // The aips++ IPosition{ } object


  // Check the present HDS status, locator, and primitive flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "get_ubyte" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_ubyte" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "get_ubyte" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_ubyte" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile",
        "get_ubyte" ) );
  }
  
  
  // Create the aips++ IPosition{ } object

  try {
    uInt uiNumDim = numDim();
    HDSDim oShape = HDSDim( shape() );
    if ( uiNumDim > 0 ) {
      poIPosition = new IPosition( uiNumDim );
      for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
        (*poIPosition)(uiDim) = oShape(uiDim);
      }
    } else {
      poIPosition = new IPosition( 1, 1 );
    }
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "shape( ) and/or IPosition{ } error\n" + oAipsError.getMesg(),
        "HDSFile", "get_ubyte" ) );
  }
  
  
  // Get the data block and place it into the aips++ Array<Int> data array

  try {
    aoLocator[uiLocator].get( (uChar**) &aucData );
  }
  
  catch ( AipsError oAipsError ) {
    if ( aucData != NULL ) {
      delete [] aucData;
    }
    throw( ermsg( "get( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_ubyte" ) );
  }
  
  aiData = new Int[poIPosition->product()];
  
  for ( uiElement = 0; uiElement < (uInt) poIPosition->product();
      uiElement++ ) {
    aiData[uiElement] = (Int) aucData[uiElement];
  }
  
  Array<Int> oArray = Array<Int>( *poIPosition, (const Int*) aiData );
  
  
  // Free the memory
  
  delete poIPosition;
  
  delete [] aucData;
  delete [] aiData;
  
  
  // Return the data array
  
  return( oArray );

}

// -----------------------------------------------------------------------------

/*

get_uword

Description:
------------
This public member function gets a data array from a _UWORD HDS locator.

Inputs:
-------
None.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Int> HDSFile::get_uword() const {

  // Declare the local variables
  
  Bool bPrim;             // The HDS locator primitive flag
  Bool bValid;            // The HDS locator validity flag

  uInt uiDim;             // The HDS locator dimension counter
  uInt uiElement;         // The HDS locator element counter
  
  uShort* ausData = NULL; // The data block
  
  Int* aiData;            // The data array
  
  IPosition* poIPosition; // The aips++ IPosition{ } object


  // Check the present HDS status, locator, and primitive flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "get_uword" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_uword" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "get_uword" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_uword" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "get_uword" ) );
  }
  
  
  // Create the aips++ IPosition{ } object

  try {
    uInt uiNumDim = numDim();
    HDSDim oShape = HDSDim( shape() );
    if ( uiNumDim > 0 ) {
      poIPosition = new IPosition( uiNumDim );
      for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
        (*poIPosition)(uiDim) = oShape(uiDim);
      }
    } else {
      poIPosition = new IPosition( 1, 1 );
    }
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "shape( ) and/or IPosition{ } error\n" + oAipsError.getMesg(),
        "HDSFile", "get_uword" ) );
  }
  
  
  // Get the data block and place it into the aips++ Array<Int> data array

  try {
    aoLocator[uiLocator].get( (uChar**) &ausData );
  }
  
  catch ( AipsError oAipsError ) {
    if ( ausData != NULL ) {
      delete [] ausData;
    }
    throw( ermsg( "get( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_uword" ) );
  }
  
  aiData = new Int[poIPosition->product()];
  
  for ( uiElement = 0; uiElement < (uInt) poIPosition->product();
      uiElement++ ) {
    aiData[uiElement] = (Int) ausData[uiElement];
  }
  
  Array<Int> oArray = Array<Int>( *poIPosition, (const Int*) aiData );
  
  
  // Free the memory
  
  delete poIPosition;
  
  delete [] ausData;
  delete [] aiData;
  
  
  // Return the data array
  
  return( oArray );

}

// -----------------------------------------------------------------------------

/*

get_word

Description:
------------
This public member function gets a data array from a _WORD HDS locator.

Inputs:
-------
None.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Int> HDSFile::get_word() const {

  // Declare the local variables
  
  Bool bPrim;             // The HDS locator primitive flag
  Bool bValid;            // The HDS locator validity flag

  uInt uiDim;             // The HDS locator dimension counter
  uInt uiElement;         // The HDS locator element counter
  
  Short* asData = NULL;   // The data block
  
  Int* aiData;            // The Int version of the data array
  
  IPosition* poIPosition; // The aips++ IPosition{ } object


  // Check the present HDS status, locator, and primitive flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "get_word" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_word" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "get_word" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_word" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "get_word" ) );
  }
  
  
  // Create the aips++ IPosition{ } object

  try {
    uInt uiNumDim = numDim();
    HDSDim oShape = HDSDim( shape() );
    if ( uiNumDim > 0 ) {
      poIPosition = new IPosition( uiNumDim );
      for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
        (*poIPosition)(uiDim) = oShape(uiDim);
      }
    } else {
      poIPosition = new IPosition( 1, 1 );
    }
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "shape( ) and/or IPosition{ } error\n" + oAipsError.getMesg(),
        "HDSFile", "get_word" ) );
  }
  
  
  // Get the data block and place it into the aips++ Array<Int> data array

  try {
    aoLocator[uiLocator].get( (uChar**) &asData );
  }
  
  catch ( AipsError oAipsError ) {
    if ( asData != NULL ) {
      delete [] asData;
    }
    throw( ermsg( "get( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "get_word" ) );
  }

  aiData = new Int[poIPosition->product()];
  
  for ( uiElement = 0; uiElement < (uInt) poIPosition->product();
      uiElement++ ) {
    aiData[uiElement] = (Int) asData[uiElement];
  }
  
  Array<Int> oArray = Array<Int>( *poIPosition, (const Int*) aiData );
  
  
  // Free the memory
  
  delete poIPosition;
  
  delete [] asData;
  delete [] aiData;
  
  
  // Return the data array
  
  return( oArray );

}

// -----------------------------------------------------------------------------

/*

HDSFile::Goto

Description:
------------
This public member function goes to an HDS locator specified by a fully resolved
HDS path.

Inputs:
-------
oPathIn - The fully resolved HDS path.

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::Goto( const String& oPathIn ) {

  // Declare the local variables
  
  uInt uiDim;      // The HDS locator dimension counter
  uInt uiName;     // The HDS locator name counter
  uInt uiNumName;  // The number of HDS locator names

  uInt* auiNumDim; // The HDS locator number of dimensions

  String* aoName;  // The HDS locator names
  
  uInt** auiDim1;  // The HDS locator lower dimension numbers
  uInt** auiDim2;  // The HDS locator upper dimension numbers
  

  // Check the inputs
  
  String oPath = oPathIn;
  oPath.gsub( RXwhite, "" );
  oPath.upcase();

  try {
    if ( oPath.matches( path() ) ) {
      cout << msg( "Already at the desired HDS path\n", "HDSFile", "Goto",
          WARN ).getMesg() << flush;
      return;
    }
  }
  
  catch( AipsError oAipsError ) {
    throw( ermsg( "path( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "Goto" ) );
  }


  // Allocate the memory

  uiNumName = (uInt) oPath.freq( "." ) + 1;

  aoName = new String[uiNumName];

  auiNumDim = new uInt[uiNumName];

  auiDim1 = new uInt*[uiNumName];
  auiDim2 = new uInt*[uiNumName];

  for ( uiName = 0; uiName < uiNumName; uiName++ ) {
    auiDim1[uiName] = new uInt[HDSDim::MXDIM];
    auiDim2[uiName] = new uInt[HDSDim::MXDIM];
  }


  // Parse the HDS object names from the fully resolved HDS path
  
  for ( uiName = 0; uiName < uiNumName; uiName++ ) {
    if ( oPath.contains( "." ) ) {
      aoName[uiName] = oPath.before( "." );
      oPath = oPath.after( "." );
    } else if ( !oPath.contains( "." ) && uiName == uiNumName - 1 ) {
      aoName[uiName] = oPath;
      oPath = "";
    } else {
      delete [] auiNumDim;
      for ( uiName = 0; uiName < uiNumName; uiName++ ) {
        delete [] auiDim1[uiName];
        delete [] auiDim2[uiName];
      }
      delete [] auiDim1;
      delete [] auiDim2;
      delete [] aoName;
      throw( ermsg( "HDS path parse error", "HDSFile", "Goto" ) );
    }
  }
  
  oPath = oPathIn;
  oPath.gsub( RXwhite, "" );
  oPath.upcase();


  // Parse the HDS object dimensions from the HDS object names

  String oCell = String();
  String oCells = String();
  
  for ( uiName = 0; uiName < uiNumName; uiName++ ) {
    if ( !aoName[uiName].contains( "(" ) ) {
      auiNumDim[uiName] = 0;
      continue;
    } else {
      oCells = String( aoName[uiName].after( "(" ) );
      oCells.gsub( ")", "" );
      aoName[uiName] = aoName[uiName].before( "(" + oCells );
      auiNumDim[uiName] = (uInt) oCells.freq( "," ) + 1;
    }
    for ( uiDim = 0; uiDim < auiNumDim[uiName]; uiDim++ ) {
      if ( oCells.contains( "," ) ) {
        oCell = oCells.before( "," );
        oCells = oCells.after( "," );
      } else {
        oCell = oCells;
        oCells = "";
      }
      if ( oCell.contains( ":" ) ) {
        auiDim1[uiName][uiDim] =
            (uInt) atol( (const char*) String( oCell.before( ":" ) ).chars() );
        auiDim2[uiName][uiDim] =
            (uInt) atol( (const char*) String( oCell.after( ":" ) ).chars() );
      } else {
        auiDim1[uiName][uiDim] = (uInt) atol( (const char*) oCell.chars() );
        auiDim2[uiName][uiDim] = auiDim1[uiName][uiDim];
      }
    }
  }


  // Go to the top HDS locator and check it, if desired

  try {
    annul( uiLocator - 1 );
  }
  
  catch ( AipsError oAipsError ) {
    delete [] auiNumDim;
    for ( uiName = 0; uiName < uiNumName; uiName++ ) {
      delete [] auiDim1[uiName];
      delete [] auiDim2[uiName];
    }
    delete [] auiDim1;
    delete [] auiDim2;
    delete [] aoName;
    throw( ermsg( "annul( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "Goto" ) );
  }


  // Descend the fully resolved HDS path

  for ( uiName = 0; uiName < uiNumName; uiName++ ) {

    if ( uiName > 0 ) {
      try {
        find( aoName[uiName] );
      }
      catch ( AipsError oAipsError ) {
        delete [] auiNumDim;
        for ( uiName = 0; uiName < uiNumName; uiName++ ) {
          delete [] auiDim1[uiName];
          delete [] auiDim2[uiName];
        }
        delete [] auiDim1;
        delete [] auiDim2;
        delete [] aoName;
        throw( ermsg( "find( ) error\n" + oAipsError.getMesg(), "HDSFile",
            "Goto" ) );
      }
    } else {
      if ( !aoName[uiName].matches( path() ) ) {
        throw( ermsg( "Invalid HDS top locator name", "HDSFile", "Goto" ) );
      }
    }

    if ( auiNumDim[uiName] == 0 ) {
      continue;
    } else {
      for ( uiDim = 0; uiDim < auiNumDim[uiName]; uiDim++ ) {
        if ( auiDim1[uiName][uiDim] != auiDim2[uiName][uiDim] ) {
          break;
        }
      }
      if ( uiDim >= auiNumDim[uiName] ) {
        try {
          cell( HDSDim( auiNumDim[uiName], auiDim1[uiName] ) );
        }
        catch ( AipsError oAipsError ) {
          delete [] auiNumDim;
          for ( uiName = 0; uiName < uiNumName; uiName++ ) {
            delete [] auiDim1[uiName];
            delete [] auiDim2[uiName];
          }
          delete [] auiDim1;
          delete [] auiDim2;
          delete [] aoName;
          throw( ermsg( "cell( ) error\n" + oAipsError.getMesg(), "HDSFile",
              "Goto" ) );
        }
      } else {
        try {
          slice( HDSDim( auiNumDim[uiName], auiDim1[uiName] ),
                 HDSDim( auiNumDim[uiName], auiDim2[uiName] ) );
        }
        catch ( AipsError oAipsError ) {
          delete [] auiNumDim;
          for ( uiName = 0; uiName < uiNumName; uiName++ ) {
            delete [] auiDim1[uiName];
            delete [] auiDim2[uiName];
          }
          delete [] auiDim1;
          delete [] auiDim2;
          delete [] aoName;
          throw( ermsg( "slice( ) error\n" + oAipsError.getMesg(), "HDSFile",
              "Goto" ) );
        }
      }

    }

  }


  // Deallocate the memory

  delete [] auiNumDim;

  for ( uiName = 0; uiName < uiNumName; uiName++ ) {
    delete [] auiDim1[uiName];
    delete [] auiDim2[uiName];
  }

  delete [] auiDim1;
  delete [] auiDim2;

  delete [] aoName;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::index

Description:
------------
This public member function "indexes" to an HDS locator.

Inputs:
-------
uiIndex - The HDS locator index.

Outputs:
--------
The HDS locator index, returned via the function value.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::index( const uInt& uiIndex ) {

  // Declare the local variables

  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "index" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "index" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "index" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "index" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile", "index" ) );
  }

  
  // Check the HDS locator number
  
  if ( uiLocator >= NUM_LOCATOR_MAX ) {
    throw( ermsg( "Maximum number of HDS locators reached", "HDSFile",
        "index" ) );
  }
  
  
  // Find the HDS locator corresponding to the index and get its locator
  
  HDSWrapper::dat_index( (const char* const) aoLocator[uiLocator].ploc(),
      (const int) uiIndex, (char* const) aoLocator[uiLocator + 1].ploc(),
      (int* const) aoLocator[uiLocator + 1].pstatus() );
  
  if ( aoLocator[uiLocator + 1].status() != OK ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "HDSWrapper::dat_index( ) error", "HDSFile", "index" ) );
  }
  
  uiLocator += 1;
  
  
  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

HDSFile::len

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
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::len( void ) const {

  // Declare the local variables

  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "len" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "len" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "len" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "len" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "len" ) );
  }


  // Get and return the HDS locator length
  
  try {
    return( aoLocator[uiLocator].len() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::len( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "len" ) );
  }

}

// -----------------------------------------------------------------------------

/*

list

Description:
------------
This public member function returns the list of HDS components beneath the
present HDS cell/locator.  The present HDS locator must be a structure, not a
primitive.

Inputs:
-------
None.

Outputs:
--------
The HDS component list, returned via the function value.

Modification history:
---------------------
1998 Nov 23 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> HDSFile::list( void ) {

  // Declare the local variables
  
  Bool bStruc;         // The HDS locator structure flag
  Bool bValid;         // The HDS locator validity flag
  
  uInt uiComp;         // The HDS component counter
  uInt uiDim;          // The HDS locator dimension counter
  uInt uiNumComp;      // The number of HDS components
  uInt uiNumDim;       // The number of HDS locator dimensions
  
  Char acComp[10 + 1]; // The string version of the HDS component number


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "list" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "list" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "list" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "list" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile", "list" ) );
  }
  

  // Check the present HDS locator number
  
  if ( uiLocator >= NUM_LOCATOR_MAX ) {
    throw( ermsg( "Maximum number of HDS locators reached", "HDSFile",
        "list" ) );
  }
  
  
  // Form the HDS locator list

  HDSDim oDim = HDSDim( shape() );
  uiNumDim = numDim();
  Vector<String> oList = Vector<String>();
  
  if ( uiNumDim == 0 ) {

    uiNumComp = ncomp();
    oList = Vector<String>( uiNumComp, "" );

    for ( uiComp = 1; uiComp <= uiNumComp; uiComp++ ) {
    
      try {
        index( uiComp );
        oList(uiComp-1) += name();
        if ( struc() ) {
          oList(uiComp-1) += String( "*" );
        }
        annul();
      }
      
      catch ( AipsError oAipsError ) {
        throw( ermsg( "Error forming HDS locator list\n" + oAipsError.getMesg(),
	    "HDSFile", "list" ) );
      }
      
    }
    
  } else {

    Vector<Int> oComp = Vector<Int>( uiNumDim, 1 );
    String oName = String( name() );

    uiNumComp = 1;
    for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
      uiNumComp *= oDim(uiDim);
    }
    oList = Vector<String>( uiNumComp, "" );

    try {
      for ( uiComp = 1; uiComp <= uiNumComp; uiComp++ ) {
        oList(uiComp-1) += oName + String( "(" );
        for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
          sprintf( acComp, "%d", oComp(uiDim) );
          oList(uiComp-1) += String( acComp );
          if ( uiDim < ( uiNumDim - 1 ) ) {
	    oList(uiComp-1) += String( "," );
          }
        }
        oList(uiComp-1) += String( ")*" );
        oComp(uiNumDim - 1) += 1;
        for ( uiDim = uiNumDim; uiDim > 0; uiDim-- ) {
          if ( oComp(uiDim - 1) > oDim(uiDim - 1) && uiDim > 1 ) {
            oComp(uiDim - 1) = 1;
	    oComp(uiDim - 2) += 1;
          }
        }
      }
    }
    
    catch ( AipsError oAipsError ) {
      throw( ermsg( "Error forming HDS locator list\n" + oAipsError.getMesg(),
          "HDSFile", "list" ) );
    }
  
  }
  
  
  // Return the HDS locator list
  
  return( oList );

}

// -----------------------------------------------------------------------------

/*

HDSFile::locator

Description:
------------
This public member function returns the number of  active HDS locators.

Inputs:
-------
None.

Outputs:
--------
The number of active HDS locators, returned via the function value.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::locator( void ) const {

  // Return the number of HDS locators
  
  return( uiLocator );
  
}

// -----------------------------------------------------------------------------

/*

HDSFile::locatord

Description:
------------
This public member function returns the desired HDSLocator{ } object.

Inputs:
-------
uiLocatorIn - The HDS locator.

Outputs:
--------
The desired HDSLocator{ } object, returned via the function value.

Modification history:
---------------------
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSLocator HDSFile::locatord( const uInt& uiLocatorIn ) const {

  // Check the inputs
  
  if ( uiLocatorIn > uiLocator ) {
    throw( ermsg( "Invalid HDS locator", "HDSFile", "locatord" ) );
  }
  

  // Return the desired HDSLocator{ } object

  return( aoLocator[uiLocatorIn] );

}

// -----------------------------------------------------------------------------

/*

HDSFile::locators

Description:
------------
This public member function returns the saved HDSLocator{ } object.

Inputs:
-------
None.

Outputs:
--------
The saved HDSLocator{ } object, returned via the function value.

Modification history:
---------------------
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSLocator HDSFile::locators( void ) const {
  
  // Return the saved HDSLocator{ } object
  
  return( *poLocatorSave );

}

// -----------------------------------------------------------------------------

/*

HDSFile::mode

Description:
------------
This public member function returns the HDS access mode.

Inputs:
-------
None.

Outputs:
--------
The HDS access mode, returned via the function value.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String HDSFile::mode( void ) const {

  // Return the HDS access mode
  
  return( poAccess->mode() );

}

// -----------------------------------------------------------------------------

/*

HDSFile::move

Description:
------------
This public member function recursively moves the present HDS locator to the
saved HDS locator (see HDSFile::save( ) ) in the present object or in another
object (need the result of id() ).

Inputs:
-------
oNameIn - The HDS locator name.
poFile  - The HDSFile{ } pointer to the other object (default = NULL).

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::move( const HDSName& oNameIn, HDSFile* poFile ) {

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access modes

  if ( poFile == NULL ) {
    if ( poAccess->mode().matches( "READ" ) ) {
      throw( ermsg( "Invalid HDS access mode", "HDSFile", "move" ) );
    }
  } else {
    if ( poFile->mode().matches( "READ" ) ) {
      throw( ermsg( "Invalid HDS access mode", "HDSFile", "move" ) );
    }
  }


  // Check the present HDS status and locator
  
  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "move" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "move" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "move" ) );
  }


  // Check the saved HDS status and locator

  if ( poFile == NULL ) {  
  
    if ( poLocatorSave->status() != OK ) {
      throw( ermsg( "Error associated with saved HDS locator", "HDSFile",
          "move" ) );
    }

    try {
      bValid = poLocatorSave->valid();
    }
  
    catch ( AipsError oAipsError ) {
      throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
          "move" ) );
    }
  
    if ( !bValid ) {
      throw( ermsg( "Invalid saved HDS locator", "HDSFile", "move" ) );
    }
    
  } else {
  
    if ( poFile->locators().status() != OK ) {
      throw( ermsg( "Error associated with other HDS locator", "HDSFile",
          "move" ) );
    }

    try {
      bValid = poFile->valid();
    }
  
    catch ( AipsError oAipsError ) {
      throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
          "move" ) );
    }
  
    if ( !bValid ) {
      throw( ermsg( "Invalid other HDS locator", "HDSFile", "move" ) );
    }
      
  }
  
  
  // Compare the present and saved HDS locators
  
  if ( poFile == NULL ) {
    
    if ( !memcmp( (const void*) aoLocator[uiLocator].ploc(),
         (const void*) poLocatorSave->pploc(), (size_t) SZLOC ) ) {
      throw( ermsg( "Indentical present/saved HDS locators", "HDSFile",
          "move" ) );
    }
    
  } else {
    
    if ( !memcmp( (const void*) aoLocator[uiLocator].ploc(),
         (const void*) poFile->locators().pploc(), (size_t) SZLOC ) ) {
      throw( ermsg( "Indentical present/saved HDS locators", "HDSFile",
          "move" ) );
    }
    
  }

  
  // Recursively move the HDS locator(s)

  if ( poFile == NULL ) {
    HDSWrapper::dat_move( (const char* const) aoLocator[uiLocator].ploc(),
        (const char* const) poLocatorSave->pploc(),
        (const char* const) oNameIn.chars(),
	(int* const) poLocatorSave->pstatus() );
    if ( poLocatorSave->status() != OK ) {
      poLocatorSave->recover();
      throw( ermsg( "HDSWrapper::dat_move( ) error", "HDSFile", "move" ) );
    }
  } else {
    HDSWrapper::dat_move( (const char* const) aoLocator[uiLocator].ploc(),
        (const char* const) poFile->locators().pploc(),
        (const char* const) oNameIn.chars(),
	(int* const) poFile->locators().pstatus() );
    if ( poFile->locators().status() != OK ) {
      poFile->locators().recover();
      throw( ermsg( "HDSWrapper::dat_move( ) error", "HDSFile", "move" ) );
    }
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::name

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
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSName HDSFile::name( void ) const {

  // Declare the local variables
  
  Bool bValid; // The HDS locator validity flag
  

  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "name" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "name" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "name" ) );
  }


  // Get and return the HDS locator name
  
  try {
    return( aoLocator[uiLocator].name() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::name( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "name" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::ncomp

Description:
------------
This public member function returns the number of HDS locators.

Inputs:
-------
None.

Outputs:
--------
The number of HDS locators, returned via the function value.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::ncomp( void ) {

  // Declare the local variables
  
  Bool bValid;         // The HDS locator validity flag
  
  uInt uiLocatorBelow; // The number of HDS locators below the present one
  

  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "ncomp" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "ncomp" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "ncomp" ) );
  }
  
  
  // Check the HDS locator number
  
  if ( uiLocator >= NUM_LOCATOR_MAX ) {
    throw( ermsg( "Maximum number of HDS locators reached", "HDSFile",
        "ncomp" ) );
  }
  
  
  // Get and return the number of HDS locators below the present one
  
  HDSWrapper::dat_ncomp( (const char* const) aoLocator[uiLocator].ploc(),
      (int* const) &uiLocatorBelow,
      (int* const) aoLocator[uiLocator].pstatus() );
  
  if ( aoLocator[uiLocator].status() != OK ) {
    aoLocator[uiLocator].on();
    throw( ermsg( "HDSWrapper::dat_ncomp( ) error", "HDSFile", "ncomp" ) );
  }
  
  return( uiLocatorBelow );

}

// -----------------------------------------------------------------------------

/*

HDSFile::New

Description:
------------
This public member function creates a new HDS locator.

Inputs:
-------
oNameIn  - The HDS locator name.
oTypeIn  - The HDS locator type.
oDimIn   - The HDS locator dimensions.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::New( const HDSName& oNameIn, const HDSType& oTypeIn,
    const HDSDim& oDimIn, const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bThere;       // The HDS locator existence flag
  Bool bValid;       // The HDS locator validity flag

  HDSDim* poDimTemp; // The temporary HDS dimension object
  
  
  // Check the access mode, present HDS status, and locator

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "New" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "New" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "New" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "New" ) );
  }

  
  // Check the HDS locator number
  
  if ( uiLocator >= NUM_LOCATOR_MAX ) {
    throw( ermsg( "Maximum number of HDS locators reached", "HDSFile",
        "New" ) );
  }


  // Check the HDS locator existence flag and act accordingly
  
  try {
    bThere = there( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "New" ) );
  }
  
  if ( bThere ) {
    if ( bReplace ) {
      try {
        find( oNameIn );
        renam( HDSName( "---TEMP---" ) );
        annul();
      }
      catch ( AipsError oAipsError ) {
        recover();
        throw( ermsg( "Error renaming HDS locator\n" + oAipsError.getMesg(),
            "HDSFile", "New" ) );
      }
    } else {
      throw( ermsg( "Replacement of HDS locator not specified", "HDSFile",
          "New" ) );
    }
  }

  
  // Create the new HDS locator
  
  poDimTemp = new HDSDim( oDimIn );
  
  HDSWrapper::dat_new( (const char* const) aoLocator[uiLocator].ploc(),
      (const char* const) oNameIn.chars(), (const char* const) oTypeIn.chars(),
      (const int) poDimTemp->nelements(), (const int* const) poDimTemp->ppdim(),
      (int* const) aoLocator[uiLocator].pstatus() );
  
  if ( aoLocator[uiLocator].status() != OK ) {
    delete poDimTemp;
    aoLocator[uiLocator].on();
    throw( ermsg( "HDSWrapper::dat_new( ) error", "HDSFile", "New" ) );
  }


  // Erase the previous HDS locator

  try {
    if ( bReplace && bThere ) {
      erase( HDSName( "---TEMP---" ) );
    }
  }
  
  catch ( AipsError oAipsError ) {
    delete poDimTemp;
    aoLocator[uiLocator].on();
    throw( ermsg( "Error erasing previous HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "New" ) );
  }

  delete poDimTemp;
  
  
  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

HDSFile::numDim

Description:
------------
This public member function returns the number of dimensions.

Inputs:
-------
None.

Outputs:
--------
The number of dimensions, returned via the function value.

Modification history:
---------------------
2000 Aug 31 - Nicholas Elias, USNO/NPOI
              Public member function added.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::numDim( void ) const {

  // Return the number of dimensions
  
  return( shape().nelements() );

}

// -----------------------------------------------------------------------------

/*

HDSFile::obtain_byte

Description:
------------
This public member function obtains a _BYTE HDS locator and puts it into a data
array.

Inputs:
-------
oNameIn - The HDS locator name.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Int> HDSFile::obtain_byte( const HDSName& oNameIn ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bThere; // The HDS locator existence flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the present HDS status, locator, and structure flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "obtain_byte" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_byte" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "obtain_byte" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_byte" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "obtain_byte" ) );
  }


  // Check the HDS locator existence flag and act accordingly
  
  try {
    bThere = there( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_byte" ) );
  }
  
  if ( !bThere ) {
    throw( ermsg( "HDS locator does not exist", "HDSFile", "obtain_byte" ) );
  }
  
  
  // Obtain the _BYTE HDS locator, put it into the data array, and return
  
  try {
    find( oNameIn );
    Array<Int> oArray = get_byte();
    annul();
    return( oArray );
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error obtaining _BYTE HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "obtain_byte" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::obtain_char

Description:
------------
This public member function obtains a _CHAR*N HDS locator and puts it into a
data array.

Inputs:
-------
oNameIn - The HDS locator name.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<String> HDSFile::obtain_char( const HDSName& oNameIn ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bThere; // The HDS locator existence flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the present HDS status, locator, and structure flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "obtain_char" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_char" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "obtain_char" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_char" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "obtain_char" ) );
  }


  // Check the HDS locator existence flag and act accordingly
  
  try {
    bThere = there( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_char" ) );
  }
  
  if ( !bThere ) {
    throw( ermsg( "HDS locator does not exist", "HDSFile", "obtain_char" ) );
  }
  
  
  // Obtain the _CHAR*N HDS locator, put it into the data array, and return
  
  try {
    find( oNameIn );
    Array<String> oArray = get_char();
    annul();
    return( oArray );
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg(
        "Error obtaining _CHAR*N HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "obtain_char" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::obtain_double

Description:
------------
This public member function obtains a _DOUBLE HDS locator and puts it into a
data array.

Inputs:
-------
oNameIn - The HDS locator name.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Double> HDSFile::obtain_double( const HDSName& oNameIn ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bThere; // The HDS locator existence flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the present HDS status, locator, and structure flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "obtain_double" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_double" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile",
        "obtain_double" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_double" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "obtain_double" ) );
  }


  // Check the HDS locator existence flag and act accordingly
  
  try {
    bThere = there( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_double" ) );
  }
  
  if ( !bThere ) {
    throw( ermsg( "HDS locator does not exist", "HDSFile", "obtain_double" ) );
  }
  
  
  // Obtain the _DOUBLE HDS locator, put it into the data array, and return
  
  try {
    find( oNameIn );
    Array<Double> oArray = get_double();
    annul();
    return( oArray );
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg(
        "Error obtaining _DOUBLE HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "obtain_double" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::obtain_integer

Description:
------------
This public member function obtains a _INTEGER HDS locator and puts it into a
data array.

Inputs:
-------
oNameIn - The HDS locator name.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Int> HDSFile::obtain_integer( const HDSName& oNameIn ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bThere; // The HDS locator existence flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the present HDS status, locator, and structure flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "obtain_integer" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_integer" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile",
        "obtain_integer" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_integer" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "obtain_integer" ) );
  }


  // Check the HDS locator existence flag and act accordingly
  
  try {
    bThere = there( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_integer" ) );
  }
  
  if ( !bThere ) {
    throw( ermsg( "HDS locator does not exist", "HDSFile", "obtain_integer" ) );
  }
  
  
  // Obtain the _INTEGER HDS locator, put it into the data array, and return
  
  try {
    find( oNameIn );
    Array<Int> oArray = get_integer();
    annul();
    return( oArray );
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg(
        "Error obtaining _INTEGER HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "obtain_integer" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::obtain_logical

Description:
------------
This public member function obtains a _LOGICAL HDS locator and puts it into a
data array.

Inputs:
-------
oNameIn - The HDS locator name.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Bool> HDSFile::obtain_logical( const HDSName& oNameIn ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bThere; // The HDS locator existence flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the present HDS status, locator, and structure flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "obtain_logical" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_logical" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile",
        "obtain_logical" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_logical" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "obtain_logical" ) );
  }


  // Check the HDS locator existence flag and act accordingly
  
  try {
    bThere = there( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_logical" ) );
  }
  
  if ( !bThere ) {
    throw( ermsg( "HDS locator does not exist", "HDSFile", "obtain_logical" ) );
  }
  
  
  // Obtain the _LOGICAL HDS locator, put it into the data array, and return
  
  try {
    find( oNameIn );
    Array<Bool> oArray = get_logical();
    annul();
    return( oArray );
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg(
        "Error obtaining _LOGICAL HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "obtain_logical" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::obtain_real

Description:
------------
This public member function obtains a _REAL HDS locator and puts it into a data
array.

Inputs:
-------
oNameIn - The HDS locator name.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Float> HDSFile::obtain_real( const HDSName& oNameIn ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bThere; // The HDS locator existence flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the present HDS status, locator, and structure flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "obtain_real" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_real" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "obtain_real" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_real" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "obtain_real" ) );
  }


  // Check the HDS locator existence flag and act accordingly
  
  try {
    bThere = there( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_real" ) );
  }
  
  if ( !bThere ) {
    throw( ermsg( "HDS locator does not exist", "HDSFile", "obtain_real" ) );
  }
  
  
  // Obtain the _REAL HDS locator, put it into the data array, and return
  
  try {
    find( oNameIn );
    Array<Float> oArray = get_real();
    annul();
    return( oArray );
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error obtaining _REAL HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "obtain_real" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::obtain_ubyte

Description:
------------
This public member function obtains a _UBYTE HDS locator and puts it into a data
array.

Inputs:
-------
oNameIn - The HDS locator name.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Int> HDSFile::obtain_ubyte( const HDSName& oNameIn ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bThere; // The HDS locator existence flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the present HDS status, locator, and structure flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "obtain_ubyte" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_ubyte" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "obtain_ubyte" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_ubyte" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "obtain_ubyte" ) );
  }


  // Check the HDS locator existence flag and act accordingly
  
  try {
    bThere = there( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_ubyte" ) );
  }
  
  if ( !bThere ) {
    throw( ermsg( "HDS locator does not exist", "HDSFile", "obtain_ubyte" ) );
  }
  
  
  // Obtain the _UBYTE HDS locator, put it into the data array, and return
  
  try {
    find( oNameIn );
    Array<Int> oArray = get_ubyte();
    annul();
    return( oArray );
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error obtaining _UBYTE HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "obtain_ubyte" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::obtain_uword

Description:
------------
This public member function obtains a _UWORD HDS locator and puts it into a data
array.

Inputs:
-------
oNameIn - The HDS locator name.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Int> HDSFile::obtain_uword( const HDSName& oNameIn ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bThere; // The HDS locator existence flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the present HDS status, locator, and structure flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "obtain_uword" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_uword" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "obtain_uword" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_uword" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "obtain_uword" ) );
  }


  // Check the HDS locator existence flag and act accordingly
  
  try {
    bThere = there( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_uword" ) );
  }
  
  if ( !bThere ) {
    throw( ermsg( "HDS locator does not exist", "HDSFile", "obtain_uword" ) );
  }
  
  
  // Obtain the _UWORD HDS locator, put it into the data array, and return
  
  try {
    find( oNameIn );
    Array<Int> oArray = get_uword();
    annul();
    return( oArray );
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error obtaining _UWORD HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "obtain_uword" ) );
  }  

}

// -----------------------------------------------------------------------------

/*

HDSFile::obtain_word

Description:
------------
This public member function obtains a _WORD HDS locator and puts it into a data
array.

Inputs:
-------
oNameIn - The HDS locator name.

Outputs:
--------
The data array, returned via the function value.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Array<Int> HDSFile::obtain_word( const HDSName& oNameIn ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bThere; // The HDS locator existence flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the present HDS status, locator, and structure flag

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "obtain_word" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_word" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "obtain_word" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_word" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "obtain_word" ) );
  }


  // Check the HDS locator existence flag and act accordingly
  
  try {
    bThere = there( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "obtain_word" ) );
  }
  
  if ( !bThere ) {
    throw( ermsg( "HDS locator does not exist", "HDSFile", "obtain_word" ) );
  }
  
  
  // Obtain the _WORD HDS locator, put it into the data array, and return
  
  try {
    find( oNameIn );
    Array<Int> oArray = get_word();
    annul();
    return( oArray );
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error obtaining _WORD HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "obtain_word" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::path

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
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String HDSFile::path( void ) const {

  // Declare the local variables
  
  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "path" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "path" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "path" ) );
  }
  
  
  // Get and return the HDS locator
  
  try {
    return( aoLocator[uiLocator].path() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::path( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "path" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::prec

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
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::prec( void ) const {

  // Declare the local variables

  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "prec" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "prec" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "prec" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "prec" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "prec" ) );
  }


  // Get and return the HDS locator precision
  
  try {
    return( aoLocator[uiLocator].prec() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::prec( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "prec" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::prim

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
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool HDSFile::prim( void ) const {

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "prim" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "prim" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "prim" ) );
  }


  // Get and return the HDS locator primitive flag
  
  try {
    return( aoLocator[uiLocator].prim() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::prim( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "prim" ) );
  }

}

// -----------------------------------------------------------------------------

/*

put_byte

Description:
------------
This public member function puts a data array into a _BYTE HDS locator.

Inputs:
-------
oArray - The data array.

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::put_byte( const Array<Int>& oArray ) const {

  // Declare the local variables
  
  Bool bDelete;        // The delete memory flag
  Bool bPrim;          // The HDS locator primitive flag
  Bool bValid;         // The HDS locator validity flag
  
  uInt uiElement;      // The HDS locator element counter

  Char* acData = NULL; // The Char version of the data block

  Int* aiData = NULL;  // The Int version of the data block
  
  
  // Check the access mode, and present HDS status, locator, and primitive flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "put_byte" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "put_byte" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_byte" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "put_byte" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_byte" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "put_byte" ) );
  }
  
  
  // Put the data block into the HDS locator
  
  try {
    aiData = (Int*) oArray.getStorage( bDelete );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Array<Int>::getStorage() error\n" + oAipsError.getMesg(),
        "HDSFile", "put_byte" ) );
  }
  
  acData = new Char[oArray.nelements()];
  
  for ( uiElement = 0; uiElement < oArray.nelements(); uiElement++ ) {
    if ( aiData[uiElement] < SCHAR_MIN || aiData[uiElement] > SCHAR_MAX ) {
      cout << msg( "Data array element out of range for _BYTE HDS locator\n",
          "HDSFile", "put_byte", WARN ).getMesg() << flush;
    }
    acData[uiElement] = (Char) aiData[uiElement];
  }
  
  try {
    aoLocator[uiLocator].put( (const uChar* const) acData );
  }
  
  catch ( AipsError oAipsError ) {
    oArray.freeStorage( (const Int*&) aiData, bDelete );
    delete [] acData;
    throw( ermsg( "HDSLocator::put() error\n" + oAipsError.getMesg(), "HDSFile",
        "put_byte" ) );
  }
  
  oArray.freeStorage( (const Int*&) aiData, bDelete );
  
  delete [] acData;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

put_char

Description:
------------
This public member function puts a data array into a _CHAR*N HDS locator.

Inputs:
-------
oArray - The data array.

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::put_char( const Array<String>& oArray ) const {

  // Declare the local variables
  
  Bool bDelete;          // The delete memory flag
  Bool bPrim;            // The HDS locator primitive flag
  Bool bValid;           // The HDS locator validity flag
  
  uInt uiElement;        // The HDS locator element counter
  uInt uiLength;         // The HDS locator length
  uInt uiLengthMax;      // The data array maximum length

  uChar* aucData = NULL; // The data block
  uChar* aucDataTemp;    // The temporary pointer to the data block
  
  String* aoData;        // The String version of the data array
  
  
  // Check the access mode, and present HDS status, locator, and primitive flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "put_char" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "put_char" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_char" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "put_char" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_char" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "put_char" ) );
  }
  
  
  // Put the data block into the HDS locator
  
  try {
    aoData = (String*) oArray.getStorage( bDelete );
  }
  
  catch ( AipsError oAipsError ) {
    oArray.freeStorage( (const String*&) aoData, bDelete );
    throw( ermsg( "Array<String>::getStorage() error\n" + oAipsError.getMesg(),
        "HDSFile", "put_char" ) );
  }
  
  uiLengthMax = aoData[0].length();
  
  for ( uiElement = 1; uiElement < oArray.nelements(); uiElement++ ) {
    if ( aoData[uiElement].length() > uiLengthMax ) {
      uiLengthMax = aoData[uiElement].length();
    }
  }
  
  if ( uiLengthMax < 1 ) {
    oArray.freeStorage( (const String*&) aoData, bDelete );
    throw( ermsg( "Invalid HDS locator element(s) maximum length", "HDSFile",
        "put_char" ) );
  }
  
  try {
    uiLength = len();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "len( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_char" ) );
  }
  
  if ( uiLengthMax > uiLength ) {
    throw( ermsg( "Data array element(s) larger than HDS locator element(s)",
        "HDSFile", "put_char" ) );
  }
  
  aucData = new uChar[uiLength * oArray.nelements()];
  aucDataTemp = aucData;
  
  for ( uiElement = 0; uiElement < oArray.nelements(); uiElement++ ) {
    aoData[uiElement] = aoData[uiElement]
        + String( " ", (int) ( uiLength - aoData[uiElement].length() ) );
    memcpy( (void*) aucDataTemp, (const void*) aoData[uiElement].chars(),
        (size_t) aoData[uiElement].length() );
    aucDataTemp += aoData[uiElement].length();
  }
  
  try {
    aoLocator[uiLocator].put( (const uChar* const) aucData );
  }
  
  catch ( AipsError oAipsError ) {
    oArray.freeStorage( (const String*&) aoData, bDelete );
    delete [] aucData;
    throw( ermsg( "HDSLocator::put() error\n" + oAipsError.getMesg(), "HDSFile",
        "put_char" ) );
  }
  
  
  // Free the memory
  
  oArray.freeStorage( (const String*&) aoData, bDelete );
  
  delete [] aucData;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

put_double

Description:
------------
This public member function puts a data array into a _DOUBLE HDS locator.

Inputs:
-------
oArray - The data array.

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::put_double( const Array<Double>& oArray ) const {

  // Declare the local variables
  
  Bool bDelete;          // The delete memory flag
  Bool bPrim;            // The HDS locator primitive flag
  Bool bValid;           // The HDS locator validity flag

  Double* adData = NULL; // The data block
  
  
  // Check the access mode, and present HDS status, locator, and primitive flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "put_double" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "put_double" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_double" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "put_double" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_double" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile",
        "put_double" ) );
  }
  
  
  // Put the data block into the HDS locator
  
  try {
    adData = (Double*) oArray.getStorage( bDelete );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Array<Double>::getStorage() error\n" + oAipsError.getMesg(),
        "HDSFile", "put_double" ) );
  }
  
  try {
    aoLocator[uiLocator].put( (const uChar* const) adData );
  }
  
  catch ( AipsError oAipsError ) {
    oArray.freeStorage( (const Double*&) adData, bDelete );
    throw( ermsg( "HDSLocator::put() error\n" + oAipsError.getMesg(), "HDSFile",
        "put_double" ) );
  }
  
  oArray.freeStorage( (const Double*&) adData, bDelete );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

put_integer

Description:
------------
This public member function puts a data array into an _INTEGER HDS locator.

Inputs:
-------
oArray - The data array.

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::put_integer( const Array<Int>& oArray ) const {

  // Declare the local variables
  
  Bool bDelete;       // The delete memory flag
  Bool bPrim;         // The HDS locator primitive flag
  Bool bValid;        // The HDS locator validity flag

  Int* aiData = NULL; // The data block
  
  
  // Check the access mode, and present HDS status, locator, and primitive flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "put_integer" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "put_integer" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_integer" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "put_integer" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_integer" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile",
        "put_integer" ) );
  }
  
  
  // Put the data block into the HDS locator
  
  try {
    aiData = (Int*) oArray.getStorage( bDelete );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Array<Int>::getStorage() error\n" + oAipsError.getMesg(),
        "HDSFile", "put_integer" ) );
  }
  
  try {
    aoLocator[uiLocator].put( (const uChar* const) aiData );
  }
  
  catch ( AipsError oAipsError ) {
    oArray.freeStorage( (const Int*&) aiData, bDelete );
    throw( ermsg( "HDSLocator::put() error\n" + oAipsError.getMesg(), "HDSFile",
        "put_integer" ) );
  }
  
  oArray.freeStorage( (const Int*&) aiData, bDelete );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

put_logical

Description:
------------
This public member function puts a data array into a _LOGICAL HDS locator.

Inputs:
-------
oArray - The data array.

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::put_logical( const Array<Bool>& oArray ) const {

  // Declare the local variables
  
  Bool bDelete;        // The delete memory flag
  Bool bPrim;          // The HDS locator primitive flag
  Bool bValid;         // The HDS locator validity flag

  Bool* abData = NULL; // The data block
  
  
  // Check the access mode, and present HDS status, locator, and primitive flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "put_logical" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "put_logical" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_logical" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "put_logical" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_logical" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile",
        "put_logical" ) );
  }
  
  
  // Put the data block into the HDS locator
  
  try {
    abData = (Bool*) oArray.getStorage( bDelete );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Array<Bool>::getStorage() error\n" + oAipsError.getMesg(),
        "HDSFile", "put_logical" ) );
  }
  
  try {
    aoLocator[uiLocator].put( (const uChar* const) abData );
  }
  
  catch ( AipsError oAipsError ) {
    oArray.freeStorage( (const Bool*&) abData, bDelete );
    throw( ermsg( "HDSLocator::put() error\n" + oAipsError.getMesg(), "HDSFile",
        "put_logical" ) );
  }
  
  oArray.freeStorage( (const Bool*&) abData, bDelete );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

put_real

Description:
------------
This public member function puts a data array into a _REAL HDS locator.

Inputs:
-------
oArray - The data array.

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::put_real( const Array<Float>& oArray ) const {

  // Declare the local variables
  
  Bool bDelete;         // The delete memory flag
  Bool bPrim;           // The HDS locator primitive flag
  Bool bValid;          // The HDS locator validity flag

  Float* afData = NULL; // The data block
  
  
  // Check the access mode, and present HDS status, locator, and primitive flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "put_real" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "put_real" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_real" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "put_real" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_real" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "put_real" ) );
  }
  
  
  // Put the data block into the HDS locator
  
  try {
    afData = (Float*) oArray.getStorage( bDelete );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Array<Float>::getStorage() error\n" + oAipsError.getMesg(),
        "HDSFile", "put_real" ) );
  }
  
  try {
    aoLocator[uiLocator].put( (const uChar* const) afData );
  }
  
  catch ( AipsError oAipsError ) {
    oArray.freeStorage( (const Float*&) afData, bDelete );
    throw( ermsg( "HDSLocator::put() error\n" + oAipsError.getMesg(), "HDSFile",
        "put_real" ) );
  }
  
  oArray.freeStorage( (const Float*&) afData, bDelete );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

put_ubyte

Description:
------------
This public member function puts a data array into a _UBYTE HDS locator.

Inputs:
-------
oArray - The data array.

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::put_ubyte( const Array<Int>& oArray ) const {

  // Declare the local variables
  
  Bool bDelete;          // The delete memory flag
  Bool bPrim;            // The HDS locator primitive flag
  Bool bValid;           // The HDS locator validity flag
  
  uInt uiElement;        // The HDS locator element counter

  uChar* aucData = NULL; // The uuChar version of the data block

  Int* aiData = NULL;    // The Int version of the data block
  
  
  // Check the access mode, and present HDS status, locator, and primitive flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "put_ubyte" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "put_ubyte" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_ubyte" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "put_ubyte" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_ubyte" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile",
        "put_ubyte" ) );
  }
  
  
  // Put the data block into the HDS locator
  
  try {
    aiData = (Int*) oArray.getStorage( bDelete );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Array<Int>::getStorage() error\n" + oAipsError.getMesg(),
        "HDSFile", "put_ubyte" ) );
  }
  
  aucData = new uChar[oArray.nelements()];
  
  for ( uiElement = 0; uiElement < oArray.nelements(); uiElement++ ) {
    if ( aiData[uiElement] > UCHAR_MAX ) {
      cout << msg( "Data array element out of range for _UBYTE HDS locator\n",
          "HDSFile", "put_ubyte", WARN ).getMesg() << flush;
    }
    aucData[uiElement] = (uChar) aiData[uiElement];
  }
  
  try {
    aoLocator[uiLocator].put( (const uChar* const) aucData );
  }
  
  catch ( AipsError oAipsError ) {
    oArray.freeStorage( (const Int*&) aiData, bDelete );
    delete [] aucData;
    throw( ermsg( "HDSLocator::put() error\n" + oAipsError.getMesg(), "HDSFile",
        "put_ubyte" ) );
  }
  
  oArray.freeStorage( (const Int*&) aiData, bDelete );
  
  delete [] aucData;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

put_uword

Description:
------------
This public member function puts a data array into a _UWORD HDS locator.

Inputs:
-------
oArray - The data array.

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::put_uword( const Array<Int>& oArray ) const {

  // Declare the local variables
  
  Bool bDelete;           // The delete memory flag
  Bool bPrim;             // The HDS locator primitive flag
  Bool bValid;            // The HDS locator validity flag
  
  uInt uiElement;         // The HDS locator element counter

  uShort* ausData = NULL; // The uShort version of the data block

  Int* aiData = NULL;     // The Int version of the data block
  
  
  // Check the access mode, and present HDS status, locator, and primitive flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "put_uword" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "put_uword" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_uword" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "put_uword" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_uword" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "put_uword" ) );
  }
  
  
  // Put the data block into the HDS locator
  
  try {
    aiData = (Int*) oArray.getStorage( bDelete );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Array<Int>::getStorage() error\n" + oAipsError.getMesg(),
        "HDSFile", "put_uword" ) );
  }
  
  ausData = new uShort[oArray.nelements()];
  
  for ( uiElement = 0; uiElement < oArray.nelements(); uiElement++ ) {
    if ( aiData[uiElement] > USHRT_MAX ) {
      cout << msg( "Data array element out of range for _UWORD HDS locator\n",
          "HDSFile", "put_uword", WARN ).getMesg() << flush;
    }
    ausData[uiElement] = (uShort) aiData[uiElement];
  }
  
  try {
    aoLocator[uiLocator].put( (const uChar* const) ausData );
  }
  
  catch ( AipsError oAipsError ) {
    oArray.freeStorage( (const Int*&) aiData, bDelete );
    delete [] ausData;
    throw( ermsg( "HDSLocator::put() error\n" + oAipsError.getMesg(), "HDSFile",
        "put_uword" ) );
  }
  
  oArray.freeStorage( (const Int*&) aiData, bDelete );
  
  delete [] ausData;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

put_word

Description:
------------
This public member function puts a data array into a _WORD HDS locator.

Inputs:
-------
oArray - The data array.

Outputs:
--------
None.

Modification history:
---------------------
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::put_word( const Array<Int>& oArray ) const {

  // Declare the local variables
  
  Bool bDelete;         // The delete memory flag
  Bool bPrim;           // The HDS locator primitive flag
  Bool bValid;          // The HDS locator validity flag
  
  uInt uiElement;       // The HDS locator element counter

  Short* asData = NULL; // The Short version of the data block

  Int* aiData = NULL;   // The Int version of the data block
  
  
  // Check the access mode, and present HDS status, locator, and primitive flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "put_word" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "put_word" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_word" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "put_word" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "put_word" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "put_word" ) );
  }
  
  
  // Put the data block into the HDS locator
  
  try {
    aiData = (Int*) oArray.getStorage( bDelete );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Array<Int>::getStorage() error\n" + oAipsError.getMesg(),
        "HDSFile", "put_word" ) );
  }
  
  asData = new Short[oArray.nelements()];
  
  for ( uiElement = 0; uiElement < oArray.nelements(); uiElement++ ) {
    if ( aiData[uiElement] < SHRT_MIN || aiData[uiElement] > SHRT_MAX ) {
      cout << msg( "Data array element out of range for _WORD HDS locator\n",
          "HDSFile", "put_word", WARN ).getMesg() << flush;
    }
    asData[uiElement] = (Short) aiData[uiElement];
  }
  
  try {
    aoLocator[uiLocator].put( (const uChar* const) asData );
  }
  
  catch ( AipsError oAipsError ) {
    oArray.freeStorage( (const Int*&) aiData, bDelete );
    delete [] asData;
    throw( ermsg( "HDSLocator::put() error\n" + oAipsError.getMesg(), "HDSFile",
        "put_word" ) );
  }
  
  oArray.freeStorage( (const Int*&) aiData, bDelete );
  
  delete [] asData;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::recover

Description:
------------
This public member function sets the HDS statuses to OK and resets the HDS
locators to NOLOC.

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

void HDSFile::recover( void ) {

  // Set the HDS statuses to OK, reset the HDS locators to NOLOC, and return
  
  while ( True ) {
    if ( aoLocator[uiLocator].status() == OK ) {
      break;
    }
    aoLocator[uiLocator].recover();
    uiLocator -= 1;
  }

  if ( poLocatorSave->status() != OK ) {
    poLocatorSave->recover();
  }
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::renam

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
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::renam( const HDSName& oNameIn ) const {

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag


  // Check the access mode, present HDS status, and locator

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "renam" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "renam" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "renam" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "renam" ) );
  }


  // Rename the HDS locator and return
  
  try {
    aoLocator[uiLocator].renam( oNameIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::renam( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "renam" ) );
  }
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::reset

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
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::reset( void ) const {

  // Declare the local variables

  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag


  // Check the access mode, present HDS status, and locator

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "reset" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "reset" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "reset" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "reset" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "reset" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "reset" ) );
  }
  
  
  // Reset the HDS locator state and return
  
  try {
    aoLocator[uiLocator].reset();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::reset( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "reset" ) );
  }
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

HDSFile::retyp

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
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::retyp( const HDSType& oTypeIn ) const {

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag


  // Check the access mode, present HDS status, and locator

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "retyp" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "retyp" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "retyp" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "retyp" ) );
  }


  // Retype the HDS locator and return
  
  try {
    aoLocator[uiLocator].retyp( oTypeIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::retyp( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "retyp" ) );
  }
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::save

Description:
------------
This public member function saves the present HDS locator.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::save( void ) {

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag


  // Check the access mode, present HDS status, and locator

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "save" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "save" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "save" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "save" ) );
  }
  
  
  // Save the present HDS locator

  delete poLocatorSave;
  poLocatorSave = new HDSLocator();

  HDSWrapper::dat_clone( (const char* const) aoLocator[uiLocator].ploc(),
      (char* const) poLocatorSave->ploc(),
      (int* const) poLocatorSave->pstatus() );
  
  if ( poLocatorSave->status() != OK ) {
    poLocatorSave->recover();
    throw( ermsg( "HDSWrapper::dat_clone( ) error", "HDSFile", "save" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::screate_byte

Description:
------------
This public member function creates a new scalar _BYTE HDS locator and puts the
datum into it.

Inputs:
-------
oNameIn  - The HDS locator name.
iDatum   - The datum.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::screate_byte( const HDSName& oNameIn, const Int& iDatum,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "screate_byte" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "screate_byte" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_byte" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "screate_byte" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_byte" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "screate_byte" ) );
  }
  
  
  // Create the scalar _BYTE HDS locator and put the datum into it
  
  try {
    New( oNameIn, HDSType( "_BYTE" ), HDSDim(), bReplace );
    find( oNameIn );
    put_byte( Array<Int>( IPosition(1,1), iDatum ) );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _BYTE HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "screate_byte" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::screate_char

Description:
------------
This public member function creates a new scalar _CHAR*N HDS locator and puts
the datum into it.

Inputs:
-------
oNameIn  - The HDS locator name.
uiLength - The HDS locator element length.
oDatum   - The datum.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::screate_char( const HDSName& oNameIn, const uInt& uiLength,
    const String& oDatum, const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc;                     // The HDS locator structure flag
  Bool bValid;                     // The HDS locator validity flag
  
  Char acType[HDSName::SZNAM + 1]; // The HDS locator type
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "screate_char" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "screate_char" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_char" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "screate_char" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_char" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "screate_char" ) );
  }
  
  
  // Create the scalar _CHAR*N HDS locator and put the datum into it
  
  try {
    sprintf( acType, "_CHAR*%d", (int) uiLength );
    New( oNameIn, HDSType( acType ), HDSDim(), bReplace );
    find( oNameIn );
    put_char( Array<String>( IPosition(1,1), oDatum ) );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _CHAR*N HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "screate_char" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::screate_double

Description:
------------
This public member function creates a new scalar _DOUBLE HDS locator and puts
the datum into it.

Inputs:
-------
oNameIn  - The HDS locator name.
dDatum   - The datum
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::screate_double( const HDSName& oNameIn, const Double& dDatum,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "screate_double" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "screate_double" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_double" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile",
        "screate_double" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_double" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "screate_double" ) );
  }
  
  
  // Create the scalar _DOUBLE HDS locator and put the datum into it
  
  try {
    New( oNameIn, HDSType( "_DOUBLE" ), HDSDim(), bReplace );
    find( oNameIn );
    put_double( Array<Double>( IPosition(1,1), dDatum ) );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _DOUBLE HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "screate_double" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::screate_integer

Description:
------------
This public member function creates a new scalar _INTEGER HDS locator and puts
the datum into it.

Inputs:
-------
oNameIn  - The HDS locator name.
iDatum   - The datum.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::screate_integer( const HDSName& oNameIn, const Int& iDatum,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "screate_integer" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "screate_integer" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_integer" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile",
        "screate_integer" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_integer" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "screate_integer" ) );
  }
  
  
  // Create the scalar _INTEGER HDS locator and put the datum into it
  
  try {
    New( oNameIn, HDSType( "_INTEGER" ), HDSDim(), bReplace );
    find( oNameIn );
    put_integer( Array<Int>( IPosition(1,1), iDatum ) );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg(
        "Error creating _INTEGER HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "screate_integer" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::screate_logical

Description:
------------
This public member function creates a new scalar _LOGICAL HDS locator and puts
the datum into it.

Inputs:
-------
oNameIn  - The HDS locator name.
bDatum   - The datum.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::screate_logical( const HDSName& oNameIn, const Bool& bDatum,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "screate_logical" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "screate_logical" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_logical" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile",
        "screate_logical" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_logical" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "screate_logical" ) );
  }
  
  
  // Create the scalar _LOGICAL HDS locator and put the datum into it
  
  try {
    New( oNameIn, HDSType( "_LOGICAL" ), HDSDim(), bReplace );
    find( oNameIn );
    put_logical( Array<Bool>( IPosition(1,1), bDatum ) );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg(
        "Error creating _LOGICAL HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "screate_logical" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::screate_real

Description:
------------
This public member function creates a new scalar _REAL HDS locator and puts the
datum into it.

Inputs:
-------
oNameIn  - The HDS locator name.
fDatum   - The datum.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::screate_real( const HDSName& oNameIn, const Float& fDatum,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "screate_real" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "screate_real" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_real" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "screate_real" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_real" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "screate_real" ) );
  }
  
  
  // Create the scalar _REAL HDS locator and put the datum into it
  
  try {
    New( oNameIn, HDSType( "_REAL" ), HDSDim(), bReplace );
    find( oNameIn );
    put_real( Array<Float>( IPosition(1,1), fDatum ) );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _REAL HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "screate_real" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::screate_ubyte

Description:
------------
This public member function creates a new scalar _UBYTE HDS locator and puts
the datum into it.

Inputs:
-------
oNameIn  - The HDS locator name.
iDatum   - The datum.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::screate_ubyte( const HDSName& oNameIn, const Int& iDatum,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "screate_ubyte" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "screate_ubyte" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_ubyte" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "screate_ubyte" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_ubyte" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "screate_ubyte" ) );
  }
  
  
  // Create the scalar _UBYTE HDS locator and put the datum into it
  
  try {
    New( oNameIn, HDSType( "_UBYTE" ), HDSDim(), bReplace );
    find( oNameIn );
    put_ubyte( Array<Int>( IPosition(1,1), iDatum ) );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _UBYTE HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "screate_ubyte" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::screate_uword

Description:
------------
This public member function creates a new scalar _UWORD HDS locator and puts
the datum into it.

Inputs:
-------
oNameIn  - The HDS locator name.
iDatum   - The datum.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::screate_uword( const HDSName& oNameIn, const Int& iDatum,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "screate_uword" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "screate_uword" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_uword" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "screate_uword" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_uword" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "screate_uword" ) );
  }
  
  
  // Create the scalar _UWORD HDS locator and put the datum into it
  
  try {
    New( oNameIn, HDSType( "_UWORD" ), HDSDim(), bReplace );
    find( oNameIn );
    put_uword( Array<Int>( IPosition(1,1), iDatum ) );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _UWORD HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "screate_uword" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::screate_word

Description:
------------
This public member function creates a new scalar _WORD HDS locator and puts
the datum into it.

Inputs:
-------
oNameIn  - The HDS locator name.
iDatum   - The datum.
bReplace - The replacement flag (default = False).

Outputs:
--------
None.

Modification history:
---------------------
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::screate_word( const HDSName& oNameIn, const Int& iDatum,
    const Bool& bReplace ) {

  // Declare the local variables
  
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag
  
  
  // Check the access mode, and present HDS status, locator, and structure flag

  if ( poAccess->mode().matches( "READ" ) ) {
    throw( ermsg( "Invalid HDS access mode", "HDSFile", "screate_word" ) );
  }

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "screate_word" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_word" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "screate_word" ) );
  }
  
  try {
    bStruc = struc();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "screate_word" ) );
  }
  
  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile",
        "screate_word" ) );
  }
  
  
  // Create the scalar _WORD HDS locator and put the datum into it
  
  try {
    New( oNameIn, HDSType( "_WORD" ), HDSDim(), bReplace );
    find( oNameIn );
    put_word( Array<Int>( IPosition(1,1), iDatum ) );
    annul();
  }
  
  catch ( AipsError oAipsError ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "Error creating _WORD HDS locator\n" + oAipsError.getMesg(),
        "HDSFile", "screate_word" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::shape

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
1998 Nov 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSDim HDSFile::shape( void ) const {

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "shape" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "shape" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "shape" ) );
  }
  
  
  // Get and return the HDS locator shape
  
  try {
    return( aoLocator[uiLocator].shape() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::shape( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "shape" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::size

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
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::size( void ) const {

  // Declare the local variables

  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "size" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "size" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "size" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "size" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "size" ) );
  }


  // Get and return the HDS locator size
  
  try {
    return( aoLocator[uiLocator].size() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::size( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "size" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::slice

Description:
------------
This public member function "slices" into an HDS locator.

Inputs:
-------
oDimLowIn  - The HDS locator slice lower limits.
oDimHighIn - The HDS locator slice upper limits.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::slice( const HDSDim& oDimLowIn, const HDSDim& oDimHighIn ) {

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "slice" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "slice" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "slice" ) );
  }
  
  
  // Check the HDS locator number and inputs
  
  HDSDim oDimLow = HDSDim( oDimLowIn );
  HDSDim oDimHigh = HDSDim( oDimHighIn );
  
  if ( uiLocator >= NUM_LOCATOR_MAX ) {
    throw( ermsg( "Maximum number of HDS locators reached", "HDSFile",
        "slice" ) );
  }
  
  if ( !checkSlice( oDimLow, oDimHigh ) ) {
    throw( ermsg( "Invalid HDS object dimensions", "HDSFile", "slice" ) );
  }
  
  if ( checkSameSlice( oDimLow, oDimHigh ) ) {
    return;
  }
  
  
  // "Slice" into the HDS locator and get its locator

  HDSWrapper::dat_slice( (const char* const) aoLocator[uiLocator].ploc(),
      (const int) oDimLow.nelements(), (const int* const) oDimLow.ppdim(),
      (const int* const) oDimHigh.ppdim(),
      (char* const) aoLocator[uiLocator + 1].ploc(),
      (int* const) aoLocator[uiLocator + 1].pstatus() );
  
  if ( aoLocator[uiLocator + 1].status() != OK ) {
    aoLocator[uiLocator + 1].recover();
    throw( ermsg( "HDSWrapper::dat_slice( ) error", "HDSFile", "slice" ) );
  }
  
  uiLocator += 1;
  
  
  // Return
  
  return;
  
}

// -----------------------------------------------------------------------------

/*

HDSFile::state

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
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool HDSFile::state( void ) const {

  // Declare the local variables

  Bool bPrim;  // The HDS locator primitive flag
  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "state" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "state" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "state" ) );
  }
  
  try {
    bPrim = prim();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "prim( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "state" ) );
  }
  
  if ( !bPrim ) {
    throw( ermsg( "HDS locator must be a primitive", "HDSFile", "state" ) );
  }


  // Get and return the HDS locator state flag
  
  try {
    return( aoLocator[uiLocator].state() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::state( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "state" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::struc

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
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool HDSFile::struc( void ) const {

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "struc" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "struc" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "struc" ) );
  }


  // Get and return the HDS locator structure flag

  try {
    return( aoLocator[uiLocator].struc() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::struc( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "struc" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::there

Description:
------------
This public member function the HDS locator existence flag.

Inputs:
-------
oNameIn - The HDS locator name.

Outputs:
--------
The HDS locator existence flag, returned via the function value.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool HDSFile::there( const HDSName& oNameIn ) {

  // Declare the local variables
  
  bool bThere; // The HDS locator existence flag
  Bool bStruc; // The HDS locator structure flag
  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "there" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "there" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "there" ) );
  }

  try {
    bStruc = struc();
  }

  catch( AipsError oAipsError ) {
    throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "there" ) );
  }

  if ( !bStruc ) {
    throw( ermsg( "HDS locator must be a structure", "HDSFile", "there" ) );
  }
  
  
  // Check the HDS locator number
  
  if ( uiLocator >= NUM_LOCATOR_MAX ) {
    throw( ermsg( "Maximum number of HDS locators reached", "HDSFile",
        "there" ) );
  }
  
  
  // Get and return the HDS locator existence flag
  
  HDSWrapper::dat_there( (const char* const) aoLocator[uiLocator].ploc(),
      (const char* const) oNameIn.chars(), (bool* const) &bThere,
      (int* const) aoLocator[uiLocator].pstatus() );
  
  if ( aoLocator[uiLocator].status() != OK ) {
    aoLocator[uiLocator].on();
    throw( ermsg( "HDSWrapper::dat_there( ) error", "HDSFile", "there" ) );
  }
  
  return( (Bool) bThere );

}

// -----------------------------------------------------------------------------

/*

HDSFile::top

Description:
------------
This public member function annuls all HDS locators except the top one.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::top( void ) {

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "top" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "top" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "top" ) );
  }

  if ( uiLocator == 1 ) {
    cout << msg( "Already at the top HDS locator\n", "HDSFile", "top",
        WARN ).getMesg() << flush;
  }


  // Annul all HDS locators except the top one
  
  try {
    annul( uiLocator - 1 );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "annul( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "top" ) );
  }
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::type

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
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSType HDSFile::type( void ) const {

  // Declare the local variables

  Bool bValid; // The HDS locator validity flag


  // Check the present HDS status and locator

  if ( aoLocator[uiLocator].status() != OK ) {
    throw( ermsg( "Error associated with present HDS locator", "HDSFile",
        "type" ) );
  }

  try {
    bValid = valid();
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "valid( ) error\n" + oAipsError.getMesg(), "HDSFile",
        "type" ) );
  }
  
  if ( !bValid ) {
    throw( ermsg( "Invalid present HDS locator", "HDSFile", "type" ) );
  }


  // Get and return the HDS locator type
  
  try {
    return( aoLocator[uiLocator].type() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::type( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "type" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::valid

Description:
------------
This public member function returns the present HDS locator validity flag.

Inputs:
-------
None.

Outputs:
--------
The present HDS locator validity flag, returned via the function value.

Modification history:
---------------------
1998 Nov 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool HDSFile::valid( void ) const {  

  // Get and return the HDS locator validity flag

  try {
    return( aoLocator[uiLocator].valid() );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "HDSLocator::valid( ) error\n" + oAipsError.getMesg(),
        "HDSFile", "valid" ) );
  }

}

// -----------------------------------------------------------------------------

/*

HDSFile::version

Description:
------------
This public member function returns the HDSFile{ } version.

Inputs:
-------
None.

Outputs:
--------
The HDSFile{ } version, returned via the function value.

Modification history:
---------------------
1999 Feb 14 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String HDSFile::version( void ) const {

  // Return the HDSFile{ } version
  
  return( String( "2.0" ) );

}

// -----------------------------------------------------------------------------

/*

HDSFile::checkSlice

Description:
------------
This public member function checks an HDS object slice.

Inputs:
-------
oSliceLow  - The lower limits of the slice.
oSliceHigh - The higher limits of the slice.

Outputs:
--------
The check boolean, returned via the function value.

Modification history:
---------------------
2000 Aug 31 - Nicholas Elias, USNO/NPOI
              Public member functions created.

*/

// -----------------------------------------------------------------------------

Bool HDSFile::checkSlice( const HDSDim& oSliceLow, const HDSDim& oSliceHigh )
    const {  
  
  // Check the HDS object slices and return the boolean

  uInt uiNumDim = numDim();
  HDSDim oShape = shape();
  
  if ( uiNumDim == 0 || uiNumDim > 3 ) {
    return( False );
  }
  
  if ( oSliceLow.nelements() != uiNumDim ) {
    return( False );
  }
  
  if ( oSliceHigh.nelements() != uiNumDim ) {
    return( False );
  }
  
  if ( !oSliceLow.check( oSliceHigh ) ) {
    return( False );
  }
  
  HDSDim oOnes = HDSDim( Vector<Int>( uiNumDim, 1 ) );
  
  if ( !oOnes.check( oSliceLow ) ) {
    return( False );
  }
  
  if ( !oSliceHigh.check( oShape ) ) {
    return( False );
  }
  
  return( True );
  
}

// -----------------------------------------------------------------------------

/*

HDSFile::checkSameSlice

Description:
------------
This public member function checks if an input HDS object slice is the same as
the present slice.

Inputs:
-------
oSliceLow  - The lower limits of the slice.
oSliceHigh - The higher limits of the slice.

Outputs:
--------
The check boolean, returned via the function value.

Modification history:
---------------------
2000 Aug 31 - Nicholas Elias, USNO/NPOI
              Public member functions created.

*/

// -----------------------------------------------------------------------------

Bool HDSFile::checkSameSlice( const HDSDim& oSliceLow,
    const HDSDim& oSliceHigh ) const {  
  
  // Check the HDS object slices and return the boolean

  uInt uiNumDim = numDim();
  HDSDim oShape = shape();
  
  HDSDim oOnes = HDSDim( Vector<Int>( uiNumDim, 1 ) );

  if ( oSliceLow == oOnes && oSliceHigh == oShape ) {
    return( True );
  }
  
  return( False );
  
}

// -----------------------------------------------------------------------------

/*

HDSFile::dimMax

Description:
------------
This static public member function returns the maximum number of dimensions.

Inputs:
-------
None.

Outputs:
--------
The maximum number of dimensions, returned via the function value.

Modification history:
---------------------
2000 Aug 31 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::dimMax( void ) {

  // Return the maximum number of dimensions
  
  return( HDSDim::MXDIM );

}

// -----------------------------------------------------------------------------

/*

HDSFile::locatorMax

Description:
------------
This static public member function returns the maximum number of locators.

Inputs:
-------
None.

Outputs:
--------
The maximum number of locators, returned via the function value.

Modification history:
---------------------
2000 Aug 29 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::locatorMax( void ) {

  // Return the maximum number of locators
  
  return( HDSFile::NUM_LOCATOR_MAX );

}

// -----------------------------------------------------------------------------

/*

HDSFile::noLocator

Description:
------------
This static public member function returns the no-locator string.

Inputs:
-------
None.

Outputs:
--------
The no-locator string, returned via the function value.

Modification history:
---------------------
2000 Aug 29 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

String HDSFile::noLocator( void ) {

  // Return the no-locator string
  
  return( HDSFile::NOLOC );

}

// -----------------------------------------------------------------------------

/*

HDSFile::sizeLocator

Description:
------------
This static public member function returns the locator size.

Inputs:
-------
None.

Outputs:
--------
The locator size, returned via the function value.

Modification history:
---------------------
2000 Aug 29 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::sizeLocator( void ) {

  // Return the locator size
  
  return( HDSFile::SZLOC );

}

// -----------------------------------------------------------------------------

/*

HDSFile::sizeMode

Description:
------------
This static public member function returns the mode size.

Inputs:
-------
None.

Outputs:
--------
The mode size, returned via the function value.

Modification history:
---------------------
2000 Aug 29 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::sizeMode( void ) {

  // Return the mode size
  
  return( HDSAccess::SZMOD );

}

// -----------------------------------------------------------------------------

/*

HDSFile::sizeName

Description:
------------
This static public member function returns the name size.

Inputs:
-------
None.

Outputs:
--------
The name size, returned via the function value.

Modification history:
---------------------
2000 Aug 29 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::sizeName( void ) {

  // Return the name size
  
  return( HDSName::SZNAM );

}

// -----------------------------------------------------------------------------

/*

HDSFile::sizeType

Description:
------------
This static public member function returns the type size.

Inputs:
-------
None.

Outputs:
--------
The type size, returned via the function value.

Modification history:
---------------------
2000 Aug 29 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSFile::sizeType( void ) {

  // Return the type size
  
  return( HDSType::SZTYP );

}

// -----------------------------------------------------------------------------

/*

HDSFile::operator=

Description:
------------
This public member function redfines operator=( ).

Inputs:
-------
oFileIn - The HDSFile{ } object.

Outputs:
--------
None.

Modification history:
---------------------
1999 Sep 16 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSFile::operator=( const HDSFile& oFileIn ) {

  // Declare the local variables
  
  uInt uiLocatorLocal; // The HDSLocator{ } counter


  // Reset the private variables and return
  
  delete poAccess;
  delete poLocatorSave;
  
  for ( uiLocatorLocal = 0; uiLocatorLocal <= NUM_LOCATOR_MAX;
      uiLocatorLocal++ ) {
    aoLocator[uiLocatorLocal] = HDSLocator();
  }
  
  poAccess = new HDSAccess( oFileIn.file(), oFileIn.mode() );
  
  poLocatorSave = new HDSLocator( oFileIn.locators() );
  
  uiLocator = oFileIn.locator();
  for ( uiLocatorLocal = 0; uiLocatorLocal <= uiLocator; uiLocatorLocal++ ) {
    aoLocator[uiLocatorLocal] = oFileIn.locatord( uiLocatorLocal );
  }
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSFile::className

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
1999 Feb 05 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String HDSFile::className( void ) const {

  // Return the class name
  
  return( String( "HDSFile" ) );

}

// -----------------------------------------------------------------------------

/*

HDSFile::methods

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
1999 Feb 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> HDSFile::methods( void ) const {

  // Return the method names
  
  Vector<String> oMethod(93);
  
  oMethod(0) = String( "alter" );
  oMethod(1) = String( "annul" );
  oMethod(2) = String( "cell" );
  oMethod(3) = String( "clen" );
  oMethod(4) = String( "copy" );
  oMethod(5) = String( "copy2file" );
  oMethod(6) = String( "create_byte" );
  oMethod(7) = String( "create_char" );
  oMethod(8) = String( "create_double" );
  oMethod(9) = String( "create_integer" );
  oMethod(10) = String( "create_logical" );
  oMethod(11) = String( "create_real" );
  oMethod(12) = String( "create_ubyte" );
  oMethod(13) = String( "create_uword" );
  oMethod(14) = String( "create_word" );
  oMethod(15) = String( "erase" );
  oMethod(16) = String( "file" );
  oMethod(17) = String( "find" );
  oMethod(18) = String( "get_byte" );
  oMethod(19) = String( "get_char" );
  oMethod(20) = String( "get_double" );
  oMethod(21) = String( "get_integer" );
  oMethod(22) = String( "get_logical" );
  oMethod(23) = String( "get_real" );
  oMethod(24) = String( "get_ubyte" );
  oMethod(25) = String( "get_uword" );
  oMethod(26) = String( "get_word" );
  oMethod(27) = String( "Goto" );
  oMethod(28) = String( "id" );
  oMethod(29) = String( "index" );
  oMethod(30) = String( "len" );
  oMethod(31) = String( "locator" );
  oMethod(32) = String( "list" );
  oMethod(33) = String( "mode" );
  oMethod(34) = String( "move" );
  oMethod(35) = String( "name" );
  oMethod(36) = String( "ncomp" );
  oMethod(37) = String( "New" );
  oMethod(38) = String( "numDim" );
  oMethod(39) = String( "obtain_byte" );
  oMethod(40) = String( "obtain_char" );
  oMethod(41) = String( "obtain_double" );
  oMethod(42) = String( "obtain_integer" );
  oMethod(43) = String( "obtain_logical" );
  oMethod(44) = String( "obtain_real" );
  oMethod(45) = String( "obtain_ubyte" );
  oMethod(46) = String( "obtain_uword" );
  oMethod(47) = String( "obtain_word" );
  oMethod(48) = String( "path" );
  oMethod(49) = String( "prec" );
  oMethod(50) = String( "prim" );
  oMethod(51) = String( "put_byte" );
  oMethod(52) = String( "put_char" );
  oMethod(53) = String( "put_double" );
  oMethod(54) = String( "put_integer" );
  oMethod(55) = String( "put_logical" );
  oMethod(56) = String( "put_real" );
  oMethod(57) = String( "put_ubyte" );
  oMethod(58) = String( "put_uword" );
  oMethod(59) = String( "put_word" );
  oMethod(60) = String( "recover" );
  oMethod(61) = String( "renam" );
  oMethod(62) = String( "reset" );
  oMethod(63) = String( "retyp" );
  oMethod(64) = String( "save" );
  oMethod(65) = String( "screate_byte" );
  oMethod(66) = String( "screate_char" );
  oMethod(67) = String( "screate_double" );
  oMethod(68) = String( "screate_integer" );
  oMethod(69) = String( "screate_logical" );
  oMethod(70) = String( "screate_real" );
  oMethod(71) = String( "screate_ubyte" );
  oMethod(72) = String( "screate_uword" );
  oMethod(73) = String( "screate_word" );
  oMethod(74) = String( "shape" );
  oMethod(75) = String( "size" );
  oMethod(76) = String( "slice" );
  oMethod(77) = String( "state" );
  oMethod(78) = String( "struc" );
  oMethod(79) = String( "there" );
  oMethod(80) = String( "top" );
  oMethod(81) = String( "type" );
  oMethod(82) = String( "valid" );
  oMethod(83) = String( "version" );
  oMethod(84) = String( "checkSlice" );
  oMethod(85) = String( "checkSameSlice" );
  oMethod(86) = String( "dimMax" );
  oMethod(87) = String( "locatorMax" );
  oMethod(88) = String( "noLocator" );
  oMethod(89) = String( "sizeLocator" );
  oMethod(90) = String( "sizeMode" );
  oMethod(91) = String( "sizeName" );
  oMethod(92) = String( "sizeType" );
  
  return( oMethod );

}

// -----------------------------------------------------------------------------

/*

HDSFile::noTraceMethods

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
1999 Sep 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> HDSFile::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}

