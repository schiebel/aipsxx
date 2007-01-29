//# tUnset.cc: Test program for the Unset class
//# Copyright (C) 1998,1999,2000,2001
//# Associated Universities, Inc. Washington DC, USA.
//#
//# This program is free software; you can redistribute it and/or modify it
//# under the terms of the GNU General Public License as published by the Free
//# Software Foundation; either version 2 of the License, or(at your option)
//# any later version.
//#
//# This program is distributed in the hope that it will be useful, but WITHOUT
//# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//# more details.
//#
//# You should have received a copy of the GNU General Public License along
//# with this program; if not, write to the Free Software Foundation, Inc.,
//# 675 Massachusetts Ave, Cambridge, MA 02139, USA.
//#
//# Correspondence concerning AIPS++ should be addressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//# $Id: tUnset.cc,v 19.3 2004/11/30 17:51:12 ddebonis Exp $

#include <tasking/Tasking/Unset.h>
#include <tasking/Glish/GlishRecord.h>
#include <casa/Exceptions/Error.h>
#include <casa/iostream.h>

#include <casa/namespace.h>
main()
{
    Int result1=0;
    Int result2=0;
    Int result3=0;
    try {
      GlishRecord IsSet;
      IsSet.add("foo", "bar");
      Int result1=Unset::isUnset(IsSet);
      cout << "IsSet is unset? : " << result1 << endl;
      Int result2=Unset::isUnset(Unset::unsetRecord());
      cout << "Unset::unsetRecord() is unset? : " << result2 << endl;
      GlishRecord TooMany=Unset::unsetRecord();
      TooMany.add("another", "record");
      Int result3=Unset::isUnset(TooMany);
      cout << "TooMany is unset? : " << result3 << endl;
    } catch (AipsError x) {
	cerr << x.getMesg() << endl;
	cout << "FAIL" << endl;
	return 1;
    } 
    cout << "OK" << endl;
    return 0;
}
