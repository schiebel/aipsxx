//#OBConfig.cc is part of the Cuttlefish server
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
//# $Id: OBConfig.cc,v 19.0 2003/07/16 06:02:26 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

OBConfig.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the OBConfig{ } class member functions.

Public member functions:
------------------------
OBConfig (3 versions), ~OBConfig, baselineID, chanWidth, chanWidthErr,
checkBaseline, checkOutBeam, dumpHDS, file, fringeMod, numSpecChan, numBaseline,
numOutBeam, obObjects, obObjectErrs, obTools, obTypes, obTypeErrs,
obYLabelDefaults, spectrometerID, tool, version, wavelength, wavelengthErr.

Private member functions:
-------------------------
loadHDS.

Inherited classes (aips++):
---------------------------
ApplicationObject.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              File created with public member functions OBConfig( ) (null,
              standard, and copy versions), ~OBConfig( ), baselineID( ),
              chanWidth( ), chanWidthErr( ), checkOutBeam( ), dumpHDS( ),
              file( ), fringeMod( ), numSpecChan( ), numBaseline( ),
              numOutBeam( ), obTools( ), obYLabelDefaults( ), spectrometerID( ),
              tool( ), version( ), wavelength( ), and wavelengthErr( ); and
              private member function loadHDS( ).
2001 Jan 30 - Nicholas Elias, USNO/NPOI
              Public member functions obObjects( ), obObjectErrs( ),
              obTypes( ), obTypeErrs( ) added.
2001 Jan 31 - Nicholas Elias, USNO/NPOI
              Public member function checkBaseline( ) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/Cuttlefish/OBConfig.h> // OBConfig file

// -----------------------------------------------------------------------------

