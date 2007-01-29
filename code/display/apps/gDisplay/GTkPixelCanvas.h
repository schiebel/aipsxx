//# GTkPixelCanvas.h: GlishTk implementation of the PixelCanvas
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
//# $Id: GTkPixelCanvas.h,v 19.5 2005/06/15 18:09:13 cvsmgr Exp $

#ifndef TRIALDISPLAY_GTKPIXELCANVAS_H
#define TRIALDISPLAY_GTKPIXELCANVAS_H

#include <casa/aips.h>
#include <casa/Containers/SimOrdMap.h>
#include <casa/Logging/LogIO.h>
#include <casa/Arrays/Matrix.h>
#include <display/Utilities/DisplayOptions.h>
#include <display/Display/X11PixelCanvas.h>
#include <display/DisplayEvents/PCTestPattern.h>
#include "GTkDisplayProxy.h"

namespace casa {
class Colormap;
class PCITFiddler;


extern "C" void GTkPixelCanvas_Create(ProxyStore *, Value *);

// <summary>
// GlishTk implementation of the PixelCanvas
// </summary>
//
// <use visibility=export>
//
// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>
//
// <prerequisites>
//   <li> TclTkPixelCanvas
//   <li> GlishTk
//   <li> X11PixelCanvas
// </prerequisites>
//
// <synopsis> 
// This class embeds a Display Library X11PixelCanvas in a
// TclTk window supplied by the interface class TclTkPixelCanvas.  The
// interaction between GTkPixelCanvas and TclTkPixelCanvas is quite
// complicated, and is as follows: when the user constructs a
// GTkPixelCanvas at the GlishTk command line, an instance of this
// class is constructed.  The resultant object then creates a
// TclTkPixelCanvas object by passing a valid TclTk command string
// through to the Tcl interpreter.  This TclTkPixelCanvas then
// arranges for space in the parent window frame, and passes back
// information to the GTkPixelCanvas object which enables it to place
// an X11PixelCanvas in the supplied frame.  Actually, GTkPixelCanvas
// is derived from X11PixelCanvas, so it actually places itself in
// the supplied frame.
//
// The GTkPixelCanvas class provides the interface to the Display
// Library PixelCanvas.  Since it is derived from both X11PixelCanvas,
// and TkProxy, it provides all PixelCanvas functions, and all
// standard GlishTk agent functions.  In addition, it provides a set
// of events for control from GlishTk - this event interface is
// sufficient for the user to accomplish moderately sophisticated
// tasks with the PixelCanvas from GlishTk.  However, most applications
// should make use of the GTkWorldCanvas, its richer cousin.
// </synopsis>
//
// <example>
// </example>
// 
// <motivation>
// This class is motivated by the desire to operate the Display Library
// directly from GlishTk.  The PixelCanvas is the fundamental drawing
// machine of the Display Library.
// </motivation>
//
// <todo asof="1999/02/11">
//   <li> conform to coding guidelines
// </todo>

class GTkPixelCanvas : public GTkDisplayProxy, public DisplayOptions,
		       public X11PixelCanvas {

 public:

  // Constructor; this should only be called from within the 
  // static method GTkPixelCanvas::Create, which is registered with
  // GlishTk to build widgets of this type.
  GTkPixelCanvas(ProxyStore *s, TkFrame *frame_, charptr width, charptr height,
		 charptr relief, charptr borderwidth, charptr padx,
		 charptr pady, charptr foreground, charptr background,
		 charptr fill, const Value *mincolors, 
		 const Value *maxcolors, charptr maptype);

  // Destructor; this is used to unmap the widget from the 
  // display, and destroy its contents.
  ~GTkPixelCanvas();

  // Unmap the contents of the widget.
  void UnMap() { TkProxy::UnMap(); }

  // Respond to pack instruction: needed to allow maximal sizing:
  const char **PackInstruction();

  // Can we expand to fill available space?
  int CanExpand() const;

  // return True if refresh is allowed, default impl is True always
  virtual casa::Bool refreshAllowed() const { return (havePixmap_ && 
						      Tk_IsMapped(self)); }

  // fill in a record describing the current color allocation state
  // and capacity.
  void fillColorTableSizeRecord(Record &rec) const;

  // GlishTk event handler: report the status of the widget
  char *w_status(Value *args);

  // GlishTk event handler: set or report the current size of the
  // PixelCanvasColorTable used by the PixelCanvas
  char *w_colortablesize(Value *args);

  // GlishTk event handler: control the Colormap fiddler installed
  // on this PixelCanvas
  //char *w_fiddler(Value *args);
  char *w_standardfiddler(Value *args);
  char *w_mapfiddler(Value *args);
  
  // GlishTk event handler: destroy this widget - probably deprecated
  //char *w_destroy(Value *args);

  // GlishTk event handler: install or remove the test pattern from
  // the PixelCanvas
  char *w_testpattern(Value *args);

  // GlishTk event handlers: explicitly register/unregister a Colormap on the
  // PixelCanvas
  // <group>
  char *w_registercolormap(Value *args);
  char *w_unregistercolormap(Value *args);
  // </group>

  // GlishTk event handler: replace one colormap with another.
  char *w_replacecolormap(Value *args);

  // GlishTk event handlers: suspend/resume the handling of refresh
  // events
  // <group>
  char *w_hold(Value *args);
  char *w_release(Value *args);
  // </group>

  // agent commands: get/set options
  // <group>
  char *w_getoptions(Value *args);
  char *w_setoptions(Value *args);
  // </group>

  // agent command: write an X Pixmap copy of the PixelCanvas
  char *w_writexpixmap(Value *args);

  // agent primitive graphics commands
  // <group>
  /*
  char *drawpolygon(Value *args);
  char *drawrectangle(Value *args);
  */
  // </group>

  // Refresh the PixelCanvas - this will cascade the event to
  // all registered refresh handlers, provided the refresh event
  // handling is not suspended
  //void refresh(Display::RefreshReason reason = Display::UserCommand);
  virtual void refresh(const Display::RefreshReason &reason = 
		       Display::UserCommand,
		       const casa::Bool &explicitrequest = True);

 protected:

  static void HandleWidgetEvent(ClientData, XEvent *);
  static void ColorTableResizeCB(PixelCanvasColorTable *, 
				 uInt, void *, Display::RefreshReason reason);
  void exposeHandler_(Display::RefreshReason reason = 
  		      Display::PixelCoordinateChange);

  casa::Bool resize_();
  void enterHandler_();

  void initCanvas();
  casa::Bool initColorTable(Tk_Window self, Display::ColorModel colormodel,
		      Int *mincolors, Int *maxcolors);
  
  casa::Bool windowExists() { return (self != NULL); }

 private:

  // fill instruction for GlishTk; this is NOT TclTk.
  char *fill_;

  PCITFiddler *itsStdFiddler, *itsMapFiddler;

  Int holdcount_;
  casa::Bool refreshheld_;
  Display::RefreshReason heldreason_;

  Colormap *cmap_;

  // Disabled until completely understood.
  // not clear yet how to share CTs
  //static SimpleOrderedMap<uLong, X11PixelCanvasColorTable *> itsXPCCTsIndex;
  //static SimpleOrderedMap<uLong, X11PixelCanvasColorTable *> itsXPCCTsRGB;
  //static SimpleOrderedMap<uLong, X11PixelCanvasColorTable *> itsXPCCTsHSV;

  PCTestPattern *itsTestPattern;

  // State variables:
  casa::Bool logging_;

  Int itsInitialMaximumColors;
  casa::Bool itsOptionsPaperColors;

};
}

#endif
