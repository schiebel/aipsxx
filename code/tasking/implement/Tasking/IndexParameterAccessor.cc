//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1998,1999,2000
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
//# $Id: IndexParameterAccessor.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/IndexParameterAccessor.h>
#include <tasking/Tasking/ScalarParameterAccessor.h>
#include <tasking/Tasking/ArrayParameterAccessor.h>

#include <casa/Utilities/Assert.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>

namespace casa { //# NAMESPACE CASA - BEGIN

IndexParameterAccessor::IndexParameterAccessor(const String &name, 
		       ParameterSet::Direction direction,
		       GlishRecord *values)
    : ParameterAccessor<Index>(name, direction, values, new Index),
      worker_p(new ScalarParameterAccessor<Int>(name, direction, values))
{
    AlwaysAssert(worker_p != 0, AipsError);
}

IndexParameterAccessor::~IndexParameterAccessor()
{
    delete worker_p;
    worker_p = 0;
}

void IndexParameterAccessor::attach(GlishRecord *values)
{
    ParameterAccessorBase::attach(values);
    worker_p->attach(values);
}

Bool IndexParameterAccessor::fromRecord(String &error)
{
    Bool retval = worker_p->fromRecord(error);
    if (retval) {
	(*this)() = (*worker_p)() - 1;
    }
    return retval;
}

Bool IndexParameterAccessor::toRecord(String &error) const
{
    error = "";
    values_p->add(name(), GlishArray(operator()().oneRelativeValue()));
    return True;
}

IndexVectorParameterAccessor::IndexVectorParameterAccessor(const String &name, 
		       ParameterSet::Direction direction,
		       GlishRecord *values)
    : ParameterAccessor< Vector<Index> >(name, direction, values, 
					 new Vector<Index>),
      worker_p(new VectorParameterAccessor<Int>(name, direction, values))
{
    AlwaysAssert(worker_p != 0, AipsError);
}

IndexVectorParameterAccessor::~IndexVectorParameterAccessor()
{
    delete worker_p;
    worker_p = 0;
}

void IndexVectorParameterAccessor::attach(GlishRecord *values)
{
    ParameterAccessorBase::attach(values);
    worker_p->attach(values);
}

Bool IndexVectorParameterAccessor::fromRecord(String &error)
{
    Bool retval = worker_p->fromRecord(error);
    if (retval) {
	Index::convertVector(this->operator()(), worker_p->operator()(), False);
    }
    return retval;
}

Bool IndexVectorParameterAccessor::toRecord(String &error) const
{
    // Use the already-allocated space in the worker as the temporary!
    error = "";
    Index::convertVector(worker_p->operator()(), this->operator()(), False);
    values_p->add(name(), GlishArray(worker_p->operator()()));
    return True;
}

} //# NAMESPACE CASA - END

