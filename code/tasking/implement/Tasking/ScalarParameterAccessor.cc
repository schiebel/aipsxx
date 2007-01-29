//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1999,2000
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
//# $Id: ScalarParameterAccessor.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ScalarParameterAccessor.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Utilities/DataType.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template<class T>
ScalarParameterAccessor<T>::ScalarParameterAccessor(const String &name, 
				    ParameterSet::Direction direction,
				    GlishRecord *values)
    : ParameterAccessor<T>(name, direction, values, new T)
{
    // Nothing
}

template<class T>
Bool ScalarParameterAccessor<T>::fromRecord(String &error)
{
    GlishValue val = values_p->get(name());
    error = "";
    if (val.type() != GlishValue::ARRAY) {
	error = String("Parameter ") + name() + " must be a scalar, not "
	    "a record";
	return False;
    }

    GlishArray arr = val;
    GlishArray::ElementType yourtype = arr.elementType();
    if (arr.nelements() > 1 || 
	(arr.nelements() == 0  && yourtype != GlishArray::STRING)) {
	error = String("Parameter ") + name() + " must be a scalar, not "
	    "an array";
	return False;
    }

    DataType mytype = whatType(static_cast<T *>(0));
    if ((mytype == TpString && yourtype != GlishArray::STRING) ||
	(yourtype == GlishArray::STRING && mytype != TpString)) {
	error = String("Parameter ") + name() + " cannot convert between "
	    "numbers and strings";
	return False;
    }

    // OK, I guess we can do it!
    T tmp;
    arr.get(tmp);
    this->operator()() = tmp;
    return True;
}

template<class T>
Bool ScalarParameterAccessor<T>::toRecord(String &error) const
{
    error = "";
    values_p->add(name(), GlishArray(operator()()));
    return True;
}

} //# NAMESPACE CASA - END

