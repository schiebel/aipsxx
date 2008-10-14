//# DOms2sdfits.cc:  this implements the ms2sdfits DO
//# Copyright (C) 2000
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
//# $Id: DOms2sdfits.cc,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

//# Includes

#include <DOms2sdfits.h>

#include <casa/Containers/RecordFieldWriter.h>
#include <fits/FITS/FITSTable.h>
#include <ms/MeasurementSets/MSReader.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/MethodResult.h>
#include <casa/System/ProgressMeter.h>
#include <casa/OS/File.h>
#include <casa/Logging/LogIO.h>

#include <SDFITSSetup.h>
#include <casa/Exceptions/Error.h>

#include <casa/namespace.h>
Bool ms2sdfits::convert(const String &newsdfitsname, const String &msname)
{
    LogIO los;
    los << LogOrigin("ms2sdfits","convert(const String &newsdfitsname, const String &msname)");

    // sanity check, msname must exist as a readable directory (further checks on
    // the validity of the MS happen when an attempt is made to open it
    File msFile(msname);
    if (!msFile.exists() || !msFile.isReadable() || !msFile.isDirectory()) {
	los << LogIO::SEVERE
	    << WHERE
	    << "MeasurementSet : " << msname << " - does not exist or is not readable." 
	    << LogIO::POST;
	return False;
    }

    // sanity check, newsdfitsname must not exist as any type of file and it
    // must be possible to create a file with that name
    File sdfFile(newsdfitsname);
    if (sdfFile.exists() || !sdfFile.canCreate()) {
	los << LogIO::SEVERE
	    << WHERE
	    << "new SDFITS file : " << newsdfitsname << " - can not be created (it may already exist)"
	    << LogIO::POST;
	return False;
    }

    Bool read = False;
    Bool copy = False;
    Bool write = False
;
    try {
        SDFITSSetup setup(msname, newsdfitsname);

	uInt nrecords = setup.reader().ms().nrow();
	Int skip = nrecords / 10;
	ProgressMeter meter(0, nrecords, "converting MS to SDFITS", "rows",
			    "", "", True, skip);


	for (uInt i=0; i<nrecords; i++) {
	    read = copy = write = False;
	    setup.reader().gotoRow(i);
	    read = True;
	    setup.copier().copy();
	    copy = True;
	    setup.writer().write();
	    write = True;
	    meter.update(i);
	}

    } catch (AipsError x) {
	if (! read) {
	    los << LogIO::SEVERE << "Unhandled read : " << x.getMesg() << LogIO::POST;
	} else if (! write) {
	    los << LogIO::SEVERE << "Unhandled write : " << x.getMesg() << LogIO::POST;
	} else {
	    los << "Unknown exception - " << x.getMesg() << LogIO::POST;
	}
	return False;
    } 

    return True;
} 

Vector<String> ms2sdfits::methods() const {
    Vector<String> method(NUMBER_METHODS);
    method(CONVERT) = "convert";
    return method;
}

Vector<String> ms2sdfits::noTraceMethods() const
{
    Vector<String> tmp;
    // everything is traced
    return tmp;
}

MethodResult ms2sdfits::runMethod(uInt which,
				  ParameterSet &parameters,
				  Bool runMethod)
{
    static String returnvalString = "returnval";

    switch (which) {
    case CONVERT:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String newmsString = "newsdfitsname";
	    Parameter<String> newsdfitsname(parameters, newmsString,
					    ParameterSet::In);
	    static String sdfitsString = "msname";
	    Parameter<String> msname(parameters, sdfitsString,
				     ParameterSet::In);
	    if (runMethod) returnval() = convert(newsdfitsname(), msname());
	}
	break;
    default:
	return error("No such method");
    }
    return ok();
}


