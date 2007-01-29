//# newsimulator.cc: Simulation  program
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002,2003
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or (at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: DOnewsimulator.cc,v 19.25 2006/05/04 15:51:11 sbhatnag Exp $

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

#include <msvis/MSVis/VisSet.h>
#include <msvis/MSVis/VisSetUtil.h>
#include <synthesis/MeasurementComponents/TimeVarVisJones.h>
#include <ms/MeasurementSets/NewMSSimulator.h>

#include <measures/Measures/Stokes.h>
#include <casa/Quanta/UnitMap.h>
#include <casa/Quanta/UnitVal.h>
#include <casa/Quanta/MVAngle.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <casa/Quanta/MVEpoch.h>
#include <measures/Measures/MEpoch.h>

#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MeasurementSets/MSColumns.h>

#include <ms/MeasurementSets/MSSummary.h>
#include <synthesis/MeasurementEquations/SkyEquation.h>
#include <synthesis/MeasurementEquations/VisEquation.h>
#include <synthesis/MeasurementComponents/ImageSkyModel.h>
#include <synthesis/MeasurementComponents/SimACohCalc.h>
#include <synthesis/MeasurementComponents/SimACoh.h>
#include <synthesis/MeasurementComponents/SimVisJones.h>
#include <synthesis/MeasurementComponents/VPSkyJones.h>
#include <synthesis/MeasurementEquations/StokesImageUtil.h>
#include <lattices/Lattices/LatticeExpr.h> 

#include <appsglish/newsimulator/DOnewsimulator.h>

#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/Index.h>
#include <tasking/Tasking/MethodResult.h>
#include <casa/System/PGPlotter.h>
#include <tasking/Tasking/ObjectController.h>
#include <synthesis/MeasurementComponents/CleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/GridBoth.h>
#include <synthesis/MeasurementComponents/WProjectFT.h>
#include <synthesis/MeasurementComponents/GridBoth.h>
#include <synthesis/MeasurementComponents/MosaicFT.h>
#include <synthesis/MeasurementComponents/SimpleComponentFTMachine.h>
#include <casa/OS/HostInfo.h>
#include <images/Images/PagedImage.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/Vector.h>
#include <casa/sstream.h>

#include <casa/namespace.h>
newsimulator::newsimulator(String& msname) 
  : msname_p(msname), ms_p(0), mssel_p(0), vs_p(0), seed_p(11111),
    gj_p(0), pj_p(0), dj_p(0), bj_p(0), ac_p(0), vp_p(0), gvp_p(0), 
    sim_p(0),epJ_p(0),epJTableName_p()
{
  LogIO os(LogOrigin("newsimulator", "newsimulator(String& msname)", WHERE));

  defaults();

  if(!sim_p) {
    sim_p= new NewMSSimulator(msname);
  }
  
  // Make a MeasurementSet object for the disk-base MeasurementSet that we just
  // created
  ms_p = new MeasurementSet(msname, Table::Update);
  AlwaysAssert(ms_p, AipsError);
}

newsimulator::newsimulator(MeasurementSet &theMs)
  : msname_p(""), ms_p(0), mssel_p(0), vs_p(0), seed_p(11111),
    gj_p(0), pj_p(0), dj_p(0), bj_p(0), ac_p(0), vp_p(0), gvp_p(0), 
    sim_p(0),epJ_p(0),epJTableName_p()
{
  LogIO os(LogOrigin("newsimulator", "newsimulator(MeasurementSet& theMs)", WHERE));

  defaults();

  msname_p=theMs.tableName();

  if(!sim_p) {
    sim_p= new NewMSSimulator(theMs);
  }

  ms_p = new MeasurementSet(theMs);
  AlwaysAssert(ms_p, AipsError);
}

newsimulator::newsimulator(const newsimulator &other)
  : msname_p(""), ms_p(0), vs_p(0), seed_p(11111),
    gj_p(0), pj_p(0), dj_p(0), bj_p(0), ac_p(0), vp_p(0), gvp_p(0),
    sim_p(0),epJ_p(0),epJTableName_p()
{
  defaults();
  ms_p = new MeasurementSet(*other.ms_p);
  if(other.mssel_p) {
    mssel_p = new MeasurementSet(*other.mssel_p);
  }
}

newsimulator &newsimulator::operator=(const newsimulator &other)
{
  if (ms_p && this != &other) {
    *ms_p = *(other.ms_p);
  }
  if (mssel_p && this != &other && other.mssel_p) {
    *mssel_p = *(other.mssel_p);
  }
  if (vs_p && this != &other) {
    *vs_p = *(other.vs_p);
  }
  if (gj_p && this != &other) {
    *gj_p = *(other.gj_p);
  }
  if (pj_p && this != &other) {
    *pj_p = *(other.pj_p);
  }
  if (dj_p && this != &other) {
    *dj_p = *(other.dj_p);
  }
  if (bj_p && this != &other) {
    *bj_p = *(other.bj_p);
  }
  if (ac_p && this != &other) {
    *ac_p = *(other.ac_p);
  }
  if (vp_p && this != &other) {
    *vp_p = *(other.vp_p);
  }
  if (gvp_p && this != &other) {
    *gvp_p = *(other.gvp_p);
  }
  if (sim_p && this != &other) {
    *sim_p = *(other.sim_p);
  }
  //  if (epJ_p && this != &other) *epJ_p = *(other.epJ_p);
  return *this;
}

newsimulator::~newsimulator()
{
  if (ms_p) {
    ms_p->unlock();
    delete ms_p;
  }
  ms_p = 0;
  if (mssel_p) {
    mssel_p->unlock();
    delete mssel_p;
  }
  mssel_p = 0;
  if (vs_p) {
    delete vs_p;
  }
  vs_p = 0;
  if (gj_p) {
    delete gj_p;
  }
  gj_p = 0;
  if (pj_p) {
    delete pj_p;
  }
  pj_p = 0;
  if (dj_p) {
    delete dj_p;
  }
  dj_p = 0;
  if (bj_p) {
    delete bj_p;
  }
  bj_p = 0;
  if (ac_p) {
    delete ac_p;
  }
  ac_p = 0;
  if (epJ_p) delete epJ_p; epJ_p = 0;

  if(sm_p) delete sm_p; sm_p = 0;
  if(ft_p) delete ft_p; ft_p = 0;
  if(cft_p) delete cft_p; cft_p = 0;
  if(vp_p) delete vp_p; vp_p = 0;
  if(gvp_p) delete gvp_p; gvp_p = 0;
  if(sim_p) delete sim_p; sim_p = 0;
  if(epJ_p) delete epJ_p; epJ_p = 0;
}



void newsimulator::defaults()
{
  UnitMap::putUser("Pixel", UnitVal(1.0), "Pixel solid angle");
  UnitMap::putUser("Beam", UnitVal(1.0), "Beam solid angle");
  gridfunction_p="SF";
  // Use half the machine memory as cache. The user can override
  // this via the setoptions function().
  cache_p=HostInfo::memoryTotal()*1024*1024*1024/(2*8);
  tile_p=16;
  ftmachine_p="gridft";
  padding_p=1.3;
  facets_p=1;
  sm_p = 0;
  ft_p = 0;
  cft_p = 0;
  vp_p = 0;
  gvp_p = 0;
  sim_p = 0;
  images_p = 0;
  nmodels_p = 1;
  // info for configurations
  areStationCoordsSet_p = False;
  telescope_p = "";
  nmodels_p = 0;

  // info for fields and schedule:
  sourceName_p="";
  calCode_p="";

  // info for spectral windows
  spWindowName_p="LBand";
  nChan_p=1;
  startFreq_p=Quantity(1.4, "GHz");
  freqInc_p=Quantity(0.1, "MHz");
  freqRes_p=Quantity(0.1, "MHz");
  stokesString_p="RR RL LR LL";

  // feeds
  feedMode_p = "perfect R L";
  nFeeds_p = 1;
  feedsHaveBeenSet = False;
  feedsInitialized = False;

  // times
  integrationTime_p = Quantity(10.0, "s");
  useHourAngle_p=True;
  refTime_p = MEpoch(Quantity(0.0, "s"), MEpoch::UTC);
  timesHaveBeenSet_p=False;

  // VP stuff
  doVP_p=False;
  doDefaultVP_p = True;

};


Bool newsimulator::close()
{
  LogIO os(LogOrigin("newsimulator", "close()", WHERE));
  os << "Closing MeasurementSet and detaching from newsimulator"
     << LogIO::POST;
  ms_p->unlock();
  if(mssel_p) mssel_p->unlock();
  if(gj_p) delete gj_p; gj_p = 0;
  if(pj_p) delete pj_p; pj_p = 0;
  if(vs_p) delete vs_p; vs_p = 0;
  if(mssel_p) delete mssel_p; mssel_p = 0;
  if(ms_p) delete ms_p; ms_p = 0;
  if(dj_p) delete dj_p; dj_p = 0;
  if(bj_p) delete bj_p; bj_p = 0;
  if(ac_p) delete ac_p; ac_p = 0;
  if(sm_p) delete sm_p; sm_p = 0;
  if(ft_p) delete ft_p; ft_p = 0;
  if(cft_p) delete cft_p; cft_p = 0;
  if(epJ_p) delete epJ_p; epJ_p = 0;

  return True;
}

String newsimulator::name() const
{
  if (detached()) {
    return "none";
  }
  return msname_p;
}

String newsimulator::state()
{
  ostringstream os;
  os << "Need to write the state() method!" << LogIO::POST;
  if(doVP_p) {
    os << "  Primary beam correction is enabled" << endl;
  }
  return String(os);
}

Bool newsimulator::summary()
{
  LogIO os(LogOrigin("newsimulator", "summary()", WHERE));
  createSummary(os);
  predictSummary(os);
  corruptSummary(os);

  return True;
}


Bool newsimulator::createSummary(LogIO& os) 
{
  Bool configResult = configSummary(os);
  Bool fieldResult = fieldSummary(os);
  Bool windowResult = spWindowSummary(os);
  Bool feedResult = feedSummary(os);

  if (!configResult && !fieldResult && !windowResult && !feedResult) {
    os << "=======================================" << LogIO::POST;
    os << "No create-type information has been set" << LogIO::POST;
    os << "=======================================" << LogIO::POST;
    return False;
  } else {
    // user has set at least ONE, so we report on each
    if (!configResult) {
      os << "No configuration information set yet, but other create-type info HAS been set" << LogIO::POST;
    }
    if (!fieldResult) {
      os << "No field information set yet, but other create-type info HAS been set" << LogIO::POST;
    }
    if (!windowResult) {
      os << "No window information set yet, but other create-type info HAS been set" << LogIO::POST;
    }
    if (!feedResult) {
      os << "No feed information set yet, but other create-type info HAS been set" << LogIO::POST;
      os << "(feeds will default to perfect R-L feeds if not set)" << LogIO::POST;
    }
    os << "======================================================================" << LogIO::POST;
  }
  return True;
}
Bool newsimulator::configSummary(LogIO& os)
{
  if ( ! areStationCoordsSet_p ) {
    return False;
  } else {
    os << "----------------------------------------------------------------------" << LogIO::POST;
    os << "Generating (u,v,w) using this configuration: " << LogIO::POST;
    os << "   x     y     z     diam     mount " << LogIO::POST;
    for (uInt i=0; i< x_p.nelements(); i++) {
      os << x_p(i)
	 << "  " << y_p(i)
	 << "  " << z_p(i)
	 << "  " << diam_p(i)
	 << "  " << mount_p(i)
	 << LogIO::POST;
    }
    os << " Coordsystem = " << coordsystem_p << LogIO::POST;
    os << " RefLocation = " << 
      mRefLocation_p.getAngle("deg").getValue("deg") << LogIO::POST;
  }
  return True;

}
Bool newsimulator::fieldSummary(LogIO& os)
{
  os << "----------------------------------------------------------------------" << LogIO::POST;
  os << " Field information: " << LogIO::POST;
  os << " Name  direction  calcode" << LogIO::POST; 
  os << sourceName_p 
     << "  " << formatDirection(sourceDirection_p)
     << "  " << calCode_p
     << LogIO::POST;
  return True;
}
Bool newsimulator::timeSummary(LogIO& os)
{
  if(integrationTime_p.getValue("s") <= 0.0) {
    return False;
  } else {
    os << "----------------------------------------------------------------------" << LogIO::POST;
    os << " Time information: " << LogIO::POST;
    os << " integration time = " << integrationTime_p.getValue("s") 
       << " s" << LogIO::POST;
    os << " reference time = " << MVTime(refTime_p.get("s").getValue("d")).string()
       << LogIO::POST;
  }
  return True;
}
Bool newsimulator::spWindowSummary(LogIO& os)
{
  os << "----------------------------------------------------------------------" << LogIO::POST;
  os << " Spectral Windows information: " << LogIO::POST;
  os << " Name  nchan  freq[GHz]  freqInc[MHz]  freqRes[MHz]  stokes" << LogIO::POST;
  os << spWindowName_p 	 
     << "  " << nChan_p
     << "  " << startFreq_p.getValue("GHz")
     << "  " << freqInc_p.getValue("MHz")
     << "  " << freqRes_p.getValue("MHz")
     << "  " << stokesString_p
     << LogIO::POST;
  return True;
}

Bool newsimulator::feedSummary(LogIO& os)
{
  if (!feedsHaveBeenSet) {
    return False;
  } else {
    os << "----------------------------------------------------------------------" << LogIO::POST;
    os << " Feed information: " << LogIO::POST;
    os << feedMode_p << LogIO::POST;
  }
  return True;
}

Bool newsimulator::predictSummary(LogIO& os)
{
  Bool vpResult = vpSummary(os);
  Bool optionsResult = optionsSummary(os);

  // keep compiler happy
  if (!vpResult && !optionsResult) {}
  return True;
}
Bool newsimulator::vpSummary(LogIO& os)
{
  if (vp_p) {
    vp_p->summary();
    return True;
  } else {
    return False;
  }
}
Bool newsimulator::optionsSummary(LogIO& os)
{
  return True;
}
 
Bool newsimulator::corruptSummary(LogIO& os)
{
  Bool gainResult = gainSummary(os);
  Bool leakageResult = leakageSummary(os);
  Bool bpesult = bandpassSummary(os);
  Bool paResult = paSummary(os);
  Bool noiseResult = noiseSummary(os);  
  if (!gainResult && !leakageResult && !bpesult && !paResult && !noiseResult) {
    os << "===========================================" << LogIO::POST;
    os << "No corrupting-type information has been set" << LogIO::POST;
    os << "===========================================" << LogIO::POST;
    return False;
  }
  return True;
}
Bool newsimulator::gainSummary(LogIO& os)
{
  if(!gj_p) {
    return False;
  } else {
    os << "Gain corruption activated" << LogIO::POST;
  }
  return True;
}
Bool newsimulator::leakageSummary(LogIO& os)
{
  if(!dj_p) {
    return False;
  } else {
    os << "Polarization leakage corruption activated" << LogIO::POST;
  }
  return True;
}
Bool newsimulator::bandpassSummary(LogIO& os)
{
  if(!bj_p) {
    return False;
  } else {
    os << "Bandpass corruption activated" << LogIO::POST;
  }
  return True;
}
Bool newsimulator::paSummary(LogIO& os)
{
  if(!pj_p) {
    return False;
  } else {
    os << "PA corruption activated" << LogIO::POST;
  }
  return True;
}
Bool newsimulator::noiseSummary(LogIO& os)
{
  if (!ac_p) {
   return False;
  } else {
    os << "Thermal noise corruption activated" << LogIO::POST;
    os << "Thermal noise mode: " << noisemode_p << LogIO::POST;
  }
  return True;
}


Bool newsimulator::settimes(const Quantity& integrationTime, 
			 const Bool      useHourAngle,
			 const MEpoch&   refTime)
{
  
  LogIO os(LogOrigin("simulator", "settimes()", WHERE));
  try {
    
    integrationTime_p=integrationTime;
    useHourAngle_p=useHourAngle;
    refTime_p=refTime;

    os << "Times " << endl
       <<  "     Integration time " << integrationTime.getValue("s") << "s" << LogIO::POST;
    if(useHourAngle) {
      os << "     Times will be interpreted as hour angles for first source" << LogIO::POST;
    }

    sim_p->settimes(integrationTime, useHourAngle, refTime);
    
    timesHaveBeenSet_p=True;
    
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
  
}



Bool newsimulator::setseed(const Int seed) {
  seed_p = seed;
  return True;
}


Bool newsimulator::setconfig(const String& telname,
			     const Vector<Double>& x, 
			     const Vector<Double>& y, 
			     const Vector<Double>& z,
			     const Vector<Double>& dishDiameter,
			     const Vector<Double>& offset,
			     const Vector<String>& mount,
			     const Vector<String>& antName,
			     const String& coordsystem,
			     const MPosition& mRefLocation) 
{

  telescope_p = telname;
  x_p.resize(x.nelements());
  x_p = x;
  y_p.resize(y.nelements());
  y_p = y;
  z_p.resize(z.nelements());
  z_p = z;
  diam_p.resize(dishDiameter.nelements());
  diam_p = dishDiameter;
  offset_p.resize(offset.nelements());
  offset_p = offset;
  mount_p.resize(mount.nelements());
  mount_p = mount;
  antName_p.resize(antName.nelements());
  antName_p = antName;
  coordsystem_p = coordsystem;
  mRefLocation_p = mRefLocation;

  uInt nn = x_p.nelements();

  if (diam_p.nelements() == 1) {
    diam_p.resize(nn);
    diam_p.set(dishDiameter(0));
  }
  if (mount_p.nelements() == 1) {
    mount_p.resize(nn);
    mount_p.set(mount(0));
  }
  if (mount_p.nelements() == 0) {
    mount_p.resize(nn);
    mount_p.set("alt-az");
  }
  if (offset_p.nelements() == 1) {
    offset_p.resize(nn);
    offset_p.set(offset(0));
  }
  if (offset_p.nelements() == 0) {
    offset_p.resize(nn);
    offset_p.set(0.0);
  }
  if (antName_p.nelements() == 1) {
    antName_p.resize(nn);
    antName_p.set(antName(0));
  }
  if (antName_p.nelements() == 0) {
    antName_p.resize(nn);
    antName_p.set("UNKNOWN");
  }

  AlwaysAssert( (nn == y_p.nelements())  , AipsError);
  AlwaysAssert( (nn == z_p.nelements())  , AipsError);
  AlwaysAssert( (nn == diam_p.nelements())  , AipsError);
  AlwaysAssert( (nn == offset_p.nelements())  , AipsError);
  AlwaysAssert( (nn == mount_p.nelements())  , AipsError);

  areStationCoordsSet_p = True;
  
  sim_p->initAnt(telescope_p, x_p, y_p, z_p, diam_p, offset_p, mount_p, antName_p, 
		 coordsystem_p, mRefLocation_p);
  
  return True;  
}


Bool newsimulator::setfield(const String& sourceName,           
			 const MDirection& sourceDirection,  
			 const String& calCode,
			 const Quantity& distance)
{
  LogIO os(LogOrigin("newsimulator", "setfield()", WHERE));

  try {
    if (sourceName == "") {
      os << LogIO::SEVERE << "must provide a source name" << LogIO::POST;  
      return False;
    }

    distance_p=distance;
    sourceName_p=sourceName;
    sourceDirection_p=sourceDirection;
    calCode_p=calCode;

    sim_p->initFields(sourceName, sourceDirection, calCode);

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
};



Bool newsimulator::setspwindow(const String& spwName,           
			    const Quantity& freq,
			    const Quantity& deltafreq,
			    const Quantity& freqresolution,
			    const Int nChan,
			    const String& stokes) 

{
  LogIO os(LogOrigin("newsimulator", "setspwindow()", WHERE));

  try {
    if (nChan == 0) {
      os << LogIO::SEVERE << "must provide nchannels" << LogIO::POST;  
      return False;
    }

    spWindowName_p = spwName;   
    nChan_p = nChan;          
    startFreq_p = freq;      
    freqInc_p = deltafreq;        
    freqRes_p = freqresolution;        
    stokesString_p = stokes;   

    sim_p->initSpWindows(spWindowName_p, nChan_p, startFreq_p, freqInc_p, 
			 freqRes_p, stokesString_p);

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
};

Bool newsimulator::setfeed(const String& mode,
			   const Vector<Double>& x,
			   const Vector<Double>& y,
			   const Vector<String>& pol)
{
  LogIO os(LogOrigin("newsimulator", "setfeed()", WHERE));
  
  if (mode != "perfect R L" && mode != "perfect X Y" && mode != "list") {
    os << LogIO::SEVERE << 
      "Currently, only perfect R L or perfect X Y feeds or list are recognized" 
       << LogIO::POST;
    return False;
  }
  sim_p->initFeeds(feedMode_p, x, y, pol);

  feedMode_p = mode;
  nFeeds_p = x.nelements();
  feedsHaveBeenSet = True;

  return True;
};




Bool newsimulator::setvp(const Bool dovp,
			 const Bool doDefaultVPs,
			 const String& vpTable,
			 const Bool doSquint,
			 const Quantity &parAngleInc,
			 const Quantity &skyPosThreshold,
			 const Float &pbLimit)
{
  LogIO os(LogOrigin("newsimulatore", "setvp()", WHERE));
  
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
  skyPosThreshold_p = skyPosThreshold;

  if (doDefaultVP_p) {
    os << "Using system default voltage patterns for each telescope"  << LogIO::POST;
  } else {
    os << "Using user defined voltage patterns in Table "<<  vpTableStr_p 
       << LogIO::POST;
  }
  if (doSquint) {
    os << "Beam Squint will be included in the VP model" <<  LogIO::POST;
    os << "and the parallactic angle increment is " 
       << parAngleInc_p.getValue("deg") << " degrees"  << LogIO::POST;
  }
  pbLimit_p = pbLimit;
  return True;
};





Bool newsimulator::setpa(const String& mode, const String& table,
		      const Quantity& interval) {
  
  LogIO os(LogOrigin("newsimulator", "setpa()", WHERE));
  
  try {
    
    if(mode=="table") {
      os << LogIO::SEVERE << "Cannot yet read from table" << LogIO::POST;
      return False;
    }
    else {
      makeVisSet();
      if(pj_p) delete pj_p; pj_p = 0;
      pj_p = new PJones (*vs_p, interval.get("s").getValue());
      os <<"Using parallactic angle correction"<< LogIO::POST;
    }

    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
};

Bool newsimulator::setnoise(const String& mode, 
			 const Quantity& simplenoise,
			 const String& table,
			 const Float antefficiency=0.80,
			 const Float correfficiency=0.85,
			 const Float spillefficiency=0.85,
			 const Float tau=0.0,
			 const Float trx=50.0, 
			 const Float tatmos=250.0, 
			 const Float tcmb=2.7) {
                         // const Quantity& trx=50.0, 
                         // const Quantity& tatmos=250.0, 
                         // const Quantity& tcmb=2.7) {
  
  LogIO os(LogOrigin("newsimulator", "setnoise()", WHERE));
  try {
    
    os << "In DOsim::setnoise() " << endl;
    noisemode_p = mode;

    if(mode=="table") {
      os << LogIO::SEVERE << "Cannot yet read from table" << LogIO::POST;
      return False;
    }
    else if (mode=="simplenoise") {
      os << "Using simple noise model with noise level of " << simplenoise.getValue("Jy")
	 << " Jy" << LogIO::POST;
	if(ac_p) delete ac_p; ac_p = 0;
	ac_p = new SimACoh(seed_p, simplenoise.getValue("Jy") );
    }
    else {
      os << "Using the Brown calculated noise model" << LogIO::POST;
	if(ac_p) delete ac_p; ac_p = 0;
	ac_p = new SimACohCalc(seed_p, antefficiency, correfficiency,
			       spillefficiency, tau, Quantity(trx, "K"), 
			       Quantity(tatmos, "K"), Quantity(tcmb, "K"));
    }

    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
  
}

Bool newsimulator::setgain(const String& mode, const String& table,
			const Quantity& interval,
			const Vector<Double>& amplitude) {
  
  LogIO os(LogOrigin("newsimulator", "setgain()", WHERE));


  try {
    
    if(mode=="table") {
      os << LogIO::SEVERE << "Cannot yet read from table" << LogIO::POST;
      return False;
    }
    else {
      makeVisSet();
      if(gj_p) delete gj_p; gj_p = 0;
      gj_p =
	new SimGJones(*vs_p, seed_p, 
		      SimVisJones::normal, 1.0, amplitude(0),
		      SimVisJones::normal, 0.0, amplitude(1),
		      interval.get("s").getValue());
    }
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
}

Bool newsimulator::setbandpass(const String& mode, const String& table,
			    const Quantity& interval,
			    const Vector<Double>& amplitude) {
  
  LogIO os(LogOrigin("newsimulator", "setbandpass()", WHERE));
  
  try {
    
    if(mode=="table") {
      os << LogIO::SEVERE << "Cannot yet read from table" << LogIO::POST;
      return False;
    }
    else {
      os << LogIO::SEVERE << "Cannot yet calculate bandpass" << LogIO::POST;
      return False;
    }
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
}

Bool newsimulator::setpointingerror(const String& epJTableName,
				    const Bool applyPointingOffsets,
				    const Bool doPBCorrection)
{
  LogIO os(LogOrigin("newsimulator", "close()", WHERE));
  epJTableName_p = epJTableName;
  makeVisSet();
  if (epJ_p) delete epJ_p;epJ_p=0;
  try
    {
      epJ_p = new EPJones(*vs_p);
      epJ_p->load(epJTableName_p,"","diagonal");
    }
  catch (AipsError x)
    {
      os << LogIO::SEVERE << "Caught exception: "
	 << x.getMesg() << LogIO::POST;
      return False;
    }

  applyPointingOffsets_p = applyPointingOffsets;
  doPBCorrection_p = doPBCorrection;
  return True;
}

Bool newsimulator::setleakage(const String& mode, const String& table,
			      const Quantity& interval, const Double amplitude) 
{
  
  LogIO os(LogOrigin("newsimulator", "setleakage()", WHERE));
  
  try {
    
    if(mode=="table") {
      os << LogIO::SEVERE << "Cannot yet read from table" << LogIO::POST;
      return False;
    }
    else {
      makeVisSet();
      if(dj_p) delete dj_p; dj_p = 0;
      dj_p = new SimDJones(*vs_p,seed_p, 
			   SimVisJones::normal,0.0,amplitude,
			   interval.get("s").getValue());
    }
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
}

Bool newsimulator::reset() {
  LogIO os(LogOrigin("newsimulator", "simulate()", WHERE));
  try {
    
    if(gj_p) delete gj_p; gj_p=0;
    if(dj_p) delete dj_p; dj_p=0;
    if(pj_p) delete pj_p; pj_p=0;
    if(ac_p) delete ac_p; ac_p=0;
    if(vp_p) delete vp_p; vp_p=0;
    if(gvp_p) delete gvp_p; gvp_p=0;
    if(sim_p) delete sim_p; sim_p=0;
    if(epJ_p) delete epJ_p; epJ_p=0;
    
    os << "Reset all components" << LogIO::POST;

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
}

Bool newsimulator::corrupt() {
  
  LogIO os(LogOrigin("newsimulator", "corrupt()", WHERE));

  try {
    
    ms_p->lock();
    if(mssel_p) mssel_p->lock();
    makeVisSet();
    AlwaysAssert(vs_p, AipsError);
    VisIter& vi=vs_p->iter();
    VisBuffer vb(vi);
    
    // -----------------------------------------------------------
    // Make and initialize the Measurement Equations i.e. Vis and 
    // Sky Equations
    VisEquation ve(*vs_p);

    // set corruption terms
    if (ac_p) ve.setACoh(*ac_p);
    if (pj_p) ve.setVisJones(*pj_p);
    if (gj_p) ve.setVisJones(*gj_p);
    if (dj_p) ve.setVisJones(*dj_p);
    if (bj_p) ve.setVisJones(*bj_p);
    
    // Corruption applies the gains and errors to the OBSERVED column,
    // and puts the result in BOTH the OBSERVED and CORRECTED columns
    ve.corrupt();      
    
    ms_p->unlock();
    if(mssel_p) mssel_p->unlock();

  } catch (AipsError x) {
    ms_p->unlock();
    if(mssel_p) mssel_p->unlock();
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
}

Bool newsimulator::setlimits(const Double shadowLimit,
			  const Quantity& elevationLimit)
{
  
  LogIO os(LogOrigin("newsimulator", "setlimits()", WHERE));
  
  try {
    
    sim_p->setFractionBlockageLimit( shadowLimit );
    sim_p->setElevationLimit( elevationLimit );
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
}
      
Bool newsimulator::setauto(const Float autocorrwt) 
{
  
  LogIO os(LogOrigin("newsimulator", "setauto()", WHERE));
  
  try {
    
    sim_p->setAutoCorrelationWt(autocorrwt);

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
}
      
void newsimulator::makeVisSet() {

  if(vs_p) return;
  
  Block<int> sort(0);
  sort.resize(5);
  sort[0] = MS::FIELD_ID;
  sort[1] = MS::FEED1;
  sort[2] = MS::ARRAY_ID;
  sort[3] = MS::DATA_DESC_ID;
  sort[4] = MS::TIME;
  Matrix<Int> noselection;
  if(mssel_p) {
    vs_p = new VisSet(*mssel_p,sort,noselection);
  }
  else {
    vs_p = new VisSet(*ms_p,sort,noselection);
  }
  AlwaysAssert(vs_p, AipsError);
  
}

Bool newsimulator::observe(const String&   sourcename,
			   const String&   spwname,
			   const Quantity& startTime, 
			   const Quantity& stopTime)
{
  LogIO os(LogOrigin("newsimulator", "observe()", WHERE));
  

  try {
    
    if(!feedsHaveBeenSet && !feedsInitialized) {
      os << "Feeds have not been set - using default " << feedMode_p << LogIO::WARN;
      sim_p->initFeeds(feedMode_p);
      feedsInitialized = True;
    }
    if(!timesHaveBeenSet_p) {
      os << "Times have not been set - using defaults " << endl
	 << "     Times will be interpreted as hour angles for first source"
	 << LogIO::WARN;
    }

    sim_p->observe(sourcename, spwname, startTime, stopTime);

    if(ms_p) delete ms_p; ms_p=0;
    if(mssel_p) delete mssel_p; mssel_p=0;
    ms_p = new MeasurementSet(msname_p, Table::Update);

    ms_p->flush();

    ms_p->unlock();

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
}

Bool newsimulator::predict(const Vector<String>& modelImage, 
			   const String& compList,
			   const Bool incremental) {
  
  LogIO os(LogOrigin("newsimulator", "predict()", WHERE));
  
  // Note that incremental here does not apply to se_p->predict(False),
  // Rather it means: add the calculated model visibility to the data visibility.
  // We return a MS with Data, Model, and Corrected columns identical

  try {

    os << "Predicting visibilities using model: " << modelImage << 
      " and componentList: " << compList << LogIO::POST;
    if (incremental) {
      os << "The data column will be incremented" <<  LogIO::POST;
    } else {
      os << "The data column will be replaced" <<  LogIO::POST;
    }
    if(!ms_p) {
      os << "MeasurementSet pointer is null : logic problem!"
	 << LogIO::EXCEPTION;
    }
    ms_p->lock();   
    if(mssel_p) mssel_p->lock();   
    if (!createSkyEquation( modelImage, compList)) {
      os << LogIO::SEVERE << "Failed to create SkyEquation" << LogIO::POST;
      return False;
    }
    se_p->predict(False);
    destroySkyEquation();

    // Copy the predicted visibilities over to the observed and 
    // the corrected data columns
    makeVisSet();

    VisIter& vi = vs_p->iter();
    VisBuffer vb(vi);
    vi.origin();
    vi.originChunks();

    os << "Copying predicted visibilities from MODEL_DATA to DATA and CORRECTED_DATA" << LogIO::POST;

    for (vi.originChunks();vi.moreChunks();vi.nextChunk()){
      for (vi.origin(); vi.more(); vi++) {
	//	vb.setVisCube(vb.modelVisCube());

	if (incremental) {
	  vi.setVis( (vb.modelVisCube() + vb.visCube()),
		     VisibilityIterator::Corrected);
	  vi.setVis(vb.correctedVisCube(),VisibilityIterator::Observed);
	  vi.setVis(vb.correctedVisCube(),VisibilityIterator::Model);
	} else {
	  vi.setVis(vb.modelVisCube(),VisibilityIterator::Observed);
	  vi.setVis(vb.modelVisCube(),VisibilityIterator::Corrected);
	}
      }
    }
    ms_p->unlock();     
    if(mssel_p) mssel_p->lock();   

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    ms_p->unlock();     
    if(mssel_p) mssel_p->lock();   
    return False;
  } 
  return True;
}

Bool newsimulator::createSkyEquation(const Vector<String>& image,
				     const String complist)
{

  LogIO os(LogOrigin("newsimulator", "createSkyEquation()", WHERE));

  try {
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
    } else {
      componentList_p=0;
    }
    
    nmodels_p = image.nelements();
    if (nmodels_p == 1 && image(0) == "") nmodels_p = 0;
    
    if (nmodels_p > 0) {
      images_p.resize(nmodels_p); 
      
      for (Int model=0;model<Int(nmodels_p);model++) {
	if(image(model)=="") {
	  os << LogIO::SEVERE << "Need a name for model "  << model+1
	     << LogIO::POST;
	  return False;
	} else {
	  if(!Table::isReadable(image(model))) {
	    os << LogIO::SEVERE << image(model) << " is unreadable" << LogIO::POST;
	  } else {
	    images_p[model]=0;
	    os << "About to open model " << model+1 << " named "
	       << image(model) << LogIO::POST;
	    images_p[model]=new PagedImage<Float>(image(model));

	    AlwaysAssert(images_p[model], AipsError);
	    // Add distance
	    if(abs(distance_p.get().getValue())>0.0) {
	      os << "  Refocusing to distance " << distance_p.get("km").getValue()
		 << " km" << LogIO::POST;
	    }
	    Record info(images_p[model]->miscInfo());
	    info.define("distance", distance_p.get("m").getValue());
	    images_p[model]->setMiscInfo(info);
	    if(sm_p->add(*images_p[model])!=model) {
	      os << LogIO::SEVERE << "Error adding model " << model+1 << LogIO::POST;
	      return False;
	    }
	  }
	}
      }
    }
    
    
    if(vs_p) {
      delete vs_p; vs_p=0;
    }
    makeVisSet();
    
    cft_p = new SimpleComponentFTMachine();
    
    MeasurementSet *ams=0;
    
    if(mssel_p) {
      ams=mssel_p;
    }
    else {
      ams=ms_p;
    }
    if((ftmachine_p=="sd")||(ftmachine_p=="both")||(ftmachine_p=="mosaic")) {
      if(!gvp_p) {
	os << "Using default primary beams for gridding" << LogIO::POST;
	gvp_p=new VPSkyJones(*ams, True, parAngleInc_p, squintType_p);
      }
      if(ftmachine_p=="sd") {
	os << "Single dish gridding " << LogIO::POST;
	if(gridfunction_p=="pb") {
	  ft_p = new SDGrid(*ams, *gvp_p, cache_p/2, tile_p, gridfunction_p);
	}
	else {
	  ft_p = new SDGrid(*ams, cache_p/2, tile_p, gridfunction_p);
	}
      }
      else if(ftmachine_p=="mosaic") {
	os << "Performing Mosaic gridding" << LogIO::POST;
	ft_p = new MosaicFT(*ams, *gvp_p, cache_p/2, tile_p, True);
      }
      else if(ftmachine_p=="both") {
	os << "Performing single dish gridding with convolution function "
	   << gridfunction_p << LogIO::POST;
	os << "and interferometric gridding with convolution function SF"
	   << LogIO::POST;
	
	ft_p = new GridBoth(*ams, *gvp_p, cache_p/2, tile_p,
			    mLocation_p, 
			    gridfunction_p, "SF", padding_p);
      }
      
      VisIter& vi(vs_p->iter());
      // Get bigger chunks o'data: this should be tuned some time
      // since it may be wrong for e.g. spectral line
      vi.setRowBlocking(100);
    }
    else {
      os << "Synthesis gridding " << LogIO::POST;
      // Now make the FTMachine
      //    if(wprojPlanes_p>1) {
      if (ftmachine_p=="wproject") {
	os << "Fourier transforms will use specified common tangent point:" << LogIO::POST;
	os << formatDirection(sourceDirection_p) << LogIO::POST;
	//      ft_p = new WProjectFT(*ams, facets_p, cache_p/2, tile_p, False);
	ft_p = new WProjectFT(*ams, wprojPlanes_p, cache_p/2, tile_p, False);
      }
      else if (ftmachine_p=="pbwproject") {
	os << "Fourier transfroms will use specified common tangent point and PBs" 
	   << LogIO::POST;
	os << formatDirection(sourceDirection_p) << LogIO::POST;
	
	if (!epJ_p)
	  os << "Antenna pointing related term (EPJones) not set.  "
	     << "This is required when using pbwproject FTMachine." 
	     << LogIO::EXCEPTION;
	doVP_p = False; // Since this FTMachine includes PB
	if (wprojPlanes_p<=1)
	  {
	    os << LogIO::NORMAL
	       << "You are using wprojplanes=1. Doing co-planar imaging "
	       << "(no w-projection needed)" 
	       << LogIO::POST;
	    os << "Performing pb-projection"
	       << LogIO::POST;
	  }
	if((wprojPlanes_p>1)&&(wprojPlanes_p<64)) 
	  {
	    os << LogIO::WARN
	       << "No. of w-planes set too low for W projection - recommend at least 128"
	       << LogIO::POST;
	    os << "Performing pb + w-plane projection"
	       << LogIO::POST;
	  }
	/*
	  epJ_p = new EPJones(*vs_p);
	  epJ_p->load(epJTableName_p,"","diagonal");
	*/
	if(!gvp_p) 
	  {
	    os << "Using defaults for primary beams used in gridding" << LogIO::POST;
	    gvp_p=new VPSkyJones(*ms_p, True, parAngleInc_p, squintType_p);
	  }
	/*
	  ft_p = new PBWProjectFT(*ms_p, epJ, gvp_p, facets_p, cache_p/2, 
	  doPointing, tile_p, paStep_p, 
	  pbLimit_p, True);
	*/
	String cfCacheDirName = "cache";
	if (mssel_p)
	  ft_p = new PBWProjectFT(*mssel_p, epJ_p, /*gvp_p,*/ wprojPlanes_p, cache_p/2, 
				  cfCacheDirName,
				  applyPointingOffsets_p, doPBCorrection_p, 
				  tile_p, 
				  0.0, /* Not required here. parAngleInc_p is used in gvp_p */
				  pbLimit_p, True);
	else
	  ft_p = new PBWProjectFT(*ms_p, epJ_p, /*gvp_p,*/ wprojPlanes_p, cache_p/2, 
				  cfCacheDirName,
				  applyPointingOffsets_p, doPBCorrection_p, 
				  tile_p, 
				  0.0, /* Not required here. parAngleInc_p is used in gvp_p */
				  pbLimit_p, True);
	AlwaysAssert(ft_p, AipsError);
	cft_p = new SimpleComponentFTMachine();
	AlwaysAssert(cft_p, AipsError);
      }
      else {
	os << "Fourier transforms will use image centers as tangent points" << LogIO::POST;
	ft_p = new GridFT(cache_p/2, tile_p, gridfunction_p, mLocation_p, padding_p);
      }
    }
    AlwaysAssert(ft_p, AipsError);
    
    se_p = new SkyEquation ( *sm_p, *vs_p, *ft_p, *cft_p );
    
    // Now add any SkyJones that are needed
    if(doVP_p) {
      if (doDefaultVP_p) {
	os << "Using default primary beams for mosaicing (use setvp to change)" << LogIO::POST;
	vp_p=new VPSkyJones(*ams, True, parAngleInc_p, squintType_p, skyPosThreshold_p);
      } else {
	Table vpTable( vpTableStr_p );
	vp_p=new VPSkyJones(*ams, vpTable, parAngleInc_p, squintType_p);
      }
      vp_p->summary();
      se_p->setSkyJones(*vp_p);
    }
    else {
      vp_p=0;
    }
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    ms_p->unlock();     
    if(mssel_p) mssel_p->lock();   
    return False;
  } 
  return True;
};

void newsimulator::destroySkyEquation() 
{
  if(se_p) delete se_p; se_p=0;
  if(sm_p) delete sm_p; sm_p=0;
  if(vp_p) delete vp_p; vp_p=0;
  if(componentList_p) delete componentList_p; componentList_p=0;

  for (Int model=0;model<Int(nmodels_p);model++) {
    if(images_p[model]) delete images_p[model]; images_p[model]=0;
  }
};



Bool newsimulator::setoptions(const String& ftmachine, const Int cache, const Int tile,
			      const String& gridfunction, const MPosition& mLocation,
			      const Float padding, const Int facets, const Double maxData,
			      const Int wprojPlanes)
{
  LogIO os(LogOrigin("newsimulator", "setoptions()", WHERE));
  
  os << "Setting processing options" << LogIO::POST;
  
  sim_p->setMaxData(maxData*1024.0*1024.0);

  ftmachine_p=downcase(ftmachine);
  if(cache>0) cache_p=cache;
  if(tile>0) tile_p=tile;
  gridfunction_p=downcase(gridfunction);
  mLocation_p=mLocation;
  if(padding>=1.0) {
    padding_p=padding;
  }
  facets_p=facets;
  wprojPlanes_p = wprojPlanes;
  // Destroy the FTMachine
  if(ft_p) {delete ft_p; ft_p=0;}
  if(cft_p) {delete cft_p; cft_p=0;}

  return True;
}



String newsimulator::className() const
{
  return "newsimulator";
}

Vector<String> newsimulator::methods() const
{
  Vector<String> method(NUM_METHODS);

  method(OBSERVE)="observe";
  method(PREDICT)="predict";
  method(CORRUPT)="corrupt";
  method(SETDATA)="setdata";
  method(RESET)="reset";
  method(STATE)="state";
  method(NAME)="name";
  method(SUMMARY)="summary";
  method(SETSEED)="setseed";
  method(SETGAIN)="setgain";
  method(SETNOISE)="setnoise";
  method(SETLEAKAGE)="setleakage";
  method(SETPOINTINGERROR)="setpointingerror";
  method(SETPA)="setpa";
  method(SETBANDPASS)="setbandpass";
  method(SETOPTIONS)="setoptions";
  method(SETFEED)="setfeed";
  method(SETTIMES)="settimes";
  method(SETCONFIG)="setconfig";
  method(SETFIELD)="setfield";
  method(SETSPWINDOW)="setspwindow";
  method(SETVP)="setvp";
  method(SETLIMITS)="setlimits";
  method(SETAUTO)="setauto";
  method(SETSEED)="setseed";
  return method;
}

Vector<String> newsimulator::noTraceMethods() const
{
  Vector<String> method(2);
  Int i=0;
  method(i++) = "state";
  method(i++) = "name";
  
  return method;
}

MethodResult newsimulator::runMethod(uInt which, 
				     ParameterSet &inputRecord,
				     Bool runMethod)
{
  
  static String returnvalString = "returnval";
  
  switch (which) {
  case OBSERVE: // observe
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<String>     sourcename(inputRecord, "sourcename", ParameterSet::In);
      Parameter<String>     spwname(inputRecord, "spwname", ParameterSet::In);
      Parameter<Quantity>   starttime(inputRecord, "starttime", ParameterSet::In);
      Parameter<Quantity>   stoptime(inputRecord, "stoptime", ParameterSet::In);

      if (runMethod) {
	returnval() = observe(sourcename(), spwname(), 
			      starttime(), stoptime());
      }
    }
    break;
  case SETTIMES: // settimes
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<Quantity>   integrationtime(inputRecord, "integrationtime", ParameterSet::In);
      Parameter< Bool >     usehourangle(inputRecord, "usehourangle", ParameterSet::In);
      Parameter<MEpoch>     referencetime(inputRecord, "referencetime", ParameterSet::In);

      if (runMethod) {
	returnval() = settimes (integrationtime(), usehourangle(), referencetime() );
      }
    }
    break;
  case PREDICT: // predict
    { 
      Parameter<Vector<String> > modelimage(inputRecord, "modelimage", ParameterSet::In); 
      Parameter<String> complist(inputRecord, "complist", ParameterSet::In); 
      Parameter<Bool>   incremental(inputRecord, "incremental", ParameterSet::In); 
      Parameter< Bool > 
	returnval(inputRecord, returnvalString, ParameterSet::Out); 
      if (runMethod) { 
	returnval() = 
	  predict ( modelimage(), complist(), incremental() ); 
      } 
    } 
    break; 
  case CORRUPT: // corrupt
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      
      if (runMethod) { 
	returnval() = corrupt();
      }
    }
    break;
  case RESET: // reset
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      
      if (runMethod) { 
	returnval() = reset();
      }
    }
    break;
  case STATE: // state
    {
      Parameter< String >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = state(); // DOIT
      }
    }
    break;
  case NAME: // name
    {
      Parameter< String >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = name(); // DOIT
      }
    }
    break;
  case SUMMARY: // summary
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = summary();
      }
    }
    break;
  case SETLIMITS: // setlimits
    {
      Parameter<Double>   shadowlimit(inputRecord, "shadowlimit", ParameterSet::In);
      Parameter<Quantity> elevationlimit(inputRecord, "elevationlimit", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = setlimits(shadowlimit(), elevationlimit());
      }
    }
    break; 
  case SETAUTO: // setauto
    {
      Parameter<Float>    autocorrwt(inputRecord, "autocorrwt", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = setauto(autocorrwt());
      }
    }
    break; 
  case SETSEED: // setseed
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      
      Parameter<Int> seed(inputRecord, "seed", ParameterSet::In);
      
      if (runMethod) {
	returnval() = setseed(seed());
      }
    }
    break;
  case SETGAIN: // setgain
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      Parameter<String>  mode(inputRecord, "mode", ParameterSet::In);
      Parameter<String>  table(inputRecord, "table", ParameterSet::In);
      Parameter<Quantity> interval(inputRecord, "interval", ParameterSet::In);
      Parameter<Vector<Double> >amplitude(inputRecord, "amplitude",
					  ParameterSet::In);
      if (runMethod) {
	returnval() = setgain(mode(), table(), interval(), amplitude());
      }
    }
    break;
  case SETNOISE: // setnoise
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      Parameter<String>  mode(inputRecord, "mode", ParameterSet::In);
      Parameter<Quantity>  simplenoise(inputRecord, "simplenoise", ParameterSet::In);
      Parameter<String>  table(inputRecord, "table", ParameterSet::In);
      Parameter<Float>  antefficiency(inputRecord, "antefficiency", ParameterSet::In);
      Parameter<Float>  correfficiency(inputRecord, "correfficiency", ParameterSet::In);
      Parameter<Float>  spillefficiency(inputRecord, "spillefficiency", ParameterSet::In);
      Parameter<Float>  tau(inputRecord, "tau", ParameterSet::In);
      Parameter<Float>  trx(inputRecord, "trx", ParameterSet::In);
      Parameter<Float>  tatmos(inputRecord, "tatmos", ParameterSet::In);
      Parameter<Float>  tcmb(inputRecord, "tcmb", ParameterSet::In);
       
      if (runMethod) {
	returnval() = setnoise(mode(), simplenoise(), table(), antefficiency(), 
			       correfficiency(), spillefficiency(), tau(), 
			       trx(), tatmos(), tcmb());
      }
    }
    break;
  case SETPOINTINGERROR: // setpointingerror
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      Parameter<String>  table(inputRecord, "table", ParameterSet::In);
      Parameter<Bool> pointing(inputRecord,"dopointing", ParameterSet::In);
      Parameter<Bool> pbcorr(inputRecord,"dopbcorrection", ParameterSet::In);
      
      if (runMethod) {
	returnval() = setpointingerror(table(), pointing(), pbcorr());
      }
    }
    break;
  case SETLEAKAGE: // setleakage
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      Parameter<String>  mode(inputRecord, "mode", ParameterSet::In);
      Parameter<String>  table(inputRecord, "table", ParameterSet::In);
      Parameter<Quantity> interval(inputRecord, "interval", ParameterSet::In);
      Parameter<Double> amplitude(inputRecord, "amplitude",
				  ParameterSet::In);
      
      if (runMethod) {
	returnval() = setleakage(mode(), table(), interval(), amplitude());
      }
    }
    break;
  case SETPA: // setpa
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      Parameter<String>  mode(inputRecord, "mode", ParameterSet::In);
      Parameter<String>  table(inputRecord, "table", ParameterSet::In);
      Parameter<Quantity> interval(inputRecord, "interval", ParameterSet::In);
      
      if (runMethod) { 
	returnval() = setpa(mode(), table(), interval());
      }
    }
    break;
  case SETBANDPASS: // setbandpass
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      Parameter<String>  mode(inputRecord, "mode", ParameterSet::In);
      Parameter<String>  table(inputRecord, "table", ParameterSet::In);
      Parameter<Quantity> interval(inputRecord, "interval", ParameterSet::In);
      Parameter<Vector<Double> > amplitude(inputRecord, "amplitude",
					   ParameterSet::In);
      
      if (runMethod) { 
	returnval() = setbandpass(mode(), table(), interval(), amplitude());
      }
    }
    break;
  case SETOPTIONS: // setoptions
    {
      Parameter<String> ftmachine(inputRecord, "ftmachine", ParameterSet::In);
      Parameter<Int> cache(inputRecord, "cache", ParameterSet::In);
      Parameter<Int> tile(inputRecord, "tile", ParameterSet::In);
      Parameter<String> gridfunction(inputRecord, "gridfunction",
				     ParameterSet::In);
      Parameter<MPosition> mlocation(inputRecord, "location",
				     ParameterSet::In);
      Parameter<Float> padding(inputRecord, "padding", ParameterSet::In);
      Parameter<Int> facets(inputRecord, "facets", ParameterSet::In);
      Parameter<Int> wprojPlanes(inputRecord, "wprojplanes", ParameterSet::In);
      Parameter<Double> maxdata(inputRecord, "maxdata", ParameterSet::In);
      

      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  setoptions (ftmachine(), cache(), tile(), gridfunction(),
		      mlocation(), padding(), facets(), maxdata(),wprojPlanes());
      }
    }
    break;
  case SETCONFIG: // setconfig
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<String >  	  telescopename(inputRecord, "telescopename", ParameterSet::In);
      Parameter<Vector<Double> >  x(inputRecord, "x", ParameterSet::In);
      Parameter<Vector<Double> >  y(inputRecord, "y", ParameterSet::In);
      Parameter<Vector<Double> >  z(inputRecord, "z", ParameterSet::In);
      Parameter<Vector<Double> >   diam(inputRecord, "dishdiameter", ParameterSet::In);
      Parameter<Vector<Double> >   offset(inputRecord, "offset", ParameterSet::In);
      Parameter<Vector<String> >  mount(inputRecord, "mount", ParameterSet::In);
      Parameter<Vector<String> >  antname(inputRecord, "antname", ParameterSet::In);
      Parameter<String>  coordsystem(inputRecord, "coordsystem", ParameterSet::In);
      Parameter<MPosition> mReferenceLocation(inputRecord, "referencelocation", ParameterSet::In);

      if (runMethod) {
	returnval() = setconfig (telescopename(), x(), y(), z(), diam(), offset(),
				 mount(), antname(), coordsystem(), mReferenceLocation());
      }
    }
    break;
  case SETFIELD: // setfield
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<String> sourcename(inputRecord, "sourcename", ParameterSet::In);
      Parameter<MDirection>   sourcedirection(inputRecord, "sourcedirection",
					      ParameterSet::In);
      Parameter<String> calcode(inputRecord, "calcode", ParameterSet::In);
      Parameter<Quantity> distance(inputRecord, "distance", ParameterSet::In);
      if (runMethod) {
	returnval() = setfield (sourcename(), sourcedirection(), calcode(), distance());
      }
    }
    break;
  case SETSPWINDOW: // setspwindow
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<String>		spwname(inputRecord, "spwname", ParameterSet::In);
      Parameter<Quantity>   	freq(inputRecord, "freq", ParameterSet::In);
      Parameter<Quantity>   	deltafreq(inputRecord, "deltafreq", ParameterSet::In);
      Parameter<Quantity>   	freqresolution(inputRecord, "freqresolution", ParameterSet::In);
      Parameter<Int>   		nchannels(inputRecord, "nchannels", ParameterSet::In);
      Parameter<String>   	stokes(inputRecord, "stokes", ParameterSet::In);

      if (runMethod) {
	returnval() = setspwindow (spwname(), freq(), deltafreq(),
				   freqresolution(), nchannels(), stokes());
      }
    }
    break;
  case SETFEED: // setfeed
    {
      Parameter< Bool>
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<String>  mode(inputRecord, "mode", ParameterSet::In);
      Parameter<Vector<Double> > x(inputRecord, "x", ParameterSet::In);
      Parameter<Vector<Double> > y(inputRecord, "y", ParameterSet::In);
      Parameter<Vector<String> > pol(inputRecord, "pol", ParameterSet::In);

      if (runMethod) {
	returnval() = setfeed (mode(), x(), y(), pol());
      }
    }
    break;
  case SETVP: // setvp
    {
      Parameter< Bool>
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<Bool>  dovp(inputRecord, "dovp", ParameterSet::In);
      Parameter<Bool>  usedefaultvp(inputRecord, "usedefaultvp", ParameterSet::In);
      Parameter<String>  vptable(inputRecord, "vptable", ParameterSet::In);
      Parameter<Bool> dosquint(inputRecord, "dosquint", ParameterSet::In);
      Parameter<Quantity> parangleinc(inputRecord, "parangleinc", ParameterSet::InOut);
      Parameter<Quantity> skyposthreshold(inputRecord, "skyposthreshold", ParameterSet::In);
      Parameter<Float> pblimit(inputRecord, "pblimit", ParameterSet::In);

      if (runMethod) {
	returnval() = setvp (dovp(), usedefaultvp(), vptable(), dosquint(), parangleinc(),
	                     skyposthreshold(), pblimit());
      }
    }
    break;
  case SETDATA: // setdata
    {
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
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = setdata (spws, fids, msSelect());
      }
    }
    break;
  default:
    return error("No such method");
  }
  return ok();
}


