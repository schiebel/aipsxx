//# DOcalibrater.cc: Implementation of DOcalibrater.h
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
//# $Id: DOcalibrater.cc,v 19.28 2006/02/14 19:47:17 gmoellen Exp $
//----------------------------------------------------------------------------

#include <appsglish/calibrater/DOcalibrater.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/DataType.h>
#include <casa/Arrays/Vector.h>
#include <casa/Containers/RecordDesc.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterSet.h>
#include <tasking/Tasking/Index.h>
#include <casa/Logging.h>
#include <casa/Logging/LogIO.h>
#include <tasking/Glish/GlishArray.h>
#include <casa/iostream.h>


#include <casa/namespace.h>
//----------------------------------------------------------------------------

calibrater::calibrater() : itsMS(0), itsCI(), itsApplyMap((Record*)0),
  itsSolveMap((Record*)0)
{
// Default constructor
// Output to private data:
//    itsMS        MeasurementSet*    MS
//    itsCI        Calibrater         Cal operator
//    itsApplyMap  SimpleOrderedMap   Cal. table apply assignments
//    itsSolveMap  SimpleOrderedMap   Cal. table solve assignments
//
}

//----------------------------------------------------------------------------

calibrater::calibrater (MeasurementSet& ms, Bool compress) :
   itsMS(0), itsCI(), itsApplyMap((Record*)0), itsSolveMap((Record*)0)
{
// Constructor from a measurement set
// Inputs:
//    ms           MeasurementSet     Existing MS
//    compress     Bool               Compress the calibration columns 
//                                    (MODEL,CORRECTED_DATA & IMAGING_WEIGHT) ?
// Output to private data:
//    itsMS        MeasurementSet*    MS
//    itsCI        Calibrater         Cal operator
//    itsApplyMap  SimpleOrderedMap   Cal. table apply assignments
//    itsSolveMap  SimpleOrderedMap   Cal. table solve assignments
//
   // Open the measurement set
   open (ms);
   
   // Initialize the calibrator object
   itsCI.initialize (ms, compress);
};

//----------------------------------------------------------------------------

calibrater::calibrater (const calibrater& other) :
   itsMS(0), itsCI(), itsApplyMap((Record*)0), itsSolveMap((Record*)0)
{
// Copy constructor
// Inputs:
//    other        calibrater&        Input cal object
// Output to private data:
//    itsMS        MeasurementSet*    MS
//    itsCI        Calibrater         Cal operator
//    itsApplyMap  SimpleOrderedMap   Cal. table apply assignments
//    itsSolveMap  SimpleOrderedMap   Cal. table solve assignments
//
   // Open the measurement set
   open (*(other.itsMS));
};

//----------------------------------------------------------------------------

calibrater::~calibrater() 
{
// Destructor
//
   // Delete pointers if they already exist
   if (itsMS) {
      delete itsMS;
    };
};

//----------------------------------------------------------------------------

void calibrater::open (MeasurementSet& ms)
{
// Private function to open/create a measurement set
// Inputs:
//    ms           MeasurementSet     MS
// Output to private data:
//    itsMS        MeasurementSet*    MS
//
   LogIO os (LogOrigin ("calibrater", "open()", WHERE));
   if (itsMS) {
      *itsMS = ms;
    } else {
      itsMS = new MeasurementSet (ms);
      AlwaysAssert (itsMS, AipsError);
    };

   // Open LogSink for MS History table logging
   logSink_p=LogSink(LogMessage::NORMAL, False);
 };

//----------------------------------------------------------------------------

calibrater& calibrater::operator= (const calibrater& other) 
{
// Assignment operator
// Inputs:
//    other        calibrater&        Input calibrater object
// Output to private data:
//    itsMS        MeasurementSet*    MS
//
//
   if (itsMS && this != &other) {
      *itsMS = *(other.itsMS);
    };
   return *this;
};

//----------------------------------------------------------------------------

void calibrater::setdata (const String& mode, const Int& nchan, 
			  const Int& start, const Int& step, 
			  const MRadialVelocity& mStart,
			  const MRadialVelocity& mStep,
			  const String& msSelect)
{
// Define primary measurement set selection criteria
// Inputs:
//    mode         const String&            Frequency/velocity selection mode
//                                          ("channel", "velocity" or 
//                                           "opticalvelocity")
//    nchan        const Int&               No of channels to select
//    start        const Int&               Start channel to select
//    step         const Int&               Channel increment
//    mStart       const MRadialVelocity&   Start radial vel. to select
//    mStep        const MRadialVelocity&   Radial velocity increment
//    msSelect     const String&            MS selection string (TAQL)
// Output to private data:
//    itsCI        Calibrater*              Calibrater object
//

  // Set up history logging infrastructure
  logSink_p.clearLocally();
  LogIO os(LogOrigin("calibrater", "setdata()"), logSink_p);

  // run reset because setdata is going to delete itsCI's VisSet,
  //  which existing VisJones objects rely upon
  reset(True,True);

  // Invoke setdata on the calibrater object
  itsCI.setdata (mode, nchan, start, step, mStart, mStep, msSelect);

  // Log parameters to HISTORY table
  os <<  "mode=" << mode << " nchan="  << nchan  << " start=" << start
     << " step=" << step << " mStart='" << mStart.getValue()
     << (mStart.getUnit()).getName() << "' mStep='" << mStep.getValue()
     << (mStep.getUnit()).getName() << "' msSelect="
     << "'" << msSelect << "'";
  itsCI.writeHistory(os,True);
};

//----------------------------------------------------------------------------

