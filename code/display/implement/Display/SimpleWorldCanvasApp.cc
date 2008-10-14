//# SimpleWorldCanvasApp.cc: basic stand-alone application with WorldCanvas
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
//#$Id: SimpleWorldCanvasApp.cc,v 19.4 2005/06/15 17:56:31 cvsmgr Exp $

#include <display/Display/SimpleWorldCanvasApp.h>
#include <casa/Exceptions/Error.h>
#include <casa/IO/AipsIO.h>
#include <casa/Utilities/Assert.h>
#include <casa/Logging/LogIO.h>
#include <casa/iostream.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Default Constructor Required
SimpleWorldCanvasApp::SimpleWorldCanvasApp(const Display::ColorModel
					   &colormodel)
{
  int fakeArgc = 0;
  toplevel_ = XtVaAppInitialize(&app_, "simple app", NULL, 0,
				&fakeArgc, NULL, NULL, NULL);
  XtSetLanguageProc(NULL, NULL, NULL);
  screen_ = XtScreen(toplevel_);

  Widget tb = buildWidget(toplevel_);

  X11PixelCanvasColorTable * xch = 0; 
  
  switch (colormodel) {
  case Display::Index: 
    {
      try {
	xch = new X11PixelCanvasColorTable(screen_, Display::Index,
					   Display::Percent, Display::System,
					   (float)50.0);
      } catch (AipsError x) {
	xch = 0;
      } 
      
      if (xch == 0) {
	try {
	  xch = new X11PixelCanvasColorTable(screen_, Display::Index,
					     Display::Percent, Display::New,
					     (float)50.0);
	} catch (AipsError x) {
	  xch = 0;
	} 
      }
    }
    break;
  case Display::RGB:
  case Display::HSV:
    {
      try {
	xch = new X11PixelCanvasColorTable(screen_, colormodel,
					   Display::Percent, Display::System,
					   (float)90.0);
      } catch (AipsError x) {
	xch = 0;
      } 
      if (xch == 0) {
	try {
	  xch = new X11PixelCanvasColorTable(screen_, colormodel,
					     Display::Percent, Display::New,
					     (float)90.0);
	} catch (AipsError x) {
	  xch = 0;
	} 
      }
    }
    break;
  default:
    throw(AipsError("Unknown ColorModel given to SimpleWorldCanvasApp"));
  }
  
  if (xch == 0) throw(AipsError("Unable to build pcct..."));

  pixelCanvas_ = new X11PixelCanvas(tb, xch, 400, 400);  

  worldCanvas_ = new WorldCanvas(pixelCanvas_);

}

void SimpleWorldCanvasApp::exitCB(Widget, XtPointer, XtPointer)
{ exit(0); }

void SimpleWorldCanvasApp::pcmapCB(Widget, XtPointer data, XtPointer) {
  ((SimpleWorldCanvasApp *)data)->printCmapInfo();
}

void SimpleWorldCanvasApp::printCmapInfo() {
  PixelCanvas *pc = worldCanvas_->pixelCanvas();
  cout << "xpcctbl: " 
       << *((X11PixelCanvasColorTable *)(pc->pcctbl())) << endl;
  cout << "colormap: "
       << pc->colormap() << endl;
  cout << "Colormap Manager: " << endl;
  cout << pc->pcctbl()->colormapManager() << endl;

}

WorldCanvas *SimpleWorldCanvasApp::worldCanvas() 
{
  return worldCanvas_;
}

Widget SimpleWorldCanvasApp::buildWidget(Widget parent)
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
		(XtCallbackProc) SimpleWorldCanvasApp::exitCB, NULL);
 
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

  Widget helpPrintColormap = XtVaCreateManagedWidget("Print colourmap info",
						     xmPushButtonGadgetClass,
						     helpMenu, NULL);
  XtAddCallback(helpPrintColormap, XmNactivateCallback,
		(XtCallbackProc) SimpleWorldCanvasApp::pcmapCB,
		(XtPointer)this);
 
  // Help > Open
  //Widget helpOpen = XtVaCreateManagedWidget("Sorry... No help!",
  XtVaCreateManagedWidget("Sorry... No help!",
			  xmPushButtonGadgetClass, helpMenu,
			  NULL);
  XtManageChild (menuBar);
  
  return workArea;
}

void SimpleWorldCanvasApp::run()
{
  XtRealizeWidget(toplevel_);
  XtAppMainLoop(app_);
}

// Destructor
SimpleWorldCanvasApp::~SimpleWorldCanvasApp()
{
}


Bool SimpleWorldCanvasApp::ok() const
{
  return True;
}

//========================= Standardized Functions ============================

// write to ostream support
ostream & operator << (ostream & os, const SimpleWorldCanvasApp &)
{
  // remove this warning when edited
  cerr << "Warning: class SimpleWorldCanvasApp, ostream op << not completed";

  return os;
}

// write to AipsiO support
AipsIO & operator << (AipsIO & aio, const SimpleWorldCanvasApp &)
{
  aio.putstart("SimpleWorldCanvasApp", SimpleWorldCanvasApp::SimpleWorldCanvasAppVersion);
  
  // write values here.  check out aio.put

  // remove this warning when edited
  cerr << "Warning: class SimpleWorldCanvasApp, AipsIO op << not completed";

  aio.putend();
  return aio;
}

// write to LogIO support
LogIO & operator << (LogIO & lio, const SimpleWorldCanvasApp & spca)
{
  lio.output() << spca;
  return lio;
}
		     
// read from AipsIO support
AipsIO & operator >> (AipsIO & aio, SimpleWorldCanvasApp &)
{
  if (aio.getstart("SimpleWorldCanvasApp") != SimpleWorldCanvasApp::SimpleWorldCanvasAppVersion) 
    {
      throw(AipsError("AipsIO &operator>>(AipsIO &aio, SimpleWorldCanvasApp &spca) - "
		      "version on disk and in class do not match"));
    }

  // read values, initialize structures.  check out aio.getnew
  
  // remove this warning when edited
  cerr << "Warning: class SimpleWorldCanvasApp, AipsIO op >> not completed";
	
  aio.getend();

  return aio;
}


} //# NAMESPACE CASA - END

