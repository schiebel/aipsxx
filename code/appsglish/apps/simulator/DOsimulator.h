//# DOsimulator: defines classes for simulator DO.
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
//# $Id: DOsimulator.h,v 19.6 2005/02/02 20:06:39 rrusk Exp $

#ifndef APPSGLISH_DOSIMULATOR_H
#define APPSGLISH_DOSIMULATOR_H

#include <casa/aips.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <casa/Quanta/Quantum.h>
#include <measures/Measures/MPosition.h>
#include <synthesis/MeasurementComponents/BeamSquint.h>
#include <synthesis/MeasurementComponents/VPSkyJones.h>

#include <casa/Logging/LogIO.h>
#include <ms/MeasurementSets/MSHistoryHandler.h>

#include <casa/namespace.h>
namespace casa { //# NAMESPACE CASA - BEGIN
class MeasurementSet;
class VisSet;
class VisJones;
class ACoh;
class SkyEquation;
class ComponentList;
class CleanImageSkyModel;
class FTMachine;
class ComponentFTMachine;
class MEpoch;
template<class T> class PagedImage;
} //# NAMESPACE CASA - END



// <summary>Simulates MeasurementSets from SkyModel and SkyEquation</summary>


// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
//   <li> <linkto class="MeasurementSet">MeasurementSet</linkto>
//   <li> <linkto class="SkyEquation">SkyEquation</linkto>
//   <li> <linkto class="SkyModel">SkyModel</linkto>
// </prerequisite>
//
// <etymology>
// The name MUST have the 'DO' prefix as this class is derived from
// ApplicationObject, and hence is classified as a distributed object. For the
// same reason the rest of its name must be in lower case. This class 
// simulates visibility data, so it is called DOsimulator.
// </etymology>
//
// <synopsis>
// </synopsis>
//
// <motivation> 
// This class was written to make the simulation capability useful from glish
// </motivation>
//
// <thrown>
// <li> AipsError - if an error occurs
// </thrown>
//
// <todo asof="1999/07/22">
//   <li> everything
// </todo>

class simulator : public ApplicationObject
{
public:
  // "simulator" ctor
  simulator(MeasurementSet &thems);
  
  // Close the current ms, and replace it with the supplied ms.
  Bool open(MeasurementSet &thems);
  
  // Flush the ms to disk and detach from the ms file. All function
  // calls after this will be a no-op.
  Bool close();
  
  // Return the name of the MeasurementSet
  String name() const;
  
  simulator();
  
  simulator(const simulator &other);

  simulator &operator=(const simulator &other);
 
  ~simulator();
  
  // set the configuration; NOTE: the telname used
  // here will determine the Voltage Pattern to be used in the
  // simulation
  Bool setconfig(const String& telname,
		 const Vector<Double>& x, 
		 const Vector<Double>& y, 
		 const Vector<Double>& z,
		 const Vector<Float>& dishDiameter,
		 const Vector<String>& mount,
		 const Vector<String>& antName,
		 const String& coordsystem,
		 const MPosition& referenceLocation);

  // set the observed fields for the simulation
  Bool setfield(const uInt rowID,
		const String& sourceName,           
		const MDirection& sourceDirection,  
		const Int intsPerPointing,         
		const Int mosPointingsX,           
		const Int mosPointingsY,           
		const Float& mosSpacing,
		const Quantity& distance);

  // set the required times for the simulation
  Bool settimes(const Quantity& integrationTime,
		const Quantity& gapTime,
		const Bool      useHourAngle,
		const Quantity& startTime,
		const Quantity& stopTime,
		const MEpoch& refTime);

  // set one or more spectral windows and their characteristics
  Bool setspwindow(const uInt rowID,
		   const String& spwName,
		   const Quantity& freq,
		   const Quantity& deltafreq,
		   const Quantity& freqresolution,
		   const Int nchannels,
		   const String& stokes);


  // Set the simulated feed characteristics (currently
  // brain dead version, only takes "perfect R L" or "perfect X Y")
  Bool setfeed(const String& mode);		

