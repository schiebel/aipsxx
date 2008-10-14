///////////////////////////////////////////////////////////////////////////////
//
//  DelayModel   class to simulate second order effects resulting in a residual
//               delay in the wide-field of view regime
//               The first order term (Bs/c) is always taken into account
//               by the main code of the simulator.
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
//# $Id: DelayModel.cc,v 1.2 2005/11/23 00:38:12 mvoronko Exp $

#include "DelayModel.h"
#include <measures/Measures/MeasConvert.h>
#include <measures/Measures/MeasFrame.h>
#include <casa/BasicMath/Math.h>

using namespace casa;

// for debugging
#include <fstream>
using namespace std;
//

// DelayModel

// setup the parameters of the delay model
// idoGravDelay  - if true, a gravitational delay will be simulated
// idoOrbital    - if true, the orbital motion of Earth is simulated
// idoDiurnal    - if true, the diurnal rotation of Earth is simulated
//      default is to simulate all
DelayModel::DelayModel(const casa::Bool &idoGravDelay,
                       const casa::Bool &idoOrbital,
     	               const casa::Bool &idoDiurnal) throw() :
     	         doGravDelay(idoGravDelay), doOrbital(idoOrbital),
     		 doDiurnal(idoDiurnal), phase_cntr(casa::Quantity(0.,"rad"),
		 casa::Quantity(0.,"rad"), casa::MDirection::J2000) {};

// setup the delay model from a string
// Possible values of the string are
// "all" simulate everything which this code can do (default)
// "gravdelayonly" simulate gravitational delay only
// "orbitalonly"   simulate the delay due to the orbital motion
// "diurnalonly"   simulate the delay due to the diurnal motion
// "orbitalanddiurnal"  simulate the delay due to the orbital and diurnal motions
// Other string will cause an exception
DelayModel::DelayModel(const casa::String &mdl) throw(casa::AipsError) :
              doGravDelay(true), doOrbital(true), doDiurnal(true),
	      phase_cntr(casa::Quantity(0.,"rad"), casa::Quantity(0.,"rad"),
	                 casa::MDirection::J2000)
                                             
{
  if (mdl=="all") return;
  else if (mdl=="gravdelayonly") doOrbital=doDiurnal=false;
  else if (mdl=="orbitalonly") doGravDelay=doDiurnal=false;
  else if (mdl=="diurnalonly") doGravDelay=doOrbital=false;
  else if (mdl=="orbitalanddiurnal") doGravDelay=false;
  else throw AipsError(mdl+" is unknown delay setup");  
}

// set position for antenna 1
void DelayModel::setAntenna1(const casa::MPosition &pos) throw(casa::AipsError)
{
  // convert to ITRF if necessary
  MPosition::Ref destframe(MPosition::ITRF);
  if (pos.getRef()!=destframe)
     ant1=MPosition::Convert(pos.getRef(),destframe)(pos).getValue();
  else  ant1=pos.getValue();
  invalid_ant1=true;
}

// set position for antenna 2
void DelayModel::setAntenna2(const casa::MPosition &pos) throw(casa::AipsError)
{
  // convert to ITRF if necessary
  MPosition::Ref destframe(MPosition::ITRF);
  if (pos.getRef()!=destframe)
     ant2=MPosition::Convert(pos.getRef(),destframe)(pos).getValue();
  else  ant2=pos.getValue();
  invalid_ant2=true;  
}

// set time when calculation is required
void DelayModel::setTime(const casa::MEpoch &tm) throw(casa::AipsError)
{
  time=tm;
  // time has been changed
  invalid_conversion=true;  
}

