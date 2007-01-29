//# GlishLogSink.cc: Send log messages as Glish events.
//# Copyright (C) 1996,1997,1998,2001,2003
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
//# $Id: GlishLogSink.cc,v 19.7 2004/11/30 17:51:11 ddebonis Exp $

#include <casa/Arrays/Vector.h>
#include <tasking/Tasking/GlishLogSink.h>
#include <casa/System/AppInfo.h>
#include <tasking/Tasking/ObjectIDRecord.h>
#include <casa/Logging/StreamLogSink.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/OS/Time.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Logging/LogFilter.h>
#include <casa/Logging/LogIO.h>
#include <casa/System/Aipsrc.h>

#include <casa/OS/Memory.h>

#include <casa/iostream.h>
#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

String GlishLogSink::localId( ) {
    return String("GlishLogSink");
}

String GlishLogSink::id( ) const {
    return String("GlishLogSink");
}

GlishLogSink::GlishLogSink(LogMessage::Priority filter, 
	     CountedPtr<GlishSysEventSource> eventSource)
  : LogSinkInterface(LogFilter(filter)), event_source_p(eventSource)
{
    // Nothing
}

GlishLogSink::GlishLogSink(const LogFilterInterface &filter, 
	     CountedPtr<GlishSysEventSource> eventSource)
  : LogSinkInterface(filter), event_source_p(eventSource)
{
    // Nothing
}

GlishLogSink::GlishLogSink(const GlishLogSink &other)
  : LogSinkInterface(other), event_source_p(other.event_source_p)
{
    // Nothing
}

GlishLogSink &GlishLogSink::operator=(const GlishLogSink &other)
{
    if (this != &other) {
        LogSinkInterface *This = this;
	(*This) = other;
	event_source_p = other.event_source_p;
    }
    return *this;
}
  
// Make file-static for exception emulation.
    static StreamLogSink backup(&cerr);
    static GlishRecord logRecord;
    static MVTime formatter;
Bool GlishLogSink::postLocally(const LogMessage &message)
{
    //***
    //*** If you change the format of the emitted record, you *MUST* *MUST*
    //*** *MUST* modify the comments in the .h file to describe the new record
    //*** layout.
    //***
    static Bool init = False;
    static Double tzoffset = 0.0;
    if (!init) {
	init = True;
	formatter.setFormat(MVTime::DMY);
	tzoffset = AppInfo::timeZone();
    }

    if (! filter().pass(message)) {
        return False;
    }

    if (event_source_p->hasInterpreter() && event_source_p->connected()) {
        logRecord.add("message", message.message());
	logRecord.add("time_mjd", 
		      message.messageTime().modifiedJulianDay());
	// When formatting use timezone!
	formatter = message.messageTime().modifiedJulianDay() + tzoffset;
	logRecord.add("time_string", formatter.string());
	logRecord.add("priority", message.toString(message.priority()));

	// Source code location.
	logRecord.add("location", message.origin().location());
	GlishRecord tmp;

	// ObjectID as a record.
	OIDtoRecord (message.origin().objectID(), tmp, "");
	logRecord.add("id", tmp);

	// # As a hack, every log message say how much memory we are using.
	Double mem = Double(Memory::allocatedMemoryInBytes())/1024/1024;
	logRecord.add("_memory", mem);

	event_source_p->postEvent("log", logRecord);
	return True;
    } else {
        backup.filter(this->filter());
        return backup.postLocally(message);
    }
}

} //# NAMESPACE CASA - END

