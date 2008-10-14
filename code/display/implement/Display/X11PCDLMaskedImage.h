//# X11PCDLMaskedImage.h: X11 PixelCanvas store/cache of masked Image command
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
//# $Id: X11PCDLMaskedImage.h,v 19.4 2005/06/15 17:56:42 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLMASKEDIMAGE_H
#define TRIALDISPLAY_X11PCDLMASKEDIMAGE_H

#include <casa/aips.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Class to store command for displaying a masked image on an X11PixelCanvas.
// </summary>
//  
// <prerequisite>
// <li> Understanding of <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
//  caching mechanism
// <li> Understanding of XImages and their display using XLib
// </prerequisite>
//
// <etymology>
// X11PCDLMaskedImage : <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// Display List - Masked Image.
// </etymology>
//
// <synopsis>
// This class is designed for use with the 
// <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>'
// caching mechanism.
//
// X11PCDLMaskedImage stores a request to draw a masked image in the
// form of an XImage structure.
//
// Note: Presently the image stored is first clipped to the window it was
// first drawn into.
// </synopsis>
//
// <motivation>
// Needed to be able to put all output graphics commands in
// a display list for fast and convenient handling.
// </motivation>
//

class X11PCDLMaskedImage  : public X11PCDisplayListObject {

 public:
  
  // Default Constructor Required
  X11PCDLMaskedImage();

  // User Constructor
  X11PCDLMaskedImage(XImage *xim, XImage *ximask, Int x, Int y);

  // translate the image
  virtual void translate(Int xt, Int yt);

  // draw function
  virtual void draw(::XDisplay *display, Drawable d, GC gc, Int xt, Int yt);

  // For caching optimization
  virtual Char optType() const 
    { return 'j'; }

  // Destructor
  virtual ~X11PCDLMaskedImage();

 private:

  // Pointer to the image
  XImage *itsXImage;

  // Pointer to the image mask
  XImage *itsXImageMask;

  // Mask pixmap
  Pixmap itsPixmapMask;

  // upper-left pixel of image rel to upper-left corner of drawable
  Int itsX;   
  Int itsY;

};


} //# NAMESPACE CASA - END

#endif


