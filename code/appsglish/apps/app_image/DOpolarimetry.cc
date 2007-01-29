//# DOpolarimetry.cc: defines DOpolarimetry class which implements functionality
//# for the image Distributed Object
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
//# $Id: DOpolarimetry.cc,v 19.10 2005/12/06 20:18:50 wyoung Exp $

#include <appsglish/app_image/DOpolarimetry.h>

#include <casa/Arrays/ArrayMath.h>
#include <coordinates/Coordinates/CoordinateUtil.h>
#include <coordinates/Coordinates/SpectralCoordinate.h>
#include <coordinates/Coordinates/StokesCoordinate.h>
#include <coordinates/Coordinates/CoordinateSystem.h>
#include <images/Images/ImageInterface.h>
#include <appsglish/app_image/DOimage.h>
#include <images/Images/ImageExpr.h>
#include <images/Images/TempImage.h>
#include <images/Images/PagedImage.h>
#include <images/Images/SubImage.h>
#include <images/Images/ImageUtilities.h>
#include <images/Images/RegionHandler.h>
#include <lattices/Lattices/LatticeExpr.h>
#include <lattices/Lattices/LatticeExprNode.h>
#include <lattices/Lattices/LCPagedMask.h>
#include <lattices/Lattices/LCMask.h>
#include <lattices/Lattices/LatticeStepper.h>
#include <lattices/Lattices/LatticeIterator.h>
#include <lattices/Lattices/LatticeUtilities.h>
#include <casa/BasicMath/Random.h>
#include <measures/Measures/Stokes.h>
#include <casa/Quanta/QC.h>
#include <casa/OS/File.h>
#include <casa/OS/Path.h>
#include <casa/OS/Directory.h>
#include <tasking/Tasking/Index.h>
#include <tables/LogTables/NewFile.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <tasking/Tasking/ObjectController.h>
#include <casa/System/PGPlotter.h>
#include <casa/Utilities/PtrHolder.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/DataType.h>

#include <casa/sstream.h>
#include <casa/stdio.h>


#include <casa/namespace.h>
imagepol::imagepol(const String& infile)
//
// Constructor "imagepol"
//
: itsImagePolPtr(0)
{
   LogIO os(LogOrigin("imagepol", "imagepol(const String& infile)",
            id(), WHERE));
//
   ImageInterface<Float>* imagePointer = 0;
   Bool deleteIt;
   image::getPointer (imagePointer, deleteIt, infile, os);
//
   try {
      itsImagePolPtr = new ImagePolarimetry(*imagePointer);
   } catch (AipsError x) {
      if (deleteIt) delete imagePointer;
      os << x.getMesg() << LogIO::EXCEPTION;
   }
//
   if (deleteIt) {
      delete imagePointer;
      imagePointer = 0;
   }
}



imagepol::imagepol (const String& outFile, const Vector<Float>& rm, Bool rmDefault,
                    Float pa0, Float sigma, Int nx, Int ny, 
                    Int nf, Float f0, Float df)
{
   LogIO os(LogOrigin("imagepol", "imagepol(...)", id(), WHERE));


// If not given make RM with no ambiguity

   Vector<Float> rm2;
   if (rmDefault) {
      Double l1 = QC::c.getValue(Unit("m/s")) / f0;
      Double l2 = QC::c.getValue(Unit("m/s")) / (f0+df);
      rm2.resize(1);
      rm2(0) = C::pi / 2 / (l1*l1 - l2*l2);
   } else {
      rm2 = rm.copy();
   }
   const uInt nRM = rm2.nelements();
//
   if (nRM == 1) {
      os << LogIO::NORMAL << "Using Rotation Measure = " << rm2(0) << " radians/m/m" << endl;
   } else { 
      os << LogIO::NORMAL  << "Using Rotation Measures : " << endl;
      for (uInt i=0; i<nRM; i++) {
         os << "                          " << rm2(i) << " radians/m/m" << endl;
      }
   }
   os << "Using pa0              = " << pa0 << " degrees" << endl;
   os << "Using frequency        = " << f0 << " Hz" << endl;
   os << "Using bandwidth        = " << df << " Hz " << endl;
   os << "Using number channels  = " << nf << LogIO::POST;

// Make image

   IPosition shape(4,nx,ny,4,nf);
   ImageInterface<Float>* pImOut = 0;
   makeIQUVImage(pImOut, outFile, Double(sigma), Double(pa0*C::pi/180.0), rm2,
                 shape, Double(f0), Double(df), os);
   try {
      itsImagePolPtr = new ImagePolarimetry(*pImOut);
   } catch (AipsError x) {
      delete pImOut;
      pImOut = 0;
      os << x.getMesg() << LogIO::EXCEPTION;
   }
//
   delete pImOut;
   pImOut = 0;
}



imagepol::imagepol(const imagepol& other)
//
// Copy constructor
//
: itsImagePolPtr(0)
{
    *this = other;
}

imagepol& imagepol::operator=(const imagepol& other)
// 
// Assignment operator
//
{
    if (this != &other) {
       if (itsImagePolPtr!= 0) delete itsImagePolPtr;
       itsImagePolPtr = new ImagePolarimetry(*(other.itsImagePolPtr));
    }
//
    return *this;
}

imagepol::~imagepol()
//
// Destructor
//
{
   delete itsImagePolPtr;
   itsImagePolPtr = 0;
}



// Public methods

void imagepol::complexLinearPolarization (const String& outfile) const
{
   LogIO os(LogOrigin("imagepol", "complexLinearPolarization(...)", id(), WHERE));

// Make output complex image

   ImageInterface<Complex>* pOutComplex = 0;
   CoordinateSystem cSysPol;
   IPosition shapePol = itsImagePolPtr->singleStokesShape(cSysPol, Stokes::Plinear);
   makeImage (pOutComplex, outfile, cSysPol, shapePol,
              itsImagePolPtr->isMasked(), False, os);

// Make Expr

   ImageExpr<Complex> expr = itsImagePolPtr->complexLinearPolarization();
   fiddleStokesCoordinate(*pOutComplex, Stokes::Plinear);

// Copy to output

   pOutComplex->setCoordinateInfo(expr.coordinates());
   LatticeUtilities::copyDataAndMask(os, *pOutComplex, expr);
//
   const ImageInterface<Float>* p = itsImagePolPtr->imageInterface();
   copyMiscellaneous (*pOutComplex, *p);
//
   delete pOutComplex;
}


