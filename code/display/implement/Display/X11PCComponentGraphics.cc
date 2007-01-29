//# X11PCComponentGraphics.cc: drawing and caching of multi-channel images
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
//# $Id: X11PCComponentGraphics.cc,v 19.4 2005/06/15 17:56:37 cvsmgr Exp $

#include <casa/Arrays/Matrix.h>
#include <display/Display/X11PixelCanvas.h>
#include <display/Display/X11PCDLImageComponent.h>
#include <display/Display/DisplayEnums.h>

namespace casa { //# NAMESPACE CASA - BEGIN

void X11PixelCanvas_drawImage(X11PixelCanvas *xpc,
			      const Matrix<uInt> &data,
			      const Int &x, const Int &y,
			      const Display::ColorComponent &component) {
  if (xpc->drawMode() == Display::Compile) {
    xpc->appendToDisplayList(new X11PCDLImageComponent(xpc, data, x, y, 
						       component));

  } else {
    xpc->bufferComponent(data, x, y, component);
  }
}

} //# NAMESPACE CASA - END

