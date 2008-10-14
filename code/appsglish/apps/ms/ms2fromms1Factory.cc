//# ms2fromms1Factory.cc:
//# Copyright (C) 1999,2000,2001
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
//# $Id: ms2fromms1Factory.cc,v 19.5 2005/11/07 21:17:04 wyoung Exp $

#include <appsglish/ms/ms2fromms1Factory.h>
#include <appsglish/ms/DOms2fromms1.h>

#include <casa/BasicSL/String.h>

#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ParameterSet.h>
#include <tasking/Tasking/Parameter.h>


#include <casa/namespace.h>
MethodResult ms2fromms1Factory::make(ApplicationObject *&newObject,
				   const String &whichConstructor,
				   ParameterSet &inputRecord,
				   Bool runConstructor)
{
  MethodResult retval;
  newObject = 0;
  
  if (whichConstructor == "ms2fromms1") {
    Parameter< String > ms2(inputRecord, "MS2",
			    ParameterSet::In);
    Parameter< String > ms1(inputRecord, "MS1",
			    ParameterSet::In);

    Parameter< Bool > inPlace(inputRecord, "InPlace",
			      ParameterSet::In);
    if (runConstructor) {
      newObject = new ms2fromms1(ms2(), ms1(), inPlace());
    }
  } else {
    retval = String("Unknown constructor ") + whichConstructor;
  }
  
  if (retval.ok() && runConstructor && !newObject) {
    retval = "Memory allocation error";
  }
  return retval;
}


