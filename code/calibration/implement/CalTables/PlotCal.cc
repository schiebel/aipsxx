//# PlotCal.cc: Implementation of PlotCal.h
//# Copyright (C) 1996,1997,1998,2001,2002,2003
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
//# $Id: PlotCal.cc,v 1.10 2006/01/26 17:57:20 kgolap Exp $
//----------------------------------------------------------------------------
#include <tables/Tables/TableDesc.h>
#include <tables/Tables/TableInfo.h>
#include <tables/Tables/SetupNewTab.h>
#include <tables/Tables/Table.h>
#include <tables/Tables/TableRecord.h>
#include <tables/Tables/ScaColDesc.h>
#include <tables/Tables/ArrColDesc.h>
#include <tables/Tables/ScalarColumn.h>
#include <tables/Tables/ArrayColumn.h>
#include <tables/Tables/ExprNode.h>
#include <casa/BasicSL/Complex.h>
#include <casa/Arrays/Vector.h>
#include <casa/Arrays/Matrix.h>
#include <casa/Arrays/ArrayIO.h>
#include <casa/Arrays/Cube.h>
#include <casa/Arrays/ArrayMath.h>
#include <casa/Arrays/ArrayLogical.h>
#include <casa/Arrays/ArrayIO.h>
#include <casa/Containers/Record.h>
#include <casa/Utilities/Assert.h>
#include <casa/Utilities/GenSort.h>
#include <casa/Exceptions/Error.h>
#include <casa/Quanta/MVTime.h>
#include <casa/OS/Time.h>
#include <casa/iostream.h>
#include <tables/TablePlot/TablePlot.h>
#include <tables/TablePlot/BasePlot.h>
#include <tables/TablePlot/CrossPlot.h>
#include <tables/TablePlot/TPPlotter.h>
#include <tasking/Tasking/ApplicationObject.h>
#include <tasking/Tasking/ApplicationEnvironment.h>
#include <graphics/Graphics/PGPlotterLocal.h>
#include <graphics/Graphics/PGPLOT.h>
#include <casa/Logging/LogIO.h>
#include <casa/sstream.h>
#include <casa/BasicSL/Constants.h>
#include <tasking/Tasking.h>
#include <casa/System/PGPlotter.h>
#include <calibration/CalTables/PlotCal.h>

namespace casa { //# NAMESPACE CASA - BEGIN
  PlotCal::PlotCal(){

  }
  PlotCal::PlotCal(String& tabName):  nxPanels_p(1), nyPanels_p(1),
  multiPlot_p(False), antSel_p(False), descIdSel_p(False), tabSel_p(0),
				     plotType_p("PHASE") {

    createCalTab(tabName);
    setPlotParam(1,1,"", False);
    whichPol_p=0;
    tp_p=new TablePlot<Float> ();
  }

  PlotCal::~PlotCal(){
    

  }
  Bool PlotCal::setPlotParam(Int nxPanels, Int nyPanels, 
			     String iterAxis, 
			     Bool multiPlot){

    nxPanels_p=nxPanels;
    nyPanels_p=nyPanels;
    multiPlot_p=multiPlot;
    
    plotopts_p.define("nxPanels", 1);      
    plotopts_p.define("nyPanels",1);      
    plotopts_p.define("windowsize", 10);    
    plotopts_p.define("aspectratio",0.8); 
    if(nxPanels_p*nyPanels_p > 1){
      plotopts_p.define("fontsize",1.0);
    }
    else{
      plotopts_p.define("fontsize",0.5);
    } 
    plotopts_p.define("plotcolour", 21);
    plotopts_p.define("plotstyle", 2);
    plotopts_p.define("plotsymbol",17);
    return True;

  }


