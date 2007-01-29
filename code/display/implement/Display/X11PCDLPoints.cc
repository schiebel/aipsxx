//# X11PCDLPoints.cc: X11 PixelCanvas store/cache of Points command
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
//# $Id: X11PCDLPoints.cc,v 19.4 2005/06/15 17:56:42 cvsmgr Exp $

#include <casa/aips.h>
#include <display/Display/X11PCLimits.h>
#include <display/Display/X11PCDLPoints.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLPoints::X11PCDLPoints()
  : data_(0), n_(0), mode_(0) {
}

// User Constructor 
X11PCDLPoints::X11PCDLPoints(XPoint * data, uInt n, uInt mode)
  : data_(data), n_(n), mode_(mode) {
}

void X11PCDLPoints::translate(Int xt, Int yt) {
  if (xt == 0 && yt == 0) {
    return;
  }
  Short * p = (Short *) data_;
  for (uInt i = 0; i < n_; i++) {
    *p++ += xt;
    *p++ -= yt;
  }
}

void X11PCDLPoints::draw(::XDisplay * display, Drawable d, GC gc, 
			 Int xt, Int yt) {
  uInt len = X11Limits::MaximumPointCount;
  translate(xt,yt);
  uInt nDone = 0;
  while (nDone < n_) {
    if (n_ - nDone < X11Limits::MaximumPointCount) {
      len = n_ - nDone;
    }
    XDrawPoints(display, d, gc, data_ + nDone, len, mode_);
    nDone += len;
  }
  translate(-xt, -yt);
}

// Destructor
X11PCDLPoints::~X11PCDLPoints() {
  if (data_) {
    delete [] data_;
  }
}



} //# NAMESPACE CASA - END

