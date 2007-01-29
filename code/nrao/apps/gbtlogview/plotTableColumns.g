# plotTableColumns.g: select columns from table for plotting, for gbtlogview
#
#
#   Copyright (C) 1995,1996,1997,1999,2001
#   Associated Universities, Inc. Washington DC, USA.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2 of the License, or (at your option)
#   any later version.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#   more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   675 Massachusetts Ave, Cambridge, MA 02139, USA.
#
#   Correspondence concerning AIPS++ should be addressed as follows:
#          Internet email: aips2-request@nrao.edu.
#          Postal address: AIPS++ Project Office
#                          National Radio Astronomy Observatory
#                          520 Edgemont Road
#                          Charlottesville, VA 22903-2475 USA
#
#   $Id: plotTableColumns.g,v 19.0 2003/07/16 03:42:26 aips2adm Exp $ 
#-----------------------------------------------------------------------------
gbtplot := [=];
#-----------------------------------------------------------------------------
# synopsis:  the one public function, 'runColumnPlottingDialogBox'
# creates a free-standing window with one listbox each for the x,y1,and y2
# axes.  select at least 1 y1 quantity, and optional x quantity (if you
# choose none, the y vector is plotted against the sequence 1..n on x).
# an 'assign to: ' entry box is provided, so that the plotted selections
# are available, at global scope in the glish interpreter, after the 
# plotting is complete; a brief description of this variable is printed
# to glish stdout.
#                       -- public function --
#
#   runColumnPlottingDialogBox := function (tbl)
#
#
#                       -- private functions --
#
#   gbtplot.setupColumnPlottingDialogBoxEvents := function (ref gui, tbl)
#   gbtplot.assignVariable := function (variableName, data, verbose = F)
#   gbtplot.legalPlotSelections := function (numberOfXAxisSelections, 
#                                                 numberOfYAxisSelections, 
#                                                 numberOfY2AxisSelections);
#   gbtplot.dispatchPlotCommands := function (tbl, xAxisColumnName, 
#                                             yAxisQuantities, 
#                                            y2AxisQuantities);
#   gbtplot.columnExists := function (tbl, columnName)
#   gbtplot.errorDialog := function (msg)
#   gbtplot.isAnMJDTimeAxis := function (columnName)
#-----------------------------------------------------------------------------

global fullEvent := create_agent()

