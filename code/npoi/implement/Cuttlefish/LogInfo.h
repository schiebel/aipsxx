//#LogInfo.h is part of the Cuttlefish server
//#Copyright (C) 2000,2001
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
//#Correspondence concerning the Cuttlefish server should be addressed as follows:
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
//# $Id: LogInfo.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

LogInfo.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the LogInfo.cc file.

Modification history:
---------------------
2001 Jan 29 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_LOGINFO_H
#define NPOI_LOGINFO_H


// Includes

extern "C" {
  #include <unistd.h>                             // Universal standard
}

#include <fstream.h>                              // File I/O stream

#include <casa/aips.h>                            // aips++
#include <tasking/Tasking/ApplicationObject.h>      // aips++ App...Object class
#include <casa/Exceptions/Error.h>                // aips++ Error classes
#include <casa/Arrays/IPosition.h>                // aips++ IPosition class
#include <tasking/Tasking/MethodResult.h>           // aips++ MethodResult class
#include <tasking/Tasking/Parameter.h>              // aips++ Parameter class
#include <tasking/Tasking/ParameterSet.h>           // aips++ ParameterSet class
#include <casa/Utilities/Regex.h>                 // aips++ Regex class
#include <casa/BasicSL/String.h>                // aips++ String class
#include <tasking/Tasking.h>                        // aips++ tasking
#include <casa/Arrays/Vector.h>                   // aips++ Vector class

#include <npoi/HDS/GeneralStatus.h>               // GeneralStatus

#include <npoi/HDS/HDSFile.h>                     // HDSFile class

#include <casa/namespace.h>
// <summary>A class for manipulating log information</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// LogInfo{ } is a class designed for manipulation of log information.
// </synopsis>

// <example>
// <src>LogInfo.cc</src>
// <srcblock>{}</srcblock>
// </example>

// <todo asof="2000/08/11">
// <LI></LI>
// </todo>

// Class definition

class LogInfo : public GeneralStatus, public ApplicationObject {

  public:

    // Create an LogInfo{ } object.
    LogInfo( void );
    LogInfo( const String& oFileIn, const String& oNameIn,
        const Bool& bReadOnlyIn = True );
    LogInfo( const LogInfo& oLogInfoIn );
    
    // Delete an LogInfo{ } object.
    ~LogInfo( void );
    
    // Return the file name.
    String file( void ) const;
    
    // Return the log name.
    String name( void ) const;
    
    // Return the read-only flag.
    Bool readOnly( void ) const;
    
    // Return the log.
    String log( void ) const;
    
    // Append the log.
    void append( const String& oLine );
    
    // Dump the data to an ASCII file.
    void dumpASCII( const String& oFileIn ) const;
    
    // Dump the data to an HDS file.
    void dumpHDS( const String& oFileIn = "" ) const;

    // Return the LogInfo{ } version.
    String version( void ) const;

    // Return the glish tool name (must be "loginfo").
    String tool( void ) const;
    
    // Return the class name.
    virtual String className( void ) const;

    // Return the list of LogInfo{ } methods.
    virtual Vector<String> methods( void ) const;

    // Return the list of LogInfo{ } methods where no trace is printed.
    virtual Vector<String> noTraceMethods( void ) const;

    // The GDC server uses this method to pass arguments to LogInfo{ } methods
    // and run them.
    virtual MethodResult runMethod( uInt uiMethod, ParameterSet& oParameters,
        Bool bRunMethod );

  private:
    
    Bool bReadOnly;
    
    String* poFile;
    String* poLog;
    String* poName;
    
    void loadHDS( const String& oFileIn, const String& oNameIn,
        const Bool& bReadOnlyIn );

};


// #endif (Include file?)

#endif // __LOGINFO_H
