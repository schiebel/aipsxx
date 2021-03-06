//# SkyJones.h: Definitions of interface for SkyJones 
//# Copyright (C) 1996,1997,1998,2000,2003
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
//# Correspondence concerning AIPS++ should be adressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: SkyJones.h,v 19.6 2004/11/30 17:50:56 ddebonis Exp $

#ifndef SYNTHESIS_SKYJONES_H
#define SYNTHESIS_SKYJONES_H

#include <casa/aips.h>
#include <casa/BasicSL/Complex.h>
#include <synthesis/MeasurementEquations/Iterate.h>
#include <msvis/MSVis/VisSet.h>
#include <images/Images/ImageInterface.h>
#include <components/ComponentModels/ComponentList.h>
#include <components/ComponentModels/SkyComponent.h>
#include <casa/Utilities/CompositeNumber.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//#forward
class SkyModel;
class ImageRegion;

//# Need forward declaration for Solve in the Jones Matrices
class SkyEquation;

// <summary> 
// Sky Jones: Model sky-plane instrumental effects for the SkyEquation
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
// <li> <linkto class="SkyEquation">SkyEquation</linkto> class
// </prerequisite>
//
// <etymology>
// SkyJones describes an interface for Components to be used in
// the <linkto class="SkyEquation">SkyEquation</linkto>.
// It is an Abstract Base Class: most methods
// must be defined in derived classes.
// </etymology>
//
// <synopsis> 
//
// A SkyJones implements the instrumental effect of some sky-plane based
// calibration effect. It conceptually applies an image of Jones matrices
// to an image. For example, it takes an image of the sky brightness and
// applies the complex primary beam for a given interferometer. Only the
// interface is defined here in the Abstract Base Class. Actual concrete
// classes must be derived from SkyJones.  Some (most) SkyJones are
// solvable: the SkyEquation can be used by the SkyJones to return
// gradients with respect to itself (via the image interface). Thus for a
// SkyJones to solve for itself, it calls the SkyEquation methods to get
// gradients of chi-squared with respect to the image pixel values. The
// SkyJones then uses these gradients as appropriate to update itself.
//
//
// The following examples illustrate how a SkyJones can  be
// used:
// <ul>
// <li> Mosaicing: one SkyJones for the primary beam. For efficiency
// the image must be cached and the VisSet iteration order set to
// minimize the number of recalculations.
// </ul>
// </synopsis> 
//
// <example>
// <srcblock>
//
//  // Low level code example:
//
//    MeasurementSet ms("imagertest/3C273XC1.ms", Table::Update);
//    VPSkyJones  unsquintedVPSJ(ms);
//    VPSkyJones  squintedVPSJ(ms, True, Quantity(5.0, "deg"), BeamSquint::GOFIGURE);
//    unsquintedVPSJ.reset();
//    squintedVPSJ.reset();
//
//    PagedImage<Complex> imageIn;
//    PagedImage<Complex> imageOut;  // in reality, this ouwld need more construction with coords and shapes
//
//    VisSet vs(ms,bi,chanSelection,interval);
//
//    Int row = 0;
//    VisIter &vi = vs.iter();
//    VisBuffer vb(vi);
//    for (vi.originChunks();vi.moreChunks();vi.nextChunk()) {
//      cout << "This is integration: " << nChunks++ << endl;
//      for (vi.origin();vi.more();vi++) {
//        if (myVPSJ.change(vb)) { 
//          cout << "State has changed: " << endl;
//          squintedVPSJ.showState(os);
//          squintedVPSJ.apply(imageIn, imageOut, vb, row);
//        }
//      }
//    }
//
//
//      // High Level Code Example:
//
//
//      // Create an ImageSkyJones from an image on disk
//      ImageSkyModel ism(PagedImage<Float>("3C273XC1.modelImage"));
//
//      // Make an FTMachine: here we use a simple Grid and FT.
//      GridFT ft;
//
//      SkyEquation se(ism, vs, ft);
//
//      // Make a Primary Beam Sky Model
//      VPSkyJones pbsj(ms);
//
//      // Add it to the SkyEquation
//      se.setSkyJones(pbsj);
//
//      // Predict the visibility set
//      se.predict();
//
//      // Read some other data
//      VisSet othervs("3c84.MS.Otherdata");
//
//      // Make a Clean Image and write it out
//      HogbomCleanImageSkyJones csm(ism);
//      if (csm.solve(othervs)) {
//        PagedImage<Float> cleanImage=csm.image(0);
//        cleanImage.setName("3c84.cleanImage");
//      }
//
// </srcblock>
// </example>
//
// <motivation>
// The properties of sky-plane based calibration effects must be described
// for the <linkto class="SkyEquation">SkyEquation</linkto>
// </motivation>
//
// <todo asof="97/10/01">
// <li> There are no Concrete Classes derived from SkyJones!
// <li> Solvable part needs implementation: we need to derive an
// image of gradients of the elements of the Jones matrix. See VisJones
// for how to do this.
// </todo>

