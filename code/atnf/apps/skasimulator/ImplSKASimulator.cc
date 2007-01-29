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
//# $Id: ImplSKASimulator.cc,v 1.5 2005/11/23 00:38:12 mvoronko Exp $


#include "ImplSKASimulator.h"
#include "MSWriter.h"

#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/BasicSL/String.h>
#include <casa/Logging/LogIO.h>
#include <casa/Logging/LogSink.h>
#include <casa/BasicSL/Complex.h>
#include <casa/BasicMath/Math.h>
#include <casa/Exceptions/Error.h>
#include <casa/OS/Path.h>
#include <casa/Containers/RecordInterface.h>
#include <casa/Containers/Record.h>

#include <components/ComponentModels/ComponentShape.h>
#include <components/ComponentModels/SpectralModel.h>
#include <components/ComponentModels/Flux.h>
#include <measures/Measures/MeasConvert.h>
#include <casa/Utilities/Assert.h>
#include <casa/Quanta/QuantumHolder.h>
#include <measures/Measures/ParAngleMachine.h>

using namespace casa;

// Some auxiliary functions


double inline sinc(double x) {
   if (x==0) return 1;
   return sin(x)/x;
}


// some constants
const double lightspeed=299792458.;  // in m/s
const double hrate=7.2921e-5; // hour angle rate in rad s^{-1}

// ImplSKASimulator

ImplSKASimulator::ImplSKASimulator() throw(casa::AipsError): is_layout_set(false),
                                       is_skymodel_set(false),
				       nchannels(1),
				       chbandw(Quantity(1.,"Hz")),
				       dotasmear(true),
				       dobandsmear(true),
				       avgtime(10.), dosky(true),
				       dorfi(false), donoise(false),
				       dovp(false),
				       rfimodel(NULL) {};

ImplSKASimulator::~ImplSKASimulator() throw()
{
  if (rfimodel != NULL)  delete rfimodel;
  if (noisemodel != NULL) delete noisemodel;
  if (delaymodel != NULL) delete delaymodel;
}

// set layout w.r.t. ITRF; all further calculations will be done
//                   for this layout
// x,y,z - global positions of each antenna
// Diam  - diameter of each antenna in metres
Bool ImplSKASimulator::setITRFLayout(const casa::Vector<casa::Double> &ix,
                                     const casa::Vector<casa::Double> &iy,
                                     const casa::Vector<casa::Double> &iz,
                                     const casa::Vector<casa::Double> &idiam) throw()
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("ImplSKASimulator","setITRFLayout",WHERE),logger);

  try {
     if (ix.nelements()!=iy.nelements() || ix.nelements()!=iz.nelements() ||
         ix.nelements()!=idiam.nelements() ||
	 iy.nelements()!=iz.nelements() ||
         iy.nelements()!=idiam.nelements() ||
         iz.nelements()!=idiam.nelements())  // fatal error
	    throw String("The layout description (X, Y, Z and diameter) should be given for all antennae (different sizes of arrays)");
     if (ix.nelements()<2) // fatal error
            throw String("At least two antennae should be specified");
     layout.resize(ix.nelements());
     diam.resize(idiam.nelements());
     for (casa::uInt i=0;i<ix.nelements();++i) {
          layout[i]=MPosition(MVPosition(ix[i],iy[i],iz[i]),MPosition::ITRF);
	  diam[i]=Quantity(idiam[i],"m");
     }     
     is_layout_set=true;
  }
  catch (const casa::String &str) {
      os<<LogIO::SEVERE<<str<<LogIO::POST;
      layout.resize(0);
      diam.resize(0);
      is_layout_set=false;
      return false;
  }
  catch (const casa::AipsError &ae) {
      os<<LogIO::SEVERE<<ae.getMesg()<<LogIO::POST;
      is_layout_set=false;
      return false;
  }

  return true;
}

// set sky model to simulate; all further calculations will be done for
// this sky model. Input parameter is a name of the external table
Bool ImplSKASimulator::setSkyModel(const casa::String &smname) throw()
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("ImplSKASimulator","setSkyModel",WHERE),logger);

  try {
      casa::ComponentList cl(smname,true);
      skymodel=cl.copy();
      is_skymodel_set=true; 
  }
  catch (const casa::AipsError &ae) {
      os<<LogIO::SEVERE<<ae.getMesg()<<LogIO::POST;
      is_skymodel_set=false;
      return false;
  }
  return true;
}

