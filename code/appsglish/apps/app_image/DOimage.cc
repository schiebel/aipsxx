//# DOimage.cc: defines DOimage class which implements functionality
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
//# $Id: DOimage.cc,v 19.40 2005/12/07 16:48:33 wyoung Exp $

#include <appsglish/app_image/DOcoordsys.h>

#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/Slicer.h>
#include <casa/Arrays/AxesSpecifier.h>
#include <components/ComponentModels/SkyComponent.h>
#include <casa/Containers/Record.h>
#include <coordinates/Coordinates/CoordinateSystem.h>
#include <coordinates/Coordinates/CoordinateUtil.h>
#include <coordinates/Coordinates/StokesCoordinate.h>
#include <coordinates/Coordinates/LinearCoordinate.h>
#include <coordinates/Coordinates/DirectionCoordinate.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <images/Images/FITSImage.h>
#include <images/Images/MIRIADImage.h>
#include <images/Images/ImageHistograms.h>
#include <images/Images/ImageStatistics.h>
#include <images/Images/ImageSummary.h>
#include <images/Images/ImageConcat.h>
#include <images/Images/ImageInterface.h>
#include <images/Images/ImageInfo.h>
#include <images/Images/ImageRegion.h>
#include <images/Images/PagedImage.h>
#include <images/Images/RegionHandler.h>
#include <images/Images/SubImage.h>
#include <images/Images/ImageRegrid.h>
#include <images/Images/RebinImage.h>
#include <images/Images/ImageTwoPtCorr.h>
#include <images/Images/ImageUtilities.h>
#include <images/Images/TempImage.h>
#include <images/Images/WCLELMask.h>
#include <images/Images/ImageExprParse.h>
#include <lattices/Lattices/LatticeStatsBase.h>
#include <lattices/Lattices/LatticeStatistics.h>
#include <lattices/Lattices/LatticeIterator.h>
#include <lattices/Lattices/LatticeStepper.h>
#include <lattices/Lattices/LCSlicer.h>
#include <lattices/Lattices/LCBox.h>
#include <lattices/Lattices/RegionType.h>
#include <lattices/Lattices/SubLattice.h>
#include <lattices/Lattices/LatticeUtilities.h>
#include <lattices/Lattices/LatticeSlice1D.h>
#include <lattices/Lattices/PixelCurve1D.h>
#include <casa/Logging/LogIO.h>
#include <casa/Logging/LogFilter.h>
#include <scimath/Mathematics/Interpolate2D.h>
#include <measures/Measures/MDoppler.h>
#include <casa/Quanta/Quantum.h>
#include <casa/Quanta/UnitMap.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <casa/OS/Directory.h>
#include <tables/Tables/Table.h>
#include <casa/System/PGPlotter.h>
#include <casa/System/ProgressMeter.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/Index.h>
#include <tasking/Tasking/MethodResult.h>
#include <tables/LogTables/NewFile.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <tasking/Tasking/ObjectController.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/COWPtr.h>
#include <casa/Utilities/PtrHolder.h>
#include <casa/Utilities/Regex.h>
#include <casa/BasicSL/String.h>
#include <casa/Containers/Block.h>

#include <casa/sstream.h>
#include <casa/iostream.h>
#include <casa/stdio.h>

#include <../app_image/DOimage.h>

#include <coordinates/Coordinates/DirectionCoordinate.h>

#include <casa/namespace.h>

image::image(const String& fileName)
//
// Constructor "image"
//
: pImage_p(0),
  pStatistics_p(0),
  pHistograms_p(0),
  pOldStatsRegionRegion_p(0),
  pOldStatsMaskRegion_p(0),
  pOldHistRegionRegion_p(0),
  pOldHistMaskRegion_p(0)
{

   LogIO os(LogOrigin("image",
            "image(const String& fileName)", id(), WHERE));
   ImageUtilities::openImage (pImage_p, fileName, os);
}



image::image(const String& outfile, const String& infile, 
             const GlishRecord& glishRegion, 
             const String& mask, Bool dropDegenerateAxes,
             Bool overwrite)
//
// Constructor "imagefromimage"
//
: pImage_p(0),
  pStatistics_p(0),
  pHistograms_p(0),
  pOldStatsRegionRegion_p(0),
  pOldStatsMaskRegion_p(0),
  pOldHistRegionRegion_p(0),
  pOldHistMaskRegion_p(0)
{
   LogIO os(LogOrigin("image", "imagefromimage", id(), WHERE));

// Open

   PtrHolder<ImageInterface<Float> > inImage;
   ImageUtilities::openImage (inImage, infile, os);
   ImageInterface<Float>* pInImage = inImage.ptr();
//
// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.    
//
   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   AxesSpecifier axesSpecifier;
   if (dropDegenerateAxes) axesSpecifier = AxesSpecifier(False);
   SubImage<Float> subImage = 
      makeSubImage (pRegionRegion, pMaskRegion, *pInImage,
                    glishRegion, mask, True, os, True, axesSpecifier);
   delete pRegionRegion;
   delete pMaskRegion;

// Create output image

   if (outfile.empty()) {
      pImage_p = new SubImage<Float>(subImage);
   } else {
      if (!overwrite) {
         NewFile validfile;
         String errmsg;
         if (!validfile.valueOK(outfile, errmsg)) {
            os << errmsg << LogIO::EXCEPTION;
         }
      }
//
      os << LogIO::NORMAL << "Creating image '" << outfile << "' of shape " 
         << subImage.shape() << LogIO::POST;
      pImage_p = new PagedImage<Float>(subImage.shape(), 
                                       subImage.coordinates(), outfile);
      if (pImage_p==0) {
        os << "Failed to create PagedImage" << LogIO::EXCEPTION;
      }
      ImageUtilities::copyMiscellaneous(*pImage_p, *pInImage);

// Make output mask if required

      if (subImage.isMasked()) {
         String maskName("");
         makeMask(*pImage_p, maskName, False, True, os, True);
      }

// Copy data and mask

      LatticeUtilities::copyDataAndMask(os, *pImage_p, subImage);
   }
}


image::image(const String &outfile, const Array<Float> &pixels,
             const GlishRecord& coordinates, Bool doLinear, 
             Bool log, Bool overwrite)
: pImage_p(0),
  pStatistics_p(0),
  pHistograms_p(0),
  pOldStatsRegionRegion_p(0),
  pOldStatsMaskRegion_p(0),
  pOldHistRegionRegion_p(0),
  pOldHistMaskRegion_p(0)
//
// Constructor "imagefromarray"
//
{
    LogIO os(LogOrigin("image", "imagefromaarray", id(), WHERE));

// Some protection.  Note that a Glish array, [], will
// propagate through to here to have ndim=1 and shape=0

   if (pixels.ndim()==0) {
      os << "The pixels array is empty" << LogIO::EXCEPTION;
   }
   for (uInt i=0; i<pixels.ndim(); i++) {
      if (pixels.shape()(i) <=0) {
         os << "The shape of the pixels array is invalid" << LogIO::EXCEPTION;
      }
   }

// Make with supplied coordinate if record not empty

   String error;
   if (coordinates.nelements()>0) {
       PtrHolder<CoordinateSystem> cSys(makeCoordinateSystem(coordinates, pixels.shape()));
       CoordinateSystem* pCS = cSys.ptr();
       if (!make_image(error, outfile, *pCS, pixels.shape(), 
                       os, log, overwrite)) {
          os << error << LogIO::EXCEPTION;
       }
   } else {

// Make default CoordinateSystem

      CoordinateSystem cSys = CoordinateUtil::makeCoordinateSystem(pixels.shape(), doLinear);
      centreRefPix(cSys, pixels.shape());
      if (!make_image(error, outfile, cSys, pixels.shape(), os, log, overwrite)) {
         os << error << LogIO::EXCEPTION;
      }
   }

// Fill image

   pImage_p->putSlice(pixels, IPosition(pixels.ndim(), 0),
                      IPosition(pixels.ndim(), 1));
}

image::image(const String &outfile, const Vector<Int> &shape,
             const GlishRecord& coordinates, Bool doLinear, 
             Bool log, Bool overwrite)
: pImage_p(0),
  pStatistics_p(0),
  pHistograms_p(0),
  pOldStatsRegionRegion_p(0),
  pOldStatsMaskRegion_p(0),
  pOldHistRegionRegion_p(0),
  pOldHistMaskRegion_p(0)
//
// Constructor "imagefromshape"
//
{
    LogIO os(LogOrigin("image", "imagefromshape", id(), WHERE));

// Some protection

   if (shape.nelements()==0) {
      os << "The shape is invalid" << LogIO::EXCEPTION;
   }
   for (uInt i=0; i<shape.nelements(); i++) {
      if (shape(i) <=0) {
         os << "The shape is invalid" << LogIO::EXCEPTION;
      }
   }

// Make with supplied CoordinateSystem if record not empty

   String error;
   if (coordinates.nelements()>0) {
       PtrHolder<CoordinateSystem> pCS(makeCoordinateSystem(coordinates, shape));
       if (!make_image(error, outfile, *(pCS.ptr()), shape, 
                       os, log, overwrite)) {
          os << error << LogIO::EXCEPTION;
       }
   } else {

// Make default CoordinateSystem

      CoordinateSystem cSys = CoordinateUtil::makeCoordinateSystem(shape, doLinear);
      centreRefPix(cSys, shape);
      if (!make_image(error, outfile, cSys, shape, os, log, overwrite)) {
         os << error << LogIO::EXCEPTION;
      }
   }
   pImage_p->set(0.0);
}


image::image(const String& outfile, const Vector<String>& infiles,
             Index axis, Bool relax, Bool tempClose, Bool overwrite)
: pImage_p(0),
  pStatistics_p(0),
  pHistograms_p(0),
  pOldStatsRegionRegion_p(0),
  pOldStatsMaskRegion_p(0),
  pOldHistRegionRegion_p(0),
  pOldHistMaskRegion_p(0)