class SkyJones : virtual public Iterate {
public:
 
  // Allowed types of VisJones matrices
  enum Type{E,T,F,D};

  enum SizeType{COMPOSITE, POWEROF2, ANY};

  // Destructor.
  ~SkyJones();

  // Apply Jones matrix to an image (and adjoint)
  // <group>
  virtual ImageInterface<Complex>& apply(const ImageInterface<Complex>& in,
					 ImageInterface<Complex>& out,
					 const VisBuffer& vb, Int row,
					 Bool forward=True) = 0;
  virtual ImageInterface<Float>& applySquare(const ImageInterface<Float>& in,
					     ImageInterface<Float>& out,
					     const VisBuffer& vb, Int row) = 0;
  // </group>

  // Apply Jones matrix to a sky component (and adjoint)
  // <group>
  virtual SkyComponent& apply(SkyComponent& in,
			      SkyComponent& out,
			      const VisBuffer& vb, Int row, Bool forward=True) = 0;
  virtual SkyComponent& applySquare(SkyComponent& in,
				    SkyComponent& out,
				    const VisBuffer& vb, Int row) = 0;
  // </group>

  // Has this operator changed since the last application?
  virtual Bool changed(const VisBuffer& vb, Int row) = 0;

  // Does this operator changed in this VisBuffer,
  // starting with row1?
  // If yes, we return in row2, the last row that has the
  // same SkyJones as row1.
  virtual Bool changedBuffer(const VisBuffer& vb, Int row1, Int& row2) = 0;

  // Reset
  virtual void reset() = 0;

  // Assure
  virtual void assure(const VisBuffer& vb, Int row) = 0;

  // Does the operator change in this visbuffer or since the last
  // call?       
  // I'm not sure this is useful -- come back to it
  // m.a.h.  Dec 30 1999
  virtual Bool change(const VisBuffer& vb) = 0;

  // Return the type of this Jones matrix (actual type of derived class).
  virtual Type type() = 0;

  // Apply gradient
  virtual ImageInterface<Complex>& 
  applyGradient(ImageInterface<Complex>& result, const VisBuffer& vb, Int row)
  = 0;
  virtual SkyComponent&
  applyGradient(SkyComponent& result, const VisBuffer& vb, Int row)
  = 0;

  // Is this solveable?
  virtual Bool isSolveable()=0;

  // Initialize for gradient search
  virtual void initializeGradients()=0;

  // Finalize for gradient search
  virtual void finalizeGradients()=0;
 
  // Add to Gradient Chisq
  virtual void addGradients(const VisBuffer& vb, Int row, const Float sumwt, 
			    const Float chisq, const Matrix<Complex>& c, 
			    const Matrix<Float>& f)=0;
 
  // Solve
  virtual Bool solve (SkyEquation& se) = 0;

  // Get the ImageRegion of the primary beam on an Image for a given pointing
  // Note: ImageRegion is not necesarily constrained to lie within the
  // image region (for example, if the pointing center is near the edge of the
  // image).  fPad: extra fractional padding beyond the primary beam support
  // (note: we do not properly treat squint yet, this will cover it for now)
  // iChan: frequency channel to take: lowest frequency channel is safe for all
  // SizeType: COMPOSITE = next larger composite number,
  //           POWEROF2  = next larger power of 2,
  //           ANY       = just take what we get!
  //
  // Potential problem: this ImageRegion includes all Stokes and Frequency Channels
  // present in the input image.

  virtual ImageRegion*  extent (const ImageInterface<Complex>& im, 
				const VisBuffer& vb, 
				const Int irow=-1,                        
				const Float fPad=1.2,  
				const Int iChan=0, 
				const SkyJones::SizeType sizeType=COMPOSITE)=0;
  virtual ImageRegion*  extent (const ImageInterface<Float>& im, 
				const VisBuffer& vb,  
				const Int irow=-1,
				const Float fPad=1.2,  
				const Int iChan=0, 
				const SkyJones::SizeType sizeType=COMPOSITE)=0;
  
 
protected:

  // Could be over-ridden if necessary
  virtual String typeName() {
    switch(type()) {
    case SkyJones::E:    // voltage pattern (ie, on-axis terms)
      return "E Jones";
    case SkyJones::T:    // Tropospheric effects
      return "T Jones";
    case SkyJones::F:    // Faraday
      return "F Jones";
    case SkyJones::D:    // D Beam (ie, polarization leakage beam; off axis terms)
      return "D Jones";
    }
    return "Not known";
  };
 
  SkyJones() {};
 

private:    
};
 

} //# NAMESPACE CASA - END

#endif










