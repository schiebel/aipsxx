//# StreamLogSink.cc: Send log messages to an ostream.
//# Copyright (C) 1996,2001,2003
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
//# $Id: StreamLogSink.cc,v 19.5 2004/11/30 17:50:17 ddebonis Exp $

#include <casa/Logging/StreamLogSink.h>
#include <casa/Logging/LogFilter.h>
#include <casa/iostream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

String StreamLogSink::localId( ) {
    return String("StreamLogSink");
}

String StreamLogSink::id( ) const {
    return String("StreamLogSink");
}

StreamLogSink::StreamLogSink(ostream *theStream) : stream_p(theStream)
{
    if (stream_p == 0) {
        stream_p = &cerr;
    }
}

StreamLogSink::StreamLogSink(LogMessage::Priority filter,
			     ostream *theStream)
  : LogSinkInterface(LogFilter(filter)), stream_p(theStream)
{
    if (stream_p == 0) {
        stream_p = &cerr;
    }
}

StreamLogSink::StreamLogSink(const LogFilterInterface &filter,
			     ostream *theStream)
  : LogSinkInterface(filter), stream_p(theStream)
{
    if (stream_p == 0) {
        stream_p = &cerr;
    }
}

StreamLogSink::StreamLogSink(const StreamLogSink &other)
  : LogSinkInterface(other), stream_p(other.stream_p)
{
    // Nothing
}

StreamLogSink &StreamLogSink::operator=(const StreamLogSink &other)
{
    if (this != &other) {
        LogSinkInterface &This = *this;
	This = other;
	stream_p = other.stream_p;
    }
    return *this;
}

StreamLogSink::~StreamLogSink()
{
    stream_p = 0;
}

Bool StreamLogSink::postLocally(const LogMessage &message) 
{
    Bool doPost = filter().pass(message);
    if (doPost) {
        // Cast away const
        ostream &os = *((ostream *)stream_p);
	os << message << endl;
    }
    return doPost;
}

void StreamLogSink::flush(Bool)
{
    stream_p->flush();
}

} //# NAMESPACE CASA - END