  Bool PlotCal::plot(){
    
    if(BPS_p.nelements() > 0){
      tp_p->cleanUpBP(BPS_p);
    }

    if(calType_p=="G" || calType_p=="T" || calType_p=="B"){
      return plotB_G();

    }
    else if(calType_p=="M" || calType_p=="MF"){
      return plotM_F();
    }
    else if(calType_p=="K"){
      return timePlotK();
    }


    return False;
  }
  Bool PlotCal::next(){

    if(calType_p=="G" || calType_p=="T" || calType_p=="B"){
      title_p=calType_p+String(" Solution for antenna: ");
      return nextAnt();   
    }
    else if(calType_p=="M" || calType_p=="MF" || calType_p=="K" ){
      title_p=calType_p+String(" Solution for Baseline: ");
      return nextAnt();

    }

    return False;
  }
  Bool PlotCal::stop(){

    iterAnt_p=False;
    tp_p->iterMultiPlotStop(ATBPS_p,tpl_p);

    return True;
  }
  



Bool PlotCal::plotB_G(){

  if(tp_p !=0){
    
    delete tp_p;
    tp_p=new TablePlot<Float>();
    
  }
  label_p.resize(3);
  iterAnt_p=False;
  
  Table tabB;
  Int nchan;
  virtualGTab(tabB, nchan);
  plotopts_p.define("timeplot", 0);
  label_p[1]=String("Channel"); 
  label_p[2]=String("Phase"); 
  label_p[0]=calType_p+String(" solution");
  Vector<String> plotstr(2);
  plotstr[0]=String("CROSS");
  plotstr[1]=plotType_p;  
 

  Table *storeTab=new Table(*tabSel_p);
  tabSel_p=&tabB;
  

  if(calType_p=="G" || calType_p=="T"){
    plotopts_p.define("timeplot", 1);
    plotstr[0]=String("TIME");
    //      plotstr[1]=String("ARG(GAIN[1,1])*180.0/PI()"); 
    if(plotType_p=="AMP"){
      label_p[2]="Amplitude";
      //	plotstr[1]=String("ABS(GAIN[1,1])"); 
    }
  } 
  else{
    plotopts_p.define("timeplot", 0);
    label_p[1]="Channel";
    plotstr[0]="CROSS";
    if(plotType_p=="PHASE"){
      ostringstream os;
      os << "PHASE[1,1:" << nchan << "]" << endl;
      plotstr[1]=String(os); 
    }
    else if(plotType_p=="AMP"){
      label_p[2]="Amplitude";
      ostringstream os;
      os << "AMP[1,1:" << nchan << "]" << endl;
      plotstr[1]=String(os); 
    }
    
  }


  plotStr_p=plotstr;


  if(multiPlot_p){
    Vector<String> iterAxes(1);
    iterAxes[0]="ANTENNA1";
    ROScalarColumn<Int> ants(*tabSel_p, iterAxes[0]);
    index_p.resize();
    nextCounter_p=0;
    index_p=ants.getColumn();
    Int numAnts=GenSort<Int>::sort(index_p,Sort::Ascending,
				   Sort::NoDuplicates);
    index_p.resize(numAnts, True);
    Int numDesc;
    if(calType_p=="T" || calType_p=="G")
      numDesc=multiTablesInt("CAL_DESC_ID");
    else if(calType_p=="B")
      numDesc=multiTablesDouble("TIME");
    
    
    for (Int k=0; k < numDesc; ++k){
      tp_p->setTableT(numDesc, *overlayTabs_p[k]);
    }
    tp_p->setPlotParameters(tpl_p, plotopts_p);
    
    Int npans=nxPanels_p*nyPanels_p;
    if(tp_p->iterMultiPlotStart( ATBPS_p, tpl_p, npans, plotstr,iterAxes)==-1){
	cout << "Error in multiplot " << endl;
	return False;
    }
    
    iterAnt_p=True;
    title_p=calType_p+String(" solution for antenna: ");
    nextAnt();
    
    
      
  }
  else{
    Int numAnt=multiTablesInt("ANTENNA1");
    for (Int k=0; k < numAnt; ++k){
      tp_p->setTableT(numAnt, *overlayTabs_p[k]);
    }
    
    tp_p->setPlotParameters(tpl_p, plotopts_p);
    tp_p->setPlotLabels(tpl_p, label_p);
    if(tp_p->createBP(BPS_p, plotStr_p[0])==1) 
      tp_p->upDateBP(BPS_p);
    tp_p->getData(BPS_p, plotStr_p);
    tp_p->plotData(BPS_p, tpl_p, 1);
  }
  
  tabSel_p=storeTab;
  return True;


}
  
  
  Bool PlotCal::plotM_F(){
    
    if(tp_p !=0){
      
      delete tp_p;
      tp_p=new TablePlot<Float>();

    }
    
    iterAnt_p=False;
    
    label_p.resize(3);
    plotopts_p.define("timeplot", 1);

 
    label_p[2]=String("Phase"); 
    label_p[0]=string("M solution");
    Vector<String> plotstr(2);
    
    Vector<Int> ant1hash;
    Vector<Int> ant2hash;
    Int nAnt;
    Int nchan;
    Table tabM;
    virtualMTab(tabM, nAnt, nchan,ant1hash, ant2hash);

    Table *storeTab= new Table(*tabSel_p);
    tabSel_p=&tabM;


    if(calType_p=="M"){
      plotopts_p.define("timeplot", 1);
      plotstr[0]=String("TIME");
      plotstr[1]=String("ARG(GAIN[1,1])*180.0/PI()"); 
      if(plotType_p=="AMP"){
	label_p[2]="Amplitude";
	plotstr[1]=String("ABS(GAIN[1,1])"); 
      }
    } 
    else{
      plotopts_p.define("timeplot", 0);
       label_p[0]=string("MF solution");
      label_p[1]="Channel";
      plotstr[0]="CROSS";
      ostringstream os;
      os << "ARG(GAIN[1,1:" << nchan << "])*180.0/PI()" << endl;
      plotstr[1]=String(os); 
      if(plotType_p=="AMP"){
	label_p[2]="Amplitude";
	ostringstream osamp;
	osamp << "ABS(GAIN[1,1:" << nchan << "])*180.0/PI()" << endl;
	plotstr[1]=String(osamp); 
      }
      
    }
 
    
	
    plotStr_p=plotstr;


    if(multiPlot_p){
      Vector<String> iterAxes(1);
      iterAxes[0]="BASELINE";
      ROScalarColumn<Int> ants(*tabSel_p, iterAxes[0]);
      index_p.resize();
      nextCounter_p=0;
      index_p=ants.getColumn();
      Int numAnts=GenSort<Int>::sort(index_p,Sort::Ascending,
				     Sort::NoDuplicates);
      index_p.resize(numAnts, True);
      Int numDesc;
      if(calType_p=="M")
	numDesc=multiTablesInt("CAL_DESC_ID");
      else if(calType_p=="MF")
	numDesc=multiTablesDouble("TIME");

      for (Int k=0; k < numDesc; ++k){
	tp_p->setTableT(numDesc, *overlayTabs_p[k]);
      }
      tp_p->setPlotParameters(tpl_p, plotopts_p);
      
      Int npans=nxPanels_p*nyPanels_p;
      if(tp_p->iterMultiPlotStart( ATBPS_p, tpl_p, npans, plotstr,iterAxes)==-1){
	cout << "Error in multiplot " << endl;
	return False;
      }

      iterAnt_p=True;
      title_p=calType_p+" Solution for baseline: " ;
      nextAnt();


      
    }
    else{
      Int numAnt=multiTablesInt("BASELINE");
      for (Int k=0; k < numAnt; ++k){
	tp_p->setTableT(numAnt, *overlayTabs_p[k]);
      }
      
      tp_p->setPlotParameters(tpl_p, plotopts_p);
      tp_p->setPlotLabels(tpl_p, label_p);
      if(tp_p->createBP(BPS_p, plotStr_p[0])==1) 
	tp_p->upDateBP(BPS_p);
      tp_p->getData(BPS_p, plotStr_p);
      tp_p->plotData(BPS_p, tpl_p, 1);
    }


    tabSel_p=storeTab;
    return True;


  }

