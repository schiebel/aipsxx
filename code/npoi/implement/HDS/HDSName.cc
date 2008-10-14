//# HDSName.cc is part of Cuttlefish (NPOI data reduction package)
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
//# $Id: HDSName.cc,v 19.0 2003/07/16 06:03:08 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

HDSName.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the HDSName{ } class member functions.

Public member functions:
------------------------
HDSName, ~HDSName.

Inherited classes (aips++):
---------------------------
String.

Inherited classes (Cuttlefish):
-------------------------------
GeneralStatus.

Modification history:
---------------------
1998 Nov 20 - Nicholas Elias, USNO/NPOI
              File created with public member functions HDSName( ) and
              ~HDSName( ).

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/HDS/HDSName.h> // HDS name

// -----------------------------------------------------------------------------

/*

HDSName::HDSName

Description:
------------
This public member function constructs the HDSName{ } object.

Inputs:
-------
oNameIn - The HDS object name.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSName::HDSName( const String& oNameIn ) : GeneralStatus(), String( oNameIn ) {

  // Fix and check the inputs

  this->gsub( RXwhite, "" );
  this->upcase();

  if ( this->length() < 1 || this->length() > SZNAM ) {
    throw( ermsg( "Invalid HDS object name", "HDSName", "HDSName" ) );
  }


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSName::~HDSName

Description:
------------
This public member function destructs the HDSName{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSName::~HDSName( void ) {}

