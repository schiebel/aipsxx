//# HDSWrapper.cc is part of Cuttlefish (NPOI data reduction package)
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
//# $Id: HDSWrapper.cc,v 19.0 2003/07/16 06:03:11 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

HDSWrapper.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the HDSWrapper{ } class member functions.

Public member functions:
------------------------
dat_alter, dat_annul, dat_cell, dat_clen, dat_clone, dat_copy, dat_erase,
dat_ermsg, dat_find, dat_get, dat_index, dat_len, dat_move, dat_name, dat_ncomp,
dat_new, dat_prec, dat_prim, dat_renam, dat_reset, dat_retyp, dat_shape,
dat_size, dat_slice, dat_state, dat_struc, dat_there, dat_type, dat_valid,
hds_copy, hds_open, hds_new, hds_trace.

Modification history:
---------------------
1998 Nov 12 - Nicholas Elias, USNO/NPOI
              File created with public member functions dat_ermsg( ),
              dat_prim( ), dat_struc( ), and hds_open( ).
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member functions dat_alter( ), dat_clen( ), dat_len( ),
	      dat_name( ), dat_prec( ), dat_renam( ), dat_reset( ),
	      dat_retyp( ), dat_shape( ), dat_size( ), dat_state( ),
	      dat_type( ), and dat_valid( ) added.
1998 Nov 19 - Nicholas Elias, USNO/NPOI
              Public member function hds_trace( ) added.
1998 Nov 23 - Nicholas Elias, USNO/NPOI
              Public member functions dat_annul( ), dat_erase( ), dat_find( ),
	      dat_index( ), dat_ncomp( ), and dat_there( ) added.
1998 Nov 24 - Nicholas Elias, USNO/NPOI
              Public member functions dat_copy( ), dat_move( ), and hds_new( )
	      added.
1998 Nov 25 - Nicholas Elias, USNO/NPOI
              Public member functions dat_cell( ), dat_get( ), dat_new( ),
	      dat_put( ), dat_slice( ), and hds_copy( ) added.
1999 Jan 22 - Nicholas Elias, USNO/NPOI
              Public member function dat_clone( ) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/HDS/HDSWrapper.h> // HDS wrapper

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_alter

Description:
------------
This public member function is the fnc.h wrapper for dat_alter( ).

Inputs:
-------
acLocator - The HDS locator.
iNumDim   - The number of dimensions.
aiDim     - The dimensions.
piStatus  - The HDS status.

Outputs:
--------
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_alter( const char* const acLocator, const int iNumDim,
    const int* const aiDim, int* const piStatus ) {

  // Declare the local variables

  int iDim; // The HDS object dimension counter


  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_INTEGER( fNumDim );
  fNumDim = iNumDim;

  DECLARE_INTEGER_ARRAY( fDim, fNumDim );
  for ( iDim = 0; iDim < iNumDim; iDim++ ) {
    fDim[iDim] = aiDim[iDim];
  }

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_alter( )

  F77_CALL(dat_alter)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fNumDim ),
      INTEGER_ARRAY_ARG( fDim ), INTEGER_ARG( &fStatus )
      TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_annul

Description:
------------
This public member function is the fnc.h wrapper for dat_annul( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
acLocator - The HDS locator.
piStatus  - The HDS status.

Modification history:
---------------------
1998 Nov 23 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_annul( char* const acLocator, int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_annul( )

  F77_CALL(dat_annul)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fStatus )
      TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  memcpy( (void*) acLocator, (const void*) fLocator, (size_t) fLocator_length );
  
  *piStatus = fStatus;


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_cell

Description:
------------
This public member function is the fnc.h wrapper for dat_cell( ).

Inputs:
-------
acLocator - The HDS locator.
iNumDim   - The number of HDS object dimensions.
aiDim     - The HDS object cell.
piStatus  - The HDS status.

Outputs:
--------
acLocatorCell - The HDS locator corresponding to the HDS object cell.
piStatus      - The HDS status.

Modification history:
---------------------
1998 Nov 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_cell( const char* const acLocator, const int iNumDim,
    const int* const aiDim, char* const acLocatorCell, int* const piStatus ) {

  // Declare the local variables
  
  int iDim; // The HDS object dimension counter


  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );
  
  DECLARE_INTEGER( fNumDim );
  fNumDim = iNumDim;
  
  DECLARE_INTEGER_ARRAY( fDim, fNumDim );
  for ( iDim = 0; iDim < iNumDim; iDim++ ) {
    fDim[iDim] = aiDim[iDim];
  }
  
  DECLARE_CHARACTER_DYN( fLocatorCell );
  F77_CREATE_CHARACTER( fLocatorCell, DAT__SZLOC );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_cell( )

  F77_CALL(dat_cell)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fNumDim ),
      INTEGER_ARRAY_ARG( fDim ), CHARACTER_ARG( fLocatorCell ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) TRAIL_ARG( fLocatorCell ) );


  // Set the return variables and free the FORTRAN memory

  memcpy( (void*) acLocatorCell, (const void*) fLocatorCell,
      (size_t) fLocatorCell_length );
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fLocatorCell );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_clen