void imagepol::complexFractionalLinearPolarization (const String& outfile) const
{
   LogIO os(LogOrigin("imagepol", "complexFractionalLinearPolarization(...)", id(), WHERE));

// Make output complex image

   ImageInterface<Complex>* pOutComplex = 0;
   CoordinateSystem cSysPol;
   IPosition shapePol = itsImagePolPtr->singleStokesShape(cSysPol, Stokes::PFlinear);
   makeImage (pOutComplex, outfile, cSysPol, shapePol,
              itsImagePolPtr->isMasked(), False, os);

// Make Expr

   ImageExpr<Complex> expr = itsImagePolPtr->complexFractionalLinearPolarization();
   fiddleStokesCoordinate(*pOutComplex, Stokes::PFlinear);

// Copy to output

   pOutComplex->setCoordinateInfo(expr.coordinates());
   LatticeUtilities::copyDataAndMask(os, *pOutComplex, expr);
//
   const ImageInterface<Float>* p = itsImagePolPtr->imageInterface();
   copyMiscellaneous (*pOutComplex, *p);
//
   delete pOutComplex;
}


ObjectID imagepol::depolarizationRatio (const String& infile,
                                        Bool debias, Float clip, 
                                        Float sigma, const String& outfile) 
{
   LogIO os(LogOrigin("imagepol", "depolarizationRatio(...)", id(), WHERE));
//
   const ImageInterface<Float>* imagePointer1 = itsImagePolPtr->imageInterface();
//
   ImageInterface<Float>* imagePointer2 = 0;
   Bool deleteIt;
   image::getPointer (imagePointer2, deleteIt, infile, os);
//
   ImageExpr<Float> expr = ImagePolarimetry::depolarizationRatio(*imagePointer1, 
                                                                 *imagePointer2, 
                                                                 debias, clip, sigma);
//
   if (deleteIt) {
      delete imagePointer2;
      imagePointer2 = 0;
   }

// Create output image if needed

    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}


ObjectID imagepol::sigmaDepolarizationRatio (const String& infile,
                                             Bool debias, Float clip, 
                                             Float sigma, const String& outfile) 
{
   LogIO os(LogOrigin("imagepol", "sigmaDepolarizationRatio(...)", id(), WHERE));
//
   const ImageInterface<Float>* imagePointer1 = itsImagePolPtr->imageInterface();
//
   ImageInterface<Float>* imagePointer2 = 0;
   Bool deleteIt;
   image::getPointer (imagePointer2, deleteIt, infile, os);
//
   ImageExpr<Float> expr = ImagePolarimetry::sigmaDepolarizationRatio(*imagePointer1, 
                                                                      *imagePointer2, 
                                                                      debias, clip, sigma);
//
   if (deleteIt) {
      delete imagePointer2;
      imagePointer2 = 0;
   }

// Create output image if needed

    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}


void imagepol::fourierRotationMeasure(const String& outfile,
                                      const String& outfileAmp, 
                                      const String& outfilePA,   
                                      const String& outfileReal,
                                      const String& outfileImag,    
                                      Bool zeroZeroLag) const
{
   LogIO os(LogOrigin("imagepol", "fourierRotationMeasure(...)", id(), WHERE));

// Make output complex image

   ImageInterface<Complex>* pOutComplex = 0;
   CoordinateSystem cSysPol;
   IPosition shapePol = itsImagePolPtr->singleStokesShape(cSysPol, Stokes::Plinear);
   makeImage (pOutComplex, outfile, cSysPol, shapePol,
              itsImagePolPtr->isMasked(), True, os);

// Make output amplitude and position angle images

   ImageInterface<Float>* pOutAmp = 0;
   ImageInterface<Float>* pOutPA = 0;
   makeImage (pOutAmp, outfileAmp, cSysPol, shapePol,
              itsImagePolPtr->isMasked(), False, os);
   makeImage (pOutPA, outfilePA, cSysPol, shapePol,
              itsImagePolPtr->isMasked(), False, os);

// Make output real and imaginary images

   ImageInterface<Float>* pOutReal = 0;
   ImageInterface<Float>* pOutImag = 0;
   makeImage (pOutReal, outfileReal, cSysPol, shapePol,
              itsImagePolPtr->isMasked(), False, os);
   makeImage (pOutImag, outfileImag, cSysPol, shapePol,
              itsImagePolPtr->isMasked(), False, os);

// The output complex image will have correct Coordinates, mask, and
// miscellaneous things copied to it

   itsImagePolPtr->fourierRotationMeasure(*pOutComplex, zeroZeroLag);

// Copy to output

   const ImageInterface<Float>* p = itsImagePolPtr->imageInterface();
   if (pOutAmp!=0) {
      LatticeExprNode node(abs(*pOutComplex));
      LatticeExpr<Float> le(node);
      LatticeUtilities::copyDataAndMask(os, *pOutAmp, le);
//
      pOutAmp->setCoordinateInfo(pOutComplex->coordinates());
      copyMiscellaneous (*pOutAmp, *p);
      pOutAmp->setUnits(p->units());
      fiddleStokesCoordinate(*pOutAmp, Stokes::Plinear);
      delete pOutAmp;
   }
   if (pOutPA!=0) {
      LatticeExprNode node(pa(imag(*pOutComplex),real(*pOutComplex)));  // degrees
      LatticeExpr<Float> le(node);
      LatticeUtilities::copyDataAndMask(os, *pOutPA, le);
//
      pOutPA->setCoordinateInfo(pOutComplex->coordinates());
      copyMiscellaneous (*pOutPA, *p);
      pOutPA->setUnits("deg");
      fiddleStokesCoordinate(*pOutPA, Stokes::Pangle);
      delete pOutPA;
   }
   if (pOutReal!=0) {
      LatticeExprNode node(real(*pOutComplex));
      LatticeExpr<Float> le(node);
      LatticeUtilities::copyDataAndMask(os, *pOutReal, le);
      pOutReal->setCoordinateInfo(pOutComplex->coordinates());
      copyMiscellaneous (*pOutReal, *p);
      pOutReal->setUnits(p->units());
      fiddleStokesCoordinate(*pOutReal, Stokes::Plinear);  // Not strictly correct
      delete pOutReal;
   }
   if (pOutImag!=0) {
      LatticeExprNode node(imag(*pOutComplex));
      LatticeExpr<Float> le(node);
      LatticeUtilities::copyDataAndMask(os, *pOutImag, le);
      pOutImag->setCoordinateInfo(pOutComplex->coordinates());
      copyMiscellaneous (*pOutImag, *p);
      pOutImag->setUnits(p->units());
      fiddleStokesCoordinate(*pOutImag, Stokes::Plinear);  // Not strictly correct
      delete pOutImag;
   }
}

