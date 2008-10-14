//# LatticePADD.cc: Class for displaying lattices along principal axes
//# Copyright (C) 1998,1999,2000,2001,2002,2004
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
//# $Id: LatticePADD.cc,v 19.9 2005/12/14 18:25:57 dking Exp $

#include <casa/aips.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Containers/Record.h>
#include <coordinates/Coordinates/CoordinateSystem.h>
#include <coordinates/Coordinates/LinearCoordinate.h>
#include <coordinates/Coordinates/SpectralCoordinate.h>
#include <display/Display/Attribute.h>
#include <display/DisplayDatas/DisplayMethod.h>
#include <display/DisplayDatas/LatticePADM.h>
#include <display/DisplayCanvas/WCResampleHandler.h>
#include <display/DisplayCanvas/WCSimpleResampleHandler.h>
#include <display/DisplayDatas/LatticePADD.h>
#include <lattices/Lattices/ArrayLattice.h>
#include <lattices/Lattices/Lattice.h>
#include <lattices/Lattices/LatticeStatistics.h>
#include <lattices/Lattices/MaskedLattice.h>
#include <lattices/Lattices/LatticeLocker.h>
#include <lattices/Lattices/SubLattice.h>
#include <images/Images/ImageInterface.h>
#include <images/Images/ImageRegion.h>
#include <images/Images/SubImage.h>
#include <images/Images/WCLELMask.h>
#include <scimath/Mathematics/Interpolate2D.h>
#include <casa/Logging/LogIO.h>
#include <casa/Logging/LogOrigin.h>
#include <tables/Tables/TableRecord.h>
#include <casa/Quanta/Unit.h>


