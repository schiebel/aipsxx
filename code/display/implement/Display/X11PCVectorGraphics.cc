//# X11PCVectorGraphics.cc: templates for monochrome vector graphics in X
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
//# $Id: X11PCVectorGraphics.cc,v 19.4 2005/06/15 17:56:44 cvsmgr Exp $

//  Had to move templated functions out because AIPS++ instantiation mechanism
//  instantiates the whole file rather than just the template function defined.

#include <display/Display/X11PCLimits.h>
#include <display/Display/X11PixelCanvas.h>
#include <display/Display/X11PCDLPoints.h>
#include <display/Display/X11PCDLLines.h>
#include <display/Display/X11PCDLPolyline.h>
#include <display/Display/X11PCDLFilledPolygon.h>
#include <display/Display/X11PCDLFilledRectangle.h>
#include <casa/Arrays/Vector.h>

namespace casa { //# NAMESPACE CASA - BEGIN

template <class T>
void X11PixelCanvas_drawPoints(X11PixelCanvas * xpc, 
			       const Vector<T> & x1,
			       const Vector<T> & y1) 
{
  uInt nPoints = x1.nelements();
  Short* base = 0;
  Short* p = 0;

  if (xpc->drawMode() == Display::Draw)
    {
      Short xt = xpc->xTranslation();
      Short yt = xpc->height() - 1 - xpc->yTranslation();

      uInt count = 0;
      uInt nDone = 0;
      uInt len = X11Limits::MaximumPointCount;

      while (nDone < nPoints)
	{
	  if (nPoints - nDone < X11Limits::MaximumPointCount) 
	    len = nPoints - nDone;

	  p = (Short *) xpc->requestBuffer();
	  
	  for (uInt i = 0; i < len; i++, count++)
	    {
	      *p++ = Short(x1(count)+T(0.5)) + xt;
	      *p++ = yt - Short(y1(count)+T(0.5));
	    }

	  if (xpc->drawToPixmap())
	    XDrawPoints(xpc->display(), xpc->pixmap(), xpc->gc(), 
			(XPoint *) xpc->requestBuffer(), len, CoordModeOrigin);
	  if (xpc->drawToWindow())
	    XDrawPoints(xpc->display(), xpc->drawWindow(), xpc->gc(), 
			(XPoint *) xpc->requestBuffer(), len, CoordModeOrigin);
	  nDone += len;
	}
    }
  else
    {
      base = new Short[nPoints*2];
      p = base;

      for (uInt i = 0; i < nPoints; i++)
	{
	  *p++ = Short(x1(i)+T(0.5));
	  *p++ = xpc->height() - 1 - Short(y1(i)+T(0.5));
	}
      xpc->appendToDisplayList(new X11PCDLPoints((XPoint *) base, 
						 nPoints,
						 CoordModeOrigin));
    }
}

template <class T>
void X11PixelCanvas_drawPoints(X11PixelCanvas * xpc, const Matrix<T> & verts)
{
  uInt nPoints = verts.nrow();
  Short* base = 0;
  Short* p = 0;

  if (xpc->drawMode() == Display::Draw)
    {
      Short xt = xpc->xTranslation();
      Short yt = xpc->height() - 1 - xpc->yTranslation();

      uInt count = 0;
      uInt nDone = 0;
      uInt len = X11Limits::MaximumPointCount;

      while (nDone < nPoints)
	{
	  if (nPoints - nDone < X11Limits::MaximumPointCount) 
	    len = nPoints - nDone;

	  p = (Short *) xpc->requestBuffer();
	  
	  for (uInt i = 0; i < len; i++, count++)
	    {
	      *p++ = Short(verts(count,0)+T(0.5)) + xt;
	      *p++ = yt - Short(verts(count,1)+T(0.5));
	    }

	  if (xpc->drawToPixmap())
	    XDrawPoints(xpc->display(), xpc->pixmap(), xpc->gc(), 
			(XPoint *) xpc->requestBuffer(), len, CoordModeOrigin);
	  if (xpc->drawToWindow())
	    XDrawPoints(xpc->display(), xpc->drawWindow(), xpc->gc(), 
			(XPoint *) xpc->requestBuffer(), len, CoordModeOrigin);
	  nDone += len;
	}
    }
  else
    {
      base = new Short[nPoints*2];
      p = base;

      for (uInt i = 0; i < nPoints; i++)
	{
	  *p++ = Short(verts(i,0)+T(0.5));
	  *p++ = xpc->height() - 1 - Short(verts(i,1)+T(0.5));
	}
      xpc->appendToDisplayList(new X11PCDLPoints((XPoint *) base, 
						 nPoints,
						 CoordModeOrigin));
    }
}

template <class T>
void X11PixelCanvas_drawLines(X11PixelCanvas * xpc, 
			      const Vector<T> & x1,
			      const Vector<T> & y1,
			      const Vector<T> & x2,
			      const Vector<T> & y2)
{
  // store in buffer sequentially for call to XDrawLines,
  // iterate as needed

  uInt nLines = x1.nelements();
  Short* base = 0;
  Short* p = 0;

  if (xpc->drawMode() == Display::Draw)
    {
      Short xt = xpc->xTranslation();
      Short yt = xpc->height() - 1 - xpc->yTranslation();

      uInt count = 0;
      uInt nDone = 0;
      uInt len = X11Limits::MaximumLineCount;

      while (nDone < nLines)
	{
	  if (nLines - nDone < X11Limits::MaximumLineCount) len = (nLines - nDone);
	  
	  base = (Short *) xpc->requestBuffer();
	  p = base;

	  for (uInt i = 0; i < len; i++, count++)
	    {
	      *p++ = Short(x1(count)+T(0.5)) + xt;
	      *p++ = yt - Short(y1(count)+T(0.5));
	      *p++ = Short(x2(count)+T(0.5)) + xt;
	      *p++ = yt - Short(y2(count)+T(0.5));
	    }

	  if (xpc->drawToPixmap())
	    XDrawSegments(xpc->display(), xpc->pixmap(), 
			  xpc->gc(), (XSegment *) xpc->requestBuffer(), len);
	  if (xpc->drawToWindow())
	    XDrawSegments(xpc->display(), xpc->drawWindow(), 
			  xpc->gc(), (XSegment *) xpc->requestBuffer(), len);
	  nDone += len;
	}
    }
  else
    {
      base = new Short[nLines*4];
      p = base;
      
      for (uInt i = 0; i < nLines; i++)
	{
	  *p++ = Short(x1(i)+T(0.5));
	  *p++ = xpc->height() - 1 - Short(y1(i)+T(0.5));
	  *p++ = Short(x2(i)+T(0.5));
	  *p++ = xpc->height() - 1 - Short(y2(i)+T(0.5));
	}
      xpc->appendToDisplayList(new X11PCDLLines((XSegment *) base, nLines));
    }
}

template <class T>
void X11PixelCanvas_drawLines(X11PixelCanvas * xpc, 
			      const Matrix<T> & verts)
{
  // store in buffer sequentially for call to XDrawLines,
  // iterate as needed

  uInt nVerts = verts.nrow();
  uInt nLines = nVerts/2;
  Short* base = 0;
  Short* p = 0;

  if (xpc->drawMode() == Display::Draw)
    {
      Short xt = xpc->xTranslation();
      Short yt = xpc->height() - 1 - xpc->yTranslation();

      uInt nDone = 0;
      uInt len = X11Limits::MaximumLineCount;

      uInt vCount = 0;

      while (nDone < nLines)
	{
	  if (nLines - nDone < X11Limits::MaximumLineCount) len = (nLines - nDone);
	  
	  base = (Short *) xpc->requestBuffer();
	  p = base;

	  for (uInt i = 0; i < len; i++)
	    {
	      *p++ = Short(verts(vCount,0)+T(0.5)) + xt;
	      *p++ = yt - Short(verts(vCount,1)+T(0.5));
	      vCount++;
	      *p++ = Short(verts(vCount,0)+T(0.5) + xt);
	      *p++ = yt - Short(verts(vCount,1)+T(0.5));
	      vCount++;
	    }

	  if (xpc->drawToPixmap())
	    XDrawSegments(xpc->display(), xpc->pixmap(), 
			  xpc->gc(), (XSegment *) xpc->requestBuffer(), len);
	  if (xpc->drawToWindow())
	    XDrawSegments(xpc->display(), xpc->drawWindow(), 
			  xpc->gc(), (XSegment *) xpc->requestBuffer(), len);
	  nDone += len;
	}
    }
  else
    {
      base = new Short[nLines*4];
      p = base;
      
      for (uInt i = 0; i < nVerts; i++)
	{
	  *p++ = Short(verts(i,0)+T(0.5));
	  *p++ = xpc->height() - 1 - Short(verts(i,1)+T(0.5));
	}
      xpc->appendToDisplayList(new X11PCDLLines((XSegment *) base, nLines));
    }
}

template <class T>
void X11PixelCanvas_drawPolyline(X11PixelCanvas * xpc,
				 const Vector<T> & x1,
				 const Vector<T> & y1)
{
  uInt nVertices = x1.nelements();

  Short* base = 0;
  Short* p = 0;

  if (xpc->drawMode() == Display::Draw)
    {
      Short xt = xpc->xTranslation();
      Short yt = xpc->height() - 1 - xpc->yTranslation();

      uInt count = 0;
      uInt nDone = 0;
      uInt len = X11Limits::MaximumPointCount;
      
      while (nDone < nVertices)
	{
	  if (nVertices - nDone < X11Limits::MaximumPointCount) len = (nVertices - nDone);
	  
	  p = (Short *) xpc->requestBuffer();
	  
	  for (uInt i = 0; i < len; i++, count++)
	    {
	      *p++ = Short(x1(count)+T(0.5)) + xt;
	      *p++ = yt - Short(y1(count)+T(0.5));
	    }

	  if (xpc->drawToPixmap())
	    XDrawLines(xpc->display(), xpc->pixmap(), xpc->gc(), 
		       (XPoint *) xpc->requestBuffer(), len, CoordModeOrigin);
	  if (xpc->drawToWindow())
	    XDrawLines(xpc->display(), xpc->drawWindow(), xpc->gc(), 
		       (XPoint *) xpc->requestBuffer(), len, CoordModeOrigin);
	  nDone += len;

	  // now correct to allow joining of lines across batch boundaries
	  if (nDone != nVertices) { nDone--; count--; }
	}
    }
  else
    {
      base = new Short[nVertices*4];
      p = base;

      for (uInt i = 0; i < nVertices; i++)
	{
	  *p++ = Short(x1(i)+T(0.5));
	  *p++ = xpc->height() - 1 - Short(y1(i)+T(0.5));
	}
      
      xpc->appendToDisplayList(new X11PCDLPolyline((XPoint *) base,
						   nVertices));
    }
}

template <class T>
void X11PixelCanvas_drawPolyline(X11PixelCanvas * xpc, const Matrix<T> & verts)
{
  uInt nVertices = verts.nrow();

  Short* base = 0;
  Short* p = 0;

  if (xpc->drawMode() == Display::Draw)
    {
      Short xt = xpc->xTranslation();
      Short yt = xpc->height() - 1 - xpc->yTranslation();

      uInt count = 0;
      uInt nDone = 0;
      uInt len = X11Limits::MaximumPointCount;
      
      while (nDone < nVertices)
	{
	  if (nVertices - nDone < X11Limits::MaximumPointCount) len = (nVertices - nDone);
	  
	  p = (Short *) xpc->requestBuffer();
	  
	  for (uInt i = 0; i < len; i++, count++)
	    {
	      *p++ = Short(verts(count,0)+T(0.5)) + xt;
	      *p++ = yt - Short(verts(count,1)+T(0.5));
	    }

	  if (xpc->drawToPixmap())
	    XDrawLines(xpc->display(), xpc->pixmap(), xpc->gc(), 
		       (XPoint *) xpc->requestBuffer(), len, CoordModeOrigin);
	  if (xpc->drawToWindow())
	    XDrawLines(xpc->display(), xpc->drawWindow(), xpc->gc(), 
		       (XPoint *) xpc->requestBuffer(), len, CoordModeOrigin);
	  nDone += len;

	  // now correct to allow joining of lines across batch boundaries
	  if (nDone != nVertices) { nDone--; count--; }
	}
    }
  else
    {
      base = new Short[nVertices*4];
      p = base;

      for (uInt i = 0; i < nVertices; i++)
	{
	  *p++ = Short(verts(i,0)+T(0.5));
	  *p++ = xpc->height() - 1 - Short(verts(i,1)+T(0.5));
	}
      
      xpc->appendToDisplayList(new X11PCDLPolyline((XPoint *) base,
						   nVertices));
    }
}

template <class T>
void X11PixelCanvas_drawFilledPolygon(X11PixelCanvas * xpc,
				      const Vector<T> & x1,
				      const Vector<T> & y1)
{
  // not particularly smart code - if we have too many vertices,
  // this will screw up pretty badly at times, but let's just
  // leave it for the moment...
  uInt nVertices = x1.nelements();
  
  Short* base = 0;
  Short* p = 0;
  
  if (xpc->drawMode() == Display::Draw)
    {
      Short xt = xpc->xTranslation();
      Short yt = xpc->height() - 1 - xpc->yTranslation();

      uInt count = 0;
      uInt nDone = 0;
      uInt len = X11Limits::MaximumPointCount;
      
      while (nDone < nVertices)
	{
	  if (nVertices - nDone < X11Limits::MaximumPointCount) len = (nVertices - nDone);
	  
	  p = (Short *) xpc->requestBuffer();
	  
	  for (uInt i = 0; i < len; i++, count++)
	    {
	      *p++ = Short(x1(count)+T(0.5)) + xt;
	      *p++ = yt - Short(y1(count)+T(0.5));
	    }

	  if (xpc->drawToPixmap())
	    XFillPolygon(xpc->display(), xpc->pixmap(), xpc->gc(), 
			 (XPoint *) xpc->requestBuffer(), len, 
			 0, CoordModeOrigin);
	  if (xpc->drawToWindow())
	    XFillPolygon(xpc->display(), xpc->drawWindow(), xpc->gc(), 
			 (XPoint *) xpc->requestBuffer(), len, 
			 0, CoordModeOrigin);
	  nDone += len;

	  // now correct to allow joining of lines across batch boundaries
	  if (nDone != nVertices) { nDone--; count--; }
	}
    }
  else
    {
      base = new Short[nVertices*4];
      p = base;

      for (uInt i = 0; i < nVertices; i++)
	{
	  *p++ = Short(x1(i)+T(0.5));
	  *p++ = xpc->height() - 1 - Short(y1(i)+T(0.5));
	}
      
      xpc->appendToDisplayList(new X11PCDLFilledPolygon((XPoint *) base,
							nVertices));
    }
}

template <class T>
void X11PixelCanvas_drawFilledRectangle(X11PixelCanvas * xpc,
					const T & x1, const T & y1,
					const T & w, const T & h)
{
  uInt uix1 = uInt(x1+T(0.5)), uiy1 = uInt(y1+T(0.5));
  uInt uiw = uInt(w+T(0.5)), uih = uInt(h+T(0.5));
  if (xpc->drawMode() == Display::Draw) {
    Short xt = xpc->xTranslation();
    Short yt = xpc->height() - 1 - xpc->yTranslation();
    if (xpc->drawToPixmap())
      XFillRectangle(xpc->display(), xpc->pixmap(), xpc->gc(),
		     uix1 + xt, yt - uiy1, uiw, uih);
    if (xpc->drawToWindow())
      XFillRectangle(xpc->display(), xpc->drawWindow(), xpc->gc(),
		     uix1 + xt, yt - uiy1, uiw, uih);
  } else {
    xpc->appendToDisplayList(new X11PCDLFilledRectangle
			     (uix1, xpc->height() - 1 - uiy1, uiw, uih));
  }
}



} //# NAMESPACE CASA - END

