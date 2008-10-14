//# X11PCDLImageComponent.cc: X11 PixelCanvas store/cache of component image
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
//# $Id: X11PCDLImageComponent.cc,v 19.3 2005/06/15 17:56:42 cvsmgr Exp $

#include <display/Display/X11PixelCanvas.h>
#include <display/Display/X11PCDLImageComponent.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Constructor.
X11PCDLImageComponent::X11PCDLImageComponent(X11PixelCanvas *xpc,
					     const Matrix<uInt> &data,
					     const uInt &x, const uInt &y,
					     const Display::ColorComponent 
					     &component) :
  itsX11PixelCanvas(xpc),
  itsX(x),
  itsY(y),
  itsComponent(component) {
  itsMatrix.resize(data.shape());
  itsMatrix = data;
}

// Draw function.
void X11PCDLImageComponent::draw(::XDisplay *, Drawable, GC, Int, Int) {
  itsX11PixelCanvas->bufferComponent(itsMatrix, itsX, itsY, itsComponent);
}


} //# NAMESPACE CASA - END

