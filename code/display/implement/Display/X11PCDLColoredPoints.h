//# X11PCDLColoredPoints.h: X11 PixelCanvas store/cache of ColoredPoints cmd
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
//# $Id: X11PCDLColoredPoints.h,v 19.4 2005/06/15 17:56:40 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLCOLOREDPOINTS_H
#define TRIALDISPLAY_X11PCDLCOLOREDPOINTS_H

#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//
// <summary>
// Class to store commands to draw colored points on an X11PixelCanvas.
// </summary>
//
// <prerequisite>
// <li> Understanding of <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
//  caching mechanism
// </prerequisite>
//
// <etymology>
// X11PCDLColoredPoints : <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// </etymology>
//
// <synopsis>
// This class is designed for use with the 
// <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>'
// caching mechanism.
//
// Cached version of the <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// drawColoredPoints() function which stores point and color information
// in native X structures for later recall.
// </synopsis>
//
// <motivation>
// Needed to be able to put all output graphics commands in
// a display list for fast and convenient handling.
// </motivation>
//

class X11PCDLColoredPoints  : public X11PCDisplayListObject {

 public:

  // Default Constructor Required
  X11PCDLColoredPoints();

  // User Constructor
  X11PCDLColoredPoints(const Vector<Short> & x1, const Vector<Short> & y1,
		       const Vector<uInt> & colors);

  // translate points
  virtual void translate(Int xt, Int yt);

  // draw func
  virtual void draw(::XDisplay * display, Drawable d, GC gc, Int xt, Int yt);

  // For caching optimization
  virtual Char optType() const { return 'd'; }

  // Destructor
  virtual ~X11PCDLColoredPoints();

 private:

  Vector<Short> x1_;
  Vector<Short> y1_;
  Vector<uInt> colors_;

};


} //# NAMESPACE CASA - END

#endif

