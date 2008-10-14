//# DOimage.h: this defines DOimage.h
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
//# $Id: DOimage.h,v 19.27 2006/08/31 23:37:57 gvandiep Exp $



#ifndef APPSGLISH_DOIMAGE_H
#define APPSGLISH_DOIMAGE_H

#include <casa/aips.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/AxesSpecifier.h>
#include <components/ComponentModels/ComponentType.h>
#include <lattices/LatticeMath/Fit2D.h>
#include <lattices/Lattices/LatticeExprNode.h>
#include <images/Images/ImageRegion.h>
#include <casa/IO/FileLocker.h>
#include <measures/Measures/Stokes.h>
#include <tasking/Tasking/ApplicationObject.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class AxesSpecifier;
class DirectionCoordinate;
class Index;
class LogIO;
class MDirection;
class MFrequency;
class MRadialVelocity;
class Random;
class SkyComponent;
class String;
class TwoSidedShape;
class Unit;
class GlishRecord;
template<class T> class Array;
template<class T> class Block;
template<class T> class Flux;
template<class T> class ImageInterface;
template<class T> class ImageStatistics;
template<class T> class ImageHistograms;
template<class T> class MaskedArray;
template<class T> class PagedImage;
template<class T> class Quantum;
template<class T> class SubLattice;
template<class T> class SubImage;
template<class T> class Vector;
} //# NAMESPACE CASA - END




// <summary> 
//  Implementation of the image DO functionality
// </summary>

// <use visibility=local>   or   <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
// </prerequisite>
//
// <etymology>
//  This implements the functionality for the image Distributed Object 
// </etymology>
//
// <synopsis>
//  The functionality that is bound to Glish and available via the
//  image module/DO is implemented here.
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// </motivation>
//
// <templating arg=T>
//    <li>
//    <li>
// </templating>
//
// <thrown>
//    <li>
//    <li>
// </thrown>
//
// <todo asof="yyyy/mm/dd">
//   <li> 
// </todo>