ObjectID imagepol::fracLinPol(Bool debias, Float clip, Float sigma, const String& outfile) const
{
    LogIO os(LogOrigin("imagepol", "fracLinPol(...)", id(), WHERE));
    ImageExpr<Float> expr = itsImagePolPtr->fracLinPol(debias, clip, sigma);

// Create output image if needed

    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}

ObjectID imagepol::fracTotPol(Bool debias, Float clip, Float sigma, const String& outfile) const
{
    LogIO os(LogOrigin("imagepol", "fracTotPol(...)", id(), WHERE));
    ImageExpr<Float> expr = itsImagePolPtr->fracTotPol(debias, clip, sigma);

// Create output image if needed

    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}

ObjectID imagepol::linPolInt(Bool debias, Float clip, Float sigma, const String& outfile) const
{
    LogIO os(LogOrigin("imagepol", "linPolInt(...)", id(), WHERE));
    ImageExpr<Float> expr = itsImagePolPtr->linPolInt(debias, clip, sigma);
    
// Create output image if needed
    
    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}

ObjectID imagepol::linPolPosAng(const String& outfile) const
{
    LogIO os(LogOrigin("imagepol", "linPolPosAng(...)", id(), WHERE));
    Bool radians = False;
    ImageExpr<Float> expr = itsImagePolPtr->linPolPosAng(radians);
    
// Create output image if needed
    
    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}



void imagepol::makeComplex (const String& outfile, const String& real,
                            const String& imag, const String& amp,
                            const String& phase)
{
   LogIO os(LogOrigin("imagepol", "makeComplex(...)", id(), WHERE));

// Checks

   if (outfile.empty()) {
      os << "You must give the output complex image file name" << LogIO::EXCEPTION;
   }

   Bool doRI = !real.empty() && !imag.empty();
   Bool doAP = !amp.empty() && !phase.empty();
   if (doRI && doAP) {
      os << "You must give either real and imaginary, or amplitude and phase" << LogIO::EXCEPTION;
   }   

// Make output complex image

   ImageInterface<Complex>* pOutComplex = 0;
   CoordinateSystem cSysPol;
   IPosition shapePol = itsImagePolPtr->singleStokesShape(cSysPol, Stokes::I);
   makeImage (pOutComplex, outfile, cSysPol, shapePol,
              itsImagePolPtr->isMasked(), False, os);

// Make Expression. Only limited Stokes types that make sense are allowed.

   ImageExpr<Complex>* pExpr = 0;
   if (doRI) {
      PagedImage<Float> rr(real);
      Stokes::StokesTypes tR = stokesType(rr.coordinates(), os);
//
      PagedImage<Float> ii(imag);
      Stokes::StokesTypes tI = stokesType(ii.coordinates(), os);
//
      if (tR!=Stokes::Q || tI!=Stokes::U) {
         os << "The real and imaginary components must be Q and U, respectively" << LogIO::EXCEPTION;
      }
      Stokes::StokesTypes typeOut = Stokes::Plinear;
//
      LatticeExprNode node(formComplex(rr,ii));
      LatticeExpr<Complex> le(node);
      pExpr = new ImageExpr<Complex>(le, String("ComplexLinearPolarization"));
      fiddleStokesCoordinate(*pExpr, typeOut);
   } else {
      PagedImage<Float> aa(amp);
      Stokes::StokesTypes tA = stokesType(aa.coordinates(), os);
//
      PagedImage<Float> pp(phase);
      Stokes::StokesTypes tP = stokesType(pp.coordinates(), os);
//
      if (tP!=Stokes::Pangle) {
         os << "The phase must be of Stokes type position angle (Pangle)" << LogIO::EXCEPTION;
      }
      Float fac = 1.0;
      String units = pp.units().getName();
      if (units.contains(String("deg"))) {
         fac = C::pi / 180.0;
      } else if (units.contains(String("rad"))) {
      } else {
         os << LogIO::WARN << "Units for phase are neither radians nor degrees. radians assumed" << LogIO::POST;
      }
//
      Stokes::StokesTypes typeOut = Stokes::Undefined;
      String exprName("");
      if (tA==Stokes::Ptotal) {
         typeOut = Stokes::Ptotal;
         exprName = String("ComplexTotalPolarization");
      } else if (tA==Stokes::Plinear) {
         typeOut = Stokes::Plinear;
         exprName = String("ComplexLinearPolarization");
      } else if (tA==Stokes::PFtotal) {
         typeOut = Stokes::PFtotal;
         exprName = String("ComplexFractionalTotalPolarization");
      } else if (tA==Stokes::PFlinear) {
         typeOut = Stokes::PFlinear;
         exprName = String("ComplexFractionalLinearPolarization");
      } else {
         os << "Cannot form Complex image for this amplitude image" << endl;
         os << "Expect linear, total, or fractional polarization" << LogIO::EXCEPTION;
      }
//
      LatticeExprNode node0(2.0*fac*pp);
      LatticeExprNode node(formComplex(aa*cos(node0),aa*sin(node0)));
      LatticeExpr<Complex> le(node);
      pExpr = new ImageExpr<Complex>(le, exprName);
      fiddleStokesCoordinate(*pExpr, typeOut);
   }

// Copy to output

   pOutComplex->setCoordinateInfo(pExpr->coordinates());
   LatticeUtilities::copyDataAndMask(os, *pOutComplex, *pExpr);
//
   const ImageInterface<Float>* p = itsImagePolPtr->imageInterface();
   copyMiscellaneous (*pOutComplex, *p);
//
   delete pExpr; pExpr = 0;
   delete pOutComplex; pOutComplex = 0;
}



