//# DOdeconvolver.cc: this implements the deconvolver DO 
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
//# $Id: DOdeconvolver.cc,v 19.16 2005/12/06 20:18:50 wyoung Exp $

#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/ArrayMath.h>

#include <casa/Logging.h>
#include <casa/Logging/LogIO.h>
#include <casa/OS/File.h>
#include <casa/Containers/Record.h>

#include <tables/Tables/TableParse.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/TableLock.h>
#include <tables/Tables/ExprNode.h>

#include <casa/BasicSL/String.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/Fallible.h>

#include <casa/BasicSL/Constants.h>

#include <casa/Logging/LogSink.h>
#include <casa/Logging/LogMessage.h>

#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>

#include <casa/Arrays/ArrayMath.h>

#include <measures/Measures/Stokes.h>
#include <casa/Quanta/UnitMap.h>
#include <casa/Quanta/UnitVal.h>
#include <casa/Quanta/MVAngle.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <casa/Quanta/MVEpoch.h>
#include <measures/Measures/MEpoch.h>

#include <synthesis/MeasurementEquations/StokesImageUtil.h>
#include <lattices/Lattices/LatticeExpr.h> 
#include <lattices/Lattices/LatticeFFT.h> 
#include <lattices/Lattices/LatticeCleaner.h> 
#include <lattices/Lattices/LatticeCleanProgress.h> 
#include <lattices/Lattices/LatticeConvolver.h> 
#include <lattices/Lattices/TiledLineStepper.h> 
#include <lattices/Lattices/LatticeStepper.h> 
#include <lattices/Lattices/LatticeNavigator.h> 
#include <lattices/Lattices/LatticeIterator.h>
#include <lattices/Lattices/SubLattice.h>
#include <lattices/Lattices/LCBox.h>
#include <lattices/Lattices/LCSlicer.h>

#include <images/Images/TempImage.h>
#include <images/Images/PagedImage.h>
#include <images/Images/ImageSummary.h>
#include <images/Images/SubImage.h>
#include <images/Images/ImageRegion.h>
#include <images/Images/ImageRegrid.h>
#include <images/Images/ImageInfo.h>

#include <coordinates/Coordinates/CoordinateSystem.h>
#include <coordinates/Coordinates/DirectionCoordinate.h>
#include <coordinates/Coordinates/SpectralCoordinate.h>
#include <coordinates/Coordinates/StokesCoordinate.h>
#include <coordinates/Coordinates/Projection.h>

#include <appsglish/deconvolver/DOdeconvolver.h>
#include <synthesis/MeasurementEquations/CEMemProgress.h>
#include <synthesis/MeasurementEquations/CEMemModel.h>
#include <synthesis/MeasurementEquations/ClarkCleanLatModel.h>
#include <synthesis/MeasurementEquations/ClarkCleanProgress.h>
#include <synthesis/DataSampling/ImageDataSampling.h>
#include <synthesis/DataSampling/PixonProcessor.h>
#include <synthesis/MeasurementEquations/LatConvEquation.h>
#include <synthesis/MeasurementEquations/IPLatConvEquation.h>


#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/Index.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <casa/System/PGPlotter.h>
#include <tasking/Tasking/ObjectController.h>

#include <casa/sstream.h>

#include <casa/namespace.h>
// Implementation comment:
// There are two different philosophies active here:
// ClarkCleanLatModel and CEMemModel are evolutionarily related and
// "solve" a LinearEquation (in this case, a LatticeConvolutionEqaution).
// The LatticeCleaner, which performs Hogbom and MultiScale Cleans,
// has no knowledge of the LatticeConvolutionEqaution (LatConvEquation), 
// but carries the PSF and DIRTY around inside itself.

deconvolver::deconvolver() 
  : dirty_p(0), psf_p(0), convolver_p(0), cleaner_p(0),
    pgplotter_p(0)
{
  defaults();
};

void deconvolver::defaults() 
{
  mode_p="none";
  beamValid_p=False;
  scalesValid_p=False;
  bmaj_p=Quantity(0, "arcsec");
  bmin_p=Quantity(0, "arcsec");
  bpa_p=Quantity(0, "deg");
  residEqn_p = 0;
  latConvEqn_p = 0;
  cleaner_p = 0;
  dirtyName_p = "";
  psfName_p = "";
  nx_p=0; ny_p=0; npol_p=0; nchan_p=0;
  fullPlane_p=False;
}

deconvolver::deconvolver(const String& dirty, const String& psf)
  : dirty_p(0), psf_p(0), convolver_p(0), cleaner_p(0),
    pgplotter_p(0)
{
  LogIO os(LogOrigin("deconvolver", "deconvolver(String& dirty, Strong& psf)", WHERE));
  defaults();
  open(dirty, psf);
}

deconvolver::deconvolver(const deconvolver &other)
  : dirty_p(0), psf_p(0), convolver_p(0), cleaner_p(0),
    pgplotter_p(0)
{
  defaults();
  open(other.dirty_p->table().tableName(), other.psf_p->table().tableName());
}

deconvolver &deconvolver::operator=(const deconvolver &other)
{
  if (dirty_p && this != &other) {
    *dirty_p = *(other.dirty_p);
  }
  if (psf_p && this != &other) {
    *psf_p = *(other.psf_p);
  }
  if (convolver_p && this != &other) {
    *convolver_p = *(other.convolver_p);
  }
  if (cleaner_p && this != &other) {
    *cleaner_p = *(other.cleaner_p);
  }
  if (pgplotter_p && this != &other) {
    *pgplotter_p = *(other.pgplotter_p);
  }
  return *this;
}

deconvolver::~deconvolver()
{
  if (psf_p) {
    delete psf_p;
  }
  psf_p = 0;
  if (convolver_p) {
    delete convolver_p;
  }
  convolver_p = 0;
  if (cleaner_p) {
    delete cleaner_p;
  }
  cleaner_p = 0;
  if (dirty_p) {
    delete dirty_p;
  }
  dirty_p = 0;
  if (pgplotter_p) {
    delete pgplotter_p;
  }
  pgplotter_p = 0;
}

Bool deconvolver::open(const String& dirty, const String& psf)
{
  LogIO os(LogOrigin("deconvolver", "open()", WHERE));
  
  if (dirty_p) delete dirty_p;  dirty_p = 0;
  dirty_p = new PagedImage<Float>(dirty);
  AlwaysAssert(dirty_p, AipsError);
  nx_p=dirty_p->shape()(0);
  ny_p=dirty_p->shape()(1);
  if(dirty_p->shape().nelements()==3){
    findAxes();
    if (chanAxis_p > 0)
      nchan_p=dirty_p->shape()(chanAxis_p);
    else
      nchan_p=0;
  }
  if(dirty_p->shape().nelements()==4){
    findAxes();
    npol_p=dirty_p->shape()(polAxis_p);
    nchan_p=dirty_p->shape()(chanAxis_p);
  }
  dirtyName_p =  dirty_p->table().tableName();
    
  if (psf_p) delete psf_p;  psf_p = 0;
  if (psf == ""){
    os << LogIO::WARN 
       << "No psf given; please define one before deconvolving" << LogIO::POST;
    os << LogIO::WARN
       << "Use the function open with the psf" << LogIO::POST;
    return True;
  }
  else{
    psf_p = new PagedImage<Float>(psf);
    AlwaysAssert(psf_p, AipsError);
    psfName_p   =  psf_p->table().tableName();    

  
    try {
      os << "Fitting PSF" << LogIO::POST;
      fitpsf(psf, bmaj_p, bmin_p, bpa_p);
      if((bmaj_p.get().getValue()>0.0)&&(bmaj_p.get().getValue()>0.0)) {
	os << "  Fitted beam is valid"<< LogIO::POST;
      }
      else {
	os << LogIO::WARN << "Fitted beam is invalid: please set using setbeam"
	   << LogIO::POST;
      }
      beamValid_p=True;
      
    } catch (AipsError x) {
      os << LogIO::WARN << "Fitted beam is invalid: please set using setbeam"
	 << LogIO::POST;
    } 
  
    if((psf_p->shape()(0) != nx_p) || psf_p->shape()(1) != ny_p){

      os << LogIO::SEVERE 
	 << "PSF and Image does not have the same XY shape" << LogIO::POST;
      os << LogIO::SEVERE
	 << "You may wish to regrid the PSF to the same shape as the dirty image" 
	 << LogIO::POST;
      return False;

    } 

    try {
      os << "Making Lattice convolver" << LogIO::POST;
      if (convolver_p) {
	delete convolver_p;
      }
    
      //      convolver_p = new LatticeConvolver<Float>(*psf_p);
      //      AlwaysAssert(convolver_p, AipsError);
      
      if (residEqn_p) {
	delete residEqn_p;
      }
      residEqn_p = 0;
      
      if (latConvEqn_p) {
	delete latConvEqn_p;
      }
      latConvEqn_p = 0;
    
      os << "Making Lattice cleaner" << LogIO::POST;
      if (cleaner_p) delete cleaner_p;
      if(nchan_p<=1){
	cleaner_p = new LatticeCleaner<Float>(*psf_p, *dirty_p);
	convolver_p = new LatticeConvolver<Float>(*psf_p);
      }
      else{
	if(npol_p > 0 ){
	  IPosition blc(4, 0, 0, 0, 0);
	  IPosition trc(4, nx_p-1, ny_p-1, 0, 0);
	  trc(polAxis_p)=npol_p-1;
	  Slicer sl(blc, trc, Slicer::endIsLast);
	  SubImage<Float> dirtySub(*dirty_p, sl, True);
	  SubImage<Float> psfSub(*psf_p, sl, True);
	  
	  convolver_p = new LatticeConvolver<Float>(psfSub);
	  AlwaysAssert(convolver_p, AipsError);
	  cleaner_p = new LatticeCleaner<Float>(psfSub, dirtySub);
	}
	else{
	  IPosition blc(3, 0, 0, 0);
	  IPosition trc(3, nx_p-1, ny_p-1, 0);
	  Slicer sl(blc, trc, Slicer::endIsLast);
	  SubImage<Float> dirtySub(*dirty_p, sl, True);
	  SubImage<Float> psfSub(*psf_p, sl, True);
	  
	  convolver_p = new LatticeConvolver<Float>(psfSub);
          AlwaysAssert(convolver_p, AipsError);
	  cleaner_p = new LatticeCleaner<Float>(psfSub, dirtySub);

	}

      }
      AlwaysAssert(cleaner_p, AipsError);
    
      return True;

    } catch (AipsError x) {
      os << LogIO::SEVERE << "Caught Exception: "<< x.getMesg() << LogIO::POST;
      return False;
    } 
  }
}

