//# DOpolarimetry.h: polarimetry DO
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
//# $Id: DOpolarimetry.h,v 19.5 2004/11/30 17:50:06 ddebonis Exp $



#ifndef APPSGLISH_DOPOLARIMETRY_H
#define APPSGLISH_DOPOLARIMETRY_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <casa/Arrays/IPosition.h>
#include <measures/Measures/Stokes.h>
#include <images/Images/ImagePolarimetry.h>
#include <casa/Utilities/DataType.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
template<class T> class Array;
template<class T> class ImageInterface;
template<class T> class MaskedLattice;
class ObjectID;
class Index;
class Normal;
} //# NAMESPACE CASA - END

// <summary> 
//  Implementation of the image polarimetry functionality
// </summary>

// <use visibility=local>   or   <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> SomeClass
// </prerequisite>
//
// <etymology>
//  This implements the functionality for the image polarimetry Distributed Object 
// </etymology>
//
// <synopsis>
//  The functionality that is bound to Glish and available via the
//  image polarimetry module/DO is implemented here.
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

class imagepol : public ApplicationObject
{
public:
// "imagepol" constructors
   imagepol(const String& infile);

// Test image constructor
   imagepol (const String& outFile, const Vector<Float>& rm, Bool rmDefault,
             Float pa0, Float sigma, Int nx, Int ny, Int nf, 
             Float f0, Float df);

// copy constructor
   imagepol(const imagepol& other);

// assignment
   imagepol& operator=(const imagepol& other);

// Destructor
   ~imagepol();

// Summary
   void summary() const;

// sigma
   Float sigma(Float clip) const;

// Stokes I
   ObjectID stokesI(const String& outfile) const;
   Float sigmaStokesI(Float clip) const;

// Stokes Q
   ObjectID stokesQ(const String& outfile) const;
   Float sigmaStokesQ(Float clip) const;

// Stokes U
   ObjectID stokesU(const String& outfile) const;
   Float sigmaStokesU(Float clip) const;

// Stokes V
   ObjectID stokesV(const String& outfile) const;
   Float sigmaStokesV(Float clip) const;

// Linearly polarized intensity
   ObjectID linPolInt(Bool debias, Float clip, Float sigma, const String& outfile) const;
   Float sigmaLinPolInt(Float clip, Float sigma) const;

// Total polarized intensity.
   ObjectID totPolInt(Bool debias, Float clip, Float sigma, const String& outfile) const;
   Float sigmaTotPolInt(Float clip, Float sigma) const;

// Complex linear polarization
   void complexLinearPolarization (const String& outfile) const;

// Complex linear polarization
   void complexFractionalLinearPolarization (const String& outfile) const;

// Linearly polarized position angle
   ObjectID linPolPosAng(const String& outfile) const;
   ObjectID sigmaLinPolPosAng(Float clip, Float sigma, const String& outfile) const;
   
// Fractional linearly polarized intensity
   ObjectID fracLinPol(Bool debias, Float clip, Float sigma, const String& outfile) const;
   ObjectID sigmaFracLinPol(Float clip, Float sigma, const String& outfile) const;

// Fractional total polarized intensity
   ObjectID fracTotPol(Bool debias, Float clip, Float sigma, const String& outfile) const;
   ObjectID sigmaFracTotPol(Float clip, Float sigma, const String& outfile) const;

// Depolarization ratio
   ObjectID depolarizationRatio (const String& infile,
                                 Bool debias, Float clip, 
                                 Float sigma, const String& outfile);
   ObjectID sigmaDepolarizationRatio (const String& infile,
                                      Bool debias, Float clip, 
                                      Float sigma, const String& outfile);

// Find Rotation Measure from Fourier method
   void fourierRotationMeasure(const String& outfile,
                               const String& outfileAmp,
                               const String& outfilePA,
                               const String& outfileReal,
                               const String& outfileImag,
                               Bool zeroZeroLag) const;

// Find Rotation Measure from traditional method
   void rotationMeasure(const String& outRM, const String& outRMErr,
                        const String& outPA0, const String& outPA0Err,
                        const String& outNTurns, const String& outChiSq,
                        Index axis, Float varQU, Float rmFg, 
                        Float rmMax, Float maxPaErr,
                        const String& plotter,
                        Int nx, Int ny) const;

// Make a complex image
   void makeComplex (const String& complex, const String& real, 
                     const String& imag, const String& amp,
                     const String& phase);

// Stuff needed for distributing this class
   virtual String className() const;
   virtual Vector<String> methods() const;
   virtual Vector<String> noTraceMethods() const;

// If your object has more than one method
   virtual MethodResult runMethod(uInt which, 
                                  ParameterSet &inputRecord,
                                  Bool runMethod);

private:
   ImagePolarimetry* itsImagePolPtr;

// Copy image and make OID
   ObjectID copyImage (LogIO& os, const ImageInterface<Float>& inImage,
                       const String& outfile,
                       Bool overwrite) const;

// Copy miscellaneous (MiscInfo, ImageInfo, history, units)
   void copyMiscellaneous (ImageInterface<Complex>& out,
                           const ImageInterface<Float>& in) const;
   void copyMiscellaneous (ImageInterface<Float>& out,
                           const ImageInterface<Float>& in) const;

// Fiddle Stokes coordinate
   void fiddleStokesCoordinate(ImageInterface<Float>& ie, Stokes::StokesTypes type) const;
   void fiddleStokesCoordinate(ImageInterface<Complex>& ie, Stokes::StokesTypes type) const;

// Return an image ObjectID for the expression
   ObjectID makeOID (const ImageInterface<Float>& expr) const;

// Make a PagedImage or TempImage output
   void makeImage (ImageInterface<Complex>*& pOutIm, const String& outfile,
                   const CoordinateSystem& cSys, const IPosition& shape,
                   Bool isMasked, Bool tempAllowed, LogIO& os) const;
   void makeImage (ImageInterface<Float>*& pOutIm, const String& outfile,
                   const CoordinateSystem& cSys, const IPosition& shape,
                   Bool isMasked, Bool tempAllowed, LogIO& os) const;

// Make an IQUV image with some dummy RM data
   void makeIQUVImage (ImageInterface<Float>*& pImOut, const String& outfile, Double sigma, 
                       Double pa0, const Vector<Float>& rm, const IPosition& shape,
                       Double f0, Double dF, LogIO& os);

// Fill IQUV image with Stokes values from RM data
   void fillIQUV (ImageInterface<Float>& im, uInt stokesAxis,
                  uInt spectralAxis, const Vector<Float>& rm, 
                  Float pa0, LogIO& os);

// Add noise to Array
   void addNoise (Array<Float>& slice, Normal& noiseGen) const;

// Centre reference pixelin image
   void centreRefPix (CoordinateSystem& cSys, const IPosition& shape) const;

// Make and define a mask 
   Bool makeMask(ImageInterface<Float>& out, Bool init, LogIO& os) const;
   Bool makeMask(ImageInterface<Complex>& out, Bool init, LogIO& os) const;

// What type ?
   inline DataType whatType(const ImageInterface<Float>*) const {return TpFloat;}
   inline DataType whatType(const ImageInterface<Complex>*) const {return TpComplex;}

// What Stokes type ?  Exception if more than one.
   Stokes::StokesTypes stokesType(const CoordinateSystem& cSys, LogIO& os) const;

// Runmethod enum
    enum methods {COMPLEXLINPOL, COMPLEXFRACLINPOL, DEPOLARIZATIONRATIO,
                  FRACLINPOL, FRACTOTPOL, FOURIERROTATIONMEASURE,
                  LINPOLINT, LINPOLPOSANG,
                  MAKECOMPLEX,
                  ROTATIONMEASURE,
                  SIGMA, SIGMADEPOLARIZATIONRATIO,
                  SIGMASTOKESI, SIGMASTOKESQ, SIGMASTOKESU, SIGMASTOKESV,
                  SIGMALINPOLINT, SIGMALINPOLPOSANG, SIGMATOTPOLINT,
                  SIGMAFRACLINPOL, SIGMAFRACTOTPOL,
                  STOKESI, STOKESQ, STOKESU, STOKESV, SUMMARY,
                  TOTPOLINT, NUM_METHODS};

    enum no_trace_methods {NT_COMPLEXLINPOL,
                           NT_COMPLEXFRACLINPOL, NT_DEPOLARIZATIONRATIO,
                           NT_FRACLINPOL, NT_FRACTOTPOL,
                           NT_LINPOLINT, NT_LINPOLPOSANG,
                           NT_MAKECOMPLEX,
                           NT_SIGMA, NT_SIGMADEPOLARIZATIONRATIO,
                           NT_SIGMASTOKESI, NT_SIGMASTOKESQ, NT_SIGMASTOKESU, NT_SIGMASTOKESV,
                           NT_SIGMALINPOLINT, NT_SIGMALINPOLPOSANG, NT_SIGMATOTPOLINT,
                           NT_SIGMAFRACLINPOL, NT_SIGMAFRACTOTPOL,
                           NT_STOKESI, NT_STOKESQ, NT_STOKESU, NT_STOKESV,
                           NT_SUMMARY, NT_TOTPOLINT, NUM_NOTRACE_METHODS};
};

#endif
