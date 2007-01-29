//# X11PCRasterGfx2.cc: raster graphics routines for X11PixelCanvas
//# Copyright (C) 1999,2000,2001,2003
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
//# $Id: X11PCRasterGfx2.cc,v 19.4 2005/06/15 17:56:43 cvsmgr Exp $

#include <display/Display/X11PixelCanvas.h>
#include <display/Display/X11PCDLImage.h>
#include <display/Display/X11PCDLPixmap.h>
#include <display/Display/X11PCDLMaskedImage.h>
#include <display/Display/X11PCDLMaskedPixmap.h>
#include <casa/Arrays/Matrix.h>

namespace casa { //# NAMESPACE CASA - BEGIN

void X11PixelCanvas_drawImage(X11PixelCanvas *xpc,
			      const Matrix<uInt> &data,
			      const Matrix<Bool> &mask,
			      const Int &xoffset, const Int &yoffset) {
  // dimensions
  uInt nx = data.nrow();
  uInt ny = data.ncolumn();
  uInt ximXSize = nx;
  uInt ximYSize = ny;

  // compute minimum size of required XImage and build it
  Int rt = (xpc->width() - (xoffset + nx));  
  if (rt < 0) {
    rt = 0;
  }
  ximXSize = xpc->width() - ((xoffset > 0) ? xoffset : 0) - rt;
  rt = (xpc->height() - (yoffset + ny)); 
  if (rt < 0) {
    rt = 0;
  }
  ximYSize = xpc->height() - ((yoffset > 0) ? yoffset : 0) - rt;
  
  // image not visible, quit
  if ((ximXSize == 0) || (ximYSize == 0)) {
    return;
  }

  // allocate space for XImage
  uLong *ximData = new uLong[ximXSize * ximYSize];
  XImage *xim = XCreateImage(xpc->display(), xpc->visual(), xpc->depth(),
			     ZPixmap, 0, (char *)ximData, ximXSize,
			     ximYSize, BitmapPad(xpc->display()), 0);
  // and for mask
  XImage *xmask = XCreateImage(xpc->display(), xpc->visual(), 1,
			       ZPixmap, 0, 0, ximXSize,
			       ximYSize, 8, 0);
  xmask->data = (char *)(new char[xmask->bytes_per_line * xmask->height]);

  // compute dataXIndex, dataYIndex
  uInt dataXIndex = (xoffset < 0) ? -xoffset : 0;
  uInt dataYIndex = (yoffset < 0) ? -yoffset : 0;

  // fill the XImage with data.  c is cell
  uInt dxc = dataXIndex;
  uInt dyc = dataYIndex;
  for (uInt y = ximYSize; y > 0;) {
    y--;
    dxc = dataXIndex;
    for (uInt x = 0; x < ximXSize; x++, dxc++) {
      XPutPixel(xim, x, y, static_cast<unsigned long>(data(dxc,dyc)));
      if (mask(dxc, dyc)) {
	XPutPixel(xmask, x, y, 1);
      } else {
	XPutPixel(xmask, x, y, 0);
      }
    }
    dyc++;
  }

  // paste the image on the offscreen pixmap
  uInt outputXoffset = (xoffset > 0) ? xoffset : 0;
  uInt outputYoffset = (yoffset > 0) ? yoffset : 0;

  // need a local graphics context so that we don't offset the 
  // image twice because of clipmasks for example...
  XGCValues values;
  unsigned long valuemask = 0;
  GC localGC = XCreateGC(xpc->display(), xpc->drawWindow(),
			 valuemask, &values);
  valuemask = GCFunction | GCPlaneMask | GCForeground | GCBackground | 
    GCLineWidth | GCLineStyle | GCCapStyle | GCJoinStyle | 
    GCFillStyle | GCFillRule | GCArcMode | GCTile |
    GCStipple | GCTileStipXOrigin | GCTileStipYOrigin | GCFont | 
    GCSubwindowMode | GCGraphicsExposures | GCDashOffset | GCDashList;
  XCopyGC(xpc->display(), xpc->gc(), valuemask, localGC);
  
  if (xpc->drawMode() == Display::Compile) {
    if (xpc->usePixmapImages()) {
      // create pixmap
      Pixmap pm = XCreatePixmap(xpc->display(), xpc->drawWindow(), 
				ximXSize, ximYSize, xpc->depth());
      // paint the image onto the pixmap
      XPutImage(xpc->display(), pm, localGC, xim, 0, 0,
		0,0, ximXSize, ximYSize);

      Pixmap pmask = XCreatePixmap(xpc->display(), xpc->drawWindow(),
				   ximXSize, ximYSize, 1);

      GC tGC = XCreateGC(xpc->display(), pmask, 0, 0);
      XPutImage(xpc->display(), pmask, tGC, xmask, 0, 0, 0, 0, 
		ximXSize, ximYSize);

      // append the pixmap onto the display
      //xpc->appendToDisplayList(new X11PCDLPixmap(xpc->display(), pm,
      xpc->appendToDisplayList(new X11PCDLMaskedPixmap(xpc->display(), pm, pmask,
						 ximXSize, ximYSize,
						 outputXoffset,
						 xpc->height() - ximYSize - 
						 outputYoffset));  
      // Destroy the XImage
      delete [] ximData;
      xim->data = 0;
      XDestroyImage(xim);
      delete [] xmask->data;
      xmask->data = 0;
      XDestroyImage(xmask);
    } else {
      xpc->appendToDisplayList(new X11PCDLImage(xim, outputXoffset,
						xpc->height() - ximYSize - 
						outputYoffset));
    }    
  } else {    
    if (xpc->drawToPixmap()) {
      // new pixmap for masked area
      Pixmap pmask = XCreatePixmap(xpc->display(), xpc->pixmap(),
				   xpc->width(),xpc->height(), 1);
      GC tGC = XCreateGC(xpc->display(), pmask, 0, 0);
      // insert mask into pixmap
      XPutImage(xpc->display(), pmask, tGC, xmask, 0, 0,
		outputXoffset + xpc->xTranslation(), 
		xpc->height() - ximYSize - outputYoffset - xpc->yTranslation(),
		ximXSize, ximYSize);
      // setup region to mask
      XSetClipOrigin(xpc->display(), localGC, 0, 0);
      XSetClipMask(xpc->display(), localGC, pmask);
      // insert (unmasked) image
      XPutImage(xpc->display(), xpc->pixmap(), localGC, xim, 0, 0,
		outputXoffset + xpc->xTranslation(), 
		xpc->height() - ximYSize - outputYoffset - 
		xpc->yTranslation(), 
		ximXSize, ximYSize);
      // unset masking
      XSetClipMask(xpc->display(), localGC, None);
      // free the mask
      XFreePixmap(xpc->display(),pmask);

    }
    if (xpc->drawToWindow()) {
      // fix this to draw mask - so far I can't see this case being
      // invoked anywhere
      XPutImage(xpc->display(), xpc->drawWindow(), localGC, xim, 0, 0, 
		outputXoffset + xpc->xTranslation(), 
		xpc->height() - ximYSize - outputYoffset - 
		xpc->yTranslation(), ximXSize, ximYSize);
    }
    delete [] ximData;
    xim->data = 0;
    XDestroyImage(xim);
    delete [] xmask->data;
    xmask->data = 0;
    XDestroyImage(xmask);
  }
  XFreeGC(xpc->display(), localGC);
}


} //# NAMESPACE CASA - END