Bool deconvolver::reopen()
{
  LogIO os(LogOrigin("deconvolver", "reopen()", WHERE));
  try {
    if (dirtyName_p != "" && psfName_p != "") {
      return (open(dirtyName_p, psfName_p));
    } else {
      return False;
    }
  }  catch (AipsError x) {
    dirty_p->table().unlock();
    psf_p->table().unlock();
    os << LogIO::SEVERE << "Caught Exception: "<< x.getMesg() << LogIO::POST;
    return False;
  } 
  return False;
}

// Fit the psf. If psf is blank then make the psf first.
Bool deconvolver::fitpsf(const String& psf, Quantity& mbmaj, Quantity& mbmin,
		 Quantity& mbpa)
{
  if(!valid()) return False;
  
  LogIO os(LogOrigin("deconvolver", "fitpsf()", WHERE));
  
  try {
    
    os << "Fitting to psf" << LogIO::POST;

    if(psf=="") {
      os << LogIO::SEVERE << "Need a psf name" << LogIO::POST;
      return False;
    }
    
    PagedImage<Float> psfImage(psf);
    StokesImageUtil::FitGaussianPSF(psfImage, mbmaj, mbmin, mbpa);
    bmaj_p=mbmaj;
    bmin_p=mbmin;
    bpa_p=mbpa;
    beamValid_p=True;
    
    os << "  Beam fit: " << bmaj_p.get("arcsec").getValue() << " by "
       << bmin_p.get("arcsec").getValue() << " (arcsec) at pa " 
       << bpa_p.get("deg").getValue() << " (deg) " << endl;
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  } 
  return True;
}

Bool deconvolver::close()
{
  if(!valid()) return False;
  if (detached()) return True;
  LogIO os(LogOrigin("deconvolver", "close()", WHERE));
  
  os << "Closing images and detaching from deconvolver" << LogIO::POST;
  if(psf_p) delete psf_p; psf_p = 0;
  if(dirty_p) delete dirty_p; dirty_p = 0;
  if(pgplotter_p) delete pgplotter_p; pgplotter_p = 0;
  if (convolver_p) delete convolver_p; convolver_p = 0;
  if (residEqn_p) delete  residEqn_p;  residEqn_p = 0;
  if (latConvEqn_p) delete latConvEqn_p; latConvEqn_p = 0;
  if (cleaner_p) delete cleaner_p; cleaner_p = 0;

  return True;
}

String deconvolver::dirtyname() const
{
  if (detached()) {
    return "none";
  }
  return dirty_p->table().tableName();
}

String deconvolver::psfname() const
{
  if (detached()) {
    return "none";
  }
  return psf_p->table().tableName();
}

Bool deconvolver::summary() const
{
  if(!valid()) return False;
  LogOrigin OR("deconvolver", "deconvolver::summary()", id(), WHERE);
  
  LogIO los(OR);
  
  try {
    
    los << "Summary of dirty image" << LogIO::POST;
    dirty_p->table().lock();
    {
       ImageSummary<Float> ims(*dirty_p);
       ims.list(los);
    }
    
    los << endl << state() << LogIO::POST;
    dirty_p->table().unlock();

    los << "Summary of PSF" << LogIO::POST;
    psf_p->table().lock();
    {
       ImageSummary<Float> psfs(*psf_p);
       psfs.list(los);
    }
    
    los << "Summary of scales" << LogIO::POST;
    if(scalesValid_p) {
      los << "Scales set" << LogIO::POST;
    }
    else {
      los << "Scales not set" << LogIO::POST;
    }

    los << endl << state() << LogIO::POST;
    psf_p->table().unlock();
    return True;
  } catch (AipsError x) {
    los << LogIO::SEVERE << "Caught Exception: " << x.getMesg()
	<< LogIO::POST;
    dirty_p->table().unlock();
    psf_p->table().unlock();
    return False;
  } 
  
  return True;
}

String deconvolver::state() const
{
  ostringstream os;
  
  try {
    os << "General: " << endl;
    if(dirty_p != 0){
      os << "  Dirty image is " << dirty_p->table().tableName() << endl; 
      dirty_p->table().unlock();
    }
    if(psf_p !=0){
      os << "  PSF         is " << psf_p->table().tableName() << endl;
      psf_p->table().unlock();
    }
    if(beamValid_p) {
      os << "  Beam fit: " << bmaj_p.get("arcsec").getValue() << " by "
	 << bmin_p.get("arcsec").getValue() << " (arcsec) at pa " 
	 << bpa_p.get("deg").getValue() << " (deg) " << endl;
    }
    else {
      os << "  Beam fit is not valid" << endl;
    }
    
  } catch (AipsError x) {
    LogOrigin OR("deconvolver", "deconvolver::state()", id(), WHERE); 
    LogIO los(OR);
    los << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    dirty_p->table().unlock();
    psf_p->table().unlock();
  } 
  return String(os);
}

// Restore: at least one model must be supplied
Bool deconvolver::restore(const String& model, const String& image,
			  Quantity& mbmaj, Quantity& mbmin, Quantity& mbpa)
{
  
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "restore()", WHERE));
  
  dirty_p->table().lock();
  psf_p->table().lock();
  try {
    
    // Validate the names
    if(model=="") {
      os << LogIO::SEVERE << "Need a model"
	 << LogIO::POST;
      return False;
    }
    
    String imagename(image);
    if(imagename=="") imagename=model+".restored";
    removeTable(imagename);
    if(!clone(model, imagename)) return False;
    
    // Smooth all the images and add residuals
    PagedImage<Float> modelImage0(model);

//
    TiledShape tShape(dirty_p->shape());
    ImageInterface<Float>* modelImage_p = new TempImage<Float>(tShape, dirty_p->coordinates());
//
    ImageRegrid<Float> regridder;
    Vector<Double> locate;
    Bool missedIt = regridder.insert(*modelImage_p, locate, modelImage0);
    if (!missedIt) {
      os << LogIO::SEVERE << "Problem in getting model Image on correct grid " << LogIO::POST;
    }

    PagedImage<Float> imageImage(modelImage_p->shape(),
				 modelImage_p->coordinates(),
				 image);

    TempImage<Float> dirtyModelImage(modelImage_p->shape(),modelImage_p->coordinates());
    imageImage.copyData(*modelImage_p);
    if((mbmaj.get().getValue()>0.0)&&(mbmaj.get().getValue()>0.0)) {
      os << "  Using specified beam: " << mbmaj.get("arcsec").getValue() << " by "
	 << mbmin.get("arcsec").getValue() << " (arcsec) at pa " 
	 << mbpa.get("deg").getValue() << " (deg) " << endl;
      StokesImageUtil::Convolve(imageImage, mbmaj, mbmin, mbpa, False);
    }
    else {
      if((bmaj_p.get().getValue()>0.0)&&(bmaj_p.get().getValue()>0.0)) {
	os << "  Using fitted beam: " << bmaj_p.get("arcsec").getValue() << " by "
	   << bmin_p.get("arcsec").getValue() << " (arcsec) at pa " 
	   << bpa_p.get("deg").getValue() << " (deg) " << endl;
	StokesImageUtil::Convolve(imageImage, bmaj_p, bmin_p, bpa_p, False);
	mbmaj = bmaj_p;
        mbmin = bmin_p;
        mbpa = bpa_p;
      }
      else {
	os << LogIO::SEVERE << "Restoring beam not specified" << LogIO::POST;
	return False;
      }
    }
    
    // PSF * Model    
    convolver_p->circular(dirtyModelImage, *modelImage_p);

    // Smoothed + Dirty - PSF * Model
    imageImage.copyData(LatticeExpr<Float>(imageImage+*dirty_p - dirtyModelImage));
    {
      ImageInfo ii = imageImage.imageInfo();
      ii.setRestoringBeam(mbmaj, mbmin, mbpa); 
      imageImage.setImageInfo(ii);
      imageImage.setUnits(Unit("Jy/beam"));
    }

    dirty_p->table().unlock();
    psf_p->table().unlock();
    if (modelImage_p != & modelImage0) {
      delete modelImage_p;
    }
    return True;
  } catch (AipsError x) {
    dirty_p->table().unlock();
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
  } 
  dirty_p->table().unlock();
  return True;
}

// Residual
Bool deconvolver::residual(const String& model, const String& image)
{
  
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "residual()", WHERE));
  
  dirty_p->table().lock();
  psf_p->table().lock();
  try {
    
    // Validate the names
    if(model=="") {
      os << LogIO::SEVERE << "Need a model"
	 << LogIO::POST;
    }
    
    String imagename(image);
    if(imagename=="") imagename=model+".residual";
    removeTable(imagename);
    if(!clone(dirty_p->table().tableName(), imagename)) return False;
    
    // Smooth all the images and add residuals
    
    // modelImage_p is a pointer to an image with the model data in it, but the
    // shape of the dirty image
    PagedImage<Float> modelImage0(model);

    TiledShape tShape(dirty_p->shape());
    ImageInterface<Float>* modelImage_p = new TempImage<Float>(tShape, dirty_p->coordinates());
//
    ImageRegrid<Float> regridder;
    Vector<Double> locate;
    Bool missedIt = regridder.insert(*modelImage_p, locate, modelImage0);
    if (!missedIt) {
      os << LogIO::SEVERE << "Problem in getting model Image on correct grid " << LogIO::POST;
    }

    PagedImage<Float> imageImage(modelImage_p->shape(),
				 modelImage_p->coordinates(),
				 image);
    // PSF * Model    
    convolver_p->circular(imageImage, *modelImage_p);

    // Dirty - PSF * Model
    imageImage.copyData(LatticeExpr<Float>(*dirty_p-imageImage));
    imageImage.setUnits(Unit("Jy/beam"));
    
    dirty_p->table().unlock();
    psf_p->table().unlock();
    if (modelImage_p != & modelImage0) {
      delete modelImage_p;
    }
    return True;
  } catch (AipsError x) {
    dirty_p->table().unlock();
    psf_p->table().unlock();
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
  } 
  dirty_p->table().unlock();
  psf_p->table().unlock();
  return True;
}

