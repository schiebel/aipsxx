//# X11PCDLLine.cc: X11 PixelCanvas store/cache of Line command
//# Copyright (C) 1993,1994,1995,1996,2000
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
//# $Id: X11PCDLLine.cc,v 19.4 2005/06/15 17:56:42 cvsmgr Exp $

#include <casa/aips.h>
#include <display/Display/X11PCDLLine.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLLine::X11PCDLLine()
  : x1_(0), y1_(0), x2_(0), y2_(0) {
}

// User Constructor
X11PCDLLine::X11PCDLLine(Short x1, Short y1, Short x2, Short y2)
  : x1_(x1), y1_(y1), x2_(x2), y2_(y2) {
}

void X11PCDLLine::translate(Int xt, Int yt) {
  x1_ += xt;
  x2_ += xt;
  y1_ -= yt;
  y2_ -= yt;
}

void X11PCDLLine::draw(::XDisplay * display, Drawable d, GC gc, Int xt, Int yt) {
  XDrawLine(display, d, gc, x1_+xt, y1_-yt, x2_+xt, y2_-yt);
}

// Destructor
X11PCDLLine::~X11PCDLLine() {
}


} //# NAMESPACE CASA - END

