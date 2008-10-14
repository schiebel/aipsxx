//# tIndex.cc: Test the Index class.
//# Copyright (C) 1998,1999,2001
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
//# $Id: tIndex.cc,v 19.3 2004/11/30 17:51:12 ddebonis Exp $

#include <tasking/Tasking/Index.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/IPosition.h>
#include <casa/Utilities/Assert.h>

#include <casa/iostream.h>

#include <casa/namespace.h>
int main()
{
//   Index(Int zeroRelValue=0)
//   Int operator()() const
//   Int zeroRelativeValue() const
//   Int oneRelativeValue() const
    Index i1;
    Index i2(5);
    AlwaysAssertExit(i1() == 0 && i2.zeroRelativeValue() == 5 &&
		     i2.oneRelativeValue() == 6);

//   Index(uInt zeroRelValue)
    Index i3(3u);
    AlwaysAssertExit(i3() == 3);

//   Index(const Index &other) : local_value_p(other.local_value_p)
//   Index &operator=(const Index &other) 
    Index i4(i3);
    AlwaysAssertExit(i4() == 3);
    i4 = i2;
    AlwaysAssertExit(i4() == 5);

    
    Vector<Index> vin(2);
    vin(0) = 3;
    vin(1) = 33;
    Vector<Int> vi;
    IPosition ip;
//   static void convertVector(Vector<Int> &out, const Vector<Index> &in, 
// 		   Bool outValuesAreLocal=True);
    Index::convertVector(vi, vin);
    AlwaysAssertExit(vi(0) == 3 && vi(1) == 33);
    Index::convertVector(vi, vin, False);
    AlwaysAssertExit(vi(0) == 4 && vi(1) == 34);
//   static void convertVector(Vector<Index> &out, const Vector<Int> &in,
// 		     Bool inValuesAreLocal=True);
    Index::convertVector(vin, vi);
    AlwaysAssertExit(vin(0)() == 4 && vin(1)() == 34);
    Index::convertVector(vin, vi, False);
    AlwaysAssertExit(vin(0)() == 3 && vin(1)() == 33);
//   static void convertIPosition(IPosition &out, const Vector<Index> &in, 
// 		   Bool outValuesAreLocal=True);
    Index::convertIPosition(ip, vin);
    AlwaysAssertExit(ip(0) == 3 && ip(1) == 33);
    Index::convertIPosition(ip, vin, False);
    AlwaysAssertExit(ip(0) == 4 && ip(1) == 34);
//   static void convertIPosition(Vector<Index> &out, const IPosition &in,
// 		     Bool inValuesAreLocal=True);
    Index::convertIPosition(vin, ip);
    AlwaysAssertExit(vin(0)() == 4 && vin(1)() == 34);
    Index::convertIPosition(vin, ip, False);
    AlwaysAssertExit(vin(0)() == 3 && vin(1)() == 33);

//                    ~Index(); implicit
    cout << "OK" << endl;
    return 0;
}
