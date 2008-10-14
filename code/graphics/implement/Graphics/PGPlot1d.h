//# PGPlot1d.h: PGPlot is one of two plotting widgets available for AIPS++
//# Copyright (C) 1993,1994,1995,1997,1999,2000,2002
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
//# $Id: PGPlot1d.h,v 19.5 2004/11/30 17:50:25 ddebonis Exp $

#ifndef GRAPHICS_PGPLOT1D_H
#define GRAPHICS_PGPLOT1D_H

#include <casa/aips.h>


#include <graphics/X11/X_enter.h>
#include <X11/Xlib.h>
#include <X11/Intrinsic.h>
#include <X11/StringDefs.h>
#include <X11/keysym.h>
#include <Xm/Xm.h>
#include <cpgplot.h>
#include <XmPgplot.h>
#include <graphics/X11/X_exit.h>


#include <casa/BasicSL/String.h>
#include <graphics/Graphics/Plot1d.h>
#include <graphics/Graphics/PGPlot1dDataAttr.h>
#include <limits.h>

namespace casa { //# NAMESPACE CASA - BEGIN

#define PGPlot1d_MAX_COLORS 60

//  <summary>
//  PGPLOT class interface according to Plot1d
//  </summary>

//  <use visibility=>

//  <reviewed reviewer="" date="" tests="" demos=""

//  <etymology>
//  PGPlot1d is a portmanteaux of PGPLOT and Plot1d
//  </etymology>

//  <synopsis>
//  Designed to support PGPLOT 5.1 by T. J. Pearson of Caltech
//
//  </synopsis>

//  <thrown>
//    <li> 
//  </thrown>

//  <example>
//  </example>

class PGPlot1d : public Plot1d
{
public:

  enum PGPlotLineStyle { LS_SOLID=1, LS_DASHED, LS_DOT_DASH,
			  LS_DOTTED, LS_DASH_3DOT };

  enum PGPlotFont { FNT_NORMAL=1, FNT_ROMAN, FNT_ITALIC, FNT_SCRIPT };

  enum PGPlotPointStyle { PS_NONE, PS_DOT, PS_BOX, PS_TRIANGLE, PS_DIAMOND,
			  PS_STAR, PS_VLINE, PS_HLINE, PS_CROSS, PS_CIRCLE,
			  PS_SQUARE };
  //
  //  - Construct PGPlot window inside given parent
  //  - initialize appropriate variables.
  //
  PGPlot1d(Widget parent);

  static void resizeCB(Widget, PGPlot1d * p1d, XtPointer);
  static void drawCB(Widget, PGPlot1d * p1d, XtPointer);

  //  Redraw the display
  //  -Cycle through the list of associated data and draw each.
  //  Don't call this function within this hierarchy.  Instead wrap
  //  drawing code with the redrawEnter()/redrawExit() pair to prevent
  //  nested and layered functions from calling redraw more than once.
  virtual void redraw();

  //  Clear the display and erase all datasets
  //  -call cpgerase to erase the display
  virtual void clear();

  // 
private:
  virtual Int addDataSet (Plot1dData * data, Plot1d::DataStyles);
public:

  //  Delete a dataset by External Identification Number
  //  -
  virtual Bool deleteDataSet(Int dataSetId);

  Int string2colorIndex(const String &color);

  //  Append data to a given dataset
  virtual Int appendData(Int dataSetId, Double y);
  virtual Int appendData (Int dataSetId, Double x, Double y);
  virtual Int appendData (Int dataSetId, Vector <Double> y);
  virtual Int appendData (Int dataSetId, Vector <Double> x, Vector <Double> y);

  //  Remove a single data item by dataset id with given index
  virtual Int removeDataPoint (Int dataSetId, Int where);
  
  //  Change the style of the given dataset id
  virtual void setDataStyle (Int dataSetId, DataStyles dataStyle);

  //  Plot title
  virtual void setPlotTitleColor(const String& color);
  virtual void setCursorColor(const String& color);
  virtual void showSelections(Bool onOff);
  
  virtual void setSelectionColor(const String& color);