// Make an empty image
Bool deconvolver::make(const String& model)
{
  
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "make()", WHERE));
  
  dirty_p->table().lock();
  try {
    
    // Make an image with the required shape and coordinates
    String modelName(model);
    if(modelName=="") modelName=dirty_p->table().tableName()+".model";
    os << "Making empty image: " << model << LogIO::POST;
    
    removeTable(modelName);
    PagedImage<Float> modelImage(dirty_p->shape(),
				 dirty_p->coordinates(), model);
    modelImage.set(0.0);
    
    modelImage.table().tableInfo().setSubType("GENERIC");
    modelImage.setUnits(Unit("Jy/pixel"));
    dirty_p->table().unlock();
    return True;
  } catch (AipsError x) {
    dirty_p->table().unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  } 
  dirty_p->table().unlock();
  return True;
};


// Make an empty image, but with only ONE STOKES pixel
Bool deconvolver::make1(const String& model)
{
  
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "make1()", WHERE));
  
  dirty_p->table().lock();
  try {
    
    // Make an image with the required shape and coordinates
    String modelName(model);
    if(modelName=="") modelName=dirty_p->table().tableName()+".model";
    os << "Making empty image: " << model << LogIO::POST;
    
    removeTable(modelName);
    IPosition newshape = dirty_p->shape();
    newshape(2) = 1;
    PagedImage<Float> modelImage(newshape,
				 dirty_p->coordinates(), model);
    modelImage.set(0.0);
    
    modelImage.table().tableInfo().setSubType("GENERIC");
    modelImage.setUnits(Unit("Jy/pixel"));
    dirty_p->table().unlock();
    return True;
  } catch (AipsError x) {
    dirty_p->table().unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  } 
  dirty_p->table().unlock();
  return True;
};


// Make an empty image, modeled in templateImage
Bool deconvolver::make(const String& model, ImageInterface<Float>& templateImage)
{
  
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "make()", WHERE));
  
  try {
    
    // Make an image with the required shape and coordinates
    String modelName(model);

    os << "Making empty image: " << model << LogIO::POST;
        removeTable(modelName);
    PagedImage<Float> modelImage(templateImage.shape(),
				 templateImage.coordinates(), model);
    modelImage.set(0.0);
    
    modelImage.table().tableInfo().setSubType("GENERIC");
    modelImage.setUnits(Unit("Jy/pixel"));
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  } 
  return True;
};


SubImage<Float>* 
deconvolver::innerQuarter(PagedImage<Float>& in)
{

  IPosition blc(in.shape().nelements(), 0);
  IPosition trc(in.shape()-1);
  for (Int i=0;i<Int(in.shape().nelements());i++) {
    blc(i)=in.shape()(i)/4;
    trc(i)=blc(i)+in.shape()(i)/2-1;
    if(trc(i)<0) trc(i)=1;
  }
  LCSlicer quarter(blc, trc);
  SubImage<Float>* si = new SubImage<Float>(in, quarter, True);
  return si;
};


SubImage<Float>* 
deconvolver::allQuarters(PagedImage<Float>& in)
{
  SubImage<Float>* si = new SubImage<Float>(in, True);
  return si;
};

Bool deconvolver::smooth(const String& model, 
			 const String& image,
			 Quantity& mbmaj, Quantity& mbmin, Quantity& mbpa,
			 Bool normalizeVolume)
{
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "smooth()", WHERE));
  
  dirty_p->table().lock();
  try {
    
    os << "Smoothing image" << LogIO::POST;
    
    if(model=="") {
      os << LogIO::SEVERE << "Need a name for model " << LogIO::POST;
      return False;
    }
    
    if(mbmaj.getValue()==0.0) {
      if(beamValid_p) {
	os << "Using previous beam fit" << LogIO::POST;
	mbmaj=bmaj_p;
	mbmin=bmin_p;
	mbpa=bpa_p;
      }
      else {
	os << LogIO::SEVERE << "Specified beam is invalid" << LogIO::POST;
      }
    }
    
    // Smooth all the images
    PagedImage<Float> modelImage(model);
    PagedImage<Float> imageImage(modelImage.shape(),
				 modelImage.coordinates(),
				 image);
//
    imageImage.copyData(modelImage);
    StokesImageUtil::Convolve(imageImage, mbmaj, mbmin, mbpa, normalizeVolume);
    {
      ImageInfo ii = imageImage.imageInfo();
      ii.setRestoringBeam(mbmaj, mbmin, mbpa); 
      imageImage.setImageInfo(ii);
      imageImage.setUnits(Unit("Jy/beam"));
    }

    dirty_p->table().unlock();
    psf_p->table().unlock();
    return True;
  } catch (AipsError x) {
    dirty_p->table().unlock();
    psf_p->table().unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  } 
  dirty_p->table().unlock();
  psf_p->table().unlock();
  return True;
}

// Clean algorithm
Bool deconvolver::clarkclean(const Int niter, 
			     const Float gain, const Quantity& threshold, 
			     const Bool displayProgress, 
			     const String& model, const String& maskName,
			     const Int histBins, 
			     const Vector<Index>& vi_psfPatchSize, const Float maxExtPsf,
			     const Float speedUp, Int maxNumPix,
			     const Int maxNumMajorCycles,
			     const Int maxNumMinorIterations)
{
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "clarkclean()", WHERE));
  
  IPosition psfPatchSize;
  Index::convertIPosition(psfPatchSize, vi_psfPatchSize);


  dirty_p->table().lock();
  psf_p->table().lock();

  String imagename(model);
  // Make first image with the required shape and coordinates only if
  // it doesn't exist yet. Otherwise we'll throw an exception later
  if(imagename=="") imagename=dirty_p->table().tableName()+".clarkclean";
  if(!Table::isWritable(imagename)) {
    make(imagename);
  }
  PagedImage<Float> modelImage(imagename);
  ClarkCleanProgress *ccpp = 0;

  {
    ostringstream oos;
    oos << "Clean gain = " <<gain<<", Niter = "<<niter<<", Threshold = "
	<<threshold;                              ;
    os << String(oos) << LogIO::POST;
  }
  {
    ostringstream oos;
    oos << "nHhistBins = "
	<<histBins << ", maxExtPsf = "<<maxExtPsf<<", psfPatchSize = "
	<<psfPatchSize<<", maxNumPix = "<<maxNumPix;
    os << String(oos) << LogIO::POST;
  }
  {
    ostringstream oos;
    oos << "Speedup Factor = "<<speedUp<<", maxMajorCycles = "
	<< maxNumMajorCycles<<", maxMinorIterations = "<<maxNumMinorIterations;
    os << String(oos) << LogIO::POST;
  }
  
  os << "Cleaning image using Clark Clean algorithm" << LogIO::POST;
  

  

  
  try {    
    if(model=="") {
      os << LogIO::SEVERE << "Need a name for model " << LogIO::POST;
      return False;
    }
    PagedImage<Float> *mask = 0;
    Bool isCubeMask=False;
 
    Int xbeg, xend, ybeg, yend;
    //default clean box
    xbeg=nx_p/4; 
    xend=3*nx_p/4-1;
    ybeg=ny_p/4; 
    yend=3*ny_p/4-1;

   // Deal with mask
    if (maskName != "") {
      if( Table::isReadable(maskName)) {
	mask= new PagedImage<Float>(maskName);
	if (chanAxis_p < Int(mask->shape().nelements())){
	  if (mask->shape()(chanAxis_p) > 1) 
	    isCubeMask=True;
	}
	checkMask(*mask, xbeg, xend, ybeg, yend);
	AlwaysAssert(mask, AipsError);

      } else {
	os << LogIO::SEVERE << "Mask "<< mask<<" is not readable" << LogIO::POST;
      }
    }
    SubImage<Float> *maskSub=0;
    IPosition blc(2,xbeg,ybeg);
    IPosition trc(2,xend,yend);
    Bool result=False;
    if(nchan_p >=1){
      for (Int k=0; k<nchan_p; ++k){
	os<< "Cleaning channel " << k+1 << LogIO::POST;
	if(npol_p > 0 ){
	  blc.resize(4);
	  blc(chanAxis_p)=k;
	  blc(polAxis_p)=0;
	  trc.resize(4);
	  trc(polAxis_p)=npol_p-1;
	  trc(chanAxis_p)=k;
	  
	}
	else{
	  blc.resize(3);
	  trc.resize(3);  
	  blc(chanAxis_p)=k;
	  trc(chanAxis_p)=k;
	  
	}
      
	
	
	Slicer sl(blc, trc, Slicer::endIsLast);
	SubImage<Float> psfSub;

	if(mask != 0){
	  if( (isCubeMask) || (!isCubeMask && maskSub == 0 )){
	    if(maskSub !=0 ) delete maskSub;
	    blc(0)=0; blc(1)=0;
	    trc(0)=nx_p-1; trc(1)=ny_p-1;
	    sl=Slicer(blc, trc, Slicer::endIsLast);
	    maskSub=new SubImage<Float> (*mask,sl,False);
	    checkMask(*maskSub, xbeg, xend, ybeg, yend);
	    blc(0)=xbeg; blc(1)=ybeg;
	    trc(0)=xend; trc(1)=yend;
	    sl =Slicer(blc, trc, Slicer::endIsLast);
	    delete maskSub;
	    maskSub=new SubImage<Float> (*mask,sl,False);
	  }
	}

   
	SubImage<Float> dirtySub(*dirty_p, sl, True);
	SubImage<Float> modelSub(modelImage,sl,True);
	IPosition blc_psf=blc; IPosition trc_psf=trc;
	if(psf_p->shape().nelements() != dirty_p->shape().nelements()){
	  blc_psf.resize(psf_p->shape().nelements());
	  trc_psf.resize(psf_p->shape().nelements());
	}
	blc_psf(0)=0; blc_psf(1)=0;
	trc_psf(0)=nx_p-1; trc_psf(1)=ny_p-1;
	sl=Slicer(blc_psf, trc_psf, Slicer::endIsLast);
	psfSub=SubImage<Float>(*psf_p, sl, True);
	
	ClarkCleanLatModel myClarkCleaner(modelSub);
	if(mask !=0 )
	  myClarkCleaner.setMask(*maskSub);
	
	myClarkCleaner.setNumberIterations(niter);
	if (maxNumMajorCycles > 0 ) 
	  myClarkCleaner.setMaxNumberMajorCycles((uInt)maxNumMajorCycles);
	if (maxNumMinorIterations > 0 ) 
	  myClarkCleaner.setMaxNumberMinorIterations((uInt)maxNumMinorIterations); 
	
	myClarkCleaner.setGain(gain);
	Double d_thresh = threshold.getValue("Jy");
	myClarkCleaner.setThreshold((Float)d_thresh);
	
	myClarkCleaner.setPsfPatchSize(psfPatchSize);
	myClarkCleaner.setHistLength((uInt)histBins); 
	myClarkCleaner.setMaxExtPsf(maxExtPsf); 
	myClarkCleaner.setSpeedup(speedUp); 
	
	if (maxNumPix == 0) 
	  maxNumPix = (Int)(modelImage.shape().product()*0.04);
	myClarkCleaner.setMaxNumPix((uInt)maxNumPix);
	
	//Now actually do the clean
	if (displayProgress) {
	  getPGPlotter(False);
	  ccpp = new ClarkCleanProgress (pgplotter_p);
	  myClarkCleaner.setProgress(*ccpp);
	}
	if(latConvEqn_p !=0) delete latConvEqn_p;
	latConvEqn_p=0;
	latConvEqn_p = new LatConvEquation (psfSub, dirtySub);
	result=myClarkCleaner.solve(*latConvEqn_p);
      }
    }
    else{
      IPosition blc(modelImage.shape().nelements(),0);
      Int elem= npol_p >0 ? npol_p:0;
      IPosition trc(modelImage.shape().nelements(),elem);
      blc(0)=xbeg; blc(1)=ybeg;
      trc(0)=xend; trc(1)=yend;
      Slicer sl(blc, trc, Slicer::endIsLast);
      SubImage<Float> maskSub;
      SubImage<Float> dirtySub(*dirty_p, sl, True);
      SubImage<Float> modelSub(modelImage,sl,True);
      if(psf_p->shape().nelements() != dirty_p->shape().nelements()){
	blc.resize(psf_p->shape().nelements());
	trc.resize(psf_p->shape().nelements());
      }
      blc(0)=0; blc(1)=0;
      trc(0)=nx_p-1; trc(1)=ny_p-1;
      sl=Slicer(blc, trc, Slicer::endIsLast);
      SubImage<Float> psfSub(*psf_p, sl, True);
      
      ClarkCleanLatModel myClarkCleaner(modelSub);
      if(mask !=0 ){
	maskSub= SubImage<Float>(*mask, sl, False);
	myClarkCleaner.setMask(maskSub);
      }

      myClarkCleaner.setNumberIterations(niter);
      if (maxNumMajorCycles > 0 ) 
	myClarkCleaner.setMaxNumberMajorCycles((uInt)maxNumMajorCycles);
      if (maxNumMinorIterations > 0 ) 
	myClarkCleaner.setMaxNumberMinorIterations((uInt)maxNumMinorIterations); 
    
      myClarkCleaner.setGain(gain);
      Double d_thresh = threshold.getValue("Jy");
      myClarkCleaner.setThreshold((Float)d_thresh);
  
      myClarkCleaner.setPsfPatchSize(psfPatchSize);
      myClarkCleaner.setHistLength((uInt)histBins); 
      myClarkCleaner.setMaxExtPsf(maxExtPsf); 
      myClarkCleaner.setSpeedup(speedUp); 
  
      if (maxNumPix == 0) 
	maxNumPix = (Int)(modelImage.shape().product()*0.04);
      myClarkCleaner.setMaxNumPix((uInt)maxNumPix);

      //Now actually do the clean
      if (displayProgress) {
	getPGPlotter(False);
	ccpp = new ClarkCleanProgress (pgplotter_p);
	myClarkCleaner.setProgress(*ccpp);
      }
      latConvEqn_p = new LatConvEquation (psfSub, dirtySub);
      result=myClarkCleaner.solve(*latConvEqn_p);
    }
    dirty_p->table().unlock();
    psf_p->table().unlock();
    if (ccpp != 0) { delete ccpp; ccpp = 0;}
    delete latConvEqn_p;  latConvEqn_p = 0;
    if (mask) { delete  mask;}

    return result;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  } 
  dirty_p->table().unlock();
  psf_p->table().unlock();
  if (ccpp != 0) {delete ccpp;  ccpp = 0; }
  delete latConvEqn_p;  latConvEqn_p = 0;

  
  return True;
};


