// Plot1d.cc: a class for plotting vectors, in many combinations and styles
//# Copyright (C) 1995,1996,1999,2001,2003
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
//# $Id: Plot1d.cc,v 19.4 2004/11/30 17:50:25 ddebonis Exp $
//#---------------------------------------------------------------------------
#include <graphics/Graphics/Plot1d.h>
#include <casa/iostream.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/BasicSL/Constants.h>
#include <casa/BasicMath/Math.h>

#include <casa/stdio.h>

namespace casa { //# NAMESPACE CASA - BEGIN

//#include <limits.h>
//#if defined(__hpux__)
//#include <float.h>                // needed for FLT_MIN
//#endif
//#---------------------------------------------------------------------------
Plot1d::Plot1d ():

	printCommand_ ("pri"),
	redrawSem_(0), 

	nextDataSetId_ (0),

	xAxisReversed_ (False),
	y1AxisReversed_ (False),
	y2AxisReversed_ (False),

	nY1DataSets_(0),
	nY2DataSets_(0),

        xAxisType_ (AXIS_TYPE_UNDEFINED),
        y1AxisType_ (AXIS_TYPE_UNDEFINED),
	y2AxisType_ (AXIS_TYPE_UNDEFINED),

	plotTitle_ (""),

        xAxisLabel_ (""),
        y1AxisLabel_ (""),
        y2AxisLabel_ (""),

	dataXMin_ (FLT_MAX),
	dataXMax_ (FLT_MIN),
	plotXMin_ (0),
	plotXMax_ (1),

	dataY1Min_ (FLT_MAX),
	dataY1Max_ (FLT_MIN),
	plotY1Min_ (0),
	plotY1Max_ (1),

	dataY2Min_ (FLT_MAX),
	dataY2Max_ (FLT_MIN),
	plotY2Min_ (0),
	plotY2Max_ (1),

