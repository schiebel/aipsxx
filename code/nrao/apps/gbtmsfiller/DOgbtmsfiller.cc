//# DOgbtmsfiller.cc:  this implements the gbtmsfiller DO
//# Copyright (C) 1999,2000,2001,2002,2003
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
//# $Id: DOgbtmsfiller.cc,v 19.10 2006/07/27 21:12:46 bgarwood Exp $

//# Includes

#include <DOgbtmsfiller.h>
#include <nrao/GBTFillers/GBTBackendFiller.h>
#include <casa/Arrays/Vector.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <casa/BasicSL/Constants.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/MethodResult.h>
#include <nrao/GBTFillers/GBTDCRFiller.h>
#include <nrao/GBTFillers/GBTHoloFiller.h>
#include <nrao/GBTFillers/GBTSPFiller.h>
#include <nrao/GBTFillers/GBTACSFiller.h>
#include <casa/Logging/LogIO.h>
#include <casa/Utilities/Assert.h>
#include <casa/Quanta/Quantum.h>
#include <tasking/Glish/GlishRecord.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <casa/namespace.h>

gbtmsfiller::gbtmsfiller()
    : projectDir_p(""), msDir_p("."),
      backend_p(GBTScanLogReader::ANY), msroot_p(""),
      minTime_p(0), maxTime_p(3000, 1, 1.0), object_p("*"),
      initialMinScan_p(-1), initialMaxScan_p(LONG_MAX),
      dcrFiller_p(0), spFiller_p(0), holoFiller_p(0), acsFiller_p(0),
      acsAFiller_p(0), acsBFiller_p(0), acsCFiller_p(0), acsDFiller_p(0),
      okToFillDCR_p(False), okToFillSP_p(False), okToFillHolo_p(False), 
      okToFillAcs_p(False), reader_p(0), more_p(False)
{
    setobject(object_p);
    initStatusRecord();
}

gbtmsfiller::gbtmsfiller(const String &project, const String &backend,
			 const String &msrootname, const String &msdirectory,
                         String mintime, String maxtime, const String &object,
			 Int minscan, Int maxscan,
			 Bool fillrawpointing, Bool fillrawfocus, 
			 Bool filllags, const String &vv,
			 const String &smooth, Bool usehighcal, Bool compresscalcols,
			 Int vvSize, Bool usebias, Bool oneacsms,
			 Double dcbias, Int minbiasfactor, Bool fixbadlags,
			 Double sigmafactor, Int spikestart)
    : projectDir_p(""), msDir_p("."),
      backend_p(GBTScanLogReader::ANY), msroot_p(""),
      minTime_p(0), maxTime_p(3000, 1, 1.0), object_p("*"),
      initialMinScan_p(minscan), initialMaxScan_p(maxscan),
      dcrFiller_p(0), spFiller_p(0), holoFiller_p(0), acsFiller_p(0),
      acsAFiller_p(0), acsBFiller_p(0), acsCFiller_p(0), acsDFiller_p(0),
      okToFillDCR_p(False), okToFillSP_p(False), okToFillHolo_p(False), 
      okToFillAcs_p(False), reader_p(0), more_p(False)
{
    setproject(project);
    setbackend(backend);
    setmsrootname(msrootname);
    setmsdirectory(msdirectory);
    setmintime(mintime);
    setmaxtime(maxtime);
    setobject(object);
    setminscan(minscan);
    setmaxscan(maxscan);
    setfillrawpointing(fillrawpointing);
    setfillrawfocus(fillrawfocus);
    setfilllags(filllags);
    setfixbadlags(fixbadlags);
    if (sigmafactor <= 0.0) {
	LogIO os(LogOrigin("gbtmsfiller","gbtmsfiller()"));
	os << LogIO::SEVERE << "sigmafactor must be > 0, using default value of 6.0 instead" << LogIO::POST;
	sigmafactor = 6.0;
    }
    fillOptions_p.setSigmaFactor(sigmafactor);
    if (spikestart <= 0) {
	LogIO os(LogOrigin("gbtmsfiller","gbtmsfiller()"));
	os << LogIO::SEVERE << "spikestart must be > 0, using default value of 200 instead" << LogIO::POST;
	spikestart = 200;
    }
    fillOptions_p.setSpikeStart(spikestart);
    if (!setvv(vv)) {
	// unrecognized vv correction type - warn that the default is being used
	LogIO os(LogOrigin("gbtmsfiller","gbtmsfiller()"));
	os << LogIO::SEVERE << "Unrecognized vanVleck type : "
	   << vv           << "; the default type is being used" 
	   << LogIO::POST;
    }
    if (!setsmooth(smooth)) {
	// unrecognized smoothing type - warn that the default is being used
	LogIO os(LogOrigin("gbtmsfiller","gbtmsfiller()"));
	os << LogIO::SEVERE << "Unrecognized smoothing type : "
	   << smooth << "; the default type is being used" 
	   << LogIO::POST;
    }
    setusehighcal(usehighcal);
    setcompresscalcols(compresscalcols);
    // the vvSize only matters if the vvCorr==Schwab
    if (fillOptions_p.vanVleckCorr() == GBTACSTable::Schwab &&
	!setvvsize(vvSize)) {
	// unrecognized vv size - warn that the default is being used
	LogIO os(LogOrigin("gbtmsfiller","gbtmsfiller()"));
	os << LogIO::SEVERE << "Invalid vanVleck table size : "
	   << vvSize << " the default size is being used"
	   << LogIO::POST;
    }
    setusebias(usebias);
    setoneacsms(oneacsms);
    setdcbias(dcbias);
    setminbiasfactor(minbiasfactor);
    initStatusRecord();
}

gbtmsfiller::~gbtmsfiller()
{
    cleanup();
}