//
// Constructor "imageconcat"
//
// We rely on the user to use Glish according to:
//
//   "f1 f2"  if they want to pass in a Vector of names
//   "f1" or 'f1'  for single strings. 
//
// Imagine they have "f1,f2"   This looks like two input file names.
// If I parsed this with ArrayUtil::stringToVector, it would convert
// it into a vector of two strings and we would be happy.  However,
// we become unhappy under some wild-card expressions.  For example,
// infiles="hcn.{a,b}"   This would be converted by getStrings to
// a vector consisting of ['hcn.{', 'b}']  and Regex would barf.  
// So the only way to cope is to get the users to be precise in their
// usage of the infiles argument in Glish.  I have of course
// documented this !
//
//
{
   LogIO os(LogOrigin("image", "imageconcat", id(), WHERE));

// There could be wild cards embedded in our list so expand them out

   Vector<String> expInNames = Directory::shellExpand(infiles, False);
   if (expInNames.nelements() <= 1) {
      os << "You must give at least two valid input images" << LogIO::EXCEPTION;
   }      
   os << LogIO::NORMAL << "Number of expanded file names = " 
      << expInNames.nelements() << LogIO::POST;

// Verify output file

   if (!outfile.empty() && !overwrite) {
      NewFile validfile;
      String errmsg;
      if (!validfile.valueOK(outfile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
   }

// Find spectral axis of first image

   PtrHolder<ImageInterface<Float> > im;
   ImageUtilities::openImage (im, expInNames(0), os);

//   PagedImage<Float> im(expInNames(0), MaskSpecifier(True));

   CoordinateSystem cSys = im.ptr()->coordinates();
   Int iAxis = axis();
   if (iAxis < 0) {
     iAxis = CoordinateUtil::findSpectralAxis(cSys);
     if (iAxis < 0) {
        os << "Could not find a spectral axis in first input image" << LogIO::EXCEPTION;
     }
   }
   
// Create concatenator.  Use holder so if exceptions, the ImageConcat
// object gets cleaned up

   uInt axis2 = uInt(iAxis);
   PtrHolder<ImageConcat<Float> > pConcat(new ImageConcat<Float>(axis2, tempClose));

// Set first image

   pConcat.ptr()->setImage(*(im.ptr()), relax);

// Set the other images.  We may run into the open file limit.

   for (uInt i=1; i<expInNames.nelements(); i++) {
      Bool doneOpen = False;
      try {
         PtrHolder<ImageInterface<Float> > im2;
         ImageUtilities::openImage (im2, expInNames(i), os);
//         PagedImage<Float> im2(expInNames(i), MaskSpecifier(True));
         doneOpen = True;
         pConcat.ptr()->setImage(*(im2.ptr()), relax);
      } catch (AipsError x) {      
          if (!doneOpen) {
             os << "Failed to open file " << expInNames(i) << endl;
             os << "This may mean you have too many files open simultaneously" << endl;
             os << "Try using tempclose=T in the imageconcat constructor" << LogIO::EXCEPTION;
          } else {
             os << x.getMesg() << LogIO::EXCEPTION;
          }
      } 
   }
//
   if (!outfile.empty()) {

// Construct output image and give it a mask if needed

      pImage_p = new PagedImage<Float>(pConcat.ptr()->shape(), pConcat.ptr()->coordinates(), 
                                       outfile);
      if (!pImage_p) {
         os << "Failed to create PagedImage" << LogIO::EXCEPTION;
      }
      os << LogIO::NORMAL << "Creating image '" << outfile << "' of shape " 
         << pImage_p->shape() << LogIO::POST;
//
      if (pConcat.ptr()->isMasked()) {
         String maskName("");
         makeMask(*pImage_p, maskName, False, True, os, True);
      }

// Copy to output

      LatticeUtilities::copyDataAndMask(os, *pImage_p, *(pConcat.ptr()));
      ImageUtilities::copyMiscellaneous(*pImage_p, *(pConcat.ptr()));
   } else {
      pImage_p = pConcat.ptr()->cloneII();
   }
}



image::image(const ImageInterface<Float>& inImage)
//
// ImageInterface  constructor
//
: pImage_p(0),
  pStatistics_p(0),
  pHistograms_p(0),
  pOldStatsRegionRegion_p(0),
  pOldStatsMaskRegion_p(0),
  pOldHistRegionRegion_p(0),
  pOldHistMaskRegion_p(0)
{
   pImage_p = inImage.cloneII();
}


image::image(const image &other)
//
// Copy constructor
//
: pImage_p(0),
  pStatistics_p(0),
  pHistograms_p(0),
  pOldStatsRegionRegion_p(0),
  pOldStatsMaskRegion_p(0),
  pOldHistRegionRegion_p(0),
  pOldHistMaskRegion_p(0)
{
    *this = other;
}


image &image::operator=(const image &other)
// 
// Assignment operator
//
{
    if (this != &other) {
       if (pImage_p != 0) delete pImage_p;
       pImage_p = other.pImage_p->cloneII();

// Ensure stats and histo are always redone

       deleteHistAndStats();
//
       oldStatsStorageForce_p = other.oldStatsStorageForce_p;
       oldHistStorageForce_p = other.oldHistStorageForce_p;
    }

    return *this;
}

image::~image()
{
   if (pImage_p != 0) {
      delete pImage_p;
      pImage_p = 0;
   }
   deleteHistAndStats();
}



// Functions

ObjectID image::addDegenerateAxes (const String& outFile, Bool direction, Bool spectral, 
                                   const String& stokes, Bool linear, Bool tabular,
                                   Bool overwrite)
{
   if (detached()) {
      return ObjectID(True);
   }
   LogIO os(LogOrigin("image", "addDegenerateAxes", id(), WHERE));

//
   PtrHolder<ImageInterface<Float> > outImage;
   ImageUtilities::addDegenerateAxes (os, outImage, *pImage_p, outFile,
                                      direction, spectral,
                                      stokes, linear, tabular,
                                      overwrite);

// Return handle

   ObjectController* controller = ApplicationEnvironment::objectController();
   ApplicationObject* subobject = 0;
   if (controller) {

// We have a controller, so we can return a valid object id after we
// register the new object

      ImageInterface<Float>* pOutImage = outImage.ptr();
      subobject = new image(*pOutImage);
      AlwaysAssert(subobject, AipsError);
      return controller->addObject(subobject);
   } else {
     return ObjectID(True); // null 
   }
}



String image::brightnessUnit () const
{
   if (detached()) return "";
   return pImage_p->units().getName();
}


void image::open(const String& inFile)
{

// Generally used if the image is already closed !b

   LogIO os(LogOrigin("image", "open(...)", id(), WHERE));

   if (pImage_p !=0 ) {
      delete pImage_p;
      os << LogIO::WARN << "Image is already open, closing first" << LogIO::POST;
   }

// Open input image.  We don't handle an Image tool because
// we would get a bit confused as to who owns the pointer

   ImageUtilities::openImage (pImage_p, inFile, os);

// Ensure that we reconstruct the statistics and histograms objects

   deleteHistAndStats();   
}


GlishRecord image::boundingBox(const GlishRecord& glishRegion)
//
// Find the bounding box of this region
//
{
   GlishRecord rec;
   if (detached()) {
      return rec;
   }
//
   LogIO os(LogOrigin("image", "boundingBox", id(), WHERE));
   const ImageRegion* pRegion = makeRegionRegion(*pImage_p, glishRegion, False, os);
   LatticeRegion latRegion = 
         pRegion->toLatticeRegion (pImage_p->coordinates(), pImage_p->shape());
//
   Slicer sl = latRegion.slicer();
   IPosition blc(sl.start()+1);                      // 1-rel for Glish
   IPosition trc(sl.end()+1);
   IPosition inc(sl.stride());
   IPosition length(sl.length());
   rec.add("blc", blc.asVector());
   rec.add("trc", trc.asVector());
   rec.add("inc", inc.asVector());
   rec.add("bbShape", (trc-blc+1).asVector());
   rec.add("regionShape", length.asVector());
   rec.add("imageShape", pImage_p->shape().asVector());
//
   CoordinateSystem cSys(pImage_p->coordinates());
   rec.add("blcf", CoordinateUtil::formatCoordinate(blc-1, cSys));   // 0-rel for use in C++
   rec.add("trcf", CoordinateUtil::formatCoordinate(trc-1, cSys));
   return rec;
}



void image::close()
{
    LogIO os(LogOrigin("image", "close()", WHERE));
    if (pImage_p != 0 ) {
       os << LogIO::NORMAL << "Detaching from image" <<  LogIO::POST;
       delete pImage_p;
    } else {
       os << LogIO::WARN << "Image is already closed" << LogIO::POST;
    }
    pImage_p = 0;
//
    deleteHistAndStats();   
}


void image::getchunk(Array<Float>& pixels, 
                     Array<Bool>& pixelMask,
                     const Vector<Index>& blc,
                     const Vector<Index>& trc,
                     const Vector<Int>& inc,
                     const Vector<Index>& axes,
                     Bool listBoundingBox,
                     Bool dropDegenerateAxes,
                     Bool getMask) const
//
// Recover some pixels from the image from a simple strided box
//
{
//
    if (detached()) return;

    IPosition iblc;
    IPosition itrc;
    IPosition imshape(shape());
  
// Verify region.
    
    Index::convertIPosition(iblc, blc);
    Index::convertIPosition(itrc, trc);
    IPosition iinc(inc.nelements());
    for (uInt i=0; i<inc.nelements(); i++) {
        iinc(i) = inc(i);
    }
    LCBox::verify(iblc, itrc, iinc, imshape);
    if (listBoundingBox) {
       LogIO os(LogOrigin("image", "getchunk", id(), WHERE));
       os << LogIO::NORMAL << "Selected bounding box "
          << iblc+1 << " to " << itrc+1 << LogIO::POST;
    }

// Get the chunk.  The mask is not returned. Leave that to getRegion

    IPosition curshape = (itrc - iblc + iinc)/iinc;
    Slicer sl(iblc, itrc, iinc, Slicer::endIsLast);
    SubImage<Float> subImage(*pImage_p, sl);
//
    IPosition iAxes;
    Index::convertIPosition(iAxes, axes);
    if (getMask) {
       LatticeUtilities::collapse (pixels, pixelMask, iAxes, subImage, dropDegenerateAxes);
    } else {
       LatticeUtilities::collapse (pixels, iAxes, subImage, dropDegenerateAxes);
    }
}


void image::getRegion (Array<Float>& data,
                       Array<Bool>& pixelMask,
                       const GlishRecord& glishRegion,
                       const Vector<Index>& axes,
                       const String& mask,
                       Bool listBoundingBox,
                       Bool dropDegenerateAxes,
                       Bool getPixels, Bool getMask)
//
// Recover some pixels and their mask from a region in the image
//
{
    if (detached()) {
       return;
    }
    LogIO os(LogOrigin("image", "getRegion", id(), WHERE));
  
// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.
    
    ImageRegion* pRegionRegion = 0;
    ImageRegion* pMaskRegion = 0;   
    SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, mask, listBoundingBox, 
                                             os, False);
    delete pRegionRegion;
    delete pMaskRegion;
    
// Get the region
       
    data.resize(IPosition(0,0));
    pixelMask.resize(IPosition(0,0));
    
// Drop degenerate axes

    IPosition iAxes;
    Index::convertIPosition(iAxes, axes);
    LatticeUtilities::collapse (data, pixelMask, iAxes, subImage, dropDegenerateAxes);
//
    return;
} 


void image::getSlice1D (Vector<Float>& xPos, Vector<Float>& yPos,
                        Vector<Float>& distance, Vector<Float>& pixels,
                        Vector<Bool>& pixelMask, 
                        const Vector<Index>& coord,
                        const Vector<Index>& axes,
                        const Vector<Double>& x, const Vector<Double>& y,
                        const String& method, Int nPts) const
{
//
    if (detached()) return;
  
// Construct PixelCurve.  FIll in defaults for x, y vectors

    PixelCurve1D curve (x-1.0, y-1.0, nPts);

// Set coordinates

    IPosition iCoord;
    Index::convertIPosition(iCoord, coord);
    IPosition iAxes;
    Index::convertIPosition(iAxes, axes);

// Get the Slice

    LatticeSlice1D<Float>::Method method2 = LatticeSlice1D<Float>::stringToMethod(method);
    LatticeSlice1D<Float> slicer(*pImage_p, method2);
    slicer.getSlice (pixels, pixelMask, curve, iAxes(0), iAxes(1), iCoord);

// Get slice locations

    uInt axis0, axis1;
    slicer.getPosition (axis0, axis1, xPos, yPos, distance);

// Make 1-rel for return

    xPos += Float(1.0);    
    yPos += Float(1.0);
}



void image::histograms(GlishRecord &histout,
                       const Vector<Index> &axes, 
                       const GlishRecord& glishRegion,
                       const String& mask,
                       Int nbins, 
 		       const Vector<Float> &includepix, 
                       Bool gauss,
 		       Bool cumu, 
                       Bool log, 
                       Bool list,
                       const String &pgdevice, 
                       Int nx, Int ny, 
                       const Vector<Int>& size,
                       Bool forceNewStorageImage,
                       Bool forceStorageOnDisk)
{
    if (detached()) return;

    LogOrigin lor("image", "histograms", id(), WHERE);
    LogIO os(lor);

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.    

    ImageRegion* pRegionRegion = 0;
    ImageRegion* pMaskRegion = 0;
    SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, mask, True, os, False);

// Make new object only if we need to.  

    Bool forceNewStorage = forceNewStorageImage;
    if (pHistograms_p != 0) {
       if (oldHistStorageForce_p!=forceStorageOnDisk) forceNewStorage = True;
    }
    if (forceNewStorage) {
       delete pHistograms_p; pHistograms_p = 0;
       delete pOldHistRegionRegion_p;  pOldHistRegionRegion_p = 0;
       delete pOldHistMaskRegion_p;  pOldHistMaskRegion_p = 0;
//
       pHistograms_p = new ImageHistograms<Float>(subImage, os, True,
                                                  forceStorageOnDisk);
    } else {    
       if (pHistograms_p == 0) {
    
// We are here if this is the first time or the image has
// changed           
 
          pHistograms_p = new ImageHistograms<Float>(subImage, os, True,
                                                     forceStorageOnDisk);
       } else {
     
// We already have a histogram object.  We only have to set
// the new image (which will force the accumulation image
// to be recomputed) if the region has changed.  If the image itself
// changed, pHistograms_p will already have been set to 0

          pHistograms_p->resetError();
          if (haveRegionsChanged (pRegionRegion, pMaskRegion, 
                                  pOldHistRegionRegion_p, pOldHistMaskRegion_p)) {
             pHistograms_p->setNewImage(subImage);
          }
       }
    }

// Assign old regions to current regions

    delete pOldHistRegionRegion_p; pOldHistRegionRegion_p = 0;
    delete pOldHistMaskRegion_p; pOldHistMaskRegion_p = 0;
//
    pOldHistRegionRegion_p = pRegionRegion;
    pOldHistMaskRegion_p = pMaskRegion;
    oldHistStorageForce_p = forceStorageOnDisk;

// Set cursor axes

    Vector<Int> tmpaxes(axes.nelements());
    Index::convertVector(tmpaxes, axes);
    if (!pHistograms_p->setAxes(tmpaxes)) {
       os << pHistograms_p->errorMessage() << LogIO::EXCEPTION;
    }

// Set number of bins

    if (!pHistograms_p->setNBins(nbins)) {
       os << pHistograms_p->errorMessage() << LogIO::EXCEPTION;
    }


// Set pixel include ranges

    Vector<Float> tmpinclude(includepix.copy());
    if (!pHistograms_p->setIncludeRange(tmpinclude)) {
       os << pHistograms_p->errorMessage() << LogIO::EXCEPTION;
    }


// Plot the gaussian ?

    if (!pHistograms_p->setGaussian(gauss)) {
       os << pHistograms_p->errorMessage() << LogIO::EXCEPTION;
    }

// Set form of histogram

    if (!pHistograms_p->setForm(log, cumu)) {
       os << pHistograms_p->errorMessage() << LogIO::EXCEPTION;
    }

// List statistics as well ?

    if (!pHistograms_p->setStatsList(list)) {
       os << pHistograms_p->errorMessage() << LogIO::EXCEPTION;
    }
    
// Make plots

    PGPlotter plotter;
    if (!pgdevice.empty()) {
//	try {
	    plotter = PGPlotter(pgdevice, 2, 100, size(0), size(1));
//	} catch (AipsError x) {
//	    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
//	    return False;
//	} 
	Vector<Int> nxy(2); nxy(0) = nx; nxy(1) = ny;
	if (nx < 0 || ny < 0) {
	    nxy.resize(0);
	}
	if (!pHistograms_p->setPlotting(plotter, nxy)) {
          os << pHistograms_p->errorMessage() << LogIO::EXCEPTION;
        }
    }

    if (plotter.isAttached()) {
       if (!pHistograms_p->display()) {
          os << pHistograms_p->errorMessage() << LogIO::EXCEPTION;
       }
       pHistograms_p->closePlotting();
    }

// If OK recover the histogram into the Glish record

    Array<Float> values, counts;
    if (!pHistograms_p->getHistograms (values, counts)) {
       os << pHistograms_p->errorMessage() << LogIO::EXCEPTION;
    }
//
    GlishRecord retval;
    retval.add("values", values);
    retval.add("counts", counts);
    histout = retval;

//  Cleanup
 
    return;
}


String image::name(const Bool stripPath) const
{
    if (detached()) {
        return "none";
    }
    return pImage_p->name(stripPath);
}


void image::pixelValue (Bool& offImage, Quantum<Double>& value, Bool& mask, 
                        Vector<Index>& pos) const
{
    if (detached()) {
        return;
    }
//
    IPosition iPos;
    Index::convertIPosition(iPos, pos);
//
    const IPosition imShape = pImage_p->shape();
    const Vector<Double> refPix = pImage_p->coordinates().referencePixel();
    const uInt nDim = pImage_p->ndim();
    const uInt nPix = iPos.nelements();
    iPos.resize(nDim,True);

// Discard extra pixels, add ref pixel for missing ones

    offImage = False;
    for (uInt i=0; i<nDim; i++) {
       if ((i+1)>nPix) {
          iPos(i) = Int(refPix(i)+0.5);
       } else {
          if (iPos(i) < 0 || iPos(i)>(imShape(i)-1)) offImage = True;
       }
    }
    if (offImage) return;
//
    IPosition shp(pImage_p->ndim(),1);
    Array<Float> pixels = pImage_p->getSlice(iPos, shp);
    Array<Bool> maskPixels = pImage_p->getMaskSlice(iPos, shp);
    Unit units = pImage_p->units();
//
    Index::convertIPosition (pos, iPos);
    value = Quantum<Double>(Double(pixels(shp-1)), units);
    mask = maskPixels(shp-1);
}



void image::putchunk(const Array<Float> &pixels,
                     const Vector<Index> &blc,
                     const Vector<Int> &inc,
                     Bool listBoundingBox,
                     Bool replicateArray)
{   
    if (detached()) {
        return;
    } 
    LogIO os(LogOrigin("image", "putchunk", id(), WHERE));
//
    IPosition imageShape = shape();
    uInt ndim = imageShape.nelements();
    if (pixels.ndim() > ndim) {
        os << "Pixels array has more axes than the image!" << LogIO::EXCEPTION;
    }
                       
// Verify blc value. Fill in values for blc and inc.  trc set to shape-1

    IPosition iblc;
    Index::convertIPosition(iblc, blc);
    IPosition itrc;
    IPosition iinc(inc.nelements());
    for (uInt i=0; i<inc.nelements(); i++) iinc(i) = inc(i);                    
    LCBox::verify(iblc, itrc, iinc, imageShape);

// Create two slicers; one describing the region defined by blc + shape-1
// with extra axes given length 1. The other we extend with the shape

    IPosition len = pixels.shape();
    len.resize(ndim, True);
    for (uInt i=pixels.shape().nelements(); i<ndim; i++) {
       len(i) = 1;
       itrc(i) = imageShape(i) - 1;
    }
    Slicer sl(iblc, len, iinc, Slicer::endIsLength);
    if (sl.end()+1 > imageShape) {
         os << "Pixels array, including inc, extends beyond edge of image."
            << LogIO::EXCEPTION;
    } 
    Slicer sl2(iblc, itrc, iinc, Slicer::endIsLast);
//
    if (listBoundingBox) {
       os << LogIO::NORMAL << "Selected bounding box "
          << sl.start()+1 << " to " << sl.end()+1 << LogIO::POST;
    }
   
// Put the pixels

    if (pixels.ndim() == ndim) {
       set_cache(pixels.shape());
       if (replicateArray) {
          LatticeUtilities::replicate (*pImage_p, sl2, pixels);
       } else {
          pImage_p->putSlice(pixels, iblc, iinc);
       }
    } else {
    
// Pad with extra degenerate axes if necessary (since it is somewhat
// costly).
       
        Array<Float> pixelsref(pixels.addDegenerate(ndim - pixels.ndim()));
        set_cache(pixelsref.shape());
        if (replicateArray) {
           LatticeUtilities::replicate (*pImage_p, sl2, pixelsref);
        } else {
           pImage_p->putSlice(pixelsref, iblc, iinc);
        }
    }
    
// Ensure that we reconstruct the statistics and histograms objects
// now that the data have changed
    
   deleteHistAndStats();
}




