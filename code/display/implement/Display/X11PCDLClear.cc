//# X11PCDLClear.cc: X11 PixelCanvas store/cache of Clear command
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
//# $Id: X11PCDLClear.cc,v 19.4 2005/06/15 17:56:37 cvsmgr Exp $

#include <casa/aips.h>
#include <display/Display/X11PixelCanvas.h>
#include <display/Display/X11PCDLClear.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLClear::X11PCDLClear() 
  : xpc_(0) {
}

// User Constructor
X11PCDLClear::X11PCDLClear(X11PixelCanvas * xpc) 
  : xpc_(xpc) {
}

void X11PCDLClear::translate(Int, Int) {
}

void X11PCDLClear::draw(::XDisplay * display, Drawable d, GC gc, Int, Int) {
  if (xpc_) {
    uInt color = xpc_->color();
    xpc_->setColor(xpc_->clearColor());
    XFillRectangle(display, d, gc, 0, 0, xpc_->width(), xpc_->height());
    xpc_->setColor(color);
  }
}

// Destructor
X11PCDLClear::~X11PCDLClear() {
}


} //# NAMESPACE CASA - END

