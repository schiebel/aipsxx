//# DOimage2.cc: defines DOimage class which implements functionality
//# for the image Distributed Object
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003,2004
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
//# $Id: DOimage2.cc,v 19.31 2005/12/06 20:18:50 wyoung Exp $

#include <appsglish/app_image/DOimage.h>

#include <casa/IO/AipsIO.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayUtil.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/MaskArrMath.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/AxesSpecifier.h>
#include <components/ComponentModels/ComponentList.h>
#include <components/ComponentModels/SkyComponent.h>
#include <components/ComponentModels/GaussianShape.h>
#include <components/ComponentModels/TwoSidedShape.h>
#include <components/ComponentModels/SkyCompRep.h>
#include <components/ComponentModels/Flux.h>
#include <casa/Containers/Record.h>
#include <coordinates/Coordinates.h>
#include <coordinates/Coordinates/GaussianConvert.h>
#include <fits/FITS/BasicFITS.h>
#include <lattices/LatticeMath/Fit2D.h>
#include <lattices/LatticeMath/LatticeFit.h>
#include <scimath/Fitting/LinearFitSVD.h>
#include <scimath/Functionals/Polynomial.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/Logging/LogIO.h>
#include <images/Images/ComponentImager.h>
#include <images/Images/LELImageCoord.h>
#include <images/Images/ImageFFT.h>
#include <images/Images/ImageMoments.h>
#include <images/Images/ImageExprParse.h>
#include <images/Images/ImageExpr.h>
#include <images/Images/ImageInfo.h>
#include <images/Images/ImageRegion.h>
#include <images/Images/PagedImage.h>
#include <images/Images/RegionHandler.h>
#include <images/Images/SubImage.h>
#include <images/Images/ImageConvolver.h>
#include <images/Images/SepImageConvolver.h>
#include <images/Images/Image2DConvolver.h>
#include <images/Images/ImageFit1D.h>
#include <images/Images/ImageSourceFinder.h>
#include <images/Images/ImageDecomposer.h>
#include <images/Images/TempImage.h>
#include <images/Images/ImageStatistics.h>
#include <images/Images/ImageUtilities.h>
#include <lattices/Lattices/ArrayLattice.h>
#include <lattices/Lattices/LatticeAddNoise.h>
#include <lattices/Lattices/MaskedLatticeIterator.h>
#include <lattices/Lattices/LatticeExpr.h>
#include <lattices/Lattices/LatticeExprNode.h>
#include <lattices/Lattices/LCRegion.h>
#include <lattices/Lattices/LCBox.h>
#include <lattices/Lattices/LCSlicer.h>
#include <lattices/Lattices/RegionType.h>
#include <lattices/Lattices/TiledLineStepper.h>
#include <lattices/Lattices/LatticeUtilities.h>
#include <casa/BasicMath/Math.h>
#include <casa/BasicSL/Constants.h>
#include <scimath/Mathematics/Convolver.h>
#include <casa/BasicMath/Random.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MFrequency.h>
#include <measures/Measures/Stokes.h>
#include <scimath/Mathematics/VectorKernel.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Quanta/QMath.h>
#include <casa/Quanta/MVAngle.h>
#include <casa/Quanta/Unit.h>
#include <components/SpectralComponents/SpectralElement.h>
#include <components/SpectralComponents/SpectralList.h>
#include <casa/System/PGPlotter.h>
#include <casa/System/ProgressMeter.h>
#include <tasking/Tasking/Index.h>
#include <tables/LogTables/NewFile.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <casa/OS/HostInfo.h>
#include <tasking/Tasking/ObjectController.h>
#include <images/Images/ImageFITSConverter.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/COWPtr.h>
#include <casa/Utilities/PtrHolder.h>
#include <casa/BasicSL/String.h>
#include <casa/Utilities/Regex.h>
#include <casa/Containers/Block.h>

#include <casa/sstream.h>
#include <casa/ostream.h>
#include <casa/stdio.h>



#include <casa/namespace.h>
image::image(const String& outfile, const String& expr, Bool overwrite,
             const GlishRecord& regions)
: pImage_p(0),
  pStatistics_p(0),
  pHistograms_p(0),
  pOldStatsRegionRegion_p(0),
  pOldStatsMaskRegion_p(0),
  pOldHistRegionRegion_p(0),
  pOldHistMaskRegion_p(0)
