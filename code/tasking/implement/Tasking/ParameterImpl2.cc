//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1998,1999,2001,2003
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
//# $Id: ParameterImpl2.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ParameterImpl.h>
#include <tasking/Tasking/DataParameterAccessor.h>
#include <casa/Utilities/DataType.h>

#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

#define DEFINE_PIMAGE_TYPE(ElType) \
ParameterAccessor< PagedImage< ElType > > *makeAccessor( \
                    PagedImage< ElType > *, \
		    const String &name, \
		    ParameterSet::Direction direction, \
		    GlishRecord *values) \
{ \
    return new PagedImageParameterAccessor<ElType>(name, direction, values); \
} \
 \
const String &typeName(PagedImage< ElType > *) \
{  \
    static String name; \
    if (name.length() == 0) { \
	name = String("PagedImage") + "<"; \
        DataType type = whatType(static_cast<ElType *>(0)); \
	ostringstream os; \
	os << type; \
	name += String(os) + ">"; \
    } \
    return name; \
}

DEFINE_PIMAGE_TYPE(Float);

ParameterAccessor<Table> *makeAccessor(Table *,
				       const String &name,
				       ParameterSet::Direction direction,
				       GlishRecord *values)
{
    return new TableParameterAccessor(name, direction, values);
}

const String &typeName(Table *)
{
    static String name = "Table";
    return name;
}

} //# NAMESPACE CASA - END

