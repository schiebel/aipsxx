///////////////////////////////////////////////////////////////////////////////
//
//  TimeIterations - easy iteration over time slots specified by
//                   the start and stop time, averaging time and gap
//                   Can be used with both sidereal and universal time 
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
//# $Id: TimeIterations.cc,v 1.3 2005/09/19 04:19:10 mvoronko Exp $


#include "TimeIterations.h"
#include <measures/Measures.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MeasConvert.h>
#include <measures/Measures/MeasRef.h>
#include <exception>

// a useful constant (sidereal second in ordinary seconds)
const casa::Double sidsec=1./1.00278;

using namespace casa;

///////////////////////////////////////////////////////////////////////////////
//
// an interface class for time slot calculators
//

ITimeSlotCalculator::~ITimeSlotCalculator() {}

//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// TimeSlotIterator - an iterator over arbitrary time slots
//

TimeSlotIterator::TimeSlotIterator(const ITimeSlotCalculator *islots,
       casa::uInt start) throw() : slots(islots), index(start), endmark(true)
{
  if (islots!=NULL) { // a valid pointer, so we can read the data
      nelements=slots->getNumberOfSlots();
      
      if (!nelements && !index) // no slots available to iterate
          return;
	  
      if (index>=nelements)
          throw String("An attempt to access more slots than exist");
      endmark=false;	  
      fillCache();	  
  }
}

// access to the current slot
const TimeSlotIterator::Slot& TimeSlotIterator::operator*()
                                         const throw(casa::String)
{
  if (endmark) throw String("An attempt to resolve a void iterator");
  return cache;
}

const TimeSlotIterator::Slot* TimeSlotIterator::operator->()
                                           const throw(casa::String)
{
  if (endmark) throw String("An attempt to resolve a void iterator");
  return &cache;
}

// comparison
Bool TimeSlotIterator::operator!=(const TimeSlotIterator &in)
                 const throw(casa::String, casa::AipsError)
{
  if (in.slots==NULL && slots==NULL) return false;
  if (endmark) {
      if (in.slots==NULL) return false;
      return !in.endmark;
  }
  if (in.endmark) {
      if (slots==NULL) return false;
      return !endmark;
  }
  if (slots!=in.slots) return true;
  return (index!=in.index);
}

Bool TimeSlotIterator::operator==(const TimeSlotIterator &in)
                 const throw(casa::String, casa::AipsError)
{
  if (in.slots==NULL && slots==NULL) return true;
  if (endmark) {
      if (in.slots==NULL) return true;
      return in.endmark;
  }
  if (in.endmark) {
      if (slots==NULL) return true;
      return endmark;
  }
  if (slots!=in.slots) return false;
  return (index==in.index);
}

// increment
TimeSlotIterator& TimeSlotIterator::operator++() throw(casa::String, casa::AipsError)
{
  if (endmark) throw String("An attempt to increment an end iterator");
  ++index;
  if (index>=nelements) endmark=true;
  else fillCache();
  return *this;
}

// read the index-th element into cache
void TimeSlotIterator::fillCache() const throw(casa::String, casa::AipsError)
{  
  cache.sidereal=slots->getSidTime(index);
  cache.utc=slots->getUTCTime(index);  
}

//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// TimeSlots
//
// a wrapper for different time slot binnings. The main goal of this
// class is to remove pointer operations from ImplSKASimulator
// and provide different slot calculators using overloaded functions
//

TimeSlots::TimeSlots() : slots(NULL), is_time_defined(false),
       is_corparams_defined(false), coravg(Quantity(10.,"s")),
       corgap(Quantity(5.,"s")) {}
       
TimeSlots::~TimeSlots() {
   if (slots!=NULL) delete slots;
}

// access to iterators
TimeSlotIterator TimeSlots::begin() const throw() {
   return TimeSlotIterator(slots);
}

TimeSlotIterator TimeSlots::end() const throw()
{
   return TimeSlotIterator();
}

// check status
Bool TimeSlots::isTimeDefined() const throw()
{
   return is_time_defined;
}

Bool TimeSlots::isCorParamsDefined() const throw()
{
  return is_corparams_defined;
}

// set the correlator averaging time and gap between consequtive measurements
void TimeSlots::setCorParams(const casa::Quantity &icoravg, const casa::Quantity &icorgap)
                  throw(casa::AipsError)
{
  coravg=icoravg; corgap=icorgap;
  if (slots!=NULL) slots->setCorParams(coravg,corgap);
  is_corparams_defined=true;
}

// start and stop are two epochs (may be LST or UTC, or whatever is
// supported in AIPS++)
void TimeSlots::setTimes(const casa::MEpoch &start, const casa::MEpoch &stop)
      throw(casa::String, casa::AipsError)
{
  if (slots!=NULL) delete slots;
  try {
       slots=new EpochTimeSlots(start,stop); 
  }
  catch (std::bad_alloc &ba) {
      casa::String what=String("Bad Alloc.: ")+ba.what();
      is_time_defined=false;
      throw what;
  }
  if (is_corparams_defined)
      slots->setCorParams(coravg,corgap);
  is_time_defined=true;      
}

// two quantities, start and stop, are the angles representing
// sidereal time range
// day - is approximate UTC epoch to have something reasonable
//       stored in the measurement set
void TimeSlots::setSiderealTimes(const casa::Quantity &start, const casa::Quantity &stop,
                      const casa::MVEpoch &day) throw(casa::String, casa::AipsError)
{
  if (slots!=NULL) delete slots;
  try {
       slots=new SiderealTimeSlots(start,stop,day); 
  }
  catch (std::bad_alloc &ba) {
      casa::String what=String("Bad Alloc.: ")+ba.what();
      is_time_defined=false;
      throw what;
  }
  if (is_corparams_defined)
      slots->setCorParams(coravg,corgap);
  is_time_defined=true;
}