void imagepol::rotationMeasure(const String& outRM, const String& outRMErr,
                               const String& outPA0, const String& outPA0Err,
                               const String& outNTurns, const String& outChiSq,
                               Index axis2, Float sigmaQU, Float rmFg, 
                               Float rmMax, Float maxPaErr, const String& plotter,
                               Int nx, Int ny) const
{
   LogIO os(LogOrigin("imagepol", "rotationMeasure(...)", id(), WHERE));

// Make output images.  Give them all a mask as we don't know if output
// will be masked or not.

   CoordinateSystem cSysRM;
   Int fAxis, sAxis;
   Int axis = axis2();
   IPosition shapeRM = itsImagePolPtr->rotationMeasureShape(cSysRM, fAxis, sAxis, os, axis);
//
   ImageInterface<Float>* pRMOut = 0;
   ImageInterface<Float>* pRMOutErr = 0;
   makeImage (pRMOut, outRM, cSysRM, shapeRM, True, False, os);
   makeImage (pRMOutErr, outRMErr, cSysRM, shapeRM, True, False, os);
//
   CoordinateSystem cSysPA;
   IPosition shapePA = itsImagePolPtr->positionAngleShape(cSysPA, fAxis, sAxis, os, axis);
   ImageInterface<Float>* pPA0Out = 0;
   ImageInterface<Float>* pPA0OutErr = 0;
   makeImage (pPA0Out, outPA0, cSysPA, shapePA, True, False, os);
   makeImage (pPA0OutErr, outPA0Err, cSysPA, shapePA, True, False, os);
//
   ImageInterface<Float>* pNTurnsOut = 0;
   makeImage (pNTurnsOut, outNTurns, cSysRM, shapeRM, True, False, os);
   ImageInterface<Float>* pChiSqOut = 0;
   makeImage (pChiSqOut, outChiSq, cSysRM, shapeRM, True, False, os);

// Make plotter

   PGPlotter pgPlotter;
   if (!plotter.empty()) {
      pgPlotter = PGPlotter(plotter);
      pgPlotter.ask(True);
      pgPlotter.sch(2.0);
      pgPlotter.subp(nx, ny);
   }

// Do it

   itsImagePolPtr->rotationMeasure(pRMOut, pRMOutErr, pPA0Out, pPA0OutErr,
                                   pNTurnsOut, pChiSqOut, pgPlotter, 
                                   axis, rmMax, maxPaErr, 
                                   sigmaQU, rmFg, True);
//
   const ImageInterface<Float>* p = itsImagePolPtr->imageInterface();
   if (pRMOut) {
      copyMiscellaneous (*pRMOut, *p);
      delete pRMOut;
   }
   if (pRMOutErr) {
      copyMiscellaneous (*pRMOutErr, *p);
      delete pRMOutErr;
   }
   if (pPA0Out) {
      copyMiscellaneous (*pPA0Out, *p);
      delete pPA0Out;
   }
   if (pPA0OutErr) {
      copyMiscellaneous (*pPA0OutErr, *p);
      delete pPA0OutErr;
   }
   if (pNTurnsOut) {
      copyMiscellaneous (*pNTurnsOut, *p);
      delete pNTurnsOut;   
   }
   if (pChiSqOut) {
      copyMiscellaneous (*pChiSqOut, *p);
      delete pChiSqOut;
   }
}


Float imagepol::sigma(Float clip) const
{
    LogIO os(LogOrigin("imagepol", "sigma(...)", id(), WHERE));
    return itsImagePolPtr->sigma(clip);
}

ObjectID imagepol::sigmaFracLinPol(Float clip, Float sigma, const String& outfile) const
{
    LogIO os(LogOrigin("imagepol", "sigmaFracLinPol(...)", id(), WHERE));
    ImageExpr<Float> expr = itsImagePolPtr->sigmaFracLinPol(clip, sigma);
    
// Create output image if needed
    
    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}

ObjectID imagepol::sigmaFracTotPol(Float clip, Float sigma, const String& outfile) const
{
    LogIO os(LogOrigin("imagepol", "sigmaFracTotPol(...)", id(), WHERE));
    ImageExpr<Float> expr = itsImagePolPtr->sigmaFracTotPol(clip, sigma);
    
// Create output image if needed
    
    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}

Float imagepol::sigmaLinPolInt(Float clip, Float sigma) const
{
    LogIO os(LogOrigin("imagepol", "sigmaLinPolInt(...)", id(), WHERE));
    return itsImagePolPtr->sigmaLinPolInt(clip, sigma);
}


ObjectID imagepol::sigmaLinPolPosAng(Float clip, Float sigma, const String& outfile) const
{
    LogIO os(LogOrigin("imagepol", "sigmaLinPolPosAng(...)", id(), WHERE));
    Bool radians = False;
    ImageExpr<Float> expr = itsImagePolPtr->sigmaLinPolPosAng(radians, clip, sigma);
    
// Create output image if needed
    
    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}

Float imagepol::sigmaTotPolInt(Float clip, Float sigma) const
{
    LogIO os(LogOrigin("imagepol", "sigmaTotPolInt(...)", id(), WHERE));
    return itsImagePolPtr->sigmaTotPolInt(clip, sigma);
}

Float imagepol::sigmaStokesI(Float clip) const
{
    LogIO os(LogOrigin("imagepol", "sigmaStokesI(...)", id(), WHERE));
    return itsImagePolPtr->sigmaStokesI(clip);
}

Float imagepol::sigmaStokesQ(Float clip) const
{
    LogIO os(LogOrigin("imagepol", "sigmaStokesQ(...)", id(), WHERE));
    return itsImagePolPtr->sigmaStokesQ(clip);
}

Float imagepol::sigmaStokesU(Float clip) const
{
    LogIO os(LogOrigin("imagepol", "sigmaStokesU(...)", id(), WHERE));
    return itsImagePolPtr->sigmaStokesU(clip);
}

Float imagepol::sigmaStokesV(Float clip) const
{
    LogIO os(LogOrigin("imagepol", "sigmaStokesV(...)", id(), WHERE));
    return itsImagePolPtr->sigmaStokesV(clip);
}

ObjectID imagepol::stokesI(const String& outfile) const
{
    LogIO os(LogOrigin("imagepol", "stokesI(...)", id(), WHERE));
    ImageExpr<Float> expr = itsImagePolPtr->stokesI();
    
// Create output image if needed
    
    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}


ObjectID imagepol::stokesQ(const String& outfile) const
{
    LogIO os(LogOrigin("imagepol", "stokesQ(...)", id(), WHERE));
    ImageExpr<Float> expr = itsImagePolPtr->stokesQ();

// Create output image if needed
    
    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}

ObjectID imagepol::stokesU(const String& outfile) const
{
    LogIO os(LogOrigin("imagepol", "stokesU(...)", id(), WHERE));
    ImageExpr<Float> expr = itsImagePolPtr->stokesU();
    
// Create output image if needed
    
    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}

ObjectID imagepol::stokesV(const String& outfile) const
{
    LogIO os(LogOrigin("imagepol", "stokesV(...)", id(), WHERE));
    ImageExpr<Float> expr = itsImagePolPtr->stokesV();
    
// Create output image if needed
    
    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}

void imagepol::summary() const
{
   LogIO os(LogOrigin("imagepol", "summary()", id(), WHERE));
   itsImagePolPtr->summary(os);
}

ObjectID imagepol::totPolInt(Bool debias, Float clip, Float sigma, const String& outfile) const
{
    LogIO os(LogOrigin("imagepol", "totPolInt(...)", id(), WHERE));
    ImageExpr<Float> expr = itsImagePolPtr->totPolInt(debias, clip, sigma);
    
// Create output image if needed
    
    if (outfile.empty()) return makeOID(expr);
    return copyImage (os, expr, outfile, True);
}



