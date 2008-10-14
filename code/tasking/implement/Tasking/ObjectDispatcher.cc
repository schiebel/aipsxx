//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2003,2004
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
//# $Id: ObjectDispatcher.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ObjectDispatcher.h>
#include <tasking/Tasking/ParameterSet.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <tasking/Tasking/MethodResult.h>

#include <tasking/Glish/GlishRecord.h>

#include <casa/Arrays/Vector.h>
#include <casa/Utilities/Assert.h>
#include <casa/OS/Timer.h>

#include <casa/Logging/LogIO.h>

#include <casa/sstream.h>


namespace casa { //# NAMESPACE CASA - BEGIN

ObjectDispatcher::ObjectDispatcher(ApplicationObject *&fromNew)
: object_p(fromNew),
  method_lookup_p(-1),
  tracers_p(0)
{
    fromNew = 0;
    AlwaysAssert(object_p != 0, AipsError);

    Vector<String> methods = object_p->methods();
    uInt n = methods.nelements();
    if (n == 0) {
	return;
    }
    uInt i;
    for (i=0; i<n; i++) {
	method_lookup_p.define(methods(i), i);
    }
    tracers_p.resize(n);
    tracers_p.set(True);
    Vector<String> dull = object_p->noTraceMethods();
    for (i=0; i<dull.nelements(); i++) {
	Int which = method_lookup_p(dull(i));
	if (which <0) {
	    LogMessage msg(LogOrigin("ObjectDispatcher",
				     "ObjectDisplatcher(ApplicationObject *&fromNew",
				     WHERE));
	    msg.message(String("Cannot turn off tracing for method ") + dull(i) +
			" - No such method!").priority(LogMessage::SEVERE);
	    LogSink::postGlobally(msg);
	}
	tracers_p[which] = False;
    }
}

ObjectDispatcher::~ObjectDispatcher()
{
    delete object_p;
}

Vector<String>
ObjectDispatcher::methods()
{
    AlwaysAssert(object_p != 0, AipsError);

    return object_p->methods();
}

MethodResult ObjectDispatcher::runMethod
                          (const String &method,
			   GlishRecord *&parametersFromNew,
			   CountedPtr<GlishRecord> &returnedParameters)
{
    if (!parametersFromNew) {
	return "Null parameters provided";
    }

    // Look up the method.
    Int which = method_lookup_p(method);
    if (which < 0) {
	return "method is not defined";
    }

    // Setup the parameters
    Bool error;
    String errorMsg;

    static LogIO log_p(LogOrigin("ObjectDispatcher",
        "runMethod(const String &method,GlishRecord *&parametersFromNew,"
	"CountedPtr<GlishRecord> &returned)", WHERE));

//  if (tracers_p[which]) {
// 	// Trace the parameters if requested
// 	ostringstream buffer;
// 	buffer << "Running " << object_p->className() << "::" << 
// 	    method << "\n";
// 	uInt nfields = parametersFromNew->nelements();
// 	for (uInt i=0; i<nfields; i++) {
// 	    String paramName = parametersFromNew->name(i);
// 	    if (paramName[0] == '_') {
// 		// Names begininning with underscores are reserved for the
// 		// implementation
// 		continue;
// 	    }
// 	    GlishValue gvalue = parametersFromNew->get(i);
// 	    buffer << "\t" << paramName << "=";
// 	    if (gvalue.nelements() <= 10) {
// 		buffer << gvalue << endl;
// 	    } else {
// 		buffer << gvalue.nelements() << " element ";
// 		if (gvalue.type() == GlishValue::RECORD) {
// 		    buffer << "record\n";
// 		} else {
// 		    buffer << "array\n";
// 		}
// 	    }
// 	}
// 	log_p << String(buffer) << LogIO::NORMAL << LogIO::POST;
//  }

    Timer timer;

    ParameterSet params;
    params.doSetup(True);
    object_p->runMethod(which, params, False);
    params.doSetup(False);
    params.setParameterRecord(parametersFromNew, error, errorMsg);
    if (!error) {
	return errorMsg;
    }
    
    if (tracers_p[which]) {
	ostringstream buffer;
	buffer << "Starting " << object_p->className() << "::" << method << 
	  "\n";
	log_p << String(buffer) << LogIO::NORMAL << LogIO::POST;
    }

    MethodResult result = object_p->runMethod(which, params, True);

    if (tracers_p[which]) {
	// Trace the CPU time
	ostringstream buffer;
	buffer << "Finished " << object_p->className() << "::" << method << 
	  "\n";
	// Should print the output records here
	timer.show(buffer);
	log_p << String(buffer) << LogIO::NORMAL << LogIO::POST;
    }

    if (result.ok()) {
	returnedParameters = params.parameterRecord (error, errorMsg);
	if (!error) {
	    result = errorMsg;
	    returnedParameters = 0;
	}
    } else {
	returnedParameters = 0;
    }
    return result;
}

} //# NAMESPACE CASA - END

