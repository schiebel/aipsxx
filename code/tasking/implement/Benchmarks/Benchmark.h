//# Benchmark.h: Class containing AIPS++ benchmarks defined in C++
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
//# $Id: Benchmark.h,v 19.6 2006/12/22 05:31:13 gvandiep Exp $

#ifndef TASKING_BENCHMARK_H
#define TASKING_BENCHMARK_H

#include <casa/aips.h>
#include <casa/BasicSL/String.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary> 
// benchmark: Class containing AIPS++ benchmarks defined in C++
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
// The Benchmark class contains AIPS++ performance benchmarks which 
// need to be written in C++. These are accessible via benchmark.g
// which also contains benchmarks written at the Glish level.
// </etymology>
//
// <example>
// <srcblock>
// </srcblock>
// </example>
//
// <motivation>
// Allow benchmarks to be defined which can only be expressed in C++
// </motivation>
//
// <todo asof="02/11/01">
//
// </todo>

class Benchmark
{
 public:
  // Default constructor, and destructor. 
  // Use the implicitly-defined copy constructor and assignment operator.
  Benchmark() {};
  ~Benchmark() {};

  // Visibility data iteration benchmark kernel; takes the following
  // set of input parameters: MS file name, iteration time interval,
  // number of rows to block when reading a sub-interval and the 
  // Table system cache size.
  void visIterKernel (const String& msfile, const Double& interval,
		      const Int& rowBlock, const Double& cacheInBytes);

 private:
};


} //# NAMESPACE CASA - END

#endif