// return the unit vector pointed to the source (coord. sys is the same
// as for (X,Y,Z). The Hour angle (hangle) and declination (dec) are
// in radians
Vector<casa::Double> ImplSKASimulator::getSVector(casa::Double hangle,
                 casa::Double dec) const throw()
{
   casa::Vector<casa::Double> res(3,0.);
   res[0]=cos(dec)*cos(hangle);
   res[1]=-cos(dec)*sin(hangle);
   res[2]=sin(dec);
   return res;
}

// check whether the source is visible at a given antenna
Bool ImplSKASimulator::isVisible(const casa::Vector<casa::Double> &s,
          casa::uInt ant) const throw(casa::String)
{
   if (s.nelements()!=3) throw String("SVector should have 3 elements");
   const casa::Vector<casa::Double> &antpos=layout[ant].getValue().getValue(); // x,y,z in metres
   casa::Double norm=sqrt(square(antpos[0])+square(antpos[1])+square(antpos[2])); 
   casa::Double cosz=(antpos[0]*s[0]+antpos[1]*s[1]+antpos[2]*s[2])/norm;       
   return (acos(cosz)<M_PI/180.*80.);
}

// return a vector with uvw for the ij baseline
// hangle and dec  are hour angle and declination in radians, respectively
Vector<casa::Double> ImplSKASimulator::getUVW(casa::Double hangle, casa::Double dec, casa::uInt i,
                      casa::uInt j) const throw(casa::String)
{
   casa::Vector<casa::Double> uvw(3,0.);
   if (i>=layout.nelements() || j>=layout.nelements())
       throw String("Access to a non-existing antenna (too high number)");
   casa::MVPosition baseline(layout[j].getValue());
   baseline-=layout[i].getValue(); // lx,ly and lz   
   uvw[0]=baseline(0)*sin(hangle)+baseline(1)*cos(hangle);
   uvw[1]=-baseline(0)*cos(hangle)*sin(dec)+baseline(1)*sin(hangle)*sin(dec)+
           baseline(2)*cos(dec);
   uvw[2]=baseline(0)*cos(hangle)*cos(dec)-baseline(1)*sin(hangle)*cos(dec)+
          baseline(2)*sin(dec);
   //uvw[2]=0.; // no w-term
   return uvw;
}

// return a vector with time derivatives of uvw for the ij baseline
// hangle and dec are hour angle and declination in radians, respectively
Vector<casa::Double> ImplSKASimulator::getUVWRates(casa::Double hangle, casa::Double dec,
               casa::uInt i, casa::uInt j) const throw(casa::String)
{
   casa::Vector<casa::Double> ruvw(3,0.);
   if (i>=layout.nelements() || j>=layout.nelements())
       throw String("Access to a non-existing antenna (too high number)");
   casa::MVPosition baseline(layout[j].getValue());
   baseline-=layout[i].getValue(); // lx,ly and lz   
   // hrate is a rate of the hour angle in rad/s (it is different from
   // Earth's angular velocity, because it implies the siderial time).
   ruvw[0]=(baseline(0)*cos(hangle)-baseline(1)*sin(hangle))*hrate;
   ruvw[1]=(baseline(0)*sin(hangle)*sin(dec)+
            baseline(1)*cos(hangle)*sin(dec))*hrate;
   ruvw[2]=(-baseline(0)*sin(hangle)*cos(dec)-
             baseline(1)*cos(hangle)*cos(dec))*hrate;
   return ruvw;  
}

