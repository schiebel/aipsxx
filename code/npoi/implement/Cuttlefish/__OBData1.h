//#OBData1.h is part of the Cuttlefish server
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
//# $Id: __OBData1.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

__OBData1.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the __OBData1.cc file.

Modification history:
---------------------
2001 May 11 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI___OBDATA1_H
#define NPOI___OBDATA1_H


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

#include <npoi/GDC/StatToolbox.h>                 // StatToolbox class
#include <npoi/GDC/GDC1Token.h>                   // GDC1Token class

#include <npoi/Cuttlefish/OBConfig.h>             // OBConfig class
#include <npoi/Cuttlefish/ScanInfo.h>             // ScanInfo class

#include <casa/namespace.h>
// <summary>A class for manipulating 1D output-beam data</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// __OBData1{ } is a class designed for manipulation of 1D output-beam data.  It
// is a derived class that inherits GDC1Token{ }.  It is meant to be inherited
// by higher-level derived classes and not used directly by the user.
// </synopsis>

// <example>
// <src>__OBData1.cc</src>
// <srcblock>{}</srcblock>
// </example>

// <todo asof="2000/07/11">
// <LI></LI>
// </todo>


// Class definition

class __OBData1 : public GDC1Token {

  public:

    // Create a __OBData1{ } object.
    __OBData1( void );
    __OBData1( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
        Double& dXMinIn, Double& dXMaxIn, Vector<String>& oTokenIn,
        const Bool& bKeepIn, const Bool& bWeightIn, const Bool& bXCalcIn,
        String& oInterpIn );
    __OBData1( const ObjectID& oObjectIDIn, Double& dXMinIn, Double& dXMaxIn,
        Vector<String>& oTokenIn, const Bool& bKeepIn );
    __OBData1( const ObjectID& oObjectIDIn, const Vector<Double>& oXIn,
        Vector<String>& oTokenIn, const Bool& bKeepIn, String& oInterpIn,
        Double& dXMinBoxIn, Double& dXMaxBoxIn );
    __OBData1( const __OBData1& oOBData1In );
    
    // Delete a __OBData1{ } object.
    virtual ~__OBData1( void );
    
    // Return the derived-from-file boolean.
    Bool derived( void ) const;
    
    // Return the file name.
    String file( void ) const;
    
    // Return the OBConfig{ } object.
    OBConfig obConfig( void ) const;
    
    // Return the ScanInfo{ } object.
    ScanInfo scanInfo( void ) const;

    // Return the object name.
    String object( void ) const;
    
    // Return the object-error name.
    String objectErr( void ) const;
   
    // Return the data type.
    String type( void ) const;
   
    // Return the data-error type.
    String typeErr( void ) const;
    
    // Return the output-beam number.
    uInt outBeam( void ) const;
    
    // Return the number of output beams.
    uInt numOutBeam( void ) const;
    
    // Return the baseline number.
    uInt baseline( void ) const;
    
    // Return the number of baselines.
    uInt numBaseline( void ) const;
    
    // Return the present x-label token.
    String xToken( void ) const;
    
    // Return the old x-label token.
    String xTokenOld( void ) const;
  
    // Return the x-label ID.
    Int xLabelID( String& oXTokenIn ) const;
    
    // Return the x-label tokens.
    Vector<String> xLabelTokens( void ) const;
    
    // Return the x-labels.
    Vector<String> xLabels( void ) const;
    
    // Change the present x-vector and associated x-plot values.
    virtual void changeX( String& oXTokenIn );
    
    // Reset the present x-vector and associated x-plot values.
    virtual void resetX( void );
    
    // Return the class name.
    virtual String className( void ) const;

    // Return the list of __OBData1{ } methods.
    virtual Vector<String> methods( void ) const;

    // Return the list of __OBData1{ } methods where no trace is printed.
    virtual Vector<String> noTraceMethods( void ) const;

    // The Cuttlefish server uses this method to pass arguments to __OBData1{ }
    // methods and run them.
    virtual MethodResult runMethod( uInt uiMethod, ParameterSet& oParameters,
        Bool bRunMethod );

  protected:
    
    virtual void initialize( const Bool& bDerivedIn,
        const OBConfig& oOBConfigIn, const ScanInfo& oScanInfo,
        String& oObjectIn, const uInt& uiOutBeamIn, const uInt& uiBaselineIn,
        String& oXTokenIn, String& oXTokenOldIn );

    String hdsPath( void ) const;

  private:
    
    Bool bDerived;

    String* poFile;
  
    OBConfig* poOBConfig;
    ScanInfo* poScanInfo;

    String* poObject;
    String* poObjectErr;

    String* poType;
    String* poTypeErr;

    uInt uiOutBeam;
    uInt uiNumOutBeam;
    
    uInt uiBaseline;
    uInt uiNumBaseline;

    String* poXToken;
    String* poXTokenOld;
    
    uInt uiNumMethod;
    Vector<String>* poMethod;

    void initMethods( void );

};


// #endif (Include file?)

#endif // __OBDATA1_H
