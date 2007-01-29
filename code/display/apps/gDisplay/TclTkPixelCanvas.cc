//# TclTkPixelCanvas.cc: TclTk implementation of the GlishTk PixelCanvas
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
//# $Id: TclTkPixelCanvas.cc,v 19.5 2005/06/15 18:09:13 cvsmgr Exp $

#include <casa/iostream.h>
#include <casa/string.h>

//# this include:
#include "TclTkPixelCanvas.h"

#include <casa/namespace.h>
TclTkPixelCanvas::TclTkPixelCanvas(Tcl_Interp *interp, char *path) :
  interp_(interp),
  background_gc_(None),
  havePixmap_(0),
  width_(0),
  height_(0),
  borderWidth_(0),
  border_(NULL),
  highlightColor_(0),
  lowlightColor_(0),
  flags_(0),
  oldFocus_(0),
  haveFocus_(0) {
  // create the window
  tkwin_ = Tk_CreateWindowFromPath(interp_, Tk_MainWindow(interp_),
				   path, NULL);
  
  // check it worked
  if (!tkwin_) {
    return;
  }

  // set the window class
  Tk_SetClass(tkwin_, "pixelcanvas");

  // made the window exist
  Tk_MakeWindowExist(tkwin_);
}

int TclTkPixelCanvas::ClassCmd(ClientData, Tcl_Interp *interp,
			  int argc, char **argv) {
  // check for sufficient args
  if (argc < 2) {
    Tcl_AppendResult(interp, "wrong number of args", NULL);
    return TCL_ERROR;
  }

  // create a new widget
  TclTkPixelCanvas *w = new TclTkPixelCanvas(interp, (char*)(argv[1]));
  
  // check it worked
  if (!w) {
    Tcl_SetResult(interp, "couldn't create widget", TCL_STATIC);
    return TCL_ERROR;
  }

  // check window exists
  if (!w->windowExists()) {
    Tcl_SetResult(interp, "couldn't create window", TCL_STATIC);
    return TCL_ERROR;
  }

  // add Tcl command handler
  Tcl_CreateCommand(interp, argv[1], TclTkPixelCanvas::WidgetCmd,
		    (ClientData)w, NULL);

  // configure the widget
  if (w->configureWidget(interp, argc - 2, argv + 2) != TCL_OK) {
    delete w;
    return TCL_ERROR;
  }

  // create event handler
  Tk_CreateEventHandler(w->tkWindow(),
			StructureNotifyMask |
			ExposureMask |
			EnterWindowMask | LeaveWindowMask,
			TclTkPixelCanvas::HandleWidgetEvent, ClientData(w));

  // return the widget name to the interpreter
  Tcl_SetResult(interp, (char*)(argv[1]), TCL_VOLATILE);

  return TCL_OK;
}

int TclTkPixelCanvas::WidgetCmd(ClientData data, Tcl_Interp *interp,
				int argc, char **argv)
{
  // get a handle to the widget
  TclTkPixelCanvas *w = (TclTkPixelCanvas *)data;

  // check for sufficient args
  if (argc < 2) {
    Tcl_AppendResult(interp, "wrong number of args", NULL);
    return TCL_ERROR;
  }

  int len = strlen(argv[1]);

  // configure the widget
  if (!strncmp("configure", argv[1], len)) {
    return w->configureWidget(interp, argc - 2, argv + 2);
  }

  // otherwise unknown command to Tcl
  else {
    Tcl_AppendResult(interp, "unknown command", NULL);
    return TCL_ERROR;
  }

  return TCL_OK;
}

