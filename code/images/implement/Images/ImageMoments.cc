//# ImageMoments.cc:  generate moments from an image
//# Copyright (C) 1995,1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: ImageMoments.cc,v 19.13 2005/12/06 20:18:50 wyoung Exp $
//   

#include <images/Images/ImageMoments.h>

#include <casa/aips.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayPosIter.h>
#include <casa/Containers/Block.h>
#include <casa/Containers/Record.h>
#include <casa/Containers/RecordFieldId.h>
#include <casa/Exceptions/Error.h>
#include <scimath/Functionals/Gaussian1D.h>
#include <casa/Logging/LogIO.h>
#include <tables/LogTables/TableLogSink.h>
#include <casa/BasicSL/Constants.h>
#include <casa/BasicMath/Math.h>
#include <scimath/Mathematics/Convolver.h>
#include <casa/Quanta/Unit.h>
#include <casa/Quanta/UnitMap.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Quanta/QMath.h>
#include <casa/OS/Directory.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <tables/Tables/Table.h>
#include <casa/Utilities/DataType.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/LinearSearch.h>
#include <casa/Utilities/PtrHolder.h>

#include <coordinates/Coordinates/CoordinateUtil.h>
#include <coordinates/Coordinates/DirectionCoordinate.h>
#include <coordinates/Coordinates/LinearCoordinate.h>
#include <coordinates/Coordinates/CoordinateSystem.h>
#include <scimath/Fitting/NonLinearFitLM.h>
#include <images/Images/ImageInterface.h>
#include <images/Images/ImageMomentsProgress.h>
#include <images/Images/ImageStatistics.h>
#include <images/Images/ImageHistograms.h>
#include <images/Images/MomentCalculator.h>
#include <images/Images/PagedImage.h>
#include <images/Images/TempImage.h>
#include <images/Images/RegionHandler.h>
#include <images/Images/ImageRegion.h>
#include <images/Images/SubImage.h>
#include <images/Images/SepImageConvolver.h>
#include <lattices/Lattices/ArrayLattice.h>
#include <lattices/Lattices/LatticeApply.h>
#include <lattices/Lattices/LatticeIterator.h>
#include <lattices/Lattices/LatticeStatsBase.h>
#include <lattices/Lattices/LCPagedMask.h>
#include <lattices/Lattices/TiledLineStepper.h>
#include <casa/System/PGPlotter.h>
#include <tables/LogTables/NewFile.h>

#include <casa/sstream.h>
#include <casa/iomanip.h>