void calibrater::setapply (const String& type, const Double& t, 
			   const String& table, 
			   const String& interp,
			   const String& select,
			   const Vector<Int>& spwmap,
                           const Bool& unset, const Float& opacity,
			   const Vector<Int>& rawspw)
{
// Set calibration application information for each component
// Inputs:
//    type          const String&        Cal. table type (e.g. "G")
//    t             const Double&        Interpolation interval
//    table         const String&        Input cal. table name
//    select        const String&        Cal. table selection
//    unset         const Bool&          To unset selected Cal type
// Output to private data:
//    itsApplyMap   SimpleOrderedMap     Cal. table apply assignments
//
  // Force type to uppercase
  String upperCaseType(type);
  upperCaseType.upcase();
  
  // If requested, just un-setapply this type
  if (unset) {
    if (itsApplyMap.isDefined(upperCaseType) ) {
      itsApplyMap.remove(upperCaseType);
      itsCI.unset(upperCaseType);
    }

  } else {
  // Arrange to apply this type:

    // Set record format for calibration table application information
    RecordDesc mapDesc;
    mapDesc.addField ("t", TpDouble);
    mapDesc.addField ("table", TpString);
    mapDesc.addField ("interp", TpString);
    mapDesc.addField ("select", TpString);
    mapDesc.addField ("opacity",TpFloat);
    mapDesc.addField ("spwmap",TpArrayInt);

    // Create record with the requisite field values
    Record* mapRec = new Record (mapDesc);
    mapRec->define ("t", t);
    mapRec->define ("table", table);
    mapRec->define ("interp", interp);
    mapRec->define ("select", select);
    mapRec->define ("opacity", opacity);
    mapRec->define ("spwmap",spwmap);

    // Add to ordered map
    itsApplyMap.define (upperCaseType, mapRec);
  }    

  rawspw_p.resize();
  rawspw_p=rawspw;
  // Execute state function to confirm:
  applystate();

};

//----------------------------------------------------------------------------

void calibrater::setsolve (const String& type, Record*& solver,
			   const Bool& unset)
{
// Set calibration solver information for each component
// Inputs:
//    type          const String&        Cal. table type (e.g. "G")
//    solver        const Record*&       Cal. solver parameters
//    unset         const Bool&          Unset this cal type
// Output to private data:
//    itsSolveMap   SimpleOrderedMap     Cal. table solve assignments
//

  // Force type to uppercase
  String upperCaseType(type);
  upperCaseType.upcase();

  // If unset requested, unsetsolve this type
  if (unset) {
    if (itsSolveMap.isDefined(upperCaseType)) {
      itsSolveMap.remove(upperCaseType);
      itsCI.unsetSolve();
    }

  } else {
  // Arrange to solve for this type

    // The table name must be specified, if present as a parameter
    if (solver->isDefined("table")) {
      String table = solver->asString("table");
      Int nlen = table.length();
      Int nspace = table.freq(' ');
      if (table.empty() || nspace==nlen) {
	throw(AipsError("Must specify a valid calibration table name"));
      };
    };
    
    // Add the solver parameters to the ordered map per Jones matrix type
    itsSolveMap.define (upperCaseType, solver);
  }

  // Execute solvestate function to confirm:
  solvestate();

};

//----------------------------------------------------------------------------

void calibrater::setsolve (const String& type, const Double& t, 
			   const Double& preavg, const Bool& phaseonly, 
			   const Int& refant, const String& table, 
			   const Bool& append, const Bool& unset)
{
// Set calibration solution information for each component
// Inputs:
//    type          const String&        Cal. table type (e.g. "G")
//    t             const Double&        Solution interval
//    preavg        const Double&        Solution pre-averaging interval
//    phaseonly     const Bool&          Solve for phase only ?
//    refant        const Int&           Reference antenna number
//    table         const String&        Output cal. table name
//    append        const Bool&          Append to cal. table ?
//    unset         const Bool&          Unset this cal type
// Output to private data:
//    itsSolveMap   SimpleOrderedMap     Cal. table solve assignments
//
  // Create a record description containing the solver parameters
  RecordDesc mapDesc;
  mapDesc.addField ("t", TpDouble);
  mapDesc.addField ("preavg", TpDouble);
  mapDesc.addField ("phaseonly", TpBool);
  mapDesc.addField ("refant", TpInt);
  mapDesc.addField ("table", TpString);
  mapDesc.addField ("append", TpBool);

  // Create a solver record with the requisite field values
  Record* mapRec = new Record (mapDesc);
  mapRec->define ("t", t);
  mapRec->define ("preavg", preavg);
  mapRec->define ("phaseonly", phaseonly);
  mapRec->define ("refant", refant);
  mapRec->define ("table", table);
  mapRec->define ("append", append);

  // Add to the solver map per Jones matrix type
  setsolve (type, mapRec, unset);
};

//----------------------------------------------------------------------------