// calculate a pure visibility of the specified component without
// primary beam attenuation, RFI, calibration error or noise
// uvw - a vector of UVW (in metres),
// phasecntr - a direction to the phase centre
// freq - an observed frequency
// if dotasmear = true, timeaverage smearing is simulated using
//     uvwrate - a vector of time derivatives of UVW (in metres per second)
//     avgtime - average time in seconds
// if dobandsmear = true, bandwidth smearing is simulated using
//     chbandw - a bandwidth of this spectral channel
// if dovp = true, a voltage pattern will be simulated
//    using parangle1 and parangle2 - parallactic angles of the phase
//    centre at individual antennae
Complex ImplSKASimulator::getSCVisibility(const casa::SkyComponent &skycomp,
                     const casa::Vector<casa::Double> &uvw,
                     const casa::MDirection &phasecntr,
	             const casa::MVFrequency &freq,
		     const casa::Vector<casa::Double> &uvwrate,
		     casa::Double parangle1, casa::Double parangle2)
		     const throw(casa::AipsError, casa::String)
{
  casa::Double lambda=lightspeed/freq.getValue(); // wavelength in metres
  if (skycomp.shape().type()!=ComponentType::POINT)
      throw String("Point sources can be simulated only");
  if (skycomp.spectrum().type()!=ComponentType::CONSTANT_SPECTRUM)
      throw String("Constant spectrum sources can be simulated only");
      
  // we have to convert reference system of the sky component to that
  // used for phase centre
  const casa::MDirection &srcdir_ownref=skycomp.shape().refDirection();
  // srcdir -> direction in the same reference system as used for phase centre
  casa::MVDirection srcdir=MDirection::Convert(srcdir_ownref.getRef(),
                         phasecntr.getRef())(srcdir_ownref.getValue()).getValue();

  // exact formulae for l and m
  casa::Double l=sin(srcdir.getLong()-
          phasecntr.getValue().getLong())*cos(srcdir.getLat());
  casa::Double m=sin(srcdir.getLat())*cos(phasecntr.getValue().getLat())-
         cos(srcdir.getLat())*sin(phasecntr.getValue().getLat())*
	 cos(srcdir.getLong()-phasecntr.getValue().getLong());
  /*
  // approximate formulae for l and m
  casa::Double l=(srcdir.getLong()-
          phasecntr.getValue().getLong())*cos(phasecntr.getValue().getLat());
  casa::Double m=srcdir.getLat()-phasecntr.getValue().getLat(); 
  */ 
  /*
  // a test code to investigate the accuracy of CC 
    ccnoise.setDispersion(square(m));
    m=ccnoise();
  // end of the test code
  */
  casa::Double phasor=2*M_PI*(uvw[0]*l+uvw[1]*m+
             uvw[2]*(sqrt(1.-square(l)-square(m))-1.))/lambda;
  
  
  /*
  // experimental code to simulate retarded baseline effect on image
        // for test assume that all directions are specified in ITRF
     casa::Double diffdelay_pcntr=getGeometricDelay(cache_ant1, cache_ant2,
           casa::MDirection(phasecntr.getValue(),casa::MDirection::ITRF),
	   freq);
     casa::Double diffdelay_src=getGeometricDelay(cache_ant1, cache_ant2,
           casa::MDirection(srcdir,casa::MDirection::ITRF),freq);
         // additional phase due to an unaccounted delay
     phasor+=2*M_PI*freq.getValue()*(diffdelay_src-diffdelay_pcntr); 
  // end of the experimental code
  */
  
  // retarded baseline effect simulated using the DelayModel class
  if (dodelay && delaymodel) {
      delaymodel->setSourceDirection(casa::MDirection(srcdir,phasecntr.getRef()));
      phasor-=2*M_PI*freq.getValue()*delaymodel->getResidualDelay();      
  }
  // end of the retarded baseline code
  
  casa::Complex vis(cos(phasor),sin(phasor));

  // No polarization at this moment
  casa::Flux<casa::Double> flux=skycomp.flux();
  flux.convertPol(ComponentType::STOKES);
  flux.convertUnit("Jy");
  vis*=flux.value()[0]/sqrt(1.-square(l)-square(m));

  if (dotasmear)
      vis*=sinc(M_PI*(uvwrate[0]*l+uvwrate[1]*m+
                      uvwrate[2]*(sqrt(1.-square(l)-square(m))-1.))/lambda*avgtime);
  if (dobandsmear)
      vis*=sinc(phasor/2/freq.getValue()*chbandw.getValue("Hz"));

  if (dovp) {
     // temporarily work with a fixed model
     Double factor=sqrt(calcGauss(l,m,parangle1,lambda));
     factor*=sqrt(calcGauss(l,m,parangle2,lambda));
     vis*=factor;
  }
    
  return vis;
}

// an auxiliary function to calculate a value of 2-D gaussian
// (temporary)
casa::Double ImplSKASimulator::calcGauss(casa::Double l,
                    casa::Double m, casa::Double pa,
		    casa::Double lambda) throw()
{
   const Double dx=lambda/20;
   const Double dy=lambda/10;
   Double new_x=l*cos(pa)-m*sin(pa);
   Double new_y=l*sin(pa)+m*cos(pa);
   return exp(-0.5*square(new_x/dx)-0.5*square(new_y/dy));
}

// set times when the observations are done using siderial time
// at the Greenwich meridian (sidstart and sidstop)
// day - UT day to form the time correctly in the measurement set
//       (may be a dummy number)
Bool ImplSKASimulator::setSiderealTimes(const casa::Quantity &sidstart,
              const casa::Quantity &sidstop, const casa::MEpoch &day) throw()
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("ImplSKASimulator","setSiderealTimes",WHERE),logger);
  
  try {
     MEpoch::Ref outref(MEpoch::UTC);
     MEpoch::Convert conv(day.getRef(),outref);
     casa::MVEpoch utcday=day.getValue();
     if (day.getRef()!=outref)
         utcday=conv(day).getValue();
     timeslots.setSiderealTimes(sidstart,sidstop,utcday);
  }
  catch (const casa::String &str) {
      os<<LogIO::SEVERE<<str<<LogIO::POST;      
      return false;
  }
  catch (const casa::AipsError &ae) {
      os<<LogIO::SEVERE<<ae.getMesg()<<LogIO::POST;      
      return false;
  }
  return true;
}

