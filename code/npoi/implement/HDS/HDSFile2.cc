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
//# $Id: HDSFile2.cc,v 19.0 2003/07/16 06:03:18 aips2adm Exp $
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

MethodResult HDSFile::runMethod1( uInt uiMethod, ParameterSet &oParameters,
    Bool bRunMethod ) {
  
  // Parse the method parameters and run the desired method
  
  switch ( uiMethod ) {

    // get_word
    case 26: {
      Parameter< Array<Int> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = get_word();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "get_word( ) error\n" + oAipsError.getMesg(), "HDSFile",
              "runMethod" ) );
        }
      }
      break;
    }

    // Goto
    case 27: {
      Parameter<String> path2( oParameters, "path", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          Goto( path2() );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "Goto( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
	}
      }
      break;
    }
    
    // id    
    case 28: {
      Parameter<ObjectID> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
	  returnval() = id();
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "id( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
	}
      }
      break;
    }

    // index
    case 29: {
      Parameter<Int> index2( oParameters, "index", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          index( index2() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "index( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // len
    case 30: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (uInt) len();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "len( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // locator
    case 31: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (uInt) locator();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "locator( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // list
    case 32: {
      Parameter< Vector<String> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = list();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "list( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }
 
    // mode
    case 33: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = mode();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "mode( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // move
    case 34: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<ObjectID> otherid( oParameters, "otherid", ParameterSet::In );
      if ( bRunMethod ) {
	ObjectController* poObjectController = NULL;
 	ApplicationObject* poApplicationObject = NULL;
        try {
	  poObjectController = ApplicationEnvironment::objectController();
	  poApplicationObject =
	      poObjectController->getObject( (const ObjectID&) otherid() );
          move( HDSName( name2() ), (HDSFile*) poApplicationObject );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "move( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // name
    case 35: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = String( (const String) HDSName( name() ) );
	}
	catch ( AipsError oAipsError ) {
	  throw( ermsg( "HDSName{ } error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
	}
      }
      break;
    }

    // ncomp
    case 36: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (uInt) ncomp();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "ncomp( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // New
    case 37: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter<String> type2( oParameters, "type", ParameterSet::In );
      Parameter< Vector<Int> > dims( oParameters, "dims", ParameterSet::In );
      Parameter<Bool> replace( oParameters, "replace", ParameterSet::In );
      if ( bRunMethod ) {
        try {
          New( HDSName( name2() ), HDSType( type2() ), HDSDim( dims() ),
              replace() );
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "New( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // numDim
    case 38: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (uInt) numDim();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "numDim( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }
    
    // obtain_byte
    case 39: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Int> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obtain_byte( HDSName( name2() ) );
        }
	catch ( AipsError oAipsError ) {
          throw( ermsg( "obtain_byte( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // obtain_char
    case 40: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<String> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obtain_char( HDSName( name2() ) );
        }
	catch ( AipsError oAipsError ) {
          throw( ermsg( "obtain_char( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // obtain_double
    case 41: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Double> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obtain_double( HDSName( name2() ) );
        }
	catch ( AipsError oAipsError ) {
          throw( ermsg( "obtain_double( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // obtain_integer
    case 42: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Int> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obtain_integer( HDSName( name2() ) );
        }
	catch ( AipsError oAipsError ) {
          throw( ermsg( "obtain_integer( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // obtain_logical
    case 43: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Bool> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obtain_logical( HDSName( name2() ) );
        }
	catch ( AipsError oAipsError ) {
          throw( ermsg( "obtain_logical( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // obtain_real
    case 44: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Float> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obtain_real( HDSName( name2() ) );
        }
	catch ( AipsError oAipsError ) {
          throw( ermsg( "obtain_real( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // obtain_ubyte
    case 45: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Int> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obtain_ubyte( HDSName( name2() ) );
        }
	catch ( AipsError oAipsError ) {
          throw( ermsg( "obtain_ubyte( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // obtain_uword
    case 46: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Int> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obtain_uword( HDSName( name2() ) );
        }
	catch ( AipsError oAipsError ) {
          throw( ermsg( "obtain_uword( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
	}
      }
      break;
    }
    
    // obtain_word
    case 47: {
      Parameter<String> name2( oParameters, "name", ParameterSet::In );
      Parameter< Array<Int> > returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = obtain_word( HDSName( name2() ) );
        }
	catch ( AipsError oAipsError ) {
          throw( ermsg( "obtain_word( ) error\n" + oAipsError.getMesg(),
              "HDSFile", "runMethod" ) );
	}
      }
      break;
    }

    // path
    case 48: {
      Parameter<String> returnval( oParameters, "returnval",
          ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = path();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "path( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // prec
    case 49: {
      Parameter<Int> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = (uInt) prec();
        }
        catch ( AipsError oAipsError ) {
          throw( ermsg( "prec( ) error\n" + oAipsError.getMesg(), "HDSFile",
	      "runMethod" ) );
        }
      }
      break;
    }

    // prim
    case 50: {
      Parameter<Bool> returnval( oParameters, "returnval", ParameterSet::Out );
      if ( bRunMethod ) {
        try {
          returnval() = prim();
        }
        catch ( AipsError ) {
          throw( ermsg( "prim( ) error\n", "HDSFile", "runMethod" ) );
        }
      }
      break;
    }
    
    // default
    default: {
      return runMethod2( uiMethod, oParameters, bRunMethod );
    }
    
  }
  
  
  // Return ok( )
  
  return( ok() );

}
