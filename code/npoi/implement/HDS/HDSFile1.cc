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
//# $Id: HDSFile1.cc,v 19.0 2003/07/16 06:03:17 aips2adm Exp $
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

MethodResult HDSFile::runMethod( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {

    // alter
    case 0: {
      Parameter<Int> lastdim( oParameters, "lastdim", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          alter( lastdim() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "alter( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // annul
    case 1: {
      Parameter<Int> locatorannul( oParameters, "locatorannul",
          ParameterSet::In );
      if ( bRunMethod ) {
        try {
          annul( (uInt) locatorannul() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "annul( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // cell
    case 2: {
      Parameter< Vector<Int> > dims( oParameters, "dims", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          cell( HDSDim( dims() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "cell( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // clen
    case 3: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (uInt) clen();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "clen( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // copy
    case 4: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<ObjectID> otherid( oParameters, "otherid", ParameterSet::In );
      if ( bRunMethod ) {
	ObjectController* poObjectController = NULL;
 	ApplicationObject* poApplicationObject = NULL;
        try {
	  poObjectController = ApplicationEnvironment::objectController();
	  poApplicationObject =
	      poObjectController->getObject( (const ObjectID&) otherid() );
          copy( HDSName( name2() ), (HDSFile*) poApplicationObject );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "copy( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // copy2file
    case 5: {
      Parameter<String> file2( oParameters, "file", ParameterSet::In );
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          copy2file( HDSAccess( file2(), "NEW" ), HDSName( name2() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "there( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // create_byte
    case 6: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Int> > data( oParameters, "data", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          create_byte( HDSName( name2() ), data(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "create_byte() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // create_char
    case 7: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<Int> length( oParameters, "length", ParameterSet::In );
      Parameter< Array<String> > data( oParameters, "data", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          create_char( HDSName( name2() ), (uInt) length(), data(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "create_char() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // create_double
    case 8: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Double> > data( oParameters, "data", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          create_double( HDSName( name2() ), data(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "create_double() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // create_integer
    case 9: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Int> > data( oParameters, "data", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          create_integer( HDSName( name2() ), data(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "create_integer() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // create_logical
    case 10: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Bool> > data( oParameters, "data", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          create_logical( HDSName( name2() ), data(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "create_logical() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // create_real
    case 11: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Float> > data( oParameters, "data", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          create_real( HDSName( name2() ), data(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "create_real() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // create_ubyte
    case 12: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Int> > data( oParameters, "data", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          create_ubyte( HDSName( name2() ), data(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "create_ubyte() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // create_uword
    case 13: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Int> > data( oParameters, "data", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          create_uword( HDSName( name2() ), data(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "create_uword() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // create_word
    case 14: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Int> > data( oParameters, "data", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          create_word( HDSName( name2() ), data(), replace() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "create_word() error\n" + oAipsError.getMesg(),
	      "HDSFile", "runMethod" ) );
	}
      }
      break;
    }

    // erase
    case 15: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          erase( HDSName( name2() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "erase( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }
  
    // file
    case 16: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = file();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "file( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // find
    case 17: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          find( HDSName( name2() ) );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "find( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // get_byte
    case 18: {
      Parameter< Array<Int> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = get_byte();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "get_byte( ) error\n" + oAipsError.getMesg(), "HDSFile",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // get_char
    case 19: {
      Parameter< Array<String> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = get_char();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "get_char( ) error\n" + oAipsError.getMesg(), "HDSFile",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // get_double
    case 20: {
      Parameter< Array<Double> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = get_double();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "get_double( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
        }
      }
      break;
    }
    
    // get_integer
    case 21: {
      Parameter< Array<Int> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = get_integer();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "get_integer( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
        }
      }
      break;
    }
    
    // get_logical
    case 22: {
      Parameter< Array<Bool> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = get_logical();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "get_logical( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
        }
      }
      break;
    }
    
    // get_real
    case 23: {
      Parameter< Array<Float> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = get_real();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "get_real( ) error\n" + oAipsError.getMesg(), "HDSFile",
              "runMethod" ) );
        }
      }
      break;
    }
    
    // get_ubyte
    case 24: {
      Parameter< Array<Int> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = get_ubyte();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "get_ubyte( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
        }
      }
      break;
    }
    
    // get_uword
    case 25: {
      Parameter< Array<Int> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = get_uword();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "get_uword( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
        }
      }
      break;
    }
    
    // default
    default: {
      return runMethod1( uiMethod, oParameters, bRunMethod );
    }

  }
  
  
  // Return ok( )
  
  return( ok() );

}
