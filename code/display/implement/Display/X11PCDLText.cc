//# X11PCDLText.cc: X11 PixelCanvas store/cache of Text command
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
//# $Id: X11PCDLText.cc,v 19.4 2005/06/15 17:56:43 cvsmgr Exp $

#include <casa/aips.h>
#include <casa/Utilities/Copy.h>
#include <display/Display/X11PCDLText.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLText::X11PCDLText()
  : x_(0), y_(0), text_(0), len_(0) {
}

// User Constructor
X11PCDLText::X11PCDLText(Int x, Int y, const char * text, uInt len)
  : x_(x), y_(y), len_(len) {
  text_ = new char[len+1];
  objcopy(text_, text, len);
}

void X11PCDLText::translate(Int xt, Int yt) {
  x_ += xt;
  y_ -= yt;
}

void X11PCDLText::draw(::XDisplay * display, Drawable d, GC gc, Int xt, Int yt) {
  XDrawString(display, d, gc, x_+xt, y_-yt, text_, len_);
}

// Destructor
X11PCDLText::~X11PCDLText() {
  if (text_) delete [] text_;
}


} //# NAMESPACE CASA - END

