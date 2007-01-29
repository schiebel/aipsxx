//# Plot1d.h: a class for plotting vectors, in many combinations and styles
//# Copyright (C) 1999,2000
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
//#---------------------------------------------------------------------------
//# $Id: Plot1d.h,v 19.5 2004/11/30 17:50:25 ddebonis Exp $
//#---------------------------------------------------------------------------
// <todo asof "1995/06/06">
//   <li> centralize accounting for numberOfDataSets_.  what is the logic
//        of holes in the sequence, created by deleted datasets?
// </todo>
//#---------------------------------------------------------------------------
#ifndef GRAPHICS_PLOT1D_H
#define GRAPHICS_PLOT1D_H
//#---------------------------------------------------------------------------
#include <casa/aips.h>
#include <casa/BasicSL/String.h>
#include <casa/Arrays/Vector.h>
#include <casa/Containers/List.h>
#include <graphics/Graphics/Plot1dData.h>
#include <graphics/Graphics/Plot1dSelection.h>

namespace casa { //# NAMESPACE CASA - BEGIN

#define DERIVED

//   <summary>
//   Generic plotting interface; allows control of linestyles, axes, etc.
//   </summary>

//   <synopsis>
//   General plotting class supporting 1-d/spectral line graphics. This
//   class is utilized in PGPlot1d which presents these methods using 
//   familiar PGPLOT nomenclature. Interface provides means of specifying
//   plot parameters of line style, font, axes, legends, etc.
//   </synopsis>

//#---------------------------------------------------------------------------
class Plot1d {
public:
  enum DataStyles {lines, points, linespoints, histogram};
  enum LineStyles {noLine, solid, dashed, dotted, shortDashed, mixedDashed, 
                   dashDot};
  enum PointStyles {noPoint, dot, box, triangle, diamond, star, verticalLine,
                    horizontalLine, cross, circle, square};
  enum AxisPlacementStrategy {axisAutomaticPlacement, axisAtMinimum, 
                              axisAtMaximum, axisAtExplicitPosition};
  enum AxisType {AXIS_TYPE_UNDEFINED, RAW_AXIS, TIME_AXIS, SKYPOSITION_AXIS};

    // datasets are usually plotted against a single y axis, even if there
    // are multiple datasets.  but it is sometimes helpful to plot datasets
    // with very different y values on the same graph, and using the same
    // x axis. for example, you might wish to plot temperature and pressure
    // for a single block of time; the temperature scale would be on the
    // first y axis (usually on the left) and the pressure scale could be
    // on the second y axis (usually on the right), with time on the x
    // axis.
  enum LegendGeometry {legendNorth, legendSouth, legendEast, legendWest,
                       legendVertical, legendHorizontal,
                       legendHidden, legendVisible, legendDefault};

  Plot1d ();
  virtual  ~Plot1d ();

  // Fill in X vector and relay to function below
  Int addDataSet (Vector <Double> &y, 
		  const String &name,
		  DataStyles style = linespoints,
		  const char *xLabel = "",
		  const char *yLabel = "",
		  Plot1d::AxisType xAxisType = RAW_AXIS,
		  Plot1d::AxisType yAxisType = RAW_AXIS,
		  Plot1dData::AssociatedYAxis whichYAxis = 
		  Plot1dData::Y1Axis);

  // Make this concrete, do error checking.
  // Then relay to derived via addDataSet(Plot1dData, ...)
  //
  // The number returned is the id to use or -1
  //
  // Set the axis type and labels, log the addition in DS accounting, and
  // call the derived class's version
  // 
  Int addDataSet (Vector <Double> &x, 
		  Vector <Double> &y,
		  const String &name,
		  DataStyles style = linespoints,
		  const char *xLabel = "",
		  const char *yLabel = "",
		  Plot1d::AxisType xAxisType = RAW_AXIS,
		  Plot1d::AxisType yAxisType = RAW_AXIS,
		  Plot1dData::AssociatedYAxis whichYAxis = 
		  Plot1dData::Y1Axis);
  
private:

  //
  // If it gets to this point, then we know the dataset must be valid
  // and compatible with the axis types.
  //
  virtual Int addDataSet (Plot1dData * data, Plot1d::DataStyles) = 0;
			  

public:			  

  // neither of the following are (yet) designed to record the data
  // in this object's non-graphical data store.  the pros & cons of
  // this need to be assessed.
  // <group>
  virtual Int appendData (Int dataSet, Double x, Double y) = 0;
  virtual Int appendData (Int dataSet, Vector <Double> x,
                                       Vector <Double> y) = 0;
  // </group>