class image : public ApplicationObject
{
public:
// "image" constructor
   image(const String& fileName);

// "imagefromfits" constructor
   image(const String &imagefile, const String &fitsfile, 
         Index whichrep, Index whichhdu, Bool zeroblanks, 
         Bool overwrite, Bool oldParser);

// "imagefromarray" constructor
   image(const String &imagefile, const Array<Float> &pixels,
     	 const GlishRecord& coordinates, Bool doLinear, Bool log,
         Bool overwrite);

// "imagefromshape" constructor
   image(const String &outfile, const Vector<Int> &shape,
     	 const GlishRecord& coordinates, Bool doLinear, Bool log,
         Bool overwrite);

// "imageconcat" constructor
   image(const String& outfile, const Vector<String>& infiles, 
         Index axis, Bool relax, Bool tempClose, Bool overwrite);

// "imagecalc" constructor
   image(const String& outfile, const String& expr, Bool overwrite,
	 const GlishRecord& tempRegions);

// "imagefromimage" constructor
   image(const String& outfile, const String& infile, 
         const GlishRecord& glishRegion, const String& mask,
         Bool dropDegenerateAxes, Bool overwrite);

// copy constructor
   image(const image& other);

// ImageInterface constructor
   image(const ImageInterface<Float>& inImage);

// assignment
   image &operator=(const image& other);

// Destructor
   ~image();

// Get at underlying ImageInterface pointer.  Do not delete this.
   ImageInterface<Float>* imagePointer() const {return pImage_p;};

// Add degenerate axes
   ObjectID addDegenerateAxes (const String& outFile, Bool direction, Bool spectral,
                               const String& stokes, Bool linear, Bool tabular, 
                               Bool overwrite);

// Add noise to image
   void addNoise (const GlishRecord& glishRegion,
                  const String& type,
                  const Vector<Double>& pars,
                  Bool zeroIt);

// Get bounding box of a region
   GlishRecord boundingBox(const GlishRecord& glishRegion);

// Get/set brightness units
// <group>
   String brightnessUnit () const;
   void setBrightnessUnit (const String& units);
//   </group>

// Make a mask from a LEL expression
   Bool calcMask(const String& expr, const GlishRecord& regions,
                 const String& maskName, Bool makeDefault);

// Flush the image to disk and detach from the image file. All function
// calls after this will be a no-op.
   void close();

// Convert pean and integral flux density
   Quantum<Double> convertFlux (const Quantum<Double>& value,
                                const Quantum<Double>& majorAxis,
                                const Quantum<Double>& minorAxis,
                                const String& type,
                                Bool toPeak) const;

// Convolve image with supplied array or image
   ObjectID convolve (const Array<Float>& kernelArray,
                      const String& kernelFile,
                      const GlishRecord& glishRegion, 
                      const String& mask,
                      const String &out,
                      Bool overwrite, Bool autoScale, Double scale);

// 2D 'functional' convolution
   ObjectID convolve2D (const GlishRecord& glishRegion,
                        const String& mask,
                        const Vector<Index> &axes,
                        const String &kernel,
                        const Quantum<Double> & major,
                        const Quantum<Double> & minor,
                        const Quantum<Double>& pa,
                        Bool autoScale,
                        Double scale,
                        const String &outFile, Bool overwrite);

// Image calculator 
   Bool calc(const String& expr, const GlishRecord& tempRegions);

// Return CoordinateSYstem
   ObjectID coordSys(const Vector<Index>& pixelAxes) const;


// Deconvolve a component list from the restoring beam
   Vector<SkyComponent> deconvolveComponentList(const Vector<SkyComponent>& list) const;

// Decompose image into sources
   GlishRecord decompose (const GlishRecord& glishRegion, 
   		          const String& mask, Bool simple,
                          Float threshold, Int nContour, Int minRange,
                          Int nAxis, Bool fit, Float maxrms, Int maxRetry,
                          Int maxIter, Float convCriteria);


// Find (point) sources in plane
   Vector<SkyComponent> findSources (Int nMax, Double cutoff, Bool absFind,
                                     const GlishRecord& region, const String& mask,
                                     Bool point, Int width);

// FFT the sky
   void fft(const String& realOut, const String& imagOut,
            const String& ampOut, const String& phaseOut,
            const Vector<Index>& axes, const GlishRecord& region,
            const String& mask);

// Fit the Sky
   Vector<SkyComponent> fitsky(Array<Float>& pixels, Array<Bool>& pixelMask, 
                               Bool& converged, 
                               const GlishRecord& region,
                               const String& mask,
                               const Vector<String>& models,
                               const Vector<SkyComponent>& estimate,
                               const Vector<String>& parameterMasks,
                               const Vector<Float>& includerange,
                               const Vector<Float>& excluderange,
                               Bool fitIt, Bool deconvolveIt, Bool list);

// Fit a profile
   void fitAllProfiles (const GlishRecord& glishRegion,
                        const String& mask,       
                        Int nGauss, Int baseline, Index axis,                                  
                        const String& sigmaFileName,       
                        const String& outFitFileName,       
                        const String& outResidFileName);

