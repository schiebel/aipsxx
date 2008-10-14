//# PGPlot1d.cc: PGPlot is one of two plotting widgets available for AIPS++
//# Copyright (C) 1993,1994,1995,1997,1999,2000,2001,2002,2003
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
//# $Id: PGPlot1d.cc,v 19.4 2004/11/30 17:50:25 ddebonis Exp $

#include <unistd.h>
#include <graphics/X11/X11Util.h>
#include <graphics/X11/X_enter.h>
#include <X11/Xlib.h>
#include <X11/Intrinsic.h>
#include <X11/StringDefs.h>
#include <X11/keysym.h>
#include <Xm/Xm.h>
#include <Xm/MainW.h>
#include <Xm/Text.h>
#include <Xm/Form.h>
#include <Xm/PushB.h>
#include <Xm/Separator.h>
#include <Xm/Frame.h>
#include <Xm/RowColumn.h>
#include <Xm/Label.h>
#include <Xm/ToggleB.h>
#include <Xm/RowColumn.h>
#include <Xm/CascadeB.h>
#include <Xm/ScrolledW.h>
#include <XmPgplot.h>
#include <graphics/X11/X_exit.h>

#include <casa/iostream.h>
#include <casa/aips.h>

#include <casa/Arrays/ArrayMath.h>
#include <graphics/Graphics/PGPlot1d.h>
#include <casa/System/Aipsrc.h>
#include <casa/OS/EnvVar.h>

namespace casa { //# NAMESPACE CASA - BEGIN

// Failed using MAX_FLOAT
#define PLT_POS_INF 1e30
#define PLT_NEG_INF -1e30

static char *PGPlotLineColors1[8] =
{
  "red","tan","lime green","medium turquoise",
  "blue","magenta","green yellow","medium blue"
};
static char *PGPlotPointColors1[8] =
{
  "magenta","green","medium blue","red",
  "red","medium blue","magenta","light sky blue"
};
static char *PGPlotLineColors2[8] =
{
  "steel blue","medium violet red","plum","aquamarine",
  "cadet blue","khaki","light blue","medium orchid"
};
static char *PGPlotPointColors2[8] =
{
  "orange","olive drab","red","yellow green",
  "sky blue","green","gold","magenta"
};
static PGPlot1dDataAttr::PointStyle PGPlotPointStyles1[8] =
{
  PGPlot1dDataAttr::PS_TRIANGLE, PGPlot1dDataAttr::PS_BOX, 
  PGPlot1dDataAttr::PS_DOT, PGPlot1dDataAttr::PS_DIAMOND, 
  PGPlot1dDataAttr::PS_STAR, PGPlot1dDataAttr::PS_TRIANGLE, 
  PGPlot1dDataAttr::PS_BOX, PGPlot1dDataAttr::PS_DOT
};
static PGPlot1dDataAttr::PointStyle PGPlotPointStyles2[8] =
{
  PGPlot1dDataAttr::PS_DOT, PGPlot1dDataAttr::PS_DIAMOND, 
  PGPlot1dDataAttr::PS_STAR, PGPlot1dDataAttr::PS_BOX, 
  PGPlot1dDataAttr::PS_TRIANGLE, PGPlot1dDataAttr::PS_DOT, 
  PGPlot1dDataAttr::PS_DIAMOND, PGPlot1dDataAttr::PS_STAR
};


PGPlot1d::PGPlot1d(Widget parent) :

  maxColors_(PGPlot1d_MAX_COLORS),
  nColors_(0),

  cursorXRef_(0),
  cursorYRef_(0),
  cursorMode_(XMP_CROSS_CURSOR),
  cursorActive_(0),
  cursorActiveMode_(XMP_RECT_CURSOR),
  cursorInactiveMode_(XMP_CROSS_CURSOR),
  cursorInWindow_(0),
  cursorColor_(3),
  selectionColor_(3),

  dataSetAttrList_(0),
  dataSetAttrIterator_(0),

  parent_(parent),
  y2PlotPrepped_(False),

  xAxisGrid_ (False),
  y1AxisGrid_ (False),
  y2AxisGrid_ (False),

  topXAxis_(True),
  rightY1Axis_(True),  // show Y1 axis on right side if no y2 data
  leftY2Axis_(True),   // show y2 axis on left sice if no y1 data

  xAxisColor_(1),
  y1AxisColor_(1),
  y2AxisColor_(6),

  xAxisLineWidth_(3),
  y1AxisLineWidth_(2),
  y2AxisLineWidth_(2),

  xAxisGridLineWidth_(1),
  y1AxisGridLineWidth_(1),
  y2AxisGridLineWidth_(2),

  xAxisGridLineStyle_(LS_DASHED),
  y1AxisGridLineStyle_(LS_DASHED),
  y2AxisGridLineStyle_(LS_DOTTED),

  xAxisGridColor_(1),
  y1AxisGridColor_(1),
  y2AxisGridColor_(6),

  plotTitleFont_(FNT_NORMAL),
  xAxisLabelFont_(FNT_NORMAL),
  y1AxisLabelFont_(FNT_NORMAL),
  y2AxisLabelFont_(FNT_NORMAL),

  plotTitleColor_(1),
  xAxisLabelColor_(1),
  y1AxisLabelColor_(1),
  y2AxisLabelColor_(6),

  plotIdStringColor_(1),
  plotIdString_(True),

  showSelections_(True),

