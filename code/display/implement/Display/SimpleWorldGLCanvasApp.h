//# SimpleWorldGLCanvasApp.h: simple application wrapping up a WorldCanvas
//# Copyright (C) 2001
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
//# $Id: SimpleWorldGLCanvasApp.h,v 19.6 2005/06/15 17:56:31 cvsmgr Exp $

#ifndef TRIALDISPLAY_SIMPLEWORLDGLCANVASAPP_H
#define TRIALDISPLAY_SIMPLEWORLDGLCANVASAPP_H

#include <casa/iostream.h>

#include <casa/aips.h>
#include <display/Display.h>

namespace casa { //# NAMESPACE CASA - BEGIN

class ostream;
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
// SimpleWorldGLCanvasApp : Simple WorldCanvas OpenGL Application Class
// </etymology>
//
// <synopsis>
// SimpleWorldGLCanvasApp provides basic a basic GUI panel for
// a simple WorldCanvas application. Event and other handlers
// can be registered to the app class. SimpleWorldGLCanvasApp was copied
// from SimpleWorldCanvasApp and modified to use a GLPixelCanvas.
// </synopsis>
//
// <motivation>
// Needed a testbed for GLPixelCanvas.
// </motivation>
//
// <example>
// See the test programs in Display
// </example>
//
// <thrown>
//  AipsError
// </thrown>

class GLPixelCanvasColorTable;
class GLPixelCanvas;

class SimpleWorldGLCanvasApp 
{
public:


  // Constructor to use if openApplication has been called or just want
  // default connection.
  SimpleWorldGLCanvasApp(const char *application_name="simpleWorldGLCanvasApp",
			 const Display::ColorModel cm = Display::RGB,
			 Float percent=90.0);

  // Just make initial connection to X server. Used if it is desired to
  // separate opening the display and creating the SimpleWorldGLCanvasApp.
  // (e.g. Open connection then use the 'Input' class get the color model.)
  static void openApplication(
			 const char *application_class_name,
			 XrmOptionDescRec* options, Cardinal num_options,
			 int *argc, char **argv,
			 char **fallback_resources,
			 ArgList args, Cardinal num_args);

  // Connect to X server then create the app.
  SimpleWorldGLCanvasApp(
			const char *application_name,
			const char *application_class_name,
			XrmOptionDescRec* options, Cardinal num_options,
			int *argc, char **argv,
			char **fallback_resources,
			ArgList args, Cardinal num_args,
			const Display::ColorModel colormodel,
			const Float percent);

  // X callback to quit the program
  static void exitCB(Widget, XtPointer, XtPointer);
  // Pass a SimpleWorldGLCanvasApp as the second arg to print colormap
  // info. (Other args are ignored.
  static void pcmapCB(Widget, XtPointer swca, XtPointer);
  // Toggle tracing.
  static void traceCB(Widget, XtPointer swca, XtPointer);

  // called by pcmapCB.
  void printCmapInfo();

  // get the WorldCanvas
  WorldCanvas *worldCanvas();

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

  GLPixelCanvas *glPixelCanvas()const{return glPixelCanvas_;}

  // Destructor
  virtual ~SimpleWorldGLCanvasApp();

  // Write a SimpleWorldGLCanvasApp to an ostream in a simple text form.
  friend ostream & operator << (ostream & os, const SimpleWorldGLCanvasApp & spca);

  // Write a SimpleWorldGLCanvasApp to an AipsIO stream in a binary format.
  friend AipsIO &operator<<(AipsIO &aio, const SimpleWorldGLCanvasApp & spca);

  // Write a SimpleWorldGLCanvasApp to a LogIO stream.
  friend LogIO &operator<<(LogIO &lio, const SimpleWorldGLCanvasApp & spca);

  // Read a SimpleWorldGLCanvasApp from an AipsIO stream in a binary format.
  // Will throw an AipsError if the current SimpleWorldGLCanvasApp Version does not match
  // that of the one on disk.
  friend AipsIO &operator>>(AipsIO &aio, SimpleWorldGLCanvasApp & spca);

  // Is this SimpleWorldGLCanvasApp consistent?
  Bool ok() const;
protected:


private:
  // function that builds the basic GUI
  Widget buildWidget(const char *appname);

  void initialize(const Display::ColorModel, const Float percent,
		  const char *appname);
  static void redrawCB(Widget w, XtPointer me, XtPointer unuseddata);

private:

  // The application shell. Not used since it may not have the correct visual.
  // the desired visual.
  static Widget appW_;
  // The X Screen needed to build the PixelCanvasColorTable
  static Screen * screen_;
  // The application context for run()
  static XtAppContext app_;
  // Parent widget (TopLevelShell) that has correct visual.
  Widget toplevel_;
  // Pointer to the PixelCanvas
  PixelCanvas * pixelCanvas_;
  GLPixelCanvas *glPixelCanvas_;
  // Pointer to the WorldCanvas
  WorldCanvas * worldCanvas_;
  // 
  GLPixelCanvasColorTable *glct_;
  enum { SimpleWorldGLCanvasAppVersion = 1 };
  String	className_;
};


} //# NAMESPACE CASA - END

#endif
