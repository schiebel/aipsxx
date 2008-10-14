//# DOimager: defines classes for imager DO.
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
//# $Id: DOimager.h,v 19.17.8.1 2006/10/06 09:00:10 wyoung Exp $

#ifndef APPSGLISH_DOIMAGER_H
#define APPSGLISH_DOIMAGER_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <tasking/Tasking/Index.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Quanta/Quantum.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <measures/Measures/MRadialVelocity.h>

#include <synthesis/MeasurementComponents/CleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/BeamSquint.h>
#include <synthesis/MeasurementComponents/WFCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/ClarkCleanImageSkyModel.h>
#include <synthesis/MeasurementEquations/SkyEquation.h>
#include <synthesis/MeasurementEquations/Imager.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class MeasurementSet;
class File;
class PGPlotter;
class GlishRecord;
} //# NAMESPACE CASA - END


// <summary> Makes images from a MeasurementSet with the SkyEquation </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class="MeasurementSet">MeasurementSet</linkto>
//   <li> <linkto class="SkyEquation">SkyEquation</linkto>
//   <li> <linkto class="SkyModel">SkyModel</linkto>
// </prerequisite>
//
// <etymology>
// The name MUST have the 'DO' prefix as this class is derived from
// ApplicationObject, and hence is classified as a distributed object. For the
// same reason the rest of its name must be in lower case. This class is a
// simplified version of the ComponentList class.
// </etymology>
//
// <synopsis>
// This class is a container that allows many SkyComponents to be grouped
// together and manipulated as a group. In this respect this class is identical
// to the <linkto class="ComponentList">ComponentList</linkto> class. The user
// is encouraged to read the synopsis of that class for a general description
// of the capabilities of this class.
//
// This class is differs from the ComponentList class in the following ways:
// <ul>
// <li> All components are indexed starting at one. This means the first
//      component in this class is obtained by <src>component(1)</src> rather
//      than <src>component(0)</src> in the ComponentList class.
// <li> Copies of the components, rather than references, are returned to the
//      user. This means that this class needs a replace function whereas
//      ComponentList does not.
// <li> Components that have been removed from the list are stored in a
//      temporary place. In the ComponentList class once they are deleted they
//      are gone.
// <li> This class is derived from ApplicationObject and follows the AIPS++
//      conventions for "distributed objects". Hence the fuunctions in this
//      class can be made accessible from glish. 
// <li> This class can generate simulated components and add them to the list.
// </ul>
//
// There is a one-to-one correspondence between the functions in the glish
// componentlist object (see the AIPS++ User Reference manual) and functions in
// this class. This is make simplify the porting from glish to C++ of a glish
// script using the componentlist distributed object.
// </synopsis>
//
// <example>
// These examples are coded in the tDOcomponentlist.h file.
// <h4>Example 1:</h4>
// In this example a ComponentList object is created and used to calculate the
// ...
// <srcblock>
// </srcblock>
// </example>
//
// <motivation> 
// This class was written to make the componentlist classes usable from glish
// </motivation>
//
// <thrown>
// <li> AipsError - If an internal inconsistancy is detected, when compiled in 
// debug mode only.
// </thrown>
//
// <todo asof="1998/05/22">
//   <li> Nothing I hope. But I expect users will disagree.
// </todo>

class imager : public ApplicationObject
{
public:
  // "imager" ctor
  imager();
  
  // Construct an imager tool from a MeasurementSet and
  // a flag indicating whether compression of attached
  // calibration data columns is required
  imager(MeasurementSet &thems, Bool compress=False);
  imager(MeasurementSet &thems, PGPlotter& thePlotter, Bool compress=False);
  
  imager(const imager &other);
  imager &operator=(const imager &other);
  ~imager();
  
  // Close the current ms, and replace it with the supplied ms.
  // Optionally compress the attached calibration data
  // columns if they are created here.
  Bool open(MeasurementSet &thems, Bool compress=False);
  
  // Flush the ms to disk and detach from the ms file. All function
  // calls after this will be a no-op.
  Bool close();
  
  // Return the name of the MeasurementSet
  String name() const;
  
