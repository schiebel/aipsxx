//# HDSAccess.cc is part of Cuttlefish (NPOI data reduction package)
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
//# $Id: HDSAccess.cc,v 19.0 2003/07/16 06:03:05 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

HDSAccess.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the HDSAccess{ } class member functions.

Public member functions:
------------------------
HDSAccess (2 versions), ~HDSAccess, file, mode, modeList, inode, setinode,
operator=.

Static public member functions:
-------------------------------
isHDSFormat.

Inherited classes (Cuttlefish):
-------------------------------
GeneralStatus.

Modification history:
---------------------
1998 Nov 22 - Nicholas Elias, USNO/NPOI
              File created with public member functions HDSAccess( ),
	      ~HDSAccess( ), pfile( ) and pmode( ).
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member function HDSAccess( ) (copy version) added.
1999 Feb 04 - Nicholas Elias, USNO/NPOI
              Public member functions inode( ) and setinode( ) added.
1999 Feb 18 - Nicholas Elias, USNO/NPOI
              Public member functions pfile( ) and pmode( ) replaced by public
              member functions file( ) and mode( ), respectively.
1999 Sep 16 - Nicholas Elias, USNO/NPOI
              Public member functions modeList( ) and operator=( ) added.
2000 Aug 23 - Nicholas Elias, USNO/NPOI
              Static public member function isHDSFormat( ) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/HDS/HDSAccess.h> // HDS access

// -----------------------------------------------------------------------------

