//# DOmsplot.h : implements the msplot DO
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
//# $Id: DOmsplot.h,v 1.10 2005/12/07 23:29:16 gli Exp $

//# Includes

#include <casa/aips.h>

#include <tasking/Glish/GlishEvent.h>
#include <tasking/Glish/GlishRecord.h>
#include <tasking/Glish/GlishArray.h>
#include <tasking/Glish/GlishValue.h>
#include <tasking/Glish/GlishRecordExpr.h>
#include <tasking/Glish/GlishRecordExpr.h>

#include <tasking/Tasking/ApplicationObject.h>
#include <casa/Logging/LogIO.h>

#include <tasking/Tasking.h>
#include <ms/MeasurementSets/MeasurementSet.h>
#include <ms/MSPlot/MsPlot.h>
//#include <tables/TablePlot/TablePlot.h>
//#include <tables/TablePlot/BasePlot.h>
//#include <tables/TablePlot/TPPlotter.h>

#include <casa/OS/Timer.h>

#include <casa/namespace.h>


// <summary>
// Implements the msplot DO
// </summary>

// <use visibility=export>

// <reviewed reviewer="" date="yyyy/mm/dd" tests="" demos="">
// </reviewed>

// <prerequisite>
// MsPlot
// TablePlot
// BasePlot
// TPPlotter
// </prerequisite>

// <synopsis>
// DOmsplot is the DO for the msplot tool. It interprets user input
// and calls functions of the MsPlot class, to extract and plot MeasurmentSet data.
// It holds the BasePlot and TPPlotter objects, and passes them to the 
// TablePlot class which then operates on them. 
// </synopsis>

// <motivation>
// Provide Glish binding to MsPlot functions.
// </motivation>

// <todo asof="$DATE:$">
//# A List of bugs, limitations, extensions or planned refinements.
//   <li> Add more user options.
//   <li> Use the (new) MSSelection class to enable runtime subtable selection for
//        MeasurementSet tables(done). Or, use the Table(TableExprNode) function to select
//        subtables from a generic table.
//   <li> Provide options for some non-standard plots (closure quantities...)
// </todo>


