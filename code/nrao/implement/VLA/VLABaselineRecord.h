//# VLABaselineRecord: 
//# Copyright (C) 1999
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
//# $Id: VLABaselineRecord.h,v 19.4 2004/11/30 17:50:42 ddebonis Exp $

#ifndef NRAO_VLABASELINERECORD_H
#define NRAO_VLABASELINERECORD_H

#include <casa/aips.h>
#include <casa/IO/ByteSource.h>
//# The following should be a forward declaration. But our Complex & DComplex
//# classes are a typedef hence this does not work. Replace the following with
//# forward declarations when Complex and DComplex are no longer typedefs.
#include <casa/BasicSL/Complex.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class String;
template <class T> class Vector;
template <class T> class Array;
} //# NAMESPACE CASA - END


// <summary></summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
//   <li> SomeOtherClass
//   <li> some concept
// </prerequisite>
//
// <etymology>
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <templating arg=T>
//    <li>
//    <li>
// </templating>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> add this feature
//   <li> fix this bug
//   <li> start discussion of this possible extension
// </todo>

class VLABaselineRecord
{
public:
   // The shapes of all the components
  enum Type {
    // A simple point component
    CONTINUUM = 0,
    // A elliptical Gaussian component
    SPECTRALLINE,
    // An unknown Component
    UNKNOWN_TYPE,
    // The number of types in this enumerator
    NUMBER_TYPES
  };

  // A virtual destructor is needed to ensure that the destructor of derived
  // classes is actually used.
  virtual ~VLABaselineRecord();

  // returns the correlations for this baseline. The returned Vector contains
  // all the data for this baseline and has been scaled.
  virtual Vector<Complex> data() const;

  // Returns the correlations for this baseline in the supplied Array. The
  // supplied Array may have any number of dimensions, but all except one must
  // have a length on 1. The axis that is not of length one must be the right
  // length to hold all the data contained in the record.  Alternatively the
  // Array may contain no elements in which case it will be resized to a Vector
  // of the correct length. The returned values have been scaled.
  virtual void data(Array<Complex>& values) const = 0;

  // returns the flags for the correlations for this baseline.
  virtual Vector<Bool> flags() const = 0;

  // returns the scaling factor used to convert the internal data to the actual
  // values.
  virtual uInt scale() const = 0;

  // returns the antenna 1 index for this baseline.
  virtual uInt ant1() const = 0;

  // returns the antenna 2 index for this baseline.
  virtual uInt ant2() const = 0;
  
  // return the type of this class
  virtual VLABaselineRecord::Type type() const = 0;

  // Convert a Type enum into a String
  static String name(VLABaselineRecord::Type typeEnum);

  // Convert a given String to a Type enumerator
  static VLABaselineRecord::Type type(const String& typeName);

protected:
  //# The default constructor creates a unusable object. Use the attach
  //function to turn an object constructed this way into a usable object.
  VLABaselineRecord();

  //# Initialise this VLABaselineRecord from the given record with the
  //# specified offset.
  VLABaselineRecord(ByteSource& record, uInt offset);
  
  //# Initialise this VLABaselineRecord from the given record with the
  //# specified offset.
  void attach(ByteSource& record, uInt offset);

  //# reads the scaling factor given the offset from the start of the record
  uInt scale(uInt headerOffset) const;

  //# returns the antenna 1 index for this baseline given the offset in bytes
  //# from the start of the record.
  uInt ant1(uInt headerOffset) const;

  //# returns the antenna 2 index for this baseline given the offset in bytes
  //# from the start of the record.
  uInt ant2(uInt headerOffset) const;
  
  //# Contains a VLA record
  mutable ByteSource itsRecord;

  //# the offset to the start of the data for this object in the VLA record.
  uInt itsOffset;
private:
  //# The copy constructor is private and undefined
  VLABaselineRecord(const VLABaselineRecord& other);

  //# The assignment operator is private and undefined.
  VLABaselineRecord& operator=(const VLABaselineRecord& other);
};
#endif


