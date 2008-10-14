//# X11PixelCanvasApp.h: application class providing simple gui for PixelCanvas
//# Copyright (C) 1993,1994,1995,1996,2000,2001
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
//# $Id: X11PixelCanvasApp.h,v 19.5 2005/06/15 17:56:44 cvsmgr Exp $

#ifndef TRIALDISPLAY_X11PIXELCANVASAPP_H
#define TRIALDISPLAY_X11PIXELCANVASAPP_H

#include <casa/aips.h>

//# Forward declarations
#include <casa/iosfwd.h>
#include <display/Display.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class AipsIO;
class LogIO;

} //# NAMESPACE CASA - END

#include <graphics/X11/X_enter.h>
#include <X11/Intrinsic.h>
#include <Xm/Xm.h>
#include <Xm/FileSB.h>
#include <Xm/MainW.h>
#include <Xm/PanedW.h>
#include <Xm/Label.h>
#include <Xm/MessageB.h>
#include <Xm/RowColumn.h>
#include <Xm/PushBG.h>
#include <Xm/CascadeB.h>
#include <Xm/SeparatoG.h>
#include <graphics/X11/X_exit.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// <summary>
// Application class the provides basic gui for a PixelCanvas
// </summary>
//  
// <prerequisite>
// <li> <linkto class="PixelCanvas">PixelCanvas</linkto>
// </prerequisite>
//
// <etymology>
// X11PixelCanvasApp :  PixelCanvas Application Class
// </etymology>
//
// <synopsis>
// X11PixelCanvasApp provides basic a basic GUI panel for
// a  PixelCanvas application.  Event handlers can be registered
// to the app class.
// </synopsis>
//
// <motivation>
// Needed  testbed for the PixelCanvas
// </motivation>
//
// <example>
// See the test programs in Display
// </example>
//

class X11PixelCanvasApp {

 public:

  // Default Constructor Required
  X11PixelCanvasApp();

  // required because init calls virtual funcs
  void init();

  // initialization hook after XtVaAppInit..
  virtual void XtAppInitHook(Screen * screen, XtAppContext * app);

  // function that creates the shell widget
  virtual Widget makeShellWidget(Widget parent, 
				 X11PixelCanvasColorTable * xpcct);

  // function that makes the application's GUI and return a
  // widget to serve as the parent to the pixel canvas
  virtual Widget makeGUI(Widget parent);

  // function to make the PixelCanvasColorTable
  virtual X11PixelCanvasColorTable *makePixelCanvasColorTable(Screen *screen);

  // function to make the PixelCanvas
  virtual X11PixelCanvas * makePixelCanvas(Widget parent,
					   X11PixelCanvasColorTable * pcct);

  // functions to add event handlers to the pixel canvas
  // <group>
  void addRefreshEventHandler(const PCRefreshEH & eh)
  { init(); ((PixelCanvas *) pixelCanvas_)->addRefreshEventHandler(eh); }
  void addMotionEventHandler(const PCMotionEH & eh)
  { init(); ((PixelCanvas *) pixelCanvas_)->addMotionEventHandler(eh); }
  void addPositionEventHandler(const PCPositionEH & eh)
  { init(); ((PixelCanvas *) pixelCanvas_)->addPositionEventHandler(eh); }
  // </group>

  // Direct access to the PixelCanvas
  PixelCanvas * pixelCanvas() { init(); return (PixelCanvas *) pixelCanvas_; }

  // Run the program
  void run();

  // X callback to quit the program
  static void exitCB(Widget, XtPointer, XtPointer);
  static void refreshCB(Widget, XtPointer, XtPointer);
  
  // Destructor
  virtual ~X11PixelCanvasApp();

  // Write a X11PixelCanvasApp to an ostream in a  text form.
  friend ostream & operator << (ostream & os, const X11PixelCanvasApp & spca);

  // Write a X11PixelCanvasApp to an AipsIO stream in a binary format.
  friend AipsIO &operator<<(AipsIO &aio, const X11PixelCanvasApp & spca);

  // Write a X11PixelCanvasApp to a LogIO stream.
  friend LogIO &operator<<(LogIO &lio, const X11PixelCanvasApp & spca);

  // Read a X11PixelCanvasApp from an AipsIO stream in a binary format.
  // Will throw an AipsError if the current X11PixelCanvasApp Version
  // does not match that of the one on disk.
  friend AipsIO &operator>>(AipsIO &aio, X11PixelCanvasApp & spca);

  // Is this X11PixelCanvasApp consistent?
  Bool ok() const;

 private:

  // Init flag, since can't init in ctor w/ virtual funcs.
  Bool init_;
  // invisible app widget
  Widget appw_;
  // visible shell widget
  Widget shell_;
  // X Screen required to launch the X11PixelCanvas
  Screen * screen_;
  // X Application context 
  XtAppContext app_;
  // Pointer to the pixelCanvas
  X11PixelCanvas * pixelCanvas_;
  // Pointer to the X11PixelCanvasColorTable
  X11PixelCanvasColorTable * xpcct_;

  enum { X11PixelCanvasAppVersion = 1 };
};


} //# NAMESPACE CASA - END

#endif