int TclTkPixelCanvas::configureWidget(Tcl_Interp *interp,
				      int argc, char **argv)
{
  // check that it has been configured
  if (widgetConfigured()) {
    
    // return configuration if no arguments
    if (argc == 0) {
      return Tk_ConfigureInfo(interp, tkwin_, ConfigSpecs_,
			      (char *)this, NULL, 0);
    }

    // or return a specific option
    else if (argc == 1) {
      return Tk_ConfigureInfo(interp, tkwin_, ConfigSpecs_,
			      (char *)this, argv[0], 0);
    }

    // otherwise configure the widget
    else {
      if (Tk_ConfigureWidget(interp, tkwin_, ConfigSpecs_,
			     argc, argv, (char *)this, 
			     TK_CONFIG_ARGV_ONLY) != TCL_OK) {
	return TCL_ERROR;
      }
    }
  }

  // otherwise configure the widget
  else {
    flags_ |= widget_configured_;
    if (Tk_ConfigureWidget(interp, tkwin_, ConfigSpecs_,
			   argc, argv, (char *)this, 0) != TCL_OK) {
      return TCL_ERROR;
    }
  }

  // invalidate the display to force a refresh
  Tk_SetBackgroundFromBorder(tkwin_, border_);
  invalidateWindow();

  // update geometry info
  Tk_GeometryRequest(tkwin_, width_, height_);
  Tk_SetInternalBorder(tkwin_, borderWidth_);

  // get a gc for drawing the window background
  XGCValues gc_values;
  gc_values.foreground = Tk_3DBorderColor(border_)->pixel;
  gc_values.graphics_exposures = False;
  if (background_gc_ != None) {
    Tk_FreeGC(Tk_Display(tkwin_), background_gc_);
  }
  background_gc_ = Tk_GetGC(tkwin_, GCForeground | GCGraphicsExposures,
			    &gc_values);

  return TCL_OK;
}

void TclTkPixelCanvas::HandleWidgetEvent(ClientData data, XEvent *ev) {

  // get a handle to the widget
  TclTkPixelCanvas *w = (TclTkPixelCanvas *)data;
  
  // check the window exists
  if (!w->windowExists()) {
    return;
  }

  switch(ev->type) {

  case ConfigureNotify:
    // w->resizeHandler(ev);
    if (ev->xconfigure.width < w->width() ||
	ev->xconfigure.height < w->height()) {
      w->exposeHandler();
    }
    break;

  case Expose:
    if (ev->xexpose.count == 0) {
      w->exposeHandler();
    }
    break;

  case EnterNotify:
    w->focus(1);
    break;

  case LeaveNotify:
    w->focus(0);
    break;

  default:
    break;
  }
}

void TclTkPixelCanvas::invalidateWindow() {
  flags_ |= (redraw_required_ | redraw_window_);
  scheduleUpdate();
}

void TclTkPixelCanvas::scheduleUpdate() {
  if (!updatePending() && windowExists()) {
    Tcl_DoWhenIdle(UpdateWidget, (ClientData)this);
    flags_ |= update_pending_;
  }
}

void TclTkPixelCanvas::UpdateWidget(ClientData d) {
  ((TclTkPixelCanvas *)d)->update();
}

void TclTkPixelCanvas::update() {
  
  // make sure the window exists
  if (!windowExists()) {
    return;
  }

  // redraw if window is on the screen
  if (redrawRequired() && Tk_IsMapped(tkwin_)) {
    if (redrawWindow()) {
      width_ = Tk_Width(tkwin_);
      height_ = Tk_Height(tkwin_);
    }

    if ((width_ > 0) && (height_ > 0)) {
      Pixmap pix = Tk_GetPixmap(Tk_Display(tkwin_), Tk_WindowId(tkwin_),
				width_, height_, Tk_Depth(tkwin_));
      XFillRectangle(Tk_Display(tkwin_), pix, background_gc_, 0, 0,
		     width_, height_);
      if (border_ && (borderWidth_ > 0)) {
	char cname[20];
	sprintf(cname, "#%4.4hx%4.4hx%4.4hx", 40, 40, 80);
	Tk_3DBorder bd = Tk_Get3DBorder(interp_, tkwin_, cname);
	Tk_Draw3DRectangle(tkwin_, Tk_WindowId(tkwin_),
			   bd, highlightThickness_,
			   highlightThickness_,
			   width_ - 2 * highlightThickness_,
			   height_ - 2 * highlightThickness_,
			   borderWidth_, relief_);
      }
      XCopyArea(Tk_Display(tkwin_), pix, Tk_WindowId(tkwin_),
		background_gc_, 0, 0, width_, height_, 0, 0);
      Tk_FreePixmap(Tk_Display(tkwin_), pix);
    }
  }

  flags_ &= ~(redraw_required_ | redraw_window_ | update_pending_);
}