  // NEW - findDataSet takes a (public) dataSetId and sets the dataSetIterator
  //       to point to the found id and returns True or returns False
  Bool findDataSet(Int dataSetId);

  // remove a datapoint from a dataSet.  This should not be
  // pure virtual.  
  virtual Int removeDataPoint (Int dataSetId, Int index);

  // How is the data to be displayed
  virtual void setDataStyle (Int dataSetId, DataStyles dataStyle) = 0;

  // Fit data to axis typ.  Try to use specified axis, else use other
  // axis,else give up
  Plot1dData::AssociatedYAxis assignAxis(AxisType newXAxisType,
					 AxisType newYAxisType,
					 Plot1dData::AssociatedYAxis whichYAxis);

  // x axis: 0   y axis:1  z axis: 2
  void setAxisType (Int axis, AxisType axisType);

  // Simplified interface
  void setXAxisType (AxisType axisType) { xAxisType_ = axisType; }
  void setYAxisType (AxisType axisType) { setY1AxisType(axisType); }
  void setY1AxisType (AxisType axisType) { y1AxisType_ = axisType; }
  void setY2AxisType (AxisType axisType) { y2AxisType_ = axisType; }

  virtual void setTopXAxis(Bool onOff) {}
  virtual void setLeftY2Axis(Bool onOff) {}
  virtual void setRightY1Axis(Bool onOff) {}
  void setRightYAxis(Bool onOff) { setRightY1Axis(onOff); }

  virtual void setXAxisGrid(Bool onOff) { }
  void setYAxisGrid(Bool onOff) 
  { setY1AxisGrid(onOff); }
  virtual void setY1AxisGrid(Bool onOff) { }
  virtual void setY2AxisGrid(Bool onOff) { }

  AxisType xAxisType() const { return xAxisType_; }
  AxisType yAxisType() const { return y1AxisType_; }
  AxisType y1AxisType() const { return y1AxisType_; }
  AxisType y2AxisType() const { return y2AxisType_; }

  virtual void setPlotTitle (const String &newLabel);
  virtual void setPlotTitleColor(const String& color) {}
  virtual void setCursorColor(const String& color) {}

  virtual void setXAxisLineWidth(const Int newSize) {}
  virtual void setY1AxisLineWidth(const Int newSize) {}
  virtual void setY2XAxisLineWidth(const Int newSize) {}

  virtual void setXAxisGridLineWidth(const Int newSize) {}
  virtual void setY1AxisGridLineWidth(const Int newSize) {}
  virtual void setY2XAxisGridLineWidth(const Int newSize) {}

  // Set the label for the axes
  // <group>
  virtual void setXAxisLabel (const String &newLabel);
  void setYAxisLabel (const String &newLabel) { setY1AxisLabel(newLabel); }
  virtual void setY1AxisLabel (const String &newLabel);
  virtual void setY2AxisLabel (const String &newLabel);
  // </group>

  // Set the color of the axes
  // <group>
  virtual void setXAxisColor (const String& color) {}
  void setYAxisColor (const String& color) 
  { setY1AxisColor(color); }
  virtual void setY1AxisColor (const String& color) {}
  virtual void setY2AxisColor (const String& color) {}
  // </group>

  // Set the color of the axis labels
  // <group>
  virtual void setXAxisLabelColor (const String& color) {}
  void setYAxisLabelColor (const String& color) 
  { setY1AxisLabelColor(color); }
  virtual void setY1AxisLabelColor (const String& color) {}
  virtual void setY2AxisLabelColor (const String& color) {}
  // </group>

  // Set the color of the axis grid
  virtual void setXAxisGridColor (const String& color) {}
  void setYAxisGridColor (const String& color) { setY1AxisGridColor(color); }
  virtual void setY1AxisGridColor (const String& color) {}
  virtual void setY2AxisGridColor (const String& color) {}

  // Set the line color, style, and width for given dataSet id
  // <group>
  virtual void setLineColor (Int dataSetId, const String &color) = 0;
  virtual void setLineStyle (Int dataSetId, Plot1d::LineStyles lineStyle) = 0;
  virtual void setLineWidth (Int dataSetId, Int newSize) = 0;
  // </group>

  // Set the point color, style, and size for given dataSet id
  // <group>
  virtual void setPointColor (Int dataSet, const String &newColor) = 0;
  virtual void setPointStyle (Int dataSet, Plot1d::PointStyles pointStyle) = 0;
  virtual void setPointSize (Int dataSet, Int newSize) = 0;
  // </group>
 
