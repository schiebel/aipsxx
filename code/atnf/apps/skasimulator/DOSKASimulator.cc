// DOSKASimulator distributed object to simulate AIPS++ datasets
//                for simple models and do some experiments related
//                to SKA design

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
//# $Id: DOSKASimulator.cc,v 1.3 2005/09/19 04:19:10 mvoronko Exp $


#include "DOSKASimulator.h"

#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>
#include <casa/Logging/LogIO.h>
#include <casa/Logging/LogSink.h>
#include <casa/BasicSL/Complex.h>
#include <casa/Exceptions/Error.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <casa/Containers/RecordInterface.h>
#include <casa/Containers/Record.h>

using namespace casa;
// SKASimulator

SKASimulator::SKASimulator() {};

// obligatory methods
String SKASimulator::className() const
{
  return "SKASimulator";
}

Vector<casa::String> SKASimulator::methods() const
{
  casa::Vector<casa::String> method(12);
  casa::Int i=0;
  method(i++)="setlayout";
  method(i++)="setskymodel";
  method(i++)="setcorparams";
  method(i++)="setsidtimes";
  method(i++)="settimes";
  method(i++)="simulate";
  method(i++)="setoptions";
  method(i++)="setrfimodel";
  method(i++)="setaddgaussnoise";
  method(i++)="getstatus";
  method(i++)="setdelaymodel";
  method(i++)="simresidualdelays";
  return method;
}

// to avoid logging simple functions
Vector<casa::String>  SKASimulator::noTraceMethods() const
{
  casa::Vector<casa::String> method(10);
  casa::Int i=0;
  method(i++)="setlayout";
  method(i++)="setskymodel";
  method(i++)="setcorparams";
  method(i++)="setsidtimes";
  method(i++)="settimes";
  method(i++)="setoptions";
  method(i++)="setrfimodel";
  method(i++)="setaddgaussnoise";
  method(i++)="getstatus";
  method(i++)="setdelaymodel";
  return method;
}

