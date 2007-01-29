//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996
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
//# $Id: ParameterAccessor.h,v 19.6 2005/06/18 21:19:18 ddebonis Exp $

#ifndef TASKING_PARAMETERACCESSOR_H
#define TASKING_PARAMETERACCESSOR_H

#include <casa/aips.h>
#include <tasking/Tasking/ParamAccBase.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template<class T> class ParameterConstraint;

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

template<class T> class ParameterAccessor : public ParameterAccessorBase
{
public:
    ParameterAccessor(const String &name, ParameterSet::Direction direction,
		      GlishRecord *values, T *valueFromNewOrNull=0,
		      T *defaultFromNewOrNull=0);

    virtual ~ParameterAccessor();

    virtual const String &type() const;

    // These call to/fromRecord if there's a field, otherwise it uses the
    // default if it exists, otherwise error
    virtual Bool copyIn(String &error);
    virtual Bool copyOut(String &error) const;

    // field exists in record
    virtual Bool fromRecord(String &error) = 0;
    virtual Bool toRecord(String &error) const = 0;
    // A default implementation is provided - just check against the constraint
    virtual Bool verifyValue(String &error) const;

    T &operator()() {return *value_p;}
    const T &operator()() const {return *value_p;}

    Bool hasDefault() {return default_p ? True : False;}
    const T &getDefaultValue() const {return *default_p;}
    virtual void setDefaultValue(const T &defaultVal);

    virtual void setConstraint(const ParameterConstraint<T> &constraint);
protected:
    T *value_p;
    T *default_p;
    // 0 means any value is OK
    ParameterConstraint<T> *constraint_p;

    //# Make template-independent parent members known
public:
    using ParameterAccessorBase::name;
protected:
    using ParameterAccessorBase::values_p;
};


} //# NAMESPACE CASA - END

#ifndef AIPS_NO_TEMPLATE_SRC
#include <tasking/Tasking/ParameterAccessor.cc>
#endif //# AIPS_NO_TEMPLATE_SRC
#endif