/*

OBConfig::OBConfig (null)

Description:
------------
This public member function constructs an OBConfig{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

OBConfig::OBConfig( void ) {}

// -----------------------------------------------------------------------------

/*

OBConfig::OBConfig

Description:
------------
This public member function constructs an OBConfig{ } object.

Inputs:
-------
oFileIn - The HDS file name.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

OBConfig::OBConfig( String& oFileIn ) {  
  
  // Load configuration from the HDS file and initialize this object
  
  try {
    loadHDS( oFileIn );
  }
  
  catch ( AipsError oAipsError ) {
    throw( ermsg( "Error in loadHDS( )\n" + oAipsError.getMesg(), "OBConfig",
        "OBConfig" ) );
  }
  
  
  // Return

  return;
  
}

// -----------------------------------------------------------------------------

/*

OBConfig::OBConfig (copy)

Description:
------------
This public member function copies an OBConfig{ } object.

Inputs:
-------
oOBConfigIn - The OBConfig{ } object.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

OBConfig::OBConfig( const OBConfig& oOBConfigIn ) {

  // Declare the local variables

  uInt uiOutBeam; // The output-beam counter


  // Copy the OBConfig{ } object and return
  
  poFile = new String( oOBConfigIn.file() );
  
  uiNumOutBeam = oOBConfigIn.numOutBeam();
  
  poNumBaseline = new Vector<Int>( uiNumOutBeam );
  poNumSpecChan = new Vector<Int>( uiNumOutBeam );
  
  poSpectrometerID = new Vector<String>( uiNumOutBeam );

  aoBaselineID = new Vector<String>* [uiNumOutBeam];

  aoWavelength = new Vector<Double>* [uiNumOutBeam];
  aoWavelengthErr = new Vector<Double>* [uiNumOutBeam];
  aoChanWidth = new Vector<Double>* [uiNumOutBeam];
  aoChanWidthErr = new Vector<Double>* [uiNumOutBeam];
  
  aoFringeMod = new Vector<Int>* [uiNumOutBeam];
  
  for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
    (*poNumBaseline)(uiOutBeam) = oOBConfigIn.numBaseline( uiOutBeam+1 );
    (*poNumSpecChan)(uiOutBeam) = oOBConfigIn.numSpecChan( uiOutBeam+1 );
    (*poSpectrometerID)(uiOutBeam) = oOBConfigIn.spectrometerID( uiOutBeam+1 );
    aoBaselineID[uiOutBeam] =
        new Vector<String>( oOBConfigIn.baselineID( uiOutBeam+1 ) );
    aoWavelength[uiOutBeam] =
        new Vector<Double>( oOBConfigIn.wavelength( uiOutBeam+1 ) );
    aoWavelengthErr[uiOutBeam] =
        new Vector<Double>( oOBConfigIn.wavelengthErr( uiOutBeam+1 ) );
    aoChanWidth[uiOutBeam] =
        new Vector<Double>( oOBConfigIn.chanWidth( uiOutBeam+1 ) );
    aoChanWidthErr[uiOutBeam] =
        new Vector<Double>( oOBConfigIn.chanWidthErr( uiOutBeam+1 ) );
    aoFringeMod[uiOutBeam] =
        new Vector<Int>( oOBConfigIn.fringeMod( uiOutBeam+1 ) );
  }
  
  return;

}

// -----------------------------------------------------------------------------

/*

OBConfig::~OBConfig

Description:
------------
This public member function destructs an OBConfig{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

OBConfig::~OBConfig( void ) {

  // Declare the local variables
  
  uInt uiOutBeam; // The output-beam counter
  

  // Deallocate the memory and return
  
  delete poFile;
  
  delete poNumBaseline;
  delete poNumSpecChan;
  
  delete poSpectrometerID;
  
  for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
    delete aoBaselineID[uiOutBeam];
    delete aoWavelength[uiOutBeam];
    delete aoWavelengthErr[uiOutBeam];
    delete aoChanWidth[uiOutBeam];
    delete aoChanWidthErr[uiOutBeam];
    delete aoFringeMod[uiOutBeam];
  }
  
  delete aoBaselineID;
  
  delete aoWavelength;
  delete aoWavelengthErr;
  delete aoChanWidth;
  delete aoChanWidthErr;
  
  delete aoFringeMod;

  return;

}

// -----------------------------------------------------------------------------

/*

OBConfig::file

Description:
------------
This public member function returns the file name.

Inputs:
-------
None.

Outputs:
--------
The file name, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String OBConfig::file( void ) const {

  // Return the file name

  return( String( *poFile ) );

}

// -----------------------------------------------------------------------------

/*

OBConfig::numOutBeam

Description:
------------
This public member function returns the number of output beams.

Inputs:
-------
None.

Outputs:
--------
The number of output beams, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt OBConfig::numOutBeam( void ) const {

  // Return the number of output beams

  return( uiNumOutBeam );

}

// -----------------------------------------------------------------------------

/*

OBConfig::numBaseline

Description:
------------
This public member function returns the number of baselines.

Inputs:
-------
uiOutBeamIn - The output-beam number.

Outputs:
--------
The number of baselines, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt OBConfig::numBaseline( const uInt& uiOutBeamIn ) const {

  // Check the output-beam number
  
  if ( !checkOutBeam( uiOutBeamIn ) ) {
    throw( ermsg( "Invalid output-beam number", "OBConfig", "numBaseline" ) );
  }
  

  // Return the number of baselines

  return( (*poNumBaseline)(uiOutBeamIn-1) );

}

// -----------------------------------------------------------------------------

/*

OBConfig::numSpecChan

Description:
------------
This public member function returns the number of spectral channels.

Inputs:
-------
uiOutBeamIn - The output-beam number.

Outputs:
--------
The number of spectral channels, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

uInt OBConfig::numSpecChan( const uInt& uiOutBeamIn ) const {

  // Check the output-beam number
  
  if ( !checkOutBeam( uiOutBeamIn ) ) {
    throw( ermsg( "Invalid output-beam number", "OBConfig", "numSpecChan" ) );
  }
  

  // Return the number of spectral channels

  return( (*poNumSpecChan)(uiOutBeamIn-1) );

}

// -----------------------------------------------------------------------------

/*

OBConfig::spectrometerID

Description:
------------
This public member function returns the spectrometer ID.

Inputs:
-------
uiOutBeamIn - The output-beam number.

Outputs:
--------
The spectrometer ID, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String OBConfig::spectrometerID( const uInt& uiOutBeamIn ) const {

  // Check the output-beam number
  
  if ( !checkOutBeam( uiOutBeamIn ) ) {
    throw( ermsg( "Invalid output-beam number", "OBConfig",
        "spectrometerID" ) );
  }
  

  // Return the spectrometer ID

  return( (*poSpectrometerID)(uiOutBeamIn-1) );

}

// -----------------------------------------------------------------------------

/*

OBConfig::baselineID

Description:
------------
This public member function returns the baseline IDs.

Inputs:
-------
uiOutBeamIn - The output-beam number.

Outputs:
--------
The baseline IDs, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> OBConfig::baselineID( const uInt& uiOutBeamIn ) const {

  // Check the output-beam number
  
  if ( !checkOutBeam( uiOutBeamIn ) ) {
    throw( ermsg( "Invalid output-beam number", "OBConfig", "baselineID" ) );
  }
  

  // Return the baseline IDs

  return( *aoBaselineID[uiOutBeamIn-1] );

}

// -----------------------------------------------------------------------------

/*

OBConfig::wavelength

Description:
------------
This public member function returns the wavelengths.

Inputs:
-------
uiOutBeamIn - The output-beam number.

Outputs:
--------
The wavelengths, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> OBConfig::wavelength( const uInt& uiOutBeamIn ) const {

  // Check the output-beam number
  
  if ( !checkOutBeam( uiOutBeamIn ) ) {
    throw( ermsg( "Invalid output-beam number", "OBConfig", "wavelength" ) );
  }
  

  // Return the wavelengths

  return( *aoWavelength[uiOutBeamIn-1] );

}

// -----------------------------------------------------------------------------

/*

OBConfig::wavelengthErr

Description:
------------
This public member function returns the wavelength errors.

Inputs:
-------
uiOutBeamIn - The output-beam number.

Outputs:
--------
The wavelength errors, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> OBConfig::wavelengthErr( const uInt& uiOutBeamIn ) const {

  // Check the output-beam number
  
  if ( !checkOutBeam( uiOutBeamIn ) ) {
    throw( ermsg( "Invalid output-beam number", "OBConfig", "wavelengthErr" ) );
  }
  

  // Return the wavelength errors

  return( *aoWavelengthErr[uiOutBeamIn-1] );

}

// -----------------------------------------------------------------------------

/*

OBConfig::chanWidth

Description:
------------
This public member function returns the channel widths.

Inputs:
-------
uiOutBeamIn - The output-beam number.

Outputs:
--------
The channel widths, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> OBConfig::chanWidth( const uInt& uiOutBeamIn ) const {

  // Check the output-beam number
  
  if ( !checkOutBeam( uiOutBeamIn ) ) {
    throw( ermsg( "Invalid output-beam number", "OBConfig", "chanWidth" ) );
  }
  

  // Return the channel widths

  return( *aoChanWidth[uiOutBeamIn-1] );

}

// -----------------------------------------------------------------------------

/*

OBConfig::chanWidthErr

Description:
------------
This public member function returns the channel-width errors.

Inputs:
-------
uiOutBeamIn - The output-beam number.

Outputs:
--------
The channel-width errors, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Double> OBConfig::chanWidthErr( const uInt& uiOutBeamIn ) const {

  // Check the output-beam number
  
  if ( !checkOutBeam( uiOutBeamIn ) ) {
    throw( ermsg( "Invalid output-beam number", "OBConfig", "chanWidthErr" ) );
  }
  

  // Return the channel-width errors

  return( *aoChanWidthErr[uiOutBeamIn-1] );

}

// -----------------------------------------------------------------------------

/*

OBConfig::fringeMod

Description:
------------
This public member function returns the fringe modulations.

Inputs:
-------
uiOutBeamIn - The output-beam number.

Outputs:
--------
The fringe modulations, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<Int> OBConfig::fringeMod( const uInt& uiOutBeamIn ) const {

  // Check the output-beam number
  
  if ( !checkOutBeam( uiOutBeamIn ) ) {
    throw( ermsg( "Invalid output-beam number", "OBConfig", "fringeMod" ) );
  }
  

  // Return the fringe modulations

  return( *aoFringeMod[uiOutBeamIn-1] );

}

// -----------------------------------------------------------------------------

/*

OBConfig::dumpHDS

Description:
------------
This public member function dumps the output-beam configuration into an HDS
file.

Inputs:
-------
oFileIn - The HDS file name.  If "", default to the object's HDS file name.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void OBConfig::dumpHDS( String& oFileIn ) const {

  // Declare/initialize the local variables
  
  uInt uiOutBeam;            // The output-beam counter
  uInt uiOutBeam2;           // The HDS output-beam counter
  
  String oFile;              // The HDS file
  
  HDSFile* poHDSFile = NULL; // HDSFile{ } object
  

  // Open the HDS file (create it, if necessary)
  
  if ( oFileIn.matches( RXwhite ) ) {
    oFileIn = String( *poFile );
  }
  
  if ( access( oFileIn.chars(), F_OK ) != 0 ) {
    try {
      poHDSFile = new HDSFile( HDSAccess( oFileIn, "NEW" ),
          HDSName( "DataSet" ), HDSType( "" ), HDSDim() );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg( "Cannot create HDS file\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }
    delete poHDSFile;
  }
  
  try {
    HDSAccess oAccess = HDSAccess( oFileIn, "UPDATE" );
    poHDSFile = new HDSFile( oAccess );
  }
  
  catch( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg( "Cannot open HDS file\n" + oAipsError.getMesg(), "OBConfig",
        "dumpHDS" ) );
  }
  
  
  // Go to the GenConfig HDS object (create it, if necessary)

  if ( !poHDSFile->there( HDSName( "GenConfig" ) ) ) {
    try {
      poHDSFile->New( HDSName( "GenConfig" ), HDSType( "" ), HDSDim(), True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create GenConfig HDS object\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }
  }

  poHDSFile->find( HDSName( "GenConfig" ) );
  
  
  // Go to the OutputBeam HDS object (create it, if necessary)

  if ( !poHDSFile->there( HDSName( "OutputBeam" ) ) ) {
    try {
      poHDSFile->New( HDSName( "OutputBeam" ), HDSType( "" ), HDSDim(), True );
    }
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create OutputBeam HDS object\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }
  }

  poHDSFile->find( HDSName( "OutputBeam" ) );
  
  
  // Dump/check the number of output beams
  
  if ( !poHDSFile->there( HDSName( "NumOutBeam" ) ) ) {

    try {
      poHDSFile->screate_integer( HDSName( "NumOutBeam" ), uiNumOutBeam, True );
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create NumOutBeam HDS object\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }

  } else {
  
    uInt uiNumOutBeamTemp = 0; // Keep compiler happy
  
    try {
      uiNumOutBeamTemp = Vector<Int>(
          poHDSFile->obtain_integer( HDSName( "NumOutBeam" ) ) )(0);
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      String oError = "Cannot get number of output beams from HDS file\n";
      oError += oAipsError.getMesg();
      throw( ermsg( oError, "OBConfig", "dumpHDS" ) );
    }
    
    if ( uiNumOutBeamTemp != uiNumOutBeam ) {
      throw( ermsg( "Number of output beams do not match", "OBConfig",
          "dumpHDS" ) );
    }
  
  }
  
  
  // Dump/check the number of baselines
  
  if ( !poHDSFile->there( HDSName( "NumBaseline" ) ) ) {

    try {
      poHDSFile->create_integer( HDSName( "NumBaseline" ),
          Array<Int>( *poNumBaseline ), True );
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create NumBaseline HDS object\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }

  } else {
  
    Vector<Int> oNumBaselineTemp; // Keep compiler happy
  
    try {
      oNumBaselineTemp = poHDSFile->obtain_integer( HDSName( "NumBaseline" ) );
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      String oError = "Cannot get number of baselines from HDS file\n";
      oError += oAipsError.getMesg();
      throw( ermsg( oError, "OBConfig", "dumpHDS" ) );
    }
    
    if ( oNumBaselineTemp != *poNumBaseline ) {
      throw( ermsg( "Number of baselines do not match", "OBConfig",
          "dumpHDS" ) );
    }
  
  }
  
  
  // Dump/check the number of spectral channels
  
  if ( !poHDSFile->there( HDSName( "NumSpecChan" ) ) ) {

    try {
      poHDSFile->create_integer( HDSName( "NumSpecChan" ),
          Array<Int>( *poNumSpecChan ), True );
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create NumSpecChan HDS object\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }

  } else {
  
    Vector<Int> oNumSpecChanTemp; // Keep compiler happy
  
    try {
      oNumSpecChanTemp = poHDSFile->obtain_integer( HDSName( "NumSpecChan" ) );
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      String oError = "Cannot get number of spectral channels from HDS file\n";
      oError += oAipsError.getMesg();
      throw( ermsg( oError, "OBConfig", "dumpHDS" ) );
    }
    
    if ( oNumSpecChanTemp != *poNumSpecChan ) {
      throw( ermsg( "Number of spectral channels do not match", "OBConfig",
          "dumpHDS" ) );
    }
  
  }
  
  
  // Dump/check the spectrometer IDs
  
  if ( !poHDSFile->there( HDSName( "SpectrometerID" ) ) ) {

    try {
      poHDSFile->create_char( HDSName( "SpectrometerID" ), 7,
          Array<String>( *poSpectrometerID ), True );
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create SpectrometerID HDS object\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }

  } else {
  
    Vector<String> oSpectrometerIDTemp; // Keep compiler happy
  
    try {
      oSpectrometerIDTemp =
          poHDSFile->obtain_char( HDSName( "SpectrometerID" ) );
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get SpectrometerID from HDS file\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }
    
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      if ( oSpectrometerIDTemp(uiOutBeam) != (*poSpectrometerID)(uiOutBeam) ) {
        throw( ermsg( "Spectrometer IDs do not match", "OBConfig",
            "dumpHDS" ) );
      }
    }
  
  }
  
  
  // Dump/check the baseline IDs
  
  if ( !poHDSFile->there( HDSName( "BaselineID" ) ) ) {

    uInt uiNumBaseline = 0; // Keep compiler happy
    
    try {
      poHDSFile->New( HDSName( "BaselineID" ), HDSType( "_CHAR*7" ),
          HDSDim( uiNumBaselineMax, uiNumOutBeam ), True );
      poHDSFile->find( HDSName( "BaselineID" ) );
      for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
        uiOutBeam2 = uiOutBeam + 1;
        uiNumBaseline = (*poNumBaseline)(uiOutBeam);
        poHDSFile->slice(
            HDSDim( 1,uiOutBeam2 ), HDSDim( uiNumBaseline,uiOutBeam2 ) );
        poHDSFile->put_char( *aoBaselineID[uiOutBeam] );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create Baseline HDS object\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }

  } else {

    uInt uiNumBaseline = 0;                        // Keep compiler happy
    Vector<String> aoBaselineIDTemp[uiNumOutBeam]; // Keep compiler happy

    try {
      poHDSFile->find( HDSName( "BaselineID" ) );
      for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
        uiOutBeam2 = uiOutBeam + 1;
        uiNumBaseline = (*poNumBaseline)(uiOutBeam);
        poHDSFile->slice(
            HDSDim( 1,uiOutBeam2 ), HDSDim( uiNumBaseline,uiOutBeam2 ) );
        aoBaselineIDTemp[uiOutBeam] =
            poHDSFile->get_char().reform( IPosition(1,uiNumBaseline) );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get BaselineID from HDS file\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }
    
    uInt uiBaseline;
    
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      uiNumBaseline = (*poNumBaseline)(uiOutBeam);
      for ( uiBaseline = 0; uiBaseline < uiNumBaseline; uiBaseline++ ) {
        if ( aoBaselineIDTemp[uiOutBeam](uiBaseline) !=
            (*aoBaselineID[uiOutBeam])(uiBaseline) ) {
          throw( ermsg( "Baseline IDs do not match", "OBConfig", "dumpHDS" ) );
        }
      }
    }
      
  }
  
  
  // Dump/check the wavelengths
  
  if ( !poHDSFile->there( HDSName( "Wavelength" ) ) ) {

    uInt uiNumSpecChan = 0; // Keep compiler happy
    
    try {
      poHDSFile->New( HDSName( "Wavelength" ), HDSType( "_DOUBLE" ),
          HDSDim( uiNumSpecChanMax, uiNumOutBeam ), True );
      poHDSFile->find( HDSName( "Wavelength" ) );
      for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
        uiOutBeam2 = uiOutBeam + 1;
        uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
        poHDSFile->slice(
            HDSDim( 1,uiOutBeam2 ), HDSDim( uiNumSpecChan,uiOutBeam2 ) );
        poHDSFile->put_double( *aoWavelength[uiOutBeam] );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create Wavelength HDS object\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }

  } else {

    uInt uiNumSpecChan = 0;                        // Keep compiler happy
    Vector<Double> aoWavelengthTemp[uiNumOutBeam]; // Keep compiler happy

    try {
      poHDSFile->find( HDSName( "Wavelength" ) );
      for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
        uiOutBeam2 = uiOutBeam + 1;
        uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
        poHDSFile->slice(
            HDSDim( 1,uiOutBeam2 ), HDSDim( uiNumSpecChan,uiOutBeam2 ) );
        aoWavelengthTemp[uiOutBeam] =
            poHDSFile->get_double().reform( IPosition(1,uiNumSpecChan) );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get Wavelength from HDS file\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }
    
    uInt uiSpecChan;
    
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
      for ( uiSpecChan = 0; uiSpecChan < uiNumSpecChan; uiSpecChan++ ) {
        if ( aoWavelengthTemp[uiOutBeam](uiSpecChan) !=
            (*aoWavelength[uiOutBeam])(uiSpecChan) ) {
          throw( ermsg( "Wavelengths do not match", "OBConfig", "dumpHDS" ) );
        }
      }
    }
      
  }
  
  
  // Dump/check the wavelength errors
  
  if ( !poHDSFile->there( HDSName( "WavelengthErr" ) ) ) {

    uInt uiNumSpecChan = 0; // Keep compiler happy
    
    try {
      poHDSFile->New( HDSName( "WavelengthErr" ), HDSType( "_DOUBLE" ),
          HDSDim( uiNumSpecChanMax, uiNumOutBeam ), True );
      poHDSFile->find( HDSName( "WavelengthErr" ) );
      for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
        uiOutBeam2 = uiOutBeam + 1;
        uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
        poHDSFile->slice(
            HDSDim( 1,uiOutBeam2 ), HDSDim( uiNumSpecChan,uiOutBeam2 ) );
        poHDSFile->put_double( *aoWavelengthErr[uiOutBeam] );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create WavelengthErr HDS object\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }

  } else {

    uInt uiNumSpecChan = 0;                           // Keep compiler happy
    Vector<Double> aoWavelengthErrTemp[uiNumOutBeam]; // Keep compiler happy

    try {
      poHDSFile->find( HDSName( "WavelengthErr" ) );
      for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
        uiOutBeam2 = uiOutBeam + 1;
        uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
        poHDSFile->slice(
            HDSDim( 1,uiOutBeam2 ), HDSDim( uiNumSpecChan,uiOutBeam2 ) );
        aoWavelengthErrTemp[uiOutBeam] =
            poHDSFile->get_double().reform( IPosition(1,uiNumSpecChan) );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get WavelengthErr from HDS file\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }
    
    uInt uiSpecChan;
    
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
      for ( uiSpecChan = 0; uiSpecChan < uiNumSpecChan; uiSpecChan++ ) {
        if ( aoWavelengthErrTemp[uiOutBeam](uiSpecChan) !=
            (*aoWavelengthErr[uiOutBeam])(uiSpecChan) ) {
          throw( ermsg( "Wavelength errors do not match", "OBConfig",
              "dumpHDS" ) );
        }
      }
    }
      
  }
  
  
  // Dump/check the channel widths
  
  if ( !poHDSFile->there( HDSName( "ChanWidth" ) ) ) {

    uInt uiNumSpecChan = 0; // Keep compiler happy
    
    try {
      poHDSFile->New( HDSName( "ChanWidth" ), HDSType( "_DOUBLE" ),
          HDSDim( uiNumSpecChanMax, uiNumOutBeam ), True );
      poHDSFile->find( HDSName( "ChanWidth" ) );
      for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
        uiOutBeam2 = uiOutBeam + 1;
        uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
        poHDSFile->slice(
            HDSDim( 1,uiOutBeam2 ), HDSDim( uiNumSpecChan,uiOutBeam2 ) );
        poHDSFile->put_double( *aoChanWidth[uiOutBeam] );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create ChanWidth HDS object\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }

  } else {

    uInt uiNumSpecChan = 0;                       // Keep compiler happy
    Vector<Double> aoChanWidthTemp[uiNumOutBeam]; // Keep compiler happy

    try {
      poHDSFile->find( HDSName( "ChanWidth" ) );
      for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
        uiOutBeam2 = uiOutBeam + 1;
        uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
        poHDSFile->slice(
            HDSDim( 1,uiOutBeam2 ), HDSDim( uiNumSpecChan,uiOutBeam2 ) );
        aoChanWidthTemp[uiOutBeam] =
            poHDSFile->get_double().reform( IPosition(1,uiNumSpecChan) );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get ChanWidth from HDS file\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }
    
    uInt uiSpecChan;
    
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
      for ( uiSpecChan = 0; uiSpecChan < uiNumSpecChan; uiSpecChan++ ) {
        if ( aoChanWidthTemp[uiOutBeam](uiSpecChan) !=
            (*aoChanWidth[uiOutBeam])(uiSpecChan) ) {
          throw( ermsg( "Channel widths do not match", "OBConfig",
              "dumpHDS" ) );
        }
      }
    }
      
  }
  
  
  // Dump/check the channel width errors
  
  if ( !poHDSFile->there( HDSName( "ChanWidthErr" ) ) ) {

    uInt uiNumSpecChan = 0; // Keep compiler happy
    
    try {
      poHDSFile->New( HDSName( "ChanWidthErr" ), HDSType( "_DOUBLE" ),
          HDSDim( uiNumSpecChanMax, uiNumOutBeam ), True );
      poHDSFile->find( HDSName( "ChanWidthErr" ) );
      for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
        uiOutBeam2 = uiOutBeam + 1;
        uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
        poHDSFile->slice(
            HDSDim( 1,uiOutBeam2 ), HDSDim( uiNumSpecChan,uiOutBeam2 ) );
        poHDSFile->put_double( *aoChanWidthErr[uiOutBeam] );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create ChanWidthErr HDS object\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }

  } else {

    uInt uiNumSpecChan = 0;                          // Keep compiler happy
    Vector<Double> aoChanWidthErrTemp[uiNumOutBeam]; // Keep compiler happy

    try {
      poHDSFile->find( HDSName( "ChanWidthErr" ) );
      for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
        uiOutBeam2 = uiOutBeam + 1;
        uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
        poHDSFile->slice(
            HDSDim( 1,uiOutBeam2 ), HDSDim( uiNumSpecChan,uiOutBeam2 ) );
        aoChanWidthErrTemp[uiOutBeam] =
            poHDSFile->get_double().reform( IPosition(1,uiNumSpecChan) );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get ChanWidthErr from HDS file\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }
    
    uInt uiSpecChan;
    
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
      for ( uiSpecChan = 0; uiSpecChan < uiNumSpecChan; uiSpecChan++ ) {
        if ( aoChanWidthErrTemp[uiOutBeam](uiSpecChan) !=
            (*aoChanWidthErr[uiOutBeam])(uiSpecChan) ) {
          throw( ermsg( "Channel width errors do not match", "OBConfig",
              "dumpHDS" ) );
        }
      }
    }
      
  }
  
  
  // Dump/check the fringe modulations
  
  if ( !poHDSFile->there( HDSName( "FringeMod" ) ) ) {

    uInt uiNumBaseline = 0; // Keep compiler happy
    
    try {
      poHDSFile->New( HDSName( "FringeMod" ), HDSType( "_INTEGER" ),
          HDSDim( uiNumBaselineMax, uiNumOutBeam ), True );
      poHDSFile->find( HDSName( "FringeMod" ) );
      for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
        uiOutBeam2 = uiOutBeam + 1;
        uiNumBaseline = (*poNumBaseline)(uiOutBeam);
        poHDSFile->slice(
            HDSDim( 1,uiOutBeam2 ), HDSDim( uiNumBaseline,uiOutBeam2 ) );
        poHDSFile->put_integer( *aoFringeMod[uiOutBeam] );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }

    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot create FringeMod HDS object\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }

  } else {

    uInt uiNumBaseline = 0;                    // Keep compiler happy
    Vector<Int> aoFringeModTemp[uiNumOutBeam]; // Keep compiler happy

    try {
      poHDSFile->find( HDSName( "FringeMod" ) );
      for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
        uiOutBeam2 = uiOutBeam + 1;
        uiNumBaseline = (*poNumBaseline)(uiOutBeam);
        poHDSFile->slice(
            HDSDim( 1,uiOutBeam2 ), HDSDim( uiNumBaseline,uiOutBeam2 ) );
        aoFringeModTemp[uiOutBeam] =
            poHDSFile->get_integer().reform( IPosition(1,uiNumBaseline) );
        poHDSFile->annul();
      }
      poHDSFile->annul();
    }
    
    catch ( AipsError oAipsError ) {
      delete poHDSFile;
      throw( ermsg(
          "Cannot get FringeMod from HDS file\n" + oAipsError.getMesg(),
          "OBConfig", "dumpHDS" ) );
    }
    
    uInt uiBaseline;
    
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      uiNumBaseline = (*poNumBaseline)(uiOutBeam);
      for ( uiBaseline = 0; uiBaseline < uiNumBaseline; uiBaseline++ ) {
        if ( aoFringeModTemp[uiOutBeam](uiBaseline) !=
            (*aoFringeMod[uiOutBeam])(uiBaseline) ) {
          throw( ermsg( "Fringe modulations do not match", "OBConfig",
              "dumpHDS" ) );
        }
      }
    }
      
  }
  
  
  // Close the HDS file
  
  delete poHDSFile;
  
  
  // Return
  
  return;

}

// -----------------------------------------------------------------------------

/*

OBConfig::version

Description:
------------
This public member function returns the OBConfig{ } version.

Inputs:
-------
None.

Outputs:
--------
The OBConfig{ } version, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String OBConfig::version( void ) const {

  // Return the OBConfig{ } version
  
  return( String( "0.0" ) );
  
}

// -----------------------------------------------------------------------------

/*

OBConfig::tool

Description:
------------
This public member function returns the glish tool name (must be "obconfig").

Inputs:
-------
None.

Outputs:
--------
The glish tool name, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String OBConfig::tool( void ) const {

  // Return the glish tool name
  
  String oTool = className();
  oTool.downcase();
  
  return( oTool );
  
}

// -----------------------------------------------------------------------------

/*

OBConfig::obToolID

Description:
------------
This public member function returns the output-beam tool ID.

Inputs:
-------
oOBToolIn - The output-beam tool name.

Outputs:
--------
The output-beam tool ID, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Int OBConfig::obToolID( String& oOBToolIn ) const {

  // Declare the local variables
  
  uInt uiNumTool; // The number of tools
  uInt uiTool;    // The tool counter
  

  // Return the output-beam tool ID
  
  oOBToolIn.gsub( RXwhite, "" );
  oOBToolIn.upcase();
  
  Vector<String> oOBToolList = obTools();
  uiNumTool = oOBToolList.nelements();
  
  for ( uiTool = 0; uiTool < uiNumTool; uiTool++ ) {
    if ( oOBToolIn.matches( oOBToolList(uiTool) ) ) {
      break;
    }
  }

  if ( uiTool < uiNumTool ) {
    return( (Int) uiTool );
  } else {
    return( -1 );
  }
  
}

// -----------------------------------------------------------------------------

/*

OBConfig::obTools

Description:
------------
This public member function returns the output-beam tool names.

Inputs:
-------
None.

Outputs:
--------
The output-beam tool names, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> OBConfig::obTools( void ) const {

  // Return the output-beam tool names
  
  Vector<String> oTools = Vector<String>( 6 );
  
  oTools(0) = String( "VISSQ" );
  oTools(1) = String( "VISSQC" );
  oTools(2) = String( "DELAYJITTER" );
  oTools(3) = String( "PHOTONRATE" );
  oTools(4) = String( "BACKGNDRATE" );
  oTools(5) = String( "UVW" );
  
  return( oTools );
  
}

// -----------------------------------------------------------------------------

/*

OBConfig::obObjects

Description:
------------
This public member function returns the output-beam HDS object names.

Inputs:
-------
None.

Outputs:
--------
The output-beam HDS object names, returned via the function value.

Modification history:
---------------------
2001 Jan 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> OBConfig::obObjects( void ) const {

  // Return the output-beam HDS object names
  
  Vector<String> oObjects = Vector<String>( 6 );
  
  oObjects(0) = String( "VISSQ" );
  oObjects(1) = String( "VISSQC" );
  oObjects(2) = String( "DELAYJITTER" );
  oObjects(3) = String( "PHOTONRATE" );
  oObjects(4) = String( "BACKGNDRATE" );
  oObjects(5) = String( "UVW" );
  
  return( oObjects );
  
}

// -----------------------------------------------------------------------------

/*

OBConfig::obObjectErrs

Description:
------------
This public member function returns the output-beam HDS object-error names.

Inputs:
-------
None.

Outputs:
--------
The output-beam HDS object-error names, returned via the function value.

Modification history:
---------------------
2001 Jan 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> OBConfig::obObjectErrs( void ) const {

  // Return the output-beam HDS object-error names
  
  Vector<String> oObjectErrs = Vector<String>( 6 );
  
  oObjectErrs(0) = String( "VISSQERR" );
  oObjectErrs(1) = String( "VISSQCERR" );
  oObjectErrs(2) = String( "DELAYJITTERERR" );
  oObjectErrs(3) = String( "PHOTONRATEERR" );
  oObjectErrs(4) = String( "BACKGNDERR" );
  oObjectErrs(5) = String( "" );
  
  return( oObjectErrs );
  
}

// -----------------------------------------------------------------------------

/*

OBConfig::obTypes

Description:
------------
This public member function returns the output-beam HDS object types.

Inputs:
-------
None.

Outputs:
--------
The output-beam HDS object types, returned via the function value.

Modification history:
---------------------
2001 Jan 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> OBConfig::obTypes( void ) const {

  // Return the output-beam HDS object types
  
  Vector<String> oTypes = Vector<String>( 56 );
  
  oTypes(0) = String( "_REAL" );
  oTypes(1) = String( "_REAL" );
  oTypes(2) = String( "_REAL" );
  oTypes(3) = String( "_REAL" );
  oTypes(4) = String( "_REAL" );
  oTypes(5) = String( "_DOUBLE" );
  
  return( oTypes );
  
}

// -----------------------------------------------------------------------------

/*

OBConfig::obTypeErrs

Description:
------------
This public member function returns the output-beam HDS object-error types.

Inputs:
-------
None.

Outputs:
--------
The output-beam HDS object-error types, returned via the function value.

Modification history:
---------------------
2001 Jan 30 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> OBConfig::obTypeErrs( void ) const {

  // Return the output-beam HDS object-error types
  
  Vector<String> oTypeErrs = Vector<String>( 6 );
  
  oTypeErrs(0) = String( "_REAL" );
  oTypeErrs(1) = String( "_REAL" );
  oTypeErrs(2) = String( "_REAL" );
  oTypeErrs(3) = String( "_REAL" );
  oTypeErrs(4) = String( "_REAL" );
  oTypeErrs(5) = String( "" );
  
  return( oTypeErrs );
  
}

// -----------------------------------------------------------------------------

/*

OBConfig::obYLabelDefaults

Description:
------------
This public member function returns the output-beam y-axis label defaults.

Inputs:
-------
None.

Outputs:
--------
The output-beam y-axis label defaults, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> OBConfig::obYLabelDefaults( void ) const {

  // Return the output-beam y-axis label defaults
  
  Vector<String> oYLabels = Vector<String>( 6 );
  
  oYLabels(0) = String( "Squared Visibility" );
  oYLabels(1) = String( "Squared Visibility" );
  oYLabels(2) = String( "Delay Jitter (m)" );
  oYLabels(3) = String( "Photon Rate (photons)" );
  oYLabels(4) = String( "Background Rate (photons)" );
  oYLabels(5) = String( "Spatial Frequency (m\\u-1\\d)" );
  
  return( oYLabels );
  
}

// -----------------------------------------------------------------------------

/*

OBConfig::checkOutBeam

Description:
------------
This public member function checks the output-beam number.

Inputs:
-------
uiOutBeamIn - The output-beam number.

Outputs:
--------
True (if OK) or False (if !OK), returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.
              
*/

