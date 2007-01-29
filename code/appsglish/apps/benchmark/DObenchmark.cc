//# DObenchmark.cc: Implementation of DObenchmark.h
//# Copyright (C) 1996,1997,1998,1999,2000,2001,2002
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
//# $Id: DObenchmark.cc,v 19.6 2005/11/07 21:17:03 wyoung Exp $
//----------------------------------------------------------------------------

#include <appsglish/benchmark/DObenchmark.h>
#include <casa/Containers/RecordDesc.h>
#include <tasking/Tasking/Parameter.h>
#include <tasking/Tasking/ParameterSet.h>
#include <casa/Logging.h>
#include <casa/Logging/LogIO.h>

#include <casa/namespace.h>
//----------------------------------------------------------------------------

benchmark::benchmark() : 
  benchmark_p()
{
// Default constructor
// Output to private data:
//    benchmark_p   Benchmark        Local Benchmark object
}

//----------------------------------------------------------------------------

void benchmark::visiterkernel(const String& msfile, const Double& interval,
			      const Int& rowblock, const Double& cache)
{
// Visibility iteration benchmark kernel
// Inputs:
//    msfile         const String&         MeasurementSet name
//    interval       const Double&         Iteration time interval (sec)
//    rowblock       const Int&            No. of rows to block in each
//                                         sub-interval iteration
//    cache          const Double&         Cache size in bytes
//
  // Invoke visIterKernel() on the Benchmark object
  benchmark_p.visIterKernel(msfile, interval, rowblock, cache);
};

//----------------------------------------------------------------------------

String benchmark::className() const
{
// Return class name for aips++ DO system
// Outputs:
//    className    String    Class name
//
   return "benchmark";
};

//----------------------------------------------------------------------------

Vector <String> benchmark::methods() const
{
// Return class methods names for aips++ DO system
// Outputs:
//    methods    Vector<String>   benchmark method names
//
   Vector <String> method(1);
   Int i = 0;
   method(i++) = "visiterkernel";
//
   return method;
};

//----------------------------------------------------------------------------

Vector <String> benchmark::noTraceMethods() const
{
// Methods for which automatic logging by the aips++ DO system is
// not required.
// Outputs:
//    noTraceMethods    Vector<String>   benchmark method names for no logging
//
   Vector <String> method(1);
   Int i = 0;
   method(i++) = "visiterkernel";
//
   return method;
};
//----------------------------------------------------------------------------

MethodResult benchmark::runMethod (uInt which, ParameterSet& inpRec, 
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
    // visiterkernel
    Parameter <String> msfile (inpRec, "msfile", ParameterSet::In);
    Parameter <Double> interval (inpRec, "interval", ParameterSet::In);
    Parameter <Int> rowblock (inpRec, "rowblock", ParameterSet::In);
    Parameter <Double> cache (inpRec, "cache", ParameterSet::In);

    if (runMethod) {
      visiterkernel(msfile(), interval(), rowblock(), cache());
    };
  }
  break;

  default: 
    return error ("No such method");
  };
  return ok();
};

//----------------------------------------------------------------------------



