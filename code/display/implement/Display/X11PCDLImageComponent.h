//# X11PCDLImageComponent.h: X11 PixelCanvas store/cache of component image
//# Copyright (C) 1999,2000
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
//# $Id: X11PCDLImageComponent.h,v 19.5 2005/06/15 17:56:42 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PCDLIMAGECOMPONENT_H
#define TRIALDISPLAY_X11PCDLIMAGECOMPONENT_H

#include <casa/aips.h>
#include <casa/Arrays/Matrix.h>
#include <display/X11PixelCanvas/X11PCDisplayListObject.h>
#include <display/Display/DisplayEnums.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class X11PixelCanvas;

// <summary>
// Storing and caching of component (RGB/HSV) images for the X11PixelCanvas.
// </summary>

// <synopsis>
// This class implements the <linkto class=X11PCDisplayListObject>
// X11PCDisplayListObject</linkto> interface to provide storing and
// caching of component-based (RGB/HSV) images for the <linkto 
// class=X11PixelCanvas>X11PixelCanvas.</linkto>
// </synopsis>

class X11PCDLImageComponent : public X11PCDisplayListObject {

 public:

  // Constructor takes the Matrix of data, the x and y position at
  // which to paint the data, and the color component to draw.
  X11PCDLImageComponent(X11PixelCanvas *xpc,
			const Matrix<uInt> &data, 
			const uInt &x, const uInt &y,
			const Display::ColorComponent &component);

  // Destructor.
  virtual ~X11PCDLImageComponent() 
    { /* empty right now */; }

  // Translate the image component.
  virtual void translate(Int xt, Int yt)
    { /* empty right now */; }

  // Draw function.
  virtual void draw(::XDisplay *display, Drawable d, GC gc, Int xt, Int yt);

  // For caching optimisation.
  virtual Char optType() const 
    { return 'j'; } // ???

 private:
  
  // Pointer to the X11PixelCanvas.
  X11PixelCanvas *itsX11PixelCanvas;

  // Store the Matrix data here.
  Matrix<uInt> itsMatrix;

  // Store the x and y coordinates here.
  uInt itsX, itsY;

  // Store the id of the component here.
  Display::ColorComponent itsComponent;

};


} //# NAMESPACE CASA - END

#endif

