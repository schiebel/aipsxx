//# X11PCDLFilledRectangle.h: X11 PixelCanvas store/cache of F/Rectangle cmd
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
//# $Id: X11PCDLFilledRectangle.h,v 19.4 2005/06/15 17:56:41 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLFILLEDRECTANGLE_H
#define TRIALDISPLAY_X11PCDLFILLEDRECTANGLE_H

#include <casa/aips.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//
// <summary>
// Class to store commands to draw a filled rectangle on an X11PixelCanvas.
// </summary>
//
// <prerequisite>
// <li> Understanding of <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
//  caching mechanism
// </prerequisite>
//
// <etymology>
// X11PCDLFilledRectangle : <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// Display List - filled rectangle command
// </etymology>
//
// <synopsis>
// This class is designed for use with the 
// <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>'
// caching mechanism.
//
// This stores the command to clear a specific region of
// the <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// </synopsis>
//
// <motivation>
// Used to clear a rectangular area of the screen.
// </motivation>
//

class X11PCDLFilledRectangle  : public X11PCDisplayListObject {

 public:

  // Default Constructor Required
  X11PCDLFilledRectangle();

  // User Constructor
  X11PCDLFilledRectangle(Int x, Int y, uInt w, uInt h);

  // translate
  virtual void translate(Int xt, Int yt);

  // draw function
  virtual void draw(::XDisplay * display, Drawable d, GC gc, Int xt, Int yt);

  // For caching optimization
  virtual Char optType() const { return 'h'; }

  // Destructor
  virtual ~X11PCDLFilledRectangle();

private:

  // x and y are the bottom left corner of the area
  Int x_;
  Int y_;

  // w and h are the width and height of the rectangular area
  uInt w_;
  uInt h_;

};


} //# NAMESPACE CASA - END

#endif

