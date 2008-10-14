//# Index.h: Interconvert between 0 and 1 based relative indexing.
//# Copyright (C) 1996,1998
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
//# $Id: Index.h,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_INDEX_H
#define TASKING_INDEX_H

#include <casa/aips.h>
namespace casa { //# NAMESPACE CASA - BEGIN

template<class T> class Vector;
class IPosition;

// <summary>
// Interconvert between 0 and 1 based relative indexing.
// </summary>

// <use visibility=export>

// <reviewed reviewer="David Barnes" date="1998/12/01" tests="tIndex" demos="">
// </reviewed>

// <synopsis>
// This class is used to help reduce the chance of error when dealing with
// index values which are generated where indexing is 1-based (Glish), and
// used where indexing is 0-based (C++). Typical examples of such indices
// include:
// <ul>
//    <li> The position of a pixel in an image or an array (use 
//         <src>Vector<Index></src>).
//    <li> The row number of a table (use an Index scalar).
// </ul>
// In general, consistent use of Index for all such locations should greatly
// reduce the likelihood of off by one errors. The Index will generally appear
// as the argument to a member function which is available to the Glish user
// through the Tasking system, however it is not coupled to the Tasking system
// in any way.
//
// Of course you should only use Index for 0 or 1 relative locations. Actual
// "counts" should remain integers.
// </synopsis>
//
// <example>
// Suppose we want to work on a Table row which is specified by a user:
// <srcBlock>
//    void SomeClass::someFunc(Table &table, Index row)
//    {
//        ScalarColumn<Float> col(table, "col");
//        Float x = col(row()); // Index::operator() returns 0-relative value
//    }
// </srcBlock>
//
// Suppose we wanted to perform some operation on a subsection of an image 
// defined by a blc and trc which is to be specified by the user. We should
// code the function as follows:
// <srcBlock>
//    void SomeClass::someFunc(ImageInterface<Float> &inout,
//                             const Vector<Index> &blc,
//                             const Vector<Index> &trc)
// {
//    // Turn blc,trc into IPositions
//    IPosition iblc, itrc;
//    Index::convertIPosition(iblc, blc);
//    Index::convertIPosition(itrc, trc);
//    ... perform computation ...
// }
// </srcBlock>
// </example>
//
// <motivation>
// Encapsulate the indexing difference between Glish (1-based) and 
// C++ (0-based).
// </motivation>
//
// <todo asof="1998/10/30">
//   <li> Nothing known.
// </todo>

class Index
{
public:
  // Construct an index from a zero-relative value. The default is zero, i.e.
  // the first position of the container.
  // <group>
  Index(Int zeroRelValue=0) : local_value_p(zeroRelValue) {}
  Index(uInt zeroRelValue) : local_value_p(zeroRelValue) {}
  // </group>

  // Make a copy of other.
  // <group>
  Index(const Index &other) : local_value_p(other.local_value_p) {}
  Index &operator=(const Index &other) 
    {local_value_p=other.local_value_p; return *this;}
  // </group>

  //# No-op
  ~Index() {}

  // Return the local, i.e. zero-relative, value.
  // <group>
  Int operator()() const { return local_value_p; }
  Int zeroRelativeValue() const {return local_value_p;}
  // </group>

  // Return the canonical value, i.e. zeroRelativeValue()+1.
  Int oneRelativeValue() const {return local_value_p + 1;}

  // Interconvert between <src>Vector<Index></src> and IPosition as well as
  // <src>Vector<Index></src> and <src>Vector<Int></src>. If necessary, the
  // output values are resized. The default is that the
  // IPosition/<src>Vector<Int></src> values are in local (0-relative) format,
  // however this may be changed. Generally this default will only be changed
  // by the Tasking system itself.  
  // <group>
  static void convertVector(Vector<Int> &out, const Vector<Index> &in, 
		   Bool outValuesAreLocal=True);
  static void convertVector(Vector<Index> &out, const Vector<Int> &in,
		     Bool inValuesAreLocal=True);
  static void convertIPosition(IPosition &out, const Vector<Index> &in, 
		   Bool outValuesAreLocal=True);
  static void convertIPosition(Vector<Index> &out, const IPosition &in,
		     Bool inValuesAreLocal=True);
  // </group>
private:
    // Zero-relative value
    Int local_value_p;
};


} //# NAMESPACE CASA - END

#endif
