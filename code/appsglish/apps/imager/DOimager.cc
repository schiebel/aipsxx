//# DOimager.cc: this implements the imager DO
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
//# $Id: DOimager.cc,v 19.61 2006/10/13 16:39:30 kgolap Exp $

#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/ArrayMath.h>

#include <casa/Logging.h>
#include <casa/Logging/LogIO.h>
#include <casa/OS/File.h>
#include <casa/Containers/Record.h>


#include <casa/BasicSL/String.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/Fallible.h>

#include <casa/Logging/LogSink.h>
#include <casa/Logging/LogMessage.h>

#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>

#include <casa/Arrays/ArrayMath.h>
#include <casa/Exceptions/Error.h>

#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>

#include <ms/MeasurementSets/MeasurementSet.h>
#include <appsglish/imager/DOimager.h>

#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/Index.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <casa/System/PGPlotter.h>
#include <tasking/Tasking/ObjectController.h>

#include <components/ComponentModels/ComponentList.h>
#include <synthesis/MeasurementEquations/ImagerMultiMS.h>

#include <casa/sstream.h>

#ifdef PABLO_IO
#include "PabloTrace.h"
#endif

#include <casa/namespace.h>

imager::imager() 
 
{

  itsImager=new ImagerMultiMS();
};


imager::imager(MeasurementSet &theMs, Bool compress)
  :  pgplotter_p(0)
{

  itsImager=new Imager(theMs, *pgplotter_p, compress);
}

imager::imager(MeasurementSet &theMs, PGPlotter& thePlotter, Bool compress)

{
  pgplotter_p = &thePlotter;
  itsImager=new Imager(theMs, *pgplotter_p, compress);
}


imager::imager(const imager &other)

{
  itsImager=other.itsImager;
  pgplotter_p=other.pgplotter_p;
}

imager &imager::operator=(const imager &other)
{
 
  *pgplotter_p = *(other.pgplotter_p);
  *itsImager = *(other.itsImager);
  return *this;
}

imager::~imager()
{
  
  if (pgplotter_p != 0)
    delete pgplotter_p;
  pgplotter_p=0;
  if(itsImager !=0)
    delete itsImager;


}

Bool imager::open(MeasurementSet& theMs, Bool compress)
{

  return itsImager->open(theMs, compress);

}

Bool imager::close()
{
  
  return itsImager->close();

}

String imager::name() const
{
  
  return itsImager->name();
}



Bool imager::summary() const
{
  
  return itsImager->summary();

}



Bool imager::setimage(const Int nx, const Int ny,
		      const Quantity& cellx, const Quantity& celly,
		      const String& stokes,
		      Bool doShift,
		      const MDirection& phaseCenter, 
		      const Quantity& shiftx, const Quantity& shifty,
		      const String& mode, const Int nchan,
		      const Int start, const Int step,
		      const MRadialVelocity& mStart, const MRadialVelocity& mStep,
		      const Vector<Int>& spectralwindowids,
		      const Int fieldid,
		      const Int facets,
		      const Quantity& distance,
		      const Float &paStep, const Float &pbLimit)
{

  return itsImager->setimage(nx, ny,cellx, celly, stokes, doShift,
			     phaseCenter, shiftx, shifty, mode,nchan,
			     start, step, mStart, mStep, spectralwindowids, 
			     fieldid, facets, distance, paStep, pbLimit);
}

Bool imager::advise(const Bool takeAdvice, const Float amplitudeLoss,
		    const Quantity& fieldOfView, Quantity& cell,
		    Int& pixels, Int& facets, MDirection& phaseCenter)
{
 
  return itsImager->advise(takeAdvice, amplitudeLoss, fieldOfView, 
			   cell, pixels, facets, phaseCenter);


}

Bool imager::setdata(const String& mode, const Vector<Int>& nchan,
		     const Vector<Int>& start, const Vector<Int>& step,
		     const MRadialVelocity& mStart,
		     const MRadialVelocity& mStep,
		     const Vector<Int>& spectralwindowids,
		     const Vector<Int>& fieldids,
		     const String& msSelect, const String& msname)
  
{
  
  return itsImager->setDataPerMS(msname, mode, nchan, start, step, spectralwindowids, fieldids,
			    msSelect);

}


Bool imager::setmfcontrol(const Float cyclefactor,
			  const Float cyclespeedup,
			  const Int stoplargenegatives, 
			  const Int stoppointmode,
			  const String& scaleType,
			  const Float minPB,
			  const Float constPB,
			  const Vector<String>& fluxscale)
{  
  return itsImager->setmfcontrol(cyclefactor, cyclespeedup,
				 stoplargenegatives, stoppointmode,
				 scaleType, minPB, constPB, fluxscale);
}  


Bool imager::setvp(const Bool dovp,
		   const Bool doDefaultVPs,
		   const String& vpTable,
		   const Bool doSquint,
		   const Quantity &parAngleInc,
		   const Quantity &skyPosThreshold,
		   String defaultTel)
{

  return itsImager->setvp(dovp, doDefaultVPs, vpTable, doSquint, parAngleInc,
			  skyPosThreshold,defaultTel);

}

Bool imager::setoptions(const String& ftmachine, const Int cache, 
			const Int tile,
			const String& gridfunction, const MPosition& mLocation,
			const Float padding, const Bool usemodelcol, 
			const Int wprojplanes,
			const String& epJTableName,
			const Bool applyPointingOffsets,
			const Bool doPointingCorrection,
			const String &cfCache)
{

  return itsImager->setoptions(ftmachine, cache, tile, gridfunction, 
			       mLocation, padding,usemodelcol, wprojplanes,
			       epJTableName,applyPointingOffsets,doPointingCorrection,
			       cfCache);
}

