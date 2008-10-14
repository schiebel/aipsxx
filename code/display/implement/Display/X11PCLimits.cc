//# X11PCLimits.cc: definition of the limits for X11 request buffers
//# Copyright (C) 1993,1994,1995,1996,1999,2000,2002
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
//#$Id: X11PCLimits.cc,v 19.4 2005/06/15 17:56:43 cvsmgr Exp $

#include <casa/aips.h>
#include <display/Display/X11PCLimits.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// 16384 is minimum guaranteed buffer size defined by X protocol
// Actual buffer limit given by 4*XMaxRequestSize(display_)
const uInt X11Limits::RequestBufferSize = 4 * 4096;
const uInt X11Limits::MaximumLineCount = (X11Limits::RequestBufferSize / 4 - 3) / 2;
const uInt X11Limits::MaximumPointCount = X11Limits::RequestBufferSize / 4 - 3;


} //# NAMESPACE CASA - END

