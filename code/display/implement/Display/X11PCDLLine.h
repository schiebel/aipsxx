//# X11PCDLLine.h: X11 PixelCanvas store/cache of Line command
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
//# $Id: X11PCDLLine.h,v 19.4 2005/06/15 17:56:42 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLLINE_H
#define TRIALDISPLAY_X11PCDLLINE_H

#include <casa/aips.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//
// <summary>
// Class to store and cache X11PixelCanvas line command.
// </summary>
//
// <prerequisite>
// <li> Understanding of <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
//  caching mechanism
// </prerequisite>
//
// <etymology>
// X11PCDLLine : <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// Display List - Line command.
// </etymology>
//
// <synopsis>
// This class is designed for use with the 
// <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>'
// caching mechanism.
//
// It stores the endpoints of a single line and draws the line when
// asked.
// </synopsis>
//
// <motivation>
// Needed to be able to put all output graphics commands in
// a display list for fast and convenient handling.
// </motivation>
//

class X11PCDLLine  : public X11PCDisplayListObject {

 public:

  // Default Constructor Required
  X11PCDLLine();

  // User Constructor
  X11PCDLLine(Short x1, Short y1, Short x2, Short y2);

  // translate the line
  virtual void translate(Int xt, Int yt);

  // draw func
  virtual void draw(::XDisplay * display, Drawable d, GC gc, Int xt, Int yt);

  // For caching optimization
  virtual Char optType() const { return 'k'; }

  // line endpoints
  virtual short x1() const { return x1_; }
  virtual short y1() const { return y1_; }
  virtual short x2() const { return x2_; }
  virtual short y2() const { return y2_; }

  // Destructor
  virtual ~X11PCDLLine();

 private:

  // Line endpoints
  Short x1_;
  Short y1_;
  Short x2_;
  Short y2_;

};


} //# NAMESPACE CASA - END

#endif


