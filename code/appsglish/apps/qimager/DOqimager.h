//# DOqimager: defines classes for qimager DO.
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
//# $Id: DOqimager.h,v 1.8 2004/11/30 17:50:09 ddebonis Exp $

#ifndef APPSGLISH_DOQIMAGER_H
#define APPSGLISH_DOQIMAGER_H

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
#include <synthesis/MeasurementComponents/ClarkCleanImageSkyModel.h>
#include <synthesis/MeasurementEquations/SkyEquation.h>
#include <synthesis/MeasurementEquations/Qimager.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class MeasurementSet;
class VisSet;
class File;
class VPSkyJones;
class GlishRecord;


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

class qimager : public ApplicationObject
{
public:
  // "qimager" ctor
  qimager();
  
  // Construct an qimager tool from a MeasurementSet and
  // a flag indicating whether compression of attached
  // calibration data columns is required
  qimager(MeasurementSet &thems, Bool compress=False);
  
  qimager(const qimager &other);
  qimager &operator=(const qimager &other);
  ~qimager();
  
  // Close the current ms, and replace it with the supplied ms.
  // Optionally compress the attached calibration data
  // columns if they are created here.
  Bool open(MeasurementSet &thems, Bool compress=False);
  
  // Flush the ms to disk and detach from the ms file. All function
  // calls after this will be a no-op.
  Bool close();
  
  // Return the name of the MeasurementSet
  String name() const;
  
  // The following setup methods define the state of the qimager.
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
		const Int facets, const Quantity& distance);
  
  // Set the data selection parameters
  Bool setdata(const String& mode, const Vector<Int>& nchan, 
	       const Vector<Int>& start,
	       const Vector<Int>& step, const MRadialVelocity& mStart,
	       const MRadialVelocity& mStep,
	       const Vector<Int>& spectralwindowids,
	       const Vector<Int>& fieldid,
	       const String& msSelect="");
  
  // Set the processing options
  Bool setoptions(const String& ftmachine, const Int cache, const Int tile,
		  const String& gridfunction,
		  const Float padding);

  // Set the single dish processing options
  Bool setsdoptions(const Float scale, const Float weight);

  // Set the voltage pattern
  Bool setvp(const Bool dovp,
	     const Bool defaultVP,
	     const String& vpTable,
	     const Bool doSquint,
	     const Quantity &parAngleInc);

  // Set the scales to be searched in Multi Scale clean
  Bool setscales(const Vector<Float>& userScaleSizes);
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
  
  // Return the image coordinates
  Bool imagecoordinates(CoordinateSystem& coordInfo);

  // Return the image shape
  IPosition imageshape() const;

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
  
  // Approximate PSF
  Bool approximatepsf(const Vector<String>& model, const Vector<String>& psf);

  // Restore
  Bool restore(const Vector<String>& model, const String& complist,
	       const Vector<String>& image, const Vector<String>& residual);

  // Setbeam
  Bool setbeam(const Quantity& bmaj, const Quantity& bmin, const Quantity& bpa);

  // Residual
  Bool residual(const Vector<String>& model, const String& complist,
	       const Vector<String>& image);

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
	   const Int niter,
	   const Float gain,
	   const Quantity& sigma, 
	   const Quantity& targetflux,
	   const Bool constrainflux,
	   const Bool displayProgress, 
	   const Vector<String>& model, const Vector<Bool>& fixed,
	   const String& complist,
	   const Vector<String>& prior,
	   const Vector<String>& mask,
	   const Vector<String>& restored,
	   const Vector<String>& residual);
  
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
		    const Int stoppointmode);
  
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
  
  // Predict from the model and componentlist
  Bool predict(const Vector<String>& model, const String& complist,
	  Bool incremental=False);

  // Make an empty image
  Bool make(const String& model);

  // Clone an image
  Bool clone(const String& imageName, const String& newImageName);
  
  // Fit the psf
  Bool fitpsf(const String& psf, Quantity& mbmaj, Quantity& mbmin,
	      Quantity& mbpa);

  // Stuff needed for distributing this class
  virtual String className() const;
  virtual Vector<String> methods() const;
  virtual Vector<String> noTraceMethods() const;
  
  // If your object has more than one method
  virtual MethodResult runMethod(uInt which, ParameterSet &inputRecord, Bool runMethod);