namespace casa { //# NAMESPACE CASA - BEGIN

// >2d array-based ctor
template <class T>
LatticePADisplayData<T>::LatticePADisplayData(Array<T> *array,
					      const uInt xAxis,
					      const uInt yAxis,
					      const uInt mAxis,
					      const IPosition fixedPos) :
  PrincipalAxesDD(xAxis, yAxis, mAxis),
  itsBaseImagePtr(0),
  itsBaseArrayPtr(0),
  itsMaskedLatticePtr(0),
  itsDeleteMLPointer(False),
  itsLatticeStatisticsPtr(0),
  itsRegionPtr(0),
  itsMaskPtr(0),
  itsDataUnit("_"),
  itsComplexToRealMethod(Display::Magnitude) 
{
  
  itsBaseArrayPtr = new Array<T>;
  *itsBaseArrayPtr = array->copy();
  itsMaskedLatticePtr = new SubLattice<T>(ArrayLattice<T>(*itsBaseArrayPtr));
  itsDeleteMLPointer = True;
  updateLatticeStatistics();

  iAmRubbish = False;
  /*
  Vector<Int> axes(3);
  axes(0) = xAxis;
  axes(1) = yAxis;
  axes(2) = mAxis;
  */

  // setup a coordinate system
  CoordinateSystem newcsys;
  LinearCoordinate lc(itsMaskedLatticePtr->ndim());
  newcsys.addCoordinate(lc);
  Vector<Double> tmp = newcsys.referencePixel();
  tmp = tmp - (Double)1.0;
  newcsys.setReferencePixel(tmp);
  setCoordinateSystem(newcsys);

  // call base class setup:
  setup(fixedPos);
  getMinAndMax();

  
}

// 2d array-based ctor
template <class T>
LatticePADisplayData<T>::LatticePADisplayData(Array<T> *array,
					      const uInt xAxis,
					      const uInt yAxis) :
  PrincipalAxesDD(xAxis, yAxis),
  itsBaseImagePtr(0),
  itsBaseArrayPtr(0),
  itsMaskedLatticePtr(0),
  itsDeleteMLPointer(False),
  itsLatticeStatisticsPtr(0),
  itsRegionPtr(0),
  itsMaskPtr(0),
  itsDataUnit("_"),
  itsComplexToRealMethod(Display::Magnitude) {

  itsBaseArrayPtr = new Array<T>;
  *itsBaseArrayPtr = array->copy();
  itsMaskedLatticePtr = new SubLattice<T>(ArrayLattice<T>(*itsBaseArrayPtr));
  itsDeleteMLPointer = True;
  updateLatticeStatistics();

  iAmRubbish = False;
  /*
  Vector<Int> axes(2);
  axes(0) = xAxis;
  axes(1) = yAxis;
  */

  // setup a coordinate system
  CoordinateSystem newcsys;
  LinearCoordinate lc(2);
  newcsys.addCoordinate(lc);
  Vector<Double> tmp = newcsys.referencePixel().copy();
  tmp = tmp - (Double)1.0;
  newcsys.setReferencePixel(tmp);
  setCoordinateSystem(newcsys);

  IPosition fixedPos(2);
  fixedPos = 0;

  // call base class setup
  setup(fixedPos);
  getMinAndMax();
}

// >2d image-based ctor
template <class T>
LatticePADisplayData<T>::LatticePADisplayData(ImageInterface<T> *image,
					      const uInt xAxis,
					      const uInt yAxis,
					      const uInt mAxis,
					      const IPosition fixedPos) :
  PrincipalAxesDD(xAxis, yAxis, mAxis),
  itsBaseImagePtr(0),
  itsBaseArrayPtr(0),
  itsMaskedLatticePtr(0),
  itsDeleteMLPointer(False),
  itsLatticeStatisticsPtr(0),
  itsRegionPtr(0),
  itsMaskPtr(0),
  itsDataUnit(image->units()),
  itsComplexToRealMethod(Display::Magnitude) {
  
  itsBaseImagePtr = image->cloneII();
  itsMaskedLatticePtr = itsBaseImagePtr;
  updateLatticeStatistics();

  iAmRubbish = False;

  setCoordinateSystem(itsBaseImagePtr->coordinates());

  // call base class setup:
  setup(fixedPos);
  getMinAndMax();
}

// 2d image-based ctor
template <class T>
LatticePADisplayData<T>::LatticePADisplayData(ImageInterface<T> *image,
					      const uInt xAxis,
					      const uInt yAxis) :
  PrincipalAxesDD(xAxis, yAxis),
  itsBaseImagePtr(0),
  itsBaseArrayPtr(0),
  itsMaskedLatticePtr(0),
  itsDeleteMLPointer(False),
  itsLatticeStatisticsPtr(0),
  itsRegionPtr(0),
  itsMaskPtr(0),
  itsDataUnit(image->units()),
  itsComplexToRealMethod(Display::Magnitude) 
{
  itsBaseImagePtr = image->cloneII();
  itsMaskedLatticePtr = itsBaseImagePtr;
  updateLatticeStatistics();

  iAmRubbish = False;
  setCoordinateSystem(image->coordinates());
  IPosition fixedPos(2);
  fixedPos = 0;

  // call base class setup
  setup(fixedPos);
  getMinAndMax();
}

// Destructor
template <class T> 
LatticePADisplayData<T>::~LatticePADisplayData() {
  if (itsLatticeStatisticsPtr) {
    delete itsLatticeStatisticsPtr;
  }
  if (itsDeleteMLPointer && itsMaskedLatticePtr) {
    delete itsMaskedLatticePtr;
  }
  if (itsBaseArrayPtr) {
    delete itsBaseArrayPtr;
  }
  if (itsBaseImagePtr) {
    delete itsBaseImagePtr;
  }
  if (itsResampleHandler) {
    delete itsResampleHandler;
  }
} 
// Query the shape of the lattice
template <class T>
const IPosition LatticePADisplayData<T>::dataShape() {
  if (!itsMaskedLatticePtr) {
    throw(AipsError("LatticePADisplayData<T>::dataShape - "
		    "no lattice is available"));
  }
  return itsMaskedLatticePtr->shape();
}

// Query the dimension of the lattice
template <class T>
const uInt LatticePADisplayData<T>::dataDim() {
  if (!itsMaskedLatticePtr) {
    throw(AipsError("LatticePADisplayData<T>::dataDim - "
		    "no lattice is available"));
  }
  return itsMaskedLatticePtr->ndim();
}

// Query the value of the lattice at a particular position:
template <class T>
const T LatticePADisplayData<T>::dataValue(IPosition pos) {
  if (!itsMaskedLatticePtr) {
    throw(AipsError("LatticePADisplayData<T>::dataValue - "
		    "no lattice is available"));
  }
  if (pos.nelements() != itsMaskedLatticePtr->ndim()) {
    throw(AipsError("LatticePADisplayData<T>::dataValue - "
		    "no such position in lattice"));
  }
  return itsMaskedLatticePtr->operator()(pos);
  
}

template <class T>
const Bool LatticePADisplayData<T>::maskValue(const IPosition &pos) {
  if (!itsMaskedLatticePtr) {
    throw(AipsError("LatticePADisplayData<T>::maskValue - "
		    "no lattice available"));
  }
  if (pos.nelements() != itsMaskedLatticePtr->ndim()) {
    throw(AipsError("LatticePADisplayData<T>::maskValue - "
		    "no such position in lattice"));
  }

// We must use getMaskSlice rather than pixelMask() because
// application of the OTF mask is not reflected by the
// pixelMask() Lattice

  static Array<Bool> tmp;
  static Bool deleteIt;
  {
    itsMaskedLatticePtr->getMaskSlice(tmp,Slicer(pos));
    return *(tmp.getStorage(deleteIt));
  }
}

// Query the units of the lattice values
template <class T>
const Unit LatticePADisplayData<T>::dataUnit() {
  if (!itsMaskedLatticePtr) {
    throw(AipsError("LatticePADisplayData<T>::dataUnit - "
		    "no lattice is available"));
  }
  return itsDataUnit;
}

template <class T>
String LatticePADisplayData<T>::getBrightnessUnits()
{
  try {
    return itsDataUnit.getName();
  } catch(...) {
    throw(AipsError("LatticePADisplayData<T>::getBrightnessUnit - "
		    "couldn't get brightness unit"));
  }

}

template <class T>
void LatticePADisplayData<T>::setDefaultOptions() {

  calcHist = False;
  PrincipalAxesDD::setDefaultOptions();
  itsResample = "nearest";
  itsResampleHandler = new WCSimpleResampleHandler(Interpolate2D::NEAREST);
  itsComplexMode = "magnitude";
  setComplexMode(Display::Magnitude);
}

template <class T>
Bool LatticePADisplayData<T>::setOptions(Record &rec, Record &recOut)
{
  Bool ret = PrincipalAxesDD::setOptions(rec, recOut);
  Bool newHistNeeded = False;    // lei050

  ImageInterface<T>* pImage = 0;
  DataType dtype;
  
  Bool error;
  if(readOptionRecord(itsResample, error, rec, "resample")) {
    ret = True;    
    
    //newHistNeeded = True;
	//#dk -- commented out 12/05
	// This is unnecessary, I believe: display resampling
	// mode should have no effect on the data histogram,
	// and recalculating it can be expensive!

    if (itsResampleHandler) {
      delete itsResampleHandler;
    }
    if (itsResample == "bilinear") {
      itsResampleHandler = new WCSimpleResampleHandler(Interpolate2D::LINEAR);
    } else if (itsResample=="bicubic") {
      itsResampleHandler = new WCSimpleResampleHandler(Interpolate2D::CUBIC);
      itsResample = "bicubic";
    } else {
      itsResampleHandler = new WCSimpleResampleHandler(Interpolate2D::NEAREST);
      itsResample = "nearest";
    }
  }
  //  
  Bool fillRecOut = False;
  T typetester;
  dtype = whatType(&typetester);
 
  if ((dtype == TpComplex) || (dtype == TpDComplex)) {
    if (readOptionRecord(itsComplexMode, error, rec, "complexmode")) {
      ret = True;
      newHistNeeded = True;

      if (itsComplexMode == "phase") {
	setComplexMode(Display::Phase);
      } else if (itsComplexMode == "real") {
	setComplexMode(Display::Real);
      } else if (itsComplexMode == "imaginary") {
	setComplexMode(Display::Imaginary);
      } else {
	setComplexMode(Display::Magnitude);
	itsComplexMode = "magnitude";
      }
      cleanup();
      updateLatticeStatistics();
      getMinAndMax();
      fillRecOut = True;
    }
  }

  Bool reread = False;
  Bool forceRegionParse = False;
  if (readOptionRecord(reread, error, rec, "reread")) {
    ret = True;
    cleanup();
    getMinAndMax();
    fillRecOut = True;
    forceRegionParse = True;
    if (itsBaseImagePtr) {   //reset to default mask
      LatticeLocker lock(*itsBaseImagePtr, FileLocker::Write);
      if (lock.hasLock(FileLocker::Write)) {
	itsBaseImagePtr->setDefaultMask(itsBaseImagePtr->getDefaultMask());
	newHistNeeded = True;
      } else {
	LogIO os(LogOrigin("LatticePADisplayData", "setOptions", WHERE));
	os << LogIO::SEVERE << "Couldn't lock image." << LogIO::POST;
      }       
    }
  }
  
  if (rec.isDefined("newdata")) {
    newHistNeeded = True;
    DataType indtype = rec.dataType("newdata");
    if ((indtype == TpString) && itsBaseImagePtr) {
      // we were built from an image, and we've been given a string -
      // assume it's an image name...

    } else if (!itsBaseImagePtr && 
	       (((indtype == TpArrayFloat) && (dtype == TpFloat)) ||
		((indtype == TpArrayComplex) && (dtype == TpComplex)))) {
      // we were built from an array of Float/Complex, and we've been given
      // the same...
      Array<T> array;
      rec.get("newdata", array);
      if (array.shape().nelements() != itsBaseArrayPtr->shape().nelements()) {
	throw(AipsError("dimensionality of new data is invalid"));
      }
      cleanup();

// When the data source is an Array, itsDeleteMLPointer must always
// be true

      AlwaysAssert(itsDeleteMLPointer, AipsError);
      if (itsMaskedLatticePtr) {
	delete itsMaskedLatticePtr;
      }
      itsMaskedLatticePtr = new SubLattice<T>(ArrayLattice<T>(array));
      updateLatticeStatistics();
      setAxes(displayAxes()(0), displayAxes()(1),
	      displayAxes()(2), fixedPosition());
      getMinAndMax();
      fillRecOut = True;
      ret = True;
    } else {
      throw(AipsError("Invalid use of 'newdata' option"));
    }
  }

// The image region and OTF mask both involve the use of SubImage
// We must handle them together, and the mask expression must
// be applied first, followed by application of the region

  if (itsBaseImagePtr && (rec.isDefined("region") || rec.isDefined("mask"))) {
    String resetString("resetCoordinates");
    Attribute resetAtt(resetString, True);
    
// If the region is unset, the returned pointer is null

    ImageRegion* pRegion = 0;
    Bool regionChanged = False;
    if (rec.isDefined("region")) {
      pRegion = makeRegion (rec);

// Update private region pointer and see if region changed

      regionChanged = isRegionDifferent (pRegion);
      if (regionChanged) {
	newHistNeeded = True;
      }
    
    }

// If the mask is unset, the returned pointer is null

    WCLELMask* pMask = 0;
    Bool maskChanged = False;
    if (rec.isDefined("mask")) {
       pMask = makeMask (rec);

// Update private mask pointer and see if mask changed

       maskChanged = isMaskDifferent (pMask);
       if (maskChanged) {
	 newHistNeeded = True;
       }
    }
//
    if (forceRegionParse || regionChanged || maskChanged) {
       cleanup();
//
       if (itsMaskPtr) {
          ImageRegion maskRegion(*itsMaskPtr);
          if (itsRegionPtr) {
             SubImage<T> subIm(*itsBaseImagePtr, maskRegion, False);
             pImage = new SubImage<T>(subIm, *itsRegionPtr, False);
          } else {
             pImage = new SubImage<T>(*itsBaseImagePtr, maskRegion, False);
          }
       } else {
          if (itsRegionPtr) {
             pImage = new SubImage<T>(*itsBaseImagePtr, *itsRegionPtr, False);
          }
       }
//
       if (itsDeleteMLPointer && itsMaskedLatticePtr) {
          delete itsMaskedLatticePtr;
       }
       itsMaskedLatticePtr = 0;

// If pImage is now null, it means both region and mask are now unset
// so we return to the base image

       CoordinateSystem cSysOld = originalCoordinateSystem();
       if (pImage) {
          itsMaskedLatticePtr = pImage;
          itsDeleteMLPointer = True;
	  newHistNeeded = True;

// Transfer over the axis unit and velocity choices that
// might have been set by PADD

          CoordinateSystem cSys = pImage->coordinates();
          transferPreferences(cSys, cSysOld);
//
          setCoordinateSystem(cSys);
       } else {
          itsMaskedLatticePtr = itsBaseImagePtr;
          itsDeleteMLPointer = False;

// Transfer over the axis unit and velocity choices that
// might have been set by PADD

          CoordinateSystem cSys = itsBaseImagePtr->coordinates();
          transferPreferences(cSys, cSysOld);
//
          setCoordinateSystem(cSys);
       }

// Update other things

       updateLatticeStatistics();
       setAxes(displayAxes()(0), displayAxes()(1),
               displayAxes()(2), fixedPosition());
       getMinAndMax();
       fillRecOut = True;

       // Request an update to the number of frames on the animator(s) where
       // this DD is registered.  (Note: this is _not_ a change to an 'Adjust'
       // gui, unlike most other uses of recOut).  The animator's current
       // frame number will remain unchanged if it is still within range;
       // otherwise it will be set to the first frame.

       if(!recOut.isDefined("setanimator")) {
         Record setanimrec;
	 recOut.defineRecord("setanimator",setanimrec);  }

// Set this so that coordinates are reset...

       setAttributeOnPrimaryWCHs(resetAtt);
       ret = True;
    }
  }
//

  if (fillRecOut) {

    Record trec = getOptions();

    // We change datamin/datamax (contained in "minmaxhist")  in "rec"
    // only if they do not pre-exist (if they do the user has specified
    // these values) If not, we stick in the updated min and max.

    if (!rec.isDefined("minmaxhist") &&
	trec.isDefined("minmaxhist")) {

      Vector<Float> tempinsert(2);
      tempinsert(0) = datamin;
      tempinsert(1) = datamax;

      insertArray(rec, tempinsert, "minmaxhist");
      insertArray(recOut, tempinsert, "minmaxhist");

    }
  }

  //Check whether or not the flag telling us whether to calculate a
  //histogram has gone from true to false (eg window opened)


  if(rec.isDefined("alwaysupdate")) {
    Bool optCalc;

    rec.get("alwaysupdate", optCalc);

    if (optCalc && !calcHist) {
      calcHist = optCalc;

      if(!(pImage)) {
	if((itsRegionPtr) || (itsMaskPtr)) {
	  if ((itsRegionPtr) && (itsMaskPtr)) {
	    //Region and Mask set
	    ImageRegion maskRegion(*itsMaskPtr);
	    SubImage<T> subIm(*itsBaseImagePtr, maskRegion, False);
	    pImage = new SubImage<T>(subIm, *itsRegionPtr, False);
	  } else if (itsRegionPtr) {
	    //Region only
	    pImage = new SubImage<T>(*itsBaseImagePtr, *itsRegionPtr, False);
	  } else {
	    //Mask only
	    ImageRegion maskRegion(*itsMaskPtr);
	    pImage = new SubImage<T>(*itsBaseImagePtr, maskRegion, False);
	  }
	}
    }
    newHistNeeded = True;

    } else {
      calcHist = optCalc;
    }
  }

  // New histogram needed?
  if(getOptions().isDefined("minmaxhist") && newHistNeeded && calcHist) {
    if (pImage) {
      if (updateHistogram(recOut, *pImage)) {
	newHistNeeded = False;
      } else {
	throw(AipsError("LatticePADD.cc - Error making new histogram data"
			" - (from pImage)"));
      }
    } else if (itsBaseImagePtr) {
      if (updateHistogram(recOut, *itsBaseImagePtr)) {
	newHistNeeded = False;
      } else {
	throw(AipsError("LatticePADD.cc - Error making new histogram data"
			" - (from baseImage)"));
      }

    } else if (itsBaseArrayPtr) {
      if (updateHistogram(recOut, itsBaseArrayPtr)) {
	newHistNeeded = False;
      } else {
	throw(AipsError("LatticePADD.cc - Error making new histogram data"
			" - (from baseArray)"));
      }

    } else {
      throw(AipsError("LatticePADD.cc - Error making new histogram data"
			" - (couldn't find anything to use!)"));
    }

  } else {
    if (recOut.isDefined("minmaxhist") &&
	recOut.subRecord("minmaxhist").isDefined("newdata")) {
      Record tmphist = recOut.subRecord("minmaxhist");
      tmphist.define("newdata", False);
      tmphist.define("histarray", "unset");
      recOut.defineRecord("minmaxhist", tmphist);
    }

  }

  //After all that, check whether histogramgui window needs new statistices
  if (rec.isDefined("imagestats") && getOptions().isDefined("minmaxhist")) {
    Vector<String> whatToGet;
    rec.get("imagestats", whatToGet);

    Record addStats;
    if (recOut.isDefined("minmaxhist")) {
      addStats = recOut.subRecord("minmaxhist");
    } else {
      addStats = getOptions().subRecord("minmaxhist");
    }
//
    Record theStats;
    Array<Double> tempStats;
    for (uInt i=0; i<whatToGet.nelements();i++) {
      if (whatToGet(i) == "mean") {
	itsLatticeStatisticsPtr->getStatistic(tempStats,LatticeStatsBase::MEAN);
	theStats.define("mean", tempStats);
      } else if (whatToGet(i) == "median") {
	itsLatticeStatisticsPtr->getStatistic(tempStats,LatticeStatsBase::MEDIAN);
	theStats.define("median", tempStats);
      } else if (whatToGet(i) == "stddev") {
	itsLatticeStatisticsPtr->getStatistic(tempStats,LatticeStatsBase::SIGMA);
	theStats.define("stddev", tempStats);
      }
    }
    theStats.define("new", True);
    addStats.defineRecord("stats", theStats);
    recOut.defineRecord("minmaxhist", addStats);
  } else {
    if (recOut.isDefined("minmaxhist")) {
      Record temp = recOut.subRecord("minmaxhist");
      if (temp.isDefined("stats")) {
	Record clear = temp.subRecord("stats");
	clear.define("new", False);
	temp.defineRecord("stats", clear);
	recOut.defineRecord("minmaxhist", temp);
      }
    }
  }

  return ret;
}

template <class T>
Record LatticePADisplayData<T>::getHist()
{
  if(imageHistogram.isDefined("values")) {
    return imageHistogram;
  } else {
    Record unset;
    unset.define("unset", "unset");
    return unset;
  }
}

template <class T>
Record LatticePADisplayData<T>::getOptions() {

  Record rec = PrincipalAxesDD::getOptions();

// Some of these widgets are not appropriate to the
// LatticeAsVector DD (which has a Complex data source)

  if (className() != String("LatticeAsVector")) {
     Record resample;
     resample.define("dlformat", "resample");
     resample.define("listname", "Resampling mode");
     resample.define("ptype", "choice");
     Vector<String> vresample(3);
     vresample(0) = "nearest"; vresample(1) = "bilinear"; vresample(2) = "bicubic";
     resample.define("popt", vresample);
     resample.define("default", "nearest");
     resample.define("value", itsResample);
     resample.define("allowunset", False);
     rec.defineRecord("resample", resample);
//
     T typetester;
     DataType dtype = whatType(&typetester);
     if ((dtype == TpComplex) || (dtype == TpDComplex)) {
       Record complexmode;
       complexmode.define("dlformat", "complexmode");
       complexmode.define("listname", "Complex mode");
       complexmode.define("ptype", "choice");
       Vector<String> vcomplexmode(4);
       vcomplexmode(0) = "magnitude"; vcomplexmode(1) = "phase";
       vcomplexmode(2) = "real"; vcomplexmode(3) = "imaginary";
       complexmode.define("popt", vcomplexmode);
       complexmode.define("default", "magnitude");
       complexmode.define("value", itsComplexMode);
       complexmode.define("allowunset", False);
       rec.defineRecord("complexmode", complexmode);
     }
  }
//
  if (itsBaseImagePtr) {
     Record region;
     region.define("dlformat", "region");
     region.define("listname", "Image region");
     region.define("ptype", "region");
     Record unset;
     unset.define("i_am_unset", "i_am_unset");
     region.defineRecord("default", unset);
     region.defineRecord("value", unset);
     region.define("allowunset", True);
     rec.defineRecord("region", region);
//
     Record mask;
     mask.define("dlformat", "mask");
     mask.define("listname", "Mask expression");
     mask.define("ptype", "string");
     mask.defineRecord("default", unset);
     mask.defineRecord("value", unset);
     mask.define("allowunset", True);
     rec.defineRecord("mask", mask);
   }
//
  return rec;
}

// update the stored minimum and maximum data values (Float version)
template<class T>
void LatticePADisplayData<T>::getMinAndMax() {
  // sanity check
  if (!itsMaskedLatticePtr || !itsLatticeStatisticsPtr) {
    throw(AipsError("LatticePADisplayData<T>::getMinAndMax - "
		    "no lattice is available"));
    return;
  }
//
  Float dMin, dMax;
  if (!itsLatticeStatisticsPtr->getFullMinMax(dMin, dMax)) {
    datamin = -1.0;
    datamax = 1.0;
  } else {
    datamin = dMin;
    datamax = dMax;
  }
}


template<class T>
WCLELMask* LatticePADisplayData<T>::makeMask (const RecordInterface& mask)
{
   LogIO os(LogOrigin("LatticePADisplayData", "makeRegion", WHERE));
   WCLELMask* maskPtr = 0;
   if (mask.dataType("mask") == TpRecord) {
      Record rec = mask.asRecord("mask");
      if (rec.isDefined("i_am_unset")) {
      } else {
         os << LogIO::SEVERE << "Mask is illegal record" << LogIO::POST;      
      }
   } else if (mask.dataType("mask") == TpString) {
      maskPtr = new WCLELMask(mask.asString("mask"));
      if (!maskPtr) {
         os << "Failed to create WCLELMask from mask String" << LogIO::POST;
      }
   } else {
      os << LogIO::SEVERE << "Mask is illegal record type" << LogIO::POST;
   }       
//
   return maskPtr;
}   


template<class T>
ImageRegion* LatticePADisplayData<T>::makeRegion (const RecordInterface& region)
{
   LogIO os(LogOrigin("LatticePADisplayData", "makeRegion", WHERE));
   ImageRegion* regionPtr = 0;
   if (region.dataType("region") == TpRecord) {
      Record rec = region.asRecord("region");
      if (rec.isDefined("i_am_unset")) {
//
      } else {
         regionPtr = ImageRegion::fromRecord(rec, String(""));
         if (!regionPtr) {
            os << LogIO::NORMAL << "Failed to create ImageRegion from region record" << LogIO::POST;
         }
      }
   } else {
      os << LogIO::SEVERE << "Region is illegal record type" << LogIO::POST;
   }       
//
   return regionPtr;
} 



template<class T>
Bool LatticePADisplayData<T>::isRegionDifferent (ImageRegion*& pRegion)
{
   Bool same = False;
   if (!pRegion) {
      if (!itsRegionPtr) same = True;
   } else {
      if (itsRegionPtr) {
         if (*itsRegionPtr==*pRegion) same = True;
      }
   }
//
   if (same) {
      delete pRegion;
      pRegion = 0;
   } else {
      if (itsRegionPtr) delete itsRegionPtr;
      itsRegionPtr = pRegion;
   }
//
   return !same;
} 

template<class T>
Bool LatticePADisplayData<T>::isMaskDifferent (WCLELMask*& pMask)
{
   Bool same = False;
   if (!pMask) {
      if (!itsMaskPtr) same = True;
   } else {
      if (itsMaskPtr) {
         if (*itsMaskPtr==*pMask) same = True;
      }
   }
//
   if (same) {
      delete pMask;
      pMask = 0;
   } else {
      if (itsMaskPtr) delete itsMaskPtr;
      itsMaskPtr = pMask;
   }
//
   return !same;
} 



template<class T>
Bool LatticePADisplayData<T>::insertFloat(Record& into, Float from, const String field) 
{
  Record tempSub;  
  if (!into.isDefined(field)) {
    tempSub = getOptions().subRecord(field);
    tempSub.define("value", from);
    into.defineRecord(field, tempSub);
  } else {
    if (into.dataType(field) == TpRecord)
      {
	tempSub = into.subRecord(field);
	tempSub.define("value", from);
	into.defineRecord(field, tempSub);
      } else {
	into.removeField(field);
	tempSub = into.subRecord(field);
	tempSub.define("value", from);
	into.defineRecord(field, tempSub);
      }
  }

  return True;
}

template<class T>
Bool LatticePADisplayData<T>::insertArray(Record& into, Vector<Float> from, const String field) 
{
  Record tempSub;  
  if (!into.isDefined(field)) {
    tempSub = getOptions().subRecord(field);
    tempSub.define("value", from);
    into.defineRecord(field, tempSub);
  } else {
    if (into.dataType(field) == TpRecord)
      {
	tempSub = into.subRecord(field);
	tempSub.define("value", from);
	into.defineRecord(field, tempSub);
      } else {
	into.removeField(field);
	tempSub = into.subRecord(field);
	tempSub.define("value", from);
	into.defineRecord(field, tempSub);
      }
  }
  return True;

}

template<class T>
Bool LatticePADisplayData<T>::transferPreferences (CoordinateSystem& cSysInOut,
                                                   const CoordinateSystem& cSysIn) const
{
   if (cSysIn.nCoordinates()!=cSysInOut.nCoordinates()) return False;
   if (cSysIn.nWorldAxes()!=cSysInOut.nWorldAxes()) return False;
   if (cSysIn.nPixelAxes()!=cSysInOut.nPixelAxes()) return False;
// 
   Int after = -1;
   Int cIn = cSysIn.findCoordinate (Coordinate::SPECTRAL, after);   
   after = -1;
   Int cInOut = cSysInOut.findCoordinate (Coordinate::SPECTRAL, after);
//
   if (cIn!=-1 && cInOut!=-1 && cIn==cInOut) {
      const SpectralCoordinate scIn = cSysIn.spectralCoordinate(cIn);
      const SpectralCoordinate scInOut = cSysInOut.spectralCoordinate(cInOut);
      SpectralCoordinate scInOut2(scInOut);
//
      MDoppler::Types velDoppler = scIn.velocityDoppler ();
      String velUnit = scIn.velocityUnit();
      scInOut2.setVelocity (velUnit, velDoppler);
//
      String formatUnit = scIn.formatUnit();
      scInOut2.setFormatUnit(formatUnit);      
//
      cSysInOut.replaceCoordinate(scInOut2, cInOut);
   }
   return True;
}



template<class T>
Bool LatticePADisplayData<T>::useStriding(
     const IPosition& shape, IPosition& stride,
     uInt maxPixels, uInt minPerAxis) {
  // Aids updateHistogram() by computing a stride to use for efficiency
  // when computing histograms (could be used elsewhere too).
  // Input parameter 'shape' is the shape of the original lattice or array.
  // Return value indicates whether striding should be used; if so, the
  // recommended stride is returned in the 'stride' parameter.
  // maxPixels is the desired maximum number of elements in the sub-lattice
  // that would result from using the returned stride (may be exceeded
  // because of minPerAxis requirements, or in any case by a few percent).
  // A stride greater than 1 will not be returned for an axis if it
  // would make the length of that axis in the strided sub-lattice
  // less than minPerAxis.
  //
  // The idea is to sample using no more than maxPixels elements from the
  // original Lattice or Array.  Histograms needn't be more accurate for
  // their purpose (which is to set color scaling).
  
  
  maxPixels = max(1u, maxPixels);  minPerAxis = max(1u, minPerAxis);
		// (safety: insure against improper input parameter use).

  uInt nAxes = shape.nelements();
  
  stride.resize(nAxes);
  stride=1;	// Initial stride on all axes.
    
  uInt latticeSize = 1;
  for(uInt axis=0; axis<nAxes; axis++) latticeSize *= shape[axis];
  
  if(latticeSize <= maxPixels) return False;
		// No striding needed.

  
  Double reduceFctr = Double(latticeSize)/maxPixels;
	// We want striding to reduce the data examined by at least
	// this factor.  (reduceFctr > 1).
  
  // Strided sampling would be poor on the Stokes axis, or even
  // on a frequency axis.  This code makes a lame attempt at
  // avoiding this, by assuming that sky coordinates are on the
  // first two axes, doing strided sampling there only, if possible.
  // In no case, however, is a stride greater than 1 set for an axis
  // which would cause fewer than minPerAxis elements to be used on
  // that axis.
  
  // After determining a stride for the shorter of the first two axes,
  // other axes will be given strides (up to their maximum) in axisOrder,
  // until reduceFctr (or maximum striding on all axes) is reached.
  // The longer of the first two axes will be the next one strided,
  // after the shortest; then the rest, as necessary.
  
  Int shortAxis=0, longAxis=1;
  IPosition axisOrder(nAxes);
  for (uInt i=1; i<nAxes; i++) axisOrder[i]=i;
  
  if(nAxes>1 && shape[1]<shape[0])  {
    shortAxis = 1;
    axisOrder[1] = longAxis = 0;  }
    
  Int shortMaxStride = max(1u, shape[shortAxis]/minPerAxis);
  Int longMaxStride  = max(1u, shape[longAxis]/minPerAxis);
	// maximum usable stride on short, long axes.
  
  Int sqrtStride = Int(ceil(sqrt(reduceFctr)));
	// This stride on first two axes, if usable, would achieve
	// the needed reduceFctr...

  // ...We may even get away with one less on the short axis...
  Int shortStride = sqrtStride-1;
  if(shortStride*min(sqrtStride,longMaxStride) < reduceFctr) shortStride++;
		// (No, not enough: use full sqrtStride, if possible...).
  
  stride[shortAxis] = min(shortMaxStride, shortStride);
		// ...but no more than shortMaxStride, in any case.
  
  
  reduceFctr /= stride[shortAxis];
	// remaining reduction factor to be achieved.
	// (slightly inaccurate, but not enough to matter...).
  
  // Compute stride on remaining axes (starting with the
  // longest of the first two).
  
  for (uInt i=1; i<nAxes; i++) {
    
    if(reduceFctr<=1.) break;	// reduceFctr achieved -- done.
    
    Int strideAxis = axisOrder[i];
	// Next axis -- the one to stride now.
    Int maxStride = max(1u, shape[strideAxis]/minPerAxis);
	// Its maximum stride.
    stride[strideAxis] = min(maxStride, Int(ceil(reduceFctr)));
	// stride to use on this axis.
    reduceFctr /= stride[strideAxis];  }
	// reduction factor still to be achieved on remaining
	// axes, in possible.
    
  return True;  }

 


} //# NAMESPACE CASA - END

