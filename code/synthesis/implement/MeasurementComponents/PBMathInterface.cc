//# PBMathInterface.cc: Implementation for PBMathInterface
//# Copyright (C) 1996,1997,1998,1999,2000,2003
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
//# $Id: PBMathInterface.cc,v 19.7 2004/11/30 17:50:50 ddebonis Exp $

#include <casa/aips.h>
#include <casa/BasicSL/Complex.h>
#include <synthesis/MeasurementComponents/PBMathInterface.h>

#include <measures/Measures/Stokes.h>
#include <casa/BasicSL/Constants.h>

#include <components/ComponentModels/Flux.h>
#include <components/ComponentModels/ComponentShape.h>
#include <components/ComponentModels/SkyComponent.h>

#include <images/Images/ImageInterface.h>
#include <lattices/Lattices/LatticeStepper.h>
#include <lattices/Lattices/LatticeIterator.h>

#include <coordinates/Coordinates/CoordinateSystem.h>
#include <coordinates/Coordinates/DirectionCoordinate.h>
#include <coordinates/Coordinates/SpectralCoordinate.h>
#include <coordinates/Coordinates/StokesCoordinate.h>
#include <coordinates/Coordinates/Projection.h>

#include <casa/Utilities/Assert.h>
#include <casa/BasicSL/String.h>

namespace casa { //# NAMESPACE CASA - BEGIN

PBMathInterface::PBMathInterface()
{
};

PBMathInterface::~PBMathInterface()
{
};



PBMathInterface::PBMathInterface(Bool isThisVP,
				 BeamSquint squint,
				 Bool useSymmetricBeam) :
isThisVP_p(isThisVP),
squint_p(squint),
useSymmetricBeam_p(useSymmetricBeam)
{
};


void
PBMathInterface::namePBClass(String & str)
{
  PBMathInterface::PBClass iPB = whichPBClass();
  switch (iPB) {
  case PBMathInterface::NONE:
    str = "NONE";
    break;
  case PBMathInterface::AIRY:
    str = "AIRY";
    break;
  case PBMathInterface::GAUSS:
    str = "GAUSSIAN";
    break;
  case PBMathInterface::POLY:
    str = "POLYNOMIAL";
    break;
  case PBMathInterface::IPOLY:
    str = "INVERSE POLYNOMIAL";
    break;
  case PBMathInterface::COSPOLY:
    str = "COSINE POLYNOMIAL";
    break;
  case PBMathInterface::NUMERIC:
    str = "NUMERIC";
    break;
  case PBMathInterface::IMAGE:
    str = "IMAGE";
    break;
  case PBMathInterface::ZERNIKE:
    str = "ZERNIKE";
    break;
  default:
    str = "UNKNOWN";
    break;
  }
};

void 
PBMathInterface::namePBClass(const PBMathInterface::PBClass iPB,  String & str)
{
  switch (iPB) {
  case PBMathInterface::NONE:
    str = "NONE";
    break;
  case PBMathInterface::AIRY:
    str = "AIRY";
    break;
  case PBMathInterface::GAUSS:
    str = "GAUSSIAN";
    break;
  case PBMathInterface::POLY:
    str = "POLYNOMIAL";
    break;
  case PBMathInterface::IPOLY:
    str = "INVERSE POLYNOMIAL";
    break;
  case PBMathInterface::COSPOLY:
    str = "COSINE POLYNOMIAL";
    break;
  case PBMathInterface::NUMERIC:
    str = "NUMERIC";
    break;
  case PBMathInterface::IMAGE:
    str = "IMAGE";
    break;
  case PBMathInterface::ZERNIKE:
    str = "ZERNIKE";
    break;
  default:
    str = "UNKNOWN";
    break;
  }
};


//forward each function call to the virtual private apply method

ImageInterface<Complex>&  
PBMathInterface::applyVP(const ImageInterface<Complex>& in,
			 ImageInterface<Complex>& out,
			 const MDirection& sp,
			 const Quantity parAngle,
			 const BeamSquint::SquintType doSquint,
			 Bool inverse,
			 Bool conjugate,
			 Float cutoff,
			 Bool forward)
{
  return apply(in, out, sp, parAngle, doSquint, inverse, conjugate, 1, cutoff,
	       forward); 
};


ImageInterface<Complex>&  
PBMathInterface::applyPB(const ImageInterface<Complex>& in,
			 ImageInterface<Complex>& out,
			 const MDirection& sp,
			 const Quantity parAngle,
			 const BeamSquint::SquintType doSquint,
			 Bool inverse,
			 Float cutoff,
			 Bool forward)
{
  return apply(in, out, sp, parAngle, doSquint, inverse, False, 2, cutoff, forward);
};


ImageInterface<Float>&  
PBMathInterface::applyPB2(const ImageInterface<Float>& in,
			  ImageInterface<Float>& out,
			  const MDirection& sp,
			  const Quantity parAngle,
			  const BeamSquint::SquintType doSquint,
			  Float cutoff)
{
  return apply(in, out, sp, parAngle, doSquint, cutoff);
};

SkyComponent& 
PBMathInterface::applyVP(SkyComponent& in,
			 SkyComponent& out,
			 const MDirection& sp,
			 const Quantity frequency,
			 const Quantity parAngle,
			 const BeamSquint::SquintType doSquint,
			 Bool inverse,
			 Bool conjugate,
			 Float cutoff,
			 Bool forward)
{
  return apply(in, out, sp, frequency, parAngle, doSquint, inverse, conjugate, 1, cutoff,
	       forward);
};

SkyComponent& 
PBMathInterface::applyPB(SkyComponent& in,
			 SkyComponent& out,
			 const MDirection& sp,
			 const Quantity frequency,
			 const Quantity parAngle,
			 const BeamSquint::SquintType doSquint,
			 Bool inverse,
			 Float cutoff,
			 Bool forward)
{
  return apply(in, out, sp, frequency, parAngle, doSquint, inverse, False, 2, cutoff,
	       forward);
};

SkyComponent& 
PBMathInterface::applyPB2(SkyComponent& in,
			  SkyComponent& out,
			  const MDirection& sp,
			  const Quantity frequency,
			  const Quantity parAngle,
			  const BeamSquint::SquintType doSquint)
{
  return apply(in, out, sp, frequency, parAngle, doSquint, False, False, 4, 0.0, True);
};


void
PBMathInterface::summary(Int nValues)
{
  LogIO os(LogOrigin("PBMathInterface", "summary"));
  if (isThisVP_p) {
    os << "These parameters are for Voltage Pattern" <<  LogIO::POST;
  } else {
    os << "These parameters are for primary Beam" <<  LogIO::POST;
  }
  if (squint_p.isNonNull()) {
    squint_p.show();
  } else {
    os << "No Beam Squint" <<  LogIO::POST;
  }
};

} //# NAMESPACE CASA - END

