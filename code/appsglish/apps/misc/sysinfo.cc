//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,2001,2002
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
//# $Id: sysinfo.cc,v 19.8 2006/04/11 14:16:17 dschieb Exp $


#include <../misc/sysinfo.h>
#include <casa/version.h>
#include <casa/OS/HostInfo.h>

#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/Parameter.h>

#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>
#include <casa/OS/EnvVar.h>
#include <casa/Logging/LogSink.h>
#include <casa/Logging/LogMessage.h>

#include <casa/sstream.h>

#include <float.h>
#include <limits.h>


#include <casa/namespace.h>
sysinfo::sysinfo()
{
    // Nothing
}

sysinfo::sysinfo(const sysinfo &other) : ApplicationObject(other)
{
    // Nothing
}

sysinfo &sysinfo::operator=(const sysinfo &)
{
    return *this;
}

sysinfo::~sysinfo()
{
    // Nothing
}

Int sysinfo::numcpu()
{
    return HostInfo::numCPUs();
}

Int sysinfo::memory()
{
    Int result = HostInfo::memoryTotal()*(1024);
    if ( result < 0 ) result = INT_MAX;
    return result;
}

void sysinfo::version(Int &majorv, Int &minorv, Int &patch, String &date,
		      String &info, String &formatted, Bool dolog) const
{
    majorv = VersionInfo::majorVersion();
    minorv = VersionInfo::minorVersion();
    patch  = VersionInfo::patch();
    date   = VersionInfo::date();
    info   = VersionInfo::info();
    ostringstream os;
    VersionInfo::report(os);
    formatted = String(os);

    if (dolog) {
	LogOrigin OR("sysinfo","version(Int &majorv, Int &minorv, Int &patch, "
	     "String &date, String &info, String &formatted, Bool dolog)",
	     id(), WHERE);
	LogMessage msg(OR);
	msg.message(formatted).line(__LINE__);;
	LogSink::postGlobally(msg);
    }
}

static String aipspath_component(Int which)
{

    String var (EnvironmentVariable::get("AIPSPATH"));
    if (var.empty()) {
	return "UNKNOWN";
    }

    String fields[4];
    Int num = split(var, fields, 4, String(" "));
    String retval;
    if (num == 4) {
        retval = fields[which];
    } else {
	retval = "MALFORMED_AIPSPATH";
    }
    return retval;
}

String sysinfo::arch()
{
    return aipspath_component(1);
}

String sysinfo::root()
{
    return aipspath_component(0);
}

String sysinfo::site()
{
    return aipspath_component(2);
}

String sysinfo::host()
{
    return aipspath_component(3);
}

String sysinfo::className() const
{
    return "sysinfo";
}

Vector<String> sysinfo::methods() const
{
    Vector<String> method(7);
    method(0) = "numcpu";
    method(1) = "memory";
    method(2) = "version";
    method(3) = "arch";
    method(4) = "root";
    method(5) = "site";
    method(6) = "host";
    return method;
}

Vector<String> sysinfo::noTraceMethods() const
{
    Vector<String> method(7);
    method(0) = "numcpu";
    method(1) = "memory";
    method(2) = "version";
    method(3) = "arch";
    method(4) = "root";
    method(5) = "site";
    method(6) = "host";
    return method;
}


MethodResult sysinfo::runMethod(uInt which, 
				ParameterSet &inputRecord,
				Bool runMethod)
{
    switch(which) {
    case 0:   // numcpu
        {
	    static String returnvalString = "returnval";
            Parameter<Int> returnval(inputRecord, returnvalString,
				     ParameterSet::Out);
            if (runMethod) {
                returnval() = numcpu();
            }
        }
    break;
    case 1:   // memory
        {
	    static String returnvalString = "returnval";
            Parameter<Int> returnval(inputRecord, returnvalString,
				     ParameterSet::Out);
            if (runMethod) {
                returnval() = memory();
            }
        }
    break;
    case 2:   // version
        {
	    Parameter<Int>        majorv(inputRecord, "major", ParameterSet::Out);
	    Parameter<Int>        minorv(inputRecord, "minor", ParameterSet::Out);
	    Parameter<Int>        patch(inputRecord, "patch", ParameterSet::Out);
	    Parameter<String>      date(inputRecord, "date", ParameterSet::Out);
	    Parameter<String>      info(inputRecord, "info", ParameterSet::Out);
	    Parameter<String> formatted(inputRecord, "formatted", 
					ParameterSet::Out);
	    Parameter<Bool>       dolog(inputRecord, "dolog", ParameterSet::In);
	    if (runMethod) {
		version(majorv(), minorv(), patch(), date(), info(),
			formatted(), dolog());
	    }
        }
    break;
    case 3:   // arch
        {
	    static String returnvalString = "returnval";
            Parameter<String> returnval(inputRecord, returnvalString,
				     ParameterSet::Out);
            if (runMethod) {
                returnval() = arch();
            }
        }
    break;
    case 4:   // root
        {
	    static String returnvalString = "returnval";
            Parameter<String> returnval(inputRecord, returnvalString,
				     ParameterSet::Out);
            if (runMethod) {
                returnval() = root();
            }
        }
    break;
    case 5:   // site
        {
	    static String returnvalString = "returnval";
            Parameter<String> returnval(inputRecord, returnvalString,
				     ParameterSet::Out);
            if (runMethod) {
                returnval() = site();
            }
        }
    break;
    case 6:   // host
        {
	    static String returnvalString = "returnval";
            Parameter<String> returnval(inputRecord, returnvalString,
				     ParameterSet::Out);
            if (runMethod) {
                returnval() = host();
            }
        }
    break;
    default:
        return error("Unknown method");
    }

    return ok();
}

