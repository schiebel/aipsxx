//# GeneralStatus.cc is part of Cuttlefish (NPOI data reduction package)
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
//# $Id: GeneralStatus.cc,v 19.0 2003/07/16 06:03:04 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

GeneralStatus.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the GeneralStatus{ } class member functions.

Public member functions:
------------------------
GeneralStatus, ~GeneralStatus, ermsg (3 versions), msg (3 versions).

Modification history:
---------------------
1999 Jan 25 - Nicholas Elias, USNO/NPOI
              File created with public member functions GeneralStatus( ),
              ~GeneralStatus( ), ermsg( ) (3 versions), and msg( ) (3 versions).

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/HDS/GeneralStatus.h> // General status

// -----------------------------------------------------------------------------

/*

GeneralStatus::GeneralStatus

Description:
------------
This public member function constructs the object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1999 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GeneralStatus::GeneralStatus( void ) {}

// -----------------------------------------------------------------------------

/*

GeneralStatus::~GeneralStatus

Description:
------------
This public member function destructs the object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1999 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

GeneralStatus::~GeneralStatus( void ) {}

// -----------------------------------------------------------------------------

/*

GeneralStatus::ermsg (message)

Description:
------------
This public member function prints an error message (using the AipsError( )
class).

Inputs:
-------
oMessage - The error message.

Outputs:
--------
The error message, returned via the function value.

Modification history:
---------------------
1999 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

AipsError GeneralStatus::ermsg( const String& oMessage ) {

  // Check the inputs
  
  if ( oMessage.length() < 1 ) {
    throw( msg( "Invalid message", "GeneralStatus", "ermsg", WARN ) );
  }
  

  // Print the error message and return
  
  return( msg( oMessage, SEVERE ) );

}

// -----------------------------------------------------------------------------

/*

GeneralStatus::ermsg (message + global function name)

Description:
------------
This public member function prints an error message (using the AipsError( )
class).

Inputs:
-------
oMessage        - The error message.
oGlobalFunction - The global function name.

Outputs:
--------
The error message, returned via the function value.

Modification history:
---------------------
1999 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

AipsError GeneralStatus::ermsg( const String& oMessage,
    const String& oGlobalFunction ) {

  // Check the inputs
  
  if ( oMessage.length() < 1 ) {
    throw( msg( "Invalid message", "GeneralStatus", "ermsg", WARN ) );
  }
  
  if ( oGlobalFunction.length() < 1 ) {
    throw( msg( "Invalid global function name", "GeneralStatus", "ermsg",
        WARN ) );
  }
  

  // Print the error message and return
  
  return( msg( oMessage, oGlobalFunction, SEVERE ) );

}

// -----------------------------------------------------------------------------

/*

GeneralStatus::ermsg (message + class name + member function name)

Description:
------------
This public member function prints an error message (using the AipsError( )
class).

Inputs:
-------
oMessage        - The error message.
oClass          - The class name.
oMemberFunction - The member function name.

Outputs:
--------
The error message, returned via the function value.

Modification history:
---------------------
1999 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

AipsError GeneralStatus::ermsg( const String& oMessage, const String& oClass,
    const String& oMemberFunction ) {  

  // Check the inputs
  
  if ( oMessage.length() < 1 ) {
    throw( msg( "Invalid message", "GeneralStatus", "ermsg", WARN ) );
  }
  
  if ( oClass.length() < 1 ) {
    throw( msg( "Invalid class name", "GeneralStatus", "ermsg", WARN ) );
  }
  
  if ( oMemberFunction.length() < 1 ) {
    throw( msg( "Invalid member function name", "GeneralStatus", "ermsg",
        WARN ) );
  }
  

  // Print the error message and return
  
  return( msg( oMessage, oClass, oMemberFunction, SEVERE ) );

}

// -----------------------------------------------------------------------------

/*

GeneralStatus::msg (message)

Description:
------------
This public member function prints a message (using the AipsError( ) class).

Inputs:
-------
oMessage - The message.
eLevel   - The level (default = NORMAL).

Outputs:
--------
The message, returned via the function value.

Modification history:
---------------------
1999 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

AipsError GeneralStatus::msg( const String& oMessage, const Level eLevel ) {

  // Check the inputs
  
  if ( oMessage.length() < 1 ) {
    throw( msg( "Invalid message", "GeneralStatus", "msg", WARN ) );
  }
  

  // Print the message and return

  if ( eLevel == NORMAL ) {
    return( AipsError( "\n " + oMessage ) );
  } else if ( eLevel == WARN ) {
    return( AipsError( "\n% " + oMessage ) );
  } else { // eLevel == SEVERE
    return( AipsError( "\n%% " + oMessage ) );
  }

}

// -----------------------------------------------------------------------------

/*

GeneralStatus::msg (message + global function name)

Description:
------------
This public member function prints a message (using the AipsError( ) class).

Inputs:
-------
oMessage        - The message.
oGlobalFunction - The global function name.
eLevel          - The level (default = NORMAL).

Outputs:
--------
The message, returned via the function value.

Modification history:
---------------------
1999 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

AipsError GeneralStatus::msg( const String& oMessage,
    const String& oGlobalFunction, const Level eLevel ) {

  // Check the inputs
  
  if ( oMessage.length() < 1 ) {
    throw( msg( "Invalid message", "GeneralStatus", "msg", WARN ) );
  }
  
  if ( oGlobalFunction.length() < 1 ) {
    throw( msg( "Invalid global function name", "GeneralStatus", "msg",
        WARN ) );
  }
  

  // Print the message and return
  
  LogOrigin oLogOrigin = LogOrigin( oGlobalFunction );

  if ( eLevel == NORMAL ) {
    return( AipsError( "\n " + oLogOrigin.toString() + ": " + oMessage ) );
  } else if ( eLevel == WARN ) {
    return( AipsError( "\n% " + oLogOrigin.toString() + ": " + oMessage ) );
  } else { // eLevel == SEVERE
    return( AipsError( "\n%% " + oLogOrigin.toString() + ": " + oMessage ) );
  }

}

// -----------------------------------------------------------------------------

/*

GeneralStatus::msg (message + class name + member function name)

Description:
------------
This public member function prints a message (using the AipsError( ) class).

Inputs:
-------
oMessage        - The message.
oClass          - The class name.
oMemberFunction - The member function name.
eLevel          - The level (default = NORMAL).

Outputs:
--------
The message, returned via the function value.

Modification history:
---------------------
1999 Jan 25 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

AipsError GeneralStatus::msg( const String& oMessage, const String& oClass,
    const String& oMemberFunction, const Level eLevel ) {

  // Check the inputs
  
  if ( oMessage.length() < 1 ) {
    throw( msg( "Invalid message", "GeneralStatus", "msg", WARN ) );
  }
  
  if ( oClass.length() < 1 ) {
    throw( msg( "Invalid class name", "GeneralStatus", "msg", WARN ) );
  }
  
  if ( oMemberFunction.length() < 1 ) {
    throw( msg( "Invalid member function name", "GeneralStatus", "msg",
        WARN ) );
  }
  

  // Print the message and return
  
  LogOrigin oLogOrigin = LogOrigin( oClass, oMemberFunction );

  if ( eLevel == NORMAL ) {
    return( AipsError( "\n " + oLogOrigin.toString() + ": " + oMessage ) );
  } else if ( eLevel == WARN ) {
    return( AipsError( "\n% " + oLogOrigin.toString() + ": " + oMessage ) );
  } else { // eLevel == SEVERE
    return( AipsError( "\n%% " + oLogOrigin.toString() + ": " + oMessage ) );
  }

}
