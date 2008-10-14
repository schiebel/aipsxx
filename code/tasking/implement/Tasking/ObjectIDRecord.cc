//# ObjectIDRecord.cc: Interconvert between ObjectID and Records.
//# Copyright (C) 1996,1999,2003
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
//# $Id: ObjectIDRecord.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ObjectIDRecord.h>
#include <casa/System/ObjectID.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>

namespace casa { //# NAMESPACE CASA - BEGIN

void OIDtoRecord (const ObjectID& id, GlishRecord& out, const char* prefix)
{
    String pfx = prefix;
    out.add (pfx + "sequence", id.sequence());
    out.add (pfx + "pid", id.pid());
    out.add (pfx + "time", id.creationTime());
    out.add (pfx + "host", id.hostName());
}

Bool OIDfromRecord (ObjectID& id, String& error, const GlishRecord& in, 
		    const char* prefix)
{
    String pfx = prefix;
    String name = pfx + "sequence";
    if (!in.exists(name)) {
	error = name + " does not exist in record";
	return False;
    }
    GlishValue val = in.get(name);
    if (val.type() != GlishValue::ARRAY) {
	error = name + " is not a scalar integer";
	return False;
    }
    GlishArray arr = val;
    if (arr.nelements()>1 || 
	arr.elementType() == GlishArray::BOOL ||
	arr.elementType() == GlishArray::COMPLEX ||
	arr.elementType() == GlishArray::DCOMPLEX ||
	arr.elementType() == GlishArray::STRING) {
	error = name + " is not a scalar integer";
	return False;
    }
    Int seq;
    arr.get(seq);

    name = pfx + "pid";
    if (!in.exists(name)) {
	error = name + " does not exist in record";
	return False;
    }
    val = in.get(name);
    if (val.type() != GlishValue::ARRAY) {
	error = name + " is not a scalar integer";
	return False;
    }
    arr = val;
    if (arr.nelements()>1 || 
	arr.elementType() == GlishArray::BOOL ||
	arr.elementType() == GlishArray::COMPLEX ||
	arr.elementType() == GlishArray::DCOMPLEX ||
	arr.elementType() == GlishArray::STRING) {
	error = name + " is not a scalar integer";
	return False;
    }
    Int pid;
    arr.get(pid);

    name = pfx + "time";
    if (!in.exists(name)) {
	error = name + " does not exist in record";
	return False;
    }
    val = in.get(name);
    if (val.type() != GlishValue::ARRAY) {
	error = name + " is not a scalar integer";
	return False;
    }
    arr = val;
    if (arr.nelements()>1 || 
	arr.elementType() == GlishArray::BOOL ||
	arr.elementType() == GlishArray::COMPLEX ||
	arr.elementType() == GlishArray::DCOMPLEX ||
	arr.elementType() == GlishArray::STRING) {
	error = name + " is not a scalar integer";
	return False;
    }
    Int time;
    arr.get(time);

    name = pfx + "host";
    if (!in.exists(name)) {
	error = name + " does not exist in record";
	return False;
    }
    val = in.get(name);
    if (val.type() != GlishValue::ARRAY) {
	error = name + " is not a scalar string";
	return False;
    }
    arr = val;
    if (arr.nelements()>1 || arr.elementType() != GlishArray::STRING) {
	error = name + " is not a scalar string";
	return False;
    }
    String hostname;
    arr.get(hostname);

    id = ObjectID(seq, pid, time, hostname);
    return True;
}

} //# NAMESPACE CASA - END

