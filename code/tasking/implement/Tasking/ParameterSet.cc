//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1999,2001
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
//# $Id: ParameterSet.cc,v 19.4 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ParameterSet.h>
#include <tasking/Tasking/ParamAccBase.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/Logging/LogIO.h>
#include <casa/Utilities/Assert.h>

namespace casa { //# NAMESPACE CASA - BEGIN

ParameterSet::ParameterSet()
: values_p(new GlishRecord),
  accessors_p(static_cast<void *>(0))
{}

// ParameterSet::ParameterSet(const ParameterSet &other)
//     : values_p(0), accessors_p(static_cast<void *>(0))
// {
//     copy(other);
// }

// ParameterSet &ParameterSet::operator=(const ParameterSet &other)
// {
//     if (this != &other) {
// 	copy(other);
//     }

//     return *this;
// }

void ParameterSet::clear()
{
    values_p = 0;
    Int n = accessors_p.ndefined();
    while (--n >= 0) {
        delete (ParameterAccessorBase *)(accessors_p.getVal(n));
    }
    accessors_p.clear();
}

ParameterSet::~ParameterSet()
{
    clear();
}

ParameterAccessorBase *ParameterSet::accessor(const String &which)
{
    void **ptrtoval = accessors_p.isDefined(which);
    if (ptrtoval) {
        void *val = *ptrtoval;
	return (ParameterAccessorBase *)val;
    } else {
        return 0;
    }
}

void ParameterSet::setAccessor(const String &which, ParameterAccessorBase *&val)
{
    if (accessors_p.isDefined(which)) {
	LogOrigin OR("ParameterSet", "setAccessor(const String &which, "
		     "ParameterAccessorBase *&val)", WHERE);
	LogMessage msg(OR, LogMessage::SEVERE);
	msg.message(String("Attempt to define parameter ") + which +
		    " more than once");
	LogSink::postGloballyThenThrow(msg);
    }

    accessors_p(which) = val;
    val = 0;
}

// void ParameterSet::copy(const ParameterSet &other)
// {
//     if (values_p) {
// 	clear();
//     }
//     values_p = new GlishRecord(*(other.values_p));
//     AlwaysAssert(values_p, AipsError);
//     accessors_p = other.accessors_p;
//     Int n = accessors_p.ndefined();
//     while (--n >= 0) {
// 	ParameterAccessorBase *ptr = accessor(n)->clone();
// 	AlwaysAssert(ptr, AipsError);
// 	ptr->attach(values_p);
// 	accessors_p.getVal(n) = ptr;
//     }
// }


const CountedPtr<GlishRecord> &ParameterSet::parameterRecord(Bool &error,
							     String &errorMsg)
{
    Int n = accessors_p.ndefined();
    error = True;
    errorMsg = "";
    String tmpmsg;
    Bool tmperr;
    while (--n >= 0) {
	ParameterAccessorBase *ptr = accessor(n);
	AlwaysAssert(ptr, AipsError);
	if (ptr->direction() != In) {
	    tmperr = ptr->copyOut(tmpmsg);
	    if (!tmperr) {
		error = False;
		if (errorMsg.length() > 0) {
		    errorMsg += "\n";
		}
		errorMsg += tmpmsg;
	    }
	}
	// Reset the accessor to free up resources, and to put it into a null
	// state so that, e.g., you don't have to worry about resizing arrays.
	// (This is not needed anymore after the change on 23-Mar-99, GvD)
	//	ptr->reset();
    }
    return values_p;
}

void ParameterSet::setParameterRecord(GlishRecord *&fromNew,
				      Bool &error, String &errorMsg)
{
    AlwaysAssert(fromNew, AipsError);
    values_p = fromNew;
    fromNew = 0;

    Int n = accessors_p.ndefined();
    error = True;
    errorMsg = "";
    String tmpmsg;
    Bool tmperr;
    while (--n >= 0) {
	ParameterAccessorBase *ptr = accessor(n);
	AlwaysAssert(ptr, AipsError);
	ptr->attach(values());
	if (ptr->direction() != Out) {
	    tmperr = ptr->copyIn(tmpmsg);
	    if (!tmperr) {
		error = False;
		if (errorMsg.length() > 0) {
		    errorMsg += "\n";
		}
		errorMsg += tmpmsg;
	    }
	}
    }
}

void ParameterSet::setParameterRecord(const GlishRecord &rec,
				      Bool &error, String &errorMsg)
{
    GlishRecord *ptr = new GlishRecord(rec);
    setParameterRecord(ptr, error, errorMsg);
}

} //# NAMESPACE CASA - END