  // set the position of the axes 
  // By default axis positioning not available
  // <group>
  virtual void setXAxisPosition (AxisPlacementStrategy strategy, Double where = 0.0) {}
  void setYAxisPosition (AxisPlacementStrategy strategy, Double where = 0.0)
  { setY1AxisPosition(strategy, where); }
  virtual void setY1AxisPosition (AxisPlacementStrategy strategy, Double where = 0.0) {}
  virtual void setY2AxisPosition (AxisPlacementStrategy strategy, Double where = 0.0) {}
  // </group>
 
  virtual void reverseXAxis () 
  { xAxisReversed_ = (xAxisReversed_ == True) ? False : True; }
  void reverseYAxis () { reverseY1Axis(); }
  virtual void reverseY1Axis () 
  { y1AxisReversed_ = (y1AxisReversed_ == True) ? False : True; }
  virtual void reverseY2Axis () 
  { y2AxisReversed_ = (y2AxisReversed_ == True) ? False : True; }

  // Default is to disable swapping
  virtual void swapY1Y2() {}
protected:
  // ... but provide implementation if derived wants
  // to enable and use it in a derived version of swapY1Y2().
  void swapY1Y2_();
public:

  virtual void setLegendGeometry (LegendGeometry newGeometry) {}

  virtual Bool printGraphToPrinter () = 0;
  virtual Bool printGraphToFile (String filename) = 0;

  // nDataSets returns the number of datasets in the list
  Int nDataSets ()     { return dataSetList_->len(); }

  // nextDataSetId() returns the next available id for data sets
  Int nextDataSetId()  { return nextDataSetId_;      }

  // #selections is internally maintained ==> Read Only
  Int nSelections () const { return selectionList_->len(); }
  Int numberOfSelections () const { return selectionList_->len(); }

  // Return a COPY of the X or Y values in the given dataSetId
  // <group>
  Vector <Double> getXValues (Int dataSetId);
  Vector <Double> getYValues (Int dataSetId);
  // </group>

  // Return a String that describes the contents of the datasets.
  String describeDataSets ();

  // Return a String that describes the contents of the selection list.
  String describeDataSelections ();

  // Return a String that describes the display styles available.
  virtual String describeDataDisplayStyles () = 0;

  // Redraw the screen
  virtual void redraw () = 0;

  // remove data, selections, initialize ancillary data, clear the plot window
  virtual void clear () = 0;

  // Remove the dataset identified by its index
  virtual Bool deleteDataSet (Int dataSetId);

  // Remove all datasets from the internal list
  void clearData() { deleteAllDataSets(); }
  void deleteAllDataSets ();

  // Remove all selections from the internal list
  void clearSelections() { deleteSelections(); }
  void deleteSelections ();

  // Draw the selections along with the points
  virtual void showSelections(Bool /*onOff*/) {}

  virtual void setSelectionColor(const String& color) {}

  // returns true if successful. all of the current selections are combined.
  // if more than one dataset is on display, then the 'frontmost' or
  // otherwise primary dataset is used.
  Bool getSelectedData (Vector <Double> &x, Vector <Double> &y);

  // The full dataset is returned, both x and y vectors, plus a logical
  // mask indicating elements have been selected.
  // <group>
  // This one chooses one from the first dataset available
  Bool getDataAndSelectionMask (Vector <Double> &x, 
				Vector <Double> &y,
                                Vector <Bool> &selectionMask);

  // This one applies the selections to the specified dataset
  Bool getDataAndSelectionMask (int dataSetId,
				Vector <Double> &x, 
				Vector <Double> &y,
                                Vector <Bool> &selectionMask);
  // </group>

   // <todo asof "1995/05/16">
   //    <li> only temporarily present here, to sidestep (glish?) bug
   //          for june 20 demo
   // </todo>
 
  virtual void placeXMarker (Double mappedX) = 0;
  virtual void placeYMarker (Double mappedY) = 0;
  virtual void enableXMarker (int onOrOff) = 0;
  virtual void enableYMarker (int onOrOff) = 0;
  virtual void setLegendAndAxisTitles (const String &title)
  { setY1AxisLabel(title); }
  virtual void setLegendAndAxisTitles (const String &title1, 
                                       const String &title2)
  { setY1AxisLabel(title1); setY2AxisLabel(title2); }

