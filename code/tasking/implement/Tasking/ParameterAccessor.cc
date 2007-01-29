//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1999
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
//# $Id: ParameterAccessor.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ParameterAccessor.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/ParameterImpl.h>
#include <casa/Utilities/Assert.h>
#include <tasking/Glish/GlishRecord.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template<class T>
ParameterAccessor<T>::ParameterAccessor(const String &name, 
			    ParameterSet::Direction direction,
			    GlishRecord *values,
			    T *valueFromNewOrNull,
		            T *defaultFromNewOrNull)
    : ParameterAccessorBase(name, direction, values),
      value_p(valueFromNewOrNull), default_p(defaultFromNewOrNull),
      constraint_p(0)
{
    // Nothing
}

template<class T>
ParameterAccessor<T>::~ParameterAccessor()
{
    if (constraint_p) {
        delete constraint_p;
	constraint_p = 0;
    }
    if (value_p) {
      delete value_p;
      value_p = 0;
    }
    if (default_p) {
      delete default_p;
      default_p = 0;
    }
}

template<class T>
Bool ParameterAccessor<T>::verifyValue(String &error) const
{
    if (constraint_p) {
	return constraint_p->valueOK(operator()(), error);
    }
    return True;
}


template<class T>
const String &ParameterAccessor<T>::type() const
{
    return typeName(static_cast<T*>(0));
}

template<class T>
Bool ParameterAccessor<T>::copyIn(String &error)
{
    Bool retval = True;
    if (! verifyIn(error)) {
	retval = False;
    }

    if (values_p->exists(name())) {
	retval = fromRecord(error);
    } else if (hasDefault() && value_p && default_p) {
	retval = True;
	*value_p = *default_p;
    } else {
      error = String("No Parameter<T> named '") + name() + "' has been "
	"sent to the method. This is probably a bug in the Glish binding.";
	retval = False;
    }

    if (retval) {
	retval = verifyValue(error);
    }
    return retval;
}

template<class T>
Bool ParameterAccessor<T>::copyOut(String &error) const
{
    Bool retval = True;
    if (! verifyOut(error)) {
	retval = False;
    }

    retval = toRecord(error);

    return retval;
}

template<class T>
void ParameterAccessor<T>::setDefaultValue(const T &defaultVal)
{
    if (default_p) {
	delete default_p;
	default_p = 0;
    }
    AlwaysAssert(direction() != ParameterSet::Out, AipsError);
    default_p = new T(defaultVal);
}

template<class T>
void ParameterAccessor<T>::setConstraint(const ParameterConstraint<T> &constraint)
{
    AlwaysAssert(direction() != ParameterSet::Out, AipsError);

    if (constraint_p) {
	delete constraint_p;
    }
    constraint_p = constraint.clone();
    AlwaysAssert(constraint_p, AipsError);
}

} //# NAMESPACE CASA - END

