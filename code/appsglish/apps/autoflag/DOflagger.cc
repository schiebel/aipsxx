//# DOflagger.cc: this defines DOflagger
//# Copyright (C) 2000,2001
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
//# $Id: DOflagger.cc,v 19.12 2005/12/06 20:18:50 wyoung Exp $
#include <appsglish/autoflag/DOflagger.h>
#include <flagging/Flagging/RedFlagger.h>
#include <casa/Exceptions/Error.h>
#include <tasking/Glish.h>
#include <casa/stdio.h>
// 
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterConstraint.h>
#include <tasking/Tasking/Index.h>
#include <tasking/Tasking/MethodResult.h>
#include <casa/System/PGPlotter.h>
#include <tasking/Tasking/ObjectController.h>

#include <measures/Measures/Stokes.h>
#include <casa/Quanta/UnitMap.h>
#include <casa/Quanta/UnitVal.h>
#include <casa/Quanta/MVAngle.h>
#include <measures/Measures/MDirection.h>
#include <measures/Measures/MPosition.h>
#include <casa/Quanta/MVEpoch.h>
#include <measures/Measures/MEpoch.h>
#include <measures/Measures/MeasTable.h>

#include <casa/namespace.h>
// -----------------------------------------------------------------------
// flagger
// Default constructor and destructor
// -----------------------------------------------------------------------
flagger::flagger () 
{
}

flagger::~flagger()
{
}

// -----------------------------------------------------------------------
// className
// Return class name for aips++ DO system
// -----------------------------------------------------------------------
String flagger::className() const
{
// Return class name for aips++ DO system
// Outputs:
//    className    String    Class name
//
  return "flagger";
};

// -----------------------------------------------------------------------
// methods
// Return class methods names for aips++ DO system
// -----------------------------------------------------------------------
Vector <String> flagger::methods() const
{
  const char *method_names[] = {
        "attach",
        "queryagents",
        "queryoptions",
        "run",
        "detach",
	"setdata"
      };

  const uInt nm = sizeof(method_names)/sizeof(method_names[0]);
  Vector <String> method(nm);
  for( uInt i=0; i<nm; i++ )
    method(i) = method_names[i];
  return method;
};

// -----------------------------------------------------------------------
// noTraceMethods
// -----------------------------------------------------------------------
Vector<String> flagger::noTraceMethods() const
{
  //  Vector<String> nm(4);
  Vector<String> nm(5);
  nm(0) = "attach";
  nm(1) = "queryagents";
  nm(2) = "queryoptions";
  nm(3) = "detach";
  nm(4) = "setdata";
  return nm;
} 


// -----------------------------------------------------------------------
// runMethod
// Mechanism to allow execution of class methods from the 
// aips++ DO system.
// Inputs:
//    which        uInt               Selected method
//    inpRec       ParameterSet       Associated input parameters
//    runMethod    Bool               Execute method ?
// -----------------------------------------------------------------------
MethodResult flagger::runMethod (uInt which, ParameterSet& inpRec, 
                                    Bool runMethod)
{
  static String returnvalString = "returnval";
  try {
    switch( which ) {
    case 0: // attach
      {
	Parameter<String> msname(inpRec,"ms",ParameterSet::In);
	if( runMethod ) 
	  redflagger.attach( MeasurementSet(msname(),Table::Update) );
	break;
      }
      
    case 1: // queryagents - returns record of agents and their parameters
      {
        Parameter<GlishRecord> agents(inpRec,"returnval", ParameterSet::Out);
        if( runMethod ) 
          agents().fromRecord( redflagger.defaultAgents() );
        break;
      }
      
    case 2: // queryoptions - returns record of default options
      {
        Parameter<GlishRecord> opt(inpRec,"returnval", ParameterSet::Out);
        if( runMethod ) 
          opt().fromRecord( redflagger.defaultOptions() );
        break;
      }
      
    case 3: // run - do the actual flagging
      {
        Parameter<GlishRecord> gagents(inpRec,"agents", ParameterSet::In);
        Parameter<GlishRecord> gopt(inpRec,"options", ParameterSet::In);
        Parameter<Bool> assaying(inpRec,"assaying", ParameterSet::In);
        if( runMethod ) 
	  {
	    Record agents,opt;
	    gagents().toRecord(agents);
	    gopt().toRecord(opt);
	    redflagger.run(agents,opt,1);
	    if( assaying() )
	      redflagger.logSink()<<"\n>>>"<<LogIO::POST;
	  }
        break;
      }
      
    case 4: // detach
      {
        Parameter<Bool> res(inpRec,"returnval", ParameterSet::Out);
        if( runMethod )
	  {
	    redflagger.detach();
	    res() = True;
	  }
        break;
      }
      
    case 5: // setdata
      {
	Parameter<String> mode(inpRec, "mode", ParameterSet::In);
	Parameter<Vector<Int> > nchan(inpRec, "nchan", ParameterSet::In);
	Parameter<Vector<Index> > start(inpRec, "start", ParameterSet::In);
	Parameter<Vector<Int> > step(inpRec, "step", ParameterSet::In);
	Parameter<Quantity> mDataStart(inpRec, "mstart", ParameterSet::In);
	Parameter<Quantity> mDataStep(inpRec, "mstep", ParameterSet::In);
	Parameter<Vector<Index> > spectralwindowids(inpRec, "spwid",
						    ParameterSet::In);
	Parameter<Vector<Index> > fieldids(inpRec, "fieldid", ParameterSet::In);
	Vector<Int> spws(spectralwindowids().nelements());
	Parameter <String> msSelect (inpRec, "msselect", ParameterSet::In);
	
	uInt i;
	for (i=0;i<spws.nelements();i++) {
	  spws(i)=spectralwindowids()(i).zeroRelativeValue();
	}
	Vector<Int> fids(fieldids().nelements());
	for (i=0;i<fids.nelements();i++) {
	  fids(i)=fieldids()(i).zeroRelativeValue();
	}
	
	Vector<Int> chanstart(start().nelements());
	for (i=0;i<chanstart.nelements();i++) {
	  chanstart(i)=start()(i).zeroRelativeValue();
	}
	Parameter< Bool >
	  returnval(inpRec, returnvalString, ParameterSet::Out);
	if (runMethod) {
	  returnval() = redflagger.setdata (mode(), nchan(), chanstart,
					    step(),
					    MRadialVelocity(mDataStart(), MRadialVelocity::LSRK),
					    MRadialVelocity(mDataStep(), MRadialVelocity::LSRK),
					    spws, fids, msSelect());
	}
	break;
      }
    default: 
      return error("No such method");
    }
  }
  catch( AipsError err )
    {
      return error( err.getMesg() );
    }
  return ok();
}


