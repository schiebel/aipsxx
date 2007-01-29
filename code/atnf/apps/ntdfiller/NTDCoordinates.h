// NTDCoordinates.h: implementation of a MeasurementSet's filler
//
//  Copyright (C) 2005, 2006
//# Associated Universities, Inc. Washington DC, USA.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
//
//
//////////////////////////////////////////////////////////////////////
#if !defined(ATNF_NTDCOORDINATES_H)
#define ATNF_NTDCOORDINATES_H
//# Includes

#include <casa/aips.h>
#include <casa/Utilities/Assert.h>

#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayUtil.h>

#include <measures/Measures/MPosition.h>
#include <measures/Measures/MBaseline.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/Muvw.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MeasTable.h>
#include <measures/Measures/Stokes.h>
#include <measures/Measures/MeasConvert.h>
#include <casa/BasicSL/Constants.h>
#include <complex>

#include <vector>

using namespace casa;
using namespace std;

//# Forward Declarations

// Class NTDCoordinates
class NTDCoordinates
{
 public:
  NTDCoordinates ();
  
  // Destructor
  ~NTDCoordinates();

  Muvw calcUVW(MEpoch& epoch, MDirection& source);
  MDirection calcAzEl(MEpoch& epoch, MDirection& source);

  MPosition getEast();
  MPosition getWest();

private:
  MPosition itsWestPos, itsEastPos;
  MVPosition itsWestVPos, itsEastVPos;
  MVBaseline itsVBaseline;
};
#endif
  