Bool gbtmsfiller::isattached(Bool silent)
{
    // equivalent to the scan log reader being there
    // try and initialize first if it isn't there
    if (!reader_p) init(silent);
    return reader_p;
}

Bool gbtmsfiller::fillall()
{
    Bool result = isattached();
    while (result && more()) {
	result = fillnext();
    }
    return result;
} 

Bool gbtmsfiller::fillnext()
{
    if (!isattached()) return False;

    reader_p->checkScanNumber();

    // if this is at the end, return True but fill nothing.
    if (reader_p->scan() < 0) {
	// this also means that more_p is False
	more_p = False;
	return True;
    }
    // skip uninteresting scans
    // everything starts out as not okay to fill, is set as okay by isInteresting
    Block<Int> backends;
    Block<String> backendFiles;
    if (isInteresting(backends, backendFiles)) {
	if (okToFillDCR_p) {
	    dcrFiller_p->fill(reader_p->dcrfile(), 
			      reader_p->dapFiles(),
			      reader_p->ifManagerFile(),
			      reader_p->rxCalInfoFiles(),
			      reader_p->GOFile(),
			      reader_p->antennaFile(),
			      reader_p->masterState(),
			      reader_p->LO1A(),
			      reader_p->LO1B(),
			      fillOptions_p);
	    okToFillDCR_p = False;
	}
	if (okToFillHolo_p) {
	    holoFiller_p->fill(reader_p->holofile(), 
			       reader_p->dapFiles(),
			       reader_p->ifManagerFile(),
			       reader_p->rxCalInfoFiles(),
			       reader_p->GOFile(),
			       reader_p->antennaFile(),
			       reader_p->masterState(),
			       reader_p->LO1A(),
			       reader_p->LO1B(),
			       fillOptions_p);
	    okToFillHolo_p = False;
	}
	if (okToFillSP_p) {
	    spFiller_p->fill(reader_p->spfile(), 
			     reader_p->dapFiles(),
			     reader_p->ifManagerFile(),
			     reader_p->rxCalInfoFiles(),
			     reader_p->GOFile(),
			     reader_p->antennaFile(),
			     reader_p->masterState(),
			     reader_p->LO1A(),
			     reader_p->LO1B(),
			     fillOptions_p);
	    okToFillSP_p = False;
	}
	if (okToFillAcs_p) {
	    if (fillOptions_p.oneacsms()) {
		acsFill(reader_p->acsfiles(), acsFiller_p);
	    } else {
		Vector<String> acsFiles = reader_p->acsfiles();
		for (uInt i=0;i<acsFiles.nelements();i++) {
		    String thisFile = acsFiles[i];
		    String bankName = thisFile.before(".fits");
		    Char bank = bankName.lastchar();
		    if (bank == 'A') {
			acsFill(Vector<String>(1,thisFile), acsAFiller_p);
		    } else if (bank == 'B') {
			acsFill(Vector<String>(1,thisFile), acsBFiller_p);
		    } else if (bank == 'C') {
			acsFill(Vector<String>(1,thisFile), acsCFiller_p);
		    } else if (bank == 'D') {
			acsFill(Vector<String>(1,thisFile), acsDFiller_p);
		    } else {
			// defaults to 'A' - issue a warning
			LogIO os(LogOrigin("gbtmsfiller","fillnext()"));
			os << LogIO::WARN << "Unrecognized ACS bank for file : "
			   << backendFiles[i] << "; will fill to MS for bank A"
			   << LogIO::POST;
			acsFill(Vector<String>(1,thisFile), acsAFiller_p);
		    }
		}
	    }
	    okToFillAcs_p = False;
	}
    }
    next();
    return True;
}

Bool gbtmsfiller::more() {
    return (isattached(True) && more_p);
}

Bool gbtmsfiller::update() {
    Bool result = isattached(True) && reader_p->reopen();
    if (result) {
	more_p = reader_p->scan() != -1;
    }
    return result;
}

Record gbtmsfiller::status() {
    *attachedStatus_p = isattached(True);
    if (reader_p) reader_p->checkScanNumber();

    // backends and mss vectors from the fillers
    doStatus(static_cast<GBTBackendFiller *>(dcrFiller_p), 
	     dcrMSStatus_p, dcrMSSize_p);
    doStatus(static_cast<GBTBackendFiller *>(spFiller_p), 
	     spMSStatus_p, spMSSize_p);
    doStatus(static_cast<GBTBackendFiller *>(holoFiller_p), 
	     holoMSStatus_p, holoMSSize_p);
    doStatus(static_cast<GBTBackendFiller *>(acsFiller_p), 
	     acsMSStatus_p, acsMSSize_p);
    doStatus(static_cast<GBTBackendFiller *>(acsAFiller_p), 
	     acsAMSStatus_p, acsAMSSize_p);
    doStatus(static_cast<GBTBackendFiller *>(acsBFiller_p), 
	     acsBMSStatus_p, acsBMSSize_p);
    doStatus(static_cast<GBTBackendFiller *>(acsCFiller_p), 
	     acsCMSStatus_p, acsCMSSize_p);
    doStatus(static_cast<GBTBackendFiller *>(acsDFiller_p), 
	     acsDMSStatus_p, acsDMSSize_p);

    if (more()) {
	*nextScanStatus_p = reader_p->scan();
	*nextDmjdStatus_p = reader_p->dmjd();
	*nextTimeStampStatus_p = reader_p->timeStamp();
    } else {
	*nextScanStatus_p = -1;
	*nextDmjdStatus_p = 0.0;
	*nextTimeStampStatus_p = 0.0;
    }
    *msDirStatus_p = msdirectory();
    *projectStatus_p = project();
    *objectStatus_p = object();
    *minTimeStatus_p = mintime();
    *maxTimeStatus_p = maxtime();
    *minScanStatus_p = minscan();
    *maxScanStatus_p = maxscan();
    *backendTypeStatus_p = backend();
    *fillRawPointingStatus_p = fillrawpointing();
    *fillRawFocusStatus_p = fillrawfocus();
    *fillLagsStatus_p = filllags();
    *vvStatus_p = vv();
    *smoothStatus_p = smooth();
    *useHighCalStatus_p = usehighcal();
    *compressCalColStatus_p = compresscalcols();
    *useBiasStatus_p = usebias();
    *oneacsmsStatus_p = oneacsms();
    *dcbiasStatus_p = dcbias();
    *minbiasfactorStatus_p = minbiasfactor();
    *fixbadlagsStatus_p = fixbadlags();

    return status_p;
}

