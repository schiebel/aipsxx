//#IBConfig.h is part of the Cuttlefish server
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
//# $Id: IBConfig.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

IBConfig.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the IBConfig.cc file.

Modification history:
---------------------
2000 Aug 11 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_IBCONFIG_H
#define NPOI_IBCONFIG_H


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
// <summary>A class for manipulating input-beam configurations</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// IBConfig{ } is a class designed for manipulation of input-beam
// (telescope-based) configurations.
// </synopsis>

// <example>
// <src>IBConfig.cc</src>
// <srcblock>{}</srcblock>
// </example>

// <todo asof="2000/08/11">
// <LI></LI>
// </todo>

// Class definition

class IBConfig : public GeneralStatus, public ApplicationObject {

  public:

    // Create an IBConfig{ } object.
    IBConfig( void );
    IBConfig( const String& oFileIn );
    IBConfig( const IBConfig& oIBConfigIn );
    
    // Delete an IBConfig{ } object.
    ~IBConfig( void );
    
    // Return the file name.
    String file( void ) const;

    // Return the number of input beams.
    uInt numInputBeam( void ) const;
    uInt numSiderostat( void ) const; // Backwards compatibility
    
    // Return the beam-combiner input ID.
    uInt bcInputID( const uInt& uiInputBeamIn ) const;
    
    // Return the delay-line ID.
    uInt delayLineID( const uInt& uiInputBeamIn ) const;
    
    // Return the input-beam ID.
    uInt inputBeamID( const uInt& uiInputBeamIn ) const;
    uInt siderostatID( const uInt& uiSidIn ) const; // Backwards compatibility
    
    // Return the star-tracker ID.
    uInt starTrackerID( const uInt& uiInputBeamIn ) const;
    
    // Return the station ID.
    String stationID( const uInt& uiInputBeamIn ) const;
    
    // Return the station coordinates.
    Vector<Double> stationCoord( const uInt& uiInputBeamIn ) const;
    
    // Dump the data to an HDS file.
    void dumpHDS( const String& oFileIn = "" ) const;

    // Return the IBConfig{ } version.
    String version( void ) const;

    // Return the glish tool name (must be "ibconfig").
    String tool( void ) const;

    // Return the input-beam tool ID.
    Int ibToolID( String& oIBToolIn ) const;

    // Return the input-beam tool names.
    Vector<String> ibTools( void ) const;

    // Return the input-beam HDS object names.
    Vector<String> ibObjects( void ) const;

    // Return the input-beam HDS object-error names.
    Vector<String> ibObjectErrs( void ) const;

    // Return the input-beam HDS object types.
    Vector<String> ibTypes( void ) const;

    // Return the input-beam HDS object-error types.
    Vector<String> ibTypeErrs( void ) const;
    
    // Return the input-beam y-axis label defaults.
    Vector<String> ibYLabelDefaults( void ) const;
    
    // Return the class name.
    virtual String className( void ) const;

    // Return the list of IBConfig{ } methods.
    virtual Vector<String> methods( void ) const;

    // Return the list of IBConfig{ } methods where no trace is printed.
    virtual Vector<String> noTraceMethods( void ) const;

    // The GDC server uses this method to pass arguments to IBConfig{ } methods
    // and run them.
    virtual MethodResult runMethod( uInt uiMethod, ParameterSet& oParameters,
        Bool bRunMethod );

  private:
  
    uInt uiNumInputBeam;
    uInt uiNumSiderostat;
    
    String* poFile;
    
    Vector<Int>* poBCInputID;
    Vector<Int>* poDelayLineID;
    Vector<Int>* poInputBeamID;
    Vector<Int>* poSiderostatID;
    Vector<Int>* poStarTrackerID;
    
    Vector<String>* poStationID;
    
    Vector<Double>** aoStationCoord;
    
    Bool checkInputBeam( const uInt& uiInputBeamIn ) const;
    
    void loadHDS( const String& oFileIn );

};


// #endif (Include file?)

#endif // __IBCONFIG_H