void image::putRegion (const Array<Float>& pixels, const Array<Bool>& mask,
                       const GlishRecord& glishRegion, Bool list,
                       Bool useMask, Bool replicateArray)
{
    if (detached()) {
        return;
    }
    LogIO os(LogOrigin("image",  "putRegion", id(), WHERE));
        
// Verify array dimension
    
    uInt ndim = shape().nelements();
    if (pixels.ndim() > ndim) {
       os << "Pixels array has more axes than the image" << LogIO::EXCEPTION;
    }
    if (mask.ndim() > ndim) {
       os << "Mask array has more axes than the image" << LogIO::EXCEPTION;  
    }
//
// Warning, an empty Array comes through the tasking system
// as shape = [0], ndim = 1, nelements = 0
//
    IPosition dataShape;
    uInt dataDim = 0;
    uInt pixelElements = pixels.nelements();
    uInt maskElements = mask.nelements();
// 
    if (pixelElements!=0 && maskElements!=0) {
       if (!pixels.shape().isEqual(mask.shape())) {
          os << "Pixels and mask arrays have different shapes"
             << LogIO::EXCEPTION;
       }
       if (pixelElements!=0) {
          dataShape = pixels.shape();
          dataDim = pixels.ndim();  
       } else {
          dataShape = mask.shape();
          dataDim = mask.ndim();
       }
    } else if (pixelElements!=0) {
       dataShape = pixels.shape();
       dataDim = pixels.ndim();
    } else if (maskElements!=0) {
       dataShape = mask.shape();
       dataDim = mask.ndim();
    } else {
       os << "Pixels and mask arrays are both zero length"
          << LogIO::EXCEPTION; 
    }

// Make region.  If the region extends beyond the image, it is truncated here.
       
    const ImageRegion* pRegion = makeRegionRegion(*pImage_p, glishRegion, list, os);
    LatticeRegion latRegion =
          pRegion->toLatticeRegion (pImage_p->coordinates(), pImage_p->shape());

// The pixels array must be same shape as the bounding box of the region for as
// many axes as there are in the pixels array.  We pad with degenerate axes for
// missing axes. If the region dangled over the edge,  it will have  been
// truncated and  the array will no longer be the correct shape and we get an error.
// We could go to the trouble of fishing out the bit that doesn't fall off the edge.

   for (uInt i=0; i<dataDim; i++) {
      if (dataShape(i) != latRegion.shape()(i)) {
        if ( !(i==dataDim-1 && dataShape(i)==1)) {
          ostringstream oss;
          oss << "Data array shape (" << dataShape << ") including inc, does not"
              << " match the shape of the region bounding box ("
              << latRegion.shape() << ")" << endl;
          os << String(oss) << LogIO::EXCEPTION;
        }
      }
   }
          
// If our image doesn't have a mask, try and make it one.
        
   if (maskElements > 0) {
      if (!pImage_p->hasPixelMask()) {
         String maskName("");  
         makeMask(*pImage_p, maskName, True, True, os, list);
      }
   }
   Bool useMask2 = useMask;
   if (!pImage_p->isMasked()) useMask2 = False;
          
// Put the mask first
     
    if (maskElements>0 && pImage_p->hasPixelMask()) {
       Lattice<Bool>& maskOut = pImage_p->pixelMask();
       if (maskOut.isWritable()) {
          if (dataDim == ndim) {
            if (replicateArray) {
               LatticeUtilities::replicate (maskOut, latRegion.slicer(), mask);
            } else {
               maskOut.putSlice(mask, latRegion.slicer().start());
            }
          } else {
            os << LogIO::NORMAL << "Padding mask array with degenerate axes" << LogIO::POST;
            Array<Bool> maskref(mask.addDegenerate(ndim - mask.ndim()));
            if (replicateArray) {
               LatticeUtilities::replicate (maskOut, latRegion.slicer(), maskref);
            } else {            
               maskOut.putSlice(maskref, latRegion.slicer().start());
            }
          }
       } else {
          os << "The mask is not writable. Probably an ImageExpr or SubImage" << LogIO::EXCEPTION;
       }
    }

// Get the mask and data from disk if we need it
             
   IPosition pixelsShape = pixels.shape();
   Array<Bool> oldMask;
   Array<Float> oldData;
   Bool deleteOldMask, deleteOldData, deleteNewData;
   const Bool* pOldMask = 0;
   const Float* pOldData = 0;
   const Float* pNewData = 0;
   if (pixelElements>0 && useMask2) {
      if (pixels.ndim()!=ndim) {
         pixelsShape.append(IPosition(ndim-pixels.ndim(),1));
      }
    
      oldData = pImage_p->getSlice(latRegion.slicer().start(), pixelsShape, False);
      oldMask = pImage_p->getMaskSlice(latRegion.slicer().start(), pixelsShape, False);
//
      pOldData = oldData.getStorage(deleteOldData);     // From disk
      pOldMask = oldMask.getStorage(deleteOldMask);     // From disk
//
      pNewData = pixels.getStorage(deleteNewData);      // From user
   }

// Put the pixels
        
    if (dataDim == ndim) {
       if (pixelElements>0) {
          if (useMask2) {
             Bool deleteNewData2;
             Array<Float> pixels2(pixelsShape);
             Float* pNewData2 = pixels2.getStorage(deleteNewData2);
             for (uInt i=0; i<pixels2.nelements(); i++) {
                pNewData2[i] = pNewData[i];                    // Value user gives
                if (!pOldMask[i]) pNewData2[i] = pOldData[i];  // Value on disk
             }
             pixels2.putStorage(pNewData2, deleteNewData2);
             if (replicateArray) {
               LatticeUtilities::replicate (*pImage_p, latRegion.slicer(), pixels2);
             } else {
                pImage_p->putSlice(pixels2, latRegion.slicer().start());
             }
          } else {
             if (replicateArray) {
               LatticeUtilities::replicate (*pImage_p, latRegion.slicer(), pixels);
             } else {
                pImage_p->putSlice(pixels, latRegion.slicer().start());
             }
          }
       }
    } else {
       if (pixelElements>0) {
          os << LogIO::NORMAL << "Padding pixels array with degenerate axes" << LogIO::POST;
//
          if (useMask2) {
             Bool deleteNewData2;
             Array<Float> pixels2(pixelsShape);
             Float* pNewData2 = pixels2.getStorage(deleteNewData2);
             for (uInt i=0; i<pixels2.nelements(); i++) {
                pNewData2[i] = pNewData[i];                    // Value user gives
                if (!pOldMask[i]) pNewData2[i] = pOldData[i];  // Value on disk
             }
             pixels2.putStorage(pNewData2, deleteNewData2);
             if (replicateArray) {
               LatticeUtilities::replicate (*pImage_p, latRegion.slicer(), pixels2);
             } else {
                pImage_p->putSlice(pixels2, latRegion.slicer().start());
             }
          } else {
             Array<Float> pixelsref(pixels.addDegenerate(ndim - pixels.ndim()));
             if (replicateArray) {
               LatticeUtilities::replicate (*pImage_p, latRegion.slicer(),  pixelsref);
             } else {
                pImage_p->putSlice(pixelsref, latRegion.slicer().start());
             }
          }
       }  
    }
//
    if (pOldMask!=0) oldMask.freeStorage(pOldMask, deleteOldMask);
    if (pOldData!=0) oldData.freeStorage(pOldData, deleteOldData);
    if (pNewData!=0) pixels.freeStorage(pNewData, deleteNewData);
    delete pRegion;
                                             
// Ensure that we reconstruct the statistics and histograms objects
// now that the data have changed
   
   deleteHistAndStats();
}


void image::setBrightnessUnit (const String& unit)
{
   if (detached()) return;
   if (!pImage_p->setUnits(Unit(unit))) {
      LogIO os(LogOrigin("image", "setBrightnessUnit", id(), WHERE));
      os << "Unable to set brightness units" << LogIO::EXCEPTION;
   }
}



Vector<Int> image::shape() const
{
    if (detached()) {
	Vector<Int> dummy;
	return dummy;
    }
    return pImage_p->shape().asVector();
}



void image::statistics(GlishRecord &statsout,
		       const Vector<Index> &axes,
                       const GlishRecord& glishRegion,
                       const String& mask,
		       const Vector<String> &plotstats, 
		       const Vector<Float> &includepix,
		       const Vector<Float> &excludepix,
		       Bool list, const String &pgdevice, 
                       Int nx, Int ny, 
                       Bool forceNewStorageImage,
                       Bool forceStorageOnDisk, Bool robust,
                       Bool verbose)

{
    if (detached()) return;

    LogOrigin lor("image", "statistics", id(), WHERE);
    LogIO os(lor);

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.    

    ImageRegion* pRegionRegion = 0;
    ImageRegion* pMaskRegion = 0;
    SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                             glishRegion, mask, verbose, os, False);

// Find BLC of subimage

    IPosition blc(subImage.ndim(),0);
    IPosition trc(subImage.shape()-1);
    if (pRegionRegion!=0) {
       LatticeRegion latRegion = 
            pRegionRegion->toLatticeRegion (pImage_p->coordinates(), pImage_p->shape());
       Slicer sl = latRegion.slicer();
       blc = sl.start();
       trc = sl.end();
    }

// Make new statistics object only if we need to.    This code is getting
// a bit silly. I should rework it somewhen.

    Bool forceNewStorage = forceNewStorageImage;
    if (pStatistics_p != 0) {
       if (forceStorageOnDisk!=oldStatsStorageForce_p) forceNewStorage = True;
    }
//
    if (forceNewStorage) {
        delete pStatistics_p; pStatistics_p = 0;
        if (verbose) {
           pStatistics_p = new ImageStatistics<Float>(subImage, os, True, 
                                                      forceStorageOnDisk);
        } else {
           pStatistics_p = new ImageStatistics<Float>(subImage, True, 
                                                      forceStorageOnDisk);
        }
    } else {
       if (pStatistics_p == 0) {

// We are here if this is the first time or the image has
// changed (pStatistics_p is deleted then)

          if (verbose) {
             pStatistics_p = new ImageStatistics<Float>(subImage, os, True,
                                                        forceStorageOnDisk);
          } else {
             pStatistics_p = new ImageStatistics<Float>(subImage, True,
                                                        forceStorageOnDisk);
          }
       } else {

// We already have a statistics object.  We only have to set
// the new image (which will force the accumulation image
// to be recomputed) if the region has changed.  If the image itself
// changed, pStatistics_p will already have been set to 0

          Bool reMake = (verbose  && !pStatistics_p->hasLogger()) ||
                        (!verbose &&  pStatistics_p->hasLogger());
          if (reMake) {
             delete pStatistics_p; pStatistics_p = 0;
             if (verbose) {
                pStatistics_p = new ImageStatistics<Float>(subImage, os, True,
                                                           forceStorageOnDisk);
             } else {
                pStatistics_p = new ImageStatistics<Float>(subImage, True,
                                                           forceStorageOnDisk);
             }
          } else {
             pStatistics_p->resetError();
             if (haveRegionsChanged (pRegionRegion, pMaskRegion, 
                                     pOldStatsRegionRegion_p, pOldStatsMaskRegion_p)) {
                pStatistics_p->setNewImage(subImage);  
             }
          }
       }
    }

// Assign old regions to current regions

    delete pOldStatsRegionRegion_p; pOldStatsRegionRegion_p = 0;
    delete pOldStatsMaskRegion_p; pOldStatsMaskRegion_p = 0;
//
    pOldStatsRegionRegion_p = pRegionRegion;
    pOldStatsMaskRegion_p = pMaskRegion;
    oldStatsStorageForce_p = forceStorageOnDisk;

// Set cursor axes

    Vector<Int> tmpaxes;
    Index::convertVector(tmpaxes, axes);
    if (!pStatistics_p->setAxes(tmpaxes)) {
       os << pStatistics_p->errorMessage() << LogIO::EXCEPTION;
    }

// Set pixel include/exclude ranges

    Vector<Float> tmpinclude(includepix.copy());
    Vector<Float> tmpexclude(excludepix.copy());
    if (!pStatistics_p->setInExCludeRange(tmpinclude, tmpexclude, False)) {
       os << pStatistics_p->errorMessage() << LogIO::EXCEPTION;
    }


// Tell what to list

    if (!pStatistics_p->setList(list)) {
       os << pStatistics_p->errorMessage() << LogIO::EXCEPTION;
    }

// What to plot

   Vector<Int> statsToPlot = LatticeStatsBase::toStatisticTypes(plotstats);

// Recover statistics

    Array<Double> npts, sum, sumsquared, min, max, mean, sigma;
    Array<Double> rms, fluxDensity, med, medAbsDevMed, quartile;
    Bool ok = True;
//
    if (!robust) {
      for (uInt i=0; i<statsToPlot.nelements(); i++) {
         if (statsToPlot(i)==Int(LatticeStatsBase::MEDIAN) ||
             statsToPlot(i)==Int(LatticeStatsBase::MEDABSDEVMED) ||
             statsToPlot(i)==Int(LatticeStatsBase::QUARTILE)) {
            robust = True;
         }
      }
    }
    if (robust) {
       ok = pStatistics_p->getStatistic(med, LatticeStatsBase::MEDIAN) &&
            pStatistics_p->getStatistic(medAbsDevMed, LatticeStatsBase::MEDABSDEVMED) &&
            pStatistics_p->getStatistic(quartile, LatticeStatsBase::QUARTILE);
    }
    if (ok) {
      ok =  pStatistics_p->getStatistic(npts, LatticeStatsBase::NPTS) &&
            pStatistics_p->getStatistic(sum, LatticeStatsBase::SUM) && 
            pStatistics_p->getStatistic(sumsquared, LatticeStatsBase::SUMSQ) && 
            pStatistics_p->getStatistic(min, LatticeStatsBase::MIN) &&
            pStatistics_p->getStatistic(max, LatticeStatsBase::MAX) && 
            pStatistics_p->getStatistic(mean, LatticeStatsBase::MEAN) &&
            pStatistics_p->getStatistic(sigma, LatticeStatsBase::SIGMA) && 
            pStatistics_p->getStatistic(rms, LatticeStatsBase::RMS);
    }
    if (!ok) {
       os << pStatistics_p->errorMessage() << LogIO::EXCEPTION;
    }
    Bool ok2 = pStatistics_p->getStatistic(fluxDensity, LatticeStatsBase::FLUX);
//
    GlishRecord retval;
    retval.add("npts", npts);
    retval.add("sum", sum);
    retval.add("sumsq", sumsquared);
    retval.add("min", min);
    retval.add("max", max);
    retval.add("mean", mean);
    if (robust) {
       retval.add("median", med);
       retval.add("medabsdevmed", medAbsDevMed);
       retval.add("quartile", quartile);
    }
    retval.add("sigma", sigma);
    retval.add("rms", rms);
    if (ok2) retval.add("flux", fluxDensity);
//
    String tmp;
    CoordinateSystem cSys = pImage_p->coordinates();
    retval.add("blc", blc.asVector()+1);
    tmp = CoordinateUtil::formatCoordinate(blc, cSys);
    retval.add("blcf", tmp);
//
    retval.add("trc", trc.asVector()+1);
    tmp = CoordinateUtil::formatCoordinate(trc, cSys);
    retval.add("trcf", tmp);
//
    IPosition minPos, maxPos;
    if (pStatistics_p->getMinMaxPos(minPos, maxPos)) {
       if (minPos.nelements()>0 && maxPos.nelements()>0) {
          retval.add("minpos", (blc+minPos).asVector()+1);
          tmp = CoordinateUtil::formatCoordinate(blc+minPos, cSys);
          retval.add("minposf", tmp);
//
          retval.add("maxpos", (blc+maxPos).asVector()+1);
          tmp = CoordinateUtil::formatCoordinate(blc+maxPos, cSys);
          retval.add("maxposf", tmp);
       }
    }
    statsout = retval;

// Make plots

    PGPlotter plotter;
    Vector<Int> nxy(2); 
    if (!pgdevice.empty()) {
//	try {
	    plotter = PGPlotter(pgdevice);
//	} catch (AipsError x) {
//	    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
//	    return False;
//	} 
	nxy(0) = nx; nxy(1) = ny;
	if (nx < 0 || ny < 0) {
	    nxy.resize(0);
	}

	if (!pStatistics_p->setPlotting(plotter, statsToPlot, nxy)) {
          os << pStatistics_p->errorMessage() << LogIO::EXCEPTION;
        }
    }

    if (list || !pgdevice.empty()) {
       if (!pStatistics_p->display()) {
          os << pStatistics_p->errorMessage() << LogIO::EXCEPTION;
       }
    }
    pStatistics_p->closePlotting();
//
    return;
}


ObjectID image::twoPointCorrelation (const String& outFile,
                                     const GlishRecord& glishRegion,
                                     const String& mask,
                                     const Vector<Index>& pixelAxes,
                                     const String& method,
                                     Bool overwrite)
{
   if (detached()) {
      return ObjectID(True);
   }
//
   LogIO os(LogOrigin("image", "twoPointCorrelation", id(), WHERE));

// Validate outfile

    if (!overwrite && !outFile.empty()) {
       NewFile validfile;
       String errmsg;
       if (!validfile.valueOK(outFile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
       }
   }

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.

   AxesSpecifier axesSpecifier;
   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                            glishRegion, mask, True, os, False, 
                                            axesSpecifier);
   delete pRegionRegion;
   delete pMaskRegion;

// Deal with axes and shape

   Vector<Int> axes2;
   Index::convertVector(axes2, pixelAxes);
//
   CoordinateSystem cSysIn = subImage.coordinates();
   IPosition axes = ImageTwoPtCorr<Float>::setUpAxes (IPosition(axes2), cSysIn);
   IPosition shapeOut = ImageTwoPtCorr<Float>::setUpShape (subImage.shape(), axes);

// Create the output image and mask

   PtrHolder<ImageInterface<Float> > imOut;
   if (outFile.empty()) {
      os << LogIO::NORMAL << "Creating (temp)image of shape " << shapeOut << LogIO::POST;
      imOut.set(new TempImage<Float>(shapeOut, cSysIn));
   } else {
      os << LogIO::NORMAL << "Creating image '" << outFile << "' of shape " << shapeOut << LogIO::POST;
      imOut.set(new PagedImage<Float>(shapeOut, cSysIn, outFile));
   }
   ImageInterface<Float>* pImOut = imOut.ptr();
   String maskName("");
   makeMask(*pImOut, maskName, True, True, os, True);

// Do the work.  The Miscellaneous items and units are dealt with
// by function ImageTwoPtCorr::autoCorrelation

   ImageTwoPtCorr<Float> twoPt;
   Bool showProgress = True;
   LatticeTwoPtCorr<Float>::Method m = LatticeTwoPtCorr<Float>::fromString(method);
   twoPt.autoCorrelation (*pImOut, subImage, axes, m, showProgress);

// Return ID

   ObjectController *controller = ApplicationEnvironment::objectController();
   ApplicationObject *subobject = 0;
   if (controller) {
      subobject = new image(*pImOut);
      AlwaysAssert(subobject, AipsError);
      return controller->addObject(subobject);
   } else {
      return ObjectID(True); // null
   }
}



ObjectID image::subimage(const String& outfile,
                         const GlishRecord& glishRegion,
                         const String& mask,
                         Bool dropDegenerateAxes, Bool overwrite,
                         Bool list)