// set times when the observations are done using fully specified
// MEpoch object (e.g. UTC time, or whatever is defined in AIPS++)   
Bool ImplSKASimulator::setTimes(const casa::MEpoch &start, const casa::MEpoch &stop)
                                throw()
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("ImplSKASimulator","setTimes",WHERE),logger);
  
  try {
     timeslots.setTimes(start,stop);
  }
  catch (const casa::String &str) {
      os<<LogIO::SEVERE<<str<<LogIO::POST;      
      return false;
  }
  catch (const casa::AipsError &ae) {
      os<<LogIO::SEVERE<<ae.getMesg()<<LogIO::POST;      
      return false;
  }
  return true;
}

// set correlator parameters
// coravg - averaging time
// corgap - gap between measurements
// inchannels - number of spectral channels
// ichbandw - channel bandwidth
Bool ImplSKASimulator::setCorParams(casa::Int inchannels,
          const casa::Quantity &ichbandw, const casa::Quantity &coravg,
          const casa::Quantity &corgap) throw()
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("ImplSKASimulator","setCorParams",WHERE),logger);
  if (inchannels<=0) {
      os<<LogIO::SEVERE<<"Number of channels should be positive"<<LogIO::POST;
      return false;
  }
  nchannels=inchannels;
  avgtime=coravg.getValue("s");
  
  try {
     chbandw=ichbandw;
     chbandw.convert("Hz"); // to have channel bandwidth in fixed units and
                            // to test that the parameter is in frequency units
     timeslots.setCorParams(coravg,corgap);
  }
  catch (const casa::AipsError &ae) {
      os<<LogIO::SEVERE<<ae.getMesg()<<LogIO::POST;      
      return false;
  }
  return true;
}