namespace casa { //# NAMESPACE CASA - BEGIN

template <class T> 
ImageMoments<T>::ImageMoments (ImageInterface<T>& image, 
                               LogIO &os,
                               Bool overWriteOutput,
                               Bool showProgressU)
: os_p(os),
  pInImage_p(0),
  showProgress_p(showProgressU),
  momentAxisDefault_p(-10),
  peakSNR_p(T(3)),
  stdDeviation_p(T(0.0)),
  yMin_p(T(0.0)),
  yMax_p(T(0.0)),
  smoothOut_p(""),
  goodParameterStatus_p(True),
  doWindow_p(False),
  doFit_p(False),
  doAuto_p(True),
  doSmooth_p(False),
  noInclude_p(True),
  noExclude_p(True),
  fixedYLimits_p(False),
  overWriteOutput_p(overWriteOutput),
  error_p(""),
  convertToVelocity_p(False),
  velocityType_p(MDoppler::RADIO)
{
   momentAxis_p = momentAxisDefault_p;
   moments_p.resize(1);
   moments_p(0) = INTEGRATED;
   kernelTypes_p.resize(0);
   kernelWidths_p.resize(0);
   nxy_p.resize(0);
   selectRange_p.resize(0);
   smoothAxes_p.resize(0);
//
   if (setNewImage(image)) {
      goodParameterStatus_p = True;
   } else {
      goodParameterStatus_p = False;
   }
//
   UnitMap::putUser("pix",UnitVal(1.0), "pixel units");
}

template <class T>
ImageMoments<T>::ImageMoments(const ImageMoments<T> &other)
: pInImage_p(0)
{
   operator=(other);
}

template <class T>
ImageMoments<T>::ImageMoments(ImageMoments<T> &other)
: pInImage_p(0)
{
   operator=(other);
}


template <class T> 
ImageMoments<T>::~ImageMoments ()
{
   delete pInImage_p;
}


template <class T>
ImageMoments<T> &ImageMoments<T>::operator=(const ImageMoments<T> &other)
//
// Assignment operator
//
{
   if (this != &other) {
      
// Deal with image pointer
 
      if (pInImage_p!=0) delete pInImage_p;
      pInImage_p = other.pInImage_p->cloneII();
 
// Do the rest

      os_p = other.os_p;
      showProgress_p = other.showProgress_p;
      momentAxis_p = other.momentAxis_p;
      worldMomentAxis_p = other.worldMomentAxis_p;
      momentAxisDefault_p = other.momentAxisDefault_p;
      kernelTypes_p = other.kernelTypes_p.copy();
      kernelWidths_p = other.kernelWidths_p.copy();
      nxy_p = other.nxy_p.copy();
      moments_p = other.moments_p.copy();
      selectRange_p = other.selectRange_p.copy();
      smoothAxes_p = other.smoothAxes_p.copy();
      peakSNR_p = other.peakSNR_p;
      stdDeviation_p = other.stdDeviation_p;
      yMin_p = other.yMin_p;
      yMax_p = other.yMax_p;
      plotter_p = other.plotter_p;
      smoothOut_p = other.smoothOut_p;
      goodParameterStatus_p = other.goodParameterStatus_p;
      doWindow_p = other.doWindow_p;
      doFit_p = other.doFit_p;
      doAuto_p = other.doAuto_p;
      doSmooth_p = other.doSmooth_p;
      noInclude_p = other.noInclude_p;
      noExclude_p = other.noExclude_p;
      fixedYLimits_p = other.fixedYLimits_p;
      overWriteOutput_p = other.overWriteOutput_p;
      error_p = other.error_p;
      convertToVelocity_p = other.convertToVelocity_p;
      velocityType_p = other.velocityType_p;
   }
   return *this;
}


template <class T> 
Bool ImageMoments<T>::setNewImage(ImageInterface<T>& image)

//
// Assign pointer to image
//
{
   if (!goodParameterStatus_p) {
      os_p << LogIO::SEVERE << "Internal class status is bad" << LogIO::POST;
      return False;
   }

   T *dummy = 0;
   DataType imageType = whatType(dummy);

   if (imageType !=TpFloat && imageType != TpDouble) {
      ostringstream oss;
      oss << "Moments can only be evaluated from images of type : " <<
              TpFloat << " and " << TpDouble << endl;
      String tmp(oss); 
      os_p << LogIO::SEVERE << tmp << LogIO::POST;
//
      goodParameterStatus_p = False;
      return False;
   }

// Make a clone of the image   
    
   if (pInImage_p!=0) delete pInImage_p;
   pInImage_p = image.cloneII();
//
   return True;
}


template <class T>
Bool ImageMoments<T>::setMoments(const Vector<Int>& momentsU)
//
// Assign the desired moments
//
{
   if (!goodParameterStatus_p) {
      error_p = "Internal class status is bad";
      return False;
   }

   moments_p.resize(0);
   moments_p = momentsU;


// Check number of moments

   uInt nMom = moments_p.nelements();
   if (nMom == 0) {
      error_p = "No moments requested";
      goodParameterStatus_p = False;
      return False;
   } else if (nMom > NMOMENTS) {
      error_p = "Too many moments specified";
      goodParameterStatus_p = False;
      return False;
   }

   for (uInt i=0; i<nMom; i++) {
      if (moments_p(i) < 0 || moments_p(i) > NMOMENTS-1) {
         error_p = "Illegal moment requested";
         goodParameterStatus_p = False;
         return False;
      }
   }
   return True;
}


template <class T>
Bool ImageMoments<T>::setMomentAxis(const Int& momentAxisU)
//
// Assign the desired moment axis.  Zero relative.
//
{
   if (!goodParameterStatus_p) {
      error_p = "Internal class status is bad";
      return False;
   }

   momentAxis_p = momentAxisU;
   if (momentAxis_p == momentAxisDefault_p) {
     momentAxis_p = CoordinateUtil::findSpectralAxis(pInImage_p->coordinates());
     if (momentAxis_p == -1) {
       error_p = "There is no spectral axis in this image -- specify the axis";
       goodParameterStatus_p = False;
       return False;
     }
   } else {
      if (momentAxis_p < 0 || momentAxis_p > Int(pInImage_p->ndim()-1)) {
         error_p = "Illegal moment axis; out of range";
         goodParameterStatus_p = False;
         return False;
      }
      if (pInImage_p->shape()(momentAxis_p) <= 1) {
         error_p = "Illegal moment axis; it has only 1 pixel";
         goodParameterStatus_p = False;
         return False;
      }
   }
   worldMomentAxis_p = pInImage_p->coordinates().pixelAxisToWorldAxis(momentAxis_p);

   return True;
}



template <class T>
Bool ImageMoments<T>::setWinFitMethod(const Vector<Int>& methodU)
//
// Assign the desired windowing and fitting methods
//
{

   if (!goodParameterStatus_p) {
      error_p = "Internal class status is bad";
      return False;
   }

// No extra methods set

   if (methodU.nelements() == 0) return True;


// Check legality

   for (uInt i = 0; i<uInt(methodU.nelements()); i++) {
      if (methodU(i) < 0 || methodU(i) > NMETHODS-1) {
         error_p = "Illegal method given";
         goodParameterStatus_p = False;
         return False;
      }
   }


// Assign Boooools

   linearSearch(doWindow_p, methodU, Int(WINDOW), methodU.nelements());
   linearSearch(doFit_p, methodU, Int(FIT), methodU.nelements());
   linearSearch(doAuto_p, methodU, Int(INTERACTIVE), methodU.nelements());
   doAuto_p  = (!doAuto_p);

   return True;
}


template <class T>
Bool ImageMoments<T>::setSmoothMethod(const Vector<Int>& smoothAxesU,
                                      const Vector<Int>& kernelTypesU,
                                      const Vector<Double>& kernelWidthsU)
{
   const uInt n = kernelWidthsU.nelements();
   Vector<Quantum<Double> > t(n);
   for (uInt i=0; i<n; i++) {
      t(i) = Quantum<Double>(kernelWidthsU(i),String("pix"));
   }
   return setSmoothMethod(smoothAxesU, kernelTypesU, t);
}

template <class T>
Bool ImageMoments<T>::setSmoothMethod(const Vector<Int>& smoothAxesU,
                                      const Vector<Int>& kernelTypesU,
                                      const Vector<Quantum<Double> >& kernelWidthsU)
//
// Assign the desired smoothing parameters. 
//
{
   if (!goodParameterStatus_p) {
      error_p = "Internal class status is bad";
      return False;
   }
 

// First check the smoothing axes

   Int i;
   if (smoothAxesU.nelements() > 0) {
      smoothAxes_p = smoothAxesU;
      for (i=0; i<Int(smoothAxes_p.nelements()); i++) {
         if (smoothAxes_p(i) < 0 || smoothAxes_p(i) > Int(pInImage_p->ndim()-1)) {
            error_p = "Illegal smoothing axis given";
            goodParameterStatus_p = False;
            return False;
         }
      }
      doSmooth_p = True;
   } else {
      doSmooth_p = False;
      return True;
   }


// Now check the smoothing types

   if (kernelTypesU.nelements() > 0) {
      kernelTypes_p = kernelTypesU;
      for (i=0; i<Int(kernelTypes_p.nelements()); i++) {
         if (kernelTypes_p(i) < 0 || kernelTypes_p(i) > VectorKernel::NKERNELS-1) {
            error_p = "Illegal smoothing kernel types given";
            goodParameterStatus_p = False;
            return False;
         }
      }
   } else {
      error_p = "Smoothing kernel types were not given";
      goodParameterStatus_p = False;
      return False;
   }


// Check user gave us enough smoothing types
 
   if (smoothAxesU.nelements() != kernelTypes_p.nelements()) {
      error_p = "Different number of smoothing axes to kernel types";
      goodParameterStatus_p = False;
      return False;
   }


// Now the desired smoothing kernels widths.  Allow for Hanning
// to not be given as it is always 1/4, 1/2, 1/4

   kernelWidths_p.resize(smoothAxes_p.nelements());
   Int nK = kernelWidthsU.nelements();
   for (i=0; i<Int(smoothAxes_p.nelements()); i++) {
      if (kernelTypes_p(i) == VectorKernel::HANNING) {

// For Hanning, width is always 3pix

         Quantum<Double> tmp(3.0, String("pix"));
         kernelWidths_p(i) = tmp;
      } else if (kernelTypes_p(i) == VectorKernel::BOXCAR) {

// For box must be odd number greater than 1

         if (i > nK-1) {
            error_p = "Not enough smoothing widths given";
            goodParameterStatus_p = False;
            return False;
         } else {
            kernelWidths_p(i) = kernelWidthsU(i);
         }
      } else if (kernelTypes_p(i) == VectorKernel::GAUSSIAN) {
         if (i > nK-1) {
            error_p = "Not enough smoothing widths given";
            goodParameterStatus_p = False;
            return False;
         } else {
            kernelWidths_p(i) = kernelWidthsU(i);
         }
      } else {
         error_p = "Internal logic error";
         goodParameterStatus_p = False;
         return False;
      }
   }

   return True;
}


template <class T>  
Bool ImageMoments<T>::setInExCludeRange(const Vector<T>& includeU,
                                        const Vector<T>& excludeU)
//
// Assign the desired exclude range           
//
{
   if (!goodParameterStatus_p) {
      error_p = "Internal class status is bad";
      return False;
   }

   Vector<T> include = includeU;
   Vector<T> exclude = excludeU;

   ostringstream os;
   if (!setIncludeExclude(selectRange_p, noInclude_p, noExclude_p,
                          include, exclude, os)) {
      error_p = "Invalid pixel inclusion/exclusion ranges";
      goodParameterStatus_p = False;
      return False;
   }
   return True; 
}


template <class T> 
Bool ImageMoments<T>::setSnr(const T& peakSNRU,
                             const T& stdDeviationU)
//
// Assign the desired snr.  The default assigned in
// the constructor is 3,0
//
{
   if (!goodParameterStatus_p) {
      error_p = "Internal class status is bad";
      return False;
   }

   if (peakSNRU <= 0.0) {
      peakSNR_p = T(3.0);
   } else {
      peakSNR_p = peakSNRU;
   }
   if (stdDeviationU <= 0.0) {
      stdDeviation_p = 0.0;
   } else {
      stdDeviation_p = stdDeviationU;
   }

   return True;
} 




template <class T>
Bool ImageMoments<T>::setSmoothOutName(const String& smoothOutU) 
//
// Assign the desired smoothed image output file name
// 
{ 
   if (!goodParameterStatus_p) {
      error_p = "Internal class status is bad";
      return False;
   }
//
   if (!overWriteOutput_p) {
      NewFile x;
      String error;
      if (!x.valueOK(smoothOutU, error)) {
         return False;
      }
   }
//
   smoothOut_p = smoothOutU;  
   return True;
}


template <class T>
Bool ImageMoments<T>::setPlotting(PGPlotter& plotterU,
                                  const Vector<Int>& nxyU,
                                  const Bool yIndU)
//   
// Assign the desired PGPLOT device name and number
// of subplots
//
{ 
   if (!goodParameterStatus_p) {
      error_p = "Internal class status is bad";
      return False;
   }

// Is new plotter attached ?
         
   if (!plotterU.isAttached()) {
       error_p = "Input plotter is not attached";
      goodParameterStatus_p = False;
      return False;
   }

// Don't reattach to the same plotter.  The assignment will
// close the previous device
   
   if (plotter_p.isAttached()) {
      if (plotter_p.qid() != plotterU.qid()) plotter_p = plotterU;
   } else {
      plotter_p = plotterU;
   }


// Set number subplots

   fixedYLimits_p = (!yIndU);
   nxy_p.resize(0);
   nxy_p = nxyU;
   if (!LatticeStatsBase::setNxy(nxy_p, os_p.output())) {
      goodParameterStatus_p = False;
      return False;
   }
   return True;
}
 

template <class T>
void ImageMoments<T>::closePlotting()
{  
   if (plotter_p.isAttached()) plotter_p.detach();
}

template <class T>
void ImageMoments<T>::setVelocityType(MDoppler::Types velocityType)
{
   velocityType_p = velocityType;
}



template <class T>
Vector<Int> ImageMoments<T>::toMethodTypes (const String& methods)
// 
// Helper function to convert a string containing a list of desired smoothed kernel types
// to the correct <src>Vector<Int></src> required for the <src>setSmooth</src> function.
// 
// Inputs:
//   methods     SHould contain some of "win", "fit", "inter"
//
{
   Vector<Int> methodTypes(3);
   if (!methods.empty()) {
      String tMethods = methods;
      tMethods.upcase();

      Int i = 0;
      if (tMethods.contains("WIN")) {
         methodTypes(i) = WINDOW;
         i++;
      }
      if (tMethods.contains("FIT")) {
         methodTypes(i) = FIT;
         i++;
      }
      if (tMethods.contains("INTER")) {
         methodTypes(i) = INTERACTIVE;
         i++;
      }
      methodTypes.resize(i, True);
   } else {
      methodTypes.resize(0);
   }
   return methodTypes;
} 


template <class T>
Bool ImageMoments<T>::createMoments(PtrBlock<MaskedLattice<T>* >& outPt,
                                    Bool doTemp, const String& outName,
                                    Bool removeAxis)
//
// This function does all the work
//
{
   if (!goodParameterStatus_p) {
      error_p = "Internal status of class is bad.  You have ignored errors";
      return False;
   }

// Find spectral axis 

   const CoordinateSystem& cSys = pInImage_p->coordinates();
   Int spectralAxis = CoordinateUtil::findSpectralAxis(cSys);
//
   if (momentAxis_p == momentAxisDefault_p) {
     if (spectralAxis==-1) {
       error_p = "There is no spectral axis in this image -- specify the moment axis";
       return False;
     }
     momentAxis_p = spectralAxis;
//
     if (pInImage_p->shape()(momentAxis_p) <= 1) {
        error_p = "Illegal moment axis; it has only 1 pixel";
        goodParameterStatus_p = False;
        return False;
     }
     worldMomentAxis_p = cSys.pixelAxisToWorldAxis(momentAxis_p);
   }
   String momentAxisUnits = cSys.worldAxisUnits()(worldMomentAxis_p);
   os_p << LogIO::NORMAL << endl << "Moment axis type is "
        << cSys.worldAxisNames()(worldMomentAxis_p) << LogIO::POST;

// If the moment axis is a spectral axis, indicate we want to convert to velocity

   convertToVelocity_p = False;
   if (momentAxis_p == spectralAxis) convertToVelocity_p = True;

// Check the user's requests are allowed

   if (!checkMethod()) return False;

// Check that input and output image names aren't the same.
// if there is only one output image

   if (moments_p.nelements() == 1 && !doTemp) {
      if (!outName.empty() && (outName == pInImage_p->name())) {
         error_p = "Input image and output image have same name";
         return False;
      }
   } 

// Try and set some useful Booools.

   Bool smoothClipMethod = False;
   Bool windowMethod = False;
   Bool fitMethod = False;
   Bool clipMethod = False;
   Bool doPlot = plotter_p.isAttached();

   if (doSmooth_p && !doWindow_p) {
      smoothClipMethod = True;      
   } else if (doWindow_p) {
      windowMethod = True;
   } else if (doFit_p) {
      fitMethod = True;
   } else {
      clipMethod = True;
   }     

// We only smooth the image if we are doing the smooth/clip method
// or possibly the interactive window method.  Note that the convolution
// routines can only handle convolution when the image fits fully in core
// at present.
   
   PtrHolder<ImageInterface<T> > pSmoothedImageHolder;
   ImageInterface<T>* pSmoothedImage = 0;
   String smoothName;
   if (doSmooth_p) {
      if (!smoothImage(pSmoothedImageHolder, smoothName)) return False;
      pSmoothedImage = pSmoothedImageHolder.ptr();

// Find the auto Y plot range.   The smooth & clip and the window
// methods only plot the smoothed data.

      if (doPlot && fixedYLimits_p && (smoothClipMethod || windowMethod)) {
         ImageStatistics<T> stats(*pSmoothedImage, False);
         Array<T> data;
         stats.getConvertedStatistic(data, LatticeStatsBase::MIN, True);
         yMin_p = data(IPosition(data.nelements(),0));
         stats.getConvertedStatistic(data, LatticeStatsBase::MAX, True);
         yMax_p = data(IPosition(data.nelements(),0));
      }
   }


// Find the auto Y plot range if not smoothing and stretch
// limits for plotting

   if (fixedYLimits_p && doPlot) {
      if (!doSmooth_p && (clipMethod || windowMethod || fitMethod)) {
         ImageStatistics<T> stats(*pInImage_p, False);
         Array<T> data;
//
         if (!stats.getConvertedStatistic(data, LatticeStatsBase::MIN, True)) {
            error_p = "Error finding minimum of input image";
            return False;
         }
         yMin_p = data(IPosition(data.nelements(),0));
//
         if (!stats.getConvertedStatistic(data, LatticeStatsBase::MAX, True)) {
            error_p = "Error finding maximum of input image";
            return False;
         }
         yMax_p = data(IPosition(data.nelements(),0));
      }
   }


// Set output images shape and coordinates.
   
   IPosition outImageShape;
   CoordinateSystem cSysOut = makeOutputCoordinates (outImageShape, cSys, 
                                                     pInImage_p->shape(),
                                                     momentAxis_p, removeAxis);

// Resize the vector of pointers for output images 

   outPt.resize(moments_p.nelements());
   for (uInt i=0; i<outPt.nelements(); i++) outPt[i] = 0;

// Loop over desired output moments

   String suffix;
   Bool goodUnits;
   Bool giveMessage = True;
   Unit imageUnits = pInImage_p->units();
//   
   for (uInt i=0; i<moments_p.nelements(); i++) {

// Set moment image units and assign pointer to output moments array
// Value of goodUnits is the same for each output moment image

      Unit momentUnits;
      goodUnits = setOutThings(suffix, momentUnits, imageUnits, momentAxisUnits, 
                               moments_p(i), convertToVelocity_p);
//   
// Create output image(s).    Either PagedImage or TempImage
//
      ImageInterface<Float>* imgp = 0;
      if (!doTemp) {
         const String in = pInImage_p->name(False);   
         String outFileName;
         if (moments_p.nelements() == 1) {
            if (outName.empty()) {
               outFileName = in + suffix;
            } else {
               outFileName = outName;
            }
         } else {
            if (outName.empty()) {
               outFileName = in + suffix;
            } else {
               outFileName = outName + suffix;
            }
         }
//
         if (!overWriteOutput_p) {
            NewFile x;
            String error;
            if (!x.valueOK(outFileName, error)) {
               os_p << LogIO::NORMAL << error << LogIO::POST;
               return False;
            }
         }
 //
         imgp = new PagedImage<T>(outImageShape, cSysOut, outFileName);         
         os_p << LogIO::NORMAL << "Created " << outFileName << LogIO::POST;
      } else {
         imgp = new TempImage<T>(TiledShape(outImageShape), cSysOut);
         os_p << LogIO::NORMAL << "Created TempImage" << LogIO::POST;
      }
//
      if (imgp==0) {
         for (uInt j=0; j<i; j++) delete outPt[j];
         os_p << "Failed to create output file" << LogIO::EXCEPTION;        
      }
      imgp->setMiscInfo(pInImage_p->miscInfo());
      imgp->setImageInfo(pInImage_p->imageInfo());
      imgp->appendLog(pInImage_p->logger());
      imgp->makeMask ("mask0", True, True);

// Set output image units if possible

      if (goodUnits) {
         imgp->setUnits(momentUnits);
      } else {
        if (giveMessage) {
           os_p << LogIO::NORMAL 
                << "Could not determine the units of the moment image(s) so the units " << endl;
           os_p << "will be the same as those of the input image. This may not be very useful." << LogIO::POST;
           giveMessage = False;
        }
      }

// Assign pointer to block

      outPt[i] = imgp;
   } 


// If the user is using the automatic, non-fitting window method, they need
// a good assement of the noise.  The user can input that value, but if
// they don't, we work it out here.

   T noise;
   if (stdDeviation_p <= T(0) && ( (doWindow_p && doAuto_p) || (doFit_p && !doWindow_p && doAuto_p) ) ) {
      if (pSmoothedImage) {
         os_p << LogIO::NORMAL << "Evaluating noise level from smoothed image" << LogIO::POST;
         if (!whatIsTheNoise (noise, *pSmoothedImage)) return False;
      } else {
         os_p << LogIO::NORMAL << "Evaluating noise level from input image" << LogIO::POST;
         if (!whatIsTheNoise (noise, *pInImage_p)) return False;
      }
      stdDeviation_p = noise;
   }


// Set up some plotting things
         
   if (doPlot) {
      plotter_p.subp(nxy_p(0), nxy_p(1));
      plotter_p.ask(True);
      plotter_p.sch(1.5);
      plotter_p.vstd();
   }        
   

// Create appropriate MomentCalculator object 

   os_p << LogIO::NORMAL << "Begin computation of moments" << LogIO::POST;
   PtrHolder<MomentCalcBase<T> > pMomentCalculatorHolder;
   try {
      if (clipMethod || smoothClipMethod) {
         pMomentCalculatorHolder.set(new MomentClip<T>(pSmoothedImage, *this, os_p, outPt.nelements()),
                                     False, False);
      } else if (windowMethod) {
         pMomentCalculatorHolder.set(new MomentWindow<T>(pSmoothedImage, *this, os_p, outPt.nelements()),
                                     False, False);
      } else if (fitMethod) {
         pMomentCalculatorHolder.set(new MomentFit<T>(*this, os_p, outPt.nelements()), False, False);
      }
   } catch (AipsError x) {

// Try and clean up so if we are called by DO, images dont get stuck open in cache
// If an exception is generated.  Can't use PtrHolder here

      for (uInt i=0; i<outPt.nelements(); i++) delete outPt[i];
   }


// Iterate optimally through the image, compute the moments, fill the output lattices

   MomentCalcBase<T>* pMomentCalculator = pMomentCalculatorHolder.ptr();
   ImageMomentsProgress* pProgressMeter = 0;
   if (showProgress_p) pProgressMeter = new ImageMomentsProgress();
   try {
      LatticeApply<T>::lineMultiApply(outPt, *pInImage_p, *pMomentCalculator, momentAxis_p, pProgressMeter);
   } catch (AipsError x) {

// Try and clean up so if we are called by DO, images dont get stuck open in cache
// If an exception is generated.  Can't use PtrHolder here

      for (uInt i=0; i<outPt.nelements(); i++) delete outPt[i];
   }


// Clean up
         
   if (windowMethod || fitMethod) {
      if (pMomentCalculator->nFailedFits() != 0) {
         os_p << LogIO::NORMAL << "There were " <<  pMomentCalculator->nFailedFits() << " failed fits" << LogIO::POST;
      }
   }
   if (pProgressMeter != 0) delete pProgressMeter;
//
   if (pSmoothedImage) {
       
// Remove the smoothed image file if they don't want to save it

      pSmoothedImageHolder.clear(True); 
      if (smoothOut_p.empty()) {
         Directory dir(smoothName);
         dir.removeRecursive();
      }
   }

// Success guarenteed !

   return True;

}





// Private member functions

template <class T> 
Bool ImageMoments<T>::checkMethod ()
{

// Make a plotting check. They must give the plotting device for interactive methods.  
// Plotting can be invoked passively for other methods.

   if ( ((doWindow_p && !doAuto_p) ||
         (!doWindow_p && doFit_p && !doAuto_p)) && !plotter_p.isAttached()) {
      error_p = "You have not given a plotting device";
      return False;
   } 


// Only can have the median coordinate under certain conditions
   
   Bool found;
   if(linearSearch(found, moments_p, Int(MEDIAN_COORDINATE), moments_p.nelements()) != -1) {
      Bool noGood = False;
      if (doWindow_p || doFit_p || doSmooth_p) {
         noGood = True;
      } else {
         if (noInclude_p && noExclude_p) {
            noGood = True;
         } else {
           if (selectRange_p(0)*selectRange_p(1) < T(0)) noGood = True;
         }
      }
      if (noGood) {
         os_p << LogIO::SEVERE;
         os_p << "You have asked for the median coordinate moment, but it is only" << endl;
         os_p << "available with the basic (no smooth, no window, no fit) method " << endl;
         os_p << "and a pixel range that is either all positive or all negative" << LogIO::POST;
         return False;
      }
   }


// Now check all the silly methods

   const Bool doInter = (!doAuto_p);
   if (!( (!doSmooth_p && !doWindow_p && !doFit_p && ( noInclude_p &&  noExclude_p) && !doInter) ||
          ( doSmooth_p && !doWindow_p && !doFit_p && (!noInclude_p || !noExclude_p) && !doInter) ||
          (!doSmooth_p && !doWindow_p && !doFit_p && (!noInclude_p || !noExclude_p) && !doInter) ||

          ( doSmooth_p &&  doWindow_p && !doFit_p && ( noInclude_p &&  noExclude_p) &&  doInter) ||
          (!doSmooth_p &&  doWindow_p && !doFit_p && ( noInclude_p &&  noExclude_p) &&  doInter) ||
          ( doSmooth_p &&  doWindow_p && !doFit_p && ( noInclude_p &&  noExclude_p) && !doInter) ||
          (!doSmooth_p &&  doWindow_p && !doFit_p && ( noInclude_p &&  noExclude_p) && !doInter) ||
          (!doSmooth_p &&  doWindow_p &&  doFit_p && ( noInclude_p &&  noExclude_p) &&  doInter) ||
          (!doSmooth_p &&  doWindow_p &&  doFit_p && ( noInclude_p &&  noExclude_p) && !doInter) ||
          ( doSmooth_p &&  doWindow_p &&  doFit_p && ( noInclude_p &&  noExclude_p) &&  doInter) ||
          ( doSmooth_p &&  doWindow_p &&  doFit_p && ( noInclude_p &&  noExclude_p) && !doInter) ||
   
          (!doSmooth_p && !doWindow_p &&  doFit_p && ( noInclude_p &&  noExclude_p) &&  doInter) ||
          (!doSmooth_p && !doWindow_p &&  doFit_p && ( noInclude_p &&  noExclude_p) && !doInter) )) {

      os_p << LogIO::NORMAL << "You have asked for an invalid combination of methods" << LogIO::POST;
      os_p << LogIO::NORMAL << "Valid combinations are: " << LogIO::POST << LogIO::POST;



      os_p <<  "Smooth    Window      Fit   in/exclude   Interactive " << endl;
      os_p <<  "-----------------------------------------------------" << endl;
   
// Basic method. Just use all the data
   
      os_p <<  "  N          N         N        N            N       " << endl;
                       
// Smooth and clip, or just clip
                  
      os_p <<  "  Y/N        N         N        Y            N       " << endl << endl;
                  
// Direct interactive window selection with or without smoothing
                  
      os_p <<  "  Y/N        Y         N        N            Y       " << endl;

// Automatic windowing via Bosma's algorithm with or without smoothing
 
      os_p <<  "  Y/N        Y         N        N            N       " << endl;

// Windowing by fitting Gaussians (selecting +/- 3-sigma) automatically or interactively 
// with or without out smoothing
          
      os_p <<  "  Y/N        Y         Y        N            Y/N     " << endl;
          
// Interactive and automatic Fitting of Gaussians and the moments worked out
// directly from the fits
          
      os_p <<  "  N          N         Y        N            Y/N     " << endl << endl;


      os_p <<  "You have asked for" << endl << endl;
      if (doSmooth_p) 
         os_p <<  "  Y";
      else
         os_p <<  "  N";

      if (doWindow_p) {
         os_p <<  "          Y";
      } else {
         os_p <<  "          N";
      }
      if (doFit_p) {
         os_p <<  "         Y";
      } else {
         os_p <<  "         N";
      }
      if (noInclude_p && noExclude_p) {
         os_p <<  "        N";
      } else {
         os_p <<  "        Y";
      }
      if (doInter) {
         os_p <<  "            Y";
      } else {
         os_p <<  "            N";
      }
      os_p <<  endl;
      os_p <<  "-----------------------------------------------------" << endl << LogIO::POST;
      return False;
   }


// Tell them what they are getting
          
   os_p << endl << endl
        << "***********************************************************************" << endl;
   os_p << LogIO::NORMAL << "You have selected the following methods" << endl;
   if (doWindow_p) {
      os_p << "The window method" << endl;
      if (doFit_p) {
         if (doInter) {
            os_p << "   with window selection via interactive Gaussian fitting" << endl;
         } else {
            os_p << "   with window selection via automatic Gaussian fitting" << endl;
         }
      } else {
         if (doInter) {
            os_p << "   with interactive direct window selection" << endl;
         } else {
            os_p << "   with automatic window selection via the converging mean (Bosma) algorithm" << endl;
         }
      }           
      if (doSmooth_p) {
         os_p << "   operating on the smoothed image.  The moments are still" << endl;
         os_p << "   evaluated from the unsmoothed image" << endl;
      } else {
         os_p << "   operating on the unsmoothed image" << endl;
      }
   } else if (doFit_p) {
      if (doInter) {
         os_p << "The interactive Gaussian fitting method" << endl;
      } else {
         os_p << "The automatic Gaussian fitting method" << endl;
      }          
      os_p << "   operating on the unsmoothed data" << endl;
      os_p << "   The moments are evaluated from the fits" << endl;
   } else if (doSmooth_p) {
      os_p << "The smooth and clip method.  The moments are evaluated from" << endl;
      os_p << "   the masked unsmoothed image" << endl;
   } else {
      if (noInclude_p && noExclude_p) {
         os_p << "The basic method" << endl;
      } else {
         os_p << "The basic clip method" << endl;
      }
   }
   os_p << endl << endl << LogIO::POST;
   
      
   return True;   
}



template <class T> 
void ImageMoments<T>::drawHistogram (const Vector<T>& x,
                                     const Vector<T>& y,
                                     PGPlotter& plotter)
{
   plotter.box ("BCNST", 0.0, 0, "BCNST", 0.0, 0);
   plotter.lab ("Intensity", "Number", "");

   const Float width = convertT(x(1) - x(0)) / 2.0;
   Float xx, yy;

   for (uInt i=0; i<x.nelements(); i++) {
      xx = convertT(x(i)) - width;
      yy = convertT(y(i));
   
      plotter.move (xx, 0.0);
      plotter.draw (xx, yy);
         
      plotter.move (xx, yy);
      xx = x(i) + width;
      plotter.draw (xx, yy);
   
      plotter.move (xx, yy);
      plotter.draw (xx, 0.0);
    }
}
 


template <class T> 
void ImageMoments<T>::drawVertical (const T& loc,
                                    const T& yMin,
                                    const T& yMax,
                                    PGPlotter& plotter) 
{
// If the colour index is zero, we are trying to rub something
// out, so don't monkey with the ci then

   Int ci;
   ci = plotter.qci();
   if (ci!=0) plotter.sci (3);

   plotter.move (convertT(loc), convertT(yMin));
   plotter.draw (convertT(loc), convertT(yMax));
   plotter.updt();
   plotter.sci (ci);
}


template <class T> 
void ImageMoments<T>::drawLine (const Vector<T>& x,
                                const Vector<T>& y,
                                PGPlotter& plotter)
//
// Draw  a spectrum on the current panel
// with the box already drawn
//
{
// Copy from templated floating type to float

   const uInt n = x.nelements();
   Vector<Float> xData(n);
   Vector<Float> yData(n);
   for (uInt i=0; i<n; i++) {
      xData(i) = convertT(x(i));
      yData(i) = convertT(y(i));
   }
   plotter.line (xData, yData);
   plotter.updt ();
}



template <class T> 
Bool ImageMoments<T>::getLoc (T& x,
                              T& y,
                              PGPlotter& plotter)
//
// Read the PGPLOT cursor and return its coordinates if not 
// off the plot and any button other than last pushed
//
{
// Fish out window

   Vector<Float> minMax(4);
   minMax = plotter.qwin();

// Position and read cursor

   Float xx = convertT(x);
   Float yy = convertT(y);
   String str;

   readCursor(plotter, xx, yy, str);
   if (xx >= minMax(0) && xx <= minMax(1) && 
       yy >= minMax(2) && yy <= minMax(3)) {
      x = xx;
      y = yy;
   } else {
      plotter.message("Cursor out of range");
      return False;
   }
   return True;
}





template <class T> 
Bool ImageMoments<T>::setOutThings(String& suffix, 
                                   Unit& momentUnits,
                                   const Unit& imageUnits,
                                   const String& momentAxisUnits,
                                   const Int moment,
                                   Bool convertToVelocity)
//
// Set the output image suffixes and units
//
// Input:
//   momentAxisUnits
//                The units of the moment axis
//   moment       The current selected moment
//   imageUnits   The brightness units of the input image.
//   convertToVelocity
//                The moment axis is the spectral axis and
//                world coordinates must be converted to km/s
// Outputs:
//   momentUnits  The brightness units of the moment image. Depends upon moment type
//   suffix       suffix for output file name
//   Bool         True if could set units for moment image, false otherwise
{
   String temp;
//
   Bool goodUnits = True;
   Bool goodImageUnits = (!imageUnits.getName().empty());
   Bool goodAxisUnits = (!momentAxisUnits.empty());
//
   if (moment == AVERAGE) {
      suffix = ".average";
      temp = imageUnits.getName();
      goodUnits = goodImageUnits;
   } else if (moment == INTEGRATED) {
      suffix = ".integrated";
      temp = imageUnits.getName() + "." + momentAxisUnits;
      if (convertToVelocity) temp = imageUnits.getName() + String(".km/s");
      goodUnits = (goodImageUnits && goodAxisUnits);
   } else if (moment == WEIGHTED_MEAN_COORDINATE) {
      suffix = ".weighted_coord";
      temp = momentAxisUnits;
      if (convertToVelocity) temp = String("km/s");
      goodUnits = goodAxisUnits;
   } else if (moment == WEIGHTED_DISPERSION_COORDINATE) {
      suffix = ".weighted_dispersion_coord";
      temp = momentAxisUnits + "." + momentAxisUnits;
      if (convertToVelocity) temp = String("km/s");
      goodUnits = goodAxisUnits;
   } else if (moment == MEDIAN) {
      suffix = ".median";
      temp = imageUnits.getName();
      goodUnits = goodImageUnits;
   } else if (moment == STANDARD_DEVIATION) {
      suffix = ".standard_deviation";
      temp = imageUnits.getName();
      goodUnits = goodImageUnits;
   } else if (moment == RMS) {
      suffix = ".rms";
      temp = imageUnits.getName();
      goodUnits = goodImageUnits;
   } else if (moment == ABS_MEAN_DEVIATION) {
      suffix = ".abs_mean_dev";
      temp = imageUnits.getName();
      goodUnits = goodImageUnits;
   } else if (moment == MAXIMUM) {
      suffix = ".maximum";
      temp = imageUnits.getName();
      goodUnits = goodImageUnits;
   } else if (moment == MAXIMUM_COORDINATE) {
      suffix = ".maximum_Coord";
      temp = momentAxisUnits;
      if (convertToVelocity) temp = String("km/s");
      goodUnits = goodAxisUnits;
   } else if (moment == MINIMUM) {
      suffix = ".minimum";
      temp = imageUnits.getName();
      goodUnits = goodImageUnits;
   } else if (moment == MINIMUM_COORDINATE) {
      suffix = ".minimum_coord";
      temp = momentAxisUnits;
      if (convertToVelocity) temp = String("km/s");
      goodUnits = goodAxisUnits;
   } else if (moment == MEDIAN_COORDINATE) {
      suffix = ".median_coord";
      temp = momentAxisUnits;
      if (convertToVelocity) temp = String("km/s");
      goodUnits = goodAxisUnits;
   }
   if (goodUnits) momentUnits.setName(temp);
   return goodUnits;
}

template <class T> 
Bool ImageMoments<T>::smoothImage (PtrHolder<ImageInterface<T> >& pSmoothedImage,
                                   String& smoothName)
//
// Smooth image.   Input masked pixels are zerod before smoothing.
// The output smoothed image is masked as well to reflect
// the input mask.
//
// Output
//   pSmoothedImage PtrHolder for smoothed Lattice
//   smoothName     Name of smoothed image file
//   Bool           True for success
{

// Check axes

   Int axMax = max(smoothAxes_p) + 1;
   if (axMax > Int(pInImage_p->ndim())) {
      error_p = "You have specified an illegal smoothing axis";
      return False;
   }
      

// Create smoothed image as a PagedImage.  We delete it later
// if the user doesn't want to save it

   if (smoothOut_p.empty()) {
//
// We overwrite this image if it exists.
//
      File inputImageName(pInImage_p->name());
      const String path = inputImageName.path().dirName() + "/";
      Path fileName = File::newUniqueName(path, String("ImageMoments_Smooth_"));
      smoothName = fileName.absoluteName();
   } else {
//
// This image has already been checked in setSmoothOutName
// to not exist
//
      smoothName = smoothOut_p;
   }

   pSmoothedImage.set(new PagedImage<T>(pInImage_p->shape(), 
                      pInImage_p->coordinates(), smoothName),
                      False, False);
//  
   ImageInterface<T>* pSmIm = pSmoothedImage.ptr();
   pSmIm->setMiscInfo(pInImage_p->miscInfo());
   if (!smoothOut_p.empty()) {
      os_p << LogIO::NORMAL << "Created " << smoothName << LogIO::POST;
   }

// Do the convolution.  Conserve flux.

   Bool autoScale = True;
   Bool useImageShapeExactly = False;
   SepImageConvolver<T> sic(*pInImage_p, os_p, True);
   for (uInt i=0; i<smoothAxes_p.nelements(); i++) {
      VectorKernel::KernelTypes type = VectorKernel::KernelTypes(kernelTypes_p(i));
      sic.setKernel(uInt(smoothAxes_p(i)), type, kernelWidths_p(i), 
                    autoScale, useImageShapeExactly, 1.0);
   }
   sic.convolve(*pSmIm);
   return True;
}


template <class T>
Bool ImageMoments<T>::setIncludeExclude (Vector<T>& range,
                                         Bool& noInclude,
                                         Bool& noExclude,
                                         const Vector<T>& include,
                                         const Vector<T>& exclude,
                                         ostream& os)
//
// Take the user's data inclusion and exclusion data ranges and
// generate the range and Booleans to say what sort it is
//
// Inputs: 
//   include   Include range given by user. Zero length indicates
//             no include range
//   exclude   Exclude range given by user. As above.
//   os        Output stream for reporting
// Outputs:
//   noInclude If True user did not give an include range
//   noExclude If True user did not give an exclude range
//   range     A pixel value selection range.  Will be resized to
//             zero length if both noInclude and noExclude are True
//   Bool      True if successfull, will fail if user tries to give too
//             many values for includeB or excludeB, or tries to give
//             values for both
{  
   noInclude = True;
   range.resize(0);
   if (include.nelements() == 0) {
     ;   
   } else if (include.nelements() == 1) {
      range.resize(2);
      range(0) = -abs(include(0));
      range(1) =  abs(include(0));
      noInclude = False;
   } else if (include.nelements() == 2) {
      range.resize(2);   
      range(0) = min(include(0),include(1));
      range(1) = max(include(0),include(1));
      noInclude = False;
   } else {
      os << endl << "Too many elements for argument include" << endl;
      return False;
   }
 
   noExclude = True;
   if (exclude.nelements() == 0) {
      ;
   } else if (exclude.nelements() == 1) {
      range.resize(2);                      
      range(0) = -abs(exclude(0));
      range(1) =  abs(exclude(0));
      noExclude = False;
   } else if (exclude.nelements() == 2) {
      range.resize(2);
      range(0) = min(exclude(0),exclude(1));
      range(1) = max(exclude(0),exclude(1));
      noExclude = False;
   } else {
      os << endl << "Too many elements for argument exclude" << endl;
      return False;
   }
   if (!noInclude && !noExclude) {
      os << "You can only give one of arguments include or exclude" << endl;
      return False;
   }
   return True;   
}


template <class T> 
Bool ImageMoments<T>::whatIsTheNoise (T& sigma,
                                      ImageInterface<T>& image)
//
// Determine the noise level in the image by first making a histogram of 
// the image, then fitting a Gaussian between the 25% levels to give sigma
//
{

// Find a histogram of the image

   ImageHistograms<T> histo(image, False);
   const uInt nBins = 100;
   histo.setNBins(nBins);

// It is safe to use Vector rather than Array because 
// we are binning the whole image and ImageHistograms will only resize
// these Vectors to a 1-D shape

   Vector<T> values, counts;
   if (!histo.getHistograms(values, counts)) {
      error_p = "Unable to make histogram of image";
      return False;
   }

// Enter into a plot/fit loop

   T binWidth = values(1) - values(0);
   T xMin, xMax, yMin, yMax;
   xMin = values(0) - binWidth;
   xMax = values(nBins-1) + binWidth;
   Float xMinF = convertT(xMin);
   Float xMaxF = convertT(xMax);
   LatticeStatsBase::stretchMinMax(xMinF, xMaxF);

   IPosition yMinPos(1), yMaxPos(1);
   minMax (yMin, yMax, yMinPos, yMaxPos, counts);
   Float yMinF = 0.0;
   Float yMaxF = convertT(yMax);
   yMaxF += yMaxF/20;

   if (plotter_p.isAttached()) {
      plotter_p.subp(1,1);
      plotter_p.swin (xMinF, xMaxF, yMinF, yMaxF);
   }


   Bool first = True;
   Bool more = True;
   T x1, x2;
   while (more) {

// Plot histogram

      if (plotter_p.isAttached()) {
         plotter_p.page();
         drawHistogram (values, counts, plotter_p);
      }

      Int iMin = 0;
      Int iMax = 0;
      if (first) {
         first = False;
         iMax = yMaxPos(0);
	 uInt i;
         for (i=yMaxPos(0); i<nBins; i++) {
            if (counts(i) < yMax/4) {
               iMax = i; 
               break;
             }      
          } 
          iMin = yMinPos(0);
          for (i=yMaxPos(0); i>0; i--) { 
             if (counts(i) < yMax/4) {
                iMin = i; 
                break;
              }      
          }

// Check range is sensible

         if (iMax <= iMin || abs(iMax-iMin) < 3) {
           os_p << LogIO::NORMAL << "The image histogram is strangely shaped, fitting to all bins" << LogIO::POST;
           iMin = 0;
           iMax = nBins-1;
         }


// Draw on plot

         if (plotter_p.isAttached()) {
            x1 = values(iMin);
            x2 = values(iMax);
            drawVertical (x1, yMin, yMax, plotter_p);
            drawVertical (x2, yMin, yMax, plotter_p);
         }

      } else if (plotter_p.isAttached()) {

// We are redoing the fit so let the user mark where they think
// the window fit should be done

         x1 = (xMin+xMax)/2;
         T y1 = (yMin+yMax)/2;
         Int i1, i2;
         i1 = i2 = 0;
  
         plotter_p.message("Mark the locations for the window");
         while (i1==i2) {
            while (!getLoc(x1, y1, plotter_p)) {};
            i1 = Int((x1 - (values(0) - binWidth/2))/binWidth);
            i1 = min(Int(nBins-1),max(0,i1));
            drawVertical (values(i1), yMin, yMax, plotter_p);

            T x2 = x1;
            while (!getLoc(x2, y1, plotter_p)) {};
            i2 = Int((x2 - (values(0) - binWidth/2))/binWidth);
            i2 = min(Int(nBins-1),max(0,i2));
            drawVertical (values(i2), yMin, yMax, plotter_p);

            if (i1 == i2) {
               plotter_p.message("Degenerate window, try again");
               plotter_p.eras ();
               drawHistogram (values, counts, plotter_p);
            }
         }


// Set window 

         iMin = min(i1, i2);
         iMax = max(i1, i2);
      }

// Now generate the distribution we want to fit.  Normalize to
// peak 1 to help fitter.  

      const uInt nPts2 = iMax - iMin + 1; 
      Vector<T> xx(nPts2);
      Vector<T> yy(nPts2);
      Int i;
      for (i=iMin; i<=iMax; i++) {
         xx(i-iMin) = values(i);
         yy(i-iMin) = counts(i)/yMax;
      }


// Create fitter

      NonLinearFitLM<T> fitter;
      Gaussian1D<AutoDiff<T> > gauss;
      fitter.setFunction(gauss);


// Initial guess

      Vector<T> v(3);
      v(0) = 1.0;                          // height
      v(1) = values(yMaxPos(0));           // position
      v(2) = nPts2*binWidth/2;             // width


// Fit

      fitter.setParameterValues(v);
      fitter.setMaxIter(50);
      T tol = 0.001;
      fitter.setCriteria(tol);

      Vector<T> resultSigma(nPts2);
      resultSigma = 1;
      Vector<T> solution;
      Bool fail = False;
      try {
        solution = fitter.fit(xx, yy, resultSigma);
      } catch (AipsError x) {
        fail = True;
      } 
//      os_p << LogIO::NORMAL << "Solution=" << solution << LogIO::POST;


// Return values of fit 

      if (!fail && fitter.converged()) {
         sigma = T(abs(solution(2)) / sqrt(2.0));
         os_p << LogIO::NORMAL 
              << "*** The fitted standard deviation of the noise is " << sigma
              << endl << LogIO::POST;

// Now plot the fit 

         if (plotter_p.isAttached()) {
            Int nGPts = 100;
            T dx = (values(nBins-1) - values(0))/nGPts;

            Gaussian1D<T> gauss(solution(0), solution(1), abs(solution(2)));
            Vector<T> xG(nGPts);
            Vector<T> yG(nGPts);

            T xx;
            for (i=0,xx=values(0); i<nGPts; xx+=dx,i++) {
               xG(i) = xx;
               yG(i) = gauss(xx) * yMax;
            }
            plotter_p.sci (7);
            drawLine (xG, yG, plotter_p);
            plotter_p.sci (1);
         }
      } else {
         os_p << LogIO::NORMAL << "The fit to determine the noise level failed." << endl;
         os_p << "Try inputting it directly" << endl;
         if (plotter_p.isAttached()) os_p << "or try a different window " << LogIO::POST;
      }

// Another go

      if (plotter_p.isAttached()) {
         plotter_p.message("Accept (click left), redo (click middle), give up (click right)");

         Float xx = convertT(xMin+xMax)/2;
         Float yy = convertT(yMin+yMax)/2;
         String str;
         readCursor(plotter_p, xx, yy, str);
         str.upcase();
 
         if (str == "D") {
            plotter_p.message("Redoing fit");
         } else if (str == "X") {
            return False;
         } else {
            more = False;
         }
      } else {
         more = False;
      }
   }
     
   return True;

}


template <class T> 
Bool ImageMoments<T>::readCursor (PGPlotter& plotter, Float& x,
                                  Float& y, String& ch)
{
   Record r;
   r = plotter.curs(x, y);
   Bool gotCursor;
   r.get(RecordFieldId(0), gotCursor);
   r.get(RecordFieldId(1), x);
   r.get(RecordFieldId(2), y);
   r.get(RecordFieldId(3), ch);
   return gotCursor;
}
 

template <class T> 
CoordinateSystem ImageMoments<T>::makeOutputCoordinates (IPosition& outShape,
                                                         const CoordinateSystem& cSysIn,
                                                         const IPosition& inShape,
                                                         Int momentAxis, Bool removeAxis)
{

// Create

   CoordinateSystem cSysOut;
   cSysOut.setObsInfo(cSysIn.obsInfo());

// Find the Coordinate corresponding to the moment axis

   Int coord, axisInCoord;
   cSysIn.findPixelAxis(coord, axisInCoord, momentAxis);
   const Coordinate& c = cSysIn.coordinate(coord);


// Find the number of axes

   if (removeAxis) {

// Shape with moment axis removed

      uInt dimIn = inShape.nelements();
      uInt dimOut = dimIn - 1;
      outShape.resize(dimOut);
      uInt k = 0;
      for (uInt i=0; i<dimIn; i++) {
         if (Int(i) != momentAxis) {
            outShape(k) = inShape(i);
            k++;
         }
      }
//
      if (c.nPixelAxes()==1 && c.nWorldAxes()==1) {

// We can physically remove the coordinate and axis

         for (uInt i=0; i<cSysIn.nCoordinates(); i++) {

// If this coordinate is not the moment axis coordinate,
// and it has not been virtually removed in the input
// we add it to the output.  We don't cope with transposed 
// CoordinateSystems yet.

            Vector<Int> pixelAxes = cSysIn.pixelAxes(i);
            Vector<Int> worldAxes = cSysIn.worldAxes(i);
//
            if (Int(i)!=coord &&
                pixelAxes[0]>=0 && worldAxes[0]>=0) {
              cSysOut.addCoordinate(cSysIn.coordinate(i));
            }
         }
      } else {

// Remove just world and pixel axis but not the coordinate

         cSysOut = cSysIn;
         Int worldAxis = cSysOut.pixelAxisToWorldAxis(momentAxis);
         cSysOut.removeWorldAxis(worldAxis, cSysIn.referenceValue()(worldAxis));
      }
   } else {

// Retain the Coordinate and give the moment axis  shape 1. 

      outShape.resize(0);
      outShape = inShape;
      outShape(momentAxis) = 1;
      cSysOut = cSysIn;
   }   
//
   return cSysOut;
}

} //# NAMESPACE CASA - END

