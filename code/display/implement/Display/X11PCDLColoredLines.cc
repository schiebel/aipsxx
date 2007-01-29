//# X11PCDLColoredLines.cc: X11 PixelCanvas store/cache of ColoredLines cmd
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
//# $Id: X11PCDLColoredLines.cc,v 19.4 2005/06/15 17:56:39 cvsmgr Exp $

#include <casa/aips.h>
#include <casa/Arrays/ArrayMath.h>
#include <display/Display/X11PCDLColoredLines.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
X11PCDLColoredLines::X11PCDLColoredLines() {
}

// User Constructor
X11PCDLColoredLines::X11PCDLColoredLines(const Vector<Short> & x1,
					 const Vector<Short> & y1,
					 const Vector<Short> & x2,
					 const Vector<Short> & y2,
					 const Vector<uInt> & colors) {
  x1_ = x1.copy();
  y1_ = y1.copy();
  x2_ = x2.copy();
  y2_ = y2.copy();
  colors_ = colors.copy();
}

void X11PCDLColoredLines::translate(Int xt, Int yt) {
  if (xt != 0) { 
    x1_ += (Short) xt; 
    x2_ += (Short) xt;
  }
  if (yt != 0) { 
    y1_ -= (Short) yt; 
    y2_ -= (Short) yt;
  }
}

void X11PCDLColoredLines::draw(::XDisplay * display, Drawable d, GC gc, 
			       Int xt, Int yt) {
  translate(xt, yt);
  uInt nLines = x1_.nelements();
  for (uInt i = 0; i < nLines; i++) {
    XSetForeground(display, gc, (uLong) colors_(i));
    XDrawLine(display, d, gc, x1_(i), y1_(i), x2_(i), y2_(i));
  }
  translate(-xt, -yt);
}

// Destructor
X11PCDLColoredLines::~X11PCDLColoredLines() {
}


} //# NAMESPACE CASA - END