void calibrater::setsolvebandpoly (const String& table, const Bool& append,
				   const Int& degamp, const Int& degphase,
				   const Bool& visnorm, const Bool& bpnorm,
				   const Int& maskcenter, 
				   const Float& maskedge,
				   const Int& refant, const Bool& unset)
{
// Set solver parameters for polynomial bandpass cal. components (BJonesPoly)
// Inputs:
//    table         const String&        Output cal. table name
//    append        const Bool&          Append to cal. table ?
//    degamp        const Int&           Polynomial degree in amplitude
//    degphase      const Int&           Polynomial degree in phase
//    visnorm       const Bool&          True if pre-normalization of the 
//                                       visibility data over frequency is
//                                       required before solving.
//    bpnorm        const Bool&          True if the output bandpass
//                                       solutions should be normalized.
//    maskcenter    const Int&           No. of central channels to mask
//                                       during the solution
//    maskedge      const Float&         Fraction of spectrum to mask at
//                                       either edge during solution
//    refant        const Int&           Reference antenna number
//    unset         const Bool&          Unset this cal type
// Output to private data:
//    itsSolveMap   SimpleOrderedMap     Cal. table solve assignments
//
  // Create a record description containing the solver parameters
  RecordDesc mapDesc;
  mapDesc.addField ("table", TpString);
  mapDesc.addField ("append", TpBool);
  mapDesc.addField ("degamp", TpInt);
  mapDesc.addField ("degphase", TpInt);
  mapDesc.addField ("visnorm", TpBool);
  mapDesc.addField ("bpnorm", TpBool);
  mapDesc.addField ("maskcenter", TpInt);
  mapDesc.addField ("maskedge", TpFloat);
  mapDesc.addField ("refant", TpInt);

  // Create a solver record with the requisite field values
  Record* mapRec = new Record (mapDesc);
  mapRec->define ("table", table);
  mapRec->define ("append", append);
  mapRec->define ("degamp", degamp);
  mapRec->define ("degphase", degphase);
  mapRec->define ("visnorm", visnorm);
  mapRec->define ("bpnorm", bpnorm);
  mapRec->define ("maskcenter", maskcenter);
  mapRec->define ("maskedge", maskedge);
  mapRec->define ("refant", refant);

  // Add to the solver map per Jones matrix type
  setsolve ("BPOLY", mapRec, unset);
};

//----------------------------------------------------------------------------

void calibrater::setsolvegainpoly (const String& table, const Bool& append,
				   const String& mode, const Int& degree, 
				   const Int& refant, const Bool& unset)
{
// Set solver parameters for polynomial gain cal. components (GJonesPoly)
// Inputs:
//    table         const String&        Output cal. table name
//    append        const Bool&          Append to cal. table ?
//    mode          const String&        Solve mode (AMP, PHAS or A&P)
//    degree        const Int&           Polynomial degree 
//    refant        const Int&           Reference antenna number
//    unset         const Bool&          Unset this cal type
// Output to private data:
//    itsSolveMap   SimpleOrderedMap     Cal. table solve assignments
//
  // Create a record description containing the solver parameters
  RecordDesc mapDesc;
  mapDesc.addField ("table", TpString);
  mapDesc.addField ("append", TpBool);
  mapDesc.addField ("mode", TpString);
  mapDesc.addField ("degree", TpInt);
  mapDesc.addField ("refant", TpInt);

  // Create a solver record with the requisite field values
  Record* mapRec = new Record (mapDesc);
  mapRec->define ("table", table);
  mapRec->define ("append", append);
  mapRec->define ("mode", mode);
  mapRec->define ("degree", degree);
  mapRec->define ("refant", refant);

  // Add to the solver map per Jones matrix type
  setsolve ("GPOLY", mapRec, unset);
};

//----------------------------------------------------------------------------

void calibrater::setsolvegainspline (const String& table, const Bool& append,
				     const String& mode, const Double& preavg,
                                     const Double& splinetime,
				     const Int& refant, const Int& npointaver,
				     const Double& anglewrap,
				     const Bool& unset)
{
// Set solver parameters for spline gain cal. components (GJonesSpline)
// Inputs:
//    table         const String&        Output cal. table name
//    append        const Bool&          Append to cal. table ?
//    mode          const String&        Solve mode (AMP, PHASE or A&P)
//    preavg        const Double&        Pre-average interval (seconds)
//    splinetime    const Double&        Knot timescale for splines
//    refant        const Int&           Reference antenna number
//    unset         const Bool&          Unset this cal type
// Output to private data:
//    itsSolveMap   SimpleOrderedMap     Cal. table solve assignments
//
  // Create a record description containing the solver parameters
  RecordDesc mapDesc;
  mapDesc.addField ("table", TpString);
  mapDesc.addField ("append", TpBool);
  mapDesc.addField ("mode", TpString);
  mapDesc.addField ("preavg", TpDouble);
  mapDesc.addField ("splinetime", TpDouble);
  mapDesc.addField ("refant", TpInt);

  // Create a solver record with the requisite field values
  Record* mapRec = new Record (mapDesc);
  mapRec->define ("table", table);
  mapRec->define ("append", append);
  mapRec->define ("mode", mode);
  mapRec->define ("preavg", preavg);
  mapRec->define ("splinetime", splinetime);
  mapRec->define ("refant", refant);

  // Add to the solver map per Jones matrix type
  setsolve ("GSPLINE", mapRec, unset);
  itsCI.setPhaseSplineParam(npointaver, anglewrap);
};

//----------------------------------------------------------------------------

void calibrater::applystate(Bool writeMSHistory)
{
// Report which Jones components are being applied
//   TBD:
//     - Neater tabulation
//     - Report in ME order?

  // Set up history logging infrastructure
  logSink_p.clearLocally();
  LogIO os(LogOrigin("calibrater", "state()"), logSink_p);

  // How many Jones components will be applied?
  uInt napply = itsApplyMap.ndefined();

  // Title for applied components:
  os << "The following calibration components will be applied:" << LogIO::POST;

  // If any, loop over them and report:
  if (napply > 0) {
    for (uInt iapply=0; iapply<napply; iapply++) {

      String type = "";
      Double t = 0.0;
      String table = "";
      String select = "";
      
      type=itsApplyMap.getKey(iapply);
      itsApplyMap.getVal(iapply)->get("t",t);
      itsApplyMap.getVal(iapply)->get("table",table);
      itsApplyMap.getVal(iapply)->get("select",select);
      
      // Handle no-table case of "P"
      if (type=="P") {
         table = "<pre-computed>";
      }

      os << "  " << type << " table=" << table << " t=" << t << " select=[" << select << "]" << LogIO::POST;
    }
  } else {
    os << "  None." << LogIO::POST;
  }
  if (writeMSHistory) {
    itsCI.writeHistory(os);
  } else {
    logSink_p.clearLocally();
  }
}

