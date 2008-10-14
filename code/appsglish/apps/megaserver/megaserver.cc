//# megaserver.cc: Mega-server to combine DO executables for memory efficiency
//# Copyright (C) 1996,1997,1998,1999,2000,2001
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: megaserver.cc,v 19.7 2005/11/07 21:17:04 wyoung Exp $

//# Includes

#include <casa/aips.h>
#include <tasking/Tasking.h>
#include <tasking/Tasking/ObjectController.h>
#include <tasking/Tasking/ApplicationObject.h>

#include <appsglish/measures/DOmeasures.h>
#include <appsglish/quanta/DOquanta.h>
#include <appsglish/calibrater/DOcalibrater.h>

#include <appsglish/app_image/imageFactory.h>
#include <appsglish/app_image/imagepolFactory.h>
#include <appsglish/app_image/coordsysFactory.h>
#include <images/Images/FITSImage.h>
#include <images/Images/MIRIADImage.h>
#include <appsglish/ms/msFactory.h>
#include <appsglish/ms/ms2fromms1Factory.h>
#include <appsglish/imager/imagerFactory.h>
#include <appsglish/componentlist/componentFactory.h>
#include <appsglish/deconvolver/deconvolverFactory.h>

#include <appsglish/misc/aipsrc.h>
#include <appsglish/misc/sysinfo.h>
#include <appsglish/misc/logtable.h>
#include <appsglish/misc/appstate.h>
#include <appsglish/misc/os.h>
#include <casa/Logging/LogSink.h>
#include <casa/Logging/StreamLogSink.h>
#include <casa/iostream.h>

// PABLO IO trace library
#ifdef PABLO_IO
#include "PabloTrace.h"
#endif

#include <casa/namespace.h>
int main(int argc, char **argv) {

  // Extract the server name
  String executable(*argv);
  String res[1024];
  Int maxn=1024;
  Int i=split(executable, res, maxn, "/");
  String lastWord = res[i-1];

  // Special handling of the logger for server misc
  if (lastWord.matches("misc")) {
    // Logging to a table is in this server, so replace the global sink
    // with cerr to prevent infinite recursions.
    LogSinkInterface *sink = new StreamLogSink(LogMessage::WARN, &cerr);
    LogSink::globalSink(sink);
  };

  // Register the PGPLotter create function.
  ApplicationEnvironment::registerPGPlotter();
  // Register the functions to create a FITSImage or MIRIADImage object.
  FITSImage::registerOpenFunction();
  MIRIADImage::registerOpenFunction();

  // Create the object controller
  ObjectController controller(argc, argv);

  // Add constructor factory methods for the selected server type.
  // Case server_type of:
  //
  // Measures server
  if (lastWord.matches("measures")) {
    controller.addMaker("measures", new StandardObjectFactory<measures>);

    // Quanta server
  } else if (lastWord.matches("quanta")) {
    controller.addMaker("quanta", new StandardObjectFactory<quanta>);

    // Image server
  } else if (lastWord.matches("app_image")) {
    String name = "image";
    imageFactory *factory = new imageFactory;
    controller.addMaker(name, factory);
    imagepolFactory *factory2 = new imagepolFactory;
    controller.addMaker(String("imagepol"), factory2);
    coordsysFactory *factory3 = new coordsysFactory;
    controller.addMaker(String("coordsys"), factory3);

    // Ms server
  } else if (lastWord.matches("ms")) {
    controller.addMaker("ms", new msFactory);
    controller.addMaker("ms2fromms1", new ms2fromms1Factory);

    // Misc server
  } else if (lastWord.matches("misc")) {
    controller.addMaker("aipsrc", new StandardObjectFactory<aipsrc>);
    controller.addMaker("sysinfo", new StandardObjectFactory<sysinfo>);
    controller.addMaker("logtable", new StandardObjectFactory<logtable>);
    controller.addMaker("appstate", new StandardObjectFactory<appstate>);
    controller.addMaker("os", new StandardObjectFactory<os>);

    // Imager server
  } else if (lastWord.matches("imager")) {
#ifdef PABLO_IO
    traceEvent(1,"Entering imager.cc",18);
#endif
    controller.addMaker("imager", new imagerFactory);

    // Calibrater server
  } else if (lastWord.matches("calibrater")) {
    String name = "calibrater";
    calibraterFactory *factory = new calibraterFactory;
    controller.addMaker(name, factory);

    // Componentlist server
  } else if (lastWord.matches("componentlist")) {
    controller.addMaker("componentlist", new componentFactory);

    // Deconvolver server
  } else if (lastWord.matches("deconvolver")) {
    controller.addMaker("deconvolver", new deconvolverFactory);
  };

  // Loop, processing events
  controller.loop();

  if (lastWord.matches("imager")) {
#ifdef PABLO_IO
    traceEvent(1,"Exiting imager.cc",17);
#endif
  };

  return 0;
}






