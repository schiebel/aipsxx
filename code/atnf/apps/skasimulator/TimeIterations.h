///////////////////////////////////////////////////////////////////////////////
//
//  TimeIterations - easy iteration over time slots specified by
//                   the start and stop time, averaging time and gap
//                   Can be used with both siderial and universal time 
//

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
//# $Id: TimeIterations.h,v 1.3 2005/09/19 04:19:10 mvoronko Exp $


#ifndef __TIMEITERATIONS_HPP
#define __TIMEITERATIONS_HPP

#include <casa/aips.h>
#include <casa/Quanta/MVEpoch.h>
#include <measures/Measures/MEpoch.h>
#include <casa/Exceptions/Error.h>


// an interface class for time slot calculators
struct ITimeSlotCalculator {
   // number of slots
   virtual casa::uInt getNumberOfSlots() const throw(casa::String, casa::AipsError) = 0;
   // return the siderial time of the given slot in radians
   virtual casa::Double getSidTime(casa::uInt index) const throw(casa::String, casa::AipsError) = 0;
   // return the UTC time of the given slot
   virtual casa::MVEpoch getUTCTime(casa::uInt index) const throw(casa::String, casa::AipsError) = 0;   
   // return the time difference between the two slots starting from index
   virtual casa::Quantity getTimeStep(casa::uInt index) const throw(casa::String, casa::AipsError) = 0;
   // set the correlator averaging time and gap between consequtive measurements
   virtual void setCorParams(const casa::Quantity &icoravg, const casa::Quantity &icorgap)
                     throw(casa::AipsError) = 0;   		     
   virtual ~ITimeSlotCalculator();		     
};

// an iterator over arbitrary time slots
class TimeSlotIterator {
public:
   // a supplementary class to allow easy access to the data fields
   struct Slot {
      casa::Double sidereal;
      casa::MVEpoch utc;   
   };
   
   TimeSlotIterator(const ITimeSlotCalculator *islots = NULL,
                    casa::uInt start = 0) throw();

   // access to the current slot
   const Slot& operator*() const throw(casa::String);
   const Slot* operator->() const throw(casa::String);

   // increment
   TimeSlotIterator& operator++() throw(casa::String, casa::AipsError);

   // comparison
   casa::Bool operator!=(const TimeSlotIterator &in) const throw(casa::String, casa::AipsError);
   casa::Bool operator==(const TimeSlotIterator &in) const throw(casa::String, casa::AipsError);

protected:
   // read the index-th element into cache
   void fillCache() const throw(casa::String, casa::AipsError);

private:
   const ITimeSlotCalculator *slots; // to benefit from polymorphism
                                     // = NULL for endmark object
		     	             // use a reference symantics
   mutable casa::uInt index; // current index
   casa::uInt nelements; // number of slots (from getNumberOfSlots())
   mutable Slot cache; // times for the current item
   mutable casa::Bool endmark; // true if the end is reached and cache no longer
                         // contains a valid information
};

// a wrapper for different time slot binnings. The main goal of this
// class is to remove pointer operations from ImplSKASimulator
// and provide different slot calculators using overloaded functions
class TimeSlots {
   ITimeSlotCalculator *slots; // to benefit from polymorphism
   casa::Bool is_time_defined; // true if start/stop times have been set
   casa::Bool is_corparams_defined; // true if coravg/corgap have been set
   casa::Quantity coravg, corgap; // corelator averaging time and gap
                            // a buffer to allow this quantities set
			    // in any order with setTimes
public:
   TimeSlots();
   ~TimeSlots();

   // access to iterators
   typedef TimeSlotIterator const_iterator;
   TimeSlotIterator begin() const throw();
   TimeSlotIterator end() const throw();

   // check status
   casa::Bool isTimeDefined() const throw();
   casa::Bool isCorParamsDefined() const throw();

   // two quantities, start and stop, are the angles representing
   // sidereal time range
   // day - is approximate UTC epoch to have something reasonable
   //       stored in the measurement set
   void setSiderealTimes(const casa::Quantity &start, const casa::Quantity &stop,
                         const casa::MVEpoch &day = casa::MVEpoch(53355.62801))
			       throw(casa::String, casa::AipsError);
   // start and stop are two epochs (may be LST or UTC, or whatever is
   // supported in AIPS++)
   void setTimes(const casa::MEpoch &start, const casa::MEpoch &stop)
                               throw(casa::String, casa::AipsError);

   // set the correlator averaging time and gap between consequtive measurements
   void setCorParams(const casa::Quantity &icoravg, const casa::Quantity &icorgap)
                     throw(casa::AipsError);

   // number of slots
   casa::uInt getNumberOfSlots() const throw(casa::String, casa::AipsError);

   // return the time difference between the two slots starting from index
   casa::Quantity getTimeStep(casa::uInt index = 0) const throw(casa::String, casa::AipsError);

};

class SiderealTimeSlots : public ITimeSlotCalculator {
  casa::Quantity start, stop;    // start and stop sidereal time
  casa::MVEpoch  utcday;         // utc day to have getUTCTime returining something
                           // realistic
  casa::Quantity coravg,corgap;  // correlator averaging time & gap, always in
                           // ordinary (not sidereal) time units
public:
  SiderealTimeSlots(const casa::Quantity &istart, const casa::Quantity &istop,
                    const casa::MVEpoch &iutcday);

  // number of slots
  virtual casa::uInt getNumberOfSlots() const throw(casa::String, casa::AipsError);

  // return the siderial time of the given slot in radians
  virtual casa::Double getSidTime(casa::uInt index) const throw(casa::String, casa::AipsError);

  // return the time difference between the two slots starting from index
  virtual casa::Quantity getTimeStep(casa::uInt) const throw(casa::String, casa::AipsError);

  // return the UTC time of the given slot
  virtual casa::MVEpoch getUTCTime(casa::uInt index) const throw(casa::String, casa::AipsError);
  
  // set the correlator averaging time and gap between consequtive measurements
  virtual void setCorParams(const casa::Quantity &icoravg, const casa::Quantity &icorgap)
                    throw(casa::AipsError);
};

class EpochTimeSlots : public ITimeSlotCalculator {
  casa::MEpoch start, stop; // start and stop siderial times in radians
  casa::Quantity coravg, corgap; // correlator averaging time & gap, always in
                           // ordinary seconds
public:
  EpochTimeSlots(const casa::MEpoch &istart, const casa::MEpoch& istop);

  // number of slots
  virtual casa::uInt getNumberOfSlots() const throw(casa::String, casa::AipsError);

  // return the siderial time of the given slot in radians
  virtual casa::Double getSidTime(casa::uInt index) const throw(casa::String, casa::AipsError);

  // return the time difference between the two slots starting from index
  virtual casa::Quantity getTimeStep(casa::uInt) const throw(casa::String, casa::AipsError);

  // return the UTC time of the given slot
  virtual casa::MVEpoch getUTCTime(casa::uInt index) const throw(casa::String, casa::AipsError);
  
  // set the correlator averaging time and gap between consequtive measurements
  virtual void setCorParams(const casa::Quantity &icoravg, const casa::Quantity &icorgap)
                    throw(casa::AipsError);    
};


#endif // #ifndef __TIMEITERATIONS_HPP
