//# X11PCDLClearRegion.h: X11 PixelCanvas store/cache of ClearRegion cmd
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
//# $Id: X11PCDLClearRegion.h,v 19.4 2005/06/15 17:56:38 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLCLEARREGION_H
#define TRIALDISPLAY_X11PCDLCLEARREGION_H

#include <casa/aips.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class X11PixelCanvas;

//
// <summary>
// X11 display list object that stores the clear command
// </summary>
//  
// <prerequisite>
// <li> Understanding of <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
//  caching mechanism
// </prerequisite>
//
// <etymology>
// X11PCDLClearRegion : <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// Display List Clear command
// </etymology>
//
// <synopsis>
// This class is designed for use with the 
// <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>'
// caching mechanism.
//
// Cached version of the clear command which uses XFillRectangle
// to set the entire backing-store pixmap to the clear color.
// </synopsis>
//
// <motivation>
// Needed to be able to clear a region of the pixelCanvas.
// Needed to be able to put all output graphics commands in
// a display list for fast and convenient processing.
// </motivation>
//

class X11PCDLClearRegion  : public X11PCDisplayListObject {

 public:

  // Default Constructor Required
  X11PCDLClearRegion();

  // User Constructor
  X11PCDLClearRegion(X11PixelCanvas * xpc, Int x, Int y, uInt w, uInt h);

  // translate moves the region
  virtual void translate(Int tx, Int ty);

  // draw command
  virtual void draw(::XDisplay * display, Drawable d, GC gc, Int tx, Int ty);

  // For caching optimization
  virtual Char optType() const { return 'b'; }

  // Destructor
  virtual ~X11PCDLClearRegion();

 private:

  Int x_, y_;
  uInt w_, h_;
  X11PixelCanvas * xpc_;

};


} //# NAMESPACE CASA - END

#endif