//----------------------------------------------------------------------------

void calibrater::solvestate(Bool writeMSHistory)
{
// Report which Jones components are being solved for
//   TBD:
//     - Neater tabulation
//     - Report in ME order?

  // Set up history logging infrastructure
  logSink_p.clearLocally();
  LogIO os(LogOrigin("calibrater", "state()"), logSink_p);

  // How many Jones components will be solved for?
  uInt nsolve = itsSolveMap.ndefined();

  // Title for solved-for components:
  os << "The following calibration components will be solved for:" << LogIO::POST;

  // If any, loop over them and report:
  if (nsolve > 0) {
    Vector<String> TF(2);
    TF(0)="F";
    TF(1)="T";

    for (uInt isolve=0; isolve<nsolve; isolve++) {

      String type = "";
      Double t = 0.0;
      Double preavg = 0.0;
      Bool phaseonly = False;
      Int refant = 0;
      String table = "";
      Bool append;

      type=itsSolveMap.getKey(isolve);
      if (itsSolveMap(type)->isDefined("t")) {
	itsSolveMap.getVal(isolve)->get("t",t);
      };
      if (itsSolveMap(type)->isDefined("preavg")) {
	itsSolveMap.getVal(isolve)->get("preavg",preavg);
      };
      if (itsSolveMap(type)->isDefined("phaseonly")) {
	itsSolveMap.getVal(isolve)->get("phaseonly",phaseonly);
      };
      if (itsSolveMap(type)->isDefined("refant")) {
	itsSolveMap.getVal(isolve)->get("refant",refant);
      };
      if (itsSolveMap(type)->isDefined("table")) {
	itsSolveMap.getVal(isolve)->get("table",table);
      };
      if (itsSolveMap(type)->isDefined("append")) {
	itsSolveMap.getVal(isolve)->get("append",append);
      };
      
      // Correct for 0-relative indexing on refant
      //    (which is realized in calibrater.g setsolve)
      refant++;

      os << "  " << type << " table=" << table << " t=" << t << " preavg=" << preavg << " phaseonly=" << TF(phaseonly) << " refant=" << refant << " append=" << TF(append) << LogIO::POST;
    }
  } else {
    os << "  None." << LogIO::POST;
  }
  if (writeMSHistory) {
    itsCI.writeHistory(os);
  } else {
    logSink_p.clearLocally();
  }
}

//----------------------------------------------------------------------------

void calibrater::state()
{
// Group applystate() & solvestate() functions

  applystate();
  solvestate();
}


//---------------------------------------------------------------------------

void calibrater::reset(const Bool& apply, const Bool& solve)
{
// Clear apply/solve states
// Inputs:
//    apply          const Bool&        If T, reset apply state
//    solve          const Bool&        If T, reset solve state

  if (apply) {
    if (itsApplyMap.isDefined("T")) itsCI.unset("T");
    if (itsApplyMap.isDefined("TOPAC")) itsCI.unset("TOPAC");
    if (itsApplyMap.isDefined("GAINCURVE")) itsCI.unset("GAINCURVE");
    if (itsApplyMap.isDefined("P")) itsCI.unset("P");
    if (itsApplyMap.isDefined("D")) itsCI.unset("D");
    if (itsApplyMap.isDefined("G")) itsCI.unset("G");
    if (itsApplyMap.isDefined("GPOLY")) itsCI.unset("GPOLY");
    if (itsApplyMap.isDefined("GSPLINE")) itsCI.unset("GSPLINE");
    if (itsApplyMap.isDefined("B")) itsCI.unset("B");
    if (itsApplyMap.isDefined("BPOLY")) itsCI.unset("BPOLY");
    if (itsApplyMap.isDefined("K")) itsCI.unset("K");
    if (itsApplyMap.isDefined("M")) itsCI.unset("M");
    if (itsApplyMap.isDefined("MF")) itsCI.unset("MF");
    itsApplyMap.clear();
  }
  if (solve) {
    itsCI.unsetSolve();
    itsSolveMap.clear();
  }

  // Report (now empty) state:
  state();

}

void calibrater::initcalset(const Int& calSet) 
{
  // Set up history logging infrastructure
  logSink_p.clearLocally();
  LogIO os(LogOrigin("calibrater", "initcalset()"), logSink_p);

  // Re-initialize cal scratch columns
  itsCI.initCalSet(calSet);

  // Log invocation into HISTORY table
  os << "calset=" << calSet << LogIO::POST;
  itsCI.writeHistory(os);
}

//----------------------------------------------------------------------------

Vector<Double> calibrater::modelfit(const Int& niter,
				    const String& type,
				    const Vector<Double>& par,
				    const Vector<Bool>& vary,
				    const String& file)
{
// Solve for a uv model
// Inputs:
//    type       iter      number of iterations
//

  try {

    return itsCI.modelfit(niter,type,par,vary,file);

  }
  catch (AipsError x) {

    String message("Ouch.");
    
    cout << message << endl;

    return Vector<Double>();

  }

};