//
// Copy a portion of the image
//
{
    if (detached()) {
	return ObjectID(True);
    }

    LogOrigin lor("image", "subimage", id(), WHERE);
    LogIO os(lor);

// Verify output file

   if (!overwrite && !outfile.empty()) {
      NewFile validfile;
      String errmsg;
      if (!validfile.valueOK(outfile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
   }

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.    

   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   AxesSpecifier axesSpecifier;
   if (dropDegenerateAxes) axesSpecifier = AxesSpecifier(False);
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                            glishRegion, mask, list, os, True, axesSpecifier);
   delete pRegionRegion;
   delete pMaskRegion;
//
   ObjectController *controller = ApplicationEnvironment::objectController();
   ApplicationObject *subobject = 0;
//
   if (outfile.empty()) {
      if (controller) {

// We have a controller, so we can return a valid object id after we
// register the new object

   	subobject = new image(subImage);
	AlwaysAssert(subobject, AipsError);
	return controller->addObject(subobject);
      } else {
        return ObjectID(True); // null
      }
   } else {

// Make the output image

      if (list) {
         os << LogIO::NORMAL << "Creating image '" << outfile << "' of shape " 
            << subImage.shape() << LogIO::POST;
      }
      PagedImage<Float> outImage(subImage.shape(), 
                                 subImage.coordinates(), outfile);
      ImageUtilities::copyMiscellaneous(outImage, *pImage_p);

// Make output mask if required
    
      if (subImage.isMasked()) {
         String maskName("");
         makeMask(outImage, maskName, False, True, os, list);
      }

// Copy data and mask

      LatticeUtilities::copyDataAndMask(os, outImage, subImage);

// Return handle

      if (controller) {

// We have a controller, so we can return a valid object id after we
// register the new object

        subobject = new image(outImage);
	AlwaysAssert(subobject, AipsError);
	return controller->addObject(subobject);
      } else {
	return ObjectID(True); // null
      }
   }
}


Vector<String> image::summary(GlishRecord& header, 
                              const String& velocityType,
                              Bool list, Bool pixelOrder) const
{
    Vector<String> messages;
    if (detached()) {
	return messages;
    }
    GlishRecord retval;
    ImageSummary<Float> s(*pImage_p);
//
    MDoppler::Types velType;
    LogOrigin lor("image", "summary", id(), WHERE);
    LogIO os(lor);
    if (!MDoppler::getType(velType, velocityType)) {
       os << LogIO::WARN << "Illegal velocity type, using RADIO" << LogIO::POST;
       velType = MDoppler::RADIO;       
    }
//
    if (list) {
       messages = s.list(os, velType, False);
    } else {

// Write messages to local sink only so we can fish them out again

       LogFilter filter;
       LogSink sink(filter, False);
       LogIO osl(sink);
       messages = s.list(osl, velType, True);
    }
//
    Vector<String> axes      = s.axisNames(pixelOrder);
    Vector<Double> crpix     = s.referencePixels(True); // 1-rel
    Vector<Double> crval     = s.referenceValues(pixelOrder);
    Vector<Double> cdelt     = s.axisIncrements(pixelOrder);
    Vector<String> axisunits = s.axisUnits(pixelOrder);
//
    retval.add("ndim", Int(s.ndim()));
    retval.add("shape", s.shape().asVector());
    retval.add("tileshape", s.tileShape().asVector());
    retval.add("axisnames", axes);
    retval.add("refpix", crpix);
    retval.add("refval", crval);
    retval.add("incr", cdelt);
    retval.add("axisunits", axisunits);
    retval.add("unit", s.units().getName());
    retval.add("hasmask", s.hasAMask());
    retval.add("defaultmask", s.defaultMaskName());
    retval.add("masks", s.maskNames());
    retval.add("imagetype", s.imageType());
//
    ImageInfo info = pImage_p->imageInfo();
    Record iRec;
    String error;
    if (!info.toRecord(error, iRec)) {
       os << LogIO::SEVERE << "Failed to convert ImageInfo to a record because " << LogIO::EXCEPTION;
       os << LogIO::SEVERE << error  << LogIO::POST;
    } else {
       GlishRecord gRec;
       if (iRec.isDefined("restoringbeam")) {
          gRec.fromRecord(iRec.asRecord("restoringbeam"));
          retval.add("restoringbeam", gRec);
       }
    }
    header = retval;
//
    return messages;

}




ObjectID image::coordSys(const Vector<Index>& pixelAxes) const
{
  if (detached()) {
     return ObjectID(True); // null
  }

// Recover CoordinateSytem into a Record

  Record rec;
  CoordinateSystem cSys = pImage_p->coordinates();
  CoordinateSystem cSys2;
  LogIO os(LogOrigin("image", "coordSys", id(), WHERE));

// Fish out the coordinate of the desired axes

  uInt j = 0;
  if (pixelAxes.nelements()>0) {
     Vector<Int> axes;
     Index::convertVector(axes, pixelAxes);
//
     const Int nPixelAxes = cSys.nPixelAxes();
     Vector<uInt> coordinates(cSys.nCoordinates(), uInt(0));
     Int coord, axisInCoord;
     for (uInt i=0; i<axes.nelements(); i++) {
        if (axes(i)>=0 && axes(i)<nPixelAxes) {
          cSys.findPixelAxis(coord, axisInCoord, uInt(axes(i)));
          if (coord!=-1) {
             coordinates(coord)++;

// Copy desired coordinate (once)

             if (coordinates(coord)==1) cSys2.addCoordinate(cSys.coordinate(coord));
          } else {

// Axis removed.  Better give up.

             os << "Pixel axis " << axes(i)+1 << " has been removed" << LogIO::EXCEPTION;
          }
        } else {
           os << "Specified pixel axis " << axes(i)+1 << " is not a valid pixel axis" << LogIO::EXCEPTION;
        }
     }
// 
// Find mapping.  Says where world axis i in cSys is in cSys2
//
     Vector<Int> worldAxisMap, worldAxisTranspose;
     Vector<Bool> refChange;
     if (!cSys2.worldMap(worldAxisMap, worldAxisTranspose, refChange, cSys)) {
       os << "Error finding world map because " << cSys2.errorMessage() << LogIO::EXCEPTION;
     }
//  
// Generate list of world axes to keep
//
     Vector<Int> keepList(cSys.nWorldAxes());
     Vector<Double> worldReplace;
     j = 0;
//
     for (uInt i=0; i<axes.nelements(); i++) {
        if (axes(i)>=0 && axes(i)<nPixelAxes) {
          Int worldAxis = cSys.pixelAxisToWorldAxis(uInt(axes(i)));
          if (worldAxis>=0) {
             keepList(j++) = worldAxisMap(worldAxis);
          } else {
             os << "World axis corresponding to pixel axis " << axes(i)+1 << " has been removed" << LogIO::EXCEPTION;
          }
        }
     }       

// Remove unwanted world (and pixel) axes.  Better would be to just
// remove the pixel axes and leave the world axes there...

     if (j>0) {
        keepList.resize(j,True);
        CoordinateUtil::removeAxes(cSys2, worldReplace, keepList, False); 
     }

// Copy the ObsInfo

     cSys2.setObsInfo(cSys.obsInfo());
  } else {   
     cSys2 = cSys;
  }

// Return ID

    ObjectController *controller = ApplicationEnvironment::objectController();
    ApplicationObject *subobject = 0;
    if (controller) {
                          
// We have a controller, so we can return a valid object id after we
// register the new object
   
       subobject = new coordsys(cSys2);
       AlwaysAssert(subobject, AipsError);
       return controller->addObject(subobject);
    } else {
       return ObjectID(True); // null
    }
}


Vector<String> image::history(Bool list) const
{
   LogIO os(LogOrigin("image", "history", WHERE));
//
   Vector<String> t;
   LoggerHolder& logger = pImage_p->logger();
//
   uInt i = 1;
   for (LoggerHolder::const_iterator iter = logger.begin(); iter != logger.end(); iter++,i++) {
      if (list) {
         os << iter->message() << endl;
      } else {
         if (i > t.nelements()) {
            t.resize(t.nelements()+100, True);
         }     
         t(i-1) = iter->message();
      }
   }
   if (list) os.post();
//
   if (!list) {
     t.resize(i-1, True);
   }
   return t;
}

void image::setHistory (const Vector<String>& history)
{
    if (detached()) return;
    LogOrigin lor(String("DOimage"), String("setHistory"));
//
    LoggerHolder& log = pImage_p->logger();
    LogSink& sink = log.sink();
    for (uInt i=0; i<history.nelements(); i++) {
       LogMessage msg(history(i), lor);
       sink.postLocally(msg);
    }
}




void image::insertImage(const String& inFile,
                        const GlishRecord& glishRegion,
                        const Vector<Double>& locatePixel, 
                        Bool doRef, Int dbg)
{
   if (detached()) return;
//
   LogIO os(LogOrigin("image", "insertImage", id(), WHERE));

// Open input image

   ImageInterface<Float>* pInImage = 0;
   Bool deleteIt;
   getPointer (pInImage, deleteIt, inFile, os);

// Create region and subImage for input image

   const ImageRegion* pRegion = makeRegionRegion(*pInImage, glishRegion, False, os);
   SubImage<Float> inSub(*pInImage, *pRegion);
   delete pRegion;

// Generate output pixel location

   const IPosition inShape = inSub.shape();
   const IPosition outShape = pImage_p->shape();
   const uInt nDim = pImage_p->ndim();  
   Vector<Double> outPix(nDim);
   const uInt nDim2 = locatePixel.nelements();
//
   if (doRef) {
      outPix.resize(0);
   } else {
      for (uInt i=0; i<nDim; i++) {
         if (i<nDim2) {
            outPix[i] = locatePixel[i] - 1.0;              // 1 -> 0 rel
         } else {
            outPix[i] = (outShape(i) - inShape(i)) / 2.0;  // Centrally located
         }
      }
   }

// Insert

   ImageRegrid<Float> ir;
   ir.showDebugInfo(dbg);
   ir.insert(*pImage_p, outPix, inSub);
//
   if (deleteIt) delete pInImage;
}

Bool image::isPersistent() const
{
    if (detached()) {
	return False;
    }
    return pImage_p->isPersistent();
}

GlishRecord image::miscinfo() const
{
    if (detached()) {
	GlishRecord dummy;
	return dummy;
    }
    GlishRecord tmp;
    tmp.fromRecord(pImage_p->miscInfo());
    return tmp;
}


Bool image::setmiscinfo(const GlishRecord &newinfo)
{
    if (detached()) {
	return False;
    }
//
    Record tmp;
    newinfo.toRecord(tmp);
    return pImage_p->setMiscInfo(tmp);
}

void image::setCoordinateSystem (const GlishRecord& coordinates)
{
   if (detached()) {
      return;
   }
//
   LogIO os(LogOrigin("image", "setCoordinateSystem", id(), WHERE));
   if (coordinates.nelements()==0) {
      os << "CoordinateSystem is empty" << LogIO::EXCEPTION;
   }
   PtrHolder<CoordinateSystem> cSys(makeCoordinateSystem(coordinates, pImage_p->shape()));
   Bool ok = pImage_p->setCoordinateInfo(*(cSys.ptr()));
   if (!ok) {
      os << "Failed to set CoordinateSystem" << LogIO::EXCEPTION;
   }
}



Bool image::lock (Bool readLock, Int nattempts)
{
   if (detached()) return False;
   FileLocker::LockType locker = FileLocker::Read;
   if (!readLock) locker = FileLocker::Write;
   uInt n = max(0,nattempts);
   return pImage_p->lock(locker, n);
}

void image::unlock()
{
   if (detached()) return;
   pImage_p->unlock();
}

Vector<Bool> image::hasLock () const
{
   Vector<Bool> tmp(2);
   tmp(0) = pImage_p->hasLock(FileLocker::Read);
   tmp(1) = pImage_p->hasLock(FileLocker::Write);
   return tmp;
}


ObjectID image::rebin (String& outFile, 
                       const Vector<Int>& factors,
                       const GlishRecord& glishRegion,
                       const String& mask,
                       Bool overwrite, Bool dropDegenerateAxes)
{
   if (detached()) {
      return ObjectID(True);
   }
//
   LogIO os(LogOrigin("image", "rebin", id(), WHERE));

// Validate outfile

    if (!overwrite && !outFile.empty()) {
       NewFile validfile;
       String errmsg;
       if (!validfile.valueOK(outFile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
       }
   }

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.

   AxesSpecifier axesSpecifier;
   if (dropDegenerateAxes) axesSpecifier = AxesSpecifier(False);
   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                            glishRegion, mask, True, os, False, axesSpecifier);
   delete pRegionRegion;
   delete pMaskRegion;

// Convert binning factors

   IPosition factors2(subImage.ndim());
   for (uInt i=0; i<factors.nelements(); i++) {
      if (factors(i) <= 0) {
         os << "Binning factors must be positive" << LogIO::EXCEPTION;
      }
      factors2[i] = max(1,factors[i]);
   }

// Create rebinner

   RebinImage<Float> binIm(subImage, factors2);
   IPosition outShape = binIm.shape();
   CoordinateSystem cSysOut = binIm.coordinates();

// Create the image and mask

   PtrHolder<ImageInterface<Float> > imOut;
   if (outFile.empty()) {
      os << LogIO::NORMAL << "Creating (temp)image of shape " << outShape
         << LogIO::POST;
      imOut.set(new TempImage<Float>(outShape, cSysOut));
   } else {
      os << LogIO::NORMAL << "Creating image '" << outFile << "' of shape " << outShape
         << LogIO::POST;
      imOut.set(new PagedImage<Float>(outShape, cSysOut, outFile));
   }
   ImageInterface<Float>* pImOut = imOut.ptr();
   String maskName("");
   makeMask(*pImOut, maskName, True, True, os, True);

// Do the work

   LatticeUtilities::copyDataAndMask (os, *pImOut, binIm);

// Copy miscellaneous things over

   ImageUtilities::copyMiscellaneous(*pImOut, binIm);

// Return ID

   ObjectController *controller = ApplicationEnvironment::objectController();
   ApplicationObject *subobject = 0;
   if (controller) {
      subobject = new image(*pImOut);
      AlwaysAssert(subobject, AipsError);
      return controller->addObject(subobject);
   } else {
      return ObjectID(True); // null
   }
}


ObjectID image::regrid (String& outFile, 
                        const Vector<Int>& shape,
                        const GlishRecord& coordinates,
                        const String& methodU, 
                        const Vector<Index>& pixelAxes,
                        const GlishRecord& glishRegion,
                        const String& mask,
                        Bool doRefChange, Bool dropDegenerateAxes,
                        Int decimate, Bool replicate, 
                        Bool overwrite, Bool forceRegrid, Int dbg) 
{
   if (detached()) {
      return ObjectID(True);
   }
//
   LogIO os(LogOrigin("image", "regrid", id(), WHERE));
   String method2 = methodU;
   method2.upcase();

// Validate outfile

    if (!overwrite && !outFile.empty()) {
       NewFile validfile;
       String errmsg;
       if (!validfile.valueOK(outFile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
       }
   }

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.

   AxesSpecifier axesSpecifier;
   if (dropDegenerateAxes) axesSpecifier = AxesSpecifier(False);
   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                            glishRegion, mask, True, os, False, axesSpecifier);
   delete pRegionRegion;
   delete pMaskRegion;

// Deal with axes

   Vector<Int> axes;
   Index::convertVector(axes, pixelAxes);
   IPosition axes2(axes);
   IPosition outShape(shape);

// Make CoordinateSystem from user given

   PtrHolder<CoordinateSystem> cSysTo;
   CoordinateSystem cSysFrom = subImage.coordinates();
   if (coordinates.nelements()==0) {
      cSysTo.set(new CoordinateSystem(cSysFrom));
   } else {
      cSysTo.set(makeCoordinateSystem(coordinates, outShape));
   }
   CoordinateSystem* pCSTo = cSysTo.ptr();
   pCSTo->setObsInfo(cSysFrom.obsInfo());

// Now build a CS which copies the user specified Coordinate for axes
// to be regridded and the input image Coordinate for axes not to be regridded

   CoordinateSystem cSys = 
     ImageRegrid<Float>::makeCoordinateSystem (os, *pCSTo, cSysFrom, axes2);
   if (cSys.nPixelAxes() != outShape.nelements()) {
      os << "The number of pixel axes in the output shape and Coordinate System must be the same" << LogIO::EXCEPTION;
   }

// Create the image and mask

   PtrHolder<ImageInterface<Float> > imOut;
   if (outFile.empty()) {
      os << LogIO::NORMAL << "Creating (temp)image of shape " << outShape
         << LogIO::POST;
      imOut.set(new TempImage<Float>(outShape, cSys));
   } else {
      os << LogIO::NORMAL << "Creating image '" << outFile << "' of shape " << outShape
         << LogIO::POST;
      imOut.set(new PagedImage<Float>(outShape, cSys, outFile));
   }
   ImageInterface<Float>* pImOut = imOut.ptr();
   pImOut->set(0.0);
   ImageUtilities::copyMiscellaneous(*pImOut, subImage);
   String maskName("");
   makeMask(*pImOut, maskName, True, True, os, True);
//
   Interpolate2D::Method method = Interpolate2D::stringToMethod(methodU);
   IPosition dummy;
   ImageRegrid<Float> ir;
   ir.showDebugInfo(dbg);
   ir.disableReferenceConversions(!doRefChange);
   ir.regrid(*pImOut, method, axes2, subImage, replicate, decimate, True, forceRegrid);

// Return ID

   ObjectController *controller = ApplicationEnvironment::objectController();
   ApplicationObject *subobject = 0;
   if (controller) {
      subobject = new image(*pImOut);
      AlwaysAssert(subobject, AipsError);
      return controller->addObject(subobject);
   } else {
      return ObjectID(True); // null
   }
}

ObjectID image::rotate (String& outFile, 
                        const Vector<Int>& shape,
                        const Quantum<Double>& pa,
                        const String& methodU, 
                        const GlishRecord& glishRegion,
                        const String& mask,
                        Int decimate, Bool replicate, 
                        Bool overwrite, Int dbg) 
//
// Only handles Direction or Linear coordinate
//
{
   if (detached()) {
      return ObjectID(True);
   }
//
   LogIO os(LogOrigin("image", "rotate", id(), WHERE));
   String method2 = methodU;
   method2.upcase();

// Validate outfile

    if (!overwrite && !outFile.empty()) {
       NewFile validfile;
       String errmsg;
       if (!validfile.valueOK(outFile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
       }
   }

// Convert region from Glish record to ImageRegion. Convert mask to ImageRegion
// and make SubImage.

   AxesSpecifier axesSpecifier;
   ImageRegion* pRegionRegion = 0;
   ImageRegion* pMaskRegion = 0;
   SubImage<Float> subImage = makeSubImage (pRegionRegion, pMaskRegion, *pImage_p,
                                            glishRegion, mask, True, os, False, axesSpecifier);
   delete pRegionRegion;
   delete pMaskRegion;

// Get image coordinate system

   CoordinateSystem cSysFrom = subImage.coordinates();
   CoordinateSystem cSysTo = cSysFrom;

// We automatically find a DirectionCoordinate or LInearCoordinate
// These must hold *only* 2 axes at this point (restriction in ImageRegrid)

   Int after = -1;
   Int dirInd=-1;
   Int linInd = -1;
   uInt coordInd = 0;
   Vector<Int> pixelAxes;
//
   dirInd = cSysTo.findCoordinate(Coordinate::DIRECTION, after);
   if (dirInd<0) {
      after = -1;
      linInd = cSysTo.findCoordinate(Coordinate::LINEAR, after);
      if (linInd>=0) {
         pixelAxes = cSysTo.pixelAxes(linInd);
         coordInd = linInd;
         os << "Rotating LinearCoordinate holding axes " << pixelAxes+1 << LogIO::POST;
      }
   } else {
      pixelAxes = cSysTo.pixelAxes(dirInd);
      coordInd = dirInd;
      os << "Rotating DirectionCoordinate holding axes " << pixelAxes+1 << LogIO::POST;
   }
//
   if (pixelAxes.nelements()==0) {
      os << "Could not find a Direction or Linear coordinate to rotate" << LogIO::EXCEPTION;
   } else if (pixelAxes.nelements()!=2) {
      os << "Coordinate to rotate must hold exactly two axes" << LogIO::EXCEPTION;
   }

// Get Linear Transform

   const Coordinate& coord = cSysTo.coordinate(coordInd);
   Matrix<Double> xf = coord.linearTransform();

// Generate rotation matrix components

   Double angleRad = pa.getValue(Unit("rad"));
   Matrix<Double> rotm(2,2);
   Double s = sin(-angleRad);
   Double c = cos(-angleRad);
   rotm(0,0) =  c; rotm(0,1) = s;
   rotm(1,0) = -s; rotm(1,1) = c;

// Create new linear transform matrix

   Matrix<Double> xform(2,2);
   xform(0,0) = rotm(0,0)*xf(0,0)+rotm(0,1)*xf(1,0);
   xform(0,1) = rotm(0,0)*xf(0,1)+rotm(0,1)*xf(1,1);
   xform(1,0) = rotm(1,0)*xf(0,0)+rotm(1,1)*xf(1,0);
   xform(1,1) = rotm(1,0)*xf(0,1)+rotm(1,1)*xf(1,1);

// Apply new linear transform matrix to coordinate

   if (cSysTo.type(coordInd)==Coordinate::DIRECTION) {
      DirectionCoordinate c = cSysTo.directionCoordinate(coordInd);
      c.setLinearTransform(xform);
      cSysTo.replaceCoordinate(c, coordInd);
   } else {
      LinearCoordinate c = cSysTo.linearCoordinate(coordInd);
      c.setLinearTransform(xform);
      cSysTo.replaceCoordinate(c, coordInd);
   }

// Determine axes to regrid to new coordinate system

   IPosition axes2(pixelAxes);
   IPosition outShape(shape);

// Now build a CS which copies the user specified Coordinate for axes
// to be regridded and the input image Coordinate for axes not to be regridded

   CoordinateSystem cSys = 
     ImageRegrid<Float>::makeCoordinateSystem (os, cSysTo, cSysFrom, axes2);
   if (cSys.nPixelAxes() != outShape.nelements()) {
      os << "The number of pixel axes in the output shape and Coordinate System must be the same" << LogIO::EXCEPTION;
   }

// Create the image and mask

   PtrHolder<ImageInterface<Float> > imOut;
   if (outFile.empty()) {
      os << LogIO::NORMAL << "Creating (temp)image of shape " << outShape
         << LogIO::POST;
      imOut.set(new TempImage<Float>(outShape, cSys));
   } else {
      os << LogIO::NORMAL << "Creating image '" << outFile << "' of shape " << outShape
         << LogIO::POST;
      imOut.set(new PagedImage<Float>(outShape, cSys, outFile));
   }
   ImageInterface<Float>* pImOut = imOut.ptr();
   pImOut->set(0.0);
   ImageUtilities::copyMiscellaneous(*pImOut, subImage);
   String maskName("");
   makeMask(*pImOut, maskName, True, True, os, True);
//
   Interpolate2D::Method method = Interpolate2D::stringToMethod(methodU);
   IPosition dummy;
   ImageRegrid<Float> ir;
   ir.showDebugInfo(dbg);
   Bool forceRegrid = False;
   ir.regrid(*pImOut, method, axes2, subImage, replicate, decimate, True, forceRegrid);

// Return ID

   ObjectController *controller = ApplicationEnvironment::objectController();
   ApplicationObject *subobject = 0;
   if (controller) {
      subobject = new image(*pImOut);
      AlwaysAssert(subobject, AipsError);
      return controller->addObject(subobject);
   } else {
      return ObjectID(True); // null
   }
}

GlishRecord image::restoringBeam () const
{
    GlishRecord rec;
    if (detached()) return rec;
//
    ImageInfo info = pImage_p->imageInfo();
    Record iRec;
    String error;
    if (!info.toRecord(error, iRec)) {
       LogIO os(LogOrigin("image", "restoringBeam", id(), WHERE));
       os << LogIO::SEVERE << "Failed to convert ImageInfo to a record because " << LogIO::POST;
       os << LogIO::SEVERE << error  << LogIO::POST;
    } else {
       if (iRec.isDefined("restoringbeam")) {
          rec.fromRecord(iRec.asRecord("restoringbeam"));
       }
    }
    return rec;
}

void image::setRestoringBeam (const GlishRecord& beam,
                              Bool deleteIt, Bool log)
{
    LogIO os(LogOrigin("image", "setRestoringBeam", id(), WHERE));
    if (detached()) return;
//
    ImageInfo ii = pImage_p->imageInfo();
    if (deleteIt) {
       if (log) {
          os << LogIO::NORMAL << "Deleting restoring beam" << LogIO::POST;
       }
       ii.removeRestoringBeam();
    } else {
       Record rec;
       beam.toRecord(rec);
       String error;
       Record rec2;
       rec2.defineRecord ("restoringbeam", rec);
       if (!ii.fromRecord(error, rec2)) {
          LogIO os(LogOrigin("image", "setRestoringBeam", id(), WHERE));
          os << error << LogIO::EXCEPTION;
       }
//
       if (log) {
          Vector<Quantum<Double> > b = ii.restoringBeam();
          os << LogIO::NORMAL << "Set restoring beam" << endl;
          {
             ostringstream oss;
             oss << b(0);
             os << "  Major          : " << String(oss) << endl;
          }
          {
             ostringstream oss;
             oss << b(1);
             os << "  Minor          : " << String(oss) << endl;
          }
          {
             ostringstream oss;
             oss << b(2);
             os << "  Position Angle : " << String(oss) << endl;
          }
          os.post();
       }
    }
    pImage_p->setImageInfo(ii);
}



// Private methods

void image::centreRefPix (CoordinateSystem& cSys, const IPosition& shape) const
{
   Int after = -1;
   Int iS = cSys.findCoordinate(Coordinate::STOKES, after);
   Int sP = -1;
   if (iS>=0) {
      Vector<Int> pixelAxes = cSys.pixelAxes(iS);
      sP = pixelAxes(0);
   }
   Vector<Double> refPix = cSys.referencePixel();
   for (Int i=0; i<Int(refPix.nelements()); i++) {
      if (i!=sP) refPix(i) = Double(shape(i) / 2);
   }
   cSys.setReferencePixel(refPix);
}




Bool image::makeMask(ImageInterface<Float>& out, String& maskName, Bool init, 
                     Bool makeDefault, LogIO& os, Bool list)  const
{
   if (out.canDefineRegion()) {

// Generate mask name if not given

      if (maskName.empty()) maskName = out.makeUniqueRegionName(String("mask"), 0);

// Make the mask if it does not exist

      if (!out.hasRegion (maskName, RegionHandler::Masks)) {
         out.makeMask(maskName, True, makeDefault, init, True);
         if (list) {
            if (init) {
               os << LogIO::NORMAL << "Created and initialized mask `" << maskName << "'" << LogIO::POST;
            } else {
               os << LogIO::NORMAL << "Created mask `" << maskName << "'" << LogIO::POST;
            }
         }
      }
//
      return True;
   } else {
      os << LogIO::WARN << "Cannot make requested mask for this type of image" << endl;
      return False;
   }
}


void image::deleteHistAndStats()
{
   if (pStatistics_p != 0) {
      delete pStatistics_p;
      pStatistics_p = 0;
   }
   if (pHistograms_p != 0) {
      delete pHistograms_p;
      pHistograms_p = 0;
   }
   if (pOldStatsRegionRegion_p != 0) {
      delete pOldStatsRegionRegion_p;
      pOldStatsRegionRegion_p = 0;
   }
   if (pOldStatsMaskRegion_p != 0) {
      delete pOldStatsMaskRegion_p;
      pOldStatsMaskRegion_p = 0;
   }
   if (pOldHistRegionRegion_p != 0) {
      delete pOldHistRegionRegion_p;
      pOldHistRegionRegion_p = 0;
   }
   if (pOldHistMaskRegion_p != 0) {
      delete pOldHistMaskRegion_p;
      pOldHistMaskRegion_p = 0;
   }
}


void image::dummyHeader(Vector<String> &axisNames,
 		        Vector<Double> &referenceValues,
		        Vector<Double> &referencePixels, 
		        Vector<Double> &deltas,
                        const Vector<Int> &shape) const

//
// Fill in some dummy values for the header coordinates
//
//  Input
//      shape   Shape of image
//
{
    uInt ndim = shape.nelements();
    axisNames.resize(ndim);
    referenceValues.resize(ndim);
    referencePixels.resize(ndim);
    deltas.resize(ndim);

    char names[] = {'x', 'y', 'z', 'w', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'};

    for (uInt i=0; i<ndim; i++) {
	axisNames(i) = names[i];
	referenceValues(i) = 0.0;
	referencePixels(i) = Float(Int((shape(i) + 1)/2));
	deltas(i) = 1.0;
    }
}




Bool image::make_image(String &error,
		       const String& outfile, 
		       const CoordinateSystem& cSys,
		       const IPosition& shape,
                       LogIO& os, Bool log, Bool overwrite)
{
// Verify outfile

    if (!overwrite && !outfile.empty()) {
      NewFile validfile;
      String errmsg;
      if (!validfile.valueOK(outfile, errmsg)) {
          error = errmsg;
          return False;
      }
   }
//
    error = "";
    if (pImage_p != 0) {
	delete pImage_p;
        pImage_p = 0;
    }

// This function is generally only called for creating new images,
// but you never know, so add statistic/histograms protection

    deleteHistAndStats();

    uInt ndim = shape.nelements();
    if (ndim != cSys.nPixelAxes()) {
       error = "Supplied CoordinateSystem and image shape are inconsistent";
       return False;
    }
//
    if (outfile.empty()) {
       pImage_p = new TempImage<Float>(shape, cSys);
       if (pImage_p == 0) {
          error = "Failed to create TempImage";
          return False;
       }
       if (log) {
          os << LogIO::NORMAL << "Creating (temp)image of shape " 
             << pImage_p->shape() << LogIO::POST;
       }
    } else {
       pImage_p = new PagedImage<Float>(shape, cSys, outfile);
       if (pImage_p == 0) {
          error = "Failed to create PagedImage";
          return False;
       }
       if (log) {
          os << LogIO::NORMAL << "Creating image '" << outfile << "' of shape " 
             << pImage_p->shape() << LogIO::POST;
       }
    }
    return True;
}



Bool image::makeExternalImage (PtrHolder<ImageInterface<Float> >& image,
                              const String& fileName, 
                              const CoordinateSystem& cSys,
                              const IPosition& shape,
                              const ImageInterface<Float>& inImage,
                              LogIO& os, Bool overwrite, Bool allowTemp,
                              Bool copyMask)

{
   if (fileName.empty()) {
      if (allowTemp) {
         os << LogIO::NORMAL << "Creating (Temp)Image '" << " of shape "
            << shape << LogIO::POST;
         image.set(new TempImage<Float>(shape, cSys));
      }
   } else {
      if (!overwrite) {
         NewFile validfile;
         String errmsg;
         if (!validfile.valueOK(fileName, errmsg)) {
             os << errmsg << LogIO::EXCEPTION;
         }
      }
      os << LogIO::NORMAL << "Creating image '" << fileName << "' of shape "
         << shape << LogIO::POST;
      image.set(new PagedImage<Float>(shape, cSys, fileName));
   }

// See if we made something

   ImageInterface<Float>* pIm = image.ptr();
   if (pIm) {
      ImageUtilities::copyMiscellaneous(*pIm, inImage);
//      
      if (copyMask && inImage.isMasked()) {
         String maskName("");
         makeMask(*pIm, maskName, False, True, os, True);
         Lattice<Bool>& pixelMaskOut = pIm->pixelMask();

// The input image may be a subimage with a pixel mask and
// a region mask, so use getMaskSlice to get its mask

         LatticeIterator<Bool> maskIter(pixelMaskOut);
         for (maskIter.reset(); !maskIter.atEnd(); maskIter++) {
           maskIter.rwCursor() = inImage.getMaskSlice(maskIter.position(),
                                                      maskIter.cursorShape());
         }
      }
      return True;
   } else {
      return False;
   }
}




Bool image::detached() const
{
    if (pImage_p == 0) {
	LogIO os(LogOrigin("image", "detached", WHERE));
	os << "Image is detached - cannot perform operation." << endl <<
	    "Call image.open('filename') to reattach." << LogIO::EXCEPTION;
    }
    return False;
}

void image::set_cache(const IPosition &chunk_shape) const
{
    if (detached()) {
	return;
    }
//    
    if (chunk_shape.nelements() != last_chunk_shape_p.nelements() ||
	chunk_shape != last_chunk_shape_p) {
	image *This = (image *)this;
	This->last_chunk_shape_p.resize(chunk_shape.nelements());
	This->last_chunk_shape_p = chunk_shape;

// Assume that we will keep getting similar sized chunks filling up
// the whole image.

	IPosition shape(pImage_p->shape());
	IPosition blc(shape.nelements()); 
	blc = 0;
	IPosition axisPath(shape.nelements());
	for (uInt i=0; i<axisPath.nelements(); i++) {
	    axisPath(i) = i;
	}
	pImage_p->setCacheSizeFromPath(chunk_shape, blc, shape, axisPath);
    }
}


CoordinateSystem* image::makeCoordinateSystem(const GlishRecord& coordinates, const IPosition& shape) const

{     
   CoordinateSystem* pCS = 0;
   Record tmp;
   coordinates.toRecord(tmp);
   pCS = CoordinateSystem::restore(tmp, "");

// Fix up any body longitude ranges...

   String errMsg;
   if (!CoordinateUtil::cylindricalFix (*pCS, errMsg, shape)) {
      LogIO os(LogOrigin("image", "makeCoordinateSystem", id(), WHERE));
      os << LogIO::WARN << errMsg << LogIO::POST;
   }
//
   return pCS;
}



ImageRegion* image::makeRegionRegion(ImageInterface<Float>& inImage,
                                     const GlishRecord& glishRegion,
                                     const Bool listBoundingBox,
                                     LogIO& os) 
{

// Convert from GlishRecord to Record and make ImageRegion
// Handles null regions here

   ImageRegion* pRegion = 0;
   CoordinateSystem cSys(inImage.coordinates());
//
   if (glishRegion.nelements()==0) {   
      IPosition blc(inImage.ndim(),0);
      IPosition trc(inImage.shape()-1);
      LCSlicer slicer(blc, trc, RegionType::Abs);
      pRegion = new ImageRegion(slicer);
//
      if (listBoundingBox) { 
         os << LogIO::NORMAL <<  "Selected bounding box : " << endl;
         os << LogIO::NORMAL <<  "    " <<  blc+1 << " to " << trc+1 
            << "  (" << CoordinateUtil::formatCoordinate(blc,cSys) 
            << " to " << CoordinateUtil::formatCoordinate(trc,cSys) << ")" << LogIO::POST;
      }
   } else {   
      Record tableRegion;
      glishRegion.toRecord(tableRegion);  
      pRegion = ImageRegion::fromRecord(tableRegion, "");
//
      if (listBoundingBox) { 
         LatticeRegion latRegion =  
            pRegion->toLatticeRegion (inImage.coordinates(), inImage.shape());
         Slicer sl = latRegion.slicer();
         os << LogIO::NORMAL <<  "Selected bounding box : " << endl;
         os << LogIO::NORMAL <<  "    " <<  sl.start()+1 << " to " << sl.end()+1
            << "  (" << CoordinateUtil::formatCoordinate(sl.start(),cSys) 
            << " to " << CoordinateUtil::formatCoordinate(sl.end(),cSys) << ")" << LogIO::POST;
      }
   }
   return pRegion;
}

SubImage<Float> image::makeSubImage (ImageRegion*& pRegionRegion, ImageRegion*& pMaskRegion,
                                     ImageInterface<Float>& inImage,
                                     const GlishRecord& glishRegion, const String& mask,
                                     Bool listBoundingBox, LogIO& os,
                                     Bool writableIfPossible,
                                     const AxesSpecifier& axesSpecifier) 
//
// The ImageRegion pointers must be null on entry
// either pointer may be null on exit
//
{
   SubImage<Float> subImage;
   pMaskRegion = makeMaskRegion (mask);

// We can get away with no region processing if the GlishRegion
// is empty and the user is not dropping degenerate axes

   if (glishRegion.nelements()==0 && axesSpecifier.keep()) {
      if (pMaskRegion!=0) {
         subImage = SubImage<Float>(inImage, *pMaskRegion, writableIfPossible);
      } else {
         subImage = SubImage<Float>(inImage,True);
      }
   } else {
      pRegionRegion = makeRegionRegion(inImage, glishRegion, listBoundingBox, os);
      if (pMaskRegion!=0) {
         SubImage<Float> subImage0(inImage, *pMaskRegion, writableIfPossible);
         subImage = SubImage<Float>(subImage0, *pRegionRegion, writableIfPossible, axesSpecifier);
      } else {
         subImage = SubImage<Float>(inImage, *pRegionRegion, writableIfPossible, axesSpecifier);
      }
   }
//
   return subImage;
}


ImageRegion* image::makeMaskRegion (const String& mask) const
{
   ImageRegion* p = 0;
   if (!mask.empty()) {

// Get LatticeExprNode (tree) from parser.  Substitute possible object-id's
// by a sequence number, while creating a LatticeExprNode for it.
// Convert the GlishRecord containing regions to a PtrBlock<const ImageRegion*>.

      Block<LatticeExprNode> tempLattices;
      String exprName;
      String newMask = substituteOID (tempLattices, exprName, mask);
//
      PtrBlock<const ImageRegion*> tempRegs;
      LatticeExprNode node = ImageExprParse::command (newMask, tempLattices, tempRegs);
      const WCLELMask maskRegion(node);
      p = new ImageRegion(maskRegion);
   }
   return p;
}

Bool image::haveRegionsChanged (ImageRegion* pNewRegionRegion, ImageRegion* pNewMaskRegion,
                                ImageRegion* pOldRegionRegion, ImageRegion* pOldMaskRegion) const
{
   Bool regionChanged = (pNewRegionRegion!=0 && pOldRegionRegion!=0 && (*pNewRegionRegion)!=(*pOldRegionRegion)) ||
                        (pNewRegionRegion==0 && pOldRegionRegion!=0) ||
                        (pNewRegionRegion!=0 && pOldRegionRegion==0);
   Bool   maskChanged = (pNewMaskRegion!=0 && pOldMaskRegion!=0 && (*pNewMaskRegion)!=(*pOldMaskRegion)) ||
                        (pNewMaskRegion==0 && pOldMaskRegion!=0) ||
                        (pNewMaskRegion!=0 && pOldMaskRegion==0);
   return (regionChanged || maskChanged);
}




void image::makeRegionBlock (PtrBlock<const ImageRegion*>& regions,
			     const GlishRecord& glishRegions,
			     LogIO& os) 
{
   for (uInt j=0; j<regions.nelements(); j++) {
      delete regions[j];
   }
   regions.resize (0, True, True);
   uInt nreg = glishRegions.nelements();
   if (nreg > 1) {
      nreg--;
      regions.resize (nreg);
      regions.set (static_cast<ImageRegion*>(0));
      for (uInt i=0; i<nreg; i++) {
         GlishRecord gRec(glishRegions.get(i+1));   // Element 0 is number of regions
         Record rRec;
         gRec.toRecord(rRec);  
         regions[i] = ImageRegion::fromRecord(rRec,"");
      }
   }
}





// Public methods needed to run DO


String image::className() const
{
    return "image";
}

Vector<String> image::methods() const
{
    Vector<String> method(NUM_METHODS); 
    method(ADDNOISE) = "addnoise";    
    method(ADDDEGAXES) = "adddegaxes";    
    method(BOUNDINGBOX) = "boundingbox";
    method(BRIGHTNESSUNIT) = "brightnessunit";
    method(CALC) = "calc";
    method(CALCMASK) = "calcmask";
    method(COORDSYS) = "coordsys";
    method(CLOSE) = "close";
    method(CONVERTFLUX) = "convertflux";
    method(CONVOLVE) = "convolve";    
    method(CONVOLVE2D) = "convolve2d";
    method(DECONVOLVECOMPONENTLIST) = "deconvolvecomponentlist";
    method(DECOMPOSE) = "decompose";
    method(FINDSOURCES) = "findsources";
    method(FFT) = "fft";
    method(FITSKY) = "fitsky";
    method(FITALLPROFILES) = "fitallprofiles";
    method(FITPROFILE) = "fitprofile";
    method(GETCHUNK) = "getchunk";
    method(GETREGION) = "getregion";
    method(GETSLICE) = "getslice";
    method(HANNING) = "hanning";
    method(HASLOCK) = "haslock";
    method(HISTOGRAMS) = "histograms";
    method(HISTORY) = "history";
    method(INSERT) = "insert";
    method(ISPERSISTENT) = "ispersistent";
    method(LOCK) = "lock";
    method(MAKECOMPLEX) = "makecomplex";
    method(MASKHANDLER) = "maskhandler";
    method(MAXFIT) = "maxfit";
    method(MISCINFO) = "miscinfo";
    method(MODIFY) = "modify";
    method(MOMENTS) = "moments";
    method(NAME) = "name";
    method(OPEN) = "open";
    method(PIXELVALUE) = "pixelvalue";
    method(FITPOLYNOMIAL) = "fitpoly";
    method(PUTCHUNK) = "putchunk";
    method(PUTREGION) = "putregion";
    method(REBIN) = "rebin";
    method(REGRID) = "regrid";
    method(ROTATE) = "rotate";
    method(REPLACEMASKEDPIXELS) = "replacemaskedpixels";
    method(RESTORINGBEAM) = "restoringbeam";
    method(SEPCONVOLVE) = "sepconvolve";
    method(SETIMAGE) = "set";
    method(SETBRIGHTNESSUNIT) = "setbrightnessunit";
    method(SETCOORDSYS) = "setcoordsys";
    method(SETHISTORY) = "sethistory";
    method(SETMISCINFO) = "setmiscinfo";
    method(SETRESTORINGBEAM) = "setrestoringbeam";
    method(SHAPE) = "shape";
    method(STATISTICS) = "statistics";
    method(SUBIMAGE) = "subimage";
    method(SUMMARY) = "summary";
    method(TOFITS) = "tofits";
    method(TWOPOINTCORRELATION) = "twopointcorrelation";
    method(UNLOCK) = "unlock";
    return method;
}

Vector<String> image::noTraceMethods() const
{
    Vector<String> method(NUM_NOTRACE_METHODS);

    method(NT_ADDNOISE) = "addnoise";    
    method(NT_ADDDEGAXES) = "adddegaxes";    
    method(NT_BOUNDINGBOX) = "boundingbox";
    method(NT_BRIGHTNESSUNIT) = "brightnessunit";
    method(NT_CALCMASK) = "calcmask";
    method(NT_CLOSE) = "close";
    method(NT_COORDSYS) = "coordsys";
    method(NT_CONVERTFLUX) = "convertflux";
    method(NT_DECONVOLVECOMPONENTLIST) = "deconvolvecomponentlist";
    method(NT_FITPROFILE) = "fitprofile";
    method(NT_GETCHUNK) = "getchunk";
    method(NT_GETREGION) = "getregion";
    method(NT_GETSLICE) = "getslice";
    method(NT_HASLOCK) = "haslock";
    method(NT_HISTORY) = "history";
    method(NT_ISPERSISTENT) = "ispersistent";
    method(NT_LOCK) = "lock";
    method(NT_MAKECOMPLEX) = "makecomplex";
    method(NT_MASKHANDLER) = "maskhandler";
    method(NT_MAXFIT) = "maxfit";
    method(NT_MISCINFO) = "miscinfo";
    method(NT_NAME) = "name";
    method(NT_OPEN) = "open";
    method(NT_PIXELVALUE) = "pixelvalue";
    method(NT_PUTCHUNK) = "putchunk";
    method(NT_PUTREGION) = "putregion";
    method(NT_REPLACEMASKEDPIXELS) = "replacemaskedpixels";
    method(NT_RESTORINGBEAM) = "restoringbeam";
    method(NT_SETIMAGE) = "set";
    method(NT_SETBRIGHTNESSUNIT) = "setbrightnessunit";
    method(NT_SETCOORDSYS) = "setcoordsys";
    method(NT_SETHISTORY) = "sethistory";
    method(NT_SETMISCINFO) = "setmiscinfo";
    method(NT_SETRESTORINGBEAM) = "setrestoringbeam";
    method(NT_SHAPE) = "shape";
    method(NT_STATISTICS) = "statistics";
    method(NT_SUBIMAGE) = "subimage";
    method(NT_SUMMARY) = "summary";
    method(NT_UNLOCK) = "unlock";
    return method;
}

MethodResult image::runMethod(uInt which, 
			      ParameterSet &inputRecord,
			      Bool runMethod)
{
    static String returnvalString = "returnval";


    switch (which) {
    case SHAPE: 
	{
	    Parameter<Vector<Int> > returnval(inputRecord, returnvalString,
					       ParameterSet::Out);
	    if (runMethod) {
               returnval() = shape();
	    }
	}
    break;
    case OPEN: 
	{
	    Parameter<String> infile(inputRecord, "infile", ParameterSet::In);
	    if (runMethod) {
               open(infile());
	    }
	}
    break;
    case GETCHUNK:
        {
	    Parameter<Array<Float> > pixels(inputRecord, "pixels", ParameterSet::Out);
            pixels().resize(IPosition(0,0));
	    Parameter<Array<Bool> > pixelMask(inputRecord, "pixelmask", ParameterSet::Out);
            pixelMask().resize(IPosition(0,0));
            Parameter<Vector<Index> >
                blc(inputRecord, "blc", ParameterSet::In);
            Parameter<Vector<Index> >
                trc(inputRecord, "trc", ParameterSet::In);
            Parameter<Vector<Int> >
                inc(inputRecord, "inc", ParameterSet::In);
            Parameter<Vector<Index> >
                axes(inputRecord, "axes", ParameterSet::In);
            Parameter<Bool> listBox(inputRecord, "list",
                                    ParameterSet::In);
            Parameter<Bool> dropDeg(inputRecord, "dropdeg",
                                    ParameterSet::In);
            Parameter<Bool> getMask(inputRecord, "getmask",
                                    ParameterSet::In);
            if (runMethod) {
                getchunk(pixels(), pixelMask(), blc(), trc(), 
                         inc(), axes(), listBox(), dropDeg(), getMask()); 
            }
        }
    break;
    break;
    case GETSLICE:
        {
	    Parameter<Vector<Float> > xPos(inputRecord, "xpos", ParameterSet::Out);
            xPos().resize(0);
	    Parameter<Vector<Float> > yPos(inputRecord, "ypos", ParameterSet::Out);
            yPos().resize(0);
	    Parameter<Vector<Float> > distance(inputRecord, "distance", ParameterSet::Out);
            distance().resize(0);
//
	    Parameter<Vector<Float> > pixels(inputRecord, "pixels", ParameterSet::Out);
            pixels().resize(0);
	    Parameter<Vector<Bool> > pixelMask(inputRecord, "pixelmask", ParameterSet::Out);
            pixelMask().resize(0);
//
            Parameter<Vector<Double> >  x(inputRecord, "x", ParameterSet::In);
            Parameter<Vector<Double> >  y(inputRecord, "y", ParameterSet::In);
            Parameter<Vector<Index> >  coord(inputRecord, "coord", ParameterSet::In);
            Parameter<Vector<Index> > axes(inputRecord, "axes", ParameterSet::In);
            Parameter<Int> nPts(inputRecord, "npts", ParameterSet::In);            
            Parameter<String> method(inputRecord, "method", ParameterSet::In);
            if (runMethod) {
                getSlice1D (xPos(), yPos(), distance(), pixels(), pixelMask(), 
                            coord(), axes(), x(), y(), method(), nPts());
            }
        }
    break;
    case PUTCHUNK: 
        {
            Parameter<Array<Float> >
                pixels(inputRecord, "pixels", ParameterSet::In);
            Parameter<Vector<Index> >
                blc(inputRecord, "blc", ParameterSet::In);
            Parameter<Vector<Int> >
                inc(inputRecord, "inc", ParameterSet::In);
            Parameter<Bool> listBox(inputRecord, "list",
                                    ParameterSet::In);
            Parameter<Bool> replicate(inputRecord, "replicate",
                                    ParameterSet::In);
            if (runMethod) {
                putchunk(pixels(), blc(), inc(), listBox(), replicate());
            }
        }
    break;
    case NAME:
	{
	    Parameter<Bool> stripPath(inputRecord, "strippath", ParameterSet::In);
	    Parameter<String>
		returnval(inputRecord, returnvalString, ParameterSet::Out);
	    if (runMethod) {
               returnval() = name(stripPath());
	    }
	}
    break;
    case TOFITS:
	{
	    Parameter<String> fitsfile(inputRecord, "fitsfile", ParameterSet::In);
	    Parameter<Bool> velocity(inputRecord, "velocity", ParameterSet::In);
	    Parameter<Bool> optical(inputRecord, "optical", ParameterSet::In);
	    Parameter<Int> bitpix(inputRecord, "bitpix", ParameterSet::In);
	    Parameter<Float> minpix(inputRecord, "minpix", ParameterSet::In);
	    Parameter<Float> maxpix(inputRecord, "maxpix", ParameterSet::In);
	    Parameter<GlishRecord> region(inputRecord, "region", ParameterSet::In);
	    Parameter<String> mask(inputRecord, "mask", ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite", ParameterSet::In);
	    Parameter<Bool> dropDeg(inputRecord, "dropdeg", ParameterSet::In);
	    Parameter<Bool> degLast(inputRecord, "deglast", ParameterSet::In);
	    if (runMethod) {
               tofits(fitsfile(), velocity(), optical(), bitpix(), minpix(),
                      maxpix(), region(), mask(), overwrite(), dropDeg(), degLast());
	    }
	}
    break;
    case SUMMARY:
	{
            Parameter<Vector<String> > returnval(inputRecord, "returnval",
                                                 ParameterSet::Out);
            Parameter<GlishRecord> header(inputRecord, "header", ParameterSet::Out);
	    Parameter<String> velocityType(inputRecord, "velocity", ParameterSet::In);
	    Parameter<Bool> listIt(inputRecord, "list", ParameterSet::In);
	    Parameter<Bool> order(inputRecord, "pixelorder", ParameterSet::In);
	    if (runMethod) {
               returnval() = summary(header(), velocityType(), 
                                     listIt(), order());
	    }
	}
    break;
    case MOMENTS:
	{
            UnitMap::putUser("pix",UnitVal(1.0), "pixel units");
	    Parameter<Vector<Int> > whichmoments(inputRecord, "moments",
						  ParameterSet::In);
	    Parameter<Index> axis(inputRecord, "axis", 
					ParameterSet::In);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
					        ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
					        ParameterSet::In);
	    Parameter<Vector<String> > method(inputRecord, "method",
						   ParameterSet::In);
	    Parameter<Vector<String> > kernels(inputRecord, "smoothtypes",
						ParameterSet::In);
	    Parameter<Vector<Index> > smoothaxes(inputRecord, "smoothaxes",
						  ParameterSet::In);
	    Parameter<Vector<Quantum<Double> > > kernelwidths(inputRecord, "smoothwidths",
						     ParameterSet::In);
	    Parameter<Vector<Float> > includepix(inputRecord, "includepix",
						  ParameterSet::In);
   	    Parameter<Vector<Float> > excludepix(inputRecord, "excludepix",
   						  ParameterSet::In);
	    Parameter<Double> peaksnr(inputRecord, "peaksnr",
						ParameterSet::In);
	    Parameter<Double> stddev(inputRecord, "stddev",
						ParameterSet::In);
	    Parameter<String> velocity(inputRecord, "velocity",
				  ParameterSet::In);
	    Parameter<String> outfile(inputRecord, "outfile",
				  ParameterSet::In);
	    Parameter<String> smoothout(inputRecord, "smoothout",
				  ParameterSet::In);
	    Parameter<String> plotter(inputRecord, "plotter",
				  ParameterSet::In);
	    Parameter<Int> nx(inputRecord, "nx", ParameterSet::In);
	    Parameter<Int> ny(inputRecord, "ny", ParameterSet::In);
	    Parameter<Bool> yind(inputRecord, "yind",
				  ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite",
				  ParameterSet::In);
	    Parameter<Bool> removeAxis(inputRecord, "remove",
				  ParameterSet::In);
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    if (runMethod) {
		returnval() = moments(whichmoments(), axis(),
                        regionRecord(), maskRecord(), method(),
			smoothaxes(), kernels(),
			kernelwidths(), includepix(),
			excludepix(), peaksnr(), stddev(), velocity(),
			outfile(), smoothout(),
			plotter(), nx(), ny(), yind(), 
                        overwrite(), removeAxis());
	    }
	}
    break;
    case STATISTICS:
	{
	    Parameter<GlishRecord> statsout(inputRecord, "statsout",
					    ParameterSet::Out);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
					        ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
   		                         ParameterSet::In);
	    Parameter<Vector<Index> > axes(inputRecord, "axes",
						  ParameterSet::In);
	    Parameter<Vector<String> > plotstats(inputRecord, "plotstats",
						   ParameterSet::In);
	    Parameter<Vector<Float> > includepix(inputRecord, "includepix",
						ParameterSet::In);
	    Parameter<Vector<Float> > excludepix(inputRecord, "excludepix",
						ParameterSet::In);
	    Parameter<Bool> list(inputRecord, "list", ParameterSet::In);
	    Parameter<String> plotter(inputRecord, "plotter",
				  ParameterSet::In);
	    Parameter<Int> nx(inputRecord, "nx", ParameterSet::In);
	    Parameter<Int> ny(inputRecord, "ny", ParameterSet::In);
	    Parameter<Bool> force(inputRecord, "force", ParameterSet::In);
	    Parameter<Bool> disk(inputRecord, "disk", ParameterSet::In);
	    Parameter<Bool> robust(inputRecord, "robust", ParameterSet::In);
	    Parameter<Bool> verbose(inputRecord, "verbose", ParameterSet::In);
	    if (runMethod) {
		statistics(statsout(), axes(),
                           regionRecord(), maskRecord(), plotstats(),
			   includepix(), excludepix(),
			   list(), plotter(), 
                           nx(), ny(), 
                           force(), disk(), robust(), verbose());
	    }
	}
    break;
    case HISTOGRAMS:
	{
            Parameter<GlishRecord> histout(inputRecord, "histout",
                                           ParameterSet::Out);
	    Parameter< Vector<Index> > axes(inputRecord, "axes",
                                            ParameterSet::In);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
					        ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
   		                         ParameterSet::In);
	    Parameter<Int> nbins(inputRecord, "nbins", ParameterSet::In);
	    Parameter<Vector<Float> > includepix(inputRecord, "includepix",
						ParameterSet::In);
	    Parameter<Bool> gauss(inputRecord, "gauss", ParameterSet::In);
	    Parameter<Bool> cumu(inputRecord, "cumu", 
				       ParameterSet::In);
	    Parameter<Bool> log(inputRecord, "log", ParameterSet::In);
	    Parameter<Bool> list(inputRecord, "list", ParameterSet::In);
	    Parameter<String> plotter(inputRecord, "plotter",
				  ParameterSet::In);
	    Parameter<Int> nx(inputRecord, "nx", ParameterSet::In);
	    Parameter<Int> ny(inputRecord, "ny", ParameterSet::In);
	    Parameter<Vector<Int> > size(inputRecord, "size",
					ParameterSet::In);
	    Parameter<Bool> force(inputRecord, "force", ParameterSet::In);
	    Parameter<Bool> disk(inputRecord, "disk", ParameterSet::In);

	    if (runMethod) {
		histograms(histout(), axes(), regionRecord(), maskRecord(),
                           nbins(), includepix(), gauss(), 
                           cumu(), log(), 
                           list(), plotter(), 
                           nx(), ny(),  size(),
                           force(), disk());
	    }
	}
    break;
    case MISCINFO:
	{
	    Parameter<GlishRecord> returnval(inputRecord, "returnval",
					     ParameterSet::Out);
	    if (runMethod) {
               returnval() = miscinfo();
	    }
	}
    break;
    case SETMISCINFO:
	{
	    Parameter<Bool> returnval(inputRecord, "returnval",
					     ParameterSet::Out);
	    Parameter<GlishRecord> newinfo(inputRecord, "newinfo",
					     ParameterSet::In);
	    if (runMethod) {
               returnval() = setmiscinfo(newinfo());
	    }
	}
    break;
    case SUBIMAGE:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
                                                ParameterSet::In);
	    Parameter<String> mask(inputRecord, "mask",
                                      ParameterSet::In);
	    Parameter<String> outfile(inputRecord, "outfile",
                                      ParameterSet::In);
	    Parameter<Bool> dropDeg(inputRecord, "dropdeg",
                                      ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite",
                                      ParameterSet::In);
	    Parameter<Bool> list(inputRecord, "list",
                                ParameterSet::In);
	    if (runMethod) {
               returnval() = subimage(outfile(), regionRecord(), mask(), 
                                      dropDeg(), overwrite(), list());
	    }
	}
    break;
    case CLOSE:
	{
	    if (runMethod) {
               close();
	    }
	}
    break;
    case INSERT:
	{
	    Parameter<GlishRecord> region(inputRecord, "region", ParameterSet::In);
            Parameter<Vector<Double> > locate(inputRecord, "locate", ParameterSet::In);
	    Parameter<String> infile(inputRecord, "infile", ParameterSet::In);
	    Parameter<Int> dbg(inputRecord, "dbg", ParameterSet::In);
	    Parameter<Bool> doRef(inputRecord, "doref", ParameterSet::In);
//
	    if (runMethod) {
               insertImage(infile(), region(), locate(), doRef(), dbg());
	    }
	}
    break;
    case HANNING:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
					     ParameterSet::Out);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
					        ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
					        ParameterSet::In);
	    Parameter<Index> axis(inputRecord, "axis", 
  					ParameterSet::In);
	    Parameter<String> outfile(inputRecord, "outfile",
					     ParameterSet::In);
	    Parameter<Bool> drop(inputRecord, "drop",
					     ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite",
					     ParameterSet::In);
	    if (runMethod) {
               returnval() = hanning(regionRecord(), maskRecord(), axis(), 
                                     outfile(), drop(), overwrite());
	    }
	}
    break;
    case CALC:
	{
	    Parameter<Bool> returnval(inputRecord, "returnval",
                                      ParameterSet::Out);
	    Parameter<String> expr(inputRecord, "expr",
                                   ParameterSet::In);
	    Parameter<GlishRecord> regionsRecord(inputRecord, "regions",
					   ParameterSet::In);
	    if (runMethod) {
               returnval() = calc(expr(), regionsRecord());
	    }
	}
    break;
    case COORDSYS:
	{
            Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    Parameter< Vector<Index> > axes(inputRecord, "axes",
                                            ParameterSet::In);
	    if (runMethod) {
               returnval() = coordSys(axes());
	    }
	}
    break;
    case SETCOORDSYS:
	{
            Parameter<GlishRecord> csys(inputRecord, "csys",
                                        ParameterSet::In);
	    if (runMethod) {
               setCoordinateSystem(csys());
	    }
	}
    break;
    case BOUNDINGBOX:
	{
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
					        ParameterSet::In);
	    Parameter<GlishRecord> returnval(inputRecord, "returnval",
					     ParameterSet::Out);
	    if (runMethod) {
               returnval() = boundingBox(regionRecord());
	    }
	}
    break;
    case GETREGION:
	{
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
					        ParameterSet::In);
            Parameter<Vector<Index> >
                axes(inputRecord, "axes", ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
					        ParameterSet::In);
            Parameter<Bool> listBoxRecord(inputRecord, "list",
                                          ParameterSet::In);
            Parameter<Bool> removeDegAxesRecord(inputRecord, "dropdeg",
                                          ParameterSet::In);
	    Parameter<Array<Float> >
		dataRecord(inputRecord, "pixels", ParameterSet::Out);
            dataRecord().resize(IPosition(0,0));
	    Parameter<Array<Bool> >
		pixelMaskRecord(inputRecord, "pixelmask", ParameterSet::Out);
            pixelMaskRecord().resize(IPosition(0,0));
            Parameter<Bool> getPixels(inputRecord, "getpixels", ParameterSet::In);

            Parameter<Bool> getMask(inputRecord, "getmask", ParameterSet::In);