protected:
  
  Qimager *itsQimager;
  String msname_p;
  MeasurementSet *ms_p;
  MeasurementSet *mssel_p;
  VisSet *vs_p;
  FTMachine *ft_p;
  ComponentFTMachine *cft_p;
  SkyEquation* se_p;
  CleanImageSkyModel* sm_p;
  VPSkyJones* vp_p;
  VPSkyJones* gvp_p;
  Bool doMultiFields_p;
  Bool multiFields_p;

  Bool setimaged_p, nullSelect_p;
  Bool redoSkyModel_p;   // if clean is run multiply ..use this to check
                         // if setimage was changed hence redo the skyModel.
  Int nx_p, ny_p, npol_p;
  Int facets_p;
  Quantity mcellx_p, mcelly_p;
  String stokes_p;
  String dataMode_p, imageMode_p;
  Vector<Int> dataNchan_p;
  Int imageNchan_p;
  Vector<Int> dataStart_p, dataStep_p;
  Int imageStart_p, imageStep_p;
  MRadialVelocity mDataStart_p, mImageStart_p;
  MRadialVelocity mDataStep_p,  mImageStep_p;
  MDirection phaseCenter_p;
  Quantity distance_p;
  Bool doShift_p;
  Quantity shiftx_p;
  Quantity shifty_p;
  String ftmachine_p, gridfunction_p;
  Bool wfGridding_p;
  Int cache_p, tile_p;
  Bool doVP_p;
  Quantity bmaj_p, bmin_p, bpa_p;
  Bool beamValid_p;
  Float padding_p;
  Float sdScale_p;
  Float sdWeight_p;
  // special mf control parms, etc
  Float cyclefactor_p;
  Float cyclespeedup_p;
  Int stoplargenegatives_p;
  Int stoppointmode_p;
  Vector<String> fluxscale_p;
  String scaleType_p;		// type of image-plane scaling: NONE, SAULT
  Float minPB_p;		// minimum value of generalized-PB pattern
  Float constPB_p;		// above this level, constant flux-scale

  Vector<Int> spectralwindowids_p;
  Int fieldid_p;

  Vector<Int> dataspectralwindowids_p;
  Vector<Int> datadescids_p;
  Vector<Int> datafieldids_p;

  String telescope_p;
  String vpTableStr_p;         // description of voltage patterns for various telescopes
                               //  in the MS
  Quantity parAngleInc_p;
  BeamSquint::SquintType  squintType_p;
  Bool doDefaultVP_p;          // make default VPs, rather than reading in a vpTable

  // Set the defaults
  void defaults();

  // Prints an error message if the qimager DO is detached and returns True.
  Bool detached() const;

  // Create the FTMachines when necessary or when the control parameters
  // have changed. 
  Bool createFTMachine();

  Bool removeTable(const String& tablename);

  Bool createSkyEquation(const String complist="");
  Bool createSkyEquation(const Vector<String>& image, 
			 const Vector<Bool>& fixed,
			 const String complist="");
  Bool createSkyEquation(const Vector<String>& image, 
			 const String complist="");
  Bool createSkyEquation(const Vector<String>& image, 
			 const Vector<Bool>& fixed,
			 const Vector<String>& mask,
			 const String complist="");
  Bool createSkyEquation(const Vector<String>& image, 
			 const Vector<Bool>& fixed,
			 const Vector<String>& mask,
			 const Vector<String>& fluxMask,
			 const String complist="");
  void destroySkyEquation();

  // Add the residuals to the SkyEquation
  Bool addResidualsToSkyEquation(const Vector<String>& residual);

  // Add or replace the masks
  Bool addMasksToSkyEquation(const Vector<String>& mask);

  Bool restoreImages(const Vector<String>& restored);

  // names of flux scale images
  Bool writeFluxScales(const Vector<String>& fluxScaleNames);

  String imageName() const;

  Bool pbguts(ImageInterface<Float>& in,  
	      ImageInterface<Float>& out, 
	      const MDirection&,
	      const Quantity&);

  Bool valid() const;

  Bool assertDefinedImageParameters() const;

  virtual void setSkyEquation()
    {se_p = new SkyEquation(*sm_p, *vs_p, *ft_p, *cft_p); return;};

  ComponentList* componentList_p;

  String scaleMethod_p;   // "nscales"   or  "uservector"
  Int nscales_p;
  Vector<Float> userScaleSizes_p;
  Bool scaleInfoValid_p;  // This means that we have set the information, not the scale beams

  Int nmodels_p;
  // Everything here must be a real class since we make, handle and
  // destroy these.
  PtrBlock<PagedImage<Float>* > images_p;
  PtrBlock<PagedImage<Float>* > masks_p;
  PtrBlock<PagedImage<Float>* > fluxMasks_p;
  PtrBlock<PagedImage<Float>* > residuals_p;
  
  // Freq frame is good and valid conversions can be done (or not)
  Bool freqFrameValid_p;

  // Preferred complex polarization representation
  SkyModel::PolRep polRep_p;
};

} //# NAMESPACE CASA - END

#endif



