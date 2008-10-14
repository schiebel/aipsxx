//#SysConfig.h is part of the Cuttlefish server
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
//# $Id: SysConfig.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

SysConfig.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the SysConfig.cc file.

Modification history:
---------------------
2001 Jan 26 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_SYSCONFIG_H
#define NPOI_SYSCONFIG_H


// Includes

extern "C" {
  #include <unistd.h>                             // Universal standard
}

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
// <summary>A class for manipulating geodetic parameters</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// SysConfig{ } is a class designed for manipulation of system configurations.
// </synopsis>

// <example>
// <src>SysConfig.cc</src>
// <srcblock>{}</srcblock>
// </example>

// <todo asof="2000/08/11">
// <LI></LI>
// </todo>

// Class definition

class SysConfig : public GeneralStatus, public ApplicationObject {

  public:

    // Create an SysConfig{ } object.
    SysConfig( void );
    SysConfig( const String& oFileIn );
    SysConfig( const SysConfig& oSysConfigIn );
    
    // Delete an SysConfig{ } object.
    ~SysConfig( void );
    
    // Return the file name.
    String file( void ) const;
    
    // Return the beam-combiner ID.
    uInt beamCombinerID( void ) const;
    
    // Return the date.
    String date( void ) const;
    
    // Return the format.
    String format( void ) const;
    
    // Return the instrument coherent integration.
    Double instrCohInt( void ) const;
    
    // Return the reference station.
    uInt refStation( void ) const;
    
    // Return the system ID.
    String systemID( void ) const;
    
    // Return the user ID.
    String userID( void ) const;
    
    // Dump the data to an HDS file.
    void dumpHDS( const String& oFileIn = "" ) const;

    // Return the SysConfig{ } version.
    String version( void ) const;

    // Return the glish tool name (must be "sysconfig").
    String tool( void ) const;
    
    // Return the class name.
    virtual String className( void ) const;

    // Return the list of SysConfig{ } methods.
    virtual Vector<String> methods( void ) const;

    // Return the list of SysConfig{ } methods where no trace is printed.
    virtual Vector<String> noTraceMethods( void ) const;

    // The GDC server uses this method to pass arguments to SysConfig{ } methods
    // and run them.
    virtual MethodResult runMethod( uInt uiMethod, ParameterSet& oParameters,
        Bool bRunMethod );

  private:
  
    uInt uiBeamCombinerID;
    uInt uiRefStation;
    
    Double dInstrCohInt;
    
    String* poDate;
    String* poFormat;
    String* poSystemID;
    String* poUserID;
    
    String* poFile;
    
    void loadHDS( const String& oFileIn );

};


// #endif (Include file?)

#endif // __SYSCONFIG_H
