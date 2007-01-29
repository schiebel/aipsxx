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
//# $Id: RFIModel.cc,v 1.3 2005/09/19 04:19:10 mvoronko Exp $


#include "RFIModel.h"
#include <measures/Measures/MeasConvert.h>
#include <casa/BasicMath/Math.h>

#include <fstream>

using namespace casa;

double inline sinc(double x) {
   if (x==0) return 1;
   return sin(x)/x;
}


// RFIModel

// The interferer velocity (iRrdot) is set up as an increment in the
// time unit defined by the timeunit parameter (1 second is default)
// iflux - Flux density of the spherical wave at the specified
//         position Rc (say at the core site)
// iRc   - Reference position for the amplitude definition
// iRr   - Position of the interferer (a source of the spherical
//         wave in this model)
//
RFIModel::RFIModel(const casa::Quantity &iflux, const casa::MPosition &iRc,
         const casa::MPosition &iRr, const casa::MPosition &iRrdot,
         const casa::Unit &timeunit) throw(casa::AipsError) : flux(iflux),
	      Rc(iRc.getValue()), Rr(iRr.getValue()),
	      Rrdot(iRrdot.getValue())
{
  flux.convert("Jy"); // to use a simple getValue() later
  MPosition::Ref destsystem(MPosition::ITRF);
  Rc=MPosition::Convert(iRc.getRef(),destsystem)(Rc).getValue();
  Rr=MPosition::Convert(iRr.getRef(),destsystem)(Rr).getValue();
  Rrdot=MPosition::Convert(iRrdot.getRef(),destsystem)(Rrdot).getValue();
  
  // conversion factor for the interferer's velocity to have it as
  // some length unit (defined in MVPosition) per second
  casa::Double factor=1./Quantity(1.,timeunit).getValue("s");
  Rrdot*=factor;
}

// calculate the RFI component of visibility for baseline r1-r2
// lambda - observed wavelength  (RFI is considered to be a broadband)
// coravg - correlator averaging time
// r1, r2 - positions of antennae
// w - w-term in length units (zero if phase tracking is off)
// dotasmear - if true, time average smearing will be simulated
// wrate - rate of the w-term (normal velocity units)
//         (zero if phase tracking is off)
Complex RFIModel::getVisibility(const casa::Quantity &lambda,
                      const casa::Quantity &coravg,
                      const casa::MPosition &r1, const casa::MPosition &r2,
		      const casa::Quantity &w, casa::Bool dotasmear,
		      const casa::Quantity &wrate)
     		    const throw(casa::AipsError)
{
  MPosition::Ref destsystem(MPosition::ITRF);
  casa::MVPosition r1_itrf=MPosition::Convert(r1.getRef(),destsystem)(r1).getValue();
  casa::MVPosition r2_itrf=MPosition::Convert(r2.getRef(),destsystem)(r2).getValue();

  // MVPosition obtained from MPosition has all fields in metres  
  const casa::Double Rr_r1=(Rr-r1_itrf).radius(); // absolute value of |Rr-r1|
  const casa::Double Rr_r2=(Rr-r2_itrf).radius(); // absolute value of |Rr-r2|
  if (Rr_r1==0 || Rr_r2==0) return Complex(0.,0.);
  
  const casa::Double phasor=2*M_PI/lambda.getValue("m")*(Rr_r1-Rr_r2
                                             -w.getValue("m"));

  casa::Complex vis(cos(phasor),sin(phasor));
  
  vis*=flux.getValue()*square((Rr-Rc).radius())/(Rr_r1*Rr_r2);
  /*
  ofstream os("a.dat",ios::app);
  os<<wrate.getValue("m/s")/lambda.getValue("m")*coravg.getValue("s")<<" "<<
      1./lambda.getValue("m")*coravg.getValue("s")*
		      (((1./Rr_r1)*(Rr-r1_itrf)-
               	       (1./Rr_r2)*(Rr-r2_itrf))*Rrdot)<<endl;
  */
  if (dotasmear) 
      vis*=sinc(M_PI/lambda.getValue("m")*coravg.getValue("s")*
                (((1./Rr_r1)*(Rr-r1_itrf)-
		  (1./Rr_r2)*(Rr-r2_itrf))*Rrdot-
		 wrate.getValue("m/s")));
   
  return vis;
}

// Move the interferer to a new location according to the time increment.
// Basically this function recalculates the position using the formula
// Rr+=Rrdot*dt, and recalculates the flux F to account for the source
// being further of closer to the core. The latter means that the
// interference emission has a flux F at the core Rc only at the first
// correlator cycle. If fix_flux == true, there is no recalculation.
void RFIModel::move(const casa::Quantity &dt, casa::Bool fix_flux)
          throw(casa::AipsError)
{
  casa::MVPosition next_Rr=Rr+Rrdot*dt.getValue("s");
  if (!fix_flux) {
      if ((next_Rr-Rc).radius()==0)
	  throw AipsError("An interferer is at the core position!");
      flux*=square((Rr-Rc).radius()/(next_Rr-Rc).radius());
  }
  Rr=next_Rr;      
}

//
///////////////////////////////////////////////////////////////////////////////
