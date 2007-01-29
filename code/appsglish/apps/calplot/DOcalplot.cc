//# DOcalplot.cc: Implementation of DOcalplot.h
//# Copyright (C) 1996-2006
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
//# $Id: DOcalplot.cc,v 1.2 2006/01/04 21:10:00 kgolap Exp $

#include <DOcalplot.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <tasking/Tasking/Index.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <graphics/Graphics/PGPlotterLocal.h>
#include <graphics/Graphics/PGPLOT.h>
#include <casa/Logging/LogIO.h>
#include <casa/sstream.h>
#include <casa/BasicSL/Constants.h>
#include <tasking/Tasking.h>
#include <casa/System/PGPlotter.h>


namespace casa { //# Begin casa namespace


// Constructor
  calplot::calplot(String& tabname) {
    ApplicationEnvironment::registerPGPlotter();
    itsPlotCal=new PlotCal(tabname);
  }

  calplot::~calplot() {};
  
  Bool calplot::setparameters(Int nxpanels, Int nypanels, String iteraxis, 
			      Bool multiplot) {
    return itsPlotCal->setPlotParam(nxpanels, nypanels, iteraxis, multiplot);
  }
  Bool calplot::setselect(Vector<Int>& antennas, Vector<Int>& caldescids, 
			  String plottype){
    
    return itsPlotCal->setSelect(antennas, caldescids, plottype);
  }

  Bool calplot::plot(){
    return itsPlotCal->plot();
  }

  Bool calplot::next(){
    return itsPlotCal->next();
  }

  Bool calplot::stopiter(){
    return itsPlotCal->stop();
  }

//
// methods from ApplicationObject
String calplot::className() const
{
  return "calplot";
}

Vector <String> calplot::methods() const
{
  Vector <String> method(5);
  Int i=0;
  method(i++)="setparameters";
  method(i++)="setselect";
  method(i++)="plot";
  method(i++)="next";
  method(i++)="stopiter";
 
  return method;
}



//----------------------------------------------------------------------------

MethodResult calplot::runMethod (uInt which, ParameterSet& inpRec, 
   Bool runMethod)
{
// Mechanism to allow execution of class methods from the 
// aips++ DO system.
// Inputs:
//    which        uInt               Selected method
//    inpRec       ParameterSet       Associated input parameters
//    runMethod    Bool               Execute method ?
//
  // Case method number of:
  switch (which) {
  case 0: {
    Parameter <Int> nxpanels(inpRec, "nxpanels", ParameterSet::In);
    Parameter <Int> nypanels(inpRec, "nypanels", ParameterSet::In);
    Parameter <String> iteraxis(inpRec, "iteraxis", ParameterSet::In);
    Parameter <Bool> multiplot(inpRec, "multiplot", ParameterSet::In);
    Parameter<Bool> returnval(inpRec, "returnval", ParameterSet::Out);

    if (runMethod) {
      returnval() = setparameters(nxpanels(), nypanels(), 
				  iteraxis(), multiplot());
    };
  }
    break;
  case 1: {
    Parameter <Vector<Int> > antennas(inpRec, "antennas", ParameterSet::In);
    Parameter <Vector<Int> > caldescids(inpRec, "caldescids", ParameterSet::In);    Parameter <String> plottype(inpRec, "plottype", ParameterSet::In);
    Parameter<Bool> returnval(inpRec, "returnval", ParameterSet::Out);
    if (runMethod) {
       returnval() = setselect(antennas(), caldescids(), 
					    plottype());
    };
  }
  break;
 
  case 2: {
    Parameter<Bool> returnval(inpRec, "returnval", ParameterSet::Out);
    if (runMethod) {
       returnval() = plot();
    };
  }
  break;
  case 3: {
    Parameter<Bool> returnval(inpRec, "returnval", ParameterSet::Out);
    if (runMethod) {
       returnval() = next();
    };
  }
  break;
  case 4: {
    Parameter<Bool> returnval(inpRec, "returnval", ParameterSet::Out);
    if (runMethod) {
       returnval() = stopiter();
    };
  }
  break;

  default: 
    return error ("No such method");
  };

  return ok();
};

MethodResult calplotFactory::make (ApplicationObject*& newObject,
                      const String& whichConstructor,
                      ParameterSet& inpRec,
                      Bool runConstructor) {
   // Intialization
   MethodResult retval;
   newObject = 0;

   // Case (constructor_type) of:
   if (whichConstructor == "calplot") {
      Parameter<String> caltable(inpRec, "caltable", ParameterSet::In);
      if (runConstructor) {
         newObject = new calplot (caltable());
       }
    } else {
      retval = String ("Unknown constructor ") + whichConstructor;
    };

   if (retval.ok() && runConstructor && !newObject) {
      retval = "Memory allocation error";
    };
   return retval;
}

} //#end casa namespace
