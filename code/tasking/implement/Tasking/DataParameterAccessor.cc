//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1998,1999,2000
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
//# $Id: DataParameterAccessor.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/DataParameterAccessor.h>
#include <casa/Arrays/IPosition.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/Utilities/DataType.h>

#include <tables/Tables/Table.h>

#include <casa/Exceptions/Error.h>


namespace casa { //# NAMESPACE CASA - BEGIN

template<class T>
PagedImageParameterAccessor<T>::PagedImageParameterAccessor(const String &name, 
				    ParameterSet::Direction direction,
				    GlishRecord *values)
    : ParameterAccessor< PagedImage<T> >(name, direction, values, 0, 0)
{
    // Nothing
}

template<class T>
Bool PagedImageParameterAccessor<T>::fromRecord(String &error)
{
    String baseError;
    if (baseError.length() == 0) {
        baseError = String("Parameter ") + name() + " ";
    }

    GlishValue val = values_p->get(name());
    if (val.type() != GlishValue::ARRAY || val.nelements() != 1) {
	error = baseError + "must be a String, not a record or array";
	return False;
    }

    GlishArray arr = val;
    if (arr.elementType() != GlishArray::STRING) {
	error = baseError + " must be a string";
	return False;
    }

    String filename;
    arr.get(filename);

    if (! Table::isReadable(filename)) {
	error = baseError + " imagefile " + filename + " does not exist";
	return False;
    }

    if (imagePixelType(filename) != whatType(static_cast<T*>(0))) {
	error = baseError + " imagefile " + filename + " wrong pixel type";
	return False;
    }

    PagedImage<T> *tmp = 0;
    try {
	tmp = new PagedImage<T>(filename);
    } catch (AipsError x) {
	error = String("Parameter ") + name() + " image(" + filename +
	    ") open error:" + x.getMesg();
	if (tmp) {delete tmp;}
	return False;
    } 

    value_p = tmp;
    return True;
}

template<class T>
Bool PagedImageParameterAccessor<T>::toRecord(String &error) const
{
    error = String("Parameter ") + name() + " cannot yet have output images - use"
      " a String filename";
    return False;
}

} //# NAMESPACE CASA - END