Bool gbtmsfiller::setproject(const String &project) 
{
    Bool result = False;
    File projFile(project);
    result = projFile.exists() && projFile.isDirectory();

    // set this even if it isn't okay
    projectDir_p = Directory(projFile);
    // this always results in cleaning up things
    // since the user has indicated a change in the
    // project directory - i.e. this is just like starting over
    cleanup();
    // be sure the true msroot name is set
    set_truemsroot();
    if (!result) {
	LogIO os(LogOrigin("gbtmsfiller","setproject(const String &project)"));
	os << LogIO::SEVERE << "This project directory " << project;
	if (!projFile.exists()) {
	    os << " does not exist.";
	} else {
	    os << " is not a directory.";
	}
	os << LogIO::POST;
    }
    return result;
}

const String &gbtmsfiller::project()
{
    return projectDir_p.path().originalName();
}

Bool gbtmsfiller::setbackend(const String &backend)
{
    backend_p = GBTScanLogReader::type(backend);
    return True;
}

const String gbtmsfiller::backend()
{
    return GBTScanLogReader::name(backend_p);
}

Bool gbtmsfiller::setmsdirectory(const String &msdirectory) 
{
    Bool result = False;
    File msFile(msdirectory);
    if (msFile.exists() && msFile.isDirectory()) {
	msDir_p = Directory(msFile);
	// this always results in cleaning up things
	// since the user has indicated a change in the
	// output MS directory - i.e. this is just like starting over
	cleanup();
	result = True;
    } else {
	LogIO os(LogOrigin("gbtmsfiller","setmsdirectory(const String &msdirectory)"));
	os << LogIO::SEVERE << "This ms directory " << msdirectory;
	if (!msFile.exists()) {
	    os << " does not exist.";
	} else {
	    os << " is not a directory.";
	}
	os << LogIO::POST;
    }
    return result;
}

const String &gbtmsfiller::msdirectory()
{
    return msDir_p.path().originalName();
}

Bool gbtmsfiller::setmsrootname(const String &msrootname)
{
    msroot_p = msrootname;
    set_truemsroot();
    return True;
}

const String &gbtmsfiller::msrootname()
{
    return truemsroot_p;
}

Bool gbtmsfiller::setmintime(const String &mintime)
{
    return makeTime(minTime_p, mintime);
}

Bool gbtmsfiller::setmaxtime(const String &maxtime)
{
    return makeTime(maxTime_p, maxtime);
}

const String gbtmsfiller::mintime()
{
    return minTime_p.string(MVTime::FITS, 8);
}

const String gbtmsfiller::maxtime()
{
    return maxTime_p.string(MVTime::FITS, 8);
}

Bool gbtmsfiller::setobject(const String &object)
{
    object_p = object;
    objectRegex_p = Regex::fromPattern(object_p);
    return True;
}

const String &gbtmsfiller::object() { return object_p;}

Bool gbtmsfiller::setminscan(Int minscan) { 
    if (isattached(True)) reader_p->setMinscan(minscan);
    if (!reader_p) initialMinScan_p = minscan;
    return True;
}

Int gbtmsfiller::minscan() { 
    return (isattached(True) ? reader_p->minscan() : initialMinScan_p);
}

Bool gbtmsfiller::setmaxscan(Int maxscan) { 
    if (isattached(True)) reader_p->setMaxscan(maxscan);
    if (!reader_p) initialMaxScan_p = maxscan;
    return True;
}

Int gbtmsfiller::maxscan() { 
    return (isattached(True) ? reader_p->maxscan() : initialMaxScan_p);
}

Bool gbtmsfiller::newms()
{
    // nothing yet
    return False;
}

Vector<String> gbtmsfiller::methods() const {
    Vector<String> method(NUMBER_METHODS);
    method(ISATTACHED) = "isattached";
    method(FILLNEXT) = "fillnext";
    method(FILLALL) = "fillall";
    method(MORE) = "more";
    method(UPDATE) = "update";
    method(STATUS) = "status";
    method(SETPROJECT) = "setproject";
    method(PROJECT) = "project";
    method(SETBACKEND) = "setbackend";
    method(BACKEND) = "backend";
    method(SETMSDIRECTORY) = "setmsdirectory";
    method(MSDIRECTORY) = "msdirectory";
    method(SETMSROOTNAME) = "setmsrootname";
    method(MSROOTNAME) = "msrootname";
    method(SETMINTIME) = "setmintime";
    method(MINTIME) = "mintime";
    method(SETMAXTIME) = "setmaxtime";
    method(MAXTIME) = "maxtime";
    method(SETOBJECT) = "setobject";
    method(OBJECT) = "object";
    method(SETMINSCAN) = "setminscan";
    method(MINSCAN) = "minscan";
    method(SETMAXSCAN) = "setmaxscan";
    method(MAXSCAN) = "maxscan";
    method(FILLRAWPOINTING) = "fillrawpointing";
    method(FILLRAWFOCUS) = "fillrawfocus";
    method(FILLLAGS) = "filllags";
    method(SETFILLRAWPOINTING) = "setfillrawpointing";
    method(SETFILLRAWFOCUS) = "setfillrawfocus";
    method(SETFILLLAGS) = "setfilllags";
    method(VV) = "vv";
    method(SETVV) = "setvv";
    method(SMOOTH) = "smooth";
    method(SETSMOOTH) = "setsmooth";
    method(SETUSEHIGHCAL) = "setusehighcal";
    method(USEHIGHCAL) = "usehighcal";
    method(SETCOMPRESSCALCOLS) = "setcompresscalcols";
    method(COMPRESSCALCOLS) = "compresscalcols";
    method(SETUSEBIAS) = "setusebias";
    method(USEBIAS) = "usebias";
    method(SETONEACSMS) = "setoneacsms";
    method(ONEACSMS) = "oneacsms";
    method(NEWMS) = "newms";
    method(SETDCBIAS) = "setdcbias";
    method(DCBIAS) = "dcbias";
    method(SETMINBIASFACTOR) = "setminbiasfactor";
    method(MINBIASFACTOR) = "minbiasfactor";
    method(SETFIXBADLAGS) = "setfixbadlags";
    method(FIXBADLAGS) = "fixbadlags";
    return method;
}