// setup cache values use cache controlling flags to determine what to
// recalculate
void DelayModel::recalculateCache() const throw(casa::AipsError)
{
  // setup some cached values (position of Sun, Earth's orbital velocity, etc)
  MDirection::Ref  destframe(phase_cntr.getRef());
  
  if (invalid_conversion) {
      MDirection sundir(MDirection::SUN);  
      MeasFrame frame(time);
      destframe.set(frame);
      if (sundir.getRef()!=phase_cntr.getRef())
          sundir=MDirection::Convert(sundir.getRef(),phase_cntr.getRef())(sundir);
      RE=MVPosition(sundir.getValue().get());
      RE*=-MeanAU;
      // convert the Sun's position into the Mean Ecliptic Reference frame
      // to get the direction of the Earth's orbital velocity vector
      MVDirection sun_mecl=MDirection::Convert(sundir.getRef(),
                     MDirection::Ref(MDirection::MECLIPTIC,frame))(sundir).getValue();
    
      // assume a circular orbit for now
      EVorb=MVPosition(MDirection::Convert(MDirection::Ref(MDirection::MECLIPTIC),
            destframe)(sun_mecl.crossProduct(MVDirection(0.,0.,1.))).getValue().get());
      EVorb*=EVorbAbs;

      // North pole direction in the required reference frame
      polaraxis=MDirection::Convert(MDirection::JTRUE,destframe)
                   (MVDirection(0.,0.,1.)).getValue();
      //cout<<polaraxis.getLong("deg").getValue()<<" "<<polaraxis.getLat("deg").getValue()<<endl;
  }

  if (invalid_conversion || invalid_ant1 || invalid_ant2) {
        
    // it is not quite clear why this conversion requires a position, but
    // the result doesn't seem to depend on this position as long as the
    // input position is a valid vector (e.g. not the Earth center)
    destframe.set(MeasFrame(time,MPosition(ant2,MPosition::ITRF)));

    if (invalid_ant2 || invalid_conversion) {
       // the 2nd antenna position in the same reference frame which was used
       // to define the phase center
       ant2phc=MVPosition(MDirection::Convert(MDirection::ITRF, destframe)(MVDirection(ant2)).getValue().get());
       ant2phc*=ant2.get()[0];
    }

    destframe.set(MeasFrame(time,MPosition(ant1,MPosition::ITRF)));

    if (invalid_ant1 || invalid_conversion) {
       // the 1st antenna position in the same reference frame which was used
       // to define the phase center
       ant1phc=MVPosition(MDirection::Convert(MDirection::ITRF, destframe)(MVDirection(ant1)).getValue().get());
       ant1phc*=ant1.get()[0];
    }
    
    baseline=ant2phc-ant1phc;        
  }
  invalid_conversion=false; invalid_ant1=false; invalid_ant2=false;  
}

// set the phase centre direction
void DelayModel::setPhaseCentre(const casa::MDirection &dir) throw(casa::AipsError)
{
  phase_cntr=dir;
  // reference frame may be different
  invalid_conversion=true;
}

// set the source direction, should be called after setPhaseCentre
void DelayModel::setSourceDirection(const casa::MDirection &dir) throw(casa::AipsError)
{
  // convert to the same reference frame as used for the phase centre
  if (dir.getRef()!=phase_cntr.getRef()) 
     src=MDirection::Convert(dir.getRef(),phase_cntr.getRef())(dir).getValue();
  else src=dir.getValue();
}

// return a residual delay for the current state of the object
casa::Double DelayModel::getResidualDelay() const throw(casa::AipsError)
{
 recalculateCache(); // update cache, if necessary
 
 Double res=0.;
 // phase center 
 MVPosition s0=MVPosition(phase_cntr.getValue().get());
// source offset from the phase center
 MVPosition ds=MVPosition(src.get())-s0;

 // antenna last receiving the wavefront
 const MVPosition &lastant=(baseline*s0<0)?ant2phc:ant1phc;

 // diurnal velocity of the second antenna
 MVPosition vel2;
 MVPosition totalVel(EVorb); // to be able to use either EVorb or EVorb+vel2
 if (!doOrbital)
     totalVel=MVPosition(0.,0.,0.);
 if (doDiurnal) {
     vel2=MVPosition(polaraxis.get()).crossProduct(lastant);
     vel2*=We; // polaraxis just determines a direction
     totalVel+=vel2; 
 }

 Double ksi=19.7e-9+square(EVorbAbs/C::c)/2.;
 Double eta=square(totalVel*s0/C::c)-totalVel*s0/C::c;
 if (doDiurnal && doOrbital)
    eta+=EVorb*vel2/square(C::c);

 Double zeta=(EVorb*baseline)*(EVorb*ds)/2./cube(C::c)+
       (s0*baseline)*(totalVel*ds)/square(C::c)*(1.-2.*totalVel*s0/C::c);
       
 res+=baseline*ds/C::c*(ksi-eta)+zeta;
 
 if (doGravDelay) {
     Double factor=1.;
     if (doDiurnal || doOrbital) 
         factor-=s0*totalVel/C::c;
     res-=gammaGMsun_c3*(baseline*ds)/(s0*RE+MeanAU)*factor;
 }
 
 return res;
}

// get model parameters
casa::Bool DelayModel::getGravDelayStatus() const throw()
{
  return doGravDelay;
}

casa::Bool DelayModel::getOrbitalDelayStatus() const throw()
{
  return doOrbital;
}

casa::Bool DelayModel::getDiurnalDelayStatus() const throw()
{
  return doDiurnal;
}


//
///////////////////////////////////////////////////////////////////////////////