   GlishRecord fitProfile (Vector<Float>& values, 
                           Vector<Float>& resid, 
                           const GlishRecord& glishRegion,
                           const String& mask, const GlishRecord& estimate,
                           Int nMax, Int baseline, Index axis, Bool fitIt, 
                           const String& sigmaFileName);

// Recover pixels from box into an array
   void getchunk(Array<Float>& pixels,
                 Array<Bool>& pixelMask,
                 const Vector<Index>& blc,
                 const Vector<Index>& trc,
                 const Vector<Int>& inc,
                 const Vector<Index>& axes,
                 Bool listBoundingBox,
                 Bool dropDegenerateAxes,
                 Bool getMask) const;

// Recover pixels from region into an array
   void getRegion(Array<Float>& data, 
                  Array<Bool>& pixelMask,
                  const GlishRecord& glishRegion,
                  const Vector<Index>& axes,
                  const String& mask,
                  Bool listBoundingBox=False,
                  Bool removeDegenerateAxes=False,
                  Bool getPixels=True, Bool getMask=True);

// Recover pixels from box into an array
   void getSlice1D (Vector<Float>& xPos, Vector<Float>& yPos,
                    Vector<Float>& distance,
                    Vector<Float>& pixels,
                    Vector<Bool>& pixelMask,
                    const Vector<Index>& coord,
                    const Vector<Index>& axes,
                    const Vector<Double>& x,
                    const Vector<Double>& y,
                    const String& method,
                    Int nPts) const;

// Hanning smooth an axis
   ObjectID hanning(const GlishRecord& regionRecord, const String& mask,
                    Index axis, const String& outfile, Bool drop, Bool overwrite);

// hasLock (read in 0 and write in 1)
   Vector<Bool> hasLock() const;

// Display image pixel histogram.
   void histograms(GlishRecord &histout,
                   const Vector<Index> &axes, 
                   const GlishRecord& regionRecord,
                   const String& mask,
                   Int nbins, 
                   const Vector<Float> &includepix, 
                   Bool gauss,
                   Bool cumu, 
                   Bool log, 
                   Bool list,
                   const String &pgdevice, 
                   Int nx, 
                   Int ny,
                   const Vector<Int>& size,
                   Bool forceNewStorageImage,
                   Bool forceStorageOnDisk);

// List history to logger
// <group>   
   Vector<String> history(Bool list) const;
   void setHistory(const Vector<String>& history);
// </group>

// Insert this image into an empty one
   void insertImage(const String &infile, 
                    const GlishRecord& region,
                    const Vector<Double>& locate,
                    Bool doRef, Int dbg);

// Is image persistent ?
   Bool isPersistent () const;

// Set a lock.  Number of attempts defaults to try for ever
   Bool lock (Bool readLock=True, Int nattempts=0);

// Make a Complex image
   void makeComplex (const String& outFile, const GlishRecord& region, 
                     const String& imagFile, Bool overWrite);

// Manipulate the mask.  
   void maskHandler (Vector<String>& namesOut, Bool& hasOutput, 
                     Vector<String>& namesIn, const String& op);

// Maxfit
   void maxfit (SkyComponent& sky, Vector<Double>& absPixel,
                const GlishRecord& glishRegion, Bool absFind,
                Bool doPoint, Int width);

// Modify image by a componentlist model
   void modify(const Vector<SkyComponent>& estimate,
               const GlishRecord& glishRegion,
               const String& mask,
               Bool subtract, Bool list);

// Perform moment analysis on the image.
   ObjectID moments(const Vector<Int> &whichmoments, Index axis,
                    const GlishRecord& glishRegion, const String& mask,
                    const Vector<String>& method,  const Vector<Index>& smoothaxes,
                    const Vector<String>& kernels, 
                    const Vector<Quantum<Double> >& kernelwidths,
                    const Vector<Float>& includepix, 
                    const Vector<Float>& excludepix,
                    Float peaksnr, Float stddev,
                    const String& velocityType, const String &out,
                    const String &smoothout, const String &pgdevice, 
                    Int nx, Int ny, Bool yind, Bool overwrite, 
                    Bool removeAxis);

// File name.  By default include full path. Path stripped on request.
   String name(const Bool stripPath=False) const;

// Close the current image, and replace it with the supplied image.
   void open(const String& infile);

// Get pixel value and mask at location
   void pixelValue (Bool& offImage, Quantum<Double>& value, Bool& mask, Vector<Index>& pos) const;

// Fit polynomials to profiles and subtract
   ObjectID fitPolynomial (Index axis, const GlishRecord& glishRegion,
                           const String& mask, Int baseline, 
                           const String& sigmaFileName,
                           const String& outFitFileName,
                           const String& outResidFileName, 
                           Bool overwrite);

// Put pixels from box into image
   void putchunk(const Array<Float> &pixels,
                 const Vector<Index> &blc,
                 const Vector<Int> &inc,
                 Bool listBoundingBox, Bool replicate);

// If blc is <0 or otherwise invalid, put starting at the beginning
   void putRegion(const Array<Float> &data, 
                  const Array<Bool> &mask, 
                  const GlishRecord& glishRegion,
                  Bool listBoundingBox,
                  Bool useMask, Bool replicate);

// Rebin
   ObjectID rebin (String& outfile, 
                   const Vector<Int>& factors,
                   const GlishRecord& glishRegion,
                   const String& mask,
                   Bool overwrite, Bool dropDegenerateAxes);

// Regrid
   ObjectID regrid (String& outfile, 
                    const Vector<Int> &shape,
                    const GlishRecord& coordinates,
                    const String& method, 
                    const Vector<Index>& pixelAxes,
                    const GlishRecord& glishRegion,
                    const String& mask,
                    Bool doRefChange, Bool dropDegenerateAxes, 
                    Int decimate, Bool replicate, Bool overwrite, 
                    Bool forceRegrid, Int dbg);

// Rotate Direction or Linear coordinate by regridding
   ObjectID rotate (String& outFile, 
		    const Vector<Int>& shape,
		    const Quantum<Double>& pa,
		    const String& methodU, 
		    const GlishRecord& glishRegion,
		    const String& mask,
		    Int decimate, Bool replicate, 
		    Bool overwrite, Int dbg);

// Replace pixels masked bad with some value 
   void replaceMaskedPixels(const String& pixels, 
                            const GlishRecord& glishRegion,
                            const String& mask,
                            Bool listBoundingBox,
                            Bool updateMask,
                            const GlishRecord& tempRegions);

// Get/set restoring beam
// <group>
   GlishRecord restoringBeam () const;
   void setRestoringBeam (const GlishRecord& beam, Bool deleteIt,
                          Bool log);
// </group>


// Do separable convolution on the image.
   ObjectID separableConvolution (const GlishRecord& glishRegion,
                                  const String& mask,
                                  const Vector<Index> &smoothaxes,
                                  const Vector<String> &kernels,
                                  const Vector<Quantum<Double> >& kernelwidths,
                                  Bool autoScale, Double scale,
                                  const String &out, Bool overwrite);

// Set all pixels in the region to the given value
   void set(Bool setPixels, 
            const String& pixels, 
            Bool setMask, 
            Bool mask,
            const GlishRecord& glishRegion,
            const Bool listBoundingBox,
            const GlishRecord& tempRegions);

// Return the image shape
   Vector<Int> shape() const;

// Set CoordinateSystem
   void setCoordinateSystem (const GlishRecord& coordinates);

// Get/Set miscellaneous "header" information in the image.
// <group>
   GlishRecord miscinfo() const;
   Bool setmiscinfo(const GlishRecord &newinfo);
// </group>

// Calculate, display, and get statistics from image.
   void statistics(GlishRecord &statsout,
                   const Vector<Index> &axes,
                   const GlishRecord& regionRecord,
                   const String& mask,
                   const Vector<String> &plotstats, 
                   const Vector<Float> &includepix,
                   const Vector<Float> &excludepix,
                   Bool list,
                   const String &pgdevice, 
                   Int nx, 
                   Int ny, 
                   Bool forceNewStorageImage,
                   Bool forceStorageOnDisk, 
                   Bool robust, Bool verbose);

// Two point correlation
   ObjectID twoPointCorrelation (const String &outfile,
                                 const GlishRecord& regionRecord,
                                 const String& mask, const Vector<Index>& axes,
                                 const String& method, Bool overwrite);

// Subimage operation
   ObjectID subimage(const String &outfile,
                     const GlishRecord& regionRecord,
                     const String& mask,
                     Bool dropDegenerateAxes, Bool overwrite,
                     Bool list);

// Return a record with various image summary information.
// Also writes the information in a log message if <src>list=True</src>.  
   Vector<String> summary(GlishRecord &header, 
                          const String& velocityType,
                          Bool list, Bool pixelOrder) const;

// Make a fits file named 'filename', will not overwrite.
   void tofits(const String &filename, Bool velocity, Bool optical,
	       Int bitpix, Float minpix, Float maxpix, 
               const GlishRecord& region, const String& mask,
               Bool overwrite, Bool dropDeg, Bool degLast);

// Unlock
   void unlock();

// Stuff needed for distributing this class
   virtual String className() const;
   virtual Vector<String> methods() const;
   virtual Vector<String> noTraceMethods() const;

// If your object has more than one method
   virtual MethodResult runMethod(uInt which, 
                                  ParameterSet &inputRecord,
                                  Bool runMethod);

// Get the pointer from the string; either a new PagedImage or fished out of an Image tool
   static void getPointer (ImageInterface<Float>*& imagePointer, Bool& deleteIt,
                           const String& infile, LogIO& os);

private:

