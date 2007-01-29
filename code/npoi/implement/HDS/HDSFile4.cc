//#HDSFile.cc is part of Cuttlefish (NPOI data reduction package)
//#Copyright (C) 1999,2000,2001
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
//#Correspondence concerning Cuttlefish should be addressed as follows:
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
//# $Id: HDSFile4.cc,v 19.0 2003/07/16 06:03:19 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

HDSFile.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the HDSFile{ } class member functions.

Public member functions:
------------------------
HDSFile (3 versions), ~HDSFile, alter, annul, cell, checkSlice, clen, clone,
copy, copy2file, create_byte, create_char, create_double, create_integer,
create_logical, create_real, create_ubyte, create_uword, create_word, erase,
file, find, get_byte, get_char, get_double, get_integer, get_logical, get_real,
get_ubyte, get_uword, get_word, Goto, index, len, list, locator, locatord,
locators, mode, move, name, ncomp, New, numDim, obtain_byte, obtain_char,
obtain_double, obtain_integer, obtain_logical, obtain_real, obtain_ubyte,
obtain_uword, obtain_word, path, prec, prim, put_byte, put_char, put_double,
put_integer, put_logical, put_real, put_ubyte, put_uword, put_word, recover,
renam, reset, retyp, save, screate_byte, screate_char, screate_double,
screate_integer, screate_logical, screate_real, screate_ubyte, screate_uword,
screate_word, shape, size, slice, state, struc, there, top, type, valid,
version.

Static public member functions:
-------------------------------
dimMax, locatorMax, noLocator, sizeLocator, sizeMode, sizeName, sizetype.

Inherited classes (aips++):
---------------------------
ApplicationObject.

Inherited classes (Cuttlefish):
-------------------------------
GeneralStatus.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              File created with public member functions HDSFile (hds_new and
	      hds_open versions), ~HDSFile, annul( ), cell( ), copy( ),
	      copy2file( ), erase( ), file( ), find( ), index( ), mode( ),
	      move( ), ncomp( ), New( ), locator( ), save( ), slice( ),
              there( ), and top().
1998 Nov 23 - Nicholas Elias, USNO/NPOI
              Public member function list( ) added.
1998 Nov 29 - Nicholas Elias, USNO/NPOI
              Public member functions alter( ), clen( ), shape( ), and valid( )
	      added.
1998 Nov 30 - Nicholas Elias, USNO/NPOI
              Public member functions get( ), len( ), name( ), path( ), prec( ),
	      prim( ), put( ), renam( ), reset( ), retyp( ), size( ), state( ),
	      struc( ), and type( ) added.
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member functions HDSFile( ) (copy version) locatord( ),
              and locators( ) added.
1999 Jan 28 - Nicholas Elias, USNO/NPOI
              Public member function clone( ) added.
1999 Feb 11 - Nicholas Elias, USNO/NPOI
              Public member functions get( ) and put( ) eliminated.  Public
	      member functions create_byte( ), create_char( ), create_double( ),
	      create_integer( ), create_logical( ), create_real( ),
	      create_ubyte( ), create_uword( ), create_word( ), get_byte( ),
	      get_char( ), get_double( ), get_integer( ), get_logical( ),
	      get_real( ), get_ubyte( ), get_uword( ), get_word( ),
	      obtain_byte( ), obtain_char( ), obtain_double( ),
	      obtain_integer( ), obtain_logical( ), obtain_real( ),
	      obtain_ubyte( ), obtain_uword( ), obtain_word( ), put_byte( ),
	      put_char( ), put_double( ), put_integer( ), put_logical( ),
	      put_real( ), put_ubyte( ), put_uword( ), and put_word( ) added.
1999 Feb 14 - Nicholas Elias, USNO/NPOI
              Public member functions Goto( ), recover( ), and version( ) added.
