//# GlishLogSink.h: Send log messages as Glish events.
//# Copyright (C) 1996,1998,2002
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
//# $Id: tGlishLogSink.cc,v 19.3 2004/11/30 17:51:12 ddebonis Exp $

#include <casa/Logging.h>
#include <tasking/Tasking/GlishLogSink.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
int main(int argc, char **argv)
{
    // This test sends a log message to Glish if started from Glish, otherwise
    // it sends it to cerr. If started from glish it should have reasonably
    // good test coverage, the .exec file results in poor coverage.

//     GlishLogSink(const LogFilter &filter, 
// 		 CountedPtr<GlishSysEventSource> eventSource);
    CountedPtr<GlishSysEventSource> ptr(new GlishSysEventSource(argc, argv));
    LogFilter defaultFilter;
    GlishLogSink gs1(defaultFilter, ptr);

//     GlishLogSink(const GlishLogSink &other);
//     GlishLogSink &operator=(const GlishLogSink &other);
    GlishLogSink *gs2 = new GlishLogSink(gs1);
    gs1 = *gs2;


//     virtual Bool postLocally(const LogMessage &message);
    LogSinkInterface *lsi = gs2;
    LogSink::globalSink(lsi);
    LogIO io;
    io << "ABCDEFGHIJKLMNOPQRSTUVWXYZ" << LogIO::POST;

    cout << "OK" << endl;
    return 0;
}
