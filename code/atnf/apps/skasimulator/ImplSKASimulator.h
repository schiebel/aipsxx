// ImplSKASimulator object to simulate AIPS++ datasets
//                for simple models and do some experiments related
//                to SKA design
//                It is split from distributed object to have a better
//                incapsulation of code and separation of a glish
//                interface from actual calculation

//# Copyright (C) 1999,2000
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
//# $Id: ImplSKASimulator.h,v 1.3 2005/09/19 04:19:10 mvoronko Exp $


// AIPS++ stuff
#include <casa/aips.h>
#include <casa/Quanta/MVFrequency.h>
#include <casa/Quanta/MVTime.h>
#include <casa/Exceptions/Error.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <components/ComponentModels/ComponentList.h>
#include <components/ComponentModels/SkyComponent.h>

// own include files
#include "TimeIterations.h"
#include "RFIModel.h"
#include "NoiseModel.h"
#include "DelayModel.h"

// ImplSKASimulator - SKA Simulator Implementation
class ImplSKASimulator {
  // layout of the interferometer
  casa::Vector<casa::MPosition> layout;    // positions of antennae
  casa::Vector<casa::Quantity> diam;       // antenna diameters
  //
  casa::Bool is_layout_set;   // true if setLayout was invoked at least once
                        // and there is a valid layout
  // Sky model
  casa::ComponentList  skymodel; // components describing sky model
                           // e.g. a list of point sources
  casa::Bool is_skymodel_set; // true if setSkyModel was invoked at least once,
                        // the model may be invalid, however
  TimeSlots timeslots;  // this object implements iterations over time slots
  casa::uInt nchannels;       // Number of spectral channels to simulate
  casa::Quantity chbandw;    // Bandwidth of individual spectral channel
  casa::Bool dotasmear;      // if true, simulate the time average smearing
  casa::Bool dobandsmear;    // if true, simulate the bandwidth smearing
  casa::Double avgtime;      // average time in seconds
  casa::Bool dosky;          // Sky model will be simulated, if true
  casa::Bool dorfi;          // RFI will be simulated, if true
  casa::Bool donoise;        // Noise will be added, if true
  casa::Bool dovp;           // Primary beam (voltage pattern) will be
                             // simulated, if true
  casa::Bool dodelay;        // Residual delays are simulated, if true
  RFIModel *rfimodel;  // Object, which can simulate RFI; NULL if it is not
                       // set up
  RandomGenerator
          *noisemodel; // Object, which can generate a noise
  DelayModel *delaymodel; // Object, which can simulate residual delays;
                          // NULL if it is not set up
  // the next is for experiments only (to investigate the accuracy required for clean components). It is not used in normal work
  mutable GaussianGenerator ccnoise; // generator of the CC position
public:
   ImplSKASimulator() throw(casa::AipsError);
   ~ImplSKASimulator() throw();

   // set layout; all further calculations will be done for this layout
   // ix,iy,iz - global positions of each antenna
   // idiam  - diameter of each antenna in metres
   // return false if something is wrong
   casa::Bool setITRFLayout(const casa::Vector<casa::Double> &ix, const casa::Vector<casa::Double> &iy,
                      const casa::Vector<casa::Double> &iz,
                      const casa::Vector<casa::Double> &idiam)  throw();

   // Control of various options: set uo what is to be simulated
   // idosky - if true, simulate sky
   // idobandsmear - if true, simulate bandwidth smearing
   // idotasmear - if true, simulate time average smearing
   // idorfi     - if true, simulate rfi
   // idonoise   - if true, simulate noise
   // idovp      - if true, simulate voltage pattern (primary beam)
   // idodelay   - if true, simulate residual delays
   casa::Bool setOptions(casa::Bool idosky, casa::Bool idobandsmear, casa::Bool idotasmear,
                   casa::Bool idorfi, casa::Bool idonoise,
		   casa::Bool idovp, casa::Bool idodelay) throw();
		  
   // set sky model to simulate; all further calculations will be done for
   // this sky model. Input parameter is a name of the external table
   // return false if something is wrong
   casa::Bool setSkyModel(const casa::String &smname)  throw();

