//# pimager.cc: Parallelized version of imager.cc
//# Copyright (C) 1996,1998,1999,2000,2002
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
//# $Id: pimager.cc,v 19.4 2004/11/30 17:50:09 ddebonis Exp $

#include <pimagerFactory.h>
#include <tasking/Tasking/ObjectController.h>
#include <tasking/Tasking.h>

#include <synthesis/Parallel/Applicator.h>
#include <synthesis/Parallel/PabloIO.h>

#ifdef PABLO_IO
#include "PabloTrace.h"
#endif

#include <casa/iostream.h>


#include <casa/namespace.h>

// The applicator is global.
namespace casa {
extern Applicator applicator;
}

int main(int argc, char **argv) {    

  // Register the PGPLotter creator.
  ApplicationEnvironment::registerPGPlotter();

// Moved PabloIO::init into the Applicator
//#ifdef PABLO_IO
  //PabloIO::init(argc, argv);
//#endif
  // Initialize the applicator, which handles the parallelization
  // transport layer, and related communications.
  applicator.init(argc, argv);

  // Only the master executes the ObjectController, and is
  // accessible from Glish through the AIPS++ DO interface;
  // all other processes spawn and do their work in applicator::init().
  if(applicator.isController()){ 
    for(int i=0;i<argc;i++)
      cerr << argv[i] << " ";
    cerr << endl;
    ObjectController controller(argc, argv);

#ifdef PABLO_IO
    traceEvent(1,"Entering pimager.cc",19);
#endif

    controller.addMaker("pimager", new pimagerFactory);
    controller.loop();

  }

#ifdef PABLO_IO
  traceEvent(1,"Exiting pimager.cc",18);
  PabloIO::terminate();
#endif

  return 0;
}
