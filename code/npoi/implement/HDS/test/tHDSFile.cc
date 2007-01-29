//# tHDSFile.cc:
//# Copyright (C) 1998,1999,2000,2001
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
//# $Id: tHDSFile.cc,v 19.3 2004/11/30 17:50:40 ddebonis Exp $

#include <npoi/HDS/HDSFile.h>
#include <casa/Exceptions/Error.h>
#include <casa/Utilities/Assert.h>
#include <casa/Arrays/Vector.h>
#include <casa/BasicSL/String.h>
#include <casa/iostream.h>

#include <casa/namespace.h>

int main() {
  try {
#if defined(HAVE_HDS)
    // Open the file (readonly)
    HDSFile file("demo_data", True);
    cout << "Name:" << file.name() 
	 << "\tType:" << file.type()
	 << "\tShape:" << file.shape() << endl;
    cout << "Contents:" << file.ls() << endl;
    file.cd("SYSLOG");
    cout << "Name:" << file.name() 
	 << "\tType:" << file.type()
	 << "\tShape:" << file.shape() << endl;
    cout << "Contents:" << file.ls() << endl;
    file.cd("..");
    file.cd("CONSTRICTORLOG");
    cout << "Name:" << file.name() 
 	 << "\tType:" << file.type()
 	 << "\tShape:" << file.shape() << endl;
    cout << "Contents:" << file.ls() << endl;
    file.cd("..");
    file.cd("FORMAT");
    cout << "Name:" << file.name() 
 	 << "\tType:" << file.type()
 	 << "\tShape:" << file.shape() << endl;
    cout << "Contents:" << file.ls() << endl;
    file.cd("..");
    file.cd("DATE");
    cout << "Name:" << file.name() 
 	 << "\tType:" << file.type()
 	 << "\tShape:" << file.shape() << endl;
    cout << "Contents:" << file.ls() << endl;
    file.cd("..");
    file.cd("USERID");
    cout << "Name:" << file.name() 
 	 << "\tType:" << file.type()
 	 << "\tShape:" << file.shape() << endl;
    cout << "Contents:" << file.ls() << endl;
    file.cd("..");
    file.cd("SYSTEMID");
    cout << "Name:" << file.name() 
 	 << "\tType:" << file.type()
 	 << "\tShape:" << file.shape() << endl;
    cout << "Contents:" << file.ls() << endl;
    file.cd("..");
    file.cd("GEOPARMS");
    cout << "Name:" << file.name() 
 	 << "\tType:" << file.type()
 	 << "\tShape:" << file.shape() << endl;
    cout << "Contents:" << file.ls() << endl;
    file.cd("..");
    file.cd("GENCONFIG");
    cout << "Name:" << file.name() 
 	 << "\tType:" << file.type()
 	 << "\tShape:" << file.shape() << endl;
    cout << "Contents:" << file.ls() << endl;
    file.cd("..");
    file.cd("SCANDATA");
    cout << "Name:" << file.name() 
 	 << "\tType:" << file.type()
 	 << "\tShape:" << file.shape() << endl;
    cout << "Contents:" << file.ls() << endl;
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
// compile-command: "gmake OPTLIB=1 tHDSFile"
// End: a
