//# X11PCDLSetClipWin.h: X11 PixelCanvas store/cache of SetClipWin command
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
//# $Id: X11PCDLSetClipWin.h,v 19.4 2005/06/15 17:56:43 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLSETCLIPWIN_H
#define TRIALDISPLAY_X11PCDLSETCLIPWIN_H

#include <casa/aips.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class X11PixelCanvas;

//
// <summary>
// Class to store and cache X11PixelCanvas setclipwin command.
// </summary>
//
// <prerequisite>
// <li> Understanding of <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
//  caching mechanism
// </prerequisite>
//
// <etymology>
// X11PCDLSetClipWin : <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// display list - set clipping window command.
// </etymology>
//
// <synopsis>
// This class is designed for use with the 
// <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>'
// caching mechanism.
//
// It stores a rectangle definition.  when called, it applies the rectangle
// to the <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>, creating
// a clipping region outside of which no graphics can be drawn.  The clipping
// window must be enabled with enable(Display::ClipWindow) before it will
// begin acting as a clip window.
// </synopsis>
//
// <motivation>
// Needed to be able to put all output graphics commands in
// a display list for fast and convenient handling.
// Needed a way to constrain output graphics to a region of
// the screen.
// </motivation>
//

class X11PCDLSetClipWin  : public X11PCDisplayListObject {

 public:

  // Default Constructor Required
  X11PCDLSetClipWin();

  // User Constructor
  X11PCDLSetClipWin(X11PixelCanvas * xpc, Int x1, Int y1, Int x2, Int y2);

  // translate
  virtual void translate(Int xt, Int yt);

  // draw
  virtual void draw(::XDisplay * display, Drawable d, GC gc, Int xt, Int yt);

  // For caching optimization
  virtual Char optType() const { return 'u'; }

  // Destructor
  virtual ~X11PCDLSetClipWin();

 private:

  // pointer to the X11PixelCanvas to affect
  X11PixelCanvas * xpc_;
  
  // rectangular clip region
  Int x1_;
  Int y1_;
  Int x2_;
  Int y2_;

};


} //# NAMESPACE CASA - END

#endif

