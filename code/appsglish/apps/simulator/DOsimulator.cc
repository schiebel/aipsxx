//# simulator.cc: Simulation test-bed program
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
//# $Id: DOsimulator.cc,v 19.15 2005/12/06 20:18:50 wyoung Exp $

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
#include <ms/MeasurementSets/MSSimulator.h>

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
#include <synthesis/MeasurementComponents/WFCleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/ImageSkyModel.h>
#include <synthesis/MeasurementComponents/SimACohCalc.h>
#include <synthesis/MeasurementComponents/SimACoh.h>
#include <synthesis/MeasurementComponents/SimVisJones.h>
#include <synthesis/MeasurementComponents/VPSkyJones.h>
#include <synthesis/MeasurementEquations/StokesImageUtil.h>
#include <lattices/Lattices/LatticeExpr.h> 

#include <appsglish/simulator/DOsimulator.h>

#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/Index.h>
#include <tasking/Tasking/MethodResult.h>
#include <casa/System/PGPlotter.h>
#include <tasking/Tasking/ObjectController.h>
#include <synthesis/MeasurementComponents/CleanImageSkyModel.h>
#include <synthesis/MeasurementComponents/GridBoth.h>
#include <synthesis/MeasurementComponents/MosaicFT.h>
#include <synthesis/MeasurementComponents/SimpleComponentFTMachine.h>
#include <casa/OS/HostInfo.h>
#include <images/Images/PagedImage.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/Vector.h>
#include <casa/sstream.h>

#include <tables/Tables/SetupNewTab.h>
#include <casa/Logging/LogSink.h>

#include <casa/namespace.h>
simulator::simulator() 
  : msname_p(""), ms_p(0), vs_p(0), seed_p(11111),
    gj_p(0), pj_p(0), dj_p(0), bj_p(0), ac_p(0), vp_p(0), gvp_p(0)
{
  defaults();
}

simulator::simulator(MeasurementSet &theMs)
  : msname_p(""), ms_p(0), vs_p(0), seed_p(11111),
    gj_p(0), pj_p(0), dj_p(0), bj_p(0), ac_p(0), vp_p(0), gvp_p(0)
{
  defaults();
  open(theMs);
}

simulator::simulator(const simulator &other)
  : msname_p(""), ms_p(0), vs_p(0), seed_p(11111),
    gj_p(0), pj_p(0), dj_p(0), bj_p(0), ac_p(0), vp_p(0), gvp_p(0)
{
  defaults();
  open(*(other.ms_p));
}

simulator &simulator::operator=(const simulator &other)
{
  if (ms_p && this != &other) {
    *ms_p = *(other.ms_p);
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
  return *this;
}

simulator::~simulator()
{
  if (ms_p) {
    delete ms_p;
  }
  ms_p = 0;
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

  if(sm_p) delete sm_p; sm_p = 0;
  if(ft_p) delete ft_p; ft_p = 0;
  if(cft_p) delete cft_p; cft_p = 0;
  if(vp_p) delete vp_p; vp_p = 0;
  if(gvp_p) delete gvp_p; gvp_p = 0;
}



void simulator::defaults()
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
  mLocation_p=MPosition();
  sm_p = 0;
  ft_p = 0;
  cft_p = 0;
  vp_p = 0;
  gvp_p = 0;
  images_p = 0;
  nmodels_p = 1;
  // info for configurations
  areStationCoordsSet_p = False;
  telescope_p = "";
  nmodels_p = 0;

  // info for fields and schedule:
  nDeltaRows_p = 20;
  nSources_p = 0;
  sourceName_p.resize(nDeltaRows_p);  sourceName_p.set("");
  sourceDirection_p.resize(nDeltaRows_p);
  intsPerPointing_p.resize(nDeltaRows_p);  intsPerPointing_p.set(0);
  mosPointingsX_p.resize(nDeltaRows_p);  mosPointingsX_p.set(0);
  mosPointingsY_p.resize(nDeltaRows_p);  mosPointingsY_p.set(0);
  mosSpacing_p.resize(nDeltaRows_p);  mosSpacing_p.set(0);
  distance_p.resize(nDeltaRows_p);  distance_p.set(Quantity(0.0, "m"));

  // info for spectral windows
  nSpWindows_p = 0;
  spWindowName_p.resize(nDeltaRows_p);	spWindowName_p.set("");
  nChan_p.resize(nDeltaRows_p);		nChan_p.set(0);
  startFreq_p.resize(nDeltaRows_p);	startFreq_p.set(Quantity(0.0, "GHz"));
  freqInc_p.resize(nDeltaRows_p);	freqInc_p.set(Quantity(0.0, "MHz")); 
  freqRes_p.resize(nDeltaRows_p);	freqRes_p.set(Quantity(0.0, "MHz"));
  stokesString_p.resize(nDeltaRows_p);	stokesString_p.set("");

  // feeds
  feedMode_p = "perfect R L";
  nFeeds_p = 1;
  feedsHaveBeenSet = False;

  // times
  integrationTime_p = Quantity(0.0, "s");
  gapTime_p = Quantity(0.0, "s");
  startTime_p = Quantity(0.0, "s");
  stopTime_p = Quantity(0.0, "s");
  refTime_p = Quantity(0.0, "s");

  // VP stuff
  doVP_p=False;
  doDefaultVP_p = True;

  // For HISTORY table logging
  logSink_p=LogSink(LogMessage::NORMAL, False);
  hist_p=0;
  histLockCounter_p=0;
};