// Clean algorithm
Bool deconvolver::clean(const String& algorithm, const Int niter,
			const Float gain, const Quantity& threshold, 
			const Bool displayProgress,
			const String& model, const String& mask)
{
  
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "clean()", WHERE));
  
  dirty_p->table().lock();
  psf_p->table().lock();
  try {
    
    if(model=="") {
      os << LogIO::SEVERE << "Need a name for model " << LogIO::POST;
      return False;
    }
  
    String imagename(model);
    // Make first image with the required shape and coordinates only if
    // it doesn't exist yet. Otherwise we'll throw an exception later
    if(imagename=="") imagename=dirty_p->table().tableName()+"."+algorithm;
    if(!Table::isWritable(imagename)) {
      make(imagename);
      dirty_p->table().lock();
      psf_p->table().lock();
    }
    
    {
      ostringstream oos;
      oos << "Clean gain = " <<gain<<", Niter = "<<niter<<", Threshold = "
	  <<threshold << ", Algorithm = " << algorithm;
      os << String(oos) << LogIO::POST;
    }

    PagedImage<Float> modelImage(imagename);

    AlwaysAssert(cleaner_p, AipsError);

    if((algorithm=="msclean")||(algorithm=="fullmsclean")) {
      os << "Cleaning image using multi-scale algorithm" << LogIO::POST;
      if(!scalesValid_p) {
	os << LogIO::SEVERE << "Scales not yet set" << LogIO::POST;
	return False;
      }
      cleaner_p->setcontrol(CleanEnums::MULTISCALE, niter, gain, threshold);
    }
    else if (algorithm=="hogbom") {
      if(!scalesValid_p) {
	Vector<Float> dummy;
        setscales("nscales", 1, dummy);
      }
      cleaner_p->setcontrol(CleanEnums::HOGBOM, niter, gain, threshold);
    } else {
      os << LogIO::SEVERE << "Unknown algorithm: " << algorithm << LogIO::POST;
      return False;
    }

    PagedImage<Float> *mask_p = 0;
    // Deal with mask
    if (mask != "") {
      if( Table::isReadable(mask)) {
	mask_p = new PagedImage<Float>(mask);
	AlwaysAssert(mask_p, AipsError);
	cleaner_p->setMask(*mask_p);
      } else {
	os << LogIO::SEVERE << "Mask "<< mask<<" is not readable" << LogIO::POST;
      }
    }
    Bool result=False;

    if(algorithm=="fullmsclean") {
      os << "Cleaning full image using multi-scale algorithm" << LogIO::POST;
      cleaner_p->ignoreCenterBox(True);
    }

    if(nchan_p >= 1){
    
      for( Int k=0; k< nchan_p; ++k){
	os << "Cleaning channel " << k+1 << LogIO::POST;
	SubImage<Float> subModel;
	if(npol_p > 0 ){
	  IPosition blc(4,0,0,0,0);
	  blc(chanAxis_p)=k;
	  blc(polAxis_p)=0;
	  IPosition trc(4, nx_p-1, ny_p-1, 0, 0);
	  trc(chanAxis_p)=k;
	  trc(polAxis_p)=npol_p-1;
	  Slicer sl(blc, trc, Slicer::endIsLast);
	  SubImage<Float> dirtySub(*dirty_p, sl, True);
	  subModel= SubImage<Float> (modelImage, sl, True);
	  SubImage<Float> psfSub(*psf_p, sl, True);
	  cleaner_p->update(dirtySub);
	}
	else{
	  IPosition blc(3, 0, 0, 0);
	  IPosition trc(3, nx_p-1, ny_p-1, 0);
	  Slicer sl(blc, trc, Slicer::endIsLast);
	  SubImage<Float> dirtySub(*dirty_p, sl, True);
	  subModel= SubImage<Float> (modelImage, sl, True);
	  SubImage<Float> psfSub(*psf_p, sl, True);
	  cleaner_p = new LatticeCleaner<Float>(psfSub, dirtySub);
	  cleaner_p->update(dirtySub);
	}
       LatticeCleanProgress * cpp = 0;
       if (displayProgress) {
	 getPGPlotter(False);
	 cpp = new LatticeCleanProgress(pgplotter_p);
       }
       result=cleaner_p->clean(subModel, cpp);    
       if(cpp != 0 ) delete cpp;
      }

    }
    else{
      // Now actually do the clean
      LatticeCleanProgress * cpp = 0;
      if (displayProgress) {
	getPGPlotter(False);
	cpp = new LatticeCleanProgress(pgplotter_p);
      }
      result=cleaner_p->clean(modelImage, cpp);    
      if(cpp != 0 ) delete cpp;
    }
    dirty_p->table().unlock();
    psf_p->table().unlock();
    if (mask_p) delete mask_p;    

    return result;
  } catch (AipsError x) {
    dirty_p->table().unlock();
    psf_p->table().unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  } 
  dirty_p->table().unlock();
  psf_p->table().unlock();
  
  return True;
}

// Pixon algorithm
Bool deconvolver::pixon(const Quantity& sigma,
			const String& model, const Bool imagePlane)
{
  
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "pixon()", WHERE));
  
  SubImage<Float>* dirtyQ_p =0; 
  SubImage<Float>* modelImageQ_p =0;

  try {

    if(model=="") {
      os << LogIO::SEVERE << "Need a name for model " << LogIO::POST;
      return False;
    }

    Bool initializeModel = False;

    if (imagePlane) {
      dirtyQ_p = allQuarters(*dirty_p);
    } else {
      dirtyQ_p = innerQuarter(*dirty_p);
    }

    String imagename(model);
    // Make first image with the required shape and coordinates only if
    // it doesn't exist yet. Otherwise we'll throw an exception later
    if(imagename=="") imagename=dirty_p->table().tableName()+".pixon";
    if(!Table::isWritable(imagename)) {
      initializeModel = True;
      make(imagename);
      dirty_p->table().lock();
      psf_p->table().lock();
    }

    PagedImage<Float> modelImage(imagename);
    
    if (imagePlane) {
      modelImageQ_p = allQuarters(modelImage);
    } else {
      modelImageQ_p = innerQuarter(modelImage);
    }

    os << "Deconvolving image using pixon algorithm" << LogIO::POST;

    os << "Calculating data sampling, etc." << LogIO::POST;
    {
      ImageDataSampling imds(*dirtyQ_p, *psf_p, sigma.getValue());
      
      os << "Making pixon processor" << LogIO::POST;
      PixonProcessor pp;
      os << "Finding pixon solution" << LogIO::POST;
      IPosition zero(dirty_p->shape().nelements(), 0);
      Array<Float> result;
      if(pp.calculate(imds, result)) {
	os << "Pixon solution succeeded" << LogIO::POST;
	modelImage.putSlice(result, zero);
      }
      else {
	os << LogIO::WARN << "Pixon solution failed" << LogIO::POST;
      }
    }
    
    modelImage.setUnits(Unit("Jy/pixel"));

    dirty_p->table().unlock();
    psf_p->table().unlock();
    if (dirtyQ_p != 0) {delete dirtyQ_p; dirtyQ_p = 0;}
    if (modelImageQ_p != 0) {delete modelImageQ_p; modelImageQ_p = 0;}

    return True;

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  } 

  dirty_p->table().unlock();
  psf_p->table().unlock();
  if (dirtyQ_p != 0) {delete dirtyQ_p; dirtyQ_p = 0;}
  if (modelImageQ_p != 0) {delete modelImageQ_p; modelImageQ_p = 0;}
  
  return True;
}


