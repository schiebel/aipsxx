//# Index.h: Convert 0- and 1- relative indexing.
//# Copyright (C) 1996,1998
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
//# $Id: Index.cc,v 19.3 2004/11/30 17:51:11 ddebonis Exp $

#include <tasking/Tasking/Index.h>
#include <casa/Arrays/Vector.h>

namespace casa { //# NAMESPACE CASA - BEGIN

void Index::convertVector(Vector<Int> &out, const Vector<Index> &in, 
		   Bool outValuesAreLocal)
{
    Int offset = outValuesAreLocal ? 0 : 1;

    if (out.nelements() != in.nelements()) {
        out.resize(in.nelements());
    }
    uInt n = out.nelements();
    for (uInt i=0; i<n; i++) {
        out(i) = in(i)() + offset;
    }
}

void Index::convertVector(Vector<Index> &out, const Vector<Int> &in,
		   Bool inValuesAreLocal)
{
    Int offset = inValuesAreLocal ? 0 : -1;

    if (out.nelements() != in.nelements()) {
        out.resize(in.nelements());
    }
    uInt n = out.nelements();
    for (uInt i=0; i<n; i++) {
        out(i) = in(i) + offset;
    }
}

void Index::convertIPosition(IPosition &out, const Vector<Index> &in, 
		   Bool outValuesAreLocal)
{
    Int offset = outValuesAreLocal ? 0 : 1;

    if (out.nelements() != in.nelements()) {
        out.resize(in.nelements());
    }
    uInt n = out.nelements();
    for (uInt i=0; i<n; i++) {
        out(i) = in(i)() + offset;
    }
}

void Index::convertIPosition(Vector<Index> &out, const IPosition &in,
		   Bool inValuesAreLocal)
{
    Int offset = inValuesAreLocal ? 0 : -1;

    if (out.nelements() != in.nelements()) {
        out.resize(in.nelements());
    }
    uInt n = out.nelements();
    for (uInt i=0; i<n; i++) {
        out(i) = in(i) + offset;
    }
}

} //# NAMESPACE CASA - END