// Private methods

ObjectID imagepol::copyImage (LogIO& os, const ImageInterface<Float>& inImage,
                              const String& outfile,
                              Bool overwrite) const
{

// If no outfile, just make the Object from the input image

    if (outfile.empty()) return makeOID(inImage);

// The user wants to write the image out; verify file

    if (!overwrite) {
       NewFile validfile;
       String errmsg;    
       if (!validfile.valueOK(outfile, errmsg)) {
           os << errmsg << LogIO::EXCEPTION;
       }
    }

// Create output image

    ImageInterface<Float>* pOut = new PagedImage<Float>(inImage.shape(), 
                                                        inImage.coordinates(), outfile);
    if (pOut == 0) {
       os << "Failed to create PagedImage" << LogIO::EXCEPTION;
    } else {
       os << LogIO::NORMAL << "Creating image '" << outfile << "' of shape "
          << pOut->shape() << LogIO::POST;
    }

// Make mask

    if (inImage.isMasked()) makeMask(*pOut, False, os);

// Copy stuff

    LatticeUtilities::copyDataAndMask (os, *pOut, inImage);
    ImageUtilities::copyMiscellaneous (*pOut, inImage);

// Make OID

    ObjectID oid = makeOID(*pOut);
    delete pOut;
    return oid;
}

void imagepol::copyMiscellaneous (ImageInterface<Complex>& out,
                                  const ImageInterface<Float>& in) const
{
    out.setMiscInfo(in.miscInfo());
    out.appendLog(in.logger());
}

void imagepol::copyMiscellaneous (ImageInterface<Float>& out,
                                  const ImageInterface<Float>& in) const
{
    out.setMiscInfo(in.miscInfo());
    out.appendLog(in.logger());
}

void imagepol::fiddleStokesCoordinate(ImageInterface<Float>& ie, Stokes::StokesTypes type) const
{
   CoordinateSystem cSys = ie.coordinates();
//
   Int afterCoord = -1;
   Int iStokes = cSys.findCoordinate(Coordinate::STOKES, afterCoord);
//
   Vector<Int> which(1);
   which(0) = Int(type);
   StokesCoordinate stokes(which);
   cSys.replaceCoordinate(stokes, iStokes);
   ie.setCoordinateInfo(cSys);
}

void imagepol::fiddleStokesCoordinate(ImageInterface<Complex>& ie, Stokes::StokesTypes type) const
{
   CoordinateSystem cSys = ie.coordinates();
//
   Int afterCoord = -1;
   Int iStokes = cSys.findCoordinate(Coordinate::STOKES, afterCoord);
//
   Vector<Int> which(1);
   which(0) = Int(type);
   StokesCoordinate stokes(which);
   cSys.replaceCoordinate(stokes, iStokes);
   ie.setCoordinateInfo(cSys);
}


ObjectID imagepol::makeOID (const ImageInterface<Float>& im) const
{

// Return ID

    ObjectController *controller = ApplicationEnvironment::objectController();
    ApplicationObject *subobject = 0;
    if (controller) {
 
// We have a controller, so we can return a valid object id after we
// register the new object

       subobject = new image(im);
       AlwaysAssert(subobject, AipsError);
       return controller->addObject(subobject);
    } else {
       return ObjectID(True); // null
    }
}


