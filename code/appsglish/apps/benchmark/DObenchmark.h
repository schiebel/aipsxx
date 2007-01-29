//# DObenchmark.h: Define the benchmark DO
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
//# Correspondence concerning AIPS++ should be adressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: DObenchmark.h,v 19.7 2006/12/22 04:46:52 gvandiep Exp $

#ifndef APPSGLISH_DOBENCHMARK_H
#define APPSGLISH_DOBENCHMARK_H

#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <casa/Containers/Record.h>
#include <casa/Arrays/Vector.h>
#include <tasking/Tasking.h>
#include <tasking/Benchmarks/Benchmark.h>

#include <casa/namespace.h>
// <summary> 
// benchmark: DO interface to the Benchmark class
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
// </prerequisite>
//
// <etymology>
// From "benchmark".
// </etymology>
//
// <synopsis>
// Module DObenchmark defines the DO interface to the Benchmark
// class. The Benchmark class contains AIPS++ performance
// benchmarks which are written in C++. Glish-level benchmarks
// are defined in benchmark.g.
// </etymology>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation>
// Provide an AIPS++ DO interface to the Benchmark class
// </motivation>
//
// <todo asof="02/11/01">
//
// </todo>

class benchmark : public ApplicationObject
{
 public:
  // Default constructor, and destructor.
  // Use implicitly-defined copy constructor and assignment operator
  benchmark();
  ~benchmark() {};

  // Visibility data iteration benchmark; takes the following
  // parameters as input: MS file name, iteration interval (seconds),
  // number of rows to block in each sub-iteration and the Table
  // system cache size (bytes).
  void visiterkernel (const String& msfile, const Double& interval,
		      const Int& rowblock, const Double& cache);
  
  // Methods required to distribute the class as an aips++ DO
  // i) return the class name
  virtual String className() const;

  // ii) return a list of class methods
  virtual Vector <String> methods() const;

  // iii) return a list of methods for which no logging is required
  virtual Vector <String> noTraceMethods() const;
   
  // iv) Execute individual methods
  virtual MethodResult runMethod (uInt which, ParameterSet& inpRec,
				  Bool runMethod);

 private:
  // Local Benchmark object
  Benchmark benchmark_p;
};

#endif