// MEM algorithm
Bool deconvolver::mem(const String& entropy, const Int niter,
		      const Quantity& sigma, const Quantity& targetFlux, 
		      Bool constrainTargetFlux, Bool displayProgress,
		      const String& model, const String& priorImage,
		      const String& maskImage,
		      const Bool imagePlane)
{
  
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "mem()", WHERE));
  
  //  SubImage<Float>* dirtyQ_p =0; 
  //  SubImage<Float>* modelImageQ_p =0;
  //  SubImage<Float>* priorImageQ_p =0;
  //  SubImage<Float>* maskImageQ_p =0;

  Entropy* myEnt_p =0;
  CEMemProgress * memProgress_p = 0;
  residEqn_p=0;

  try {

    //    if(model=="") {
    //     os << LogIO::SEVERE << "Need a name for model " << LogIO::POST;
    //      return False;
    //   }

    Bool initializeModel = False;
    Int xbeg, xend, ybeg, yend;
    if (imagePlane) {
      xbeg=0;
      xend=nx_p-1;
      ybeg=0;
      yend=ny_p-1;
      fullPlane_p=True;
    } else {
      xbeg=nx_p/4; 
      xend=3*nx_p/4-1;
      ybeg=ny_p/4; 
      yend=3*ny_p/4-1;
    }

    String imagename(model);
    // Make first image with the required shape and coordinates only if
    // it doesn't exist yet. Otherwise we'll throw an exception later
    if(imagename=="") {
      imagename=dirty_p->table().tableName()+"."+entropy;
      os << LogIO::WARN << "No model name given, model will be " 
	 << imagename  << LogIO::POST;
    }
    if(!Table::isWritable(imagename)) {
      initializeModel = True;
      make(imagename);
      dirty_p->table().lock();
      psf_p->table().lock();
    }

    PagedImage<Float> modelImage(imagename);
    
    //   if (imagePlane) {
    //      modelImageQ_p = allQuarters(modelImage);
    //   } else {
    //     modelImageQ_p = innerQuarter(modelImage);
    //  }

    {
      ostringstream oos;
      oos << "MEM Niter = "<<niter<<", Sigma = "<<sigma << 
	", TargetFlux = "  <<targetFlux << 
	", ConstrainTargetFlux = "  <<constrainTargetFlux << 
	", Entropy = " << entropy;
      os << String(oos) << LogIO::POST;
    }

    if(entropy=="entropy") {
      os << "Deconvolving image using maximum entropy algorithm" << LogIO::POST;
      myEnt_p = new EntropyI;
    }
    else if (entropy=="emptiness") {
      myEnt_p = new EntropyEmptiness;
    }
    else {
      os << " Known MEM entropies: entropy | emptiness " << LogIO::POST;
      os << LogIO::SEVERE << "Unknown MEM entropy: " << entropy << LogIO::POST;
      return False;
    }


    PagedImage<Float> *mask = 0;
    Bool isCubeMask=False;
    PagedImage<Float> *prior =0;
    
    // Deal with mask
    if (maskImage != "") {
      if( Table::isReadable(maskImage)) {
	mask= new PagedImage<Float>(maskImage);
	if (chanAxis_p < Int(mask->shape().nelements())){
	  if (mask->shape()(chanAxis_p) > 1) 
	    isCubeMask=True;
	}
	checkMask(*mask, xbeg, xend, ybeg, yend);
	AlwaysAssert(mask, AipsError);
	
      } else {
	os << LogIO::SEVERE << "Mask "<< mask<<" is not readable" << LogIO::POST;
      }
    }

    if (priorImage!="") {
      if( Table::isReadable(priorImage)) {
        prior= new PagedImage<Float>(priorImage);
      } else {
        os << LogIO::SEVERE << "Prior "<< prior<<" is not readable" << LogIO::POST;
      }
    }

    Bool result=False;
    SubImage<Float> *maskSub=0;
    IPosition blc(2,xbeg,ybeg);
    IPosition trc(2,xend,yend);
    if(nchan_p >= 1){
      for (Int k=0; k< nchan_p; ++k){	
	os<< "Processing channel " << k+1 << LogIO::POST;
	if(npol_p > 0 ){
	  blc.resize(4);
	  blc(chanAxis_p)=k;
	  blc(polAxis_p)=0;
	  trc.resize(4);
	  trc(polAxis_p)=npol_p-1;
	  trc(chanAxis_p)=k;
	
	}
	else{
	  blc.resize(3);
	  trc.resize(3);  
	  blc(chanAxis_p)=k;
	  trc(chanAxis_p)=k;
	
	}

	Slicer sl(blc, trc, Slicer::endIsLast);
	SubImage<Float> psfSub;
	SubImage<Float> priorSub;

	if(mask != 0){
	  if( (isCubeMask) || (!isCubeMask && maskSub == 0 )){
	    if(maskSub !=0 ) delete maskSub;
	    blc(0)=0; blc(1)=0;
	    trc(0)=nx_p-1; trc(1)=ny_p-1;
	    sl=Slicer(blc, trc, Slicer::endIsLast);
	    maskSub=new SubImage<Float> (*mask,sl,False);
	    checkMask(*maskSub, xbeg, xend, ybeg, yend);
	    blc(0)=xbeg; blc(1)=ybeg;
	    trc(0)=xend; trc(1)=yend;
	    sl =Slicer(blc, trc, Slicer::endIsLast);
	    delete maskSub;
	    maskSub=new SubImage<Float> (*mask,sl,False);
	  }
	}


	if(prior !=0 ){	  
	  priorSub= SubImage<Float>(*prior, False);
	}

	SubImage<Float> dirtySub(*dirty_p, sl, True);
	SubImage<Float> modelSub(modelImage,sl,True);
	IPosition blc_psf=blc; IPosition trc_psf=trc;
	if(psf_p->shape().nelements() != dirty_p->shape().nelements()){
	  blc_psf.resize(psf_p->shape().nelements());
	  trc_psf.resize(psf_p->shape().nelements());
	}
	blc_psf(0)=0; blc_psf(1)=0;
	trc_psf(0)=nx_p-1; trc_psf(1)=ny_p-1;
	sl=Slicer(blc_psf, trc_psf, Slicer::endIsLast);
	psfSub=SubImage<Float>(*psf_p, sl, True);



	CEMemModel myMemer( *myEnt_p, modelSub, niter, sigma.getValue("Jy"),
			    targetFlux.getValue("Jy"),  constrainTargetFlux,
			    initializeModel, imagePlane);
    
	if (!initializeModel) {
	  Record info=modelImage.miscInfo();
	  try {
	    Float alpha = 0.0;
	    Float beta = 0.0;
	    info.get("ALPHA", alpha);
	    myMemer.setAlpha(alpha);
	    info.get("BETA", beta);
	    myMemer.setBeta(beta); 
	  } catch  (AipsError x) {
	    // could not get Alpha and Beta for initialization
	    // continue
	    os << "Could not retrieve Alpha and Beta from previously initialized model" 
	       << LogIO::POST;
	  } 
	} 



	if(prior != 0){
	  myMemer.setPrior(priorSub);
	}
	if (mask != 0) {
	  myMemer.setMask(*maskSub);
	}
      
    
	// Now actually do the MEM deconvolution
	if (displayProgress) {
	  getPGPlotter(False);
	  memProgress_p = new  CEMemProgress (pgplotter_p);
	  myMemer.setProgress(*memProgress_p);
	}

	if(residEqn_p !=0) delete residEqn_p;
	residEqn_p=0;
	if (imagePlane) {
	  residEqn_p = new IPLatConvEquation (psfSub, dirtySub);
	} else {
	  residEqn_p = new LatConvEquation (psfSub, dirtySub);
	}    

	result=myMemer.solve(*residEqn_p);
    
	Record info=modelImage.miscInfo();
	info.define("ALPHA", myMemer.getBeta());
	info.define("BETA",  myMemer.getAlpha());
	modelImage.setMiscInfo(info);
      }
    }

    else{
      SubImage<Float>* dirtyQ =0; 
      SubImage<Float>* modelQ =0; 
      Bool initializeModel = False;

      if (imagePlane) {
	dirtyQ = allQuarters(*dirty_p);
      } else {
	dirtyQ = innerQuarter(*dirty_p);
      }
      if (imagePlane) {
	modelQ = allQuarters(modelImage);
      } else {
	modelQ = innerQuarter(modelImage);
      }
      CEMemModel myMemer( *myEnt_p, *modelQ, niter, 
			  sigma.getValue("Jy"),
			  targetFlux.getValue("Jy"),  constrainTargetFlux,
			  initializeModel, imagePlane);
      if (!initializeModel) {
	Record info=modelImage.miscInfo();
	try {
	  Float alpha = 0.0;
	  Float beta = 0.0;
	  info.get("ALPHA", alpha);
	  myMemer.setAlpha(alpha);
	  info.get("BETA", beta);
	  myMemer.setBeta(beta); 
	} catch  (AipsError x) {
	  // could not get Alpha and Beta for initialization
	  // continue
	  os << "Could not retrieve Alpha and Beta from previously initialized model" 
	     << LogIO::POST;
	} 
      } 
      SubImage<Float> * priorQ;
      if(prior !=0){	

	if (imagePlane) {
	  priorQ = allQuarters(*prior);
	} else {
	  priorQ = innerQuarter(*prior);
	
	}
	 myMemer.setPrior(*priorQ);
      }
      SubImage<Float> *maskQ;
      if(mask !=0){	

	if (imagePlane) {
	  maskQ = allQuarters(*mask);
	} else {
	  maskQ = innerQuarter(*mask);
	
	}
	 myMemer.setMask(*maskQ);
      }
      if (displayProgress) {
	getPGPlotter(False);
	memProgress_p = new  CEMemProgress (pgplotter_p);
	myMemer.setProgress(*memProgress_p);
      }

      if (imagePlane) {
	residEqn_p = new IPLatConvEquation (*psf_p, *dirtyQ);
      } else {
	residEqn_p = new LatConvEquation (*psf_p, *dirtyQ);
      }    
      
      result=myMemer.solve(*residEqn_p);
      
      Record info=modelImage.miscInfo();
      info.define("ALPHA", myMemer.getBeta());
      info.define("BETA",  myMemer.getAlpha());
      modelImage.setMiscInfo(info);

      if (dirtyQ != 0) {delete dirtyQ; dirtyQ = 0;}
      if (modelQ != 0) {delete modelQ; modelQ = 0;}
      if (residEqn_p != 0) {delete residEqn_p;    residEqn_p = 0;}
      if (priorQ != 0) {delete priorQ; priorQ = 0;}
      if (maskQ != 0) {delete maskQ; maskQ = 0;}

    }

    modelImage.setUnits(Unit("Jy/pixel"));

    dirty_p->table().unlock();
    psf_p->table().unlock();
    if (myEnt_p != 0) {delete myEnt_p;  myEnt_p = 0;}
    if (memProgress_p!=0) {delete memProgress_p;  memProgress_p = 0; }    

    return result;

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  } 
  
  dirty_p->table().unlock();
  psf_p->table().unlock();
  if (myEnt_p != 0) {delete myEnt_p;  myEnt_p = 0;}
  if (residEqn_p != 0) {delete residEqn_p;    residEqn_p = 0;}
  if (memProgress_p!=0) {delete memProgress_p;  memProgress_p = 0; }    
  
  return True;
}