//
// Constructor "imagecalc"
//
{
   LogIO os(LogOrigin("image", "imagecalc", id(), WHERE));
   
// Check output file name
 
   if (!outfile.empty() && !overwrite) {
      NewFile validfile;
      String errmsg;
      if (!validfile.valueOK(outfile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
   }

// Get LatticeExprNode (tree) from parser.  Substitute possible object-id's
// by a sequence number, while creating a LatticeExprNode for it.
// Convert the GlishRecord containing regions to a PtrBlock<const ImageRegion*>.
  
   if (expr.empty()) {
      os << "You must specify an expression" << LogIO::EXCEPTION;
   }
   Block<LatticeExprNode> temps;
   String exprName;
   String newexpr = substituteOID (temps, exprName, expr);
   PtrBlock<const ImageRegion*> tempRegs;
   makeRegionBlock (tempRegs, regions, os);
   LatticeExprNode node = ImageExprParse::command (newexpr, temps, tempRegs);
  
// Get the shape of the expression
   
   const IPosition shapeOut = node.shape();
       
// Get the CoordinateSystem of the expression
 
   const LELAttribute attr = node.getAttribute();
   const LELLattCoordBase* lattCoord = &(attr.coordinates().coordinates());
   if (!lattCoord->hasCoordinates() || lattCoord->classname()!="LELImageCoord") {
      os << "Images in expression have no coordinates" << LogIO::EXCEPTION;
   }
   const LELImageCoord* imCoord = 
                          dynamic_cast<const LELImageCoord*>(lattCoord);
   AlwaysAssert (imCoord != 0, AipsError);
   CoordinateSystem cSysOut = imCoord->coordinates();

// Create LatticeExpr create mask if needed
 
   LatticeExpr<Float> latEx(node);

// Construct output image - an ImageExpr or a PagedImage

   if (outfile.empty()) {
      pImage_p = new ImageExpr<Float>(latEx, exprName);
      if (pImage_p==0) {
         os << "Failed to create ImageExpr" << LogIO::EXCEPTION;
      }
   } else {
      os << LogIO::NORMAL << "Creating image `" << outfile << "' of shape "
         << shapeOut <<LogIO::POST;
      pImage_p = new PagedImage<Float>(shapeOut, cSysOut, outfile);
      if (pImage_p==0) {
         os << "Failed to create PagedImage" << LogIO::EXCEPTION;
      }

// Make mask if needed, and copy data and mask

      if (latEx.isMasked()) {
         String maskName("");
         makeMask(*pImage_p, maskName, False, True, os, True);
      }
      LatticeUtilities::copyDataAndMask(os, *pImage_p, latEx);
   }

// Copy miscellaneous stuff over

    pImage_p->setMiscInfo(imCoord->miscInfo());
    pImage_p->setImageInfo(imCoord->imageInfo());
    pImage_p->setUnits(imCoord->unit());

// Logger not yet available

//    pImage_p->appendLog(imCoord->logger());


// Delete the ImageRegions (by using an empty GlishRecord).

   makeRegionBlock (tempRegs, GlishRecord(), os);
} 
 


image::image(const String &outfile, const String &fitsfile, 
             Index whichRep, Index whichhdu, Bool zeroBlanks, Bool overwrite,
             Bool oldParser)
: pImage_p(0),
  pStatistics_p(0),
  pHistograms_p(0),
  pOldStatsRegionRegion_p(0),
  pOldStatsMaskRegion_p(0),
  pOldHistRegionRegion_p(0),
  pOldHistMaskRegion_p(0)
//
// Constructor "imagefromfits"
//
{
    LogIO os(LogOrigin("image", "imagefromfits", id(), WHERE));

// Check output file

   if (!overwrite && !outfile.empty()) {
      NewFile validfile;
      String errmsg;
      if (!validfile.valueOK(outfile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
   }
//
   if (whichRep() < 0) {
      os << "The Coordinate Representation index must be non-negative" << LogIO::EXCEPTION;
   }
//
    ImageInterface<Float>* pOut = 0;
    String error;
    if (oldParser) {
       ImageFITSConverter::FITSToImageOld(pOut, error, outfile, fitsfile,
                                          whichhdu(),
                                          HostInfo::memoryFree()/1024, 
                                          overwrite, zeroBlanks);
    } else {
       ImageFITSConverter::FITSToImage(pOut, error, outfile, fitsfile,
                                       whichRep(), whichhdu(), 
                                       HostInfo::memoryFree()/1024, 
                                       overwrite, zeroBlanks);
    }				         
//
    if (pOut == 0) {
        os << error << LogIO::EXCEPTION;
    }
    pImage_p = pOut;
}


Bool image::calc(const String& expr, const GlishRecord& regions)
{
    if (detached()) {
        return False;
    }
//     
    LogOrigin OR("image", "calc", id(), WHERE);
    LogIO os(OR);
    
// Get LatticeExprNode (tree) from parser
// Convert the GlishRecord containing regions to a
// PtrBlock<const ImageRegion*>.
 
   if (expr.empty()) {    
      os << "You must specify an expression" << LogIO::EXCEPTION;
      return False;
   }
   Block<LatticeExprNode> temps;
   String exprName;
   String newexpr = substituteOID (temps, exprName, expr);
   PtrBlock<const ImageRegion*> tempRegs;
   makeRegionBlock (tempRegs, regions, os);
   LatticeExprNode node = ImageExprParse::command (newexpr, temps, tempRegs);
 
// Delete the ImageRegions (by using an empty GlishRecord)
   
   makeRegionBlock (tempRegs, GlishRecord(), os);
 
// Get the shape of the expression and check it matches that
// of the output image
      
   if (!node.isScalar()) {
      const IPosition shapeOut = node.shape();
      if (!pImage_p->shape().isEqual(shapeOut)) {
        os << LogIO::SEVERE << "The shape of the expression does not conform " << endl;
        os                  << "with the shape of the output image" << LogIO::POST;
        os << "Expression shape = " << shapeOut << endl;
        os << "Image shape      = " << pImage_p->shape() << LogIO::EXCEPTION;
      }
   }   
   
// Get the CoordinateSystem of the expression and check it matches
// that of the output image
 
   if (!node.isScalar()) {
     const LELAttribute attr = node.getAttribute();
     const LELLattCoordBase* lattCoord = &(attr.coordinates().coordinates());
     if (!lattCoord->hasCoordinates() || lattCoord->classname()!="LELImageCoord") {
       
// We assume here that the output coordinates are ok
   
       os << LogIO::WARN << "Images in expression have no coordinates" << LogIO::POST;
 
     } else {
        const LELImageCoord* imCoord = 
                            dynamic_cast<const LELImageCoord*>(lattCoord);
        AlwaysAssert (imCoord != 0, AipsError);   
        const CoordinateSystem& cSysOut = imCoord->coordinates();
        if (!pImage_p->coordinates().near(cSysOut)) {
 
// Since the output image has coordinates, and the shapes have conformed,
// just issue a warning 
  
          os << LogIO::WARN << "The coordinates of the expression do not conform " << endl;
          os                << "with the coordinates of the output image" << endl;
          os                << "Proceeding with output image coordinates" << LogIO::POST;
        }
     }
  }

 
// Make a LatticeExpr and see if it is masked
 
   Bool exprIsMasked = node.isMasked();
   if (exprIsMasked) {
      if (!pImage_p->isMasked()) {
    
// The image does not have a default mask set.  So try and make it one.
     
         String maskName("");
         makeMask(*pImage_p, maskName, True, True, os, True);
      }
   } 
 
// Evaluate the expression and fill the output image and mask

   if (node.isScalar()) {    
      LatticeExprNode node2 = toFloat(node);

// If the scalar value is masked, there is nothing
// to do.

      if (!exprIsMasked) {
         Float value = node2.getFloat();

         if (pImage_p->isMasked()) {

// We implement with a LEL expression of the form
// iif(mask(image)", value, image)

            LatticeExprNode node3 = iif(mask(*pImage_p), node2, *pImage_p);
            pImage_p->copyData(LatticeExpr<Float>(node3));
         } else {

// Just set all values to the scalar. There is no mask to worry about.

            pImage_p->set(value);
         }
      }
   } else {
      if (pImage_p->isMasked()) {

// We implement with a LEL expression of the form
// iif(mask(image)", expr, image)

         LatticeExprNode node3 = iif(mask(*pImage_p), node, *pImage_p);
         pImage_p->copyData(LatticeExpr<Float>(node3));
      } else {

// Just copy the pixels from the expression to the output.
// There is no mask to worry about.

         pImage_p->copyData(LatticeExpr<Float>(node));
      }
   }
    
                               
// Ensure that we reconstruct the statistics and histograms objects
// now that the data have changed
    
   deleteHistAndStats();
// 
   return True;
}


void image::makeComplex (const String& outFile, const GlishRecord& glishRegion,
                         const String& imagFile, Bool overwrite)
{
   if (detached()) return;
//     
   LogOrigin OR("image", "makeComplex", id(), WHERE);
   LogIO os(OR);

// Check output file

   if (!overwrite && !outFile.empty()) {
      NewFile validfile;
      String errmsg;
      if (!validfile.valueOK(outFile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
   }

// Open images and check consistency

   PagedImage<Float> imagImage(imagFile);
//
   const IPosition realShape = pImage_p->shape();
   const IPosition imagShape = imagImage.shape();
   if (!realShape.isEqual(imagShape)) {
      os << "Image shapes are not identical" << LogIO::EXCEPTION;
   }
//
   CoordinateSystem cSysReal = pImage_p->coordinates();
   CoordinateSystem cSysImag = imagImage.coordinates();
   if (!cSysReal.near(cSysImag)) {
      os << "Image Coordinate systems are not conformant" << LogIO::POST;
   }   
    
// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.
   
   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   String mask;
   SubImage<Float> subRealImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                                glishRegion, mask, True, os, False);
   delete pRegionRegion;
   delete pMaskRegion;
//
   SubImage<Float> subImagImage = makeSubImage (pRegionRegion, pMaskRegion, imagImage,
                                                glishRegion, mask, False, os, False);
   delete pRegionRegion;
   delete pMaskRegion;

// LEL node

   LatticeExprNode node(formComplex(subRealImage,subImagImage));
   LatticeExpr<Complex> expr(node);
//
   PagedImage<Complex> outImage(realShape, cSysReal, outFile); 
   outImage.copyData(expr);
   ImageUtilities::copyMiscellaneous(outImage, *pImage_p);
}


Quantum<Double> image::convertFlux (const Quantum<Double>& value,
                                    const Quantum<Double>& majorAxis,
                                    const Quantum<Double>& minorAxis,
                                    const String& type,
                                    Bool toPeak) const
{   
   Quantum<Double> valueOut;
   if (detached()) return valueOut;
   LogIO os(LogOrigin("image", "convertFlux", id(), WHERE));
//
   const Unit& brightnessUnit = pImage_p->units();
   const ImageInfo& info = pImage_p->imageInfo();
   const CoordinateSystem& cSys = pImage_p->coordinates();
//
   Vector<Quantum<Double> > beam = info.restoringBeam();
//
   if (majorAxis.getValue()>0.0 && minorAxis.getValue()>0.0) {
     Unit rad("rad");
     if (!(majorAxis.getFullUnit()==rad) || !(minorAxis.getFullUnit()==rad)) {
        os << "The major and minor axes must be angular" << LogIO::EXCEPTION;
     }
   } else {
     os << "The major and minor axes must both be positive" << LogIO::EXCEPTION;
   }
//
   Int afterCoord = -1;
   Int iC = cSys.findCoordinate(Coordinate::DIRECTION, afterCoord);
   if (iC<0) {
      os << "No DirectionCoordinate - cannot convert flux density" << LogIO::EXCEPTION;
   }
   const DirectionCoordinate& dirCoord = cSys.directionCoordinate(iC);
   ComponentType::Shape shape = ComponentType::shape(type);
//
   if (toPeak) {
      valueOut = SkyCompRep::integralToPeakFlux (dirCoord, shape, value,
                                                 brightnessUnit,
                                                 majorAxis, minorAxis, beam);
   } else {
      valueOut = SkyCompRep::peakToIntegralFlux (dirCoord, shape, value,
                                                 majorAxis,  minorAxis, beam);
   }
//
   return valueOut;
}
    
   



ObjectID image::convolve2D (const GlishRecord& glishRegion,
                            const String& mask,
                            const Vector<Index> &pixelAxes,
                            const String& kernel,
                            const Quantum<Double>& majorKernel,
                            const Quantum<Double>& minorKernel,
                            const Quantum<Double>& paKernel,
                            Bool autoScale, Double scale,
                            const String &outFile, Bool overwrite)
{
   if (detached()) { 
       return ObjectID(True);
   }
     
   LogOrigin OR("image", "convolve2D", id(), WHERE);
   LogIO os(OR);

// Check output file

   if (!overwrite && !outFile.empty()) {
      NewFile validfile;
      String errmsg;
      if (!validfile.valueOK(outFile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
   }

    
// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.
   
   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                            glishRegion, mask, True, os, False);
   delete pRegionRegion;
   delete pMaskRegion;

// Convert inputs

   Vector<Int> axes2;
   Index::convertVector(axes2, pixelAxes);
   if (axes2.nelements()!=2) {
      os << "You must give two axes to convolve" << LogIO::EXCEPTION;
   }
   IPosition axes3(axes2);
//
   VectorKernel::KernelTypes kernelType = VectorKernel::toKernelType(kernel);
//
   Vector<Quantum<Double> > parameters(3);
   parameters(0) = majorKernel;
   parameters(1) = minorKernel;
   parameters(2) = paKernel;

// Create output image and mask

   IPosition outShape = subImage.shape();
   PtrHolder<ImageInterface<Float> > imOut;
   if (outFile.empty()) {
      os << LogIO::NORMAL << "Creating (temp)image of shape " << outShape
         << LogIO::POST;
      imOut.set(new TempImage<Float>(outShape, subImage.coordinates()));
   } else {             
      os << LogIO::NORMAL << "Creating image '" << outFile << "' of shape " << outShape
         << LogIO::POST;
      imOut.set(new PagedImage<Float>(outShape, subImage.coordinates(), outFile));
   }
   ImageInterface<Float>* pImOut = imOut.ptr();

// Make the convolver 

   Image2DConvolver<Float> ic;
   ic.convolve(os, *pImOut, subImage, kernelType, axes3,
               parameters, autoScale, scale, True);

// Return handle     
 
   ObjectController *controller = ApplicationEnvironment::objectController();
   ApplicationObject *subobject = 0;
   if (controller) {
    
// We have a controller, so we can return a valid object id after we
// register the new object
 
       subobject = new image(*pImOut);
       AlwaysAssert(subobject, AipsError);
       return controller->addObject(subobject);
   } else {
       return ObjectID(True); // null
   }
}



ObjectID image::convolve (const Array<Float>& kernelArray,
                          const String& kernelFileName,
                          const GlishRecord& glishRegion,
                          const String& mask,
                          const String& outFile, Bool overwrite,
                          Bool autoScale, Double scale)
{
    if (detached()) {
        return ObjectID(True);
    }
    LogIO os(LogOrigin("image", "convolve", id(), WHERE));

// Check output file name
 
   if (!outFile.empty() && !overwrite) {
      NewFile validfile;
      String errmsg;
      if (!validfile.valueOK(outFile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
   }
   
// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.
   
    ImageRegion* pRegionRegion = 0;
    ImageRegion* pMaskRegion = 0;
    SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, mask, True, os, False);
    delete pRegionRegion;
    delete pMaskRegion;

// Create output image

   IPosition outShape = subImage.shape();
   PtrHolder<ImageInterface<Float> > imOut;
   if (outFile.empty()) {
      os << LogIO::NORMAL << "Creating (temp)image of shape " << outShape
         << LogIO::POST;
      imOut.set(new TempImage<Float>(outShape, subImage.coordinates()));
   } else {             
      os << LogIO::NORMAL << "Creating image '" << outFile << "' of shape " << outShape
         << LogIO::POST;
      imOut.set(new PagedImage<Float>(outShape, subImage.coordinates(), outFile));
   }
   ImageInterface<Float>* pImOut = imOut.ptr();
    
// Make the convolver 

    ImageConvolver<Float> aic;
    Bool copyMisc = True;
    Bool warnOnly = True;
    ImageConvolver<Float>::ScaleTypes scaleType(ImageConvolver<Float>::NONE);
    if (autoScale) {
       scaleType = ImageConvolver<Float>::AUTOSCALE;
    } else {
       scaleType = ImageConvolver<Float>::SCALE;
    }
    if (kernelFileName.empty()) {
       if (kernelArray.nelements() > 1) {
          aic.convolve(os, *pImOut, subImage, kernelArray, scaleType, scale, copyMisc);
       } else {
          os << "Kernel array dimensions are invalid" << LogIO::EXCEPTION;
       }
    } else {
       PagedImage<Float> kernelImage(kernelFileName);
       aic.convolve(os, *pImOut, subImage, kernelImage, scaleType, scale, copyMisc, warnOnly);
    }

// Return handle     
 
    ObjectController *controller = ApplicationEnvironment::objectController();
    ApplicationObject *subobject = 0;
    if (controller) {
    
// We have a controller, so we can return a valid object id after we
// register the new object
 
        subobject = new image(*pImOut);
        AlwaysAssert(subobject, AipsError);
        return controller->addObject(subobject);
    } else {
        return ObjectID(True); // null
    }
}


Vector<SkyComponent> image::deconvolveComponentList(const Vector<SkyComponent>& list) const
{
   LogIO os(LogOrigin("image", "deconvolveComponentList()", WHERE));

// Do we have a beam ?

   ImageInfo ii = pImage_p->imageInfo();
   Vector<Quantum<Double> > beam = ii.restoringBeam();
   if (beam.nelements()!=3) {
      os << "This image does not have a restoring beam" << LogIO::EXCEPTION;
   }
//         
   const CoordinateSystem cSys = pImage_p->coordinates();
   Int dirCoordinate = cSys.findCoordinate(Coordinate::DIRECTION);
   if (dirCoordinate==-1) {
      os << "This image does not contain a DirectionCoordinate - cannot deconvolve" << LogIO::EXCEPTION;
   }
   DirectionCoordinate dirCoord = cSys.directionCoordinate(dirCoordinate);
         
// Loop over components and deconvolve
  
   const uInt n = list.nelements();
   Vector<SkyComponent> listOut(n);
//
   for (uInt i=0; i<n; i++) {
      listOut(i) = deconvolveSkyComponent(os, list(i), beam, dirCoord);
   }
//
   return listOut;
}
    


GlishRecord image::decompose (const GlishRecord& glishRegion, 
   		              const String& mask, Bool simple,
                              Float threshold, Int nContour, Int minRange,
                              Int nAxis, Bool fit, Float maxrms, Int maxRetry,
                              Int maxIter, Float convCriteria)
{
   GlishRecord recOut;
   if (detached()) return recOut;
//
   LogIO os(LogOrigin("image", "decompose", id(), WHERE));

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.  Drop degenerate axes.

   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   AxesSpecifier axesSpec(False);
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                            glishRegion, mask, True, os, False,
					    axesSpec);
   delete pRegionRegion;
   delete pMaskRegion;

// Make finder

   ImageDecomposer <Float> decomposer(subImage);

// Set auto-threshold at 5-sigma

   if (threshold <= 0.0) {
     LatticeStatistics<Float> stats(subImage);
     Array<Float> out;
     //Bool ok = stats.getSigma (out, True); //what did this do?
     threshold = 5.0 * out(IPosition(subImage.ndim(),0));
   }

// Do it

   decomposer.setDeblend(!simple);
   decomposer.setDeblendOptions(threshold, nContour, minRange, nAxis);
   decomposer.setFit(fit);
   decomposer.setFitOptions(maxrms, maxRetry, maxIter, convCriteria);

   decomposer.decomposeImage();
   decomposer.printComponents();

// As yet no methods to put the results into an output container
// (Note: component list can be output as a Matrix.)

   return recOut;
}
  

Vector<SkyComponent> image::findSources (Int nMax, Double cutoff, Bool absFind,
                                         const GlishRecord& glishRegion, 
					 const String& mask, Bool point,
                                         Int width)
{
   Vector<SkyComponent> listOut;
   if (detached()) return listOut;
//
   LogIO os(LogOrigin("image", "findsources", id(), WHERE));

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.  Drop degenerate axes.

    ImageRegion* pRegionRegion = 0;
    ImageRegion* pMaskRegion = 0;
    AxesSpecifier axesSpec(False);
    SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, mask, True, os, False, 
					     axesSpec);
    delete pRegionRegion;
    delete pMaskRegion;

// Make finder

   ImageSourceFinder<Float> sf(subImage);

// Find them

   ComponentList list = sf.findSources(os, nMax, cutoff, absFind, point, width);
   uInt nC = list.nelements();
   listOut.resize(nC);
   for (uInt i=0; i<nC; i++) listOut(i) = list.component(i);
   return listOut;
}
  

       


void image::fft(const String& realOut, const String& imagOut,
                const String& ampOut, const String& phaseOut,
                const Vector<Index>& axes, const GlishRecord& glishRegion,
                const String& mask)
{
   if (detached()) return;
   LogIO os(LogOrigin("image", "fft", id(), WHERE));

// Validate outfiles

    if (realOut.empty() && imagOut.empty() &&
        ampOut.empty() && phaseOut.empty()) {
       os << LogIO::WARN  << "You did not request any output images" << LogIO::POST;
       return;
    }
//
    String errmsg;
    if (!realOut.empty()) {
       NewFile validFileReal;
       if (!validFileReal.valueOK(realOut, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
       }
    }
//
    if (!imagOut.empty()) {
       NewFile validFileImag;
       if (!validFileImag.valueOK(imagOut, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
       }
    }
//
    if (!ampOut.empty()) {
       NewFile validFileAmp;
       if (!validFileAmp.valueOK(ampOut, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
    }
//
    if (!phaseOut.empty()) {
       NewFile validFilePhase;
       if (!validFilePhase.valueOK(phaseOut, errmsg)) {
         os << errmsg << LogIO::EXCEPTION;
       }
    }

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.
   
    ImageRegion* pRegionRegion = 0;
    ImageRegion* pMaskRegion = 0;
    SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, mask, True, os, False);
    delete pRegionRegion;
    delete pMaskRegion;

// Do the FFT

    ImageFFT fft;
    if (axes.nelements()==0) {
       os << LogIO::NORMAL << "FFT the sky" << LogIO::POST;
       fft.fftsky(subImage);
    } else {

// Set vector of bools specifying axes

       Vector<Int> intAxes(axes.nelements());
       Index::convertVector(intAxes, axes);
       Vector<Bool> which(subImage.ndim(),False);
       for (uInt i=0; i<intAxes.nelements(); i++) which(intAxes(i)) = True;
//
       os << LogIO::NORMAL << "FFT axes " << intAxes+1 << LogIO::POST;
       fft.fft(subImage, which);
    }        


// Write output files

    String maskName("");
    if (!realOut.empty()) {
       os << LogIO::NORMAL << "Creating image '" << realOut << "'" << LogIO::POST;
       PagedImage<Float> realOutIm(subImage.shape(), subImage.coordinates(), realOut);
       if (subImage.isMasked()) makeMask(realOutIm, maskName, False, True, os, True);
       fft.getReal(realOutIm);
    }
    if (!imagOut.empty()) {
       os << LogIO::NORMAL << "Creating image '" << imagOut << "'" << LogIO::POST;
       PagedImage<Float> imagOutIm(subImage.shape(), subImage.coordinates(), imagOut);
       if (subImage.isMasked()) makeMask(imagOutIm, maskName, False, True, os, True);
       fft.getImaginary(imagOutIm);
    }
    if (!ampOut.empty()) {
       os << LogIO::NORMAL << "Creating image '" << ampOut << "'" << LogIO::POST;
       PagedImage<Float> ampOutIm(subImage.shape(), subImage.coordinates(), ampOut);
       if (subImage.isMasked()) makeMask(ampOutIm, maskName, False, True, os, True);
       fft.getAmplitude(ampOutIm);
    }
    if (!phaseOut.empty()) {
       os << LogIO::NORMAL << "Creating image '" << phaseOut << "'" << LogIO::POST;
       PagedImage<Float> phaseOutIm(subImage.shape(), subImage.coordinates(), phaseOut);
       if (subImage.isMasked()) makeMask(phaseOutIm, maskName, False, True, os, True);
       fft.getPhase(phaseOutIm);
    }
}

Vector<SkyComponent> image::fitsky(Array<Float>& residPixels,
                                   Array<Bool>& residMask,
                                   Bool& converged,
                                   const GlishRecord& glishRegion,
                                   const String& mask,
                                   const Vector<String>& models,
                                   const Vector<SkyComponent>& estimate,
                                   const Vector<String>& fixed,
                                   const Vector<Float>& includepix,
                                   const Vector<Float>& excludepix,
                                   Bool fitIt, Bool deconvolveIt, Bool list)
{
   Vector<SkyComponent> emptyVectorComp(0);
   if (detached()) {
       return emptyVectorComp;
   }
   LogOrigin OR("image", "fitsky", id(), WHERE);
   LogIO os(OR);
   converged = False;
// 
   const uInt nModels = models.nelements();
   const uInt nMasks = fixed.nelements();
   const uInt nEstimates = estimate.nelements();
// 
   if (nModels==0) {
      os << "You have not specified any models" << LogIO::EXCEPTION;
   }     
   if (nModels>1) {
      if (estimate.nelements() < nModels) {
         os << "You must specify one estimate for each model component" << LogIO::EXCEPTION;
      }
   }
   if (!fitIt && nModels>1) {
      os << "Parameter estimates are only available for a single model" << LogIO::EXCEPTION;
   }
//
   for (uInt i=0; i<nModels; i++) {
/*
      Fit2D::Types model = Fit2D::type(models(i));
      if (model != Fit2D::GAUSSIAN) {
         os << "Only Gaussian models are currently available" << LogIO::EXCEPTION;
      }
*/
   }
//
   Bool doInclude = (includepix.nelements()>0);
   Bool doExclude = (excludepix.nelements()>0);
   if (doInclude && doExclude) {
     os << "You cannot give both an include and an exclude pixel range" 
        << LogIO::EXCEPTION;
   }

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.  Drop degenerate axes.
   
   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   AxesSpecifier axesSpec(False);
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                            glishRegion, mask, list, os, False, axesSpec);
   delete pRegionRegion;
   delete pMaskRegion;

// Make sure the region is 2D and that it holds the sky.  Exception if not.

   const CoordinateSystem& cSys = subImage.coordinates();
   Bool xIsLong = CoordinateUtil::isSky(os, cSys);

// Get 2D pixels and mask 

   Array<Float> pixels = subImage.get(True);
   IPosition shape = pixels.shape();
   residMask.resize(IPosition(0));
   residMask = subImage.getMask(True).copy();

// What Stokes type does this plane hold ?

   Stokes::StokesTypes stokes(Stokes::Undefined);
   stokes = CoordinateUtil::findSingleStokes (os, cSys, 0);
  
// Form masked array and find min/max

   MaskedArray<Float> maskedPixels(pixels, residMask,True);
   Float minVal, maxVal;
   IPosition minPos(2), maxPos(2);
   minMax(minVal, maxVal, minPos, maxPos, pixels);

// Create fitter
   
   Fit2D fitter(os);   

// Set pixel range depending on Stokes type and min/max

   if (!doInclude && !doExclude) {
      if (stokes==Stokes::I) {
        if (abs(maxVal)>=abs(minVal)) {
           fitter.setIncludeRange(0.0, maxVal+0.001);
           os << LogIO::NORMAL << "Selecting pixels > 0.0" << LogIO::POST;
        } else {
           fitter.setIncludeRange(minVal-0.001, 0.0);
           os << LogIO::NORMAL << "Selecting pixels < 0.0" << LogIO::POST;
        }
      } else {
         os << LogIO::NORMAL << "Selecting all pixels" << LogIO::POST;
      }
   } else {
      if (doInclude) {
         if (includepix.nelements()==1) {
            fitter.setIncludeRange(-abs(includepix(0)), abs(includepix(0)));
            os << LogIO::NORMAL << "Selecting pixels from " << -abs(includepix(0)) << " to " 
               << abs(includepix(0))  << LogIO::POST;
         } else if (includepix.nelements()>1) {
            fitter.setIncludeRange(includepix(0), includepix(1));
            os << LogIO::NORMAL << "Selecting pixels from " << includepix(0) << " to " 
               << includepix(1) << LogIO::POST;
         }
      } else {
         if (excludepix.nelements()==1) {
            fitter.setExcludeRange(-abs(excludepix(0)), abs(excludepix(0)));
            os << LogIO::NORMAL << "Excluding pixels from " << -abs(excludepix(0)) << " to " 
               << abs(excludepix(0))  << LogIO::POST;
         } else if (excludepix.nelements()>1) {
            fitter.setExcludeRange(excludepix(0), excludepix(1));
            os << LogIO::NORMAL << "Excluding pixels from " << excludepix(0) << " to " 
               << excludepix(1) << LogIO::POST;
         }
      }
   }


// Recover just single component estimate if desired and bug out
// Must use subImage in calls as converting positions to absolute pixel
// and vice versa

   if (!fitIt) {
      Vector<Double> parameters;
      parameters = singleParameterEstimate(fitter, Fit2D::GAUSSIAN, maskedPixels, 
                                           minVal, maxVal, minPos, maxPos, 
                                           stokes, subImage, xIsLong, os);

// Encode as SkyComponent and return

      Vector<SkyComponent> result(1);
      Double facToJy;
      result(0) = encodeSkyComponent (os, facToJy, subImage, convertModelType(Fit2D::GAUSSIAN), 
                                      parameters, stokes, xIsLong, deconvolveIt);
      return result;
   }

// For ease of use, make each model have a mask string

   Vector<String> fixedParameters(fixed.copy());
   fixedParameters.resize(nModels, True);
   for (uInt j=0; j<nModels; j++) {
      if (j>=nMasks) {
         fixedParameters(j) = String("");
      }
   }

// Add models


   Vector<String> modelTypes(models.copy());
   for (uInt i=0; i<nModels; i++) {

// If we ask to fit a POINT component, that really means a Gaussian of
// shape the restoring beam.  So fix the shape parameters and make it Gaussian

      Fit2D::Types modelType;
      if (ComponentType::shape(models(i))==ComponentType::POINT) {
         modelTypes(i) = String("GAUSSIAN");
         fixedParameters(i) += String("abp");
      }
      modelType = Fit2D::type(modelTypes(i));
//
      Vector<Bool> parameterMask = Fit2D::convertMask(fixedParameters(i), modelType);
//
      Vector<Double> parameters;
      if (nModels==1 && nEstimates==0) {

// Auto estimate

         parameters = singleParameterEstimate(fitter, modelType, maskedPixels, 
                                              minVal, maxVal, minPos, maxPos, 
                                              stokes, subImage, xIsLong, os);
      } else {

// Decode parameters from estimate


         const CoordinateSystem& cSys = subImage.coordinates();
         const ImageInfo& imageInfo = subImage.imageInfo();
         parameters = ImageUtilities::decodeSkyComponent (estimate(i), imageInfo,
                                                          cSys, subImage.units(), 
                                                          stokes, xIsLong);

// The estimate SkyComponent may not be the same type as the
// model type we are fitting for.  Try and do something about
// this if need be by adding or removing component shape parameters

         ComponentType::Shape estType = estimate(i).shape().type();
         if (modelType==Fit2D::GAUSSIAN || modelType==Fit2D::DISK) {
            if (estType==ComponentType::POINT) {

// We need the restoring beam shape as well.  

               Vector<Quantum<Double> > beam = imageInfo.restoringBeam();               
               Vector<Quantum<Double> > wParameters(5);
//
               wParameters(0).setValue(0.0);             // Because we convert at the reference
               wParameters(1).setValue(0.0);             // value for the beam, the position is
               wParameters(0).setUnit(String("rad"));    // irrelevant
               wParameters(1).setUnit(String("rad"));
               wParameters(2) = beam(0);
               wParameters(3) = beam(1);
               wParameters(4) = beam(2);

// Convert to pixels for Fit2D

               IPosition pixelAxes(2);
               pixelAxes(0) = 0; 
               pixelAxes(1) = 1; 
               if (!xIsLong) {
                  pixelAxes(1) = 0; 
                  pixelAxes(0) = 1; 
               }
               Bool doRef = True;
               Vector<Double> dParameters;
               ImageUtilities::worldWidthsToPixel(os, dParameters, wParameters, cSys, 
                                                  pixelAxes, doRef);
//
               parameters.resize(6, True);
               parameters(3) = dParameters(0);
               parameters(4) = dParameters(1);
               parameters(5) = dParameters(2);
            }
         } else if (modelType==Fit2D::LEVEL) {
            os << LogIO::EXCEPTION;            // Levels not supported yet
         }
      }
      fitter.addModel (modelType, parameters, parameterMask);
   }
            
// Do fit 

   Array<Float> sigma;
   Fit2D::ErrorTypes status = fitter.fit(pixels, residMask, sigma);
   if (status==Fit2D::OK) {
      os << LogIO::NORMAL << "Number of iterations = " << fitter.numberIterations() << endl;
      converged = True;
   } else {
      converged = False;
      os << LogIO::WARN << fitter.errorMessage() << LogIO::POST;
      return emptyVectorComp;
   }
         
// Compute residuals

   fitter.residual(residPixels, pixels);

// Convert units of solution from pixel units to astronomical units

   Vector<SkyComponent> result(nModels);
   Double facToJy;
   for (uInt i=0; i<models.nelements(); i++) {   
      ComponentType::Shape modelType = convertModelType(Fit2D::type(modelTypes(i)));
      Vector<Double> solution = fitter.availableSolution(i);
      Vector<Double> errors = fitter.availableErrors(i);
//
      result(i) = encodeSkyComponent (os, facToJy, subImage, modelType,  solution,
                                      stokes, xIsLong, deconvolveIt);
      encodeSkyComponentError (os, result(i), facToJy, subImage, solution, 
                               errors, stokes, xIsLong);
   }
//
   return result;
}


void image::fitAllProfiles (const GlishRecord& glishRegion,
                            const String& mask,
                            Int nGauss, Int baseline, Index axis,
                            const String& sigmaFileName,
                            const String& fitFileName,
                            const String& residFileName)

{
   LogIO os(LogOrigin("image", "fitAllProfiles", id(), WHERE));
   if (!(nGauss>0 || baseline>=0)) {
     os << "You must specify a number of gaussians and/or a polynomial order to fit" << LogIO::EXCEPTION;
   }
//  
   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                            glishRegion, mask, False, os, True);
   delete pRegionRegion;
   delete pMaskRegion;
   IPosition imageShape = subImage.shape();
//
   PtrHolder<ImageInterface<Float> > weightsImage;
   ImageInterface<Float>* pWeights = 0;
   if (!sigmaFileName.empty()) {
      PagedImage<Float> sigmaImage(sigmaFileName);
      if (!sigmaImage.shape().conform(pImage_p->shape())) {
         os << "image and sigma images must have same shape" << LogIO::EXCEPTION;
      }
//      
      ImageRegion* pR = makeRegionRegion(sigmaImage, glishRegion, True, os);
      weightsImage.set(new SubImage<Float>(sigmaImage, *pR, False));
      pWeights = weightsImage.ptr();
      delete pR;
   }

// Set default axis

   CoordinateSystem cSys = subImage.coordinates();
   Int pAxis = CoordinateUtil::findSpectralAxis(cSys);
   Int axis2 = axis();
   if (axis2<0) {
      if (pAxis != -1) {
         axis2 = pAxis;
      } else {
         axis2 = subImage.ndim() - 1;
      }
   }

// Create output images with a mask

   PtrHolder<ImageInterface<Float> > fitImage, residImage;
   ImageInterface<Float>* pFit = 0;
   ImageInterface<Float>* pResid = 0;
   if (makeExternalImage (fitImage, fitFileName, cSys, imageShape,  
                          subImage, os, True, False, True)) pFit = fitImage.ptr();
   if (makeExternalImage (residImage, residFileName, cSys, imageShape,  
                          subImage, os, True, False, True)) pResid = residImage.ptr();

// Do fits

   Bool showProgress(True);
   uInt axis3(axis2);
   uInt nGauss2 = max(0,nGauss);
   ImageUtilities::fitProfiles (pFit, pResid, subImage, pWeights,
                                axis3, nGauss2, baseline, showProgress);
}                                   



GlishRecord image::fitProfile (Vector<Float>& values,
                               Vector<Float>& residual,
                               const GlishRecord& glishRegion,
                               const String& mask, const GlishRecord& estimate,
                               Int nMax, Int baseline, Index axis, Bool fitIt,
                               const String& sigmaFileName)

{
   LogIO os(LogOrigin("image", "fitProfile", id(), WHERE));
//  
   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                            glishRegion, mask, False, os, False);
   delete pRegionRegion;
   delete pMaskRegion;
   IPosition imageShape = subImage.shape();
//
   PtrHolder<ImageInterface<Float> > weightsImage;
   ImageInterface<Float>* pWeights = 0;
   if (!sigmaFileName.empty()) {
      PagedImage<Float> sigmaImage(sigmaFileName);
      if (!sigmaImage.shape().conform(pImage_p->shape())) {
         os << "image and sigma images must have same shape" << LogIO::EXCEPTION;
      }
//      
      ImageRegion* pR = makeRegionRegion(sigmaImage, glishRegion, True, os);
      weightsImage.set(new SubImage<Float>(sigmaImage, *pR, False));
      pWeights = weightsImage.ptr();
      delete pR;
   }

// Set default axis

   const uInt nDim = subImage.ndim();
   CoordinateSystem cSys = subImage.coordinates();
   Int pAxis = CoordinateUtil::findSpectralAxis(cSys);
   Int axis2 = axis();
   if (axis2<0) {
      if (pAxis != -1) {
         axis2 = pAxis;
      } else {
         axis2 = nDim - 1;
      }
   }

// Convert estimate from GlishRecord to Record

   Record recIn;
   estimate.toRecord(recIn);

// Fish out request units from input estimate record
// Fields  are
//  xunit
//  doppler
//  xabs
//  yunit
//  elements
//   i
//     parameters        
//     errors
//     fixed             
// 
// SpectralElement fromRecord handles each numbered elements 
// field (type, parameters, errors). It does not yet handle
// the 'fixed' field (see below)

   String xUnit, yUnit, doppler;
   if (recIn.isDefined("xunit")) {
      xUnit = recIn.asString("xunit");
   }
   if (recIn.isDefined("doppler")) {
      doppler = recIn.asString("doppler");
   }
//
   Bool xAbs = True;
   if (recIn.isDefined("xabs")) {
      xAbs = recIn.asBool("xabs");
   }
   if (recIn.isDefined("yunit")) {             // Not used presently.Drop ?
      yUnit = recIn.asString("yunit");
   }

// Figure out the abcissa type specifying what abcissa domain the fitter
// is operating in.  Convert the CoordinateSystem to this domain
// and set it back in the image

   String errMsg;
   uInt axis3(axis2);
   ImageFit1D<Float>::AbcissaType abcissaType = ImageFit1D<Float>::PIXEL;
   Bool ok = ImageFit1D<Float>::setAbcissaState (errMsg, abcissaType, cSys, 
                                                 xUnit, doppler, axis3);
   subImage.setCoordinateInfo  (cSys);
/*
cerr << "xUnit, doAbs, doppler, axis = " << xUnit << ", " << xAbs << ", " << doppler << ", " << axis3 << endl;
cerr << "abcissa type = " << abcissaType << endl;
cerr << "nMax = " << nMax << endl;
*/

// Make fitter

   ImageFit1D<Float> fitter;
   if (pWeights) {
      fitter.setImage (subImage, *pWeights, axis3);
   } else {
      fitter.setImage (subImage, axis3);
   }

// Set data region averaging data in region.  We could also set the
// ImageRegion from that passed in to this function rather than making
// a SubImage. But the way I have done it, the 'mask' keyword is 
// handled automatically there.

   Slicer sl(IPosition(nDim,0), imageShape, Slicer::endIsLength);
   LCSlicer sl2(sl);
   ImageRegion region(sl2);
   if (!fitter.setData (region, abcissaType, xAbs)) {
      os << fitter.errorMessage() << LogIO::EXCEPTION;
   }

// If we have the "elements" field, decode it into a list

   SpectralList list;
   if (recIn.isDefined("elements")) {
      if (!list.fromRecord(errMsg, recIn.asRecord(String("elements")))) {
         os << errMsg << LogIO::EXCEPTION;
      }

// Handle the 'fixed' record here. This is a work around until we
// redo this stuff properly in SpectralList and friends.

      Record tmpRec = recIn.asRecord("elements");
      const uInt nRec = tmpRec.nfields();
      AlwaysAssert(nRec==list.nelements(),AipsError);
//
      for (uInt i=0; i<nRec; i++) {           // Loop over elements
         Record tmpRec2 = tmpRec.asRecord(i);
         Vector<Bool> fixed;
         if (tmpRec2.isDefined("fixed")) {
            fixed = tmpRec2.asArrayBool("fixed");
            SpectralElement& el = list[i];
            el.fix(fixed);
         }
      }
   }

// Now we do one of three things:
// 1) make a fit and evaluate
// 2) evaluate a model
// 3) make an estimate and evaluate

   values.resize(0);
   residual.resize(0);
   Bool addExtras = False;
   Record recOut;

   if (fitIt) {
      if (list.nelements()>0) {

// Strip off any polynomial

         SpectralList list2;
         for (uInt i=0; i<list.nelements(); i++) {
            if (list[i].getType()==SpectralElement::GAUSSIAN) {
               list2.add(list[i]);
            }
         }
//        
         fitter.setElements(list2);              // Set estimate
      } else {
         fitter.setGaussianElements(nMax);       // Set auto estimate
      }
      if (baseline >=0) {
         SpectralElement polyEl(baseline);       // Add baseline
         fitter.addElement(polyEl);
      }
//
      if (!fitter.fit()) {                       // Fit
         os << LogIO::WARN << "Fit failed to converge" << LogIO::POST;
      }
//  
      values = fitter.getFit();                  // Evaluate
      residual = fitter.getResidual(-1, True);
//
      const SpectralList& fitList = fitter.getList(True);  // Convert to GlishRecord
      fitList.toRecord(recOut);
      addExtras = True;
   } else {
      if (list.nelements()>0) {
         fitter.setElements(list);                   // Set list
         values = fitter.getEstimate();              // Evaluate list
         residual = fitter.getResidual(-1, False);
      } else {
         if (fitter.setGaussianElements(nMax)) {     // Auto estimate
            values = fitter.getEstimate();           // Evaluate
            residual = fitter.getResidual(-1, False); 
            const SpectralList& list = fitter.getList(False);
//
            list.toRecord(recOut); 
            addExtras = True;
         } else {
            os << LogIO::SEVERE << fitter.errorMessage() << LogIO::POST;
         }
      }
   }
//
   Record recOut2;
   recOut2.defineRecord ("elements", recOut);
   if (addExtras) {
      recOut2.define("xunit", xUnit);
      recOut2.define("doppler", doppler);
      recOut2.define("xabs", xAbs);
      recOut2.define("yunit", yUnit);
   }

// Convert to GlishRecord

   GlishRecord gRec;
   gRec.fromRecord(recOut2);
   return gRec;
}




ObjectID image::fitPolynomial (Index axis, const GlishRecord& glishRegion,
                           const String& mask, Int baseline, 
                           const String& sigmaFile,
                           const String& fitFile,
                           const String& residFile, Bool overwrite)
{
    if (detached()) {
        return ObjectID(True);
    }
//
   LogIO os(LogOrigin("image", "fitPolynomial", id(), WHERE));

// Verify output file
     
   if (!overwrite && !residFile.empty()) {
      NewFile validfile;
      String errmsg;
      if (!validfile.valueOK(residFile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
   }

// Make SubImages from input image

   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                            glishRegion, mask, False, os, False);
   delete pMaskRegion;
   IPosition imageShape = subImage.shape();

// Make subimage from input error image

   SubImage<Float>* pSubSigmaImage = 0;
   if (!sigmaFile.empty()) {
      PagedImage<Float> sigmaImage(sigmaFile);
      if (!sigmaImage.shape().conform(pImage_p->shape())) {
         os << "image and sigma images must have same shape" << LogIO::EXCEPTION;
      }
//      
      if (glishRegion.nelements()>0) {
         ImageRegion* pR = makeRegionRegion(sigmaImage, glishRegion, True, os);
         pSubSigmaImage = new SubImage<Float>(sigmaImage, *pR, False);
         delete pR;
      } else {
         pSubSigmaImage = new SubImage<Float>(sigmaImage, False);
      }
   }

// Find spectral axis if not given.

   CoordinateSystem cSys = subImage.coordinates();
   Int pAxis = CoordinateUtil::findSpectralAxis(cSys);
//
   Int axis2;
   if (axis()<0) {
      if (pAxis != -1) {
         axis2 = pAxis;
      } else {
         axis2 = subImage.ndim() - 1;
      }
   } else {
      axis2 = axis();
   }

// Create output residual image (returned as an Image tool)
// Create with no mask

   PtrHolder<ImageInterface<Float> > residImage;
   ImageInterface<Float>* pResid = 0;
   if (makeExternalImage (residImage, residFile, cSys, imageShape,  
                          subImage, os, True, True, False)) pResid = residImage.ptr();

// Create optional disk image holding fit
// Create with no mask

   PtrHolder<ImageInterface<Float> > fitImage;
   ImageInterface<Float>* pFit = 0;
   if (makeExternalImage (fitImage, fitFile, cSys, imageShape,  
                          subImage, os, True, False, False)) pFit = fitImage.ptr();

// Make fitter

    Polynomial<AutoDiff<Float> > poly(baseline);
    LinearFitSVD<Float> fitter;
    fitter.setFunction(poly);

// Fit

   LatticeFit::fitProfiles (pFit, pResid, subImage, pSubSigmaImage, 
                            fitter, axis2, True);
   if (pSubSigmaImage) delete pSubSigmaImage;

// Copy mask from input image so that we exclude the OTF mask
// in the output.  The OTF mask is just used to select what we fit
// but should not be copied to the output

   SubImage<Float>* pSubImage2 = 0;
   if (pRegionRegion) {
      pSubImage2 = new SubImage<Float>(*pImage_p, *pRegionRegion, True);
   } else {
      pSubImage2 = new SubImage<Float>(*pImage_p, True);
   }
   delete pRegionRegion;
//
   if (pSubImage2->isMasked()) {
      Lattice<Bool>& pixelMaskIn = pSubImage2->pixelMask();
      String maskNameResid;
      makeMask(*pResid, maskNameResid, False, True, os, True);
      {
         Lattice<Bool>& pixelMaskOut = pResid->pixelMask();
         pixelMaskOut.copyData (pixelMaskIn);
      }
//
      if (pFit) {
        String maskNameFit;
        makeMask(*pFit, maskNameFit, False, True, os, True);
        {
           Lattice<Bool>& pixelMaskOut = pFit->pixelMask();
           pixelMaskOut.copyData (pixelMaskIn);
        }
      }
   }
   delete pSubImage2;

// Return Tool ID for residual image

   ObjectController *controller = ApplicationEnvironment::objectController();
   ApplicationObject *subobject = 0;
   if (controller) {
      subobject = new image(*pResid);
      AlwaysAssert(subobject, AipsError);
      return controller->addObject(subobject);
   } else {
      return ObjectID(True); 
   }
}



ObjectID image::hanning(const GlishRecord& glishRegion, const String& mask,
                        Index axis, const String& outFile, Bool drop, Bool overwrite)
{
    if (detached()) {
        return ObjectID(True);
    }
    LogIO os(LogOrigin("image", "hanning", id(), WHERE));
    
// Validate outfile
       
    if (!overwrite && !outFile.empty()) { 
       NewFile validfile;
       String errmsg;
       if (!validfile.valueOK(outFile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
       }
    }
       
// Deal with axis
    
    Int iAxis = axis();
    if (iAxis < 0) {
       iAxis = CoordinateUtil::findSpectralAxis(pImage_p->coordinates());
       if (iAxis < 0) {
          os << "Could not find a spectral axis in input image" << LogIO::EXCEPTION;
       }
    } else {
       if (iAxis > Int(pImage_p->ndim())-1) {
          os << "Specified axis of " << iAxis+1
               << "is greater than input image dimension of "
               << pImage_p->ndim() << LogIO::EXCEPTION;
       }
    }

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.

    ImageRegion* pRegionRegion = 0;
    ImageRegion* pMaskRegion = 0;
    SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, mask, True, os, False);
//
    IPosition blc(subImage.ndim(),0);
    if (pRegionRegion) {
       LatticeRegion latRegion =
            pRegionRegion->toLatticeRegion (pImage_p->coordinates(), pImage_p->shape());
       blc = latRegion.slicer().start();
    }
//
    delete pRegionRegion;
    delete pMaskRegion;

// Work out shape of output image
       
    IPosition inShape(subImage.shape());
    IPosition outShape(inShape);
    if (drop) {
       outShape(iAxis) = inShape(iAxis)/2;
       if (inShape(iAxis)%2 == 0) outShape(iAxis) = outShape(iAxis) - 1;
    }
    os << LogIO::NORMAL << "Output image shape = " << outShape << LogIO::POST;
     

// Create output image coordinates.  Account for region selection and if
// we drop every other point, the first output point is centred on
// the second input pixel.
    
    Vector<Float> cInc(pImage_p->ndim(),1.0);
    Vector<Float> cBlc(blc.nelements());
    for (uInt i=0; i<cBlc.nelements(); i++) cBlc(i) = Float(blc(i));
    if (drop) {
       cInc(iAxis) = 2.0;
       cBlc(iAxis) += 1.0;
    }
    CoordinateSystem cSys = pImage_p->coordinates().subImage(cBlc, cInc, outShape.asVector());
          
// Make output image and mask if needed

    PtrHolder<ImageInterface<Float> > imOut;
    Bool isMasked = False;  
    if (outFile.empty()) {
       os << LogIO::NORMAL << "Creating (temp)image '" << outFile << "' of shape "
          << outShape << LogIO::POST;   
       imOut.set(new TempImage<Float>(outShape, cSys));
    } else {    
       os << LogIO::NORMAL << "Creating image '" << outFile << "' of shape "
          << outShape << LogIO::POST;   
       imOut.set(new PagedImage<Float>(outShape, cSys, outFile));
    }
    ImageInterface<Float>* pImOut = imOut.ptr();
    if (subImage.isMasked()) {
       String maskName("");
       isMasked = makeMask(*pImOut, maskName, False, True, os, True);
   }
    
// Create input image iterator
 
    IPosition inTileShape = subImage.niceCursorShape();
    TiledLineStepper inNav(subImage.shape(), inTileShape, iAxis);
    RO_MaskedLatticeIterator<Float> inIter(subImage, inNav);
       
// Iterate by profile and smooth
       
    Int nProfiles = subImage.shape().product()/inIter.vectorCursor().nelements();
    ProgressMeter clock(0.0, Double(nProfiles), "Hanning smooth", "Profiles smoothed",
                        "", "", True, max(1,Int(nProfiles/20)));
    Double meterValue = 0.0;
//
    IPosition outSliceShape(pImOut->ndim(),1);
    outSliceShape(iAxis) = pImOut->shape()(iAxis);
    Array<Float> slice(outSliceShape);
//
    IPosition inSliceShape(subImage.ndim(),1);
    inSliceShape(iAxis) = subImage.shape()(iAxis);
    Array<Bool> maskIn(inSliceShape);
    Array<Bool> maskOut(outSliceShape);
    Lattice<Bool>* pMaskOut = 0;
    if (isMasked) {
       pMaskOut = &pImOut->pixelMask();   
       if (!pMaskOut->isWritable()) {
          os << LogIO::WARN << "The output image has a mask but it is not writable" << endl;
          os << LogIO::WARN << "So the mask will not be transferred to the output" << LogIO::POST;
          isMasked = False;
       }
    }
//
    while (!inIter.atEnd()) {
       if (isMasked) {
          inIter.getMask(maskIn, False);
          hanning_smooth(slice, maskOut, inIter.vectorCursor(), maskIn, True);
          pMaskOut->putSlice(maskOut, inIter.position());
       } else {
          hanning_smooth(slice, maskOut, inIter.vectorCursor(), maskIn, False);
       }
       pImOut->putSlice(slice, inIter.position());
//
       inIter++;
       meterValue += 1.0;
       clock.update(meterValue);
    }
    ImageUtilities::copyMiscellaneous(*pImOut, *pImage_p);
 
// Return handle to new file
    
    ObjectController *controller = ApplicationEnvironment::objectController();
    ApplicationObject *subobject = 0;
    if (controller) {
         
// We have a controller, so we can return a valid object id after we
// register the new object
       
       subobject = new image(*pImOut);
       AlwaysAssert(subobject, AipsError); 
       return controller->addObject(subobject);
    } else {
       return ObjectID(True); // null
    }
}



Bool image::calcMask(const String& expr, const GlishRecord& regions,
                     const String& maskName, Bool makeDefault)
{
    if (detached()) {
        return False;
    }
     
    LogOrigin OR("image", "calcMask", id(), WHERE);
    LogIO os(OR);
    
// Get LatticeExprNode (tree) from parser
// Convert the GlishRecord containing regions to a
// PtrBlock<const ImageRegion*>.
 
   if (expr.empty()) {    
      os << "You must specify an expression" << LogIO::EXCEPTION;
      return False;
   }
   Block<LatticeExprNode> temps;
   String exprName;
   String newexpr = substituteOID (temps, exprName, expr);
   PtrBlock<const ImageRegion*> tempRegs;
   makeRegionBlock (tempRegs, regions, os);
   LatticeExprNode node = ImageExprParse::command (newexpr, temps, tempRegs);
 
// Delete the ImageRegions (by using an empty GlishRecord).
   
   makeRegionBlock (tempRegs, GlishRecord(), os);

// Make sure the expression is Boolean

   DataType type = node.dataType();
   if (type!=TpBool) {
      os << "The expression type must be Boolean" << LogIO::EXCEPTION;
   }
 
// Get the shape of the expression and check it matches that
// of the output image.  We don't check that the Coordinates
// match as that would be an un-necessary restriction.
      
   if (!node.isScalar()) {
      const IPosition shapeOut = node.shape();
      if (!pImage_p->shape().isEqual(shapeOut)) {
        os << LogIO::SEVERE << "The shape of the expression does not conform " << endl;
        os                  << "with the shape of the output image" << LogIO::POST;
        os << "Expression shape = " << shapeOut << endl;
        os << "Image shape      = " << pImage_p->shape() << LogIO::EXCEPTION;
      }
   }   
   

// Make mask and get hold of its name.   Currently new mask is forced to
// be default because of other problems.  Cannot use the usual makeMask
// function because I cant attach/make it default until the expression
// has been evaluated

   if (pImage_p->canDefineRegion()) {
   
// Generate mask name if not given

      String maskName2 = maskName;      
      if (maskName.empty()) maskName2 = pImage_p->makeUniqueRegionName(String("mask"), 0);
   
// Make the mask if it does not exist

      if (!pImage_p->hasRegion (maskName2, RegionHandler::Masks)) {
         pImage_p->makeMask (maskName2, True, False);
         os << LogIO::NORMAL << "Created mask `" << maskName2 << "'" << LogIO::POST;
//
         ImageRegion iR = pImage_p->getRegion(maskName2, RegionHandler::Masks);
         LCRegion& mask = iR.asMask();
         if (node.isScalar()) {    
            Bool value = node.getBool();
            mask.set(value);
         } else {
            mask.copyData(LatticeExpr<Bool>(node));   
         }
      } else {

// Access pre-existing mask.  

         ImageRegion iR = pImage_p->getRegion(maskName2, RegionHandler::Masks);
         LCRegion& mask2 = iR.asMask();
         if (node.isScalar()) {    
            Bool value = node.getBool();
            mask2.set(value);
         } else {
            mask2.copyData(LatticeExpr<Bool>(node));   
         }
      }
      if (makeDefault) pImage_p->setDefaultMask(maskName2);
   } else {
      os << "Cannot make requested mask for this type of image" << endl;
      os << "It is probably an ImageExpr or SubImage" << LogIO::EXCEPTION;
   }
//
   return True;
}



void image::maskHandler (Vector<String>& namesOut, Bool& hasOutput,
                         Vector<String>& namesIn, const String& op)
{
   if (detached()) return;
   LogIO os(LogOrigin("image", "maskHandler", WHERE));
//
   String OP = upcase(op);
   const uInt n = namesIn.nelements();
   hasOutput = False;  
//
   if (OP.contains(String("SET"))) {

// Set new default mask.  Empty means unset default mask

      if (n==0) {
         pImage_p->setDefaultMask(String(""));
      } else {
         pImage_p->setDefaultMask(namesIn(0));
      }
   } else if (OP.contains(String("DEF"))) {

// Return default mask

      namesOut.resize(1);
      namesOut(0) = pImage_p->getDefaultMask();
      hasOutput = True;
   } else if (OP.contains(String("DEL"))) {

// Delete mask(s)

      if (n<=0) {
         os << "You have not supplied any mask names" << LogIO::EXCEPTION;
      }
      for (uInt i=0; i<n; i++) {
         pImage_p->removeRegion(namesIn(i), RegionHandler::Masks, False);
      }
   } else if (OP.contains(String("REN"))) {

// Rename masks

      if (n!=2) {
         os << "You must give two mask names" << LogIO::EXCEPTION;
      }
      pImage_p->renameRegion(namesIn(1), namesIn(0), RegionHandler::Masks, False);
   } else if (OP.contains(String("GET"))) {

// Get names of all masks

      namesOut.resize(0);
      namesOut = pImage_p->regionNames(RegionHandler::Masks);
      hasOutput = True;
   } else if (OP.contains(String("COP"))) {

// Copy mask;  maskIn maskOut  or imageIn:maskIn maskOut  

      if (n!=2) {
         os << "You must give two mask names" << LogIO::EXCEPTION;
      }
      Vector<String> mask2 = stringToVector(namesIn(0), ':');
      const uInt n2 = mask2.nelements();
//
      String maskOut = namesIn(1);
      String maskIn, nameIn;
      Bool external = False;
      if (n2==1) {
         external = False;
         maskIn = mask2(0);
      } else if (n2==2) {
         external = True;
         nameIn = mask2(0);
         maskIn = mask2(1);
      } else {
         os << "Illegal number of mask names" << LogIO::EXCEPTION;
      }
//
      if (pImage_p->hasRegion(maskOut, RegionHandler::Any)) {
          os << "The mask " << maskOut << " already exists in image " << pImage_p->name() << LogIO::EXCEPTION;
      }
 
// Create new mask in output

      pImage_p->makeMask(maskOut, True, False);

// Copy masks

      ImageInterface<Float>* pImIn = 0;
      if (external) {
         pImIn = new PagedImage<Float>(nameIn);
         if (pImIn->shape() != pImage_p->shape()) {
            os << "Images have different shapes" << LogIO::EXCEPTION;
         }
      } else {
         pImIn = pImage_p;
      }
//
      AxesSpecifier axesSpecifier;   
      ImageUtilities::copyMask (*pImage_p, *pImIn, maskOut, maskIn, axesSpecifier);
//
      if (external) {
         delete pImIn; 
         pImIn = 0;
      }
   } else {
      os << "Unknown operation" << LogIO::EXCEPTION;
   }

// Make sure hist and stats are redone

   deleteHistAndStats();
}


void image::maxfit (SkyComponent& sky, Vector<Double>& absPixel,
                    const GlishRecord& glishRegion, Bool absFind,
                    Bool doPoint, Int width)
{
   LogIO os(LogOrigin("image", "maxfit", WHERE));

// Make subimage 

   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   AxesSpecifier axesSpec(False);   // drop degenerate
   String mask;
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                            glishRegion, mask, True, os, False, axesSpec);
   Vector<Float> blc;
   if (pRegionRegion) {
      blc = pRegionRegion->asLCSlicer().blc();
   } else {
      blc.resize(subImage.ndim());
      blc = 0.0;
   }
   delete pRegionRegion;
   delete pMaskRegion;

// Find it

   ImageSourceFinder<Float> sf(subImage);
   Double cutoff = 0.1;
   sky = sf.findSourceInSky (os, absPixel, cutoff, absFind, doPoint, width);
   absPixel += 1.0;
}


void image::modify(const Vector<SkyComponent>& mod, const GlishRecord& glishRegion,  
                   const String& mask, Bool subtract, Bool list)
{
    if (detached()) return;
    LogOrigin OR("image", "modify", id(), WHERE);
    LogIO os(OR);

//
    const uInt n = mod.nelements();
    if (n==0) {
       os << "There are no components in the model componentlist" << LogIO::EXCEPTION;
     }

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.   Drop degenerate axes.

    ImageRegion* pRegionRegion = 0;
    ImageRegion* pMaskRegion = 0;
    SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, mask, list, os, True);
    delete pRegionRegion;
    delete pMaskRegion;

// Allow for subtraction/addition

    ComponentList cl;
    for (uInt i=0; i<n; i++) {
       SkyComponent sky = mod(i);
       if (subtract) sky.flux().scaleValue(-1.0);
       cl.add(sky);
    }

// Do it

    ComponentImager::project(subImage, cl);

// Ensure that we reconstruct the statistics and histograms objects  
// now that the data have changed
    
    deleteHistAndStats();
}



ObjectID image::moments(const Vector<Int>& whichmoments, Index axis,
                        const GlishRecord& glishRegion,
                        const String& mask,
                        const Vector<String>& method,
                        const Vector<Index>& smoothaxes,
                        const Vector<String>& kernels,
                        const Vector<Quantum<Double> >& kernelwidths,
                        const Vector<Float>& includepix,
                        const Vector<Float>& excludepix,
                        Float peaksnr,  Float stddev,
                        const String& velocityType,
                        const String& out, const String& smoothout,
                        const String& pgdevice,
                        Int nx, Int ny,
                        Bool yind, Bool overwrite, 
                        Bool removeAxis)
//   
// Note that the user may give the strings (method & kernels)
// as either vectors of strings or one string with separators.
// Hence the code below that deals with it.   Also in image.g we therefore
// give the default value as a blank string rather than a null vector.
//
{
    if (detached()) return ObjectID(True);

    LogOrigin OR("image", "moments", id(), WHERE);
    LogIO os(OR);
     
// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.

    ImageRegion* pRegionRegion = 0;
    ImageRegion* pMaskRegion = 0;
    SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, mask, True, os, False);
    delete pRegionRegion;
    delete pMaskRegion;

// Create ImageMoments object

    ImageMoments<Float> momentMaker(subImage, os, overwrite, True);
        
// Set which moments to output
            
    if (!momentMaker.setMoments(whichmoments + 1)) {
       os << momentMaker.errorMessage() <<  LogIO::EXCEPTION;
    }
     
// Set moment axis

    if (axis() >= 0) {
       if (!momentMaker.setMomentAxis(axis())) {
          os << momentMaker.errorMessage() <<  LogIO::EXCEPTION; 
       }
    }
// Set moment methods
    
    if (method.nelements()>0 && method(0) != "") {
        String tmp;
        for (uInt i=0; i<method.nelements(); i++) {
            tmp += method(i) + " ";
        }
        Vector<Int> intmethods = momentMaker.toMethodTypes(tmp);
        if (!momentMaker.setWinFitMethod(intmethods)) {
           os << momentMaker.errorMessage() <<  LogIO::EXCEPTION; 
        }
    }
    
// Set smoothing
 
    if (kernels.nelements()>=1 && kernels(0)!="" &&
        smoothaxes.nelements()>=1 && kernelwidths.nelements()>=1) {
        String tmp;
        for (uInt i=0; i<kernels.nelements(); i++) {
            tmp += kernels(i) + " ";
        }
//
        Vector<Int> intkernels = VectorKernel::toKernelTypes(kernels);
        Vector<Int> intaxes(smoothaxes.nelements());
        Index::convertVector(intaxes, smoothaxes);
        if (!momentMaker.setSmoothMethod(intaxes, intkernels, kernelwidths)) {
           os << momentMaker.errorMessage() <<  LogIO::EXCEPTION; 
        }
    }  
 
// Set pixel include/exclude range
    
    if (!momentMaker.setInExCludeRange(includepix, excludepix)) {
       os << momentMaker.errorMessage() <<  LogIO::EXCEPTION; 
    }
   
// Set SNR cutoff
 
    if (!momentMaker.setSnr(peaksnr, stddev)) {
       os << momentMaker.errorMessage() <<  LogIO::EXCEPTION; 
    }

// Set velocity type

    if (!velocityType.empty()) {
       MDoppler::Types velType;
       if (!MDoppler::getType(velType, velocityType)) {
          os << LogIO::WARN << "Illegal velocity type, using RADIO" << LogIO::POST;
          velType = MDoppler::RADIO;
       }
       momentMaker.setVelocityType(velType);
    }

// Set output names
                                      
    if (smoothout != "" && !momentMaker.setSmoothOutName(smoothout)) {
       os << momentMaker.errorMessage() <<  LogIO::EXCEPTION; 
    }
 
// Set plotting attributes
        
    PGPlotter plotter;
    if (!pgdevice.empty()) {
//      try {
            plotter = PGPlotter(pgdevice);
//      } catch (AipsError x) {
//          os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
//          return False;
//      } 
        Vector<Int> nxy(2); nxy(0) = nx; nxy(1) = ny;
        if (nx < 0 || ny < 0) nxy.resize(0);
        if (!momentMaker.setPlotting(plotter, nxy, yind)) {
          os << momentMaker.errorMessage() <<  LogIO::EXCEPTION; 
        }
    }

// If no file name given for one moment image, make TempImage.
// Else PagedImage results

   Bool doTemp = False;
   if (out.empty() && whichmoments.nelements()==1) doTemp = True;
     
// Create moments

    PtrBlock<MaskedLattice<Float>* > images;
    if (!momentMaker.createMoments(images, doTemp, out, removeAxis)) {
       os << momentMaker.errorMessage() <<  LogIO::EXCEPTION; 
    }
    momentMaker.closePlotting();

// Return handle of first image

   ObjectID oid(True);
   ObjectController *controller = ApplicationEnvironment::objectController();
   ApplicationObject *subobject = 0;
   if (controller) {
    
// We have a controller, so we can return a valid object id after we
// register the new object

       ImageInterface<Float>* pIm = dynamic_cast<ImageInterface<Float>*>(images[0]);
       subobject = new image(*pIm);
       AlwaysAssert(subobject, AipsError);
       oid = controller->addObject(subobject);
   }

// Clean up pointer block

   for (uInt i=0; i<images.nelements(); i++) delete images[i];
//
   return oid;
}


void image::addNoise (const GlishRecord& glishRegion,
                      const String& type,
                      const Vector<Double>& pars, 
                      Bool zeroIt)
{
   LogIO os(LogOrigin("image",  "addNoise", id(), WHERE));

// Make SubImage

   String mask;   
   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, mask, False, os, True);
   delete pRegionRegion;
   delete pMaskRegion;

// Zero subimage if requested

   if (zeroIt) subImage.set(0.0);

// Do it

   Random::Types typeNoise = Random::asType(type);
   LatticeAddNoise lan(typeNoise, pars);
   lan.add(subImage);
//
   deleteHistAndStats();
}





void image::replaceMaskedPixels(const String& pixels, const GlishRecord& glishRegion,
                                const String& maskRegion,  Bool list, 
                                Bool updateMask, const GlishRecord& tempRegions)
{  
    if (detached()) {
        return;
    }
    LogIO os(LogOrigin("image",  "replaceMaskedPixels", id(), WHERE));
//
    if (pixels.empty()) {
       os << "You must specify an expression" << LogIO::EXCEPTION;
    }

// Whine about no mask if appropriate.  

    if (maskRegion.empty() && !pImage_p->isMasked()) {
       os << "This image does not have a mask - no action taken" << LogIO::WARN;
       return;
    }
     
// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.

    ImageRegion* pRegionRegion = 0;
    ImageRegion* pMaskRegion = 0;
    SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, maskRegion, list, 
                                             os, True);
    delete pRegionRegion;
    delete pMaskRegion;

// See if we can write to ourselves

    if (!subImage.isWritable()) {
       os << "This image is not writable.  It is probably a reference or expression virtual image" << LogIO::EXCEPTION;
    }

// Get LatticeExprNode (tree) from parser.
// Convert the GlishRecord containing regions to a
// PtrBlock<const ImageRegion*>.
 
    Block<LatticeExprNode> temps;
    String exprName;
    String newexpr = substituteOID (temps, exprName, pixels);
    PtrBlock<const ImageRegion*> tempRegs;
    makeRegionBlock (tempRegs, tempRegions, os);
    LatticeExprNode node = ImageExprParse::command (newexpr, temps, tempRegs);
 
// Delete the ImageRegions (by using an empty GlishRecord).
   
    makeRegionBlock (tempRegs, GlishRecord(), os);

// Create the LEL expression we need.  It's like  replace(lattice, pixels)
// where pixels is an expression itself.
  
   LatticeExprNode node2 = replace(subImage, node);

// Do it

    subImage.copyData(LatticeExpr<Float>(node2));

// Update the mask if desired

    if (updateMask) {
       Lattice<Bool>& mask = subImage.pixelMask();
       LatticeExprNode node (iif(!mask,True,mask));
       LatticeExpr<Bool> expr(node);
       mask.copyData(expr);
    }    

// Ensure that we reconstruct the statistics and histograms objects
// now that the data/mask have changed
         
    deleteHistAndStats();   
}
    



void image::set(Bool setPixels, const String& pixels,
                Bool setMask, Bool mask,
                const GlishRecord& glishRegion,
                const Bool list,
                const GlishRecord& tempRegions)
{  
    if (detached()) {
        return;
    }
    LogIO os(LogOrigin("image",  "set", id(), WHERE));
    if (!setPixels && !setMask) {
       os << LogIO::WARN << "Nothing to do" << LogIO::POST;
       return;
    }

// Try and make a mask if we need one. 

    if (setMask && !pImage_p->isMasked()) {
       String maskName("");
       makeMask(*pImage_p, maskName, True, True, os, list);
    }
     
// Make region and subimage

    const ImageRegion* pRegion = makeRegionRegion(*pImage_p, glishRegion, list, os);
    SubImage<Float> subImage(*pImage_p, *pRegion, True);
    delete pRegion;

       
// Set the pixels 

    if (setPixels) {

// Get LatticeExprNode (tree) from parser
// Convert the GlishRecord containing regions to a
// PtrBlock<const ImageRegion*>.
 
      if (pixels.empty()) {
         os << "You must specify an expression" << LogIO::EXCEPTION;
      }
      Block<LatticeExprNode> temps;
      String exprName;
      String newexpr = substituteOID (temps, exprName, pixels);
      PtrBlock<const ImageRegion*> tempRegs;
      makeRegionBlock (tempRegs, tempRegions, os);
      LatticeExprNode node = ImageExprParse::command (newexpr, temps, tempRegs);
 
// Delete the ImageRegions (by using an empty GlishRecord).
   
      makeRegionBlock (tempRegs, GlishRecord(), os);
//
// We must have a scalar expression
//
      if (!node.isScalar()) {
         os << "The pixels expression must be scalar" << LogIO::EXCEPTION;
      }
      if (node.isInvalidScalar()) {
         os << "The scalar pixels expression is invalid" << LogIO::EXCEPTION;
      }
      LatticeExprNode node2 = toFloat(node);
//
// if region==T (good) set value given by pixel expression, else
// leave the pixels as they are
//
       LatticeRegion region = subImage.region();
       LatticeExprNode node3(iif(region, node2.getFloat(), subImage));
       subImage.copyData(LatticeExpr<Float>(node3));
    } 
//
// Set the mask
//
    if (setMask) {
       Lattice<Bool>& pixelMask = subImage.pixelMask();
       LatticeRegion region = subImage.region();
//
// if region==T (good) set value given by "mask", else
// leave the pixelMask as it is
//
       LatticeExprNode node4(iif(region, mask, pixelMask));
       pixelMask.copyData(LatticeExpr<Bool>(node4));
    } 
//    
// Ensure that we reconstruct the statistics and histograms objects
// now that the data/mask have changed
         
    deleteHistAndStats();   
}
    

ObjectID image::separableConvolution (const GlishRecord& glishRegion,
                                      const String& mask,
                                      const Vector<Index>& smoothaxes,
                                      const Vector<String>& kernels,
                                      const Vector<Quantum<Double> >& kernelwidths,
                                      Bool autoScale, Double scale,
                                      const String& outFile, Bool overwrite)
{
    if (detached()) { 
        return ObjectID(True);
    
    }
     
    LogOrigin OR("image", "separableConvolution", id(), WHERE);
    LogIO os(OR);
    
// Checks
 
    if (smoothaxes.nelements()==0) {
       os << "You have not specified any axes to convolve" << LogIO::EXCEPTION;
    }  
    if (smoothaxes.nelements()!=kernels.nelements() ||
        smoothaxes.nelements()!=kernelwidths.nelements()) {
       os << "You must give the same number of axes, kernels and widths"
          << LogIO::EXCEPTION;
    }
       
// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.

    ImageRegion* pRegionRegion = 0;
    ImageRegion* pMaskRegion = 0;
    SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, mask, True, os, False);
    delete pRegionRegion;
    delete pMaskRegion;
 
// Create convolver
  
    SepImageConvolver<Float> sic(subImage, os, True);
                                   
// Handle inputs.

    Bool useImageShapeExactly = False;
    Vector<Int> smoothaxes2;
    Index::convertVector(smoothaxes2, smoothaxes);
    for (uInt i=0; i<smoothaxes2.nelements(); i++) {
       VectorKernel::KernelTypes type = VectorKernel::toKernelType(kernels(i));
       sic.setKernel(uInt(smoothaxes2(i)), type, kernelwidths(i), autoScale, 
                     useImageShapeExactly, scale);
       os << LogIO::NORMAL << "Axis " << smoothaxes2(i) 
          << " : kernel shape = " << sic.getKernelShape(uInt(smoothaxes2(i))) << LogIO::POST;
    }
 

// Make output image  - leave it until now incase there are
// errors in VectorKernel

    PtrHolder<ImageInterface<Float> > imOut;
    if (outFile.empty()) {
       os << LogIO::NORMAL << "Creating (temp)image of shape "
          << subImage.shape() << LogIO::POST;   
       imOut.set(new TempImage<Float>(subImage.shape(), subImage.coordinates()));
    } else {
       if (!overwrite) {
          NewFile validfile;
          String errmsg;
          if (!validfile.valueOK(outFile, errmsg)) {
              os << errmsg << LogIO::EXCEPTION;  
          }
       }
//
       os << LogIO::NORMAL << "Creating image '" << outFile << "' of shape "
          << subImage.shape() << LogIO::POST;   
       imOut.set(new PagedImage<Float>(subImage.shape(), subImage.coordinates(),
                                       outFile));
    }
    ImageInterface<Float>* pImOut = imOut.ptr();
    ImageUtilities::copyMiscellaneous(*pImOut, *pImage_p);

// Do it
 
    sic.convolve(*pImOut);
    
// Return handle
 
    
    ObjectController *controller = ApplicationEnvironment::objectController();
    ApplicationObject *subobject = 0;
    if (controller) {

// We have a controller, so we can return a valid object id after we
// register the new object
     
        subobject = new image(*pImOut);
        AlwaysAssert(subobject, AipsError);
        return controller->addObject(subobject);
    } else {
        return ObjectID(True); // null
    }
}



