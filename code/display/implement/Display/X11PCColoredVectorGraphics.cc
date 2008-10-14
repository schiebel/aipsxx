//# X11PCColoredVectorGraphics.cc: per-element colored lines and points
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000,2001
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
//# $Id: X11PCColoredVectorGraphics.cc,v 19.4 2005/06/15 17:56:37 cvsmgr Exp $

//  These functions handle per-element color when it is passed as a parameter.
//  
//  The fastest performance will be obtained when vectors are grouped
//  according to similar color in their array

#include <display/Display/X11PixelCanvas.h>
#include <display/Display/X11PCLimits.h>
#include <display/Display/X11PCDLColoredPoints.h>
#include <display/Display/X11PCDLColoredLines.h>
namespace casa { //# NAMESPACE CASA - BEGIN

//#include <casa/Arrays/ArrayMath.h>

template <class T>
void X11PixelCanvas_drawColoredPoints(X11PixelCanvas * xpc,
			       const Vector<T> & x1,
			       const Vector<T> & y1,
			       const Vector<uInt> & colors)
{
  uInt nPoints = x1.nelements();

  Short xt = xpc->xTranslation();
  Short yt = xpc->height() - 1 - xpc->yTranslation();

  if (xpc->drawMode() == Display::Draw)
    {
      if (xpc->drawToPixmap())
	for (uInt i = 0; i < nPoints; i++)
	  {
	    XSetForeground(xpc->display(), xpc->gc(), uLong(colors(i)));
	    XDrawPoint(xpc->display(), xpc->pixmap(), xpc->gc(), 
		       Short(x1(i)+T(0.5)) + xt, yt - Short(y1(i)+T(0.5)));
	  }
      if (xpc->drawToWindow())
	for (uInt i = 0; i < nPoints; i++)
	  {
	    XSetForeground(xpc->display(), xpc->gc(), uLong(colors(i)));
	    XDrawPoint(xpc->display(), xpc->drawWindow(), xpc->gc(), 
		       Short(x1(i)+T(0.5)) + xt, yt - Short(y1(i)+T(0.5)));
	  }
    }
  else
    {
      Vector<Short> sx1(nPoints);
      Vector<Short> sy1(nPoints);

      //convertArray(sx1, x1);
      for (uInt i = 0; i < nPoints; i++)
	{
	  sx1(i) = Short(x1(i)+T(0.5));
	  sy1(i) = xpc->height() - 1 - Short(y1(i)+T(0.5));
	}
	
      xpc->appendToDisplayList(new X11PCDLColoredPoints(sx1, sy1, colors));
    }
}

template <class T>
void X11PixelCanvas_drawColoredLines(X11PixelCanvas * xpc,
				     const Vector<T> & x1,
				     const Vector<T> & y1,
				     const Vector<T> & x2,
				     const Vector<T> & y2,
				     const Vector<uInt> & colors)
{
  uInt nLines = x1.nelements();
  Short xt = xpc->xTranslation();
  Short yt = xpc->height() - 1 - xpc->yTranslation();

  if (xpc->drawMode() == Display::Draw)
    {
      if (xpc->drawToPixmap())
	for (uInt i = 0; i < nLines; i++)
	  {
	    XSetForeground(xpc->display(), xpc->gc(), uLong(colors(i)));
	    XDrawLine(xpc->display(), xpc->pixmap(), xpc->gc(), 
		      Short(x1(i)+T(0.5)) + xt, yt - Short(y1(i)+T(0.5)),
		      Short(x2(i)+T(0.5)) + xt, yt - Short(y2(i)+T(0.5)));
	  }
      if (xpc->drawToWindow())
	for (uInt i = 0; i < nLines; i++)
	  {
	    XSetForeground(xpc->display(), xpc->gc(), uLong(colors(i)));
	    XDrawLine(xpc->display(), xpc->drawWindow(), xpc->gc(), 
		      Short(x1(i)+T(0.5)) + xt, yt - Short(y1(i)+T(0.5)),
		      Short(x2(i)+T(0.5)) + xt, yt - Short(y2(i)+T(0.5)));
	  }
    }
  else
    {
      Vector<Short> sx1(nLines);
      Vector<Short> sy1(nLines);
      Vector<Short> sx2(nLines);
      Vector<Short> sy2(nLines);

      //convertArray(sx1, x1);
      //convertArray(sx2, x2);
      for (uInt i = 0; i < nLines; i++)
	{
	  sx1(i) = Short(x1(i)+T(0.5));
	  sx2(i) = Short(x2(i)+T(0.5));
	  sy1(i) = xpc->height() - 1 - Short(y1(i)+T(0.5));
	  sy2(i) = xpc->height() - 1 - Short(y2(i)+T(0.5));
	}

      xpc->appendToDisplayList(new X11PCDLColoredLines(sx1,sy1,sx2,sy2,colors));
    }
}



#if 0

// drawColoredPoints optimization?
Short * p = (Short *) xpc->requestBuffer();
uInt nDone = 0;

// want to combine calls with same color
// So we build an array and flush it when it gets too full or
// when the color changes.

uInt ccolor = colors(0);
uInt ncolor = colors(0);

XSetForeground(xpc->display(), xpc->gc(), uLong(ccolor));
uInt buflen = 0;
while (nDone < nPoints)
{
  *p++ = Short(x1(nDone)+T(0.5));
  *p++ = xpc->height() - 1 - Short(y1(nDone)+T(0.5));
  
  ncolor = colors(nDone);
  
  nDone++;
  buflen++;
  
  if ((buflen >= X11Limits::MaximumPointCount) || (ncolor != ccolor))
    {
      if (buflen == 1) 
	XDrawPoint(xpc->display(), xpc->pixmap(), xpc->gc(), *p, *(p+1));
      else
	XDrawPoints(xpc->display(), xpc->pixmap(), xpc->gc(),
		    (XPoint *) xpc->requestBuffer(), buflen, CoordModeOrigin);
      if (ncolor != ccolor) 
	{
	  ccolor = ncolor;
	  XSetForeground(xpc->display(), xpc->gc(), uLong(ccolor));
	}
      p = (Short *) xpc->requestBuffer();
      buflen = 0;
    }
}

if (buflen)
{
  if (buflen == 2) 
    XDrawPoint(xpc->display(), xpc->pixmap(), xpc->gc(), *p, *(p+1));
  else
    XDrawPoints(xpc->display(), xpc->pixmap(), xpc->gc(),
		(XPoint *) xpc->requestBuffer(), buflen, CoordModeOrigin);
}


// drawLines optimization?