void imagepol::makeImage (ImageInterface<Float>*& pOutIm, 
                          const String& outfile,
                          const CoordinateSystem& cSys,
                          const IPosition& shape,
                          Bool isMasked,
                          Bool tempAllowed,
                          LogIO& os) const
{ 
// Verify outfile
       
    if (outfile.empty()) {
      if (!tempAllowed) return;
    } else {
      NewFile validfile;
      String errmsg;    
      if (!validfile.valueOK(outfile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
    }
//
    uInt ndim = shape.nelements();
    if (ndim != cSys.nPixelAxes()) {
       os << "Supplied CoordinateSystem and image shape are inconsistent" << LogIO::EXCEPTION;
    }
    if (outfile.empty()) {
       pOutIm = new TempImage<Float>(shape, cSys);
       if (pOutIm == 0) {
          os << "Failed to create TempImage" << LogIO::EXCEPTION;
       }
       os << LogIO::NORMAL << "Creating (temp)image of shape "
          << pOutIm->shape() << LogIO::POST;
    } else {
       pOutIm = new PagedImage<Float>(shape, cSys, outfile);
       if (pOutIm == 0) {
          os << "Failed to create PagedImage" << LogIO::EXCEPTION;
       }
       os << LogIO::NORMAL << "Creating image '" << outfile << "' of shape "
          << pOutIm->shape() << LogIO::POST;
    }
//
    if (isMasked) {
       makeMask(*pOutIm, True, os);
    }
}

void imagepol::makeImage (ImageInterface<Complex>*& pOutIm, 
                          const String& outfile,
                          const CoordinateSystem& cSys,
                          const IPosition& shape,
                          Bool isMasked,
                          Bool tempAllowed,
                          LogIO& os) const
{ 
// Verify outfile.  If TempAllowed==False and name is empty,
// just return without making anything.
       
    if (outfile.empty()) {
       if (!tempAllowed) return;
    } else {
      NewFile validfile;
      String errmsg;    
      if (!validfile.valueOK(outfile, errmsg)) {
          os << errmsg << LogIO::EXCEPTION;
      }
    }
//
    uInt ndim = shape.nelements();
    if (ndim != cSys.nPixelAxes()) {
       os << "Supplied CoordinateSystem and image shape are inconsistent" << LogIO::EXCEPTION;
    }
//
    if (outfile.empty()) {
       pOutIm = new TempImage<Complex>(shape, cSys);
       if (pOutIm == 0) {
          os << "Failed to create TempImage" << LogIO::EXCEPTION;
       }
       os << LogIO::NORMAL << "Creating (temp)image of shape "
          << pOutIm->shape() << LogIO::POST;
    } else {
       pOutIm = new PagedImage<Complex>(shape, cSys, outfile);
       if (pOutIm == 0) {
          os << "Failed to create PagedImage" << LogIO::EXCEPTION;
       }
       os << LogIO::NORMAL << "Creating image '" << outfile << "' of shape "
          << pOutIm->shape() << LogIO::POST;
   }
//
   if (isMasked) {
       makeMask(*pOutIm, True, os);
   }
}


            
         
Bool imagepol::makeMask(ImageInterface<Float>& out, Bool init,
                        LogIO& os)  const
{
   if (out.canDefineRegion()) {
  
// Generate mask name if not given
   
      String maskName = out.makeUniqueRegionName(String("mask"), 0);
      
// Make the mask if it does not exist
 
      if (!out.hasRegion (maskName, RegionHandler::Masks)) {
         out.makeMask (maskName, True, True, init, True);
         if (init) {
            os << LogIO::NORMAL << "Created and initialized mask `" << maskName << "'" << LogIO::POST;
         } else {
            os << LogIO::NORMAL << "Created mask `" << maskName << "'" << LogIO::POST;
         }
      }
      return True;
   } else {
      os << LogIO::WARN << "Cannot make requested mask for this type of image" << endl;
      return False;
   }
}

         
Bool imagepol::makeMask(ImageInterface<Complex>& out, Bool init, LogIO& os)  const
{
   if (out.canDefineRegion()) {
  
// Generate mask name if not given
   
      String maskName = out.makeUniqueRegionName(String("mask"), 0);
      
// Make the mask if it does not exist
 
      if (!out.hasRegion (maskName, RegionHandler::Masks)) {
         out.makeMask (maskName, True, True, init, True);
         if (init) {
            os << LogIO::NORMAL << "Created and initialized mask `" << maskName << "'" << LogIO::POST;
         } else {
            os << LogIO::NORMAL << "Created mask `" << maskName << "'" << LogIO::POST;
         }
      }
      return True;
   } else {
      os << LogIO::WARN << "Cannot make requested mask for this type of image" << endl;
      return False;
   }
}



void imagepol::makeIQUVImage (ImageInterface<Float>*& pImOut, const String& outfile, 
                              Double sigma, Double pa0, const Vector<Float>& rm, 
                              const IPosition& shape,
                              Double f0, Double dF, LogIO& os)
//
// Must be 4D
//
{
   AlwaysAssert(shape.nelements()==4,AipsError);
   AlwaysAssert(shape(2)==4,AipsError);
//
   CoordinateSystem cSys;
   CoordinateUtil::addDirAxes(cSys);
//
   Vector<Int> whichStokes(4);
   whichStokes(0) = Stokes::I;
   whichStokes(1) = Stokes::Q;
   whichStokes(2) = Stokes::U;
   whichStokes(3) = Stokes::V;
   StokesCoordinate stokesCoord(whichStokes);
   cSys.addCoordinate(stokesCoord);
//
   const Int nchan = shape(3);
   Double df = dF / nchan;
   Double refpix = 0.0;
   SpectralCoordinate spectCoord(MFrequency::TOPO, f0, df, refpix, f0);
   cSys.addCoordinate(spectCoord);

// Centre reference pixel

   centreRefPix (cSys, shape);

// Make image 

   makeImage (pImOut, outfile, cSys, shape, False, True, os);
//
   uInt stokesAxis = 2;
   uInt spectralAxis = 3;

// Fill image with I, Q, U and V. 

   fillIQUV (*pImOut, stokesAxis, spectralAxis, rm, pa0, os);

// Add noise 

   Array<Float> slice = pImOut->get();
   Float maxVal = max(slice);
   Float t = sigma * maxVal;
   os << LogIO::NORMAL << "Using sigma            = " << t << LogIO::POST;
   MLCG gen;
   Normal noiseGen(&gen, 0.0, t*t);
   addNoise(slice, noiseGen);
   pImOut->put(slice);
}



void imagepol::fillIQUV (ImageInterface<Float>& im, uInt stokesAxis, 
                         uInt spectralAxis, const Vector<Float>& rm, 
                         Float pa0, LogIO& os)
//
// Image must be 4D
//
{

// Find spectral coordinate

   const CoordinateSystem& cSys = im.coordinates();   
   Int spectralCoord, iDum;
   cSys.findPixelAxis(spectralCoord, iDum, spectralAxis);
   const SpectralCoordinate& sC = cSys.spectralCoordinate(spectralCoord);
//
   IPosition shape = im.shape();
   Double c = QC::c.getValue(Unit("m/s"));
   Double lambdasq;
   MFrequency freq;
   IPosition blc(4,0);
   IPosition trc(shape-1);
//
   Double ii = 2.0;                      // arbitrary
   Double vv = 0.05 * ii;                // arbitrary
   const Int n = shape(3);
   const uInt nRM = rm.nelements();
   for (Int i=0; i<n; i++) {
      if (!sC.toWorld(freq, Double(i))) {
        os << sC.errorMessage() << LogIO::EXCEPTION;
      }
      Double fac = c / freq.get(Unit("Hz")).getValue();
      lambdasq = fac*fac;
//
      Double chi = rm(0)*lambdasq + pa0;
      Double q = cos(2*chi);
      Double u = sin(2*chi);
//
      if (nRM > 1) {
         for (uInt j=1; j<nRM; j++) {
            chi = rm(j)*lambdasq + pa0;
            q += cos(2*chi);
            u += sin(2*chi);
         }
      }
      q = q / Double(nRM);
      u = u / Double(nRM);
//
      blc(spectralAxis) = i;                // channel
      trc(spectralAxis) = i;
      {
        blc(stokesAxis) = 1;                // Q       
        trc(stokesAxis) = 1;                
        Slicer sl(blc, trc, Slicer::endIsLast);
        SubImage<Float> subImage(im, sl, True);
        subImage.set(q);
      }
      {
        blc(stokesAxis) = 2;                // U
        trc(stokesAxis) = 2;                
        Slicer sl(blc, trc, Slicer::endIsLast);
        SubImage<Float> subImage(im, sl, True);
        subImage.set(u);
      }
   }
// 
   blc(spectralAxis) = 0;  
   trc(spectralAxis) = n-1;
   {
      blc(stokesAxis) = 0;                // I
      trc(stokesAxis) = 0;                
      Slicer sl(blc, trc, Slicer::endIsLast);
      SubImage<Float> subImage(im, sl, True);
      subImage.set(ii);
   }
   {
     blc(stokesAxis) = 3;                // V
     trc(stokesAxis) = 3;                
     Slicer sl(blc, trc, Slicer::endIsLast);
     SubImage<Float> subImage(im, sl, True);
     subImage.set(vv);
   }
}

void imagepol::addNoise (Array<Float>& slice, Normal& noiseGen) const
{
   Bool deleteIt;
   Float* p = slice.getStorage(deleteIt);
   for (uInt i=0; i<slice.nelements(); i++) {
      p[i] += noiseGen();
   }
   slice.putStorage(p, deleteIt);
}


void imagepol::centreRefPix (CoordinateSystem& cSys, const IPosition& shape) const
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

Stokes::StokesTypes imagepol::stokesType(const CoordinateSystem& cSys, LogIO& os) const
{
   Stokes::StokesTypes type = Stokes::Undefined;
   Int afterCoord = -1;
   Int iStokes = cSys.findCoordinate(Coordinate::STOKES, afterCoord);
   if (iStokes >=0) {
      Vector<Int> which = cSys.stokesCoordinate(iStokes).stokes();
      if (which.nelements()>1) {
        os << "Stokes axis must be of length unity" << LogIO::EXCEPTION;
      } else {
         type = Stokes::type(which(0));
      }
   } else {
      os << "No StokesCoordinate" << LogIO::EXCEPTION;
   }
   return type;
}


// Public methods needed to run DO


String imagepol::className() const
{
    return "imagepol";
}

Vector<String> imagepol::methods() const
{
    Vector<String> method(NUM_METHODS); 
    method(COMPLEXLINPOL) = "complexlinpol";
    method(COMPLEXFRACLINPOL) = "complexfraclinpol";
    method(DEPOLARIZATIONRATIO) = "depolratio";
    method(FOURIERROTATIONMEASURE) = "fourierrotationmeasure";
    method(FRACLINPOL) = "fraclinpol";
    method(FRACTOTPOL) = "fractotpol";
    method(LINPOLINT) = "linpolint";
    method(LINPOLPOSANG) = "linpolposang";
    method(MAKECOMPLEX) = "makecomplex";    
    method(ROTATIONMEASURE) = "rotationmeasure";
    method(SIGMASTOKESI) = "sigmastokesi";
    method(SIGMASTOKESQ) = "sigmastokesq";
    method(SIGMASTOKESU) = "sigmastokesu";
    method(SIGMASTOKESV) = "sigmastokesv";
    method(SIGMA) = "sigma";
    method(SIGMADEPOLARIZATIONRATIO) = "sigmadepolratio";
    method(SIGMALINPOLINT) = "sigmalinpolint";
    method(SIGMALINPOLPOSANG) = "sigmalinpolposang";
    method(SIGMATOTPOLINT) = "sigmatotpolint";
    method(SIGMAFRACLINPOL) = "sigmafraclinpol";
    method(SIGMAFRACTOTPOL) = "sigmafractotpol";
    method(STOKESI) = "stokesi";
    method(STOKESQ) = "stokesq";
    method(STOKESU) = "stokesu";
    method(STOKESV) = "stokesv";
    method(SUMMARY) = "summary";
    method(TOTPOLINT) = "totpolint";
//
    return method;

}

Vector<String> imagepol::noTraceMethods() const
{
    Vector<String> method(NUM_NOTRACE_METHODS);
    method(NT_COMPLEXLINPOL) = "complexlinpol";
    method(NT_COMPLEXFRACLINPOL) = "complexfraclinpol";
    method(NT_DEPOLARIZATIONRATIO) = "depolratio";
    method(NT_FRACLINPOL) = "fraclinpol";
    method(NT_FRACTOTPOL) = "fractotpol";
    method(NT_LINPOLINT) = "linpolint";
    method(NT_LINPOLPOSANG) = "linpolposang";
    method(NT_MAKECOMPLEX) = "makecomplex";
    method(NT_SIGMASTOKESI) = "sigmastokesi";
    method(NT_SIGMASTOKESQ) = "sigmastokesq";
    method(NT_SIGMASTOKESU) = "sigmastokesu";
    method(NT_SIGMASTOKESV) = "sigmastokesv";
    method(NT_SIGMA) = "sigma";
    method(NT_SIGMADEPOLARIZATIONRATIO) = "sigmadepolratio";
    method(NT_SIGMALINPOLINT) = "sigmalinpolint";
    method(NT_SIGMALINPOLPOSANG) = "sigmalinpolposang";
    method(NT_SIGMATOTPOLINT) = "sigmatotpolint";
    method(NT_SIGMAFRACLINPOL) = "sigmafraclinpol";
    method(NT_SIGMAFRACTOTPOL) = "sigmafractotpol";
    method(NT_STOKESI) = "stokesi";
    method(NT_STOKESQ) = "stokesq";
    method(NT_STOKESU) = "stokesu";
    method(NT_STOKESV) = "stokesv";
    method(NT_SUMMARY) = "summary";
    method(NT_TOTPOLINT) = "totpolint";
//
    return method;
}

MethodResult imagepol::runMethod(uInt which, 
                                 ParameterSet &inputRecord,
                                 Bool runMethod)
{
    static String returnvalString = "returnval";
//
    switch (which) {
    case STOKESI:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = stokesI(outfile());
	    }
	}
    break;
    case STOKESQ:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = stokesQ(outfile());
    }
	}
    break;
    case STOKESU:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = stokesU(outfile());
	    }
	}
    break;
    case STOKESV:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = stokesV(outfile());
	    }
	}
    break;
    case LINPOLINT:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
            Parameter<Bool> debias(inputRecord, "debias", ParameterSet::In);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
            Parameter<Float> sigma(inputRecord, "sigma", ParameterSet::In);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = linPolInt(debias(), clip(), sigma(), outfile());
	    }
	}
    break;
    case LINPOLPOSANG:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = linPolPosAng(outfile());
	    }
	}
    break;
    case TOTPOLINT:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
            Parameter<Bool> debias(inputRecord, "debias", ParameterSet::In);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
            Parameter<Float> sigma(inputRecord, "sigma", ParameterSet::In);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = totPolInt(debias(), clip(), sigma(), outfile());
	    }
	}
    break;
    case FRACLINPOL:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
            Parameter<Bool> debias(inputRecord, "debias", ParameterSet::In);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
            Parameter<Float> sigma(inputRecord, "sigma", ParameterSet::In);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = fracLinPol(debias(), clip(), sigma(), outfile());
	    }
	}
    break;
    case FRACTOTPOL:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
            Parameter<Bool> debias(inputRecord, "debias", ParameterSet::In);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
            Parameter<Float> sigma(inputRecord, "sigma", ParameterSet::In);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = fracTotPol(debias(), clip(), sigma(), outfile());
	    }
	}
    break;
    case DEPOLARIZATIONRATIO:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
            Parameter<String> infile(inputRecord, "infile", ParameterSet::In);
            Parameter<Bool> debias(inputRecord, "debias", ParameterSet::In);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
            Parameter<Float> sigma(inputRecord, "sigma", ParameterSet::In);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = depolarizationRatio(infile(), debias(), clip(), sigma(), outfile());
	    }
	}
    break;
    case FOURIERROTATIONMEASURE:
	{
            Parameter<String> complexRec(inputRecord, "complex", ParameterSet::In);
            Parameter<String> ampRec(inputRecord, "amp", ParameterSet::In);
            Parameter<String> paRec(inputRecord, "pa", ParameterSet::In);
            Parameter<String> realRec(inputRecord, "real", ParameterSet::In);
            Parameter<String> imagRec(inputRecord, "imag", ParameterSet::In);
            Parameter<Bool> zeroLagZeroRec(inputRecord, "zerolag0", ParameterSet::In);
	    if (runMethod) {
               fourierRotationMeasure(complexRec(), ampRec(), paRec(), 
                                      realRec(), imagRec(), zeroLagZeroRec());
	    }
	}
    break;
    case SUMMARY:
	{
	    if (runMethod) {
               summary();
	    }
	}
    break;
    case ROTATIONMEASURE:
	{
            Parameter<String> rmRec(inputRecord, "rm", ParameterSet::In);
            Parameter<String> rmErrRec(inputRecord, "rmerr", ParameterSet::In);
            Parameter<String> pa0Rec(inputRecord, "pa0", ParameterSet::In);
            Parameter<String> pa0ErrRec(inputRecord, "pa0err", ParameterSet::In);
            Parameter<String> nTurnsRec(inputRecord, "nturns", ParameterSet::In);
            Parameter<String> chiSqRec(inputRecord, "chisq", ParameterSet::In);
            Parameter<Index> axisRec(inputRecord, "axis", ParameterSet::In);
            Parameter<Float> sigmaRec(inputRecord, "sigma", ParameterSet::In);
            Parameter<Float> rmFgRec(inputRecord, "rmfg", ParameterSet::In);
            Parameter<Float> rmMaxRec(inputRecord, "rmmax", ParameterSet::In);
            Parameter<Float> maxPaErrRec(inputRecord, "maxpaerr", ParameterSet::In);
            Parameter<String> plotterRec(inputRecord, "plotter", ParameterSet::In);
            Parameter<Int> nxRec(inputRecord, "nx", ParameterSet::In);
            Parameter<Int> nyRec(inputRecord, "ny", ParameterSet::In);
//
	    if (runMethod) {
               rotationMeasure(rmRec(), rmErrRec(), pa0Rec(), pa0ErrRec(),
                               nTurnsRec(), chiSqRec(), axisRec(), sigmaRec(), rmFgRec(),
                               rmMaxRec(), maxPaErrRec(), plotterRec(), nxRec(), nyRec());
	    }
	}
    break;
    case SIGMASTOKESI:
	{
	    Parameter<Float> returnval(inputRecord, "returnval",
                                       ParameterSet::Out);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
	    if (runMethod) {
               returnval() = sigmaStokesI(clip());
	    }
	}
    break;
    case SIGMASTOKESQ:
	{
	    Parameter<Float> returnval(inputRecord, "returnval",
                                       ParameterSet::Out);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
	    if (runMethod) {
               returnval() = sigmaStokesQ(clip());
	    }
	}
    break;
    case SIGMASTOKESU:
	{
	    Parameter<Float> returnval(inputRecord, "returnval",
                                       ParameterSet::Out);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
	    if (runMethod) {
               returnval() = sigmaStokesU(clip());
	    }
	}
    break;
    case SIGMASTOKESV:
	{
	    Parameter<Float> returnval(inputRecord, "returnval",
                                       ParameterSet::Out);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
	    if (runMethod) {
               returnval() = sigmaStokesV(clip());
	    }
	}
    break;
    case SIGMA: 
	{
	    Parameter<Float> returnval(inputRecord, "returnval",
                                       ParameterSet::Out);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
	    if (runMethod) {
               returnval() = sigma(clip());
	    }
	}
    break;
    case SIGMALINPOLINT:
	{
	    Parameter<Float> returnval(inputRecord, "returnval",
                                       ParameterSet::Out);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
            Parameter<Float> sigma(inputRecord, "sigma", ParameterSet::In);
	    if (runMethod) {
               returnval() = sigmaLinPolInt(clip(), sigma());
	    }
	}
    break;
    case SIGMALINPOLPOSANG:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                       ParameterSet::Out);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
            Parameter<Float> sigma(inputRecord, "sigma", ParameterSet::In);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = sigmaLinPolPosAng(clip(), sigma(), outfile());
	    }
	}
    break;
    case SIGMATOTPOLINT:
	{
	    Parameter<Float> returnval(inputRecord, "returnval",
                                       ParameterSet::Out);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
            Parameter<Float> sigma(inputRecord, "sigma", ParameterSet::In);
	    if (runMethod) {
               returnval() = sigmaTotPolInt(clip(), sigma());
	    }
	}
    break;
    case SIGMAFRACLINPOL:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                       ParameterSet::Out);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
            Parameter<Float> sigma(inputRecord, "sigma", ParameterSet::In);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = sigmaFracLinPol(clip(), sigma(), outfile());
	    }
	}
    break;
    case SIGMAFRACTOTPOL:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                       ParameterSet::Out);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
            Parameter<Float> sigma(inputRecord, "sigma", ParameterSet::In);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = sigmaFracTotPol(clip(), sigma(), outfile());
	    }
	}
    break;
    case SIGMADEPOLARIZATIONRATIO:
	{
	    Parameter<ObjectID> returnval(inputRecord, "returnval",
                                          ParameterSet::Out);
            Parameter<String> infile(inputRecord, "infile", ParameterSet::In);
            Parameter<Bool> debias(inputRecord, "debias", ParameterSet::In);
            Parameter<Float> clip(inputRecord, "clip", ParameterSet::In);
            Parameter<Float> sigma(inputRecord, "sigma", ParameterSet::In);
            Parameter<String> outfile(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               returnval() = sigmaDepolarizationRatio(infile(), debias(), clip(), sigma(), outfile());
	    }
	}
    break;
    case COMPLEXLINPOL:
	{
            Parameter<String> filename(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               complexLinearPolarization (filename());
	    }
	}
    break;
    case COMPLEXFRACLINPOL:
	{
            Parameter<String> filename(inputRecord, "outfile", ParameterSet::In);
	    if (runMethod) {
               complexFractionalLinearPolarization (filename());
	    }
	}
    break;
    case MAKECOMPLEX: 
        {
            Parameter<String> outFile(inputRecord, "complex", ParameterSet::In);
            Parameter<String> realFile(inputRecord, "real", ParameterSet::In);
            Parameter<String> imagFile(inputRecord, "imag", ParameterSet::In);
            Parameter<String> ampFile(inputRecord, "amp", ParameterSet::In);
            Parameter<String> phaseFile(inputRecord, "phase", ParameterSet::In);
	    if (runMethod) {
               makeComplex (outFile(), realFile(), imagFile(), ampFile(), phaseFile());
	    }
	}
    break;
    default:
	return error("No such method");
    }
    return ok();
}