  //  Set axis preferences
  virtual void setTopXAxis(Bool onOff)
  { redrawEnter(); topXAxis_ = onOff; redrawExit(); }
  virtual void setLeftY2Axis(Bool onOff)
  { redrawEnter(); leftY2Axis_ = onOff; redrawExit(); }
  virtual void setRightY1Axis(Bool onOff)
  { redrawEnter(); rightY1Axis_ = onOff; redrawExit(); }

  //  Set the axis attributes
  virtual void setXAxisColor(const String& color);
  virtual void setY1AxisColor(const String& color);
  virtual void setY2AxisColor(const String& color);

  virtual void setXAxisLabelColor(const String& color);
  virtual void setY1AxisLabelColor(const String& color);
  virtual void setY2AxisLabelColor(const String& color);

  virtual void setXAxisGridColor(const String& color);
  virtual void setY1AxisGridColor(const String& color);
  virtual void setY2AxisGridColor(const String& color);

  virtual void setXAxisLineWidth(const Int newSize)
  { redrawEnter(); xAxisLineWidth_ = newSize; redrawExit(); }
  virtual void setY1AxisLineWidth(const Int newSize)
  { redrawEnter(); y1AxisLineWidth_ = newSize; redrawExit(); }
  virtual void setY2XAxisLineWidth(const Int newSize)
  { redrawEnter(); y2AxisLineWidth_ = newSize; redrawExit(); }

  virtual void setXAxisGrid(Bool onOff) 
  { redrawEnter(); xAxisGrid_ = onOff; redrawExit(); }
  virtual void setY1AxisGrid(Bool onOff) 
  { redrawEnter(); y1AxisGrid_ = onOff; redrawExit(); }
  virtual void setY2AxisGrid(Bool onOff) 
  { redrawEnter(); y2AxisGrid_ = onOff; redrawExit(); }

  virtual void setXAxisGridLineWidth(const Int newSize)
  { redrawEnter(); xAxisGridLineWidth_ = newSize; redrawExit(); }
  virtual void setY1AxisGridLineWidth(const Int newSize)
  { redrawEnter(); y1AxisGridLineWidth_ = newSize; redrawExit(); }
  virtual void setY2XAxisGridLineWidth(const Int newSize)
  { redrawEnter(); y2AxisGridLineWidth_ = newSize; redrawExit(); }

  //  Set the line attributes
  //  
  virtual void setLineColor (Int dataSetId, const String &color);
  virtual void setLineStyle (Int dataSetId, LineStyles lineStyle);
  virtual void setLineWidth (Int datasetId, Int newSize);

  //  Set the Point attributes
  virtual void setPointColor (Int dataSetId, const String &color);
  virtual void setPointStyle (Int dataSetId, PointStyles pointStyle);
  virtual void setPointSize (Int dataSetId, Int newSize);
  
  //  Set the axis position strategy 
  //  - ignored
  virtual void setXAxisPosition (Plot1d::AxisPlacementStrategy strategy,
				 Double where = 0.0);
  void setYAxisPosition(Plot1d::AxisPlacementStrategy strategy, Double where = 0.0)
    { setY1AxisPosition(strategy, where); }
  virtual void setY1AxisPosition (Plot1d::AxisPlacementStrategy strategy,
				 Double where = 0.0);
  virtual void setY2AxisPosition (Plot1d::AxisPlacementStrategy strategy,
				 Double where = 0.0);

  //  Place Markers
  //  - ignored
  void placeXMarker(Double x) {}
  void placeYMarker(Double y) {}

  //  Query doesn't make sense if Plot1d defines the enums!
  String describeDataDisplayStyles() 
  { return String("PGPlot Styles: todo"); }

  //  Reverse the plot axes (global for widget)
  //  -swap the min and max values
  virtual void reverseXAxis();
  void reverseYAxis() { reverseY1Axis(); }
  virtual void reverseY1Axis();
  virtual void reverseY2Axis();

  virtual void swapY1Y2();

  //  Set the position of the legend
  //  - ignore for now
  virtual void setLegendGeometry (LegendGeometry newGeometry);

  //  Open postscript device and send to printer
  virtual Bool printGraphToPrinter();
  virtual Bool printGraphToFile(String filename);
  
  //  "Markers" are pieces of the crosshair cursor
  //  - ignore for now
  virtual void enableXMarker (int onOff);
  virtual void enableYMarker (int onOff);

