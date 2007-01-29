//# <ClassFileName.h>: this defines <ClassName>, which ...
//# Copyright (C) 1996,1997,2001,2004
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
//# $Id: NFITSFieldFillers.cc,v 19.4 2004/11/30 17:50:08 ddebonis Exp $

#include <NFITSFieldFillers.h>

#include <casa/Arrays/ArrayIO.h>
#include <casa/Utilities/Assert.h>

#include <casa/sstream.h>

#include <casa/namespace.h>
FITSStringArrayTypeWriter::FITSStringArrayTypeWriter(
    RecordInterface &outRecord,
    const String &outField,
    const RecordInterface &inRecord,
    const String &inField) :
    inArray_p(inRecord, inField),
    outString_p(outRecord, outField)
{
}

void FITSStringArrayTypeWriter::writeField()
{
    ostringstream str;
    str << *inArray_p;
    *outString_p = str.str();
}
