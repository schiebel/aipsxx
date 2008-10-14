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
//# $Id: Parameter.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/Parameter.h>
#include <casa/BasicSL/String.h>
#include <tasking/Tasking/ParameterImpl.h>
#include <casa/Utilities/Assert.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template<class T> Parameter<T>::Parameter(ParameterSet &parameters, 
					  const String &which,
					  ParameterSet::Direction direction)
{
    if (parameters.doSetup()) {
	accessor_p = makeAccessor(static_cast<T *>(0), which, direction, 
				  parameters.values());
	ParameterAccessorBase *tmp = accessor_p;
	parameters.setAccessor(which, tmp);
    } else {
	ParameterAccessorBase *base = parameters.accessor(which);
	AlwaysAssert(base, AipsError);
	AlwaysAssert(base->direction() == direction, AipsError);
	AlwaysAssert(base->type() == typeName(static_cast<T *>(0)), AipsError);
	accessor_p = (ParameterAccessor<T> *)base;
    }
}

template<class T> const String &Parameter<T>::name() const
{
    return accessor_p->name();
}

template<class T> ParameterSet::Direction Parameter<T>::direction() const
{
    return accessor_p->direction();
}

template<class T> void Parameter<T>::setDefaultValue(const T &defaultValue)
{
    accessor_p->setDefaultValue(defaultValue);
    accessor_p->operator()() = defaultValue;
}

template<class T> void Parameter<T>::setConstraint(
				      const ParameterConstraint<T> &constraint)
{
    accessor_p->setConstraint(constraint);
}


} //# NAMESPACE CASA - END

