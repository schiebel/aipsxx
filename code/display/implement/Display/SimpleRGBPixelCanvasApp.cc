//# SimpleRGBPixelCanvasApp.cc: simple stand-alone RGB application
//# Copyright (C) 1993,1994,1995,1996,1999,2000,2001,2002
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
//#$Id: SimpleRGBPixelCanvasApp.cc,v 19.6 2005/06/15 17:56:31 cvsmgr Exp $

#include <casa/stdio.h>   // sprintf

#include <display/Display/SimpleRGBPixelCanvasApp.h>
#include <casa/Exceptions/Error.h>
#include <casa/IO/AipsIO.h>
#include <casa/Utilities/Assert.h>
#include <casa/BasicSL/String.h>
#include <casa/Logging/LogIO.h>
#include <casa/iostream.h>
#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
SimpleRGBPixelCanvasApp::SimpleRGBPixelCanvasApp()
{
  int fakeArgc = 0;

  Widget appw = XtVaAppInitialize(&app_, "simple rgb app", NULL, 0,
				&fakeArgc, NULL, NULL,
				NULL);
  screen_ = XtScreen(appw);

  XtSetLanguageProc(NULL, NULL, NULL);
  XSynchronize(DisplayOfScreen(screen_), XTrue);

#if 1
  X11PixelCanvasColorTable * xpcct = 
    new X11PixelCanvasColorTable(screen_, Display::RGB, 
				 Display::Custom, 
				 Display::System,
				 16, 1, 16);
#endif
  
  String name = "";

  switch(xpcct->visual()->c_class)
    {
    case PseudoColor: name += "PseudoColor"; break;
    case TrueColor:   name += "TrueColor"; break;
    case DirectColor: name += "DirectColor"; break;
    case StaticColor: name += "StaticColor"; break;
    case GrayScale:   name += "GrayScale"; break;
    case StaticGray:  name += "StaticGray"; break;
    }

  name += " Visual, ";
  
  char depthStr[8];
  sprintf(depthStr, "%d", xpcct->depth());
  name += depthStr;
  name += "-bit depth, ";

  ostringstream cmodel;
  cmodel << xpcct->colorModel();
  name += cmodel.str();
  name += " Color Model";

  toplevel_ = XtVaCreatePopupShell(name.chars(),
				   topLevelShellWidgetClass, appw,
				   XmNvisual, xpcct->visual(),
				   XmNdepth, xpcct->depth(),
				   XmNcolormap, xpcct->xcmap(),
				   NULL);

  Widget wa = buildWidget(toplevel_);
  pixelCanvas_ = new X11PixelCanvas(wa, xpcct, (uInt)680, (uInt)460);  
  XtRealizeWidget(toplevel_);
  XtPopup(toplevel_, XtGrabNone);
}

void SimpleRGBPixelCanvasApp::exitCB(Widget, XtPointer, XtPointer)
{ exit(0); }