  Bool PlotCal::timePlotK(){


    if(tp_p !=0){

      delete tp_p;
      tp_p=new TablePlot<Float>();

    }

    iterAnt_p=False;

    label_p.resize(3);
    plotopts_p.define("timeplot", 1);

 
    label_p[2]=String("Phase in degrees"); 
    label_p[0]=string("K solution");
    Vector<String> plotstr(2);
    
    Vector<Int> ant1hash;
    Vector<Int> ant2hash;
    Int nAnt;
    Table tabM;
    virtualKTab(tabM, nAnt, ant1hash, ant2hash);

    Table *storeTab= new Table(*tabSel_p);
    tabSel_p=&tabM;
    plotstr[0]=String("TIME");
    plotstr[1]=plotType_p;
      
    if(plotType_p=="AMP"){
	label_p[2]="Amplitude";
    }
    if(plotType_p=="DELAY"){
	label_p[2]="Delay  (ns)";
    }
    if(plotType_p=="DELAYRATE"){
	label_p[2]="Delay rate (ps/s)";
    }
	
    plotStr_p=plotstr;


    if(multiPlot_p){
      Vector<String> iterAxes(1);
      iterAxes[0]="BASELINE";
      ROScalarColumn<Int> ants(*tabSel_p, iterAxes[0]);
      index_p.resize();
      nextCounter_p=0;
      index_p=ants.getColumn();
      Int numAnts=GenSort<Int>::sort(index_p,Sort::Ascending,
				     Sort::NoDuplicates);
      index_p.resize(numAnts, True);
      Int numDesc;
      numDesc=multiTablesInt("CAL_DESC_ID");

      for (Int k=0; k < numDesc; ++k){
	tp_p->setTableT(numDesc, *overlayTabs_p[k]);
      }
      tp_p->setPlotParameters(tpl_p, plotopts_p);
      
      Int npans=nxPanels_p*nyPanels_p;
      if(tp_p->iterMultiPlotStart( ATBPS_p, tpl_p, npans, plotstr,iterAxes)==-1){
	cout << "Error in multiplot " << endl;
	return False;
      }

      iterAnt_p=True;
      title_p=calType_p+" Solution for baseline: " ;
      nextAnt();


      
    }
    else{
      Int numAnt=multiTablesInt("BASELINE");
      for (Int k=0; k < numAnt; ++k){
	tp_p->setTableT(numAnt, *overlayTabs_p[k]);
      }
      
      tp_p->setPlotParameters(tpl_p, plotopts_p);
      tp_p->setPlotLabels(tpl_p, label_p);
      if(tp_p->createBP(BPS_p, plotStr_p[0])==1) 
	tp_p->upDateBP(BPS_p);
      tp_p->getData(BPS_p, plotStr_p);
      tp_p->plotData(BPS_p, tpl_p, 1);
    }


    tabSel_p=storeTab;
    
    return True;


  }


