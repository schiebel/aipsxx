//# XTkPixelCanvas.h: X / Tk implementation the PixelCanvas
//# Copyright (C) 1999,2000,2001,2002
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
//# $Id: XTkPixelCanvas.h,v 1.3 2005/06/15 17:56:44 cvsmgr Exp $

#ifndef TRIALDISPLAY_XTKPIXELCANVAS_H
#define TRIALDISPLAY_XTKPIXELCANVAS_H

#include <casa/aips.h>
#include <display/Utilities/DisplayOptions.h>
#include <display/Display/X11PixelCanvas.h>
#include <display/DisplayEvents/PCTestPattern.h>

#include "TkPixelCanvas.h"	//#diag <--(or do XEnter stuff..)
//#diag	extern "C" {
//#diag	#include <tcl.h>
//#diag	#include <tk.h>
//#diag	}

namespace casa {

class Colormap;
class PCITFiddler;


// <summary>
// X Tk implementation of the PixelCanvas
// </summary>
//
// <use visibility=export>
//
// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>
//
// <prerequisites>
//   <li> TkPixelCanvas
//   <li> X11PixelCanvas
// </prerequisites>
//
// <synopsis> 
// This class was sculpted from GTkPixelCanvas (with an axe).  It uses
// TkPixelCanvas (and probably should be combined with it) to set
// up a Tk custom widget, building the X11PixelCanvas onto that
// (as GTkPixelCanvas does).  However, it does not use glish; that
// functional interface / event framework has been ripped out, and will
// have to be replaced with a new framework/interface (yet TBD).
// </synopsis>
//
// <example>
// </example>
// 
// <motivation>
// This class is motivated by the desire to operate the Display Library
// within Tk, but independently of glish.  The PixelCanvas is the fundamental
// drawing machine of the Display Library.
// </motivation>

class XTkPixelCanvas : public DisplayOptions, public X11PixelCanvas {

 public:

  // Constructor; this should only be called from within the 
  // static method XTkPixelCanvas::Create, which is registered with
  // GlishTk to build widgets of this type.
  XTkPixelCanvas(Tcl_Interp* tcl, String tkpath, 
		 Vector<Int> mincolors, Vector<Int> maxcolors,
		 String maptype="index",
		 String width="0", String height="0",
		 String relief="raised", String borderwidth="0",
		 String background="black");

  // Destructor; this is used to unmap the widget from the 
  // display, and destroy its contents.
  ~XTkPixelCanvas();



  // fill in a record describing the current color allocation state
  // and capacity.
  void fillColorTableSizeRecord(Record &rec) const;


  // Refresh the PixelCanvas - this will cascade the event to
  // all registered refresh handlers, provided the refresh event
  // handling is not suspended
  //void refresh(Display::RefreshReason reason = Display::UserCommand);
  virtual void refresh(const Display::RefreshReason &reason = 
		       Display::UserCommand,
		       const Bool& explicitrequest = True);
       
  static Int evalTcl(Tcl_Interp* tcl, const String& cmdStr);
  
  

 protected:

  static void HandleWidgetEvent(ClientData, XEvent *);
  
  static void ColorTableResizeCB(PixelCanvasColorTable *, 
				 uInt, void *, Display::RefreshReason reason);
  
  void exposeHandler_(Display::RefreshReason reason = 
  		      Display::PixelCoordinateChange);

  Bool resize_();
  
  void initCanvas();
  
  void initColorTable(Display::ColorModel colormodel,
		      Vector<Int> mincolors, Vector<Int> maxcolors);
  
  Bool windowExists() { return (tkWin_ != NULL); }
  
  //# (not used for holding refresh).
  virtual Bool refreshAllowed() const { 
    return (havePixmap_ && Tk_IsMapped(tkWin_));  }



 private:

  Tcl_Interp* tcl_;		// pointer to tcl interpreter
  String tkPath_;		// Tk pathname for this widget
  String parentPath_;		// Tk pathname for parent
  Tk_Window tkWin_;		// Tk window handle for this widget
  Tk_Window parentWin_;		// Tk window handle for parent
  Tk_Window rootWin_;		// Tk root window handle

  
  
  PCITFiddler *itsStdFiddler, *itsMapFiddler;

  Colormap *cmap_;

  PCTestPattern *testPattern_;

  Bool paperColors_;
  
  
};

}

#endif
