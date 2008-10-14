//# imager.cc: Server for sky-related distributed objects
//# Copyright (C) 1996,1998,1999,2000
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
//# $Id: imager.cc,v 19.5 2005/02/09 16:26:53 ddebonis Exp $

#include <imagerFactory.h>
#include <tasking/Tasking/ObjectController.h>
#include <tasking/Tasking.h>
#include <synthesis/Parallel/PabloIO.h>
#ifdef PABLO_IO
#include <PabloTrace.h>
#endif
#include <casa/namespace.h>

int main(int argc, char **argv) {
#ifdef PABLO_IO
  PabloIO::init(argc, argv);
  traceEvent(1,"Entering imager.cc",18);
#endif

  ApplicationEnvironment::registerPGPlotter();

  ObjectController controller(argc, argv);
  

  controller.addMaker("imager", new imagerFactory);
  controller.loop();

#ifdef PABLO_IO
  traceEvent(1,"Exiting imager.cc",17);
  PabloIO::terminate();
#endif

  return 0;
}
