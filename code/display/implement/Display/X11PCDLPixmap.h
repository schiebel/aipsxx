//# X11PCDLPixmap.h: X11 PixelCanvas store/cache of Pixmap command
//# Copyright (C) 1993,1994,1995,1996,2000,2002
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
//# $Id: X11PCDLPixmap.h,v 19.4 2005/06/15 17:56:42 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLPIXMAP_H
#define TRIALDISPLAY_X11PCDLPIXMAP_H

#include <casa/aips.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//
// <summary>
//   
// </summary>
//
// <use visibility=export>
//
// <reviewed>
// </reviewed>
//  
// <prerequisite>
// <li> none
// </prerequisite>
//
// <etymology>
// The name of X11PCDLPixmap comes from ...
// </etymology>
//
// <synopsis>
// Display Class File
// </synopsis>
//
// <motivation>
// </motivation>
//
// <example>
// none available.
// </example>
//
// <todo>
// <li> write and test!
// </todo>
//

class X11PCDLPixmap  : public X11PCDisplayListObject {

 public:

  // Default Constructor Required
  X11PCDLPixmap();

  // User Constructor
  X11PCDLPixmap(::XDisplay * display, Pixmap pm, 
		uInt w, uInt h, Int x, Int y);

  // Destructor
  virtual ~X11PCDLPixmap();

  // translate
  virtual void translate(Int xt, Int yt);

  // draw func
  virtual void draw(::XDisplay * display, Drawable d, GC gc, 
				   Int xt, Int yt);

  // For caching optimization
  virtual Char optType() const { return 'x'; }

 private:

  ::XDisplay * display_;
  Pixmap pm_;
  Int x_, y_;
  uInt w_, h_;

};


} //# NAMESPACE CASA - END

#endif


