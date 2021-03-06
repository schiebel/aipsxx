//# CEMemModel.cc:  this implements CEMemModel
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2003
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
//# $Id: CEMemModel.cc,v 19.7 2005/12/06 20:18:51 wyoung Exp $

#include <synthesis/MeasurementEquations/CEMemModel.h>
#include <synthesis/MeasurementEquations/CEMemProgress.h>
#include <synthesis/MeasurementEquations/LatConvEquation.h>
#include <casa/Arrays/IPosition.h>
#include <lattices/Lattices/LatticeExpr.h>
#include <lattices/Lattices/LatticeExprNode.h>
#include <lattices/Lattices/TiledLineStepper.h>
#include <lattices/Lattices/TempLattice.h>
#include <lattices/Lattices/LatticeIterator.h>
#include <casa/Arrays/Slice.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/ArrayError.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/VectorIter.h>
#include <casa/Logging/LogOrigin.h>
#include <casa/BasicMath/Math.h>
#include <casa/Exceptions/Error.h>
#include <casa/Utilities/Assert.h>
#include <casa/System/PGPlotter.h>
#include <casa/iostream.h> 
#include <casa/sstream.h>


namespace casa { //# NAMESPACE CASA - BEGIN

//----------------------------------------------------------------------
CEMemModel::CEMemModel(Entropy &ent, 
		       Lattice<Float> & model,
		       uInt nIntegrations,
		       Float sigma,
		       Float targetFlux,
		       Bool useFluxConstraint,
		       Bool initializeModel,
		       Bool doImageplane) :
  itsEntropy_ptr(&ent),
  itsResidualEquation_ptr(0),
  itsModel_ptr(&model),
  itsPrior_ptr(0),
  itsMask_ptr(0),
  itsInitializeModel(initializeModel),
  itsNumberIterations(nIntegrations),
  itsSigma(sigma),
  itsTargetFlux(targetFlux),
  itsUseFluxConstraint(useFluxConstraint),
  itsDoImagePlane(doImageplane),
  itsThreshold0(0.0),
  itsThresholdSpeedup(0.0),
  itsCycleFlux(0.0),
  itsFirstIteration(0),
  itsChoose(False),
  itsLog(LogOrigin("CEMemModel", 
		   "CEMemModel(const Lattice<Float> & model)")),
  itsProgressPtr(0)
{
  initStuff();
};

//----------------------------------------------------------------------
CEMemModel::CEMemModel(Entropy &ent, 
		       Lattice<Float> & model,
		       Lattice<Float> & prior,
		       uInt nIntegrations,
		       Float sigma,
		       Float targetFlux,
		       Bool useFluxConstraint,
		       Bool initializeModel,
		       Bool doImageplane) :
  itsEntropy_ptr(&ent),
  itsResidualEquation_ptr(0),
  itsModel_ptr(&model),
  itsPrior_ptr(&prior),
  itsMask_ptr(0),
  itsInitializeModel(initializeModel),
  itsNumberIterations(nIntegrations),
  itsSigma(sigma),
  itsTargetFlux(targetFlux),
  itsUseFluxConstraint(useFluxConstraint),
  itsDoImagePlane(doImageplane),
  itsThreshold0(0.0),
  itsThresholdSpeedup(0.0),
  itsCycleFlux(0.0),
  itsFirstIteration(0),
  itsChoose(False),
  itsLog(LogOrigin("CEMemModel", 
		   "CEMemModel(const Lattice<Float> & model)")),
   itsProgressPtr(0)
{
  initStuff();
};

//----------------------------------------------------------------------
CEMemModel::CEMemModel(Entropy &ent, 
		       Lattice<Float> & model,
		       Lattice<Float> & prior,
		       Lattice<Float> & mask,
		       uInt nIntegrations,
		       Float sigma,
		       Float targetFlux,
		       Bool useFluxConstraint,
		       Bool initializeModel,
		       Bool doImageplane)
  :
  itsEntropy_ptr(&ent),
  itsResidualEquation_ptr(0),
  itsModel_ptr(&model),
  itsPrior_ptr(&prior),
  itsMask_ptr(&mask),
  itsInitializeModel(initializeModel),
  itsNumberIterations(nIntegrations),
  itsSigma(sigma),
  itsTargetFlux(targetFlux),
  itsUseFluxConstraint(useFluxConstraint),
  itsDoImagePlane(doImageplane),
  itsThreshold0(0.0),
  itsThresholdSpeedup(0.0),
  itsCycleFlux(0.0),
  itsFirstIteration(0),
  itsChoose(False), 
  itsLog(LogOrigin("CEMemModel", 
		   "CEMemModel(const Lattice<Float> & model)")),
  itsProgressPtr(0)

{
  initStuff();
};


//----------------------------------------------------------------------
CEMemModel::~CEMemModel()
{
  delete itsStep_ptr;
  delete itsResidual_ptr;
};



//----------------------------------------------------------------------
void CEMemModel::setPrior(Lattice<Float> & prior)
{
  checkImages(itsModel_ptr, &prior); 
  itsPrior_ptr = &prior; 
  initStuff();
}

//----------------------------------------------------------------------
Float CEMemModel::getThreshold()
{
  if (itsThresholdSpeedup<= 0.0) {
    return itsThreshold0;
  } else {
    Float factor = (1 + (Float)(itsIteration - itsFirstIteration)/((Float)(itsThresholdSpeedup)) );
    return (itsThreshold0 * factor);
  }
};


//----------------------------------------------------------------------
Bool CEMemModel::initStuff()
{
  checkImage(itsModel_ptr);

  // initialize various parameters

  if (itsMask_ptr) {
    LatticeExprNode LEN = sum(*itsMask_ptr);
    itsNumberPixels = LEN.getFloat();
  } else {
    itsNumberPixels = itsModel_ptr->nelements();
  }

  formFlux();
  itsDefaultLevel = abs(itsTargetFlux) / itsNumberPixels;

  Float clipVal = 1.0e-7;
  if (itsPrior_ptr != 0) {
    itsDefaultLevel = 0.0;
    Lattice<Float> &prior = *itsPrior_ptr;
    prior.copyData(  (LatticeExpr<Float>) (iif(prior < clipVal, clipVal, prior)) );     
  }

  Lattice<Float> &model = *itsModel_ptr;
  if (itsInitializeModel) {
    if (itsDefaultLevel > 0.0) {
      model.set(itsDefaultLevel);
    } else {
      model.set(itsSigma/10.0);
    }
  } else {
    // use the model passed in, but clip it to avoid negativity
     model.copyData( (LatticeExpr<Float>) (iif(model<clipVal, clipVal, model)) );     
  }

  applyMask( model );  // zero out masked pixels in model
   
  itsTolerance = 0.05;
  itsQ = 10;
  itsGain = 0.3;
  itsMaxNormGrad = 100.0;

  itsDoInit = True;
  itsAlpha = 0;
  itsBeta = 0;
  Bool isOK = True;

  //Create temporary images

  itsStep_ptr = new TempLattice<Float> (itsModel_ptr->shape(), 2);
  itsResidual_ptr = new TempLattice<Float> (itsModel_ptr->shape(), 2);
  if (itsStep_ptr &&  itsResidual_ptr) {
    itsStep_ptr->set(0.0);
    itsResidual_ptr->set(0.0);
  } else {
    isOK = False;
  }

  // We have been given an Entropy object, now we have to
  // tell it about US
  itsEntropy_ptr->setMemModel( *this );

  return isOK;
};


//----------------------------------------------------------------------
void CEMemModel::initializeAlphaBeta()
{
  // Note: in practice, this routine seems to never get called;
  // included for consistency with SDE MEM routine
  if (! itsUseFluxConstraint) {
    itsAlpha = max(0.0,  itsGDG(H,C)/ itsGDG(C,C) );
    itsBeta = 0.0;
  } else {
    Double det = itsGDG(C,C)*itsGDG(F,F) - itsGDG(C,F)*itsGDG(C,F);
    itsAlpha = (itsGDG(F,F)*itsGDG(H,C) - itsGDG(C,F)*itsGDG(H,F) )/det;
    itsBeta =  (itsGDG(C,C)*itsGDG(H,F) - itsGDG(C,F)*itsGDG(H,C) )/det;
  }
};



//----------------------------------------------------------------------
void CEMemModel::updateAlphaBeta()
{

  // code stolen from SDE's mem.f
  Double a = itsGDG(C,J)/itsGDG(C,C);
  Double b = square(a) - (itsGDG(J, J) - itsGain*itsLength)/ itsGDG(C, C);

  Double dAMax;
  Double dAMin;
  Double dBMax;
  Double dBMin;

  if (b > 0.0) {
    b = sqrt(b);
    dAMax = a + b;
    dAMin = a - b;
  } else {
    dAMax = 0.0;
    dAMin = 0.0;
  }

  Double dChisq;
  Double dAlpha;
  Double dBeta;
  Double dFlux;

  if ( ! itsUseFluxConstraint ) {
    dChisq =  itsChisq -  itsTargetChisq + itsGDG (C, J);
    dAlpha = dChisq/itsGDG(C, C);

    dAlpha = max(dAMin, min(dAMax, dAlpha));
    itsAlpha = max(0.0, itsAlpha + dAlpha);
  } else {
    a = itsGDG(F,J)/itsGDG(F,F);
    b = square(a) - (itsGDG(J, J) - itsGain*itsLength)/itsGDG(F,F);
    if ( b > 0.0) {
      b = sqrt((double)b);
      dBMax = a + b;
      dBMin = a - b;
    } else {
      dBMax = 0.0;
      dBMin = 0.0;
    }
    
    dChisq = itsChisq - itsTargetChisq + itsGDG(C, J);
    dFlux = itsFlux - itsTargetFlux +  itsGDG(F, J);
    Double det = itsGDG(C, C)*itsGDG(F, F) - square(itsGDG(F, C));
    dAlpha = (itsGDG(F, F)*dChisq - itsGDG(C, F)*dFlux)/det;
    dBeta =  (itsGDG(C, C)*dFlux  - itsGDG(C, F)*dChisq)/det;
    
    dAlpha = max(dAMin, min(dAMax, dAlpha));
    itsAlpha = max(0.0, itsAlpha + dAlpha);
    dBeta    = max(dBMin, min(dBMax, dBeta));
    itsBeta  = itsBeta + dBeta;
  }

};



//----------------------------------------------------------------------
void CEMemModel::changeAlphaBeta()
{
  formGDG();
  itsLength = itsGDG(H,H) + square(itsAlpha) * itsGDG(C,C) 
    + square(itsBeta) * itsGDG(F,F);
  if (itsAlpha == 0.0 && itsBeta == 0.0) {
    itsLength = itsGDG(F,F);
  }
  itsNormGrad = itsGDG(J,J) / itsLength;
  if (itsAlpha == 0.0) 
    itsNormGrad = 0.0;
  if (itsNormGrad < itsGain) {
    updateAlphaBeta();
  } else {
    initializeAlphaBeta();
  }
};



//----------------------------------------------------------------------
Bool CEMemModel::checkImage(const Lattice<Float> *im)
{
  // I guess we don't have anything to do
  return True;
};



//----------------------------------------------------------------------
Bool CEMemModel::checkImages(const Lattice<Float> *one, const Lattice<Float> *other)
{
  Bool isOK = True;

  for (uInt i = 0; i < one->ndim(); i++) {
    AlwaysAssert(one->shape()(i) == other->shape()(i), AipsError);
  }
  return isOK;
};


//----------------------------------------------------------------------
Bool CEMemModel::ok() 
{
  Bool isOK = True;
  if (!itsModel_ptr) {
    isOK = False;
  } else {
    isOK = checkImage(itsModel_ptr);
    if (itsPrior_ptr) {
      checkImages(itsModel_ptr, itsPrior_ptr);
    }
    if (itsMask_ptr) {
      checkImages(itsModel_ptr, itsMask_ptr);
    }
    if (itsStep_ptr) {
      checkImages(itsModel_ptr, itsStep_ptr);
    }
    if (itsResidual_ptr) {
      checkImages(itsModel_ptr, itsResidual_ptr);
    }
    if (! itsEntropy_ptr) {
      isOK = False;
    }

    // Also need to check state variables in the future!
  }
  return isOK;
};

void CEMemModel::setMask(Lattice<Float> & mask)
{ 
  checkImages(itsModel_ptr, &mask); 
  itsMask_ptr = &mask;
  initStuff();
}


void CEMemModel::state()
{
   if (itsPrior_ptr == 0) {
    itsLog << "Using blank prior image" << LogIO::POST;
  } else {
    itsLog << "Using prior image "  << LogIO::POST;
  }
  if (itsMask_ptr != 0) {
    itsLog << "Using mask to restrict emission" << LogIO::POST;
  }
}

//----------------------------------------------------------------------
Bool CEMemModel::solve(ResidualEquation<Lattice<Float> >  & eqn) 
{
  itsResidualEquation_ptr = &eqn;
  Bool converged = False;
  Bool endNow = False;
  state();

  itsEntropy_ptr->infoBanner();

  for (itsIteration = itsFirstIteration;
       ( (itsIteration < itsNumberIterations) && !endNow);
       itsIteration++) {
    if (itsDoImagePlane) {
      itsTargetChisq = square(itsSigma) * itsNumberPixels;
    } else {
      itsTargetChisq = square(itsSigma) * itsNumberPixels / itsQ;
    }

    oneIteration();

    itsFit = sqrt((double)( itsChisq / itsTargetChisq) );
    itsAFit = max(itsFit, 1.0f) * 
      sqrt((double)( itsTargetChisq / itsNumberPixels) );
    itsEntropy_ptr->infoPerIteration(itsIteration);

    converged = itsEntropy_ptr->testConvergence();
    if (! converged && getThreshold() > 0.0) {
      converged = testConvergenceThreshold();
    }

    if (itsNormGrad > itsMaxNormGrad) {
      endNow = True;
      itsLog << " Excessive gradient: stopping now" << LogIO::EXCEPTION;
    }

    if (converged) {
      endNow = True;;
      itsLog << "Converged at iteration " << itsIteration+1 << LogIO::POST;
    }

  }
  if (!converged) {
    itsLog << "MEM failed to converge after " <<  itsNumberIterations+1 
	   << " iterations" << LogIO::POST;
  }    

  formFlux();
  return converged;
};

Bool CEMemModel::testConvergenceThreshold()
{ 
  Bool less = False; 
  if (getThreshold() > 0.0) {
   if (itsCurrentPeakResidual < getThreshold() ) {
     less = True;
   }
  }
  return less;
};

Bool CEMemModel::applyMask( Lattice<Float> & lat ) {
  if (itsMask_ptr) {
    LatticeExpr<Float> exp = ( (*itsMask_ptr) * (lat) );
    lat.copyData( exp );
    return True;
  } else {
    return False;
  }
};


void  CEMemModel::oneIteration()
{
  ok();
  if (itsDoInit) {
    itsDoInit = False;
    // passing *this reverts to the LinearModel from which we are derived
    itsResidualEquation_ptr->residual( *itsResidual_ptr, 
				       itsChisq,
				       *this);
    applyMask( *itsResidual_ptr );

    if (!itsDoImagePlane) itsChisq /= itsQ;  

    if (itsAlpha == 0.0 || itsBeta == 0.0)
      changeAlphaBeta();
  }


  calculateStep();
  relaxMin();
  
  // limit the step to less than the gain
  Float scale = 1.0;
  Float scalem = 1.0;
  if (itsNormGrad > 0.0)
    scalem = itsGain/itsNormGrad;
  scale = min(1.0f, scalem);

  takeStep(1.0, scale);

  // passing *this reverts to the LinearModel from which we are derived
  itsResidualEquation_ptr->residual( *itsResidual_ptr, 
				     itsChisq,
				     *this);
  applyMask( *itsResidual_ptr );
  if (!itsDoImagePlane) itsChisq /= itsQ;  

  if (itsThreshold0 > 0.0) {
    LatticeExprNode LEN = max(*itsResidual_ptr);
    Float rmax = LEN.getFloat();
    LEN = min(*itsResidual_ptr);
    Float rmin = LEN.getFloat();
    itsCurrentPeakResidual =  max (abs(rmax), abs(rmin));
  }

  // form Gradient dot Step
  formGDS();
  

  // determine optimal step
  Double eps = 1.0;
  if (itsGradDotStep0 != itsGradDotStep1) 
    eps = itsGradDotStep0/(itsGradDotStep0-itsGradDotStep1);
  if (scale != 0.0f) eps = min(eps, (Double)(scalem/scale) );
  if (eps <= 0.0) {
    eps = 1.0;
    itsLog << "warning: eps = 0.0" << LogIO::WARN;
  }
  
  // Step to optimum point
  
  if (abs(eps-1.0) > itsGain) {
    takeStep(1.0, scale*(eps-1.0));
    // passing *this reverts to the LinearModel from which we are derived
    itsResidualEquation_ptr->residual( *itsResidual_ptr, 
				       itsChisq,
				       *this);				       
    applyMask( *itsResidual_ptr );
    if (!itsDoImagePlane) itsChisq /= itsQ;  

    if (itsThreshold0 > 0.0) {
      LatticeExprNode LEN = max(*itsResidual_ptr);
      Float rmax = LEN.getFloat();
      LEN = min(*itsResidual_ptr);
      Float rmin = LEN.getFloat();
      itsCurrentPeakResidual =  max (abs(rmax), abs(rmin));
    }
    
  }

  formEntropy();
  //  formFlux();

  // readjust beam volume
  itsQ = itsQ*(1.0/max(0.5, min(2.0,eps))+1.0)/2.0;

  changeAlphaBeta();
};



//----------------------------------------------------------------------
void CEMemModel::calculateStep()
{
  
  formGDGStep();

  formFlux();
  itsGradDotStep0 = itsGDG(J,J);
  itsLength = itsGDG(H,H) + square(itsAlpha) * itsGDG(C,C) 
    + square(itsBeta) * itsGDG(F,F);
  if (itsLength <= 0.0) {
    itsLength = itsGDG(F,F);
  }
  itsNormGrad = itsGDG(J,J) / itsLength;
};


//----------------------------------------------------------------------
void CEMemModel::takeStep(Float wt1, Float wt2)
{
  Lattice<Float> &model = *itsModel_ptr;
  Lattice<Float> &step  = *itsStep_ptr;
  LatticeExprNode  node;

  applyMask( step );

  node = max ( (wt1*model  + wt2*step), itsRequiredModelMin);
  model.copyData( (LatticeExpr<Float>)node);
};



//----------------------------------------------------------------------
Float CEMemModel::formFlux()
{
  itsFlux = 0.0;
  itsModelMin =  1e+20;
  itsModelMax = -1e+20;

  Lattice<Float> &model = *itsModel_ptr;
  TiledLineStepper mtls(model.shape(), model.niceCursorShape(), 0);
  RO_LatticeIterator<Float> mod( model, mtls); 
  for (mod.reset(); !mod.atEnd(); mod++) {
    for (uInt i=0;i<mod.vectorCursor().nelements();i++) {
      itsFlux +=  mod.vectorCursor()(i);
      if (mod.vectorCursor()(i) > itsModelMax)
	itsModelMax = mod.vectorCursor()(i);
      if (mod.vectorCursor()(i) < itsModelMin)
	itsModelMin = mod.vectorCursor()(i);
    }
  }
  return itsFlux;
};



} //# NAMESPACE CASA - END

