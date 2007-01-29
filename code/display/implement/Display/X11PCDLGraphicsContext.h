//# X11PCDLGraphicsContext.h: X11 PixelCanvas store/cache of Context commands
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
//# $Id: X11PCDLGraphicsContext.h,v 19.4 2005/06/15 17:56:41 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLGRAPHICSCONTEXT_H
#define TRIALDISPLAY_X11PCDLGRAPHICSCONTEXT_H

#include <casa/aips.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//
// <summary>
// Class to store context commands for X11PixelCanvases, eg. linewidth.
// </summary>
//  
// <prerequisite>
// <li> Knowledge of X11 Graphics Contexts
// <li> Understanding of <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
//  caching mechanism
// </prerequisite>
//
// <etymology>
// X11PCDLGraphicsContext : <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// Display List - Graphics context
// </etymology>
//
// <synopsis>
// This class is designed for use with the 
// <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>'
// caching mechanism.
//
// The X11PCDLGraphicsContext is used to cache changes to the state variables
// in X that control drawing properties.  X Properties it controls
// include
// <ul>
// <li> Drawing Function
// <li> Foreground Color
// <li> Background Color
// <li> Line Width
// <li> Line Style
// <li> Line Cap Style
// <li> Line Join Style
// <li> Polygon Fill Style
// <li> Polygon Fill Rule
// <li> Text Font
// <li> Arc Mode
// </ul>
// </synopsis>
//
// <motivation>
// Needed to be able to put all output graphics commands in
// a display list for fast and convenient handling.
// </motivation>
//

class X11PCDLGraphicsContext  : public X11PCDisplayListObject {

 public:

  // Default Constructor Required
  X11PCDLGraphicsContext();

  // User Constructor
  X11PCDLGraphicsContext(const XGCValues & values, uLong mask);

  // translate does nothing
  virtual void translate(Int, Int);

  // apply the context
  virtual void draw(::XDisplay * display, Drawable d, GC gc, Int, Int);

  // For caching optimization
  virtual Char optType() const { return 'i'; }

  // Destructor
  virtual ~X11PCDLGraphicsContext();

 private:
  
  // X11 mask that identifies the new value(s)
  uLong mask_;

  // values structure that contains the new information
  XGCValues values_;

};


} //# NAMESPACE CASA - END

#endif


