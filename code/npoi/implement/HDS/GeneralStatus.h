//# GeneralStatus.h is part of Cuttlefish (NPOI data reduction package)
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
//# $Id: GeneralStatus.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

GeneralStatus.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the include information for the GeneralStatus.cc file.

Modification history:
---------------------
1999 Jan 25 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_GENERALSTATUS_H
#define NPOI_GENERALSTATUS_H


// Includes

#include <casa/aips.h>             // aips++
#include <casa/Exceptions/Error.h> // aips++ Error classes
#include <casa/Logging/LogIO.h>    // aips++ LogIO class
#include <casa/Utilities/Regex.h>  // aips++ Regex class
#include <casa/BasicSL/String.h> // aips++ String class

#include <casa/namespace.h>
// <summary>A class for printing messages</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// This simple class is used to print messages using the AipsError class.
// </synopsis>

// <example>
// <src>GeneralStatus.cc</src>
// <srcblock>{}</srcblock>
// </example>

// Class definition

class GeneralStatus {

  public:

    // Constructor.
    GeneralStatus( void );

    // Destructor.
    ~GeneralStatus( void );

    // Prints a generic error message.
    static AipsError ermsg( const String& oMessage );
    
    // Prints an error message along with the global function name.
    static AipsError ermsg( const String& oMessage,
        const String& oGlobalFunction );
    
    // Prints an error message along with the class and member function names.
    static AipsError ermsg( const String& oMessage, const String& oClass,
        const String& oMemberFunction );

    // Message level
    typedef enum Level {
      NORMAL = 0,
      WARN = 1,
      SEVERE = 2
    } Level;
    
    // Prints a generic message.
    static AipsError msg( const String& oMessage, const Level eLevel = NORMAL );
    
    // Prints a message along with the global function name.
    static AipsError msg( const String& oMessage, const String& oGlobalFunction,
        const Level eLevel = NORMAL );
	
    // Prints a message along with the class and member function names.
    static AipsError msg( const String& oMessage, const String& oClass,
        const String& oMemberFunction, const Level eLevel = NORMAL );

};


// #endif (Include file?)

#endif // __GENERALSTATUS_H