    ImageInterface<Float>* pImage_p;

// Having private version of IS and IH means that they will
// only recreate storage images if they have to

    ImageStatistics<Float>* pStatistics_p;
    ImageHistograms<Float>* pHistograms_p;
//
    IPosition last_chunk_shape_p;
    ImageRegion* pOldStatsRegionRegion_p;
    ImageRegion* pOldStatsMaskRegion_p;
    ImageRegion* pOldHistRegionRegion_p;
    ImageRegion* pOldHistMaskRegion_p;
    Bool oldStatsStorageForce_p, oldHistStorageForce_p;

// Center refpix apart from STokes
    void centreRefPix (CoordinateSystem& cSys, const IPosition& shape) const;

// Convert types
   ComponentType::Shape convertModelType (Fit2D::Types typeIn) const;

// Deconvolve from beam
   Bool deconvolveFromBeam(Quantum<Double>& majorFit,
                           Quantum<Double>& minorFit,
                           Quantum<Double>& paFit,
                           LogIO& os, const Vector<Quantum<Double> >& beam) const;

// Deconvolve SkyComponent from beam    
   SkyComponent deconvolveSkyComponent(LogIO& os, const SkyComponent& skyIn,
                                       const Vector<Quantum<Double> >& beam,
                                       const DirectionCoordinate& dirCoord) const;

// Delete private ImageStatistics and ImageHistograms objects
   void deleteHistAndStats();

// Make a dummy image header
   void dummyHeader(Vector<String> &axisNames,
                     Vector<Double> &referenceValues,
                     Vector<Double> &referencePixels,
                     Vector<Double> &deltas,
                     const Vector<Int> &shape) const;

// Convert a parameters vector to a SkyComponent
   SkyComponent encodeSkyComponent(LogIO& os, Double& fluxRatio,
                                   const ImageInterface<Float>& im,
                                   ComponentType::Shape modelType,
                                   const Vector<Double>& parameters,
                                   Stokes::StokesTypes stokes,
                                   Bool xIsLong, Bool deconvolveIt) const;


// Convert error parameters from pixel to world and insert in SkyComponent
   void encodeSkyComponentError (LogIO& os, 
                                 SkyComponent& sky,
                                 Double fluxRatio,
                                 const ImageInterface<Float>& subIm,
                                 const Vector<Double>& parameters,
                                 const Vector<Double>& errors,
                                 Stokes::StokesTypes stokes,
                                 Bool xIsLong) const;

// Hanning smooth a vector
   void hanning_smooth (Array<Float>& out,
                        Array<Bool>& maskOut,
                        const Vector<Float>& in,
                        const Array<Bool>& maskIn,
                        Bool isMasked) const;

// Make a new image with given CS
   Bool make_image(String &error,
                   const String &image, 
                   const CoordinateSystem& cSys,
                   const IPosition& shape,
                   LogIO& os, Bool log=True, Bool overwrite=False);

// If file name empty make TempImage (allowTemp=T) or do nothing.
// Otherwise, make a PagedImage from file name and copy mask and 
// misc from inimage.   Returns T if image made, F if not 
   Bool makeExternalImage (PtrHolder<ImageInterface<Float> >& image,
                           const String& fileName,
                           const CoordinateSystem& cSys,
                           const IPosition& shape,
                           const ImageInterface<Float>& inImage,
                           LogIO& os, Bool overwrite=False,
                           Bool allowTemp=False, Bool copyMask=True);


// Make a mask and define it in the image. 
   Bool makeMask(ImageInterface<Float>& out, String& maskName, Bool init, 
                 Bool makeDefault, LogIO& os, Bool list=True) const;

// Convert region GlishRecord to an ImageRegion pointer
   ImageRegion* makeRegionRegion(ImageInterface<Float>& inImage,
                                 const GlishRecord& glishRegion, 
                                 const Bool listBoundingBox, 
                                 LogIO& logger);

// Make ImageRegion from 'mask' string
   ImageRegion* makeMaskRegion (const String& mask) const;

// Make a SubImage from a region and a WCLELMask string
   SubImage<Float> makeSubImage (ImageRegion*& pRegionRegion, ImageRegion*& pMaskRegion,
                                 ImageInterface<Float>& inImage,
                                 const GlishRecord& glishRegion, const String& mask,
                                 Bool listBoundingBox, LogIO& os,
                                 Bool writableIfPossible,
                                 const AxesSpecifier& axesSpecifier=AxesSpecifier());

// See if the combination of the 'region' and 'mask' ImageRegions have changed
   Bool haveRegionsChanged (ImageRegion* pNewRegionRegion, ImageRegion* pNewMaskRegion, 
                            ImageRegion* pOldRegionRegion, ImageRegion* pOldMaskRegion) const;

// Convert a Glish record to a CoordinateSystem
   CoordinateSystem* makeCoordinateSystem(const GlishRecord& cSys, const IPosition& shape) const;

// Make a block of regions from a GlishRecord (filled in by substitute.g).
    void makeRegionBlock(PtrBlock<const ImageRegion*>& regions,
			 const GlishRecord& glishRegions,
			 LogIO& logger);

// Put beam into +x -> +y frame
   Vector<Quantum<Double> > putBeamInXYFrame (const Vector<Quantum<Double> >& beam,
                                               const DirectionCoordinate& dirCoord) const;

// Set the cache
    void set_cache(const IPosition &chunk_shape) const;

// Make an estimate for single parameter fit models
   Vector<Double> singleParameterEstimate (Fit2D& fitter,
                                           Fit2D::Types modelType,
                                           const MaskedArray<Float>& pixels,
                                           Float minVal, Float maxVal,
                                           const IPosition& minPos,
                                           const IPosition& maxPos,
                                           Stokes::StokesTypes stokes,
                                           const ImageInterface<Float>& im,
                                           Bool xIsLong, 
                                           LogIO& os) const;

// Prints an error message if the image DO is detached and returns True.
   Bool detached() const;

// Convert object-id's in the expression to LatticeExprNode objects.
// It returns a string where the object-id's are placed by $n.
// That string can be parsed by ImageExprParse.
// Furthermore it fills the string exprName with the expression
// where the object-id's are replaced by the image names.
// Note that an image name can be an expression in itself, so
// this string is not suitable for the ImageExprParse.
    String substituteOID (Block<LatticeExprNode>& nodes,
                          String& exprName,
                          const String& expr) const;

// Methods enum
   enum methods {ADDDEGAXES, ADDNOISE, BOUNDINGBOX, BRIGHTNESSUNIT,
                 CALC, CALCMASK, CLOSE, COORDSYS, CONVERTFLUX, CONVOLVE, CONVOLVE2D, 
                 DECOMPOSE, DECONVOLVECOMPONENTLIST, FINDSOURCES,
                 FFT, FITSKY, FITALLPROFILES, FITPROFILE, HASLOCK, LOCK, 
                 OPEN, GETCHUNK, GETREGION, GETSLICE, 
                 HANNING, HISTOGRAMS, HISTORY, INSERT, 
                 ISPERSISTENT, MAKECOMPLEX, MASKHANDLER, MAXFIT,
                 MISCINFO, MODIFY, MOMENTS, NAME, 
                 PIXELVALUE, FITPOLYNOMIAL, PUTCHUNK, PUTREGION,
                 REBIN, REGRID, ROTATE, REPLACEMASKEDPIXELS, RESTORINGBEAM,
                 SEPCONVOLVE, 
                 SETIMAGE, SETBRIGHTNESSUNIT, SETCOORDSYS,  SETMISCINFO,
                 SETHISTORY, SETRESTORINGBEAM,
                 SHAPE, STATISTICS, SUBIMAGE, SUMMARY, TOFITS, 
                 TWOPOINTCORRELATION, UNLOCK, 
                 NUM_METHODS};
//
   enum notrace_methods {NT_ADDDEGAXES, NT_ADDNOISE, NT_BOUNDINGBOX, NT_BRIGHTNESSUNIT, 
                         NT_CALCMASK, 
                         NT_CLOSE, NT_COORDSYS, NT_CONVERTFLUX,
                         NT_DECONVOLVECOMPONENTLIST, NT_FITPROFILE,
                         NT_HASLOCK, NT_LOCK, NT_OPEN, NT_GETCHUNK, NT_GETREGION,
                         NT_GETSLICE, NT_HISTORY, NT_ISPERSISTENT, NT_MAKECOMPLEX, 
                         NT_MASKHANDLER, NT_MAXFIT, NT_MISCINFO, NT_NAME, NT_PIXELVALUE, 
                         NT_PUTCHUNK, NT_PUTREGION,
                         NT_REPLACEMASKEDPIXELS, NT_RESTORINGBEAM,
                         NT_SETIMAGE, NT_SETBRIGHTNESSUNIT, 
                         NT_SETCOORDSYS, NT_SETMISCINFO, NT_SETHISTORY,
                         NT_SETRESTORINGBEAM, NT_SHAPE, NT_STATISTICS, 
                         NT_SUBIMAGE, NT_SUMMARY, NT_UNLOCK, 
                         NUM_NOTRACE_METHODS};
};


#endif