Bool newsimulator::detached() const
{
  return False;
}

String newsimulator::formatDirection(const MDirection& direction) {
  MVAngle mvRa=direction.getAngle().getValue()(0);
  MVAngle mvDec=direction.getAngle().getValue()(1);
  ostringstream oss;
  oss.setf(ios::left, ios::adjustfield);
  oss.width(14);
  oss << mvRa(0.0).string(MVAngle::TIME,8);
  oss.width(14);
  oss << mvDec.string(MVAngle::DIG2,8);
  oss << "     " << MDirection::showType(direction.getRefPtr()->getType());
  return String(oss);
}

String newsimulator::formatTime(const Double time) {
  MVTime mvtime(Quantity(time, "s"));
  return mvtime.string(MVTime::DMY,7);
}

Bool newsimulator::setdata(const Vector<Int>& spectralwindowids,
			   const Vector<Int>& fieldids,
			   const String& msSelect)
  
{

  
  LogIO os(LogOrigin("newsimulator", "setdata()", WHERE));

  if(!ms_p) {
    os << LogIO::SEVERE << "Program logic error: MeasurementSet pointer ms_p not yet set"
       << LogIO::POST;
    return False;
  }

  try {
    
    os << "Selecting data" << LogIO::POST;
    
   // Map the selected spectral window ids to data description ids
    MSDataDescColumns dataDescCol(ms_p->dataDescription());
    Vector<Int> ddSpwIds=dataDescCol.spectralWindowId().getColumn();

    Vector<Int> datadescids(0);
    for (uInt row=0; row<ddSpwIds.nelements(); row++) {
      Bool found=False;
      for (uInt j=0; j<spectralwindowids.nelements(); j++) {
	if (ddSpwIds(row)==spectralwindowids(j)) found=True;
      };
      if (found) {
	datadescids.resize(datadescids.nelements()+1,True);
	datadescids(datadescids.nelements()-1)=row;
      };
    };

    if(vs_p) delete vs_p; vs_p=0;
    if(mssel_p) delete mssel_p; mssel_p=0;
      
    // If a selection has been made then close the current MS
    // and attach to a new selected MS. We do this on the original
    // MS. 
    if(fieldids.nelements()>0||datadescids.nelements()>0) {
      os << "Performing selection on MeasurementSet" << LogIO::POST;
      Table& original=*ms_p;
      
      // Now we make a condition to do the old FIELD_ID, SPECTRAL_WINDOW_ID
      // selection
      TableExprNode condition;
      String colf=MS::columnName(MS::FIELD_ID);
      String cols=MS::columnName(MS::DATA_DESC_ID);
      if(fieldids.nelements()>0&&datadescids.nelements()>0){
	condition=original.col(colf).in(fieldids)&&original.col(cols).in(datadescids);
        os << "Selecting on field and spectral window ids" << LogIO::POST;
      }
      else if(datadescids.nelements()>0) {
	condition=original.col(cols).in(datadescids);
        os << "Selecting on spectral window id" << LogIO::POST;
      }
      else if(fieldids.nelements()>0) {
	condition=original.col(colf).in(fieldids);
        os << "Selecting on field id" << LogIO::POST;
      }
      
      // Now remake the original ms
      mssel_p = new MeasurementSet(original(condition));

      AlwaysAssert(mssel_p, AipsError);
      mssel_p->rename(msname_p+"/SELECTED_TABLE", Table::Scratch);
      if(mssel_p->nrow()==0) {
	delete mssel_p; mssel_p=0;
	os << LogIO::WARN
	   << "Selection is empty: reverting to original MeasurementSet"
	   << LogIO::POST;
	mssel_p=new MeasurementSet(original);
      }
      else {
	mssel_p->flush();
      }

    }
    else {
      mssel_p=new MeasurementSet(*ms_p);
    }
    {
      Int len = msSelect.length();
      Int nspace = msSelect.freq (' ');
      Bool nullSelect=(msSelect.empty() || nspace==len);
      if (!nullSelect) {
	os << "Now applying selection string " << msSelect << LogIO::POST;
	MeasurementSet* mssel_p2;
	// Apply the TAQL selection string, to remake the original MS
	String parseString="select from $1 where " + msSelect;
	mssel_p2=new MeasurementSet(tableCommand(parseString,*mssel_p));
	AlwaysAssert(mssel_p2, AipsError);
	// Rename the selected MS as */SELECTED_TABLE2
	mssel_p2->rename(msname_p+"/SELECTED_TABLE2", Table::Scratch); 
	if (mssel_p2->nrow()==0) {
	  os << LogIO::WARN
	     << "Selection string results in empty MS: "
	     << "reverting to original MeasurementSet"
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
    makeVisSet();

    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg()
       << LogIO::POST;
    return False;
  } 
  return True;
}

