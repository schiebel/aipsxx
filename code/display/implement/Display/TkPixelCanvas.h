//# TkPixelCanvas.h: Tk interface for PixelCanvas
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
//# $Id: TkPixelCanvas.h,v 1.2 2005/06/15 17:56:33 cvsmgr Exp $

#ifndef TRIALDISPLAY_TKPIXELCANVAS_H
#define TRIALDISPLAY_TKPIXELCANVAS_H

//# aips includes:
#include <casa/aips.h>

//# tcl includes:

#include <graphics/X11/X_enter.h>
//# Use tcl8.4 in non-const mode (to be able to use tcl 8.3 as well)
#define USE_NON_CONST
extern "C" {
#include <tcl.h>
#include <tk.h>
}
#undef USE_NON_CONST
#include <graphics/X11/X_exit.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//#diag	#include <casa/namespace.h>

//# forwards
//#diag	extern "C" {
//#diag	  int TkPixelCanvas_Init(Tcl_Interp *);
//#diag	}

// <summary>
// Tk interface for PixelCanvas
// </summary>
//
// <use visibility=local>
//
// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>
//
// <prerequisites>
//   <li> Tk
//   <li> PixelCanvas
// </prerequisites>
//
// <synopsis>
// This class manages some native TclTk interface for the Display
// Library PixelCanvas.  It is practically identical with TclTkPixelCanvas.
// It will be cleaned up and absorbed soon into XTkPixelCanvas.
// </synopsis>
//
// <example>
// </example>
//
// <motivation>
// Putting X11PixelCanvas on top of Tk
// </motivation>
//
// <todo asof="1999/02/11">
// </todo>

class TkPixelCanvas {

 public:

  static int init(Tcl_Interp *); 
  
  // Constructor; instances of this class should only be 
  // constructed by the static member TkPixelCanvas::ClassCmd.
  TkPixelCanvas(Tcl_Interp *interp, char *path);

  // This static member is registered with Tcl to be called 
  // when the user creates a widget of this type.
  static int ClassCmd(ClientData, Tcl_Interp *, int, char **);

  // This static member is registered with Tcl to be called
  // when the user invokes an operation on a widget of this
  // type.  It is registered by TkPixelCanvas::ClassCmd.
  static int WidgetCmd(ClientData, Tcl_Interp *, int, char **);

  // Configure the widget using Tcl-style arguments.
  int configureWidget(Tcl_Interp *, int, char **);

  // Handle events in which the Tk side of things is interested:
  static void HandleWidgetEvent(ClientData, XEvent *);

  // A set of methods to arrange the invalidation of the current
  // window display, and arrange for appropriate update.
  // <group>
  void invalidateWindow();
  void scheduleUpdate();
  static void UpdateWidget(ClientData);
  void update();
  // </group>

  // Handle resizing:
  void resizeHandler(XEvent *);

  // Handle exposure:
  void exposeHandler();

  // Update the focus state of the visual widget:
  void focus(int);

  // Does the Tk window exist?
  int windowExists() { return tkwin_ != NULL; }

  // Has the widget been configured already?
  int widgetConfigured() { return flags_ & widget_configured_; }

  // Is an update waiting to be serviced?
  int updatePending() { return flags_ & update_pending_; }

  // Is a redraw needed?
  int redrawRequired() { return flags_ & redraw_required_; }

  // Should we redraw the window?
  int redrawWindow() { return flags_ & redraw_window_; }

  // width and height of widget
  // <group>
  int width() { return width_; }
  int height() { return height_; }
  // </group>

  // What is the Tk_Window?
  Tk_Window tkWindow() { return tkwin_; }


 private:

  // devices
  Tcl_Interp *interp_;
  Tk_Window tkwin_;
  GC background_gc_;
  Pixmap pixmap_;
  int havePixmap_;

  // configuration
  static Tk_ConfigSpec *ConfigSpecs_;
  int width_;
  int height_;
  int borderWidth_;
  Tk_3DBorder border_;
  int highlightThickness_;
  XColor *highlightColor_;
  XColor *lowlightColor_;
  int relief_;

  // state
  unsigned int flags_;
  enum FlagVals {
    widget_configured_ = 0x01,
    redraw_required_   = 0x02,
    redraw_window_     = 0x04,
    update_pending_    = 0x08
  };
  Tcl_DString *oldFocus_;
  int haveFocus_;
  
};

} //# NAMESPACE CASA - END

#endif
