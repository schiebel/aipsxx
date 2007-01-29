//# SimpleWorldGLCanvasApp.cc: basic stand-alone application with WorldCanvas
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
//#$Id $

#if defined(OGL)
#include <display/Display/SimpleWorldGLCanvasApp.h>
#include <graphics/X11/X_enter.h>
#include <X11/Intrinsic.h>
#include <X11/IntrinsicP.h>
#include <Xm/Xm.h>
#include <X11/CompositeP.h>
#include <X11/Shell.h>
#include <X11/ShellP.h>
#include <graphics/X11/X_exit.h>

#include <casa/Exceptions/Error.h>
#include <casa/IO/AipsIO.h>
#include <casa/Utilities/Assert.h>
#include <casa/aips.h>
#include <casa/Logging/LogIO.h>
#include <casa/iostream.h>
#include <display/Display/GLPixelCanvasColorTable.h>
#include <display/Display/GLPixelCanvas.h>

namespace casa { //# NAMESPACE CASA - BEGIN

/* SimpleWorldGLCanvasApp is meant to be a standalone application.

  In order to allow access to argc & argv before the AIPS++ arg scanner
and still allow parameters to affect the PixelCanvas, certain variables
are global to SimpleWorldGLCanvasApp instances. Even if there were more
than one instance of SimpleWorldGLCanvasApp, these could still be the
same. Since SimpleWorldGLCanvasApp is meant to be a standalone
application, the issue should never arise anyway.
*/

// The X Screen needed to build the PixelCanvasColorTable
Screen * SimpleWorldGLCanvasApp::screen_ = NULL;
// The application context for run()
XtAppContext SimpleWorldGLCanvasApp::app_ = NULL;
// The application shell. Parent to others, but probably doesn't use
// the desired visual. (Use toplevel as parent).
Widget SimpleWorldGLCanvasApp::appW_ = NULL;

// Default Constructor
SimpleWorldGLCanvasApp::SimpleWorldGLCanvasApp(
				const char *application_name,
				const Display::ColorModel colormodel,
				const Float percent)
{ int fakeargc=0;
  static const char *APPLICATION_CLASS_NAME = "SimpleWorldGLCanvasApp";
	className_ = APPLICATION_CLASS_NAME;

	openApplication(APPLICATION_CLASS_NAME, NULL, 0,
			&fakeargc, NULL,
			NULL, NULL, 0);
	initialize(colormodel, percent, application_name);
}

SimpleWorldGLCanvasApp::SimpleWorldGLCanvasApp(
			const char *application_name,
			const char *application_class_name,
			XrmOptionDescRec* options, Cardinal num_options,
			int *argc, char **argv,
			char **fallback_resources,
			ArgList args, Cardinal num_args,
			const Display::ColorModel colormodel,
			const Float percent)

{
	if(application_class_name == NULL)
		className_ = "SimpleWorldApp";
	else
		className_ = application_class_name;
	openApplication(application_class_name, options, num_options,
			argc, argv,
			fallback_resources, args, num_args);

	const char *an;
	if((application_name == NULL) && (argv != NULL))
		an = argv[0];
	else
		an = application_name;	// May be NULL.

	initialize(colormodel, percent, an);
}

// Make the initial connection to the X server.
void SimpleWorldGLCanvasApp::openApplication(
			 const char *className,
			 XrmOptionDescRec* options, Cardinal num_options,
			 int *argc, char **argv,
			 char **fallback_resources,
			 ArgList args, Cardinal num_args)
{
	if(app_ != NULL)	// Already opened?
		return;

	appW_ = XtOpenApplication(&app_, className,
				options, num_options,
				argc, argv,
				fallback_resources,
				applicationShellWidgetClass,
				args, num_args);

	XtSetLanguageProc(NULL, NULL, NULL);
	screen_ = XtScreen(appW_);
}

// Creates a colortable, builds the widgets, and finally a canvas.
void SimpleWorldGLCanvasApp::initialize(const Display::ColorModel colormodel,
					const Float percent,
					const char *appname)
{
  GLPixelCanvasColorTable * glct = 0; 
  
  try {
	glct = new GLPixelCanvasColorTable(XtDisplay(appW_), colormodel,
					   percent);
  } catch (AipsError x) {
	glct = 0;
  }
  
  if (glct == 0) throw(AipsError("Unable to build GLPixelCanvasColorTable."));
  glct_ = glct;

  Widget tb = buildWidget(appname);

  glPixelCanvas_ = new GLPixelCanvas(tb, glct, 400, 400);  
  pixelCanvas_ = glPixelCanvas_;

  worldCanvas_ = new WorldCanvas(pixelCanvas_);
}

void SimpleWorldGLCanvasApp::exitCB(Widget, XtPointer, XtPointer)
{ exit(0); }

void SimpleWorldGLCanvasApp::pcmapCB(Widget, XtPointer data, XtPointer) {
  ((SimpleWorldGLCanvasApp *)data)->printCmapInfo();
}

void SimpleWorldGLCanvasApp::traceCB(Widget, XtPointer data, XtPointer)
{
  SimpleWorldGLCanvasApp *me = (SimpleWorldGLCanvasApp *)data;
  if(me == NULL)
	return;
  GLPixelCanvas *c = me->glPixelCanvas();
	c->trace(!c->tracing());
}

void SimpleWorldGLCanvasApp::printCmapInfo() {
  PixelCanvas *pc = worldCanvas_->pixelCanvas();
  cout << "xpcctbl: " 
       << *((GLPixelCanvasColorTable *)(pc->pcctbl())) << endl;
  cout << "colormap: "
       << pc->colormap() << endl;
  cout << "Colormap Manager: " << endl;
  cout << pc->pcctbl()->colormapManager() << endl;

}

WorldCanvas *SimpleWorldGLCanvasApp::worldCanvas() 
{
  return worldCanvas_;
}

Widget SimpleWorldGLCanvasApp::buildWidget(const char *appname)
{ XmString xstr;

  if(appname == NULL)
	appname = "simpleWorldGLCanvas";
  // Create a top level widget with the desired visual.
  // (Only top level widgets take the visual arg).
  toplevel_ = XtVaAppCreateShell(appname, className_.chars(),
			topLevelShellWidgetClass, XtDisplay(appW_),
			NULL);
  Widget workArea = XtVaCreateManagedWidget("mainWindow",
                                      xmMainWindowWidgetClass, toplevel_,
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
  Widget fileRedraw = XtVaCreateManagedWidget("Redraw",
			  xmPushButtonGadgetClass, fileMenu,
			  NULL);
  XtAddCallback(fileRedraw, XmNactivateCallback, (XtCallbackProc) redrawCB,
		(XtPointer)this);

    // File > Exit
  Widget fileExit = XtVaCreateManagedWidget("Exit",
                                            xmPushButtonGadgetClass, fileMenu,
                                            NULL);
  XtAddCallback(fileExit, XmNactivateCallback, 
		(XtCallbackProc) SimpleWorldGLCanvasApp::exitCB, NULL);
 
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
		(XtCallbackProc) SimpleWorldGLCanvasApp::pcmapCB,
		(XtPointer)this);

#if 0
  // This works except that once tracing is enabled, it stays until
  // the traced object is regenerated (usually via a window resize).
  Widget helpToggleTrace = XtVaCreateManagedWidget("Toggle Tracing",
						     xmPushButtonGadgetClass,
						     helpMenu, NULL);
  XtAddCallback(helpToggleTrace, XmNactivateCallback,
		(XtCallbackProc) SimpleWorldGLCanvasApp::traceCB,
		(XtPointer)this);
#endif

  // Help > Open
  //Widget helpOpen = XtVaCreateManagedWidget("Sorry... No help!",
  XtVaCreateManagedWidget("Sorry... No help!",
			  xmPushButtonGadgetClass, helpMenu,
			  NULL);
  XtManageChild (menuBar);
  
  return workArea;
}

void SimpleWorldGLCanvasApp::run()
{
  XtRealizeWidget(toplevel_);
  XtAppMainLoop(app_);
}

// Destructor
SimpleWorldGLCanvasApp::~SimpleWorldGLCanvasApp()
{
	delete glct_;
	delete pixelCanvas_;
}


Bool SimpleWorldGLCanvasApp::ok() const
{
  return True;
}

void SimpleWorldGLCanvasApp::redrawCB(Widget, XtPointer me, XtPointer)
{
	if(me != NULL)
	{ SimpleWorldGLCanvasApp *sca = (SimpleWorldGLCanvasApp *)me;
		sca->glPixelCanvas_->redraw();
	}
}

//========================= Standardized Functions ============================

// write to ostream support
ostream & operator << (ostream & os, const SimpleWorldGLCanvasApp &)
{
  // remove this warning when edited
  cerr << "Warning: class SimpleWorldGLCanvasApp, ostream op << not completed";

  return os;
}

// write to AipsiO support
AipsIO & operator << (AipsIO & aio, const SimpleWorldGLCanvasApp &)
{
  aio.putstart("SimpleWorldGLCanvasApp", SimpleWorldGLCanvasApp::SimpleWorldGLCanvasAppVersion);
  
  // write values here.  check out aio.put

  // remove this warning when edited
  cerr << "Warning: class SimpleWorldGLCanvasApp, AipsIO op << not completed";

  aio.putend();
  return aio;
}

// write to LogIO support
LogIO & operator << (LogIO & lio, const SimpleWorldGLCanvasApp & spca)
{
  lio.output() << spca;
  return lio;
}
		     
// read from AipsIO support
AipsIO & operator >> (AipsIO & aio, SimpleWorldGLCanvasApp &)
{
  if (aio.getstart("SimpleWorldGLCanvasApp") != SimpleWorldGLCanvasApp::SimpleWorldGLCanvasAppVersion) 
    {
      throw(AipsError("AipsIO &operator>>(AipsIO &aio, SimpleWorldGLCanvasApp &spca) - "
		      "version on disk and in class do not match"));
    }

  // read values, initialize structures.  check out aio.getnew
  
  // remove this warning when edited
  cerr << "Warning: class SimpleWorldGLCanvasApp, AipsIO op >> not completed";
	
  aio.getend();

  return aio;
}

} //# NAMESPACE CASA - END

#endif // OGL