//
	    if (runMethod) {
               getRegion(dataRecord(), pixelMaskRecord(),
                         regionRecord(), axes(), maskRecord(), listBoxRecord(),
                         removeDegAxesRecord(), getPixels(), getMask());
	    }
	}
    break;
    case PUTREGION:
	{
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
					        ParameterSet::In);
            Parameter<Bool> listBoxRecord(inputRecord, "list",
                                          ParameterSet::In);
	    Parameter<Array<Float> >
		dataRecord(inputRecord, "pixels", ParameterSet::In);
	    Parameter<Array<Bool> >
		maskRecord(inputRecord, "pixelmask", ParameterSet::In);
	    Parameter<Bool>
		useMaskRecord(inputRecord, "usemask", ParameterSet::In);
	    Parameter<Bool>
		replicateRecord(inputRecord, "replicate", ParameterSet::In);
	    if (runMethod) {
               putRegion(dataRecord(), maskRecord(), regionRecord(), 
                         listBoxRecord(), useMaskRecord(), replicateRecord());
	    }
	}
    break;
    case FITSKY:
        {
	    Parameter<Array<Float> >
		dataRecord(inputRecord, "pixels", ParameterSet::Out);
            dataRecord().resize(IPosition(0,0));
	    Parameter<Array<Bool> >
		pixelMaskRecord(inputRecord, "pixelmask", ParameterSet::Out);
            pixelMaskRecord().resize(IPosition(0,0));
	    Parameter<Bool>
		convergedRecord(inputRecord, "converged", ParameterSet::Out);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
                                                ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
                                                ParameterSet::In);
	    Parameter<Vector<String> > modelRecord(inputRecord, "models",
                                                    ParameterSet::In);
	    Parameter<Vector<String> > fixedMaskRecord(inputRecord, "fixed",
                                                    ParameterSet::In);
	    Parameter<Vector<SkyComponent> >
		estimateRecord(inputRecord, "estimate", ParameterSet::In);
	    Parameter<Vector<Float> >
		includeRecord(inputRecord, "includepix", ParameterSet::In);
	    Parameter<Vector<Float> >
		excludeRecord(inputRecord, "excludepix", ParameterSet::In);
	    Parameter<Bool>
		fitItRecord(inputRecord, "fit", ParameterSet::In);
	    Parameter<Bool>
		deconvolveItRecord(inputRecord, "deconvolve", ParameterSet::In);
	    Parameter<Bool>
		listRecord(inputRecord, "list", ParameterSet::In);