// simulate the experiment and store the data in the data set fname
// freq - observed frequency (1st channel)
// phasecntr - direction to the phase centre
// if dosky is true, visibilities due to sky model are simulated
// if dorfi is true, visibilities due to rfi model are simulated
// if donoise is true, noise is added
// if dovp is true, primary beam is simulated
Bool ImplSKASimulator::simulate(const casa::String &fname, const casa::Quantity &freq,
              const casa::MDirection &phasecntr) throw()
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("ImplSKASimulator","setCorParams",WHERE),logger);

  try {
    if (!timeslots.isTimeDefined() || !timeslots.isCorParamsDefined())
        throw String("Times and correlator parameters should be defined first");
    if (!is_layout_set)
        throw String("An array layout should be defined first");
    if (!is_skymodel_set && dosky)
        throw String("A sky model should be defined first");
    if (dorfi && rfimodel==NULL)
        throw String("An RFI model should be defined first");
    if (donoise && noisemodel==NULL)
        throw String("A noise model should be defined first");
    if (dodelay && delaymodel==NULL)
        throw String("A delay model should be defined first");
	
    os<<LogIO::NORMAL<<"Simulate "<<timeslots.getNumberOfSlots()<<" scans, "
      <<nchannels<<" spectral channel(s)"<<LogIO::POST;

    if (!donoise)
        os<<LogIO::NORMAL<<"No noise will be added to visibilities"<<LogIO::POST;

    // a code for the retarded baseline effect
    if (delaymodel && dodelay) 
       delaymodel->setPhaseCentre(phasecntr);


    casa::uInt numvis=0;
    casa::uInt numbadvis=0;
    { // to have the measurement set closed before the end of the function
       MSWriter mswrt(fname,phasecntr,freq,nchannels,chbandw);
       
       for (TimeSlots::const_iterator ci=timeslots.begin();
                              ci!=timeslots.end();++ci) {
	    // assuming that the phase centre is given in the current epoch,
	    // which is not true! To be precise it should be converted
	    // from its own reference system
            casa::Vector<casa::Double> svec=getSVector(ci->sidereal-
	                phasecntr.getValue().getLong(),
	                phasecntr.getValue().getLat());

            // it is easier to define the time required for to calculate
	    // the parallactic angle as the UTC time. Although sidereal
	    // time would be enough
	    MEpoch time(ci->utc,MEpoch::UTC);

	    // a code for the retarded baseline effect
	    if (delaymodel && dodelay) 
		delaymodel->setTime(time);
	    
	    
            for (casa::uInt i=0; i<layout.nelements();++i) {
	      // check whether the source is visible at antenna i
              if (!isVisible(svec,i)) {
	           numbadvis+=(layout.nelements()-i);
                   numvis+=(layout.nelements()-i);
	           continue;
	      }
  
	      for (casa::uInt j=i+1;j<layout.nelements();++j) {
	           // baseline ij at the current time slot (defined by ci)
                   numvis++;	  
		   if (!isVisible(svec,j)) {
		       numbadvis++;
		       continue;
		   }
		   casa::Vector<casa::Double> uvw=getUVW(ci->sidereal-
		                      phasecntr.getValue().getLong(),
				      phasecntr.getValue().getLat(),i,j);
		   
		   // checking shadowing
		   if (sqrt(square(uvw[0])+square(uvw[1]))<
		           (diam[i]+diam[j]).getValue("m")/2) {
		       numbadvis++;
		       continue;		   
		   }
		   /*
		   // temporary - without small baselines
		   if ((layout[i].getValue()-layout[j].getValue()).radius()<
		       100000) {
			 numbadvis++;
			 continue;
		   }
		   //
		   */

		   casa::Vector<casa::Double> uvwrate=getUVWRates(ci->sidereal-
		                      phasecntr.getValue().getLong(),
				      phasecntr.getValue().getLat(),i,j);

		   // a code for the retarded baseline effect
		   if (delaymodel && dodelay) {
		       delaymodel->setAntenna1(layout[i]);
		       delaymodel->setAntenna2(layout[j]);
		   }

		   // a special feature for experimental code -
		   // store baseline parameters in the internal cache
		   // to be able to use them where uvw's are not enough
		   // this code doesn't affect anything and can be left
		   // uncommented even for normal operations
		   setBaselineParameters(i,j);

		   // end of the experimental code

		   // parallactic angles
		   casa::Double  parangle1=getParAngle(time,i,phasecntr);
		   casa::Double  parangle2=getParAngle(time,j,phasecntr);

                   // one step is to write a matrix nPol x nChan
		   casa::Matrix<casa::Complex> visbuf(mswrt.getNCorr(),mswrt.getNChan());
		   DebugAssert(mswrt.getNCorr()==nchannels, casa::AipsError);
		   
		   // cycle on spectral channels
		   for (casa::uInt s=0;s<nchannels;++s) {
		        casa::Complex vis=0;
			MVFrequency skyfreq(freq);
			skyfreq+=(double(s)+0.5)*MVFrequency(chbandw);
			if (dosky)
			    vis+=getSkyVisibility(uvw,phasecntr,skyfreq,
			              uvwrate,parangle1,parangle2);
			
			if (dorfi)
			    vis+=rfimodel->getVisibility(Quantity(lightspeed/skyfreq.getValue(),"m"),
			                   Quantity(avgtime,"s"),layout[i],
					   layout[j],uvw[2],dotasmear,uvwrate[2]);
                        if (donoise)
			    vis+=Complex((*noisemodel)(),(*noisemodel)());
			    
			// no polarizations now, simply store a copy of a single visibility
			for (casa::uInt p=0;p<mswrt.getNCorr();++p)
			     visbuf(p,s)=vis;                       
		   }
		   // write visibility
		   mswrt.writevis(uvw,i,j,ci->utc,visbuf);
	      } // cycle on j
	    } // cycle on i
	    // move the interferer to the next position
	    if (dorfi)
	        rfimodel->move(timeslots.getTimeStep(),true);
       } // cycle over time slots
       
       if (numvis==numbadvis)
           throw String("No visibilities to simulate");
	   
       os<<LogIO::NORMAL<<"Simulations have been completed. Write the antenna table. "<<LogIO::POST;
       mswrt.writeANtable(layout,diam);
    } // to close measurement set
  }

  catch (const casa::String &str) {
      os<<LogIO::SEVERE<<str<<LogIO::POST;      
      return false;
  }
  catch (const casa::AipsError &ae) {
      os<<LogIO::SEVERE<<ae.getMesg()<<LogIO::POST;      
      return false;
  }
  
  return true;
}

// return the parallatic angle in radians for a given time, antenna
// and phase centre. The siderial time is specified in radians
casa::Double ImplSKASimulator::getParAngle(const casa::MEpoch &time,
                         casa::uInt ant, const casa::MDirection &phasecntr)
			      const throw(casa::String, casa::AipsError)
{
  ParAngleMachine pam(phasecntr);
  MeasFrame frame(time,layout[ant]);
  pam.set(frame);
  return pam(time).getValue("rad");
}

