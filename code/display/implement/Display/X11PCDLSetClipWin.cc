//# X11PCDLSetClipWin.cc: X11 PixelCanvas store/cache of SetClipWin command
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
//# $Id: X11PCDLSetClipWin.cc,v 19.4 2005/06/15 17:56:43 cvsmgr Exp $

#include <casa/aips.h>
#include <display/Display/X11PixelCanvas.h>
#include <display/Display/X11PCDLSetClipWin.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLSetClipWin::X11PCDLSetClipWin()
  : xpc_(0) {
}

// User Constructor
X11PCDLSetClipWin::X11PCDLSetClipWin(X11PixelCanvas * xpc, 
				     Int x1, Int y1, Int x2, Int y2)
  : xpc_(xpc), x1_(x1), y1_(y1), x2_(x2), y2_(y2) {
}

void X11PCDLSetClipWin::translate(Int xt, Int yt) {
  // y translation reversed when setClipWindow is called
  x1_ += xt; x2_ += xt;
  y1_ += yt; y2_ += yt;
}

void X11PCDLSetClipWin::draw(::XDisplay *, Drawable, GC, Int xt, Int yt) {
  translate(xt, yt);
  xpc_->setClipWindow(x1_, y1_, x2_, y2_);
  translate(-xt, -yt);
}

// Destructor
X11PCDLSetClipWin::~X11PCDLSetClipWin() {
}



} //# NAMESPACE CASA - END

