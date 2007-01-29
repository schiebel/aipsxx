//# ObjectType.h: 
//# Copyright (C) 1996,1998,1999,2000,2001
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
//# $Id: ObjectType.h,v 19.5 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_OBJECTTYPE_H
#define TASKING_OBJECTTYPE_H

#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>
#include <casa/Containers/HashMap.h>


namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Base Class for Objects in Tasking interface
// </summary>

// <use visibility=local>   or   <use visibility=export>

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


class ObjectType
{
public:
    ObjectType();
    ObjectType(const String &typeName);
    ObjectType(const ObjectType &other);
    ObjectType(const Vector<String> &typeNames);
    ObjectType &operator=(const ObjectType &other);
    ~ObjectType();

    // We should check that the type doesn't already exist
    void addAncestor(const String &typeName);
    void addChild(const String &typeName);

    Bool isExactTypeOf(const ObjectType &other) const;
    Bool operator==(const ObjectType &other) const
      { return this->isExactTypeOf(other);} // !!!! Move out of class declaration
    Bool operator!=(const ObjectType &other) const
       { return (! this->isExactTypeOf(other));}
    Bool isA(const ObjectType &other) const;

    const Vector<String> &typeNames() const;
private:
    Vector<String> type_hierarchy_p;
};

const ObjectType &defaultHashValue(const ObjectType *);
uInt hashFunc(const ObjectType &);

ostream &operator<<(ostream &os, const ObjectType &type);

//-------------------------------------- Inlines

inline const Vector<String> &
ObjectType::typeNames() const {return type_hierarchy_p;}


} //# NAMESPACE CASA - END

#endif
