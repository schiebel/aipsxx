//# DOcalplot.h : implements the calplot DO
//# Copyright (C) 1994-2006
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
//# $Id: DOcalplot.h,v 1.1 2006/01/03 04:29:18 kgolap Exp $


//# Includes

#include <casa/aips.h>

#include <tasking/Glish/GlishEvent.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishValue.h>
#include <tasking/Glish/GlishRecordExpr.h>
#include <tasking/Glish/GlishRecordExpr.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <casa/Logging/LogIO.h>
#include <tasking/Tasking.h>
#include <calibration/CalTables/PlotCal.h>


namespace casa {

// <summary>
// Implements the calplot DO
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
// TablePlot
// BasePlot
// TPPlotter
// PlotCal
// </prerequisite>

// <synopsis>
//  
// </synopsis>

// <motivation>
// Provide Glish binding to PlotCal functions.
// </motivation>

// <todo asof="$DATE:$">
//# A List of extensions
//  
// </todo>


class calplot : public ApplicationObject 
{

 public:
  calplot(String& caltable);  
  ~calplot();
  
  // set plot parameters
  Bool setparameters(Int nxpanels, Int nypanels, 
		     String iteraxis="antenna", Bool multiplot=False); 
  
  // Setting the plot selection
  Bool setselect(Vector<Int>& antennas, Vector<Int>& caldescids, 
		 String plottype=String("PHASE")); 
  
  //Plot the selection and table
  Bool plot();
  
  //next iteration if necessary
  Bool next();
  
  
  // stop plot while iterating over an axis.
  Bool stopiter();     
  
  
  virtual String className() const;               
  virtual Vector<String> methods() const;                        
  virtual MethodResult runMethod(uInt which,
				 ParameterSet &parameters,
				 Bool runMethod);

 private:

  PlotCal *itsPlotCal;
		
		
};

class calplotFactory : public ApplicationObjectFactory
{
 public:
  //-------------------------------------------------------------------
  // make()
  // ------------------------
  /**
   * Override make for non-standard constructors.
   */
  //-------------------------------------------------------------------
   virtual MethodResult make (ApplicationObject*& newObject,
      const String& whichConstructor, ParameterSet& inpRec,
      Bool runConstructor);
 };


} //#End casa namespace