void image::tofits(const String &fitsfile, Bool velocity, Bool optical,
		   Int bitpix, Float minpix, Float maxpix, 
                   const GlishRecord& glishRegion, const String& mask,
                   Bool overwrite, Bool dropDeg, Bool degLast)
//
// Convert image to FITS
//
{
    if (detached()) {
	return;
    }
    String error;
    LogIO os(LogOrigin("image", "tofits", id(), WHERE));

// Check output file

   if (!overwrite && !fitsfile.empty()) {
      NewFile validfile;
      String errmsg;
      if (!validfile.valueOK(fitsfile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
   }

// The SubImage that goes to the FITSCOnverter no longer will know
// the name of the parent mask, so spit it out here

    if (pImage_p->isMasked()) {
       os << LogIO::NORMAL << "Applying mask of name '"
          << pImage_p->getDefaultMask() << "'" << LogIO::POST;
    }

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.
 
    ImageRegion* pRegionRegion = 0;
    ImageRegion* pMaskRegion = 0;
    AxesSpecifier axesSpecifier;
    if (dropDeg) axesSpecifier = AxesSpecifier(False);
    SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, mask, True, os, False,
                                             axesSpecifier);
    delete pRegionRegion;
    delete pMaskRegion;
//
    Bool ok = ImageFITSConverter::ImageToFITS(error, subImage, fitsfile,
                                              HostInfo::memoryFree()/1024,
                                              velocity, optical,
                                              bitpix, minpix, maxpix, overwrite, degLast);
    if (!ok) os << error  << LogIO::EXCEPTION;
}



// Private methods


SkyComponent image::encodeSkyComponent(LogIO& os, 
                                       Double& facToJy,
                                       const ImageInterface<Float>& subIm,
                                       ComponentType::Shape model,
                                       const Vector<Double>& parameters,
                                       Stokes::StokesTypes stokes,
                                       Bool xIsLong, Bool deconvolveIt) const
//
// This function takes a vector of doubles and converts them to
// a SkyComponent.   These doubles are in the 'x' and 'y' frames
// (e.g. result from Fit2D). It is possible that the
// x and y axes of the pixel array are lat/long rather than
// long/lat if the CoordinateSystem has been reordered.  So we have
// to take this into account before making the SkyComponent as it
// needs to know long/lat values.  The subImage holds only the sky
//
// Input
//   pars(0) = Flux     image units
//   pars(1) = x cen    abs pix
//   pars(2) = y cen    abs pix
//   pars(3) = major    pix
//   pars(4) = minor    pix
//   pars(5) = pa radians (pos +x -> +y)
// Output
//   facToJy = converts brightness units to Jy 
//
{
   const ImageInfo& ii = subIm.imageInfo();
   const CoordinateSystem& cSys = subIm.coordinates();
   const Unit& bU = subIm.units();
   SkyComponent sky = 
      ImageUtilities::encodeSkyComponent (os, facToJy, ii, cSys, bU, model, 
                                          parameters, stokes, xIsLong);
//
   if (!deconvolveIt) return sky;
//
   Vector<Quantum<Double> > beam = ii.restoringBeam();
   if (beam.nelements()==0) {
      os << LogIO::WARN << "This image does not have a restoring beam so no deconvolution possible" << LogIO::POST;
      return sky;
   } else {
      Int dirCoordinate = cSys.findCoordinate(Coordinate::DIRECTION);
      if (dirCoordinate==-1) {
         os << LogIO::WARN << "This image does not have a DirectionCoordinate so no deconvolution possible" << LogIO::POST;
         return sky;
      }
//
      const DirectionCoordinate& dirCoord = cSys.directionCoordinate(dirCoordinate);
      return deconvolveSkyComponent(os, sky, beam, dirCoord);
   }
}

void image::encodeSkyComponentError (LogIO& os, 
                                     SkyComponent& sky,
                                     Double facToJy,
                                     const ImageInterface<Float>& subIm,
                                     const Vector<Double>& parameters,
                                     const Vector<Double>& errors,
                                     Stokes::StokesTypes stokes,
                                     Bool xIsLong) const
//
// Input
//   facToJy = conversion factor to Jy
//   pars(0) = peak flux  image units
//   pars(1) = x cen    abs pix
//   pars(2) = y cen    abs pix
//   pars(3) = major    pix
//   pars(4) = minor    pix
//   pars(5) = pa radians (pos +x -> +y)
//
//   error values will be zero for fixed parameters
{
//
// Flux. The fractional error of the integrated and peak flux
// is the same.  errorInt = Int * (errorPeak / Peak) * facToJy

   Flux<Double> flux = sky.flux();      // Integral
   Vector<Double> valueInt;
   flux.value(valueInt);
   Vector<Double> tmp(4, 0.0);
//
   if (errors(0) > 0.0) {
      Double rat = (errors(0) / parameters(0)) * facToJy;
      if (stokes==Stokes::I) { 
         tmp(0) = valueInt(0) * rat;
      } else if (stokes==Stokes::Q) {
         tmp(1) = valueInt(1) * rat;
      } else if (stokes==Stokes::U) {         
         tmp(2) = valueInt(2) * rat;
      } else if (stokes==Stokes::V) {
         tmp(3) = valueInt(3) * rat;
      } else {
         os << LogIO::WARN << "Can only properly handle I,Q,U,V presently." << endl;
         os << "The brightness is assumed to be Stokes I"  << LogIO::POST;
         tmp(0) = valueInt(0) * rat;
      }
      flux.setErrors(tmp(0), tmp(1), tmp(2), tmp(3));
   }

// Shape.  Only TwoSided shapes have something for me to do

   IPosition pixelAxes(2);
   pixelAxes(0) = 0; 
   pixelAxes(1) = 1; 
   if (!xIsLong) {
     pixelAxes(1) = 0; 
     pixelAxes(0) = 1; 
   }
//
   ComponentShape& shape = sky.shape();
   TwoSidedShape* pS = dynamic_cast<TwoSidedShape*>(&shape);
   Vector<Double> dParameters(5);
   Vector<Quantum<Double> > wParameters;
   const CoordinateSystem& cSys = subIm.coordinates();
   if (pS) {
      if (errors(3)>0.0 || errors(4)>0.0 || errors(5)>0.0) {
         dParameters(0) = parameters(1);    // x
         dParameters(1) = parameters(2);    // y

// Use the pixel to world converter by pretending the width errors are widths.
// The minor error may be greater than major error so beware as the
// widths converted will flip them about.  The error in p.a. is just the
// input error value as its already angular.

         if (errors(3)>0.0) {
            dParameters(2) = errors(3);          // Major
         } else {
            dParameters(2) = 0.1*parameters(3);  // Fudge
         }
         if (errors(4)>0.0) {
            dParameters(3) = errors(4);          // Minor
         } else {
            dParameters(3) = 0.1*parameters(4);  // Fudge
         }
         dParameters(4) = parameters(5);          // PA

// If flipped, it means pixel major axis morphed into world minor
// Put back any zero errors as well.

         Bool flipped =
            ImageUtilities::pixelWidthsToWorld (os, wParameters, dParameters, cSys, pixelAxes, False);
         Quantum<Double> paErr(errors(5), Unit(String("rad")));
         if (flipped) {
            if (errors(3) <= 0.0) wParameters(1).setValue(0.0);
            if (errors(4) <= 0.0) wParameters(0).setValue(0.0);
            pS->setErrors(wParameters(1), wParameters(0), paErr);
         } else {
            if (errors(3) <= 0.0) wParameters(0).setValue(0.0);
            if (errors(4) <= 0.0) wParameters(1).setValue(0.0);
            pS->setErrors(wParameters(0), wParameters(1), paErr);
         }
      }
   }

// Position.  Use the pixel to world widths converter again.
// Or do something simpler ?

   {
      if (errors(1)>0.0 || errors(2)>0.0) {

// Use arbitrary position error of 1 pixel if none

         if (errors(1)>0.0) {
            dParameters(2) = errors(1);      // X
         } else {
            dParameters(2) = 1.0;
         }
         if (errors(2)>0.0) {
            dParameters(3) = errors(2);      // Y
         } else {
            dParameters(3) = 1.0;
         }
         dParameters(4) = 0.0;               // Pixel errors are in X/Y directions not along major axis
         Bool flipped = 
            ImageUtilities::pixelWidthsToWorld (os, wParameters, dParameters, cSys, pixelAxes, False);
         if (flipped) {
            pS->setRefDirectionError (wParameters(1), wParameters(0));     // TSS::setRefDirErr interface has lat first
         } else {
            pS->setRefDirectionError (wParameters(0), wParameters(1));     // TSS::setRefDirErr interface has lat first
         }
      }
   }
}



void image::hanning_smooth (Array<Float>& out,
                            Array<Bool>& maskOut,
                            const Vector<Float>& in,
                            const Array<Bool>& maskIn,
                            Bool isMasked) const
{
   const uInt nIn = in.nelements();
   const uInt nOut = out.nelements();
   Bool deleteOut, deleteIn, deleteMaskIn, deleteMaskOut;
//
   const Float* pDataIn = in.getStorage(deleteIn);
   const Bool* pMaskIn = 0;
   if (isMasked) {
      pMaskIn = maskIn.getStorage(deleteMaskIn);
   }
//
   Float* pDataOut = out.getStorage(deleteOut);
   Bool* pMaskOut = 0;
   if (isMasked) {
      pMaskOut = maskOut.getStorage(deleteMaskOut);
   }
            
// Zero masked points.
       
   Float* pData = 0;
   if (isMasked) {
      pData = new Float[in.nelements()];
      for (uInt i=0; i<nIn; i++) {
         pData[i] = pDataIn[i];
         if (!pMaskIn[i]) pData[i] = 0.0;
      }
   } else {
      pData = (Float*)pDataIn;
   }

// Smooth
 
   if (nIn != nOut) {
 
// Dropping every other pixel.  First output pixel is centred
// on the second input pixel.   We discard the last input pixel
// if the input spectrum is of an even number of pixels
  
      if (isMasked) {
         Int j = 1;
         for (uInt i=0; i<nOut; i++) {
            pDataOut[i] = 0.25*(pData[j-1] + pData[j+1]) + 0.5*pData[j];
            pMaskOut[i] = pMaskIn[j];
            j += 2;
         }
      } else {
         Int j = 1;
         for (uInt i=0; i<nOut; i++) {
            pDataOut[i] = 0.25*(pData[j-1] + pData[j+1]) + 0.5*pData[j];
            j += 2;
         }
      }
   } else {
                               
// All pixels
 
      if (isMasked) {
         for (uInt i=1; i<nIn-1; i++) {
            pDataOut[i] = 0.25*(pData[i-1] + pData[i+1]) + 0.5*pData[i];
            pMaskOut[i] = pMaskIn[i];
         }
         pMaskOut[0] = pMaskIn[0];
         pMaskOut[nIn-1] = pMaskIn[nIn-1];
      } else {
         for (uInt i=1; i<nIn-1; i++) { 
            pDataOut[i] = 0.25*(pData[i-1] + pData[i+1]) + 0.5*pData[i];
         }
      }
      pDataOut[0] = 0.5*(pData[0] + pData[1]);
      pDataOut[nIn-1] = 0.5*(pData[nIn-2] + pData[nIn-1]);
   }
//
   if (isMasked) {
      delete [] pData;
      maskOut.putStorage(pMaskOut, deleteMaskOut);
      maskIn.freeStorage(pMaskIn, deleteMaskIn);
   }
   in.freeStorage(pDataIn, deleteIn);
   out.putStorage(pDataOut, deleteOut);
}
            
   

Vector<Double> image::singleParameterEstimate (Fit2D& fitter,
                                               Fit2D::Types model,
                                               const MaskedArray<Float>& pixels,
                                               Float minVal, Float maxVal, 
                                               const IPosition& minPos, 
                                               const IPosition& maxPos,
                                               Stokes::StokesTypes stokes,
                                               const ImageInterface<Float>& im,
                                               Bool xIsLong,
                                               LogIO& os) const
//
// position angle +x -> +y
//
{

// Return the initial fit guess as either the model, an auto guess, or some combination.

   Vector<Double> parameters;
   if (model==Fit2D::GAUSSIAN || model==Fit2D::DISK) {
//
// Auto determine estimate 
//
      parameters = fitter.estimate(model, pixels.getArray(), pixels.getMask());
//
      if (parameters.nelements()==0) {
//
// Fall back parameters
//
         os << LogIO::WARN << "The primary initial estimate failed.  Fallback may be poor" 
            << LogIO::POST;
//
         parameters.resize(6);
         IPosition shape = pixels.shape();
         if (abs(minVal)>abs(maxVal)) {
            parameters(0) = minVal;                                // height
            parameters(1) = Double(minPos(0));                     // x cen
            parameters(2) = Double(minPos(1));                     // y cen
         } else {
            parameters(0) = maxVal;                                // height
            parameters(1) = Double(maxPos(0));                     // x cen
            parameters(2) = Double(maxPos(1));                     // y cen
         }
         parameters(3) = Double(max(shape(0), shape(1)) / 2);      // major axis
         parameters(4) = 0.9*parameters(3);                        // minor axis
         parameters(5) = 0.0;                                      // position angle
      } else if (parameters.nelements()!=6) {
        os << "Not enough parameters returned by fitter estimate" << LogIO::EXCEPTION;
      }
   } else {

// points, levels etc
      os << "Only Gaussian/Disk auto-single estimates are available" << LogIO::EXCEPTION;

   }
   return parameters;
}


void image::getPointer (ImageInterface<Float>*& pImage, Bool& deleteIt,
                        const String& infile, LogIO& os)
{

// infile might be a string holding a file name, or a string
// holding an Image tool symbol

   ObjectController* controller = ApplicationEnvironment::objectController();

// Added this for python/acs prototype pipeline

    if (controller==0) {
       LogIO os(LogOrigin("image", "getPointer"));
       os << LogIO::WARN << "There is no ObjectController available so '$tool' strings will fail" << endl;
       return;
    }

// Get the object-id's from the string, where they are replaced by $n.

   Block<ObjectID> oid;
   String result = ObjectID::extractIDs (oid, infile);

// If there were no substitutions, the String is just the file name,
// else we assume just one $
  
   pImage = 0;
   if (oid.nelements() > 0) {
      if (oid.nelements()>1) {
         os << "Only one $ substituted tool is allowed in the infile string" << LogIO::EXCEPTION;
      }
   
// Get the image object pointer

      ApplicationObject* obj = controller->getObject (oid[0]);
      AlwaysAssert (obj->className() == "image", AipsError);
      const image* img = dynamic_cast<const image*>(obj);

// Get the underlying ImageInterface pointer

      pImage = img->imagePointer();
      deleteIt = False;
   } else {
      ImageUtilities::openImage (pImage, infile, os);
      deleteIt = True;
   }
}


String image::substituteOID (Block<LatticeExprNode>& nodes,
                             String& exprName,
                             const String& expr) const
{
    ObjectController* controller = ApplicationEnvironment::objectController();

// Added this for python/acs prototype pipeline

    if (controller==0) {
       LogIO os(LogOrigin("image", "substituteOID", id(), WHERE));
       os << LogIO::WARN << "There is no ObjectController available so '$tool' substitutions are not available" << endl;
       os << LogIO::WARN << "Any LatticeExpressionLanguage (LEL) strings containing these will fail" << LogIO::POST;
       return expr;
    }

// Get the object-id's from the string, where they are replaced by $OBJ#n.

    Block<ObjectID> oid;
    String result = ObjectID::extractIDs (oid, expr);
    nodes.resize (oid.nelements(), False, True);
    exprName = result;
    char str[16];

// Get all image objects (as a non-templated LatticeExprNode).
// Create an expression 'name' by replacing $OBJ#n by the image name.

    for (uInt i=0; i<oid.nelements(); i++) {
        ApplicationObject* obj = controller->getObject (oid[i]);
        AlwaysAssert (obj->className() == "image", AipsError);
        const image* img = (const image*)obj;
        nodes[i] = LatticeExprNode (*img->pImage_p);

// Replace $OBJ#n by the image name.
// If the image is an expression, enclose it in parentheses.
// Enclose a name in quotes.
// Note that using gsub is in principle dangerous, because
// one could have $OBJ#n in a quoted string.
// However, in practice that won't occur.
// It is checked if only one replacement is done.

        sprintf (str, "$OBJ#%i#O", i+1);
        String name = img->pImage_p->name();
        if (name(0,12) == "Expression: ") {
            name = '(' + name.from(12) + ')';
        } else {
            name = "\"" + name + "\"";
        }
        Int nsub = exprName.gsub (str, name);
        AlwaysAssert (nsub==1, AipsError);
    }
    return result;
}           



ComponentType::Shape image::convertModelType (Fit2D::Types typeIn) const
{
   if (typeIn==Fit2D::GAUSSIAN) {
      return ComponentType::GAUSSIAN;
   } else if (typeIn==Fit2D::DISK) {
      return ComponentType::DISK;
   } else {
     throw(AipsError("Unrecognized model type"));
   }
}


SkyComponent image::deconvolveSkyComponent(LogIO& os, const SkyComponent& skyIn,
                                           const Vector<Quantum<Double> >& beam,
                                           const DirectionCoordinate& dirCoord) const
{
   SkyComponent skyOut;   
   skyOut = skyIn.copy();
//
   const ComponentShape& shapeIn = skyIn.shape();
   ComponentType::Shape type = shapeIn.type();

// Put beam p.a. into XY frame

   Vector<Quantum<Double> > beam2 = putBeamInXYFrame (beam, dirCoord);
   if (type==ComponentType::POINT) {
//
   } else if (type==ComponentType::GAUSSIAN) {
        
// Recover shape
    
      const TwoSidedShape& ts = dynamic_cast<const TwoSidedShape&>(shapeIn);
      Quantum<Double> major = ts.majorAxis();
      Quantum<Double> minor = ts.minorAxis();
      Quantum<Double> pa = ts.positionAngle();

// Adjust position angle to XY pixel frame  (pos +x -> +y)

      Vector<Double> p = ts.toPixel(dirCoord);

// Deconvolve.  
//      Bool isPointSource = deconvolveFromBeam(major, minor, paXYFrame, os, beam);      

      Quantum<Double> paXYFrame(p(4), Unit("rad"));
      Quantum<Double> paXYFrame2(paXYFrame);
      deconvolveFromBeam(major, minor, paXYFrame, os, beam2);

// Account for frame change of position angle
    
      Quantum<Double> diff = paXYFrame2 - paXYFrame;
      pa -= diff;
//
      const MDirection dirRefIn = shapeIn.refDirection();
      GaussianShape shapeOut(dirRefIn, major, minor, pa);
      skyOut.setShape(shapeOut);
   } else {
      os << "Cannot deconvolve components of type " << shapeIn.ident() << LogIO::EXCEPTION;
   }
//
   return skyOut;
}
    

Bool image::deconvolveFromBeam(Quantum<Double>& majorFit,
                               Quantum<Double>& minorFit,
                               Quantum<Double>& paFit, LogIO& os,
                               const Vector<Quantum<Double> >& beam) const
{

// The position angle of the component is measured in the frame
// of the local coordinate system.  Since the restoring beam
// is invariant over the image, we need to rotate the restoring
// beam into the same coordinate system as the component.
//
   Bool isPointSource = False;
   Quantum<Double> majorOut;
   Quantum<Double> minorOut;
   Quantum<Double> paOut;
   try {
     isPointSource =
        GaussianConvert::deconvolve(majorOut, minorOut, paOut,
                                    majorFit, minorFit, paFit,
                                    beam(0), beam(1), beam(2));
   } catch (AipsError x) {
      os << LogIO::WARN << "Could not deconvolve beam from source - "
         << x.getMesg() << endl;
      {
         ostringstream oss;
         oss <<  "Model = " << majorFit << ", " << minorFit << ", " << paFit << endl;
         os << String(oss);
      }
      {
         ostringstream oss;
         oss << "Beam  = " << beam(0) << ", " << beam(1) << ", " << beam(2) << endl;
         os << String(oss) << LogIO::POST;
      }
      return False;
   } 
//
   os << LogIO::NORMAL << "Deconvolving gaussian fit from beam" << LogIO::POST;
   majorFit = majorOut;
   minorFit = minorOut;
   paFit = paOut;
//
   return isPointSource;
}


Vector<Quantum<Double> > image::putBeamInXYFrame (const Vector<Quantum<Double> >& beam, 
                                                  const DirectionCoordinate& dirCoord) const
//
// The beam is spatially invariant across an image, and its position 
// must be fit in the pixel coordinate system to make any sense.
// However, its position angle is positive N->E which means
// some attempt to look at the increments has been made...
// We want positive +x -> +y  so have to try and do this.
{
   Vector<Quantum<Double> > beam2 = beam.copy();
   Vector<Double> inc = dirCoord.increment();
   Double pa  = beam(2).getValue(Unit("rad"));
   Double pa2 = beam2(2).getValue(Unit("rad"));
//
   if (inc(1) > 0) {
      if (inc(0) < 0) {
         pa2 = C::pi_2 + pa;
      } else {
         pa2 = C::pi_2 - pa;
      }
   } else {
      if (inc(0) < 0) {
         pa2 = C::pi + C::pi_2 - pa;
      } else {
         pa2 = C::pi + C::pi_2 + pa;
      }
   }
//
   Double pa3 = fmod(pa2, C::pi);
   if (pa3 < 0.0) pa3 += C::pi;
   beam2(2).setValue(pa3);
   beam2(2).setUnit(Unit("rad"));
   return beam2;
}

