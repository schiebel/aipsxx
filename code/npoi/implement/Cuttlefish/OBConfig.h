//#OBConfig.h is part of the Cuttlefish server
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
//# $Id: OBConfig.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

OBConfig.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the include information for the OBConfig.cc file.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_OBCONFIG_H
#define NPOI_OBCONFIG_H


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
// <summary>A class for manipulating output-beam configurations</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// OBConfig{ } is a class designed for manipulation of output-beam
// (telescope-based) configurations.
// </synopsis>

// <example>
// <src>OBConfig.cc</src>
// <srcblock>{}</srcblock>
// </example>

// <todo asof="2000/08/11">
// <LI></LI>
// </todo>

// Class definition

class OBConfig : public GeneralStatus, public ApplicationObject {

  public:

    // Create an OBConfig{ } object.
    OBConfig( void );
    OBConfig( String& oFileIn );
    OBConfig( const OBConfig& oOBConfigIn );
    
    // Delete an OBConfig{ } object.
    ~OBConfig( void );
    
    // Return the file name.
    String file( void ) const;
    
    // Return the number of output beams.
    uInt numOutBeam( void ) const;
    
    // Return the number of baselines.
    uInt numBaseline( const uInt& uiOutBeamIn ) const;

    // Return the number of spectral channels.
    uInt numSpecChan( const uInt& uiOutBeamIn ) const;
    
    // Return the spectrometer ID.
    String spectrometerID( const uInt& uiOutBeamIn ) const;
    
    // Return the baseline IDs.
    Vector<String> baselineID( const uInt& uiOutBeamIn ) const;
    
    // Return the wavelengths.
    Vector<Double> wavelength( const uInt& uiOutBeamIn ) const;
    
    // Return the wavelength errors.
    Vector<Double> wavelengthErr( const uInt& uiOutBeamIn ) const;
    
    // Return the channel widths.
    Vector<Double> chanWidth( const uInt& uiOutBeamIn ) const;
    
    // Return the channel width errors.
    Vector<Double> chanWidthErr( const uInt& uiOutBeamIn ) const;
    
    // Return the fringe modulations.
    Vector<Int> fringeMod( const uInt& uiOutBeamIn ) const;
    
    // Dump the data to an HDS file.
    void dumpHDS( String& oFileIn ) const;

    // Return the OBConfig{ } version.
    String version( void ) const;

    // Return the glish tool name (must be "obconfig").
    String tool( void ) const;

    // Return the output-beam tool ID.
    Int obToolID( String& oOBToolIn ) const;

    // Return the output-beam tool names.
    Vector<String> obTools( void ) const;

    // Return the output-beam HDS object names.
    Vector<String> obObjects( void ) const;

    // Return the output-beam HDS object-error names.
    Vector<String> obObjectErrs( void ) const;

    // Return the output-beam HDS object types.
    Vector<String> obTypes( void ) const;

    // Return the output-beam HDS object-error types.
    Vector<String> obTypeErrs( void ) const;
    
    // Return the output-beam y-axis label defaults.
    Vector<String> obYLabelDefaults( void ) const;

    // Check the output-beam number.
    Bool checkOutBeam( const uInt& uiOutBeamIn ) const;

    // Check the baseline number.
    Bool checkBaseline( const uInt& uiOutBeamIn,
        const uInt& uiBaselineIn ) const;
    
    // Return the class name.
    virtual String className( void ) const;

    // Return the list of OBConfig{ } methods.
    virtual Vector<String> methods( void ) const;

    // Return the list of OBConfig{ } methods where no trace is printed.
    virtual Vector<String> noTraceMethods( void ) const;

    // The GDC server uses this method to pass arguments to OBConfig{ } methods
    // and run them.
    virtual MethodResult runMethod( uInt uiMethod, ParameterSet& oParameters,
        Bool bRunMethod );

  private:
  
    uInt uiNumOutBeam;
    
    uInt uiNumBaselineMax;
    uInt uiNumSpecChanMax;
    
    String* poFile;
    
    Vector<Int>* poNumBaseline;
    Vector<Int>* poNumSpecChan;
    
    Vector<String>* poSpectrometerID;
    
    Vector<String>* *aoBaselineID;
    
    Vector<Double>* *aoWavelength;
    Vector<Double>* *aoWavelengthErr;
    Vector<Double>* *aoChanWidth;
    Vector<Double>* *aoChanWidthErr;
    
    Vector<Int>* *aoFringeMod;
    
    void loadHDS( String& oFileIn );

};


// #endif (Include file?)

#endif // __OBCONFIG_H