// calculate a sky visibility (no RFI, error or noise) using a preset
// sky brightness model
Complex ImplSKASimulator::getSkyVisibility(const casa::Vector<casa::Double> &uvw,
                            const casa::MDirection &phasecntr,
		            const casa::MVFrequency &freq,
			    const casa::Vector<casa::Double> &uvwrate,
			    casa::Double parangle1, casa::Double parangle2)
			        const throw(casa::AipsError, casa::String)
{
  casa::Complex vis;
  // No primary beams so far
  for (casa::uInt i=0;i<skymodel.nelements();++i)
	/*  // the next row only is for tests
	  if (!i) vis+=casa::Complex(1,0); else */
       vis+=getSCVisibility(skymodel.component(i),uvw,phasecntr,freq,uvwrate,
                            parangle1, parangle2);
  return vis;
}

// Control of various options: set what is to be simulated
// idosky - if true, simulate sky
// idobandsmear - if true, simulate bandwidth smearing
// idotasmear - if true, simulate time average smearing
// idorfi     - if true, simulate rfi
// idonoise   - if true, simulate noise
// idovp      - if true, simulate voltage pattern (primary beam)
// idodelay   - if true, simulate residual delays
Bool ImplSKASimulator::setOptions(casa::Bool idosky, casa::Bool idobandsmear, casa::Bool idotasmear,
                         casa::Bool idorfi, casa::Bool idonoise,
			 casa::Bool idovp, casa::Bool idodelay) throw()
{
 dosky=idosky;
 dobandsmear=idobandsmear;
 dotasmear=idotasmear;
 dorfi=idorfi;
 donoise=idonoise;
 dovp=idovp;
 dodelay=idodelay;
 return true;
}

// set RFI model - a single moving source of a spherical wave (broadband)
// flux - rfi flux density at the reference position Rc (e.g. core)
// Rr    - position of the interferor
// Rrdot - velocity (a vector quantity) of the interferor specified as
//         an increment of Rr per the unit of time (defined below)
// timeunit - unit of time (e.g. second)
// return false, if something is wrong
Bool ImplSKASimulator::setRFIModel(const casa::Quantity &flux, const casa::MPosition &Rc,
                              const casa::MPosition &Rr, const casa::MPosition &Rrdot,
	                      const casa::Unit &timeunit) throw()
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("ImplSKASimulator","setRFIModel",WHERE),logger);

  try {
       if (rfimodel!=NULL) delete rfimodel;
       rfimodel=new RFIModel(flux,Rc,Rr,Rrdot,timeunit);       
  }
  catch (const casa::AipsError &ae) {
      os<<LogIO::SEVERE<<ae.getMesg()<<LogIO::POST;      
      return false;
  }
  catch (const std::bad_alloc &ba) {
      os<<LogIO::SEVERE<<"Unable to allocate memory"<<LogIO::POST;
      return false;
  }
  return true;
}

// set delay model, effects taken into account are described by the input
// string. Possible values are
// "all" simulate everything which this code can do (default)
// "gravdelayonly" simulate gravitational delay only
// "orbitalonly"   simulate the delay due to the orbital motion
// "diurnalonly"   simulate the delay due to the diurnal motion
// "orbitalanddiurnal"  simulate the delay due to the orbital and diurnal motions   
// return false, if something is wrong (e.g. the string is unrecognized)
casa::Bool ImplSKASimulator::setDelayModel(const casa::String &in) throw()
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("ImplSKASimulator","setDelayModel",WHERE),logger);

  try {
       if (delaymodel!=NULL) delete delaymodel;
       delaymodel=new DelayModel(in);       
  }
  catch (const casa::AipsError &ae) {
      os<<LogIO::SEVERE<<ae.getMesg()<<LogIO::POST;      
      return false;
  }
  catch (const std::bad_alloc &ba) {
      os<<LogIO::SEVERE<<"Unable to allocate memory"<<LogIO::POST;
      return false;
  }
  return true;
}



