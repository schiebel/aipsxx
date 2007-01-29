//# FITSFieldFillers.cc: this defines <ClassName>, which ...
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
//#
//# $Id: FITSFieldFillers.cc,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#include <casa/Arrays/ArrayIO.h>
#include <FITSFieldFillers.h>
#include <FITSDefaultValues.h>
#include <casa/Utilities/Assert.h>
#include <ms/MeasurementSets/MSReader.h>

#include <casa/namespace.h>
template<class outType, class inType>
FITSScalarWriter<outType, inType>::FITSScalarWriter(MSReader &reader,
						    const String &tableName,
						    RecordInterface &outRecord,
						    const String &outField,
						    const RecordInterface &inRecord,
						    const String &inField)
    : itsReader(&reader), tableName(tableName),
      itsOut(outRecord, outField), itsIn(inRecord, inField)
{
    AlwaysAssert(isScalar(whatType(&(*itsOut))), AipsError);
    FITSDefaultValues::set(&itsDefVal);
}

template<class outType, class inType>
void FITSScalarWriter<outType, inType>::writeField()
{
    if (itsReader->rowNumber(tableName) >= 0) {
	// safe to use - just copy
	*itsOut = outType(*itsIn);
    } else {
	// default value
	*itsOut = itsDefVal;
    }
}

template<class outType, class inType>
FITSArrayWriter<outType, inType>::FITSArrayWriter(MSReader &reader,
						  const String &tableName,
						  RecordInterface &outRecord,
						  const String &outField,
						  const RecordInterface &inRecord,
						  const String &inField)
    : itsReader(&reader), tableName(tableName),
      itsOut(outRecord, outField), itsIn(inRecord, inField)
{
    AlwaysAssert(isArray(whatType(&(*itsOut))), AipsError);
    FITSDefaultValues::set(&itsDefVal);
}

template<class outType, class inType>
void FITSArrayWriter<outType, inType>::writeField()
{
    if (itsReader->rowNumber(tableName) >= 0) {
	// safe to use - just copy, first resize to be safe
	(*itsOut).resize((*itsIn).shape());
	*itsOut = Array<outType>(*itsIn);
    } else {
	// default value - use whatever the previous size was
	*itsOut = itsDefVal;
    }
}
