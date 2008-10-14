//# HDSDim.cc is part of Cuttlefish (NPOI data reduction package)
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
//# $Id: HDSDim.cc,v 19.0 2003/07/16 06:03:06 aips2adm Exp $
// -----------------------------------------------------------------------------

/*

HDSDim.cc

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++/Cuttlefish

Description:
------------
This file contains the HDSDim{ } class member functions.

Public member functions:
------------------------
HDSDim (3 versions), ~HDSDim, check, ppdim, resize.

Inherited classes (aips++):
---------------------------
Vector<Int>.

Inherited classes (Cuttlefish):
-------------------------------
GeneralStatus.

Modification history:
---------------------
1998 Nov 20 - Nicholas Elias, USNO/NPOI
              File created with public member functions HDSDim( ) (2 versions),
	      ~HDSDim( ), check( ), and ppdim( ).
1998 Dec 03 - Nicholas Elias, USNO/NPOI
              Public member function resize( ) added.
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member function HDSDim( ) (copy version) added.

*/

// -----------------------------------------------------------------------------

// Includes

#include <npoi/HDS/HDSDim.h> // HDS dimension

// -----------------------------------------------------------------------------

/*

HDSDim::HDSDim (all dimensions, specified individually)

Description:
------------
This public member function constructs the HDSDim{ } object.

Inputs:
-------
uiDim1 - The first dimension (default = 0).
uiDim2 - The second dimension (default = 0).
uiDim3 - The third dimension (default = 0).
uiDim4 - The fourth dimension (default = 0).
uiDim5 - The fifth dimension (default = 0).
uiDim6 - The sixth dimension (default = 0).
uiDim7 - The seventh dimension (default = 0).

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSDim::HDSDim( const uInt uiDim1, const uInt uiDim2, const uInt uiDim3,
    const uInt uiDim4, const uInt uiDim5, const uInt uiDim6, const uInt uiDim7 )
    : GeneralStatus(), bDelete( False ) {

  // Declare the local variables

  uInt uiDim;         // The HDS dimension counter
  uInt uiNumDim;      // The HDS number of dimensions
  
  uInt auiDim[MXDIM]; // The HDS dimensions
  
  
  // Check MXDIM
  
  if ( MXDIM != 7 ) {
    throw( ermsg( "MXDIM is no longer 7", "HDSDim", "HDSDim" ) );
  }


  // Determine the HDS number of dimensions and load the HDS dimension array
  
  uiNumDim = 0;
  
  if ( uiDim1 > 0 ) {
    uiNumDim += 1;
    if ( uiDim2 > 0 ) {
      uiNumDim += 1;
      if ( uiDim3 > 0 ) {
        uiNumDim += 1;
	if ( uiDim4 > 0 ) {
	  uiNumDim += 1;
	  if ( uiDim5 > 0 ) {
	    uiNumDim += 1;
	    if ( uiDim6 > 0 ) {
	      uiNumDim += 1;
	      if ( uiDim7 > 0 ) {
	        uiNumDim += 1;
              }
	    }
	  }
	}
      }
    }
  }
  
  auiDim[0] = uiDim1;
  auiDim[1] = uiDim2;
  auiDim[2] = uiDim3;
  auiDim[3] = uiDim4;
  auiDim[4] = uiDim5;
  auiDim[5] = uiDim6;
  auiDim[6] = uiDim7;
  

  // Set the HDS dimensions

  Vector<Int>::resize( uiNumDim, False );

  for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
    (*this)(uiDim) = auiDim[uiDim];
  }

  piDim = getStorage( bDelete );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSDim::HDSDim (all dimensions, specified via array)

Description:
------------
This public member function constructs the HDSDim{ } object.

Inputs:
-------
uiNumDimIn - The number of HDS dimensions.
auiDimIn   - The HDS dimensions.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSDim::HDSDim( const uInt uiNumDimIn, const uInt* const auiDimIn )
    : GeneralStatus(), bDelete( False ) {

  // Declare the local variables

  uInt uiDim; // The HDS dimension counter


  // Check the inputs

  if ( uiNumDimIn < 0 || uiNumDimIn > MXDIM ) {
    throw( ermsg( "Invalid number of HDS dimensions", "HDSDim",
        "HDSDim" ) );
  }

  for ( uiDim = 0; uiDim < uiNumDimIn; uiDim++ ) {
    if ( auiDimIn[uiDim] < 1 ) {
      throw( ermsg( "Invalid HDS dimension(s)", "HDSDim", "HDSDim" ) );
    }
  }


  // Set the HDS dimensions

  Vector<Int>::resize( uiNumDimIn, False );

  for ( uiDim = 0; uiDim < uiNumDimIn; uiDim++ ) {
    (*this)(uiDim) = auiDimIn[uiDim];
  }

  piDim = getStorage( bDelete );


  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSDim::HDSDim (Vector<Int>)

Description:
------------
This public member function constructs the HDSDim{ } object.

Inputs:
-------
oVector - The Vector<Int> object.

Outputs:
--------
None.

Modification history:
---------------------
1999 Jan 29 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSDim::HDSDim( const Vector<Int>& oVector ) : GeneralStatus(),
    bDelete( False ) {

  // Declare the local variables

  uInt uiDim;    // The HDS dimension counter
  uInt uiNumDim; // The HDS number of dimensions


  // Check the inputs

  if ( oVector.nelements() < 0 || oVector.nelements() > MXDIM ) {
    throw( ermsg( "Invalid number of HDS dimensions", "HDSDim",
        "HDSDim" ) );
  }

  for ( uiDim = 1; uiDim < oVector.nelements(); uiDim++ ) {
    if ( oVector(uiDim) < 1 ) {
      throw( ermsg( "Invalid HDS dimension(s)", "HDSDim", "HDSDim" ) );
    }
  }


  // Initialize the HDSDim{ } object

  if ( oVector.nelements() > 0 ) {
    if ( oVector(0) > 0 ) {
      uiNumDim = oVector.nelements();
    } else {
      uiNumDim = 0;
    }
  } else {
    uiNumDim = 0;
  }

  Vector<Int>::resize( uiNumDim, False );

  for ( uiDim = 0; uiDim < uiNumDim; uiDim++ ) {
    (*this)(uiDim) = oVector(uiDim);
  }

  piDim = getStorage( bDelete );
  

  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSDim::HDSDim (copy)

Description:
------------
This public member function copies the object.

Inputs:
-------
oDimIn - The HDSDim{ } object.

Outputs:
--------
None.

Modification history:
---------------------
1999 Jan 13 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSDim::HDSDim( const HDSDim& oDimIn ) : GeneralStatus(), bDelete( False ) {

  // Declare the local variables

  uInt uiDim; // The HDS dimension counter


  // Initialize the HDSDim{ } object

  Vector<Int>::resize( oDimIn.nelements(), False );

  for ( uiDim = 0; uiDim < oDimIn.nelements(); uiDim++ ) {
    (*this)(uiDim) = oDimIn(uiDim);
  }

  piDim = getStorage( bDelete );
  

  // Return

  return;

}

// -----------------------------------------------------------------------------

/*

HDSDim::~HDSDim

Description:
------------
This public member function destructs the HDSDim{ } object.

Inputs:
-------
None.

Outputs:
--------
None.

Modification history:
---------------------
1998 Nov 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

HDSDim::~HDSDim( void ) {

  // Delete the HDS dimension copy, if it exists

  if ( bDelete ) {
    putStorage( piDim, bDelete );
  }

}

// -----------------------------------------------------------------------------

/*

HDSDim::check

Description:
------------
This public member function checks the dimensions of this HDSDim{ } object (low)
and the dimensions of another HDSDim{ } object (high).

Inputs:
-------
oDimHighIn - The other HDSDim{ } object (high).

Outputs:
--------
True or False, returned via the function value.

Modification history:
---------------------
1998 Nov 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

Bool HDSDim::check( const HDSDim& oDimHighIn ) const {

  // Declare the local variables

  uInt uiDim; // The HDS dimension counter


  // Check the HDSDim{ } objects

  if ( nelements() != oDimHighIn.nelements() ) {
    return( False );
  }

  for ( uiDim = 0; uiDim < nelements(); uiDim++ ) {
    if ( (*this)(uiDim) > oDimHighIn(uiDim) ) {
      return( False );
    }
  }


  // Return True

  return( True );

}

// -----------------------------------------------------------------------------

/*

HDSDim::ppdim

Description:
------------
This public member function returns the HDS dimension pointer (cannot be
changed).

Inputs:
-------
None.

Outputs:
--------
The HDS dimension pointer, returned via the function value.

Modification history:
---------------------
1998 Nov 20 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

const Int* const HDSDim::ppdim( void ) const {

  // Return the HDS dimension pointer

  return( (const Int* const) piDim );

}

// -----------------------------------------------------------------------------

/*

HDSDim::resize

Description:
------------
This public member function changes the number of HDS dimensions after checking
the inputs, i.e., this public member function acts as an invisible front end for
Vector<Int>::resize().

Inputs:
-------
uiNumDimIn - The number of HDS dimensions.
bCopy      - The copy flag

Outputs:
--------
None.

Modification history:
---------------------
1998 Dec 03 - Nicholas Elias, USNO/NPOI
              Public member function created.

*/

// -----------------------------------------------------------------------------

void HDSDim::resize( const uInt uiNumDimIn, Bool bCopy ) {

  // Check the inputs
  
  if ( uiNumDimIn < 0 || uiNumDimIn > MXDIM ) {
    throw( ermsg( "Invalid number of HDS dimensions", "HDSDim",
        "resize" ) );
  }
  

  // Change the number of HDS dimensions

  Vector<Int>::resize( uiNumDimIn, bCopy );

  if ( bDelete ) {
    putStorage( piDim, bDelete );
  }

  piDim = getStorage( bDelete );
  
  
  // Return
  
  return;
  
}
