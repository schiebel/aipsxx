//# tRebinImage.cc: This program tests RebinImage
//# Copyright (C) 2001,2002,2004
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
//# $Id: tRebinImage.cc,v 1.6 2004/11/30 17:50:28 ddebonis Exp $

//# Includes
#include <casa/Inputs/Input.h>
#include <casa/Containers/Block.h>
#include <coordinates/Coordinates/CoordinateSystem.h>
#include <coordinates/Coordinates/CoordinateUtil.h>
#include <images/Images/TempImage.h>
#include <images/Images/SubImage.h>
#include <images/Images/PagedImage.h>
#include <images/Images/RebinImage.h>
#include <images/Images/ImageRegion.h>
#include <lattices/Lattices/TiledShape.h>
#include <lattices/Lattices/LatticeUtilities.h>
#include <casa/Logging/LogIO.h>
#include <casa/Utilities/Assert.h>
#include <casa/iostream.h>



#include <casa/namespace.h>
int main (int argc, char **argv) {

try {

   Input inputs(1);
   inputs.version ("$Revision: 1.6 $");

// Get inputs

   inputs.create("in", "", "Input image name");
   inputs.create("factors", "-10", "factors");
   inputs.create("save", "False", "Save output ?");
   inputs.create("shape", "-10", "Shape");
   inputs.readArguments(argc, argv);
   const String in = inputs.getString("in");
   const Bool save = inputs.getBool("save");
   const Block<Int> factorsU(inputs.getIntArray("factors"));
   const Block<Int> shapeU(inputs.getIntArray("shape"));
//
   Int maxMBInMemory = -1;
   ImageInterface<Float>* pIm = 0;

   IPosition shapeIn;
   if (in.empty()) {
      if (shapeU.nelements()>0) {
         if (shapeU.nelements()==1 && shapeU[0]==-10) {
            shapeIn = IPosition(2, 32, 32);
         } else {
            shapeIn.resize(shapeU.nelements());
            for (uInt i=0; i<shapeIn.nelements(); i++) shapeIn(i) = shapeU[i];
         }
      }
//
      TiledShape shape2(shapeIn);
      CoordinateSystem cSys = CoordinateUtil::makeCoordinateSystem(shapeIn, False);
//
      pIm = new TempImage<Float>(shape2, cSys, maxMBInMemory);
      pIm->set(1.0);
//
      TempLattice<Bool> inMask(shape2, maxMBInMemory);
      inMask.set(True);
      TempImage<Float>* pTemp = dynamic_cast<TempImage<Float>*>(pIm);
      pTemp->attachMask(inMask);
   } else {
      pIm = new PagedImage<Float>(in);
      shapeIn = pIm->shape();
   }
//
   IPosition factors(pIm->ndim(), 1);
   if (factorsU.nelements()>0) {
      if (factorsU.nelements()==1 && factorsU[0]==-10) {
         factors = 2;
      } else {
         factors.resize(factorsU.nelements());
         for (uInt i=0; i<factors.nelements(); i++) factors(i) = factorsU[i];
      }
   }
//
   RebinImage<Float> rebinner(*pIm, factors);
   IPosition shapeOut = rebinner.shape();
   cerr << "factors = " << factors << endl;
   cerr << "shapeIn, shapeOut = " << shapeIn << shapeOut << endl;
   CoordinateSystem cSysOut = rebinner.coordinates();
//
   {
      ImageInterface<Float>* pImOut = 0;
      if (save) {
         pImOut = new PagedImage<Float>(shapeOut, cSysOut, String("outFile"));
      } else {
         pImOut = new TempImage<Float>(shapeOut, cSysOut, maxMBInMemory);
      }
      cerr << "Nice shapes = " << rebinner.niceCursorShape() << pImOut->niceCursorShape() << endl;
      String maskName = pImOut->makeUniqueRegionName(String("mask"), 0);    
      pImOut->makeMask(maskName, True, True, True, True);

// Do it

      LogIO os(LogOrigin("tRebinImage", "main()", WHERE));
      LatticeUtilities::copyDataAndMask (os, *pImOut, rebinner, False);
      delete pImOut;
    }
//
    delete pIm;

} catch (AipsError x) {
     cerr << "aipserror: error " << x.getMesg() << endl;
     return 1;
} 

return 0;

}