// -----------------------------------------------------------------------------

Bool OBConfig::checkOutBeam( const uInt& uiOutBeamIn ) const {

  // Check the output-beam number and return the boolean
  
  if ( uiOutBeamIn >= 1 && uiOutBeamIn <= numOutBeam() ) {
    return( True );
  } else {
    return( False );
  }

}

// -----------------------------------------------------------------------------

/*

OBConfig::checkBaseline

Description:
------------
This public member function checks the baseline number.

Inputs:
-------
uiOutBeamIn  - The output-beam number.
uiBaselineIn - The baseline number.

Outputs:
--------
True (if OK) or False (if !OK), returned via the function value.

Modification history:
---------------------
2001 Jan 31 - Nicholas Elias, USNO/NPOI
              Public member function created.
              
*/

// -----------------------------------------------------------------------------

Bool OBConfig::checkBaseline( const uInt& uiOutBeamIn,
    const uInt& uiBaselineIn ) const {

  // Check the baseline number and return the boolean

  if ( !checkOutBeam( uiOutBeamIn ) ) {
    return( False );
  }
  
  if ( uiBaselineIn >= 0 && uiBaselineIn <= numBaseline( uiOutBeamIn ) ) {
    return( True );
  } else {
    return( False );
  }

}

// -----------------------------------------------------------------------------

