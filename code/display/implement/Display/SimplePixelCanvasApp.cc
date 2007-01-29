//# SimplePixelCanvasApp.cc: simple application class for a PixelCanvas
//# Copyright (C) 1993,1994,1995,1996,1999,2000,2001
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
//# $Id: SimplePixelCanvasApp.cc,v 19.4 2005/06/15 17:56:30 cvsmgr Exp $

#include <display/Display/SimplePixelCanvasApp.h>
#include <casa/Exceptions/Error.h>
#include <casa/IO/AipsIO.h>
#include <casa/Utilities/Assert.h>
#include <casa/Logging/LogIO.h>
#include <casa/iostream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
SimplePixelCanvasApp::SimplePixelCanvasApp()
{
  int fakeArgc = 0;
  toplevel_ = XtVaAppInitialize(&app_, "simple app", NULL, 0,
				&fakeArgc, NULL, NULL, NULL);
  XtSetLanguageProc(NULL, NULL, NULL);
  screen_ = XtScreen(toplevel_);

  Widget tb = buildWidget(toplevel_);

  X11PixelCanvasColorTable * xch = 
    new X11PixelCanvasColorTable(screen_, Display::Index, 
				 Display::Percent, 
				 Display::System, (float)50.0);
  
  pixelCanvas_ = new X11PixelCanvas(tb, xch, (uInt)400, (uInt)400);  
}

void SimplePixelCanvasApp::exitCB(Widget, XtPointer, XtPointer)
{ exit(0); }

Widget SimplePixelCanvasApp::buildWidget(Widget parent)
{
  XmString xstr;
  Widget workArea = XtVaCreateManagedWidget ("mainWindow",
                                      xmMainWindowWidgetClass, parent,
                                      //XmNscrollBarDisplayPolicy, XmAS_NEEDED,
                                      //XmNscrollingPolicy, XmAUTOMATIC,
                                      NULL);
  
  // Menu Bar
  Widget menuBar = XmCreateMenuBar(workArea, "MenuBar", NULL, 0);
 
  // File Menu
  Widget fileMenu = XmCreatePulldownMenu(menuBar, "fileMenu", NULL, 0);
  
  // File Cascade button
  xstr = XmStringCreateLocalized("File");
  //Widget fileCascade = XtVaCreateManagedWidget("File",
  XtVaCreateManagedWidget("File",
			  xmCascadeButtonWidgetClass, menuBar,
			  XmNlabelString, xstr,
			  XmNmnemonic, 'F',
			  XmNsubMenuId, fileMenu,
			  NULL);
  XmStringFree(xstr);
 
  // File > Open
  //Widget fileOpen = XtVaCreateManagedWidget("Open",
  XtVaCreateManagedWidget("Open",
			  xmPushButtonGadgetClass, fileMenu,
			  NULL);
 
  //XtAddCallback(fileOpen, XmNactivateCallback, (XtCallbackProc) &CNApp::openCB, this);
 
  // File > Save
  //Widget fileSave = XtVaCreateManagedWidget("Save",
  XtVaCreateManagedWidget("Save",
			  xmPushButtonGadgetClass, fileMenu,
			  NULL);
  // File | separator
  //Widget fileSep = XtVaCreateManagedWidget("separator",
  XtVaCreateManagedWidget("separator",
			  xmSeparatorGadgetClass, fileMenu,
			  NULL);

  // File > Redraw
  //Widget fileRedraw = XtVaCreateManagedWidget("Redraw",
  XtVaCreateManagedWidget("Redraw",
			  xmPushButtonGadgetClass, fileMenu,
			  NULL);
  //XtAddCallback(fileRedraw, XmNactivateCallback, (XtCallbackProc) redrawCB, NULL);

    // File > Exit
  Widget fileExit = XtVaCreateManagedWidget("Exit",
                                            xmPushButtonGadgetClass, fileMenu,
                                            NULL);
  XtAddCallback(fileExit, XmNactivateCallback, 
		(XtCallbackProc) SimplePixelCanvasApp::exitCB, NULL);
 
  // Help Menu
  Widget helpMenu = XmCreatePulldownMenu(menuBar, "helpMenu", NULL, 0);
  
   // Help Cascade button
  xstr = XmStringCreateLocalized("Help");
  //Widget helpCascade = XtVaCreateManagedWidget("Help",
  XtVaCreateManagedWidget("Help",
			  xmCascadeButtonWidgetClass, menuBar,
			  XmNlabelString, xstr,
			  XmNmnemonic, 'F',
			  XmNsubMenuId, helpMenu,
			  NULL);
  XmStringFree(xstr);
 
  // Help > Open
  //Widget helpOpen = XtVaCreateManagedWidget("Sorry... No help!",
  XtVaCreateManagedWidget("Sorry... No help!",
			  xmPushButtonGadgetClass, helpMenu,
			  NULL);
  XtManageChild (menuBar);
  
  return workArea;
}

void SimplePixelCanvasApp::run()
{
  XtRealizeWidget(toplevel_);
  XtAppMainLoop(app_);
}

// Destructor
SimplePixelCanvasApp::~SimplePixelCanvasApp()
{
}


Bool SimplePixelCanvasApp::ok() const
{
  return True;
}

//========================= Standardized Functions ============================

// write to ostream support
ostream & operator << (ostream & os, const SimplePixelCanvasApp &)
{
  // remove this warning when edited
  cerr << "Warning: class SimplePixelCanvasApp, ostream op << not completed";

  return os;
}

// write to AipsiO support
AipsIO & operator << (AipsIO & aio, const SimplePixelCanvasApp &)
{
  aio.putstart("SimplePixelCanvasApp", SimplePixelCanvasApp::SimplePixelCanvasAppVersion);
  
  // write values here.  check out aio.put

  // remove this warning when edited
  cerr << "Warning: class SimplePixelCanvasApp, AipsIO op << not completed";

  aio.putend();
  return aio;
}

// write to LogIO support
LogIO & operator << (LogIO & lio, const SimplePixelCanvasApp & spca)
{
  lio.output() << spca;
  return lio;
}
		     
// read from AipsIO support
AipsIO & operator >> (AipsIO & aio, SimplePixelCanvasApp &)
{
  if (aio.getstart("SimplePixelCanvasApp") != SimplePixelCanvasApp::SimplePixelCanvasAppVersion) 
    {
      throw(AipsError("AipsIO &operator>>(AipsIO &aio, SimplePixelCanvasApp &spca) - "
		      "version on disk and in class do not match"));
    }

  // read values, initialize structures.  check out aio.getnew
  
  // remove this warning when edited
  cerr << "Warning: class SimplePixelCanvasApp, AipsIO op >> not completed";
	
  aio.getend();

  return aio;
}


} //# NAMESPACE CASA - END