  Bool PlotCal::nextAnt(){
    Int npanels;
    Int ret;
    if(!iterAnt_p) return False;
    ret=tp_p->iterMultiPlotNext(ATBPS_p,tpl_p, npanels);
    //No more next's 
    if(ret != 1){
      if(overlayTabs_p.nelements() > 0){
	for (uInt k =0; k < overlayTabs_p.nelements() ; ++k)
	  delete overlayTabs_p[k];
	overlayTabs_p.resize(0, True);
      }
      nextCounter_p=0;
      iterAnt_p=False; //Stop iterating
      return False;
    }
    for(Int i=0; i<npanels; i++){
      if(tp_p->getData(*ATBPS_p[i],plotStr_p)) 
	return False;
      {
	ostringstream buf;
	buf << title_p << index_p[nextCounter_p];
	label_p[0] = String(buf);
	++nextCounter_p;
      }		
      tp_p->setPlotLabels(tpl_p,label_p);
      tp_p->plotData(*ATBPS_p[i],tpl_p,i+1);
    }


    return True;

  }


  Int PlotCal::multiTablesInt(String colName){

    ROScalarColumn<Int> descs(*tabSel_p, colName);
    Vector<Int> descCol=descs.getColumn();
    Int numDesc=GenSort<Int>::sort(descCol,Sort::Ascending,
				   Sort::NoDuplicates);
    descCol.resize(numDesc, True);
    Vector<Int> sel(1);
    String col=colName;
    overlayTabs_p.resize(numDesc);
    for (Int k=0; k < numDesc; ++k){ 
      sel[0]=descCol[k];
      TableExprNode condition;
      condition=(*tabSel_p).col(col).in(sel);
      overlayTabs_p[k]=new Table((*tabSel_p)(condition));
      ostringstream os;
      os << tabSel_p->tableName() << "desc" << k << endl;
      overlayTabs_p[k]->rename(String(os), Table::Scratch);
    }
    return numDesc;
    
  }
  Int PlotCal::multiTablesDouble(String colName){

    ROScalarColumn<Double> descs(*tabSel_p, colName);
    Vector<Double> descCol=descs.getColumn();
    Int numDesc=GenSort<Double>::sort(descCol,Sort::Ascending,
				   Sort::NoDuplicates);
    descCol.resize(numDesc, True);
    Vector<Double> sel(1);
    String col=colName;
    overlayTabs_p.resize(numDesc);
    for (Int k=0; k < numDesc; ++k){ 
      sel[0]=descCol[k];
      TableExprNode condition;
      condition=(*tabSel_p).col(col).in(sel);
      overlayTabs_p[k]=new Table((*tabSel_p)(condition));
      ostringstream os;
      os << tabSel_p->tableName() << "desc" << k << endl;
      overlayTabs_p[k]->rename(String(os), Table::Scratch);
    }
    return numDesc;
    
  }
  Bool PlotCal::setSelect(Vector<Int>& antennas, Vector<Int>& caldescids, 
		 String plottype){
    
    if(antennas.nelements()==0){
      antSel_p=False;
    }
    else{
      antSel_p=True;
    }
    if(caldescids.nelements()==0){
      descIdSel_p=False;
    }
    else{
      descIdSel_p=True;
    } 

    plotType_p=plottype;
    plotType_p.upcase();

    if(plotType_p == "RLPHASE" || plotType_p == "XYPHASE" ){
      whichPol_p=2;
      plotType_p="PHASE";
    }
    if(antSel_p || descIdSel_p){
      TableExprNode condition;
      if(antSel_p){
	String col="ANTENNA1";
	condition=tab_p.col(col).in(antennas);
      }
      if(descIdSel_p){
	String col="CAL_DESC_ID";
	condition=condition && tab_p.col(col).in(caldescids);
      }
      if(tabSel_p !=0) delete tabSel_p;
      tabSel_p=0;
      tabSel_p=new Table(tab_p(condition));
      tabSel_p->rename(tab_p.tableName()+".plotCal", Table::Scratch);
      if(tabSel_p->nrow()==0) {
	delete tabSel_p; tabSel_p=0;
	tabSel_p=new Table(tab_p);
	return False;
      }
    }
    return True;
  }


