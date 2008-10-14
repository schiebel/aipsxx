//# DOqimager.cc: this implements the imager DO
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
//# $Id: DOqimager.cc,v 1.23 2005/11/07 21:17:04 wyoung Exp $

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
#include <casa/Utilities/CompositeNumber.h>

#include <casa/BasicSL/Constants.h>

#include <casa/Logging/LogSink.h>
#include <casa/Logging/LogMessage.h>

#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>

#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/Slice.h>
#include <synthesis/MeasurementEquations/ClarkCleanProgress.h>
#include <lattices/Lattices/LatticeCleanProgress.h>
#include <msvis/MSVis/VisSet.h>
#include <msvis/MSVis/VisSetUtil.h>

#include <measures/Measures/Stokes.h>
#include <casa/Quanta/UnitMap.h>
#include <casa/Quanta/UnitVal.h>
#include <casa/Quanta/MVAngle.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <casa/Quanta/MVEpoch.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MeasTable.h>

#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSColumns.h>

#include <ms/MeasurementSets/MSDopplerUtil.h>
#include <ms/MeasurementSets/MSSourceIndex.h>
#include <ms/MeasurementSets/MSSummary.h>
#include <synthesis/MeasurementEquations/VisEquation.h>
#include <synthesis/MeasurementComponents/ImageSkyModel.h>
#include <synthesis/MeasurementComponents/CEMemImageSkyModel.h>
#include <synthesis/MeasurementComponents/MFCEMemImageSkyModel.h>
#include <synthesis/MeasurementComponents/MFCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/CSCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/MFMSCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/HogbomCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/MSCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/NNLSImageSkyModel.h>
#include <synthesis/MeasurementComponents/MosaicFT.h>
#include <synthesis/MeasurementComponents/WProjectFT.h>
#include <synthesis/MeasurementComponents/SDGrid.h>
#include <synthesis/MeasurementComponents/SimpleComponentFTMachine.h>
#include <synthesis/MeasurementComponents/VPSkyJones.h>

#include <synthesis/MeasurementEquations/StokesImageUtil.h>
#include <lattices/Lattices/TiledLineStepper.h> 
#include <lattices/Lattices/LatticeIterator.h> 
#include <lattices/Lattices/LatticeExpr.h> 
#include <lattices/Lattices/LCBox.h> 
#include <lattices/Lattices/LatticeFFT.h>
#include <images/Images/ImageRegrid.h>
#include <synthesis/MeasurementComponents/PBMath.h>


#include <images/Images/PagedImage.h>
#include <images/Images/ImageInfo.h>

#include <coordinates/Coordinates/CoordinateSystem.h>
#include <coordinates/Coordinates/DirectionCoordinate.h>
#include <coordinates/Coordinates/SpectralCoordinate.h>
#include <coordinates/Coordinates/StokesCoordinate.h>
#include <coordinates/Coordinates/Projection.h>
#include <coordinates/Coordinates/ObsInfo.h>

#include <components/ComponentModels/ComponentList.h>
#include <components/ComponentModels/ConstantSpectrum.h>
#include <components/ComponentModels/Flux.h>
#include <components/ComponentModels/PointShape.h>
#include <components/ComponentModels/FluxStandard.h>

#include <appsglish/qimager/DOqimager.h>

#include <casa/OS/HostInfo.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/Index.h>
#include <tasking/Tasking/MethodResult.h>
#include <tasking/Tasking/ObjectController.h>

#include <components/ComponentModels/ComponentList.h>

#include <casa/sstream.h>

