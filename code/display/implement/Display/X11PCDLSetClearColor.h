//# X11PCDLSetClearColor.h: X11 PixelCanvas store/cache of SetClearColor Cmd
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
//# $Id: X11PCDLSetClearColor.h,v 19.4 2005/06/15 17:56:43 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLSETCLEARCOLOR_H
#define TRIALDISPLAY_X11PCDLSETCLEARCOLOR_H

#include <casa/aips.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class X11PixelCanvas;

//
// <summary>
// Class to store and cache X11PixelCanvas setclearcolor command.
// </summary>
//
// <prerequisite>
// <li> Understanding of <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
//  caching mechanism
// </prerequisite>
//
// <etymology>
// X11PCDLSetClearColor : <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// Display List - setClearColor command
// </etymology>
//
// <synopsis>
// This class is designed for use with the 
// <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>'
// caching mechanism.
//
// This class stores the clear command, which it applies to the
// stored <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>.
// </synopsis>
//
// <motivation>
// Needed to be able to put all output graphics commands in
// a display list for fast and convenient handling.
// </motivation>
//

class X11PCDLSetClearColor  : public X11PCDisplayListObject {

 public:
  
  // Default Constructor Required
  X11PCDLSetClearColor();

  // User Constructor
  X11PCDLSetClearColor(X11PixelCanvas * xpc, uInt color);

  // translate does nothing
  virtual void translate(Int, Int);

  // draw command sets the clear color
  virtual void draw(::XDisplay * display, Drawable d, GC gc, Int, Int);

  // For caching optimization
  virtual Char optType() const { return 't'; }

  // Destructor
  virtual ~X11PCDLSetClearColor();

private:

  // Pointer to the X11Pixel canvas
  X11PixelCanvas * xpc_;

  // new clear color
  uInt color_;

};


} //# NAMESPACE CASA - END

#endif


