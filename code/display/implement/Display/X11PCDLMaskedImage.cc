//# X11PCDLMaskedImage.cc: X11 PixelCanvas store/cache of masked Image command
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
//# $Id: X11PCDLMaskedImage.cc,v 19.4 2005/06/15 17:56:42 cvsmgr Exp $

#include <casa/aips.h>
#include <display/Display/X11PCDLMaskedImage.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLMaskedImage::X11PCDLMaskedImage() :
  itsXImage(0), 
  itsXImageMask(0), 
  itsX(0), 
  itsY(0) {
}

X11PCDLMaskedImage::X11PCDLMaskedImage(XImage *xim, XImage *ximask,
				       Int x, Int y) :
  itsXImage(xim), 
  itsXImageMask(ximask), 
  itsX(x), 
  itsY(y) {
}

// Destructor
X11PCDLMaskedImage::~X11PCDLMaskedImage() {
  if (itsXImage) {
    delete [] itsXImage->data;
    itsXImage->data = 0;
    XDestroyImage(itsXImage);
  }
  if (itsXImageMask) {
    delete [] itsXImageMask->data;
    itsXImageMask->data = 0;
    XDestroyImage(itsXImageMask);
  }
}

void X11PCDLMaskedImage::translate(Int xt, Int yt) {
  itsX += xt;
  itsY -= yt;
}

void X11PCDLMaskedImage::draw(::XDisplay *display, Drawable d, GC gc, 
			      Int xt, Int yt) {
  if (itsXImageMask) {
    itsPixmapMask = XCreatePixmap(display, d, itsXImage->width, 
				  itsXImage->height, 1);
    XPutImage(display, itsPixmapMask, gc, itsXImageMask, 0, 0, 0, 0,
	      itsXImage->width, itsXImage->height);
    XSetClipOrigin(display, gc, itsX + xt, itsY - yt);
    XSetClipMask(display, gc, itsPixmapMask);
  }
  XPutImage(display, d, gc, itsXImage, 0, 0, itsX + xt, itsY - yt, 
	    itsXImage->width, itsXImage->height);
  if (itsXImageMask) {
    XSetClipMask(display, gc, None);
  }
}


} //# NAMESPACE CASA - END

