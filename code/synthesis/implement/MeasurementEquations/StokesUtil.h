//# StokesUtil.h:
//# Copyright (C) 1996,1999,2001
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This library is free software; you can redistribute it and/or modify it
//# under the terms of the GNU Library General Public License as published by
//# the Free Software Foundation; either version 2 of the License, or (at your
//# option) any later version.
//#
//# This library is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library General Public
//# License for more details.
//#
//# You should have received a copy of the GNU Library General Public License
//# along with this library; if not, write to the Free Software Foundation,
//# Inc., 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: StokesUtil.h,v 19.6 2005/06/18 21:19:17 ddebonis Exp $

#ifndef SYNTHESIS_STOKESUTIL_H
#define SYNTHESIS_STOKESUTIL_H


#include <casa/aips.h>
#include <casa/Arrays/Array.h>
#include <msvis/MSVis/StokesVector.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// for use with StokesVectors and related classes
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite> <li> StokesVector </prerequisite>
//
// <synopsis>
// Global Functions to operate on StokesVectors. Currently this includes
// functions to convert arrays from/to arrays of StokesVectors and some
// miscellaneous mathematical operations. 

// The {un,re}packStokes functions convert between an Array of StokesVector
// or CStokesvector into an Array of Float/Double or Complex/DComplex. The
// Float/Double array has one more dimension than the corresponding
// StokesVector array, and this extra dimension (always the slowest moving
// or last one) has a length of 4. The output array is always resized to the
// appropriate size.

// The StokesVector comparison functions use the the "length" of the
// StokesVector (ie. sqrt(I^2+Q^2+U^2+V^2)) to make a comparison. In
// particular the abs() function returns the "length" of the
// StokesVector. It is called abs rather than say length() to allow
// StokesVectors to utilise other globals functions (like allNearAbs())
// which expect the absolute value function to be defined.

// </synopsis>
//
// <motivation>
// g++ does not like templated and non-templated code in the same file. So
// the templated stuff was split off and put into this file. Later this
// became a convient place to put all the global functions, and the
// non-templated global functions are also defined here (and the
// implementation is put in a separate .cc file)
// </motivation>
//
//
// <thrown>
//    <li> repackStokes()::AipsError
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> I am uncertain how efficient any of these functions are.
// </todo>

// <linkfrom anchor="StokesVector ancillary functions" classes="StokesVector CStokesVector">
//   <here>StokesVector ancillary functions</here> -- Ancillary functions
//   used to manipulate StokesVector and related classes
// </linkfrom>


// <group name="StokesVector ancillary Functions">
// <group>
// Convert an Array of StokesVectors to an array of Floats or Doubles
// (depending on the templates). The same function can be used to convert an
// array of CStokesVectors to a Complex or DComplex  Array. I have not
// tested if this works for other template types.
template<class T, class U> void 
unpackStokes(Array<U>& output, const Array<T>& input);

// Convert an Array of Floats or Doubles to an Array of StokesVectors. The
// same function can be used to convert a Complex/DComplex array to an array
// of CStokesVector. The last non-degenerate axis on the input array MUST be
// of length 4
template<class T, class U> void 
repackStokes(Array<U>& output, const Array<T>& input);
// </group>

// These Functions to multiply a StokesVector by an Array of Floats. The
// result is an Array of StokesVectors that is the same size as the Array of
// Floats with each polarization being the Array of floats multiplied by the
// corresponding component in the supplied StokesVector.  
// <group>
Array<StokesVector> operator* (const Array<Float> & farray, 
			       const StokesVector & sv);
inline Array<StokesVector> operator* (const StokesVector & sv,
			       const Array<Float> & farray){
  return farray*sv;
}
// </group>

// Functions to compare stokesVectors with each other. They are all based on
// the norm derived using the "length" of the vector in 4-space.
// <group>
inline Float abs(const StokesVector& sv){
  return sqrt(innerProduct(sv,sv));
}

Bool operator>(const StokesVector& left,const StokesVector& right); 

inline Bool operator<(const StokesVector& left, const StokesVector& right){
  return !(left>right);
}

// </group>

// Functions to determine if  one StokesVector is near another
// <group>
Bool nearAbs(const StokesVector& val1, const StokesVector& val2, 
	      Double tol = 1.0e-5);

Bool near(const StokesVector& val1, const StokesVector& val2, 
	  Double tol = 1.0e-5);
// </group>


// </group>

} //# NAMESPACE CASA - END

#ifndef AIPS_NO_TEMPLATE_SRC
#include <synthesis/MeasurementEquations/StokesUtil.cc>
#endif //# AIPS_NO_TEMPLATE_SRC
#endif
