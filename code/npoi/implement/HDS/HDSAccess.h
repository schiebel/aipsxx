//# HDSAccess.h is part of Cuttlefish (NPOI data reduction package)
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
//# $Id: HDSAccess.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

HDSAccess.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the include information for the HDSAccess.cc file.

Modification history:
---------------------
1998 Nov 22 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_HDSACCESS_H
#define NPOI_HDSACCESS_H


// Includes

extern "C" {
  #include <stdio.h>                // Standard I/O
  #include <sys/stat.h>             // File statistics
  #include <unistd.h>               // Universal standard
}

#include <casa/aips.h>              // aips++
#include <casa/Exceptions/Error.h>  // aips++ Error classes
#include <casa/Utilities/Regex.h>   // aips++ Regex class
#include <casa/BasicSL/String.h>  // aips++ String class

extern "C" {
  #include <dat_par.h>              // HDS data parameters
}

#include <npoi/HDS/GeneralStatus.h> // General status

#include <casa/namespace.h>
// <summary>A class for checking the HDS file and mode</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// This class fixes the HDS file name (removes embedded spaces) and fixes the
// HDS mode name (removes embedded spaces and capitalizes). It checks to see if
// the HDS mode name is in the allowed list ("NEW", "READ", "UPDATE", and
// "WRITE").  For a given HDS mode, it checks the HDS file:
// <UL>
// <LI><B>NEW</B>    - Makes sure the file doesn't already exist</LI>
// <LI><B>READ</B>   - Makes sure the file exists and is readable.</LI>
// <LI><B>UPDATE</B> - Makes sure the file exists and is readable/writable.</LI>
// <LI><B>WRITE</B>  - Makes sure the file exists and is readable/writable.</LI>
// </UL>
// In addition, the inode is set so that the file may be locked by HDSFile
// after it is opened.
// </synopsis>

// <example>
// <src>HDSAccess.cc</src>
// <srcblock>{}</srcblock>
// </example>


// Class definition

class HDSAccess : public GeneralStatus {

  public:
  
    // Standard constructor.
    HDSAccess( const String& oFileIn, const String& oModeIn = "READ" );
    
    // Copy constructor.
    HDSAccess( const HDSAccess& oAccessIn );
    
    // Destructor.
    ~HDSAccess( void );

    // Return the HDS file name.
    String file( void ) const;
    
    // Return the HDS mode.
    String mode( void ) const;
    
    // Return the HDS mode list.
    String modeList( void ) const;
    
    // Return the inode.
    uInt inode( void ) const;
    
    // Set the inode.
    uInt setinode( void );

    // The overloaded = operator.
    void operator=( const HDSAccess& oAccessIn );
    
    // Determine if a file is in HDS format.
    static Bool isHDSFormat( const String& oFileIn );

    // The maximum length of the mode name (15)
    static const uInt SZMOD = DAT__SZMOD;

    // The mode list string
    static const Char* const acModeList = "NEW READ UPDATE WRITE";
  
  private:
  
    uInt uiINode;

    String* poFile;
    String* poMode;

};


// #endif (Include file?)

#endif // __HDSACCESS_H