/*

OBConfig::className

Description:
------------
This public member function returns the class name.

Inputs:
-------
None.

Outputs:
--------
The class name, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

String OBConfig::className( void ) const {

  // Return the class name
  
  return( String( "OBConfig" ) );

}

// -----------------------------------------------------------------------------

/*

OBConfig::methods

Description:
------------
This public member function returns the method names.

Inputs:
-------
None.

Outputs:
--------
The method names, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> OBConfig::methods( void ) const {

  // Return the method names
  
  Vector<String> oMethod = Vector<String>( 23 );
  
  oMethod(0) = String( "file" );
  oMethod(1) = String( "numOutBeam" );
  oMethod(2) = String( "numBaseline" );
  oMethod(3) = String( "numSpecChan" );
  oMethod(4) = String( "spectrometerID" );
  oMethod(5) = String( "baselineID" );
  oMethod(6) = String( "wavelength" );
  oMethod(7) = String( "wavelengthErr" );
  oMethod(8) = String( "chanWidth" );
  oMethod(9) = String( "chanWidthErr" );
  oMethod(10) = String( "fringeMod" );
  oMethod(11) = String( "dumpHDS" );
  oMethod(12) = String( "id" );
  oMethod(13) = String( "version" );
  oMethod(14) = String( "tool" );
  oMethod(15) = String( "obTools" );
  oMethod(16) = String( "obObjects" );
  oMethod(17) = String( "obObjectErrs" );
  oMethod(18) = String( "obTypes" );
  oMethod(19) = String( "obTypeErrs" );
  oMethod(20) = String( "obYLabelDefaults" );
  oMethod(21) = String( "checkOutBeam" );
  oMethod(22) = String( "checkBaseline" );
  
  return( oMethod );

}

// -----------------------------------------------------------------------------

/*

OBConfig::noTraceMethods

Description:
------------
This public member function returns the method names that are not traced.

Inputs:
-------
None.

Outputs:
--------
The method names, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Vector<String> OBConfig::noTraceMethods( void ) const {

  // Return the method names
  
  return( methods() );

}

// -----------------------------------------------------------------------------

/*

OBConfig::runMethod

Description:
------------
This public member function provides the glish/aips++ interface for running the
methods of this class.

Inputs:
-------
uiMethod    - The method number.
oParameters - The method parameters.
bRunMethod  - The method run boolean.

Outputs:
--------
The method result, returned via the function value.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult OBConfig::runMethod( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {
    
    // file
    case 0: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = file();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "file( ) error\n" + oAipsError.getMesg(), "OBConfig",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // numOutBeam
    case 1: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) numOutBeam();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "numOutBeam( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // numBaseline
    case 2: {
      Parameter<Int> outbeam( oParameters, "outbeam", ParameterSet::In );
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) numBaseline( (uInt) outbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "numBaseline( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // numSpecChan
    case 3: {
      Parameter<Int> outbeam( oParameters, "outbeam", ParameterSet::In );
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) numSpecChan( (uInt) outbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "numSpecChan( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // spectrometerID
    case 4: {
      Parameter<Int> outbeam( oParameters, "outbeam", ParameterSet::In );
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = spectrometerID( (uInt) outbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "spectrometerID( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // baselineID
    case 5: {
      Parameter<Int> outbeam( oParameters, "outbeam", ParameterSet::In );
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = baselineID( (uInt) outbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "baselineID( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // wavelength
    case 6: {
      Parameter<Int> outbeam( oParameters, "outbeam", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = wavelength( (uInt) outbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "wavelength( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // wavelengthErr
    case 7: {
      Parameter<Int> outbeam( oParameters, "outbeam", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = wavelengthErr( (uInt) outbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "wavelengthErr( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }
     
    // chanWidth
    case 8: {
      Parameter<Int> outbeam( oParameters, "outbeam", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = chanWidth( (uInt) outbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "chanWidth( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }
     
    // chanWidthErr
    case 9: {
      Parameter<Int> outbeam( oParameters, "outbeam", ParameterSet::In );
      Parameter< Vector<Double> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = chanWidthErr( (uInt) outbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "chanWidthErr( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }
     
    // fringeMod
    case 10: {
      Parameter<Int> outbeam( oParameters, "outbeam", ParameterSet::In );
      Parameter< Vector<Int> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = fringeMod( (uInt) outbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "fringeMod( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // dumpHDS
    case 11: {
      Parameter<String> file( oParameters, "file", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          dumpHDS( file() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "dumpHDS( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }
    
    // id    
    case 12: {
      Parameter<ObjectID> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
	  returnval() = id();
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "id( ) error\n" + oAipsError.getMesg(), "OBConfig",
	      "runMethod" ) );
	}
      }
      break;
    }

    // version
    case 13: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = version();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "version( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // tool
    case 14: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = tool();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "tool( ) error\n" + oAipsError.getMesg(), "OBConfig",
	      "runMethod" ) );
        }
      }
      break;
    }

    // obTools
    case 15: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obTools();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "obTools( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // obObjects
    case 16: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obObjects();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "obObjects( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // obObjectErrs
    case 17: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obObjectErrs();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "obObjectErrs( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // obTypes
    case 18: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obTypes();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "obTypes( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // obTypeErrs
    case 19: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obTypeErrs();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "obTypeErrs( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // obYLabelDefaults
    case 20: {
      Parameter< Vector<String> >
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obYLabelDefaults();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "obYLabelDefaults( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) );
        }
      }
      break;
    }

    // checkOutBeam
    case 21: {
      Parameter<Int> outbeam( oParameters, "outbeam", ParameterSet::In );
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = checkOutBeam( (uInt) outbeam() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "checkOutBeam( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) ); 
        }     
      }
      break;
    }

    // checkBaseline
    case 22: {
      Parameter<Int> outbeam( oParameters, "outbeam", ParameterSet::In );
      Parameter<Int> baseline( oParameters, "baseline", ParameterSet::In );
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = checkBaseline( (uInt) outbeam(), (uInt) baseline() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "checkBaseline( ) error\n" + oAipsError.getMesg(),
              "OBConfig", "runMethod" ) ); 
        }     
      }
      break;
    }

    // default
    default: {
      if ( bRunMethod ) {
        throw( ermsg( "Invalid OBConfig{ } method", "OBConfig", "runMethod" ) );
      }
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}

// -----------------------------------------------------------------------------

/*

OBConfig::loadHDS

Description:
------------
This private member function loads the output-beam configuration from an HDS
file.

Inputs:
-------
oFileIn - The HDS file name.

Outputs:
--------
None.

Modification history:
---------------------
2001 Jan 18 - Nicholas Elias, USNO/NPOI
              Private member function created.

*/

