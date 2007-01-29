//#ScanInfo.h is part of the Cuttlefish server
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
//# $Id: ScanInfo.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

ScanInfo.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the ScanInfo.cc file.

Modification history:
---------------------
2000 Aug 15 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_SCANINFO_H
#define NPOI_SCANINFO_H


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

#include <npoi/HDS/GeneralStatus.h>               // GeneralStatus class

#include <npoi/GDC/GDC1Token.h>                   // GDC1Token class

#include <npoi/HDS/HDSFile.h>                     // HDSFile class

#include <casa/namespace.h>
// <summary>A class for manipulating scan information</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// ScanInfo{ } is a class designed for manipulation of scan information.
// </synopsis>

// <example>
// <src>ScanInfo.cc</src>
// <srcblock>{}</srcblock>
// </example>

// <todo asof="2000/08/11">
// <LI></LI>
// </todo>

// Class definition

class ScanInfo : public GeneralStatus, public ApplicationObject {

  public:

    // Create a ScanInfo{ } object.
    ScanInfo( void );
    ScanInfo( const String& oFileIn );
    ScanInfo( String& oFileIn, const Vector<Int>& oScanIDIn,
        const Vector<String>& oStarIDIn, const Vector<Double>& oScanTimeIn,
        const Vector<Double>& oRAIn, const Vector<Double>& oDECIn );
    ScanInfo( const ScanInfo& oScanInfoIn );
    
    // Delete an ScanInfo{ } object.
    ~ScanInfo( void );
    
    // Return the derived-from-file boolean.
    Bool derived( void ) const;
    
    // Return the file name.
    String file( void ) const;

    // Return the number of scans.
    uInt numScan( void ) const;
    uInt length( uInt& uiStartScanIn, uInt& uiStopScanIn,
          Vector<String>& oStarIDIn ) const;
    
    // Return the scans.
    Vector<Int> scan( uInt& uiStartScanIn, uInt& uiStopScanIn,
        Vector<String>& oStarIDIn ) const;
    Vector<Int> timeScan( Double& dStartTimeIn, Double& dStopTimeIn,
        Vector<String>& oStarIDIn ) const;
    
    // Return the scan IDs.
    Vector<Int> scanID( uInt& uiStartScanIn, uInt& uiStopScanIn,
        Vector<String>& oStarIDIn ) const;
    
    // Return the star IDs.
    Vector<String> starID( uInt& uiStartScanIn, uInt& uiStopScanIn,
        Vector<String>& oStarIDIn ) const;
    
    // Return the scan times.
    Vector<Double> scanTime( uInt& uiStartScanIn, uInt& uiStopScanIn,
        Vector<String>& oStarIDIn ) const;
    
    // Return the right ascensions.
    Vector<Double> RA( uInt& uiStartScanIn, uInt& uiStopScanIn,
        Vector<String>& oStarIDIn ) const;
    
    // Return the declinations.
    Vector<Double> DEC( uInt& uiStartScanIn, uInt& uiStopScanIn,
        Vector<String>& oStarIDIn ) const;
    
    // Return the total list of stars.
    Vector<String> starList( void ) const;
    
    // Return the star validity booleans.
    Vector<Bool> starValid( const Vector<String>& oStarIDIn ) const;
    
    // Dump the data to an HDS file (not the present one).
    void dumpHDS( String& oFileIn, uInt& uiStartScanIn, uInt& uiStopScanIn,
        Vector<String>& oStarIDIn ) const;
    
    // Dump the data to an ASCII file.
    void dumpASCII( const String& oFileIn, uInt& uiStartScanIn,
        uInt& uiStopScanIn, Vector<String>& oStarIDIn ) const;

    // Return the ScanInfo{ } version.
    String version( void ) const;

    // Return the glish tool name (must be "scaninfo").
    String tool( void ) const;

    // Get the selected star IDs.
    Vector<String> getStarID( void ) const;
    
    // Set the selected star IDs.
    void setStarID( Vector<String>& oStarIDIn );
    void setStarIDDefault( void );
    
    // Add the selected star IDs.
    void addStarID( Vector<String>& oStarIDIn );
    
    // Remove the selected star IDs.
    void removeStarID( Vector<String>& oStarIDIn );

    // Check/fix the start and stop scans.
    Bool checkScan( uInt& uiStartScanIn, uInt& uiStopScanIn ) const;

    // Check/fix the star IDs.
    Bool checkStarID( Vector<String>& oStarIDIn ) const;
    
    // Return the class name.
    virtual String className( void ) const;

    // Return the list of ScanInfo{ } methods.
    virtual Vector<String> methods( void ) const;

    // Return the list of ScanInfo{ } methods where no trace is printed.
    virtual Vector<String> noTraceMethods( void ) const;

    // The GDC server uses this method to pass arguments to ScanInfo{ } methods
    // and run them.
    virtual MethodResult runMethod( uInt uiMethod, ParameterSet& oParameters,
        Bool bRunMethod );

  private:
  
    uInt uiNumScan;
    
    Bool bDerived;
    
    String* poFile;
    
    GDC1Token* poScan;
    GDC1Token* poScanTime;
    GDC1Token* poRA;
    GDC1Token* poDEC;
    
    void loadHDS( const String& oFileIn, Vector<Int>& oScanIDOut,
        Vector<String>& oStarIDOut, Vector<Double>& oScanTimeOut,
        Vector<Double>& oRAOut, Vector<Double>& oDECOut );

    void initialize( const Vector<Int>& oScanIDIn,
        const Vector<String>& oStarIDIn, const Vector<Double>& oScanTimeIn,
        const Vector<Double>& oRAIn, const Vector<Double>& oDECIn );

};


// #endif (Include file?)

#endif // __SCANINFO_H