//----------------------------------------------------------------------------

void calibrater::solve()
{
// Solve for the specified calibration components
//
   Bool retval = True;

   logSink_p.clearLocally();
   LogIO os (LogOrigin ("calibrater", "solve()"), logSink_p);
   os << "Solving:" << LogIO::POST;
   // Update HISTORY table
   itsCI.writeHistory(os);

   // Remind user what is being applied/solved for
   //state();
   applystate(True);
   solvestate(True);

   // Load all specified cal tables, else initialize the component
   loadSetCal ("P");
   loadSetCal ("T");
   loadSetCal ("TOPAC");
   loadSetCal ("GAINCURVE");
   loadSetCal ("B");
   loadSetCal ("BPOLY");
   loadSetCal ("G");
   loadSetCal ("GPOLY");
   loadSetCal ("GSPLINE");
   //   loadSetCal ("GDELAYRATESB");  
   loadSetCal ("D");
   loadSetCal ("K");
   loadSetCal ("M");
   loadSetCal ("MF");
   loadSetCal ("UVMOD");

   // Solve for the specified calibration components
   solveCal ("T");
   solveCal ("G");
   solveCal ("GPOLY");
   solveCal ("GSPLINE");
   //   solveCal ("GDELAYRATESB");
   solveCal ("B");
   solveCal ("BPOLY");
   solveCal ("D");
   solveCal ("K");
   solveCal ("M");
   solveCal ("MF");
   solveCal ("UVMOD");

   // Flush VisSet
   retval = itsCI.write();
   AlwaysAssert (retval, AipsError);

   // Update the cal tables on disk
   updateCal ("T");
   updateCal ("G");
   updateCal ("GPOLY");
   updateCal ("GSPLINE");
   //   updateCal ("GDELAYRATESB");
   updateCal ("B");
   updateCal ("BPOLY");
   updateCal ("D");
   //   updateCal ("M");

 };

//----------------------------------------------------------------------------

void calibrater::loadSetCal (const String& type)
{
// Load the calibration table if possible, else initialize
// Inputs:
//    type      String      Cal component type (eg. "G")
//
   Bool retval = True;
   LogIO os (LogOrigin ("calibrater", "loadSetCal()", WHERE));

   // Check if the component is to be applied
   if (itsApplyMap.isDefined(type)) {
     retval = itsCI.setApply (type, *(itsApplyMap(type)),rawspw_p);
   };

   // Check if the component is to be solved for
   if (itsSolveMap.isDefined(type)) {
     retval = itsCI.setSolve (type, *(itsSolveMap(type)));
   };
   AlwaysAssert (retval, AipsError);
};

//----------------------------------------------------------------------------

void calibrater::solveCal (const String& type)
{
// Solve for an individual cal component, if selected
// Inputs:
//    type       String      Cal component type (eg. "G")
//
   Bool retval = True;
   LogIO os (LogOrigin ("calibrater", "solveCal()", WHERE));

   // Check if solution requested for this component
   if (itsSolveMap.isDefined (type)) {
     // Do solution
     retval = itsCI.solve (type);
     AlwaysAssert (retval, AipsError);
   };
};

//----------------------------------------------------------------------------

void calibrater::updateCal (const String& type)
{
// Update cal table on disk
// Inputs:
//    type      String     Cal component type (eg. "G")
//
   Bool retval = True;
   LogIO os (LogOrigin ("calibrater", "updateCal()", WHERE));

   // Were an output table name and solution interval set ?
   String tname = "";
   Double tint = -1.0;
   if (itsSolveMap.isDefined (type)) {
     itsSolveMap(type)->get ("table", tname);
     if (itsSolveMap(type)->isDefined("t")) {
       itsSolveMap(type)->get ("t", tint);
     };
   };

   if (tname != "" && tint >= 0.0) {
     // Update table on disk, applying append flag
     Bool append = False;
     itsSolveMap(type)->get ("append", append);
     retval = itsCI.put (type, tname, append);
     AlwaysAssert (retval, AipsError);
   };
};

//----------------------------------------------------------------------------

void calibrater::correct()
{
// Apply the calibration to update the CORRECTED_DATA column in the MS
//

   Bool retval = True;

   logSink_p.clearLocally();
   LogIO os (LogOrigin ("calibrater", "correct()"), logSink_p);
   os << "Correcting:" << LogIO::POST;
   // Update HISTORY table
   itsCI.writeHistory(os);

   // Remind user what will be applied
   applystate(True);

   // Load all specified cal components; interpolate as required
   loadIntpCal ("P");
   loadIntpCal ("T");
   loadIntpCal ("TOPAC");
   loadIntpCal ("GAINCURVE");
   loadIntpCal ("B");
   loadIntpCal ("BPOLY");
   loadIntpCal ("G");
   loadIntpCal ("GPOLY");
   loadIntpCal ("GSPLINE");
   loadIntpCal ("D");
   loadIntpCal ("K");
   loadIntpCal ("M");
   loadIntpCal ("MF");

   // Apply the calibration solutions to the uv-data
   retval = itsCI.correct();
   AlwaysAssert (retval, AipsError);

   // Flush VisSet
   retval = itsCI.write();
   AlwaysAssert (retval, AipsError);

};

//----------------------------------------------------------------------------

