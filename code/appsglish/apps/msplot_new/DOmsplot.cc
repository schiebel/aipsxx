//# DOmsplot.cc : implements the msplot DO
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
//# $Id: DOmsplot.cc,v 1.13 2006/08/31 23:51:36 gvandiep Exp $

//# Includes

#include <iostream>
#include <cmath>
#include <time.h>
//
#include <DOmsplot.h>
#include <casa/BasicSL/String.h>
//
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/MatrixMath.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Array.h>
#include <casa/Arrays/Matrix.h>

#include <tables/Tables/MemoryTable.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/Table.h>

#include <ms/MeasurementSets/MSFlagger.h>
#include <ms/MeasurementSets/MSSelection.h>

#include <ms/MeasurementSets/MSRange.h>
#include <ms/MeasurementSets/MSSummary.h>
#include <ms/MeasurementSets/MSLister.h> 
#include <msvis/MSVis/SubMS.h>

namespace casa {
/* Default Constructor */
template<class T> msplot<T>::msplot( const String& msName ):
   m_adbg( 1 ), m_firstPlot( True ), m_iterPlot( False ),
   m_iterPlotOn( False ), m_tableSet( False ), m_labelSet( False )
{
   if(m_adbg)cout << "Instantiate a msplot object and hence a MsPlot object" << endl;
	m_ms = MeasurementSet( msName );
	if(m_adbg)cout << "Instantiated a MeasurementSet object sucessfully!" << endl;
	m_msPlot = new MsPlot<T>( m_ms );
	if(m_adbg)cout << "Instantiated a MsPlot object sucessfully!" << endl;
	m_msPlotMemo = NULL;
	m_dataStr.resize(0);
}
/* Destructor */
template<class T> msplot<T>::~msplot()
{
	if(m_adbg)cout << "Call ~MsPlot()" << endl;
	delete m_msPlot;
	if( m_msPlotMemo != NULL ) delete m_msPlotMemo;
	//delete m_ms;
}

/* Tasking + Glish binding... */
template<class T> String msplot<T>::className() const
{
	return("msplot");
}


/* Tasking + Glish binding... */
template<class T> Vector<String> msplot<T>::methods() const
{
	Vector<String> methodlist(22);
	methodlist[SETDATA] = "setdata";
	methodlist[SETAXES] = "setaxes";
	methodlist[SETLABELS] = "setlabels";
	methodlist[UVCOVERAGE] = "uvcoverage";
	methodlist[ARRAY] = "array";
	methodlist[UVDIST] = "uvdist";
	methodlist[GAINTIME] = "gaintime";
	methodlist[GAINCHANNEL] = "gainchannel";
	methodlist[PLOTXY] = "plotxy";
	methodlist[BASELINE] = "baseline";
	methodlist[HOURANGLE] = "hourangle";
	methodlist[AZIMUTH] = "azimuth";
	methodlist[ELEVATION] = "elevation";
	methodlist[PARALLACTICANGLE] = "parallacticangle";
	methodlist[PLOT] = "plot";
	methodlist[MARKFLAGS] = "markflags";
	methodlist[FLAGDATA] = "flagdata";
	methodlist[CLEARFLAGS] = "clearflags";
	methodlist[ITERPLOTSTART] = "iterplotstart";
	methodlist[ITERPLOTNEXT] = "iterplotnext";
	methodlist[ITERPLOTSTOP] = "iterplotstop";
	methodlist[ZOOMPLOT] = "zoomplot";
	//methodlist[GETACTIVETABLES] = "getactivetables";
	
	return methodlist;
}
 
/* Tasking + Glish binding... */
template<class T> MethodResult msplot<T>::runMethod(uInt which,
                                                       ParameterSet &parameters,
                                                       Bool runMethod)
{
	static String returnvalName = "returnval";                  
	////
	static String antennaNamesName = "antennaNames";
	static String antennaIndexName = "antennaIndex";
	static String spwNamesName = "spwNames";
	static String spwIndexName = "spwIndex";
	static String fieldNamesName = "fieldNames";
	static String fieldIndexName = "fieldIndex";
	static String uvDistsName = "uvDists";
	static String timesName = "times";
	static String correlationsName = "correlations";
	static String columnName = "column";
	static String whatName = "what";
	static String xName = "X";
	static String yName ="Y";
	static String iterName = "iteration";
	//
	static String xAxesName = "xAxes";
	static String yAxesName = "yAxes";
	//                                    
	static String poptionName = "poption"; 
	static String labelsName = "labels";
	// parameter for markflags and zoomplot
	static String panelName = "panel";
	// parameters for flagData                 
	static String diskwriteName = "diskwrite";                  
	static String rowflagName = "rowflag";
	// paramters for iterplotstart                  
   static String iteraxesName = "iteraxes";                   
	static String datastrName = "datastr";
	// parameter for zoomplot
   static String directionName = "direction";	  

       	
    	switch (which) 
    	{
		case SETDATA:
			{
				 Parameter<Vector<String> > antennaNames(parameters, antennaNamesName,ParameterSet::In );
				 Parameter<Vector<Int> > antennaIndex(parameters, antennaIndexName, ParameterSet::In );
             Parameter<Vector<String> > spwNames(parameters, spwNamesName, ParameterSet::In ); 
				 Parameter<Vector<Int> > spwIndex(parameters, spwIndexName, ParameterSet::In );
				 Parameter<Vector<String> > fieldNames(parameters, fieldNamesName, ParameterSet::In );
				 Parameter<Vector<Int> > fieldIndex(parameters, fieldIndexName, ParameterSet::In );
				 Parameter<Vector<String> > uvDists(parameters, uvDistsName, ParameterSet::In );
				 Parameter<Vector<String> > times(parameters, timesName, ParameterSet::In );
				 Parameter<Vector<String> > correlations(parameters, correlationsName, ParameterSet::In );
			    Parameter<Int> returnval(parameters, returnvalName,ParameterSet::Out);
			    if( runMethod ) 
				    returnval() = setdata( antennaNames(),antennaIndex(), spwNames(), spwIndex(), fieldNames(),
					                        fieldIndex(), uvDists(), times(), correlations()); 
			    break;         
			}
    
		case SETAXES:
		   {
			    Parameter<Vector<String> > xAxes(parameters, xAxesName, ParameterSet::In ); 
				 Parameter<Vector<String> > yAxes(parameters, yAxesName, ParameterSet::In );
				 Parameter<Int> returnval(parameters, returnvalName,ParameterSet::Out);
				 if( runMethod )
				    returnval() = setaxes( xAxes(), yAxes() );
					 
				 break;
			}
		case SETLABELS:
			{
			    Parameter<GlishRecord> poption(parameters,poptionName, 
			                           ParameterSet::In); 
			    Parameter<Vector<String> > labels(parameters,labelsName, 
			                                       ParameterSet::In); 
			    Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = setlabels( poption(),labels() ); 
			    break;                                            
			}
		case UVCOVERAGE:
		   {
			   Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
				if( runMethod )
				   returnval() = uvcoverage();
				break;
			}
		case ARRAY:
		   {
			   Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
				if( runMethod )
				   returnval() = array();
				break;
			}
		case UVDIST:
		   {
			   Parameter<String> column(parameters, columnName, ParameterSet::In );
				Parameter<String> what(parameters, whatName, ParameterSet::In );
			   Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
				if( runMethod )
				   returnval() = uvdist( column(), what() );
				break;
			}
		case GAINTIME:
		   {
			   Parameter<String> column(parameters, columnName, ParameterSet::In );
				Parameter<String> what(parameters, whatName, ParameterSet::In );
				Parameter<String> iteration(parameters, iterName, ParameterSet::In );
			   Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
				if( runMethod )
				   returnval() = gaintime( column(), what(), iteration() );
				break;
			}
		case GAINCHANNEL:
		   {
			   Parameter<String> column(parameters, columnName, ParameterSet::In );
				Parameter<String> what(parameters, whatName, ParameterSet::In );
				Parameter<String> iteration(parameters, iterName, ParameterSet::In );
			   Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
				if( runMethod )
				   returnval() = gainchannel( column(), what(), iteration() );
				break;
			}
		case PLOTXY:
		   {
			   Parameter<String> X(parameters, xName, ParameterSet::In );
				Parameter<String> Y(parameters, yName, ParameterSet::In );
				Parameter<String> iteration(parameters, iterName, ParameterSet::In );
				Parameter<String> what(parameters, whatName, ParameterSet::In );
			   Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
				if( runMethod )
				   returnval() = plotxy( X(), Y(), iteration(), what() );
				break;
			}
		case BASELINE:
		   {
			   Parameter<String> column(parameters, columnName, ParameterSet::In );
				Parameter<String> what(parameters, whatName, ParameterSet::In );
			   Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
				if( runMethod )
				   returnval() = baseline( column(), what() );
				break;
			}
		case HOURANGLE:
		   {
			   Parameter<String> column(parameters, columnName, ParameterSet::In );
				Parameter<String> what(parameters, whatName, ParameterSet::In );
			   Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
				if( runMethod )
				   returnval() = hourangle( column(), what() );
				break;
			}
		case AZIMUTH:
		   {
			   Parameter<String> column(parameters, columnName, ParameterSet::In );
				Parameter<String> what(parameters, whatName, ParameterSet::In );
			   Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
				if( runMethod )
				   returnval() = azimuth( column(), what() );
				break;
			}	
		case ELEVATION:
		   {
			   Parameter<String> column(parameters, columnName, ParameterSet::In );
				Parameter<String> what(parameters, whatName, ParameterSet::In );
			   Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
				if( runMethod )
				   returnval() = elevation( column(), what() );
				break;
			}	
		case PARALLACTICANGLE:
		   {
			   Parameter<String> column(parameters, columnName, ParameterSet::In );
				Parameter<String> what(parameters, whatName, ParameterSet::In );
			   Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
				if( runMethod )
				   returnval() = parallacticangle( column(), what() );
				break;
			}				
		case PLOT:
		   {
			   Parameter<Int> returnval(parameters, returnvalName, ParameterSet::Out);
				if( runMethod )
				   returnval() = plot();
				break;
			}
		case MARKFLAGS:
			{
			    Parameter<Int> panel(parameters,panelName, 
			                       ParameterSet::In); 
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = markflags(panel()); 
			    break;                                            
			}
		case FLAGDATA:
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
		case CLEARFLAGS:
			{
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = clearflags(); 
			    break;                                            
			}
		case ITERPLOTSTART:
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
		case ITERPLOTNEXT:
			{
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = iterplotnext(); 
			    break;                                            
			}
		case ITERPLOTSTOP:
			{
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = iterplotstop(); 
			    break;                                            
			}
		case ZOOMPLOT:
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
       /*case GETACTIVETABLES:
		   {
			    Parameter<Int> returnval(parameters, returnvalName,
					             ParameterSet::Out);
			    
			    if (runMethod) 
				    returnval() = getactivetables(); 
			    break; 
			}*/

		default:                                             
        	return error("Unknown method");               
	}  
	return ok();     
}
/*********************************************************************************/
// public interface methods:
template<class T> Bool msplot<T>:: setdata( const Vector<String>& antennaNames, const Vector<Int>& antennaIndex,
                 const Vector<String>& spwNames, const Vector<Int>& spwIndex,
				     const Vector<String>& fieldNames,  const Vector<Int>& fieldIndex,
				     const Vector<String>& uvDists,
				     const Vector<String>& times,
				     const Vector<String>& correlations ){
		if( !antennaNames[0].compare(String(""))  && antennaIndex==-1
		    && !spwNames[0].compare(String(""))   && spwIndex==-1 
			 && !fieldNames[0].compare(String("")) && fieldIndex==-1
			 && !uvDists[0].compare(String(""))    && !times[0].compare(String(""))
          && !correlations[0].compare(String("")) ) {
		   cout << "[ msplot<T>::setdata() ] No value has been passed into any parameter of this method! " << endl;
			cout << " So no selection will take place and if setaxes() method is called next, the original " << endl;
			cout << " MeasurementSet will be used. " << endl;
         return False;
		}

		if(!m_msPlot->setData( antennaNames, antennaIndex, spwNames, spwIndex, fieldNames,
		    fieldIndex, uvDists, times, correlations[0] ) ) {
			 cout << "[ msplot::setData()] failed!" << endl;
			 return False;
		}
		m_tableSet = True;
		return True;					
	}
   // set the plotting axes ( X and Y )
/*********************************************************************************/
template<class T> Bool msplot<T>:: setaxes( const Vector<String> &xAxes, const Vector<String> &yAxes ){
      Int nx =xAxes.nelements();
		Vector<String> dataStr( 2*nx );
		for( Int i=0; i<nx; i++ ){
		   dataStr[ 2*i ] = xAxes[i];
		   dataStr[ 2*i+1] = yAxes[i];
		}
		if(m_adbg) cout << "[msplot<T>:: setaxes()] dataStr = " << dataStr << endl;
		// check if data is set.
		if( !m_tableSet ){
		     // no sub-dataset has been selected, so set the original MS dataset to TABS_P.
			  cout << "[ mslot<T>::setsxes() ] Set the original MS dataset to TABS_P." << endl;
			  //cout << "[ msplot<T>::setsxes() ] m_ms.historyTableName() is " << m_ms.historyTableName() << endl;
		     Int nTabs = 1;
		     //m_msPlot->setTableT( nTabs, m_ms );
			  // for some reason TablePlot::setTableT() does not work here 
			  // ( it does work in the MsPlot::setAxes()! ), so use TablePlot::setTableS() instead.
			  String msName = m_ms.tableName();
			  //cout << "[ msplot<T>::setAxes() ]  msName is " << msName << endl;
			  m_msPlot->setTableS( nTabs, msName );
		     // now the data for plotting has been set, so set the member m_dataIsSet to true.
	        m_tableSet = True; 
		 }
		 // check if the dataStr is different form the previous one. If it is diff, create a new PtrBlock<BasePlot<T>* > object.	
		if( m_adbg)cout << "[ msplot<T>:: setaxes()] datastr size : " << dataStr.nelements() << endl;
	   if( m_adbg)cout << "[ msplot<T>:: setaxes()] m_dataStr size : " << m_dataStr.nelements() << endl;
	   Bool diffDataStr = False;
	   if( m_dataStr.nelements() == dataStr.nelements())
	   {
		   for( uInt i=0;i<(uInt)dataStr.nelements();i++ )
			if(dataStr[i].compare( m_dataStr[i])){  diffDataStr = True; break; }
	   }else{ diffDataStr = True; }
	   if( m_adbg)cout << "[ msplot<T>:: setaxes()] diffDataStr = " << diffDataStr << endl;

		if( diffDataStr || m_BPS.nelements()==0)
	   {			
	      m_dataStr.resize(dataStr.nelements());
      	m_dataStr = dataStr;
		   if( m_adbg) cout << "[ msplot<T>:: setaxes()] Now create and update m_BPS" << endl;
		   if( m_msPlot->createBP( m_BPS, m_dataStr[0]) == 1) m_msPlot->upDateBP( m_BPS ); 
		   //if( m_msPLot->createBP( m_BPS ) == 1) m_msPLot->upDateBP( m_BPS ); 
	      if( !m_msPlot->setAxes( m_BPS, dataStr ) ){
		      cout <<"[ msplot::setAxes() ] failed! " << endl;
			   return False;
		   }
	   }
//
      // initialize the PtrBlock<BasePlot<T>* > object 
/*		if( m_BPS.nelements()==0 )
	   {
		   m_msPlot->createBP( m_BPS ); // to be done only ONCE !!!
		   m_msPlot->upDateBP( m_BPS ); 
	   }
		if( m_adbg ) cout<< "[ msplot::setAxes() ] &m_BPS = " << &m_BPS << endl;
	   if( !m_msPlot->setAxes( m_BPS, dataStr ) ){
		   cout <<"[ msplot::setAxes() ] failed! " << endl;
			return False;
		}
*/
		if(m_adbg)cout << "[msplot<T>:: setaxes()] setaxes() successful." << endl;
		return True;
	}
/*********************************************************************************/
template<class T> Bool msplot<T>:: setlabels( const GlishRecord &poption, Vector<String> &labels ){
     if(m_adbg)cout << "[msplot<T>:: setlabels()] setlabels() starting..." << endl;
     // convert GlidhRecord data
	  poption.toRecord( m_plotOption );
	  if( m_plotOption.isDefined("nxpanels"))
	  {
		  RecordFieldId ridnx("nxpanels");
	     m_plotOption.get(ridnx, m_nXPanels);
	  } else{ m_nXPanels = 1;}
	  if( m_plotOption.isDefined("nypanels"))
	  {
		  RecordFieldId ridny("nypanels");
		  m_plotOption.get(ridny, m_nYPanels);
	  }else{ m_nYPanels = 1;}
	  if( m_plotOption.isDefined("plotcolour"))
	  { 
	     Int l_plotcolour = 0;
		  RecordFieldId ridcolour("plotcolour");
		  m_plotOption.get( ridcolour, l_plotcolour);
		  if(m_adbg) cout << "[msplot<T>:: setlabels()] plotcolour = " << l_plotcolour << endl;
	  }
	  m_nPanels = m_nXPanels*m_nYPanels;

	  if( !m_msPlot->setLabels( m_TPLP, m_plotOption, labels )){
	     cout <<"[ msplot::setLabels() ] failed! " << endl;
		  return False;
	  }
	  m_labels.resize( labels.nelements());
	  m_labels = labels;
	  m_labelSet = True;
	  if(m_adbg)cout << "[msplot<T>:: setlabels()] setlabels() successful!" << endl;
	  return True;
	}
/*********************************************************************************/
/* Plot uv coverage (data corresponding to a given set of TaQl expressions) */
template<class T> Int msplot<T>::uvcoverage()
{
   Vector<String> xAxes(2), yAxes(2);
	xAxes[0] = "UVW[1]";
	xAxes[1] = "-UVW[1]";
	yAxes[0] = "UVW[2]";
	yAxes[1] = "-UVW[2]";
	//if( !m_labelSet ){
		GlishRecord plotOption;
      defaultPlotProperties( plotOption );
		Vector<String> labels(3);
		labels[0] = "U vs V";
		labels[1] = "U[ m ]";
		labels[2] = "V[ m ]";
		setlabels( plotOption, labels );
	//}
	setaxes( xAxes, yAxes );
	plot();
	if(m_adbg)cout << "[msplot<T>::uvCoverage()] successful." << endl;
	return 0;
}
/*********************************************************************************/
/* Plot antenna distribution( After transforming the coordinates to the local one ) */
template<class T> Int msplot<T>::array()
{
   String xAxis, yAxis;
	xAxis = "XEAST";
	yAxis = "YNORTH";
	Vector<String> dataStr(2);
	dataStr(0) = xAxis;
	dataStr(1) = yAxis;
	//SetupNewTable maker("antXY", TableDesc(), Table::New);
	//MemoryTable antXY( maker, 0, False );
	Table antXY;
	// get antenna positions as a MemoryTable
	m_msPlot->antennaPositions( antXY );
	// instantiate a local MsPlot object
	m_msPlotMemo = new MsPlot<T>();
	// set the MemoryTable to TablePlot::TABS_p.
	Int nTabs = 1;
	m_msPlotMemo->setTableT( nTabs, antXY );
	//TPPlotter<T> l_TPLP;
	//if( !m_labelSet ){
		GlishRecord plotOption;
		defaultPlotProperties( plotOption );
		plotOption.add( "linewidth", 6 );
		plotOption.add( "plotsymbol", 4 );
	  //
	   Record l_plotOption;
	   plotOption.toRecord( l_plotOption );
     //
		Vector<String> labels(3);
		labels[0] = "Antenna Locations";
		labels[1] = "X[m]";
		labels[2] = "Y[m]";
		//TPPlotter<T> m_TPLP;
		m_msPlotMemo->setLabels( m_TPLP, l_plotOption, labels );
	//}
   // initialize the PtrBlock<BasePlot<T>* > object
	//PtrBlock<BasePlot<T>* > l_BPS; 
	//m_msPlotMemo->createBP( l_BPS ); // to be done only ONCE !!!
	//m_msPlotMemo->upDateBP( l_BPS ); 
	//
	// initialize the PtrBlock<BasePlot<T>* > object 
		//if( m_BPS.nelements()==0 )
	   //{
		  // m_msPlotMemo->createBP( m_BPS ); // to be done only ONCE !!!
		  // m_msPlotMemo->upDateBP( m_BPS );
		PtrBlock<BasePlot<T>* > l_BPS; 
		if( m_msPlotMemo->createBP( l_BPS, dataStr[0]) == 1) m_msPlotMemo->upDateBP( l_BPS );
	   //}
	//
	m_msPlotMemo->setAxes( l_BPS, dataStr );
	m_msPlotMemo->plot( l_BPS, m_TPLP, 1 );

	if(m_adbg)cout << "[msplot<T>::array()] successful." << endl;
	//time_t wait = 10 + time(NULL);
   //while ( wait > time(NULL)){};
	return 0;
}
/*****************************************************************************************/
// plot quantities ( amplitude, phase, or both ) versus uv distance.
template<class T> Bool msplot<T>::uvdist( const String& column, const String& what ){
   cout <<"[msplot::uvdist()] column = " << column << endl;
	cout <<"[msplot::uvdist()] what = " << what << endl;
   if( !m_tableSet ){
	  cout << "msplot::[uvdist()] Data not set, the whole MS will be used! " << endl; 
	}
// set the labels if the user did not set it.
	if( !m_labelSet ){
		GlishRecord plotOption;
      defaultPlotProperties( plotOption );
		Vector<String> labels(3);
		labels[0] = column + " vs. uv distance";
		labels[1] = "sqrt( u^2 + v^2 ) [ m ]";
		labels[2] = column + "[ " + what + " ]";;
		setlabels( plotOption, labels );
	}
// set the indices for the data to be plot ( DATA[,], MODEL[ , ], etc.)
	PtrBlock<Vector<Int>* > polarsIndices;
	Vector<Int> chanIndices;
	Vector<String> chanRange(2);
	chanRange[0] = String("");
	chanRange[1] = String("");
	//
	Vector<String> xAxes, yAxes;
	String xExpr = "SQRT(SUMSQUARE(UVW[1:2]))";
	String yExpr;
   // get the TaQL string for Y-axis without the sub-indices
	if( !dataAxis( column, what, yExpr ) ){
		 cout<< "[msplot::uvdist()] illegal Y-axis! " << endl;
	}	
	if( m_adbg ){
	   cout<<"[msplot::uvdist()] xExpr = " << xExpr << endl;
	   cout<<"[msplot::uvdist()] yExpr = " << yExpr << endl;
	}
	//  user did not pass any value for both spw and correllatio parameter, so use all the
	//  the polariation and channels( by leaving them empty in DATA[ , ], etc.)
	if( !m_msPlot->polarNchannel( polarsIndices, chanIndices, chanRange )){
	   xAxes.resize(1);
		yAxes.resize(1);
		xAxes[0] = xExpr;
		yAxes[0] = yExpr;
		setaxes( xAxes, yAxes );
    	plot();
		return True;
	}
	// check if there are actually any polarIndices based on the user inputted spws and correlations
	uInt polarsDim = polarsIndices.nelements();
	uInt polarsDimAll = 0;	
	for( uInt i=0; i< polarsDim; i++ ){
		if( polarsIndices[i] != NULL )
			polarsDimAll = polarsDimAll + (*(polarsIndices[i])).nelements();
	}
	//
	// Even if the user inputs both spws and correlations, we may still  get nothing for polarsIndices since
	// the inputted correlations parameters may missmatch the spws

	if( polarsDimAll == 0 ){
	   polarsIndices.resize(0, True );
		if( m_adbg )cout<<"[msplot::uvdist()] polarsIndices.nelements() = " << polarsIndices.nelements() << endl;
	}

	dataAxesNIndices( polarsIndices, chanIndices, chanRange, xExpr, yExpr, xAxes, yAxes );
	setaxes( xAxes, yAxes );
	plot();
	if(m_adbg)cout << "[msplot<T>::uvdist()] successful." << endl;
	return True;
}
/*****************************************************************************************/
// plot quantities ( amplitude, phase ) versus time. Time will be formatted later
template<class T> Bool msplot<T>::gaintime( const String& column, const String& what, const String& iteration ){
   cout <<"[msplot::gaintime()] column = " << column << endl;
	cout <<"[msplot::gaintime()] what = " << what << endl;
   if( !m_tableSet ){
	  cout << "msplot::[gaintime()] Data not set, the whole MS will be used! " << endl; 
	}
// set the labels if the user did not set it.
	//if( !m_labelSet ){
	   GlishRecord plotOption;
  	   Vector<String> labels(3);
      defaultPlotProperties( plotOption );
		labels[0] = column + " vs. Time";
		labels[1] = "Time";
		labels[2] = column + "[ " + what + " ]";
		if( iteration.compare("") ){
		      plotOption.add( "nxpanels", 1 );
			   plotOption.add( "nypanels", 3 );
				plotOption.add( "fontsize", 2.0 );				
		}
		m_plotOptionG = plotOption;
		m_labels.resize(3);
		m_labels = labels;
		setlabels( plotOption, labels );
	//}
// set the indices for the data to be plot ( DATA[,], MODEL[ , ], etc.)
	PtrBlock<Vector<Int>* > polarsIndices;
	Vector<Int> chanIndices;
	Vector<String> chanRange(2);
	chanRange[0] = String("");
	chanRange[1] = String("");
	//
	Vector<String> xAxes, yAxes;
	String xExpr = "TIME";
	String yExpr;
   // get the TaQL string for Y-axis without the sub-indices
	if( !dataAxis( column, what, yExpr ) ){
		 cout<< "[msplot::gaintime()] illegal Y-axis! " << endl;
	}	
	if( m_adbg ){
	   cout<<"[msplot::gaintime()] xExpr = " << xExpr << endl;
	   cout<<"[msplot::gaintime()] yExpr = " << yExpr << endl;
	}
	//  user did not pass any value for both spw and correllation parameter, so use all the
	//  the polariation and channels( by leaving them empty in DATA[ , ], etc.)
	if( !m_msPlot->polarNchannel( polarsIndices, chanIndices, chanRange )){
	   xAxes.resize(1);
		yAxes.resize(1);
		xAxes[0] = xExpr;
		yAxes[0] = yExpr;
		setaxes( xAxes, yAxes );
    	plot();
		return True;
	}
	// check if there are actually any polarIndices based on the user inputted spws and correlations
	uInt polarsDim = polarsIndices.nelements();
	uInt polarsDimAll = 0;	
	for( uInt i=0; i< polarsDim; i++ ){
		if( polarsIndices[i] != NULL )
			polarsDimAll = polarsDimAll + (*(polarsIndices[i])).nelements();
	}
	//
	// Even if the user inputs both spws and correlations, we may still  get nothing for polarsIndices since
	// the inputted correlations parameters may missmatch the spws
	if( polarsDimAll == 0 ){
	   polarsIndices.resize(0, True );
		if( m_adbg )cout<<"[msplot::gaintime()] polarsIndices.nelements() = " << polarsIndices.nelements() << endl;
	}

	dataAxesNIndices( polarsIndices, chanIndices, chanRange, xExpr, yExpr, xAxes, yAxes );
	if( !iteration.compare( String("") ) ){
	   setaxes( xAxes, yAxes );
	   plot();
	}else{
	   if( !iteration.compare( "baseline" ) ){
		   Vector<String> iterStr(2);
			iterStr[0] = "ANTENNA1";
			iterStr[1] = "ANTENNA2";
			uInt naxes = yAxes.nelements();
		   Vector<String> dataStr( 2*naxes );
			for( uInt i=0; i<naxes; i++ ){
			   dataStr[2*i] = xAxes[i];
			   dataStr[2*i+1] = yAxes[i];
			}
	      iterplotstart( m_plotOptionG, m_labels, dataStr, iterStr);
		}else if( !iteration.compare( "antenna" ) ){
		   Vector<String> iterStr(1);
			iterStr[0] = "ANTENNA1";
			uInt naxes = yAxes.nelements();
		   Vector<String> dataStr( 2*naxes );
			for( uInt i=0; i<naxes; i++ ){
			   dataStr[2*i] = xAxes[i];
			   dataStr[2*i+1] = yAxes[i];
			}
	      iterplotstart( m_plotOptionG, m_labels, dataStr, iterStr);		
		}else if( !iteration.compare( "channel" )){
		   cout<<"[msplot::gaintime()] Iteration over channel is to be implemented." << endl;
			return False;
		}else{
		   cout<<"[msplot::gaintime()] The inputted iteration axis is invalid!" << endl;
			return False;
		}	
	}
	if(m_adbg)cout << "[msplot<T>::gaintime()] successful." << endl;
	return True;
}
/****************************************************************************************************************/
// plot quantities ( amplitude, phase ) versus chanel( frequency, velocity ).
template<class T> Bool msplot<T>::gainchannel( const String& column, const String& what, const String& iteration ){
   cout <<"[msplot::gainchannel()] column = " << column << endl;
	cout <<"[msplot::gainchannel()] what = " << what << endl;
   if( !m_tableSet ){
	  cout << "msplot::[gainchannel()] Data not set, the whole MS will be used! " << endl; 
	}
// set the labels if the user did not set it.
	//if( !m_labelSet ){
	   GlishRecord plotOption;
  	   Vector<String> labels(3);
      defaultPlotProperties( plotOption );
		labels[0] = column + " vs. Channel";
		labels[1] = "Channel";
		labels[2] = column + "[ " + what + " ]";
		if( iteration.compare("") ){
		      plotOption.add( "nxpanels", 1 );
			   plotOption.add( "nypanels", 3 );
				plotOption.add( "fontsize", 2.0 );				
		}
		m_plotOptionG = plotOption;
		m_labels.resize(3);
		m_labels = labels;
		setlabels( plotOption, labels );
	//}
// set the indices for the data to be plot ( DATA[,], MODEL[ , ], etc.)
	PtrBlock<Vector<Int>* > polarsIndices;
	Vector<Int> chanIndices;
	Vector<String> chanRange(2);
	chanRange[0] = String("");
	chanRange[1] = String("");
	//
	Vector<String> xAxes, yAxes;
	String xExpr = "CROSS"; // this indicates that it is a cross plot with channel as X-coordinate
	String yExpr;
   // get the TaQL string for Y-axis without the sub-indices
	if( !dataAxis( column, what, yExpr ) ){
		 cout<< "[msplot::gainchannel()] illegal Y-axis! " << endl;
	}	
	if( m_adbg ){
	   cout<<"[msplot::gainchannel()] xExpr = " << xExpr << endl;
	   cout<<"[msplot::gainchannel()] yExpr = " << yExpr << endl;
	}
	//  user did not pass any value for both spw and correllation parameter, so use all the
	//  the polariation and channels( by leaving them empty in DATA[ , ], etc.)
	if( !m_msPlot->polarNchannel( polarsIndices, chanIndices, chanRange )){
	   xAxes.resize(1);
		yAxes.resize(1);
		xAxes[0] = xExpr;
		yAxes[0] = yExpr;
		setaxes( xAxes, yAxes );
    	plot();
		return True;
	}
	// check if there are actually any polarIndices based on the user inputted spws and correlations
	uInt polarsDim = polarsIndices.nelements();
	uInt polarsDimAll = 0;	
	for( uInt i=0; i< polarsDim; i++ ){
		if( polarsIndices[i] != NULL )
			polarsDimAll = polarsDimAll + (*(polarsIndices[i])).nelements();
	}
	//
	// Even if the user inputs both spws and correlations, we may still  get nothing for polarsIndices since
	// the inputted correlations parameters may missmatch the spws
	if( polarsDimAll == 0 ){
	   polarsIndices.resize(0, True );
		if( m_adbg )cout<<"[msplot::gainchannel()] polarsIndices.nelements() = " << polarsIndices.nelements() << endl;
	}

	dataAxesNIndices( polarsIndices, chanIndices, chanRange, xExpr, yExpr, xAxes, yAxes );
	if( !iteration.compare( String("") ) ){
	   setaxes( xAxes, yAxes );
	   plot();
	}else{
	   if( !iteration.compare( "baseline" ) ){
		   if(m_adbg)cout << "[msplot<T>::gainchannel()] iteration axis is baseline." << endl;
		   Vector<String> iterStr(2);
			iterStr[0] = "ANTENNA1";
			iterStr[1] = "ANTENNA2";
			uInt naxes = yAxes.nelements();
		   Vector<String> dataStr( 2*naxes );
			for( uInt i=0; i<naxes; i++ ){
			   dataStr[2*i] = xAxes[i];
			   dataStr[2*i+1] = yAxes[i];
			}
	      iterplotstart( m_plotOptionG, m_labels, dataStr, iterStr);
		}else if( !iteration.compare( "antenna" ) ){
		   if(m_adbg)cout << "[msplot<T>::gainchannel()] iteration axis is ANTENNA." << endl;
		   Vector<String> iterStr(1);
			iterStr[0] = "ANTENNA1";
			uInt naxes = yAxes.nelements();
		   Vector<String> dataStr( 2*naxes );
			for( uInt i=0; i<naxes; i++ ){
			   dataStr[2*i] = xAxes[i];
			   dataStr[2*i+1] = yAxes[i];
			}
	      iterplotstart( m_plotOptionG, m_labels, dataStr, iterStr);		
		}else if( !iteration.compare( "time" )){
		   if(m_adbg)cout << "[msplot<T>::gainchannel()] iteration axis is TIME." << endl;
		   Vector<String> iterStr(1);
			iterStr[0] = "TIME";
			uInt naxes = yAxes.nelements();
		   Vector<String> dataStr( 2*naxes );
			for( uInt i=0; i<naxes; i++ ){
			   dataStr[2*i] = xAxes[i];
			   dataStr[2*i+1] = yAxes[i];
			}
	      iterplotstart( m_plotOptionG, m_labels, dataStr, iterStr);	
		}else{
		   cout<<"[msplot::gainchannel()] The inputted iteration axis is invalid!" << endl;
			return False;
		}	
	}
	if(m_adbg)cout << "[msplot<T>::gainchannel()] successful." << endl;
	return True;
}
/****************************************************************************************************/
// X, Y: Antenna1, Antenna2, Feed1, Feed2, Field_id, ifr_number, Scan_number, Time, channel, frequency,
//       u, v, w, uvdistance, weight, data, model, corrected, residual.
// iteration: Antenna1, Antenna2, Feed1, Feed2, Field_id, Scan_number, Time, Spectral Window/Polarization_id

template<class T> Bool msplot<T>::plotxy( const String& X, const String& Y, const String& iteration, const String& what){
   String Xstr = String( X );
	String Ystr = String( Y );
	String iterStr = String( iteration );
   Vector<String> xAxes(1), yAxes(1);
	xAxes[0] = String("");
	yAxes[0] = String("");
	if( !isValidAxis( X ) ){
	   cout<<"[msplot::plotxy()] Invalid X-axis inputted!" << endl;
		return False;
	}
	if( !isValidAxis( Y ) ){
	  	cout<<"[msplot::plotxy()] Invalid Y-axis inputted!" << endl;
		return False; 
	}
	// we dediced to be more tolerant. Even if the inputed iteration is illegal, we still plot, but will not iterate.
	//if( isValidIter( iteration ) ){
	//   cout<<"[msplot::plotxy()] Invalid Yiteration-axis inputted!" << endl;
	//	return False; 
	//}
	// set the TaQL string for X and Y axes
	if( isData( Y ) ){
	   if( isData( X ) ){
		   cout<<"[msplot::plotxy()] Both X and Y coordinates are data quantities, make no sense to draw!" << endl;
			return False;
		}
		if( !X.compare("uvdist")){
		   xAxes[0] = "SQRT(SUMSQUARE(UVW[1:2]))";
		}else if( !X.compare("channel") || !X.compare("frequency") || !X.compare( "ifr_number" ) ){
		   cout<<"[msplot::plotxy()] For this situation, plotxy() is to be implemented." << endl;
			return False; // change this to return True after implementation!
		}else{
		   Xstr.upcase();
		   xAxes[0] = Xstr;
			if( m_adbg ) cout<< "[msplot::plotxy()] xAxes[0] = " << xAxes[0] << endl;
		}
		if( !dataAxis( Y, what, yAxes[0] ) ){
		   cout<< "[msplot::plotxy()] illegal Y-axis! " << endl;
		}	
	}else{ // Y-axis is  not data( or model, ...) column
	   if( !X.compare( Y ) ){
		  cout<<"[msplot::plotxy()] X and Y axes are the same, make no sense to draw!"<< endl;
		  return False;		
		}
		if( !Y.compare("uvdist")){
		    yAxes[0] = "SQRT(SUMSQUARE(UVW[1:2]))";
		}else if( !Y.compare("channel") || !Y.compare("frequency") || !Y.compare( "ifr_number" ) ){
		   cout<<"[msplot::plotxy()] For this situation, plotxy() is to be implemented." << endl;
			return False;
		}else{
		   Ystr.upcase();
		   yAxes[0] = Ystr;
			if( m_adbg ) cout<< "[msplot::plotxy()] yAxes[0] = " << yAxes[0] << endl;
		}

	   if( isData( X )){
		   if( !dataAxis( X, what, xAxes[0] ) ){
		      cout<< "[msplot::plotxy()] illegal X-axis! " << endl;
		   }
	   }else if( !X.compare("uvdist")){
		   xAxes[0] = "SQRT(SUMSQUARE(UVW[1:2]))";	
		}else if( !X.compare("channel") || !X.compare("frequency") || !X.compare( "ifr_number" ) ){
		   cout<<"[msplot::plotxy()] For this situation, plotxy() is to be implemented." << endl;
			return False;
		}else{
		   Xstr.upcase();
		   xAxes[0] = Xstr;
			if( m_adbg ) cout<< "[msplot::plotxy()] xAxes[0] = " << xAxes[0] << endl;
		}	
	}
	// set the labels if the user did not set it.
	Vector<String> labels(3);
	GlishRecord plotOption;
	if( !m_labelSet ){
      defaultPlotProperties( plotOption );
		if( iteration.compare("") ){
		   if( isValidIter( iteration ) ){
		      plotOption.add( "nxpanels", 1 );
			   plotOption.add( "nypanels", 3 );
				plotOption.add( "fontsize", 2.0 );
		   }else{
			   cout<<"[msplot::plotxy()] Invalid iteration axis, ignored. " << endl;
			}
		}
 
		labels[0] = Y + " vs " + X;
		labels[1] = X;
		labels[2] = Y;
		if( isData(X) ) labels[1] = labels[1] + "[ " + what + " ]";
		if( isData(Y) ) labels[2] = labels[2] + "[ " + what + " ]";
		if( !iteration.compare("") ){
		   setlabels( plotOption, labels );
		}
	}

	// if user does not give any iteratio axis, just draw, else iterate.
	if( !iteration.compare("") ){
	   setaxes( xAxes, yAxes );
	   plot();	
	}else{
	   if( isValidIter( iteration ) ){ 
	      Vector<String> dataStr(2);
			dataStr[0] = xAxes[0];
			dataStr[1] = yAxes[0];
			iterStr.upcase();
		   Vector<String> iterAxis(1);
			iterAxis[0] = iterStr;
	      iterplotstart( plotOption, labels, dataStr, iterAxis);
		}else{
		   setaxes( xAxes, yAxes );
	      plot();
		}	
	}
   return True;
}
/*****************************************************************************************/
// plot quantities ( amplitude, phase, or both ) versus baseline.
template<class T> Bool msplot<T>::baseline( const String& column, const String& what ){
   cout <<"[msplot::baseline()] column = " << column << endl;
	cout <<"[msplot::baseline()] what = " << what << endl;
   if( !m_tableSet ){
	  cout << "msplot::[baseline()] Data not set, the whole MS will be used! " << endl; 
	}
// set the labels if the user did not set it.
	if( !m_labelSet ){
		GlishRecord plotOption;
      defaultPlotProperties( plotOption );
		Vector<String> labels(3);
		labels[0] = column + " vs. baseline";
		labels[1] = "baseline number";
		labels[2] = column + "[ " + what + " ]";;
		setlabels( plotOption, labels );
	}
// set the indices for the data to be plot ( DATA[,], MODEL[ , ], etc.)
	PtrBlock<Vector<Int>* > polarsIndices;
	Vector<Int> chanIndices;
	Vector<String> chanRange(2);
	chanRange[0] = String("");
	chanRange[1] = String("");
	//
	Vector<String> xAxes, yAxes;
	// This is how we map the baseline( antenna pair ) to a baseline number uniquely.
	String xExpr = "ANTENNA2*(ANTENNA2-1)/2+ANTENNA1+1";
	String yExpr;
   // get the TaQL string for Y-axis without the sub-indices
	if( !dataAxis( column, what, yExpr ) ){
		 cout<< "[msplot::baseline()] illegal Y-axis! " << endl;
	}	
	if( m_adbg ){
	   cout<<"[msplot::baseline()] xExpr = " << xExpr << endl;
	   cout<<"[msplot::baseline()] yExpr = " << yExpr << endl;
	}
	//  user did not pass any value for both spw and correllatio parameter, so use all the
	//  the polariation and channels( by leaving them empty in DATA[ , ], etc.)
	if( !m_msPlot->polarNchannel( polarsIndices, chanIndices, chanRange )){
	   xAxes.resize(1);
		yAxes.resize(1);
		xAxes[0] = xExpr;
		yAxes[0] = yExpr;
		setaxes( xAxes, yAxes );
    	plot();
		return True;
	}
	// check if there are actually any polarIndices based on the user inputted spws and correlations
	uInt polarsDim = polarsIndices.nelements();
	uInt polarsDimAll = 0;	
	for( uInt i=0; i< polarsDim; i++ ){
		if( polarsIndices[i] != NULL )
			polarsDimAll = polarsDimAll + (*(polarsIndices[i])).nelements();
	}
	//
	// Even if the user inputs both spws and correlations, we may still  get nothing for polarsIndices since
	// the inputted correlations parameters may missmatch the spws

	if( polarsDimAll == 0 ){
	   polarsIndices.resize(0, True );
		if( m_adbg )cout<<"[msplot::baseline()] polarsIndices.nelements() = " << polarsIndices.nelements() << endl;
	}

	dataAxesNIndices( polarsIndices, chanIndices, chanRange, xExpr, yExpr, xAxes, yAxes );
	setaxes( xAxes, yAxes );
	plot();
	if(m_adbg)cout << "[msplot<T>::baseline()] successful." << endl;
	return True;
}
/*****************************************************************************************/
// plot quantities ( amplitude, phase, or both ) versus hour angle.
template<class T> Bool msplot<T>::hourangle( const String& column, const String& what ){
    if( !derivedQuantities( column, what, "hourAngle" ) ) return False;
	 plot();
	 if( m_adbg ) cout <<"[msplot::hourangle()] successful." << endl;
	 return True;
}
/*****************************************************************************************/
// plot quantities ( amplitude, phase, or both ) versus hour angle.
template<class T> Bool msplot<T>::azimuth( const String& column, const String& what ){
    if( !derivedQuantities( column, what, "azimuth" ) ) return False;
	 plot();
	 if( m_adbg ) cout <<"[msplot::azimuth()] successful." << endl;
	 return True;
}
/*****************************************************************************************/
// plot quantities ( amplitude, phase, or both ) versus hour angle.
template<class T> Bool msplot<T>::elevation( const String& column, const String& what ){
    if( !derivedQuantities( column, what, "elevation" ) ) return False;
	 plot();
	 if( m_adbg ) cout <<"[msplot::elevation()] successful." << endl;
	 return True;
}
/*****************************************************************************************/
// plot quantities ( amplitude, phase, or both ) versus hour angle.
template<class T> Bool msplot<T>::parallacticangle( const String& column, const String& what ){
    if( !derivedQuantities( column, what, "parallacticAngle" ) ) return False;
	 plot();
	 if( m_adbg ) cout <<"[msplot::parallacticalangle()] successful." << endl;
	 return True;
}
/*****************************************************************************************/
// plot quantities ( amplitude, phase, or both ) versus derived quantities( hour angle, azimuth,
// elevation, parallactic angle ).
template<class T> Bool msplot<T>::derivedQuantities( const String& column, const String& what, const String& quanType ){
   if( m_adbg ) cout <<"[msplot::derivedQuantities()] column = " << column << endl;
	if( m_adbg ) cout <<"[msplot::derivedQuantities()] what = " << what << endl;
	if( m_adbg ) cout <<"[msplot::derivedQuantities()] quanType = " << quanType << endl;
   if( !m_tableSet ){
	  cout << "msplot::[derivedQuantities()] Data not set, the whole MS will be used! " << endl; 
	}
// set the labels if the user did not set it.
	//if( !m_labelSet ){
		GlishRecord plotOption;
      defaultPlotProperties( plotOption );
		Vector<String> labels(3);
		labels[0] = column + " vs. " + quanType;
		labels[1] = quanType;
		labels[2] = column + "[ " + what + " ]";;
		setlabels( plotOption, labels );
	//}
// set the indices for the data to be plot ( DATA[,], MODEL[ , ], etc.)
	PtrBlock<Vector<Int>* > polarsIndices;
	Vector<Int> chanIndices;
	Vector<String> chanRange(2);
	chanRange[0] = String("");
	chanRange[1] = String("");
	//
	Vector<String> xAxes, yAxes;
	// Now since the X-coordinate is derived quantity, we have to calculate it by calling MsPlot::derivedValues().
	// However, we use TIME as its initial values.
	String xExpr = "TIME";
	String yExpr;
   // get the TaQL string for Y-axis without the sub-indices
	if( !dataAxis( column, what, yExpr ) ){
		 cout<< "[msplot::derivedQuantities()] illegal Y-axis! " << endl;
	}	
	if( m_adbg ){
	   cout<<"[msplot::derivedQuantities()] xExpr = " << xExpr << endl;
	   cout<<"[msplot::derivedQuantities()] yExpr = " << yExpr << endl;
	}
	//  user did not pass any value for both spw and correllatio parameter, so use all the
	//  the polariation and channels( by leaving them empty in DATA[ , ], etc.)
	if( !m_msPlot->polarNchannel( polarsIndices, chanIndices, chanRange )){
	   xAxes.resize(1);
		yAxes.resize(1);
		xAxes[0] = xExpr;
		yAxes[0] = yExpr;
		setaxes( xAxes, yAxes );
		Vector<Double> xPlotData;
		Vector<Double> derivedQuan;
		m_msPlot->derivedValues( derivedQuan, quanType );
		Matrix <T> l_xData;
	   for( Int i=0; i<(Int)m_BPS.nelements() ; i++ ){
		   m_msPlot->readXData( m_BPS[i], l_xData );
		   if( (uInt)l_xData.shape()[1] != (uInt)derivedQuan.nelements() ){
	         cout<<"[msplot::derivedQuan()] the original data and the derived quanties has different size. Something went wrong!" << endl;
	         if( m_adbg ){ 
				   cout<<"[msplot::derivedQuanties()] l_xData.shape()[1] = " << l_xData.shape()[1] << endl;
					cout<<"[msplot::derivedQuanties()] derivedQuan.nelements() = " << derivedQuan.nelements() << endl;
				}
				return False;
			}else{
		      for(Int j=0;j< l_xData.shape()[0];j++){
			      for(Int k=0;k< l_xData.shape()[1];k++){
				     l_xData(j,k) = (T)derivedQuan(k);
				     //if( m_adbg ) cout<< "[msplot::derivedQuan() ] l_xData(" <<  j << "," << k << " ) = " << l_xData( j,k ) << endl;
					}
			   }				
	  	      m_msPlot->writeXData( m_BPS[i], l_xData );
		   }
      }
    	// plot();
		return True;
	}
	// check if there are actually any polarIndices based on the user inputted spws and correlations
	uInt polarsDim = polarsIndices.nelements();
	uInt polarsDimAll = 0;	
	for( uInt i=0; i< polarsDim; i++ ){
		if( polarsIndices[i] != NULL )
			polarsDimAll = polarsDimAll + (*(polarsIndices[i])).nelements();
	}
	//
	// Even if the user inputs both spws and correlations, we may still  get nothing for polarsIndices since
	// the inputted correlations parameters may missmatch the spws

	if( polarsDimAll == 0 ){
	   polarsIndices.resize(0, True );
		if( m_adbg )cout<<"[msplot::derivedQuantities()] polarsIndices.nelements() = " << polarsIndices.nelements() << endl;
	}

	dataAxesNIndices( polarsIndices, chanIndices, chanRange, xExpr, yExpr, xAxes, yAxes );
	setaxes( xAxes, yAxes );
	Vector<Double> xPlotData;
	Vector<Double> derivedQuan;
	//
	m_msPlot->derivedValues( derivedQuan, quanType );
	//
	Matrix <T> l_xData;
	for( uInt i=0; i<(uInt)m_BPS.nelements() ; i++ ){
		m_msPlot->readXData( m_BPS[i], l_xData );
		if( (uInt)l_xData.shape()[1] != (uInt)derivedQuan.nelements() ){
	      cout<<"[msplot::derivedQuan()] the original data and the derived quanties has different size. Something went wrong!" << endl;
	      if( m_adbg ){ 
				cout<<"[msplot::derivedQuanties()] l_xData.shape()[1] = " << l_xData.shape()[1] << endl;
			   cout<<"[msplot::derivedQuanties()] derivedQuan.nelements() = " << derivedQuan.nelements() << endl;
			}
			return False;
		}else{
		   for(Int j=0;j< l_xData.shape()[0];j++){
			   for(Int k=0;k< l_xData.shape()[1];k++){
				  l_xData(j,k) = (T)derivedQuan(k);
				  //if( m_adbg ) cout<< "[msplot::derivedQuan() ] l_xData(" <<  j << "," << k << " ) = " << l_xData( j,k ) << endl;
				}
			}
	  	   m_msPlot->writeXData( m_BPS[i], l_xData);
		}
   }
	//plot();
	if(m_adbg)cout << "[msplot<T>::derivedQuantities()] successful." << endl;
	return True;
}
/*********************************************************************************************/
/* Plot data corresponding to a given set of TaQl expressions */
template<class T> Int msplot<T>::plot()
{
	if( m_firstPlot && m_BPS.nelements() == 0 ){
		//m_msPlot->createBP (m_BPS ); // to be done only ONCE !!!
	   //m_msPlot->upDateBP(m_BPS); // to be done only ONCE !!!
		if (m_adbg )cout << "[ msplot<T>::plot() ] m_BPS nelements = " << m_BPS.nelements() << endl;
		if( m_msPlot->createBP( m_BPS, m_dataStr[0]) == 1) m_msPlot->upDateBP( m_BPS );
		m_firstPlot = False;
	}
   m_msPlot->plot( m_BPS, m_TPLP, 1 );
	if(m_adbg)cout << "[msplot<T>::plot()] plot() successful." << endl;
	return 0;
}  

/*********************************************************************************/
// get active table names
/*   template<class T>	Vector<String> msplot<T>::getactivetables(){
   Vector<Table> tables = m_msPlot->getactivetables();
	Vector<String> tableNames(tables.nelements());
	for( Int i=0; i<tables.nelements(); i++ ){
	   tableNames[i] = (String)(tables[i].tableName());
	}
   return ( tableNames ); 
}
*/
/*********************************************************************************/
/*********************************************************************************/

/* Mark Flag region on a panel */
template<class T> Int msplot<T>::markflags(Int panel)
{
	if(m_adbg)cout << "Mark Flag Regions" << endl;
	
	m_msPlot->markFlags(panel,m_TPLP);
	
	return 0;
}

/*********************************************************************************/

/* Zoom on a panel */
template<class T> Int msplot<T>::zoomplot(Int panel,Int direction)
{
	if(m_adbg)cout << "Mark Zoom Region and PlotData" << endl;
	
	Int l_zoompanel = m_msPlot->markZoom(panel,m_TPLP,direction);
	
	if( l_zoompanel != -1)
	if( !m_iterPlot ) m_msPlot->plot( m_BPS, m_TPLP, 1 );
	else m_msPlot->plot( *m_ATBPS[panel-1], m_TPLP, panel);
	return 0;
}

/*********************************************************************************/

/* Flag marked regions */
template<class T> Int msplot<T>::flagdata(Int diskwrite, Int rowflag)
{
	if( m_adbg )cout << "Flag Data" << endl;
	
	if( !m_iterPlot ) m_msPlot->flagData( m_BPS, m_TPLP, 1, diskwrite, rowflag, 0 );
	else 
	{
		//loop over panels - or only for panels with flagged regions...
		for(Int i=0;i< m_nPanels;i++) 
			m_msPlot->flagData(*m_ATBPS[i],m_TPLP,i+1, diskwrite, rowflag, 0 );
	}

	return 0;
}

/*********************************************************************************/

/* Clear all flags */
template<class T> Int msplot<T>::clearflags()
{
	if( m_iterPlotOn ){
	    m_msPlot->iterMultiPlotStop(m_ATBPS,m_TPLP);
		 m_iterPlotOn = False;
	}
	// check if data is set.
	if( !m_tableSet ){
		 // no sub-dataset has been selected, so set the original MS dataset to TABS_P.
		cout << "[ msplot<T>::clearflags() ] Set the original MS dataset to TABS_P." << endl;
		cout << "[ msplot<T>::clearflags() ] m_ms.historyTableName() is " << m_ms.historyTableName() << endl;
		Int nTabs = 1;
		//m_msPlot->setTableT( nTabs, m_ms );
	   // for some reason TablePlot::setTableT() does not work here 
		// ( it does work in the MsPlot::setAxes()! ), so use TablePlot::setTableS() instead.
		String msName = m_ms.tableName();
		//cout << "[ msplot<T>::setAxes() ]  msName is " << msName << endl;
		m_msPlot->setTableS( nTabs, msName );
		// now the data for plotting has been set, so set the member m_dataIsSet to true.
	   m_tableSet = True; 
	}
	// check if the m_BPS is initialized.	
	if( m_BPS.nelements()==0 )
	{
		//m_msPlot->createBP( m_BPS ); // to be done only ONCE !!!
		//m_msPlot->upDateBP( m_BPS ); 
		if( m_msPlot->createBP( m_BPS, m_dataStr[0]) == 1) m_msPlot->upDateBP( m_BPS );
	}
	m_msPlot->clearFlags( m_BPS );
	if( m_adbg )cout << "[msplot<T>::clearflags()] Cleared Flags" << endl;
	return 0;
}

/*********************************************************************************/

/* Start iterations */
/* take in poption, datastr, and iteraxis label */
/* need to have called settables or selectdata before this.. */
template<class T> Int msplot<T>::iterplotstart(GlishRecord &poption, Vector<String> &labels, Vector<String> &datastr, Vector<String> &iteraxes)
{
	if(m_adbg)cout << "[ msplot<T>::iterplotstart() ] Plot while iterating over axis. " << endl;
	if( m_iterPlotOn ){
	   m_msPlot->iterMultiPlotStop(m_ATBPS,m_TPLP);
		m_iterPlotOn = False;
	}

	if(datastr.nelements() % 2 != 0){
	   cout << "[ msplot<T>::iterplotstart() ] Error : Need even number of TaQL strings" << endl;
	   return -1;
	}
	// check if data is set.
	if( !m_tableSet ){
		 // no sub-dataset has been selected, so set the original MS dataset to TABS_P.
		cout << "[ msplot<T>::iterplotstart() ] Set the original MS dataset to TABS_P." << endl;
		cout << "[ msplot<T>::iterplotstart() ] m_ms.historyTableName() is " << m_ms.historyTableName() << endl;
		Int nTabs = 1;
		//m_msPlot->setTableT( nTabs, m_ms );
	   // for some reason TablePlot::setTableT() does not work here 
		// ( it does work in the MsPlot::setAxes()! ), so use TablePlot::setTableS() instead.
		String msName = m_ms.tableName();
		//cout << "[ msplot<T>::setAxes() ]  msName is " << msName << endl;
		m_msPlot->setTableS( nTabs, msName );
		// now the data for plotting has been set, so set the member m_dataIsSet to true.
	   m_tableSet = True; 
	}	
   // convert GlidhRecord data
	poption.toRecord( m_plotOption );
	if( m_plotOption.isDefined("nxpanels"))
	{
		RecordFieldId ridnx("nxpanels");
		m_plotOption.get(ridnx, m_nXPanels);
	} else{ m_nXPanels = 1;}
	if( m_plotOption.isDefined("nypanels"))
	{
		RecordFieldId ridny("nypanels");
		m_plotOption.get(ridny, m_nYPanels);
	}else{ m_nYPanels = 1;}
	m_nPanels = m_nXPanels*m_nYPanels;
	// use setLabels() instead?	
	// m_msPlot->setPlotParameters( m_TPLP, m_plotOption,labels );	
	m_msPlot->setPlotParameters( m_TPLP, m_plotOption );
	m_msPlot->setPlotLabels( m_TPLP,labels );
	m_iterPlot = True;
	
	m_dataStr.resize(datastr.nelements());
	m_dataStr = datastr;
	m_iterAxes = iteraxes;

	if( m_msPlot->iterMultiPlotStart( m_ATBPS, m_TPLP, m_nPanels, datastr,iteraxes )==-1)
	 return -1;
	
	m_iterPlotOn = True;
	iterplotnext();
	
	return 0;
}

/*********************************************************************************/

/* Advance to next set of panels */
template<class T> Int msplot<T>::iterplotnext()
{
	if( !m_iterPlotOn ){cout << "End of Iterations...." << endl; return 0;}
	Int l_retVal = 0;
	Int l_nPanels = 0; // actual number of panels (maybe less than npanels for end of data)	
	l_retVal = m_msPlot->iterMultiPlotNext(m_ATBPS,m_TPLP, l_nPanels);
	if( l_retVal == 0 ){
	   m_iterPlotOn = False;
	   return l_retVal;
	}else{
	   if( m_adbg ) cout << "[ msplot<T>::iterplotnext() ] l_nPanels = " << l_nPanels << endl;
		for( Int i=0;i< l_nPanels;i++)
		{
			if( !m_msPlot->setAxes( *m_ATBPS[i], m_dataStr) ) return -1;
			m_msPlot->plot( *m_ATBPS[i], m_TPLP, i+1 );
		}
	}
	return l_retVal;
}
/*********************************************************************************/

/* Stop iterations */
template<class T> Int msplot<T>::iterplotstop()
{
	if( m_adbg )cout << " Stop iterplot..." << endl;
	if( m_iterPlot )
	{
		m_msPlot->iterMultiPlotStop( m_ATBPS, m_TPLP);
	}
	m_iterPlotOn = False;
	return 0;
}
/*********************************************************************************/
/* Set default plot properties */
template<class T> void msplot<T>::defaultPlotProperties( GlishRecord& plotoption )
{
		plotoption.add( "nxpanels", GlishArray(1) );
		plotoption.add( "nypanels", GlishArray(1) );
		plotoption.add( "windowsize", 8 );
		plotoption.add( "aspectratio", 1 );
		plotoption.add( "plotstyle", 1 );
		plotoption.add( "plotcolour", 21 );
		plotoption.add( "fontsize", 1.0 );
}
/*****************************************************************************************************/
// check if the String axis is a valid axis for plotxt() method 
template<class T> Bool msplot<T>::isValidAxis( const String& axis ){
   if( axis.compare( String( "antenna1" )) || axis.compare( String("antenna2" )) ||
	    axis.compare( String( "feed1" )) || axis.compare( String("feed2" )) ||
		 axis.compare( String( "field_id" )) || axis.compare( String("ifr_number" )) ||
		 axis.compare( String( "scan_number" )) ||axis.compare( String( "time" )) ||
		 axis.compare( String( "channel" )) || axis.compare( String( "frequency" )) ||
		 axis.compare( String( "u" )) || axis.compare( String( "v" )) ||
		 axis.compare( String( "w" )) || axis.compare( String( "uvdistance" )) ||
		 /*axis.compare( String( "weight" )) ||*/ axis.compare( String( "data" )) ||
		 axis.compare( String( "model" )) || axis.compare( String( "corrected" )) ||
		 axis.compare( String( "residual" )) ){
	   return True;	 
	}
   return False;
}
// check if the String iteratio is a valid iteration axis
template<class T> Bool msplot<T>:: isValidIter( const String& iteration ){
   if( iteration.compare( String( "antenna1" )) || iteration.compare( String("antenna2" )) ||
	    iteration.compare( String( "feed1" )) || iteration.compare( String("feed2" )) ||
		 iteration.compare( String( "field_id" )) || iteration.compare( String( "scan_number" )) ||
		 iteration.compare( String( "time" )) /* || iteration.compare( String( "spectral_window" )) ||
		 iteration.compare( String( "polarization_id" ))*/ ){
	   return True;	 
	} 
   return False;
}
/********************************************************************************************/
// check if the string xy represents a data column in Main table of MS.
template<class T> Bool msplot<T>::isData( String xy ){
    if( !xy.compare("data") || !xy.compare("model" ) || !xy.compare("corrected" ) || !xy.compare("residual") ){
	    return True;
	 }
	 return False;
}
/*****************************************************************************************************/
// helper method to set up the TaQL string for the data axis without the sub-indices( it could be Y or X axis.)
template<class T> Bool msplot<T>::dataAxis( const String& column, const String& what, String& dataAxis ){
   String yExpr;
	if( !column.compare( String("data") )){
	   if( !what.compare(String("amp"))){
	     yExpr = String("AMPLITUDE(DATA[,])" );
		}else if( !what.compare(String("phase"))){
		  yExpr = String("PHASE(DATA[,])" );
		}else if( !what.compare(String("both"))){
		   cout<<"[msplot::dataAxis() To be implemented." << endl;
		}else{
		   cout<<"[msplot::dataAxis()] Iputted wrong value for parameter what!" << endl;
			return False;
		}
	}else if( !column.compare( String("model"))){
	   if( !what.compare(String("amp"))){
	     yExpr = String("AMPLITUDE(MODEL_DATA[,])" );
		}else if( !what.compare(String("phase"))){
		  yExpr = String("PHASE(MODEL_DATA[,])" );
		}else if( !what.compare(String("both"))){
		   cout<<"[msplot::dataAxis() To be implemented." << endl;
		}else{
		   cout<<"[msplot::dataAxis()] Iputted wrong value for parameter what!" << endl;
			return False;
		}
	}else if( !column.compare(String("corrected"))){
	   if( !what.compare(String("amp"))){
	     yExpr = String("AMPLITUDE(CORRECTED_DATA[,])" );
		}else if( !what.compare(String("phase"))){
		  yExpr = String("PHASE(CORRECTED_DATA[,])" );
		}else if( !what.compare(String("both"))){
		   cout<<"[msplot::dataAxis() To be implemented." << endl;
		}else{
		   cout<<"[msplot::dataAxis()] Iputted wrong value for parameter what!" << endl;
			return False;
		}	
	}else if( !column.compare(String("residual"))){
	   if( !what.compare(String("amp"))){
	     yExpr = String("AMPLITUDE(RESIDUAL_DATA[,])" );
		}else if( !what.compare(String("phase"))){
		  yExpr = String("PHASE(RESIDUAL_DATA[,])" );
		}else if( !what.compare(String("both"))){
		   cout<<"[msplot::dataAxis() To be implemented." << endl;
		}else{
		   cout<<"[msplot::dataAxis()] Iputted wrong value for parameter what!" << endl;
			return False;
		}	
	}else{
	    cout<<"[msplot::dataAxis()] Inputted wrong value for parameter column!" << endl;
		 return False;	
	}
	dataAxis = yExpr;
	return True;
}// end of dataAxis()
/*********************************************************************************************/
// data axes with the sub-indices, such as DATA[1:2,2:6], etc.
template<class T> Bool msplot<T>:: dataAxesNIndices( const PtrBlock<Vector<Int>* >& polarsIndices, const Vector<Int>& chanIndices, 
						     const Vector<String>& chanRange, const String& xExpr, const String& yExpr,
							  Vector<String>& xAxes, Vector<String>& yAxes ){
	uInt polarsDim = polarsIndices.nelements();
	 //
	if( m_adbg ){
      for( uInt i=0; i<polarsDim; i++ )
		   if( polarsIndices[i] != NULL )
		       cout<<"[msplot::dataAxesNIndices()] *polarsIndices[i] = " << *polarsIndices[i] << endl; 		
	}
   uInt polarsDimAll = 0;	
	for( uInt i=0; i< polarsDim; i++ ){
		if( polarsIndices[i] != NULL )
			polarsDimAll = polarsDimAll + (*(polarsIndices[i])).nelements();
	}
	//
	if( polarsIndices.nelements() !=0 ){
	   if( m_adbg )cout<<"[msplot::dataAxesNIndices()] polarsIndices.nelements() = " << polarsIndices.nelements() << endl;
	   if( chanIndices.nelements()!=0 ){
		   String chanIndStr = String("");
	      uInt yDim = 0;
			uInt chanDim = chanIndices.nelements();
			yDim = polarsDimAll*chanDim;
		   yAxes.resize( yDim );
		   xAxes.resize( yDim );
			uInt k = 0;
			uInt inPos = 0;
			String polIndStr = String("");
		   for( uInt i=0; i< polarsDim; i++  ){
			  if( polarsIndices[i] != NULL ){
			    for( uInt j=0; j< (*(polarsIndices[i])).nelements(); j++ ){
				   for( uInt jc=0; jc< chanDim; jc++ ){
			  	      xAxes[k] = xExpr;
						yAxes[k] = yExpr;
					   polIndStr = String::toString( (*(polarsIndices[i]))[j] );
					   inPos = yAxes[k].find(',');
					   // insert the str after ',' first so that the position of comma is not changed!
						chanIndStr = String::toString( chanIndices[jc] );
				  	   yAxes[k].insert( inPos+1, chanIndStr );
					   yAxes[k].insert( inPos, polIndStr );	 
					   if( m_adbg ) cout<<"[msplot::dataAxesNIndices()] yAxes[k] = " << yAxes[k] << endl;
					   k = k+1;
					}// end of jc loop
				}// end of j loop
			  } // end of if()
			}// end of i loop
      }else{
		   String chanRangeStr= String("");
		   if( chanRange.nelements()!=0 ){ // channel range
		      chanRangeStr = chanRange[0] + ":" +chanRange[1];
			}else{
			   chanRangeStr = String(" ");
			}
			if( m_adbg ) cout<<"[msplot::dataAxesNIndices()] chanRangeStr = " << chanRangeStr << endl;
	      uInt yDim = 0;
		   uInt polarsDim = polarsIndices.nelements();
	      for( uInt i=0; i< polarsDim; i++ ){
			   if( polarsIndices[i] != NULL )
			       yDim = yDim + (*(polarsIndices[i])).nelements();
			}
			if( m_adbg ) cout<<"[msplot::dataAxesNIndices()] yDim = " << yDim << endl;
		   yAxes.resize( yDim );
		   xAxes.resize( yDim );
			uInt k = 0;
			uInt inPos = 0;
			String polIndStr = String("");
		   for( uInt i=0; i< polarsDim; i++  ){
			  if( polarsIndices[i] != NULL ){
			    for( uInt j=0; j< (*(polarsIndices[i])).nelements(); j++ ){
			  	   xAxes[k] = xExpr;
					if( m_adbg ) cout<<"[msplot::dataAxesNIndices()] (*(polarsIndices[i]))[j] = " << (*(polarsIndices[i]))[j] << endl;
					polIndStr = String::toString( (*(polarsIndices[i]))[j] );
					if( m_adbg ) cout<<"[msplot::dataAxesNIndices()] polIndStr = " << polIndStr << endl;
					yAxes[k] = yExpr;
					inPos = yAxes[k].find(',');
					 // insert the str after ',' first so that the position of comma is not changed!
					yAxes[k].insert( inPos+1, chanRangeStr );
					yAxes[k].insert( inPos, polIndStr );	 
	  	         
					if( m_adbg ) cout<<"[msplot::dataAxesNIndices()] yAxes[k] = " << yAxes[k] << endl;
					k = k+1;
				 }
			  }// end of if()
			}
	
	   }//end of  if( chanIndices.nelements()!=0 )
	}else if( polarsIndices.nelements() == 0 ){
      if( chanIndices.nelements()!= 0 ){
					uInt chanDim = chanIndices.nelements();
					yAxes.resize( chanDim );
		         xAxes.resize( chanDim );
					String chanIndStr = String("");
					uInt inPos = 0;
				   for( uInt jc=0; jc< chanDim; jc++ ){
			  	      xAxes[jc] = xExpr;
						yAxes[jc] = yExpr;
					   inPos = yAxes[jc].find(',');
						chanIndStr = String::toString( chanIndices[jc] );
				  	   yAxes[jc].insert( inPos+1, chanIndStr ); 
					   if( m_adbg ) cout<<"[msplot::dataAxesNIndices()] yAxes = " << yAxes << endl;
					}// end of jc loop		
		}else{// user did not input any spw and channel selection, so use all the channels in the MS
		   String chanRangeStr= String("");
		   if( chanRange.nelements()!=0 ){ // channel range
		      chanRangeStr = chanRange[0] + ":" +chanRange[1];
			}else{
			   // this is redundant since we have handled it above if polarNchannel() return false.
			   chanRangeStr = String(" "); 
			}
		   xAxes.resize(1);
		   yAxes.resize(1);
		   xAxes[0] = xExpr;
			yAxes[0] = yExpr;
			uInt inPos = yAxes[0].find(',');
			yAxes[0].insert( inPos+1, chanRangeStr );
		}
	}// end of if( polarsIndices.nelement() !=0 )
	return True;
}
/*****************************************************************************************************************/

} //#End casa namespace

/*********************************************************************************/


