//# Benchmark.cc: Implementation of Benchmark.h
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
//# $Id: Benchmark.cc,v 19.4 2004/11/30 17:51:10 ddebonis Exp $
//----------------------------------------------------------------------------

#include <tasking/Benchmarks/Benchmark.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Containers/Block.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <msvis/MSVis/VisSet.h>
#include <msvis/MSVis/VisBuffer.h>
#include <msvis/MSVis/VisibilityIterator.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//----------------------------------------------------------------------------

void Benchmark::visIterKernel(const String& msfile, const Double& interval,
			      const Int& rowBlock, const Double& cacheInBytes) 
{
// Visibility iteration benchmark kernel
// Input:
//    msfile          const String&     MeasurementSet file name
//    interval        const Double&     Iteration time interval
//    rowBlock        const Int&        Number of rows to block in 
//                                      sub-interval iteration
//    cacheInBytes    const Double&     Cache size in bytes
//
  // Open the MS
  MeasurementSet ms(msfile, Table::Update);

  // Construct a visibility set
  Block<Int> nosort(0);
  Matrix<Int> noselection;
  Bool compress = False;
  VisSet vs(ms, nosort, noselection, interval, compress);

  // Attach a visibility buffer to the underlying visibility iterator
  VisIter& iter(vs.iter());
  VisBuffer vb(iter);

  // Set the row blocking for sub-interval iteration
  iter.setRowBlocking(rowBlock);

  // Iterate through the MS
  for (iter.originChunks(); iter.moreChunks(); iter.nextChunk()) {
    for (iter.origin(); iter.more(); iter++) {
      Vector<Int> ant1 = vb.antenna1();
    };
  };
}

//----------------------------------------------------------------------------







} //# NAMESPACE CASA - END

