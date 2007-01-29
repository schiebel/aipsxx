//# DOtableplot.cc : implements the tableplot DO
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
//# $Id: DOtableplot.cc,v 1.7 2005/12/09 19:06:44 rurvashi Exp $


//# Includes

#include <iostream>
#include <cmath>

#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/MatrixMath.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Matrix.h>

#include <tables/Tables/Table.h>

#include <ms/MeasurementSets/MSFlagger.h>
#include <ms/MeasurementSets/MSSelection.h>
#include <ms/MeasurementSets/MeasurementSet.h>

#include <ms/MeasurementSets/MSRange.h>
#include <ms/MeasurementSets/MSSummary.h>
#include <ms/MeasurementSets/MSLister.h> 
#include <msvis/MSVis/SubMS.h>

#include <DOtableplot.h>

namespace casa {

/* Default Constructor */
template<class T> tableplot<T>::tableplot()
{
	adbg=0;
	if(adbg)cout << "Instantiate a tableplot obj and hence a TablePlot object" << endl;
	SinglePlot=0; IterPlot=0; IterPlotOn=0; TablesSet=0;
	IterPlotCount=0;
	TabNames.resize(0);
	DataStr.resize(0);
	Labels.resize(0);
	XDAT.resize(0,0);
	zoompanel=1;
	nTabs=0;
}

/* Destructor */
template<class T> tableplot<T>::~tableplot()
{
	if(adbg)cout << "Call ~TP()" << endl;
	if(IterPlotOn==1){TP.iterMultiPlotStop(ATBPS,TPLP);IterPlotOn=0;IterPlotCount=0;}
	for(Int i=0;i<(Int)BPS.nelements();i++) delete BPS[i];
	BPS.resize(0);
}

/* Tasking + Glish binding... */
template<class T> String tableplot<T>::className() const
{
	return("tableplot");
}


/* Tasking + Glish binding... */
template<class T> Vector<String> tableplot<T>::methods() const
{
	Vector<String> methodlist(11);
	methodlist[0] = "selectdata";
	methodlist[1] = "plotdata";
	methodlist[2] = "markflags";
	methodlist[3] = "flagdata";
	methodlist[4] = "clearflags";
	methodlist[5] = "iterplotstart";
	methodlist[6] = "settables";
	methodlist[7] = "iterplotnext";
	methodlist[8] = "iterplotstop";
	methodlist[9] = "zoomplot";
	methodlist[10] = "unflagdata";
	
	return methodlist;
}
 
/* Tasking + Glish binding... */
template<class T> MethodResult tableplot<T>::runMethod(uInt which,
                                                       ParameterSet &parameters,
                                                       Bool runMethod)
{
	static String returnvalName = "returnval";                  
	static String tabnamesName = "tabnames";                  
	static String selName = "sel";                  
	static String poptionName = "poption";                  
	static String datastrName = "datastr";                  
	static String diskwriteName = "diskwrite";                  
	static String rowflagName = "rowflag";                  
        static String iteraxesName = "iteraxes";
        static String panelName = "panel";
        static String directionName = "direction";
        static String labelsName = "labels";
	
    	switch (which) 
    	{
		case 0:
			{
			    Parameter<Vector<String> > tabnames(parameters,tabnamesName, 
			                                 ParameterSet::In); 
			    Parameter<Int> sel(parameters,selName, 
			                       ParameterSet::In); 
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    if (runMethod) 
				    returnval() = selectdata(tabnames(),sel()); 
			    break;         
			}
    
		case 1:
			{
			    Parameter<GlishRecord> poption(parameters,poptionName, 
			                           ParameterSet::In); 
			    Parameter<Vector<String> > labels(parameters,labelsName, 
			                                       ParameterSet::In); 
			    Parameter<Vector<String> > datastr(parameters,datastrName, 
			                                       ParameterSet::In); 
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = plotdata(poption(),labels(),datastr()); 
			    break;                                            
			}
		case 2:
			{
			    Parameter<Int> panel(parameters,panelName, 
			                       ParameterSet::In); 
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = markflags(panel()); 
			    break;                                            
			}
		case 3:
			{
			    Parameter<Int> diskwrite(parameters,diskwriteName, 
			                           ParameterSet::In); 
			    Parameter<Int> rowflag(parameters,rowflagName, 
			                           ParameterSet::In); 
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = flagdata(diskwrite(),rowflag()); 
			    break;                                            
			}
		case 4:
			{
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = clearflags(); 
			    break;                                            
			}
		case 5:
			{
			    Parameter<GlishRecord> poption(parameters,poptionName, 
			                           ParameterSet::In); 
			    Parameter<Vector<String> > labels(parameters,labelsName, 
			                                       ParameterSet::In); 
			    Parameter<Vector<String> > datastr(parameters,datastrName, 
			                                       ParameterSet::In); 
			    Parameter<Vector<String> > iteraxes(parameters,iteraxesName, 
			                                       ParameterSet::In); 
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = iterplotstart(poption(),labels(),datastr(),iteraxes()); 
			    break;                                            
			}
		case 6:
			{
			    Parameter<Vector<String> > tabnames(parameters,tabnamesName, 
			                                 ParameterSet::In); 
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    if (runMethod) 
				    returnval() = settables(tabnames()); 
			    break;         
			}
		case 7:
			{
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = iterplotnext(); 
			    break;                                            
			}
		case 8:
			{
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = iterplotstop(); 
			    break;                                            
			}
		case 9:
			{
			    Parameter<Int> panel(parameters,panelName, 
			                       ParameterSet::In); 
			    Parameter<Int> direction(parameters,directionName, 
			                           ParameterSet::In); 
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = zoomplot(panel(),direction()); 
			    break;                                            
			}
		case 10:
			{
			    Parameter<Int> diskwrite(parameters,diskwriteName, 
			                           ParameterSet::In); 
			    Parameter<Int> rowflag(parameters,rowflagName, 
			                           ParameterSet::In); 
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = unflagdata(diskwrite(),rowflag()); 
			    break;                                            
			}
    

		default:                                             
        	return error("Unknown method");               
	}  
	return ok();     
}

/*********************************************************************************/

/* Create a Vector of Table objects in TP 
   If MSSelection needs to be done, do it here, and pass in the subtable objects 
   to TP */

// rename this to something more appropriate -...

template<class T> Int tableplot<T>::selectdata(Vector<String> &tabnames, Int &sel)
{
	if(adbg)cout << "Select Data : call MSSelection and set tables from objects" << endl;
	if(IterPlotOn==1){TP.iterMultiPlotStop(ATBPS,TPLP);IterPlotOn=0;IterPlotCount=0;}
	
	if(nTabs > 0) 
	{
		cout << "Call 'done' and restart tableplot" << endl;
		return -1;
	}

	/* Set the total number of tables that will be simultaneously accessed */
	nTabs = tabnames.nelements();
	TabNames.resize(nTabs);
	TabNames = tabnames;

	/* Tables as Objects */ /* make sure these table-objs are writable */

	/* Call MSSelection here and get out a list of subtable objects.. */
	
	Table *TObj; // need pointer ?
	try
	{
	for(Int i=0;i<nTabs;i++) 
	{
		TObj = new Table(TabNames[i],Table::Update);
		TP.setTableT(nTabs,*TObj);
	}
	}
	catch(TableError &x)
	{
		cout << "Table Error : " << x.getMesg() << endl;
		return -1;
	}
	
	
	TablesSet=1;
	
	return 0;
}

/*********************************************************************************/

/* Take in table names and create writable table objects */
template<class T> Int tableplot<T>::settables(Vector<String> &tabnames)
{
	if(adbg)cout << "setTables : Set tables from table names " << endl;
	if(IterPlotOn==1){TP.iterMultiPlotStop(ATBPS,TPLP);IterPlotOn=0;IterPlotCount=0;}

	if(nTabs > 0) 
	{
		cout << "Call 'done' and restart tableplot" << endl;
		return -1;
	}

	nTabs = tabnames.nelements();
	if(adbg)cout << "nTabs : " << nTabs << endl;

	TabNames.resize(nTabs);
	TabNames = tabnames;

	/* Table Names as strings */
	for(Int i=0;i<nTabs;i++) 
	{
		if(TP.setTableS(nTabs,TabNames[i])==-1)
		{
			TabNames.resize(0);
			nTabs=0;
			nTabs=0;
			return -1;
		}
	}
	
	TablesSet=1;
	
	return 0;
}

/*********************************************************************************/

/* Plot data corresponding to a given set of TaQl expressions */
template<class T> Int tableplot<T>::plotdata(GlishRecord &poption, Vector<String> &labels, Vector<String> &datastr)
{
	if(adbg)cout << "Extract and Plot Data" << endl;
	if(IterPlotOn==1){TP.iterMultiPlotStop(ATBPS,TPLP);IterPlotOn=0;IterPlotCount=0;}

	if(datastr.nelements() % 2 != 0)
	{cout << "Error : Need even number of TaQL strings" << endl; return -1;}
	
	Int TQchange=1; // variable to record whether a new TAQL string has arrived or
	  		// if it's the same as before. If same, then BPs already exist
			// and need not call createBP/upDateBP or getData.

	if(adbg)cout << "datastr size : " << datastr.nelements() << endl;
	if(adbg)cout << "DataStr size : " << DataStr.nelements() << endl;
	
	if(DataStr.nelements() == datastr.nelements())
	{
		TQchange=0;
		for(Int i=0;i<(Int)datastr.nelements();i++)
			if(datastr[i].compare(DataStr[i])) TQchange=1;
	}
	if(adbg)cout << "TQchange : " << TQchange << endl;
	
	DataStr.resize(datastr.nelements());
	DataStr = datastr;
	
	NxPanels=1; NyPanels=1;
	NPanels=NxPanels*NyPanels;
	CurrentNPanels=1;
	CrossDir=0;

	// Choose number of panels based on the number of tables ! Optionally.
	
	poption.toRecord(PlotOption);
	if(PlotOption.isDefined("nxpanels"))
	{
		RecordFieldId ridnx("nxpanels");
		PlotOption.define(ridnx,NxPanels);
	}
	if(PlotOption.isDefined("nypanels"))
	{
		RecordFieldId ridny("nypanels");
		PlotOption.define(ridny,NyPanels);
	}
	
	if(PlotOption.isDefined("crossdirection"))
	{
		RecordFieldId ridcd("crossdirection");
		PlotOption.get(ridcd,CrossDir);
	}else CrossDir = 0;

	NPanels = NxPanels*NyPanels;
	
	TP.setPlotParameters(TPLP,PlotOption);
	Labels = labels;
	TP.setPlotLabels(TPLP,Labels);

	IterPlot=0;

	// Look at the first string in 'datastr' -> based on keyword, choose what to 
	//   send into createBP.

	if(adbg) cout << "start to plot..."<< endl;
	
	if(TQchange || BPS.nelements()==0)
	{
		if(adbg) cout << "Now create and update BPs" << endl;
		if(TP.createBP(BPS,datastr[0]) == 1) TP.upDateBP(BPS); 
		//if(TP.createBP(BPS) == 1) TP.upDateBP(BPS); 
		if(adbg) cout << "Now get the data" << endl;
		if(TP.getData(BPS,datastr) == -1) return -1;
		// Change the X data here if required. 
		//changexdata(BPS);
		// Change the Y data here if required. 
		//changeydata(BPS);
	}

	
	

	// Plot separately for each panel (and each table). Optionally.
	
	if(adbg) cout << "Now plot the data" << endl;
	TP.plotData(BPS,TPLP,1);

	return 0;
}

/*********************************************************************************/

/* Mark Flag region on a panel */
template<class T> Int tableplot<T>::markflags(Int panel)
{
	if(adbg)cout << "Mark Flag Regions" << endl;
	
	TP.markFlags(panel,TPLP);
	
	return 0;
}

/*********************************************************************************/

/* Zoom on a panel */
template<class T> Int tableplot<T>::zoomplot(Int panel,Int direction)
{
	if(adbg)cout << "Mark Zoom Region and PlotData" << endl;
	
	zoompanel = TP.markZoom(panel,TPLP,direction);
	
	if(zoompanel != -1)
	if(IterPlot==0) TP.plotData(BPS,TPLP,1);
	else TP.plotData(*ATBPS[panel-1],TPLP,panel);
	return 0;
}

/*********************************************************************************/

/* Flag marked regions */
template<class T> Int tableplot<T>::flagdata(Int diskwrite, Int rowflag)
{
	if(adbg)cout << "Flag Data" << endl;
	
	if(IterPlot==0) TP.flagData(BPS,TPLP,1,diskwrite,rowflag,FLAG);
	else 
	{
		//loop over panels - or only for panels with flagged regions...
		for(Int p=0;p<NPanels;p++) 
			TP.flagData(*ATBPS[p],TPLP,p+1,diskwrite,rowflag,FLAG);
	}
	

	return 0;
}
/*********************************************************************************/

/* Flag marked regions */
template<class T> Int tableplot<T>::unflagdata(Int diskwrite, Int rowflag)
{
	if(adbg)cout << "Un-Flag Data" << endl;
	
	if(IterPlot==0) TP.flagData(BPS,TPLP,1,diskwrite,rowflag,UNFLAG);
	else 
	{
		//loop over panels - or only for panels with flagged regions...
		for(Int p=0;p<NPanels;p++) 
			TP.flagData(*ATBPS[p],TPLP,p+1,diskwrite,rowflag,UNFLAG);
	}
	

	return 0;
}

/*********************************************************************************/

/* Clear all flags */
template<class T> Int tableplot<T>::clearflags()
{
	if(IterPlotOn==1){TP.iterMultiPlotStop(ATBPS,TPLP);IterPlotOn=0;IterPlotCount=0;}
	if(TablesSet==0) { cout << "Set/Select Tables first....." << endl;
			   cout << "No flags cleared" << endl;
			   return -1;
	}

	if(adbg)cout << "Clear Flags" << endl;
	
	if(TP.createBP(BPS,DataStr[0]) == 1) TP.upDateBP(BPS); 
	TP.clearFlags(BPS);
	return 0;
}

/*********************************************************************************/

/* Start iterations */
/* take in poption, datastr, and iteraxis label */
/* need to have called settables or selectdata before this.. */
template<class T> Int tableplot<T>::iterplotstart(GlishRecord &poption, Vector<String> &labels, Vector<String> &datastr, Vector<String> &iteraxes)
{
	if(adbg)cout << "Plot while iterating over an axis..." << endl;
	if(IterPlotOn==1){TP.iterMultiPlotStop(ATBPS,TPLP);IterPlotOn=0;IterPlotCount=0;}
	
	// clean up any existing BP objs... 
	TP.cleanUpBP(BPS);

	//if(BPS.nelements()>0)
	//{
	//	for(Int i=0;i<(Int)BPS.nelements();i++) delete BPS[i];
	//	BPS.resize(0,(Bool)1);
	//}

	if(datastr.nelements() % 2 != 0)
	{cout << "Error : Need even number of TaQL strings" << endl; return -1;}

	IterPlotOn=1;
	
	poption.toRecord(PlotOption);
	if(PlotOption.isDefined("nxpanels"))
	{
		RecordFieldId ridnx("nxpanels");
		PlotOption.get(ridnx,NxPanels);
	} else NxPanels = 1;
	if(PlotOption.isDefined("nypanels"))
	{
		RecordFieldId ridny("nypanels");
		PlotOption.get(ridny,NyPanels);
	}else NyPanels = 1;
	
	if(PlotOption.isDefined("crossdirection"))
	{
		RecordFieldId ridcd("crossdirection");
		PlotOption.get(ridcd,CrossDir);
	}else CrossDir = 0;

	NPanels = NxPanels*NyPanels;
	
	TP.setPlotParameters(TPLP,PlotOption);
	Labels.resize(0);
	Labels = labels;
	TP.setPlotLabels(TPLP,Labels);
	
	IterPlot=1;
	
	DataStr.resize(datastr.nelements());
	DataStr = datastr;
	IterAxes.resize(iteraxes.nelements());
	IterAxes = iteraxes;

	if(TP.iterMultiPlotStart(ATBPS,TPLP,NPanels,datastr,iteraxes)==-1)
	 return -1;
	
	iterplotnext();
	
	return 0;
}

/*********************************************************************************/

/* Advance to next set of panels */
template<class T> Int tableplot<T>::iterplotnext()
{
	if(IterPlotOn==0){cout << "End of Iterations...." << endl; return 0;}
	Int ret=0;
	Int apanels=0; // actual number of panels (maybe less than npanels for end of data)
	Vector<String> labs;
	labs.resize(0);
	labs = Labels;
	
	ret = TP.iterMultiPlotNext(ATBPS,TPLP,apanels);
	if(ret==0){IterPlotOn=0; IterPlotCount=0 ;return ret;}

	CurrentNPanels = apanels;
	
	if(ret==1)
	{
		for(Int i=0;i<apanels;i++)
		{
			if(TP.getData(*ATBPS[i],DataStr)) return -1;
			//changexdata(*ATBPS[i]);
			//changeydata(*ATBPS[i]);

			{
			IterPlotCount++;
			ostringstream buf;
			buf << Labels[0] << " : " << IterPlotCount;
			labs[0] = String(buf.str());
			}
			
			TP.setPlotLabels(TPLP,labs);
			
			TP.plotData(*ATBPS[i],TPLP,i+1);
		}

	}
	return ret;
}
/*********************************************************************************/

/* Stop iterations */
template<class T> Int tableplot<T>::iterplotstop()
{
	if(adbg)cout << " Stop iterplot..." << endl;
	if(IterPlotOn==1)
	{
		TP.iterMultiPlotStop(ATBPS,TPLP);
	}
	IterPlotCount=0;IterPlotOn=0;
	return 0;
}

/*********************************************************************************/
/* Change Data */
template<class T> Int tableplot<T>::changexdata(PtrBlock<BasePlot<T>* > &BP)
{
	if(adbg)cout << " Change xdata" << endl;
	
	for (Int i=0;i<(Int)BP.nelements();i++)
	{
		TP.readXData(BP[i],XDAT,CrossDir);

		for(Int j=0;j<XDAT.shape()[0];j++)
			for(Int k=0;k<XDAT.shape()[1];k++)
				XDAT(j,k) = XDAT(j,k)/1000;
				
		TP.writeXData(BP[i],XDAT);
	}
	
	return 0;
}

/*********************************************************************************/
/* Change Data */
template<class T> Int tableplot<T>::changeydata(PtrBlock<BasePlot<T>* > &BP)
{
	if(adbg)cout << " Change ydata" << endl;
	
	for (Int i=0;i<(Int)BP.nelements();i++)
	{
		TP.readYData(BP[i],YDAT);

		for(Int j=0;j<YDAT.shape()[0];j++)
			for(Int k=0;k<YDAT.shape()[1];k++)
				YDAT(j,k) = YDAT(j,k)/1000;
				
		TP.writeYData(BP[i],YDAT);
	}
	
	return 0;
}

/*********************************************************************************/
// Instantiate a template.
template class tableplot<Float>;

} //#End casa namespace

/*********************************************************************************/