  Short * p = (Short *) xpc->requestBuffer();
  uInt nDone = 0;

  // want to combine calls with same color
  // So we build an array and flush it when it gets too full or
  // when the color changes.

  uInt ccolor = colors(0);
  uInt ncolor = colors(0);

  XSetForeground(xpc->display(), xpc->gc(), uLong(ccolor));
  uInt buflen = 0;
  while (nDone < nPoints)
    {
      *p++ = Short(x1(nDone)+T(0.5));
      *p++ = xpc->height() - 1 - Short(y1(nDone)+T(0.5));
      *p++ = Short(x2(nDone)+T(0.5));
      *p++ = xpc->height() - 1 - Short(y2(nDone)+T(0.5));

      ncolor = colors(nDone);

      nDone++;
      buflen++;
      
      if ((buflen > X11Limits::MaximumLineCount) || (ncolor != ccolor))
	{
	  if (buflen == 1) 
	    XDrawPoint(xpc->display(), xpc->pixmap(), xpc->gc(), *p, *(p+1));
	  else
	    XDrawPoints(xpc->display(), xpc->pixmap(), xpc->gc(),
			(XPoint *) xpc->requestBuffer(), buflen, CoordModeOrigin);
	  if (ncolor != ccolor) 
	    {
	      ccolor = ncolor;
	      XSetForeground(xpc->display(), xpc->gc(), uLong(ccolor));
	    }
	  p = (Short *) xpc->requestBuffer();
	  buflen = 0;
	}
    }

  if (buflen)
    {
      if (buflen == 1) 
	XDrawPoint(xpc->display(), xpc->pixmap(), xpc->gc(), *p, *(p+1));
      else
	XDrawPoints(xpc->display(), xpc->pixmap(), xpc->gc(),
		    (XPoint *) xpc->requestBuffer(), buflen, CoordModeOrigin);
    }

#endif

} //# NAMESPACE CASA - END