// number of slots
uInt TimeSlots::getNumberOfSlots() const throw(casa::String,AipsError)
{
  if (!is_corparams_defined || !is_time_defined || slots==NULL)
      throw String("Parameters of the TimeSlots() object are not set up");
  return slots->getNumberOfSlots();      
}

// return the time difference between the two slots starting from index
casa::Quantity TimeSlots::getTimeStep(casa::uInt index) const throw(casa::String, casa::AipsError)
{
  if (!is_corparams_defined || !is_time_defined || slots==NULL)
      throw String("Parameters of the TimeSlots() object are not set up");
  return slots->getTimeStep(index);      
}
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// EpochTimeSlots
//

EpochTimeSlots::EpochTimeSlots(const casa::MEpoch &istart, const casa::MEpoch& istop) :
    start(istart), stop(istop)
{
  MEpoch::Ref outref(MEpoch::UTC);
  if (istart.getRef()!=outref) {
      MEpoch::Convert conv(istart.getRef(),outref);
      start=conv(istart);
  }
  if (istop.getRef()!=outref) {
      MEpoch::Convert conv(istop.getRef(),outref);
      stop=conv(istop);
  }  
}

// set correlator averaging and gap time
void EpochTimeSlots::setCorParams(const casa::Quantity& icoravg,
                              const casa::Quantity& icorgap) throw(casa::AipsError)
{
  coravg=icoravg;
  corgap=icorgap;  
}

uInt EpochTimeSlots::getNumberOfSlots()  const throw(casa::String, casa::AipsError)
{     
     return uInt(floor((stop.getValue().getTime("rad").getValue("rad")-
                        start.getValue().getTime("rad").getValue("rad")+
            corgap.getValue("rad"))/(coravg.getValue("rad")+corgap.getValue("rad"))));
}

// return the time difference between the two slots starting from index
casa::Quantity EpochTimeSlots::getTimeStep(casa::uInt) const 
                             throw(casa::String, casa::AipsError)
{
  return (coravg+corgap);
}


// return a sidereal time of the given slot in radians
Double EpochTimeSlots::getSidTime(casa::uInt index)
             const throw(casa::String, casa::AipsError)
{
   MEpoch::Ref outref(MEpoch::GMST1);
   MEpoch::Convert utc2gmst(start.getRef(),outref);
   casa::MVEpoch slotutct=(start.getValue()+(coravg+corgap)*Double(index)/sidsec+
                  0.5*coravg/sidsec);
   casa::Double sidtime=utc2gmst(MEpoch(slotutct,
          MEpoch::Ref(MEpoch::UTC))).getValue().getTime().getValue("rad");
   sidtime-=2.*M_PI*floor(sidtime/2./M_PI);
   return sidtime;
}

// return the UTC time of the given slot
MVEpoch EpochTimeSlots::getUTCTime(casa::uInt index) const throw(casa::String, casa::AipsError)
{
   return (start.getValue()+(coravg+corgap)*Double(index)/sidsec+
                  0.5*coravg/sidsec);    
}

//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// SiderealTimeSlots
//

SiderealTimeSlots::SiderealTimeSlots(const casa::Quantity &istart,
  const casa::Quantity &istop, const casa::MVEpoch &iutcday) : start(istart),
   stop(istop), utcday(iutcday) {}

// set correlator averaging and gap time
void SiderealTimeSlots::setCorParams(const casa::Quantity& icoravg,
                              const casa::Quantity& icorgap) throw(casa::AipsError)
{
  coravg=icoravg;
  corgap=icorgap;  
}

uInt SiderealTimeSlots::getNumberOfSlots()  const throw(casa::String, casa::AipsError)
{     
   return uInt(floor((stop.getValue("rad")-start.getValue("rad")+
          corgap.getValue("rad")/sidsec)/(coravg.getValue("rad")+
	                              corgap.getValue("rad"))*sidsec));
}

// return the time difference between the two slots starting from index
casa::Quantity SiderealTimeSlots::getTimeStep(casa::uInt) const 
                             throw(casa::String, casa::AipsError)
{
  return (coravg+corgap)/sidsec;
}

// return a sidereal time of the given slot in radians
Double SiderealTimeSlots::getSidTime(casa::uInt index)
             const throw(casa::String, casa::AipsError)
{
   casa::Double sidtime=(start.getValue("rad")+
          (coravg.getValue("rad")+corgap.getValue("rad"))*index/sidsec+
                  0.5*coravg.getValue("rad")/sidsec);
   sidtime-=2.*M_PI*floor(sidtime/2./M_PI);
   return sidtime;
}

// return the UTC time of the given slot
MVEpoch SiderealTimeSlots::getUTCTime(casa::uInt index)
            const throw(casa::String, casa::AipsError)
{  
    MEpoch::Ref outref(MEpoch::UTC);
    MEpoch::Ref inref(MEpoch::GMST1);
    MEpoch::Convert utc2gmst(outref,inref); // to get a correct day number
    MEpoch::Convert gmst2utc(inref,outref);
    casa::MVEpoch daysidt=utc2gmst(MEpoch(utcday,MEpoch::Ref(MEpoch::UTC))).getValue();
    daysidt.adjust(); 
    casa::MVEpoch slotsidt(daysidt.getDay(),(start+
      (coravg+corgap)*Double(index)/sidsec+0.5*coravg/sidsec).getValue("d"));
    return gmst2utc(MEpoch(slotsidt,MEpoch::Ref(MEpoch::GMST1))).getValue();
}

//
///////////////////////////////////////////////////////////////////////////////
