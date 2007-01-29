//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1999
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
//# $Id: ObjectDispatcher.h,v 19.6 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_OBJECTDISPATCHER_H
#define TASKING_OBJECTDISPATCHER_H


//# Includes
#include <casa/aips.h>
#include <casa/Containers/Block.h>
#include <casa/Containers/SimOrdMap.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>
#include <casa/Utilities/CountedPtr.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations
class ApplicationObject;
class ParameterSet;
class MethodResult;
class GlishRecord;

// <summary>
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

class ObjectDispatcher
{
public:
    ObjectDispatcher(ApplicationObject *&fromNew);
    ~ObjectDispatcher();

    MethodResult runMethod(const String &method, 
			   GlishRecord *&parametersFromNew,
			   CountedPtr<GlishRecord> &returnedParameters);

    ApplicationObject *object();
    // Return the list of methods
    Vector<String> methods();
private:
    ApplicationObject       *object_p;
    SimpleOrderedMap<String, Int>  method_lookup_p;
    // True if we are to trace (parameters, timing info) the given method.
    Block<Bool> tracers_p;

    // These constructors/assignment cannot be used.
    // <group>
    ObjectDispatcher();
    ObjectDispatcher(const ObjectDispatcher &other);
    ObjectDispatcher &operator=(const ObjectDispatcher &other);
    // </group>
};

inline ApplicationObject *ObjectDispatcher::object()
{
    return object_p;
}


} //# NAMESPACE CASA - END

#endif
