//# SDDataSampling.cc: Implementation of SDDataSampling class
//# Copyright (C) 1997,1998,1999,2000,2001,2003
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
//# $Id: SDDataSampling.cc,v 19.4 2004/11/30 17:50:47 ddebonis Exp $

#include <synthesis/DataSampling/SDDataSampling.h>
#include <coordinates/Coordinates/CoordinateSystem.h>
#include <coordinates/Coordinates/DirectionCoordinate.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <casa/BasicSL/Constants.h>
#include <synthesis/MeasurementComponents/SkyJones.h>
#include <msvis/MSVis/VisSet.h>
#include <msvis/MSVis/VisBuffer.h>
#include <msvis/MSVis/VisibilityIterator.h>
#include <images/Images/ImageInterface.h>
#include <images/Images/PagedImage.h>
#include <images/Images/TempImage.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>
#include <casa/System/ProgressMeter.h>
#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

SDDataSampling::SDDataSampling(MeasurementSet& ms,
			       SkyJones& sj,
			       const CoordinateSystem& coords,
			       const IPosition& shape,
			       const Quantity& sigmaConst)
{

  LogIO os(LogOrigin("SDDataSampling", "SDDataSampling"));

  DataSampling::IDLScript_p="@app_sd";

  // Now create the VisSet
  Block<int> sort(1);
  sort[0] = MS::TIME;
  
  Matrix<Int> noselection;
  VisSet vs(ms,sort,noselection);
  
  // First get the CoordinateSystem for the image and then find
  // the DirectionCoordinate
  Int directionIndex=coords.findCoordinate(Coordinate::DIRECTION);
  AlwaysAssert(directionIndex>=0, AipsError);
  DirectionCoordinate directionCoord=coords.directionCoordinate(directionIndex);

  Int lastRow = 0;

  ROMSPointingColumns mspc(ms.pointing());

  lastIndex_p=0;

  VisIter& vi=vs.iter();

  // Get bigger chunks o'data: this should be tuned some time
  // since it may be wrong for e.g. spectral line
  vi.setRowBlocking(100);

  VisBuffer vb(vi);
  vi.originChunks();
  vi.origin();

  Vector<Double> imagePos;
  imagePos = directionCoord.referenceValue();

  Vector<Double> worldPos;

  MDirection imagePosMeas;
  MDirection worldPosMeas;

  // First try the POINTING sub-table
  Int pointIndex=getIndex(mspc, vb.time()(0));
  // If no valid POINTING entry, then use FIELD phase center
  ROMSColumns msc(ms);
  if((pointIndex>=0)||(pointIndex<mspc.time().nrow())) {
    worldPosMeas=mspc.directionMeas(pointIndex);
  } else {
    worldPosMeas=msc.field().phaseDirMeas(vb.fieldId());
  };
  MDirection::Convert pointingToImage(worldPosMeas,
				      directionCoord.directionType());
  imagePosMeas = pointingToImage(worldPosMeas);
  directionCoord.setReferenceValue(imagePosMeas.getAngle().getValue());

  Vector<Double> unitVec(2);
  Int nx=shape(0);
  Int ny=shape(1);
  unitVec(0)=nx/2;
  unitVec(1)=ny/2;
  directionCoord.setReferencePixel(unitVec);
  CoordinateSystem iCoords(coords);
  iCoords.replaceCoordinate(directionCoord, directionIndex);

  TempImage<Float> PB(shape, iCoords);
  PB.set(1.0);

  sj.applySquare(PB, PB, vb, 0);
  prf_p=PB.getSlice(IPosition(4, 0, 0, 0, 0),
		    IPosition(4, nx, ny, 1, 1), True);

  // Reset the direction coordinate
  directionCoord=coords.directionCoordinate(directionIndex);
  // Now fill in the data and position columns
  ProgressMeter pm(1.0, Double(ms.nrow()), "Sampling Data", "", "", "", True);

  // Loop over all visibilities
  Int cohDone = 0;
  Float sigmaVal=sigmaConst.getValue();
  Vector<Double> xyPos(2);

  Array<Float> dx(IPosition(2, 2, ms.nrow()));
  dx=-1.0;
  Array<Float> data(IPosition(1, ms.nrow()));
  data=0.0;
  Array<Float> sigma(IPosition(1, ms.nrow()));
  sigma=-1.0;

  for (vi.originChunks();vi.moreChunks();vi.nextChunk()) {
    for (vi.origin(); vi.more(); vi++) {
      for (Int row=0;row<vb.nRow();row++) {
	Int pointIndex=getIndex(mspc, vb.time()(row));
	if((pointIndex>=0)||(pointIndex<mspc.time().nrow())) {
	  imagePosMeas=
	    pointingToImage(mspc.directionMeas(pointIndex));
	  if(directionCoord.toPixel(xyPos, imagePosMeas)) {
	    if((!vb.flagRow()(row))&&
	       (vb.sigma()(row)>0.0)&&
	       (Float(xyPos(0))>0.0)&&
	       (Float(xyPos(1))>0.0)) {
	      dx(IPosition(2, 0, lastRow)) = Float(xyPos(0));
	      dx(IPosition(2, 1, lastRow)) = Float(xyPos(1));
	      IPosition irow(1, lastRow);
	      data(irow) = real(vb.correctedVisCube()(0,0,row));
	      if(sigmaVal>0.0) {
		sigma(irow) = sigmaVal;
	      }
	      else {
		sigma(irow) = vb.sigma()(row);
	      }
	      lastRow++;
	    }
	  }
	}
      }
      cohDone+=vb.nRow();
      pm.update(Double(cohDone));
    }
  }
  if(lastRow==0) {
    LogIO os(LogOrigin("SDDataSampling", "SDDataSampling()", WHERE));
    os << LogIO::SEVERE << "No valid data: check image parameters, sigmas in data"
       << LogIO::EXCEPTION;
  }
  // Now copy good rows to output arrays
  dx_p.resize(IPosition(2, 2, lastRow)); 
  data_p.resize(IPosition(1, lastRow));  
  sigma_p.resize(IPosition(1, lastRow)); 
  for (Int row=0;row<lastRow;row++) {
    IPosition ip(2, 0, row);
    dx_p(ip)=dx(ip);
    ip(0)=1;
    dx_p(ip)=dx(ip);
    IPosition rp(1, row);
    sigma_p(rp)=sigma(rp);
    data_p(rp)=data(rp);
  }

}

//---------------------------------------------------------------------- 
SDDataSampling& SDDataSampling::operator=(const SDDataSampling& other)
{
  if(this!=&other) {
  };
  return *this;
};

//----------------------------------------------------------------------
SDDataSampling::SDDataSampling(const SDDataSampling& other)
{
  operator=(other);
}

//----------------------------------------------------------------------
SDDataSampling::~SDDataSampling() {
}

void SDDataSampling::ok() {
}

Int SDDataSampling::getIndex(const ROMSPointingColumns& mspc, const Double& time) {
  Int start=lastIndex_p;
  // Search forwards
  Int nrows=mspc.time().nrow();
  for (Int i=start;i<nrows;i++) {
    if(abs(mspc.time()(i)-time) < mspc.interval()(i)) {
      lastIndex_p=i;
      return i;
    }
  }
  // Search backwards
  for (Int i=start;i>=0;i--) {
    if(abs(mspc.time()(i)-time) < mspc.interval()(i)) {
      lastIndex_p=i;
      return i;
    }
  }
  // No match!
  return -1;
}

} //# NAMESPACE CASA - END

