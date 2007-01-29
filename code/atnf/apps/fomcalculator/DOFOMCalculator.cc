// DOFOMCalculator distributed object to calculate Figures Of Merit for
// a given antenna layout
//
//# Copyright (C) 1999-2005
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
//# $Id: DOFOMCalculator.cc,v 1.3 2005/08/12 03:26:04 mvoronko Exp $


#include "DOFOMCalculator.h"

#include <casa/Arrays/Vector.h>
#include <casa/Arrays/MaskedArray.h>
#include <casa/Arrays/Matrix.h>
#include <casa/BasicSL/String.h>
#include <casa/Logging/LogIO.h>
#include <casa/Logging/LogSink.h>
#include <casa/BasicSL/Complex.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <casa/Utilities/GenSort.h>
#include <casa/Exceptions/Error.h>

#include "PairOrderedFirst.cc"
using namespace casa;

//#include <fstream>

Double inline sqr(casa::Double x) {return x*x;}


// HistogramCalculator - a supplementary class which returns the index
//                       (box number) given a value of the function
class HistogramCalculator {
  casa::Double maxval;
  casa::Double minval;
  casa::uInt nboxes; // number of boxes
  casa::Bool dologscale; // the scale is logarithmic
public:
  HistogramCalculator(casa::Double imaxval, casa::uInt inboxes, casa::Bool idologscale=false,
                      casa::Double iminval=0.) : maxval(imaxval), minval(iminval),
		      nboxes(inboxes), dologscale(idologscale)
		      {
		        if (maxval<=minval) throw String("maximum should be greater than minimum, can't bin the data");
		      }
  casa::uInt operator()(casa::Double val) const;
  casa::Double getValue(casa::uInt box) const;
};

uInt HistogramCalculator::operator()(casa::Double val) const
{
  if (nboxes<=1) return 0;
  if (val<=minval) return 0;
  if (val>=maxval) return nboxes-1;
  if (dologscale) {
      const casa::Double r=(log(val-minval)/log(maxval-minval))*nboxes;
      if (r<0) return 0;
      casa::uInt res=uInt(floor(r));
      if (res>=nboxes) return nboxes-1;
      else return res;
  } 

  const casa::Double r=((val-minval)/(maxval-minval))*Double(nboxes);
  if (r<0) return 0; // just in case,...
  casa::uInt res=uInt(floor(r));
  if (res>=nboxes) return nboxes-1;
  else return res;  
}

Double HistogramCalculator::getValue(casa::uInt box) const
{
  if (dologscale) 
      return minval+exp((Double(box)+0.5)/Double(nboxes)*log(maxval-minval));
  return minval+(Double(box)+0.5)/Double(nboxes)*(maxval-minval);
}


// FOMCalculator

FOMCalculator::FOMCalculator() : isdone_sizestat(false){};

// set layout; all further calculations will be done for this layout
// x,y,z - global positions of each antenna
// Diam  - diameter of each antenna
void FOMCalculator::setLayout(const casa::Vector<casa::Double> &ix,
                              const casa::Vector<casa::Double> &iy,
                              const casa::Vector<casa::Double> &iz,
                              const casa::Vector<casa::Double> &idiam) 
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("FOMCalculator","setLayout",WHERE),logger);

  try {
     if (ix.nelements()!=iy.nelements() || ix.nelements()!=iz.nelements() ||
         ix.nelements()!=idiam.nelements() ||
	 iy.nelements()!=iz.nelements() ||
         iy.nelements()!=idiam.nelements() ||
         iz.nelements()!=idiam.nelements())  // fatal error
	    throw String("The layout description (X, Y, Z and diameter) should be given for all antennae (different sizes of arrays)");
     if (ix.nelements()<2) // fatal error
            throw String("At least two antennae should be specified");
     x.resize(); y.resize(); z.resize(); diam.resize();	    
     x=ix; y=iy; z=iz; diam=idiam;
     isdone_sizestat=false;
  }
  catch (const casa::String &str) {
      os<<LogIO::SEVERE<<str<<LogIO::POST;
      x.resize(0);
      y.resize(0);
      z.resize(0);
      diam.resize(0);
      return;
  }
  
}

// obligatory methods
String FOMCalculator::className() const
{
  return "FOMCalculator";
}

Vector<casa::String> FOMCalculator::methods() const
{
  casa::Vector<casa::String> method(3);
  casa::Int i=0;
  method(i++)="setlayout";
  method(i++)="getuvstats";
  method(i++)="getsizestats";
  return method;
}

