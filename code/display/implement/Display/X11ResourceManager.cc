//# X11ResourceManager.cc: management of shared X11 resources
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000
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
//# $Id: X11ResourceManager.cc,v 19.3 2005/06/15 17:56:44 cvsmgr Exp $

#include <display/Display/X11ResourceManager.h>
#include <display/Display/X11PixelCanvasColorTable.h>

namespace casa { //# NAMESPACE CASA - BEGIN

List <XColormap> X11ResourceManager::cmapList_;
List <uInt> X11ResourceManager::refCountList_;
List <void *> X11ResourceManager::displayList_;

List <void *> X11ResourceManager::pcctblList_;
ListIter <void *> X11ResourceManager::itp_(&pcctblList_);

void X11ResourceManager::refColormap(Screen * screen, XColormap id)
{
  if (id == DefaultColormapOfScreen(screen)) return;

  Bool done = False;
  ListIter<XColormap> it(&cmapList_);
  ListIter<uInt> itr(&refCountList_);
  ListIter<void *> itd(&displayList_);

  void * display = (void *) DisplayOfScreen(screen);

  while(!it.atEnd())
    {
      if (it.getRight() == id && itd.getRight() == display)
	{
	  itr.getRight() = itr.getRight() + 1;

	  done = True;
	  break;
	}
      it++;
      itr++;
      itd++;
    }

  if (!done)
    {
      it.addRight(id);
      itr.addRight(1);
      itd.addRight(display);
    }

}

void X11ResourceManager::unrefColormap(Screen * screen, XColormap id)
{
  if (id == DefaultColormapOfScreen(screen)) return;

  ListIter<XColormap> it(&cmapList_);
  ListIter<uInt> itr(&refCountList_);
  ListIter<void *> itd(&displayList_);

  void * display = (void *) DisplayOfScreen(screen);

  while(!it.atEnd())
    {
      if (it.getRight() == id && itd.getRight() == display)
	{
	  uInt ref = itr.getRight();
	  if (ref == 1)
	    {
	      XFreeColormap((::XDisplay *) display, it.getRight());
	      it.removeRight();
	      itr.removeRight();
	      itd.removeRight();
	    }
	  else
	    {
	      itr.getRight() = itr.getRight() - 1;
	    }
	  break;
	}
      it++;
      itr++;
      itd++;
    }
}

void X11ResourceManager::addX11PixelCanvasColormap(X11PixelCanvasColorTable * pccm)
{
  Bool done = False;
  itp_.toStart();
  while (!itp_.atEnd())
    {
      if (itp_.getRight() == (void *) pccm) { done = True; break; }
      itp_++;
    }
  if (!done) itp_.addRight((void *) pccm);
}

void X11ResourceManager::removeX11PixelCanvasColormap(X11PixelCanvasColorTable * pccm)
{
  itp_.toStart();
  while (!itp_.atEnd())
    {
      if (itp_.getRight() == (void *) pccm) { itp_.removeRight(); break; }
      itp_++;
    }
}

uLong X11ResourceManager::allocColor(X11PixelCanvasColorTable * pccm,
				     uShort r, uShort g, uShort b)
{
  // If XAllocColor succeeds, we're done
  XColor c;
  c.flags = DoRed | DoGreen | DoBlue;
  c.red = r;
  c.green = g;
  c.blue = b;

  Bool ok = False;

  while (!ok)
    {
      if (XAllocColor(pccm->display(), pccm->xcmap(), &c))
	{
	  ok = True;
	}
      else
	{
	  // Here we must either resize a pccm or return an
	  // index to the closest number.
#if 1 

	  // Resizing strategy...
	  XColormap cmap = pccm->xcmap();

	  uInt count = 0;

	  // Add up number of registered pccm's on this colormap
	  ConstListIter<void *> itp2(&pcctblList_);
	  while (!itp2.atEnd())
	    {
	      X11PixelCanvasColorTable * p = (X11PixelCanvasColorTable *) itp2.getRight();
	      if (p->xcmap() == cmap && !p->rigid())
		count++;
	      itp2++;
	    }

	  if (count == 0)
	    {
	      // can't do a resize, search for best color and return;
	      return X11ResourceManager::bestColorMatch(pccm,r,g,b);
	    }

	  // count >= 1
	  if (itp_.atEnd()) itp_.toStart(); else itp_++;
	  while (1)
	    {
	      X11PixelCanvasColorTable * p = (X11PixelCanvasColorTable *) itp_.getRight();
	      if (p->xcmap() == cmap && !p->rigid()) 
		break;
	      if (itp_.atEnd()) itp_.toStart(); else itp_++;
	    }
	      
	  // now iterator points to pcctbl to resize
	  X11PixelCanvasColorTable * pToResize = (X11PixelCanvasColorTable *) itp_.getRight();
	  pToResize->resize(pToResize->nColors() - 1);


#else
	  // Just pick best of what is available

	  return X11ResourceManager::bestColorMatch(r,g,b);
#endif
	}
    }

  return c.pixel;
}


Bool X11ResourceManager::errFlag_;
int (*X11ResourceManager::prevHandler_)(::XDisplay * display, XErrorEvent * ev);

int X11ResourceManager::getROCCErrorHandler(::XDisplay * display, XErrorEvent * ev)
{
  if (ev->error_code == BadAccess)
    {
      // This was expected
      errFlag_ = True;
      return 1;
    }
  else
    {
      // This was not, forward to previous error handler
      return prevHandler_(display, ev);
    }
}

Bool X11ResourceManager::getReadOnlyColorCells(Vector<Bool>,
					       ::XDisplay *,
					       XColormap )
{
  return False;
}

// The man pages of XStoreColor says that if you try to store a color in 
// a cell that is unallocated or read-only, it will cause a BadAccess
// error.  This function allocates the rest of the map temporarily to
// remove the possibility of the first case.  It then installs an
// error handler which sets a static flag when a BadAccess error happens
// Using XStoreColors.  The only other XFunction that is called when the
// error handler is in place is XQueryColor(), which does not generate
// a BadAccess error.
//
// For each cell in the map, this function copies the error flag into
// the mask.  The result is an instantaneous map of cells that are
// read-only.  The mask MUST be set to the appropriate length.  If it
// is too big, an X server error will likely be generated.
//
Bool X11ResourceManager::getReadOnlyColorCells(uChar * mask, uInt len, ::XDisplay * display, 
					       XColormap colormap)
{
  //
  //  First thing we have to do is allocate the remaining cells in the map
  //
  uLong * colors = NULL;
  uInt nFreeColors = 0;
  
  Bool ok = False;
  while (!ok)
    {
      nFreeColors = X11QueryColorsAvailable(display, colormap, False);

      // No free colors, nothing to do
      if (nFreeColors == 0) { ok = True; break; }
      
      uLong planeMask[1];
      colors = new uLong[nFreeColors];
      if (XAllocColorCells(display, colormap, 0, 
			   planeMask, 0, colors, nFreeColors) > 0) 
	ok = True;
      else
	{ delete [] colors; colors = NULL; }
    }

  // Install an error handler so we can get away with bad calls to XStoreColor
  prevHandler_ = XSetErrorHandler(X11ResourceManager::getROCCErrorHandler);

  // Test the cells one by one.  This can be done without changing the
  // colors on the screen.
  XColor c;
  for (uInt j = 0; j < len; j++)
    {
      c.pixel = j;
      XQueryColor(display, colormap, &c);
      errFlag_ = False;
      XStoreColor(display, colormap, &c);
      mask[j] = (errFlag_ == True) ? 1 : 0;
    }

  // Put the old handler back
  XSetErrorHandler(prevHandler_);

  // Free the colors we allocated if any along with its pixel memory
  if (colors)
    {
      XFreeColors(display, colormap, colors, nFreeColors, 0);
      delete [] colors;
    }

  return True;
}


// Improve this to ignore R/W cells if needed
uLong X11ResourceManager::bestColorMatch(X11PixelCanvasColorTable * pcctbl, 
					 uShort r, uShort g, uShort b)
{
  // Get a mask describing which cells are readonly
  uInt maplen = CellsOfScreen(pcctbl->screen());
  Vector<Bool> mapMask(maplen, False);
  X11ResourceManager::getReadOnlyColorCells(mapMask, pcctbl->display(), pcctbl->xcmap());
  
  // Find the closest pixel in RGB space
  double mind = (r*r + g*g + b*b);
  uLong pixel = BlackPixelOfScreen(pcctbl->screen());
  XColor c;
  c.flags = DoRed | DoGreen | DoBlue;
  for (uInt i = 0; i < maplen; i++)
    {
      if (mapMask(i) == False) continue;
      c.pixel = i;
      XQueryColor(pcctbl->display(), pcctbl->xcmap(), &c);
      double d = (r - c.red)*(r - c.red) + (g - c.green)*(g - c.green) + (b - c.blue)*(b - c.blue);
      if (d < mind)
	{
	  pixel = c.pixel;
	  mind = d;
	}
    }

  // Return the best match.
  return pixel;
}

ostream & operator << (ostream & os, const X11ResourceManager & xrm)
{
  os << "-------------- X11ResourceManager ------------------\n";
  
  ListIter<XColormap> it(&xrm.cmapList_);
  ListIter<uInt> itr(&xrm.refCountList_);
  ListIter<void *> itd(&xrm.displayList_);
  
  while (!it.atEnd())
    {
      os << "X XColormap <id = " << it.getRight() << ", display = " << itd.getRight() << "> : " 
	 << itr.getRight() << " refs\n";
      it++; itd++; itr++;
    }
  
  xrm.itp_.toStart();
  while (!xrm.itp_.atEnd())
    {
      X11PixelCanvasColorTable * pccm = (X11PixelCanvasColorTable *) xrm.itp_.getRight();
      os << "PixelCanvasColorTable <id = " << (void *) pccm << ", X XColormap = " 
	 << pccm->xcmap() << ".\n";
      xrm.itp_++;
    }

  os << "-------------------- END ---------------------------\n";
  return os;
}



} //# NAMESPACE CASA - END