  void PlotCal::createCalTab(String& tabName){
    LogIO os(LogOrigin("plotcal", "createCalTab", WHERE));
    if(!Table::isReadable(tabName)) {
      os << LogIO::SEVERE << "Calibration table " << tabName 
	 << " does not exist " 
	 << LogIO::POST;
    }
    tab_p=Table(tabName);
    if(!tab_p.tableInfo().type().contains("Calibration")){
      os << LogIO::SEVERE << "Table " << tabName 
	 << " is not a calibration table " 
	 << LogIO::POST;
    }

    if(tabSel_p!=0) delete tabSel_p;
    tabSel_p=0;
    //default selection
    tabSel_p=new Table(tab_p);
		      
   
    String subType[2];
    split(tab_p.tableInfo().subType(), subType, 1, String(" "));
 
    if(subType[0].contains("G")){
      calType_p="G";
    }
    else if(subType[0].contains("B")){
      calType_p="B";
    }
    else if(subType[0].contains("D")){
      calType_p="D";
    }
    else if(subType[0].contains("T")){
      calType_p="T";
    }
    else if(subType[0].contains("MF")){
      calType_p="MF";
    }
    else if(subType[0].contains("M")){
      calType_p="M";
    }
    else if(subType[0].contains("K")){
      calType_p="K";
    } 
  }



  void PlotCal::virtualMTab( Table& tabB, Int& nAnt, Int& nchan, 
			     Vector<Int>& ant1hash, Vector<Int>& ant2hash ){

    TableDesc td("", "1", TableDesc::Scratch);
    td.comment() = "A memory M/F table to have the array size to satisfy tableplot";
    td.addColumn (ScalarColumnDesc<Int>("ANTENNA1"));
    td.addColumn (ScalarColumnDesc<Int>("ANTENNA2"));
    td.addColumn (ScalarColumnDesc<Int>("BASELINE"));
    td.addColumn (ArrayColumnDesc<Complex>("GAIN"));  
    td.addColumn (ScalarColumnDesc<Int>("CAL_DESC_ID"));
    td.addColumn (ArrayColumnDesc<Bool> ("FLAG"));
    td.addColumn (ScalarColumnDesc<Double> ("TIME"));
    
    Int nrows=tabSel_p->nrow();
    
    
    // Now create a new table from the description.
    SetupNewTable aNewTab("mofoscratch", td, Table::New);
    tabB = Table (aNewTab, Table::Memory, nrows);
    
    
    ROArrayColumn<Complex>  origGain(*tabSel_p,"GAIN");
    ROArrayColumn<Bool> solnOk(*tabSel_p, "SOLUTION_OK") ;
    ROScalarColumn<Int> origBaseline(*tabSel_p, "ANTENNA1");
    ROScalarColumn<Int> origCalDesc(*tabSel_p, "CAL_DESC_ID");
    ROScalarColumn<Double> origTime(*tabSel_p, "TIME");
    Cube<Complex> ydata=origGain.getColumn();
    Vector<Int> baselines=origBaseline.getColumn();
    //Let's determine nAnt now
    Int maxbaseline=max(baselines);
    Int baseId=0;
    nAnt=0;
    while(baseId <= maxbaseline){
      baseId=nAnt*(nAnt+1)/2;
      ++nAnt;
    }
    --nAnt;
    ant1hash.resize(maxbaseline+1);
    ant2hash.resize(maxbaseline+1);
    Int ibl=0;
    for (Int k=0; k < nAnt; ++k){
      for (Int j=k; j < nAnt; ++j){
	ibl=k*nAnt-k*(k+1)/2+j;
	ant1hash(ibl)=k;
	ant2hash(ibl)=j;
      } 
    }
    //===

    Cube<Bool> soln=solnOk.getColumn();
    Int npol=ydata.shape()(0);
    nchan=soln.shape()(1);
    Cube<Bool> flag(1, nchan, nrows);
    Vector<Int> ant1(nrows);
    Vector<Int> ant2(nrows);
    Cube<Complex> newGain(1,nchan,nrows);
    for (Int k=0; k < nrows ; ++k){
      for (Int j=0; j <nchan; ++j){
	if(npol==1)
	  newGain(0,j,k)=ydata(0,j,k);
	else if(npol==2)
	  newGain(0,j,k)=(ydata(0,j,k)+ydata(1,j,k))/2.0;
	else if(npol==4)
	  newGain(0,j,k)=(ydata(0,j,k)+ydata(3,j,k))/2.0;
	flag(0,j,k)=!soln(0,j,k);
      } 
      ant1[k]=ant1hash[baselines[k]];
      ant2[k]=ant2hash[baselines[k]];

      
    }
 

    ScalarColumn<Int> newAnt1(tabB, "ANTENNA1");
    newAnt1.putColumn(ant1);
    ScalarColumn<Int> newAnt2(tabB, "ANTENNA2");
    newAnt2.putColumn(ant2);
    ScalarColumn<Int> cal_desc(tabB, "CAL_DESC_ID");
    cal_desc.putColumn(origCalDesc);
    ArrayColumn<Bool> flagCol(tabB, "FLAG");
    flagCol.putColumn(flag);
    Vector<Double> time0=origTime.getColumn();
    reformatTime(time0);
    ScalarColumn<Double> newtime(tabB, "TIME");
    newtime.putColumn(time0);
    ArrayColumn<Complex> gainB(tabB, "GAIN");
    gainB.putColumn(newGain);
    ScalarColumn<Int> newBas(tabB, "BASELINE");
    newBas.putColumn(baselines);



  }


