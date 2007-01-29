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
//# $Id: DelayModel.h,v 1.1 2005/09/19 04:19:10 mvoronko Exp $


#ifndef __DELAYMODEL_H
#define __DELAYMODEL_H

// AIPS++ stuff
#include <casa/aips.h>
#include <casa/Exceptions/Error.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <casa/Quanta.h>
#include <casa/Quanta/MVPosition.h>
#include <casa/Quanta/MVDirection.h>
#include <measures/Measures/MEpoch.h>
#include <casa/BasicSL/Complex.h>
#include <casa/BasicSL/Constants.h>


class DelayModel {
   casa::Bool  doGravDelay;  // if true, a gravitational delay will be simulated
   casa::Bool  doOrbital;    // if true, the orbital motion of Earth is taken
                             // into account
   casa::Bool  doDiurnal;    // if true, the diurnal rotation of Earth is taken
                             // into account
   casa::MVPosition ant1;     // position of antenna 1 in ITRF
   casa::MVPosition ant2;     // position of antenna 2 in ITRF
   casa::MDirection phase_cntr; // direction to the phase centre
   casa::MVDirection src;     // direction to the source, the same frame as for phase_cntr
   casa::MEpoch time;        // time when calculation is required   
   mutable casa::MVPosition RE; // Earth position in the barycentric system (based on the frame
                                // used to specify phase_cntr)
   mutable casa::MVPosition EVorb; // Orbital velocity of Earth in the barycentric frame
                                   // velocity units are metres per second
   mutable casa::MVPosition baseline; // baseline ant2-ant1 in the barycentric frame (based on the frame
                                 // used to specify phase_cntr)
   mutable casa::MVPosition ant1phc; // position of antennae 1 and 2
   mutable casa::MVPosition ant2phc; // in the same frame, which was used to
				     // define the phase center
   mutable casa::MVDirection polaraxis; // direction to the North Pole in the
                                        // frame defined by phase_cntr
   // flags controlling caching
   mutable casa::Bool invalid_conversion;  // if true, either epoch of frame has been changed
   mutable casa::Bool invalid_ant1;     // antenna 1 has been changed
   mutable casa::Bool invalid_ant2;     // antenna 2 has been changed
   
   // constants
   static const casa::Double EVorbAbs = 30000; // The orbital velocity by
                                   // absolute value in metres per second
   static const casa::Double MeanAU = 1.5e11; // AU in metres
   static const casa::Double We = M_PI/43200.; // angular velocity of diurnal rotation (rad/s)
   static const casa::Double gammaGMsun_c3 = 9.9e-6; // (1+\gamma)GMsun/c^3, seconds
public:
   // setup the delay model
   // idoGravDelay  - if true, a gravitational delay will be simulated
   // idoOrbital    - if true, the orbital motion of Earth is simulated
   // idoDiurnal    - if true, the diurnal rotation of Earth is simulated
   //      default is to simulate all
   explicit DelayModel(const casa::Bool &idoGravDelay=true,
                       const casa::Bool &idoOrbital=true,
		       const casa::Bool &idoDiurnal=true) throw();
			 
   // setup the delay model from a string
   // Possible values of the string are
   // "all" simulate everything which this code can do (default)
   // "gravdelayonly" simulate gravitational delay only
   // "orbitalonly"   simulate the delay due to the orbital motion
   // "diurnalonly"   simulate the delay due to the diurnal motion
   // "orbitalanddiurnal"  simulate the delay due to the orbital and diurnal motions
   // Other string will cause an exception
   explicit DelayModel(const casa::String &mdl="all") throw(casa::AipsError);

   // set position for antenna 1
   void setAntenna1(const casa::MPosition &pos) throw(casa::AipsError);
   // set position for antenna 2
   void setAntenna2(const casa::MPosition &pos) throw(casa::AipsError);
   // set time when calculation is required
   void setTime(const casa::MEpoch &tm) throw(casa::AipsError);
   // set the phase centre direction
   void setPhaseCentre(const casa::MDirection &dir) throw(casa::AipsError);
   // set the source direction
   void setSourceDirection(const casa::MDirection &dir) throw(casa::AipsError);
   // return a residual delay for the current state of the object
   casa::Double getResidualDelay() const throw(casa::AipsError);

   // get model parameters
   casa::Bool getGravDelayStatus() const throw();
   casa::Bool getOrbitalDelayStatus() const throw();
   casa::Bool getDiurnalDelayStatus() const throw();
protected:
   // setup cache values use cache controlling flags to determine what to
   // recalculate
   void recalculateCache() const throw(casa::AipsError);
};

#endif // #ifndef __DELAYMODEL_H
