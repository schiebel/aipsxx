//# MSDerivedValues.cc: Calculate values derived from a MS
//# Copyright (C) 1996,1997,1999,2000
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
//# $Id: MSDerivedValues.cc,v 19.3 2004/11/30 17:50:35 ddebonis Exp $

#include <ms/MeasurementSets/MSDerivedValues.h>
#include <casa/Arrays/ArrayMath.h>
#include <ms/MeasurementSets/MSColumns.h>
#include <casa/Logging/LogMessage.h>
#include <casa/Logging/LogSink.h>
#include <casa/Utilities/Assert.h>
#include <casa/Exceptions/Error.h>

namespace casa { //# NAMESPACE CASA - BEGIN

MSDerivedValues::MSDerivedValues() 
{
  init();
}

MSDerivedValues::MSDerivedValues(const MSDerivedValues& other)
{
  operator=(other);
}

MSDerivedValues::~MSDerivedValues() {}

MSDerivedValues& 
MSDerivedValues::operator=(const MSDerivedValues& other) 
{
  antenna_p=other.antenna_p;
  // should copy all data here, for now, just init
  init();
  return *this;
}

Int MSDerivedValues::setAntennas(const ROMSAntennaColumns& ac)
{
  Int nAnt=ac.position().nrow();

  mAntPos_p.resize(nAnt);
  Vector<String> mount(nAnt);
  Vector<Double> avPos(3); avPos=0;
  for (Int ant=0; ant<nAnt; ant++) {
    mAntPos_p(ant) = ac.positionMeas()(ant);
    mount(ant) = ac.mount()(ant);
    avPos+=ac.position()(ant);
  }
  if (nAnt>0) {
    avPos/=Double(nAnt);
    mObsPos_p = mAntPos_p(0);
    mObsPos_p.set(MVPosition(avPos));
    setAntennaMount(mount);
    setAntenna(0);
  }
  return nAnt;
}

MSDerivedValues& MSDerivedValues::setAntennaPositions(const Vector<MPosition>&
						      antPosition)
{
  Int nAnt=antPosition.nelements();
  AlwaysAssert(nAnt>0,AipsError);
  mAntPos_p.resize(nAnt);
  mAntPos_p=antPosition;
  Vector<Double> avPos(3); avPos=0;
  for (Int i=0; i<nAnt; i++) {
    avPos+=mAntPos_p(i).getValue().get();
  }
  avPos/=Double(nAnt);
  mObsPos_p=mAntPos_p(0);
  mObsPos_p.set(MVPosition(avPos));
  setAntenna(0);
  return *this;
}

MSDerivedValues& MSDerivedValues::setObservatoryPosition(const MPosition&
							 obsPosition)
{
  mObsPos_p=obsPosition;
  setAntenna(-1);
  return *this;
}

MSDerivedValues& MSDerivedValues::setAntennaMount(const Vector<String>& mount)
{
  Int nAnt=mount.nelements();
  if (nAnt>0) {
    mount_p.resize(nAnt);
    for (Int i=0; i<nAnt; i++) {
      if (mount(i)=="alt-az" || mount(i)=="ALT-AZ" || mount(i)=="") 
	mount_p(i)=0;
      else if (mount(i)=="equatorial" || mount(i)=="EQUATORIAL") mount_p(i)=1;
      else if (mount(i)=="X-Y" || mount(i)=="x-y") mount_p(i)=2;
      else if (mount(i)=="orbiting" || mount(i)=="ORBITING") mount_p(i)=3;
      else if (mount(i)=="bizarre" || mount(i)=="BIZARRE") mount_p(i)=4;
      else throw(AipsError("MSDerivedValues::setAntennaMount() - "
			   "Unrecognized mount type"));
    }
  }
  return *this;
}
MSDerivedValues& MSDerivedValues::setEpoch(const MEpoch& time)
{
  cUTCToLAST_p.setModel(time);
  fAntFrame_p.resetEpoch(time);
  return *this;
}

MSDerivedValues& MSDerivedValues::setFieldCenter(const MDirection& fieldCenter)
{
  cRADecToAzEl_p.setModel(fieldCenter);
  cRADecToHADec_p.setModel(fieldCenter);
  fAntFrame_p.resetDirection(fieldCenter);
  mFieldCenter_p=fieldCenter;
  return *this;
}

MSDerivedValues& MSDerivedValues::setAntenna(Int antenna)
{
  DebugAssert(antenna>=-1,AipsError);
  DebugAssert(antenna<Int(mAntPos_p.nelements()),AipsError);
  // Reset the reference frame used in the conversion machines to be
  // for this antenna.
  if (antenna==-1) {
    fAntFrame_p.resetPosition(mObsPos_p);
  } else {
    fAntFrame_p.resetPosition(mAntPos_p(antenna));
  }
  antenna_p=max(0,antenna);
  return *this;
}

// compute parallactic angle.
Double MSDerivedValues::parAngle()
{
  DebugAssert(mAntPos_p.nelements()==mount_p.nelements(),AipsError);
  // Calculate Parallactic angle for this UT. To do this we find
  // the AzEl Directions of the phase center and of the (HA,Dec) pole
  // and then calculate the position angle between these two directions.
 
  // Do conversion. Can use the same conversion machine for
  // all antennas & times since we just change the Frame
  Double pa=0;

  if (mount_p(antenna_p)==0) {
    // Now we can do the conversions using the machines
    mRADecInAzEl_p     = cRADecToAzEl_p();
    mHADecPoleInAzEl_p = cHADecToAzEl_p();

    // Get the parallactic angle
    pa = mRADecInAzEl_p.getValue().
      positionAngle(mHADecPoleInAzEl_p.getValue());

    // pa_p(iant)+= receptorAngle_p(iant);
    //#if (iant==0) 
    //#  cout<<"Antenna "<<iant<<" at time: "<<MVTime(mEpoch.getValue())<<
    //#  " has PA = "<<pa_p(iant)*57.28<<endl;
    
  } else if (mount_p(antenna_p)==1) {
    // nothing to do for equatorial mounts, pa is always 0
  } else {
    LogMessage message(LogOrigin("MSDerivedValues","parAngle"));
    LogSink logSink;
    message.message("unhandled mount type");
    message.priority(LogMessage::SEVERE);
    logSink.post(message);
  }
  return pa;
}

MSDerivedValues& MSDerivedValues::setVelocityFrame(MRadialVelocity::Types vType)
{
  cTOPOToLSR_p.setOut(vType);
  return *this;
}

Double MSDerivedValues::hourAngle() 
{
  return cRADecToHADec_p().getValue().get()(0);
}

const MDirection& MSDerivedValues::azel()
{
  return cRADecToAzEl_p();
}

const MEpoch& MSDerivedValues::last()
{
  return cUTCToLAST_p();
}

const MRadialVelocity& MSDerivedValues::obsVel()
{
  return cTOPOToLSR_p();
}

void MSDerivedValues::init() 
{
  // Set up the frame for epoch and antenna position. We will
  // adjust this to effect the coordinate transformations
  fAntFrame_p.set(MEpoch(), MPosition(),MDirection());
  MDirection::Ref rHADec(MDirection::HADEC,fAntFrame_p);
  // Make the HADec pole as expressed in HADec. The pole is the default.
  MDirection mHADecPole;
  mHADecPole.set(rHADec);
  // Set up the machines to convert to AzEl, HADec and LAST 
  cRADecToAzEl_p.set(MDirection(), 
		     MDirection::Ref(MDirection::AZEL,fAntFrame_p));
  cHADecToAzEl_p.set(mHADecPole,MDirection::Ref(MDirection::AZEL,fAntFrame_p));
  cRADecToHADec_p.set(MDirection(),rHADec);
  cUTCToLAST_p.set(MEpoch(),MEpoch::Ref(MEpoch::LAST,fAntFrame_p));
  // set up the velocity conversion with zero velocity in the TOPO/antenna 
  // frame. We'll use this to compute the observatory velocity in another
  // frame (often LSR).
  cTOPOToLSR_p.set(MRadialVelocity(MVRadialVelocity(0.0),
				   MRadialVelocity::Ref(MRadialVelocity::TOPO,
							fAntFrame_p)),
		   MRadialVelocity::Ref(MRadialVelocity::LSRK));
}




} //# NAMESPACE CASA - END

