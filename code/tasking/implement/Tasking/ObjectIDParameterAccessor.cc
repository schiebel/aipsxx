//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,2003
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
//# $Id: ObjectIDParameterAccessor.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ObjectIDParameterAccessor.h>
#include <tasking/Tasking/ObjectIDRecord.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>

#include <casa/Arrays/Vector.h>

namespace casa { //# NAMESPACE CASA - BEGIN

ObjectIDParameterAccessor::ObjectIDParameterAccessor(const String &name, 
                            ParameterSet::Direction direction,
                            GlishRecord *values)
  : ParameterAccessor<ObjectID>(name, direction, values, new ObjectID(True))
{
    // Nothing
}

ObjectIDParameterAccessor::~ObjectIDParameterAccessor()
{
    // Nothing
}

Bool ObjectIDParameterAccessor::fromRecord(String &error)
{
    static GlishValue  gval;
    static GlishRecord gid;

    gval = values_p->get(name());
    if (gval.type() != GlishValue::RECORD) {
	error = "Can only turn a GlishRecord into an ObjectID";
	return False;
    }
    gid = gval;

    Bool ok = fromRecord(operator()(), error, gid);

    return ok;
}

Bool ObjectIDParameterAccessor::toRecord(String &error) const
{
    static GlishRecord gidrec;
    Bool ok = toRecord(gidrec, error, operator()());

    values_p->add(name(), gidrec);

    return ok;
}

Bool ObjectIDParameterAccessor::toRecord(GlishRecord &record, String &, 
					 const ObjectID &id)
{
    OIDtoRecord(id, record, "");

    return True;
}

// Arrays should not be static function level with our exception emulation
    static Vector<Int> guts_vector(4);
Bool ObjectIDParameterAccessor::fromRecord(ObjectID &id, String &error, 
					   const GlishRecord &record)
{
    return OIDfromRecord(id, error, record, "");
}

} //# NAMESPACE CASA - END