runColumnPlottingDialogBox := function (tbl)
{
    tableColumnTitles :=  tbl.colnames();
    numberOfTitles := len (tableColumnTitles);
    if (numberOfTitles == 0) return;

    frames := [=];
    buttons := [=];
    spacers := [=];
    listboxes := [=];
    labels := [=];
    entries := [=];
    composites := [=];

    frames.toplevel  := dws.frame (title='Plot Log Data');
    frames.listboxes  := dws.frame (frames.toplevel,side='left');
    frames.operations := dws.frame (frames.toplevel,side='top');
    frames.buttons    := dws.frame (frames.operations,side='left');
    frames.assignment := dws.frame (frames.operations,side='left');

    buttons.plot := dws.button (frames.buttons,text='Plot');
    buttons.clearPlot := dws.button (frames.buttons,text='Clear Plot');
    buttons.lines := dws.button (frames.buttons,type='check',text='Points');
    buttons.dismiss := dws.button (frames.buttons,text='Dismiss',
				type='dismiss');
 
    labels.assignVariable := dws.label (frames.assignment, text='Assign to:');
    
    entries.assignVariable := dws.entry (frames.assignment);

    spacers.horizontal0 := dws.frame (frames.listboxes, width=10);

    frames.xAxis  := dws.frame (frames.listboxes, side='top');
    xvf:= dws.frame(frames.listboxes,side='left',borderwidth=0);
    frames.yAxis  := dws.frame (frames.listboxes, side='top');
    yvf:= dws.frame(frames.listboxes,side='left',borderwidth=0);
    frames.y2Axis := dws.frame (frames.listboxes, side='top');
    y2vf:=dws.frame(frames.listboxes,side='left',borderwidth=0);

    labels.xAxis  := dws.label (frames.xAxis,text='X Axis');
    labels.yAxis  := dws.label (frames.yAxis,text='Y Axis');
    labels.y2Axis := dws.label (frames.y2Axis,text='Y2 Axis');

# change height to 20 from numberOfTitles
    listboxes.xAxis := dws.listbox (frames.xAxis, width=24,
				    height=20,
				    mode='browse',
				    exportselection=T);

    listboxes.yAxis := dws.listbox (frames.yAxis, width=24,
				    height=20,
				    height=14,
				    exportselection=F,
				    mode='multiple');

    listboxes.y2Axis := dws.listbox (frames.y2Axis,
				     width=24,
				     height=20,
				     mode='multiple');
#
    xf := dws.frame(frames.xAxis,side='top',borderwidth=0);
    yf := dws.frame(frames.yAxis,side='top',borderwidth=0);
    y2f:= dws.frame(frames.y2Axis,side='top',borderwidth=0);
#
#
#  padx:=dws.frame(xf,expand='none',width=23,height=23)
    hsb_x:=dws.scrollbar(xf,orient='horizontal');
    hsb_y1:=dws.scrollbar(yf,orient='horizontal');
    hsb_y2:=dws.scrollbar(y2f,orient='horizontal');
    vsb_x:=dws.scrollbar(xvf,orient='vertical');
    vsb_y1:=dws.scrollbar(yvf,orient='vertical');
    vsb_y2:=dws.scrollbar(y2vf,orient='vertical');
    whenever hsb_x->scroll do
	listboxes.xAxis->view($value);
    whenever hsb_y1->scroll do
	listboxes.yAxis->view($value);
    whenever hsb_y2->scroll do
	listboxes.y2Axis->view($value);
    whenever listboxes.xAxis->xscroll do
	hsb_x->view($value);
    whenever listboxes.yAxis->xscroll do
	hsb_y1->view($value);
    whenever listboxes.y2Axis->xscroll do
	hsb_y2->view($value);
    whenever vsb_x->scroll do
	listboxes.xAxis->view($value);
    whenever vsb_y1->scroll do
	listboxes.yAxis->view($value);
    whenever vsb_y2->scroll do 
	listboxes.y2Axis->view($value);
    whenever listboxes.xAxis->yscroll do
	vsb_x->view($value);
    whenever listboxes.yAxis->yscroll do
	vsb_y1->view($value);
    whenever listboxes.y2Axis->yscroll do
	vsb_y2->view($value);
############################################
    for (i in 1:len (tableColumnTitles)) {
#	tmptc := tableColumnTitles[i];
#        tmptc =~ s/_/$$/g;
#	ltmptc := len(tmptc);
#	if (ltmptc>=4) {
#		cattmptc:=spaste(tmptc[ltmptc-3],'_',tmptc[ltmptc-2],'_',tmptc[ltmptc],"");
#		tableColumnTitles[i]:=cattmptc;
#	}
	listboxes.xAxis->insert (tableColumnTitles [i]);
	listboxes.yAxis->insert (tableColumnTitles [i]);
	listboxes.y2Axis->insert (tableColumnTitles [i]);
    }

    r := [=];
    r.frames := frames;
    r.buttons := buttons;
    r.entries := entries;
    r.spacers := spacers;
    r.labels := labels;
    r.listboxes := listboxes;
    r.composites := composites;

    gbtplot.setupColumnPlottingDialogBoxEvents (r, tbl);
    return ref (r);

}# runColumnPlottingDialogBox
#-----------------------------------------------------------------------------
gbtplot.setupColumnPlottingDialogBoxEvents := function (ref gui, tbl)
{
    whenever gui.buttons.dismiss->press do {
	val gui.frames.toplevel := F;
    }

    whenever gui.buttons.clearPlot->press do {
	junk := pg.clear();
    }

    whenever gui.buttons.plot->press, fullEvent->newOne do {
	junk := pg.clear()
	xAxisIndices := gui.listboxes.xAxis->selection ();
	numberOfXAxisSelections := len (xAxisIndices);
	yAxisIndices := gui.listboxes.yAxis->selection ();
	numberOfYAxisSelections := len (yAxisIndices);
	y2AxisIndices := gui.listboxes.y2Axis->selection ();
	numberOfY2AxisSelections := len (y2AxisIndices);
	if (!gbtplot.legalPlotSelections (numberOfXAxisSelections, 
					  numberOfYAxisSelections, 
					  numberOfY2AxisSelections)) {
	    gbtplot.errorDialog(
                spaste ('You must specify at least 1 quantity from ',
			'either the Y1 or Y2 axis. You cannot plot ',
			'to the Y2 axis unless the Y1 axis is also ',
			'in use.' ));
	}
	else {
	    if (numberOfXAxisSelections == 1)
		xAxisQuantity :=
		    gui.listboxes.xAxis->get (xAxisIndices);
	    else
		xAxisQuantity := F;
	    if (numberOfYAxisSelections > 0)
		yAxisQuantities :=
		    gui.listboxes.yAxis->get (yAxisIndices);
	    else
		yAxisQuantities := F;

	    if (numberOfY2AxisSelections > 0)
		y2AxisQuantities := 
		    gui.listboxes.y2Axis->get (y2AxisIndices);
	    else
		y2AxisQuantities := F;
      
	    extractedData := gbtplot.dispatchPlotCommands (tbl,
			  xAxisQuantity, yAxisQuantities, y2AxisQuantities,
			   !gui.buttons.lines->state());
	    variableName := gui.entries.assignVariable->get ();
	    if (strlen (variableName) > 0) {
		verbose := T;
		gbtplot.assignVariable (variableName, extractedData, verbose);
	    }
	}# else: legal selections to make a plot
    }# plotButton->press  

}# setupColumnPlottingDialogBoxEvents
#-----------------------------------------------------------------------------
gbtplot.assignVariable := function (variableName, data, verbose = F)
# assign, at global scope, the string <variableName> to the arbitrary
# data in <data>.  
# for plotTableColumn.g, <data> is expected to be a record holding some
# number of vectors.
# assignment is straightforward -- simply use the glish builtin function
# "symbol_set".
# it's a little tricky, though, to support the <verbose> option.  
# in particular, getting the value of the nth field of the record, so
# that its length can be determined, requires this awkard locution:
# 
#        symbol_value (variableName)[1][i]
#
# symbol_value (variableName) returns a record whose only field is
# 'variableName'.  for example:
#
#    variableName := 'xxx';
#    symbol_set (variableName, [x=1,y=2,z=3]);
#    symbol_value (variableName)           --> [xxx=[x=1, y=2, z=3]]
#    symbol_value (variableName) [1]       --> [x=1, y=2, z=3]
#    len (symbol_value (variableName) [1]) --> 3 
#    symbol_value (variableName) [1][1]    --> 1
#    symbol_value (variableName) [1][2]    --> 2
#    symbol_value (variableName) [1][3]    --> 3
#
# i hope that's clear....
{
    junk := symbol_set (variableName, data);
    if (!verbose) return;

    fieldNames := field_names (symbol_value (variableName) [1]);
    numberOfFields := len (fieldNames);

    print 'just assigned:';
    for (i in 1:numberOfFields) {
	fullNameOfField := spaste (variableName,'.',fieldNames [i]);
	numberOfElements := len (symbol_value (variableName)[1][i]);
	msg := spaste (fullNameOfField, ' (',numberOfElements, ' elements)');
	print msg;
    }# for i

}# gbtplot.assignVariable
#-----------------------------------------------------------------------------
gbtplot.legalPlotSelections := function (numberOfXAxisSelections, 
                                              numberOfYAxisSelections, 
                                              numberOfY2AxisSelections)
