//# X11PCDLEnable.h: X11 PixelCanvas store/cache Enable command
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
//# $Id: X11PCDLEnable.h,v 19.5 2005/06/15 17:56:41 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLENABLE_H
#define TRIALDISPLAY_X11PCDLENABLE_H

#include <casa/aips.h>
#include <display/Display/DisplayEnums.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class X11PixelCanvas;

//
// <summary>
// Class to store commands to enable clipping on an X11PixelCanvas.
// </summary>
//
// <prerequisite>
// <li> Understanding of <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
//  caching mechanism
// </prerequisite>
//
// <etymology>
// X11PCDLEnable : <linkto class="X11PixelCanvas">X11PixelCanvas</linkto> 
// Display List - Enable command
// </etymology>
//
// <synopsis>
// This class is designed for use with the 
// <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>'
// caching mechanism.
//
// It stores the enable() command which is used to enable boolean options
// such as the clip window.
// </synopsis>
//
// <motivation>
// Needed to be able to put all output graphics commands in
// a display list for fast and convenient handling.
// </motivation>
//

class X11PCDLEnable  : public X11PCDisplayListObject {

 public:

  // Default Constructor Required
  X11PCDLEnable();

  // User Constructor
  X11PCDLEnable(X11PixelCanvas * xpc, Display::Option option);

  // translate does nothing
  virtual void translate(int xt, int yt);

  // draw calls xpc->enable(option)
  virtual void draw(::XDisplay * display, Drawable d, GC gc, Int, Int);

  // For caching optimization
  virtual Char optType() const { return 'g'; }

  // Destructor
  virtual ~X11PCDLEnable();

private:

  X11PixelCanvas * xpc_;
  Display::Option option_;

};


} //# NAMESPACE CASA - END

#endif