// makeprior, for MEM
Bool deconvolver::makeprior(const String& prior, const String& templatename, 
			    const Quantity& lowClipFrom, const Quantity& lowClipTo, 
			    const Quantity& highClipFrom, const Quantity& highClipTo, 
			    const Vector<Index>& blc, const Vector<Index>& trc)
{
  
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "makeprior()", WHERE));
  
  try {
    if(templatename=="") {
      os << LogIO::SEVERE << "Need a name for template image " << endl
	 << "May I suggest you make a clean or mem image and " << endl
	 << "smooth it for the template?" << LogIO::POST;
      return False;
    }
    if(prior=="") {
      os << LogIO::SEVERE << "Need a name for output prior image " << LogIO::POST;
      return False;
    }

    PagedImage<Float> templateImage(templatename);
    String priorname(prior);
    if(priorname=="") priorname=templateImage.table().tableName()+".prior";
    if(!Table::isWritable(priorname)) {
      make(priorname);
    }
//
    PagedImage<Float> priorImage(priorname);
    ImageInterface<Float>* templateImage2_p = 0;
//
    if (priorImage.shape() != templateImage.shape()) {
       TiledShape tShape(priorImage.shape());
       templateImage2_p = new TempImage<Float>(tShape, priorImage.coordinates());
//
       ImageRegrid<Float> regridder;
       Vector<Double> locate;
       Bool missedIt = regridder.insert(*templateImage2_p, locate, templateImage);
       if (!missedIt) {
	os << LogIO::SEVERE << "Problem in getting template Image on correct grid " << LogIO::POST;
       }
    } else {
      templateImage2_p = &templateImage;
    }

    {
      ostringstream oos;
      oos << "Prior = "<<priorname<<", template = "<<templatename << endl;
      oos <<"   Clip Below = "  << lowClipFrom.getValue("Jy") << 
	", Replace with = "  << lowClipTo.getValue("Jy") << endl;
      
      oos <<"   Clip Above = "  << highClipFrom.getValue("Jy") << 
	", Replace with = "  << highClipTo.getValue("Jy") << endl; 
      // oos <<"   blc = " << blc <<", trc = " << trc << endl;
      os << String(oos) << LogIO::POST;
    }

    priorImage.set(lowClipTo.getValue("Jy"));

    IPosition iblc;
    IPosition itrc;
    IPosition imshape(priorImage.shape());  
    Index::convertIPosition(iblc, blc);
    Index::convertIPosition(itrc, trc);
    IPosition iinc(imshape.nelements(),1);
    LCBox::verify(iblc, itrc, iinc, imshape);
    LCSlicer box(iblc, itrc);

    SubImage<Float> templateBox(*templateImage2_p, ImageRegion(box), False);
    SubImage<Float> priorBox(priorImage, ImageRegion(box), True);

    // do Low clipping
    priorBox.copyData( (LatticeExpr<Float>) 
		       (iif(templateBox<lowClipFrom.getValue("Jy"), 
			    lowClipTo.getValue("Jy"), templateBox)) );  
    // do High clipping
    priorBox.copyData( (LatticeExpr<Float>) 
		       (iif(priorBox > highClipFrom.getValue("Jy"), 
			    highClipTo.getValue("Jy"), priorBox)) );  


    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  } 
  
  return True;
}

// clipimage
Bool deconvolver::clipimage(const String& clippedImageName, const String& inputImageName, 
			    const Quantity& threshold)
{
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "clipimage()", WHERE));
  
  try {
    if(inputImageName=="") {
      os << LogIO::SEVERE << "Need a name for the image to clip" <<  LogIO::POST;
      return False;
    }
    if(clippedImageName=="") {
      os << LogIO::SEVERE << "Need a name for output clipped image " << LogIO::POST;
      return False;
    }

    PagedImage<Float> inputImage(inputImageName);
    String clippedImageName2(clippedImageName);
    if(clippedImageName2=="") clippedImageName2 = inputImage.table().tableName()+".clipped";
    if(!Table::isWritable(clippedImageName2)) {
      make (clippedImageName2);
    }
    PagedImage<Float> clippedImage(clippedImageName2);
    if  (clippedImage.shape() != inputImage.shape() ) {
      os << LogIO::SEVERE << "Input and clipped image sizes disagree " << LogIO::POST;
      return False;
    }
    {
      ostringstream oos;
      oos << "Clipped Image = "<<clippedImageName2<<", Input Image = "<< inputImageName << endl;
      oos << "Clip with Stokes I below = "  << threshold.getValue("Jy");
      os << String(oos) << LogIO::POST;
    }

    IPosition trc = inputImage.shape() - 1;
    IPosition blc(4,0);
    
    trc(2) = 0;
    blc(2) = 0;
    LCSlicer boxI(blc, trc);
    SubImage<Float> stokesISub(inputImage, ImageRegion(boxI), False);
    Int iStokes;
    for (iStokes=0; iStokes < inputImage.shape()(2); iStokes++) {
      trc(2) = iStokes;
      blc(2) = iStokes;
      LCSlicer box(blc, trc);
      SubImage<Float> stokesClippedSub(clippedImage, ImageRegion(box), True);
      SubImage<Float>   stokesInputSub(inputImage, ImageRegion(box), False);
      if (stokesISub.shape() != stokesClippedSub.shape() ) {
	os << LogIO::SEVERE << "Input and clipped image sizes disagree " << LogIO::POST;
	return False;
      }
      stokesClippedSub.copyData( (LatticeExpr<Float>) 
				 (iif(stokesISub < threshold.getValue("Jy"), 
				      0.0, stokesInputSub)) );  
    }
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  } 
  
  return True;
}

// boxmask
Bool deconvolver::boxmask(const String& boxmask, 
			  const Vector<Int> blc, const Vector<Int> trc,
			  const Quantity& fillValue, const Quantity& externalValue)
{
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "boxmask()", WHERE));
  
  try {
    if(boxmask=="") {
      os << LogIO::SEVERE << "Need a name for output boxmask image " << LogIO::POST;
      return False;
    }
    String boxname(boxmask);
    if(boxname=="") boxname="boxmask";
    if(!Table::isWritable(boxname)) {
      make(boxname);
    }
    PagedImage<Float> boxImage(boxname);

    {
      ostringstream oos;
      oos << "BoxMask = "<<boxname<<
	", blc = " << blc(0) << " " << blc(1)<<
	", trc = " << trc(0) << " " << trc(1);
      os << String(oos) << LogIO::POST;
    }

    boxImage.set(externalValue.getValue("Jy"));

    // This only makes a 2-d box; will need to fix this for other
    // image sorts
    uInt dim = boxImage.ndim();
    IPosition pshape = boxImage.shape();
    IPosition blc0(dim, 0);
    IPosition trc0(dim, 0);
    blc0(0) = max(0, blc(0));
    blc0(1) = max(0, blc(1));
    if (trc0(0) == 0) trc0(0) = pshape(0)-1;
    if (trc0(1) == 0) trc0(1) = pshape(1)-1;    
    trc0(0) = min(trc(0), pshape(0)-1);
    trc0(1) = min(trc(1), pshape(1)-1);
    LCSlicer box(blc0, trc0);
    SubImage<Float> innerSub(boxImage, ImageRegion(box), True);
    innerSub.set(fillValue.getValue("Jy"));
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  }   
  return True;
}

// Fourier transform the model
Bool deconvolver::ft(const String& model, const String& transform)
{
  if(!valid()) return False;
  
  LogIO os(LogOrigin("deconvolver", "ft()", WHERE));
  
  try {
    
    if(model=="") {
      os << LogIO::SEVERE << "Need a name for model " << LogIO::POST;
      return False;
    }
    
    os << "Fourier transforming model" << LogIO::POST;

    String transformname(transform);
    if(transformname=="") transformname=model+".ft";
    removeTable(transformname);
    
    PagedImage<Float> modelImage(model);
    PagedImage<Complex> transformImage(modelImage.shape(),
				       modelImage.coordinates(),
				       transformname);
    transformImage.copyData(LatticeExpr<Complex>(toComplex(modelImage)));

    LatticeFFT::cfft2d(transformImage);

    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
  } 
  return True;
}