  Double xAxisMin () { return plotXMin_; }
  Double xAxisMax () { return plotXMax_; }
  Double yAxisMin () { return plotY1Min_; }
  Double yAxisMax () { return plotY1Max_; }
  Double y1AxisMin () { return plotY1Min_; }
  Double y1AxisMax () { return plotY1Max_; }
  Double y2AxisMin () { return plotY2Min_; }
  Double y2AxisMax () { return plotY2Max_; }

  // Derived Functions should call Plot1d's version, then do specific work.
  virtual void setXScale (Double x0, Double x1);
  void setYScale (Double y0, Double y1)    { setY1Scale (y0,y1); }
  virtual void setY1Scale (Double y0, Double y1);
  virtual void setY2Scale (Double y0, Double y1);

  // NEW - Return true if all plot range meets or exceeds data range.
  Bool fullScale();
  // NEW - Set plot range = data range
  //       Plot1d's version calls the setScale's above with the data ranges
  virtual void setFullScale();

  // OBS [ ] Plot1d can call virtual setScale functions
  // for XRT
  // virtual void restoreFullScale () = 0;

  //  How to select objects
  enum SelectableObjects {selectOnXAxis, selectOnYAxis, selectBoxOfData};
  SelectableObjects currentSelectable () {return currentSelectable_;};
  void setSelectable (const SelectableObjects &newValue);

  //  Dragging?
  //  Ah... Using the cursor to describe a region...
  // 
  enum DragModes {zoom, selectData};
  DragModes currentDragMode () { return dragMode_; }
  DragModes dragMode () { return dragMode_; }
  void setDragMode (const DragModes &newValue);

  //  Read Acces for data limits
  Double dataXMin () const { return dataXMin_;  }
  Double dataXMax () const { return dataXMax_;  }
  Double dataYMin () const { return dataY1Min_; }
  Double dataYMax () const { return dataY1Max_; }
  Double dataY1Min() const { return dataY1Min_; }
  Double dataY1Max() const { return dataY1Max_; }
  Double dataY2Min() const { return dataY2Min_; }
  Double dataY2Max() const { return dataY2Max_; }

  //  Read Access for plot limits (min always less than max)
  Double plotXMin () const { return plotXMin_;  }
  Double plotXMax () const { return plotXMax_;  }
  Double plotYMin () const { return plotY1Min_; }
  Double plotYMax () const { return plotY1Max_; }
  Double plotY1Min() const { return plotY1Min_; }
  Double plotY1Max() const { return plotY1Max_; }
  Double plotY2Min() const { return plotY2Min_; }
  Double plotY2Max() const { return plotY2Max_; }

  //  Read Access for plot left and right values accounting
  // for reverse flags on each axis
  Double plotXLeft() const { return (xAxisReversed_ == False) ? plotXMin_ : plotXMax_; }
  Double plotXRight() const { return (xAxisReversed_ == False) ? plotXMax_ : plotXMin_; }
  Double plotYBottom() const { return (y1AxisReversed_ == False) ? plotY1Min_ : plotY1Max_; }
  Double plotYTop() const { return (y1AxisReversed_ == False) ? plotY1Max_ : plotY1Min_; }
  Double plotY1Bottom() const { return (y1AxisReversed_ == False) ? plotY1Min_ : plotY1Max_; }
  Double plotY1Top() const { return (y1AxisReversed_ == False) ? plotY1Max_ : plotY1Min_; }
  Double plotY2Bottom() const { return (y2AxisReversed_ == False) ? plotY2Min_ : plotY2Max_; }
  Double plotY2Top() const { return (y2AxisReversed_ == False) ? plotY2Max_ : plotY2Min_; }

  const char * plotTitleChars() const { return plotTitle_.chars(); }
  const char * xAxisLabelChars() const { return xAxisLabel_.chars(); }
  const char * yAxisLabelChars() const { return y1AxisLabel_.chars(); }
  const char * y1AxisLabelChars() const { return y1AxisLabel_.chars(); }
  const char * y2AxisLabelChars() const { return y2AxisLabel_.chars(); }

  // Return the index'th selection (0-based)
  Plot1dSelection getSelection (Int selectIndex);

  // Read Access to axis reversed flags
  Bool xAxisReversed() const { return xAxisReversed_; }
  Bool yAxisReversed() const { return y1AxisReversed_; }
  Bool y1AxisReversed() const { return y1AxisReversed_; }
  Bool y2AxisReversed() const { return y2AxisReversed_; }

