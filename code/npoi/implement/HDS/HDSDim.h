//# HDSDim.h is part of Cuttlefish (NPOI data reduction package)
//# Copyright (C) 1999,2000
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
//# $Id: HDSDim.h,v 19.3 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

HDSDim.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the include information for the HDSDim.cc file.

Modification history:
---------------------
1998 Nov 20 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_HDSDIM_H
#define NPOI_HDSDIM_H


// Includes

#include <casa/aips.h>              // aips++
#include <casa/Arrays/Vector.h>     // aips++ Vector class

extern "C" {
  #include <dat_par.h>              // HDS data parameters
}

#include <npoi/HDS/GeneralStatus.h> // General status

#include <casa/namespace.h>
// <summary>A class for representing the dimension numbers of an HDS object</summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos=""></reviewed>

// <prerequisite>
// </prerequisite>

// <synopsis>
// This simple class inherits the Vector<Int> class and is used to represent
// the dimension numbers of an HDS object.  It makes sure that the dimension
// numbers are correct and allocates the correct amount of memory for the
// dimension array.
// </synopsis>

// <example>
// <src>HDSDim.cc</src>
// <srcblock>{}</srcblock>
// </example>

// Class definition

class HDSDim : public GeneralStatus, public Vector<Int> {

  public:

    // Constructor using up to 7 dimension numbers.  For example, if uiDim1 !=
    // 0 and the rest 0, the object will have one dimension number.
    HDSDim( const uInt uiDim1 = 0, const uInt uiDim2 = 0, const uInt uiDim3 = 0,
        const uInt uiDim4 = 0, const uInt uiDim5 = 0, const uInt uiDim6 = 0,
        const uInt uiDim7 = 0 );

    // Same as the previous constructor, except that the dimension numbers are
    // in an array.
    HDSDim( const uInt uiNumDimIn, const uInt* const auiDimIn );
    
    // Same as the previous constructors, except that the dimension numbers are
    // in a Vector<Int> object.
    HDSDim( const Vector<Int>& oVector );
    
    // Copy constructor.
    HDSDim( const HDSDim& oDimIn );

    // Destructor.
    ~HDSDim( void );

    // Compares the present HDS dimension numbers (low) with other HDS
    // dimension numbers (high).  If correct, returns True, otherwise False.
    // Useful for slicing operations in HDSFile.
    Bool check( const HDSDim& oDimHighIn ) const;
    
    // Returns the pointer to the HDS dimension array.  Neither the value or
    // the address may be modified.
    const Int* const ppdim( void ) const;
    
    // Changes the number of HDS dimensions.  If the new number of HDS
    // dimensions is larger than before, the new dimensions are undefined.
    void resize( const uInt uiNumDimIn, Bool bCopy = False );

    // The maximum number of dimensions (7, from FORTRAN limitations).
    static const uInt MXDIM = DAT__MXDIM;

  private:

    Bool bDelete;
    Int* piDim;

};


// #endif (Include file?)

#endif // __HDSDIM_H

