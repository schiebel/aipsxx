//# tMath.cc:
//# Copyright (C) 1999,2000,2001
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
//# $Id: tMath.cc,v 19.6 2004/11/30 17:50:14 ddebonis Exp $

#include <casa/aips.h>
#include <casa/Exceptions/Error.h>
#include <casa/Utilities/Assert.h>
#include <casa/BasicSL/String.h>
#include <casa/iostream.h>

#include <casa/BasicMath/Math.h>

#include <casa/namespace.h>
int main() {
  try {
    {
      Float x;
      setNaN(x);
      AlwaysAssert(isNaN(x), AipsError);
      AlwaysAssert(!isFinite(x), AipsError);
    }
    {
      Double x = floatNaN();
      AlwaysAssert(isNaN(x), AipsError);
      AlwaysAssert(!isFinite(x), AipsError);
    }
    {
      Float x = doubleNaN();
      AlwaysAssert(isNaN(x), AipsError);
      AlwaysAssert(!isFinite(x), AipsError);
    }
    {
      Double x;
      setNaN(x);
      AlwaysAssert(isNaN(x), AipsError);
      AlwaysAssert(!isFinite(x), AipsError);
    }
    {
      Float x;
      setInf(x);
      AlwaysAssert(isInf(x), AipsError);
      AlwaysAssert(!isFinite(x), AipsError);
    }
    {
      Double x = floatInf();
      AlwaysAssert(isInf(x), AipsError);
      AlwaysAssert(!isFinite(x), AipsError);
    }
    {
      Float x = doubleInf();
      AlwaysAssert(isInf(x), AipsError);
      AlwaysAssert(!isFinite(x), AipsError);
    }
    {
      Double x;
      setInf(x);
      AlwaysAssert(isInf(x), AipsError);
      AlwaysAssert(!isFinite(x), AipsError);
    }
  }
  catch (AipsError x) {
    cerr << x.getMesg() << endl;
    cout << "FAIL" << endl;
    return 1;
  } 
  cout << "OK" << endl;
  return 0;
}
// Local Variables: 
// compile-command: "gmake OPTLIB=1 tMath"
// End: 
