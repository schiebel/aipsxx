//# tRegionhandler.cc:  test the regions in the Regionhandler classes
//# Copyright (C) 2000,2001
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or(at your option)
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
//# $Id: tRegionHandler.cc,v 19.4 2004/11/30 17:50:28 ddebonis Exp $

#include <images/Images/RegionHandlerMemory.h>
#include <images/Images/RegionHandlerTable.h>

#include <casa/Arrays/Vector.h>
#include <casa/Arrays/IPosition.h>
#include <lattices/Lattices/PagedArray.h>
#include <lattices/Lattices/LCSlicer.h>
#include <lattices/Lattices/LCPagedMask.h>
#include <images/Images/ImageRegion.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/Table.h>
#include <casa/OS/File.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>
#include <casa/iostream.h>


#include <casa/namespace.h>
Table theTable;

Table& getTable (void*, Bool)
{
  return theTable;
}

void doIt (RegionHandler& reghand)
{
  IPosition shape(2,32,8);
  LCSlicer box1(IPosition(2,0), shape-1);
  const ImageRegion* regptr;

// Create a region as a mask and add it to the image.
// The region won't be found in the regions.
  reghand.defineRegion ("reg1", box1, RegionHandler::Masks);
  AlwaysAssertExit (reghand.hasRegion ("reg1"));
  AlwaysAssertExit (! reghand.hasRegion ("reg2"));
  regptr = reghand.getRegion("reg1");
  AlwaysAssertExit (regptr != 0);
  AlwaysAssertExit (*regptr == ImageRegion(box1));
  delete regptr;

// Define the region as the default.
  reghand.setDefaultMask ("reg1");
  AlwaysAssertExit (reghand.getDefaultMask() == "reg1");

// Define the region in the regions group and check it can be found.
  reghand.defineRegion ("regr1", box1, RegionHandler::Regions);
  regptr = reghand.getRegion ("regr1", RegionHandler::Regions, False);
  AlwaysAssertExit (regptr != 0);
  delete regptr;
  regptr = reghand.getRegion ("regr1", RegionHandler::Masks, False);
  AlwaysAssertExit (regptr == 0);
  regptr = reghand.getRegion ("regr1", RegionHandler::Any, False);
  AlwaysAssertExit (regptr != 0);
  delete regptr;

// Get all region names.
  Vector<String> names = reghand.regionNames();
  AlwaysAssertExit (names.nelements() == 2);
  AlwaysAssertExit (names(0) == "reg1"  ||  names(1) == "reg1");
  AlwaysAssertExit (names(0) == "regr1"  ||  names(1) == "regr1");
  Vector<String> rnames = reghand.regionNames (RegionHandler::Regions);
  AlwaysAssertExit (rnames.nelements() == 1);
  AlwaysAssertExit (rnames(0) == "regr1");
  Vector<String> mnames = reghand.regionNames (RegionHandler::Masks);
  AlwaysAssertExit (mnames.nelements() == 1);
  AlwaysAssertExit (mnames(0) == "reg1");

// Rename the region in the regions group and check it can be found.
  reghand.renameRegion ("regr2", "regr1", RegionHandler::Regions);
  regptr = reghand.getRegion ("regr2", RegionHandler::Regions, False);
  AlwaysAssertExit (regptr != 0);
  delete regptr;
  regptr = reghand.getRegion ("regr2", RegionHandler::Masks, False);
  AlwaysAssertExit (regptr == 0);
  regptr = reghand.getRegion ("regr2", RegionHandler::Any, False);
  AlwaysAssertExit (regptr != 0);
  delete regptr;
  regptr = reghand.getRegion ("regr1", RegionHandler::Any, False);
  AlwaysAssertExit (regptr == 0);

// Create a lattice and mask and make it default region.
  PagedArray<Float> lattice (shape, "tRegionHandler_tmp.lat");
  reghand.defineRegion ("reg2", reghand.makeMask (lattice, "reg2"),
			RegionHandler::Masks);
  reghand.setDefaultMask ("reg2");
  AlwaysAssertExit (reghand.getDefaultMask() == "reg2");

// Rename that mask and make sure the table and default mask are renamed too.
  reghand.renameRegion ("reg2n", "reg2");
  AlwaysAssertExit (reghand.hasRegion ("reg2n"));
  AlwaysAssertExit (! reghand.hasRegion ("reg2"));
  AlwaysAssertExit (reghand.getDefaultMask() == "reg2n");

// Make a unique name.
  AlwaysAssertExit (reghand.makeUniqueRegionName ("reg2n") == "reg2n1");
  AlwaysAssertExit (reghand.makeUniqueRegionName ("reg2n", 3) == "reg2n3");
  AlwaysAssertExit (reghand.makeUniqueRegionName ("reg2na", 3) == "reg2na3");

// Now get the mask as a region and check it is correct.
  regptr = reghand.getRegion (reghand.getDefaultMask());
  AlwaysAssertExit (regptr != 0);
  AlwaysAssertExit (regptr->isLCRegion());
  delete regptr;

// Remove the region, which should also remove the default mask and the table.
  reghand.removeRegion ("reg2n");
  AlwaysAssertExit (! reghand.hasRegion ("reg2n"));
  AlwaysAssertExit (reghand.getDefaultMask() == "");
  AlwaysAssertExit (! File("tRegionHandler_tmp.lat/reg2n").exists());
}


int main()
{
  try {
    RegionHandlerMemory regmem;
    doIt (regmem);

    SetupNewTable newtab ("tRegionHandler_tmp.data", TableDesc(), Table::New);
    theTable = Table(newtab);
    RegionHandlerTable regtab (getTable, 0);
    doIt (regtab);
  } catch (AipsError x) {
    cerr << "Unexpected exception: " << x.getMesg() << endl;
    exit(1);
  } 
  cout << "ok" << endl;
  exit(0);
}