# a temporary compromise is needed here.  the xrt plot widget requires
# plotting to the y1 axis before the y2 axis can be used.  an ugly
# way to find that out -- since the Plot1d interface does not yet support
# this query directly -- is to find out the length of the string returned
# by the gplot1d.g function 'queryData ()'.  an empty plot returns
# a string of length 24; a non-empty plot returns a string of at least
# 100 characters.
# todo: add the ability to query numberOfPlottedQuantities, or some such thing,
# todo: to gplot1d.  maybe this requirement (y1 plotting before y2) will
# todo: go away.
{
  
    if (numberOfYAxisSelections >= 1)
	return T;

    somethingAlreadyPlotted := strlen (queryData ()) > 30; #todo: eliminate trick
    if (somethingAlreadyPlotted && numberOfY2AxisSelections > 0)
	return T;

    return F;
}
#------------------------------------------------------------------------------
gbtplot.dispatchPlotCommands := function (tbl, xAxisColumnName, 
                                          y1AxisColumnNames, 
                                          y2AxisColumnNames,
                                          lstate)
{
  
    #print 'dispatch plot command, xAxis:', xAxisColumnName;
    #print '                      y1Axis:', y1AxisColumnNames;
    #print '                      y2Axis:', y2AxisColumnNames;
  
    extractedData := [=];
  
    numberOfXAxisQuantities := 0;
    numberOfY1AxisQuantities := 0;
    numberOfY2AxisQuantities := 0;
    timeOnXAxis := F;

    if (!is_boolean (xAxisColumnName)) 
	numberOfXAxisQuantities := len (xAxisColumnName);
  
    if (!is_boolean (y1AxisColumnNames)) 
	numberOfY1AxisQuantities := len (y1AxisColumnNames);

    if (!is_boolean (y2AxisColumnNames)) 
	numberOfY2AxisQuantities := len (y2AxisColumnNames);

    if (numberOfXAxisQuantities == 0)
	implicitXAxis := T;
    else {
	implicitXAxis := F;
	timeOnXAxis := gbtplot.isAnMJDTimeAxis (xAxisColumnName);
	if (numberOfXAxisQuantities != 1) {
	    print 'too many quantities for x axis: ', numberOfXAxisQuantities;
	    return F;
	}
	implicitXAxis := F;
	if (!tbl.isscalarcol(xAxisColumnName)) {
	    print 'X axis data is not scalar!', xAxisColumnName;
	    return F;
	}
	xVector := tbl.getcol(xAxisColumnName);
    	if (timeOnXAxis) {
        xAxisColumnName := paste ("t0:", toDate (xVector[1]));}

	if (len (xVector) == 0) {
	    print 'No X axis data!';
	    return F;
	}
	extractedData.x := xVector;
    } # else: data comes from tbl 

if (numberOfY1AxisQuantities  > 0) {
    	tbllen:=tbl.nrows();
    	y1Vector:=array(0,numberOfY1AxisQuantities,tbllen);
	for (i in 1:numberOfY1AxisQuantities) {
	    y1ColumnName := y1AxisColumnNames [i];
	    if (!gbtplot.columnExists (tbl, y1ColumnName)) {
		print 'Y1 Column not in table: ', y1ColumnName;
		return F;
	    }
	    if (!tbl.isscalarcol(y1ColumnName)) {
		print 'Y1 axis data is not scalar!', y1ColumnName;
		return F;
	    }
	    y1Vector[i,] := tbl.getcol (y1ColumnName);
	}# for each data item on the y1 axis
	if (len (y1Vector) == 0)  {
		print 'No Y1 axis data!';
		return F;
	}
	if (implicitXAxis) 
		dataset := pgploty (y1Vector, "Number",y1AxisColumnNames,,lstate);
	else {
		if (timeOnXAxis) {
		    tinseconds:=(xVector-as_integer(xVector[1]))*86400.
		    dataset := pgtimey (tinseconds, y1Vector, xAxisColumnName,y1AxisColumnNames,,lstate);
		}
		else
		 dataset := pgplotxy (xVector, y1Vector,xAxisColumnName,y1AxisColumnNames,,lstate);
	}
	y1VarName := spaste ('y1',i);
	extractedData[y1VarName] := y1Vector;
} #numberOfY1AxisQuantities

if (numberOfY2AxisQuantities > 0) {
        tbllen:=tbl.nrows();
        y2Vector:=array(0,numberOfY2AxisQuantities,tbllen);
	for (i in 1:numberOfY2AxisQuantities) {
	    y2ColumnName := y2AxisColumnNames [i];
	    if (!gbtplot.columnExists (tbl, y2ColumnName)) {
		print 'Y2 Column not in table: ', y2ColumnName;
		return F;
	    }
	    if (!tbl.isscalarcol(y2ColumnName)) {
		print 'Y2 axis data is not scalar!', y2ColumnName;
		return F;
	    }
	    y2Vector[i,] := tbl.getcol(y2ColumnName);
	}# for each data item on the y2 axis
	if (len (y2Vector) == 0)  {
		print 'No Y2 axis data!';
		return F;
	}
	if (implicitXAxis) {
		dataset := pgploty2(y2Vector,"Number",y2AxisColumnNames,,lstate);
	} else {
		if (timeOnXAxis) {
		    tinseconds:=(xVector-as_integer(xVector[1]))*86400.
			dataset := pgtimey2 (tinseconds, y2Vector, xAxisColumnName,y2AxisColumnNames,,lstate);
		}
		else
		    dataset := pgplotxy2(xVector,y2Vector,xAxisColumnName,y2AxisColumnNames,,lstate);
	}
	y2VarName := spaste ('y2',i);
	extractedData[y2VarName] := y2Vector;
} #numberOfY2AxisQuantities

    return extractedData;

}# dispatch plot commands
#------------------------------------------------------------------------------
gbtplot.columnExists := function (tbl, columnName)
# todo: think about caching the column names
{
    return (sum(tbl.colnames() == columnName) > 0);
}
#------------------------------------------------------------------------------
gbtplot.errorDialog := function (msg)
{
    global gui;

    f := dws.frame (title='Error!');
    messageWidget := 
	dws.message (f, text=msg);

    quitButton := dws.button (f, text='Dismiss',type='dismiss');

    whenever quitButton->press do {
	f := F;
    }

}# gbtplot.errorDialog
#-----------------------------------------------------------------------------
gbtplot.isAnMJDTimeAxis := function (columnName)
# Time, RC12_18_DMJD, Weather1_DMJD, OnePpsDeltas_DMJD
{
    if (columnName == 'Time') return T;

    substrings := split (columnName, '_');
    numberOfSubstrings := len (substrings);

    if (numberOfSubstrings < 2) return F;

    if (substrings [numberOfSubstrings] == 'DMJD') return T;

    return F;

}# gbtplot.isAnMJDTimeAxis
#-----------------------------------------------------------------------------
# to test this file's functions in isolation from gbtlogview.g, enable
# the following lines

#include "gtable.g"
#include "gmisc.g"
#include "gplot1d.g"
#tbl := table ('logtable');
#gui := runColumnPlottingDialogBox (tbl);