// to avoid logging simple functions
Vector<casa::String>  FOMCalculator::noTraceMethods() const
{
  casa::Vector<casa::String> method(2);
  casa::Int i=0;
  method(i++)="setlayout";
  method(i++)="getsizestats";
  return method;
}


void FOMCalculator::calcSizeStatistics() const throw(casa::String)
{
   if (isdone_sizestat) return; // cache value is still valid
   if (x.nelements()<2) throw String("Array should have at least 2 antennae");

   rabaseline=0.; // mean of baseline length reciprocals will be
                  // accumulated here
   bool dora=true; // do rabaseline calculations (no zero length
                                               // baselines so far)
   bool first=true;   
   for (casa::uInt i=0;i<x.nelements();++i)
        for (casa::uInt j=0;j<i;++j) {
	     casa::Double length=sqrt(sqr(x[i]-x[j])+sqr(y[i]-y[j])+sqr(z[i]-z[j]));

	     casa::Double ns=fabs(z[i]-z[j]);
	     casa::Double ew=sqrt(sqr(x[i]-x[j])+sqr(y[i]-y[j]));

	     if (dora)
	         if (length>1e-13)
	             rabaseline+=1./length;
		 else {
		     rabaseline=0.;
		     dora=false;
		 }
	     if (first || maxbaseline<length) maxbaseline=length;
	     if (first || maxnsbaseline<ns) maxnsbaseline=ns;
	     if (first || maxewbaseline<ew) maxewbaseline=ew;
	     first=false;
	}
   if (rabaseline!=0. && dora)
       rabaseline=(Double(x.nelements())*Double(x.nelements()-1)/2.)/rabaseline;
       
   // Area statistics
   casa::Vector<PairOrderedFirst<casa::Double,uInt> > antennae_dist(x.nelements());
   
   for (casa::uInt i=0;i<x.nelements();++i) {
        // distance from the reference position
        antennae_dist[i].first=sqrt(sqr(x[i]-getReferenceX())+
	          sqr(y[i]-getReferenceY())+sqr(z[i]-getReferenceZ()));
        antennae_dist[i].second=i; // array index to understand which
	                           // antenna is where
   }
   casa::GenSort<PairOrderedFirst<casa::Double,uInt> >::sort(antennae_dist);
   // calculate actual statistics
    area.resize(antennae_dist.nelements());
    distance.resize(antennae_dist.nelements());
    casa::Double curArea=0.;
    casa::Bool needfill5km=true, needfill25km=true, needfill150km=true;
    for (casa::uInt i=0;i<antennae_dist.nelements();++i) {
         curArea+=M_PI*sqr(diam[antennae_dist[i].second])/4.; // area of this antenna
	 area[i]=curArea;
	 distance[i]=antennae_dist[i].first;
	 if (needfill5km && antennae_dist[i].first>5e3) {
	     areain5km=curArea;
	     needfill5km=false;
	 }
	 if (needfill25km && antennae_dist[i].first>25e3) {
	     areain25km=curArea;
	     needfill25km=false;
	 }
	 if (needfill150km && antennae_dist[i].first>15e4) {
	     areain150km=curArea;
	     needfill150km=false;
	 }
    }
    totalarea=curArea;
    if (needfill5km) areain5km=curArea;
    if (needfill25km) areain25km=curArea;
    if (needfill150km) areain150km=curArea;
    
    if (totalarea==0) throw String("Array happends to have zero total area");
    for (casa::uInt i=0;i<antennae_dist.nelements();++i) 
         area[i]/=totalarea;     
    areain5km/=totalarea;
    areain25km/=totalarea;
    areain150km/=totalarea;
   //
   isdone_sizestat=true;
}

