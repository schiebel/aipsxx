//# X11PCLimits.h: definition of the limits for X11 request buffers
//# Copyright (C) 1993,1994,1995,1996,1999,2000
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
//#$Id: X11PCLimits.h,v 19.4 2005/06/15 17:56:43 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCLIMITS_H
#define TRIALDISPLAY_X11PCLIMITS_H

#include <casa/aips.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Definition of the limits for X11 request buffers.
// </summary>
//
// <synopsis>
// The X graphics system has limits on the amount of memory
// transferred to the server in one go.  This limits the number of
// points and lines that can be sent in calls to XDrawPoints and
// XDrawLines.
//
// The X11PixelCanvas is designed to ensure large requests are broken
// into sizes small enough for X to handle.  X Standards require that
// the buffer is at least 16KB, so that size was chosen.
// </synopsis>

namespace X11Limits {
 
  extern const uInt RequestBufferSize;
  extern const uInt MaximumLineCount;
  extern const uInt MaximumPointCount;
 
};
 

} //# NAMESPACE CASA - END

#endif