  void PlotCal::virtualKTab( Table& tabB, Int& nAnt,  
			     Vector<Int>& ant1hash, Vector<Int>& ant2hash ){

    TableDesc td("", "1", TableDesc::Scratch);
    td.comment() = "A memory K table to have the array size to satisfy tableplot";
    td.addColumn (ScalarColumnDesc<Int>("ANTENNA1"));
    td.addColumn (ScalarColumnDesc<Int>("ANTENNA2"));
    td.addColumn (ScalarColumnDesc<Int>("BASELINE"));
    td.addColumn (ArrayColumnDesc<Float>("PHASE"));
    td.addColumn (ArrayColumnDesc<Float>("AMP"));
    td.addColumn (ArrayColumnDesc<Float>("DELAY"));
    td.addColumn (ArrayColumnDesc<Float>("DELAYRATE"));
    td.addColumn (ScalarColumnDesc<Int>("CAL_DESC_ID"));
    td.addColumn (ArrayColumnDesc<Bool> ("FLAG"));
    td.addColumn (ScalarColumnDesc<Double> ("TIME"));
    
    Int nrows=tabSel_p->nrow();
    
    
    // Now create a new table from the description.
    SetupNewTable aNewTab("mofoscratch", td, Table::New);
    tabB = Table (aNewTab, Table::Memory, nrows);
    
    
    ROArrayColumn<Complex>  origGain(*tabSel_p,"GAIN");
    ROArrayColumn<Bool> solnOk(*tabSel_p, "SOLUTION_OK") ;
    ROScalarColumn<Int> origBaseline(*tabSel_p, "ANTENNA1");
    ROScalarColumn<Int> origCalDesc(*tabSel_p, "CAL_DESC_ID");
    ROScalarColumn<Double> origTime(*tabSel_p, "TIME");
    Cube<Complex> ydata=origGain.getColumn();
    Vector<Int> baselines=origBaseline.getColumn();
    //Let's determine nAnt now
    Int maxbaseline=max(baselines);
    Int baseId=0;
    nAnt=0;
    while(baseId <= maxbaseline){
      baseId=nAnt*(nAnt+1)/2;
      ++nAnt;
    }
    --nAnt;
    ant1hash.resize(maxbaseline+1);
    ant2hash.resize(maxbaseline+1);
    Int ibl=0;
    for (Int k=0; k < nAnt; ++k){
      for (Int j=k; j < nAnt; ++j){
	ibl=k*nAnt-k*(k+1)/2+j;
	ant1hash(ibl)=k;
	ant2hash(ibl)=j;
      } 
    }
    //===

    Cube<Bool> soln=solnOk.getColumn();
    Cube<Bool> flag(1, 1, nrows);
    Vector<Int> ant1(nrows);
    Vector<Int> ant2(nrows);
    Cube<Float> newPhase(1,1,nrows);
    newPhase.set(0);
    Cube<Float> newAmp(1,1,nrows);
    newAmp.set(0);
    Cube<Float> newDelay(1,1,nrows);
    newDelay.set(0);
    Cube<Float> newDelayRate(1,1,nrows);
    newDelayRate.set(0);

    for (Int k=0; k < nrows ; ++k){
      ant1[k]=ant1hash[baselines[k]];
      ant2[k]=ant2hash[baselines[k]];
      if(whichPol_p==0){
	newPhase(0,0,k)=arg(ydata(0,0,k))*(180.0/C::pi);
	newAmp(0,0,k)=abs(ydata(0,0,k));
	newDelay(0,0,k)=real(ydata(1,0,k));
      }
      else if(whichPol_p==1){
	newPhase(0,0,k)=arg(ydata(2,0,k))*(180.0/C::pi);
	newAmp(0,0,k)=abs(ydata(2,0,k));
	newDelay(0,0,k)=real(ydata(3,0,k));
      }
      else if(whichPol_p==2){
	newPhase(0,0,k)=(arg(ydata(0,0,k))-arg(ydata(2,0,k)))*180.0/C::pi;
	while(newPhase(0,0,k) > 180.0){
	  newPhase(0,0,k)-=360.0;
	}
	while(newPhase(0,0,k) < -180.0){
	  newPhase(0,0,k)+=360.0;
	}
	if(abs(ydata(2,0,k))> 0){
	  newAmp(0,0,k)=abs(ydata(0,0,k))/abs(ydata(2,0,k));

	}
	newDelay(0,0,k)=real(ydata(1,0,k)-ydata(3,0,k));
      }
      else if(whichPol_p==3){
	newPhase(0,0,k)=arg( (ydata(0,0,k) + ydata(2,0,k))/2.0)*180.0/C::pi;
	newAmp(0,0,k)=abs((ydata(0,0,k)+ydata(2,0,k))/2.0);
	newDelay(0,0,k)=real(ydata(3,0,k)+ydata(1,0,k))/2.0;	  
      }
      
      newDelayRate(0,0,k)=real(ydata(4,0,k));
      flag(0,0,k)=!soln(0,0,k);
      
      
    }
 

    ScalarColumn<Int> newAnt1(tabB, "ANTENNA1");
    newAnt1.putColumn(ant1);
    ScalarColumn<Int> newAnt2(tabB, "ANTENNA2");
    newAnt2.putColumn(ant2);
    ScalarColumn<Int> cal_desc(tabB, "CAL_DESC_ID");
    cal_desc.putColumn(origCalDesc);
    ArrayColumn<Bool> flagCol(tabB, "FLAG");
    flagCol.putColumn(flag);
    Vector<Double> time0=origTime.getColumn();
    reformatTime(time0);
    ScalarColumn<Double> newtime(tabB, "TIME");
    newtime.putColumn(time0);
    ArrayColumn<Float> phase(tabB, "PHASE");
    phase.putColumn(newPhase);
    ArrayColumn<Float> amp(tabB, "AMP");
    amp.putColumn(newAmp);
    ArrayColumn<Float> del(tabB, "DELAY");
    del.putColumn(newDelay);
    ArrayColumn<Float> delrat(tabB, "DELAYRATE");
    delrat.putColumn(newDelayRate);
    ScalarColumn<Int> newBas(tabB, "BASELINE");
    newBas.putColumn(baselines);



  }