Bool simulator::open(MeasurementSet& theMs)
{
  logSink_p.clearLocally();
  LogIO os(LogOrigin("simulator", "open()"), logSink_p);
  
  if (ms_p) {
    *ms_p = theMs;
  } else {
    ms_p = new MeasurementSet(theMs);
    AlwaysAssert(ms_p, AipsError);
  }
  
  try {
    ms_p->lock();
    msname_p = ms_p->tableName();
    
    os << "Opening MeasurementSet " << msname_p << LogIO::POST;

    //// Write LogIO to HISTORY Table in MS
    if(!(Table::isReadable(ms_p->historyTableName()))){
      // Create a new HISTORY table if its not already there
      TableRecord &kws = ms_p->rwKeywordSet();
      SetupNewTable historySetup(ms_p->historyTableName(),
				 MSHistory::requiredTableDesc(),Table::New);
      kws.defineTable(MS::keywordName(MS::HISTORY), Table(historySetup));
    }
    historytab_p=Table(ms_p->historyTableName(),
		       TableLock(TableLock::UserNoReadLocking), Table::Update);
    hist_p= new MSHistoryHandler(*ms_p, "simulator");
    ////

    Bool initialize=(!ms_p->tableDesc().isColumn("CORRECTED_DATA"));
    
    if(vs_p) {
      delete vs_p; vs_p=0;
    }
    
    // Now create the VisSet
    // this sort order is to speed the mosaicing processing 
    Block<int> sort(4);
    sort[0] = MS::FIELD_ID;
    sort[1] = MS::ARRAY_ID;
    sort[2] = MS::DATA_DESC_ID;
    sort[3] = MS::TIME;

    Matrix<Int> noselection;
    vs_p = new VisSet(*ms_p,sort,noselection);
    AlwaysAssert(vs_p, AipsError);
    
    // Polarization
    MSColumns msc(*ms_p);
    Vector<String> polType=msc.feed().polarizationType()(0);
    if (polType(0)!="X" && polType(0)!="Y" &&
	polType(0)!="R" && polType(0)!="L") {
      os << LogIO::SEVERE << "Warning: Unknown stokes types in feed table: "
	 << polType(0) << endl
	 << "Results open to question!" << LogIO::POST;
    }
    
    if(initialize) {
      os << LogIO::NORMAL
	 << "Initializing corrected and model data and natural weights"
	 << LogIO::POST;
      {
	VisEquation ve(*vs_p);
	PJones pj(*vs_p, 10.0, 1.0);
	ve.setVisJones(pj);
	ve.correct();
      }
      Double sumwt=0.0;
      VisSetUtil::WeightNatural(*vs_p, sumwt);
    }
    ms_p->unlock();
    this->writeHistory(os);
    return True;
  } catch (AipsError x) {
    ms_p->unlock();
    os << LogIO::SEVERE << "Caught Exception: "<< x.getMesg() << LogIO::POST;
    this->writeHistory(os);
    return False;
  } 
  return True;
}

Bool simulator::close()
{
  logSink_p.clearLocally();
  LogIO os(LogOrigin("simulator", "close()"), logSink_p);
  os << "Closing MeasurementSet and detaching from simulator"
     << LogIO::POST;
  ms_p->unlock();
  this->writeHistory(os);
  if(gj_p) delete gj_p; gj_p = 0;
  if(pj_p) delete pj_p; pj_p = 0;
  if(vs_p) delete vs_p; vs_p = 0;
  if(ms_p) delete ms_p; ms_p = 0;
  if(dj_p) delete dj_p; dj_p = 0;
  if(bj_p) delete bj_p; bj_p = 0;
  if(ac_p) delete ac_p; ac_p = 0;
  if(sm_p) delete sm_p; sm_p = 0;
  if(ft_p) delete ft_p; ft_p = 0;
  if(cft_p) delete cft_p; cft_p = 0;

  return True;
}

String simulator::name() const
{
  if (detached()) {
    return "none";
  }
  return msname_p;
}

String simulator::state()
{
  ostringstream os;
  os << "Need to write the state() method!" << LogIO::POST;
  if(doVP_p) {
    os << "  Primary beam correction is enabled" << endl;
  }
  return String(os);
}

Bool simulator::summary()
{
  LogIO os(LogOrigin("simulator", "summary()", WHERE));
  createSummary(os);
  predictSummary(os);
  corruptSummary(os);

  return True;
}


Bool simulator::createSummary(LogIO& os) 
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
Bool simulator::configSummary(LogIO& os)
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
Bool simulator::fieldSummary(LogIO& os)
{
  if (nSources_p <= 0) {
    return False;
  } else {
    os << "----------------------------------------------------------------------" << LogIO::POST;
    os << " Field information: " << LogIO::POST;
    os << " Name  direction  int/pnt  mosX  mosY  mosSpacing(in lambda/2D) distance(km)" << LogIO::POST;
    for (uInt i=0; i < nSources_p; i++) {
      MDirection dir = sourceDirection_p(i);
      os << sourceName_p(i) 
	 << "  " << dir.getAngle("deg").getValue("deg")
	 << "  " << intsPerPointing_p(i)
	 << "  " << mosPointingsX_p(i)
	 << "  " << mosPointingsY_p(i)
	 << "  " << mosSpacing_p(i)
	 << "  " << distance_p(i).get("km").getValue()
	 << LogIO::POST;
    }
  }
  return True;
}
Bool simulator::timeSummary(LogIO& os)
{
  if(integrationTime_p.getValue("s") <= 0.0) {
    return False;
  } else {
    os << "----------------------------------------------------------------------" << LogIO::POST;
    os << " Time information: " << LogIO::POST;
    os << " integration time = " << integrationTime_p.getValue("s") 
       << " s" << LogIO::POST;
    os << " gap time = " << gapTime_p.getValue("s") 
       << " s" << LogIO::POST;
    os << " start time = " << startTime_p.getValue("h") 
       << " h" << LogIO::POST;
    os << " stop time = " << stopTime_p.getValue("h") 
       << " h" << LogIO::POST;
    os << " reference time = " << MVTime(refTime_p.get("s").getValue("d")).string()
       << LogIO::POST;
  }
  return True;
}
Bool simulator::spWindowSummary(LogIO& os)
{
  if (nSpWindows_p <= 0) {
    return False;
  } else {
    os << "----------------------------------------------------------------------" << LogIO::POST;
    os << " Spectral Windows information: " << LogIO::POST;
    os << " Name  nchan  freq[GHz]  freqInc[MHz]  freqRes[MHz]  stokes" << LogIO::POST;
    for (uInt i=0; i < nSources_p; i++) {
      os << spWindowName_p(i) 	 
	 << "  " << nChan_p(i)
	 << "  " << startFreq_p(i).getValue("GHz")
	 << "  " << freqInc_p(i).getValue("MHz")
	 << "  " << freqRes_p(i).getValue("MHz")
	 << "  " << stokesString_p(i)
	 << LogIO::POST;
    }
  }
  return True;
}
Bool simulator::feedSummary(LogIO& os)
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
Bool simulator::predictSummary(LogIO& os)
{
  Bool vpResult = vpSummary(os);
  Bool optionsResult = optionsSummary(os);

  if (!vpResult && !optionsResult) {
    os << "========================================" << LogIO::POST;
    os << "No predict-type information has been set" << LogIO::POST;
    os << "========================================" << LogIO::POST;
    return False;
  }
  return True;
}
Bool simulator::vpSummary(LogIO& os)
{
  if (vp_p) {
    os << "vp Summary:" << LogIO::POST;
    vp_p->summary();
    return True;
  } else {
    return False;
  }
}
Bool simulator::optionsSummary(LogIO& os)
{
  os << "Summary of setoptions() parameters:" << LogIO::POST;
  os << "ftmachine=" << ftmachine_p << " cache=" << cache_p
     << " tile=" << tile_p << " gridfunction=" << gridfunction_p
     << LogIO::POST;
  os << "padding=" << padding_p << " facets=" << facets_p << LogIO::POST;
  //  os << "mLocation=" << mLocation_p.tellMe() << LogIO::POST;
  return True;
}
 
