//# X11PCDisplayListObject.h: base class for X-based display list caching
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
//# $Id: X11PCDisplayListObject.h,v 19.4 2004/12/23 07:53:56 gvandiep Exp $

#ifndef DISPLAY_X11PCDISPLAYLISTOBJECT_H
#define DISPLAY_X11PCDISPLAYLISTOBJECT_H

#include <casa/aips.h>
#include <graphics/X11/X_enter.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <graphics/X11/X_exit.h>


namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Base class for caching of X11 device (ie. X11PixelCanvas) display lists.
// </summary>

// <use visibility=local>

// <reviewed reviewer="Bob Garwood" date="2000/02/01" test="" demos="">
// </reviewed>

// <prerequisite>
// <li> <linkto class="X11PixelCanvas">X11PixelCanvas</linkto>
// </prerequisite>

// <etymology>
// "X11PCDisplayListObject" is a contraction and concatenation of 
// "X11PixelCanvas", "Display List" and "Object".
// </etymology>

// <synopsis>
// This class forms the base interface for a set of classes which
// provide storing (and optimisation) of drawing commands for the
// <linkto class="X11PixelCanvas"> X11PixelCanvas </linkto> class.
// Most primitive graphics routines available on the X11PixelCanvas,
// for example <src>drawImage</src> and <src>drawRectangle</src>, have
// corresponding objects derived from this class, which are
// constructed by the primitive routines, and then called upon to draw
// themselves when necessary.
//
// Each instance of a class derived from X11PCDisplayListObject keeps
// with it information necessary to draw to the X11 drawable or to
// change the X11PixelCanvas's attributes.  Furthermore, these objects
// tend to store the information necessary to do the drawing in native
// X11 format, or as close to that as is practicable, thus lending a
// level of optimisation to the drawing process.
//
// Some X11PCDisplayListObjects take over the memory the PixelCanvas
// used to create the object when constructed and therefore undertake
// to destroy the memory when the X11PCDisplayListObject is destroyed.
// Examples of this include images and sets of points or lines.
//
// Each derived class must implement the draw and translate functions
// correctly.
// </synopsis>

// <motivation> 
// Is is extremely convenient to place all output graphics commands
// (including context changes) in a display list for fast and
// efficient handling.  The user gets control over drawn objects
// without knowing how the objects are drawn, or how they are cached.
// </motivation>

// <thrown>
// None.
// </thrown>

// <todo asof="2000/02/01">
// <li> Nothing known.
// </todo>

class X11PCDisplayListObject {

 public:
  
  // A virtual destructor is needed so that it will use the
  // actual destructor in the derived class.
  virtual ~X11PCDisplayListObject();
  
  // Translate the object by the specified displacements.
  virtual void translate(Int xt, Int yt) = 0;
  
  // Draw to the current context provided with the translation given.
  virtual void draw(::XDisplay *display, Drawable d, GC gc, Int xt,
		    Int yt) = 0;
  
  // Return a special character code identifying the type of drawing,
  // and therefore enabling down-stream caching.  <note
  // role=caution>Presently, the character codes are listed in
  // <src>X11PCCaceOpt.cc</src>, and are used in calls to
  // <src>X11PixelCanvas::packDisplayList</src>.</note>
  virtual Char optType() const = 0;
  
 protected:

  // (Required) default constructor.
  X11PCDisplayListObject();

  // (Required) copy constructor.
  X11PCDisplayListObject(const X11PCDisplayListObject &other);

  // (Required) copy assignment.
  X11PCDisplayListObject &operator=(const X11PCDisplayListObject &other);

};


} //# NAMESPACE CASA - END

#endif