void calibrater::loadIntpCal (const String& type)
{
// Load cal table, interpolate as required
// Inputs:
//     type      String      Cal component type (eg. "G")
//
   Bool retval = True;
   LogIO os (LogOrigin ("calibrater", "loadIntpCal()", WHERE));

   // Check if this calibration component is to be applied
   if (itsApplyMap.isDefined(type)) {
     retval = itsCI.setApply (type, *(itsApplyMap(type)));
   };

   AlwaysAssert (retval, AipsError);
};

//----------------------------------------------------------------------------

void calibrater::smooth(const String& infile,
                        const String& outfile,const Bool& append,
                        const String& select,
                        const String& smoothtype,const Double& smoothtime,
                        const String& interptype,const Double& interptime)
{
  // Call Calibrater::smooth
  itsCI.smooth(infile,
               outfile,append,
               select,
               smoothtype,smoothtime,
               interptype,interptime);
}

//----------------------------------------------------------------------------

void calibrater::fluxscale(const String& infile, 
			   const String& outfile,
			   const Vector<Int>& refField, 
			   const Vector<Int>& refSpwMap, 
			   const Vector<Int>& tranField,
			   const Bool& append,
			   GlishArray& fluxDensity) 
{
// Scale gain moduli according to reference fields
// Inputs:
//    infile       const String&            Input cal table
//    outfile      const String&            Output cal table
//    refField     const Vector<Int>        Reference field Ids
//    refSpwMap    const Vector<Int>        Reference spws, per spw
//    tranField    const Vector<Int>        Scale transfer field Ids
//    append       const Bool&              Append flag for output table
//
// Output 
//    fluxScaleFactor  Matrix<Double>       Matrix of flux density scale factors
//

  // Write parameters to HISTORY log
  logSink_p.clearLocally();
  LogIO os(LogOrigin("calibrater", "fluxscale()"), logSink_p);
  os << "infile=" << infile << " outfile=" << outfile
     << " refField=" << refField << " refSpwMap=" << refSpwMap
     << " tranField=" << tranField << " append=" << append << LogIO::POST;
  itsCI.writeHistory(os,True);

  // Invoke fluxscale on the calibrater object
  Matrix<Double> fluxScaleFactor;
  itsCI.fluxscale(infile,outfile,refField,refSpwMap,tranField,append,fluxScaleFactor);

  GlishArray fluxd(fluxScaleFactor);
  fluxDensity=fluxd;

};

//----------------------------------------------------------------------------
void calibrater::accumulate(const String& intab,
                            const String& incrtab,
                            const String& outtab,
                            const Vector<Int>& fields,
                            const Vector<Int>& calFields,
                            const String& interp,
                            const Double& t)
{
// Accumulate incremental calibration onto existing cumulative calibration
// Inputs:
//    intab        const String&            Input cumulative cal table
//    incrtab      const String&            Input incremental cal table
//    outtab       const String&            Output cumulative cal table
//    interp       const String&            Interpolation type for incr
//    t            const Double&            Cumulative timescale (for init)
//    fields       const Vector<Int>&       Fields in cumulative to treat
//    calFields    const Vector<Int>&       Fields in incremental to use
//
//
  // Invoke accumulate on the calibrater object
  itsCI.accumulate(intab,incrtab,outtab,fields,calFields,interp,t);

};

//----------------------------------------------------------------------------
void calibrater::close()
{
// Close calibrater object, detach measurement set
//
   if (itsMS) delete itsMS;
   itsMS = 0;
 };

//----------------------------------------------------------------------------

String calibrater::className() const
{
// Return class name for aips++ DO system
// Outputs:
//    className    String    Class name
//
   return "calibrater";
};

//----------------------------------------------------------------------------

Vector <String> calibrater::methods() const
{
// Return class methods names for aips++ DO system
// Outputs:
//    methods    Vector<String>   calibrater method names
//
   Vector <String> method(16);
   Int i = 0;
   method(i++) = "setdata";
   method(i++) = "setapply";
   method(i++) = "setsolve";
   method(i++) = "setsolvebandpoly";
   method(i++) = "setsolvegainpoly";
   method(i++) = "setsolvegainspline";
   method(i++) = "solve";
   method(i++) = "correct";
   method(i++) = "close";
   method(i++) = "state";
   method(i++) = "reset";
   method(i++) = "initcalset";
   method(i++) = "smooth";
   method(i++) = "fluxscale";
   method(i++) = "accumulate";
   method(i++) = "modelfit";
//
   return method;
};

//----------------------------------------------------------------------------

Vector <String> calibrater::noTraceMethods() const
{
// Methods for which automatic logging by the aips++ DO system is
// not required.
// Outputs:
//    noTraceMethods    Vector<String>   calibrater method names for no logging
//
   Vector <String> method(16);
   Int i = 0;
   method(i++) = "setdata";
   method(i++) = "setapply";
   method(i++) = "setsolve";
   method(i++) = "setsolvebandpoly";
   method(i++) = "setsolvegainpoly";
   method(i++) = "setsolvegainspline";
   method(i++) = "solve";
   method(i++) = "correct";
   method(i++) = "close";
   method(i++) = "state";
   method(i++) = "reset";
   method(i++) = "initcalset";
   method(i++) = "smooth";
   method(i++) = "fluxscale";
   method(i++) = "accumulate";
   method(i++) = "modelfit";
//
   return method;
};
//----------------------------------------------------------------------------

