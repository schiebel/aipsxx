//# SimplePixelCanvasApp.h: simple application class for a PixelCanvas
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
//# $Id: SimplePixelCanvasApp.h,v 19.5 2005/06/15 17:56:31 cvsmgr Exp $

#ifndef TRIALDISPLAY_SIMPLEPIXELCANVASAPP_H
#define TRIALDISPLAY_SIMPLEPIXELCANVASAPP_H

#include <casa/aips.h>
#include <display/Display.h>

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

#include <casa/iosfwd.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//# Forward declarations
class AipsIO;
class LogIO;

// <summary>
// Application class the provides basic gui for a PixelCanvas
// </summary>
//  
// <prerequisite>
// <li> <linkto class="PixelCanvas">PixelCanvas</linkto>
// </prerequisite>
//
// <etymology>
// SimplePixelCanvasApp : Simple PixelCanvas Application Class
// </etymology>
//
// <synopsis>
// SimplePixelCanvasApp provides basic a basic GUI panel for
// a simple PixelCanvas application.  Event handlers can be registered
// to the app class.
// </synopsis>
//
// <motivation>
// Needed simple testbed for the PixelCanvas
// </motivation>
//
// <example>
// See the test programs in Display
// </example>
//

class SimplePixelCanvasApp 
{
public:

  // Default Constructor Required
  SimplePixelCanvasApp();

  // X callback to quit the program
  static void exitCB(Widget, XtPointer, XtPointer);
  
  // function that builds the basic GUI
  Widget buildWidget(Widget parent);

  // functions to add event handlers to the pixel canvas
  // <group>
  void addRefreshEventHandler(const PCRefreshEH & eh)
  { pixelCanvas_->addRefreshEventHandler(eh); }
  void addMotionEventHandler(const PCMotionEH & eh)
  { pixelCanvas_->addMotionEventHandler(eh); }
  void addPositionEventHandler(const PCPositionEH & eh)
  { pixelCanvas_->addPositionEventHandler(eh); }
  // </group>

  // Direct access to the PixelCanvas
  PixelCanvas * pixelCanvas() const { return pixelCanvas_; }

  // Run the program
  void run();

  // Destructor
  virtual ~SimplePixelCanvasApp();

  // Write a SimplePixelCanvasApp to an ostream in a simple text form.
  friend ostream & operator << (ostream & os, const SimplePixelCanvasApp & spca);

  // Write a SimplePixelCanvasApp to an AipsIO stream in a binary format.
  friend AipsIO &operator<<(AipsIO &aio, const SimplePixelCanvasApp & spca);

  // Write a SimplePixelCanvasApp to a LogIO stream.
  friend LogIO &operator<<(LogIO &lio, const SimplePixelCanvasApp & spca);

  // Read a SimplePixelCanvasApp from an AipsIO stream in a binary format.
  // Will throw an AipsError if the current SimplePixelCanvasApp Version
  // does not match that of the one on disk.
  friend AipsIO &operator>>(AipsIO &aio, SimplePixelCanvasApp & spca);

  // Is this SimplePixelCanvasApp consistent?
  Bool ok() const;

 private:

  // top level widget
  Widget toplevel_;
  // X Screen required to launch the X11PixelCanvas
  Screen * screen_;
  // X Application context 
  XtAppContext app_;
  // Pointer to the PixelCanvas
  PixelCanvas * pixelCanvas_;
  // Pointer to the colormap used
  Colormap * cmap_;

  enum { SimplePixelCanvasAppVersion = 1 };
};


} //# NAMESPACE CASA - END

#endif