Description:
------------
This public member function is the fnc.h wrapper for dat_clen( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
piCLen   - The HDS object character length.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_clen( const char* const acLocator, int* const piCLen,
    int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_INTEGER( fCLen );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_clen( )

  F77_CALL(dat_clen)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fCLen ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  *piCLen = fCLen;

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_clone

Description:
------------
This public member function is the fnc.h wrapper for dat_clone( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
acLocatorClone - The cloned HDS locator.
piStatus       - The HDS status.

Modification history:
---------------------
1999 Jan 22 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_clone( const char* const acLocator,
    char* const acLocatorClone, int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );
  
  DECLARE_CHARACTER_DYN( fLocatorClone );
  F77_CREATE_CHARACTER( fLocatorClone, DAT__SZLOC );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_clone( )

  F77_CALL(dat_clone)( CHARACTER_ARG( fLocator ),
      CHARACTER_ARG( fLocatorClone ), INTEGER_ARG( &fStatus )
      TRAIL_ARG( fLocator ) TRAIL_ARG( fLocatorClone ) );


  // Set the return variables and free the FORTRAN memory

  memcpy( (void*) acLocatorClone, (const void*) fLocatorClone,
      (size_t) fLocatorClone_length );
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fLocatorClone );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_copy

Description:
------------
This public member function is the fnc.h wrapper for dat_copy( ).

Inputs:
-------
acLocator     - The HDS locator.
acLocatorCopy - The HDS locator corresponding to the HDS copy object name.
acName        - The HDS copy object name.
piStatus      - The HDS status.

Outputs:
--------
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 24 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_copy( const char* const acLocator,
    const char* const acLocatorCopy, const char* const acName,
    int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_CHARACTER_DYN( fLocatorCopy );
  F77_CREATE_CHARACTER( fLocatorCopy, DAT__SZLOC );
  memcpy( (void*) fLocatorCopy, (const void*) acLocatorCopy,
      (size_t) fLocatorCopy_length );

  DECLARE_CHARACTER_DYN( fName );
  F77_CREATE_CHARACTER( fName, strlen( acName ) );
  memcpy( (void*) fName, (const void*) acName, (size_t) fName_length );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_copy( )

  F77_CALL(dat_copy)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fLocatorCopy ),
      CHARACTER_ARG( fName ), INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator )
      TRAIL_ARG( fLocatorCopy ) TRAIL_ARG( fName ) );


  // Set the return variables and free the FORTRAN memory
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fLocatorCopy );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_erase

Description:
------------
This public member function is the fnc.h wrapper for dat_erase( ).

Inputs:
-------
acLocator - The HDS locator.
acName    - The HDS object name.
piStatus  - The HDS status.

Outputs:
--------
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 23 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_erase( const char* const acLocator,
    const char* const acName, int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_CHARACTER_DYN( fName );
  F77_CREATE_CHARACTER( fName, strlen( acName ) );
  memcpy( (void*) fName, (const void*) acName, (size_t) fName_length );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_erase( )

  F77_CALL(dat_erase)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fName ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) TRAIL_ARG( fName ) );


  // Set the return variables and free the FORTRAN memory

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fName );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_ermsg

Description:
------------
This public member function is the fnc.h wrapper for dat_ermsg( ).

Inputs:
-------
iStatus - The HDS status.

Outputs:
--------
piLength  - The message length.
acMessage - The message.

