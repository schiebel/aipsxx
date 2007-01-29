//# DOcalibrater.h: Define the calibrater DO
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
//# Correspondence concerning AIPS++ should be adressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: DOcalibrater.h,v 19.18 2006/12/22 04:48:11 gvandiep Exp $

#ifndef APPSGLISH_DOCALIBRATER_H
#define APPSGLISH_DOCALIBRATER_H

#include <casa/aips.h>
#include <tasking/Tasking.h>
#include <casa/BasicSL/String.h>
#include <casa/Containers/Record.h>
#include <casa/Containers/SimOrdMap.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <measures/Measures/MRadialVelocity.h>
#include <synthesis/MeasurementComponents/Calibrater.h>

#include <casa/namespace.h>
// <summary> 
// calibrater: Calibrater class, forming the basis of the calibrater DO
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
//   <li> <linkto class="skyImpl">skyImpl</linkto> module
// </prerequisite>
//
// <etymology>
// From "calibrater".
// </etymology>
//
// <synopsis>
// Module DOcalibrater defines the calibrater classes which form the basis
// of the calibrater DO. It is used in conjunction with the sky DO
// to provide calibration capabilities within the synthesis package. 
// The basic responsibilities of the calibrater are to determine
// and apply calibration information for data stored in an aips++ 
// measurement set.
// </etymology>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation>
// The calibration aspects of synthesis processing form a coherent
// subset, with sufficient features and structure to be represented 
// as a separate class, with associated DO.
// </motivation>
//
// <todo asof="98/01/05">
//
// </todo>

class calibrater : public ApplicationObject
{
 public:
   // Default constructor, and destructor
   calibrater();
   ~calibrater();

   // Construct from an existing measurement set and a flag
   // to specify optional compression of the calibration
   // columns (MODEL_DATA, CORRECTED_DATA and IMAGING_WEIGHT).
   calibrater (MeasurementSet& ms, Bool compress);

   // Copy constructor and assignment
   calibrater (const calibrater& other);
   calibrater& operator= (const calibrater& other);

   // Define the measurement set selection parameters
   void setdata (const String& mode, const Int& nchan, const Int& start,
		 const Int& step, const MRadialVelocity& mStart,
		 const MRadialVelocity& mStep, const String& msSelect);

   // Set the calibration application information for each component
   void setapply (const String& type, const Double& t, const String& table, 
		  const String& interp,
		  const String& select, const Vector<Int>& spwmap,
		  const Bool& unset, 
                  const Float& opacity,
		  const Vector<Int>& rawspw);

   // Set the solution information for each calibration component
   void setsolve (const String& type, const Double& t, const Double& preavg,
		  const Bool& phaseonly, const Int& refant, 
		  const String& table, const Bool& append, const Bool& unset);

   // Set solver parameters for specific solver types.
   // i) Polynomial bandpass solutions over frequency (BJonesPoly)
   void setsolvebandpoly (const String& table, const Bool& append, 
			  const Int& degamp, const Int& degphase,
			  const Bool& visnorm, const Bool& bpnorm,
			  const Int& maskcenter, const Float& maskedge,
			  const Int& refant, const Bool& unset);

   // ii) Polynomial electronic gain solutions over time (GJonesPoly) 
   void setsolvegainpoly (const String& table, const Bool& append,
			  const String& mode, const Int& degree, 
			  const Int& refant, const Bool& unset);

   // iii) Spline electronic gain solutions over time (GJonesSpline)
   void setsolvegainspline (const String& table, const Bool& append,
			    const String& mode, const Double& preavg,
                            const Double& splinetime,
			    const Int& refant, const Int& npoi,
			    const Double& anglewrap, const Bool& unset);

   // Obtain apply/solve state of the calibrater tool
   void state();

   // Solve for the specified calibration components
   void solve();

   // Solve for the specified calibration components
   Vector<Double> modelfit(const Int& niter,
			   const String& type,
			   const Vector<Double>& par,
			   const Vector<Bool>& vary,
			   const String& file);

   // Apply calibration
   void correct();

   // Smooth calibration
   void smooth(const String& infile,
               const String& outfile, const Bool& append,
               const String& select,
               const String& smoothtype, const Double& smoothtime,
               const String& interptype, const Double& interptime);

  // Fluxscale
  void fluxscale(const String& infile, 
		 const String& outfile,
		 const Vector<Int>& refField, 
		 const Vector<Int>& refSpwMap, 
		 const Vector<Int>& tranField,
		 const Bool& append,
		 GlishArray& fluxDensity);


  // Accumulate (incremental)
  void accumulate(const String& intab,
		  const String& incrtab,
		  const String& outtab,
		  const Vector<Int>& fields,
		  const Vector<Int>& calFields,
		  const String& interp="linear",
		  const Double& t=-1.0);

   // Reset the entire state of the calibrater tool
   void reset(const Bool& apply, const Bool& solve);

   // Re-initialize the calibration scratch columns
   void initcalset(const Int& calSet);

   // Close, detach measurement set
   void close();

   // Methods required to distribute the class as an aips++ DO
   // i) return the class name
   virtual String className() const;

   // ii) return a list of class methods
   virtual Vector <String> methods() const;

   // iii) return a list of methods for which no logging is required
   virtual Vector <String> noTraceMethods() const;
   
   // iv) Execute individual methods
   virtual MethodResult runMethod (uInt which, ParameterSet& inpRec,
      Bool runMethod);

 private:

   // Pointer to the underlying measurement set
   MeasurementSet* itsMS;

   // Calibrater object; overlay this class for now
   Calibrater itsCI;

   // Calibration table assignments and information
   SimpleOrderedMap <String, Record*> itsApplyMap;
   SimpleOrderedMap <String, Record*> itsSolveMap;

   // Open the measurement set
   void open (MeasurementSet& ms);

   // Add, or remove, an entry to the solver map (per Jones matrix type)
   void setsolve (const String& type, Record*& solver, const Bool& unset);

   // Obtain apply state of the calibrater tool
   void applystate(Bool writeMSHistory = False);

   // Obtain solve state of the calibrater tool
   void solvestate(Bool writeMSHistory = False);

   // Set default parameter values
   void defaults();

   // Load existing cal table, else initialize cal component
   void loadSetCal (const String& type);

   // Load existing cal table, interpolate as required
   void loadIntpCal (const String& type);

   // Solve for an individual cal component
   void solveCal (const String& type);

   // Update cal table on disk
   void updateCal (const String& type);

   // Raw phase transfer spw
   Vector<Int> rawspw_p;

   // Sink used to store history
   LogSink logSink_p;

 };

class calibraterFactory : public ApplicationObjectFactory
{
 public:
   // Mechanism to allow non-standard constructors for class
   // calibrater as an aips++ distributed object.
   virtual MethodResult make (ApplicationObject*& newObject,
      const String& whichConstructor, ParameterSet& inpRec,
      Bool runConstructor);
 };

#endif