   // set RFI model - a single moving source of a spherical wave (broadband)
   // flux - rfi flux density at the reference position Rc (e.g. core)
   // Rr    - position of the interferor
   // Rrdot - velocity (a vector quantity) of the interferor specified as
   //         an increment of Rr per the unit of time (defined below)
   // timeunit - unit of time (e.g. second)
   // return false, if something is wrong
   casa::Bool setRFIModel(const casa::Quantity &flux, const casa::MPosition &Rc,
                    const casa::MPosition &Rr, const casa::MPosition &Rrdot,
		    const casa::Unit &timeunit) throw();

   // set delay model, effects taken into account are described by the input
   // string. Possible values are
   // "all" simulate everything which this code can do (default)
   // "gravdelayonly" simulate gravitational delay only
   // "orbitalonly"   simulate the delay due to the orbital motion
   // "diurnalonly"   simulate the delay due to the diurnal motion
   // "orbitalanddiurnal"  simulate the delay due to the orbital and diurnal motions   
   // return false, if something is wrong (e.g. the string is unrecognized)
   casa::Bool setDelayModel(const casa::String &in="all") throw();


   // summarize the status in the logger, or just update the record
   // adding the status information if beQuiet=True
   // The fields of this record are as follows:
   // layoutset     - T if layout is set, F otherwise
   // dotasmear     - T if time average smearing will be simulated
   // dobandsmear   - T if bandwidth smearing will be simulated
   // nchannels     - Number of spectral channels
   // chbandw       - Channel Bandwidth (Quantity)
   // avgtime       - Average Time (Quantity)
   // dosky         - T if sky model will be used to calculate visibilities
   //    if T additional fields exist
   //    skymodelset - T if sky model is set, F otherwise
   //    nsources    - number of sources in the model
   // dorfi          - T is an rfi has to be simulated
   //    if T an additional field exists
   //    rfimodelset - T if rfi model is set, F otherwise   
   // donoise        - T if a noise has to be simulated
   //    if T an additional field exists
   //    noisemodelset
   // dodelay        - T if residual delays are simulated
   //    if T additional fields exist
   //    delaymodelset - T if a delay model is set, F otherwise
   //               the rest fields present only if delaymodelset is T
   //    gravdelay    - T if a gravitational delay has to be simulated
   //    orbitaldelay - T if a delay due to Earth's orbital motion has
   //                      to be simulated
   //    diurnaldelay - T if a delay due to Earth's diurnal rotation has
   //                     to be simulated
   // Return True if the operation is successful, otherwise False
   casa::Bool getStatus(casa::RecordInterface &rec, casa::Bool beQuiet = casa::False) const throw();
  
   

   // set additive gaussian noise as a noise model
   // variance - sqrt(dispersion). If mean=0 (default), it is equal to rms
   // mean - expectation of the value   
   casa::Bool setAddGaussianNoise(const casa::Quantity &variance,
                            const casa::Quantity &mean = casa::Quantity(0.,"Jy")) throw();

   // simulate the experiment and store the data in the data set fname
   // freq - observed frequency (1st channel)
   // phasecntr - direction to the phase centre
   // if dosky is true, visibilities due to sky model are simulated
   // if dorfi is true, visibilities due to rfi model are simulated
   // if donoise is true, noise is added
   casa::Bool simulate(const casa::String &fname, const casa::Quantity &freq,
                 const casa::MDirection &phasecntr)  throw();

   // set times when the observations are done using sidereal time
   // at the Greenwich meridian (sidstart and sidstop)
   // day - epoch to form the time correctly in the measurement set
   //       (may be a dummy number)
   casa::Bool setSiderealTimes(const casa::Quantity &sidstart, const casa::Quantity &sidstop,
              const casa::MEpoch &day = casa::MEpoch(casa::Quantity(53355.),
		                               casa::MEpoch::UTC))
	                             throw();

   // set times when the observations are done using fully specified
   // MEpoch object (e.g. UTC time, or whatever is defined in AIPS++)   
   casa::Bool setTimes(const casa::MEpoch &start, const casa::MEpoch &stop) throw();

   // set correlator parameters
   // coravg - averaging time
   // corgap - gap between measurements
   casa::Bool setCorParams(casa::Int inchannels, const casa::Quantity &ichbandw,
                     const casa::Quantity &coravg, const casa::Quantity &corgap)
		           throw();

