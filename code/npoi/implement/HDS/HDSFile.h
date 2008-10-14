//#HDSFile.h is part of Cuttlefish (NPOI data reduction package)
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
//# $Id: HDSFile.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

HDSFile.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the include information for the HDSFile.cc file.

Modification history:
---------------------
1998 Nov 18 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_HDSFILE_H
#define NPOI_HDSFILE_H


// Includes

extern "C" {
  #include <sys/file.h>                           // File lock
  #include <sys/stat.h>                           // File statistics
  #include <limits.h>                             // Machine limits
  #include <stdio.h>                              // Standard I/O
  #include <stdlib.h>                             // Standard library
  #include <string.h>                             // String
  #include <unistd.h>                             // Universal standard
}

#include <casa/aips.h>                            // aips++
#include <tasking/Tasking/ApplicationEnvironment.h> // aips++ App...Env... class
#include <tasking/Tasking/ApplicationObject.h>      // aips++ App...Object class
#include <casa/Arrays/Array.h>                    // aips++ Array class
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

#include <npoi/HDS/HDSWrapper.h>                  // HDS wrapper
#include <npoi/HDS/HDSAccess.h>                   // HDS access
#include <npoi/HDS/HDSDim.h>                      // HDS dimension
#include <npoi/HDS/HDSName.h>                     // HDS name
#include <npoi/HDS/HDSType.h>                     // HDS type
#include <npoi/HDS/HDSLocator.h>                  // HDS locator

#include <casa/namespace.h>
// <summary>A class for manipulating an ensemble of locators in an HDS file</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// HDS (Hierarchical Database System) is a library of FORTRAN functions used to
// manipulate files in HDS binary format.  The library is available free of
// charge from <A href=http://star-www.rl.ac.uk/>Starlink</A>.

// An HDS file consists of a hierarchy of <B>objects</B>, each with an
// associated <B>locator</B>.  Each object has a <B>name</B>, up to 15
// characters in length. 
// There are two classes of objects, <B>structures</B> and <B>primitives</B>.
// A structure points to a lower-level object and a primitive points to data,
// analogous to a file system and files.

// Each object has a <B>type</B>.  Primitive types must be one of the
// following:
// <UL>
// <LI><B>_UBYTE</B>   - unsigned byte.</LI>
// <LI><B>_BYTE</B>    - signed byte.</LI>
// <LI><B>_UWORD</B>   - unsigned word.</LI>
// <LI><B>_WORD</B>    - signed word.</LI>
// <LI><B>_INTEGER</B> - signed integer.</LI>
// <LI><B>_REAL</B>    - single precision.</LI>
// <LI><B>_DOUBLE</B>  - double precision.</LI>
// <LI><B>_LOGICAL</B> - logical/boolean.</LI>
// <LI><B>_CHAR*N</B>  - character string, where N=integer.</LI>
// </UL>
// <B>The initial underscore is NOT optional for primitive types.</B> Structure
// types can be anything up to 15 characters in length, but in most cases they
// are just '' (null strings).  HDS itself does not treat non-null structure
// types differently than null structures, but software using the HDS library
// may do so.

// Objects are also assigned a <B>shape</B>, or dimensionality.  A scalar
// object has a shape of 0.  The HDS library is written in FORTRAN 77, so the
// maximum number of dimensions is 7, e.g., [4,5,2,6,4,3,2].

// When an HDS tool is created, it starts at the top-level locator.  The user
// may proceed up and down the hierarchy (along structure objects), with
// locators being pushed on (popped off) a FILO stack.  When a primitive object
// is reached, it is not possible to go down the hierarchy any further at that
// point.  At any structure object, new objects may be created beneath it.
// Objects may also be erased, modified in shape, modified in content
// (for primitives), etc.
// </synopsis>

// <example>
// <src>HDSFile.cc</src>
// <srcblock>{}</srcblock>
// </example>

// <todo asof="yyyy/mm/dd">
// <LI> Uncomment flock() code (doesn't work for RedHat 5.x), so HDS files may
// be locked when opened.</LI>
// </todo>

// Class definition

class HDSFile : public GeneralStatus, public ApplicationObject {

  public:

    // Maximum size of an HDS path.
    static const uInt SZPATH = 1000;

