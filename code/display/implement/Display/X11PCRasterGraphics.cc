//# X11PCRasterGraphics.cc: raster graphics routines for X11PixelCanvas
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000,2001,2002
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
//# $Id: X11PCRasterGraphics.cc,v 19.4 2005/06/15 17:56:43 cvsmgr Exp $

//  Had to move templated functions out because AIPS++ instantiation mechanism
//  instantiates the whole file rather than just the template function defined.

#include <display/Display/X11PixelCanvas.h>
#include <display/Display/X11PCDLImage.h>
#include <display/Display/X11PCDLPixmap.h>
#include <casa/Arrays/Matrix.h>
#include <casa/iostream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//
// Private templated drawImage was convenient for parameterizing
// the data values that would be supported.  Interface provided
// to all data types.
//
//
//
// drawImage with offset optimized for zoom of 1
template <class T> 
void X11PixelCanvas_drawImage(X11PixelCanvas * xpc,
			      const Matrix<T> & data,
			      Int xoffset, Int yoffset)
{
  // swapped column & row  (TAO)
  uInt nx = data.nrow();
  uInt ny = data.ncolumn();

  uInt ximXSize = nx;
  uInt ximYSize = ny;

  // Compute minimum size of required XImage and build it
  Int rt = (xpc->width() - (xoffset + nx));  if (rt < 0) rt = 0;
  ximXSize = xpc->width() - ((xoffset > 0) ? xoffset : 0) - rt;
  rt = (xpc->height() - (yoffset + ny)); if (rt < 0) rt = 0;
  ximYSize = xpc->height() - ((yoffset > 0) ? yoffset : 0) - rt;
  
  // Image not visible, quit
  if (ximXSize == 0 || ximYSize == 0) return;

  // want smarter allocation, may not need 4x, may need more for
  // machines with more than 8 bits per pixel.
  uLong * ximData = new uLong[ximXSize*ximYSize];
  for (uInt xix = 0; xix < ximXSize * ximYSize; xix++) {
    ximData[xix] = uLong(0);
  }
  XImage *xim = XCreateImage(xpc->display(),
			     xpc->visual(),
			     xpc->depth(),
			     ZPixmap,
			     0,
			     (char *) ximData,
			     ximXSize,
			     ximYSize,
			     BitmapPad(xpc->display()),
			     0);

  // Compute dataXIndex, dataYIndex
  uInt dataXIndex = (xoffset < 0) ? -xoffset : 0;
  uInt dataYIndex = (yoffset < 0) ? -yoffset : 0;

  // Fill the XImage with data.  c is cell
  uInt dxc = dataXIndex;
  uInt dyc = dataYIndex;
 
#ifdef PPOPT
  int (*putpixel)(XImage *, int, int, unsigned long) = xim->put_pixel;

} //# NAMESPACE CASA - END