        dataSetList_ (NULL),
	dataSetIterator_ (NULL),
	selectionList_ (NULL),
	selectionIterator_ (NULL)

{
  dataSetList_ = new List <Plot1dData *>();
  dataSetIterator_ = new ListIter <Plot1dData *> (dataSetList_);

  selectionList_ = new List <Plot1dSelection>();
  selectionIterator_ = new ListIter <Plot1dSelection> (selectionList_);

  // Set 0-dataset values for data and plotRanges
  resetAllRanges();
}

//#---------------------------------------------------------------------------
Plot1d::~Plot1d ()
{
 //cout << "Plot1d dtor" << endl;
 //cout << "  data sets: " << dataSetIterator_->len () << endl;

 if (dataSetList_) delete dataSetList_;
 if (dataSetIterator_) delete dataSetIterator_;

 if (selectionList_) delete selectionList_;
 if (selectionIterator_) delete selectionIterator_;
}
//#--------------------------------------------------------------------------
void Plot1d::setAxisType (Int axisNumber, AxisType axisType)
{
  switch (axisNumber) 
    {
    case 0: 
      setXAxisType(axisType);
      break;
    case 1:
      setY1AxisType(axisType);
      break;
    case 2:
      setY2AxisType(axisType);
      break;
    default:
      cerr << "Plot1d::setAxisType: Unknown axis number.";
    }
}

//
//
//  DATASET MANAGEMENT
//
//

Int Plot1d::addDataSet (Vector <Double> &y, 
			const String &name,
			DataStyles style,
			const char *xLabel,
			const char *yLabel,
			Plot1d::AxisType xAxisType,
			Plot1d::AxisType yAxisType,
			Plot1dData::AssociatedYAxis whichYAxis)
{
  Vector<Double> x(y.nelements());

  for (uInt i=0; i < y.nelements(); i++) x(i) = i;

  return addDataSet(x,y,name,style,xLabel,yLabel,xAxisType,yAxisType,whichYAxis);
}

Int Plot1d::addDataSet (Vector <Double> &x, 
			Vector <Double> &y,
			const String &name,
			DataStyles style,
			const char *xLabel,
			const char *yLabel,
			Plot1d::AxisType xAxisType,
			Plot1d::AxisType yAxisType,
			Plot1dData::AssociatedYAxis whichYAxis)
{
  // We want to ensure that we can add this dataset to the
  // (Plot1d) list of datasets.

  redrawEnter();

  // Fail if different lengths
  if (x.nelements() != y.nelements())
    {
      cerr << "pgplot::addDataSet - x,y have different lengths" << endl;
      return -1;
    }

  // Assign axis, bail if can't fit data to plot widget
  Plot1dData::AssociatedYAxis assignedAxis = 
    assignAxis(xAxisType, yAxisType, whichYAxis);

  if (assignedAxis == Plot1dData::NoAxis)
    {
      cerr << "Cannot fit new data to plot" << endl;
      return -1;
    }

  // Create an id for public use
  int publicId = nextDataSetId_;

  // Create a Plot1dData for this data
  Plot1dData * pd = new Plot1dData(x, y, name, publicId, assignedAxis);

  // Call derived add (should be void) to allow for any 
  // class specific processing or filtering
  int ok = DERIVED addDataSet(pd, style);
  if (ok < 0)
    {
      // Clean up and return failure
      delete pd;
      return ok; // ok < 0 here.
    }

  // Adjust the data ranges on the relevant axes
  adjustDataRanges(pd);

  // Set the labels if they are non-default
  if (strlen(xLabel) > 0)
    setXAxisLabel(xLabel);
  if (strlen(yLabel) > 0)
    {
      switch(assignedAxis)
	{
	case Plot1dData::NoAxis:
	  // Clean up and return failure to add
	  delete pd;
	  return -1;
	case Plot1dData::Y1Axis:
	  setY1AxisLabel(yLabel);
	  break;
	case Plot1dData::Y2Axis:
	  setY2AxisLabel(yLabel);
	  break;
	}
    }

  // If we get here, everyone is happy with the dataset, so add it
  // to the list and step the id generator.
  dataSetIterator_->toEnd();
  dataSetIterator_->addRight(pd);
  nextDataSetId_++;

  // Update the cached values of nY1DataSets/nY2DataSets
  switch(assignedAxis)
    {
    case Plot1dData::Y1Axis:
      nY1DataSets_++;
      break;
    case Plot1dData::Y2Axis:
      nY2DataSets_++;
      break;
    case Plot1dData::NoAxis:
      cerr << "Plot1d: shouldn't get here (line" << __LINE__ << ")." << endl;
      break;
    }

  // Redraw the screen using the derived class
  redrawExit();

  // Return the public id to the user
  return publicId;
}

void Plot1d::resetAllRanges()
{
  dataXMin_ = FLT_MAX;
  dataXMax_ = FLT_MIN;
  dataY1Min_ = FLT_MAX;
  dataY1Max_ = FLT_MIN;
  dataY2Min_ = FLT_MAX;
  dataY2Max_ = FLT_MIN;

  plotXMin_ = 0;
  plotXMax_ = 1;
  xAxisReversed_ = False;

  plotY1Min_ = 0;
  plotY1Max_ = 1;
  y1AxisReversed_ = False;

  plotY2Min_ = 0;
  plotY2Max_ = 1;
  y2AxisReversed_ = False;
}

void Plot1d::recomputeDataRanges()
{
  dataXMin_ = FLT_MAX;
  dataXMax_ = FLT_MIN;
  dataY1Min_ = FLT_MAX;
  dataY1Max_ = FLT_MIN;
  dataY2Min_ = FLT_MAX;
  dataY2Max_ = FLT_MIN;  

  dataSetIterator_->toStart();
  while (!dataSetIterator_->atEnd())
    {
      adjustDataRanges(dataSetIterator_->getRight());
      (*dataSetIterator_)++;
    }
}

//
//  Incorporate the new dataset and extend the min and max of the dataset
//  to incorporate the new dataset.
//
//  If the full range of data is being viewed, extend the view to include
//  the limits if needed, otherwise leave it alone
//
Int Plot1d::nsigfigs(Double v)
{
  Char buffer[80];
  if (v == 0) return 0;
  sprintf(buffer, "%e", v);
  Int n = strlen(buffer)-5;
  Int adj = 0;
  while (buffer[n] == '0')
    {
      if (buffer[n] == '.') adj = -1;
      n--;
    }
  return n+adj;
}
void Plot1d::minMaxFromValue(Double v, Double & min, Double & max)
{
  Double va = ::fabs(v);

  Int n = nsigfigs(va);
  Int ndec = int (::log10(va));
  if (ndec < 0) n++;
  Double delta = pow(10, ndec - n + 1);
  min = v - delta;
  max = v + delta;
}

void Plot1d::adjustDataRanges(Plot1dData * pd)
{
  Double pdXMin = min(pd->x());
  Double pdXMax = max(pd->x());
  Double pdYMin = min(pd->y());
  Double pdYMax = max(pd->y());

  Bool fv = fullScale();

  //cout << "fullscale query: " << fv << endl;

  dataXMin_ = (Double)((Float) min(dataXMin_, pdXMin));
  dataXMax_ = (Double)((Float) max(dataXMax_, pdXMax));

  if (nearAbs(dataXMin_, dataXMax_, 1e-5))
    minMaxFromValue(dataXMin_, dataXMin_, dataXMax_);

  switch(pd->whichYAxis())
    {
    case Plot1dData::Y1Axis:
      dataY1Min_ = (Double)((Float) min(dataY1Min_, pdYMin));
      dataY1Max_ = (Double)((Float) max(dataY1Max_, pdYMax));
      if (nearAbs(dataY1Min_, dataY1Max_, 1e-6))
	minMaxFromValue(dataY1Min_, dataY1Min_, dataY1Max_);
      break;
    case Plot1dData::Y2Axis:
      dataY2Min_ = (Double)((Float) min(dataY2Min_, pdYMin));
      dataY2Max_ = (Double)((Float) max(dataY2Max_, pdYMax));
      if (nearAbs(dataY2Min_, dataY2Max_, 1e-6))
	minMaxFromValue(dataY2Min_, dataY2Min_, dataY2Max_);
      break;
    default :
      break;
    }

  if (fv) { setFullScale(); }

  //cout << "new scales: data X  min " << dataXMin_ << " max " << dataXMax_ << endl;
  //cout << "            data Y1 min " << dataY1Min_ << " max " << dataY1Max_ << endl;
  //cout << "            data Y2 min " << dataY2Min_ << " max " << dataY2Max_ << endl;
}

//
//  Return True if the displayed screen clips no data
//
Bool Plot1d::fullScale()
{
  if (nDataSets() == 0) return True;
  if (dataXMin_ != FLT_MAX)
    if (dataXMin_ < plotXMin_ || dataXMax_ > plotXMax_) return False;
  if (nY1DataSets() > 0)
    if (dataY1Min_ < plotY1Min_ || dataY1Max_ > plotY1Max_) return False;
  if (nY2DataSets() > 0)
    if (dataY2Min_ < plotY2Min_ || dataY2Max_ > plotY2Max_) return False;
  return True;
}

// This is a good example of the redrawEnter()/redrawExit() in use.  We normally
// would get one redraw for each call to the 3 derived functions.  But the
// semaphore redrawSem_ only reaches zero at the redrawExit() in THIS function,
// and hence only a single redraw will be issued.
//
void Plot1d::setFullScale()
{
  //cout << "setFullScale" << endl;
  redrawEnter();
  //cout << "setting scales" << endl;
  if (dataXMin_ != FLT_MAX) DERIVED setXScale(dataXMin_, dataXMax_);
  if (dataY1Min_ != FLT_MAX) DERIVED setY1Scale(dataY1Min_, dataY1Max_);
  if (dataY2Min_ != FLT_MAX) DERIVED setY2Scale(dataY2Min_, dataY2Max_);
  redrawExit();
}

//
//  Programmers note:  I don't like this method of
//  dealing with axis reversing.  I'd rather see
//  left and right values kept, and you call it reversed
//  when the left value is bigger than the right value. 
//
//  Reverse would be handled by swapping the values. -JLP
//
void Plot1d::setXScale(Double xMin, Double xMax)
{
  redrawEnter();
  if (xMin != xMax)
    {
      plotXMin_ = min(xMin, xMax); 
      plotXMax_ = max(xMin, xMax);
    }
  redrawExit();
}

void Plot1d::setY1Scale(Double y1Min, Double y1Max)
{
  redrawEnter();
  if (y1Min != y1Max)
    {
      plotY1Min_ = min(y1Min,y1Max);
      plotY1Max_ = max(y1Min,y1Max);
    }
  redrawExit();
}

void Plot1d::setY2Scale(Double y2Min, Double y2Max)
{
  redrawEnter();
  if (y2Min != y2Max)
    {
      plotY2Min_ = min(y2Min,y2Max);
      plotY2Max_ = max(y2Min,y2Max);
    }
  redrawExit();
}

void Plot1d::swapY1Y2_()
{
  redrawEnter();
  
  // Switch each dataset in turn
  dataSetIterator_->toStart();
  while (!dataSetIterator_->atEnd())
    {
      Plot1dData * pd = dataSetIterator_->getRight();
      switch(pd->whichYAxis())
	{
	case Plot1dData::Y1Axis:
	  pd->setWhichYAxis(Plot1dData::Y2Axis);
	  break;
	case Plot1dData::Y2Axis:
	  pd->setWhichYAxis(Plot1dData::Y1Axis);
	  break;
	default :
	  break;
	}
      dataSetIterator_->step();
    }

  // Swap # y1,y2 datasets
  {
    int t = nY1DataSets_; 
    nY1DataSets_ = nY2DataSets_;
    nY2DataSets_ = t;
  }
  // Swap the plot and data Y ranges
  {
    // Plot ranges must be set using derivable funcs
    Double t = plotY1Min(); 
    Double u = plotY1Max();
    setY1Scale(plotY2Min(), plotY2Max());
    setY2Scale(t,u);

    // Data ranges are internal to Plot1d, so just swap
    t = dataY1Min_; dataY1Min_ = dataY2Min_; dataY2Min_ = t;
    t = dataY1Max_; dataY1Max_ = dataY2Max_; dataY2Max_ = t;
  }

  redrawExit();
}

//
//  Fit data to axis type.  Try to use desired axis, or other if desired
//  won't work.  Returns index of axis to use or throws exception.
//	
Plot1dData::AssociatedYAxis Plot1d::assignAxis(Plot1d::AxisType newXAxisType,
					       Plot1d::AxisType newYAxisType,
					       Plot1dData::AssociatedYAxis whichYAxis)
{
  // FAIL if can't match xAxis
  if (xAxisType() != AXIS_TYPE_UNDEFINED && 
      xAxisType() != newXAxisType)
    {
      return Plot1dData::NoAxis;
    }
  
  switch(whichYAxis)
    {
    case Plot1dData::Y1Axis:
      if (y1AxisType() != AXIS_TYPE_UNDEFINED &&
	  y1AxisType() != newYAxisType)
	{
	  cout << "Unable to match Y1 axis as desired.  Trying y2..." << endl;

	  if (y2AxisType() != AXIS_TYPE_UNDEFINED &&
	      y2AxisType() != newYAxisType)
	    {
	      cout << "Failed Y2 match, can't fit" << endl;
	      return Plot1dData::NoAxis;
	    }
	  else
	    {
	      cout << "Matched on Y2.  Reassigning to Y2" << endl;
	      setXAxisType(newXAxisType);
	      setY2AxisType(newYAxisType);
	      return Plot1dData::Y2Axis;
	    }
	}
      else
	{
	  // cout << "Matched on Y1.  Assigning to Y1" << endl;
	  setXAxisType(newXAxisType);
	  setY1AxisType(newYAxisType);
	  return Plot1dData::Y1Axis;
	}
      break;
    case Plot1dData::Y2Axis:
      if (y2AxisType() != AXIS_TYPE_UNDEFINED &&
	  y2AxisType() != newYAxisType)
	{
	  cout << "Unable to match Y2 axis as desired.  Trying Y1..." << endl;

	  if (y1AxisType() != AXIS_TYPE_UNDEFINED &&
	      y1AxisType() != newYAxisType)
	    {
	      cout << "Failed Y1 match, can't fit" << endl;
	      return Plot1dData::NoAxis;
	    }
	  else
	    {
	      cout << "Matched on Y1.  Reassigning to Y1" << endl;
	      setXAxisType(newXAxisType);
	      setY1AxisType(newYAxisType);
	      return Plot1dData::Y1Axis;
	    }
	}
      else
	{
	  // cout << "Matched on Y2.  Assigning to Y2" << endl;
	  setXAxisType(newXAxisType);
	  setY2AxisType(newYAxisType);
	  return Plot1dData::Y2Axis;
	}
      break;
    default :
      break;
    }
    return Plot1dData::NoAxis;
}

void Plot1d::setPlotTitle(const String& newLabel)
{
  redrawEnter();
  plotTitle_ = newLabel;
  redrawExit();
}

void Plot1d::setXAxisLabel(const String& newLabel)
{
  redrawEnter();
  xAxisLabel_ = newLabel;
  redrawExit();
}
void Plot1d::setY1AxisLabel(const String& newLabel)
{
  redrawEnter();
  y1AxisLabel_ = newLabel;
  redrawExit();
}
void Plot1d::setY2AxisLabel(const String& newLabel)
{
  redrawEnter();
  y2AxisLabel_ = newLabel;
  redrawExit();
}

//#--------------------------------------------------------------------------
Int Plot1d::recordDataSelection (Double x0, Double y0, Double x1, Double y1)
{
  Double xMin=x0, xMax=x1, yMin=y0, yMax=y1;

  if (x0 > x1) 
    {
      xMin = x1;
      xMax = x0;
    }
  if (y0 > y1) 
    {
      yMin = y1;
      yMax = y0;
    }

  Plot1dSelection selection (xMin, yMin, xMax, yMax);
  selectionIterator_->toEnd ();
  selectionIterator_->addRight (selection);
  return nSelections();   // todo: use member function
}

//#--------------------------------------------------------------------------
//  Move the iterator to the dataset given by Id
//
Bool Plot1d::findDataSet(int dataSetId)
{
  dataSetIterator_->toStart();
  while (!dataSetIterator_->atEnd())
    {
      if (dataSetIterator_->getRight()->id() == dataSetId)
	return True;
      (*dataSetIterator_)++;
    }
  return False;
}


//#--------------------------------------------------------------------------
Vector <Double> Plot1d::getXValues (Int dataSetId)
{
  if (findDataSet(dataSetId))
    return dataSetIterator_->getRight()->x();
  else
    {
      Vector<Double> temp(1); temp(0) = 0.0; return temp;
    }
}

//#--------------------------------------------------------------------------
Vector <Double> Plot1d::getYValues (Int dataSetId)
{
  if (findDataSet(dataSetId))
    return dataSetIterator_->getRight()->y();
  else
    {
      Vector<Double> temp(1); temp(0) = 0.0; return temp;
    }
}

Int Plot1d::removeDataPoint(Int dataSetId, Int ndx)
{
  if (findDataSet(dataSetId))
    {
      dataSetIterator_->getRight();
      //Plot1dData * pd = dataSetIterator_->getRight();
      // [ ] remove data point.
    }
  return 0;
}
	

//#--------------------------------------------------------------------------
// [ ] check length/reset ranges if needed
Bool Plot1d::deleteDataSet (Int dataSetId)
{
  Bool retval = False;
  redrawEnter();
  if (findDataSet(dataSetId))
    {
      Plot1dData * pd = dataSetIterator_->getRight();
      dataSetIterator_->removeRight();

      switch(pd->whichYAxis())
	{
	case Plot1dData::Y1Axis:
	  nY1DataSets_--;
	  if (nY1DataSets_ == 0)
	    {
	      setY1Scale(0,1);
	      y1AxisReversed_ = False;
	      y1AxisType_ = AXIS_TYPE_UNDEFINED;
	    }
	  break;
	case Plot1dData::Y2Axis:
	  nY2DataSets_--;
	  if (nY2DataSets_ == 0)
	    {
	      setY2Scale(0,1);
	      y2AxisReversed_ = False;
	      y2AxisType_ = AXIS_TYPE_UNDEFINED;
	    }
	  break;
	default:
	  break;
	}

      delete pd;
      recomputeDataRanges();

      if (nDataSets() == 0) 
	{
	  xAxisType_ = AXIS_TYPE_UNDEFINED;
	  y1AxisType_ = AXIS_TYPE_UNDEFINED;
	  y2AxisType_ = AXIS_TYPE_UNDEFINED;
	  resetAllRanges();
	  nextDataSetId_ = 0;
	}
      retval = True;
    }
  redrawExit();
  return retval;
}

//#--------------------------------------------------------------------------
void Plot1d::deleteAllDataSets ()
{
  redrawEnter();
#if 1
  while (nDataSets() > 0)
    {
      dataSetIterator_->toStart();
      Plot1dData * pd = dataSetIterator_->getRight();
      if (!pd) abort();
      deleteDataSet(pd->id());
    }
#endif
#if 0
  dataSetIterator_->toStart();
  while (!dataSetIterator_->atEnd()) 
    {
      Plot1dData * pd = dataSetIterator_->getRight();
      dataSetIterator_->removeRight();
      delete pd;
    }
  nextDataSetId_ = 0;
#endif
#if 0
  // todo:  probable memory leak, list won't delete contents.
  // list changed to pointer list, won't delete this one ...
  if (dataSetList_) delete dataSetList_;
  if (dataSetIterator_) delete dataSetIterator_;

  // but will delete this one.
  dataSetList_ = new List <Plot1dData>();
  dataSetIterator_ = new ListIter <Plot1dData> (dataSetList_);
  //setNumberOfDataSets (0);
#endif
  
  resetAllRanges();
  xAxisType_ = AXIS_TYPE_UNDEFINED;
  y1AxisType_ = AXIS_TYPE_UNDEFINED;
  y2AxisType_ = AXIS_TYPE_UNDEFINED;

  redrawExit();
}

//#--------------------------------------------------------------------------
//  selectIndex is 0-based
//
Plot1dSelection Plot1d::getSelection (Int selectIndex)
{
  Plot1dSelection selection;

  if (selectIndex >= nSelections ())
     return selection;  // default constructed, all zeros

  selectionIterator_->pos (selectIndex);
  return (selectionIterator_->getRight ());

}

//#--------------------------------------------------------------------------
void Plot1d::deleteSelections ()
{
#if 1
  redrawEnter();
  selectionIterator_->toStart();
  while (!selectionIterator_->atEnd()) selectionIterator_->removeRight();
  redrawExit();
#else

    // todo:  probable memory leak, list won't delete contents
  if (selectionList_) delete selectionList_;
  if (selectionIterator_) delete selectionIterator_;

  selectionList_ = new List <Plot1dSelection>();
  selectionIterator_ = new ListIter <Plot1dSelection> (selectionList_);
#endif
}

//#--------------------------------------------------------------------------
String Plot1d::describeDataSets ()
{
  String description;
  char buffer [1024];
  
  sprintf (buffer, "---- %3d data sets ----\n", dataSetIterator_->len ());
  description += buffer;

 for (dataSetIterator_->toStart (); !(dataSetIterator_->atEnd ());
     (*dataSetIterator_)++) { 
   Plot1dData * cursor = dataSetIterator_->getRight ();
   sprintf (buffer, " %3d: %20s   size: %5d  ",
            cursor->number (), cursor->name().chars(), cursor->x().nelements());
   description += buffer;
   sprintf (buffer, "  x: %f -> %f  y: %f -> %f\n",
            min (cursor->x()), max (cursor->x()), 
            min (cursor->y()), max (cursor->y()));
   description += buffer;
   } // for iterator

  return description;  
}
//#--------------------------------------------------------------------------
String Plot1d::describeDataSelections ()
{
  Plot1dSelection cursor;
  String description;
  char buffer [1024];
  
  sprintf (buffer, "----  %2d selected regions ----\n", 
           selectionIterator_->len ());
  description += buffer;
  
  Int count = 0;
  for (selectionIterator_->toStart (); !(selectionIterator_->atEnd ());
      (*selectionIterator_)++) { 
   cursor = selectionIterator_->getRight ();
   sprintf (buffer, "%2d. x: %f -> %f,  y: %f -> %f\n", count++,
            cursor.x0 (), cursor.x1 (), cursor.y0 (), cursor.y1 ());
   description += buffer;
   } // for iterator

  return description;
}
//#--------------------------------------------------------------------------
Bool Plot1d::getSelectedData (Vector <Double> &selectedX, 
                              Vector <Double> &selectedY)
/* for now, just return the most recent selection, that is, the one
 * at the end of the selection list.  
 * in the future: combine all of the selected data into one pair of vectors; 
 * and also return the number of selections that went into the combinations.
 * or provide a mechanism for the user to identify the dataset they want
 * to get from.
 */
{
  if (nSelections() == 0) return False;
  if (nDataSets() == 0) return False;

  dataSetIterator_->pos (0);  // todo -- allow selection later
  Vector <Double> candidateX = dataSetIterator_->getRight()->x();
  Vector <Double> candidateY = dataSetIterator_->getRight()->y();

  if (candidateX.nelements () != candidateY.nelements ())
    throw (AipsError ("candidate data x and y have different lengths"));

  uInt numberOfSelectedPoints = 0;
  uInt sizeOfFullDataSet = candidateX.nelements ();

  for (selectionIterator_->toStart (); !(selectionIterator_->atEnd ());
      (*selectionIterator_)++) { 
     Plot1dSelection cursor = selectionIterator_->getRight ();
     Double x0 = cursor.x0 ();
     Double x1 = cursor.x1 ();
     Double y0 = cursor.y0 ();
     Double y1 = cursor.y1 ();
     for (uInt i=0; i < sizeOfFullDataSet; i++) {
       Double x = candidateX (i);
       if (x >= x0 && x <= x1) {
         Double y = candidateY (i);
         if (y >= y0 && y <= y1) {
           numberOfSelectedPoints++;
           } // if in y range
         } // if in x range
       } // for i
     } // for selectionIterator

  //cout << "-- number of selected points: " << numberOfSelectedPoints << endl;

    // resize and fill the vectors with the selected points
  selectedX.resize (numberOfSelectedPoints);
  selectedY.resize (numberOfSelectedPoints);

  if (numberOfSelectedPoints <= 0) return True;

  uInt count = 0;
  for (selectionIterator_->toStart (); !(selectionIterator_->atEnd ());
      (*selectionIterator_)++) { 
     Plot1dSelection cursor = selectionIterator_->getRight ();
     Double x0 = cursor.x0 ();
     Double x1 = cursor.x1 ();
     Double y0 = cursor.y0 ();
     Double y1 = cursor.y1 ();
     for (uInt i=0; i < sizeOfFullDataSet; i++) {
       Double x = candidateX (i);
       if (x >= x0 && x <= x1) {
         Double y = candidateY (i);
         if (y >= y0 && y <= y1) {
           selectedX (count) = x;
           selectedY (count) = y;
           count++;
           if (count > numberOfSelectedPoints)
             throw (AipsError ("counting error while extracting selections"));
           } // if in y range
         } // if in x range
       } // for i
     } // for selectionIterator

  return True;

}  // get selected data
//#--------------------------------------------------------------------------
//
//  For Backward Compatibility
//
Bool Plot1d::getDataAndSelectionMask (Vector <Double> &x,
				      Vector <Double> &y,
				      Vector <Bool> &selectionMask)
{
  return getDataAndSelectionMask(0,x,y,selectionMask);
}

//#--------------------------------------------------------------------------
//
//  Y2 data not involved in selection????
//
Bool Plot1d::getDataAndSelectionMask (Int dataSetId,
				      Vector <Double> &x, 
				      Vector <Double> &y,
                                      Vector <Bool> &selectionMask)
{
  if (nSelections() == 0) return False;
  if (nDataSets() == 0) return False;

  if (!findDataSet(dataSetId)) throw(AipsError ("Bad Id for getDataAndSelMask"));
  Plot1dData * dataSet = dataSetIterator_->getRight();

  Int sizeOfFullDataSet = dataSet->x().nelements();
  x.resize (sizeOfFullDataSet);
  y.resize (sizeOfFullDataSet);
  selectionMask.resize (sizeOfFullDataSet);
  // all 3 vectors now have the right size, but undefined values

  // initialize the mask to False
  for (Int i=0; i < sizeOfFullDataSet; i++)
    selectionMask (i) = False; 

  x = dataSet->x ();
  y = dataSet->y ();

  uInt numberOfSelectedPoints = 0;

  for (selectionIterator_->toStart (); !(selectionIterator_->atEnd ());
      (*selectionIterator_)++) { 
     Plot1dSelection selection = selectionIterator_->getRight ();
     Double x0 = selection.x0 ();
     Double x1 = selection.x1 ();
     Double y0 = selection.y0 ();
     Double y1 = selection.y1 ();
     for (Int i=0; i < sizeOfFullDataSet; i++) {
       Double xValue = x (i);
       if (xValue >= x0 && xValue <= x1) {
         Double yValue = y (i);
         if (yValue >= y0 && yValue <= y1) {
           selectionMask (i) = True;
           numberOfSelectedPoints++;
           //cout << "mask T at index " << i << endl;
           } // if in y range
         } // if in x range
       } // for i
     } // for selectionIterator

  //cout << "-- number of selected points: " << numberOfSelectedPoints << endl;

  return True;

}  // get data with selection mask


//#--------------------------------------------------------------------------
void Plot1d::setSelectable (const SelectableObjects &newValue)
{
  currentSelectable_ = newValue;
}
//#--------------------------------------------------------------------------
void Plot1d::setDragMode (const DragModes &newValue)
{
  //cout << "new drag mode: " << newValue << endl;
  dragMode_ = newValue;
}
//#--------------------------------------------------------------------------
void Plot1d::setPrintCommand (const String &printCmd)
{
  printCommand_ = printCmd;
}
//#--------------------------------------------------------------------------
void Plot1d::setPrinter (const String &printerName)
{
  printCommand_ = "pri -P" + printerName;
}
//#--------------------------------------------------------------------------

} //# NAMESPACE CASA - END