  void PlotCal::virtualGTab( Table& tabB, Int& nchan ){

    TableDesc td("", "1", TableDesc::Scratch);
    td.comment() = "A memory BGT table to have the array size to satisfy tableplot";
    td.addColumn (ScalarColumnDesc<Int>("ANTENNA1"));
    td.addColumn (ArrayColumnDesc<Float>("PHASE"));
    td.addColumn (ArrayColumnDesc<Float>("AMP"));
    td.addColumn (ScalarColumnDesc<Int>("CAL_DESC_ID"));
    td.addColumn (ArrayColumnDesc<Bool> ("FLAG"));
    td.addColumn (ScalarColumnDesc<Double> ("TIME"));
    
    Int nrows=tabSel_p->nrow();
    
    
    // Now create a new table from the description.
    SetupNewTable aNewTab("mofoscratch", td, Table::New);
    tabB = Table (aNewTab, Table::Memory, nrows);
    
    
    ROArrayColumn<Complex>  origGain(*tabSel_p,"GAIN");
    ROArrayColumn<Bool> solnOk(*tabSel_p, "SOLUTION_OK") ;
    ROScalarColumn<Int> origAnt1(*tabSel_p, "ANTENNA1");
    ROScalarColumn<Int> origCalDesc(*tabSel_p, "CAL_DESC_ID");
    ROScalarColumn<Double> origTime(*tabSel_p, "TIME");
    Array<Complex> ydata=origGain.getColumn();

    Cube<Bool> soln=solnOk.getColumn();
    Int npol=soln.shape()(0);
    nchan=soln.shape()(1);
    Cube<Bool> flag(npol, nchan, nrows);
    Cube<Float> newPhase(npol,nchan,nrows);
    newPhase.set(0);
    Cube<Float> newAmp(npol,nchan,nrows);
    newAmp.set(0);
    IPosition ipos1(5,0,0,0,0,0);
    IPosition ipos2(5,1,1,0,0,0);
    for (Int k=0; k < nrows ; ++k){
      ipos1(4)=k;
      ipos2(4)=k;
      for (Int j =0; j< npol ; ++j){
	ipos1(2)=j;
	ipos2(2)=j;
	for (Int i =0 ; i < nchan ; ++i){
	  ipos1(3)=i;
	  ipos2(3)=i;
	  flag(j,i,k)= !(soln(j,i,k));

	  if(whichPol_p==0){
	    newPhase(j,i,k)=arg(ydata(ipos1))*(180.0/C::pi);
	    newAmp(j,i,k)=abs(ydata(ipos1));
	  }
	  else if(whichPol_p==1){
	    newPhase(j,i,k)=arg(ydata(ipos2))*(180.0/C::pi);
	    newAmp(j,i,k)=abs(ydata(ipos2));
	  }
	  else if(whichPol_p==2){
	    newPhase(j,i,k)=(arg(ydata(ipos1))-arg(ydata(ipos2)))*180.0/C::pi;
	    while(newPhase(j,i,k) > 180.0){
	      newPhase(j,i,k)-=360.0;
	    }
	    while(newPhase(j,i,k) < -180.0){
	      newPhase(j,i,k)+=360.0;
	    }
	    if(abs(ydata(ipos2))> 0){
	      newAmp(j,i,k)=abs(ydata(ipos1))/abs(ydata(ipos2));
	      
	    }
	  }
	  else if(whichPol_p==3){
	    newPhase(j,i,k)=arg((ydata(ipos1) + ydata(ipos2))/2.0)*180.0/C::pi;
	    newAmp(j,i,k)=abs((ydata(ipos1)+ydata(ipos2))/2.0);	  
	  }

	}
      }
    }


 

    ScalarColumn<Int> newAnt1(tabB, "ANTENNA1");
    newAnt1.putColumn(origAnt1);
    ScalarColumn<Int> cal_desc(tabB, "CAL_DESC_ID");
    cal_desc.putColumn(origCalDesc);
    ArrayColumn<Bool> flagCol(tabB, "FLAG");
    flagCol.putColumn(flag);
    Vector<Double> time0=origTime.getColumn();
    //No need to reformat time for B
    if(calType_p != "B"){
      reformatTime(time0);
    }
    ScalarColumn<Double> newtime(tabB, "TIME");
    newtime.putColumn(time0);
    ArrayColumn<Float> phase(tabB, "PHASE");
    phase.putColumn(newPhase);
    ArrayColumn<Float> amp(tabB, "AMP");
    amp.putColumn(newAmp);


  }


  void PlotCal::reformatTime(Vector<Double>& time){
    Double begorig=min(time);
    Double diff= max(time)-begorig;
    Double beg=begorig-Int(begorig/24.0/3600.0)*24.0*3600.0;
    time=(time-begorig+beg);
    //   MVTime mytime(begorig);

    //   cout << "Mytime " << mytime.string();
    //   cout << "y " << mytime.ymd() << endl;

    if(diff < 86400.0){
      time=time/Double(3600.0);
      label_p[1]="Time in hours";
    }
    else{
      time=time/Double(3600.0*24.0);
      label_p[1]="Time in days";
    }


  }


//----------------------------------------------------------------------------

} //# NAMESPACE CASA - END
