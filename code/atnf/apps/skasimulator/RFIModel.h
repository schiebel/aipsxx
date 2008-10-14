///////////////////////////////////////////////////////////////////////////////
//
//  RFIModel   class to simulate radio interference using simple
//             models
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
//# $Id: RFIModel.h,v 1.3 2005/09/19 04:19:10 mvoronko Exp $


#ifndef __RFIMODEL_HPP
#define __RFIMODEL_HPP

// AIPS++ stuff
#include <casa/aips.h>
#include <casa/Exceptions/Error.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <casa/Quanta.h>
#include <casa/Quanta/MVPosition.h>
#include <casa/BasicSL/Complex.h>


class RFIModel {
   casa::Quantity    flux;   // Flux density of the spherical wave at the specified
                       // position Rc (say at the core site)
           // following parameters are stored in the ITRF reference system
   casa::MVPosition   Rc;     // Reference position for the amplitude definition
   casa::MVPosition   Rr;     // Position of the interferer (a source of the spherical
                       // wave in this model)
   casa::MVPosition   Rrdot;  // Increment of the Rr in 1 second (velocity)   
public:
   // The interferer velocity (iRrdot) is set up as an increment in the
   // time unit defined by the timeunit parameter (1 second is default)
   RFIModel(const casa::Quantity &iflux, const casa::MPosition &iRc,
            const casa::MPosition &iRr, const casa::MPosition &iRrdot =
	    casa::MPosition(casa::Quantity(0.,"m"), casa::Quantity(0.,"m"),
		    casa::Quantity(0.,"m"), casa::MPosition::ITRF),
            const casa::Unit &timeunit = casa::Unit("s")) throw(casa::AipsError);

   // Move the interferer to a new location according to the time increment.
   // Basically this function recalculates the position using the formula
   // Rr+=Rrdot*dt, and recalculates the flux F to account for the source
   // being further of closer to the core. The latter means that the
   // interference emission has a flux F at the core Rc only at the first
   // correlator cycle. If fix_flux == true, there is no recalculation.
   void move(const casa::Quantity &dt, casa::Bool fix_flux = false)
             throw(casa::AipsError);

   // calculate the RFI component of visibility for baseline r1-r2
   // lambda - observed wavelength  (RFI is considered to be a broadband)
   // coravg - correlator averaging time
   // r1, r2 - positions of antennae
   // w - w-term in length units (zero if phase tracking is off)
   // dotasmear - if true, time average smearing will be simulated
   // wrate - rate of the w-term (normal velocity units)
   //         (zero if phase tracking is off)      
   casa::Complex getVisibility(const casa::Quantity &lambda, const casa::Quantity &coravg,
                         const casa::MPosition &r1, const casa::MPosition &r2,
			 const casa::Quantity &w, casa::Bool dotasmear,
			 const casa::Quantity &wrate)
			    const throw(casa::AipsError);
};

#endif // #ifndef __RFIMODEL_HPP