2000 Aug 14 - Nicholas Elias, USNO/NPOI
              Public member functions screate_byte( ), screate_char( ),
              screate_double( ), screate_integer( ), screate_logical( ),
              screate_real( ), screate_ubyte( ), screate_uword( ), and
              screate_word( ) added.
2000 Aug 29 - Nicholas Elias, USNO/NPOI
              Static public member functions locatorMax( ), noLocator( ),
              sizeLocator( ), sizeMode( ), sizeName( ), and sizeType( ) added.
2000 Aug 31 - Nicholas Elias, USNO/NPOI
              Public member functions checkSlice( ) and numDim( ) added. 
              Static public member function dimMax( ) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/HDS/HDSFile.h> // HDS file

// -----------------------------------------------------------------------------

/*

HDSFile::className

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
1999 Feb 05 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

/*

HDSFile::runMethod

Description:
------------
This public member function provides the glish/aips++ interface for running the
methods of this class.

Inputs:
-------
uiMethod    - The method number.
oParameters - The method parameters.
bRunMethod  - The method run flag.

Outputs:
--------
The method result, returned via the function value.

Modification history:
---------------------
1999 Feb 05 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

MethodResult HDSFile::runMethod3( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {

  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {

    // slice
    case 76: {
      Parameter< Vector<Int> > dims1( oParameters, "dims1", ParameterSet::In );
      Parameter< Vector<Int> > dims2( oParameters, "dims2", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          slice( HDSDim( dims1() ), HDSDim( dims2() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "slice( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // state
    case 77: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = state();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "state( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // struc
    case 78: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = struc();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "struc( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // there
    case 79: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = there( HDSName( name2() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // top
    case 80: {
      if ( bRunMethod ) {
        try {
          top();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "top( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // type
    case 81: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = String( (const String) HDSType( type() ) );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "HDSType{ } error\n" + oAipsError.getMesg(), "HDSFile",
	     "runMethod" ) );
	}
      }
      break;
    }

    // valid
    case 82: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = valid();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "valid() error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // version
    case 83: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = version();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "version( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // checkSlice
    case 84: {
      Parameter< Vector<Int> > dims1( oParameters, "dims1", ParameterSet::In );
      Parameter< Vector<Int> > dims2( oParameters, "dims2", ParameterSet::In );
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = checkSlice( HDSDim( dims1() ), HDSDim( dims2() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "checkSlice( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
        }
      }
      break;
    }
    
    // checkSameSlice
    case 85: {
      Parameter< Vector<Int> > dims1( oParameters, "dims1", ParameterSet::In );
      Parameter< Vector<Int> > dims2( oParameters, "dims2", ParameterSet::In );
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = checkSameSlice( HDSDim( dims1() ), HDSDim( dims2() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "checkSameSlice( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
        }
      }
      break;
    }

    // dimMax
    case 86: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) dimMax();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "dimMax( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
        }
      }
      break;
    }

    // locatorMax
    case 87: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) locatorMax();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "locatorMax( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
        }
      }
      break;
    }

    // noLocator
    case 88: {
      Parameter<String>
          returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = noLocator();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "noLocator( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
        }
      }
      break;
    }

    // sizeLocator
    case 89: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) sizeLocator();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "sizeLocator( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
        }
      }
      break;
    }

    // sizeMode
    case 90: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) sizeMode();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "sizeMode( ) error\n" + oAipsError.getMesg(), "HDSFile",
              "runMethod" ) );
        }
      }
      break;
    }

    // sizeName
    case 91: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) sizeName();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "sizeName( ) error\n" + oAipsError.getMesg(), "HDSFile",
              "runMethod" ) );
        }
      }
      break;
    }

    // sizeType
    case 92: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (Int) sizeType();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "sizeType( ) error\n" + oAipsError.getMesg(), "HDSFile",
              "runMethod" ) );
        }
      }
      break;
    }

    // default
    default: {
      if ( bRunMethod ) {
        throw( ermsg( "Invalid HDSFile{ } method\n", "HDSFile", "runMethod" ) );
      }
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}