  // set the scale
  // - Clamp?
  virtual void setXScale(Double x0, Double x1);
  void setYScale(Double y0, Double y1) { setY1Scale(y0,y1); }
  virtual void setY1Scale(Double y0, Double y1);
  virtual void setY2Scale(Double y0, Double y1);
    
  //
  //  X cursor input callback
  //
  void cursorInput(XmpCursorCallbackStruct * cursor);
  static void cursorInputCB(Widget, XtPointer p1d, XtPointer cursor);

  void armCursor(int mode, float x, float y)
  { 
    cpgslct(xmp_device_id(w_plot_));
    cpgsci(cursorColor_);
    xmp_arm_cursor(w_plot_, mode, x, y,
		   (XtCallbackProc) PGPlot1d::cursorInputCB, this); 
  }

  void disarmCursor()
  {
    cpgslct(xmp_device_id(w_plot_));
    xmp_disarm_cursor(w_plot_);
    cursorActive_ = 0;
    cursorMode_ = cursorInactiveMode_;
  }

  void setCursorInactiveMode(int mode);
  void setCursorActiveMode(int mode);

  void selectRegion(float x1, float x2, float y1, float y2);

  static void leaveNotifyEH(Widget, XtPointer pthis, XEvent *, Boolean *);
  void leaveNotify();
  static void enterNotifyEH(Widget, XtPointer pthis, XEvent *, Boolean *);
  void enterNotify();
  static void motionNotifyEH(Widget, XtPointer pthis, XEvent *, Boolean *);
  void motionNotify(int x, int y);

  void setPrintCommand(const String & s);
  const String & printCommand() const { return printCommand_; }

private:

  // 

  Int pickY1Style(int id);
  Int pickY2Style(int id);
  Vector<Int> y1StyleTable_;
  Vector<Int> y2StyleTable_;
  void setDataAttributes(PGPlot1dDataAttr * pda,
			 Plot1dData::AssociatedYAxis whichYAxis);

  // Add standard suite of X colors
  void addStandardColors();

  // Add color to PGPlot's list of colors.  Returns False if failed
  Int addColor(const String& s);

  // Return color index for given color or -1 if not found
  Int searchColor(const String& s);

  void updateReadouts(float x1ro, float y1ro);
  
  static void quitCB(Widget, XtPointer, XtPointer);
  static void printCB(Widget, XtPointer, XtPointer);
  static void fullViewCB(Widget, XtPointer, XtPointer);
  static void clearSelectionsCB(Widget, XtPointer, XtPointer);
  static void clearCB(Widget, XtPointer, XtPointer);
  static void selectXAxisCB(Widget, XtPointer, XtPointer);
  static void selectYAxisCB(Widget, XtPointer, XtPointer);
  static void selectBoxCB(Widget, XtPointer, XtPointer);
  static void setZoomDragModeCB(Widget, XtPointer, XtPointer);
  static void setSelectDataDragModeCB(Widget, XtPointer, XtPointer);

  void drawPage();

  Bool openGraphicsDevice();
  void closeGraphicsDevice();
  Bool openPrinterDevice();
  void closePrinterDevice();
  Bool openPSFileDevice();
  void closePSFileDevice();

  PGPlot1dDataAttr * findPda(Int id);

  void initializeWidgets(Widget parent);


  void prepDataAttributes(Plot1dData * pd);

  //  Insure that plot range set for y1 data
  void prepY1Plot()
    { 
      if (y2PlotPrepped_)
	cpgswin(plotXLeft(), plotXRight(), plotY1Bottom(), plotY1Top());
      y2PlotPrepped_ = False;
    }

  //  Insure that plot range set for y2 data
  void prepY2Plot()
    { 
      if (!y2PlotPrepped_)
	cpgswin(plotXLeft(), plotXRight(), plotY2Bottom(), plotY2Top());
      y2PlotPrepped_ = True;
    }

  //  Functions to draw various pieces of the graph
  //  <group>
  void drawXAxes();
  void drawY1Axes();
  void drawY2Axes();
  void drawBottomXAxis();
  void drawLeftY1Axis();
  void drawRightY2Axis();
  void drawXAxisGrid();
  void drawY1AxisGrid();
  void drawY2AxisGrid();
  void drawY1Data();
  void drawY2Data();
  void drawTitle();
  void drawIdString();
  void drawSelections();

