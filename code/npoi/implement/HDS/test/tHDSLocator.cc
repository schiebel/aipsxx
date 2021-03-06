//# tHDSLocator.cc:
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
//# $Id: tHDSLocator.cc,v 19.2 2004/11/30 17:50:40 ddebonis Exp $

#include <npoi/HDS/HDSLocator.h>
#include <casa/Exceptions/Error.h>
#include <casa/Utilities/Assert.h>

#include <casa/namespace.h>

int main() {
  try {
#if defined(HAVE_HDS)
    // Create a default locator;
    HDSLocator loc;
    // Check that it is not valid
    AlwaysAssert(loc.isValid() == False, AipsError);
    // This is about all that can be done with a locator class without invoking
    // functions in the HDSLib class. Those tests are done in tHDSLib.cc
#endif
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
// compile-command: "gmake OPTLIB=1 tHDSLocator"
// End: 
