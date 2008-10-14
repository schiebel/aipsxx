//# DOpimager.cc: this implements the pimager DO
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: DOpimager.cc,v 19.13 2005/12/06 20:18:50 wyoung Exp $

#include <appsglish/pimager/DOpimager.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayMath.h>

#include <casa/Logging.h>
#include <casa/Logging/LogIO.h>
#include <casa/Logging/LogSink.h>
#include <casa/Logging/LogMessage.h>

#include <casa/OS/File.h>
#include <casa/Containers/Record.h>

#include <tables/Tables/TableParse.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/TableLock.h>
#include <tables/Tables/ExprNode.h>

#include <casa/BasicSL/String.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/Fallible.h>
#include <casa/Utilities/CompositeNumber.h>

#include <casa/BasicSL/Constants.h>

#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>

#include <synthesis/MeasurementEquations/ClarkCleanProgress.h>
#include <synthesis/MeasurementComponents/PClarkCleanImageSkyModel.h>
#include <msvis/MSVis/VisSet.h>
#include <msvis/MSVis/VisSetUtil.h>
#include <synthesis/MeasurementComponents/TimeVarVisJones.h>

#include <measures/Measures/Stokes.h>
#include <casa/Quanta/UnitMap.h>
#include <casa/Quanta/UnitVal.h>
#include <casa/Quanta/MVAngle.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <casa/Quanta/MVEpoch.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/UVWMachine.h>

#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <ms/MeasurementSets/MSSummary.h>
#include <ms/MeasurementSets/MSDopplerUtil.h>
#include <synthesis/MeasurementEquations/SkyEquation.h>
//#include <synthesis/MeasurementEquations/PSkyEquation.h>
//#include <trial/MeasurementEquations/MFSkyEquation.h>
#include <synthesis/MeasurementEquations/VisEquation.h>
#include <synthesis/MeasurementEquations/StokesImageUtil.h>

#include <synthesis/MeasurementComponents/ImageSkyModel.h>
#include <synthesis/MeasurementComponents/CEMemImageSkyModel.h>
#include <synthesis/MeasurementComponents/MFCEMemImageSkyModel.h>
//#include <trial/MeasurementComponents/PMFCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/MFCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/MFMSCleanImageSkyModel.h>
//#include <synthesis/MeasurementComponents/PWFCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/HogbomCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/MSCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/NNLSImageSkyModel.h>
#include <synthesis/MeasurementComponents/GridFT.h>
#include <synthesis/MeasurementComponents/SDGrid.h>
#include <synthesis/MeasurementComponents/SimpleComponentFTMachine.h>
#include <synthesis/MeasurementComponents/SimpCompGridMachine.h>
#include <synthesis/MeasurementComponents/VPSkyJones.h>
#include <synthesis/MeasurementComponents/ReadMSAlgorithm.h>
#include <synthesis/MeasurementComponents/PBMath.h>

#include <lattices/Lattices/TiledLineStepper.h> 
#include <lattices/Lattices/LatticeIterator.h> 
#include <lattices/Lattices/LatticeExpr.h> 
#include <lattices/Lattices/LCBox.h> 
#include <lattices/Lattices/LatticeFFT.h>

#include <images/Images/ImageRegrid.h>
#include <images/Images/PagedImage.h>
#include <images/Images/ImageInfo.h>

#include <coordinates/Coordinates/CoordinateSystem.h>
#include <coordinates/Coordinates/DirectionCoordinate.h>
#include <coordinates/Coordinates/SpectralCoordinate.h>
#include <coordinates/Coordinates/StokesCoordinate.h>
#include <coordinates/Coordinates/Projection.h>
#include <coordinates/Coordinates/ObsInfo.h>

#include <components/ComponentModels/ComponentList.h>
#include <components/ComponentModels/ConstantSpectrum.h>
#include <components/ComponentModels/Flux.h>
#include <components/ComponentModels/PointShape.h>
#include <components/ComponentModels/FluxStandard.h>
#include <components/ComponentModels/ComponentList.h>

#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/Index.h>
#include <tasking/Tasking/MethodResult.h>
#include <casa/System/PGPlotter.h>
#include <tasking/Tasking/ObjectController.h>

#include <synthesis/Parallel/Applicator.h>
#include <casa/sstream.h>

#ifdef PABLO_IO
#include "PabloTrace.h"
#endif

#include <casa/namespace.h>
//----------------------------------------------------------------------
pimager::pimager(MeasurementSet &theMs)
  : imager(theMs)
{


}
/*
//----------------------------------------------------------------------
// Parallel read test function

Bool pimager::tryparread(const String& thems, const Int& numloops)
{
  Int msid=0;
  ReadMSAlgorithm readms;
  Bool allDone, assigned;
  Int rank;
  LogIO os(LogOrigin("pimager","tryparread",WHERE));

  try{
    for (Int k=0; k < numloops ; k++){
      assigned=applicator.nextAvailProcess(readms, rank);
 
      while (!assigned) {
	rank = applicator.nextProcessDone(readms, allDone);
	Int stat;
	applicator.get(stat);
	if(stat){
	  os << rank << " worker seems to have read the file " << LogIO::POST;
	}
	else{
	  os << rank << " worker seems to have got into trouble " 
	     << LogIO::POST;
	} 
        
	// Assign the next available process
	assigned = applicator.nextAvailProcess(readms, rank);
      };

      // Send filename to worker assigned
      applicator.put(thems);
      applicator.apply(readms); // For serial transport
    }

    rank = applicator.nextProcessDone(readms, allDone);
    while (!allDone) {
      Int stat;
      applicator.get(stat);
      if(stat){
	os << rank << " worker seems to have read the file " << LogIO::POST;
      }
      else{
	os << rank << " worker seems to have got into trouble " << LogIO::POST;
      } 
      // Wait for the next process to complete
      rank = applicator.nextProcessDone(readms, allDone);
    };
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Exceptionally yours: " << x.getMesg() 
       << LogIO::POST;
  }  
  return True;
}

//----------------------------------------------------------------------

Vector<String> pimager::methods() const
{
  // Add to the methods list already compiled by the imager parent class
  Vector<String> method = imager::methods();
  Int n = method.nelements();
  Int nAdd = 1;
  method.resize(n+nAdd, True);
  Int i = n ;
  method(i) = "tryparread";
  return method;
}

//----------------------------------------------------------------------

MethodResult pimager::runMethod(uInt which, ParameterSet &inputRecord,
				Bool runMethod)
{
  static String returnvalString = "returnval";

  // First check if this method is defined by imager::runMethod();
  // If not already defined, check additional local methods
  Int start = imager::methods().nelements();

  if (which >= start) {
    switch (which-start) {
    case 0: // tryparread
      {
	Parameter<String> ms(inputRecord, "ms", ParameterSet::In);
	Parameter<Int> numloops(inputRecord, "numloops", ParameterSet::In);
	Parameter<Bool> 
	  returnval(inputRecord, returnvalString, ParameterSet::Out);
	if (runMethod) {
	  returnval() = tryparread(ms(), numloops());
	}
      }
      break;
    default:
      return error("No such method");
    }
    return ok();

  } else {
    // Call parent runMethod()
    return imager::runMethod(which, inputRecord, runMethod);
  };
};
*/
//----------------------------------------------------------------------