  // Set the voltage pattern
  Bool setvp(const Bool dovp,
             const Bool defaultVP,
             const String& vpTable,
             const Bool doSquint,
             const Quantity &parAngleInc);

  // Set the random number generator seed for the addition of errors
  Bool setseed(const Int seed);

  // Apply antenna-based gain errors
  Bool setgain(const String& mode, const String& table,
	       const Quantity& interval, const Vector<Double>& amplitude);

  // Apply polarization leakage errors
  Bool setleakage(const String& mode, const String& table,
		  const Quantity& interval, const Double amplitude);

  // Apply bandpass errors
  Bool setbandpass(const String& mode, const String& table,
		   const Quantity& interval, const Vector<Double>& amplitude);

  // Simulate the parallactic angle phase effect
  Bool setpa(const String& mode, const String& table,
	     const Quantity& interval);

  // Simulate quasi-realistic thermal noise, which can depend upon
  // elevation, bandwidth, antenna diameter, as expected
  Bool setnoise(const String& mode, 
		const Quantity& simplenoise,
		const String& table,
		const Float antefficiency,
		const Float correfficiency,
		const Float spillefficiency,
		const Float tau,
		const Float trx,
		const Float tatmos, 
		const Float tcmb);
		// const Quantity& trx,
		// const Quantity& tatmos, 
		// const Quantity& tcmb);

  // calculate errors and apply them to the data in our MS
  Bool corrupt();

  // Create a MS from a file containing the names of various parameter files
  // (ie, fields, spectral window, etc -- see MeasurementSets/MSSimulator
  // for more info).
  Bool create(const String& newMSName, 
	      const Double shadowFraction,
	      const Quantity& elevationLimit,
	      const Float autocorrwt=0.0);


  // add new visibilities as described by the set methods to an existing
  // or just created measurement set
  Bool add(const Double shadowFraction,
	   const Quantity& elevationLimit,
	   const Float autocorrwt=0.0);

  // Given a model image, predict the visibilities onto the (u,v) coordinates
  // of our MS
  Bool predict(const Vector<String>& modelImage, 
	       const String& compList, 
	       const Bool incremental);

  String state();

  Bool summary();

  Bool reset();

  // Set the processing options
  Bool setoptions(const String& ftmachine, const Int cache, const Int tile,
		  const String& gridfunction, const MPosition& mLocation,
		  const Float padding, const Int facets);

  // Stuff needed for distributing this class
  virtual String className() const;
  virtual Vector<String> methods() const;
  virtual Vector<String> noTraceMethods() const;
  
  // If your object has more than one method
  virtual MethodResult runMethod(uInt which, 
				 ParameterSet &inputRecord,
				 Bool runMethod);
private:
  
  // Prints an error message if the simulator DO is detached and returns True.
  Bool detached() const;

  // set up some defaults
  void defaults();

  // print out some help about create()
  void createHelp();

  // individual summary() functions
  // <group>
  Bool createSummary(LogIO& os);
  Bool configSummary(LogIO& os);
  Bool fieldSummary(LogIO& os);
  Bool spWindowSummary(LogIO& os);
  Bool feedSummary(LogIO& os);
  Bool timeSummary(LogIO& os);

  Bool predictSummary(LogIO& os);
  Bool vpSummary(LogIO& os);
  Bool optionsSummary(LogIO& os);

  Bool corruptSummary(LogIO& os);
  Bool gainSummary(LogIO& os);
  Bool leakageSummary(LogIO& os);
  Bool bandpassSummary(LogIO& os);
  Bool paSummary(LogIO& os);
  Bool noiseSummary(LogIO& os);
  // </group>


  // SkyEquation management
  // <group>
  Bool createSkyEquation( const Vector<String>& image, const String complist);
  void destroySkyEquation();
  // </group>

  String msname_p;
  MeasurementSet* ms_p;
  VisSet* vs_p;

  Int seed_p;

  VisJones *gj_p;
  VisJones *pj_p;
  VisJones *dj_p;
  VisJones *bj_p;
  ACoh     *ac_p;

