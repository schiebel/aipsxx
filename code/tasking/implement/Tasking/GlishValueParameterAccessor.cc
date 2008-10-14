//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,2000
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
//# $Id: GlishValueParameterAccessor.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/GlishValueParameterAccessor.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>

namespace casa { //# NAMESPACE CASA - BEGIN

GlishValueParameterAccessor::GlishValueParameterAccessor(const String &name, 
			    ParameterSet::Direction direction,
			    GlishRecord *values)
  : ParameterAccessor<GlishValue>(name, direction, values, new GlishValue)
{
    // Nothing
}

GlishValueParameterAccessor::~GlishValueParameterAccessor()
{
    // Nothing
}

Bool GlishValueParameterAccessor::fromRecord(String &error)
{
    error = "";
    this->operator()() = values_p->get(name());
    return True;
}

Bool GlishValueParameterAccessor::toRecord(String &error) const
{
    error = "";
    values_p->add(name(), operator()());
    return True;
}

GlishArrayParameterAccessor::GlishArrayParameterAccessor(const String &name, 
			    ParameterSet::Direction direction,
			    GlishRecord *values)
  : ParameterAccessor<GlishArray>(name, direction, values, new GlishArray)
{
    // Nothing
}

GlishArrayParameterAccessor::~GlishArrayParameterAccessor()
{
    // Nothing
}

Bool GlishArrayParameterAccessor::fromRecord(String &error)
{
    GlishValue tmp = values_p->get(name());
    error = "";
    if (tmp.type() != GlishValue::ARRAY) {
	error = "Cannot convert a non-array (record) to a Glish Array";
	return False;
    }
    this->operator()() = values_p->get(name());
    return True;
}

Bool GlishArrayParameterAccessor::toRecord(String &error) const
{ 
    error = "";
    values_p->add(name(), operator()());
    return True;
}

GlishRecordParameterAccessor::GlishRecordParameterAccessor(const String &name, 
			    ParameterSet::Direction direction,
			    GlishRecord *values)
  : ParameterAccessor<GlishRecord>(name, direction, values, new GlishRecord)
{
    // Nothing
}

GlishRecordParameterAccessor::~GlishRecordParameterAccessor()
{
    // Nothing
}

Bool GlishRecordParameterAccessor::fromRecord(String &error)
{
    GlishValue tmp = values_p->get(name());
    error = "";
    if (tmp.type() != GlishValue::RECORD) {
	error = "Cannot convert an array to a Glish Record";
	return False;
    }
    this->operator()() = values_p->get(name());
    return True;
}

Bool GlishRecordParameterAccessor::toRecord(String &error) const
{
    error = "";
    values_p->add(name(), operator()());
    return True;
}


} //# NAMESPACE CASA - END

