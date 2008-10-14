//# PlotCal.h Class to plot calibration tables
//# Copyright (C) 1996-2006
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
//# Correspondence concerning AIPS++ should be adressed as follows:
//#        Internet email: aips2-request@nrao.edu.
//#        Postal address: AIPS++ Project Office
//#                        National Radio Astronomy Observatory
//#                        520 Edgemont Road
//#                        Charlottesville, VA 22903-2475 USA
//#
//#
//# $Id: PlotCal.h,v 1.7 2006/01/13 20:46:53 kgolap Exp $
#include <casa/aips.h>




#include <tables/TablePlot/TablePlot.h>
#include <tables/TablePlot/BasePlot.h>
#include <tables/TablePlot/CrossPlot.h>
#include <tables/TablePlot/TPPlotter.h>


#ifndef CALIBRATION_PLOTCAL_H
#define CALIBRATION_PLOTCAL_H


namespace casa { //# NAMESPACE CASA - BEGIN

// forward declarations:
template <class T> class PtrBlock;
class Record;


class PlotCal
  {

// <summary> 
// PlotCal: Class to plot calibration tables.
// </summary>
// <use visibility=export>

// <reviewed reviewer="" date="" tests="" demos="">

// <prerequisite>
//   <li> <linkto class="TablePlot">TablePlot</linkto> module
// </prerequisite>
//
// <etymology>
// From "Plot" and "Calibration Table"
// </etymology>
//
// <synopsis>
// To plot calibration tables ...encapsulates knowledge of 
// different cal tables 
// </synopsis>

// <todo asof="2005/12/31">
// (i) make use of cal-iterators
// </todo>

  public:
    //Default constructor
    PlotCal();

    //Construct from a table should be a Cal table
    //PlotCal(Table& calTable);

    //Construct from a calib table name
    PlotCal(String& tabname);

    //Destructor
    virtual ~PlotCal();

    // Setting the plot look and feel
    Bool setPlotParam(Int nxPanels=1, Int nyPanels=1, String iterAxis="", 
		      Bool multiPlot=False);

    // Setting the plot selection
    Bool setSelect(Vector<Int>& antennas, Vector<Int>& caldescids, 
		   String plottype=String("PHASE")); 


    //Plot the selection and table
    Bool plot();
    
    //next iteration if necessary
    Bool next();

    //stop iterations
    Bool stop();
      
  private:
    Bool timePlotK();
    Bool plotB_G();
    Bool plotM_F();
    Bool nextAnt();
    Int multiTablesInt(String colName);
    // A little piece of replication to justify templating
    Int multiTablesDouble(String colName);
    void virtualGTab( Table& tabG, Int& nchan);
    // reorder stuff and relabel ant1 etc..for the m type
    void virtualMTab( Table& tabB, Int& nAnt, Int& nchan, 
			       Vector<Int>& ant1hash, Vector<Int>& ant2hash );
    void virtualKTab( Table& tabB, Int& nAnt, 
			       Vector<Int>& ant1hash, Vector<Int>& ant2hash );
    void createCalTab(String& tabName);
    void reformatTime(Vector<Double>& time);
		   
    Int nxPanels_p, nyPanels_p; 
    Bool multiPlot_p;
    Bool antSel_p, descIdSel_p;
    String calType_p;
    Record plotopts_p;
    TablePlot<Float> *tp_p;
    TablePlot<Float> *tpStore_p;
    TPPlotter<Float> tpl_p;
    PtrBlock<BasePlot<Float>* > BPS_p;
    PtrBlock<PtrBlock<BasePlot<Float>* > *> ATBPS_p;
    Table tab_p;
    Table* tabSel_p;
    String plotType_p;
    PtrBlock<Table *> overlayTabs_p;
    Vector<String> plotStr_p;
    Vector<String> label_p;
    Vector<Int> index_p;
    Int nextCounter_p;
    Bool iterAnt_p;
    String title_p;
    // whichPol_p determines which pol to plot
    // 0 = "R" or "X"
    // 1 = "L" or "Y"
    // 2 = "diff of phase " or "ratio of amplitude" between R and L or X and Y
    // 3 = "mean" of  "R" and "L" or "X" and "Y"  
    Int whichPol_p;



  };


} //# NAMESPACE CASA - END

#endif
   