  SkyEquation* se_p;
  CleanImageSkyModel* sm_p;
  FTMachine *ft_p;
  ComponentFTMachine *cft_p;

  Int nmodels_p;
  PtrBlock<PagedImage<Float>* > images_p;
  ComponentList *componentList_p;

  String ftmachine_p, gridfunction_p;
  Int cache_p, tile_p;
  MPosition mLocation_p;
  Float padding_p;
  Bool MSMayBeOK;
  Int facets_p;

  // info for coordinates and station locations
  // <group>
  Bool           areStationCoordsSet_p;
  String         telescope_p;
  Vector<Double> x_p;
  Vector<Double> y_p;
  Vector<Double> z_p;
  Vector<Float>  diam_p;
  Vector<String> mount_p;
  Vector<String> antName_p;
  String         coordsystem_p;
  MPosition      mRefLocation_p;
  // </group>

  // info for observed field parameters
  // this will grow into an observing schedule
  // <group>

  // checks to see if fields have been handled properly (ie, no gaps),
  // returns false if there is a problem
  Bool checkFields();

  // check to see if rows are contiguous; returns True if fields were
  // contiguous in row numbers (ie, vectors had no gaps.
  // if doFix==True, we remove any empty rows
  Bool fieldsContiguous(Bool doFix);

  // resizes field vectors
  void resizeFields(const uInt newsize);

  uInt			nDeltaRows_p;
  uInt			nSources_p;
  Vector<String> 	sourceName_p; 
  Vector<MDirection>	sourceDirection_p;
  Vector<Int>		intsPerPointing_p;
  Vector<Int>		mosPointingsX_p;
  Vector<Int>		mosPointingsY_p;
  Vector<Float>		mosSpacing_p;      
  Vector<Quantity>      distance_p;

  // </group>


  // info for spectral window parameters
  // <group>

  // checks to see if spwindows have been handled properly (ie, no gaps),
  // returns false if there is a problem
  Bool checkSpWindows();

  // check to see if rows are contiguous; returns True if spwindows were
  // contiguous in row numbers (ie, vectors had no gaps.
  // if doFix==True, we remove any empty rows
  Bool spWindowsContiguous(Bool doFix);

  // resizes spWindow vectors
  void resizeSpWindows(const uInt newsize);

  // spectral windows data
  // <group>
  uInt			nSpWindows_p;
  Vector<String> 	spWindowName_p; 
  Vector<Int>		nChan_p;
  Vector<Quantity>     	startFreq_p;
  Vector<Quantity>     	freqInc_p;
  Vector<Quantity>     	freqRes_p;
  Vector<String>     	stokesString_p;   
  // </group>
  // </group>


  // Feed information (there will be much more coming,
  // but we are brain dead at this moment).
  String feedMode_p;
  Int nFeeds_p;
  Bool feedsHaveBeenSet;

  // Some times which are required for "create"
  // <group>
  Quantity integrationTime_p;
  Quantity gapTime_p;
  Bool     useHourAngle_p;
  Quantity startTime_p;
  Quantity stopTime_p;
  MEpoch   refTime_p;
  // </group>

  // Some parameters for voltage pattern (vp):
  // <group>
  Bool doVP_p;			// Do we apply VP or not?
  Bool doDefaultVP_p;		// Do we use the default VP for this telescope?
  String vpTableStr_p;		// Otherwise, use the VP specified in this Table
  Quantity  parAngleInc_p;	// Parallactic Angle increment 
  BeamSquint::SquintType  squintType_p;	// Control of squint to use
  VPSkyJones* vp_p;		// pointer to VPSkyJones for the sky equation
  VPSkyJones* gvp_p;		// pointer to VPSkyJones for the sky equation
  // </group>

  // Saving some information about the various corrupting terms
  // <group>
  String noisemode_p;
  // </group>

  // Sink used to store history
  LogSink logSink_p;

  //Used to update the MS HISTORY Table
  Table historytab_p;
  MSHistoryHandler *hist_p;
  Int histLockCounter_p;

  // Methods to update MS HISTORY Table
  void writeHistory(LogIO& os, Bool cliCommand=False);

};

#endif