/*

HDSAccess::HDSAccess

Description:
------------
This public member function constructs the HDSAccess{ } object.

Inputs:
-------
oFileIn - The HDS file.
oModeIn - The HDS mode (default = "READ").

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 22 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSAccess::HDSAccess( const String& oFileIn, const String& oModeIn )
    : GeneralStatus(), uiINode( 0 ) {

  // Check the HDS file
  
  poFile = new String( oFileIn );
  
  poFile->gsub( RXwhite, "" );
  
  if ( poFile->length() < 1 ) {
    delete poFile;
    throw( ermsg( "Invalid HDS file name", "HDSAccess", "HDSAccess" ) );
  }


  // Check the HDS mode
  
  poMode = new String( oModeIn );
  
  poMode->gsub( RXwhite, "" );
  poMode->upcase();

  if ( poMode->length() < 1 || poMode->length() > SZMOD ) {
    delete poFile;
    delete poMode;
    throw( ermsg( "Invalid HDS mode", "HDSAccess", "HDSAccess" ) );
  }

  String oModeList = String( acModeList );
  
  if ( !oModeList.contains( poMode->chars() ) ) {
    throw( ermsg( "Invalid HDS mode", "HDSAccess", "HDSAccess" ) );
  }
  
  
  // Check if the HDS file can be opened in the desired HDS mode
  
  if ( poMode->matches( "NEW" ) ) {
  
    if ( access( poFile->chars(), F_OK ) == 0 ) {
      delete poFile;
      delete poMode;
      throw( ermsg( "HDS file already exists", "HDSAccess", "HDSAccess" ) );
    }
    
    uiINode = 0;
  
  } else if ( poMode->matches( "READ" ) ) {
    
    if ( access( poFile->chars(), F_OK ) != 0 ) {
      delete poFile;
      delete poMode;
      throw( ermsg( "HDS file does not exist", "HDSAccess", "HDSAccess" ) );
    }
    
    if ( access( poFile->chars(), R_OK ) != 0 ) {
      delete poFile;
      delete poMode;
      throw( ermsg( "HDS file is not readable", "HDSAccess", "HDSAccess" ) );
    }
    
    if ( !isHDSFormat( *poFile ) ) {
      delete poFile;
      delete poMode;
      throw( ermsg( "File is not in HDS format", "HDSAccess", "HDSAccess" ) );
    }
    
    try {
      setinode();
    }
    
    catch ( AipsError oAipsError ) {
      delete poFile;
      delete poMode;
      throw( ermsg( "setinode( ) error\n" + oAipsError.getMesg(), "HDSAccess",
          "HDSAccess" ) );
    }
    
  } else if ( poMode->matches( "UPDATE" ) || poMode->matches( "WRITE" ) ) {
    
    if ( access( poFile->chars(), F_OK ) != 0 ) {
      delete poFile;
      delete poMode;
      throw( ermsg( "HDS file does not exist", "HDSAccess", "HDSAccess" ) );
    }
    
    if ( access( poFile->chars(), R_OK ) != 0 ) {
      delete poFile;
      delete poMode;
      throw( ermsg( "HDS file is not readable", "HDSAccess", "HDSAccess" ) );
    }
    
    if ( access( poFile->chars(), W_OK ) != 0 ) {
      delete poFile;
      delete poMode;
      throw( ermsg( "HDS file is not writable", "HDSAccess", "HDSAccess" ) );
    }
    
    if ( !isHDSFormat( *poFile ) ) {
      delete poFile;
      delete poMode;
      throw( ermsg( "File is not in HDS format", "HDSAccess", "HDSAccess" ) );
    }
    
    try {
      setinode();
    }
    
    catch ( AipsError oAipsError ) {
      delete poFile;
      delete poMode;
      throw( ermsg( "setinode( ) error\n" + oAipsError.getMesg(), "HDSAccess",
          "HDSAccess" ) );
    }
      
  }
  
  
  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSAccess::HDSAccess (copy)

Description:
------------
This public member function copies the HDSAccess{ } object.

Inputs:
-------
oAccessIn - The HDSAccess{ } object.

Outputs:
--------
None.

Modification history:
---------------------
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSAccess::HDSAccess( const HDSAccess& oAccessIn ) : GeneralStatus() {

  // Initialize the String array private variables
  
  uiINode = oAccessIn.inode();
  
  poFile = new String( oAccessIn.file() );
  poMode = new String( oAccessIn.mode() );
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSAccess::~HDSAccess

Description:
------------
This public member function destructs the HDSAccess{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 22 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSAccess::~HDSAccess( void ) {

  // Deallocate the memory

  delete poFile;
  delete poMode;

}

// -----------------------------------------------------------------------------

/*

HDSAccess::file

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
1999 Feb 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String HDSAccess::file( void ) const {

  // Return the HDS file name

  return( String( *poFile ) );

}

// -----------------------------------------------------------------------------

/*

HDSAccess::mode

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
1999 Feb 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String HDSAccess::mode( void ) const {

  // Return the HDS access mode

  return( String( *poMode ) );

}

// -----------------------------------------------------------------------------

/*

HDSAccess::modeList

Description:
------------
This public member function returns the HDS access mode list.

Inputs:
-------
None.

Outputs:
--------
The HDS access mode list, returned via the function value.

Modification history:
---------------------
1999 Sep 16 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String HDSAccess::modeList( void ) const {

  // Return the HDS access mode list

  return( String( acModeList ) );

}

// -----------------------------------------------------------------------------

/*

HDSAccess::inode

Description:
------------
This public member returns the HDS file inode number.

Inputs:
-------
None.

Outputs:
--------
The HDS file inode number, returned via the function value.

Modification history:
---------------------
1999 Feb 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSAccess::inode( void ) const {

  // Return the HDS file inode number

  return( uiINode );
  
}

// -----------------------------------------------------------------------------

/*

HDSAccess::setinode

Description:
------------
This public member function sets the HDS file inode number (if it presently
equals 0) and returns that value.

Inputs:
-------
None.

Outputs:
--------
The HDS file inode number, returned via the function value.

Modification history:
---------------------
1999 Feb 04 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt HDSAccess::setinode( void ) {

  // Declare the local variables
  
  struct stat mtStat; // The HDS file statistics
  

  // Check if the HDS file inode number can be set

  if ( uiINode != 0 ) {
    throw( ermsg( "Cannot set the HDS file inode number", "HDSAccess",
        "setinode" ) );
  }
  

  // Set and return the HDS file inode number

  stat( (const char*) file().chars(), &mtStat );    
  uiINode = (uInt) mtStat.st_ino;

  return( uiINode );
  
}

// -----------------------------------------------------------------------------

/*

HDSAccess::operator=

Description:
------------
This public member function redfines operator=( ).

Inputs:
-------
oAccessIn - The HDSAccess{ } object.

Outputs:
--------
None.

Modification history:
---------------------
1999 Sep 16 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSAccess::operator=( const HDSAccess& oAccessIn ) {

  // Reset the private variables and return

  uiINode = oAccessIn.inode();
  
  delete poFile;
  delete poMode;
  
  poFile = new String( oAccessIn.file() );
  poMode = new String( oAccessIn.mode() );
  
  return;

}

// -----------------------------------------------------------------------------

/*

HDSAccess::isHDSFormat

Description:
------------
This static public member function determines if a file is in HDS format.

Inputs:
-------
oFileIn - The file.

Outputs:
--------
True if HDS format and False otherwise, returned via the function value.

Modification history:
---------------------
2000 Aug 23 - Nicholas Elias, USNO/NPOI
              Static public member function created.

*/

// -----------------------------------------------------------------------------

Bool HDSAccess::isHDSFormat( const String& oFileIn ) {

  // Declare the local variables

  Char acToken[4]; // The file token
  
  FILE* pmtStream; // The file stream
  

  // Determine if the file is in HDS format and return the boolean
  
  pmtStream = fopen( oFileIn.chars(), "r" );
  
  if ( pmtStream == NULL ) {
    return( False );
  }

  fgets( acToken, 4, pmtStream );
  
  fclose( pmtStream );

  if ( !strcmp( acToken, "SDS" ) ) {
    return( True );
  } else {
    return( False );
  }
    
}