  // set the command string used to print including any options
  void setPrintCommand(const String & s);
  // return the print command string
  const String & printCommand() const { return printCommand_; }
  const String & queryPrintCommand() const { return printCommand_; }
  // (deprecated) set the command string to "pri -P"+printerName.
  void setPrinter (const String &printerName);

  // Surround code that makes several changes to the graph with these
  // two functions if you want to avoid having each change trigger a redraw.  
  // An underlying counter ensures redraw happens only on drawBlockExit.
  //
  // WARNING: This is a hook to an internal mechanism.  If these functions are
  // not executed in pairs, you will get strange results.
  void drawBlockEnter() { redrawEnter(); }
  void drawBlockExit() { redrawExit(); }

protected:

  void redrawEnter() { redrawSem_++; }
  void redrawExit() { redrawSem_--; if (redrawSem_==0) redraw(); }
  void redrawExitNoRedraw() { redrawSem_--; }

  // NEW reset data and plot ranges to default values
  void resetAllRanges();

  // NEW adjust ranges as needed depending on the axis
  void adjustDataRanges(Plot1dData * pd);

  // NEW recalc ranges from scratch(e.g., after a delete)
  void recomputeDataRanges();

  // OBS [ ] This is a problem because axis info is lost
  void adjustDataMinAndMax (const Vector <Double> &x, const Vector <Double> &y);

  // OBS [ ] add
  void initializeDataBounds ();

  // OBS [ ] This needs to be made obsolete
  Int recordDataSet (Vector <Double> &x, Vector <Double> &y, 
                     const String &name,
                     Plot1dData::AssociatedYAxis yAxis);

  // A "Data Selection" is a region defined in the coordinate system of the
  // plot data.
  Int recordDataSelection (Double x0, Double y0, Double x1, Double y1);

  // delete all selections
  void clearDataSelections ();

  // once a plot exists, some axis types will not make sense.
  // for instance, if the x axis displays time, neither a raw nor
  // skyposition axis makes any sense.
  Bool legalAxisType (AxisType newXAxisType, AxisType newYAxisType);

  // <todo asof="1995/06/22">
  //   <li> make the following data members private, with protected or
  //        public access functions.
  // </todo>
  SelectableObjects currentSelectable_;
  DragModes dragMode_;

  // Printer command
  String printCommand_;
  
  // Return number of data sets currently assigned to
  // the corresponding axes
  // <group>
  Int nY1DataSets() const { return nY1DataSets_; }
  Int nY2DataSets() const { return nY2DataSets_; }
  // </group>

protected:

  ListIter <Plot1dData *> * dataSetIterator() { return dataSetIterator_; }

  Int nextDataSetId() const { return nextDataSetId_; }

private:

  Int nsigfigs(Double v);
  void minMaxFromValue(Double v, Double & min, Double & max);

  // This is the redraw semaphore that enforces a single redraw
  // despite the layering of functions which require redraw.
  uInt redrawSem_;

  // Next PUBLIC id.  Resets only when deleteAllDataSets() is called
  // or nDataSets drops to zero.
  int nextDataSetId_;

  // Set if x (y) axis points to left (down)
  Bool xAxisReversed_; 
  Bool y1AxisReversed_;
  Bool y2AxisReversed_;

  // Cached number of datasets on each of y1,y2 axes
  Int nY1DataSets_;
  Int nY2DataSets_;

  // Current axis types
  AxisType xAxisType_, y1AxisType_, y2AxisType_;

  // Plot title string
  String plotTitle_;

  // Current axis labels
  String xAxisLabel_, y1AxisLabel_, y2AxisLabel_;

  // Data range and plot limits
  // "left" value is min when reversed false, max when reversed true. 
  // Same for "bottom".  This is a VERY confusing way of doing this
  //
  Double dataXMin_, dataXMax_, plotXMin_, plotXMax_;
  Double dataY1Min_, dataY1Max_, plotY1Min_, plotY1Max_;
  Double dataY2Min_, dataY2Max_, plotY2Min_, plotY2Max_;

  // Disable copy and assignment
  Plot1d (const Plot1d &);
  const Plot1d& operator = (const Plot1d &);

  // Lists and iterators for datasets and selections
  List <Plot1dData *> *dataSetList_;
  ListIter <Plot1dData *> *dataSetIterator_;

  // Sorry, had to cheat!
protected:
  List <Plot1dSelection> *selectionList_;
  ListIter <Plot1dSelection> *selectionIterator_;
};
//#---------------------------------------------------------------------------

} //# NAMESPACE CASA - END

#endif