Vector<String> gbtmsfiller::noTraceMethods() const
{
    Vector<String> tmp(45);
    Vector<String> meths(methods());
    // don't trace the query methods
    tmp(0) = meths(ISATTACHED);
    tmp(1) = meths(MORE);
    tmp(2) = meths(STATUS);
    tmp(3) = meths(SETPROJECT);
    tmp(4) = meths(PROJECT);
    tmp(5) = meths(SETBACKEND);
    tmp(6) = meths(BACKEND);
    tmp(7) = meths(SETMSDIRECTORY);
    tmp(8) = meths(MSDIRECTORY);
    tmp(9) = meths(SETMSROOTNAME);
    tmp(10) = meths(MSROOTNAME);
    tmp(11) = meths(SETMINTIME);
    tmp(12) = meths(MINTIME);
    tmp(13) = meths(SETMAXTIME);
    tmp(14) = meths(MAXTIME);
    tmp(15) = meths(SETOBJECT);
    tmp(16) = meths(OBJECT);
    tmp(17) = meths(SETMINSCAN);
    tmp(18) = meths(MINSCAN);
    tmp(19) = meths(SETMAXSCAN);
    tmp(20) = meths(MAXSCAN);
    tmp(21) = meths(SETFILLRAWPOINTING);
    tmp(22) = meths(FILLRAWPOINTING);
    tmp(23) = meths(SETFILLRAWFOCUS);
    tmp(24) = meths(FILLRAWFOCUS);
    tmp(25) = meths(SETFILLLAGS);
    tmp(26) = meths(FILLLAGS);
    tmp(27) = meths(VV);
    tmp(28) = meths(SETVV);
    tmp(29) = meths(SMOOTH);
    tmp(30) = meths(SETSMOOTH);
    tmp(31) = meths(SETUSEHIGHCAL);
    tmp(32) = meths(USEHIGHCAL);
    tmp(33) = meths(SETCOMPRESSCALCOLS);
    tmp(34) = meths(COMPRESSCALCOLS);
    tmp(35) = meths(SETUSEBIAS);
    tmp(36) = meths(USEBIAS);
    tmp(37) = meths(SETONEACSMS);
    tmp(38) = meths(SETONEACSMS);
    tmp(39) = meths(SETDCBIAS);
    tmp(40) = meths(DCBIAS);
    tmp(41) = meths(SETMINBIASFACTOR);
    tmp(42) = meths(MINBIASFACTOR);
    tmp(43) = meths(SETFIXBADLAGS);
    tmp(44) = meths(FIXBADLAGS);
    return tmp;
}