  void drawPd(Plot1dData * pd);

  // Double->Float for drawing
  void drawXYLines(const Vector<Double>& x,
		   const Vector<Double>& y);
  void drawXYPoints(const Vector<Double>& x,
		    const Vector<Double>& y,
		    uInt markerIndex);
  void drawXYHistogram(const Vector<Double>& x,
		      const Vector<Double>& y);

  // </group>

  //  Convert a dataset Id to a dataset index.  Returns the (0-based)
  //  index of the item in the dataSetList or -1 if not found
  int DataSetId2DataSetIndex_(int DataSetId);


  // If true, redraw sets the WM property to register a private
  // colormap (this is done only once)
  Bool setwm_;

  // vector of strings
  Vector<String> colorNameTable_;
  int maxColors_;
  int nColors_;

  float cursorXRef_;
  float cursorYRef_;
  
  // modes are XMP_{NORM,LINE,RECT,YRNG,XRNG,HLINE,VLINE,CROSS}_CURSOR
  int   cursorMode_;
  int   cursorActive_;
  int   cursorActiveMode_;
  int   cursorInactiveMode_;
  int   cursorInWindow_;

  uInt  cursorColor_;

  uInt  selectionColor_;

  List <PGPlot1dDataAttr *> *dataSetAttrList_;
  ListIter <PGPlot1dDataAttr *> *dataSetAttrIterator_;

  GC gc_;

  Widget parent_;
  Widget w_scrollbar_;
  Widget w_plot_;
  Widget w_main_;

  Widget w_x1readout_;
  Widget w_y1readout_;
  Widget w_x2readout_;
  Widget w_y2readout_;

  //  True if plot prepped for y2
  Bool y2PlotPrepped_;

  //  These variables are here to allow the style of PGPlot1d
  //  to be tailored to the nth degree.

  //  Extend the major ticks across the plotting area to form 
  //  plot-wide horizontal and/or vertical lines
  // <group>
  Bool xAxisGrid_;
  Bool y1AxisGrid_;
  Bool y2AxisGrid_;
  // </group>

  //  If true, add the other axis when appropriate
  //  <group>
  Bool topXAxis_;
  Bool rightY1Axis_;
  Bool leftY2Axis_;
  // </group>

  //  Controls color of the axis and numbers
  //  <group>
  uInt xAxisColor_;
  uInt y1AxisColor_;
  uInt y2AxisColor_;
  //  </group>

  //  Holds width of the axis lines, units 1/200 inch
  //  <group>
  uInt xAxisLineWidth_;
  uInt y1AxisLineWidth_;
  uInt y2AxisLineWidth_;
  //  </group>

  //  Holds width of the axis gridlines
  //  <group>
  uInt xAxisGridLineWidth_;
  uInt y1AxisGridLineWidth_;
  uInt y2AxisGridLineWidth_;
  //  </group>

  //  Set the line style for the axis gridlines
  //  <group>
  uInt xAxisGridLineStyle_;
  uInt y1AxisGridLineStyle_;
  uInt y2AxisGridLineStyle_;
  //  </group>

  //  Set the color for the axis gridlines
  //  <group>
  uInt xAxisGridColor_;
  uInt y1AxisGridColor_;
  uInt y2AxisGridColor_;
  //  </group>

  //  Choose the font for the following categories
  // <group>
  PGPlotFont plotTitleFont_; 
  PGPlotFont xAxisLabelFont_;
  PGPlotFont y1AxisLabelFont_;
  PGPlotFont y2AxisLabelFont_;
  // </group>

  //  Choose the color index for the plot labels
  // <group>
  uInt plotTitleColor_;
  uInt xAxisLabelColor_;
  uInt y1AxisLabelColor_;
  uInt y2AxisLabelColor_;
  // </group>
  
  //  These variables control the plotting of the identification
  //  string for the plot
  // <group>.
  uInt plotIdStringColor_;
  Bool plotIdString_;
  // </group>

  Bool showSelections_;

  //  Printing control
  String printTmpFilename_;
  Bool printLandscape_;
  Bool printColor_;
  String printFilename_;
  int psDevId_;
};
  



} //# NAMESPACE CASA - END

#endif