Bool deconvolver::setscales(const String& scaleMethod,
			    const Int inscales,
			    const Vector<Float>& userScaleSizes)
{
  LogIO os(LogOrigin("deconvolver", "setscales()", WHERE));

  AlwaysAssert(cleaner_p, AipsError);

  Vector<Double> cells = psf_p->coordinates().increment();
  os << "Cell size = " << abs(cells(0)/C::arcsec) << LogIO::POST;
  AlwaysAssert (cells(0)!=0.0, AipsError);

  if (scaleMethod == "nscales") {
    Int nscales=inscales;

    if(nscales<1) {
      os << "Using default of 5 scales" << LogIO::POST;
      nscales=5;
    }
  
    // Validate scales
    Float scaleInc=bmin_p.get("arcsec").getValue()/abs(cells(0)/C::arcsec);

    Vector<Float> scaleSizes(nscales);  
    os << "Creating " << nscales << 
      " scales from powerlaw nscales method" << LogIO::POST;
    scaleSizes(0) = 0.0;
    os << "scale 1 = 0.0 pixels " << LogIO::POST;
    for (Int scale=1; scale<nscales;scale++) {
      scaleSizes(scale) =
	scaleInc * pow(10.0, (Float(scale)-2.0)/2.0);
      os << "scale " << scale+1 << " = " << scaleSizes(scale)
	 << " pixels" << LogIO::POST;
    }  
    cleaner_p->setscales(scaleSizes);   
    scalesValid_p=True;

  } else if (scaleMethod == "uservector") {
    if (userScaleSizes.nelements() <= 0) {
       os << LogIO::SEVERE 
	  << "Need at least one scale for method uservector"
	  << LogIO::POST;
    }
    os << "Creating scales from uservector method: " << LogIO::POST;
    for(uInt scale=0; scale < userScaleSizes.nelements(); scale++) {
      os << "scale " << scale+1 << " = " << userScaleSizes(scale)
	 << " pixels" << LogIO::POST;
    }
    cleaner_p->setscales(userScaleSizes);   
    scalesValid_p=True;

  } else {
    os << LogIO::SEVERE << "Unknown scale setting algorithm: " 
       << scaleMethod << LogIO::POST;
    return False;
  }

  return True;
}
  
Bool deconvolver::clone(const String& imageName, const String& newImageName)
{
  if(!valid()) return False;
  LogIO os(LogOrigin("deconvolver", "clone()", WHERE));
  try {
    PagedImage<Float> oldImage(imageName);
    PagedImage<Float> newImage(oldImage.shape(), oldImage.coordinates(),
			       newImageName);
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
}

String deconvolver::className() const
{
  return "deconvolver";
}


Bool deconvolver::convolve(const String& convolvedName, 
			   const String& modelName)
{
   PagedImage<Float> model(modelName);
   PagedImage<Float> convolved(model.shape(),
			     model.coordinates(),
			     convolvedName);
   convolver_p->linear( convolved, model );
   return True;
};

Bool deconvolver::makegaussian(const String& gaussianName, Quantity& mbmaj, Quantity& mbmin,
			       Quantity& mbpa, Bool normalizeVolume)
{
  PagedImage<Float> gaussian(dirty_p->shape(),
			     dirty_p->coordinates(),
			     gaussianName);
  gaussian.set(0.0);
  uInt naxis=gaussian.shape().nelements();
  if(naxis==2){
    IPosition center = gaussian.shape()/2;
    gaussian.putAt(1.0, center);
  }
  else if(naxis==3){
    IPosition center(3, Int((nx_p/4)*2), Int((ny_p/4)*2),0);
    for (Int k=0; k < gaussian.shape()(2); ++k){
      center(2) = k;
      gaussian.putAt(1.0, center);
    }
  }
  else if(naxis==4){
    IPosition center(4, Int((nx_p/4)*2), Int((ny_p/4)*2),0,0);
    for (Int k=0; k < gaussian.shape()(2); ++k){
      
      center(2) = k;
      for(Int j=0; j < gaussian.shape()(3); ++j){
	center(3)=j;
	gaussian.putAt(1.0, center);
      }
    }


  }
  StokesImageUtil::Convolve(gaussian, mbmaj, mbmin, mbpa, normalizeVolume);
  return True;
};



Vector<String> deconvolver::methods() const
{
  Vector<String> method(23);
  Int i=0;
  method(i++) = "open";
  method(i++) = "state";
  method(i++) = "close";
  method(i++) = "dirtyname";
  method(i++) = "psfname";

  method(i++) = "summary";
  method(i++) = "restore";
  method(i++) = "clean";
  method(i++) = "ft";
  method(i++) = "setscales";

  method(i++) = "clone";
  method(i++) = "smooth";
  method(i++) = "residual";
  method(i++) = "mem";
  method(i++) = "makeprior";
  
  method(i++) = "clarkclean";
  method(i++) = "make";
  method(i++) = "clipimage";
  method(i++) = "boxmask";
  method(i++) = "reopen";

  method(i++) = "convolve";
  method(i++) = "makegaussian";
  method(i++) = "pixon";

  return method;
}

Vector<String> deconvolver::noTraceMethods() const
{
  Vector<String> method(5);
  Int i=0;
  method(i++) = "dirtyname";
  method(i++) = "psfname";
  method(i++) = "close";
  method(i++) = "summary";
  method(i++) = "state";
  
  return method;
}

MethodResult deconvolver::runMethod(uInt which, 
				    ParameterSet &inputRecord,
				    Bool runMethod)
{
  
  static String returnvalString = "returnval";
  
  switch (which) {
  case 0: // open
    {
      static String thedirtyString = "thedirty";
      static String thepsfString = "thepsf";
      //      Parameter< MeasurementSet > 
      Parameter< String > 
	thedirty(inputRecord, thedirtyString, ParameterSet::In);
      Parameter< String > 
	thepsf(inputRecord, thepsfString, ParameterSet::In);
      if (runMethod) {
	open(thedirty(), thepsf());
      }
    }
    break;
  case 1: // state
    {
      Parameter< String >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = state(); 
      }
    }
    break;
  case 2: // close
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = close();
      }
    }
    break;
  case 3: // dirtyname
    {
      Parameter< String >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = dirtyname(); 
      }
    }
    break;
  case 4: // psfname
    {
      Parameter< String >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = psfname(); 
      }
    }
    break;
  case 5: // summary
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = summary();
      }
    }
    break;
  case 6: // restore
    {
      Parameter<String > model(inputRecord, "model", ParameterSet::In);
      Parameter<String > image(inputRecord, "image", ParameterSet::In);
      Parameter<Quantity> bmaj(inputRecord, "bmaj", ParameterSet::InOut);
      Parameter<Quantity> bmin(inputRecord, "bmin", ParameterSet::InOut);
      Parameter<Quantity> bpa(inputRecord, "bpa", ParameterSet::InOut);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  restore(model(), image(), bmaj(), bmin(), bpa());
      }
    }
    break;
  case 7: // clean
    {
      Parameter<String> algorithm(inputRecord, "algorithm", ParameterSet::In);
      Parameter<Int> niter(inputRecord, "niter", ParameterSet::In);
      Parameter<Float> gain(inputRecord, "gain", ParameterSet::In);
      Parameter<Quantity> threshold(inputRecord, "threshold",  ParameterSet::In);
      Parameter<Bool>    displayprogress(inputRecord, "displayprogress",  ParameterSet::In);
      Parameter<String > model(inputRecord, "model", ParameterSet::In);
      Parameter<String > mask(inputRecord, "mask", ParameterSet::In);
      Parameter< Bool >	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  clean(algorithm(), niter(), gain(), threshold(), displayprogress(),  model(),
	      mask());
      }
    }
    break;
  case 8: // ft
    {
      Parameter<String > model(inputRecord, "model", ParameterSet::In);
      Parameter<String > transform(inputRecord, "transform", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  ft(model(), transform());
      }
    }
    break;
  case 9: // setscales
    {
      Parameter<String> scalemethod(inputRecord, "scalemethod", ParameterSet::In);
      Parameter<Int> nscales(inputRecord, "nscales", ParameterSet::In);
      Parameter<Vector<Float> > uservector(inputRecord, "uservector", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = setscales(scalemethod(), nscales(), uservector());
      }
    }
    break;
  case 10: // clone
    {
      Parameter<String> image(inputRecord, "image", ParameterSet::In);
      Parameter<String> templateImage(inputRecord, "template", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  clone(templateImage(), image());
      }
    }
    break;
  case 11: // smooth
    {
      Parameter<String > model(inputRecord, "model", ParameterSet::In);
      Parameter<String > image(inputRecord, "image", ParameterSet::In);
      Parameter<Quantity> bmaj(inputRecord, "bmaj", ParameterSet::InOut);
      Parameter<Quantity> bmin(inputRecord, "bmin", ParameterSet::InOut);
      Parameter<Quantity> bpa(inputRecord, "bpa", ParameterSet::InOut);
      Parameter<Bool> normalizevolume(inputRecord, "normalize",
				      ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  smooth(model(), image(), bmaj(), bmin(), bpa(), normalizevolume());
      }
    }
    break;
  case 12: // residual
    {
      Parameter<String > model(inputRecord, "model", ParameterSet::In);
      Parameter<String > image(inputRecord, "image", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  residual(model(), image());
      }
    }
    break;
  case 13: // mem
    {
      Parameter<String> entropy(inputRecord, "entropy", ParameterSet::In);
      Parameter<Int> niter(inputRecord, "niter", ParameterSet::In);
      Parameter<Quantity> sigma(inputRecord, "sigma",  ParameterSet::In);
      Parameter<Quantity> targetFlux(inputRecord, "targetflux",  ParameterSet::In);
      Parameter< Bool > constrainTargetFlux(inputRecord, "constrainflux",  
					    ParameterSet::In);
      Parameter< Bool > displayprogress(inputRecord, "displayprogress",  
					    ParameterSet::In);
      Parameter<String > model(inputRecord, "model", ParameterSet::In);
      Parameter<String > prior(inputRecord, "prior", ParameterSet::In);
      Parameter<String > mask(inputRecord, "mask", ParameterSet::In);
      Parameter< Bool > imageplane(inputRecord, "imageplane", ParameterSet::In);
      Parameter< Bool >	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  mem(entropy(), niter(), sigma(), targetFlux(), constrainTargetFlux(),
	      displayprogress(), model(), prior(), mask(), imageplane());
      }
    }
    break;
  case 14: // makeprior
    {
      Parameter<String > prior(inputRecord, "prior", ParameterSet::In);
      Parameter<String > templateImage(inputRecord, "templateimage", ParameterSet::In);
      Parameter<Quantity> lowclipfrom(inputRecord, "lowclipfrom",  ParameterSet::In);
      Parameter<Quantity> lowclipto(inputRecord, "lowclipto",  ParameterSet::In);
      Parameter<Quantity> highclipfrom(inputRecord, "highclipfrom",  ParameterSet::In);
      Parameter<Quantity> highclipto(inputRecord, "highclipto",  ParameterSet::In);
      Parameter< Vector<Index> > blc(inputRecord, "blc",  ParameterSet::In);
      Parameter< Vector<Index> > trc(inputRecord, "trc",  ParameterSet::In);
      Parameter< Bool >	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  makeprior(prior(),templateImage(), lowclipfrom(), lowclipto(), 
		    highclipfrom(), highclipto(), blc(), trc());
      }
    }
    break;
  case 15: // clarkclean
    {
      Parameter<Int> niter(inputRecord, "niter", ParameterSet::In);
      Parameter<Float> gain(inputRecord, "gain", ParameterSet::In);
      Parameter<Quantity> threshold(inputRecord, "threshold",  ParameterSet::In);
      Parameter<Bool>    displayprogress(inputRecord, "displayprogress",  ParameterSet::In);
      Parameter<String > model(inputRecord, "model", ParameterSet::In);
      Parameter<String > mask(inputRecord, "mask", ParameterSet::In);
      Parameter<Int > histbins(inputRecord, "histbins", ParameterSet::In);
      Parameter< Vector<Index> > psfpatchsize(inputRecord, "psfpatchsize", ParameterSet::In);
      Parameter<Float > maxextpsf(inputRecord, "maxextpsf", ParameterSet::In);
      Parameter<Float > speedup(inputRecord, "speedup", ParameterSet::In);
      Parameter<Int > maxnumpix(inputRecord, "maxnumpix", ParameterSet::In);
      Parameter<Int > maxnummajcycles(inputRecord, "maxnummajcycles", ParameterSet::In);
      Parameter<Int > maxnummineriter(inputRecord, "maxnummineriter", ParameterSet::In);
      Parameter< Bool >	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  clarkclean(niter(), gain(), threshold(), displayprogress(),
		     model(), mask(),
		     histbins(), psfpatchsize(), maxextpsf(), speedup(),
		     maxnumpix(), maxnummajcycles(), maxnummineriter());
      }
    }
    break;
  case 16: // make
    {
      Parameter<String > image(inputRecord, "image", ParameterSet::In);
      Parameter< Bool >	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = make(image());
      }
    }
    break;
  case 17: // clipimage
    {
      Parameter<String > clippedimage(inputRecord, "clippedimage", ParameterSet::In);
      Parameter<String > inputimage(inputRecord, "inputimage", ParameterSet::In);
      Parameter<Quantity > threshold(inputRecord, "threshold", ParameterSet::In);
      Parameter< Bool >	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = clipimage(clippedimage(), inputimage(), threshold());
      }
    }
    break;
  case 18: // boxmask
    {
      Parameter<String > mask(inputRecord, "mask", ParameterSet::In);
      Parameter< Vector<Int> > blc(inputRecord, "blc",  ParameterSet::In);
      Parameter< Vector<Int> > trc(inputRecord, "trc",  ParameterSet::In);
      Parameter<Quantity > fillvalue(inputRecord, "fillvalue", ParameterSet::In);
      Parameter<Quantity > outsidevalue(inputRecord, "outsidevalue", ParameterSet::In);
      Parameter< Bool >	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = boxmask(mask(), blc(), trc(), fillvalue(), outsidevalue());
      }
    }
    break;
  case 19: // reopen
    {
      Parameter< String >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = reopen(); 
      }
    }
    break;
  case 20: // convolve
    {
      Parameter<String > convolvedmodel(inputRecord, "convolvedmodel", ParameterSet::In);
      Parameter<String > model(inputRecord, "model", ParameterSet::In);
      Parameter< Bool >	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = convolve(convolvedmodel(), model());
      }
    }
    break;
  case 21: // makegaussian
    {
      Parameter<String > gaussianimage(inputRecord, "gaussianimage", ParameterSet::In);
      Parameter<Quantity > bmaj(inputRecord, "bmaj", ParameterSet::In);
      Parameter<Quantity > bmin(inputRecord, "bmin", ParameterSet::In);
      Parameter<Quantity > bpa(inputRecord, "bpa", ParameterSet::In);
      Parameter< Bool >	 normalize(inputRecord, "normalize", ParameterSet::In);
      Parameter< Bool >	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = makegaussian(gaussianimage(),bmaj(), bmin(), bpa(), normalize() );
      }
    }
    break;
  case 22: // pixon
    {
      Parameter<Quantity> sigma(inputRecord, "sigma",  ParameterSet::In);
      Parameter<String > model(inputRecord, "model", ParameterSet::In);
      Parameter< Bool > imageplane(inputRecord, "imageplane", ParameterSet::In);
      Parameter< Bool >	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  pixon(sigma(), model(), imageplane());
      }
    }
    break;
  default:
    return error("No such method");
  }
  return ok();
}


