//# X11PCDLClearRegion.cc: X11 PixelCanvas store/cache of ClearRegion cmd
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
//# $Id: X11PCDLClearRegion.cc,v 19.5 2005/06/15 17:56:38 cvsmgr Exp $

#include <casa/aips.h>
#include <casa/BasicMath/Math.h>
#include <display/Display/X11PixelCanvas.h>
#include <display/Display/X11PCDLClearRegion.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLClearRegion::X11PCDLClearRegion() 
  : x_(0), y_(0), w_(0), h_(0), xpc_(0) {
}

// User Constructor
X11PCDLClearRegion::X11PCDLClearRegion(X11PixelCanvas * xpc, Int x, Int y,
				       uInt w, uInt h) 
  : x_(x), y_(y), w_(w), h_(h), xpc_(xpc) {
}

void X11PCDLClearRegion::translate(Int tx, Int ty) {
  x_ += tx;
  y_ -= ty;
}

void X11PCDLClearRegion::draw(::XDisplay * display, Drawable d, GC gc, 
			      Int tx, Int ty) {
  translate(tx, ty);
  if (xpc_) {
    // clamp to area
    Int xt = max(x_, 0);
    Int yt = max(y_, 0);
    uInt wt = min(xpc_->width() - xt, w_); 
    uInt ht = min(xpc_->height() - yt, h_);
    // have to use XFRect because d could be inputOnly drawable (pixmap)
    uInt color = xpc_->color();
    xpc_->setColor(xpc_->clearColor());
    XFillRectangle(display, d, gc, xt, yt, wt, ht);
    xpc_->setColor(color);
  }
  translate(-tx, -ty);
}

// Destructor
X11PCDLClearRegion::~X11PCDLClearRegion() {
}


} //# NAMESPACE CASA - END