Bool imager::setsdoptions(const Float scale, const Float weight, 
			  const Int convsupport)
{

  return itsImager->setsdoptions(scale, weight, convsupport);
}


Bool imager::mask(const String& mask, const String& image,
		  const Quantity& threshold) 
{
  
  return itsImager->mask(mask, image, threshold);
}

Bool imager::boxmask(const String& mask, const Vector<Int>& blc,
		  const Vector<Int>& trc, const Float value) 
{
  return itsImager->boxmask(mask, blc, trc, value);

}

Bool imager::clipimage(const String& image, const Quantity& threshold)
{
 
  return itsImager->clipimage(image, threshold);

}

// Add together low and high resolution images in the Fourier plane
Bool imager::feather(const String& image, const String& highRes,
		     const String& lowRes, const String& lowPSF)
{
 
  
  return itsImager->feather(image, highRes, lowRes, lowPSF);
}




// Apply a primary beam or voltage pattern to an image
Bool imager::pb(const String& inimage, 
		const String& outimage,
		const String& incomps,
		const String& outcomps,
		const String& operation, 
		const MDirection& pointingCenter,
		const Quantity& pa,
		const String& pborvp)

{
  
  return itsImager->pb(inimage, outimage, incomps, outcomps, operation, 
		       pointingCenter, pa, pborvp);
}



Bool imager::linearmosaic(const String& mosaic,
			  const String& fluxscale,
			  const String& sensitivity,
			  const Vector<String>& images,
			  const Vector<Int>& fieldids)

{
 
  
  return itsImager->linearmosaic(mosaic, fluxscale, sensitivity,
				 images, fieldids);
}



// Weight the MeasurementSet
Bool imager::weight(const String& type, const String& rmode,
                 const Quantity& noise, const Double robust,
                 const Quantity& fieldofview,
                 const Int npixels)
{
 
  return itsImager->weight(type, rmode, noise, robust, fieldofview, npixels);
}




// Filter the MeasurementSet
Bool imager::filter(const String& type, const Quantity& bmaj,
		 const Quantity& bmin, const Quantity& bpa)
{
  
  return itsImager->filter(type, bmaj, bmin, bpa);
}


// Implement a uv range
Bool imager::uvrange(const Double& uvmin, const Double& uvmax)
{
  
  return itsImager->uvrange(uvmin, uvmax);
}

// Find the sensitivity
Bool imager::sensitivity(Quantity& pointsourcesens, Double& relativesens,
		      Double& sumwt)
{
 
  return itsImager->sensitivity(pointsourcesens, relativesens,
				sumwt);
}

Bool imager::makeimage(const String& type, const String& image)
{
  return imager::makeimage(type, image, "");
}

// Calculate various sorts of image. Only one image
// can be calculated at a time. The complex Image make
// be retained if a name is given. This does not use
// the SkyEquation.
Bool imager::makeimage(const String& type, const String& image,
		   const String& compleximage)
{

  return itsImager->makeimage(type, image, compleximage);
}  

// Restore: at least one model must be supplied
Bool imager::restore(const Vector<String>& model,
		     const String& complist,
		     const Vector<String>& image,
		     const Vector<String>& residual)
{
  return itsImager->restore(model, complist, image, residual);
}

// Residual
Bool imager::residual(const Vector<String>& model,
		      const String& complist,
		      const Vector<String>& image)
{
  return itsImager->residual(model, complist, image);
}

// Residual
Bool imager::approximatepsf(const Vector<String>& model,
			     const Vector<String>& psf)
{
  return itsImager->approximatepsf(model, psf);
}

Bool imager::smooth(const Vector<String>& model, 
		    const Vector<String>& image, Bool usefit, 
		    Quantity& mbmaj, Quantity& mbmin, Quantity& mbpa,
		    Bool normalizeVolume)
{
  return itsImager->smooth(model, image, usefit, mbmaj, mbmin, mbpa,
			   normalizeVolume);
}

// Clean algorithm
Bool imager::clean(const String& algorithm,
		   const Int niter, 
		   const Float gain,
		   const Quantity& threshold, 
		   const Bool displayProgress, 
		   const Vector<String>& model, const Vector<Bool>& fixed,
		   const String& complist,
		   const Vector<String>& mask,
		   const Vector<String>& image,
		   const Vector<String>& residual)
{


  return itsImager->clean(algorithm, niter, gain, threshold, displayProgress, 
			  model, fixed, complist, mask, image, residual);

}


// Mem algorithm
Bool imager::mem(const String& algorithm,
		 const Int niter, 
		 const Quantity& sigma, 
		 const Quantity& targetFlux,
		 const Bool constrainFlux,
		 const Bool displayProgress, 
		 const Vector<String>& model, 
		 const Vector<Bool>& fixed,
		 const String& complist,
		 const Vector<String>& prior,
		 const Vector<String>& mask,
		 const Vector<String>& image,
		 const Vector<String>& residual)
{

  return itsImager->mem(algorithm, niter, sigma, targetFlux, constrainFlux,
			displayProgress, model, fixed, complist, prior,
			mask, image, residual);

}

