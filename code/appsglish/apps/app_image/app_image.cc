//# app_image.cc: Server for image-related distributed objects
//# Copyright (C) 1996,1999,2000
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
//# $Id: app_image.cc,v 19.5 2005/03/16 15:04:46 gvandiep Exp $

#include <imageFactory.h>
#include <imagepolFactory.h>
#include <coordsysFactory.h>
#include <images/Images/FITSImage.h>
#include <images/Images/MIRIADImage.h>
#include <tasking/Tasking/ObjectController.h>
#include <tasking/Tasking.h>

#include <casa/namespace.h>
int main(int argc, char **argv)
{
    // Register the PGPLotter create function.
    ApplicationEnvironment::registerPGPlotter();
    // Register the functions to create a FITSImage or MIRIADImage object.
    FITSImage::registerOpenFunction();
    MIRIADImage::registerOpenFunction();

    ObjectController controller(argc, argv);
//
    imageFactory* factory = new imageFactory;
    controller.addMaker(String("image"), factory);
//
    imagepolFactory* factory2 = new imagepolFactory;
    controller.addMaker(String("imagepol"), factory2);
//
    coordsysFactory* factory3 = new coordsysFactory;
    controller.addMaker(String("coordsys"), factory3);
//
    controller.loop();
    return 0;
}