MethodResult gbtmsfiller::runMethod(uInt which,
				    ParameterSet &parameters,
				    Bool runMethod)
{
    static String returnvalString = "returnval";

    switch (which) {
    case ISATTACHED:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = isattached();
	}
	break;
    case FILLNEXT:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = fillnext();
	}
	break;
    case FILLALL:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = fillall();
	}
	break;
    case MORE:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = more();
	}
	break;
    case UPDATE:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = update();
	}
	break;
    case STATUS:
	{
	    Parameter<GlishRecord> returnval(parameters, returnvalString,
					     ParameterSet::Out);
	    GlishRecord glStatus;
	    glStatus.fromRecord(status());
	    if (runMethod) returnval() = glStatus;
	}
	break;
    case SETPROJECT:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String projectString = "project";
	    Parameter<String> projectParm(parameters, projectString,
					  ParameterSet::In);
	    if (runMethod) returnval() = setproject(projectParm());
	}
	break;
    case PROJECT:
	{
	    Parameter<String> returnval(parameters, returnvalString,
                                        ParameterSet::Out);
            if (runMethod) returnval() = project();
	}
	break;
    case SETBACKEND: 
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String backendString = "backend";
	    Parameter<String> backendParm(parameters, backendString,
					  ParameterSet::In);
	    if (runMethod) returnval() = setbackend(backendParm());
	}
	break;
    case BACKEND:
	{
	    Parameter<String> returnval(parameters, returnvalString,
                                        ParameterSet::Out);
            if (runMethod) returnval() = backend();
	}
	break;
    case SETMSDIRECTORY:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String projectString = "msdirectory";
	    Parameter<String> msdirectoryParm(parameters, projectString,
					      ParameterSet::In);
	    if (runMethod) returnval() = setmsdirectory(msdirectoryParm());
	}
	break;
    case MSDIRECTORY:
	{
	    Parameter<String> returnval(parameters, returnvalString,
                                        ParameterSet::Out);
            if (runMethod) returnval() = msdirectory();
	}
	break;
    case SETMSROOTNAME: 
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String msrootnameString = "msrootname";
	    Parameter<String> msrootnameParm(parameters, msrootnameString,
					     ParameterSet::In);
	    if (runMethod) returnval() = setmsrootname(msrootnameParm());
	}
	break;
    case MSROOTNAME: 
	{
	    Parameter<String> returnval(parameters, returnvalString,
                                        ParameterSet::Out);
            if (runMethod) returnval() = msrootname();
	}
	break;
    case SETMINTIME: 
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String mintimeString = "mintime";
	    Parameter<String> mintimeParm(parameters, mintimeString,
					  ParameterSet::In);
	    if (runMethod) returnval() = setmintime(mintimeParm());
	}
	break;
    case MINTIME: 
	{
	    Parameter<String> returnval(parameters, returnvalString,
                                        ParameterSet::Out);
            if (runMethod) returnval() = mintime();
	}
	break;
    case SETMAXTIME: 
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String maxtimeString = "maxtime";
	    Parameter<String> maxtimeParm(parameters, maxtimeString,
					  ParameterSet::In);
	    if (runMethod) returnval() = setmaxtime(maxtimeParm());
	}
	break;
    case MAXTIME: 
	{
	    Parameter<String> returnval(parameters, returnvalString,
                                        ParameterSet::Out);
            if (runMethod) returnval() = maxtime();
	}
	break;
    case SETOBJECT: 
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String objectString = "object";
	    Parameter<String> objectParm(parameters, objectString,
					 ParameterSet::In);
	    if (runMethod) returnval() = setobject(objectParm());
	}
	break;
    case OBJECT: 
	{
	    Parameter<String> returnval(parameters, returnvalString,
                                        ParameterSet::Out);
            if (runMethod) returnval() = object();
	}
	break;
    case SETMINSCAN: 
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String minscanString = "minscan";
	    Parameter<Int> minscanParm(parameters, minscanString,
				       ParameterSet::In);
	    if (runMethod) returnval() = setminscan(minscanParm());
	}
	break;
    case MINSCAN: 
	{
	    Parameter<Int> returnval(parameters, returnvalString,
				     ParameterSet::Out);
            if (runMethod) returnval() = minscan();
	}
	break;
    case SETMAXSCAN: 
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String maxscanString = "maxscan";
	    Parameter<Int> maxscanParm(parameters, maxscanString,
				      ParameterSet::In);
	    if (runMethod) returnval() = setmaxscan(maxscanParm());
	}
	break;
    case MAXSCAN: 
	{
	    Parameter<Int> returnval(parameters, returnvalString,
				     ParameterSet::Out);
            if (runMethod) returnval() = maxscan();
	}
	break;
    case SETFILLRAWPOINTING:
	{
	    Parameter<Bool> returnval(parameters, returnvalString, 
				      ParameterSet::Out);
	    static String fillrawpointingString = "fillrawpointing";
	    Parameter<Bool> fillrawpointingParm(parameters, fillrawpointingString,
						ParameterSet::In);
	    if (runMethod) returnval() = setfillrawpointing(fillrawpointingParm());
	}
	break;
    case FILLRAWPOINTING:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = fillrawpointing();
	}
	break;
    case SETFILLRAWFOCUS:
	{
	    Parameter<Bool> returnval(parameters, returnvalString, 
				      ParameterSet::Out);
	    static String fillrawfocusString = "fillrawfocus";
	    Parameter<Bool> fillrawfocusParm(parameters, fillrawfocusString,
						ParameterSet::In);
	    if (runMethod) returnval() = setfillrawfocus(fillrawfocusParm());
	}
	break;
    case FILLRAWFOCUS:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = fillrawfocus();
	}
	break;
     case SETFILLLAGS:
	{
	    Parameter<Bool> returnval(parameters, returnvalString, 
				      ParameterSet::Out);
	    static String filllagsString = "filllags";
	    Parameter<Bool> filllagsParm(parameters, filllagsString,
					 ParameterSet::In);
	    if (runMethod) returnval() = setfilllags(filllagsParm());
	}
	break;
    case FILLLAGS:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = filllags();
	}
	break;
    case SETVV:
	{
	    Parameter<Bool> returnval(parameters, returnvalString, 
				      ParameterSet::Out);
	    static String vvString = "vv";
	    Parameter<String> vvParm(parameters, vvString,
				     ParameterSet::In);
	    if (runMethod) returnval() = setvv(vvParm());
	}
	break;
    case VV:
	{
	    Parameter<String> returnval(parameters, returnvalString,
					ParameterSet::Out);
	    if (runMethod) returnval() = vv();
	}
	break;
    case SETSMOOTH:
	{
	    Parameter<Bool> returnval(parameters, returnvalString, 
				      ParameterSet::Out);
	    static String smoothString = "smooth";
	    Parameter<String> smoothParm(parameters, smoothString,
					 ParameterSet::In);
	    if (runMethod) returnval() = setsmooth(smoothParm());
	}
	break;
    case SMOOTH:
	{
	    Parameter<String> returnval(parameters, returnvalString,
					ParameterSet::Out);
	    if (runMethod) returnval() = smooth();
	}
	break;
    case SETUSEHIGHCAL:
	{
	    Parameter<Bool> returnval(parameters, returnvalString, 
				      ParameterSet::Out);
	    static String usehighcalString = "usehighcal";
	    Parameter<Bool> usehighcalParm(parameters, usehighcalString,
					   ParameterSet::In);
	    if (runMethod) returnval() = setusehighcal(usehighcalParm());
	}
	break;
    case USEHIGHCAL:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = usehighcal();
	}
	break;
    case SETCOMPRESSCALCOLS:
	{
	    Parameter<Bool> returnval(parameters, returnvalString, 
				      ParameterSet::Out);
	    static String compresscalcolsString = "compresscalcols";
	    Parameter<Bool> compresscalcolsParm(parameters, compresscalcolsString,
						ParameterSet::In);
	    if (runMethod) returnval() = setcompresscalcols(compresscalcolsParm());
	}
	break;
    case COMPRESSCALCOLS:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = compresscalcols();
	}
	break;
    case SETUSEBIAS:
	{
	    Parameter<Bool> returnval(parameters, returnvalString, 
				      ParameterSet::Out);
	    static String usebiasString = "usebias";
	    Parameter<Bool> usebiasParm(parameters, usebiasString,
					ParameterSet::In);
	    if (runMethod) returnval() = setusebias(usebiasParm());
	}
	break;
    case USEBIAS:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = usebias();
	}
	break;
    case SETONEACSMS:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String oneacsmsString = "oneacsms";
	    Parameter<Bool> oneacsmsParm(parameters, oneacsmsString,
					      ParameterSet::In);
	    if (runMethod) returnval() = setoneacsms(oneacsmsParm());
	}
	break;
    case ONEACSMS:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = oneacsms();
	}
	break;
    case SETDCBIAS: 
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String dcbiasString = "dcbias";
	    Parameter<Double> dcbiasParm(parameters, dcbiasString,
					 ParameterSet::In);
	    if (runMethod) returnval() = setdcbias(dcbiasParm());
	}
	break;
    case DCBIAS: 
	{
	    Parameter<Double> returnval(parameters, returnvalString,
					ParameterSet::Out);
            if (runMethod) returnval() = dcbias();
	}
	break;
    case SETMINBIASFACTOR: 
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    static String minbiasfactorString = "minbiasfactor";
	    Parameter<Int> minbiasfactorParm(parameters, minbiasfactorString,
					     ParameterSet::In);
	    if (runMethod) returnval() = setminbiasfactor(minbiasfactorParm());
	}
	break;
    case MINBIASFACTOR: 
	{
	    Parameter<Int> returnval(parameters, returnvalString,
				     ParameterSet::Out);
            if (runMethod) returnval() = minbiasfactor();
	}
	break;
    case SETFIXBADLAGS:
	{
	    Parameter<Bool> returnval(parameters, returnvalString, 
				      ParameterSet::Out);
	    static String fixbadlagsString = "fixbadlags";
	    Parameter<Bool> fixbadlagsParm(parameters, fixbadlagsString,
					ParameterSet::In);
	    if (runMethod) returnval() = setfixbadlags(fixbadlagsParm());
	}
	break;
    case FIXBADLAGS:
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
	    if (runMethod) returnval() = fixbadlags();
	}
	break;
    case NEWMS: 
	{
	    Parameter<Bool> returnval(parameters, returnvalString,
				      ParameterSet::Out);
            if (runMethod) returnval() = newms();
	}
	break;
    default:
	return error("No such method");
    }
    return ok();
}

