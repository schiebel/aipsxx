//# imageFactory.cc: defines imageFactory.cc
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

#include <../app_image/imageFactory.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/Index.h>
#include <casa/System/AppInfo.h>
#include <tasking/Tasking/ObjectController.h>
#include <appsglish/app_image/DOimage.h>
#include <tasking/Glish/GlishRecord.h>
#include <images/Images/PagedImage.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>

#include <casa/namespace.h>

MethodResult imageFactory::make(ApplicationObject *&newObject,
				const String &whichConstructor,
				ParameterSet &inputRecord,
				Bool runConstructor)
{
    MethodResult retval;
    newObject = 0;
    if (whichConstructor == "image") {
	Parameter<String> infile(inputRecord, "infile",
  				 ParameterSet::In);
	if (runConstructor) {
	    newObject = new image(infile());
	}
    } else if (whichConstructor == "imagefromimage") {
	Parameter<String> outfile(inputRecord, "outfile",
                                  ParameterSet::In);
        Parameter<String> infile(inputRecord, "infile",
                                 ParameterSet::In);
        Parameter<GlishRecord> region(inputRecord, "region",
                                      ParameterSet::In);
        Parameter<String> mask(inputRecord, "mask",
                               ParameterSet::In);
        Parameter<Bool> dropDeg(inputRecord, "dropdeg",
                              ParameterSet::In);
	Parameter<Bool> overwrite(inputRecord, "overwrite",
                                  ParameterSet::In);
	if (runConstructor) {
	    newObject = new image(outfile(), infile(), region(), 
                                  mask(), dropDeg(), overwrite());
	}
    } else if (whichConstructor == "imagefromfits") {
	Parameter<String> outfile(inputRecord, "outfile",
				    ParameterSet::In);
	Parameter<String> fitsfile(inputRecord, "fitsfile",
				   ParameterSet::In);
	Parameter<Index> whichrep(inputRecord, "whichrep",
				  ParameterSet::In);
	Parameter<Index> whichhdu(inputRecord, "whichhdu",
				  ParameterSet::In);
        Parameter<Bool> zeroblanks(inputRecord, "zeroblanks", ParameterSet::In);
	Parameter<Bool> overwrite(inputRecord, "overwrite",
                                  ParameterSet::In);
	Parameter<Bool> oldParser(inputRecord, "old",
                                  ParameterSet::In);
	if (runConstructor) {
	    newObject = new image(outfile(), fitsfile(), whichrep(), whichhdu(), 
                                  zeroblanks(), overwrite(), oldParser());
	}
    } else if (whichConstructor == "imagefromarray") {
	Parameter<String> outfile(inputRecord, "outfile",
				    ParameterSet::In);
	Parameter< Array<Float> > pixels(inputRecord, "pixels",
				   ParameterSet::In);
	Parameter<GlishRecord> csys(inputRecord, "csys",
                                    ParameterSet::In);
	Parameter<Bool> linear(inputRecord, "linear",
                               ParameterSet::In);
	Parameter<Bool> log(inputRecord, "log",
                               ParameterSet::In);
	Parameter<Bool> overwrite(inputRecord, "overwrite",
                                  ParameterSet::In);
	if (runConstructor) {
	    newObject = new image(outfile(), pixels(), csys(), 
                                  linear(), log(), overwrite());
	}
    } else if (whichConstructor == "imagefromshape") {
	Parameter<String> outfile(inputRecord, "outfile",
				    ParameterSet::In);
	Parameter< Vector<Int> > shape(inputRecord, "shape",
   				       ParameterSet::In);
	Parameter<GlishRecord> csys(inputRecord, "csys",
                                    ParameterSet::In);
	Parameter<Bool> linear(inputRecord, "linear",
                               ParameterSet::In);
	Parameter<Bool> log(inputRecord, "log",
                               ParameterSet::In);
	Parameter<Bool> overwrite(inputRecord, "overwrite",
                                  ParameterSet::In);
	if (runConstructor) {
	    newObject = new image(outfile(), shape(), csys(), 
                                  linear(), log(), overwrite());
	}
    } else if (whichConstructor == "imageconcat") {
        Parameter<Index> axis(inputRecord, "axis",
				  ParameterSet::In);
	Parameter<String> outfile(inputRecord, "outfile",
				    ParameterSet::In);
	Parameter< Vector<String> > infiles(inputRecord, "infiles",
				    ParameterSet::In);
	Parameter<Bool> relax(inputRecord, "relax",
				    ParameterSet::In);
	Parameter<Bool> tempClose(inputRecord, "tempclose",
				    ParameterSet::In);
	Parameter<Bool> overwrite(inputRecord, "overwrite",
                                  ParameterSet::In);
//
	if (runConstructor) {
	    newObject = new image(outfile(), infiles(), axis(), 
                                  relax(), tempClose(), overwrite());
	}
    } else if (whichConstructor == "imagecalc") {
	Parameter<String> outfile(inputRecord, "outfile",
                                  ParameterSet::In);
	Parameter<String> expr(inputRecord, "expr",
                               ParameterSet::In);
	Parameter<Bool> overwrite(inputRecord, "overwrite",
                                  ParameterSet::In);
	Parameter<GlishRecord> regionsRecord(inputRecord, "regions",
					     ParameterSet::In);
	if (runConstructor) {
	    newObject = new image(outfile(), expr(), overwrite(), 
                                  regionsRecord());
	}
    } else {
	retval = String("Unknown constructor ") + whichConstructor;
    }

    if (retval.ok() && runConstructor && !newObject) {
	retval = "Memory allocation error";
    }
    return retval;
}
