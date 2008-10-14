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
//# $Id: HDSFile3.cc,v 19.0 2003/07/16 06:03:18 aips2adm Exp $
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

MethodResult HDSFile::runMethod2( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {

    // put_byte
    case 51: {
      Parameter< Array<Int> > data( oParameters, "data", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          put_byte( data() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "put_byte() error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
	}
      }
      break;
    }
    
    // put_char
    case 52: {
      Parameter< Array<String> > data( oParameters, "data", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          put_char( data() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "put_char() error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
	}
      }
      break;
    }
    
    // put_double
    case 53: {
      Parameter< Array<Double> > data( oParameters, "data", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          put_double( data() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "put_double() error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // put_integer
    case 54: {
      Parameter< Array<Int> > data( oParameters, "data", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          put_integer( data() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "put_integer() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // put_logical
    case 55: {
      Parameter< Array<Bool> > data( oParameters, "data", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          put_logical( data() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "put_logical() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // put_real
    case 56: {
      Parameter< Array<Float> > data( oParameters, "data", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          put_real( data() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "put_real() error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
	}
      }
      break;
    }
    
    // put_ubyte
    case 57: {
      Parameter< Array<Int> > data( oParameters, "data", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          put_ubyte( data() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "put_ubyte() error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
	}
      }
      break;
    }
    
    // put_uword
    case 58: {
      Parameter< Array<Int> > data( oParameters, "data", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          put_uword( data() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "put_uword() error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
	}
      }
      break;
    }
    
    // put_word
    case 59: {
      Parameter< Array<Int> > data( oParameters, "data", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          put_word( data() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "put_word() error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
	}
      }
      break;
    }

    // recover
    case 60: {
      if ( bRunMethod ) {
        try {
          recover();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "recover( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // renam
    case 61: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          renam( HDSName( name2() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "renam( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // reset
    case 62: {
      if ( bRunMethod ) {
        try {
          reset();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "reset( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // retyp
    case 63: {
      Parameter<String> type2( oParameters, "type", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          retyp( HDSType( type2() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "retyp( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // save
    case 64: {
      if ( bRunMethod ) {
        try {
          save( );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "save( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // screate_byte
    case 65: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<Int> datum( oParameters, "datum", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          screate_byte( HDSName( name2() ), datum(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "screate_byte() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // screate_char
    case 66: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<Int> length( oParameters, "length", ParameterSet::In );
      Parameter<String> datum( oParameters, "datum", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          screate_char( HDSName( name2() ), (uInt) length(), datum(),
              replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "screate_char() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // screate_double
    case 67: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<Double> datum( oParameters, "datum", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          screate_double( HDSName( name2() ), datum(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "screate_double() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // screate_integer
    case 68: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<Int> datum( oParameters, "datum", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          screate_integer( HDSName( name2() ), datum(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "screate_integer() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // screate_logical
    case 69: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<Bool> datum( oParameters, "datum", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          screate_logical( HDSName( name2() ), datum(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "screate_logical() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // screate_real
    case 70: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<Float> datum( oParameters, "datum", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          screate_real( HDSName( name2() ), datum(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "screate_real() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // screate_ubyte
    case 71: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<Int> datum( oParameters, "datum", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          screate_ubyte( HDSName( name2() ), datum(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "screate_ubyte() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // screate_uword
    case 72: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<Int> datum( oParameters, "datum", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          screate_uword( HDSName( name2() ), datum(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "screate_uword() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // screate_word
    case 73: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<Int> datum( oParameters, "datum", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          screate_word( HDSName( name2() ), datum(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "screate_word() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }

    // shape
    case 74: {
      Parameter< Vector<Int> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
	  if ( numDim() > 0 ) {
	    returnval() = (Vector<Int>) HDSDim( shape() );
	  } else {
	    returnval() = Vector<Int>( 1, 0 );
	  }
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "HDSDim{ } error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
	}
      }
      break;
    }

    // size
    case 75: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (uInt) size();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "size( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // default
    default: {
      return runMethod3( uiMethod, oParameters, bRunMethod );
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}
