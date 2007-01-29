//# X11PCDLColoredLines.h: X11 PixelCanvas store/cache of ColoredLines cmd
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
//# $Id: X11PCDLColoredLines.h,v 19.4 2005/06/15 17:56:39 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLCOLOREDLINES_H
#define TRIALDISPLAY_X11PCDLCOLOREDLINES_H

#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//
// <summary>
// Class to store commands to draw colored lines on an X11PixelCanvas.
// </summary>
//
// <prerequisite>
// <li> Understanding of <linkto class="X11PixelCanvas>X11PixelCanvas</linkto>
//      display list caching system
// </prerequisite>
//
// <etymology>
// X11PCDLColoredLines : <linkto class="X11PixelCanvas>X11PixelCanvas</linkto>
// Display List - Colored Lines
// </etymology>
//
// <synopsis>
// Stores in native X structures information required to
// draw a set of lines, each having their own color.
// </synopsis>
//
// <motivation>
// Needed to be able to put all output graphics commands in
// a display list for fast and convenient processing.
// </motivation>
//

class X11PCDLColoredLines  : public X11PCDisplayListObject {

 public:

  // Default Constructor Required
  X11PCDLColoredLines();

  // User Constructor
  X11PCDLColoredLines(const Vector<Short> & x1, const Vector<Short> & y1,
		      const Vector<Short> & x2, const Vector<Short> & y2,
		      const Vector<uInt> & colors);

  // translate 
  virtual void translate(Int xt, Int yt);

  // draw func
  virtual void draw(::XDisplay * display, Drawable d, GC gc, Int xt, Int yt);

  // For caching optimization
  virtual Char optType() const { return 'c'; }

  // Destructor
  virtual ~X11PCDLColoredLines();

 private:

  Vector<Short> x1_;
  Vector<Short> y1_;
  Vector<Short> x2_;
  Vector<Short> y2_;
  Vector<uInt> colors_;

};


} //# NAMESPACE CASA - END

#endif


