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
//# $Id: ParamAccBase.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ParamAccBase.h>

namespace casa { //# NAMESPACE CASA - BEGIN

ParameterAccessorBase::ParameterAccessorBase(
				     const String &name,
				     ParameterSet::Direction direction,
				     GlishRecord *values)
: values_p(values),
  name_p(name),
  direction_p(direction)
{
}


ParameterAccessorBase::ParameterAccessorBase(const ParameterAccessorBase &other)
{
    copy(other);
}

ParameterAccessorBase::~ParameterAccessorBase()
{
    values_p = 0;
    name_p = "unset";
}

void ParameterAccessorBase::attach(GlishRecord *values)
{
    values_p = values;
}

void ParameterAccessorBase::reset()
{
  // Nothing
}

Bool ParameterAccessorBase::verifyIn(String &error) const
{
    Bool retval = True;
    if (direction() == ParameterSet::Out) {
	error = String("Parameter ") + name() + " is being used for input although"
	    " it is an output only parameter";
	retval = False;
    }
    return retval;
}

Bool ParameterAccessorBase::verifyOut(String &error) const
{
    Bool retval = True;
    if (direction() == ParameterSet::In) {
	error = String("Parameter ") + name() + " is being used for output although"
	    " it is an input only parameter";
	retval = False;
    }
    return retval;
}

void ParameterAccessorBase::copy(const ParameterAccessorBase &other)
{
    if (this != &other) {
	values_p = other.values_p;
	name_p = other.name_p;
	direction_p = other.direction_p;
    }
}


} //# NAMESPACE CASA - END