void gbtmsfiller::init(Bool silent)
{
    if (reader_p) {
	initialMinScan_p = reader_p->minscan();
	initialMaxScan_p = reader_p->maxscan();
    }
    cleanup();
    // open the ScanLog.fits file
    Path scanLogPath(projectDir_p.path());
    scanLogPath.append("ScanLog.fits");
    File scanLogFile(scanLogPath);
    if (scanLogFile.exists() && scanLogFile.isRegular()) {
	reader_p = new GBTScanLogReader(scanLogFile, initialMinScan_p,
					initialMaxScan_p);
	// check for problems here and emit an error message
	if (!reader_p && !silent) {
	    LogIO os(LogOrigin("gbtmsfiller","init()"));
	    os << LogIO::SEVERE
	       << "Unable to open " << scanLogPath.absoluteName()
	       << LogIO::POST;
	} else if (!reader_p->isValid()) {
	    LogIO os(LogOrigin("gbtmsfiller","init()"));
	    os << LogIO::SEVERE
	       << "The scan log file " << scanLogPath.absoluteName()
	       << " is unexpectedly invalid"
	       << LogIO::POST;
	}
	more_p = reader_p->scan() != -1;
	// do some initial stuff - positioning past end of times in MSs
	// as available, marking backends as ok to fill if known

	// open all of the known types of MeasurementSets
	// this is annoying because it means that if this project has used
	// a back end at all, it will be opened here for the duration of
	// this object.  Instead, it would be better to do this as necessary
	// but unfortunately I need to know what the last filled time was.
	// This should be unnecessary once there is a fill log table
	// associated with each project.
	
	// create fillers for all of the known types and remember the min times as appropriate
	String mshead = msdirectory() + "/" + truemsroot_p;
	dcrFiller_p = new GBTDCRFiller(mshead + 
				       GBTScanLogReader::name(GBTScanLogReader::DCR), 
				       objectRegex_p);
	holoFiller_p = new GBTHoloFiller(mshead + 
					 GBTScanLogReader::name(GBTScanLogReader::HOLOGRAPHY), 
					 objectRegex_p);
	spFiller_p = new GBTSPFiller(mshead + 
				     GBTScanLogReader::name(GBTScanLogReader::SP), 
				     objectRegex_p);
	acsFiller_p = new GBTACSFiller(mshead + 
				       GBTScanLogReader::name(GBTScanLogReader::ACS),
				       objectRegex_p);
	acsAFiller_p = new GBTACSFiller(mshead + 
					GBTScanLogReader::name(GBTScanLogReader::ACS) + "_A",
					objectRegex_p);
	acsBFiller_p = new GBTACSFiller(mshead + 
					GBTScanLogReader::name(GBTScanLogReader::ACS) + "_B", 
					objectRegex_p);
	acsCFiller_p = new GBTACSFiller(mshead + 
					GBTScanLogReader::name(GBTScanLogReader::ACS) + "_C", 
					objectRegex_p);
	acsDFiller_p = new GBTACSFiller(mshead + 
					GBTScanLogReader::name(GBTScanLogReader::ACS) + "_D", 
					objectRegex_p);
	AlwaysAssert(dcrFiller_p && holoFiller_p && spFiller_p && acsFiller_p && 
		     acsAFiller_p && acsBFiller_p && acsCFiller_p && acsDFiller_p, AipsError);
	if (dcrFiller_p->startTime() > minTime_p) minTime_p = dcrFiller_p->startTime();
	if (holoFiller_p->startTime() > minTime_p) minTime_p = holoFiller_p->startTime();
	if (spFiller_p->startTime() > minTime_p) minTime_p = spFiller_p->startTime();
	if (acsFiller_p->startTime() > minTime_p) minTime_p = acsFiller_p->startTime();
	if (acsAFiller_p->startTime() > minTime_p) minTime_p = acsAFiller_p->startTime();
	if (acsBFiller_p->startTime() > minTime_p) minTime_p = acsBFiller_p->startTime();
	if (acsCFiller_p->startTime() > minTime_p) minTime_p = acsCFiller_p->startTime();
	if (acsDFiller_p->startTime() > minTime_p) minTime_p = acsDFiller_p->startTime();
	
	// skip uninteresting scans
	// stop at the first scan which is interesting or end of log
	// we don't use this here
	Block<Int> backends;
	Block<String> backendFiles;
	while (more() && !isInteresting(backends, backendFiles)) {
	    next();
	}
    } else {
	if (!silent) {
	    LogIO os(LogOrigin("gbtmsfiller","init()"));
	    os << LogIO::SEVERE << "The ScanLog.fits file in " 
	       << projectDir_p.path().absoluteName()
	       << " could not be opened because ";
	    if (!scanLogFile.exists()) {
		os << "it does not exist.";
	    } else {
		os << "it is not a regular file.";
	    }
	    os << LogIO::POST;
	}
    }
}