// -----------------------------------------------------------------------------

void OBConfig::loadHDS( String& oFileIn ) {
  
  // Declare/initialize the local variables
  
  uInt uiNumBaseline;        // The number of baselines for a given output beam
  uInt uiNumSpecChan;        // The number of spectral channels for a given
                             // output beam
  uInt uiOutBeam;            // The output-beam counter
  uInt uiOutBeam2;           // The HDS output-beam counter
  
  HDSFile* poHDSFile = NULL; // The HDSFile{ } object
  

  // Open the HDS file
  
  oFileIn.gsub( RXwhite, "" );
  
  try {
    HDSAccess oAccess = HDSAccess( oFileIn, "READ" );
    poHDSFile = new HDSFile( oAccess );
  }
  
  catch( AipsError oAipsError ) {
    throw( ermsg( "Cannot open HDS file\n" + oAipsError.getMesg(), "OBConfig",
        "loadHDS" ) );
  }

  poFile = new String( oFileIn );
  
  
  // Go to the output-beam configuration
  
  try {
    poHDSFile->Goto( "DataSet.GenConfig.OutputBeam" );
  }
  
  catch ( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg( "No output-beam configuration\n" + oAipsError.getMesg(),
        "OBConfig", "loadHDS" ) );
  }
  
  
  // Get the output-beam configuration
  
  try {
  
    uiNumOutBeam = (uInt) Vector<Int>(
        poHDSFile->obtain_integer( HDSName( "NumOutBeam" ) ) )(0);
    poNumBaseline = new Vector<Int>(
        poHDSFile->obtain_integer( HDSName( "NumBaseline" ) ) );
    poNumSpecChan = new Vector<Int>(
        poHDSFile->obtain_integer( HDSName( "NumSpecChan" ) ) );
    poSpectrometerID = new Vector<String>(
        poHDSFile->obtain_char( HDSName( "SpectrometerID" ) ) );

    poHDSFile->find( HDSName( "BaselineID" ) );
    aoBaselineID = new Vector<String>* [uiNumOutBeam];
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      uiOutBeam2 = uiOutBeam + 1;
      uiNumBaseline = (*poNumBaseline)(uiOutBeam);
      poHDSFile->slice(
          HDSDim( 1, uiOutBeam2 ), HDSDim( uiNumBaseline, uiOutBeam2 ) );
      aoBaselineID[uiOutBeam] = new Vector<String>(
          poHDSFile->get_char().reform( IPosition(1,uiNumBaseline) ) );
      poHDSFile->annul();
    }
    poHDSFile->annul();

    poHDSFile->find( HDSName( "Wavelength" ) );
    aoWavelength = new Vector<Double>* [uiNumOutBeam];
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      uiOutBeam2 = uiOutBeam + 1;
      uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
      poHDSFile->slice(
          HDSDim( 1, uiOutBeam2 ), HDSDim( uiNumSpecChan, uiOutBeam2 ) );
      aoWavelength[uiOutBeam] = new Vector<Double>(
          poHDSFile->get_double().reform( IPosition(1,uiNumSpecChan) ) );
      poHDSFile->annul();
    }
    poHDSFile->annul();

    poHDSFile->find( HDSName( "WavelengthErr" ) );
    aoWavelengthErr = new Vector<Double>* [uiNumOutBeam];
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      uiOutBeam2 = uiOutBeam + 1;
      uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
      poHDSFile->slice(
          HDSDim( 1, uiOutBeam2 ), HDSDim( uiNumSpecChan, uiOutBeam2 ) );
      aoWavelengthErr[uiOutBeam] = new Vector<Double>(
          poHDSFile->get_double().reform( IPosition(1,uiNumSpecChan) ) );
      poHDSFile->annul();
    }
    poHDSFile->annul();

    poHDSFile->find( HDSName( "ChanWidth" ) );
    aoChanWidth = new Vector<Double>* [uiNumOutBeam];
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      uiOutBeam2 = uiOutBeam + 1;
      uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
      poHDSFile->slice(
          HDSDim( 1, uiOutBeam2 ), HDSDim( uiNumSpecChan, uiOutBeam2 ) );
      aoChanWidth[uiOutBeam] = new Vector<Double>(
          poHDSFile->get_double().reform( IPosition(1,uiNumSpecChan) ) );
      poHDSFile->annul();
    }
    poHDSFile->annul();

    poHDSFile->find( HDSName( "ChanWidthErr" ) );
    aoChanWidthErr = new Vector<Double>* [uiNumOutBeam];
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      uiOutBeam2 = uiOutBeam + 1;
      uiNumSpecChan = (*poNumSpecChan)(uiOutBeam);
      poHDSFile->slice(
          HDSDim( 1, uiOutBeam2 ), HDSDim( uiNumSpecChan, uiOutBeam2 ) );
      aoChanWidthErr[uiOutBeam] = new Vector<Double>(
          poHDSFile->get_double().reform( IPosition(1,uiNumSpecChan) ) );
      poHDSFile->annul();
    }
    poHDSFile->annul();

    poHDSFile->find( HDSName( "FringeMod" ) );
    aoFringeMod = new Vector<Int>* [uiNumOutBeam];
    for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
      uiOutBeam2 = uiOutBeam + 1;
      uiNumBaseline = (*poNumBaseline)(uiOutBeam);
      poHDSFile->slice(
          HDSDim( 1, uiOutBeam2 ), HDSDim( uiNumBaseline, uiOutBeam2 ) );
      aoFringeMod[uiOutBeam] = new Vector<Int>(
          poHDSFile->get_integer().reform( IPosition(1,uiNumBaseline) ) );
      poHDSFile->annul();
    }
    poHDSFile->annul();
    
  }
  
  catch ( AipsError oAipsError ) {
    delete poHDSFile;
    throw( ermsg(
        "Cannot load output-beam configuration\n" + oAipsError.getMesg(),
        "OBConfig", "loadHDS" ) );
  }


  // Close the HDS file

  delete poHDSFile;
  
  
  // Determine the maximum number of baselines and spectral channels
  
  uiNumBaselineMax = 0;
  uiNumSpecChanMax = 0;
  
  for ( uiOutBeam = 0; uiOutBeam < uiNumOutBeam; uiOutBeam++ ) {
    if ( (*poNumBaseline)(uiOutBeam) > (Int) uiNumBaselineMax ) {
      uiNumBaselineMax = (*poNumBaseline)(uiOutBeam);
    }
    if ( (*poNumSpecChan)(uiOutBeam) > (Int) uiNumSpecChanMax ) {
      uiNumSpecChanMax = (*poNumSpecChan)(uiOutBeam);
    }
  }
  
  
  // Return
  
  return;

}
