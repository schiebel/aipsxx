//# HDSLocator.h is part of Cuttlefish (NPOI data reduction package)
//# Copyright (C) 1999
//# United States Naval Observatory; Washington, DC; USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is designed for use only in AIPS++ (National Radio Astronomy
//# Observatory; Charlottesville, VA; USA) in the hope that it will be useful,
//# but WITHOUT ANY WARRANTY; without even the implied warranty of
//# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//# See the GNU Library General Public License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning Cuttlefish should be addressed as follows:
//#        Internet email: nme@nofs.navy.mil
//#        Postal address: Dr. Nicholas Elias
//#                        United States Naval Observatory
//#                        Navy Prototype Optical Interferometer
//#                        P.O. Box 1149
//#                        Flagstaff, AZ 86002-1149 USA
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: HDSLocator.h,v 19.4 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

HDSLocator.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the include information for the HDSLocator.cc file.

Modification history:
---------------------
1998 Nov 06 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_HDSLOCATOR_H
#define NPOI_HDSLOCATOR_H


// Includes

#include <string.h>                // String

#include <casa/aips.h>             // aips++
#include <casa/Containers/Block.h> // aips++ Block class
#include <casa/Exceptions/Error.h> // aips++ Error classes
#include <casa/BasicSL/String.h> // aips++ String class

#include <npoi/HDS/HDSWrapper.h>   // HDS wrapper
#include <npoi/HDS/HDSDim.h>       // HDS dimension
#include <npoi/HDS/HDSName.h>      // HDS name
#include <npoi/HDS/HDSStatus.h>    // HDS status
#include <npoi/HDS/HDSType.h>      // HDS type

#include <casa/namespace.h>
// <summary>A class for representing an HDS locator</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// This simple class inherits the Block<Char> class and is used to represent an
// HDS locator.  When the locator actually points to part or all of an HDS
// object, it can then be manipulated.
// </synopsis>

// <example>
// <src>HDSLocator.cc</src>
// <srcblock>{}</srcblock>
// </example>

// Class definition

class HDSLocator : public HDSStatus {

  public:

    // Standard constructor.
    HDSLocator( void );
    
    // Copy constructor.
    HDSLocator( const HDSLocator& oLocatorIn );

    // Destructor.
    ~HDSLocator( void );
    
    // Alter the last dimension of a non-scalar HDS object.
    void alter( const uInt uiLastDim );
    
    // Returns the number of characters need to represent an HDS primitive
    // object.
    const uInt clen( void );
    
    // Get data from part or all of the present HDS object.  The pointer may be
    // cast to another variable of the proper type.  For two+ dimensional
    // arrays, the data are stored in FORTRAN order.
    void get( uChar* (*aucData) );
    
    // Return the length, in bytes, of a single element in the present HDS
    // object.
    const uInt len( void );
    
    // Return the name of the present HDS object.
    const HDSName name( void );
    
    // Return the fully resolved path.
    const String path( void );
    
    // Return a pointer to the HDS locator.  It's value may be changed, but not
    // it's address.
    Char* const ploc( void );
    
    // Return a pointer to the HDS locator.  Neither it's value or address may
    // be changed.
    const Char* const pploc( void ) const;
    
    // Return the precision of the present HDS object.
    const uInt prec( void );
    
    // If the present HDS object is a primitive, return True, otherwise False.
    Bool prim( void );
    
    // Put data into part or all of the present HDS object.  The data array
    // must be cast to a uChar* pointer.  For two+ dimensional data arrays, the
    // data must be stored in FORTRAN order.
    void put( const uChar* const aucData );
    
    // If an HDS error occurs, reset the locator to NOLOC.
    void recover( void );
    
    // Rename the present HDS object.
    void renam( const HDSName& oNameIn );
    
    // Reset present HDS primitive object (return to uninitialized state).
    void reset( void );
    
    // Change the type of the present HDS object.
    void retyp( const HDSType& oTypeIn );
    
    // Return the shape (dimensions) of the present HDS object.
    const HDSDim shape( void );
    
    // Return the size (number of elements) of the present HDS object.
    const uInt size( void );
    
    // If the present HDS object is initialized, return True, otherwise False.
    Bool state( void );
    
    // If the present HDS object is a structure, return True, otherwise False.
    Bool struc( void );
    
    // Return the type of the present HDS object.
    const HDSType type( void );
    
    // If the present HDS locator is valid, return True, otherwise False.
    Bool valid( void );
    
    // The overloaded = operator.
    void operator=( const HDSLocator& oLocatorIn );

    static const Char* const NOLOC = DAT__NOLOC;
    static const uInt SZLOC = DAT__SZLOC;

  private:

    static const uInt NUM_CHAR_MAX = 1000;

    Block<Char>* poLocator;

};


// #endif (Include file?)

#endif // __HDSLOCATOR_H
