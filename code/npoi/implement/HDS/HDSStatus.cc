//# HDSStatus.cc is part of Cuttlefish (NPOI data reduction package)
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
//# $Id: HDSStatus.cc,v 19.0 2003/07/16 06:03:09 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

HDSStatus.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the HDSStatus{ } class member functions.

Public member functions:
------------------------
HDSStatus (2 versions), ~HDSStatus, hds_ermsg (4 versions), on, pstatus, status.

Modification history:
---------------------
1998 Nov 10 - Nicholas Elias, USNO/NPOI
              File created with public member functions HDSStatus( ),
              ~HDSStatus( ), hds_ermsg( ) (3 versions), pstatus( ), and
              status( ).
1999 Jan 03 - Nicholas Elias, USNO/NPOI
              Public member functions hds_ermsg( ) (version 4), and on( ) added.
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member function HDSStatus( ) (copy version) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/HDS/HDSStatus.h> // HDS status

// -----------------------------------------------------------------------------

/*

HDSStatus::HDSStatus

Description:
------------
This public member function constructs the HDSStatus{ } object.

Inputs:
-------
uiStatusIn - The HDS status (default = OK).

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSStatus::HDSStatus( const uInt uiStatusIn ) : GeneralStatus() {

  // Set the present HDS status and return

  uiStatus = uiStatusIn;

  return;

}

// -----------------------------------------------------------------------------

/*

HDSStatus::HDSStatus (copy)

Description:
------------
This public member function copies the HDSStatus{ } object.

Inputs:
-------
oStatusIn - The HDSStatus{ } object.

Outputs:
--------
None.

Modification history:
---------------------
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSStatus::HDSStatus( const HDSStatus& oStatusIn ) : GeneralStatus() {

  // Set the present HDS status and return

  uiStatus = oStatusIn.status();

  return;

}

// -----------------------------------------------------------------------------

/*

HDSStatus::~HDSStatus

Description:
------------
This public member function destructs the HDSStatus{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSStatus::~HDSStatus( void ) {}

// -----------------------------------------------------------------------------

/*

HDSStatus::hds_ermsg (void)

Description:
------------
This public member function prints an error message (using the AipsError( )
class) corresponding to the present HDS status.

Inputs:
-------
None.

Outputs:
--------
The error message, returned via the function value.

Modification history:
---------------------
1999 Jan 03 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

AipsError HDSStatus::hds_ermsg( void ) const {

  // Declare the local variables

  uInt uiLength;                  // The error message length

  Char acMessage[EMS__SZMSG + 1]; // The error message


  // Get/print the error message and return

  HDSWrapper::dat_ermsg( (const int) uiStatus, (int* const) &uiLength,
      (char* const) acMessage );

  return( msg( acMessage, SEVERE ) );
  
}

// -----------------------------------------------------------------------------

/*

HDSStatus::hds_ermsg (HDS status)

Description:
------------
This public member function prints an error message (using the AipsError( )
class) corresponding to an HDS status.

Inputs:
-------
uiStatusIn - The HDS status.

Outputs:
--------
The error message, returned via the function value.

Modification history:
---------------------
1998 Nov 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

AipsError HDSStatus::hds_ermsg( const uInt uiStatusIn ) {

  // Declare the local variables

  uInt uiLength;                  // The error message length

  Char acMessage[EMS__SZMSG + 1]; // The error message


  // Get/print the error message and return

  HDSWrapper::dat_ermsg( (const int) uiStatusIn, (int* const) &uiLength,
      (char* const) acMessage );
  
  return( msg( acMessage, SEVERE ) );

}

// -----------------------------------------------------------------------------

/*

HDSStatus::hds_ermsg (HDS status + global function name)

Description:
------------
This public member function prints an error message (using the AipsError( )
class) corresponding to an HDS status.

Inputs:
-------
uiStatusIn      - The HDS status.
oGlobalFunction - The global function name.

Outputs:
--------
The error message, returned via the function value.

Modification history:
---------------------
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

AipsError HDSStatus::hds_ermsg( const uInt uiStatusIn,
    const String& oGlobalFunction ) {

  // Declare the local variables

  uInt uiLength;                  // The error message length

  Char acMessage[EMS__SZMSG + 1]; // The error message
  
  
  // Check the inputs
  
  if ( oGlobalFunction.length() < 1 ) {
    throw( msg( "Invalid global function name", "HDSStatus", "hds_ermsg",
        WARN ) );
  }


  // Get/print the error message and return

  HDSWrapper::dat_ermsg( (const int) uiStatusIn, (int* const) &uiLength,
      (char* const) acMessage );
  
  return( msg( acMessage, oGlobalFunction, SEVERE ) );

}

// -----------------------------------------------------------------------------

/*

HDSStatus::hds_ermsg (HDS status + class name + member function name)

Description:
------------
This public member function prints an error message (using the AipsError( )
class) corresponding to an HDS status.

Inputs:
-------
uiStatusIn      - The HDS status.
oClass          - The class name.
oMemberFunction - The member function name.

Outputs:
--------
The error message, returned via the function value.

Modification history:
---------------------
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

AipsError HDSStatus::hds_ermsg( const uInt uiStatusIn, const String& oClass,
    const String& oMemberFunction ) {

  // Declare the local variables

  uInt uiLength;                  // The error message length

  Char acMessage[EMS__SZMSG + 1]; // The error message

  
  // Check the inputs
  
  if ( oClass.length() < 1 ) {
    throw( msg( "Invalid class name", "HDSStatus", "hds_ermsg", WARN ) );
  }
  
  if ( oMemberFunction.length() < 1 ) {
    throw( msg( "Invalid member function name", "HDSStatus", "hds_ermsg",
        WARN ) );
  }


  // Get/print the error message and return

  HDSWrapper::dat_ermsg( (const int) uiStatusIn, (int* const) &uiLength,
      (char* const) acMessage );
  
  return( msg( acMessage, oClass, oMemberFunction, SEVERE ) );

}

// -----------------------------------------------------------------------------

/*

HDSStatus::on

Description:
------------
This public member function sets the HDS status to OK.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1999 Jan 03 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSStatus::on( void ) {

  // Set the HDS status to OK and return
  
  uiStatus = OK;
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSStatus::pstatus

Description:
------------
This public member function returns the HDS status pointer.

Inputs:
-------
None.

Outputs:
--------
The HDS status pointer, returned via the function value.

Modification history:
---------------------
1998 Nov 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt* const HDSStatus::pstatus( void ) {

  // Return the HDS status pointer

  return( &uiStatus );

}

// -----------------------------------------------------------------------------

/*

HDSStatus::status

Description:
------------
This public member function returns the present HDS status.

Inputs:
-------
None.

Outputs:
--------
The present HDS status, returned via the function value.

Modification history:
---------------------
1998 Nov 10 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

const uInt HDSStatus::status( void ) const {

  // Return the present HDS status

  return( uiStatus );

}
