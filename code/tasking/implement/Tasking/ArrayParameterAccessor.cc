//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1999,2000
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
//# $Id: ArrayParameterAccessor.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ArrayParameterAccessor.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/IPosition.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Utilities/DataType.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template<class T>
ArrayParameterAccessor<T>::ArrayParameterAccessor(const String &name, 
				    ParameterSet::Direction direction,
				    GlishRecord *values)
    : ParameterAccessor< Array<T> >(name, direction, values, new Array<T>)
{
    // Nothing
}

template<class T>
Bool ArrayParameterAccessor<T>::fromRecord(String &error)
{
    GlishValue val = values_p->get(name());
    error = "";
    if (val.type() != GlishValue::ARRAY) {
	error = String("Parameter ") + name() + " must be an array, not "
	    "a record";
	return False;
    }

    GlishArray arr = val;
    DataType mytype = whatType(static_cast<T *>(0));
    GlishArray::ElementType yourtype = arr.elementType();
    if ((mytype == TpString && yourtype != GlishArray::STRING) ||
	(yourtype == GlishArray::STRING && mytype != TpString)) {
	error = String("Parameter ") + name() + " cannot convert between "
	    "numbers and strings";
	return False;
    }

    IPosition shape = arr.shape( );
    if ( shape.product( ) != (Int) arr.nelements() )
	{
	error = String( "Parameter " ) + name() + " shape does not match length";
	return False;
    }

    // OK, I guess we can do it!
    this->operator()().resize(shape);
    arr.get(this->operator()());
    return True;
}

template<class T>
Bool ArrayParameterAccessor<T>::toRecord(String &error) const
{
    error="";
    values_p->add(name(), GlishArray(operator()()));
    return True;
}

template<class T>
void ArrayParameterAccessor<T>::reset()
{
    if (value_p) {
	// Reset the array to being zero sized.
	IPosition empty(operator()().ndim(), 0);
	operator()().resize(empty);
    }
}


template<class T>
VectorParameterAccessor<T>::VectorParameterAccessor(const String &name, 
				    ParameterSet::Direction direction,
				    GlishRecord *values)
    : ParameterAccessor< Vector<T> >(name, direction, values, new Vector<T>)
{
    // Nothing
}

template<class T>
Bool VectorParameterAccessor<T>::fromRecord(String &error)
{
    GlishValue val = values_p->get(name());
    error = "";
    if (val.type() != GlishValue::ARRAY) {
	error = String("Parameter ") + name() + " must be an vector, not "
	    "a record";
	return False;
    }

    GlishArray arr = val;
    DataType mytype = whatType(static_cast<T *>(0));
    GlishArray::ElementType yourtype = arr.elementType();
    if ((mytype == TpString && yourtype != GlishArray::STRING) ||
	(yourtype == GlishArray::STRING && mytype != TpString)) {
	error = String("Parameter ") + name() + " cannot convert between "
	    "numbers and strings";
	return False;
    }

    if (arr.shape().nelements() != 1) {
	error = String("Parameter ") + name() + " Vectors must be initialized "
	    "from 1-D arrays";
	return False;
    }

    IPosition shape = arr.shape( );
    if ( shape.product( ) != (Int) arr.nelements() )
	{
	error = String( "Parameter " ) + name() + " shape does not match length";
	return False;
    }

    // OK, I guess we can do it!
    this->operator()().resize(shape);
    arr.get(this->operator()());
    return True;
}

template<class T>
Bool VectorParameterAccessor<T>::toRecord(String &error) const
{
    error="";
    values_p->add(name(), GlishArray(operator()()));
    return True;
}

template<class T>
void VectorParameterAccessor<T>::reset()
{
    if (value_p) {
	// Reset the array to being zero sized.
	operator()().resize(0);
    }
}

} //# NAMESPACE CASA - END