void gbtmsfiller::cleanup() {
    delete dcrFiller_p;
    dcrFiller_p = 0;
    delete holoFiller_p;
    holoFiller_p = 0;
    delete spFiller_p;
    spFiller_p = 0;
    delete acsFiller_p;
    acsFiller_p = 0;
    delete acsAFiller_p;
    acsAFiller_p = 0;
    delete acsBFiller_p;
    acsBFiller_p = 0;
    delete acsCFiller_p;
    acsCFiller_p = 0;
    delete acsDFiller_p;
    acsDFiller_p = 0;
    okToFillDCR_p = okToFillHolo_p = okToFillSP_p = False;
    okToFillAcs_p = False;
    delete reader_p;
    reader_p = 0;
    more_p = False;
}


void gbtmsfiller::set_truemsroot()
{
    if (msroot_p.length() == 0) {
	truemsroot_p = projectDir_p.path().baseName() + "_";
    } else {
	truemsroot_p = msroot_p;
    }
}


Bool gbtmsfiller::makeTime(MVTime &toTime, 
			   const String &fromString)
{
    Quantum<Double> res;
    Bool result = MVTime::read(res, fromString);
    if (result) {
	toTime = res;
	if (minTime_p > maxTime_p) {
	    MVTime tmp = minTime_p;
	    minTime_p = maxTime_p;
	    maxTime_p = tmp;
	}
    }
    return result;
}

