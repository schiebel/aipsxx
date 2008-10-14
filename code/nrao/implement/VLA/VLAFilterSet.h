//# VLAFilterSet.h: 
//# Copyright (C) 1999,2000
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
//# $Id: VLAFilterSet.h,v 19.3 2004/11/30 17:50:43 ddebonis Exp $

#ifndef NRAO_VLAFILTERSET_H
#define NRAO_VLAFILTERSET_H

#include <casa/aips.h>
#include <casa/Containers/Block.h>

#include <casa/namespace.h>
class VLALogicalRecord;
class VLAFilter;

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

class VLAFilterSet
{
public:
  // The default constructor creates a filter set that does not contan any
  // filters. Using the passThru function without any filters always returns
  // True;
  VLAFilterSet();
  
  // The copy constructor uses copy semantics.
  VLAFilterSet(const VLAFilterSet& other);
  
  // The destructor is trivial
  virtual ~VLAFilterSet();
  
  // The assignment operator uses copy semantics.
  VLAFilterSet& operator=(const VLAFilterSet& other);
  
  // Adds the specified filter to the set.
  void addFilter(const VLAFilter& filter);
  
  // Adds the specified filter from the set. Throws an exception if which is
  // not less than the value returned by nelements().
  void removeFilter(const uInt which);

  // Returns the number of filters in the set.
  uInt nelements() const;

  // Returns a reference to the specified filter
  const VLAFilter& filter(const uInt which) const;

  // returns True if the supplied record meets the filter criteria for all the
  // filters that are contained within in this filter set. Also returns True if
  // there are no filters in the set.
  virtual Bool passThru(const VLALogicalRecord& record) const;
  
  // Function which checks the internal data of this class for correct
  // dimensionality and consistant values. Returns True if everything is fine
  // otherwise returns False.
  virtual Bool ok() const;
  
private:
  //# deletes all the filters in the current filter set.
  void deleteAllFilters();
  //# copies all the filters from the specified set to the current one.
  void copyFilters(const VLAFilterSet& other);

  PtrBlock<VLAFilter*> itsFilters;
};

inline uInt VLAFilterSet::nelements() const {
  return itsFilters.nelements();
}

#endif
