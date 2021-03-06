//# version.h: Version information for AIPS++
//# Copyright (C) 1996,1997,2001
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
//# $Id: version2.cc,v 19.3 2004/11/30 17:50:13 ddebonis Exp $

#include <casa/version.h>

#include <casa/iostream.h>
#include <casa/iomanip.h>

namespace casa { //# NAMESPACE CASA - BEGIN

void VersionInfo::report(ostream &os)
{
    int major1 = majorVersion()/10;
    int major2 = majorVersion() - major1*10;
    os << major1 << "." << major2;

    if (minorVersion() == 0) {
	// End user release
	os << "." << setfill('0') << setw(2) << patch();
    } else {
	// Developer release
	if (patch() != 0) {
	    // Shouldn't happen, but allow it
	    os << "." << setfill('0') << setw(2) << patch();
	}
	os << " (build #" << minorVersion() << ")";
    }
    
    const char *ptr = info();
    if (ptr && *ptr) {
	os << " - " << ptr;
    }
}

} //# NAMESPACE CASA - END

