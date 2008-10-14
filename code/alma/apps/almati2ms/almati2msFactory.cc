//# almati2msFactory.cc: implementation of almati2msFactory.h
//# Copyright (C) 1997,1998,1999,2001,2002
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
//# $Id: almati2msFactory.cc,v 19.2 2005/02/07 17:03:08 wyoung Exp $

#include <../almati2ms/almati2msFactory.h>
#include <DOalmati2ms.h>

#include <casa/namespace.h>
MethodResult almati2msFactory::make(ApplicationObject *&newObject,
				     const String &whichConstructor,
				     ParameterSet &inputRecord,
				     Bool runConstructor)
{
  MethodResult retval;
  newObject = 0;
    
  if (whichConstructor == "almati2ms") {
    Parameter<String> msfile(inputRecord, "msfile", ParameterSet::In);
    Parameter<String> fitsin(inputRecord, "fitsin", ParameterSet::In);
    Parameter<Bool> append(inputRecord, "append", ParameterSet::In);
    if (runConstructor) {
      newObject = new almati2ms(msfile(), fitsin(), append());
    }
  } else {
    retval = String("Unknown constructor ") + whichConstructor;
  }
  
  if (retval.ok() && runConstructor && !newObject) {
    retval = "Memory allocation error";
  }
  return retval;
}
