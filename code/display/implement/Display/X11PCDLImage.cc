//# X11PCDLImage.cc: X11 PixelCanvas store/cache of Image command
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
//# $Id: X11PCDLImage.cc,v 19.4 2005/06/15 17:56:42 cvsmgr Exp $

#include <casa/aips.h>
#include <display/Display/X11PCDLImage.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLImage::X11PCDLImage()
  : xim_(0), x_(0), y_(0) {
}

X11PCDLImage::X11PCDLImage(XImage * xim, Int x, Int y)
  : xim_(xim), x_(x), y_(y) {
}

// Destructor
X11PCDLImage::~X11PCDLImage() {
  if (xim_) {
    delete [] xim_->data;
    xim_->data = 0;
    XDestroyImage(xim_);
  }
}

void X11PCDLImage::translate(Int xt, Int yt) {
  x_ += xt;
  y_ -= yt;
}

void X11PCDLImage::draw(::XDisplay * display, Drawable d, GC gc, 
			Int xt, Int yt) {
  XPutImage(display, d, gc, xim_, 0, 0, x_+xt, y_-yt, xim_->width, 
	    xim_->height);
}


} //# NAMESPACE CASA - END