  // The following setup methods define the state of the imager.
  // <group>
  // Set image construction parameters
  Bool setimage(const Int nx, const Int ny,
		const Quantity& cellx, const Quantity& celly,
		const String& stokes,
                Bool doShift,
		const MDirection& phaseCenter, 
                const Quantity& shiftx, const Quantity& shifty,
		const String& mode, const Int nchan,
                const Int start, const Int step,
		const MRadialVelocity& mStart, const MRadialVelocity& mStep,
		const Vector<Int>& spectralwindowids, const Int fieldid,
		const Int facets, const Quantity& distance,
		const Float &paStep, const Float &pbLimit);
  
  // Set the data selection parameters
  Bool setdata(const String& mode, const Vector<Int>& nchan, 
	       const Vector<Int>& start,
	       const Vector<Int>& step, const MRadialVelocity& mStart,
	       const MRadialVelocity& mStep,
	       const Vector<Int>& spectralwindowids,
	       const Vector<Int>& fieldid,
	       const String& msSelect="", const String& msname="");
  
  // Set the processing options
  Bool setoptions(const String& ftmachine, const Int cache, const Int tile,
		  const String& gridfunction, const MPosition& mLocation,
		  const Float padding, const Bool usemodelcol=True, 
		  const Int wprojplanes=1,
		  const String& epJTableName="",
		  const Bool applyPointingOffsets=True,
		  const Bool doPointingCorrection=True,
		  const String& cfCacheDirName="");

  // Set the single dish processing options
  Bool setsdoptions(const Float scale, const Float weight, 
		    const Int convsupport=-1);

  // Set the voltage pattern
  Bool setvp(const Bool dovp,
	     const Bool defaultVP,
	     const String& vpTable,
	     const Bool doSquint,
	     const Quantity &parAngleInc,
	     const Quantity &skyPosThreshold,
	     String defaultTel="");

  // Set the scales to be searched in Multi Scale clean
  Bool setscales(const String& scaleMethod,          // "nscales"  or  "uservector"
		 const Int inscales,
		 const Vector<Float>& userScaleSizes);
  // Set the number of taylor series terms in the expansion of the
  // image as a function of frequency.
  Bool settaylorterms(const Int intaylor); 
      
  // </group>
  
  // Advise on suitable values
  Bool advise(const Bool takeAdvice, const Float amplitudeloss,
              const Quantity& fieldOfView,
	      Quantity& cell, Int& npixels, Int& facets,
	      MDirection& phaseCenter);

  // Output a summary of the state of the object
  Bool summary() const;
  

  // Return the state of the object as a string
  String state() const;
  
  //TO GO 
  // Return the image coordinates
  //   Bool imagecoordinates(CoordinateSystem& coordInfo);

  //TO GO
  // Return the image shape
  // IPosition imageshape() const;

  // Weight the MeasurementSet
  Bool weight(const String& algorithm, const String& rmode,
	      const Quantity& noise, const Double robust,
              const Quantity& fieldofview, const Int npixels);
  
  // Filter the MeasurementSet
  Bool filter(const String& type, const Quantity& bmaj, const Quantity& bmin,
	      const Quantity& bpa);
  
  // Apply a uvrange
  Bool uvrange(const Double& uvmin, const Double& uvmax);
  
  // Sensitivity
  Bool sensitivity(Quantity& pointsourcesens, Double& relativesens, Double& sumwt);
  
  // Make plain image
  Bool makeimage(const String& type, const String& imageName);

  // Make plain image: keep the complex image as well
  Bool makeimage(const String& type, const String& imageName,
	     const String& complexImageName);
  
  // Fill in a region of a mask
  Bool boxmask(const String& mask, const Vector<Int>& blc,
	       const Vector<Int>& trc, const Float value);

  // Clip on Stokes I
  Bool clipimage(const String& image, const Quantity& threshold);

  // Make a mask image
  Bool mask(const String& mask, const String& imageName,
	    const Quantity& threshold);
  
  // Restore
  Bool restore(const Vector<String>& model, const String& complist,
	       const Vector<String>& image, const Vector<String>& residual);

  // Setbeam
  Bool setbeam(const Quantity& bmaj, const Quantity& bmin, const Quantity& bpa);

  // Residual
  Bool residual(const Vector<String>& model, const String& complist,
	       const Vector<String>& image);

  // Approximate PSF
  Bool approximatepsf(const Vector<String>& model, const Vector<String>& psf);

