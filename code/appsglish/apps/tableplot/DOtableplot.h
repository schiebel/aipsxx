//# DOtableplot.h : implements the tableplot DO
//# Copyright (C) 1994,1995,1996,1997,1998,1999,2000,2001,2002,2003
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
//# $Id: DOtableplot.h,v 1.7 2005/12/09 19:06:44 rurvashi Exp $


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

#include <tables/TablePlot/TablePlot.h>
#include <tables/TablePlot/BasePlot.h>
#include <tables/TablePlot/CrossPlot.h>
#include <tables/TablePlot/TPPlotter.h>

#include <casa/OS/Timer.h>


namespace casa {

// <summary>
// Implements the tableplot DO
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
// TablePlot
// BasePlot
// TPPlotter
// </prerequisite>

// <synopsis>
// DOtableplot is the DO for the tableplot tool. It interprets user input
// and calls functions of the TablePlot class, to extract and plot data.
// It holds the BasePlot and TPPlotter objects, and passes them to the 
// TablePlot class which then operates on them. 
// </synopsis>

// <motivation>
// Provide Glish binding to TablePlot functions.
// </motivation>

// <todo asof="$DATE:$">
//# A List of bugs, limitations, extensions or planned refinements.
//   <li> Add more user options.
//   <li> Use the (new) MSSelection class to enable runtime subtable selection for
//        MeasurementSet tables. Or, use the Table(TableExprNode) function to select
//        subtables from a generic table.
//   <li> Provide options for some non-standard plots (closure quantities...)
// </todo>


template<class T> class tableplot : public ApplicationObject 
{
	public:
		tableplot();  
		~tableplot();
		
		// do MSSelection and set tables as objects.
		Int selectdata(Vector<String> &tabnames, Int &sel); 
		
		// set tables from table names.
		Int settables(Vector<String> &tabnames);

		// mark regions to flag.
		Int markflags(Int panel);    
		
		// Take in TaQL strings and display the data.
		Int plotdata(GlishRecord &poption, Vector<String> &labels, Vector<String> &datastr);     
		
		// flag regions from the plot.
		Int flagdata(Int diskwrite,Int rowflag);     
		
		// flag regions from the plot.
		Int unflagdata(Int diskwrite,Int rowflag);     
		
		// zoom
		Int zoomplot(Int panel,Int direction);    
		
		// clear flags. 
		Int clearflags();   

		// plot while iterating over an axis.
		Int iterplotstart(GlishRecord &poption, Vector<String> &labels, Vector<String> &datastr, Vector<String> &iteraxes);     
		
		// plot while iterating over an axis.
		Int iterplotnext();     
		
		// plot while iterating over an axis.
		Int iterplotstop();     
		
		virtual String className() const;               
   		virtual Vector<String> methods() const;                        
    		virtual MethodResult runMethod(uInt which,
			            ParameterSet &parameters,
                                    Bool runMethod);

	private:

		Int changexdata(PtrBlock<BasePlot<T>* > &BP);
		Int changeydata(PtrBlock<BasePlot<T>* > &BP);
		
		TablePlot<T> TP;
		TPPlotter<T> TPLP;

		PtrBlock<BasePlot<T>* > BPS;
		PtrBlock<PtrBlock<BasePlot<T>* >*> ATBPS; 		

		Matrix<T> XDAT;
		Matrix<T> YDAT;

		Int NPanels;
		Int NxPanels,NyPanels;
		Int CrossDir;
	
		Vector<String> TabNames;
		Int nTabs;

		Int SinglePlot,IterPlot;

		Int IterPlotOn;
		Int TablesSet;

		Int zoompanel;
		Int CurrentNPanels;

		Vector<String> DataStr;
		Vector<String> IterAxes;
		Record PlotOption;
		Vector<String> Labels;
		uInt IterPlotCount;

		//Vector<BasePlot<T> > VBPS;
		Int adbg;
};

} //#End casa namespace