Bool simulator::corruptSummary(LogIO& os)
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
Bool simulator::gainSummary(LogIO& os)
{
  if(!gj_p) {
    return False;
  } else {
    os << "Gain corruption activated" << LogIO::POST;
  }
  return True;
}
Bool simulator::leakageSummary(LogIO& os)
{
  if(!dj_p) {
    return False;
  } else {
    os << "Polarization leakage corruption activated" << LogIO::POST;
  }
  return True;
}
Bool simulator::bandpassSummary(LogIO& os)
{
  if(!bj_p) {
    return False;
  } else {
    os << "Bandpass corruption activated" << LogIO::POST;
  }
  return True;
}
Bool simulator::paSummary(LogIO& os)
{
  if(!pj_p) {
    return False;
  } else {
    os << "PA corruption activated" << LogIO::POST;
  }
  return True;
}
Bool simulator::noiseSummary(LogIO& os)
{
  if (!ac_p) {
   return False;
  } else {
    os << "Thermal noise corruption activated" << LogIO::POST;
    os << "Thermal noise mode: " << noisemode_p << LogIO::POST;
  }
  return True;
}




Bool simulator::setseed(const Int seed) {
  seed_p = seed;
  return True;
}


Bool simulator::setconfig(const String& telname,
			  const Vector<Double>& x, 
			  const Vector<Double>& y, 
			  const Vector<Double>& z,
			  const Vector<Float>& dishDiameter,
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
  AlwaysAssert( (nn == mount_p.nelements())  , AipsError);


  areStationCoordsSet_p = True;
  return True;  
}