// uv-plane fill statistics
//    Input:
// nradbox - number of radial bins 
// nangbox - number of angular bins
// dologscale - if true, logarithm of uv-distance is binned
// domfs - if true, fracband is a fractional bandwith (0..1) of the
//         experiment; multifrequency synthesis with infinite
//          number of channels is assumed
// dosnapshot - if true, just one visibility per baseline is generated
//              otherwise observations lasts duration hours with
//              infinitesimal integration time      
// fracband - fractional bandwidth (df/f)
// duration - duration of observations (hours)
// declination - source declination (degrees)      
//
// Output: Modified mutable fields
// uvsamples - an array with binned uvcoverage (0..nradbox-1,0..nangbox-1)
// uvcoords  - an array with the same length containing u and v (as a complex
//             quantity)
// uv-statistics 
void FOMCalculator::getUVStats(casa::uInt nradbox, casa::uInt nangbox, casa::Bool dologscale,
                casa::Bool domfs, casa::Bool dosnapshot, casa::Double fracband,
  	        casa::Double duration, casa::Double declination) const throw(casa::String)
{
  casa::LogSink logger;
  casa::LogIO os(LogOrigin("FOMCalculator","getUVStats",WHERE),logger);

  // size statistics
  calcSizeStatistics();
  if (nradbox<1) throw String("At least 1 radial box is necessary");
  if (nangbox<1) throw String("At least 1 angular box is necessary");

  // allocate arrays
  uvsamples.resize(nradbox,nangbox);
  uvcoords.resize(nradbox,nangbox);
  
  // start accumulating from the empty uv-coverage
  for (casa::uInt i=0;i<nradbox;++i)
       for (casa::uInt j=0;j<nangbox;++j)
            uvsamples(i,j)=0;

  // to speed the program up
  const casa::Double dec=M_PI/180.*declination; // declination in radians
  const casa::Double sindec=sin(dec);
  const casa::Double cosdec=cos(dec);

  os<<LogIO::NORMAL<<"Source at "<<declination<<" degrees of declination will be simulated"<<LogIO::POST;
  os<<LogIO::NORMAL<<"Duration of observations: ";
  if (dosnapshot) os<<"snap-shot"<<LogIO::POST;
  else os<<duration<<" hours"<<LogIO::POST;
  os<<"Multifrequency synthesis mode is ";
  if (domfs) os<<"on, fractional bandwidth is "<<fracband<<LogIO::POST;
  else os<<"off"<<LogIO::POST;
  
  // limits for hour angle to iterate
  const casa::Double Hmax=(dosnapshot?0:duration/2); // source should be in transit
                                               // in the middle of observations
  // increment for hour angle
  const casa::Double Hstep=(dosnapshot?1:3.0/Double(nangbox));
  
  // it is useless to consider  baselines lower than the miminal diameter
  // as they always be shadowed
  casa::Double mindiam=diam[0]; // we have at least two antennae!
  for (casa::uInt i=0;i<diam.nelements();++i)
       if (mindiam>diam[i]) mindiam=diam[i];  

  // maximum uv-distance for histogram is scaled with fracband to accommodate
  // maximum possible uv-distance in the case of mfs
  HistogramCalculator radhist((domfs?(1.+fracband/2.)*maxbaseline:maxbaseline),
                              nradbox,dologscale,mindiam);
  HistogramCalculator anghist(M_PI,nangbox,false);

  // number of "visibilities" & without rejection
  casa::uInt numvis=0;
  casa::uInt numvistot=0;

  // we want the source in transit at the first antenna of array
  // a longitude should be subtracted to get the hour angle at the Greenwich
  // meridian
  const casa::Double ant1long=getReferenceLongitude(); // longitude in radians

  //std::ofstream tos("tstuv.dat");
    
  for (casa::Double Hcur=(dosnapshot?Hmax:-Hmax); Hcur<=Hmax; Hcur+=Hstep) {
       const casa::Double  Hcur_rad=M_PI/12.*Hcur; // in radians
       const casa::Double cosha=cos(Hcur_rad-ant1long);
       const casa::Double sinha=sin(Hcur_rad-ant1long);
       // iteration over baselines
       for (casa::uInt i=0;i<x.nelements();++i)
            for (casa::uInt j=i+1;j<x.nelements();++j) {
	         ++numvistot;
	         const casa::Double lx=x[j]-x[i];
		 const casa::Double ly=y[j]-y[i];
		 const casa::Double lz=z[j]-z[i];
		 const casa::Complex uv(lx*sinha+ly*cosha,
		             -lx*cosha*sindec+ly*sinha*sindec+lz*cosdec);
                 // we don't need w-term for this program
		 // const Double w=lx*cosha*cosdec-ly*sinha*cosdec+lz*sindec;

		 // components of a unit vector pointing to the source
		 // in XYZ coordinates
		 const casa::Double sx=cosdec*cosha;
		 const casa::Double sy=-cosdec*sinha;
		 const casa::Double sz=sindec;

		 // checking whether the source is visible on antenna i
		 const casa::Double r_i=sqrt(sqr(x[i])+sqr(y[i])+sqr(z[i]));
		 const casa::Double cosz_i=(x[i]*sx+y[i]*sy+z[i]*sz)/r_i;
		 if (cosz_i<0) continue; // source is below horizon

		 // checking whether the source is visible on antenna j
		 const casa::Double r_j=sqrt(sqr(x[j])+sqr(y[j])+sqr(z[j]));
		 const casa::Double cosz_j=(x[j]*sx+y[j]*sy+z[j]*sz)/r_j;
		 if (cosz_j<0) continue; // source is below horizon

		 casa::Double phi=arg(uv); // angle of this visibility
		 if (phi>M_PI) phi-=M_PI;
		 if (phi<0) phi+=M_PI;

		 //tos<<real(uv)<<" "<<imag(uv)<<endl;
		 //tos<<-real(uv)<<" "<<-imag(uv)<<endl;

                 ++numvis;
		 if (domfs) {
		    // several adjacent radial cells may be filled due
		    // to mfs
		    casa::uInt boxmin=radhist(abs(uv)*(1.-fracband/2.));
		    casa::uInt boxmax=radhist(abs(uv)*(1.+fracband/2.));
		    casa::uInt angbox=anghist(phi);
		    for (casa::uInt k=boxmin;k<=boxmax;++k)
		       uvsamples(k,angbox)+=/*M_PI*(sqr(diam[i])+sqr(diam[j]))/
			    4.*/1./(fabs(Double(boxmax)-Double(boxmin))+1.);
		 } else 
		   uvsamples(radhist(abs(uv)),anghist(phi))++;
		             //M_PI*(sqr(diam[i])+sqr(diam[j]))/4.;
	    }     
  }
  // uvcoverage is calculated now
  os<<LogIO::NORMAL<<"Simulated "<<numvis<<" visibilities (for each spectral channel)"<<LogIO::POST;
  os<<LogIO::NORMAL<<numvistot-numvis<<" has been rejected due to elevation limit"<<LogIO::POST;

  // filling uvcoords
  for (casa::uInt i=0;i<nradbox;++i)
       for (casa::uInt j=0;j<nangbox;++j)
            uvcoords(i,j)=Complex(radhist.getValue(i)*cos(anghist.getValue(j)),radhist.getValue(i)*sin(anghist.getValue(j)));
 
  // calculating actual statistics
  if (nradbox<=1 && nangbox<=1) {
      meansamp=0.;
      return;
  }
  
  varsamp=0.; // will use it to accumulate the sum^2  
  meansamp=0.; // will use it to accumulate the sum

  // initialization of angular and radial statistics
  radmean.resize(nradbox);
  radvar.resize(nradbox);
  angmean.resize(nangbox);
  angvar.resize(nangbox);
  for (casa::uInt i=0;i<nradbox;++i) {
       radmean[i]=0;
       radvar[i]=0;
  }
  for (casa::uInt i=0;i<nangbox;++i) {
       angmean[i]=0;
       angvar[i]=0;
  }
   
  // calculation of statistics
  
  for (casa::uInt i=0;i<nradbox;++i)
       for (casa::uInt j=0;j<nangbox;++j) {
            const casa::Double nsmp=uvsamples(i,j);
	    const casa::Double nsmp2=sqr(uvsamples(i,j));
            meansamp+=nsmp;
	    varsamp+=nsmp2;
	    radmean[i]+=nsmp;
	    radvar[i]+=nsmp2;
	    angmean[j]+=nsmp;
	    angvar[j]+=nsmp2;
       }

  meansamp/=Double(nradbox*nangbox);
  varsamp/=Double(nradbox*nangbox);
  varsamp=sqrt(varsamp-sqr(meansamp));

  for (casa::uInt i=0;i<nradbox;++i) {
       radmean[i]/=Double(nangbox);
       radvar[i]/=Double(nangbox);
       radvar[i]=sqrt(radvar[i]-sqr(radmean[i]));
  }
  for (casa::uInt i=0;i<nangbox;++i) {
       angmean[i]/=Double(nradbox);
       angvar[i]/=Double(nradbox);
       angvar[i]=sqrt(angvar[i]-sqr(angmean[i]));       
  }
}

