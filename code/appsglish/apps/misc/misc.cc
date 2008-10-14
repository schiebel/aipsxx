//# misc.cc: server for miscellaneous DO's
//# Copyright (C) 1996,1997,1999,2001
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
//# $Id: misc.cc,v 19.3 2004/11/30 17:50:08 ddebonis Exp $

#include <tasking/Tasking.h>
#include <aipsrc.h>
#include <sysinfo.h>
#include <logtable.h>
#include <appstate.h>
#include <os.h>

#include <casa/Logging/LogSink.h>
#include <casa/Logging/StreamLogSink.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
int main(int argc, char **argv)
{
    // Logging to a table is in this server, so replce the global sink
    // with cerr to prevent infinite recursions.
    LogSinkInterface *sink = new StreamLogSink(LogMessage::WARN, &cerr);
    LogSink::globalSink(sink);

    ObjectController controller(argc, argv);

    controller.addMaker("aipsrc", new StandardObjectFactory<aipsrc>);
    controller.addMaker("sysinfo", new StandardObjectFactory<sysinfo>);
    controller.addMaker("logtable", new StandardObjectFactory<logtable>);
    controller.addMaker("appstate", new StandardObjectFactory<appstate>);
    controller.addMaker("os", new StandardObjectFactory<os>);

    controller.loop();
    return 0;
}
