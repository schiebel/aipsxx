//# coordsysFactory.cc: defines coordsysFactory.cc
//# Copyright (C) 1996,1997,1998,1999,2000,2001
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
//# $Id: 
//#

#include <../app_image/coordsysFactory.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/Index.h>
#include <tasking/Tasking/ObjectController.h>
#include <appsglish/app_image/DOcoordsys.h>
#include <coordinates/Coordinates/CoordinateSystem.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>


#include <casa/namespace.h>
MethodResult coordsysFactory::make(ApplicationObject *&newObject,
   				   const String &whichConstructor,
				   ParameterSet &inputRecord,
				   Bool runConstructor)
{
    MethodResult retval;
    newObject = 0;
    if (whichConstructor == "coordsys") {	
        Parameter<Bool> direction(inputRecord, "direction",
                                  ParameterSet::In);
        Parameter<Bool> spectral(inputRecord, "spectral",
                                 ParameterSet::In);
        Parameter<Vector<String> > stokes(inputRecord, "stokes",
                              ParameterSet::In);
        Parameter<Int> linear(inputRecord, "linear",
                              ParameterSet::In);
        Parameter<Bool> tabular(inputRecord, "tabular",
                                  ParameterSet::In);
	if (runConstructor) {
	    newObject = new coordsys(direction(), spectral(), 
                                     stokes(), linear(), tabular());
	}
    } else {
	retval = String("Unknown constructor ") + whichConstructor;
    }

    if (retval.ok() && runConstructor && !newObject) {
	retval = "Memory allocation error";
    }
    return retval;
}