Bool imager::pixon(const String& algorithm,
		   const Quantity& sigma, 
		   const String& model)
{

  return itsImager->pixon(algorithm, sigma, model);

}


    
// NNLS algorithm
Bool imager::nnls(const String& algo,  const Int niter, const Float tolerance, 
		  const Vector<String>& model, const Vector<Bool>& fixed,
		  const String& complist,
		  const Vector<String>& fluxMask,
		  const Vector<String>& dataMask,
		  const Vector<String>& residual,
		  const Vector<String>& image)
{

  return itsImager->nnls(algo, niter, tolerance, model, fixed,
			 complist, fluxMask, dataMask, residual,
			 image);
}

// Fourier transform the model and componentlist
Bool imager::ft(const Vector<String>& model, const String& complist,
		const Bool incremental)
{
  return itsImager->ft(model, complist, incremental);
}

Bool imager::setjy(const Int fieldid, const Int spectralwindowid,
		   const Vector<Double>& fluxDensity, const String& standard)
{
  return itsImager->setjy(fieldid, spectralwindowid, fluxDensity, standard);
}


// Make an empty image
Bool imager::make(const String& model)
{
  return itsImager->make(model);
}

// Fit the psf. If psf is blank then make the psf first.
Bool imager::fitpsf(const String& psf, Quantity& mbmaj, Quantity& mbmin,
		    Quantity& mbpa)
{

  return itsImager->fitpsf(psf, mbmaj, mbmin, mbpa);
}


Bool imager::setscales(const String& scaleMethod,
			    const Int inscales,
			    const Vector<Float>& userScaleSizes)
{
  
  return itsImager->setscales(scaleMethod, inscales, userScaleSizes);
};

Bool imager::settaylorterms(const Int intaylor)
{
  
  return itsImager->settaylorterms(intaylor);
};


// Set the beam
Bool imager::setbeam(const Quantity& mbmaj, const Quantity& mbmin,
		     const Quantity& mbpa)
{
  return itsImager->setbeam(mbmaj, mbmin, mbpa);
}

// Correct the data using a plain VisEquation.
// This just moves data from observed to corrected.
// Eventually we should pass in a calibrater
// object to do the work.
Bool imager::correct(const Bool doparallactic, const Quantity& t) 
{  
  return itsImager->correct(doparallactic, t);
}

// Plot the uv plane
Bool imager::plotuv(const Bool rotate) 
{
  // This get and setPGPotter should go away if Imager is constructed with it
  PGPlotter plotter=getPGPlotter();
  itsImager->setPGPlotter(plotter);
  return itsImager->plotuv(rotate);
}

// Plot the visibilities
Bool imager::plotvis(const String& type, const Int increment) 
{
  // This get and setPGPotter should go away if Imager is constructed with it
  PGPlotter plotter=getPGPlotter();
  itsImager->setPGPlotter(plotter);
  return itsImager->plotvis(type, increment);
}

// Plot the weights
Bool imager::plotweights(const Bool gridded, const Int increment) 
{
  // This get and setPGPotter should go away if Imager is constructed with it
  PGPlotter plotter=getPGPlotter();
  itsImager->setPGPlotter(plotter);
  return itsImager->plotweights(gridded, increment);
}

// Plot the visibilities
Bool imager::clipvis(const Quantity& threshold) 
{
  return itsImager->clipvis(threshold);
}

// Plot various ids
Bool imager::plotsummary() 
{
  // This get and setPGPotter should go away if Imager is constructed with it
  PGPlotter plotter=getPGPlotter();
  itsImager->setPGPlotter(plotter);
  return itsImager->plotsummary();
}

String imager::state() const {

  return itsImager->state();

}

Bool imager::clone(const String& imageName, const String& newImageName){
  return itsImager->clone(imageName, newImageName);

}

String imager::className() const
{
  return "imager";
}

Vector<String> imager::methods() const
{
  Vector<String> method(46);
  Int i=0;
  method(i++) = "open";
  method(i++) = "state";
  method(i++) = "close";
  method(i++) = "name";
  method(i++) = "summary";
  
  method(i++) = "setimage";
  method(i++) = "setdata";
  method(i++) = "setoptions";
  method(i++) = "makeimage";
  method(i++) = "weight";
  
  method(i++) = "restore";
  method(i++) = "clean";
  method(i++) = "nnls";
  method(i++) = "ft";
  method(i++) = "setjy";

  method(i++) = "make";
  method(i++) = "fitpsf";
  method(i++) = "correct";
  method(i++) = "mask";
  method(i++) = "filter";

  method(i++) = "clone";
  method(i++) = "smooth";
  method(i++) = "plotuv";
  method(i++) = "residual";
  method(i++) = "plotsummary";

  method(i++) = "plotvis";
  method(i++) = "plotweights";
  method(i++) = "uvrange";
  method(i++) = "sensitivity";
  method(i++) = "boxmask";

  method(i++) = "clipimage";
  method(i++) = "clipvis";
  method(i++) = "advise";
  method(i++) = "setbeam";
  method(i++) = "setvp";

  method(i++) = "setscales";
  method(i++) = "mem";
  method(i++) = "feather";
  method(i++) = "setmfcontrol";
  method(i++) = "pb";

  method(i++) = "linearmosaic";
  method(i++) = "pixon";
  method(i++) = "setsdoptions";
  method(i++) = "approximatepsf";
  method(i++) = "makemodelfromsd";
  method(i++) = "settaylorterms";

  return method;
}

