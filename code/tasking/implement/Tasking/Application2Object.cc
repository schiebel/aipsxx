//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996
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
//# $Id: Application2Object.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ApplicationObject.h>
#include <tasking/Tasking/MethodResult.h>
#include <casa/Arrays/Vector.h>

namespace casa { //# NAMESPACE CASA - BEGIN

ApplicationObject::ApplicationObject()
{
}

ApplicationObject::ApplicationObject(const ApplicationObject &)
{
  // unique id
}

ApplicationObject &ApplicationObject::operator=(const ApplicationObject &)
{
  // Don't copy over other id!
  return *this;
}

ApplicationObject::~ApplicationObject()
{
  // Nothing
}

MethodResult ApplicationObject::ok()
{
    MethodResult retval;
    return retval;
}

Vector<String> ApplicationObject::noTraceMethods() const
{
    // By default, all methods are traced
    Vector<String> empty;
    return empty;
}

MethodResult ApplicationObject::error(const String &message)
{
    return MethodResult(message);
}

ApplicationObjectFactory::~ApplicationObjectFactory()
{
    // Nothing
}


} //# NAMESPACE CASA - END