  // Smooth
  Bool smooth(const Vector<String>& model, 
	      const Vector<String>& image, Bool usefit,
	      Quantity& bmaj, Quantity& bmin, Quantity& bpa,
	      Bool normalizeVolume);

  // Clean algorithm
  Bool clean(const String& algorithm,
	     const Int niter, 
	     const Float gain, 
	     const Quantity& threshold, 
	     const Bool displayProgress, 
	     const Vector<String>& model, const Vector<Bool>& fixed,
	     const String& complist,
	     const Vector<String>& mask,
	     const Vector<String>& restored,
	     const Vector<String>& residual);
  
  // MEM algorithm
  Bool mem(const String& algorithm,
	   const Int niter, const Quantity& sigma, 
	   const Quantity& targetflux,
	   const Bool constrainflux,
	   const Bool displayProgress, 
	   const Vector<String>& model, const Vector<Bool>& fixed,
	   const String& complist,
	   const Vector<String>& prior,
	   const Vector<String>& mask,
	   const Vector<String>& restored,
	   const Vector<String>& residual);
  
  // pixon algorithm
  Bool pixon(const String& algorithm,
	     const Quantity& sigma, 
	     const String& model);
  
  // NNLS algorithm
  Bool nnls(const String& algorithm, const Int niter, const Float tolerance,
	    const Vector<String>& model, const Vector<Bool>& fixed,
	    const String& complist,
	    const Vector<String>& fluxMask, const Vector<String>& dataMask,
	    const Vector<String>& restored,
	    const Vector<String>& residual);

  // Multi-field control parameters
  Bool setmfcontrol(const Float cyclefactor,
		    const Float cyclespeedup,
		    const Int stoplargenegatives, 
		    const Int stoppointmode,
		    const String& scaleType,
		    const Float  minPB,
		    const Float constPB,
		    const Vector<String>& fluxscale);
  
  // Feathering algorithm
  Bool feather(const String& image,
	       const String& highres,
	       const String& lowres,
	       const String& lowpsf);
  
  // Apply or correct for Primary Beam or Voltage Pattern
  Bool pb(const String& inimage,
	  const String& outimage,
	  const String& incomps,
	  const String& outcomps,
	  const String& operation,
	  const MDirection& pointngCenter,
	  const Quantity& pa,
	  const String& pborvp);

  // Make a linear mosaic of several images
  Bool linearmosaic(const String& mosaic,
		    const String& fluxscale,
		    const String& sensitivity,
		    const Vector<String>& images,
		    const Vector<Int>& fieldids);
  
  // Fourier transform the model and componentlist
  Bool ft(const Vector<String>& model, const String& complist,
	  Bool incremental=False);

  // Compute the model visibility using specified source flux densities
  Bool setjy(const Int fieldid, const Int spectralwindowid,
	     const Vector<Double>& fluxDensity, const String& standard);

  // Make an empty image
  Bool make(const String& model);


  // make a model from a SD image. 
  // This model then can be used as initial clean model to include the 
  // shorter spacing.
  Bool makemodelfromsd(const String& sdImage, const String& modelimage,
		       const String& lowPSF,
		       String& maskImage);


  // Clone an image
  Bool clone(const String& imageName, const String& newImageName);
  
  // Fit the psf
  Bool fitpsf(const String& psf, Quantity& mbmaj, Quantity& mbmin,
	      Quantity& mbpa);

  // Correct the visibility data (OBSERVED->CORRECTED)
  Bool correct(const Bool doparallactic, const Quantity& t);

  // Plot the uv plane
  Bool plotuv(const Bool rotate);

  // Plot the visibilities
  Bool plotvis(const String& type, const Int increment);

  // Plot the weights
  Bool plotweights(const Bool gridded, const Int increment);

  // Plot a summary
  Bool plotsummary();

  // Clip visibilities
  Bool clipvis(const Quantity& threshold);

  // Stuff needed for distributing this class
  virtual String className() const;
  virtual Vector<String> methods() const;
  virtual Vector<String> noTraceMethods() const;
  
  // If your object has more than one method
  virtual MethodResult runMethod(uInt which, ParameterSet &inputRecord, Bool runMethod);

protected:
  
  Imager *itsImager;
 
  // These should disappear if one uses the constructor to send in the 
  // PGplotter
  PGPlotter& getPGPlotter(Bool newPlotter=False);
  PGPlotter* pgplotter_p;


};

#endif