    // Create a new HDS file.
    HDSFile( const HDSAccess& oAccessIn, const HDSName& HDSNameIn,
        const HDSType& oTypeIn, const HDSDim& oDimIn );

    // Open an existing HDS file for reading/updating.
    HDSFile( const HDSAccess& oAccessIn );
    
    // Copy constructor.
    HDSFile( const HDSFile& oFileIn );
  
    // Destructor.
    ~HDSFile( void );
    
    // Alter the last dimension of a non-scalar HDS object.
    void alter( const uInt& uiLastDim );
    
    // Annul the locator of the present HDS object.
    void annul( const uInt& uiNumLocatorAnnul = 1 );
    
    // Go to a cell of an HDS object.  A locator for this cell is pushed on the
    // FILO stack.  All subsequent commands reflect the cell, until the locator
    // is popped off the FILO stack.
    void cell( const HDSDim& oDimIn );
    
    // Returns the number of characters need to represent an HDS primitive
    // object.
    uInt clen( void ) const;
    
    // Clone the present HDS locator.
    HDSLocator clone( void ) const;
    
    // Recursively copy the present HDS object to a saved object.  The saved
    // object may be in the same file or another file.
    void copy( const HDSName& oNameIn, HDSFile* poFile = NULL );
    
    // Recursively copy the present HDS object to a new file.
    void copy2file( const HDSAccess& oAccessIn, const HDSName& oNameIn );
    