//
	    Parameter<Vector<SkyComponent> > returnval(inputRecord, "returnval",
                                              ParameterSet::Out);
	    if (runMethod) {
               returnval() = fitsky(dataRecord(), pixelMaskRecord(), convergedRecord(), 
                                    regionRecord(), maskRecord(),
                                    modelRecord(), estimateRecord(), fixedMaskRecord(),
                                    includeRecord(), excludeRecord(), fitItRecord(),
                                    deconvolveItRecord(), listRecord());
	    }
        }
    break;
    case FITALLPROFILES:
        {
	    Parameter<GlishRecord> region(inputRecord, "region",
                                          ParameterSet::In);
	    Parameter<String> outFit(inputRecord, "fit", ParameterSet::In);
	    Parameter<String> outResid(inputRecord, "resid", ParameterSet::In);
	    Parameter<String> sigma(inputRecord, "sigma", ParameterSet::In);
//
            Parameter<Int> nGauss(inputRecord, "ngauss", ParameterSet::In);
            Parameter<Index> axis(inputRecord, "axis", ParameterSet::In);
	    Parameter<String> mask(inputRecord, "mask", ParameterSet::In);
	    Parameter<Int> poly(inputRecord, "poly", ParameterSet::In);
//
	    if (runMethod) {
               fitAllProfiles (region(), mask(), nGauss(), poly(), axis(), 
                               sigma(), outFit(), outResid());
	    }
        }
    break;
    case FITPROFILE:
        {
	    Parameter<Vector<Float> > values(inputRecord, "values",
                                             ParameterSet::Out);
	    Parameter<Vector<Float> > resid(inputRecord, "resid",
                                            ParameterSet::Out);
	    Parameter<GlishRecord> region(inputRecord, "region",
                                          ParameterSet::In);
	    Parameter<String> sigma(inputRecord, "sigma", ParameterSet::In);
//
	    Parameter<GlishRecord> estimate(inputRecord, "estimate",
                                            ParameterSet::In);
            Parameter<Int> nMax(inputRecord, "nmax", ParameterSet::In);
            Parameter<Int> baseline(inputRecord, "baseline", ParameterSet::In);
            Parameter<Index> axis(inputRecord, "axis", ParameterSet::In);
	    Parameter<String> mask(inputRecord, "mask",
                                   ParameterSet::In);
	    Parameter<Bool> fitIt(inputRecord, "fit", ParameterSet::In);
//
	    Parameter<GlishRecord> returnVal(inputRecord, "returnval",
                                             ParameterSet::Out);

	    if (runMethod) {
               returnVal() = fitProfile (values(), resid(), region(), 
                                         mask(), estimate(), nMax(), baseline(), axis(), 
                                         fitIt(), sigma());
	    }
        }
    break;
    case FITPOLYNOMIAL:
        {
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    Parameter<GlishRecord> region(inputRecord, "region",
                                          ParameterSet::In);
	    Parameter<String> outFit(inputRecord, "outfit", ParameterSet::In);
	    Parameter<String> outResid(inputRecord, "outresid", ParameterSet::In);
	    Parameter<String> sigma(inputRecord, "sigma", ParameterSet::In);
//
            Parameter<Int> baseline(inputRecord, "baseline", ParameterSet::In);
            Parameter<Index> axis(inputRecord, "axis", ParameterSet::In);            
            Parameter<Bool> overwrite(inputRecord, "overwrite", ParameterSet::In);            
	    Parameter<String> mask(inputRecord, "mask",
                                   ParameterSet::In);
//
	    if (runMethod) {
               returnval() = fitPolynomial (axis(), region(), mask(), baseline(), 
                                            sigma(), outFit(), outResid(), overwrite());
	    }
        }

    break;
    case MASKHANDLER:
        {
            Parameter<Vector<String> > namesIn(inputRecord, "inputnames", ParameterSet::In); 
            Parameter<String> opRecord(inputRecord, "op", ParameterSet::In); 
            Parameter<Bool> outputRec(inputRecord, "output", ParameterSet::Out); 
            Parameter<Vector<String> > namesOut(inputRecord, "outputnames", ParameterSet::Out); 
	    if (runMethod) {
               maskHandler(namesOut(), outputRec(), namesIn(), opRecord());
	    }
        }
    break;
    case HISTORY:
        {
	    Parameter<Vector<String> > returnval(inputRecord, "returnval",
                                                 ParameterSet::Out);
            Parameter<Bool> list(inputRecord, "list", ParameterSet::In); 
	    if (runMethod) {
               returnval() = history(list());
            }
        }
    break;
    case SETHISTORY:
	{
	    Parameter<Vector<String> > history(inputRecord, "history",  ParameterSet::In);
	    if (runMethod) {
               setHistory(history());
	    }
	}
    break;
    case SEPCONVOLVE:
        {
            UnitMap::putUser("pix",UnitVal(1.0), "pixel units");
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
					        ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
                                         ParameterSet::In);
	    Parameter<Vector<String> > kernels(inputRecord, "types",
						ParameterSet::In);
	    Parameter<Vector<Index> > smoothaxes(inputRecord, "axes",
						  ParameterSet::In);
	    Parameter<Vector<Quantum<Double> > > kernelwidths(inputRecord, "widths",
						     ParameterSet::In);
            Parameter<Bool> autoScale(inputRecord, "autoscale", ParameterSet::In); 
            Parameter<Double> scale(inputRecord, "scale", ParameterSet::In); 
	    Parameter<String> outfile(inputRecord, "outfile",
				  ParameterSet::In);
            Parameter<Bool> overwrite(inputRecord, "overwrite", ParameterSet::In); 
	    if (runMethod) {
		returnval() = separableConvolution(regionRecord(), maskRecord(),
                                                   smoothaxes(), kernels(),
                                                   kernelwidths(), autoScale(),
                                                   scale(), outfile(), overwrite());
	    }
        }
    break;
    case CONVOLVE:
        {
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
					        ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
                                         ParameterSet::In);
	    Parameter<Array<Float> > kernelArray(inputRecord, "kernelarray",
						ParameterSet::In);
	    Parameter<String> kernelFile(inputRecord, "kernelfilename",
						ParameterSet::In);
	    Parameter<String> outfile(inputRecord, "outfile",
				  ParameterSet::In);
            Parameter<Bool> autoScale(inputRecord, "autoscale", ParameterSet::In); 
            Parameter<Double> scale(inputRecord, "scale", ParameterSet::In); 
	    Parameter<Bool> overwrite(inputRecord, "overwrite",
				  ParameterSet::In);
	    if (runMethod) {
		returnval() = convolve(kernelArray(), kernelFile(), regionRecord(),
                                       maskRecord(), outfile(), overwrite(),
                                       autoScale(), scale());
	    }
        }
    break;
    case LOCK:
        {
	    Parameter<Bool> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    Parameter<Bool> locker(inputRecord, "read",
                                   ParameterSet::In);
	    Parameter<Int> nattempts(inputRecord, "nattempts",
                                     ParameterSet::In);
	    if (runMethod) {
		returnval() = lock(locker(), nattempts());
	    }
        }
    break;
    case UNLOCK:
        {
	    if (runMethod) {
		unlock();
	    }
        }
    break;
    case SETIMAGE:
	{
	    Parameter<Bool>
		setValueRecord(inputRecord, "setpixels", ParameterSet::In);
	    Parameter<String>
		valueRecord(inputRecord, "pixels", ParameterSet::In);
	    Parameter<Bool>
		setMaskRecord(inputRecord, "setmask", ParameterSet::In);
	    Parameter<Bool>
		maskRecord(inputRecord, "pixelmask", ParameterSet::In);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
					        ParameterSet::In);
            Parameter<Bool> listBoxRecord(inputRecord, "list",
                                          ParameterSet::In);
	    Parameter<GlishRecord> regionsRecord(inputRecord, "regions",
					   ParameterSet::In);

	    if (runMethod) {
               set(setValueRecord(), valueRecord(), setMaskRecord(), 
                   maskRecord(), regionRecord(), listBoxRecord(), regionsRecord());
	    }
	}
    break;
    case REPLACEMASKEDPIXELS:
	{
	    Parameter<String>
		pixelsRecord(inputRecord, "pixels", ParameterSet::In);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
					        ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
                                         ParameterSet::In);
            Parameter<Bool> listBoxRecord(inputRecord, "list",
                                          ParameterSet::In);
            Parameter<Bool> updateMaskRecord(inputRecord, "update",
                                              ParameterSet::In);
	    Parameter<GlishRecord> regionsRecord(inputRecord, "regions",
					   ParameterSet::In);
	    if (runMethod) {
               replaceMaskedPixels(pixelsRecord(), regionRecord(), maskRecord(),
                                   listBoxRecord(), updateMaskRecord(),
                                   regionsRecord());
	    }
	}
    break;
    case FFT:
	{
	    Parameter<String> realRecord(inputRecord, "real", ParameterSet::In); 
            Parameter<String> imagRecord(inputRecord, "imag", ParameterSet::In);
	    Parameter<String> ampRecord(inputRecord, "amp", ParameterSet::In); 
            Parameter<String> phaseRecord(inputRecord, "phase", ParameterSet::In);
            Parameter<Vector<Index> > axesRecord(inputRecord, "axes", ParameterSet::In);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
                                                ParameterSet::In);
            Parameter<String> maskRecord(inputRecord, "mask", ParameterSet::In);
	    if (runMethod) {
               fft(realRecord(), imagRecord(), ampRecord(), phaseRecord(),
                   axesRecord(), regionRecord(), maskRecord());
	    }
	}
    break;
    case HASLOCK:
	{
	    Parameter<Vector<Bool> > returnval(inputRecord, "returnval",
                                               ParameterSet::Out);
	    if (runMethod) {
               returnval() = hasLock();
	    }
	}
    break;
    case MODIFY:
        {
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
                                                ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
                                         ParameterSet::In);
	    Parameter<Vector<SkyComponent> >
		modelRecord(inputRecord, "model", ParameterSet::In);
	    Parameter<Bool> subRecord(inputRecord, "subtract", ParameterSet::In);
	    Parameter<Bool> listRecord(inputRecord, "list", ParameterSet::In);
	    if (runMethod) {
               modify(modelRecord(), regionRecord(), maskRecord(), 
                      subRecord(), listRecord());
	    }
        }
    break;
    case  REBIN:
        {
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    Parameter<Vector<Int> > factors(inputRecord, "factors",
					     ParameterSet::In);
	    Parameter<String> outfile(inputRecord, "outfile",
                                      ParameterSet::In);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
                                                ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
                                                ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite", ParameterSet::In);
	    Parameter<Bool> dropDeg (inputRecord, "dropdeg", ParameterSet::In);
	    if (runMethod) {
               returnval() = rebin (outfile(), factors(),  regionRecord(), 
                                    maskRecord(), overwrite(), dropDeg());
	    }
	}
    break;
    case  REGRID:
        {
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    Parameter<GlishRecord> coordsRecord(inputRecord, "csys",
                                                ParameterSet::In);
	    Parameter<Vector<Int> > shape(inputRecord, "shape",
					     ParameterSet::In);
	    Parameter<String> outfile(inputRecord, "outfile",
                                      ParameterSet::In);
	    Parameter<String> method(inputRecord, "method", ParameterSet::In);
	    Parameter<Vector<Index> > pixelAxes(inputRecord, "axes",
                                                ParameterSet::In);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
                                                ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
                                                ParameterSet::In);
	    Parameter<Int> dorefRecord(inputRecord, "doref", ParameterSet::In);
	    Parameter<Bool> dropDegRecord(inputRecord, "dropdeg", ParameterSet::In);
	    Parameter<Bool> replicateRecord(inputRecord, "replicate", ParameterSet::In);
	    Parameter<Int> decimateRecord(inputRecord, "decimate", ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite", ParameterSet::In);
	    Parameter<Bool> forceRegrid(inputRecord, "force", ParameterSet::In);
	    Parameter<Int> dbg(inputRecord, "dbg", ParameterSet::In);
	    if (runMethod) {
               returnval() = regrid(outfile(), shape(), coordsRecord(), 
                                    method(), pixelAxes(), regionRecord(), 
                                    maskRecord(), dorefRecord(), dropDegRecord(), 
                                    decimateRecord(), replicateRecord(), 
                                    overwrite(), forceRegrid(), dbg());
	    }
	}
    break;
    case  ROTATE:
        {
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    Parameter<Quantum<Double> > pa(inputRecord, "pa",
   				           ParameterSet::In);
	    Parameter<Vector<Int> > shape(inputRecord, "shape",
					     ParameterSet::In);
	    Parameter<String> outfile(inputRecord, "outfile",
                                      ParameterSet::In);
	    Parameter<String> method(inputRecord, "method", ParameterSet::In);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
                                                ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
                                                ParameterSet::In);
	    Parameter<Bool> replicateRecord(inputRecord, "replicate", ParameterSet::In);
	    Parameter<Int> decimateRecord(inputRecord, "decimate", ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite", ParameterSet::In);
	    Parameter<Int> dbg(inputRecord, "dbg", ParameterSet::In);
	    if (runMethod) {
               returnval() = rotate(outfile(), shape(), pa(), 
                                    method(), regionRecord(), 
                                    maskRecord(),
                                    decimateRecord(), replicateRecord(), 
                                    overwrite(), dbg());
	    }
	}
    break;
    case ISPERSISTENT:
        {
	    Parameter<Bool> returnval(inputRecord, "returnval",
                                      ParameterSet::Out);
	    if (runMethod) {
               returnval() = isPersistent();
	    }
	}
    break;
    case CALCMASK:
	{
	    Parameter<Bool> returnval(inputRecord, "returnval",
                                      ParameterSet::Out);
	    Parameter<String> expr(inputRecord, "expr",
                                   ParameterSet::In);
	    Parameter<GlishRecord> regionsRecord(inputRecord, "regions",
					   ParameterSet::In);
	    Parameter<String> name(inputRecord, "name",
                                   ParameterSet::In);
	    Parameter<Bool> def(inputRecord, "default",
                                   ParameterSet::In);
	    if (runMethod) {
               returnval() = calcMask(expr(), regionsRecord(), 
                                      name(), def());
	    }
	}
    break;
    case BRIGHTNESSUNIT:
	{
	    Parameter<String> returnval(inputRecord, "returnval",
                                      ParameterSet::Out);
	    if (runMethod) {
               returnval() = brightnessUnit();
	    }
	}
    break;
    case SETBRIGHTNESSUNIT:
	{
	    Parameter<String> unit(inputRecord, "unit", ParameterSet::In);
	    if (runMethod) {
               setBrightnessUnit(unit());
	    }
	}
    break;
    case RESTORINGBEAM:
	{
	    Parameter<GlishRecord> returnval(inputRecord, "returnval",
                                      ParameterSet::Out);
	    if (runMethod) {
               returnval() = restoringBeam();
	    }
	}
    break;
    case SETRESTORINGBEAM:
	{
	    Parameter<GlishRecord> beam(inputRecord, "beam", ParameterSet::In);
	    Parameter<Bool> deleteIt(inputRecord, "delete", ParameterSet::In);
	    Parameter<Bool> log(inputRecord, "log", ParameterSet::In);
	    if (runMethod) {
               setRestoringBeam(beam(), deleteIt(), log());
	    }
	}
    break;
    case CONVOLVE2D:
        {
            UnitMap::putUser("pix",UnitVal(1.0), "pixel units");
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
					        ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
                                         ParameterSet::In);
	    Parameter<String> kernel(inputRecord, "type",
						ParameterSet::In);
	    Parameter<Vector<Index> > axes(inputRecord, "axes",
   				           ParameterSet::In);
	    Parameter<Quantum<Double> > majorAxis(inputRecord, "major",
					     ParameterSet::In);
	    Parameter<Quantum<Double> > minorAxis(inputRecord, "minor",
					     ParameterSet::In);
	    Parameter<Quantum<Double> > pa(inputRecord, "pa",
   				           ParameterSet::In);
            Parameter<Bool> autoScale(inputRecord, "autoscale", ParameterSet::In); 
            Parameter<Double> scale(inputRecord, "scale", ParameterSet::In); 
	    Parameter<String> outfile(inputRecord, "outfile",
				  ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite",
				  ParameterSet::In);
	    if (runMethod) {
		returnval() = convolve2D(regionRecord(), maskRecord(), axes(), kernel(),
   				         majorAxis(), minorAxis(), pa(), 
                                         autoScale(), scale(), 
                                         outfile(), overwrite());
	    }
        }
    break;
    case DECONVOLVECOMPONENTLIST:
        {
	    Parameter<Vector<SkyComponent> >
		in(inputRecord, "list", ParameterSet::In);
	    Parameter<Vector<SkyComponent> > returnval(inputRecord, "returnval",
                                              ParameterSet::Out);
	    if (runMethod) {
               returnval() = deconvolveComponentList(in());
	    }
        }
    break;
    case DECOMPOSE:
        {
	    Parameter<GlishRecord> returnval(inputRecord, "returnval",
                                             ParameterSet::Out);
	    Parameter<GlishRecord> region(inputRecord, "region", ParameterSet::In);
	    Parameter<String> mask(inputRecord, "mask", ParameterSet::In);
            Parameter<Bool> simple(inputRecord, "simple", ParameterSet::In);
	    Parameter<Float> threshold(inputRecord, "threshold", ParameterSet::In);
            Parameter<Int> nContour(inputRecord, "ncontour", ParameterSet::In);
            Parameter<Int> minRange(inputRecord, "minrange", ParameterSet::In);
            Parameter<Int> nAxis(inputRecord, "naxis", ParameterSet::In);
            Parameter<Bool> fit(inputRecord, "fit", ParameterSet::In);
            Parameter<Float> maxrms(inputRecord, "maxrms", ParameterSet::In);
            Parameter<Int> maxRetry(inputRecord, "maxretry", ParameterSet::In);
            Parameter<Int> maxIter(inputRecord, "maxiter", ParameterSet::In);
            Parameter<Float> convCriteria(inputRecord, "convcriteria", ParameterSet::In);
//
	    if (runMethod) {
               returnval() = decompose(region(), mask(), simple(), threshold(),
                                       nContour(), minRange(), nAxis(), fit(), maxrms(), 
                                       maxRetry(), maxIter(), convCriteria());
 
	    }
        }
    break;
    case FINDSOURCES:
        {
	    Parameter<Int> nMax(inputRecord, "nmax", ParameterSet::In);
	    Parameter<Double> cutoff(inputRecord, "cutoff", ParameterSet::In);
	    Parameter<Bool> absFind(inputRecord, "absfind", ParameterSet::In);
	    Parameter<Vector<SkyComponent> > returnval(inputRecord, "returnval",
                                                       ParameterSet::Out);
	    Parameter<GlishRecord> region(inputRecord, "region", ParameterSet::In);
	    Parameter<String> mask(inputRecord, "mask", ParameterSet::In);
	    Parameter<Bool> point(inputRecord, "point", ParameterSet::In);
	    Parameter<Int> width(inputRecord, "width", ParameterSet::In);
	    if (runMethod) {
               returnval() = findSources(nMax(), cutoff(), absFind(), 
                                         region(), mask(), point(), width());
	    }
        }
    break;
    case PIXELVALUE:
        {
	    Parameter<Quantum<Double> > value(inputRecord, "value", ParameterSet::Out);
	    Parameter<Bool> mask(inputRecord, "mask", ParameterSet::Out);
	    Parameter<Bool> offImage(inputRecord, "offimage", ParameterSet::Out);
	    Parameter<Vector<Index> > pos(inputRecord, "pos", ParameterSet::InOut);
	    if (runMethod) {
                pixelValue (offImage(), value(), mask(), pos());
	    }
        }
    break;
    case ADDDEGAXES:
        {
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    Parameter<Bool> direction(inputRecord, "direction", ParameterSet::In);
	    Parameter<Bool> spectral(inputRecord, "spectral", ParameterSet::In);
	    Parameter<String> stokes(inputRecord, "stokes", ParameterSet::In);
	    Parameter<Bool> linear(inputRecord, "linear", ParameterSet::In);
	    Parameter<Bool> tabular(inputRecord, "tabular", ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite", ParameterSet::In);
	    if (runMethod) {
                returnval() = addDegenerateAxes (outfile(), direction(), 
                                                 spectral(), stokes(), 
                                                 linear(), tabular(),
                                                 overwrite());
	    }
        }
    break;
    case ADDNOISE:
        {
	    Parameter<GlishRecord> region(inputRecord, "region", ParameterSet::In);
	    Parameter<String> type(inputRecord, "type", ParameterSet::In);
	    Parameter<Vector<Double> > pars(inputRecord, "pars", ParameterSet::In);
	    Parameter<Bool> zeroIt(inputRecord, "zero", ParameterSet::In);
	    if (runMethod) {
                addNoise (region(), type(), pars(), zeroIt());
	    }
        }
    break;
    case MAXFIT:
        {
	    Parameter<SkyComponent> sky(inputRecord, "sky",
                                        ParameterSet::Out);
	    Parameter<Vector<Double> > absPix(inputRecord, "abspixel",
                                        ParameterSet::Out);
	    Parameter<GlishRecord> region(inputRecord, "region", ParameterSet::In);
	    Parameter<Bool> absFind(inputRecord, "absfind", ParameterSet::In);
	    Parameter<Bool> point(inputRecord, "point", ParameterSet::In);
	    Parameter<Int> width(inputRecord, "width", ParameterSet::In);
	    if (runMethod) {
                maxfit (sky(), absPix(), region(), absFind(), point(), width());
	    }
        }
    break;
    case CONVERTFLUX:
        {
	    Parameter<Quantum<Double> > returnval(inputRecord, "returnval",
                                                  ParameterSet::Out);
	    Parameter<Quantum<Double> > value(inputRecord, "value",
                                        ParameterSet::In);
	    Parameter<Quantum<Double> > majorAxis(inputRecord, "major",
                                        ParameterSet::In);
	    Parameter<Quantum<Double> > minorAxis(inputRecord, "minor",
                                        ParameterSet::In);
	    Parameter<String> type(inputRecord, "type",
                                        ParameterSet::In);
	    Parameter<Bool> topeak(inputRecord, "topeak",
                                   ParameterSet::In);
	    if (runMethod) {
                returnval() = convertFlux(value(), majorAxis(), minorAxis(), 
                                          type(), topeak());
	    }
        }
    break;
    case  TWOPOINTCORRELATION:
        {
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
	    Parameter<String> outfile(inputRecord, "outfile",
                                      ParameterSet::In);
	    Parameter<Vector<Index> > pixelAxes(inputRecord, "axes",
                                                ParameterSet::In);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
                                                ParameterSet::In);
	    Parameter<String> maskRecord(inputRecord, "mask",
                                                ParameterSet::In);
	    Parameter<String> methodRecord(inputRecord, "method",
                                           ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite", ParameterSet::In);
	    if (runMethod) {
               returnval() = twoPointCorrelation (outfile(), regionRecord(), 
                                                  maskRecord(), pixelAxes(), 
                                                  methodRecord(), overwrite());
	    }
	}
    break;
    case  MAKECOMPLEX:
        {
	    Parameter<String> outFile(inputRecord, "outfile",
                                      ParameterSet::In);
	    Parameter<GlishRecord> regionRecord(inputRecord, "region",
                                                ParameterSet::In);
	    Parameter<String> imagFile(inputRecord, "imag", ParameterSet::In);
	    Parameter<Bool> overwrite(inputRecord, "overwrite", ParameterSet::In);
	    if (runMethod) {
               makeComplex (outFile(), regionRecord(), 
                            imagFile(),  overwrite());
	    }
	}
    break;
    default:
	return error("No such method");
    }
    return ok();
}