MethodResult FOMCalculator::runMethod(casa::uInt which,
     casa::ParameterSet &parameters, casa::Bool runMethod)
{
   //static String returnvalString = "returnval";
   try {
        switch(which) {
	    case 0: { // setLayout
	              casa::Parameter<casa::Vector<casa::Double> > x(parameters,"x",
		                                   ParameterSet::In);
		      casa::Parameter<casa::Vector<casa::Double> > y(parameters,"y",
		                                   ParameterSet::In);
                      casa::Parameter<casa::Vector<casa::Double> > z(parameters,"z",
		                                   ParameterSet::In);
		      casa::Parameter<casa::Vector<casa::Double> > diam(parameters,"diam",
		                                   ParameterSet::In);
		      if (runMethod) {
		          setLayout(x(),y(),z(),diam());
		      }
		      break;
	            }
             case 1: {  //getuvstats
	              casa::Parameter<casa::Int> nradbox(parameters,"nradbox",
	                                           ParameterSet::In);
                      casa::Parameter<casa::Int> nangbox(parameters,"nangbox",
	                                           ParameterSet::In);
                      casa::Parameter<casa::Bool> dologscale(parameters,"dologscale",
	                                           ParameterSet::In);
                      casa::Parameter<casa::Bool> domfs(parameters,"domfs",
	                                           ParameterSet::In);
                      casa::Parameter<casa::Bool> dosnapshot(parameters,"dosnapshot",
	                                           ParameterSet::In);
                      casa::Parameter<casa::Double> fracband(parameters,"fracband",
	                                           ParameterSet::In);
                      casa::Parameter<casa::Double> duration(parameters,"duration",
	                                           ParameterSet::In);
                      casa::Parameter<casa::Double> declination(parameters,"declination",
	                                           ParameterSet::In);
                      casa::Parameter<casa::GlishRecord> uvstats(parameters,"uvstats",
		                                   ParameterSet::Out);
		      if (runMethod) {
		          getUVStats(nradbox(),nangbox(),dologscale(),domfs(),
			             dosnapshot(),fracband(),duration(),
				     declination());
                          uvstats().add("uvsamples",uvsamples);
			  uvstats().add("uvcoords",uvcoords);
			  uvstats().add("meansamp",meansamp);
			  uvstats().add("varsamp",varsamp);
			  uvstats().add("radmean",radmean);
			  uvstats().add("radvar",radvar);
			  uvstats().add("angmean",angmean);
			  uvstats().add("angvar",angvar);
		      }
						   
                      break;
		      }
	      case 2: { // getsizestats
                      casa::Parameter<casa::GlishRecord> sizestats(parameters,"sizestats",
		                                   ParameterSet::Out);
		      if (runMethod) {
		          calcSizeStatistics();
		          sizestats().add("maxbaseline",maxbaseline);
			  sizestats().add("maxnsbaseline",maxnsbaseline);
			  sizestats().add("maxewbaseline",maxewbaseline);
			  sizestats().add("areain5km",areain5km);
			  sizestats().add("areain25km",areain25km);
			  sizestats().add("areain150km",areain150km);
			  sizestats().add("totalarea",totalarea);
			  sizestats().add("area",area);
			  sizestats().add("distance",distance);
			  sizestats().add("rabaseline",rabaseline);
		      }
	      
	              break;
	              } 
	    default:
	          return error("Unknown method");
        }
   }
   catch (const casa::String &str) {
      return error(str);
   }
   catch (const casa::AipsError &ae) {
      return error(ae.what());
   }
   catch (...) {
      return error("Unexpected exception");
   }
   return ok(); 
}