void gbtmsfiller::initStatusRecord()
{
    RecordDesc desc;
    desc.addField("attached", TpBool);
    desc.addField("nextscan", TpInt);
    desc.addField("nextdmjd", TpDouble);
    desc.addField("nexttimestamp", TpDouble);
    desc.addField("project", TpString);
    desc.addField("msdirectory", TpString);
    desc.addField("object", TpString);
    desc.addField("mintime", TpString);
    desc.addField("maxtime", TpString);
    desc.addField("minscan", TpInt);
    desc.addField("maxscan", TpInt);
    desc.addField("fillrawpointing", TpBool);
    desc.addField("fillrawfocus", TpBool);
    desc.addField("filllags", TpBool);
    desc.addField("vv", TpString);
    desc.addField("smooth", TpString);
    desc.addField("usehighcal", TpBool);
    desc.addField("compresscalcols", TpBool);
    desc.addField("usebias", TpBool);
    desc.addField("backendtype", TpString);
    desc.addField("oneacsms", TpBool);
    desc.addField("dcbias", TpDouble);
    desc.addField("minbiasfactor", TpInt);
    desc.addField("fixbadlags", TpBool);

    // status for each possible backend
    RecordDesc backendDesc;
    backendDesc.addField("ms", TpString);
    backendDesc.addField("nrows", TpInt);
    desc.addField("dcr", backendDesc);
    desc.addField("sp", backendDesc);
    desc.addField("holo", backendDesc);
    RecordDesc acsDesc;
    acsDesc.addField("ABCD", backendDesc);
    acsDesc.addField("A", backendDesc);
    acsDesc.addField("B", backendDesc);
    acsDesc.addField("C", backendDesc);
    acsDesc.addField("D", backendDesc);
    desc.addField("acs", acsDesc);

    // restructure the status record
    status_p.restructure(desc);

    // attach the pointers
    attachedStatus_p.attachToRecord(status_p,"attached");
    nextScanStatus_p.attachToRecord(status_p,"nextscan");
    nextDmjdStatus_p.attachToRecord(status_p,"nextdmjd");
    nextTimeStampStatus_p.attachToRecord(status_p,"nexttimestamp");
    projectStatus_p.attachToRecord(status_p,"project");
    msDirStatus_p.attachToRecord(status_p,"msdirectory");
    objectStatus_p.attachToRecord(status_p,"object");
    minTimeStatus_p.attachToRecord(status_p,"mintime");
    maxTimeStatus_p.attachToRecord(status_p,"maxtime");
    minScanStatus_p.attachToRecord(status_p,"minscan");
    maxScanStatus_p.attachToRecord(status_p,"maxscan");
    fillRawPointingStatus_p.attachToRecord(status_p,"fillrawpointing");
    fillRawFocusStatus_p.attachToRecord(status_p,"fillrawfocus");
    fillLagsStatus_p.attachToRecord(status_p,"filllags");
    vvStatus_p.attachToRecord(status_p,"vv");
    smoothStatus_p.attachToRecord(status_p,"smooth");
    useHighCalStatus_p.attachToRecord(status_p,"usehighcal");
    compressCalColStatus_p.attachToRecord(status_p, "compresscalcols");
    useBiasStatus_p.attachToRecord(status_p, "usebias");
    backendTypeStatus_p.attachToRecord(status_p,"backendtype");
    oneacsmsStatus_p.attachToRecord(status_p,"oneacsms");
    dcbiasStatus_p.attachToRecord(status_p, "dcbias");
    minbiasfactorStatus_p.attachToRecord(status_p, "minbiasfactor");
    fixbadlagsStatus_p.attachToRecord(status_p, "fixbadlags");

    dcrMSStatus_p.attachToRecord(status_p.rwSubRecord("dcr"),"ms");
    dcrMSSize_p.attachToRecord(status_p.rwSubRecord("dcr"),"nrows");
    holoMSStatus_p.attachToRecord(status_p.rwSubRecord("holo"),"ms");
    holoMSSize_p.attachToRecord(status_p.rwSubRecord("holo"),"nrows");
    spMSStatus_p.attachToRecord(status_p.rwSubRecord("sp"),"ms");
    spMSSize_p.attachToRecord(status_p.rwSubRecord("sp"),"nrows");
    acsMSStatus_p.attachToRecord(status_p.rwSubRecord("acs").rwSubRecord("ABCD"),"ms");
    acsMSSize_p.attachToRecord(status_p.rwSubRecord("acs").rwSubRecord("ABCD"),"nrows");
    acsAMSStatus_p.attachToRecord(status_p.rwSubRecord("acs").rwSubRecord("A"),"ms");
    acsAMSSize_p.attachToRecord(status_p.rwSubRecord("acs").rwSubRecord("A"),"nrows");
    acsBMSStatus_p.attachToRecord(status_p.rwSubRecord("acs").rwSubRecord("B"),"ms");
    acsBMSSize_p.attachToRecord(status_p.rwSubRecord("acs").rwSubRecord("B"),"nrows");
    acsCMSStatus_p.attachToRecord(status_p.rwSubRecord("acs").rwSubRecord("C"),"ms");
    acsCMSSize_p.attachToRecord(status_p.rwSubRecord("acs").rwSubRecord("C"),"nrows");
    acsDMSStatus_p.attachToRecord(status_p.rwSubRecord("acs").rwSubRecord("D"),"ms");
    acsDMSSize_p.attachToRecord(status_p.rwSubRecord("acs").rwSubRecord("D"),"nrows");
}

Bool gbtmsfiller::isInteresting(Block<Int> &backends, Block<String> &backendFiles)
{
    Bool result = False;
    // nothing is okay to fill at this point
    okToFillDCR_p = okToFillHolo_p = okToFillSP_p = okToFillAcs_p = False;
    // reader_p must already be attached, no sanity check here
    if (reader_p->timeStamp() <= maxTime_p &&
	reader_p->timeStamp() >= minTime_p) {
	backends = reader_p->backends();
	backendFiles = reader_p->backendFiles();
	okToFillDCR_p = reader_p->dcrfile().length() > 0 && 
	    (backend_p == GBTScanLogReader::ANY || backend_p == GBTScanLogReader::DCR);
	okToFillHolo_p = reader_p->holofile().length() > 0 && 
	    (backend_p == GBTScanLogReader::ANY || backend_p == GBTScanLogReader::HOLOGRAPHY);
	okToFillSP_p = reader_p->spfile().length() > 0 && 
	    (backend_p == GBTScanLogReader::ANY || backend_p == GBTScanLogReader::SP);
	okToFillAcs_p = reader_p->acsfiles().nelements() > 0 &&
	    (backend_p == GBTScanLogReader::ANY || backend_p == GBTScanLogReader::ACS);
	result = True;
    }
    return result;
}

void gbtmsfiller::next() {
    if (reader_p->more()) {
	reader_p->next();
	more_p = reader_p->scan() != -1;
    } else {
	// then we've just processed the last one in the file
	more_p = False;
    }
}

void gbtmsfiller::acsFill(const Vector<String> &files, GBTACSFiller *filler)
{
    filler->fill(files, 
		 reader_p->dapFiles(),
		 reader_p->ifManagerFile(),
		 reader_p->rxCalInfoFiles(),
		 reader_p->GOFile(),
		 reader_p->antennaFile(),
		 reader_p->masterState(),
		 reader_p->LO1A(),
		 reader_p->LO1B(),
		 fillOptions_p);
}

void gbtmsfiller::doStatus(GBTBackendFiller *filler,
			   RecordFieldPtr<String> &msStatusField,
			   RecordFieldPtr<Int> &msSizeField)
{
    if (filler && !filler->ms().isNull()) {
	*msStatusField = filler->ms().tableName();
	*msSizeField = filler->ms().nrow();
    } else {
	*msStatusField = "<unset>";
	*msSizeField = -1;
    }
}