Modification history:
---------------------
1998 Nov 12 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_ermsg( const int iStatus, int* const piLength,
    char* const acMessage ) {

  // Declare the FORTRAN variables

  DECLARE_INTEGER( fStatus );
  fStatus = iStatus;

  DECLARE_INTEGER( fLength );

  DECLARE_CHARACTER_DYN( fMessage );
  F77_CREATE_CHARACTER( fMessage, EMS__SZMSG );


  // Call dat_ermsg( )

  F77_CALL(dat_ermsg)( INTEGER_ARG( &fStatus ), INTEGER_ARG( &fLength ),
      CHARACTER_ARG( fMessage ) TRAIL_ARG( fMessage ) );


  // Set the return variables and free the FORTRAN memory

  *piLength = fLength;

  memcpy( (void*) acMessage, (const void*) fMessage, (size_t) *piLength );
  acMessage[*piLength] = '\0';

  F77_FREE_CHARACTER( fMessage );


  // return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_find

Description:
------------
This public member function is the fnc.h wrapper for dat_find( ).

Inputs:
-------
acLocator - The HDS locator.
acName    - The HDS object name.
piStatus  - The HDS status.

Outputs:
--------
acLocatorFind - The HDS locator corresponding to the HDS find object name.
piStatus      - The HDS status.

Modification history:
---------------------
1998 Nov 23 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_find( const char* const acLocator,
    const char* const acName, char* const acLocatorFind, int* const piStatus ) {

  // Declare the local variables

  char acLocatorTemp[DAT__SZLOC]; // The temporary locator (keeps the compiler
                                  // happy)
  char acNameTemp[DAT__SZNAM];    // The temporary name (keeps the compiler
                                  // happy)


  // Declare the FORTRAN variables

  DECLARE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) acLocatorTemp, (const void*) acLocator, (size_t) DAT__SZLOC );
  cnf_expch( acLocatorTemp, fLocator, fLocator_length );

  DECLARE_CHARACTER_DYN( fName );
  strcpy( acNameTemp, acName );
  F77_CREATE_CHARACTER( fName, strlen( acName ) );
  cnf_exprt( acNameTemp, fName, fName_length );
  
  DECLARE_CHARACTER( fLocatorFind, DAT__SZLOC );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_find( )

  F77_CALL(dat_find)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fName ),
      CHARACTER_ARG( fLocatorFind ), INTEGER_ARG( &fStatus )
      TRAIL_ARG( fLocator ) TRAIL_ARG( fName ) TRAIL_ARG( fLocatorFind ) );


  // Set the return variables and free the FORTRAN memory

  cnf_impch( fLocatorFind, fLocatorFind_length, acLocatorFind );

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fName );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_get

Description:
------------
This public member function is the fnc.h wrapper for dat_get( ).  NB: The memory
for the output HDS object data array is allocated in this public member function
but must be deallocated elsewhere.

Inputs:
-------
acLocator - The HDS locator.
acType    - The HDS object type.
iNumDim   - The number of HDS object dimensions.
aiDim     - The HDS object dimensions.
piStatus  - The HDS status.

Outputs:
--------
(*aucData) - The HDS object data.
piStatus   - The HDS status.

Modification history:
---------------------
1998 Nov 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_get( const char* const acLocator, const char* const acType,
    const int iNumDim, const int* const aiDim, unsigned char* (*aucData),
    int* const piStatus ) {

  // Declare the local variables
  
  int iDim;        // The HDS object dimension counter
  int iNumByte;    // The number of bytes per HDS object element
  int iNumElement; // The number of HDS object elements


  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_CHARACTER_DYN( fType );
  F77_CREATE_CHARACTER( fType, strlen( acType ) );
  memcpy( (void*) fType, (const void*) acType, (size_t) fType_length );
  
  DECLARE_INTEGER( fNumDim );
  fNumDim = iNumDim;

  DECLARE_INTEGER_ARRAY( fDim, fNumDim );
  for ( iDim = 0; iDim < iNumDim; iDim++ ) {
    fDim[iDim] = aiDim[iDim];
  }
  
  iNumElement = 1;
  for ( iDim = 0; iDim < iNumDim; iDim++ ) {
    iNumElement *= aiDim[iDim];
  }
  
  dat_len( acLocator, &iNumByte, piStatus );
  if ( *piStatus != SAI__OK ) {
    F77_FREE_CHARACTER( fLocator );
    F77_FREE_CHARACTER( fType );
    return;
  }

  DECLARE_CHARACTER_ARRAY( fData, iNumByte, iNumElement );
  
  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_get( )

  F77_CALL(dat_get)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fType ),
      INTEGER_ARG( &fNumDim ), INTEGER_ARRAY_ARG( fDim ),
      CHARACTER_ARRAY_ARG( fData ), INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator )
      TRAIL_ARG( fType ) TRAIL_ARG( fData ) );


  // Set the return variables and free the FORTRAN memory
  
  (*aucData) = new unsigned char[iNumByte * iNumElement];
  memcpy( (void*) (*aucData), (const void*) fData,
      (size_t) ( iNumByte * iNumElement ) );
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fType );
  

  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_index

Description:
------------
This public member function is the fnc.h wrapper for dat_index( ).

Inputs:
-------
acLocator - The HDS locator.
iIndex    - The HDS object index.
piStatus  - The HDS status.

Outputs:
--------
acLocatorIndex - The HDS locator corresponding to the HDS index object.
piStatus       - The HDS status.