void TclTkPixelCanvas::resizeHandler(XEvent *ev) {
  int w = ev->xconfigure.width;
  int h = ev->xconfigure.height;
  // if shrunk is true, we will have to force a refresh
  int shrunk = ((w < width_) || (h < height_));
  width_ = w;
  height_ = h;

  // update our stored pixmap
  if (havePixmap_) {
    Tk_FreePixmap(Tk_Display(tkwin_), pixmap_);
  }
  pixmap_ = Tk_GetPixmap(Tk_Display(tkwin_), Tk_WindowId(tkwin_),
			 width_, height_, Tk_Depth(tkwin_));
  havePixmap_ = 1;

  if (shrunk) {
    exposeHandler();
  }
}

void TclTkPixelCanvas::exposeHandler() {
  if (!havePixmap_) {
    return;
  }
  
  // fill with background colour
  XFillRectangle(Tk_Display(tkwin_), pixmap_, background_gc_, 0, 0,
		 width_, height_);
    
  // draw 3d border
  if (border_ && (borderWidth_ > 0)) {
    Tk_Draw3DRectangle(tkwin_, pixmap_,
		       border_, highlightThickness_,
		       highlightThickness_,
		       width_ - 2 * highlightThickness_,
		       height_ - 2 * highlightThickness_,
		       borderWidth_, relief_);
  }
    
  // blit to screen
  XCopyArea(Tk_Display(tkwin_), pixmap_, Tk_WindowId(tkwin_),
	    background_gc_, 0, 0, width_, height_, 0, 0);
}

void TclTkPixelCanvas::focus(int f) {
  if (f) {
    Tcl_Eval(interp_, "focus");
    if (!oldFocus_) {
      oldFocus_ = new Tcl_DString;
    } else {
      Tcl_DStringFree(oldFocus_);
    }
    Tcl_DStringInit(oldFocus_);
    Tcl_DStringGetResult(interp_, oldFocus_);
    Tcl_VarEval(interp_, "focus ", Tk_PathName(tkwin_), 0);
  } else {
    //if (Tcl_DStringLength(oldFocus_)) {
    //  Tcl_VarEval(interp_, "focus ", Tcl_DStringValue(oldFocus_), 0);
    //} else {
      Tcl_Eval(interp_, "focus .");
      //}
  }
  haveFocus_ = f;
}

Tk_ConfigSpec *TclTkPixelCanvas::ConfigSpecs_;
extern "C" int TclTkPixelCanvas_Init(Tcl_Interp *interp) {
  Tcl_CreateCommand(interp, "pixelcanvas", TclTkPixelCanvas::ClassCmd,
		    (ClientData)1, 0);

  // initialize config info
  static Tk_ConfigSpec cSpecs[] = {

    {TK_CONFIG_PIXELS, 
     "-width", "width", "Width",
     "10c", Tk_Offset(TclTkPixelCanvas, width_), 0, NULL},

    {TK_CONFIG_PIXELS,
     "-height", "height", "Height",
     "8c", Tk_Offset(TclTkPixelCanvas, height_), 0, NULL},

    {TK_CONFIG_PIXELS,
     "-borderwidth", "borderWidth", "BorderWidth",
     "1m", Tk_Offset(TclTkPixelCanvas, borderWidth_), 0, NULL},

    {TK_CONFIG_BORDER,
     "-background", "background", "Background",
     "Black", Tk_Offset(TclTkPixelCanvas, border_), 0},

    {TK_CONFIG_PIXELS,
     "-highlightthickness", "highlightThickness", "HighlightThickness",
     "2", Tk_Offset(TclTkPixelCanvas, highlightThickness_), 0},

    {TK_CONFIG_COLOR,
     "-highlightcolor", "highlightColor", "HighlightColor",
     "black", Tk_Offset(TclTkPixelCanvas, highlightColor_), 0},

  {TK_CONFIG_COLOR,
     "-highlightbackground", "highlightBackground", "HighlightBackground",
     "grey", Tk_Offset(TclTkPixelCanvas, lowlightColor_), 0},    

    {TK_CONFIG_RELIEF,
     "-relief", "relief", "Relief",
     "raised", Tk_Offset(TclTkPixelCanvas, relief_), 0},

    {TK_CONFIG_END}
  };

  TclTkPixelCanvas::ConfigSpecs_ = cSpecs;

  return TCL_OK;
}