   // tests with geometric delays (baseline ij)
   // offsets - offsets in radians
   casa::Bool simResidualDelays(casa::Vector<casa::Double> &delays,
                               const casa::Vector<casa::Double> &offsetsx,
                               const casa::Vector<casa::Double> &offsetsy,
                               casa::uInt i, casa::uInt j,
                               const casa::MDirection &phasecentre,
			       const casa::MFrequency &freq) const throw();
   
protected:

   // return a unit vector pointed to the source (coord. sys is the same
   // as for (X,Y,Z). The Hour angle (hangle) and declination (dec) are
   // in radians
   casa::Vector<casa::Double> getSVector(casa::Double hangle, casa::Double dec) const throw();

   // check whether the source is visible at a given antenna
   casa::Bool isVisible(const casa::Vector<casa::Double> &s, casa::uInt ant) const throw(casa::String);

   // return a vector with uvw for the ij baseline
   // hangle and dec  are hour angle and declination in radians, respectively
   casa::Vector<casa::Double> getUVW(casa::Double hangle, casa::Double dec, casa::uInt i,
                         casa::uInt j) const throw(casa::String);

   // return a vector with time derivatives of uvw for the ij baseline
   // hangle and dec are hour angle and declination in radians, respectively
   casa::Vector<casa::Double> getUVWRates(casa::Double hangle, casa::Double dec, casa::uInt i,
                              casa::uInt j) const throw(casa::String);

   // return the parallatic angle in radians for a given time, antenna
   // and phase centre. The siderial time is specified in radians
   casa::Double getParAngle(const casa::MEpoch &time, casa::uInt ant,
                            const casa::MDirection &phasecntr) const
			             throw(casa::String, casa::AipsError);

   // an auxiliary function to calculate a value of 2-D gaussian
   // (temporary)
   static casa::Double calcGauss(casa::Double l, casa::Double m,
                                 casa::Double pa, casa::Double lambda) throw();
    
   // calculate a pure visibility of the specified component without
   // RFI, calibration error or noise
   // uvw - a vector of UVW (in metres),
   // phasecntr - a direction to the phase centre
   // freq - an observed frequency
   // if dotasmear = true, timeaverage smearing is simulated using
   //     uvwrate - a vector of time derivatives of UVW (in metres per second)
   //     avgtime - average time in seconds
   // if dobandsmear = true, bandwidth smearing is simulated using
   //     bandwidth - a bandwidth of this spectral channel
   // if dovp = true, a voltage pattern will be simulated
   //    using parangle1 and parangle2 - parallactic angles of the phase
   //    centre at individual antennae
   casa::Complex getSCVisibility(const casa::SkyComponent &skycomp,
                         const casa::Vector<casa::Double> &uvw,
			 const casa::MDirection &phasecntr,
			 const casa::MVFrequency &freq,
			 const casa::Vector<casa::Double> &uvwrate,
			 casa::Double parangle1, casa::Double parangle2)
			    const throw(casa::AipsError, casa::String);
				       
   // calculate a sky visibility (no RFI, error or noise) using a preset
   // sky brightness model
   casa::Complex getSkyVisibility(const casa::Vector<casa::Double> &uvw,
                            const casa::MDirection &phasecntr,
			    const casa::MVFrequency &freq,
			    const casa::Vector<casa::Double> &uvwrate,
			    casa::Double parangle1, casa::Double parangle2)
			       const throw(casa::AipsError, casa::String);
			       
   // calculate a geometric delay for a given pair of antennae (baseline ij)
   // This function is used only in the experimental code and doesn't affect
   // the main functionality of the simulator
   casa::Double getGeometricDelay(casa::uInt i, casa::uInt j,
            const casa::MDirection &dir, const casa::MVFrequency &freq)
	          const throw(casa::AipsError);

   // for experiments only, not used in normal simulations.
   // store information about the current baseline to be able to use
   // it in those parts of the code, where uvw's are not sufficient
   void setBaselineParameters(casa::uInt i, casa::uInt j)
                          const throw();
private:
   // some cached values which are not used in normal simulations
   // (intended to use in the case where uvw's are not enough)
   mutable casa::uInt cache_ant1; // index of the first antenna
   mutable casa::uInt cache_ant2; // index of the second antenna
};