// Note:  rowID is 1-based, as it leaks out to glish & gui
Bool simulator::setfield(const uInt rowID,
			 const String& sourceName,           
			 const MDirection& sourceDirection,  
			 const Int intsPerPointing,         
			 const Int mosPointingsX,           
			 const Int mosPointingsY,           
			 const Float&  mosSpacing,
			 const Quantity& distance)
{
  LogIO os(LogOrigin("simulator", "setfield()", WHERE));

  try {
    if (rowID > sourceName_p.nelements()) {
      resizeFields(rowID + nDeltaRows_p);  // vectors may have extra space at the end
      nSources_p = rowID;
    }
    if (rowID > nSources_p) {
      nSources_p = rowID;
    }
    if (rowID < 1) {
      os << LogIO::SEVERE << "row is 1-based" << LogIO::POST;  
      return False;
    }
    if (sourceName == "") {
      os << LogIO::SEVERE << "must provide a source name" << LogIO::POST;  
      return False;
    }

    sourceName_p(rowID-1) = sourceName;
    sourceDirection_p(rowID-1) = sourceDirection;
    intsPerPointing_p(rowID-1) = intsPerPointing;
    if (intsPerPointing_p(rowID-1) == 0) intsPerPointing_p(rowID-1) = 1;
    mosPointingsY_p(rowID-1) = mosPointingsY;
    mosPointingsX_p(rowID-1) = mosPointingsX;
    mosSpacing_p(rowID-1) = mosSpacing;
    distance_p(rowID-1) = distance;

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
};



// Note:  rowID is 1-based, as it leaks out to glish & gui
Bool simulator::setspwindow(const uInt rowID,
			    const String& spwName,           
			    const Quantity& freq,
			    const Quantity& deltafreq,
			    const Quantity& freqresolution,
			    const Int nChan,
			    const String& stokes) 

{
  LogIO os(LogOrigin("simulator", "setspwindow()", WHERE));

  try {
    if (rowID > spWindowName_p.nelements()) {
      resizeSpWindows(rowID + nDeltaRows_p);  // vectors may have extra space at the end
      nSpWindows_p = rowID;
    }
    if (rowID > nSpWindows_p) {
      nSpWindows_p = rowID;
    }
    if (rowID < 1) {
      os << LogIO::SEVERE << "row is 1-based" << LogIO::POST;  
      return False;
    }
    if (nChan == 0) {
      os << LogIO::SEVERE << "must provide nchannels" << LogIO::POST;  
      return False;
    }

    spWindowName_p(rowID-1) = spwName;   
    nChan_p(rowID-1) = nChan;          
    startFreq_p(rowID-1) = freq;      
    freqInc_p(rowID-1) = deltafreq;        
    freqRes_p(rowID-1) = freqresolution;        
    stokesString_p(rowID-1) = stokes;   

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
};

void simulator::resizeFields(const uInt newsize)
{
  sourceName_p.resize(newsize, True); 
  sourceDirection_p.resize(newsize, True);
  intsPerPointing_p.resize(newsize, True);
  mosPointingsX_p.resize(newsize, True);
  mosPointingsY_p.resize(newsize, True);
  mosSpacing_p.resize(newsize, True);      
  distance_p.resize(newsize, True);      
}


void simulator::resizeSpWindows(const uInt newsize)
{
  spWindowName_p.resize(newsize, True);   
  nChan_p.resize(newsize, True);          
  startFreq_p.resize(newsize, True);      
  freqInc_p.resize(newsize, True);        
  freqRes_p.resize(newsize, True);        
  stokesString_p.resize(newsize, True);  
}

Bool simulator::checkFields()
{
  LogIO os(LogOrigin("simulator", "checkFields()", WHERE));

  // possible error conditions:
  // 1: NO fields present (return False)
  // 2: non-contiguous fields (in which case we just skip any blank
  //    fields and give a warning, return True)
  if (nSources_p == 0) {
    os << "No source positions have been set!  Run setfield()" << LogIO::POST;
    return False;
  }

  if ( ! fieldsContiguous(True) ) {
    os << "Field rows were non-contiguous, but we fixed that" << LogIO::POST;
  }
  return True;
};


Bool simulator::checkSpWindows()
{
  LogIO os(LogOrigin("simulator", "checkFields()", WHERE));

  // possible error conditions:
  // 1: NO spWindows present (return False)
  // 2: non-contiguous spWindows (in which case we just skip any blank
  //    rows and give a warning, return True)
  if (nSpWindows_p == 0) {
    os << "No spectral windows have been set!  Run setspwindow()" << LogIO::POST;
    return False;
  }

  if ( ! spWindowsContiguous(True) ) {
    os << "Spectral Window rows were non-contiguous, but we fixed that" << LogIO::POST;
  }
  return True;
};


Bool simulator::fieldsContiguous(Bool doFix)
{
  Bool isContiguous = True;
  uInt nTrue = 0;
  for (uInt i=0;i<nSources_p;i++) {
    if (sourceName_p(i) == "") {
      cout << "DEBUG: field rows are noncontiguous at row " << (i+1) << endl;
      isContiguous = False;
    } else {
      nTrue++;
    }
  }
  
  if (!isContiguous && doFix) {
    
    Vector<String> 	sourceName_t(nTrue); 
    Vector<MDirection>	sourceDirection_t(nTrue);
    Vector<Int>		intsPerPointing_t(nTrue);
    Vector<Int>		mosPointingsX_t(nTrue);
    Vector<Int>		mosPointingsY_t(nTrue);
    Vector<Float>	mosSpacing_t(nTrue);       
    Vector<Quantity>	distance_t(nTrue);       
 
    uInt j=0;
    for (uInt i=0;i<nSources_p;i++) {      
      if (sourceName_p(i) != "") {
	cout << "DEBUG: fixing row " << (i+1) << endl;
	sourceName_t(j) = sourceName_p(i);       	
	sourceDirection_t(j) = sourceDirection_p(i);  
	intsPerPointing_t(j) = intsPerPointing_p(i);  
	mosPointingsX_t(j) = mosPointingsX_p(i);    
	mosPointingsY_t(j) = mosPointingsY_p(i);    
	mosSpacing_t(j) = mosSpacing_p(i);
	distance_t(j) = distance_p(i);
	j++;
      }
    }
    nSources_p = nTrue;
    sourceName_p.resize(nTrue); 
    sourceDirection_p.resize(nTrue);
    intsPerPointing_p.resize(nTrue);
    mosPointingsX_p.resize(nTrue);
    mosPointingsY_p.resize(nTrue);
    mosSpacing_p.resize(nTrue);      
    distance_p.resize(nTrue);      

    sourceName_p = sourceName_t;
    sourceDirection_p = sourceDirection_t;
    intsPerPointing_p = intsPerPointing_t;
    mosPointingsX_p = mosPointingsX_t;
    mosPointingsY_p = mosPointingsY_t;
    mosSpacing_p = mosSpacing_t;
    distance_p = distance_t;
  }
  return isContiguous;
};



Bool simulator::spWindowsContiguous(Bool doFix)
{
  Bool isContiguous = True;
  uInt nTrue = 0;
  for (uInt i=0;i<nSpWindows_p;i++) {
    if (nChan_p(i) <= 0) {
      cout << "DEBUG: sp window rows are noncontiguous at row " << (i+1) << endl;
      isContiguous = False;
    } else {
      nTrue++;
    }
  }
  
  if (!isContiguous && doFix) {
    Vector<String> 	spWindowName_t(nTrue); 
    Vector<Int>		nChan_t(nTrue);
    Vector<Quantity>    startFreq_t(nTrue);
    Vector<Quantity>    freqInc_t(nTrue);
    Vector<Quantity>    freqRes_t(nTrue);
    Vector<String>     	stokesString_t(nTrue);   
  
    uInt j=0;
    for (uInt i=0;i<nSpWindows_p;i++) {
      if (nChan_p(i) <= 0) {
	cout << "DEBUG: fixing row " << (i+1) << endl;
	spWindowName_t(j) = spWindowName_p(i);
	nChan_t(j) = nChan_p(i);          
	startFreq_t(j) = startFreq_p(i);      
	freqInc_t(j) = freqInc_p(i);        
	freqRes_t(j) = freqRes_p(i);        
	stokesString_t(j) = stokesString_p(i);   	
	j++;
      }
    }
    nSpWindows_p = nTrue;
    spWindowName_p.resize(nTrue); 
    nChan_p.resize(nTrue); 
    startFreq_p.resize(nTrue); 
    freqInc_p.resize(nTrue); 
    freqRes_p.resize(nTrue); 
    stokesString_p.resize(nTrue); 

    spWindowName_p = spWindowName_t;
    nChan_p = nChan_t;
    startFreq_p = startFreq_t;
    freqInc_p = freqInc_t;
    freqRes_p = freqRes_t;
    stokesString_p = stokesString_t;
  }
  return isContiguous;
};


// This method is brain dead and can only produce perfect
// feeds -- we'll come back and expand it later!
Bool simulator::setfeed(const String& mode) 
{
  LogIO os(LogOrigin("simulator", "setfeed()", WHERE));
  
  if (mode != "perfect R L" && mode != "perfect X Y") {
    os << LogIO::SEVERE << 
      "Currently, only perfect R L or perfect X Y feeds are recognized" 
       << LogIO::POST;
    return False;
  }
  feedMode_p = mode;
  nFeeds_p = 1;
  feedsHaveBeenSet = True;
  return True;
};




Bool simulator::setvp(const Bool dovp,
                   const Bool doDefaultVPs,
                   const String& vpTable,
                   const Bool doSquint,
                   const Quantity &parAngleInc)
{
  LogIO os(LogOrigin("simulatore", "setvp()", WHERE));
  
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

  return True;
};





Bool simulator::setpa(const String& mode, const String& table,
		      const Quantity& interval) {
  
  LogIO os(LogOrigin("simulator", "setpa()", WHERE));
  
  try {
    
    if(mode=="table") {
      os << LogIO::SEVERE << "Cannot yet read from table" << LogIO::POST;
      return False;
    }
    else {
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

Bool simulator::setnoise(const String& mode, 
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
  
  LogIO os(LogOrigin("simulator", "setnoise()", WHERE));
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


Bool simulator::settimes(const Quantity& integrationTime, 
			 const Quantity& gapTime, 
			 const Bool      useHourAngle,
			 const Quantity& startTime, 
			 const Quantity& stopTime, 
			 const MEpoch&   refTime)
{
  
  LogIO os(LogOrigin("simulator", "settimes()", WHERE));
  try {
    
    integrationTime_p = integrationTime;
    gapTime_p = gapTime; 
    useHourAngle_p = useHourAngle;
    startTime_p = startTime;
    stopTime_p = stopTime; 
    refTime_p = refTime;
    
    return True;
  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
  
}

Bool simulator::setgain(const String& mode, const String& table,
			const Quantity& interval,
			const Vector<Double>& amplitude) {
  
  LogIO os(LogOrigin("simulator", "setgain()", WHERE));


  if (!ms_p) { 
    os << LogIO::SEVERE << "setgain need to have an ms attached to simulator" 
       << LogIO::POST; 
    os << LogIO::SEVERE << "use open(ms) or create(ms)" 
       << LogIO::POST;
    return False; 
  }

  
  try {
    
    if(mode=="table") {
      os << LogIO::SEVERE << "Cannot yet read from table" << LogIO::POST;
      return False;
    }
    else {
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

Bool simulator::setbandpass(const String& mode, const String& table,
			    const Quantity& interval,
			    const Vector<Double>& amplitude) {
  
  LogIO os(LogOrigin("simulator", "setbandpass()", WHERE));
  
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

Bool simulator::setleakage(const String& mode, const String& table,
			   const Quantity& interval, const Double amplitude) {
  
  LogIO os(LogOrigin("simulator", "setleakage()", WHERE));
  
  try {
    
    if(mode=="table") {
      os << LogIO::SEVERE << "Cannot yet read from table" << LogIO::POST;
      return False;
    }
    else {
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

Bool simulator::reset() {
  LogIO os(LogOrigin("simulator", "simulate()", WHERE));
  try {
    
    if(gj_p) delete gj_p; gj_p=0;
    if(dj_p) delete dj_p; dj_p=0;
    if(pj_p) delete pj_p; pj_p=0;
    if(ac_p) delete ac_p; ac_p=0;
    if(vp_p) delete vp_p; vp_p=0;
    if(gvp_p) delete gvp_p; gvp_p=0;
    
    os << "Reset all components" << LogIO::POST;

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
}

Bool simulator::corrupt() {

  logSink_p.clearLocally();
  LogIO os(LogOrigin("simulator", "corrupt()"), logSink_p);

  if (!ms_p) {
    os << LogIO::SEVERE << "Need to open(ms) or create(ms)" << LogIO::POST;
    return False;
  }
  
  try {
    
    ms_p->lock();
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
    corruptSummary(os);
    this->writeHistory(os);
  } catch (AipsError x) {
    ms_p->unlock();
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    corruptSummary(os);
    this->writeHistory(os);
    return False;
  } 
  return True;
}

void simulator::createHelp()
{
  LogIO os(LogOrigin("simulator", "createHelp()", WHERE));
  os << "When create()-ing a MS from scratch, you need to supply some information:" << LogIO::POST;
  os << "     * the array configuration needs to be set via setconfig() "  << LogIO::POST;
  os << "     * the starting time and stopping time, as well as the integration time " << LogIO::POST;
  os << "       needs to be set via settimes() "  << LogIO::POST;
  os << "     * the sources to be observed need to be set via setfield() "  << LogIO::POST;
  os << "     * need to run setspwindow() to set frequency, bandwidth, etc "  << LogIO::POST;
  os << "     * need to run setfeed() to set the feed characteristics"  << LogIO::POST;
  os << "For the future (itsems currently covered in obsparms file): "  << LogIO::POST;
  os << "     * the schedule will be entirely up to user control in terms of "  << LogIO::POST;
  os << "       the fields, spectral windows, and feeds already set "  << LogIO::POST;
};


Bool simulator::create(const String& newMSName, 
		       const Double shadowLimit,
		       const Quantity& elevationLimit,
		       const Float  autoCorrWt) {

  logSink_p.clearLocally();
  LogIO os(LogOrigin("simulator", "create()"), logSink_p);
  
  if ( ! areStationCoordsSet_p ) {
    os << LogIO::SEVERE << "Need to setconfig() before create()-ing " << LogIO::POST;
    createHelp();
    return False;
  }
  if ( ! checkFields()  ) {
    os << LogIO::SEVERE << "Need to setfield() one or more times before create()-ing " 
       << LogIO::POST;
    createHelp();
    return False;
  }
  if ( integrationTime_p.getValue("s") <= 0.0 ) {
    os << LogIO::SEVERE << "Need to settimes() before create()-ing " << LogIO::POST;
    createHelp();
    return False;
  }
  if ( ! checkSpWindows() ) {
    os << LogIO::SEVERE << "Need to setspwindow() before create()-ing " << LogIO::POST;
    createHelp();
    return False;
  }
  if ( nFeeds_p <= 0) {
    os << LogIO::SEVERE << "Need to setfeed() before create()-ing " << LogIO::POST;
    createHelp();
    return False;
  }

  try {

    MSSimulator sim;
    sim.setFractionBlockageLimit( shadowLimit );
    sim.setElevationLimit( elevationLimit );
    sim.setAutoCorrelationWt( autoCorrWt );
    sim.setTimes( integrationTime_p, gapTime_p, useHourAngle_p,
		  startTime_p, stopTime_p, refTime_p );

    sim.initFields(nSources_p, sourceName_p, sourceDirection_p, intsPerPointing_p,
		   mosPointingsX_p, mosPointingsY_p, mosSpacing_p);
    sim.initAnt(telescope_p, x_p, y_p, z_p, diam_p, mount_p, antName_p, 
		coordsystem_p, mRefLocation_p);
    sim.initSpWindows(nSpWindows_p, spWindowName_p, nChan_p, startFreq_p, freqInc_p, 
		      freqRes_p, stokesString_p);
    sim.initFeeds( feedMode_p );

    sim.writeMS(newMSName);    // writeMS creates all time, (u,v) coordinates too.

    // Now hook up the new MS to our own ms machinery
    ms_p = new MeasurementSet(newMSName, Table::Update);
    open(*ms_p);

    createSummary(os);
    os << "Created MS coordinates in " << newMSName << LogIO::POST;
    this->writeHistory(os);

    os << "Now run predict() to fill in data and corrupt() to apply simulated errors" 
       << LogIO::POST;	

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
}

Bool simulator::add(const Double shadowLimit,
		    const Quantity& elevationLimit,
		    const Float  autoCorrWt){

  logSink_p.clearLocally();
  LogIO os(LogOrigin("simulator", "add()"), logSink_p);

  if (!ms_p) {
    os << LogIO::SEVERE << "Need to have an existing ms or create(ms) before adding to it" << LogIO::POST;
    return False;
  }

  // Log parameters to HISTORY table
  os << "Adding to MeasurementSet " << ms_p->tableName()
     << " with parameters: ";
  os << "shadowLimit=" << shadowLimit
     << " elevationLimit='" << elevationLimit.getValue()
     << elevationLimit.getUnit() << "' autoCorrWt=" << autoCorrWt;
  this->writeHistory(os);

  try {

    MSSimulator sim;
    sim.setFractionBlockageLimit( shadowLimit );
    sim.setElevationLimit( elevationLimit );
    sim.setAutoCorrelationWt( autoCorrWt );
    sim.setTimes( integrationTime_p, gapTime_p, useHourAngle_p,
		  startTime_p, stopTime_p, refTime_p );

    sim.initFields(nSources_p, sourceName_p, sourceDirection_p, 
		   intsPerPointing_p,
		   mosPointingsX_p, mosPointingsY_p, mosSpacing_p);
    sim.initAnt(telescope_p, x_p, y_p, z_p, diam_p, mount_p, antName_p, 
		coordsystem_p, mRefLocation_p);
    sim.initSpWindows(nSpWindows_p, spWindowName_p, nChan_p, startFreq_p, 
		      freqInc_p, 
		      freqRes_p, stokesString_p);
    sim.initFeeds( feedMode_p );

    sim.extendMS(*ms_p);
    {
      MSSpWindowColumns msSpW(ms_p->spectralWindow());
      Int nSpw=ms_p->spectralWindow().nrow();
      Matrix<Int> selection(2,nSpw);
      selection.row(0)=0; //start
      selection.row(1)=msSpW.numChan().getColumn(); 
      ArrayColumn<Complex> mcd(*ms_p,"MODEL_DATA");
      mcd.rwKeywordSet().define("CHANNEL_SELECTION",selection);
    }
    if(vs_p) delete vs_p;

    Block<int> sort(4);
    sort[0] = MS::FIELD_ID;
    sort[1] = MS::ARRAY_ID;
    sort[2] = MS::DATA_DESC_ID;
    sort[3] = MS::TIME;

    Matrix<Int> noselection;
    vs_p = new VisSet(*ms_p,sort,noselection);
    AlwaysAssert(vs_p, AipsError);

    Double sumwt=0.0;
    VisSetUtil::WeightNatural(*vs_p, sumwt);

    ms_p->unlock();

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    return False;
  } 
  return True;
}

Bool simulator::predict(const Vector<String>& modelImage, 
			const String& compList,
			const Bool incremental) {

  logSink_p.clearLocally();
  LogIO os(LogOrigin("simulator", "predict()"), logSink_p);
  
  // Note that incremental here does not apply to se_p->predict(False),
  // Rather it means: add the calculated model visibility to the data visibility.
  // We return a MS with Data, Model, and Corrected columns identical

  if (!ms_p) {
    os << LogIO::SEVERE << "Need to open(ms) or create(ms)" << LogIO::POST;
    return False;
  }

  try {
    os << "Predicting visibilities using model: " << modelImage << 
      " and componentList: " << compList << LogIO::POST;
    if (incremental) {
      os << "The data column will be incremented" <<  LogIO::POST;
    } else {
      os << "The data column will be replaced" <<  LogIO::POST;
    }

    predictSummary(os);
    this->writeHistory(os);

    ms_p->lock();   
    if (!createSkyEquation( modelImage, compList)) {
      os << LogIO::SEVERE << "Failed to create SkyEquation" << LogIO::POST;
      return False;
    }
    se_p->predict(False);
    destroySkyEquation();

    // Copy the predicted visibilities over to the observed and 
    // the corrected data columns
    VisIter& vi = vs_p->iter();
    VisBuffer vb(vi);
    vi.origin();
    vi.originChunks();

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

  } catch (AipsError x) {
    os << LogIO::SEVERE << "Caught exception: " << x.getMesg() << LogIO::POST;
    ms_p->unlock();     
    os << "Predict summary: ";
    predictSummary(os);
    this->writeHistory(os);
    return False;
  } 
  return True;
}

Bool simulator::createSkyEquation(const Vector<String>& image,
				  const String complist)
{

  LogIO os(LogOrigin("simulator", "createSkyEquation()", WHERE));

  if(sm_p==0) {
    if(facets_p>1) {
      sm_p = new WFCleanImageSkyModel(facets_p);
    }
    else {
      sm_p = new CleanImageSkyModel();
    }
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

  if (nmodels_p != 0) {
    images_p.resize(nmodels_p); 

    for (Int model=0;model<Int(nmodels_p);model++) {
      if(image(model)=="") {
        os << LogIO::SEVERE << "Need a name for model "
           << model+1 << LogIO::POST;
        return False;
      } else {
        if(!Table::isReadable(image(model))) {
	  os << LogIO::SEVERE << image(model) << " is unreadable" << LogIO::POST;
	} else {
	  images_p[model]=0;
	  images_p[model]=new PagedImage<Float>(image(model));
	  AlwaysAssert(images_p[model], AipsError);
	  // Add distance
	  if(abs(distance_p(model).get().getValue())>0.0) {
	    os << "  Refocusing to distance " << distance_p(model).get("km").getValue()
	       << " km" << LogIO::POST;
	  }
	  Record info(images_p[model]->miscInfo());
	  info.define("distance", distance_p(model).get("m").getValue());
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
  // Now create the VisSet
  Block<int> sort(0);
  Matrix<Int> noselection;
  vs_p = new VisSet(*ms_p,sort,noselection);
  AlwaysAssert(vs_p, AipsError);
  
  cft_p = new SimpleComponentFTMachine();

  if((ftmachine_p=="sd")||(ftmachine_p=="both")||(ftmachine_p=="mosaic")) {
    if(!gvp_p) {
      os << "Using default primary beams for gridding" << LogIO::POST;
      gvp_p=new VPSkyJones(*ms_p, True, parAngleInc_p, squintType_p);
    }
    if(ftmachine_p=="sd") {
      os << "Single dish gridding " << LogIO::POST;
      if(gridfunction_p=="pb") {
	ft_p = new SDGrid(*ms_p, *gvp_p, cache_p/2, tile_p, gridfunction_p);
      }
      else {
	ft_p = new SDGrid(*ms_p, cache_p/2, tile_p, gridfunction_p);
      }
    }
    else if(ftmachine_p=="mosaic") {
      os << "Performing Mosaic gridding" << LogIO::POST;
      ft_p = new MosaicFT(*ms_p, *gvp_p, cache_p/2, tile_p, True);
    }
    else if(ftmachine_p=="both") {
      os << "Performing single dish gridding with convolution function "
	 << gridfunction_p << LogIO::POST;
      os << "and interferometric gridding with convolution function SF"
	 << LogIO::POST;
      
      ft_p = new GridBoth(*ms_p, *gvp_p, cache_p/2, tile_p,
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
    if(facets_p>1) {
      os << "Fourier transforms will use specified common tangent point:" << LogIO::POST;
      MDirection phaseCenter(sourceDirection_p(0));
      MVAngle mvRa=phaseCenter.getAngle().getValue()(0);
      MVAngle mvDec=phaseCenter.getAngle().getValue()(1);
      ostringstream oos;
      oos << "     ";
      Int widthRA=20;
      Int widthDec=20;
      oos.setf(ios::left, ios::adjustfield);
      oos.width(widthRA);  oos << mvRa(0.0).string(MVAngle::TIME,8);
      oos.width(widthDec); oos << mvDec.string(MVAngle::DIG2,8);
      oos << "     "
	  << MDirection::showType(phaseCenter.getRefPtr()->getType());
      os << String(oos)  << LogIO::POST;
      ft_p = new GridFT(cache_p/2, tile_p, gridfunction_p, mLocation_p, phaseCenter,
			padding_p);
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
      vp_p=new VPSkyJones(*ms_p, True, parAngleInc_p, squintType_p);
    } else {
      Table vpTable( vpTableStr_p );
      vp_p=new VPSkyJones(*ms_p, vpTable, parAngleInc_p, squintType_p);
    }
    vp_p->summary();
    se_p->setSkyJones(*vp_p);
  }
  else {
    vp_p=0;
  }
  return True;
};

void simulator::destroySkyEquation() 
{
  if(se_p) delete se_p; se_p=0;
  if(sm_p) delete sm_p; sm_p=0;
  if(vp_p) delete vp_p; vp_p=0;
  if(componentList_p) delete componentList_p; componentList_p=0;

  for (Int model=0;model<Int(nmodels_p);model++) {
    if(images_p[model]) delete images_p[model]; images_p[model]=0;
  }
};



Bool simulator::setoptions(const String& ftmachine, const Int cache, const Int tile,
			const String& gridfunction, const MPosition& mLocation,
			const Float padding, const Int facets)
{
  LogIO os(LogOrigin("simulator", "setoptions()", WHERE));
  
  os << "Setting processing options" << LogIO::POST;
  
  ftmachine_p=downcase(ftmachine);
  if(cache>0) cache_p=cache;
  if(tile>0) tile_p=tile;
  gridfunction_p=downcase(gridfunction);
  mLocation_p=mLocation;
  if(padding>=1.0) {
    padding_p=padding;
  }
  facets_p=facets;
  // Destroy the FTMachine
  if(ft_p) {delete ft_p; ft_p=0;}
  if(cft_p) {delete cft_p; cft_p=0;}
  return True;
  return True;
}

void simulator::writeHistory(LogIO& os, Bool cliCommand)
{
  if (!historytab_p.isNull()) {
    if (histLockCounter_p == 0)	{
      historytab_p.lock(False);
    }
    ++histLockCounter_p;

    os.postLocally();
    if (cliCommand) {
      hist_p->cliCommand(os);
    } else {
      hist_p->addMessage(os);
    }

    if (histLockCounter_p == 1) {
	historytab_p.unlock();
    }
    if (histLockCounter_p > 0) {
      --histLockCounter_p;
    }
  } else {
    os << LogIO::SEVERE << "use open(ms) or create(ms)" << LogIO::POST;
  }    
}

String simulator::className() const
{
  return "simulator";
}

Vector<String> simulator::methods() const
{
  Vector<String> method(23);
  Int i=0;

  method(i++) = "open";
  method(i++) = "state";
  method(i++) = "close";
  method(i++) = "name";
  method(i++) = "summary";

  method(i++) = "setseed";
  method(i++) = "setgain";
  method(i++) = "setnoise";
  method(i++) = "setleakage";
  method(i++) = "setpa";

  method(i++) = "corrupt";
  method(i++) = "reset";
  method(i++) = "setbandpass";
  method(i++) = "create";
  method(i++) = "predict";

  method(i++) = "setoptions";
  method(i++) = "setconfig";
  method(i++) = "setfield";
  method(i++) = "settimes";
  method(i++) = "setspwindow";

  method(i++) = "setfeed";
  method(i++) = "setvp";
  method(i++) = "add";

  return method;
}

Vector<String> simulator::noTraceMethods() const
{
  Vector<String> method(4);
  Int i=0;
  method(i++) = "open";
  method(i++) = "state";
  method(i++) = "close";
  method(i++) = "name";
  
  return method;
}

MethodResult simulator::runMethod(uInt which, 
				  ParameterSet &inputRecord,
				  Bool runMethod)
{
  
  static String returnvalString = "returnval";
  
  switch (which) {
  case 0: // open
    {
      static String themsString = "thems";

      Parameter< String > 
	thems(inputRecord, themsString, ParameterSet::In);
      if (runMethod) {
	MeasurementSet thisms(thems(), 
			      Table::Update);
	open(thisms);
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
  case 5: // setseed
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      
      Parameter<Int> seed(inputRecord, "seed", ParameterSet::In);
      
      if (runMethod) {
	returnval() = setseed(seed());
      }
    }
    break;
  case 6: // setgain
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
  case 7: // setnoise
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
  case 8: // setleakage
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
  case 9: // setpa
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
  case 10: // corrupt
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      
      if (runMethod) { 
	returnval() = corrupt();
      }
    }
    break;
  case 11: // reset
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      
      if (runMethod) { 
	returnval() = reset();
      }
    }
    break;
  case 12: // setbandpass
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
  case 13: // create
    {
      Parameter<String>   newms(inputRecord, "newms", ParameterSet::In);
      Parameter<Double>   shadowlimit(inputRecord, "shadowlimit", ParameterSet::In);
      Parameter<Quantity> elevationlimit(inputRecord, "elevationlimit", ParameterSet::In);
      Parameter<Float>    autocorrwt(inputRecord, "autocorrwt", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = create(newms(), shadowlimit(), elevationlimit(), autocorrwt());
      }
    }
    break; 
  case 14: // predict
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
  case 15: // setoptions
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
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() =
	  setoptions (ftmachine(), cache(), tile(), gridfunction(),
		      mlocation(), padding(), facets());
      }
    }
    break;
  case 16: // setconfig
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<String >  	  telescopename(inputRecord, "telescopename", ParameterSet::In);
      Parameter<Vector<Double> >  x(inputRecord, "x", ParameterSet::In);
      Parameter<Vector<Double> >  y(inputRecord, "y", ParameterSet::In);
      Parameter<Vector<Double> >  z(inputRecord, "z", ParameterSet::In);
      Parameter<Vector<Float> >   diam(inputRecord, "dishdiameter", ParameterSet::In);
      Parameter<Vector<String> >  mount(inputRecord, "mount", ParameterSet::In);
      Parameter<Vector<String> >  antname(inputRecord, "antname", ParameterSet::In);
      Parameter<String>  coordsystem(inputRecord, "coordsystem", ParameterSet::In);
      Parameter<MPosition> mReferenceLocation(inputRecord, "referencelocation", ParameterSet::In);

      if (runMethod) {
	returnval() = setconfig (telescopename(), x(), y(), z(), diam(),  
				 mount(), antname(), coordsystem(), mReferenceLocation());
      }
    }
    break;
  case 17: // setfield
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<Int>    rowid(inputRecord, "row", ParameterSet::In);
      Parameter<String> sourcename(inputRecord, "sourcename", ParameterSet::In);
      Parameter<MDirection>   sourcedirection(inputRecord, "sourcedirection",
					      ParameterSet::In);
      Parameter<Int>    integrations(inputRecord, "integrations", ParameterSet::In);
      Parameter<Int>    xmospointings(inputRecord, "xmospointings", ParameterSet::In);
      Parameter<Int>    ymospointings(inputRecord, "ymospointings", ParameterSet::In);
      Parameter<Float>  mosspacing(inputRecord, "mosspacing", ParameterSet::In);
      Parameter<Quantity>  distance(inputRecord, "distance", ParameterSet::In);

      if (runMethod) {
	returnval() = setfield (rowid(), sourcename(), sourcedirection(), integrations(),
				xmospointings(), ymospointings(), mosspacing(),
				distance());
      }
    }
    break;
  case 18: // settimes
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<Quantity>   integrationtime(inputRecord, "integrationtime", ParameterSet::In);
      Parameter<Quantity>   gaptime(inputRecord, "gaptime", ParameterSet::In);
      Parameter< Bool >     usehourangle(inputRecord, "usehourangle", ParameterSet::In);
      Parameter<Quantity>   starttime(inputRecord, "starttime", ParameterSet::In);
      Parameter<Quantity>   stoptime(inputRecord, "stoptime", ParameterSet::In);
      Parameter<MEpoch>     referencetime(inputRecord, "referencetime", ParameterSet::In);

      if (runMethod) {
	returnval() = settimes (integrationtime(), gaptime(), 
				usehourangle(),  starttime(),
				stoptime(), referencetime() );
      }
    }
    break;
  case 19: // setspwindow
    {
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<Int>		row(inputRecord, "row", ParameterSet::In);
      Parameter<String>		spwname(inputRecord, "spwname", ParameterSet::In);
      Parameter<Quantity>   	freq(inputRecord, "freq", ParameterSet::In);
      Parameter<Quantity>   	deltafreq(inputRecord, "deltafreq", ParameterSet::In);
      Parameter<Quantity>   	freqresolution(inputRecord, "freqresolution", ParameterSet::In);
      Parameter<Int>   		nchannels(inputRecord, "nchannels", ParameterSet::In);
      Parameter<String>   	stokes(inputRecord, "stokes", ParameterSet::In);

      if (runMethod) {
	returnval() = setspwindow (row(), spwname(), freq(), deltafreq(),
				   freqresolution(), nchannels(), stokes());
      }
    }
    break;
  case 20: // setfeed
    {
      Parameter< Bool>
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<String>  mode(inputRecord, "mode", ParameterSet::In);

      if (runMethod) {
	returnval() = setfeed (mode());
      }
    }
    break;
  case 21: // setvp
    {
      Parameter< Bool>
	returnval(inputRecord, returnvalString, ParameterSet::Out);

      Parameter<Bool>  dovp(inputRecord, "dovp", ParameterSet::In);
      Parameter<Bool>  usedefaultvp(inputRecord, "usedefaultvp", ParameterSet::In);
      Parameter<String>  vptable(inputRecord, "vptable", ParameterSet::In);
      Parameter<Bool> dosquint(inputRecord, "dosquint", ParameterSet::In);
      Parameter<Quantity> parangleinc(inputRecord, "parangleinc", ParameterSet::InOut);

      if (runMethod) {
	returnval() = setvp (dovp(), usedefaultvp(), vptable(), dosquint(), parangleinc() );
      }
    }
    break;
  case 22: // add
    {
      Parameter<Double>   shadowlimit(inputRecord, "shadowlimit", ParameterSet::In);
      Parameter<Quantity> elevationlimit(inputRecord, "elevationlimit", ParameterSet::In);
      Parameter<Float>    autocorrwt(inputRecord, "autocorrwt", ParameterSet::In);
      Parameter< Bool >
	returnval(inputRecord, returnvalString, ParameterSet::Out);
      if (runMethod) {
	returnval() = add(shadowlimit(), elevationlimit(), autocorrwt());
      }
    }
    break; 
  default:
    return error("No such method");
  }
  return ok();
}


Bool simulator::detached() const
{
  return False;
}
