//# X11PCDLColoredPoints.cc: X11 PixelCanvas store/cache of ColoredPoints cmd
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
//# $Id: X11PCDLColoredPoints.cc,v 19.4 2005/06/15 17:56:39 cvsmgr Exp $

#include <casa/aips.h>
#include <casa/Arrays/ArrayMath.h>
#include <display/Display/X11PCDLColoredPoints.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLColoredPoints::X11PCDLColoredPoints() {
}

// User Constructor
X11PCDLColoredPoints::X11PCDLColoredPoints(const Vector<Short> & x1,
					   const Vector<Short> & y1,
					   const Vector<uInt> & colors) {
  x1_ = x1.copy();
  y1_ = y1.copy();
  colors_ = colors.copy();
}

void X11PCDLColoredPoints::translate(Int xt, Int yt) {
  if (xt != 0) {
    x1_ += (Short) xt;
  }
  if (yt != 0) { 
    y1_ -= (Short) yt;
  }
}

void X11PCDLColoredPoints::draw(::XDisplay * xdisplay, Drawable d, GC gc, 
				Int xt, Int yt) {
  translate(xt, yt);
  uInt nPoints = x1_.nelements();
  for (uInt i = 0; i < nPoints; i++) {
    XSetForeground(xdisplay, gc, (uLong) colors_(i));
    XDrawPoint(xdisplay, d, gc, x1_(i), y1_(i));
  }
  translate(-xt, -yt);
}

// Destructor
X11PCDLColoredPoints::~X11PCDLColoredPoints() {
}



} //# NAMESPACE CASA - END

