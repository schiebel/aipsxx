//# X11PCDLPopMatrix.h: X11 PixelCanvas store/cache of PopMatrix command
//# Copyright (C) 1993,1994,1995,1996,2000
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
//# $Id: X11PCDLPopMatrix.h,v 19.4 2005/06/15 17:56:42 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLPOPMATRIX_H
#define TRIALDISPLAY_X11PCDLPOPMATRIX_H

#include <casa/aips.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class X11PixelCanvas;

//
// <summary>
// X11 display list object that stores the popMatrix command  
// </summary>
//
// <use visibility=export>
//
// <reviewed>
// </reviewed>
//  
// <prerequisite>
// <li> Understanding of <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
//  caching mechanism
// </prerequisite>
//
// <etymology>
// X11PCDLPuxhMatrix : <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// Display List PopMatrix command
// </etymology>
//
// <synopsis>
// This class is designed for use with the 
// <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>'
// caching mechanism.
//
// Cached version of the popMatrix command which can be used
// in display lists.
// </synopsis>
//
// <motivation>
// Needed to be able to put all output graphics commands in
// a display list for fast and convenient processing.
// </motivation>
//

class X11PCDLPopMatrix  : public X11PCDisplayListObject {

 public:
  
  // Default Constructor Required
  X11PCDLPopMatrix();

  // User Constructor
  X11PCDLPopMatrix(X11PixelCanvas * xpc);

  // translate does nothing
  virtual void translate(Int, Int);

  // For caching optimization
  virtual Char optType() const { return 'q'; }

  // draw command
  virtual void draw(::XDisplay * , Drawable , GC , Int , Int );

  // Destructor
  virtual ~X11PCDLPopMatrix();

 private:

  X11PixelCanvas * xpc_;
  
};


} //# NAMESPACE CASA - END

#endif