// reference position (core centre). The source will be
// in transit at this location
// getReferenceX,Y or Z return the geocetric coordinate of the core
// default is to return the position of the first antenna in the array
Double FOMCalculator::getReferenceX() const throw(casa::String)
{
  if (!x.nelements()) throw String("getReferenceX(): array should have at least one antenna");  
  return x[0];
}

Double FOMCalculator::getReferenceY() const throw(casa::String)
{
  if (!y.nelements()) throw String("getReferenceY(): array should have at least one antenna");  
  return y[0];
}

Double FOMCalculator::getReferenceZ() const throw(casa::String)
{
  if (!z.nelements()) throw String("getReferenceZ(): array should have at least one antenna");  
  return z[0];
}

// longitude in radians calculated using getReferenceX,Y or Z
Double FOMCalculator::getReferenceLongitude() const throw(casa::String)
{
  return atan2(getReferenceY(),getReferenceX()); // longitude in radians  
}

// latitude in radians calculated using getReferenceX,Y or Z
Double FOMCalculator::getReferenceLatitude() const throw(casa::String)
{
  const casa::Double r=sqrt(sqr(getReferenceX())+sqr(getReferenceY())+sqr(getReferenceZ()));
  if (r==0) throw String("getReferenceLatitude(): antenna appears at the Earth's centre");
  return asin(getReferenceZ()/r); // latitude in radians
}
