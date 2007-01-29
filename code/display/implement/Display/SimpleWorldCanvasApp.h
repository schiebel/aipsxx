//# SimpleWorldCanvasApp.h: simple application wrapping up a WorldCanvas
//# Copyright (C) 1993,1994,1995,1996,1998,1999,2000,2001
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
//# $Id: SimpleWorldCanvasApp.h,v 19.5 2005/06/15 17:56:31 cvsmgr Exp $

#ifndef TRIALDISPLAY_SIMPLEWORLDCANVASAPP_H
#define TRIALDISPLAY_SIMPLEWORLDCANVASAPP_H

#include <casa/aips.h>
#include <display/Display.h>

//# Forward declarations
#include <casa/iosfwd.h>
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
// Simple application class providing a PixelCanvas and WorldCanvas.
// </summary>
//
// <prerequisite>
// <li> <linkto class="WorldCanvas">WorldCanvas</linkto>
// </prerequisite>
//
// <etymology>
// SimpleWorldCanvasApp : Simple WorldCanvas Application Class
// </etymology>
//
// <synopsis>
// SimpleWorldCanvasApp provides basic a basic GUI panel for
// a simple WorldCanvas application.  Event and other handlers
// can be registered to the app class.
// </synopsis>
//
// <motivation>
// Needed a testbed for the WorldCanvas
// </motivation>
//
// <example>
// See the test programs in Display
// </example>
//

class SimpleWorldCanvasApp 
{
public:

  // Default Constructor Required
  SimpleWorldCanvasApp(const Display::ColorModel &colormodel = Display::Index);

  // X callback to quit the program
  static void exitCB(Widget, XtPointer, XtPointer);
  static void pcmapCB(Widget, XtPointer, XtPointer);

  void printCmapInfo();

  // get the WorldCanvas
  WorldCanvas *worldCanvas();

  // function that builds the basic GUI
  Widget buildWidget(Widget parent);

  // add event handlers to the WorldCanvas
  // <group>
  void addRefreshEventHandler(WCRefreshEH & eh)
  { worldCanvas_->addRefreshEventHandler(eh); }
  void addMotionEventHandler(WCMotionEH & eh)
  { worldCanvas_->addMotionEventHandler(eh); }
  void addPositionEventHandler(WCPositionEH & eh)
  { worldCanvas_->addPositionEventHandler(eh); }
  // </group>

  // add specialized handlers to the WorldCanvas
  // <group>
  void setSizeControlHandler(WCSizeControlHandler & sch)
  { worldCanvas_->setSizeControlHandler(&sch); }
  void setCoordinateHandler(WCCoordinateHandler & ch)
  { worldCanvas_->setCoordinateHandler(&ch); }
  // </group>

  // Run the application
  void run();

  // Destructor
  virtual ~SimpleWorldCanvasApp();

  // Write a SimpleWorldCanvasApp to an ostream in a simple text form.
  friend ostream & operator << (ostream & os, const SimpleWorldCanvasApp & spca);

  // Write a SimpleWorldCanvasApp to an AipsIO stream in a binary format.
  friend AipsIO &operator<<(AipsIO &aio, const SimpleWorldCanvasApp & spca);

  // Write a SimpleWorldCanvasApp to a LogIO stream.
  friend LogIO &operator<<(LogIO &lio, const SimpleWorldCanvasApp & spca);

  // Read a SimpleWorldCanvasApp from an AipsIO stream in a binary format.
  // Will throw an AipsError if the current SimpleWorldCanvasApp Version does not match
  // that of the one on disk.
  friend AipsIO &operator>>(AipsIO &aio, SimpleWorldCanvasApp & spca);

  // Is this SimpleWorldCanvasApp consistent?
  Bool ok() const;

protected:


private:

  // The top widget in the widget tree
  Widget toplevel_;
  // The X Screen needed to build the PixelCanvasColorTable
  Screen * screen_;
  // The application context for run()
  XtAppContext app_;
  // Pointer to the PixelCanvas
  PixelCanvas * pixelCanvas_;
  // Pointer to the WorldCanvas
  WorldCanvas * worldCanvas_;
  // Colormap used
  Colormap * cmap_;

  enum { SimpleWorldCanvasAppVersion = 1 };
};


} //# NAMESPACE CASA - END

#endif


