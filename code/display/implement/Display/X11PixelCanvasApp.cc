//# X11PixelCanvasApp.cc: basic application providing a X11PixelCanvas
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
//# $Id: X11PixelCanvasApp.cc,v 19.5 2005/06/15 17:56:44 cvsmgr Exp $

#include <display/Display/X11PixelCanvasApp.h>
#include <casa/Exceptions/Error.h>
#include <casa/IO/AipsIO.h>
#include <casa/Utilities/Assert.h>
#include <casa/Logging/LogIO.h>
#include <casa/iostream.h>
#include <casa/sstream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

X11PixelCanvasApp::X11PixelCanvasApp()
  : init_(False)
{
  int fakeArgc = 0;
  appw_ = XtVaAppInitialize(&app_, " app", NULL, 0,
				  &fakeArgc, NULL, NULL, NULL);

  XtSetLanguageProc(NULL, NULL, NULL);
  screen_ = XtScreen(appw_);
}

void X11PixelCanvasApp::XtAppInitHook(Screen *, XtAppContext *)
{  
}

// default function
X11PixelCanvasColorTable * 
X11PixelCanvasApp::makePixelCanvasColorTable(Screen *)
{
  X11PixelCanvasColorTable *retval = 0;

  // First try to get somewhere between 40 and 100 colors
  // using the system colortable.
  try {
    retval = new X11PixelCanvasColorTable(screen_, Display::Index, 
				   Display::MinMax, 
				   Display::System,
				   64, 128);
  } catch (AipsError x) {
    retval = 0;
  } 

  if (retval) return retval;

  // Second just use a private map
  try {
    retval = new X11PixelCanvasColorTable(screen_, Display::Index, 
				   Display::Best, 
				   Display::New);
  } catch (AipsError x) {
    retval = 0;
  } 

  if (retval) 
    return retval;
  else
    throw(AipsError("Can't get a colormap!"));

  return 0;
}
 
Widget X11PixelCanvasApp::makeShellWidget(Widget appw,
					  X11PixelCanvasColorTable * xpcct)
{

  String info = "";

  switch(xpcct->visual()->c_class)
    {
    case PseudoColor: info += "PseudoColor"; break;
    case TrueColor:   info += "TrueColor"; break;
    case DirectColor: info += "DirectColor"; break;
    case StaticColor: info += "StaticColor"; break;
    case GrayScale:   info += "GrayScale"; break;
    case StaticGray:  info += "StaticGray"; break;
    }

  info += " Visual, ";
  
  ostringstream depthStr;
  depthStr << xpcct_->depth(); 
  info += depthStr.str();
  info += "-bit depth, ";

  ostringstream cmodel;
  if (xpcct->colorModel() == Display::Index)
    {
      cmodel << xpcct->nColors() << " Colors";
    }
  else
    {
      uInt n1, n2, n3;
      xpcct->nColors(n1, n2, n3);
      cmodel << n1 << "x" << n2 << "x" << n3;
    }
  cmodel << ", " << xpcct->colorModel();
  info += cmodel.str();
  info += " Color Model";

  Widget shell = XtVaCreatePopupShell(info.chars(),
				      topLevelShellWidgetClass, appw,
				      XmNvisual, xpcct->visual(),
				      XmNdepth, xpcct->depth(),
				      XmNcolormap, xpcct->xcmap(),
				      NULL);
  return shell;
}

// default function
X11PixelCanvas *
X11PixelCanvasApp::makePixelCanvas(Widget parent, X11PixelCanvasColorTable * xpcct)
{
  return new X11PixelCanvas(parent, xpcct, 480, 320);
}

void X11PixelCanvasApp::exitCB(Widget, XtPointer, XtPointer)
{ exit(0); }

void X11PixelCanvasApp::refreshCB(Widget, XtPointer xpcap, XtPointer)
{
  X11PixelCanvasApp * xpca = (X11PixelCanvasApp *) xpcap;
  xpca->pixelCanvas()->refresh();
}

