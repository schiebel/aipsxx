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
//# $Id: ParamAccBase.h,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#ifndef TASKING_PARAMACCBASE_H
#define TASKING_PARAMACCBASE_H

#include <casa/aips.h>
#include <tasking/Tasking/ParameterSet.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward Declarations

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

class ParameterAccessorBase
{
public:
    ParameterAccessorBase(const String &name, ParameterSet::Direction direction,
			  GlishRecord *values);
    ParameterAccessorBase(const ParameterAccessorBase &other);
    virtual ~ParameterAccessorBase();

    const String &name() const;
    ParameterSet::Direction direction() const;

    virtual void attach(GlishRecord *values);

    virtual const String &type() const = 0;

    virtual Bool copyIn(String &error) = 0;
    virtual Bool copyOut(String &error) const = 0;
    virtual Bool verifyValue(String &error) const = 0;

    // Reset our value to its "null" state. In particular, resize arrays to be
    // zero-length so that they can be copied over etc.
    virtual void reset();
protected:
    GlishRecord *values_p;

    Bool verifyIn(String &error) const;
    Bool verifyOut(String &error) const;

private:
    void copy(const ParameterAccessorBase &other);
    String name_p;
    ParameterSet::Direction direction_p;
};

inline const String &ParameterAccessorBase::name() const
{
    return name_p;
}

inline ParameterSet::Direction ParameterAccessorBase::direction() const
{
    return direction_p;
}


} //# NAMESPACE CASA - END

#endif