Vector<String> imager::noTraceMethods() const
{
  Vector<String> method(7);
  Int i=0;
  method(i++) = "close";
  method(i++) = "name";
  method(i++) = "summary";
  method(i++) = "setimage";
  method(i++) = "setoptions";
  method(i++) = "setsdoptions";
  
  method(i++) = "state";
  
  return method;
}

MethodResult imager::runMethod(uInt which, 
			       ParameterSet &inputRecord,
			       Bool runMethod)
{
try {  
  static String returnvalString = "returnval";
  
  switch (which) {
  case 0: // open
    {
      static String themsString = "thems";
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      Parameter< String > 
	thems(inputRecord, themsString, ParameterSet::In);
      Parameter< Bool > compress(inputRecord, "compress", ParameterSet::In);
      if (runMethod) {
	MeasurementSet thisms(thems(), TableLock(TableLock::UserLocking),
			      Table::Update);
	returnval() = open(thisms, compress());
      }
    }
    break;
  case 1: // state
    {
      Parameter< String >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = state(); // DOIT
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
  case 3: // name
    {
      Parameter< String >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = name(); // DOIT
      }
    }
    break;
  case 4: // summary
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = summary();
      }
    }
    break;
  case 5: // setimage
    {
      Parameter<Float> paStep(inputRecord, "pastep", ParameterSet::In);
      Parameter<Float> pbLimit(inputRecord, "pblimit", ParameterSet::In);
      Parameter<Int> nx(inputRecord, "nx", ParameterSet::In);
      Parameter<Int> ny(inputRecord, "ny", ParameterSet::In);
      Parameter<Quantity> cellx(inputRecord, "cellx", ParameterSet::In);
      Parameter<Quantity> celly(inputRecord, "celly", ParameterSet::In);
      Parameter<String> stokes(inputRecord, "stokes", ParameterSet::In);
      Parameter<Bool> doshift(inputRecord, "doshift", ParameterSet::In);
      Parameter<Index> start(inputRecord, "start", ParameterSet::In);
      Parameter<Int> step(inputRecord, "step", ParameterSet::In);
      Parameter<MDirection> mPhaseCenter(inputRecord, "phasecenter",
					 ParameterSet::In);
      Parameter<Quantity> shiftx(inputRecord, "shiftx", ParameterSet::In);
      Parameter<Quantity> shifty(inputRecord, "shifty", ParameterSet::In);
      Parameter<String> mode(inputRecord, "mode", ParameterSet::In);
      Parameter<Int> nchan(inputRecord, "nchan", ParameterSet::In);
      Parameter<Quantity> mImageStart(inputRecord, "mstart",
				      ParameterSet::In);
      Parameter<Quantity> mImageStep(inputRecord, "mstep",
				     ParameterSet::In);
      Parameter<Vector<Index> > spectralwindowids(inputRecord, "spwid",
						  ParameterSet::In);
      Parameter<Index> fieldid(inputRecord, "fieldid", ParameterSet::In);
      Vector<Int> spws(spectralwindowids().nelements());
      for (uInt i=0;i<spws.nelements();i++) {
	spws(i)=spectralwindowids()(i).zeroRelativeValue();
      }
      Parameter<Int> facets(inputRecord, "facets", ParameterSet::In);
      Parameter<Quantity> distance(inputRecord, "distance", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = setimage (nx(), ny(),
				cellx(), celly(),
				stokes(),
				doshift(), mPhaseCenter(), 
				shiftx(), shifty(),
				mode(), nchan(), start().zeroRelativeValue(), step(),
				MRadialVelocity(mImageStart(), MRadialVelocity::LSRK),
				MRadialVelocity(mImageStep(), MRadialVelocity::LSRK),
				spws, fieldid().zeroRelativeValue(), facets(),
				distance(), paStep(), pbLimit());
      }
    }
    break;
  case 6: // setdata
    {
      Parameter<String> msname(inputRecord, "msname", ParameterSet::In);
      Parameter<String> mode(inputRecord, "mode", ParameterSet::In);
      Parameter<Vector<Int> > nchan(inputRecord, "nchan", ParameterSet::In);
      Parameter<Vector<Index> > start(inputRecord, "start", ParameterSet::In);
      Parameter<Vector<Int> > step(inputRecord, "step", ParameterSet::In);
      Parameter<Quantity> mDataStart(inputRecord, "mstart", ParameterSet::In);
      Parameter<Quantity> mDataStep(inputRecord, "mstep", ParameterSet::In);
      Parameter<Vector<Index> > spectralwindowids(inputRecord, "spwid",
						  ParameterSet::In);
      Parameter<Vector<Index> > fieldids(inputRecord, "fieldid", ParameterSet::In);
      Vector<Int> spws(spectralwindowids().nelements());
      Parameter <String> msSelect (inputRecord, "msselect", ParameterSet::In);

      uInt i;
      for (i=0;i<spws.nelements();i++) {
	spws(i)=spectralwindowids()(i).zeroRelativeValue();
      }
      Vector<Int> fids(fieldids().nelements());
      for (i=0;i<fids.nelements();i++) {
	fids(i)=fieldids()(i).zeroRelativeValue();
      }
      
      Vector<Int> chanstart(start().nelements());
      for (i=0;i<chanstart.nelements();i++) {
	chanstart(i)=start()(i).zeroRelativeValue();
      }
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = setdata (mode(), nchan(), chanstart,
			       step(),
			       MRadialVelocity(mDataStart(), MRadialVelocity::LSRK),
			       MRadialVelocity(mDataStep(), MRadialVelocity::LSRK),
			       spws, fids, msSelect(), msname());
      }
    }
    break;
  case 7: // setoptions
    {
      Parameter<String> ftmachine(inputRecord, "ftmachine", ParameterSet::In);
      Parameter<Int> cache(inputRecord, "cache", ParameterSet::In);
      Parameter<Int> tile(inputRecord, "tile", ParameterSet::In);
      Parameter<String> gridfunction(inputRecord, "gridfunction",
				     ParameterSet::In);
      Parameter<MPosition> mlocation(inputRecord, "location",
				     ParameterSet::In);
      Parameter<Float> padding(inputRecord, "padding", ParameterSet::In);
      Parameter<Bool> usemodelcol(inputRecord, 
				  "usemodelcol", ParameterSet::In);
      Parameter<Int> wprojplanes(inputRecord, "wprojplanes", ParameterSet::In);
      Parameter<String> epJTableName(inputRecord, "pointingtable",
				     ParameterSet::In);
      Parameter<Bool> doPointing(inputRecord, "dopointing",
				     ParameterSet::In);
      Parameter<Bool> doPBCorr(inputRecord, "dopbcorr", ParameterSet::In);
      Parameter<String> cfCacheDirName(inputRecord,"cfcache",
				       ParameterSet::In);

      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  setoptions (ftmachine(), cache(), tile(), gridfunction(),
		      mlocation(), padding(), usemodelcol(), wprojplanes(),
		      epJTableName(), doPointing(),doPBCorr(),cfCacheDirName());
      }
    }
    break;
  case 8: // makeimage
    {
      Parameter<String> type(inputRecord, "type", ParameterSet::In);
      Parameter<String> imagename(inputRecord, "image",
				  ParameterSet::In);
      Parameter<String> compleximagename(inputRecord, "compleximage",
					 ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  makeimage(type(), imagename(), compleximagename());
      }
    }
    break;
  case 9: // weight
    {
      Parameter<String> type(inputRecord, "type", ParameterSet::In);
      Parameter<String> rmode(inputRecord, "rmode", ParameterSet::In);
      Parameter<Quantity> noise(inputRecord, "noise", ParameterSet::In);
      Parameter<Double> robust(inputRecord, "robust", ParameterSet::In);
      Parameter<Quantity> fieldofview(inputRecord, "fieldofview", ParameterSet::In);
      Parameter<Int> npixels(inputRecord, "npixels", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  weight(type(), rmode(), noise(), robust(), fieldofview(), npixels());
      }
    }
    break;
  case 10: // restore
    {
      Parameter<Vector<String> > model(inputRecord, "model", ParameterSet::In);
      Parameter<String> complist(inputRecord, "complist", ParameterSet::In);
      Parameter<Vector<String> > image(inputRecord, "image", ParameterSet::In);
      Parameter<Vector<String> > residual(inputRecord, "residual",
					  ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  restore(model(), complist(), image(), residual());
      }
    }
    break;
  case 11: // clean
    {
      Parameter<String> algorithm(inputRecord, "algorithm", ParameterSet::In);
      Parameter<Int> niter(inputRecord, "niter", ParameterSet::In);
      Parameter<Float> gain(inputRecord, "gain", ParameterSet::In);
      Parameter<Quantity> threshold(inputRecord, "threshold",
				    ParameterSet::In);
      Parameter<Bool>  displayprogress(inputRecord, "displayprogress",  ParameterSet::In);
      Parameter<Vector<String> > model(inputRecord, "model", ParameterSet::In);
      Parameter<Vector<Bool> > fixed(inputRecord, "fixed", ParameterSet::In);
      Parameter<String> complist(inputRecord, "complist", ParameterSet::In);
      Parameter<Vector<String> > mask(inputRecord, "mask", ParameterSet::In);
      Parameter<Vector<String> > image(inputRecord, "image", ParameterSet::In);
      Parameter<Vector<String> > residual(inputRecord, "residual", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  clean(algorithm(), niter(), gain(), threshold(), 
		displayprogress(), 
		model(), fixed(), complist(), mask(), image(), 
	        residual());
      }
    }
    break;
  case 12: // nnls
    {
      Parameter<String> algorithm(inputRecord, "algorithm", ParameterSet::In);
      Parameter<Int> niter(inputRecord, "niter", ParameterSet::In);
      Parameter<Float> tolerance(inputRecord, "tolerance", ParameterSet::In);
      Parameter<Vector<String> > model(inputRecord, "model", ParameterSet::In);
      Parameter<Vector<Bool> > fixed(inputRecord, "fixed", ParameterSet::In);
      Parameter<String> complist(inputRecord, "complist", ParameterSet::In);
      Parameter<Vector<String> > fluxmask(inputRecord, "fluxmask",
					  ParameterSet::In);
      Parameter<Vector<String> > datamask(inputRecord, "datamask",
					  ParameterSet::In);
      Parameter<Vector<String> > image(inputRecord, "image", ParameterSet::In);
      Parameter<Vector<String> > residual(inputRecord, "residual", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  nnls(algorithm(), niter(), tolerance(), model(), fixed(), complist(),
	     fluxmask(), datamask(), residual(), image());
      }
    }
    break;
  case 13: // ft
    {
      Parameter<Vector<String> > model(inputRecord, "model", ParameterSet::In);
      Parameter<String> complist(inputRecord, "complist", ParameterSet::In);
      Parameter<Bool> incremental(inputRecord, "incremental",
				  ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  ft(model(), complist(), incremental());
      }
    }
    break;
  case 14: // setjy
    {
      Parameter<Index> inpFieldId(inputRecord, "fieldid", ParameterSet::In);
      Parameter<Index> inpSpwId(inputRecord, "spwid", ParameterSet::In);
      Parameter<Vector<Double> > fluxDensity(inputRecord, "fluxdensity",
					     ParameterSet::In);
      Parameter<String> standard(inputRecord, "standard", ParameterSet::In);

      // Adjust 1-relative input field id.'s and spectral window id.'s to 
      // 0-relative, as required for the C++ convention for MS indices.
      Int fieldid=inpFieldId().zeroRelativeValue();
      Int spwid=inpSpwId().zeroRelativeValue();

      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  setjy(fieldid, spwid, fluxDensity(), standard());
      }
    }
    break;
  case 15: // make
    {
      Parameter<String> image(inputRecord, "image", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  make(image());
      }
    }
    break;
  case 16: // fitpsf
    {
      Parameter<String> psf(inputRecord, "psf", ParameterSet::In);
      Parameter<Quantity> bmaj(inputRecord, "bmaj", ParameterSet::Out);
      Parameter<Quantity> bmin(inputRecord, "bmin", ParameterSet::Out);
      Parameter<Quantity> bpa(inputRecord, "bpa", ParameterSet::Out);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  fitpsf(psf(), bmaj(), bmin(), bpa());
      }
    }
    break;
  case 17: // correct
    {
      Parameter<Bool> doparallactic(inputRecord, "doparallactic",
				    ParameterSet::In);
      Parameter<Quantity> timestep(inputRecord, "timestep",
				   ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  correct(doparallactic(), timestep());
      }
    }
    break;
  case 18: // mask
    {
      Parameter<String> maskI(inputRecord, "mask", ParameterSet::In);
      Parameter<String> image(inputRecord, "image", ParameterSet::In);
      Parameter<Quantity> threshold(inputRecord, "threshold",
				    ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  mask(maskI(), image(), threshold());
      }
    }
    break;
  case 19: // filter
    {
      Parameter<String> type(inputRecord, "type", ParameterSet::In);
      Parameter<Quantity> bmaj(inputRecord, "bmaj", ParameterSet::In);
      Parameter<Quantity> bmin(inputRecord, "bmin", ParameterSet::In);
      Parameter<Quantity> bpa(inputRecord, "bpa", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  filter(type(), bmaj(), bmin(), bpa());
      }
    }
    break;
  case 20: // clone
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
  case 21: // smooth
    {
      Parameter<Vector<String> > model(inputRecord, "model", ParameterSet::In);
      Parameter<Vector<String> > image(inputRecord, "image", ParameterSet::In);
      Parameter<Bool> usefit(inputRecord, "usefit", ParameterSet::In);
      Parameter<Quantity> bmaj(inputRecord, "bmaj", ParameterSet::InOut);
      Parameter<Quantity> bmin(inputRecord, "bmin", ParameterSet::InOut);
      Parameter<Quantity> bpa(inputRecord, "bpa", ParameterSet::InOut);
      Parameter<Bool> normalizevolume(inputRecord, "normalize",
				      ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  smooth(model(), image(), usefit(), bmaj(), bmin(), bpa(), normalizevolume());
      }
    }
    break;
  case 22: // plotuv
    {
      Parameter<Bool> rotate(inputRecord, "rotate", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  plotuv(rotate());
      }
    }
    break;
  case 23: // residual
    {
      Parameter<Vector<String> > model(inputRecord, "model", ParameterSet::In);
      Parameter<String> complist(inputRecord, "complist", ParameterSet::In);
      Parameter<Vector<String> > image(inputRecord, "image", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  residual(model(), complist(), image());
      }
    }
    break;
  case 24: // plotsummary
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  plotsummary();
      }
    }
    break;
  case 25: // plotvis
    {
      Parameter<String> type(inputRecord, "type", ParameterSet::In);
      Parameter<Int> increment(inputRecord, "increment", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  plotvis(type(), increment());
      }
    }
    break;
  case 26: // plotweights
    {
      Parameter<Bool> gridded(inputRecord, "gridded", ParameterSet::In);
      Parameter<Int> increment(inputRecord, "increment", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  plotweights(gridded(), increment());
      }
    }
    break;
  case 27: // uvrange
    {
      Parameter<Double> uvmin(inputRecord, "uvmin", ParameterSet::In);
      Parameter<Double> uvmax(inputRecord, "uvmax", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  uvrange(uvmin(), uvmax());
      }
    }
    break;
  case 28: // sensitivity
    {
      Parameter<Quantity> pointsource(inputRecord, "pointsource", ParameterSet::Out);
      Parameter<Double> relative(inputRecord, "relative", ParameterSet::Out);
      Parameter<Double> sumwt(inputRecord, "sumweights", ParameterSet::Out);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  sensitivity(pointsource(), relative(), sumwt());
      }
    }
    break;
  case 29: // boxmask
    {
      Parameter<String> maskI(inputRecord, "mask", ParameterSet::In);
      Parameter<Vector<Index> > blc(inputRecord, "blc", ParameterSet::In);
      Parameter<Vector<Index> > trc(inputRecord, "trc", ParameterSet::In);
      Parameter<Float> value(inputRecord, "value", ParameterSet::In);

      Vector<Int> iblc(blc().nelements());
      uInt i;
      for (i=0;i<iblc.nelements();i++) {
	iblc(i)=blc()(i).zeroRelativeValue();
      }
      Vector<Int> itrc(trc().nelements());
      for (i=0;i<itrc.nelements();i++) {
	itrc(i)=trc()(i).zeroRelativeValue();
      }


      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  boxmask(maskI(), iblc, itrc, value());
      }
    }
    break;
  case 30: // clipimage
    {
      Parameter<String> image(inputRecord, "image", ParameterSet::In);
      Parameter<Quantity> threshold(inputRecord, "threshold",
				    ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  clipimage(image(), threshold());
      }
    }
    break;
  case 31: // clipvis
    {
      Parameter<Quantity> threshold(inputRecord, "threshold",
				    ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  clipvis(threshold());
      }
    }
    break;
  case 32: // advise
    {
      Parameter<Bool> takeAdvice(inputRecord, "takeadvice",
				    ParameterSet::In);
      Parameter<Float> amplitudeLoss(inputRecord, "amplitudeloss",
				     ParameterSet::In);
      Parameter<Quantity> fieldOfView(inputRecord, "fieldofview",
				      ParameterSet::In);
      Parameter<Quantity> cell(inputRecord, "cell", ParameterSet::Out);
      Parameter<Int> pixels(inputRecord, "pixels", ParameterSet::Out);
      Parameter<Int> facets(inputRecord, "facets", ParameterSet::Out);
      Parameter<MDirection> mPhaseCenter(inputRecord, "phasecenter",
					 ParameterSet::Out);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  advise(takeAdvice(), amplitudeLoss(), fieldOfView(), cell(),
		 pixels(), facets(), mPhaseCenter());
      }
    }
    break;
  case 33: // setbeam
    {
      Parameter<Quantity> bmaj(inputRecord, "bmaj", ParameterSet::InOut);
      Parameter<Quantity> bmin(inputRecord, "bmin", ParameterSet::InOut);
      Parameter<Quantity> bpa(inputRecord, "bpa", ParameterSet::InOut);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  setbeam(bmaj(), bmin(), bpa());
      }
    }
    break;
  case 34: // setvp
    {
      Parameter<Bool> dovp(inputRecord, "dovp", ParameterSet::In);
      Parameter<Bool> usedefaultvp(inputRecord, "usedefaultvp", ParameterSet::In);
      Parameter<String> vptable(inputRecord, "vptable", ParameterSet::In);
      Parameter<Bool> dosquint(inputRecord, "dosquint", ParameterSet::In);
      Parameter<Quantity> parangleinc(inputRecord, "parangleinc", ParameterSet::InOut);
      Parameter<Quantity> skyposthreshold(inputRecord, "skyposthreshold", ParameterSet::In);
      Parameter<String> telescope(inputRecord, "telescope", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  setvp(dovp(), usedefaultvp(), vptable(),  dosquint(), parangleinc(), 
		skyposthreshold(),telescope());
      }
    }
    break;
  case 35: // setscales
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
  case 36: // mem
    {
      Parameter<String> algorithm(inputRecord, "algorithm", ParameterSet::In);
      Parameter<Int> niter(inputRecord, "niter", ParameterSet::In);
      Parameter<Quantity> sigma(inputRecord, "sigma",
				    ParameterSet::In);
      Parameter<Quantity> targetflux(inputRecord, "targetflux",
				    ParameterSet::In);
      Parameter<Bool>    constrainflux(inputRecord, "constrainflux",  ParameterSet::In);
      Parameter<Bool>    displayprogress(inputRecord, "displayprogress",  ParameterSet::In);
      Parameter<Vector<String> > model(inputRecord, "model", ParameterSet::In);
      Parameter<Vector<Bool> > fixed(inputRecord, "fixed", ParameterSet::In);
      Parameter<String> complist(inputRecord, "complist", ParameterSet::In);
      Parameter<Vector<String> > prior(inputRecord, "prior", ParameterSet::In);
      Parameter<Vector<String> > mask(inputRecord, "mask", ParameterSet::In);
      Parameter<Vector<String> > image(inputRecord, "image", ParameterSet::In);
      Parameter<Vector<String> > residual(inputRecord, "residual", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  mem(algorithm(), niter(), sigma(), 
	      targetflux(), constrainflux(), 
	      displayprogress(), model(), fixed(),
	      complist(), prior(), mask(), image(), residual());
      }
    }
    break;
  case 37: // feather
    {
      Parameter<String> image(inputRecord, "image", ParameterSet::In);
      Parameter<String> highres(inputRecord, "highres", ParameterSet::In);
      Parameter<String> lowres(inputRecord, "lowres", ParameterSet::In);
      Parameter<String> lowPSF(inputRecord, "lowpsf", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = feather(image(), highres(), lowres(), lowPSF());
      }
    }
    break;
 
  case 38: // setmfcontrol
    {
      Parameter<Float> cyclefactor(inputRecord, "cyclefactor", ParameterSet::In);
      Parameter<Float> cyclespeedup(inputRecord, "cyclespeedup", ParameterSet::In);
      Parameter<Int>  stoplargenegatives(inputRecord, "stoplargenegatives", ParameterSet::In);
      Parameter<Int>   stoppointmode(inputRecord, "stoppointmode", ParameterSet::In);
      Parameter<String>   scaletype(inputRecord, "scaletype", ParameterSet::In);
      Parameter<Float>   minpb(inputRecord, "minpb", ParameterSet::In);
      Parameter<Float>   constpb(inputRecord, "constpb", ParameterSet::In);
      Parameter<Vector<String> > fluxscale(inputRecord, "fluxscale", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = setmfcontrol(cyclefactor(), cyclespeedup(), 
				   stoplargenegatives(), stoppointmode(), scaletype(),
				   minpb(), constpb(), fluxscale());
      }
    }
    break;

  case 39: // pb
    {
      Parameter<String> inimage(inputRecord, "inimage", ParameterSet::In);
      Parameter<String> outimage(inputRecord, "outimage", ParameterSet::In);
      Parameter<String> incomps(inputRecord, "incomps", ParameterSet::In);
      Parameter<String> outcomps(inputRecord, "outcomps", ParameterSet::In);
      Parameter<String> operation(inputRecord, "operation", ParameterSet::In);
      Parameter<MDirection> pointingcenter(inputRecord, "pointingcenter", ParameterSet::In);
      Parameter<Quantity> pa(inputRecord, "parangle", ParameterSet::In);
      Parameter<String> pborvp(inputRecord, "pborvp", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = pb(inimage(), outimage(), incomps(), outcomps(),
			 operation(), pointingcenter(), pa(), pborvp());
      }
    }
    break;

  case 40: // linearmosaic
    {
      Parameter<String> mosaic(inputRecord, "mosaic", ParameterSet::In);
      Parameter<String> fluxscale(inputRecord, "fluxscale", ParameterSet::In);
      Parameter<String> sensitivity(inputRecord, "sensitivity", ParameterSet::In);
      Parameter<Vector<String> > images(inputRecord, "images", ParameterSet::In);
      Parameter<Vector<Int> > fieldid(inputRecord, "fieldid", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = linearmosaic(mosaic(), fluxscale(), sensitivity(),
			 images(), fieldid());
      }
    }
    break;
  case 41: // pixon
    {
      Parameter<String> algorithm(inputRecord, "algorithm", ParameterSet::In);
      Parameter<Quantity> sigma(inputRecord, "sigma",
				    ParameterSet::In);
      Parameter<String > model(inputRecord, "model", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = pixon(algorithm(), sigma(), model());
      }
    }
    break;
  case 42: // setsdoptions
    {
      Parameter<Float> scale(inputRecord, "scale", ParameterSet::In);
      Parameter<Float> weight(inputRecord, "weight", ParameterSet::In);
      Parameter<Int> convsupport(inputRecord, "convsupport", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = setsdoptions(scale(), weight(), convsupport());
      }
    }
    break;
  case 43: // approximatePSF
    {
      Parameter<Vector<String> > model(inputRecord, "model", ParameterSet::In);
      Parameter<Vector<String> > psf(inputRecord, "psf", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  approximatepsf(model(), psf());
      }
    }
    break;
  case 44: // makemodelfromsd
    {
      Parameter<String> sdimage(inputRecord, "sdimage", ParameterSet::In);
      Parameter<String> modelimage(inputRecord, "modelimage", ParameterSet::In);
      Parameter<String> sdpsf(inputRecord, "sdpsf", ParameterSet::In);
      Parameter<String> maskimage(inputRecord, "maskimage", ParameterSet::InOut);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = makemodelfromsd(sdimage(), modelimage(), sdpsf(), maskimage());
      }
    }
    break;
  case 45: // settaylorterms
    {
      Parameter<Int> ntaylor(inputRecord, "ntaylor", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = settaylorterms(ntaylor());
      }
    }
    break;
  default:
    return error("No such method");
  }
}
catch(const AipsError &ae) {
  LogSink logger;
  LogIO os(LogOrigin("DOimager","runMethod",WHERE),logger);
  os<<LogIO::SEVERE<<ae.what()<<LogIO::POST;
  return error(ae.what());
}
catch(const std::exception &se) {
  LogSink logger;
  LogIO os(LogOrigin("DOimager","runMethod",WHERE),logger);
  os<<LogIO::SEVERE<<se.what()<<LogIO::POST;
  return error(se.what());
}
catch(...) {
  LogSink logger;
  LogIO os(LogOrigin("DOimager","runMethod",WHERE),logger);
  os<<LogIO::SEVERE<<"Unexpected exception"<<LogIO::POST;
  return error("Unexpected exception");
}
  return ok();
}



PGPlotter& imager::getPGPlotter(Bool newPlotter) {

  // Destroy the old plotter?
  if(pgplotter_p){
    if(newPlotter) {
      delete pgplotter_p;
      pgplotter_p=0;
    }
    else{
      if(!(pgplotter_p->isAttached())){
	delete pgplotter_p; 
	pgplotter_p=0;
      }
    }
  }
  // If a plotter does not exist create a new one
  if(!pgplotter_p) {
    PlotDevice device=ApplicationEnvironment::defaultPlotter(id());
    pgplotter_p = new PGPlotter(ApplicationEnvironment::getPlotter(device));
  }
  AlwaysAssert(pgplotter_p, AipsError);
  return *pgplotter_p;
}


Bool imager::makemodelfromsd(const String& sdImage, const String& modelImage, 
			     const String& lowPSF, String& maskImage)
{


  
  return itsImager->makemodelfromsd(sdImage, modelImage, lowPSF, maskImage);


}