    // New, find, put, annul combination for _BYTE objects.
    void create_byte( const HDSName& oNameIn, const Array<Int>& oArray,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for _CHAR*N objects.
    void create_char( const HDSName& oNameIn, const uInt& uiLength,
        const Array<String>& oArray, const Bool& bReplace = False );
	
    // New, find, put, annul combination for _DOUBLE objects.
    void create_double( const HDSName& oNameIn, const Array<Double>& oArray,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for _INTEGER objects.
    void create_integer( const HDSName& oNameIn, const Array<Int>& oArray,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for _LOGICAL objects.
    void create_logical( const HDSName& oNameIn, const Array<Bool>& oArray,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for _REAL objects.
    void create_real( const HDSName& oNameIn, const Array<Float>& oArray,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for _UBYTE objects.
    void create_ubyte( const HDSName& oNameIn, const Array<Int>& oArray,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for _UWORD objects.
    void create_uword( const HDSName& oNameIn, const Array<Int>& oArray,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for _WORD objects.
    void create_word( const HDSName& oNameIn, const Array<Int>& oArray,
        const Bool& bReplace = False );
	
    // Erase an HDS object below the present object.
    void erase( const HDSName& oNameIn );
    
    // Return the file name.
    String file( void ) const;
    
    // Go to an HDS object beneath the present one.
    void find( const HDSName& oNameIn );
    
    // Get _BYTE data from part or all of the present HDS object.
    Array<Int> get_byte() const;
    
    // Get _CHAR*N data from part or all of the present HDS object.
    Array<String> get_char() const;
    
    // Get _DOUBLE data from part or all of the present HDS object.
    Array<Double> get_double() const;
    
    // Get _INTEGER data from part or all of the present HDS object.
    Array<Int> get_integer() const;
    
    // Get _LOGICAL data from part or all of the present HDS object.
    Array<Bool> get_logical() const;
    
    // Get _REAL data from part or all of the present HDS object.
    Array<Float> get_real() const;
    
    // Get _UBYTE data from part or all of the present HDS object.
    Array<Int> get_ubyte() const;
    
    // Get _UWORD data from part or all of the present HDS object.
    Array<Int> get_uword() const;
    
    // Get _WORD data from part or all of the present HDS object.
    Array<Int> get_word() const;
    
    // Go to an HDS object, using the fully resolved HDS path.
    void Goto( const String& oPathIn );
    
    // Go to an HDS object beneath the present one using its index number.
    void index( const uInt& uiIndex );
    
    // Return the length, in bytes, of a single element in the present HDS
    // object.
    uInt len( void ) const;
    
    // Return the list of HDS objects beneath the present one (order consistent
    // with indexing).
    Vector<String> list( void );
    
    // Return the number of HDS locators in the FILO stack.
    uInt locator( void ) const;
    
    // Return the present locator.
    HDSLocator locatord( const uInt& uiLocatorIn ) const;
    
    // Return the saved locator.
    HDSLocator locators( void ) const;
    
    // Return the access mode.
    String mode( void ) const;
    
    // Recursively move the present HDS object to a saved object.  The saved
    // object may be in the same file or another file.
    void move( const HDSName& oNameIn, HDSFile* poFile = NULL );
    
    // Return the name of the present HDS object.
    HDSName name( void ) const;
    
    // Return the number of HDS objects beneath the present one.
    uInt ncomp( void );
    
    // Create a new HDS object beneath the present one.  No data is put into
    // the object, and the locator is not pushed on the FILO stack.
    void New( const HDSName& oNameIn, const HDSType& oTypeIn,
        const HDSDim& oDimIn, const Bool& bReplace = False );
    
    // Return the number of dimensions.
    uInt numDim( void ) const;
    
    // Find, get, annul combination for _BYTE objects.
    Array<Int> obtain_byte( const HDSName& oNameIn );
    
    // Find, get, annul combination for _CHAR*N objects.
    Array<String> obtain_char( const HDSName& oNameIn );
    
    // Find, get, annul combination for _DOUBLE objects.
    Array<Double> obtain_double( const HDSName& oNameIn );
    
    // Find, get, annul combination for _INTEGER objects.
    Array<Int> obtain_integer( const HDSName& oNameIn );
    
    // Find, get, annul combination for _LOGICAL objects.
    Array<Bool> obtain_logical( const HDSName& oNameIn );
    
    // Find, get, annul combination for _REAL objects.
    Array<Float> obtain_real( const HDSName& oNameIn );
    
    // Find, get, annul combination for _UBYTE objects.
    Array<Int> obtain_ubyte( const HDSName& oNameIn );
    
    // Find, get, annul combination for _UWORD objects.
    Array<Int> obtain_uword( const HDSName& oNameIn );
    
    // Find, get, annul combination for _WORD objects.
    Array<Int> obtain_word( const HDSName& oNameIn );
    
    // Return the fully resolved path.
    String path( void ) const;
    
    // Return the precision of the present HDS object.
    uInt prec( void ) const;
    
    // If the present HDS object is a primitive, return True, otherwise False.
    Bool prim( void ) const;
    
    // Put _BYTE data into part or all of the present HDS object.
    void put_byte( const Array<Int>& oArray ) const;
    
    // Put _CHAR*N data into part or all of the present HDS object.
    void put_char( const Array<String>& oArray ) const;
    
    // Put _DOUBLE data into part or all of the present HDS object.
    void put_double( const Array<Double>& oArray ) const;
    
    // Put _INTEGER data into part or all of the present HDS object.
    void put_integer( const Array<Int>& oArray ) const;
    
    // Put _LOGICAL data into part or all of the present HDS object.
    void put_logical( const Array<Bool>& oArray ) const;
    
    // Put _REAL data into part or all of the present HDS object.
    void put_real( const Array<Float>& oArray ) const;
    
    // Put _UBYTE data into part or all of the present HDS object.
    void put_ubyte( const Array<Int>& oArray ) const;
    
    // Put _UWORD data into part or all of the present HDS object.
    void put_uword( const Array<Int>& oArray ) const;
    
    // Put _WORD data into part or all of the present HDS object.
    void put_word( const Array<Int>& oArray ) const;
    
    // If an HDS error occurs, pop HDS locators off the FILO stack until a
    // valid one is reached.
    void recover( void );
    
    // Rename the present HDS object.
    void renam( const HDSName& oNameIn ) const;
    
    // Reset present HDS primitive object (return to uninitialized state).
    void reset( void ) const;
    
    // Change the type of the present HDS object.
    void retyp( const HDSType& oTypeIn ) const;
    
    // Save the present HDS locator (used in conjunction with copy and move).
    void save( void );
    
    // New, find, put, annul combination for scalar _BYTE objects.
    void screate_byte( const HDSName& oNameIn, const Int& iDatum,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for scalar _CHAR*N objects.
    void screate_char( const HDSName& oNameIn, const uInt& uiLength,
        const String& oDatum, const Bool& bReplace = False );
	
    // New, find, put, annul combination for scalar _DOUBLE objects.
    void screate_double( const HDSName& oNameIn, const Double& dDatum,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for scalar _INTEGER objects.
    void screate_integer( const HDSName& oNameIn, const Int& iDatum,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for scalar _LOGICAL objects.
    void screate_logical( const HDSName& oNameIn, const Bool& bDatum,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for scalar _REAL objects.
    void screate_real( const HDSName& oNameIn, const Float& fDatum,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for scalar _UBYTE objects.
    void screate_ubyte( const HDSName& oNameIn, const Int& iDatum,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for scalar _UWORD objects.
    void screate_uword( const HDSName& oNameIn, const Int& iDatum,
        const Bool& bReplace = False );
	
    // New, find, put, annul combination for scalar _WORD objects.
    void screate_word( const HDSName& oNameIn, const Int& iDatum,
        const Bool& bReplace = False );

    // Return the shape (dimensions) of the present HDS object.
    HDSDim shape( void ) const;
    
    // Return the size (number of elements) of the present HDS object.
    uInt size( void ) const;
    
    // Go to a slice of an HDS object.  A locator for this slice is pushed on
    // the FILO stack.  All subsequent commands reflect the slice, until the
    // locator is popped off the FILO stack.
    void slice( const HDSDim& oDimLowIn, const HDSDim& oDimHighIn );
    
    // If the present HDS object is initialized, return True, otherwise False.
    Bool state( void ) const;
    
    // If the present HDS object is a structure, return True, otherwise False.
    Bool struc( void ) const;
    
    // If an HDS object exists beneath the present HDS object, return True,
    // otherwise False.
    Bool there( const HDSName& oNameIn );
    
    // Pop all HDS locators off the FILO stack except the top one.
    void top( void );
    
    // Return the type of the present HDS object.
    HDSType type( void ) const;
    
    // If the present HDS locator is valid, return True, otherwise False.
    Bool valid( void ) const;
    
    // Return the version number of the HDS server.
    String version( void ) const;
    
    // Check an HDS object slice.
    Bool checkSlice( const HDSDim& oSliceLow, const HDSDim& oSliceHigh ) const;
    
    // Check if an input HDS object slice is the same as the present slice.
    Bool checkSameSlice( const HDSDim& oSliceLow,
        const HDSDim& oSliceHigh ) const;
    
    // Return the maximum number of dimensions.
    static uInt dimMax( void );
    
    // Return the maximum number of locators.
    static uInt locatorMax( void );
        
    // Return the no-locator string.
    static String noLocator( void );
    
    // Return the locator size.
    static uInt sizeLocator( void );
    
    // Return the mode size.
    static uInt sizeMode( void );
    
    // Return the name size.
    static uInt sizeName( void );
    
    // Return the type size.
    static uInt sizeType( void );

    // The overloaded = operator.
    void operator=( const HDSFile& oFileIn );

    // Return the class name.
    virtual String className( void ) const;
    
    // Return the list of HDSFile methods.
    virtual Vector<String> methods( void ) const;
    
    // Return the list of HDSFile methods where no trace is printed.
    virtual Vector<String> noTraceMethods( void ) const;
    
    // The HDS server uses this method to pass arguments to HDSFile methods and
    // run them.
    virtual MethodResult runMethod( uInt uiMethod, ParameterSet& oParameters,
        Bool bRunMethod );

  private:

    MethodResult runMethod1( uInt uiMethod, ParameterSet& oParameters,
        Bool bRunMethod );
    MethodResult runMethod2( uInt uiMethod, ParameterSet& oParameters,
        Bool bRunMethod );
    MethodResult runMethod3( uInt uiMethod, ParameterSet& oParameters,
        Bool bRunMethod );

    static const uInt OK = HDSStatus::OK;

    static const uInt NUM_LOCATOR_MAX = 20;
    static const Char* const NOLOC = HDSLocator::NOLOC;
    static const uInt SZLOC = HDSLocator::SZLOC;
  
    uInt uiLocator;

    HDSAccess* poAccess;

    HDSLocator* poLocatorSave;
    HDSLocator* aoLocator;

};


// #endif (Include file?)

#endif // __HDSFILE_H