Widget SimpleRGBPixelCanvasApp::buildWidget(Widget parent)
{
  Visual * visual;
  int depth;
  XColormap xcmap;

  XtVaGetValues(parent, XmNvisual, &visual, XmNdepth, &depth, XmNcolormap, &xcmap, NULL);

  cout << "depth is " << depth << endl;
  cout << "visual is " << visual << endl;
  cout << "colormap is " << xcmap << endl << flush;

  XmString xstr;
  Widget workArea = XtVaCreateManagedWidget ("mainWindow",
					     xmMainWindowWidgetClass, parent,
					     XmNdepth, depth,
					     XmNcolormap, xcmap,
					     XmNvisual, visual,
					     //XmNscrollBarDisplayPolicy, XmAS_NEEDED,
					     //XmNscrollingPolicy, XmAUTOMATIC,
					     NULL);

  Arg args[4];
  XtSetArg(args[0], XmNdepth, depth);
  XtSetArg(args[1], XmNcolormap, xcmap);
  XtSetArg(args[2], XmNvisual, visual);

  // Menu Bar
  Widget menuBar = XmCreateMenuBar(workArea, "MenuBar", args, 3);
 
  // File Menu
  Widget fileMenu = XmCreatePulldownMenu(menuBar, "fileMenu", args, 3);
  
  // File Cascade button
  xstr = XmStringCreateLocalized("File");
  //Widget fileCascade = XtVaCreateManagedWidget("File",
  XtVaCreateManagedWidget("File",
			  xmCascadeButtonWidgetClass, menuBar,
			  XmNlabelString, xstr,
			  XmNmnemonic, 'F',
			  XmNsubMenuId, fileMenu,
			  XmNdepth, depth,
			  XmNcolormap, xcmap,
			  XmNvisual, visual,
			  NULL);
  XmStringFree(xstr);
 
  // File > Open
  //Widget fileOpen = XtVaCreateManagedWidget("Open",
  XtVaCreateManagedWidget("Open",
			  xmPushButtonGadgetClass, fileMenu,
			  XmNdepth, depth,
			  XmNcolormap, xcmap,
			  XmNvisual, visual,
			  NULL);
  
  //XtAddCallback(fileOpen, XmNactivateCallback, (XtCallbackProc) &CNApp::openCB, this);
 
  // File > Save
  //Widget fileSave = XtVaCreateManagedWidget("Save",
  XtVaCreateManagedWidget("Save",
			  xmPushButtonGadgetClass, fileMenu,
			  XmNdepth, depth,
			  XmNcolormap, xcmap,
			  XmNvisual, visual,
			  NULL);
  // File | separator
  //Widget fileSep = XtVaCreateManagedWidget("separator",
  XtVaCreateManagedWidget("separator",
			  xmSeparatorGadgetClass, fileMenu,
			  XmNdepth, depth,
			  XmNcolormap, xcmap,
			  XmNvisual, visual,
			  NULL);
  
  // File > Redraw
  //Widget fileRedraw = XtVaCreateManagedWidget("Redraw",
  XtVaCreateManagedWidget("Redraw",
			  xmPushButtonGadgetClass, fileMenu,
			  XmNdepth, depth,
			  XmNcolormap, xcmap,
			  XmNvisual, visual,
			  NULL);
  //XtAddCallback(fileRedraw, XmNactivateCallback, (XtCallbackProc) redrawCB, NULL);

    // File > Exit
  Widget fileExit = XtVaCreateManagedWidget("Exit",
                                            xmPushButtonGadgetClass, fileMenu,
					    XmNdepth, depth,
					    XmNcolormap, xcmap,
					    XmNvisual, visual,
					    NULL);
  XtAddCallback(fileExit, XmNactivateCallback, 
		(XtCallbackProc) SimpleRGBPixelCanvasApp::exitCB, NULL);
 
  // Help Menu
  Widget helpMenu = XmCreatePulldownMenu(menuBar, "helpMenu", args, 3);
  
   // Help Cascade button
  xstr = XmStringCreateLocalized("Help");
  //Widget helpCascade = XtVaCreateManagedWidget("Help",
  XtVaCreateManagedWidget("Help",
			  xmCascadeButtonWidgetClass, menuBar,
			  XmNlabelString, xstr,
			  XmNmnemonic, 'F',
			  XmNsubMenuId, helpMenu,
			  XmNdepth, depth,
			  XmNcolormap, xcmap,
			  XmNvisual, visual,
			  NULL);
  XmStringFree(xstr);
 
  // Help > Open
  //Widget helpOpen = XtVaCreateManagedWidget("Sorry... No help!",
  XtVaCreateManagedWidget("Sorry... No help!",
			  xmPushButtonGadgetClass, helpMenu,
			  XmNdepth, depth,
			  XmNcolormap, xcmap,
			  XmNvisual, visual,
			  NULL);
  XtManageChild (menuBar);
  
  return workArea;
}

void SimpleRGBPixelCanvasApp::run()
{
  XtAppMainLoop(app_);
}

// Destructor
SimpleRGBPixelCanvasApp::~SimpleRGBPixelCanvasApp()
{
}


Bool SimpleRGBPixelCanvasApp::ok() const
{
  return True;
}

//========================= Standardized Functions ============================

// write to ostream support
ostream & operator << (ostream & os, const SimpleRGBPixelCanvasApp &)
{
  // remove this warning when edited
  cerr << "Warning: class SimpleRGBPixelCanvasApp, ostream op << not completed";

  return os;
}

// write to AipsiO support
AipsIO & operator << (AipsIO & aio, const SimpleRGBPixelCanvasApp &)
{
  aio.putstart("SimpleRGBPixelCanvasApp", SimpleRGBPixelCanvasApp::SimpleRGBPixelCanvasAppVersion);
  
  // write values here.  check out aio.put

  // remove this warning when edited
  cerr << "Warning: class SimpleRGBPixelCanvasApp, AipsIO op << not completed";

  aio.putend();
  return aio;
}

// write to LogIO support
LogIO & operator << (LogIO & lio, const SimpleRGBPixelCanvasApp & spca)
{
  lio.output() << spca;
  return lio;
}
		     
// read from AipsIO support
AipsIO & operator >> (AipsIO & aio, SimpleRGBPixelCanvasApp &)
{
  if (aio.getstart("SimpleRGBPixelCanvasApp") != SimpleRGBPixelCanvasApp::SimpleRGBPixelCanvasAppVersion) 
    {
      throw(AipsError("AipsIO &operator>>(AipsIO &aio, SimpleRGBPixelCanvasApp &spca) - "
		      "version on disk and in class do not match"));
    }

  // read values, initialize structures.  check out aio.getnew
  
  // remove this warning when edited
  cerr << "Warning: class SimpleRGBPixelCanvasApp, AipsIO op >> not completed";
	
  aio.getend();

  return aio;
}


} //# NAMESPACE CASA - END

