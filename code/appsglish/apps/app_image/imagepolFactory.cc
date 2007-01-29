//# imagepolFactory.cc: defines imagepolFactory.cc
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

#include <../app_image/imagepolFactory.h>
#include <casa/Arrays/Vector.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ObjectController.h>
#include <appsglish/app_image/DOpolarimetry.h>
#include <images/Images/PagedImage.h>
#include <casa/BasicSL/String.h>


#include <casa/namespace.h>
MethodResult imagepolFactory::make(ApplicationObject *&newObject,
                                   const String &whichConstructor,
                                   ParameterSet &inputRecord,
                                   Bool runConstructor)
{
    MethodResult retval;
    newObject = 0;
    if (whichConstructor == "imagepol") {
	Parameter<String> infile(inputRecord, "infile",
                                 ParameterSet::In);
	if (runConstructor) {
	    newObject = new imagepol(infile());
	}
    } else if (whichConstructor == "imagepoltestimage") {
        Parameter<String> outFile(inputRecord, "outfile", ParameterSet::In);
        Parameter<Vector<Float> > rm(inputRecord, "rm", ParameterSet::In);
        Parameter<Bool> rmDefault(inputRecord, "defaultrm", ParameterSet::In);
        Parameter<Float> pa0(inputRecord, "pa0", ParameterSet::In);
        Parameter<Float> sigma(inputRecord, "sigma", ParameterSet::In);
        Parameter<Float> f0(inputRecord, "f0", ParameterSet::In);
        Parameter<Float> bw(inputRecord, "bw", ParameterSet::In);
        Parameter<Int> nx(inputRecord, "nx", ParameterSet::In);
        Parameter<Int> ny(inputRecord, "ny", ParameterSet::In);
        Parameter<Int> nf(inputRecord, "nf", ParameterSet::In);
        if (runConstructor) {
          newObject = new imagepol (outFile(), rm(), rmDefault(),
                                    pa0(), sigma(), nx(), ny(),
                                    nf(), f0(), bw());
        }
    } else {   
	retval = String("Unknown constructor ") + whichConstructor;
    }

    if (retval.ok() && runConstructor && !newObject) {
	retval = "Memory allocation error";
    }
    return retval;
}