// set additive gaussian noise as a noise model
// variance - sqrt(dispersion). If mean=0 (default), it is equal to rms
// mean - expectation of the value   
Bool ImplSKASimulator::setAddGaussianNoise(const casa::Quantity &variance,
                     const casa::Quantity &mean) throw()
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("ImplSKASimulator","setAddGaussianNoise",WHERE),logger);

  try {
       if (noisemodel != NULL) delete noisemodel;
       noisemodel=new GaussianGenerator(mean.getValue("Jy"),
                      square(variance.getValue("Jy")));
  }
  catch (const casa::AipsError &ae) {
      os<<LogIO::SEVERE<<ae.getMesg()<<LogIO::POST;      
      return false;
  }
  catch (const std::bad_alloc &ba) {
      os<<LogIO::SEVERE<<"Unable to allocate memory"<<LogIO::POST;
      return false;
  }
  return true;
}

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
//    dovp        - T if a voltage pattern has to be simulated
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
Bool ImplSKASimulator::getStatus(casa::RecordInterface &rec,
                            casa::Bool beQuiet) const throw()
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("ImplSKASimulator","getStatus",WHERE),logger);

  try {
     if (!beQuiet) {
         // output to the logger
         if (is_layout_set)
             os<<LogIO::NORMAL<<"Antenna layout is set ("<<layout.nelements()
	       <<" stations)"<<LogIO::POST;
	 else os<<LogIO::NORMAL<<"Antenna layout is not set"<<LogIO::POST;

	 os<<LogIO::NORMAL<<"Time average smearing: ";
	 if (dotasmear)  os<<"simulate"<<LogIO::POST;
	     else os<<"DO NOT simulate"<<LogIO::POST;

         os<<LogIO::NORMAL<<"Correlator averaging time is "<<avgtime
	   <<"s"<<LogIO::POST;

         os<<LogIO::NORMAL<<"Bandwidth smearing: ";
	 if (dobandsmear)  os<<"simulate"<<LogIO::POST;
	     else os<<"DO NOT simulate"<<LogIO::POST;

	 os<<LogIO::NORMAL<<"Channel bandwidth is "<<chbandw.getValue("Hz")<<
	                    " Hz"<<LogIO::POST;

	 os<<LogIO::NORMAL<<"Number of channels is "<<nchannels<<LogIO::POST;

	 os<<LogIO::NORMAL<<"Sky model visibilities: ";
	 if (dosky) {
	     os<<"simulate;"; 
	     // mode specific fields
	     if (is_skymodel_set) os<<"sky model is set ("
	         <<skymodel.nelements()<<" sources)"<<LogIO::POST;
	     else os<<"Sky model is not set"<<LogIO::POST;
	     os<<"Voltage pattern ";
	     if (dovp) os<<"will be simulated"<<LogIO::POST;
	     else os<<"will not be simulated"<<LogIO::POST;
	 } else os<<"DO NOT simulate"<<LogIO::POST;         
	     
	 os<<LogIO::NORMAL<<"RFI: ";
         if (dorfi) {
	     os<<"simulate; ";
	     if (rfimodel) os<<"RFI model is set"<<LogIO::POST;
	     else os<<"RFI model is not set"<<LogIO::POST;
	 } else os<<"DO NOT simulate"<<LogIO::POST;         
	     
         os<<LogIO::NORMAL<<"Noise: ";
         if (donoise) {
	     os<<"simulate; ";
	     if (noisemodel) os<<"Noise model is set"<<LogIO::POST;
	     else os<<"RFI model is not set"<<LogIO::POST;
	 } else os<<"DO NOT simulate"<<LogIO::POST;

	 os<<LogIO::NORMAL<<"Residual delay (retarded baseline): ";
	 if (dodelay) {
	     os<<"simulate; ";
	     if (delaymodel) {
	        os<<" delay model (";
	        casa::String dmstatus;
		if (delaymodel->getGravDelayStatus())
		    dmstatus+="grav. delay";
		if (delaymodel->getOrbitalDelayStatus()) {
		    if (dmstatus!="") dmstatus+=", ";
		    dmstatus+="orbital motion";
		}
		if (delaymodel->getDiurnalDelayStatus()) {
		    if (dmstatus!="") dmstatus+=", ";
		    dmstatus+="diurnal rotation";
		}
		if (dmstatus=="") dmstatus="probably invalid";
		os<<dmstatus<<") is set"<<LogIO::POST;
		
	     } else os<<"delay model is not set"<<LogIO::POST;
	 } else os<<"DO NOT simulate"<<LogIO::POST;
     }

     // add required fields to the record
     rec.define("layoutset",is_layout_set);
     rec.define("dotasmear",dotasmear);
     rec.define("dobandsmear",dobandsmear);
     rec.define("nchannels",nchannels);
     {
       casa::QuantumHolder qh(chbandw);
       casa::Record chbandwrec;
       casa::String error;
       if (!qh.toRecord(error, chbandwrec))
           throw AipsError(String("getStatus: unable to convert Channel "
	                   "Bandwidth to a record - ")+error);
       rec.defineRecord("chbandw",chbandwrec);
     }
     {
       casa::QuantumHolder qh(Quantity(avgtime,"s"));
       casa::Record avgtimerec;
       casa::String error;
       if (!qh.toRecord(error, avgtimerec))
           throw AipsError(String("getStatus: unable to convert Averaging "
	                   "Time to a record - ")+error);
       rec.defineRecord("avgtime",avgtimerec);
     }
     rec.define("dosky",dosky);
     if (dosky) { // mode specific fields
         rec.define("skymodelset",is_skymodel_set);
	 rec.define("nsources",skymodel.nelements());
	 rec.define("dovp",dovp);
     }
     rec.define("dorfi",dorfi);
     if (dorfi) // a mode specific field
         rec.define("rfimodelset",rfimodel!=NULL);
     rec.define("donoise",donoise);
     if (donoise) // a mode specific field
         rec.define("donoise",noisemodel!=NULL);
     rec.define("dodelay",dodelay);
     if (dodelay) { // mode specific fields
         rec.define("delaymodelset",delaymodel!=NULL);
	 if (delaymodel) {
	     rec.define("gravdelay",delaymodel->getGravDelayStatus());
	     rec.define("orbitaldelay",delaymodel->getOrbitalDelayStatus());
	     rec.define("diurnaldelay",delaymodel->getDiurnalDelayStatus());
         }
     }
  }
  catch (const casa::AipsError &ae) {
      os<<LogIO::SEVERE<<ae.getMesg()<<LogIO::POST;      
      return False;
  }
  return True;
}

