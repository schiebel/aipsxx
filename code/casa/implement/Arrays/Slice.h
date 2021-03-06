//# Slice.h: Define a (start,length,increment) along an axis
//# Copyright (C) 1993,1994,1995,1997
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
//# $Id: Slice.h,v 19.5 2004/11/30 17:50:14 ddebonis Exp $

#ifndef CASA_SLICE_H
#define CASA_SLICE_H

#include <casa/aips.h>

#if defined(AIPS_DEBUG)
#include <casa/Utilities/Assert.h>
#endif

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary> define a (start,length,increment) along an axis </summary>
// <reviewed reviewer="UNKNOWN" date="before2004/08/25" tests="" demos="">
// </reviewed>
//
// <synopsis>
// A "slice" (aka Section) is a a regular sub-Array (and ultimately sub-Image)
// that is defined by defining a (start,length,increment) for each axis in
// the array. That is, the output array's axis is of size "length", and the
// elements are sampled by stepping along the input array in strides of 
// "increment".
// <note role=warning> 
//   The "length" is the length of the OUTPUT array, the output length
//        is NOT divided by the increment/stride.
// </note>
// If increment is not defined, then it defaults to one. 
// (Increment, if defined, must be >= 1). If length
// is not defined, then it defaults to a length of one also (i.e. just the pixel
// "start"). If start is also undefined, then all pixels along this axis are
// chosen. This class deprecates the "_" (IndexRange) class, which had a failed
// syntax and used (start,end,increment) which is generally less convenient.
// Some simple examples follow:
// <srcblock> 
// Vector<Int> vi(100);          // Vector of length 100;
// //...
//                               // Copy odd values onto even values
// vi(Slice(0,50,2)) = vi(Slice(1,50,2));
// 
// Matrix<float> mf(100,50), smallMf;
// smallMf.reference(mf(Slice(0,10,10), Slice(0,5,10)));
//                               // smallMF is now a "dezoomed" (every 10th pix)
//                               // refference to mf. Of course we could also
//                               // make it a copy by using assignment; e.g:
//
// smallMf.resize(0,0);          // Make it so it will "size to fit"
// smallMf = mf(Slice(0,10,10), Slice(0,5,10));
// </srcblock> 
// As shown above, normally Slices will normally be used as temporaries,
// but they may also be put into variables if desired (the default
// copy constructors and assignment operators suffice for this class).
//
// While it will be unusual for a user to want this, a zero-length slice
// is allowable.
//
// Another way to produce a slice from any of the Array classes is to use
// SomeArray(blc,trc,inc) where blc,trc,inc are IPositions. This is described
// in the documentation for Array<T>.
// </synopsis>

class Slice
{
public:
    // The entire range of indices on the axis is desired.
    Slice();
    // Create a Slice with a given start, length, and increment. The latter
    // two default to one if not given.
    Slice(Int Start, uInt Length=1, uInt Inc=1);
    // Was the entire range of indices on this axis selected?
    Bool all() const;
    // Report the selected starting position. If all() is true,
    // start=len=inc=0 is set.
    Int start() const;
    // Report the defined length. If all() is true, start=len=inc=0 is set.
    uInt length() const;
    // Report the defined increment. If all() is true, start=len=inc=0 is set.
    uInt inc() const;
    // Attempt to report the last element of the slice. If all() is
    // True, end() returns -1 (which is less than start(), which returns
    // zero  in that case).
    Int end() const;
private:
    //# Inc of <0 is used as a private flag to mean that the whole axis is
    //# selected. Users are given a uInt in their interface, so they cannot
    //# set it to this. Chose Inc rather than length since it's more likely
    //# that we'd need all bits of length than of inc. The "p" in the names
    //# stands for private to avoid it colliding with the accessor names.
    //# incp < 0 is chosen as the flag since the user can set inc to be zero
    //# although that is an error that can be caught if AIPS_DEBUG is defined).
    Int startp, incp;
    uInt lengthp;
};

inline Slice::Slice() : startp(0), incp(-1), lengthp(0)
{
    // Nothing
}

inline
Slice::Slice(Int Start, uInt Length, uInt Inc) : startp(Start), incp(Inc), 
                                                 lengthp(Length)
{
#if defined(AIPS_DEBUG)
    DebugAssert(incp > 0, AipsError);
#endif
}

inline Bool Slice::all() const
{
    if (incp < 0) {
	return True;
    } else {
	return False;
    }
}

inline Int Slice::start() const
{
    return startp;
}

inline uInt Slice::length() const
{
    return lengthp;
}

inline uInt Slice::inc() const
{
    if (all()) {
	return 0;
    } else {
	return incp;
    }
}

inline Int Slice::end() const
{
    // return -1 if all()
    return startp + lengthp - 1;
}


} //# NAMESPACE CASA - END

#endif