#endif
  for (uInt y = ximYSize; y > 0;)
    {
      y--;
      dxc = dataXIndex;
      for (uInt x = 0; x < ximXSize; x++, dxc++)
	{
#ifdef PPOPT
	  putpixel(xim, x, y, 
		   static_cast<unsigned long>(data(dxc,dyc)+T(0.5)));
#else
	  XPutPixel(xim, x, y,
		    static_cast<unsigned long>(data(dxc,dyc)+T(0.5)));
#endif
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

  if (xpc->drawMode() == Display::Compile)
    {
      if (xpc->usePixmapImages())
	{
	  // create pixmap
	  Pixmap pm = XCreatePixmap(xpc->display(), xpc->drawWindow(), 
				    ximXSize, ximYSize, xpc->depth());

	  // paint the image onto the pixmap
	  XPutImage(xpc->display(), pm, localGC, xim, 0, 0,
		    0,0, ximXSize, ximYSize);

	  // append the pixmap onto the display
	  xpc->appendToDisplayList(new X11PCDLPixmap(xpc->display(), pm,
						     ximXSize,
						     ximYSize,
						     outputXoffset,
						     xpc->height() - ximYSize - outputYoffset));  
	  // Destroy the XImage
	  delete [] ximData;
	  xim->data = 0;
	  XDestroyImage(xim);
	}
      else
	xpc->appendToDisplayList(new X11PCDLImage(xim,
			    outputXoffset,
			    xpc->height() - ximYSize - outputYoffset));
    }
  else
    {
      if (xpc->drawToPixmap())
	XPutImage(xpc->display(), xpc->pixmap(), localGC, xim, 0, 0, 
		  outputXoffset + xpc->xTranslation(), 
		  xpc->height() - ximYSize - outputYoffset - xpc->yTranslation(), 
		  ximXSize, ximYSize);
      if (xpc->drawToWindow())
	XPutImage(xpc->display(), xpc->drawWindow(), localGC, xim, 0, 0, 
		  outputXoffset + xpc->xTranslation(), 
		  xpc->height() - ximYSize - outputYoffset - xpc->yTranslation(), 
		  ximXSize, ximYSize);
  
      delete [] ximData;
      xim->data = 0;
      XDestroyImage(xim);
    }
  XFreeGC(xpc->display(), localGC);
}

// drawImage with offset and zoom support
// again, template class does the work, thin interface to 
// call underlying function for supported types.
//
template <class T>
void X11PixelCanvas_drawImage(X11PixelCanvas * xpc,
			      const Matrix<T> & data,
			      Int xoffset, Int yoffset,
			      uInt xzoom, uInt yzoom)
{
  cout << "X11PixelCanvas_drawImage AA" << endl << flush;

  if (xzoom == 0) xzoom = 1;
  if (yzoom == 0) yzoom = 1;

  uInt nx = data.ncolumn();
  uInt ny = data.nrow();

  if (xzoom == 1 && yzoom == 1)
    {
      X11PixelCanvas_drawImage(xpc, data, xoffset, yoffset);
      return;
    }

  // Compute minimum size of required XImage and build it.  Clipping
  // is done here to maximize the drawing speed of clipped images and
  // to minimize the resource requirements
  int rt = (xpc->width() - (xoffset + xzoom*nx)); if (rt < 0) rt = 0;
  uInt ximXSize = xpc->width() - ((xoffset > 0) ? xoffset : 0) - rt;
  rt = (xpc->height() - (yoffset + yzoom*ny)); if (rt < 0) rt = 0;
  uInt ximYSize = xpc->height() - ((yoffset > 0) ? yoffset : 0) - rt;

  // Image not visible, quit
  if (ximXSize == 0 || ximYSize == 0) return;

  // want smarter allocation, may not need 4x, may need more for
  // machines with more than 8 bits per pixel.  
  uLong * ximData = new uLong[ximXSize*ximYSize];
  XImage * xim = XCreateImage(xpc->display(),
			      xpc->visual(),
			      xpc->depth(),
			      ZPixmap,
			      0,
			      (Char *) ximData,
			      ximXSize,
			      ximYSize,
			      BitmapPad(xpc->display()),
			      0);

  // Compute dataXIndex, dataYIndex
  uInt dataXIndex = (xoffset < 0) ? -xoffset/xzoom : 0;
  uInt dataYIndex = (yoffset < 0) ? -yoffset/yzoom : 0;

  // Compute cell offset
  uInt xCellOffset = (xoffset < 0) ? (-xoffset % xzoom) : 0;
  uInt yCellOffset = (yoffset < 0) ? (-yoffset % yzoom) : 0;

  // Fill the XImage with data.  o is offset, c is cell
  uInt dxo = xCellOffset;
  uInt dxc = dataXIndex;
  uInt dyo = yCellOffset;
  uInt dyc = dataYIndex;
 
  // Optimize this later
  // [ ] store x cell row access pattern
  for (uInt y = ximYSize; y > 0;)
    {
      y--;
      dxc = dataXIndex;
      dxo = xCellOffset;
      for (uInt x = 0; x < ximXSize; x++)
	{
	  XPutPixel(xim, x, y,
		    static_cast<unsigned long>(data(dxc,dyc)+T(0.5)));
	  dxo++; if (dxo == xzoom) { dxo = 0; dxc++; }
	}
      dyo++; if (dyo == yzoom) { dyo = 0; dyc++;}
    }

  // put the image on the display
  uInt outputXoffset = (xoffset > 0) ? xoffset : 0;
  uInt outputYoffset = (yoffset > 0) ? yoffset : 0;
    
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

  if (xpc->drawMode() == Display::Compile)
    {
      if (xpc->usePixmapImages())
	{
	  // create pixmap
	  Pixmap pm = XCreatePixmap(xpc->display(), xpc->drawWindow(), 
				    ximXSize, ximYSize, xpc->depth());

	  // paint the image onto the pixmap
	  XPutImage(xpc->display(), pm, localGC, xim, 0, 0,
		    0, 0, ximXSize, ximYSize);

	  // append the pixmap onto the display
	  xpc->appendToDisplayList(new X11PCDLPixmap(xpc->display(), pm,
						     ximXSize,
						     ximYSize,
						     outputXoffset,
						     xpc->height() - ximYSize - outputYoffset));  
	  // Destroy the XImage
	  delete [] ximData;
	  xim->data = 0;
	  XDestroyImage(xim);
	}
      else
	xpc->appendToDisplayList(new X11PCDLImage(xim,
			    outputXoffset,
			    xpc->height() - ximYSize - outputYoffset));
    }
  else
    {
      if (xpc->drawToPixmap())
	XPutImage(xpc->display(), xpc->pixmap(), localGC, xim, 0, 0,
		  outputXoffset + xpc->xTranslation(),
		  xpc->height() - ximYSize - outputYoffset - xpc->yTranslation(), 
		  ximXSize, ximYSize);
      if (xpc->drawToWindow())
	XPutImage(xpc->display(), xpc->drawWindow(), localGC, xim, 0, 0,
		  outputXoffset + xpc->xTranslation(),
		  xpc->height() - ximYSize - outputYoffset - xpc->yTranslation(), 
		  ximXSize, ximYSize);
      delete [] xim->data;
      xim->data = 0;
      XDestroyImage(xim);
    }
  XFreeGC(xpc->display(), localGC);
}

}