Bool deconvolver::detached() const
{
  if (dirty_p == 0) {
    LogIO os(LogOrigin("deconvolver", "detached()", WHERE));
    os << LogIO::SEVERE << 
      "deconvolver is detached - cannot perform operation." << endl <<
      "Call deconvolver.open('dirtyname', 'psfname') to reattach." << LogIO::POST;
    return True;
  }
  return False;
}

Bool deconvolver::removeTable(const String& tablename) {
  
  LogIO os(LogOrigin("deconvolver", "removeTable()", WHERE));
  
  if(Table::isReadable(tablename)) {
    if (! Table::isWritable(tablename)) {
      os << LogIO::SEVERE << "Table " << tablename
	 << " is not writable!: cannot alter it" << LogIO::POST;
      return False;
    }
    else {
      if (Table::isOpened(tablename)) {
	os << LogIO::SEVERE << "Table " << tablename
	   << " is already open in the process. It needs to be closed first"
	   << LogIO::POST;
	  return False;
      } else {
	Table table(tablename, Table::Update);
	if (table.isMultiUsed()) {
	  os << LogIO::SEVERE << "Table " << tablename
	     << " is already open in another process. It needs to be closed first"
	     << LogIO::POST;
	    return False;
	} else {
	  Table table(tablename, Table::Delete);
	}
      }
    }
  }
  return True;
}

Bool deconvolver::valid() const {
  LogIO os(LogOrigin("deconvolver", "if(!valid()) return False", WHERE));
  if(!dirty_p) {
    os << LogIO::SEVERE << "Program logic error: Dirty image pointer dirty_p not yet set"
       << LogIO::POST;
    return False;
  }
  if(!psf_p) {
    os << LogIO::SEVERE << "Program logic error: PSF  pointer psf_p not yet set"
       << LogIO::POST;
    return False;
  }
  return True;
}

void deconvolver::findAxes(){

  CoordinateSystem coordsys= dirty_p->coordinates();
  polAxis_p=coordsys.findCoordinate(Coordinate::STOKES);
  if(polAxis_p > coordsys.findCoordinate(Coordinate::DIRECTION))
    polAxis_p+=1;
  chanAxis_p=coordsys.findCoordinate(Coordinate::SPECTRAL);
  if(chanAxis_p > coordsys.findCoordinate(Coordinate::DIRECTION))
    chanAxis_p+=1;
  
}

void deconvolver::checkMask(ImageInterface<Float>& maskImage, Int& xbeg, Int& xend, 
			    Int& ybeg, Int& yend){
 

  LogIO os(LogOrigin("deconvolver","checkMask",WHERE)); 

  xbeg=nx_p/4;
  ybeg=ny_p/4;
  
  xend=xbeg+nx_p/2-1;
  yend=ybeg+ny_p/2-1;  
  Slicer sl;
  if(nchan_p >= 1){
    
    if(npol_p > 0 ){
      IPosition blc(4,0,0,0,0);
      blc(chanAxis_p)=0;
      blc(polAxis_p)=0;
      IPosition trc(4, nx_p-1, ny_p-1, 0, 0);
      trc(chanAxis_p)=0;
      trc(polAxis_p)=0;
      sl=Slicer(blc, trc, Slicer::endIsLast);
    }
    else{
      IPosition blc(3, 0, 0, 0);
      IPosition trc(3, nx_p-1, ny_p-1, 0);
      sl=Slicer(blc, trc, Slicer::endIsLast);
    }
  }
  else{
    if(npol_p > 0 ){
      IPosition blc(3, 0, 0, 0);
      IPosition trc(3, nx_p-1, ny_p-1, 0);
      sl=Slicer(blc, trc, Slicer::endIsLast);
    }
    else{
       IPosition blc(2, 0, 0);
       IPosition trc(2, nx_p-1, ny_p-1);
    }
  }


  Matrix<Float> mask= maskImage.getSlice(sl, True);
  // ignore mask if none exists
  if(max(mask) < 0.000001) {
    os << "Mask seems to be empty; will CLEAN inner quarter" 
       << LogIO::WARN;
    return;
  }
  // Now read the mask and determine the bounding box

  xbeg=nx_p-1;
  ybeg=ny_p-1;
  xend=0;
  yend=0;

  
  for (Int iy=0;iy<ny_p;iy++) {
    for (Int ix=0;ix<nx_p;ix++) {
      if(mask(ix,iy)>0.000001) {
	xbeg=min(xbeg,ix);
	ybeg=min(ybeg,iy);
	xend=max(xend,ix);
	yend=max(yend,iy);

      }
    }
  }
  // Now have possible BLC. Make sure that we don't go over the
  // edge later
  if(((xend - xbeg)>nx_p/2) && (!fullPlane_p)) {
    xbeg=nx_p/4-1; //if larger than quarter take inner of mask
    os << LogIO::WARN << "Mask span over more than half the x-axis: Considering inner half of the x-axis"  << LogIO::POST;
  } 
  if(((yend - ybeg)>ny_p/2) && (!fullPlane_p)) { 
    ybeg=ny_p/4-1;
    os << LogIO::WARN << "Mask span over more than half the y-axis: Considering inner half of the y-axis" << LogIO::POST;
  }  

  // Just making sure we are within limits...
  if(fullPlane_p){
    xend=min(xend,nx_p-1);
    yend=min(yend,ny_p-1);
  }
  else{
    xend=min(xend,xbeg+nx_p/2-1);
    yend=min(yend,ybeg+ny_p/2-1); 
  }



}

PGPlotter& deconvolver::getPGPlotter(Bool newPlotter) {

  // Destroy the old plotter?
  if(newPlotter) {
    if(pgplotter_p) delete pgplotter_p;
    pgplotter_p=0;
  }

  // If a plotter does not exist create a new one
  if(!pgplotter_p) {
    PlotDevice device=ApplicationEnvironment::defaultPlotter(id());
    pgplotter_p = new PGPlotter(ApplicationEnvironment::getPlotter(device));
  }
  AlwaysAssert(pgplotter_p, AipsError);
  return *pgplotter_p;
};

// Local Variables: 
// compile-command: "gmake DOdeconvolver"
// End: 