MethodResult SKASimulator::runMethod(casa::uInt which,
     casa::ParameterSet &parameters, casa::Bool runMethod)
{
   //static String returnvalString = "returnval";
   try {
        switch(which) {
	    case 0: { // setITRFLayout
	              casa::Parameter<casa::Bool> returnval(parameters,"returnval",
		                                ParameterSet::Out);
	              casa::Parameter<casa::Vector<casa::Double> > x(parameters,"x",
		                                   ParameterSet::In);
		      casa::Parameter<casa::Vector<casa::Double> > y(parameters,"y",
		                                   ParameterSet::In);
                      casa::Parameter<casa::Vector<casa::Double> > z(parameters,"z",
		                                   ParameterSet::In);
		      casa::Parameter<casa::Vector<casa::Double> > diam(parameters,"diam",
		                                   ParameterSet::In);
		      if (runMethod) {
		          returnval()=setITRFLayout(x(),y(),z(),diam());
		      }
		      break;
	            }
            case 1: { //setSkyModel
	              casa::Parameter<casa::Bool> returnval(parameters,"returnval",
		                                ParameterSet::Out);
	              casa::Parameter<casa::String> cl(parameters,"componentlist",
		                                ParameterSet::In);
	              if (runMethod) 
		          returnval()=setSkyModel(cl());
		      		      
	              break;
	            }
	     case 2: { // setcorparams
	              casa::Parameter<casa::Bool> returnval(parameters,"returnval",
		                                ParameterSet::Out);
		      casa::Parameter<casa::Int>  nchannels(parameters,"nchannels",
		                                ParameterSet::In);
	              casa::Parameter<casa::Quantity> chbandw(parameters,"chbandw",
		                                ParameterSet::In);
	              casa::Parameter<casa::Quantity> coravg(parameters,"coravg",
		                                ParameterSet::In);
	              casa::Parameter<casa::Quantity> corgap(parameters,"corgap",
		                                ParameterSet::In);
                      if (runMethod) 
		          returnval()=setCorParams(nchannels(),
			         chbandw(),coravg(),corgap());		      
	              break;
	             }
             case 3: { // setsidtimes
	              casa::Parameter<casa::Bool> returnval(parameters,"returnval",
		                                ParameterSet::Out);
	              casa::Parameter<casa::Quantity> sidstart(parameters,"sidstart",
		                                ParameterSet::In);
	              casa::Parameter<casa::Quantity> sidstop(parameters,"sidstop",
		                                ParameterSet::In);
	              casa::Parameter<casa::MEpoch>   utcday(parameters,"utcday",
		                                ParameterSet::In);
	              if (runMethod)
		          returnval()=setSiderealTimes(sidstart(),
			       sidstop(),utcday());
                      break; 			       
	             }
             case 4: { // settimes
	              casa::Parameter<casa::Bool> returnval(parameters,"returnval",
		                                ParameterSet::Out);
	              casa::Parameter<casa::MEpoch> start(parameters,"start",
		                                ParameterSet::In);
	              casa::Parameter<casa::MEpoch> stop(parameters,"stop",
		                                ParameterSet::In);
                      if (runMethod)
		          returnval()=setTimes(start(),stop());
		      break;
	             }
	     case 5: { // simulate
	              casa::Parameter<casa::Bool> returnval(parameters,"returnval",
		                                ParameterSet::Out);
	              casa::Parameter<casa::String> fname(parameters,"fname",
		                              ParameterSet::In);
                      casa::Parameter<casa::Quantity> freq(parameters,"freq",
		                              ParameterSet::In);
		      casa::Parameter<casa::MDirection> phasecntr(parameters,"phasecntr",
		                              ParameterSet::In);
		      if (runMethod)
		          returnval()=simulate(fname(),freq(),phasecntr());
		      break;	  
	             }
             case 6: { // setoptions
	              casa::Parameter<casa::Bool> returnval(parameters,"returnval",
		                                ParameterSet::Out);
		      casa::Parameter<casa::Bool> dosky(parameters,"dosky",
		                            ParameterSet::In);
                      casa::Parameter<casa::Bool> dobandsmear(parameters,"dobandsmear",
		                            ParameterSet::In);
                      casa::Parameter<casa::Bool> dotasmear(parameters,"dotasmear",
		                            ParameterSet::In);
                      casa::Parameter<casa::Bool> dorfi(parameters,"dorfi",
		                            ParameterSet::In);
                      casa::Parameter<casa::Bool> donoise(parameters,"donoise",
		                            ParameterSet::In);
                      casa::Parameter<casa::Bool> dovp(parameters,"dovp",
		                            ParameterSet::In);
                      casa::Parameter<casa::Bool> dodelay(parameters,"dodelay",
		                            ParameterSet::In);
                      if (runMethod)
		          returnval()=setOptions(dosky(),dobandsmear(),
			        dotasmear(),dorfi(),donoise(),dovp(),dodelay());
                      break;				
	             }
	     case 7: { // setrfimodel
	              casa::Parameter<casa::Bool> returnval(parameters,"returnval",
		                                ParameterSet::Out);
                      casa::Parameter<casa::Quantity> flux(parameters,"flux",
		                                ParameterSet::In);
                      casa::Parameter<casa::MPosition> Rc(parameters,"Rc",
		                                ParameterSet::In);
		      casa::Parameter<casa::MPosition> Rr(parameters,"Rr",
		                                ParameterSet::In);
	 	      casa::Parameter<casa::MPosition> Rrdot(parameters,"Rrdot",
		                                ParameterSet::In);
		      casa::Parameter<casa::String> timeunit(parameters,"timeunit",
		                                ParameterSet::In);
                      if (runMethod)
		          returnval()=setRFIModel(flux(),Rc(),Rr(),
			             Rrdot(),timeunit());
                      break;				     
		     }
	       case 8: { // setaddgaussnoise
	              casa::Parameter<casa::Bool> returnval(parameters,"returnval",
		                                ParameterSet::Out);
                      casa::Parameter<casa::Quantity> variance(parameters,"variance",
		                                ParameterSet::In);
                      casa::Parameter<casa::Quantity> mean(parameters,"mean",
		                                ParameterSet::In);
                      if (runMethod)
		          returnval()=setAddGaussianNoise(variance(),mean());
                      break;
	             }
		case 9: { // getstatus
		      casa::Parameter<casa::Bool> returnval(parameters,"returnval",
		                                ParameterSet::Out);
                      casa::Parameter<casa::GlishRecord> status(parameters,"status",
		                                ParameterSet::Out);
                      casa::Parameter<casa::Bool> beQuiet(parameters,"bequiet",
		                                ParameterSet::In);
                      if (runMethod) {
		          casa::Record rec; // a temporary object - AIPS++ record
			  returnval()=getStatus(rec,beQuiet());
			  status().fromRecord(rec);
		      }
		      break;
		     }
		case 10: { // setdelaymodel
	              casa::Parameter<casa::Bool> returnval(parameters,"returnval",
		                                ParameterSet::Out);
                      casa::Parameter<casa::String> mdl(parameters,"mdl",
		                                ParameterSet::In);
                      if (runMethod)
		          returnval()=setDelayModel(mdl());
                      break;				     
		     }
	       case 11: { // simresidualdelays - tests, not necessary for
		           // the original simulator
		       casa::Parameter<casa::Bool> returnval(parameters,"returnval",
		                                ParameterSet::Out);
		       casa::Parameter<casa::Vector<casa::Double> > offsetsx(parameters,"offsetsx",
		                                   ParameterSet::In);
		       casa::Parameter<casa::Vector<casa::Double> > offsetsy(parameters,"offsetsy",
		                                   ParameterSet::In);
		       casa::Parameter<casa::Vector<casa::Double> > delays(parameters,"delays",
		                                   ParameterSet::Out);
		       casa::Parameter<casa::Int> ant1(parameters,"ant1",
		                                   ParameterSet::In);
		       casa::Parameter<casa::Int> ant2(parameters,"ant2",
		                                   ParameterSet::In);
		       casa::Parameter<casa::MDirection> phasecntr(parameters,"phasecntr",
		                              ParameterSet::In);
		       casa::Parameter<casa::MFrequency> freq(parameters,"freq",
		                              ParameterSet::In);
		       if (runMethod) 
			  returnval()=simResidualDelays(delays(),offsetsx(),
			         offsetsy(),(uInt)ant1(),(uInt)ant2(),
		                 phasecntr(),freq());
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
      return error(ae.getMesg());
   }
   catch (...) {
      return error("Unexpected exception");
   }
   return ok(); 
}