MethodResult calibraterFactory::make (ApplicationObject*& newObject,
   const String& whichConstructor, ParameterSet& inpRec,
   Bool runConstructor)
{
// Mechanism to allow non-standard constructors for the calibrater
// class as an aips++ DO
// Inputs:
//    whichConstructor    String            Constructor name
//    inpRec              ParameterSet      Input parameter set
//    runConstructor      Book              Execute constructor ?
// Outputs:
//    newObject           ApplicationObject Constructed object ref.
//
   // Intialization
   MethodResult retval;
   newObject = 0;

   // Case (constructor_type) of:
   // "calibrater":
   if (whichConstructor == "calibrater") {
      Parameter <String> msfile (inpRec, "msfile", ParameterSet::In);
      Parameter <Bool> compress (inpRec, "compress", ParameterSet::In);
      if (runConstructor) {
         MeasurementSet mstemp (msfile(), Table::Update);
         newObject = new calibrater (mstemp, compress());
       }
    } else {
      retval = String ("Unknown constructor ") + whichConstructor;
    };

   if (retval.ok() && runConstructor && !newObject) {
      retval = "Memory allocation error";
    };
   return retval;
 };
         
//----------------------------------------------------------------------------

MethodResult calibrater::runMethod (uInt which, ParameterSet& inpRec, 
   Bool runMethod)
{
// Mechanism to allow execution of class methods from the 
// aips++ DO system.
// Inputs:
//    which        uInt               Selected method
//    inpRec       ParameterSet       Associated input parameters
//    runMethod    Bool               Execute method ?
//

  static String returnvalString = "returnval";

  // Case method number of:
  switch (which) {

  case 0: {
    // setdata
    Parameter <String> mode (inpRec, "mode", ParameterSet::In);
    Parameter <Int> nchan (inpRec, "nchan", ParameterSet::In);
    Parameter <Index> start (inpRec, "start", ParameterSet::In);
    Parameter <Int> step (inpRec, "step", ParameterSet::In);
    Parameter <Quantity> mStart (inpRec, "mstart", ParameterSet::In);
    Parameter <Quantity> mStep (inpRec, "mstep", ParameterSet::In);
    Parameter <String> msSelect (inpRec, "msselect", ParameterSet::In);
    if (runMethod) {
      setdata (mode(), nchan(), start().zeroRelativeValue(), step(),
	       MRadialVelocity (mStart(), MRadialVelocity::LSR),
	       MRadialVelocity (mStep(), MRadialVelocity::LSR),
	       msSelect());
    };
  }
  break;
  
  case 1: {
    // setapply
    Parameter <String> type (inpRec, "type", ParameterSet::In);
    Parameter <Double> t (inpRec, "t", ParameterSet::In);
    Parameter <String> nameIn (inpRec, "table", ParameterSet::In);
    Parameter <String> interp (inpRec, "interp", ParameterSet::In);
    Parameter <String> select (inpRec, "select", ParameterSet::In);
    Parameter <Vector<Int> > spwmap (inpRec, "spwmap", ParameterSet::In);
    Parameter <Bool> unset (inpRec, "unset", ParameterSet::In);
    Parameter <Float> opacity (inpRec, "opacity", ParameterSet::In);
    Parameter <Vector<Index> > rawspw (inpRec, "rawspw", ParameterSet::In);
    Vector<Int> rawspwids(rawspw().nelements());
    for (uInt k=0; k < rawspwids.nelements(); ++k){
      rawspwids(k)=rawspw()(k).zeroRelativeValue();
    }
      
    if (runMethod) {
      setapply (type(), t(), nameIn(), interp(), select(), spwmap(), unset(), opacity(), rawspwids);
    };
  }
  break;
  
  case 2: {
    // setsolve
    Parameter <String> type (inpRec, "type", ParameterSet::In);
    Parameter <Double> t (inpRec, "t", ParameterSet::In);
    Parameter <Double> preavg (inpRec, "preavg", ParameterSet::In);
    Parameter <Bool> phaseonly (inpRec, "phaseonly", ParameterSet::In);
    Parameter <Int> refant (inpRec, "refant", ParameterSet::In);
    Parameter <String> nameOut (inpRec, "table", ParameterSet::In);
    Parameter <Bool> append (inpRec, "append", ParameterSet::In);
    Parameter <Bool> unset (inpRec, "unset", ParameterSet::In);
    if (runMethod) {
      setsolve (type(), t(), preavg(), phaseonly(), refant(), nameOut(), 
		append(), unset());
    };
  }
  break;
  
  case 3: {
    // setsolvebandpoly
    Parameter <String> nameOut (inpRec, "table", ParameterSet::In);
    Parameter <Bool> append (inpRec, "append", ParameterSet::In);
    Parameter <Int> degamp (inpRec, "degamp", ParameterSet::In);
    Parameter <Int> degphase (inpRec, "degphase", ParameterSet::In);
    Parameter <Bool> visnorm (inpRec, "visnorm", ParameterSet::In);
    Parameter <Bool> bpnorm (inpRec, "bpnorm", ParameterSet::In);
    Parameter <Int> maskcenter (inpRec, "maskcenter", ParameterSet::In);
    Parameter <Float> maskedge (inpRec, "maskedge", ParameterSet::In);
    Parameter <Int> refant (inpRec, "refant", ParameterSet::In);
    Parameter <Bool> unset (inpRec, "unset", ParameterSet::In);
    if (runMethod) {
      setsolvebandpoly (nameOut(), append(), degamp(), degphase(), 
			visnorm(), bpnorm(), maskcenter(), maskedge(),
			refant(), unset());
    };
  }
  break;
  
  case 4: {
    // setsolvegainpoly
    Parameter <String> nameOut (inpRec, "table", ParameterSet::In);
    Parameter <Bool> append (inpRec, "append", ParameterSet::In);
    Parameter <String> mode (inpRec, "mode", ParameterSet::In);
    Parameter <Int> degree (inpRec, "degree", ParameterSet::In);
    Parameter <Int> refant (inpRec, "refant", ParameterSet::In);
    Parameter <Bool> unset (inpRec, "unset", ParameterSet::In);
    if (runMethod) {
      setsolvegainpoly (nameOut(), append(), mode(), degree(), refant(), 
			unset());
    };
  }
  break;
  
  case 5: {
    // setsolvegainspline
    Parameter <String> nameOut (inpRec, "table", ParameterSet::In);
    Parameter <Bool> append (inpRec, "append", ParameterSet::In);
    Parameter <String> mode (inpRec, "mode", ParameterSet::In);
    Parameter <Double> preavg (inpRec, "preavg", ParameterSet::In);
    Parameter <Double> splinetime (inpRec, "splinetime", ParameterSet::In);
    Parameter <Int> refant (inpRec, "refant", ParameterSet::In);
    Parameter <Int> npointaver (inpRec, "npointaver", ParameterSet::In);
    Parameter <Double> phasewrap (inpRec, "phasewrap", ParameterSet::In);
    Parameter <Bool> unset (inpRec, "unset", ParameterSet::In);
    if (runMethod) {
      setsolvegainspline (nameOut(), append(), mode(), preavg(), splinetime(),
                          refant(), 
			  npointaver(), phasewrap(), 
			  unset());
    };
  }
  break;

  case 6: {
    // solve
    if (runMethod) solve();
  }         
  break;
    
  case 7: {
    // correct
    if (runMethod) correct();
  }         
  break;
  
  case 8: {
    // close
    if (runMethod) close();
  }         
  break;
  
  case 9: {
    // state
    if (runMethod) state();
  }
  break;

  case 10: {
    // reset
    Parameter <Bool> apply (inpRec, "apply", ParameterSet::In);
    Parameter <Bool> solve (inpRec, "solve", ParameterSet::In);
    if (runMethod) reset( apply(), solve() );
  }
  break;

  case 11: {
    // initcalset
    Parameter <Int> calset (inpRec, "calset", ParameterSet::In);
    if (runMethod) initcalset( calset() );
  }
  break;

  case 12: {
    // smooth
    Parameter <String> infile(inpRec,"infile",ParameterSet::In);
    Parameter <String> outfile(inpRec,"outfile",ParameterSet::In);
    Parameter <Bool> append(inpRec,"append",ParameterSet::In);
    Parameter <String> select(inpRec,"select",ParameterSet::In);
    Parameter <String> smoothtype(inpRec,"smoothtype",ParameterSet::In);
    Parameter <Double> smoothtime(inpRec,"smoothtime",ParameterSet::In);
    Parameter <String> interptype(inpRec,"interptype",ParameterSet::In);
    Parameter <Double> interptime(inpRec,"interptime",ParameterSet::In);

    if (runMethod) smooth(infile(),
                          outfile(), append(), 
                          select(),
                          smoothtype(), smoothtime(),
                          interptype(), interptime() );
  }         
  break;

  case 13: {
    // fluxscale
    //    static String fluxd = "fluxd";
    Parameter <String>          infile(inpRec,"infile",ParameterSet::In);
    Parameter <String>          outfile(inpRec,"outfile",ParameterSet::In);
    Parameter <Vector<Int> >    refField(inpRec,"reference",ParameterSet::In);
    Parameter <Vector<Int> >    refSpwMap(inpRec,"refspwmap",ParameterSet::In);
    Parameter <Vector<Int> >    tranField(inpRec,"transfer",ParameterSet::In);
    Parameter <Bool>            append(inpRec,"append",ParameterSet::In);
    Parameter <GlishArray>  fluxScaleFactor(inpRec,"fluxd",ParameterSet::Out);

    if (runMethod) fluxscale(infile(),
			     outfile(),
			     refField(),
			     refSpwMap(),
			     tranField(),
			     append(), 
			     fluxScaleFactor() );

  }         
  break;

  case 14: {
    // accumulate
    Parameter <String>          intab(inpRec,   "intab",ParameterSet::In);
    Parameter <String>          incrtab(inpRec, "incrtab",ParameterSet::In);
    Parameter <String>          outtab(inpRec,  "outtab",ParameterSet::In);
    Parameter <Vector<Int> >    field(inpRec,   "field",ParameterSet::In);
    Parameter <Vector<Int> >    calfield(inpRec,"calfield",ParameterSet::In);
    Parameter <String>          interp(inpRec,  "interp",ParameterSet::In);
    Parameter <Double>          t(inpRec,       "t",ParameterSet::In);
    
    if (runMethod) accumulate(intab(),
			      incrtab(),
			      outtab(),
			      field(),
			      calfield(),
			      interp(),
			      t() );
    
  }
  break;

  case 15: {
    // modelfit
    Parameter <Int>             niter(inpRec,"niter",ParameterSet::In);
    Parameter <String>          type(inpRec,"type",ParameterSet::In);
    Parameter <Vector<Double> > par(inpRec,"par",ParameterSet::In);
    Parameter <Vector<Bool> >   vary(inpRec,"vary",ParameterSet::In);
    Parameter <String>          file(inpRec,"file",ParameterSet::In);
    Parameter <Vector<Double> > returnval(inpRec,returnvalString,ParameterSet::Out);
    if (runMethod) returnval() = modelfit(niter(),type(),par(),vary(),file());
  }         
  break;

  default: 
    return error ("No such method");
  };
  return ok();
};

//----------------------------------------------------------------------------



