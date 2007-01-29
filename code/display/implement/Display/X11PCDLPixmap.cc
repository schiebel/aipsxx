//# X11PCDLPixmap.cc: X11 PixelCanvas store/cache of Pixmap command
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
//# $Id: X11PCDLPixmap.cc,v 19.4 2005/06/15 17:56:42 cvsmgr Exp $

#include <casa/aips.h>
#include <display/Display/X11PCDLPixmap.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLPixmap::X11PCDLPixmap()
  : display_(0), pm_(0), x_(0), y_(0), w_(0), h_(0) {
}

// User Constructor
X11PCDLPixmap::X11PCDLPixmap(::XDisplay * display, Pixmap pm, 
			     uInt w, uInt h,
			     Int x, Int y)
  : display_(display), pm_(pm), x_(x), y_(y), w_(w), h_(h) {
}

// Destructor
X11PCDLPixmap::~X11PCDLPixmap() {
  XFreePixmap(display_, pm_);
}

void X11PCDLPixmap::translate(Int xt, Int yt) {
  x_ += xt;
  y_ -= yt;
}

void X11PCDLPixmap::draw(::XDisplay * display, Drawable d, GC gc, 
			 Int xt, Int yt) {
  XCopyArea(display, pm_, d, gc, 0, 0, w_, h_, x_+xt, y_-yt);
}



} //# NAMESPACE CASA - END

