//# X11PCDLDisplayList.h: X11 PixelCanvas hierarchical display list store
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
//# $Id: X11PCDLDisplayList.h,v 19.4 2005/06/15 17:56:41 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLDISPLAYLIST_H
#define TRIALDISPLAY_X11PCDLDISPLAYLIST_H

#include <casa/aips.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class PixelCanvas;

//
// <summary>
// Class to store heirarchies of X11PixelCanvas display list objects.
// </summary>
// 
// <prerequisite>
// <li> Understanding of <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
//  caching mechanism
// </prerequisite>
//
// <etymology>
// X11PCDLDisplayList : <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// Display List - Execute Display List object.
// </etymology>
//
// <synopsis>
// This class is designed for use with the 
// <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>'
// caching mechanism.
// 
// It stores a reference to a display list.  Execution of the
// object causes the display list to be drawn.  In this
// way hierarchical scenes may be constructed.
// </synopsis>
//
// <motivation>
// Needed to be able to put all output graphics commands in
// a display list for fast and convenient handling.
// </motivation>
//

class X11PCDLDisplayList  : public X11PCDisplayListObject {

 public:

  // Default Constructor Required
  X11PCDLDisplayList();

  // User Constructor
  X11PCDLDisplayList(PixelCanvas * pc, uInt listId);

  // translate each item in the list
  virtual void translate(Int xt, Int yt);

  // draw the list
  virtual void draw(::XDisplay * display, Drawable d, GC gc, Int xt, Int yt);

  // For caching optimization
  virtual Char optType() const { return 'f'; }

  // Destructor
  virtual ~X11PCDLDisplayList();

 private:
  
  // List id
  uInt listId_;

  // PixelCanvas where id is registered
  PixelCanvas * pc_;

};


} //# NAMESPACE CASA - END

#endif

