//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,2000
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
//# $Id: ApplicationObject.h,v 19.6 2005/06/18 21:19:18 ddebonis Exp $

#ifndef TASKING_APPLICATIONOBJECT_H
#define TASKING_APPLICATIONOBJECT_H

#include <casa/aips.h>
#include <casa/System/ObjectID.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class MethodResult;
class ParameterSet;
class String;
template<class T> class Vector;

// <summary>
// Encapsulates an AIPS++ Application. DOs are derived from ApplicationObject
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

class ApplicationObject
{
public:
    virtual ~ApplicationObject();
    // Handled by this base class
    const ObjectID &id() const;

    // Convenient ways to generate a return.
    static MethodResult ok();
    static MethodResult error(const String &message);
    
    // Must be filled in by the end user class.
    virtual String className() const = 0;
    virtual Vector<String> methods() const = 0;

    // By default, parameters in and out of a method, and CPU times taken
    // by the method are automatically logged. This is not appropriate for
    // small methods that do not do very much. Return the names of methods
    // you do not want traced from this function. The default is to trace
    // all methods.
    virtual Vector<String> noTraceMethods() const;

    virtual MethodResult runMethod(uInt which, 
				   ParameterSet &inputRecord,
				   Bool runMethod) = 0;
protected:
    ApplicationObject();
    ApplicationObject(const ApplicationObject &other);
    ApplicationObject &operator=(const ApplicationObject &other);
private:
    ObjectID id_p;
};


// <summary>
// A factory for making ApplicationObjects.
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

class ApplicationObjectFactory
{
public:
    virtual ~ApplicationObjectFactory();
    // Do it - normally just calls "new MyActualType" if MyActualType has a
    // default ctor.
    virtual MethodResult make(ApplicationObject *&newObject,
			      const String &whichConstructor,
			      ParameterSet &inputRecord,
			      Bool runConstructor) = 0;
};

// <summary>
// The standard factory for making ApplicationObjects.
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

template<class AppType> class StandardObjectFactory : 
    public ApplicationObjectFactory
{
public:
    virtual MethodResult make(ApplicationObject *&newObject,
			      const String &whichConstructor,
			      ParameterSet &inputRecord,
			      Bool runConstructor);
};

//# Inlines ------------------------------------------------------------

inline const ObjectID &ApplicationObject::id() const
{
    return id_p;
}


} //# NAMESPACE CASA - END

#ifndef AIPS_NO_TEMPLATE_SRC
#include <tasking/Tasking/ApplicationObject.cc>
#endif //# AIPS_NO_TEMPLATE_SRC
#endif


