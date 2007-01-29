//# istream.h: Interim solution for standard/nonstandard system istream
//# Copyright (C) 2001,2002
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
//# $Id: istream.h,v 19.4 2004/11/30 17:50:13 ddebonis Exp $

#ifndef CASA_ISTREAM_H
#define CASA_ISTREAM_H

// Define the C standard C++ include file. 
// This is an interim solution to cater for the SGI non-existence of
// them (e.g. <cstring>)

// Make sure any special macros are set
#include <casa/aips.h>
// gcc has no <istream> yet. Change later
#if defined(__GNUG__)
#include <casa/iostream.h>
#else
#include <istream>
namespace casa { //# NAMESPACE CASA - BEGIN
using std::istream;
using std::ws;
} //# NAMESPACE CASA - END
#endif

namespace casa { //# NAMESPACE CASA - BEGIN

} //# NAMESPACE CASA - END

#endif