//# HDSStatus.h is part of Cuttlefish (NPOI data reduction package)
//# Copyright (C) 1999
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
//# $Id: HDSStatus.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

HDSStatus.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the HDSStatus.cc file.

Modification history:
---------------------
1998 Nov 10 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_HDSSTATUS_H
#define NPOI_HDSSTATUS_H


// Includes

#include <casa/aips.h>              // aips++
#include <casa/Exceptions/Error.h>  // aips++ Error classes
#include <casa/Utilities/Regex.h>   // aips++ Regex class
#include <casa/BasicSL/String.h>  // aips++ String class

extern "C" {
  #include <ems_par.h>              // HDS error parameters
  #include <sae_par.h>              // HDS Starlink ADAM
}

#include <npoi/HDS/GeneralStatus.h> // General status
#include <npoi/HDS/HDSWrapper.h>    // HDS FORTRAN-to-C wrappers

#include <casa/namespace.h>
// <summary>A class for maintaining the HDS status and printing messages</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// This simple class inherits GeneralStatus class and is used to maintain the
// HDS status and print HDS messages using the AipsError class.
// </synopsis>

// <example>
// <src>HDSStatus.cc</src>
// <srcblock>{}</srcblock>
// </example>

// Class definition

class HDSStatus : public GeneralStatus {

  public:

    // Standard constructor.
    HDSStatus( const uInt uiStatusIn = OK );
    
    // Copy constructor.
    HDSStatus( const HDSStatus& oStatusIn );

    // Destructor.
    ~HDSStatus( void );

    // Prints an error message corresponding to the present HDS status.
    AipsError hds_ermsg( void ) const;
    
    // Prints an error message corresponding to a given HDS status.
    static AipsError hds_ermsg( const uInt uiStatusIn );
    
    // Prints an error message and global function name corresponding to a
    // given HDS status.
    static AipsError hds_ermsg( const uInt uiStatusIn,
        const String& oGlobalFunction );

    // Prints an error message, class name, and member function name
    // corresponding to a given HDS status.
    static AipsError hds_ermsg( const uInt uiStatusIn, const String& oClass,
        const String& oMemberFunction );

    // Sets the HDS status to OK (turns HDS back on after an error occurs).
    void on( void );
    
    // Returns a pointer to the present HDS status (the address may not be
    // changed).
    uInt* const pstatus( void );
    
    // Returns the present HDS status.
    const uInt status ( void ) const;

    // OK HDS status (HDS on).
    static const uInt OK = SAI__OK;
    
    // WARNING HDS status (HDS on).
    static const uInt WARNING = SAI__WARN;
    
    // ERROR HDS status (HDS off).
    static const uInt ERROR = SAI__ERROR;

  private:

    uInt uiStatus;

};


// #endif (Include file?)

#endif // __HDSSTATUS_H