Widget X11PixelCanvasApp::makeGUI(Widget parent)
{
  Visual * visual;
  int depth;
  XColormap xcmap;

  XtVaGetValues(parent, XmNvisual, &visual, XmNdepth, &depth, XmNcolormap, &xcmap, NULL);

  // cout << "depth is " << depth << endl;
  // cout << "visual is " << visual << endl;
  // cout << "colormap is " << xcmap << endl << flush;

  XmString xstr;
  Widget workArea = XtVaCreateManagedWidget ("mainWindow",
					     xmMainWindowWidgetClass, parent,
					     XmNdepth, depth,
					     XmNcolormap, xcmap,
					     XmNvisual, visual,
					     //XmNscrollBarDisplayPolicy, XmAS_NEEDED,
					     //XmNscrollingPolicy, XmAUTOMATIC,
					     NULL);

  Arg args[3];
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
  Widget fileRedraw = XtVaCreateManagedWidget("Refresh",
					      xmPushButtonGadgetClass, fileMenu,
					      XmNdepth, depth,
					      XmNcolormap, xcmap,
					      XmNvisual, visual,
					      NULL);
  XtAddCallback(fileRedraw, XmNactivateCallback, (XtCallbackProc) refreshCB, this);

    // File > Exit
  Widget fileExit = XtVaCreateManagedWidget("Exit",
                                            xmPushButtonGadgetClass, fileMenu,
					    XmNdepth, depth,
					    XmNcolormap, xcmap,
					    XmNvisual, visual,
					    NULL);
  XtAddCallback(fileExit, XmNactivateCallback, 
		(XtCallbackProc) X11PixelCanvasApp::exitCB, NULL);
 
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

void X11PixelCanvasApp::init()
{
  if (init_ == False)
    {
      init_ = True;
      XtAppInitHook(screen_, &app_);
      
      xpcct_ = makePixelCanvasColorTable(screen_);
      
      shell_ = makeShellWidget(appw_, xpcct_);
      Widget tb = makeGUI(shell_);
      pixelCanvas_ = makePixelCanvas(tb, xpcct_);
    }
}

void X11PixelCanvasApp::run()
{
  init();
  XtRealizeWidget(shell_);
  XtPopup(shell_, XtGrabNone);
  XtAppMainLoop(app_);
}

// Destructor
X11PixelCanvasApp::~X11PixelCanvasApp()
{
}


Bool X11PixelCanvasApp::ok() const
{
  return True;
}

//========================= Standardized Functions ============================

// write to ostream support
ostream & operator << (ostream & os, const X11PixelCanvasApp &) {
  // remove this warning when edited
  cerr << "Warning: class X11PixelCanvasApp, ostream op << not completed";

  return os;
}

// write to AipsiO support
AipsIO & operator << (AipsIO & aio, const X11PixelCanvasApp &) {
  aio.putstart("X11PixelCanvasApp", X11PixelCanvasApp::X11PixelCanvasAppVersion);
  
  // write values here.  check out aio.put

  // remove this warning when edited
  cerr << "Warning: class X11PixelCanvasApp, AipsIO op << not completed";

  aio.putend();
  return aio;
}

// write to LogIO support
LogIO & operator << (LogIO & lio, const X11PixelCanvasApp & spca)
{
  lio.output() << spca;
  return lio;
}
		     
// read from AipsIO support
AipsIO & operator >> (AipsIO & aio, X11PixelCanvasApp &) {
  if (aio.getstart("X11PixelCanvasApp") != X11PixelCanvasApp::X11PixelCanvasAppVersion) 
    {
      throw(AipsError("AipsIO &operator>>(AipsIO &aio, X11PixelCanvasApp &spca) - "
		      "version on disk and in class do not match"));
    }

  // read values, initialize structures.  check out aio.getnew
  
  // remove this warning when edited
  cerr << "Warning: class X11PixelCanvasApp, AipsIO op >> not completed";
	
  aio.getend();

  return aio;
}


} //# NAMESPACE CASA - END

