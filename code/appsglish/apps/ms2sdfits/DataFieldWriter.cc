//# ClassFileName.cc:  this defines ClassName, which ...
//# Copyright (C) 1997,1999,2000
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
//# $Id: DataFieldWriter.cc,v 19.3 2004/11/30 17:50:08 ddebonis Exp $

//# Includes

#include <DataFieldWriter.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <casa/Utilities/Copy.h>
#include <casa/Utilities/Assert.h>
#include <casa/Arrays/IPosition.h>

#include <casa/namespace.h>
DataFieldWriter::DataFieldWriter(RecordInterface &outRecord,
				 const RecordInterface &inRecord)
    : out_p(outRecord, "DATA"), in_p(inRecord, MS::columnName(MS::FLOAT_DATA))
{
    // Nothing
}

void DataFieldWriter::writeField()
{
    IPosition inShape = (*in_p).shape();
    IPosition outShape(4, 1);
    uInt nstokes = inShape(0);
    uInt nchan = inShape(1);
    outShape(0) = nchan;
    outShape(1) = nstokes;
    (*out_p).resize(outShape);
    Bool deleteOut, deleteIn;
    Float *out = (*out_p).getStorage(deleteOut);
    const Float *in = (*in_p).getStorage(deleteIn);
    for (uInt i=0;i<nstokes;i++) {
	objcopy((out+nchan*i), (in+i), nchan, 1, nstokes);
    }
    (*out_p).putStorage(out, deleteOut);
    (*in_p).freeStorage(in, deleteIn);
}
