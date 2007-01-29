//#WetDelay.h is part of the Cuttlefish server
//#Copyright (C) 2001
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
//# $Id: WetDelay.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

WetDelay.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the WetDelay.cc file.

Modification history:
---------------------
2001 May 10 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_WETDELAY_H
#define NPOI_WETDELAY_H


// Includes

#include <casa/aips.h>                            // aips++
#include <tasking/Tasking/ApplicationEnvironment.h> // aips++ App...Env... class
#include <tasking/Tasking/ApplicationObject.h>      // aips++ App...Object class
#include <casa/Arrays/Array.h>                    // aips++ Array class
#include <casa/Exceptions/Error.h>                // aips++ Error classes
#include <tasking/Tasking/MethodResult.h>           // aips++ MethodResult class
#include <tasking/Tasking/Parameter.h>              // aips++ Parameter class
#include <tasking/Tasking/ParameterSet.h>           // aips++ ParameterSet class
#include <casa/Utilities/Regex.h>                 // aips++ Regex class
#include <casa/BasicSL/String.h>                // aips++ String class
#include <tasking/Tasking.h>                        // aips++ tasking
#include <casa/Arrays/Vector.h>                   // aips++ Vector class

#include <npoi/HDS/GeneralStatus.h>               // GeneralStatus

#include <npoi/GDC/GDC1Token.h>                   // GDC1Token class

#include <npoi/HDS/HDSFile.h>                     // HDSFile class

#include <npoi/Cuttlefish/IBConfig.h>             // IBConfig class
#include <npoi/Cuttlefish/OBConfig.h>             // OBConfig class

#include <npoi/Cuttlefish/__IBData1.h>            // __IBData1 class

#include <casa/namespace.h>
// <summary>A class for manipulating delays</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// WetDelay{ } is a class designed for manipulation of wet delays.  Wet delays
// are 1-dimensional/tokenized and telescoped-based, so WetDelay{ } inherits
// __IBData1 and uses the initialize( ).  It is meant to be inherited by
// higher-level derived classes and not used directly by the user.
// </synopsis>

// <example>
// <src>WetDelay.cc</src>
// <srcblock>{}</srcblock>
// </example>

// <todo asof="2000/07/11">
// <LI></LI>
// </todo>


// Class definition

class WetDelay : public __IBData1 {

  public:

    // Create a WetDelay{ } object.
    WetDelay( String& oFileIn, const uInt& uiInputBeamIn );
    WetDelay( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
        Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        const Bool& bKeepIn, const Bool& bWeightIn, const Bool& bXCalcIn,
        String& oInterpIn );
    WetDelay( const ObjectID& oObjectIDIn, Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, const Bool& bKeepIn );
    WetDelay( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
        Vector<String>& oTokenIn, const Bool& bKeepIn, String& oInterpIn,
        Double& dXMinBoxIn, Double& dXMaxBoxIn );
    WetDelay( const WetDelay& oWetDelayIn );
    
    // Delete a WetDelay{ } object.
    ~WetDelay( void );
    
    // Dump the data to an HDS file (not the one).
    void dumpHDS( String& oFileIn, Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn ) const;
    
    // Save the data to the present HDS file.
    void saveHDS( void ) const;
    
    // Return the WetDelay{ } version.
    String version( void ) const;

    // Return the glish base-tool name.
    String baseTool( void ) const;

    // Return the glish tool name.
    String tool( void ) const;
    
    // Return the class name.
    virtual String className( void ) const;

    // Return the list of WetDelay{ } methods.
    virtual Vector<String> methods( void ) const;

    // Return the list of WetDelay{ } methods where no trace is printed.
    virtual Vector<String> noTraceMethods( void ) const;

    // The Cuttlefish server uses this method to pass arguments to WetDelay{ }
    // methods and run them.
    virtual MethodResult runMethod( uInt uiMethod, ParameterSet& oParameters,
        Bool bRunMethod );

  protected:
    
    virtual void initialize( void );

  private:
  
    uInt uiNumMethod;
    Vector<String>* poMethod;
    
    void loadHDS( String& oFileIn, const uInt& uiInputBeamIn,
        Vector<Double>& oXOut, Vector<Double>& oYOut, Vector<Double>& oXErrOut,
        Vector<Double>& oYErrOut, Vector<String>& oTokenOut,
        Vector<Bool>& oFlagOut );

    void initMethods( void );

};


// #endif (Include file?)

#endif // __WETDELAY_H