// calculate a geometric delay for a given pair of antennae (baseline ij)
// This function is used only in the experimental code and doesn't affect
// the main functionality of the simulator; linear term is removed!
casa::Double ImplSKASimulator::getGeometricDelay(casa::uInt i, casa::uInt j,
         const casa::MDirection &dir, const casa::MVFrequency &freq)
               const throw(casa::AipsError)
{
   if (i>=layout.nelements() || j>=layout.nelements())
       throw AipsError("Access to a non-existing antenna (too high number)");
   // station positions are in the ITRF frame -> velocities in this frame as
   // well; speed units are metres per seconds
   MVPosition vel_i(-layout[i].getValue()(1)*hrate,
                     layout[i].getValue()(0)*hrate, 0.);
   MVPosition vel_j(-layout[j].getValue()(1)*hrate,
                     layout[j].getValue()(0)*hrate, 0.);

   // we should convert source position into ITRF
   MDirection::Ref destframe(MDirection::ITRF);
   MVDirection srcdir=MDirection::Convert(dir.getRef(),
                           destframe)(dir).getValue();
   // the vector pointing to the source in the terrestrial frame
   MVPosition src(Quantity(1.,"m"),srcdir.get()[0],srcdir.get()[1]);

   // linear term is subtracted!
   return src*(layout[j].getValue()-layout[i].getValue())/lightspeed*(/*1./(1.-
           */src*vel_j/lightspeed/*)*/);
}

// tests with geometric delays (baseline ij)
casa::Bool ImplSKASimulator::simResidualDelays(casa::Vector<Double> &delays,
                             const casa::Vector<Double> &offsetsx,
			     const casa::Vector<Double> &offsetsy,
                             casa::uInt i, casa::uInt j,
			     const casa::MDirection &phasecentre,
			     const casa::MFrequency &freq) const throw()
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("ImplSKASimulator","simResidualDelays",WHERE),logger);

  try {
     if (!is_layout_set) throw AipsError("An array layout should be assigned first");
     if (offsetsx.nelements()!=offsetsy.nelements())
         throw AipsError("Arrays with offsets in two coordinates should have the same size");
	 
     MVFrequency freqbuf=freq.getValue(); // temporary: no conversion
     delays.resize(offsetsx.nelements());
     Double pcnt_delay=getGeometricDelay(i,j,phasecentre,freqbuf);
     for (uInt k=0;k<offsetsx.nelements();++k) {
          MDirection testdir(phasecentre);
	  testdir.shiftLongitude(Quantity(offsetsx[k],"rad"),False);
	  testdir.shiftLatitude(Quantity(offsetsy[k],"rad"),False);
	  delays[k]=getGeometricDelay(i,j,testdir,freqbuf)-pcnt_delay;
     }
  }
  catch (const casa::AipsError &ae) {
      os<<LogIO::SEVERE<<ae.getMesg()<<LogIO::POST;
      return false;
  }

  return true;

}

// for experiments only, not used in normal simulations.
// store information about the current baseline to be able to use
// it in those parts of the code, where uvw's are not sufficient
void ImplSKASimulator::setBaselineParameters(casa::uInt i, casa::uInt j)
                       const throw()
{
  cache_ant1=i;
  cache_ant2=j;
}
