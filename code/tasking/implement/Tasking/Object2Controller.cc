//# ObjectController2.cc: Functions which aren't needed all the time.
//# Copyright (C) 1996,1997,1999,2001,2003
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
//# $Id: Object2Controller.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/ObjectController.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <casa/OS/Memory.h>
#include <tables/Tables/Table.h>

namespace casa { //# NAMESPACE CASA - BEGIN

ObjectController::ObjectController(int argc, char **argv,
				   LogSinkInterface *globalSink)
    : makers_p(static_cast<void *>(0))
{
    init(argc, argv, globalSink, relinquishLockIdleFunction);
}


Bool ObjectController::relinquishLockIdleFunction(Int elapsedTime)
{
    if (elapsedTime >= longIdleTime) {
	Table::relinquishAutoLocks(True);
	// If we've been idle for a long time try giving memory back to the
	// OS
	Memory::releaseMemory();
    } else {
	Table::relinquishAutoLocks(False);
    }
    // Unilaterally send our memory use every time. Send it *AFTER* doing our
    // lock relinquishing etc.
    ObjectController *controller = 
        ApplicationEnvironment::objectController();
    if (controller) {
        // If we are attached say how much memory we are using before we
        // sign off
        controller->sendMemoryUse();
    }
    return (Table::nAutoLocks() != 0);
}

} //# NAMESPACE CASA - END