template<class T> class msplot : public ApplicationObject 
{
	public:		
   // Constructor
   msplot( const String& msname);

   //#! Destructor
   // Destructor
   ~msplot();

   //#! Operators

   //#! General Member Functions
   // General Member Functions
   //#! Select a subset of the data (MeasurementSet )
   Bool setdata( const Vector<String>& antennaNames, const Vector<Int>& antennaIndex,
                 const Vector<String>& spwNames, const Vector<Int>& spwIndex,
				     const Vector<String>& fieldNames,  const Vector<Int>& fieldIndex,
				     const Vector<String>& uvDists,
				     const Vector<String>& times,
				     const Vector<String>& correlations 
               );
   // set the plotting axes ( X and Y )
	Bool setaxes( const Vector<String> &xAxes, const Vector<String> &yAxes );
   Bool setlabels( const GlishRecord &poption, Vector<String> &labels );
	// Plot UV coverage
	Int uvcoverage();
	// Plot antenna distribution in local reference frame
	Int array();
	// Plot quanties versus uv distance
	// column: data, corrected, model, residual.
	// what: amp, phase, both
	// Bool uvdist( const String& column, const String& what /*, Bool slice, Double angle */);
	Bool uvdist( const String& column, const String& what );
	// plot quantities ( amplitude, phase ) versus time. Time will be formatted later
   Bool gaintime( const String& column, const String& what, const String& iteration );
	// plot quantities ( amplitude, phase ) versus chanel( frequency, velocity ).
	Bool gainchannel( const String& column, const String& what, const String& iteration );
	// plot X verus Y for all meaningful columns in the Main table and derived quantities.
	// X, Y: Antenna1, Antenna2, Feed1, Feed2, Field_id, ifr_number, Scan_number, Time, channel, frequency,
   //       u, v, w, uvdistance, weight, data, model, corrected, residual.
   // iteration: Antenna1, Antenna2, Feed1, Feed2, Field_id, Scan_number, Time, Spectral Window/Polarization_id
	Bool plotxy( const String& X, const String& Y, const String& iteration, const String& what);
	Bool baseline( const String& column, const String& what );
	Bool hourangle( const String& column, const String& what );
	Bool azimuth( const String& column, const String& what );
	Bool elevation( const String& column, const String& what );
	Bool parallacticangle( const String& column, const String& what );
   // Plot the data
   Int plot();
	// do MSSelection and set tables as objects.
	//Int selectdata(Vector<String> &tabnames, Int &sel); 		
	// set tables from table names.
	//Int settables(Vector<String> &tabnames);
   // Take in TaQL strings and display the data.
	//Int plotdata(GlishRecord &poption, Vector<String> &labels, Vector<String> &datastr);  
	// mark regions to flag.
	Int markflags(Int panel);    		   
	// Zoom on a panel
   Int zoomplot( Int panel,Int direction ); 
	// Flag marked regions
   Int flagdata( Int diskwrite, Int rowflag );
   // Clear all flags 
   Int clearflags();
	// Start iterations
   // take in poption, datastr, and iteraxis label
   // need to have called settables or selectdata before this.
   Int iterplotstart( GlishRecord &poption, Vector<String> &labels, Vector<String> &datastr, Vector<String> &iteraxes );
   // Advance to next set of panels 
   Int iterplotnext();
	// Stop iterations 
   Int iterplotstop();

		
		virtual String className() const;               
   	virtual Vector<String> methods() const;                        
    	virtual MethodResult runMethod(uInt which, ParameterSet &parameters, Bool runMethod);

	private:	
      // enumeration for method names
       enum methodNames { SETDATA, SETAXES,SETLABELS, UVCOVERAGE, ARRAY, UVDIST, GAINTIME, GAINCHANNEL, PLOTXY,
		                    BASELINE, HOURANGLE, AZIMUTH, ELEVATION, PARALLACTICANGLE, PLOT, MARKFLAGS, FLAGDATA,
								  CLEARFLAGS, ITERPLOTSTART, ITERPLOTNEXT, ITERPLOTSTOP, ZOOMPLOT, GETACTIVETABLES };
     	Int m_adbg;
		Bool m_firstPlot;
		Bool m_iterPlot;
		Bool m_iterPlotOn;
		// indicating if the data has been set to the TABS_p of TablePlot.
		Bool m_tableSet;
		Bool m_labelSet; // indicating if the labels are set.
		Int m_nPanels;
		Int m_nXPanels,m_nYPanels;
		Record m_plotOption;
		GlishRecord m_plotOptionG;
		Vector<String> m_dataStr;
		Vector<String> m_iterAxes;
		Vector<String> m_labels;
		MsPlot<T>* m_msPlot;
		MsPlot<T>* m_msPlotMemo;
		MeasurementSet m_ms;
		TPPlotter<T> m_TPLP;
		PtrBlock<BasePlot<T>* > m_BPS;
		PtrBlock<PtrBlock<BasePlot<T>* >*> m_ATBPS;
		//Vector<String> m_dataStr;
		// functions
	// helper function to set the default plot properties
	void defaultPlotProperties( GlishRecord& plotoption );
	// check if the String axis is a valid axis for plotxt() method 
   Bool isValidAxis( const String& axis );
	// check if the String iteratio is a valid iteration axis
   Bool isValidIter( const String& iteration );
	// check if the string xy represents a data column in Main table of MS.
   Bool isData( String xy );
	// helper method to set up the TaQL string for the data axis( it could be Y or X axis.)
   Bool dataAxis( const String& column, const String& what, String& dataAxis );
	Bool dataAxesNIndices( const PtrBlock<Vector<Int>* >& polarsIndices, const Vector<Int>& chanIndices, 
						     const Vector<String>& chanRange, const String& xExpr, const String& yExpr,
							  Vector<String>& xAxes, Vector<String>& yAxes );
	Bool derivedQuantities( const String& column, const String& what, const String& quanType );	
};

template class msplot<Float>;
//msplot<Float> mspf;
// end of file