  printLandscape_(True),
  printColor_(True)

{
  initializeWidgets(parent);
  addStandardColors();
  dataSetAttrList_ = new List <PGPlot1dDataAttr *>();
  dataSetAttrIterator_ = new ListIter <PGPlot1dDataAttr *> (dataSetAttrList_);
  y1StyleTable_.resize(8);
  y2StyleTable_.resize(8);
  for (Int i = 0; i < 8; i++)
    {
      y1StyleTable_(i) = 0;
      y2StyleTable_(i) = 0;
    }
}

void PGPlot1d::initializeWidgets (Widget parent)
{
  // Decide which colormap to use: the parent's colormap
  // or a new one for w_main.
  ::XDisplay * display = XtDisplay(parent);
  Screen * screen = XtScreen(parent);

  XColormap cmap = 0;
  setwm_ = False;

  XtVaGetValues(parent, XmNcolormap, &cmap, NULL);

  //cout << "colormap is" << cmap << endl;
  //cout << "screen is" << screen << endl;

  if (Int(X11QueryColorsAvailable(display, cmap, True)) < maxColors_ + 10)
    {
      // make a new colormap for w_main
      cmap = XCreateColormap(display, 
			     RootWindowOfScreen(screen),
			     DefaultVisualOfScreen(screen), 
			     AllocNone);
#ifdef AIPS_DEBUG
      uint ncolors = X11QueryColorsAvailable(display, cmap, True);
      cout << "PGPlot1d: using private colormap (" << cmap << ") with " << ncolors << " available colors." << endl;
#endif
      setwm_ = True;
    }
  else
    {
#ifdef AIPS_DEBUG
      uint ncolors = X11QueryColorsAvailable(display, cmap, True);
      cout << "PGPlot1d: using parent colormap (" << cmap << ") with " << ncolors << " available colors" << endl;
#endif
    }

  XmString fileMenuString, quitMenuString, printMenuString;
  fileMenuString = XmStringCreateLocalized ("File");
  printMenuString = XmStringCreateLocalized ("Print");
  quitMenuString = XmStringCreateLocalized ("Quit");

  w_main_ = XtVaCreateManagedWidget ("mainWindow", 
				     xmMainWindowWidgetClass,
				     parent, 
				     XmNcolormap, cmap,
				     NULL);

  // Main | menubar

  Widget w_menubar = XmCreateMenuBar (w_main_, "menubar", NULL, 0);

  XtVaSetValues (w_main_, XmNmenuBar, w_menubar, NULL);

  Widget w_fileSubmenu = XmCreatePulldownMenu (w_menubar, "fileSubmenu", NULL, 0);

  Widget w_printButton = XtVaCreateManagedWidget ("Print", xmPushButtonWidgetClass,
					  w_fileSubmenu,
					  NULL);
  XtAddCallback(w_printButton, XmNactivateCallback,
		printCB, (XtPointer) this);

  Widget w_quitButton = XtCreateManagedWidget ("Quit", xmPushButtonWidgetClass,
					w_fileSubmenu, NULL, 0);
  XtAddCallback(w_quitButton, XmNactivateCallback, quitCB, (XtPointer) this);

  XtManageChild (w_menubar);

  XmStringFree (fileMenuString);
  XmStringFree (printMenuString);
  XmStringFree (quitMenuString);

  // ------------------------


  Widget w_outerForm =
    XtVaCreateManagedWidget ("outerForm", xmFormWidgetClass, w_main_,
                               NULL);
  Widget w_commandsForm =
    XtVaCreateManagedWidget ("commandsForm", xmFormWidgetClass, w_outerForm,
                             XmNtopAttachment,         XmATTACH_FORM,
                             XmNleftAttachment,        XmATTACH_FORM,
                             XmNrightAttachment,       XmATTACH_FORM,
                             NULL);
    
  Widget w_plotterForm =
    XtVaCreateManagedWidget ("plotterForm", xmFormWidgetClass, w_outerForm,
                             NULL);


  Widget w_buttonContainer =
    XtVaCreateManagedWidget ("buttonContainer",
                             xmRowColumnWidgetClass,  w_commandsForm,
                             NULL);

  Widget w_fullViewButton =
    XtVaCreateManagedWidget ("fullViewButton",
                             xmPushButtonWidgetClass,  w_buttonContainer,
                             //XmNsensitive,             False,
                             NULL);
  XtAddCallback(w_fullViewButton, XmNactivateCallback, fullViewCB, (XtPointer)this);

  Widget w_clearSelectionButton =
    XtVaCreateManagedWidget ("clearSelectionButton",
                             xmPushButtonWidgetClass,  w_buttonContainer,
                             //XmNsensitive,             False,
                             NULL);

  XtAddCallback (w_clearSelectionButton, XmNactivateCallback, 
		 clearSelectionsCB, (XtPointer) this);

  Widget w_clearPlotButton =
    XtVaCreateManagedWidget ("clearPlotButton",
                             xmPushButtonWidgetClass,  w_buttonContainer,
                             XmNsensitive,             True,
                             NULL);
  XtAddCallback (w_clearPlotButton, XmNactivateCallback,
		 clearCB, (XtPointer) this);


  // -----------------------------
  Widget w_setDragObjectFrame =
    XtVaCreateManagedWidget ("setDragObjectFrame", xmFrameWidgetClass,
                             w_commandsForm, NULL);

  Widget w_setDragObjectRadioBox = XmCreateRadioBox (w_setDragObjectFrame,
                                              "setDragObjectRadioBox",
                                              NULL, 0);
  Widget w_selectXAxisButton =
    XtVaCreateManagedWidget ("selectXAxisButton", xmToggleButtonWidgetClass,
                             w_setDragObjectRadioBox,
                             NULL);
  XtAddCallback (w_selectXAxisButton, XmNvalueChangedCallback,
		 selectXAxisCB, (XtPointer) this);

  Widget w_selectYAxisButton =
    XtVaCreateManagedWidget ("selectYAxisButton", xmToggleButtonWidgetClass,
                            w_setDragObjectRadioBox, NULL);
  XtAddCallback (w_selectYAxisButton, XmNvalueChangedCallback,
		 selectYAxisCB, (XtPointer) this);

  Widget w_selectBoxButton =
    XtVaCreateManagedWidget ("selectBoxButton", xmToggleButtonWidgetClass,
                             w_setDragObjectRadioBox, NULL);
  XtAddCallback (w_selectBoxButton, XmNvalueChangedCallback,
		 selectBoxCB, (XtPointer) this);

  XtManageChild (w_setDragObjectRadioBox);
  XmToggleButtonSetState (w_selectXAxisButton, True, True);

  // -------------------------------

  Widget w_setDragModeFrame =
    XtVaCreateManagedWidget ("setDragModeFrame", xmFrameWidgetClass,
                             w_commandsForm, NULL);
  
  Widget w_setDragModeRadioBox = XmCreateRadioBox (w_setDragModeFrame,
                                           "setDragModeRadioBox",
                                           NULL, 0);
  Widget w_setZoomButton =
    XtVaCreateManagedWidget ("setZoomButton", xmToggleButtonWidgetClass,
                             w_setDragModeRadioBox,
                             NULL);
  XtAddCallback(w_setZoomButton, XmNvalueChangedCallback,
		setZoomDragModeCB, (XtPointer) this);

  Widget w_setSelectDataButton =
    XtVaCreateManagedWidget ("setSelectDataButton", xmToggleButtonWidgetClass,
                             w_setDragModeRadioBox, NULL);
  XtAddCallback(w_setSelectDataButton, XmNvalueChangedCallback,
		setSelectDataDragModeCB, (XtPointer) this);
  
  XtManageChild (w_setDragModeRadioBox);
  XmToggleButtonSetState  (w_setZoomButton, True, True);

  // ---------------------------------
  
  w_y1readout_ =
    XtVaCreateManagedWidget ("y1readout", xmTextWidgetClass, w_plotterForm,
                             NULL);
  w_x1readout_ =
    XtVaCreateManagedWidget ("x1readout", xmTextWidgetClass, w_plotterForm,
                             NULL);

    // only plots with 2 Y axes need an extra pair of readouts.
    // these 2 Y axes will ususally have very different range

  w_y2readout_ = XtVaCreateManagedWidget ("y2readout", xmTextWidgetClass,
                                        w_plotterForm, NULL);
  w_x2readout_ = XtVaCreateManagedWidget ("x2readout", xmTextWidgetClass,
                                         w_plotterForm, NULL);

  // ----------------------------------


  w_plot_ = XtVaCreateManagedWidget("plot",
				    xmPgplotWidgetClass, w_plotterForm,
				    XmNheight, 300,
				    XmNwidth, 300,
				    XmpNmaxColors, maxColors_,
				    //XmpNinheritVisual, XmpParentVisual,
				    NULL);

  

  XtAddCallback(w_plot_, XmNresizeCallback, 
		(XtCallbackProc) &PGPlot1d::resizeCB, 
		(XtPointer) this);

  XtAddEventHandler(w_plot_, LeaveWindowMask, False, 
		    &PGPlot1d::leaveNotifyEH, this);

  XtAddEventHandler(w_plot_, EnterWindowMask, False, 
		    &PGPlot1d::enterNotifyEH, this);

  XtAddEventHandler(w_plot_, PointerMotionMask, False,
  		    &PGPlot1d::motionNotifyEH, this);

  XtRealizeWidget(parent);

  //cout << "Opening '" << xmp_device_name(w_plot_) << "'." << endl;
  if (cpgopen(xmp_device_name(w_plot_)) <= 0)
    {
      cerr << "error opening PGPLOT" << endl;
    }

  redraw();
}

void PGPlot1d::addStandardColors()
{
  cpgslct(xmp_device_id(w_plot_));

  colorNameTable_.resize(maxColors_);
  for (int i = 0; i < maxColors_; i++)
    {
      colorNameTable_(i) = "";
    }

  // First two defined colors are background and foreground

  addColor("white");
  addColor("black");
  addColor("red");
  addColor("green");
  addColor("blue");
  addColor("cyan");
  addColor("magenta");
  addColor("yellow");
  addColor("orange");
  addColor("tan");
  addColor("lime green");
  addColor("medium blue");
  addColor("green yellow");
  addColor("light sky blue");
  addColor("steel blue");
  addColor("medium violet red");
  addColor("olive drab");
  addColor("plum");
  addColor("aquamarine");
  addColor("yellow green");
  addColor("cadet blue");
  addColor("sky blue");
  addColor("khaki");
  addColor("light blue");
  addColor("gold");
  addColor("medium orchid");
  addColor("medium turquoise");
}

int PGPlot1d::addColor(const String& str)
{
  String s = downcase(str);
  int cindex;
  if ((cindex = searchColor(s)) == -1)
    {
      if (nColors_ == maxColors_)
	{
	  cout << "%PGPlot1d: color table full!" << endl;
	  return -1;
	}

      XColor exact, closest;
      XColormap cm;
      XtVaGetValues(w_plot_, XtNcolormap, &cm, NULL);
      // cout << "PGPlot's colormap is # " << cm << endl;
      if ((XLookupColor(XtDisplay(w_plot_),
			cm,
			s.chars(),
			&exact,
			&closest)) == 0)
	{
	  cout << "%PGPlot1d: don't know color '" << s.chars() << "'." << endl;
	  return -1;
	}

      float r = (float) exact.red / 65536.0;
      float g = (float) exact.green / 65536.0;
      float b = (float) exact.blue / 65536.0;

      if (nColors_ >= 27)
	{
	  cout << "%PGPlot1d: adding color '" << s.chars() << "': (" 
	       << nColors_ << " of " << maxColors_ << ")." << endl;
	}

      colorNameTable_(nColors_) = s;
      cpgscr(nColors_,r,g,b);
      nColors_++;
      return nColors_-1;
    }
  else
    {
      cout << "color " << s.chars() << " already in table!" << endl;
      return cindex;
    }
}

int PGPlot1d::searchColor(const String& str)
{
  String s = downcase(str);
  for (int i = 0; i < nColors_; i++)
    {
      if (colorNameTable_(i) == s)
	return i;
    }
  return -1;
}

/* static */
void PGPlot1d::leaveNotifyEH(Widget, XtPointer pthis, XEvent *, Boolean *)
{
  //cout << "leave notify" << endl;
  ((PGPlot1d *) pthis)->leaveNotify();
}
void PGPlot1d::leaveNotify()
{
  cpgslct(xmp_device_id(w_plot_));
  xmp_disarm_cursor(w_plot_);
  cursorMode_ = XMP_NORM_CURSOR;
  cursorInWindow_ = False;
}

/* static */
void PGPlot1d::enterNotifyEH(Widget, XtPointer pthis, XEvent *, Boolean *)
{
  //cout << "enter notify" << endl;
  ((PGPlot1d *) pthis)->enterNotify();
}
void PGPlot1d::enterNotify()
{
  cursorMode_ = (cursorActive_) ? cursorActiveMode_ : cursorInactiveMode_;
  armCursor(cursorMode_, cursorXRef_, cursorYRef_);
  cursorInWindow_ = True;
}

void PGPlot1d::motionNotifyEH(Widget, XtPointer self, XEvent * ev, Boolean *)
{
  ((PGPlot1d *) self)->motionNotify(ev->xmotion.x, ev->xmotion.y);
}
void PGPlot1d::motionNotify(int x, int y)
{
  // cout << "motion notify <" << x << "," << y << ">." << endl;
  // Bounce event to Motif driver to get WC info

  XKeyPressedEvent event;
  event.type = KeyPress;
  event.display = XtDisplay(w_plot_);
  event.window = XtWindow(w_plot_);
  event.root = XtWindow(parent_);
  event.subwindow = XtWindow(w_plot_);
  event.x = x;
  event.y = y;
  event.x_root = x;
  event.y_root = y;
  event.time = CurrentTime;
  event.keycode = XKeysymToKeycode(XtDisplay(w_plot_), XK_bracketleft);
  XSendEvent(XtDisplay(w_plot_), 
	     XtWindow(w_plot_),
	     True,  // propagate
	     KeyPressMask,
	     (XEvent *) &event);
}

void PGPlot1d::resizeCB(Widget, PGPlot1d * p1d, XtPointer)
{
  p1d->redraw();
}

void PGPlot1d::drawCB(Widget, PGPlot1d *p1d, XtPointer)
{
  p1d->redraw();
}

void PGPlot1d::cursorInputCB(Widget, 
			    void * p1d,
			    void * cursor)
{
  //cout.flush();
  //cout << "cursor input" << endl;
  ((PGPlot1d *) p1d)->cursorInput((XmpCursorCallbackStruct *) cursor);
}

//
//
//  INTERACTIVE FUNCTIONS
//
//

void PGPlot1d::selectRegion(float x1, float x2, float y1, float y2)
{
  // printf("selectRegion from <%f,%f> to <%f,%f> \n", x1,x2,y1,y2);

  float xa = min(x1,x2);
  float xb = max(x1,x2);
  float ya = min(y1,y2);
  float yb = max(y1,y2);

  // printf("selectRegion from <%f,%f> to <%f,%f> \n", xa,xb,ya,yb);

  redrawEnter();
  
  // PGPLOT is (at the moment) single precision, dataSel is double
  // so have to enforce this across the boundaries.

  Plot1d::recordDataSelection((Double)xa,
			      (Double)ya,
			      (Double)xb,
			      (Double)yb);
  redrawExit();
}


void PGPlot1d::setCursorInactiveMode(int mode)
{
  if (mode == XMP_NORM_CURSOR || mode == XMP_HLINE_CURSOR ||
      mode == XMP_VLINE_CURSOR || mode == XMP_CROSS_CURSOR)
    {
      if (cursorInWindow_)
	{
	  cursorActive_ = 0;
	  disarmCursor();
	  cursorInactiveMode_ = mode;
	  cursorMode_ = cursorInactiveMode_;
	  armCursor(cursorMode_, cursorXRef_, cursorYRef_);
	}
      else
	{
	  cursorInactiveMode_ = mode;
	}
    }
}

void PGPlot1d::setCursorActiveMode(int mode)
{
  if (mode == XMP_RECT_CURSOR || mode == XMP_XRNG_CURSOR ||
      mode == XMP_YRNG_CURSOR)
    {
      if (cursorInWindow_)
	{
	  cursorActive_ = 0;
	  disarmCursor();
	  cursorActiveMode_ = mode;
	  cursorMode_ = cursorInactiveMode_;
	  armCursor(cursorMode_, cursorXRef_, cursorYRef_);
	}
      else
	{
	  cursorActiveMode_ = mode;
	}
    }
}

// static
void PGPlot1d::quitCB(Widget, XtPointer, XtPointer)
{
  exit(0);
}
void PGPlot1d::printCB(Widget, XtPointer self, XtPointer)
{
  ((PGPlot1d *) self)->printGraphToPrinter();
}
void PGPlot1d::fullViewCB(Widget, XtPointer self, XtPointer)
{
  ((PGPlot1d *) self)->setFullScale();
}
void PGPlot1d::clearSelectionsCB(Widget, XtPointer self, XtPointer)
{
  ((PGPlot1d *) self)->clearSelections();
}
void PGPlot1d::clearCB(Widget, XtPointer self, XtPointer)
{
  ((PGPlot1d *) self)->clear();
}
void PGPlot1d::selectXAxisCB(Widget, XtPointer xself, XtPointer)
{
  PGPlot1d * self = (PGPlot1d *) xself;
  self->setCursorInactiveMode(XMP_VLINE_CURSOR);
  self->setCursorActiveMode(XMP_XRNG_CURSOR);
}
void PGPlot1d::selectYAxisCB(Widget, XtPointer xself, XtPointer)
{
  PGPlot1d * self = (PGPlot1d *) xself;
  self->setCursorInactiveMode(XMP_HLINE_CURSOR);
  self->setCursorActiveMode(XMP_YRNG_CURSOR);
}
void PGPlot1d::selectBoxCB(Widget, XtPointer xself, XtPointer)
{
  PGPlot1d * self = (PGPlot1d *) xself;
  self->setCursorInactiveMode(XMP_CROSS_CURSOR);
  self->setCursorActiveMode(XMP_RECT_CURSOR);
}
void PGPlot1d::setZoomDragModeCB(Widget, XtPointer self, XtPointer)
{
  ((PGPlot1d *) self)->setDragMode(Plot1d::zoom);
}
void PGPlot1d::setSelectDataDragModeCB(Widget, XtPointer self, XtPointer)
{
  ((PGPlot1d *) self)->setDragMode(Plot1d::selectData);
}

void PGPlot1d::cursorInput(XmpCursorCallbackStruct * cursor)
{
  //cout << "cursorInput" << endl;
  //cout << ": received key " << cursor->key <<
  //  ", selected at position (" << cursor->x << "," << cursor->y
  //  << ")." << endl;

  // map first mouse button according to dragmode
  if (cursor->key == 'A')
    {
      if (dragMode() == zoom) 
	cursor->key = 'D';
      else if (dragMode() == selectData)
	cursor->key = 'X';
    } 

  switch(cursor->key)
    {
    case 'D':
      // zoom to region
      if (cursorActive_ == 0)
	{
	  cursorActive_ = 1;
	  cursorMode_ = cursorActiveMode_;
	  
	  cursorXRef_ = cursor->x;
	  cursorYRef_ = cursor->y;

	  armCursor(cursorMode_, cursor->x, cursor->y);
	}
      else
	{
	  switch(cursorMode_)
	    {
	    case XMP_CROSS_CURSOR:
	    case XMP_NORM_CURSOR:
	    case XMP_HLINE_CURSOR:
	    case XMP_VLINE_CURSOR:
	    case XMP_LINE_CURSOR:
	      break;
	    case XMP_XRNG_CURSOR:
	      setXScale(cursorXRef_, cursor->x);
	      break;
	    case XMP_YRNG_CURSOR:
	      setYScale(cursorYRef_, cursor->y);
	      // [ ] adjust y2 proportionally
	      break;
	    case XMP_RECT_CURSOR:
	      redrawEnter();
	      setXScale(cursorXRef_, cursor->x);
	      setYScale(cursorYRef_, cursor->y);
	      redrawExit();
	      // [ ] adjust y2 proportionally
	      break;
	    }
	  cursorActive_ = 0;
	  cursorMode_ = cursorInactiveMode_;
	  armCursor(cursorMode_, cursor->x, cursor->y);
	}	
      break;

    case 'X':
      // cursor type defines how we are selecting points
      if (cursorActive_ == 0)
	{
	  cursorActive_ = 1;
	  cursorMode_ = cursorActiveMode_;
	  
	  cursorXRef_ = cursor->x;
	  cursorYRef_ = cursor->y;
	  
	  armCursor(cursorMode_, cursor->x, cursor->y);
	} 
      else
	{
	  switch(cursorMode_)
	    {
	    case XMP_CROSS_CURSOR:
	    case XMP_NORM_CURSOR:
	    case XMP_HLINE_CURSOR:
	    case XMP_VLINE_CURSOR:
	    case XMP_LINE_CURSOR:
	      break;
	    case XMP_XRNG_CURSOR:
	      //cout << "PLT_NEG_INF: " << PLT_NEG_INF << "PLT_POS_INF: " << PLT_POS_INF << endl;
	      selectRegion(cursorXRef_, cursor->x, PLT_NEG_INF, PLT_POS_INF);
	      break;
	    case XMP_YRNG_CURSOR:
	      selectRegion(PLT_NEG_INF, PLT_POS_INF, cursorYRef_, cursor->y); 
	      break;
	    case XMP_RECT_CURSOR:
	      selectRegion(cursorXRef_, cursor->x, cursorYRef_, cursor->y);
	      break;
	    }
	  
	  cursorActive_ = 0;
	  cursorMode_ = cursorInactiveMode_;
	  armCursor(cursorMode_, cursor->x, cursor->y);
	}
      break;
    case '[':
      {
	// Call setup by XSendEvent to cause readouts to update
	updateReadouts(cursor->x, cursor->y);
      }
      break;
      
    default:
      {
	cout << "got '" << cursor->key << "'." << endl;
      }
      break;
    }
}

void PGPlot1d::updateReadouts(float x1ro, float y1ro)
{
  float y2ro = plotY2Top() - (plotY2Top()-plotY2Bottom())*(plotY1Top() - y1ro)
    /(plotY1Top() - plotY1Bottom());
  char buffer[80];
  sprintf(buffer, "%f", x1ro);
  XmTextSetString(w_x1readout_, buffer);
  XmTextSetString(w_x2readout_, buffer);
  sprintf(buffer, "%f", y1ro);
  XmTextSetString(w_y1readout_, buffer);
  sprintf(buffer, "%f", y2ro);
  XmTextSetString(w_y2readout_, buffer);
}

//
//
//  FUNCTIONS TO DRAW VARIOUS PORTIONS OF THE GRAPH
//
//

//  Always on Y1 !!!
void PGPlot1d::drawSelections()
{
  prepY1Plot();

  cpgsci(selectionColor_);
  cpgshs(120.0, 3.0, 0.0);

  selectionIterator_->toStart();
  while (!selectionIterator_->atEnd())
    {
      Plot1dSelection ps = selectionIterator_->getRight();
      float xa = (float) max(plotXMin(), min(plotXMax(), (Double) ps.x0()));
      float xb = (float) max(plotXMin(), min(plotXMax(), (Double) ps.x1()));
      float ya = (float) max(plotYMin(), min(plotYMax(), (Double) ps.y0()));
      float yb = (float) max(plotYMin(), min(plotYMax(), (Double) ps.y1()));

      cpgsls(4);
      cpgsfs(4);
      cpgrect(xa,xb,ya,yb);
      cpgsfs(2);
      cpgsls(1);
      cpgrect(xa,xb,ya,yb);

      selectionIterator_->step();
    }
  cpgsfs(1);
  cpgshs(45.0, 1.0, 0.0); 
  cpgsls(1);
}

void PGPlot1d::drawIdString()
{
  cpgsci(plotIdStringColor_);
  cpgiden();
}

void PGPlot1d::drawTitle()
{
  cpgslw(1);
  cpgsci(plotTitleColor_);
  cpgscf(plotTitleFont_);
  cpglab("","",plotTitleChars());
}

void PGPlot1d::drawXAxes()
{
  prepY1Plot();
  cpgsci(xAxisColor_);
  cpgslw(xAxisLineWidth_);

  if (xAxisType() == Plot1d::TIME_AXIS)
    cpgtbox("ZHBCNMST",0.0,0,"",0.0,0);
  else if (xAxisType() == Plot1d::SKYPOSITION_AXIS)
    cpgtbox("ZDBCNMST",0.0,0,"",0.0,0);
  else
    cpgbox("BCNMST", 0.0, 0, "", 0.0, 0);

  cpgsci(xAxisLabelColor_);
  cpgscf(xAxisLabelFont_);
  cpglab(xAxisLabelChars(), "", "");
}

void PGPlot1d::drawY1Axes()
{
  prepY1Plot();
  cpgsci(y1AxisColor_);
  cpgslw(y1AxisLineWidth_);
  if (y1AxisType() == Plot1d::TIME_AXIS)
    cpgtbox("",0.0,0,"ZHBCNMST",0.0,0);
  else if (y1AxisType() == Plot1d::SKYPOSITION_AXIS)
    cpgtbox("",0.0,0,"ZDBCNMST",0.0,0);
  else
    cpgbox("", 0.0, 0, "BCNMST", 0.0, 0);

  cpgsci(y1AxisLabelColor_);
  cpgscf(y1AxisLabelFont_);
  cpglab("", y1AxisLabelChars(), "");

  // compute world coordinate offset from axis
  float sizex, sizey;
  cpglen(4, "M", &sizex, &sizey);
  if (xAxisReversed()) sizex = -sizex;

  // put y label on right side, too
  cpgptxt(plotXRight() + 3.5*sizex,
	 (plotY1Top() + plotY1Bottom())/2.0, 90.0, 0.5,
	 y1AxisLabelChars());
}

void PGPlot1d::drawY2Axes()
{
  prepY2Plot();
  cpgsci(y2AxisColor_);
  cpgslw(y2AxisLineWidth_);
  if (y2AxisType() == Plot1d::TIME_AXIS)
    cpgtbox("",0.0,0,"ZHBCNMST",0.0,0);
  else if (y2AxisType() == Plot1d::SKYPOSITION_AXIS)
    cpgtbox("",0.0,0,"ZDBCNMST",0.0,0);
  else
    cpgbox("", 0.0, 0, "BCNMST", 0.0, 0);

  cpgsci(y2AxisLabelColor_);
  cpgscf(y2AxisLabelFont_);
  cpglab("", y2AxisLabelChars(), "");

  // compute world coordinate offset from axis
  float sizex, sizey;
  cpglen(4, "M", &sizex, &sizey);
  if (xAxisReversed()) sizex = -sizex;

  // put y2 label on right side, too
  cpgptxt(plotXRight() + 3.5*sizex,
	 (plotY2Max() + plotY2Min())/2.0, 90.0, 0.5,
	 y2AxisLabelChars());
}

void PGPlot1d::drawBottomXAxis()
{
  cpgsci(xAxisColor_);
  cpgslw(xAxisLineWidth_);  
  if (xAxisType() == Plot1d::TIME_AXIS)
    cpgtbox("ZHBNST",0.0,0,"",0.0,0);
  else if (xAxisType() == Plot1d::SKYPOSITION_AXIS)
    cpgtbox("ZDBNST",0.0,0,"",0.0,0);
  else
    cpgbox("BNST", 0.0, 0, "", 0.0, 0);

  cpgsci(xAxisLabelColor_);
  cpgscf(xAxisLabelFont_);
  cpglab(xAxisLabelChars(), "", "");
}

void PGPlot1d::drawLeftY1Axis()
{
  prepY1Plot();
  cpgsci(y1AxisColor_);
  cpgslw(y1AxisLineWidth_);
  if (y1AxisType() == Plot1d::TIME_AXIS)
    cpgtbox("",0.0,0,"ZHBNST",0.0,0);
  else if (y1AxisType() == Plot1d::SKYPOSITION_AXIS)
    cpgtbox("",0.0,0,"ZDBNST",0.0,0);
  else
    cpgbox("", 0.0, 0, "BNST", 0.0, 0);

  cpgsci(y1AxisLabelColor_);
  cpgscf(y1AxisLabelFont_);
  cpglab("", y1AxisLabelChars(), "");
}

void PGPlot1d::drawRightY2Axis()
{
  prepY2Plot();
  cpgsci(y2AxisColor_);
  cpgslw(y2AxisLineWidth_);
  if (y2AxisType() == Plot1d::TIME_AXIS)
    cpgtbox("",0.0,0,"ZHCMST",0.0,0);
  else if (y2AxisType() == Plot1d::SKYPOSITION_AXIS)
    cpgtbox("",0.0,0,"ZDCMST",0.0,0);
  else
    cpgbox("", 0.0, 0, "CMST", 0.0, 0);

  cpgsci(y2AxisLabelColor_);
  cpgscf(y2AxisLabelFont_);

  // compute world coordinate offset from axis
  float sizex, sizey;
  cpglen(4, "M", &sizex, &sizey);
  if (xAxisReversed()) sizex = -sizex;

  // put y label on right side, too
  cpgptxt(plotXRight() + 3.5*sizex,
	  (plotY2Top() + plotY2Bottom())*0.5, 90.0, 0.5,
	  y2AxisLabelChars());  
}

void PGPlot1d::drawXAxisGrid()
{
  cpgsci(xAxisGridColor_);
  cpgsls(xAxisGridLineStyle_);
  cpgslw(xAxisGridLineWidth_);
  if (xAxisType() == Plot1d::TIME_AXIS)
    cpgtbox("G",0.0,0,"",0.0,0);
  else if (xAxisType() == Plot1d::SKYPOSITION_AXIS)
    cpgtbox("G",0.0,0,"",0.0,0);
  else
    cpgbox("G", 0.0, 0, "", 0.0, 0);
}

void PGPlot1d::drawY1AxisGrid()
{
  prepY1Plot();
  cpgsci(y1AxisGridColor_);
  cpgsls(y1AxisGridLineStyle_);
  cpgslw(y1AxisGridLineWidth_);
  if (y1AxisType() == Plot1d::TIME_AXIS)
    cpgtbox("",0.0,0,"G",0.0,00);
  else if (y1AxisType() == Plot1d::SKYPOSITION_AXIS)
    cpgtbox("",0.0,0,"G",0.0,0);
  else
    cpgbox("", 0.0, 0, "G", 0.0, 0);
}

void PGPlot1d::drawY2AxisGrid()
{
  prepY2Plot();
  cpgsci(y2AxisGridColor_);
  cpgsls(y2AxisGridLineStyle_);
  cpgslw(y2AxisGridLineWidth_);
  if (y2AxisType() == Plot1d::TIME_AXIS)
    cpgtbox("",0.0,0,"G",0.0,0);
  else if (y2AxisType() == Plot1d::SKYPOSITION_AXIS)
    cpgtbox("",0.0,0,"G",0.0,0);
  else
    cpgbox("", 0.0, 0, "G", 0.0, 0);
}

void PGPlot1d::drawY1Data()
{
  prepY1Plot();
  
  for (dataSetIterator()->toStart();
       !dataSetIterator()->atEnd();
       dataSetIterator()->step())
    {
      Plot1dData * pd = dataSetIterator()->getRight();
      if (pd->whichYAxis() == Plot1dData::Y1Axis)
	{
	  drawPd(pd);
	}
    }
}

void PGPlot1d::drawY2Data()
{
  prepY2Plot();
  for (dataSetIterator()->toStart();
       !dataSetIterator()->atEnd();
       dataSetIterator()->step())
    {
      Plot1dData * pd = dataSetIterator()->getRight();
      if (pd->whichYAxis() == Plot1dData::Y2Axis)
	{
	  drawPd(pd);
	}
    }  
}

void PGPlot1d::drawPd(Plot1dData * pd)
{
  PGPlot1dDataAttr * pda = findPda(pd->id());

  if (!pda)
    {
      cerr << "PGPlot1d::drawPD: Couldn't locate pda for pd!!" << endl;
      return;
    }

  if (pda->dataStyle() == PGPlot1dDataAttr::DS_LINES
      || pda->dataStyle() == PGPlot1dDataAttr::DS_LINESPOINTS)
    {
      if (pda->lineStyle() != PGPlot1dDataAttr::LS_NONE)
	{
	  cpgslw(pda->lineWidth());
	  cpgsci(pda->lineColor());
	  cpgsls(pda->lineStyleCode());

	  //cout << "drawPd:lineStyleCode = " << pda->lineStyleCode() << endl;
	  
	  drawXYLines(pd->x(), pd->y());
	}
    }
  if (pda->dataStyle() == PGPlot1dDataAttr::DS_POINTS
      || pda->dataStyle() == PGPlot1dDataAttr::DS_LINESPOINTS)
    {
      cpgsci(pda->pointColor());
      float size;
      cpgqch(&size);
      cpgsch(pda->pointSize());
      drawXYPoints(pd->x(), pd->y(), pda->pointStyleCode());
      cpgsch(size);
    }
  if (pda->dataStyle() == PGPlot1dDataAttr::DS_HISTOGRAM)
    {
      cpgsci(pda->lineColor());
      cpgslw(pda->lineWidth());
      if (pda->lineStyle() != PGPlot1dDataAttr::LS_NONE)
	cpgsls(pda->lineStyleCode());
      else
	cpgsls(1);  // solid
      drawXYHistogram(pd->x(), pd->y());
    }
}

//  Draw to open device
void PGPlot1d::drawXYLines(const Vector<Double>& x,
			   const Vector<Double>& y)
{
  //cout << "drawXYLines" << endl;
  cpgmove((float) x(0), (float) y(0));
  for (uInt i = 1; i < x.nelements(); i++)
    {
      cpgdraw((float) x(i), (float) y(i));
    }
}

void PGPlot1d::drawXYPoints(const Vector<Double>& x,
			    const Vector<Double>& y,
			    uInt markerIndex)
{
  Vector<Float> xF;
  Vector<Float> yF;
  
  //cout << "drawXYPoints" << endl;

  xF.resize(x.nelements());
  yF.resize(y.nelements());
  
  for (uInt i = 0; i < x.nelements(); i++)
    {
      xF(i) = x(i);
      yF(i) = y(i);
    }
  
  Bool deleteItX, deleteItY;
  Float * xP = xF.getStorage(deleteItX);
  Float * yP = yF.getStorage(deleteItY);
  cpgpt(xF.nelements(), xP, yP, markerIndex);
  xF.putStorage(xP, deleteItX);
  yF.putStorage(yP, deleteItY);
}

// Draws histogram-style plot of (X,Y)
void PGPlot1d::drawXYHistogram(const Vector<Double>& x,
			       const Vector<Double>& y)
{
  int hlen = x.nelements()-1;
  int i;

  // hatching
  cpgsfs(3);
  for (i = 1; i < hlen; i++)
    cpgrect((float) 0.5 * (x(i)+x(i-1)),
	    (float) 0.5 * (x(i)+x(i+1)),
	    (float) 0, 
	    (float) y(i));

  // boundary
  cpgsfs(2);
  for (i = 1; i < hlen; i++)
    cpgrect((float) 0.5 * (x(i)+x(i-1)),
	    (float) 0.5 * (x(i)+x(i+1)),
	    (float) 0, 
	    (float) y(i));
}
			       
//  Redraw the motif widget
void PGPlot1d::redraw()
{
  if (setwm_)
    {
      Widget top = X11TopLevelWidget(w_main_);
      // cout << "PGPlot1d: Setting WM property on toplevel widget (" << XtName(top) << ")." << endl;
      Widget ws[2];
      ws[0] = w_main_;
      ws[1] = top;
      XtSetWMColormapWindows(top,
			     ws,
			     2);
      setwm_ = False;
    }

  cpgslct(xmp_device_id(w_plot_));
  
  if (cursorInWindow_) disarmCursor(); 
  
  XtCallbackProc cb = (XtCallbackProc) PGPlot1d::cursorInputCB;

  drawPage();

  //
  //  Arm the cursor
  //

  prepY1Plot();

  if (cursorInWindow_)
    {
      cpgsci(cursorColor_);
      xmp_arm_cursor( w_plot_, 
		      (int) cursorMode_, 
		      (float) cursorXRef_,
		      (float) cursorYRef_,
		      cb,
		      (void *) this);
    }
}

//
//  Draw the page
//
void PGPlot1d::drawPage()
{
  cpgask(0);
  cpgpage();
  cpgbbuf();
  cpgsci(1);
  cpgvstd();
  cpgswin(plotXLeft(), plotXRight(), plotY1Bottom(), plotY1Top());

  // [ ] DEBUG ONLY
  cursorXRef_ = 1.1;
  cursorYRef_ = 2.2;

  //
  //  DRAW THE AXES
  //
  
  //  Always use solid line for axes
  cpgsls(LS_SOLID);

  if (topXAxis_ == True)
    {
      drawXAxes();
    }
  else
    {
      drawBottomXAxis();
    }
  
  if (nY2DataSets() == 0)
    {
      if (rightY1Axis_ == True)
	{
	  drawY1Axes();
	}
      else
	{
	  drawLeftY1Axis();
	}
    }
  else if (nY1DataSets() == 0)
    {
      if (leftY2Axis_ == True)
	{
	  drawY2Axes();
	}
      else
	{
	  drawRightY2Axis();
	}
    }
  else
    {
      drawLeftY1Axis();
      drawRightY2Axis();
    }
  
  //
  //  DRAW THE GRID IF REQUESTED
  //
  
  if (xAxisGrid_)
    {
      drawXAxisGrid();
    }
  
  if (nY2DataSets() > 0 && y2AxisGrid_)
    {
      drawY2AxisGrid();
    }
  
  if (nY1DataSets() > 0 && y1AxisGrid_)
    {
      drawY1AxisGrid();
    }
  
  //
  //  DRAW SELECTIONS AS HATCHED REGIONS IF REQUESTED
  //

  if (showSelections_)
    {
      drawSelections();
    }

  //
  //  DRAW THE DATA
  //

  // cout << "#DataSets: Y1: " << nY1DataSets() << " Y2: " << nY2DataSets() << endl;

  if (nY2DataSets() > 0)
    {
      //cout << "drawing Y2 data" << endl;
      drawY2Data();
    }
  
  if (nY1DataSets() > 0)
    {
      //cout << "drawing Y1 data" << endl;
      drawY1Data();
    }
  
  //
  //  DRAW THE TITLE AND IDENT STRING
  //

  drawTitle();

  if (plotIdString_)
    {
      drawIdString();
    }

  //
  //  End buffer
  //
  
  cpgebuf();

}

//
//  APPLICATION and INTERFACE FUNCTIONS
//

void PGPlot1d::clear()
{
  redrawEnter();

  // [ ] Remove the datasets
  dataSetAttrIterator_->toStart();
  while (!dataSetAttrIterator_->atEnd())
    {
      PGPlot1dDataAttr * pda = dataSetAttrIterator_->getRight();
      dataSetAttrIterator_->removeRight();
      // I'm not sure why PGPlot1d::deleteDataSet isn't use here
      // but the following happens there so should presumably
      // happen here - rwg 24 Jan 1997
      if (pda->index() >= 8) 
	y2StyleTable_(pda->index()-8) = 0;
      else
	y1StyleTable_(pda->index()) = 0;
      if (Plot1d::deleteDataSet(pda->id()) == False)
	{
	  cerr << "PGPlot1d: Internal consistency error!!!";
	  abort();
	}
    }

  Plot1d::clearSelections();
  redrawExit();
}

// return attribute pointer to the id given or NULL
PGPlot1dDataAttr * PGPlot1d::findPda(Int dataSetId)
{
  dataSetAttrIterator_->toStart();
  while (!dataSetAttrIterator_->atEnd())
    {
      PGPlot1dDataAttr * pda = dataSetAttrIterator_->getRight();
      if (pda->id() == dataSetId)
	return pda;
      (*dataSetAttrIterator_)++;
    }
  return NULL;
}

// Return 0 on failure
Int PGPlot1d::addDataSet(Plot1dData * data, Plot1d::DataStyles ds)
{
  redrawEnter();

  // Create a new attribute set and add it to the list
  PGPlot1dDataAttr * pda = new PGPlot1dDataAttr(data->id());
  dataSetAttrIterator_->toStart();
  dataSetAttrIterator_->addRight(pda);

  setDataStyle(data->id(), ds);
  setDataAttributes(pda, data->whichYAxis());

  redrawExit();

  return pda->id();  
}

void PGPlot1d::setDataAttributes(PGPlot1dDataAttr * pda,
				 Plot1dData::AssociatedYAxis whichYAxis)
{
  switch(whichYAxis)
    {
    case Plot1dData::NoAxis:
      break;
    case Plot1dData::Y1Axis:
      {
	int index = pickY1Style(pda->id());
	pda->setLineColor(string2colorIndex(PGPlotLineColors1[index]));
	pda->setPointColor(string2colorIndex(PGPlotPointColors1[index]));
	pda->setPointStyle(PGPlotPointStyles1[index]);
	pda->setIndex(index);
	break;
      }
    case Plot1dData::Y2Axis:
      {
	int index = pickY2Style(pda->id());
	pda->setLineColor(string2colorIndex(PGPlotLineColors2[index]));
	pda->setPointColor(string2colorIndex(PGPlotPointColors2[index]));
	pda->setPointStyle(PGPlotPointStyles2[index]);
	pda->setIndex(8+index);
	break;
      }
    }
}
Int PGPlot1d::pickY1Style(int id)
{
  for (int i = 0; i < 8; i++)
    {
      if (y1StyleTable_(i) == 0)
	{
	  y1StyleTable_(i) = 1;
	  return i;
	}
    }
  return (id % 8);
}
Int PGPlot1d::pickY2Style(int id)
{
  for (int i = 0; i < 8; i++)
    {
      if (y2StyleTable_(i) == 0)
	{
	  y2StyleTable_(i) = 1;
	  return i;
	}
    }
  return (id % 8);
}

Bool PGPlot1d::deleteDataSet(Int dataSetId)
{
  Bool retval = False;
  
  redrawEnter();

  // [ ] Remove from the data set attribute list
  dataSetAttrIterator_->toStart();
  while (!dataSetAttrIterator_->atEnd())
    {
      PGPlot1dDataAttr * pda = dataSetAttrIterator_->getRight();
      if (pda->id() == dataSetId) 
	{
	  dataSetAttrIterator_->removeRight();
	  if (pda->index() >= 8)
	    y2StyleTable_(pda->index()-8) = 0;
	  else
	    y1StyleTable_(pda->index()) = 0;
	  retval = True;
	}
      dataSetAttrIterator_->step();
    }

  if (retval)
    {
      if (Plot1d::deleteDataSet(dataSetId) == False)
	{
	  cerr << "PGPlot1d: Internal consistency error!!!";
	  abort();
	}
    }

  redrawExit();
  return retval;
}

Int PGPlot1d::appendData(Int dataSetId, Double y)
{
  redrawEnter();
  cout << "appendData NYI" << endl;
  redrawExit();
  return 0;  
}

Int PGPlot1d::appendData(Int dataSetId, Double x, Double y)
{
  redrawEnter();
  cout << "appendData NYI" << endl;
  redrawExit();
  return 0;  
}

Int PGPlot1d::appendData(Int dataSetId, Vector <Double> y)
{
   redrawEnter();
  cout << "appendData NYI" << endl;
  redrawExit();
 return 0;  
}

Int PGPlot1d::appendData(Int dataSetId, Vector <Double> x, Vector <Double> y)
{
  redrawEnter();
  cout << "appendData NYI" << endl;
  redrawExit();
  return 0;  
}

Int PGPlot1d::removeDataPoint (Int dataSetId, Int where)
{
  redrawEnter();
  cout << "removeDataPoint NYI" << endl;
  redrawExit();
  return 0;  
}

void PGPlot1d::setDataStyle (Int dataSetId, DataStyles dataStyle)
{
  redrawEnter();
  PGPlot1dDataAttr * pda = findPda(dataSetId);
  if (pda)
    {
      // cout << "setting data style to " << dataStyle << "." << endl;
      switch (dataStyle)
	{
	case lines:
	  pda->setDataStyle(PGPlot1dDataAttr::DS_LINES);
	  break;
	case points:
	  pda->setDataStyle(PGPlot1dDataAttr::DS_POINTS);
	  break;
	case linespoints:
	  pda->setDataStyle(PGPlot1dDataAttr::DS_LINESPOINTS);
	  break;
	case histogram:
	  pda->setDataStyle(PGPlot1dDataAttr::DS_HISTOGRAM);
	  break;
	}
    }
  redrawExit();
}

void PGPlot1d::setSelectionColor (const String &color)
{
  //cout << "setSelectionColor " << color << endl;
  redrawEnter();
  Int index = string2colorIndex(color);
  if (index >= 0)
    {
      selectionColor_ = index;
    }
  redrawExit();
}
void PGPlot1d::setPlotTitleColor (const String &color)
{
  redrawEnter();
  Int index = string2colorIndex(color);
  if (index >= 0)
    {
      plotTitleColor_ = index;
    }
  redrawExit();
}
void PGPlot1d::setCursorColor (const String &color)
{
  redrawEnter();
  Int index = string2colorIndex(color);
  if (index >= 0)
    {
      cursorColor_ = index;
    }
  redrawExit();
}
void PGPlot1d::showSelections (Bool onOff) 
{
  cout << "ShowSelections: onOff = " << onOff << endl;
  redrawEnter();
  showSelections_ = onOff; 
  redrawExit();
}
void PGPlot1d::setXAxisColor (const String &color)
{
  redrawEnter();
  Int index = string2colorIndex(color);
  if (index >= 0)
    {
      xAxisColor_ = index;
    }
  redrawExit();
}
void PGPlot1d::setY1AxisColor (const String &color)
{
  redrawEnter();
  Int index = string2colorIndex(color);
  if (index >= 0)
    {
      y1AxisColor_ = index;
    }
  redrawExit();
}
void PGPlot1d::setY2AxisColor (const String &color)
{
  redrawEnter();
  Int index = string2colorIndex(color);
  if (index >= 0)
    {
      y2AxisColor_ = index;
    }
  redrawExit();
}
void PGPlot1d::setXAxisLabelColor (const String &color)
{
  redrawEnter();
  Int index = string2colorIndex(color);
  if (index >= 0)
    {
      xAxisLabelColor_ = index;
    }
  redrawExit();
}
void PGPlot1d::setY1AxisLabelColor (const String &color)
{
  redrawEnter();
  Int index = string2colorIndex(color);
  if (index >= 0)
    {
      y1AxisLabelColor_ = index;
    }
  redrawExit();
}
void PGPlot1d::setY2AxisLabelColor (const String &color)
{
  redrawEnter();
  Int index = string2colorIndex(color);
  if (index >= 0)
    {
      y2AxisLabelColor_ = index;
    }
  redrawExit();
}
void PGPlot1d::setXAxisGridColor (const String &color)
{
  redrawEnter();
  Int index = string2colorIndex(color);
  if (index >= 0)
    {
      xAxisGridColor_ = index;
    }
  redrawExit();
}
void PGPlot1d::setY1AxisGridColor (const String &color)
{
  redrawEnter();
  Int index = string2colorIndex(color);
  if (index >= 0)
    {
      y1AxisGridColor_ = index;
    }
  redrawExit();
}
void PGPlot1d::setY2AxisGridColor (const String &color)
{
  redrawEnter();
  Int index = string2colorIndex(color);
  if (index >= 0)
    {
      y2AxisGridColor_ = index;
    }
  redrawExit();
}

#if 0
// private
void PGPlot1d::setStyle_(Int * target, Plot1d::LineStyles lineStyle)
{
  redrawEnter();
  switch(lineStyle)
    {
      
    }
  redrawExit();
}
#endif

void PGPlot1d::setLineColor (Int dataSetId, const String &color)
{
  PGPlot1dDataAttr * pda = findPda(dataSetId);
  redrawEnter();
  if (pda)
    {
      Int index = string2colorIndex(color);
      if (index >= 0)
	pda->setLineColor(index);
    }
  redrawExit();
}

void PGPlot1d::setLineStyle (Int dataSetId, Plot1d::LineStyles lineStyle)
{
  redrawEnter();
  PGPlot1dDataAttr * pda = findPda(dataSetId);
  if (pda)
    {
      switch (lineStyle)
	{
	case Plot1d::noLine:
	  cout << "setting no line" << endl;
	  pda->setLineStyle(PGPlot1dDataAttr::LS_NONE);
	  break;
	case Plot1d::solid:
	  pda->setLineStyle(PGPlot1dDataAttr::LS_SOLID);
	  break;
	case Plot1d::dashed:
	  pda->setLineStyle(PGPlot1dDataAttr::LS_DASHED);
	  break;
	case Plot1d::dotted:
	  pda->setLineStyle(PGPlot1dDataAttr::LS_DOTTED);
	  break;
	case Plot1d::shortDashed:
	  pda->setLineStyle(PGPlot1dDataAttr::LS_DASH_3DOT);
	  break;
	case Plot1d::mixedDashed:
	  pda->setLineStyle(PGPlot1dDataAttr::LS_DASH_3DOT);
	  break;
	case Plot1d::dashDot:
	  pda->setLineStyle(PGPlot1dDataAttr::LS_DOT_DASH);
	  break;
	}
    }
  redrawExit();
}

// newSize is in pixels; convert to units of 1/200 inch
void PGPlot1d::setLineWidth (Int dataSetId, Int newSize)
{
  redrawEnter();
  PGPlot1dDataAttr * pda = findPda(dataSetId);
  if (pda)
    {
      //int pgplotUnits = 200 * pixels2inches(newSize);
      int pgplotUnits = newSize;
      pda->setLineWidth(pgplotUnits);
    }
  redrawExit();
}

// 
//
Int PGPlot1d::string2colorIndex(const String &color)
{
  int index = searchColor(color);

  if (index == -1)
    {
      // wasn't found, try to add
      return addColor(color);
    }
  else
    return index;
}

void PGPlot1d::setPointColor (Int dataSetId, const String &color)
{
  redrawEnter();
  PGPlot1dDataAttr * pda = findPda(dataSetId);
  if (pda)
    {
      Int index = string2colorIndex(color);
      if (index >= 0)
	pda->setPointColor(index);
    }
  redrawExit();
}

void PGPlot1d::setPointStyle (Int dataSetId, Plot1d::PointStyles pointStyle)
{
  redrawEnter();
  PGPlot1dDataAttr * pda = findPda(dataSetId);
  if (pda)
    {
      switch(pointStyle)
	{
	case Plot1d::noPoint:
	  pda->setPointStyle(PGPlot1dDataAttr::PS_NONE);
	  break;
	case Plot1d::dot:
	  pda->setPointStyle(PGPlot1dDataAttr::PS_DOT);
	  break;
	case Plot1d::box:
	  pda->setPointStyle(PGPlot1dDataAttr::PS_BOX);
	  break;
	case Plot1d::triangle:
	  pda->setPointStyle(PGPlot1dDataAttr::PS_TRIANGLE);
	  break;
	case Plot1d::diamond:
	  pda->setPointStyle(PGPlot1dDataAttr::PS_DIAMOND);
	  break;
	case Plot1d::star:
	  pda->setPointStyle(PGPlot1dDataAttr::PS_STAR);
	  break;
	case Plot1d::verticalLine:
	  pda->setPointStyle(PGPlot1dDataAttr::PS_VLINE);
	  break;
	case Plot1d::horizontalLine:
	  pda->setPointStyle(PGPlot1dDataAttr::PS_HLINE);
	  break;
	case Plot1d::cross:
	  pda->setPointStyle(PGPlot1dDataAttr::PS_CROSS);
	  break;
	case Plot1d::circle:
	  pda->setPointStyle(PGPlot1dDataAttr::PS_CIRCLE);
	  break;
	case Plot1d::square:
	  pda->setPointStyle(PGPlot1dDataAttr::PS_SQUARE);
	  break;
	default:
	  cerr << "PGPlot1d::setPointStyle: Unrecognized Point Style" << endl;
	  break;
	}
    }
  redrawExit();
}

void PGPlot1d::setPointSize (Int dataSetId, Int newSize)
{
  redrawEnter();
  PGPlot1dDataAttr * pda = findPda(dataSetId);
  if (pda)
    {
      pda->setPointSize(newSize);
    }
  redrawExit();
}

//
// Extra Axis positioning
//

void PGPlot1d::setXAxisPosition (AxisPlacementStrategy,
				 Double where)
{
#if 0
  redrawEnter();
  // add extra x axis at
  //
  if (where == 0.0)
    extraXAxis_ = False;
  else
    extraXAxisPosition_ = where;
  redrawExit();
#endif
}

void PGPlot1d::setY1AxisPosition (AxisPlacementStrategy,
				 Double where)
{
  redrawEnter();
  cout << "setY1AxisPosition NYI" << endl;
  redrawExit();
}
void PGPlot1d::setY2AxisPosition (AxisPlacementStrategy,
				 Double where)
{
  redrawEnter();
  cout << "setY2AxisPosition NYI" << endl;
  redrawExit();
}

void PGPlot1d::reverseXAxis()
{
  redrawEnter();
  Plot1d::reverseXAxis();
  redrawExit();
}
void PGPlot1d::reverseY1Axis()
{
  redrawEnter();
  Plot1d::reverseY1Axis();
  redrawExit();
}
void PGPlot1d::reverseY2Axis()
{
  redrawEnter();
  Plot1d::reverseY2Axis();
  redrawExit();
}

void PGPlot1d::swapY1Y2()
{
  redrawEnter();
  Plot1d::swapY1Y2_();
  redrawExit();
}

void PGPlot1d::setLegendGeometry (LegendGeometry newGeometry)
{
  cerr << "PGPlot1d::setLegendGeometry: Not Supported" << endl;
}

//
//
//  PRINTER DEVICE (Tmp ps file which is sent to printer via print command)
//
//


// [ ] clean up with Strings
Bool PGPlot1d::openPrinterDevice()
{
  char buf[256];

  sprintf(buf, "./gplot1d.%d.ps", getpid());
  printTmpFilename_ = buf;

  sprintf(buf, "\"%s\"/%s%sPS",
	  printTmpFilename_.chars(),
	  printLandscape_ ? "" : "V",
	  printColor_ ? "C" : "");
  
  psDevId_ = cpgopen(buf);
  //cout << "PS File device id : " << psDevId_ << endl;
  if (psDevId_ <= 0)
    {
      cout << " Couldn't open print-tmpfile device '"
	   << buf
	   << "'."
	   << endl;
      return False;
    }
  return True; 
}

void PGPlot1d::closePrinterDevice()
{
  cpgslct(psDevId_);
  cpgclos();

#if 0
  // PGPlot1d no longer constructs the print command assuming "lpr"
  String printerName;

  // Take PRINTER if it is defined, otherwise use aipsrc variable printer.default
  // otherwise error

  if (printerName_.length () > 0) {
    printerName = printerName_;
  } else {
    printerName = EnvironmentVariable::get ("PRINTER");
    if (printerName.empty()) {
      if (Aipsrc::find(printerName, "printer.default")) {
	// Nothing - printername set as side-effect of find
      }  else {
	cerr << "print error:  no environment variable PRINTER defined" << endl;
	cerr << "              and none other explicitly set." << endl;
	return;
      }
    }
  }

  cout << "printing postscript rendering to " << printerName << "..." << endl;
#endif

  String command = printCommand_;
  command += " ";
  command += printTmpFilename_;
  command += "; rm -f ";
  command += printTmpFilename_;

  cout << "closePrinterDevice command = '" << command << "'." << endl;

  system(command.chars());
}

//
//
//  POSTSCRIPT FILE DEVICE (Print to file, but don't send to printer)
//
//

// [ ] clean up with Strings
Bool PGPlot1d::openPSFileDevice()
{
  char buf[256];
  
  sprintf(buf, "\"%s\"/%s%sPS",
	  printFilename_.chars(),
	  printLandscape_ ? "" : "V",
	  printColor_ ? "C" : "");

  psDevId_ = cpgopen(buf);
  // cout << "PS File device id : " << psDevId_ << endl;
  if (psDevId_ <= 0)
    {
      cout << " Couldn't open print-to-file device '"
	<< buf
	<< "'."
	<< endl;

      return False;
    }
  return True;
}

void PGPlot1d::closePSFileDevice()
{
  cpgslct(psDevId_);
  cpgclos();
}

Bool PGPlot1d::printGraphToPrinter()
{
  Bool retval = openPrinterDevice();
  if (retval)
    {
      // cout << "Printing to Printer" << endl;
      cpgslct(psDevId_);
      drawPage();
      closePrinterDevice();
    }
  return retval;
}

Bool PGPlot1d::printGraphToFile(String filename)
{
  printFilename_ = filename;
  Bool retval = openPSFileDevice();
  if (retval)
    {
      // cout << "Printing to File" << endl;
      cpgslct(psDevId_);
      drawPage();
      closePSFileDevice();
    }
  return retval;
}

void PGPlot1d::enableXMarker (int onOff)
{
  if (onOff == True)
    {
      switch (cursorInactiveMode_)
	{
	case XMP_CROSS_CURSOR:
	case XMP_VLINE_CURSOR:
	  break;
	case XMP_HLINE_CURSOR:
	  setCursorInactiveMode(XMP_CROSS_CURSOR);
	  break;
	case XMP_NORM_CURSOR:
	  setCursorInactiveMode(XMP_VLINE_CURSOR);
	  break;
	}
    }
  else
    {
      switch (cursorInactiveMode_)
	{
	case XMP_CROSS_CURSOR:
	  setCursorInactiveMode(XMP_HLINE_CURSOR);
	  break;
	case XMP_VLINE_CURSOR:
	  setCursorInactiveMode(XMP_NORM_CURSOR);
	  break;
	case XMP_HLINE_CURSOR:
	case XMP_NORM_CURSOR:
	  break;
	}
    }
}

void PGPlot1d::enableYMarker (int onOff)
{
  if (onOff == True)
    {
      switch (cursorInactiveMode_)
	{
	case XMP_CROSS_CURSOR:
	case XMP_HLINE_CURSOR:
	  break;
	case XMP_VLINE_CURSOR:
	  setCursorInactiveMode(XMP_CROSS_CURSOR);
	  break;
	case XMP_NORM_CURSOR:
	  setCursorInactiveMode(XMP_HLINE_CURSOR);
	  break;
	}
    }
  else
    {
      switch (cursorInactiveMode_)
	{
	case XMP_CROSS_CURSOR:
	  setCursorInactiveMode(XMP_VLINE_CURSOR);
	  break;
	case XMP_HLINE_CURSOR:
	  setCursorInactiveMode(XMP_NORM_CURSOR);
	  break;
	case XMP_VLINE_CURSOR:
	case XMP_NORM_CURSOR:
	  break;
	}
    }
}

void PGPlot1d::setXScale(Double x0, Double x1)
{
  redrawEnter();
  Plot1d::setXScale(x0,x1);
  redrawExit();
}
void PGPlot1d::setY1Scale(Double y0, Double y1)
{
  redrawEnter();
  Plot1d::setY1Scale(y0,y1);
  redrawExit();
}
void PGPlot1d::setY2Scale(Double y0, Double y1)
{
  redrawEnter();
  Plot1d::setY2Scale(y0,y1);
  redrawExit();
}

} //# NAMESPACE CASA - END