Modification history:
---------------------
1998 Nov 23 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_index( const char* const acLocator, const int iIndex,
    char* const acLocatorIndex, int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );
  
  DECLARE_INTEGER( fIndex );
  fIndex = iIndex;

  DECLARE_CHARACTER_DYN( fLocatorIndex );
  F77_CREATE_CHARACTER( fLocatorIndex, DAT__SZLOC );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_index( )

  F77_CALL(dat_index)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fIndex ),
      CHARACTER_ARG( fLocatorIndex ), INTEGER_ARG( &fStatus )
      TRAIL_ARG( fLocator ) TRAIL_ARG( fLocatorIndex ) );


  // Set the return variables and free the FORTRAN memory

  memcpy( (void*) acLocatorIndex, (const void*) fLocatorIndex,
      (size_t) fLocatorIndex_length );
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fLocatorIndex );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_len

Description:
------------
This public member function is the fnc.h wrapper for dat_len( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
piLen    - The HDS object length.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_len( const char* const acLocator, int* const piLen,
    int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_INTEGER( fLen );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_len( )

  F77_CALL(dat_len)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fLen ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  *piLen = fLen;

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_move

Description:
------------
This public member function is the fnc.h wrapper for dat_move( ).

Inputs:
-------
acLocator     - The HDS locator.
acLocatorMove - The HDS locator corresponding to the HDS move object name.
acName        - The HDS move object name.
piStatus      - The HDS status.

Outputs:
--------
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 24 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_move( const char* const acLocator,
    const char* const acLocatorMove, const char* const acName,
    int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_CHARACTER_DYN( fLocatorMove );
  F77_CREATE_CHARACTER( fLocatorMove, DAT__SZLOC );
  memcpy( (void*) fLocatorMove, (const void*) acLocatorMove,
      (size_t) fLocatorMove_length );

  DECLARE_CHARACTER_DYN( fName );
  F77_CREATE_CHARACTER( fName, strlen( acName ) );
  memcpy( (void*) fName, (const void*) acName, (size_t) fName_length );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_move( )

  F77_CALL(dat_move)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fLocatorMove ),
      CHARACTER_ARG( fName ), INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator )
      TRAIL_ARG( fLocatorMove ) TRAIL_ARG( fName ) );


  // Set the return variables and free the FORTRAN memory
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fLocatorMove );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_name

Description:
------------
This public member function is the fnc.h wrapper for dat_name( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
acName   - The HDS object name.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_name( const char* const acLocator, char* const acName,
    int* const piStatus ) {

  // Declare the local variables

  int iChar; // The character counter


  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_CHARACTER_DYN( fName );
  F77_CREATE_CHARACTER( fName, ( DAT__SZNAM + 1 ) );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_name( )

  F77_CALL(dat_name)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fName ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) TRAIL_ARG( fName ) );


  // Set the return variables and free the FORTRAN memory

  for ( iChar = 0; iChar < DAT__SZNAM; iChar++ ) {
    if ( isspace( fName[iChar] ) ) {
      fName[iChar] = '\0';
      break;
    }
  }

  fName[DAT__SZNAM] = '\0';

  memcpy( (void*) acName, (const void*) fName,
      strlen( (const char*) fName ) + 1 );
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fName );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_ncomp

Description:
------------
This public member function is the fnc.h wrapper for dat_ncomp( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
piNComp  - The number of HDS components.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 23 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_ncomp( const char* const acLocator, int* const piNComp,
    int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_INTEGER( fNComp );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_ncomp( )

  F77_CALL(dat_ncomp)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fNComp ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  *piNComp = fNComp;

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_new

Description:
------------
This public member function is the fnc.h wrapper for dat_new( ).

Inputs:
-------
acLocator - The HDS locator.
acName    - The HDS top object name.
acType    - The HDS top object type.
iNumDim   - The number of HDS object dimensions.
aiDim     - The HDS object dimensions.
piStatus  - The HDS status.

Outputs:
--------
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_new( const char* const acLocator, const char* const acName,
    const char* const acType, const int iNumDim, const int* const aiDim,
    int* const piStatus ) {

  // Declare the local variables
  
  int iDim; // The HDS object dimension counter


  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_CHARACTER_DYN( fName );
  F77_CREATE_CHARACTER( fName, strlen( acName ) );
  memcpy( (void*) fName, (const void*) acName, (size_t) fName_length );

  DECLARE_CHARACTER_DYN( fType );
  F77_CREATE_CHARACTER( fType, strlen( acType ) );
  memcpy( (void*) fType, (const void*) acType, (size_t) fType_length );
  
  DECLARE_INTEGER( fNumDim );
  fNumDim = iNumDim;

  DECLARE_INTEGER_ARRAY( fDim, fNumDim );
  for ( iDim = 0; iDim < iNumDim; iDim++ ) {
    fDim[iDim] = aiDim[iDim];
  }

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_new( )

  F77_CALL(dat_new)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fName ),
      CHARACTER_ARG( fType ), INTEGER_ARG( &fNumDim ),
      INTEGER_ARRAY_ARG( fDim ), INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator )
      TRAIL_ARG( fName ) TRAIL_ARG( fType ) );


  // Set the return variables and free the FORTRAN memory
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fName );
  F77_FREE_CHARACTER( fType );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_prec

