//# X11ResourceManager.h: management of shared X11 resources
//# Copyright (C) 1993,1994,1995,1996,1999,2000,2001
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
//# $Id: X11ResourceManager.h,v 19.4 2005/06/15 17:56:44 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11RESOURCEMANAGER_H
#define TRIALDISPLAY_X11RESOURCEMANAGER_H



#include <graphics/X11/X_enter.h>
#include <X11/Xlib.h>
#include <graphics/X11/X_exit.h>
#include <casa/aips.h>
#include <casa/Arrays/Vector.h>
#include <casa/Containers/List.h>


//# Forward declarations
#include <casa/iosfwd.h>
namespace casa { //# NAMESPACE CASA - BEGIN

class X11PixelCanvasColorTable;

// <summary>
// Class to manage shared X11 resources among registered clients.
// </summary>
//
// <prerequisite>
// <li> Understanding of <linkto class="X11PixelCanvasColorTable">X11PixelCanvasColorTable</linkto>s
// <li> Understanding of X11 color resources.
// </prerequisite>
//
// <etymology>
// X11ResourceManager : X11 Resource Manager
// </etymology>
//
// <synopsis>
// This class is <em>never</em> directly accessed by application code.  It
// is for internal use only.
//
// X11ResourceManager maintains a list of X virtual colormaps and their reference
// counts.  This ensures that 
// <linkto class="X11PixelCanvasColorTable">X11PixelCanvasColorTable</linkto>s
// that share the same, new, virtual Xcolormap will have the map deleted properly.
//
// Responsibility for allocating read-only colorcells falls on the shoulders of
// this class as well.  This class has the ability to reduce allocation of a
// <linkto class="X11PixelCanvasColorTable">X11PixelCanvasColorTable</linkto>
// to satisfy a request for a read-only colorcell.
//
// Display classes call refColormap() and unrefColormap() when appropriate to manage
// the shared resources.
// </synopsis>
//
// <motivation>
// Needed a way to implement sharing of virtual colormaps by independent X11PixelCanvasColorTables
// and maintain minimum X resource allocation.
// Wanted a way to allow pixelCanvas A to be resized to satisfy a color allocation request for
// pixelCanvas B.
// </motivation>
//


class X11ResourceManager
{
public:

  // Make a reference to an X virtual colormap.  This is necessary
  // to allow multiple X11PixelCanvasColorTables to share a single
  // X virtual hardware colormap.
  // <group>
  static void refColormap(Screen * screen, XColormap id);
  static void unrefColormap(Screen * screen, XColormap id);
  // </group>

  // This is unused at the moment, but may be used to 
  // give allocColor the ability to adjust its colortables...
  // <group>
  static void addX11PixelCanvasColormap(X11PixelCanvasColorTable * pccm);
  static void removeX11PixelCanvasColormap(X11PixelCanvasColorTable * pccm);
  // </group>

  // Allocate a (possibly read-only color)
  static uLong allocColor(X11PixelCanvasColorTable * pccm, 
			  uShort r, uShort g, uShort b);

  // Return a Bool vector that describes which cells are
  // read-only
  static Bool getReadOnlyColorCells(Vector<Bool> mask,
				    ::XDisplay * display,
				    XColormap colormap);

  // Return a char vector that describes which cells are
  // read-only
  static Bool getReadOnlyColorCells(uChar * mask, uInt n,
				    ::XDisplay * display,
				    XColormap colormap);

  // Return the index that best matches the specified r,g,b
  // color.  Used to map r,g,b to colorindex when needed.
  static uLong bestColorMatch(X11PixelCanvasColorTable * pcctbl,
			      uShort r, uShort g, uShort b);

  // print to the stream
  friend ostream & operator << (ostream & os, const X11ResourceManager & xrm);
  
private:

  // error handler for read-only colorcell determination
  static int getROCCErrorHandler(::XDisplay * display, XErrorEvent * ev);

  // list of registered colormaps, their count, and the display they're
  // associated with.
  // <group>
  static List <XColormap> cmapList_;
  static List <uInt> refCountList_;
  static List <void *> displayList_;
  // </group>

  // list of the registered 
  // <linkto class="X11PixelCanvasColorTable">X11PixelCanvasColorTable</linkto>
  static List <void *> pcctblList_;
  // iterator for the above list
  static ListIter <void *> itp_;

  // These two functions are involved in a test to see if a particular
  // cell is read-only
  // <group>
  static Bool errFlag_;
  static int (*prevHandler_)(::XDisplay * display, XErrorEvent * ev);
  // </group>
};


} //# NAMESPACE CASA - END

#endif
