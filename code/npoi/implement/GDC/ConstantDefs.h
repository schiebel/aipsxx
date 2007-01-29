//#ConstantsDef.h is part of the GDC server
//#Copyright (C) 2000
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
//#Correspondence concerning the GDC server should be addressed as follows:
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
//# $Id: ConstantDefs.h,v 19.3 2004/11/30 17:50:40 ddebonis Exp $
// -----------------------------------------------------------------------------

/*

ConstantDefs.h

USNO/NRL Optical Interferometer
United States Naval Observatory
3450 Massachusetts Avenue, NW
Washington, DC  20392-5420

Package:
--------
aips++

Description:
------------
This file contains the constant definitions.

Modification history:
---------------------
1999 Mar 26 - Nicholas Elias, USNO/NPOI
              File created.

*/

// -----------------------------------------------------------------------------

// #ifndef (Include file?)

#ifndef NPOI_CONSTANTDEFS_H
#define NPOI_CONSTANTDEFS_H


// Includes

#include <casa/aips.h> // aips++


#include <casa/namespace.h>
// Class definition

class ConstantDefs {

  public:
  
    static const Double E = 2.7182818284590451;
  
    static const Double HALF_PI = 1.5707963267948966;
    static const Double PI = 3.1415926535897932;
    static const Double THREEHALF_PI = 4.7123889803846897;
    static const Double TWO_PI = 6.2831853071795862;

};


// #endif (Include file?)

#endif // __CONSTANTDEFS_H