Description:
------------
This public member function is the fnc.h wrapper for dat_prec( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
piPrec   - The HDS object precision.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_prec( const char* const acLocator, int* const piPrec,
    int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_INTEGER( fPrec );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_prec( )

  F77_CALL(dat_prec)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fPrec ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  *piPrec = fPrec;

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_prim

Description:
------------
This public member function is the fnc.h wrapper for dat_prim( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
pbPrim   - The HDS primitive flag.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 12 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_prim( const char* const acLocator, bool* const pbPrim,
    int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_LOGICAL( fPrim );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_prim( )

  F77_CALL(dat_prim)( CHARACTER_ARG( fLocator ), LOGICAL_ARG( &fPrim ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  *pbPrim = fPrim;

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_put

Description:
------------
This public member function is the fnc.h wrapper for dat_put( ).

Inputs:
-------
acLocator - The HDS locator.
acType    - The HDS object type.
iNumDim   - The number of HDS object dimensions.
aiDim     - The HDS object dimensions.
aucData   - The HDS object data.
piStatus  - The HDS status.

Outputs:
--------
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_put( const char* const acLocator, const char* const acType,
    const int iNumDim, const int* const aiDim,
    const unsigned char* const aucData, int* const piStatus ) {

  // Declare the local variables
  
  int iDim;        // The HDS object dimension counter
  int iNumByte;    // The number of bytes per HDS object element
  int iNumElement; // The number of HDS object elements


  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_CHARACTER_DYN( fType );
  F77_CREATE_CHARACTER( fType, strlen( acType ) );
  memcpy( (void*) fType, (const void*) acType, (size_t) fType_length );
  
  DECLARE_INTEGER( fNumDim );
  fNumDim = iNumDim;

  DECLARE_INTEGER_ARRAY( fDim, fNumDim );
  for ( iDim = 0; iDim < iNumDim; iDim++ ) {
    fDim[iDim] = aiDim[iDim];
  }
  
  iNumElement = 1;
  for ( iDim = 0; iDim < iNumDim; iDim++ ) {
    iNumElement *= aiDim[iDim];
  }
  
  dat_len( acLocator, &iNumByte, piStatus );
  if ( *piStatus != SAI__OK ) {
    F77_FREE_CHARACTER( fLocator );
    F77_FREE_CHARACTER( fType );
    return;
  }

  DECLARE_CHARACTER_ARRAY( fData, iNumByte, iNumElement );
  memcpy( (void*) fData, (const void*) aucData,
      (size_t) ( iNumByte * iNumElement ) );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_put( )

  F77_CALL(dat_put)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fType ),
      INTEGER_ARG( &fNumDim ), INTEGER_ARRAY_ARG( fDim ),
      CHARACTER_ARRAY_ARG( fData ), INTEGER_ARG( &fStatus )
      TRAIL_ARG( fLocator ) TRAIL_ARG( fType ) TRAIL_ARG( fData ) );


  // Set the return variables and free the FORTRAN memory
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fType );
  

  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_renam

Description:
------------
This public member function is the fnc.h wrapper for dat_renam( ).

Inputs:
-------
acLocator - The HDS locator.
acName    - The HDS object name.
piStatus  - The HDS status.

Outputs:
--------
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_renam( const char* const acLocator,
    const char* const acName, int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_CHARACTER_DYN( fName );
  F77_CREATE_CHARACTER( fName, strlen( acName ) );
  memcpy( (void*) fName, (const void*) acName, (size_t) fName_length );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_renam( )

  F77_CALL(dat_renam)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fName ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) TRAIL_ARG( fName ) );


  // Set the return variables and free the FORTRAN memory

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fName );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_reset

Description:
------------
This public member function is the fnc.h wrapper for dat_reset( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_reset( const char* const acLocator, int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_reset( )

  F77_CALL(dat_reset)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fStatus )
      TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_retyp

Description:
------------
This public member function is the fnc.h wrapper for dat_retyp( ).

Inputs:
-------
acLocator - The HDS locator.
acType    - The HDS object type.
piStatus  - The HDS status.

Outputs:
--------
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_retyp( const char* const acLocator,
    const char* const acType, int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_CHARACTER_DYN( fType );
  F77_CREATE_CHARACTER( fType, strlen( acType ) );
  memcpy( (void*) fType, (const void*) acType, (size_t) fType_length );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_retyp( )

  F77_CALL(dat_retyp)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fType ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) TRAIL_ARG( fType ) );


  // Set the return variables and free the FORTRAN memory

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fType );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_shape

Description:
------------
This public member function is the fnc.h wrapper for dat_shape( ).

Inputs:
-------
acLocator - The HDS locator.
piNumDim  - The number of dimensions.
aiDim     - The dimensions.
piStatus  - The HDS status.

Outputs:
--------
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_shape( const char* const acLocator, int* const piNumDim,
    int* const aiDim, int* const piStatus ) {

  // Declare the local variables

  int iDim; // The HDS object dimension counter


  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_INTEGER( fNumDimMax );
  fNumDimMax = DAT__MXDIM;

  DECLARE_INTEGER( fNumDim );

  DECLARE_INTEGER_ARRAY( fDim, fNumDimMax );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_shape( )

  F77_CALL(dat_shape)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fNumDimMax ),
      INTEGER_ARRAY_ARG( fDim ), INTEGER_ARG( &fNumDim ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  *piNumDim = fNumDim;
  
  for ( iDim = 0; iDim < *piNumDim; iDim++ ) {
    aiDim[iDim] = fDim[iDim];
  }
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_size

Description:
------------
This public member function is the fnc.h wrapper for dat_size( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
piSize   - The HDS object size.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_size( const char* const acLocator, int* const piSize,
    int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_INTEGER( fSize );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_size( )

  F77_CALL(dat_size)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fSize ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  *piSize = fSize;

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_slice

Description:
------------
This public member function is the fnc.h wrapper for dat_slice( ).

Inputs:
-------
acLocator - The HDS locator.
iNumDim   - The number of HDS object dimensions.
aiDimLow  - The HDS object low dimensions.
aiDimHigh - The HDS object high dimensions.
piStatus  - The HDS status.

Outputs:
--------
acLocatorSlice - The HDS locator corresponding to the HDS object slice.
piStatus       - The HDS status.

Modification history:
---------------------
1998 Nov 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_slice( const char* const acLocator, const int iNumDim,
    const int* const aiDimLow, const int* const aiDimHigh,
    char* const acLocatorSlice, int* const piStatus ) {

  // Declare the local variables
  
  int iDim; // The HDS object dimension counter


  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );
  
  DECLARE_INTEGER( fNumDim );
  fNumDim = iNumDim;
  
  DECLARE_INTEGER_ARRAY( fDimLow, fNumDim );
  for ( iDim = 0; iDim < iNumDim; iDim++ ) {
    fDimLow[iDim] = aiDimLow[iDim];
  }
  
  DECLARE_INTEGER_ARRAY( fDimHigh, fNumDim );
  for ( iDim = 0; iDim < iNumDim; iDim++ ) {
    fDimHigh[iDim] = aiDimHigh[iDim];
  }
  
  DECLARE_CHARACTER_DYN( fLocatorSlice );
  F77_CREATE_CHARACTER( fLocatorSlice, DAT__SZLOC );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_slice( )

  F77_CALL(dat_slice)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fNumDim ),
      INTEGER_ARRAY_ARG( fDimLow ), INTEGER_ARRAY_ARG( fDimHigh ),
      CHARACTER_ARG( fLocatorSlice ), INTEGER_ARG( &fStatus )
      TRAIL_ARG( fLocator ) TRAIL_ARG( fLocatorSlice ) );


  // Set the return variables and free the FORTRAN memory

  memcpy( (void*) acLocatorSlice, (const void*) fLocatorSlice,
      (size_t) fLocatorSlice_length );
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fLocatorSlice );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_state

Description:
------------
This public member function is the fnc.h wrapper for dat_state( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
pbState  - The HDS state flag.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_state( const char* const acLocator, bool* const pbState,
    int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_LOGICAL( fState );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_state( )

  F77_CALL(dat_state)( CHARACTER_ARG( fLocator ), LOGICAL_ARG( &fState ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  *pbState = fState;

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_struc

Description:
------------
This public member function is the fnc.h wrapper for dat_struc( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
pbStruc  - The HDS structure flag.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 12 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_struc( const char* const acLocator, bool* const pbStruc,
    int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_LOGICAL( fStruc );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_struc( )

  F77_CALL(dat_struc)( CHARACTER_ARG( fLocator ), LOGICAL_ARG( &fStruc ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  *pbStruc = fStruc;

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_there

Description:
------------
This public member function is the fnc.h wrapper for dat_there( ).

Inputs:
-------
acLocator - The HDS locator.
acName    - The HDS object name.
piStatus  - The HDS status.

Outputs:
--------
pbThere  - The HDS "there" flag.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 23 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_there( const char* const acLocator,
    const char* const acName, bool* const pbThere, int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_CHARACTER_DYN( fName );
  F77_CREATE_CHARACTER( fName, strlen( acName ) );
  memcpy( (void*) fName, (const void*) acName, (size_t) fName_length );
  
  DECLARE_LOGICAL( fThere );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_there( )

  F77_CALL(dat_there)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fName ),
      LOGICAL_ARG( &fThere ), INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator )
      TRAIL_ARG( fName ) );


  // Set the return variables and free the FORTRAN memory

  *pbThere = fThere;

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fName );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_type

Description:
------------
This public member function is the fnc.h wrapper for dat_type( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
acType   - The HDS object type.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_type( const char* const acLocator, char* const acType,
    int* const piStatus ) {

  // Declare the local variables

  int iChar; // The character counter


  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_CHARACTER_DYN( fType );
  F77_CREATE_CHARACTER( fType, ( DAT__SZTYP + 1 ) );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_type( )

  F77_CALL(dat_type)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fType ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) TRAIL_ARG( fType ) );


  // Set the return variables and return the FORTRAN memory

  for ( iChar = 0; iChar < DAT__SZTYP; iChar++ ) {
    if ( isspace( fType[iChar] ) ) {
      fType[iChar] = '\0';
      break;
    }
  }
  
  fType[DAT__SZTYP] = '\0';

  memcpy( (void*) acType, (const void*) fType,
      strlen( (const char*) fType ) + 1 );
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fType );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::dat_valid

Description:
------------
This public member function is the fnc.h wrapper for dat_valid( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
pbValid  - The HDS validity flag.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::dat_valid( const char* const acLocator, bool* const pbValid,
    int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_LOGICAL( fValid );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call dat_valid( )

  F77_CALL(dat_valid)( CHARACTER_ARG( fLocator ), LOGICAL_ARG( &fValid ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  *pbValid = fValid;

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::hds_copy

Description:
------------
This public member function is the fnc.h wrapper for hds_copy( ).

Inputs:
-------
acLocator - The HDS locator.
acFile    - The HDS file name.
acName    - The HDS top object name.
piStatus  - The HDS status.

Outputs:
--------
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::hds_copy( const char* const acLocator,
    const char* const acFile, const char* const acName, int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_CHARACTER_DYN( fFile );
  F77_CREATE_CHARACTER( fFile, strlen( acFile ) );
  memcpy( (void*) fFile, (const void*) acFile, (size_t) fFile_length );

  DECLARE_CHARACTER_DYN( fName );
  F77_CREATE_CHARACTER( fName, strlen( acName ) );
  memcpy( (void*) fName, (const void*) acName, (size_t) fName_length );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call hds_copy( )

  F77_CALL(hds_copy)( CHARACTER_ARG( fLocator ), CHARACTER_ARG( fFile ),
      CHARACTER_ARG( fName ), INTEGER_ARG( &fStatus ) TRAIL_ARG( fLocator )
      TRAIL_ARG( fFile ) TRAIL_ARG( fName ) );


  // Set the return variables and free the FORTRAN memory
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fFile );
  F77_FREE_CHARACTER( fName );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::hds_new

Description:
------------
This public member function is the fnc.h wrapper for hds_new( ).

Inputs:
-------
acFile   - The HDS file name.
acName   - The HDS top object name.
acType   - The HDS top object type.
iNumDim  - The number of HDS object dimensions.
aiDim    - The HDS object dimensions.
piStatus - The HDS status.

Outputs:
--------
acLocator - The HDS locator.
piStatus  - The HDS status.

Modification history:
---------------------
1998 Nov 24 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::hds_new( const char* const acFile, const char* const acName,
    const char* const acType, const int iNumDim, const int* const aiDim,
    char* const acLocator, int* const piStatus ) {

  // Declare the local variables
  
  int iDim; // The HDS object dimension counter


  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fFile );
  F77_CREATE_CHARACTER( fFile, strlen( acFile ) );
  memcpy( (void*) fFile, (const void*) acFile, (size_t) fFile_length );

  DECLARE_CHARACTER_DYN( fName );
  F77_CREATE_CHARACTER( fName, strlen( acName ) );
  memcpy( (void*) fName, (const void*) acName, (size_t) fName_length );

  DECLARE_CHARACTER_DYN( fType );
  F77_CREATE_CHARACTER( fType, strlen( acType ) );
  memcpy( (void*) fType, (const void*) acType, (size_t) fType_length );
  
  DECLARE_INTEGER( fNumDim );
  fNumDim = iNumDim;

  DECLARE_INTEGER_ARRAY( fDim, fNumDim );
  for ( iDim = 0; iDim < iNumDim; iDim++ ) {
    fDim[iDim] = aiDim[iDim];
  }

  DECLARE_CHARACTER( fLocator, DAT__SZLOC );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call hds_new( )

  F77_CALL(hds_new)( CHARACTER_ARG( fFile ), CHARACTER_ARG( fName ),
      CHARACTER_ARG( fType ), INTEGER_ARG( &fNumDim ),
      INTEGER_ARRAY_ARG( fDim ), CHARACTER_ARG( fLocator ),
      INTEGER_ARG( &fStatus ) TRAIL_ARG( fFile ) TRAIL_ARG( fName )
      TRAIL_ARG( fType ) TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  memcpy( (void*) acLocator, (const void*) fLocator, (size_t) fLocator_length );
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fFile );
  F77_FREE_CHARACTER( fName );
  F77_FREE_CHARACTER( fType );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::hds_open

Description:
------------
This public member function is the fnc.h wrapper for hds_open( ).

Inputs:
-------
acFile   - The HDS file name.
acMode   - The HDS access mode.
piStatus - The HDS status.

Outputs:
--------
acLocator - The HDS locator.
piStatus  - The HDS status.

Modification history:
---------------------
1998 Nov 12 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::hds_open( const char* const acFile, const char* const acMode,
    char* const acLocator, int* const piStatus ) {

  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fFile );
  F77_CREATE_CHARACTER( fFile, strlen( acFile ) );
  memcpy( (void*) fFile, (const void*) acFile, (size_t) fFile_length );

  DECLARE_CHARACTER_DYN( fMode );
  F77_CREATE_CHARACTER( fMode, strlen( acMode ) );
  memcpy( (void*) fMode, (const void*) acMode, (size_t) fMode_length );

  DECLARE_CHARACTER( fLocator, DAT__SZLOC );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call hds_open( )

  F77_CALL(hds_open)( CHARACTER_ARG( fFile ), CHARACTER_ARG( fMode ),
      CHARACTER_ARG( fLocator ), INTEGER_ARG( &fStatus ) TRAIL_ARG( fFile )
      TRAIL_ARG( fMode ) TRAIL_ARG( fLocator ) );


  // Set the return variables and free the FORTRAN memory

  memcpy( (void*) acLocator, (const void*) fLocator, (size_t) fLocator_length );

  *piStatus = fStatus;

  F77_FREE_CHARACTER( fFile );
  F77_FREE_CHARACTER( fMode );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSWrapper::hds_trace

Description:
------------
This public member function is the fnc.h wrapper for hds_trace( ).

Inputs:
-------
acLocator - The HDS locator.
piStatus  - The HDS status.

Outputs:
--------
piNumLev - The number of levels.
acPath   - The fully resolved HDS path.
acFile   - The HDS file name.
piStatus - The HDS status.

Modification history:
---------------------
1998 Nov 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSWrapper::hds_trace( const char* const acLocator, int* const piNumLev,
    char* const acPath, char* const acFile, int* const piStatus ) {

  // Declare the local variables

  int iChar; // The character counter


  // Declare the FORTRAN variables

  DECLARE_CHARACTER_DYN( fLocator );
  F77_CREATE_CHARACTER( fLocator, DAT__SZLOC );
  memcpy( (void*) fLocator, (const void*) acLocator, (size_t) fLocator_length );

  DECLARE_INTEGER( fNumLev );

  DECLARE_CHARACTER_DYN( fPath );
  F77_CREATE_CHARACTER( fPath, ( NUM_CHAR_MAX + 1 ) );

  DECLARE_CHARACTER_DYN( fFile );
  F77_CREATE_CHARACTER( fFile, ( NUM_CHAR_MAX + 1 ) );

  DECLARE_INTEGER( fStatus );
  fStatus = *piStatus;


  // Call hds_trace( )

  F77_CALL(hds_trace)( CHARACTER_ARG( fLocator ), INTEGER_ARG( &fNumLev ),
      CHARACTER_ARG( fPath ), CHARACTER_ARG( fFile ), INTEGER_ARG( &fStatus )
      TRAIL_ARG( fLocator ) TRAIL_ARG( fPath ) TRAIL_ARG( fFile ) );


  // Set the return variables and free the FORTRAN memory

  for ( iChar = 0; iChar < NUM_CHAR_MAX; iChar++ ) {
    if ( isspace( fPath[iChar] ) ) {
      fPath[iChar] = '\0';
      break;
    }
  }
  
  fPath[NUM_CHAR_MAX] = '\0';
  
  memcpy( (void*) acPath, (const void*) fPath,
      strlen( (const char*) fPath ) + 1 );

  for ( iChar = 0; iChar < NUM_CHAR_MAX; iChar++ ) {
    if ( isspace( fFile[iChar] ) ) {
      fFile[iChar] = '\0';
      break;
    }
  }
  
  fFile[NUM_CHAR_MAX] = '\0';
  
  memcpy( (void*) acFile, (const void*) fFile,
      strlen( (const char*) fFile ) + 1 );
  
  *piStatus = fStatus;

  F77_FREE_CHARACTER( fLocator );
  F77_FREE_CHARACTER( fPath );
  F77_FREE_CHARACTER( fFile );


  // Return

  return;

}
