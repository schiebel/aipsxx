//# ArrayUtil.cc: Utility functions for arrays (non-templated)
//# Copyright (C) 1995,1999,2001
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
//# $Id: ArrayUtil2.cc,v 19.3 2004/11/30 17:50:13 ddebonis Exp $

#include <casa/Arrays/ArrayUtil.h>
#include <casa/Utilities/Regex.h>


namespace casa { //# NAMESPACE CASA - BEGIN

Vector<String> stringToVector (const String& string, char delim)
{
    if (string.empty()) {
	return Vector<String>(0);
    }
    String str(string);
    uInt nr = str.freq (delim);
    Vector<String> vec(nr+1);
    uInt st = 0;
    nr = 0;
    uInt i;
    for (i=0; i<str.length(); i++) {
	if (str[i] == delim) {
	    vec(nr++) = str(st,i-st);
	    st = i+1;
	}
    }
    vec(nr++) = str(st,i-st);
    return vec;
}

Vector<String> stringToVector (const String& string, const Regex& delim)
{
    Vector<String> vec;
    uInt nr = 0;
    const char* s = string.chars();
    Int sl = string.length();
    if (sl == 0) {
        return vec;
    }
    Int pos = 0;
    Int matchlen;
    Int p = delim.search (s, sl, matchlen, pos);
    while (p >= 0) {
        if (nr >= vec.nelements()) {
	    vec.resize (nr+64, True);
	}
	vec(nr++) = String (s+pos, p - pos);
	pos = p + matchlen;
	p = delim.search (s, sl, matchlen, pos);
    }
    vec.resize (nr+1, True);
    vec(nr) = String (s+pos, sl - pos);
    return vec;
}


uInt reorderArrayHelper (IPosition& newShape, IPosition& incr,
			 const IPosition& shape, const IPosition& newAxisOrder)
{
  uInt ndim = shape.nelements();
  // Get the remaining axes forming mapping of new to old axes.
  // It also checks if axes are specified correctly.
  IPosition toOld = IPosition::makeAxisPath (ndim, newAxisOrder);
  // Create the mapping from old to new axes.
  // Create the new shape and the volume for each dimension.
  // Check if axes are really reordered.
  IPosition toNew(ndim);
  newShape.resize (ndim);
  IPosition volume(ndim+1, 1);
  uInt contAxes = ndim;
  for (uInt i=0; i<ndim; i++) {
    uInt oldAxis = toOld(i);
    toNew(oldAxis) = i;
    newShape(i) = shape(oldAxis);
    volume(i+1) = volume(i) * newShape(i);
    if (contAxes == ndim  &&  oldAxis != i) {
      contAxes = i;
    }
  }
  // Create an array which determines how to increment in the result
  // when incrementing an axis of the input array.
  incr.resize (ndim);
  // The increment in the first dimension is the volume of the axes
  // that get in front of the originally first axis.
  incr(0) = volume(toNew(0));
  // The increment in the other axes is the difference between the
  // last item in the previous dimension and the first one in the next.
  for (uInt i=1; i<ndim; i++) {
    uInt prevAxis = toNew(i-1);
    uInt newAxis = toNew(i);
    incr(i) = volume(newAxis) - volume(prevAxis+1);
  }
  return contAxes;
}

} //# NAMESPACE CASA - END

