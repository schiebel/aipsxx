//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1998,1999,2000,2001
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
//# $Id: ObjectType.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ObjectType.h>
#include <casa/Arrays/Slice.h>


namespace casa { //# NAMESPACE CASA - BEGIN

ObjectType::ObjectType() : type_hierarchy_p(0)
{
}

ObjectType::ObjectType(const String &typeName) : type_hierarchy_p(1)
{
    type_hierarchy_p(0) = typeName;
}

ObjectType::ObjectType(const ObjectType &other) 
  : type_hierarchy_p(other.type_hierarchy_p.copy())
{
}

ObjectType::ObjectType(const Vector<String> &typeNames)
  : type_hierarchy_p(typeNames.copy())
{
    // Nothing
}

ObjectType &ObjectType::operator=(const ObjectType &other)
{
    if (this != &other) {
        type_hierarchy_p.resize(other.type_hierarchy_p.nelements());
	type_hierarchy_p = other.type_hierarchy_p;
    }
    return *this;
}

ObjectType::~ObjectType()
{
    // Nothing
}

void ObjectType::addAncestor(const String &typeName)
{
    // Ancestors go at the END of the list
    Int old_size = type_hierarchy_p.nelements();
    Vector<String> old_hierarchy(type_hierarchy_p);
    type_hierarchy_p.resize(old_size + 1);
    type_hierarchy_p(Slice(0, old_size)) = old_hierarchy;
    type_hierarchy_p(old_size) = typeName;
}

void ObjectType::addChild(const String &typeName)
{
    // Children go at the FRONT of the list
    Int old_size = type_hierarchy_p.nelements();
    Vector<String> old_hierarchy(type_hierarchy_p);
    type_hierarchy_p.resize(old_size + 1);
    type_hierarchy_p(Slice(1, old_size)) = old_hierarchy;
    type_hierarchy_p(0) = typeName;
}

Bool ObjectType::isExactTypeOf(const ObjectType &other) const
{
    uInt n1 = type_hierarchy_p.nelements();
    uInt n2 = other.type_hierarchy_p.nelements();
    if (n1 == 0 || n2 == 0) {
        return (n1 == n2);
    } else {
        return (typeNames()(0) == other.typeNames()(0));
    }
}

Bool ObjectType::isA(const ObjectType &other) const
{
    // this "isA" other if other is a parent of this (or the same type)
    uInt n1 = type_hierarchy_p.nelements();
    uInt n2 = other.type_hierarchy_p.nelements();
    if (n1 == 0 || n2 == 0) {
        return (n1 == n2);
    } else {
        for (uInt i=0; i < n1; i++) {
	    if (typeNames()(i) == other.typeNames()(0)) {
	        return True;
	    }
	}
	return False;
    }
}

ostream &operator<<(ostream &os, const ObjectType &type)
{
    const Vector<String> &types = type.typeNames();
    uInt n = types.nelements();
    os << "type=";
    if (n == 0) {
        os << "null";
    } else {
        os << types(0);
    }
    if (n > 1) {
        os << " parents=";
	for (uInt i=1; i<n; i++) {
	    os << types(i) << " ";
	}
    }
    return os;
}

uInt hashFunc(const ObjectType &obj)
{
     const Vector<String> &names = obj.typeNames();
     uInt whichName = 0;
     uInt hash = 0;
     while (whichName < names.nelements()) {
         // Stolen from Hash(String)
         const char *ptr = names(whichName).chars();
 	while (*ptr) {
 	    hash = hash * 33 + *ptr++;
 	}
 	whichName++;
     }
     return hash;
}


    static ObjectType tmp;
const ObjectType &defaultHashValue(const ObjectType *ptr)
{
  if(!ptr) {};
  return tmp;
}

} //# NAMESPACE CASA - END