namespace casa {

qimager::qimager() 
  : msname_p(""), ms_p(0), mssel_p(0), vs_p(0), ft_p(0), cft_p(0), se_p(0),
    sm_p(0), vp_p(0), gvp_p(0), setimaged_p(False), nullSelect_p(False)
{
  defaults();
};

void qimager::defaults() 
{

  setimaged_p=False;
  nullSelect_p=False;
  nx_p=128; ny_p=128; facets_p=1;
  mcellx_p=Quantity(1, "arcsec"); mcelly_p=Quantity(1, "arcsec");
  shiftx_p=Quantity(0.0, "arcsec"); shifty_p=Quantity(0.0, "arcsec");
  distance_p=Quantity(0.0, "m");
  stokes_p="I"; npol_p=1;
  nscales_p=5;
  scaleMethod_p="nscales";  
  scaleInfoValid_p=False;
  dataMode_p="none";
  imageMode_p="mfs";
  dataNchan_p=0;
  imageNchan_p=0;
  doVP_p=False;
  doDefaultVP_p = True;
  telescope_p="VLA";
  gridfunction_p="SF";
  // Use half the machine memory as cache. The user can override
  // this via the setoptions function().
  cache_p=HostInfo::memoryTotal()*1024*1024*1024/(2*4);
  tile_p=16;
  ftmachine_p="ft";
  wfGridding_p=False;
  padding_p=1.2;
  sdScale_p=1.0;
  sdWeight_p=1.0;

  doShift_p=False;
  spectralwindowids_p.resize(1); 
  spectralwindowids_p=0;
  fieldid_p=0;
  dataspectralwindowids_p.resize(0); 
  datadescids_p.resize(0);
  datafieldids_p.resize(0);
  mImageStart_p=MRadialVelocity(Quantity(0.0, "km/s"), MRadialVelocity::LSRK);
  mImageStep_p=MRadialVelocity(Quantity(0.0, "km/s"), MRadialVelocity::LSRK);
  mDataStart_p=MRadialVelocity(Quantity(0.0, "km/s"), MRadialVelocity::LSRK);
  mDataStep_p=MRadialVelocity(Quantity(0.0, "km/s"), MRadialVelocity::LSRK);
  beamValid_p=False;
  bmaj_p=Quantity(0, "arcsec");
  bmin_p=Quantity(0, "arcsec");
  bpa_p=Quantity(0, "deg");
  images_p.resize(0);
  masks_p.resize(0);
  fluxMasks_p.resize(0);
  residuals_p.resize(0);
  componentList_p=0;

  cyclefactor_p = 1.5;
  cyclespeedup_p =  -1;
  stoplargenegatives_p = 2;
  stoppointmode_p = -1;
  fluxscale_p.resize(0);
  scaleType_p = "NONE";
  minPB_p = 0.1;
  constPB_p = 0.4;
  redoSkyModel_p=True;
  nmodels_p=0;
  
  freqFrameValid_p=False;
}

qimager::qimager(MeasurementSet &theMs, Bool compress)
  : msname_p(""), ms_p(0), mssel_p(0), vs_p(0), ft_p(0), cft_p(0), se_p(0),
    sm_p(0), vp_p(0), gvp_p(0), setimaged_p(False), nullSelect_p(False)
{


  LogIO os(LogOrigin("qimager", "qimager(MeasurementSet &theMS)", WHERE));
  if(!open(theMs, compress)) {
    os << LogIO::SEVERE << "Open of MeasurementSet failed" << LogIO::EXCEPTION;
  };

  defaults();

}

qimager::qimager(const qimager &other)
  : msname_p(""), ms_p(0), mssel_p(0), vs_p(0), ft_p(0), cft_p(0), se_p(0),
    sm_p(0), vp_p(0), gvp_p(0), setimaged_p(False), nullSelect_p(False)
{
  defaults();
  open(*(other.ms_p));
}

qimager &qimager::operator=(const qimager &other)
{
  if (ms_p && this != &other) {
    *ms_p = *(other.ms_p);
  }
  if (mssel_p && this != &other) {
    *mssel_p = *(other.mssel_p);
  }
  if (vs_p && this != &other) {
    *vs_p = *(other.vs_p);
  }
  if (ft_p && this != &other) {
    *ft_p = *(other.ft_p);
  }
  if (cft_p && this != &other) {
    *cft_p = *(other.cft_p);
  }
  if (se_p && this != &other) {
    *se_p = *(other.se_p);
  }
  if (sm_p && this != &other) {
    *sm_p = *(other.sm_p);
  }
  if (vp_p && this != &other) {
    *vp_p = *(other.vp_p);
  }
  if (gvp_p && this != &other) {
    *gvp_p = *(other.gvp_p);
  }
  return *this;
}

qimager::~qimager()
{
  if (mssel_p) {
    delete mssel_p;
  }
  mssel_p = 0;
  if (ms_p) {
    delete ms_p;
  }
  ms_p = 0;
  if (vs_p) {
    delete vs_p;
  }
  vs_p = 0;
  if (ft_p) {
    delete ft_p;
  }
  ft_p = 0;
  if (cft_p) {
    delete cft_p;
  }
  cft_p = 0;
  if (itsQimager){
    delete itsQimager; 
  }
  destroySkyEquation();
}

Bool qimager::open(MeasurementSet& theMs, Bool compress)
{


  LogIO os(LogOrigin("qimager", "open()", WHERE));
  
  if (ms_p) {
    *ms_p = theMs;
  } else {
    ms_p = new MeasurementSet(theMs);
    AlwaysAssert(ms_p, AipsError);
  }
  
  try {
    itsQimager= new Qimager(*ms_p);
    itsQimager->openSubTables();
    itsQimager->lock();
    msname_p = ms_p->tableName();
    
    os << "Opening MeasurementSet " << msname_p << LogIO::POST;

    // Check for DATA or FLOAT_DATA column
    if(!ms_p->tableDesc().isColumn("DATA") && 
       !ms_p->tableDesc().isColumn("FLOAT_DATA")) {
      os << LogIO::SEVERE
	 << "Missing DATA or FLOAT_DATA column: qimager cannot be run"
	 << LogIO::POST;
      ms_p->unlock();
      delete ms_p; ms_p=0;
      return False;
    }
    
    Bool initialize=(!ms_p->tableDesc().isColumn("CORRECTED_DATA"));
    
    if(vs_p) {
      delete vs_p; vs_p=0;
    }
    
    // Now open the selected MeasurementSet to be initially the
    // same as the original MeasurementSet
    mssel_p=new MeasurementSet(*ms_p);
    
    // Now create the VisSet
    Block<int> sort(4);
    sort[0] = MS::FIELD_ID;
    sort[1] = MS::ARRAY_ID;
    sort[2] = MS::DATA_DESC_ID;
    sort[3] = MS::TIME;
    
    Matrix<Int> noselection;
    Double timeInterval=0;
    vs_p = new VisSet(*mssel_p,sort,noselection,timeInterval,compress);
    AlwaysAssert(vs_p, AipsError);
    
    // Polarization
    MSColumns msc(*mssel_p);
    Vector<String> polType=msc.feed().polarizationType()(0);
    if (polType(0)!="X" && polType(0)!="Y" &&
	polType(0)!="R" && polType(0)!="L") {
      os << LogIO::SEVERE << "Warning: Unknown stokes types in feed table: "
	 << polType(0) << endl
	 << "Results open to question!" << LogIO::POST;
    }
    
    
    // Initialize the weights if the IMAGING_WEIGHT column
    // was just created
    if(initialize) {
      os << LogIO::NORMAL
	 << "Initializing natural weights"
	 << LogIO::POST;
      Double sumwt=0.0;
      VisSetUtil::WeightNatural(*vs_p, sumwt);
    }
    itsQimager->unlock();

    return True;
  } catch (AipsError x) {
    itsQimager->unlock();
    os << LogIO::SEVERE << "Caught Exception: "<< x.getMesg() << LogIO::POST;

    return False;
  } 

  return True;
}

Bool qimager::close()
{
  if(!valid()) return False;
  if (detached()) return True;
  LogIO os(LogOrigin("qimager", "close()", WHERE));
  os << "Closing MeasurementSet and detaching from qimager"
     << LogIO::POST;
  itsQimager->unlock();
  if(ft_p) delete ft_p; ft_p = 0;
  if(cft_p) delete cft_p; cft_p = 0;
  if(vs_p) delete vs_p; vs_p = 0;
  if(mssel_p) delete mssel_p; mssel_p = 0;
  if(ms_p) delete ms_p; ms_p = 0;

  if(se_p) delete se_p; se_p = 0;

  if(vp_p) delete vp_p; vp_p = 0;
  if(gvp_p) delete gvp_p; gvp_p = 0;

  return True;
}

String qimager::name() const
{
  if (detached()) {
    return "none";
  }
  return msname_p;
}

String qimager::imageName() const
{
  LogIO os(LogOrigin("qimager", "imageName()", WHERE));
  try {
    itsQimager->lock();
    String name(msname_p);
    MSColumns msc(*ms_p);
    if(datafieldids_p.shape() !=0) {
      name=msc.field().name()(datafieldids_p(0));
    }
    else if(fieldid_p > -1) {
       name=msc.field().name()(fieldid_p);
    }
    itsQimager->unlock();
    return name;
  } catch (AipsError x) {
    itsQimager->unlock();
    os << LogIO::SEVERE << "Caught Exception: "<< x.getMesg()
       << LogIO::POST; return "";
  } 
  return String("qimagerImage");
}


// Make standard choices for coordinates
Bool qimager::imagecoordinates(CoordinateSystem& coordInfo) 
{  
  if(!valid()) return False;
  if(!assertDefinedImageParameters()) return False;
  LogIO os(LogOrigin("qimager", "imagecoordinates()", WHERE));
  
  Vector<Double> deltas(2);
  deltas(0)=-mcellx_p.get("rad").getValue();
  deltas(1)=mcelly_p.get("rad").getValue();
  
  MSColumns msc(*ms_p);
  MFrequency::Types obsFreqRef=MFrequency::DEFAULT;
  ROScalarColumn<Int> measFreqRef(ms_p->spectralWindow(),
				  MSSpectralWindow::columnName(MSSpectralWindow::MEAS_FREQ_REF));
  //using the first frame of reference; TO DO should do the right thing 
  //for different frames selected. 
  if(measFreqRef(spectralwindowids_p(0)) >=0) 
     obsFreqRef=(MFrequency::Types)measFreqRef(spectralwindowids_p(0));
			    

  // MS Doppler tracking utility
  MSDopplerUtil msdoppler(*ms_p);

  MVDirection mvPhaseCenter(phaseCenter_p.getAngle());
  // Normalize correctly
  MVAngle ra=mvPhaseCenter.get()(0);
  ra(0.0);
  MVAngle dec=mvPhaseCenter.get()(1);
  Vector<Double> refCoord(2);
  refCoord(0)=ra.get().getValue();    
  refCoord(1)=dec;    
  
  Vector<Double> refPixel(2); 
  refPixel(0)=Double(nx_p/2);
  refPixel(1)=Double(ny_p/2);
  
  //defining observatory...needed for position on earth
  String telescop=msc.observation().telescopeName()(0);
  // defining epoch as begining time from timerange in OBSERVATION subtable
  // Using first observation for now
  MEpoch obsEpoch=msc.observation().timeRangeMeas()(0)(IPosition(1,0));

  //Now finding the position of the telescope on Earth...needed for proper
  //frequency conversions

  MPosition obsPosition;
  if(! (MeasTable::Observatory(obsPosition, telescop))){
    os << LogIO::WARN << "Did not get the position of " << telescop 
       << " from data repository" << LogIO::POST ;
    os << LogIO::WARN 
       << "Please do inform aips++  to put in the repository "
       << LogIO::POST;
    os << LogIO::WARN << "Frequency conversion will not work " << LogIO::POST;
    freqFrameValid_p=False;
  }
  else{
    freqFrameValid_p=True;
  }
  // Now find the projection to use: could probably also use
  // max(abs(w))=0.0 as a criterion
  Projection projection(Projection::SIN);
  if(telescop=="ATCA") {
    os << LogIO::NORMAL << "Using SIN image projection adjusted for SCP" 
       << LogIO::POST;
    Vector<Double> projectionParameters(2);
    projectionParameters(0)=0.0;
    if(sin(dec)!=0.0) {
      projectionParameters(1)=cos(dec)/sin(dec);
      projection=Projection(Projection::SIN, projectionParameters);
    }
    else {
      os << LogIO::WARN << "Singular projection for ATCA: using plain SIN" << LogIO::POST;
      projection=Projection(Projection::SIN);
    }
  }
  else if(telescop=="WSRT") {
    os << LogIO::NORMAL << "Using SIN image projection adjusted for NCP" 
       << LogIO::POST;
    Vector<Double> projectionParameters(2);
    projectionParameters(0)=0.0;
    if(sin(dec)!=0.0) {
      projectionParameters(1)=cos(dec)/sin(dec);
      projection=Projection(Projection::SIN, projectionParameters);
    }
    else {
      os << LogIO::WARN << "Singular projection for WSRT: using plain SIN" 
	 << LogIO::POST;
      projection=Projection(Projection::SIN);
    }
  }
  else {
    os << LogIO::DEBUGGING << "Using SIN image projection" << LogIO::POST;
  }
  os << LogIO::NORMAL;
  
  Matrix<Double> xform(2,2);
  xform=0.0;xform.diagonal()=1.0;
  DirectionCoordinate
    myRaDec(MDirection::Types(phaseCenter_p.getRefPtr()->getType()),
	    projection,
	    refCoord(0), refCoord(1),
	    deltas(0), deltas(1),
	    xform,
	    refPixel(0), refPixel(1));
  
  // Now set up spectral coordinate
  SpectralCoordinate* mySpectral=0;
  Double refChan=0.0;
  
  // Spectral synthesis
  // For mfs band we set the window to include all spectral windows
  Int nspw=spectralwindowids_p.nelements();
  if (imageMode_p=="mfs") {
    Double fmin=C::dbl_max;
    Double fmax=-(C::dbl_max);
    Double fmean=0.0;
    for (Int i=0;i<nspw;i++) {
      Int spw=spectralwindowids_p(i);
      Vector<Double> chanFreq=msc.spectralWindow().chanFreq()(spw); 
      Vector<Double> freqResolution=msc.spectralWindow().resolution()(spw); 
      
      if(dataMode_p=="none"){
      

	if(i==0) {
	  fmin=min(chanFreq-abs(freqResolution));
	  fmax=max(chanFreq+abs(freqResolution));
	}
	else {
	  fmin=min(fmin,min(chanFreq-abs(freqResolution)));
	  fmax=max(fmax,max(chanFreq+abs(freqResolution)));
	}
      }
      else if(dataMode_p=="channel"){
	Int lastchan=dataStart_p[i]+ dataNchan_p[i]*dataStep_p[i];
        for(Int k=dataStart_p[i] ; k < lastchan ;  k+=dataStep_p[i]){
	  fmin=min(fmin,chanFreq[k]-abs(freqResolution[k]*dataStep_p[i]));
	  fmax=max(fmax,chanFreq[k]+abs(freqResolution[k]*dataStep_p[i]));
        }
      }
      else{
            os << LogIO::SEVERE << "setdata has to be in 'channel' or 'none' mode for 'mfs' imaging to work"
	 << LogIO::POST;
      return False;
      }
 
    }

    fmean=(fmax+fmin)/2.0;
    // Look up first rest frequency found (for now)
    Vector<Double> restFreqArray;
    Double restFreq=fmean;
    Int fieldid = (datafieldids_p.nelements()>0 ? datafieldids_p(0) : fieldid_p);
    if (msdoppler.dopplerInfo(restFreqArray,spectralwindowids_p(0),fieldid)) {
      restFreq = restFreqArray(0);    
    } 
    imageNchan_p=1;
    Double finc=(fmax-fmin); 
    mySpectral = new SpectralCoordinate(obsFreqRef,  fmean, finc,
      					refChan, restFreq);
    os <<  "Frequency = "
       << MFrequency(Quantity(fmean, "Hz")).get("GHz").getValue()
       << " GHz, synthesized continuum bandwidth = "
       << MFrequency(Quantity(finc, "Hz")).get("GHz").getValue()
       << " GHz" << LogIO::POST;
  } else {
    //    if(nspw>1) {
    //      os << LogIO::SEVERE << "Line modes allow only one spectral window"
    //	 << LogIO::POST;
    //      return False;
    //    }
    Vector<Double> chanFreq;
    Vector<Double> freqResolution;
    //starting with a default rest frequency to be ref 
    //in case none is defined
    Double restFreq=
      msc.spectralWindow().refFrequency()(spectralwindowids_p(0));

    for (Int spwIndex=0; spwIndex < nspw; ++spwIndex){
 
      Int spw=spectralwindowids_p(spwIndex);
      Int origsize=chanFreq.shape()(0);
      Int newsize=origsize+msc.spectralWindow().chanFreq()(spw).shape()(0);
      chanFreq.resize(newsize, True);
      chanFreq(Slice(origsize, newsize-origsize))=msc.spectralWindow().chanFreq()(spw);
      freqResolution.resize(newsize, True);
      freqResolution(Slice(origsize, newsize-origsize))=
	msc.spectralWindow().resolution()(spw); 
      
      // Look up first rest frequency found (for now)
     
      Vector<Double> restFreqArray;
      Int fieldid = (datafieldids_p.nelements()>0 ? datafieldids_p(0) : 
		     fieldid_p);
      if (msdoppler.dopplerInfo(restFreqArray,spw,fieldid)) {
	if(spwIndex==0){
	  restFreq = restFreqArray(0);
	}
	else{
	  if(restFreq != restFreqArray(0)){
	    os << LogIO::WARN << "Rest frequencies are different for  spectralwindows selected " 
	       << LogIO::POST;
	    os << LogIO::WARN 
	       <<"Will be using the restFreq defined in spectralwindow "
	       << spectralwindowids_p(0)+1 << LogIO::POST;
	  }
	  
	}	
      }
    }

    if(imageMode_p=="channel") {
      if(imageNchan_p==0) {
	os << LogIO::SEVERE << "Must specify number of channels" 
	   << LogIO::POST;
	return False;
      }
      Vector<Double> freqs;
      Int nsubchans=
	(chanFreq.shape()(0) - Int(imageStart_p)+1)/Int(imageStep_p);
      if(imageNchan_p>nsubchans) imageNchan_p=nsubchans;
      os << "Image spectral coordinate: "<< imageNchan_p
	   << " channels, starting at visibility channel "
	 << imageStart_p+1 << " stepped by "
	 << imageStep_p << endl;
      freqs.resize(imageNchan_p);
      for (Int chan=0;chan<imageNchan_p;chan++) {
	freqs(chan)=chanFreq(Int(imageStart_p)+chan*Int(imageStep_p));
      }
      // Use this next line when non-linear working
      //    mySpectral = new SpectralCoordinate(obsFreqRef, freqs,
      //					restFreq);
      // Since we are taking the frequencies as is, the frame must be
      // what is specified in the SPECTRAL_WINDOW table
      //      Double finc=(freqs(imageNchan_p-1)-freqs(0))/(imageNchan_p-1);
      Double finc;
      if(imageNchan_p > 1){
	finc=freqs(1)-freqs(0);
      }
      else if(imageNchan_p==1) {
	finc=freqResolution(IPosition(1,0))*imageStep_p;
      }
      mySpectral = new SpectralCoordinate(obsFreqRef, freqs(0), finc,
					  refChan, restFreq);
      os <<  "Frequency = "
	 << MFrequency(Quantity(freqs(0), "Hz")).get("GHz").getValue()
	 << ", channel increment = "
	 << MFrequency(Quantity(finc, "Hz")).get("GHz").getValue() 
	 << "GHz" << endl;
      os << LogIO::NORMAL << "Rest frequency is " 
	 << MFrequency(Quantity(restFreq, "Hz")).get("GHz").getValue()
	 << "GHz" << LogIO::POST;
      
    }
    // Spectral channels resampled at equal increments in optical velocity
    // Here we compute just the first two channels and use increments for
    // the others
    else if (imageMode_p=="velocity") {
      if(imageNchan_p==0) {
	os << LogIO::SEVERE << "Must specify number of channels" 
	   << LogIO::POST;
	return False;
      }
      {
	ostringstream oos;
	oos << "Image spectral coordinate:"<< imageNchan_p 
	    << " channels, starting at radio velocity " << mImageStart_p
	    << "  stepped by " << mImageStep_p << endl;
	os << String(oos);
      }
      Vector<Double> freqs(2);
      freqs=0.0;
      if(Double(mImageStep_p.getValue())!=0.0) {
	MRadialVelocity mRadVel=mImageStart_p;
	for (Int chan=0;chan<2;chan++) {
	  MDoppler mdoppler=mRadVel.toDoppler();
	  freqs(chan)=
	    MFrequency::fromDoppler(mdoppler, 
				    restFreq).getValue().getValue();
	  Quantity vel=mRadVel.get("m/s");
	  Quantity inc=mImageStep_p.get("m/s");
	  vel+=inc;
	  mRadVel=MRadialVelocity(vel, MRadialVelocity::LSRK);
	}
      }
      else {
	for (Int chan=0;chan<2;chan++) {
	  freqs(chan)=chanFreq(chan);
	}
      }

      // when setting in velocity its in LSRK
      mySpectral = new SpectralCoordinate(MFrequency::LSRK, freqs(0),
					  freqs(1)-freqs(0), refChan,
					  restFreq);
      {
	ostringstream oos;
	oos << "Reference Frequency = "
	    << MFrequency(Quantity(freqs(0), "Hz")).get("GHz")
	    << ", spectral increment = "
	    << MFrequency(Quantity(freqs(1)-freqs(0), "Hz")).get("GHz") 
	    << endl;
	oos << "Rest frequency is " 
	    << MFrequency(Quantity(restFreq, "Hz")).get("GHz").getValue()
	    << " GHz" << endl;
	os << String(oos) << LogIO::POST;
      }
      
    }
    // Since optical velocity is non-linear in frequency, we have to
    // pass in all the frequencies. For radio velocity we can use 
    // a linear axis.
    else if (imageMode_p=="opticalvelocity") {
      if(imageNchan_p==0) {
	os << LogIO::SEVERE << "Must specify number of channels" 
	   << LogIO::POST;
	return False;
      }
      {
	ostringstream oos;
	oos << "Image spectral coordinate: "<< imageNchan_p 
	    << " channels, starting at optical velocity " << mImageStart_p
	    << "  stepped by " << mImageStep_p << endl;
	os << String(oos);
      }
      Vector<Double> freqs(imageNchan_p);
      freqs=0.0;
      if(Double(mImageStep_p.getValue())!=0.0) {
	MRadialVelocity mRadVel=mImageStart_p;
	for (Int chan=0;chan<imageNchan_p;chan++) {
	  MDoppler mdoppler=mRadVel.toDoppler();
	  freqs(chan)=
	    MFrequency::fromDoppler(mdoppler, restFreq).getValue().getValue();
	  mRadVel.set(mRadVel.getValue()+mImageStep_p.getValue());
	}
      }
      else {
	for (Int chan=0;chan<imageNchan_p;chan++) {
	    freqs(chan)=chanFreq(chan);
	}
      }
      // Use this next line when non-linear is working
      // when selecting in velocity its LSRK
      mySpectral = new SpectralCoordinate(MFrequency::LSRK, freqs,
					  restFreq);
      // mySpectral = new SpectralCoordinate(MFrequency::DEFAULT, freqs(0),
      //				       freqs(1)-freqs(0), refChan,
      //				        restFreq);
      {
	ostringstream oos;
	oos << "Reference Frequency = "
	    << MFrequency(Quantity(freqs(0), "Hz")).get("GHz")
	    << " Ghz" << endl;
	os << String(oos) << LogIO::POST;
      }
    }
    else {
      os << LogIO::SEVERE << "Unknown mode " << imageMode_p
	 << LogIO::POST;
      return False;
    }
    
    
    if(freqFrameValid_p && (imageMode_p != "mfs") ){
    //In FTMachine lsrk is used for channel matching with data channel 
    //hence we make sure that
    // we convert to lsrk when dealing with the channels
    
      mySpectral->setReferenceConversion(MFrequency::LSRK, obsEpoch, 
					 obsPosition,
					 phaseCenter_p);
    }
  }
  
  // Polarization
  Vector<String> polType=msc.feed().polarizationType()(0);
  if (polType(0)!="X" && polType(0)!="Y" &&
      polType(0)!="R" && polType(0)!="L") {
    os << "Warning: Unknown stokes types in feed table: ["
       << polType(0) << ", " << polType(1) << "]" << endl
       << "Results open to question!" << LogIO::POST;
  }
  
  if (polType(0)=="X" || polType(0)=="Y") {
    polRep_p=SkyModel::LINEAR;
    os << "Preferred polarization representation is linear" << LogIO::POST;
  }
  else {
    polRep_p=SkyModel::CIRCULAR;
    os << "Preferred polarization representation is circular" << LogIO::POST;
  }

  Vector<Int> whichStokes(npol_p);
  switch(npol_p) {
  case 1:
    whichStokes.resize(1);
    whichStokes(0)=Stokes::I;
    os <<  "Image polarization = Stokes I" << LogIO::POST;
    break;
  case 2:
    whichStokes.resize(2);
    whichStokes(0)=Stokes::I;
    if (polRep_p==SkyModel::LINEAR) {
      whichStokes(1)=Stokes::Q;
      os <<  "Image polarization = Stokes I,Q" << LogIO::POST;
    }
    else {
      whichStokes(1)=Stokes::V;
      os <<  "Image polarization = Stokes I,V" << LogIO::POST;
    }
    break;
  case 3:
    whichStokes.resize(3);
    whichStokes(0)=Stokes::I;
    whichStokes(1)=Stokes::Q;
    whichStokes(1)=Stokes::U;
    os <<  "Image polarization = Stokes I,Q,U" << LogIO::POST;
    break;
  case 4:
    whichStokes.resize(4);
    whichStokes(0)=Stokes::I;
    whichStokes(1)=Stokes::Q;
    whichStokes(2)=Stokes::U;
    whichStokes(3)=Stokes::V;
    os <<  "Image polarization = Stokes I,Q,U,V" << LogIO::POST;
    break;
  default:
    os << LogIO::SEVERE << "Illegal number of Stokes parameters: " << npol_p
       << LogIO::POST;
    return False;
  };
  
  StokesCoordinate myStokes(whichStokes);
  

  //Set Observatory info
  ObsInfo myobsinfo;
  myobsinfo.setTelescope(telescop);
  myobsinfo.setPointingCenter(mvPhaseCenter);
  myobsinfo.setObsDate(obsEpoch);

  //Adding everything to the coordsystem
  coordInfo.addCoordinate(myRaDec);
  coordInfo.addCoordinate(myStokes);
  coordInfo.addCoordinate(*mySpectral);
  coordInfo.setObsInfo(myobsinfo);

  if(mySpectral) delete mySpectral;
  
  return True;
}

IPosition qimager::imageshape() const
{
  return IPosition(4, nx_p, ny_p, npol_p, imageNchan_p);
}

Bool qimager::summary() const
{
  if(!valid()) return False;
  LogOrigin OR("qimager", "qimager::summary()", id(), WHERE);
  
  LogIO los(OR);
  
  los << "Logging summary" << LogIO::POST;
  try {
    
    itsQimager->lock();
    MSSummary mss(*ms_p);
    mss.list(los, True);
    
    los << endl << state() << LogIO::POST;
    itsQimager->unlock();
    return True;
  } catch (AipsError x) {
    los << LogIO::SEVERE << "Caught Exception: " << x.getMesg()
	<< LogIO::POST;
    itsQimager->unlock();
    return False;
  } 
  
  return True;
}

String qimager::state() const
{
  ostringstream os;
  
  try {
    itsQimager->lock();
    os << "General: " << endl;
    os << "  MeasurementSet is " << ms_p->tableName() << endl;
    if(beamValid_p) {
      os << "  Beam fit: " << bmaj_p.get("arcsec").getValue() << " by "
	 << bmin_p.get("arcsec").getValue() << " (arcsec) at pa " 
	 << bpa_p.get("deg").getValue() << " (deg) " << endl;
    }
    else {
      os << "  Beam fit is not valid" << endl;
    }
    
    MSColumns msc(*ms_p);
    MDirection mDesiredCenter;
    if(setimaged_p) {
      os << "Image definition settings: "
	"(use setimage in Function Group <setup> to change)" << endl;
      os << "  nx=" << nx_p << ", ny=" << ny_p
	 << ", cellx=" << mcellx_p << ", celly=" << mcelly_p
	 << ", Stokes axes : " << stokes_p << endl;
      Int widthRA=20;
      Int widthDec=20;
      if(doShift_p) {
	os << "  doshift is True: Image phase center will be as specified "
	   << endl;
      }
      else {
	os << "  doshift is False: Image phase center will be that of field "
	   << fieldid_p+1 << " :" << endl;
      }
      
      if(shiftx_p.get().getValue()!=0.0||shifty_p.get().getValue()!=0.0) {
	os << "  plus the shift: longitude: " << shiftx_p
	   << " / cos(latitude) : latitude: " << shifty_p << endl;
      }
      
      MVAngle mvRa=phaseCenter_p.getAngle().getValue()(0);
      MVAngle mvDec=phaseCenter_p.getAngle().getValue()(1);
      os << "     ";
      os.setf(ios::left, ios::adjustfield);
      os.width(widthRA);  os << mvRa(0.0).string(MVAngle::TIME,8);
      os.width(widthDec); os << mvDec.string(MVAngle::DIG2,8);
      os << "     " << MDirection::showType(phaseCenter_p.getRefPtr()->getType())
	 << endl;
      
      if(distance_p.get().getValue()!=0.0) {
	os << "  Refocusing to distance " << distance_p << endl;
      }
      
      if(imageMode_p=="mfs") {
	os << "  Image mode is mfs: Image will be frequency synthesised from spectral windows : ";
	for (uInt i=0;i<spectralwindowids_p.nelements();i++) {
	  os << spectralwindowids_p(i)+1 << " ";
	}
	os << endl;
      }
      
      else {
	os << "  Image mode is " << imageMode_p
	   << "  Image number of spectral channels ="
	   << imageNchan_p << endl;
      }
      
    }
    else {
      os << "Image: parameters not yet set (use setimage "
	"in Function Group <setup> )" << endl;
    }
    
    os << "Data selection settings: (use setdata in Function Group <setup> "
      "to change)" << endl;
    if(dataMode_p=="none") {
      if(mssel_p->nrow() == ms_p->nrow()){
	os << "  All data selected" << endl;
      }
      else{
        os << " Number of rows of data selected= " << mssel_p->nrow() << endl;
      }
    }
    else {
      os << "  Data selection mode is " << dataMode_p << ": have selected "
	 << dataNchan_p << " channels";
      if(dataspectralwindowids_p.nelements()>0) {
	os << " spectral windows : ";
	for (uInt i=0;i<dataspectralwindowids_p.nelements();i++) {
	  os << dataspectralwindowids_p(i)+1 << " ";
	}
      }
      if(datafieldids_p.nelements()>0) {
	os << "  Data selected includes fields : ";
	for (uInt i=0;i<datafieldids_p.nelements();i++) {
	  os << datafieldids_p(i)+1 << " ";
	}
      }
      os << endl;
    }
    os << "Options settings: (use setoptions in Function Group <setup> "
      "to change) " << endl;
    os << "  Gridding cache has " << cache_p << " complex pixels, in tiles of "
       << tile_p << " pixels on a side" << endl;
    os << "  Gridding convolution function is ";
    
    os << endl;
    
    if(doVP_p) {
      os << "  Primary beam correction is enabled" << endl;
      //       Table vpTable( vpTableStr_p );   could fish out info and summarize
    }
    else {
      os << "  No primary beam correction will be made " << endl;
    }
    os << "  Image plane padding : " << padding_p << endl;
    
    itsQimager->unlock();
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << endl;
    itsQimager->unlock();
  } 
  return String(os);
}

Bool qimager::setimage(const Int nx, const Int ny,
		      const Quantity& cellx, const Quantity& celly,
		      const String& stokes,
		      Bool doShift,
		      const MDirection& phaseCenter, 
		      const Quantity& shiftx, const Quantity& shifty,
		      const String& mode, const Int nchan,
		      const Int start, const Int step,
		      const MRadialVelocity& mStart,
		       const MRadialVelocity& mStep,
		      const Vector<Int>& spectralwindowids,
		      const Int fieldid,
		      const Int facets,
		      const Quantity& distance)
{



  if(!valid())
    {

      return False;
    }

  LogIO os(LogOrigin("qimager", "setimage()", WHERE));
  
  os << "Defining image properties" << LogIO::POST;
  
  try {
    
    itsQimager->lock();
    if(2*Int(nx/2)!=nx) {
      os << LogIO::SEVERE << "nx must be even" << LogIO::POST;
      return False;
    }
    if(2*Int(ny/2)!=ny) {
      os << LogIO::SEVERE << "ny must be even" << LogIO::POST;
      return False;
    }
    {
      CompositeNumber cn(nx);
      if (! cn.isComposite(nx)) {
	Int nxc = (Int)cn.nextLargerEven(nx);
	Int nnxc = (Int)cn.nearestEven(nx);
	if (nxc == nnxc) {
	  os << LogIO::WARN << "nx = " << nx << " is not composite; nx = " 
	     << nxc << " will be more efficient" << LogIO::POST;
	} else {
	  os <<  LogIO::WARN << "nx = " << nx << " is not composite; nx = " 
	     << nxc <<  " or " << nnxc << " will be more efficient" << LogIO::POST;
	}
      }
      if (! cn.isComposite(ny)) {
	Int nyc = (Int)cn.nextLargerEven(ny);
	Int nnyc = (Int)cn.nearestEven(ny);
	if (nyc == nnyc) {
	  os <<  LogIO::WARN << "ny = " << ny << " is not composite; ny = " 
	     << nyc << " will be more efficient" << LogIO::POST;
	} else {
	  os <<  LogIO::WARN << "ny = " << ny << " is not composite; ny = " << nyc << 
	      " or " << nnyc << " will be more efficient" << LogIO::POST;
	}
      }
    }

    nx_p=nx;
    ny_p=ny;
    mcellx_p=cellx;
    mcelly_p=celly;
    distance_p=distance;
    stokes_p=stokes;
    imageMode_p=mode;
    imageNchan_p=nchan;
    imageStart_p=start;
    imageStep_p=step;
    mImageStart_p=mStart;
    mImageStep_p=mStep;
    spectralwindowids_p.resize(spectralwindowids.nelements());
    spectralwindowids_p=spectralwindowids;
    fieldid_p=fieldid;
    facets_p=facets;
    redoSkyModel_p=True;
    destroySkyEquation();

    // Now make the derived quantities 
    if(stokes_p=="I") {
      npol_p=1;
    }
    else if(stokes_p=="IQ") {
      npol_p=2;
    }
    else if(stokes_p=="IV") {
      npol_p=2;
    }
    else if(stokes_p=="IQU") {
      npol_p=3;
    }
    else if(stokes_p=="IQUV") {
      npol_p=4;
    }
    else {
      os << LogIO::SEVERE << "Illegal Stokes string " << stokes_p
	 << LogIO::POST;

      return False;
    };
    
    // Now do the shifts
    MSColumns msc(*ms_p);

    doShift_p=doShift;
    if(doShift_p) {
      phaseCenter_p=phaseCenter;
    }
    else {
      phaseCenter_p=msc.field().phaseDirMeas(fieldid_p);
    }
    
    // Now add the optional shifts
    shiftx_p=shiftx;
    shifty_p=shifty;
    if(shiftx_p.get().getValue()!=0.0||shifty_p.get().getValue()!=0.0) {
      Vector<Double> vPhaseCenter(phaseCenter_p.getAngle().getValue());
      if(cos(vPhaseCenter(1))!=0.0) {
	vPhaseCenter(0)+=shiftx_p.get().getValue()/cos(vPhaseCenter(1));
      }
      vPhaseCenter(1)+=shifty_p.get().getValue();
      phaseCenter_p.set(MVDirection(vPhaseCenter));
    }
    
    // Now we have set the image parameters
    setimaged_p=True;
    beamValid_p=False;
    
    itsQimager->unlock();

    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    itsQimager->unlock();

    return False;
  } 

  return True;
}

Bool qimager::advise(const Bool takeAdvice, const Float amplitudeLoss,
		    const Quantity& fieldOfView, Quantity& cell,
		    Int& pixels, Int& facets, MDirection& phaseCenter)
{
  if(!valid()) return False;
  
  LogIO os(LogOrigin("qimager", "advise()", WHERE));
  
  try {
    
    os << "Advising image properties" << LogIO::POST;
    
    Float maxAbsUV=0.0;
    Float maxWtAbsUV=0.0;
    // To determine the number of facets, we need to fit w to
    // a.u + b.v. The misfit from this (i.e. the dispersion 
    // will determine the error beam due to the non-coplanar
    // baselines. We'll do both cases: where the position
    // errors are important and where they are not. We'll use
    // the latter.
    Double sumWt = 0.0;

    Double sumUU=0.0;
    Double sumUV=0.0;
    Double sumUW=0.0;
    Double sumVV=0.0;
    Double sumVW=0.0;
    Double sumWW=0.0;

    Double sumWtUU=0.0;
    Double sumWtUV=0.0;
    Double sumWtUW=0.0;
    Double sumWtVV=0.0;
    Double sumWtVW=0.0;
    Double sumWtWW=0.0;

    Double sum = 0.0;

    itsQimager->lock();
    VisIter& vi(vs_p->iter());
    VisBuffer vb(vi);
    
    for (vi.originChunks();vi.moreChunks();vi.nextChunk()) {
      for (vi.origin();vi.more();vi++) {
	Int nRow=vb.nRow();
	Int nChan=vb.nChannel();
	for (Int row=0; row<nRow; row++) {
	  for (Int chn=0; chn<nChan; chn++) {
	    if(!vb.flag()(chn,row)) {
	      Float f=vb.frequency()(chn)/C::c;
	      Float u=vb.uvw()(row)(0)*f;
	      Float v=vb.uvw()(row)(1)*f;
	      Float w=vb.uvw()(row)(2)*f;
              Double wt=vb.imagingWeight()(chn,row);
	      if(wt>0.0) {
		if(abs(u)>maxWtAbsUV) maxWtAbsUV=abs(u);
		if(abs(v)>maxWtAbsUV) maxWtAbsUV=abs(v);
		sumWt += wt;
                sumWtUU += wt * u * u;
                sumWtUV += wt * u * v;
                sumWtUW += wt * u * w;
                sumWtVV += wt * v * v;
                sumWtVW += wt * v * w;
                sumWtWW += wt * w * w;
	      }
	      sum += 1;
	      if(abs(u)>maxAbsUV) maxAbsUV=abs(u);
	      if(abs(v)>maxAbsUV) maxAbsUV=abs(v);
	      sumUU += u * u;
	      sumUV += u * v;
	      sumUW += u * w;
	      sumVV += v * v;
	      sumVW += v * w;
	      sumWW += w * w;
	    }
	  }
	}
      }
    }
    
    if(sumWt==0.0) {
      os << LogIO::WARN << "Visibility data are not yet weighted: using unweighted values" << LogIO::POST;
      sumWt = sum;
    }
    else {
      sumUU = sumWtUU;
      sumUV = sumWtUV;
      sumUW = sumWtUW;
      sumVV = sumWtVV;
      sumVW = sumWtVW;
      sumWW = sumWtWW;
      maxAbsUV = maxWtAbsUV;
    }

    // First find the cell size
    if(maxAbsUV==0.0) {
      os << LogIO::SEVERE << "Maximum uv distance is zero" << LogIO::POST;
      return False;
    }
    else {
      cell=Quantity(0.5/maxAbsUV, "rad").get("arcsec");
      os << "Maximum uv distance = " << maxAbsUV << " wavelengths" << endl;
      os << "Recommended cell size < " << cell.get("arcsec").getValue()
	 << " arcsec" << LogIO::POST;
    }

    // Now we can find the number of pixels for the specified field of view
    pixels = 2*Int((fieldOfView.get("rad").getValue()/cell.get("rad").getValue())/2.0);
    {
      CompositeNumber cn(pixels);
      pixels = (Int) (cn.nextLargerEven(pixels));
    }
    if(pixels < 64) pixels = 64;
    os << "Recommended number of pixels = " << pixels << endl;

      // Rough rule for number of facets:
      // For the specified facet size, the loss in amplitude
      // due to the peeling of facets from the sphere should 
      // be equal to the amplitude error.
      Int worstCaseFacets=1;
      if(sumWt<=0.0||sumUU<=0.0||(sumUU+sumVV)<=0.0) {
	os << LogIO::SEVERE << "Sum of imaging weights is zero" << LogIO::POST;
	return False;
      }
      else {
	Double rmsUV  = sqrt((sumUU + sumVV)/sumWt);
	Double rmsW = sqrt(sumWW/sumWt);
	os << "Dispersion in uv, w distance = " << rmsUV << ", "<< rmsW
	   << " wavelengths" << endl;
	if(rmsW>0.0&&rmsUV>0.0&&amplitudeLoss>0.0) {
	  worstCaseFacets =
	    Int (pixels * (abs(cell.get("rad").getValue())*
				  sqrt(C::pi*rmsW/(sqrt(32.0*amplitudeLoss)))));
	}
	else {
	  os << LogIO::WARN << "Cannot calculate number of facets: using 1"
	     << LogIO::POST;
	  worstCaseFacets = 1;
	}
	// Solve for the parameters:
	Double Determinant = sumUU * sumVV - square(sumUV);
	Double rmsFittedW = rmsW;
	if(Determinant > 0.0) {
	  Double a = ( sumVV * sumUW - sumUV * sumVW)/Determinant;
	  Double b = (-sumUV * sumUW + sumUU * sumVW)/Determinant;
	  os << "Best fitting plane is w = " << a << " * u + "
	     << b << " * v" << endl;
	  Double FittedWW =
	    sumWW  + square(a) * sumUU + square(b) * sumVV +
	    + 2.0 * a * b * sumUV - 2.0 * (a * sumUW + b * sumVW);
	  rmsFittedW  = sqrt(FittedWW/sumWt);
	  os << "Dispersion in fitted w = " << rmsFittedW
	     << " wavelengths" << endl;
	  facets = Int (pixels * (abs(cell.get("rad").getValue())*
				  sqrt(C::pi*rmsFittedW/(sqrt(32.0*amplitudeLoss)))));
          if (facets<1) facets = 1;
	}
	else {
	  os << "Error in fitting plane to uvw data" << LogIO::POST;
	}
	if(worstCaseFacets<1) worstCaseFacets=1;
	if(worstCaseFacets>1) {
	  os << "qimager recommends that you use the wide field clean" << endl
	     << "For accurate positions, use " << worstCaseFacets
	     << " facets on each axis" << endl
	     << "For accurate removal of sources, you only need "
	     << facets << " facets on each axis" << LogIO::POST;
	}
	else {
	  os << "Wide field cleaning is not necessary"
	     << LogIO::POST;
	}
      }

    MSColumns msc(*mssel_p);
    if(datafieldids_p.shape()!=0){
      //If setdata has been used prior to this
    phaseCenter=msc.field().phaseDirMeas(datafieldids_p(0));
    }
    else{
    phaseCenter=msc.field().phaseDirMeas(fieldid_p);   
    }

    
    // Now we have set the image parameters
    if(takeAdvice) {
      os << "Using advised image properties" << LogIO::POST;
      mcellx_p=cell;
      mcelly_p=cell;
      phaseCenter_p=phaseCenter;
      setimaged_p=True;
      beamValid_p=False;
      facets_p=facets;
      nx_p=ny_p=pixels;
    }
    
    itsQimager->unlock();
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    itsQimager->unlock();
    return False;
  } 
  
  return True;
}
Bool qimager::setdata(const String& mode, const Vector<Int>& nchan,
		     const Vector<Int>& start, const Vector<Int>& step,
		     const MRadialVelocity& mStart,
		     const MRadialVelocity& mStep,
		     const Vector<Int>& spectralwindowids,
		     const Vector<Int>& fieldids,
		     const String& msSelect)
  
{

  
  LogIO os(LogOrigin("qimager", "setdata()", WHERE));

  if(!ms_p) {
    os << LogIO::SEVERE << "Program logic error: MeasurementSet pointer ms_p not yet set"
       << LogIO::POST;
    return False;
  }

  try {
    
    os << "Selecting data" << LogIO::POST;
    
    itsQimager->lock();
    nullSelect_p=False;
    dataMode_p=mode;
    dataNchan_p=nchan;
    dataStart_p=start;
    dataStep_p=step;
    mDataStart_p=mStart;
    mDataStep_p=mStep;
    dataspectralwindowids_p.resize(spectralwindowids.nelements());
    dataspectralwindowids_p=spectralwindowids;
    datafieldids_p.resize(fieldids.nelements());
    datafieldids_p=fieldids;
    
   // Map the selected spectral window ids to data description ids
    MSDataDescColumns dataDescCol(ms_p->dataDescription());
    Vector<Int> ddSpwIds=dataDescCol.spectralWindowId().getColumn();

    datadescids_p.resize(0);
    for (uInt row=0; row<ddSpwIds.nelements(); row++) {
      Bool found=False;
      for (uInt j=0; j<dataspectralwindowids_p.nelements(); j++) {
	if (ddSpwIds(row)==dataspectralwindowids_p(j)) found=True;
      };
      if (found) {
	datadescids_p.resize(datadescids_p.nelements()+1,True);
	datadescids_p(datadescids_p.nelements()-1)=row;
      };
    };

    // If a selection has been made then close the current MS
    // and attach to a new selected MS. We do this on the original
    // MS. 
    if(datafieldids_p.nelements()>0||datadescids_p.nelements()>0) {
      os << "Performing selection on MeasurementSet" << LogIO::POST;
      if(vs_p) delete vs_p; vs_p=0;
      if(mssel_p) delete mssel_p; mssel_p=0;
      
      // check that sorted table exists (it should), if not, make it now.
      if (!ms_p->keywordSet().isDefined("SORTED_TABLE")) {
	Block<int> sort(4);
	sort[0] = MS::FIELD_ID;
	sort[1] = MS::ARRAY_ID;
	sort[2] = MS::DATA_DESC_ID;
	sort[3] = MS::TIME;
	Matrix<Int> noselection;
	VisSet vs(*ms_p,sort,noselection);
      }
      Table sorted=ms_p->keywordSet().asTable("SORTED_TABLE");
      
      
      // Now we make a condition to do the old FIELD_ID, SPECTRAL_WINDOW_ID
      // selection
      TableExprNode condition;
      String colf=MS::columnName(MS::FIELD_ID);
      String cols=MS::columnName(MS::DATA_DESC_ID);
      if(datafieldids_p.nelements()>0&&datadescids_p.nelements()>0){
	condition=sorted.col(colf).in(datafieldids_p)&&
	  sorted.col(cols).in(datadescids_p);
        os << "Selecting on field and spectral window ids" << LogIO::POST;
      }
      else if(datadescids_p.nelements()>0) {
	condition=sorted.col(cols).in(datadescids_p);
        os << "Selecting on spectral window id" << LogIO::POST;
      }
      else if(datafieldids_p.nelements()>0) {
	condition=sorted.col(colf).in(datafieldids_p);
        os << "Selecting on field id" << LogIO::POST;
      }
      
      // Now remake the selected ms
      mssel_p = new MeasurementSet(sorted(condition));

      AlwaysAssert(mssel_p, AipsError);
      mssel_p->rename(msname_p+"/SELECTED_TABLE", Table::Scratch);
      if(mssel_p->nrow()==0) {
	delete mssel_p; mssel_p=0;
	os << LogIO::WARN
	   << "Selection is empty: reverting to sorted MeasurementSet"
	   << LogIO::POST;
	mssel_p=new MeasurementSet(sorted);
	nullSelect_p=True;
      }
      else {
	mssel_p->flush();
	nullSelect_p=False;
      }
      if (nullSelect_p) {
	Table mytab(msname_p+"/FIELD", Table::Old);
	if (mytab.nrow() > 1) {
	   multiFields_p = True;
	} else {
	   multiFields_p = False;
	}
      }

      Int len = msSelect.length();
      Int nspace = msSelect.freq (' ');
      Bool nullSelect=(msSelect.empty() || nspace==len);
      if (!nullSelect) {
	MeasurementSet* mssel_p2;
	// Apply the TAQL selection string, to remake the selected MS
	String parseString="select from $1 where " + msSelect;
	mssel_p2=new MeasurementSet(tableCommand(parseString,*mssel_p));
	AlwaysAssert(mssel_p2, AipsError);
	// Rename the selected MS as */SELECTED_TABLE2
	mssel_p2->rename(msname_p+"/SELECTED_TABLE2", Table::Scratch); 
	if (mssel_p2->nrow()==0) {
	  os << LogIO::WARN
	     << "Selection string results in empty MS: "
	     << "reverting to sorted MeasurementSet"
	     << LogIO::POST;
	  delete mssel_p2;
	} else {
	  if (mssel_p) {
	    delete mssel_p; 
	    mssel_p=mssel_p2;
	    mssel_p->flush();
	  }
	}
      } else {
	os << "No selection string given" << LogIO::POST;
      }

      if(mssel_p->nrow()!=ms_p->nrow()) {
	os << "By selection " << ms_p->nrow() << " rows are reduced to "
	   << mssel_p->nrow() << LogIO::POST;
      }
      else {
	os << "Selection did not drop any rows" << LogIO::POST;
      }
    }
    
    // Now create the VisSet
    if(vs_p) delete vs_p; vs_p=0;
    Block<int> sort(4);
    sort[0] = MS::FIELD_ID;
    sort[1] = MS::ARRAY_ID;
    sort[2] = MS::DATA_DESC_ID;
    sort[3] = MS::TIME;
    Matrix<Int> noselection;
    vs_p = new VisSet(*mssel_p,sort,noselection);
    AlwaysAssert(vs_p, AipsError);
    
    // Now we do a selection to cut down the amount of information
    // passed around.

    itsQimager->selectDataChannel(*vs_p, dataspectralwindowids_p, dataMode_p,
				 dataNchan_p, dataStart_p, dataStep_p,
				 mDataStart_p, mDataStep_p);

    // Guess that the beam is no longer valid
    beamValid_p=False;
    destroySkyEquation();
    if(!valid()){ 
      os << LogIO::SEVERE << "Check your data selection or Measurement set " << LogIO::POST;
      return False;
    }
    itsQimager->unlock();
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    itsQimager->unlock();
    return False;
  } 
  return True;
}


Bool qimager::setmfcontrol(const Float cyclefactor,
			   const Float cyclespeedup,
			   const Int stoplargenegatives,
			   const Int stoppointmode)
{  
  cyclefactor_p = cyclefactor;
  cyclespeedup_p =  cyclespeedup;
  stoplargenegatives_p = stoplargenegatives;
  stoppointmode_p = stoppointmode;
  return True;
}  


Bool qimager::setvp(const Bool dovp,
		   const Bool doDefaultVPs,
		   const String& vpTable,
		   const Bool doSquint,
		   const Quantity &parAngleInc)
{

  if(!valid())
    {

      return False;
    }
  LogIO os(LogOrigin("qimager", "setvp()", WHERE));
  
  os << "Setting voltage pattern parameters" << LogIO::POST;
  
  doVP_p=dovp;
  doDefaultVP_p = doDefaultVPs;
  vpTableStr_p = vpTable;
  if (doSquint) {
    squintType_p = BeamSquint::GOFIGURE;
  } else {
    squintType_p = BeamSquint::NONE;
  }

  parAngleInc_p = parAngleInc;

  if (doDefaultVP_p) {
    os << "Using system default voltage patterns for each telescope"
       << LogIO::POST;
  } else {
    os << "Using user defined voltage patterns in Table "
       <<  vpTableStr_p << LogIO::POST;
  }
  if (doSquint) {
    os << "Beam Squint will be included in the VP model" <<  LogIO::POST;
    os << "and the Parallactic Angle increment is " 
       << parAngleInc_p.getValue("deg") << " degrees"  << LogIO::POST;
  }
  return True;

}

Bool qimager::setoptions(const String& ftmachine, const Int cache,
			 const Int tile,
			 const String& gridfunction,
			 const Float padding)
{

  if(!valid()) 
    {

      return False;
    }
  if(!assertDefinedImageParameters())
    {

      return False;
    }
  LogIO os(LogOrigin("qimager", "setoptions()", WHERE));
  
  os << "Setting processing options" << LogIO::POST;
  
  ftmachine_p=downcase(ftmachine);
  if(ftmachine_p=="gridft") {
    os << "FT machine gridft is now called ft - please use the new name in future" << endl;
    ftmachine_p="ft";
  }
  else if(ftmachine_p=="wfmemoryft"){
    wfGridding_p=True;
    ftmachine_p="ft";
  }
  else if(ftmachine_p=="wproject"){
    wfGridding_p=True;
    ftmachine_p="ft";
  }
  else if(ftmachine_p=="mosaic"){
    wfGridding_p=False;
  }
  else if(ftmachine_p=="sd"){
    wfGridding_p=False;
  }
  else {
    os << "Unknown ftmachine " << ftmachine_p << LogIO::WARN;
    return False;
  }

  if(cache>0) cache_p=cache;
  if(tile>0) tile_p=tile;
  gridfunction_p=gridfunction;
  if(padding>=1.0) {
    padding_p=padding;
  }
  // Destroy the FTMachine
  if(ft_p) {delete ft_p; ft_p=0;}
  if(gvp_p) {delete gvp_p; gvp_p=0;}
  if(cft_p) {delete cft_p; cft_p=0;}

  return True;
}

Bool qimager::setsdoptions(const Float scale, const Float weight)
{


  if(!valid()) 
    {

      return False;
    }

  LogIO os(LogOrigin("qimager", "setsdoptions()", WHERE));
  
  os << "Setting single dish processing options" << LogIO::POST;
  
  sdScale_p=scale;
  sdWeight_p=weight;

  // Destroy the FTMachine
  if(ft_p) {delete ft_p; ft_p=0;}
  if(gvp_p) {delete gvp_p; gvp_p=0;}
  if(cft_p) {delete cft_p; cft_p=0;}

  return True;
}

// Add together low and high resolution images in the Fourier plane
Bool qimager::feather(const String& image, const String& highRes,
		     const String& lowRes, const String& lowPSF)
{
  if(!valid()) return False;
  
  LogIO os(LogOrigin("qimager", "feather()", WHERE));
  
  try {
    
    if ( ! doVP_p ) {
      os << LogIO::SEVERE << 
	"Must invoke setvp() first in order to apply the primary beam" << LogIO::POST;
      return False;
    }

    os << "Feathering together high and low resolution images" << LogIO::POST;
    
    // Get initial images
    PagedImage<Float> high(highRes);
    PagedImage<Float> low0(lowRes);

    Vector<Quantum<Double> > hBeam, lBeam;
    ImageInfo highInfo=high.imageInfo();
    hBeam=highInfo.restoringBeam();
    ImageInfo lowInfo=low0.imageInfo();
    lBeam=lowInfo.restoringBeam();
    if((hBeam.nelements()<3)||!((hBeam(0).get("arcsec").getValue()>0.0)&&(hBeam(1).get("arcsec").getValue()>0.0))) {
      os << LogIO::WARN << "High resolution image does not have any resolution information - will be unable to scale correctly" << LogIO::POST;
    }

    PBMath * myPBp = 0;
    if(lowPSF=="") {
      // create the low res's PBMath object, needed to apply PB 
      // to make high res Fourier weight image
      if (doDefaultVP_p) {
	// look up the telescope in ObsInfo
	ObsInfo oi = low0.coordinates().obsInfo();
	String myTelescope = oi.telescope();
	if (myTelescope == "") {
	  os << LogIO::SEVERE << "No telescope imbedded in low res image" << LogIO::POST;
	  os << LogIO::SEVERE << "Create a PB description with the vpmanager" << LogIO::POST;
	  return False;
	}
	Quantity qFreq;
	{
	  Int spectralIndex=low0.coordinates().findCoordinate(Coordinate::SPECTRAL);
	  AlwaysAssert(spectralIndex>=0, AipsError);
	  SpectralCoordinate
	    spectralCoord=low0.coordinates().spectralCoordinate(spectralIndex);
	  Vector<String> units(1); units = "Hz";
	  spectralCoord.setWorldAxisUnits(units);	
	  Vector<Double> spectralWorld(1);
	  Vector<Double> spectralPixel(1);
	  spectralPixel(0) = 0;
	  spectralCoord.toWorld(spectralWorld, spectralPixel);  
	  Double freq  = spectralWorld(0);
	  qFreq = Quantity( freq, "Hz" );
	}
	String band;
	PBMath::CommonPB whichPB;
	String pbName;
	// get freq from coordinates
	PBMath::whichCommonPBtoUse (myTelescope, qFreq, band, whichPB, pbName);
	if (whichPB  == PBMath::UNKNOWN) {
	  os << LogIO::SEVERE << "Unknown telescope for PB type: " << myTelescope << LogIO::POST;
	  return False;
	}
	myPBp = new PBMath(whichPB);
      } else {
	// get the PB from the vpTable
	Table vpTable( vpTableStr_p );
	ROScalarColumn<TableRecord> recCol(vpTable, (String)"pbdescription");
	myPBp = new PBMath(recCol(0));
      }
      AlwaysAssert((myPBp != 0), AipsError);
    }

    // regrid the single dish image
    TempImage<Float> low(high.shape(), high.coordinates());
    {
      ImageRegrid<Float> ir;
      IPosition axes(3,0,1,3);   // if its a cube, regrid the spectral too
      ir.regrid(low, Interpolate2D::LINEAR, axes, low0);
    }
    
    // get image center direction (needed for SD PB, which is needed for
    // the high res Fourier weight image
    MDirection wcenter;  
    {
      Int directionIndex=high.coordinates().findCoordinate(Coordinate::DIRECTION);
      AlwaysAssert(directionIndex>=0, AipsError);
      DirectionCoordinate
	directionCoord=high.coordinates().directionCoordinate(directionIndex);
      Vector<Double> pcenter(2);
      pcenter(0) = high.shape()(0)/2;
      pcenter(1) = high.shape()(1)/2;    
      directionCoord.toWorld( wcenter, pcenter );
    }

    // make the weight image for high res Fourier plane:  1 - normalized(FT(sd_PB))
    TempImage<Complex> cweight(high.shape(), high.coordinates());
    if(lowPSF=="") {
      os << "Using primary beam to determine weighting" << LogIO::POST;
      cweight.set(1.0);
      if (myPBp != 0) {
	myPBp->applyPB(cweight, cweight, wcenter, Quantity(0.0, "deg"), BeamSquint::NONE);
	delete myPBp;
      }
    }
    else {
      os << "Using specified low resolution PSF to determine weighting" << LogIO::POST;
      // regrid the single dish psf
      PagedImage<Float> lowpsf0(lowPSF);
      TempImage<Float> lowpsf(high.shape(), high.coordinates());
      {
	ImageRegrid<Float> ir;
	IPosition axes(3,0,1,3);   // if its a cube, regrid the spectral too
	ir.regrid(lowpsf, Interpolate2D::LINEAR, axes, lowpsf0);
      }
      if((lBeam.nelements()>0)&&(lBeam(0).get("arcsec").getValue()==0.0)) {
	os << "Determining scaling from low resolution PSF" << LogIO::POST;
	lBeam.resize(3);
	StokesImageUtil::FitGaussianPSF(lowpsf0, lBeam(0), lBeam(1), lBeam(2));
      }
      StokesImageUtil::From(cweight, lowpsf);
    }
    LatticeFFT::cfft2d( cweight );
    LatticeExprNode node = max( cweight );
    Float fmax = abs(node.getComplex());
    cweight.copyData(  (LatticeExpr<Complex>)( 1.0f - cweight/fmax ) );

    // FT high res image
    TempImage<Complex> cimagehigh(high.shape(), high.coordinates() );
    StokesImageUtil::From(cimagehigh, high);
    LatticeFFT::cfft2d( cimagehigh );
    
    // FT low res image
    TempImage<Complex> cimagelow(high.shape(), high.coordinates() );
    StokesImageUtil::From(cimagelow, low);
    LatticeFFT::cfft2d( cimagelow );

    // This factor comes from the beam volumes
    if(sdScale_p!=1.0) os << "Multiplying single dish data by user specified factor " << sdScale_p << LogIO::POST;
    Float sdScaling  = sdScale_p;
    if((hBeam(0).get("arcsec").getValue()>0.0)&&(hBeam(1).get("arcsec").getValue()>0.0)&&
       (lBeam(0).get("arcsec").getValue()>0.0)&&(lBeam(1).get("arcsec").getValue()>0.0)) {
      Float beamFactor=
	hBeam(0).get("arcsec").getValue()*hBeam(1).get("arcsec").getValue()/
	(lBeam(0).get("arcsec").getValue()*lBeam(1).get("arcsec").getValue());
      os << "Applying additional scaling for ratio of the volumes of the high to the low resolution images : "
	 <<  beamFactor << LogIO::POST;
      sdScaling*=beamFactor;
    }
    else {
      os << LogIO::WARN << "Insufficient information to scale correctly" << LogIO::POST;
    }

    // combine high and low res, appropriately normalized, in Fourier plane. The vital point to
    // remember is that cimagelow is already multiplied by 1-cweight so we only need adjust for
    // the ratio of beam volumes
    cimagehigh.copyData(  (LatticeExpr<Complex>)((cimagehigh * cweight + cimagelow * sdScaling)));
    
    // FT back to image plane
    LatticeFFT::cfft2d( cimagehigh, False);
    
    // write to output image
    PagedImage<Float> featherImage(high.shape(), high.coordinates(), image );
    StokesImageUtil::To(featherImage, cimagehigh);
    
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    return False;
  } 
  
  return True;
}




// Apply a primary beam or voltage pattern to an image
Bool qimager::pb(const String& inimage, 
		const String& outimage,
		const String& incomps,
		const String& outcomps,
		const String& operation, 
		const MDirection& pointingCenter,
		const Quantity& pa,
		const String& pborvp)

{
  if(!valid()) return False;
  
  LogIO os(LogOrigin("qimager", "pb()", WHERE));
  
  PagedImage<Float> * inImage_pointer = 0;
  PagedImage<Float> * outImage_pointer = 0;
  ComponentList * inComps_pointer = 0;
  ComponentList * outComps_pointer = 0;
  PBMath * myPBp = 0;
  try {

    if ( ! doVP_p ) {
      os << LogIO::SEVERE << 
	"Must invoke setvp() first in order to apply the primary beam" << LogIO::POST;
      return False;
    }
    
    if (pborvp == "vp") {
      os << LogIO::SEVERE << "VP application is not yet implemented in DOqqimager" << LogIO::POST;
      return False;
    }

    if (operation == "apply") {
      os << "function pb will apply " << pborvp << LogIO::POST;
    } else if (operation=="correct") {
      os << "function pb will correct for " << pborvp << LogIO::POST;
    } else {
      os << LogIO::SEVERE << "Unknown pb operation " << operation << LogIO::POST;
      return False;
    }
    
    // Get initial image and/or SkyComponents

    if (incomps!="") {
      if(!Table::isReadable(incomps)) {
	os << LogIO::SEVERE << "ComponentList " << incomps
	   << " not readable" << LogIO::POST;
	return False;
      }
      inComps_pointer = new ComponentList(incomps);
      outComps_pointer = new ComponentList( inComps_pointer->copy() );
    }
    if (inimage !="") {
      if(!Table::isReadable(inimage)) {
	os << LogIO::SEVERE << "Image " << inimage << " not readable" << LogIO::POST;
	return False;
      }
      inImage_pointer = new PagedImage<Float>( inimage );
      if (outimage != "") {
	outImage_pointer = new PagedImage<Float>( inImage_pointer->shape(), 
						  inImage_pointer->coordinates(), outimage);
      }
    }
    // create the PBMath object, needed to apply PB 
    // to make high res Fourier weight image
    Quantity qFreq;
    if (doDefaultVP_p && inImage_pointer==0) {
	os << LogIO::SEVERE << 
	  "There is no default telescope associated with a componentlist" << LogIO::POST;
	os << LogIO::SEVERE << 
	  "Either specify the PB/VP via a vptable or supply an image as well" << LogIO::POST;
	return False;
    } else if (doDefaultVP_p && inImage_pointer!=0) {
      // look up the telescope in ObsInfo
      ObsInfo oi = inImage_pointer->coordinates().obsInfo();
      String myTelescope = oi.telescope();
      if (myTelescope == "") {
	os << LogIO::SEVERE << "No telescope imbedded in image" << LogIO::POST;
	return False;
      }
      {
	Int spectralIndex=inImage_pointer->coordinates().findCoordinate(Coordinate::SPECTRAL);
	AlwaysAssert(spectralIndex>=0, AipsError);
	SpectralCoordinate
	  spectralCoord=inImage_pointer->coordinates().spectralCoordinate(spectralIndex);
	Vector<String> units(1); units = "Hz";
	spectralCoord.setWorldAxisUnits(units);	
	Vector<Double> spectralWorld(1);
	Vector<Double> spectralPixel(1);
	spectralPixel(0) = 0;
	spectralCoord.toWorld(spectralWorld, spectralPixel);  
	Double freq  = spectralWorld(0);
	qFreq = Quantity( freq, "Hz" );
      }
      String band;
      PBMath::CommonPB whichPB;
      String pbName;
      // get freq from coordinates
      PBMath::whichCommonPBtoUse (myTelescope, qFreq, band, whichPB, pbName);
      if (whichPB  == PBMath::UNKNOWN) {
	os << LogIO::SEVERE << "Unknown telescope for PB type: " << myTelescope << LogIO::POST;
	return False;
      }
      myPBp = new PBMath(whichPB);
    } else {
      // get the PB from the vpTable
      Table vpTable( vpTableStr_p );
      ROScalarColumn<TableRecord> recCol(vpTable, (String)"pbdescription");
      myPBp = new PBMath(recCol(0));
    }
    AlwaysAssert((myPBp != 0), AipsError);


    // Do images (if indeed we have any)
    if (outImage_pointer!=0) {
      Vector<Int> whichStokes;
      CoordinateSystem cCoords;
      cCoords=StokesImageUtil::CStokesCoord(inImage_pointer->shape(),
					    inImage_pointer->coordinates(),
					    whichStokes,
					    polRep_p);
      TempImage<Complex> cIn(inImage_pointer->shape(),
			     cCoords);
      StokesImageUtil::From(cIn, *inImage_pointer);
      if (operation=="apply") {
	myPBp->applyPB(cIn, cIn, pointingCenter, 
		       pa, squintType_p, False);
      } else {
	myPBp->applyPB(cIn, cIn, pointingCenter, 
		       pa, squintType_p, True);
      }
      StokesImageUtil::To(*outImage_pointer, cIn);
    }
    // Do components (if indeed we have any)
    if (inComps_pointer!=0) {
      if (inImage_pointer==0) {
	os << LogIO::SEVERE << 
	  "No input image was given for the componentList to get the frequency from" 
	   << LogIO::POST;
	return False;
      }
      Int ncomponents = inComps_pointer->nelements();
      for (Int icomp=0;icomp<ncomponents;icomp++) {
	SkyComponent component=outComps_pointer->component(icomp);
	if (operation=="apply") {
	  myPBp->applyPB(component, component, pointingCenter, 
			 qFreq, pa, squintType_p, False);
	} else {
	  myPBp->applyPB(component, component, pointingCenter, 
			 qFreq, pa, squintType_p, True);
	}
      }
    }
    if (myPBp) delete myPBp;
    if (inImage_pointer) delete inImage_pointer;
    if (outImage_pointer) delete outImage_pointer; 
    if (inComps_pointer) delete inComps_pointer; 
    if (outComps_pointer) delete outComps_pointer; 
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    if (myPBp) delete myPBp;
    if (inImage_pointer) delete inImage_pointer;
    if (outImage_pointer) delete outImage_pointer; 
    if (inComps_pointer) delete inComps_pointer; 
    if (outComps_pointer) delete outComps_pointer; 
    return False;
  }
  return True;
}



Bool qimager::linearmosaic(const String& mosaic,
			  const String& fluxscale,
			  const String& sensitivity,
			  const Vector<String>& images,
			  const Vector<Int>& fieldids)

{
  if(!valid()) return False;
  LogIO os(LogOrigin("qimager", "linearmosaic()", WHERE));
  if(mosaic=="") {
    os << LogIO::SEVERE << "Need name for mosaic image" << LogIO::POST;
    return False;
  }
  if(!Table::isWritable( mosaic )) {
    make( mosaic );
  }
  if (images.nelements() == 0) {
    os << LogIO::SEVERE << "Need names of images to mosaic" << LogIO::POST;
    return False;
  }
  if (images.nelements() != fieldids.nelements()) {
    os << LogIO::SEVERE << "number of fieldids doesn\'t match the" 
       << " number of images" << LogIO::POST;
    return False;
  }

  PagedImage<Float> mosaicImage( mosaic );
  mosaicImage.set(0.0);
  TempImage<Float>  numerator( mosaicImage.shape(), mosaicImage.coordinates() );
  numerator.set(0.0);
  TempImage<Float>  denominator( mosaicImage.shape(), mosaicImage.coordinates() );
  numerator.set(0.0);

  ImageRegrid<Float> regridder;
  MSColumns msc(*ms_p);
  for (uInt i=0; i < images.nelements(); i++) {
    if(!Table::isReadable(images(i))) {   
      os << LogIO::SEVERE << "Image " << images(i) << 
	" is not readable" << LogIO::POST;
      return False;
    }
    PagedImage<Float> smallImage( images(i) );
    TempImage<Float> fullImage(  mosaicImage.shape(), mosaicImage.coordinates() );

    // Need a provision for "same size exactly";  for now, insert will cover it

    /*
    Bool congruent = Coordinates::isCongruent(fullImage.coordinates(), smallImage.coordinates());
    if (congruent) {
      regridder.insert( fullImage, refShift, smallImage );
    } else {
      regridder.regrid( fullImage, Interpolate2D::CUBIC,
			IPosition(2,0,1), smallImage );
    }
    */
    regridder.regrid( fullImage, Interpolate2D::CUBIC,
		      IPosition(2,0,1), smallImage );

    TempImage<Float>  imageTimesPB( fullImage.shape(), fullImage.coordinates());
    imageTimesPB.set(0.0);
    TempImage<Float>  PB( fullImage.shape(), fullImage.coordinates());
    PB.set(1.0);

    MDirection pointingDirection = msc.field().phaseDirMeas( fieldids(i)-1 );

    Quantity pa(0.0, "deg");
    pbguts ( PB, PB, pointingDirection, pa);

    imageTimesPB.copyData( (LatticeExpr<Float>) (fullImage *  PB ) );

    // accumulate the images
    
    numerator.copyData( (LatticeExpr<Float>) (numerator + imageTimesPB) );
    denominator.copyData( (LatticeExpr<Float>) (denominator + pow(PB, 2)) );
  }
    
  LatticeExprNode LEN = max( denominator );
  Float dMax =  LEN.getFloat();

  if (scaleType_p == "SAULT") {

    // truncate denominator at ggSMin1
    denominator.copyData( (LatticeExpr<Float>) 
			  (iif(denominator < (dMax * constPB_p), dMax, 
			       denominator) ) );

    if (fluxscale != "") {
      if(!Table::isWritable( fluxscale )) {
	make( fluxscale );
      }
      PagedImage<Float> fluxscaleImage( fluxscale );
      fluxscaleImage.copyData( (LatticeExpr<Float>) 
			       (iif(denominator < (dMax*minPB_p), 0.0,
				    (dMax*minPB_p)/(denominator) )) );
      fluxscaleImage.copyData( (LatticeExpr<Float>) 
			       (iif(denominator > (dMax*constPB_p), 1.0,
				    (fluxscaleImage) )) );
    }
  } else {
    mosaicImage.copyData( (LatticeExpr<Float>)(iif(denominator > (dMax*minPB_p),
						   (numerator/denominator), 0)) );
    if (fluxscale != "") {
      if(!Table::isWritable( fluxscale )) {
	make( fluxscale );
      }
      PagedImage<Float> fluxscaleImage( fluxscale );
      fluxscaleImage.copyData( (LatticeExpr<Float>)( 1.0 ) );
    }
  }
  
  return True;
}



// Apply a primary beam or voltage pattern to an image
Bool qimager::pbguts(ImageInterface<Float>& inImage, 
		    ImageInterface<Float>& outImage,
		    const MDirection& pointingDirection,
		    const Quantity& pa)
{
  if(!valid()) return False;
  
  LogIO os(LogOrigin("qimager", "pbguts()", WHERE));
  
  try {
    if ( ! doVP_p ) {
      os << LogIO::SEVERE << 
	"Must invoke setvp() first in order to apply the primary beam" << LogIO::POST;
      return False;
    }
    String operation = "apply";  // could have as input in the future!

    // create the PBMath object, needed to apply PB 
    // to make high res Fourier weight image
    Quantity qFreq;
    PBMath * myPBp = 0;

    if (doDefaultVP_p) {
      // look up the telescope in ObsInfo
      ObsInfo oi = inImage.coordinates().obsInfo();
      String myTelescope = oi.telescope();
      if (myTelescope == "") {
	os << LogIO::SEVERE << "No telescope imbedded in image" << LogIO::POST;
	return False;
      }
      {
	Int spectralIndex=inImage.coordinates().findCoordinate(Coordinate::SPECTRAL);
	AlwaysAssert(spectralIndex>=0, AipsError);
	SpectralCoordinate
	  spectralCoord=inImage.coordinates().spectralCoordinate(spectralIndex);
	Vector<String> units(1); units = "Hz";
	spectralCoord.setWorldAxisUnits(units);	
	Vector<Double> spectralWorld(1);
	Vector<Double> spectralPixel(1);
	spectralPixel(0) = 0;
	spectralCoord.toWorld(spectralWorld, spectralPixel);  
	Double freq  = spectralWorld(0);
	qFreq = Quantity( freq, "Hz" );
      }
      String band;
      PBMath::CommonPB whichPB;
      String pbName;
      // get freq from coordinates
      PBMath::whichCommonPBtoUse (myTelescope, qFreq, band, whichPB, pbName);
      if (whichPB  == PBMath::UNKNOWN) {
	os << LogIO::SEVERE << "Unknown telescope for PB type: " << myTelescope << LogIO::POST;
	return False;
      }
      myPBp = new PBMath(whichPB);
    } else {
      // get the PB from the vpTable
      Table vpTable( vpTableStr_p );
      ROScalarColumn<TableRecord> recCol(vpTable, (String)"pbdescription");
      myPBp = new PBMath(recCol(0));
    }
    AlwaysAssert((myPBp != 0), AipsError);

    Vector<Int> whichStokes;
    CoordinateSystem cCoords;
    cCoords=StokesImageUtil::CStokesCoord(inImage.shape(),
					  inImage.coordinates(),
					  whichStokes,
					  polRep_p);
    TempImage<Complex> cIn(inImage.shape(),
			   cCoords);
    StokesImageUtil::From(cIn, inImage);
    if (operation=="apply") {
      myPBp->applyPB(cIn, cIn, pointingDirection, 
		     pa, squintType_p, False);
    } else {
      myPBp->applyPB(cIn, cIn, pointingDirection, 
		     pa, squintType_p, True);
    }
    StokesImageUtil::To(outImage, cIn);
    delete myPBp;    
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    return False;
  } 
  
  return True;
}







// Weight the MeasurementSet
Bool qimager::weight(const String& type, const String& rmode,
                 const Quantity& noise, const Double robust,
                 const Quantity& fieldofview,
                 const Int npixels)
{
  if(!valid()) return False;
  
  LogIO os(LogOrigin("qimager", "weight()", WHERE));
  
  itsQimager->lock();
  try {
    
    os << "Weighting MS: IMAGING_WEIGHT column will be changed" << LogIO::POST;
    
    Double sumwt=0.0;
    
    if (type=="natural") {
      os << "Natural weighting" << LogIO::POST;
      VisSetUtil::WeightNatural(*vs_p, sumwt);
    }
    else if ((type=="robust")||(type=="uniform")||(type=="briggs")) {
      if(!assertDefinedImageParameters()) return False;
      Quantity actualFieldOfView(fieldofview);
      Int actualNPixels(npixels);
      String wtype;
      if(type=="briggs") {
        wtype = "Briggs";
      }
      else {
        wtype = "Uniform";
      }
      if(actualFieldOfView.get().getValue()==0.0&&actualNPixels==0) {
        actualNPixels=nx_p;
        actualFieldOfView=Quantity(actualNPixels*mcellx_p.get("rad").getValue(), "rad");
        os << wtype << " weighting: sidelobes will be suppressed over full image" << endl;
      }
      else if(actualFieldOfView.get().getValue()>0.0&&actualNPixels==0) {
        actualNPixels=nx_p;
        os << wtype << " weighting: sidelobes will be suppressed over specified field of view: "
           << actualFieldOfView.get("arcsec").getValue() << " arcsec" << endl;
      }
      else if(actualFieldOfView.get().getValue()==0.0&&actualNPixels>0) {
        actualFieldOfView=Quantity(actualNPixels*mcellx_p.get("rad").getValue(), "rad");
        os << wtype << " weighting: sidelobes will be suppressed over full image field of view: "
           << actualFieldOfView.get("arcsec").getValue() << " arcsec" << endl;
      }
      else {
        os << wtype << " weighting: sidelobes will be suppressed over specified field of view: "
           << actualFieldOfView.get("arcsec").getValue() << " arcsec" << endl;
      }
      os << "                 : using " << actualNPixels << " pixels in the uv plane"
         << LogIO::POST;
      Quantity actualCellSize(actualFieldOfView.get("rad").getValue()/actualNPixels, "rad");
      
      VisSetUtil::WeightUniform(*vs_p, rmode, noise, robust, actualNPixels,
                                actualNPixels,
                                actualCellSize, actualCellSize, sumwt);
    }
    else if (type=="radial") {
      os << "Radial weighting" << LogIO::POST;
      VisSetUtil::WeightRadial(*vs_p, sumwt);
    }
    else {
      os << LogIO::SEVERE << "Unknown weighting " << type
         << LogIO::POST;    
      itsQimager->unlock();
      return False;
    }
    
    if(sumwt>0.0) {
      os << "Sum of weights = " << sumwt << LogIO::POST;
    }
    else {
      os << LogIO::SEVERE << "Sum of weights is not positive" << LogIO::POST;
      itsQimager->unlock();
      return False;
    }
    
    // Beam is no longer valid
    beamValid_p=False;
    destroySkyEquation();
    itsQimager->unlock();
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    itsQimager->unlock();
    return False;
  } 
  
  return True;
}




// Filter the MeasurementSet
Bool qimager::filter(const String& type, const Quantity& bmaj,
		 const Quantity& bmin, const Quantity& bpa)
{
  if(!valid()) return False;
  
  LogIO os(LogOrigin("qimager", "filter()", WHERE));
  
  itsQimager->lock();
  try {
    
    os << "Filtering MS: IMAGING_WEIGHT column will be changed" << LogIO::POST;
    
    Double sumwt=0.0;
    Double maxfilter=0.0;
    Double minfilter=1.0;
    
    VisSetUtil::Filter(*vs_p, type, bmaj, bmin, bpa, sumwt, minfilter,
		       maxfilter);
    
    if(sumwt>0.0) {
      os << "Sum of weights = " << sumwt << endl;
      os << "Max, min taper = " << maxfilter << ", " << minfilter << LogIO::POST;
    }
    else {
      os << LogIO::SEVERE
	 << "Sum of weights is zero: perhaps you need to weight the data"
	 << LogIO::POST;
    }
    
    // Beam is no longer valid
    beamValid_p=False;
    destroySkyEquation();
    itsQimager->unlock();
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    itsQimager->unlock();
    return False;
  } 
  
  return True;
}


// Implement a uv range
Bool qimager::uvrange(const Double& uvmin, const Double& uvmax)
{
  if(!valid()) return False;
  LogIO os(LogOrigin("qimager", "uvrange()", WHERE));
  
  try {
    
      os << "Selecting data according to  uvrange: setdata will reset this selection" << LogIO::POST;

    Double auvmin(uvmin);
    Double auvmax(uvmax);

    if(auvmax<=0.0) auvmax=1e10;
    if(auvmax>auvmin&&(auvmin>=0.0)) {
      os << "Allowed uv range: " << auvmin << " to " << auvmax
	 << " wavelengths" << LogIO::POST;
    }
    else {
      os << LogIO::SEVERE << "Invalid uvmin and uvmax: "
	 << auvmin << ", " << auvmax
	 << LogIO::POST;
      return False;
    }
    Vector<Double> freq;
    ostringstream strUVmax, strUVmin, ostrInvLambda;

    itsQimager->lock();
      
    if(!mssel_p){ os << "Please setdata first before using uvrange " << LogIO::POST; return False; }


     // use the average wavelength for the selected windows to convert
     // uv-distance from lambda to meters
     ostringstream spwsel;
     spwsel << "select from $1 where ROWID() IN [";
     for(uInt i=0; i < dataspectralwindowids_p.nelements(); i++) {
	 if (i > 0) spwsel << ", ";
	 spwsel << dataspectralwindowids_p(i);
     }
     spwsel << "]";

     MSSpectralWindow msspw(tableCommand(spwsel.str(), 
					 mssel_p->spectralWindow()));
     MSSpWindowColumns spwc(msspw);

     // This averaging scheme will work even if the spectral windows are
     // of different sizes.  Note, however, that using an average wavelength
     // may not be a good choice when the total range in frequency is 
     // large (e.g. mfs across double sidebands).
     uInt nrows = msspw.nrow();
     Double ftot = 0.0;
     Int nchan = 0;
     for(uInt i=0; i < nrows; i++) {
	 nchan += (spwc.numChan())(i);
	 ftot += sum((spwc.chanFreq())(i));
     }
     Double invLambda=ftot/(nchan*C::c);

     // This is message may not be helpful as mfs is set with setimage()
     // which may sometimes get called after uvrange()
     if (nrows > 1 && imageMode_p=="mfs") {
 	 os << LogIO::WARN 
 	    << "When using mfs over a broad range of frequencies, It is more "
 	    << "accurate to " << endl 
 	    << "constrain uv-ranges using setdata(); try: " << endl 
 	    << "  msselect='(SQUARE(UVW[1]) + SQUARE(UVW[2])) > uvmin && "
 	    << "(SQUARE(UVW[1]) + SQUARE(UVW[2])) < uvmax'" << endl
 	    << "where [uvmin, uvmax] is the range given in meters." 
 	    << LogIO::POST;
     }

     invLambda=invLambda*invLambda;
     auvmax=auvmax*auvmax;
     auvmin=auvmin*auvmin;
     strUVmax << auvmax; 
     strUVmin << auvmin;
     ostrInvLambda << invLambda; 
     String strInvLambda=ostrInvLambda;
     MeasurementSet* mssel_p2;

     // Apply the TAQL selection string, to remake the selected MS
     String parseString="select from $1 where (SQUARE(UVW[1]) + SQUARE(UVW[2]))*" + strInvLambda + " > " + strUVmin + " &&  (SQUARE(UVW[1]) + SQUARE(UVW[2]))*" + strInvLambda + " < " + strUVmax ;

     mssel_p2=new MeasurementSet(tableCommand(parseString,*mssel_p));
     AlwaysAssert(mssel_p2, AipsError);
     // Rename the selected MS as */SELECTED_UVRANGE
     mssel_p2->rename(msname_p+"/SELECTED_UVRANGE", Table::Scratch);
      
     if (mssel_p2->nrow()==0) {
	 os << LogIO::WARN
	    << "Selection string results in empty MS: "
	    << "reverting to sorted MeasurementSet"
	    << LogIO::POST;
	 delete mssel_p2;
     } else {
	 if (mssel_p) {
	     os << "By UVRANGE selection previously selected number of rows " << mssel_p->nrow() << "  are now reduced to " << mssel_p2->nrow() << LogIO::POST; 
	     delete mssel_p; 
	     mssel_p=mssel_p2;
	     mssel_p->flush();
	 }
     }
      
     if(vs_p) delete vs_p; vs_p=0;
     Block<int> sort(4);
     sort[0] = MS::FIELD_ID;
     sort[1] = MS::ARRAY_ID;
     sort[2] = MS::DATA_DESC_ID;
     sort[3] = MS::TIME;
     Matrix<Int> noselection;
     vs_p = new VisSet(*mssel_p,sort,noselection);
     AlwaysAssert(vs_p, AipsError);

     // NOW WE HAVE TO REDO THE VELOCITY INFO FOR VS_P AS IN SETDATA

     itsQimager->selectDataChannel(*vs_p, dataspectralwindowids_p, dataMode_p,
				  dataNchan_p, dataStart_p, dataStep_p,
				  mDataStart_p, mDataStep_p);

    itsQimager->unlock();
    
    // Beam is no longer valid
    beamValid_p=False;
    return True;    
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    return False;
  } 
  return True;
}

// Find the sensitivity
Bool qimager::sensitivity(Quantity& pointsourcesens, Double& relativesens,
		      Double& sumwt)
{
  if(!valid()) return False;
  LogIO os(LogOrigin("qimager", "sensitivity()", WHERE));
  
  try {
    
    os << "Calculating sensitivity from IMAGING_WEIGHT and SIGMA columns"
       << LogIO::POST;
    os << "(assuming that SIGMA column is correct, otherwise scale appropriately)" << LogIO::POST;
    
    itsQimager->lock();
    VisSetUtil::Sensitivity(*vs_p, pointsourcesens, relativesens, sumwt);
    os << "RMS Point source sensitivity  : "
       << pointsourcesens.get("Jy").getValue() << " Jy/beam"
       << LogIO::POST;
    os << "Relative to natural weighting : " << relativesens << LogIO::POST;
    os << "Sum of weights                : " << sumwt << LogIO::POST;
    itsQimager->unlock();
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    itsQimager->unlock();
    return False;
  } 
  return True;
}

Bool qimager::makeimage(const String& type, const String& image)
{
  qimager::makeimage(type, image, "");
  return True;
}

// Calculate various sorts of image. Only one image
// can be calculated at a time. The complex Image make
// be retained if a name is given. This does not use
// the SkyEquation.
Bool qimager::makeimage(const String& type, const String& image,
		   const String& compleximage)
{

  if(!valid()) 
    {

      return False;
    }
  LogIO os(LogOrigin("qimager", "makeimage()", WHERE));
  
  itsQimager->lock();
  try {
    if(!assertDefinedImageParameters())
      {

	return False;
      }
    
    os << "Calculating image (without full skyequation)" << LogIO::POST;
    
    FTMachine::Type seType(FTMachine::OBSERVED);
    Bool doSD(False);

    if(type=="observed") {
      seType=FTMachine::OBSERVED;
      os << "Making dirty image from " << type << " data "
	 << LogIO::POST;
    }
    else if (type=="model") {
      seType=FTMachine::MODEL;
      os << "Making dirty image from " << type << " data "
	 << LogIO::POST;
    }
    else if (type=="corrected") {
      seType=FTMachine::CORRECTED;
      os << "Making dirty image from " << type << " data "
	 << LogIO::POST;
    }
    else if (type=="psf") {
      seType=FTMachine::PSF;
      os << "Making point spread function "
	 << LogIO::POST;
    }
    else if (type=="residual") {
      seType=FTMachine::RESIDUAL;
      os << "Making dirty image from " << type << " data "
	 << LogIO::POST;
    }
    else if (type=="singledish-observed") {
      doSD = True;
      seType=FTMachine::OBSERVED;
      os << "Making single dish image from observed data" << LogIO::POST;
    }
    else if (type=="singledish") {
      doSD = True;
      seType=FTMachine::CORRECTED;
      os << "Making single dish image from corrected data" << LogIO::POST;
    }
    else if (type=="coverage") {
      doSD = True;
      seType=FTMachine::COVERAGE;
      os << "Making single dish coverage function "
	 << LogIO::POST;
    }
    else if (type=="holography") {
      doSD = True;
      seType=FTMachine::CORRECTED;
      os << "Making complex holographic image from corrected data "
	 << LogIO::POST;
    }
    else if (type=="holography-observed") {
      doSD = True;
      seType=FTMachine::OBSERVED;
      os << "Making complex holographic image from observed data "
	 << LogIO::POST;
    }
    else {
      os << LogIO::SEVERE << "Unknown image type " << type << LogIO::POST;

      return False;
    }

    if(doSD&&(ftmachine_p=="ft")) {
      os << "To make single dish images, ftmachine in setoptions must be set to either sd or both"
	 << LogIO::EXCEPTION;
    }
    
    // Now make the images. If we didn't specify the names then
    // delete on exit.
    String imageName(image);
    if(image=="") {
      imageName=qimager::imageName()+".image";
    }
    os << "Image is : " << imageName << LogIO::POST;
    Bool keepImage=(image!="");
    Bool keepComplexImage=(compleximage!="")||(type=="holography")||(type=="holography-observed");
    String cImageName(compleximage);

    if(compleximage=="") {
      cImageName=imageName+".compleximage";
    }

    if(keepComplexImage) {
      os << "Retaining complex image: " << compleximage << LogIO::POST;
    }

    CoordinateSystem imagecoords;
    if(!imagecoordinates(imagecoords))
      {

	return False;
      }
    PagedImage<Float> imageImage(imageshape(), imagecoords, imageName);
    imageImage.set(0.0);
    imageImage.table().markForDelete();
    
    // Now set up the tile size, here we guess only
    IPosition cimageShape(imageshape());
    
    IPosition tileShape(4, min(32, cimageShape(0)), min(32, cimageShape(1)),
			min(4, cimageShape(2)), min(32, cimageShape(3)));
    
    CoordinateSystem cimagecoords;
    if(!imagecoordinates(cimagecoords))
      {

	return False;
      }
    PagedImage<Complex> cImageImage(TiledShape(cimageShape, tileShape),
				    cimagecoords,
				    cImageName);
    cImageImage.set(Complex(0.0));
    cImageImage.setMaximumCacheSize(cache_p/2);
    cImageImage.table().markForDelete();
    //
    // Add the distance to the object: this is not nice. We should define the
    // coordinates properly.
    //
    Record info(imageImage.miscInfo());
    info.define("distance", distance_p.get("m").getValue());
    cImageImage.setMiscInfo(info);

    
    String ftmachine(ftmachine_p);
    createFTMachine();
    
    // Now make the required image
    Matrix<Float> weight;
    ft_p->makeImage(seType, *vs_p, cImageImage, weight);
    StokesImageUtil::To(imageImage, cImageImage);
    imageImage.setUnits(Unit("Jy/beam"));
    cImageImage.setUnits(Unit("Jy/beam"));
    
    if(keepImage) {
      imageImage.table().unmarkForDelete();
    }
    if(keepComplexImage) {
      cImageImage.table().unmarkForDelete();
    }
    itsQimager->unlock();

    return True;
  } catch (AipsError x) {
    itsQimager->unlock();
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;

    return False;
  } 
  itsQimager->unlock();

  return True;
}  

// Residual
Bool qimager::approximatepsf(const Vector<String>& model,
			     const Vector<String>& psf)
{
  
  if(!valid()) return False;
  LogIO os(LogOrigin("imager", "approximatepsfs()", WHERE));
  
  itsQimager->lock();
  try {
    if(!assertDefinedImageParameters()) return False;
    os << "Calculating approximate PSFs using full sky equation" << LogIO::POST;
    
    if(psf.nelements()>model.nelements()) {
      itsQimager->unlock();
      os << LogIO::SEVERE << "Cannot specify more output psfs than models"
	 << LogIO::POST;
      return False;
    }
    else {
      os << "Finding PSFs for " << model.nelements()
	 << " models" << LogIO::POST;
    }
    
    Vector<String> psfNames(psf);
    if(psf.nelements()<model.nelements()) {
      psfNames.resize(model.nelements());
      for(Int i=Int(psf.nelements());i<Int(model.nelements());i++) {
	psfNames(i)="";
      }
    }

    for (Int thismodel=0;thismodel<Int(model.nelements());thismodel++) {
      if(psfNames(thismodel)=="")
	psfNames(thismodel)=model(thismodel)+".psf";
      removeTable(psfNames(thismodel));
      if(psfNames(thismodel)=="") {
	itsQimager->unlock();
	os << LogIO::SEVERE << "Illegal name for output psf "
	   << psfNames(thismodel) << LogIO::POST;
	return False;
      }
      if(!clone(model(thismodel), psfNames(thismodel))) return False;
    }
    
    if(!createSkyEquation(model)) return False;
    
    sm_p->makeApproxPSFs(*se_p);

    for (Int thismodel=0;thismodel<Int(model.nelements());thismodel++) {
      PagedImage<Float> psf(psfNames(thismodel));
      psf.copyData(sm_p->PSF(thismodel));
      Quantity mbmaj, mbmin, mbpa;
      StokesImageUtil::FitGaussianPSF(psf, mbmaj, mbmin, mbpa);
      LatticeExprNode sumPSF = sum(psf);
      Float volume=sumPSF.getFloat();
      os << "Approximate PSF for model " << thismodel+1 << ": size "
	 << mbmaj.get("arcsec").getValue() << " by "
	 << mbmin.get("arcsec").getValue() << " (arcsec) at pa " 
	 << mbpa.get("deg").getValue() << " (deg)" << endl
	 << "and volume = " << volume << " pixels " << LogIO::POST;
    }
    
    destroySkyEquation();
    
    itsQimager->unlock();
    return True;
  } catch (AipsError x) {
    itsQimager->unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  itsQimager->unlock();
  return True;
}

// Restore: at least one model must be supplied
Bool qimager::restore(const Vector<String>& model,
		     const String& complist,
		     const Vector<String>& image,
		     const Vector<String>& residual)
{
  
  if(!valid()) return False;
  LogIO os(LogOrigin("qimager", "restore()", WHERE));
  
  itsQimager->lock();
  try {
    if(!assertDefinedImageParameters()) return False;
    
    if(image.nelements()>model.nelements()) {
      os << LogIO::SEVERE << "Cannot specify more output images than models"
	 << LogIO::POST;
      return False;
    }
    else {
      os << "Restoring " << model.nelements() << " models" << LogIO::POST;
    }
    
    if(redoSkyModel_p){
      Vector<String> imageNames(image);
      if(image.nelements()<model.nelements()) {
	imageNames.resize(model.nelements());
	for(Int i=Int(image.nelements());i<Int(model.nelements());i++) {
	  imageNames(i)="";
	}
      }
      
      for (Int thismodel=0;thismodel<Int(model.nelements());thismodel++) {
	if(imageNames(thismodel)=="") {
	  imageNames(thismodel)=model(thismodel)+".restored";
	}
	removeTable(imageNames(thismodel));
	if(imageNames(thismodel)=="") {
	  os << LogIO::SEVERE << "Illegal name for output image "
	     << imageNames(thismodel) << LogIO::POST;
	  return False;
	}
	if(!clone(model(thismodel), imageNames(thismodel))) return False;
      }
      
      Vector<String> residualNames(residual);
      if(residual.nelements()<model.nelements()) {
	residualNames.resize(model.nelements());
	for(Int i=Int(residual.nelements());i<Int(model.nelements());i++) {
	  residualNames(i)="";
	}
      }

      for (Int thismodel=0;thismodel<Int(model.nelements());thismodel++) {
	if(residualNames(thismodel)=="")
	  residualNames(thismodel)=model(thismodel)+".residual";
	removeTable(residualNames(thismodel));
	if(residualNames(thismodel)=="") {
	  os << LogIO::SEVERE << "Illegal name for output residual "
	     << residualNames(thismodel) << LogIO::POST;
	  return False;
	}
	if(!clone(model(thismodel), residualNames(thismodel))) return False;
      }
    
      if(beamValid_p) {
	os << "Using previous beam fit" << LogIO::POST;
      }
      else {
	os << "Calculating PSF using current parameters" << LogIO::POST;
	String psf;
	psf=imageNames(0)+".psf";
	if(!clone(imageNames(0), psf)) return False;
	qimager::makeimage("psf", psf);
	fitpsf(psf, bmaj_p, bmin_p, bpa_p);
	beamValid_p=True;
      }
    
      if(!createSkyEquation(model, complist)) return False;
      
      addResidualsToSkyEquation(residualNames);
    }
    sm_p->solveResiduals(*se_p);
    
    restoreImages(image);

    destroySkyEquation();
    
    itsQimager->unlock();
    return True;
  } catch (AipsError x) {
    itsQimager->unlock();
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    return False;
  } 
  itsQimager->unlock();
  return True;
}

// Residual
Bool qimager::residual(const Vector<String>& model,
		       const String& complist,
		       const Vector<String>& image)
{
  
  if(!valid()) return False;
  LogIO os(LogOrigin("qimager", "residual()", WHERE));
  
  itsQimager->lock();
  try {
    if(!assertDefinedImageParameters()) return False;
    os << "Calculating residual image using full sky equation" << LogIO::POST;
    
    if(image.nelements()>model.nelements()) {
      os << LogIO::SEVERE << "Cannot specify more output images than models"
	 << LogIO::POST;
      return False;
    }
    else {
      os << "Finding residuals for " << model.nelements()
	 << " models" << LogIO::POST;
    }
    
    Vector<String> imageNames(image);
    if(image.nelements()<model.nelements()) {
      imageNames.resize(model.nelements());
      for(Int i=Int(image.nelements());i<Int(model.nelements());i++) {
	imageNames(i)="";
      }
    }

    for (Int thismodel=0;thismodel<Int(model.nelements());thismodel++) {
      if(imageNames(thismodel)=="")
	imageNames(thismodel)=model(thismodel)+".residual";
      removeTable(imageNames(thismodel));
      if(imageNames(thismodel)=="") {
	os << LogIO::SEVERE << "Illegal name for output image "
	   << imageNames(thismodel) << LogIO::POST;
	return False;
      }
      if(!clone(model(thismodel), imageNames(thismodel))) return False;
    }
    
    if(!createSkyEquation(model, complist)) return False;
    
    addResidualsToSkyEquation(imageNames);
    
    sm_p->solveResiduals(*se_p);
    
    destroySkyEquation();
    
    itsQimager->unlock();
    return True;
  } catch (AipsError x) {
    itsQimager->unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  itsQimager->unlock();
  return True;
}

Bool qimager::smooth(const Vector<String>& model, 
		    const Vector<String>& image, Bool usefit, 
		    Quantity& mbmaj, Quantity& mbmin, Quantity& mbpa,
		    Bool normalizeVolume)
{
  if(!valid()) return False;
  LogIO os(LogOrigin("qimager", "smooth()", WHERE));
  
  itsQimager->lock();
  try {
    if(!assertDefinedImageParameters()) return False;
    
    os << "Smoothing image" << LogIO::POST;
    
    if(model.nelements()>0) {
      for ( uInt thismodel=0;thismodel<model.nelements();thismodel++) {
	if(model(thismodel)=="") {
	  os << LogIO::SEVERE << "Need a name for model " << thismodel+1 << LogIO::POST;
	  return False;
	}
      }
    }
    
    if(image.nelements()>model.nelements()) {
      os << LogIO::SEVERE << "Cannot specify more output images than models" << LogIO::POST;
      return False;
    }
    
    if(usefit) {
      if(beamValid_p) {
	os << "Using previous beam" << LogIO::POST;
	mbmaj=bmaj_p;
	mbmin=bmin_p;
	mbpa=bpa_p;
      }
      else {
	os << "Calculating PSF using current parameters" << LogIO::POST;
	String psf;
	psf=model(0)+".psf";
	if(!clone(model(0), psf)) return False;
	qimager::makeimage("psf", psf);
	fitpsf(psf, mbmaj, mbmin, mbpa);
	bmaj_p=mbmaj;
	bmin_p=mbmin;
	bpa_p=mbpa;
	beamValid_p=True;
      }
    }
    
    // Smooth all the images
    Vector<String> imageNames(image);
    for (Int thismodel=0;thismodel<Int(image.nelements());thismodel++) {
      if(imageNames(thismodel)=="") {
        imageNames(thismodel)=model(thismodel)+".smoothed";
      }
      PagedImage<Float> modelImage(model(thismodel));
      PagedImage<Float> imageImage(modelImage.shape(),
				   modelImage.coordinates(),
				   imageNames(thismodel));
      imageImage.table().markForDelete();
      imageImage.copyData(modelImage);
      StokesImageUtil::Convolve(imageImage, mbmaj, mbmin, mbpa,
				normalizeVolume);
      
      ImageInfo ii = imageImage.imageInfo();
      ii.setRestoringBeam(mbmaj, mbmin, mbpa); 
      imageImage.setImageInfo(ii);
      imageImage.setUnits(Unit("Jy/beam"));
      imageImage.table().unmarkForDelete();
    }
    
    itsQimager->unlock();
    return True;
  } catch (AipsError x) {
    itsQimager->unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  itsQimager->unlock();
  return True;
}

// Clean algorithm
Bool qimager::clean(const String& algorithm,
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


  Bool converged=True;

  if(!valid()) return False;

  LogIO os(LogOrigin("qimager", "clean()", WHERE));
  
  itsQimager->lock();
  try {
    if(!assertDefinedImageParameters()) return False;

    os << "Cleaning images" << LogIO::POST;
    
    Int nmodels=model.nelements();
    os<< "Found " << nmodels << " specified model images" << LogIO::POST;
    
    if(model.nelements()>0) {
      for (uInt thismodel=0;thismodel<model.nelements();thismodel++) {
	if(model(thismodel)=="") {
	  os << LogIO::SEVERE << "Need a name for model "
	     << thismodel+1 << LogIO::POST;
	  
	  return False;
	}
      }
    }
    
    Vector<String> modelNames=model;
    // Make first image with the required shape and coordinates only if
    // it doesn't exist yet. Otherwise we'll throw an exception later
    if(modelNames(0)=="") modelNames(0)=imageName()+".clean";
    if(!Table::isWritable(modelNames(0))) {
      make(modelNames(0));
    }
    
    Vector<String> maskNames(nmodels);
    if(Int(mask.nelements())==nmodels) {
      maskNames=mask;
    }
    else {
      maskNames="";
    }


    if(sm_p){
      if( sm_p->getAlgorithm() != "clean") destroySkyEquation();
      if(images_p.nelements() != uInt(nmodels)){
	destroySkyEquation();
      }
      else{
	for (Int k=0; k < nmodels ; k++){
	  if(!(images_p[k]->name().contains(modelNames[k]))) destroySkyEquation();
	}
      }
    }

    // Always fill in the residual images
    Vector<String> residualNames(nmodels);
    if(redoSkyModel_p){
 
      if(Int(residual.nelements())==nmodels) {
	residualNames=residual;
      }
      else {
	residualNames="";
      }
      for (Int thismodel=0;thismodel<Int(model.nelements());thismodel++) {
	if(residualNames(thismodel)=="") {
	  residualNames(thismodel)=modelNames(thismodel)+".residual";
	}
	removeTable(residualNames(thismodel));
	if(!clone(model(thismodel), residualNames(thismodel)))
	  {
	    
	    return False;
	  }
      }
    }
    
    // Make an ImageSkyModel with the specified polarization representation
    // (i.e. circular or linear)

    if( redoSkyModel_p || !sm_p){
      if(sm_p) delete sm_p;
      if(algorithm=="clark") {
	sm_p = new ClarkCleanImageSkyModel();
      }
      else if (algorithm=="hogbom") {
	sm_p = new HogbomCleanImageSkyModel();
      }
      else if (algorithm=="multiscale") {
	if (!scaleInfoValid_p) {
	  os << LogIO::SEVERE << "Scales not yet set" << LogIO::POST;
	  return False;
	}
	if (scaleMethod_p=="uservector") {	
	  sm_p = new MSCleanImageSkyModel(userScaleSizes_p);
	} else {
	  sm_p = new MSCleanImageSkyModel(nscales_p);
	}
      }
      else if (algorithm=="mfclark" || algorithm=="mf") {
	sm_p = new MFCleanImageSkyModel();
	sm_p->setSubAlgorithm("clark");
	doMultiFields_p = True;
	os << "Using Clark Clean" << LogIO::POST;
      }
      else if (algorithm=="csclean" || algorithm=="cs") {
	sm_p = new CSCleanImageSkyModel();
	doMultiFields_p = True;
	os << "Using Cotton-Schwab Clean" << LogIO::POST;
      }
      else if (algorithm=="csfast" || algorithm=="csf") {
	sm_p = new CSCleanImageSkyModel();
	sm_p->setSubAlgorithm("fast");
	doMultiFields_p = True;
	os << "Using Cotton-Schwab Clean (optimized)" << LogIO::POST;
      }
      else if (algorithm=="mfhogbom") {
	sm_p = new MFCleanImageSkyModel();
	sm_p->setSubAlgorithm("hogbom");
	doMultiFields_p = True;
	os << "Using Hogbom Clean" << LogIO::POST;
      }
      else if (algorithm=="mfmultiscale") {
	if (!scaleInfoValid_p) {
	  os << LogIO::SEVERE << "Scales not yet set" << LogIO::POST;
	  return False;
	}
	if (scaleMethod_p=="uservector") {
	  sm_p = new MFMSCleanImageSkyModel(userScaleSizes_p, 
					    stoplargenegatives_p, 
					    stoppointmode_p);
	} else {
	  sm_p = new MFMSCleanImageSkyModel(nscales_p, 
					    stoplargenegatives_p, 
					    stoppointmode_p);
	}
	sm_p->setSubAlgorithm("fast");
	doMultiFields_p = True;
	os << "Using Multi-Scale Clean with fast calculation of residuals" << LogIO::POST;
      }
      else if (algorithm=="fullmfmultiscale") {
	if (!scaleInfoValid_p) {
	  os << LogIO::SEVERE << "Scales not yet set" << LogIO::POST;
	  return False;
	}
	if (scaleMethod_p=="uservector") {
	  sm_p = new MFMSCleanImageSkyModel(userScaleSizes_p, 
					    stoplargenegatives_p, 
					    stoppointmode_p);
	} else {
	  sm_p = new MFMSCleanImageSkyModel(nscales_p, 
					    stoplargenegatives_p, 
					    stoppointmode_p);
	}
	sm_p->setSubAlgorithm("full");
	doMultiFields_p = True;
	os << "Using Multi-Scale Clean with full calculation of residuals" << LogIO::POST;
      }
      else {
	os << LogIO::SEVERE << "Unknown algorithm: " << algorithm 
	   << LogIO::POST;

	return False;
      }
      
      AlwaysAssert(sm_p, AipsError);
      sm_p->setAlgorithm("clean");
      
      if(!createSkyEquation(modelNames, fixed, maskNames, complist)) 
	return False;
      os << "Created Sky Equation" << LogIO::POST;
      addResidualsToSkyEquation(residualNames);
    }
    else{
      //adding or modifying mask associated with skyModel
      addMasksToSkyEquation(maskNames);
    }

    if (displayProgress) {
      sm_p->setDisplayProgress(True);
    }
    sm_p->setGain(gain);
    sm_p->setNumberIterations(niter);
    sm_p->setThreshold(threshold.get("Jy").getValue());
    sm_p->setCycleFactor(cyclefactor_p);
    sm_p->setCycleSpeedup(cyclespeedup_p);
    {
      ostringstream oos;
      oos << "Clean gain = " <<gain<<", Niter = "<<niter<<", Threshold = "
	  <<threshold << ", Algorithm = " << algorithm;
      os << String(oos) << LogIO::POST;
    }
    os << "Starting deconvolution" << LogIO::POST;
    if(se_p->solveSkyModel()) {
      os << "Successfully deconvolved image" << LogIO::POST;
    }
    else {
      converged=False;
      os << "Clean did not reach threshold" << LogIO::POST;
    }

    //Use predefined beam for restoring or find one by fitting
    if(beamValid_p == True){
      os << "Beam used in restoration: " ;
    }
    else{
      Vector<Float> beam(3);
      beam=sm_p->beam(0);
      bmaj_p=Quantity(abs(beam(0)), "arcsec"); 
      bmin_p=Quantity(abs(beam(1)), "arcsec");
      bpa_p=Quantity(beam(2), "deg");
      beamValid_p=True;
      os << "Fitted beam used in restoration: " ;	
    }

    os << bmaj_p.get("arcsec").getValue() << " by "
       << bmin_p.get("arcsec").getValue() << " (arcsec) at pa " 
       << bpa_p.get("deg").getValue() << " (deg) " << LogIO::POST;

    if(algorithm=="clark" || algorithm=="hogbom" || algorithm=="multiscale")
      sm_p->solveResiduals(*se_p);
    restoreImages(image);
    writeFluxScales(fluxscale_p);
    //    destroySkyEquation();  
    redoSkyModel_p=False;
    for (Int thismodel=0;thismodel<Int(model.nelements());thismodel++) {
      residuals_p[thismodel]->table().relinquishAutoLocks(True);
      residuals_p[thismodel]->table().unlock();
    }
    itsQimager->unlock();

    return converged;
  } catch (AipsError x) {
    for (Int thismodel=0;thismodel<Int(model.nelements());thismodel++) {
      images_p[thismodel]->table().relinquishAutoLocks(True);
      images_p[thismodel]->table().unlock();
      residuals_p[thismodel]->table().relinquishAutoLocks(True);
      residuals_p[thismodel]->table().unlock();
    }
    itsQimager->unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;

    return False;
  } 
  itsQimager->unlock();

  return converged;

}

// Mem algorithm
Bool qimager::mem(const String& algorithm,
		  const Int niter, 
		  const Float gain,
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
   if(!valid())
    {
      return False;
    }
  LogIO os(LogOrigin("qimager", "mem()", WHERE));
  
  itsQimager->lock();
  try {
    if(!assertDefinedImageParameters()) 
      {
	return False;
      }
    os << "Deconvolving images with MEM" << LogIO::POST;
    
    Int nmodels=model.nelements();
    os<< "Found " << nmodels << " specified model images" << LogIO::POST;
    
    if(model.nelements()>0) {
      for (uInt thismodel=0;thismodel<model.nelements();thismodel++) {
	if(model(thismodel)=="") {
	  os << LogIO::SEVERE << "Need a name for model "
	     << thismodel+1 << LogIO::POST;
	  return False;
	}
	else {
	  os << "Model " <<  thismodel+1 << " " << model(thismodel)
	     << LogIO::POST;
	}
      }
    }
    
    Vector<String> priorNames(prior);
    if(priorNames.nelements()==1) {
      if(priorNames(0)=="") {
	priorNames.resize(0);
      }
      else {
	os << "Prior 1 " << priorNames(0)
	   << LogIO::POST;
      }
    }
    else if(priorNames.nelements()>1) {
      for (uInt thismodel=0;thismodel<priorNames.nelements();thismodel++) {
	if(priorNames(thismodel)=="") {
	  os << LogIO::SEVERE << "Need a name for prior "
	     << thismodel+1 << LogIO::POST;
	  return False;
	}
	else {
	  os << "Prior " <<  thismodel+1 << " " << priorNames(thismodel)
	     << LogIO::POST;
	}
      }
    }
    
    Vector<String> modelNames=model;
    // Make first image with the required shape and coordinates only if
    // it doesn't exist yet. Otherwise we'll throw an exception later
    if(modelNames(0)=="") modelNames(0)=imageName()+".mem";
    if(!Table::isWritable(modelNames(0))) {
      make(modelNames(0));
    }
    
    Vector<String> maskNames(nmodels);
    if(Int(mask.nelements())==nmodels) {
      maskNames=mask;
    }
    else {
      maskNames="";
    }
    
    // Always fill in the residual images
    Vector<String> residualNames(nmodels);
    if(Int(residual.nelements())==nmodels) {
      residualNames=residual;
    }
    else {
      residualNames="";
    }
    for (Int thismodel=0;thismodel<Int(model.nelements());thismodel++) {
      if(residualNames(thismodel)=="") {
	residualNames(thismodel)=modelNames(thismodel)+".residual";
      }
      removeTable(residualNames(thismodel));
      if(!clone(model(thismodel), residualNames(thismodel)))
	{
	  return False;
	}
    }
    
    // Make an ImageSkyModel with the specified polarization representation
    // (i.e. circular or linear)
    if(algorithm=="entropy") {
      sm_p = new CEMemImageSkyModel(sigma.get("Jy").getValue(),
				    targetFlux.get("Jy").getValue(),
				    constrainFlux,
				    priorNames,
				    "entropy");
      os << "Using single-field algorithm with Maximum Entropy" << LogIO::POST;
    }
    else if (algorithm=="emptiness") {
      sm_p = new CEMemImageSkyModel(sigma.get("Jy").getValue(),
				    targetFlux.get("Jy").getValue(),
				    constrainFlux,
				    priorNames,
				    "emptiness");
      os << "Using single-field algorithm with Maximum Emptiness" << LogIO::POST;
    }
    else if ((algorithm=="mfentropy")||(algorithm=="fullmfentropy")) {
      sm_p = new MFCEMemImageSkyModel(sigma.get("Jy").getValue(),
				      targetFlux.get("Jy").getValue(),
				      constrainFlux,
				      priorNames,
				      "mfentropy");
      doMultiFields_p = True;
      if(algorithm=="fullmfentropy") {
	sm_p->setSubAlgorithm("full");
	os << "Using Maximum Entropy  with full calculation of residuals" << LogIO::POST;
      }
      else {
	os << "Using Maximum Entropy  with fast calculation of residuals" << LogIO::POST;
      }
    } else if ((algorithm=="mfemptiness")||(algorithm=="mfemptiness")) {
      sm_p = new MFCEMemImageSkyModel(sigma.get("Jy").getValue(),
				      targetFlux.get("Jy").getValue(),
				      constrainFlux,
				      priorNames,
				      "mfemptiness");
      doMultiFields_p = True;
      if(algorithm=="fullmfemptiness") {
	sm_p->setSubAlgorithm("full");
	os << "Using Maximum Emptiness  with full calculation of residuals" << LogIO::POST;
      }
      else {
	os << "Using Maximum Emptiness  with fast calculation of residuals" << LogIO::POST;
      }
    } else {
      os << LogIO::SEVERE << "Unknown algorithm: " << algorithm << LogIO::POST;
      return False;
    }
    AlwaysAssert(sm_p, AipsError);
    sm_p->setAlgorithm("mem");
    if (displayProgress) {
      sm_p->setDisplayProgress(True);
    }
    sm_p->setNumberIterations(niter);
    sm_p->setCycleFactor(cyclefactor_p);   // used by mf algs
    sm_p->setCycleSpeedup(cyclespeedup_p); // used by mf algs
    sm_p->setGain(gain);
    {
      ostringstream oos;
      oos << "MEM algorithm = " <<algorithm<<", Niter = "<<niter
	  <<", Gain = " << gain
	  <<", Sigma = " << sigma
	  << ", Target Flux = " << targetFlux;
      os << String(oos) << LogIO::POST;
    }
    
    if(!createSkyEquation(modelNames, fixed, maskNames, complist)) 
      {
	return False;
      }
    os << "Created Sky Equation" << LogIO::POST;
    
    addResidualsToSkyEquation(residualNames);

    os << "Starting deconvolution" << LogIO::POST;
    if(se_p->solveSkyModel()) {
      os << "Successfully deconvolved image" << LogIO::POST;
    }
    else {
      os << "Nominally failed deconvolution" << LogIO::POST;
    }

    // Get the PSF fit while we are here
    Vector<Float> beam(3);
    beam=sm_p->beam(0);
    bmaj_p=Quantity(abs(beam(0)), "arcsec"); 
    bmin_p=Quantity(abs(beam(1)), "arcsec");
    bpa_p=Quantity(beam(2), "deg");
    beamValid_p=True;

    if(algorithm=="entropy" || algorithm=="emptiness" )
      sm_p->solveResiduals(*se_p);
    restoreImages(image);
    writeFluxScales(fluxscale_p);
    destroySkyEquation();  
    itsQimager->unlock();

    return True;
  } catch (AipsError x) {
    itsQimager->unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;

    return False;
  } 
  itsQimager->unlock();
  return True;

}

Bool qimager::restoreImages(const Vector<String>& restoredNames)
{

  LogIO os(LogOrigin("qimager", "restoreImages()", WHERE));
  
  // It's important that we use the congruent images in both
  // cases. This means that we must use the residual image as
  // passed to the SkyModel and not the one returned.
  if(restoredNames.nelements()>0) {
    for (Int thismodel=0;thismodel<Int(restoredNames.nelements());thismodel++) {
      if(restoredNames(thismodel)!="") {
	PagedImage<Float> restored(images_p[thismodel]->shape(),
				   images_p[thismodel]->coordinates(),
				   restoredNames(thismodel));
	restored.table().markForDelete();
	restored.copyData(*images_p[thismodel]);
	StokesImageUtil::Convolve(restored, bmaj_p, bmin_p, bpa_p);

	// We can work only if the residual image was defined.
	if(residuals_p[thismodel]) {
	  LatticeExpr<Float> le(restored+(*residuals_p[thismodel])); 
	  restored.copyData(le);
	}
	else {
          os << LogIO::SEVERE << "No residual image for model "
	     << thismodel+1 << ", cannot restore image" << LogIO::POST;
	}

	ImageInfo ii = restored.imageInfo();
	ii.setRestoringBeam(bmaj_p, bmin_p, bpa_p); 
	restored.setImageInfo(ii);
	restored.setUnits(Unit("Jy/beam"));
	restored.table().unmarkForDelete();
      }
    }
    
  }
  return True;
}

Bool qimager::writeFluxScales(const Vector<String>& fluxScaleNames)
{
  LogIO os(LogOrigin("qimager", "writeFluxScales()", WHERE));
  Bool answer = False;
  if(fluxScaleNames.nelements()>0) {
    for (Int thismodel=0;thismodel<Int(fluxScaleNames.nelements());thismodel++) {
      if(fluxScaleNames(thismodel)!="") {
        PagedImage<Float> fluxScale(images_p[thismodel]->shape(),
                                    images_p[thismodel]->coordinates(),
                                    fluxScaleNames(thismodel));

        if (sm_p->doFluxScale(thismodel)) {
	  answer = True;
          fluxScale.copyData(sm_p->fluxScale(thismodel));
        } else {
	  answer = False;
          os << "No flux scale available (or required) for model " << thismodel << LogIO::POST;
          os << "(This is only pertinent to mosaiced images)" << LogIO::POST;
          os << "Writing out image of constant 1.0" << LogIO::POST;
          fluxScale.set(1.0);
        }
      }
    }
  }
  return answer;
}
    
// NNLS algorithm
Bool qimager::nnls(const String&,  const Int niter, const Float tolerance, 
		  const Vector<String>& model, const Vector<Bool>& fixed,
		  const String& complist,
		  const Vector<String>& fluxMask,
		  const Vector<String>& dataMask,
		  const Vector<String>& residual,
		  const Vector<String>& image)
{
  if(!valid()) return False;
  LogIO os(LogOrigin("qimager", "nnls()", WHERE));
  
  itsQimager->lock();
  try {
    if(!assertDefinedImageParameters()) return False;
    
    os << "Performing NNLS deconvolution" << LogIO::POST;
    
    if(niter<0) {
      os << LogIO::SEVERE << "Number of iterations must be positive" << LogIO::POST;
      return False;
    }
    if(tolerance<0.0) {
      os << LogIO::SEVERE << LogIO::SEVERE << "Tolerance must be positive" << LogIO::POST;
      return False;
    }
    
    // Add the images to the ImageSkyModel
    Int nmodels=model.nelements();
    if(nmodels>1) os<< "Can only process one model" << LogIO::POST;
    
    if(model(0)=="") {
      os << LogIO::SEVERE << "Need a name for model " << LogIO::POST;
      return False;
    }
    
    if(!Table::isWritable(model(0))) {
      make(model(0));
      itsQimager->lock();
    }
    
    // Always fill in the residual images
    Vector<String> residualNames(nmodels);
    if(Int(residual.nelements())==nmodels) {
      residualNames=residual;
    }
    else {
      residualNames="";
    }
    for (Int thismodel=0;thismodel<Int(model.nelements());thismodel++) {
      if(residualNames(thismodel)=="") {
	residualNames(thismodel)=model(thismodel)+".residual";
      }
      removeTable(residualNames(thismodel));
      if(!clone(model(thismodel), residualNames(thismodel))) return False;
    }
    
    // Now make the NNLS ImageSkyModel
    sm_p= new NNLSImageSkyModel();
    sm_p->setNumberIterations(niter);
    sm_p->setTolerance(tolerance);
    sm_p->setAlgorithm("nnls");
    os << "NNLS Niter = "<<niter<<", Tolerance = "<<tolerance << LogIO::POST;
    
    if(!createSkyEquation(model, fixed, dataMask, fluxMask, complist)) return False;

    addResidualsToSkyEquation(residualNames);
    
    os << "Starting deconvolution" << LogIO::POST;

    if(se_p->solveSkyModel()) {
      os << "Successfully deconvolved image" << LogIO::POST;
    }
    else {
      os << "Nominally failed deconvolution" << LogIO::POST;
    }
    
    // Get the PSF fit while we are here
    StokesImageUtil::FitGaussianPSF(sm_p->PSF(0), bmaj_p, bmin_p, bpa_p);
    beamValid_p=True;
    
    // Restore the image
    restoreImages(image);

    destroySkyEquation();
    itsQimager->unlock();
    return True;
  } catch (AipsError x) {
    itsQimager->unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  itsQimager->unlock();
  return True;
}

// Predict from the model and componentlist
Bool qimager::predict(const Vector<String>& model, const String& complist,
		      const Bool incremental)
{
  if(!valid()) return False;
  
  LogIO os(LogOrigin("qimager", "predict()", WHERE));
  
  itsQimager->lock();
  try {
    
    if(sm_p) destroySkyEquation();
    if(incremental) {
      os << "Predicting model: adding to MODEL_DATA column" << LogIO::POST;
    }
    else {
      os << "Predicting model: replacing MODEL_DATA column" << LogIO::POST;
    }
    
    if(!createSkyEquation(model, complist)) return False;
    
    se_p->predict(incremental);
    
    destroySkyEquation();
    
    itsQimager->unlock();
    return True;
  } catch (AipsError x) {
    itsQimager->unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  itsQimager->unlock();
  return True;
}

Bool qimager::clone(const String& imageName, const String& newImageName)
{
  if(!valid()) return False;
  if(!assertDefinedImageParameters()) return False;
  LogIO os(LogOrigin("qimager", "clone()", WHERE));
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

// Make an empty image
Bool qimager::make(const String& model)
{

  if(!valid())
    {

      return False;
    }
  LogIO os(LogOrigin("qimager", "make()", WHERE));
  
  itsQimager->lock();
  try {
    if(!assertDefinedImageParameters())
      {

	return False;
      }
    
    // Make an image with the required shape and coordinates
    String modelName(model);
    if(modelName=="") modelName=imageName()+".model";
    os << "Making empty image: " << model << LogIO::POST;
    
    removeTable(model);
    CoordinateSystem coords;
    if(!imagecoordinates(coords)) 
      {

	return False;
      }
    PagedImage<Float> modelImage(imageshape(), coords, model);
    modelImage.set(0.0);
    modelImage.table().markForDelete();
    
    // Fill in miscellaneous information needed by FITS
    MSColumns msc(*ms_p);
    Record info;
    String object=msc.field().name()(fieldid_p);
    String telescop=msc.observation().telescopeName()(0);
    info.define("OBJECT", object);
    info.define("TELESCOP", telescop);
    info.define("INSTRUME", telescop);
    info.define("distance", distance_p.get("m").getValue());
    modelImage.setMiscInfo(info);
    modelImage.table().tableInfo().setSubType("GENERIC");
    modelImage.setUnits(Unit("Jy/beam"));
    itsQimager->unlock();

    modelImage.table().unmarkForDelete();
    return True;
  } catch (AipsError x) {
    itsQimager->unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;

    return False;    

  } 
  itsQimager->unlock();

  return True;
}

// Fit the psf. If psf is blank then make the psf first.
Bool qimager::fitpsf(const String& psf, Quantity& mbmaj, Quantity& mbmin,
		    Quantity& mbpa)
{

  if(!valid()) 
    {

      return False;
    }
  LogIO os(LogOrigin("qimager", "fitpsf()", WHERE));
  
  itsQimager->lock();
  try {
    if(!assertDefinedImageParameters()) 
      {

	return False;
      }
    
    os << "Fitting to psf" << LogIO::POST;
    
    String lpsf; lpsf=psf;
    if(lpsf=="") {
      lpsf=imageName()+".psf";
      makeimage("psf", lpsf);
    }

    if(!Table::isReadable(lpsf)) {
      os << LogIO::SEVERE << "PSF image " << lpsf << " does not exist"
	 << LogIO::POST;

      return False;
    }

    PagedImage<Float> psfImage(lpsf);
    StokesImageUtil::FitGaussianPSF(psfImage, mbmaj, mbmin, mbpa);
    bmaj_p=mbmaj;
    bmin_p=mbmin;
    bpa_p=mbpa;
    beamValid_p=True;
    
    os << "  Beam fit: " << bmaj_p.get("arcsec").getValue() << " by "
       << bmin_p.get("arcsec").getValue() << " (arcsec) at pa " 
       << bpa_p.get("deg").getValue() << " (deg) " << endl;

    itsQimager->unlock();
    
return True;
  } catch (AipsError x) {
    itsQimager->unlock();
    os << LogIO::SEVERE << "Exception: " << x.getMesg() << LogIO::POST;

     return False;
  } 
  itsQimager->unlock();

  return True;
}


Bool qimager::setscales(const Vector<Float>& userScaleSizes)
{
  scaleMethod_p = "uservector";
  userScaleSizes_p=userScaleSizes;
  scaleInfoValid_p = True;  
  return True;
};




// Set the beam
Bool qimager::setbeam(const Quantity& mbmaj, const Quantity& mbmin,
		     const Quantity& mbpa)
{
  if(!valid()) return False;
  
  LogIO os(LogOrigin("qimager", "setbeam()", WHERE));
  
  bmaj_p=mbmaj;
  bmin_p=mbmin;
  bpa_p=mbpa;
  beamValid_p=True;
    
  return True;
}

String qimager::className() const
{
  return "qimager";
}

Vector<String> qimager::methods() const
{
  Vector<String> method(33);
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
  method(i++) = "predict";
  method(i++) = "make";

  method(i++) = "fitpsf";
  method(i++) = "filter";
  method(i++) = "smooth";
  method(i++) = "residual";
  method(i++) = "uvrange";

  method(i++) = "sensitivity";
  method(i++) = "advise";
  method(i++) = "setbeam";
  method(i++) = "setvp";
  method(i++) = "setscales";

  method(i++) = "mem";
  method(i++) = "feather";
  method(i++) = "setmfcontrol";
  method(i++) = "pb";
  method(i++) = "linearmosaic";

  method(i++) = "setsdoptions";
  method(i++) = "clone";
  method(i++) = "approximatepsf";

  return method;
}

Vector<String> qimager::noTraceMethods() const
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

MethodResult qimager::runMethod(uInt which, 
			       ParameterSet &inputRecord,
			       Bool runMethod)
{
  
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
	returnval() =        setimage (nx(), ny(),
		  cellx(), celly(),
		  stokes(),
		  doshift(), mPhaseCenter(), 
                  shiftx(), shifty(),
		  mode(), nchan(), start().zeroRelativeValue(), step(),
		  MRadialVelocity(mImageStart(), MRadialVelocity::LSRK),
		  MRadialVelocity(mImageStep(), MRadialVelocity::LSRK),
		  spws, fieldid().zeroRelativeValue(), facets(),
				       distance());
      }
    }
    break;
  case 6: // setdata
    {
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
		 spws, fids, msSelect());
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
      Parameter<Float> padding(inputRecord, "padding", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  setoptions (ftmachine(), cache(), tile(), gridfunction(),
		      padding());
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
  case 13: // predict
    {
      Parameter<Vector<String> > model(inputRecord, "model", ParameterSet::In);
      Parameter<String> complist(inputRecord, "complist", ParameterSet::In);
      Parameter<Bool> incremental(inputRecord, "incremental",
				  ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  predict(model(), complist(), incremental());
      }
    }
    break;
  case 14: // make
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
  case 15: // fitpsf
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
  case 16: // filter
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
  case 17: // smooth
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
  case 18: // residual
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
  case 19: // uvrange
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
  case 20: // sensitivity
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
  case 21: // advise
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
  case 22: // setbeam
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
  case 23: // setvp
    {
      Parameter<Bool> dovp(inputRecord, "dovp", ParameterSet::In);
      Parameter<Bool> usedefaultvp(inputRecord, "usedefaultvp", ParameterSet::In);
      Parameter<String> vptable(inputRecord, "vptable", ParameterSet::In);
      Parameter<Bool> dosquint(inputRecord, "dosquint", ParameterSet::In);
      Parameter<Quantity> parangleinc(inputRecord, "parangleinc", ParameterSet::InOut);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  setvp(dovp(), usedefaultvp(), vptable(),  dosquint(), parangleinc());
      }
    }
    break;
  case 24: // setscales
    {
      Parameter<Vector<Float> > uservector(inputRecord, "uservector", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = setscales(uservector());
      }
    }
    break;
  case 25: // mem
    {
      Parameter<String> algorithm(inputRecord, "algorithm", ParameterSet::In);
      Parameter<Int> niter(inputRecord, "niter", ParameterSet::In);
      Parameter<Float> gain(inputRecord, "gain", ParameterSet::In);
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
	  mem(algorithm(), niter(), gain(), sigma(), 
	      targetflux(), constrainflux(), 
	      displayprogress(), model(), fixed(),
	      complist(), prior(), mask(), image(), residual());
      }
    }
    break;
  case 26: // feather
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
 
  case 27: // setmfcontrol
    {
      Parameter<Float> cyclefactor(inputRecord, "cyclefactor", ParameterSet::In);
      Parameter<Float> cyclespeedup(inputRecord, "cyclespeedup", ParameterSet::In);
      Parameter<Int>  stoplargenegatives(inputRecord, "stoplargenegatives", ParameterSet::In);
      Parameter<Int>   stoppointmode(inputRecord, "stoppointmode", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = setmfcontrol(cyclefactor(), cyclespeedup(), 
				   stoplargenegatives(), stoppointmode());
      }
    }
    break;

  case 28: // pb
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
  case 29: // linearmosaic
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
  case 30: // setsdoptions
    {
      Parameter<Float> scale(inputRecord, "scale", ParameterSet::In);
      Parameter<Float> weight(inputRecord, "weight", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = setsdoptions(scale(), weight());
      }
    }
    break;
  case 31: // clone
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
  case 32: // approximatePSF
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
  default:
    return error("No such method");
  }
  return ok();
}


Bool qimager::detached() const
{
  if (ms_p == 0) {
    LogIO os(LogOrigin("qimager", "detached()", WHERE));
    os << LogIO::SEVERE << 
      "qimager is detached - cannot perform operation." << endl <<
      "Call qimager.open('filename') to reattach." << LogIO::POST;
    return True;
  }
  return False;
}

// Create the FTMachine as late as possible
Bool qimager::createFTMachine()
{
  
  if(ft_p) {delete ft_p; ft_p=0;}
  if(gvp_p) {delete gvp_p; gvp_p=0;}
  if(cft_p) {delete cft_p; cft_p=0;}

  LogIO os(LogOrigin("qimager", "createFTMachine()", WHERE));
  
  // This next line is only a guess
  Int numberAnt=((MeasurementSet&)*ms_p).antenna().nrow();
  
  Int imageVolume=imageshape().product()/square(facets_p);
  if(imageVolume) {
    //    Int minimumCachesize=
    //      tile_p*tile_p*npol_p*imageNchan_p*numberAnt*(numberAnt-1)/2;
    if(imageVolume>cache_p/2) {
      os<<"Cache too small to fit entire image, will use tiled gridding"
	<< endl;  
      os<<"MS has at most "<<numberAnt<<" antennas"<<endl;
      os<<"Optimum cache size to do all baselines is "<< imageVolume
	<< " (complex words)" << LogIO::POST;
    }
  }

  Float padding;
  padding=1.0;
  if(doMultiFields_p) {
    padding = padding_p;
  }

  VisIter& vi(vs_p->iter());
  //  vi.setRowBlocking(100);
  
  if((ftmachine_p=="mosaic")||(ftmachine_p=="sd")) {
    if (doDefaultVP_p) {
      os << "Gridding with default primary beam"
	 << LogIO::POST;
      gvp_p=new VPSkyJones(*ms_p, True, parAngleInc_p, squintType_p);
    } else {
      os << "Gridding with specified primary beam " << vpTableStr_p
	 << LogIO::POST;
      Table vpTable( vpTableStr_p );
      gvp_p=new VPSkyJones(*ms_p, vpTable, parAngleInc_p, squintType_p);
    }
    if(ftmachine_p=="sd") {
      os << "Single dish gridding" << LogIO::POST;
      MSColumns msc(*ms_p);
      String telescop=msc.observation().telescopeName()(0);
      MPosition obsPosition;
      if(! (MeasTable::Observatory(obsPosition, telescop))){
	os << LogIO::WARN << "Did not get the position of " << telescop 
	   << " from data repository" << LogIO::POST ;
	os << LogIO::WARN 
	   << "Please do inform aips++  to put in the repository "
	   << LogIO::POST;
      }
      ft_p = new SDGrid(*ms_p, obsPosition, *gvp_p, cache_p/2, tile_p, gridfunction_p, -1);
    }
    else {
      os << "Mosaic gridding" << LogIO::POST;
      ft_p = new MosaicFT(*ms_p, *gvp_p, cache_p/2, tile_p, True);
    }
  }
  else {
    os << "Performing w-plane projection" << LogIO::POST;
    if(facets_p<64) {
      os << LogIO::WARN
	 << "Facets set too low for W projection - recommend at least 128"
	 << LogIO::POST;
    }
    ft_p = new WProjectFT(*ms_p, facets_p, cache_p/2, tile_p, True);
  }
  
  AlwaysAssert(ft_p, AipsError);
  
  cft_p = new SimpleComponentFTMachine();
  AlwaysAssert(cft_p, AipsError);
  
  ft_p->setSpw(dataspectralwindowids_p, freqFrameValid_p);
  return True;
}

Bool qimager::removeTable(const String& tablename) {
  
  LogIO os(LogOrigin("qimager", "removeTable()", WHERE));
  
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

Bool qimager::createSkyEquation(const String complist) 
{
  Vector<String> image;
  Vector<String> mask;
  Vector<String> fluxMask;
  Vector<Bool> fixed;
  return createSkyEquation(image, fixed, mask, fluxMask, complist);
}

Bool qimager::createSkyEquation(const Vector<String>& image,
			       const String complist) 
{
  Vector<Bool> fixed(image.nelements()); fixed=False;
  Vector<String> mask(image.nelements()); mask="";
  Vector<String> fluxMask(image.nelements()); fluxMask="";
  return createSkyEquation(image, fixed, mask, fluxMask, complist);
}

Bool qimager::createSkyEquation(const Vector<String>& image,
			       const Vector<Bool>& fixed,
			       const String complist) 
{
  Vector<String> mask(image.nelements()); mask="";
  Vector<String> fluxMask(image.nelements()); fluxMask="";
  return createSkyEquation(image, fixed, mask, fluxMask, complist);
}

Bool qimager::createSkyEquation(const Vector<String>& image,
			       const Vector<Bool>& fixed,
			       const Vector<String>& mask,
			       const String complist) 
{
  Vector<String> fluxMask(image.nelements()); fluxMask="";
  return createSkyEquation(image, fixed, mask, fluxMask, complist);
}

Bool qimager::createSkyEquation(const Vector<String>& image,
			       const Vector<Bool>& fixed,
			       const Vector<String>& mask,
			       const Vector<String>& fluxMask,
			       const String complist)
{
  
  if(!valid()) return False;

  LogIO os(LogOrigin("qimager", "createSkyEquation()", WHERE));
  
  // If there is no sky model, we'll make one:

  if(sm_p==0) {
    sm_p = new CleanImageSkyModel();
  }
  AlwaysAssert(sm_p, AipsError);

  // Add the componentlist
  if(complist!="") {
    if(!Table::isReadable(complist)) {
      os << LogIO::SEVERE << "ComponentList " << complist
	 << " not readable" << LogIO::POST;
      return False;
    }
    componentList_p=new ComponentList(complist, True);
    if(componentList_p==0) {
      os << LogIO::SEVERE << "Cannot create ComponentList from " << complist
	 << LogIO::POST;
      return False;
    }
    if(!sm_p->add(*componentList_p)) {
      os << LogIO::SEVERE << "Cannot add ComponentList " << complist
	 << " to SkyModel" << LogIO::POST;
      return False;
    }
  }
  else {
    componentList_p=0;
  }
 
  // Make image with the required shape and coordinates only if
  // they don't exist yet
  nmodels_p=image.nelements();

  // Remove degenerate case (due to user interface?)
  if((nmodels_p==1)&&(image(0)=="")) {
    nmodels_p=0;
  }
  if(nmodels_p>0) {
    images_p.resize(nmodels_p); 
    masks_p.resize(nmodels_p);  
    fluxMasks_p.resize(nmodels_p); 
    residuals_p.resize(nmodels_p); 
    for (Int model=0;model<Int(nmodels_p);model++) {
      if(image(model)=="") {
	os << LogIO::SEVERE << "Need a name for model "
	   << model+1 << LogIO::POST;
	return False;
      }
      else {
	if(!Table::isWritable(image(model))) {
	  if(!assertDefinedImageParameters()) return False;
	  make(image(model));
	}
      }
      images_p[model]=0;
      images_p[model]=new PagedImage<Float>(image(model));
      AlwaysAssert(images_p[model], AipsError);

      if((sm_p->add(*images_p[model]))!=model) {
	os << LogIO::SEVERE << "Error adding model " << model+1 << LogIO::POST;
	return False;
      }
      if(Int(fixed.nelements())>model&&fixed(model)) {
        os << "Model " << model+1 << " will be held fixed" << LogIO::POST;
	sm_p->fix(model);
      }      
      fluxMasks_p[model]=0;
      if(fluxMask(model)!=""&&Table::isReadable(fluxMask(model))) {
	fluxMasks_p[model]=new PagedImage<Float>(fluxMask(model));
	AlwaysAssert(fluxMasks_p[model], AipsError);
        if(!sm_p->addFluxMask(model, *fluxMasks_p[model])) {
	  os << LogIO::SEVERE << "Error adding flux mask " << model+1
	     << " : " << fluxMask(model) << LogIO::POST;
	  return False;
	}
      }
      residuals_p[model]=0;
    }
    addMasksToSkyEquation(mask);
  }
  
  // Always need a VisSet and an FTMachine

  createFTMachine();
  
  // Now set up the SkyEquation
  AlwaysAssert(sm_p, AipsError);
  AlwaysAssert(vs_p, AipsError);
  AlwaysAssert(ft_p, AipsError);
  AlwaysAssert(cft_p, AipsError);

  setSkyEquation();
  AlwaysAssert(se_p, AipsError);
  
  return True;  
}

// Tell the sky model to use the specified images as the residuals    
Bool qimager::addResidualsToSkyEquation(const Vector<String>& imageNames) {
  
  residuals_p.resize(imageNames.nelements());
  for (Int thismodel=0;thismodel<Int(imageNames.nelements());thismodel++) {
    if(imageNames(thismodel)!="") {
      removeTable(imageNames(thismodel));
      residuals_p[thismodel]=
	new PagedImage<Float> (images_p[thismodel]->shape(),
			       images_p[thismodel]->coordinates(),
			       imageNames(thismodel));
      AlwaysAssert(residuals_p[thismodel], AipsError);
      residuals_p[thismodel]->setUnits(Unit("Jy/beam"));
      sm_p->addResidual(thismodel, *residuals_p[thismodel]);
    }
  }
  return True;
} 

void qimager::destroySkyEquation() 
{
  if(se_p) delete se_p; se_p=0;
  if(sm_p) delete sm_p; sm_p=0;
  if(vp_p) delete vp_p; vp_p=0;
  if(gvp_p) delete gvp_p; gvp_p=0;
  if(componentList_p) delete componentList_p; componentList_p=0;
  for (Int model=0;model<Int(nmodels_p);model++) {
    if(images_p[model]) delete images_p[model]; images_p[model]=0;
    if(masks_p[model]) delete masks_p[model]; masks_p[model]=0;
    if(fluxMasks_p[model]) delete fluxMasks_p[model]; fluxMasks_p[model]=0;
    if(residuals_p[model]) delete residuals_p[model]; residuals_p[model]=0;
  }
  redoSkyModel_p=True;
}

Bool qimager::assertDefinedImageParameters() const
{
  LogIO os(LogOrigin("qimager", "if(!assertDefinedImageParameters()", WHERE));
  if(!setimaged_p) { 
    os << LogIO::SEVERE << "Image parameters not yet set: use setimage "
      "in Function Group <setup> " << LogIO::POST;
    return False;
  }
  return True;
}

Bool qimager::valid() const {
  LogIO os(LogOrigin("qimager", "if(!valid()) return False", WHERE));
  if(!ms_p) {
    os << LogIO::SEVERE << "Program logic error: MeasurementSet pointer ms_p not yet set"
       << LogIO::POST;
    return False;
  }
  if(!mssel_p) {
    os << LogIO::SEVERE << "Program logic error: MeasurementSet pointer mssel_p not yet set"
       << LogIO::POST;
    return False;
  }
  if(!vs_p) {
    os << LogIO::SEVERE << "Program logic error: VisSet pointer vs_p not yet set"
       << LogIO::POST;
    return False;
  }
  return True;
}

Bool qimager::addMasksToSkyEquation(const Vector<String>& mask){
  LogIO os(LogOrigin("qimager", "addMasksToSkyEquation()", WHERE));

  for(Int model=0 ;model < nmodels_p; model++){
    if(!(masks_p[model])) delete masks_p[model];
    masks_p[model]=0;
      if(mask(model)!=""&&Table::isReadable(mask(model))) {
	masks_p[model]=new PagedImage<Float>(mask(model));
	AlwaysAssert(masks_p[model], AipsError);
        if(!sm_p->addMask(model, *masks_p[model])) {
	  os << LogIO::SEVERE << "Error adding mask " << model+1
	     << " : " << mask(model) << LogIO::POST;
	  return False;
	}
      }
  }
  return True;
}

} //#End casa namespace
