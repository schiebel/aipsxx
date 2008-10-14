//# X11PCDLPolyline.cc: X11 PixelCanvas store/cache of Polyline command
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
//# $Id: X11PCDLPolyline.cc,v 19.4 2005/06/15 17:56:42 cvsmgr Exp $

#include <casa/aips.h>
#include <display/Display/X11PCLimits.h>
#include <display/Display/X11PCDLPolyline.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLPolyline::X11PCDLPolyline() : 
  nPoints_(0),
  points_(0) {
}

X11PCDLPolyline::X11PCDLPolyline(XPoint * points, uInt nPoints) :
  nPoints_(nPoints),
  points_(points) {
}

void X11PCDLPolyline::translate(Int xt, Int yt) {
  if (xt == 0 && yt == 0) {
    return;
  }
  Short * p = (Short *) points_;
  for (uInt i = 0; i < nPoints_; i++) {
    *p++ += xt;
    *p++ -= yt;
  }
}

// Draw func
void X11PCDLPolyline::draw(::XDisplay * display, Drawable d, GC gc, 
			   Int xt, Int yt) {
  translate(xt,yt);
  uInt nDone = 0;
  uInt len = X11Limits::MaximumPointCount;
  while (nDone < nPoints_) {
    if (nPoints_ - nDone < X11Limits::MaximumLineCount) {
      len = (nPoints_ - nDone);
    }
    XDrawLines(display, d, gc, points_ + nDone, len, CoordModeOrigin);
    nDone += len;
  }
  translate(-xt,-yt);
}

// Destructor
X11PCDLPolyline::~X11PCDLPolyline() {
  if (points_) {
    delete [] points_;
  }
}



} //# NAMESPACE CASA - END

